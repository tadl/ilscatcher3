class SuggestAnItemMailer < ActionMailer::Base
  def suggest_an_item_email(info)
  	@users = ENV["SUGGEST_AN_ITEM_EMAIL"]
  	@info = info
  	mail to: @users, subject: 'TADL - Suggest An Item'
  end
end