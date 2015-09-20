#
# Convert RSSI units from dBm to a dimensionless %
# representation.
#
Template.registerHelper 'convertRSSItoPercent', (dBm) ->
  Math.min( Math.max(2 * (dBm + 100), 0), 100)
#
# What stage of the SoftAP setup the user is currently on.
#
Template.registerHelper 'setupStepIs', (_setupState) ->
  return true if setupStep.get() is _setupState
  return false
#
# Are we currently trying to get the deviceInfo & public
# key from the Photon?
#
Template.registerHelper 'attemptingToConnectToPhoton', ->
  attemptingToConnectToPhoton.get()
#
# The last set of AP scan results that were visible to the
# Photon.
#
Template.registerHelper 'APs', ->
  APs.get()
#
# Is the Photon currently scanning for APs?
#
Template.registerHelper 'scanningAPsFromPhoton', ->
  scanningAPsFromPhoton.get()
#
# The current AP that the user has selected for the Photon
# to connect to.
#
Template.registerHelper 'selectedAP', ->
  selectedAP.get()
#
# Is _ap the same access point as selectedAP?
#
Template.registerHelper 'isSelectedAP', (_ap) ->
  return true if selectedAP.get() is _ap
  return false
#
# Given a security type as a decimal integer, returns the
# associated encryption type as a string.
#
Template.registerHelper 'securityType', (securityType_dec) ->
  sap.securityLookup securityType_dec
