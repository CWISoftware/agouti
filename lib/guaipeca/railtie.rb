require 'guaipeca/rack/package_limiter'
require 'rails/railtie'

module Guaipeca
  class Railtie < ::Rails::Railtie
    initializer 'guaipeca.rails_initialization' do | app |
      app.config.middleware.use Guaipeca::Rack::PackageLimiter
    end
  end
end