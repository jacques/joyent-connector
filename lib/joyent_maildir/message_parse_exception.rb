=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

module JoyentMaildir
  class MessageParseException < RuntimeError
    include DRbUndumped

    def initialize(message, file)
      @message = message
      @file    = file
    end
    
    def to_s
      "#{@message}: #{@file}"
    end
  end
end