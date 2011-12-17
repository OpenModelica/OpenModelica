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
  annotation(__OpenModelica_Impure = true);
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'initial()'\">initial()</a>
</html>"));
end initial;

function terminal
  output Boolean isTerminal;
  annotation(__OpenModelica_Impure = true);
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'terminal()'\">terminal()</a>
</html>"));
end terminal;

type AssertionLevel = enumeration(error, warning);

function assert
  input Boolean condition;
  input String message;
  input AssertionLevel level;
external "builtin";
end assert;

function constrain
  input Real i1;
  input Real i2;
  input Real i3;
  output Real o1;
external "builtin";
annotation(version="Dymola / MSL 1.6");
end constrain;

function sample
  parameter input Real start(fixed=false);
  parameter input Real interval(fixed=false);
  output Boolean isSample;
  annotation(__OpenModelica_Impure = true);
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'sample()'\">sample()</a>
</html>"));
end sample;

function ceil
  input Real x;
  output Real y;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'ceil()'\">ceil()</a>
</html>"));
end ceil;

function floor
  input Real x;
  output Real y;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'floor()'\">floor()</a>
</html>"));
end floor;

function integer
  input Real x;
  output Integer y;
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'integer()'\">integer()</a>
</html>"));
end integer;

function sqrt
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
external "builtin";
annotation(version="Modelica 3.2");
end homotopy;

function linspace
  input Real x1 "start";
  input Real x2 "end";
  input Integer n "number";
  output Real v[n];
annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'linspace()'\">linspace()</a>
</html>"));
algorithm
  assert(n >= 2, "linspace requires n>=2 but got " + String(n));
  v := {x1 + (x2-x1)*(i-1)/(n-1) for i in 1:n};
end linspace;

function div = overload(OpenModelica.Internal.intDiv,OpenModelica.Internal.realDiv)
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'div()'\">div()</a>
</html>"));

function mod = overload(OpenModelica.Internal.intMod,OpenModelica.Internal.realMod)
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'mod()'\">mod()</a>
</html>"));

function rem = overload(OpenModelica.Internal.intRem,OpenModelica.Internal.realRem)
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'rem()'\">rem()</a>
</html>"));

function abs = overload(OpenModelica.Internal.intAbs,OpenModelica.Internal.realAbs)
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'abs()'\">abs()</a>
</html>"));

function outerProduct = overload(OpenModelica.Internal.outerProductInt,OpenModelica.Internal.outerProductReal)
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'outerProduct()'\">outerProduct()</a>
</html>"));

function cross = overload(OpenModelica.Internal.crossInt,OpenModelica.Internal.crossReal)
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'cross()'\">cross()</a>
</html>"));

function skew = overload(OpenModelica.Internal.skewInt,OpenModelica.Internal.skewReal)
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'skew()'\">skew()</a>
</html>"));

// Dummy functions that can't be properly defined in Modelica, but used by
// SCodeFlatten to define which builtin functions exist (SCodeFlatten doesn't
// care how the functions are defined, only if they exist or not).

function delay
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

function symmetric
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'symmetric()'\">symmetric()</a>
</html>"));
end symmetric;

function smooth
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'smooth()'\">smooth()</a>
</html>"));
end smooth;

function diagonal
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'diagonal()'\">diagonal()</a>
</html>"));
end diagonal;

function cardinality
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

function zeros
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'zeros()'\">zeros()</a>
</html>"));
end zeros;

function ones
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'ones()'\">ones()</a>
</html>"));
end ones;

function fill
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'fill()'\">fill()</a>
</html>"));
end fill;

function noEvent
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'noEvent()'\">noEvent()</a>
</html>"));
end noEvent;

function pre
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'pre()'\">pre()</a>
</html>"));
end pre;

function change
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'change()'\">change()</a>
</html>"));
end change;

function reinit
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'reinit()'\">reinit()</a>
</html>"));
end reinit;

