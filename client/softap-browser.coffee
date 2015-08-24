Template.connectHub.created = ->
  window.sap = new SoftAPSetup()
  @connectionStep = new ReactiveVar 'connectToHub'
  @selectedAP = new ReactiveVar false

Template.connectHub.helpers
  connectionStepIs: (_connectionState) ->
    return true if Template.instance().connectionStep.get() is _connectionState
    return false
  selectedAP: ->
    Template.instance().selectedAP.get()

Template.connectHub.events
  'click button[data-locate-hub]': (event, template) ->
    console.log("Obtaining device information...");
    sap.deviceInfo (err, dat) ->
      throw err if err
      if dat.id?
        template.connectionStep.set 'chooseSSID'
      else
        template.connectionStep.set 'connectToHub'
  'click div.hub-ssid-option': (event, template) ->
    template.selectedAP.set @


###
#     Template.scanHubAPs
###
Template.scanHubAPs.created = ->
  @scanningAPs = new ReactiveVar true
  @aps = new ReactiveVar []
  @scanAPs = =>
    @scanningAPs.set true
    console.log "Scanning APs..."
    sap.scan (err, dat) =>
      throw err if err
      console.log "Finished scanning: "
      console.log dat.scans
      @retrieveKey(dat.scans) if dat.scans?
  @retrieveKey = (aps=[]) =>
    console.log "Retrieving public key..."
    sap.publicKey (err, dat) =>
      throw err if err
      console.log "Key retrieved: #{dat}"
      @scanningAPs.set false
      @aps.set aps
  @scanAPs()

Template.scanHubAPs.helpers
  aps: ->
    Template.instance().aps.get()
  scanningAPs: ->
    Template.instance().scanningAPs.get()
  securityType: (securityType_dec) ->
    sap.securityLookup securityType_dec

Template.scanHubAPs.events
  'click button[data-scan-aps]': (event, template) ->
    template.scanAPs()


###
#     Template.connectToAP
###
Template.connectToAP.events
  'submit form#connect-to-ssid': (event, template) ->
    connection_config =
      ssid: template.data.ap.ssid
      channel: template.data.ap.ch
      security: sap.securityLookup template.data.ap.sec
    if template.data.ap.sec
      connection_config.password = template.find("input#ssid-pw").value
    else
      connection_config.password = ""
    sap.configure connection_config, (err, dat) ->
      throw err if err
      console.log 'configured!!!'
      sap.connect (err, dat) ->
        throw err if err
        console.log 'connected!!!'
    return false
