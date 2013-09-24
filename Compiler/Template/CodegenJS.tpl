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
- <%fileNamePrefix%>.js
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
$xml = $(xml)

// Set the default simulation parameters
defex = $xml.find("DefaultExperiment")
defex.attr("stopTime", stopTime)
defex.attr("stepSize", +stopTime / intervals)
defex.attr("tolerance", tolerance)
defex.attr("solver", solver)

// Set some model parameters

// Write out the initialization file
xmlstring = new XMLSerializer().serializeToString(xml)
Module['FS_createDataFile']('/', '<%fileNamePrefix%>_init.xml', xmlstring, true, true)

// Run the simulation!
run()

// delete the input file
FS.unlink('/<%fileNamePrefix%>_init.xml')
```

## Results

```js
// read the csv file with the simulation results
csv = intArrayToString(FS.findObject("<%fileNamePrefix%>_res.csv").contents)
x = $.csv.toArrays(csv, {onParseValue: $.csv.hooks.castToScalar})

// `header` has the column names. The first is the time, and the rest
// of the columns are the variables.
header = x.slice(0,1)[0].slice(1)

// Select graph variables with a select box based on the header values
if (typeof(graphvar) == "undefined") graphvar = header[0];

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

$active_element.jsonForm(jsonform);
```

```js id=plotdiv
idx = header.indexOf(graphvar) + 1;

// pick out the column to plot
series = x.slice(1).map(function(x) {return [x[0], x[idx]];});

plot([series]);
```

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
[chua.md](http://tshort.github.io/mdpad/chua.md) for the Markdown code
for this page.
>>
end markdownContents;

end CodegenJS;

// vim: filetype=susan sw=2 sts=2
