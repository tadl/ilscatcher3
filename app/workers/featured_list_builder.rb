class FeaturedListBuilder < ApplicationController
  include Sidekiq::Worker
  require 'rake' 

  def perform()
    Rake::Task.clear 
    Ilscatcher3::Application.load_tasks
    Rake::Task["generate_sliders"].invoke
  end
  if Settings.account_only != "true" then
    Sidekiq::Cron::Job.create(name: 'fetch featured lists - every 10min', cron: '*/10 * * * *', class: 'FeaturedListBuilder')
  end

end
