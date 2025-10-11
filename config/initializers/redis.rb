# Инициализатор Redis

REDIS_URL = ENV.fetch("REDIS_URL", "redis://localhost:6379/1")
REDIS     = Redis.new(url: REDIS_URL)

REDIS_POOL = ConnectionPool.new(size: 5, timeout: 5) do
  Redis.new(url: REDIS_URL)
end

Redis.define_singleton_method(:current) do
  REDIS_POOL
end
