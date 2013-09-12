/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

function der "derivative of the input expression"
  input Real x(unit="'p");
  output Real dx(unit="'p/s");
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'der()'\">der()</a>
</html>"));
end der;

function initial
  output Boolean isInitial;
external "builtin";
annotation(__OpenModelica_Impure = true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'initial()'\">initial()</a>
</html>"));
end initial;

function terminal
  output Boolean isTerminal;
external "builtin";
annotation(__OpenModelica_Impure = true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'terminal()'\">terminal()</a>
</html>"));
end terminal;

type AssertionLevel = enumeration(error, warning) annotation(Documentation(info="<html>
  Used by <a href=\"modelica://assert\">assert()</a>
</html>"));

function assert
  input Boolean condition;
  input String message;
  input AssertionLevel level;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'assert()'\">assert()</a>
</html>"));
end assert;

function constrain
  input Real i1;
  input Real i2;
  input Real i3;
  output Real o1;
external "builtin";
annotation(version="Dymola / MSL 1.6");
end constrain;

function sample "Trigger time events"
  parameter input Real start(fixed=false);
  parameter input Real interval(fixed=false);
  output Boolean isSample;
external "builtin";
annotation(__OpenModelica_Impure = true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'sample()'\">sample()</a>
</html>"));
end sample;

function ceil "Round a real number towards plus infinity"
  input Real x;
  output Real y;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'ceil()'\">ceil()</a>
</html>"));
end ceil;

function floor "Round a real number towards minus infinity"
  input Real x;
  output Real y;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'floor()'\">floor()</a>
</html>"));
end floor;

function integer "Round a real number towards minus infinity"
  input Real x;
  output Integer y;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'integer()'\">integer()</a>
</html>"));
end integer;

function sqrt "Square root"
  input Real x(unit="'p");
  output Real y(unit="'p(1/2)");
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'sqrt()'\">sqrt()</a>
</html>"));
end sqrt;

function sign
  input Real v;
  output Integer _sign;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'sign()'\">sign()</a>
</html>"));
/* We do this with external "builtin" for now. But maybe we should inline it instead...
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  _sign := noEvent(if v > 0 then 1 else if v < 0 then -1 else 0);
 */
end sign;

function identity
  input Integer arraySize;
  output Integer[arraySize,arraySize] outArray;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'identity()'\">identity()</a>
</html>"));
end identity;

function semiLinear
  input Real x;
  input Real positiveSlope;
  input Real negativeSlope;
  output Real result;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'semiLinear()'\">semiLinear()</a>
</html>"));
end semiLinear;

function edge
  input Boolean b;
  output Boolean edgeEvent;
  // TODO: Ceval parameters? Needed to remove the builtin handler
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'edge()'\">edge()</a>
</html>"));
end edge;

function sin "Sine"
  input Real x;
  output Real y;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'sin()'\">sin()</a>
</html>"));
end sin;

function cos "Cosine"
  input Real x;
  output Real y;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'cos()'\">cos()</a>
</html>"));
end cos;

function tan "Tangent (u shall not be -pi/2, pi/2, 3*pi/2, ...)"
  input Real u;
  output Real y;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'tan()'\">tan()</a>
</html>"));
end tan;

function sinh "Hyperbolic sine"
  input Real x;
  output Real y;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'sinh()'\">sinh()</a>
</html>"));
end sinh;

function cosh "Hyperbolic cosine"
  input Real x;
  output Real y;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'cosh()'\">cosh()</a>
</html>"));
end cosh;

function tanh "Hyperbolic tangent"
  input Real x;
  output Real y;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'tanh()'\">tanh()</a>
</html>"));
end tanh;

function asin "Inverse sine (-1 <= u <= 1)"
  input Real u;
  output Real y;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'asin()'\">asin()</a>
</html>"));
end asin;

function acos "Inverse cosine (-1 <= u <= 1)"
  input Real u;
  output Real y;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'acos()'\">acos()</a>
</html>"));
end acos;

function atan "Inverse tangent"
  input Real x;
  output Real y;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'atan()'\">atan()</a>
</html>"));
end atan;

function atan2 "Four quadrant inverse tangent"
  input Real y;
  input Real x;
  output Real z;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'atan2()'\">atan2()</a>
</html>"));
end atan2;

function exp "Exponential, base e"
  input Real x(unit="1");
  output Real y(unit="1");
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'exp()'\">exp()</a>
</html>"));
end exp;

function log "Natural (base e) logarithm (u shall be > 0)"
  input Real u(unit="1");
  output Real y(unit="1");
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'log()'\">log()</a>
</html>"));
end log;

function log10 "Base 10 logarithm (u shall be > 0)"
  input Real u(unit="1");
  output Real y(unit="1");
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'log10()'\">log10()</a>
</html>"));
end log10;

function homotopy
  input Real actual;
  input Real simplified;
  output Real outValue;
external "builtin"
annotation(version="Modelica 3.2",Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'homotopy()'\">homotopy()</a> (experimental implementation)
</html>"));
end homotopy;

function linspace
  input Real x1 "start";
  input Real x2 "end";
  input Integer n "number";
  output Real v[n];
algorithm
  // assert(n >= 2, "linspace requires n>=2 but got " + String(n));
  v := {x1 + (x2-x1)*(i-1)/(n-1) for i in 1:n};
annotation(__OpenModelica_EarlyInline=true,Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'linspace()'\">linspace()</a>
</html>"));
end linspace;

function div = $overload(OpenModelica.Internal.intDiv,OpenModelica.Internal.realDiv)
  "Integer part of a division of two Real numbers"
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'div()'\">div()</a>
</html>"));

function mod = $overload(OpenModelica.Internal.intMod,OpenModelica.Internal.realMod)
  "Integer modulus of a division of two Real numbers"
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'mod()'\">mod()</a>
</html>"));

function rem = $overload(OpenModelica.Internal.intRem,OpenModelica.Internal.realRem)
  "Integer remainder of the division of two Real numbers"
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'rem()'\">rem()</a>
</html>"));

function abs = $overload(OpenModelica.Internal.intAbs,OpenModelica.Internal.realAbs)
  "Absolute value"
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'abs()'\">abs()</a>
</html>"));

function outerProduct "Outer product of two vectors"
  input Real[:] v1;
  input Real[:] v2;
  output Real[size(v1,1),size(v2,1)] o;
algorithm
  o := matrix(v1) * transpose(matrix(v2));
annotation(__OpenModelica_EarlyInline=true,preferredView="text",Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'outerProduct()'\">outerProduct()</a>
</html>"));
end outerProduct;

function cross "Cross product of two 3-vectors"
  input Real[3] x;
  input Real[3] y;
  output Real[3] z;
/* Not working due to problems with non-builtin overloaded functions? Maybe it works now. Maybe it's bad to inline due to evaluating the same element many times?
algorithm
  z := { x[2]*y[3]-x[3]*y[2] , x[3]*y[1]-x[1]*y[3] , x[1]*y[2]-x[2]*y[1] };
*/
external "builtin" cross(x,y,z);
  annotation(__OpenModelica_EarlyInline = true, preferredView="text",Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'cross()'\">cross()</a>
</html>"));
end cross;

function skew "The skew matrix associated with the vector"
  input Real[3] x;
  output Real[3,3] y;
external "builtin" skew(x,y);
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'skew()'\">skew()</a>
</html>"));
end skew;

// Dummy functions that can't be properly defined in Modelica, but used by
// SCodeFlatten to define which builtin functions exist (SCodeFlatten doesn't
// care how the functions are defined, only if they exist or not).

function delay "Delay expression"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'delay()'\">delay()</a>
</html>"));
end delay;

function min "Returns the smallest element"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'min()'\">min()</a>
</html>"));
end min;

function max "Returns the largest element"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'max()'\">max()</a>
</html>"));
end max;

function sum
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'sum()'\">sum()</a>
</html>"));
end sum;

function product
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'product()'\">product()</a>
</html>"));
end product;

function transpose
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'transpose()'\">transpose()</a>
</html>"));
end transpose;

function symmetric "Returns a symmetric matrix"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'symmetric()'\">symmetric()</a>
</html>"));
end symmetric;

function smooth "Indicate smoothness of expression"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'smooth()'\">smooth()</a>
</html>"));
end smooth;

function diagonal "Returns a diagonal matrix"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'diagonal()'\">diagonal()</a>
</html>"));
end diagonal;

function cardinality "Number of connectors in connection"
  input Real c;
  output Integer numOccurances;
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'cardinality()'\">cardinality()</a>
</html>"),version="Deprecated");
end cardinality;

function array
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'array()'\">array()</a>
</html>"));
end array;

function zeros "Returns a zero array"
  input Integer n annotation(__OpenModelica_varArgs=true);
  output Integer o[:];
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'zeros()'\">zeros()</a>
</html>"));
end zeros;

function ones "Returns a one array"
  input Integer n annotation(__OpenModelica_varArgs=true);
  output Integer o[:];
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'ones()'\">ones()</a>
</html>"));
end ones;

function fill "Returns an array with all elements equal"
  input OpenModelica.Internal.BuiltinType s;
  input Integer n annotation(__OpenModelica_varArgs=true);
  output OpenModelica.Internal.BuiltinType o[:];
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'fill()'\">fill()</a>
</html>"));
end fill;

function noEvent "Turn off event triggering"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'noEvent()'\">noEvent()</a>
</html>"));
end noEvent;

function pre "Refer to left limit"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'pre()'\">pre()</a>
</html>"));
end pre;

function change "Indicate discrete variable changing"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'change()'\">change()</a>
</html>"));
end change;

function reinit "Reinitialize state variable"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'reinit()'\">reinit()</a>
</html>"));
end reinit;

function ndims "Number of array dimensions"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'ndims()'\">ndims()</a>
</html>"));
end ndims;

function size "Returns dimensions of an array"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'size()'\">size()</a>
</html>"));
end size;

function scalar
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'scalar()'\">scalar()</a>
</html>"));
end scalar;

function vector
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'vector()'\">vector()</a>
</html>"));
end vector;

function matrix
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'matrix()'\">matrix()</a>
</html>"));
end matrix;

function cat
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'cat()'\">cat()</a>
</html>"));
end cat;

function rooted "Not yet standard Modelica, but in the MSL since 3-4 years now."
  external "builtin";
  annotation(Documentation(info="<html>
<p><b>Not yet standard Modelica, but in the MSL since 3-4 years now.</b></p>
<h4>Syntax</h4>
<blockquote>
<pre><b>rooted</b>(x)</pre>
</blockquote>
<h4>Description</h4>
<p>The operator \"rooted\" was introduced to improve efficiency:
A tool that constructs the graph with the Connections.branch/.root etc.
built-in operators has to cut the graph in order to arrive at \"spanning trees\".
If there is a statement \"Connections.branch(A,B)\", then \"rooted(A)\" returns true,
if \"A\" is closer to the root of the spanning tree as \"B\". Otherwise false is returned.
For the MultiBody library this allows to avoid unnecessary small linear systems of equations.
</p>
<h4>Known Bugs</h4>
<p>
OpenModelica, <b>rooted</b>(x) always returns true.
See <a href=\"https://trac.modelica.org/Modelica/ticket/95\">rooted ticket in the Modelica Trac</a> for details.
</p>
</html>"),version="Deprecated in the upcoming Modelica 3.2 rev2");
end rooted;

function actualStream
  external "builtin";
end actualStream;

function inStream
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'inStream()'\">inStream()</a>
</html>"));
end inStream;

/* Extension for uncertainty computations */
record Distribution
  String name "the name of the distibution, e.g \"normal\" ";
  Real params[:] "parameter values for the specified distribution, e.g {0,0.1} for a normal distribution";
  String paramNames[:/*should be size(params,1) but doesn't work, cb issue #1682*/] "the parameter names for the specified distribution, e.g {\"my\",\"sigma\"} for a normal distribution";
end Distribution;

record Correlation "defines correlation between two uncertainty variables"
   Real v1 "first variable";
   Real v2 "second variable";
   Real c "correlation value";
end Correlation;


encapsulated package Connections
  import OpenModelica.$Code.VariableName;

  function branch
    input VariableName node1;
    input VariableName node2;
    external "builtin";
  end branch;

  function root
    input VariableName node;
    external "builtin";
  end root;

  function potentialRoot
    input VariableName node;
    parameter input Integer priority = 0;
    external "builtin";
  end potentialRoot;

  function isRoot
    input VariableName node;
    output Boolean isroot;
    external "builtin";
  end isRoot;
end Connections;

encapsulated package Subtask
  type SamplingType = enumeration(Disabled, Continuous, Periodic);

  function decouple
    external "builtin";
  end decouple;

  function activated
    output Boolean activated;
    external "builtin";
  end activated;

  function lastInterval
    external "builtin";
  end lastInterval;
end Subtask;

function print "Prints to stdout, useful for debugging."
  input String str;
external "builtin";
annotation(__OpenModelica_Impure = true, version="OpenModelica extension");
end print;

function classDirectory "No clue what it does as it's not standardized"
  output String str;
external "builtin";
annotation(version="Dymola / MSL 2.2.1");
end classDirectory;

function getInstanceName
  output String instanceName;
external "builtin";
  annotation(Documentation(info="<html>
<h4>
Modelica definition:
</h4>
<p>
Returns a string with the name of the model/block that is simulated,
appended with the fully qualified name of the instance in which this
function is called.
</p>

<p>
If MyLib.Vehicle is simulated, the call of <b>getInstanceName()</b> might return:
  <em>Vehicle.engine.controller</em>
</p>
<p>
Outside of a model or block, the return value is not specified.
</p>

<h4>
OpenModelica specifics:
</h4>

<p>
When OpenModelica does not have a prefix (e.g. in functions or packages),
it returns the name of the function or package.
</p>

<p>
If no class was being simulated, the last simulated class or a default will be used
(applicable for functions called from the scripting environment).
</p>
</html>
"),version="Modelica 3.3");
end getInstanceName;

function spatialDistribution "Not yet implemented"
  input Real in0;
  input Real x;
  input Real initialPoints[:];
  input Real initialValues[size(initialPoints)];
  input Real in1;
  input Boolean positiveVelocity;
  output Real val;
external "builtin";
annotation(version="Modelica 3.3");
end spatialDistribution;

/* Actually contains more...
record SimulationResult
  String resultFile;
  String simulationOptions;
  String messages;
end SimulationResult; */

encapsulated package OpenModelica "OpenModelica internal defintions and scripting functions"

type $Code "Code quoting is not a uniontype yet because that would require enabling MetaModelica extensions in the regular compiler.
Besides, it has special semantics."

type Expression "An expression of some kind" end Expression;
type TypeName "A path, for example the name of a class, e.g. A.B.C or .A.B" end TypeName;
type VariableName "A variable name, e.g. a.b or a[1].b[3].c" end VariableName;
type VariableNames "An array of variable names, e.g. {a.b,a[1].b[3].c}, or a single VariableName" end VariableNames;

end $Code;

package Internal "Contains internal implementations, e.g. overloaded builtin functions"

  type BuiltinType "Integer,Real,String,enumeration or array of some kind"
  end BuiltinType;

  function intAbs
    input Integer v;
    output Integer o;
  external "builtin" o=abs(v);
  annotation(preferredView="text");
  end intAbs;

  function realAbs
    input Real v;
    output Real o;
  external "builtin" o=abs(v);
  annotation(preferredView="text");
  end realAbs;

  function intDiv
    input Integer x;
    input Integer y;
    output Integer z;
  external "builtin" z=div(x,y);
  annotation(preferredView="text");
  end intDiv;

  function realDiv
    input Real x;
    input Real y;
    output Real z;
  external "builtin" z=div(x,y);
  annotation(preferredView="text");
  end realDiv;

  function intMod
    input Integer x;
    input Integer y;
    output Integer z;
  external "builtin" z=mod(x,y);
  annotation(preferredView="text");
  end intMod;

  function realMod
    input Real x;
    input Real y;
    output Real z;
  external "builtin" z=mod(x,y);
  annotation(preferredView="text");
  end realMod;

  function intRem
    input Integer x;
    input Integer y;
    output Integer z;
  algorithm
    z := x - (div(x, y) * y);
  annotation(preferredView="text");
  end intRem;

  function realRem
    input Real x;
    input Real y;
    output Real z;
  algorithm
    z := x - (div(x, y) * y);
  annotation(preferredView="text");
  end realRem;

  package Architecture
    function numBits
      output Integer numBit;
      external "builtin";
    end numBits;
    function integerMax
      output Integer max;
      external "builtin";
    end integerMax;
  end Architecture;

annotation(preferredView="text");
end Internal;

package Scripting

import OpenModelica.$Code.Expression;
import OpenModelica.$Code.TypeName;
import OpenModelica.$Code.VariableName;
import OpenModelica.$Code.VariableNames;

record CheckSettingsResult
  String OPENMODELICAHOME, OPENMODELICALIBRARY, OMC_PATH, SYSTEM_PATH, OMDEV_PATH;
  Boolean OMC_FOUND;
  String MODELICAUSERCFLAGS, WORKING_DIRECTORY;
  Boolean CREATE_FILE_WORKS, REMOVE_FILE_WORKS;
  String OS, SYSTEM_INFO, SENDDATALIBS, C_COMPILER, C_COMPILER_VERSION;
  Boolean C_COMPILER_RESPONDING, HAVE_CORBA;
  String CONFIGURE_CMDLINE;
annotation(preferredView="text");
end CheckSettingsResult;

package Internal

package Time

/* From CevalScript */
constant Integer RT_CLOCK_SIMULATE_TOTAL = 8;
constant Integer RT_CLOCK_SIMULATE_SIMULATION = 9;
constant Integer RT_CLOCK_BUILD_MODEL = 10;
constant Integer RT_CLOCK_EXECSTAT_MAIN = 11;
constant Integer RT_CLOCK_EXECSTAT_BACKEND_MODULES = 12;
constant Integer RT_CLOCK_FRONTEND = 13;
constant Integer RT_CLOCK_BACKEND = 14;
constant Integer RT_CLOCK_SIMCODE = 15;
constant Integer RT_CLOCK_LINEARIZE = 16;
constant Integer RT_CLOCK_TEMPLATES = 17;
constant Integer RT_CLOCK_UNCERTAINTIES = 18;
constant Integer RT_CLOCK_USER_RESERVED = 19;

function readableTime
  input Real sec;
  output String str;
protected
  Integer tmp,min,hr;
algorithm
  tmp := mod(integer(sec),60);
  min := div(integer(sec),60);
  hr := div(min,60);
  min := mod(min,60);
  str := (if hr>0 then String(hr) + "h" else "") + (if min>0 then String(min) + "m" else "") + String(tmp) + "s";
end readableTime;

function timerTick
  input Integer index;
external "builtin";
annotation(Documentation(info="<html>
Starts the internal timer with the given index.
</html>"),preferredView="text");
end timerTick;

function timerTock
  input Integer index;
  output Real elapsed;
external "builtin";
annotation(Documentation(info="<html>
Reads the internal timer with the given index.
</html>"),preferredView="text");
end timerTock;

function timerClear
  input Integer index;
external "builtin";
annotation(Documentation(info="<html>
Clears the internal timer with the given index.
</html>"),preferredView="text");
end timerClear;

end Time;

type FileType = enumeration(NoFile, RegularFile, Directory, SpecialFile);

function stat
  input String name;
  output FileType fileType;
external "C" fileType = ModelicaInternal_stat(name) annotation(Library="ModelicaExternalC");
end stat;

end Internal;

function checkSettings "Display some diagnostics."
  output CheckSettingsResult result;
external "builtin";
annotation(preferredView="text");
end checkSettings;

function loadFile "load file (*.mo) and merge it with the loaded AST."
  input String fileName;
  input String encoding := "UTF-8";
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end loadFile;

function loadString "Parses the data and merges the resulting AST with ithe
  loaded AST.
  If a filename is given, it is used to provide error-messages as if the string
was read in binary format from a file with the same name.
  The file is converted to UTF-8 from the given character set.

  NOTE: Encoding is deprecated as *ALL* strings are now UTF-8 encoded.
  "
  input String data;
  input String filename := "<interactive>";
  input String encoding := "UTF-8";
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end loadString;

function parseString
  input String data;
  input String filename := "<interactive>";
  output TypeName names[:];
external "builtin";
annotation(preferredView="text");
end parseString;

function parseFile
  input String filename;
  input String encoding := "UTF-8";
  output TypeName names[:];
external "builtin";
annotation(preferredView="text");
end parseFile;

function loadFileInteractiveQualified
  input String filename;
  input String encoding := "UTF-8";
  output TypeName names[:];
external "builtin";
annotation(preferredView="text");
end loadFileInteractiveQualified;

function loadFileInteractive
  input String filename;
  input String encoding := "UTF-8";
  output TypeName names[:];
external "builtin";
annotation(preferredView="text");
end loadFileInteractive;

function system "Similar to system(3). Executes the given command in the system shell."
  input String callStr "String to call: bash -c $callStr";
  output Integer retval "Return value of the system call; usually 0 on success";
external "builtin" annotation(__OpenModelica_Impure=true);
annotation(preferredView="text");
end system;

function system_parallel "Similar to system(3). Executes the given commands in the system shell, in parallel if omc was compiled using OpenMP."
  input String callStr[:] "String to call: bash -c $callStr";
  input Integer numThreads := numProcessors();
  output Integer retval[:] "Return value of the system call; usually 0 on success";
external "builtin" annotation(__OpenModelica_Impure=true);
annotation(preferredView="text");
end system_parallel;

function saveAll "save the entire loaded AST to file."
  input String fileName;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end saveAll;

function help "display the OpenModelica help text."
  input String topic := "topics";
  output String helpText;
external "builtin";
end help;

function clear "Clears everything: symboltable and variables."
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end clear;

function clearVariables "Clear all user defined variables."
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end clearVariables;

function generateHeader
  input String fileName;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end generateHeader;

function generateSeparateCode
  input TypeName className[:] := fill($TypeName(AllLoadedClasses),0);
  input Boolean cleanCache := false "If true, the cache is reset between each generated package. This conserves memory at the cost of speed.";
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html><p>Under construction.</p>
</html>"),preferredView="text");
end generateSeparateCode;

function generateSeparateCodeDependencies
  input String stampSuffix := ".c" "Suffix to add to dependencies (often .c.stamp)";
  output String [:] dependencies;
external "builtin";
annotation(Documentation(info="<html><p>Under construction.</p>
</html>"),preferredView="text");
end generateSeparateCodeDependencies;

function getLinker
  output String linker;
external "builtin";
annotation(preferredView="text");
end getLinker;

function setLinker
  input String linker;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setLinker;

function getLinkerFlags
  output String linkerFlags;
external "builtin";
annotation(preferredView="text");
end getLinkerFlags;

function setLinkerFlags
  input String linkerFlags;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setLinkerFlags;

function getCompiler "CC"
  output String compiler;
external "builtin";
annotation(preferredView="text");
end getCompiler;

function setCompiler "CC"
  input String compiler;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setCompiler;

function setCFlags "CFLAGS"
  input String inString;
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
Sets the CFLAGS passed to the C-compiler. Remember to add -fPIC if you are on a 64-bit platform. If you want to see the defaults before you modify this variable, check the output of <a href=\"modelica://OpenModelica.Scripting.getCFlags\">getCFlags()</a>. ${SIM_OR_DYNLOAD_OPT_LEVEL} can be used to get a default lower optimization level for dynamically loaded functions. And ${MODELICAUSERCFLAGS} is nice to add so you can easily modify the CFLAGS later by using an environment variable.
</html>"),
  preferredView="text");
end setCFlags;

public function getCFlags "CFLAGS"
  output String outString;
external "builtin";
annotation(Documentation(info="<html>
See <a href=\"modelica://OpenModelica.Scripting.setCFlags\">setCFlags()</a> for details.
</html>"),
  preferredView="text");
end getCFlags;

function getCXXCompiler "CXX"
  output String compiler;
external "builtin";
annotation(preferredView="text");
end getCXXCompiler;

function setCXXCompiler "CXX"
  input String compiler;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setCXXCompiler;

function verifyCompiler
  output Boolean compilerWorks;
external "builtin";
annotation(preferredView="text");
end verifyCompiler;

function setCompilerPath
  input String compilerPath;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setCompilerPath;

function getCompileCommand
  output String compileCommand;
external "builtin";
annotation(preferredView="text");
end getCompileCommand;

function setCompileCommand
  input String compileCommand;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setCompileCommand;

function setPlotCommand
  input String plotCommand;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setPlotCommand;

function getSettings
  output String settings;
algorithm
  settings :=
    "Compile command: " + getCompileCommand() + "\n" +
    "Temp folder path: " + getTempDirectoryPath() + "\n" +
    "Installation folder: " + getInstallationDirectoryPath() + "\n" +
    "Modelica path: " + getModelicaPath() + "\n";
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end getSettings;

function setTempDirectoryPath
  input String tempDirectoryPath;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setTempDirectoryPath;

function getTempDirectoryPath "Returns the current user temporary directory location."
  output String tempDirectoryPath;
external "builtin";
annotation(preferredView="text");
end getTempDirectoryPath;

function getEnvironmentVar "Returns the value of the environment variable."
  input String var;
  output String value "returns empty string on failure";
external "builtin";
annotation(preferredView="text");
end getEnvironmentVar;

function setEnvironmentVar
  input String var;
  input String value;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setEnvironmentVar;

function appendEnvironmentVar "Appends a variable to the environment variables list."
  input String var;
  input String value;
  output String result "returns \"error\" if the variable could not be appended";
algorithm
  result := if setEnvironmentVar(var,getEnvironmentVar(var)+value) then getEnvironmentVar(var) else "error";
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end appendEnvironmentVar;

function setInstallationDirectoryPath "Sets the OPENMODELICAHOME environment variable. Use this method instead of setEnvironmentVar."
  input String installationDirectoryPath;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setInstallationDirectoryPath;

function getInstallationDirectoryPath "This returns OPENMODELICAHOME if it is set; on some platforms the default path is returned if it is not set."
  output String installationDirectoryPath;
external "builtin";
annotation(preferredView="text");
end getInstallationDirectoryPath;

function setModelicaPath "The Modelica Library Path - MODELICAPATH in the language specification; OPENMODELICALIBRARY in OpenModelica."
  input String modelicaPath;
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
See <a href=\"modelica://OpenModelica.Scripting.loadModel\">loadModel()</a> for a description of what the MODELICAPATH is used for.
</html>"),
  preferredView="text");
end setModelicaPath;

function getModelicaPath "Get the Modelica Library Path."
  output String modelicaPath;
external "builtin";
annotation(Documentation(info="<html>
<p>The MODELICAPATH is list of paths to search when trying to  <a href=\"modelica://OpenModelica.Scripting.loadModel\">load a library</a>. It is a string separated by colon (:) on all OSes except Windows, which uses semicolon (;).</p>
<p>To override the default path (<a href=\"modelica://OpenModelica.Scripting.getModelicaPath\">getModelicaPath()</a>/lib/omlibrary/:~/.openmodelica/libraries/), set the environment variable OPENMODELICALIBRARY=...</p>
</html>"),
  preferredView="text");
end getModelicaPath;

function setCompilerFlags
  input String compilerFlags;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setCompilerFlags;

function setDebugFlags "example input: failtrace,-noevalfunc"
  input String debugFlags;
  output Boolean success;
algorithm
  success := setCommandLineOptions("+d=" + debugFlags);
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setDebugFlags;

function setPreOptModules "example input: removeFinalParameters,removeSimpleEquations,expandDerOperator"
  input String modules;
  output Boolean success;
algorithm
  success := setCommandLineOptions("+preOptModules=" + modules);
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setPreOptModules;

function setCheapMatchingAlgorithm "example input: 3"
  input Integer matchingAlgorithm;
  output Boolean success;
algorithm
  success := setCommandLineOptions("+cheapmatchingAlgorithm=" + String(matchingAlgorithm));
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setCheapMatchingAlgorithm;

function getMatchingAlgorithm
  output String selected;
  external "builtin";
end getMatchingAlgorithm;

function getAvailableMatchingAlgorithms
  output String[:] allChoices;
  output String[:] allComments;
  external "builtin";
end getAvailableMatchingAlgorithms;

function setMatchingAlgorithm "example input: omc"
  input String matchingAlgorithm;
  output Boolean success;
algorithm
  success := setCommandLineOptions("+matchingAlgorithm=" + matchingAlgorithm);
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setMatchingAlgorithm;

function getIndexReductionMethod
  output String selected;
  external "builtin";
end getIndexReductionMethod;

function getAvailableIndexReductionMethods
  output String[:] allChoices;
  output String[:] allComments;
  external "builtin";
end getAvailableIndexReductionMethods;

function setIndexReductionMethod "example input: dynamicStateSelection"
  input String method;
  output Boolean success;
algorithm
  success := setCommandLineOptions("+indexReductionMethod=" + method);
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setIndexReductionMethod;

function setPostOptModules "example input: lateInline,inlineArrayEqn,removeSimpleEquations."
  input String modules;
  output Boolean success;
algorithm
  success := setCommandLineOptions("+postOptModules=" + modules);
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setPostOptModules;

function getTearingMethod
  output String selected;
  external "builtin";
end getTearingMethod;

function getAvailableTearingMethods
  output String[:] allChoices;
  output String[:] allComments;
  external "builtin";
end getAvailableTearingMethods;

function setTearingMethod "example input: omcTearing"
  input String tearingMethod;
  output Boolean success;
algorithm
  success := setCommandLineOptions("+tearingMethod=" + tearingMethod);
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setTearingMethod;

function setCommandLineOptions
  "The input is a regular command-line flag given to OMC, e.g. +d=failtrace or +g=MetaModelica"
  input String option;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setCommandLineOptions;

function clearCommandLineOptions
  "Resets all commdand-line flags to their default values."
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end clearCommandLineOptions;

function getVersion "Returns the version of the Modelica compiler."
  input TypeName cl := $TypeName(OpenModelica);
  output String version;
external "builtin";
annotation(preferredView="text");
end getVersion;

function regularFileExists
  input String fileName;
  output Boolean exists;
algorithm
  exists := Internal.stat(fileName) == Internal.FileType.RegularFile;
end regularFileExists;

function directoryExists
  input String dirName;
  output Boolean exists;
algorithm
  exists := Internal.stat(dirName) == Internal.FileType.Directory;
end directoryExists;

function readFile
  "The contents of the given file are returned.
  Note that if the function fails, the error message is returned as a string instead of multiple output or similar."
  input String fileName;
  output String contents;
external "builtin" annotation(__OpenModelica_Impure=true);
annotation(preferredView="text");
end readFile;

function writeFile
  "Write the data to file. Returns true on success."
  input String fileName;
  input String data;
  input Boolean append := false;
  output Boolean success;
external "builtin" annotation(__OpenModelica_Impure=true);
annotation(preferredView="text");
end writeFile;

function regex  "Sets the error buffer and returns -1 if the regex does not compile.

  The returned result is the same as POSIX regex():
  The first value is the complete matched string
  The rest are the substrings that you wanted.
  For example:
  regex(lorem,\" \\([A-Za-z]*\\) \\([A-Za-z]*\\) \",maxMatches=3)
  => {\" ipsum dolor \",\"ipsum\",\"dolor\"}
  This means if you have n groups, you want maxMatches=n+1
"
  input String str;
  input String re;
  input Integer maxMatches := 1 "The maximum number of matches that will be returned";
  input Boolean extended := true "Use POSIX extended or regular syntax";
  input Boolean caseInsensitive := false;
  output Integer numMatches "-1 is an error, 0 means no match, else returns a number 1..maxMatches";
  output String matchedSubstrings[maxMatches] "unmatched strings are returned as empty";
external "C" numMatches = OpenModelica_regex(str,re,maxMatches,extended,caseInsensitive,matchedSubstrings);
annotation(preferredView="text");
end regex;

function regexBool "Returns true if the string matches the regular expression."
  input String str;
  input String re;
  input Boolean extended := true "Use POSIX extended or regular syntax";
  input Boolean caseInsensitive := false;
  output Boolean matches;
protected
  Integer numMatches;
algorithm
  numMatches := regex(str,re,0,extended,caseInsensitive);
  matches := numMatches == 1;
annotation(preferredView="text");
end regexBool;

function testsuiteFriendlyName
  input String path;
  output String fixed;
protected
  Integer i;
  String matches[4];
algorithm
  (i,matches) := regex(path, "^(.*/testsuite/)?(.*/build/)?(.*)",4);
  fixed := matches[i];
end testsuiteFriendlyName;

function readFileNoNumeric
  "Returns the contents of the file, with anything resembling a (real) number stripped out, and at the end adding:
  Filter count from number domain: n.
  This should probably be changed to multiple outputs; the filtered string and an integer.
  Does anyone use this API call?"
  input String fileName;
  output String contents;
external "builtin";
annotation(preferredView="text");
end readFileNoNumeric;

function getErrorString "Returns the current error message. [file.mo:n:n-n:n:b] Error: message"
  output String errorString;
external "builtin";
annotation(preferredView="text");
end getErrorString;

function getMessagesString
  "see getErrorString()"
  output String messagesString;
external "builtin" messagesString=getErrorString();
annotation(preferredView="text");
end getMessagesString;

record SourceInfo
  String filename;
  Boolean readonly;
  Integer lineStart;
  Integer columnStart;
  Integer lineEnd;
  Integer columnEnd;
annotation(preferredView="text");
end SourceInfo;

type ErrorKind = enumeration(
  syntax "syntax errors",
  grammar "grammatical errors",
  translation "instantiation errors: up to flat modelica",
  symbolic "symbolic manipulation error, simcodegen, up to executable file",
  runtime "simulation/function runtime error",
  scripting "runtime scripting /interpretation error"
);
type ErrorLevel = enumeration(notification,warning,error);

record ErrorMessage
  SourceInfo info;
  String message "After applying the individual arguments";
  ErrorKind kind;
  ErrorLevel level;
  Integer id "Internal ID of the error (just ignore this)";
annotation(preferredView="text");
end ErrorMessage;

function getMessagesStringInternal
  "{{[file.mo:n:n-n:n:b] Error: message, TRANSLATION, Error, code}}"
  output ErrorMessage[:] messagesString;
external "builtin";
annotation(preferredView="text");
end getMessagesStringInternal;

function clearMessages "Clears the error buffer."
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end clearMessages;

function runScript "Runs the mos-script specified by the filename."
  input String fileName "*.mos";
  output String result;
external "builtin";
annotation(preferredView="text");
end runScript;

function echo "echo(false) disables Interactive output, echo(true) enables it again."
  input Boolean setEcho;
  output Boolean newEcho;
external "builtin";
annotation(preferredView="text");
end echo;

function getClassesInModelicaPath "MathCore-specific or not? Who knows!"
  output String classesInModelicaPath;
external "builtin";
annotation(preferredView="text");
end getClassesInModelicaPath;

function strictRMLCheck "Checks if any loaded function."
  output String message "empty if there was no problem";
external "builtin";
annotation(preferredView="text");
end strictRMLCheck;

/* These don't influence anything...
function getClassNamesForSimulation
  output String classNamesForSimulation;
external "builtin";
end getClassNamesForSimulation;

function setClassNamesForSimulation
  input String classNamesForSimulation;
  output Boolean success;
external "builtin";
end setClassNamesForSimulation;
*/

function getAnnotationVersion "Returns the current annotation version."
  output String annotationVersion;
external "builtin";
annotation(preferredView="text");
end getAnnotationVersion;

function setAnnotationVersion "Sets the annotation version."
  input String annotationVersion;
  output Boolean success;
algorithm
  success := setCommandLineOptions("+annotationVersion=" + annotationVersion);
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setAnnotationVersion;

function getNoSimplify "Returns true if noSimplify flag is set."
  output Boolean noSimplify;
external "builtin";
annotation(preferredView="text");
end getNoSimplify;

function setNoSimplify "Sets the noSimplify flag."
  input Boolean noSimplify;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setNoSimplify;

function getVectorizationLimit
  output Integer vectorizationLimit;
external "builtin";
annotation(preferredView="text");
end getVectorizationLimit;

function setVectorizationLimit
  input Integer vectorizationLimit;
  output Boolean success;
algorithm
  success := setCommandLineOptions("+v=" + String(vectorizationLimit));
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setVectorizationLimit;

public function getDefaultOpenCLDevice
  "Returns the id for the default OpenCL device to be used."
  output Integer defdevid;
external "builtin";
annotation(preferredView="text");
end getDefaultOpenCLDevice;

public function setDefaultOpenCLDevice
  "Sets the default OpenCL device to be used."
  input Integer defdevid;
  output Boolean success;
algorithm
  success := setCommandLineOptions("+o=" + String(defdevid));
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setDefaultOpenCLDevice;

function setShowAnnotations
  input Boolean show;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setShowAnnotations;

function getShowAnnotations
  output Boolean show;
external "builtin";
annotation(preferredView="text");
end getShowAnnotations;

function setOrderConnections "Sets the orderConnection flag."
  input Boolean orderConnections;
  output Boolean success;
algorithm
  success := setCommandLineOptions("+orderConnections=" + String(orderConnections));
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setOrderConnections;

function getOrderConnections "Returns true if orderConnections flag is set."
  output Boolean orderConnections;
external "builtin";
annotation(preferredView="text");
end getOrderConnections;

function setLanguageStandard "Sets the Modelica Language Standard."
  input String inVersion;
  output Boolean success;
algorithm
  success := setCommandLineOptions("+std=" + inVersion);
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setLanguageStandard;

function getLanguageStandard "Returns the current Modelica Language Standard in use."
  output String outVersion;
external "builtin";
annotation(preferredView="text");
end getLanguageStandard;

function getAstAsCorbaString "Print the whole AST on the CORBA format for records, e.g.
  record Absyn.PROGRAM
    classes = ...,
    within_ = ...,
    globalBuildTimes = ...
  end Absyn.PROGRAM;"
  input String fileName := "<interactive>";
  output String result "returns the string if fileName is interactive; else it returns ok or error depending on if writing the file succeeded";
external "builtin";
annotation(preferredView="text");
end getAstAsCorbaString;

function cd "change directory to the given path (which may be either relative or absolute)
  returns the new working directory on success or a message on failure
  if the given path is the empty string, the function simply returns the current working directory."
  input String newWorkingDirectory := "";
  output String workingDirectory;
external "builtin";
annotation(preferredView="text");
end cd;

function mkdir "create directory of given path (which may be either relative or absolute)
  returns true if directory was created or already exists."
  input String newDirectory;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end mkdir;

function remove "removes a file or directory of given path (which may be either relative or absolute)
  returns 0 if path was removed successfully."
  input String newDirectory;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end remove;

function checkModel "Checks a model and returns number of variables and equations."
  input TypeName className;
  output String result;
external "builtin";
annotation(preferredView="text");
end checkModel;

function checkAllModelsRecursive "Checks all models recursively and returns number of variables and equations."
  input TypeName className;
  input Boolean checkProtected := false "Checks also protected classes if true";
  output String result;
external "builtin";
annotation(preferredView="text");
end checkAllModelsRecursive;

function typeOf
  input VariableName variableName;
  output String result;
external "builtin";
annotation(preferredView="text");
end typeOf;

function instantiateModel "Instantiates the class and returns the flat Modelica code."
  input TypeName className;
  output String result;
external "builtin";
annotation(preferredView="text");
end instantiateModel;

function buildOpenTURNSInterface "generates wrapper code for OpenTURNS"
  input TypeName className;
  input String pythonTemplateFile;
  input Boolean showFlatModelica := false;
  output String outPythonScript;
  external "builtin";
end buildOpenTURNSInterface;

function runOpenTURNSPythonScript "runs OpenTURNS with the given python script returning the log file"
  input String pythonScriptFile;
  output String logOutputFile;
  external "builtin";
end runOpenTURNSPythonScript;

function generateCode "The input is a function name for which C-code is generated and compiled into a dll/so"
  input TypeName className;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end generateCode;

function loadModel "Loads the Modelica Standard Library."
  input TypeName className;
  input String[:] priorityVersion := {"default"};
  input Boolean notify := false "Give a notification of the libraries and versions that were loaded";
  input String languageStandard := "" "Override the set language standard. Parse with the given setting, but do not change it permanently.";
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
Loads a Modelica library.
<h4>Syntax</h4>
<blockquote>
<pre><b>loadModel</b>(Modelica)</pre>
<pre><b>loadModel</b>(Modelica,{\"3.2\"})</pre>
</blockquote>
<h4>Description</h4>
<p>loadModel() begins by parsing the <a href=\"modelica://OpenModelica.Scripting.getModelicaPath\">getModelicaPath()</a>, and looking for candidate packages to load in the given paths (separated by : or ; depending on OS).</p>
<p>The candidate is selected by choosing the one with the highest priority, chosen by looking through the <i>priorityVersion</i> argument to the function.
If the version searched for is \"default\", the following special priority is used: no version name > highest main release > highest pre-release > lexical sort of others (see table below for examples).
If none of the searched versions exist, false is returned and an error is added to the buffer.</p>
<p>A top-level package may either be defined in a file (\"Modelica 3.2.mo\") or directory (\"Modelica 3.2/package.mo\")</p>
<p>The encoding of any Modelica file in the package is assumed to be UTF-8.
Legacy code may contain files in a different encoding.
In order to handle this, add a file package.encoding at the top-level of the package, containing a single line with the name of the encoding in it.
If your package contains files with mixed encodings and your system iconv supports UTF-8//IGNORE, you can ignore the bad characters in some of the files.
You are recommended to convert your files to UTF-8 without byte-order mark.
</p>

<table summary=\"Modelica version numbering\">
<tr><th>Priority</th><th>Example</th></tr>
<tr><td>No version name</td><td>Modelica</td></tr>
<tr><td>Main release</td><td>Modelica 3.3</td></tr>
<tr><td>Pre-release</td><td>Modelica 3.3 Beta 1</td></tr>
<tr><td>Non-ordered</td><td>Modelica Trunk</td></tr>
</table>

<h4>Bugs</h4>
<p>If loadModel(Modelica.XXX) is called, loadModel(Modelica) is executed instead, loading the complete library.</p>
</html>"),
preferredView="text");
end loadModel;

function deleteFile "Deletes a file with the given name."
  input String fileName;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end deleteFile;

function saveModel
  input String fileName;
  input TypeName className;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end saveModel;

function saveTotalModel
  input String fileName;
  input TypeName className;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end saveTotalModel;

function save
  input TypeName className;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end save;

function saveTotalSCode
  input String fileName;
  input TypeName className;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end saveTotalSCode;

function translateGraphics
  input TypeName className;
  output String result;
external "builtin";
annotation(preferredView="text");
end translateGraphics;

function codeToString
  input $Code className;
  output String string;
external "builtin";
annotation(preferredView="text");
end codeToString;

function dumpXMLDAE "Outputs the DAE system corresponding to a specific model."
  input TypeName className;
  input String translationLevel := "flat";
  input Boolean addOriginalIncidenceMatrix := false;
  input Boolean addSolvingInfo := false;
  input Boolean addMathMLCode := false;
  input Boolean dumpResiduals := false;
  input String fileNamePrefix := "<default>" "this is the className in string form by default";
  output String result[2] "Contents, Message/Filename; why is this an array and not 2 output arguments?";
external "builtin";
annotation(preferredView="text");
end dumpXMLDAE;

function listVariables "Lists the names of the active variables in the scripting environment."
  output TypeName variables[:];
external "builtin";
annotation(preferredView="text");
end listVariables;

function strtok "Splits the strings at the places given by the token, for example:
  strtok(\"abcbdef\",\"b\") => {\"a\",\"c\",\"def\"}"
  input String string;
  input String token;
  output String[:] strings;
external "builtin";
annotation(preferredView="text");
end strtok;

public function stringReplace
  input String str;
  input String source;
  input String target;
  output String res;
external "builtin";
annotation(Documentation(info="<html>
Replaces all occurances of the string <em>source</em> with <em>target</em>.
</html>"),preferredView="text");
end stringReplace;

public function escapeXML
  input String inStr;
  output String outStr;
algorithm
  outStr := stringReplace(inStr, "&", "&amp;");
  outStr := stringReplace(outStr, "<", "&lt;");
  outStr := stringReplace(outStr, ">", "&gt;");
  outStr := stringReplace(outStr, "\"", "&quot;");
end escapeXML;

type ExportKind = enumeration(Absyn "Normal Absyn",SCode "Normal SCode",Internal "True unparsing of the Absyn");

function list "Lists the contents of the given class, or all loaded classes."
  input TypeName class_ := $TypeName(AllLoadedClasses);
  input Boolean interfaceOnly := false;
  input Boolean shortOnly := false "only short class definitions";
  input ExportKind exportKind := ExportKind.Absyn;
  output String contents;
external "builtin";
annotation(Documentation(info="<html>
Pretty-prints a class definition.
<h4>Syntax</h4>
<blockquote>
<pre><b>list</b>(Modelica.Math.sin)</pre>
<pre><b>list</b>(Modelica.Math.sin,interfaceOnly=true)</pre>
</blockquote>
<h4>Description</h4>
<p>list() pretty-prints the whole of the loaded AST while list(className) lists a class and its children.
It keeps all annotations and comments intact but strips out any comments and normalizes white-space.</p>
<p>list(className,interfaceOnly=true) works on functions and pretty-prints only the interface parts
(annotations and protected sections removed). String-comments on public variables are kept.</p>
<p>If the specified class does not exist (or is not a function when interfaceOnly is given), the
empty string is returned.</p>
</html>",revisions="<html>
<table>
<tr><th>Revision</th><th>Author</th><th>Comment</th></tr>
<tr><td>16124</td><td>sjoelund.se</td><td>Added replaced exportAsCode option with exportKind (selecting which kind of unparsing to use)</td></tr>
<tr><td>10796</td><td>sjoelund.se</td><td>Added shortOnly option</td></tr>
<tr><td>10756</td><td>sjoelund.se</td><td>Added interfaceOnly option</td></tr>
</table>
</html>"),
  preferredView="text");
end list;

function realpath "Get full path name of file or directory name"
  input String name "Absolute or relative file or directory name";
  output String fullName "Full path of 'name'";
external "C" fullName = ModelicaInternal_fullPathName(name) annotation(Library="ModelicaExternalC");
  annotation (Documentation(info="<html>
Return the canonicalized absolute pathname.
Similar to <a href=\"http://linux.die.net/man/3/realpath\">realpath(3)</a>, but with the safety of Modelica strings.
</html>"));
end realpath;

function uriToFilename
  input String uri;
  output String filename := "";
  output String message := "";
protected
  String [:,2] libraries;
  Integer numMatches;
  String [:] matches,matches2;
  String path, schema, str;
  Boolean isUri,isMatch:=false,isModelicaUri,isFileUri,isFileUriAbsolute;
algorithm
  isUri := regexBool(uri, "^[A-Za-z]*://");
  if isUri then
    (numMatches,matches) := regex(uri,"^[A-Za-z]*://?([^/]*)(.*)$",4);
    isModelicaUri := regexBool(uri, "^modelica://", caseInsensitive=true);
    isFileUriAbsolute := regexBool(uri, "^file:///", caseInsensitive=true);
    isFileUri := regexBool(uri, "^file://", caseInsensitive=true);
    if isModelicaUri then
      libraries := getLoadedLibraries();
      if sum(1 for lib in libraries) == 0 then
        filename := "";
        return;
      end if;
      path := matches[2];
      if path == "" then
        message := "Malformed modelica:// URI path. Package name '" + matches[2]+"', path: '"+matches[3] + "'";
        return;
      end if;
      while path <> "" loop
        (numMatches,matches2) := regex(path, "^([A-Za-z_][A-Za-z0-9_]*)?[.]?(.*)?$",3);
        path := matches2[3];
        if isMatch then
          /* We already have a match for the first part. The full name was e.g. Modelica.Blocks, so we now see if the Blocks directory exists, and so on */
          if directoryExists(filename + "/" + matches2[2]) then
            filename := realpath(filename + "/" + matches2[2]);
          else
            break;
          end if;
        else
          /* It is the first part of the name (Modelica.XXX) - look among the loaded classes for the name Modelica and use that path */
          for i in 1:sum(1 for lib in libraries) loop
            if libraries[i,1] == matches2[2] then
              filename := libraries[i,2];
              isMatch := true;
              break;
            end if;
          end for;
          if not isMatch then
            message := "Could not resolve URI: " + uri;
            filename := "";
            return;
          end if;
        end if;
      end while;
      filename := if isMatch then filename + matches[3] else filename;
    elseif isFileUriAbsolute then
      (,matches) := regex(uri,"file://(/.*)?",2,caseInsensitive=true);
      filename := matches[2];
    elseif isFileUri and not isFileUriAbsolute then
      (,matches) := regex(uri,"file://(.*)",2,caseInsensitive=true);
      filename := realpath("./") + "/" + matches[2];
      return;
    elseif not (isModelicaUri or isFileUri) then
      /* Not using else because OpenModelica handling of assertions at runtime is not very good */
      message := "Unknown URI schema: " + uri;
      filename := "";
      return;
    else
      /* empty */
      message := "Unknown error";
      filename := "";
    end if;
  else
    filename := if regularFileExists(uri) then realpath(uri) else if regexBool(uri, "^/") then uri else (realpath("./") + "/" + uri);
  end if;
annotation(Documentation(info="<html>
Handles modelica:// and file:// URI's. The result is an absolute path on the local system.
modelica:// URI's are only handled if the class is already loaded.
Returns the empty string on failure.
</html>"));
end uriToFilename;

function getLoadedLibraries
  output String [:,2] libraries;
external "builtin";
annotation(Documentation(info="<html>
Returns a list of names of libraries and their path on the system, for example:
<pre>{{\"Modelica\",\"/usr/lib/omlibrary/Modelica 3.2.1\"},{\"ModelicaServices\",\"/usr/lib/omlibrary/ModelicaServices 3.2.1\"}}</pre>
</html>"));
end getLoadedLibraries;

type LinearSystemSolver = enumeration(dgesv,lpsolve55);
function solveLinearSystem
  "Solve A*X = B, using dgesv or lp_solve (if any variable in X is integer)
  Returns for solver dgesv: info>0: Singular for element i. info<0: Bad input.
  For solver lp_solve: ???"
  input Real[size(B,1),size(B,1)] A;
  input Real[:] B;
  input LinearSystemSolver solver := LinearSystemSolver.dgesv;
  input Integer[:] isInt := {-1} "list of indices that are integers";
  output Real[size(B,1)] X;
  output Integer info;
external "builtin";
annotation(preferredView="text");
end solveLinearSystem;

type StandardStream = enumeration(stdin,stdout,stderr);
function reopenStandardStream
  input StandardStream _stream;
  input String filename;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end reopenStandardStream;

function importFMUOld "Imports the Functional Mockup Unit
  Example command:
  importFMUOld(\"A.fmu\");"
  input String filename "the fmu file name";
  input String workdir := "<default>" "The output directory for imported FMU files. <default> will put the files to current working directory.";
  output Boolean success "Returns true on success";
external "builtin";
annotation(preferredView="text");
end importFMUOld;

/* Under Development */
function importFMU "Imports the Functional Mockup Unit
  Example command:
  importFMU(\"A.fmu\");"
  input String filename "the fmu file name";
  input String workdir := "<default>" "The output directory for imported FMU files. <default> will put the files to current working directory.";
  input Integer loglevel := 3 "loglevel_nothing=0;loglevel_fatal=1;loglevel_error=2;loglevel_warning=3;loglevel_info=4;loglevel_verbose=5;loglevel_debug=6";
  input Boolean fullPath := false "When true the full output path is returned otherwise only the file name.";
  input Boolean debugLogging := false "When true the FMU's debug output is printed.";
  input Boolean generateInputConnectors := true "When true creates the input connector pins.";
  input Boolean generateOutputConnectors := true "When true creates the output connector pins.";
  output String generatedFileName "Returns the full path of the generated file.";
external "builtin";
annotation(preferredView="text");
end importFMU;
/* Under Development */

function simulate "simulates a modelica model by generating c code, build it and run the simulation executable.
 The only required argument is the className, while all others have some default values.
 simulate(className, [startTime], [stopTime], [numberOfIntervals], [stepSize], [tolerance], [method], [fileNamePrefix], [options], [outputFormat], [variableFilter], [measureTime], [cflags], [simflags])
 Example command:
  simulate(A);
"
  input TypeName className "the class that should simulated";
  input Real startTime := "<default>" "the start time of the simulation. <default> = 0.0";
  input Real stopTime := 1.0 "the stop time of the simulation. <default> = 1.0";
  input Real numberOfIntervals := 500 "number of intervals in the result file. <default> = 500";
  input Real stepSize := 0.002 "step size that is used for the result file. <default> = 0.002";
  input Real tolerance := 1e-6 "tolerance used by the integration method. <default> = 1e-6";
  input String method := "<default>" "integration method used for simulation. <default> = dassl";
  input String fileNamePrefix := "<default>" "fileNamePrefix. <default> = \"\"";
  input Boolean storeInTemp := false "storeInTemp. <default> = false";
  input Boolean noClean := false "noClean. <default> = false";
  input String options := "<default>" "options. <default> = \"\"";
  input String outputFormat := "mat" "Format for the result file. <default> = \"mat\"";
  input String variableFilter := ".*" "Filter for variables that should store in result file. <default> = \".*\"";
  input Boolean measureTime := false "creates a html file with proffiling data for model simulation. <default> = false";
  input String cflags := "<default>" "cflags. <default> = \"\"";
  input String simflags := "<default>" "simflags. <default> = \"\"";
  output String simulationResults;
external "builtin";
annotation(preferredView="text");
end simulate;

function moveClass 
"moves a class up or down depending on the given direction,
 it returns true if the move was performed or false if we
 could not move the class"
 input TypeName className "the class that should be moved";
 input String direction "up or down";
 output Boolean result;
end moveClass;

function linearize "creates a model with symbolic linearization matrixes"
  input TypeName className "the class that should simulated";
  input Real startTime := "<default>" "the start time of the simulation. <default> = 0.0";
  input Real stopTime := 1.0 "the stop time of the simulation. <default> = 1.0";
  input Real numberOfIntervals := 500 "number of intervals in the result file. <default> = 500";
  input Real stepSize := 0.002 "step size that is used for the result file. <default> = 0.002";
  input Real tolerance := 1e-6 "tolerance used by the integration method. <default> = 1e-6";
  input String method := "<default>" "integration method used for simulation. <default> = dassl";
  input String fileNamePrefix := "<default>" "fileNamePrefix. <default> = \"\"";
  input Boolean storeInTemp := false "storeInTemp. <default> = false";
  input Boolean noClean := false "noClean. <default> = false";
  input String options := "<default>" "options. <default> = \"\"";
  input String outputFormat := "mat" "Format for the result file. <default> = \"mat\"";
  input String variableFilter := ".*" "Filter for variables that should store in result file. <default> = \".*\"";
  input Boolean measureTime := false "creates a html file with proffiling data for model simulation. <default> = false";
  input String cflags := "<default>" "cflags. <default> = \"\"";
  input String simflags := "<default>" "simflags. <default> = \"\"";
  output String linearizationResult;
external "builtin";
annotation(Documentation(info="<html>
<p>Creates a model with symbolic linearization matrixes.</p>
<p>At stopTime the linearization matrixes are evaluated and a modelica model is created.</p>
<p>The only required argument is the className, while all others have some default values.</p>
<h2>Usage:</h2>
<p><b>linearize</b>(<em>A</em>, stopTime=0.0);</p>
<p>Creates the file \"linear_A.mo\" that contains the linearized matrixes at stopTime.</p>
</html>", revisions="<html>
<table>
<tr><th>Revision</th><th>Author</th><th>Comment</th></tr>
<tr><td>13421</td><td>wbraun</td><td>Added to omc</td></tr>
</table>
</html>"),preferredView="text");
end linearize;

function getSourceFile "Returns the filename of the class."
  input TypeName class_;
  output String filename "empty on failure";
external "builtin";
annotation(preferredView="text");
end getSourceFile;

function setSourceFile
  input TypeName class_;
  input String filename;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setSourceFile;

function isShortDefinition "returns true if the definition is a short class definition"
  input TypeName class_;
  output Boolean isShortCls;
external "builtin";
annotation(preferredView="text");
end isShortDefinition;

function setClassComment "Sets the class comment."
  input TypeName class_;
  input String filename;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setClassComment;

function getClassNames "Returns the list of class names defined in the class."
  input TypeName class_ := $TypeName(AllLoadedClasses);
  input Boolean recursive := false;
  input Boolean qualified := false;
  input Boolean sort := false;
  input Boolean builtin := false "List also builtin classes if true";
  input Boolean showProtected := false "List also protected classes if true";
  output TypeName classNames[:];
external "builtin";
annotation(preferredView="text");
end getClassNames;

function getPackages "Returns the list of packages defined in the class."
  input TypeName class_ := $TypeName(AllLoadedClasses);
  output TypeName classNames[:];
external "builtin";
annotation(preferredView="text");
end getPackages;

function setPlotSilent "Sets the plotSilent flag."
  input Boolean silent;
  output Boolean success;
algorithm
  success := setCommandLineOptions("+plotSilent=" + String(silent));
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setPlotSilent;

function getPlotSilent "Returns true if plotSilent flag is set."
  output Boolean plotSilent;
external "builtin";
annotation(preferredView="text");
end getPlotSilent;

partial function basePlotFunction "Extending this does not seem to work at the moment. A real shame; functions below are copy-paste and all need to be updated if the interface changes."
  input String fileName := "<default>" "The filename containing the variables. <default> will read the last simulation result";
  input String interpolation := "linear" "
    Determines if the simulation data should be interpolated to allow drawing of continuous lines in the diagram.
    \"linear\" results in linear interpolation between data points, \"constant\" keeps the value of the last known
    data point until a new one is found and \"none\" results in a diagram where only known data points are plotted."
  ;
  input String title := "Plot by OpenModelica" "This text will be used as the diagram title.";
  input Boolean legend := true "Determines whether or not the variable legend is shown.";
  input Boolean grid := true "Determines whether or not a grid is shown in the diagram.";
  input Boolean logX := false "Determines whether or not the horizontal axis is logarithmically scaled.";
  input Boolean logY := false "Determines whether or not the vertical axis is logarithmically scaled.";
  input String xLabel := "time" "This text will be used as the horizontal label in the diagram.";
  input String yLabel := "" "This text will be used as the vertical label in the diagram.";
  input Boolean points := false "Determines whether or not the data points should be indicated by a dot in the diagram.";
  input Real xRange[2] := {0.0,0.0} "Determines the horizontal interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real yRange[2] := {0.0,0.0} "Determines the vertical interval that is visible in the diagram. {0,0} will select a suitable range.";
  output Boolean success "Returns true on success";
annotation(preferredView="text");
end basePlotFunction;

function plot "Launches a plot window using OMPlot."
  input VariableNames vars "The variables you want to plot";
  input Boolean externalWindow := false "Opens the plot in a new plot window";
  input String fileName := "<default>" "The filename containing the variables. <default> will read the last simulation result";
  input String title := "Plot by OpenModelica" "This text will be used as the diagram title.";
  input Boolean legend := true "Determines whether or not the variable legend is shown.";
  input Boolean grid := true "Determines whether or not a grid is shown in the diagram.";
  input Boolean logX := false "Determines whether or not the horizontal axis is logarithmically scaled.";
  input Boolean logY := false "Determines whether or not the vertical axis is logarithmically scaled.";
  input String xLabel := "time" "This text will be used as the horizontal label in the diagram.";
  input String yLabel := "" "This text will be used as the vertical label in the diagram.";
  input Real xRange[2] := {0.0,0.0} "Determines the horizontal interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real yRange[2] := {0.0,0.0} "Determines the vertical interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real curveWidth := 1.0 "Sets the width of the curve.";
  input Integer curveStyle := 1 "Sets the style of the curve. SolidLine=1, DashLine=2, DotLine=3, DashDotLine=4, DashDotDotLine=5, Sticks=6, Steps=7.";
  output Boolean success "Returns true on success";
  output String[:] result "Returns list i.e {\"_omc_PlotResult\",\"<fileName>\",\"<title>\",\"<legend>\",\"<grid>\",\"<PlotType>\",\"<logX>\",\"<logY>\",\"<xLabel>\",\"<yLabel>\",\"<xRange>\",\"<yRange>\",\"<PlotVariables>\"}";
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Launches a plot window using OMPlot. Returns true on success.</p>

<p>Example command sequences:</p>
<ul>
<li>simulate(A);plot({x,y,z});</li>
<li>simulate(A);plot(x, externalWindow=true);</li>
<li>simulate(A,fileNamePrefix=\"B\");simulate(C);plot(z,\"B.mat\",legend=false);</li>
</ul>
</html>"));
end plot;

function plotAll "Works in the same way as plot(), but does not accept any
  variable names as input. Instead, all variables are part of the plot window.

  Example command sequences:
  simulate(A);plotAll();
  simulate(A);plotAll(externalWindow=true);
  simulate(A,fileNamePrefix=\"B\");simulate(C);plotAll(x,\"B.mat\");"

  input Boolean externalWindow := false "Opens the plot in a new plot window";
  input String fileName := "<default>" "The filename containing the variables. <default> will read the last simulation result";
  input String title := "Plot by OpenModelica" "This text will be used as the diagram title.";
  input Boolean legend := true "Determines whether or not the variable legend is shown.";
  input Boolean grid := true "Determines whether or not a grid is shown in the diagram.";
  input Boolean logX := false "Determines whether or not the horizontal axis is logarithmically scaled.";
  input Boolean logY := false "Determines whether or not the vertical axis is logarithmically scaled.";
  input String xLabel := "time" "This text will be used as the horizontal label in the diagram.";
  input String yLabel := "" "This text will be used as the vertical label in the diagram.";
  input Real xRange[2] := {0.0,0.0} "Determines the horizontal interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real yRange[2] := {0.0,0.0} "Determines the vertical interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real curveWidth := 1.0 "Sets the width of the curve.";
  input Integer curveStyle := 1 "Sets the style of the curve. SolidLine=1, DashLine=2, DotLine=3, DashDotLine=4, DashDotDotLine=5, Sticks=6, Steps=7.";
  output Boolean success "Returns true on success";
  output String[:] result "Returns list i.e {\"_omc_PlotResult\",\"<fileName>\",\"<title>\",\"<legend>\",\"<grid>\",\"<PlotType>\",\"<logX>\",\"<logY>\",\"<xLabel>\",\"<yLabel>\",\"<xRange>\",\"<yRange>\",\"<PlotVariables>\"}";
external "builtin";
annotation(preferredView="text");
end plotAll;

function visualize "Uses the 3D visualization package, SimpleVisual.mo, to
  visualize the model. See chapter 3.4 (3D Animation) of the OpenModelica
  System Documentation for more details.
  Writes the visulizations objects into the file \"model_name.visualize\"

  Example command sequence:
  simulate(A,outputFormat=\"mat\");visualize(A);visualize(A,\"B.mat\");visualize(A,\"B.mat\", true);
  "
  input TypeName className;
  input Boolean externalWindow := false "Opens the visualize in a new window";
  input String fileName := "<default>" "The filename containing the variables. <default> will read the last simulation result";
  output Boolean success "Returns true on success";
  external "builtin";
annotation(preferredView="text");
end visualize;

function plotParametric "Launches a plotParametric window using OMPlot. Returns true on success.

  Example command sequences:
  simulate(A);plotParametric2(x,y);
  simulate(A);plotParametric2(x,y, externalWindow=true);
  "
  input VariableName xVariable;
  input VariableName yVariable;
  input Boolean externalWindow := false "Opens the plot in a new plot window";
  input String fileName := "<default>" "The filename containing the variables. <default> will read the last simulation result";
  input String title := "Plot by OpenModelica" "This text will be used as the diagram title.";
  input Boolean legend := true "Determines whether or not the variable legend is shown.";
  input Boolean grid := true "Determines whether or not a grid is shown in the diagram.";
  input Boolean logX := false "Determines whether or not the horizontal axis is logarithmically scaled.";
  input Boolean logY := false "Determines whether or not the vertical axis is logarithmically scaled.";
  input String xLabel := "time" "This text will be used as the horizontal label in the diagram.";
  input String yLabel := "" "This text will be used as the vertical label in the diagram.";
  input Real xRange[2] := {0.0,0.0} "Determines the horizontal interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real yRange[2] := {0.0,0.0} "Determines the vertical interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real curveWidth := 1.0 "Sets the width of the curve.";
  input Integer curveStyle := 1 "Sets the style of the curve. SolidLine=1, DashLine=2, DotLine=3, DashDotLine=4, DashDotDotLine=5, Sticks=6, Steps=7.";
  output Boolean success "Returns true on success";
  output String[:] result "Returns list i.e {\"_omc_PlotResult\",\"<fileName>\",\"<title>\",\"<legend>\",\"<grid>\",\"<PlotType>\",\"<logX>\",\"<logY>\",\"<xLabel>\",\"<yLabel>\",\"<xRange>\",\"<yRange>\",\"<PlotVariables>\"}";
external "builtin";
annotation(preferredView="text");
end plotParametric;

function readSimulationResult "Reads a result file, returning a matrix corresponding to the variables and size given."
  input String filename;
  input VariableNames variables;
  input Integer size := 0 "0=read any size... If the size is not the same as the result-file, this function fails";
  output Real result[:,:];
external "builtin";
annotation(preferredView="text");
end readSimulationResult;

function readSimulationResultSize "The number of intervals that are present in the output file."
  input String fileName;
  output Integer sz;
external "builtin";
annotation(preferredView="text");
end readSimulationResultSize;

function readSimulationResultVars "Returns the variables in the simulation file; you can use val() and plot() commands using these names."
  input String fileName;
  output String[:] vars;
external "builtin";
annotation(preferredView="text");
end readSimulationResultVars;

public function compareSimulationResults "compares simulation results."
  input String filename;
  input String reffilename;
  input String logfilename;
  input Real relTol := 0.01;
  input Real absTol := 0.0001;
  input String[:] vars := fill("",0);
  output String[:] result;
external "builtin";
annotation(preferredView="text");
end compareSimulationResults;

public function checkTaskGraph "Checks if the given taskgraph has the same structure as the reference taskgraph and if all attributes are set correctly."
  input String filename;
  input String reffilename;
  output String[:] result;
external "builtin";
annotation(preferredView="text");
end checkTaskGraph;

function val "Return the value of a variable at a given time in the simulation results"
  input VariableName var;
  input Real time;
  input String fileName := "<default>" "The contents of the currentSimulationResult variable";
  output Real valAtTime;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Return the value of a variable at a given time in the simulation results.</p>
<p>Works on the filename pointed to by the scripting variable currentSimulationResult or a given filename.</p>
<p>For parameters, any time may be given. For variables the startTime<=time<=stopTime needs to hold.</p>
<p>On error, nan (Not a Number) is returned and the error buffer contains the message.</p>
</html>"));
end val;

function closeSimulationResultFile "Closes the current simulation result file.
  Only needed by Windows. Windows cannot handle reading and writing to the same file from different processes.
  To allow OMEdit to make successful simulation again on the same file we must close the file after reading the Simulation Result Variables.
  Even OMEdit only use this API for Windows."
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end closeSimulationResultFile;

function addClassAnnotation
  input TypeName class_;
  input Expression annotate;
  output Boolean bool;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Used to set annotations, like Diagrams and Icons in classes. The function is given the name of the class
and the annotation to set.</p>
<p>Usage: addClassAnnotation(Modelica, annotate = Documentation(info = \"&lt;html&gt;&lt;/html&gt;\"))</p>
</html>"));
end addClassAnnotation;

function getAlgorithmCount "Counts the number of Algorithm sections in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getAlgorithmCount;

function getNthAlgorithm "Returns the Nth Algorithm section."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthAlgorithm;

function getInitialAlgorithmCount "Counts the number of Initial Algorithm sections in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getInitialAlgorithmCount;

function getNthInitialAlgorithm "Returns the Nth Initial Algorithm section."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthInitialAlgorithm;

function getAlgorithmItemsCount "Counts the number of Algorithm items in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getAlgorithmItemsCount;

function getNthAlgorithmItem "Returns the Nth Algorithm Item."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthAlgorithmItem;

function getInitialAlgorithmItemsCount "Counts the number of Initial Algorithm items in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getInitialAlgorithmItemsCount;

function getNthInitialAlgorithmItem "Returns the Nth Initial Algorithm Item."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthInitialAlgorithmItem;

function getEquationCount "Counts the number of Equation sections in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getEquationCount;

function getNthEquation "Returns the Nth Equation section."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthEquation;

function getInitialEquationCount "Counts the number of Initial Equation sections in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getInitialEquationCount;

function getNthInitialEquation "Returns the Nth Initial Equation section."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthInitialEquation;

function getEquationItemsCount "Counts the number of Equation items in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getEquationItemsCount;

function getNthEquationItem "Returns the Nth Equation Item."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthEquationItem;

function getInitialEquationItemsCount "Counts the number of Initial Equation items in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getInitialEquationItemsCount;

function getNthInitialEquationItem "Returns the Nth Initial Equation Item."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthInitialEquationItem;

function getAnnotationCount "Counts the number of Annotation sections in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getAnnotationCount;

function getNthAnnotationString "Returns the Nth Annotation section as string."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthAnnotationString;

function getImportCount "Counts the number of Import sections in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getImportCount;

function getNthImport "Returns the Nth Import as string."
  input TypeName class_;
  input Integer index;
  output String out[3] "{\"Path\",\"Id\",\"Kind\"}";
external "builtin";
annotation(preferredView="text");
end getNthImport;

function iconv "The iconv() function converts one multibyte characters from one character
  set to another.
  See man (3) iconv for more information.
"
  input String string;
  input String from;
  input String to := "UTF-8";
  output String result;
external "builtin";
annotation(preferredView="text");
end iconv;

function getDocumentationAnnotation "Returns the documentaiton annotation defined in the class."
  input TypeName cl;
  output String out[2] "{info,revision} TODO: Should be changed to have 2 outputs instead of an array of 2 Strings...";
external "builtin";
annotation(preferredView="text");
end getDocumentationAnnotation;

function setDocumentationAnnotation
  input TypeName class_;
  input String info = "";
  input String revisions = "";
  output Boolean bool;

  external "builtin" ;
annotation(preferredView = "text", Documentation(info = "<html>
<p>Used to set the Documentation annotation of a class. An empty argument (e.g. for revisions) means no annotation is added.</p>
</html>"));
end setDocumentationAnnotation;

function typeNameString
  input TypeName cl;
  output String out;
external "builtin";
annotation(preferredView="text");
end typeNameString;

function typeNameStrings
  input TypeName cl;
  output String out[:];
external "builtin";
annotation(preferredView="text");
end typeNameStrings;

function getClassComment "Returns the class comment."
  input TypeName cl;
  output String comment;
external "builtin";
annotation(preferredView="text");
end getClassComment;

function dirname
  input String path;
  output String dirname;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns the directory name of a file path.
  Similar to <a href=\"http://linux.die.net/man/3/dirname\">dirname(3)</a>, but with the safety of Modelica strings.
</html>"),
  preferredView="text");
end dirname;

function basename
  input String path;
  output String basename;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns the base name (file part) of a file path.
  Similar to <a href=\"http://linux.die.net/man/3/basename\">basename(3)</a>, but with the safety of Modelica strings.
</html>"),
  preferredView="text");
end basename;

function isPackage
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns true if the given class is a package.
</html>"),
  preferredView="text");
end isPackage;

function isPartial
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns true if the given class is partial.
</html>"),
  preferredView="text");
end isPartial;

function isModel
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns true if the given class has restriction model.
</html>"),
  preferredView="text");
end isModel;

function isOperator
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns true if the given class has restriction operator.
</html>"),
  preferredView="text");
end isOperator;

function isOperatorRecord
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns true if the given class has restriction \"operator record\".
</html>"),
  preferredView="text");
end isOperatorRecord;

function isOperatorFunction
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns true if the given class has restriction \"operator function\".
</html>"),
  preferredView="text");
end isOperatorFunction;

function isProtectedClass
  input TypeName cl;
  input String c2;
  output Boolean b;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns true if the given class c1 has class c2 as one of its protected class.
</html>"),
  preferredView="text");
end isProtectedClass;

function setInitXmlStartValue
  input String fileName;
  input String variableName;
  input String startValue;
  input String outputFile;
  output Boolean success := false;
protected
  String xsltproc;
  String command;
  CheckSettingsResult settings;
algorithm
  if regularFileExists(fileName) then
    settings := checkSettings();
    xsltproc := if settings.OS == "Windows_NT" then getInstallationDirectoryPath() + "/lib/omc/libexec/xsltproc/xsltproc.exe" else "xsltproc";
    command := xsltproc + " -o " + outputFile + " --stringparam variableName " + variableName + " --stringparam variableStart " + startValue + " " +
      getInstallationDirectoryPath() + "/share/omc/scripts/replace-startValue.xsl " + fileName;
    success := 0 == system(command);
  end if;
end setInitXmlStartValue;

function isExperiment "An experiment is defined as having annotation Experiment(stopTime=...)"
  input TypeName name;
  output Boolean res;
external "builtin";
end isExperiment;

function classAnnotationExists "Check if annotation exists"
  input TypeName className;
  input TypeName annotationName;
  output Boolean exists;
external "builtin";
annotation(Documentation(info="<html>
Returns true if <b>className</b> has a class annotation called <b>annotationName</b>.
</html>",revisions="<html>
<table>
<tr><th>Revision</th><th>Author</th><th>Comment</th></tr>
<tr><td>16311</td><td>sjoelund.se</td><td>Added to omc</td></tr>
</table>
</html>"));
end classAnnotationExists;

function getBooleanClassAnnotation "Check if annotation exists and returns its value"
  input TypeName className;
  input TypeName annotationName;
  output Boolean value;
external "builtin";
annotation(Documentation(info="<html>
Returns the value of the class annotation <b>annotationName</b> of class <b>className</b>. If there is no such annotation, or if it is not true or false, this function fails.
</html>",revisions="<html>
<table>
<tr><th>Revision</th><th>Author</th><th>Comment</th></tr>
<tr><td>16311</td><td>sjoelund.se</td><td>Added to omc</td></tr>
</table>
</html>"));
end getBooleanClassAnnotation;

function extendsFrom "returns true if the given class extends from the given base class"
  input TypeName className;
  input TypeName baseClassName;
  output Boolean res;
external "builtin";
end extendsFrom;

function loadModelica3D
  input String version := "3.2.1";
  output Boolean status;
protected
  String m3d;
algorithm
  status := loadModel(Modelica,{version});
  if version == "3.1" then
    status := status and loadModel(ModelicaServices,{"1.0 modelica3d"});
    m3d:=getInstallationDirectoryPath()+"/lib/omlibrary-modelica3d/";
    status := status and min(loadFile({m3d + file for file in {"DoublePendulum.mo","Engine1b.mo","Internal.mo","Pendulum.mo"}}));
  elseif status then
    status := loadModel(ModelicaServices,{version + " modelica3d"});
  end if;
  annotation(Documentation(info="<html>
<h2>Usage</h2>
<p>Modelica3D requires some changes to the standard ModelicaServices in order to work correctly. These changes will make your MultiBody models unable to simulate because they need an object declared as:</p>
<pre>inner ModelicaServices.Modelica3D.Controller m3d_control</pre>
<p>This API call will load the modified ModelicaServices 3.2.1 so Modelica3D runs. You can also simply call loadModel(ModelicaServices,{\"3.2.1 modelica3d\"});</p>
<p>You will also need to start an m3d backend to render the results. We hid them in $OPENMODELICAHOME/lib/omlibrary-modelica3d/osg-gtk/dbus-server.py (or blender2.59).</p>
<p>For more information and example models, visit the <a href=\"https://mlcontrol.uebb.tu-berlin.de/redmine/projects/modelica3d-public/wiki\">Modelica3D wiki</a>.</p>
 </html>"));
end loadModelica3D;

function searchClassNames "Searches for the class name in the all the loaded classes.
  Example command:
  searchClassNames(\"ground\");
  searchClassNames(\"ground\", true);"
  input String searchText;
  input Boolean findInText := false;
  output TypeName classNames[:];
external "builtin";
annotation(
  Documentation(info="<html>
  Look for searchText in All Loaded Classes and their code. Returns the list of searched classes.
</html>"),
  preferredView="text");
end searchClassNames;

function getAvailableLibraries
  output String[:] libraries;
external "builtin";
annotation(
  Documentation(info="<html>
  Looks for all libraries that are visible from the <a href=\"modelica://OpenModelica.Scripting.getModelicaPath\">getModelicaPath()</a>.
</html>"),
  preferredView="text");
end getAvailableLibraries;

function getUses
  input TypeName pack;
  output String[:,:] uses;
external "builtin";
annotation(
  Documentation(info="<html>
Returns the libraries used by the package {{\"Library1\",\"Version\"},{\"Library2\",\"Version\"}}.
</html>"),
  preferredView="text");
end getUses;

function getDerivedClassModifierNames "Returns the derived class modifier names.
  Example command:
  type Resistance = Real(final quantity=\"Resistance\",final unit=\"Ohm\");
  getDerivedClassModifierNames(Resistance) => {\"quantity\",\"unit\"}"
  input TypeName className;
  output String[:] modifierNames;
external "builtin";
annotation(
  Documentation(info="<html>
  Finds the modifiers of the derived class.
</html>"),
  preferredView="text");
end getDerivedClassModifierNames;

function getDerivedClassModifierValue "Returns the derived class modifier value.
  Example command:
  type Resistance = Real(final quantity=\"Resistance\",final unit=\"Ohm\");
  getDerivedClassModifierValue(Resistance, unit); => \" = \"Ohm\"\"
  getDerivedClassModifierValue(Resistance, unit); => \" = \"Resistance\"\""
  input TypeName className;
  input TypeName modifierName;
  output String modifierValue;
external "builtin";
annotation(
  Documentation(info="<html>
  Finds the modifier value of the derived class.
</html>"),
  preferredView="text");
end getDerivedClassModifierValue;

function generateEntryPoint
  input String fileName;
  input TypeName entryPoint;
  input String url = "https://trac.openmodelica.org/OpenModelica/newticket";
external "builtin";
annotation(
  Documentation(info="<html>
<p>Generates a main() function that calls the given MetaModelica entrypoint (assumed to have input list<String> and no outputs).</p>
</html>"));
end generateEntryPoint;

function numProcessors
  output Integer result;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns the number of processors (if compiled against hwloc) or hardware threads (if using sysconf) available to OpenModelica.</p>
</html>"));
end numProcessors;

function forkAvailable
  output Boolean result;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns true if the fork system call is available on the platform.</p>
</html>"));
end forkAvailable;

function runScriptParallel
  input String scripts[:];
  input Integer numThreads := numProcessors();
  input Boolean fork := false;
  output Boolean results[:];
external "builtin";
annotation(
  Documentation(info="<html>
<p>As <a href=\"modelica://OpenModelica.Scripting.runScript\">runScript</a>, but runs the commands in parallel.</p>
<p>If useFork=false (default), the script will be run in an empty environment (same as running a new omc process) with default config flags.</p>
<p>If useFork=true (only available on platforms that implement fork), the script will run in the same (forked) environment as previously.
No changes made to the environment will be visible in the main process and the rest of the commands that are executed.</p>
</html>"));
end runScriptParallel;

function exit
  input Integer status;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Forces omc to quit with the given exit status.</p>
</html>"));
end exit;

function getMemorySize
  output Real memory(unit="MiB");
external "builtin";
annotation(
  Documentation(info="<html>
<p>Retrieves the physical memory size available on the system in megabytes.</p>
</html>"));
end getMemorySize;

annotation(preferredView="text");
end Scripting;

package UsersGuide
package ReleaseNotes
package '1.0' "Version 1.0 (r1026, 2003-10-31)"
end '1.0';
package '1.1' "Version 1.1 (r1323, 2004-10-25)"
end '1.1';
package '1.2' "Version 1.2 (r1562, 2005-03-04)"
end '1.2';
package '1.3.1' "Version 1.3.1 (r1999, 2005-12-01)"
annotation(Documentation(info="<html>
This release has several important highlights.
This is also the <em>first</em> release for which the New BSD (Berkeley) open-source license applies to the source code, including the whole compiler and run-time system. This makes is possible to use OpenModelica for both academic and commercial purposes without restrictions.
<h4>OpenModelica Compiler (OMC)</h4>
This release includes a significantly improved OpenModelica Compiler (OMC):
<ul>
<li>Support for hybrid and discrete-event simulation (if-equations, if-expressions, when-equations;    not yet if-statements and when-statements).</li>
<li>Parsing of full Modelica 2.2</li>
<li>Improved support for external functions.</li>
<li>Vectorization of function arguments; each-modifiers, better implementation of replaceable, better handling of structural parameters, better support for vector and array operations, and many other improvements.</li>
<li>Flattening of the Modelica Block library version 1.5 (except a few models), and simulation of most of these.</li>
<li>Automatic index reduction (present also in previous release).</li>
<li>Updated User's Guide including examples of hybrid simulation and external functions.</li>
</ul>
<h4>OpenModelica Shell (OMShell)</h4>
An improved window-based interactive command shell, now including command completion and better editing and font size support.
<h4>OpenModelica Notebook (OMNotebook)</h4>
A free implementation of an OpenModelica notebook (OMNOtebook), for electronic books with course material, including the DrModelica interactive course material. It is possible to simulate and plot from this notebook.
<h4>OpenModelica Eclipse Plug-in (MDT)</h4>
An early alpha version of the first Eclipse plug-in (called MDT for Modelica Development Tooling) for Modelica Development. This version gives compilation support and partial support for browsing Modelica package hierarchies and classes.
<h4>OpenModelica Development Environment (OMDev)</h4>
The following mechanisms have been put in place to support OpenModelica development.
<ul>
<li>Bugzilla support for OpenModelica bug tracking, accessible to anybody.</li>
<li>A system for automatic regression testing of the compiler and simulator, (+ other system parts) usually run at check in time.</li>
<li>Version handling is done using SVN, which is better than the previously used CVS system. For example, name change of modules is now possible within the version handling system.</li>
</ul>
</html>"));
end '1.3.1';
package '1.4.0' "Version 1.4.0 (r2393, 2006-05-18)"
annotation(Documentation(info="<html>
This release has a number of improvements described below. The most significant change is probably that OMC has now been translated to an extended subset of Modelica (MetaModelica), and that all development of the compiler is now done in this version..
<h4>OpenModelica Compiler (OMC)</h4>
This release includes further improvements of the OpenModelica Compiler (OMC):
<ul>
<li>Partial support for mixed system of equations.</li>
<li>New initialization routine, based on optimization (minimizing residuals of initial equations).</li>
<li>Symbolic simplification of builtin operators for vectors and matrices.</li>
<li>Improved code generation in simulation code to support e.g. Modelica functions.</li>
<li>Support for classes extending basic types, e.g. connectors (support for MSL 2.2 block connectors).</li>
<li>Support for parametric plotting via the plotParametric command.</li>
<li>Many bug fixes.</li>
</ul>
<h4>OpenModelica Shell (OMShell)</h4>
Essentially the same OMShell as in 1.3.1. One difference is that now all error messages are sent to the command window instead of to a separate log window.
<h4>OpenModelica Notebook (OMNotebook)</h4>
Many significant improvements and bug fixes. This version supports graphic plots within the cells in the notebook. Improved cell handling and Modelica code syntax highlighting. Command completion of the most common OMC commands is now supported. The notebook has been used in several courses.
<h4>OpenModelica Eclipse Plug-in (MDT)</h4>
This is the first really useful version of MDT. Full browsing of Modelica code, e.g. the MSL 2.2, is now supported. (MetaModelica browsing is not yet fully supported). Full support for automatic indentation of Modelica code, including the MetaModelica extensions. Many bug fixes. The Eclipse plug-in is now in use for OpenModelica development at PELAB and MathCore Engineering AB since approximately one month.
<h4>OpenModelica Development Environment (OMDev)</h4>
The following mechanisms have been put in place to support OpenModelica development.
<ul>
<li>A separate web page for OMDev  (OpenModelica Development Environment).</li>
<li>A pre-packaged OMDev zip-file with precompiled binaries for development under Windows using the mingw Gnu compiler from the Eclipse MDT plug-in. (Development is also possible using Visual Studio).</li>
<li>All source code of the OpenModelica compiler has recently been translated to an extended subset of Modelica, currently called MetaModelica. The current size of OMC is approximately 100 000 lines All development is now done in this version.</li>
<li>A new tutorial and users guide for development in MetaModelica.</li>
<li>Successful builds and tests of OMC under Linux and Solaris.</li>
</ul>
</html>"));
end '1.4.0';
package '1.4.1' "Version 1.4.1 (r2432, 2006-06-19)"
annotation(Documentation(info="<html>
This release has only improvements and bug fixes of the OMC compiler, the MDT plugin and the OMDev components. The OMShell and OMNotebook are the same.
<h4>OpenModelica Compiler (OMC)</h4>
This release includes further improvements of the OpenModelica Compiler (OMC):
<ul>
<li>Support for external objects.</li>
<li>OMC now reports the version number (via command line switches or CORBA API getVersion()).</li>
<li>Implemented caching for faster instantiation of large models.</li>
<li>Many bug fixes.</li>
</ul>
<h4>OpenModelica Eclipse Plug-in (MDT)</h4>
Improvements of the error reporting when building the OMC compiler. The errors are now added to the problems view. The latest MDT release is version 0.6.6 (2006-06-06).
<h4>OpenModelica Development Environment (OMDev)</h4>
Small fixes in the MetaModelica compiler. MetaModelica Users Guide is now part of the OMDev release. The latest OMDev was release in 2006-06-06.
</html>"));
end '1.4.1';
package '1.4.2' "Version 1.4.2 (r2557, 2006-10-01)"
annotation(Documentation(info="<html>
This release has improvements and bug fixes of the OMC compiler, OMNotebook, the MDT plugin and the OMDev. OMShell is the same as previously.
<h4>OpenModelica Compiler (OMC)</h4>
This release includes further improvements of the OpenModelica Compiler (OMC):
<ul>
<li>Improved initialization and index reduction.</li>
<li>Support for integer arrays is now largely implemented.</li>
<li>The val(variable,time) scripting function for accessing the value of a simulation result variable at a certain point in the simulated time.</li>
<li>Interactive evalution of for-loops, while-loops, if-statements, if-expressions, in the interactive scripting mode.</li>
<li>Improved documentation and examples of calling the Model Query and Manipulation API.</li>
<li>Many bug fixes.</li>
</ul>
<h4>OpenModelica Notebook (OMNotebook)</h4>
Search and replace functions have been added. The DrModelica tutorial (all files) has been updated, obsolete sections removed, and models which are not supported by the current implementation marked clearly. Automatic recognition of the .onb suffix (e.g. when double-clicking) in Windows makes it even more convenient to use.
<h4>OpenModelica Eclipse Plug-in (MDT)</h4>
Two major improvements are added in this release:
<ul>
<li>Browsing and code completion works both for standard Modelica and for MetaModelica.</li>
<li>The debugger for algorithmic code is now available and operational in Eclipse for debugging of MetaModelica programs.</li>
</ul>
<h4>OpenModelica Development Environment (OMDev)</h4>
Mostly the same as previously.
</html>"));
end '1.4.2';
package '1.4.3' "Version 1.4.3 (r2860, 2007-07-13)"
annotation(Documentation(info="<html>
This release has  a number of significant improvements of the OMC compiler, OMNotebook, the MDT plugin and the OMDev. Increased platform availability now also for Linux and Macintosh, in addition to Windows. OMShell is the same as previously, but now ported to Linux and Mac.
<h4>OpenModelica Compiler (OMC)</h4>
This release includes a number of  improvements of the OpenModelica Compiler (OMC):
<ul>
<li>Significantly increased compilation speed, especially with large models and many packages.</li>
<li>Now available also for Linux and Macintosh platforms.</li>
<li>Support for when-equations in algorithm sections, including elsewhen.</li>
<li>Support for inner/outer prefixes of components (but without type error checking).</li>
<li>Improved solution of nonlinear systems.</li>
<li>Added ability to compile generated simulation code using Visual Studio compiler.</li>
<li>Added smart setting of fixed attribute to false. If initial equations, OMC instead has fixed=true as default for states due to allowing overdetermined initial equation systems.</li>
<li>Better state select heuristics.</li>
<li>New function getIncidenceMatrix(ClassName) for dumping the incidence matrix.</li>
<li>Builtin functions String(), product(), ndims(), implemented.</li>
<li>Support for terminate() and assert() in equations.</li>
<li>In emitted flat form: protected variables are now prefixed with protected when printing flat class.</li>
<li>Some support for  tables, using omcTableTimeIni instead of dymTableTimeIni2.</li>
<li>Better support for empty arrays, and support for matrix operations like  a*[1,2;3,4].</li>
<li>Improved val() function can now evaluate array elements and record fields, e.g. val(x[n]), val(x.y) .</li>
<li>Support for reinit in algorithm sections.</li>
<li>String support in external functions.</li>
<li>Double precision floating point precision now also for interpreted expressions</li>
<li>Better simulation error messages.</li>
<li>Support for der(expressions).</li>
<li>Support for iterator expressions such as {3*i for i in 1..10}.</li>
<li>More test cases in the test suite.</li>
<li>A number of bug fixes, including sample and event handling bugs.</li>
</ul>
<h4>OpenModelica Notebook (OMNotebook)</h4>
A number of improvements, primarily in the platform availability.
<ul>
<li>Available on the Linux and Macintosh platforms, in addition to Windows.</li>
<li>Fixed cell copying bugs, plotting of derivatives now works, etc.</li>
</ul>
<h4>OpenModelica Shell (OMShell)</h4>
Now available also on the Macintosh platform.
<h4>OpenModelica Eclipse Plug-in (MDT)</h4>
This release includes major improvements of MDT and the associated MetaModelica debugger:
<ul>
<li>Greatly improved browsing and code completion works both for standard Modelica and for MetaModelica.</li>
<li>Hovering over identifiers displays type information.</li>
<li>A new and greatly improved implementation of the debugger for MetaModelica algorithmic code, operational in Eclipse. Greatly improved performance - only approx 10% speed reduction even for 100 000 line programs. Greatly improved single stepping, step over, data structure browsing, etc.</li>
<li>Many bug fixes.</li>
</ul>
<h4>OpenModelica Development Environment (OMDev)</h4>
<ul>
<li>Increased compilation speed for MetaModelica.</li>
<li>Better if-expression support in MetaModelica.</li>
</ul>
</html>"));
end '1.4.3';
package '1.4.4' "Version 1.4.4 (r3218, 2008-02-20)"
annotation(Documentation(info="<html>
This release is primarily a bug fix release, except for a preliminary version of new plotting functionality available both from the OMNotebook and separately through a Modelica API. This is also the first release under the open source license OSMC-PL (Open Source Modelica Consortium Public License), with support from the recently created Open Source Modelica Consortium. An integrated version handler, bug-, and issue tracker has also been added.
<h4>OpenModelica Compiler (OMC)</h4>
This release includes small improvements and some bugfixes of the OpenModelica Compiler (OMC):
<ul>
<li>Better support for if-equations, also inside when.</li>
<li>Better support for calling functions in parameter expressions and interactively through dynamic loading of functions.</li>
<li>Less memory consumtion during compilation and interactive evaluation.</li>
<li>A number of bug-fixes.</li>
</ul>
<h4>OpenModelica Notebook (OMNotebook)</h4>
Test release of improvements, primarily in the plotting functionality and platform availability.
<ul>
<li>Preliminary version of improvements in the plotting functionality: scalable plots, zooming, logarithmic plots, grids, etc., currently available in a preliminary version through the plot2 function.</li>
<li>Programmable plotting accessible through a Modelica API.</li>
</ul>
<h4>OpenModelica Shell (OMShell)</h4>
Same as previously.
<h4>OpenModelica Eclipse Plug-in (MDT)</h4>
This release includes minor bugfixes of MDT and the associated MetaModelica debugger.
<h4>OpenModelica Development Environment (OMDev)</h4>
Extended test suite with a better structure. Version handling, bug tracking, issue tracking, etc. now available under the integrated Codebeamer.
</html>"));
end '1.4.4';
package '1.4.5' "Version 1.4.5 (r3856, 2009-02-10)"
annotation(Documentation(info="<html>
This release has several improvements, especially platform availability, less compiler memory usage, and supporting more aspects of  Modelica 3.0.
<h4>OpenModelica Compiler (OMC)</h4>
This release includes small improvements and some bugfixes of the OpenModelica Compiler (OMC):
<ul>
<li>Less memory consumption and better memory management over time. This also includes a better API supporting automatic memory management when calling C functions from within the compiler.</li>
<li>Modelica 3.0 parsing support.</li>
<li>Export of DAE to XML and MATLAB.</li>
<li>Support for several platforms Linux, MacOS, Windows (2000, Xp, Vista).</li>
<li>Support for record and strings as function arguments.</li>
<li>Many bug fixes.</li>
<li>(Not part of OMC): Additional free graphic editor SimForge can be used with OpenModelica.</li>
</ul>
<h4>OpenModelica Notebook (OMNotebook)</h4>
A number of improvements, primarily in the plotting functionality and platform availability.
<ul>
<li>A number of improvements in the plotting functionality: scalable plots, zooming, logarithmic plots, grids, etc.</li>
<li>Programmable plotting accessible through a Modelica API.</li>
<li>Simple 3D visualization.</li>
<li>Support for several platforms Linux, MacOS, Windows (2000, Xp, Vista).</li>
</ul>
<h4>OpenModelica Shell (OMShell)</h4>
Same as previously.
<h4>OpenModelica Eclipse Plug-in (MDT)</h4>
Minor bug fixes.
<h4>OpenModelica Development Environment (OMDev)</h4>
Same as previously.
</html>"));
end '1.4.5';
package '1.5.0' "Version 1.5.0 (r5856, 2010-07-13)"
annotation(Documentation(info="<html>
This OpenModelica 1.5 release has major improvements in the OpenModelica compiler frontend and some in the backend. A major improvement of this release is full flattening support for the MultiBody library as well as limited simulation support for MultiBody. Interesting new facilities are the interactive simulation and the integrated UML-Modelica modeling with ModelicaML. Approximately 4 person-years of additional effort have been invested in the compiler compared to the 1.4.5 version, e.g., in order to have a more complete coverage of Modelica 3.0, mainly focusing on improved flattening in the compiler frontend.
<h4>OpenModelica Compiler (OMC)</h4>
This release includes major improvements of the flattening frontend part of the OpenModelica Compiler (OMC) and some improvements of the backend, including, but not restricted to:
<ul>
<li>Improved flattening speed of at least a factor of 10 or more compared to the 1.4.5 release, primarily for larger models with inner-outer, but also speedup for other models, e.g. the robot model flattens in approximately 2 seconds.</li>
<li>Flattening of all MultiBody models, including all elementary models, breaking connection graphs, world object, etc. Moreover, simulation is now possible for at least five MultiBody models: Pendulum, DoublePendulum, InitSpringConstant, World, PointGravityWithPointMasses.</li>
<li>Progress in supporting the Media library, but simulation is not yet possible.</li>
<li>Support for enumerations, both in the frontend and the backend.</li>
<li>Support for expandable connectors.</li>
<li>Support for the inline and late inline annotations in functions.</li>
<li>Complete support for record constructors, also for records containing other records.</li>
<li>Full support for iterators, including nested ones.</li>
<li>Support for inferred iterator and for-loop ranges.</li>
<li>Support for the function derivative annotation.</li>
<li>Prototype of interactive simulation.</li>
<li>Prototype of integrated UML-Modelica modeling and simulation with ModelicaML.</li>
<li>A new bidirectional external Java interface for calling external Java functions, or for calling Modelica functions from Java.</li>
<li>Complete implementation of replaceable model extends.</li>
<li>Fixed problems involving arrays of unknown dimensions.</li>
<li>Limited support for tearing.</li>
<li>Improved error handling at division by zero.</li>
<li>Support for Modelica 3.1 annotations.</li>
<li>Support for all MetaModelica language constructs inside OpenModelica.</li>
<li>OpenModelica works also under 64-bit Linux and Mac 64-bit OSX.</li>
<li>Parallel builds and running test suites in parallel on multi-core platforms.</li>
<li>New OpenModelica text template language for easier implementation of code generators, XML generators, etc.</li>
<li>New OpenModelica code generators to C and C# using the text template language.</li>
<li>Faster simulation result data file output optionally as comma-separated values.</li>
<li>Many bug fixes.</li>
</ul>
It is now possible to graphically edit models using parts from the Modelica Standard Library 3.1, since the simForge graphical editor (from Politecnico di Milano) that is used together with OpenModelica has been updated to version 0.9.0 with a important new functionality, including support for Modelica 3.1 and 3.0 annotations. The 1.6 and 2.2.1 Modelica graphical annotation versions are still supported.
<h4>OpenModelica Notebook (OMNotebook)</h4>
Improvements in platform availability.
<ul>
<li>Support for 64-bit Linux.</li>
<li>Support for Windows 7.</li>
<li>Better support for MacOS, including 64-bit OSX.</li>
</ul>
<h4>OpenModelica Shell (OMShell)</h4>
Same as previously.
<h4>OpenModelica Eclipse Plug-in (MDT)</h4>
Minor bug fixes.
<h4>OpenModelica Development Environment (OMDev)</h4>
Minor bug fixes.
</html>"));
end '1.5.0';
package '1.6.0' "Version 1.6.0 (r7524, 2010-12-21)"
annotation(Documentation(info="<html>
The OpenModelica 1.6 release primarily contains flattening, simulation, and performance improvements regarding Modelica Standard Library 3.1 support, but also has an interesting new tool - the OMEdit graphic connection editor, and a new educational material called DrControl, and an improved ModelicaML UML/Modelica profile with better support for modeling and requirement handling.
<h4>OpenModelica Compiler (OMC)</h4>
This release includes bug fix and performance improvemetns of the flattening frontend part of the OpenModelica Compiler (OMC) and some improvements of the backend, including, but not restricted to:
<ul>
<li>Flattening of the whole Modelica Standard Library 3.1 (MSL 3.1), except Media and Fluid.</li>
<li>Improved flattening speed of a factor of 5-20 compared to OpenModelica 1.5 for a number of models, especially in the MultiBody library.</li>
<li>Reduced memory consumption by the OpenModelica compiler frontend, for certain large models a reduction of a factor 50.</li>
<li>Reorganized, more modular OpenModelica compiler backend, can now handle approximately 30000 equations, compared to previously approximately 10000 equations.</li>
<li>Better error messages from the compiler, especially regarding functions.</li>
<li>Improved simulation coverage of MSL 3.1. Many models that did not simulate before are now simulating. However, there are still many models in certain sublibraries that do not simulate.</li>
<li>Progress in supporting the Media library, but simulation is not yet possible.</li>
<li>Improved support for enumerations, both in the frontend and the backend.</li>
<li>Implementation of stream connectors.</li>
<li>Support for linearization through symbolic Jacobians.</li>
<li>Many bug fixes.</li>
</ul>
<h4>OpenModelica Notebook (OMNotebook)</h4>
A new DrControl electronic notebook for teaching control and modeling with Modelica.
<h4>OpenModelica Shell (OMShell)</h4>
Same as previously.
<h4>OpenModelica Eclipse Plug-in (MDT)</h4>
Same as previously.
<h4>OpenModelica Development Environment (OMDev)</h4>
Several enhancements. Support for match-expressions in addition to matchcontinue. Support for real if-then-else. Support for if-then without else-branches. Modelica Development Tooling 0.7.7 with small improvements such as more settings, improved error detection in console, etc.
<h4>New Graphic Editor OMEdit</h4>
A new improved open source graphic model connection editor called OMEdit, supporting 3.1 graphical annotations, which makes it possible to move models back and forth to other tools without problems. The editor has been implemented by students at Linköping University and is based on the C++ Qt library.
</html>"));
end '1.6.0';
package '1.7.0' "Version 1.7.0 (r8711, 2011-04-20)"
annotation(Documentation(info="<html>
The OpenModelica 1.7 release contains OMC flattening improvements for the Media library, better and faster event handling and simulation, and fast MetaModelica support in the compiler, enabling it to compiler itself. This release also includes two interesting new tools - the OMOpttim optimization subsystem, and a new performance profiler for equation-based Modelica models.
<h4>OpenModelica Compiler (OMC)</h4>
This release includes bug fixes and performance improvements of the flattening frontend part of the OpenModelica Compiler (OMC) and several improvements of the backend, including, but not restricted to:
<ul>
<li>Flattening of the whole Modelica Standard Library 3.1 (MSL 3.1), except Media and Fluid.</li>
<li>Progress in supporting the Media library, some models now flatten.</li>
<li>Much faster simulation of many models through more efficient handling of alias variables, binary output format, and faster event handling.</li>
<li>Faster and more stable simulation through new improved event handling, which is now default.</li>
<li>Simulation result storage in binary .mat files, and plotting from such files.</li>
<li>Support for Unicode characters in quoted Modelica identifiers, including Japanese and Chinese.</li>
<li>Preliminary MetaModelica 2.0 support. (use setCommandLineOptions({\"+g=MetaModelica\"}) ). Execution is as fast as MetaModelica 1.0, except for garbage collection.</li>
<li>Preliminary bootstrapped OpenModelica compiler: OMC now compiles itself, and the bootstrapped compiler passes the test suite. A garbage collector is still missing.</li>
<li>Many bug fixes.</li>
</ul>
<h4>OpenModelica Notebook (OMNotebook)</h4>
Improved much faster and more stable 2D plotting through the new OMPlot module. Plotting from binary .mat files. Better integration between OMEdit and OMNotebook, copy/paste between them.
<h4>OpenModelica Shell (OMShell)</h4>
Same as previously, except the improved 2D plotting through OMPlot.
<h4>OpenModelica Eclipse Plug-in (MDT)</h4>
Same as previously.
<h4>OpenModelica Development Environment (OMDev)</h4>
No changes.
<h4>Graphic Editor OMEdit</h4>
Several enhancements of OMEdit are included in this release. Support for Icon editing is now available. There is also an improved much faster 2D plotting through the new OMPlot module. Better integration between OMEdit and OMNotebook, with copy/paste between them. Interactive on-line simulation is available in an easy-to-use way.
<h4>New OMOptim Optimization Subsystem</h4>
A new optimization subsystem called OMOptim has been added to OpenModelica. Currently, parameter optimization using genetic algorithms is supported in this version 0.9. Pareto front optimization is also supported.
<h4>New Performance Profiler</h4>
A new, low overhead, performance profiler for Modelica models has been developed.
</html>"));
end '1.7.0';
package '1.8.0' "Version 1.8.0 (r10584, 2011-11-25)"
annotation(Documentation(info="<html>
The OpenModelica 1.8 release contains OMC flattening improvements for the Media library - it now flattens the whole library and simulates about 20% of its example models. Moreover, about half of the Fluid library models also flatten. This release also includes two new tool functionalities - the FMI for model exchange import and export, and a new efficient Eclipse-based debugger for Modelica/MetaModelica algorithmic code.
<h4>OpenModelica Compiler (OMC)</h4>
This release includes bug fixes and improvements of the flattening frontend part of the OpenModelica Compiler (OMC) and several improvements of the backend, including, but not restricted to:
A faster and more stable OMC model compiler. The 1.8.0 version flattens and simulates more models than the previous 1.7.0 version.
<ul>
<li>Flattening of the whole Media library, and about half of the Fluid library. Simulation of approximately 20% of the Media library example models.</li>
<li>Functional Mockup Interface FMI 1.0 for model exchange, export and import, for the Windows platform.</li>
<li>Bug fixes in the OpenModelica graphical model connection editor OMEdit, supporting easy-to-use graphical drag-and-drop modeling and MSL 3.1.</li>
<li>Bug fixes in the OMOptim optimization subsystem.</li>
<li>Beta version of compiler support for a new Eclipse-based very efficient algorithmic code debugger for functions in MetaModelica/Modelica, available in the development environment when using the bootstrapped OpenModelica compiler.</li>
<li>Improvements in initialization of simulations.</li>
<li>Improved index reduction with dynamic state selection, which improves simulation.</li>
<li>Better error messages from several parts of the compiler, including a new API call for giving better error messages.</li>
<li>Automatic partitioning of equation systems and multi-core parallel simulation of independent parts based on the shared-memory OpenMP model. This version is a preliminary experimental version without load balancing.</li>
</ul>
<h4>OpenModelica Notebook (OMNotebook)</h4>
No changes.
<h4>OpenModelica Shell (OMShell)</h4>
Small performance improvements.
<h4>OpenModelica Eclipse Plug-in (MDT)</h4>
Small fixes and improvements. MDT now also includes a beta version of a new Eclipse-based very efficient algorithmic code debugger for functions in MetaModelica/Modelica.
<h4>OpenModelica Development Environment (OMDev)</h4>
Third party binaries, including Qt libraries and executable Qt clients, are now part of the OMDev package. Also, now uses GCC 4.4.0 instead of the earlier GCC 3.4.5.
<h4>Graphic Editor OMEdit</h4>
Bug fixes. Access to FMI Import/Export through a pull-down menu. Improved configuration of library loading. A function to go to a specific line number. A button to cancel an on-going simulation. Support for some updated OMC API calls.
<h4>New OMOptim Optimization Subsystem</h4>
Bug fixes, especially in the Linux version.
<h4>FMI Support</h4>
The Functional Mockup Interface FMI 1.0 for model exchange import and export is supported by this release. The functionality is accessible via API calls as well as via pull-down menu commands in OMEdit.
</html>"));
end '1.8.0';
package '1.8.1' "Version 1.8.1 (r11645, 2012-04-03)"
annotation(Documentation(info="<html>
<p>The OpenModelica 1.8.1 release has a faster and more stable OMC model compiler. It flattens and simulates more models than the previous 1.8.0 version. Significant flattening speedup of the compiler has been achieved for certain large models. It also contains a New ModelicaML version with support for value bindings in requirements-driven modeling and importing Modelica library models into ModelicaML models. A beta version of the new OpenModelica Python scripting is also included.</p>
<h4>OpenModelica Compiler (OMC)</h4>
<p>This release includes bug fixes and improvements of the flattening frontend part of the OpenModelica Compiler (OMC) and several improvements of the backend, including, but not restricted to:</p>
<ul>
<li>A faster and more stable OMC model compiler. The 1.8.1 version flattens and simulates more models than the previous 1.8.0 version.</li>
<li>Support for operator overloading (except Complex numbers).</li>
<li>New ModelicaML version with support for value bindings in requirements-driven modeling and importing Modelica library models into ModelicaML models.</li>
<li>Faster plotting in OMNotebook. The feature sendData has been removed from OpenModelica. As a result, the kernel no longer depends on Qt. The plot3() family of functions have now replaced to plot(), which in turn have been removed. The non-standard visualize() command has been removed in favour of more recent alternatives.</li>
<li>Store OpenModelica documentation as Modelica <a href=\"modelica://ModelicaReference.Annotations.Documentation\">Documentation</a> annotations.</li>
<li>Re-implementation of the simulation runtime using C instead of C++ (this was needed to export FMI source-based packages).</li>
<li>FMI import/export bug fixes.</li>
<li>Changed the internal representation of various structures to share more memory. This significantly improved the performance for very large models that use records.</li>
<li>Faster model flattening, Improved simulation, some graphical API bug fixes.</li>
<li>More robust and general initialization, but currently time-consuming.</li>
<li>New initialization flags to omc and options to simulate(), to control whether fast or robust initialization is selected, or initialization from an external (.mat) data file.</li>
<li>New options to API calls list, loadFile, and more.</li>
<li>Enforce the restriction that input arguments of functions may not be assigned to.</li>
<li>Improved the scripting environment. cl := $TypeName(Modelica);getClassComment(cl); now works as expected. As does looping over lists of typenames and using reduction expressions.</li>
<li>Beta version of Python scripting.</li>
<li>Various bugfixes.</li>
<li>NOTE: interactive simulation is not operational in this release. It will be put back again in the near future, first available as a nightly build. It is also available in the previous 1.8.0 release.</li>
</ul>
<h4>OpenModelica Notebook (OMNotebook)</h4>
<ul>
<li>Faster and more stable plottning.</li>
</ul>
<h4>OpenModelica Shell (OMShell)</h4>
<ul>
<li>No changes.</li>
</ul>
<h4>OpenModelica Eclipse Plug-in (MDT)</h4>
<ul>
<li>Small fixes and improvements.</li>
</ul>
<h4>OpenModelica Development Environment (OMDev)</h4>
<ul>
<li>No changes.</li>
</ul>
<h4>Graphic Editor OMEdit</h4>
<ul>
<li>Bug fixes.</li>
</ul>
<h4>OMOptim Optimization Subsystem</h4>
<ul>
<li>Bug fixes.</li>
</ul>
<h4>FMI Support</h4>
<ul>
<li>Bug fixes.</li>
</ul>
</html>"));
end '1.8.1';
package '1.9.0' "Version 1.9.0 (2012-08-31)"
  annotation(Documentation(info = "<html>
<head>
<meta name=\"generator\" content=
\"HTML Tidy for Linux (vers 25 March 2009), see www.w3.org\" />
<title>ReleaseNotes/1.9.0 – OpenModelica</title>
<meta http-equiv=\"Content-Type\" content=
\"text/html; charset=utf-8\" /><!--[if lt IE 7]>
    <script type=\"text/javascript\" src=\"/OpenModelica/chrome/common/js/ie_pre7_hacks.js\"></script>
    <![endif]-->

<style type=\"text/css\">
/*<![CDATA[*/
body { background: #fff; color: #000; margin: 10px; padding: 0; }
body, th, tr {
 font: normal 13px Verdana,Arial,'Bitstream Vera Sans',Helvetica,sans-serif;
}
h1, h2, h3, h4 {
 font-family: Arial,Verdana,'Bitstream Vera Sans',Helvetica,sans-serif;
 font-weight: bold;
 letter-spacing: -0.018em;
 page-break-after: avoid;
}
h1 { font-size: 19px; margin: .15em 1em 0.5em 0 }
h2 { font-size: 16px }
h3 { font-size: 14px }
hr { border: none;  border-top: 1px solid #ccb; margin: 2em 0 }
address { font-style: normal }
img { border: none }

.underline { text-decoration: underline }
ol.loweralpha { list-style-type: lower-alpha }
ol.upperalpha { list-style-type: upper-alpha }
ol.lowerroman { list-style-type: lower-roman }
ol.upperroman { list-style-type: upper-roman }
ol.arabic     { list-style-type: decimal }

/* Link styles */
:link, :visited {
 text-decoration: none;
 color: #b00;
 border-bottom: 1px dotted #bbb;
}
:link:hover, :visited:hover { background-color: #eee; color: #555 }
h1 :link, h1 :visited ,h2 :link, h2 :visited, h3 :link, h3 :visited,
h4 :link, h4 :visited, h5 :link, h5 :visited, h6 :link, h6 :visited {
 color: inherit;
}
.trac-rawlink { border-bottom: none }

/* Heading anchors */
.anchor:link, .anchor:visited {
 border: none;
 color: #d7d7d7;
 font-size: .8em;
 vertical-align: text-top;
}
* > .anchor:link, * > .anchor:visited {
 visibility: hidden;
}
h1:hover .anchor, h2:hover .anchor, h3:hover .anchor,
h4:hover .anchor, h5:hover .anchor, h6:hover .anchor,
span:hover .anchor {
 visibility: visible;
}

@media screen {
 a.ext-link .icon {
  padding-left: 12px;
 }
 a.mail-link .icon {
  padding-left: 14px;
 }
}

/* Forms */
input, textarea, select { margin: 2px }
input, select { vertical-align: middle }
input[type=button], input[type=submit], input[type=reset] {
 background: #eee;
 color: #222;
 border: 1px outset #ccc;
 padding: .1em .5em;
}
input[type=button]:hover, input[type=submit]:hover, input[type=reset]:hover {
 background: #ccb;
}
input[type=button][disabled], input[type=submit][disabled],
input[type=reset][disabled] {
 background: #f6f6f6;
 border-style: solid;
 color: #999;
}
input[type=text], input.textwidget, textarea { border: 1px solid #d7d7d7 }
input[type=text], input.textwidget { padding: .25em .5em }
input[type=text]:focus, input.textwidget:focus, textarea:focus {
 border: 1px solid #886;
}
option { border-bottom: 1px dotted #d7d7d7 }
fieldset { border: 1px solid #d7d7d7; padding: .5em; margin: 1em 0 }
p.hint, span.hint { color: #666; font-size: 85%; font-style: italic; margin: .5em 0;
  padding-left: 1em;
}
fieldset.iefix {
  background: transparent;
  border: none;
  padding: 0;
  margin: 0;
}
* html fieldset.iefix { width: 98% }
fieldset.iefix p { margin: 0 }
legend { color: #999; padding: 0 .25em; font-size: 90%; font-weight: bold }
label.disabled { color: #d7d7d7 }
.buttons { margin: .5em .5em .5em 0 }
.buttons form, .buttons form div { display: inline }
.buttons input { margin: 1em .5em .1em 0 }
.inlinebuttons input {
 font-size: 70%;
 border-width: 1px;
 border-style: dotted;
 margin: 0 .1em;
 padding: 0.1em;
 background: none;
}

/* Header */
#header hr { display: none }
#header h1 { margin: 1.5em 0 -1.5em; padding: 0 }
#header img { border: none; margin: 0 0 -3em }
#header :link, #header :visited, #header :link:hover, #header :visited:hover {
 background: transparent;
 color: #555;
 margin-bottom: 2px;
 border: none;
 padding: 0;
}
#header h1 :link:hover, #header h1 :visited:hover { color: #000 }

/* Quick search */
#search {
 clear: both;
 font-size: 10px;
 height: 2.2em;
 margin: 0 0 1em;
 text-align: right;
}
#search input { font-size: 10px }
#search label { display: none }

/* Navigation */
.nav h2, .nav hr { display: none }
.nav ul {
 font-size: 10px;
 list-style: none;
 margin: 0;
 text-align: right;
}
.nav li {
 border-right: 1px solid #d7d7d7;
 display: inline;
 padding: 0 .75em;
 white-space: nowrap;
}
.nav li.last { border-right: none }

/* Main navigation bar */
#mainnav {
 border: 1px solid #000;
 font: normal 10px verdana,'Bitstream Vera Sans',helvetica,arial,sans-serif;
 margin: .66em 0 .33em;
 padding: .2em 0;
}
#mainnav li { border-right: none; padding: .25em 0 }
#mainnav :link, #mainnav :visited {
 border-right: 1px solid #fff;
 border-bottom: none;
 border-left: 1px solid #555;
 color: #000;
 padding: .2em 20px;
}
* html #mainnav :link, * html #mainnav :visited { background-position: 1px 0 }
#mainnav :link:hover, #mainnav :visited:hover {
 background-color: #ccc;
 border-right: 1px solid #ddd;
}
#mainnav .active :link, #mainnav .active :visited {
 border-top: none;
 border-right: 1px solid #000;
 color: #eee;
 font-weight: bold;
}
#mainnav .active :link:hover, #mainnav .active :visited:hover {
 border-right: 1px solid #000;
}

/* Context-dependent navigation links */
#ctxtnav { min-height: 1em }
#ctxtnav li ul {
 background: #f7f7f7;
 color: #ccc;
 border: 1px solid;
 padding: 0;
 display: inline;
 margin: 0;
}
#ctxtnav li li { padding: 0; }
#ctxtnav li li :link, #ctxtnav li li :visited { padding: 0 1em }
#ctxtnav li li :link:hover, #ctxtnav li li :visited:hover {
 background: #bba;
 color: #fff;
}

.trac-nav, .trac-topnav {
 float: right;
 font-size: 80%;
}
.trac-topnav {
 margin-top: 14px;
}

/* Alternate links */
#altlinks { clear: both; text-align: center }
#altlinks h3 { font-size: 12px; letter-spacing: normal; margin: 0 }
#altlinks ul { list-style: none; margin: 0; padding: 0 0 1em }
#altlinks li {
 border-right: 1px solid #d7d7d7;
 display: inline;
 font-size: 11px;
 line-height: 1.5;
 padding: 0 1em;
 white-space: nowrap;
}
#altlinks li.last { border-right: none }
#altlinks li :link, #altlinks li :visited {
 background-repeat: no-repeat;
 color: #666;
 border: none;
 padding: 0 0 2px;
}

/* Footer */
#footer {
  clear: both;
  color: #bbb;
  font-size: 10px;
  border-top: 1px solid;
  height: 31px;
  padding: .25em 0;
}
#footer :link, #footer :visited { color: #bbb; }
#footer hr { display: none }
#footer #tracpowered { border: 0; float: left }
#footer #tracpowered:hover { background: transparent }
#footer p { margin: 0 }
#footer p.left {
  float: left;
  margin-left: 1em;
  padding: 0 1em;
  border-left: 1px solid #d7d7d7;
  border-right: 1px solid #d7d7d7;
}
#footer p.right {
  float: right;
  text-align: right;
}

#content { padding-bottom: 2em; position: relative }

#help {
 clear: both;
 color: #999;
 font-size: 90%;
 margin: 1em;
 text-align: right;
}
#help :link, #help :visited { cursor: help }
#help hr { display: none }

/* Section folding */
.foldable :link, .foldable :visited {
 border: none;
 padding-left: 16px;
}
.foldable :link:hover, .foldable :visited:hover { background-color: transparent }
.collapsed > .foldable :link, .collapsed > .foldable :visited {
}
.collapsed > div, .collapsed > table, .collapsed > ul, .collapsed > dl { display: none }
fieldset > legend.foldable :link, fieldset > legend.foldable :visited {
 color: #666;
 font-size: 110%;
}

/* Page preferences form */
#prefs {
 background: #f7f7f0;
 border: 1px outset #998;
 float: right;
 font-size: 9px;
 padding: .8em;
 position: relative;
 margin: 0 1em 1em;
}
#prefs input, #prefs select { font-size: 9px; vertical-align: middle }
#prefs fieldset {
 background: transparent;
 border: none;
 margin: .5em;
 padding: 0;
}
#prefs fieldset legend {
 background: transparent;
 color: #000;
 font-size: 9px;
 font-weight: normal;
 margin: 0 0 0 -1.5em;
 padding: 0;
}
#prefs .buttons { text-align: right }

/* Version information (browser, wiki, attachments) */
#info {
 margin: 1em 0 0 0;
 background: #f7f7f0;
 border: 1px solid #d7d7d7;
 border-collapse: collapse;
 border-spacing: 0;
 clear: both;
 width: 100%;
}
#info th, #info td { font-size: 85%; padding: 2px .5em; vertical-align: top }
#info th { font-weight: bold; text-align: left; white-space: nowrap }
#info td.message { width: 100% }
#info .message ul { padding: 0; margin: 0 2em }
#info .message p { margin: 0; padding: 0 }

/* Wiki */
.wikipage { padding-left: 18px }
.wikipage h1, .wikipage h2, .wikipage h3 { margin-left: -18px }
.wikipage table h1, .wikipage table h2, .wikipage table h3 { margin-left: 0px }
div.compact > p:first-child { margin-top: 0 }
div.compact > p:last-child { margin-bottom: 0 }

a.missing:link, a.missing:visited, a.missing, span.missing,
a.forbidden, span.forbidden { color: #998 }
a.missing:hover { color: #000 }
a.closed:link, a.closed:visited, span.closed { text-decoration: line-through }

/* User-selectable styles for blocks */
.important {
 background: #fcb;
 border: 1px dotted #d00;
 color: #500;
 padding: 0 .5em 0 .5em;
 margin: .5em;
}

dl.wiki dt { font-weight: bold }
dl.compact dt { float: left; padding-right: .5em }
dl.compact dd { margin: 0; padding: 0 }

pre.wiki, pre.literal-block {
 background: #f7f7f7;
 border: 1px solid #d7d7d7;
 margin: 1em 1.75em;
 padding: .25em;
 overflow: auto;
}

blockquote.citation {
 margin: -0.6em 0;
 border-style: solid;
 border-width: 0 0 0 2px;
 padding-left: .5em;
 border-color: #b44;
}
.citation blockquote.citation { border-color: #4b4; }
.citation .citation blockquote.citation { border-color: #44b; }
.citation .citation .citation blockquote.citation { border-color: #c55; }

table.wiki {
 border: 1px solid #ccc;
 border-collapse: collapse;
 border-spacing: 0;
}
table.wiki td { border: 1px solid #ccc;  padding: .1em .25em; }
table.wiki th {
 border: 1px solid #bbb;
 padding: .1em .25em;
 background-color: #f7f7f7;
}

.wikitoolbar {
 margin-top: 0.3em;
 margin-left: 2px;
 border: solid #d7d7d7;
 border-width: 1px 1px 1px 0;
 height: 18px;
 width: 234px;
}
.wikitoolbar :link, .wikitoolbar :visited {
 border: 1px solid #fff;
 border-left-color: #d7d7d7;
 cursor: default;
 display: block;
 float: left;
 width: 24px;
 height: 16px;
}
.wikitoolbar :link:hover, .wikitoolbar :visited:hover {
 background-color: transparent;
 border: 1px solid #fb2;
}
.wikitoolbar a#em { background-position: 0 0 }
.wikitoolbar a#strong { background-position: 0 -16px }
.wikitoolbar a#heading { background-position: 0 -32px }
.wikitoolbar a#link { background-position: 0 -48px }
.wikitoolbar a#code { background-position: 0 -64px }
.wikitoolbar a#hr { background-position: 0 -80px }
.wikitoolbar a#np { background-position: 0 -96px }
.wikitoolbar a#br { background-position: 0 -112px }
.wikitoolbar a#img { background-position: 0 -128px }

/* Textarea resizer */
div.trac-resizable { display: table; width: 1px }
div.trac-resizable > div { display: table-cell }
div.trac-resizable textarea { display: block; margin-bottom: 0 }
div.trac-grip {
 height: 5px;
 overflow: hidden;
 border: 1px solid #ddd;
 border-top-width: 0;
 cursor: s-resize;
}

/* Styles for the form for adding attachments. */
#attachment .field { margin-top: 1.3em }
#attachment label { padding-left: .2em }
#attachment fieldset { margin-top: 2em }
#attachment fieldset .field { float: left; margin: 0 1em .5em 0 }
#attachment .options { float: left; padding: 0 0 1em 1em }
#attachment br { clear: left }
.attachment #preview { margin-top: 1em }

/* Styles for the list of attachments. */
#attachments > div { border: 1px outset #996; padding: 1em }
#attachments .attachments { margin-left: 2em; padding: 0 }
#attachments dt { display: list-item; list-style: square; }
#attachments dd { font-style: italic; margin-left: 0; padding-left: 0; }

/* Styles for tabular listings such as those used for displaying directory
   contents and report results. */
table.listing {
 clear: both;
 border-bottom: 1px solid #d7d7d7;
 border-collapse: collapse;
 border-spacing: 0;
 margin-top: 1em;
 width: 100%;
}
table.listing th { text-align: left; padding: 0 1em .1em 0; font-size: 12px }
table.listing thead tr { background: #f7f7f0 }
table.listing thead th {
 border: 1px solid #d7d7d7;
 border-bottom-color: #999;
 font-size: 11px;
 font-weight: bold;
 padding: 2px .5em;
 vertical-align: bottom;
 white-space: nowrap;
}
table.listing thead th :link:hover, table.listing thead th :visited:hover {
 background-color: transparent;
}
table.listing thead th a { border: none; padding-right: 12px }
table.listing th.asc a, table.listing th.desc a {
 font-weight: bold;
 background-position: 100% 50%;
 background-repeat: no-repeat;
}
table.listing tbody td, table.listing tbody th {
 border: 1px dotted #ddd;
 padding: .3em .5em;
 vertical-align: top;
}
table.listing tbody td a:hover, table.listing tbody th a:hover {
 background-color: transparent;
}
table.listing tbody tr { border-top: 1px solid #ddd }
table.listing tbody tr.even { background-color: #fcfcfc }
table.listing tbody tr.odd { background-color: #f7f7f7 }
table.listing tbody tr:hover { background: #eed !important }
table.listing tbody tr.focus { background: #ddf !important }

/* Styles for the page history table
   (extends the styles for \"table.listing\") */
#fieldhist td { padding: 0 .5em }
#fieldhist td.date, #fieldhist td.diff, #fieldhist td.version,
#fieldhist td.author {
 white-space: nowrap;
}
#fieldhist td.version { text-align: center }
#fieldhist td.comment { width: 100% }

/* Auto-completion interface */
.suggestions { background: #fff; border: 1px solid #886; color: #222; }
.suggestions ul {
  font-family: sans-serif;
  max-height: 20em;
  min-height: 3em;
  list-style: none;
  margin: 0;
  overflow: auto;
  padding: 0;
  width: 440px;
}
* html .suggestions ul { height: 10em; }
.suggestions li { background: #fff; cursor: pointer; padding: 2px 5px }
.suggestions li.selected { background: #b9b9b9 }

/* Styles for the error page (and rst errors) */
#content.error .message, div.system-message {
 background: #fdc;
 border: 2px solid #d00;
 color: #500;
 padding: .5em;
 margin: 1em 0;
}
#content.error div.message pre, div.system-message pre {
  margin-left: 1em;
  overflow: hidden;
  white-space: normal;
}
div.system-message p { margin: 0; }
div.system-message p.system-message-title { font-weight: bold; }

#warning.system-message, .warning.system-message { background: #ffb; border: 1px solid #000; }
#warning.system-message li { list-style-type: square; }

#notice.system-message, .notice.system-message { background: #dfd; border: 1px solid #000; }
#notice.system-message li { list-style-type: square; }

#content.error form.newticket { display: inline; }
#content.error form.newticket textarea { display: none; }

#content.error #systeminfo, #content.error #plugins { margin: 1em; width: auto; }
#content.error #systeminfo th, #content.error #systeminfo td,
#content.error #plugins th, #content.error #plugins td { font-size: 90%; }
#content.error #systeminfo th, #content.error #plugins th { background: #f7f7f7; font-weight: bold; }

#content.error #traceback { margin-left: 1em; }
#content.error #traceback :link, #content.error #traceback :visited {
  border: none;
}
#content.error #tbtoggle { font-size: 80%; }
#content.error #traceback div { margin-left: 1em; }
#content.error #traceback h3 { font-size: 95%; margin: .5em 0 0; }
#content.error #traceback :link var, #content.error #traceback :visited var {
  font-family: monospace;
  font-style: normal;
  font-weight: bold;
}
#content.error #traceback span.file { color: #666; font-size: 85%; }
#content.error #traceback ul { list-style: none; margin: .5em 0; padding: 0; }
#content.error #traceback table.code td { white-space: pre; font-size: 90%; }
#content.error #traceback table.code tr.current td { background: #e6e6e6; }
#content.error #traceback table { margin: .5em 0 1em;  }
#content.error #traceback th, #content.error #traceback td {
  font-size: 85%; padding: 1px;
}
#content.error #traceback th var {
  font-family: monospace;
  font-style: normal;
}
#content.error #traceback td code { white-space: pre; }
#content.error #traceback pre { font-size: 95%; }

#content.error #plugins td.file { color: #666; }

#content .paging { margin: 0 0 2em; padding: .5em 0 0;
  font-size: 85%; line-height: 2em; text-align: center;
}
#content .paging .current {
  padding: .1em .3em;
  border: 1px solid #333;
  background: #999; color: #fff;
}

#content .paging :link, #content .paging :visited {
  padding: .1em .3em;
  border: 1px solid #666;
  background: transparent; color: #666;
}
#content .paging :link:hover, #content .paging :visited:hover {
  background: #999; color: #fff;  border-color: #333;
}
#content .paging .previous a,
#content .paging .next a {
  font-size: 150%; font-weight: bold; border: none;
}
#content .paging .previous a:hover,
#content .paging .next a:hover {
  background: transparent; color: #666;
}

#content h2 .numresults { color: #666; font-size: 90%; }

/* Styles for search word highlighting */
@media screen {
 .searchword0 { background: #ff9 }
 .searchword1 { background: #cfc }
 .searchword2 { background: #cff }
 .searchword3 { background: #ccf }
 .searchword4 { background: #fcf }
}

@media print {
 #header, #altlinks, #footer, #help { display: none }
 .nav, form, .buttons form, form .buttons, form .inlinebuttons,
 .noprint, .trac-rawlink, .trac-nav, .trac-topnav {
   display: none;
 }
 form.printableform { display: block }
}
/*]]>*/
</style>
</head>
<body>
<div id=\"main\">
<div id=\"content\" class=\"wiki\">
<div class=\"wikipage searchable\">
<div id=\"wikipage\">
<div style=\"float: right; margin: 0 1em\" class=\"wikipage\">
<blockquote>
<p>&larr; <a class=\"wiki\" href=
\"https://trac.openmodelica.org/OpenModelica/wiki/ReleaseNotes/1.8.1\">
1.8.1</a> | <a class=\"missing wiki\" href=
\"https://trac.openmodelica.org/OpenModelica/wiki/ReleaseNotes/Future\"
rel=\"nofollow\">Future?</a> &rarr;</p>
</blockquote>
</div>
<div style=
\"margin-top: .5em; padding: 0 1em; background-color: #ffd; border:1px outset #ddc; text-align: center; clear: right\"
class=\"wikipage\">
<p>This is not the final release version</p>
</div>
<h1 id=\"ReleaseNotesforOpenModelica1.9.0Beta3Release\">Release Notes
for OpenModelica <a class=\"milestone\" href=
\"https://trac.openmodelica.org/OpenModelica/milestone/1.9.0\">1.9.0</a>
Beta3 Release</h1>
<div class=\"wiki-toc\">
<ol>
<li><a href=\"#OpenModelicaCompilerOMC\">OpenModelica Compiler
(OMC)</a></li>
<li><a href=\"#OtherOpenModelicaSubsystems\">Other OpenModelica
Subsystems</a></li>
<li><a href=\"#DetailedChanges\">Detailed Changes</a></li>
</ol>
</div>
<p>The OpenModelica 1.9.0 beta3 release has a more complete OMC
model compiler. It simulates many more models than the previous
1.8.1 version and 1.9.0 beta1 and beta2 releases. This is the first
release that simulates many (58%) of the MSL 3.2.1 Fluid models.
Regarding the whole MSL 3.2.1, 233 out of 253 example models now
simulate (92%) compared to 118 in the beta2 release Oct 20, and 30%
in the 1.9.0 beta1 release. There is also partial support for some
other libraries like ThermoSysPro. It also contains a further
improved ModelicaML version for the latest Eclipse and Papyrus
releases.</p>
<h2 id=\"OpenModelicaCompilerOMC\">OpenModelica Compiler (OMC)</h2>
<p>This release mainly includes bug fixes and improvements of the
OpenModelica Compiler (OMC), including, but not restricted to the
following:</p>
<ul>
<li>A more stable and complete OMC model compiler. The 1.9.0 beta3
version simulates many more models than the previous 1.8.1 version
and OpenModelica 1.9.0 beta1 and beta2 versions.</li>
<li>Much better simulation support for MSL 3.2.1, now 233 out of
253 example models simulate (92%) compared to 118 in the beta2
release Oct 20, and 30% in the 1.9.0 beta1 release.</li>
<li>Good support for the MSL 3.2.1 MultiBody library. All example
models except one simulate using dynamic state selection, the
remaining one simulates with a special flag.</li>
<li>Fairly good support for the MSL 3.2.1 Fluid library, now 24
example models simulate (58%), and all flatten.</li>
<li>Better simulation support for several other libraries, e.g.
more than twenty examples simulate from ThermoSysPro, and all but
one model from PlanarMechanics simulate.</li>
<li>Improved tearing algorithm for the compiler backend. Tearing is
by default used.</li>
<li>Much faster matching and dynamic state selection algorithms for
the compiler backend.</li>
<li>New index reduction algorithm implementation.</li>
<li>New default initialization method that symbolically solves the
initialization problem much faster and more accurately. This is the
first version that in general initialize hybrid models
correctly.</li>
<li>Better class loading from files. The package.order file is now
respected and the file structure is more thoroughly examined
(<a class=\"closed ticket\" href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1764\" title=
\"defect: getClassNames and list should care of package.order (closed: fixed)\">#1764</a>).</li>
<li>It is now possible to translate the error messages in the omc
kernel (<a class=\"closed ticket\" href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1767\" title=
\"task: Translations of the omc kernel (closed: fixed)\">#1767</a>).
Swedish and German language translations available.</li>
<li>Enhanced ModelicaML version with support for value bindings in
requirements-driven modeling available for the latest Eclipse and
Papyrus versions. GUI specific adaptations. Automated model
composition workflows (used for model-based design verification
against requirements) are modularized and have improved in terms of
performance.</li>
<li>FMI for co-simulation with OMC as master, and improved FMI
import.</li>
<li>Checking (when possible) that variables have been assigned to
before they are used in algorithmic code (<a class=\"closed ticket\"
href=\"https://trac.openmodelica.org/OpenModelica/ticket/1776\"
title=\"defect: Add detection of usage of unbound variables (closed: fixed)\">#1776</a>).</li>
<li>Full version of Python scripting.</li>
<li>3D graphics visualization using the Modelica3D library.</li>
<li>Prototype support for uncertainty computations, special feature
enabled by special flag.</li>
<li>Parallel algorithmc Modelica support (ParModelica) for
efficient portable parallel algorithmic programming based on the
OpenCL standard, for CPUs and GPUs.</li>
<li>Support for optimisation of semiLinear according to MSL 3.3
chapter 3.7.2.5 semiLinear (<a class=\"changeset\" href=
\"https://trac.openmodelica.org/OpenModelica/changeset/12657\" title=
\"- add support for semiLinear optimization, see MSL Spec 3.7.2.5\">r12657</a>,<a class=\"changeset\"
href=\"https://trac.openmodelica.org/OpenModelica/changeset/12658\"
title=
\"- use noEvent for y = semiLinear(x,sa,s1) -&gt; s1 = if noEvent(x&gt;=0) then ...\">r12658</a>).</li>
<li>NOTE: interactive simulation is not operational in this beta
release. It will be put back again in the near future, first
available as a nightly build. It is also available in the previous
1.8.0 release.</li>
</ul>
<h2 id=\"OtherOpenModelicaSubsystems\">Other OpenModelica
Subsystems</h2>
<ul>
<li><strong><em>OpenModelica Notebook (OMNotebook)</em></strong>. A
<tt>shortOutput</tt> option has been introduced in the simulate
command for less verbose output. The DrModelica interactive
document has been updated and the models tested. Almost all models
now simulate with OpenModelica.</li>
<li><strong><em>OpenModelica Eclipse Plug-in (MDT).</em></strong>
Enhanced debugger for algorithmic Modelica code, supporting both
standard Modelica algorithmic code called from simulation models,
and MetaModelica code.</li>
<li><strong><em>OpenModelica Development Environment
(OMDev.)</em></strong> Migration of version handling and
configuration management from CodeBeamer to Trac.</li>
<li><strong><em>Graphic Editor OMEdit:</em></strong>
<ul>
<li>Options to set matching algorithm and index reduction method
for simulation.</li>
<li>Backward and Forward navigation support in Documentation
view.</li>
<li>Output window for simulations.</li>
<li>Preserving user customizations.</li>
<li>Show dummy red box for models with no graphical
annotations.</li>
</ul>
</li>
</ul>
<h2 id=\"DetailedChanges\">Detailed Changes</h2>
<div xmlns=\"http://www.w3.org/1999/xhtml\">
<h2 class=\"report-result\">Component: Backend <span class=
\"numrows\">(50 matches)</span></h2>
<table class=\"listing tickets\">
<thead>
<tr class=\"trac-columns\">
<th class=\"id asc\"><a title=\"Sort by Ticket (descending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;desc=1&amp;order=id\">
Ticket</a></th>
<th class=\"summary\"><a title=\"Sort by Summary (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=summary\">
Summary</a></th>
<th class=\"resolution\"><a title=\"Sort by Resolution (ascending)\"
href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=resolution\">
Resolution</a></th>
<th class=\"owner\"><a title=\"Sort by Owner (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=owner\">
Owner</a></th>
<th class=\"type\"><a title=\"Sort by Type (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=type\">
Type</a></th>
<th class=\"priority\"><a title=\"Sort by Priority (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=priority\">
Priority</a></th>
<th class=\"version\"><a title=\"Sort by Version (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=version\">
Version</a></th>
</tr>
</thead>
<tbody>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1664\" title=
\"View ticket\" class=\"closed\">#1664</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1664\" title=
\"View ticket\">Initialization seems to get stuck on model:
Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.fullRobot</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1670\" title=
\"View ticket\" class=\"closed\">#1670</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1670\" title=
\"View ticket\">Update help()</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1676\" title=
\"View ticket\" class=\"closed\">#1676</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1676\" title=
\"View ticket\">Simulation Executable Crashes</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adeas31</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1690\" title=
\"View ticket\" class=\"closed\">#1690</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1690\" title=
\"View ticket\">initial algorithm aren't considered while the
initialization</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">lochel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1691\" title=
\"View ticket\" class=\"closed\">#1691</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1691\" title=
\"View ticket\">M.E.Digital.Examples fail to run backend</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1692\" title=
\"View ticket\" class=\"closed\">#1692</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1692\" title=
\"View ticket\">Non-linear system causes stack protection
issues</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio4\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1708\" title=
\"View ticket\" class=\"closed\">#1708</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1708\" title=
\"View ticket\">Strip unused functions from generated code</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">normal</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio1\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1721\" title=
\"View ticket\" class=\"closed\">#1721</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1721\" title=
\"View ticket\">error division by zero</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">mohamed</td>
<td class=\"type\">defect</td>
<td class=\"priority\">blocker</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1735\" title=
\"View ticket\" class=\"closed\">#1735</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1735\" title=
\"View ticket\">Driveline model takes a long time to generate
code</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">perost</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1740\" title=
\"View ticket\" class=\"closed\">#1740</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1740\" title=
\"View ticket\">typo in XMLDump.mo</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">janssen</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1743\" title=
\"View ticket\" class=\"closed\">#1743</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1743\" title=
\"View ticket\">XMLDump incorrectly wraps matrix, vector, and array
elements in an apply block</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">janssen</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio4\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1773\" title=
\"View ticket\" class=\"closed\">#1773</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1773\" title=
\"View ticket\">Array&lt;Integer&gt; arr := {1,2,3} causes a segfault
when arr is passed to a function</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">normal</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1775\" title=
\"View ticket\" class=\"closed\">#1775</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1775\" title=
\"View ticket\">Concatenating a string with an unbound string
variable segfaults</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1780\" title=
\"View ticket\" class=\"closed\">#1780</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1780\" title=
\"View ticket\">Linearization returns zero for systems with
independent variables</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1781\" title=
\"View ticket\" class=\"closed\">#1781</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1781\" title=
\"View ticket\">Modelica.Mechanics.Rotational.Examples.LossyGearDemo2</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1785\" title=
\"View ticket\" class=\"closed\">#1785</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1785\" title=
\"View ticket\">Integration has trouble with
Modelica.Mechanics.Translational.Examples.PreLoad.mos</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1787\" title=
\"View ticket\" class=\"closed\">#1787</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1787\" title=
\"View ticket\">Backend adds = 0.0 bindings for no good
reason</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1794\" title=
\"View ticket\" class=\"closed\">#1794</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1794\" title=
\"View ticket\">Internal error BackendEquation.equationToExp failed
with 1.9 beta, 1.8.1 works.</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">jfrenkel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1802\" title=
\"View ticket\" class=\"closed\">#1802</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1802\" title=
\"View ticket\">Nonliniear Solver converge to wrong solution</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1826\" title=
\"View ticket\" class=\"closed\">#1826</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1826\" title=
\"View ticket\">Passing built in functions as funargs generates
invalid C code</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1827\" title=
\"View ticket\" class=\"closed\">#1827</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1827\" title=
\"View ticket\">BackendDAE cannot represent NORETCALL
equations</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1828\" title=
\"View ticket\" class=\"closed\">#1828</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1828\" title=
\"View ticket\">Generated code for RobotR3.oneAxis contains division
by zero.</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">jfrenkel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1830\" title=
\"View ticket\" class=\"closed\">#1830</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1830\" title=
\"View ticket\">when in algorithm only triggered once</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1846\" title=
\"View ticket\" class=\"closed\">#1846</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1846\" title=
\"View ticket\">Ceval doesn't compile: unbound variable info</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio1\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1866\" title=
\"View ticket\" class=\"closed\">#1866</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1866\" title=
\"View ticket\">zero-crossings need to check for logical operator
instead just for relation</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">blocker</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio4\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1868\" title=
\"View ticket\" class=\"closed\">#1868</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1868\" title=
\"View ticket\">A couple of syntax errors in
Compiler/Template/CodegenXML.tpl</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">janssen</td>
<td class=\"type\">defect</td>
<td class=\"priority\">normal</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1872\" title=
\"View ticket\" class=\"closed\">#1872</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1872\" title=
\"View ticket\">Array-expression and when-statements do not
work</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1873\" title=
\"View ticket\" class=\"closed\">#1873</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1873\" title=
\"View ticket\">Stack overflow introduced in backend</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">jfrenkel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1876\" title=
\"View ticket\" class=\"closed\">#1876</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1876\" title=
\"View ticket\">Expandable connectors: wrong equations generation in
Multibody</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1891\" title=
\"View ticket\" class=\"closed\">#1891</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1891\" title=
\"View ticket\">Fail to match discrete equation</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">jfrenkel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1895\" title=
\"View ticket\" class=\"closed\">#1895</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1895\" title=
\"View ticket\">Error building simulator</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">jfrenkel</td>
<td class=\"type\">enhancement</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1898\" title=
\"View ticket\" class=\"closed\">#1898</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1898\" title=
\"View ticket\">make tests working again from r13489</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">jfrenkel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1903\" title=
\"View ticket\" class=\"closed\">#1903</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1903\" title=
\"View ticket\">Modelica.Blocks.Examples.BooleanNetwork1</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">jfrenkel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1926\" title=
\"View ticket\" class=\"closed\">#1926</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1926\" title=
\"View ticket\">hybrid initialization</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">lochel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1943\" title=
\"View ticket\" class=\"closed\">#1943</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1943\" title=
\"View ticket\">Wrong equation count for enum in when
equations</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">jfrenkel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio4\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1948\" title=
\"View ticket\" class=\"closed\">#1948</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1948\" title=
\"View ticket\">MultiBody model goes infinite in the
back-end</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">jfrenkel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">normal</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1955\" title=
\"View ticket\" class=\"closed\">#1955</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1955\" title=
\"View ticket\">Parameter values lost</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1957\" title=
\"View ticket\" class=\"closed\">#1957</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1957\" title=
\"View ticket\">Modelica.Mechanics.MultiBody.Examples.Elementary.Surfaces</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1959\" title=
\"View ticket\" class=\"closed\">#1959</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1959\" title=
\"View ticket\">Modelica.Blocks.Routing.Extractor doesn't
work</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1960\" title=
\"View ticket\" class=\"closed\">#1960</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1960\" title=
\"View ticket\">Modelica.blocks.sources.pulse wrong simulation
results</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1964\" title=
\"View ticket\" class=\"closed\">#1964</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1964\" title=
\"View ticket\">Bound Parameter Expression unfixed</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">jfrenkel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1965\" title=
\"View ticket\" class=\"closed\">#1965</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1965\" title=
\"View ticket\">TriggeredSampler model doesn't switch
properly</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1970\" title=
\"View ticket\" class=\"closed\">#1970</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1970\" title=
\"View ticket\">Multibody Visualizers type error</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">probably noone</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1971\" title=
\"View ticket\" class=\"closed\">#1971</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1971\" title=
\"View ticket\">Errors in return values in functions with two
outputs</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">probably noone</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1973\" title=
\"View ticket\" class=\"closed\">#1973</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1973\" title=
\"View ticket\">Problem with initial equations affecting valve models
in Modelica.Fluid</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">lochel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1975\" title=
\"View ticket\" class=\"closed\">#1975</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1975\" title=
\"View ticket\">Error in solving nonlinear system for
Mechanics.rotational clutch model</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1992\" title=
\"View ticket\" class=\"closed\">#1992</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1992\" title=
\"View ticket\">Problem with plt</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1996\" title=
\"View ticket\" class=\"closed\">#1996</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1996\" title=
\"View ticket\">wrong over determined initial system II</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">lochel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/2008\" title=
\"View ticket\" class=\"closed\">#2008</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/2008\" title=
\"View ticket\">delay in initial equation</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">lochel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/2011\" title=
\"View ticket\" class=\"closed\">#2011</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/2011\" title=
\"View ticket\">sample breaks c-code</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">lochel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
</tbody>
<tbody>
<tr class=\"trac-group\">
<th colspan=\"7\">
<h2 class=\"report-result\">Component: Build Environment <span class=
\"numrows\">(6 matches)</span></h2>
</th>
</tr>
<tr class=\"trac-columns\">
<th class=\"id asc\"><a title=\"Sort by Ticket (descending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;desc=1&amp;order=id\">
Ticket</a></th>
<th class=\"summary\"><a title=\"Sort by Summary (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=summary\">
Summary</a></th>
<th class=\"resolution\"><a title=\"Sort by Resolution (ascending)\"
href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=resolution\">
Resolution</a></th>
<th class=\"owner\"><a title=\"Sort by Owner (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=owner\">
Owner</a></th>
<th class=\"type\"><a title=\"Sort by Type (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=type\">
Type</a></th>
<th class=\"priority\"><a title=\"Sort by Priority (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=priority\">
Priority</a></th>
<th class=\"version\"><a title=\"Sort by Version (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=version\">
Version</a></th>
</tr>
</tbody>
<tbody>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1742\" title=
\"View ticket\" class=\"closed\">#1742</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1742\" title=
\"View ticket\">11890 won't compile to the end</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">amadeus</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1771\" title=
\"View ticket\" class=\"closed\">#1771</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1771\" title=
\"View ticket\">libintl.h missing when compiling on OS X</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1793\" title=
\"View ticket\" class=\"closed\">#1793</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1793\" title=
\"View ticket\">Update omc 3.2 library to MSL 3.2.1 (dev
version)</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">task</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1800\" title=
\"View ticket\" class=\"closed\">#1800</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1800\" title=
\"View ticket\">Integrate Modelica3D into OpenModelica</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">task</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1984\" title=
\"View ticket\" class=\"closed\">#1984</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1984\" title=
\"View ticket\">Improperly tests simulations</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">cschubert</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/2003\" title=
\"View ticket\" class=\"closed\">#2003</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/2003\" title=
\"View ticket\">OpenCL headers should be moved to OMDEV</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">mahge930</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
</tbody>
<tbody>
<tr class=\"trac-group\">
<th colspan=\"7\">
<h2 class=\"report-result\">Component: Code Generation <span class=
\"numrows\">(15 matches)</span></h2>
</th>
</tr>
<tr class=\"trac-columns\">
<th class=\"id asc\"><a title=\"Sort by Ticket (descending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;desc=1&amp;order=id\">
Ticket</a></th>
<th class=\"summary\"><a title=\"Sort by Summary (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=summary\">
Summary</a></th>
<th class=\"resolution\"><a title=\"Sort by Resolution (ascending)\"
href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=resolution\">
Resolution</a></th>
<th class=\"owner\"><a title=\"Sort by Owner (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=owner\">
Owner</a></th>
<th class=\"type\"><a title=\"Sort by Type (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=type\">
Type</a></th>
<th class=\"priority\"><a title=\"Sort by Priority (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=priority\">
Priority</a></th>
<th class=\"version\"><a title=\"Sort by Version (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=version\">
Version</a></th>
</tr>
</tbody>
<tbody>
<tr class=\"even prio1\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1720\" title=
\"View ticket\" class=\"closed\">#1720</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1720\" title=
\"View ticket\">error FMU</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">mohamed</td>
<td class=\"type\">defect</td>
<td class=\"priority\">blocker</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1746\" title=
\"View ticket\" class=\"closed\">#1746</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1746\" title=
\"View ticket\">Inconsistent array access using indices</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">mburisch</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1769\" title=
\"View ticket\" class=\"closed\">#1769</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1769\" title=
\"View ticket\">.so file of FMI for model exchange problem</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1799\" title=
\"View ticket\" class=\"closed\">#1799</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1799\" title=
\"View ticket\">Fix codegen for tuple equations</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1812\" title=
\"View ticket\" class=\"closed\">#1812</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1812\" title=
\"View ticket\">Code generation error with simple Fluid
model</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1848\" title=
\"View ticket\" class=\"closed\">#1848</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1848\" title=
\"View ticket\">Tuple assignments containing records in which a
component has been aliased are not generated correctly in
CodegenC.tpl</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio1\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1854\" title=
\"View ticket\" class=\"closed\">#1854</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1854\" title=
\"View ticket\">Returning array as an output from function</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">blocker</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1855\" title=
\"View ticket\" class=\"closed\">#1855</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1855\" title=
\"View ticket\">assert failure in combination with encapsulated
packages</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1870\" title=
\"View ticket\" class=\"closed\">#1870</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1870\" title=
\"View ticket\">Using fail() outside a match/matchcontinue causes a
crash</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1877\" title=
\"View ticket\" class=\"closed\">#1877</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1877\" title=
\"View ticket\">Support size(cr)</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1878\" title=
\"View ticket\" class=\"closed\">#1878</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1878\" title=
\"View ticket\">function copy_double_data_mem is missing in cpp
runtine</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">Niklas Worschech</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1885\" title=
\"View ticket\" class=\"closed\">#1885</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1885\" title=
\"View ticket\">generated FMI can not be simulated with
FMUSDK</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">1.9.0Beta</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1922\" title=
\"View ticket\" class=\"closed\">#1922</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1922\" title=
\"View ticket\">Codegeneration does not handle extended
records</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1979\" title=
\"View ticket\" class=\"closed\">#1979</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1979\" title=
\"View ticket\">wrong results in integer matrix equation</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio4\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/2020\" title=
\"View ticket\" class=\"closed\">#2020</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/2020\" title=
\"View ticket\">XML expressions not properly closed in
template</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">normal</td>
<td class=\"version\">trunk</td>
</tr>
</tbody>
<tbody>
<tr class=\"trac-group\">
<th colspan=\"7\">
<h2 class=\"report-result\">Component: Command Prompt Environment
<span class=\"numrows\">(3 matches)</span></h2>
</th>
</tr>
<tr class=\"trac-columns\">
<th class=\"id asc\"><a title=\"Sort by Ticket (descending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;desc=1&amp;order=id\">
Ticket</a></th>
<th class=\"summary\"><a title=\"Sort by Summary (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=summary\">
Summary</a></th>
<th class=\"resolution\"><a title=\"Sort by Resolution (ascending)\"
href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=resolution\">
Resolution</a></th>
<th class=\"owner\"><a title=\"Sort by Owner (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=owner\">
Owner</a></th>
<th class=\"type\"><a title=\"Sort by Type (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=type\">
Type</a></th>
<th class=\"priority\"><a title=\"Sort by Priority (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=priority\">
Priority</a></th>
<th class=\"version\"><a title=\"Sort by Version (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=version\">
Version</a></th>
</tr>
</tbody>
<tbody>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1695\" title=
\"View ticket\" class=\"closed\">#1695</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1695\" title=
\"View ticket\">SCodeFlatten causes scripting API to stop
working</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1744\" title=
\"View ticket\" class=\"closed\">#1744</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1744\" title=
\"View ticket\">Add OMDEV info to checkSettings()</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio5\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1753\" title=
\"View ticket\" class=\"closed\">#1753</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1753\" title=
\"View ticket\">typo in OMShell \"does not exits\" --&gt; \"does not
exist\"</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">Pittiplatsch</td>
<td class=\"type\">defect</td>
<td class=\"priority\">low</td>
<td class=\"version\"></td>
</tr>
</tbody>
<tbody>
<tr class=\"trac-group\">
<th colspan=\"7\">
<h2 class=\"report-result\">Component: FMI <span class=\"numrows\">(1
match)</span></h2>
</th>
</tr>
<tr class=\"trac-columns\">
<th class=\"id asc\"><a title=\"Sort by Ticket (descending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;desc=1&amp;order=id\">
Ticket</a></th>
<th class=\"summary\"><a title=\"Sort by Summary (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=summary\">
Summary</a></th>
<th class=\"resolution\"><a title=\"Sort by Resolution (ascending)\"
href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=resolution\">
Resolution</a></th>
<th class=\"owner\"><a title=\"Sort by Owner (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=owner\">
Owner</a></th>
<th class=\"type\"><a title=\"Sort by Type (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=type\">
Type</a></th>
<th class=\"priority\"><a title=\"Sort by Priority (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=priority\">
Priority</a></th>
<th class=\"version\"><a title=\"Sort by Version (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=version\">
Version</a></th>
</tr>
</tbody>
<tbody>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1933\" title=
\"View ticket\" class=\"closed\">#1933</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1933\" title=
\"View ticket\">FMUChecker crashes with exported FMUs</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adeas31</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
</tbody>
<tbody>
<tr class=\"trac-group\">
<th colspan=\"7\">
<h2 class=\"report-result\">Component: Frontend <span class=
\"numrows\">(57 matches)</span></h2>
</th>
</tr>
<tr class=\"trac-columns\">
<th class=\"id asc\"><a title=\"Sort by Ticket (descending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;desc=1&amp;order=id\">
Ticket</a></th>
<th class=\"summary\"><a title=\"Sort by Summary (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=summary\">
Summary</a></th>
<th class=\"resolution\"><a title=\"Sort by Resolution (ascending)\"
href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=resolution\">
Resolution</a></th>
<th class=\"owner\"><a title=\"Sort by Owner (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=owner\">
Owner</a></th>
<th class=\"type\"><a title=\"Sort by Type (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=type\">
Type</a></th>
<th class=\"priority\"><a title=\"Sort by Priority (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=priority\">
Priority</a></th>
<th class=\"version\"><a title=\"Sort by Version (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=version\">
Version</a></th>
</tr>
</tbody>
<tbody>
<tr class=\"even prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/130\" title=
\"View ticket\" class=\"closed\">#130</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/130\" title=
\"View ticket\">Modifiers are not propagated correctly inside
redeclared model</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">casella</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/139\" title=
\"View ticket\" class=\"closed\">#139</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/139\" title=
\"View ticket\">Input-input and output-output connection does not
return any error and equation are not reported.</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">donida</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio5\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1336\" title=
\"View ticket\" class=\"closed\">#1336</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1336\" title=
\"View ticket\">Implement a preprocessing phase from SCode to SCode
that simplifies instantiation</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">task</td>
<td class=\"priority\">low</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio1\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1707\" title=
\"View ticket\" class=\"closed\">#1707</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1707\" title=
\"View ticket\">type mismatch</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">blocker</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1723\" title=
\"View ticket\" class=\"closed\">#1723</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1723\" title=
\"View ticket\">Check uses-annotations before inst</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1731\" title=
\"View ticket\" class=\"closed\">#1731</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1731\" title=
\"View ticket\">Connecting ranges generates wrong equations</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1733\" title=
\"View ticket\" class=\"closed\">#1733</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1733\" title=
\"View ticket\">range in connect equation fails</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">Frenkel TUD</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1734\" title=
\"View ticket\" class=\"closed\">#1734</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1734\" title=
\"View ticket\">Compiler generates bad flattened version of function
from MSL</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">janssen</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1738\" title=
\"View ticket\" class=\"closed\">#1738</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1738\" title=
\"View ticket\">reinit on parameter gives no error and check Model
returns nothing</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">petar</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1749\" title=
\"View ticket\" class=\"closed\">#1749</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1749\" title=
\"View ticket\">Improve tuple assignment error messages</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">petar</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1750\" title=
\"View ticket\" class=\"closed\">#1750</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1750\" title=
\"View ticket\">inheritance in protected section not propagated to
components</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">petar</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1766\" title=
\"View ticket\" class=\"closed\">#1766</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1766\" title=
\"View ticket\">Locale changes cause real to string conversion to
fail</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio4\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1767\" title=
\"View ticket\" class=\"closed\">#1767</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1767\" title=
\"View ticket\">Translations of the omc kernel</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">task</td>
<td class=\"priority\">normal</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1772\" title=
\"View ticket\" class=\"closed\">#1772</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1772\" title=
\"View ticket\">Functions that return MetaModelica arrays produce
errors</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1774\" title=
\"View ticket\" class=\"closed\">#1774</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1774\" title=
\"View ticket\">Instantiation fails for
Modelica.StateGraph.Examples.ControlledTanks</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">perost</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1776\" title=
\"View ticket\" class=\"closed\">#1776</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1776\" title=
\"View ticket\">Add detection of usage of unbound variables</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1777\" title=
\"View ticket\" class=\"closed\">#1777</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1777\" title=
\"View ticket\">function handlin failed for
Modelica.Media.Examples.Tests.MediaTestModels.LinearFluid.LinearWater_pT</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio4\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1786\" title=
\"View ticket\" class=\"closed\">#1786</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1786\" title=
\"View ticket\">Empty list pattern incorrectly used causes an endless
loop</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">normal</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio1\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1796\" title=
\"View ticket\" class=\"closed\">#1796</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1796\" title=
\"View ticket\">Subscripts of last type of cref with stripped subs
are reversed</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">perost</td>
<td class=\"type\">defect</td>
<td class=\"priority\">blocker</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1801\" title=
\"View ticket\" class=\"closed\">#1801</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1801\" title=
\"View ticket\">Fixed simplification of matrix-vector
multiplication</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1811\" title=
\"View ticket\" class=\"closed\">#1811</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1811\" title=
\"View ticket\">Wrong equation count in Fluid source model with zero
ports</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1819\" title=
\"View ticket\" class=\"closed\">#1819</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1819\" title=
\"View ticket\">RealInput Failure</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">perost</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1821\" title=
\"View ticket\" class=\"closed\">#1821</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1821\" title=
\"View ticket\">Complex constructor does not work</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">mahge930</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1823\" title=
\"View ticket\" class=\"closed\">#1823</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1823\" title=
\"View ticket\">Error when using constant in connector</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1825\" title=
\"View ticket\" class=\"closed\">#1825</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1825\" title=
\"View ticket\">Error filling array with A:B:C notation</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">perost</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1829\" title=
\"View ticket\" class=\"closed\">#1829</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1829\" title=
\"View ticket\">Cannot find aliased package functions</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">discussion</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1833\" title=
\"View ticket\" class=\"closed\">#1833</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1833\" title=
\"View ticket\">Local name shadowing and assignment to
inputs</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">openmodelicadevelopers@…</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1844\" title=
\"View ticket\" class=\"closed\">#1844</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1844\" title=
\"View ticket\">Incorrect Type Unboxing (?) when calling funargs in
if expressions</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1847\" title=
\"View ticket\" class=\"closed\">#1847</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1847\" title=
\"View ticket\">Duplicates in the package.order file are reported in
the wrong place</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1851\" title=
\"View ticket\" class=\"closed\">#1851</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1851\" title=
\"View ticket\">Warn on unassigned output variables (Using unbound
output variables causes segfault)</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">enhancement</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1875\" title=
\"View ticket\" class=\"closed\">#1875</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1875\" title=
\"View ticket\">Error printed although record instantiation
succeeds</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1882\" title=
\"View ticket\" class=\"closed\">#1882</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1882\" title=
\"View ticket\">Inside flow appear twice in the connection set in
some weird cases</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1892\" title=
\"View ticket\" class=\"closed\">#1892</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1892\" title=
\"View ticket\">Error extending model</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1896\" title=
\"View ticket\" class=\"closed\">#1896</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1896\" title=
\"View ticket\">Error occurred while flattening model
Modelica.Mechanics.MultiBody.Examples.Elementary.PointGravityWithPointMasses2</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1907\" title=
\"View ticket\" class=\"closed\">#1907</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1907\" title=
\"View ticket\">Handle empty arrays on the lhs of algorithm</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio1\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1917\" title=
\"View ticket\" class=\"closed\">#1917</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1917\" title=
\"View ticket\">Instantiaten lost Parameter Binding</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">blocker</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1920\" title=
\"View ticket\" class=\"closed\">#1920</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1920\" title=
\"View ticket\">Add casts inside matrix constructor</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1923\" title=
\"View ticket\" class=\"closed\">#1923</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1923\" title=
\"View ticket\">Connection Graph is not broken correctly</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1944\" title=
\"View ticket\" class=\"closed\">#1944</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1944\" title=
\"View ticket\">unbalanced models: empty array of unused connector
yields equations</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">perost</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1945\" title=
\"View ticket\" class=\"closed\">#1945</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1945\" title=
\"View ticket\">unbalanced models by duplicate inheritance</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">perost</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1946\" title=
\"View ticket\" class=\"closed\">#1946</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1946\" title=
\"View ticket\">Finding the dimension of the component with unknown
dimension from the parameter binding fails</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1947\" title=
\"View ticket\" class=\"closed\">#1947</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1947\" title=
\"View ticket\">unbalanced model - Wrong root in connection
graph</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1950\" title=
\"View ticket\" class=\"closed\">#1950</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1950\" title=
\"View ticket\">symmetric: failed to elaborate expression</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1951\" title=
\"View ticket\" class=\"closed\">#1951</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1951\" title=
\"View ticket\">Array reduction with function returning a tuple does
not work</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1952\" title=
\"View ticket\" class=\"closed\">#1952</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1952\" title=
\"View ticket\">SCodeDependency removes necessary classes in some
cases</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1953\" title=
\"View ticket\" class=\"closed\">#1953</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1953\" title=
\"View ticket\">Function calls returning tuples are not handled in
binary/unary expressions</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1954\" title=
\"View ticket\" class=\"closed\">#1954</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1954\" title=
\"View ticket\">Vectorization of inStream and actualStream does not
work</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio1\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1961\" title=
\"View ticket\" class=\"closed\">#1961</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1961\" title=
\"View ticket\">Modelica.Electrical.Digital.Sources.Table</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">blocker</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio1\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1969\" title=
\"View ticket\" class=\"closed\">#1969</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1969\" title=
\"View ticket\">function with multiple return value used only first
one does not work</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">blocker</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1972\" title=
\"View ticket\" class=\"closed\">#1972</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1972\" title=
\"View ticket\">Reinit in when equations with condition initial()
should report an error</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio4\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1983\" title=
\"View ticket\" class=\"closed\">#1983</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1983\" title=
\"View ticket\">Parameter has neither value nor start value, and is
fixed</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">normal</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1987\" title=
\"View ticket\" class=\"closed\">#1987</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1987\" title=
\"View ticket\">Unbalanced model</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1988\" title=
\"View ticket\" class=\"closed\">#1988</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1988\" title=
\"View ticket\">Inner class definition is removed by dependency
analysis</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio4\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1993\" title=
\"View ticket\" class=\"closed\">#1993</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1993\" title=
\"View ticket\">CevalScript.getConst: Not handled exp: -4</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">enhancement</td>
<td class=\"priority\">normal</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/2024\" title=
\"View ticket\" class=\"closed\">#2024</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/2024\" title=
\"View ticket\">Problem with connects and array components</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">perost</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/2032\" title=
\"View ticket\" class=\"closed\">#2032</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/2032\" title=
\"View ticket\">Implement loadResource</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/2035\" title=
\"View ticket\" class=\"closed\">#2035</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/2035\" title=
\"View ticket\">Error with replaceable models</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
</tbody>
<tbody>
<tr class=\"trac-group\">
<th colspan=\"7\">
<h2 class=\"report-result\">Component: Interactive Environment
<span class=\"numrows\">(2 matches)</span></h2>
</th>
</tr>
<tr class=\"trac-columns\">
<th class=\"id asc\"><a title=\"Sort by Ticket (descending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;desc=1&amp;order=id\">
Ticket</a></th>
<th class=\"summary\"><a title=\"Sort by Summary (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=summary\">
Summary</a></th>
<th class=\"resolution\"><a title=\"Sort by Resolution (ascending)\"
href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=resolution\">
Resolution</a></th>
<th class=\"owner\"><a title=\"Sort by Owner (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=owner\">
Owner</a></th>
<th class=\"type\"><a title=\"Sort by Type (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=type\">
Type</a></th>
<th class=\"priority\"><a title=\"Sort by Priority (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=priority\">
Priority</a></th>
<th class=\"version\"><a title=\"Sort by Version (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=version\">
Version</a></th>
</tr>
</tbody>
<tbody>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1421\" title=
\"View ticket\" class=\"closed\">#1421</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1421\" title=
\"View ticket\">AddClassAnnotation adds the duplicate annotations to
the model.</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1864\" title=
\"View ticket\" class=\"closed\">#1864</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1864\" title=
\"View ticket\">Load libraries in the user's home directory by
default</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">task</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
</tbody>
<tbody>
<tr class=\"trac-group\">
<th colspan=\"7\">
<h2 class=\"report-result\">Component: New Instantiation <span class=
\"numrows\">(1 match)</span></h2>
</th>
</tr>
<tr class=\"trac-columns\">
<th class=\"id asc\"><a title=\"Sort by Ticket (descending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;desc=1&amp;order=id\">
Ticket</a></th>
<th class=\"summary\"><a title=\"Sort by Summary (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=summary\">
Summary</a></th>
<th class=\"resolution\"><a title=\"Sort by Resolution (ascending)\"
href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=resolution\">
Resolution</a></th>
<th class=\"owner\"><a title=\"Sort by Owner (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=owner\">
Owner</a></th>
<th class=\"type\"><a title=\"Sort by Type (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=type\">
Type</a></th>
<th class=\"priority\"><a title=\"Sort by Priority (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=priority\">
Priority</a></th>
<th class=\"version\"><a title=\"Sort by Version (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=version\">
Version</a></th>
</tr>
</tbody>
<tbody>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1956\" title=
\"View ticket\" class=\"closed\">#1956</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1956\" title=
\"View ticket\">Merge modifiers from the original component when
redeclaring components.</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adrpo</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
</tbody>
<tbody>
<tr class=\"trac-group\">
<th colspan=\"7\">
<h2 class=\"report-result\">Component: OMEdit <span class=
\"numrows\">(9 matches)</span></h2>
</th>
</tr>
<tr class=\"trac-columns\">
<th class=\"id asc\"><a title=\"Sort by Ticket (descending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;desc=1&amp;order=id\">
Ticket</a></th>
<th class=\"summary\"><a title=\"Sort by Summary (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=summary\">
Summary</a></th>
<th class=\"resolution\"><a title=\"Sort by Resolution (ascending)\"
href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=resolution\">
Resolution</a></th>
<th class=\"owner\"><a title=\"Sort by Owner (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=owner\">
Owner</a></th>
<th class=\"type\"><a title=\"Sort by Type (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=type\">
Type</a></th>
<th class=\"priority\"><a title=\"Sort by Priority (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=priority\">
Priority</a></th>
<th class=\"version\"><a title=\"Sort by Version (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=version\">
Version</a></th>
</tr>
</tbody>
<tbody>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1719\" title=
\"View ticket\" class=\"closed\">#1719</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1719\" title=
\"View ticket\">OMEdit does not display quoted classes</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio1\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1809\" title=
\"View ticket\" class=\"closed\">#1809</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1809\" title=
\"View ticket\">Allow JavaScript in OMEdit html viewer</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">task</td>
<td class=\"priority\">blocker</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1820\" title=
\"View ticket\" class=\"closed\">#1820</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1820\" title=
\"View ticket\">Add GUI boxes for dynamic state selection and index
reduction</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adeas31</td>
<td class=\"type\">task</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1836\" title=
\"View ticket\" class=\"closed\">#1836</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1836\" title=
\"View ticket\">OMEdit: navigation buttons in documentation
viewer</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">hkiel</td>
<td class=\"type\">enhancement</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio4\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1837\" title=
\"View ticket\" class=\"closed\">#1837</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1837\" title=
\"View ticket\">OMEdit: default action for double click</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">hkiel</td>
<td class=\"type\">enhancement</td>
<td class=\"priority\">normal</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1845\" title=
\"View ticket\" class=\"closed\">#1845</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1845\" title=
\"View ticket\">Simulation messages not shown in OMEdit</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adeas31</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1880\" title=
\"View ticket\" class=\"closed\">#1880</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1880\" title=
\"View ticket\">OMEdit: uses all CPU during simulation</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">hkiel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1897\" title=
\"View ticket\" class=\"closed\">#1897</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1897\" title=
\"View ticket\">OMEdit crashes (segfault) when opening
Modelica.Mechanics.Translational.Examples.SignConvention</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">hkiel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1906\" title=
\"View ticket\" class=\"closed\">#1906</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1906\" title=
\"View ticket\">Add GUI option to select compiler</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">enhancement</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
</tbody>
<tbody>
<tr class=\"trac-group\">
<th colspan=\"7\">
<h2 class=\"report-result\">Component: Parser <span class=
\"numrows\">(3 matches)</span></h2>
</th>
</tr>
<tr class=\"trac-columns\">
<th class=\"id asc\"><a title=\"Sort by Ticket (descending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;desc=1&amp;order=id\">
Ticket</a></th>
<th class=\"summary\"><a title=\"Sort by Summary (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=summary\">
Summary</a></th>
<th class=\"resolution\"><a title=\"Sort by Resolution (ascending)\"
href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=resolution\">
Resolution</a></th>
<th class=\"owner\"><a title=\"Sort by Owner (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=owner\">
Owner</a></th>
<th class=\"type\"><a title=\"Sort by Type (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=type\">
Type</a></th>
<th class=\"priority\"><a title=\"Sort by Priority (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=priority\">
Priority</a></th>
<th class=\"version\"><a title=\"Sort by Version (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=version\">
Version</a></th>
</tr>
</tbody>
<tbody>
<tr class=\"even prio4\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1757\" title=
\"View ticket\" class=\"closed\">#1757</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1757\" title=
\"View ticket\">loadFile of package.mo with encoding=\"Windows-1252\"
only applies to package.mo file.</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">normal</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1764\" title=
\"View ticket\" class=\"closed\">#1764</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1764\" title=
\"View ticket\">getClassNames and list should care of
package.order</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adeas31</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio2\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1808\" title=
\"View ticket\" class=\"closed\">#1808</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1808\" title=
\"View ticket\">Reject multiple elements in class</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">critical</td>
<td class=\"version\">trunk</td>
</tr>
</tbody>
<tbody>
<tr class=\"trac-group\">
<th colspan=\"7\">
<h2 class=\"report-result\">Component: Run-time <span class=
\"numrows\">(12 matches)</span></h2>
</th>
</tr>
<tr class=\"trac-columns\">
<th class=\"id asc\"><a title=\"Sort by Ticket (descending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;desc=1&amp;order=id\">
Ticket</a></th>
<th class=\"summary\"><a title=\"Sort by Summary (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=summary\">
Summary</a></th>
<th class=\"resolution\"><a title=\"Sort by Resolution (ascending)\"
href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=resolution\">
Resolution</a></th>
<th class=\"owner\"><a title=\"Sort by Owner (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=owner\">
Owner</a></th>
<th class=\"type\"><a title=\"Sort by Type (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=type\">
Type</a></th>
<th class=\"priority\"><a title=\"Sort by Priority (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=priority\">
Priority</a></th>
<th class=\"version\"><a title=\"Sort by Version (ascending)\" href=
\"https://trac.openmodelica.org/OpenModelica/query?status=closed&amp;resolution=fixed&amp;resolution=-&amp;severity=!trivial&amp;milestone=1.9.0&amp;group=component&amp;max=0&amp;order=version\">
Version</a></th>
</tr>
</tbody>
<tbody>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1751\" title=
\"View ticket\" class=\"closed\">#1751</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1751\" title=
\"View ticket\">Wrong code generation for
getEnvironmentVariable</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">mburisch</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1778\" title=
\"View ticket\" class=\"closed\">#1778</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1778\" title=
\"View ticket\">Make TwoMass.mos work again</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1789\" title=
\"View ticket\" class=\"closed\">#1789</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1789\" title=
\"View ticket\">CombiTable2D does not work with simple double(8,6)
table</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1798\" title=
\"View ticket\" class=\"closed\">#1798</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1798\" title=
\"View ticket\">Support for ModelicaError in
ModelicaUtilities.h</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">task</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1843\" title=
\"View ticket\" class=\"closed\">#1843</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1843\" title=
\"View ticket\">MSL 3.2
Modelica.Mechanics.Rotational.Examples.LossyGearDemo*
issues</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1860\" title=
\"View ticket\" class=\"closed\">#1860</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1860\" title=
\"View ticket\">Multibody MSL models that use quaternions as states
fail simulation</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">1.9.0Beta</td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1871\" title=
\"View ticket\" class=\"closed\">#1871</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1871\" title=
\"View ticket\">The FMI implementation contains int&lt;-&gt;pointer
casts</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">adeas31</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio4\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1881\" title=
\"View ticket\" class=\"closed\">#1881</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1881\" title=
\"View ticket\">Glycol47 segfaults in LAPACK routine</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">normal</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1902\" title=
\"View ticket\" class=\"closed\">#1902</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1902\" title=
\"View ticket\">problems with event handling on 32-bit with
gcc-4.6</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">somebody</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">1.9.0Beta</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1921\" title=
\"View ticket\" class=\"closed\">#1921</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1921\" title=
\"View ticket\">Oscillator executable fails without message</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">wbraun</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\"></td>
</tr>
<tr class=\"even prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1981\" title=
\"View ticket\" class=\"closed\">#1981</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/1981\" title=
\"View ticket\">wrong handling of events for the first
evaluation</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">lochel</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
<tr class=\"odd prio3\">
<td class=\"id\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/2026\" title=
\"View ticket\" class=\"closed\">#2026</a></td>
<td class=\"summary\"><a href=
\"https://trac.openmodelica.org/OpenModelica/ticket/2026\" title=
\"View ticket\">generated mat-file is invalid</a></td>
<td class=\"resolution\">fixed</td>
<td class=\"owner\">sjoelund.se</td>
<td class=\"type\">defect</td>
<td class=\"priority\">high</td>
<td class=\"version\">trunk</td>
</tr>
</tbody>
</table>
</div>
</div>
</div>
</div>
</div>
</body>
</html>"));
end '1.9.0';
package trunk "Development version"
annotation(Documentation(info="<html>
</html>"));
end trunk;
annotation(Documentation(info="<html>
This section summarizes the major releases of OpenModelica and what changed between the major versions.
However, OpenModelica is developed rapidly and updated on a continuous basis. There are probably changes
in the <a href=\"modelica://OpenModelica.UsersGuide.ReleaseNotes.trunk\">current version</a>.
</html>"));
end ReleaseNotes;
end UsersGuide;

annotation(
  Documentation(revisions="<html>See <a href=\"modelica://OpenModelica.UsersGuide.ReleaseNotes\">ReleaseNotes</a></html>",
  __Dymola_DocumentationClass = true),
  preferredView="text");
end OpenModelica;
