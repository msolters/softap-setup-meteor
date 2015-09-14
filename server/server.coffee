@WiFiScanner = Meteor.npmRequire 'node-wifiscanner2'
@Future = Meteor.npmRequire 'fibers/future'
@exec = Npm.require('child_process').exec

if process.platform is "darwin"
  getIFACE = "route get 10.10.10.10"
  child = exec getIFACE, (error, stdout, stderr) ->
    console.log stdout
