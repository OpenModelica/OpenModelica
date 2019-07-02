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

encapsulated package GlobalScriptDump
" file:        GlobalScriptDump.mo
  package:     GlobalScriptDump
  description: Dump functions for scripting types.

"

import Absyn;
import GlobalScript;
import SymbolTable;

protected

import Dump;
import List;

public

function printIstmtsStr
  "Prints a group of interactive statements to a string."
  input GlobalScript.Statements inStatements;
  output String outString;
algorithm
  outString := match(inStatements)
    local
      list<GlobalScript.Statement> stmts;

    case GlobalScript.ISTMTS(interactiveStmtLst = stmts)
      then stringDelimitList(List.map(stmts, printIstmtStr), "; ");

    else "printIstmtsStr: unknown";
  end match;
end printIstmtsStr;

function printIstmtStr
  input GlobalScript.Statement inStatement;
  output String outString;
algorithm
  outString := match(inStatement)
    local
      Absyn.AlgorithmItem alg;
      Absyn.Exp expr;

    case GlobalScript.IALG(algItem = alg)
      then Dump.unparseAlgorithmStr(alg);

    case GlobalScript.IEXP(exp = expr)
      then Dump.printExpStr(expr);

    else "printIstmtStr: unknown";
  end match;
end printIstmtStr;

function printAST
"author: vwaurich TUD 10-2016"
  input Absyn.Program pr;
protected
  String s="";
  Absyn.Class class_;
  list<Absyn.Class> classes;
  Absyn.Within within_ ;
algorithm
  Absyn.PROGRAM(classes, within_) := pr;
  for class_ in classes loop
    s := s+classString(class_)+"\n";
  end for;
  print(s);
end printAST;

function printGlobalScript
"author: vwaurich TUD 10-2016"
  input SymbolTable st;
algorithm
  print("AST\n");
  printAST(st.ast);
end printGlobalScript;

protected

function classString
"author: vwaurich TUD 10-2016"
  input Absyn.Class cl;
  output String s;
protected
  Absyn.Ident id;
algorithm
  Absyn.CLASS(name = id) := cl;
  s := id +": "+ AbsynUtil.classFilename(cl);
end classString;

annotation(__OpenModelica_Interface="backend");
end GlobalScriptDump;
