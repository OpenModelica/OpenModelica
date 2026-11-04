var Module = {};
var preloadComplete = false;

Module['noInitialRun'] = true;
Module['OpenModelica_readFile'] = function(fname) {
  return intArrayToString(FS.findObject(fname).contents);
};
Module['OpenModelica_readFileBuffer'] = function(fname) {
  return FS.findObject(fname).contents;
};

try { // Try to add an event listener like a webworker thread
  self.addEventListener('message', function(e) {
    var data = e.data;
    if (!data) return;
    if (data.preload) {
      if (!preloadComplete) {
        FS.createLazyFile('/', data.basename + "_info.xml", data.basename + "_info.xml", true, false);
        preloadComplete = true;
      }
      self.postMessage({preloaded:true});
      return;
    }
    var result = {};
    result.status = "Simulation failed"
    try {
      shouldRunNow = true;
      var overrideLst = ['outputFormat=csv'];
      var overrides = Object.getOwnPropertyNames(data.override);
      for (var i=0; i<overrides.length; i++) {
        overrideLst.push(overrides[i] + '=' + data.override[overrides[i]]);
      }
      var args = ['-override',overrideLst.join(',')];
      Module.callMain(args);
      result.csv = intArrayToString(FS.findObject(data.basename + "_res.csv").contents);
      result.status = "Simulation finished";
  } catch(e) {
  }
  self.postMessage(result);
  }, false);
} catch (e) {
}
