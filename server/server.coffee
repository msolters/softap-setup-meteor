Meteor.startup ->
	#
	#	Initialize WiFiControl for the Native application!
	#
	WiFiControl.init
    debug: true

#	open is for opening URLs in the OS's native browser
#	instead of the Electron window when running natively.
open = Meteor.npmRequire 'open'

Meteor.methods 'link': (url) ->
  open url
  return
