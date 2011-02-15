#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require 'spec_helper'

describe Mention do
  before do
    @user = alice
    @user2 = bob
    @sm =  Factory(:status_message)
    @sm2 =  Factory.build(:status_message, :private => true) 
    @sm2.stub!(:private_recipients).and_return([@user.person])
    @sm2.save!

    @m  = Mention.new(:person => @user.person, :post=> @sm)
    @m2  = Mention.new(:person => @user2.person, :post=> @sm)

    @m3 = Mention.new(:person => @user.person, :post=> @sm2)
    @m4  = Mention.new(:person => @user2.person, :post=> @sm2)
  end

  describe 'before create' do
   
   it 'does not notify someone who is mentioned in a private message and is not the recipient' do
      @m4.post.should_receive(:private_recipients).and_return([])
      lambda{
        @m4.save
      }.should_not change(Notification, :count)
    end

    it 'notifies the person being mention' do
      Notification.should_receive(:notify).with(@user, @m, @sm.person)
      @m.save
    end

    it 'should only notify if the person is local' do 
      m = Mention.new(:person => Factory(:person), :post => @sm)
      Notification.should_not_receive(:notify)
      m.save
    end
  end

  describe '#notification_type' do
    it "returns 'mentioned'" do
     @m.notification_type.should == 'mentioned' 
     @m2.notification_type.should == 'mentioned' 
    end

    it 'returns "private message" for the person receiving the private message' do
      @m3.post.should_receive(:private_recipients).and_return([@m3.person])
      @m3.notification_type.should == 'private_message'
    end

    it 'returns nil for the person who is not receiving the private message' do
      @m4.post.should_receive(:private_recipients).and_return([])
      @m4.notification_type.should == nil
    end
  end
  
  describe 'after destroy' do
    it 'destroys a notification' do
      @user = alice
      @sm =  Factory(:status_message)
      @m  = Mention.create(:person => @user.person, :post=> @sm)

      lambda{
        @m.destroy
      }.should change(Notification, :count).by(-1)
    end
  end
end

