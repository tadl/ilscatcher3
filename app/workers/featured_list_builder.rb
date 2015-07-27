class FeaturedListBuilder < ApplicationController
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence {minutely(10)}

  def perform()
  	  puts "getting list"
  	  music_list_raw = JSON.parse(open('https://www.tadl.org/mobile/export/items/31/json').read)['nodes'].map {|i| i['node']}
      movie_list_raw = JSON.parse(open('https://www.tadl.org/mobile/export/items/32/json').read)['nodes'].map {|i| i['node']}
      book_list_raw = JSON.parse(open('https://www.tadl.org/mobile/export/items/68/json').read)['nodes'].map {|i| i['node']}
      game_list_raw = JSON.parse(open('https://www.tadl.org/mobile/export/items/505/json').read)['nodes'].map {|i| i['node']}
      movie_list = Dish(movie_list_raw)
      music_list = Dish(music_list_raw)
      book_list = Dish(book_list_raw)
      game_list = Dish(game_list_raw)
      Rails.cache.write('music_list', music_list)
      Rails.cache.write('movie_list', movie_list)
      Rails.cache.write('book_list', book_list)
      Rails.cache.write('game_list', game_list)
  end

end