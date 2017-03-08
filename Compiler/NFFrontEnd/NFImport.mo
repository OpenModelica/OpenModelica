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

encapsulated package NFImport
" file:        NFImport.mo
  package:     NFImport
  description: Instantiation of class extends
"

import Absyn;
import SCode;

import Builtin = NFBuiltin;
import Binding = NFBinding;
import NFComponent.Component;
import Dimension = NFDimension;
import Expression = NFExpression;
import NFClass.ClassTree;
import NFClass.Class;
import NFInst.InstNode;
import NFInst.InstNodeType;
import NFMod.Modifier;
import NFMod.ModifierScope;
import NFEquation.Equation;
import NFStatement.Statement;
import Type = NFType;

protected
import Array;
import Error;
import Flatten = NFFlatten;
import Global;
import InstUtil = NFInstUtil;
import List;
import Lookup = NFLookup;
import MetaModelica.Dangerous;
import Typing = NFTyping;
import ExecStat.{execStat,execStatReset};
import SCodeDump;
import SCodeUtil;
import System;

public
function addImportsToScope
  // adrpo: hm, i don't know if this is correct as imports are not inherited
  input list<SCode.Element> imports;
  input InstNode currentScope;
  input output ClassTree.Tree scope;
protected
  Absyn.Import i;
  InstNode node, top_scope;
  SourceInfo info;
  Class cls;
  ClassTree.Tree els;
algorithm
  if listEmpty(imports) then
    return;
  end if;

  // All imports are looked up from the top scope, so we might as well look it
  // up now to avoid having to do that for each import.
  top_scope := InstNode.topScope(currentScope);

  for imp in imports loop
    SCode.IMPORT(imp = i, info = info) := imp;

    () := match i
      case Absyn.NAMED_IMPORT()
        algorithm
          node := Lookup.lookupClassName(Absyn.FULLYQUALIFIED(i.path), top_scope, info);
          // TODO! FIXME! check if there is a local definition with the same name and if prefix of path is a package
          // how about importing constants not just classes?!
          scope := NFInst.addClassToScope(i.name, ClassTree.Entry.CLASS(node), info, scope);
        then
          ();

      case Absyn.QUAL_IMPORT()
        algorithm
          node := Lookup.lookupClassName(Absyn.FULLYQUALIFIED(i.path), top_scope, info);
          // TODO! FIXME! check if there is a local definition with the same name and if prefix of path is a package
          // how about importing constants not just classes?!
          scope := NFInst.addClassToScope(Absyn.pathLastIdent(i.path), ClassTree.Entry.CLASS(node), info, scope);
        then
          ();

      case Absyn.UNQUAL_IMPORT()
        algorithm
          node := Lookup.lookupClassName(Absyn.FULLYQUALIFIED(i.path), top_scope, info);
          node := NFInst.expand(node);
          // TODO! FIXME! check that the path is a package!
          // how about importing constants not just classes?!
          // add all the definitions from node to current scope
          // using addInheritedElements here as is basically similar
          scope := NFInst.addInheritedElements({node}, scope);
        then
          ();

      else
        algorithm
          print("NFInst.addImportsToScope: IMPLEMENT ME\n");
        then
          ();

    end match;
  end for;
end addImportsToScope;

annotation(__OpenModelica_Interface="frontend");
end NFImport;
