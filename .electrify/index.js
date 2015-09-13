var app       = require('app');
var browser   = require('browser-window');
var electrify = require('electrify');


var window    = null;

app.on('ready', function() {

  window = new browser({
    width: 1200,
    height: 900,
    'node-integration': false
  });
  
  electrify.boot(function() {
    window.loadUrl(electrify.meteor_url);
  });

});


app.on('will-quit', function(event) {
  electrify.shutdown(app, event);
});

app.on('window-all-closed', function() {
  app.quit();
});