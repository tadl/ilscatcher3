class FeaturedListBuilder < ApplicationController
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  require 'open-uri'
  require 'mini_magick'
  require 'rake' 

  recurrence {minutely(5)}

  def perform()
    Rake::Task.clear 
    Ilscatcher3::Application.load_tasks
    Rake::Task["generate_sliders"].invoke
  end

end