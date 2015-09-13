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
          fut.return {
            success: true
            networks: data
            msg: "Nearby devices successfully scanned."
          }
      fut.wait()
    catch error
      return {
        success: false
        msg: "We encountered an error while scanning for Photons: #{error}"
      }
