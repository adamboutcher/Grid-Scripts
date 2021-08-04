#
# Netbox Puppet Facter
# Pulls out Rack Name or Cluster Name and place into the fact :netbox_rack
# Probably breaks on Non-Linux systems.
# 2021 - Adam Boutcher - IPPP, Durham University (UKI-SCOTGRID-DURHAM)
#

require 'json'

Facter.add(:netbox_rack) do
  vm = Facter.value(:is_virtual)
  token = "ThisWereYouPutYour40CharAPIKeyForNetbox."
  netbox = "netbox.example.com"
  if !defined?(vm) || (vm != true && vm != "true")
    json = `curl -s -H "Authorization: Token #{token}" https://#{netbox}/api/dcim/devices/?name=$(hostname -s)`
    parsed = JSON.parse(json)
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
    json = `curl -s -H "Authorization: Token #{token}" https://#{netbox}/api/virtualization/virtual-machines/?name=$(hostname -s)`
    parsed = JSON.parse(json)
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
