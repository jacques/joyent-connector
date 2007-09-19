=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class BaseView
  attr_reader :start_time, :end_time, :current_user

  def initialize(start_time, end_time, current_user)
    @events        = []
    @others_events = {} # key: user_id, value: array of events
    @start_time    = start_time
    @end_time      = end_time
    @current_user  = current_user
  end

  def events
    @events.sort!
  end

  def each(&block)
  end

  def others_events
    @others_events
  end

end