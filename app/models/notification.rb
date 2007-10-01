=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class Notification < ActiveRecord::Base
  validates_presence_of :organization_id
  validates_presence_of :notifier_id
  validates_presence_of :notifiee_id
  validates_presence_of :item_id
  validates_presence_of :item_type

  belongs_to :organization
  belongs_to :notifier, :class_name => 'User', :foreign_key => 'notifier_id'
  belongs_to :notifiee, :class_name => 'User', :foreign_key => 'notifiee_id'
  belongs_to :item, :polymorphic => true

  after_create   :notify!
  after_save     :add_invitation
  before_destroy :remove_invitation

  cattr_accessor :notification_systems
  @@notification_systems = {:email  => NotificationSystem::EmailNotifier,
                            :jabber => NotificationSystem::JabberNotifier,
                            :sms    => NotificationSystem::SmsNotifier }

  def acknowledge!
    self.acknowledged = true
    self.save!
  end
  
  def notify!
    @@notification_systems.each do |key, value|
      value.notify(self) if notifiee.notify_via?(key)
    end
  end

  private

    def add_invitation
      item.invite(notifiee) if item.is_a?(Event)
    end               
  
    def remove_invitation
      item.uninvite(notifiee) if item.is_a?(Event)
    end
end