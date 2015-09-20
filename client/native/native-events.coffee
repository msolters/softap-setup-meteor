###
#     Template.nativeSetup
###
Template.nativeSetup.created = ->
  scanForPhotons()

Template.nativeSetup.events
  #
  # Scan the local WiFi networks for something that looks
  # like a Photon, using the WiFiControl NPM package on the
  # server.
  #
  'click button[data-scan-for-photons]': ->
    scanForPhotons()
  #
  # Automatically hop to the Photon's AP and then try to
  # negotiate device data with it.
  #
  'click li[data-connect-to-photon]': (event, template) ->
    #
    # (1) Direct the OS to connect to the Photon's AP.
    #
    attemptingToConnectToPhoton.set true
    Materialize.toast "Connecting to Photon WiFi Beacon...", 4500
    Meteor.call "connectToAP", {ssid: @ssid}, (err, resp) ->
      meteorMethodCB err, resp
      if !err?
        if resp.success
          # (2) If we are successful, create a new SAP object
          #     and begin to extract deviceInfo from the Photon.
          Materialize.toast "Communicating with Photon...", 4500
          delete window.sap if window.sap?
          window.sap = new SoftAPSetup()
          retrievePhotonInfo()
          return
      #
      # (3) If we're not successful, reset the setup wizard!
      #
      attemptingToConnectToPhoton.set false
      Meteor.call "resetWiFi", (err, resp) ->
        meteorMethodCB err, resp
  #
  # Some buttons -- such as hitting cancel buttons -- should
  # force the user's computer back to their default WiFi.
  #
  'click [data-reset-wifi]': ->
    Meteor.call "resetWiFi", (err, resp) ->
      meteorMethodCB err, resp
  #
  # Closing a window in Electron is the same as closing the app!
  #
  'click button[data-close-app]': ->
    window.close()
  #
  # Intercept URLs from the Electron part of the app,
  # force them to open in the OS-native browser.
  #
  'click a': (event, target) ->
    event.preventDefault()
    url = $(event.currentTarget).attr "href"
    Meteor.call "link", url if url?
