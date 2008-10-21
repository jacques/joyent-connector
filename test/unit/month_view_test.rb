=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

# Redefine the today method for the Date class in order to test MonthView for various dates
class Date
	@@test_year  = 2008
	@@test_month = 1
	@@test_day   = 1

	def self.today
		return Date.new(@@test_year, @@test_month, @@test_day)
  end

  def Date.set_test_day(new_year, new_month, new_day)
		@@test_year  = new_year
		@@test_month = new_month
    @@test_day   = new_day
  end
end


class MonthViewTest < Test::Unit::TestCase
	fixtures :users
	START_OF_WEEK = 0

	def setup
		User.current = users(:ian)
	end	
  
  # Since these tests are overriding Date.today, there won't be a problem with
  # the date at which these are being ran.
	def test_create_month_view_current_month
		month_date = Date.new(2008, 10, 1)

		Date.set_test_day(2008, 10, 1)
		assert month = MonthView.new(month_date, START_OF_WEEK, User.current)
    # No additional weeks needed
		assert_equal 5, month.week_count
    Date.set_test_day(2008, 10, 8)
    assert month = MonthView.new(month_date, START_OF_WEEK, User.current)
    # No additional weeks needed    
    assert_equal 5, month.week_count		
    Date.set_test_day(2008, 10, 15)
    assert month = MonthView.new(month_date, START_OF_WEEK, User.current)
    # One week needed
    assert_equal 6, month.week_count   
    Date.set_test_day(2008, 10, 22)
    assert month = MonthView.new(month_date, START_OF_WEEK, User.current)
    # Two weeks needed
    assert_equal 7, month.week_count    
    Date.set_test_day(2008, 10, 29)
    assert month = MonthView.new(month_date, START_OF_WEEK, User.current)
    # Three weeks needed    
    assert_equal 8, month.week_count    
	end

	def test_create_month_view_start_of_week
		month_date = Date.new(2008, 10, 1)

    Date.set_test_day(2008, 10, 5)
    assert month = MonthView.new(month_date, START_OF_WEEK, User.current)
    # No additional weeks needed    
    assert_equal 5, month.week_count		
    Date.set_test_day(2008, 10, 12)
    assert month = MonthView.new(month_date, START_OF_WEEK, User.current)
    # One week needed
    assert_equal 6, month.week_count   
    Date.set_test_day(2008, 10, 19)
    assert month = MonthView.new(month_date, START_OF_WEEK, User.current)
    # Two weeks needed
    assert_equal 7, month.week_count    
    Date.set_test_day(2008, 10, 26)
    assert month = MonthView.new(month_date, START_OF_WEEK, User.current)
    # Three weeks needed    
    assert_equal 8, month.week_count    
	end

	def test_create_month_view_different_month
		month_date = Date.new(2008, 10, 01)

    # No additional weeks needed when not seeing current month
		Date.set_test_day(2008, 03, 01)
		assert month = MonthView.new(month_date, START_OF_WEEK, User.current)
    assert_equal 5, month.week_count
		Date.set_test_day(2008, 03, 15)
		assert month = MonthView.new(month_date, START_OF_WEEK, User.current)
    assert_equal 5, month.week_count
		Date.set_test_day(2008, 11, 01)
		assert month = MonthView.new(month_date, START_OF_WEEK, User.current)
    assert_equal 5, month.week_count
		Date.set_test_day(2008, 9, 30)
		assert month = MonthView.new(month_date, START_OF_WEEK, User.current)
    assert_equal 5, month.week_count    
	end
end
