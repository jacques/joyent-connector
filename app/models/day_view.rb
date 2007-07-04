=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class DayView < BaseView
  attr_reader :date

  def initialize(date)
    super()
    @date       = date
    @start_time = @date.to_time(:utc)
    @end_time   = (@date + 1).to_time(:utc)
  end

  # todo: actually now that i think about it i don't think this respects the user's timezone
  def today?
    start_time.midnight == User.current.now.midnight
  end

  # todo: this neither
  def tomorrow?
    start_time.midnight == (User.current.now + 1.day).midnight
  end
  
  def take_events(events)
    local_start_time = date.to_time(:utc).midnight
    local_end_time   = local_start_time + 1.day
    @events += events.select{|event| event.between?(local_start_time, local_end_time)} 

    #@events += events.select{|event| event.falls_on?(date)} 
  end

  def take_others_events(user_id, events)
    user_id = user_id.to_i
    return unless user_id and events

    my_date = self.date
    events.each do |event|
      if event.falls_on?(my_date)
        @others_events[user_id] = [] unless @others_events[user_id]
        @others_events[user_id] << event
      end
    end
  end

  def all_day_events
    events.select{|e| e.all_day?}.sort_by{|e| e.name}
  end
  
  def non_all_day_events
    events.reject{|e| e.all_day?}.sort_by{|e| e.start_time_in_user_tz}
  end

  def users
    [User.current] + @others_events.collect{|key, value| Organization.current.users.find(key)}
  end

  def events_for_user(user)
    return @events if user == User.current
    return @others_events[user.id] if @others_events.has_key?(user.id)
    return []
  end

end