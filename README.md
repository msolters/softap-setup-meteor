# softap-setup-meteor
A Meteor implementation of the Particle Photon SoftAP.

##  How to Implement SoftAP Setup into a Browser
Incorporating the SoftAP step into the browser is a win-win.  It means the setup procedure is essentially the same for all users, mobile and laptop -- any web browser will work.

All required SoftAP functionality is inside [`client/lib/softap-browser.js`](https://github.com/msolters/softap-setup-meteor/tree/master/client/lib).  (Browserified thanks to the amazing [work of @brewnerd](https://github.com/spark/softap-setup-js/pull/3)).  Everything else apart from that lib file is merely an implementation of the methods it provides using the Meteor framework.

Once the `softap-browser.js` file is included, it allows you to create a SoftAP object as follows:

```
  var SAP = new SoftAPSetup(); 
```

Then, you can use the `SAP` object to access the Particle SoftAP methods as documented on the official [softap-setup-js page's readme](https://github.com/spark/softap-setup-js/blob/master/README.md#usage).  For example, to acquire the JSON data containing the Photon's public key, one could then simply write:

```
  SAP.deviceInfo( function callback(err, dat) {
    if (err) { throw err; }
    console.log("Device ID: %s, claimed: %s", dat.id, dat.claimed ? "yes" : "no");
  };
```

*If you are comparing this to the official readme, note that the browserified SoftAP only works by HTTP, so we can leave out the `{ protocol: 'http' }` argument in the `new SoftAPSetup()` instantiation.  It will happen behind the scenes, out of necessity.*

## How to use the `SAP` Methods to Find & Setup the Photon
Including the [`softap-browser.js`](https://github.com/msolters/softap-setup-meteor/tree/master/client/lib) file above will provide the methods you need for browser-based setup, and all you need is JavaScript.  Period.  Full stop.

In this app I chose to use Meteor because it is a favourite tool of mine for quickly making reactive interfaces such as a setup wizard.  In addition, it can operate in offline mode and easily creates Phonegap apps as a core functionality, making it a natural framework for these kind of IoT applications.

I am assuming that most people are unfamiliar, so I will lay out the general logic of the JavaScript SoftAP procedure, which is framework agnostic.  I reiterate, **you only need the [`softap-browser.js`](https://github.com/msolters/softap-setup-meteor/tree/master/client/lib) file for this procedure to work**.

1.  The user visits the page.
1.  The user changes the computer (or mobile device) so that it is connected to the Photon's AP (i.e. `Photon-ABCD` or whatever).  This is super important.  If the user doesn't hop to the Photon's AP, none of these methods will function.
1.  When the user confirms (I use a "next" button) they are now on the Photon's AP, you can execute

    ```
    SAP.deviceInfo( function(err, dat) {
      var photonID = dat.id;
    } );
    ```
    
    Inside the cb logic, make sure that there's no `err` and that `dat.id` isn't null.  Now you know the Photon's ID and more importantly, that it's reachable.
1.  Next load the Photon's public key: call

    ```
    SAP.publicKey( function(err, dat) {
      // cb logic
    } );`
    
    The only real cb logic here is making sure there's no `err`.
1.  Now the fun part!  We get a list of SSIDs that the Photon can detect by calling

    ```
    var aps;
    SAP.scan( function(err, dat) {
      aps = dat.scans; // an array of ap objects
    } );
    ```
    
    The scan results will be returned as an array of JSON objects inside `dat.scans`.  These should be stored somewhere else in a larger scope for rendering, and later, for looking up when constructing our `config` object.
1.  At this point we would render `aps` into some sort of a list of choices for the user.  In my example app here, I add lock icons and password textboxes for WiFi networks that have security.  I also sort AP choices by decreasing radio strength.  (Hint, you can get a dimensionless "% strength" from the RSSI by using `percentStrength = Math.min( Math.max(2 * (RSSI + 100), 0), 100);`.  At the end of the day, we need to know which element of `aps` corresponds to the AP the user chooses from the list, because we'll need the `channel` and `security` properties from that element.
1.  Once an AP has been chosen, we construct a configuration object as follows.  Assuming `ap` is the element of `dat.scans` that the user wants to connect to:

   ```
   ap = aps[0]; // or whatever the user picks
   var ap_config = {
    ssid: ap.ssid,
    channel: ap.ch,
    security: SAP.securityLookup(ap.sec),
    password = document.getElementById("#ssid-pw").value | ""
   }
   ```
   
  Note how we find the actual security string associated with `ap.sec`, which is an int, by using the `SAP.securityLookup()` method.  The password should come from some password-type input.  It's useful to only show such an input if the user has selected an AP that has security to begin with.
1.  Next we transmit our configuration settings to the Photon itself:

   ```
   SAP.configure( ap_config, function(err, dat) {
    // make sure there are no errors
   } );
   ```
   
1.  Provided that `.congigure()` returns no errors, we can can now connect:
    ```
    SAP.connect( function(err, dat) {
      // check for errors
    } );
    ```

It's most useful to chain these methods, since they behave as callbacks -- for example, I call `SAP.connect()` inside the callback to `SAP.configure`, provided there were no errors.
