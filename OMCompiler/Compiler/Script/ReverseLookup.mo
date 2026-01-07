/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

encapsulated package ReverseLookup
  import Absyn;

protected
  import AbsynUtil;
  import BaseAvlTree;
  import Dump;
  import ExecStat;
  import InteractiveUtil;
  import JSON;
  import NFApi;
  import Util;

  uniontype PathEntry
    record ENTRY
      PathTree.Tree tree;
      Boolean shadowed;
    end ENTRY;
  end PathEntry;

  encapsulated package PathTree
    import BaseAvlTree;
    import ReverseLookup.PathEntry;
    extends BaseAvlTree;

    redeclare type Key = String;
    redeclare type Value = PathEntry;

    redeclare function extends keyStr
    algorithm
      outString := inKey;
    end keyStr;

    redeclare function extends valueStr
    algorithm
      outString := "";
    end valueStr;

    redeclare function extends keyCompare
    algorithm
      outResult := stringCompare(inKey1, inKey2);
    end keyCompare;
  end PathTree;

  uniontype Paths
    record PATHS
      PathTree.Tree tree;
      list<String> relativePath;
    end PATHS;
  end Paths;

  uniontype Match
    record MATCH
      Absyn.ComponentRef name;
      SourceInfo info;
    end MATCH;
  end Match;

  type Matches = list<Match>;

public
  function lookup
    input Absyn.Path path;
    input Absyn.Path scope;
    input Absyn.Program program;
    input Boolean exactMatch;
    input Boolean prettyPrint;
    output String result;
  protected
    PathTree.Tree tree;
    Matches matches;
    Paths paths;
    Absyn.Class cls;
    Option<Absyn.Path> opt_path;
    Absyn.Path relative_path;
  algorithm
    ExecStat.execStatReset();

    if AbsynUtil.pathEqual(scope, Absyn.Path.IDENT("AllLoadedClasses")) then
      tree := addPath(path, PathTree.new());
      paths := Paths.PATHS(tree, AbsynUtil.pathToStringList(path));
      matches := lookupInProgram(program, paths, exactMatch);
    else
      opt_path := AbsynUtil.pathStripSamePrefix(path, scope);
      relative_path := Util.getOptionOrDefault(opt_path, path);
      tree := addPath(relative_path, PathTree.new());
      paths := Paths.PATHS(tree, AbsynUtil.pathToStringList(relative_path));

      try
        cls := InteractiveUtil.getPathedClassInProgram(scope, program);
        matches := lookupInClass(cls, paths, exactMatch, {});
      else
        matches := {};
      end try;
    end if;

    result := serializeMatches(matches, prettyPrint);
    ExecStat.execStat("ReverseLookup.lookup(" + AbsynUtil.pathString(path) + ")");
  end lookup;

