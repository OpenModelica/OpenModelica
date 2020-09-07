/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

type StateSelect = enumeration(
  never "Do not use as state at all.",
  avoid "Use as state, if it cannot be avoided (but only if variable appears differentiated and no other potential state with attribute default, prefer, or always can be selected).",
  default "Use as state if appropriate, but only if variable appears differentiated.",
  prefer "Prefer it as state over those having the default value (also variables can be selected, which do not appear differentiated).",
  always "Do use it as a state."
);

function der "Derivative of the input expression"
  input Real x(unit="'p");
  output Real dx(unit="'p/s");
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'der()'\">der()</a>
</html>"));
end der;

impure function initial "True if in initialization phase"
  output Boolean isInitial;
external "builtin";
annotation(__OpenModelica_Impure=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'initial()'\">initial()</a>
</html>"));
end initial;

impure function terminal "True after successful analysis"
  output Boolean isTerminal;
external "builtin";
annotation(__OpenModelica_Impure=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'terminal()'\">terminal()</a>
</html>"));
end terminal;

type AssertionLevel = enumeration(error, warning) annotation(__OpenModelica_builtin=true,
  Documentation(info="<html>Used by <a href=\"modelica://assert\">assert()</a></html>"));

function assert "Check an assertion condition"
  input Boolean condition;
  input String message;
  input AssertionLevel level = AssertionLevel.error;
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

function integer "Returns the largest integer not greater than x. The argument shall have type Real. The result has type Integer. [Note, outside of a when-clause state events are triggered when the return value changes discontinuously.]."
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

function sign "Sign of real or integer number"
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

function identity "Identity matrix of given size"
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

function edge "Indicate rising edge"
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
external "builtin";
annotation(version="Modelica 3.2",Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'homotopy()'\">homotopy()</a> (experimental implementation)
</html>"));
end homotopy;

function linspace "Real vector with equally spaced elements"
  input Real x1 "start";
  input Real x2 "end";
  input Integer n "number";
  output Real v[n];
algorithm
  // assert(n >= 2, "linspace requires n>=2 but got " + String(n));
  v := {x1 + (x2-x1)*(i-1)/(n-1) for i in 1:n};
  annotation(__OpenModelica_builtin=true,__OpenModelica_EarlyInline=true,Documentation(info="<html>
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
annotation(__OpenModelica_builtin=true,__OpenModelica_EarlyInline=true,preferredView="text",Documentation(info="<html>
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

function delay = $overload(OpenModelica.Internal.delay2,OpenModelica.Internal.delay3) "Delay expression"
  annotation(__OpenModelica_Impure=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'delay()'\">delay()</a>
</html>"));

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

function sum "Sum of all array elements"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'sum()'\">sum()</a>
</html>"));
end sum;

function product "Product of all array elements"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'product()'\">product()</a>
</html>"));
end product;

function transpose "Transpose a matrix"
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

function diagonal<T> "Returns a diagonal matrix"
  input T v[:];
  output T mat[size(v,1),size(v,1)];
  external "builtin";
  annotation(__OpenModelica_UnboxArguments=true, Documentation(info="<html>
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

function array "Constructs an array"
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

function sample "Overloaded operator to either trigger time events or to convert between continuous-time and clocked-time representation"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'sample()'\">sample()</a>
</html>"));
end sample;

function shiftSample "First activation of clock is shifted in time"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'shiftSample()'\">shiftSample()</a>
</html>"));
end shiftSample;

function backSample "First activation of clock is shifted in time before activation of u"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'backSample()'\">backSample()</a>
</html>"));
end backSample;

function transition "Define state machine transition"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'transition()'\">transition()</a>
</html>"));
end transition;

function initialState "Define inital state of a state machine"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'initialState()'\">initialState()</a>
</html>"));
end initialState;

function activeState "Return true if instance of a state machine is active, otherwise false"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'activeState()'\">activeState()</a>
</html>"));
end activeState;

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

function scalar "Returns a one-element array as scalar"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'scalar()'\">scalar()</a>
</html>"));
end scalar;

function vector "Returns an array as vector"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'vector()'\">vector()</a>
</html>"));
end vector;

function matrix "Returns the first two dimensions of an array as matrix"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'matrix()'\">matrix()</a>
</html>"));
end matrix;

function cat "Concatenate arrays along given dimension"
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'cat()'\">cat()</a>
</html>"));
end cat;

function actualStream
  input Real x;
  output Real y;
  external "builtin";
end actualStream;

function inStream
  input Real x;
  output Real y;
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

  function uniqueRoot
    input VariableName root;
    input String message = "";
    external "builtin";
  end uniqueRoot;

  function uniqueRootIndices
    input VariableName[:] roots;
    input VariableName[:] nodes;
    input String message = "";
    output Integer[size(roots, 1)] rootIndices;
    // adrpo: I would like an assert here: size(nodes) <= size (roots)
    external "builtin";
  end uniqueRootIndices;

  function rooted
    external "builtin";
    annotation(Documentation(info="<html>
  <h4>Syntax</h4>
  <blockquote>
  <pre><b>Connections.rooted</b>(x)</pre>
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
  </html>"));
  end rooted;
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

impure function print "Prints to stdout, useful for debugging."
  input String str;
  external "builtin";
  annotation(__OpenModelica_Impure=true, version="OpenModelica extension");
end print;

function classDirectory "Non-standard operator"
  output String str;
external "builtin";
annotation(Documentation(info="<html>
<p>classDirectory() is a <b>non-standard operator</b> that was replaced by <a href=\"modelica://Modelica.Utilities.Files.loadResource\">Modelica.Utilities.Files.loadResource(uri)</a> before it was added to the language specification.</p>
<p>Returns the directory of the file where the classDirectory() call came from.</p>
</html>"),version="Dymola / MSL 2.2.1");
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
  input Real in1;
  input Real x;
  input Boolean positiveVelocity;
  parameter input Real initialPoints[:](each min = 0, each max = 1) = {0.0, 1.0};
  parameter input Real initialValues[size(initialPoints, 1)] = {0.0, 0.0};
  output Real out0;
  output Real out1;
external "builtin";
annotation(version="Modelica 3.3");
end spatialDistribution;

function previous<T> "Access previous value of a clocked variable"
  input T u;
  output T y;
  external "builtin";
  annotation(__OpenModelica_UnboxArguments=true, version="Modelica 3.3", Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'previous()'\">previous()</a>
</html>"));
end previous;

function subSample = $overload(OpenModelica.Internal.subSampleExpression, OpenModelica.Internal.subSampleClock)
  "Conversion from faster clock to slower clock"
  annotation(version="Modelica 3.3", Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'subSample()'\">subSample()</a>
</html>"));

function superSample = $overload(OpenModelica.Internal.superSampleExpression, OpenModelica.Internal.superSampleClock)
  "Conversion from slower clock to faster clock"
  annotation(version="Modelica 3.3", Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'superSample()'\">superSample()</a>
</html>"));

function hold<T> "Conversion from clocked discrete-time to continuous time"
  input T u;
  output T y;
  external "builtin";
  annotation(__OpenModelica_UnboxArguments=true, version="Modelica 3.3", Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'hold()'\">hold()</a>
</html>"));
end hold;

function noClock<T> "Clock of y=Clock(u) is always inferred"
  input T u;
  output T y;
  external "builtin";
  annotation(__OpenModelica_UnboxArguments=true, version="Modelica 3.3", Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'noClock()'\">noClock()</a>
</html>"));
end noClock;

function interval = $overload(OpenModelica.Internal.intervalInferred, OpenModelica.Internal.intervalExpression)
   "Returns the interval between the previous and present tick of the clock of its argument"
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'interval()'\">interval()</a>
</html>"));

impure function ticksInState "Returns the number of clock ticks since a transition was made to the currently active state"
  output Integer ticks;
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'ticksInState()'\">ticksInState()</a>
</html>"));
end ticksInState;

impure function timeInState "Returns the time duration as Real in [s] since a transition was made to the currently active state"
  output Real t;
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'ticksInState()'\">ticksInState()</a>
</html>"));
end timeInState;

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
type ExpressionOrModification "An expression or modification of some kind" end ExpressionOrModification;
type TypeName "A path, for example the name of a class, e.g. A.B.C or .A.B" end TypeName;
type VariableName "A variable name, e.g. a.b or a[1].b[3].c" end VariableName;
type VariableNames "An array of variable names, e.g. {a.b,a[1].b[3].c}, or a single VariableName" end VariableNames;

end $Code;

function threadData
  output ThreadData threadData;
protected
  record ThreadData
  end ThreadData;
external "builtin";
annotation(Documentation(info="<html>
<p>Used to access thread-specific data in external functions.</p>
</html>"));
end threadData;

package Internal "Contains internal implementations, e.g. overloaded builtin functions"

  type BuiltinType "Integer,Real,String,enumeration or array of some kind"
  end BuiltinType;

  function ClockConstructor = $overload(OpenModelica.Internal.inferredClock, OpenModelica.Internal.rationalClock, OpenModelica.Internal.realClock, OpenModelica.Internal.booleanClock, OpenModelica.Internal.solverClock)
    "Overloaded clock constructor"
    annotation(version="Modelica 3.3", Documentation(info="<html>
    The Clock constructors.</a>
  </html>"));

  function inferredClock
    output Clock c;
    external "builtin";
  end inferredClock;

  function rationalClock
    input Integer intervalCounter(min=0);
    parameter input Integer resolution(unit="Hz", min=1)=1;
    output Clock c;
    external "builtin";
  end rationalClock;

  function realClock
    input Real interval(unit="s", min=0);
    output Clock c;
    external "builtin";
  end realClock;

  function booleanClock
    input Boolean condition;
    input Real startInterval=0.0;
    output Clock c;
    external "builtin";
  end booleanClock;

  function solverClock
    input Clock c;
    parameter input String solverMethod;
    output Clock clk;
    external "builtin";
  end solverClock;

  function intervalInferred
    output Real interval;
    external "builtin" interval=interval();
  end intervalInferred;

  function intervalExpression<T>
    input T u;
    output Real y;
    external "builtin" y=interval(u);
    annotation(__OpenModelica_UnboxArguments=true);
  end intervalExpression;

  impure function subSampleExpression<T>
    input T u;
    parameter input Integer factor(min=0)=0;
    output T y;
    external "builtin" y=subSample(u,factor);
    annotation(__OpenModelica_UnboxArguments=true);
  end subSampleExpression;

  impure function subSampleClock
    input Clock u;
    parameter input Integer factor(min=0)=0;
    output Clock y;
    external "builtin" y=subSample(u,factor);
  end subSampleClock;

  impure function superSampleExpression<T>
    input T u;
    parameter input Integer factor(min=0)=0;
    output T y;
    external "builtin" y=superSample(u,factor);
    annotation(__OpenModelica_UnboxArguments=true);
  end superSampleExpression;

  impure function superSampleClock
    input Clock u;
    parameter input Integer factor(min=0)=0;
    output Clock y;
    external "builtin" y=superSample(u,factor);
  end superSampleClock;

  impure function delay2
    input Real expr;
    parameter input Real delayTime;
    output Real value;
    external "builtin" value=delay(expr, delayTime);
  end delay2;

  impure function delay3
    input Real expr, delayTime;
    parameter input Real delayMax;
    output Real value;
    external "builtin" value=delay(expr, delayTime, delayMax);
  end delay3;

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
    annotation(preferredView="text", __OpenModelica_EarlyInline=true);
  end intRem;

  function realRem
    input Real x;
    input Real y;
    output Real z;
  algorithm
    z := x - (div(x, y) * y);
    annotation(preferredView="text", __OpenModelica_EarlyInline=true);
  end realRem;

  package Architecture
    function numBits
      output Integer numBit;
      external "builtin" numBit = architecture_numbits() annotation(Include="#define architecture_numbits() (8*sizeof(void*))");
    end numBits;
    function integerMax
      output Integer max;
      external "builtin" max = intMaxLit();
    end integerMax;
  end Architecture;

annotation(preferredView="text");
end Internal;

package Scripting

import OpenModelica.$Code.Expression;
import OpenModelica.$Code.ExpressionOrModification;
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
"returns time in format AhBmTs [X.YYYY]"
  input Real sec;
  output String str;
protected
  Integer tmp,min,hr;
algorithm
  /*
  tmp := mod(integer(sec),60);
  min := div(integer(sec),60);
  hr := div(min,60);
  min := mod(min,60);
  str := (if hr>0 then String(hr) + "h" else "") + (if min>0 then String(min) + "m" else "") + String(tmp) + "s";
  str := str + " [" + String(sec, significantDigits=4) + "]";
  */
  str := String(sec, significantDigits=4);
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
  external "C" fileType = ModelicaInternal_stat(name);
  annotation(Library="ModelicaExternalC");
end stat;

end Internal;

function checkSettings "Display some diagnostics."
  output CheckSettingsResult result;
external "builtin";
annotation(preferredView="text");
end checkSettings;

function loadFile "load file (*.mo) and merge it with the loaded AST."
  input String fileName;
  input String encoding = "UTF-8";
  input Boolean uses = true;
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
<p>Loads the given file using the given encoding.</p>
<p>
  Note that if the file basename is package.mo and the parent directory is the top-level class, the library structure is loaded as if loadModel(ClassName) was called.
  Uses-annotations are respected if uses=true.
  The main difference from loadModel is that loadFile appends this directory to the MODELICAPATH (for this call only).
</p>
</html>"), preferredView="text");
end loadFile;

function loadFiles "load files (*.mo) and merges them with the loaded AST."
  input String[:] fileNames;
  input String encoding = "UTF-8";
  input Integer numThreads = OpenModelica.Scripting.numProcessors();
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end loadFiles;

function parseEncryptedPackage
  input String fileName;
  input String workdir = "<default>" "The output directory for imported encrypted files. <default> will put the files to current working directory.";
  output TypeName names[:];
external "builtin";
annotation(Documentation(info="<html>
<p>Parses the given encrypted package and returns the names of the parsed classes.</p>
</html>"), preferredView="text");
end parseEncryptedPackage;

function loadEncryptedPackage
  input String fileName;
  input String workdir = "<default>" "The output directory for imported encrypted files. <default> will put the files to current working directory.";
  input Boolean skipUnzip = false "Skips the unzip of .mol if true. In that case we expect the files are already extracted e.g., because of parseEncryptedPackage() call.";
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
<p>Loads the given encrypted package.</p>
</html>"), preferredView="text");
end loadEncryptedPackage;

function reloadClass "reloads the file associated with the given (loaded class)"
  input TypeName name;
  input String encoding = "UTF-8";
  output Boolean success;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Given an existing, loaded class in the compiler, compare the time stamp of the loaded class with the time stamp (mtime) of the file it was loaded from. If these differ, parse the file and merge it with the AST.</p>
</html>"));
end reloadClass;

function loadString "Parses the data and merges the resulting AST with ithe
  loaded AST.
  If a filename is given, it is used to provide error-messages as if the string
was read in binary format from a file with the same name.
  The file is converted to UTF-8 from the given character set.
  When merge is true the classes cNew in the file will be merged with the already loaded classes cOld in the following way:
   1. get all the inner class definitions from cOld that were loaded from a different file than itself
   2. append all elements from step 1 to class cNew public list

  NOTE: Encoding is deprecated as *ALL* strings are now UTF-8 encoded.
  "
  input String data;
  input String filename = "<interactive>";
  input String encoding = "UTF-8";
  input Boolean merge = false "if merge is true the parsed AST is merged with the existing AST, default to false which means that is replaced, not merged";
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end loadString;

function parseString
  input String data;
  input String filename = "<interactive>";
  output TypeName names[:];
external "builtin";
annotation(preferredView="text");
end parseString;

function parseFile
  input String filename;
  input String encoding = "UTF-8";
  output TypeName names[:];
external "builtin";
annotation(preferredView="text");
end parseFile;

function loadFileInteractiveQualified
  input String filename;
  input String encoding = "UTF-8";
  output TypeName names[:];
external "builtin";
annotation(preferredView="text");
end loadFileInteractiveQualified;

function loadFileInteractive
  input String filename;
  input String encoding = "UTF-8";
  output TypeName names[:];
external "builtin";
annotation(preferredView="text");
end loadFileInteractive;

impure function system "Similar to system(3). Executes the given command in the system shell."
  input String callStr "String to call: sh -c $callStr";
  input String outputFile = "" "The output is redirected to this file (unless already done by callStr)";
  output Integer retval "Return value of the system call; usually 0 on success";
external "builtin" annotation(__OpenModelica_Impure=true);
annotation(preferredView="text");
end system;

impure function system_parallel "Similar to system(3). Executes the given commands in the system shell, in parallel if omc was compiled using OpenMP."
  input String callStr[:] "String to call: sh -c $callStr";
  input Integer numThreads = numProcessors();
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
  input String topic = "topics";
  output String helpText;
external "builtin";
end help;

function clear "Clears everything: symboltable and variables."
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end clear;

function clearProgram "Clears loaded ."
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end clearProgram;

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

function generateJuliaHeader
  input String fileName;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end generateJuliaHeader;

function generateSeparateCode
  input TypeName className;
  input Boolean cleanCache = false "If true, the cache is reset between each generated package. This conserves memory at the cost of speed.";
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html><p>Under construction.</p>
</html>"),preferredView="text");
end generateSeparateCode;

function generateSeparateCodeDependencies
  input String stampSuffix = ".c" "Suffix to add to dependencies (often .c.stamp)";
  output String [:] dependencies;
external "builtin";
annotation(Documentation(info="<html><p>Under construction.</p>
</html>"),preferredView="text");
end generateSeparateCodeDependencies;

function generateSeparateCodeDependenciesMakefile
  input String filename "The file to write the makefile to";
  input String directory = "" "The relative path of the generated files";
  input String suffix = ".c" "Often .stamp since we do not update all the files";
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html><p>Under construction.</p>
</html>"),preferredView="text");
end generateSeparateCodeDependenciesMakefile;

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
<p>See <a href=\"modelica://OpenModelica.Scripting.loadModel\">loadModel()</a> for a description of what the MODELICAPATH is used for.</p>
<p>Set it to empty string to clear it: setModelicaPath(\"\");</p>
</html>"),
  preferredView="text");
end setModelicaPath;

function getModelicaPath "Get the Modelica Library Path."
  output String modelicaPath;
external "builtin";
annotation(Documentation(info="<html>
<p>The MODELICAPATH is a list of paths to search when trying to  <a href=\"modelica://OpenModelica.Scripting.loadModel\">load a library</a>. It is a string separated by colon (:) on all OSes except Windows, which uses semicolon (;).</p>
<p>To override the default path (<a href=\"modelica://OpenModelica.Scripting.getInstallationDirectoryPath\">OPENMODELICAHOME</a>/lib/omlibrary/:~/.openmodelica/libraries/), set the environment variable OPENMODELICALIBRARY=...</p>
<p>On Windows the HOME directory '~' is replaced by %APPDATA%</p>
</html>"),
  preferredView="text");
end getModelicaPath;

function setCompilerFlags
  input String compilerFlags;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setCompilerFlags;

function enableNewInstantiation
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end enableNewInstantiation;

function disableNewInstantiation
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end disableNewInstantiation;

function setDebugFlags "example input: failtrace,-noevalfunc"
  input String debugFlags;
  output Boolean success;
algorithm
  success := setCommandLineOptions("-d=" + debugFlags);
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setDebugFlags;

function clearDebugFlags
  "Resets all debug flags to their default values."
  output Boolean success;
  external "builtin";
  annotation(preferredView="text");
end clearDebugFlags;

function setPreOptModules "example input: removeFinalParameters,removeSimpleEquations,expandDerOperator"
  input String modules;
  output Boolean success;
algorithm
  success := setCommandLineOptions("--preOptModules=" + modules);
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setPreOptModules;

function setCheapMatchingAlgorithm "example input: 3"
  input Integer matchingAlgorithm;
  output Boolean success;
algorithm
  success := setCommandLineOptions("--cheapmatchingAlgorithm=" + String(matchingAlgorithm));
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
  success := setCommandLineOptions("--matchingAlgorithm=" + matchingAlgorithm);
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
  success := setCommandLineOptions("--indexReductionMethod=" + method);
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setIndexReductionMethod;

function setPostOptModules "example input: lateInline,inlineArrayEqn,removeSimpleEquations."
  input String modules;
  output Boolean success;
algorithm
  success := setCommandLineOptions("--postOptModules=" + modules);
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
  success := setCommandLineOptions("--tearingMethod=" + tearingMethod);
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setTearingMethod;

function setCommandLineOptions
  "The input is a regular command-line flag given to OMC, e.g. -d=failtrace or -g=MetaModelica"
  input String option;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setCommandLineOptions;

function getCommandLineOptions
  "Returns all command line options who have non-default values as a list of
   strings. The format of the strings is '--flag=value --flag2=value2'."
  output String[:] flags;
external "builtin";
annotation(preferredView="text");
end getCommandLineOptions;

function getConfigFlagValidOptions
  "Returns the list of valid options for a string config flag, and the description strings for these options if available"
  input String flag;
  output String validOptions[:];
  output String mainDescription;
  output String descriptions[:];
external "builtin";
annotation(preferredView="text");
end getConfigFlagValidOptions;

function clearCommandLineOptions
  "Resets all command-line flags to their default values."
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end clearCommandLineOptions;

function getVersion "Returns the version of the Modelica compiler."
  input TypeName cl = $TypeName(OpenModelica);
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

impure function stat
  input String fileName;
  output Boolean success;
  output Real fileSize;
  output Real mtime;
external "builtin" annotation(__OpenModelica_Impure=true,Documentation(info="<html>
<p>Like <a href=\"http://linux.die.net/man/2/stat\">stat(2)</a>, except the output is of type real because of limited precision of Integer.</p>
</html>"));
end stat;

impure function readFile
  "The contents of the given file are returned.
  Note that if the function fails, the error message is returned as a string instead of multiple output or similar."
  input String fileName;
  output String contents;
external "builtin" annotation(__OpenModelica_Impure=true, preferredView="text");
end readFile;

impure function writeFile
  "Write the data to file. Returns true on success."
  input String fileName;
  input String data;
  input Boolean append = false;
  output Boolean success;
external "builtin"; annotation(__OpenModelica_Impure=true, preferredView="text");
end writeFile;

impure function compareFilesAndMove
  input String newFile;
  input String oldFile;
  output Boolean success;
external "builtin"; annotation(__OpenModelica_Impure=true,Documentation(info="<html>
<p>Compares <i>newFile</i> and <i>oldFile</i>. If they differ, overwrite <i>oldFile</i> with <i>newFile</i></p>
<p>Basically: test -f ../oldFile && cmp newFile oldFile || mv newFile oldFile</p>
</html>"));
end compareFilesAndMove;

impure function compareFiles
  input String file1;
  input String file2;
  output Boolean isEqual;
external "builtin"; annotation(__OpenModelica_Impure=true,Documentation(info="<html>
<p>Compares <i>file1</i> and <i>file2</i> and returns true if their content is equal, otherwise false.</p>
</html>"));
end compareFiles;

impure function alarm
  input Integer seconds;
  output Integer previousSeconds;
external "builtin"; annotation(__OpenModelica_Impure=true,Library = {"omcruntime"},Documentation(info="<html>
<p>Like <a href=\"http://linux.die.net/man/2/alarm\">alarm(2)</a>.</p>
<p>Note that OpenModelica also sends SIGALRM to the process group when the alarm is triggered (in order to kill running simulations).</p>
</html>"));
end alarm;

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
  input Integer maxMatches = 1 "The maximum number of matches that will be returned";
  input Boolean extended = true "Use POSIX extended or regular syntax";
  input Boolean caseInsensitive = false;
  output Integer numMatches "-1 is an error, 0 means no match, else returns a number 1..maxMatches";
  output String matchedSubstrings[maxMatches] "unmatched strings are returned as empty";
external "C" numMatches = OpenModelica_regex(str,re,maxMatches,extended,caseInsensitive,matchedSubstrings);
annotation(preferredView="text");
end regex;

function regexBool "Returns true if the string matches the regular expression."
  input String str;
  input String re;
  input Boolean extended = true "Use POSIX extended or regular syntax";
  input Boolean caseInsensitive = false;
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

impure function getErrorString "Returns the current error message. [file.mo:n:n-n:n:b] Error: message"
  input Boolean warningsAsErrors = false;
  output String errorString;
external "builtin";
annotation(preferredView="text", Documentation(info="<html>
<p>Returns a user-friendly string containing the errors stored in the buffer. With warningsAsErrors=true, it reports warnings as if they were errors.</p>
</html>"));
end getErrorString;

function getMessagesString
  "see getErrorString()"
  output String messagesString;
external "builtin" messagesString=getErrorString();
annotation(preferredView="text");
end getMessagesString;

record SourceInfo
  String fileName;
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
  "{{[file.mo:n:n-n:n:b] Error: message, TRANSLATION, Error, code}}
  if unique = true (the default) only unique messages will be shown"
  input Boolean unique = true;
  output ErrorMessage[:] messagesString;
external "builtin";
annotation(preferredView="text");
end getMessagesStringInternal;

function countMessages
  output Integer numMessages;
  output Integer numErrors;
  output Integer numWarnings;
external "builtin";
annotation(Documentation(info="<html>
<p>Returns the total number of messages in the error buffer, as well as the number of errors and warnings.</p>
</html>"));
end countMessages;

function clearMessages "Clears the error buffer."
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end clearMessages;

impure function runScript "Runs the mos-script specified by the filename."
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
  success := setCommandLineOptions("--annotationVersion=" + annotationVersion);
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
  success := setCommandLineOptions("-v=" + String(vectorizationLimit));
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
  success := setCommandLineOptions("-o=" + String(defdevid));
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
  success := setCommandLineOptions("--orderConnections=" + String(orderConnections));
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
  success := setCommandLineOptions("--std=" + inVersion);
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
  input String fileName = "<interactive>";
  output String result "returns the string if fileName is interactive; else it returns ok or error depending on if writing the file succeeded";
external "builtin";
annotation(preferredView="text");
end getAstAsCorbaString;

function cd "change directory to the given path (which may be either relative or absolute)
  returns the new working directory on success or a message on failure
  if the given path is the empty string, the function simply returns the current working directory."
  input String newWorkingDirectory = "";
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

function copy "copies the source file to the destination file. Returns true if the file has been copied."
  input String source;
  input String destination;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end copy;

function remove "removes a file or directory of given path (which may be either relative or absolute)."
  input String path;
  output Boolean success "Returns true on success.";
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
  input Boolean checkProtected = false "Checks also protected classes if true";
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
  input Boolean showFlatModelica = false;
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
  input String[:] priorityVersion = {"default"};
  input Boolean notify = false "Give a notification of the libraries and versions that were loaded";
  input String languageStandard = "" "Override the set language standard. Parse with the given setting, but do not change it permanently.";
  input Boolean requireExactVersion = false "If the version is required to be exact, if there is a uses Modelica(version=\"3.2\"), Modelica 3.2.1 will not match it.";
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

function saveTotalModel "Save the className model in a single file, together with all
   the other classes that it depends upon, directly and indirectly.
   This file can be later reloaded with the loadFile() API function,
   which loads className and all the other needed classes into memory.
   This is useful to allow third parties to run a certain model (e.g. for debugging)
   without worrying about all the library dependencies.
   Please note that SaveTotal file is not a valid Modelica .mo file according to the
   specification, and cannot be loaded in OMEdit - it can only be loaded with loadFile()."
  input String fileName;
  input TypeName className;
  input Boolean stripAnnotations = false;
  input Boolean stripComments = false;
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

function saveTotalSCode = saveTotalModel;

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
  input String translationLevel = "flat" "flat, optimiser, backEnd, or stateSpace";
  input Boolean addOriginalAdjacencyMatrix = false;
  input Boolean addSolvingInfo = false;
  input Boolean addMathMLCode = false;
  input Boolean dumpResiduals = false;
  input String fileNamePrefix = "<default>" "this is the className in string form by default";
  input String rewriteRulesFile = "" "the file from where the rewiteRules are read, default is empty which means no rewrite rules";
  output Boolean success "if the function succeeded true/false";
  output String xmlfileName "the Xml file";
external "builtin";
annotation(Documentation(info="<html>
<p>Valid translationLevel strings are: <em>flat</em>, <em>optimiser</em> (runs the backend until sorting/matching), <em>backEnd</em>, or <em>stateSpace</em>.</p>
</html>"),preferredView="text");
end dumpXMLDAE;

function convertUnits
  input String s1;
  input String s2;
  output Boolean unitsCompatible;
  output Real scaleFactor;
  output Real offset;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Returns the scale factor and offsets used when converting two units.</p>
<p>Returns false if the types are not compatible and should not be converted.</p>
</html>"));
end convertUnits;

function getDerivedUnits
  input String baseUnit;
  output String[:] derivedUnits;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Returns the list of derived units for the specified base unit.</p>
</html>"));
end getDerivedUnits;

function listVariables "Lists the names of the active variables in the scripting environment."
  output TypeName variables[:];
external "builtin";
annotation(preferredView="text");
end listVariables;

function strtok "Splits the strings at the places given by the token, for example:
  strtok(\"abcbdef\",\"b\") => {\"a\",\"c\",\"def\"}
  strtok(\"abcbdef\",\"cd\") => {\"ab\",\"ef\"}
"
  input String string;
  input String token;
  output String[:] strings;
external "builtin";
annotation(Documentatrion(info="<html>
<p>Splits the strings at the places given by the token, for example:
<ul>
<li>strtok(\"abcbdef\",\"b\") => {\"a\",\"c\",\"def\"}</li>
<li>strtok(\"abcbdef\",\"cd\") => {\"ab\",\"ef\"}</li>
</ul>
</p>
<p>Note: strtok does not return empty tokens. To split a read file into every line, use <a href=\"modelica://OpenModelica.Scripting.stringSplit\">stringSplit</a> instead (splits only on character).</p>
</html>"),preferredView="text");
end strtok;

function stringSplit "Splits the string at the places given by the character"
  input String string;
  input String token "single character only";
  output String[:] strings;
external "builtin";
annotation(Documentatrion(info="<html>
<p>Splits the string at the places given by the character, for example:
<ul>
<li>stringSplit(\"abcbdef\",\"b\") => {\"a\",\"c\",\"def\"}</li>
</ul>
</p>
</html>"),preferredView="text");
end stringSplit;

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

type ExportKind = enumeration(Absyn "Normal Absyn",SCode "Normal SCode",MetaModelicaInterface "A restricted MetaModelica package interface (protected parts are stripped)",Internal "True unparsing of the Absyn");

function list "Lists the contents of the given class, or all loaded classes."
  input TypeName class_ = $TypeName(AllLoadedClasses);
  input Boolean interfaceOnly = false;
  input Boolean shortOnly = false "only short class definitions";
  input ExportKind exportKind = ExportKind.Absyn;
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

function listFile "Lists the contents of the file given by the class."
  input TypeName class_;
  input Boolean nestedClasses = true;
  output String contents;
external "builtin";
annotation(Documentation(info="<html>
<p>Lists the contents of the file given by the class.
See also <a href=\"modelica://OpenModelica.Scripting.list\">list()</a>.</p>
</html>",revisions="<html>
<table>
<tr><th>Revision</th><th>Author</th><th>Comment</th></tr>
<tr><td>1.9.3-dev</td><td>sjoelund.se</td><td>Introduced the API.</td></tr>
</table>
</html>"),
  preferredView="text");
end listFile;

type DiffFormat = enumeration(plain "no deletions, no markup", color "terminal escape sequences", xml "XML tags");

function diffModelicaFileListings "Creates diffs of two strings corresponding to Modelica files"
  input String before, after;
  input DiffFormat diffFormat = DiffFormat.color;
  output String result;
external "builtin";
annotation(Documentation(info="<html>
<p>Creates diffs of two strings (before and after) corresponding to Modelica files.
The diff is specialized to handle the <a href=\"modelica://OpenModelica.Scripting.list\">list</a>
API moving comments around in the file and introducing or deleting whitespace.</p>
<p>The output can be chosen to be a colored diff (for terminals), XML, or
the final text (deletions removed).</p>
</html>",revisions="<html>
<table>
<tr><th>Revision</th><th>Author</th><th>Comment</th></tr>
<tr><td>1.9.3-dev</td><td>sjoelund.se</td><td>Introduced the API.</td></tr>
</table>
</html>"),
  preferredView="text");
end diffModelicaFileListings;

// exportToFigaro added by Alexander Carlqvist
function exportToFigaro
  input TypeName path;
  input String directory = cd();
  input String database;
  input String mode;
  input String options;
  input String processor;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end exportToFigaro;

function inferBindings
  input TypeName path;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end inferBindings;

function generateVerificationScenarios
  input TypeName path;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end generateVerificationScenarios;

public function rewriteBlockCall "Function for property modeling, transforms block calls into instantiations for a loaded model"
  input TypeName className;
  input TypeName inDefs;
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
<p>An extension for modeling requirements in Modelica. Rewrites block calls as block instantiations.</p>
</html>"),preferredView="text");
end rewriteBlockCall;

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
  output String filename = "";
external "builtin" filename=OpenModelica_uriToFilename(uri);
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
  input LinearSystemSolver solver = LinearSystemSolver.dgesv;
  input Integer[:] isInt = {-1} "list of indices that are integers";
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

function importFMU "Imports the Functional Mockup Unit
  Example command:
  importFMU(\"A.fmu\");"
  input String filename "the fmu file name";
  input String workdir = "<default>" "The output directory for imported FMU files. <default> will put the files to current working directory.";
  input Integer loglevel = 3 "loglevel_nothing=0;loglevel_fatal=1;loglevel_error=2;loglevel_warning=3;loglevel_info=4;loglevel_verbose=5;loglevel_debug=6";
  input Boolean fullPath = false "When true the full output path is returned otherwise only the file name.";
  input Boolean debugLogging = false "When true the FMU's debug output is printed.";
  input Boolean generateInputConnectors = true "When true creates the input connector pins.";
  input Boolean generateOutputConnectors = true "When true creates the output connector pins.";
  output String generatedFileName "Returns the full path of the generated file.";
external "builtin";
annotation(preferredView="text");
end importFMU;

function importFMUModelDescription "Imports modelDescription.xml
  Example command:
  importFMUModelDescription(\"A.xml\");"
  input String filename "the fmu file name";
  input String workdir = "<default>" "The output directory for imported FMU files. <default> will put the files to current working directory.";
  input Integer loglevel = 3 "loglevel_nothing=0;loglevel_fatal=1;loglevel_error=2;loglevel_warning=3;loglevel_info=4;loglevel_verbose=5;loglevel_debug=6";
  input Boolean fullPath = false "When true the full output path is returned otherwise only the file name.";
  input Boolean debugLogging = false "When true the FMU's debug output is printed.";
  input Boolean generateInputConnectors = true "When true creates the input connector pins.";
  input Boolean generateOutputConnectors = true "When true creates the output connector pins.";
  output String generatedFileName "Returns the full path of the generated file.";
external "builtin";
annotation(preferredView="text");
end importFMUModelDescription;

function translateModelFMU
"translates a modelica model into a Functional Mockup Unit.
The only required argument is the className, while all others have some default values.
  Example command:
  translateModelFMU(className, version=\"2.0\");"
  input TypeName className "the class that should translated";
  input String version = "2.0" "FMU version, 1.0 or 2.0.";
  input String fmuType = "me" "FMU type, me (model exchange), cs (co-simulation), me_cs (both model exchange and co-simulation)";
  input String fileNamePrefix = "<default>" "fileNamePrefix. <default> = \"className\"";
  input Boolean includeResources = false "include Modelica based resources via loadResource or not";
  output String generatedFileName "Returns the full path of the generated FMU.";
external "builtin";
annotation(preferredView="text");
end translateModelFMU;

function buildModelFMU
"translates a modelica model into a Functional Mockup Unit.
The only required argument is the className, while all others have some default values.
  Example command:
  buildModelFMU(className, version=\"2.0\");"
  input TypeName className "the class that should translated";
  input String version = "2.0" "FMU version, 1.0 or 2.0.";
  input String fmuType = "me" "FMU type, me (model exchange), cs (co-simulation), me_cs (both model exchange and co-simulation)";
  input String fileNamePrefix = "<default>" "fileNamePrefix. <default> = \"className\"";
  input String platforms[:] = {"static"} "The list of platforms to generate code for. \"dynamic\"=current platform, dynamically link the runtime. \"static\"=current platform, statically link everything. Else, use a host triple, e.g. \"x86_64-linux-gnu\" or \"x86_64-w64-mingw32\"";
  input Boolean includeResources = false "include Modelica based resources via loadResource or not";
  output String generatedFileName "Returns the full path of the generated FMU.";
external "builtin";
annotation(preferredView="text");
end buildModelFMU;

function buildEncryptedPackage
  input TypeName className "the class that should encrypted";
  input Boolean encrypt = true;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end buildEncryptedPackage;

function simulate "simulates a modelica model by generating c code, build it and run the simulation executable.
 The only required argument is the className, while all others have some default values.
 simulate(className, [startTime], [stopTime], [numberOfIntervals], [tolerance], [method], [fileNamePrefix], [options], [outputFormat], [variableFilter], [cflags], [simflags])
 Example command:
  simulate(A);
"
  input TypeName className "the class that should simulated";
  input Real startTime = "<default>" "the start time of the simulation. <default> = 0.0";
  input Real stopTime = 1.0 "the stop time of the simulation. <default> = 1.0";
  input Real numberOfIntervals = 500 "number of intervals in the result file. <default> = 500";
  input Real tolerance = 1e-6 "tolerance used by the integration method. <default> = 1e-6";
  input String method = "<default>" "integration method used for simulation. <default> = dassl";
  input String fileNamePrefix = "<default>" "fileNamePrefix. <default> = \"\"";
  input String options = "<default>" "options. <default> = \"\"";
  input String outputFormat = "mat" "Format for the result file. <default> = \"mat\"";
  input String variableFilter = ".*" "Filter for variables that should store in result file. <default> = \".*\"";
  input String cflags = "<default>" "cflags. <default> = \"\"";
  input String simflags = "<default>" "simflags. <default> = \"\"";
  output SimulationResult simulationResults;
  record SimulationResult
    String resultFile;
    String simulationOptions;
    String messages;
    Real timeFrontend;
    Real timeBackend;
    Real timeSimCode;
    Real timeTemplates;
    Real timeCompile;
    Real timeSimulation;
    Real timeTotal;
  end SimulationResult;
external "builtin";
annotation(preferredView="text");
end simulate;

function buildModel "builds a modelica model by generating c code and build it.
 It does not run the code!
 The only required argument is the className, while all others have some default values.
 simulate(className, [startTime], [stopTime], [numberOfIntervals], [tolerance], [method], [fileNamePrefix], [options], [outputFormat], [variableFilter], [cflags], [simflags])
 Example command:
  simulate(A);
"
  input TypeName className "the class that should be built";
  input Real startTime = "<default>" "the start time of the simulation. <default> = 0.0";
  input Real stopTime = 1.0 "the stop time of the simulation. <default> = 1.0";
  input Real numberOfIntervals = 500 "number of intervals in the result file. <default> = 500";
  input Real tolerance = 1e-6 "tolerance used by the integration method. <default> = 1e-6";
  input String method = "<default>" "integration method used for simulation. <default> = dassl";
  input String fileNamePrefix = "<default>" "fileNamePrefix. <default> = \"\"";
  input String options = "<default>" "options. <default> = \"\"";
  input String outputFormat = "mat" "Format for the result file. <default> = \"mat\"";
  input String variableFilter = ".*" "Filter for variables that should store in result file. <default> = \".*\"";
  input String cflags = "<default>" "cflags. <default> = \"\"";
  input String simflags = "<default>" "simflags. <default> = \"\"";
  output String[2] buildModelResults;
external "builtin";
annotation(preferredView="text");
end buildModel;

function buildLabel "builds Lable."
input TypeName className "the class that should be built";
 input Real startTime = 0.0 "the start time of the simulation. <default> = 0.0";
  input Real stopTime = 1.0 "the stop time of the simulation. <default> = 1.0";
  input Integer numberOfIntervals = 500 "number of intervals in the result file. <default> = 500";
  input Real tolerance = 1e-6 "tolerance used by the integration method. <default> = 1e-6";
  input String method = "dassl" "integration method used for simulation. <default> = dassl";
  input String fileNamePrefix = "" "fileNamePrefix. <default> = \"\"";
  input String options = "" "options. <default> = \"\"";
  input String outputFormat = "mat" "Format for the result file. <default> = \"mat\"";
  input String variableFilter = ".*" "Filter for variables that should store in result file. <default> = \".*\"";
  input String cflags = "" "cflags. <default> = \"\"";
  input String simflags = "" "simflags. <default> = \"\"";
output String[2] buildModelResults;
external "builtin";
annotation(preferredView="text");
end buildLabel;

function reduceTerms "reduce terms."
input TypeName className "the class that should be built";
 input Real startTime = 0.0 "the start time of the simulation. <default> = 0.0";
  input Real stopTime = 1.0 "the stop time of the simulation. <default> = 1.0";
  input Integer numberOfIntervals = 500 "number of intervals in the result file. <default> = 500";
  input Real tolerance = 1e-6 "tolerance used by the integration method. <default> = 1e-6";
  input String method = "dassl" "integration method used for simulation. <default> = dassl";
  input String fileNamePrefix = "" "fileNamePrefix. <default> = \"\"";
  input String options = "" "options. <default> = \"\"";
  input String outputFormat = "mat" "Format for the result file. <default> = \"mat\"";
  input String variableFilter = ".*" "Filter for variables that should store in result file. <default> = \".*\"";
  input String cflags = "" "cflags. <default> = \"\"";
  input String simflags = "" "simflags. <default> = \"\"";
  input String labelstoCancel="";
output String[2] buildModelResults;
external "builtin";
annotation(preferredView="text");
end reduceTerms;

function moveClass
 "Moves a class up or down depending on the given offset, where a positive
  offset moves the class down and a negative offset up. The offset is truncated
  if the resulting index is outside the class list. It retains the visibility of
  the class by adding public/protected sections when needed, and merges sections
  of the same type if the class is moved from a section it was alone in. Returns
  true if the move was successful, otherwise false."
 input TypeName className "the class that should be moved";
 input Integer offset "Offset in the class list.";
 output Boolean result;
external "builtin";
annotation(preferredView="text");
end moveClass;

function moveClassToTop
  "Moves a class to the top of its enclosing class. Returns true if the move
   was successful, otherwise false."
  input TypeName className;
  output Boolean result;
external "builtin";
annotation(preferredView="text");
end moveClassToTop;

function moveClassToBottom
  "Moves a class to the bottom of its enclosing class. Returns true if the move
   was successful, otherwise false."
  input TypeName className;
  output Boolean result;
external "builtin";
annotation(preferredView="text");
end moveClassToBottom;

function copyClass
"Copies a class within the same level"
 input TypeName className "the class that should be copied";
 input String newClassName "the name for new class";
 input TypeName withIn = $TypeName(TopLevel) "the with in path for new class";
 output Boolean result;
external "builtin";
annotation(preferredView="text");
end copyClass;

function linearize "creates a model with symbolic linearization matrixes"
  input TypeName className "the class that should simulated";
  input Real startTime = "<default>" "the start time of the simulation. <default> = 0.0";
  input Real stopTime = 1.0 "the stop time of the simulation. <default> = 1.0";
  input Real numberOfIntervals = 500 "number of intervals in the result file. <default> = 500";
  input Real stepSize = 0.002 "step size that is used for the result file. <default> = 0.002";
  input Real tolerance = 1e-6 "tolerance used by the integration method. <default> = 1e-6";
  input String method = "<default>" "integration method used for simulation. <default> = dassl";
  input String fileNamePrefix = "<default>" "fileNamePrefix. <default> = \"\"";
  input Boolean storeInTemp = false "storeInTemp. <default> = false";
  input Boolean noClean = false "noClean. <default> = false";
  input String options = "<default>" "options. <default> = \"\"";
  input String outputFormat = "mat" "Format for the result file. <default> = \"mat\"";
  input String variableFilter = ".*" "Filter for variables that should store in result file. <default> = \".*\"";
  input String cflags = "<default>" "cflags. <default> = \"\"";
  input String simflags = "<default>" "simflags. <default> = \"\"";
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

function optimize "optimize a modelica/optimica model by generating c code, build it and run the optimization executable.
 The only required argument is the className, while all others have some default values.
 simulate(className, [startTime], [stopTime], [numberOfIntervals], [stepSize], [tolerance], [fileNamePrefix], [options], [outputFormat], [variableFilter], [cflags], [simflags])
 Example command:
  simulate(A);"
  input TypeName className "the class that should simulated";
  input Real startTime = "<default>" "the start time of the simulation. <default> = 0.0";
  input Real stopTime = 1.0 "the stop time of the simulation. <default> = 1.0";
  input Real numberOfIntervals = 500 "number of intervals in the result file. <default> = 500";
  input Real stepSize = 0.002 "step size that is used for the result file. <default> = 0.002";
  input Real tolerance = 1e-6 "tolerance used by the integration method. <default> = 1e-6";
  input String method = DAE.SCONST("optimization") "optimize a modelica/optimica model.";
  input String fileNamePrefix = "<default>" "fileNamePrefix. <default> = \"\"";
  input Boolean storeInTemp = false "storeInTemp. <default> = false";
  input Boolean noClean = false "noClean. <default> = false";
  input String options = "<default>" "options. <default> = \"\"";
  input String outputFormat = "mat" "Format for the result file. <default> = \"mat\"";
  input String variableFilter = ".*" "Filter for variables that should store in result file. <default> = \".*\"";
  input String cflags = "<default>" "cflags. <default> = \"\"";
  input String simflags = "<default>" "simflags. <default> = \"\"";
  output String optimizationResults;
external "builtin";
annotation(preferredView="text");
end optimize;

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
  input TypeName class_ = $TypeName(AllLoadedClasses);
  input Boolean recursive = false;
  input Boolean qualified = false;
  input Boolean sort = false;
  input Boolean builtin = false "List also builtin classes if true";
  input Boolean showProtected = false "List also protected classes if true";
  input Boolean includeConstants = false "List also constants in the class if true";
  output TypeName classNames[:];
external "builtin";
annotation(preferredView="text");
end getClassNames;

function getUsedClassNames "Returns the list of class names used in the total program defined by the class."
  input TypeName className;
  output TypeName classNames[:];
external "builtin";
annotation(preferredView="text");
end getUsedClassNames;

function getPackages "Returns the list of packages defined in the class."
  input TypeName class_ = $TypeName(AllLoadedClasses);
  output TypeName classNames[:];
external "builtin";
annotation(preferredView="text");
end getPackages;

function getAllSubtypeOf
  "Returns the list of all classes that extend from className given a parentClass where the lookup for className should start"
  input TypeName className;
  input TypeName parentClass = $TypeName(AllLoadedClasses);
  input Boolean qualified = false;
  input Boolean includePartial = false;
  input Boolean sort = false;
  output TypeName classNames[:];
external "builtin";
annotation(preferredView="text");
end getAllSubtypeOf;

partial function basePlotFunction "Extending this does not seem to work at the moment. A real shame; functions below are copy-paste and all need to be updated if the interface changes."
  input String fileName = "<default>" "The filename containing the variables. <default> will read the last simulation result";
  input String interpolation = "linear" "
    Determines if the simulation data should be interpolated to allow drawing of continuous lines in the diagram.
    \"linear\" results in linear interpolation between data points, \"constant\" keeps the value of the last known
    data point until a new one is found and \"none\" results in a diagram where only known data points are plotted."
  ;
  input String title = "Plot by OpenModelica" "This text will be used as the diagram title.";
  input Boolean legend = true "Determines whether or not the variable legend is shown.";
  input Boolean grid = true "Determines whether or not a grid is shown in the diagram.";
  input Boolean logX = false "Determines whether or not the horizontal axis is logarithmically scaled.";
  input Boolean logY = false "Determines whether or not the vertical axis is logarithmically scaled.";
  input String xLabel = "time" "This text will be used as the horizontal label in the diagram.";
  input String yLabel = "" "This text will be used as the vertical label in the diagram.";
  input Boolean points = false "Determines whether or not the data points should be indicated by a dot in the diagram.";
  input Real xRange[2] = {0.0,0.0} "Determines the horizontal interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real yRange[2] = {0.0,0.0} "Determines the vertical interval that is visible in the diagram. {0,0} will select a suitable range.";
  output Boolean success "Returns true on success";
annotation(preferredView="text");
end basePlotFunction;

function plot "Launches a plot window using OMPlot."
  input VariableNames vars "The variables you want to plot";
  input Boolean externalWindow = false "Opens the plot in a new plot window";
  input String fileName = "<default>" "The filename containing the variables. <default> will read the last simulation result";
  input String title = "" "This text will be used as the diagram title.";
  input String grid = "detailed" "Sets the grid for the plot i.e simple, detailed, none.";
  input Boolean logX = false "Determines whether or not the horizontal axis is logarithmically scaled.";
  input Boolean logY = false "Determines whether or not the vertical axis is logarithmically scaled.";
  input String xLabel = "time" "This text will be used as the horizontal label in the diagram.";
  input String yLabel = "" "This text will be used as the vertical label in the diagram.";
  input Real xRange[2] = {0.0,0.0} "Determines the horizontal interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real yRange[2] = {0.0,0.0} "Determines the vertical interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real curveWidth = 1.0 "Sets the width of the curve.";
  input Integer curveStyle = 1 "Sets the style of the curve. SolidLine=1, DashLine=2, DotLine=3, DashDotLine=4, DashDotDotLine=5, Sticks=6, Steps=7.";
  input String legendPosition = "top" "Sets the POSITION of the legend i.e left, right, top, bottom, none.";
  input String footer = "" "This text will be used as the diagram footer.";
  input Boolean autoScale = true "Use auto scale while plotting.";
  input Boolean forceOMPlot = false "if true launches OMPlot and doesn't call callback function even if it is defined.";
  output Boolean success "Returns true on success";
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Launches a plot window using OMPlot. Returns true on success.</p>

<p>Example command sequences:</p>
<ul>
<li>simulate(A);plot({x,y,z});</li>
<li>simulate(A);plot(x, externalWindow=true);</li>
<li>simulate(A,fileNamePrefix=\"B\");simulate(C);plot(z,fileName=\"B.mat\",legend=false);</li>
</ul>
</html>"));
end plot;

function plotAll "Works in the same way as plot(), but does not accept any
  variable names as input. Instead, all variables are part of the plot window.

  Example command sequences:
  simulate(A);plotAll();
  simulate(A);plotAll(externalWindow=true);
  simulate(A,fileNamePrefix=\"B\");simulate(C);plotAll(x,fileName=\"B.mat\");"

  input Boolean externalWindow = false "Opens the plot in a new plot window";
  input String fileName = "<default>" "The filename containing the variables. <default> will read the last simulation result";
  input String title = "" "This text will be used as the diagram title.";
  input String grid = "detailed" "Sets the grid for the plot i.e simple, detailed, none.";
  input Boolean logX = false "Determines whether or not the horizontal axis is logarithmically scaled.";
  input Boolean logY = false "Determines whether or not the vertical axis is logarithmically scaled.";
  input String xLabel = "time" "This text will be used as the horizontal label in the diagram.";
  input String yLabel = "" "This text will be used as the vertical label in the diagram.";
  input Real xRange[2] = {0.0,0.0} "Determines the horizontal interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real yRange[2] = {0.0,0.0} "Determines the vertical interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real curveWidth = 1.0 "Sets the width of the curve.";
  input Integer curveStyle = 1 "Sets the style of the curve. SolidLine=1, DashLine=2, DotLine=3, DashDotLine=4, DashDotDotLine=5, Sticks=6, Steps=7.";
  input String legendPosition = "top" "Sets the POSITION of the legend i.e left, right, top, bottom, none.";
  input String footer = "" "This text will be used as the diagram footer.";
  input Boolean autoScale = true "Use auto scale while plotting.";
  input Boolean forceOMPlot = false "if true launches OMPlot and doesn't call callback function even if it is defined.";
  output Boolean success "Returns true on success";
external "builtin";
annotation(preferredView="text");
end plotAll;

function plotParametric "Launches a plotParametric window using OMPlot. Returns true on success.

  Example command sequences:
  simulate(A);plotParametric(x,y);
  simulate(A);plotParametric(x,y, externalWindow=true);
  "
  input VariableName xVariable;
  input VariableName yVariable;
  input Boolean externalWindow = false "Opens the plot in a new plot window";
  input String fileName = "<default>" "The filename containing the variables. <default> will read the last simulation result";
  input String title = "" "This text will be used as the diagram title.";
  input String grid = "detailed" "Sets the grid for the plot i.e simple, detailed, none.";
  input Boolean logX = false "Determines whether or not the horizontal axis is logarithmically scaled.";
  input Boolean logY = false "Determines whether or not the vertical axis is logarithmically scaled.";
  input String xLabel = "time" "This text will be used as the horizontal label in the diagram.";
  input String yLabel = "" "This text will be used as the vertical label in the diagram.";
  input Real xRange[2] = {0.0,0.0} "Determines the horizontal interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real yRange[2] = {0.0,0.0} "Determines the vertical interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real curveWidth = 1.0 "Sets the width of the curve.";
  input Integer curveStyle = 1 "Sets the style of the curve. SolidLine=1, DashLine=2, DotLine=3, DashDotLine=4, DashDotDotLine=5, Sticks=6, Steps=7.";
  input String legendPosition = "top" "Sets the POSITION of the legend i.e left, right, top, bottom, none.";
  input String footer = "" "This text will be used as the diagram footer.";
  input Boolean autoScale = true "Use auto scale while plotting.";
  input Boolean forceOMPlot = false "if true launches OMPlot and doesn't call callback function even if it is defined.";
  output Boolean success "Returns true on success";
external "builtin";
annotation(preferredView="text");
end plotParametric;

function readSimulationResult "Reads a result file, returning a matrix corresponding to the variables and size given."
  input String filename;
  input VariableNames variables;
  input Integer size = 0 "0=read any size... If the size is not the same as the result-file, this function fails";
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
  input Boolean readParameters = true;
  input Boolean openmodelicaStyle = false;
  output String[:] vars;
external "builtin";
annotation(Documentation(info="<html>
<p>Takes one simulation results file and returns the variables stored in it.</p>
<p>If readParameters is true, parameter names are returned.</p>
<p>If openmodelicaStyle is true, the stored variable names are converted to the canonical form used by OpenModelica variables (a.der(b) becomes der(a.b), and so on).</p>
</html>"),preferredView="text");
end readSimulationResultVars;

public function filterSimulationResults
  input String inFile;
  input String outFile;
  input String[:] vars;
  input Integer numberOfIntervals = 0 "0=Do not resample";
  input Boolean removeDescription = false;
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
<p>Takes one simulation result and filters out the selected variables only, producing the output file.</p>
<p>If numberOfIntervals<>0, re-sample to that number of intervals, ignoring event points (might be changed in the future).</p>
<p>if removeDescription=true, the description matrix will contain 0-length strings, making the file smaller.</p>
</html>",revisions="<html>
<table>
<tr><th>Revision</th><th>Author</th><th>Comment</th></tr>
<tr><td>1.13.0</td><td>sjoelund.se</td><td>Introduced removeDescription.</td></tr>
</table>
</html>"),preferredView="text");
end filterSimulationResults;

public function compareSimulationResults "compares simulation results."
  input String filename;
  input String reffilename;
  input String logfilename;
  input Real relTol = 0.01;
  input Real absTol = 0.0001;
  input String[:] vars = fill("",0);
  output String[:] result;
external "builtin";
annotation(preferredView="text");
end compareSimulationResults;

public function deltaSimulationResults "calculates the sum of absolute errors."
  input String filename;
  input String reffilename;
  input String method "method to compute then error. choose 1norm, 2norm, maxerr";
  input String[:] vars = fill("",0);
  output Real result;
external "builtin";
annotation(Documentation(info="<html>
<p>For each data point in the reference file, the sum of all absolute error sums of all given variables is calculated.</p>
</html>"),preferredView="text");
end deltaSimulationResults;

public function diffSimulationResults "compares simulation results."
  input String actualFile;
  input String expectedFile;
  input String diffPrefix;
  input Real relTol = 1e-3 "y tolerance";
  input Real relTolDiffMinMax = 1e-4 "y tolerance based on the difference between the maximum and minimum of the signal";
  input Real rangeDelta = 0.002 "x tolerance";
  input String[:] vars = fill("",0);
  input Boolean keepEqualResults = false;
  output Boolean success /* On success, resultFiles is empty. But it might be empty on failure anyway (for example if an input file does not exist) */;
  output String[:] failVars;
external "builtin";
annotation(Documentation(info="<html>
<p>Takes two result files and compares them. By default, all selected variables that are not equal in the two files are output to diffPrefix.varName.csv.</p>
<p>The output is the names of the variables for which files were generated.</p>
</html>"),preferredView="text");
end diffSimulationResults;

public function diffSimulationResultsHtml
  input String var;
  input String actualFile;
  input String expectedFile;
  input Real relTol = 1e-3 "y tolerance";
  input Real relTolDiffMinMax = 1e-4 "y tolerance based on the difference between the maximum and minimum of the signal";
  input Real rangeDelta = 0.002 "x tolerance";
  output String html;
external "builtin";
annotation(Documentation(info="<html>
<p>Takes two result files and compares them. By default, all selected variables that are not equal in the two files are output to diffPrefix.varName.csv.</p>
<p>The output is the names of the variables for which files were generated.</p>
</html>"),preferredView="text");
end diffSimulationResultsHtml;

public function checkTaskGraph "Checks if the given taskgraph has the same structure as the reference taskgraph and if all attributes are set correctly."
  input String filename;
  input String reffilename;
  output String[:] result;
external "builtin";
annotation(preferredView="text");
end checkTaskGraph;

public function checkCodeGraph "Checks if the given taskgraph has the same structure as the graph described in the codefile."
  input String graphfile;
  input String codefile;
  output String[:] result;
external "builtin";
annotation(preferredView="text");
end checkCodeGraph;

function val "Return the value of a variable at a given time in the simulation results"
  input VariableName var;
  input Real timePoint = 0.0;
  input String fileName = "<default>" "The contents of the currentSimulationResult variable";
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
  input ExpressionOrModification annotate;
  output Boolean bool;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Used to set annotations, like Diagrams and Icons in classes. The function is given the name of the class
and the annotation to set.</p>
<p>Usage: addClassAnnotation(Modelica, annotate = Documentation(info = \"&lt;html&gt;&lt;/html&gt;\"))</p>
</html>"));
end addClassAnnotation;

function getParameterNames
  input TypeName class_;
  output String[:] parameters;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns the list of parameters of the class.
</html>"),
  preferredView="text");
end getParameterNames;

function getParameterValue
  input TypeName class_;
  input String parameterName;
  output String parameterValue;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns the value of the parameter of the class.
</html>"),
  preferredView="text");
end getParameterValue;

function getComponentModifierNames
  input TypeName class_;
  input String componentName;
  output String[:] modifiers;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns the list of class component modifiers.
</html>"),
  preferredView="text");
end getComponentModifierNames;

function getComponentModifierValue
  input TypeName class_;
  input TypeName modifier;
  output String value;
external "builtin";
annotation(
  Documentation(info="<html>
  <p>Returns the modifier value (only the binding excluding submodifiers) of component.
    For instance,
      model A
        B b1(a1(p1=5,p2=4));
      end A;
      getComponentModifierValue(A,b1.a1.p1) => 5
      getComponentModifierValue(A,b1.a1.p2) => 4
    See also <a href=\"modelica://OpenModelica.Scripting.getComponentModifierValues\">getComponentModifierValues()</a>.</p>
</html>"),
  preferredView="text");
end getComponentModifierValue;

function getComponentModifierValues
  input TypeName class_;
  input TypeName modifier;
  output String value;
external "builtin";
annotation(
  Documentation(info="<html>
  <p>Returns the modifier value (including the submodfiers) of component.
    For instance,
      model A
        B b1(a1(p1=5,p2=4));
      end A;
      getComponentModifierValues(A,b1.a1) => (p1 = 5, p2 = 4)
    See also <a href=\"modelica://OpenModelica.Scripting.getComponentModifierValue\">getComponentModifierValue()</a>.</p>
</html>"),
  preferredView="text");
end getComponentModifierValues;

function removeComponentModifiers
  input TypeName class_;
  input String componentName;
  input Boolean keepRedeclares = false;
  output Boolean success;
external "builtin";
annotation(
  Documentation(info="<html>
  Removes the component modifiers.
</html>"),
  preferredView="text");
end removeComponentModifiers;

function getElementModifierNames
  input TypeName className;
  input String elementName;
  output String[:] modifiers;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns the list of element (component or short class) modifiers in a class.
</html>"),
  preferredView="text");
end getElementModifierNames;

function getElementModifierValue
  input TypeName className;
  input TypeName modifier;
  output String value;
external "builtin";
annotation(
  Documentation(info="<html>
  <p>Returns the modifier value (only the binding excluding submodifiers) of element (component or short class).
    For instance,
      model A
        B b1(a1(p1=5,p2=4));
        model X = Y(a1(p1=5,p2=4));
      end A;
      getElementModifierValue(A,b1.a1.p1) => 5
      getElementModifierValue(A,b1.a1.p2) => 4
      getElementModifierValue(A,X.a1.p1) => 5
      getElementModifierValue(A,X.a1.p2) => 4
    See also <a href=\"modelica://OpenModelica.Scripting.getElementModifierValues\">getElementModifierValues()</a>.</p>
</html>"),
  preferredView="text");
end getElementModifierValue;

function getElementModifierValues
  input TypeName className;
  input TypeName modifier;
  output String value;
external "builtin";
annotation(
  Documentation(info="<html>
  <p>Returns the modifier value (including the submodfiers) of element (component or short class).
    For instance,
      model A
        B b1(a1(p1=5,p2=4));
        model X = Y(a1(p1=5,p2=4));
      end A;
      getElementModifierValues(A,b1.a1) => (p1 = 5, p2 = 4)
      getElementModifierValues(A,X.a1) => (p1 = 5, p2 = 4)
    See also <a href=\"modelica://OpenModelica.Scripting.getElementModifierValue\">getElementModifierValue()</a>.</p>
</html>"),
  preferredView="text");
end getElementModifierValues;

function removeElementModifiers
  input TypeName className;
  input String componentName;
  input Boolean keepRedeclares = false;
  output Boolean success;
external "builtin";
annotation(
  Documentation(info="<html>
  Removes the element (component or short class) modifiers.
</html>"),
  preferredView="text");
end removeElementModifiers;

function getInstantiatedParametersAndValues
  input TypeName cls;
  output String[:] values;
external "builtin";
annotation(
  Documentation(info="<html>
  <p>Returns the parameter names and values from the DAE.</p>
</html>"),
  preferredView="text");
end getInstantiatedParametersAndValues;

function removeExtendsModifiers
  input TypeName className;
  input TypeName baseClassName;
  input Boolean keepRedeclares = false;
  output Boolean success;
external "builtin";
annotation(
  Documentation(info="<html>
  Removes the extends modifiers of a class.
</html>"),
  preferredView="text");
end removeExtendsModifiers;

function updateConnection
  input TypeName className;
  input String from;
  input String to;
  input ExpressionOrModification annotate;
  output Boolean result;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Updates the connection annotation in the class. See also updateConnectionNames().</p>
</html>"));
end updateConnection;

function updateConnectionNames
  input TypeName className;
  input String from;
  input String to;
  input String fromNew;
  input String toNew;
  output Boolean result;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Updates the connection connector names in the class. See also updateConnection().</p>
</html>"));
end updateConnectionNames;

function getConnectionCount "Counts the number of connect equation in a class."
  input TypeName className;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getConnectionCount;

function getNthConnection "Returns the Nth connection.
  Example command:
  getNthConnection(A) => {\"from\", \"to\", \"comment\"}"
  input TypeName className;
  input Integer index;
  output String[:] result;
external "builtin";
annotation(preferredView="text");
end getNthConnection;

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

function getMMfileTotalDependencies
  input String in_package_name;
  input String public_imports_dir;
  output String[:] total_pub_imports;
external "builtin";
annotation(preferredView="text");
end getMMfileTotalDependencies;

function getImportedNames "Returns the prefix paths of all imports in a class."
  input TypeName class_;
  output String[:] out_public;
  output String[:] out_protected;
external "builtin";
annotation(preferredView="text");
end getImportedNames;

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
  input String to = "UTF-8";
  output String result;
external "builtin";
annotation(preferredView="text");
end iconv;

function getDocumentationAnnotation "Returns the documentaiton annotation defined in the class."
  input TypeName cl;
  output String out[3] "{info,revision,infoHeader} TODO: Should be changed to have 2 outputs instead of an array of 2 Strings...";
external "builtin";
annotation(preferredView="text");
end getDocumentationAnnotation;

function setDocumentationAnnotation
  input TypeName class_;
  input String info = "";
  input String revisions = "";
  output Boolean bool;

  external "builtin";
annotation(preferredView = "text", Documentation(info = "<html>
<p>Used to set the Documentation annotation of a class. An empty argument (e.g. for revisions) means no annotation is added.</p>
</html>"));
end setDocumentationAnnotation;

function getTimeStamp
  input TypeName cl;
  output Real timeStamp;
  output String timeStampAsString;
external "builtin";
annotation(Documentation(info = "<html>
<p>The given class corresponds to a file (or a buffer), with a given last time this file was modified at the time of loading this file. The timestamp along with its String representation is returned.</p>
</html>"));
end getTimeStamp;

function stringTypeName
  input String str;
  output TypeName cl;
external "builtin";
annotation(Documentation(info = "<html>
<p>stringTypeName is used to make it simpler to create some functionality when scripting. The basic use-case is calling functions like simulate when you do not know the name of the class a priori simulate(stringTypeName(readFile(\"someFile\"))).</p>
</html>"),preferredView="text");
end stringTypeName;

function stringVariableName
  input String str;
  output VariableName cl;
external "builtin";
annotation(Documentation(info = "<html>
<p>stringVariableName is used to make it simpler to create some functionality when scripting. The basic use-case is calling functions like val when you do not know the name of the variable a priori val(stringVariableName(readFile(\"someFile\"))).</p>
</html>"),preferredView="text");
end stringVariableName;

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

function getClassRestriction
  input TypeName cl;
  output String restriction;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns the restriction of the given class.
</html>"),
  preferredView="text");
end getClassRestriction;

function isType
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns true if the given class has restriction type.
</html>"),
  preferredView="text");
end isType;

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

function isClass
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns true if the given class has restriction class.
</html>"),
  preferredView="text");
end isClass;

function isRecord
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns true if the given class has restriction record.
</html>"),
  preferredView="text");
end isRecord;

function isBlock
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns true if the given class has restriction block.
</html>"),
  preferredView="text");
end isBlock;

function isFunction
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns true if the given class has restriction function.
</html>"),
  preferredView="text");
end isFunction;

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

function isConnector
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns true if the given class has restriction connector or expandable connector.
</html>"),
  preferredView="text");
end isConnector;

function isOptimization
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns true if the given class has restriction optimization.
</html>"),
  preferredView="text");
end isOptimization;

function isEnumeration
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns true if the given class has restriction enumeration.
</html>"),
  preferredView="text");
end isEnumeration;

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

function getBuiltinType
  input TypeName cl;
  output String name;
external "builtin";
annotation(
  Documentation(info="<html>
  Returns the builtin type e.g Real, Integer, Boolean & String of the class.
</html>"),
  preferredView="text");
end getBuiltinType;

function setInitXmlStartValue
  input String fileName;
  input String variableName;
  input String startValue;
  input String outputFile;
  output Boolean success = false;
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

function ngspicetoModelica "Converts ngspice netlist to Modelica code. Modelica file is created in the same directory as netlist file."
  input String netlistfileName;
  output Boolean success = false;
protected
  String command;
algorithm
  command := "python " + getInstallationDirectoryPath() + "/share/omc/scripts/ngspicetoModelica.py " + netlistfileName;
  success := 0 == system(command);
annotation(preferredView="text");
end ngspicetoModelica;

function getInheritedClasses
  input TypeName name;
  output TypeName inheritedClasses[:];
external "builtin";
annotation(
  Documentation(info="<html>
  Returns the list of inherited classes.
</html>"),
  preferredView="text");
end getInheritedClasses;

function getComponentsTest
  input TypeName name;
  output Component[:] components;
  record Component
    String className; // when building record the constructor. Records are allowed to contain only components of basic types, arrays of basic types or other records.
    String name;
    String comment;
    Boolean isProtected;
    Boolean isFinal;
    Boolean isFlow;
    Boolean isStream;
    Boolean isReplaceable;
    String variability "'constant', 'parameter', 'discrete', ''";
    String innerOuter "'inner', 'outer', ''";
    String inputOutput "'input', 'output', ''";
    String dimensions[:];
  end Component;
external "builtin";
annotation(Documentation(info="<html>
<p>Returns the components found in the given class.</p>
</html>"));
end getComponentsTest;

function isExperiment
  input TypeName name;
  output Boolean res;
external "builtin";
annotation(Documentation(info="<html>
<p>An experiment is defined as having annotation experiment(StopTime=...)</p>
</html>"));
end isExperiment;

function getSimulationOptions
  input TypeName name;
  input Real defaultStartTime = 0.0;
  input Real defaultStopTime = 1.0;
  input Real defaultTolerance = 1e-6;
  input Integer defaultNumberOfIntervals = 500 "May be overridden by defining defaultInterval instead";
  input Real defaultInterval = 0.0 "If = 0.0, then numberOfIntervals is used to calculate the step size";
  output Real startTime;
  output Real stopTime;
  output Real tolerance;
  output Integer numberOfIntervals;
  output Real interval;
external "builtin";
annotation(Documentation(info="<html>
<p>Returns the startTime, stopTime, tolerance, and interval based on the experiment annotation.</p>
</html>"));
end getSimulationOptions;

function getAnnotationNamedModifiers
   input TypeName name;
   input String vendorannotation;
   output String[:] modifiernamelist;
external "builtin";
annotation(Documentation(info="<html>
<p>Returns the Modifiers name in the vendor annotation example annotation(__OpenModelica_simulationFlags(solver=\"dassl\"))
calling sequence should be getAnnotationNamedModifiers(className,\"__OpenModelica_simulationFlags\") which returns {solver}.</p>
</html>"));
end getAnnotationNamedModifiers;

function getAnnotationModifierValue
  input TypeName name;
  input String vendorannotation;
  input String modifiername;
  output String modifiernamevalue;
external "builtin";
annotation(Documentation(info="<html>
<p>Returns the Modifiers value in the vendor annotation example annotation(__OpenModelica_simulationFlags(solver=\"dassl\"))
calling sequence should be getAnnotationNamedModifiersValue(className,\"__OpenModelica_simulationFlags\",\"modifiername\") which returns \"dassl\".</p>
</html>"));
end getAnnotationModifierValue;

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
  input String version = "3.2.1";
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
<p>Example session:</p>
<pre>loadModelica3D();getErrorString();
loadString(\"model DoublePendulum
  extends Modelica.Mechanics.MultiBody.Examples.Elementary.DoublePendulum;
  inner ModelicaServices.Modelica3D.Controller m3d_control;
end DoublePendulum;\");getErrorString();
system(\"python \" + getInstallationDirectoryPath() + \"/lib/omlibrary-modelica3d/osg-gtk/dbus-server.py &amp;\");getErrorString();
simulate(DoublePendulum);getErrorString();</pre>
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
  input Boolean findInText = false;
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

function installPackage
  input TypeName pkg;
  input String version = "";
  input Boolean exactMatch = false;
  output Boolean result;
external "builtin";
annotation(
  Documentation(info="<html>
  Installs the package with the best matching version (or only the specified version if exactMatch is given).
  To update the index, call <code>updatePackageIndex()</code>.
</html>"),
  preferredView="text");
end installPackage;

function updatePackageIndex
  output Boolean result;
external "builtin";
annotation(
  Documentation(info="<html>
  Updates the package index from the internet.
  This adds new packages to be able to install or upgrade packages.
  To upgrade installed packages, call <code>upgradeInstalledPackages()</code>.
</html>"),
  preferredView="text");
end updatePackageIndex;

function upgradeInstalledPackages
  input Boolean installNewestVersions = true;
  output Boolean result;
external "builtin";
annotation(
  Documentation(info="<html>
  Upgrades installed packages that have been registered by the package manager.
  To update the index, call <code>updatePackageIndex()</code>.
</html>"),
  preferredView="text");
end upgradeInstalledPackages;

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

function getConversionsFromVersions
  input TypeName pack;
  output String[:] withoutConversion;
  output String[:] withConversion;
external "builtin";
annotation(
  Documentation(info="<html>
Returns the versions this library can convert from with and without conversions.
</html>"),
  preferredView="text");
end getConversionsFromVersions;

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
  getDerivedClassModifierValue(Resistance, quantity); => \" = \"Resistance\"\""
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

function runScriptParallel
  input String scripts[:];
  input Integer numThreads = numProcessors();
  input Boolean useThreads = false;
  output Boolean results[:];
external "builtin";
annotation(
  Documentation(info="<html>
<p>As <a href=\"modelica://OpenModelica.Scripting.runScript\">runScript</a>, but runs the commands in parallel.</p>
<p>If useThreads=false (default), the script will be run in an empty environment (same as running a new omc process) with default config flags.</p>
<p>If useThreads=true (experimental), the scripts will run in parallel in the same address space and with the same environment (which will not be updated).</p>
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

function threadWorkFailed
external "builtin";
annotation(
  Documentation(info="<html>
<p>(Experimental) Exits the current (<a href=\"modelica://OpenModelica.Scripting.runScriptParallel\">worker thread</a>) signalling a failure.</p>
</html>"));
end threadWorkFailed;

function getMemorySize
  output Real memory(unit="MiB");
external "builtin";
annotation(
  Documentation(info="<html>
<p>Retrieves the physical memory size available on the system in megabytes.</p>
</html>"));
end getMemorySize;

function GC_gcollect_and_unmap
external "builtin";
annotation(
  Documentation(info="<html>
<p>Forces GC to collect and unmap memory (we use it before we start and wait for memory-intensive tasks in child processes).</p>
</html>"));
end GC_gcollect_and_unmap;

function GC_expand_hp
  input Integer size;
  output Boolean success;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Forces the GC to expand the heap to accomodate more data.</p>
</html>"));
end GC_expand_hp;

function GC_set_max_heap_size
  input Integer size;
  output Boolean success;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Forces the GC to limit the maximum heap size.</p>
</html>"));
end GC_set_max_heap_size;

record GC_PROFSTATS
  Integer heapsize_full;
  Integer free_bytes_full;
  Integer unmapped_bytes;
  Integer bytes_allocd_since_gc;
  Integer allocd_bytes_before_gc;
  Integer non_gc_bytes;
  Integer gc_no;
  Integer markers_m1;
  Integer bytes_reclaimed_since_gc;
  Integer reclaimed_bytes_before_gc;
end GC_PROFSTATS;

function GC_get_prof_stats
  output GC_PROFSTATS gcStats;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns a record with the GC statistics.</p>
</html>"));
end GC_get_prof_stats;

function checkInterfaceOfPackages
  input TypeName cl;
  input String dependencyMatrix[:,:];
  output Boolean success;
  external "builtin";
annotation(
  Documentation(info="<html>
<p>Verifies the __OpenModelica_Interface=str annotation of all loaded packages with respect to the given main class.</p>
<p>For each row in the dependencyMatrix, the first element is the name of a dependency type. The rest of the elements are the other accepted dependency types for this one (frontend can call frontend and util, for example). Empty entries are ignored (necessary in order to have a rectangular matrix).</p>
</html>"));
end checkInterfaceOfPackages;

function sortStrings
  input String arr[:];
  output String sorted[:];
  external "builtin";
annotation(
  Documentation(info="<html>
<p>Sorts a string array in ascending order.</p>
</html>"));
end sortStrings;

function getClassInformation
  input TypeName cl;
  output String restriction, comment;
  output Boolean partialPrefix, finalPrefix, encapsulatedPrefix;
  output String fileName;
  output Boolean fileReadOnly;
  output Integer lineNumberStart, columnNumberStart, lineNumberEnd, columnNumberEnd;
  output String dimensions[:];
  output Boolean isProtectedClass;
  output Boolean isDocumentationClass;
  output String version;
  output String preferredView;
  output Boolean state;
  output String access;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns class information for the given class.</p>
<p>The dimensions are returned as an array of strings. The string is the textual representation of the dimension (they are not evaluated to Integers).</p>
</html>"), preferredView="text");
end getClassInformation;

function getTransitions
  input TypeName cl;
  output String[:,:] transitions;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns list of transitions for the given class.</p>
<p>Each transition item contains 8 values i.e, from, to, condition, immediate, reset, synchronize, priority.</p>
</html>"), preferredView="text");
end getTransitions;

function addTransition
  input TypeName cl;
  input String from;
  input String to;
  input String condition;
  input Boolean immediate = true;
  input Boolean reset = true;
  input Boolean synchronize = false;
  input Integer priority = 1;
  input ExpressionOrModification annotate;
  output Boolean bool;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Adds the transition to the class.</p>
</html>"));
end addTransition;

function deleteTransition
  input TypeName cl;
  input String from;
  input String to;
  input String condition;
  input Boolean immediate;
  input Boolean reset;
  input Boolean synchronize;
  input Integer priority;
  output Boolean bool;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Deletes the transition from the class.</p>
</html>"));
end deleteTransition;

function updateTransition
  input TypeName cl;
  input String from;
  input String to;
  input String oldCondition;
  input Boolean oldImmediate;
  input Boolean oldReset;
  input Boolean oldSynchronize;
  input Integer oldPriority;
  input String newCondition;
  input Boolean newImmediate;
  input Boolean newReset;
  input Boolean newSynchronize;
  input Integer newPriority;
  input ExpressionOrModification annotate;
  output Boolean bool;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Updates the transition in the class.</p>
</html>"));
end updateTransition;

function getInitialStates
  input TypeName cl;
  output String[:,:] initialStates;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns list of initial states for the given class.</p>
<p>Each initial state item contains 2 values i.e, state name and annotation.</p>
</html>"), preferredView="text");
end getInitialStates;

function addInitialState
  input TypeName cl;
  input String state;
  input ExpressionOrModification annotate;
  output Boolean bool;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Adds the initial state to the class.</p>
</html>"));
end addInitialState;

function deleteInitialState
  input TypeName cl;
  input String state;
  output Boolean bool;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Deletes the initial state from the class.</p>
</html>"));
end deleteInitialState;

function updateInitialState
  input TypeName cl;
  input String state;
  input ExpressionOrModification annotate;
  output Boolean bool;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Updates the initial state in the class.</p>
</html>"));
end updateInitialState;

function generateScriptingAPI
  input TypeName cl;
  input String name;
  output Boolean success;
  output String moFile;
  output String qtFile;
  output String qtHeader;
external "builtin";
annotation(
  Documentation(info="<html>
<p><b>Work in progress</b></p>
<p>Returns OpenModelica.Scripting API entry points for the classes that we can automatically generate entry points for.</p>
<p>The entry points are MetaModelica code calling CevalScript directly, and Qt/C++ code that calls the MetaModelica code.</p>
</html>"), preferredView="text");
end generateScriptingAPI;

// OMSimulator API calls
type oms_system = enumeration(oms_system_none,oms_system_tlm, oms_system_wc,oms_system_sc);
type oms_causality = enumeration(oms_causality_input, oms_causality_output, oms_causality_parameter, oms_causality_bidir, oms_causality_undefined);
type oms_signal_type = enumeration (oms_signal_type_real,
  oms_signal_type_integer,
  oms_signal_type_boolean,
  oms_signal_type_string,
  oms_signal_type_enum,
  oms_signal_type_bus);

type oms_solver = enumeration(
  oms_solver_none,
  oms_solver_sc_min,
  oms_solver_sc_explicit_euler,
  oms_solver_sc_cvode,  ///< default
  oms_solver_sc_max,
  oms_solver_wc_min,
  oms_solver_wc_ma,     ///< Fixed stepsize (default)
  oms_solver_wc_mav,    ///< Adaptive stepsize
  oms_solver_wc_assc,   ///< Adaptive stepsize by @farkasrebus
  oms_solver_wc_mav2,   ///< Adaptive stepsize (double-step)
  oms_solver_wc_max
);

type oms_tlm_domain = enumeration(
  oms_tlm_domain_input,
  oms_tlm_domain_output,
  oms_tlm_domain_mechanical,
  oms_tlm_domain_rotational,
  oms_tlm_domain_hydraulic,
  oms_tlm_domain_electric
);

type oms_tlm_interpolation = enumeration(
  oms_tlm_no_interpolation,
  oms_tlm_coarse_grained,
  oms_tlm_fine_grained
);

type oms_fault_type = enumeration (
  oms_fault_type_bias,      ///< y = y.$original + faultValue
  oms_fault_type_gain,      ///< y = y.$original * faultValue
  oms_fault_type_const      ///< y = faultValue
);

function loadOMSimulator "loads the OMSimulator DLL from default path"
  output Integer status;
external "builtin";
annotation(preferredView="text");
end loadOMSimulator;

function unloadOMSimulator "free the OMSimulator instances"
  output Integer status;
external "builtin";
annotation(preferredView="text");
end unloadOMSimulator;

function oms_addBus
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addBus;

function oms_addConnection
  input String crefA;
  input String crefB;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addConnection;

function oms_addConnector
  input String cref;
  input oms_causality causality;
  input oms_signal_type type_;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addConnector;

function oms_addConnectorToBus
  input String busCref;
  input String connectorCref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addConnectorToBus;

function oms_addConnectorToTLMBus
  input String busCref;
  input String connectorCref;
  input String type_;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addConnectorToTLMBus;

function oms_addDynamicValueIndicator
  input String signal;
  input String lower;
  input String upper;
  input Real stepSize;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addDynamicValueIndicator;

function oms_addEventIndicator
  input String signal;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addEventIndicator;

function oms_addExternalModel
  input String cref;
  input String path;
  input String startscript;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addExternalModel;

function oms_addSignalsToResults
  input String cref;
  input String regex;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addSignalsToResults;

function oms_addStaticValueIndicator
  input String signal;
  input Real lower;
  input Real upper;
  input Real stepSize;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addStaticValueIndicator;

function oms_addSubModel
  input String cref;
  input String fmuPath;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addSubModel;

function oms_addSystem
  input String cref;
  input oms_system type_;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addSystem;

function oms_addTimeIndicator
  input String signal;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addTimeIndicator;

function oms_addTLMBus
  input String cref;
  input oms_tlm_domain domain;
  input Integer dimensions;
  input oms_tlm_interpolation interpolation;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addTLMBus;

function oms_addTLMConnection
  input String crefA;
  input String crefB;
  input Real delay;
  input Real alpha;
  input Real linearimpedance;
  input Real angularimpedance;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addTLMConnection;

function oms_cancelSimulation_asynchronous
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_cancelSimulation_asynchronous;

function oms_compareSimulationResults
  input String filenameA;
  input String filenameB;
  input String var;
  input Real relTol;
  input Real absTol;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_compareSimulationResults;

function oms_copySystem
  input String source;
  input String target;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_copySystem;

function oms_delete
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_delete;

function oms_deleteConnection
  input String crefA;
  input String crefB;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_deleteConnection;

function oms_deleteConnectorFromBus
  input String busCref;
  input String connectorCref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_deleteConnectorFromBus;

function oms_deleteConnectorFromTLMBus
  input String busCref;
  input String connectorCref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_deleteConnectorFromTLMBus;

function oms_export
  input String cref;
  input String filename;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_export;

function oms_exportDependencyGraphs
  input String cref;
  input String initialization;
  input String simulation;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_exportDependencyGraphs;

function oms_extractFMIKind
  input String filename;
  output Integer  kind;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_extractFMIKind;

function oms_getBoolean
  input String cref;
  output Boolean  value;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getBoolean;

function oms_getFixedStepSize
  input String cref;
  output Real stepSize;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getFixedStepSize;

function oms_getInteger
  input String cref;
  input Integer value;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getInteger;

function oms_getModelState
  input String cref;
  output Integer modelState;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getModelState;

function oms_getReal
  input String cref;
  output Real value;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getReal;

function oms_getSolver
  input String cref;
  output Integer solver;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getSolver;

function oms_getStartTime
  input String cref;
  output Real startTime;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getStartTime;

function oms_getStopTime
  input String cref;
  output Real stopTime;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getStopTime;

function oms_getSubModelPath
  input String cref;
  output String path;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getSubModelPath;

function oms_getSystemType
  input String cref;
  output Integer type_;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getSystemType;

function oms_getTolerance
  input String cref;
  output Real absoluteTolerance;
  output Real relativeTolerance;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getTolerance;

function oms_getVariableStepSize
  input String cref;
  output Real initialStepSize;
  output Real minimumStepSize;
  output Real maximumStepSize;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getVariableStepSize;

function oms_faultInjection
  input String signal;
  input oms_fault_type faultType;
  input Real faultValue;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_faultInjection;

function oms_importFile
  input String filename;
  output String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_importFile;

function oms_initialize
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_initialize;

function oms_instantiate
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_instantiate;

function oms_list
  input String cref;
  output String contents;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_list;

function oms_listUnconnectedConnectors
  input String cref;
  output String contents;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_listUnconnectedConnectors;

function oms_loadSnapshot
  input String cref;
  input String snapshot;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_loadSnapshot;

function oms_newModel
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_newModel;

function oms_parseModelName
  input String contents;
  output String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_parseModelName;

function oms_removeSignalsFromResults
  input String cref;
  input String regex;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_removeSignalsFromResults;

function oms_rename
  input String cref;
  input String newCref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_rename;

function oms_reset
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_reset;

function oms_RunFile
  input String filename;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_RunFile;

function oms_setBoolean
  input String cref;
  input Boolean value;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setBoolean;

function oms_setCommandLineOption
  input String cmd;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setCommandLineOption;

function oms_setFixedStepSize
  input String cref;
  input Real stepSize;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setFixedStepSize;

function oms_setInteger
  input String cref;
  input Integer value;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setInteger;

function oms_setLogFile
  input String filename;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setLogFile;

function oms_setLoggingInterval
  input String cref;
  input Real loggingInterval;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setLoggingInterval;

function oms_setLoggingLevel
  input Integer logLevel;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setLoggingLevel;

function oms_setReal
  input String cref;
  input Real value;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setReal;

function oms_setRealInputDerivative
  input String cref;
  input Real value;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setRealInputDerivative;

function oms_setResultFile
  input String cref;
  input String filename;
  input Integer bufferSize;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setResultFile;

function oms_setSignalFilter
  input String cref;
  input String regex;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setSignalFilter;

function oms_setSolver
  input String cref;
  input oms_solver solver;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setSolver;

function oms_setStartTime
  input String cref;
  input Real startTime;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setStartTime;

function oms_setStopTime
  input String cref;
  input Real stopTime;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setStopTime;

function oms_setTempDirectory
  input String newTempDir;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setTempDirectory;

function oms_setTLMPositionAndOrientation
  input String cref;
  input Real x1;
  input Real x2;
  input Real x3;
  input Real A11;
  input Real A12;
  input Real A13;
  input Real A21;
  input Real A22;
  input Real A23;
  input Real A31;
  input Real A32;
  input Real A33;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setTLMPositionAndOrientation;

function oms_setTLMSocketData
  input String cref;
  input String address;
  input Integer managerPort;
  input Integer monitorPort;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setTLMSocketData;

function oms_setTolerance
  input String cref;
  input Real absoluteTolerance;
  input Real relativeTolerance;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setTolerance;

function oms_setVariableStepSize
  input String cref;
  input Real initialStepSize;
  input Real minimumStepSize;
  input Real maximumStepSize;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setVariableStepSize;

function oms_setWorkingDirectory
  input String newWorkingDir;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setWorkingDirectory;

function oms_simulate
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_simulate;

function oms_stepUntil
  input String cref;
  input Real stopTime;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_stepUntil;

function oms_terminate
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_terminate;

function oms_getVersion "Returns the version of the OMSimulator."
  output String version;
external "builtin";
annotation(preferredView="text");
end oms_getVersion;

// end of OMSimulator API calls

package Experimental

function relocateFunctions
  input String fileName;
  input String names[:,2];
  output Boolean success;
external "builtin";
annotation(
  Documentation(info="<html>
<p><strong>Highly experimental, requires OMC be compiled with special flags to use</strong>.</p>
<p>Update symbols in the running program to ones defined in the given shared object.</p>
<p>This will hot-swap the functions at run-time, enabling a smart build system to do some incremental compilation
(as long as the function interfaces are the same).</p>
</html>"), preferredView="text");
end relocateFunctions;

function toJulia
  output String res;
external "builtin";
end toJulia;

function interactiveDumpAbsynToJL
  output String res;
external "builtin";
end interactiveDumpAbsynToJL;

end Experimental;

end Scripting;

package UsersGuide
package ReleaseNotes
  annotation(Documentation(info = "<html>
  <head><meta http-equiv=\"refresh\" content=\"0; url=https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/releases.html\"></head>
  <body>Redirecting to the <a href=\"https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/releases.html\">on-line release notes</a> (you can also find the release notes in the locally installed version of the user's guide, OPENMODELICAHOME/share/doc/OpenModelicaUsersGuide).</body>
</html>"));
end ReleaseNotes;
end UsersGuide;

package AutoCompletion "Auto completion information for OMEdit."
  package Annotations "Auto completion information on annotations."
    // Annotations for Documentation
    record Documentation "Defines the documentation."
      String info "The textual description of the class.";
      String revisions "A list of revisions and other annotations defined by a tool.";
    end Documentation;

    String preferredView = "diagram" "Default view when selecting the class (<b>info</b>, <b>diagram</b> or <b>text</b>).";
    Boolean DocumentationClass = true "Implies that this class and all classes within it are treated as having the annotation <b>preferredView=\"info\"</b>. If the annotation <b>preferredView</b> is explicitly set for a class, it has precedence over a <b>DocumentationClass</b> annotation.";

    // Annotations for Code Generation
    Boolean Evaluate = true "Defines if the value can be utilize for symbolic processing.";
    Boolean HideResult = true "Proposes to not show the simulator results.";
    Boolean Inline = true "Proposes to inline the function which means the body of the function is included at all places where the function is called.";
    Boolean LateInline = true "Proposes to inline the function after all symbolic transformations have been performed.";
    Boolean GenerateEvents = true "proposes that crossing functions in the function should generate events.";
    Integer smoothOrder "Defines the number of differentiations of the function, in order that all of the differentiated outputs are continuous provided all input arguments and their derivatives up to order <b>smoothOrder</b> are continuous.";

    // Annotations for Simulation Experiments
    record experiment "Define default experiment parameters."
      Real StartTime(unit = "s") = 0 "Default start time of simulation.";
      Real StopTime(unit = "s") = 1 "Default stop time of simulation.";
      Real Interval(unit = "s", min = 0) = 0.002 "Resolution for the result grid.";
      Real Tolerance(min = 0) = 1e-6 "Default relative integration tolerance.";
    end experiment;

    // Annotation for single use of class
    Boolean singleInstance = true "Indicates that there should only be one component instance of the class.";

    // TODO: Annotations for Graphical Objects. Do we really need them? Don't think that users will prefer to write them manually.

    // Annotations for the Graphical User Interface
    String defaultComponentName "Recommended name when creating a component of the class.";
    String defaultComponentPrefixes "Recommended prefixes when creating a component of the class.";
    String missingInnerMessage "Specifies a message when an <b>outer</b> component of the class does not have a corresponding <b>inner</b> component.";
    Boolean absoluteValue "If <b>false</b>, then the variable defines a relative quantity, and if <b>true</b> an absolute quantity.";
    Boolean defaultConnectionStructurallyInconsistent "If <b>true</b>, it is stated that a default connection will result in a structurally inconsistent model or block.";
    String obsolete "Indicates that the class ideally should not be used anymore and gives a message indicating the recommended action.";
    String unassignedMessage "Defines a diagnostic message to use when a variable declaration cannot be computed due to the structure of the equations.";

    record Dialog
      parameter String tab = "General";
      parameter String group = "Parameters";
      parameter Boolean enable = true;
      parameter Boolean showStartAttribute = false;
      parameter Boolean colorSelector = false;
      parameter Selector loadSelector;
      parameter Selector saveSelector;
      parameter String groupImage = "";
      parameter Boolean connectorSizing = false;
    end Dialog;

    record Selector
      parameter String filter = "";
      parameter String caption = "";
    end Selector;

    // Annotations for Version Handling
    String version "The version number of the released library.";
    String versionDate "The date in UTC format (according to ISO 8601) when the library was released.";
    Integer versionBuild "The optional build number of the library.";
    String dateModified "The UTC date and time (according to ISO 8601) of the last modification of the package.";
    String revisionId "A tool specific revision identifier possibly generated by a source code management system (e.g. Subversion or CVS).";

    record uses "A list of dependent classes."
    end uses;

    // Annotations for Access Control to Protect Intellectual Property
    type Access = enumeration(hide, icon, documentation, diagram, nonPackageText, nonPackageDuplicate, packageText, packageDuplicate);

    record Protection "Protection of class"
      Access access "Defines what parts of a class are visible.";
      String features[:] = fill("", 0) "Required license features";
      record License
        String libraryKey;
        String licenseFile = "" "Optional, default mapping if empty";
      end License;
    end Protection;

    record Authorization
      String licensor = "" "Optional string to show information about the licensor";
      String libraryKey "Matching the key in the class. Must be encrypted and not visible";
      License license[:] "Definition of the license options and of the access rights";
    end Authorization;

    record License
      String licensee = "" "Optional string to show information about the licensee";
      String id[:] "Unique machine identifications, e.g. MAC addresses";
      String features[:] = fill("", 0) "Activated library license features";
      String startDate = "" "Optional start date in UTCformat YYYY-MM-DD";
      String expirationDate = "" "Optional expiration date in UTCformat YYYY-MM-DD";
      String operations[:] = fill("",0) "Library usage conditions";
    end License;

    // TODO: Function Derivative Annotations

    // Inverse Function Annotation
    record inverse
    end inverse;

    // TODO: External Function Annotations

    // Annotation Choices for Modifications and Redeclarations
    record choices "Defines a suitable redeclaration or modifications of the element."
      Boolean checkBox = true "Display a checkbox to input the values false or true in the graphical user interface.";
      // TODO: how to handle choice?
    end choices;

    Boolean choicesAllMatching "Specify whether to construct an automatic list of choices menu or not.";

    record derivative
      Integer order = 1;
      String noDerivative;
      String zeroDerivative;
    end derivative;

    record __OpenModelica_commandLineOptions
    end __OpenModelica_commandLineOptions;

    record __OpenModelica_simulationFlags
    end __OpenModelica_simulationFlags;

    // TODO: Annotation for External Libraries and Include Files

    annotation(
        Documentation(info = "<html>In this package annotations are gathered in their record-like form together with meta information such as descriptions, units, min, max, etc.</html>"));
  end Annotations;
  annotation(
    Documentation(info = "<html>In this package a machine-readable auto completion information is gathered for use by OMEdit.</html>"));
end AutoCompletion;

annotation(
  Documentation(revisions="<html>See <a href=\"modelica://OpenModelica.UsersGuide.ReleaseNotes\">ReleaseNotes</a></html>",
  __Dymola_DocumentationClass = true),
  preferredView="text");
end OpenModelica;
