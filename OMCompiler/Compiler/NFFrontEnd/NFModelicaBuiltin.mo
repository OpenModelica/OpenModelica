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
"Only the Internal package is defined here, the rest of the Scripting package will be copied
 from FrontEnd/ModelicaBuiltin.mo when loading it in FBuiltin.getInitialFunctions."

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
  external "C" fileType = OpenModelicaInternal_stat(name);
end stat;

end Internal;

end Scripting;

package UsersGuide
  "This package will be overwritten by the one in FrontEnd/ModelicaBuiltin.mo
   when loading it with FBuiltin.getInitialFunctions."
end UsersGuide;

package AutoCompletion
  "This package will be overwritten by the one in FrontEnd/ModelicaBuiltin.mo
   when loading it with FBuiltin.getInitialFunctions."
end AutoCompletion;

annotation(
  Documentation(revisions="<html>See <a href=\"modelica://OpenModelica.UsersGuide.ReleaseNotes\">ReleaseNotes</a></html>",
  __Dymola_DocumentationClass = true),
  preferredView="text");
end OpenModelica;
