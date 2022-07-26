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

encapsulated package TotalModelDebug
  "Implements a simple heuristic based on which identifiers are used in a class,
   that can be used instead of the usual instantiation-based saveTotalModel when
   that approach fails."

  import Absyn;
  import SCode;

protected
  import AbsynUtil;
  import SCodeUtil;
  import UnorderedSet;
  import Util;
  import MetaModelica.Dangerous.*;

  type UseTable = UnorderedSet<String>;

public
  function getTotalModel
    input output SCode.Program program;
    input Absyn.Path classPath;
  protected
    UseTable used;
    Integer prev_size = 0;
  algorithm
    // Create a new table and add each identifier in the path of the class.
    used := UnorderedSet.new(stringHashDjb2Mod, stringEq);
    analysePath(classPath, used);

    // Add some identifiers which can be implicitly used.
    UnorderedSet.add("constructor", used);
    UnorderedSet.add("destructor", used);

    // Go through the program and add identifiers used in classes that are in
    // the table. Repeat this until no more new identifiers are found.
    while UnorderedSet.size(used) <> prev_size loop
      prev_size := UnorderedSet.size(used);
      analyseProgram(program, used);
    end while;

    // Save all classes whose name is in the table.
    program := saveElements(program, used);
  end getTotalModel;

  function analyseProgram
    input SCode.Program program;
    input UseTable used;
  algorithm
    for e in program loop
      analyseElement(e, used);
    end for;
  end analyseProgram;

  function analyseElements
    input list<SCode.Element> elements;
    input UseTable used;
  algorithm
    for e in elements loop
      analyseElement(e, used);
    end for;
  end analyseElements;

  function analyseElement
    input SCode.Element element;
    input UseTable used;
  algorithm
    () := match element
      case SCode.Element.IMPORT()
        algorithm
          analyseImport(element.imp, used);
        then
          ();

      case SCode.Element.EXTENDS()
        algorithm
          analysePath(element.baseClassPath, used);
          analyseMod(element.modifications, used);
        then
          ();

      case SCode.Element.CLASS()
        guard UnorderedSet.contains(element.name, used)
        algorithm
          if SCodeUtil.isOperatorRecord(element) then
            analyseOperatorRecord(element, used);
          end if;

          analyseClassDef(element.classDef, used);
          analysePrefixes(element.prefixes, used);
          analyseComment(element.cmt, used);
        then
          ();

      case SCode.Element.COMPONENT()
        algorithm
          analysePrefixes(element.prefixes, used);
          analyseAttributes(element.attributes, used);
          analyseTypeSpec(element.typeSpec, used);
          analyseMod(element.modifications, used);
          analyseExpOpt(element.condition, used);
          analyseComment(element.comment, used);
        then
          ();

      else ();
    end match;
  end analyseElement;

  function analyseImport
    input Absyn.Import imp;
    input UseTable used;
  algorithm
    analysePath(AbsynUtil.importPath(imp), used);
  end analyseImport;

  function analyseClassDef
    input SCode.ClassDef def;
    input UseTable used;
  algorithm
    () := match def
      case SCode.ClassDef.PARTS()
        algorithm
          analyseElements(def.elementLst, used);
          analyseEquations(def.normalEquationLst, used);
          analyseEquations(def.initialEquationLst, used);
          analyseAlgorithms(def.normalAlgorithmLst, used);
          analyseAlgorithms(def.initialAlgorithmLst, used);

          if isSome(def.externalDecl) then
            analyseExternalDecl(Util.getOption(def.externalDecl), used);
          end if;
        then
          ();

      case SCode.ClassDef.CLASS_EXTENDS()
        algorithm
          analyseMod(def.modifications, used);
          analyseClassDef(def.composition, used);
        then
          ();

      case SCode.ClassDef.DERIVED()
        algorithm
          analyseTypeSpec(def.typeSpec, used);
          analyseMod(def.modifications, used);
          analyseAttributes(def.attributes, used);
        then
          ();

      else ();
    end match;
  end analyseClassDef;

  function analyseExternalDecl
    input SCode.ExternalDecl extDecl;
    input UseTable used;
  algorithm
    if isSome(extDecl.annotation_) then
      analyseAnnotation(Util.getOption(extDecl.annotation_), used);
    end if;
  end analyseExternalDecl;

  function analyseOperatorRecord
    input SCode.Element element;
    input UseTable used;
  algorithm
    () := match element
      case SCode.Element.CLASS()
        algorithm
          UnorderedSet.add(element.name, used);

          for e in SCodeUtil.getClassElements(element) loop
            analyseOperatorRecord(e, used);
          end for;
        then
          ();

      else ();
    end match;
  end analyseOperatorRecord;

  function analyseAttributes
    input SCode.Attributes attributes;
    input UseTable used;
  algorithm
    analyseDims(attributes.arrayDims, used);
  end analyseAttributes;

  function analysePrefixes
    input SCode.Prefixes prefixes;
    input UseTable used;
  algorithm
    analyseReplaceable(prefixes.replaceablePrefix, used);
  end analysePrefixes;

  function analyseReplaceable
    input SCode.Replaceable repl;
    input UseTable used;
  protected
    SCode.ConstrainClass cc;
  algorithm
    () := match repl
      case SCode.Replaceable.REPLACEABLE(cc = SOME(cc))
        algorithm
          analyseConstrainClass(cc, used);
        then
          ();

      else ();
    end match;
  end analyseReplaceable;

  function analyseConstrainClass
    input SCode.ConstrainClass cc;
    input UseTable used;
  algorithm
    analysePath(cc.constrainingClass, used);
    analyseMod(cc.modifier, used);
    analyseComment(cc.comment, used);
  end analyseConstrainClass;

  function analyseMod
    input SCode.Mod mod;
    input UseTable used;
  algorithm
    () := match mod
      case SCode.Mod.MOD()
        algorithm
          for s in mod.subModLst loop
            analyseMod(s.mod, used);
          end for;

          analyseExpOpt(mod.binding, used);
        then
          ();

      case SCode.Mod.REDECL()
        algorithm
          analyseElement(mod.element, used);
        then
          ();

      else ();
    end match;
  end analyseMod;

  function analyseTypeSpec
    input Absyn.TypeSpec ty;
    input UseTable used;
  algorithm
    () := match ty
      case Absyn.TypeSpec.TPATH()
        algorithm
          analysePath(ty.path, used);

          if isSome(ty.arrayDim) then
            analyseDims(Util.getOption(ty.arrayDim), used);
          end if;
        then
          ();

      case Absyn.TypeSpec.TCOMPLEX()
        algorithm
          analysePath(ty.path, used);

          for t in ty.typeSpecs loop
            analyseTypeSpec(t, used);
          end for;

          if isSome(ty.arrayDim) then
            analyseDims(Util.getOption(ty.arrayDim), used);
          end if;
        then
          ();
    end match;
  end analyseTypeSpec;

  function analysePath
    input Absyn.Path path;
    input UseTable used;
  algorithm
    for i in AbsynUtil.pathToStringList(path) loop
      UnorderedSet.add(i, used);
    end for;
  end analysePath;

  function analyseEquations
    input list<SCode.Equation> eqs;
    input UseTable used;
  algorithm
    for e in eqs loop
      analyseEquation(e, used);
    end for;
  end analyseEquations;

  function analyseEquation
    input SCode.Equation eq;
    input UseTable used;
  algorithm
    () := match eq
      case SCode.Equation.EQ_IF()
        algorithm
          analyseExpList(eq.condition, used);

          for b in eq.thenBranch loop
            analyseEquations(b, used);
          end for;

          analyseEquations(eq.elseBranch, used);
          analyseComment(eq.comment, used);
        then
          ();

      case SCode.Equation.EQ_EQUALS()
        algorithm
          analyseExp(eq.expLeft, used);
          analyseExp(eq.expRight, used);
          analyseComment(eq.comment, used);
        then
          ();

      case SCode.Equation.EQ_PDE()
        algorithm
          analyseExp(eq.expLeft, used);
          analyseExp(eq.expRight, used);
          analyseComment(eq.comment, used);
        then
          ();

      case SCode.Equation.EQ_CONNECT()
        algorithm
          analyseCref(eq.crefLeft, used);
          analyseCref(eq.crefRight, used);
          analyseComment(eq.comment, used);
        then
          ();

      case SCode.Equation.EQ_FOR()
        algorithm
          analyseExpOpt(eq.range, used);
          analyseEquations(eq.eEquationLst, used);
          analyseComment(eq.comment, used);
        then
          ();

      case SCode.Equation.EQ_WHEN()
        algorithm
          analyseExp(eq.condition, used);
          analyseEquations(eq.eEquationLst, used);

          for b in eq.elseBranches loop
            analyseExp(Util.tuple21(b), used);
            analyseEquations(Util.tuple22(b), used);
          end for;

          analyseComment(eq.comment, used);
        then
          ();

      case SCode.Equation.EQ_ASSERT()
        algorithm
          analyseExp(eq.condition, used);
          analyseExp(eq.message, used);
          analyseExp(eq.level, used);
          analyseComment(eq.comment, used);
        then
          ();

      case SCode.Equation.EQ_TERMINATE()
        algorithm
          analyseExp(eq.message, used);
          analyseComment(eq.comment, used);
        then
          ();

      case SCode.Equation.EQ_REINIT()
        algorithm
          analyseExp(eq.cref, used);
          analyseExp(eq.expReinit, used);
          analyseComment(eq.comment, used);
        then
          ();

      case SCode.Equation.EQ_NORETCALL()
        algorithm
          analyseExp(eq.exp, used);
          analyseComment(eq.comment, used);
        then
          ();
    end match;
  end analyseEquation;

  function analyseAlgorithms
    input list<SCode.AlgorithmSection> algs;
    input UseTable used;
  algorithm
    for a in algs loop
      analyseAlgorithm(a, used);
    end for;
  end analyseAlgorithms;

  function analyseAlgorithm
    input SCode.AlgorithmSection alg;
    input UseTable used;
  algorithm
    analyseStatements(alg.statements, used);
  end analyseAlgorithm;

  function analyseStatements
    input list<SCode.Statement> stmts;
    input UseTable used;
  algorithm
    for s in stmts loop
      analyseStatement(s, used);
    end for;
  end analyseStatements;

  function analyseStatement
    input SCode.Statement stmt;
    input UseTable used;
  algorithm
    () := match stmt
      case SCode.Statement.ALG_ASSIGN()
        algorithm
          analyseExp(stmt.assignComponent, used);
          analyseExp(stmt.value, used);
          analyseComment(stmt.comment, used);
        then
          ();

      case SCode.Statement.ALG_IF()
        algorithm
          analyseExp(stmt.boolExpr, used);
          analyseStatements(stmt.trueBranch, used);

          for b in stmt.elseIfBranch loop
            analyseExp(Util.tuple21(b), used);
            analyseStatements(Util.tuple22(b), used);
          end for;

          analyseStatements(stmt.elseBranch, used);
          analyseComment(stmt.comment, used);
        then
          ();

      case SCode.Statement.ALG_FOR()
        algorithm
          analyseExpOpt(stmt.range, used);
          analyseStatements(stmt.forBody, used);
          analyseComment(stmt.comment, used);
        then
          ();

      case SCode.Statement.ALG_PARFOR()
        algorithm
          analyseExpOpt(stmt.range, used);
          analyseStatements(stmt.parforBody, used);
          analyseComment(stmt.comment, used);
        then
          ();

      case SCode.Statement.ALG_WHILE()
        algorithm
          analyseExp(stmt.boolExpr, used);
          analyseStatements(stmt.whileBody, used);
          analyseComment(stmt.comment, used);
        then
          ();

      case SCode.Statement.ALG_WHEN_A()
        algorithm
          for b in stmt.branches loop
            analyseExp(Util.tuple21(b), used);
            analyseStatements(Util.tuple22(b), used);
          end for;

          analyseComment(stmt.comment, used);
        then
          ();

      case SCode.Statement.ALG_ASSERT()
        algorithm
          analyseExp(stmt.condition, used);
          analyseExp(stmt.message, used);
          analyseExp(stmt.level, used);
          analyseComment(stmt.comment, used);
        then
          ();

      case SCode.Statement.ALG_TERMINATE()
        algorithm
          analyseExp(stmt.message, used);
          analyseComment(stmt.comment, used);
        then
          ();

      case SCode.Statement.ALG_REINIT()
        algorithm
          analyseExp(stmt.cref, used);
          analyseExp(stmt.newValue, used);
          analyseComment(stmt.comment, used);
        then
          ();

      case SCode.Statement.ALG_NORETCALL()
        algorithm
          analyseExp(stmt.exp, used);
          analyseComment(stmt.comment, used);
        then
          ();

      case SCode.Statement.ALG_RETURN()
        algorithm
          analyseComment(stmt.comment, used);
        then
          ();

      case SCode.Statement.ALG_BREAK()
        algorithm
          analyseComment(stmt.comment, used);
        then
          ();

      case SCode.Statement.ALG_CONTINUE()
        algorithm
          analyseComment(stmt.comment, used);
        then
          ();

      else ();
    end match;
  end analyseStatement;

  function analyseDims = analyseSubscripts;

  function analyseSubscripts
    input list<Absyn.Subscript> subs;
    input UseTable used;
  algorithm
    for s in subs loop
      analyseSubscript(s, used);
    end for;
  end analyseSubscripts;

  function analyseSubscript
    input Absyn.Subscript sub;
    input UseTable used;
  algorithm
    () := match sub
      case Absyn.Subscript.SUBSCRIPT()
        algorithm
          analyseExp(sub.subscript, used);
        then
          ();

      else ();
    end match;
  end analyseSubscript;

  function analyseExpOpt
    input Option<Absyn.Exp> exp;
    input UseTable used;
  algorithm
    if isSome(exp) then
      analyseExp(Util.getOption(exp), used);
    end if;
  end analyseExpOpt;

  function analyseExpList
    input list<Absyn.Exp> expl;
    input UseTable used;
  algorithm
    for e in expl loop
      analyseExp(e, used);
    end for;
  end analyseExpList;

  function analyseExp
    input Absyn.Exp exp;
    input UseTable used;
  algorithm
    AbsynUtil.traverseExp(exp, analyseExpTraverse, used);
  end analyseExp;

  function analyseExpTraverse
    input output Absyn.Exp exp;
    input output UseTable used;
  algorithm
    () := match exp
      case Absyn.Exp.CREF()
        algorithm
          analyseCref(exp.componentRef, used);
        then
          ();

      case Absyn.Exp.CALL()
        algorithm
          analyseCref(exp.function_, used);
        then
          ();

      case Absyn.Exp.PARTEVALFUNCTION()
        algorithm
          analyseCref(exp.function_, used);
        then
          ();

      else ();
    end match;
  end analyseExpTraverse;

  function analyseCref
    input Absyn.ComponentRef cref;
    input UseTable used;
    input Boolean includeLast = true;
  algorithm
    () := match cref
      case Absyn.ComponentRef.CREF_FULLYQUALIFIED()
        algorithm
          analyseCref(cref.componentRef, used, includeLast);
        then
          ();

      case Absyn.ComponentRef.CREF_QUAL()
        algorithm
          UnorderedSet.add(cref.name, used);
          analyseSubscripts(cref.subscripts, used);
          analyseCref(cref.componentRef, used, includeLast);
        then
          ();

      case Absyn.ComponentRef.CREF_IDENT()
        algorithm
          if includeLast then
            UnorderedSet.add(cref.name, used);
          end if;

          analyseSubscripts(cref.subscripts, used);
        then
          ();

      else ();
    end match;
  end analyseCref;

  function analyseComment
    input SCode.Comment comment;
    input UseTable used;
  algorithm
    if isSome(comment.annotation_) then
      analyseAnnotation(Util.getOption(comment.annotation_), used);
    end if;
  end analyseComment;

  function analyseAnnotation
    input SCode.Annotation ann;
    input UseTable used;
  algorithm
    analyseMod(ann.modification, used);
  end analyseAnnotation;

  function saveElements
    input list<SCode.Element> elements;
    input UseTable used;
    output list<SCode.Element> outElements = {};
  algorithm
    for e in elements loop
      outElements := saveElement(e, used, outElements);
    end for;

    outElements := listReverseInPlace(outElements);
  end saveElements;

  function saveElement
    input SCode.Element element;
    input UseTable used;
    input output list<SCode.Element> elements;
  protected
    SCode.Element elem = element;
    Boolean is_empty;
  algorithm
    elements := match elem
      case SCode.Element.CLASS()
        guard UnorderedSet.contains(elem.name, used)
        algorithm
          elem.classDef := saveClassDef(elem.classDef, used);
        then
          elem :: elements;

      case SCode.Element.CLASS() then elements;

      case SCode.Element.EXTENDS()
        guard AbsynUtil.pathContains(elem.baseClassPath, "Icons")
        then elements;

      else element :: elements;
    end match;
  end saveElement;

  function saveClassDef
    input output SCode.ClassDef def;
    input UseTable used;
  algorithm
    () := match def
      case SCode.ClassDef.PARTS()
        algorithm
          def.elementLst := saveElements(def.elementLst, used);
        then
          ();

      case SCode.ClassDef.CLASS_EXTENDS()
        algorithm
          def.composition := saveClassDef(def.composition, used);
        then
          ();

      else ();
    end match;
  end saveClassDef;

  annotation(__OpenModelica_Interface="backend");
end TotalModelDebug;
