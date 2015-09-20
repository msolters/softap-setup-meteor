Template.body.events
  'click button[data-connect-to-photon]': (event, template) ->
    #
    # (1) Create a new SAP object and begin to extract deviceInfo from the Photon.
    #
    attemptingToConnectToPhoton.set true
    Materialize.toast "Communicating with Photon...", 4500
    delete window.sap if window.sap?
    window.sap = new SoftAPSetup()
    retrievePhotonInfo()
  #
  'click button[data-scan-aps-from-photon]': ->
    scanAPsFromPhoton()
  #
  # When a user selects an AP from the SSID list,
  # set selectedAP equal to that AP object.
  #
  'click div.photon-ssid-option': (event, template) ->
    return unless selectedAP.get() isnt @
    selectedAP.set @
  #
  # Here's the logic that gets called when a user hits "connect" or
  # hits Enter after entering the password for an AP from the SSID
  # list.
  #
  'click button#data-connect-to-ap, submit form#connect-to-ssid': (event, template) ->
    #
    # (1) Using the currently selected AP, create a configuration object
    #     that the SoftAPSetup library can use to configure the Photon.
    #
    _ap = selectedAP.get()
    connection_config =
      ssid: _ap.ssid
      channel: _ap.ch
      security: sap.securityLookup _ap.sec
    #
    # (2) Was there security on this AP?  If so, add a password.
    #
    if _ap.sec
      connection_config.password = template.find("input#ssid-pw").value
    else
      connection_config.password = ""
    #
    # (3) Call the SAP.configure and SAP.connect methods.
    #
    configurePhoton connection_config
    return false
  'click button[data-cancel-setup]': (event, template) ->
    resetSetup()

Template.body.destroyed = ->
  delete window.sap if window.sap?
