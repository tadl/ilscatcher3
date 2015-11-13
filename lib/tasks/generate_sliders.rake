desc "create lists from shelving locations and check for images"
task :generate_sliders => :environment do
	require 'open-uri'
	require 'mini_magick'	
	
	lists = [
		{'name' => 'music_list', 'loc' => '23', 'shelving_locations' => ['686']},
		{'name' => 'movie_list', 'loc' => '23', 'shelving_locations' => ['682','687','814']},
		{'name' => 'game_list', 'loc' => '23', 'shelving_locations' => ['777']},
	]

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