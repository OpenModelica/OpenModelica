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

encapsulated package NFEquation

import Absyn;
import NFExpression.Expression;
import Type = NFType;

public uniontype Equation
  record EQUALITY
    Expression lhs "The left hand side expression.";
    Expression rhs "The right hand side expression.";
    Type ty;
    SourceInfo info;
  end EQUALITY;

  record CONNECT
    Expression lhs "The left hand side component.";
    //NFConnect2.Face lhsFace "The face of the lhs component, inside or outside.";
    Type lhsType     "The type of the lhs component.";
    Expression rhs "The right hand side component.";
    //NFConnect2.Face rhsFace "The face of the rhs component, inside or outside.";
    Type rhsType     "The type of the rhs component.";
    //Prefix prefix;
    SourceInfo info;
  end CONNECT;

  record FOR
    String name           "The name of the iterator variable.";
    Integer index         "The index of the iterator variable.";
    Type indexType    "The type of the index/iterator variable.";
    Option<Expression> range "The range expression to loop over.";
    list<Equation> body   "The body of the for loop.";
    SourceInfo info;
  end FOR;

  record IF
    list<tuple<Expression, list<Equation>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    SourceInfo info;
  end IF;

  record WHEN
    list<tuple<Expression, list<Equation>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    SourceInfo info;
  end WHEN;

  record ASSERT
    Expression condition "The assert condition.";
    Expression message "The message to display if the assert fails.";
    Expression level "Error or warning";
    SourceInfo info;
  end ASSERT;

  record TERMINATE
    Expression message "The message to display if the terminate triggers.";
    SourceInfo info;
  end TERMINATE;

  record REINIT
    Expression cref "The variable to reinitialize.";
    Expression reinitExp "The new value of the variable.";
    SourceInfo info;
  end REINIT;

  record NORETCALL
    Expression exp;
    SourceInfo info;
  end NORETCALL;
end Equation;

annotation(__OpenModelica_Interface="frontend");
end NFEquation;
