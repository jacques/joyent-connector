=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateContactLists < ActiveRecord::Migration
  def self.up
    create_table :contact_lists do |t|
      t.column :user_id, :integer
    end
  end

  def self.down
    drop_table :contact_lists
  end
end