function ndims
  external "builtin";
  annotation(Documentation(info="<html>
  See <a href=\"modelica://ModelicaReference.Operators.'ndims()'\">ndims()</a>
</html>"));
end ndims;

function size
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
<pre><b>rooted</b>(<i>x</i>)</pre>
</blockquote>
<h4>Description</h4>
<p>The operator \"rooted\" was introduced to improve efficiency: 
A tool that constructs the graph with the Connections.branch/.root etc. 
built-in operators has to cut the graph in order to arrive at \"spanning trees\". 
If there is a statement \"Connections.branch(A,B)\", then \"rooted(A)\" returns <pre>true</pre>, 
if \"A\" is closer to the root of the spanning tree as \"B\". Otherwise <pre>false</pre> is returned. 
For the MultiBody library this allows to avoid unnecessary small linear systems of equations.
</p>
<h4>Known Bugs</h4>
<p>
OpenModelica, <pre><b>rooted</b>(x)</pre> always returns <pre>true</pre>.
See <a href=\"https://trac.modelica.org/Modelica/ticket/95\">rooted ticket in the Modelica Trac</a> for details.
</p>
</html>"),version="Dymola / MSL 3");
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

encapsulated package Connections
  function branch
    external "builtin";
  end branch;

  function root
    external "builtin";
  end root;

  function potentialRoot
    external "builtin";
  end potentialRoot;

  function isRoot
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
  annotation(__OpenModelica_Impure = true);
external "builtin";
annotation(version="OpenModelica extension");
end print;

function classDirectory "No clue what it does, used by MSL 2.2.1"
  output String str;
external "builtin";
annotation(version="Dymola extension");
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
If MyLib.Vehicle is simulated, the call of <pre>getInstanceName()</pre> might return:
  <pre>Vehicle.engine.controller</pre>
</p>
<p>
Outside of a model or block, the return value is not specified.
</p>

<h4>
OpenModelica specifics:
</h4>

<p>
When OpenModelica does not have a prefix (e.g. in functions or packages),
it returns the name of the model that is simulated suffixed by
<pre><Prefix.NOPRE()></pre>, e.g. <pre>Vehicle.<Prefix.NOPRE()></pre>.
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

encapsulated package OpenModelica "OpenModelica internal defintions and scripting functions are defined here."

type Code "Code quoting is not a uniontype yet because that would require enabling MetaModelica extensions in the regular compiler.
Besides, it has special semantics."

type TypeName "A path, for example the name of a class, e.g. A.B.C or .A.B" end TypeName;
type VariableName "A variable name, e.g. a.b or a[1].b[3].c" end VariableName;
type VariableNames "An array of variable names, e.g. {a.b,a[1].b[3].c}, or a single VariableName" end VariableNames;

end Code;

package Internal "Contains internal implementations, e.g. overloaded builtin functions"
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
  external "builtin" z=rem(x,y);
  annotation(preferredView="text");
  end intRem;

  function realRem
    input Real x;
    input Real y;
    output Real z;
  external "builtin" z=rem(x,y);
  annotation(preferredView="text");
  end realRem;

  function outerProductInt
    input Integer[:] v1;
    input Integer[:] v2;
    output Integer[size(v1,1),size(v2,1)] o;
    external "builtin" o=outerProduct(v1,v2);
  /* Not working due to problems with matrix and transpose :(
  algorithm
    o := matrix(v1) * transpose(matrix(v2));
  */
  annotation(preferredView="text");
  end outerProductInt;

  function outerProductReal
    input Real[:] v1;
    input Real[:] v2;
    output Real[size(v1,1),size(v2,1)] o;
    external "builtin" o=outerProduct(v1,v2);
  /* Not working due to problems with matrix and transpose :(
  algorithm
    o := matrix(v1) * transpose(matrix(v2));
  */
  annotation(preferredView="text");
  end outerProductReal;

  function crossInt
    input Integer[3] x;
    input Integer[3] y;
    output Integer[3] z;
    annotation(__OpenModelica_EarlyInline = true);
    external "builtin" cross(x,y,z);
  /* Not working due to problems with non-builtin overloaded functions
  algorithm
    z := { x[2]*y[3]-x[3]*y[2] , x[3]*y[1]-x[1]*y[3] , x[1]*y[2]-x[2]*y[1] };
  */
  annotation(preferredView="text");
  end crossInt;

  function crossReal
    input Real[3] x;
    input Real[3] y;
    output Real[3] z;
    annotation(__OpenModelica_EarlyInline = true);
    external "builtin" cross(x,y,z);
  /* Not working due to problems with non-builtin overloaded functions
  algorithm
    z := { x[2]*y[3]-x[3]*y[2] , x[3]*y[1]-x[1]*y[3] , x[1]*y[2]-x[2]*y[1] };
  */
  annotation(preferredView="text");
  end crossReal;

  function skewInt
    input Integer[3] x;
    output Integer[3,3] y;
    external "builtin" skew(x,y);
  annotation(preferredView="text");
  end skewInt;

  function skewReal
    input Real[3] x;
    output Real[3,3] y;
    external "builtin" skew(x,y);
  end skewReal;
annotation(preferredView="text");
end Internal;

package Scripting
  
import OpenModelica.Code.TypeName;
import OpenModelica.Code.VariableName;
import OpenModelica.Code.VariableNames;

record CheckSettingsResult
  String OPENMODELICAHOME,OPENMODELICALIBRARY,OMC_PATH;
  Boolean OMC_FOUND;
  String MODELICAUSERCFLAGS,WORKING_DIRECTORY;
  Boolean CREATE_FILE_WORKS,REMOVE_FILE_WORKS;
  String OS, SYSTEM_INFO,SENDDATALIBS,C_COMPILER;
  Boolean C_COMPILER_RESPONDING;
  String CONFIGURE_CMDLINE;
annotation(preferredView="text");
end CheckSettingsResult;

function checkSettings "Display some diagnostics"
  output CheckSettingsResult result;
external "builtin";
annotation(preferredView="text");
end checkSettings;

function loadFile "load file (*.mo) and merge it with the loaded AST"
  input String fileName;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end loadFile;
 
function loadString "Parses the data and merges the resulting AST with the
  loaded AST.
  If a filename is given, it is used to provide error-messages as if the string
was read in binary format from a file with the same name.
  The file is converted to UTF-8 from the given character set.
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
  output TypeName names[:];
external "builtin";
annotation(preferredView="text");
end parseFile;

function loadFileInteractiveQualified
  input String filename;
  output TypeName names[:];
external "builtin";
annotation(preferredView="text");
end loadFileInteractiveQualified;

function loadFileInteractive
  input String filename;
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

function saveAll "save the entire loaded AST to file"
  input String fileName;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end saveAll;

function help "display the OpenModelica help text"
  output String helpText;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  helpText := readFile(getInstallationDirectoryPath() + "/share/doc/omc/omc_helptext.txt");
annotation(preferredView="text");
end help;

function clear
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end clear;

function clearVariables
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end clearVariables;

function enableSendData
  input Boolean enabled;
  output Boolean success;
external "builtin";
end enableSendData;

function setDataPort
  input Integer port;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setDataPort;

function generateHeader
  input String fileName;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end generateHeader;

function generateSeparateCode
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end generateSeparateCode;

function setLinker
  input String linker;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setLinker;

function setLinkerFlags
  input String linkerFlags;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setLinkerFlags;

function setCompiler
  input String compiler;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setCompiler;

function setCXXCompiler
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
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  settings :=
    "Compile command: " + getCompileCommand() + "\n" +
    "Temp folder path: " + getTempDirectoryPath() + "\n" +
    "Installation folder: " + getInstallationDirectoryPath() + "\n" +
    "Modelica path: " + getModelicaPath() + "\n";
annotation(preferredView="text");
end getSettings;

function setTempDirectoryPath
  input String tempDirectoryPath;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setTempDirectoryPath;

function getTempDirectoryPath
  output String tempDirectoryPath;
external "builtin";
annotation(preferredView="text");
end getTempDirectoryPath;

function getEnvironmentVar
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

function appendEnvironmentVar
  input String var;
  input String value;
  output String result "returns \"error\" if the variable could not be appended";
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  result := if setEnvironmentVar(var,getEnvironmentVar(var)+value) then getEnvironmentVar(var) else "error";
annotation(preferredView="text");
end appendEnvironmentVar;
        
function setInstallationDirectoryPath "Sets the OPENMODELICAHOME environment variable. Use this method instead of setEnvironmentVar"
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
annotation(preferredView="text");
end setModelicaPath;

function getModelicaPath "The Modelica Library Path - MODELICAPATH in the language specification; OPENMODELICALIBRARY in OpenModelica."
  output String modelicaPath;
external "builtin";
annotation(preferredView="text");
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
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  success := setCommandLineOptions("+d=" + debugFlags);
annotation(preferredView="text");
end setDebugFlags;

function setPreOptModules "example input: removeFinalParameters,removeSimpleEquations,expandDerOperator"
  input String modules;
  output Boolean success;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  success := setCommandLineOptions("+preOptModules=" + modules);
annotation(preferredView="text");
end setPreOptModules;

function setPastOptModules "example input: lateInline,inlineArrayEqn,removeSimpleEquations"
  input String modules;
  output Boolean success;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  success := setCommandLineOptions("+pastOptModules=" + modules);
annotation(preferredView="text");
end setPastOptModules;

function setIndexReductionMethod "example input: dummyDerivative"
  input String method;
  output Boolean success;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  success := setCommandLineOptions("+indexReductionMethod=" + method);
annotation(preferredView="text");
end setIndexReductionMethod;

function setCommandLineOptions
  "The input is a regular command-line flag given to OMC, e.g. +d=failtrace or +g=MetaModelica"
  input String option;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setCommandLineOptions;

function getVersion
  "Returns the version of the Modelica compiler"
  input TypeName cl := $TypeName(OpenModelica);
  output String version;
external "builtin";
annotation(preferredView="text");
end getVersion;

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

function readFileShowLineNumbers "
  Prefixes each line in the file with <n>:, where n is the line number.
  Note: Scales O(n^2)"
  input String fileName;
  output String out;
protected
  String line;
  Integer num:=1;
algorithm
  out := "";
  for line in strtok(readFile(fileName),"\n") loop
    out := out + String(num) + ": " + line + "\n";
    num := num + 1;
  end for;
annotation(preferredView="text");
end readFileShowLineNumbers;

function readFilePostprocessLineDirective "
  Searches lines for the #modelicaLine directive. If it is found, all lines up
  until the next #modelicaLine or #endModelicaLine are put on a single file,
  following a #line linenumber \"filename\" line.
  This causes GCC to output an executable that we can set breakpoints in and
  debug.
  Note: You could use a stack to keep track of start/end of #modelicaLine and
  match them up. But this is not really desirable since that will cause extra
  breakpoints for the same line (you would get breakpoints before and after
  each case if you break on a match-expression, etc).
  "
  input String fileName;
  output String out;
protected
  constant String regexStart := "^ *..#modelicaLine";
  constant String regexEnd := "^ *..#endModelicaLine";
  constant String regexSplit := "^ *..#modelicaLine .([A-Za-z.]*):([0-9]*):[0-9]*-[0-9]*:[0-9]*...$";
  constant Integer numInRegex := 3;
  String str,line,currentModelicaFileName;
  Integer lineNumInOutputFile:=1,numMatches:=0;
  Boolean insideModelicaLine:=false;
  String splitLine[numInRegex] := {"","",""};
algorithm
  str := readFile(fileName);
  out := "";
  for line in strtok(str,"\n") loop
    (numMatches,splitLine) := regex(line,regexSplit,numInRegex);
    if numMatches == 3 then
      insideModelicaLine := true;
      out := out + "#line " + splitLine[3] + " \"" + splitLine[2] + "\"\n";
      lineNumInOutputFile := lineNumInOutputFile + 1;
    elseif regexBool(line,regexEnd) then
      insideModelicaLine := false;
      out := out + "\n" + "#line " + String(lineNumInOutputFile+1) + " \"" + fileName + "\"\n";
      lineNumInOutputFile := lineNumInOutputFile + 3;
    elseif insideModelicaLine then
      out := out + " " + line;
    else
      out := out + line + "\n";
      lineNumInOutputFile := lineNumInOutputFile + 1;
    end if;
  end for;
annotation(preferredView="text");
end readFilePostprocessLineDirective;

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
external "builtin";
annotation(preferredView="text");
end regex;

function regexBool "Returns true if the string matches the regular expression"
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

function getErrorString
  "[file.mo:n:n-n:n:b] Error: message"
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
  Integer lineStart,columnStart,lineEnd,columnEnd;
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

function clearMessages "Clears the error buffer"
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

function strictRMLCheck "Checks if any loaded function"
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

function getAnnotationVersion
  output String annotationVersion;
external "builtin";
annotation(preferredView="text");
end getAnnotationVersion;

function setAnnotationVersion
  input String annotationVersion;
  output Boolean success;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  success := setCommandLineOptions("+annotationVersion=" + annotationVersion);
annotation(preferredView="text");
end setAnnotationVersion;

function getNoSimplify
  output Boolean noSimplify;
external "builtin";
annotation(preferredView="text");
end getNoSimplify;

function setNoSimplify
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
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  success := setCommandLineOptions("+v=" + String(vectorizationLimit));
annotation(preferredView="text");
end setVectorizationLimit;

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

function setOrderConnections
  input Boolean orderConnections;
  output Boolean success;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  success := setCommandLineOptions("+orderConnections=" + String(orderConnections));
annotation(preferredView="text");
end setOrderConnections;

function getOrderConnections
  output Boolean orderConnections;
external "builtin";
annotation(preferredView="text");
end getOrderConnections;

function setLanguageStandard
  input String inVersion;
  output Boolean success;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  success := setCommandLineOptions("+std=" + inVersion);
annotation(preferredView="text");
end setLanguageStandard;

function getLanguageStandard
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
  if the given path is the empty string, the function simply returns the current working directory
  "
  input String newWorkingDirectory := "";
  output String workingDirectory;
external "builtin";
annotation(preferredView="text");
end cd;

function checkModel
  input TypeName className;
  output String result;
external "builtin";
annotation(preferredView="text");
end checkModel;

function checkAllModelsRecursive
  input TypeName className;
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

function instantiateModel
  input TypeName className;
  output String result;
external "builtin";
annotation(preferredView="text");
end instantiateModel;

function generateCode "The input is a function name for which C-code is generated and compiled into a dll/so"
  input TypeName className;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end generateCode;

function loadModel "Parses the getModelicaPath(), and finds the package to load.
If the input is Modelica.XXX, the complete Modelica AST is loaded.

Default priority is: no version name > highest main release > highest pre-release > lexical sort of others.
If none of the searched versions exist, false is returned and an error is added to the buffer.
"
  input TypeName className;
  input String[:] priorityVersion := {"default"};
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end loadModel;

function deleteFile "Deletes a file with the given name"
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
  input Code className;
  output String string;
external "builtin";
annotation(preferredView="text");
end codeToString;

function dumpXMLDAE
  input TypeName className;
  input String translationLevel := "flat";
  input Boolean addOriginalIncidenceMatrix := false;
  input Boolean addSolvingInfo := false;
  input Boolean addMathMLCode := false;
  input Boolean dumpResiduals := false;
  input String fileNamePrefix := "<default>" "this is the className in string form by default";
  input Boolean storeInTemp := false;
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
annotation(preferredView="text");
end stringReplace;

function list "Lists the contents of the given class, or all loaded classes"
  input TypeName class_ := $TypeName(AllLoadedClasses);
  output String contents;
external "builtin";
annotation(preferredView="text");
end list;

function uriToFilename "Handles modelica:// and file:// URI's. The result is an absolute path on the local system.
  The result depends on the current MODELICAPATH. Returns the empty string on failure."
  input String uri;
  output String filename;
external "builtin";
annotation(preferredView="text");
end uriToFilename;

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

function importFMU "Imports the Functional Mockup Unit
  Example command:
  importFMU(\"A.fmu\");"
  input String filename "the fmu file name";
  input String workdir := "./" "The output directory for imported FMU files. <default> will put the files to current working directory.";
  output Boolean success "Returns true on success";
protected
  String omhome,exe,call;
algorithm
  // get OPENMODELICAHOME
  omhome := getInstallationDirectoryPath();
  // create the path till fmigenerator
  exe := omhome + "/bin/fmigenerator";
  // create the list of arguments for fmigenerator
  call := exe + " " + "--fmufile=\"" + filename + "\" --outputdir=\"" + workdir + "\"";
  success := 0 == system(call);
annotation(preferredView="text");
end importFMU;

function getSourceFile
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

function setClassComment
  input TypeName class_;
  input String filename;
  output Boolean success;
external "builtin";
annotation(preferredView="text");
end setClassComment;

function getClassNames
  input TypeName class_ := $TypeName(AllLoadedClasses);
  input Boolean recursive := false;
  input Boolean qualified := false;
  input Boolean sort := false;
  input Boolean builtin := false "List also builtin classes if true";
  output TypeName classNames[:]; 
external "builtin";
annotation(preferredView="text");
end getClassNames;

function getPackages
  input TypeName class_ := $TypeName(AllLoadedClasses);
  output TypeName classNames[:]; 
external "builtin";
annotation(preferredView="text");
end getPackages;

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

function plot "Launches a plot window using OMPlotWindow. Returns true on success.
  If OpenModelica was compiled without sendData support, this function will return false.
  
  Example command sequences:
  simulate(A);plot({x,y,z});
  simulate(A);plot(x);
  simulate(A,fileNamePrefix=\"B\");simulate(C);plot(z,\"B.mat\",legend=false);
  "
  input VariableNames vars "The variables you want to plot";
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
external "builtin";
annotation(preferredView="text");
end plot;

function plot3 "Launches a plot window using OMPlot. Returns true on success.
  Don't require sendData support.
  
  Example command sequences:
  simulate(A);plot({x,y,z});
  simulate(A);plot(x, externalWindow=true);
  simulate(A,fileNamePrefix=\"B\");simulate(C);plot(z,\"B.mat\",legend=false);
  "
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
  output Boolean success "Returns true on success";
external "builtin";
annotation(preferredView="text");
end plot3;

function plotAll "Works in the same way as plot(), but does not accept any
  variable names as input. Instead, all variables are part of the plot window.
  
  Example command sequences:
  simulate(A);plotAll();
  simulate(A,fileNamePrefix=\"B\");simulate(C);plotAll(x,\"B.mat\");
  "
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
external "builtin";
annotation(preferredView="text");
end plotAll;

function plotAll3 "Works in the same way as plot(), but does not accept any
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
  output Boolean success "Returns true on success";
external "builtin";
annotation(preferredView="text");
end plotAll3;

function plot2 "Uses the Java-based plot window (ptplot.jar) to launch a plot,
  similar to the plot() command. This command accepts fewer options, but works
  even when OpenModelica was not compiled with sendData support.
  
  Example command sequences:
  simulate(A);plot2({x,y});
  simulate(A,fileNamePrefix=\"B\");simulate(C);plot2(x,\"B.mat\");
  "
  input VariableNames vars;
  input String fileName := "<default>";
  output Boolean success "Returns true on success";
external "builtin";
annotation(preferredView="text");
end plot2;

function visualize "Uses the 3D visualization package, SimpleVisual.mo, to
  visualize the model. See chapter 3.4 (3D Animation) of the OpenModelica
  System Documentation for more details.
  
  Example command sequence:
  simulate(A,outputFormat=\"plt\");visualize(A);
  "
  input TypeName classToVisualize;
  output Boolean success "Returns true on success";
annotation(preferredView="text");
end visualize;

function visualize2 "Uses the 3D visualization package, SimpleVisual.mo, to
  visualize the model. See chapter 3.4 (3D Animation) of the OpenModelica
  System Documentation for more details.
  Writes the visulizations objects into the file \"model_name.visualize\"
  Don't require sendData support.
  
  Example command sequence:
  simulate(A,outputFormat=\"mat\");visualize2(A);visualize2(A,\"B.mat\");visualize2(A,\"B.mat\", true);
  "
  input TypeName className;
  input Boolean externalWindow := false "Opens the visualize in a new window";
  input String fileName := "<default>" "The filename containing the variables. <default> will read the last simulation result";
  output Boolean success "Returns true on success";
  external "builtin";
annotation(preferredView="text");
end visualize2;

function plotParametric "Plots the y-variables as a function of the x-variable.

  Example command sequences:
  simulate(A);plotParametric(x,y);
  simulate(A,fileNamePrefix=\"B\");simulate(C);plotParametric(x,{y1,y2,y3},fileName=\"B.mat\",yLabel=\"[V]\");
  "
  input VariableName xVariable;
  input VariableNames yVariables;
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
  input String xLabel := "" "This text will be used as the horizontal label in the diagram.";
  input String yLabel := "" "This text will be used as the vertical label in the diagram.";
  input Boolean points := false "Determines whether or not the data points should be indicated by a dot in the diagram.";
  input Real xRange[2] := {0.0,0.0} "Determines the horizontal interval that is visible in the diagram. {0,0} will select a suitable range.";
  input Real yRange[2] := {0.0,0.0} "Determines the vertical interval that is visible in the diagram. {0,0} will select a suitable range.";
  output Boolean success "Returns true on success";
external "builtin";
annotation(preferredView="text");
end plotParametric;

function plotParametric2 "Plots the y-variables as a function of the x-variable.

  Example command sequences:
  simulate(A);plotParametric2(x,y);
  simulate(A,fileNamePrefix=\"B\");simulate(C);plotParametric2(x,{y1,y2,y3},\"B.mat\");
  "
  input VariableName xVariable;
  input VariableNames yVariables;
  input String fileName := "<default>";
  output Boolean success "Returns true on success";
external "builtin";
annotation(preferredView="text");
end plotParametric2;

function plotParametric3 "Launches a plotParametric window using OMPlot. Returns true on success.
  Don't require sendData support.
  
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
  output Boolean success "Returns true on success";
external "builtin";
annotation(preferredView="text");
end plotParametric3;

function readSimulationResult "Reads a result file, returning a matrix corresponding to the variables and size given."
  input String filename;
  input VariableNames variables;
  input Integer size := 0 "0=read any size... If the size is not the same as the result-file, this function fails";
  output Real result[:,:];
external "builtin";
annotation(preferredView="text");
end readSimulationResult;

function readSimulationResultSize "The number of intervals that are present in the output file"
  input String fileName;
  output Integer sz;
external "builtin";
annotation(preferredView="text");
end readSimulationResultSize;

function readSimulationResultVars "Returns the variables in the simulation file; you can use val() and plot() commands using these names"
  input String fileName;
  output String[:] vars;
external "builtin";
annotation(preferredView="text");
end readSimulationResultVars;

public function compareSimulationResults "compare simulation results"
  input String filename;
  input String reffilename;
  input String logfilename;
  input Real refTol;
  input Real absTol;
  input String[:] vars;
  output String result;
external "builtin";
annotation(preferredView="text");
end compareSimulationResults;

function val "Works on the filename pointed to by the scripting variable currentSimulationResult.
  The result is the value of the variable at a certain time point.
  For parameters, any time may be given. For variables the startTime<=time<=stopTime needs to hold.
  On error, nan (Not a Number) is returned and the error buffer contains the message."
  input VariableName var;
  input Real time;
  output Real valAtTime;
external "builtin";
annotation(preferredView="text");
end val;

function getAlgorithmCount "Counts the number of Algorithm sections in a class"
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getAlgorithmCount;

function getNthAlgorithm "Returns the Nth Algorithm section"
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthAlgorithm;

function getInitialAlgorithmCount "Counts the number of Initial Algorithm sections in a class"
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getInitialAlgorithmCount;

function getNthInitialAlgorithm "Returns the Nth Initial Algorithm section"
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthInitialAlgorithm;

function getEquationCount "Counts the number of Equation sections in a class"
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getEquationCount;

function getNthEquation "Returns the Nth Equation section"
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthEquation;

function getInitialEquationCount "Counts the number of Initial Equation sections in a class"
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getInitialEquationCount;

function getNthInitialEquation "Returns the Nth Initial Equation section"
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthInitialEquation;

function getAnnotationCount "Counts the number of Annotation sections in a class"
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getAnnotationCount;

function getNthAnnotationString "Returns the Nth Annotation section as string"
  input TypeName class_;
  input Integer index;
  output String result;
external "builtin";
annotation(preferredView="text");
end getNthAnnotationString;

function getImportCount "Counts the number of Import sections in a class"
  input TypeName class_;
  output Integer count;
external "builtin";
annotation(preferredView="text");
end getImportCount;

function getNthImport "Returns the Nth Import as string"
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

function getDocumentationAnnotation "
  TODO: Should be changed to have 2 outputs instead of an array of 2 Strings...
"
  input TypeName cl;
  output String out[2] "{info,revision}";
external "builtin";
annotation(preferredView="text");
end getDocumentationAnnotation;

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

function getClassComment
  input TypeName cl;
  output String comment;
external "builtin";
annotation(preferredView="text");
end getClassComment;

function dirname
  input String path;
  output String dirname;
external "builtin";
annotation(preferredView="text");
end dirname;

function basename
  input String path;
  output String basename;
external "builtin";
annotation(preferredView="text");
end basename;

annotation(preferredView="text");
end Scripting;

annotation(Documentation(__Dymola_DocumentationClass = true));
annotation(preferredView="text");
end OpenModelica;
