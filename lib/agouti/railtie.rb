require 'agouti/rack/package_limiter'
require 'rails/railtie'

module Agouti
  class Railtie < ::Rails::Railtie
    initializer 'agouti.rails_initialization' do | app |
      app.config.middleware.use Agouti::Rack::PackageLimiter
    end
  end
end