protected
  function addPath
    input Absyn.Path path;
    input output PathTree.Tree tree;
  protected
    Option<PathEntry> opt_entry;
    PathEntry entry;
    Option<PathTree.Tree> opt_tree;
    PathTree.Tree rest_tree;
  algorithm
    tree := match path
      case Absyn.Path.IDENT() then PathTree.add(tree, path.name, PathEntry.ENTRY(PathTree.new(), false), conflictFunc = PathTree.addConflictKeep);
      case Absyn.Path.QUALIFIED()
        algorithm
          opt_entry := PathTree.getOpt(tree, path.name);

          if isSome(opt_entry) then
            entry := Util.getOption(opt_entry);
            entry.tree := addPath(path.path, entry.tree);
          else
            entry := PathEntry.ENTRY(addPath(path.path, PathTree.new()), false);
          end if;
        then
          PathTree.add(tree, path.name, entry, conflictFunc = PathTree.addConflictReplace);

      case Absyn.Path.FULLYQUALIFIED() then addPath(path.path, tree);
    end match;
  end addPath;

  function lookupPath
    input Absyn.Path path;
    input PathTree.Tree paths;
    input Boolean exactMatch;
    input Boolean fullyQualified = false;
    output Boolean found;
  protected
    PathEntry entry;
  algorithm
    found := matchcontinue path
      case Absyn.Path.IDENT()
        algorithm
          entry := PathTree.get(paths, path.name);
        then
          (fullyQualified or not entry.shadowed) and PathTree.isEmpty(entry.tree);

      case Absyn.Path.QUALIFIED()
        algorithm
          entry := PathTree.get(paths, path.name);

          if entry.shadowed and not fullyQualified then
            found := false;
          elseif PathTree.isEmpty(entry.tree) and not exactMatch then
            // A prefix of the path matches.
            found := true;
          else
            found := lookupPath(path.path, entry.tree, exactMatch, fullyQualified);
          end if;
        then
          found;

      case Absyn.Path.FULLYQUALIFIED() then lookupPath(path.path, paths, exactMatch, true);
      else false;
    end matchcontinue;
  end lookupPath;

  function matchPath
    input Absyn.Path path;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    if lookupPath(path, paths.tree, exactMatch) then
      matches := Match.MATCH(AbsynUtil.pathToCref(path), info) :: matches;
    end if;
  end matchPath;

  function lookupCref
    input Absyn.ComponentRef cref;
    input PathTree.Tree paths;
    input Boolean exactMatch;
    input Boolean fullyQualified = false;
    output Boolean found;
  protected
    PathEntry entry;
  algorithm
    found := matchcontinue cref
      case Absyn.ComponentRef.CREF_IDENT()
        algorithm
          entry := PathTree.get(paths, cref.name);
        then
          (fullyQualified or not entry.shadowed) and PathTree.isEmpty(entry.tree);

      case Absyn.ComponentRef.CREF_QUAL()
        algorithm
          entry := PathTree.get(paths, cref.name);

          if entry.shadowed and not fullyQualified then
            found := false;
          elseif PathTree.isEmpty(entry.tree) and not exactMatch then
            // A prefix of the path matches.
            found := true;
          else
            found := lookupCref(cref.componentRef, entry.tree, exactMatch, fullyQualified);
          end if;
        then
          found;

      case Absyn.ComponentRef.CREF_FULLYQUALIFIED() then lookupCref(cref.componentRef, paths, exactMatch, true);
      else false;
    end matchcontinue;
  end lookupCref;

  function matchCref
    input Absyn.ComponentRef cref;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    if lookupCref(cref, paths.tree, exactMatch) then
      matches := Match.MATCH(cref, info) :: matches;
    end if;
  end matchCref;

  function shadowLocalNames
    input Absyn.Class cls;
    input output Paths paths;
  algorithm
    for part in AbsynUtil.getClassPartsInClass(cls) loop
      for item in AbsynUtil.getElementItemsInClass(cls) loop
        paths := shadowLocalNamesInElementItem(item, paths);
      end for;
    end for;
  end shadowLocalNames;

  function shadowLocalNamesInElementItem
    input Absyn.ElementItem item;
    input output Paths paths;
  protected
    Absyn.ElementSpec spec;
  algorithm
    paths := match item
      case Absyn.ElementItem.ELEMENTITEM(element = Absyn.Element.ELEMENT(specification = spec))
        then shadowLocalNamesInElementSpec(spec, paths);
      else paths;
    end match;
  end shadowLocalNamesInElementItem;

  function shadowLocalNamesInElementSpec
    input Absyn.ElementSpec spec;
    input output Paths paths;
  algorithm
    paths := match spec
      case Absyn.ElementSpec.CLASSDEF()
        then shadowLocalName(AbsynUtil.className(spec.class_), paths);

      case Absyn.ElementSpec.COMPONENTS()
        algorithm
          for comp in spec.components loop
            paths := shadowLocalName(AbsynUtil.componentName(comp), paths);
          end for;
        then
          paths;

      else paths;
    end match;
  end shadowLocalNamesInElementSpec;

  function shadowLocalName
    input String name;
    input output Paths paths;
  protected
    PathEntry entry;
  algorithm
    if PathTree.hasKey(paths.tree, name) then
      entry := PathTree.get(paths.tree, name);

      if not entry.shadowed then
        entry.shadowed := true;
        paths.tree := PathTree.update(paths.tree, name, entry);
      end if;
      //paths.tree := PathTree.update(paths.tree, name, PathTree.add(PathTree.new(), "$shadowed", PathTree.new()));
    end if;
  end shadowLocalName;

  function lookupInProgram
    input Absyn.Program program;
    input Paths paths;
    input Boolean exactMatch;
    output Matches matches = {};
  algorithm
    for cls in program.classes loop
      matches := lookupInClass(cls, paths, exactMatch, matches);
    end for;
  end lookupInProgram;

  function lookupInClass
    input Absyn.Class cls;
    input Paths paths;
    input Boolean exactMatch;
    input output Matches matches;
  protected
    list<String> relative_path = paths.relativePath;
    Paths local_paths;
  algorithm
    local_paths := shadowLocalNames(cls, paths);

    if not listEmpty(relative_path) and cls.name == listHead(relative_path) then
      relative_path := listRest(relative_path);
      local_paths.relativePath := relative_path;

      if not listEmpty(relative_path) then
        local_paths.tree := addPath(AbsynUtil.stringListPath(relative_path), local_paths.tree);
      end if;
    end if;

    matches := lookupInClassDef(cls.body, local_paths, exactMatch, cls.info, matches);
  end lookupInClass;

  function lookupInClassDef
    input Absyn.ClassDef cdef;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    matches := match cdef
      case Absyn.ClassDef.PARTS()
        algorithm
          for part in cdef.classParts loop
            matches := lookupInClassPart(part, paths, exactMatch, info, matches);
          end for;

          for ann in cdef.ann loop
            matches := lookupInAnnotation(ann, paths, exactMatch, matches);
          end for;
        then
          matches;

      case Absyn.ClassDef.DERIVED()
        algorithm
          matches := lookupInTypeSpec(cdef.typeSpec, paths, exactMatch, info, matches);

          for arg in cdef.arguments loop
            matches := lookupInElementArg(arg, paths, exactMatch, matches);
          end for;
        then
          lookupInCommentOpt(cdef.comment, paths, exactMatch, matches);

      case Absyn.ClassDef.ENUMERATION()
        algorithm
          matches := lookupInEnumDef(cdef.enumLiterals, paths, exactMatch, matches);
        then
          lookupInCommentOpt(cdef.comment, paths, exactMatch, matches);

      case Absyn.ClassDef.OVERLOAD()
        then lookupInCommentOpt(cdef.comment, paths, exactMatch, matches);

      case Absyn.ClassDef.CLASS_EXTENDS()
        algorithm
          for arg in cdef.modifications loop
            matches := lookupInElementArg(arg, paths, exactMatch, matches);
          end for;

          for part in cdef.parts loop
            matches := lookupInClassPart(part, paths, exactMatch, info, matches);
          end for;

          for ann in cdef.ann loop
            matches := lookupInAnnotation(ann, paths, exactMatch, matches);
          end for;
        then
          matches;

      case Absyn.ClassDef.PDER()
        algorithm
          matches := matchPath(cdef.functionName, paths, exactMatch, info, matches);
        then
          lookupInCommentOpt(cdef.comment, paths, exactMatch, matches);

      else matches;
    end match;
  end lookupInClassDef;

  function lookupInClassPart
    input Absyn.ClassPart part;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    matches := match part
      case Absyn.ClassPart.PUBLIC()
        algorithm
          for e in part.contents loop
            matches := lookupInElementItem(e, paths, exactMatch, matches);
          end for;
        then
          matches;

      case Absyn.ClassPart.PROTECTED()
        algorithm
          for e in part.contents loop
            matches := lookupInElementItem(e, paths, exactMatch, matches);
          end for;
        then
          matches;

      case Absyn.ClassPart.EQUATIONS()
        algorithm
          for e in part.contents loop
            matches := lookupInEquationItem(e, paths, exactMatch, matches);
          end for;
        then
          matches;

      case Absyn.ClassPart.INITIALEQUATIONS()
        algorithm
          for e in part.contents loop
            matches := lookupInEquationItem(e, paths, exactMatch, matches);
          end for;
        then
          matches;

      case Absyn.ClassPart.ALGORITHMS()
        algorithm
          for alg in part.contents loop
            matches := lookupInAlgorithmItem(alg, paths, exactMatch, matches);
          end for;
        then
          matches;

      case Absyn.ClassPart.INITIALALGORITHMS()
        algorithm
          for alg in part.contents loop
            matches := lookupInAlgorithmItem(alg, paths, exactMatch, matches);
          end for;
        then
          matches;

      case Absyn.ClassPart.EXTERNAL()
        algorithm
          matches := lookupInExternalDecl(part.externalDecl, paths, exactMatch, info, matches);

          if isSome(part.annotation_) then
            matches := lookupInAnnotation(Util.getOption(part.annotation_), paths, exactMatch, matches);
          end if;
        then
          matches;

      else matches;
    end match;
  end lookupInClassPart;

  function lookupInEnumDef
    input Absyn.EnumDef enumDef;
    input Paths paths;
    input Boolean exactMatch;
    input output Matches matches;
  algorithm
    matches := match enumDef
      case Absyn.EnumDef.ENUMLITERALS()
        algorithm
          for lit in enumDef.enumLiterals loop
            matches := lookupInCommentOpt(lit.comment, paths, exactMatch, matches);
          end for;
        then
          matches;

      else matches;
    end match;
  end lookupInEnumDef;

  function lookupInCommentOpt
    input Option<Absyn.Comment> cmt;
    input Paths paths;
    input Boolean exactMatch;
    input output Matches matches;
  algorithm
    if isSome(cmt) then
      matches := lookupInComment(Util.getOption(cmt), paths, exactMatch, matches);
    end if;
  end lookupInCommentOpt;

  function lookupInComment
    input Absyn.Comment cmt;
    input Paths paths;
    input Boolean exactMatch;
    input output Matches matches;
  algorithm
    if isSome(cmt.annotation_) then
      matches := lookupInAnnotation(Util.getOption(cmt.annotation_), paths, exactMatch, matches);
    end if;
  end lookupInComment;

  function lookupInAnnotation
    input Absyn.Annotation ann;
    input Paths paths;
    input Boolean exactMatch;
    input output Matches matches;
  algorithm
    for arg in ann.elementArgs loop
      matches := lookupInElementArg(arg, paths, exactMatch, matches);
    end for;
  end lookupInAnnotation;

  function lookupInElementArg
    input Absyn.ElementArg arg;
    input Paths paths;
    input Boolean exactMatch;
    input output Matches matches;
  algorithm
    matches := match arg
      case Absyn.ElementArg.MODIFICATION()
        algorithm
          if isSome(arg.modification) then
            matches := lookupInModification(Util.getOption(arg.modification), paths, exactMatch, matches);
          end if;
        then
          matches;

      case Absyn.ElementArg.REDECLARATION()
        algorithm
          matches := lookupInElementSpec(arg.elementSpec, paths, exactMatch, arg.info, matches);

          if isSome(arg.constrainClass) then
            matches := lookupInConstrainClass(Util.getOption(arg.constrainClass), paths, exactMatch, arg.info, matches);
          end if;
        then
          matches;

      else matches;
    end match;
  end lookupInElementArg;

  function lookupInModification
    input Absyn.Modification mod;
    input Paths paths;
    input Boolean exactMatch;
    input output Matches matches;
  algorithm
    for arg in mod.elementArgLst loop
      matches := lookupInElementArg(arg, paths, exactMatch, matches);
    end for;

    matches := lookupInEqMod(mod.eqMod, paths, exactMatch, matches);
  end lookupInModification;

  function lookupInEqMod
    input Absyn.EqMod eqMod;
    input Paths paths;
    input Boolean exactMatch;
    input output Matches matches;
  algorithm
    matches := match eqMod
      case Absyn.EqMod.EQMOD()
        then lookupInExp(eqMod.exp, paths, exactMatch, eqMod.info, matches);
      else matches;
    end match;
  end lookupInEqMod;

  function lookupInExp
    input Absyn.Exp exp;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    matches := match exp
      case Absyn.Exp.CREF() then matchCref(exp.componentRef, paths, exactMatch, info, matches);
      case Absyn.Exp.BINARY()
        algorithm
          matches := lookupInExp(exp.exp1, paths, exactMatch, info, matches);
        then
          lookupInExp(exp.exp2, paths, exactMatch, info, matches);

      case Absyn.Exp.UNARY()
        then lookupInExp(exp.exp, paths, exactMatch, info, matches);

      case Absyn.Exp.LBINARY()
        algorithm
          matches := lookupInExp(exp.exp1, paths, exactMatch, info, matches);
        then
          lookupInExp(exp.exp2, paths, exactMatch, info, matches);

      case Absyn.Exp.LUNARY()
        then lookupInExp(exp.exp, paths, exactMatch, info, matches);

      case Absyn.Exp.IFEXP()
        algorithm
          matches := lookupInExp(exp.ifExp, paths, exactMatch, info, matches);
          matches := lookupInExp(exp.trueBranch, paths, exactMatch, info, matches);
          matches := lookupInExp(exp.elseBranch, paths, exactMatch, info, matches);

          for branch in exp.elseIfBranch loop
            matches := lookupInExp(Util.tuple21(branch), paths, exactMatch, info, matches);
            matches := lookupInExp(Util.tuple22(branch), paths, exactMatch, info, matches);
          end for;
        then
          matches;

      case Absyn.Exp.CALL()
        algorithm
          matches := matchCref(exp.function_, paths, exactMatch, info, matches);
        then
          lookupInFunctionArgs(exp.functionArgs, paths, exactMatch, info, matches);

      case Absyn.Exp.PARTEVALFUNCTION()
        algorithm
          matches := matchCref(exp.function_, paths, exactMatch, info, matches);
        then
          lookupInFunctionArgs(exp.functionArgs, paths, exactMatch, info, matches);

      case Absyn.Exp.ARRAY()
        algorithm
          for e in exp.arrayExp loop
            matches := lookupInExp(e, paths, exactMatch, info, matches);
          end for;
        then
          matches;

      case Absyn.Exp.MATRIX()
        algorithm
          for row in exp.matrix loop
            for e in row loop
              matches := lookupInExp(e, paths, exactMatch, info, matches);
            end for;
          end for;
        then
          matches;

      case Absyn.Exp.RANGE()
        algorithm
          matches := lookupInExp(exp.start, paths, exactMatch, info, matches);

          if isSome(exp.step) then
            matches := lookupInExp(Util.getOption(exp.step), paths, exactMatch, info, matches);
          end if;

        then
          lookupInExp(exp.stop, paths, exactMatch, info, matches);

      case Absyn.Exp.TUPLE()
        algorithm
          for e in exp.expressions loop
            matches := lookupInExp(e, paths, exactMatch, info, matches);
          end for;
        then
          matches;

      case Absyn.Exp.EXPRESSIONCOMMENT()
        then lookupInExp(exp.exp, paths, exactMatch, info, matches);

      case Absyn.Exp.SUBSCRIPTED_EXP()
        algorithm
          matches := lookupInExp(exp.exp, paths, exactMatch, info, matches);
        then
          lookupInSubscripts(exp.subscripts, paths, exactMatch, info, matches);

      else matches;
    end match;
  end lookupInExp;

  function lookupInCref
    input Absyn.ComponentRef cref;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    matches := matchCref(cref, paths, exactMatch, info, matches);
    matches := lookupInCrefSubs(cref, paths, exactMatch, info, matches);
  end lookupInCref;

  function lookupInCrefSubs
    input Absyn.ComponentRef cref;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    matches := match cref
      case Absyn.ComponentRef.CREF_IDENT()
        then lookupInSubscripts(cref.subscripts, paths, exactMatch, info, matches);

      case Absyn.ComponentRef.CREF_QUAL()
        algorithm
          matches := lookupInSubscripts(cref.subscripts, paths, exactMatch, info, matches);
        then
          lookupInCrefSubs(cref.componentRef, paths, exactMatch, info, matches);

      case Absyn.ComponentRef.CREF_FULLYQUALIFIED()
        then lookupInCrefSubs(cref.componentRef, paths, exactMatch, info, matches);

      else matches;
    end match;
  end lookupInCrefSubs;

  function lookupInSubscripts
    input list<Absyn.Subscript> subs;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    for sub in subs loop
      matches := lookupInSubscript(sub, paths, exactMatch, info, matches);
    end for;
  end lookupInSubscripts;

  function lookupInSubscript
    input Absyn.Subscript sub;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    matches := match sub
      case Absyn.Subscript.SUBSCRIPT() then lookupInExp(sub.subscript, paths, exactMatch, info, matches);
      else matches;
    end match;
  end lookupInSubscript;

  function lookupInFunctionArgs
    input Absyn.FunctionArgs args;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    matches := match args
      case Absyn.FunctionArgs.FUNCTIONARGS()
        algorithm
          for arg in args.args loop
            matches := lookupInExp(arg, paths, exactMatch, info, matches);
          end for;

          for named_arg in args.argNames loop
            matches := lookupInExp(named_arg.argValue, paths, exactMatch, info, matches);
          end for;
        then
          matches;

      case Absyn.FunctionArgs.FOR_ITER_FARG()
        algorithm
          matches := lookupInExp(args.exp, paths, exactMatch, info, matches);
          matches := lookupInForIterators(args.iterators, paths, exactMatch, info, matches);
        then
          matches;

    end match;
  end lookupInFunctionArgs;

  function lookupInForIterators
    input Absyn.ForIterators iterators;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    for i in iterators loop
      if isSome(i.range) then
        matches := lookupInExp(Util.getOption(i.range), paths, exactMatch, info, matches);
      end if;
    end for;
  end lookupInForIterators;

  function lookupInElementItem
    input Absyn.ElementItem item;
    input Paths paths;
    input Boolean exactMatch;
    input output Matches matches;
  algorithm
    matches := match item
      case Absyn.ElementItem.ELEMENTITEM() then lookupInElement(item.element, paths, exactMatch, matches);
      else matches;
    end match;
  end lookupInElementItem;

  function lookupInElement
    input Absyn.Element element;
    input Paths paths;
    input Boolean exactMatch;
    input output Matches matches;
  algorithm
    matches := match element
      case Absyn.Element.ELEMENT()
        algorithm
          matches := lookupInElementSpec(element.specification, paths, exactMatch, element.info, matches);

          if isSome(element.constrainClass) then
            matches := lookupInConstrainClass(Util.getOption(element.constrainClass), paths, exactMatch, element.info, matches);
          end if;
        then
          matches;

      else matches;
    end match;
  end lookupInElement;

  function lookupInElementSpec
    input Absyn.ElementSpec spec;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    matches := match spec
      case Absyn.ElementSpec.CLASSDEF() then lookupInClass(spec.class_, paths, exactMatch, matches);
      case Absyn.ElementSpec.EXTENDS()
        algorithm
          matches := matchPath(spec.path, paths, exactMatch, info, matches);

          for arg in spec.elementArg loop
            matches := lookupInElementArg(arg, paths, exactMatch, matches);
          end for;

          if isSome(spec.annotationOpt) then
            matches := lookupInAnnotation(Util.getOption(spec.annotationOpt), paths, exactMatch, matches);
          end if;
        then
          matches;

      case Absyn.ElementSpec.IMPORT()
        algorithm
          matches := lookupInImport(spec.import_, paths, exactMatch, info, matches);
        then
          matches;

      case Absyn.ElementSpec.COMPONENTS()
        algorithm
          matches := lookupInTypeSpec(spec.typeSpec, paths, exactMatch, info, matches);

          for c in spec.components loop
            matches := lookupInComponentItem(c, paths, exactMatch, info, matches);
          end for;
        then
          matches;

    end match;
  end lookupInElementSpec;

  function lookupInConstrainClass
    input Absyn.ConstrainClass constrainClass;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    matches := lookupInElementSpec(constrainClass.elementSpec, paths, exactMatch, info, matches);
  end lookupInConstrainClass;

  function lookupInImport
    input Absyn.Import imp;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    matches := match imp
      case Absyn.Import.NAMED_IMPORT()
        then matchPath(imp.path, paths, exactMatch, info, matches);

      case Absyn.Import.QUAL_IMPORT()
        then matchPath(imp.path, paths, exactMatch, info, matches);

      case Absyn.Import.UNQUAL_IMPORT()
        then matchPath(imp.path, paths, exactMatch, info, matches);

      case Absyn.Import.GROUP_IMPORT()
        then matchPath(imp.prefix, paths, exactMatch, info, matches);
    end match;
  end lookupInImport;

  function lookupInComponentItem
    input Absyn.ComponentItem item;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    matches := lookupInComponent(item.component, paths, exactMatch, info, matches);

    if isSome(item.condition) then
      matches := lookupInExp(Util.getOption(item.condition), paths, exactMatch, info, matches);
    end if;
  end lookupInComponentItem;

  function lookupInComponent
    input Absyn.Component component;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    matches := lookupInSubscripts(component.arrayDim, paths, exactMatch, info, matches);

    if isSome(component.modification) then
      matches := lookupInModification(Util.getOption(component.modification), paths, exactMatch, matches);
    end if;
  end lookupInComponent;

  function lookupInTypeSpec
    input Absyn.TypeSpec typeSpec;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    matches := match typeSpec
      case Absyn.TypeSpec.TPATH()
        algorithm
          matches := matchPath(typeSpec.path, paths, exactMatch, info, matches);

          if isSome(typeSpec.arrayDim) then
            matches := lookupInSubscripts(Util.getOption(typeSpec.arrayDim), paths, exactMatch, info, matches);
          end if;
        then
          matches;

      else matches;
    end match;
  end lookupInTypeSpec;

  function lookupInEquationItems
    input list<Absyn.EquationItem> items;
    input Paths paths;
    input Boolean exactMatch;
    input output Matches matches;
  algorithm
    for item in items loop
      matches := lookupInEquationItem(item, paths, exactMatch, matches);
    end for;
  end lookupInEquationItems;

  function lookupInEquationItem
    input Absyn.EquationItem item;
    input Paths paths;
    input Boolean exactMatch;
    input output Matches matches;
  algorithm
    matches := match item
      case Absyn.EquationItem.EQUATIONITEM()
        algorithm
          matches := lookupInEquation(item.equation_, paths, exactMatch, item.info, matches);
        then
          lookupInCommentOpt(item.comment, paths, exactMatch, matches);

      else matches;
    end match;
  end lookupInEquationItem;

  function lookupInEquation
    input Absyn.Equation eq;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    () := match eq
      case Absyn.Equation.EQ_IF()
        algorithm
          matches := lookupInExp(eq.ifExp, paths, exactMatch, info, matches);
          matches := lookupInEquationItems(eq.equationTrueItems, paths, exactMatch, matches);

          for branch in eq.elseIfBranches loop
            matches := lookupInExp(Util.tuple21(branch), paths, exactMatch, info, matches);
            matches := lookupInEquationItems(Util.tuple22(branch), paths, exactMatch, matches);
          end for;

          matches := lookupInEquationItems(eq.equationElseItems, paths, exactMatch, matches);
        then
          ();

      case Absyn.Equation.EQ_EQUALS()
        algorithm
          matches := lookupInExp(eq.leftSide, paths, exactMatch, info, matches);
          matches := lookupInExp(eq.rightSide, paths, exactMatch, info, matches);
        then
          ();

      case Absyn.Equation.EQ_PDE()
        algorithm
          matches := lookupInExp(eq.leftSide, paths, exactMatch, info, matches);
          matches := lookupInExp(eq.rightSide, paths, exactMatch, info, matches);
        then
          ();

      case Absyn.Equation.EQ_CONNECT()
        algorithm
          matches := lookupInCref(eq.connector1, paths, exactMatch, info, matches);
          matches := lookupInCref(eq.connector2, paths, exactMatch, info, matches);
        then
          ();

      case Absyn.Equation.EQ_FOR()
        algorithm
          matches := lookupInForIterators(eq.iterators, paths, exactMatch, info, matches);
          matches := lookupInEquationItems(eq.forEquations, paths, exactMatch, matches);
        then
          ();

      case Absyn.Equation.EQ_WHEN_E()
        algorithm
          matches := lookupInExp(eq.whenExp, paths, exactMatch, info, matches);
          matches := lookupInEquationItems(eq.whenEquations, paths, exactMatch, matches);

          for branch in eq.elseWhenEquations loop
            matches := lookupInExp(Util.tuple21(branch), paths, exactMatch, info, matches);
            matches := lookupInEquationItems(Util.tuple22(branch), paths, exactMatch, matches);
          end for;
        then
          ();

      case Absyn.Equation.EQ_NORETCALL()
        algorithm
          matches := lookupInCref(eq.functionName, paths, exactMatch, info, matches);
          matches := lookupInFunctionArgs(eq.functionArgs, paths, exactMatch, info, matches);
        then
          ();

      else ();
    end match;
  end lookupInEquation;

  function lookupInAlgorithmItems
    input list<Absyn.AlgorithmItem> items;
    input Paths paths;
    input Boolean exactMatch;
    input output Matches matches;
  algorithm
    for item in items loop
      matches := lookupInAlgorithmItem(item, paths, exactMatch, matches);
    end for;
  end lookupInAlgorithmItems;

  function lookupInAlgorithmItem
    input Absyn.AlgorithmItem item;
    input Paths paths;
    input Boolean exactMatch;
    input output Matches matches;
  algorithm
    matches := match item
      case Absyn.AlgorithmItem.ALGORITHMITEM()
        algorithm
          matches := lookupInAlgorithm(item.algorithm_, paths, exactMatch, item.info, matches);
          matches := lookupInCommentOpt(item.comment, paths, exactMatch, matches);
        then
          matches;

      else matches;
    end match;
  end lookupInAlgorithmItem;

  function lookupInAlgorithm
    input Absyn.Algorithm alg;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    () := match alg
      case Absyn.Algorithm.ALG_ASSIGN()
        algorithm
          matches := lookupInExp(alg.assignComponent, paths, exactMatch, info, matches);
          matches := lookupInExp(alg.value, paths, exactMatch, info, matches);
        then
          ();

      case Absyn.Algorithm.ALG_IF()
        algorithm
          matches := lookupInExp(alg.ifExp, paths, exactMatch, info, matches);
          matches := lookupInAlgorithmItems(alg.trueBranch, paths, exactMatch, matches);

          for branch in alg.elseIfAlgorithmBranch loop
            matches := lookupInExp(Util.tuple21(branch), paths, exactMatch, info, matches);
            matches := lookupInAlgorithmItems(Util.tuple22(branch), paths, exactMatch, matches);
          end for;

          matches := lookupInAlgorithmItems(alg.elseBranch, paths, exactMatch, matches);
        then
          ();

      case Absyn.Algorithm.ALG_FOR()
        algorithm
          matches := lookupInForIterators(alg.iterators, paths, exactMatch, info, matches);
          matches := lookupInAlgorithmItems(alg.forBody, paths, exactMatch, matches);
        then
          ();

      case Absyn.Algorithm.ALG_PARFOR()
        algorithm
          matches := lookupInForIterators(alg.iterators, paths, exactMatch, info, matches);
          matches := lookupInAlgorithmItems(alg.parforBody, paths, exactMatch, matches);
        then
          ();

      case Absyn.Algorithm.ALG_WHILE()
        algorithm
          matches := lookupInExp(alg.boolExpr, paths, exactMatch, info, matches);
          matches := lookupInAlgorithmItems(alg.whileBody, paths, exactMatch, matches);
        then
          ();

      case Absyn.Algorithm.ALG_WHEN_A()
        algorithm
          matches := lookupInExp(alg.boolExpr, paths, exactMatch, info, matches);
          matches := lookupInAlgorithmItems(alg.whenBody, paths, exactMatch, matches);

          for branch in alg.elseWhenAlgorithmBranch loop
            matches := lookupInExp(Util.tuple21(branch), paths, exactMatch, info, matches);
            matches := lookupInAlgorithmItems(Util.tuple22(branch), paths, exactMatch, matches);
          end for;
        then
          ();

      case Absyn.Algorithm.ALG_NORETCALL()
        algorithm
          matches := lookupInCref(alg.functionCall, paths, exactMatch, info, matches);
          matches := lookupInFunctionArgs(alg.functionArgs, paths, exactMatch, info, matches);
        then
          ();

      else ();
    end match;
  end lookupInAlgorithm;

  function lookupInExternalDecl
    input Absyn.ExternalDecl extDecl;
    input Paths paths;
    input Boolean exactMatch;
    input SourceInfo info;
    input output Matches matches;
  algorithm
    for arg in extDecl.args loop
      matches := lookupInExp(arg, paths, exactMatch, info, matches);
    end for;

    if isSome(extDecl.annotation_) then
      matches := lookupInAnnotation(Util.getOption(extDecl.annotation_), paths, exactMatch, matches);
    end if;
  end lookupInExternalDecl;

  function serializeMatches
    input Matches matches;
    input Boolean prettyPrint;
    output String str;
  protected
    list<JSON> json_elems = {};
    JSON json_elem;
  algorithm
    for m in matches loop
      json_elem := NFApi.dumpJSONSourceInfo(m.info);
      json_elem := JSON.addPair("name", JSON.makeString(Dump.printComponentRefStr(m.name)), json_elem);
      json_elems := json_elem :: json_elems;
    end for;

    str := JSON.toString(JSON.makeArray(json_elems), prettyPrint);
  end serializeMatches;

  annotation(__OpenModelica_Interface="backend");
end ReverseLookup;
