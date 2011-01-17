class AddTokensToContacts < ActiveRecord::Migration
  def self.up
    add_column :contacts, :local_token, :string
    add_column :contacts, :remote_token, :string
  end

  def self.down
    remove_column :contacts, :remote_token
    remove_column :contacts, :local_token
  end
end
