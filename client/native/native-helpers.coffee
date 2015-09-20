#
# Get the current list of nearby Photons.
#
Template.registerHelper 'nearbyPhotons', ->
  nearbyPhotons.get()
#
# Are we currently looking for nearby Photons?
#
Template.registerHelper 'scanningForPhotons', ->
  scanningForPhotons.get()
