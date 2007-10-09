=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class ListColumn < ActiveRecord::Base
  belongs_to :list
  has_many   :list_cells, :dependent => :destroy
  
  acts_as_list :scope => :list_id  

  validates_presence_of :list_id  
  validates_presence_of :name
  validates_presence_of :kind

  after_save {|record| record.list.save}
  after_save :create_cells
  after_destroy {|record| record.list.save}

  ColumnKinds = %w(Checkbox Date Number Text)
  
  def validate
    unless ColumnKinds.include?(kind.to_s)
      errors.add("kind", "was not recognized")
    end
  end
  
  # fill-in cells for new columns
  def create_cells
    list.list_rows.each do |list_row|
      if list_cells.detect{|list_cell| list_cell.list_row_id == list_row.id}
        next
      else
        list_cells.create(:list_row_id => list_row.id)
      end
    end
  end
  
  def convert_to!(new_kind)
    return if self.kind == new_kind
    return unless ColumKinds.include?(new_kind)

    list_cells.each{|lc| lc.convert_to!(new_kind)}
    update_attribute(:kind, new_kind)
  end
  
end