$LOAD_PATH << File.expand_path(__dir__)

require "net/http"
require "json"
require "pp"
require 'byebug'
require 'persistance/csv'
require 'byebug'

persistance = Persistance::Csv.new('builds')
# https://ci.comptoirdubitcoin.com/account
access_token = "uvBjQGObiLtytzL6qCQx5Bsng5Iao9D5"

uri = URI("https://ci.comptoirdubitcoin.com/api/repos/ArizenHQ/coinhouse/builds")
uri.query = URI.encode_www_form({ access_token: access_token, page: 1 })

response = Net::HTTP.get_response(uri)
byebug
builds = JSON.parse(response.body, symbolize_names: true)

failures = builds.filter do |build|
  build[:status] == "failure"
end

error = builds.filter do |build|
  build[:status] == "error"
end

killed = builds.filter do |build|
  build[:status] == "killed"
end

successes = builds.filter { |build| build[:status] == "success"}

persistance.save({
  failures: failures.count,
  errors: error.count,
  killed: killed.count,
  successes: successes.count
})
