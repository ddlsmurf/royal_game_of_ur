(function() {
  var scripts = document.getElementsByTagName("script");
  var socket = io.connect(
      (function() { for(var i=0;i<scripts.length;i++) { if(scripts[i].src && scripts[i].src.indexOf("/socket.io.js") > -1)
      return (/^([^#]*?:\/\/.*?)(\/.*)$/.exec(scripts[i].src) || [])[1];
    } })()
  );
  window.IOSocket = socket;
})();