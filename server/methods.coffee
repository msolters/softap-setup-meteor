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
  connectToAP: (ssid) =>
    #
    # (1) Determine operating system
    #
    switch @PLATFORM
      when "linux"
        IFACE = "wlan0"
        COMMANDS =
          stopNM: "sudo service network-manager stop"
          enableIFACE: "sudo ifconfig #{@IFACE} up"
          connect: "sudo iwconfig #{@IFACE} essid \"#{ssid}\""
          getIP: "sudo dhclient #{@IFACE}"
          startNM: "sudo service network-manager start"
        connectToPhotonChain = [ "stopNM", "enableIFACE", "connect", "getIP"  ]
      when "win32"
        #
        # (1) First we must create a network profile XML file!
        #
        ssid_hex = ""
        for i in [0..ssid.length-1]
          ssid_hex += ssid.charCodeAt(i).toString(16)
        data.charCodeAt(i).toString(16)
        xmlContent = "<?xml version=\"1.0\"?>
                      <WLANProfile xmlns=\"http://www.microsoft.com/networking/WLAN/profile/v1\">
                        <name>Photon-SoftAP</name>
                        <SSIDConfig>
                          <SSID>
                            <hex>#{ssid_hex}</hex>
                            <name>#{ssid}</name>
                          </SSID>
                        </SSIDConfig>
                        <connectionType>ESS</connectionType>
                        <connectionMode>manual</connectionMode>
                        <MSM>
                          <security>
                            <authEncryption>
                              <authentication>open</authentication>
                              <encryption>none</encryption>
                              <useOneX>false</useOneX>
                            </authEncryption>
                          </security>
                        </MSM>
                      </WLANProfile>"
        fut = new Future()
        fs.writeFile "Photon-SoftAP.xml", xmlContent, (err) ->
          if err?
            console.error err
            fut.return false
          else
            fut.return true
        return unless fut.wait()
        COMMANDS =
          loadProfile: "netsh #{@IFACE} add profile filename=\"Photon-SoftAP.xml\""
          connect: "netsh #{@IFACE} connect ssid=\"#{ssid}\" name=\"Photon-SoftAP\""
        connectToPhotonChain = [ "loadProfile", "connect" ]
      when "darwin" # i.e., MacOS
        COMMANDS =
          connect: "networksetup -setairportnetwork #{@IFACE} \"#{ssid}\""
        connectToPhotonChain = [ "connect" ]

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
  resetWiFi: =>
    #
    # (1) Determine operating system
    #
    switch @PLATFORM
      when "linux"
        COMMANDS =
          startNM: "sudo service network-manager start"
        resetWiFiChain = [ "startNM" ]
      when "win32"
        IFACE = "wlan"
        COMMANDS =
          connect: "netsh #{IFACE} connect ssid=YOURSSID name=PROFILENAME"
      when "darwin" # i.e., MacOS
        COMMANDS =
          enableAirport: "networksetup -setairportpower #{@IFACE} on"
          disableAirport: "networksetup -setairportpower #{@IFACE} off"
        resetWiFiChain = [ "disableAirport", "enableAirport" ]

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
