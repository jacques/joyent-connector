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

class ProductionLdapSystemTest < Test::Unit::TestCase
  fixtures all_fixtures

  def setup
    @system = ProductionLdapSystem.new(JoyentConfig.ldap_host, 'user', 'pass', 'dc=joyent,dc=com')
    @person = people(:ian)
    @user   = users(:ian)
    @org    = organizations(:joyent)
    @alias  = mail_aliases(:www)
    
    # LDAP Connection stubbing
    @ldap_connection = mock('ldap connection')
    LDAP::Conn.stubs(:new).returns(@ldap_connection)
    
    @ldap_connection.stubs(:set_option).returns(true)
    @ldap_connection.stubs(:bind).returns(true)
  end
  
  def test_user_dn
    assert_equal "ou=users,o=joyent.joyent.com,dc=joyent,dc=com", 
                 @system.user_dn(organizations(:joyent))
  end
  
  def test_contact_dn
    assert_equal "ou=contacts,o=joyent.joyent.com,dc=joyent,dc=com",
                 @system.contact_dn(organizations(:joyent))
  end
  
  def test_person_to_ldap
    assert_matches_fixture 'ian-person', @system.person_to_ldap(people(:ian))
  end

  def test_user_to_ldap
    assert_matches_fixture 'ian-user', @system.user_to_ldap(users(:ian))
  end
  
  def test_alias_to_ldap
    assert_matches_fixture 'www-alias', @system.alias_to_ldap(@alias)
  end

  def test_base_dn_for_person
    assert_equal "dbid=1,ou=contacts,o=joyent.joyent.com,dc=joyent,dc=com", 
                 @system.base_dn_for_person(people(:ian))
  end
  
  def test_base_dn_for_user
    assert_equal "uid=ian@joyent.joyent.com,ou=users,o=joyent.joyent.com,dc=joyent,dc=com",
                 @system.base_dn_for_user(users(:ian))
  end
  
  def test_base_dn_for_alias
    assert_equal "mail=www@joyent.joyent.com,ou=aliases,o=joyent.joyent.com,dc=joyent,dc=com",
                 @system.base_dn_for_alias(@alias)
  end
  
  def test_person_to_ldap_without_addresses_or_phone
    assert_matches_fixture 'user_with_restrictions-person',
                 @system.person_to_ldap(people(:user_with_restrictions))
  end
  
  
  def test_person_to_ldap_with_address_no_phone
    assert_matches_fixture 'notuser-person', @system.person_to_ldap(people(:notuser))
  end
  
  def test_person_to_ldap_without_address_with_phone
    assert_matches_fixture 'jason-person', @system.person_to_ldap(people(:jason))
  end

  def test_base_hash
    h = {"objectClass"=>["top", "dcObject", "organization", "joyentOrganization"], "o"=>["joyent.joyent.com"], "description"=>["Root for Joyent"], "dc"=>["joyent"], "aliasDomain"=>["joyent.joyent.com", "joyent.net", "koz.dev.joyent.com"]}
    assert_equal h, @system.base_hash(organizations(:joyent))
  end  

  def test_users_hash
    h = {"description"=>["Users for Joyent"], "ou"=>["users"], "objectClass"=>["top", "organizationalUnit"]}
    assert_equal h, @system.users_hash(organizations(:joyent))
  end
  
  def test_contacts_hash
    h = {"description"=>["Contacts for Joyent"], "ou"=>["contacts"], "objectClass"=>["top", "organizationalUnit"]}
    assert_equal h, @system.contacts_hash(organizations(:joyent))
  end

  def assert_matches_fixture(name, object)
    assert_equal ldap_fixture(name), object
  end
  
  def test_write_person_user    
    # Person doesn't exist in LDAP
    @system.expects(:person_in_ldap?).with(@person).returns(false)
    @ldap_connection.expects(:add).with(@system.base_dn_for_person(@person), @system.person_to_ldap(@person)).returns(true)    
    @ldap_connection.expects(:delete).never    
    assert @system.write_person(@person)
    
    # Person exists in LDAP
    @system.expects(:person_in_ldap?).with(@person).returns(true)
    @ldap_connection.expects(:add).with(@system.base_dn_for_person(@person), @system.person_to_ldap(@person)).returns(true)    
    @ldap_connection.expects(:delete).with(@system.base_dn_for_person(@person)).returns(true)    
    assert @system.write_person(@person)    

    # User doesn't exist in LDAP
    @system.expects(:user_in_ldap?).with(@user).returns(false)
    @ldap_connection.expects(:add).with(@system.base_dn_for_user(@user), @system.user_to_ldap(@user)).returns(true)    
    @ldap_connection.expects(:delete).never    
    assert @system.write_user(@user)
    
    # User exists in LDAP
    @system.expects(:user_in_ldap?).with(@user).returns(true)
    @ldap_connection.expects(:add).with(@system.base_dn_for_user(@user), @system.user_to_ldap(@user)).returns(true)    
    @ldap_connection.expects(:delete).with(@system.base_dn_for_user(@user)).returns(true)    
    assert @system.write_user(@user)    
  end
  
  def test_update_person_user
    # Person doesn't exist in LDAP
    @system.expects(:person_in_ldap?).with(@person).returns(false)
    @ldap_connection.expects(:modify).never    
    assert_nil @system.update_person(@person)
    
    # Person exists in LDAP
    @system.expects(:person_in_ldap?).with(@person).returns(true)
    @ldap_connection.expects(:modify).with(@system.base_dn_for_person(@person), @system.person_to_ldap(@person)).returns(true)
    assert @system.update_person(@person)    

    # User doesn't exist in LDAP
    @system.expects(:user_in_ldap?).with(@user).returns(false)
    @ldap_connection.expects(:modify).never    
    assert_nil @system.update_user(@user)
    
    # User exists in LDAP
    @system.expects(:user_in_ldap?).with(@user).returns(true)
    @ldap_connection.expects(:modify).with(@system.base_dn_for_user(@user), @system.user_to_ldap(@user)).returns(true)    
    assert @system.update_user(@user)    
  end

  def test_remove_person_user
    # Person doesn't exist in LDAP
    @system.expects(:person_in_ldap?).with(@person).returns(false)
    @ldap_connection.expects(:delete).never
    assert_nil @system.remove_person(@person)    

    # Person exists in LDAP    
    @system.expects(:person_in_ldap?).with(@person).returns(true)
    @ldap_connection.expects(:delete).with(@system.base_dn_for_person(@person)).returns(true)
    assert @system.remove_person(@person)    
  
    # User doesn't exist in LDAP
    @system.expects(:user_in_ldap?).with(@user).returns(false)
    @ldap_connection.expects(:delete).never    
    assert_nil @system.remove_user(@user)
    
    # User exists in LDAP
    @system.expects(:user_in_ldap?).with(@user).returns(true)
    @ldap_connection.expects(:delete).with(@system.base_dn_for_user(@user)).returns(true)    
    assert @system.remove_user(@user)    
  end

  def test_write_alias    
    @ldap_connection.expects(:add).with(@system.base_dn_for_alias(@alias), @system.alias_to_ldap(@alias)).returns(true)    
    assert @system.write_alias(@alias)
  end
  
  def test_update_alias
    # Alias doesn't exist in LDAP
    @system.expects(:alias_in_ldap?).with(@alias).returns(false)
    @ldap_connection.expects(:modify).never
    @system.expects(:write_alias).with(@alias).returns(true)
    assert @system.update_alias(@alias)
    
    # Alias exists in LDAP
    @system.expects(:alias_in_ldap?).with(@alias).returns(true)
    @ldap_connection.expects(:modify).with(@system.base_dn_for_alias(@alias), @system.alias_to_ldap(@alias)).returns(true)
    @system.expects(:write_alias).never
    assert @system.update_alias(@alias)    
  end

  def test_remove_alias
    # Alias doesn't exist in LDAP
    @system.expects(:alias_in_ldap?).with(@alias).returns(false)
    @ldap_connection.expects(:delete).never
    assert_nil @system.remove_alias(@alias)    

    # Alias exists in LDAP    
    @system.expects(:alias_in_ldap?).with(@alias).returns(true)
    @ldap_connection.expects(:delete).with(@system.base_dn_for_alias(@alias)).returns(true)
    assert @system.remove_alias(@alias)    
  end  
  
  def test_save_organization_group
    # Successful save
    @ldap_connection.expects(:modify).with(@system.group_base_dn(@org), @system.group_base_hash(@org)).returns(true)
    assert @system.save_organization_group(@org)
    
    # Unsuccessful save, organization group doesn't exist and it gets created
    @ldap_connection.expects(:modify).with(@system.group_base_dn(@org), @system.group_base_hash(@org)).raises(LDAP::Error)    
    @ldap_connection.expects(:add).with(@system.group_base_dn(@org), @system.group_base_hash(@org)).returns(true)
    assert @system.save_organization_group(@org)
  end

  def test_remove_organization_group
    # Successful removal
    @ldap_connection.expects(:delete).with(@system.group_base_dn(@org)).returns(true)
    assert @system.remove_organization_group(@org)
    
    # Unsuccessful removal, organization group doesn't exist: do nothing
    @ldap_connection.expects(:delete).with(@system.group_base_dn(@org)).raises(LDAP::Error)    
    assert_nil @system.remove_organization_group(@org)
  end  

  def test_write_organization
    # Define a sequence
    add_calls = sequence('add_calls')
    # Define a call sequence
    @ldap_connection.expects(:add).with(@system.base_dn(@org), @system.base_hash(@org)).returns(true).in_sequence(add_calls)
    @ldap_connection.expects(:add).with(@system.user_dn(@org), @system.users_hash(@org)).returns(true).in_sequence(add_calls)    
    @ldap_connection.expects(:add).with(@system.contact_dn(@org), @system.contacts_hash(@org)).returns(true).in_sequence(add_calls)
    @ldap_connection.expects(:add).with(@system.alias_dn(@org), @system.aliases_hash(@org)).returns(true).in_sequence(add_calls)
    
    @system.expects(:save_organization_group).with(@org).returns(true)
    
    assert @system.write_organization(@org)
  end  
  
  def test_update_organization
    # Successful update
    @ldap_connection.expects(:modify).with(@system.base_dn(@org), @system.base_hash(@org)).returns(true)
    @system.expects(:save_organization_group).with(@org).returns(true)
    assert @system.update_organization(@org)
    
    # Unsuccessful update, maybe org doesn't exist and it gets created
    @ldap_connection.expects(:modify).with(@system.base_dn(@org), @system.base_hash(@org)).raises(LDAP::Error)    
    @system.expects(:write_organization).with(@org).returns(true)
    @system.expects(:save_organization_group).with(@org).returns(true)    
    assert @system.update_organization(@org)
  end

  def test_remove_organization
    # Successful removal
    remove_calls = sequence('remove_calls')

    @ldap_connection.expects(:delete).with(@system.user_dn(@org)).returns(true).in_sequence(remove_calls)    
    @ldap_connection.expects(:delete).with(@system.contact_dn(@org)).returns(true).in_sequence(remove_calls)
    @ldap_connection.expects(:delete).with(@system.alias_dn(@org)).returns(true).in_sequence(remove_calls)    
    @ldap_connection.expects(:delete).with(@system.base_dn(@org)).returns(true).in_sequence(remove_calls)        
    
    @system.expects(:remove_organization_group).with(@org).returns(true)
    
    assert @system.remove_organization(@org)
    
    # Unsuccessful update, org doesn't exist: do nothing
    # It should fail on the first call
    @ldap_connection.expects(:delete).with(@system.user_dn(@org)).raises(LDAP::Error)    
    # And then, a call to remove_organization should raise an exception too, but let's just stub
    # this method and test it in its own testcase
    @system.expects(:remove_organization_group).with(@org).returns(true)
    assert @system.remove_organization(@org)
  end
end