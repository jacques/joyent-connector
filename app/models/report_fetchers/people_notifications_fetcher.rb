=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class PeopleNotificationsFetcher < ReportFetcher
  class << self 
    def summary(report)
      "All of the user's unacknowledged person notifications."
    end
    
    def html_url(report)  
      # Notifications aren't viewable by other people
      {:controller => 'people', :action => 'notifications'}  
    end                 
    
    def group_type(report)
      'notifications'  
    end                         
  end  
end