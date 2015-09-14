###
#       Global template helpers
###
Template.registerHelper 'convertRSSItoPercent', (dBm) ->
  Math.min( Math.max(2 * (dBm + 100), 0), 100)


###
#       Template.WiFiSetup
###
Template.WiFiSetup.created = ->
  @beacons = new ReactiveVar 0
  @scanningForDevices = new ReactiveVar false
  @scanForDevices = =>
    @scanningForDevices.set true
    Meteor.call "scanWiFi", (err, resp) =>
      @scanningForDevices.set false
      if resp.success
        @beacons.set resp.networks
  @scanForDevices()
  #
  # ( ) Initialize basic SoftAP objects and methods.
  #
  delete window.sap if window.sap?
  window.sap = new SoftAPSetup()
  @connectionStep = new ReactiveVar 'connectToPhoton'
  #
  # ( ) Variables for tracking attempts to connect to the Photon
  #
  @locatingPhoton = new ReactiveVar false
  @setPhotonConnectionState =
    connected: =>
      @locatingPhoton.set false
      @connectionStep.set 'chooseSSID'
      @scanAPs()
    disconnected: =>
      @locatingPhoton.set false
      @connectionStep.set 'connectToPhoton'
      Materialize.toast "We weren't able to find a Photon!  Make sure your computer's wireless network manager is properly connected to the Photon via WiFi.", 7000, "red"
  #
  # This method returns the deviceInfo of the Photon.
  #
  @retrieveDeviceInfo = =>
    console.log "Retrieving device info..."
    sap.deviceInfo (err, dat) =>
      if !err
        if dat.id?
          console.log "Device info retrieved: #{dat}"
          @retrieveKey()
          return
      else
        @setPhotonConnectionState.disconnected()
  @retrieveKey = =>
    console.log "Retrieving public key..."
    sap.publicKey (err, dat) =>
      throw err if err
      if !err
        console.log "Key retrieved: #{dat}"
        @setPhotonConnectionState.connected()
      else
        @setPhotonConnectionState.disconnected()
  #
  # ( ) Define SoftAP scanning methods and callbacks.
  #
  @scanningAPs = new ReactiveVar false
  @aps = new ReactiveVar []
  @selectedAP = new ReactiveVar false
  @scanAPs = =>
    if @scanningAPs.get()
      Materialize.toast "The Photon is currently scanning for WiFi networks, please wait...", 3500, "teal"
      return
    @aps.set []
    @scanningAPs.set true
    console.log "Scanning APs..."
    sap.scan (err, dat) =>
      throw err if err
      console.log "Finished scanning: "
      console.log dat.scans
      @scanningAPs.set false
      @aps.set _.sortBy dat.scans, (_ap) ->
        -_ap.rssi

Template.WiFiSetup.helpers
  beacons: ->
    Template.instance().beacons.get()
  scanningForDevices: ->
    Template.instance().scanningForDevices.get()
  connectionStepIs: (_connectionState) ->
    return true if Template.instance().connectionStep.get() is _connectionState
    return false
  # SoftAP photon location helpers.
  locatingPhoton: ->
    Template.instance().locatingPhoton.get()
  # SoftAP scanning helpers.
  aps: ->
    Template.instance().aps.get()
  selectedAP: ->
    Template.instance().selectedAP.get()
  scanningAPs: ->
    Template.instance().scanningAPs.get()
  securityType: (securityType_dec) ->
    sap.securityLookup securityType_dec
  isSelectedAP: (_ap) ->
    return true if Template.instance().selectedAP.get() is _ap
    return false

Template.WiFiSetup.events
  'click button[data-scan-beacons]': (event, template) ->
    template.scanForDevices()
  'click li[data-connect-to-photon]': (event, template) ->
    template.locatingPhoton.set true
    Meteor.call "connectToAP", @ssid, (err, resp) ->
      if !err?
        if resp.success
          template.retrieveDeviceInfo()
          return
      template.locatingPhoton.set false
      Meteor.call "resetWiFi", (err, resp) ->

  # SoftAP photon location events.
  'click button[data-locate-photon]': (event, template) ->
    template.locatingPhoton.set true
    template.retrieveDeviceInfo()
  # SoftAP scanning events.
  'click button[data-scan-aps]': (event, template) ->
    template.scanAPs()
  'click button[data-deselect-ssid]': (event, template) ->
    template.selectedAP.set false
  'click div.photon-ssid-option': (event, template) ->
    return unless template.selectedAP.get() isnt @
    template.selectedAP.set @
  # SoftAP connection events.
  'click button#data-connect-to-ap, submit form#connect-to-ssid': (event, template) ->
    _ap = template.selectedAP.get()
    connection_config =
      ssid: _ap.ssid
      channel: _ap.ch
      security: sap.securityLookup _ap.sec
    if _ap.sec
      connection_config.password = template.find("input#ssid-pw").value
    else
      connection_config.password = ""
    sap.configure connection_config, (err, dat) ->
      throw err if err
      console.log 'configured!!!'
      sap.connect (err, dat) ->
        throw err if err
        template.connectionStep.set 'pendingConnection'
        Meteor.call "resetWiFi", (err, resp) ->
        console.log 'connected!!!'
    return false
  # SoftAP pendingConnection events.
  'click button[data-restart-wifi-wizard]': (event, template) ->
    Meteor.call "resetWiFi", (err, resp) ->
    template.locatingPhoton.set false
    template.aps.set []
    template.selectedAP.set false
    template.scanningAPs.set false
    template.connectionStep.set 'connectToPhoton'

Template.WiFiSetup.destroyed = ->
  delete window.sap if window.sap?
