#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

module SocketsHelper
  include ApplicationHelper
  include NotificationsHelper

  def obj_id(object)
    if object.respond_to?(:post_id)
      object.post_id
    elsif object.respond_to?(:post_guid)
      object.post_guid
    else
      object.id
    end
  end

  def action_hash(user, object, opts={})
    uid = user.id
    begin
      unless user.nil?
        old_locale = I18n.locale
        I18n.locale = user.language.to_s
      end

      object[:guid] = obj_id(object)

      action_hash = {}
      action_hash[:type] = object.class.name
      action_hash[:object] = object
      action_hash[:opts] = opts


      action_hash.to_json
    end
  end
end
