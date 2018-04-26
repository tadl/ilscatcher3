class SuggestAnItemMailer < ActionMailer::Base
  default from: "tadlbot@tadl.org"

  def suggest_an_item_email(info)
    @users = ENV["SUGGEST_AN_ITEM_EMAIL"]
    @info = info
    mail to: @users, subject: '<%= Settings.system_name %> - Suggest An Item'
  end
end
