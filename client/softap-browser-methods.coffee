#
# ReactiveVars
#
# setupStep is the current SoftAP setup stage the user is on.
@setupStep = new ReactiveVar 'connectToPhoton'
# Are we waiting on device info or public key from the Photon?
@attemptingToConnectToPhoton = new ReactiveVar false
# Are we waiting on AP scan results from the Photon?
@scanningAPsFromPhoton = new ReactiveVar false
# APs is the current list of APs visible to the Photon.
@APs = new ReactiveVar []
# selectedAP is the last chosen AP the user clicked on.
@selectedAP = new ReactiveVar false

#
# Methods
#

#
# resetSetup: Configure all reactive-vars to their default
#             state, as for a new visitor.
#
@resetSetup = ->
  delete window.sap if window.sap?
  attemptingToConnectToPhoton.set false
  APs.set []
  selectedAP.set false
  scanningAPsFromPhoton.set false
  setupStep.set 'connectToPhoton'

#
# meteorMethodCB: This takes MMethod callback parameters, and
#                 displays an appropriate toast.
#
@meteorMethodCB = (err, resp) ->
  if err?
    Materialize.toast resp.msg, 4500, "red"
  else
    if resp.success
      Materialize.toast resp.msg, 4500
    else
      Materialize.toast resp.msg, 4500, "red"

#
# setPhotonConnectionState: Contains methods for indicating we have
#                           successfully connected to a Photon's AP,
#                           or that we are now disconnected.
#
@setPhotonConnectionState =
  connected: =>
    attemptingToConnectToPhoton.set false
    setupStep.set 'chooseSSID'
    scanAPsFromPhoton()
  disconnected: =>
    attemptingToConnectToPhoton.set false
    setupStep.set 'connectToPhoton'
    Materialize.toast "We weren't able to find a Photon!  Make sure your computer's wireless network manager is properly connected to the Photon via WiFi.", 7000, "red"
    #Meteor.call "resetWiFi", (err, resp) ->
    #  meteorMethodCB err, resp

#
# retrievePhotonInfo: This method returns the Photon's deviceInfo.
#                     If successful, will then invoke retrievePhotonKey().
#
@retrievePhotonInfo = ->
  console.log "Retrieving device info..."
  attempt = 0
  getInfoAttempt = ->
    return unless sap?
    sap.deviceInfo (err, dat) ->
      if !err
        if dat.id?
          console.log "Photon device info retrieved: #{dat}"
          retrievePhotonKey()
          return
      else
        if attempt is 5
          setPhotonConnectionState.disconnected()
          return
        else
          attempt++
          Meteor.setTimeout getInfoAttempt, 1500
  getInfoAttempt()
#
# retrievePhotonKey:  This method returns the Photon's public key.
#
@retrievePhotonKey = ->
  console.log "Retrieving public key..."
  sap.publicKey (err, dat) ->
    throw err if err
    if !err
      console.log "Key retrieved: #{dat}"
      Materialize.toast "Photon is now scanning for nearby WiFi networks...", 4500
      setPhotonConnectionState.connected()
    else
      setPhotonConnectionState.disconnected()

@scanAPsFromPhoton = ->
  if scanningAPsFromPhoton.get()
    Materialize.toast "The Photon is currently scanning for WiFi networks, please wait...", 3500, "teal"
    return
  APs.set []
  scanningAPsFromPhoton.set true
  console.log "Photon is scanning APs..."
  sap.scan (err, dat) ->
    throw err if err
    console.log "Finished scanning: "
    console.log dat.scans
    scanningAPsFromPhoton.set false
    networkMsg = "#{dat.scans.length} WiFi network"
    networkMsg += "s" unless dat.scans.length is 1
    networkMsg += " found."
    Materialize.toast networkMsg, 4500, "green"
    APs.set _.sortBy dat.scans, (_ap) ->
      -_ap.rssi

@configurePhoton = ( connection_config ) ->
  sap.configure connection_config, (err, dat) ->
    throw err if err
    console.log 'configured!!!'
    sap.connect (err, dat) ->
      throw err if err
      setupStep.set 'finished'
      Meteor.call "resetWiFi", (err, resp) ->
      console.log 'connected!!!'
