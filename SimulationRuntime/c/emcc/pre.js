var Module = {};

Module['noInitialRun'] = true;
Module['OpenModelica_readFile'] = function(fname) {
  return intArrayToString(FS.findObject(fname).contents);
};

try { // Try to add an event listener like a webworker thread
  self.addEventListener('message', function(e) {
    var data = e.data;
    if (!data) return;
    var result = {};
    try {
        shouldRunNow = true;
        var args = ['-override','outputFormat=csv,stopTime=' +  data.stopTime +',tolerance=' + data.tolerance + ',stepSize=' + data.stepSize];
        Module.callMain(args);
        result.csv = intArrayToString(FS.findObject(data.basename + "_res.csv").contents);
        result.status = "Simulation finished";
    } catch(err) {
        result.status = "Simulation failed";
    };
    self.postMessage(result);
  }, false);
} catch (e) {
}
