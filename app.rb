require 'rubygems'
require 'sinatra/base'
require 'sequel'

APPS = [
    'http://game.lpm.io',
    'http://auth.lpm.io',
    'http://s.lpm.io',
    'http://tv.lpm.io',
    'http://stanfordharmonics.com',
    'http://pingbot.lpm.io'
]

class NilClass
    def to_s
        "NEVER" # Probably don't do this in a real app
    end
end

class PingBot < Sinatra::Base
    configure do
        DB = Sequel.connect(ENV['HEROKU_POSTGRESQL_YELLOW_URL'] || ENV['DATABASE_URL'] || raise('No DB found'))
        DB.create_table? :apps do
            primary_key :id
            String :url, null: false
            DateTime :last_ping, null: true
            DateTime :last_success, null: true
        end

        App = DB[:apps]
        if App.count == 0
            APPS.each do |app|
                App.insert url: app
            end
        end
    end

    helpers do
        def diagnose(app)
            if app[:last_success].nil? && app[:last_ping].nil?
                "#{app[:url]} might not be set up correctly. It has never been pinged."
            else
                return "#{app[:url]} is UP! Successfully pinged at #{app[:last_success]}." if app[:last_success] == app[:last_ping]
                "#{app[:url]} might be down. Last attempted ping: #{app[:last_ping]}. Last success: #{app[:last_success]}."
            end
        end
    end

    get '/' do
        @apps = App.all
        erb :index
    end
end