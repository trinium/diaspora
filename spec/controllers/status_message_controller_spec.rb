#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require 'spec_helper'

describe StatusMessagesController do
  render_views

  let!(:user1)   { Factory.create(:user) }
  let!(:aspect) { user1.aspects.create(:name => "AWESOME!!") }
  let!(:aspect1) { user1.aspects.create(:name => "AWESOME2!") }

  let!(:user2)   { Factory.create(:user) }
  let!(:aspect2) { user2.aspects.create(:name => "WIN!!") }

  context 'local actions' do

    before do
      connect_users(user1, aspect1, user2, aspect2)
      request.env["HTTP_REFERER"] = ""
      sign_in :user, user1
      @controller.stub!(:current_user).and_return(user1)
      user1.reload
    end

    describe '#show' do
      it 'succeeds' do
        message = user1.build_post :status_message, :message => "ohai", :to => aspect1.id
        message.save!
        user1.add_to_streams(message, [aspect1])
        user1.dispatch_post message, :to => aspect1.id

        get :show, "id" => message.id.to_s
        response.should be_success
      end
    end

    describe '#create' do
      let(:status_message_hash) {
        { :status_message => {
        :public  =>"true",
        :message =>"facebook, is that you?",
      },
      :aspect_ids =>"#{aspect1.id}" }
      }
      it 'responds to js requests' do
        post :create, status_message_hash.merge(:format => 'js')
        response.status.should == 201
      end

      it "doesn't overwrite person_id" do
        status_message_hash[:status_message][:person_id] = user2.person.id
        post :create, status_message_hash
        new_message = StatusMessage.find_by_message(status_message_hash[:status_message][:message])
        new_message.person_id.should == user1.person.id
      end

      it "doesn't overwrite id" do
        old_status_message = user1.post(:status_message, :message => "hello", :to => aspect1.id)
        status_message_hash[:status_message][:id] = old_status_message.id
        post :create, status_message_hash
        old_status_message.reload.message.should == 'hello'
      end

      it "dispatches all referenced photos" do
        fixture_filename  = 'button.png'
        fixture_name      = File.join(File.dirname(__FILE__), '..', 'fixtures', fixture_filename)

        photo1 = user1.build_post(:photo, :user_file=> File.open(fixture_name), :to => aspect1.id)
        photo2 = user1.build_post(:photo, :user_file=> File.open(fixture_name), :to => aspect1.id)

        photo1.save!
        photo2.save!

        hash = status_message_hash
        hash[:photos] = [photo1.id.to_s, photo2.id.to_s]

        user1.should_receive(:dispatch_post).exactly(3).times
        post :create, hash
      end
    end

    describe '#destroy' do
      let!(:message) {user1.post(:status_message, :message => "hey", :to => aspect1.id)}
      let!(:message2) {user2.post(:status_message, :message => "hey", :to => aspect2.id)}

      it 'let a user delete his photos' do
        delete :destroy, :id => message.id
        StatusMessage.find_by_id(message.id).should be_nil
      end

      it 'will not let you destroy posts visible to you' do
        delete :destroy, :id => message2.id
        StatusMessage.find_by_id(message2.id).should be_true
      end

      it 'will not let you destory posts you do not own' do
        delete :destroy, :id => message2.id
        StatusMessage.find_by_id(message2.id).should be_true
      end
    end

  end
  
  context 'remote actions' do
  let!(:user3)   { Factory.create(:user) }
  let!(:aspect3) { user3.aspects.create(:name => "WIN!!") }

    before do
      connect_users(user1, aspect1, user2, aspect2)
    end

    describe '#remote_show' do
      let!(:message)  {user1.post(:status_message, :message => "hey", :to => aspect1.id)}
      let!(:message2) {user1.post(:status_message, :message => "hey", :to => aspect.id)}

      before do
        contact = user1.contact_for(user2.person)
        contact.local_token = "abc"
        contact.remote_token = "123"
        contact.save
        @post_params = {:format => 'json',:author_handle => user1.diaspora_handle, :post_id => message.guid, :requester_handle => user2.diaspora_handle, 
           :token => 'abc'}

      end

      it 'succeeds with valid token' do
        get :remote_show, @post_params
        response.code.should == "200"
      end

      it 'fails with invalid token' do
        @post_params[:token] = '312'
        get :remote_show, @post_params

        response.code.should == "401"
      end

      it 'fails if they are not friends' do
        @post_params[:requester_handle] = user3.diaspora_handle
        @post_params[:token] = 'abc'
        get :remote_show, @post_params

        response.code.should == "401" 
      end

      it 'fails if the message is posted to a different aspect' do
        @post_params[:post_id] = message2.guid
        get :remote_show, @post_params

        response.code.should == "401"
      end
    end
  end
end
