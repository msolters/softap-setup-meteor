@WiFiScanner = Meteor.npmRequire 'node-wifiscanner2'
@Future = Meteor.npmRequire 'fibers/future'
@exec = Npm.require('child_process').exec

#
# (1) Establish network interface.
#
if process.platform is "darwin"
  getIFACE = "route get 10.10.10.10"
  child = exec getIFACE, (error, stdout, stderr) ->
    @IFACE = stdout.trim().split(": ")[1]
