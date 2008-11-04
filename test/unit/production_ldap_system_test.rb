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

  def test_base_dn_for_person
    assert_equal "dbid=1,ou=contacts,o=joyent.joyent.com,dc=joyent,dc=com", 
                 @system.base_dn_for_person(people(:ian))
  end
  
  def test_base_dn_for_user
    assert_equal "uid=ian@joyent.joyent.com,ou=users,o=joyent.joyent.com,dc=joyent,dc=com",
                 @system.base_dn_for_user(users(:ian))
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

  def test_remove_person
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
end