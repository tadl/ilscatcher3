class EmailSuggestAnItem < ApplicationController
  include Sidekiq::Worker
  def perform(params)
  	SuggestAnItemMailer.suggest_an_item_email(params).deliver
  end
end
