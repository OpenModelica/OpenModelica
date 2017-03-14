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

encapsulated package NFStatement

import Absyn;
import Type = NFType;
import Expression = NFExpression;
import NFInstNode.InstNode;

public uniontype Statement
  record ASSIGNMENT
    Expression lhs "The asignee";
    Expression rhs "The expression";
    SourceInfo info;
  end ASSIGNMENT;

  record FUNCTION_ARRAY_INIT "Used to mark in which order local array variables in functions should be initialized"
    String name;
    Type ty;
    SourceInfo info;
  end FUNCTION_ARRAY_INIT;

  record FOR
    InstNode iterator;
    list<Statement> body "The body of the for loop.";
    SourceInfo info;
  end FOR;

  record IF
    list<tuple<Expression, list<Statement>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    SourceInfo info;
  end IF;

  record WHEN
    list<tuple<Expression, list<Statement>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    SourceInfo info;
  end WHEN;

  record ASSERT
    Expression condition "The assert condition.";
    Expression message "The message to display if the assert fails.";
    Expression level;
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

  record WHILE
    Expression condition;
    list<Statement> body;
    SourceInfo info;
  end WHILE;

  record RETURN
    SourceInfo info;
  end RETURN;

  record BREAK
    SourceInfo info;
  end BREAK;

  record FAILURE
    list<Statement> body;
    SourceInfo info;
  end FAILURE;

end Statement;

annotation(__OpenModelica_Interface="frontend");
end NFStatement;
