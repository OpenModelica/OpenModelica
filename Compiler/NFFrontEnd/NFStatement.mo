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

import DAE;

public uniontype Statement
  record UNTYPED_ASSIGNMENT
    Absyn.Exp lhs;
    Absyn.Exp rhs;
    SourceInfo info;
  end UNTYPED_ASSIGNMENT;

  record ASSIGNMENT
    DAE.Exp lhs "The asignee";
    DAE.Exp rhs "The expression";
    SourceInfo info;
  end ASSIGNMENT;

  record FUNCTION_ARRAY_INIT "Used to mark in which order local array variables in functions should be initialized"
    String name;
    DAE.Type ty;
    SourceInfo info;
  end FUNCTION_ARRAY_INIT;

  record UNTYPED_FOR
    String name;
    Option<Absyn.Exp> range;
    list<Statement> body;
    SourceInfo info;
  end UNTYPED_FOR;

  record FOR
    String name "The name of the iterator variable.";
    Integer index "The index of the scope of the iterator variable.";
    DAE.Type indexType "The type of the index/iterator variable.";
    Option<DAE.Exp> range "The range expression to loop over.";
    list<Statement> body "The body of the for loop.";
    SourceInfo info;
  end FOR;

  record UNTYPED_IF
    list<tuple<Absyn.Exp, list<Statement>>> branches;
    SourceInfo info;
  end UNTYPED_IF;

  record IF
    list<tuple<DAE.Exp, list<Statement>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    SourceInfo info;
  end IF;

  record UNTYPED_WHEN
    list<tuple<Absyn.Exp, list<Statement>>> branches;
    SourceInfo info;
  end UNTYPED_WHEN;

  record WHEN
    list<tuple<DAE.Exp, list<Statement>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    SourceInfo info;
  end WHEN;

  record UNTYPED_ASSERT
    Absyn.Exp condition;
    Absyn.Exp message;
    Absyn.Exp level;
    SourceInfo info;
  end UNTYPED_ASSERT;

  record ASSERT
    DAE.Exp condition "The assert condition.";
    DAE.Exp message "The message to display if the assert fails.";
    DAE.Exp level;
    SourceInfo info;
  end ASSERT;

  record UNTYPED_TERMINATE
    Absyn.Exp message;
    SourceInfo info;
  end UNTYPED_TERMINATE;

  record TERMINATE
    DAE.Exp message "The message to display if the terminate triggers.";
    SourceInfo info;
  end TERMINATE;

  record UNTYPED_REINIT
    Absyn.ComponentRef cref;
    Absyn.Exp reinitExp;
    SourceInfo info;
  end UNTYPED_REINIT;

  record REINIT
    DAE.ComponentRef cref "The variable to reinitialize.";
    DAE.Exp reinitExp "The new value of the variable.";
    SourceInfo info;
  end REINIT;

  record UNTYPED_NORETCALL
    Absyn.Exp exp;
    SourceInfo info;
  end UNTYPED_NORETCALL;

  record NORETCALL
    DAE.Exp exp;
    SourceInfo info;
  end NORETCALL;

  record UNTYPED_WHILE
    Absyn.Exp condition;
    list<Statement> body;
    SourceInfo info;
  end UNTYPED_WHILE;

  record WHILE
    DAE.Exp condition;
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
