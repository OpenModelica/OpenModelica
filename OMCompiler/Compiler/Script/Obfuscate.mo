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

encapsulated package Obfuscate
  import Absyn;
  import AbsynUtil;
  import Dump;
  import FBuiltin;
  import SCode;
  import SCodeUtil;
  import System;
  import UnorderedMap;
  import Util;

  type Mapping = UnorderedMap<String, String>;
  type Builtins = UnorderedMap<String, ElementType>;

  // Most builtin elements are not reserved keywords and can be shadowed by
  // user elements. To try and avoid issues when we have e.g. a component named
  // abs we keep track of what types of builtin elements we have and what type
  // of element we're looking for with this enumeration.
  type ElementType = enumeration(
    TYPE,
    FUNCTION,
    TYPE_AND_FUNCTION,
    OTHER
  );

  uniontype Env
    record ENV
      Mapping mapping;
      Builtins builtins;
    end ENV;
  end Env;

  function obfuscateProgram
    "Obfuscates an SCode.Program by replacing names with generated identifiers,
     such as Modelica.SIUnits.Angle => n23.n54.n13. Also takes the path and
     comment for a class and obfuscates them too, which is needed by
     saveTotalModel.

     Note that the given class path does not affect what is obfuscated, this
     function always obfuscate the entire SCode.Program that it's given."
    input output SCode.Program program;
    input output Absyn.Path classPath;
    input output SCode.Comment classComment = SCode.noComment;
          output String mapStr;
  protected
    Mapping mapping;
    Builtins builtins;
    Env env;
  algorithm
    // The mapping table is used to keep track of which obfuscated name each
    // original name is mapped to.
    mapping := UnorderedMap.new<String>(stringHashDjb2Mod, stringEqual);
    // We don't want to obfuscate builtin names, so we keep track of them in a
    // separate table.
    builtins := makeBuiltins();
    env := ENV(mapping, builtins);

    program := list(obfuscateElement(e, env) for e in program);
    classPath := obfuscatePath(classPath, env, ElementType.TYPE);
    classComment := obfuscateComment(classComment, env);

    // Convert the mapping table to a JSON structure that can be used to look up
    // which name is mapped to what.
    mapStr := UnorderedMap.toJSON(env.mapping, Util.id, Util.id);
  end obfuscateProgram;

  function makeBuiltins
    "Creates the table with builtin names."
    output Builtins builtins;
  protected
    SCode.Program builtin_scode;
    ElementType etype;
  algorithm
    builtins := UnorderedMap.new<ElementType>(stringHashDjb2Mod, stringEqual);

    (_, builtin_scode) := FBuiltin.getInitialFunctions();

    for b in builtin_scode loop
      etype := if SCodeUtil.isFunction(b) then ElementType.FUNCTION else ElementType.TYPE;
      UnorderedMap.add(SCodeUtil.elementName(b), etype, builtins);
    end for;

    // Builtin types.
    UnorderedMap.add("Boolean"    , ElementType.TYPE             , builtins);
    UnorderedMap.add("Clock"      , ElementType.TYPE             , builtins);
    UnorderedMap.add("Real"       , ElementType.TYPE             , builtins);
    // Builtin types that are also functions.
    UnorderedMap.add("Integer"    , ElementType.TYPE_AND_FUNCTION, builtins);
    UnorderedMap.add("String"     , ElementType.TYPE_AND_FUNCTION, builtins);
    // Builtin type attributes.
    UnorderedMap.add("displayUnit", ElementType.OTHER            , builtins);
    UnorderedMap.add("fixed"      , ElementType.OTHER            , builtins);
    UnorderedMap.add("max"        , ElementType.OTHER            , builtins);
    UnorderedMap.add("min"        , ElementType.OTHER            , builtins);
    UnorderedMap.add("nominal"    , ElementType.OTHER            , builtins);
    UnorderedMap.add("quantity"   , ElementType.OTHER            , builtins);
    UnorderedMap.add("start"      , ElementType.OTHER            , builtins);
    UnorderedMap.add("stateSelect", ElementType.OTHER            , builtins);
    UnorderedMap.add("time"       , ElementType.OTHER            , builtins);
    UnorderedMap.add("unbounded"  , ElementType.OTHER            , builtins);
    UnorderedMap.add("uncertain"  , ElementType.OTHER            , builtins);
    UnorderedMap.add("unit"       , ElementType.OTHER            , builtins);
    // Builtin functions.
    UnorderedMap.add("constructor", ElementType.FUNCTION         , builtins);
    UnorderedMap.add("destructor" , ElementType.FUNCTION         , builtins);
    UnorderedMap.add("$array"     , ElementType.FUNCTION         , builtins);
  end makeBuiltins;

  function obfuscateElement
    input output SCode.Element element;
    input Env env;
  algorithm
    () := match element
      case SCode.Element.IMPORT()
        algorithm
          element.imp := obfuscateImport(element.imp, env);
        then
          ();

      case SCode.Element.EXTENDS()
        algorithm
          element.baseClassPath := obfuscatePath(element.baseClassPath, env, ElementType.TYPE);
          element.modifications := obfuscateMod(element.modifications, env);
          element.ann := obfuscateAnnotationOpt(element.ann, env);
        then
          ();

      case SCode.Element.CLASS()
        algorithm
          element.name := obfuscateIdentifier(element.name, env, ElementType.TYPE_AND_FUNCTION);
          element.prefixes := obfuscatePrefixes(element.prefixes, env);
          element.classDef := obfuscateClassDef(element.classDef, env);
          element.cmt := obfuscateComment(element.cmt, env);
        then
          ();

      case SCode.Element.COMPONENT()
        algorithm
          element.name := obfuscateIdentifier(element.name, env, ElementType.OTHER);
          element.prefixes := obfuscatePrefixes(element.prefixes, env);
          element.attributes := obfuscateAttributes(element.attributes, env);
          element.typeSpec := obfuscateTypeSpec(element.typeSpec, env);
          element.modifications := obfuscateMod(element.modifications, env);
          element.comment := obfuscateComment(element.comment, env);
          element.condition := obfuscateExpOpt(element.condition, env);
        then
          ();

      else ();
    end match;
  end obfuscateElement;

  function obfuscateImport
    input output Absyn.Import imp;
    input Env env;
  algorithm
    () := match imp
      case Absyn.Import.NAMED_IMPORT()
        algorithm
          imp.name := obfuscateIdentifier(imp.name, env, ElementType.OTHER);
          imp.path := obfuscatePath(imp.path, env, ElementType.TYPE);
        then
          ();

      case Absyn.Import.QUAL_IMPORT()
        algorithm
          imp.path := obfuscatePath(imp.path, env, ElementType.TYPE);
        then
          ();

      case Absyn.Import.UNQUAL_IMPORT()
        algorithm
          imp.path := obfuscatePath(imp.path, env, ElementType.TYPE);
        then
          ();

      case Absyn.Import.GROUP_IMPORT()
        algorithm
          imp.prefix := obfuscatePath(imp.prefix, env, ElementType.TYPE);
          imp.groups := list(obfuscateGroupImport(g, env) for g in imp.groups);
        then
          ();
    end match;
  end obfuscateImport;

  function obfuscateGroupImport
    input output Absyn.GroupImport imp;
    input Env env;
  algorithm
    () := match imp
      case Absyn.GroupImport.GROUP_IMPORT_NAME()
        algorithm
          imp.name := obfuscateIdentifier(imp.name, env, ElementType.TYPE);
        then
          ();

      case Absyn.GroupImport.GROUP_IMPORT_RENAME()
        algorithm
          imp.rename := obfuscateIdentifier(imp.rename, env, ElementType.OTHER);
          imp.name := obfuscateIdentifier(imp.name, env, ElementType.TYPE);
        then
          ();
    end match;
  end obfuscateGroupImport;

  function obfuscateClassDef
    input output SCode.ClassDef cdef;
    input Env env;
  algorithm
    () := match cdef
      case SCode.ClassDef.PARTS()
        algorithm
          cdef.elementLst := list(obfuscateElement(e, env) for e in cdef.elementLst);
          cdef.normalEquationLst := list(obfuscateEquation(e, env) for e in cdef.normalEquationLst);
          cdef.initialEquationLst := list(obfuscateEquation(e, env) for e in cdef.initialEquationLst);
          cdef.normalAlgorithmLst := list(obfuscateAlgorithm(a, env) for a in cdef.normalAlgorithmLst);
          cdef.initialAlgorithmLst := list(obfuscateAlgorithm(a, env) for a in cdef.initialAlgorithmLst);
          cdef.externalDecl := Util.applyOption(cdef.externalDecl,
            function obfuscateExternalDecl(env = env));
        then
          ();

      case SCode.ClassDef.CLASS_EXTENDS()
        algorithm
          cdef.modifications := obfuscateMod(cdef.modifications, env);
          cdef.composition := obfuscateClassDef(cdef.composition, env);
        then
          ();

      case SCode.ClassDef.DERIVED()
        algorithm
          cdef.typeSpec := obfuscateTypeSpec(cdef.typeSpec, env);
          cdef.modifications := obfuscateMod(cdef.modifications, env);
          cdef.attributes := obfuscateAttributes(cdef.attributes, env);
        then
          ();

      case SCode.ClassDef.ENUMERATION()
        algorithm
          cdef.enumLst := list(obfuscateEnum(e, env) for e in cdef.enumLst);
        then
          ();

      case SCode.ClassDef.OVERLOAD()
        algorithm
          cdef.pathLst := list(obfuscatePath(p, env, ElementType.TYPE) for p in cdef.pathLst);
        then
          ();

      case SCode.ClassDef.PDER()
        algorithm
          cdef.functionPath := obfuscatePath(cdef.functionPath, env, ElementType.FUNCTION);
          cdef.derivedVariables := list(obfuscateIdentifier(v, env, ElementType.OTHER) for v in cdef.derivedVariables);
        then
          ();
    end match;
  end obfuscateClassDef;

  function obfuscateTypeSpec
    input output Absyn.TypeSpec ty;
    input Env env;
  algorithm
    () := match ty
      case Absyn.TypeSpec.TPATH()
        algorithm
          ty.path := obfuscatePath(ty.path, env, ElementType.TYPE);
          ty.arrayDim := obfuscateArrayDimsOpt(ty.arrayDim, env);
        then
          ();

      case Absyn.TypeSpec.TCOMPLEX()
        algorithm
          ty.path := obfuscatePath(ty.path, env, ElementType.TYPE);
          ty.typeSpecs := list(obfuscateTypeSpec(t, env) for t in ty.typeSpecs);
          ty.arrayDim := obfuscateArrayDimsOpt(ty.arrayDim, env);
        then
          ();
    end match;
  end obfuscateTypeSpec;

  function obfuscateEnum
    input output SCode.Enum enum;
    input Env env;
  algorithm
    enum.literal := obfuscateIdentifier(enum.literal, env, ElementType.OTHER);
    enum.comment := obfuscateComment(enum.comment, env);
  end obfuscateEnum;

  function obfuscatePrefixes
    input output SCode.Prefixes prefixes;
    input Env env;
  algorithm
    prefixes.replaceablePrefix := obfuscateReplaceable(prefixes.replaceablePrefix, env);
  end obfuscatePrefixes;

  function obfuscateReplaceable
    input output SCode.Replaceable repl;
    input Env env;
  protected
    SCode.ConstrainClass cc;
  algorithm
    () := match repl
      case SCode.Replaceable.REPLACEABLE(cc = SOME(cc))
        algorithm
          cc.constrainingClass := obfuscatePath(cc.constrainingClass, env, ElementType.OTHER);
          cc.modifier := obfuscateMod(cc.modifier, env);
          cc.comment := obfuscateComment(cc.comment, env);
          repl.cc := SOME(cc);
        then
          ();

      else ();
    end match;
  end obfuscateReplaceable;

  function obfuscateAttributes
    input output SCode.Attributes attributes;
    input Env env;
  algorithm
    attributes.arrayDims := obfuscateArrayDims(attributes.arrayDims, env);
  end obfuscateAttributes;

  function obfuscateMod
    input output SCode.Mod mod;
    input Env env;
  algorithm
    () := match mod
      case SCode.Mod.MOD()
        algorithm
          mod.subModLst := list(obfuscateSubMod(s, env) for s in mod.subModLst);
          mod.binding := obfuscateExpOpt(mod.binding, env);
        then
          ();

      case SCode.Mod.REDECL()
        algorithm
          mod.element := obfuscateElement(mod.element, env);
        then
          ();

      else ();
    end match;
  end obfuscateMod;

  function obfuscateSubMod
    input output SCode.SubMod mod;
    input Env env;
  algorithm
    mod.ident := obfuscateIdentifier(mod.ident, env, ElementType.OTHER);
    mod.mod := obfuscateMod(mod.mod, env);
  end obfuscateSubMod;

  function obfuscatePath
    input output Absyn.Path path;
    input Env env;
    input ElementType etype;
  protected
    Absyn.Ident name;
  algorithm
    () := match path
      case Absyn.Path.IDENT()
        algorithm
          name := obfuscateIdentifier(path.name, env, etype);

          // Don't obfuscate if it's a builtin name.
          if referenceEq(name, path.name) then
            return;
          end if;

          path.name := name;
        then
          ();

      case Absyn.Path.QUALIFIED()
        algorithm
          name := obfuscateIdentifier(path.name, env, etype);

          // Don't obfuscate if it's a builtin name, and don't obfuscate the
          // rest of the path either.
          if referenceEq(name, path.name) then
            return;
          end if;

          path.name := name;
          path.path := obfuscatePath(path.path, env, etype);
        then
          ();

      case Absyn.Path.FULLYQUALIFIED()
        algorithm
          path.path := obfuscatePath(path.path, env, etype);
        then
          ();
    end match;
  end obfuscatePath;

  function obfuscateIdentifier
    input String id;
    input Env env;
    input ElementType etype;
    output String outId;
  protected
    Builtins builtins = env.builtins;
    Mapping mapping = env.mapping;
    Option<ElementType> opt_ety;
    ElementType ety;
  algorithm
    opt_ety := UnorderedMap.get(id, builtins);

    if isSome(opt_ety) then
      SOME(ety) := opt_ety;

      if isBuiltinInContext(etype, ety) then
        outId := id;
        return;
      end if;
    end if;

    outId := UnorderedMap.addUpdate(id,
      function makeId(index = UnorderedMap.size(mapping)), mapping);
  end obfuscateIdentifier;

  function isBuiltinInContext
    input ElementType expectedType;
    input ElementType actualType;
    output Boolean res;
  algorithm
    res := match (expectedType, actualType)
      // Looking for a type and found a builtin type.
      case (ElementType.TYPE, ElementType.TYPE) then true;
      case (ElementType.TYPE, ElementType.TYPE_AND_FUNCTION) then true;
      // Looking for a function and found a builtin function.
      case (ElementType.FUNCTION, ElementType.FUNCTION) then true;
      case (ElementType.FUNCTION, ElementType.TYPE_AND_FUNCTION) then true;
      // Looking for a type or function and found type or function.
      case (ElementType.TYPE_AND_FUNCTION, ElementType.TYPE) then true;
      case (ElementType.TYPE_AND_FUNCTION, ElementType.FUNCTION) then true;
      case (ElementType.TYPE_AND_FUNCTION, ElementType.TYPE_AND_FUNCTION) then true;
      // Looking for anything and found a builtin type, probably something like
      // StateSelect used in an expression like StateSelect.prefer.
      case (_, ElementType.TYPE) then true;
      // Looking for anything and found something else, probably a builtin type
      // attribute.
      case (_, ElementType.OTHER) then true;
      else false;
    end match;
  end isBuiltinInContext;

  function makeId
    input Option<String> oldId;
    input Integer index;
    output String id;
  algorithm
    if isSome(oldId) then
      SOME(id) := oldId;
    else
      id := "n" + String(index);
    end if;
  end makeId;

  function obfuscateComment
    input output SCode.Comment comment;
    input Env env;
  algorithm
    comment.annotation_ := obfuscateAnnotationOpt(comment.annotation_, env);
    comment.comment := NONE();
  end obfuscateComment;

  function obfuscateAnnotationOpt
    input output Option<SCode.Annotation> ann;
    input Env env;
  algorithm
    ann := Util.applyOption(ann, function obfuscateAnnotation(env = env));
  end obfuscateAnnotationOpt;

  function obfuscateAnnotation
    input output SCode.Annotation ann;
    input Env env;
  algorithm
    ann.modification := obfuscateAnnotationMod(ann.modification, env);
  end obfuscateAnnotation;

  function obfuscateAnnotationMod
    input output SCode.Mod mod;
    input Env env;
    input Boolean obfuscateName = false;
  algorithm
    () := match mod
      case SCode.Mod.MOD()
        algorithm
          mod.subModLst := list(obfuscateAnnotationSubMod(s, env, obfuscateName)
            for s guard isAllowedAnnotation(s) in mod.subModLst);
          mod.binding := obfuscateExpOpt(mod.binding, env);
        then
          ();

      else ();
    end match;
  end obfuscateAnnotationMod;

  function isAllowedAnnotation
    input SCode.SubMod mod;
    output Boolean allowed;
  algorithm
    allowed := match mod.ident
      case "Icon" then false;
      case "Diagram" then false;
      case "Dialog" then false;
      case "IconMap" then false;
      case "DiagramMap" then false;
      case "Placement" then false;
      case "Text" then false;
      case "Line" then false;
      case "defaultComponentName" then false;
      case "defaultComponentPrefixes" then false;
      case "missingInnerMessage" then false;
      case "obsolete" then false;
      case "unassignedMessage" then false;
      case "Protection" then false;
      case "Authorization" then false;
      else not Util.stringStartsWith("__", mod.ident);
    end match;
  end isAllowedAnnotation;

  function obfuscateAnnotationSubMod
    input output SCode.SubMod mod;
    input Env env;
    input Boolean obfuscateName;
  protected
    Boolean obfuscate_name;
  algorithm
    if obfuscateName then
      mod.ident := obfuscateIdentifier(mod.ident, env, ElementType.OTHER);
    end if;

    obfuscate_name := match mod.ident
      case "inverse" then true;
      else false;
    end match;

    mod.mod := obfuscateAnnotationMod(mod.mod, env, obfuscate_name);
  end obfuscateAnnotationSubMod;

  function obfuscateExpOpt
    input output Option<Absyn.Exp> exp;
    input Env env;
  algorithm
    exp := Util.applyOption(exp, function obfuscateExp(env = env));
  end obfuscateExpOpt;

  function obfuscateExp
    input output Absyn.Exp exp;
    input Env env;
  algorithm
    exp := AbsynUtil.traverseExp(exp, obfuscateExpTraverse, env);
  end obfuscateExp;

  function obfuscateExpTraverse
    input output Absyn.Exp exp;
    input output Env env;
  algorithm
    () := match exp
      case Absyn.Exp.CREF()
        algorithm
          // AbsynUtil.traverseExp traverses subscripts, so skip them here to
          // avoid obfuscating them twice.
          exp.componentRef := obfuscateCref(exp.componentRef, env, ElementType.OTHER, obfuscateSubs = false);
        then
          ();

      case Absyn.Exp.CALL()
        algorithm
          exp.functionArgs := obfuscateFunctionArgs(exp.functionArgs, exp.function_, env);
          exp.function_ := obfuscateCref(exp.function_, env, ElementType.FUNCTION, obfuscateSubs = false);
        then
          ();

      case Absyn.Exp.PARTEVALFUNCTION()
        algorithm
          exp.functionArgs := obfuscateFunctionArgs(exp.functionArgs, exp.function_, env);
          exp.function_ := obfuscateCref(exp.function_, env, ElementType.OTHER, obfuscateSubs = false);
        then
          ();

      else ();
    end match;
  end obfuscateExpTraverse;

  function obfuscateCref
    input output Absyn.ComponentRef cref;
    input Env env;
    input ElementType etype;
    input Boolean obfuscateSubs = true;
  protected
    Absyn.Ident name;
  algorithm
    () := match cref
      case Absyn.ComponentRef.CREF_IDENT()
        algorithm
          name := obfuscateIdentifier(cref.name, env, etype);

          // Don't obfuscate if it's a builtin name.
          if referenceEq(name, cref.name) then
            return;
          end if;

          cref.name := name;

          if obfuscateSubs then
            cref.subscripts := obfuscateSubscripts(cref.subscripts, env);
          end if;
        then
          ();

      case Absyn.ComponentRef.CREF_QUAL()
        algorithm
          name := obfuscateIdentifier(cref.name, env, etype);

          // Don't obfuscate if it's a builtin name, and don't obfuscate the
          // rest of the cref either.
          if referenceEq(name, cref.name) then
            return;
          end if;

          cref.name := name;

          if obfuscateSubs then
            cref.subscripts := obfuscateSubscripts(cref.subscripts, env);
          end if;

          cref.componentRef := obfuscateCref(cref.componentRef, env, etype, obfuscateSubs);
        then
          ();

      case Absyn.ComponentRef.CREF_FULLYQUALIFIED()
        algorithm
          cref.componentRef := obfuscateCref(cref.componentRef, env, etype, obfuscateSubs);
        then
          ();

      else ();
    end match;
  end obfuscateCref;

  function obfuscateSubscripts
    input output list<Absyn.Subscript> subs;
    input Env env;
  algorithm
    subs := list(obfuscateSubscript(s, env) for s in subs);
  end obfuscateSubscripts;

  function obfuscateSubscript
    input output Absyn.Subscript sub;
    input Env env;
  algorithm
    () := match sub
      case Absyn.Subscript.SUBSCRIPT()
        algorithm
          sub.subscript := obfuscateExp(sub.subscript, env);
        then
          ();

      else ();
    end match;
  end obfuscateSubscript;

  function obfuscateFunctionArgs
    "Obfuscates the names inside an Absyn.FunctionArgs (the expressions are
     assumed to have already been obfuscated due to using AbsynUtil.traverseExp)."
    input output Absyn.FunctionArgs args;
    input Absyn.ComponentRef fnName;
    input Env env;
  algorithm
    () := match args
      // Normal function arguments, obfuscate the names of named arguments
      // unless the function is builtin.
      case Absyn.FunctionArgs.FUNCTIONARGS()
        guard not listEmpty(args.argNames) and not isBuiltinCall(fnName, env)
        algorithm
          args.argNames := list(obfuscateNamedArg(a, env) for a in args.argNames);
        then
          ();

      // Iterator arguments, obfuscate the iterators' names.
      case Absyn.FunctionArgs.FOR_ITER_FARG()
        algorithm
          args.iterators := list(obfuscateForIterator(i, env) for i in args.iterators);
        then
          ();

      else ();
    end match;
  end obfuscateFunctionArgs;

  function obfuscateNamedArg
    input output Absyn.NamedArg arg;
    input Env env;
  algorithm
    arg.argName := obfuscateIdentifier(arg.argName, env, ElementType.OTHER);
  end obfuscateNamedArg;

  function obfuscateForIterator
    input output Absyn.ForIterator iterator;
    input Env env;
  algorithm
    iterator.name := obfuscateIdentifier(iterator.name, env, ElementType.OTHER);
  end obfuscateForIterator;

  function obfuscateArrayDimsOpt
    input output Option<Absyn.ArrayDim> dims;
    input Env env;
  algorithm
    dims := Util.applyOption(dims, function obfuscateArrayDims(env = env));
  end obfuscateArrayDimsOpt;

  function obfuscateArrayDims = obfuscateSubscripts;

  function obfuscateExternalDecl
    input output SCode.ExternalDecl extDecl;
    input Env env;
  algorithm
    extDecl.args := list(obfuscateExp(a, env) for a in extDecl.args);
    extDecl.output_ := Util.applyOption(extDecl.output_,
      function obfuscateCref(env = env, etype = ElementType.OTHER, obfuscateSubs = true));
    extDecl.annotation_ := obfuscateAnnotationOpt(extDecl.annotation_, env);
  end obfuscateExternalDecl;

  function obfuscateEquation
    input output SCode.Equation eq;
    input Env env;
  algorithm
    eq.eEquation := obfuscateEEquation(eq.eEquation, env);
  end obfuscateEquation;

  function obfuscateEEquations
    input output list<SCode.EEquation> eql;
    input Env env;
  algorithm
    eql := list(obfuscateEEquation(eq, env) for eq in eql);
  end obfuscateEEquations;

  function obfuscateEEquation
    input output SCode.EEquation eq;
    input Env env;
  algorithm
    () := match eq
      case SCode.EEquation.EQ_IF()
        algorithm
          eq.condition := list(obfuscateExp(e, env) for e in eq.condition);
          eq.thenBranch := list(obfuscateEEquations(e, env) for e in eq.thenBranch);
          eq.elseBranch := obfuscateEEquations(eq.elseBranch, env);
          eq.comment := obfuscateComment(eq.comment, env);
        then
          ();

      case SCode.EEquation.EQ_EQUALS()
        algorithm
          eq.expLeft := obfuscateExp(eq.expLeft, env);
          eq.expRight := obfuscateExp(eq.expRight, env);
          eq.comment := obfuscateComment(eq.comment, env);
        then
          ();

      case SCode.EEquation.EQ_PDE()
        algorithm
          eq.expLeft := obfuscateExp(eq.expLeft, env);
          eq.expRight := obfuscateExp(eq.expRight, env);
          eq.comment := obfuscateComment(eq.comment, env);
        then
          ();

      case SCode.EEquation.EQ_CONNECT()
        algorithm
          eq.crefLeft := obfuscateCref(eq.crefLeft, env, ElementType.OTHER);
          eq.crefRight := obfuscateCref(eq.crefRight, env, ElementType.OTHER);
          eq.comment := obfuscateComment(eq.comment, env);
        then
          ();

      case SCode.EEquation.EQ_FOR()
        algorithm
          eq.index := obfuscateIdentifier(eq.index, env, ElementType.OTHER);
          eq.range := obfuscateExpOpt(eq.range, env);
          eq.eEquationLst := obfuscateEEquations(eq.eEquationLst, env);
          eq.comment := obfuscateComment(eq.comment, env);
        then
          ();

      case SCode.EEquation.EQ_WHEN()
        algorithm
          eq.condition := obfuscateExp(eq.condition, env);
          eq.eEquationLst := obfuscateEEquations(eq.eEquationLst, env);
          eq.elseBranches := list(
            (obfuscateExp(Util.tuple21(b), env),
             obfuscateEEquations(Util.tuple22(b), env)) for b in eq.elseBranches);
          eq.comment := obfuscateComment(eq.comment, env);
        then
          ();

      case SCode.EEquation.EQ_ASSERT()
        algorithm
          eq.condition := obfuscateExp(eq.condition, env);
          eq.message := obfuscateMessage(eq.message, "assert");
          eq.level := obfuscateExp(eq.level, env);
          eq.comment := obfuscateComment(eq.comment, env);
        then
          ();

      case SCode.EEquation.EQ_TERMINATE()
        algorithm
          eq.message := obfuscateMessage(eq.message, "terminate");
          eq.comment := obfuscateComment(eq.comment, env);
        then
          ();

      case SCode.EEquation.EQ_REINIT()
        algorithm
          eq.cref := obfuscateExp(eq.cref, env);
          eq.expReinit := obfuscateExp(eq.expReinit, env);
          eq.comment := obfuscateComment(eq.comment, env);
        then
          ();

      case SCode.EEquation.EQ_NORETCALL()
        algorithm
          eq.exp := obfuscateExp(eq.exp, env);
          eq.comment := obfuscateComment(eq.comment, env);
        then
          ();
    end match;
  end obfuscateEEquation;

  function obfuscateMessage
    "Obfuscates the message of assert/terminate by replacing it with
     '<%fnName%> message <%hash of message%>'"
    input output Absyn.Exp message;
    input String fnName;
  protected
    String msg_str;
  algorithm
    msg_str := match message
      case Absyn.Exp.STRING() then message.value;
      // The message should be a string, but just to be safe.
      else Dump.printExpStr(message);
    end match;

    msg_str := String(System.stringHashDjb2(msg_str));
    msg_str := fnName + " message " + msg_str;
    message := Absyn.Exp.STRING(msg_str);
  end obfuscateMessage;

  function obfuscateAlgorithm
    input output SCode.AlgorithmSection alg;
    input Env env;
  algorithm
    alg.statements := obfuscateStatements(alg.statements, env);
  end obfuscateAlgorithm;

  function obfuscateStatements
    input output list<SCode.Statement> stmts;
    input Env env;
  algorithm
    stmts := list(obfuscateStatement(s, env) for s in stmts);
  end obfuscateStatements;

  function obfuscateStatement
    input output SCode.Statement stmt;
    input Env env;
  algorithm
    () := match stmt
      case SCode.Statement.ALG_ASSIGN()
        algorithm
          stmt.assignComponent := obfuscateExp(stmt.assignComponent, env);
          stmt.value := obfuscateExp(stmt.value, env);
          stmt.comment := obfuscateComment(stmt.comment, env);
        then
          ();

      case SCode.Statement.ALG_IF()
        algorithm
          stmt.boolExpr := obfuscateExp(stmt.boolExpr, env);
          stmt.trueBranch := obfuscateStatements(stmt.trueBranch, env);
          stmt.elseIfBranch := list(
            (obfuscateExp(Util.tuple21(b), env),
             obfuscateStatements(Util.tuple22(b), env)) for b in stmt.elseIfBranch);
          stmt.elseBranch := obfuscateStatements(stmt.elseBranch, env);
          stmt.comment := obfuscateComment(stmt.comment, env);
        then
          ();

      case SCode.Statement.ALG_FOR()
        algorithm
          stmt.index := obfuscateIdentifier(stmt.index, env, ElementType.OTHER);
          stmt.range := obfuscateExpOpt(stmt.range, env);
          stmt.forBody := obfuscateStatements(stmt.forBody, env);
          stmt.comment := obfuscateComment(stmt.comment, env);
        then
          ();

      case SCode.Statement.ALG_PARFOR()
        algorithm
          stmt.index := obfuscateIdentifier(stmt.index, env, ElementType.OTHER);
          stmt.range := obfuscateExpOpt(stmt.range, env);
          stmt.parforBody := obfuscateStatements(stmt.parforBody, env);
          stmt.comment := obfuscateComment(stmt.comment, env);
        then
          ();

      case SCode.Statement.ALG_WHILE()
        algorithm
          stmt.boolExpr := obfuscateExp(stmt.boolExpr, env);
          stmt.whileBody := obfuscateStatements(stmt.whileBody, env);
          stmt.comment := obfuscateComment(stmt.comment, env);
        then
          ();

      case SCode.Statement.ALG_WHEN_A()
        algorithm
          stmt.branches := list(
            (obfuscateExp(Util.tuple21(b), env),
             obfuscateStatements(Util.tuple22(b), env)) for b in stmt.branches);
          stmt.comment := obfuscateComment(stmt.comment, env);
        then
          ();

      case SCode.Statement.ALG_ASSERT()
        algorithm
          stmt.condition := obfuscateExp(stmt.condition, env);
          stmt.message := obfuscateMessage(stmt.message, "assert");
          stmt.level := obfuscateExp(stmt.level, env);
          stmt.comment := obfuscateComment(stmt.comment, env);
        then
          ();

      case SCode.Statement.ALG_TERMINATE()
        algorithm
          stmt.message := obfuscateMessage(stmt.message, "terminate");
          stmt.comment := obfuscateComment(stmt.comment, env);
        then
          ();

      case SCode.Statement.ALG_REINIT()
        algorithm
          stmt.cref := obfuscateExp(stmt.cref, env);
          stmt.newValue := obfuscateExp(stmt.newValue, env);
          stmt.comment := obfuscateComment(stmt.comment, env);
        then
          ();

      case SCode.Statement.ALG_NORETCALL()
        algorithm
          stmt.exp := obfuscateExp(stmt.exp, env);
          stmt.comment := obfuscateComment(stmt.comment, env);
        then
          ();

      case SCode.Statement.ALG_RETURN()
        algorithm
          stmt.comment := obfuscateComment(stmt.comment, env);
        then
          ();

      case SCode.Statement.ALG_BREAK()
        algorithm
          stmt.comment := obfuscateComment(stmt.comment, env);
        then
          ();

      else ();
    end match;
  end obfuscateStatement;

  function isBuiltinCall
    input Absyn.ComponentRef callName;
    input Env env;
    output Boolean res;
  protected
    String name;
    ElementType ety;
  algorithm
    name := AbsynUtil.crefFirstIdent(callName);
    ety := UnorderedMap.getOrDefault(name, env.builtins, ElementType.OTHER);
    res := ety == ElementType.FUNCTION or ety == ElementType.TYPE_AND_FUNCTION;
  end isBuiltinCall;

  annotation(__OpenModelica_Interface="backend");
end Obfuscate;
