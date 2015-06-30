class MockController < ApplicationController

    before_filter :shared_mock_variables

    def index
        music_list_raw = JSON.parse(open('https://www.tadl.org/mobile/export/items/31/json').read)['nodes'].map {|i| i['node']}
        movie_list_raw = JSON.parse(open('https://www.tadl.org/mobile/export/items/32/json').read)['nodes'].map {|i| i['node']}
        book_list_raw = JSON.parse(open('https://www.tadl.org/mobile/export/items/68/json').read)['nodes'].map {|i| i['node']}
        games_list_raw = JSON.parse(open('https://www.tadl.org/mobile/export/items/505/json').read)['nodes'].map {|i| i['node']}
        @movie_list = Dish(movie_list_raw)
        @music_list = Dish(music_list_raw)
        @book_list = Dish(book_list_raw)
        @games_list = Dish(games_list_raw)
    end


  def search
    @search = Search.new params
    results = @search.results
    @items = results[0]
    @facets = results[1]
    @more_results = results[2]
  end


  def details
    if params[:id]
      @recordid = params[:id]
    else
      @recordid = nil # we should probably redirect to error or something here instead
    end
    item_details_raw = JSON.parse(open('http://ilscatcher2.herokuapp.com/items/details?record=' + @recordid).read)
    @item = Dish(item_details_raw['item_details'])
    @copies_on_shelf = Dish(item_details_raw['copies_on_shelf'])
    @copies_all = Dish(item_details_raw['copies'])
  end

  # def more_results
  #   if 
  #   else
  #     @search = Search.new params
  #     Rails.cache.write(params.to_s, @search, :expires_in => 5.minutes)
  #   end
  # end

end
