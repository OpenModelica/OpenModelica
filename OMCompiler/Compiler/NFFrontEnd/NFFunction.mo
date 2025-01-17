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

encapsulated package NFFunction

import Absyn;
import AbsynUtil;
import Expression = NFExpression;
import Pointer;
import NFInstNode.InstNode;
import Type = NFType;
import NFPrefixes.*;
import List;
import FunctionDerivative = NFFunctionDerivative;
import FunctionInverse = NFFunctionInverse;
import NFModifier.Modifier;

protected
import ErrorExt;
import Inst = NFInst;
import NFInst.InstSettings;
import Binding = NFBinding;
import Config;
import DAE;
import Error;
import InstUtil;
import Class = NFClass;
import Component = NFComponent;
import Attributes = NFAttributes;
import StringUtil;
import Typing = NFTyping;
import TypeCheck = NFTypeCheck;
import Util;
import ComponentRef = NFComponentRef;
import NFInstNode.CachedData;
import Lookup = NFLookup;
import ClassTree = NFClassTree.ClassTree;
import Prefixes = NFPrefixes;
import NFLookupState.LookupState;
import Record = NFRecord;
import NFTyping.ClassScope;
import MatchKind = NFTypeCheck.MatchKind;
import Restriction = NFRestriction;
import Dimension = NFDimension;
import Statement = NFStatement;
import Sections = NFSections;
import Algorithm = NFAlgorithm;
import OperatorOverloading = NFOperatorOverloading;
import MetaModelica.Dangerous.listReverseInPlace;
import Array;
import ElementSource;
import SCodeUtil;
import IOStream;
import ComplexType = NFComplexType;
import InstContext = NFInstContext;
import UnorderedSet;
import Graph;
import FlatModelicaUtil = NFFlatModelicaUtil;
import Subscript = NFSubscript;

public

type NamedArg = tuple<String, Expression>;

uniontype TypedArg
  record TYPED_ARG
    Option<String> name;
    Expression value;
    Type ty;
    Variability var;
    Purity purity;
  end TYPED_ARG;
end TypedArg;

public
type SlotType = enumeration(
  POSITIONAL "Only accepts positional arguments.",
  NAMED      "Only accepts named argument.",
  GENERIC    "Accepts both positional and named arguments."
) "Determines which type of argument a slot accepts.";

type SlotEvalStatus = enumeration(NOT_EVALUATED, EVALUATING, EVALUATED);

uniontype Slot
  record SLOT
    InstNode node;
    SlotType ty;
    Option<Expression> default;
    Option<TypedArg> arg;
    Integer index;
    SlotEvalStatus evalStatus;
  end SLOT;

  function positional
    input Slot slot;
    output Boolean pos;
  algorithm
    pos := match slot.ty
      case SlotType.POSITIONAL then true;
      case SlotType.GENERIC then true;
      else false;
    end match;
  end positional;

  function named
    input Slot slot;
    output Boolean pos;
  algorithm
    pos := match slot.ty
      case SlotType.NAMED then true;
      case SlotType.GENERIC then true;
      else false;
    end match;
  end named;

  function name
    input Slot slot;
    output String name = InstNode.name(slot.node);
  end name;

  function hasNode
    input InstNode node;
    input Slot slot;
    output Boolean hasNode = InstNode.refEqual(node, slot.node);
  end hasNode;
end Slot;

public
encapsulated
uniontype FunctionMatchKind
  import Dimension = NFDimension;

  record EXACT "Exact match." end EXACT;

  record CAST "Matched by casting one or more arguments. e.g. Integer to Real" end CAST;

  record GENERIC "Matched with a generic type on one or more arguments e.g. function F<T> input T i; end F; F(1)"
  end GENERIC;

  record VECTORIZED "Matched by vectorization"
    list<Dimension> vectDims;
    // When vectorizing a call exact argument matches are allowed to not be vectorized
    // Instead they are added to each call as is.
    // This list represents which args should be vectorized.
    list<Integer> vectorizedArgs;
    FunctionMatchKind baseMatch;
  end VECTORIZED;

  record NOT_COMPATIBLE end NOT_COMPATIBLE;

  function isValid
    input FunctionMatchKind mk;
    output Boolean b;
  algorithm
    b := match mk
      case NOT_COMPATIBLE() then false;
      else true;
    end match;
  end isValid;

  function isExact
    input FunctionMatchKind mk;
    output Boolean b;
  algorithm
    b := match mk
      case EXACT() then true;
      else false;
    end match;
  end isExact;

  function isVectorized
    input FunctionMatchKind mk;
    output Boolean b;
  algorithm
    b := match mk
      case VECTORIZED() then true;
      else false;
    end match;
  end isVectorized;

  function isExactVectorized
    input FunctionMatchKind mk;
    output Boolean b;
  algorithm
    b := match mk
      case VECTORIZED(baseMatch = EXACT()) then true;
      else false;
    end match;
  end isExactVectorized;

end FunctionMatchKind;

constant FunctionMatchKind EXACT_MATCH = FunctionMatchKind.EXACT();
constant FunctionMatchKind CAST_MATCH = FunctionMatchKind.CAST();
constant FunctionMatchKind GENERIC_MATCH = FunctionMatchKind.GENERIC();
constant FunctionMatchKind NO_MATCH = FunctionMatchKind.NOT_COMPATIBLE();

encapsulated
uniontype MatchedFunction
  import NFFunction.Function;
  import NFFunction.TypedArg;
  import NFFunction.FunctionMatchKind;

  record MATCHED_FUNC
    Function func;
    list<TypedArg> args;
    FunctionMatchKind mk;
  end MATCHED_FUNC;

  function getExactMatches
    input list<MatchedFunction> matchedFunctions;
    output list<MatchedFunction> outFuncs = list(mf for mf guard(FunctionMatchKind.isExact(mf.mk)) in matchedFunctions);
  end getExactMatches;

  function getExactVectorizedMatches
    input list<MatchedFunction> matchedFunctions;
    output list<MatchedFunction> outFuncs =
      list(mf for mf guard(FunctionMatchKind.isExactVectorized(mf.mk)) in matchedFunctions);
  end getExactVectorizedMatches;

  function isVectorized
    input MatchedFunction mf;
    output Boolean b = FunctionMatchKind.isVectorized(mf.mk);
  end isVectorized;

end MatchedFunction;

type FunctionStatus = enumeration(
  BUILTIN    "A builtin function.",
  INITIAL    "The initial status.",
  EVALUATED  "Constants in the function has been evaluated by EvalConstants.",
  SIMPLIFIED "The function has been simplified by SimplifyModel.",
  COLLECTED  "The function has been added to the function tree."
);

