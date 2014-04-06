require 'rubygems'
require 'sinatra/base'
require 'sequel'
require 'pg'

APPS = [
    'http://game.lpm.io',
    'http://auth.lpm.io',
    'http://s.lpm.io',
    'http://tv.lpm.io',
    'http://stanfordharmonics.com',
    'http://pingbot.lpm.io'
]

class PingBot < Sinatra::Base
    configure do
        DB = Sequel.connect(ENV['HEROKU_POSTGRESQL_YELLOW_URL'] || ENV['DATABASE_URL'] || "raise('No DB found')")
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
        def pretty_url(url)
            "<a href='#{url}'><em>#{url}</em></a>"
        end

        def pretty_timestamp(datetime)
            return "never" if datetime.nil?
            '<strong>' + datetime.strftime("%a, %m/%d/%Y at %H:%m:%S %P") + '</strong>'
        end

        def diagnose(app)
            if app[:last_success].nil? && app[:last_ping].nil?
                "#{pretty_url app[:url]} might not be set up correctly. It has never been pinged."
            else
                return "#{pretty_url app[:url]} is <strong>UP!</strong> Successfully pinged on #{pretty_timestamp app[:last_success]}." if app[:last_success] == app[:last_ping]
                "#{pretty_url app[:url]} might be <strong>down.</strong> Last attempted ping: #{pretty_timestamp app[:last_ping]}. Last success: #{pretty_timestamp app[:last_success]}."
            end
        end
    end

    get '/' do
        @apps = App.all
        erb :index
    end
end