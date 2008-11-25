class AddPeoplePersonGroupReportDescription < ActiveRecord::Migration
  def self.up
    ReportDescription.create :name => 'people_person_group'                                                                          
  end

  def self.down
    ReportDescription.find_by_name('people_person_group').destroy
  end
end
