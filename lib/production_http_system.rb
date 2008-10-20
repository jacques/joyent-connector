=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'digest/md5'
require 'net/http'
require 'gettext/rails'

# Digest auth from emeritus Joyeur Johan Sørensen <http://theexciter.com/articles/bingo>
module Net
  module HTTPHeader
    @@nonce_count = -1
    CNONCE = Digest::MD5.new.update("%x" % (Time.now.to_i + rand(65535))).hexdigest
    def digest_auth(user, password, response)
      # based on http://segment7.net/projects/ruby/snippets/digest_auth.rb
      @@nonce_count += 1

      response['www-authenticate'] =~ /^(\w+) (.*)/

      params = {}
      $2.gsub(/(\w+)="(.*?)"/) { params[$1] = $2 }

      a_1 = "#{user}:#{params['realm']}:#{password}"
      a_2 = "#{@method}:#{@path}"
      request_digest = ''
      request_digest << Digest::MD5.new.update(a_1).hexdigest
      request_digest << ':' << params['nonce']
      request_digest << ':' << ('%08x' % @@nonce_count)
      request_digest << ':' << CNONCE
      request_digest << ':' << params['qop']
      request_digest << ':' << Digest::MD5.new.update(a_2).hexdigest

      header = []
      header << "Digest username=\"#{user}\""
      header << "realm=\"#{params['realm']}\""
      
      header << "qop=#{params['qop']}"

      header << "algorithm=MD5"
      header << "uri=\"#{@path}\""
      header << "nonce=\"#{params['nonce']}\""
      header << "nc=#{'%08x' % @@nonce_count}"
      header << "cnonce=\"#{CNONCE}\""
      header << "response=\"#{Digest::MD5.new.update(request_digest).hexdigest}\""

      @header['Authorization'] = header
    end
  end
end

# Custom Net::HTTP requests with localizations for some
# of the most frequent problems with URLs provided by application users
class ProductionHttpSystem
  include GetText
  bindtextdomain('connector')
  
  class << self
    # Net::HTTPResponse
    def get_response_by_url(url, user = '', password = '', redirects_to_follow = 0)
      begin
        parsed = URI.parse(url)
      rescue URI::InvalidURIError
        raise "#{_("The provided URL is not valid")}"
      end
      unless (parsed.scheme == 'http' || parsed.scheme == 'https')
        raise "#{_("Only http and https protocols supported")}"
      end  
      response = self.get_response_by_host_and_path(parsed.host, parsed.path, user, password, redirects_to_follow)
    end

    # Net::HTTPResponse
    def get_response_by_host_and_path(host, path = '', user = '', password = '', redirects_to_follow = 0, digest_auth = false)

      # Maybe is redundant, but want to ensure that we're not going to allow
      # more redirections than the allowed in JoyentConfig
      if redirects_to_follow > JoyentConfig.http_max_redirects
        redirects_to_follow = JoyentConfig.http_max_redirects
      end

      begin
        Net::HTTP.start(host) {|http|
          
          req = Net::HTTP::Get.new(path)
          
          unless user.blank?
            unless digest_auth 
              # Basic Auth:
              req.basic_auth(user, password)
            else 
              # Head request required for Digest Authentication
              res = http.head(url.request_uri)
              # Digest Auth:
              req.digest_auth(user, password, res)
            end
          end
          
          http.read_timeout = JoyentConfig.http_read_timeout
          
          response = http.request(req)
          
          case response
          when Net::HTTPSuccess
            return response
          # Eventually, following redirections
          when Net::HTTPRedirection
            return self.get_response_by_url(response['location'], user, password, redirects_to_follow - 1)
          # Most common problems?. Would like to localize, at least, the most frequent problems
          when Net::HTTPUnauthorized
            # We don't want to return authorization error before to try Digest Auth
            if digest_auth
              raise "#{_("Either the provided Username or Password are not valid")}"
            else
              self.get_response_by_host_and_path(host, path, user, password, redirects_to_follow, true)
            end
          when Net::HTTPNotFound
            raise "#{_("Cannot find the required ICS Calendar. The server returns 404 - Not found")}"
          else # Catch whatever the error
            begin
              response.value
            rescue Exception => e
              raise "#{_("Request error with response: %{i18n_error_message}")%{:i18n_error_message => "#{e.message}"}}"
            end
          end

        }
      rescue SocketError
        raise "#{_("Cannot connect to the provided host")}"
      end
    end
    
  end
  
end