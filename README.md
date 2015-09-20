# softap-setup-meteor
A Meteor implementation of the Particle Photon SoftAP.

##  How to Implement SoftAP Setup into a Browser
Incorporating the SoftAP step into the browser is a win-win.  It means the setup procedure is essentially the same for all users, mobile and laptop -- any web browser will work.

All required SoftAP functionality is inside [`client/lib/softap-browser.js`](https://github.com/msolters/softap-setup-meteor/tree/master/client/lib).  (Browserified thanks to the amazing [work of @brewnerd](https://github.com/spark/softap-setup-js/pull/3)).  Everything else apart from that lib file is merely an implementation of the methods it provides using the Meteor framework.

Once the `softap-browser.js` file is included, it allows you to create a SoftAP object as follows:

```js
  var SAP = new SoftAPSetup();
```

Then, you can use the `SAP` object to access the Particle SoftAP methods as documented on the official [softap-setup-js page's readme](https://github.com/spark/softap-setup-js/blob/master/README.md#usage).  For example, to acquire the JSON data containing the Photon's public key, one could then simply write:

```js
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

    ```js
    SAP.deviceInfo( function(err, dat) {
      var photonID = dat.id;
    } );
    ```

    Inside the cb logic, make sure that there's no `err` and that `dat.id` isn't null.  Now you know the Photon's ID and more importantly, that it's reachable.
1.  Next load the Photon's public key:

    ```js
    SAP.publicKey( function(err, dat) {
      // cb logic
    } );
    ```

    The only real cb logic here is making sure there's no `err`.  This may seem useless (we never explicitly use any return value), but it is an important step internally for the `SAP` machinery!!  Without it, we can't encrypt passwords and therefore cannot complete the last 2 steps of the setup.
1.  Now the fun part!  We get a list of SSIDs that the Photon can detect by calling

    ```js
    var aps;
    SAP.scan( function(err, dat) {
      aps = dat.scans; // an array of ap objects
    } );
    ```

    The scan results will be returned as an array of JSON objects inside `dat.scans`.  These should be stored somewhere else in a larger scope for rendering, and later, for looking up when constructing our `config` object.
1.  At this point we would render `aps` into some sort of a list of choices for the user.  In my example app here, I add lock icons and password textboxes for WiFi networks that have security.  I also sort AP choices by decreasing radio strength.  (Hint, you can get a dimensionless "% strength" from the RSSI by using `percentStrength = Math.min( Math.max(2 * (RSSI + 100), 0), 100);`.  At the end of the day, we need to know which element of `aps` corresponds to the AP the user chooses from the list, because we'll need the `channel` and `security` properties from that element.
1.  Once an AP has been chosen, we construct a configuration object as follows.  Assuming `ap` is the element of `dat.scans` that the user wants to connect to:

   ```js
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

   ```js
   SAP.configure( ap_config, function(err, dat) {
    // make sure there are no errors
   } );
   ```

1.  Provided that `.configure()` returns no errors, we can can now connect:
    ```js
    SAP.connect( function(err, dat) {
      // check for errors
    } );
    ```

It's most useful to chain these methods, since they behave as callbacks -- for example, I call `SAP.connect()` inside the callback to `SAP.configure`, provided there were no errors.

## Deploy as a Stand Alone Application
This Meteor application has been designed to be deployed as a stand-alone native application by using [Electron](http://electron.atom.io/) through the [arboleya:electrify](https://atmospherejs.com/arboleya/electrify) package.

The underlying motivation is that this will provide:

*  Automatation of WiFi switching and Photon detection by using the [msolters:wifi-control](https://atmospherejs.com/msolters/wifi-control) package.
*  Guaranteed compatibility, since Electron is essentially Chromium -- which is tested to work with SoftAP.
*  Never lose assets or resources, which can occur when web apps lose their connection to the internet whilst connected to the Photon's AP.

To run the application natively:

1.  Make sure you have [Meteor installed](https://www.meteor.com/install).
1.  Clone this repo, and `cd` into `softap-setup-meteor`.
2.  Execute `meteor`.

This should automatically launch an Electron shell containing this application (the native app).  In addition, visiting `http://localhost:3000/` in any other browser will work equivalently as a local app.  At the time of this writing, expect some bugs in Windows.

If you see errors associated with Electron or `electrify`, consider manually installing the `electrify` tool inside `softap-setup-meteor/.electrify`:

```sh
  cd .electrify && npm install
```

## Firmware Notes & Gotchas
The Photon will not automatically *leave* listening mode when the `SAP.connect()` command is issued for firmware < v0.4.4.  This is a [known bug and is fixed](https://github.com/spark/firmware/issues/558) in versions >= 0.4.5.  Press reset to manually trigger the Photon to attempt to connect, and make sure your firmware is the latest version!
