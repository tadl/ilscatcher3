desc "create lists from shelving locations and check for images"
task :generate_sliders => :environment do
    require 'open-uri'
    require 'mini_magick'

    lists = Settings.lists

    lists.each do |l|
        fetch = Search.new l['search_params']
        results = fetch.results
        list = results[0]
        results_with_images = Array.new
        puts 'processing ' + l['name']
        list.each do |i|
            url = 'https://catalog.tadl.org/opac/extras/ac/jacket/medium/r/' + i.id.to_s
            image = MiniMagick::Image.open(url) rescue nil
            if image != nil
                if image.width > 2
                    results_with_images.push(i)
                end
            end
            if !image.nil?
              image.destroy!
            end
        end
        Rails.cache.write(l['name'], results_with_images)
    end
    time_now = Time.now
    Rails.cache.write('last_updated', time_now)
end
