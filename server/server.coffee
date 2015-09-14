@WiFiScanner = Meteor.npmRequire 'node-wifiscanner2'
@Future = Meteor.npmRequire 'fibers/future'
@exec = Npm.require('child_process').exec
@fs = Npm.require('fs')

#
# (1) Establish network interface.
#

@PLATFORM = process.platform
switch @PLATFORM
  when "linux"
    getIFACE = "ip link show | grep wlan | grep -i \"state UP\""
    child = exec getIFACE, (error, stdout, stderr) =>
      @IFACE = stdout.trim().split(": ")[1]
  when "win32"
    @IFACE = "wlan" # default
  when "darwin"
    getIFACE = "route get 10.10.10.10 | grep interface"
    child = exec getIFACE, (error, stdout, stderr) =>
      @IFACE = stdout.trim().split(": ")[1]
