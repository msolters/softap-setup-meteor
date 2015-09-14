Meteor.methods
  scanWiFi: ->
    try
      fut = new Future()
      WiFiScanner.scan (err, data) ->
        if err
          fut.return {
            success: false
            msg: "We encountered an error while scanning for Photons: #{error}"
          }
        else
          console.log data
          deviceFilter = new RegExp /Photon/
          fut.return {
            success: true
            networks: _.filter data, (n) -> deviceFilter.test n.ssid
            msg: "Nearby devices successfully scanned."
          }
      fut.wait()
    catch error
      return {
        success: false
        msg: "We encountered an error while scanning for Photons: #{error}"
      }
  connectToAP: (network) ->
