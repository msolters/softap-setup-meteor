Meteor.methods
  scanWiFi: ->
    try
      fut = new Future()
      WiFiScanner.scan (err, data) ->
        if err
          fut.return {
            success: false
            msg: "We encountered an error while scanning for Photons: #{error}"
          }
        else
          console.log data
          deviceFilter = new RegExp /Photon/
          fut.return {
            success: true
            networks: _.filter data, (n) -> deviceFilter.test n.ssid
            msg: "Nearby devices successfully scanned."
          }
      fut.wait()
    catch error
      return {
        success: false
        msg: "We encountered an error while scanning for Photons: #{error}"
      }
  connectToAP: (ssid) ->
    #
    # (1) Determine operating system
    #
    switch process.platform
    	when "linux"
    		IFACE = "wlan0"
    		COMMANDS =
    			stopNM: "sudo service network-manager stop"
    			enableIFACE: "sudo ifconfig #{IFACE} up"
    			connect: "sudo iwconfig #{IFACE} essid \"#{ssid}\""
    			getIP: "sudo dhclient #{IFACE}"
    			startNM: "sudo service network-manager start"
    		connectToPhotonChain = [ "stopNM", "enableIFACE", "connect", "getIP"  ]
    	when "win32"
        IFACE = "wlan"
        COMMANDS =
          connect: "netsh #{IFACE} connect ssid=YOURSSID name=PROFILENAME"
      when "darwin" # i.e., MacOS
        IFACE = "en1"
        COMMANDS =
          connect: "networksetup -setairportnetwork #{IFACE} #{SSID}"
          enable: "networksetup -setairportpower #{IFACE} on"
          disable: "networksetup -setairportpower #{IFACE} off"

    for com in connectToPhotonChain
      fut = new Future()
      child = exec COMMANDS[com], (error, stdout, stderr) ->
        #console.log "stdout: #{stdout}"
        #console.log "stderr: #{stderr}"
        if error?
          console.log "exec error: #{error}"
          fut.return {
            success: false
            msg: "Encountered an error connecting to Photon: #{error}"
          }
        else
          fut.return {
            success: true
            msg: "Successfully connected to Photon!"
          }
      if !fut.wait().success
        return fut.wait()
    return {
      success: true
      msg: "Successfully connected to Photon!"
    }
  resetWiFi: ->
    #
    # (1) Determine operating system
    #
    switch process.platform
    	when "linux"
    		IFACE = "wlan0"
    		COMMANDS =
    			startNM: "sudo service network-manager start"
    		resetWiFiChain = [ "startNM" ]
    	when "win32"
        IFACE = "wlan"
        COMMANDS =
          connect: "netsh #{IFACE} connect ssid=YOURSSID name=PROFILENAME"
      when "darwin" # i.e., MacOS
        IFACE = "en1"
        COMMANDS =
          connect: "networksetup -setairportnetwork #{IFACE} #{SSID}"
          enable: "networksetup -setairportpower #{IFACE} on"
          disable: "networksetup -setairportpower #{IFACE} off"

    for com in resetWiFiChain
      fut = new Future()
      child = exec COMMANDS[com], (error, stdout, stderr) ->
        #console.log "stdout: #{stdout}"
        #console.log "stderr: #{stderr}"
        if error?
          console.log "exec error: #{error}"
          fut.return {
            success: false
            msg: "Encountered an error resetting WiFi: #{error}"
          }
        else
          fut.return {
            success: true
            msg: "Successfully returned to home WiFi!"
          }
      if !fut.wait().success
        return fut.wait()
    return {
      success: true
      msg: "Successfully returned to home WiFi!"
    }
