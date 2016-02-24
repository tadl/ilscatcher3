class UserListFetcher < ApplicationController
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(user_token)
    args = Hash.new
    args['token'] = user_token
    user = User.new args
    lists = user.get_lists
    key_name = 'list_' + user_token
    Rails.cache.write(key_name, lists, :expires_in => 2.hours)
  end

end
