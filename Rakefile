require 'net/http'
require 'sequel'
require 'tzinfo'

DB = Sequel.connect(ENV['HEROKU_POSTGRESQL_YELLOW_URL'] || ENV['DATABASE_URL'] || raise('No DB found'))
App = DB[:apps]

desc "This task is called by the Heroku scheduler add-on to keep my apps awake"
task :ping_all do
  local_hour = TZInfo::Timezone.get("America/Los_Angeles").utc_to_local(Time.now.utc).hour
  return if local_hour < 8 # Sleep between midnight and 8am pacific to be nicer to Heroku's free servers
  App.each do |app|
    uri = URI.parse app[:url]
    response = Net::HTTP.get_response uri

    # Follow redirects
    while response.kind_of? Net::HTTPRedirection
      response = Net::HTTP.get_response(URI.parse response.header['location'])
    end

    now = DateTime.now
    App.where(id: app[:id]).update last_ping: now
    if response.kind_of? Net::HTTPSuccess
      App.where(id: app[:id]).update last_success: now
    end
  end
end

namespace :db do
  task :reset do
    App.delete
  end
end
