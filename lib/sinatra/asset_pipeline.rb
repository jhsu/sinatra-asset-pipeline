require 'sprockets'
require 'sprockets-helpers'

module Sinatra
  module AssetPipeline
    class << self
      attr_accessor :app_class
    end
    def self.registered(app)
      self.app_class = app.class
      app.set_default :sprockets, Sprockets::Environment.new
      app.set_default :assets_precompile, %w(app.js app.css *.png *.jpg *.svg *.eot *.ttf *.woff)
      app.set_default :assets_prefix, 'assets'
      app.set_default :assets_path, -> { File.join(public_folder, assets_prefix) }
      app.set_default :assets_protocol, 'http'

      app.set :static, true
      app.set :assets_digest, true
      app.set :static_cache_control, [:public, :max_age => 525600]

      app.configure do
        Dir[File.join app.assets_prefix, "*"].each {|path| app.sprockets.append_path path}

        Sprockets::Helpers.configure do |config|
          config.environment = app.sprockets
          config.digest = app_class.assets_digest
        end
      end

      app.configure :staging, :production do
        Sprockets::Helpers.configure do |config|
          config.manifest = Sprockets::Manifest.new(app.sprockets, app_class.assets_path)
        end
      end

      app.configure :production do
        Sprockets::Helpers.configure do |config|
          config.protocol = app_class.assets_protocol
          config.asset_host = app_class.assets_host if app_class.respond_to? :assets_host
        end
      end

      app.helpers Sprockets::Helpers

      app.configure :development do
        app.get '/assets/*' do |key|
          key.gsub! /(-\w+)(?!.*-\w+)/, ""
          asset = app.sprockets[key]
          content_type asset.content_type
          asset.to_s
        end
      end
    end

    def set_default(key, default)
      self.set(key, default) unless self.class.app_class.respond_to? key
    end
  end
end
