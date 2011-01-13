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

function der "type for builtin operator der has unit type parameter to be able to express that
derivative of expression means an addition of 1/s on the unit dimension"
  input Real x(unit="'p");
  output Real dx(unit="'p/s");
external "builtin";
end der;

function initial
  output Boolean isInitial;
  annotation(__OpenModelica_Impure = true);
external "builtin";
end initial;

function terminal
  output Boolean isTerminal;
  annotation(__OpenModelica_Impure = true);
external "builtin";
end terminal;

function sample
  input Real start;
  input Real interval;
  output Boolean isSample;
  annotation(__OpenModelica_Impure = true);
external "builtin";
end sample;

function ceil
  input Real x;
  output Real y;
external "builtin";
end ceil;

function floor
  input Real x;
  output Real y;
external "builtin";
end floor;

function integer
  input Real x;
  output Integer y;
external "builtin";
end integer;

function sqrt
  input Real x(unit="'p");
  output Real y(unit="'p(1/2)");
external "builtin";
end sqrt;

function sign
  input Real v;
  output Integer _sign;
external "builtin";
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
end identity;

function semiLinear
  input Real x;
  input Real positiveSlope;
  input Real negativeSlope;
  output Real result;
external "builtin";
end semiLinear;

function edge
  input Boolean b;
  output Boolean edgeEvent;
  // TODO: Ceval parameters? Needed to remove the builtin handler
external "builtin";
end edge;

function sin
  input Real x;
  output Real y;
external "builtin";
end sin;

function cos
  input Real x;
  output Real y;
external "builtin";
end cos;

function tan
  input Real x;
  output Real y;
external "builtin";
end tan;

function sinh
  input Real x;
  output Real y;
external "builtin";
end sinh;

function cosh
  input Real x;
  output Real y;
external "builtin";
end cosh;

function tanh
  input Real x;
  output Real y;
external "builtin";
end tanh;

function asin
  input Real x;
  output Real y;
external "builtin";
end asin;

function acos
  input Real x;
  output Real y;
external "builtin";
end acos;

function atan
  input Real x;
  output Real y;
external "builtin";
end atan;

function atan2
  input Real x1;
  input Real x2;
  output Real y;
external "builtin";
end atan2;

function exp
  input Real x(unit="1");
  output Real y(unit="1");
external "builtin";
end exp;

function log
  input Real x(unit="1");
  output Real y(unit="1");
external "builtin";
end log;

function log10
  input Real x(unit="1");
  output Real y(unit="1");
external "builtin";
end log10;

function homotopy
  input Real actual;
  input Real simplified;
  output Real outValue;
end homotopy;

// Dummy functions that can't be properly defined in Modelica, but used by
// SCodeFlatten to define which builtin functions exist (SCodeFlatten doesn't
// care how the functions are defined, only if they exist or not).

function div
/* Real or Integer in/output */
external "builtin";
end div;

function mod
/* Real or Integer in/output */
external "builtin";
end mod;

function rem
/* Real or Integer in/output */
external "builtin";
end rem;

function delay
  external "builtin";
end delay;

function abs
/* Real or Integer in/output */
  external "builtin";
end abs;

function min
  external "builtin";
end min;

function max
  external "builtin";
end max;

function sum
  external "builtin";
end sum;

function product
  external "builtin";
end product;

function transpose
  external "builtin";
end transpose;

function outerProduct
  external "builtin";
end outerProduct;

function symmetric
  external "builtin";
end symmetric;

function cross
  external "builtin";
end cross;

function skew
  external "builtin";
end skew;

function smooth
  external "builtin";
end smooth;

function diagonal
  external "builtin";
end diagonal;

function cardinality
  external "builtin";
end cardinality;

function array
  external "builtin";
end array;

function zeros
  external "builtin";
end zeros;

function ones
  external "builtin";
end ones;

function fill
  external "builtin";
end fill;

function linspace
  external "builtin";
end linspace;

function noEvent
  external "builtin";
end noEvent;

function pre
  external "builtin";
end pre;

function change
  external "builtin";
end change;

function reinit
  external "builtin";
end reinit;

function ndims
  external "builtin";
end ndims;

function size
  external "builtin";
end size;

function scalar
  external "builtin";
end scalar;

function vector
  external "builtin";
end vector;

function matrix
  external "builtin";
end matrix;

function cat
  external "builtin";
end cat;

function rooted "Not standard Modelica"
  external "builtin";
end rooted;

function actualStream
  external "builtin";
end actualStream;

function inStream
  external "builtin";
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
    external "builtin";
  end activated;

  function lastInterval
    external "builtin";
  end lastInterval;
end Subtask;

function print "Not standard Modelica, but very useful for debugging."
  input String str;
  annotation(__OpenModelica_Impure = true);
external "builtin";
end print;

function classDirectory "Not standard Modelica"
  output String str;
external "builtin";
end classDirectory;

encapsulated package OpenModelica
  package Scripting
    function system "Similar to system(3). Executes the given command in the system shell."
      input String callStr "String to call: bash -c $callStr";
      output Integer retval "Return value of the system call; usually 0 on success";
    external "builtin";
    end system;
  end Scripting;
end OpenModelica;
