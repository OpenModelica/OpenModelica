/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package GlobalScript
" file:        InteractiveTypes.mo
  package:     GlobalScript
  description: Types part of the AST for interactive scripting

"

public import Absyn;

public
uniontype Statement
"An Statement given in the interactive environment can either be
 an Algorithm statement or an expression.
 - GlobalScript.Statement"
  record IALG
    Absyn.AlgorithmItem algItem;
  end IALG;

  record IEXP
    Absyn.Exp exp;
    SourceInfo info;
  end IEXP;

end Statement;

public
uniontype Statements
  "Several interactive statements are used in Modelica scripts.
  - GlobalScript.Statements"
  record ISTMTS
    list<Statement> interactiveStmtLst "interactiveStmtLst" ;
    Boolean semicolon "semicolon; true = statement ending with a semicolon. The result will not be shown in the interactive environment." ;
  end ISTMTS;

end Statements;

annotation(__OpenModelica_Interface="parser");
end GlobalScript;
