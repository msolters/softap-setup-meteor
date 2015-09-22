#
# ReactiveVars
#
# nearbyPhotons is a list of APs being broadcast by Photons.
@nearbyPhotons = new ReactiveVar []
# scanningForPhotons is true only when we are scanning for
# APs being broadcast by any Photons nearby.
@scanningForPhotons = new ReactiveVar false

#
# Methods
#
#
# scanForPhotons: Scan nearby WiFi APs using the wifi-control package.
#                 Return any APs that contain "Photon-*"
#
@scanForPhotons = ->
  scanningForPhotons.set true
  Meteor.call "scanForWiFi", (err, resp) ->
    scanningForPhotons.set false
    if resp.success
      deviceFilter = new RegExp /Photon-/ # We only want APs that contain "Photon-"
      nearbyPhotons.set _.filter resp.networks, (n) ->
        deviceFilter.test n.ssid