uniontype Function

  record FUNCTION
    Absyn.Path path;
    InstNode node;
    list<InstNode> inputs;
    list<InstNode> outputs;
    list<InstNode> locals;
    list<Slot> slots;
    Type returnType;
    DAE.FunctionAttributes attributes;
    list<FunctionDerivative> derivatives;
    list<Integer> derivedInputs;
    array<FunctionInverse> inverses;
    Pointer<FunctionStatus> status;
    Pointer<Integer> callCounter "Used during function evaluation to limit recursion.";
  end FUNCTION;

  function new
    input Absyn.Path path;
    input InstNode node;
    output Function fn;
  protected
    Class cls;
    list<InstNode> inputs, outputs, locals;
    list<Slot> slots;
    DAE.FunctionAttributes attr;
    FunctionStatus status;
  algorithm
    (inputs, outputs, locals) := collectParams(node);
    attr := makeAttributes(node, inputs, outputs);
    // Make sure builtin functions aren't added to the function tree.
    status := if isBuiltinAttr(attr) then FunctionStatus.COLLECTED else FunctionStatus.INITIAL;
    fn := FUNCTION(path, node, inputs, outputs, locals, {}, Type.UNKNOWN(),
      attr, {}, {}, listArray({}), Pointer.create(status), Pointer.create(0));
  end new;

  function lookupFunctionSimple
    input String functionName;
    input InstNode scope;
    input InstContext.Type context;
    output ComponentRef functionRef;
  protected
    InstNode found_scope;
    LookupState state;
    Absyn.Path functionPath;
    ComponentRef prefix;
  algorithm
    (functionRef, found_scope) :=
      Lookup.lookupFunctionNameSilent(Absyn.CREF_IDENT(functionName, {}), scope, context);
    prefix := ComponentRef.fromNodeList(InstNode.scopeList(found_scope));
    functionRef := ComponentRef.append(functionRef, prefix);
  end lookupFunctionSimple;

  function lookupFunction
    input Absyn.ComponentRef functionName;
    input InstNode scope;
    input InstContext.Type context;
    input SourceInfo info;
    output ComponentRef functionRef;
  protected
    InstNode found_scope;
    LookupState state;
    Absyn.Path functionPath;
    ComponentRef prefix;
    Boolean is_class;
  algorithm
    try
      // Make sure the name is a path.
      functionPath := AbsynUtil.crefToPath(functionName);
    else
      Error.addSourceMessageAndFail(Error.SUBSCRIPTED_FUNCTION_CALL,
        {Dump.printComponentRefStr(functionName)}, info);
    end try;

    (functionRef, found_scope) := Lookup.lookupFunctionName(functionName, scope, context, info);
    // If we found a function class we include the root in the prefix, but if we
    // instead found a component (i.e. a functional parameter) we don't.
    is_class := InstNode.isClass(ComponentRef.node(functionRef));
    prefix := ComponentRef.fromNodeList(InstNode.scopeList(found_scope, includeRoot = is_class));
    functionRef := ComponentRef.append(functionRef, prefix);
  end lookupFunction;

  function instFunction
    input Absyn.ComponentRef functionName;
    input InstNode scope;
    input InstContext.Type context;
    input SourceInfo info;
    output ComponentRef fn_ref;
    output InstNode fn_node;
    output Boolean specialBuiltin;
  protected
    CachedData cache;
  algorithm
    fn_ref := lookupFunction(functionName, scope, context, info);
    (fn_ref, fn_node, specialBuiltin) := instFunctionRef(fn_ref, context, info);
  end instFunction;

  function instFunctionRef
    input output ComponentRef fn_ref;
    input InstContext.Type context;
    input SourceInfo info;
    output InstNode fn_node;
    output Boolean specialBuiltin;
  protected
    CachedData cache;
    InstNode parent;
  algorithm
    fn_node := InstNode.classScope(ComponentRef.node(fn_ref));
    cache := InstNode.getFuncCache(fn_node);

    // Check if a cached instantiation of this function already exists.
    (fn_node, specialBuiltin) := match cache
      case CachedData.FUNCTION() then (fn_node, cache.specialBuiltin);
      else
        algorithm
          parent := if InstNode.isRedeclare(ComponentRef.node(fn_ref)) or ComponentRef.isSimple(fn_ref) then
            InstNode.EMPTY_NODE() else ComponentRef.node(ComponentRef.rest(fn_ref));

          if not InstNode.isComponent(parent) then
            parent := InstNode.EMPTY_NODE();
          end if;
        then
          instFunction2(ComponentRef.toPath(fn_ref), fn_node, context, info, parent);
    end match;
  end instFunctionRef;

  function instFunctionNode
    "Instantiates the given InstNode as a function."
    input output InstNode node;
    input InstContext.Type context;
    input SourceInfo info;
  protected
    CachedData cache;
  algorithm
    cache := InstNode.getFuncCache(node);

    () := match cache
      case CachedData.FUNCTION() then ();
      else
        algorithm
          node := instFunction2(InstNode.fullPath(node), node, context, info);
        then
          ();
    end match;
  end instFunctionNode;

  function instFunction2
    input Absyn.Path fnPath;
    input output InstNode fnNode;
    input InstContext.Type context;
    input SourceInfo info;
    input InstNode parent = InstNode.EMPTY_NODE();
          output Boolean specialBuiltin;
  protected
    SCode.Element def = InstNode.definition(fnNode);
  algorithm
    (fnNode, specialBuiltin) := match def
      local
        SCode.ClassDef cdef;
        Function fn;
        Absyn.ComponentRef cr;
        InstNode node;
        list<Function> funcs;

      case SCode.CLASS() guard SCodeUtil.isOperatorRecord(def)
        algorithm
          fnNode := instFunction3(fnNode, context, info);
          fnNode := OperatorOverloading.instConstructor(fnPath, fnNode, context, info);
        then
          (fnNode, false);

      case SCode.CLASS() guard SCodeUtil.isRecord(def)
        algorithm
          fnNode := instFunction3(fnNode, context, info);
          fnNode := Record.instDefaultConstructor(fnPath, fnNode, context, info);
        then
          (fnNode, false);

      case SCode.CLASS(restriction = SCode.R_OPERATOR(), classDef = cdef as SCode.PARTS())
        algorithm
          fnNode := instFunction3(fnNode, context, info);
          fnNode := OperatorOverloading.instOperatorFunctions(fnNode, context, info);
        then
          (fnNode, false);

      case SCode.CLASS(classDef = cdef as SCode.OVERLOAD())
        algorithm
          for p in cdef.pathLst loop
            cr := AbsynUtil.pathToCref(p);
            (_,node,specialBuiltin) := instFunction(cr, fnNode, context, info);
            for f in getCachedFuncs(node) loop
              fnNode := InstNode.cacheAddFunc(fnNode, f, specialBuiltin);
            end for;
          end for;
        then
          (fnNode, false);

      // An enumeration type name used as an operator, create a conversion
      // operator EnumTypeName(Integer) => EnumTypeName for it.
      case SCode.CLASS()
        guard InstNode.isEnumerationType(fnNode)
        algorithm
          node := makeEnumConversionOp(fnNode);
          node := InstNode.setNodeType(NFInstNode.InstNodeType.ROOT_CLASS(parent), node);
          node := instFunction3(node, context, info);
          fn := new(fnPath, node);
          fnNode := InstNode.cacheAddFunc(fnNode, fn, false);
        then
          (fnNode, false);

      case SCode.CLASS()
        algorithm
          if SCodeUtil.isOperator(def) then
            OperatorOverloading.checkOperatorRestrictions(fnNode);
          end if;

          fnNode := InstNode.setNodeType(NFInstNode.InstNodeType.ROOT_CLASS(parent), fnNode);
          fnNode := instFunction3(fnNode, context, info);
          fn := new(fnPath, fnNode);
          specialBuiltin := isSpecialBuiltin(fn);
          fn.derivatives := FunctionDerivative.instDerivatives(fnNode, fn);
          fn.inverses := FunctionInverse.instInverses(fnNode, fn);
          fn.derivedInputs := instPartialDerivedVars(def.classDef, fn.inputs, fn, context, info);
          fnNode := InstNode.cacheAddFunc(fnNode, fn, specialBuiltin);
        then
          (fnNode, specialBuiltin);

    end match;
  end instFunction2;

  function instFunction3
    input output InstNode fnNode;
    input InstContext.Type context;
    input SourceInfo info;
  protected
    SCode.Element def;
    Integer numError = Error.getNumErrorMessages();
    InstContext.Type fn_context = InstContext.set(context, NFInstContext.FUNCTION);
  algorithm
    try
      fnNode := Inst.instantiate(fnNode, context = fn_context, instPartial = true);
    else
      true := Error.getNumErrorMessages() == numError;
      def := InstNode.definition(fnNode);
      Error.addSourceMessage(Error.UNKNOWN_ERROR_INST_FUNCTION, {SCodeDump.unparseElementStr(def)}, SCodeUtil.elementInfo(def));
      fail();
    end try;

    // Set up an empty function cache to signal that this function is
    // currently being instantiated, so recursive functions can be handled.
    InstNode.cacheInitFunc(fnNode);
    Inst.instExpressions(fnNode, context = context, settings = InstSettings.create());
  end instFunction3;

  function makeEnumConversionOp
    "Creates an EnumTypeName(index) conversion operator."
    input InstNode enumNode;
    output InstNode fnNode;
  protected
    SCode.ClassDef def, fn_def;
    SCode.Element elem, fn_elem;
    list<SCode.Element> params;
    list<SCode.Statement> stmts;
    SourceInfo info = InstNode.info(enumNode);
    String enum_name = InstNode.name(enumNode);
  algorithm
    elem := InstNode.definition(InstNode.resolveInner(Class.lastBaseClass(enumNode)));

    // Construct an SCode definition for the conversion operator.
    fn_def := match elem
      case SCode.Element.CLASS(classDef = def as SCode.ClassDef.ENUMERATION())
        algorithm
          // function E
          params := {
            // input Integer index;
            SCode.Element.COMPONENT("index",
              SCode.defaultPrefixes,
              SCode.defaultInputAttr,
              Absyn.TypeSpec.TPATH(Absyn.Path.IDENT("Integer"), NONE()),
              SCode.NOMOD(),
              SCode.noComment,
              NONE(),
              info
            ),
            // output E value;
            SCode.Element.COMPONENT("value",
              SCode.defaultPrefixes,
              SCode.defaultOutputAttr,
              Absyn.TypeSpec.TPATH(Absyn.Path.IDENT(enum_name), NONE()),
              SCode.NOMOD(),
              SCode.noComment,
              NONE(),
              info
            )
          };
          // algorithm
          stmts := {
            // assert(index >= 1 and index <= size(E, 1),
            //        "Enumeration index '" + String(index) + "' out of bounds in call to E()");
            SCode.Statement.ALG_ASSERT(
              Absyn.Exp.LBINARY(
                Absyn.Exp.RELATION(
                  Absyn.Exp.CREF(Absyn.ComponentRef.CREF_IDENT("index", {})),
                  Absyn.Operator.GREATEREQ(),
                  Absyn.Exp.INTEGER(1)
                ),
                Absyn.Operator.AND(),
                Absyn.Exp.RELATION(
                  Absyn.Exp.CREF(Absyn.ComponentRef.CREF_IDENT("index", {})),
                  Absyn.Operator.LESSEQ(),
                  Absyn.Exp.INTEGER(listLength(def.enumLst))
                )
              ),
              Absyn.Exp.BINARY(
                Absyn.Exp.STRING("Enumeration index '"),
                Absyn.Operator.ADD(),
                Absyn.Exp.BINARY(
                  Absyn.Exp.CALL(
                    Absyn.ComponentRef.CREF_IDENT("String", {}),
                    Absyn.FunctionArgs.FUNCTIONARGS(
                      {Absyn.Exp.CREF(Absyn.ComponentRef.CREF_IDENT("index", {}))},
                      {}
                    ),
                    {}
                  ),
                  Absyn.Operator.ADD(),
                  Absyn.Exp.STRING("' out of bounds in call to " + enum_name + "()")
                )
              ),
              Absyn.Exp.CREF(Absyn.ComponentRef.CREF_QUAL(
                "AssertionLevel", {}, Absyn.ComponentRef.CREF_IDENT("error", {}))),
              SCode.noComment,
              info
            ),
            // value := {E.literal1, E.literal2, ...}[index];
            SCode.Statement.ALG_ASSIGN(
              Absyn.Exp.CREF(Absyn.ComponentRef.CREF_IDENT("value", {})),
              Absyn.Exp.SUBSCRIPTED_EXP(
                Absyn.Exp.ARRAY(
                  list(Absyn.Exp.CREF(Absyn.ComponentRef.CREF_QUAL(enum_name,
                          {}, Absyn.ComponentRef.CREF_IDENT(e.literal, {}))) for
                      e in def.enumLst)
                ),
                {Absyn.Subscript.SUBSCRIPT(Absyn.Exp.CREF(Absyn.ComponentRef.CREF_IDENT("index", {})))}
              ),
              SCode.noComment,
              info
            )
          };
          // end E;
        then
          SCode.ClassDef.PARTS(params, {}, {}, {SCode.AlgorithmSection.ALGORITHM(stmts)}, {}, {}, {}, NONE());

      else
        fail();
    end match;

    // Construct an SCode element from the definition. The element name is
    // prefixed with $ since we use the enumeration type inside the function,
    // and the lookup would otherwise find the function instead. But the flat
    // model will show the non-prefixed name since the name of the function is
    // defined when creating the Function object.
    fn_elem := SCode.Element.CLASS(
      "$" + enum_name,
      SCode.defaultPrefixes,
      SCode.Encapsulated.NOT_ENCAPSULATED(),
      SCode.Partial.NOT_PARTIAL(),
      SCode.Restriction.R_FUNCTION(SCode.FunctionRestriction.FR_NORMAL_FUNCTION(Absyn.FunctionPurity.PURE())),
      fn_def,
      SCode.Comment.COMMENT(NONE(), SOME("Automatically generated conversion operator for " + enum_name)),
      info
    );

    // Create a node from the SCode element.
    fnNode := InstNode.new(fn_elem, InstNode.parentScope(enumNode, ignoreRedeclare=true));
  end makeEnumConversionOp;

  function getCachedFuncs
    input InstNode inNode;
    output list<Function> outFuncs;
  protected
    CachedData cache;
  algorithm
    cache := InstNode.getFuncCache(InstNode.classScope(inNode));
    outFuncs := match cache
      case CachedData.FUNCTION() then cache.funcs;
      else {};
    end match;
  end getCachedFuncs;

  function mapCachedFuncs
    input InstNode inNode;
    input MapFn mapFn;

    partial function MapFn
      input output Function fn;
    end MapFn;
  protected
    InstNode cls_node;
    CachedData cache;
  algorithm
    cls_node := InstNode.classScope(inNode);
    cache := InstNode.getFuncCache(cls_node);

    cache := match cache
      case CachedData.FUNCTION()
        algorithm
          cache.funcs := list(mapFn(fn) for fn in cache.funcs);
        then
          cache;

      else fail();
    end match;

    InstNode.setFuncCache(cls_node, cache);
  end mapCachedFuncs;

  function isEvaluated
    input Function fn;
    output Boolean evaluated;
  algorithm
    evaluated := match Pointer.access(fn.status)
      case FunctionStatus.BUILTIN then true;
      case FunctionStatus.EVALUATED then true;
      else false;
    end match;
  end isEvaluated;

  function markEvaluated
    input Function fn;
  algorithm
    if Pointer.access(fn.status) <> FunctionStatus.BUILTIN then
      Pointer.update(fn.status, FunctionStatus.EVALUATED);
    end if;
  end markEvaluated;

  function isSimplified
    input Function fn;
    output Boolean simplified;
  algorithm
    simplified := match Pointer.access(fn.status)
      case FunctionStatus.BUILTIN then true;
      case FunctionStatus.SIMPLIFIED then true;
      else false;
    end match;
  end isSimplified;

  function markSimplified
    input Function fn;
  algorithm
    if Pointer.access(fn.status) <> FunctionStatus.BUILTIN then
      Pointer.update(fn.status, FunctionStatus.SIMPLIFIED);
    end if;
  end markSimplified;

  function isCollected
    "Returns true if this function has already been added to the function tree
     (or shouldn't be added, e.g. if it's builtin), otherwise false."
    input Function fn;
    output Boolean collected;
  algorithm
    collected := match Pointer.access(fn.status)
      case FunctionStatus.BUILTIN then true;
      case FunctionStatus.COLLECTED then true;
      else false;
    end match;
  end isCollected;

  function collect
    "Marks this function as collected for addition to the function tree."
    input Function fn;
  algorithm
    // The pointer might be immutable, check before assigning to it.
    if Pointer.access(fn.status) <> FunctionStatus.BUILTIN then
      Pointer.update(fn.status, FunctionStatus.COLLECTED);
    end if;
  end collect;

  function name
    input Function fn;
    output Absyn.Path path = fn.path;
  end name;

  function setName
    input Absyn.Path name;
    input output Function fn;
  algorithm
    fn.path := name;
  end setName;

  function nameConsiderBuiltin
    "Handles the DAE.mo structure where builtin calls are replaced by their simpler name"
    input Function fn;
    output Absyn.Path path;
  algorithm
    path := match fn.attributes.isBuiltin
      local
        String name;
      case DAE.FUNCTION_BUILTIN(name=SOME(name)) then Absyn.IDENT(name);
      case DAE.FUNCTION_BUILTIN() then AbsynUtil.pathLast(fn.path);
      else fn.path;
    end match;
  end nameConsiderBuiltin;

  function signatureString
    "Constructs a signature string for a function, e.g. Real func(Real x, Real y)"
    input Function fn;
    input Boolean printTypes = true;
    output String str;
  protected
    Absyn.Path fn_name;
    String input_str, output_str, var_s;
    list<String> inputs_strl = {};
    list<InstNode> inputs = fn.inputs;
    Component c;
    Expression def_exp;
    Type ty;
  algorithm
    for s in fn.slots loop
      input_str := "";
      c := InstNode.component(listHead(inputs));
      inputs := listRest(inputs);

      // Add the default expression if it has any.
      if isSome(s.default) then
        SOME(def_exp) := s.default;
        input_str := " = " + Expression.toString(def_exp);
      end if;

      // Add the name from the slot and not the node, since some builtin
      // functions don't bother using proper names for the nodes.
      input_str := Slot.name(s) + input_str;

      // Add a $ in front of the name if the parameter only takes positional
      // arguments.
      input_str := match s.ty
        case SlotType.POSITIONAL then "$" + input_str;
        else input_str;
      end match;

      // Add the type if the parameter has been typed.
      if printTypes and Component.isTyped(c) then
        ty := Component.getType(c);
        var_s := Prefixes.unparseVariability(Component.variability(c), ty);
        input_str := var_s + Type.toString(ty) + " " + input_str;
      end if;

      inputs_strl := input_str :: inputs_strl;
    end for;

    input_str := stringDelimitList(listReverse(inputs_strl), ", ");
    output_str := if printTypes and isTyped(fn) then " => " + Type.toString(fn.returnType) else "";
    fn_name := nameConsiderBuiltin(fn);
    // if isSome(display_name) then Util.getOption(display_name) else fn.path;
    str := AbsynUtil.pathString(fn_name) + "(" + input_str + ")" + output_str;
  end signatureString;

  function candidateFuncListString
    input list<Function> fns;
    output String s = stringDelimitList(list(Function.signatureString(fn, true) for fn in fns), "\n  ");
  end candidateFuncListString;

  function callString
    "Constructs a string representing a call, for use in error messages."
    input Function fn;
    input list<Expression> posArgs;
    input list<NamedArg> namedArgs;
    output String str;
  algorithm
    str := stringDelimitList(list(Expression.toString(arg) for arg in posArgs), ", ");

    if not listEmpty(namedArgs) then
      str := str + ", " + stringDelimitList(
        list(Util.tuple21(arg) + " = " + Expression.toString(Util.tuple22(arg))
          for arg in namedArgs), ", ");
    end if;

    str := AbsynUtil.pathString(fn.path) + "(" + str + ")";
  end callString;

  function typeString
    "Constructs a string representing the type of the function, on the form
     function_name<function>(inputs) => outputs"
    input Function fn;
    output String str;
  protected
    String inputs, outputs;

    function param_str
      input InstNode p;
      output String s = Type.toString(InstNode.getType(p)) + " " + InstNode.name(p);
    end param_str;
  algorithm
    inputs := List.toString(fn.inputs, param_str, "", "", ", ", "");
    outputs := List.toString(fn.outputs, param_str, "", "", ", ", "");

    if listEmpty(fn.outputs) or listLength(fn.outputs) > 1 then
      outputs := "(" + outputs + ")";
    end if;

    str := AbsynUtil.pathString(name(fn)) + "<function>(" + inputs + ") => " + outputs;
  end typeString;

  function toFlatStream
    input Function fn;
    input BaseModelica.OutputFormat format;
    input String indent;
    input output IOStream.IOStream s;
    input String overrideName = "";
  protected
    String fn_name;
    list<Statement> fn_body;
    SCode.Comment cmt;
    SCode.Mod annMod;
  algorithm
    if isDefaultRecordConstructor(fn) then
      s := Record.toFlatDeclarationStream(fn.node, format, indent, s);
    elseif isPartialDerivative(fn) then
      fn_name := if stringEmpty(overrideName) then Util.makeQuotedIdentifier(AbsynUtil.pathString(fn.path)) else overrideName;

      s := IOStream.append(s, indent);
      s := IOStream.append(s, "function ");
      s := IOStream.append(s, fn_name);
      s := IOStream.append(s, " = der(");
      s := IOStream.append(s, Util.makeQuotedIdentifier(AbsynUtil.pathString(getDerivedFunctionName(fn))));
      s := IOStream.append(s, ", ");
      s := IOStream.append(s, stringDelimitList(getDerivedInputNames(fn), ", "));
      s := FlatModelicaUtil.appendComment(SCodeUtil.getElementComment(InstNode.definition(fn.node)),
        NFFlatModelicaUtil.ElementType.FUNCTION, s);
      s := IOStream.append(s, ")");
    else
      cmt := Util.getOptionOrDefault(SCodeUtil.getElementComment(InstNode.definition(fn.node)), SCode.COMMENT(NONE(), NONE()));
      fn_name := if stringEmpty(overrideName) then Util.makeQuotedIdentifier(AbsynUtil.pathString(fn.path)) else overrideName;

      s := IOStream.append(s, indent);

      if InstNode.isPartial(fn.node) then
        s := IOStream.append(s, "partial ");
      end if;

      s := IOStream.append(s, "function ");
      s := IOStream.append(s, fn_name);
      s := FlatModelicaUtil.appendCommentString(SOME(cmt), s);
      s := IOStream.append(s, "\n");

      for i in fn.inputs loop
        s := IOStream.append(s, InstNode.toFlatString(i, format, indent + "  "));
        s := IOStream.append(s, ";\n");
      end for;

      for o in fn.outputs loop
        s := IOStream.append(s, InstNode.toFlatString(o, format, indent + "  "));
        s := IOStream.append(s, ";\n");
      end for;

      if not listEmpty(fn.locals) then
        for l in fn.locals loop
          s := IOStream.append(s, InstNode.toFlatString(l, format, indent + "  "));
          s := IOStream.append(s, ";\n");
        end for;
      end if;

      s := Sections.toFlatStream(InstNode.getSections(fn.node), fn.path, format, indent, s);

      if isSome(cmt.annotation_) then
        SOME(SCode.ANNOTATION(modification=annMod)) := cmt.annotation_;
      else
        annMod := SCode.NOMOD();
      end if;
      // Generate derivative/inverse annotations from the instantiated model. Paths have changed.
      annMod := SCodeUtil.filterSubMods(annMod,
        function SCodeUtil.removeGivenSubModNames(namesToRemove={"derivative", "inverse"}));

      for derivative in listReverse(fn.derivatives) loop
        annMod := SCodeUtil.prependSubModToMod(FunctionDerivative.toSubMod(derivative), annMod);
      end for;

      for i in arrayLength(fn.inverses):-1:1 loop
        annMod := SCodeUtil.prependSubModToMod(FunctionInverse.toSubMod(fn.inverses[i]), annMod);
      end for;

      if not SCodeUtil.emptyModOrEquality(annMod) then
        cmt := SCode.COMMENT(SOME(SCode.ANNOTATION(annMod)), NONE());
        s := FlatModelicaUtil.appendCommentAnnotation(SOME(cmt),
          NFFlatModelicaUtil.ElementType.FUNCTION, indent + "  ", ";\n", s);
      end if;

      s := IOStream.append(s, indent);
      s := IOStream.append(s, "end ");
      s := IOStream.append(s, fn_name);
    end if;
  end toFlatStream;

  function toFlatString
    input Function fn;
    input BaseModelica.OutputFormat format = BaseModelica.defaultFormat;
    input String indent = "";
    output String str;
  protected
    IOStream.IOStream s;
  algorithm
    s := IOStream.create(getInstanceName(), IOStream.IOStreamType.LIST());
    s := toFlatStream(fn, format, indent, s);
    str := IOStream.string(s);
    IOStream.delete(s);
  end toFlatString;

  function instance
    input Function fn;
    output InstNode node = fn.node;
  end instance;

  function returnType
    input Function fn;
    output Type ty = fn.returnType;
  end returnType;

  function setReturnType
    input Type ty;
    input output Function fn;
  algorithm
    fn.returnType := ty;
  end setReturnType;

  function getSlots
    input Function fn;
    output list<Slot> slots = fn.slots;
  end getSlots;

  function fillArgs
    "Matches the given arguments to the slots in a function, and returns the
     arguments sorted in the order of the function parameters."
    input list<TypedArg> posArgs;
    input list<TypedArg> namedArgs;
    input Function fn;
    input InstContext.Type context;
    input SourceInfo info;
    output list<TypedArg> args = posArgs;
    output Boolean matching;
  protected
    Slot slot;
    list<Slot> slots, remaining_slots;
    list<TypedArg> filled_named_args;
    array<Slot> slots_arr;
    Integer pos_arg_count, slot_count, index = 1;
  algorithm
    slots := fn.slots;
    pos_arg_count := listLength(posArgs);
    slot_count := listLength(slots);

    if pos_arg_count > slot_count then
      // If we have too many positional arguments it can't possibly match.
      matching := false;
      return;
    elseif pos_arg_count == slot_count and listEmpty(namedArgs) then
      // If we have exactly as many positional arguments as slots and no named
      // arguments we can just return the list of arguments as it is.
      matching := true;
      return;
    end if;

    slots_arr := listArray(slots);

    for arg in args loop
      slot := slots_arr[index];

      if not Slot.positional(slot) then
        // Slot doesn't allow positional arguments (used for some builtin functions).
        matching := false;
        return;
      end if;

      slot.arg := SOME(arg);
      arrayUpdate(slots_arr, index, slot);
      index := index + 1;
    end for;

    for narg in namedArgs loop
      (slots_arr, matching) := fillNamedArg(narg, slots_arr, fn, info);

      if not matching then
        return;
      end if;
    end for;

    (args, matching) := collectArgs(slots_arr, context, info);
  end fillArgs;

  function fillNamedArg
    "Looks up a slot with the given name and tries to fill it with the given
     argument expression."
    input TypedArg arg;
    input output array<Slot> slots;
    input Function fn "For error reporting";
    input SourceInfo info;
          output Boolean matching = true;
  protected
    Slot s;
    String arg_name;
  algorithm
    // Try to find a slot and fill it with the argument expression.
    // Positional arguments fill the slots from the start of the array, so
    // searching backwards will generally be a bit more efficient.
    for i in arrayLength(slots):-1:1 loop
      s := slots[i];

      SOME(arg_name) := arg.name;

      if Slot.name(s) == arg_name then
        if not Slot.named(s) then
          // Slot doesn't allow named argument (used for some builtin functions).
          matching := false;
        elseif isNone(s.arg) then
          s.arg := SOME(arg);
          slots[i] := s;
        else
          // TODO: Improve the error message, should mention function name.
          Error.addSourceMessage(Error.FUNCTION_SLOT_ALREADY_FILLED,
            {arg_name, ""}, info);
          matching := false;
        end if;

        return;
      end if;
    end for;

    // No slot could be found.
    matching := false;

    // A slot with the given name couldn't be found. This means it doesn't
    // exist, or we removed it when handling positional argument. We need to
    // search through all slots to be sure.
    for s in fn.slots loop
      if arg_name == Slot.name(s) then
        // We found a slot, so it must have already been filled.
        Error.addSourceMessage(Error.FUNCTION_SLOT_ALREADY_FILLED,
          {arg_name, ""}, info);
        return;
      end if;

      // No slot could be found, so it doesn't exist.
      Error.addSourceMessage(Error.NO_SUCH_INPUT_PARAMETER,
        {InstNode.name(instance(fn)), arg_name}, info);
    end for;

  end fillNamedArg;

  function collectArgs
    "Collects the arguments from the given slots."
    input array<Slot> slots;
    input InstContext.Type context;
    input SourceInfo info;
    output list<TypedArg> args = {};
    output Boolean matching = true;
  protected
    Option<Expression> default;
    Expression e;
    Option<TypedArg> arg;
    TypedArg a;
  algorithm
    for s in slots loop
      SLOT(default = default, arg = arg) := s;

      args := matchcontinue arg
        // Use the argument from the call if one was given.
        case SOME(a) then a :: args;

        // Otherwise, try to fill the slot with its default argument.
        case _ then fillDefaultSlot(s, slots, context, info) :: args;

        else
          algorithm
            matching := false;
          then
            args;
      end matchcontinue;
    end for;

    args := listReverse(args);
  end collectArgs;

  function fillDefaultSlot
    input Slot slot;
    input array<Slot> slots;
    input InstContext.Type context;
    input SourceInfo info;
    output TypedArg outArg;
  algorithm
    outArg := match slot
      // Slot already filled by function argument.
      case SLOT(arg = SOME(outArg)) then outArg;

      // Slot not filled by function argument, but has default value.
      case SLOT(default = SOME(_))
        then fillDefaultSlot2(slot, slots, context, info);

      // Give an error if no argument was given and there's no default argument.
      else
        algorithm
          Error.addSourceMessage(Error.UNFILLED_SLOT, {Slot.name(slot)}, info);
        then
          fail();

    end match;
  end fillDefaultSlot;

  function fillDefaultSlot2
    input Slot slot;
    input array<Slot> slots;
    input InstContext.Type context;
    input SourceInfo info;
    output TypedArg outArg;
  algorithm
    outArg := match slot.evalStatus
      local
        Expression exp;
        Type ty;
        Variability var;
        Purity pur;

      // An already evaluated slot, return its binding.
      case SlotEvalStatus.EVALUATED
        then Util.getOption(slot.arg);

      // A slot in the process of being evaluated => cyclic bindings.
      case SlotEvalStatus.EVALUATING
        algorithm
          Error.addSourceMessage(Error.CYCLIC_DEFAULT_VALUE, {Slot.name(slot)}, info);
        then
          fail();

      // A slot with a not evaluated binding, evaluate the binding and return it.
      case SlotEvalStatus.NOT_EVALUATED
        algorithm
          slot.evalStatus := SlotEvalStatus.EVALUATING;
          arrayUpdate(slots, slot.index, slot);

          exp := evaluateSlotExp(Util.getOption(slot.default), slots, context, info);
          (exp, ty, var, pur) := Typing.typeExp(exp, context, info);
          outArg := TypedArg.TYPED_ARG(NONE(), exp, ty, var, pur);

          slot.arg := SOME(outArg);
          slot.evalStatus := SlotEvalStatus.EVALUATED;
          arrayUpdate(slots, slot.index, slot);
        then
          outArg;

    end match;
  end fillDefaultSlot2;

  function evaluateSlotExp
    input Expression exp;
    input array<Slot> slots;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression outExp;
  algorithm
    outExp := Expression.map(exp,
      function evaluateSlotExp_traverser(slots = slots, context = context, info = info));
  end evaluateSlotExp;

  function evaluateSlotExp_traverser
    input Expression exp;
    input array<Slot> slots;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression outExp;
  algorithm
    outExp := match exp
      case Expression.CREF() then evaluateSlotCref(exp, slots, context, info);
      else exp;
    end match;
  end evaluateSlotExp_traverser;

  function evaluateSlotCref
    input output Expression crefExp;
    input array<Slot> slots;
    input InstContext.Type context;
    input SourceInfo info;
  protected
    ComponentRef cref;
    Type cref_ty;
    list<ComponentRef> cref_parts;
    Option<Slot> slot;
    TypedArg arg;
    InstNode cref_node;
  algorithm
    Expression.CREF(cref = cref, ty = cref_ty) := crefExp;

    if not ComponentRef.isCref(cref) then
      return;
    end if;

    cref :: cref_parts := ComponentRef.toListReverse(cref);
    cref_node := ComponentRef.node(cref);
    slot := lookupSlotInArray(cref_node, slots);

    if isSome(slot) then
      arg := fillDefaultSlot(Util.getOption(slot), slots, context, info);
      crefExp := arg.value;
      crefExp := applyCrefSubs(cref, crefExp);

      for cr in cref_parts loop
        crefExp := Expression.recordElement(ComponentRef.firstName(cr), crefExp);
        crefExp := applyCrefSubs(cref, crefExp);
      end for;

      if Type.isKnown(cref_ty) then
        crefExp := TypeCheck.matchTypes(Expression.typeOf(crefExp), cref_ty, crefExp);
      end if;
    end if;
  end evaluateSlotCref;

  function applyCrefSubs
    input ComponentRef cref;
    input output Expression exp;
  protected
    list<Subscript> subs;
  algorithm
    subs := ComponentRef.getSubscripts(cref);

    if listEmpty(subs) then
      return;
    end if;

    try
      exp := Expression.applySubscripts(subs, exp);
    else
      // Applying the subscripts might not work if the expression is not typed,
      // in that case just create a subscripted expression.
      exp := Expression.SUBSCRIPTED_EXP(exp, subs, ComponentRef.getSubscriptedType(cref), false);
    end try;
  end applyCrefSubs;

  function lookupSlotInArray
    input InstNode node;
    input array<Slot> slots;
    output Option<Slot> outSlot;
  protected
    Slot slot;
  algorithm
    try
      slot := Array.getMemberOnTrue(node, slots, Slot.hasNode);
      outSlot := SOME(slot);
    else
      outSlot := NONE();
    end try;
  end lookupSlotInArray;

  function matchArgs
    input Function func;
    input output list<TypedArg> args;
    input SourceInfo info;
    input Boolean vectorize = true;
          output FunctionMatchKind funcMatchKind = EXACT_MATCH;
  protected
    Component comp;
    list<InstNode> inputs = func.inputs;
    InstNode input_node;
    Integer arg_idx = 1;
    list<TypedArg> checked_args = {};
    Expression arg_exp;
    Type arg_ty, input_ty, ty;
    Variability arg_var;
    TypeCheck.MatchKind mk;
    Expression vect_arg = Expression.INTEGER(0);
    list<Dimension> vect_dims = {};
    Boolean matched;
    list<Integer> vectorized_args = {};
  algorithm
    for arg in args loop
      TypedArg.TYPED_ARG(value = arg_exp, ty = arg_ty, var = arg_var) := arg;

      input_node :: inputs := inputs;
      comp := InstNode.component(input_node);

      // Check that the variability of the argument and input parameter matches.
      if arg_var > Component.variability(comp) then
        Error.addSourceMessage(Error.FUNCTION_SLOT_VARIABILITY,
          {InstNode.name(input_node), Expression.toString(arg_exp),
           AbsynUtil.pathString(Function.name(func)), Prefixes.variabilityString(arg_var),
           Prefixes.variabilityString(Component.variability(comp))}, info);
        funcMatchKind := NO_MATCH;
        return;
      end if;

      // Check if the type of the argument and the input parameter matches exactly.
      input_ty := Component.getType(comp);
      (arg_exp, ty, mk) := TypeCheck.matchTypes(arg_ty, input_ty, arg_exp, NFTypeCheck.ALLOW_UNKNOWN);
      matched := TypeCheck.isValidArgumentMatch(mk);

      if not matched and vectorize then
        // If the types don't match, try to vectorize the argument.
        (arg_exp, ty, vect_arg, vect_dims, mk) :=
          matchArgVectorized(arg_exp, arg_ty, input_ty, vect_arg, vect_dims, info);
        vectorized_args := arg_idx :: vectorized_args;
        matched := TypeCheck.isValidArgumentMatch(mk);
      end if;

      if not matched then
        // Print an error if the types match neither exactly nor vectorized.
        Error.addSourceMessage(Error.ARG_TYPE_MISMATCH,
          {intString(arg_idx), AbsynUtil.pathString(func.path), InstNode.name(input_node),
           Expression.toString(arg_exp), Type.toString(arg_ty), Type.toString(input_ty)}, info);
        funcMatchKind := NO_MATCH;
        return;
      end if;

      // TODO: This should be a running reduction of the matches. Not just based on the
      // last match.
      if TypeCheck.isCastMatch(mk) then
        funcMatchKind := CAST_MATCH;
      elseif TypeCheck.isGenericMatch(mk) then
        funcMatchKind := GENERIC_MATCH;
      end if;

      checked_args := TypedArg.TYPED_ARG(arg.name, arg_exp, ty, arg_var, arg.purity) :: checked_args;
      arg_idx := arg_idx + 1;
    end for;

    if not listEmpty(vectorized_args) then
      funcMatchKind := FunctionMatchKind.VECTORIZED(vect_dims, listReverse(vectorized_args), funcMatchKind);
    end if;

    args := listReverse(checked_args);
  end matchArgs;

  function matchArgVectorized
    input output Expression argExp;
    input output Type argTy;
    input Type inputTy;
    input output Expression vectArg;
    input output list<Dimension> vectDims;
    input SourceInfo info;
          output TypeCheck.MatchKind matchKind;
  protected
    list<Dimension> arg_dims, input_dims, vect_dims, rest_dims;
    Type rest_ty;
    TypeCheck.MatchKind mk;
    Integer vect_dims_count;
  algorithm
    arg_dims := Type.arrayDims(argTy);
    input_dims := Type.arrayDims(inputTy);
    vect_dims_count := listLength(arg_dims) - listLength(input_dims);

    // Only try to vectorize if the argument has more dimensions than the input parameter.
    if vect_dims_count < 1 then
      matchKind := MatchKind.NOT_COMPATIBLE;
      return;
    end if;

    (vect_dims, rest_dims) := List.split(arg_dims, vect_dims_count);

    // Make sure the vectorization dimensions are consistent.
    if listEmpty(vectDims) then
      vectDims := fillUnknownVectorizedDims(vect_dims, argExp);
      vectArg := argExp;
    elseif not List.isEqualOnTrue(vectDims, vect_dims, Dimension.isEqual) then
      Error.addSourceMessage(Error.VECTORIZE_CALL_DIM_MISMATCH,
        {"", Expression.toString(vectArg), "", Expression.toString(argExp),
         Dimension.toStringList(vectDims), Dimension.toStringList(vect_dims)}, info);
    end if;

    // Check that the argument and the input parameter are type compatible when
    // the dimensions to vectorize over has been removed from the argument's type.
    rest_ty := Type.liftArrayLeftList(Type.arrayElementType(argTy), rest_dims);
    (argExp, argTy, matchKind) := TypeCheck.matchTypes(rest_ty, inputTy, argExp);
  end matchArgVectorized;

  function fillUnknownVectorizedDims
    "Helper function to matchArgVectorized. Replaces unknown dimensions in the
     list with size(argExp, dimension index), so that vectorized calls involving
     unknown dimensions (e.g. in functions) can be handled correctly."
    input list<Dimension> dims;
    input Expression argExp;
    output list<Dimension> outDims = {};
  protected
    Integer i = 1;
  algorithm
    for dim in dims loop
      if Dimension.isUnknown(dim) then
        dim := Dimension.EXP(Expression.SIZE(argExp, SOME(Expression.INTEGER(i))), Variability.CONTINUOUS);
      end if;

      outDims := dim :: outDims;
      i := i + 1;
    end for;

    outDims := listReverseInPlace(outDims);
  end fillUnknownVectorizedDims;

  function matchFunction
    input Function func;
    input list<TypedArg> args;
    input list<TypedArg> named_args;
    input InstContext.Type context;
    input SourceInfo info;
    input Boolean vectorize = true;
    output list<TypedArg> out_args;
    output FunctionMatchKind matchKind = NO_MATCH;
  protected
    Boolean slot_matched;
  algorithm
    (out_args, slot_matched) := fillArgs(args, named_args, func, context, info);

    if slot_matched then
      (out_args, matchKind) := matchArgs(func, out_args, info, vectorize);
    end if;
  end matchFunction;

  function matchFunctions
    input list<Function> funcs;
    input list<TypedArg> args;
    input list<TypedArg> named_args;
    input InstContext.Type context;
    input SourceInfo info;
    input Boolean vectorize = true;
    output list<MatchedFunction> matchedFunctions;
  protected
    list<TypedArg> m_args;
    FunctionMatchKind matchKind;
    Boolean matched;
  algorithm
    matchedFunctions := {};
    for func in funcs loop
      (m_args, matchKind) := matchFunction(func, args, named_args, context, info, vectorize);

      if FunctionMatchKind.isValid(matchKind) then
        matchedFunctions := MatchedFunction.MATCHED_FUNC(func,m_args,matchKind)::matchedFunctions;
      end if;
    end for;
  end matchFunctions;

  function matchFunctionsSilent
    input list<Function> funcs;
    input list<TypedArg> args;
    input list<TypedArg> named_args;
    input InstContext.Type context;
    input SourceInfo info;
    input Boolean vectorize = true;
    output list<MatchedFunction> matchedFunctions;
  protected
  algorithm
    ErrorExt.setCheckpoint("NFFunction:matchFunctions");
    matchedFunctions := matchFunctions(funcs, args, named_args, context, info, vectorize);
    ErrorExt.rollBack("NFFunction:matchFunctions");
  end matchFunctionsSilent;

  function isTyped
    input Function fn;
    output Boolean isTyped;
  algorithm
    isTyped := match fn.returnType
      case Type.UNKNOWN() then false;
      else true;
    end match;
  end isTyped;

  function typeRefCache
    "Returns the function(s) referenced by the given cref, and types them if
     they are not already typed."
    input ComponentRef functionRef;
    input InstContext.Type context = NFInstContext.FUNCTION;
    output list<Function> functions;
  algorithm
    functions := match functionRef
      case ComponentRef.CREF() then typeNodeCache(functionRef.node, context);
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got invalid function call reference", sourceInfo());
        then
          fail();
    end match;
  end typeRefCache;

  function typeNodeCache
    "Returns the function(s) in the cache of the given node, and types them if
     they are not already typed."
    input InstNode functionNode;
    input InstContext.Type context = NFInstContext.FUNCTION;
    output list<Function> functions;
  protected
    InstNode fn_node;
    Boolean typed, special;
    String name;
  algorithm
    fn_node := InstNode.classScope(functionNode);
    CachedData.FUNCTION(functions, typed, special) := InstNode.getFuncCache(fn_node);

    // Type the function(s) if not already done.
    if not typed then
      functions := list(typeFunctionSignature(f, context) for f in functions);
      InstNode.setFuncCache(fn_node, CachedData.FUNCTION(functions, true, special));
      functions := list(typeFunctionBody(f, context) for f in functions);
      InstNode.setFuncCache(fn_node, CachedData.FUNCTION(functions, true, special));
    end if;
  end typeNodeCache;

  function getRefCache
    input ComponentRef fnRef;
    output list<Function> functions;
  protected
    InstNode fn_node;
  algorithm
    fn_node := InstNode.classScope(ComponentRef.node(fnRef));
    CachedData.FUNCTION(funcs = functions) := InstNode.getFuncCache(fn_node);
  end getRefCache;

  function typeFunction
    input output Function fn;
    input InstContext.Type context = NFInstContext.FUNCTION;
  algorithm
    fn := typeFunctionSignature(fn, context);
    fn := typeFunctionBody(fn, context);
  end typeFunction;

  function typeFunctionSignature
    "Types a function's parameters and local components."
    input output Function fn;
    input InstContext.Type context;
  protected
    DAE.FunctionAttributes attr;
    InstNode node = fn.node;
    InstContext.Type fn_context;
  algorithm
    if not isTyped(fn) then
      fn_context := InstContext.set(context, NFInstContext.FUNCTION);
      fn.slots := makeSlots(fn.inputs);

      // Type all the components in the function.
      Typing.typeClassType(node, NFBinding.EMPTY_BINDING, fn_context, node);
      Typing.typeComponents(node, fn_context, preserveDerived = isPartialDerivative(fn));

      if InstNode.isPartial(node) then
        ClassTree.applyComponents(Class.classTree(InstNode.getClass(node)), boxFunctionParameter);
      end if;

      // Make the slots and return type for the function.
      checkParamTypes(fn);
      checkPartialDerivativeTypes(fn);
      fn.returnType := makeReturnType(fn);
    end if;
  end typeFunctionSignature;

  function typeFunctionBody
    "Types the body of a function, along with any component bindings."
    input output Function fn;
    input InstContext.Type context;
  protected
    Boolean pure;
    DAE.FunctionAttributes attr;
    InstContext.Type fn_context;
  algorithm
    fn_context := InstContext.set(context, NFInstContext.FUNCTION);

    // Type the bindings of components in the function.
    for c in fn.inputs loop
      Typing.typeComponentBinding(c, fn_context);
    end for;

    for c in fn.outputs loop
      Typing.typeComponentBinding(c, fn_context);
    end for;

    for c in fn.locals loop
      Typing.typeComponentBinding(c, fn_context);
    end for;

    // Type the algorithm section of the function, if it has one.
    Typing.typeFunctionSections(fn.node, fn_context);

    // Type any derivatives of the function.
    for fn_der in fn.derivatives loop
      FunctionDerivative.typeDerivative(fn_der);
    end for;

    // Type any inverses of the function.
    Array.mapNoCopy(fn.inverses, FunctionInverse.typeInverse);

    // If the function is pure, check that it doesn't contain any impure calls.
    if not isImpure(fn) then
      pure := foldExp(fn, function checkPureCall(fn = fn), true);

      // The function does contain impure calls, mark the function as impure.
      if not pure then
        attr := fn.attributes;
        attr.isImpure := true;
        fn.attributes := attr;
      end if;
    end if;

    if not InstContext.inRelaxed(fn_context) then
      checkUseBeforeAssign(fn);
    end if;

    // Sort the local variables based on their dependencies.
    fn.locals := sortLocals(fn.locals, InstNode.info(fn.node));
  end typeFunctionBody;

  function checkPureCall
    input Expression exp;
    input Function fn;
    input output Boolean pure;
  algorithm
    if not pure then
      return;
    end if;

    if Expression.isImpureCall(exp) then
      pure := false;

      if Config.languageStandardAtLeast(Config.LanguageStandard.'3.3') then
        Error.addSourceMessage(Error.PURE_FUNCTION_WITH_IMPURE_CALLS,
          {AbsynUtil.pathString(Function.name(fn)), Expression.getName(exp)},
          InstNode.info(fn.node));
      end if;
    end if;
  end checkPureCall;

  function boxFunctionParameter
    input InstNode component;
  protected
    Component comp;
  algorithm
    comp := InstNode.component(component);
    comp := Component.setType(Type.box(Component.getType(comp)), comp);
    InstNode.updateComponent(comp, component);
  end boxFunctionParameter;

  function typePartialApplication
    input output Expression exp;
    input InstContext.Type context;
    input SourceInfo info;
          output Type ty;
          output Variability variability;
          output Purity purity;
  protected
    ComponentRef fn_ref;
    list<Expression> args, ty_args = {};
    list<String> arg_names, rest_names;
    String arg_name;
    Expression arg_exp;
    Type arg_ty;
    Variability arg_var;
    Purity arg_pur;
    Function fn;
    InstContext.Type next_context = InstContext.set(context, NFInstContext.SUBEXPRESSION);
    list<InstNode> inputs;
    list<Slot> slots;
    array<Slot> slots_arr;
    TypedArg ty_arg;
    TypeCheck.MatchKind mk;
  algorithm
    Expression.PARTIAL_FUNCTION_APPLICATION(fn = fn_ref, args = args, argNames = arg_names) := exp;
    // TODO: Handle overloaded functions?
    fn :: _ := typeRefCache(fn_ref);
    slots_arr := listArray(fn.slots);

    purity := if Function.isImpure(fn) or Function.isOMImpure(fn) then Purity.IMPURE else Purity.PURE;
    variability := Variability.CONSTANT;

    // Type the arguments and add them to the slots.
    for arg in args loop
      (arg, arg_ty, arg_var, arg_pur) := Typing.typeExp(arg, next_context, info);
      arg_name :: arg_names := arg_names;
      ty_arg := TypedArg.TYPED_ARG(SOME(arg_name), arg, arg_ty, arg_var, arg_pur);
      (slots_arr, true) := fillNamedArg(ty_arg, slots_arr, fn, info);
      variability := Prefixes.variabilityMax(variability, arg_var);
      purity := Prefixes.purityMin(purity, arg_pur);
    end for;

    exp := makePartialApplicationFromSlots(slots_arr, fn, fn_ref, info);
    ty := Expression.typeOf(exp);
  end typePartialApplication;

  function makePartialApplicationFromSlots
    input array<Slot> slotsArray;
    input Function fn;
    input ComponentRef fnRef;
    input SourceInfo info;
    output Expression outExp;
  protected
    list<InstNode> inputs = {};
    list<Slot> slots = {};
    list<Expression> args = {};
    list<String> arg_names = {};
    TypedArg ty_arg;
    Expression arg;
    TypeCheck.MatchKind mk;
    Type fn_ty;
  algorithm
    for slot in slotsArray loop
      if isSome(slot.arg) then
        // For each slot that's filled, type check the argument and add it to
        // the arguments of the partial function application.
        SOME(ty_arg) := slot.arg;
        (arg, _, mk) := TypeCheck.matchTypes(ty_arg.ty, InstNode.getType(slot.node), ty_arg.value, NFTypeCheck.ALLOW_UNKNOWN);

        if TypeCheck.isIncompatibleMatch(mk) then
          Error.addSourceMessage(Error.NAMED_ARG_TYPE_MISMATCH,
            {AbsynUtil.pathString(name(fn)), Util.getOption(ty_arg.name), Expression.toString(ty_arg.value),
             Type.toString(ty_arg.ty), Type.toString(InstNode.getType(slot.node))}, info);
          fail();
        end if;

        args := Expression.box(arg) :: args;
        arg_names := Util.getOption(ty_arg.name) :: arg_names;
      else
        // For each slot that's not filled, add it as an input of the partially evaluated function.
        inputs := slot.node :: inputs;
        slots := slot :: slots;
      end if;
    end for;

    fn.inputs := listReverseInPlace(inputs);
    fn.slots := listReverseInPlace(slots);
    fn_ty := Type.FUNCTION(fn, NFType.FunctionType.FUNCTIONAL_VARIABLE);
    args := listReverseInPlace(args);
    arg_names := listReverseInPlace(arg_names);
    outExp := Expression.PARTIAL_FUNCTION_APPLICATION(fnRef, args, arg_names, fn_ty);
  end makePartialApplicationFromSlots;

  function isBuiltin
    input Function fn;
    output Boolean isBuiltin = isBuiltinAttr(fn.attributes);
  end isBuiltin;

  function isBuiltinAttr
    input DAE.FunctionAttributes attrs;
    output Boolean isBuiltin;
  algorithm
    isBuiltin := match attrs.isBuiltin
      case DAE.FunctionBuiltin.FUNCTION_NOT_BUILTIN() then false;
      else true;
    end match;
  end isBuiltinAttr;

  function isSpecialBuiltin
    "Returns whether or not a Function refers to a builtin function that doesn't
     follow normal Modelica rules and instead needs special handling."
    input Function fn;
    output Boolean special;
  protected
    Absyn.Path path;
  algorithm
    if not isBuiltin(fn) then
      special := false;
    else
      path := Function.nameConsiderBuiltin(fn);

      if not AbsynUtil.pathIsIdent(path) then
        special := false;
      else
        special := match AbsynUtil.pathFirstIdent(path)
          // Can have variable number of arguments.
          case "array" then true;
          case "actualStream" then true;
          case "backSample" then true;
          case "branch" then true;
          case "cardinality" then true;
          case "cat" then true;
          // Function should not be used in function context.
          // argument should be a cref?
          case "change" then true;
          case "der" then true;
          // Function should not be used in function context.
          case "edge" then true;
          // can have variable number of arguments
          case "fill" then true;
          case "getInstanceName" then true;
          // Always discrete.
          case "initial" then true;
          case "inStream" then true;
          case "isRoot" then true;
          // Arguments can be scalar, vector, matrix, 3d array .... basically anything
          // We need to make sure size(Arg,i) = 1 for 2 < i <= ndims(Arg).
          // return type should always be Matrix.
          case "matrix" then true;
          // Needs to check that arguments are basic types or enums
          // We need to check array inputs as well
          case "max" then true;
          // Needs to check that arguments are basic types or enums
          // We need to check array inputs as well
          case "min" then true;
          // Argument can have any number of dimensions.
          case "ndims" then true;
          // Can take any expression as argument.
          case "noEvent" then true;
          // can have variable number of arguments
          case "ones" then true;
          case "potentialRoot" then true;
          // Function should not be used in function context.
          // argument should be a cref?
          case "pre" then true;
          // needs unboxing and return type fix.
          case "promote" then true;
          case "pure" then true;
          case "root" then true;
          case "rooted" then true;
          case "uniqueRoot" then true;
          case "uniqueRootIndices" then true;
          // We need to make sure size(Arg,i) = 1 for 0 <= i <= ndims(Arg).
          // return type should always be scalar.
          case "scalar" then true;
          // First argument can have any number of dimensions.
          case "size" then true;
          case "shiftSample" then true;
          // Needs to check that second argument is real or array of real or record of reals.
          case "smooth" then true;
          case "subSample" then true;
          // needs unboxing and return type fix.
          case "superSample" then true;
          // unbox args and set return type.
          case "symmetric" then true;
          // Always discrete.
          case "terminal" then true;
          // unbox args and set return type (swap the first two dims).
          case "transpose" then true;
          // We need to construct output diminsion size from the size of elements in the array
          // return type should always be vector.
          case "vector" then true;
          // can have variable number of arguments
          case "zeros" then true;
          // sample - overloaded for sync features
          case "sample" then true;
          else false;
        end match;
      end if;
    end if;
  end isSpecialBuiltin;

  function isSubscriptableBuiltin
    input Function fn;
    output Boolean scalarBuiltin;
  protected
  algorithm
    if not isBuiltin(fn) then
      scalarBuiltin := false;
    else
      scalarBuiltin := match AbsynUtil.pathFirstIdent(Function.nameConsiderBuiltin(fn))
        case "change" then true;
        case "der" then true;
        case "pre" then true;
        else false;
      end match;
    end if;
  end isSubscriptableBuiltin;

  function isImpure
    input Function fn;
    output Boolean isImpure = fn.attributes.isImpure;
  end isImpure;

  function isOMImpure
    input Function fn;
    output Boolean isImpure = not fn.attributes.isOpenModelicaPure;
  end isOMImpure;

  function isFunctionPointer
    input Function fn;
    output Boolean isPointer = fn.attributes.isFunctionPointer;
  end isFunctionPointer;

  function setFunctionPointer
    input Boolean isPointer;
    input output Function fn;
  protected
    DAE.FunctionAttributes attr = fn.attributes;
  algorithm
    attr.isFunctionPointer := isPointer;
    fn.attributes := attr;
    // The whole function should just be this, but it doesn't compile yet.
    //fn.attributes.isFunctionPointer := isPointer;
  end setFunctionPointer;

  function isExternal
    input Function fn;
    output Boolean isExternal = not InstNode.isEmpty(fn.node) and
                                Class.isExternalFunction(InstNode.getClass(fn.node));
  end isExternal;

  function isExternalObjectConstructorOrDestructor
    input Function fn;
    output Boolean isExternal;
  protected
    Absyn.Path path;
    String lastIdent;
  algorithm
    path := name(fn);
    lastIdent := AbsynUtil.pathLastIdent(path);
    isExternal := false;
    if lastIdent == "constructor" then
      isExternal := Type.isExternalObject(fn.returnType);
    elseif lastIdent == "destructor" then
      if listLength(fn.inputs) == 1 then
        isExternal := Type.isExternalObject(Component.getType(InstNode.component(listHead(fn.inputs))));
      end if;
    end if;
  end isExternalObjectConstructorOrDestructor;

  function isPartialDerivative
    "Returns true if the function is a partial derivative of a function, df = der(f, x)."
    input Function fn;
    output Boolean res = not listEmpty(fn.derivedInputs);
  end isPartialDerivative;

  function getDerivedInputNames
    "Returns the names of the differentiated inputs in a partial derivative,
     df = der(f, x, y, z) => {\"x\", \"y\", \"z\"}"
    input Function fn;
    output list<String> names = {};
  algorithm
    for i in fn.derivedInputs loop
      names := InstNode.name(listGet(fn.inputs, i)) :: names;
    end for;

    names := listReverseInPlace(names);
  end getDerivedInputNames;

  function getDerivedFunctionName
    "Returns the name of the derived function in a partial derivative, df = der(f, x) => f"
    input Function fn;
    output Absyn.Path name = InstNode.fullPath(Class.lastBaseClass(fn.node), ignoreBaseClass = true);
  end getDerivedFunctionName;

  function inlineBuiltin
    input Function fn;
    output DAE.InlineType inlineType;
  algorithm
    inlineType := match fn.attributes.isBuiltin
      case DAE.FunctionBuiltin.FUNCTION_BUILTIN_PTR()
        then DAE.InlineType.BUILTIN_EARLY_INLINE();
      else fn.attributes.inline;
    end match;
  end inlineBuiltin;

  function isDefaultRecordConstructor
    input Function fn;
    output Boolean isConstructor = Restriction.isRecordConstructor(InstNode.restriction(fn.node));
  end isDefaultRecordConstructor;

  function isNonDefaultRecordConstructor
    input Function fn;
    output Boolean b = isNonDefaultRecordConstructorPath(fn.path);
    function isNonDefaultRecordConstructorPath
      input Absyn.Path path;
      output Boolean b;
    algorithm
      b := match path
        case Absyn.Path.QUALIFIED(name = "'constructor'") then true;
        case Absyn.Path.QUALIFIED()                       then isNonDefaultRecordConstructorPath(path.path);
        else false;
      end match;
    end isNonDefaultRecordConstructorPath;
  end isNonDefaultRecordConstructor;

  function toDAE
    input Function fn;
    input DAE.FunctionDefinition def;
    output DAE.Function daeFn;
  protected
    SCode.Visibility vis;
    Boolean par, impr;
    DAE.InlineType ity;
    DAE.Type ty;
    list<DAE.FunctionDefinition> defs;
    list<Integer> unused_inputs;
  algorithm
    vis := SCode.PUBLIC(); // TODO: Use the actual visibility.
    par := false; // TODO: Use the actual partial prefix.
    impr := fn.attributes.isImpure;
    ity := fn.attributes.inline;
    ty := makeDAEType(fn);
    unused_inputs := analyseUnusedParameters(fn);
    defs := list(FunctionInverse.toDAE(fn_inv) for fn_inv in fn.inverses);
    defs := listAppend(list(FunctionDerivative.toDAE(fn_der) for fn_der in fn.derivatives), defs);
    defs := def :: defs;
    daeFn := DAE.FUNCTION(fn.path, defs, ty, vis, par, impr, ity, unused_inputs,
      ElementSource.createElementSource(InstNode.info(fn.node)),
      SCodeUtil.getElementComment(InstNode.definition(fn.node)));
  end toDAE;

  function makeDAEType
    input Function fn;
    input Boolean boxTypes = false;
    output DAE.Type outType;
  protected
    list<DAE.FuncArg> params = {};
    String pname;
    Type ty;
    DAE.Type ptype;
    DAE.Const pconst;
    DAE.VarParallelism ppar;
    Option<DAE.Exp> pdefault;
    Component comp;
  algorithm
    for param in fn.inputs loop
      comp := InstNode.component(param);
      pname := InstNode.name(param);
      ty := Component.getType(comp);
      ptype := Type.toDAE(if boxTypes then Type.box(ty) else ty);
      pconst := Prefixes.variabilityToDAEConst(Component.variability(comp));
      ppar := Prefixes.parallelismToDAE(Component.parallelism(comp));
      pdefault := Util.applyOption(Binding.typedExp(Component.getBinding(comp)), Expression.toDAE);
      params := DAE.FuncArg.FUNCARG(pname, ptype, pconst, ppar, pdefault) :: params;
    end for;

    params := listReverse(params);
    ty := if isDefaultRecordConstructor(fn) then InstNode.getType(fn.node) else fn.returnType;
    ty := if boxTypes then Type.box(ty) else ty;
    outType := DAE.T_FUNCTION(params, Type.toDAE(ty), fn.attributes, fn.path);
  end makeDAEType;

  function getBody
    input Function fn;
    output list<Statement> body = getBody2(fn.node);
  end getBody;

  function hasUnboxArgs
    "Returns true if the function has the __OpenModelica_UnboxArguments annotation, otherwise false."
    input Function fn;
    output Boolean res;
  algorithm
    res := match fn.attributes
      case DAE.FunctionAttributes.FUNCTION_ATTRIBUTES(
        isBuiltin = DAE.FunctionBuiltin.FUNCTION_BUILTIN(unboxArgs = res)) then res;
      else false;
    end match;
  end hasUnboxArgs;

  function hasUnboxArgsAnnotation
    input SCode.Comment cmt;
    output Boolean res = SCodeUtil.commentHasBooleanNamedAnnotation(cmt, "__OpenModelica_UnboxArguments");
  end hasUnboxArgsAnnotation;

  function hasOptionalArgument
    input SCode.Element component;
    output Boolean res = SCodeUtil.hasBooleanNamedAnnotationInComponent(component, "__OpenModelica_optionalArgument");
  end hasOptionalArgument;

  function mapExp
    input output Function fn;
    input MapFunc mapFn;
    input MapFunc mapFnFields = mapFn "Used for expressions in subcomponents, i.e. record fields";
    input Boolean mapParameters = true;
    input Boolean mapBody = true;

    partial function MapFunc
      input output Expression exp;
    end MapFunc;
  protected
    Class cls;
    ClassTree ctree;
    array<InstNode> comps;
    Sections sections;
    Component comp;
    Binding binding, binding2;
  algorithm
    cls := InstNode.getClass(fn.node);

    if mapParameters then
      ctree := Class.classTree(cls);
      ClassTree.applyComponents(ctree,
        function mapExpParameter(mapFn = mapFn, mapFnFields = mapFnFields));
      fn.returnType := makeReturnType(fn);
    end if;

    if mapBody then
      sections := Sections.mapExp(Class.getSections(cls), mapFn);
      cls := cls.setSections(sections, cls);
      InstNode.updateClass(cls, fn.node);
    end if;
  end mapExp;

  function mapExpParameter
    input InstNode node;
    input MapFunc mapFn;
    input MapFunc mapFnFields;

    partial function MapFunc
      input output Expression exp;
    end MapFunc;
  protected
    Component comp;
    Binding binding, binding2;
    Class cls;
    Type ty;
    Boolean dirty = false;
  algorithm
    comp := InstNode.component(node);
    binding := Component.getBinding(comp);
    binding2 := Binding.mapExp(binding, mapFn);

    if not referenceEq(binding, binding2) then
      comp := Component.setBinding(binding2, comp);
      dirty := true;
    end if;

    () := match comp
      case Component.COMPONENT()
        algorithm
          ty := Type.mapDims(comp.ty, function Dimension.mapExp(func = mapFn));

          if not referenceEq(ty, comp.ty) then
            comp.ty := ty;
            dirty := true;
          end if;

          cls := InstNode.getClass(comp.classInst);
          ClassTree.applyComponents(Class.classTree(cls),
            function mapExpParameter(mapFn = mapFnFields, mapFnFields = mapFnFields));
        then
          ();

      else ();
    end match;

    if dirty then
      InstNode.updateComponent(comp, node);
    end if;
  end mapExpParameter;

  function mapBody
    input output Function fn;
    input MapFn mapFn;

    partial function MapFn
      input output Algorithm alg;
    end MapFn;
  protected
    Class cls;
    Sections sections;
  algorithm
    cls := InstNode.getClass(fn.node);
    sections := Sections.map(Class.getSections(cls), algFn = mapFn);
    cls := cls.setSections(sections, cls);
    InstNode.updateClass(cls, fn.node);
  end mapBody;

  function foldExp<ArgT>
    input Function fn;
    input FoldFunc foldFn;
    input output ArgT arg;
    input Boolean mapParameters = true;
    input Boolean mapBody = true;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  protected
    Class cls;
  algorithm
    cls := InstNode.getClass(fn.node);

    if mapParameters then
      arg := ClassTree.foldComponents(Class.classTree(cls),
        function foldExpParameter(foldFn = foldFn), arg);
    end if;

    if mapBody then
      arg := Sections.foldExp(Class.getSections(cls), foldFn, arg);
    end if;
  end foldExp;

  function foldExpParameter<ArgT>
    input InstNode node;
    input FoldFunc foldFn;
    input output ArgT arg;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  protected
    Component comp;
    Class cls;
  algorithm
    comp := InstNode.component(node);
    arg := Binding.foldExp(Component.getBinding(comp), foldFn, arg);

    () := match comp
      case Component.COMPONENT()
        algorithm
          arg := Type.foldDims(comp.ty, function Dimension.foldExp(func = foldFn), arg);
          cls := InstNode.getClass(comp.classInst);
          arg := ClassTree.foldComponents(Class.classTree(cls),
            function foldExpParameter(foldFn = foldFn), arg);
        then
          ();

      else ();
    end match;
  end foldExpParameter;

  function isPartial
    input Function fn;
    output Boolean isPartial = InstNode.isPartial(fn.node);
  end isPartial;

  function getLocalArguments
    input Function fn;
    output list<Expression> localArgs = {};
  protected
    Binding binding;
  algorithm
    for l in fn.locals loop
      if InstNode.isComponent(l) then
        binding := Component.getBinding(InstNode.component(l));
        Error.assertion(Binding.hasExp(binding),
          getInstanceName() + " got local component without binding", sourceInfo());
        localArgs := Binding.getExp(binding) :: localArgs;
      end if;
    end for;

    localArgs := listReverseInPlace(localArgs);
  end getLocalArguments;

protected
  function collectParams
    "Sorts all the function parameters as inputs, outputs and locals."
    input InstNode node;
    input output list<InstNode> inputs = {};
    input output list<InstNode> outputs = {};
    input output list<InstNode> locals = {};
  protected
    Class cls;
    array<InstNode> comps;
    InstNode n;
    Boolean check_vis;
  algorithm
    Error.assertion(InstNode.isClass(node), getInstanceName() + " got non-class node", sourceInfo());
    cls := InstNode.getClass(node);

    () := match cls
      case Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps))
        algorithm
          for i in arrayLength(comps):-1:1 loop
            n := comps[i];
            // Base Modelica does not have public/protected.
            check_vis := not Flags.getConfigBool(Flags.BASE_MODELICA);

            // Sort the components based on their direction.
            () := match paramDirection(n, check_vis)
              case Direction.INPUT algorithm inputs := n :: inputs; then ();
              case Direction.OUTPUT algorithm outputs := n :: outputs; then ();
              case Direction.NONE algorithm locals := n :: locals; then ();
            end match;
          end for;
        then
          ();

      case Class.EXPANDED_DERIVED()
        algorithm
          (inputs, outputs, locals) := collectParams(cls.baseClass);
        then
          ();

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got non-instantiated function " + AbsynUtil.pathString(InstNode.scopePath(node)), sourceInfo());
        then
          fail();
    end match;
  end collectParams;

  function paramDirection
    input InstNode component;
    input Boolean checkVisibility;
    output Direction direction;
  protected
    Component comp;
    ConnectorType.Type cty;
    InnerOuter io;
    Visibility vis;
    Variability var;
  algorithm
    comp := InstNode.component(InstNode.resolveOuter(component));

    // Outer components are not instantiated, so check this first to make sure
    // it's safe to e.g. fetch the attributes of the component.
    io := Component.innerOuter(comp);

    // Function components may not be inner/outer.
    if io <> InnerOuter.NOT_INNER_OUTER then
      Error.addSourceMessage(Error.INNER_OUTER_FORMAL_PARAMETER,
        {Prefixes.innerOuterString(io), InstNode.name(component)},
        InstNode.info(InstNode.resolveOuter(component)));
      fail();
    end if;

    Attributes.ATTRIBUTES(
      connectorType = cty,
      direction = direction,
      variability = var) := Component.getAttributes(comp);

    // Function components may not be connectors.
    if ConnectorType.isFlowOrStream(cty) then
      Error.addSourceMessage(Error.INNER_OUTER_FORMAL_PARAMETER,
        {ConnectorType.toString(cty), InstNode.name(component)},
        InstNode.info(component));
      fail();
    end if;

    if checkVisibility then
      // Formal parameters must be public, other function variables must be protected.
      vis := InstNode.visibility(component);

      if direction <> Direction.NONE then
        if vis == Visibility.PROTECTED then
          Error.addSourceMessage(Error.PROTECTED_FORMAL_FUNCTION_VAR,
            {InstNode.name(component)}, InstNode.info(component));
          fail();
        end if;
      elseif vis == Visibility.PUBLIC then
        Error.addSourceMessageAsError(Error.NON_FORMAL_PUBLIC_FUNCTION_VAR,
          {InstNode.name(component)}, InstNode.info(component));
        fail();
      end if;
    end if;
  end paramDirection;

  function makeSlots
    input list<InstNode> inputs;
    output list<Slot> slots = {};
  protected
    Integer index = 1;
  algorithm
    for i in inputs loop
      slots := makeSlot(i, index) :: slots;
      index := index + 1;
    end for;

    slots := listReverseInPlace(slots);
  end makeSlots;

  function makeSlot
    input InstNode component;
    input Integer index;
    output Slot slot;
  protected
    Component comp;
    Option<Expression> default;
    String name;
  algorithm
    try
      comp := InstNode.component(component);
      default := Binding.getExpOpt(Component.getImplicitBinding(comp, InstNode.instanceParent(component)));
      name := InstNode.name(component);

      // Remove $in_ for OM input output arguments.
      if StringUtil.startsWith(name, "$in_") then
        name := substring(name, 5, stringLength(name));
      end if;

      slot := SLOT(component, SlotType.GENERIC, default, NONE(), index, SlotEvalStatus.NOT_EVALUATED);
    else
      Error.assertion(false, getInstanceName() + " got invalid component", sourceInfo());
    end try;
  end makeSlot;

  function hasOMPure
    input SCode.Comment cmt;
    output Boolean res =
      not SCodeUtil.commentHasBooleanNamedAnnotation(cmt, "__OpenModelica_Impure");
  end hasOMPure;

  function hasImpure
    input SCode.Comment cmt;
    output Boolean res =
      SCodeUtil.commentHasBooleanNamedAnnotation(cmt, "__ModelicaAssociation_Impure");
  end hasImpure;

  function getBuiltinPtr
    input SCode.Comment cmt;
    output DAE.FunctionBuiltin builtin =
      if SCodeUtil.commentHasBooleanNamedAnnotation(cmt, "__OpenModelica_BuiltinPtr") then
        DAE.FUNCTION_BUILTIN_PTR() else DAE.FUNCTION_NOT_BUILTIN();
  end getBuiltinPtr;

  function mergeFunctionAnnotations
    "Merges the function's comments from inherited classes."
    input list<SCode.Comment> comments;
    output SCode.Comment outComment;
  protected
    Option<String> comment = NONE();
    SCode.Mod mod = SCode.NOMOD(), mod2;
  algorithm
    for cmt in comments loop
      if isNone(comment) then
        comment := cmt.comment;
      end if;

      mod := match cmt
        case SCode.COMMENT(annotation_ = SOME(SCode.ANNOTATION(modification = mod2)))
          then SCodeUtil.mergeModifiers(mod2, mod);
        else mod;
      end match;
    end for;

    outComment := match mod
      case SCode.NOMOD() then SCode.COMMENT(NONE(), comment);
      else SCode.COMMENT(SOME(SCode.ANNOTATION(mod)), comment);
    end match;
  end mergeFunctionAnnotations;

  function makeAttributes
    input InstNode node;
    input list<InstNode> inputs;
    input list<InstNode> outputs;
    output DAE.FunctionAttributes attr;
  protected
    SCode.Element def;
    array<InstNode> params;
    SCode.Restriction res;
    SCode.FunctionRestriction fres;
    Boolean is_partial;
    list<SCode.Comment> cmts;
    SCode.Comment cmt;
  algorithm
    def := InstNode.definition(Class.lastBaseClass(node));
    res := SCodeUtil.getClassRestriction(def);

    Error.assertion(SCodeUtil.isFunctionRestriction(res), getInstanceName() + " got non-function restriction", sourceInfo());

    SCode.Restriction.R_FUNCTION(functionRestriction = fres) := res;
    is_partial := InstNode.isPartial(node);

    cmts := InstNode.getComments(node);
    cmt := mergeFunctionAnnotations(cmts);

    attr := matchcontinue fres
      local
        Boolean is_impure, is_om_pure, has_out_params, has_unbox_args;
        String name;
        list<String> in_params, out_params;
        DAE.InlineType inline_ty;
        DAE.FunctionBuiltin builtin;
        Absyn.FunctionPurity purity;

      // External builtin function.
      case SCode.FunctionRestriction.FR_EXTERNAL_FUNCTION(purity)
        algorithm
          in_params := list(InstNode.name(i) for i in inputs);
          out_params := list(InstNode.name(o) for o in outputs);
          name := SCodeUtil.isBuiltinFunction(def, in_params, out_params);
          inline_ty := InstUtil.commentIsInlineFunc(cmt);
          is_impure := AbsynUtil.isImpure(purity) or hasImpure(cmt);
          has_unbox_args := hasUnboxArgsAnnotation(cmt);
        then
          DAE.FUNCTION_ATTRIBUTES(inline_ty, hasOMPure(cmt), is_impure, is_partial,
            DAE.FUNCTION_BUILTIN(SOME(name), has_unbox_args), DAE.FP_NON_PARALLEL());

      // Parallel function: there are some builtin functions.
      case SCode.FunctionRestriction.FR_PARALLEL_FUNCTION()
        algorithm
          in_params := list(InstNode.name(i) for i in inputs);
          out_params := list(InstNode.name(o) for o in outputs);
          name := SCodeUtil.isBuiltinFunction(def, in_params, out_params);
          inline_ty := InstUtil.commentIsInlineFunc(cmt);
          has_unbox_args := hasUnboxArgsAnnotation(cmt);
        then
          DAE.FUNCTION_ATTRIBUTES(inline_ty, hasOMPure(cmt), false, is_partial,
            DAE.FUNCTION_BUILTIN(SOME(name), has_unbox_args), DAE.FP_PARALLEL_FUNCTION());

      // Parallel function: non-builtin.
      case SCode.FunctionRestriction.FR_PARALLEL_FUNCTION()
        algorithm
          inline_ty := InstUtil.commentIsInlineFunc(cmt);
        then
          DAE.FUNCTION_ATTRIBUTES(inline_ty, hasOMPure(cmt), false, is_partial,
            getBuiltinPtr(cmt), DAE.FP_PARALLEL_FUNCTION());

      // Kernel functions: never builtin and never inlined.
      case SCode.FunctionRestriction.FR_KERNEL_FUNCTION()
        then DAE.FUNCTION_ATTRIBUTES(DAE.NO_INLINE(), true, false, is_partial,
          DAE.FUNCTION_NOT_BUILTIN(), DAE.FP_KERNEL_FUNCTION());

      // Normal function.
      else
        algorithm
          inline_ty := InstUtil.commentIsInlineFunc(cmt);

          // In Modelica 3.2 and before, external functions with side-effects are not marked.
          is_impure := SCodeUtil.isRestrictionImpure(res,
              Config.languageStandardAtMost(Config.LanguageStandard.'3.2')) or
            SCodeUtil.commentHasBooleanNamedAnnotation(cmt, "__ModelicaAssociation_Impure");

          if SCodeUtil.hasNamedExternalCall("ModelicaError", SCodeUtil.getClassDef(def)) then
            is_impure := false;
          end if;
        then
          DAE.FUNCTION_ATTRIBUTES(inline_ty, hasOMPure(cmt), is_impure, is_partial,
            getBuiltinPtr(cmt), DAE.FP_NON_PARALLEL());

    end matchcontinue;
  end makeAttributes;

  function checkParamTypes
    "Checks that all the function parameters have types which are allowed in a
     function."
    input Function fn;
  algorithm
    checkParamTypes2(fn.inputs);
    checkParamTypes2(fn.outputs);
    checkParamTypes2(fn.locals);
  end checkParamTypes;

  function checkParamTypes2
    input list<InstNode> params;
  protected
    Type ty;
  algorithm
    for p in params loop
      ty := InstNode.getType(p);

      if not isValidParamType(ty) then
        Error.addSourceMessage(Error.INVALID_FUNCTION_VAR_TYPE,
          {Type.toString(ty), InstNode.name(p)}, InstNode.info(p));
        fail();
      end if;
    end for;
  end checkParamTypes2;

  function isValidParamType
    input Type ty;
    output Boolean isValid;
  algorithm
    isValid := match ty
      case Type.INTEGER() then true;
      case Type.REAL() then true;
      case Type.STRING() then true;
      case Type.BOOLEAN() then true;
      case Type.CLOCK() then true;
      case Type.ENUMERATION() then true;
      case Type.POLYMORPHIC() then true;
      case Type.ARRAY() then isValidParamType(ty.elementType);
      case Type.COMPLEX() then isValidParamState(ty.cls);
      case Type.FUNCTION() then true;
      case Type.METABOXED() then isValidParamType(ty.ty);
      else false;
    end match;
  end isValidParamType;

  function isValidParamState
    input InstNode cls;
    output Boolean isValid;
  algorithm
    isValid := match Class.restriction(InstNode.getClass(cls))
      case Restriction.RECORD() then true;
      case Restriction.TYPE() then true;
      case Restriction.OPERATOR() then true;
      case Restriction.FUNCTION() then true;
      case Restriction.EXTERNAL_OBJECT() then true;
      else false;
    end match;
  end isValidParamState;

  function checkPartialDerivativeTypes
    input Function fn;
  protected
    InstNode node;
    Type ty;
  algorithm
    for i in fn.derivedInputs loop
      node := listGet(fn.inputs, i);
      ty := InstNode.getType(node);

      if not (Type.isReal(ty) and Type.isScalar(ty)) then
        Error.addSourceMessage(Error.PARTIAL_DERIVATIVE_INPUT_INVALID_TYPE,
          {InstNode.name(node), AbsynUtil.pathString(getDerivedFunctionName(fn))}, InstNode.info(fn.node));
        fail();
      end if;
    end for;
  end checkPartialDerivativeTypes;

  public function makeReturnType
    input Function fn;
    output Type returnType;
  protected
    list<Type> ret_tyl;
  algorithm
    ret_tyl := list(InstNode.getType(o) for o in fn.outputs);

    returnType := match ret_tyl
      case {} then Type.NORETCALL();
      case {returnType} then returnType;
      else Type.TUPLE(ret_tyl, NONE());
    end match;
  end makeReturnType;

  function getBody2
    input InstNode node;
    output list<Statement> body;
  protected
    Algorithm fn_body;
  algorithm
    body := match InstNode.getSections(node)
      case Sections.SECTIONS(algorithms = {}) then {};
      case Sections.SECTIONS(algorithms = {fn_body}) then fn_body.statements;
      case Sections.EMPTY() then {};
      case Sections.EXTERNAL()
        algorithm
          Error.assertion(false, getInstanceName() + " got function with external section (not algorithm section)", sourceInfo());
        then fail();

      case Sections.SECTIONS()
        algorithm
          Error.assertion(false, getInstanceName() + " got function with multiple algorithm sections", sourceInfo());
        then fail();

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown sections", sourceInfo());
        then fail();

    end match;
  end getBody2;

  function hasSingleOrEmptyBody
    input Function fn;
    output Boolean b = false;
  protected
    list<Algorithm> algorithms;
  algorithm
    try
      // InstNode.getSections can fail
      if isBuiltin(fn) then return; end if;
      b := match InstNode.getSections(fn.node)
        case Sections.SECTIONS(algorithms = algorithms) then listLength(algorithms) < 2;
        case Sections.EMPTY() then true;
        else false;
      end match;
    else
    end try;
  end hasSingleOrEmptyBody;

  function analyseUnusedParameters
    input Function fn;
    output list<Integer> unusedInputs = {};
  protected
    list<InstNode> inputs;
    Integer index;
  algorithm
    inputs := foldExp(fn, analyseUnusedParametersExp, fn.inputs);

    for i in inputs loop
      index := List.positionOnTrue(fn.inputs, function InstNode.refEqual(node1 = i));
      unusedInputs := index :: unusedInputs;
    end for;
  end analyseUnusedParameters;

  function analyseUnusedParametersExp
    input Expression exp;
    input output list<InstNode> params;
  algorithm
    if not listEmpty(params) then
      params := Expression.fold(exp, analyseUnusedParametersExp2, params);
    end if;
  end analyseUnusedParametersExp;

  function analyseUnusedParametersExp2
    input Expression exp;
    input output list<InstNode> params;
  algorithm
    () := match exp
      case Expression.CREF()
        algorithm
          params := List.deleteMemberOnTrue(exp.cref, params, ComponentRef.containsNode);
        then
          ();

      else ();
    end match;
  end analyseUnusedParametersExp2;

  function sortLocals
    "Sorts local components in a function such that they can be initialized in
     order, or gives an error if there are mutually dependent components."
    input output list<InstNode> locals;
    input SourceInfo info;
  protected
    UnorderedSet<InstNode> locals_set;
    list<tuple<InstNode, list<InstNode>>> dep_graph, cycles;
    String cycles_str;
  algorithm
    locals_set := UnorderedSet.fromList(locals, InstNode.hash, InstNode.refEqual);
    dep_graph := Graph.buildGraph(locals, getLocalDependencies, locals_set);
    (locals, cycles) := Graph.topologicalSort(dep_graph, InstNode.refEqual);

    if not listEmpty(cycles) then
      cycles_str := stringDelimitList(
        list(List.toString(cycle, InstNode.name, "", "{", ", ", "}", true)
          for cycle in Graph.findCycles(cycles, InstNode.refEqual)), ", ");

      Error.addSourceMessage(Error.CYCLIC_FUNCTION_COMPONENTS, {cycles_str}, info);
      fail();
    end if;
  end sortLocals;

  function getLocalDependencies
    input InstNode node;
    input UnorderedSet<InstNode> locals;
    output list<InstNode> dependencies;
  protected
    UnorderedSet<InstNode> deps;
  algorithm
    // Use a set to store the dependencies to avoid duplicates.
    deps := UnorderedSet.new(InstNode.hash, InstNode.refEqual, 1);
    deps := getLocalDependencies2(node, locals, deps);

    // If we have a record instance with fields that have bindings that refer to
    // other fields we'll get a dependency on the record instance itself here.
    // But that's actually fine, so remove it to avoid a false cycle being detected.
    UnorderedSet.remove(node, deps);

    deps := Type.foldDims(InstNode.getType(node),
      function getLocalDependenciesDim(locals = locals), deps);

    dependencies := UnorderedSet.toList(deps);
  end getLocalDependencies;

  function getLocalDependencies2
    input InstNode node;
    input UnorderedSet<InstNode> locals;
    input output UnorderedSet<InstNode> dependencies;
  protected
    Component comp;
    Binding binding;
  algorithm
    comp := InstNode.component(node);
    binding := Component.getBinding(comp);

    if Binding.hasExp(binding) then
      dependencies := getLocalDependenciesExp(Binding.getExp(binding), locals, dependencies);
    elseif Type.isRecord(Component.getType(comp)) then
      // If the component is a record instance without a binding, check the
      // bindings on the record fields instead.
      dependencies := ClassTree.foldComponents(
        Class.classTree(InstNode.getClass(node)),
        function getLocalDependencies2(locals = locals), dependencies);
    end if;
  end getLocalDependencies2;

  function getLocalDependenciesExp
    input Expression exp;
    input UnorderedSet<InstNode> locals;
    input output UnorderedSet<InstNode> deps;
  algorithm
    deps := Expression.fold(exp,
      function getLocalDependenciesExp2(locals = locals), deps);
  end getLocalDependenciesExp;

  function getLocalDependenciesExp2
    input Expression exp;
    input UnorderedSet<InstNode> locals;
    input output UnorderedSet<InstNode> deps;
  algorithm
    () := match exp
      local
        ComponentRef cr;
        InstNode cr_node;

      case Expression.CREF()
        algorithm
          // Get the 'last' part of the cref, i.e. a in a.b.c, in case there are
          // e.g. local record instances.
          cr := ComponentRef.last(exp.cref);

          // Make sure it's something that actually has a node.
          if ComponentRef.isCref(cr) then
            cr_node := ComponentRef.node(cr);

            // Check if the cref refers to a local variable, in that case add it
            // to the set of dependencies.
            if UnorderedSet.contains(cr_node, locals) then
              UnorderedSet.add(cr_node, deps);
            end if;
          end if;
        then
          ();

      else ();
    end match;
  end getLocalDependenciesExp2;

  function getLocalDependenciesDim
    input Dimension dim;
    input UnorderedSet<InstNode> locals;
    input output UnorderedSet<InstNode> deps;
  algorithm
    deps := Dimension.foldExp(dim,
      function getLocalDependenciesExp(locals = locals), deps);
  end getLocalDependenciesDim;

  function getDerivative
    "returns the first derivative that fits the interface_map
    and returns NONE() if none of them fit."
    input Function original;
    input UnorderedMap<String, Boolean> interface_map;
    output Option<Function> derivative = NONE();
  protected
    list<FunctionDerivative> derivatives;
    Boolean perfect_fit;
  algorithm
    for func in original.derivatives loop
      if FunctionDerivative.perfectFit(func, interface_map) then
        derivative := SOME(List.first(getCachedFuncs(func.derivativeFn)));
        return;
      end if;
    end for;

    // no derivative could be found, set whole map to true
    // so that the self-generated function removes as much as possible
    for key in UnorderedMap.keyList(interface_map) loop
      UnorderedMap.add(key, true, interface_map);
    end for;
  end getDerivative;

  function checkUseBeforeAssign
    "Checks if any output or local variables in a function are used
     uninitialized and prints warnings for such uses."
    input Function fn;
  protected
    Vector<InstNode> unassigned;
    list<Statement> body;
    InstNode parent;
    list<SourceInfo> sources;
  algorithm
    // Skip external and builtin functions.
    if isExternal(fn) or isBuiltin(fn) then
      return;
    end if;

    // Check if there are variables being used uninitialized.
    unassigned := Vector.new<InstNode>();
    addUnassignedComponents(unassigned, fn.outputs);
    addUnassignedComponents(unassigned, fn.locals);

    body := getBody(fn);
    checkUseBeforeAssign2(unassigned, body);

    // Give a warning for any outputs that were not assigned in the function.
    for var in Vector.toList(unassigned) loop
      if InstNode.isOutput(var) then
        parent := InstNode.InstNode.parent(var);
        sources := {InstNode.info(var)};

        // If the output is inherited then also give the source location of the
        // derived function, since that's likely where the assignment is missing.
        if InstNode.isBaseClass(parent) then
          sources := InstNode.info(InstNode.getDerivedNode(parent)) :: sources;
        end if;

        Error.addMultiSourceMessage(Error.UNASSIGNED_FUNCTION_OUTPUT, {InstNode.name(var)}, sources);
      end if;
    end for;
  end checkUseBeforeAssign;

  function addUnassignedComponents
    input Vector<InstNode> unassigned;
    input list<InstNode> variables;
  protected
    Type ty;
  algorithm
    for var in variables loop
      ty := InstNode.getType(var);

      if Type.isScalarBuiltin(ty) and not Component.hasBinding(InstNode.component(var)) then
        Vector.push(unassigned, var);
      end if;
    end for;
  end addUnassignedComponents;

  function checkUseBeforeAssign2
    input Vector<InstNode> unassigned;
    input list<Statement> statements;
  protected
    SourceInfo info;
  algorithm
    for stmt in statements loop
      info := Statement.info(stmt);

      () := match stmt
        case Statement.ASSIGNMENT()
          algorithm
            checkUseBeforeAssignExp(unassigned, stmt.rhs, info);
            markAssignedOutput(unassigned, stmt.lhs);
          then
            ();

        case Statement.FOR()
          algorithm
            if isSome(stmt.range) then
              checkUseBeforeAssignExp(unassigned, Util.getOption(stmt.range), info);
            end if;

            checkUseBeforeAssign2(unassigned, stmt.body);
          then
            ();

        case Statement.IF()
          algorithm
            checkUseBeforeAssignIf(unassigned, stmt.branches, info);
          then
            ();

        case Statement.ASSERT()
          algorithm
            checkUseBeforeAssignExp(unassigned, stmt.condition, info);
            checkUseBeforeAssignExp(unassigned, stmt.message, info);
            checkUseBeforeAssignExp(unassigned, stmt.level, info);
          then
            ();

        case Statement.WHILE()
          algorithm
            checkUseBeforeAssignExp(unassigned, stmt.condition, info);
            checkUseBeforeAssign2(unassigned, stmt.body);
          then
            ();

        else ();
      end match;
    end for;
  end checkUseBeforeAssign2;

  function markAssignedOutput
    input Vector<InstNode> unassigned;
    input Expression assignedExp;
  protected
    InstNode node;
    Integer index;
  algorithm
    () := match assignedExp
      case Expression.CREF()
        guard ComponentRef.isCref(assignedExp.cref)
        algorithm
          node := ComponentRef.node(ComponentRef.last(assignedExp.cref));
          (_, index) := Vector.find(unassigned, function InstNode.refEqual(node1 = node));

          if index > 0 then
            Vector.remove(unassigned, index);
          end if;
        then
          ();

      case Expression.TUPLE()
        algorithm
          for e in assignedExp.elements loop
            markAssignedOutput(unassigned, e);
          end for;
        then
          ();

      else ();
    end match;
  end markAssignedOutput;

  function checkUseBeforeAssignIf
    input Vector<InstNode> unassigned;
    input list<tuple<Expression, list<Statement>>> branches;
    input SourceInfo info;
  protected
    Vector<InstNode> unassigned_branch;
    list<InstNode> assigned = {};
    Integer index;
  algorithm
    for b in branches loop
      checkUseBeforeAssignExp(unassigned, Util.tuple21(b), info);
    end for;

    // Check each branch separately, then assume that any variables that were
    // assigned (or incorrectly used) in at least one branch are assigned after
    // the if-statement to avoid false positives.
    for b in branches loop
      unassigned_branch := Vector.copy(unassigned);
      checkUseBeforeAssign2(unassigned_branch, Util.tuple22(b));

      if Vector.size(unassigned) <> Vector.size(unassigned_branch) then
        assigned := listAppend(
          List.setDifferenceOnTrue(Vector.toList(unassigned), Vector.toList(unassigned_branch), InstNode.refEqual),
          assigned);
      end if;
    end for;

    if not listEmpty(assigned) then
      assigned := List.uniqueOnTrue(assigned, InstNode.refEqual);

      for a in assigned loop
        (_, index) := Vector.find(unassigned, function InstNode.refEqual(node1 = a));

        if index > 0 then
          Vector.remove(unassigned, index);
        end if;
      end for;
    end if;
  end checkUseBeforeAssignIf;

  function checkUseBeforeAssignExp
    input Vector<InstNode> unassigned;
    input Expression exp;
    input SourceInfo info;
  algorithm
    Expression.apply(exp,
      function checkUseBeforeAssignExp_traverse(unassigned = unassigned, info = info));
  end checkUseBeforeAssignExp;

  function checkUseBeforeAssignExp_traverse
    input Vector<InstNode> unassigned;
    input Expression exp;
    input SourceInfo info;
  protected
    Integer index;
    InstNode node;
  algorithm
    () := match exp
      case Expression.CREF()
        guard ComponentRef.isCref(exp.cref)
        algorithm
          node := ComponentRef.node(ComponentRef.last(exp.cref));
          (_, index) := Vector.find(unassigned, function InstNode.refEqual(node1 = node));

          if index > 0 then
            Vector.remove(unassigned, index);
            Error.addSourceMessage(Error.WARNING_DEF_USE, {InstNode.name(node)}, info);
          end if;
        then
          ();

      else ();
    end match;
  end checkUseBeforeAssignExp_traverse;

  function instPartialDerivedVars
    input SCode.ClassDef classDef;
    input list<InstNode> inputs;
    input Function fn;
    input InstContext.Type context;
    input SourceInfo info;
    output list<Integer> derivedVars = {};
  protected
    Integer index;
  algorithm
    () := match classDef
      case SCode.ClassDef.PDER()
        algorithm
          for var in classDef.derivedVariables loop
            index := List.positionOnTrue(inputs, function InstNode.isNamed(name = var));

            if index < 1 then
              Error.addSourceMessage(Error.PARTIAL_DERIVATIVE_INPUT_NOT_FOUND,
                {var, AbsynUtil.pathString(getDerivedFunctionName(fn))}, info);
              fail();
            end if;

            derivedVars := index :: derivedVars;
          end for;

          derivedVars := listReverseInPlace(derivedVars);
        then
          ();

      else ();
    end match;
  end instPartialDerivedVars;
end Function;

annotation(__OpenModelica_Interface="frontend");
end NFFunction;
