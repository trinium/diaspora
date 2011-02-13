#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require 'spec_helper'

describe Post do
  before do
    @user = alice
    @aspect = @user.aspects.create(:name => "winners")
  end

  it 'validates that its not public and private at the same time' do
    sm = @user.build_post(:status_message, :message => "hey", :private => true, :public => true)
    sm.should_not be_valid
  end

  describe 'deletion' do
    it 'should delete a posts comments on delete' do
      post = Factory.create(:status_message, :person => @user.person)
      @user.comment "hey", :on => post
      post.destroy
      Post.where(:id => post.id).empty?.should == true
      Comment.where(:text => "hey").empty?.should == true
    end
  end

  describe 'serialization' do
    it 'should serialize the handle and not the sender' do
      post = @user.post :status_message, :message => "hello", :to => @aspect.id
      xml = post.to_diaspora_xml

      xml.include?("person_id").should be false
      xml.include?(@user.person.diaspora_handle).should be true
    end

    it 'serializes the private flag' do
      post = @user.post :status_message, :message => "hello", :to => @aspect.id
      xml = post.to_diaspora_xml

      xml.should include "private"
    end
  end

  describe '#mutable?' do
    it 'should be false by default' do
      post = @user.post :status_message, :message => "hello", :to => @aspect.id
      post.mutable?.should == false
    end
  end

  describe '#subscribers' do
    it 'returns the people contained in the aspects the post appears in' do

      post = @user.post :status_message, :message => "hello", :to => @aspect.id

      post.subscribers(@user).should == []
    end
  end

  describe '#receive' do
  end
end
