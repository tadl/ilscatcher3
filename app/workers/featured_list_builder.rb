class FeaturedListBuilder < ApplicationController
  include Sidekiq::Worker
  require 'rake' 

  def perform()
    Rake::Task.clear 
    Ilscatcher3::Application.load_tasks
    Rake::Task["generate_sliders"].invoke
  end
  Sidekiq::Cron::Job.create(name: 'fetch featured lists - every 5min', cron: '*/5 * * * *', class: 'FeaturedListBuilder')

end
