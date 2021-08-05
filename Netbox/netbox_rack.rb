#
# Netbox Puppet Facter
# Pulls out Rack Name or Cluster Name and place into the fact :netbox_rack
# Probably breaks on Non-Linux systems.
# 2021 - Adam Boutcher - IPPP, Durham University (UKI-SCOTGRID-DURHAM)
#

require 'json'
require 'net/http'
require 'uri'
require 'socket'

Facter.add(:netbox_rack) do
  vm = Facter.value(:is_virtual)
  token = "ThisWereYouPutYour40CharAPIKeyForNetbox."
  netbox = "netbox.example.com"
  host = Socket.gethostname[/^[^.]+/]
  if !defined?(vm) || (vm != true && vm != "true")
    uri = URI.parse("https://#{netbox}/api/dcim/devices/?name=#{host}")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Token #{token}"
    req_options = {
      use_ssl: uri.scheme == "https",
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    parsed = JSON.parse(response.body)
    setcode do
      if parsed['results'].any?
        if parsed['results'][0]['rack']['name'].length != 0
          parsed['results'][0]['rack']['name']
        else
          ""
        end
      end
    end
  else
    uri = URI.parse("https://#{netbox}/api/virtualization/virtual-machines/?name=#{host}")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Token #{token}"
    req_options = {
      use_ssl: uri.scheme == "https",
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    parsed = JSON.parse(response.body)
    setcode do
      if parsed['results'].any?
        if parsed['results'][0]['cluster']['name'].length != 0
          parsed['results'][0]['cluster']['name']
        else
          ""
        end
      end
    end
  end
end
