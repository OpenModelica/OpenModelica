/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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
encapsulated uniontype NBStrongComponent
"file:        NBStrongComponent.mo
 package:     NBStrongComponent
 description: This file contains the data-types used save the strong Component
              data after causalization.
"
protected
  // selfimport
  import StrongComponent = NBStrongComponent;

  // NF imports
  import Variable = NFVariable;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import NBEquation.Equation;
  import Tearing = NBTearing;

  // Util imports
  import Pointer;
  import StringUtil;

public
  record SINGLE_EQUATION
    Pointer<Variable> var;
    Pointer<Equation> eqn;
  end SINGLE_EQUATION;

  record SINGLE_ARRAY
    list<Pointer<Variable>> vars;
    Pointer<Equation> eqn;
  end SINGLE_ARRAY;

  record SINGLE_ALGORITHM
    list<Pointer<Variable>> vars;
    Pointer<Equation> eqn;
  end SINGLE_ALGORITHM;

  record SINGLE_RECORD_EQUATION
    list<Pointer<Variable>> vars;
    Pointer<Equation> eqn;
  end SINGLE_RECORD_EQUATION;

  record SINGLE_WHEN_EQUATION
    list<Pointer<Variable>> vars;
    Pointer<Equation> eqn;
  end SINGLE_WHEN_EQUATION;

  record SINGLE_IF_EQUATION
    list<Pointer<Variable>> vars;
    Pointer<Equation> eqn;
  end SINGLE_IF_EQUATION;

  record ALGEBRAIC_LOOP
    list<Pointer<Variable>> vars;
    list<Pointer<Equation>> eqns;
    Option<BackendDAE> jac;
    Boolean mixed         "true for system that has discrete dependencies to the
                          iteration variables";
  end ALGEBRAIC_LOOP;

  record TORN_LOOP
    Tearing strict;
    Option<Tearing> casual;
    Boolean linear;
    Boolean mixed "true for system that discrete dependencies to the iteration variables";
  end TORN_LOOP;

  function toString
    input StrongComponent comp;
    input Integer index = -1;
    output String str;
  protected
    String indexStr = if index > 0 then " " + intString(index) else "";
  algorithm
    str := match comp
      local
        StrongComponent qual;
        Tearing casual;

      case qual as SINGLE_EQUATION()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single Equation");
          str := str + "### Variable:" + Variable.toString(Pointer.access(qual.var), "\t") + "\n";
          str := str + "### Equation:" + Equation.toString(Pointer.access(qual.eqn), "\t") + "\n";
      then str;

      case qual as SINGLE_ARRAY()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single Array");
          str := str + "### Variables:\n";
          for var in qual.vars loop
            str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
          end for;
          str := str + "\n### Equation:" + Equation.toString(Pointer.access(qual.eqn), "\t") + "\n";
      then str;

      case qual as SINGLE_ALGORITHM()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single Algorithm");
          str := str + "### Variables:\n";
          for var in qual.vars loop
            str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
          end for;
          str := str + "\n### Equation:" + Equation.toString(Pointer.access(qual.eqn), "\t") + "\n";
      then str;

      case qual as SINGLE_RECORD_EQUATION()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single Record Equation");
          str := str + "### Variables:\n";
          for var in qual.vars loop
            str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
          end for;
          str := str + "\n### Equation:" + Equation.toString(Pointer.access(qual.eqn), "\t") + "\n";
      then str;

      case qual as SINGLE_WHEN_EQUATION()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single When-Equation");
          str := str + "### Variables:\n";
          for var in qual.vars loop
            str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
          end for;
          str := str + "\n### Equation:" + Equation.toString(Pointer.access(qual.eqn), "\t") + "\n";
      then str;

      case qual as SINGLE_IF_EQUATION()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single If-Equation");
          str := str + "### Variables:\n";
          for var in qual.vars loop
            str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
          end for;
          str := str + "\n### Equation:" + Equation.toString(Pointer.access(qual.eqn), "\t") + "\n";
      then str;

      case qual as ALGEBRAIC_LOOP()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Algebraic Loop (Mixed = " + boolString(qual.mixed) + ")");
          str := str + "### Variables:\n";
          for var in qual.vars loop
            str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
          end for;
          str := str + "\n### Equations:\n";
          for eqn in qual.eqns loop
            str := str  + Equation.toString(Pointer.access(eqn), "\t") + "\n";
          end for;
      then str;

      case qual as TORN_LOOP()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Torn Algebraic Loop (Linear = " + boolString(qual.linear) + ", Mixed = " + boolString(qual.mixed) + ")");
          str := str + Tearing.toString(qual.strict, "Strict Tearing Set");
          if isSome(qual.casual) then
            SOME(casual) := qual.casual;
            str := str + Tearing.toString(casual, "Casual Tearing Set");
          end if;
      then str;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
      then fail();
    end match;
  end toString;

    annotation(__OpenModelica_Interface="backend");
end NBStrongComponent;
