#!/opt/puppetlabs/bolt/bin/ruby

require 'yaml'
require 'json'
require 'date'
require 'net/https'

params = JSON.parse(STDIN.read)

def make_error (msg)
  error = {
    "_error" => {
      "kind" => "execution error",
      "msg"  => msg,
      "details" => {}
    }
  }
  return error
end

target = params['_target']

puts target

splunk_server = target['hostname']
splunk_token  = target['token']

splunk_port = target['port'] || '8088'

report = params['report']
facts = params['facts']

# now we can create the event with the timestamp from the report
time = DateTime.parse(report['time'])
epoch = time.strftime('%Q').to_str.insert(-4, '.')

host = params['host'] || facts['clientcert']

event = report

event['facts'] = facts

splunk_event = {
  "host" => host,
  "time" => epoch,
  "event"  => event,
}

#  create header here
#header = "Authorization: Splunk #{splunk_token}"

request = Net::HTTP::Post.new("https://#{splunk_server}:#{splunk_port}/services/collector")
request.add_field("Authorization", "Splunk #{splunk_token}")
request.add_field("Content-Type", "application/json")
request.body = splunk_event.to_json

client = Net::HTTP.new(splunk_server, splunk_port)

client.use_ssl = true
client.verify_mode = OpenSSL::SSL::VERIFY_NONE

client.request(request)