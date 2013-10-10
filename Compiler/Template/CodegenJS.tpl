// Code to generate control files for JavaScript

package CodegenJS

import interface SimCodeTV;
import CodegenUtil.*;

template markdownFile(SimCode simCode)
::=
match simCode case SIMCODE(__) then textFile(markdownContents(simCode), '<%fileNamePrefix%>.md')
end markdownFile;

template markdownContents(SimCode simCode)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(functions = functions, varInfo = vi as VARINFO(__), vars = vars as SIMVARS(__)),
             simulationSettingsOpt = SOME(s as SIMULATION_SETTINGS(__)), makefileParams = makefileParams as MAKEFILE_PARAMS(__))
then
<<
```yaml script=scriptloader
- tinytimer.js
```

```yaml script=dataloader
xml: <%fileNamePrefix%>_init.xml
```

# OpenModelica simulation example
## <%Util.escapeModelicaStringToXmlString(dotPath(modelInfo.name))%>

<img src="<%fileNamePrefix%>.svg" class="pull-right" style="width:540px; background-color:#ffffff; border:2px solid gray" />

```yaml jquery=jsonForm class="form-horizontal" name=frm 
schema: 
  stopTime:
    type: string
    title: Stop time [s]
    default: <%s.stopTime%>
  intervals:
    type: string
    title: Output intervals
    default: <%realDiv(s.stopTime,s.stepSize)%>
  tolerance:
    type: string
    title: Tolerance
    default: <%s.tolerance%>
  solver: 
    type: string
    title: Solver
    enum: 
      - dassl
      - euler
      - rungekutta
form: 
  - "*"
params:
  fieldHtmlClass: input-medium
```

```js
if (typeof(isRunning) == "undefined") isRunning = false

if (typeof(timer) != "undefined") {clearInterval(timer.interval); timer = null};
$xml = $(xml)

// Set the default simulation parameters
defex = $xml.find("DefaultExperiment")
defex.attr("stopTime", stopTime)
defex.attr("stepSize", +stopTime / intervals)
defex.attr("tolerance", tolerance)
defex.attr("solver", solver)

// Set some model parameters - UNCOMMENT & CHANGE AS NEEDED
//$xml.find("ScalarVariable[name = 'RL.R']").find("Real").attr("start", RL)

// Write out the initialization file
xmlstring = new XMLSerializer().serializeToString(xml)

$("#statustext").html('<img src="wait.gif" /> Simulation running')
$("#statustimer").html("");
$('#statustimer').tinyTimer({ from: Date.now() });

timer = $("#statustimer").data("tinyTimer")

// Start the simulation!
basename = "<%fileNamePrefix%>"

if (typeof(wworker) != "undefined" && isRunning) wworker.terminate() 
if (typeof(wworker) == "undefined" || isRunning) wworker = new Worker(basename + ".js")
isRunning = true

wworker.postMessage({basename: basename, xmlstring: xmlstring})
wworker.addEventListener('error', function(event) {
});


```

<div id="status" style="text-align:center"><span id="statustext">
Simulation loading</span>. &nbsp Time: <span id="statustimer"> </span></div>


## Results

<div id="yaxisform"> </div>

```js
// read the csv file with the simulation results

wworker.addEventListener("message", function(e) {
    $("#statustext").html(e.data.status)
    timer.stop();
    isRunning = false
    x = $.csv.toArrays(e.data.csv, {onParseValue: $.csv.hooks.castToScalar})
    
    // `header` has the column names. The first is the time, and the rest
    // of the columns are the variables.
    header = x.slice(0,1)[0]
    
    // Select graph variables with a select box based on the header values
    if (typeof(graphvar) == "undefined") graphvar = header[1];
    if (typeof(graphvarX) == "undefined") graphvarX = header[0];
    
    var jsonform = {
      schema: {
        graphvar: {
          type: "string",
          title: "Plot variable",
          default: graphvar,
          enum: header
        }
      },
      form: [
        {
          key: "graphvar",
          onChange: function (evt) {
            calculate_forms();
            $("#plotdiv").calculate();
          }
        }
      ]
    };
    var jsonformX = {
      schema: {
        graphvarX: {
          type: "string",
          default: graphvarX,
          enum: x.slice(0,1)[0]
        }
      },
      form: [
        {
          key: "graphvarX",
          onChange: function (evt) {
            calculate_forms();
            $("#plotdiv").calculate();
          }
        }
      ]
    };
    
    $("#yaxisform").html("");
    $("#yaxisform").jsonForm(jsonform);
    $("#xaxisform").html("");
    $("#xaxisform").jsonForm(jsonformX);
    $("#plotdiv").calculate();
    
}, false);

```

```js id=plotdiv
if (typeof(header) != "undefined") {
    yidx = header.indexOf(graphvar);
    xidx = header.indexOf(graphvarX);
    // pick out the column to plot
    series = x.slice(1).map(function(x) {return [x[xidx], x[yidx]];});
    plot([series]);
}
```

<div id="xaxisform" style="left:200px; width:300px; position:relative"> </div>

## Comments

This simulation model is from a [Modelica](http://modelica.org) model.
Modelica is a language for simulating electrical, thermal, and
mechanical, systems. [OpenModelica](http://openmodelica.org) was used
to compile this model to C. Then, [Emscripten](http://emscripten.org/)
was used to compile the C code to JavaScript.

For more information on compiling OpenModelica to JavaScript, see
[here](https://github.com/tshort/openmodelica-javascript).

The user interface was created in
[mdpad](http://tshort.github.io/mdpad/). See
[<%fileNamePrefix%>.md](<%fileNamePrefix%>.md) for the Markdown code
for this page.
>>
end markdownContents;

end CodegenJS;

// vim: filetype=susan sw=2 sts=2
