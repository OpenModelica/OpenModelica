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

encapsulated uniontype NFFlatModel
  import Equation = NFEquation;
  import Algorithm = NFAlgorithm;
  import Variable = NFVariable;

protected
  import Statement = NFStatement;
  import IOStream;

  import FlatModel = NFFlatModel;

public
  record FLAT_MODEL
    String name;
    list<Variable> variables;
    list<Equation> equations;
    list<Equation> initialEquations;
    list<Algorithm> algorithms;
    list<Algorithm> initialAlgorithms;
    Option<SCode.Comment> comment;
  end FLAT_MODEL;

  function toString
    input FlatModel flatModel;
    output String str;
  protected
    IOStream.IOStream s;
  algorithm
    s := IOStream.create(getInstanceName(), IOStream.IOStreamType.LIST());

    s := IOStream.append(s, "class " + flatModel.name + "\n");
    s := toString2(flatModel.variables, function Variable.toString(indent = "  "), "", s);
    s := toString2(flatModel.initialEquations, function Equation.toString(indent = "  "), "initial equation", s);
    s := toString2(flatModel.equations, function Equation.toString(indent = "  "), "equation", s);

    for alg in flatModel.initialAlgorithms loop
      s := toString2(alg.statements, function Statement.toString(indent = "  "), "initial algorithm", s);
    end for;

    for alg in flatModel.algorithms loop
      s := toString2(alg.statements, function Statement.toString(indent = "  "), "algorithm", s);
    end for;

    s := IOStream.append(s, "end " + flatModel.name + ";\n");

    str := IOStream.string(s);
    IOStream.delete(s);
  end toString;

protected
  function toString2<T>
    input list<T> elements;
    input FuncT toStringFunc;
    input String header;
    input output IOStream.IOStream s;

    partial function FuncT
      input T element;
      output String str;
    end FuncT;
  algorithm
    if listEmpty(elements) then
      return;
    end if;

    if not stringEmpty(header) then
      s := IOStream.append(s, header);
      s := IOStream.append(s, "\n");
    end if;

    for e in elements loop
      s := IOStream.append(s, toStringFunc(e));
      s := IOStream.append(s, "\n");
    end for;
  end toString2;

  annotation(__OpenModelica_Interface="frontend");
end NFFlatModel;
