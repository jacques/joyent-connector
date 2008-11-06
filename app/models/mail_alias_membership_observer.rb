=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class MailAliasMembershipObserver < ActiveRecord::Observer
  
  def after_create(membership)
    Person.ldap_system.write_user(membership.user)
    update_in_ldap(membership)
  end
  
  def after_destroy(membership)
    # Why should we destroy an user just when deleting a MailAliasMembership?
    # Person.ldap_system.remove_user(membership.user)
    update_in_ldap(membership)
  end
  
  protected
  
    def update_in_ldap(mam)
      Person.ldap_system.update_alias(mam.mail_alias)
    end
  
end