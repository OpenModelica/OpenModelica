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
) annotation(__OpenModelica_builtin = true);

type Uncertainty = enumeration(
  given,
  sought,
  refine,
  propagate
) annotation(__OpenModelica_builtin = true);

partial class Clock
  annotation(__OpenModelica_builtin=true);
end Clock;

partial class ExternalObject
  annotation(__OpenModelica_builtin=true);
end ExternalObject;

function der "Derivative of the input expression"
  input Real x(unit="'p");
  output Real dx(unit="'p/s");
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'der()'\">der()</a>
</html>"));
end der;

impure function initial "True if in initialization phase"
  discrete output Boolean isInitial;
external "builtin";
annotation(__OpenModelica_builtin=true, __OpenModelica_Impure=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'initial()'\">initial()</a>
</html>"));
end initial;

impure function terminal "True after successful analysis"
  discrete output Boolean isTerminal;
external "builtin";
annotation(__OpenModelica_builtin=true, __OpenModelica_Impure=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'terminal()'\">terminal()</a>
</html>"));
end terminal;

type AssertionLevel = enumeration(warning, error) annotation(__OpenModelica_builtin=true,
  Documentation(info="<html>Used by <a href=\"modelica://assert\">assert()</a></html>"));

function assert "Check an assertion condition"
  input Boolean condition;
  input String message;
  input AssertionLevel level = AssertionLevel.error;
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'assert()'\">assert()</a>
</html>"));
end assert;

function ceil "Round a real number towards plus infinity"
  input Real x;
  output Real y;
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'ceil()'\">ceil()</a>
</html>"));
end ceil;

function floor "Round a real number towards minus infinity"
  input Real x;
  output Real y;
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'floor()'\">floor()</a>
</html>"));
end floor;

function integer "Returns the largest integer not greater than x. The argument shall have type Real. The result has type Integer. [Note, outside of a when-clause state events are triggered when the return value changes discontinuously.]."
  input Real x;
  output Integer y;
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'integer()'\">integer()</a>
</html>"));
end integer;

function sqrt "Square root"
  input Real x(unit="'p");
  output Real y(unit="'p(1/2)");
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'sqrt()'\">sqrt()</a>
</html>"));
end sqrt;

function sign "Sign of real or integer number"
  input Real v;
  output Integer _sign;
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
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
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'identity()'\">identity()</a>
</html>"));
end identity;

function semiLinear
  input Real x;
  input Real positiveSlope;
  input Real negativeSlope;
  output Real result;
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'semiLinear()'\">semiLinear()</a>
</html>"));
end semiLinear;

function edge "Indicate rising edge"
  input Boolean b;
  output Boolean edgeEvent;
  // TODO: Ceval parameters? Needed to remove the builtin handler
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'edge()'\">edge()</a>
</html>"));
end edge;

function sin "Sine"
  input Real x;
  output Real y;
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'sin()'\">sin()</a>
</html>"));
end sin;

function cos "Cosine"
  input Real x;
  output Real y;
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'cos()'\">cos()</a>
</html>"));
end cos;

function tan "Tangent (u shall not be -pi/2, pi/2, 3*pi/2, ...)"
  input Real u;
  output Real y;
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'tan()'\">tan()</a>
</html>"));
end tan;

function sinh "Hyperbolic sine"
  input Real x;
  output Real y;
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'sinh()'\">sinh()</a>
</html>"));
end sinh;

function cosh "Hyperbolic cosine"
  input Real x;
  output Real y;
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'cosh()'\">cosh()</a>
</html>"));
end cosh;

function tanh "Hyperbolic tangent"
  input Real x;
  output Real y;
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'tanh()'\">tanh()</a>
</html>"));
end tanh;

function asin "Inverse sine (-1 <= u <= 1)"
  input Real u;
  output Real y;
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'asin()'\">asin()</a>
</html>"));
end asin;

function acos "Inverse cosine (-1 <= u <= 1)"
  input Real u;
  output Real y;
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'acos()'\">acos()</a>
</html>"));
end acos;

function atan "Inverse tangent"
  input Real x;
  output Real y;
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'atan()'\">atan()</a>
</html>"));
end atan;

function atan2 "Four quadrant inverse tangent"
  input Real y;
  input Real x;
  output Real z;
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'atan2()'\">atan2()</a>
</html>"));
end atan2;

function exp "Exponential, base e"
  input Real x(unit="1");
  output Real y(unit="1");
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'exp()'\">exp()</a>
</html>"));
end exp;

function log "Natural (base e) logarithm (u shall be > 0)"
  input Real u(unit="1");
  output Real y(unit="1");
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'log()'\">log()</a>
</html>"));
end log;

function log10 "Base 10 logarithm (u shall be > 0)"
  input Real u(unit="1");
  output Real y(unit="1");
external "builtin";
annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'log10()'\">log10()</a>
</html>"));
end log10;

impure function homotopy "Homotopy operator actual*lambda + simplified*(1-lambda)"
  input Real actual;
  input Real simplified;
  output Real outValue;
external "builtin";
annotation(__OpenModelica_builtin=true, version="Modelica 3.2",Documentation(info="<html>
  See <a href=\"https://specification.modelica.org/maint/3.6/operators-and-expressions.html#homotopy\">homotopy()</a>
</html>"));
end homotopy;

function linspace "Real vector with equally spaced elements"
  input Real x1 "start";
  input Real x2 "end";
  input Integer n "number";
  output Real v[n];
algorithm
  // Error.assertion(n >= 2, "linspace requires n>=2 but got " + String(n), sourceInfo());
  v := {x1 + (x2-x1)*(i-1)/(n-1) for i in 1:n};
  annotation(__OpenModelica_builtin=true,__OpenModelica_EarlyInline=true,Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'linspace()'\">linspace()</a>
</html>"));
end linspace;

function div = $overload(OpenModelica.Internal.intDiv,OpenModelica.Internal.realDiv)
  "Integer part of a division of two Real numbers"
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'div()'\">div()</a>
</html>"));

function mod = $overload(OpenModelica.Internal.intMod,OpenModelica.Internal.realMod)
  "Integer modulus of a division of two Real numbers"
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'mod()'\">mod()</a>
</html>"));

function rem = $overload(OpenModelica.Internal.intRem,OpenModelica.Internal.realRem)
  "Integer remainder of the division of two Real numbers"
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'rem()'\">rem()</a>
</html>"));

function abs = $overload(OpenModelica.Internal.intAbs,OpenModelica.Internal.realAbs)
  "Absolute value"
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
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
algorithm
  z := { x[2]*y[3]-x[3]*y[2] , x[3]*y[1]-x[1]*y[3] , x[1]*y[2]-x[2]*y[1] };
annotation(__OpenModelica_builtin=true, __OpenModelica_EarlyInline = true, preferredView="text",Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'cross()'\">cross()</a>
</html>"));
end cross;

function skew "The skew matrix associated with the vector"
  input Real[3] x;
  output Real[3,3] y;
algorithm
  y := {{0, -x[3], x[2]}, {x[3], 0, -x[1]}, {-x[2], x[1], 0}};
annotation(__OpenModelica_builtin=true, __OpenModelica_EarlyInline = true, preferredView = "text", Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'skew()'\">skew()</a>
</html>"));
end skew;

function delay = $overload(OpenModelica.Internal.delay2,OpenModelica.Internal.delay3) "Delay expression"
  annotation(__OpenModelica_builtin=true, __OpenModelica_Impure=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'delay()'\">delay()</a>
</html>"));

// function min = $overload(OpenModelica.Internal.realMin, OpenModelica.Internal.intMin
//                         , OpenModelica.Internal.boolMin, OpenModelica.Internal.enumMin
//                         , OpenModelica.Internal.arrayMin)
//function min = $overload(OpenModelica.Internal.scalarMin, OpenModelica.Internal.arrayMin)
function min
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'min()'\">min()</a>
</html>"));
end min;

// function max = $overload(OpenModelica.Internal.realMax, OpenModelica.Internal.intMax
//                         , OpenModelica.Internal.boolMax, OpenModelica.Internal.enumMax
//                         , OpenModelica.Internal.arrayMax)
//function max = $overload(OpenModelica.Internal.scalarMax, OpenModelica.Internal.arrayMax)
function max
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'max()'\">max()</a>
</html>"));
end max;

function sum<__Array, __Scalar> "Sum of all array elements"
  input __Array a;
  output __Scalar s;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'sum()'\">sum()</a>
</html>"));
end sum;

function product<__Array, __Scalar> "Product of all array elements"
  input __Array a;
  output __Scalar s;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'product()'\">product()</a>
</html>"));
end product;

function promote
  external "builtin";
  annotation(__OpenModelica_builtin=true);
end promote;

function transpose<T> "Transpose a matrix"
  input T a;
  output T b;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'transpose()'\">transpose()</a>
</html>"));
end transpose;

function symmetric<T> "Returns a symmetric matrix"
  input T[:, size(a, 1)] a;
  output T[size(a, 1), size(a, 2)] b;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'symmetric()'\">symmetric()</a>
</html>"));
end symmetric;

function smooth<RealArrayOrRecord> "Indicate smoothness of expression"
  parameter input Integer p annotation(__OpenModelica_functionVariability=true);
  input RealArrayOrRecord expr;
  output RealArrayOrRecord s;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'smooth()'\">smooth()</a>
</html>"));
end smooth;

function diagonal<__Scalar> "Returns a diagonal matrix"
  input __Scalar v[:];
  output __Scalar mat[size(v,1),size(v,1)];
  external "builtin";
  annotation(__OpenModelica_builtin=true, __OpenModelica_UnboxArguments=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'diagonal()'\">diagonal()</a>
</html>"));
end diagonal;

function cardinality<__Connector> "Number of connectors in connection"
  input __Connector c;
  parameter output Integer numOccurances;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'cardinality()'\">cardinality()</a>
</html>"),version="Deprecated");
end cardinality;

function array "Constructs an array"
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'array()'\">array()</a>
</html>"));
end array;

function zeros "Returns a zero array"
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'zeros()'\">zeros()</a>
</html>"));
end zeros;

function ones "Returns a one array"
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'ones()'\">ones()</a>
</html>"));
end ones;

function fill "Returns an array with all elements equal"
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'fill()'\">fill()</a>
</html>"));
end fill;

function noEvent<__Any> "Turn off event triggering"
  input __Any x;
  output __Any y;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'noEvent()'\">noEvent()</a>
</html>"));
end noEvent;

function pre<PodCref> "Refer to left limit"
  discrete input PodCref y;
  output PodCref p;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'pre()'\">pre()</a>
</html>"));
end pre;

function change<PodCref> "Indicate discrete variable changing"
  discrete input PodCref y;
  output Boolean p;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'change()'\">change()</a>
</html>"));
end change;

function reinit<RealOrArrayCref, RealOrArrayExpr> "Reinitialize state variable"
  input RealOrArrayCref x;
  input RealOrArrayExpr expr;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'reinit()'\">reinit()</a>
</html>"));
end reinit;

function sample = $overload(OMC_NO_CLOCK.sample, OMC_CLOCK.sample)
   "Returns the interval between the previous and present tick of the clock of its argument"
  annotation(__OpenModelica_builtin=true, __OpenModelica_UnboxArguments=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'sample()'\">sample()</a>
</html>"));

package OMC_NO_CLOCK
  impure function sample "Overloaded operator to either trigger time events or to convert between continuous-time and clocked-time representation"
    parameter input Real start annotation(__OpenModelica_functionVariability=true);
    parameter input Real interval annotation(__OpenModelica_functionVariability=true);
    output Boolean b;
    external "builtin";
    annotation(Documentation(info="<html>
    See <a href=\"modelica://ModelicaReference.Operators.'sample()'\">sample()</a>
  </html>"));
  end sample;
end OMC_NO_CLOCK;

package OMC_CLOCK
  impure function sample<T> "Overloaded operator to either trigger time events or to convert between continuous-time and clocked-time representation"
    input T u;
    input Clock c = OpenModelica.Internal.inferredClock();
    output T o;
    external "builtin";
    annotation(version="Modelica 3.3", Documentation(info="<html>
    See <a href=\"modelica://ModelicaReference.Operators.'sample()'\">sample()</a>
  </html>"));
  end sample;
end OMC_CLOCK;

function shiftSample<__Any> "First activation of clock is shifted in time"
  input __Any u;
  parameter input Integer shiftCounter(min = 0) annotation(__OpenModelica_functionVariability=true);
  parameter input Integer resolution(min = 1) = 1 annotation(__OpenModelica_functionVariability=true);
  output __Any c;
  external "builtin";
  annotation(__OpenModelica_builtin=true, version="Modelica 3.3", Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'shiftSample()'\">shiftSample()</a>
</html>"));
end shiftSample;

function backSample<__Any> "First activation of clock is shifted in time before activation of u"
  input __Any u;
  parameter input Integer backCounter(min = 0) annotation(__OpenModelica_functionVariability=true);
  parameter input Integer resolution(min = 1) = 1 annotation(__OpenModelica_functionVariability=true);
  output __Any c;
  external "builtin";
  annotation(__OpenModelica_builtin=true, version="Modelica 3.3", Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'backSample()'\">backSample()</a>
</html>"));
end backSample;

function transition<__Block> "Define state machine transition"
  input __Block from;
  input __Block to;
  input Boolean condition;
  input Boolean immediate = true;
  input Boolean reset = true;
  input Boolean synchronize = false;
  input Integer priority = 1;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'transition()'\">transition()</a>
</html>"));
end transition;

function initialState<__Block> "Define inital state of a state machine"
  input __Block state;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'initialState()'\">initialState()</a>
</html>"));
end initialState;

function activeState<__Block> "Return true if instance of a state machine is active, otherwise false"
  input __Block state;
  output Boolean active;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'activeState()'\">activeState()</a>
</html>"));
end activeState;

function ndims<T> "Number of array dimensions"
  input T a;
  parameter output Integer d;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'ndims()'\">ndims()</a>
</html>"));
end ndims;

function size "Returns dimensions of an array"
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'size()'\">size()</a>
</html>"));
end size;

impure function DynamicSelect<__Any> "select static or dynamic expressions in the annotations"
  input __Any static;
  input __Any dynamic;
  output __Any selected;
  external "builtin";
  annotation(__OpenModelica_builtin=true, __OpenModelica_Impure=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Annotations.DynamicSelect\">DynamicSelect</a>
</html>"));
end DynamicSelect;

function scalar<T,ScalarType> "Returns a one-element array as scalar"
  input T i;
  output ScalarType s;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'scalar()'\">scalar()</a>
</html>"));
end scalar;

function vector<T,VectorType> "Returns an array as vector"
  input T i;
  output VectorType v;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'vector()'\">vector()</a>
</html>"));
end vector;

function matrix<T,Matrix> "Returns the first two dimensions of an array as matrix"
  input T i;
  output Matrix m;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'matrix()'\">matrix()</a>
</html>"));
end matrix;

function cat "Concatenate arrays along given dimension"
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'cat()'\">cat()</a>
</html>"));
end cat;

function actualStream
  input Real x;
  output Real y;
  external "builtin";
  annotation(__OpenModelica_builtin=true);
end actualStream;

function inStream
  input Real x;
  output Real y;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'inStream()'\">inStream()</a>
</html>"));
end inStream;

function pure<__Any>
  input __Any x;
  output __Any y;
  external "builtin";
  annotation(__OpenModelica_builtin=true, version="Modelica 3.4");
end pure;

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

function rooted
  external "builtin";
  annotation(__OpenModelica_builtin=true);
end rooted;

encapsulated package Connections
  import OpenModelica.$Code.VariableName;

  function branch
    input VariableName node1;
    input VariableName node2;
    external "builtin";
    annotation(__OpenModelica_builtin=true);
  end branch;

  function root
    input VariableName node;
    external "builtin";
    annotation(__OpenModelica_builtin=true);
  end root;

  function potentialRoot
    input VariableName node;
    parameter input Integer priority = 0 annotation(__OpenModelica_functionVariability=true);
    external "builtin";
    annotation(__OpenModelica_builtin=true);
  end potentialRoot;

  function isRoot
    input VariableName node;
    output Boolean isroot;
    external "builtin";
    annotation(__OpenModelica_builtin=true);
  end isRoot;

  function uniqueRoot
    input VariableName root;
    input String message = "";
    external "builtin";
    annotation(__OpenModelica_builtin=true);
  end uniqueRoot;

  function uniqueRootIndices
    input VariableName[:] roots;
    input VariableName[:] nodes;
    input String message = "";
    output Integer[size(roots, 1)] rootIndices;
    // adrpo: I would like an assert here: size(nodes) <= size (roots)
    external "builtin";
    annotation(__OpenModelica_builtin=true);
  end uniqueRootIndices;

  function rooted
    external "builtin";
    annotation(__OpenModelica_builtin=true, Documentation(info="<html>
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

  annotation(__OpenModelica_builtin=true);
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
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
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

function spatialDistribution "Approximation of variable-speed transport of properties"
  input Real in0;
  input Real in1;
  input Real x;
  input Boolean positiveVelocity;
  parameter input Real initialPoints[:](each min = 0, each max = 1) = {0.0, 1.0} annotation(__OpenModelica_functionVariability=true);
  parameter input Real initialValues[size(initialPoints, 1)] = {0.0, 0.0} annotation(__OpenModelica_functionVariability=true);
  output Real out0;
  output Real out1;
external "builtin";
annotation(Documentation(info="<html>
spatialDistribution allows approximation of variable-speed transport of properties. For further details, see the Modelica Language Specification <a href=\"https://specification.modelica.org/maint/3.6/operators-and-expressions.html#spatialdistribution\">spatialdistribution()</a>.
</html>"), version="Modelica 3.3");
end spatialDistribution;

function previous<__ComponentExpression> "Access previous value of a clocked variable"
  input __ComponentExpression u;
  output __ComponentExpression y;
  external "builtin";
  annotation(__OpenModelica_builtin=true, version="Modelica 3.3", Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'previous()'\">previous()</a>
</html>"));
end previous;

function firstTick = $overload(OMC_NO_ARGS.firstTick, OMC_ARGS.firstTick)
   "Returns the interval between the previous and present tick of the clock of its argument"
  annotation(__OpenModelica_builtin=true, __OpenModelica_UnboxArguments=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'firstTick()'\">firstTick()</a>
</html>"));

function interval = $overload(OMC_NO_ARGS.interval, OMC_ARGS.interval)
   "Returns the interval between the previous and present tick of the clock of its argument"
  annotation(__OpenModelica_builtin=true, __OpenModelica_UnboxArguments=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'interval()'\">interval()</a>
</html>"));

package OMC_NO_ARGS
  impure function firstTick<T>
    "This operator returns true at the first tick of the clock of the expression, in which this operator is called. The operator returns false at all subsequent ticks of the clock. The optional argument u is only used for clock inference"
    output Boolean b;
    external "builtin";
    annotation(__OpenModelica_UnboxArguments=true, version="Modelica 3.3", Documentation(info="<html>
    See <a href=\"modelica://ModelicaReference.Operators.'firstTick()'\">firstTick()</a>
    </html>"));
  end firstTick;

  impure function interval<T>
    "This operator returns true at the first tick of the clock of the expression, in which this operator is called. The operator returns false at all subsequent ticks of the clock. The optional argument u is only used for clock inference"
    output Real b;
    external "builtin";
    annotation(__OpenModelica_UnboxArguments=true, version="Modelica 3.3", Documentation(info="<html>
    See <a href=\"modelica://ModelicaReference.Operators.'interval()'\">interval()</a>
    </html>"));
  end interval;
end OMC_NO_ARGS;

package OMC_ARGS
  impure function firstTick<T>
    "This operator returns true at the first tick of the clock of the expression, in which this operator is called. The operator returns false at all subsequent ticks of the clock. The optional argument u is only used for clock inference"
    input T u annotation(__OpenModelica_optionalArgument=true);
    output Boolean b;
    external "builtin";
    annotation(__OpenModelica_UnboxArguments=true, version="Modelica 3.3", Documentation(info="<html>
    See <a href=\"modelica://ModelicaReference.Operators.'firstTick()'\">firstTick()</a>
    </html>"));
  end firstTick;

  impure function interval<T>
    "This operator returns true at the first tick of the clock of the expression, in which this operator is called. The operator returns false at all subsequent ticks of the clock. The optional argument u is only used for clock inference"
    input T u annotation(__OpenModelica_optionalArgument=true);
    output Real b;
    external "builtin";
    annotation(__OpenModelica_UnboxArguments=true, version="Modelica 3.3", Documentation(info="<html>
    See <a href=\"modelica://ModelicaReference.Operators.'interval()'\">interval()</a>
    </html>"));
  end interval;
end OMC_ARGS;

function subSample = $overload(OpenModelica.Internal.subSampleExpression, OpenModelica.Internal.subSampleClock)
  "Conversion from faster clock to slower clock"
  annotation(__OpenModelica_builtin=true, version="Modelica 3.3", Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'subSample()'\">subSample()</a>
</html>"));

function superSample = $overload(OpenModelica.Internal.superSampleExpression, OpenModelica.Internal.superSampleClock)
  "Conversion from slower clock to faster clock"
  annotation(__OpenModelica_builtin=true, version="Modelica 3.3", Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'superSample()'\">superSample()</a>
</html>"));

function hold<__Any> "Conversion from clocked discrete-time to continuous time"
  input __Any u;
  output __Any y;
  external "builtin";
  annotation(__OpenModelica_builtin=true, version="Modelica 3.3", Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'hold()'\">hold()</a>
</html>"));
end hold;

function noClock<__Any> "Clock of y=Clock(u) is always inferred"
  input __Any u;
  output __Any y;
  external "builtin";
  annotation(__OpenModelica_builtin=true, version="Modelica 3.3", Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'noClock()'\">noClock()</a>
</html>"));
end noClock;

impure function ticksInState "Returns the number of clock ticks since a transition was made to the currently active state"
  output Integer ticks;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'ticksInState()'\">ticksInState()</a>
</html>"));
end ticksInState;

impure function timeInState "Returns the time duration as Real in [s] since a transition was made to the currently active state"
  output Real t;
  external "builtin";
  annotation(__OpenModelica_builtin=true, Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'ticksInState()'\">ticksInState()</a>
</html>"));
end timeInState;

/* Actually contains more...
record SimulationResult
  String resultFile;
  String simulationOptions;
  String messages;
end SimulationResult; */
encapsulated package OpenModelica "OpenModelica internal definitions and scripting functions"

package $Code
  "Code quoting is not a uniontype yet because that would require enabling MetaModelica
   extensions in the regular compiler. Besides, it has special semantics."

  type Expression
    "An expression of some kind"
    annotation(__OpenModelica_builtinType=true);
  end Expression;

  type ExpressionOrModification
    "An expression or modification of some kind"
    annotation(__OpenModelica_builtinType=true);
  end ExpressionOrModification;

  type TypeName
    "A path, for example the name of a class, e.g. A.B.C or .A.B"
    annotation(__OpenModelica_builtinType=true);
  end TypeName;

  type VariableName
    "A variable name, e.g. a.b or a[1].b[3].c"
    annotation(__OpenModelica_builtinType=true);
  end VariableName;

  type VariableNames
    "An array of variable names, e.g. {a.b,a[1].b[3].c}, or a single VariableName"
    annotation(__OpenModelica_builtinType=true);
  end VariableNames;
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
    parameter input Integer resolution(min = 1) = 1 annotation(__OpenModelica_functionVariability=true);
    output Clock c;
    external "builtin";
  end rationalClock;

  function realClock
    input Real interval(unit="s", min = 0);
    output Clock c;
    external "builtin";
  end realClock;

  function booleanClock
    input Boolean condition;
    input Real startInterval = 0.0;
    output Clock c;
    external "builtin";
  end booleanClock;

  function solverClock
    input Clock c;
    input String solverMethod;
    output Clock clk;
    external "builtin";
  end solverClock;

  impure function subSampleExpression<__Any>
    input __Any u;
    parameter input Integer factor(min=0)=0 annotation(__OpenModelica_functionVariability=true);
    output __Any y;
    external "builtin" y=subSample(u,factor);
  end subSampleExpression;

  impure function subSampleClock
    input Clock u;
    parameter input Integer factor(min=0)=0 annotation(__OpenModelica_functionVariability=true);
    output Clock y;
    external "builtin" y=subSample(u,factor);
  end subSampleClock;

  impure function superSampleExpression<__Any>
    input __Any u;
    parameter input Integer factor(min=0)=0 annotation(__OpenModelica_functionVariability=true);
    output __Any y;
    external "builtin" y=superSample(u,factor);
  end superSampleExpression;

  impure function superSampleClock
    input Clock u;
    parameter input Integer factor(min=0)=0 annotation(__OpenModelica_functionVariability=true);
    output Clock y;
    external "builtin" y=superSample(u,factor);
  end superSampleClock;

  impure function delay2
    input Real expr;
    parameter input Real delayTime annotation(__OpenModelica_functionVariability=true);
    output Real value;
  algorithm
    value := delay3(expr, delayTime, delayTime);
    annotation(__OpenModelica_EarlyInline=true);
  end delay2;

  impure function delay3
    input Real expr, delayTime;
    parameter input Real delayMax annotation(__OpenModelica_functionVariability=true);
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

  /*
  function intMax
    input Integer i1;
    input Integer i2;
    output Integer i;
  algorithm
    i := if i1 > i2 then i1 else i2;
    annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
  end intMax;

  function realMax
    input Real r1;
    input Real r2;
    output Real r;
  algorithm
    r := if r1 > r2 then r1 else r2;
    annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
  end realMax;

  function boolMax
    input Boolean b1;
    input Boolean b2;
    output Boolean b;
  algorithm
    b := if b1 then b2 else b1;
    annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
  end boolMax;

  function enumMax<enumType>
    "Returns the smallest element of two enums.
    This will need special handling internaly"
    input enumType s1;
    input enumType s2;
    output enumType s;
    external "builtin" b = max(s1,s2);
    annotation(Documentation(info="<html>
    See <a href=\"modelica://ModelicaReference.Operators.'min()'\">min()</a>
  </html>"));
  end enumMax;
  */

  function scalarMax<ScalarBasicType> "Returns the largest element of two scalar basic types"
    input ScalarBasicType a;
    input ScalarBasicType b;
    output ScalarBasicType m;
    external "builtin" m = max(a, b);
    annotation(Documentation(info="<html>
    See <a href=\"modelica://ModelicaReference.Operators.'min()'\">min()</a>
  </html>"));
  end scalarMax;

  function arrayMax<ArrayType,ScalarBasicType> "Returns the largest element of a multidimenstional array"
    input ArrayType a;
    output ScalarBasicType b;
    external "builtin" b = max(a);
    annotation(Documentation(info="<html>
    See <a href=\"modelica://ModelicaReference.Operators.'min()'\">min()</a>
  </html>"));
  end arrayMax;

  function scalarMin<ScalarBasicType> "Returns the smallest element of two scalar basic types"
    input ScalarBasicType a;
    input ScalarBasicType b;
    output ScalarBasicType m;
    external "builtin" m = min(a, b);
    annotation(Documentation(info="<html>
    See <a href=\"modelica://ModelicaReference.Operators.'min()'\">min()</a>
  </html>"));
  end scalarMin;

  function arrayMin<ArrayType,ScalarBasicType> "Returns the smallest element of a multidimenstional array"
    input ArrayType a;
    output ScalarBasicType b;
    external "builtin" b = min(a);
    annotation(Documentation(info="<html>
    See <a href=\"modelica://ModelicaReference.Operators.'min()'\">min()</a>
  </html>"));
  end arrayMin;

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
  "Return type of checkSettings."
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
  "Internal definitions."

package Time
  "Time related functions."

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
  "Returns the time in seconds formatted as a string with four significant digits."
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
annotation(preferredView="text");
end readableTime;

function timerTick
  "Starts the internal timer with the given index."
  input Integer index;
external "builtin";
annotation(preferredView="text");
end timerTick;

function timerTock
  "Reads the internal timer with the given index."
  input Integer index;
  output Real elapsed;
external "builtin";
annotation(preferredView="text");
end timerTock;

function timerClear
  "Clears the internal timer with the given index."
  input Integer index;
external "builtin";
annotation(preferredView="text");
end timerClear;

end Time;

type FileType = enumeration(NoFile, RegularFile, Directory, SpecialFile) "Return type of stat.";

function stat
  "Display file status."
  input String name;
  output FileType fileType;
  external "C" fileType = OpenModelicaInternal_stat(name);
annotation(preferredView="text");
end stat;

end Internal;

function checkSettings
  "Display some diagnostics."
  output CheckSettingsResult result;
external "builtin";
annotation(preferredView="text");
end checkSettings;

function loadFile
  "Loads a Modelica file (*.mo)."
  input String fileName;
  input String encoding = "UTF-8";
  input Boolean uses = true;
  input Boolean notify = true "Give a notification of the libraries and versions that were loaded";
  input Boolean requireExactVersion = false "If the version is required to be exact, if there is a uses Modelica(version=\"3.2\"), Modelica 3.2.1 will not match it.";
  input Boolean allowWithin = true "Whether to allow the file to have a within-clause other than 'within;'.";
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

function loadFiles
  "Loads Modelica files (*.mo)."
  input String[:] fileNames;
  input String encoding = "UTF-8";
  input Integer numThreads = OpenModelica.Scripting.numProcessors();
  input Boolean uses = true;
  input Boolean notify = true "Give a notification of the libraries and versions that were loaded";
  input Boolean requireExactVersion = false "If the version is required to be exact, if there is a uses Modelica(version=\"3.2\"), Modelica 3.2.1 will not match it.";
  input Boolean allowWithin = true "Whether to allow the files to have a within-clause other than 'within;'.";
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end loadFiles;

function parseEncryptedPackage
  "Parses an encrypted package and returns the names of the parsed classes."
  input String fileName;
  input String workdir = "<default>" "The output directory for imported encrypted files. <default> will put the files to current working directory.";
  output TypeName names[:];
external "builtin";
annotation(preferredView="text");
end parseEncryptedPackage;

function loadEncryptedPackage
  "Loads an encrypted package."
  input String fileName;
  input String workdir = "<default>" "The output directory for imported encrypted files. <default> will put the files to current working directory.";
  input Boolean skipUnzip = false "Skips the unzip of .mol if true. In that case we expect the files are already extracted e.g., because of parseEncryptedPackage() call.";
  input Boolean uses = true;
  input Boolean notify = true "Give a notification of the libraries and versions that were loaded";
  input Boolean requireExactVersion = false "If the version is required to be exact, if there is a uses Modelica(version=\"3.2\"), Modelica 3.2.1 will not match it.";
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end loadEncryptedPackage;

function reloadClass
  "Reloads the file associated with the given loaded class."
  input TypeName name;
  input String encoding = "UTF-8";
  output Boolean success;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Given an existing, loaded class in the compiler, compare the time stamp of the loaded class with the time stamp (mtime) of the file it was loaded from. If these differ, parse the file and merge it with the AST.</p>
</html>"));
end reloadClass;

function loadString
  "Loads Modelica definitions from a string."
  input String data;
  input String filename = "<interactive>";
  input String encoding = "UTF-8" "Deprecated as *ALL* strings are now UTF-8 encoded";
  input Boolean merge = false "if merge is true the parsed AST is merged with the existing AST,
                               default to false which means that is replaced, not merged";
  input Boolean uses = true;
  input Boolean notify = true "Give a notification of the libraries and versions that were loaded";
  input Boolean requireExactVersion = false "If the version is required to be exact,
                                             if there is a uses Modelica(version=\"3.2\"),
                                             Modelica 3.2.1 will not match it.";
  output Boolean success;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
  <p>Parses the data and merges the resulting AST with the loaded AST. If a filename is given, it is used to provide error messages as if the string
was read from a file with the same name.</p>
  <p>When merge is true the classes cNew in the file will be merged with the already loaded classes cOld in the following way:
  <ol>
  <li>get all the inner class definitions from cOld that were loaded from a different file than itself</li>
  <li>append all elements from step 1 to class cNew public list</li>
  </ol>
  </p>
  <p>NOTE: Encoding is deprecated as *ALL* strings are now UTF-8 encoded.</p>
</html>"));
end loadString;

function loadClassContentString
  "Loads class elements from a string and inserts them into the given loaded class."
  input String data;
  input TypeName className;
  input Integer offsetX = 0;
  input Integer offsetY = 0;
  output Boolean success;
external "builtin";
annotation(preferredView="test",Documentation(info="<html>
<p>Loads class content from a string and inserts it into the given loaded class with an optional position offset for graphical annotations.
The existing class must be a long class definition, either normal or class
extends. The content is merged according to the following rules:</p>
<p>
<ul>
<li>public/protected sections: Merged with the last public/protected section if the protection is the same.</li>
<li>equation sections: Merged with the last equation section if it's the same type of equation section (normal/initial).</li>
<li>external declaration: The new declaration overwrites the old.</li>
<li>annotations: The new annotation is merged with the old.
</ul>
</p>
<p>
Any section not merged is added after the last section of the same type, or
where they would normally be placed if no such section exists (i.e.
public/protected first, then equations, etc).  </p>
<p>
Example:
<blockquote>
<pre>
loadClassContentString(\"
    Real y;
  equation
    y = x;
\", P.M);
</pre>
</blockquote>
</p>
<p>
If an offset is given it will be applied to the graphical annotations on the loaded content before it's merged into the class, for example Placement annotations on components.
</p>
</html>"));
end loadClassContentString;

function parseString
  "Parses a string containing Modelica definitions and returns the parsed classes."
  input String data;
  input String filename = "<interactive>";
  output TypeName names[:];
external "builtin";
annotation(preferredView="text");
end parseString;

function parseFile
  "Parses a Modelica file and returns the parsed classes."
  input String filename;
  input String encoding = "UTF-8";
  output TypeName names[:];
external "builtin";
annotation(preferredView="text");
end parseFile;

function loadFileInteractiveQualified
  "Loads a Modelica file and returns a list of the top-level classes that were loaded."
  input String filename;
  input String encoding = "UTF-8";
  output TypeName names[:];
external "builtin";
annotation(preferredView="text");
end loadFileInteractiveQualified;

function loadFileInteractive
  "Loads a Modelica file and returns a list of all loaded top-level classes."
  input String filename;
  input String encoding = "UTF-8";
  input Boolean uses = true;
  input Boolean notify = true "Give a notification of the libraries and versions that were loaded";
  input Boolean requireExactVersion = false "If the version is required to be exact, if there is a uses Modelica(version=\"3.2\"), Modelica 3.2.1 will not match it.";
  output TypeName names[:];
external "builtin";
annotation(preferredView="text");
end loadFileInteractive;

impure function system "Similar to system(3). Executes the given command in the system shell."
  input String callStr "String to call: sh -c $callStr";
  input String outputFile = "" "The output is redirected to this file (unless already done by callStr)";
  output Integer retval "Return value of the system call; usually 0 on success";
external "builtin";
annotation(__OpenModelica_Impure=true, preferredView="text");
end system;

impure function system_parallel "Similar to system(3). Executes the given commands in the system shell, in parallel if omc was compiled using OpenMP."
  input String callStr[:] "String to call: sh -c $callStr";
  input Integer numThreads = numProcessors();
  output Integer retval[:] "Return value of the system call; usually 0 on success";
external "builtin";
annotation(__OpenModelica_Impure=true, preferredView="text");
end system_parallel;

function saveAll "Saves the entire loaded AST to file."
  input String fileName;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end saveAll;

function help "Display the OpenModelica help text."
  input String topic = "topics";
  output String helpText;
external "builtin";
end help;

function clear "Clears loaded classes and user defined variables."
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end clear;

function clearProgram "Clears loaded classes."
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end clearProgram;

function clearVariables "Clears all user defined variables."
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end clearVariables;

function generateHeader
  "Generates header file for external MetaModelica functions."
  input String fileName;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end generateHeader;

function generateJuliaHeader
  "Generates a Julia header file for external MetaModelica functions."
  input String fileName;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end generateJuliaHeader;

function generateSeparateCode
  "Generates code for a MetaModelica package."
  input TypeName className;
  input Boolean cleanCache = false "If true, the cache is reset between each generated package. This conserves memory at the cost of speed.";
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html><p>Under construction.</p>
</html>"),preferredView="text");
end generateSeparateCode;

function generateSeparateCodeDependencies
  "Generates dependencies for a MetaModelica package."
  input String stampSuffix = ".c" "Suffix to add to dependencies (often .c.stamp)";
  output String [:] dependencies;
external "builtin";
annotation(Documentation(info="<html><p>Under construction.</p>
</html>"),preferredView="text");
end generateSeparateCodeDependencies;

function generateSeparateCodeDependenciesMakefile
  "Generates dependencies Makefile for a MetaModelica package."
  input String filename "The file to write the makefile to";
  input String directory = "" "The relative path of the generated files";
  input String suffix = ".c" "Often .stamp since we do not update all the files";
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html><p>Under construction.</p>
</html>"),preferredView="text");
end generateSeparateCodeDependenciesMakefile;

function getLinker
  "Returns the linker (LINK) used for simulation code."
  output String linker;
external "builtin";
annotation(preferredView="text");
end getLinker;

function setLinker
  "Sets the linker (LINK) used for simulation code."
  input String linker;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setLinker;

function getLinkerFlags
  "Returns the linker flags (LDFLAGS) used for simulation code."
  output String linkerFlags;
external "builtin";
annotation(preferredView="text");
end getLinkerFlags;

function setLinkerFlags
  "Sets the linker flags (LDFLAGS) used for simulation code."
  input String linkerFlags;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setLinkerFlags;

function getCompiler
  "Returns the C compiler (CC) used for simulation code."
  output String compiler;
external "builtin";
annotation(preferredView="text");
end getCompiler;

function setCompiler
  "Sets the C compiler (CC) used for simulation code."
  input String compiler;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setCompiler;

function getCFlags
  "Returns the C compiler flags (CFLAGS) used for simulation code."
  output String outString;
external "builtin";
annotation(Documentation(info="<html>
See <a href=\"modelica://OpenModelica.Scripting.setCFlags\">setCFlags()</a> for details.
</html>"),
  preferredView="text");
end getCFlags;

function setCFlags
  "Sets the C compiler flags (CFLAGS) used for simulation code."
  input String inString;
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
Sets the CFLAGS passed to the C compiler. Remember to add -fPIC if you are on a 64-bit platform. If you want to see the defaults before you modify this variable, check the output of <a href=\"modelica://OpenModelica.Scripting.getCFlags\">getCFlags()</a>. ${SIM_OR_DYNLOAD_OPT_LEVEL} can be used to get a default lower optimization level for dynamically loaded functions. And ${MODELICAUSERCFLAGS} is nice to add so you can easily modify the CFLAGS later by using an environment variable.
</html>"),
  preferredView="text");
end setCFlags;

function getCXXCompiler
  "Returns the C++ compiler (CXX) used for simulation code."
  output String compiler;
external "builtin";
annotation(preferredView="text");
end getCXXCompiler;

function setCXXCompiler
  "Sets the C++ compiler (CXX) used for simulation code."
  input String compiler;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setCXXCompiler;

function getSettings
  "Returns some settings."
  output String settings;
algorithm
  settings :=
    "Temp folder path: " + getTempDirectoryPath() + "\n" +
    "Installation folder: " + getInstallationDirectoryPath() + "\n" +
    "Modelica path: " + getModelicaPath() + "\n";
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end getSettings;

function setTempDirectoryPath
  "Sets the current user temporary directory location."
  input String tempDirectoryPath;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setTempDirectoryPath;

function getTempDirectoryPath
  "Returns the current user temporary directory location."
  output String tempDirectoryPath;
external "builtin";
annotation(preferredView="text");
end getTempDirectoryPath;

function getEnvironmentVar
  "Returns the value of the given environment variable."
  input String var;
  output String value "returns empty string on failure";
external "builtin";
annotation(preferredView="text");
end getEnvironmentVar;

function setEnvironmentVar
  "Sets the value of the given environment variable."
  input String var;
  input String value;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setEnvironmentVar;

function appendEnvironmentVar
  "Appends a variable to the environment variables list."
  input String var;
  input String value;
  output String result "returns \"error\" if the variable could not be appended";
algorithm
  result := if setEnvironmentVar(var,getEnvironmentVar(var)+value) then getEnvironmentVar(var) else "error";
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end appendEnvironmentVar;

function setInstallationDirectoryPath
  "Sets the OPENMODELICAHOME environment variable."
  input String installationDirectoryPath;
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
<p>Use this method instead of setEnvironmentVar.</p>
</html>"),
  preferredView="text");
end setInstallationDirectoryPath;

function getInstallationDirectoryPath
  "Returns the installation directory path."
  output String installationDirectoryPath;
external "builtin";
annotation(Documentation(info="<html>
<p>This returns OPENMODELICAHOME if it is set; on some platforms the default path is returned if it is not set.</p>
</html>"),
  preferredView="text");
end getInstallationDirectoryPath;

function setModelicaPath
  "Sets the Modelica library path."
  input String modelicaPath;
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
<p>Sets the OPENMODELICALIBRARY (MODELICAPATH in the language specification) environment variable in OpenModelica. See <a href=\"modelica://OpenModelica.Scripting.loadModel\">loadModel()</a> for a description of what the MODELICAPATH is used for.</p>
<p>Set it to empty string to clear it: setModelicaPath(\"\");</p>
</html>"),
  preferredView="text");
end setModelicaPath;

function getModelicaPath
  "Returns the Modelica library path."
  output String modelicaPath;
external "builtin";
annotation(Documentation(info="<html>
<p>The MODELICAPATH is a list of paths to search when trying to  <a href=\"modelica://OpenModelica.Scripting.loadModel\">load a library</a>. It is a string separated by colon (:) on all OSes except Windows, which uses semicolon (;).</p>
<p>To override the default path (<a href=\"modelica://OpenModelica.Scripting.getInstallationDirectoryPath\">OPENMODELICAHOME</a>/lib/omlibrary/:~/.openmodelica/libraries/), set the environment variable OPENMODELICALIBRARY=...</p>
<p>On Windows the HOME directory '~' is replaced by %APPDATA%</p>
</html>"),
  preferredView="text");
end getModelicaPath;

function getHomeDirectoryPath
  "Returns the path to the current user's HOME directory."
  output String homeDirectoryPath;
external "builtin";
annotation(preferredView="text");
end getHomeDirectoryPath;

function setCompilerFlags
  "Same as setCFlags."
  input String compilerFlags;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setCompilerFlags;

function enableNewInstantiation
  "Enables the new (default) instantiation."
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end enableNewInstantiation;

function disableNewInstantiation
  "Disables the new (default) instantiation."
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end disableNewInstantiation;

function setDebugFlags
  "Sets compiler debug flags."
  input String debugFlags;
  output Boolean success;
algorithm
  success := setCommandLineOptions("-d=" + debugFlags);
annotation(__OpenModelica_EarlyInline = true, Documentation(info="<html>
<p>Calling the compiler with <code>--help=debug</code> will list all debug flags and what they do. The flags are given as a comma separated string. Flags can be disabled by prefixing them with <code>-</code>.</p>
<p>Example input: <code>failtrace,-noevalfunc</code></p>
</html>"),
  preferredView="text");
end setDebugFlags;

function clearDebugFlags
  "Resets all debug flags to their default values."
  output Boolean success;
  external "builtin";
  annotation(preferredView="text");
end clearDebugFlags;

function setPreOptModules
  "Sets pre optimization modules for the backend."
  input String modules;
  output Boolean success;
algorithm
  success := setCommandLineOptions("--preOptModules=" + modules);
annotation(__OpenModelica_EarlyInline = true, Documentation(info="<html>
<p>Sets the optimization modules which are used before the matching and index reduction in the backend, given as a comma separated string. Call the compiler with <code>--help=optmodules</code> for more information about what modules are available.</p>
<p>Example input: <code>removeFinalParameters,removeSimpleEquations,expandDerOperator</code></p>
</html>"),
  preferredView="text");
end setPreOptModules;

function setCheapMatchingAlgorithm
  "Sets the cheap matching algorithm."
  input Integer matchingAlgorithm;
  output Boolean success;
algorithm
  success := setCommandLineOptions("--cheapmatchingAlgorithm=" + String(matchingAlgorithm));
annotation(__OpenModelica_EarlyInline = true, Documentation(info="<html>
<p>Sets the cheap matching algorithm used by the backend. Same as calling the compiler with the <code>--cheapmatchingAlgorithm</code> flag.</p>
<p>Example input: <code>3</code></p>
</html>"),
  preferredView="text");
end setCheapMatchingAlgorithm;

function getMatchingAlgorithm
  "Returns the currently used matching algorithm."
  output String selected;
  external "builtin";
end getMatchingAlgorithm;

function getAvailableMatchingAlgorithms
  "Returns the available matching algorithms."
  output String[:] allChoices;
  output String[:] allComments;
  external "builtin";
end getAvailableMatchingAlgorithms;

function setMatchingAlgorithm
  "Sets the matching algorithm."
  input String matchingAlgorithm;
  output Boolean success;
algorithm
  success := setCommandLineOptions("--matchingAlgorithm=" + matchingAlgorithm);
annotation(__OpenModelica_EarlyInline = true, Documentation(info="<html>
<p>Sets the matching algorithm used by the backend after the pre optimization modules. Call the compiler with <code>--help=optmodules</code> for more information about what algorithms are available.</p>
<p>Example input: <code>PFPlus</code></p>
</html>"),
  preferredView="text");
end setMatchingAlgorithm;

function getIndexReductionMethod
  "Returns the currently used index reduction method."
  output String selected;
  external "builtin";
end getIndexReductionMethod;

function getAvailableIndexReductionMethods
  "Returns the currently available index reduction methods."
  output String[:] allChoices;
  output String[:] allComments;
  external "builtin";
end getAvailableIndexReductionMethods;

function setIndexReductionMethod
  "Sets the index reduction method."
  input String method;
  output Boolean success;
algorithm
  success := setCommandLineOptions("--indexReductionMethod=" + method);
annotation(__OpenModelica_EarlyInline = true, Documentation(info="<html>
<p>Sets the index reduction method used by the backend after the pre optimization modules. Call the compiler with <code>--help=optmodules</code> for more information about what methods are available.</p>
<p>Example input: <code>dynamicStateSelection</code></p>
</html>"),
  preferredView="text");
end setIndexReductionMethod;

function setPostOptModules
  "Sets post optimization modules for the backend."
  input String modules;
  output Boolean success;
algorithm
  success := setCommandLineOptions("--postOptModules=" + modules);
annotation(__OpenModelica_EarlyInline = true, Documentation(info="<html>
<p>Sets the optimization modules which are used after the index reduction to optimize the system for simulation, given as a comma separated string. Call the compiler with <code>--help=optmodules</code> for more information about what methods are available.</p>
<p>Example input: <code>lateInline,inlineArrayEqn,removeSimpleEquations</code></p>
</html>"),
  preferredView="text");
end setPostOptModules;

function getTearingMethod
  "Returns the currently used tearing method."
  output String selected;
  external "builtin";
end getTearingMethod;

function getAvailableTearingMethods
  "Returns the available tearing methods."
  output String[:] allChoices;
  output String[:] allComments;
  external "builtin";
end getAvailableTearingMethods;

function setTearingMethod
  "Sets the tearing method used by the backend."
  input String tearingMethod;
  output Boolean success;
algorithm
  success := setCommandLineOptions("--tearingMethod=" + tearingMethod);
annotation(__OpenModelica_EarlyInline = true, Documentation(info="<html>
<p>Same as calling the compiler with the <code>--tearingMethod</code> flag.</p>
<p>Example input: <code>omcTearing</code></p>
</html>"),
  preferredView="text");
end setTearingMethod;

function setCommandLineOptions
  "Sets command line options for the compiler."
  input String options;
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
<p>Takes a space separated list of command line options as input, with the same format as when calling the compiler on the command line. Call the compiler with <code>--help</code> for a list of available options.</p>
<p>Example input: <code>--showErrorMessages -d=failtrace</code></p>
</html>"),
  preferredView="text");
end setCommandLineOptions;

function getCommandLineOptions
  "Returns all command line options who have non-default values as a list of strings."
  output String[:] flags;
external "builtin";
annotation(Documentation(info="<html>
<p>Example output: <code>{&quot;-d=failtrace&quot;, &quot;--showErrorMessages=true&quot;}</code>.</p>
</html>"),
  preferredView="text");
end getCommandLineOptions;

function getConfigFlagValidOptions
  "Returns the list of valid options for a string config flag, and the description strings for these options if available."
  input String flag;
  output String validOptions[:];
  output String mainDescription;
  output String descriptions[:];
external "builtin";
annotation(preferredView="text");
end getConfigFlagValidOptions;

function clearCommandLineOptions
  "Resets all command line options to their default values."
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end clearCommandLineOptions;

function getVersion
  "Returns the version of the compiler or a Modelica library."
  input TypeName cl = $TypeName(OpenModelica);
  output String version;
external "builtin";
annotation(Documentation(info="<html>
<p>Returns the version of the compiler if called without an argument, or the version of a loaded Modelica library if the name of the library is given as argument.</p>
</html>"),
  preferredView="text");
end getVersion;

function regularFileExists
  "Returns whether the given file exists or not."
  input String fileName;
  output Boolean exists;
external "builtin";
annotation(preferredView="text");
end regularFileExists;

function directoryExists
  "Returns whether the given directory exists or not."
  input String dirName;
  output Boolean exists;
external "builtin";
annotation(preferredView="text");
end directoryExists;

impure function stat
  "Returns status for a file."
  input String fileName;
  output Boolean success;
  output Real fileSize;
  output Real mtime;
external "builtin";
annotation(__OpenModelica_Impure=true, Documentation(info="<html>
<p>Like <a href=\"http://linux.die.net/man/2/stat\">stat(2)</a>, except the output is of type real because of limited precision of Integer.</p>
</html>"),
  preferredView="text");
end stat;

impure function readFile
  "Returns the contents of a file."
  input String fileName;
  output String contents;
external "builtin";
annotation(__OpenModelica_Impure=true, Documentation(info="<html>
<p>Returns the contents of a file as a string or an empty string if the file couldn't be read. If the file couldn't be read an error message is emitted which can be viewed with <a href=\"modelica://OpenModelica.Scripting.getErrorString\">getErrorString()</a>.</p>
</html>"),
  preferredView="text");
end readFile;

impure function writeFile
  "Writes data to a file."
  input String fileName;
  input String data;
  input Boolean append = false;
  output Boolean success;
external "builtin";
annotation(__OpenModelica_Impure=true, Documentation(info="<html>
<p>Returns true on success. If <code>append = true</code> the data is appended to the file, otherwise the file is overwritten with the new content.</p>
</html>"),
  preferredView="text");
end writeFile;

impure function compareFilesAndMove
  "Overwrites a file with another if they differ."
  input String newFile;
  input String oldFile;
  output Boolean success;
external "builtin";
annotation(__OpenModelica_Impure=true,Documentation(info="<html>
<p>Compares <i>newFile</i> and <i>oldFile</i>. If they differ, overwrite <i>oldFile</i> with <i>newFile</i></p>
<p>Basically: test -f ../oldFile && cmp newFile oldFile || mv newFile oldFile</p>
</html>"));
end compareFilesAndMove;

impure function compareFiles
  "Checks if two files are equal or not."
  input String file1;
  input String file2;
  output Boolean isEqual;
external "builtin";
annotation(__OpenModelica_Impure=true,Documentation(info="<html>
<p>Compares <i>file1</i> and <i>file2</i> and returns true if their content is equal, otherwise false.</p>
</html>"));
end compareFiles;

impure function alarm
  "Schedules an alarm signal for the process."
  input Integer seconds;
  output Integer previousSeconds;
external "builtin";
annotation(__OpenModelica_Impure=true,Library = {"omcruntime"},Documentation(info="<html>
<p>Like <a href=\"http://linux.die.net/man/2/alarm\">alarm(2)</a>.</p>
<p>Note that OpenModelica also sends SIGALRM to the process group when the alarm is triggered (in order to kill running simulations).</p>
</html>"));
end alarm;

function regex
  "Matches a string with a regular expression and returns the result."
  input String str;
  input String re;
  input Integer maxMatches = 1 "The maximum number of matches that will be returned";
  input Boolean extended = true "Use POSIX extended or regular syntax";
  input Boolean caseInsensitive = false;
  output Integer numMatches "-1 is an error, 0 means no match, else returns a number 1..maxMatches";
  output String matchedSubstrings[maxMatches] "unmatched strings are returned as empty";
external "C" numMatches = OpenModelica_regex(str,re,maxMatches,extended,caseInsensitive,matchedSubstrings);
annotation(Documentation(info="<html>
<p>Sets the error buffer and returns -1 if the regex does not compile.</p>

<p>The returned result is the same as POSIX regex():
<ul>
  <li>The first value is the complete matched string.</li>
  <li>The rest are the substrings that you wanted.</li>
</ul>
</p>
<p>For example:
<pre>regex(lorem,\" \\([A-Za-z]*\\) \\([A-Za-z]*\\) \",maxMatches=3)
  => {\" ipsum dolor \",\"ipsum\",\"dolor\"}</pre>
</p>
<p>This means if you have n groups, you want maxMatches=n+1.</p>
</html>"),
  preferredView="text");
end regex;

function regexBool
  "Returns true if the string matches the regular expression."
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
  "Converts a filename to a testsuite friendly one."
  input String path;
  output String fixed;
protected
  Integer i;
  String matches[4];
algorithm
  (i,matches) := regex(path, "^(.*/testsuite/)?(.*/build/)?(.*)",4);
  fixed := matches[i];
end testsuiteFriendlyName;

impure function getErrorString
  "Returns current error messages."
  input Boolean warningsAsErrors = false;
  output String errorString;
external "builtin";
annotation(preferredView="text", Documentation(info="<html>
<p>Returns a user-friendly string containing the errors stored in the buffer. With warningsAsErrors=true, it reports warnings as if they were errors.</p>
</html>"));
end getErrorString;

record SourceInfo
  "Record used to store source location information."
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
) "Enumeration used to indicate where an error comes from.";
type ErrorLevel = enumeration(internal,notification,warning,error) "Enumeration used to indicate error severeness.";

record ErrorMessage
  "Record used to store an error message."
  SourceInfo info;
  String message "After applying the individual arguments";
  ErrorKind kind;
  ErrorLevel level;
  Integer id "Internal ID of the error (just ignore this)";
annotation(preferredView="text");
end ErrorMessage;

function getMessagesStringInternal
  "Returns error messages in a machine-readable format."
  input Boolean unique = true;
  output ErrorMessage[:] messagesString;
external "builtin";
annotation(Documentation(info="<html>
<p>If <code>unique = true</code> (the default) only unique messages will be shown.</p>
</html>"),
  preferredView="text");
end getMessagesStringInternal;

function countMessages
  "Returns the number of buffered messages."
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

function echo
  "Turns interactive output on or off."
  input Boolean setEcho;
  output Boolean newEcho;
external "builtin";
annotation(Documentation(info="<html>
<p><code>echo(false)</code> turns off all output when executing interactive commands or a script, <code>echo(true)</code> turns it on again.<p>
</html>"),
  preferredView="text");
end echo;

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
  "Returns the vectorization limit used by the old frontend."
  output Integer vectorizationLimit;
external "builtin";
annotation(preferredView="text");
end getVectorizationLimit;

function setVectorizationLimit
  "Sets the vectorization limit used by the old frontend."
  input Integer vectorizationLimit;
  output Boolean success;
algorithm
  success := setCommandLineOptions("-v=" + String(vectorizationLimit));
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setVectorizationLimit;

function getDefaultOpenCLDevice
  "Returns the id for the default OpenCL device to be used."
  output Integer defdevid;
external "builtin";
annotation(preferredView="text");
end getDefaultOpenCLDevice;

function setDefaultOpenCLDevice
  "Sets the default OpenCL device to be used."
  input Integer defdevid;
  output Boolean success;
algorithm
  success := setCommandLineOptions("-o=" + String(defdevid));
annotation(__OpenModelica_EarlyInline = true, preferredView="text");
end setDefaultOpenCLDevice;

function setShowAnnotations
  "Sets the value of the --showAnnotations flag."
  input Boolean show;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setShowAnnotations;

function getShowAnnotations
  "Returns the value of the --showAnnotations flag."
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

function getAstAsCorbaString
  "Returns the AST in CORBA format."
  input String fileName = "<interactive>";
  output String result "returns the string if fileName is interactive; else it returns ok or error depending on if writing the file succeeded";
external "builtin";
annotation(Documentation(info="<html>
<p>Prints the whole AST on the CORBA format for records, e.g.:
<pre>
  record Absyn.PROGRAM
    classes = ...,
    within_ = ...,
  end Absyn.PROGRAM;
</pre>
</p>
</html>"),
  preferredView="text");
end getAstAsCorbaString;

function cd
  "Changes the working directory."
  input String newWorkingDirectory = "";
  output String workingDirectory;
external "builtin";
annotation(Documentation(info="<html>
<p>Changes the working directory to the given filesystem path (which may be either relative or absolute).
Returns the new working directory on success or a message on failure.</p>
<p>If the given path is the empty string, the function simply returns the current working directory.</p>
</html>"),
  preferredView="text");
end cd;

function mkdir
  "Creates a directory."
  input String newDirectory;
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
<p>Creates a directory for the given filesystem path (which may be either relative or absolute).
Returns true if the directory was created or already exists, otherwise false.</p>
</html>"),
  preferredView="text");
end mkdir;

function copy
  "Copies a file."
  input String source;
  input String destination;
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
<p>Copies the source file to the destination file. Returns true if the file was successfully copied, otherwise false.</p>
</html>"),
  preferredView="text");
end copy;

function remove
  "Removes a file or directory."
  input String path;
  output Boolean success "Returns true on success.";
external "builtin";
annotation(Documentation(info="<html>
<p>Removes the file or directory with the given filesystem path (which may be either relative or absolute).
Returns true if the file was successfully removed, otherwise false.</p>
</html>"),
  preferredView="text");
end remove;

function checkModel
  "Checks a model and returns the number of variables and equations."
  input TypeName className;
  output String result;
external "builtin";
annotation(preferredView="text");
end checkModel;

function checkAllModelsRecursive
  "Checks all models recursively and returns number of variables and equations."
  input TypeName className;
  input Boolean checkProtected = false "Checks also protected classes if true";
  output String result;
external "builtin";
annotation(preferredView="text");
end checkAllModelsRecursive;

function typeOf
  "Returns the type of an interactive variable."
  input VariableName variableName;
  output String result;
external "builtin";
annotation(preferredView="text");
end typeOf;

function instantiateModel
  "Instantiates a model and returns the flattened model."
  input TypeName className;
  output String result;
external "builtin";
annotation(preferredView="text");
end instantiateModel;

function generateCode
  "Generates code for a function."
  input TypeName className;
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
<p>The input is a function name for which C-code is generated and compiled into a dll/so.</p>
</html>"),
  preferredView="text");
end generateCode;

function loadModel
  "Loads a Modelica library."
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
<p>loadModel() begins by parsing the <a href=\"modelica://OpenModelica.Scripting.getModelicaPath\">getModelicaPath()</a> and looking for candidate packages to load in the given paths (separated by : or ; depending on OS).</p>
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

function deleteFile
  "Deletes a file with the given name."
  input String fileName;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end deleteFile;

function saveModel
  "Saves a loaded model to the given file."
  input String fileName;
  input TypeName className;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end saveModel;

function saveTotalModel
  "Saves a model and dependencies to a single file."
  input String fileName;
  input TypeName className;
  input Boolean stripAnnotations = false;
  input Boolean stripComments = false;
  input Boolean obfuscate = false;
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
<p>Save the <code>className</code> model in a single file, together with all the other classes
that it depends upon, directly and indirectly. This file can be later reloaded
with the <a href=\"modelica://OpenModelica.Scripting.loadFile\">loadFile()</a>
API function, which loads <code>className</code> and all the other needed
classes into memory.</p>
<p>This is useful to allow third parties to run a certain model (e.g. for
debugging) without worrying about all the library dependencies.</p>
<p>Please note that the resulting file is not a valid Modelica .mo file according
to the specification and cannot be loaded in OMEdit - it can only be
loaded with loadFile() or passing the file to the compiler on the command line.</p>
</html>"),
  preferredView="text");
end saveTotalModel;

function saveTotalModelDebug
  "Saves a model and dependencies to a single file using a heuristic."
  input String filename;
  input TypeName className;
  input Boolean stripAnnotations = false;
  input Boolean stripComments = false;
  input Boolean obfuscate = false;
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
<p>Saves the <code>className</code> model in a single file, together with all other classes
that it depends on.</p>
<p>This function uses a naive heuristic based on which identifiers are used and
might save things which are not actually used, and is meant to be used in cases
where the normal <a href=\"modelica://OpenModelica.Scripting.saveTotalModel\">saveTotalModel()</a> fails.</p>
</html>"),
  preferredView="text");
end saveTotalModelDebug;

function save
  "Saves a class to the file(s) it's defined in."
  input TypeName className;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end save;

function saveTotalSCode = saveTotalModel "Alias for saveTotalModel";

function translateGraphics
  "Translates old graphical annotations to Modelica standard annotations."
  input TypeName className;
  output String result;
external "builtin";
annotation(preferredView="text");
end translateGraphics;

function codeToString
  "Converts a $Code expression to a string."
  input $Code className;
  output String string;
external "builtin";
annotation(preferredView="text");
end codeToString;

function dumpXMLDAE
  "Outputs the DAE system corresponding to a specific model."
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
  "Gets conversion factors for two units."
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
  "Returns the list of derived units for the specified base unit."
  input String baseUnit;
  output String[:] derivedUnits;
external "builtin";
annotation(preferredView="text");
end getDerivedUnits;

function listVariables
  "Lists the names of the active variables in the scripting environment."
  output TypeName variables[:];
external "builtin";
annotation(preferredView="text");
end listVariables;

function strtok
  "Splits a string at the places given by the token."
  input String string;
  input String token;
  output String[:] strings;
external "builtin";
annotation(Documentation(info="<html>
<p>Splits a string at the places given by the token, for example:
<ul>
<li><code>strtok(\"abcbdef\",\"b\") => {\"a\",\"c\",\"def\"}</code></li>
<li><code>strtok(\"abcbdef\",\"cd\") => {\"ab\",\"ef\"}</code></li>
</ul>
</p>
<p>Note: strtok does not return empty tokens. To split a read file into lines, use <a href=\"modelica://OpenModelica.Scripting.stringSplit\">stringSplit</a> instead (splits only on character).</p>
</html>"),preferredView="text");
end strtok;

function stringSplit "Splits a string at the places given by the character"
  input String string;
  input String token "single character only";
  output String[:] strings;
external "builtin";
annotation(Documentation(info="<html>
<p>Splits the string at the places given by the character, for example:
<ul>
<li><code>stringSplit(\"abcbdef\",\"b\") => {\"a\",\"c\",\"def\"}</code></li>
</ul>
</p>
</html>"),preferredView="text");
end stringSplit;

function stringReplace
  "Replaces all occurrences of a token with another token in a string."
  input String str;
  input String source;
  input String target;
  output String res;
external "builtin";
annotation(preferredView="text");
end stringReplace;

function escapeXML
  "Replaces characters in a string with XML escape characters."
  input String inStr;
  output String outStr;
algorithm
  outStr := stringReplace(inStr, "&", "&amp;");
  outStr := stringReplace(outStr, "<", "&lt;");
  outStr := stringReplace(outStr, ">", "&gt;");
  outStr := stringReplace(outStr, "\"", "&quot;");
end escapeXML;

type ExportKind = enumeration(Absyn "Normal Absyn",SCode "Normal SCode",MetaModelicaInterface "A restricted MetaModelica package interface (protected parts are stripped)",Internal "True unparsing of the Absyn") "Enumeration used by list to configure the output.";

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
<p><code>list()</code> pretty-prints the whole of the loaded AST while <code>list(className)</code> lists a class and its children.
It keeps all annotations and comments intact but strips out any comments and normalizes white-space.</p>
<p><code>list(className,interfaceOnly=true)</code> works on functions and pretty-prints only the interface parts
(annotations and protected sections removed). String-comments on public variables are kept.</p>
<p>If the specified class does not exist (or is not a function when interfaceOnly is given), an
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

type DiffFormat = enumeration(plain "no deletions, no markup", color "terminal escape sequences", xml "XML tags") "Enumeration used by diffModelicaFileListings to configure the output format.";

function diffModelicaFileListings "Creates diffs of two strings corresponding to Modelica files"
  input String before;
  input String after;
  input DiffFormat diffFormat = DiffFormat.color;
  input Boolean failOnSemanticsChange = false "Defaults to returning after instead of hard fail";
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
  "Exports a model to a Figaro database."
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
  "Update bindings for a verification model."
  input TypeName path;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end inferBindings;

function generateVerificationScenarios
  "Generate scenarios for a verification model."
  input TypeName path;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end generateVerificationScenarios;

function rewriteBlockCall "Function for property modeling, transforms block calls into instantiations for a loaded model"
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
external "builtin" fullName = OpenModelicaInternal_fullPathName(name);
  annotation (Documentation(info="<html>
Return the canonicalized absolute pathname.
Similar to <a href=\"http://linux.die.net/man/3/realpath\">realpath(3)</a>, but with the safety of Modelica strings.
</html>"));
end realpath;

function uriToFilename
  "Converts a URI to a filename."
  input String uri;
  output String filename = "";
external "builtin" filename=OpenModelica_uriToFilename(uri);
annotation(Documentation(info="<html>
<p>Handles modelica:// and file:// URI's. The result is an absolute path on the local system.
modelica:// URI's are only handled if the class is already loaded.</p>
<p>Returns the empty string on failure.</p>
</html>"));
end uriToFilename;

function getLoadedLibraries
  "Returns the loaded libraries."
  output String [:,2] libraries;
external "builtin";
annotation(Documentation(info="<html>
Returns a list of names of libraries and their path on the system, for example:
<pre>{{\"Modelica\",\"/usr/lib/omlibrary/Modelica 3.2.1\"},{\"ModelicaServices\",\"/usr/lib/omlibrary/ModelicaServices 3.2.1\"}}</pre>
</html>"));
end getLoadedLibraries;

function solveLinearSystem
  "Solve A*X = B using dgesv."
  input Real[size(B,1),size(B,1)] A;
  input Real[:] B;
  output Real[size(B,1)] X;
  output Integer info;
external "builtin";
annotation(Documentation(info="<html>
<p>Returns for solver dgesv:
<ul>
<li>info>0: Singular for element i.</li>
<li>info<0: Bad input.</li>
</ul>
</p>
</html>"),
  preferredView="text");
end solveLinearSystem;

type StandardStream = enumeration(stdin,stdout,stderr) "Enumeration for standard streams.";
function reopenStandardStream
  "Changes which file is associated with a standard stream."
  input StandardStream _stream;
  input String filename;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end reopenStandardStream;

function importFMU
  "Imports a Functional Mockup Unit."
  input String filename "the fmu file name";
  input String workdir = "<default>" "The output directory for imported FMU files. <default> will put the files to current working directory.";
  input Integer loglevel = 3 "loglevel_nothing=0;loglevel_fatal=1;loglevel_error=2;loglevel_warning=3;loglevel_info=4;loglevel_verbose=5;loglevel_debug=6";
  input Boolean fullPath = false "When true the full output path is returned otherwise only the file name.";
  input Boolean debugLogging = false "When true the FMU's debug output is printed.";
  input Boolean generateInputConnectors = true "When true creates the input connector pins.";
  input Boolean generateOutputConnectors = true "When true creates the output connector pins.";
  input TypeName modelName = $TypeName(Default) "Name of the generated model. If default then the name is auto generated using FMU information.";
  output String generatedFileName "Returns the full path of the generated file.";
external "builtin";
annotation(Documentation(info="<html>
<p>Example command:
<pre>importFMU(\"A.fmu\");</pre>
</p>
</html>"),
  preferredView="text");
end importFMU;

function importFMUModelDescription "Imports modelDescription.xml"
  input String filename "the fmu file name";
  input String workdir = "<default>" "The output directory for imported FMU files. <default> will put the files to current working directory.";
  input Integer loglevel = 3 "loglevel_nothing=0;loglevel_fatal=1;loglevel_error=2;loglevel_warning=3;loglevel_info=4;loglevel_verbose=5;loglevel_debug=6";
  input Boolean fullPath = false "When true the full output path is returned otherwise only the file name.";
  input Boolean debugLogging = false "When true the FMU's debug output is printed.";
  input Boolean generateInputConnectors = true "When true creates the input connector pins.";
  input Boolean generateOutputConnectors = true "When true creates the output connector pins.";
  output String generatedFileName "Returns the full path of the generated file.";
external "builtin";
annotation(Documentation(info="<html>
<p>Example command:
<pre>importFMUModelDescription(\"A.xml\");</pre>
</p>
</html>"),
  preferredView="text");
end importFMUModelDescription;

function translateModelFMU
  "Deprecated: Translates a model into C code for a FMU without building it."
  input TypeName className "the class that should translated";
  input String version = "2.0" "FMU version, 1.0 or 2.0.";
  input String fmuType = "me" "FMU type, me (model exchange), cs (co-simulation), me_cs (both model exchange and co-simulation)";
  input String fileNamePrefix = "<default>" "fileNamePrefix. <default> = \"className\"";
  input String platforms[:] = {"static"} "The list of platforms to generate code for.
                                          \"dynamic\"=current platform, dynamically link the runtime.
                                          \"static\"=current platform, statically link everything.
                                          \"<cpu>-<vendor>-<os>\", host tripple, e.g. \"x86_64-linux-gnu\" or \"x86_64-w64-mingw32\".
                                          \"<cpu>-<vendor>-<os> docker run ghcr.io/openmodelica/crossbuild:v1.26.0-dev\" host tripple with OpenModelica supplied Docker image, e.g. \"x86_64-linux-gnu docker run ghcr.io/openmodelica/crossbuild:v1.26.0-dev\".
                                          \"<cpu>-<vendor>-<os> docker run <image>\" host tripple with Docker image, e.g. \"x86_64-linux-gnu docker run --pull=never multiarch/crossbuild\"";
  input Boolean includeResources = false "include Modelica based resources via loadResource or not";
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
<p><b>Deprecated: Use buildModelFMU instead.</b></p>
<p>The only required argument is the className, while all others have some default values.</p>
<p>Example command:
<pre>translateModelFMU(className, version=\"2.0\");</pre>
</p>
</html>"),
  preferredView="text", version="Deprecated");
end translateModelFMU;

function buildModelFMU
  "Translates a Modelica model into a Functional Mockup Unit."
  input TypeName className "the class that should translated";
  input String version = "2.0" "FMU version, 1.0 or 2.0.";
  input String fmuType = "me" "FMU type, me (model exchange), cs (co-simulation), me_cs (both model exchange and co-simulation)";
  input String fileNamePrefix = "<default>" "fileNamePrefix. <default> = \"className\"";
  input String platforms[:] = {"static"} "The list of platforms to generate code for.
                                          \"dynamic\"=current platform, dynamically link the runtime.
                                          \"static\"=current platform, statically link everything.
                                          \"<cpu>-<vendor>-<os>\", host tripple, e.g. \"x86_64-linux-gnu\" or \"x86_64-w64-mingw32\".
                                          \"<cpu>-<vendor>-<os> docker run ghcr.io/openmodelica/crossbuild:v1.26.0-dev\" host tripple with OpenModelica supplied Docker image, e.g. \"x86_64-linux-gnu docker run ghcr.io/openmodelica/crossbuild:v1.26.0-dev\".
                                          \"<cpu>-<vendor>-<os> docker run <image>\" host tripple with Docker image, e.g. \"x86_64-linux-gnu docker run --pull=never multiarch/crossbuild\"";
  input Boolean includeResources = false "Depreacted and no effect";
  output String generatedFileName "Returns the full path of the generated FMU.";
external "builtin";
annotation(Documentation(info="<html>
<p>The only required argument is the className, while all others have some default values.</p>
<p>Example command:
<pre>buildModelFMU(className, version=\"2.0\");</pre>
</p>
</html>"),
  preferredView="text");
end buildModelFMU;

function buildEncryptedPackage
  "Builds an encrypted package for a class."
  input TypeName className "the class that should encrypted";
  input Boolean encrypt = true;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end buildEncryptedPackage;

function simulate
  "Simulates a model."
  input TypeName className "the class that should simulated";
  input Real startTime = "<default>" "the start time of the simulation. <default> = 0.0";
  input Real stopTime = 1.0 "the stop time of the simulation. <default> = 1.0";
  input Integer numberOfIntervals = 500 "number of intervals in the result file. <default> = 500";
  input Real tolerance = 1e-6 "tolerance used by the integration method. <default> = 1e-6";
  input String method = "<default>" "integration method used for simulation. <default> = dassl";
  input String fileNamePrefix = "<default>" "fileNamePrefix. <default> = \"\"";
  input String options = "<default>" "options. <default> = \"\"";
  input String outputFormat = "mat" "Format for the result file. <default> = \"mat\"";
  input String variableFilter = ".*" "Only variables fully matching the regexp are stored in the result file. <default> = \".*\"";
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
annotation(Documentation(info="<html>
<p>Simulates a Modelica model by generating C code, building it and running the simulation executable.
 The only required argument is the className, while all others have some default values.</p>
<p><code>simulate(className, [startTime], [stopTime], [numberOfIntervals], [tolerance], [method], [fileNamePrefix], [options], [outputFormat], [variableFilter], [cflags], [simflags])</code></p>
<p>Example command:
<pre>simulate(A);</pre>
</p>
</html>"),
  preferredView="text");
end simulate;

function translateModel
  "Translates a modelica model into C code without building it."
  input TypeName className "the class that should be built";
  input Real startTime = "<default>" "the start time of the simulation. <default> = 0.0";
  input Real stopTime = 1.0 "the stop time of the simulation. <default> = 1.0";
  input Integer numberOfIntervals = 500 "number of intervals in the result file. <default> = 500";
  input Real tolerance = 1e-6 "tolerance used by the integration method. <default> = 1e-6";
  input String method = "<default>" "integration method used for simulation. <default> = dassl";
  input String fileNamePrefix = "<default>" "fileNamePrefix. <default> = \"\"";
  input String options = "<default>" "options. <default> = \"\"";
  input String outputFormat = "mat" "Format for the result file. <default> = \"mat\"";
  input String variableFilter = ".*" "Only variables fully matching the regexp are stored in the result file. <default> = \".*\"";
  input String cflags = "<default>" "cflags. <default> = \"\"";
  input String simflags = "<default>" "simflags. <default> = \"\"";
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end translateModel;

function buildModel
  "Translates a Modelica model into C code and builds a simulation executable."
  input TypeName className "the class that should be built";
  input Real startTime = "<default>" "the start time of the simulation. <default> = 0.0";
  input Real stopTime = 1.0 "the stop time of the simulation. <default> = 1.0";
  input Integer numberOfIntervals = 500 "number of intervals in the result file. <default> = 500";
  input Real tolerance = 1e-6 "tolerance used by the integration method. <default> = 1e-6";
  input String method = "<default>" "integration method used for simulation. <default> = dassl";
  input String fileNamePrefix = "<default>" "fileNamePrefix. <default> = \"\"";
  input String options = "<default>" "options. <default> = \"\"";
  input String outputFormat = "mat" "Format for the result file. <default> = \"mat\"";
  input String variableFilter = ".*" "Only variables fully matching the regexp are stored in the result file. <default> = \".*\"";
  input String cflags = "<default>" "cflags. <default> = \"\"";
  input String simflags = "<default>" "simflags. <default> = \"\"";
  output String[2] buildModelResults;
external "builtin";
annotation(Documentation(info="<html>
<p>Note that unlike <a href=\"modelica://OpenModelica.Scripting.simulate\">simulate()</a> this function only builds a simulation executable, it does not run it.
 The only required argument is the className, while all others have some default values.</p
<p>Returns the filenames for the generated simulation executable and the initialization file.</p>
<p><code>buildModel(className, [startTime], [stopTime], [numberOfIntervals], [tolerance], [method], [fileNamePrefix], [options], [outputFormat], [variableFilter], [cflags], [simflags])</code></p>
<p>Example command:
<pre>buildModel(A);</pre>
</p>
</html>"),
  preferredView="text");
end buildModel;

function buildLabel
  "Calls buildModel with the --generateLabeledSimCode flag enabled."
  input TypeName className "the class that should be built";
  input Real startTime = 0.0 "the start time of the simulation. <default> = 0.0";
  input Real stopTime = 1.0 "the stop time of the simulation. <default> = 1.0";
  input Integer numberOfIntervals = 500 "number of intervals in the result file. <default> = 500";
  input Real tolerance = 1e-6 "tolerance used by the integration method. <default> = 1e-6";
  input String method = "dassl" "integration method used for simulation. <default> = dassl";
  input String fileNamePrefix = "" "fileNamePrefix. <default> = \"\"";
  input String options = "" "options. <default> = \"\"";
  input String outputFormat = "mat" "Format for the result file. <default> = \"mat\"";
  input String variableFilter = ".*" "Only variables fully matching the regexp are stored in the result file. <default> = \".*\"";
  input String cflags = "" "cflags. <default> = \"\"";
  input String simflags = "" "simflags. <default> = \"\"";
  output String[2] buildModelResults;
external "builtin";
annotation(preferredView="text");
end buildLabel;

function reduceTerms
  "Calls buildModel with the --reduceTerms flag enabled."
  input TypeName className "the class that should be built";
  input Real startTime = 0.0 "the start time of the simulation. <default> = 0.0";
  input Real stopTime = 1.0 "the stop time of the simulation. <default> = 1.0";
  input Integer numberOfIntervals = 500 "number of intervals in the result file. <default> = 500";
  input Real tolerance = 1e-6 "tolerance used by the integration method. <default> = 1e-6";
  input String method = "dassl" "integration method used for simulation. <default> = dassl";
  input String fileNamePrefix = "" "fileNamePrefix. <default> = \"\"";
  input String options = "" "options. <default> = \"\"";
  input String outputFormat = "mat" "Format for the result file. <default> = \"mat\"";
  input String variableFilter = ".*" "Only variables fully matching the regexp are stored in the result file. <default> = \".*\"";
  input String cflags = "" "cflags. <default> = \"\"";
  input String simflags = "" "simflags. <default> = \"\"";
  input String labelstoCancel="";
  output String[2] buildModelResults;
external "builtin";
annotation(preferredView="text");
end reduceTerms;

function createModel
  "Creates a new empty model."
  input TypeName className;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end createModel;

function newModel
  "Creates a new empty model in the given package."
  input TypeName className;
  input TypeName withinPath;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end newModel;

function moveClass
  "Moves a class up or down in a package."
 input TypeName className "the class that should be moved";
 input Integer offset "Offset in the class list.";
 output Boolean result;
external "builtin";
annotation(Documentation(info="<html>
<p>Moves a class up or down depending on the given offset, where a positive offset
moves the class down and a negative offset up. The offset is truncated if the
resulting index is outside the class list.</p>
<p>It retains the visibility of the class by adding public/protected sections
when needed, and merges sections of the same type if the class is moved from a
section it was alone in.</p>
<p>Returns true if the move was successful, otherwise false.</p>
</html>"),
  preferredView="text");
end moveClass;

function moveClassToTop
  "Moves a class to the top of its enclosing class."
  input TypeName className;
  output Boolean result;
external "builtin";
annotation(Documentation(info="<html>
<p>Returns true if the move was successful, otherwise false.
</html>"),
  preferredView="text");
end moveClassToTop;

function moveClassToBottom
  "Moves a class to the bottom of its enclosing class."
  input TypeName className;
  output Boolean result;
external "builtin";
annotation(Documentation(info="<html>
<p>Returns true if the move was successful, otherwise false.
</html>"),
  preferredView="text");
end moveClassToBottom;

function copyClass
  "Copies a class within the same level."
  input TypeName className "the class that should be copied";
  input String newClassName "the name for new class";
  input TypeName withIn = $TypeName(__OpenModelica_TopLevel) "the within path for new class";
  output Boolean result;
external "builtin";
annotation(preferredView="text");
end copyClass;

function renameClass
  "Renames a class and updates references to it."
  input TypeName oldName "The path of the class to rename.";
  input TypeName newName "The new non-qualified name of the class.";
  output TypeName[:] result;
external "builtin";
annotation(Documentation(info="<html>
<p>Renames a class and updates references to it in the loaded classes. Returns a list of classes that were changed.</p>
</html>"),
  preferredView="text");
end renameClass;

function deleteClass
  "Unloads a class."
  input TypeName className;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end deleteClass;

function refactorClass
  "Updates old graphical annotations to Modelica standard ones in a class."
  input TypeName className;
  output String result;
external "builtin";
annotation(
  Documentation(info="<html>
</html>"),
  preferredView="text");
end refactorClass;

function linearize
  "Creates a model with symbolic linearization matrices."
  input TypeName className "the class that should simulated";
  input Real startTime = "<default>" "the start time of the simulation. <default> = 0.0";
  input Real stopTime = 1.0 "the stop time of the simulation. <default> = 1.0";
  input Integer numberOfIntervals = 500 "number of intervals in the result file. <default> = 500";
  input Real stepSize = 0.002 "step size that is used for the result file. <default> = 0.002";
  input Real tolerance = 1e-6 "tolerance used by the integration method. <default> = 1e-6";
  input String method = "<default>" "integration method used for simulation. <default> = dassl";
  input String fileNamePrefix = "<default>" "fileNamePrefix. <default> = \"\"";
  input Boolean storeInTemp = false "storeInTemp. <default> = false";
  input Boolean noClean = false "noClean. <default> = false";
  input String options = "<default>" "options. <default> = \"\"";
  input String outputFormat = "mat" "Format for the result file. <default> = \"mat\"";
  input String variableFilter = ".*" "Only variables fully matching the regexp are stored in the result file. <default> = \".*\"";
  input String cflags = "<default>" "cflags. <default> = \"\"";
  input String simflags = "<default>" "simflags. <default> = \"\"";
  output String linearizationResult;
external "builtin";
annotation(Documentation(info="<html>
<p>Creates a model with symbolic linearization matrices.</p>
<p>At stopTime the linearization matrices are evaluated and a modelica model is created.</p>
<p>The only required argument is the className, while all others have some default values.</p>
<h2>Usage:</h2>
<p><b>linearize</b>(<em>A</em>, stopTime=0.0);</p>
<p>Creates the file \"linear_A.mo\" that contains the linearized matrices at stopTime.</p>
</html>", revisions="<html>
<table>
<tr><th>Revision</th><th>Author</th><th>Comment</th></tr>
<tr><td>13421</td><td>wbraun</td><td>Added to omc</td></tr>
</table>
</html>"),preferredView="text");
end linearize;

function optimize
  "Generates an optimization executable for a Modelica/Optimica model and runs it."
  input TypeName className "the class that should simulated";
  input Real startTime = "<default>" "the start time of the simulation. <default> = 0.0";
  input Real stopTime = 1.0 "the stop time of the simulation. <default> = 1.0";
  input Integer numberOfIntervals = 500 "number of intervals in the result file. <default> = 500";
  input Real stepSize = 0.002 "step size that is used for the result file. <default> = 0.002";
  input Real tolerance = 1e-6 "tolerance used by the integration method. <default> = 1e-6";
  input String method = DAE.SCONST("optimization") "optimize a modelica/optimica model.";
  input String fileNamePrefix = "<default>" "fileNamePrefix. <default> = \"\"";
  input Boolean storeInTemp = false "storeInTemp. <default> = false";
  input Boolean noClean = false "noClean. <default> = false";
  input String options = "<default>" "options. <default> = \"\"";
  input String outputFormat = "mat" "Format for the result file. <default> = \"mat\"";
  input String variableFilter = ".*" "Only variables fully matching the regexp are stored in the result file. <default> = \".*\"";
  input String cflags = "<default>" "cflags. <default> = \"\"";
  input String simflags = "<default>" "simflags. <default> = \"\"";
  output String optimizationResults;
external "builtin";
annotation(Documentation(info="<html>
<p>Optimizes a Modelica/Optimica model by generating C code, building it and running the optimization executable.
 The only required argument is the className, while all others have some default values.</p>
<p>Example command:
<pre>optimize(A);</pre>
</p>
</html>"),
  preferredView="text");
end optimize;

function getSourceFile
  "Returns the filename of the class."
  input TypeName class_;
  output String filename "empty on failure";
external "builtin";
annotation(preferredView="text");
end getSourceFile;

function setSourceFile
  "Sets the filename for a class."
  input TypeName class_;
  input String filename;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setSourceFile;

function isShortDefinition
  "Returns true if the given class is defined as a short class."
  input TypeName class_;
  output Boolean isShortCls;
external "builtin";
annotation(preferredView="text");
end isShortDefinition;

function setClassComment
  "Sets a class comment."
  input TypeName class_;
  input String filename;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setClassComment;

function getIconAnnotation
  "Returns the Icon annotation for a given class."
  input TypeName className;
  output Expression result;
external "builtin";
annotation(preferredView="text");
end getIconAnnotation;

function getDiagramAnnotation
  "Returns the Diagram annotation for a given class."
  input TypeName className;
  output Expression result;
external "builtin";
annotation(preferredView="text");
end getDiagramAnnotation;

function refactorIconAnnotation
  "Updates an old Icon annotation to a Modelica standard one in the given class."
  input TypeName className;
  output Expression result;
external "builtin";
annotation(preferredView="text");
end refactorIconAnnotation;

function refactorDiagramAnnotation
  "Updates an old Diagram annotation to a Modelica standard one in the given class."
  input TypeName className;
  output Expression result;
external "builtin";
annotation(preferredView="text");
end refactorDiagramAnnotation;

function getClassNames
  "Returns the list of class names defined in the class."
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
  input Boolean qualified = false "Not implemented";
  input Boolean includePartial = false;
  input Boolean sort = false;
  output TypeName classNames[:];
external "builtin";
annotation(preferredView="text");
end getAllSubtypeOf;

function getReplaceableChoices
  "Returns all replaceable choices for a class with choicesAllMatching."
  input TypeName baseClass;
  input TypeName parentClass;
  input Boolean includePartial = false;
  input Boolean sort = false;
  output String choices[:, :];
external "builtin";
annotation(preferredView="text");
end getReplaceableChoices;

function plot
  "Displays a plot with selected variables using OMPlot."
  input VariableNames vars "The variables you want to plot";
  input Boolean externalWindow = false "Opens the plot in a new plot window";
  input String fileName = "<default>" "The filename containing the variables. <default> will read the last simulation result";
  input String title = "" "This text will be used as the diagram title.";
  input String grid = "simple" "Sets the grid for the plot i.e simple, detailed, none.";
  input Boolean logX = false "Determines whether or not the horizontal axis is logarithmically scaled.";
  input Boolean logY = false "Determines whether or not the vertical axis is logarithmically scaled.";
  input String xLabel = "time" "This text will be used as the horizontal label in the diagram.";
  input String yLabel = "" "This text will be used as the left vertical label in the diagram.";
  input Real xRange[2] = {0.0,0.0} "Determines the horizontal interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real yRange[2] = {0.0,0.0} "Determines the left vertical interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real curveWidth = 1.0 "Sets the width of the curve.";
  input Integer curveStyle = 1 "Sets the style of the curve. SolidLine=1, DashLine=2, DotLine=3, DashDotLine=4, DashDotDotLine=5, Sticks=6, Steps=7.";
  input String legendPosition = "top" "Sets the POSITION of the legend i.e left, right, top, bottom, none.";
  input String footer = "" "This text will be used as the diagram footer.";
  input Boolean autoScale = true "Use auto scale while plotting.";
  input Boolean forceOMPlot = false "if true launches OMPlot and doesn't call callback function even if it is defined.";
  input String yAxis = "L" "Sets the variable to be plotted on the left (L) or right (R) y-axis.";
  input String yLabelRight = "" "This text will be used as the right vertical label in the diagram.";
  input Real yRangeRight[2] = {0.0,0.0} "Determines the right vertical interval that is visible in the diagram. {0,0} will select a suitable range.";
  output Boolean success "Returns true on success";
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Returns true on success.</p>

<p>Example command sequences:</p>
<ul>
<li><code>simulate(A); plot({x,y,z});</code></li>
<li><code>simulate(A); plot(x, externalWindow=true);</code></li>
<li><code>simulate(A,fileNamePrefix=\"B\"); simulate(C); plot(z,fileName=\"B.mat\",legendPosition=none);</code></li>
</ul>
</html>"));
end plot;

function plotAll
  "Displays a plot with all variables using OMPlot."
  input Boolean externalWindow = false "Opens the plot in a new plot window";
  input String fileName = "<default>" "The filename containing the variables. <default> will read the last simulation result";
  input String title = "" "This text will be used as the diagram title.";
  input String grid = "simple" "Sets the grid for the plot i.e simple, detailed, none.";
  input Boolean logX = false "Determines whether or not the horizontal axis is logarithmically scaled.";
  input Boolean logY = false "Determines whether or not the vertical axis is logarithmically scaled.";
  input String xLabel = "time" "This text will be used as the horizontal label in the diagram.";
  input String yLabel = "" "This text will be used as the left vertical label in the diagram.";
  input Real xRange[2] = {0.0,0.0} "Determines the horizontal interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real yRange[2] = {0.0,0.0} "Determines the left vertical interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real curveWidth = 1.0 "Sets the width of the curve.";
  input Integer curveStyle = 1 "Sets the style of the curve. SolidLine=1, DashLine=2, DotLine=3, DashDotLine=4, DashDotDotLine=5, Sticks=6, Steps=7.";
  input String legendPosition = "top" "Sets the POSITION of the legend i.e left, right, top, bottom, none.";
  input String footer = "" "This text will be used as the diagram footer.";
  input Boolean autoScale = true "Use auto scale while plotting.";
  input Boolean forceOMPlot = false "if true launches OMPlot and doesn't call callback function even if it is defined.";
  input String yAxis = "L" "Sets the variable to be plotted on the left (L) or right (R) y-axis.";
  input String yLabelRight = "" "This text will be used as the right vertical label in the diagram.";
  input Real yRangeRight[2] = {0.0,0.0} "Determines the right vertical interval that is visible in the diagram. {0,0} will select a suitable range.";
  output Boolean success "Returns true on success";
external "builtin";
annotation(Documentation(info="<html>
<p>Works in the same way as plot(), but does not accept any variable names as input. Instead, all variables are part of the plot window.</p>
<p>Example command sequences:
<ul>
<li><code>simulate(A); plotAll();</code></li>
<li><code>simulate(A); plotAll(externalWindow=true);</code></li>
<li><code>simulate(A, fileNamePrefix=\"B\"); simulate(C); plotAll(x, fileName=\"B.mat\");</code></li>
</ul>
</p>
</html>"),
  preferredView="text");
end plotAll;

function plotParametric
  "Displays a parametric plot with two variables using OMPlot."
  input VariableName xVariable;
  input VariableName yVariable;
  input Boolean externalWindow = false "Opens the plot in a new plot window";
  input String fileName = "<default>" "The filename containing the variables. <default> will read the last simulation result";
  input String title = "" "This text will be used as the diagram title.";
  input String grid = "simple" "Sets the grid for the plot i.e simple, detailed, none.";
  input Boolean logX = false "Determines whether or not the horizontal axis is logarithmically scaled.";
  input Boolean logY = false "Determines whether or not the vertical axis is logarithmically scaled.";
  input String xLabel = "" "This text will be used as the horizontal label in the diagram.";
  input String yLabel = "" "This text will be used as the left vertical label in the diagram.";
  input Real xRange[2] = {0.0,0.0} "Determines the horizontal interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real yRange[2] = {0.0,0.0} "Determines the left vertical interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real curveWidth = 1.0 "Sets the width of the curve.";
  input Integer curveStyle = 1 "Sets the style of the curve. SolidLine=1, DashLine=2, DotLine=3, DashDotLine=4, DashDotDotLine=5, Sticks=6, Steps=7.";
  input String legendPosition = "top" "Sets the POSITION of the legend i.e left, right, top, bottom, none.";
  input String footer = "" "This text will be used as the diagram footer.";
  input Boolean autoScale = true "Use auto scale while plotting.";
  input Boolean forceOMPlot = false "if true launches OMPlot and doesn't call callback function even if it is defined.";
  input String yAxis = "L" "Sets the variable to be plotted on the left (L) or right (R) y-axis.";
  input String yLabelRight = "" "This text will be used as the right vertical label in the diagram.";
  input Real yRangeRight[2] = {0.0,0.0} "Determines the right vertical interval that is visible in the diagram. {0,0} will select a suitable range.";
  output Boolean success "Returns true on success";
external "builtin";
annotation(Documentation(info="<html>
<p>Returns true on success.</p>
<p>Example command sequences:
<ul>
<li><code>simulate(A); plotParametric(x,y);</code></li>
<li><code>simulate(A); plotParametric(x,y, externalWindow=true);</code></li>
</html>"),
  preferredView="text");
end plotParametric;

function readSimulationResult
  "Reads a result file, returning a matrix corresponding to the variables and size given."
  input String filename;
  input VariableNames variables "e.g. {a.b, a[1].b[3].c}, or a single VariableName";
  input Integer size = 0 "0=read any size... If the size is not the same as the result-file, this function fails";
  output Real result[:,:];
external "builtin";
annotation(preferredView="text");
end readSimulationResult;

function readSimulationResultSize
  "Returns the number of intervals that are present in the output file."
  input String fileName;
  output Integer sz;
external "builtin";
annotation(preferredView="text");
end readSimulationResultSize;

function readSimulationResultVars
  "Returns the variables in a simulation results file."
  input String fileName;
  input Boolean readParameters = true;
  input Boolean openmodelicaStyle = false;
  output String[:] vars;
external "builtin";
annotation(Documentation(info="<html>
<p>Takes a simulation results file and returns the variables stored in it. These names can be used with e.g. <a href=\"modelica://OpenModelica.Scripting.val\">val()</a> or <a href=\"modelica://OpenModelica.Scripting.plot\">plot()</a></p>
<p>If readParameters is true, parameter names are also returned.</p>
<p>If openmodelicaStyle is true, the stored variable names are converted to the canonical form used by OpenModelica variables (a.der(b) becomes der(a.b), and so on).</p>
</html>"),preferredView="text");
end readSimulationResultVars;

function filterSimulationResults
  "Creates a simulation results file with selected variables."
  input String inFile;
  input String outFile;
  input String[:] vars;
  input Integer numberOfIntervals = 0 "0=Do not resample";
  input Boolean removeDescription = false;
  input Boolean hintReadAllVars = true;
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
<p>Takes one simulation result and filters out the selected variables only, producing the output file.</p>
<p>If numberOfIntervals<>0, re-sample to that number of intervals, ignoring event points (might be changed in the future).</p>
<p>if removeDescription=true, the description matrix will contain 0-length strings, making the file smaller.</p>
<p>if hintReadAllVars=true, the whole mat-file will be read at once (this is faster but uses more memory if you only use few variables from the file). May cause a crash if there is not enough virtual memory.</p>
</html>",revisions="<html>
<table>
<tr><th>Revision</th><th>Author</th><th>Comment</th></tr>
<tr><td>1.13.0</td><td>sjoelund.se</td><td>Introduced removeDescription.</td></tr>
</table>
</html>"),preferredView="text");
end filterSimulationResults;

function compareSimulationResults
  "Compares simulation results."
  input String filename;
  input String reffilename;
  input String logfilename;
  input Real relTol = 0.01;
  input Real absTol = 0.0001;
  input String[:] vars = fill("",0);
  output String[:] result;
external "builtin";
annotation(preferredView="text", version="Deprecated");
end compareSimulationResults;

function deltaSimulationResults
  "Calculates the sum of absolute errors."
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

function diffSimulationResults
  "Compares simulation results."
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

function diffSimulationResultsHtml
  "Compares simulation results and generates an HTML report."
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

function checkTaskGraph
  "Checks if the given taskgraph has the same structure as the reference taskgraph and if all attributes are set correctly."
  input String filename;
  input String reffilename;
  output String[:] result;
external "builtin";
annotation(preferredView="text");
end checkTaskGraph;

function checkCodeGraph
  "Checks if the given taskgraph has the same structure as the graph described in the codefile."
  input String graphfile;
  input String codefile;
  output String[:] result;
external "builtin";
annotation(preferredView="text");
end checkCodeGraph;

function val
  "Return the value of a variable at a given time in the simulation results"
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

function closeSimulationResultFile
  "Closes the current simulation results file."
  output Boolean success;
external "builtin";
annotation(Documentation(info="<html>
Only needed by Windows. Windows cannot handle reading and writing to the same file from different processes.
To allow OMEdit to make successful simulation again on the same file we must close the file after reading the Simulation Result Variables.
</html>"),
  preferredView="text");
end closeSimulationResultFile;

function addClassAnnotation
  "Adds an annotation to a class."
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

function addComponent
  "Adds a component to the given class."
  input TypeName componentName;
  input TypeName typeName;
  input TypeName classPath;
  input Expression binding = $Expression(());
  input ExpressionOrModification modification = $Code(());
  input Expression comment = $Expression(());
  input Expression annotate = $Expression(());
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end addComponent;

function updateComponent
  "Updates an existing component."
  input TypeName componentName;
  input TypeName typeName;
  input TypeName classPath;
  input Expression binding = $Expression(());
  input ExpressionOrModification modification = $Code(());
  input Expression comment = $Expression(());
  input Expression annotate = $Expression(());
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end updateComponent;

function deleteComponent
  "Deletes a component from the given class."
  input TypeName componentName;
  input TypeName classPath;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end deleteComponent;

function renameComponent
  "Renames a component and updates references to it."
  input TypeName classPath;
  input VariableName oldName;
  input VariableName newName;
  output TypeName[:] result;
external "builtin";
annotation(
  Documentation(info="<html>
  Renames a component and updates references to it in the loaded classes. Returns a list of classes that were changed.
</html>"),
  preferredView="text");
end renameComponent;

function renameComponentInClass
  "Renames a component in a class."
  input TypeName classPath;
  input VariableName oldName;
  input VariableName newName;
  output TypeName[:] result;
external "builtin";
annotation(
  Documentation(info="<html>
  Renames a component only in the given class. Returns the name of the class if successful.
</html>"),
  preferredView="text");
end renameComponentInClass;

function getParameterNames
  "Returns the names of all parameters in a given class."
  input TypeName class_;
  output String[:] parameters;
external "builtin";
annotation(preferredView="text");
end getParameterNames;

function getParameterValue
  "Returns the value of a parameter of the class."
  input TypeName class_;
  input String parameterName;
  output String parameterValue;
external "builtin";
annotation(preferredView="text");
end getParameterValue;

function setParameterValue
  "Sets the binding equation of a component."
  input TypeName className;
  input TypeName variableName;
  input Expression value;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setParameterValue;

function getNthComponent
  "Returns the type, name, and description string of the n:th component in the given class."
  input TypeName className;
  input Integer n;
  output Expression result;
external "builtin";
annotation(preferredView="text");
end getNthComponent;

function getComponents
  "Returns information about the component in a given class."
  input TypeName className;
  input Boolean useQuotes = false;
external "builtin";
annotation(
  Documentation(info="<html>
<p>For each component the following information is returned in an array:
<ul>
<li>type</li>
<li>name</li>
<li>description string</li>
<li>public/protected</li>
<li>final prefix</li>
<li>flow prefix</li>
<li>stream prefix</li>
<li>replaceable prefix</li>
<li>variability (constant/parameter/discrete/unspecified)</li>
<li>inner/outer prefix</li>
<li>input/output prefix</li>
<li>array dimensions</li>
</ul>
</p>
</html>"),
  preferredView="text");
end getComponents;

function getElements
  "Returns information about the elements in a given class."
  input TypeName className;
  input Boolean useQuotes = false;
external "builtin";
annotation(
  Documentation(info="<html>
<p>For each component/short class definition the following information is returned in an array:
<ul>
<li>kind of element (co = component, cl = class)</li>
<li>class restriction</li>
<li>type</li>
<li>name</li>
<li>description string</li>
<li>public/protected</li>
<li>final prefix</li>
<li>flow prefix</li>
<li>stream prefix</li>
<li>replaceable prefix</li>
<li>variability (constant/parameter/discrete/unspecified)</li>
<li>inner/outer prefix</li>
<li>input/output prefix</li>
<li>constraining class</li>
<li>array dimensions</li>
</ul>
</p>
</html>"),
  preferredView="text");
end getElements;

function getElementsInfo
  "Returns information about the elements in a given class."
  input TypeName className;
  output Expression result;
external "builtin";
annotation(preferredView="text");
end getElementsInfo;

function getComponentModifierNames
  "Returns the list of class component modifiers."
  input TypeName class_;
  input String componentName;
  output String[:] modifiers;
external "builtin";
annotation(preferredView="text");
end getComponentModifierNames;

function getComponentModifierValue
  "Returns the binding equation of a component."
  input TypeName class_;
  input TypeName modifier;
  output String value;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns the modifier value (only the binding excluding submodifiers) of a component.</p>
<p>Example:
<pre>
  model A
    B b1(a1(p1=5,p2=4));
  end A;

  getComponentModifierValue(A,b1.a1.p1) => 5
  getComponentModifierValue(A,b1.a1.p2) => 4
</pre>
</p>
</p>
<p>See also <a href=\"modelica://OpenModelica.Scripting.getComponentModifierValues\">getComponentModifierValues()</a>.</p>
</html>"),
  preferredView="text");
end getComponentModifierValue;

function getComponentModifierValues
  "Returns the modifier for a component."
  input TypeName class_;
  input TypeName modifier;
  output String value;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns the modifier (including the submodfiers) for a component.</p>
<p>Example:
<pre>
  model A
    B b1(a1(p1=5,p2=4));
  end A;

  getComponentModifierValues(A,b1.a1) => (p1 = 5, p2 = 4)
</pre>
<p>See also <a href=\"modelica://OpenModelica.Scripting.getComponentModifierValue\">getComponentModifierValue()</a>.</p>
</html>"),
  preferredView="text");
end getComponentModifierValues;

function removeComponentModifiers
  "Removes the component modifiers."
  input TypeName class_;
  input String componentName;
  input Boolean keepRedeclares = false;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end removeComponentModifiers;

function getElementModifierNames
  "Returns the list of element (component or short class) modifiers in a class."
  input TypeName className;
  input String elementName;
  output String[:] modifiers;
external "builtin";
annotation(preferredView="text");
end getElementModifierNames;

function getExtendsModifierNames
  "Returns the names of the modifiers on an extends clause."
  input TypeName className;
  input TypeName extendsName;
  input Boolean useQuotes = false;
  output String modifiers;
external "builtin";
annotation(preferredView="text");
end getExtendsModifierNames;

function setComponentModifierValue = setElementModifierValue "Deprecated; alias for setElementModifierValue.";

function setElementModifierValue
  "Sets a modifier on an element in a class definition."
  input TypeName className;
  input TypeName elementName;
  input ExpressionOrModification modifier;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setElementModifierValue;

function getElementModifierValue
  "Returns the binding equation for an element."
  input TypeName className;
  input TypeName modifier;
  output String value;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns the modifier value (only the binding excluding submodifiers) of an element (component or short class).</p>
<p>Example:
<pre>
  model A
    B b1(a1(p1=5,p2=4));
    model X = Y(a1(p1=5,p2=4));
  end A;

  getElementModifierValue(A,b1.a1.p1) => 5
  getElementModifierValue(A,b1.a1.p2) => 4
  getElementModifierValue(A,X.a1.p1) => 5
  getElementModifierValue(A,X.a1.p2) => 4
</pre>
</p>
<p>See also <a href=\"modelica://OpenModelica.Scripting.getElementModifierValues\">getElementModifierValues()</a>.</p>
</html>"),
  preferredView="text");
end getElementModifierValue;

function getElementModifierValues
  "Returns the modifier for an element."
  input TypeName className;
  input TypeName modifier;
  output String value;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns the modifier value (including the submodifiers) of an element (component or short class).
<p>Example:
<pre>
  model A
    B b1(a1(p1=5,p2=4));
    model X = Y(a1(p1=5,p2=4));
  end A;

  getElementModifierValues(A,b1.a1) => (p1 = 5, p2 = 4)
  getElementModifierValues(A,X.a1) => (p1 = 5, p2 = 4)
</pre>
</p>
<p>See also <a href=\"modelica://OpenModelica.Scripting.getElementModifierValue\">getElementModifierValue()</a>.</p>
</html>"),
  preferredView="text");
end getElementModifierValues;

function removeElementModifiers
  "Removes the element (component or short class) modifiers."
  input TypeName className;
  input String componentName;
  input Boolean keepRedeclares = false;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end removeElementModifiers;

function getExtendsModifierValue
  "Returns the modifier value for a modifier on an extends clause."
  input TypeName className;
  input TypeName extendsName;
  input TypeName modifierName;
  output Expression result;
external "builtin";
annotation(preferredView="text");
end getExtendsModifierValue;

function setExtendsModifierValue
  "Sets a modifier on an element in an extends clause in a class."
  input TypeName className;
  input TypeName extendsName;
  input TypeName elementName;
  input ExpressionOrModification modifier;
  output Boolean success;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Example:
<pre>
package P
  model M
    extends A.B(a = 1.0, x(z = 2.0));
  end M;
end P;

setExtendsModifierValue(P.M, A.B, x.y, $Code((start = 3.0))) =>

package P
  model M
    extends A.B(a = 1.0, x(z = 2.0, y(start = 3.0)));
  end M;
end P;
</pre>
</p>
</html>"),
  preferredView="text");
end setExtendsModifierValue;

function setExtendsModifier
  "Sets a modifier on an extends clause in a class definition."
  input TypeName className;
  input TypeName extendsName;
  input ExpressionOrModification modifier;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setExtendsModifier;

function isExtendsModifierFinal
  "Returns whether a modifier on an extends clause is final or not."
  input TypeName className;
  input TypeName extendsName;
  input TypeName modifierName;
  output Boolean isFinal;
external "builtin";
annotation(preferredView="text");
end isExtendsModifierFinal;

function getComponentCount
  "Returns the number of components in a class."
  input TypeName classPath;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getComponentCount;

function getNthComponentAnnotation
  "Returns the annotation for the n:th component in the given class."
  input TypeName className;
  input Integer n;
  output Expression result;
external "builtin";
annotation(preferredView="text");
end getNthComponentAnnotation;

function getNthComponentModification
  "Returns the modification for the n:th component in the given class."
  input TypeName className;
  input Integer n;
  output ExpressionOrModification result[:];
external "builtin";
annotation(preferredView="text");
end getNthComponentModification;

function getNthComponentCondition
  "Returns the condition for the n:th component in the given class as a string."
  input TypeName className;
  input Integer n;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthComponentCondition;

function getElementAnnotation
  "Returns the annotation on a component or class element as a string."
  input TypeName elementName;
  output String annotationString;
external "builtin";
annotation(preferredView="text");
end getElementAnnotation;

function setElementAnnotation
  "Sets the annotation on a component or class element."
  input TypeName elementName;
  input ExpressionOrModification annotationMod;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setElementAnnotation;

function setElementType
  "Changes the type of a component or short class element."
  input TypeName elementName;
  input VariableName typeName;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setElementType;

function getInstantiatedParametersAndValues
  "Returns the top-level parameter names and values from the DAE."
  input TypeName cls;
  output String[:] values;
external "builtin";
annotation(preferredView="text");
end getInstantiatedParametersAndValues;

function getComponentAnnotations
  "Returns the annotations of the components in the given class."
  input TypeName className;
  output Expression result;
external "builtin";
annotation(preferredView="text");
end getComponentAnnotations;

function getElementAnnotations
  "Returns the annotations of the components and short class definitions in the given class."
  input TypeName className;
  output Expression result;
external "builtin";
annotation(preferredView="text");
end getElementAnnotations;

function removeExtendsModifiers
  "Removes the extends modifiers of a class."
  input TypeName className;
  input TypeName baseClassName;
  input Boolean keepRedeclares = false;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end removeExtendsModifiers;

function getComponentComment
  "Returns the comment on a component."
  input TypeName className;
  input TypeName componentName;
  output String comment;
external "builtin";
annotation(preferredView="text");
end getComponentComment;

function setComponentComment
  "Sets the comment on a component."
  input TypeName className;
  input TypeName componentName;
  input String comment;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setComponentComment;

function setComponentDimensions
  "Sets the array dimensions of a component."
  input TypeName className;
  input TypeName componentName;
  input Expression dimensions;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setComponentDimensions;

function setComponentProperties
  "Sets the properties of a component in a class."
  input TypeName className;
  input TypeName componentName;
  input Boolean[:] prefixArray;
  input String[1] variability;
  input Boolean[2] innerOuter;
  input String[1] direction;
  output Boolean success;
external "builtin";
annotation(
  Documentation(info="<html>
  <p>The prefixArray argument is an array of 4 or 5 values: <b>final</b>, <b>flow</b>, <b>stream</b> (optional), <b>protected</b>, <b>replaceable</b>.</p>
</html>"),
  preferredView="text");
end setComponentProperties;

function getNthConnector
  "Returns the name and type of the n:th public connector in the given class."
  input TypeName className;
  input Integer n;
  output Expression result;
external "builtin";
annotation(preferredView="text");
end getNthConnector;

function getNthConnectorIconAnnotation
  "Returns the Icon annotation from the type of the n:th public connector in the given class."
  input TypeName className;
  input Integer n;
  output Expression result;
external "builtin";
annotation(preferredView="text");
end getNthConnectorIconAnnotation;

function getConnectorCount
  "Returns the number of public connectors in the given class."
  input TypeName className;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getConnectorCount;

function addConnection
  "Adds a connection to the given class."
  input VariableName connector1;
  input VariableName connector2;
  input TypeName className;
  input Expression comment = $Expression(());
  input Expression annotate = $Expression(());
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end addConnection;

function deleteConnection
  "Deletes a connection in the given class."
  input VariableName connector1;
  input VariableName connector2;
  input TypeName className;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end deleteConnection;

function updateConnection
  "Updates the connection annotation in the class."
  input TypeName className;
  input String from;
  input String to;
  input ExpressionOrModification annotate;
  output Boolean result;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>See also <a href=\"modelica://OpenModelica.Scripting.updateConnectionNames\">updateConnectionNames()</a>.</p>
</html>"));
end updateConnection;

function updateConnectionAnnotation
  "Updates the connection annotation in the class."
  input TypeName className;
  input String from;
  input String to;
  input String annotate;
  output Boolean result;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>See also <a href=\"modelica://OpenModelica.Scripting.updateConnectionNames\">updateConnectionNames()</a>.</p>
</html>"));
end updateConnectionAnnotation;

function setConnectionComment
  "Sets the description string on a connect equation in the given class."
  input TypeName className;
  input VariableName connector1;
  input VariableName connector2;
  input String comment;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setConnectionComment;

function updateConnectionNames
  "Updates the connection connector names in the class."
  input TypeName className;
  input String from;
  input String to;
  input String fromNew;
  input String toNew;
  output Boolean result;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>See also <a href=\"modelica://OpenModelica.Scripting.updateConnection\">updateConnection()</a>.</p>
</html>"));
end updateConnectionNames;

function getConnectionCount
  "Counts the number of connect equation in a class."
  input TypeName className;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getConnectionCount;

function getNthConnection
  "Returns the n:th connection."
  input TypeName className;
  input Integer index;
  output String[:] result;
external "builtin";
annotation(Documentation(info="<html>
<p>Example command:
<pre>getNthConnection(A) => {\"from\", \"to\", \"comment\"}</pre>
</p>
</html>"),
  preferredView="text");
end getNthConnection;

function getNthConnectionAnnotation
  "Returns the annotation of the n:th connect clause in the class."
  input TypeName className;
  input Integer index;
  output Expression result;
external "builtin";
annotation(preferredView="text");
end getNthConnectionAnnotation;

function getConnectionList
  "Returns an list of all connect equations including those within loops"
  input TypeName className;
  output String[:,:] result;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Example:
<pre>{{\"connector1.lhs\",\"connector1.rhs\"}, {\"connector2.lhs\",\"connector2.rhs\"}}</pre>
</p>
</html>"),
  preferredView="text");
end getConnectionList;

function getAlgorithmCount
  "Counts the number of algorithm sections in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getAlgorithmCount;

function getNthAlgorithm
  "Returns the n:th algorithm section in a class."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthAlgorithm;

function getInitialAlgorithmCount
  "Counts the number of initial algorithm sections in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getInitialAlgorithmCount;

function getNthInitialAlgorithm
  "Returns the n:th initial algorithm section in a class."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthInitialAlgorithm;

function getAlgorithmItemsCount
  "Counts the number of algorithm statements in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getAlgorithmItemsCount;

function getNthAlgorithmItem
  "Returns the n:th algorithm statement in a class."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthAlgorithmItem;

function getInitialAlgorithmItemsCount
  "Counts the number of initial algorithm statements in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getInitialAlgorithmItemsCount;

function getNthInitialAlgorithmItem
  "Returns the n:th initial algorithm statement in a class."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthInitialAlgorithmItem;

function getEquationCount
  "Counts the number of equation sections in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getEquationCount;

function getNthEquation
  "Returns the n:th equation section in a class."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthEquation;

function getInitialEquationCount
  "Counts the number of initial equation sections in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getInitialEquationCount;

function getNthInitialEquation
  "Returns the n:th initial equation section in a class."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthInitialEquation;

function getEquationItemsCount
  "Counts the number of equations in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getEquationItemsCount;

function getNthEquationItem
  "Returns the n:th equation in a class."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthEquationItem;

function getInitialEquationItemsCount
  "Counts the number of initial equations in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getInitialEquationItemsCount;

function getNthInitialEquationItem
  "Returns the n:th initial equation in a class."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthInitialEquationItem;

function getAnnotationCount
  "Counts the number of annotation sections in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getAnnotationCount;

function getNthAnnotationString
  "Returns the n:th annotation section as string."
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthAnnotationString;

function getImportCount
  "Counts the number of import-clauses in a class."
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getImportCount;

function getMMfileTotalDependencies
  "Returns imports for a MetaModelica package."
  input String in_package_name;
  input String public_imports_dir;
  output String[:] total_pub_imports;
external "builtin";
annotation(preferredView="text");
end getMMfileTotalDependencies;

function getImportedNames
  "Returns the definition names of all import-clauses in a class."
  input TypeName class_;
  output String[:] out_public;
  output String[:] out_protected;
external "builtin";
annotation(preferredView="text");
end getImportedNames;

function getNthImport
  "Returns the n:th import-clause."
  input TypeName class_;
  input Integer index;
  output String out[3] "{\"Path\",\"Id\",\"Kind\"}";
external "builtin";
annotation(preferredView="text");
end getNthImport;

function iconv
  "Converts a string from one character encoding to another."
  input String string;
  input String from;
  input String to = "UTF-8";
  output String result;
external "builtin";
annotation(Documentation(info="<html>
<p>See man (3) iconv for more information.</p>
</html>"),
  preferredView="text");
end iconv;

function getDocumentationAnnotation
  "Returns the Documentation annotation defined in the class."
  input TypeName cl;
  output String out[3] "{info,revision,infoHeader}"; //TODO: Should be changed to have 2 outputs instead of an array of 2 Strings..."
external "builtin";
annotation(preferredView="text");
end getDocumentationAnnotation;

function setDocumentationAnnotation
  "Sets the Documentation annotation in a class."
  input TypeName class_;
  input String info = "";
  input String revisions = "";
  output Boolean bool;

  external "builtin";
annotation(preferredView = "text", Documentation(info = "<html>
<p>The existing Documentation annotation of the class is overwritten, so an empty argument for e.g. <code>revisions</code> means that an existing <code>revisions</code> annotation is removed.</p>
</html>"));
end setDocumentationAnnotation;

function getTimeStamp
  "Returns the timestamp for a class."
  input TypeName cl;
  output Real timeStamp;
  output String timeStampAsString;
external "builtin";
annotation(Documentation(info = "<html>
<p>The given class corresponds to a file (or a buffer), with a given last time this file was modified at the time of loading this file. The timestamp along with its String representation is returned.</p>
</html>"));
end getTimeStamp;

function stringTypeName
  "Constructs a TypeName from a string."
  input String str;
  output TypeName cl;
external "builtin";
annotation(Documentation(info = "<html>
<p>stringTypeName is used to make it simpler to create some functionality when scripting. The basic use case is calling functions like simulate when you do not know the name of the class a priori: <code>simulate(stringTypeName(readFile(\"someFile\")))</code>.</p>
</html>"),preferredView="text");
end stringTypeName;

function stringVariableName
  "Constructs a VariableName from a string."
  input String str;
  output VariableName cl;
external "builtin";
annotation(Documentation(info = "<html>
<p>stringVariableName is used to make it simpler to create some functionality when scripting. The basic use case is calling functions like val when you do not know the name of the variable a priori: <code>val(stringVariableName(readFile(\"someFile\")))</code>.</p>
</html>"),preferredView="text");
end stringVariableName;

function typeNameString
  "Converts a TypeName to a string."
  input TypeName cl;
  output String out;
external "builtin";
annotation(preferredView="text");
end typeNameString;

function typeNameStrings
  "Converts a TypeName to a list of strings."
  input TypeName cl;
  output String out[:];
external "builtin";
annotation(preferredView="text");
end typeNameStrings;

function getClassComment
  "Returns a class's comment."
  input TypeName cl;
  output String comment;
external "builtin";
annotation(preferredView="text");
end getClassComment;

function dirname
  "Returns the directory name of a file path."
  input String path;
  output String dirname;
external "builtin";
annotation(Documentation(info="<html>
<p>Similar to <a href=\"http://linux.die.net/man/3/dirname\">dirname(3)</a>, but with the safety of Modelica strings.</p>
</html>"),
  preferredView="text");
end dirname;

function basename
  "Returns the base name (file part) of a file path."
  input String path;
  output String basename;
external "builtin";
annotation(Documentation(info="<html>
<p>Similar to <a href=\"http://linux.die.net/man/3/basename\">basename(3)</a>, but with the safety of Modelica strings.</p>
</html>"),
  preferredView="text");
end basename;

function existClass
  "Returns whether the given class exists or not."
  input TypeName cl;
  output Boolean exists;
external "builtin";
annotation(preferredView="text");
end existClass;

function existModel = isModel "Returns whether the given model exists or not.";
function existPackage = isPackage "Returns whether the given package exists or not.";

function getClassRestriction
  "Returns the restriction of the given class."
  input TypeName cl;
  output String restriction;
external "builtin";
annotation(preferredView="text");
end getClassRestriction;

function isType
  "Checks if a given class is a type."
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isType;

function isPackage
  "Checks if a given class is a package."
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isPackage;

function isClass
  "Checks if a given class is a class."
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isClass;

function isRecord
  "Checks if a given class is a record."
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isRecord;

function isBlock
  "Checks if a given class is a block."
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isBlock;

function isFunction
  "Checks if a given class is a function."
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isFunction;

function isPartial
  "Checks if a given class is partial."
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isPartial;

function isReplaceable
  "Checks if a given element is replaceable."
  input TypeName element;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isReplaceable;

function isRedeclare
  "Checks if a given element is a redeclare element."
  input TypeName element;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isRedeclare;

function isModel
  "Checks if a given class is a model."
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isModel;

function isConnector
  "Checks if a given class is a connector or expandable connector."
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isConnector;

function isOptimization
  "Checks if a given class is an optimization."
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isOptimization;

function isEnumeration
  "Checks if a given class is an enumeration."
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isEnumeration;

function isOperator
  "Checks if a given class is an operator."
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isOperator;

function isOperatorRecord
  "Checks if a given class is an operator record."
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isOperatorRecord;

function isOperatorFunction
  "Checks if a given class is an operator function."
  input TypeName cl;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isOperatorFunction;

function isProtectedClass
  "Returns true if the given class c1 has class c2 as one of its protected class."
  input TypeName cl;
  input String c2;
  output Boolean b;
external "builtin";
annotation(preferredView="text");
end isProtectedClass;

function getBuiltinType
  "Returns the builtin type e.g Real, Integer, Boolean & String of the class."
  input TypeName cl;
  output String name;
external "builtin";
annotation(preferredView="text");
end getBuiltinType;

function isPrimitive
  "Checks if a type is primitive."
  input TypeName className;
  output Boolean result;
external "builtin";
annotation(preferredView="text");
end isPrimitive;

function isParameter
  "Checks whether a component in a class is a parameter."
  input TypeName componentName;
  input TypeName className;
  output Boolean result;
external "builtin";
annotation(preferredView="text");
end isParameter;

function isConstant
  "Checks if a component in a class is a constant."
  input TypeName componentName;
  input TypeName className;
  output Boolean result;
external "builtin";
annotation(preferredView="text");
end isConstant;

function isProtected
  "Checks if a component in a class is protected."
  input TypeName componentName;
  input TypeName className;
  output Boolean result;
external "builtin";
annotation(preferredView="text");
end isProtected;

function setInitXmlStartValue
  "Sets the start value for a variable in an initialization file."
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
annotation(Documentation(info="<html>
<p>Requires <code>xsltproc</code> from libxslt (included in the OpenModelica installer for Windows).</p>
</html>"),
  preferredView="text");
end setInitXmlStartValue;

function ngspicetoModelica
  "Converts ngspice netlist to Modelica code."
  input String netlistfileName;
  output Boolean success = false;
protected
  String command;
algorithm
  command := "python " + getInstallationDirectoryPath() + "/share/omc/scripts/ngspicetoModelica.py " + netlistfileName;
  success := 0 == system(command);
annotation(Documentation(info="<html>
<p>The Modelica file is created in the same directory as netlist file.</p>
</html>"),
  preferredView="text");
end ngspicetoModelica;

function getInheritanceCount
  "Returns the numbers of extends clauses in the given class."
  input TypeName className;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getInheritanceCount;

function getInheritedClasses
  "Returns the list of inherited classes in a class."
  input TypeName name;
  output TypeName inheritedClasses[:];
external "builtin";
annotation(preferredView="text");
end getInheritedClasses;

function getNthInheritedClass
  "Returns the name of the n:th inherited class in the given class."
  input TypeName className;
  input Integer n;
  output TypeName baseClass;
external "builtin";
annotation(preferredView="text");
end getNthInheritedClass;

function getNthInheritedClassIconMapAnnotation
  "Returns the IconMap annotation for the n:th inherited class in the given class."
  input TypeName className;
  input Integer n;
  output Expression result;
external "builtin";
annotation(preferredView="text");
end getNthInheritedClassIconMapAnnotation;

function getNthInheritedClassDiagramMapAnnotation
  "Returns the IconMap annotation for the n:th inherited class in the given class."
  input TypeName className;
  input Integer n;
  output Expression result;
external "builtin";
annotation(preferredView="text");
end getNthInheritedClassDiagramMapAnnotation;

function getComponentsTest
  "Returns an array of records with information about the components of the given class."
  input TypeName name;
  output Component[:] components;
  record Component
    String className "the type of the component";
    String name "the name of the component";
    String comment "the comment of the component";
    Boolean isProtected "true if component is protected";
    Boolean isFinal "true if component is final";
    Boolean isFlow "true if component is flow";
    Boolean isStream "true if component is stream";
    Boolean isReplaceable "true if component is replaceable";
    String variability "'constant', 'parameter', 'discrete', ''";
    String innerOuter "'inner', 'outer', ''";
    String inputOutput "'input', 'output', ''";
    String dimensions[:] "array with the dimensions of the component";
  end Component;
external "builtin";
annotation(preferredView="text");
end getComponentsTest;

function isExperiment
  "Checks if a class is an experiment."
  input TypeName name;
  output Boolean res;
external "builtin";
annotation(Documentation(info="<html>
<p>An experiment is defined as a non-partial model or block having annotation experiment(StopTime=...)</p>
</html>"),
  preferredView="text");
end isExperiment;

function getSimulationOptions
  "Returns the startTime, stopTime, tolerance, and interval based on the experiment annotation."
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
annotation(preferredView="text");
end getSimulationOptions;

function getAnnotationNamedModifiers
  "Returns the names of the modifiers in the given annotation."
  input TypeName className;
  input String annotationName;
  output String[:] modifierNames;
external "builtin";
annotation(Documentation(info="<html>
<p>Example:
<pre>
  model M
    annotation(experiment(StartTime = 1.0, StopTime = 2.0));
  end M;

  getAnnotationNamedModifiers(M, \"experiment\") => {\"StartTime\", \"StopTime\"}
</pre>
</p>
</html>"));
end getAnnotationNamedModifiers;

function getAnnotationModifierValue
  "Returns the value for a modifier in the given annotation."
  input TypeName className;
  input String annotationName;
  input String modifierName;
  output String modifierValue;
external "builtin";
annotation(Documentation(info="<html>
<p>Example:
<pre>
  model M
    annotation(experiment(StartTime = 1.0, StopTime = 2.0));
  end M;

  getAnnotationModifierValue(M, \"experiment\", \"StopTime\") => 2.0
</pre>
</p>
</html>"));
end getAnnotationModifierValue;

function classAnnotationExists
  "Checks if an annotation exists in a class."
  input TypeName className;
  input TypeName annotationName;
  output Boolean exists;
external "builtin";
annotation(Documentation(info="<html>
<p>Returns true if <b>className</b> has a class annotation called <b>annotationName</b>.</p>
</html>",revisions="<html>
<table>
<tr><th>Revision</th><th>Author</th><th>Comment</th></tr>
<tr><td>16311</td><td>sjoelund.se</td><td>Added to omc</td></tr>
</table>
</html>"));
end classAnnotationExists;

function getBooleanClassAnnotation
  "Checks if an annotation exists and returns its value"
  input TypeName className;
  input TypeName annotationName;
  output Boolean value;
external "builtin";
annotation(Documentation(info="<html>
<p>Returns the value of the class annotation <b>annotationName</b> of class <b>className</b>. If there is no such annotation, or if it is not true or false, this function fails.</p>
</html>",revisions="<html>
<table>
<tr><th>Revision</th><th>Author</th><th>Comment</th></tr>
<tr><td>16311</td><td>sjoelund.se</td><td>Added to omc</td></tr>
</table>
</html>"));
end getBooleanClassAnnotation;

function getNamedAnnotation
  "Returns the value of the annotation with the given name in the given class."
  input TypeName className;
  input TypeName annotationName;
  output Expression result;
external "builtin";
annotation(preferredView="text");
end getNamedAnnotation;

function extendsFrom
  "Returns true if the given class extends from the given base class."
  input TypeName className;
  input TypeName baseClassName;
  output Boolean res;
external "builtin";
annotation(preferredView="text");
end extendsFrom;

function loadModelica3D
  "Loads Modelica3D."
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
<p>This API call will load the modified ModelicaServices 3.2.1 so Modelica3D runs. You can also simply call <code>loadModel(ModelicaServices,{\"3.2.1 modelica3d\"});</code></p>
<p>You will also need to start an m3d backend to render the results. We hid them in $OPENMODELICAHOME/lib/omlibrary-modelica3d/osg-gtk/dbus-server.py (or blender2.59).</p>
<p>For more information and example models, visit the <a href=\"https://mlcontrol.uebb.tu-berlin.de/redmine/projects/modelica3d-public/wiki\">Modelica3D wiki</a>.</p>
 </html>"), preferredView="text");
end loadModelica3D;

function searchClassNames
  "Searches for a string in the loaded classes."
  input String searchText;
  input Boolean findInText = false;
  output TypeName classNames[:];
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns a list of classes whose name contains <code>searchText</code>. If <code>findInText = true</code> then classes whose text contains <code>searchText</code> is also returned.</p>
<p>Example command:
<pre>
  searchClassNames(\"ground\");
  searchClassNames(\"ground\", true);
</pre>
</p>
</html>"),
  preferredView="text");
end searchClassNames;

function getAvailableLibraries
  "Returns a list of all available libraries."
  output String[:] libraries;
external "builtin";
annotation(
  Documentation(info="<html>
  Looks for all libraries that are visible from the <a href=\"modelica://OpenModelica.Scripting.getModelicaPath\">getModelicaPath()</a>.
</html>"),
  preferredView="text");
end getAvailableLibraries;

function getAvailableLibraryVersions
  "Returns the installed versions of a library."
  input TypeName libraryName;
  output String[:] librariesAndVersions;
external "builtin";
annotation(preferredView="text");
end getAvailableLibraryVersions;

function installPackage
  "Installs a package."
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
  "Updates the package index."
  output Boolean result;
external "builtin";
annotation(
  Documentation(info="<html>
  Updates the package index from the internet.
  This adds new packages to be able to install or upgrade packages.
  To upgrade installed packages, call <a href=\"modelica://OpenModelica.Scripting.upgradeInstalledPackages\">upgradeInstalledPackages()</a>.
</html>"),
  preferredView="text");
end updatePackageIndex;

function getAvailablePackageVersions
  "Returns the versions that provide the requested version of the library."
  input TypeName pkg;
  input String version;
  output String[:] withoutConversion;
external "builtin";
annotation(preferredView="text");
end getAvailablePackageVersions;

function getAvailablePackageConversionsTo
  "Returns the versions that provide conversion to the requested version of the library."
  input TypeName pkg;
  input String version;
  output String[:] convertsTo;
external "builtin";
annotation(preferredView="text");
end getAvailablePackageConversionsTo;

function getAvailablePackageConversionsFrom
  "Returns the versions that provide conversion from the requested version of the library."
  input TypeName pkg;
  input String version;
  output String[:] convertsTo;
external "builtin";
annotation(preferredView="text");
end getAvailablePackageConversionsFrom;

function upgradeInstalledPackages
  "Upgrades installed packages."
  input Boolean installNewestVersions = true;
  output Boolean result;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Upgrades installed packages that have been registered by the package manager.
  To update the index, call <a href=\"modelica://OpenModelica.Scripting.updatePackageIndex\">updatePackageIndex()</a>.</p>
</html>"),
  preferredView="text");
end upgradeInstalledPackages;

function getUses
  "Returns the libraries used by a package."
  input TypeName pack;
  output String[:,:] uses;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns the libraries used by the package based on the uses-annotation, using the format: <code>{{\"Library1\",\"Version\"},{\"Library2\",\"Version\"}}</code>.</p>
</html>"),
  preferredView="text");
end getUses;

function getConversionsFromVersions
  "Returns the versions this library can convert from with and without conversions."
  input TypeName pack;
  output String[:] withoutConversion;
  output String[:] withConversion;
external "builtin";
annotation(preferredView="text");
end getConversionsFromVersions;

function getDerivedClassModifierNames
  "Returns a derived class's modifier names."
  input TypeName className;
  output String[:] modifierNames;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Example command:
<pre>
  type Resistance = Real(final quantity=\"Resistance\",final unit=\"Ohm\");
  getDerivedClassModifierNames(Resistance) => {\"quantity\",\"unit\"}
</pre>
</p>
</html>"),
  preferredView="text");
end getDerivedClassModifierNames;

function getDerivedClassModifierValue
  "Returns a derived class's modifier value."
  input TypeName className;
  input TypeName modifierName;
  output String modifierValue;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Example command:
<pre>
  type Resistance = Real(final quantity=\"Resistance\",final unit=\"Ohm\");
  getDerivedClassModifierValue(Resistance, unit); => \" = \"Ohm\"\"
  getDerivedClassModifierValue(Resistance, quantity); => \" = \"Resistance\"\"
</pre>
</p>
</html>"),
  preferredView="text");
end getDerivedClassModifierValue;

function generateEntryPoint
  "Generates an entry point for a MetaModelica program."
  input String fileName;
  input TypeName entryPoint;
  input String url = "https://trac.openmodelica.org/OpenModelica/newticket";
external "builtin";
annotation(Documentation(info="<html>
<p>Generates a main() function that calls the given MetaModelica entry point (assumed to have input list<String> and no outputs).</p>
</html>"),
  preferredView="text");
end generateEntryPoint;

function numProcessors
  "Returns the number of available processors or threads."
  output Integer result;
external "builtin";
annotation(Documentation(info="<html>
<p>Returns the number of processors (if compiled against hwloc) or hardware threads (if using sysconf) available to OpenModelica.</p>
</html>"),
  preferredView="text");
end numProcessors;

function runScriptParallel
  "Runs multiple scripts in parallel."
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
</html>"),
  preferredView="text");
end runScriptParallel;

function exit
  "Forces omc to quit with the given exit status."
  input Integer status;
external "builtin";
annotation(preferredView="text");
end exit;

function threadWorkFailed
  "Exits the current thread with a failure."
external "builtin";
annotation(
  Documentation(info="<html>
<p>(Experimental) Exits the current (<a href=\"modelica://OpenModelica.Scripting.runScriptParallel\">worker thread</a>) signalling a failure.</p>
</html>"));
end threadWorkFailed;

function getMemorySize
  "Returns the amount of system memory."
  output Real memory(unit="MiB");
external "builtin";
annotation(
  Documentation(info="<html>
<p>Retrieves the physical memory size available on the system in megabytes.</p>
</html>"),
  preferredView="text");
end getMemorySize;

function GC_gcollect_and_unmap
  "Forces the GC to collect and unmap memory."
external "builtin";
annotation(
  Documentation(info="<html>
<p>Forces GC to collect and unmap memory (we use it before we start and wait for memory-intensive tasks in child processes).</p>
</html>"),
  preferredView="text");
end GC_gcollect_and_unmap;

function GC_expand_hp
  "Forces the GC to expand the heap to accomodate more data."
  input Integer size;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end GC_expand_hp;

function GC_set_max_heap_size
  "Forces the GC to limit the maximum heap size."
  input Integer size;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end GC_set_max_heap_size;

record GC_PROFSTATS
  "Return type for GC_get_prof_stats."
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
  "Returns a record with the GC statistics."
  output GC_PROFSTATS gcStats;
external "builtin";
annotation(preferredView="text");
end GC_get_prof_stats;

function checkInterfaceOfPackages
  "Checks the interfaces of MetaModelica packages."
  input TypeName cl;
  input String dependencyMatrix[:,:];
  output Boolean success;
  external "builtin";
annotation(
  Documentation(info="<html>
<p>Verifies the __OpenModelica_Interface=str annotation of all loaded packages with respect to the given main class.</p>
<p>For each row in the dependencyMatrix, the first element is the name of a dependency type. The rest of the elements are the other accepted dependency types for this one (frontend can call frontend and util, for example). Empty entries are ignored (necessary in order to have a rectangular matrix).</p>
</html>"),
  preferredView="text");
end checkInterfaceOfPackages;

function sortStrings
  "Sorts a string array in ascending order."
  input String arr[:];
  output String sorted[:];
  external "builtin";
annotation(preferredView="text");
end sortStrings;

function getClassInformation
  "Returns information about a class."
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
  output String versionDate;
  output String versionBuild;
  output String dateModified;
  output String revisionId;
external "builtin";
annotation(
  Documentation(info="<html>
<p>The dimensions are returned as an array of strings. The string is the textual representation of the dimension (they are not evaluated to Integers).</p>
</html>"), preferredView="text");
end getClassInformation;

function getCrefInfo
  "Deprecated; use getClassInformation instead."
  input TypeName cl;
  output Expression[:] result;
external "builtin";
annotation(preferredView="text");
end getCrefInfo;

function getDefaultComponentName
  "Returns the default component name for a class."
  input TypeName cl;
  output String name;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns the default component name for a class as defined by the defaultComponentName annotation.</p>
</html>"), preferredView="text");
end getDefaultComponentName;

function getDefaultComponentPrefixes
  "Returns the default component prefixes for a class."
  input TypeName cl;
  output String prefixes;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns the default component prefixes for a class as defined by the defaultComponentPrefixes annotation.</p>
</html>"), preferredView="text");
end getDefaultComponentPrefixes;

function getShortDefinitionBaseClassInformation
  "Returns information about a short class definition."
  input TypeName className;
  output Expression result;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns information about a short class definition: the base class, flow prefix, stream prefix, variability, input/output prefix, and array dimensions.</p>
</html>"),
  preferredView="text");
end getShortDefinitionBaseClassInformation;

function getExternalFunctionSpecification
  "Returns information about a function's external specification."
  input TypeName functionName;
  output Expression result;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns information about the given function's external specification: language, output variable, external function name, arguments, annotations on the external declaration, and annotations on the function.</p>
</html>"),
  preferredView="text");
end getExternalFunctionSpecification;

function getEnumerationLiterals
  "Returns the literals for a given enumeration type."
  input TypeName className;
  output String[:] result;
external "builtin";
annotation(preferredView="text");
end getEnumerationLiterals;

function getTransitions
  "Returns list of transitions for the given class."
  input TypeName cl;
  output String[:,:] transitions;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Each transition item contains: from, to, condition, immediate, reset, synchronize, priority.</p>
</html>"), preferredView="text");
end getTransitions;

function addTransition
  "Adds a transition to a class."
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
annotation(preferredView="text");
end addTransition;

function deleteTransition
  "Deletes a transition from a class."
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
annotation(preferredView="text");
end deleteTransition;

function updateTransition
  "Updates a transition in a class."
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
annotation(preferredView="text");
end updateTransition;

function getInitialStates
  "Returns a list of initial states in a class."
  input TypeName cl;
  output String[:,:] initialStates;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Each initial state item contains 2 values i.e, state name and annotation.</p>
</html>"), preferredView="text");
end getInitialStates;

function addInitialState
  "Adds an initial state to a class."
  input TypeName cl;
  input String state;
  input ExpressionOrModification annotate;
  output Boolean bool;
external "builtin";
annotation(preferredView="text");
end addInitialState;

function deleteInitialState
  "Deletes an initial state in a class."
  input TypeName cl;
  input String state;
  output Boolean bool;
external "builtin";
annotation(preferredView="text");
end deleteInitialState;

function updateInitialState
  "Updates an initial state in a class."
  input TypeName cl;
  input String state;
  input ExpressionOrModification annotate;
  output Boolean bool;
external "builtin";
annotation(preferredView="text");
end updateInitialState;

function generateScriptingAPI
  "Generates the scripting API."
  input TypeName cl;
  input String name;
  output Boolean success;
  output String moFile;
  output String qtFile;
  output String qtHeader;
external "builtin";
annotation(
  Documentation(info="<html>
<p>Returns OpenModelica.Scripting API entry points for the classes that we can automatically generate entry points for.</p>
<p>The entry points are MetaModelica code calling CevalScript directly, and Qt/C++ code that calls the MetaModelica code.</p>
</html>"), preferredView="text");
end generateScriptingAPI;

function runConversionScript
  "Runs a conversion script on a selected package."
  input TypeName packageToConvert;
  input String scriptFile;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end runConversionScript;

function convertPackageToLibrary
  "Runs the conversion script for a library on a selected package."
  input TypeName packageToConvert;
  input TypeName library;
  input String libraryVersion;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end convertPackageToLibrary;

function getModelInstance
  "Dumps a model instance as a JSON string."
  input TypeName className;
  input String modifier = "";
  input Boolean prettyPrint = false;
  output String result;
external "builtin";
end getModelInstance;

function getModelInstanceAnnotation
  "Dumps the annotation of a model using the same JSON format as getModelInstance."
  input TypeName className;
  input String[:] filter = fill("", 0);
  input Boolean prettyPrint = false;
  output String result;
external "builtin";
annotation(
   Documentation(info="<html>
<p>Returns the whole annotation if the filter is empty, otherwise only the parts matching the filter.</p>
</html>"),
   preferredView="text");
end getModelInstanceAnnotation;

function modifierToJSON
  "Parses a modifier given as a string and dumps it as JSON."
  input String modifier;
  input Boolean prettyPrint = false;
  output String json;
external "builtin";
annotation(preferredView="text");
end modifierToJSON;

function storeAST
  "Stores the AST and returns an id that can be used to restore it with restoreAST."
  output Integer id;
external "builtin";
annotation(preferredView="text");
end storeAST;

function restoreAST
  "Restores an AST that was previously stored with storeAST."
  input Integer id;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end restoreAST;

function qualifyPath
  "Returns the fully qualified path for the given path in a class."
  input TypeName classPath;
  input TypeName path;
  output TypeName qualifiedPath;
external "builtin";
annotation(preferredView="text");
end qualifyPath;

function getDefinitions
  "Dumps the defined packages, classes, and optionally functions to a string."
  input Boolean addFunctions;
  output String result;
external "builtin";
annotation(preferredView="text",Documentation(info="<html>
<p>Used by org.openmodelica.corba.parser.DefinitionsCreator.</p>
</html>"));
end getDefinitions;

// OMSimulator API calls
type oms_system = enumeration(oms_system_none,oms_system_tlm, oms_system_wc,oms_system_sc) "OMSimulator enumeration for system type.";
type oms_causality = enumeration(oms_causality_input, oms_causality_output, oms_causality_parameter, oms_causality_bidir, oms_causality_undefined) "OMSimulator enumeration for casuality.";
type oms_signal_type = enumeration (oms_signal_type_real,
  oms_signal_type_integer,
  oms_signal_type_boolean,
  oms_signal_type_string,
  oms_signal_type_enum,
  oms_signal_type_bus) "OMSimulator enumeration for signal type.";

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
) "OMSimulator enumeration for solvers.";

type oms_tlm_domain = enumeration(
  oms_tlm_domain_input,
  oms_tlm_domain_output,
  oms_tlm_domain_mechanical,
  oms_tlm_domain_rotational,
  oms_tlm_domain_hydraulic,
  oms_tlm_domain_electric
) "OMSimulator enumeration for TLM domains.";

type oms_tlm_interpolation = enumeration(
  oms_tlm_no_interpolation,
  oms_tlm_coarse_grained,
  oms_tlm_fine_grained
) "OMSimulator enumeration for TLM interpolation methods.";

type oms_fault_type = enumeration (
  oms_fault_type_bias,      ///< y = y.$original + faultValue
  oms_fault_type_gain,      ///< y = y.$original * faultValue
  oms_fault_type_const      ///< y = faultValue
) "OMSimulator enumeration for fault types.";

function loadOMSimulator
  "Loads the OMSimulator DLL from the default path."
  output Integer status;
external "builtin";
annotation(preferredView="text");
end loadOMSimulator;

function unloadOMSimulator
  "Frees the OMSimulator instances."
  output Integer status;
external "builtin";
annotation(preferredView="text");
end unloadOMSimulator;

function oms_addBus
  "OMSimulator: Adds a bus to a given component."
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addBus;

function oms_addConnection
  "Adds a new connection between connectors A and B."
  input String crefA;
  input String crefB;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addConnection;

function oms_addConnector
  "Adds a connector to a given component."
  input String cref;
  input oms_causality causality;
  input oms_signal_type type_;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addConnector;

function oms_addConnectorToBus
  "Adds a connector to a bus."
  input String busCref;
  input String connectorCref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addConnectorToBus;

function oms_addConnectorToTLMBus
  "Adds a connector to a TLM bus."
  input String busCref;
  input String connectorCref;
  input String type_;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addConnectorToTLMBus;

function oms_addDynamicValueIndicator
  "Adds a dynamic value indicator."
  input String signal;
  input String lower;
  input String upper;
  input Real stepSize;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addDynamicValueIndicator;

function oms_addEventIndicator
  "Adds an event indicator."
  input String signal;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addEventIndicator;

function oms_addExternalModel
  "Adds an external model to a TLM system."
  input String cref;
  input String path;
  input String startscript;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addExternalModel;

function oms_addSignalsToResults
  "Adds all variables that match the given regex to the result file."
  input String cref;
  input String regex;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addSignalsToResults;

function oms_addStaticValueIndicator
  "Adds a static value indicator."
  input String signal;
  input Real lower;
  input Real upper;
  input Real stepSize;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addStaticValueIndicator;

function oms_addSubModel
  "Adds a component to a system."
  input String cref;
  input String fmuPath;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addSubModel;

function oms_addSystem
  "Adds a (sub-)system to a model or system."
  input String cref;
  input oms_system type_;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addSystem;

function oms_addTimeIndicator
  "Adds a time indicator."
  input String signal;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addTimeIndicator;

function oms_addTLMBus
  "Adds a TLM bus."
  input String cref;
  input oms_tlm_domain domain;
  input Integer dimensions;
  input oms_tlm_interpolation interpolation;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_addTLMBus;

function oms_addTLMConnection
  "Connects two TLM connectors."
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

function oms_compareSimulationResults
  "Compares a given signal in two result files."
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
  "Copies a system."
  input String source;
  input String target;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_copySystem;

function oms_delete
  "Deletes a connector, component, system, or model object."
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_delete;

function oms_deleteConnection
  "Deletes the connection between two connectors."
  input String crefA;
  input String crefB;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_deleteConnection;

function oms_deleteConnectorFromBus
  "Deletes a connector from a given bus."
  input String busCref;
  input String connectorCref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_deleteConnectorFromBus;

function oms_deleteConnectorFromTLMBus
  "Deletes a connector from a given TLM bus."
  input String busCref;
  input String connectorCref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_deleteConnectorFromTLMBus;

function oms_export
  "Exports a composite model to a SPP file."
  input String cref;
  input String filename;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_export;

function oms_exportDependencyGraphs
  "Exports the dependency graphs of a given model to dot files."
  input String cref;
  input String initialization;
  input String event;
  input String simulation;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_exportDependencyGraphs;

function oms_exportSnapshot
  "Lists the SSD representation of a given model, system, or component."
  input String cref;
  output String contents;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_exportSnapshot;

function oms_extractFMIKind
  "Extracts the FMI kind of a given FMU from the file system."
  input String filename;
  output Integer  kind;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_extractFMIKind;

function oms_getBoolean
  "Get boolean value of a given signal."
  input String cref;
  output Boolean  value;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getBoolean;

function oms_getFixedStepSize
  "Gets the fixed step size."
  input String cref;
  output Real stepSize;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getFixedStepSize;

function oms_getInteger
  "Get integer value of a given signal."
  input String cref;
  input Integer value;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getInteger;

function oms_getModelState
  "Gets the model state of the given model cref."
  input String cref;
  output Integer modelState;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getModelState;

function oms_getReal
  "Get real value."
  input String cref;
  output Real value;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getReal;

function oms_getSolver
  "Gets the selected solver method of the given system."
  input String cref;
  output Integer solver;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getSolver;

function oms_getStartTime
  "Gets the start time from the model."
  input String cref;
  output Real startTime;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getStartTime;

function oms_getStopTime
  "Gets the stop time from the model."
  input String cref;
  output Real stopTime;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getStopTime;

function oms_getSubModelPath
  "Returns the path of a given component."
  input String cref;
  output String path;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getSubModelPath;

function oms_getSystemType
  "Gets the type of a given system."
  input String cref;
  output Integer type_;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getSystemType;

function oms_getTolerance
  "Gets the tolerance of a given system or component."
  input String cref;
  output Real absoluteTolerance;
  output Real relativeTolerance;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getTolerance;

function oms_getVariableStepSize
  "Gets the step size parameters."
  input String cref;
  output Real initialStepSize;
  output Real minimumStepSize;
  output Real maximumStepSize;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_getVariableStepSize;

function oms_faultInjection
  "Defines a new fault injection block."
  input String signal;
  input oms_fault_type faultType;
  input Real faultValue;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_faultInjection;

function oms_importFile
  "Imports a composite model from a SSP file."
  input String filename;
  output String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_importFile;

function oms_importSnapshot
  "Loads a snapshot to restore a previous model state."
  input String cref;
  input String snapshot;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_importSnapshot;

function oms_initialize
  "Initializes a composite model."
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_initialize;

function oms_instantiate
  "Instantiates a given composite model."
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_instantiate;

function oms_list
  "Lists the SSD representation of a given model, system, or component."
  input String cref;
  output String contents;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_list;

function oms_listUnconnectedConnectors
  "Lists all unconnected connectors of a given system."
  input String cref;
  output String contents;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_listUnconnectedConnectors;

function oms_loadSnapshot
  "Loads a snapshot to restore a previous model state."
  input String cref;
  input String snapshot;
  output String newCref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_loadSnapshot;

function oms_newModel
  "Creates a new composite model."
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_newModel;

function oms_removeSignalsFromResults
  "Removes all variables that match the given regex from the result file."
  input String cref;
  input String regex;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_removeSignalsFromResults;

function oms_rename
  "Renames a model, system, or component."
  input String cref;
  input String newCref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_rename;

function oms_reset
  "Reset the composite model after a simulation run."
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_reset;

function oms_RunFile
  "Simulates a single FMU or SSP model."
  input String filename;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_RunFile;

function oms_setBoolean
  "Sets the value of a given boolean signal."
  input String cref;
  input Boolean value;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setBoolean;

function oms_setCommandLineOption
  "Sets special flags."
  input String cmd;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setCommandLineOption;

function oms_setFixedStepSize
  "Sets the fixed step size."
  input String cref;
  input Real stepSize;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setFixedStepSize;

function oms_setInteger
  "Sets the value of a given integer signal."
  input String cref;
  input Integer value;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setInteger;

function oms_setLogFile
  "Redirects logging output to file or std streams."
  input String filename;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setLogFile;

function oms_setLoggingInterval
  "Sets the logging interval of the simulation."
  input String cref;
  input Real loggingInterval;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setLoggingInterval;

function oms_setLoggingLevel
  "Enables/disables debug logging."
  input Integer logLevel;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setLoggingLevel;

function oms_setReal
  "Sets the value of a given real signal."
  input String cref;
  input Real value;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setReal;

function oms_setRealInputDerivative
  "Sets the first order derivative of a real input signal."
  input String cref;
  input Real value;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setRealInputDerivative;

function oms_setResultFile
  "Sets the result file of the simulation."
  input String cref;
  input String filename;
  input Integer bufferSize;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setResultFile;

function oms_setSignalFilter
  "Sets a signal filter."
  input String cref;
  input String regex;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setSignalFilter;

function oms_setSolver
  "Sets the solver method for the given system."
  input String cref;
  input oms_solver solver;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setSolver;

function oms_setStartTime
  "Sets the start time of the simulation."
  input String cref;
  input Real startTime;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setStartTime;

function oms_setStopTime
  "Sets the stop time of the simulation."
  input String cref;
  input Real stopTime;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setStopTime;

function oms_setTempDirectory
  "Sets new temp directory."
  input String newTempDir;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setTempDirectory;

function oms_setTLMPositionAndOrientation
  "Sets initial position and orientation for a TLM 3D interface."
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
  "Sets data for TLM socket communication."
  input String cref;
  input String address;
  input Integer managerPort;
  input Integer monitorPort;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setTLMSocketData;

function oms_setTolerance
  "Sets the tolerance for a given model or system."
  input String cref;
  input Real absoluteTolerance;
  input Real relativeTolerance;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setTolerance;

function oms_setVariableStepSize
  "Sets the step size parameters for methods with stepsize control."
  input String cref;
  input Real initialStepSize;
  input Real minimumStepSize;
  input Real maximumStepSize;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setVariableStepSize;

function oms_setWorkingDirectory
  "Sets a new working directory."
  input String newWorkingDir;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_setWorkingDirectory;

function oms_simulate
  "Simulates a composite model."
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_simulate;

function oms_stepUntil
  "Simulates a composite model until a given time value."
  input String cref;
  input Real stopTime;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_stepUntil;

function oms_terminate
  "Terminates a given composite model."
  input String cref;
  output Integer status;
external "builtin";
annotation(preferredView="text");
end oms_terminate;

function oms_getVersion
  "Returns the version of the OMSimulator."
  output String version;
external "builtin";
annotation(preferredView="text");
end oms_getVersion;

// end of OMSimulator API calls

package Experimental
  "Package with experimental features."

function relocateFunctions
  "Update symbols in the running program to ones defined in the given shared object."
  input String fileName;
  input String names[:,2];
  output Boolean success;
external "builtin";
annotation(
  Documentation(info="<html>
<p><strong>Highly experimental, requires OMC be compiled with special flags to use</strong>.</p>
<p>This will hot-swap the functions at run-time, enabling a smart build system to do some incremental compilation
(as long as the function interfaces are the same).</p>
</html>"), preferredView="text");
end relocateFunctions;

function toJulia
  "Translates Absyn to Julia."
  output String res;
external "builtin";
end toJulia;

function interactiveDumpAbsynToJL
  "Dumps the AST into a Julia representation."
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
      String operations[:] = fill("", 0) "Library usage conditions";
    end License;

    // TODO: Function Derivative Annotations

    // Inverse Function Annotation
    record inverse
    end inverse;

    // TODO: External Function Annotations

    // Annotation Choices for Modifications and Redeclarations
    record choices "Defines a suitable redeclaration or modifications of the element."
      Boolean checkBox = true "Display a checkbox to input the values false or true in the graphical user interface.";
      String choice[:] = fill("", 0) "the choices as an array of strings";
    end choices;

    Boolean choicesAllMatching "Specify whether to construct an automatic list of choices menu or not.";

    record derivative
      Integer order = 1;
      String noDerivative;
      String zeroDerivative;
    end derivative;

    String __OpenModelica_commandLineOptions "annotation(__OpenModelica_commandLineOptions = \"--matchingAlgorithm=BFSB --indexReductionMethod=dynamicStateSelection\");";

    record __OpenModelica_simulationFlags "annotation(__OpenModelica_simulationFlags(s = \"ida\", cpu = \"()\"));"
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
