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

    for v in flatModel.variables loop
      s := Variable.toStream(v, "  ", s);
      s := IOStream.append(s, ";\n");
    end for;

    if not listEmpty(flatModel.initialEquations) then
      s := IOStream.append(s, "initial equation\n");
      s := Equation.toStreamList(flatModel.initialEquations, "  ", s);
    end if;

    if not listEmpty(flatModel.equations) then
      s := IOStream.append(s, "equation\n");
      s := Equation.toStreamList(flatModel.equations, "  ", s);
    end if;

    for alg in flatModel.initialAlgorithms loop
      if not listEmpty(alg.statements) then
        s := IOStream.append(s, "initial algorithm\n");
        s := Statement.toStreamList(alg.statements, "  ", s);
      end if;
    end for;

    for alg in flatModel.algorithms loop
      if not listEmpty(alg.statements) then
        s := IOStream.append(s, "algorithm\n");
        s := Statement.toStreamList(alg.statements, "  ", s);
      end if;
    end for;

    s := IOStream.append(s, "end " + flatModel.name + ";\n");

    str := IOStream.string(s);
    IOStream.delete(s);
  end toString;

  annotation(__OpenModelica_Interface="frontend");
end NFFlatModel;
