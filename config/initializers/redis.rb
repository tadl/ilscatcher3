if Rails.env.production?
	uri = URI.parse(ENV["REDIS_URL"])
	REDIS = Redis.new(:url => uri)
end
