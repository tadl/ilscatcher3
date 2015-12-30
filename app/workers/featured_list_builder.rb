class FeaturedListBuilder < ApplicationController
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  require 'open-uri'
  require 'mini_magick' 

  recurrence {minutely(5)}

  def perform()
    lists = Settings.lists
    lists.each do |l|
      query = {"sort" => "pubdateDESC",  "loc" => l['loc'], "qtype" => "shelf", "shelving_location" => l['shelving_locations'], "availability" => "on"}
      fetch = Search.new query
        results = fetch.results
        list = results[0]
        results_with_images = Array.new
      puts 'processing ' + l['name']
      list.each do |i|
          url = 'https://catalog.tadl.org/opac/extras/ac/jacket/large/r/' + i.id.to_s
          image = MiniMagick::Image.open(url) rescue nil
          if image != nil 
            if image.width > 2
              puts i.title + ' was a good one'
              results_with_images.push(i)
            else
              puts i.title + ' was a bad one because one pixel'
            end
          else
            puts i.title + ' was a bad one because 404'
          end
        end
        Rails.cache.write(l['name'], results_with_images)
      end
  end
  time_now = Time.now
  Rails.cache.write('last_updated', time_now)
end