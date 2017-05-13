(function() {
  window.IOSocket.on('page',       reloadPage)
                 .on('css',        reloadCss)
                 .on('reconnect',  reloadPage);

  function reloadPage() {
    location.reload();
  }

  function reloadCss() {
    var links = document.getElementsByTagName("link");
    for (var i = 0; i < links.length; i++) {
      var tag = links[i];
      if (tag.rel.toLowerCase().indexOf("stylesheet") >= 0 && tag.href) {
        var newHref = tag.href.replace(/(&|%5C?)\d+/, "");
        tag.href = newHref + (newHref.indexOf("?") >= 0 ? "&" : "?") + (new Date().valueOf());
      }
    }

    // set timeout because occasionally the styles aren't
    // ready yet and you get blank page
    setTimeout(function() {
      var el = document.body;
      var bodyDisplay = el.style.display || 'block';
      el.style.display = 'none';
      el.offsetHeight;
      el.style.display = bodyDisplay;
      console.log('CSS updated');
    }, 150);
  }

})();