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

encapsulated uniontype NFImport
  import SCode;
  import NFInstNode.InstNode;

protected
  import Inst = NFInst;
  import Lookup = NFLookup;
  import NFClassTree.ClassTree;
  import NFClass.Class;

  import Import = NFImport;

public
  record UNRESOLVED_IMPORT
    Absyn.Import imp;
    InstNode scope;
    SourceInfo info;
  end UNRESOLVED_IMPORT;

  record RESOLVED_IMPORT
    InstNode node;
    SourceInfo info;
  end RESOLVED_IMPORT;

  record CONFLICTING_IMPORT
    Import imp1;
    Import imp2;
  end CONFLICTING_IMPORT;

  function name
    input Import imp;
    output String name;
  algorithm
    name := match imp
      case UNRESOLVED_IMPORT() then Absyn.importName(imp.imp);
      case RESOLVED_IMPORT() then InstNode.name(imp.node);
    end match;
  end name;

  function info
    input Import imp;
    output SourceInfo info;
  algorithm
    info := match imp
      case UNRESOLVED_IMPORT() then imp.info;
      case RESOLVED_IMPORT() then imp.info;
    end match;
  end info;

  function resolve
    input Import imp;
    output InstNode node;
    output Boolean changed;
    output Import outImport;
  algorithm
    (outImport, node, changed) := match imp
      case UNRESOLVED_IMPORT()
        algorithm
          (outImport, node) := instQualified(imp.imp, imp.scope, imp.info);
        then
          (outImport, node, true);

      case RESOLVED_IMPORT()
        then (imp, imp.node, false);

      case CONFLICTING_IMPORT()
        algorithm
          printImportError(imp.imp1, imp.imp2);
        then
          fail();

    end match;
  end resolve;

  function instQualified
    input Absyn.Import imp;
    input InstNode scope;
    input SourceInfo info;
    output Import outImport;
    output InstNode node;
  algorithm
    node := match imp
      case Absyn.Import.NAMED_IMPORT()
        algorithm
          node := Lookup.lookupImport(imp.path, scope, info);
        then
          InstNode.rename(imp.name, node);

      case Absyn.Import.QUAL_IMPORT()
        then Lookup.lookupImport(imp.path, scope, info);
    end match;

    outImport := RESOLVED_IMPORT(node, info);
  end instQualified;

  function instUnqualified
    input Absyn.Import imp;
    input InstNode scope;
    input SourceInfo info;
    input output list<Import> imps = {};
  protected
    Absyn.Path path;
    InstNode node;
    ClassTree tree;
    list<InstNode> elements;
  algorithm
    Absyn.Import.UNQUAL_IMPORT(path = path) := imp;

    node := Lookup.lookupImport(path, scope, info);
    node := Inst.instPackage(node);
    tree := Class.classTree(InstNode.getClass(node));

    () := match tree
      case ClassTree.FLAT_TREE()
        algorithm
          for cls in tree.classes loop
            imps := RESOLVED_IMPORT(cls, info) :: imps;
          end for;

          for comp in tree.components loop
            imps := RESOLVED_IMPORT(comp, info) :: imps;
          end for;
        then
          ();

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got invalid class tree", sourceInfo());
        then
          ();

    end match;
  end instUnqualified;

  function printImportError
    input Import imp1;
    input Import imp2;
  protected
    Error.Message err_msg;
  algorithm
    Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, info(imp1));

    err_msg := match imp2
      case UNRESOLVED_IMPORT() then Error.MULTIPLE_QUALIFIED_IMPORTS_WITH_SAME_NAME;
      case RESOLVED_IMPORT() then Error.IMPORT_SEVERAL_NAMES;
    end match;

    Error.addSourceMessage(err_msg, {name(imp2)}, info(imp2));
  end printImportError;

annotation(__OpenModelica_Interface="frontend");
end NFImport;
