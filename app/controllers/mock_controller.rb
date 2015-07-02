class MockController < ApplicationController
    include ApplicationHelper
    before_filter :shared_mock_variables
    respond_to :html, :json, :js

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
    @format_options = [['All Formats', 'all'],['Movies', 'g'],['Music', 'j']]
    @search = Search.new params
    results = @search.results
    @items = results[0]
    @facets = results[1]
    @more_results = results[2]
    respond_to do |format|
      format.html
      format.js
    end
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

end
