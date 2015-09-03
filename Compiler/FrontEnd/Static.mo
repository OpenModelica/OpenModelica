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

encapsulated package Static
" file:        Static.mo
  package:     Static
  description: Static analysis of expressions

  RCS: $Id$

  This module does static analysis on expressions.
  The analyzed expressions are built using the
  constructors in the Expression module from expressions defined in Absyn.
  Also, a set of properties of the expressions is calculated during analysis.
  Properties of expressions include type information and a boolean indicating if the
  expression is constant or not.
  If the expression is constant, the Ceval module is used to evaluate the expression
  value. A value of an expression is described using the Values module.

  The main function in this module is evalExp which takes an Absyn.Exp and transform it
  into an DAE.Exp, while performing type checking and automatic type conversions, etc.
  To determine types of builtin functions and operators, the module also contain an elaboration
  handler for functions and operators. This function is called elabBuiltinHandler.
  NOTE: These functions should only determine the type and properties of the builtin functions and
  operators and not evaluate them. Constant evaluation is performed by the Ceval module.
  The module also contain a function for deoverloading of operators, in the \'deoverload\' function.
  It transforms operators like + to its specific form, ADD, ADD_ARR, etc.

  Interactive function calls are also given their types by elabExp, which calls
  elabCallInteractive.

  Elaboration for functions involve checking the types of the arguments by filling slots of the
  argument list with first positional and then named arguments to find a matching function. The
  details of this mechanism can be found in the Modelica specification.
  The elaboration also contain function deoverloading which will be added to Modelica in the future."

public import Absyn;
public import DAE;
public import FCore;
public import FGraph;
public import FNode;
public import GlobalScript;
public import MetaUtil;
public import SCode;
public import SCodeUtil;
public import Values;
public import Prefix;
public import Util;

protected
constant Integer SLOT_NOT_EVALUATED = 0;
constant Integer SLOT_EVALUATING = 1;
constant Integer SLOT_EVALUATED = 2;

uniontype Slot
  record SLOT
    DAE.FuncArg defaultArg "The slots default argument.";
    Boolean slotFilled "True if the slot has been filled, otherwise false.";
    Option<DAE.Exp> arg "The argument for the slot given by the function call.";
    DAE.Dimensions dims "The dimensions of the slot.";
    Integer idx "The index of the slot, 1 = first slot etc.";
    Integer evalStatus;
  end SLOT;
end Slot;

protected import Array;
protected import BackendInterface;
protected import Ceval;
protected import ClassInf;
protected import ComponentReference;
protected import Config;
protected import Debug;
protected import Dump;
protected import Error;
protected import ErrorExt;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import Global;
protected import GlobalScriptUtil;
protected import Inline;
protected import Inst;
protected import InstFunction;
protected import InstTypes;
protected import InnerOuter;
protected import List;
protected import Lookup;
protected import OperatorOverloading;
protected import Patternm;
protected import Print;
protected import System;
protected import Types;
protected import ValuesUtil;
protected import DAEUtil;
protected import PrefixUtil;
protected import VarTransform;
protected import SCodeDump;
protected import RewriteRules;

public function elabExpList "Expression elaboration of Absyn.Exp list, i.e. lists of expressions."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inExpl;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  input DAE.Type inLastType = DAE.T_UNKNOWN_DEFAULT "The type of the last evaluated expression; used to speed up instantiation of enumeration :)";
  output FCore.Cache outCache = inCache;
  output list<DAE.Exp> outExpl = {};
  output list<DAE.Properties> outProperties = {};
  output Option<GlobalScript.SymbolTable> outST = inST;
protected
  DAE.Exp exp;
  DAE.Properties prop;
  DAE.Type last_ty = inLastType;
algorithm
  for e in inExpl loop
    _ := matchcontinue(e, last_ty)
      local
        Absyn.ComponentRef cr;
        Absyn.Path path, path1, path2;
        String name;
        list<String> names;
        Integer idx;

      // Hack to make enumeration arrays elaborate a _lot_ faster
      case (Absyn.CREF(cr as Absyn.CREF_FULLYQUALIFIED()),
            DAE.T_ENUMERATION(path = path2, names = names))
        algorithm
          path := Absyn.crefToPath(cr);
          (path1, Absyn.IDENT(name)) := Absyn.splitQualAndIdentPath(path);
          true := Absyn.pathEqual(path1, path2);
          idx := List.position(name, names);
          exp := DAE.ENUM_LITERAL(path, idx);
          prop := DAE.PROP(last_ty, DAE.C_CONST());
        then
          ();

      else
        algorithm
          (outCache, exp, prop, outST) := elabExpInExpression(outCache, inEnv,
            e, inImplicit, outST, inDoVect, inPrefix, inInfo);
          last_ty := Types.getPropType(prop);
        then
          ();

    end matchcontinue;

    outExpl := exp :: outExpl;
    outProperties := prop :: outProperties;
  end for;

  outExpl := listReverse(outExpl);
  outProperties := listReverse(outProperties);
end elabExpList;

protected function elabExpList_enum
  input Absyn.Exp inExp;
  input DAE.Type inLastType;
  output Integer outIndex;
algorithm
  outIndex := matchcontinue(inExp, inLastType)
    local
      Absyn.ComponentRef cr;
      Absyn.Path path, path1, path2;
      String name;
      list<String> names;

    case (Absyn.CREF(cr as Absyn.CREF_FULLYQUALIFIED()),
          DAE.T_ENUMERATION(path = path2, names = names))
      algorithm
        path := Absyn.crefToPath(cr);
        (path1, Absyn.IDENT(name)) := Absyn.splitQualAndIdentPath(path);
        true := Absyn.pathEqual(path1, path2);
      then
        List.position(name, names);

    else -1;

  end matchcontinue;
end elabExpList_enum;

public function elabExpListList
"Expression elaboration of lists of lists of expressions.
  Used in for instance matrices, etc."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<list<Absyn.Exp>> inExpl;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  input DAE.Type inLastType = DAE.T_UNKNOWN_DEFAULT "The type of the last evaluated expression; used to speed up instantiation of enumerations :)";
  output FCore.Cache outCache = inCache;
  output list<list<DAE.Exp>> outExpl = {};
  output list<list<DAE.Properties>> outProperties = {};
  output Option<GlobalScript.SymbolTable> outST = inST;
protected
  list<DAE.Exp> expl;
  list<DAE.Properties> props;
  DAE.Type last_ty = inLastType;
algorithm
  for lst in inExpl loop
    (outCache, expl, props, outST) := elabExpList(outCache, inEnv, lst,
      inImplicit, inST, inDoVect, inPrefix, inInfo, last_ty);
    outExpl := expl :: outExpl;
    outProperties := props :: outProperties;
    last_ty := Types.getPropType(listHead(props));
  end for;

  outExpl := listReverse(outExpl);
  outProperties := listReverse(outProperties);
end elabExpListList;

protected function elabExpOptAndMatchType "
  elabExp, but for Option<Absyn.Exp>,DAE.Type => Option<DAE.Exp>"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Option<Absyn.Exp> inExp;
  input DAE.Type inDefaultType;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output Option<DAE.Exp> outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outST = inST;
protected
  Absyn.Exp exp;
  DAE.Exp dexp;
  DAE.Properties prop;
algorithm
  outProperties := DAE.PROP(inDefaultType, DAE.C_CONST());

  if isSome(inExp) then
    SOME(exp) := inExp;
    (outCache, dexp, prop, outST) := elabExpInExpression(outCache, inEnv,
      exp, inImplicit, inST, inDoVect, inPrefix, inInfo);
    (dexp, outProperties) := Types.matchProp(dexp, prop, outProperties, true);
    outExp := SOME(dexp);
  else
    outExp := NONE();
  end if;
end elabExpOptAndMatchType;

public function elabExp "
function: elabExp
  Static analysis of expressions means finding out the properties of
  the expression.  These properties are described by the
  DAE.Properties type, and include the type and the variability of the
  expression.  This function performs analysis, and returns an
  DAE.Exp and the properties."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outST = inST;
protected
  Absyn.Exp e;
  Integer num_errmsgs;
  DAE.Exp exp, exp1, exp2;
  DAE.Properties prop1, prop2;
  DAE.Type ty;
  DAE.Const c;
  PartialElabExpFunc elabfunc;
algorithm
  // Apply any rewrite rules we have, if any.
  e := if RewriteRules.noRewriteRulesFrontEnd() then inExp else
    RewriteRules.rewriteFrontEnd(inExp);

  num_errmsgs := Error.getNumErrorMessages();

  try
    elabfunc := match(e)
      case Absyn.END()
        algorithm
          Error.addSourceMessage(Error.END_ILLEGAL_USE_ERROR, {}, inInfo);
        then
          fail();

      case Absyn.CREF() then elabExp_Cref;
      case Absyn.BINARY() then elabExp_Binary;
      case Absyn.UNARY() then elabExp_Unary;
      case Absyn.LBINARY() then elabExp_Binary;
      case Absyn.LUNARY() then elabExp_LUnary;
      case Absyn.RELATION() then elabExp_Binary;
      case Absyn.IFEXP() then elabExp_If;
      case Absyn.CALL() then elabExp_Call;
      case Absyn.PARTEVALFUNCTION() then elabExp_PartEvalFunction;
      case Absyn.TUPLE() then elabExp_Tuple;
      case Absyn.RANGE() then elabExp_Range;
      case Absyn.ARRAY() then elabExp_Array;
      case Absyn.MATRIX() then elabExp_Matrix;
      case Absyn.CODE() then elabExp_Code;
      case Absyn.CONS() then elabExp_Cons;
      case Absyn.LIST() then elabExp_List;
      case Absyn.MATCHEXP() then Patternm.elabMatchExpression;
      case Absyn.DOT() then elabExp_Dot;
      else elabExp_BuiltinType;
    end match;

    (outCache, outExp, outProperties, outST) :=
      elabfunc(inCache, inEnv, e, inImplicit, inST, inDoVect, inPrefix, inInfo);
  else
    true := num_errmsgs == Error.getNumErrorMessages();
    Error.addSourceMessage(Error.GENERIC_ELAB_EXPRESSION,
      {Dump.printExpStr(e)}, inInfo);
    fail();
  end try;
end elabExp;

protected partial function PartialElabExpFunc
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outST = inST;
end PartialElabExpFunc;

protected function elabExp_BuiltinType
  extends PartialElabExpFunc;
algorithm
  (outExp, outProperties) := match(inExp)
    // The types below should contain the default values of the attributes of the builtin
    // types. But since they are default, we can leave them out for now, unit=\"\" is not
    // that interesting to find out.
    case Absyn.INTEGER()
      then (DAE.ICONST(inExp.value),
            DAE.PROP(DAE.T_INTEGER_DEFAULT, DAE.C_CONST()));

    case Absyn.REAL()
      then (DAE.RCONST(System.stringReal(inExp.value)),
            DAE.PROP(DAE.T_REAL_DEFAULT, DAE.C_CONST()));

    case Absyn.STRING()
      then (DAE.SCONST(System.unescapedString(inExp.value)),
            DAE.PROP(DAE.T_STRING_DEFAULT, DAE.C_CONST()));

    case Absyn.BOOL()
      then (DAE.BCONST(inExp.value),
            DAE.PROP(DAE.T_BOOL_DEFAULT, DAE.C_CONST()));

  end match;
end elabExp_BuiltinType;

protected function elabExp_Cref
  extends PartialElabExpFunc;
protected
  Absyn.ComponentRef cr;
  DAE.Type ty;
  DAE.Const c;
algorithm
  Absyn.CREF(componentRef = cr) := inExp;
  (outCache, SOME((outExp, outProperties, _))) := elabCref(inCache, inEnv, cr,
    inImplicit, inDoVect, inPrefix, inInfo);

  // BoschRexroth specifics, convert param to var.
  if not Flags.getConfigBool(Flags.CEVAL_EQUATION) then
    DAE.PROP(ty, c) := outProperties;
    outProperties := if Types.isParameter(c) then
      DAE.PROP(ty, DAE.C_VAR()) else outProperties;
  end if;
end elabExp_Cref;

protected function elabExp_Binary
  extends PartialElabExpFunc;
protected
  Absyn.Exp e1, e2;
  Absyn.Operator op;
  DAE.Properties prop1, prop2;
  DAE.Exp exp1, exp2;
algorithm
  _ := match(inExp)
    case Absyn.BINARY(exp1 = e1, op = op, exp2 = e2) then ();
    case Absyn.LBINARY(exp1 = e1, op = op, exp2 = e2) then ();
    case Absyn.RELATION(exp1 = e1, op = op, exp2 = e2) then ();
  end match;

  (outCache, exp1, prop1, outST) := elabExpInExpression(inCache, inEnv,
    e1, inImplicit, inST, inDoVect, inPrefix, inInfo);
  (outCache, exp2, prop2, outST) := elabExpInExpression(outCache, inEnv,
    e2, inImplicit, outST, inDoVect, inPrefix, inInfo);
  (outCache, outExp, outProperties) := OperatorOverloading.binary(outCache,
    inEnv, op, prop1, exp1, prop2, exp2, inExp, e1, e2, inImplicit,
      outST, inPrefix, inInfo);
end elabExp_Binary;

protected function elabExp_Unary
  extends PartialElabExpFunc;
protected
  Absyn.Exp e;
  Absyn.Operator op;
  DAE.Type ty;
  DAE.Const c;
algorithm
  Absyn.UNARY(op = op, exp = e) := inExp;

  (outCache, outExp, outProperties as DAE.PROP(ty, c), outST) :=
  elabExpInExpression(inCache, inEnv, e, inImplicit, inST, inDoVect, inPrefix, inInfo);

  if not (valueEq(op, Absyn.UPLUS()) and
          Types.isIntegerOrRealOrSubTypeOfEither(Types.arrayElementType(ty)))
  then
    (outCache, outExp, outProperties) := OperatorOverloading.unary(outCache, inEnv,
      op, outProperties, outExp, inExp, e, inImplicit, outST, inPrefix, inInfo);
  end if;
end elabExp_Unary;

protected function elabExp_LUnary
  extends PartialElabExpFunc;
protected
  Absyn.Exp e;
  Absyn.Operator op;
algorithm
  Absyn.LUNARY(op = op, exp = e) := inExp;
  (outCache, outExp, outProperties, outST) := elabExpInExpression(outCache, inEnv, e,
    inImplicit, outST, inDoVect, inPrefix, inInfo);
  (outCache, outExp, outProperties) := OperatorOverloading.unary(outCache,
    inEnv, op, outProperties, outExp, inExp, e, inImplicit, outST, inPrefix, inInfo);
end elabExp_LUnary;

protected function elabExp_If
  "Elaborates an if-expression. If one of the branches can not be elaborated and
   the condition is parameter or constant; it is evaluated and the correct branch is selected.
   This is a dirty hack to make MSL CombiTable models work!
   Note: Because of this, the function has to rollback or delete an ErrorExt checkpoint."
  extends PartialElabExpFunc;
protected
  Absyn.Exp cond_e, true_e, false_e;
  DAE.Exp cond_exp, true_exp, false_exp;
  DAE.Properties cond_prop, true_prop, false_prop;
  FCore.Cache cache;
  Option<GlobalScript.SymbolTable> st;
  Boolean b;
algorithm
  Absyn.IFEXP(ifExp = cond_e, trueBranch = true_e, elseBranch = false_e) :=
    Absyn.canonIfExp(inExp);
  (cache, cond_exp, cond_prop, st) := elabExpInExpression(inCache,
    inEnv, cond_e, inImplicit, inST, inDoVect, inPrefix, inInfo);

  _ := matchcontinue()
    case ()
      algorithm
        ErrorExt.setCheckpoint("Static.elabExp:IFEXP");
        (outCache, true_exp, true_prop, outST) := elabExpInExpression(cache,
          inEnv, true_e, inImplicit, st, inDoVect, inPrefix, inInfo);
        (outCache, false_exp, false_prop, outST) := elabExpInExpression(outCache,
          inEnv, false_e, inImplicit, outST, inDoVect, inPrefix, inInfo);
        (outCache, outExp, outProperties) := makeIfExp(outCache, inEnv, cond_exp,
          cond_prop, true_exp, true_prop, false_exp, false_prop, inImplicit,
          outST, inPrefix, inInfo);
        ErrorExt.delCheckpoint("Static.elabExp:IFEXP");
      then
        ();

    case ()
      algorithm
        ErrorExt.setCheckpoint("Static.elabExp:IFEXP:HACK") "Extra rollback point so we get the regular error message only once if the hack fails";
        true := Types.isParameterOrConstant(Types.propAllConst(cond_prop));
        (outCache, Values.BOOL(b), _) := Ceval.ceval(cache, inEnv, cond_exp,
          inImplicit, NONE(), Absyn.MSG(inInfo));
        (outCache, outExp, outProperties) := elabExpInExpression(outCache, inEnv,
          if b then true_e else false_e, inImplicit, st, inDoVect, inPrefix, inInfo);
        ErrorExt.delCheckpoint("Static.elabExp:IFEXP:HACK");
        ErrorExt.rollBack("Static.elabExp:IFEXP");
      then
        ();

    else
      algorithm
        ErrorExt.rollBack("Static.elabExp:IFEXP:HACK");
        ErrorExt.delCheckpoint("Static.elabExp:IFEXP");
      then
        fail();

  end matchcontinue;
end elabExp_If;

protected function elabExp_Call
  extends PartialElabExpFunc;
protected
  Absyn.ComponentRef func_name;
  Absyn.FunctionArgs args;
  Absyn.Exp arg;
  String last_id;
algorithm
  Absyn.CALL(function_ = func_name, functionArgs = args) := inExp;

  _ := match(args)
    case Absyn.FUNCTIONARGS()
      algorithm
        (outCache, outExp, outProperties, outST) := elabCall(inCache, inEnv,
          func_name, args.args, args.argNames, inImplicit, inST, inPrefix, inInfo);
        outExp := ExpressionSimplify.simplify1(outExp);
      then
        ();

    case Absyn.FOR_ITER_FARG()
      algorithm
        (outCache, outExp, outProperties, outST) := elabCallReduction(inCache,
          inEnv, func_name, args.exp, args.iterType, args.iterators, inImplicit,
          inST, inDoVect, inPrefix, inInfo);
      then
        ();
  end match;
end elabExp_Call;

protected function elabExp_Dot
  extends PartialElabExpFunc;
algorithm
  (outExp, outProperties) := match(inExp)
    local
      String s;
      DAE.Type ty;
    case Absyn.DOT()
      algorithm
        s := match inExp.index
          case Absyn.CREF(Absyn.CREF_IDENT(name=s)) then s;
          else
            algorithm
              Error.addSourceMessage(Error.COMPILER_ERROR, {"Dot operator is only allowed when indexing using a single simple name, got: " + Dump.printExpStr(inExp.index)}, inInfo);
            then fail();
        end match;
        (outCache,outExp,outProperties,outST) := elabExp(inCache,inEnv,inExp.exp,inImplicit,inST, inDoVect, inPrefix, inInfo);
        ty := Types.getPropType(outProperties);
        _ := match ty
          local
            list<String> names;
            Integer i;
          case DAE.T_TUPLE(names=SOME(names))
            algorithm
              if not listMember(s, names) then
                Error.addSourceMessage(Error.COMPILER_ERROR, {"Dot operator could not find " + s + " in " + Types.unparseType(ty)}, inInfo);
                fail();
              end if;
              i := List.position(s, names);
              outExp := DAE.TSUB(outExp, i, listGet(ty.types,i));
              outProperties := DAE.PROP(listGet(ty.types,i), Types.propAllConst(outProperties));
            then ();
          else
            algorithm
              Error.addSourceMessage(Error.COMPILER_ERROR, {"Dot operator is only allowed when the expression returns a named tuple. Got expression: " + ExpressionDump.printExpStr(outExp) + " with type " + Types.unparseType(ty)}, inInfo);
            then fail();
        end match;
      then (outExp, outProperties);

  end match;
end elabExp_Dot;

protected function elabExp_PartEvalFunction
  "turns an Absyn.PARTEVALFUNCTION into an DAE.PARTEVALFUNCTION"
  extends PartialElabExpFunc;
protected
  Absyn.ComponentRef cref;
  list<Absyn.Exp> pos_args;
  list<Absyn.NamedArg> named_args;
  Absyn.Path path;
  DAE.Type ty, tty, tty2;
  list<DAE.Exp> args;
  list<DAE.Const> consts;
  list<Slot> slots;
  DAE.Const c;
algorithm
  Absyn.PARTEVALFUNCTION(cref, Absyn.FUNCTIONARGS(pos_args, named_args)) := inExp;

  if listEmpty(pos_args) and listEmpty(named_args) then
    (outCache, outExp, outProperties, outST) := elabExpInExpression(inCache,
      inEnv, Absyn.CREF(cref), inImplicit, inST, inDoVect, inPrefix, inInfo);
  else
    path := Absyn.crefToPath(cref);
    (outCache, {tty}) := Lookup.lookupFunctionsInEnv(inCache, inEnv, path, inInfo);
    tty := Types.makeFunctionPolymorphicReference(tty);
    (outCache, args, consts, _, tty, _, slots) := elabTypes(outCache, inEnv, pos_args,
      named_args, {tty}, true, true, inImplicit, NOT_EXTERNAL_OBJECT_MODEL_SCOPE(),
      NONE(), inPrefix, inInfo);

    if not Types.isFunctionPointer(tty) then
      (outCache, path) := Inst.makeFullyQualified(outCache, inEnv, path);
      (outCache, Util.SUCCESS()) := instantiateDaeFunction(outCache, inEnv,
        path, false, NONE(), true);
    end if;

    tty2 := stripExtraArgsFromType(slots, tty);
    tty2 := Types.makeFunctionPolymorphicReference(tty2);
    ty := Types.simplifyType(tty2);
    tty := Types.simplifyType(tty);
    c := List.fold(consts, Types.constAnd, DAE.C_CONST());
    outExp := DAE.PARTEVALFUNCTION(path, args, ty, tty);
    outProperties := DAE.PROP(tty2, c);
  end if;
end elabExp_PartEvalFunction;

protected function elabExp_Tuple
  extends PartialElabExpFunc;
protected
  list<Absyn.Exp> el;
  list<DAE.Exp> expl;
  list<DAE.Properties> props;
  list<DAE.Type> types;
  list<DAE.TupleConst> consts;
algorithm
  Absyn.TUPLE(expressions = el) := inExp;
  (outCache, expl, props) := elabTuple(outCache, inEnv, el, inImplicit,
    inDoVect, inPrefix, inInfo);
  (types, consts) := splitProps(props);
  (outExp, outProperties) := fixTupleMetaModelica(expl, types, consts);
end elabExp_Tuple;

protected function elabExp_Range
  "Elaborates a range expression on the form start:stop or start:step:stop."
  extends PartialElabExpFunc;
protected
  Absyn.Exp start, step, stop;
  Option<Absyn.Exp> ostep;
  DAE.Exp start_exp, step_exp, stop_exp;
  Option<DAE.Exp> ostep_exp = NONE();
  DAE.Type start_ty, step_ty, stop_ty, ety, ty;
  Option<DAE.Type> ostep_ty = NONE();
  DAE.Const start_c, step_c, stop_c, c;
algorithm
  Absyn.RANGE(start = start, step = ostep, stop = stop) := inExp;

  // Elaborate start and stop of the range.
  (outCache, start_exp, DAE.PROP(start_ty, start_c), outST) :=
    elabExpInExpression(inCache, inEnv, start, inImplicit, inST, inDoVect, inPrefix, inInfo);
  (outCache, stop_exp, DAE.PROP(stop_ty, stop_c), outST) :=
    elabExpInExpression(outCache, inEnv, stop, inImplicit, outST, inDoVect, inPrefix, inInfo);
  c := Types.constAnd(start_c, stop_c);

  // If step was given, elaborate it too.
  if isSome(ostep) then
    SOME(step) := ostep;
    (outCache, step_exp, DAE.PROP(step_ty, step_c), outST) :=
      elabExpInExpression(outCache, inEnv, step, inImplicit, outST, inDoVect, inPrefix, inInfo);
    ostep_exp := SOME(step_exp);
    ostep_ty := SOME(step_ty);
    c := Types.constAnd(c, step_c);
  end if;

  if Types.isBoxedType(start_ty) then
    (start_exp, start_ty) := Types.matchType(start_exp, start_ty, Types.unboxedType(start_ty), true);
  end if;
  if Types.isBoxedType(stop_ty) then
    (stop_exp, stop_ty) := Types.matchType(stop_exp, stop_ty, Types.unboxedType(stop_ty), true);
  end if;

  (start_exp, ostep_exp, stop_exp, ety) :=
    deoverloadRange(start_exp, start_ty, ostep_exp, ostep_ty, stop_exp, stop_ty, inInfo);
  (outCache, ty) := elabRangeType(outCache, inEnv, start_exp, ostep_exp,
    stop_exp, start_ty, ety, c, inImplicit);

  outExp := DAE.RANGE(ety, start_exp, ostep_exp, stop_exp);
  outProperties := DAE.PROP(ty, c);
end elabExp_Range;

protected function elabExp_Array
  extends PartialElabExpFunc;
protected
  list<Absyn.Exp> es;
  list<DAE.Exp> expl;
  list<DAE.Properties> props;
  DAE.Type ty, arr_ty;
  DAE.Const c;
  DAE.Exp exp;
algorithm
  (outExp, outProperties) := matchcontinue(inExp)
    // Part of the MetaModelica extension. This eliminates elabArray failed
    // failtraces when using the empty list. sjoelund
    case Absyn.ARRAY({}) guard(Config.acceptMetaModelicaGrammar())
      then (DAE.LIST({}), DAE.PROP(DAE.T_METALIST_DEFAULT, DAE.C_CONST()));

    // array expressions, e.g. {1,2,3}
    case Absyn.ARRAY(arrayExp = es)
      algorithm
        (outCache, expl, props) := elabExpList(inCache, inEnv, es, inImplicit,
          inST, inDoVect, inPrefix, inInfo);
        (expl, DAE.PROP(ty, c)) := elabArray(expl, props, inPrefix, inInfo); // type-checking the array
        arr_ty := DAE.T_ARRAY(ty, {DAE.DIM_INTEGER(listLength(expl))}, DAE.emptyTypeSource);
        exp := DAE.ARRAY(Types.simplifyType(arr_ty), not Types.isArray(ty), expl);
        MetaUtil.checkArrayType(ty);
        exp := elabMatrixToMatrixExp(exp);
      then
        (exp, DAE.PROP(arr_ty, c));

    // Part of the MetaModelica extension. KS
    case Absyn.ARRAY(arrayExp = es) guard(Config.acceptMetaModelicaGrammar())
      algorithm
        (outCache, outExp, outProperties, outST) := elabExpInExpression(inCache,
          inEnv, Absyn.LIST(es), inImplicit, inST, inDoVect, inPrefix, inInfo);
      then
        (outExp, outProperties);

  end matchcontinue;
end elabExp_Array;

protected function elabExp_Matrix
  extends PartialElabExpFunc;
protected
  list<list<Absyn.Exp>> ess;
  list<list<DAE.Exp>> dess;
  list<list<DAE.Properties>> props;
  list<list<DAE.Type>> tps;
  list<DAE.Type> tys;
  Integer nmax;
  Boolean have_real;
  DAE.Type ty;
  DAE.Const c;
  DAE.Dimension dim1, dim2;
algorithm
  Absyn.MATRIX(matrix = ess) := inExp;
  (outCache, dess, props) := elabExpListList(inCache, inEnv, ess, inImplicit,
    inST, inDoVect, inPrefix, inInfo);

  tps := List.mapList(props, Types.getPropType);
  tys := List.flatten(tps);
  nmax := matrixConstrMaxDim(tys);
  have_real := Types.containReal(tys);

  (outCache, outExp, DAE.PROP(ty, c), dim1, dim2) := elabMatrixSemi(outCache,
    inEnv, dess, props, inImplicit, inST, have_real, nmax, inDoVect, inPrefix, inInfo);

  if have_real then
    outExp := DAE.CAST(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {dim1, dim2}, DAE.emptyTypeSource), outExp);
  end if;

  // TODO: Should this be moved into the if-statement above?
  outExp := ExpressionSimplify.simplify1(outExp); // To propagate cast down to scalar elts.
  outExp := elabMatrixToMatrixExp(outExp);
  ty := Types.unliftArray(Types.unliftArray(ty)); // All elts promoted to matrix, therefore unlifting.
  ty := DAE.T_ARRAY(ty, {dim2}, DAE.emptyTypeSource);
  ty := DAE.T_ARRAY(ty, {dim1}, DAE.emptyTypeSource);
  outProperties := DAE.PROP(ty, c);
end elabExp_Matrix;

protected function elabExp_Code
  extends PartialElabExpFunc;
protected
  DAE.Type ty, ty2;
  Absyn.CodeNode cn;
algorithm
  Absyn.CODE(code = cn) := inExp;
  ty := elabCodeType(cn);
  ty2 := Types.simplifyType(ty);
  outExp := DAE.CODE(cn, ty2);
  outProperties := DAE.PROP(ty, DAE.C_CONST());
end elabExp_Code;

protected function elabExp_Cons
  extends PartialElabExpFunc;
protected
  Absyn.Exp e1, e2;
  DAE.Exp exp1, exp2;
  DAE.Properties prop1;
  DAE.Type ty, ty1, ty2;
  DAE.Const c1, c2;
  String exp_str, ty1_str, ty2_str;
algorithm
  Absyn.CONS(e1, e2) := inExp;
  {e1, e2} := MetaUtil.transformArrayNodesToListNodes({e1, e2});

  // Elaborate both sides of the cons expression.
  (outCache, exp1, prop1) := elabExpInExpression(outCache, inEnv, e1,
    inImplicit, inST, inDoVect, inPrefix, inInfo);
  (outCache, exp2, DAE.PROP(DAE.T_METALIST(ty = ty2), c2), _) := elabExpInExpression(
    outCache, inEnv, e2, inImplicit, inST, inDoVect, inPrefix, inInfo);

  try
    // Replace all metarecords with uniontypes with.
    ty1 := Types.getUniontypeIfMetarecordReplaceAllSubtypes(Types.getPropType(prop1));
    ty2 := Types.getUniontypeIfMetarecordReplaceAllSubtypes(ty2);
    c1 := Types.propAllConst(prop1);
    ty := Types.getUniontypeIfMetarecordReplaceAllSubtypes(
      Types.superType(Types.boxIfUnboxedType(ty1), Types.boxIfUnboxedType(ty2)));

    // Make sure the operands have correct types.
    exp1 := Types.matchType(exp1, ty1, ty, true);
    ty := DAE.T_METALIST(ty, DAE.emptyTypeSource);
    exp2 := Types.matchType(exp2, ty, DAE.T_METALIST(ty2, DAE.emptyTypeSource), true);

    outExp := DAE.CONS(exp1, exp2);
    outProperties := DAE.PROP(ty, Types.constAnd(c1, c2));
  else
    exp_str := Dump.printExpStr(inExp);
    ty1_str := Types.unparseType(Types.getPropType(prop1));
    ty2_str := Types.unparseType(ty2);
    Error.addSourceMessage(Error.META_CONS_TYPE_MATCH, {exp_str, ty1_str, ty2_str}, inInfo);
    fail();
  end try;
end elabExp_Cons;

protected function elabExp_List
  extends PartialElabExpFunc;
protected
  list<Absyn.Exp> es;
  list<DAE.Exp> expl;
  list<DAE.Properties> props;
  list<DAE.Type> types;
  list<DAE.Const> consts;
  DAE.Const c;
  DAE.Type ty;
algorithm
  Absyn.LIST(exps = es) := inExp;

  // The Absyn.LIST() node is used for list expressions that are transformed
  // from Absyn.ARRAY()
  if listEmpty(es) then
    outExp := DAE.LIST({});
    outProperties := DAE.PROP(DAE.T_METALIST_DEFAULT, DAE.C_CONST());
  else
    (outCache, expl, props, outST) := elabExpList(inCache, inEnv, es, inImplicit,
      inST, inDoVect, inPrefix, inInfo);
    types := list(Types.getPropType(p) for p in props);
    consts := Types.getConstList(props);
    c := List.fold(consts, Types.constAnd, DAE.C_CONST());
    ty := Types.boxIfUnboxedType(List.reduce(types, Types.superType));
    expl := Types.matchTypes(expl, types, ty, true);

    outExp := DAE.LIST(expl);
    outProperties := DAE.PROP(DAE.T_METALIST(ty, DAE.emptyTypeSource), c);
  end if;
end elabExp_List;

public function elabExpInExpression "Like elabExp but casts PROP_TUPLE to a PROP"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> st;
algorithm
  (outCache,outExp,outProperties,st) := elabExp(inCache,inEnv,inExp,inImplicit,inST,performVectorization,inPrefix,info);
  (outExp,outProperties) := elabExpInExpression2(outExp,outProperties);
end elabExpInExpression;

protected function elabExpInExpression2
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outExp,outProperties) := match (inExp,inProperties)
    local
      DAE.Type ty;
      DAE.Const c;
    case (_,DAE.PROP_TUPLE(type_ = DAE.T_TUPLE(types = ty :: _), tupleConst = DAE.TUPLE_CONST(tupleConstLst = DAE.SINGLE_CONST(const = c) :: _)))
      then (DAE.TSUB(inExp, 1, ty), DAE.PROP(ty,c));
    else (inExp,inProperties);
  end match;
end elabExpInExpression2;

public function checkAssignmentToInput
  input Absyn.Exp inExp;
  input DAE.Attributes inAttributes;
  input FCore.Graph inEnv;
  input Boolean inAllowTopLevelInputs;
  input SourceInfo inInfo;
algorithm
  // If we don't allow top level inputs and we're in a function scope and not
  // using parmodelica, check for assignment to input.
  if not inAllowTopLevelInputs and FGraph.inFunctionScope(inEnv) and
     not Config.acceptParModelicaGrammar() then
    checkAssignmentToInput2(inExp, inAttributes, inInfo);
  end if;
end checkAssignmentToInput;

protected function checkAssignmentToInput2
  input Absyn.Exp inExp;
  input DAE.Attributes inAttributes;
  input SourceInfo inInfo;
algorithm
  _ := match(inExp, inAttributes, inInfo)
    local
      Absyn.ComponentRef cr;
      String cr_str;

    case (Absyn.CREF(cr), DAE.ATTR(direction = Absyn.INPUT()), _)
      equation
        cr_str = Dump.printComponentRefStr(cr);
        Error.addSourceMessage(Error.ASSIGN_READONLY_ERROR,
          {"input", cr_str}, inInfo);
      then
        fail();

    else ();

  end match;
end checkAssignmentToInput2;

public function checkAssignmentToInputs
  input list<Absyn.Exp> inExpCrefs;
  input list<DAE.Attributes> inAttributes;
  input FCore.Graph inEnv;
  input SourceInfo inInfo;
algorithm
  if FGraph.inFunctionScope(inEnv) then
    List.threadMap1_0(inExpCrefs, inAttributes, checkAssignmentToInput2, inInfo);
  end if;
end checkAssignmentToInputs;

public function elabExpCrefNoEvalList
"elaborates a list of expressions that are only component references."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inExpl;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output list<DAE.Exp> outExpl = {};
  output list<DAE.Properties> outProperties = {};
  output list<DAE.Attributes> outAttributes = {};
  output Option<GlobalScript.SymbolTable> outST = inST;
protected
  Integer num_err = Error.getNumErrorMessages();
  DAE.Exp exp;
  DAE.Properties prop;
  list<DAE.Properties> props = {};
  DAE.Attributes attr;
  Absyn.ComponentRef cr;
  DAE.Type ty;
  DAE.Const c;
algorithm
  for e in inExpl loop
    try
      Absyn.CREF(componentRef = cr) := e;
      (outCache, exp, prop, attr) :=
        elabCrefNoEval(outCache, inEnv, cr, inImplicit, inDoVect, inPrefix, inInfo);
      outExpl := exp :: outExpl;
      outAttributes := attr :: outAttributes;
      props := prop :: props;
    else
      true := num_err == Error.getNumErrorMessages();
      Error.addSourceMessage(Error.GENERIC_ELAB_EXPRESSION,
        {Dump.printExpStr(e)}, inInfo);
    end try;
  end for;

  // BoschRexroth specifics, convert all params to vars.
  if not Flags.getConfigBool(Flags.CEVAL_EQUATION) then
    for p in props loop
      DAE.PROP(ty, c) := p;
      p := if Types.isParameter(c) then DAE.PROP(ty, DAE.C_VAR()) else p;
      outProperties := p :: outProperties;
    end for;
  else
    outProperties := listReverse(props);
  end if;

  outExpl := listReverse(outExpl);
  outAttributes := listReverse(outAttributes);
end elabExpCrefNoEvalList;

// Part of MetaModelica extension
public function elabListExp "Function that elaborates the MetaModelica list type,
for instance list<Integer>.
This is used by Inst.mo when handling a var := {...} statement"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inExpList;
  input DAE.Properties inProp;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache, outExp, outProperties, outST) := matchcontinue(inExpList)
    local
      list<DAE.Exp> expl;
      list<DAE.Properties> props;
      list<DAE.Type> types;
      DAE.Const c;
      DAE.Type ty;

    case {} then (inCache, DAE.LIST({}), inProp, inST);

    case _
      algorithm
        DAE.PROP(DAE.T_METALIST(), c) := inProp;
        (outCache, expl, props, outST) := elabExpList(inCache, inEnv,
          inExpList, inImplicit, inST, inDoVect, inPrefix, inInfo);
        types := list(Types.getPropType(p) for p in props);
        (expl, ty) := Types.listMatchSuperType(expl, types, true);
        outProperties := DAE.PROP(DAE.T_METALIST(ty, DAE.emptyTypeSource), c);
      then
        (outCache, DAE.LIST(expl), outProperties, outST);

    else
      algorithm
        true := Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Static.elabListExp failed, non-matching args in list constructor?");
      then
        fail();
  end matchcontinue;
end elabListExp;

/* ------------------------------- */

public function fromEquationsToAlgAssignments " Converts equations to algorithm assignments.
 Matchcontinue expressions may contain statements that you won't find
 in a normal equation section. For instance:

 case(...)
 local
 equation
     (var1,_,MYREC(...)) = func(...);
    fail();
 then 1;"
  input Absyn.ClassPart cp;
  output list<Absyn.AlgorithmItem> algsOut;
algorithm
  algsOut := match cp
    local
      list<Absyn.EquationItem> rest;
      list<Absyn.AlgorithmItem> alg;
      String str;

    case Absyn.ALGORITHMS(alg) then alg;
    case Absyn.EQUATIONS(rest) then fromEquationsToAlgAssignmentsWork(rest);
    else
      algorithm
        str := Dump.unparseClassPart(cp);
        Error.addInternalError("Static.fromEquationsToAlgAssignments: Unknown classPart in match expression:\n" + str, sourceInfo());
      then
        fail();
  end match;
end fromEquationsToAlgAssignments;

protected function fromEquationsToAlgAssignmentsWork
  "Converts equations to algorithm assignments.
   Matchcontinue expressions may contain statements that you won't find
   in a normal equation section. For instance:

     case(...)
       equation
         (var1, _, MYREC(...)) = func(...);
         fail();
       then
         1;"
  input list<Absyn.EquationItem> eqsIn;
  output list<Absyn.AlgorithmItem> algsOut = {};
algorithm
  for ei in eqsIn loop
    _ := match ei
      local
        Absyn.Equation eq;
        Option<Absyn.Comment> comment;
        SourceInfo info;
        list<Absyn.AlgorithmItem> algs;

      case Absyn.EQUATIONITEM(equation_ = eq, comment = comment, info = info)
        algorithm
          algs := fromEquationToAlgAssignment(eq, comment, info);
          algsOut := listAppend(algs, algsOut);
        then
          ();

      case Absyn.EQUATIONITEMCOMMENT() then ();
    end match;
  end for;

  algsOut := listReverse(algsOut);
end fromEquationsToAlgAssignmentsWork;

protected function fromEquationBranchesToAlgBranches
"Converts equations to algorithm assignments."
  input list<tuple<Absyn.Exp,list<Absyn.EquationItem>>> eqsIn;
  output list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> algsOut = {};
protected
  Absyn.Exp e;
  list<Absyn.EquationItem> eqs;
  list<Absyn.AlgorithmItem> algs;
algorithm
  for branch in eqsIn loop
    (e, eqs) := branch;
    algs := fromEquationsToAlgAssignmentsWork(eqs);
    algsOut := (e, algs) :: algsOut;
  end for;

  algsOut := listReverse(algsOut);
end fromEquationBranchesToAlgBranches;

protected function fromEquationToAlgAssignment "function: fromEquationToAlgAssignment"
  input Absyn.Equation eq;
  input Option<Absyn.Comment> comment;
  input SourceInfo info;
  output list<Absyn.AlgorithmItem> algStatement;
algorithm
  algStatement := matchcontinue (eq)
    local
      String str,strLeft,strRight;
      Absyn.Exp left,right,e;
      Absyn.AlgorithmItem algItem,algItem1,algItem2;
      Absyn.Equation eq2;
      Option<Absyn.Comment> comment2;
      SourceInfo info2;
      Absyn.AlgorithmItem res;
      Absyn.ComponentRef cref;
      Absyn.FunctionArgs fargs;
      list<Absyn.AlgorithmItem> algs, algTrueItems, algElseItems;
      list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> algBranches;
      list<Absyn.EquationItem> eqTrueItems, eqElseItems;
      list<tuple<Absyn.Exp,list<Absyn.EquationItem>>> eqBranches;

    case Absyn.EQ_EQUALS(Absyn.CREF(Absyn.CREF_IDENT(strLeft,{})),Absyn.CREF(Absyn.CREF_IDENT(strRight,{})))
      equation
        true = strLeft == strRight;
        // match x case x then ... produces equation x = x; we save a bit of time by removing it here :)
      then {};

      // The syntax n>=0 = true; is also used
    case Absyn.EQ_EQUALS(left,Absyn.BOOL(true))
      equation
        failure(Absyn.CREF(_) = left); // If lhs is a CREF, it should be an assignment
        algItem1 = Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(Absyn.CREF_IDENT("fail",{}),Absyn.FUNCTIONARGS({},{})),comment,info);
        algItem2 = Absyn.ALGORITHMITEM(Absyn.ALG_IF(Absyn.LUNARY(Absyn.NOT(),left),{algItem1},{},{}),comment,info);
      then {algItem2};

    case Absyn.EQ_EQUALS(left,Absyn.BOOL(false))
      equation
        failure(Absyn.CREF(_) = left); // If lhs is a CREF, it should be an assignment
        algItem1 = Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(Absyn.CREF_IDENT("fail",{}),Absyn.FUNCTIONARGS({},{})),comment,info);
        algItem2 = Absyn.ALGORITHMITEM(Absyn.ALG_IF(left,{algItem1},{},{}),comment,info);
      then {algItem2};

    case Absyn.EQ_NORETCALL(Absyn.CREF_IDENT("fail",_),_)
      equation
        algItem = Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(Absyn.CREF_IDENT("fail",{}),Absyn.FUNCTIONARGS({},{})),comment,info);
      then {algItem};

    case Absyn.EQ_NORETCALL(cref,fargs)
      equation
        algItem = Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(cref,fargs),comment,info);
      then {algItem};

    case Absyn.EQ_EQUALS(left,right)
      equation
        algItem = Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(left,right),comment,info);
      then {algItem};

    case Absyn.EQ_FAILURE(Absyn.EQUATIONITEM(eq2,comment2,info2))
      equation
        algs = fromEquationToAlgAssignment(eq2,comment2,info2);
        res = Absyn.ALGORITHMITEM(Absyn.ALG_FAILURE(algs),comment,info);
      then {res};

    case Absyn.EQ_IF(ifExp = e, equationTrueItems = eqTrueItems, elseIfBranches = eqBranches, equationElseItems = eqElseItems)
      equation
        algTrueItems = fromEquationsToAlgAssignmentsWork(eqTrueItems);
        algElseItems = fromEquationsToAlgAssignmentsWork(eqElseItems);
        algBranches = fromEquationBranchesToAlgBranches(eqBranches);
        res = Absyn.ALGORITHMITEM(Absyn.ALG_IF(e, algTrueItems, algBranches, algElseItems),comment,info);
      then {res};

    else
      equation
        str = Dump.equationName(eq);
        Error.addSourceMessage(Error.META_MATCH_EQUATION_FORBIDDEN, {str}, info);
      then fail();
  end matchcontinue;
end fromEquationToAlgAssignment;

protected function elabMatrixToMatrixExp
  "Convert an 2-dimensional array expression to a matrix expression."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp)
    local
      list<list<DAE.Exp>> mexpl;
      DAE.Type a;
      Integer d1;
      list<DAE.Exp> expl;

    // Convert a 2-dimensional array to a matrix.
    case (DAE.ARRAY(ty = a as DAE.T_ARRAY(dims = _ :: _ :: {}), array = expl))
      equation
        mexpl = List.map(expl, Expression.arrayContent);
        d1 = listLength(mexpl);
        true = Expression.typeBuiltin(Expression.unliftArray(Expression.unliftArray(a)));
      then
        DAE.MATRIX(a, d1, mexpl);

    // if fails, skip conversion, use generic array expression as is.
    else inExp;
  end matchcontinue;
end elabMatrixToMatrixExp;

protected function matrixConstrMaxDim
  "Helper function to elabExp (MATRIX).
  Determines the maximum dimension of the array arguments to the matrix
  constructor as.
  max(2, ndims(A), ndims(B), ndims(C),..) for matrix constructor arguments
  A, B, C, ..."
  input list<DAE.Type> inTypes;
  output Integer outMaxDim = 2;
algorithm
  for ty in inTypes loop
    outMaxDim := max(Types.numberOfDimensions(ty), outMaxDim);
  end for;
end matrixConstrMaxDim;

protected function elabCallReduction
"This function elaborates reduction expressions that look like function
  calls. For example an array constructor."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inReductionFn;
  input Absyn.Exp inReductionExp;
  input Absyn.ReductionIterType inIterType;
  input Absyn.ForIterators inIterators;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outST;
protected
  FCore.Graph env, fold_env;
  list<DAE.ReductionIterator> reduction_iters;
  list<DAE.Dimension> dims;
  DAE.Const iter_const, exp_const, c;
  Boolean has_guard_exp;
  DAE.Exp exp;
  Option<Absyn.Exp> afold_exp;
  Option<DAE.Exp> fold_exp;
  DAE.Type exp_ty, res_ty;
  Absyn.Path fn;
  Option<Values.Value> v;
  String fold_id, res_id;
algorithm
  try
    env := FGraph.openScope(inEnv, SCode.NOT_ENCAPSULATED(),
      SOME(FCore.forIterScopeName), NONE());

    // Elaborate the iterators.
    (outCache, env, reduction_iters, dims, iter_const, has_guard_exp, outST) :=
      elabCallReductionIterators(inCache, env, listReverse(inIterators),
        inReductionExp, inImplicit, inST, inDoVect, inPrefix, inInfo);
    dims := fixDimsIterType(inIterType, listReverse(dims));

    // Elaborate the expression.
    (outCache, exp, DAE.PROP(exp_ty, exp_const), outST) :=
      elabExpInExpression(outCache, env, inReductionExp, inImplicit, outST,
        inDoVect, inPrefix, inInfo);

    // Figure out the type of the reduction.
    c := exp_const; // Types.constAnd(exp_const, iter_const);
    fn := Absyn.crefToPath(inReductionFn);
    (outCache, exp, exp_ty, res_ty, v, fn) := reductionType(outCache, inEnv, fn,
      exp, exp_ty, Types.unboxedType(exp_ty), dims, has_guard_exp, inInfo);
    outProperties := DAE.PROP(exp_ty, c);

    // Construct the reduction expression.
    fold_id := Util.getTempVariableIndex();
    res_id := Util.getTempVariableIndex();
    (fold_env, afold_exp) := makeReductionFoldExp(env, fn, exp_ty, res_ty, fold_id, res_id);
    (outCache, fold_exp, _, outST) := elabExpOptAndMatchType(outCache, fold_env,
      afold_exp, res_ty, inImplicit, outST, inDoVect, inPrefix, inInfo);

    outExp := DAE.REDUCTION(
      DAE.REDUCTIONINFO(fn, inIterType, exp_ty, v, fold_id, res_id, fold_exp),
      exp,
      reduction_iters);
  else
    if listLength(inIterators) > 1 then
      Error.addSourceMessage(Error.INTERNAL_ERROR, {"Reductions using multiple iterators is not yet implemented. Try rewriting the expression using nested reductions (e.g. array(i+j for i, j) => array(array(i+j for i) for j)."}, inInfo);
    else
      true := Flags.isSet(Flags.FAILTRACE);
      Debug.traceln("Static.elabCallReduction - failed!");
    end if;
    fail();
  end try;
end elabCallReduction;

protected function fixDimsIterType
  input Absyn.ReductionIterType iterType;
  input list<DAE.Dimension> dims;
  output list<DAE.Dimension> outDims;
algorithm
  outDims := match(iterType)
    case Absyn.COMBINE() then dims;

    // TODO: Get the best dimension (if several, choose the one that is integer
    // constant; we do run-time checks to assert they are all equal)
    else {listHead(dims)};
  end match;
end fixDimsIterType;

protected function elabCallReductionIterators
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ForIterators inIterators;
  input Absyn.Exp inReductionExp;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output FCore.Graph outIteratorsEnv = inEnv;
  output list<DAE.ReductionIterator> outIterators = {};
  output list<DAE.Dimension> outDims = {};
  output DAE.Const outConst = DAE.C_CONST();
  output Boolean outHasGuard = false;
  output Option<GlobalScript.SymbolTable> outST = inST;
protected
  String iter_name;
  Absyn.Exp aiter_exp;
  Option<Absyn.Exp> oaguard_exp, oaiter_exp;
  DAE.Exp iter_exp;
  Option<DAE.Exp> guard_exp;
  DAE.Type full_iter_ty, iter_ty;
  DAE.Const iter_const, guard_const, c;
  DAE.Dimension dim;
  FCore.Graph env;
algorithm
  for iter in inIterators loop
    Absyn.ITERATOR(iter_name, oaguard_exp, oaiter_exp) := iter;

    if isSome(oaiter_exp) then
      // An explicit iteration range, elaborate it.
      SOME(aiter_exp) := oaiter_exp;

      (outCache, iter_exp, DAE.PROP(full_iter_ty, iter_const), outST) :=
        elabExpInExpression(outCache, inEnv, aiter_exp, inImpl, outST, inDoVect, inPrefix, inInfo);
    else
      // An implicit iteration range, try to deduce the range based on how the
      // iterator is used.
      (iter_exp, DAE.PROP(full_iter_ty, iter_const), outCache) := deduceIterationRange(iter_name,
        Absyn.findIteratorIndexedCrefs(inReductionExp, iter_name), inEnv, outCache, inInfo);
    end if;

    // We need to evaluate the iterator because the rest of the compiler is stupid.
    c := if FGraph.inFunctionScope(inEnv) then iter_const else DAE.C_CONST();
    (outCache, iter_exp) :=
      Ceval.cevalIfConstant(outCache, inEnv, iter_exp, DAE.PROP(full_iter_ty, c), inImpl, inInfo);

    (iter_ty, dim) := Types.unliftArrayOrList(full_iter_ty);
    // The iterator needs to be added to two different environments, to hide the
    // iterators from the different guard-expressions.
    env := FGraph.addForIterator(inEnv, iter_name, iter_ty, DAE.UNBOUND(),
      SCode.CONST(), SOME(iter_const));
    outIteratorsEnv := FGraph.addForIterator(outIteratorsEnv, iter_name, iter_ty, DAE.UNBOUND(),
      SCode.CONST(), SOME(iter_const));

    // Elaborate the guard expression.
    (outCache, guard_exp, DAE.PROP(_, guard_const), outST) := elabExpOptAndMatchType(
      outCache, env, oaguard_exp, DAE.T_BOOL_DEFAULT, inImpl, inST, inDoVect, inPrefix, inInfo);

    // If we have a guard expression we don't determine the dimension, since the
    // number of elements depend on the guard.
    if isSome(guard_exp) then
      outHasGuard := true;
      dim := DAE.DIM_UNKNOWN();
    end if;

    outConst := Types.constAnd(guard_const, iter_const);
    outIterators := DAE.REDUCTIONITER(iter_name, iter_exp, guard_exp, iter_ty) :: outIterators;
    outDims := dim :: outDims;
  end for;

  outIterators := listReverse(outIterators);
  outDims := listReverse(outDims);
end elabCallReductionIterators;

public function deduceIterationRange
  "This function tries to deduce the size of an iteration range for a reduction
   based on how an iterator is used. It does this by analysing the reduction
   expression to find out where the iterator is used as a subscript, and uses
   the subscripted components' dimensions to determine the size of the range."
  input String inIterator;
  input list<Absyn.IteratorIndexedCref> inCrefs;
  input FCore.Graph inEnv;
  input FCore.Cache inCache;
  input Absyn.Info inInfo;
  output DAE.Exp outRange;
  output DAE.Properties outProperties;
  output FCore.Cache outCache = inCache;
protected
  Absyn.ComponentRef acref;
  DAE.ComponentRef cref;
  Integer idx, i1, i2;
  DAE.Type ty;
  list<DAE.Dimension> dims;
  DAE.Dimension dim;
  DAE.Exp range;
  list<DAE.Exp> ranges = {};
  String cr_str1, cr_str2;
algorithm
  // Check that we have some crefs, otherwise we print an error and fail.
  if listLength(inCrefs) < 1 then
    Error.addSourceMessageAndFail(Error.IMPLICIT_ITERATOR_NOT_FOUND_IN_LOOP_BODY,
      {inIterator}, inInfo);
  end if;

  // For each cref-index pair, figure out the range of the subscripted dimension.
  for cr in inCrefs loop
    (acref, idx) := cr;
    cref := ComponentReference.toExpCref(acref);

    // Look the cref up to get its type.
    try
      (outCache, _, ty) := Lookup.lookupVar(outCache, inEnv, cref);
    else
      Error.addSourceMessageAndFail(Error.LOOKUP_VARIABLE_ERROR,
        {Dump.printComponentRefStr(acref), ""}, inInfo);
    end try;

    // Get the cref's dimensions.
    dims := Types.getDimensions(ty);

    // Check that the indexed dimension actually exists.
    if idx <= listLength(dims) then
      // Get the indexed dimension and construct a range from it.
      dim := listGet(dims, idx);
      (range, outProperties) := deduceReductionIterationRange2(dim, cref, ty, idx);
    else
      // The indexed dimension doesn't exist, i.e. we have too many subscripts.
      // Return some dummy variables, and let elabCallReduction handle the error
      // reporting since we don't know how many subscripts were used here.
      range := DAE.ICONST(0);
      outProperties := DAE.PROP(DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT, {DAE.DIM_INTEGER(0)},
        DAE.emptyTypeSource), DAE.C_UNKNOWN());
    end if;

    ranges := range :: ranges;
  end for;

  // If we have more than one range we must check that they are all equal,
  // otherwise it's not possible to determine the actual iteration range.
  // If they are equal we can just return anyone of them.
  outRange :: ranges := ranges;
  idx := 2;

  for r in ranges loop
    if not Expression.expEqual(r, outRange) then
      (acref, i1) := listHead(inCrefs);
      cr_str1 := Dump.printComponentRefStr(acref);
      (acref, i2) := listGet(inCrefs, idx);
      cr_str2 := Dump.printComponentRefStr(acref);
      Error.addSourceMessageAndFail(Error.INCOMPATIBLE_IMPLICIT_RANGES,
        {intString(i2), cr_str2, intString(i1), cr_str1}, inInfo);
    end if;
    idx := idx + 1;
  end for;
end deduceIterationRange;

protected function iteratorIndexedCrefsEqual
  "Checks whether two cref-index pairs are equal."
  input tuple<Absyn.ComponentRef, Integer> inCref1;
  input tuple<Absyn.ComponentRef, Integer> inCref2;
  output Boolean outEqual;
protected
  Absyn.ComponentRef cr1, cr2;
  Integer idx1, idx2;
algorithm
  (cr1, idx1) := inCref1;
  (cr2, idx2) := inCref2;
  outEqual := idx1 == idx2 and Absyn.crefEqual(cr1, cr2);
end iteratorIndexedCrefsEqual;

protected function deduceReductionIterationRange_traverser
  "Traversal function used by deduceReductionIterationRange. Used to find crefs
   which are subscripted by a given iterator."
  input Absyn.Exp inExp;
  input list<tuple<Absyn.ComponentRef, Integer>> inCrefs;
  input String inIterator;
  output Absyn.Exp outExp = inExp;
  output list<tuple<Absyn.ComponentRef, Integer>> outCrefs;
algorithm
  outCrefs := match inExp
    local
      Absyn.ComponentRef cref;

    case Absyn.CREF(componentRef = cref)
      then getIteratorIndexedCrefs(cref, inIterator, inCrefs);

    else inCrefs;
  end match;
end deduceReductionIterationRange_traverser;

protected function getIteratorIndexedCrefs
  "Checks if the given component reference is subscripted by the given iterator.
   Only cases where a subscript consists of only the iterator is considered.
   If so it adds a cref-index pair to the list, where the cref is the subscripted
   cref without subscripts, and the index is the subscripted dimension. E.g. for
   iterator i:
     a[i] => (a, 1), b[1, i] => (b, 2), c[i+1] => (), d[2].e[i] => (d[2].e, 1)"
  input Absyn.ComponentRef inCref;
  input String inIterator;
  input list<tuple<Absyn.ComponentRef, Integer>> inCrefs;
  output list<tuple<Absyn.ComponentRef, Integer>> outCrefs = inCrefs;
protected
  list<tuple<Absyn.ComponentRef, Integer>> crefs;
algorithm
  outCrefs := match inCref
    local
      list<Absyn.Subscript> subs;
      Integer idx;
      String name, id;
      Absyn.ComponentRef cref;

    case Absyn.CREF_IDENT(name = id, subscripts = subs)
      algorithm
        // For each subscript, check if the subscript consists of only the
        // iterator we're looking for.
        idx := 1;
        for sub in subs loop
          _ := match sub
            case Absyn.SUBSCRIPT(subscript = Absyn.CREF(componentRef =
                Absyn.CREF_IDENT(name = name, subscripts = {})))
              algorithm
                if name == inIterator then
                  outCrefs := (Absyn.CREF_IDENT(id, {}), idx) :: outCrefs;
                end if;
              then
                ();

            else ();
          end match;

          idx := idx + 1;
        end for;
      then
        outCrefs;

    case Absyn.CREF_QUAL(name = id, subscripts = subs, componentRef = cref)
      algorithm
        crefs := getIteratorIndexedCrefs(cref, inIterator, {});

        // Append the prefix from the qualified cref to any matches, and add
        // them to the result list.
        for cr in crefs loop
          (cref, idx) := cr;
          outCrefs := (Absyn.CREF_QUAL(id, subs, cref), idx) :: outCrefs;
        end for;
      then
        getIteratorIndexedCrefs(Absyn.CREF_IDENT(id, subs), inIterator, outCrefs);

    case Absyn.CREF_FULLYQUALIFIED(componentRef = cref)
      algorithm
        crefs := getIteratorIndexedCrefs(cref, inIterator, {});

        // Make any matches fully qualified, and add the to the result list.
        for cr in crefs loop
          (cref, idx) := cr;
          outCrefs := (Absyn.CREF_FULLYQUALIFIED(cref), idx) :: outCrefs;
        end for;
      then
        outCrefs;

    else inCrefs;
  end match;
end getIteratorIndexedCrefs;

protected function deduceReductionIterationRange2
  "Helper function to deduceReductionIterationRange. Constructs a range based on
   the given dimension."
  input DAE.Dimension inDimension;
  input DAE.ComponentRef inCref "The subscripted component without subscripts.";
  input DAE.Type inType "The type of the subscripted component.";
  input Integer inIndex "The index of the dimension.";
  output DAE.Exp outRange "The range expression.";
  output DAE.Properties outProperties "The properties of the range expression.";
protected
  DAE.Type range_ty;
  DAE.Const range_const;
  Absyn.Path enum_path, enum_start, enum_end;
  list<String> enum_lits;
  Integer sz;
algorithm
  outRange := match inDimension
    // Boolean dimension => false:true
    case DAE.DIM_BOOLEAN()
      algorithm
        range_ty := DAE.T_BOOL_DEFAULT;
        range_const := DAE.C_CONST();
      then
        DAE.RANGE(range_ty, DAE.BCONST(false), NONE(), DAE.BCONST(true));

    // Enumeration dimension => Enum.first:Enum.last
    case DAE.DIM_ENUM(enumTypeName = enum_path, literals = enum_lits)
      algorithm
        enum_start := Absyn.suffixPath(enum_path, listHead(enum_lits));
        enum_end := Absyn.suffixPath(enum_path, List.last(enum_lits));
        range_ty := DAE.T_ENUMERATION(NONE(), enum_path, enum_lits, {}, {}, DAE.emptyTypeSource);
        range_const := DAE.C_CONST();
      then
        DAE.RANGE(range_ty, DAE.ENUM_LITERAL(enum_start, 1), NONE(),
          DAE.ENUM_LITERAL(enum_end, listLength(enum_lits)));

    // Integer dimension => 1:size
    case DAE.DIM_INTEGER(integer = sz)
      algorithm
        range_ty := DAE.T_INTEGER_DEFAULT;
        range_const := DAE.C_CONST();
      then
        DAE.RANGE(range_ty, DAE.ICONST(1), NONE(), DAE.ICONST(sz));

    // Any other kind of dimension => 1:size(cref, index)
    else
      algorithm
        range_ty := DAE.T_INTEGER_DEFAULT;
        range_const := DAE.C_PARAM();
      then
        DAE.RANGE(range_ty, DAE.ICONST(1), NONE(),
          DAE.SIZE(DAE.CREF(inCref, inType), SOME(DAE.ICONST(inIndex))));

  end match;

  // Set the properties of the range expression.
  outProperties := DAE.PROP(
    DAE.T_ARRAY(range_ty, {inDimension}, DAE.emptyTypeSource),
    range_const
  );
end deduceReductionIterationRange2;

protected function makeReductionFoldExp
  input FCore.Graph inEnv;
  input Absyn.Path path;
  input DAE.Type expty;
  input DAE.Type resultTy;
  input String foldId;
  input String resultId;
  output FCore.Graph outEnv;
  output Option<Absyn.Exp> afoldExp;
protected
  String func_name;
algorithm
  (outEnv, afoldExp) := match path
    local
      Absyn.Exp exp;
      Absyn.ComponentRef cr, cr1, cr2;
      FCore.Graph env;

    case Absyn.IDENT("array") then (inEnv, NONE());
    case Absyn.IDENT("list") then (inEnv, NONE());
    case Absyn.IDENT("listReverse") then (inEnv, NONE());

    case Absyn.IDENT("sum")
      equation
        env = FGraph.addForIterator(inEnv, foldId, expty, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        env = FGraph.addForIterator(env, resultId, expty, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        cr1 = Absyn.CREF_IDENT(foldId, {});
        cr2 = Absyn.CREF_IDENT(resultId, {});
        exp = Absyn.BINARY(Absyn.CREF(cr2), Absyn.ADD(), Absyn.CREF(cr1));
      then
        (env, SOME(exp));

    case Absyn.IDENT("product")
      equation
        env = FGraph.addForIterator(inEnv, foldId, expty, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        env = FGraph.addForIterator(env, resultId, expty, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        cr1 = Absyn.CREF_IDENT(foldId, {});
        cr2 = Absyn.CREF_IDENT(resultId, {});
        exp = Absyn.BINARY(Absyn.CREF(cr2), Absyn.MUL(), Absyn.CREF(cr1));
      then
        (env, SOME(exp));

    else
      equation
        cr = Absyn.pathToCref(path);
        // print("makeReductionFoldExp => " + Absyn.pathString(path) + Types.unparseType(expty) + "\n");
        env = FGraph.addForIterator(inEnv, foldId, expty, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        env = FGraph.addForIterator(env, resultId, resultTy, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        cr1 = Absyn.CREF_IDENT(foldId, {});
        cr2 = Absyn.CREF_IDENT(resultId, {});
        exp = Absyn.CALL(cr, Absyn.FUNCTIONARGS({Absyn.CREF(cr1), Absyn.CREF(cr2)}, {}));
      then
        (env, SOME(exp));
  end match;
end makeReductionFoldExp;

protected function reductionType
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path fn;
  input DAE.Exp inExp;
  input DAE.Type inType;
  input DAE.Type unboxedType;
  input DAE.Dimensions dims;
  input Boolean hasGuardExp;
  input SourceInfo info;
  output FCore.Cache outCache = inCache;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output DAE.Type resultType;
  output Option<Values.Value> defaultValue;
  output Absyn.Path outPath;
algorithm
  (outExp, outType, resultType, defaultValue, outPath) := match(fn, unboxedType)
    local
      Boolean b;
      Integer i;
      Real r;
      list<DAE.Type> fnTypes;
      DAE.Type ty,ty2,typeA,typeB,resType;
      Absyn.Path path;
      Values.Value v;
      DAE.Exp exp;
      InstTypes.PolymorphicBindings bindings;
      Option<Values.Value> defaultBinding;

    case (Absyn.IDENT(name = "array"), _)
      algorithm
        ty := List.foldr(dims, Types.liftArray, inType);
      then
        (inExp, ty, ty, SOME(Values.ARRAY({},{0})), fn);

    case (Absyn.IDENT(name = "list"), _)
      algorithm
        (exp, ty) := Types.matchType(inExp, inType, DAE.T_METABOXED_DEFAULT, true);
        ty := List.foldr(dims, Types.liftList, ty);
      then
        (exp, ty, ty, SOME(Values.LIST({})), fn);

    case (Absyn.IDENT(name = "listReverse"), _)
      algorithm
        (exp, ty) := Types.matchType(inExp, inType, DAE.T_METABOXED_DEFAULT, true);
        ty := List.foldr(dims, Types.liftList, ty);
      then
        (exp, ty, ty, SOME(Values.LIST({})), fn);

    case (Absyn.IDENT("min"), DAE.T_REAL())
      algorithm
        r := System.realMaxLit();
        v := Values.REAL(r);
        (exp, ty) := Types.matchType(inExp, inType, DAE.T_REAL_DEFAULT, true);
      then
        (exp, ty, ty, SOME(v), fn);

    case (Absyn.IDENT("min"), DAE.T_INTEGER())
      algorithm
        i := System.intMaxLit();
        v := Values.INTEGER(i);
        (exp, ty) := Types.matchType(inExp, inType, DAE.T_INTEGER_DEFAULT, true);
      then
        (exp, ty, ty, SOME(v), fn);

    case (Absyn.IDENT("min"), DAE.T_BOOL())
      algorithm
        v := Values.BOOL(true);
        (exp, ty) := Types.matchType(inExp, inType, DAE.T_BOOL_DEFAULT, true);
      then
        (exp, ty, ty, SOME(v), fn);

    case (Absyn.IDENT("min"), DAE.T_STRING())
      algorithm
        (exp, ty) := Types.matchType(inExp, inType, DAE.T_STRING_DEFAULT, true);
      then
        (exp, ty, ty, NONE(), fn);

    case (Absyn.IDENT("max"), DAE.T_REAL())
      algorithm
        r := realNeg(System.realMaxLit());
        v := Values.REAL(r);
        (exp, ty) := Types.matchType(inExp, inType, DAE.T_REAL_DEFAULT, true);
      then
        (exp, ty, ty, SOME(v), fn);

    case (Absyn.IDENT("max"), DAE.T_INTEGER())
      algorithm
        i := intNeg(System.intMaxLit());
        v := Values.INTEGER(i);
        (exp, ty) := Types.matchType(inExp, inType, DAE.T_INTEGER_DEFAULT, true);
      then
        (exp, ty, ty, SOME(v), fn);

    case (Absyn.IDENT("max"), DAE.T_BOOL())
      algorithm
        v := Values.BOOL(false);
        (exp,ty) := Types.matchType(inExp, inType, DAE.T_BOOL_DEFAULT, true);
      then
        (exp, ty, ty, SOME(v), fn);

    case (Absyn.IDENT("max"), DAE.T_STRING())
      algorithm
        v := Values.STRING("");
        (exp, ty) := Types.matchType(inExp, inType, DAE.T_STRING_DEFAULT, true);
      then
        (exp, ty, ty, SOME(v), fn);

    case (Absyn.IDENT("sum"), DAE.T_REAL())
      algorithm
        v := Values.REAL(0.0);
        (exp, ty) := Types.matchType(inExp, inType, DAE.T_REAL_DEFAULT, true);
      then
        (exp, ty, ty, SOME(v), fn);

    case (Absyn.IDENT("sum"), DAE.T_INTEGER())
      algorithm
        v := Values.INTEGER(0);
        (exp, ty) := Types.matchType(inExp, inType, DAE.T_INTEGER_DEFAULT, true);
      then
        (exp, ty, ty, SOME(v), fn);

    case (Absyn.IDENT("sum"), DAE.T_BOOL())
      algorithm
        v := Values.BOOL(false);
        (exp, ty) := Types.matchType(inExp, inType, DAE.T_BOOL_DEFAULT, true);
      then
        (exp, ty, ty, SOME(v), fn);

    case (Absyn.IDENT("sum"), DAE.T_STRING())
      algorithm
        v := Values.STRING("");
        (exp, ty) := Types.matchType(inExp, inType, DAE.T_STRING_DEFAULT, true);
      then
        (exp, ty, ty, SOME(v), fn);

    case (Absyn.IDENT("sum"), DAE.T_ARRAY())
      then (inExp, inType, inType, NONE(), fn);

    case (Absyn.IDENT("product"), DAE.T_REAL())
      algorithm
        v := Values.REAL(1.0);
        (exp, ty) := Types.matchType(inExp, inType, DAE.T_REAL_DEFAULT, true);
      then
        (exp, ty, ty, SOME(v), fn);

    case (Absyn.IDENT("product"), DAE.T_INTEGER())
      algorithm
        v := Values.INTEGER(1);
        (exp, ty) := Types.matchType(inExp, inType, DAE.T_INTEGER_DEFAULT, true);
      then
        (exp, ty, ty, SOME(v), fn);

    case (Absyn.IDENT("product"), DAE.T_BOOL())
      algorithm
        v := Values.BOOL(true);
        (exp, ty) := Types.matchType(inExp, inType, DAE.T_BOOL_DEFAULT, true);
      then
        (exp, ty, ty, SOME(v), fn);

    case (Absyn.IDENT("product"), DAE.T_STRING())
      algorithm
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"product reduction not defined for String"},info);
      then
        fail();

    case (Absyn.IDENT("product"), DAE.T_ARRAY())
      then (inExp, inType, inType, NONE(), fn);

    else
      algorithm
        (outCache, fnTypes) := Lookup.lookupFunctionsInEnv(inCache, inEnv, fn, info);
        (typeA,typeB,resType,defaultBinding,path) := checkReductionType1(inEnv, fn,fnTypes,info);
        ty2 := if isSome(defaultBinding) then typeB else inType;
        (exp,typeA,bindings) := Types.matchTypePolymorphicWithError(inExp, inType,typeA,SOME(path),{},info);
        (_,typeB,bindings) := Types.matchTypePolymorphicWithError(DAE.CREF(DAE.CREF_IDENT("$result",DAE.T_ANYTYPE_DEFAULT,{}),DAE.T_ANYTYPE_DEFAULT),ty2,typeB,SOME(path),bindings,info);
        bindings := Types.solvePolymorphicBindings(bindings, info, {path});
        typeA := Types.fixPolymorphicRestype(typeA, bindings, info);
        typeB := Types.fixPolymorphicRestype(typeB, bindings, info);
        resType := Types.fixPolymorphicRestype(resType, bindings, info);
        (exp,ty) := checkReductionType2(exp, inType,typeA,typeB,resType,Types.equivtypes(typeA,typeB) or isSome(defaultBinding),Types.equivtypes(typeB,resType),info);
        (outCache, Util.SUCCESS()) := instantiateDaeFunction(outCache, inEnv, path, false, NONE(), true);
        Error.assertionOrAddSourceMessage(Config.acceptMetaModelicaGrammar() or Flags.isSet(Flags.EXPERIMENTAL_REDUCTIONS), Error.COMPILER_NOTIFICATION, {"Custom reduction functions are an OpenModelica extension to the Modelica Specification. Do not use them if you need your model to compile using other tools or if you are concerned about using experimental features. Use +d=experimentalReductions to disable this message."}, info);
      then
        (exp, ty, typeB, defaultBinding, path);
  end match;
end reductionType;

protected function checkReductionType1
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  input list<DAE.Type> fnTypes;
  input SourceInfo info;
  output DAE.Type typeA;
  output DAE.Type typeB;
  output DAE.Type resType;
  output Option<Values.Value> startValue;
  output Absyn.Path outPath;
algorithm
  (typeA, typeB, resType, startValue, outPath) := match fnTypes
    local
      String str1, str2;
      Absyn.Path path;
      FCore.Graph env;
      DAE.Exp e;
      Values.Value v;

    case {}
      algorithm
        str1 := Absyn.pathString(inPath);
        str2 := FGraph.printGraphPathStr(inEnv);
        Error.addSourceMessage(Error.LOOKUP_FUNCTION_ERROR, {str1, str2}, info);
      then
        fail();

    case {DAE.T_FUNCTION(funcArg={DAE.FUNCARG(ty = typeA, const = DAE.C_VAR()),
                                  DAE.FUNCARG(ty = typeB, const = DAE.C_VAR(), defaultBinding=SOME(e))},
                         funcResultType = resType, source = {path})}
      algorithm
        v := Ceval.cevalSimple(e);
      then
        (typeA, typeB, resType, SOME(v), path);

    case {DAE.T_FUNCTION(funcArg={DAE.FUNCARG(ty = typeA, const = DAE.C_VAR()),
                                  DAE.FUNCARG(ty = typeB, const = DAE.C_VAR(), defaultBinding=NONE())},
                         funcResultType = resType, source = {path})}
      then (typeA, typeB, resType, NONE(), path);

    else
      algorithm
        str1 := stringDelimitList(List.map(fnTypes, Types.unparseType), ",");
        Error.addSourceMessage(Error.UNSUPPORTED_REDUCTION_TYPE, {str1}, info);
      then
        fail();

  end match;
end checkReductionType1;

protected function checkReductionType2
  input DAE.Exp inExp;
  input DAE.Type expType;
  input DAE.Type typeA;
  input DAE.Type typeB;
  input DAE.Type typeC;
  input Boolean equivAB;
  input Boolean equivBC;
  input SourceInfo info;
  output DAE.Exp outExp;
  output DAE.Type outTy;
algorithm
  (outExp,outTy) := match(equivAB,equivBC)
    local
      String str1,str2;
      DAE.Exp exp;

    case (true, true)
        // (exp,outTy) = Types.matchType(exp,expType,typeA,true);
      then (inExp, typeA);

    case (_, false)
      algorithm
        str1 := Types.unparseType(typeB);
        str2 := Types.unparseType(typeC);
        Error.addSourceMessage(Error.REDUCTION_TYPE_ERROR,{"second argument", "result-type", "identical", str1, str2},info);
      then
        fail();

    case (false,true)
      algorithm
        str1 := Types.unparseType(typeA);
        str2 := Types.unparseType(typeB);
        Error.addSourceMessage(Error.REDUCTION_TYPE_ERROR,{"first", "second arguments", "identical", str1, str2},info);
      then
        fail();

    case (true,true)
      algorithm
        str1 := Types.unparseType(expType);
        str2 := Types.unparseType(typeA);
        Error.addSourceMessage(Error.REDUCTION_TYPE_ERROR,{"reduction expression", "first argument", "compatible", str1, str2},info);
      then
        fail();
  end match;
end checkReductionType2;

protected function constToVariability "translates an DAE.Const to a SCode.Variability"
  input DAE.Const const;
  output SCode.Variability variability;
algorithm
  variability := match const
    case DAE.C_VAR()  then SCode.VAR();
    case DAE.C_PARAM() then SCode.PARAM();
    case DAE.C_CONST() then SCode.CONST();
    case DAE.C_UNKNOWN()
      algorithm
        true := Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Static.constToVariability failed on DAE.C_UNKNOWN()\n");
      then
        fail();
  end match;
end constToVariability;

protected function constructArrayType
  "Helper function for elabCallReduction. Combines the type of the expression in
    an array constructor with the type of the generated array by replacing the
    placeholder T_UNKNOWN in arrayType with expType. Example:
      r[i] for i in 1:5 =>
        arrayType = type(i in 1:5) = (T_ARRAY(DIM(5), T_UNKNOWN),NONE())
        expType = type(r[i]) = (T_REAL,NONE())
      => resType = (T_ARRAY(DIM(5), (T_REAL,NONE())),NONE())"
  input DAE.Type arrayType;
  input DAE.Type expType;
  output DAE.Type resType;
algorithm
  resType := match(arrayType)
    local
      DAE.Type ty;
      DAE.Dimension dim;
      Option<Absyn.Path> path;
      DAE.TypeSource ts;

    case DAE.T_UNKNOWN() then expType;

    case DAE.T_ARRAY(dims = {dim}, ty = ty, source = ts)
      algorithm
        ty := constructArrayType(ty, expType);
      then
        DAE.T_ARRAY(ty, {dim}, ts);
  end match;
end constructArrayType;

protected function elabCodeType
  "This function will construct the correct type for the given Code expression.
   The types are built-in classes of different types. E.g. the class TypeName is
   the type of Code expressions corresponding to a type name Code expression."
  input Absyn.CodeNode inCode;
  output DAE.Type outType;
algorithm
  outType := match inCode
    case Absyn.C_TYPENAME()
      then DAE.T_CODE(DAE.C_TYPENAME(),DAE.emptyTypeSource);

    case Absyn.C_VARIABLENAME()
      then DAE.T_CODE(DAE.C_VARIABLENAME(),DAE.emptyTypeSource);

    case Absyn.C_EQUATIONSECTION()
      then DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("EquationSection")),{},NONE(),DAE.emptyTypeSource);

    case Absyn.C_ALGORITHMSECTION()
      then DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("AlgorithmSection")),{},NONE(),DAE.emptyTypeSource);

    case Absyn.C_ELEMENT()
      then DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("Element")),{},NONE(),DAE.emptyTypeSource);

    case Absyn.C_EXPRESSION()
      then DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("Expression")),{},NONE(),DAE.emptyTypeSource);

    case Absyn.C_MODIFICATION()
      then DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("Modification")),{},NONE(),DAE.emptyTypeSource);
  end match;
end elabCodeType;

public function elabGraphicsExp
"investigating Modelica 2.0 graphical annotations.
  These have an array of records representing graphical objects. These
  elements can have different types, therefore elab_graphic_exp will allow
  arrays with elements of varying types. "
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inPrefix,info)
    local
      Integer i,l,nmax;
      Real r;
      DAE.Dimension dim1,dim2;
      Boolean b,impl,a,havereal;
      String s,ps;
      DAE.Exp dexp,e1_1,e2_1,e_1,e3_1,start_1,stop_1,start_2,stop_2,step_1,step_2,mexp,mexp_1;
      DAE.Properties prop,prop1,prop2,prop3;
      FCore.Graph env;
      Absyn.ComponentRef cr,fn;
      DAE.Type t,start_t,stop_t,step_t,t_1,t_2;
      DAE.Const c1,c,c_start,c_stop,const,c_step;
      Absyn.Exp e,e1,e2,e3,start,stop,step,exp;
      Absyn.Operator op;
      list<Absyn.Exp> args,rest,es;
      list<Absyn.NamedArg> nargs;
      list<DAE.Exp> es_1;
      list<DAE.Properties> props;
      list<DAE.Type> types,tps_2;
      list<DAE.TupleConst> consts;
      DAE.Type rt,at;
      list<list<DAE.Properties>> tps;
      list<list<DAE.Type>> tps_1;
      FCore.Cache cache;
      Prefix.Prefix pre;
      list<list<Absyn.Exp>> ess;
      list<list<DAE.Exp>> dess;

    case (cache,_,Absyn.INTEGER(value = i),_,_,_) then (cache,DAE.ICONST(i),DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_CONST()));  /* impl */

    case (cache,_,Absyn.REAL(value = s),_,_,_)
      equation
        r = System.stringReal(s);
      then
        (cache,DAE.RCONST(r),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_CONST()));

    case (cache,_,Absyn.STRING(value = s),_,_,_)
      equation
        s = System.unescapedString(s);
      then
        (cache,DAE.SCONST(s),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_CONST()));

    case (cache,_,Absyn.BOOL(value = b),_,_,_)
      then
        (cache,DAE.BCONST(b),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()));

    // adrpo: 2010-11-17 this is now fixed!
    // adrpo, if we have useHeatPort, return false.
    // this is a workaround for handling Modelica.Electrical.Analog.Basic.Resistor
    // case (cache,env,Absyn.CREF(componentRef = cr as Absyn.CREF_IDENT("useHeatPort", _)),impl,pre,info)
    //   equation
    //     dexp  = DAE.BCONST(false);
    //     prop = DAE.PROP(DAE.T_BOOL_DEFAULT, DAE.C_CONST());
    //   then
    //     (cache,dexp,prop);
    case (cache,env,Absyn.CREF(componentRef = cr),impl,pre,_)
      equation
        (cache,SOME((dexp,prop,_))) = elabCref(cache,env, cr, impl,true /*perform vectorization*/,pre,info);
      then
        (cache,dexp,prop);

    // Binary and unary operations
    case (cache,env,(exp as Absyn.BINARY(exp1 = e1,op = op,exp2 = e2)),impl,pre,_)
      equation
        (cache,e1_1,prop1) = elabGraphicsExp(cache,env, e1, impl,pre,info);
        (cache,e2_1,prop2) = elabGraphicsExp(cache,env, e2, impl,pre,info);
        (cache, dexp, prop) = OperatorOverloading.binary(cache, env, op, prop1, e1_1, prop2, e2_1, exp, e1, e2, impl, NONE(), pre, info);
      then
        (cache, dexp, prop);
    case (cache,env,(e as Absyn.UNARY(op = Absyn.UPLUS())),impl,pre,_)
      equation
        (cache,e_1,DAE.PROP(t,c)) = elabGraphicsExp(cache,env, e, impl,pre,info);
        true = Types.isRealOrSubTypeReal(Types.arrayElementType(t));
        prop = DAE.PROP(t,c);
      then
        (cache,e_1,prop);
    case (cache,env,(exp as Absyn.UNARY(op = op,exp = e)),impl,pre,_)
      equation
        (cache,e_1,prop1) = elabGraphicsExp(cache,env, e, impl,pre,info);
        (cache, dexp, prop) = OperatorOverloading.unary(cache,env, op, prop1, e_1, exp, e, impl, NONE(), pre, info);
      then
        (cache, dexp, prop);

    // Logical binary expressions
    case (cache,env,(exp as Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2)),impl,pre,_)
      equation
        (cache,e1_1,prop1) = elabGraphicsExp(cache,env, e1, impl,pre,info);
        (cache,e2_1,prop2) = elabGraphicsExp(cache,env, e2, impl,pre,info);
        (cache, dexp, prop) = OperatorOverloading.binary(cache, env, op, prop1, e1_1, prop2, e2_1, exp, e1, e2, impl, NONE(), pre, info);
      then
        (cache, dexp, prop);

    // Logical unary expressions
    case (cache,env,(exp as Absyn.LUNARY(op = op,exp = e)),impl,pre,_)
      equation
        (cache,e_1,prop1) = elabGraphicsExp(cache,env, e, impl,pre,info);
        (cache, dexp, prop) = OperatorOverloading.unary(cache,env, op, prop1, e_1, exp, e, impl, NONE(), pre, info);
      then
        (cache, dexp, prop);

    // Relation expressions
    case (cache,env,(exp as Absyn.RELATION(exp1 = e1,op = op,exp2 = e2)),impl,pre,_)
      equation
        (cache,e1_1,prop1) = elabGraphicsExp(cache,env, e1, impl,pre,info);
        (cache,e2_1,prop2) = elabGraphicsExp(cache,env, e2, impl,pre,info);
        (cache, dexp, prop) = OperatorOverloading.binary(cache, env, op, prop1, e1_1, prop2, e2_1, exp, e1, e2, impl, NONE(), pre, info);
      then
        (cache, dexp, prop);

    // Conditional expressions
    case (cache,env,e as Absyn.IFEXP(),impl,pre,_)
      equation
        Absyn.IFEXP(ifExp = e1,trueBranch = e2,elseBranch = e3) = Absyn.canonIfExp(e);
        (cache,e1_1,prop1) = elabGraphicsExp(cache,env, e1, impl,pre,info);
        (cache,e2_1,prop2) = elabGraphicsExp(cache,env, e2, impl,pre,info);
        (cache,e3_1,prop3) = elabGraphicsExp(cache,env, e3, impl,pre,info);
        (cache,e_1,prop) = makeIfExp(cache,env, e1_1, prop1, e2_1, prop2, e3_1, prop3, impl,NONE(),pre, info);
      then
        (cache,e_1,prop);

    // Function calls
    case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),_,pre,_)
      equation
        (cache,e_1,prop,_) = elabCall(cache,env, fn, args, nargs, true,NONE(),pre,info);
      then
        (cache,e_1,prop);

    // PR. Get the properties for each expression in the tuple.
    // Each expression has its own constflag.
    // The output from functions does just have one const flag. Fix this!!
    case (cache,env,Absyn.TUPLE(expressions = (es as (_ :: _))),impl,pre,_)
      equation
        (cache,es_1,props) = elabTuple(cache,env,es,impl,false,pre,info);
        (types,consts) = splitProps(props);
      then
        (cache,DAE.TUPLE(es_1),DAE.PROP_TUPLE(DAE.T_TUPLE(types,NONE(),DAE.emptyTypeSource),DAE.TUPLE_CONST(consts)));

    // array-related expressions
    case (cache,env,Absyn.RANGE(start = start,step = NONE(),stop = stop),impl,pre,_)
      equation
        (cache,start_1,DAE.PROP(start_t,c_start)) = elabGraphicsExp(cache,env, start, impl,pre,info);
        (cache,stop_1,DAE.PROP(stop_t,c_stop)) = elabGraphicsExp(cache,env, stop, impl,pre,info);
        (_,NONE(),_,rt) = deoverloadRange(start_1,start_t,NONE(),NONE(),stop_1,stop_t,info);
        const = Types.constAnd(c_start, c_stop);
        (cache, t) = elabRangeType(cache, env, start_1, NONE(), stop_1, start_t, rt, const, impl);
      then
        (cache,DAE.RANGE(rt,start_1,NONE(),stop_1),DAE.PROP(t,const));

    case (cache,env,Absyn.RANGE(start = start,step = SOME(step),stop = stop),impl,pre,_)
      equation
        (cache,start_1,DAE.PROP(start_t,c_start)) = elabGraphicsExp(cache,env, start, impl,pre,info) "fprintln(\"setr\", \"elab_graphics_exp_range2\") &" ;
        (cache,step_1,DAE.PROP(step_t,c_step)) = elabGraphicsExp(cache,env, step, impl,pre,info);
        (cache,stop_1,DAE.PROP(stop_t,c_stop)) = elabGraphicsExp(cache,env, stop, impl,pre,info);
        (start_2,SOME(step_2),stop_2,rt) = deoverloadRange(start_1,start_t, SOME(step_1),SOME(step_t), stop_1,stop_t,info);
        c1 = Types.constAnd(c_start, c_step);
        const = Types.constAnd(c1, c_stop);
        (cache, t) = elabRangeType(cache, env, start_1, SOME(step_1), stop_1, start_t, rt, const, impl);
      then
        (cache,DAE.RANGE(rt,start_2,SOME(step_2),stop_2),DAE.PROP(t,const));

    case (cache,env,Absyn.ARRAY(arrayExp = es),impl,pre,_)
      equation
        (cache,es_1,DAE.PROP(t,const)) = elabGraphicsArray(cache,env, es, impl,pre,info);
        l = listLength(es_1);
        at = Types.simplifyType(t);
        a = Types.isArray(t);
      then
        (cache,DAE.ARRAY(at,a,es_1),DAE.PROP(DAE.T_ARRAY(t, {DAE.DIM_INTEGER(l)},DAE.emptyTypeSource),const));

    case (cache,env,Absyn.MATRIX(matrix = ess),impl,pre,_)
      equation
        (cache,dess,tps,_) = elabExpListList(cache,env,ess,impl,NONE(),true,pre,info);
        tps_1 = List.mapList(tps, Types.getPropType);
        tps_2 = List.flatten(tps_1);
        nmax = matrixConstrMaxDim(tps_2);
        havereal = Types.containReal(tps_2);
        (cache,mexp,DAE.PROP(t,c),dim1,dim2) = elabMatrixSemi(cache,env,dess,tps,impl,NONE(),havereal,nmax,true,pre,info);
        _ = elabMatrixToMatrixExp(mexp); // TODO: Does this do anything?
        t_1 = Types.unliftArray(t);
        t_2 = Types.unliftArray(t_1);
      then
        (cache,mexp,DAE.PROP(DAE.T_ARRAY(DAE.T_ARRAY(t_2, {dim2}, DAE.emptyTypeSource), {dim1}, DAE.emptyTypeSource),c));

    case (_,_,e,_,pre,_)
      equation
        Print.printErrorBuf("- Inst.elabGraphicsExp failed: ");
        ps = PrefixUtil.printPrefixStr2(pre);
        s = Dump.printExpStr(e);
        Print.printErrorBuf(ps+s);
        Print.printErrorBuf("\n");
      then
        fail();
  end matchcontinue;
end elabGraphicsExp;

protected function deoverloadRange "Does deoverloading of range expressions.
  They can be both Integer ranges and Real ranges.
  This function determines which one to use."
  input DAE.Exp inStartExp;
  input DAE.Type inStartType;
  input Option<DAE.Exp> inStepExp;
  input Option<DAE.Type> inStepType;
  input DAE.Exp inStopExp;
  input DAE.Type inStopType;
  input SourceInfo inInfo;
  output DAE.Exp outStart;
  output Option<DAE.Exp> outStep;
  output DAE.Exp outStop;
  output DAE.Type outRangeType;
algorithm
  (outStart, outStep, outStop, outRangeType) := match(inStartType, inStepType, inStopType)
    local
      DAE.Exp step_exp;
      DAE.Type step_ty, et;
      list<String> ns,ne;
      String e1_str, e2_str, t1_str, t2_str;

    // Boolean range has no step value.
    case (DAE.T_BOOL(), NONE(), DAE.T_BOOL())
      then (inStartExp, NONE(), inStopExp, DAE.T_BOOL_DEFAULT);

    case (DAE.T_INTEGER(), NONE(), DAE.T_INTEGER())
      then (inStartExp, inStepExp, inStopExp, DAE.T_INTEGER_DEFAULT);

    case (DAE.T_INTEGER(), SOME(DAE.T_INTEGER()), DAE.T_INTEGER())
      then (inStartExp, inStepExp, inStopExp, DAE.T_INTEGER_DEFAULT);

    // Enumeration range has no step value.
    case (DAE.T_ENUMERATION(names = ns), NONE(), DAE.T_ENUMERATION(names = ne))
      algorithm
        // check if enumtype start and end are equal
        if List.isEqual(ns,ne,true) then
          // convert vars
          et := Types.simplifyType(inStartType);
        else
          // Print an error if the enumerations are different for start and stop.
          e1_str := ExpressionDump.printExpStr(inStartExp);
          e2_str := ExpressionDump.printExpStr(inStopExp);
          t1_str := Types.unparseTypeNoAttr(inStartType);
          _ := Types.unparseTypeNoAttr(inStopType);
          Error.addSourceMessageAndFail(Error.UNRESOLVABLE_TYPE,
            {e1_str + ":" + e2_str, t1_str + ", " + t1_str, ""}, inInfo);
        end if;
      then
        (inStartExp, NONE(), inStopExp, et);

    case (_, NONE(), _)
      algorithm
        ({outStart, outStop},_) := OperatorOverloading.elabArglist(
          {DAE.T_REAL_DEFAULT, DAE.T_REAL_DEFAULT},
          {(inStartExp, inStartType), (inStopExp, inStopType)});
      then
        (outStart, NONE(), outStop, DAE.T_REAL_DEFAULT);

    case (_, SOME(step_ty), _)
      algorithm
        SOME(step_exp) := inStepExp;
        ({outStart, step_exp, outStop},_) := OperatorOverloading.elabArglist(
          {DAE.T_REAL_DEFAULT, DAE.T_REAL_DEFAULT, DAE.T_REAL_DEFAULT},
          {(inStartExp, inStartType), (step_exp, step_ty), (inStopExp, inStopType)});
      then
        (outStart, SOME(step_exp), outStop, DAE.T_REAL_DEFAULT);

  end match;
end deoverloadRange;

protected function elabRangeType
  "This function creates a type for a range expression given by a start, stop,
  and optional step expression. This function always succeeds, but may return an
  array-type of unknown size if the expressions can't be constant evaluated."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inStart;
  input Option<DAE.Exp> inStep;
  input DAE.Exp inStop;
  input DAE.Type inType;
  input DAE.Type inExpType;
  input DAE.Const co;
  input Boolean inImpl;
  output FCore.Cache outCache;
  output DAE.Type outType;
algorithm
  (outCache, outType) := matchcontinue(inStep, co)
    local
      DAE.Exp step_exp;
      Values.Value start_val, step_val, stop_val;
      Integer dim;
      FCore.Cache cache;

    case (_, DAE.C_VAR())
      then (inCache, DAE.T_ARRAY(inType, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource));

    // No step value.
    case (NONE(), _)
      equation
        (cache, start_val) = Ceval.ceval(inCache, inEnv, inStart, inImpl);
        (cache, stop_val) = Ceval.ceval(cache, inEnv, inStop, inImpl);
        dim = elabRangeSize(start_val, NONE(), stop_val);
      then
        (cache, DAE.T_ARRAY(inType, {DAE.DIM_INTEGER(dim)}, DAE.emptyTypeSource));

    // Some step value.
    case (SOME(step_exp), _)
      equation
        (cache, start_val) = Ceval.ceval(inCache, inEnv, inStart, inImpl);
        (cache, step_val) = Ceval.ceval(cache, inEnv, step_exp, inImpl);
        (cache, stop_val) = Ceval.ceval(cache, inEnv, inStop, inImpl);
        dim = elabRangeSize(start_val, SOME(step_val), stop_val);
      then
        (cache, DAE.T_ARRAY(inType, {DAE.DIM_INTEGER(dim)}, DAE.emptyTypeSource));

    // Ceval failed in previous cases, return an array of unknown size.
    else (inCache, DAE.T_ARRAY(inType, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource));
  end matchcontinue;
end elabRangeType;

protected function elabRangeSize
  "Returns the size of a range, given a start, stop, and optional step value."
  input Values.Value inStartValue;
  input Option<Values.Value> inStepValue;
  input Values.Value inStopValue;
  output Integer outSize;
algorithm
  outSize := matchcontinue(inStartValue, inStepValue, inStopValue)
    local
      Integer int_start, int_step, int_stop, dim;
      Real real_start, real_step, real_stop;

    // start:stop where start > stop gives an empty vector.
    case (_, NONE(), _)
      equation
        // start > stop == not (start <= stop)
        false = ValuesUtil.safeLessEq(inStartValue, inStopValue);
      then
        0;

    case (Values.INTEGER(int_start), NONE(), Values.INTEGER(int_stop))
      equation
        dim = int_stop - int_start + 1;
      then
        dim;

    case (Values.INTEGER(int_start), SOME(Values.INTEGER(int_step)),
          Values.INTEGER(int_stop))
      equation
        dim = int_stop - int_start;
        dim = intDiv(dim, int_step) + 1;
      then
        dim;

    case (Values.REAL(real_start), NONE(), Values.REAL(real_stop))
      then Util.realRangeSize(real_start, 1.0, real_stop);

    case (Values.REAL(real_start), SOME(Values.REAL(real_step)),
          Values.REAL(real_stop))
      then Util.realRangeSize(real_start, real_step, real_stop);

    case (Values.ENUM_LITERAL(index = int_start), NONE(),
          Values.ENUM_LITERAL(index = int_stop))
      equation
        dim = int_stop - int_start + 1;
      then
        dim;

    case (Values.BOOL(true), NONE(), Values.BOOL(false)) then 0;
    case (Values.BOOL(false), NONE(), Values.BOOL(true)) then 2;
    case (Values.BOOL(_), NONE(), Values.BOOL(_)) then 1;
  end matchcontinue;
end elabRangeSize;

protected function elabTuple
  "This function does elaboration of tuples, i.e. function calls returning several values."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inExpl;
  input Boolean inImplicit;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output list<DAE.Exp> outExpl = {};
  output list<DAE.Properties> outProperties = {};
protected
  DAE.Exp exp;
  DAE.Properties prop;
algorithm
  for e in inExpl loop
    (outCache, exp, prop) :=
      elabExp(outCache, inEnv, e, inImplicit, NONE(), inDoVect, inPrefix, inInfo);

    if Absyn.isTuple(e) then
      (exp, prop) := Types.matchProp(exp, prop,
        DAE.PROP(DAE.T_METABOXED_DEFAULT, DAE.C_CONST()), true);
    end if;

    outExpl := exp :: outExpl;
    outProperties := prop :: outProperties;
  end for;

  outExpl := listReverse(outExpl);
  outProperties := listReverse(outProperties);
end elabTuple;

protected function stripExtraArgsFromType
  input list<Slot> slots;
  input DAE.Type inType;
  output DAE.Type outType = inType;
algorithm
  outType := matchcontinue outType
    case DAE.T_FUNCTION()
      algorithm
        outType.funcArg := stripExtraArgsFromType2(slots, outType.funcArg);
      then
        outType;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Static.stripExtraArgsFromType failed\n");
      then
        fail();
  end matchcontinue;
end stripExtraArgsFromType;

protected function stripExtraArgsFromType2
  input list<Slot> inSlots;
  input list<DAE.FuncArg> inType;
  input list<DAE.FuncArg> inAccumType = {};
  output list<DAE.FuncArg> outType;
algorithm
  outType := match(inSlots, inType)
    local
      list<Slot> slotsRest;
      list<DAE.FuncArg> rest;
      DAE.FuncArg arg;

    case (SLOT(slotFilled = true) :: slotsRest, _ :: rest)
      then stripExtraArgsFromType2(slotsRest, rest, inAccumType);

    case (SLOT(slotFilled = false) :: slotsRest, arg :: rest)
      then stripExtraArgsFromType2(slotsRest, rest, arg :: inAccumType);

    case ({}, {}) then listReverse(inAccumType);
  end match;
end stripExtraArgsFromType2;

protected function elabArray
  "This function elaborates on array expressions.

   All types of an array should be equivalent. However, mixed Integer and Real
   elements are allowed in an array and in that case the Integer elements are
   converted to Real elements."
  input list<DAE.Exp> inExpl;
  input list<DAE.Properties> inProps;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output list<DAE.Exp> outExpLst;
  output DAE.Properties outProperties;
protected
  list<DAE.Type> types = {};
  DAE.Type ty;
  DAE.Const c = DAE.C_CONST(), c2;
  Boolean mixed;
algorithm
  // Empty array constructors are not allowed in Modelica.
  if listEmpty(inExpl) then
    Error.addSourceMessage(Error.EMPTY_ARRAY, {}, inInfo);
    fail();
  end if;

  // Get the types of all elements, and the array's variability.
  for p in inProps loop
    DAE.PROP(type_ = ty, constFlag = c2) := p;
    types := ty :: types;
    c := Types.constAnd(c, c2);
  end for;
  types := listReverse(types);

  // Check if the array contains a mix of ints and reals.
  (ty, mixed) := elabArrayHasMixedIntReals(types);

  if mixed then
    outExpLst := elabArrayReal2(inExpl, types, ty);
  else
    (outExpLst, ty) := elabArray2(inExpl, types, inPrefix, inInfo);
  end if;

  outProperties := DAE.PROP(ty, c);
end elabArray;

protected function elabArrayHasMixedIntReals
  "Helper function to elabArray. Checks if a list of types contains both
   Integer and Real types, and returns the first Real type if it does."
  input list<DAE.Type> inTypes;
  output DAE.Type outType;
  output Boolean outIsMixed = true;
protected
  Boolean has_int = false, has_real = false;
  DAE.Type ty;
  list<DAE.Type> rest_tys;
algorithm
  outType :: rest_tys := inTypes;

  // If the first element is a Real, search for an Integer.
  if Types.isReal(outType) then
    while not listEmpty(rest_tys) loop
      ty :: rest_tys := rest_tys;

      if Types.isInteger(ty) then
        return;
      end if;
    end while;
  // If the first element is an Integer, search for a Real.
  elseif Types.isInteger(outType) then
    while not listEmpty(rest_tys) loop
      outType :: rest_tys := rest_tys;

      if Types.isReal(outType) then
        return;
      end if;
    end while;
  end if;

  outIsMixed := false;
end elabArrayHasMixedIntReals;

protected function elabArrayConst
  "Constructs a const value from a list of properties, using constAnd."
  input list<DAE.Properties> inProperties;
  output DAE.Const outConst = DAE.C_CONST();
algorithm
  for prop in inProperties loop
    outConst := Types.constAnd(outConst, Types.getPropConst(prop));
  end for;
end elabArrayConst;

protected function elabArrayReal2
  "Applies type_convert to all expressions in a list to the type given as
   argument."
  input list<DAE.Exp> inExpl;
  input list<DAE.Type> inTypes;
  input DAE.Type inExpectedType;
  output list<DAE.Exp> outExpl = {};
protected
  DAE.Exp exp;
  list<DAE.Exp> rest_expl = inExpl;
algorithm
  for ty in inTypes loop
    exp :: rest_expl := rest_expl;

    // If the types are not equivalent, type convert the expression.
    if not Types.equivtypes(ty, inExpectedType) then
      exp := Types.matchType(exp, ty, inExpectedType, true);
    end if;

    outExpl := exp :: outExpl;
  end for;

  outExpl := listReverse(outExpl);
end elabArrayReal2;

protected function elabArray2
"Helper function to elabArray, checks that all elements are equivalent."
  input list<DAE.Exp> inExpl;
  input list<DAE.Type> inTypes;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output list<DAE.Exp> outExpl;
  output DAE.Type outType;
protected
  DAE.Type ty2;
  list<DAE.Type> rest_tys;
  DAE.Exp exp1;
  list<DAE.Exp> rest_expl;
  String pre_str, exp_str, expl_str, ty1_str, ty2_str;
algorithm
  exp1 :: rest_expl := inExpl;
  outType :: rest_tys := inTypes;

  outExpl := {exp1};
  outType := Types.getUniontypeIfMetarecordReplaceAllSubtypes(outType);

  for exp2 in rest_expl loop
    ty2 :: rest_tys := rest_tys;
    ty2 := Types.getUniontypeIfMetarecordReplaceAllSubtypes(ty2);

    // If the types are not equivalent, try type conversion.
    if not Types.equivtypes(outType, ty2) then
      try
        (exp2, outType) := Types.matchType(exp2, outType, ty2, false);
      else
        ty1_str := Types.unparseTypeNoAttr(outType);
        ty2_str := Types.unparseTypeNoAttr(ty2);
        Types.typeErrorSanityCheck(ty1_str, ty2_str, inInfo);
        pre_str := PrefixUtil.printPrefixStr(inPrefix);
        exp_str := ExpressionDump.printExpStr(exp2);
        expl_str := List.toString(inExpl, ExpressionDump.printExpStr, "", "[", ",", "]", true);
        Error.addSourceMessageAndFail(Error.TYPE_MISMATCH_ARRAY_EXP,
          {pre_str, exp_str, ty1_str, expl_str, ty2_str}, inInfo);
      end try;
    end if;

    outExpl := exp2 :: outExpl;
  end for;

  outExpl := listReverse(outExpl);
end elabArray2;

protected function elabGraphicsArray
  "This function elaborates array expressions for graphics elaboration."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inExpl;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output list<DAE.Exp> outExpl = {};
  output DAE.Properties outProperties;
protected
  DAE.Const c = DAE.C_CONST(), c2;
  DAE.Exp exp;
  DAE.Type ty;
algorithm
  // Empty array constructors are not allowed in Modelica.
  if listEmpty(inExpl) then
    Error.addSourceMessage(Error.EMPTY_ARRAY, {}, inInfo);
    fail();
  end if;

  for e in inExpl loop
    (outCache, exp, DAE.PROP(ty, c2)) :=
      elabGraphicsExp(outCache, inEnv, e, inImplicit, inPrefix, inInfo);
    outExpl := exp :: outExpl;
    c := Types.constAnd(c, c2);
  end for;

  outExpl := listReverse(outExpl);
  outProperties := DAE.PROP(ty, c);
end elabGraphicsArray;

protected function elabMatrixComma "This function is a helper function for elabMatrixSemi.
  It elaborates one matrix row of a matrix."
  input list<DAE.Exp> inExpl;
  input list<DAE.Properties> inProps;
  input Boolean inHaveReal;
  input Integer inDims;
  input SourceInfo inInfo;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.Dimension outDim1;
  output DAE.Dimension outDim2;
protected
  DAE.Exp exp;
  list<DAE.Exp> rest_expl, accum_expl = {};
  DAE.Properties prop;
  list<DAE.Properties> rest_props;
  DAE.Type ty, sty;
  DAE.Dimension dim2;
algorithm
  try
    exp :: rest_expl := inExpl;
    prop :: rest_props := inProps;

    (exp, outProperties as DAE.PROP(type_ = ty)) := promoteExp(exp, prop, inDims);
    accum_expl := exp :: accum_expl;
    (_, outDim1 :: outDim2 :: _) := Types.flattenArrayTypeOpt(ty);
    sty := Expression.liftArrayLeft(Types.simplifyType(ty), DAE.DIM_INTEGER(1));

    while not listEmpty(rest_expl) loop
      exp :: rest_expl := rest_expl;
      prop :: rest_props := rest_props;

      (exp, prop as DAE.PROP(type_ = ty)) := promoteExp(exp, prop, inDims);
      accum_expl := exp :: accum_expl;
      (_, _ :: dim2 :: _) := Types.flattenArrayTypeOpt(ty);
      // Comma between matrices => concatenation along second dimension.
      outDim2 := Expression.dimensionsAdd(dim2, outDim2);
      outProperties := Types.matchWithPromote(prop, outProperties, inHaveReal);
    end while;

    outExp := DAE.ARRAY(sty, false, listReverse(accum_expl));
  else
    true := Flags.isSet(Flags.FAILTRACE);
    Debug.traceln("- Static.elabMatrixComma failed");
    fail();
  end try;
end elabMatrixComma;

protected function elabMatrixCatTwoExp "author: PA
  This function takes an array expression of dimension >=3 and
  concatenates each array element along the second dimension.
  For instance
  elab_matrix_cat_two( {{1,2;5,6}, {3,4;7,8}}) => {1,2,3,4;5,6,7,8}"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
protected
  list<DAE.Exp> expl;
algorithm
  try
    DAE.ARRAY(array = expl) := inExp;
    expl := ExpressionSimplify.simplifyList(expl, {});
    expl := list(Expression.matrixToArray(e) for e in expl);
    outExp := elabMatrixCatTwo(expl);
  else
    true := Flags.isSet(Flags.FAILTRACE);
    Debug.traceln("- Static.elabMatrixCatTwoExp failed");
  end try;
end elabMatrixCatTwoExp;

protected function elabMatrixCatTwo "author: PA
  Concatenates a list of matrix(or higher dim) expressions along
  the second dimension."
  input list<DAE.Exp> inExpl;
  output DAE.Exp outExp;
protected
  DAE.Type ty;
algorithm
  try
    outExp := elabMatrixCatTwo2(e for e in listReverse(inExpl));
  else
    ty := Expression.typeof(listHead(inExpl));
    outExp := Expression.makePureBuiltinCall("cat", DAE.ICONST(2) :: inExpl, ty);
  end try;
end elabMatrixCatTwo;

protected function elabMatrixCatTwo2 "Helper function to elabMatrixCatTwo
  Concatenates two array expressions that are matrices (or higher dimension)
  along the first dimension (row)."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output DAE.Exp outExp;
protected
  list<DAE.Exp> expl1, expl2;
  Boolean sc;
  DAE.Type ty;
algorithm
  DAE.ARRAY(scalar = sc, array = expl1) := inExp1;
  DAE.ARRAY(array = expl2) := inExp2;
  expl1 := list(elabMatrixCatTwo3(e1, e2) threaded for e1 in expl1, e2 in expl2);
  ty := Expression.typeof(listHead(expl1));
  ty := Expression.liftArrayLeft(ty, DAE.DIM_INTEGER(1));
  outExp := DAE.ARRAY(ty, sc, expl1);
end elabMatrixCatTwo2;

protected function elabMatrixCatTwo3
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output DAE.Exp outExp;
protected
  DAE.Type ty1, ty2;
  Boolean sc;
  list<DAE.Exp> expl1, expl2;
algorithm
  DAE.ARRAY(ty = ty1, scalar = sc, array = expl1) := inExp1;
  DAE.ARRAY(ty = ty2, array = expl2) := inExp2;
  expl1 := listAppend(expl1, expl2);
  ty1 := Expression.concatArrayType(ty1, ty2);
  outExp := DAE.ARRAY(ty1, sc, expl1);
end elabMatrixCatTwo3;

protected function elabMatrixCatOne "author: PA
  Concatenates a list of matrix(or higher dim) expressions along
  the first dimension.
  i.e. elabMatrixCatOne( { {1,2;3,4}, {5,6;7,8} }) => {1,2;3,4;5,6;7,8}"
  input list<DAE.Exp> inExpl;
  output DAE.Exp outExp;
protected
  DAE.Type ty;
algorithm
  try
    outExp := List.reduce(inExpl, elabMatrixCatOne2);
  else
    ty := Expression.typeof(listHead(inExpl));
    outExp := Expression.makePureBuiltinCall("cat", DAE.ICONST(1) :: inExpl, ty);
  end try;
end elabMatrixCatOne;

protected function elabMatrixCatOne2
  "Helper function to elabMatrixCatOne. Concatenates two arrays along the
  first dimension."
  input DAE.Exp inArray1;
  input DAE.Exp inArray2;
  output DAE.Exp outExp;
protected
  DAE.Type ety;
  Boolean at;
  DAE.Dimension dim, dim1, dim2;
  DAE.Dimensions dim_rest;
  list<DAE.Exp> expl, expl1, expl2;
  DAE.TypeSource ts;
algorithm
  DAE.ARRAY(DAE.T_ARRAY(ety, dim1 :: dim_rest, ts), at, expl1) := inArray1;
  DAE.ARRAY(ty = DAE.T_ARRAY(dims = dim2 :: _), array = expl2) := inArray2;
  expl := listAppend(expl1, expl2);
  dim := Expression.dimensionsAdd(dim1, dim2);
  outExp := DAE.ARRAY(DAE.T_ARRAY(ety, dim :: dim_rest, ts), at, expl);
end elabMatrixCatOne2;

protected function promoteExp
  "Wrapper function for Expression.promoteExp which also handles Properties."
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input Integer inDims;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  DAE.Type ty;
  DAE.Const c;
algorithm
  try
    DAE.PROP(ty, c) := inProperties;
    (outExp, ty) := Expression.promoteExp(inExp, ty, inDims);
    outProperties := DAE.PROP(ty, c);
  else
    true := Flags.isSet(Flags.FAILTRACE);
    Debug.traceln("- Static.promoteExp failed");
  end try;
end promoteExp;

protected function elabMatrixSemi
"This function elaborates Matrix expressions, e.g. {1,0;2,1}
  A row is elaborated with elabMatrixComma."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<list<DAE.Exp>> inMatrix;
  input list<list<DAE.Properties>> inProperties;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inHaveReal;
  input Integer inDims;
  input Boolean inDoVectorization;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.Dimension outDim1;
  output DAE.Dimension outDim2;
protected
  list<DAE.Exp> expl;
  list<list<DAE.Exp>> rest_expl;
  list<DAE.Properties> props;
  list<list<DAE.Properties>> rest_props;
  DAE.Exp exp;
  DAE.Properties prop;
  DAE.Dimension dim1, dim2;
  String dim1_str, dim2_str, pre_str, el_str, ty1_str, ty2_str;
algorithm
  // Elaborate the first row so we have something to compare against.
  expl :: rest_expl := inMatrix;
  props :: rest_props := inProperties;

  (outExp, outProperties, outDim1, outDim2) :=
    elabMatrixComma(expl, props, inHaveReal, inDims, inInfo);
  outExp := elabMatrixCatTwoExp(outExp);

  // Elaborate the rest of the rows (if any).
  while not listEmpty(rest_expl) loop
    expl :: rest_expl := rest_expl;
    props :: rest_props := rest_props;

    (exp, prop, dim1, dim2) := elabMatrixComma(expl, props, inHaveReal, inDims, inInfo);

    // Check that all rows have the same size, otherwise print an error and fail.
    if not Expression.dimensionsEqual(dim2, outDim2) then
      dim1_str := ExpressionDump.dimensionString(dim1);
      dim2_str := ExpressionDump.dimensionString(dim2);
      pre_str := PrefixUtil.printPrefixStr3(inPrefix);
      el_str := List.toString(expl, ExpressionDump.printExpStr, "", "{", ", ", "}", true);
      Error.addSourceMessageAndFail(Error.MATRIX_EXP_ROW_SIZE,
        {pre_str, el_str, dim1_str, dim2_str}, inInfo);
    end if;

    // Check that all rows are of the same type, otherwise print an error and fail.
    try
      outProperties := Types.matchWithPromote(outProperties, prop, inHaveReal);
    else
      ty1_str := Types.unparsePropTypeNoAttr(outProperties);
      ty2_str := Types.unparsePropTypeNoAttr(prop);
      Types.typeErrorSanityCheck(ty1_str, ty2_str, inInfo);
      pre_str := PrefixUtil.printPrefixStr3(inPrefix);
      el_str := List.toString(expl, ExpressionDump.printExpStr, "", "{", ", ", "}", true);
      Error.addSourceMessageAndFail(Error.TYPE_MISMATCH_MATRIX_EXP,
        {pre_str, el_str, ty1_str, ty2_str}, inInfo);
    end try;

    // Add the row to the matrix.
    exp := elabMatrixCatTwoExp(exp);
    outExp := elabMatrixCatOne({outExp, exp});
    outDim1 := Expression.dimensionsAdd(dim1, outDim1);
  end while;
end elabMatrixSemi;

protected function verifyBuiltInHandlerType "
 Author BZ, 2009-02
  This function validates that arguments to function are of a correct type.
  Then call elabCallArgs to vectorize/type-match."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inExpl;
  input Boolean inImplicit;
  input extraFunc inTypeChecker;
  input String inFnName;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;

  partial function extraFunc
    input DAE.Type inp1;
    output Boolean outp1;
  end extraFunc;
protected
  Absyn.Exp e;
  DAE.Type ty;
algorithm
  {e} := inExpl;
  (outCache, _, outProperties) := elabExpInExpression(inCache, inEnv, e,
      inImplicit, NONE(), true, inPrefix, inInfo);
  ty := Types.getPropType(outProperties);
  ty := Types.arrayElementType(ty);
  true := inTypeChecker(ty);
  (outCache, outExp, outProperties as DAE.PROP()) := elabCallArgs(outCache,
      inEnv, Absyn.FULLYQUALIFIED(Absyn.IDENT(inFnName)), {e}, {}, inImplicit,
      NONE(), inPrefix, inInfo);
end verifyBuiltInHandlerType;

protected function elabBuiltinCardinality
"author: PA
  This function elaborates the cardinality operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  DAE.Type ty;
  Absyn.Exp e;
algorithm
  checkBuiltinCallArgs(inPosArgs, inNamedArgs, 1, "cardinality", inInfo);

  {e} := inPosArgs;
  (outCache, outExp, outProperties) := elabExpInExpression(inCache, inEnv, e,
    inImplicit, NONE(), true, inPrefix, inInfo);
  DAE.PROP(type_ = ty) := outProperties;
  ty := Types.liftArrayListDims(DAE.T_INTEGER_DEFAULT, Types.getDimensions(ty));
  outExp := Expression.makePureBuiltinCall("cardinality", {outExp}, ty);
  outProperties := DAE.PROP(ty, DAE.C_CONST());
end elabBuiltinCardinality;

protected function elabBuiltinSmooth
"This function elaborates the smooth operator.
  smooth(p,expr) - If p>=0 smooth(p, expr) returns expr and states that expr is p times
  continuously differentiable, i.e.: expr is continuous in all real variables appearing in
  the expression and all partial derivatives with respect to all appearing real variables
  exist and are continuous up to order p.
  The only allowed types for expr in smooth are: real expressions, arrays of
  allowed expressions, and records containing only components of allowed
  expressions."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  String msg_str;
  Absyn.Exp p, expr;
  DAE.Exp dp, dexpr;
  DAE.Type ty;
  DAE.Const c;
algorithm
  if listLength(inPosArgs) <> 2 or not listEmpty(inNamedArgs) then
    msg_str := ", expected smooth(p, expr)";
    printBuiltinFnArgError("smooth", msg_str, inPosArgs, inNamedArgs, inPrefix, inInfo);
  end if;

  {p, expr} := inPosArgs;
  (outCache, dp, DAE.PROP(ty, c), _) := elabExpInExpression(inCache, inEnv, p,
    inImplicit, NONE(), true, inPrefix, inInfo);

  if not Types.isParameterOrConstant(c) or not Types.isInteger(ty) then
    msg_str := ", first argument must be a constant or parameter expression of type Integer";
    printBuiltinFnArgError("smooth", msg_str, inPosArgs, inNamedArgs, inPrefix, inInfo);
  end if;

  (outCache, dexpr, outProperties as DAE.PROP(ty, c), _) :=
    elabExpInExpression(outCache, inEnv, expr, inImplicit, NONE(), true, inPrefix, inInfo);

  if not (Types.isReal(ty) or Types.isRecordWithOnlyReals(ty)) then
    msg_str := ", second argument must be a Real, array of Reals or record only containing Reals";
    printBuiltinFnArgError("smooth", msg_str, inPosArgs, inNamedArgs, inPrefix, inInfo);
  end if;

  ty := Types.simplifyType(ty);
  outExp := Expression.makePureBuiltinCall("smooth", {dp, dexpr}, ty);
end elabBuiltinSmooth;

protected function printBuiltinFnArgError
  input String inFnName;
  input String inMsg;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
protected
  String args_str, pre_str, msg_str;
  list<String> pos_args, named_args;
algorithm
  pos_args := list(Dump.printExpStr(arg) for arg in inPosArgs);
  named_args := list(Dump.printNamedArgStr(arg) for arg in inNamedArgs);
  args_str := stringDelimitList(listAppend(pos_args, named_args), ", ");
  pre_str := PrefixUtil.printPrefixStr3(inPrefix);
  msg_str := inFnName + "(" + args_str + ")" + inMsg;
  Error.addSourceMessageAndFail(Error.WRONG_TYPE_OR_NO_OF_ARGS, {msg_str, pre_str}, inInfo);
end printBuiltinFnArgError;

protected function elabBuiltinSize
"This function elaborates the size operator.
  Input is the list of arguments to size as Absyn.Exp
  expressions and the environment, FCore.Graph."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inBoolean,inPrefix)
    local
      DAE.Exp dimp,arraycrefe,exp;
      DAE.Type arrtp;
      DAE.Properties prop;
      Boolean impl;
      FCore.Graph env;
      Absyn.Exp arraycr,dim;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Type ety;
      DAE.Dimensions dims;

    case (cache, env, {arraycr, dim}, impl, pre)
      equation
        (cache, dimp, _, _) =
          elabExpInExpression(cache, env, dim, impl, NONE(), true, pre, info);
        (cache, arraycrefe, prop, _) =
          elabExpInExpression(cache, env, arraycr, impl, NONE(), false, pre, info);
        ety = Expression.typeof(arraycrefe);
        dims = Expression.arrayDimension(ety);
        // sent in the props of the arraycrefe as if the array is constant then the size(x, 1) is constant!
        // see Modelica.Media.Incompressible.Examples.Glycol47 and Modelica.Media.Incompressible.TableBased (hasDensity)
        (SOME(exp), SOME(prop)) =
          elabBuiltinSizeIndex(arraycrefe, prop, ety, dimp, dims, env, info);
      then
        (cache, exp, prop);

    case (cache, env, {arraycr}, impl, pre)
      equation
        (cache, arraycrefe, DAE.PROP(arrtp, _), _) =
          elabExpInExpression(cache, env, arraycr, impl, NONE(), false, pre, info);
        ety = Expression.typeof(arraycrefe);
        dims = Expression.arrayDimension(ety);
        (exp, prop) = elabBuiltinSizeNoIndex(arraycrefe, ety, dims, arrtp, info);
      then
        (cache, exp, prop);

  end match;
end elabBuiltinSize;

protected function elabBuiltinSizeNoIndex
  "Helper function to elabBuiltinSize. Elaborates the size(A) operator."
  input DAE.Exp inArrayExp;
  input DAE.Type inArrayExpType;
  input DAE.Dimensions inDimensions;
  input DAE.Type inArrayType;
  input SourceInfo inInfo;
  output DAE.Exp outSizeExp;
  output DAE.Properties outProperties;
algorithm
  (outSizeExp, outProperties) := matchcontinue(inDimensions)
    local
      list<DAE.Exp> dim_expl;
      Integer dim_int;
      DAE.Exp exp;
      DAE.Properties prop;
      Boolean b;
      DAE.Const cnst;
      DAE.Type ty;
      String exp_str, size_str;

    // size of a scalar is not allowed.
    case {}
      equation
        // Make sure that we have a proper type here. We might get DAE.T_UNKNOWN if
        // the size expression is part of a modifier, in which case we can't
        // determine if it's a scalar or array.
        false = Types.isUnknownType(inArrayExpType);
        exp_str = ExpressionDump.printExpStr(inArrayExp);
        size_str = "size(" + exp_str + ")";
        Error.addSourceMessage(Error.INVALID_ARGUMENT_TYPE_FIRST_ARRAY, {size_str}, inInfo);
      then
        fail();

    // size(A) for an array A with known dimensions.
    // Returns an array of all dimensions of A.
    case _ :: _
      equation
        dim_expl = List.map(inDimensions, Expression.dimensionSizeExp);
        dim_int = listLength(dim_expl);
        ty = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(dim_int)}, DAE.emptyTypeSource);
        exp = DAE.ARRAY(ty, true, dim_expl);
        prop = DAE.PROP(ty, DAE.C_CONST());
      then
        (exp, prop);

    // If we couldn't evaluate the size expression or find any problems with it,
    // just generate a call to size and let the runtime sort it out.
    case _ :: _
      equation
        b = Types.dimensionsKnown(inArrayType);
        cnst = Types.boolConstSize(b);
        exp = DAE.SIZE(inArrayExp,NONE());
        ty = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()} , DAE.emptyTypeSource);
        prop = DAE.PROP(ty, cnst);
      then
        (exp, prop);

  end matchcontinue;
end elabBuiltinSizeNoIndex;

protected function elabBuiltinSizeIndex
  "Helper function to elabBuiltinSize. Elaborates the size(A, x) operator."
  input DAE.Exp inArrayExp;
  input DAE.Properties inArrayProp;
  input DAE.Type inArrayType;
  input DAE.Exp inIndexExp;
  input DAE.Dimensions inDimensions;
  input FCore.Graph inEnv;
  input SourceInfo inInfo;
  output Option<DAE.Exp> outSizeExp;
  output Option<DAE.Properties> outProperties;
algorithm
  (outSizeExp, outProperties) := matchcontinue(inDimensions)
    local
      Integer dim_int, dim_count;
      DAE.Exp exp;
      DAE.Dimension dim;
      DAE.Properties prop;
      DAE.Const cnst;
      String exp_str, index_str, size_str, dim_str;

    // size of a scalar is not allowed.
    case {}
      equation
        // Make sure that we have a proper type here. We might get T_UNKNOWN if
        // the size expression is part of a modifier, in which case we can't
        // determine if it's a scalar or array.
        false = Types.isUnknownType(inArrayType);
        exp_str = ExpressionDump.printExpStr(inArrayExp);
        index_str = ExpressionDump.printExpStr(inIndexExp);
        size_str = "size(" + exp_str + ", " + index_str + ")";
        Error.addSourceMessage(Error.INVALID_ARGUMENT_TYPE_FIRST_ARRAY, {size_str}, inInfo);
      then
        (NONE(), NONE());

    // size(A, x) for an array A with known dimensions and constant x.
    // Returns the size of the x:th dimension.
    case _
      equation
        dim_int = Expression.expInt(inIndexExp);
        dim_count = listLength(inDimensions);
        true = (dim_int > 0 and dim_int <= dim_count);
        dim = listGet(inDimensions, dim_int);
        exp = Expression.dimensionSizeConstantExp(dim);
        prop = DAE.PROP(DAE.T_INTEGER_DEFAULT, DAE.C_CONST());
      then
        (SOME(exp), SOME(prop));

    // The index is out of bounds.
    case _
      equation
        false = Types.isUnknownType(inArrayType);
        dim_int = Expression.expInt(inIndexExp);
        dim_count = listLength(inDimensions);
        true = (dim_int <= 0 or dim_int > dim_count);
        index_str = intString(dim_int);
        exp_str = ExpressionDump.printExpStr(inArrayExp);
        dim_str = intString(dim_count);
        Error.addSourceMessage(Error.INVALID_SIZE_INDEX,
          {index_str, exp_str, dim_str}, inInfo);
      then
        (NONE(), NONE());

    // If we couldn't evaluate the size expression or find any problems with it,
    // just generate a call to size and let the runtime sort it out.
    else
      equation
        exp = DAE.SIZE(inArrayExp, SOME(inIndexExp));
        cnst = DAE.C_PARAM(); // Types.getPropConst(inArrayProp);
        cnst = if FGraph.inFunctionScope(inEnv) then DAE.C_VAR() else cnst;
        prop = DAE.PROP(DAE.T_INTEGER_DEFAULT, cnst);
      then
        (SOME(exp), SOME(prop));

  end matchcontinue;
end elabBuiltinSizeIndex;

protected function elabBuiltinNDims
"@author Stefan Vorkoetter <svorkoetter@maplesoft.com>
 ndims(A) : Returns the number of dimensions k of array expression A, with k >= 0.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp arraycrefe,exp;
      DAE.Type arrtp;
      Boolean impl;
      FCore.Graph env;
      Absyn.Exp arraycr;
      FCore.Cache cache;
      list<Absyn.Exp> expl;
      Integer nd;
      Prefix.Prefix pre;
      String sp;

    case (cache,env,{arraycr},_,impl,pre,_)
      equation
        (cache,_,DAE.PROP(arrtp,_),_) = elabExpInExpression(cache,env, arraycr, impl,NONE(),true,pre,info);
        nd = Types.numberOfDimensions(arrtp);
        exp = DAE.ICONST(nd);
      then
        (cache,exp,DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_CONST()));

    case (_,_,expl,_,_,pre,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        sp = PrefixUtil.printPrefixStr3(pre);
        Debug.traceln("- Static.elabBuiltinNdims failed for: ndims(" + Dump.printExpLstStr(expl) + " in component: " + sp);
      then
        fail();
  end matchcontinue;
end elabBuiltinNDims;

protected function elabBuiltinFill "This function elaborates the builtin operator fill.
  The input is the arguments to fill as Absyn.Exp expressions and the environment FCore.Graph"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp s_1,exp;
      DAE.Properties prop;
      list<DAE.Exp> dims_1;
      list<DAE.Properties> dimprops;
      DAE.Type sty;
      list<Values.Value> dimvals;
      FCore.Graph env;
      Absyn.Exp s;
      list<Absyn.Exp> dims;
      Boolean impl;
      String implstr,expstr,str,sp;
      list<String> expstrs;
      FCore.Cache cache;
      DAE.Const c1;
      Prefix.Prefix pre;
      DAE.Type exp_type;

    // try to constant evaluate dimensions
    case (cache,env,(s :: dims),_,impl,pre,_)
      equation
        (cache,s_1,prop,_) = elabExpInExpression(cache, env, s, impl,NONE(), true, pre, info);
        (cache,dims_1,dimprops,_) = elabExpList(cache, env, dims, impl, NONE(), true, pre, info);
        (dims_1,_) = Types.matchTypes(dims_1, List.map(dimprops,Types.getPropType), DAE.T_INTEGER_DEFAULT, false);
        c1 = Types.propertiesListToConst(dimprops);
        failure(DAE.C_VAR() = c1);
        c1 = Types.constAnd(c1,Types.propAllConst(prop));
        sty = Types.getPropType(prop);
        (cache,dimvals,_) = Ceval.cevalList(cache, env, dims_1, impl, NONE(), Absyn.NO_MSG(),0);
        (cache,exp,prop) = elabBuiltinFill2(cache, env, s_1, sty, dimvals, c1, pre, dims, info);
      then
        (cache, exp, prop);

    // If the previous case failed we probably couldn't constant evaluate the
    // dimensions. Create a function call to fill instead, and let the compiler sort it out later.
    case (cache, env, (s :: dims), _, impl, pre, _)
      equation
        c1 = unevaluatedFunctionVariability(env);
        (cache, s_1, prop, _) = elabExpInExpression(cache, env, s, impl,NONE(), true, pre, info);
        (cache, dims_1, dimprops, _) = elabExpList(cache, env, dims, impl, NONE(), true, pre, info);
        (dims_1,_) = Types.matchTypes(dims_1, List.map(dimprops,Types.getPropType), DAE.T_INTEGER_DEFAULT, false);
        sty = Types.getPropType(prop);
        sty = Types.liftArrayListExp(sty, dims_1);
        exp_type = Types.simplifyType(sty);
        prop = DAE.PROP(sty, c1);
        exp = Expression.makePureBuiltinCall("fill", s_1 :: dims_1, exp_type);
     then
       (cache, exp, prop);

    // Non-constant dimensons are also allowed in the case of non-expanded arrays
    // TODO: check that the diemnsions are parametric?
    case (cache, env, (s :: dims), _, impl, pre, _)
      equation
        false = Config.splitArrays();
        (cache, s_1, DAE.PROP(sty, c1), _) = elabExpInExpression(cache, env, s, impl,NONE(), true, pre, info);
        (cache, dims_1,_, _) = elabExpList(cache, env, dims, impl,NONE(), true, pre, info);
        sty = Types.liftArrayListExp(sty, dims_1);
        exp_type = Types.simplifyType(sty);
        c1 = Types.constAnd(c1, DAE.C_PARAM());
        prop = DAE.PROP(sty, c1);
        exp = Expression.makePureBuiltinCall("fill", s_1 :: dims_1, exp_type);
     then
       (cache, exp, prop);

    case (_,env,dims,_,_,_,_)
      equation
        str = "Static.elabBuiltinFill failed in component" + PrefixUtil.printPrefixStr3(inPrefix) +
              " and scope: " + FGraph.printGraphPathStr(env) +
              " for expression: fill(" + Dump.printExpLstStr(dims) + ")";
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then
        fail();

    case (_,_,dims,_,impl,pre,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Static.elabBuiltinFill: Couldn't elaborate fill(): ");
        implstr = boolString(impl);
        expstrs = List.map(dims, Dump.printExpStr);
        expstr = stringDelimitList(expstrs, ", ");
        sp = PrefixUtil.printPrefixStr3(pre);
        str = stringAppendList({expstr," impl=",implstr,", in component: ",sp});
        Debug.traceln(str);
      then
        fail();
  end matchcontinue;
end elabBuiltinFill;

public function elabBuiltinFill2
"
  function: elabBuiltinFill2
  Helper function to: elabBuiltinFill

  Public since it is used by ExpressionSimplify.simplifyBuiltinCalls.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input DAE.Type inType;
  input list<Values.Value> inValuesValueLst;
  input DAE.Const constVar;
  input Prefix.Prefix inPrefix;
  input list<Absyn.Exp> inDims;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inExp,inType,inValuesValueLst,constVar,inPrefix,inDims,inInfo)
    local
      list<DAE.Exp> arraylist;
      DAE.Type at;
      Boolean a;
      FCore.Graph env;
      DAE.Exp s,exp;
      DAE.Type sty,ty,sty2;
      Integer v;
      DAE.Const con;
      list<Values.Value> rest;
      FCore.Cache cache;
      DAE.Const c1;
      Prefix.Prefix pre;
      String str;

    // we might get here negative integers!
    case (cache,_,s,sty,{Values.INTEGER(integer = v)},c1,_,_,_)
      equation
        true = intLt(v, 0); // fill with 0 then!
        v = 0;
        arraylist = List.fill(s, v);
        sty2 = DAE.T_ARRAY(sty, {DAE.DIM_INTEGER(v)}, DAE.emptyTypeSource);
        at = Types.simplifyType(sty2);
        a = Types.isArray(sty2);
      then
        (cache,DAE.ARRAY(at,a,arraylist),DAE.PROP(sty2,c1));

    case (cache,_,s,sty,{Values.INTEGER(integer = v)},c1,_,_,_)
      equation
        arraylist = List.fill(s, v);
        sty2 = DAE.T_ARRAY(sty, {DAE.DIM_INTEGER(v)}, DAE.emptyTypeSource);
        at = Types.simplifyType(sty2);
        a = Types.isArray(sty2);
      then
        (cache,DAE.ARRAY(at,a,arraylist),DAE.PROP(sty2,c1));

    case (cache,env,s,sty,(Values.INTEGER(integer = v) :: rest),c1,pre,_,_)
      equation
        (cache,exp,DAE.PROP(ty,_)) = elabBuiltinFill2(cache,env, s, sty, rest,c1,pre,inDims,inInfo);
        arraylist = List.fill(exp, v);
        sty2 = DAE.T_ARRAY(ty, {DAE.DIM_INTEGER(v)}, DAE.emptyTypeSource);
        at = Types.simplifyType(sty2);
        a = Types.isArray(sty2);
      then
        (cache,DAE.ARRAY(at,a,arraylist),DAE.PROP(sty2,c1));

    else
      equation
        str = "Static.elabBuiltinFill2 failed in component" + PrefixUtil.printPrefixStr3(inPrefix) +
              " and scope: " + FGraph.printGraphPathStr(inEnv) +
              " for expression: fill(" + Dump.printExpLstStr(inDims) + ")";
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, inInfo);
      then
        fail();
  end matchcontinue;
end elabBuiltinFill2;

protected function elabBuiltinSymmetric "This function elaborates the builtin operator symmetric"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Type tp;
      Boolean  impl;
      DAE.Dimension d1,d2;
      DAE.Type eltp,newtp;
      DAE.Properties prop;
      DAE.Const c;
      FCore.Graph env;
      Absyn.Exp matexp;
      DAE.Exp exp_1,exp;
      FCore.Cache cache;
      Prefix.Prefix pre;

    case (cache,env,{matexp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(DAE.T_ARRAY(dims = {d1}, ty = DAE.T_ARRAY(dims = {d2}, ty = eltp)), c),_)
          = elabExpInExpression(cache,env, matexp, impl,NONE(),true,pre,info);
        newtp = DAE.T_ARRAY(DAE.T_ARRAY(eltp, {d1}, DAE.emptyTypeSource), {d2}, DAE.emptyTypeSource);
        tp = Types.simplifyType(newtp);
        exp = Expression.makePureBuiltinCall("symmetric", {exp_1}, tp);
        prop = DAE.PROP(newtp,c);
      then
        (cache,exp,prop);
  end match;
end elabBuiltinSymmetric;

protected function elabBuiltinClassDirectory
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match info
    local
      String str,fileName;

    case SOURCEINFO(fileName=fileName)
      equation
        str = stringAppend(System.dirname(fileName),"/");
        Error.addSourceMessage(Error.NON_STANDARD_OPERATOR_CLASS_DIRECTORY, {}, info);
      then
        (inCache,DAE.SCONST(str),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_CONST()));
  end match;
end elabBuiltinClassDirectory;

protected function elabBuiltinSourceInfo
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  {} := inAbsynExpLst;
  (outCache,outExp,outProperties) := match info
    local
      list<DAE.Exp> args;

    case SOURCEINFO()
      algorithm
        args := {
           DAE.SCONST(info.fileName),
           DAE.BCONST(info.isReadOnly),
           DAE.ICONST(info.lineNumberStart),
           DAE.ICONST(info.columnNumberStart),
           DAE.ICONST(info.lineNumberEnd),
           DAE.ICONST(info.columnNumberEnd),
           DAE.RCONST(info.lastModification)
        };
        outExp := DAE.METARECORDCALL(Absyn.QUALIFIED("SourceInfo",Absyn.IDENT("SOURCEINFO")),args,{"fileName","isReadOnly","lineNumberStart","columnNumberStart","lineNumberEnd","columnNumberEnd","lastEditTime"},0);
      then (inCache,outExp,DAE.PROP(DAE.T_SOURCEINFO_DEFAULT,DAE.C_CONST()));
  end match;
end elabBuiltinSourceInfo;

protected function elabBuiltinSome
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  DAE.Exp arg;
  DAE.Properties prop;
  DAE.Type ty;
  DAE.Const c;
algorithm
  // SOME should have exactly one positional argument.
  if listLength(inPosArgs) <> 1 or not listEmpty(inNamedArgs) then
    Error.addSourceMessageAndFail(Error.WRONG_TYPE_OR_NO_OF_ARGS,
      {"SOME", ""}, inInfo);
  else
    (outCache, arg, prop) := elabExpInExpression(inCache, inEnv,
      listHead(inPosArgs), inImplicit, NONE(), true, inPrefix, inInfo);
    ty := Types.getPropType(prop);
    (arg, ty) := Types.matchType(arg, ty, DAE.T_METABOXED_DEFAULT, true);
    c := Types.propAllConst(prop);
    outExp := DAE.META_OPTION(SOME(arg));
    outProperties := DAE.PROP(DAE.T_METAOPTION(ty, DAE.emptyTypeSource), c);
  end if;
end elabBuiltinSome;

protected function elabBuiltinNone
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  DAE.Exp arg;
  DAE.Properties prop;
  DAE.Type ty;
  DAE.Const c;
algorithm
  // NONE shouldn't have any arguments.
  if not listEmpty(inPosArgs) or not listEmpty(inNamedArgs) then
    Error.addSourceMessageAndFail(Error.WRONG_TYPE_OR_NO_OF_ARGS,
      {"NONE", ""}, inInfo);
  else
    outExp := DAE.META_OPTION(NONE());
    outProperties := DAE.PROP(DAE.T_METAOPTION(DAE.T_UNKNOWN_DEFAULT,
      DAE.emptyTypeSource), DAE.C_CONST());
  end if;
end elabBuiltinNone;

protected function elabBuiltinHomotopy
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  String replaceWith;
  Absyn.Exp e, e1, e2;
algorithm
  replaceWith := Flags.getConfigString(Flags.REPLACE_HOMOTOPY);

  // Replace homotopy if Flags.REPLACE_HOMOTOPY is "actual" or "simplified"
  if replaceWith == "actual" or replaceWith == "simplified" then
    {e1, e2} := getHomotopyArguments(inPosArgs, inNamedArgs);
    e := if replaceWith == "actual" then e1 else e2;

    (outCache, outExp, outProperties) := elabExpInExpression(inCache, inEnv, e,
      inImplicit, NONE(), true, inPrefix, inInfo);
  else
     // Otherwise, handle it like a normal function.
    (outCache, outExp, outProperties) := elabCallArgs(inCache, inEnv,
      Absyn.IDENT("homotopy"), inPosArgs, inNamedArgs, inImplicit, NONE(),
      inPrefix, inInfo);
  end if;
end elabBuiltinHomotopy;

protected function getHomotopyArguments
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  output list<Absyn.Exp> outPositionalArgs;
algorithm
  outPositionalArgs := match(args, nargs)
    local
      Absyn.Exp e1, e2;

    // only positional
    case ({e1, e2}, _) then {e1, e2};
    // only named
    case ({}, {Absyn.NAMEDARG("actual", e1), Absyn.NAMEDARG("simplified", e2)}) then {e1, e2};
    case ({}, {Absyn.NAMEDARG("simplified", e2), Absyn.NAMEDARG("actual", e1)}) then {e1, e2};
    // combination
    case ({e1}, {Absyn.NAMEDARG("simplified", e2)}) then {e1, e2};
    else
      equation
        Error.addCompilerError("+replaceHomotopy: homotopy called with wrong arguments: " +
          Dump.printFunctionArgsStr(Absyn.FUNCTIONARGS(args, nargs)));
      then
        fail();
  end match;
end getHomotopyArguments;

protected function elabBuiltinDynamicSelect
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache, outExp, outProperties) := elabExpInExpression(inCache, inEnv,
    listHead(inPosArgs), inImplicit, NONE(), true, inPrefix, inInfo);
end elabBuiltinDynamicSelect;

protected function elabBuiltinTranspose
  "Elaborates the builtin operator transpose."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  FCore.Cache cache;
  Absyn.Exp aexp;
  DAE.Exp exp;
  DAE.Type ty, el_ty;
  DAE.Const c;
  DAE.Dimension d1, d2;
  DAE.TypeSource src1, src2;
algorithm
  {aexp} := inPosArgs;
  (outCache, exp, DAE.PROP(ty, c), _) :=
    elabExpInExpression(inCache, inEnv, aexp, inImpl, NONE(), true, inPrefix, inInfo);
  // Transpose the type.
  DAE.T_ARRAY(DAE.T_ARRAY(el_ty, {d1}, src1), {d2}, src2) := ty;
  ty := DAE.T_ARRAY(DAE.T_ARRAY(el_ty, {d2}, src1), {d1}, src2);
  outProperties := DAE.PROP(ty, c);
  // Simplify the type and make a call to transpose.
  ty := Types.simplifyType(ty);
  outExp := Expression.makePureBuiltinCall("transpose", {exp}, ty);
end elabBuiltinTranspose;

protected function elabBuiltinSum "This function elaborates the builtin operator sum.
  The input is the arguments to fill as Absyn.Exp expressions and the environment FCore.Graph"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inBoolean,inPrefix)
    local
      DAE.Exp exp_1,exp_2;
      DAE.Type t,tp;
      DAE.Const c;
      FCore.Graph env;
      Absyn.Exp arrexp;
      Boolean impl,b;
      FCore.Cache cache;
      Prefix.Prefix pre;
      String estr,tstr;
      DAE.Type etp;

    case (cache,env,{arrexp},impl,pre)
      equation
        (cache,exp_1,DAE.PROP(t,c),_) = elabExpInExpression(cache,env,arrexp, impl,NONE(),true,pre,info);
        tp = Types.arrayElementType(t);
        etp = Types.simplifyType(tp);
        b = Types.isArray(t);
        b = b and Types.isSimpleType(tp);
        estr = Dump.printExpStr(arrexp);
        tstr = Types.unparseType(t);
        Error.assertionOrAddSourceMessage(b,Error.SUM_EXPECTED_ARRAY,{estr,tstr},info);
        exp_2 = Expression.makePureBuiltinCall("sum", {exp_1}, etp);
      then
        (cache,exp_2,DAE.PROP(tp,c));
  end match;
end elabBuiltinSum;

protected function elabBuiltinProduct "This function elaborates the builtin operator product.
  The input is the arguments to fill as Absyn.Exp expressions and the environment FCore.Graph"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inPrefix)
    local
      DAE.Exp exp_1,exp_2;
      DAE.Dimension dim;
      DAE.Type t,tp;
      DAE.Const c;
      FCore.Graph env;
      Absyn.Exp arrexp;
      Boolean impl;
      DAE.Type ty,ty2;
      FCore.Cache cache;
      Prefix.Prefix pre;
      String str_exp,str_pre;
      DAE.Type etp;

    case (cache,env,{arrexp},impl,pre)
      equation
        (cache,exp_1,DAE.PROP(ty,c),_) = elabExpInExpression(cache,env, arrexp, impl,NONE(),true,pre,info);
        (exp_1,_) = Types.matchType(exp_1, ty, DAE.T_INTEGER_DEFAULT, true);
        str_exp = "product(" + Dump.printExpStr(arrexp) + ")";
        str_pre = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.BUILTIN_FUNCTION_PRODUCT_HAS_SCALAR_PARAMETER, {str_exp, str_pre}, info);
      then
         (cache,exp_1,DAE.PROP(DAE.T_INTEGER_DEFAULT,c));

    case (cache,env,{arrexp},impl,pre)
      equation
        (cache,exp_1,DAE.PROP(ty,c),_) = elabExpInExpression(cache,env, arrexp, impl,NONE(),true,pre,info);
        (exp_1,_) = Types.matchType(exp_1, ty, DAE.T_REAL_DEFAULT, true);
        str_exp = "product(" + Dump.printExpStr(arrexp) + ")";
        str_pre = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.BUILTIN_FUNCTION_PRODUCT_HAS_SCALAR_PARAMETER, {str_exp, str_pre}, info);
      then
         (cache,exp_1,DAE.PROP(DAE.T_REAL_DEFAULT,c));

    case (cache,env,{arrexp},impl,pre)
      equation
        (cache,exp_1,DAE.PROP(t as DAE.T_ARRAY(dims = {_}, ty = tp),c),_) = elabExpInExpression(cache,env, arrexp, impl,NONE(),true,pre,info);
        tp = Types.arrayElementType(t);
        etp = Types.simplifyType(tp);
        exp_2 = Expression.makePureBuiltinCall("product", {exp_1}, etp);
        exp_2 = elabBuiltinProduct2(exp_2);
      then
        (cache,exp_2,DAE.PROP(tp,c));
  end matchcontinue;
end elabBuiltinProduct;

protected function elabBuiltinProduct2
  "Replaces product({a1,a2,...an}) with a1*a2*...*an} and
   product([a11,a12,...,a1n;...,am1,am2,..amn]) with a11*a12*...*amn"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      DAE.Exp array_exp;
      list<DAE.Exp> expl;

    case DAE.CALL(expLst = {array_exp})
      then Expression.makeProductLst(Expression.arrayElements(array_exp));

    else inExp;
  end matchcontinue;
end elabBuiltinProduct2;

protected function elabBuiltinPre "This function elaborates the builtin operator pre.
  Input is the arguments to the pre operator and the environment, FCore.Graph."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  DAE.Exp exp;
  DAE.Type ty, ty2;
  DAE.Const c;
  list<DAE.Exp> expl;
  Boolean sc;
  String exp_str, pre_str;
algorithm
  checkBuiltinCallArgs(inPosArgs, inNamedArgs, 1, "pre", inInfo);

  (outCache, exp, DAE.PROP(ty, c), _) := elabExpInExpression(inCache, inEnv,
    listHead(inPosArgs), inImplicit, NONE(), true, inPrefix, inInfo);

  // A matrix?
  if Expression.isMatrix(exp) then
    DAE.T_ARRAY(ty = ty2) := ty;
    ty2 := Types.unliftArray(ty2);
    outExp := Expression.makePureBuiltinCall("pre", {exp}, Types.simplifyType(ty2));
    outExp := elabBuiltinPreMatrix(outExp, ty2);
  // An array?
  elseif Types.isArray(ty) then
    ty2 := Types.unliftArray(ty);
    outExp := Expression.makePureBuiltinCall("pre", {exp}, Types.simplifyType(ty2));
    (expl, sc) := elabBuiltinPre2(outExp, ty2);
    outExp := DAE.ARRAY(Types.simplifyType(ty), sc, expl);
  // A scalar?
  else
    ty := Types.flattenArrayType(ty);

    if Types.basicType(ty) then
      outExp := Expression.makePureBuiltinCall("pre", {exp}, Types.simplifyType(ty));
    else
      exp_str := ExpressionDump.printExpStr(exp);
      pre_str := PrefixUtil.printPrefixStr3(inPrefix);
      Error.addSourceMessageAndFail(Error.OPERAND_BUILTIN_TYPE,
        {"pre", pre_str, exp_str}, inInfo);
    end if;
  end if;

  outProperties := DAE.PROP(ty, c);
end elabBuiltinPre;

protected function elabBuiltinPre2
  "Help function for elabBuiltinPre, when type is array, send it here."
  input DAE.Exp inExp;
  input DAE.Type inType;
  output list<DAE.Exp> outExp;
  output Boolean outScalar;
algorithm
  (outExp, outScalar) := matchcontinue(inExp)
    local
      Boolean sc;
      list<DAE.Exp> expl;
      Integer i;
      list<list<DAE.Exp>> mexpl;
      DAE.Type ty;

    case DAE.CALL(expLst = {DAE.ARRAY(scalar = sc, array = expl)})
      then (makePreLst(expl, inType), sc);

    case DAE.CALL(expLst = {DAE.MATRIX(ty = ty, integer = i, matrix = mexpl)})
      algorithm
        mexpl := list(makePreLst(e, inType) for e in mexpl);
      then
        ({DAE.MATRIX(ty, i, mexpl)}, false);

    else ({inExp}, false);
  end matchcontinue;
end elabBuiltinPre2;

protected function elabBuiltinInStream "This function elaborates the builtin operator inStream.
  Input is the arguments to the inStream operator and the environment, FCore.Graph."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  Absyn.Exp e;
  DAE.Exp exp;
  DAE.Type ty;
algorithm
  {e} := inArgs;
  (outCache, exp, outProperties) := elabExpInExpression(inCache, inEnv, e,
      inImpl, NONE(), true, inPrefix, inInfo);
  ty := Types.getPropType(outProperties);
  outExp := elabBuiltinStreamOperator(outCache, inEnv, "inStream", exp, ty, inInfo);

  // Use elabCallArgs to also try vectorized calls
  if Types.dimensionsKnown(ty) then
    (outCache, outExp, outProperties) := elabCallArgs(outCache, inEnv,
      Absyn.IDENT("inStream"), {e}, {}, inImpl, NONE(), inPrefix, inInfo);
  end if;
end elabBuiltinInStream;

protected function elabBuiltinActualStream "This function elaborates the builtin operator actualStream.
  Input is the arguments to the actualStream operator and the environment, FCore.Graph."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  Absyn.Exp e;
  DAE.Exp exp;
  DAE.Type ty;
algorithm
  {e} := inArgs;
  (outCache, exp, outProperties) := elabExpInExpression(inCache, inEnv, e,
      inImpl, NONE(), true, inPrefix, inInfo);
  ty := Types.getPropType(outProperties);
  outExp := elabBuiltinStreamOperator(outCache, inEnv, "actualStream", exp, ty, inInfo);

  // Use elabCallArgs to also try vectorized calls
  if Types.dimensionsKnown(ty) then
    (outCache, outExp, outProperties) := elabCallArgs(outCache, inEnv,
      Absyn.IDENT("actualStream"), {e}, {}, inImpl, NONE(), inPrefix, inInfo);
  end if;
end elabBuiltinActualStream;

protected function elabBuiltinStreamOperator
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String inOperator;
  input DAE.Exp inExp;
  input DAE.Type inType;
  input SourceInfo inInfo;
  output DAE.Exp outExp;
algorithm
  outExp := match inExp
    local
      DAE.Type et;
      DAE.Exp exp;

    case DAE.ARRAY(array = {}) then inExp;

    else
      equation
        exp :: _ = Expression.flattenArrayExpToList(inExp);
        validateBuiltinStreamOperator(inCache, inEnv, exp, inType, inOperator, inInfo);
        et = Types.simplifyType(inType);
        exp = Expression.makePureBuiltinCall(inOperator, {exp}, et);
      then
        exp;

  end match;
end elabBuiltinStreamOperator;

protected function validateBuiltinStreamOperator
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inOperand;
  input DAE.Type inType;
  input String inOperator;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue inOperand
    local
      DAE.ComponentRef cr;
      DAE.Attributes attr;
      String op_str;

    // Operand is a stream variable, ok!
    case DAE.CREF(componentRef = cr)
      algorithm
        (_, attr) := Lookup.lookupVar(inCache, inEnv, cr);
        DAE.ATTR(connectorType = SCode.STREAM()) := attr;
      then
        ();

    // Operand is not a stream variable, error!
    else
      algorithm
        op_str := ExpressionDump.printExpStr(inOperand);
        Error.addSourceMessage(Error.NON_STREAM_OPERAND_IN_STREAM_OPERATOR,
          {op_str, inOperator}, inInfo);
      then
        fail();
  end matchcontinue;
end validateBuiltinStreamOperator;

protected function makePreLst
  "Takes a list of expressions and makes a list of pre - expressions"
  input list<DAE.Exp> inExpl;
  input DAE.Type inType;
  output list<DAE.Exp> outExpl;
protected
  DAE.Type ty;
algorithm
  ty := Types.simplifyType(inType);
  outExpl := list(Expression.makePureBuiltinCall("pre", {e}, ty) for e in inExpl);
end makePreLst;

protected function elabBuiltinPreMatrix
  "Help function for elabBuiltinPreMatrix, when type is matrix, send it here."
  input DAE.Exp inExp;
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := match inExp
    local
      DAE.Exp exp;

    case DAE.CALL(expLst = {exp as DAE.MATRIX()})
      algorithm
        exp.matrix := list(makePreLst(row, inType) for row in exp.matrix);
      then
        exp;

    else inExp;
  end match;
end elabBuiltinPreMatrix;

protected function elabBuiltinArray "
  This function elaborates the builtin operator \'array\'. For instance,
  array(1,4,6) which is the same as {1,4,6}.
  Input is the list of arguments to the operator, as Absyn.Exp list.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  list<DAE.Exp> expl;
  list<DAE.Properties> props;
  DAE.Type ty, arr_ty;
  DAE.Const c;
  Integer len;
algorithm
  (outCache, expl, props) := elabExpList(inCache, inEnv, inPosArgs, inImplicit,
    NONE(), true, inPrefix, inInfo);
  (_, DAE.PROP(ty, c)) := elabBuiltinArray2(expl, props, inPrefix, inInfo);
  len := listLength(expl);
  arr_ty := DAE.T_ARRAY(ty, {DAE.DIM_INTEGER(len)}, DAE.emptyTypeSource);
  outProperties := DAE.PROP(arr_ty, c);
  arr_ty := Types.simplifyType(arr_ty);
  outExp := DAE.ARRAY(arr_ty, Types.isArray(ty), expl);
end elabBuiltinArray;

protected function elabBuiltinArray2
  "Helper function to elabBuiltinArray.
   Asserts that all types are of same dimensionality and of same builtin types."
  input list<DAE.Exp> inExpl;
  input list<DAE.Properties> inProperties;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output list<DAE.Exp> outExpl;
  output DAE.Properties outProperties;
protected
  String pre_str;
  list<DAE.Types> types;
  Boolean have_real = false;
  DAE.Properties prop;
algorithm
  if not sameDimensions(inProperties) then
    pre_str := PrefixUtil.printPrefixStr3(inPrefix);
    Error.addSourceMessageAndFail(Error.DIFFERENT_DIM_SIZE_IN_ARGUMENTS,
      {"array", pre_str}, inInfo);
  end if;

  prop := if Types.propsContainReal(inProperties) then
    DAE.PROP(DAE.T_REAL_DEFAULT, DAE.C_VAR()) else listHead(inProperties);
  (outExpl, outProperties) := elabBuiltinArray3(inExpl, inProperties, prop);
end elabBuiltinArray2;

protected function elabBuiltinArray3
  "Helper function to elab_builtin_array."
  input list<DAE.Exp> inExpl;
  input list<DAE.Properties> inPropertiesLst;
  input DAE.Properties inProperties;
  output list<DAE.Exp> outExpl = {};
  output DAE.Properties outProperties = listHead(inPropertiesLst);
protected
  DAE.Properties prop;
  list<DAE.Properties> rest_props = inPropertiesLst;
algorithm
  for e in inExpl loop
    prop :: rest_props := rest_props;
    e := Types.matchProp(e, prop, inProperties, true);
    outExpl := e :: outExpl;
  end for;

  outExpl := listReverse(outExpl);
end elabBuiltinArray3;

protected function elabBuiltinZeros "This function elaborates the builtin operator zeros(n)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache, outExp, outProperties) := elabBuiltinFill(inCache, inEnv,
      Absyn.INTEGER(0) :: inPosArgs, {}, inImplicit, inPrefix, inInfo);
end elabBuiltinZeros;

protected function sameDimensions
  "This function returns true if all properties, containing types, have the same
  dimensions, otherwise false."
  input list<DAE.Properties> inProps;
  output Boolean res;
protected
  list<DAE.Type> types;
  list<DAE.Dimensions> dims;
algorithm
  types := List.map(inProps, Types.getPropType);
  dims := List.map(types, Types.getDimensions);
  res := sameDimensions2(dims);
end sameDimensions;

protected function sameDimensionsExceptionDimX
  "This function returns true if all properties, containing types, have the same
  dimensions (except for dimension X), otherwise false."
  input list<DAE.Properties> inProps;
  input Integer dimException;
  output Boolean res;
protected
  list<DAE.Type> types;
  list<DAE.Dimensions> dims;
algorithm
  types := List.map(inProps, Types.getPropType);
  dims := List.map(types, Types.getDimensions);
  dims := List.map1(dims, listDelete, dimException);
  res := sameDimensions2(dims);
end sameDimensionsExceptionDimX;

protected function sameDimensions2
  "Helper function to sameDimensions. Checks that each list of dimensions has
   the same dimensions as the other lists."
  input list<DAE.Dimensions> inDimensions;
  output Boolean outSame = true;
protected
  DAE.Dimensions dims;
  list<DAE.Dimensions> rest_dims = inDimensions;
algorithm
  if listEmpty(inDimensions) then
    return;
  end if;

  while not listEmpty(listHead(rest_dims)) loop
    dims := list(listHead(d) for d in rest_dims);

    if not sameDimensions3(dims) then
      outSame := false;
      return;
    end if;

    rest_dims := list(listRest(d) for d in rest_dims);
  end while;

  // Make sure the lists were the same length.
  for d in rest_dims loop
    true := listEmpty(d);
  end for;
end sameDimensions2;

protected function sameDimensions3
  "Helper function to sameDimensions2. Check that all dimensions in a list are equal."
  input DAE.Dimensions inDims;
  output Boolean outSame = true;
protected
  DAE.Dimension dim1;
algorithm
  if listEmpty(inDims) then
    return;
  end if;

  dim1 := listHead(inDims);
  for dim2 in listRest(inDims) loop
    if not Expression.dimensionsEqual(dim1, dim2) then
      outSame := false;
      return;
    end if;
  end for;
end sameDimensions3;

protected function elabBuiltinOnes "This function elaborates on the builtin opeator ones(n)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache, outExp, outProperties) := elabBuiltinFill(inCache, inEnv,
    Absyn.INTEGER(1) :: inPosArgs, {}, inImplicit, inPrefix, inInfo);
end elabBuiltinOnes;

protected function elabBuiltinMax
  "This function elaborates on the builtin operator max(a, b)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inFnArgs;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
 (outCache, outExp, outProperties) :=
    elabBuiltinMinMaxCommon(inCache, inEnv, "max", inFnArgs, inImpl, inPrefix, info);
end elabBuiltinMax;

protected function elabBuiltinMin
  "This function elaborates the builtin operator min(a, b)"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inFnArgs;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache, outExp, outProperties) :=
    elabBuiltinMinMaxCommon(inCache, inEnv, "min", inFnArgs, inImpl, inPrefix, info);
end elabBuiltinMin;

protected function elabBuiltinMinMaxCommon
  "Helper function to elabBuiltinMin and elabBuiltinMax, containing common
  functionality."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String inFnName;
  input list<Absyn.Exp> inFnArgs;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache, outExp, outProperties):=
  match (inCache, inEnv, inFnName, inFnArgs, inImpl, inPrefix, info)
    local
      DAE.Exp arrexp_1,s1_1,s2_1, call;
      DAE.Type tp;
      DAE.Type ty,ty1,ty2,elt_ty;
      DAE.Const c,c1,c2;
      FCore.Graph env;
      Absyn.Exp arrexp,s1,s2;
      Boolean impl;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties p;

    // min|max(vector)
    case (cache, env, _, {arrexp}, impl, pre, _)
      equation
        (cache, arrexp_1, DAE.PROP(ty, c), _) =
          elabExpInExpression(cache, env, arrexp, impl,NONE(), true, pre, info);
        true = Types.isArray(ty);
        arrexp_1 = Expression.matrixToArray(arrexp_1);
        elt_ty = Types.arrayElementType(ty);
        tp = Types.simplifyType(elt_ty);
        false = Types.isString(tp);
        call = Expression.makePureBuiltinCall(inFnName, {arrexp_1}, tp);
      then
        (cache, call, DAE.PROP(elt_ty,c));

    // min|max(x,y) where x & y are scalars.
    case (cache, env, _, {s1, s2}, impl, pre, _)
      equation
        (cache, s1_1, DAE.PROP(ty1, c1), _) =
          elabExpInExpression(cache, env, s1, impl,NONE(), true, pre, info);
        (cache, s2_1, DAE.PROP(ty2, c2), _) =
          elabExpInExpression(cache, env, s2, impl,NONE(), true, pre, info);

        ty = Types.scalarSuperType(ty1,ty2);
        (s1_1,_) = Types.matchType(s1_1, ty1, ty, true);
        (s2_1,_) = Types.matchType(s2_1, ty2, ty, true);
        c = Types.constAnd(c1, c2);
        tp = Types.simplifyType(ty);
        false = Types.isString(tp);
        call = Expression.makePureBuiltinCall(inFnName, {s1_1, s2_1}, tp);
      then
        (cache, call, DAE.PROP(ty,c));

  end match;
end elabBuiltinMinMaxCommon;

protected function elabBuiltinDelay "
Author BZ
TODO: implement,
fix types, so we can have integer as input
verify that the input is correct."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  DAE.Type ty;
algorithm
  if listLength(inPosArgs) == 2 then
    ty := DAE.T_FUNCTION(
      {DAE.FUNCARG("expr",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
       DAE.FUNCARG("delayTime",DAE.T_REAL_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
      DAE.T_REAL_DEFAULT,
      DAE.FUNCTION_ATTRIBUTES_BUILTIN,
      DAE.emptyTypeSource);
  else
    ty := DAE.T_FUNCTION(
      {DAE.FUNCARG("expr",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
       DAE.FUNCARG("delayTime",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
       DAE.FUNCARG("delayMax",DAE.T_REAL_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
      DAE.T_REAL_DEFAULT,
      DAE.FUNCTION_ATTRIBUTES_BUILTIN,
      DAE.emptyTypeSource);
  end if;

  (outCache, SOME((outExp, outProperties))) := elabCallArgs3(inCache, inEnv, {ty},
      Absyn.IDENT("delay"), inPosArgs, inNamedArgs, inImplicit, NONE(), inPrefix, inInfo);
  outExp := Expression.traverseExpDummy(outExp, elabBuiltinDelay2);
end elabBuiltinDelay;

protected function elabBuiltinDelay2
  input DAE.Exp exp;
  output DAE.Exp oexp;
algorithm
  oexp := match exp
    local
      Absyn.Path path;
      DAE.Exp e1,e2;
      DAE.CallAttributes attr;

    case DAE.CALL(path as Absyn.IDENT("delay"), {e1,e2}, attr)
      then DAE.CALL(path, {e1,e2,e2}, attr);

    else exp;
  end match;
end elabBuiltinDelay2;

protected function elabBuiltinClock
  "Author: BTH
   This function elaborates the builtin Clock constructor Clock(..)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call,interval,intervalCounter,resolution,condition,startInterval,c,solverMethod;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1,prop2, prop = DAE.PROP(DAE.T_CLOCK_DEFAULT, DAE.C_VAR());
      Absyn.Exp ainterval, aintervalCounter, aresolution, acondition, astartInterval, ac, asolverMethod;
      Real rInterval, rStartInterval;
      Integer iIntervalCounter, iResolution;
      DAE.Const variability;
      String strSolverMethod;

    // Inferred clock "Clock()"
    case (cache,_,{},{},_,_,_)
      equation
        call = DAE.CLKCONST(DAE.INFERRED_CLOCK());
      then (cache, call, DAE.PROP(DAE.T_CLOCK_DEFAULT, DAE.C_VAR()));

    // clock with Integer interval "Clock(intervalCounter)"
    case (cache,env,{aintervalCounter},{},impl,pre,_)
      equation
        (cache, intervalCounter, prop1, _) = elabExpInExpression(cache,env,aintervalCounter,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        (intervalCounter,_) = Types.matchType(intervalCounter,ty1,DAE.T_INTEGER_DEFAULT,true);
        call = DAE.CLKCONST(DAE.INTEGER_CLOCK(intervalCounter, 1));
      then (cache, call, prop);

    // clock with Integer interval "Clock(intervalCounter, resolution)"
    case (cache,env,{aintervalCounter, aresolution},{},impl,pre,_)
      equation
        (cache, intervalCounter, prop1, _) = elabExpInExpression(cache,env,aintervalCounter,impl,NONE(),true,pre,info);
        (cache, resolution, prop2, _) = elabExpInExpression(cache,env,aresolution,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty2 = Types.arrayElementType(Types.getPropType(prop2));
        (intervalCounter,_) = Types.matchType(intervalCounter,ty1,DAE.T_INTEGER_DEFAULT,true);
        (resolution,_) = Types.matchType(resolution,ty2,DAE.T_INTEGER_DEFAULT,true);
        iResolution = Expression.expInt(resolution);
        true = iResolution >= 1;
        call = DAE.CLKCONST(DAE.INTEGER_CLOCK(intervalCounter, iResolution));
      then (cache, call, prop);

    // clock with Real interval "Clock(interval)"
    case (cache,env,{ainterval},{},impl,pre,_)
      equation
        (cache, interval, prop1, _) = elabExpInExpression(cache,env,ainterval,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        (interval,_) = Types.matchType(interval,ty1,DAE.T_REAL_DEFAULT,true);
        call = DAE.CLKCONST(DAE.REAL_CLOCK(interval));
      then (cache, call, prop);

    // Boolean Clock (clock triggered by zero-crossing events) "Clock(condition)"
    case (cache,env,{acondition},{},impl,pre,_)
      equation
        (cache, condition, prop1, _) = elabExpInExpression(cache,env,acondition,impl,NONE(),true,pre,info);
        astartInterval = Absyn.REAL("0.0");
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        (condition,_) = Types.matchType(condition,ty1,DAE.T_BOOL_DEFAULT,true);
        call = DAE.CLKCONST(DAE.BOOLEAN_CLOCK(condition, 0));
      then (cache, call, prop);

    // Boolean Clock (clock triggered by zero-crossing events) "Clock(condition, startInterval)"
    case (cache,env,{acondition, astartInterval},{},impl,pre,_)
      equation
        (cache, condition, prop1, _) = elabExpInExpression(cache,env,acondition,impl,NONE(),true,pre,info);
        (cache, startInterval, prop2, _) = elabExpInExpression(cache,env,astartInterval,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty2 = Types.arrayElementType(Types.getPropType(prop2));
        (condition,_) = Types.matchType(condition,ty1,DAE.T_BOOL_DEFAULT,true);
        (startInterval,_) = Types.matchType(startInterval,ty2,DAE.T_REAL_DEFAULT,true);
        rStartInterval = Expression.toReal(startInterval);
        true = rStartInterval >= 0.0;
        call = DAE.CLKCONST(DAE.BOOLEAN_CLOCK(condition, rStartInterval));
      then (cache, call, prop);

    // Solver Clock "Clock(c, solverMethod)"
    case (cache,env,{ac, asolverMethod},{},impl,pre,_)
      equation
        (cache, c, prop1, _) = elabExpInExpression(cache,env,ac,impl,NONE(),true,pre,info);
        (cache, solverMethod, prop2, _) = elabExpInExpression(cache,env,asolverMethod,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty2 = Types.arrayElementType(Types.getPropType(prop2));
        (c,_) = Types.matchType(c,ty1,DAE.T_CLOCK_DEFAULT,true);
        (solverMethod,_) = Types.matchType(solverMethod,ty2,DAE.T_STRING_DEFAULT,true);
        strSolverMethod = Expression.expString(solverMethod);
        call = DAE.CLKCONST(DAE.SOLVER_CLOCK(c, strSolverMethod));
      then (cache, call, prop);

  end matchcontinue;
end elabBuiltinClock;

protected function elabBuiltinPrevious "
Author: BTH
This function elaborates the builtin operator previous(u)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call, u;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1, prop;
      Absyn.Exp au;

    case (cache,env,{au},{},impl,pre,_)
      equation
        (cache,_, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("previous"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinPrevious;

protected function elabBuiltinHold "
Author: BTH
This function elaborates the builtin operator hold(u)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call, u;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1, prop;
      Absyn.Exp au;

    case (cache,env,{au},{},impl,pre,_)
      equation
        (cache,_, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("hold"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinHold;

protected function elabBuiltinSample "
Author: BTH
This function elaborates the builtin operator sample(..) variants."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call,u,c,start,interval;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1,prop2,prop;
      DAE.Const variability;
      Absyn.Exp au,ac,astart,ainterval;

    // The time event triggering sample(start, interval)
    case (cache,env,{astart,ainterval},{},impl,pre,_)
      equation
        (cache, start, prop1, _) = elabExpInExpression(cache,env,astart,impl,NONE(),true,pre,info);
        (cache, interval, prop2, _) = elabExpInExpression(cache,env,ainterval,impl,NONE(),true,pre,info);
        ty1 = Types.getPropType(prop1);
        ty2 = Types.getPropType(prop2);
        (start,_) = Types.matchType(start,ty1,DAE.T_REAL_DEFAULT,true);
        (interval,_) = Types.matchType(interval,ty2,DAE.T_REAL_DEFAULT,true);
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("start",DAE.T_REAL_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("interval",DAE.T_REAL_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                 DAE.T_BOOL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("sample"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    // The sample from the Synchronous Language Elements chapter (Modelica 3.3)
    case (cache,env,{au,ac}, {},impl,pre,_)
      equation
        (cache,_, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        (cache, c, prop2, _) = elabExpInExpression(cache,env,ac,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty2 = Types.arrayElementType(Types.getPropType(prop2));
        variability = Types.getPropConst(prop1);
        (c,_) = Types.matchType(c,ty2,DAE.T_CLOCK_DEFAULT,true);

        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,variability,DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("c",ty2,DAE.C_VAR(),DAE.NON_PARALLEL(),SOME(DAE.CLKCONST(DAE.INFERRED_CLOCK())))},
                ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);

        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("sample"),
          args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    case (cache,env,{au}, {},impl,pre,_)
      equation
        (cache,_, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        variability = Types.getPropConst(prop1);

        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,variability,DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("c",DAE.T_CLOCK_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),SOME(DAE.CLKCONST(DAE.INFERRED_CLOCK())))},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);

        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("sample"),
          args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);


  end matchcontinue;
end elabBuiltinSample;


protected function elabBuiltinSubSample "
Author: BTH
This function elaborates the builtin operator subSample(u,factor)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call,u,factor;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1,prop2,prop;
      Absyn.Exp au,afactor;

    case (cache,env,{au},{},impl,pre,_)
      equation
        (cache,_, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        afactor = Absyn.INTEGER(0);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("factor",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        // Pretend that subSample(x) was subSample(x,0) since "0" is the default value if no argument given
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("subSample"),
               listReverse(afactor :: args), nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    case (cache,env,{au,afactor},{},impl,pre,_)
      equation
        (cache,_, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        (cache, factor, prop2, _) = elabExpInExpression(cache,env,afactor,impl,NONE(),true,pre,info);
        (factor,_) = Types.matchType(factor,Types.getPropType(prop2),DAE.T_INTEGER_DEFAULT,true);
        true = Expression.expInt(factor) >= 0;
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("factor",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("subSample"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinSubSample;

protected function elabBuiltinSuperSample "
Author: BTH
This function elaborates the builtin operator superSample(u,factor)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call,u,factor;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1,prop2,prop;
      Absyn.Exp au,afactor;

    case (cache,env,{au},{},impl,pre,_)
      equation
        (cache,_, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        afactor = Absyn.INTEGER(0);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("factor",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        // Pretend that superSample(x) was superSample(x,0) since "0" is the default value if no argument given
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("superSample"),
               listReverse(afactor :: args), nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    case (cache,env,{au,afactor},{},impl,pre,_)
      equation
        (cache,_, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        (cache, factor, prop2, _) = elabExpInExpression(cache,env,afactor,impl,NONE(),true,pre,info);
        (factor,_) = Types.matchType(factor,Types.getPropType(prop2),DAE.T_INTEGER_DEFAULT,true);
        true = Expression.expInt(factor) >= 0;
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("factor",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("superSample"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinSuperSample;

protected function elabBuiltinShiftSample "
Author: BTH
This function elaborates the builtin operator shiftSample(u,shiftCounter,resolution)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call,u,shiftCounter,resolution;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1,prop2,prop3,prop;
      Absyn.Exp au,ashiftCounter,aresolution;

    case (cache,env,{au,ashiftCounter},{},impl,pre,_)
      equation
        (cache,_, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        (cache, shiftCounter, prop2, _) = elabExpInExpression(cache,env,ashiftCounter,impl,NONE(),true,pre,info);
        (shiftCounter,_) = Types.matchType(shiftCounter,Types.getPropType(prop2),DAE.T_INTEGER_DEFAULT,true);
        true = Expression.expInt(shiftCounter) >= 0;
        aresolution = Absyn.INTEGER(1);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("shiftCounter",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("resolution",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        // Pretend that shiftSample(u,shiftCounter) was shiftSample(u,shiftCounter,1) (resolution=1 is default value)
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("shiftSample"),
                listAppend(args,{aresolution}), nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    case (cache,env,{au,ashiftCounter,aresolution},{},impl,pre,_)
      equation
        (cache,_, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        (cache, shiftCounter, prop2, _) = elabExpInExpression(cache,env,ashiftCounter,impl,NONE(),true,pre,info);
        (shiftCounter,_) = Types.matchType(shiftCounter,Types.getPropType(prop2),DAE.T_INTEGER_DEFAULT,true);
        true = Expression.expInt(shiftCounter) >= 0;
        (cache, resolution, prop3, _) = elabExpInExpression(cache,env,aresolution,impl,NONE(),true,pre,info);
        (resolution,_) = Types.matchType(resolution,Types.getPropType(prop3),DAE.T_INTEGER_DEFAULT,true);
        true = Expression.expInt(resolution) >= 1;
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("shiftCounter",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("resolution",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("shiftSample"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

  end match;
end elabBuiltinShiftSample;

protected function elabBuiltinBackSample "
Author: BTH
This function elaborates the builtin operator backSample(u,backCounter,resolution)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call,u,backCounter,resolution;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1,prop2,prop3,prop;
      Absyn.Exp au,abackCounter,aresolution;

    case (cache,env,{au,abackCounter},{},impl,pre,_)
      equation
        (cache,_, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        (cache, backCounter, prop2, _) = elabExpInExpression(cache,env,abackCounter,impl,NONE(),true,pre,info);
        (backCounter,_) = Types.matchType(backCounter,Types.getPropType(prop2),DAE.T_INTEGER_DEFAULT,true);
        true = Expression.expInt(backCounter) >= 0;
        aresolution = Absyn.INTEGER(1);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("backCounter",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("resolution",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        // Pretend that backSample(u,backCounter) was backSample(u,backCounter,1) (resolution=1 is default value)
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("backSample"),
                listAppend(args, {aresolution}), nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    case (cache,env,{au,abackCounter,aresolution},{},impl,pre,_)
      equation
        (cache,_, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        (cache, backCounter, prop2, _) = elabExpInExpression(cache,env,abackCounter,impl,NONE(),true,pre,info);
        (backCounter,_) = Types.matchType(backCounter,Types.getPropType(prop2),DAE.T_INTEGER_DEFAULT,true);
        true = Expression.expInt(backCounter) >= 0;
        (cache, resolution, prop3, _) = elabExpInExpression(cache,env,aresolution,impl,NONE(),true,pre,info);
        (resolution,_) = Types.matchType(resolution,Types.getPropType(prop3),DAE.T_INTEGER_DEFAULT,true);
        true = Expression.expInt(resolution) >= 1;
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("backCounter",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("resolution",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("backSample"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

  end match;
end elabBuiltinBackSample;

protected function elabBuiltinNoClock "
Author: BTH
This function elaborates the builtin operator noClock(u)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call, u;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1, prop;
      Absyn.Exp au;

    case (cache,env,{au},{},impl,pre,_)
      equation
        (cache,_, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("noClock"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinNoClock;

protected function elabBuiltinInterval "
Author: BTH
This function elaborates the builtin operator interval(u)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call, u;
      DAE.Type ty1,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1, prop;
      Absyn.Exp au;

    case (cache,env,{},{},impl,pre,_)
      equation
        ty =  DAE.T_FUNCTION(
                {},
                DAE.T_REAL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("interval"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    case (cache,env,{au},{},impl,pre,_)
      equation
        (cache,_, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                DAE.T_REAL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("interval"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinInterval;

protected function isBlockTypeWorkaround "
Author: BTH
Helper function to elabBuiltinTransition.
This function checks whether a type is complex.
It is used as a workaround to check for block instances in elabBuiltinTransition, elabBultinActiveState and elabBuiltinInitalState.
This is not perfect since there are also other instances that are 'complex' types which are not block instances.
But allowing more might not be so bad anyway, since the MLS 3.3 restriction to block seems more restrictive than necessary,
e.g., one can be more lenient and allow models as states, too..."
  input DAE.Type ity;
  output Boolean b;
algorithm
  b := match(ity)
    case (DAE.T_SUBTYPE_BASIC()) then isBlockTypeWorkaround(ity.complexType);
    case (DAE.T_COMPLEX()) then true;
    else false;
  end match;
end isBlockTypeWorkaround;

protected function elabBuiltinTransition "
Author: BTH
This function elaborates the builtin operator
transition(from, to, condition, immediate=true, reset=true, synchronize=false, priority=1)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop;
      Integer n, nFrom;
      String strMsg0,strPre,s1,s2;
      list<String> slist;

    case (cache,env,_,_,impl,pre,_)
      equation
        slist = List.map(nargs,Dump.printNamedArgStr);
        s1 = Dump.printExpLstStr(args);
        s2 = stringDelimitList(s1 :: slist, ", ");
        strMsg0 = "transition(" + s2 + ")";
        strPre = PrefixUtil.printPrefixStr3(pre);
        n = listLength(args);

        // Check if "from" and "to" arguments are of complex type and return their type
        ty1 = elabBuiltinTransition2(cache, env, args, nargs, impl, pre, info, "from", n, strMsg0, strPre);
        ty2 = elabBuiltinTransition2(cache, env, args, nargs, impl, pre, info, "to", n, strMsg0, strPre);

        // Alternatively, ty1 and ty2 could be replaced by DAE.T_CODE(DAE.C_VARIABLENAME,{}), not sure if that would be a better solution
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("from",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("to",ty2,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("condition",DAE.T_BOOL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("immediate",DAE.T_BOOL_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),SOME(DAE.BCONST(true))),
                 DAE.FUNCARG("reset",DAE.T_BOOL_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),SOME(DAE.BCONST(true))),
                 DAE.FUNCARG("synchronize",DAE.T_BOOL_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),SOME(DAE.BCONST(false))),
                 DAE.FUNCARG("priority",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),SOME(DAE.ICONST(1)))},
                 DAE.T_NORETCALL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("transition"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinTransition;

protected function elabBuiltinTransition2 "
Author: BTH
Helper function to elabBuiltinTransition.
Check if the \"from\" argument or the \"to\" argument is of complex type."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  input Absyn.Ident argName;
  input Integer n;
  input String strMsg0;
  input String strPre;
  output DAE.Type ty;
protected
  Absyn.Exp arg1;
  DAE.Properties prop1;
  Integer nPos;
  String s1,s2,strPos,strMsg1;
  Boolean b1;
algorithm
  strPos := if argName == "from" then "first" else "second";
  nPos := if argName == "from" then 1 else 2;
  b1 := List.isMemberOnTrue(argName, nargs, elabBuiltinTransition3);

  s1 := strMsg0 + ", named argument \"" + argName + "\" already has a value.";
  Error.assertionOrAddSourceMessage(not (b1 and n >= nPos),Error.WRONG_TYPE_OR_NO_OF_ARGS,
    {s1, strPre}, info);

  s2 := strMsg0 + ", missing value for " + strPos + " argument \"" + argName + "\".";
  Error.assertionOrAddSourceMessage(b1 or n >= nPos, Error.WRONG_TYPE_OR_NO_OF_ARGS,
      {s2, strPre}, info);

  arg1 := elabBuiltinTransition5(argName, b1, args, nargs);
  (_, _, prop1, _) := elabExpInExpression(inCache,inEnv,arg1,inBoolean,NONE(),true,inPrefix,info);
  ty := Types.getPropType(prop1);
  strMsg1 := strMsg0 + ", " + strPos + "argument needs to be a block instance.";
  Error.assertionOrAddSourceMessage(isBlockTypeWorkaround(ty),Error.WRONG_TYPE_OR_NO_OF_ARGS,
  {strMsg1, strPre}, info);

end elabBuiltinTransition2;


protected function elabBuiltinTransition3 "
Author: BTH
Helper function to elabBuiltinTransition.
Checks if namedArg.argName == name"
  input Absyn.Ident name;
  input Absyn.NamedArg namedArg;
  output Boolean outIsEqual;
algorithm
  outIsEqual := match namedArg
    local
      Absyn.Ident argName;
      Absyn.Exp argValue;

    case Absyn.NAMEDARG()
      then stringEq(name, namedArg.argName);

    else false;
  end match;
end elabBuiltinTransition3;

protected function elabBuiltinTransition4 "
Author: BTH
Helper function to elabBuiltinTransition.
Extract element argValue."
  input Absyn.NamedArg inElement;
  output Absyn.Exp argValue;
algorithm
  Absyn.NAMEDARG(argValue = argValue) := inElement;
end elabBuiltinTransition4;

protected function elabBuiltinTransition5 "
Author: BTH
Helper function to elabBuiltinTransition."
  input String argName;
  input Boolean getAsNamedArg;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  output Absyn.Exp argValue;
algorithm
  argValue := match (argName, getAsNamedArg)
    local
      Absyn.NamedArg namedArg;

    case ("from", true)
      equation
        namedArg = List.getMemberOnTrue("from", nargs, elabBuiltinTransition3);
      then elabBuiltinTransition4(namedArg);
    case ("from", false)
      then listHead(args);
    case ("to", true)
      equation
        namedArg = List.getMemberOnTrue("to", nargs, elabBuiltinTransition3);
      then elabBuiltinTransition4(namedArg);
    case ("to", false)
      then listGet(args, 2);
  end match;
end elabBuiltinTransition5;

protected function elabBuiltinInitialState "
Author: BTH
This function elaborates the builtin operator
initialState(state)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call,state;
      DAE.Type ty1,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1,prop;
      Absyn.Exp astate;
      String strMsg, strPre;

    case (cache,env,{astate},{},impl,pre,_)
      equation
        (cache,_, prop1, _) = elabExpInExpression(cache,env,astate,impl,NONE(),true,pre,info);
        ty1 = Types.getPropType(prop1);
        strMsg = "initialState(" + Dump.printExpLstStr(args) + "), Argument needs to be a block instance.";
        strPre = PrefixUtil.printPrefixStr3(pre);
        Error.assertionOrAddSourceMessage(isBlockTypeWorkaround(ty1),Error.WRONG_TYPE_OR_NO_OF_ARGS,
          {strMsg, strPre}, info);

        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("state",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                 DAE.T_NORETCALL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("initialState"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinInitialState;

protected function elabBuiltinActiveState "
Author: BTH
This function elaborates the builtin operator
activeState(state)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call,state;
      DAE.Type ty1,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1,prop;
      Absyn.Exp astate;
      String strMsg, strPre;

    case (cache,env,{astate},{},impl,pre,_)
      equation
        (cache,_, prop1, _) = elabExpInExpression(cache,env,astate,impl,NONE(),true,pre,info);
        ty1 = Types.getPropType(prop1);
        strMsg = "activeState(" + Dump.printExpLstStr(args) + "), Argument needs to be a block instance.";
        strPre = PrefixUtil.printPrefixStr3(pre);
        Error.assertionOrAddSourceMessage(isBlockTypeWorkaround(ty1), Error.WRONG_TYPE_OR_NO_OF_ARGS,
          {strMsg, strPre}, info);

        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("state",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                 DAE.T_BOOL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("activeState"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinActiveState;

protected function elabBuiltinTicksInState "
Author: BTH
This function elaborates the builtin operator
ticksInState()."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call;
      DAE.Type ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop;

    case (cache,env,{},{},impl,pre,_)
      equation
        ty =  DAE.T_FUNCTION(
                {},
                 DAE.T_INTEGER_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("ticksInState"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinTicksInState;

protected function elabBuiltinTimeInState "
Author: BTH
This function elaborates the builtin operator
timeInState()."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call;
      DAE.Type ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop;

    case (cache,env,{},{},impl,pre,_)
      equation
        ty =  DAE.T_FUNCTION(
                {},
                 DAE.T_REAL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("timeInState"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinTimeInState;

protected function elabBuiltinBoolean
  "This function elaborates on the builtin operator boolean, which extracts
   the boolean value of a Real, Integer or Boolean value."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache, outExp, outProperties) := verifyBuiltInHandlerType(inCache, inEnv,
    inPosArgs, inImplicit, Types.isIntegerOrRealOrBooleanOrSubTypeOfEither,
      "boolean", inPrefix, inInfo);
end elabBuiltinBoolean;

protected function elabBuiltinIntegerEnum
"This function elaborates on the builtin operator Integer for Enumerations, which extracts
  the Integer value of a Enumeration element."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache, outExp, outProperties) := verifyBuiltInHandlerType(inCache, inEnv,
    inPosArgs, inImplicit, Types.isEnumeration, "Integer", inPrefix, inInfo);
end elabBuiltinIntegerEnum;

protected function elabBuiltinDiagonal "This function elaborates on the builtin operator diagonal, creating a
  matrix with a value of the diagonal. The other elements are zero."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  DAE.Exp exp;
  list<DAE.Exp> expl;
  DAE.Properties prop;
  DAE.Dimension dim;
  DAE.Type arr_ty, ty;
  DAE.Const c;
algorithm
  (outCache, exp, prop) := elabExpInExpression(inCache, inEnv,
    listHead(inPosArgs), inImplicit, NONE(), true, inPrefix, inInfo);
  DAE.PROP(DAE.T_ARRAY(dims = {dim}, ty = arr_ty), c) := prop;

  ty := DAE.T_ARRAY(DAE.T_ARRAY(arr_ty, {dim}, DAE.emptyTypeSource), {dim}, DAE.emptyTypeSource);
  outProperties := DAE.PROP(ty, c);
  ty := Types.simplifyType(ty);

  outExp := Expression.makePureBuiltinCall("diagonal", {exp}, ty);
end elabBuiltinDiagonal;

protected function elabBuiltinSimplify "This function elaborates the simplify function.
  The call in mosh is: simplify(x+yx-x,\"Real\") if the variable should be
  Real or simplify(x+yx-x,\"Integer\") if the variable should be Integer
  This function is only for testing ExpressionSimplify.simplify"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  Absyn.Exp e;
  String ty_str;
  list<Absyn.ComponentRef> crefs;
  GlobalScript.SymbolTable symbol_table;
  FCore.Graph env;
  DAE.Type ty;
algorithm
  checkBuiltinCallArgs(inPosArgs, inNamedArgs, 2, "simplify", inInfo);

  {e, Absyn.STRING(value = ty_str)} := inPosArgs;

  if ty_str == "Real" then
    ty := DAE.T_REAL_DEFAULT;
  elseif ty_str == "Integer" then
    ty := DAE.T_INTEGER_DEFAULT;
  else
    Error.addInternalError("Invalid type " + ty_str + " given to simplify", inInfo);
  end if;

  crefs := Absyn.getCrefFromExp(e, true, false);
  symbol_table := absynCrefListToInteractiveVarList(crefs, GlobalScript.emptySymboltable, ty);
  env := GlobalScriptUtil.buildEnvFromSymboltable(symbol_table);
  (outCache, outExp, outProperties) := elabExpInExpression(inCache, env, e,
      inImplicit, NONE(), true, inPrefix, inInfo);
  outExp := Expression.makePureBuiltinCall("simplify", {outExp}, ty);
end elabBuiltinSimplify;

protected function absynCrefListToInteractiveVarList "
  Creates Interactive variables from the list of component references. Each
  variable will get a value that is the AST code for the variable itself.
  This is used when calling differentiate, etc., to be able to evaluate
  a variable and still get the variable name.
"
  input list<Absyn.ComponentRef> inCrefs;
  input GlobalScript.SymbolTable inST;
  input DAE.Type inType;
  output GlobalScript.SymbolTable outST = inST;
protected
  String path_str;
algorithm
  for cr in inCrefs loop
    path_str := Absyn.pathString(Absyn.crefToPath(cr));
    outST := GlobalScriptUtil.addVarToSymboltable(
      DAE.CREF_IDENT(path_str, inType, {}),
      Values.CODE(Absyn.C_VARIABLENAME(cr)), FGraph.empty(), outST);
  end for;
end absynCrefListToInteractiveVarList;

protected function elabBuiltinNoevent
  "The builtin operator noEvent makes sure that events are not generated for the
   expression."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  Absyn.Exp e;
algorithm
  checkBuiltinCallArgs(inPosArgs, inNamedArgs, 1, "noEvent", inInfo);

  e := listHead(inPosArgs);
  (outCache, outExp, outProperties) := elabExpInExpression(inCache, inEnv, e,
      inImplicit, NONE(), true, inPrefix, inInfo);
  outExp := Expression.makePureBuiltinCall("noEvent", {outExp}, DAE.T_BOOL_DEFAULT);
end elabBuiltinNoevent;

protected function elabBuiltinEdge
  "This function handles the built in edge operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  DAE.Type ty;
  DAE.Const c;
  String msg;
algorithm
  checkBuiltinCallArgs(inPosArgs, inNamedArgs, 1, "edge", inInfo);

  (outCache, outExp, outProperties) := elabExpInExpression(inCache, inEnv,
      listHead(inPosArgs), inImplicit, NONE(), true, inPrefix, inInfo);
  DAE.PROP(ty, c) := outProperties;

  // Print an error if the argument is not a Boolean.
  if not Types.isScalarBoolean(ty) then
    msg := "edge(" + ExpressionDump.printExpStr(outExp) + ")";
    Error.addSourceMessageAndFail(Error.TYPE_ERROR, {msg}, inInfo);
  end if;

  // If the argument is a variable, make a call to edge. Otherwise the
  // expression is false.
  if Types.isVar(c) then
    outExp := Expression.makePureBuiltinCall("edge", {outExp}, DAE.T_BOOL_DEFAULT);
  else
    outExp := DAE.BCONST(false);
  end if;
end elabBuiltinEdge;

protected function elabBuiltinDer
  "This function handles the built in der operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  DAE.Type ty;
  DAE.Const c;
  list<DAE.Dimension> dims;
  String exp_str, ty_str;
algorithm
  if FGraph.inFunctionScope(inEnv) then
    Error.addSourceMessageAndFail(Error.DERIVATIVE_FUNCTION_CONTEXT, {}, inInfo);
  end if;

  checkBuiltinCallArgs(inPosArgs, inNamedArgs, 1, "der", inInfo);

  (outCache, outExp, outProperties) := elabExpInExpression(inCache, inEnv,
      listHead(inPosArgs), inImplicit, NONE(), true, inPrefix, inInfo);
  DAE.PROP(ty, c) := outProperties;

  // Make sure the argument's type is a subtype of Real.
  if not Types.isRealOrSubTypeReal(Types.arrayElementType(ty)) then
    exp_str := Dump.printExpStr(listHead(inPosArgs));
    ty_str := Types.unparseTypeNoAttr(ty);
    Error.addSourceMessageAndFail(Error.DERIVATIVE_NON_REAL,
      {exp_str, ty_str}, inInfo);
  end if;

  if Types.isVar(c) then
    if Types.dimensionsKnown(ty) then
      // Use elabCallArgs to handle vectorization if possible.
      (outCache, outExp, outProperties) := elabCallArgs(inCache, inEnv,
          Absyn.IDENT("der"), inPosArgs, {}, inImplicit, NONE(), inPrefix, inInfo);
    else
      // Otherwise just create a call to der.
      outExp := Expression.makePureBuiltinCall("der", {outExp},
          Types.simplifyType(ty));
    end if;
  else
    // der(constant) = 0.
    dims := Types.getDimensions(ty);
    (outExp, ty) := Expression.makeZeroExpression(dims);
    outProperties := DAE.PROP(ty, DAE.C_CONST());
  end if;
end elabBuiltinDer;

protected function elabBuiltinChange
  "This function handles the built in change operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  Absyn.Exp e;
  String pre_str;
  DAE.Type ty;
  DAE.Const c;
  DAE.Attributes attr;
  DAE.ComponentRef cref;
  SCode.Variability var;
algorithm
  checkBuiltinCallArgs(inPosArgs, inNamedArgs, 1, "change", inInfo);

  e := listHead(inPosArgs);

  // Check that the argument is a variable (i.e. a component reference).
  if not Absyn.isCref(e) then
    pre_str := PrefixUtil.printPrefixStr3(inPrefix);
    Error.addSourceMessageAndFail(Error.ARGUMENT_MUST_BE_VARIABLE,
      {"First", "change", pre_str}, inInfo);
  end if;

  (outCache, outExp, outProperties) := elabExpInExpression(inCache, inEnv, e,
      inImplicit, NONE(), true, inPrefix, inInfo);
  DAE.PROP(ty, c) := outProperties;

  if Types.isSimpleType(ty) then
    if Types.isParameterOrConstant(c) then
      // change(constant) = false
      outExp := DAE.BCONST(false);
      outProperties := DAE.PROP(DAE.T_BOOL_DEFAULT, DAE.C_CONST());
    elseif Types.isDiscreteType(ty) then
      // If the argument is discrete, make a call to change.
      outExp := Expression.makePureBuiltinCall("change", {outExp}, DAE.T_BOOL_DEFAULT);
      outProperties := DAE.PROP(DAE.T_BOOL_DEFAULT, DAE.C_VAR());
    else
      // Workaround for discrete Reals. Does not handle Reals that become
      // discrete due to when-section.
      cref := Expression.getCrefFromCrefOrAsub(outExp);
      // Look up the component's variability.
      (outCache, attr) := Lookup.lookupVar(outCache, inEnv, cref);
      DAE.ATTR(variability = var) := attr;

      if valueEq(var, SCode.DISCRETE()) then
        // If it's discrete, make a call to change.
        outExp := Expression.makePureBuiltinCall("change", {outExp}, DAE.T_BOOL_DEFAULT);
        outProperties := DAE.PROP(DAE.T_BOOL_DEFAULT, DAE.C_VAR());
      else
        // Otherwise, print an error and fail.
        pre_str := PrefixUtil.printPrefixStr3(inPrefix);
        Error.addSourceMessageAndFail(Error.ARGUMENT_MUST_BE_DISCRETE_VAR,
          {"First", "change", pre_str}, inInfo);
      end if;
    end if;
  else
    // If the argument does not have a simple type, print an error and fail.
    pre_str := PrefixUtil.printPrefixStr3(inPrefix);
    Error.addSourceMessageAndFail(Error.TYPE_MUST_BE_SIMPLE,
      {"operand to change", pre_str}, inInfo);
  end if;
end elabBuiltinChange;

protected function elabBuiltinCat
  "This function handles the built in cat operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  DAE.Exp dim_exp;
  DAE.Properties dim_props;
  DAE.Type dim_ty, ty, result_ty;
  DAE.Const dim_c, arr_c, c;
  String pre_str, exp_str;
  Integer dim_int;
  list<DAE.Exp> arr_expl;
  list<DAE.Properties> arr_props;
  list<DAE.Type> arr_tys, tys;
  list<DAE.Dimension> dims;
  DAE.Dimension dim;
algorithm
  if listLength(inPosArgs) < 2 or not listEmpty(inNamedArgs) then
    Error.addSourceMessageAndFail(Error.WRONG_NO_OF_ARGS, {"cat"}, inInfo);
  end if;

  // Elaborate the first argument, the dimension to concatenate along.
  (outCache, dim_exp, dim_props) := elabExpInExpression(inCache, inEnv,
      listHead(inPosArgs), inImplicit, NONE(), true, inPrefix, inInfo);
  DAE.PROP(dim_ty, dim_c) := dim_props;

  // The first argument must be an integer.
  if not Types.isScalarInteger(dim_ty) then
    pre_str := PrefixUtil.printPrefixStr3(inPrefix);
    Error.addSourceMessageAndFail(Error.ARGUMENT_MUST_BE_INTEGER,
      {"First", "cat", pre_str}, inInfo);
  end if;

  // Evaluate the first argument.
  (outCache, Values.INTEGER(dim_int), _) :=
    Ceval.ceval(inCache, inEnv, dim_exp, false, NONE(), Absyn.MSG(inInfo));

  // Elaborate the rest of the arguments, the arrays to concatenate.
  (outCache, arr_expl, arr_props) := elabExpList(outCache, inEnv,
      listRest(inPosArgs), inImplicit, NONE(), true, inPrefix, inInfo);

  // Type check the arguments and check that all dimensions except the one we
  // will concatenate along is equal.
  arr_tys := list(Types.getPropType(p) for p in arr_props);
  ty :: tys := list(Types.makeNthDimUnknown(t, dim_int) for t in arr_tys);
  result_ty := List.fold1(tys, Types.arraySuperType, inInfo, ty);

  try
    (arr_expl, arr_tys) := Types.matchTypes(arr_expl, arr_tys, result_ty, false);
  else
    // Mismatched types, print an error and fail.
    exp_str := stringDelimitList(list(Dump.printExpStr(e) for e in inPosArgs), ", ");
    exp_str := "cat(" + exp_str + ")";
    pre_str := PrefixUtil.printPrefixStr3(inPrefix);
    Error.addSourceMessageAndFail(Error.DIFFERENT_DIM_SIZE_IN_ARGUMENTS,
      {exp_str, pre_str}, inInfo);
  end try;

  // Calculate the size of the concatenated dimension, and insert it in the
  // result type.
  dims := list(Types.getDimensionNth(t, dim_int) for t in arr_tys);
  dim := Expression.dimensionsAdd(d for d in dims);
  result_ty := Types.setDimensionNth(result_ty, dim, dim_int);

  // Construct a call to cat.
  arr_c := elabArrayConst(arr_props);
  c := Types.constAnd(dim_c, arr_c);
  ty := Types.simplifyType(result_ty);
  outExp := Expression.makePureBuiltinCall("cat", dim_exp :: arr_expl, ty);
  outProperties := DAE.PROP(result_ty, c);
end elabBuiltinCat;

protected function elabBuiltinIdentity
  "This function handles the built in identity operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  DAE.Type ty, exp_ty;
  DAE.Const c;
  String pre_str;
  Absyn.Msg msg;
  Integer sz;
  DAE.Dimension dim_size;
  DAE.Exp dim_exp;
  Boolean check_model;
algorithm
  checkBuiltinCallArgs(inPosArgs, inNamedArgs, 1, "identity", inInfo);

  (outCache, dim_exp, outProperties) := elabExpInExpression(inCache, inEnv,
      listHead(inPosArgs), inImplicit, NONE(), true, inPrefix, inInfo);
  DAE.PROP(ty, c) := outProperties;

  // Check that the argument is an Integer.
  if not Types.isScalarInteger(ty) then
    pre_str := PrefixUtil.printPrefixStr3(inPrefix);
    Error.addSourceMessageAndFail(Error.ARGUMENT_MUST_BE_INTEGER,
      {"First", "identity", pre_str}, inInfo);
  end if;

  if Types.isParameterOrConstant(c) then
    // If the argument is a parameter or constant, evaluate it.
    check_model := Flags.getConfigBool(Flags.CHECK_MODEL);
    msg := if check_model then Absyn.NO_MSG() else Absyn.MSG(inInfo);

    try
      (outCache, Values.INTEGER(sz), _) :=
        Ceval.ceval(outCache, inEnv, dim_exp, false, NONE(), msg);
      dim_size := DAE.DIM_INTEGER(sz);
      dim_exp := DAE.ICONST(sz);
    else
      // Allow evaluation to fail if checkModel is used.
      if check_model then dim_size := DAE.DIM_UNKNOWN(); else fail(); end if;
    end try;
  else
    dim_size := DAE.DIM_UNKNOWN();
  end if;

  ty := Types.liftArrayListDims(DAE.T_INTEGER_DEFAULT, {dim_size, dim_size});
  exp_ty := Types.simplifyType(ty);
  outExp := Expression.makePureBuiltinCall("identity", {dim_exp}, exp_ty);
  outProperties := DAE.PROP(ty, c);
end elabBuiltinIdentity;

protected function zeroSizeOverconstrainedOperator
  input DAE.Exp inExp;
  input DAE.Exp inFExp;
  input SourceInfo inInfo;
algorithm
  _ := match inExp
    local String s;

    case DAE.ARRAY(array = {})
      equation
        s = ExpressionDump.printExpStr(inFExp);
        Error.addSourceMessage(Error.OVERCONSTRAINED_OPERATOR_SIZE_ZERO_RETURN_FALSE, {s}, inInfo);
      then
        ();

    else ();

  end match;
end zeroSizeOverconstrainedOperator;

protected function elabBuiltinIsRoot
"This function elaborates on the builtin operator Connections.isRoot."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  DAE.Exp exp;
algorithm
  checkBuiltinCallArgs(inPosArgs, inNamedArgs, 1, "Connections.isRoot", inInfo);

  (outCache, exp) := elabExpInExpression(inCache, inEnv, listHead(inPosArgs),
      false, NONE(), false, inPrefix, inInfo);
  outExp := DAE.CALL(Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")),
      {exp}, DAE.callAttrBuiltinBool);
  outProperties := DAE.PROP(DAE.T_BOOL_DEFAULT, DAE.C_VAR());

  zeroSizeOverconstrainedOperator(exp, outExp, inInfo);
end elabBuiltinIsRoot;

protected function elabBuiltinRooted
"author: adrpo
  This function handles the built-in rooted operator. (MultiBody).
  See more here: http://trac.modelica.org/Modelica/ticket/95"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  DAE.Exp exp;
algorithm
  // this operator is not even specified in the specification!
  // see: http://trac.modelica.org/Modelica/ticket/95
  checkBuiltinCallArgs(inPosArgs, inNamedArgs, 1, "rooted", inInfo);

  (outCache, exp) := elabExpInExpression(inCache, inEnv, listHead(inPosArgs),
      false, NONE(), false, inPrefix, inInfo);
  outExp := DAE.CALL(Absyn.IDENT("rooted"), {exp}, DAE.callAttrBuiltinBool);
  outProperties := DAE.PROP(DAE.T_BOOL_DEFAULT, DAE.C_VAR());

  zeroSizeOverconstrainedOperator(exp, outExp, inInfo);
end elabBuiltinRooted;

protected function elabBuiltinUniqueRootIndices
"This function elaborates on the builtin operator Connections.uniqueRootIndices.
 TODO: assert size(second arg) <= size(first arg)
 See Modelica_StateGraph2:
  https://github.com/modelica/Modelica_StateGraph2
  and
  https://trac.modelica.org/Modelica/ticket/984
  and
  http://www.ep.liu.se/ecp/043/041/ecp09430108.pdf
 for a specification of this operator"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      FCore.Graph env;
      FCore.Cache cache;
      Boolean impl;
      Absyn.Exp aexp1, aexp2, aexp3;
      DAE.Exp exp1, exp2, exp3;
      Prefix.Prefix pre;
      DAE.Dimensions dims;
      DAE.Properties props;
      list<DAE.Exp> lst;
      Integer dim;
      DAE.Type ty;

    case (cache,env,{aexp1,aexp2},{},_,pre,_)
      equation
        (cache,exp1 as DAE.ARRAY(array = lst),_,_) = elabExpInExpression(cache, env, aexp1, false, NONE(), false, pre, info);
        dim = listLength(lst);
        (cache,exp2,_,_) = elabExpInExpression(cache, env, aexp2, false, NONE(), false, pre, info);
        exp3 = DAE.SCONST("");
        ty = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(dim)}, DAE.emptyTypeSource);
      then
        (cache,
        DAE.CALL(Absyn.QUALIFIED("Connections", Absyn.IDENT("uniqueRootIndices")), {exp1, exp2, exp3},
                 DAE.CALL_ATTR(ty,false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL())),
        DAE.PROP(ty, DAE.C_VAR()));

    case (cache,env,{aexp1,aexp2,_},{},_,pre,_)
      equation
        (cache,exp1 as DAE.ARRAY(array = lst),_,_) = elabExpInExpression(cache, env, aexp1, false, NONE(), false, pre, info);
        dim = listLength(lst);
        (cache,exp2,_,_) = elabExpInExpression(cache, env, aexp2, false, NONE(), false, pre, info);
        (cache,exp3,_,_) = elabExpInExpression(cache, env, aexp2, false, NONE(), false, pre, info);
        ty = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(dim)}, DAE.emptyTypeSource);
      then
        (cache,
        DAE.CALL(Absyn.QUALIFIED("Connections", Absyn.IDENT("uniqueRootIndices")), {exp1, exp2, exp3},
                 DAE.CALL_ATTR(ty,false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL())),
        DAE.PROP(ty, DAE.C_VAR()));

    case (cache,env,{aexp1,aexp2},{Absyn.NAMEDARG("message", _)},_,pre,_)
      equation
        (cache,exp1 as DAE.ARRAY(array = lst),_,_) = elabExpInExpression(cache, env, aexp1, false, NONE(), false, pre, info);
        dim = listLength(lst);
        (cache,exp2,_,_) = elabExpInExpression(cache, env, aexp2, false,NONE(), false,pre,info);
        (cache,exp3,_,_) = elabExpInExpression(cache, env, aexp2, false,NONE(), false,pre,info);
        ty = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(dim)}, DAE.emptyTypeSource);
      then
        (cache,
        DAE.CALL(Absyn.QUALIFIED("Connections", Absyn.IDENT("uniqueRootIndices")), {exp1, exp2, exp3},
                 DAE.CALL_ATTR(ty,false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL())),
        DAE.PROP(ty, DAE.C_VAR()));

  end match;
end elabBuiltinUniqueRootIndices;

protected function elabBuiltinScalar
  "This function handles the built in scalar operator.
   For example, scalar({1}) => 1 or scalar({a}) => a"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  DAE.Type ty, scalar_ty;
  DAE.Const c;
  list<DAE.Dimension> dims;
  String ty_str;
algorithm
  checkBuiltinCallArgs(inPosArgs, inNamedArgs, 1, "scalar", inInfo);

  (outCache, outExp, DAE.PROP(ty, c), _) := elabExpInExpression(inCache, inEnv,
    listHead(inPosArgs), inImplicit, NONE(), true, inPrefix, inInfo);

  (scalar_ty, dims) := Types.flattenArrayTypeOpt(ty);

  // Check that any known dimensions have size 1.
  for dim in dims loop
    if Expression.dimensionKnown(dim) and Expression.dimensionSize(dim) <> 1 then
      ty_str := Types.unparseTypeNoAttr(ty);
      Error.addSourceMessageAndFail(Error.INVALID_ARRAY_DIM_IN_CONVERSION_OP,
        {ty_str}, inInfo);
    end if;
  end for;

  // If the argument is an array, make a call to scalar. Otherwise the
  // expression is already a scalar, so return it as it is.
  if not listEmpty(dims) then
    outExp := Expression.makePureBuiltinCall("scalar", {outExp}, scalar_ty);
  end if;

  outExp := ExpressionSimplify.simplify1(outExp);
  outProperties := DAE.PROP(scalar_ty, c);
end elabBuiltinScalar;

constant Slot STRING_ARG_MINLENGTH = SLOT(DAE.FUNCARG("minimumLength",
  DAE.T_INTEGER_DEFAULT, DAE.C_VAR(), DAE.NON_PARALLEL(), NONE()), false,
  SOME(DAE.ICONST(0)), {}, 2, SLOT_NOT_EVALUATED);

constant Slot STRING_ARG_LEFTJUSTIFIED = SLOT(DAE.FUNCARG("leftJustified",
  DAE.T_BOOL_DEFAULT, DAE.C_VAR(), DAE.NON_PARALLEL(), NONE()), false,
  SOME(DAE.BCONST(true)), {}, 3, SLOT_NOT_EVALUATED);

constant Slot STRING_ARG_SIGNIFICANT_DIGITS = SLOT(DAE.FUNCARG("significantDigits",
  DAE.T_INTEGER_DEFAULT, DAE.C_VAR(), DAE.NON_PARALLEL(), NONE()), false,
  SOME(DAE.ICONST(6)), {}, 4, SLOT_NOT_EVALUATED);

protected function elabBuiltinString "
  author: PA
  This function handles the built-in String operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  Absyn.Exp e;
  DAE.Exp exp;
  DAE.Type ty;
  DAE.Const c;
  list<DAE.Exp> args;
  list<DAE.Const> consts;
  Slot val_slot, format_slot;
  Option<DAE.Exp> format_arg = NONE();
  list<Slot> slots;
algorithm
  try
    // Check if 'String' is overloaded.
    e := Absyn.CALL(Absyn.CREF_IDENT("String", {}),
        Absyn.FUNCTIONARGS(inPosArgs, inNamedArgs));
    (outCache, outExp, outProperties) := OperatorOverloading.string(inCache,
        inEnv, e, inImplicit, NONE(), true, inPrefix, inInfo);
  else
    // Elaborate the first argument so we know what type we're dealing with.
    e := listHead(inPosArgs);
    (outCache, exp, DAE.PROP(ty, c), _) :=
      elabExpInExpression(inCache, inEnv, e, inImplicit, NONE(), true, inPrefix, inInfo);
    val_slot := SLOT(DAE.FUNCARG("x", ty, DAE.C_VAR(), DAE.NON_PARALLEL(),
      NONE()), false, NONE(), {}, 1, SLOT_NOT_EVALUATED);

    try
      // Try the String(val, <option>) format.
      slots := {val_slot, STRING_ARG_MINLENGTH, STRING_ARG_LEFTJUSTIFIED};

      // Only String(Real) has the significantDigits option.
      if Types.isRealOrSubTypeReal(ty) then
        slots := listAppend(slots, {STRING_ARG_SIGNIFICANT_DIGITS});
      end if;

      (outCache, args, _, consts) := elabInputArgs(outCache, inEnv, inPosArgs, inNamedArgs,
          slots, false, true, inImplicit, NOT_EXTERNAL_OBJECT_MODEL_SCOPE(),
          NONE(), inPrefix, inInfo, DAE.T_UNKNOWN_DEFAULT, Absyn.IDENT("String"));
    else
      // Try the String(val, format = s) format.
      if Types.isRealOrSubTypeReal(ty) then
        format_arg := SOME(DAE.SCONST("f"));
      elseif Types.isIntegerOrSubTypeInteger(ty) then
        format_arg := SOME(DAE.SCONST("d"));
      elseif Types.isString(ty) then
        format_arg := SOME(DAE.SCONST("s"));
      else
        format_arg := NONE();
      end if;

      if isSome(format_arg) then
        slots := {val_slot, SLOT(DAE.FUNCARG("format", DAE.T_STRING_DEFAULT, DAE.C_VAR(),
              DAE.NON_PARALLEL(), NONE()), false, format_arg, {}, 2,
              SLOT_NOT_EVALUATED)};
      else
        slots := {val_slot};
      end if;

      (outCache, args, _, consts) := elabInputArgs(outCache, inEnv, inPosArgs, inNamedArgs,
          slots, false, true, inImplicit, NOT_EXTERNAL_OBJECT_MODEL_SCOPE(),
          NONE(), inPrefix, inInfo, DAE.T_UNKNOWN_DEFAULT, Absyn.IDENT("String"));
    end try;

    c := List.fold(consts, Types.constAnd, DAE.C_CONST());
    outExp := Expression.makePureBuiltinCall("String", args, DAE.T_STRING_DEFAULT);
    outProperties := DAE.PROP(DAE.T_STRING_DEFAULT, c);
  end try;
end elabBuiltinString;

protected function elabBuiltinGetInstanceName
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  String str;
  Absyn.Path name, envName;
algorithm
  checkBuiltinCallArgs(inPosArgs, inNamedArgs, 0, "getInstanceName", inInfo);

  FCore.CACHE(modelName = name) := inCache;

  if PrefixUtil.isNoPrefix(inPrefix) then
    envName := FGraph.getGraphNameNoImplicitScopes(inEnv);
    str := if Absyn.pathEqual(envName, name) then
      Absyn.pathLastIdent(name) else Absyn.pathString(envName);
  else
    str := Absyn.pathLastIdent(name) + "." + PrefixUtil.printPrefixStr(inPrefix);
  end if;

  outExp := DAE.SCONST(str);
  outProperties := DAE.PROP(DAE.T_STRING_DEFAULT, DAE.C_CONST());
end elabBuiltinGetInstanceName;

protected function elabBuiltinVector
  "This function handles the built in vector operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  Absyn.Exp e;
  DAE.Type ty, arr_ty, exp_ty, el_ty;
  DAE.Const c;
  list<DAE.Exp> expl;
algorithm
  checkBuiltinCallArgs(inPosArgs, inNamedArgs, 1, "vector", inInfo);

  e := listHead(inPosArgs);
  (outCache, outExp, outProperties as DAE.PROP(ty, c), _) :=
    elabExpInExpression(inCache, inEnv, e, inImplicit, NONE(), true, inPrefix, inInfo);

  // Scalar
  if Types.isSimpleType(ty) then
    // vector(scalar) = {scalar}
    arr_ty := Types.liftArray(ty, DAE.DIM_INTEGER(1));
    exp_ty := Types.simplifyType(arr_ty);
    outExp := DAE.ARRAY(exp_ty, true, {outExp});
    outProperties := DAE.PROP(arr_ty, c);
  // Array or Matrix
  elseif Expression.isArray(outExp) or Expression.isMatrix(outExp) then
    // If the array/matrix has more than one dimension, flatten it into a one-
    // dimensional array. Otherwise, do nothing and return the expression as is.
    if Types.numberOfDimensions(ty) <> 1 then
      checkBuiltinVectorDims(e, inEnv, ty, inPrefix, inInfo);
      expl := Expression.getArrayOrMatrixContents(outExp);
      expl := flattenArray(expl);

      el_ty := Types.arrayElementType(ty);
      arr_ty := Types.liftArray(el_ty, DAE.DIM_INTEGER(listLength(expl)));

      outExp := DAE.ARRAY(Types.simplifyType(arr_ty), false, expl);
      outProperties := DAE.PROP(arr_ty, c);
    end if;
  // Anything else
  else
    // For any other type of expression, make a call to vector.
    ty := Types.liftArray(Types.arrayElementType(ty), DAE.DIM_UNKNOWN());
    exp_ty := Types.simplifyType(ty);
    outExp := Expression.makePureBuiltinCall("vector", {outExp}, exp_ty);
    outProperties := DAE.PROP(ty, c);
  end if;
end elabBuiltinVector;

protected function checkBuiltinVectorDims
  "Checks that the argument to vector has at most one dimension which is larger
   than one, otherwise prints an error and fails."
  input Absyn.Exp inExp;
  input FCore.Graph inEnv;
  input DAE.Type inType;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
protected
  Boolean found_dim_sz_one = false;
  list<Integer> dims;
  String arg_str, scope_str, dim_str, pre_str;
algorithm
  dims := Types.getDimensionSizes(inType);

  for dim in dims loop
    if dim > 1 then
      if found_dim_sz_one then
        scope_str := FGraph.printGraphPathStr(inEnv);
        arg_str := "vector(" + Dump.printExpStr(inExp) + ")";
        dim_str := "[" + stringDelimitList(list(intString(d) for d in dims), ", ") + "]";
        pre_str := PrefixUtil.printPrefixStr3(inPrefix);
        Error.addSourceMessageAndFail(Error.BUILTIN_VECTOR_INVALID_DIMENSIONS,
          {scope_str, pre_str, dim_str, arg_str}, inInfo);
      else
        found_dim_sz_one := true;
      end if;
    end if;
  end for;
end checkBuiltinVectorDims;

protected function flattenArray
  input list<DAE.Exp> arr;
  output list<DAE.Exp> flattenedExpl;
algorithm
  flattenedExpl := match(arr)
    local
      DAE.Exp e;
      list<DAE.Exp> expl, expl2, rest_expl;

    case ({}) then {};

    case ((DAE.ARRAY(array = expl) :: rest_expl))
      equation
        expl = flattenArray(expl);
        expl2 = flattenArray(rest_expl);
        expl = listAppend(expl, expl2);
      then expl;

    case ((DAE.MATRIX(matrix = {{e}}) :: rest_expl))
      equation
        expl = flattenArray(rest_expl);
      then
        (e :: expl);

    case ((e :: expl))
      equation
        expl = flattenArray(expl);
      then
        (e :: expl);
  end match;
end flattenArray;

public function elabBuiltinMatrix
  "Elaborates the builtin matrix function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  DAE.Type ty;
algorithm
  checkBuiltinCallArgs(inPosArgs, inNamedArgs, 1, "matrix", inInfo);

  (outCache, outExp, outProperties) := elabExpInExpression(inCache, inEnv,
      listHead(inPosArgs), inImpl, NONE(), true, inPrefix, inInfo);
  ty := Types.getPropType(outProperties);
  (outExp, outProperties) := elabBuiltinMatrix2(inCache, inEnv, outExp,
      outProperties, ty, inInfo);
end elabBuiltinMatrix;

protected function elabBuiltinMatrix2
  "Helper function to elabBuiltinMatrix, evaluates the matrix function given the
   elaborated argument."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inArg;
  input DAE.Properties inProperties;
  input DAE.Type inType;
  input SourceInfo inInfo;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outExp, outProperties) := match inArg
    local
      DAE.Type ty;
      DAE.Exp exp;
      DAE.Properties props;
      list<DAE.Exp> expl;
      DAE.Type ety;
      DAE.Dimension dim1, dim2;
      Boolean scalar;
      DAE.TypeSource ts;

    // Scalar
    case _ guard(Types.isSimpleType(inType))
      algorithm
        (exp, props) := promoteExp(inArg, inProperties, 2);
      then
        (exp, props);

    // 1-dimensional array
    case _ guard(Types.numberOfDimensions(inType) == 1)
      algorithm
        (exp, props) := promoteExp(inArg, inProperties, 2);
      then
        (exp, props);

    // Matrix
    case DAE.MATRIX()
      then (inArg, inProperties);

    // n-dimensional array
    case DAE.ARRAY(ty = DAE.T_ARRAY(ety, dim1 :: dim2 :: _, ts), scalar = scalar, array = expl)
      algorithm
        expl := List.map1(expl, elabBuiltinMatrix3, inInfo);
        ty := Types.arrayElementType(inType);
        ty := Types.liftArrayListDims(ty, {dim1, dim2});
        props := Types.setPropType(inProperties, ty);
      then
        (DAE.ARRAY(DAE.T_ARRAY(ety, {dim1, dim2}, ts), scalar, expl), props);

  end match;
end elabBuiltinMatrix2;

protected function elabBuiltinMatrix3
  "Helper function to elabBuiltinMatrix2."
  input DAE.Exp inExp;
  input SourceInfo inInfo;
  output DAE.Exp outExp;
algorithm
  outExp := match inExp
    local
      DAE.Type ety, ety2;
      Boolean scalar;
      list<DAE.Exp> expl;
      DAE.Dimension dim;
      DAE.Dimensions dims;
      list<list<DAE.Exp>> matrix_expl;
      DAE.TypeSource ts;

    case DAE.ARRAY(ty = DAE.T_ARRAY(ety, dim :: _, ts),scalar = scalar, array = expl)
      algorithm
        expl := list(arrayScalar(e, 3, "matrix", inInfo) for e in expl);
      then
        DAE.ARRAY(DAE.T_ARRAY(ety, {dim}, ts), scalar, expl);

    case DAE.MATRIX(ty = DAE.T_ARRAY(ety, dim :: dims, ts), matrix = matrix_expl)
      algorithm
        ety2 := DAE.T_ARRAY(ety, dims, ts);
        expl := list(Expression.makeArray(e, ety2, true) for e in matrix_expl);
        expl := list(arrayScalar(e, 3, "matrix", inInfo) for e in expl);
      then
        DAE.ARRAY(DAE.T_ARRAY(ety, {dim}, ts), true, expl);

  end match;
end elabBuiltinMatrix3;

protected function arrayScalar
  "Returns the scalar value of an array, or prints an error message and fails if
   any dimension of the array isn't of size 1."
  input DAE.Exp inExp;
  input Integer inDim "The current dimension, used for error message.";
  input String inOperator "The current operator name, used for error message.";
  input SourceInfo inInfo;
  output DAE.Exp outExp;
algorithm
  outExp := match inExp
    local
      DAE.Exp exp;
      DAE.Type ty;
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> mexpl;
      String dim_str, size_str;

    // An array with one element.
    case DAE.ARRAY(array = {exp})
      then arrayScalar(exp, inDim + 1, inOperator, inInfo);

    // Any other array.
    case DAE.ARRAY(array = expl)
      algorithm
        dim_str := intString(inDim);
        size_str := intString(listLength(expl));
        Error.addSourceMessage(Error.INVALID_ARRAY_DIM_IN_CONVERSION_OP,
          {dim_str, inOperator, "1", size_str}, inInfo);
      then
        fail();

    // A matrix where the first dimension is 1.
    case DAE.MATRIX(ty = ty, matrix = {expl})
      then arrayScalar(DAE.ARRAY(ty, true, expl), inDim + 1, inOperator, inInfo);

    // Any other matrix.
    case DAE.MATRIX(matrix = mexpl)
      algorithm
        dim_str := intString(inDim);
        size_str := intString(listLength(mexpl));
        Error.addSourceMessage(Error.INVALID_ARRAY_DIM_IN_CONVERSION_OP,
          {dim_str, inOperator, "1", size_str}, inInfo);
      then
        fail();

    // Anything else is assumed to be a scalar.
    else inExp;
  end match;
end arrayScalar;

public function elabBuiltinHandler
  "This function dispatches the elaboration of builtin operators by returning
   the appropriate function. When a new builtin operator is added, a new rule
   has to be added to this function."
  input String inIdent;
  output HandlerFunc outHandler;

  partial function HandlerFunc
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input list<Absyn.Exp> inAbsynExpLst;
    input list<Absyn.NamedArg> inNamedArg;
    input Boolean inBoolean;
    input Prefix.Prefix inPrefix;
    input SourceInfo info;
    output FCore.Cache outCache;
    output DAE.Exp outExp;
    output DAE.Properties outProperties;
  end HandlerFunc;
algorithm
  outHandler := match (inIdent)
    case "delay" then elabBuiltinDelay;
    case "smooth" then elabBuiltinSmooth;
    case "size" then elabBuiltinSize;
    case "ndims" then elabBuiltinNDims;
    case "zeros" then elabBuiltinZeros;
    case "ones" then elabBuiltinOnes;
    case "fill" then elabBuiltinFill;
    case "max" then elabBuiltinMax;
    case "min" then elabBuiltinMin;
    case "transpose" then elabBuiltinTranspose;
    case "symmetric" then elabBuiltinSymmetric;
    case "array" then elabBuiltinArray;
    case "sum" then elabBuiltinSum;
    case "product" then elabBuiltinProduct;
    case "pre" then elabBuiltinPre;
    case "interval" then elabBuiltinInterval;
    case "boolean" then elabBuiltinBoolean;
    case "diagonal" then elabBuiltinDiagonal;
    case "noEvent" then elabBuiltinNoevent;
    case "edge" then elabBuiltinEdge;
    case "der" then elabBuiltinDer;
    case "change" then elabBuiltinChange;
    case "cat" then elabBuiltinCat;
    case "identity" then elabBuiltinIdentity;
    case "vector" then elabBuiltinVector;
    case "matrix" then elabBuiltinMatrix;
    case "scalar" then elabBuiltinScalar;
    case "String" then elabBuiltinString;
    case "rooted" then elabBuiltinRooted;
    case "Integer" then elabBuiltinIntegerEnum;
    case "EnumToInteger" then elabBuiltinIntegerEnum;
    case "inStream" then elabBuiltinInStream;
    case "actualStream" then elabBuiltinActualStream;
    case "getInstanceName" then elabBuiltinGetInstanceName;
    case "classDirectory" then elabBuiltinClassDirectory;
    case "sample" then elabBuiltinSample;
    case "cardinality" then elabBuiltinCardinality;
    case "homotopy" then elabBuiltinHomotopy;
    case "DynamicSelect" then elabBuiltinDynamicSelect;
    case "Clock"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinClock;
    case "previous"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinPrevious;
    case "hold"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinHold;
    case "subSample"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinSubSample;
    case "superSample"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinSuperSample;
    case "shiftSample"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinShiftSample;
    case "backSample"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinBackSample;
    case "noClock"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinNoClock;
    case "transition"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinTransition;
    case "initialState"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinInitialState;
    case "activeState"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinActiveState;
    case "ticksInState"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinTicksInState;
    case "timeInState"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinTimeInState;
    case "sourceInfo"
      equation
        true = Config.acceptMetaModelicaGrammar();
      then elabBuiltinSourceInfo;
    case "SOME"
      equation
        true = Config.acceptMetaModelicaGrammar();
      then elabBuiltinSome;
    case "NONE"
      equation
        true = Config.acceptMetaModelicaGrammar();
      then elabBuiltinNone;
  end match;
end elabBuiltinHandler;

public function elabBuiltinHandlerInternal "
  This function dispatches the elaboration of builtin operators by
  returning the appropriate function. When a new builtin operator is
  added, a new rule has to be added to this function.
"
  input String inIdent;
  output FuncType outFunc;

  partial function FuncType
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input list<Absyn.Exp> inAbsynExpLst;
    input list<Absyn.NamedArg> inNamedArg;
    input Boolean inBoolean;
    input Prefix.Prefix inPrefix;
    input SourceInfo info;
    output FCore.Cache outCache;
    output DAE.Exp outExp;
    output DAE.Properties outProperties;
  end FuncType;
algorithm
  outFunc := match inIdent
    case "simplify" then elabBuiltinSimplify;
  end match;
end elabBuiltinHandlerInternal;

protected function isBuiltinFunc "Returns true if the function name given as argument
  is a builtin function, which either has a elabBuiltinHandler function
  or can be found in the builtin environment."
  input Absyn.Path inPath "the path of the found function";
  input DAE.Type ty;
  output DAE.FunctionBuiltin isBuiltin;
  output Boolean b;
  output Absyn.Path outPath "make the path non-FQ";
algorithm
  (isBuiltin,b,outPath) := matchcontinue (inPath,ty)
    local
      String id;
      Absyn.Path path;

    case (path,DAE.T_FUNCTION(functionAttributes=DAE.FUNCTION_ATTRIBUTES(isBuiltin=isBuiltin as DAE.FUNCTION_BUILTIN(_))))
      equation
        path = Absyn.makeNotFullyQualified(path);
      then (isBuiltin, true, path);

    case (path,DAE.T_FUNCTION(functionAttributes=DAE.FUNCTION_ATTRIBUTES(isBuiltin=isBuiltin as DAE.FUNCTION_BUILTIN_PTR())))
      equation
        path = Absyn.makeNotFullyQualified(path);
      then (isBuiltin, false, path);

    case (Absyn.IDENT(name = id),_)
      equation
        elabBuiltinHandler(id);
      then
        (DAE.FUNCTION_BUILTIN(SOME(id)), true, inPath);

    case (Absyn.QUALIFIED("OpenModelicaInternal", Absyn.IDENT(name = id)), _)
      equation
        elabBuiltinHandlerInternal(id);
      then
        (DAE.FUNCTION_BUILTIN(SOME(id)), true, inPath);

    case (Absyn.FULLYQUALIFIED(path), _)
      equation
        (isBuiltin as DAE.FUNCTION_BUILTIN(_),_,path) = isBuiltinFunc(path,ty);
      then
        (isBuiltin, true, path);

    case (Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")), _)
      then (DAE.FUNCTION_BUILTIN(NONE()), true, inPath);

    else (DAE.FUNCTION_NOT_BUILTIN(), false, inPath);
  end matchcontinue;
end isBuiltinFunc;

protected function elabCallBuiltin
  "This function elaborates on builtin operators (such as \"pre\", \"der\" etc.),
   by calling the builtin handler to retrieve the correct function to call."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inFnName;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;

  partial function HandlerFunc
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input list<Absyn.Exp> inPosArgs;
    input list<Absyn.NamedArg> inNamedArgs;
    input Boolean inImplicit;
    input Prefix.Prefix inPrefix;
    input SourceInfo inInfo;
    output FCore.Cache outCache;
    output DAE.Exp outExp;
    output DAE.Properties outProperties;
  end HandlerFunc;
algorithm
  (outCache, outExp, outProperties) := match(inFnName)
    local
      HandlerFunc handler;
      Absyn.ComponentRef cr;

    case Absyn.CREF_IDENT(subscripts = {})
      algorithm
        handler := elabBuiltinHandler(inFnName.name);
      then
        handler(inCache, inEnv, inPosArgs, inNamedArgs, inImplicit, inPrefix, inInfo);

    case Absyn.CREF_QUAL(name = "OpenModelicaInternal", componentRef = cr as Absyn.CREF_IDENT())
      algorithm
        handler := elabBuiltinHandlerInternal(cr.name);
      then
        handler(inCache, inEnv, inPosArgs, inNamedArgs, inImplicit, inPrefix, inInfo);

    case Absyn.CREF_QUAL(name = "Connections", componentRef = Absyn.CREF_IDENT(name = "isRoot"))
      then elabBuiltinIsRoot(inCache, inEnv, inPosArgs, inNamedArgs, inImplicit, inPrefix, inInfo);

    case Absyn.CREF_QUAL(name = "Connections", componentRef = Absyn.CREF_IDENT(name = "uniqueRootIndices"))
      algorithm
        Error.addSourceMessage(Error.NON_STANDARD_OPERATOR, {"Connections.uniqueRootIndices"}, inInfo);
      then elabBuiltinUniqueRootIndices(inCache, inEnv, inPosArgs, inNamedArgs, inImplicit, inPrefix, inInfo);

    case Absyn.CREF_QUAL(name = "Connections", componentRef = Absyn.CREF_IDENT(name = "rooted"))
      then elabBuiltinRooted(inCache, inEnv, inPosArgs, inNamedArgs, inImplicit, inPrefix, inInfo);

    case Absyn.CREF_FULLYQUALIFIED(cr)
      then elabCallBuiltin(inCache, inEnv, cr, inPosArgs, inNamedArgs, inImplicit, inPrefix, inInfo);

  end match;
end elabCallBuiltin;

protected function elabCall
  "This function elaborates on a function call.  It converts the name to a
   Absyn.Path, and used the Static.elabCallArgs to do the rest of the work."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inST;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outST;
protected
  Integer numErrorMessages = Error.getNumErrorMessages();
algorithm
  (outCache,outExp,outProperties,outST):=
  matchcontinue (inCache,inEnv,inComponentRef,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,inST,inPrefix,info)
    local
      DAE.Exp e;
      DAE.Properties prop;
      Option<GlobalScript.SymbolTable> st;
      FCore.Graph env;
      Absyn.ComponentRef fn;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      Boolean impl;
      Absyn.Path fn_1;
      String fnstr,argstr,prestr,s,name,env_str;
      list<String> argstrs;
      FCore.Cache cache;
      Prefix.Prefix pre;

    case (cache,env,fn,args,nargs,impl,st,pre,_)
      equation
        (cache,e,prop) = elabCallBuiltin(cache,env, fn, args, nargs, impl,pre,info) "Built in functions (e.g. \"pre\", \"der\"), have only possitional arguments" ;
      then
        (cache,e,prop,st);

    case (_,_,fn,args,_,_,_,pre,_)
      equation
        true = hasBuiltInHandler(fn);
        true = numErrorMessages == Error.getNumErrorMessages();
        name = Absyn.printComponentRefStr(fn);
        s = stringDelimitList(List.map(args, Dump.printExpStr), ", ");
        s = stringAppendList({name,"(",s,").\n"});
        prestr = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {s,prestr}, info);
      then fail();

    /* Interactive mode */
    case (cache,env,fn,args,nargs,(impl as true),st,pre,_)
      equation
        false = hasBuiltInHandler(fn);
        ErrorExt.setCheckpoint("elabCall_InteractiveFunction");
        fn_1 = Absyn.crefToPath(fn);
        (cache,e,prop) = elabCallArgs(cache,env, fn_1, args, nargs, impl, st,pre,info);
        ErrorExt.delCheckpoint("elabCall_InteractiveFunction");
      then
        (cache,e,prop,st);

    /* Non-interactive mode */
    case (cache,env,fn,args,nargs,(impl as false),st,pre,_)
      equation
        false = hasBuiltInHandler(fn);
        fn_1 = Absyn.crefToPath(fn);
        (cache,e,prop) = elabCallArgs(cache,env, fn_1, args, nargs, impl, st,pre,info);
      then
        (cache,e,prop,st);

    case (_,_,fn,args,_,_,_,pre,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Static.elabCall failed\n");
        Debug.trace(" function: ");
        fnstr = Dump.printComponentRefStr(fn);
        Debug.trace(fnstr);
        Debug.trace("   posargs: ");
        argstrs = List.map(args, Dump.printExpStr);
        argstr = stringDelimitList(argstrs, ", ");
        Debug.traceln(argstr);
        Debug.trace(" prefix: ");
        prestr = PrefixUtil.printPrefixStr(pre);
        Debug.traceln(prestr);
      then
        fail();
    case (cache,env,fn,args,nargs,impl,st as SOME(_),pre,_) /* impl LS: Check if a builtin function call, e.g. size() and calculate if so */
      equation
        (cache,e,prop,st) = BackendInterface.elabCallInteractive(cache, env, fn, args, nargs, impl, st, pre, info) "Elaborate interactive function calls, such as simulate(), plot() etc." ;
        if impl==true then
          ErrorExt.rollBack("elabCall_InteractiveFunction");
        end if;
      then
        (cache,e,prop,st);
    else
        equation
          true=ErrorExt.isTopCheckpoint("elabCall_InteractiveFunction");
          ErrorExt.delCheckpoint("elabCall_InteractiveFunction");
        then fail();
  end matchcontinue;
end elabCall;

public function hasBuiltInHandler "
Author: BZ, 2009-02
Determine if a function has a builtin handler or not.
"
  input Absyn.ComponentRef fn;
  output Boolean b;
algorithm
  b := matchcontinue(fn)
    local
      String name;
    case (Absyn.CREF_IDENT(name = name,subscripts = {}))
      equation
        elabBuiltinHandler(name);
      then
        true;
    else false;
  end matchcontinue;
end hasBuiltInHandler;

public function elabVariablenames "This function elaborates variablenames to DAE.Expression. A variablename can
  be used in e.g. plot(model,{v1{3},v2.t}) It should only be used in interactive
  functions that uses variablenames as componentreferences.
"
  input list<Absyn.Exp> inExpl;
  output list<DAE.Exp> outExpl = {};
protected
  DAE.Exp exp;
  Absyn.ComponentRef cr;
algorithm
  outExpl := list(match e
    case Absyn.CREF() then DAE.CODE(Absyn.C_VARIABLENAME(e.componentRef), DAE.T_UNKNOWN_DEFAULT);
    case Absyn.CALL(Absyn.CREF_IDENT(name = "der"), Absyn.FUNCTIONARGS({Absyn.CREF()}, {}))
      then DAE.CODE(Absyn.C_EXPRESSION(e), DAE.T_UNKNOWN_DEFAULT);
  end match for e in inExpl);
end elabVariablenames;

public function getOptionalNamedArgExpList
  input String name;
  input list<Absyn.NamedArg> nargs;
  output list<DAE.Exp> out;
algorithm
  out := matchcontinue nargs
    local
      list<Absyn.Exp> absynExpList;
      String argName;
      list<Absyn.NamedArg> rest;

    case {} then {};

    case Absyn.NAMEDARG(argName = argName, argValue = Absyn.ARRAY(arrayExp = absynExpList)) :: _
      equation
        true = stringEq(name, argName);
      then
        absynExpListToDaeExpList(absynExpList);

    case _ :: rest
      then getOptionalNamedArgExpList(name, rest);

  end matchcontinue;
end getOptionalNamedArgExpList;

protected function absynExpListToDaeExpList
  input list<Absyn.Exp> absynExpList;
  output list<DAE.Exp> out;
algorithm
  out := match absynExpList
    local
      list<DAE.Exp> daeExpList;
      list<Absyn.Exp> absynRest;
      Absyn.ComponentRef absynCr;
      Absyn.Path absynPath;
      DAE.ComponentRef daeCr;
      DAE.Exp crefExp;

    case {} then {};

    case Absyn.CREF(componentRef = absynCr) :: absynRest
      equation
        absynPath = Absyn.crefToPath(absynCr);
        daeCr = ComponentReference.pathToCref(absynPath);
        crefExp = Expression.crefExp(daeCr);
        daeExpList = absynExpListToDaeExpList(absynRest);
      then
        crefExp :: daeExpList;

    case _ :: absynRest
      then absynExpListToDaeExpList(absynRest);
  end match;
end absynExpListToDaeExpList;

public function getOptionalNamedArg
  "This function is used to 'elaborate' interactive functions' optional parameters,
   e.g. simulate(A.b, startTime=1), startTime is an optional parameter."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inImplicit;
  input String inArgName;
  input DAE.Type inType;
  input list<Absyn.NamedArg> inArgs;
  input DAE.Exp inDefaultExp;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output DAE.Exp outExp = inDefaultExp;
protected
  String name, exp_str, ty_str, ety_str;
  DAE.Type ty;
  Absyn.Exp e;
  Boolean ty_match;
algorithm
  for arg in inArgs loop
    Absyn.NAMEDARG(argName = name) := arg;

    if name == inArgName then
      // Found the argument, try to evaluate it.
      try
        Absyn.NAMEDARG(argValue = e) := arg;

        (outCache, outExp, DAE.PROP(type_ = ty), _) :=
          elabExpInExpression(inCache, inEnv, e, inImplicit, inST, true, inPrefix, inInfo);
        outExp := Types.matchType(outExp, ty, inType, true);
      else
        // The argument couldn't be evaluated, possibly due to having the wrong
        // type. We should print an error for this, but some API functions like
        // simulate depend on the default arguments having the wrong type.
      end try;

      break;
    end if;
  end for;
end getOptionalNamedArg;

public function elabUntypedCref
  "This function elaborates a ComponentRef without adding type information.
   Environment is passed along, such that constant subscripts can be elabed
   using existing functions."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inCref;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match inCref
    local
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr;

    case Absyn.CREF_IDENT()
      algorithm
        (outCache, subs) := elabSubscripts(inCache, inEnv, inCref.subscripts,
          inImplicit, inPrefix, inInfo);
      then
        ComponentReference.makeCrefIdent(inCref.name, DAE.T_UNKNOWN_DEFAULT, subs);

    case Absyn.CREF_QUAL()
      algorithm
        (outCache, subs) := elabSubscripts(inCache, inEnv, inCref.subscripts,
          inImplicit, inPrefix, inInfo);
        (outCache, cr) := elabUntypedCref(outCache, inEnv, inCref.componentRef,
          inImplicit, inPrefix, inInfo);
      then
        ComponentReference.makeCrefQual(inCref.name, DAE.T_UNKNOWN_DEFAULT, subs, cr);

  end match;
end elabUntypedCref;

public function needToRebuild
  input String newFile;
  input String oldFile;
  input Real   buildTime;
  output Boolean buildNeeded;
algorithm
  buildNeeded := matchcontinue(newFile, oldFile)
    local String newf,oldf; Real bt,nfmt;
    case ("", "") then true; // rebuild all the time if the function has no file!
    case (newf, oldf)
      equation
        true = stringEq(newf, oldf); // the files should be the same!
        // the new file nf should have an older modification time than the last build
        SOME(nfmt) = System.getFileModificationTime(newf);
        true = realGt(buildTime, nfmt); // the file was not modified since last build
      then false;
    else true;
  end matchcontinue;
end needToRebuild;

public function isFunctionInCflist
"This function returns true if a function, named by an Absyn.Path,
  is present in the list of precompiled functions that can be executed
  in the interactive mode. If it returns true, it also returns the
  functionHandle stored in the cflist."
  input list<GlobalScript.CompiledCFunction> inFunctions;
  input Absyn.Path inPath;
  output Boolean outBoolean;
  output Integer outFuncHandle;
  output Real outBuildTime;
  output String outFileName;
protected
  Absyn.Path path;
algorithm
  for fn in inFunctions loop
    GlobalScript.CFunction(path = path) := fn;

    if Absyn.pathEqual(path, inPath) then
      GlobalScript.CFunction(funcHandle = outFuncHandle, buildTime =
          outBuildTime, loadedFromFile = outFileName) := fn;
      outBoolean := true;
      return;
    end if;
  end for;

  outBoolean := false;
  outFuncHandle := -1;
  outBuildTime := -1.0;
  outFileName := "";
end isFunctionInCflist;

protected function createDummyFarg
  input String name;
  output DAE.FuncArg farg;
algorithm
  farg := DAE.FUNCARG(name, DAE.T_UNKNOWN_DEFAULT, DAE.C_VAR(), DAE.NON_PARALLEL(), NONE());
end createDummyFarg;

protected function propagateDerivedInlineAnnotation
  "Inserts an inline annotation from the given class into the given comment, if
   the comment doesn't already have such an annotation."
  input SCode.Element inExtendedClass;
  input SCode.Comment inComment;
  output SCode.Comment outComment;
algorithm
  outComment := matchcontinue inExtendedClass
    local
      SCode.Comment cmt;
      SCode.Annotation ann;

    case SCode.CLASS(cmt = cmt)
      algorithm
        NONE() := SCode.getInlineTypeAnnotationFromCmt(inComment);
        SOME(ann) := SCode.getInlineTypeAnnotationFromCmt(cmt);
        cmt := SCode.appendAnnotationToComment(ann, cmt);
      then
        cmt;

    else inComment;
  end matchcontinue;
end propagateDerivedInlineAnnotation;

public function elabCallArgs "
function: elabCallArgs
  Given the name of a function and two lists of expression and
  NamedArg respectively to be used
  as actual arguments in a function call to that function, this
  function finds the function definition and matches the actual
  arguments to the formal parameters."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inST;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,SOME((outExp,outProperties))) :=
  elabCallArgs2(inCache,inEnv,inPath,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,Util.makeStatefulBoolean(false),inST,inPrefix,info,Error.getNumErrorMessages());
  (outCache,outProperties) := elabCallArgsEvaluateArrayLength(outCache,inEnv,outProperties,inPrefix,info);
end elabCallArgs;

protected function elabCallArgsEvaluateArrayLength
  "Evaluate array dimensions in the returned type. For a call f(n) we might get
   Integer[n] back, where n is a parameter expression.  We consider any such
   parameter structural since it decides the dimension of an array.  We fall
   back to not evaluating the parameter if we fail since the dimension may not
   be structural (used in another call or reduction, etc)."
  input FCore.Cache inCache;
  input FCore.Graph env;
  input DAE.Properties inProperties;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Properties outProperties;
protected
  DAE.Type ty;
algorithm
  try
    // Unsure if we want to evaluate dimensions inside function scope.
    // Last scope ref in env is a class scope.
    true := FGraph.checkScopeType({FGraph.lastScopeRef(env)}, SOME(FCore.CLASS_SCOPE()));
    ty := Types.getPropType(inProperties);
    (ty, (outCache, _)) := Types.traverseType(ty, (inCache, env), elabCallArgsEvaluateArrayLength2);
    outProperties := Types.setPropType(inProperties, ty);
  else
    outCache := inCache;
    outProperties := inProperties;
  end try;
end elabCallArgsEvaluateArrayLength;

protected function elabCallArgsEvaluateArrayLength2
  input DAE.Type ty;
  input tuple<FCore.Cache,FCore.Graph> inTpl;
  output DAE.Type oty = ty;
  output tuple<FCore.Cache,FCore.Graph> outTpl;
algorithm
  (oty,outTpl) := matchcontinue (oty,inTpl)
    local
      tuple<FCore.Cache,FCore.Graph> tpl;
      DAE.Dimensions dims;
      DAE.TypeSource source;
    case (DAE.T_ARRAY(),tpl)
      algorithm
        (dims,tpl) := List.mapFold(oty.dims,elabCallArgsEvaluateArrayLength3,tpl);
        oty.dims := dims;
      then (oty,tpl);
    else (oty,inTpl);
  end matchcontinue;
end elabCallArgsEvaluateArrayLength2;

protected function elabCallArgsEvaluateArrayLength3
  input DAE.Dimension inDim;
  input tuple<FCore.Cache,FCore.Graph> inTpl;
  output DAE.Dimension outDim;
  output tuple<FCore.Cache,FCore.Graph> outTpl;
algorithm
  (outDim,outTpl) := matchcontinue (inDim,inTpl)
    local
      Integer i;
      DAE.Exp exp;
      FCore.Cache cache;
      FCore.Graph env;
    case (DAE.DIM_EXP(exp),(cache,env))
      algorithm
        (cache,Values.INTEGER(i),_) := Ceval.ceval(cache,env,exp,false,NONE(),Absyn.NO_MSG(),0);
      then (DAE.DIM_INTEGER(i),(cache,env));
    else (inDim,inTpl);
  end matchcontinue;
end elabCallArgsEvaluateArrayLength3;

protected function createInputVariableReplacements
"@author: adrpo
  This function will add the binding expressions for inputs
  to the variable replacement structure. This is needed to
  be able to replace input variables in default values.
  Example: ... "
  input list<Slot> inSlotLst;
  input VarTransform.VariableReplacements inVarsRepl;
  output VarTransform.VariableReplacements outVarsRepl;
algorithm
  outVarsRepl := matchcontinue inSlotLst
    local
      VarTransform.VariableReplacements o;
      String id;
      DAE.Exp e;
      list<Slot> rest;

    // handle empty
    case {} then inVarsRepl;

    // only interested in filled slots that have a optional expression
    case SLOT(defaultArg = DAE.FUNCARG(name=id), slotFilled = true, arg = SOME(e)) :: rest
      algorithm
        o := VarTransform.addReplacement(inVarsRepl, ComponentReference.makeCrefIdent(id, DAE.T_UNKNOWN_DEFAULT, {}), e);
      then
        createInputVariableReplacements(rest, o);

    // try the next.
    else createInputVariableReplacements(listRest(inSlotLst), inVarsRepl);
  end matchcontinue;
end createInputVariableReplacements;

protected function elabCallArgs2 "
function: elabCallArgs
  Given the name of a function and two lists of expression and
  NamedArg respectively to be used
  as actual arguments in a function call to that function, this
  function finds the function definition and matches the actual
  arguments to the formal parameters."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Util.StatefulBoolean stopElab;
  input Option<GlobalScript.SymbolTable> inST;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  input Integer numErrors;
  output FCore.Cache outCache;
  output Option<tuple<DAE.Exp,DAE.Properties>> expProps;
algorithm
  (outCache,expProps) :=
  matchcontinue (inCache,inEnv,inPath,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,stopElab,inST,inPrefix,info,numErrors)
    local
      DAE.Type t,outtype,restype,functype,tp1;
      list<DAE.FuncArg> fargs;
      FCore.Graph env_1,env_2,env,classEnv,recordEnv;
      list<Slot> slots,newslots,newslots2;
      list<DAE.Exp> args_1,args_2;
      list<DAE.Const> constlist, constInputArgs, constDefaultArgs;
      DAE.Const const;
      DAE.TupleConst tyconst;
      DAE.Properties prop,prop_1;
      SCode.Element cl,scodeClass,recordCl;
      Absyn.Path fn,fn_1,fqPath,utPath,fnPrefix,componentType,correctFunctionPath,functionClassPath,path;
      list<Absyn.Exp> args,t4;
      Absyn.Exp argexp;
      list<Absyn.NamedArg> nargs, translatedNArgs;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      list<DAE.Type> typelist;
      DAE.Dimensions vect_dims;
      DAE.Exp call_exp,callExp,daeexp;
      list<String> t_lst,names;
      String fn_str,types_str,scope,pre_str,componentName,fnIdent;
      String s,name,argStr,stringifiedInstanceFunctionName;
      FCore.Cache cache;
      DAE.Type tp;
      Prefix.Prefix pre;
      SCode.Restriction re;
      Integer index;
      list<DAE.Var> vars;
      list<SCode.Element> comps;
      Absyn.InnerOuter innerOuter;
      list<Absyn.Path> operNames;
      Absyn.ComponentRef cref;
      DAE.ComponentRef daecref;
      DAE.Function func;
      DAE.ElementSource source;

    /* Record constructors that might have come from Graphical expressions with unknown array sizes */
    /*
     * adrpo: HACK! HACK! TODO! remove this case if records with unknown sizes can be instantiated
     * this could be also fixed by transforming the function call arguments into modifications and
     * send the modifications as an option in Lookup.lookup* functions!
     */
    case (cache,env,fn,args,nargs,impl,_,st,pre,_,_)
      equation
        (cache,cl as SCode.CLASS(restriction = SCode.R_PACKAGE()),_) =
           Lookup.lookupClass(cache, env, Absyn.IDENT("GraphicalAnnotationsProgram____"), false);
        (cache,cl as SCode.CLASS( restriction = SCode.R_RECORD(_)),env_1) = Lookup.lookupClass(cache, env, fn, false);
        (cache,cl,env_2) = Lookup.lookupRecordConstructorClass(cache, env_1 /* env */, fn);
        (_,_::names) = SCode.getClassComponents(cl); // remove the fist one as it is the result!
        /*
        (cache,(t as (DAE.T_FUNCTION(fargs,(outtype as (DAE.T_COMPLEX(complexClassType as ClassInf.RECORD(name),_,_,_),_))),_)),env_1)
          = Lookup.lookupType(cache, env, fn, SOME(info));
        */
        fargs = List.map(names, createDummyFarg);
        slots = makeEmptySlots(fargs);
        (cache,_,newslots,constInputArgs,_) = elabInputArgs(cache, env, args, nargs, slots, true, false /*checkTypes*/ ,impl,NOT_EXTERNAL_OBJECT_MODEL_SCOPE(), st,pre,info,DAE.T_UNKNOWN_DEFAULT,fn);
        (cache,newslots2,constDefaultArgs,_) = fillGraphicsDefaultSlots(cache, newslots, cl, env_2, impl, pre, info);
        _ = listAppend(constInputArgs, constDefaultArgs);
        // _ = List.fold(constlist, Types.constAnd, DAE.C_CONST());
        args_2 = slotListArgs(newslots2);

        tp = complexTypeFromSlots(newslots2,ClassInf.UNKNOWN(Absyn.IDENT("")));
      then
        (cache,SOME((DAE.CALL(fn,args_2,DAE.CALL_ATTR(tp,false,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL())),DAE.PROP(DAE.T_UNKNOWN_DEFAULT,DAE.C_CONST()))));

    // Record constructors, user defined or implicit, try the hard stuff first
    case (cache,env,fn,args,nargs,impl,_,st,pre,_,_)
      equation
        // For unrolling errors if an overloaded 'constructor' matches later.
        ErrorExt.setCheckpoint("RecordConstructor");

        (cache,func) = InstFunction.getRecordConstructorFunction(cache,env,fn);

        DAE.RECORD_CONSTRUCTOR(path,tp1,_,_) = func;
        DAE.T_FUNCTION(fargs, outtype, _, {path}) = tp1;


        slots = makeEmptySlots(fargs);
        (cache,_,newslots,constInputArgs,_) = elabInputArgs(cache,env, args, nargs, slots,true,true,impl, NOT_EXTERNAL_OBJECT_MODEL_SCOPE(),st,pre,info,tp1,path);

        (args_2, newslots2) = addDefaultArgs(newslots, info);
        vect_dims = slotsVectorizable(newslots2, info);

        constlist = constInputArgs;
        const = List.fold(constlist, Types.constAnd, DAE.C_CONST());

        tyconst = elabConsts(outtype, const);
        prop = getProperties(outtype, tyconst);

        callExp = DAE.CALL(path,args_2,DAE.CALL_ATTR(outtype,false,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

        (call_exp,prop_1) = vectorizeCall(callExp, vect_dims, newslots2, prop, info);
        expProps = SOME((call_exp,prop_1));

        Util.setStatefulBoolean(stopElab,true);
        ErrorExt.rollBack("RecordConstructor");

      then
        (cache,expProps);

        /* If the default constructor failed and we have an operator record
        look for overloaded Record constructors (operators), user defined.
        mahge:TODO move this to a function and call it from above.
        avoids uneccesary lookup since we already have a record.*/
    case (cache,env,fn,args,nargs,impl,_,st,pre,_,_)
      equation

        false = Util.getStatefulBoolean(stopElab);

        (cache,recordCl,recordEnv) = Lookup.lookupClass(cache,env,fn, false);
        true = SCode.isOperatorRecord(recordCl);

        fn_1 = Absyn.joinPaths(fn,Absyn.IDENT("'constructor'"));
        (cache,recordCl,recordEnv) = Lookup.lookupClass(cache,recordEnv,fn_1, false);
        true = SCode.isOperator(recordCl);

        operNames = SCodeUtil.getListofQualOperatorFuncsfromOperator(recordCl);
        (cache,typelist as _::_) = Lookup.lookupFunctionsListInEnv(cache, recordEnv, operNames, info, {});

        Util.setStatefulBoolean(stopElab,true);
        (cache,expProps) = elabCallArgs3(cache,env,typelist,fn_1,args,nargs,impl,st,pre,info);

        ErrorExt.rollBack("RecordConstructor");

      then
        (cache,expProps);

    /* ------ */
    case (cache,env,fn,args,nargs,impl,_,st,pre,_,_) /* Metamodelica extension, added by simbj */
      equation

        ErrorExt.delCheckpoint("RecordConstructor");

        true = Config.acceptMetaModelicaGrammar();
        false = Util.getStatefulBoolean(stopElab);
        (cache,t as DAE.T_METARECORD(source={_}),_) = Lookup.lookupType(cache, env, fn, NONE());
        Util.setStatefulBoolean(stopElab,true);
        (cache,expProps) = elabCallArgsMetarecord(cache,env,t,args,nargs,impl,stopElab,st,pre,info);
      then
        (cache,expProps);

      /* ..Other functions */
    case (cache,env,fn,args,nargs,impl,_,st,pre,_,_)
      equation

        ErrorExt.setCheckpoint("elabCallArgs2FunctionLookup");

        false = Util.getStatefulBoolean(stopElab);
        (cache,typelist as _::_) = Lookup.lookupFunctionsInEnv(cache, env, fn, info)
        "PR. A function can have several types. Taking an array with
         different dimensions as parameter for example. Because of this we
         cannot just lookup the function name and trust that it
         returns the correct function. It returns just one
         functiontype of several possibilites. The solution is to send
         in the function type of the user function and check both the
         function name and the function\'s type." ;
        Util.setStatefulBoolean(stopElab,true);
        (cache,expProps) = elabCallArgs3(cache,env,typelist,fn,args,nargs,impl,st,pre,info);

        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");

      then
        (cache,expProps);

    case (cache,env,fn,args,nargs,impl,_,st,pre,_,_) /* no matching type found, with -one- candidate */
      equation
        (cache,typelist as {tp1}) = Lookup.lookupFunctionsInEnv(cache, env, fn, info);
        (cache,args_1,_,_,functype,_,_) =
          elabTypes(cache, env, args, nargs, typelist, true, false/* Do not check types*/, impl,NOT_EXTERNAL_OBJECT_MODEL_SCOPE(), st,pre,info);
        argStr = ExpressionDump.printExpListStr(args_1);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        fn_str = Absyn.pathString(fn) + "(" + argStr + ")\nof type\n  " + Types.unparseType(functype);
        types_str = "\n  " + Types.unparseType(tp1);
        Error.assertionOrAddSourceMessage(Error.getNumErrorMessages()<>numErrors,Error.NO_MATCHING_FUNCTION_FOUND, {fn_str,pre_str,types_str}, info);

        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
      then
        (cache,NONE());

    case (cache,env,fn,_,_,_,_,_,_,_,_) /* class found; not function */
      equation
        (cache,SCode.CLASS(restriction = re),_) = Lookup.lookupClass(cache,env,fn,false);
        false = SCode.isFunctionRestriction(re);
        fn_str = Absyn.pathString(fn);
        s = SCodeDump.restrString(re);
        Error.addSourceMessage(Error.LOOKUP_FUNCTION_GOT_CLASS, {fn_str,s}, info);

        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
      then
        (cache,NONE());

    case (cache,env,fn,_,_,_,_,_,pre,_,_) /* no matching type found, with candidates */
      equation
        (cache,typelist as _::_::_) = Lookup.lookupFunctionsInEnv(cache,env, fn, info);
        t_lst = List.map(typelist, Types.unparseType);
        fn_str = Absyn.pathString(fn);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        types_str = stringDelimitList(t_lst, "\n -");
        //fn_str = fn_str + " in component " + pre_str;
        Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND, {fn_str,pre_str,types_str}, info);

        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
      then
        (cache,NONE());

    // In Optimica there is an odd syntax like for eg.,  x(finalTime) + y(finalTime); where both x and y are normal variables
    // not functions. So it is not really a call Exp but the compiler treats it as if it is up until this point.
    // This is a kind of trick to handle that.
    case (cache,env,fn,{Absyn.CREF(Absyn.CREF_IDENT(name,_))},_,impl,_,_,pre,_,_)
      guard Config.acceptOptimicaGrammar()
      equation
        cref = Absyn.pathToCref(fn);

        (cache,SOME((daeexp as DAE.CREF(daecref,tp),prop,_))) = elabCref(cache,env, cref, impl,true,pre,info);
        ErrorExt.rollBack("elabCallArgs2FunctionLookup");

        daeexp = DAE.CREF(DAE.OPTIMICA_ATTR_INST_CREF(daecref,name), tp);
        expProps = SOME((daeexp,prop));
      then
        (cache,expProps);

    case (cache,env,fn,_,_,_,_,_,_,_,_)
      equation
        failure((_,_,_) = Lookup.lookupType(cache,env, fn, NONE())) "msg" ;
        scope = FGraph.printGraphPathStr(env) + " (looking for a function or record)";
        fn_str = Absyn.pathString(fn);
        Error.addSourceMessage(Error.LOOKUP_ERROR, {fn_str,scope}, info); // No need to add prefix because only depends on scope?

        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
      then
        (cache,NONE());

    case (cache,env,fn,_,_,_,_,_,pre,_,_) /* no matching type found, no candidates. */
      equation
        (cache,{}) = Lookup.lookupFunctionsInEnv(cache,env,fn,info);
        fn_str = Absyn.pathString(fn);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        fn_str = fn_str + " in component " + pre_str;
        Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NO_CANDIDATE, {fn_str}, info);

        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
      then
        (cache,NONE());

    case (_,env,fn,_,_,_,_,_,_,_,_)
      equation
        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Static.elabCallArgs failed on: " + Absyn.pathString(fn) + " in env: " + FGraph.printGraphPathStr(env));
      then
        fail();
  end matchcontinue;
end elabCallArgs2;

public function elabCallArgs3
  "Elaborates the input given a set of viable function candidates, and vectorizes the arguments+performs type checking"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Type> typelist;
  input Absyn.Path fn;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix pre;
  input SourceInfo info;
  output FCore.Cache outCache;
  output Option<tuple<DAE.Exp,DAE.Properties>> expProps;
protected
  DAE.Exp callExp,call_exp;
  list<DAE.Exp> args_1,args_2;
  list<DAE.Const> constlist;
  DAE.Const const;
  DAE.Type restype,functype;
  DAE.FunctionBuiltin isBuiltin;
  DAE.FunctionParallelism funcParal;
  Boolean isPure,tuple_,builtin,isImpure;
  DAE.InlineType inlineType;
  Absyn.Path fn_1;
  DAE.Properties prop,prop_1;
  DAE.Type tp;
  DAE.TupleConst tyconst;
  DAE.Dimensions vect_dims;
  list<Slot> slots,slots2;
  DAE.FunctionTree functionTree;
  Util.Status status;
  FCore.Cache cache;
  Boolean didInline;
  Boolean b,onlyOneFunction,isFunctionPointer;
  IsExternalObject isExternalObject;
algorithm
  onlyOneFunction := listLength(typelist) == 1;
  (cache,b) := isExternalObjectFunction(inCache,inEnv,fn);
  isExternalObject := if b and not FGraph.inFunctionScope(inEnv) then IS_EXTERNAL_OBJECT_MODEL_SCOPE() else NOT_EXTERNAL_OBJECT_MODEL_SCOPE();
  (cache,
   args_1,
   constlist,
   restype,
   functype as DAE.T_FUNCTION(functionAttributes=DAE.FUNCTION_ATTRIBUTES(isOpenModelicaPure=isPure,
                                                                         isImpure=isImpure,
                                                                         inline=inlineType,
                                                                         isFunctionPointer=isFunctionPointer,
                                                                         functionParallelism=funcParal)),
   vect_dims,
   slots) := elabTypes(cache, inEnv, args, nargs, typelist, onlyOneFunction, true/* Check types*/, impl,isExternalObject,st,pre,info)
   "The constness of a function depends on the inputs. If all inputs are constant the call itself is constant." ;
  (fn_1,functype) := deoverloadFuncname(fn, functype, inEnv);
  tuple_ := Types.isTuple(restype);
  (isBuiltin,builtin,fn_1) := isBuiltinFunc(fn_1,functype);
  inlineType := inlineBuiltin(isBuiltin,inlineType);

  //check the env to see if a call to a parallel or kernel function is a valid one.
  true := isValidWRTParallelScope(fn,builtin,funcParal,inEnv,info);

  const := List.fold(constlist, Types.constAnd, DAE.C_CONST());
  const := if (Flags.isSet(Flags.RML) and not builtin) or (not isPure) then DAE.C_VAR() else const "in RML no function needs to be ceval'ed; this speeds up compilation significantly when bootstrapping";
  (cache,const) := determineConstSpecialFunc(cache,inEnv,const,fn_1);
  tyconst := elabConsts(restype, const);
  prop := getProperties(restype, tyconst);
  tp := Types.simplifyType(restype);
  // adrpo: 2011-09-30 NOTE THAT THIS WILL NOT ADD DEFAULT ARGS
  //                   FROM extends (THE BASE CLASS)
  (args_2, slots2) := addDefaultArgs(slots, info);
  // DO NOT CHECK IF ALL SLOTS ARE FILLED!
  true := List.fold(slots2, slotAnd, true);
  callExp := DAE.CALL(fn_1,args_2,DAE.CALL_ATTR(tp,tuple_,builtin,isImpure or (not isPure),isFunctionPointer,inlineType,DAE.NO_TAIL()));
  //ExpressionDump.dumpExpWithTitle("function elabCallArgs3: ", callExp);

  // create a replacement for input variables -> their binding
  //inputVarsRepl = createInputVariableReplacements(slots2, VarTransform.emptyReplacements());
  //print("Repls: " + VarTransform.dumpReplacementsStr(inputVarsRepl) + "\n");
  // replace references to inputs in the arguments
  //callExp = VarTransform.replaceExp(callExp, inputVarsRepl, NONE());

  //debugPrintString = if_(Util.isEqual(DAE.NORM_INLINE,inline)," Inline: " + Absyn.pathString(fn_1) + "\n", "");print(debugPrintString);
  (call_exp,prop_1) := vectorizeCall(callExp, vect_dims, slots2, prop, info);
  // print("3 Prefix: " + PrefixUtil.printPrefixStr(pre) + " path: " + Absyn.pathString(fn_1) + "\n");
  // Instantiate the function and add to dae function tree
  (cache,status) := instantiateDaeFunction(cache,inEnv,
    if Lookup.isFunctionCallViaComponent(cache, inEnv, fn) then fn else fn_1, // don't use the fully qualified name for calling component functions
    builtin,NONE(),true);
  // Instantiate any implicit record constructors needed and add them to the dae function tree
  cache := instantiateImplicitRecordConstructors(cache, inEnv, args_1, st);
  functionTree := FCore.getFunctionTree(cache);
  (call_exp,_,didInline,_) := Inline.inlineExp(call_exp,(SOME(functionTree),{DAE.BUILTIN_EARLY_INLINE(),DAE.EARLY_INLINE()}),DAE.emptyElementSource);
  (call_exp,_) := ExpressionSimplify.condsimplify(didInline,call_exp);
  didInline := didInline and (not Config.acceptMetaModelicaGrammar() /* Some weird errors when inlining. Becomes boxed even if it shouldn't... */);
  prop_1 := if didInline then Types.setPropType(prop_1, restype) else prop_1;
  (cache, call_exp, prop_1) := Ceval.cevalIfConstant(cache, inEnv, call_exp, prop_1, impl, info);
  expProps := if Util.isSuccess(status) then SOME((call_exp,prop_1)) else NONE();
  outCache := cache;
end elabCallArgs3;

protected function inlineBuiltin
  input DAE.FunctionBuiltin isBuiltin;
  input DAE.InlineType inlineType;
  output DAE.InlineType outInlineType;
algorithm
  outInlineType := match isBuiltin
    case DAE.FUNCTION_BUILTIN_PTR() then DAE.BUILTIN_EARLY_INLINE();
    else inlineType;
  end match;
end inlineBuiltin;

protected function isValidWRTParallelScope
  input Absyn.Path inFn;
  input Boolean isBuiltin;
  input DAE.FunctionParallelism inFuncParallelism;
  input FCore.Graph inEnv;
  input SourceInfo inInfo;
  output Boolean isValid;
algorithm
  isValid := isValidWRTParallelScope_dispatch(inFn, isBuiltin, inFuncParallelism, FGraph.currentScope(inEnv), inInfo);
end isValidWRTParallelScope;

protected function isValidWRTParallelScope_dispatch
  input Absyn.Path inFn;
  input Boolean isBuiltin;
  input DAE.FunctionParallelism inFuncParallelism;
  input FCore.Scope inScope;
  input SourceInfo inInfo;
  output Boolean isValid;
algorithm
  isValid := matchcontinue(inFn,isBuiltin,inFuncParallelism,inScope,inInfo)
  local
    String scopeName, errorString;
    FCore.Scope restScope;
    FCore.Ref ref;


    // non-parallel builtin function call is OK everywhere.
    case(_,true,DAE.FP_NON_PARALLEL(), _, _)
      then true;

    // If we have a function call in an implicit scope type, then go
    // up recursively to find the actuall scope and then check.
    // But parfor scope is a parallel type so is handled differently.
    case(_,_,_, ref::restScope, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);
        true = listMember(scopeName, FCore.implicitScopeNames);
        false = stringEq(scopeName, FCore.parForScopeName);
      then isValidWRTParallelScope_dispatch(inFn,isBuiltin,inFuncParallelism,restScope,inInfo);

    // This two are common cases so keep them at the top.
    // normal(non parallel) function call in a normal scope (function and class scopes) is OK.
    case(_,_,DAE.FP_NON_PARALLEL(), ref::_, _)
      equation
        true = FGraph.checkScopeType({ref}, SOME(FCore.CLASS_SCOPE()));
      then
        true;

    case(_,_,DAE.FP_NON_PARALLEL(), ref::_, _)
      equation
        true = FGraph.checkScopeType({ref}, SOME(FCore.FUNCTION_SCOPE()));
      then
        true;

    // Normal function call in a prallel scope is error, if it is not a built-in function.
    case(_,_,DAE.FP_NON_PARALLEL(), ref::_, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);
        true = FGraph.checkScopeType({ref}, SOME(FCore.PARALLEL_SCOPE()));

        errorString = "\n" +
             "- Non-Parallel function '" + Absyn.pathString(inFn) +
             "' can not be called from a parallel scope." + "\n" +
             "- Here called from :" + scopeName + "\n" +
             "- Please declare the function as parallel function.";
        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, inInfo);
      then
        false;


    // parallel function call in a parallel scope (kernel function, parallel function) is OK.
    // Except when it is calling itself, recurssion
    case(_,_,DAE.FP_PARALLEL_FUNCTION(), ref::_, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);
        true = FGraph.checkScopeType({ref}, SOME(FCore.PARALLEL_SCOPE()));
        // make sure the function is not calling itself
        // recurrsion is not allowed.
        false = stringEqual(scopeName,Absyn.pathString(inFn));
      then
        true;

    // If the above case failed (parallel function recurssion) this will print the error message
    case(_,_,DAE.FP_PARALLEL_FUNCTION(), ref::_, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);
        true = FGraph.checkScopeType({ref}, SOME(FCore.PARALLEL_SCOPE()));

        // make sure the function is not calling itself
        // recurrsion is not allowed.
        true = stringEqual(scopeName,Absyn.pathString(inFn));
        errorString = "\n" +
             "- Parallel function '" + Absyn.pathString(inFn) +
             "' can not call itself. Recurrsion is not allowed for parallel functions currently." + "\n" +
             "- Parallel functions can only be called from: 'kernel' functions," +
             " OTHER 'parallel' functions (no recurrsion) or from a body of a" +
             " 'parfor' loop";
        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, inInfo);
      then
        false;

    // parallel function call in a parfor scope is OK.
    case(_,_,DAE.FP_PARALLEL_FUNCTION(), ref::_, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);
        true = stringEqual(scopeName, FCore.parForScopeName);
      then
        true;

    //parallel function call in non parallel scope types is error.
    case(_,_,DAE.FP_PARALLEL_FUNCTION(), ref::_,_)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);

        errorString = "\n" +
             "- Parallel function '" + Absyn.pathString(inFn) +
             "' can not be called from a non parallel scope '" + scopeName + "'.\n" +
             "- Parallel functions can only be called from: 'kernel' functions," +
             " other 'parallel' functions (no recurrsion) or from a body of a" +
             " 'parfor' loop";
        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, inInfo);
      then false;

    // Kernel functions should not call themselves.
    case(_,_,DAE.FP_KERNEL_FUNCTION(), ref::_, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);

        // make sure the function is not calling itself
        // recurrsion is not allowed.
        true = stringEqual(scopeName,Absyn.pathString(inFn));
        errorString = "\n" +
             "- Kernel function '" + Absyn.pathString(inFn) +
             "' can not call itself. " + "\n" +
             "- Recurrsion is not allowed for Kernel functions. ";
        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, inInfo);
      then
        false;

    //kernel function call in a parallel scope (kernel function, parallel function) is Error.
    case(_,_,DAE.FP_KERNEL_FUNCTION(), ref::_, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);
        true = FGraph.checkScopeType({ref}, SOME(FCore.PARALLEL_SCOPE()));

        errorString = "\n" +
             "- Kernel function '" + Absyn.pathString(inFn) +
             "' can not be called from a parallel scope '" + scopeName + "'.\n" +
             "- Kernel functions CAN NOT be called from: 'kernel' functions," +
             " 'parallel' functions or from a body of a" +
             " 'parfor' loop";
        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, inInfo);
      then
        false;

    //kernel function call in a parfor loop is Error too (similar to above). just different error message.
    case(_,_,DAE.FP_KERNEL_FUNCTION(), ref::_, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);

        true = stringEqual(scopeName, FCore.parForScopeName);
        errorString = "\n" +
             "- Kernel function '" + Absyn.pathString(inFn) +
             "' can not be called from inside parallel for (parfor) loop body." + "'.\n" +
             "- Kernel functions CAN NOT be called from: 'kernel' functions," +
             " 'parallel' functions or from a body of a" +
             " 'parfor' loop";
        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, inInfo);
      then false;

    // Kernel function call in a non-parallel scope is OK.
    // Except when it is calling itself, recurssion
    case(_,_,DAE.FP_KERNEL_FUNCTION(), ref::_, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);
        // make sure the function is not calling itself
        // recurrsion is not allowed.
        false = stringEqual(scopeName,Absyn.pathString(inFn));
      then
        true;

    else true;

        /*
    //Normal (non parallel) function call in a normal function scope is OK.
    case(DAE.FP_NON_PARALLEL(), FCore.N(scopeType = FCore.FUNCTION_SCOPE())) then();
    //Normal (non parallel) function call in a normal class scope is OK.
    case(DAE.FP_NON_PARALLEL(), FCore.N(scopeType = FCore.CLASS_SCOPE())) then();
    //Normal (non parallel) function call in a normal function scope is OK.
    case(DAE.FP_NON_PARALLEL(), FCore.N(scopeType = FCore.FUNCTION_SCOPE())) then();
    //Normal (non parallel) function call in a normal class scope is OK.
    case(DAE.FP_KERNEL_FUNCTION(), FCore.N(scopeType = FCore.CLASS_SCOPE())) then();
    //Normal (non parallel) function call in a normal function scope is OK.
    case(DAE.FP_KERNEL_FUNCTION(), FCore.N(scopeType = FCore.FUNCTION_SCOPE())) then();
    */

 end matchcontinue;
end isValidWRTParallelScope_dispatch;

protected function elabCallArgsMetarecord
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Type inType;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplicit;
  input Util.StatefulBoolean stopElab;
  input Option<GlobalScript.SymbolTable> inST;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output Option<tuple<DAE.Exp,DAE.Properties>> expProps;
algorithm
  (outCache, expProps) := matchcontinue inType
    local
      Absyn.Path fq_path, ut_path;
      String str, fn_str;
      list<String> field_names;
      list<DAE.Type> tys;
      list<DAE.FuncArg> fargs;
      list<Slot> slots;
      list<DAE.Const> const_lst;
      DAE.Const const;
      DAE.TupleConst ty_const;
      DAE.Properties prop;
      list<DAE.Exp> args;

    case DAE.T_METARECORD(source = {fq_path})
      algorithm
        DAE.TYPES_VAR(name = str) := List.find(inType.fields, Types.varHasMetaRecordType);
        fn_str := Absyn.pathString(fq_path);
        Error.addSourceMessage(Error.METARECORD_CONTAINS_METARECORD_MEMBER,
          {fn_str, str}, inInfo);
      then
        (inCache, NONE());

    case DAE.T_METARECORD(source = {_})
      algorithm
        false := listLength(inType.fields) == listLength(inPosArgs) + listLength(inNamedArgs);
        fn_str := Types.unparseType(inType);
        Error.addSourceMessage(Error.WRONG_NO_OF_ARGS, {fn_str}, inInfo);
      then
        (inCache, NONE());

    case DAE.T_METARECORD(source = {fq_path})
      algorithm
        field_names := list(Types.getVarName(var) for var in inType.fields);
        tys := list(Types.getVarType(var) for var in inType.fields);
        fargs := list(Types.makeDefaultFuncArg(n, t) threaded for n in field_names, t in tys);
        slots := makeEmptySlots(fargs);
        (outCache, _, slots, const_lst) := elabInputArgs(inCache, inEnv, inPosArgs,
          inNamedArgs, slots, true, true, inImplicit, NOT_EXTERNAL_OBJECT_MODEL_SCOPE(),
          inST, inPrefix, inInfo, inType, inType.utPath);
        const := List.fold(const_lst, Types.constAnd, DAE.C_CONST());
        ty_const := elabConsts(inType, const);
        prop := getProperties(inType, ty_const);
        true := List.fold(slots, slotAnd, true);
        args := slotListArgs(slots);
      then
        (outCache, SOME((DAE.METARECORDCALL(fq_path, args, field_names, inType.index), prop)));

    // MetaRecord failure.
    case DAE.T_METARECORD(source = {fq_path})
      algorithm
        (outCache, _, prop) := elabExpInExpression(inCache, inEnv,
          Absyn.TUPLE(inPosArgs), false, inST, false, inPrefix, inInfo);
        tys := list(Types.getVarType(var) for var in inType.fields);
        str := "Failed to match types:\n    actual:   " +
          Types.unparseType(Types.getPropType(prop)) +
          "\n    expected: " +
          Types.unparseType(DAE.T_TUPLE(tys, NONE(), DAE.emptyTypeSource));
        fn_str := Absyn.pathString(fq_path);
        Error.addSourceMessage(Error.META_RECORD_FOUND_FAILURE, {fn_str, str}, inInfo);
      then
        (outCache, NONE());

    // MetaRecord failure (args).
    else
      algorithm
        {fq_path} := Types.getTypeSource(inType);
        str := "Failed to elaborate arguments " + Dump.printExpStr(Absyn.TUPLE(inPosArgs));
        fn_str := Absyn.pathString(fq_path);
        Error.addSourceMessage(Error.META_RECORD_FOUND_FAILURE, {fn_str, str}, inInfo);
      then
        (inCache, NONE());

  end matchcontinue;
end elabCallArgsMetarecord;

protected uniontype ForceFunctionInst
  record FORCE_FUNCTION_INST "Used when blocking function instantiation to instantiate the function anyway" end FORCE_FUNCTION_INST;
  record NORMAL_FUNCTION_INST "Used when blocking function instantiation to instantiate the function anyway" end NORMAL_FUNCTION_INST;
end ForceFunctionInst;

public function instantiateDaeFunction
  "Help function to elabCallArgs. Instantiates the function as a DAE and adds it
   to the functiontree of a newly created DAE."
  input FCore.Cache inCache;
  input FCore.Graph env;
  input Absyn.Path name;
  input Boolean builtin "builtin functions create empty dae";
  input Option<SCode.Element> clOpt "if not present, looked up by name in environment";
  input Boolean printErrorMsg "if true, prints an error message if the function could not be instantiated";
  output FCore.Cache outCache;
  output Util.Status status;
algorithm
  (outCache,status) := instantiateDaeFunction2(inCache, env, name, builtin,
    clOpt, printErrorMsg, NORMAL_FUNCTION_INST());
end instantiateDaeFunction;

public function instantiateDaeFunctionFromTypes
  "Help function to elabCallArgs. Instantiates the function as a DAE and adds it
   to the functiontree of a newly created DAE."
  input FCore.Cache inCache;
  input FCore.Graph env;
  input list<DAE.Type> tys;
  input Boolean builtin "builtin functions create empty dae";
  input Option<SCode.Element> clOpt "if not present, looked up by name in environment";
  input Boolean printErrorMsg "if true, prints an error message if the function could not be instantiated";
  input Util.Status acc;
  output FCore.Cache outCache;
  output Util.Status status;
algorithm
  (outCache,status) := match (tys, acc)
    local
      Absyn.Path name;
      list<DAE.Type> rest;
      Util.Status status1,status2;

    case (DAE.T_FUNCTION(source = {name}) :: rest, Util.SUCCESS())
      algorithm
        (outCache,status) := instantiateDaeFunction(inCache, env, name, builtin, clOpt, printErrorMsg);
      then
        instantiateDaeFunctionFromTypes(inCache, env, rest, builtin, clOpt, printErrorMsg, status);

    else (inCache, acc);
  end match;
end instantiateDaeFunctionFromTypes;

public function instantiateDaeFunctionForceInst
  "Help function to elabCallArgs. Instantiates the function as a DAE and adds it
   to the functiontree of a newly created DAE."
  input FCore.Cache inCache;
  input FCore.Graph env;
  input Absyn.Path name;
  input Boolean builtin "builtin functions create empty dae";
  input Option<SCode.Element> clOpt "if not present, looked up by name in environment";
  input Boolean printErrorMsg "if true, prints an error message if the function could not be instantiated";
  output FCore.Cache outCache;
  output Util.Status status;
algorithm
  (outCache,status) := instantiateDaeFunction2(inCache, env, name, builtin,
    clOpt, printErrorMsg, FORCE_FUNCTION_INST());
end instantiateDaeFunctionForceInst;

protected function instantiateDaeFunction2
  "Help function to elabCallArgs. Instantiates the function as a DAE and adds it
   to the functiontree of a newly created DAE."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inName;
  input Boolean builtin "builtin functions create empty dae";
  input Option<SCode.Element> clOpt "if not present, looked up by name in environment";
  input Boolean printErrorMsg "if true, prints an error message if the function could not be instantiated";
  input ForceFunctionInst forceFunctionInst;
  output FCore.Cache outCache;
  output Util.Status status;
protected
  Integer numError = Error.getNumErrorMessages();
  Boolean instOnlyForcedFunctions = isSome(getGlobalRoot(Global.instOnlyForcedFunctions));
algorithm
  (outCache,status) := matchcontinue(builtin, clOpt, instOnlyForcedFunctions, forceFunctionInst)
    local
      FCore.Graph env;
      SCode.Element cl;
      String pathStr,envStr;
      DAE.ComponentRef cref;
      Absyn.Path name;
      DAE.Type ty;

    // Skip function instantiation if we set those flags
    case (_, _, true, NORMAL_FUNCTION_INST())
      algorithm
        // Don't skip builtin functions or functions in the same package; they are useful to inline
        false := Absyn.pathIsIdent(inName);
        // print("Skipping: " + Absyn.pathString(name) + "\n");
      then
        (inCache, Util.SUCCESS());

    // Builtin functions skipped
    case (true, _, _, _) then (inCache, Util.SUCCESS());

    // External object functions skipped
    case (_, _, _, NORMAL_FUNCTION_INST())
      algorithm
        (_, true) := isExternalObjectFunction(inCache, inEnv, inName);
      then
        (inCache, Util.SUCCESS());

    // Recursive calls (by looking at environment) skipped
    case (_, NONE(), _, _)
      algorithm
        false := FGraph.isTopScope(inEnv);
        true := Absyn.pathSuffixOf(inName, FGraph.getGraphName(inEnv));
      then
        (inCache, Util.SUCCESS());

    // Recursive calls (by looking in cache) skipped
    case (_, _, _, _)
      algorithm
        (outCache, _, _, name) := lookupAndFullyQualify(inCache, inEnv, inName);
        FCore.checkCachedInstFuncGuard(outCache, name);
      then
        (outCache, Util.SUCCESS());

    // class must be looked up
    case (_, NONE(), _, _)
      algorithm
        (outCache, env, cl, name) := lookupAndFullyQualify(inCache, inEnv, inName);
        outCache := FCore.addCachedInstFuncGuard(outCache, name);
        outCache := InstFunction.implicitFunctionInstantiation(outCache, env,
          InnerOuter.emptyInstHierarchy, DAE.NOMOD(), Prefix.NOPRE(), cl, {});
      then
        (outCache, Util.SUCCESS());

    // class already available
    case (_, SOME(cl), _, _)
      algorithm
        (outCache,_) := Inst.makeFullyQualified(inCache, inEnv, inName);
        outCache := InstFunction.implicitFunctionInstantiation(outCache, inEnv,
          InnerOuter.emptyInstHierarchy, DAE.NOMOD(), Prefix.NOPRE(), cl, {});
      then
        (outCache, Util.SUCCESS());

    // call to function reference variable
    case (_, NONE(), _, _)
      algorithm
        cref := ComponentReference.pathToCref(inName);
        (outCache, _, ty) := Lookup.lookupVar(inCache, inEnv, cref);
        DAE.T_FUNCTION() := ty;
      then
        (outCache, Util.SUCCESS());

    case (_, _, true, _)
      algorithm
        true := Error.getNumErrorMessages() == numError;
        envStr := FGraph.printGraphPathStr(inEnv);
        pathStr := Absyn.pathString(inName);
        Error.addMessage(Error.GENERIC_INST_FUNCTION, {pathStr, envStr});
      then
        fail();

    else (inCache, Util.FAILURE());
  end matchcontinue;
end instantiateDaeFunction2;

protected function lookupAndFullyQualify
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inFunctionName;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output SCode.Element outClass;
  output Absyn.Path outFunctionName;
algorithm
  if Lookup.isFunctionCallViaComponent(inCache, inEnv, inFunctionName) then
    // do NOT qualify function calls via component instance!
    (_, outClass, outEnv) := Lookup.lookupClass(inCache, inEnv, inFunctionName, false);
    outFunctionName := FGraph.joinScopePath(outEnv, Absyn.makeIdentPathFromString(SCode.elementName(outClass)));
    outCache := inCache;
  else
    // qualify everything else
    (outCache, outClass, outEnv) := Lookup.lookupClass(inCache, inEnv, inFunctionName, false);
    outFunctionName := Absyn.makeFullyQualified(
      FGraph.joinScopePath(outEnv, Absyn.makeIdentPathFromString(SCode.elementName(outClass))));
  end if;
end lookupAndFullyQualify;

protected function instantiateImplicitRecordConstructors
  "Given a list of arguments to a function, this function checks if any of the
  arguments are component references to a record instance, and instantiates the
  record constructors for those components. These are implicit record
  constructors, because they are not explicitly called, but are needed when code
  is generated for record instances as function input arguments."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> args;
  input Option<GlobalScript.SymbolTable> st;
  output FCore.Cache outCache;
algorithm
  outCache := matchcontinue(args, st)
    local
      list<DAE.Exp> rest_args;
      Absyn.Path record_name;
      FCore.Cache cache;

    case (_, SOME(_)) then inCache;
    case ({}, _) then inCache;

    case (DAE.CREF(ty = DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(path = record_name))) :: rest_args, _)
      algorithm
        (cache, Util.SUCCESS()) := instantiateDaeFunction(inCache, inEnv, record_name, false, NONE(), false);
      then
        instantiateImplicitRecordConstructors(cache, inEnv, rest_args, NONE());

    case (_ :: rest_args, _)
      then instantiateImplicitRecordConstructors(inCache, inEnv, rest_args, NONE());

  end matchcontinue;
end instantiateImplicitRecordConstructors;

protected function addDefaultArgs
  "Adds default values to a list of function slots."
  input list<Slot> inSlots;
  input SourceInfo inInfo;
  output list<DAE.Exp> outArgs;
  output list<Slot> outSlots;
algorithm
  (outArgs, outSlots) := List.map2_2(inSlots, fillDefaultSlot, listArray(inSlots), inInfo);
end addDefaultArgs;

protected function fillDefaultSlot
  "Fills a function slot with it's default value if it hasn't already been filled."
  input Slot inSlot;
  input array<Slot> inSlotArray;
  input SourceInfo inInfo;
  output DAE.Exp outArg;
  output Slot outSlot;
algorithm
  (outArg, outSlot) := match inSlot
    local
      DAE.Exp arg;
      String id;
      Integer idx;

    // Slot already filled by function argument.
    case SLOT(slotFilled = true, arg = SOME(arg)) then (arg, inSlot);

    // Slot not filled by function argument, but has default value.
    case SLOT(slotFilled = false, defaultArg = DAE.FUNCARG(defaultBinding=SOME(_)), idx = idx)
      then fillDefaultSlot2(inSlotArray[idx], inSlotArray, inInfo);

    // Slot not filled, and has no default value => error.
    case SLOT(defaultArg = DAE.FUNCARG(name = id))
      equation
        Error.addSourceMessage(Error.UNFILLED_SLOT, {id}, inInfo);
      then
        fail();

  end match;
end fillDefaultSlot;

protected function fillDefaultSlot2
  input Slot inSlot;
  input array<Slot> inSlotArray;
  input SourceInfo inInfo;
  output DAE.Exp outArg;
  output Slot outSlot = inSlot;
algorithm
  (outArg, outSlot) := match outSlot
    local
      Slot slot;
      DAE.Exp exp;
      String id;
      DAE.FuncArg da;
      DAE.Dimensions dims;
      Integer idx;
      list<tuple<Slot, Integer>> slots;
      list<String> cyclic_slots;

    // An already evaluated slot, return its binding.
    case SLOT(arg = SOME(exp), evalStatus = 2)
      then (exp, inSlot);

    // A slot in the process of being evaluated => cyclic bindings.
    case SLOT(defaultArg = DAE.FUNCARG(name=id),
              evalStatus = 1)
      algorithm
        Error.addSourceMessage(Error.CYCLIC_DEFAULT_VALUE,
          {id}, inInfo);
      then
        fail();

    // A slot with an unevaluated binding, evaluate the binding and return it.
    case SLOT(defaultArg = DAE.FUNCARG(defaultBinding=SOME(exp)),
        idx = idx, evalStatus = 0)
      algorithm
        outSlot.evalStatus := SLOT_EVALUATING;
        arrayUpdate(inSlotArray, idx, outSlot);

        exp := evaluateSlotExp(exp, inSlotArray, inInfo);
        outSlot.arg := SOME(exp);
        outSlot.slotFilled := true;

        outSlot.evalStatus := SLOT_EVALUATED;
        arrayUpdate(inSlotArray, idx, outSlot);
      then
        (exp, outSlot);

  end match;
end fillDefaultSlot2;

protected function evaluateSlotExp
  "Evaluates a slot's binding by recursively replacing references to other slots
   with their bindings."
  input DAE.Exp inExp;
  input array<Slot> inSlotArray;
  input SourceInfo inInfo;
  output DAE.Exp outExp;
algorithm
  outExp := Expression.traverseExpBottomUp(inExp, evaluateSlotExp_traverser, (inSlotArray, inInfo));
end evaluateSlotExp;

protected function evaluateSlotExp_traverser
  input DAE.Exp inExp;
  input tuple<array<Slot>, SourceInfo> inTuple;
  output DAE.Exp outExp;
  output tuple<array<Slot>, SourceInfo> outTuple;
algorithm
  (outExp,outTuple) := match (inExp, inTuple)
    local
      String id;
      array<Slot> slots;
      Option<Slot> slot;
      DAE.Exp exp, orig_exp;
      SourceInfo info;

    // Only simple identifiers can be slot names.
    case (orig_exp as DAE.CREF(componentRef = DAE.CREF_IDENT(ident = id)), (slots, info))
      algorithm
        slot := lookupSlotInArray(id, slots);
        exp := getOptSlotDefaultExp(slot, slots, info, orig_exp);
      then
        (exp, (slots, info));

    else (inExp, inTuple);
  end match;
end evaluateSlotExp_traverser;

protected function lookupSlotInArray
  "Looks up the given name in an array of slots, and returns either SOME(slot)
   if a slot with that name was found, or NONE() if a slot couldn't be found."
  input String inSlotName;
  input array<Slot> inSlots;
  output Option<Slot> outSlot;
protected
  Slot slot;
algorithm
  try
    slot := Array.getMemberOnTrue(inSlotName, inSlots, isSlotNamed);
    outSlot := SOME(slot);
  else
    outSlot := NONE();
  end try;
end lookupSlotInArray;

protected function isSlotNamed
  input String inName;
  input Slot inSlot;
  output Boolean outIsNamed;
protected
  String id;
algorithm
  SLOT(defaultArg = DAE.FUNCARG(name=id)) := inSlot;
  outIsNamed := stringEq(id, inName);
end isSlotNamed;

protected function getOptSlotDefaultExp
  "Takes an optional slot and tries to evaluate the slot's binding if it's SOME,
   otherwise returns the original expression if it's NONE."
  input Option<Slot> inSlot;
  input array<Slot> inSlots;
  input SourceInfo inInfo;
  input DAE.Exp inOrigExp;
  output DAE.Exp outExp;
algorithm
  outExp := match inSlot
    local
      Slot slot;
      DAE.Exp exp;

    // Got a slot, evaluate its binding and return it.
    case SOME(slot)
      algorithm
        exp := fillDefaultSlot(slot, inSlots, inInfo);
      then
        exp;

    // No slot, return the original expression.
    case NONE() then inOrigExp;
  end match;
end getOptSlotDefaultExp;

protected function determineConstSpecialFunc
  "For the special functions constructor and destructor, in external object, the
   constantness is always variable, even if arguments are constant, because they
   should be called during runtime and not during compiletime."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Const inConst;
  input Absyn.Path inFuncName;
  output FCore.Cache outCache;
  output DAE.Const outConst;
protected
  Boolean is_ext;
algorithm
  (outCache, is_ext) := isExternalObjectFunction(inCache, inEnv, inFuncName);
  outConst := if is_ext then DAE.C_VAR() else inConst;
end determineConstSpecialFunc;

public function isExternalObjectFunction
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  output FCore.Cache outCache;
  output Boolean outIsExt;
protected
  list<SCode.Element> els;
  String last_id;
algorithm
  try
    (outCache, SCode.CLASS(classDef = SCode.PARTS(elementLst = els)), _) :=
      Lookup.lookupClass(inCache, inEnv, inPath, false);
    true := SCode.isExternalObject(els);
    outIsExt := true;
  else
    last_id := Absyn.pathLastIdent(inPath);
    outCache := inCache;
    outIsExt := last_id == "constructor" or last_id == "destructor";
  end try;
end isExternalObjectFunction;

protected constant String vectorizeArg = "$vectorizeArg";

protected function vectorizeCall "author: PA
  Takes an expression and a list of array dimensions and the Slot list.
  It will vectorize the expression over the dimension given as array dim
  for the slots which have that dimension.
  For example foo:(Real,Real[:])=> Real
  foo(1:2,{1,2;3,4}) vectorizes with arraydim [2] to
  {foo(1,{1,2}),foo(2,{3,4})}"
  input DAE.Exp inExp;
  input DAE.Dimensions inDims;
  input list<Slot> inSlots;
  input DAE.Properties inProperties;
  input SourceInfo info;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outExp, outProperties) := matchcontinue (inExp, inDims, inProperties)
    local
      DAE.Exp e,vect_exp,vect_exp_1,dimexp;
      DAE.Type tp,tp0;
      DAE.Properties prop;
      DAE.Type exp_type,etp;
      DAE.Const c;
      Absyn.Path fn;
      list<DAE.Exp> expl,es;
      Boolean scalar;
      Integer int_dim;
      DAE.Dimension dim;
      DAE.Dimensions ad;
      list<Slot> slots;
      String str;
      DAE.CallAttributes attr;
      DAE.ReductionInfo rinfo;
      DAE.ReductionIterator riter;
      String foldName,resultName;
      list<DAE.ReductionIterator> riters;
      Absyn.ReductionIterType iterType;

    case (e, {}, prop) then (e,prop);

    // If the dimension is not defined we can't vectorize the call. If we are running
    // checkModel this should succeed anyway, since we might be checking a function
    // that takes a vector of unknown size. So pretend that the dimension is 1.
    case (e, (DAE.DIM_UNKNOWN() :: ad), prop)
      algorithm
        true := Flags.getConfigBool(Flags.CHECK_MODEL);
      then
        vectorizeCall(e, DAE.DIM_INTEGER(1) :: ad, inSlots, prop, info);

    /* Scalar expression, i.e function call */
    case (e as DAE.CALL(),(dim :: ad),DAE.PROP(tp,c))
      algorithm
        int_dim := Expression.dimensionSize(dim);
        exp_type := Types.simplifyType(Types.liftArray(tp, dim)) "pass type of vectorized result expr";
        vect_exp := vectorizeCallScalar(e, exp_type, int_dim, inSlots);
        tp := Types.liftArray(tp, dim);
      then
        vectorizeCall(vect_exp, ad, inSlots, DAE.PROP(tp,c),info);

    /* array expression of function calls */
    case (DAE.ARRAY(),(dim :: ad),DAE.PROP(tp,c))
      algorithm
        int_dim := Expression.dimensionSize(dim);
        // _ = Types.simplifyType(Types.liftArray(tp, dim));
        vect_exp := vectorizeCallArray(inExp, int_dim, inSlots);
        tp := Types.liftArrayRight(tp, dim);
      then
        vectorizeCall(vect_exp, ad, inSlots, DAE.PROP(tp,c),info);

    /* Multiple dimensions are possible to change to a reduction, like:
     * f(arr1,arr2) => array(f(x,y) thread for x in arr1, y in arr2)
     * f(mat1,mat2) => array(array(f(x,y) thread for x in arr1, y in arr2) thread for arr1 in mat1, arr2 in mat2
     */
    case (DAE.CALL(fn,es,attr),dim::ad,prop as DAE.PROP(tp,c))
      algorithm
        (es, riters) := vectorizeCallUnknownDimension(es,inSlots,info);
        tp := Types.liftArrayRight(tp, dim);
        prop := DAE.PROP(tp,c);
        e := DAE.CALL(fn,es,attr);
        (e, prop) := vectorizeCall(e,ad,inSlots,prop,info); // Recurse...
        foldName := Util.getTempVariableIndex();
        resultName := Util.getTempVariableIndex();
        iterType := if listLength(riters)>1 then Absyn.THREAD() else Absyn.COMBINE();
        rinfo := DAE.REDUCTIONINFO(Absyn.IDENT("array"),iterType,tp,SOME(Values.ARRAY({},{0})),foldName,resultName,NONE());
      then
        (DAE.REDUCTION(rinfo, e, riters), prop);

    /* Scalar expression, non-constant but known dimensions */
    case (DAE.CALL(),(DAE.DIM_EXP() :: _),DAE.PROP())
      algorithm
        str := "Cannot vectorize call with dimensions [" + ExpressionDump.dimensionsString(inDims) + "]";
        Error.addSourceMessage(Error.INTERNAL_ERROR,{str},info);
      then
        fail();

    else
      algorithm
        true := Flags.isSet(Flags.FAILTRACE);
        str := ExpressionDump.dimensionString(listHead(inDims));
        Debug.traceln("- Static.vectorizeCall failed: " + str);
      then
        fail();
  end matchcontinue;
end vectorizeCall;

protected function vectorizeCallUnknownDimension
  "Returns the new call arguments and a reduction iterator argument"
  input list<DAE.Exp> inEs;
  input list<Slot> inSlots;
  input SourceInfo info;
  output list<DAE.Exp> oes = {};
  output list<DAE.ReductionIterator> ofound = {};
protected
  list<Slot> rest_slots = inSlots;
  list<DAE.Dimension> dims;
  DAE.Type ty, tp;
  String name;
algorithm
  for e in inEs loop
    SLOT(dims = dims, defaultArg = DAE.FUNCARG(ty = ty)) :: rest_slots := rest_slots;

    if listEmpty(dims) then
      oes := e :: oes;
    else
      name := Util.getTempVariableIndex();
      tp := Types.expTypetoTypesType(Expression.typeof(e)); // Maybe raise the type from the SLOT instead?
      ofound := DAE.REDUCTIONITER(name, e, NONE(), tp) :: ofound;
      oes := DAE.CREF(DAE.CREF_IDENT(name, ty, {}), ty) :: oes;
    end if;
  end for;

  if listEmpty(ofound) then
    Error.addSourceMessageAndFail(Error.INTERNAL_ERROR,
      {"Static.vectorizeCallUnknownDimension could not find any slot to vectorize"}, info);
  end if;

  oes := listReverse(oes);
  ofound := listReverse(ofound);
end vectorizeCallUnknownDimension;

protected function vectorizeCallArray
  "Helper function to vectorizeCall, vectorizes an ARRAY expression to an array
   of array expressions."
  input DAE.Exp inExp;
  input Integer inDim;
  input list<Slot> inSlots;
  output DAE.Exp outExp;
protected
  DAE.Type ty;
  list<DAE.Exp> expl;
  Boolean sc;
algorithm
  DAE.ARRAY(ty = ty, array = expl) := inExp;
  expl := vectorizeCallArray2(expl, ty, inDim, inSlots);
  sc := Expression.typeBuiltin(ty);
  ty := Expression.liftArrayRight(ty, DAE.DIM_INTEGER(inDim));
  outExp := DAE.ARRAY(ty, sc, expl);
end vectorizeCallArray;

protected function vectorizeCallArray2
  "Helper function to vectorizeCallArray"
  input list<DAE.Exp> inExpl;
  input DAE.Type inType;
  input Integer inDim;
  input list<Slot> inSlots;
  output list<DAE.Exp> outExpl;
algorithm
  outExpl := list(
    match e
      case DAE.CALL() then vectorizeCallScalar(e, inType, inDim, inSlots);
      case DAE.ARRAY() then vectorizeCallArray(e, inDim, inSlots);
    end match for e in inExpl);
end vectorizeCallArray2;

protected function vectorizeCallScalar
"author: PA
  Helper function to vectorizeCall, vectorizes CALL expressions to
  array expressions."
  input DAE.Exp exp "e.g. abs(v)";
  input DAE.Type ty " e.g. Real[3], result of vectorized call";
  input Integer dim;
  input list<Slot> slots;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue exp
    local
      list<DAE.Exp> expl,args;
      Boolean scalar;
      DAE.Exp new_exp;
      DAE.Type e_type,arr_type;

    case DAE.CALL()
      algorithm
        expl := vectorizeCallScalar2(exp.path, exp.expLst, exp.attr, slots, dim);
        e_type := Expression.unliftArray(ty);
        scalar := Expression.typeBuiltin(e_type) " unlift vectorized dimension to find element type";
        arr_type := DAE.T_ARRAY(e_type, {DAE.DIM_INTEGER(dim)}, DAE.emptyTypeSource);
        new_exp := DAE.ARRAY(arr_type,scalar,expl);
      then
        new_exp;

    else
      algorithm
        true := Flags.isSet(Flags.FAILTRACE);
        Debug.trace("-Static.vectorizeCallScalar failed\n");
      then
        fail();
  end matchcontinue;
end vectorizeCallScalar;

protected function vectorizeCallScalar2
  "Iterates through vectorized dimension an creates argument list according to vectorized dimension in corresponding slot."
  input Absyn.Path fn;
  input list<DAE.Exp> exps;
  input DAE.CallAttributes attr;
  input list<Slot> slots;
  input Integer dim;
  output list<DAE.Exp> res = {};
protected
  list<DAE.Exp> callargs;
algorithm
  for cur_dim in dim:-1:1 loop
    callargs := vectorizeCallScalar3(exps, slots, cur_dim);
    res := DAE.CALL(fn,callargs,attr) :: res;
  end for;
end vectorizeCallScalar2;

protected function vectorizeCallScalar3
"author: PA
  Helper function to vectorizeCallScalar2"
  input list<DAE.Exp> inExpl;
  input list<Slot> inSlots;
  input Integer inIndex;
  output list<DAE.Exp> outExpl = {};
protected
  list<Slot> rest_slots = inSlots;
  list<DAE.Dimension> dims;
algorithm
  for e in inExpl loop
    SLOT(dims = dims) :: rest_slots := rest_slots;

    if not listEmpty(dims) then
      // Foreach argument.
      e := Expression.makeASUB(e, {DAE.ICONST(inIndex)});
      e := ExpressionSimplify.simplify1(e);
    end if;

    outExpl := e :: outExpl;
  end for;

  outExpl := listReverse(outExpl);
end vectorizeCallScalar3;

protected function deoverloadFuncname
"This function is used to deoverload function calls. It investigates the
  type of the function to see if it has the optional functionname set. If
  so this is returned. Otherwise return input."
  input Absyn.Path inPath;
  input DAE.Type inType;
  input FCore.Graph inEnv;
  output Absyn.Path outPath;
  output DAE.Type outType;
algorithm
  (outPath,outType) := match inType
    local
      Absyn.Path fn;
      String name;
      DAE.Type tty;

    case DAE.T_FUNCTION(functionAttributes = DAE.FUNCTION_ATTRIBUTES(
        isBuiltin = DAE.FUNCTION_BUILTIN(SOME(name))))
      algorithm
        fn := Absyn.IDENT(name);
        tty := Types.setTypeSource(inType, Types.mkTypeSource(SOME(fn)));
      then
        (fn, tty);

    case DAE.T_FUNCTION(source = {fn}) then (fn,inType);
    else (inPath, inType);

  end match;
end deoverloadFuncname;

protected function elabTypes
  "Elaborate input parameters to a function and select matching function type
   from a list of types."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input list<DAE.Type> inTypes;
  input Boolean inOnlyOneFunction "if true, we can report errors as soon as possible";
  input Boolean inCheckTypes "if true, checks types";
  input Boolean inImplicit;
  input IsExternalObject isExternalObject;
  input Option<GlobalScript.SymbolTable> inST;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output list<DAE.Exp> outArgs;
  output list<DAE.Const> outConsts;
  output DAE.Type outResultType;
  output DAE.Type outFunctionType;
  output DAE.Dimensions outDimensions;
  output list<Slot> outSlots;
protected
  list<DAE.FuncArg> params;
  DAE.Type res_ty, func_ty;
  DAE.FunctionAttributes func_attr;
  list<Slot> slots;
  InstTypes.PolymorphicBindings pb;
  DAE.TypeSource ts;
  Absyn.Path path;
  Boolean success = false;
  list<DAE.Type> rest_tys = inTypes;
algorithm
  while not success loop
    func_ty :: rest_tys := rest_tys;

    DAE.T_FUNCTION(funcArg = params, funcResultType = res_ty,
      functionAttributes = func_attr, source = ts) := func_ty;

    try
      slots := makeEmptySlots(params);
      path := if listEmpty(ts) then Absyn.IDENT("builtinFunction") else listHead(ts);
      (outCache, outArgs, outSlots, outConsts, pb) := elabInputArgs(inCache, inEnv,
        inPosArgs, inNamedArgs, slots, inOnlyOneFunction, inCheckTypes, inImplicit,
        isExternalObject, inST, inPrefix, inInfo, func_ty, path);

      // Check the sanity of function parameters whose types are dependent on other parameters.
      // e.g. input Integer i; input Integer a[i]; // type of 'a' depends on the value 'i'.
      (params, res_ty) := applyArgTypesToFuncType(outSlots, params, res_ty, inEnv, inCheckTypes, inInfo);
      pb := Types.solvePolymorphicBindings(pb, inInfo, ts);

      outDimensions := slotsVectorizable(outSlots, inInfo);
      outResultType := Types.fixPolymorphicRestype(res_ty, pb, inInfo);
      outFunctionType := DAE.T_FUNCTION(params, outResultType, func_attr, ts);

      // Only created when not checking types for error msg.
      outFunctionType := createActualFunctype(outFunctionType, outSlots, inCheckTypes);
      success := true;
    else
      // The type didn't match, try next function type.
    end try;
  end while;
end elabTypes;

protected function applyArgTypesToFuncType
  "This function is yet another hack trying to handle function parameters with
   unknown dimensions. It uses the input arguments to try and figure out the
   actual dimensions of the dimensions."
  input list<Slot> inSlots;
  input list<DAE.FuncArg> inParameters;
  input DAE.Type inResultType;
  input FCore.Graph inEnv;
  input Boolean checkTypes; // If not checking types no need to do any of this. In and out.
  input SourceInfo inInfo;
  output list<DAE.FuncArg> outParameters;
  output DAE.Type outResultType;
protected
  list<DAE.Type> tys;
  list<DAE.Dimension> dims;
  list<String> used_args;
  list<Slot> used_slots;
  FCore.Cache cache;
  FCore.Graph env;
  list<DAE.Var> vars;
  SCode.Element dummy_var;
  DAE.Type res_ty;
algorithm
  // If not checking types or no function parameters there is nothing to be done here.
  // Even if dims don't match we need the function as candidate for error messages.
  if not checkTypes or listEmpty(inParameters) then
    outParameters := inParameters;
    outResultType := inResultType;
    return;
  end if;

  // Get all the dims, bind the actual params to the formal params.
  // Build a new env frame with these bindings and evaluate dimensions.

  // Extract all dimensions from the parameters.
  tys := list(Types.funcArgType(param) for param in inParameters);
  dims := getAllOutputDimensions(inResultType);
  dims := listAppend(List.mapFlat(tys, Types.getDimensions), dims);

  // Use the dimensions to figure out which parameters are referenced by other
  // parameters' dimensions. This is done to minimize the things we need to
  // constant evaluate, a.k.a. 'things that go wrong'.
  used_args := extractNamesFromDims(dims);
  used_slots := list(s for s guard(isSlotUsed(s, used_args)) in inSlots);

  // Create DAE.Vars from the slots.
  cache := FCore.noCache();
  vars := list(makeVarFromSlot(s, inEnv, cache) for s in used_slots);

  // Use a dummy SCode.Element, because we're only interested in the DAE.Vars.
  dummy_var := SCode.COMPONENT("dummy", SCode.defaultPrefixes,
    SCode.defaultVarAttr, Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
    SCode.noComment, NONE(), Absyn.dummyInfo);

  // Create a new implicit scope with the needed parameters on top of the
  // current env so we can find the bindings if needed. We need an implicit
  // scope so comp1.comp2 can be looked up without package constant restriction.
  env := FGraph.openScope(inEnv, SCode.NOT_ENCAPSULATED(), SOME(FCore.forScopeName), NONE());

  // Add variables to the environment.
  env := makeDummyFuncEnv(env, vars, dummy_var);
  // Evaluate the dimensions in the types.
  outParameters := list(evaluateFuncParamDimAndMatchTypes(s, p, env, cache, inInfo)
    threaded for s in inSlots, p in inParameters);
  outResultType := evaluateFuncArgTypeDims(inResultType, env, cache);
end applyArgTypesToFuncType;

protected function getAllOutputDimensions
  "Return the dimensions of an output type."
  input DAE.Type inOutputType;
  output list<DAE.Dimension> outDimensions;
algorithm
  outDimensions := match(inOutputType)
    local
      list<DAE.Type> tys;

    // A tuple, get the dimensions of all the types.
    case DAE.T_TUPLE(types = tys)
      then List.mapFlat(tys, Types.getDimensions);

    else Types.getDimensions(inOutputType);
  end match;
end getAllOutputDimensions;

protected function extractNamesFromDims
  "Extracts a list of unique names referenced by the given list of dimensions."
  input list<DAE.Dimension> inDimensions;
  input list<String> inAccumNames = {};
  output list<String> outNames;
algorithm
  outNames := match inDimensions
    local
      DAE.Exp exp;
      list<DAE.Dimension> rest_dims;
      list<DAE.ComponentRef> crefs;
      list<String> names;

    case DAE.DIM_EXP(exp = exp) :: rest_dims
      algorithm
        crefs := Expression.extractCrefsFromExp(exp);
        names := List.fold(crefs, extractNamesFromDims2, inAccumNames);
      then
        extractNamesFromDims(rest_dims, names);

    case _ :: rest_dims then extractNamesFromDims(rest_dims, inAccumNames);
    case {} then inAccumNames;

  end match;
end extractNamesFromDims;

protected function extractNamesFromDims2
  input DAE.ComponentRef inCref;
  input list<String> inAccumNames;
  output list<String> outNames;
algorithm
  outNames := match(inCref, inAccumNames)
    local
      String name;

    // Only interested in simple identifier, since that's all we can handle
    // anyway.
    case (DAE.CREF_IDENT(ident = name), _)
      algorithm
        // Make sure we haven't added this name yet.
        outNames := if List.isMemberOnTrue(name, inAccumNames, stringEq) then
          inAccumNames else name :: inAccumNames;
      then
        outNames;

    else inAccumNames;

  end match;
end extractNamesFromDims2;

protected function isSlotUsed
  "Checks if a slot is used, in the sense that it's referenced by a function
   parameter dimension."
  input Slot inSlot;
  input list<String> inUsedNames;
  output Boolean outIsUsed;
protected
  String slot_name;
algorithm
  SLOT(defaultArg = DAE.FUNCARG(name=slot_name)) := inSlot;
  outIsUsed := List.isMemberOnTrue(slot_name, inUsedNames, stringEq);
end isSlotUsed;

protected function makeVarFromSlot
  "Converts a Slot to a DAE.Var."
  input Slot inSlot;
  input FCore.Graph inEnv;
  input FCore.Cache inCache;
  output DAE.Var outVar;
algorithm
  outVar := matchcontinue inSlot
    local
      DAE.Ident name;
      DAE.Type ty;
      DAE.Exp exp;
      DAE.Binding binding;
      Values.Value val;
      DAE.FuncArg defaultArg;
      Boolean slotFilled;
      DAE.Dimensions dims;
      Integer idx;
      DAE.Var var;

    // If the argument expression already has known dimensions, no need to
    // constant evaluate it.
    case SLOT(defaultArg = DAE.FUNCARG(name=name), arg = SOME(exp))
      algorithm
        false := Expression.expHasCref(exp,ComponentReference.makeCrefIdent(name,DAE.T_UNKNOWN_DEFAULT,{}));
        ty := Expression.typeof(exp);
        true := Types.dimensionsKnown(ty);
        binding := DAE.EQBOUND(exp, NONE(), DAE.C_CONST(), DAE.BINDING_FROM_DEFAULT_VALUE());
      then (DAE.TYPES_VAR(name, DAE.dummyAttrParam, ty, binding, NONE()));

    // Otherwise, try to constant evaluate the expression.
    case SLOT(defaultArg = DAE.FUNCARG(name=name), arg = SOME(exp))
      algorithm
        // Constant evaluate the bound expression.
        (_, val) := Ceval.ceval(inCache, inEnv, exp, false, NONE(), Absyn.NO_MSG(), 0);
        exp := ValuesUtil.valueExp(val);
        ty := Expression.typeof(exp);
        // Create a binding from the evaluated expression.
        binding := DAE.EQBOUND(exp, SOME(val), DAE.C_CONST(), DAE.BINDING_FROM_DEFAULT_VALUE());
      then DAE.TYPES_VAR(name, DAE.dummyAttrParam, ty, binding, NONE());

    case SLOT(defaultArg = DAE.FUNCARG(name=name, ty=ty))
      then (DAE.TYPES_VAR(name, DAE.dummyAttrParam, ty, DAE.UNBOUND(), NONE()));

  end matchcontinue;
end makeVarFromSlot;

protected function evaluateStructuralSlots2
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Slot> inSlots;
  input list<String> usedSlots;
  input list<Slot> acc;
  output FCore.Cache cache;
  output list<Slot> slots;
algorithm
  (cache,slots) := matchcontinue inSlots
    local
      String name;
      Boolean slotFilled;
      DAE.Exp exp;
      Slot slot;
      list<Slot> rest;
      DAE.FuncArg defaultArg;
      list<DAE.Dimension> dims;
      Integer idx;
      Values.Value val;
      DAE.Type ty;
      DAE.Binding binding;
      Integer ses;

    case {} then (inCache,listReverse(acc));

    case slot::rest
      algorithm
        false := isSlotUsed(slot, usedSlots);
        (cache,slots) := evaluateStructuralSlots2(inCache,inEnv,rest,usedSlots,slot::acc);
      then (cache,slots);

      // If we are suggested the argument is structural, evaluate it
    case SLOT(defaultArg as DAE.FUNCARG(), _, SOME(exp), dims, idx, ses)::rest
      algorithm
        // Constant evaluate the bound expression.
        (cache, val) := Ceval.ceval(inCache, inEnv, exp, false, NONE(), Absyn.NO_MSG(), 0);
        exp := ValuesUtil.valueExp(val);
        // Create a binding from the evaluated expression.
        slot := SLOT(defaultArg,true,SOME(exp),dims,idx,ses);
        (cache,slots) := evaluateStructuralSlots2(cache,inEnv,rest,usedSlots,slot::acc);
      then (cache,slots);

    case slot::rest
      algorithm
        (cache,slots) := evaluateStructuralSlots2(inCache,inEnv,rest,usedSlots,slot::acc);
      then (cache,slots);
  end matchcontinue;
end evaluateStructuralSlots2;

protected function evaluateStructuralSlots
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Slot> inSlots;
  input DAE.Type funcType;
  output FCore.Cache cache;
  output list<Slot> slots;
algorithm
  (cache,slots) := match funcType
    local
      list<DAE.Type> tys;
      list<DAE.Dimension> dims;
      list<String> used_args;
      list<DAE.FuncArg> funcArg;
      DAE.Type funcResultType;

    case DAE.T_FUNCTION(funcArg=funcArg,funcResultType=funcResultType)
      algorithm
        tys := list(Types.funcArgType(arg) for arg in funcArg);
        dims := getAllOutputDimensions(funcResultType);
        dims := listAppend(List.mapFlat(tys, Types.getDimensions), dims);
        // Use the dimensions to figure out which parameters are referenced by
        // other parameters' dimensions. This is done to minimize the things we
        // need to constant evaluate, a.k.a. 'things that go wrong'.
        used_args := extractNamesFromDims(dims);
        (cache, slots) := evaluateStructuralSlots2(inCache, inEnv, inSlots, used_args, {});
      then
        (cache,slots);

    else (inCache, inSlots); // T_METARECORD, T_NOTYPE etc for builtins
  end match;
end evaluateStructuralSlots;

protected function makeDummyFuncEnv
  "Helper function to applyArgTypesToFuncType, creates a dummy function
   environment."
  input FCore.Graph inEnv;
  input list<DAE.Var> inVars;
  input SCode.Element inDummyVar;
  output FCore.Graph outEnv = inEnv;
protected
  SCode.Element dummy_var;
algorithm
  for var in inVars loop
    dummy_var := SCode.setComponentName(inDummyVar, DAEUtil.typeVarIdent(var));
    outEnv := FGraph.mkComponentNode(outEnv, var, dummy_var, DAE.NOMOD(),
      FCore.VAR_TYPED(), FGraph.empty());
  end for;
end makeDummyFuncEnv;

protected function evaluateFuncParamDimAndMatchTypes
  "Constant evaluates the dimensions of a FuncArg and then makes
  sure the type matches with the expected type in the slot."
  input Slot inSlot;
  input DAE.FuncArg inParam;
  input FCore.Graph inEnv;
  input FCore.Cache inCache;
  input SourceInfo inInfo;
  output DAE.FuncArg outParam;
algorithm
  outParam := match(inSlot, inParam)
  local
    DAE.Ident ident;
    DAE.Type pty, sty;
    DAE.Const c;
    DAE.VarParallelism p;
    Option<DAE.Exp> oexp;
    DAE.Dimensions dims1, dims2;
    String t_str1,t_str2;
    DAE.Dimensions vdims;
    Boolean b;


    // If we have a code exp argument we can't check dims...
    // There are all kinds of scripting function that complicate things.
    case (_, DAE.FUNCARG(ty=DAE.T_CODE()))
      then inParam;

    // If we have an array constant-evaluate the dimensions and make sure
    // They add up
    case (SLOT(arg = SOME(DAE.ARRAY(ty = sty)), dims = vdims), _)
      algorithm
        DAE.FUNCARG(ty = pty) := inParam;
        // evaluate the dimesions
        pty := evaluateFuncArgTypeDims(pty, inEnv, inCache);
        // append the vectorization dim if argument is vectorized.
        dims1 := Types.getDimensions(pty);
        dims1 := listAppend(vdims,dims1);

        dims2 := Types.getDimensions(sty);
        true := Expression.dimsEqual(dims1, dims2);

        outParam := Types.setFuncArgType(inParam, pty);
      then
        outParam;

    case (SLOT(arg = SOME(DAE.MATRIX(ty = sty)), dims = vdims), _)
      algorithm
        DAE.FUNCARG(ty=pty) := inParam;
        // evaluate the dimesions
        pty := evaluateFuncArgTypeDims(pty, inEnv, inCache);
        // append the vectorization dim if argument is vectorized.
        dims1 := Types.getDimensions(pty);
        dims1 := listAppend(dims1,vdims);
        dims2 := Types.getDimensions(sty);
        true := Expression.dimsEqual(dims1, dims2);

        outParam := Types.setFuncArgType(inParam, pty);
      then
        outParam;

    else
      algorithm
        DAE.FUNCARG(ty=pty) := inParam;
        pty := evaluateFuncArgTypeDims(pty, inEnv, inCache);
        outParam := Types.setFuncArgType(inParam, pty);
      then
        outParam;

  end match;
end evaluateFuncParamDimAndMatchTypes;

protected function evaluateFuncArgTypeDims
  "Constant evaluates the dimensions of a type."
  input DAE.Type inType;
  input FCore.Graph inEnv;
  input FCore.Cache inCache;
  output DAE.Type outType;
algorithm
  outType := matchcontinue inType
    local
      DAE.Type ty;
      DAE.TypeSource ts;
      Integer n;
      DAE.Dimension dim;
      list<DAE.Type> tys;
      FCore.Graph env;

    // Array type, evaluate the dimension.
    case DAE.T_ARRAY(ty, {dim}, ts)
      algorithm
        (_, Values.INTEGER(n), _) := Ceval.cevalDimension(inCache, inEnv, dim, false, NONE(), Absyn.NO_MSG(), 0);
        ty := evaluateFuncArgTypeDims(ty, inEnv, inCache);
      then
        DAE.T_ARRAY(ty, {DAE.DIM_INTEGER(n)}, ts);

    // Previous case failed, keep the dimension but evaluate the rest of the type.
    case DAE.T_ARRAY(ty, {dim}, ts)
      algorithm
        ty := evaluateFuncArgTypeDims(ty, inEnv, inCache);
      then
        DAE.T_ARRAY(ty, {dim}, ts);

    case ty as DAE.T_TUPLE()
      algorithm
        ty.types := List.map2(ty.types, evaluateFuncArgTypeDims, inEnv, inCache);
      then ty;

    else inType;

  end matchcontinue;
end evaluateFuncArgTypeDims;

protected function createActualFunctype
"Creates the actual function type of a CALL expression, used for error messages.
 This type is only created if checkTypes is false."
  input DAE.Type tp;
  input list<Slot> slots;
  input Boolean checkTypes;
  output DAE.Type outTp = tp;
algorithm
  outTp := match(outTp, checkTypes)
    local
      DAE.TypeSource ts;
      list<DAE.FuncArg> slotParams,params;
      DAE.Type restype;
      DAE.FunctionAttributes functionAttributes;

    case (_, true) then tp;

    // When not checking types, create function type by looking at the filled slots
    case (DAE.T_FUNCTION(), _)
      algorithm
        outTp.funcArg := funcArgsFromSlots(slots);
      then
        outTp;

  end match;
end createActualFunctype;

protected function slotsVectorizable
"author: PA
  This function checks all vectorized array dimensions in the slots and
  confirms that they all are of same dimension,or no dimension, i.e. not
  vectorized. The uniform vectorized array dimension is returned."
  input list<Slot> inSlots;
  input SourceInfo info;
  output DAE.Dimensions outDims;
algorithm
  outDims := matchcontinue(inSlots)
    local
      DAE.Dimensions ad;
      list<Slot> rest;
      DAE.Exp exp;
      String name;

    case {} then {};

    case SLOT(defaultArg = DAE.FUNCARG(name=name), arg = SOME(exp), dims = (ad as (_ :: _))) :: rest
      algorithm
        sameSlotsVectorizable(rest, ad, name, exp, info);
      then
        ad;

    case SLOT(dims = {}) :: rest then slotsVectorizable(rest, info);

    else
      algorithm
        true := Flags.isSet(Flags.FAILTRACE);
        Debug.trace("-slots_vectorizable failed\n");
      then
        fail();
  end matchcontinue;
end slotsVectorizable;

protected function sameSlotsVectorizable
"author: PA
  This function succeds if all slots in the list either has the array
  dimension as given by the second argument or no array dimension at all.
  The array dimension must match both in dimension size and number of
  dimensions."
  input list<Slot> inSlots;
  input DAE.Dimensions inDims;
  input String name;
  input DAE.Exp exp;
  input SourceInfo info;
algorithm
  _ := match inSlots
    local
      DAE.Dimensions slot_ad;
      list<Slot> rest;
      DAE.Exp exp2;
      String name2;

    // Array dims must match.
    case (SLOT(defaultArg = DAE.FUNCARG(name=name2), arg = SOME(exp2), dims = (slot_ad as (_ :: _))) :: rest)
      algorithm
        sameArraydimLst(inDims, name, exp, slot_ad, name2, exp2, info);
        sameSlotsVectorizable(rest, inDims, name, exp, info);
      then
        ();

    // Empty array dims matches too.
    case SLOT(dims = {}) :: rest
      algorithm
        sameSlotsVectorizable(rest, inDims, name, exp, info);
      then
        ();

    case {} then ();
  end match;
end sameSlotsVectorizable;

protected function sameArraydimLst
"author: PA
  Helper function to sameSlotsVectorizable. "
  input DAE.Dimensions inDims1;
  input String name1;
  input DAE.Exp exp1;
  input DAE.Dimensions inDims2;
  input String name2;
  input DAE.Exp exp2;
  input SourceInfo info;
algorithm
  _:= matchcontinue (inDims2, inDims2)
    local
      Integer i1,i2;
      DAE.Dimensions ads1,ads2;
      DAE.Exp e1,e2;
      DAE.Dimension ad1,ad2;
      String str1,str2,str3,str4,str;

    case (DAE.DIM_INTEGER(integer = i1) :: ads1,
          DAE.DIM_INTEGER(integer = i2) :: ads2)
      algorithm
        true := intEq(i1, i2);
        sameArraydimLst(ads1, name1, exp1, ads2, name2, exp2, info);
      then
        ();

    case (DAE.DIM_UNKNOWN() :: ads1, DAE.DIM_UNKNOWN() :: ads2)
      algorithm
        sameArraydimLst(ads1, name1, exp1, ads2, name2, exp2, info);
      then
        ();

    case (DAE.DIM_EXP(e1) :: ads1, DAE.DIM_EXP(e2) :: ads2)
      algorithm
        true := Expression.expEqual(e1,e2);
        sameArraydimLst(ads1, name1, exp1, ads2, name2, exp2, info);
      then
        ();

    case ({}, {}) then ();

    case (ad1 :: _, ad2 :: _)
      algorithm
        str1 := ExpressionDump.printExpStr(exp1);
        str2 := ExpressionDump.printExpStr(exp2);
        str3 := ExpressionDump.dimensionString(ad1);
        str4 := ExpressionDump.dimensionString(ad2);
        Error.addSourceMessage(Error.VECTORIZE_CALL_DIM_MISMATCH, {name1,str1,name2,str2,str3,str4}, info);
      then
        fail();

  end matchcontinue;
end sameArraydimLst;

protected function getProperties
"This function creates a Properties object from a DAE.Type and a
  DAE.TupleConst value."
  input DAE.Type inType;
  input DAE.TupleConst inTupleConst;
  output DAE.Properties outProperties;
algorithm
  outProperties := match(inType,inTupleConst)
    local
      DAE.Type tt,t,ty;
      DAE.TupleConst const;
      DAE.Const b;
      String tystr,conststr;

    // At least two elements in the type list, this is a tuple. LS: Tuples are fixed before here
    case (tt as DAE.T_TUPLE(),const) then DAE.PROP_TUPLE(tt,const);

    // One type, this is a tuple with one element. The resulting properties is then identical to that of a single expression.
    case (t,DAE.TUPLE_CONST(tupleConstLst = (DAE.SINGLE_CONST(const = b) :: {}))) then DAE.PROP(t,b);
    case (t,DAE.TUPLE_CONST(tupleConstLst = (DAE.SINGLE_CONST(const = b) :: {}))) then DAE.PROP(t,b);
    case (t,DAE.SINGLE_CONST(const = b)) then DAE.PROP(t,b);

    // failure
    case (ty,const)
      algorithm
        true := Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Static.getProperties failed: ");
        tystr := Types.unparseType(ty);
        conststr := Types.printTupleConstStr(const);
        Debug.trace(tystr);
        Debug.trace(", ");
        Debug.traceln(conststr);
      then
        fail();

  end match;
end getProperties;

protected function elabConsts "author: PR
  This just splits the properties list into a type list and a const list.
  LS: Changed to take a Type, which is the functions return type.
  LS: Update: const is derived from the input arguments and sent here."
  input DAE.Type inType;
  input DAE.Const inConst;
  output DAE.TupleConst outTupleConst;
algorithm
  outTupleConst := match(inType,inConst)
    local
      list<DAE.TupleConst> consts;
      list<DAE.Type> tys;
      DAE.Const c;
      DAE.Type ty;

    case (DAE.T_TUPLE(types = tys), c)
      equation
        consts = checkConsts(tys, c);
      then
        DAE.TUPLE_CONST(consts);

    // LS: If not a tuple then one normal type, T_INTEGER etc, but we make a list of types
    // with one element and call the same check_consts, so that we always have DAE.TUPLE_CONST as result
    case (ty, c)
      equation
        consts = checkConsts({ty}, c);
      then
        DAE.TUPLE_CONST(consts);

  end match;
end elabConsts;

protected function checkConsts
"LS: Changed to take a Type list, which is the functions return type. Only
   for functions returning a tuple
  LS: Update: const is derived from the input arguments and sent here "
  input list<DAE.Type> inTypes;
  input DAE.Const inConst;
  output list<DAE.TupleConst> outTupleConsts;
algorithm
  outTupleConsts := list(checkConst(ty, inConst) for ty in inTypes);
end checkConsts;

protected function checkConst "author: PR
   At the moment this make all outputs non cons.
  All ouputs should be checked in the function body for constness.
  LS: but it says true?
  LS: Adapted to check one type instead of funcarg, since it just checks
  return type
  LS: Update: const is derived from the input arguments and sent here"
  input DAE.Type inType;
  input DAE.Const c;
  output DAE.TupleConst outTupleConst;
algorithm
  outTupleConst := match inType
    case DAE.T_TUPLE()
      equation
        Error.addInternalError("No support for tuples built by tuples", sourceInfo());
      then fail();

    else DAE.SINGLE_CONST(c);
  end match;
end checkConst;

protected function splitProps
  "Splits the properties list into the separated types list and const list."
  input list<DAE.Properties> inProperties;
  output list<DAE.Type> outTypes = {};
  output list<DAE.TupleConst> outConsts = {};
protected
  DAE.Type ty;
  DAE.Const c;
  DAE.TupleConst tc;
algorithm
  for prop in listReverse(inProperties) loop
    tc := match prop
      case DAE.PROP(type_ = ty, constFlag = c) then DAE.SINGLE_CONST(c);
      case DAE.PROP_TUPLE(type_ = ty, tupleConst = tc) then tc;
    end match;

    outTypes := ty :: outTypes;
    outConsts := tc :: outConsts;
  end for;
end splitProps;

protected function getTypes
"This function returns the types of a DAE.FuncArg list."
  input list<DAE.FuncArg> farg;
  output list<DAE.Type> outTypes;
algorithm
  outTypes := list(Types.funcArgType(arg) for arg in farg);
end getTypes;

protected function elabInputArgs
  "This function_ elaborates on a number of expressions and_ matches them to a
   number of `DAE.Var\' objects, applying type_ conversions on the expressions
   when necessary to match the type_ of the DAE.Var.

   Positional arguments and named arguments are filled in the argument slots as:
     1. Positional arguments fill the first slots according to their position.
     2. Named arguments fill slots with the same name as the named argument.
     3. Unfilled slots are checked so that they have default values, otherwise error."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input list<Slot> inSlots;
  input Boolean inOnlyOneFunction;
  input Boolean inCheckTypes "if true, check types";
  input Boolean inImplicit;
  input IsExternalObject isExternalObject;
  input Option<GlobalScript.SymbolTable> inST;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  input DAE.Type inFuncType "Used to determine which arguments are structural. We will evaluate them later to figure if they are used in dimensions. So we evaluate them here to get a more optimised DAE";
  input Absyn.Path inPath;
  output FCore.Cache outCache = inCache;
  output list<DAE.Exp> outExps;
  output list<Slot> outSlots = inSlots;
  output list<DAE.Const> outConsts;
  output InstTypes.PolymorphicBindings outPolymorphicBindings = {};
protected
  list<DAE.FuncArg> fargs;
  list<DAE.Const> consts1, consts2;
algorithm
  // Empty function call, e.g. foo(), is always constant.
  // adrpo 2010-11-09: TODO! FIXME! This is not always true, RecordCall() can
  // contain DEFAULT bindings that are param.
  if listEmpty(inPosArgs) and listEmpty(inNamedArgs) then
    outConsts := {DAE.C_CONST()};
  else
    fargs := funcArgsFromSlots(inSlots);

    // Elaborate positional arguments.
    (outCache, outSlots, consts1, outPolymorphicBindings) :=
      elabPositionalInputArgs(outCache, inEnv, inPosArgs, fargs, outSlots,
        inOnlyOneFunction, inCheckTypes, inImplicit, isExternalObject,
        outPolymorphicBindings, inST, inPrefix, inInfo, inPath);

    // Elaborate named arguments.
    (outCache, outSlots, consts2, outPolymorphicBindings) :=
      elabNamedInputArgs(outCache, inEnv, inNamedArgs, fargs, outSlots,
        inOnlyOneFunction, inCheckTypes, inImplicit, isExternalObject,
        outPolymorphicBindings, inST, inPrefix, inInfo, inPath);

    outConsts := listAppend(consts1, consts2);
  end if;

  (outCache, outSlots) := evaluateStructuralSlots(outCache, inEnv, outSlots, inFuncType);
  outExps := slotListArgs(outSlots);
end elabInputArgs;

protected function makeEmptySlots
  "Creates a list of empty slots given a list of function parameters."
  input list<DAE.FuncArg> inArgs;
  output list<Slot> outSlots;
algorithm
  outSlots := List.mapFold(inArgs, makeEmptySlot, 1);
end makeEmptySlots;

protected function makeEmptySlot
  input DAE.FuncArg inArg;
  input Integer inIndex;
  output Slot outSlot;
  output Integer outIndex;
algorithm
  outSlot := SLOT(inArg, false, NONE(), {}, inIndex, SLOT_NOT_EVALUATED);
  outIndex := inIndex + 1;
end makeEmptySlot;

protected function funcArgsFromSlots
  "Converts a list of Slot to a list of FuncArg."
  input list<Slot> inSlots;
  output list<DAE.FuncArg> outFuncArgs;
algorithm
  outFuncArgs := list(funcArgFromSlot(slot) for slot in inSlots);
end funcArgsFromSlots;

protected function funcArgFromSlot
  input Slot inSlot;
  output DAE.FuncArg outFuncArg;
algorithm
  SLOT(defaultArg = outFuncArg) := inSlot;
end funcArgFromSlot;

protected function complexTypeFromSlots
  "Creates an DAE.T_COMPLEX type from a list of slots.
   Used to create type of record constructors "
  input list<Slot> inSlots;
  input ClassInf.State complexClassType;
  output DAE.Type outType;
protected
  String id;
  DAE.Type ty;
  list<DAE.Var> vars = {};
algorithm
  for slot in inSlots loop
    SLOT(defaultArg = DAE.FUNCARG(name = id, ty = ty)) := slot;
    vars := Expression.makeVar(id, Types.simplifyType(ty)) :: vars;
  end for;

  vars := listReverse(vars);
  outType := DAE.T_COMPLEX(complexClassType, vars, NONE(), DAE.emptyTypeSource);
end complexTypeFromSlots;

protected function slotListArgs
  "Gets the argument expressions from a list of slots."
  input list<Slot> inSlots;
  output list<DAE.Exp> outArgs;
algorithm
  outArgs := List.filterMap(inSlots, slotArg);
end slotListArgs;

protected function slotArg
  "Gets the argument from a slot."
  input Slot inSlot;
  output DAE.Exp outArg;
algorithm
  SLOT(arg = SOME(outArg)) := inSlot;
end slotArg;

protected function fillGraphicsDefaultSlots
  "This function takes a slot list and a class definition of a function
  and fills  default values into slots which have not been filled.

  Special case for graphics exps"
  input FCore.Cache inCache;
  input list<Slot> inSlots;
  input SCode.Element inClass;
  input FCore.Graph inEnv;
  input Boolean inImplicit;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output list<Slot> outSlots = {};
  output list<DAE.Const> outConsts = {};
  output InstTypes.PolymorphicBindings outPolymorphicBindings = {};
protected
  Boolean filled;
  Absyn.Exp e;
  DAE.Exp exp;
  String id;
  DAE.FuncArg defarg;
  DAE.Type ty;
  DAE.Const c;
algorithm
  for slot in inSlots loop
    SLOT(slotFilled = filled) := slot;

    // Try to fill the slot if it's not yet filled.
    if not filled then
      slot := matchcontinue slot
        case SLOT(defaultArg = defarg as DAE.FUNCARG())
          algorithm
            SCode.COMPONENT(modifications = SCode.MOD(binding = SOME(e))) :=
              SCode.getElementNamed(defarg.name, inClass);

            (outCache, exp, DAE.PROP(ty, c), _) :=
              elabExpInExpression(outCache, inEnv, e, inImplicit, NONE(), true, inPrefix, inInfo);

            (exp, _, outPolymorphicBindings) := Types.matchTypePolymorphic(exp,
              ty, defarg.ty, FGraph.getGraphPathNoImplicitScope(inEnv), outPolymorphicBindings, false);

            true := Types.constEqualOrHigher(c, defarg.const);
            outConsts := c :: outConsts;

            slot.slotFilled := true;
            slot.arg := SOME(exp);
          then
            slot;

        else slot;
      end matchcontinue;
    end if;

    outSlots := slot :: outSlots;
  end for;

  outSlots := listReverse(outSlots);
  outConsts := listReverse(outConsts);
end fillGraphicsDefaultSlots;

protected function printSlotsStr
  "prints the slots to a string"
  input list<Slot> inSlots;
  output String outString;
algorithm
  outString := match inSlots
    local
      Boolean filled;
      String farg_str,filledStr,str,s,s1,s2,res;
      list<String> str_lst;
      DAE.FuncArg farg;
      Option<DAE.Exp> exp;
      DAE.Dimensions ds;
      list<Slot> xs;

    case SLOT(defaultArg = farg,slotFilled = filled,arg = exp,dims = ds) :: xs
      algorithm
        farg_str := Types.printFargStr(farg);
        filledStr := if filled then "filled" else "not filled";
        str := Dump.getOptionStr(exp, ExpressionDump.printExpStr);
        str_lst := List.map(ds, ExpressionDump.dimensionString);
        s := stringDelimitList(str_lst, ", ");
        s1 := stringAppendList({"SLOT(",farg_str,", ",filledStr,", ",str,", [",s,"])\n"});
        s2 := printSlotsStr(xs);
        res := stringAppend(s1, s2);
      then
        res;

    case {} then "";

  end match;
end printSlotsStr;

protected uniontype IsExternalObject
  record IS_EXTERNAL_OBJECT_MODEL_SCOPE end IS_EXTERNAL_OBJECT_MODEL_SCOPE;
  record NOT_EXTERNAL_OBJECT_MODEL_SCOPE end NOT_EXTERNAL_OBJECT_MODEL_SCOPE;
end IsExternalObject;

protected function evalExternalObjectInput
  "External Object requires us to construct before initialization for good
   results. So try to evaluate the inputs."
  input IsExternalObject isExternalObject;
  input DAE.Type ty;
  input DAE.Const const;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
algorithm
  (outCache,outExp) := matchcontinue isExternalObject
    local
      String str;
      Values.Value val;

    case NOT_EXTERNAL_OBJECT_MODEL_SCOPE()
      then (inCache,inExp);

    case _
      algorithm
        true := Types.isParameterOrConstant(const);
        false := Expression.isConst(inExp);
        (outCache, val, _) := Ceval.ceval(inCache, inEnv, inExp, false, NONE(), Absyn.MSG(info), 0);
        outExp := ValuesUtil.valueExp(val);
      then
        (outCache,outExp);

    case _
      algorithm
        true := Types.isParameterOrConstant(const) or Types.isExternalObject(ty) or Expression.isConst(inExp);
      then
        (inCache,inExp);

    else
      algorithm
        false := Types.isParameterOrConstant(const);
        str := ExpressionDump.printExpStr(inExp);
        Error.addSourceMessage(Error.EVAL_EXTERNAL_OBJECT_CONSTRUCTOR, {str}, info);
      then
        (inCache,inExp);

  end matchcontinue;
end evalExternalObjectInput;

protected function elabPositionalInputArgs
"This function elaborates the positional input arguments of a function.
  A list of slots is filled from the beginning with types of each
  positional argument."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<DAE.FuncArg> inFuncArgs;
  input list<Slot> inSlots;
  input Boolean inOnlyOneFunction;
  input Boolean inCheckTypes "if true, check types";
  input Boolean inImplicit;
  input IsExternalObject isExternalObject;
  input InstTypes.PolymorphicBindings inPolymorphicBindings;
  input Option<GlobalScript.SymbolTable> inST;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  input Absyn.Path inPath;
  output FCore.Cache outCache = inCache;
  output list<Slot> outSlots = inSlots;
  output list<DAE.Const> outConsts = {};
  output InstTypes.PolymorphicBindings outPolymorphicBindings = inPolymorphicBindings;
protected
  DAE.FuncArg farg;
  list<DAE.FuncArg> farg_rest = inFuncArgs;
  DAE.Const c;
  Integer position = 1;
algorithm
  for arg in inPosArgs loop
    farg :: farg_rest := farg_rest;

    (outCache, outSlots, c, outPolymorphicBindings) :=
      elabPositionalInputArg(outCache, inEnv, arg, farg, position, outSlots,
          inOnlyOneFunction, inCheckTypes, inImplicit, isExternalObject,
          outPolymorphicBindings, inST, inPrefix, inInfo, inPath);

    position := position + 1;
    outConsts := c :: outConsts;
  end for;

  outConsts := listReverse(outConsts);
end elabPositionalInputArgs;

protected function elabPositionalInputArg
"This function elaborates the positional input arguments of a function.
  A list of slots is filled from the beginning with types of each
  positional argument."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input DAE.FuncArg farg;
  input Integer position;
  input list<Slot> inSlotLst;
  input Boolean onlyOneFunction;
  input Boolean checkTypes "if true, check types";
  input Boolean impl;
  input IsExternalObject isExternalObject;
  input InstTypes.PolymorphicBindings inPolymorphicBindings;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  input Absyn.Path path;
  output FCore.Cache outCache;
  output list<Slot> outSlotLst;
  output DAE.Const outConst;
  output InstTypes.PolymorphicBindings outPolymorphicBindings;
protected
  Integer numErrors = Error.getNumErrorMessages();
algorithm
  (outCache,outSlotLst,outConst,outPolymorphicBindings):=
  matchcontinue (inCache,inEnv,inExp,farg,position,inSlotLst,onlyOneFunction,checkTypes,impl,isExternalObject,inPolymorphicBindings,st,inPrefix,info,path,numErrors)
    local
      list<Slot> slots,slots_1,newslots;
      DAE.Exp e_1,e_2;
      DAE.Type t,vt;
      DAE.Const c1,c2;
      DAE.VarParallelism pr;
      DAE.Properties prop;
      list<DAE.Const> clist;
      FCore.Graph env;
      Absyn.Exp e;
      list<Absyn.Exp> es;
      list<DAE.FuncArg> vs;
      DAE.Dimensions ds;
      FCore.Cache cache;
      String id;
      DAE.Properties props;
      Prefix.Prefix pre;
      DAE.CodeType ct;
      InstTypes.PolymorphicBindings polymorphicBindings;
      String s1,s2,s3,s4,s5;

    case (cache, env, e, DAE.FUNCARG(name=id,ty = vt as DAE.T_CODE(ct,_),par=pr), _, slots, _, true, _, _, polymorphicBindings,_,pre,_,_,_)
      equation
        e_1 = elabCodeExp(e,cache,env,ct,st,info);
        slots_1 = fillSlot(DAE.FUNCARG(id,vt,DAE.C_VAR(),pr,NONE()), e_1, {}, slots,pre,info);
      then
        (cache,slots_1,DAE.C_VAR(),polymorphicBindings);

    // exact match
    case (cache, env, e, DAE.FUNCARG(name=id,ty=vt,par=pr), _, slots, _, true, _, _, polymorphicBindings,_,pre,_,_,_)
      equation
        (cache,e_1,props,_) = elabExpInExpression(cache,env, e, impl,st, true,pre,info);
        t = Types.getPropType(props);
        vt = Types.traverseType(vt, -1, Types.makeExpDimensionsUnknown);
        c1 = Types.propAllConst(props);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, vt, c1, cache, env, e_1, info);
        (e_2,_,polymorphicBindings) = Types.matchTypePolymorphic(e_1,t,vt,FGraph.getGraphPathNoImplicitScope(env),polymorphicBindings,false);
        slots_1 = fillSlot(DAE.FUNCARG(id,vt,c1,pr,NONE()), e_2, {}, slots,pre,info) "no vectorized dim" ;
      then
        (cache,slots_1,c1,polymorphicBindings);

    // check if vectorized argument
    case (cache, env, e, DAE.FUNCARG(name=id,ty=vt,par=pr), _, slots, _, true, _, _, polymorphicBindings,_,pre,_,_,_)
      equation
        (cache,e_1,props,_) = elabExpInExpression(cache,env, e, impl,st,true,pre,info);
        t = Types.getPropType(props);
        vt = Types.traverseType(vt, -1, Types.makeExpDimensionsUnknown);
        c1 = Types.propAllConst(props);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, vt, c1, cache, env, e_1, info);
        (e_2,_,ds,polymorphicBindings) = Types.vectorizableType(e_1, t, vt, FGraph.getGraphPathNoImplicitScope(env));
        slots_1 = fillSlot(DAE.FUNCARG(id,vt,c1,pr,NONE()), e_2, ds, slots, pre,info);
      then
        (cache,slots_1,c1,polymorphicBindings);

    // not checking types
    case (cache, env, e, DAE.FUNCARG(name=id,par=pr), _, slots, _, false, _, _, polymorphicBindings,_,pre,_,_,_)
      equation
        (cache,e_1,props,_) = elabExpInExpression(cache,env, e, impl,st,true,pre,info);
        t = Types.getPropType(props);
        c1 = Types.propAllConst(props);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, t, c1, cache, env, e_1, info);
        /* fill slot with actual type for error message*/
        slots_1 = fillSlot(DAE.FUNCARG(id,t,c1,pr,NONE()), e_1, {}, slots, pre,info);
      then
        (cache,slots_1,c1,polymorphicBindings);

    // check types and display error
    case (cache,env,e,DAE.FUNCARG(name=id,ty=vt),_,_, true /* 1 function */,true /* checkTypes */,_,_,_,_,pre,_,_,_)
      equation
        true = Error.getNumErrorMessages() == numErrors;
        (cache,e_1,prop,_) = elabExpInExpression(cache, env, e, impl,st, true,pre,info);
        s1 = intString(position);
        s2 = Absyn.pathStringNoQual(path);
        s3 = ExpressionDump.printExpStr(e_1);
        s4 = Types.unparseTypeNoAttr(Types.getPropType(prop));
        s5 = Types.unparseTypeNoAttr(vt);
        Error.addSourceMessage(Error.ARG_TYPE_MISMATCH, {s1,s2,id,s3,s4,s5}, info);
      then fail();

  end matchcontinue;
end elabPositionalInputArg;

protected function elabNamedInputArgs
"This function takes an Env, a NamedArg list, a DAE.FuncArg list and a
  Slot list.
  It builds up a new slot list and a list of elaborated expressions.
  If a slot is filled twice the function fails. If a slot is not filled at
  all and the
  value is not a parameter or a constant the function also fails."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input list<DAE.FuncArg> inTypesFuncArgLst;
  input list<Slot> inSlotLst;
  input Boolean onlyOneFunction;
  input Boolean checkTypes "if true, check types";
  input Boolean impl;
  input IsExternalObject isExternalObject;
  input InstTypes.PolymorphicBindings inPolymorphicBindings;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  input Absyn.Path path;
  output FCore.Cache outCache;
  output list<Slot> outSlotLst;
  output list<DAE.Const> outTypesConstLst;
  output InstTypes.PolymorphicBindings outPolymorphicBindings;
algorithm
  (outCache,outSlotLst,outTypesConstLst,outPolymorphicBindings) :=
  match (inCache,inEnv,inAbsynNamedArgLst,inTypesFuncArgLst,inSlotLst,onlyOneFunction,checkTypes,impl,isExternalObject,inPolymorphicBindings,st,inPrefix,info,path)
    local
      DAE.Exp e_1,e_2;
      DAE.Type t,vt;
      DAE.Const c1;
      DAE.VarParallelism pr;
      list<Slot> slots_1,newslots,slots;
      list<DAE.Const> clist;
      FCore.Graph env;
      String id, pre_str;
      Absyn.Exp e;
      Absyn.NamedArg na;
      list<Absyn.NamedArg> nas,narg;
      list<DAE.FuncArg> farg;
      DAE.CodeType ct;
      FCore.Cache cache;
      DAE.Dimensions ds;
      Prefix.Prefix pre;
      InstTypes.PolymorphicBindings polymorphicBindings;

    // the empty case
    case (cache,_,{},_,slots,_,_,_,_,_,_,_,_,_)
      then (cache,slots,{},inPolymorphicBindings);

    case (cache, env, na :: nas, farg, slots, _, _, _, _, polymorphicBindings, _, _, _, _)
      equation
        (cache,slots,c1,polymorphicBindings) =
        elabNamedInputArg(cache, env, na, farg, slots, onlyOneFunction, checkTypes, impl, isExternalObject, polymorphicBindings, st, inPrefix, info, path, Error.getNumErrorMessages());
        (cache,slots,clist,polymorphicBindings) =
        elabNamedInputArgs(cache, env, nas, farg, slots, onlyOneFunction, checkTypes, impl, isExternalObject, polymorphicBindings, st, inPrefix, info, path);
      then
        (cache,slots,c1::clist,polymorphicBindings);

  end match;
end elabNamedInputArgs;

protected function elabNamedInputArg
"This function takes an Env, a NamedArg list, a DAE.FuncArg list and a
  Slot list.
  It builds up a new slot list and a list of elaborated expressions.
  If a slot is filled twice the function fails. If a slot is not filled at
  all and the
  value is not a parameter or a constant the function also fails."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.NamedArg inNamedArg;
  input list<DAE.FuncArg> inTypesFuncArgLst;
  input list<Slot> inSlotLst;
  input Boolean onlyOneFunction;
  input Boolean checkTypes "if true, check types";
  input Boolean impl;
  input IsExternalObject isExternalObject;
  input InstTypes.PolymorphicBindings inPolymorphicBindings;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  input Absyn.Path path;
  input Integer numErrors;
  output FCore.Cache outCache;
  output list<Slot> outSlotLst;
  output DAE.Const outTypesConstLst;
  output InstTypes.PolymorphicBindings outPolymorphicBindings;
algorithm
  (outCache,outSlotLst,outTypesConstLst,outPolymorphicBindings) :=
  matchcontinue (inCache,inEnv,inNamedArg,inTypesFuncArgLst,inSlotLst,onlyOneFunction,checkTypes,impl,isExternalObject,inPolymorphicBindings,st,inPrefix,info,path,numErrors)
    local
      DAE.Exp e_1,e_2;
      DAE.Type t,vt;
      DAE.Const c1;
      DAE.VarParallelism pr;
      list<Slot> slots_1,newslots,slots;
      list<DAE.Const> clist;
      FCore.Graph env;
      String id, pre_str, str;
      Absyn.Exp e;
      list<Absyn.NamedArg> nas,narg;
      list<DAE.FuncArg> farg;
      DAE.CodeType ct;
      FCore.Cache cache;
      DAE.Dimensions ds;
      Prefix.Prefix pre;
      InstTypes.PolymorphicBindings polymorphicBindings;
      DAE.Properties prop;
      String s1,s2,s3,s4;

    case (cache, env, Absyn.NAMEDARG(argName = id,argValue = e), farg, slots, _, true, _, _, polymorphicBindings,_,pre,_,_,_)
      equation
        (vt as DAE.T_CODE(ty=ct)) = findNamedArgType(id, farg);
        pr = findNamedArgParallelism(id,farg);
        e_1 = elabCodeExp(e,cache,env,ct,st,info);
        slots_1 = fillSlot(DAE.FUNCARG(id,vt,DAE.C_VAR(),pr,NONE()), e_1, {}, slots,pre,info);
      then (cache,slots_1,DAE.C_VAR(),polymorphicBindings);

    // check types exact match
    case (cache,env,Absyn.NAMEDARG(argName = id,argValue = e),farg,slots,_,true,_,_,polymorphicBindings,_,pre,_,_,_)
      equation
        vt = findNamedArgType(id, farg);
        pr = findNamedArgParallelism(id,farg);
        (cache,e_1,DAE.PROP(t,c1),_) = elabExpInExpression(cache, env, e, impl,st, true,pre,info);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, t, c1, cache, env, e_1, info);
        (e_2,_,polymorphicBindings) = Types.matchTypePolymorphic(e_1,t,vt,FGraph.getGraphPathNoImplicitScope(env),polymorphicBindings,false);
        slots_1 = fillSlot(DAE.FUNCARG(id,vt,c1,pr,NONE()), e_2, {}, slots,pre,info);
      then (cache,slots_1,c1,polymorphicBindings);

    // check types vectorized argument
    case (cache,env,Absyn.NAMEDARG(argName = id,argValue = e),farg,slots,_,true,_,_,polymorphicBindings,_,pre,_,_,_)
      equation
        vt = findNamedArgType(id, farg);
        pr = findNamedArgParallelism(id,farg);
        (cache,e_1,DAE.PROP(t,c1),_) = elabExpInExpression(cache, env, e, impl,st, true,pre,info);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, t, c1, cache, env, e_1, info);
        (e_2,_,ds,polymorphicBindings) = Types.vectorizableType(e_1, t, vt, FGraph.getGraphPathNoImplicitScope(env));
        slots_1 = fillSlot(DAE.FUNCARG(id,vt,c1,pr,NONE()), e_2, ds, slots, pre,info);
      then (cache,slots_1,c1,polymorphicBindings);

    // do not check types
    case (cache,env,Absyn.NAMEDARG(argName = id,argValue = e),farg,slots,_,false,_,_,polymorphicBindings,_,pre,_,_,_)
      equation
        vt = findNamedArgType(id, farg);
        pr = findNamedArgParallelism(id,farg);
        (cache,e_1,DAE.PROP(t,c1),_) = elabExpInExpression(cache,env, e, impl,st,true,pre,info);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, t, c1, cache, env, e_1, info);
        slots_1 = fillSlot(DAE.FUNCARG(id,vt,c1,pr,NONE()), e_1, {}, slots,pre,info);
      then (cache,slots_1,c1,polymorphicBindings);

    case (_, _, Absyn.NAMEDARG(argName = id), farg, _, true /* only 1 function */, _, _, _, _,_,_,_,_,_)
      equation
        failure(_ = findNamedArgType(id, farg));
        s1 = Absyn.pathStringNoQual(path);
        Error.addSourceMessage(Error.NO_SUCH_ARGUMENT, {s1,id}, info);
      then fail();

    // failure
    case (cache,env,Absyn.NAMEDARG(argName = id,argValue = e),farg,_,true /* 1 function */,true /* checkTypes */,_,_,_,_,pre,_,_,_)
      equation
        true = Error.getNumErrorMessages() == numErrors;
        vt = findNamedArgType(id, farg);
        (cache,e_1,prop,_) = elabExpInExpression(cache, env, e, impl,st, true,pre,info);
        s1 = Absyn.pathStringNoQual(path);
        s2 = ExpressionDump.printExpStr(e_1);
        s3 = Types.unparseTypeNoAttr(Types.getPropType(prop));
        s4 = Types.unparseTypeNoAttr(vt);
        Error.addSourceMessage(Error.NAMED_ARG_TYPE_MISMATCH, {s1,id,s2,s3,s4}, info);
      then fail();
  end matchcontinue;
end elabNamedInputArg;

protected function findNamedArg
  input String inIdent;
  input list<DAE.FuncArg> inArgs;
  output DAE.FuncArg outArg;
protected
  String id;
algorithm
  for arg in inArgs loop
    DAE.FUNCARG(name = id) := arg;

    if id == inIdent then
      outArg := arg;
      return;
    end if;
  end for;
  fail();
end findNamedArg;

protected function findNamedArgType
  "This function takes an Ident and a FuncArg list, and returns the FuncArg
   which has  that identifier.
   Used for instance when looking up named arguments from the function type."
  input String inIdent;
  input list<DAE.FuncArg> inArgs;
  output DAE.Type outType;
algorithm
  DAE.FUNCARG(ty = outType) := findNamedArg(inIdent, inArgs);
end findNamedArgType;

protected function findNamedArgParallelism
  "This function takes an Ident and a FuncArg list, and returns the
   parallelism of the FuncArg which has  that identifier."
  input String inIdent;
  input list<DAE.FuncArg> inArgs;
  output DAE.VarParallelism outParallelism;
algorithm
  DAE.FUNCARG(par = outParallelism) := findNamedArg(inIdent, inArgs);
end findNamedArgParallelism;

protected function fillSlot
"This function takses a `FuncArg\' and an DAE.Exp and a Slot list and fills
  the slot holding the FuncArg, by setting the boolean value of the slot
  and setting the expression. The function fails if the slot is allready set."
  input DAE.FuncArg inFuncArg;
  input DAE.Exp inExp;
  input DAE.Dimensions inDims;
  input list<Slot> inSlotLst;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output list<Slot> outSlotLst = {};
protected
  String fa1, fa2, exp_str, c_str, pre_str;
  DAE.Type ty1, ty2;
  DAE.Const c1, c2;
  DAE.VarParallelism prl;
  Option<DAE.Exp> binding;
  Boolean filled;
  Integer idx, ses;
  Slot slot;
  list<Slot> rest_slots = inSlotLst;
algorithm
  DAE.FUNCARG(name = fa1, ty = ty1, const = c1) := inFuncArg;

  while not listEmpty(rest_slots) loop
    slot :: rest_slots := rest_slots;
    SLOT(defaultArg = DAE.FUNCARG(name = fa2)) := slot;

    // Check if this slot has the same name as the one we're looking for.
    if stringEq(fa1, fa2) then
      SLOT(defaultArg = DAE.FUNCARG(const = c2, par = prl, defaultBinding = binding),
        slotFilled = filled, idx = idx, evalStatus = ses) := slot;

      // Fail if the slot is already filled.
      if filled then
        pre_str := PrefixUtil.printPrefixStr3(inPrefix);
        Error.addSourceMessageAndFail(Error.FUNCTION_SLOT_ALLREADY_FILLED,
          {fa2, pre_str}, inInfo);
      end if;

      // Fail if the variability is wrong.
      if not Types.constEqualOrHigher(c1, c2) then
        exp_str := ExpressionDump.printExpStr(inExp);
        c_str := DAEUtil.constStrFriendly(c2);
        Error.addSourceMessageAndFail(Error.FUNCTION_SLOT_VARIABILITY,
          {fa1, exp_str, c_str}, inInfo);
      end if;

      // Found a valid slot, fill it and reconstruct the slot list.
      slot := SLOT(DAE.FUNCARG(fa2, ty1, c2, prl, binding), true, SOME(inExp), inDims, idx, ses);
      outSlotLst := listAppend(listReverse(outSlotLst), slot :: rest_slots);
      return;
    end if;

    outSlotLst := slot :: outSlotLst;
  end while;

  Error.addSourceMessageAndFail(Error.NO_SUCH_ARGUMENT, {"", fa1}, inInfo);
end fillSlot;

public function elabCref "
function: elabCref
  Elaborate on a component reference.  Check the type of the
  component referred to, and check if the environment contains
  either a constant binding for that variable, or if it contains an
  equation binding with a constant expression."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Boolean inImplicit "implicit instantiation";
  input Boolean performVectorization "true => generates vectorized expressions, {v[1],v[2],...}";
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output Option<tuple<DAE.Exp,DAE.Properties,DAE.Attributes>> res;
algorithm
  (outCache,res) := elabCref1(inCache,inEnv,inComponentRef,inImplicit,performVectorization,inPrefix,true,info);
end elabCref;

public function elabCrefNoEval "
  Some functions expect a DAE.ComponentRef back and use this instead of elabCref :)"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Boolean inImplicit "implicit instantiation";
  input Boolean performVectorization "true => generates vectorized expressions, {v[1],v[2],...}";
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.Attributes outAttributes;
algorithm
  (outCache, SOME((outExp, outProperties, outAttributes))) :=
    elabCref1(inCache,inEnv,inComponentRef,inImplicit,performVectorization,inPrefix,false,info);
end elabCrefNoEval;

protected function elabCref1 "
function: elabCref
  Elaborate on a component reference.  Check the type of the
  component referred to, and check if the environment contains
  either a constant binding for that variable, or if it contains an
  equation binding with a constant expression."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Boolean inImplicit "implicit instantiation";
  input Boolean performVectorization "true => generates vectorized expressions, {v[1],v[2],...}";
  input Prefix.Prefix inPrefix;
  input Boolean evalCref;
  input SourceInfo info;
  output FCore.Cache outCache;
  output Option<tuple<DAE.Exp,DAE.Properties,DAE.Attributes>> res;
algorithm
  (outCache,res) := matchcontinue (inCache,inEnv,inComponentRef,inImplicit,inPrefix)
    local
      DAE.ComponentRef c_1;
      DAE.Const const,const1,const2,constCref,constSubs;
      DAE.TypeSource tySource;
      DAE.Type t,origt, sub_ty;
      DAE.Type tt;
      DAE.Exp exp,exp1,exp2,crefExp,expASUB;
      FCore.Graph env;
      Absyn.ComponentRef c;
      FCore.Cache cache;
      Boolean impl,doVect,isBuiltinFn,isBuiltinFnOrInlineBuiltin,hasZeroSizeDim;
      DAE.Type et;
      String s,scope;
      InstTypes.SplicedExpData splicedExpData;
      Absyn.Path path,fpath;
      list<String> enum_lit_strs;
      String typeStr,id;
      DAE.ComponentRef expCref;
      Option<DAE.Const> forIteratorConstOpt;
      Prefix.Prefix pre;
      Absyn.Exp e;
      SCode.Element cl;
      DAE.FunctionBuiltin isBuiltin;
      DAE.Attributes attr;
      DAE.Binding binding "equation modification";

    // wildcard
    case (cache, _, Absyn.WILD(), _, _)
      equation
        t = DAE.T_ANYTYPE_DEFAULT;
        et = Types.simplifyType(t);
        crefExp = Expression.makeCrefExp(DAE.WILD(),et);
      then
        (cache,SOME((crefExp,DAE.PROP(t, DAE.C_VAR()),DAE.dummyAttrVar)));

    // Boolean => {false, true}
    case (cache, _, Absyn.CREF_IDENT(name = "Boolean"), _, _)
      equation
        exp = Expression.makeScalarArray({DAE.BCONST(false), DAE.BCONST(true)}, DAE.T_BOOL_DEFAULT);
        t = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(2)}, DAE.emptyTypeSource);
      then
        (cache, SOME((exp, DAE.PROP(t, DAE.C_CONST()), DAE.dummyAttrConst)));

    // MetaModelica arrays are only used in function context as IDENT, and at most one subscript
    // No vectorization is performed
    case (cache, env, Absyn.CREF_IDENT(name = id, subscripts = {Absyn.SUBSCRIPT(e)}), impl, pre)
      algorithm
        true := Config.acceptMetaModelicaGrammar();
        // Elaborate the cref without the subscript.
        (cache, SOME((exp1, DAE.PROP(t, const1), attr))) :=
          elabCref1(cache, env, Absyn.CREF_IDENT(id, {}), false, false, pre, evalCref, info);

        // Check that the type is a MetaModelica array, and get the element type.
        t := Types.metaArrayElementType(t);

        // Elaborate the subscript.
        (cache,exp2,DAE.PROP(sub_ty, const2),_) :=
          elabExpInExpression(cache,env,e,impl,NONE(),false,pre,info);

        // Unbox the subscript if it's boxed, since it will be converted to an
        // arrayGet/arrayUpdate in code generation.
        if Types.isMetaBoxedType(sub_ty) then
          sub_ty := Types.unboxedType(sub_ty);
          exp2 := DAE.UNBOX(exp2, sub_ty);
        end if;

        true := Types.isScalarInteger(sub_ty);
        const := Types.constAnd(const1,const2);
        exp := Expression.makeASUB(exp1,{exp2});
      then
        (cache, SOME((exp, DAE.PROP(t, const), attr)));

    // a normal cref
    case (cache, env, c, impl, pre)
      algorithm
        c := replaceEnd(c);
        env := if Absyn.crefIsFullyQualified(inComponentRef) then FGraph.topScope(inEnv) else inEnv;
        (cache,c_1,constSubs,hasZeroSizeDim) := elabCrefSubs(cache, env, inEnv, c, pre, Prefix.NOPRE(), impl, false, info);
        (cache,attr,t,binding,forIteratorConstOpt,splicedExpData) := Lookup.lookupVar(cache, env, c_1);
        // get the binding if is a constant
        (cache,exp,const,attr) := elabCref2(cache, env, c_1, attr, constSubs, forIteratorConstOpt, t, binding, performVectorization, splicedExpData, pre, evalCref, info);
        t := fixEnumerationType(t);
        (exp,const) := evaluateEmptyVariable(hasZeroSizeDim and evalCref,exp,t,const);
      then
        (cache,SOME((exp,DAE.PROP(t, const),attr)));

    // An enumeration type => array of enumeration literals.
    case (cache, env, c, _, _)
      equation
        c = replaceEnd(c);
        path = Absyn.crefToPath(c);
        (cache, cl as SCode.CLASS(restriction = SCode.R_ENUMERATION()), env) =
          Lookup.lookupClass(cache, env, path, false);
        typeStr = Absyn.pathLastIdent(path);
        path = FGraph.joinScopePath(env, Absyn.IDENT(typeStr));
        enum_lit_strs = SCode.componentNames(cl);
        (exp, t) = makeEnumerationArray(path, enum_lit_strs);
      then
        (cache,SOME((exp,DAE.PROP(t, DAE.C_CONST()),DAE.dummyAttrConst /* RO */)));

    // MetaModelica Partial Function
    case (cache, env, c, _, _)
      equation
        // true = Flags.isSet(Flags.FNPTR) or Config.acceptMetaModelicaGrammar();
        path = Absyn.crefToPath(c);
        // call the lookup function that removes errors when it fails!
        (cache, {t}) = lookupFunctionsInEnvNoError(cache, env, path, info);
        (isBuiltin,isBuiltinFn,path) = isBuiltinFunc(path,t);
        isBuiltinFnOrInlineBuiltin = not valueEq(DAE.FUNCTION_NOT_BUILTIN(),isBuiltin);
        tySource = Types.getTypeSource(t);
        // some builtin functions store {} there
        tySource = if isBuiltinFn then Types.mkTypeSource(SOME(path)) else tySource;
        tt = Types.setTypeSource(t, tySource);
        origt = tt;
        {fpath} = Types.getTypeSource(t);
        t = Types.makeFunctionPolymorphicReference(t);
        c = Absyn.pathToCref(fpath);
        expCref = ComponentReference.toExpCref(c);
        exp = Expression.makeCrefExp(expCref,DAE.T_FUNCTION_REFERENCE_FUNC(isBuiltinFnOrInlineBuiltin,origt,tySource));
        // This is not done by lookup - only elabCall. So we should do it here.
        (cache,Util.SUCCESS()) = instantiateDaeFunction(cache,env,path,isBuiltinFn,NONE(),true);
      then
        (cache,SOME((exp,DAE.PROP(t,DAE.C_VAR()),DAE.dummyAttrConst /* RO */)));

    // MetaModelica extension
    case (cache, _, Absyn.CREF_IDENT("NONE",{}), _, _)
      equation
        true = Config.acceptMetaModelicaGrammar();
        Error.addSourceMessage(Error.META_NONE_CREF, {}, info);
      then
        (cache,NONE());

    case (_, env, c, _, _)
      equation
        // enabled with +d=failtrace
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Static.elabCref failed: " +
          Dump.printComponentRefStr(c) + " in env: " +
          FGraph.printGraphPathStr(env));
        // Debug.traceln("ENVIRONMENT:\n" + FGraph.printGraphStr(env));
      then
        fail();

    /*
    // maybe we do have it but without a binding, so maybe we can actually type it!
    case (cache,env,c,impl,doVect,pre,info)
      equation
        failure((_,_,_) = elabCrefSubs(cache,env, c, pre, Prefix.NOPRE(),impl,info));
        id = Absyn.crefFirstIdent(c);
        (cache,DAE.TYPES_VAR(name, attributes, visibility, ty, binding, constOfForIteratorRange),
               SOME((cl as SCode.COMPONENT(n, pref, SCode.ATTR(arrayDims = ad), Absyn.TPATH(tpath, _),m,comment,cond,info),cmod)),instStatus,_)
          = Lookup.lookupIdent(cache, env, id);
        print("Static: cref:" + Absyn.printComponentRefStr(c) + " component first ident:\n" + SCodeDump.unparseElementStr(cl) + "\n");
        (cache, cl, env) = Lookup.lookupClass(cache, env, tpath, false);
        print("Static: cref:" + Absyn.printComponentRefStr(c) + " class component first ident:\n" + SCodeDump.unparseElementStr(cl) + "\n");
      then
        (cache,NONE());*/

    case (cache, env, c, impl, pre)
      equation
        failure((_,_,_,_) = elabCrefSubs(cache,env, env,c, pre, Prefix.NOPRE(),impl,false,info));
        s = Dump.printComponentRefStr(c);
        scope = FGraph.printGraphPathStr(env);
        // No need to add prefix info since problem only depends on the scope?
        Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR, {s,scope}, info);
      then
        (cache,NONE());
  end matchcontinue;
end elabCref1;

protected function lookupFunctionsInEnvNoError
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  (outCache, outTypesTypeLst) := matchcontinue(inCache, inEnv, inPath, inInfo)

    case (_, _, _, _)
      equation
        ErrorExt.setCheckpoint("Static.lookupFunctionsInEnvNoError");
        (outCache, outTypesTypeLst) = Lookup.lookupFunctionsInEnv(inCache, inEnv, inPath, inInfo);
        // rollback lookup errors!
        ErrorExt.rollBack("Static.lookupFunctionsInEnvNoError");
      then
        (outCache, outTypesTypeLst);

    else
      equation
        // rollback lookup errors!
        ErrorExt.rollBack("Static.lookupFunctionsInEnvNoError");
      then
        fail();
  end matchcontinue;
end lookupFunctionsInEnvNoError;


protected function evaluateEmptyVariable
  "A variable with a 0-length dimension can be evaluated.
  This is good to do because otherwise the C-code contains references to non-existing variables"
  input Boolean hasZeroSizeDim;
  input DAE.Exp inExp;
  input DAE.Type ty;
  input DAE.Const c;
  output DAE.Exp oexp;
  output DAE.Const oc;
algorithm
  (oexp,oc) := matchcontinue (hasZeroSizeDim,inExp,ty,c)
    local
      Boolean sc,a;
      DAE.Type et;
      list<DAE.Subscript> ss;
      DAE.ComponentRef cr;
      list<DAE.Exp> sub;
      DAE.Exp exp;

    case (true,DAE.ASUB(sub=sub),_,_)
      equation
        // TODO: Use a DAE.ERROR() or something if this has subscripts?
        a = Types.isArray(ty);
        sc = boolNot(a);
        et = Types.simplifyType(ty);
        exp = DAE.ARRAY(et,sc,{});
        exp = Expression.makeASUB(exp,sub);
      then (exp,c);

    case (true,DAE.CREF(componentRef=cr),_,_)
      equation
        a = Types.isArray(ty);
        sc = boolNot(a);
        et = Types.simplifyType(ty);
        {} = ComponentReference.crefLastSubs(cr);
        exp = DAE.ARRAY(et,sc,{});
      then (exp,c);

    case (true,DAE.CREF(componentRef=cr),_,_)
      equation
        // TODO: Use a DAE.ERROR() or something if this has subscripts?
        a = Types.isArray(ty);
        sc = boolNot(a);
        et = Types.simplifyType(ty);
        (ss as _::_) = ComponentReference.crefLastSubs(cr);
        exp = DAE.ARRAY(et,sc,{});
        exp = Expression.makeASUB(exp,List.map(ss,Expression.getSubscriptExp));
      then (exp,c);

    else (inExp,c);
  end matchcontinue;
end evaluateEmptyVariable;

public function fixEnumerationType
"Removes the index from an enumeration type."
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := matchcontinue(inType)
    local
      Absyn.Path p;
      list<String> n;
      list<DAE.Var> v, al;
      DAE.TypeSource ts;

    case DAE.T_ENUMERATION(index = SOME(_), path = p, names = n, literalVarLst = v, attributeLst = al, source = ts)
      then
        DAE.T_ENUMERATION(NONE(), p, n, v, al, ts);

    else inType;
  end matchcontinue;
end fixEnumerationType;

public function applySubscriptsVariability
  "Takes the variability of a variable and the constness of it's subscripts and
  determines if the varibility of the variable should be raised. I.e.:
    parameter with variable subscripts => variable
    constant with variable subscripts => variable
    constant with parameter subscripts => parameter"
  input SCode.Variability inVariability;
  input DAE.Const inSubsConst;
  output SCode.Variability outVariability;
algorithm
  outVariability := match(inVariability, inSubsConst)
    case (SCode.PARAM(), DAE.C_VAR()) then SCode.VAR();
    case (SCode.CONST(), DAE.C_VAR()) then SCode.VAR();
    case (SCode.CONST(), DAE.C_PARAM()) then SCode.PARAM();
    else inVariability;
  end match;
end applySubscriptsVariability;

public function makeEnumerationArray
  "Expands an enumeration type to an array of it's enumeration literals."
  input Absyn.Path enumTypeName;
  input list<String> enumLiterals;
  output DAE.Exp enumArray;
  output DAE.Type enumArrayType;

protected
  list<DAE.Exp> enum_lit_expl;
  Integer sz;
  DAE.Type ety;
algorithm
  enum_lit_expl := Expression.makeEnumLiterals(enumTypeName, enumLiterals);
  sz := listLength(enumLiterals);
  ety := DAE.T_ARRAY(DAE.T_ENUMERATION(NONE(), enumTypeName, enumLiterals, {}, {}, DAE.emptyTypeSource),
                     {DAE.DIM_ENUM(enumTypeName, enumLiterals, sz)},
                     DAE.emptyTypeSource);
  enumArray := DAE.ARRAY(ety, true, enum_lit_expl);
  enumArrayType := ety;
end makeEnumerationArray;

protected function fillCrefSubscripts
"This is a helper function to elab_cref2.
  It investigates a DAE.Type in order to fill the subscript lists of a
  component reference. For instance, the name a.b with the type array of
  one dimension will become a.b[:]."
  input DAE.ComponentRef inComponentRef;
  input DAE.Type inType;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue (inComponentRef,inType/*,slicedExp*/)
    local
      DAE.ComponentRef e,cref_1,cref;
      DAE.Type t;
      list<DAE.Subscript> subs_1,subs;
      String id;
      DAE.Type ty2;
    // no subscripts
    case ((e as DAE.CREF_IDENT(subscriptLst = {})),_) then e;

    // simple ident with non-empty subscripts
    case ((DAE.CREF_IDENT(ident = id, identType = ty2, subscriptLst = subs)),t)
      equation
        subs_1 = fillSubscripts(subs, t);
      then
        ComponentReference.makeCrefIdent(id,ty2,subs_1);
    // qualified ident with non-empty subscrips
    case ((DAE.CREF_QUAL(ident = id,subscriptLst = subs,componentRef = cref,identType = ty2 )),t)
      equation
        subs = fillSubscripts(subs, ty2);
        t = stripPrefixType(t, ty2);
        cref_1 = fillCrefSubscripts(cref, t);
      then
        ComponentReference.makeCrefQual(id,ty2,subs,cref_1);
  end matchcontinue;
end fillCrefSubscripts;

protected function stripPrefixType
  input DAE.Type inType;
  input DAE.Type inPrefixType;
  output DAE.Type outType;
algorithm
  outType := match(inType, inPrefixType)
    local
      DAE.Type t, pt;

    case (DAE.T_ARRAY(ty = t), DAE.T_ARRAY(ty = pt)) then stripPrefixType(t, pt);
    else inType;
  end match;
end stripPrefixType;

protected function fillSubscripts
"Helper function to fillCrefSubscripts."
  input list<DAE.Subscript> inExpSubscriptLst;
  input DAE.Type inType;
  output list<DAE.Subscript> outExpSubscriptLst;
algorithm
  outExpSubscriptLst := matchcontinue (inExpSubscriptLst,inType)
    local
      list<DAE.Subscript> subs;
      DAE.Dimensions dims;

    // an array
    case (_, DAE.T_ARRAY())
      equation
        subs = List.fill(DAE.WHOLEDIM(), listLength(Types.getDimensions(inType)));
        subs = List.stripN(subs, listLength(inExpSubscriptLst));
        subs = listAppend(inExpSubscriptLst, subs);
      then
        subs;

    // not an array type!
    else inExpSubscriptLst;

  end matchcontinue;
end fillSubscripts;

protected function elabCref2
  "This function does some more processing of crefs, like replacing a constant
   with its value and vectorizing a non-constant."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inCref;
  input DAE.Attributes inAttributes;
  input DAE.Const constSubs;
  input Option<DAE.Const> inIteratorConst;
  input DAE.Type inType;
  input DAE.Binding inBinding;
  input Boolean inVectorize "true => vectorized expressions";
  input InstTypes.SplicedExpData splicedExpData;
  input Prefix.Prefix inPrefix;
  input Boolean evalCref;
  input SourceInfo info;
  output FCore.Cache outCache = inCache;
  output DAE.Exp outExp;
  output DAE.Const outConst;
  output DAE.Attributes outAttributes;
protected
  SCode.Variability var = DAEUtil.getAttrVariability(inAttributes);
algorithm
  (outExp, outConst, outAttributes) := matchcontinue(var, inType, inBinding, splicedExpData)
    local
      DAE.Type ty, expTy, idTy, expIdTy;
      DAE.ComponentRef cr, subCr1, subCr2;
      DAE.Exp e, index;
      Option<DAE.Exp> sexp;
      Values.Value v;
      FCore.Graph env;
      DAE.Const const;
      String s, str, scope, pre_str;
      DAE.Binding binding;
      Integer i;
      Absyn.Path p;
      DAE.Attributes attr;
      list<DAE.Subscript> subsc;
      DAE.Subscript slice;

    // If type not yet determined, component must be referencing itself.
    // Use the variability as the constness.
    case (_, DAE.T_UNKNOWN(), _, _)
      algorithm
        expTy := Types.simplifyType(inType);
        const := Types.variabilityToConst(var);
      then
        (DAE.CREF(inCref, expTy), const, inAttributes);

    // adrpo: report a warning if the binding came from a start value!
    // lochel: I moved the warning to the back end for now
    case (SCode.PARAM(), _, DAE.EQBOUND(source = DAE.BINDING_FROM_START_VALUE()), _)
      algorithm
        true := Types.getFixedVarAttributeParameterOrConstant(inType);
        // s := ComponentReference.printComponentRefStr(inCref);
        // pre_str := PrefixUtil.printPrefixStr2(inPrefix);
        // s := pre_str + s;
        // str := DAEUtil.printBindingExpStr(inBinding);
        // Error.addSourceMessage(Error.UNBOUND_PARAMETER_WITH_START_VALUE_WARNING, {s,str}, info); // Don't add source info here... Many models give multiple errors that are not filtered out
        binding := DAEUtil.setBindingSource(inBinding, DAE.BINDING_FROM_DEFAULT_VALUE());
        (outCache, e, const, attr) := elabCref2(outCache, inEnv, inCref, inAttributes, constSubs,
          inIteratorConst, inType, binding, inVectorize, splicedExpData, inPrefix, evalCref, info);
      then
        (e, const, attr);

    // an enumeration literal -> simplify to a literal expression
    case (SCode.CONST(), DAE.T_ENUMERATION(index = SOME(i), path = p), _, _) guard(evalCref)
      algorithm
        p := Absyn.joinPaths(p, ComponentReference.crefLastPath(inCref));
      then
        (DAE.ENUM_LITERAL(p, i), DAE.C_CONST(), inAttributes);

    // Don't evaluate constants if evalCref is false.
    case (SCode.CONST(), _, _, _) guard(not evalCref)
      algorithm
        expTy := Types.simplifyType(inType);
      then
        (Expression.makeCrefExp(inCref, expTy), DAE.C_CONST(), inAttributes);

    // a constant with variable subscript
    case (SCode.CONST(), _, _, InstTypes.SPLICEDEXPDATA()) guard(Types.isVar(constSubs))
      algorithm
        cr := ComponentReference.crefStripLastSubs(inCref);
        subsc := ComponentReference.crefLastSubs(inCref);
        (outCache, v) := Ceval.cevalCref(outCache, inEnv, cr, false, Absyn.MSG(info), 0);
        e := ValuesUtil.valueExp(v);
        e := Expression.makeASUB(e, list(Expression.getSubscriptExp(sub) for sub in subsc));
      then
        (e, DAE.C_VAR(), inAttributes);

    // a constant -> evaluate binding
    case (SCode.CONST(), _, binding, InstTypes.SPLICEDEXPDATA(_, idTy))
      algorithm
        true := Types.equivtypes(inType, idTy);

        try
          (outCache, v) := Ceval.cevalCrefBinding(outCache, inEnv, inCref, binding, false, Absyn.MSG(info), 0);
          e := ValuesUtil.valueExp(v);
        else
          // Couldn't evaluate binding, replace the cref with the unevaluated binding.
          SOME(e) := DAEUtil.bindingExp(binding);

          e := Expression.makeASUB(e,
            list(Expression.getSubscriptExp(sub) for sub in ComponentReference.crefLastSubs(inCref)));
        end try;

        const := DAE.C_CONST(); //Types.constAnd(DAE.C_CONST(), constSubs);
      then
        (e, const, inAttributes);

    // a constant with some for iterator constness -> don't constant evaluate
    case (SCode.CONST(), _, _, _) guard(isSome(inIteratorConst))
      algorithm
        expTy := Types.simplifyType(inType);
      then
        (Expression.makeCrefExp(inCref, expTy), DAE.C_CONST(), inAttributes);

    // a constant with a binding
    case (SCode.CONST(), _, DAE.EQBOUND(constant_ = DAE.C_CONST()),
        InstTypes.SPLICEDEXPDATA(sexp, idTy))
      algorithm
        expTy := Types.simplifyType(inType) "Constants with equal bindings should be constant, i.e. true
                                    but const is passed on, allowing constants to have wrong bindings
                                    This must be caught later on." ;
        expIdTy := Types.simplifyType(idTy);
        cr := fillCrefSubscripts(inCref, inType);
        e := Expression.makeCrefExp(cr, expTy);
        e := crefVectorize(inVectorize, e, inType, sexp, expIdTy);
        (outCache, v) := Ceval.ceval(outCache, inEnv, e, false, NONE(), Absyn.MSG(info), 0);
        e := ValuesUtil.valueExp(v);
      then
        (e, DAE.C_CONST(), inAttributes);

    // evaluate parameters only if "evalparam" or Config.getEvaluateParametersInAnnotations() is set
    // TODO! also ceval if annotation Evaluate := true.
    case (SCode.PARAM(), _, _, InstTypes.SPLICEDEXPDATA(sexp, idTy)) guard(DAEUtil.isBound(inBinding))
      algorithm
        true := Flags.isSet(Flags.EVAL_PARAM) or Config.getEvaluateParametersInAnnotations();
        // make it a constant if evalparam is used
        attr := DAEUtil.setAttrVariability(inAttributes, SCode.CONST());
        expTy := Types.simplifyType(inType) "Constants with equal bindings should be constant, i.e. true
                                    but const is passed on, allowing constants to have wrong bindings
                                    This must be caught later on.";
        expIdTy := Types.simplifyType(idTy);
        cr := fillCrefSubscripts(inCref, inType);
        e := crefVectorize(inVectorize, Expression.makeCrefExp(cr, expTy), inType, sexp, expIdTy);
        (outCache, v) := Ceval.ceval(outCache, inEnv, e, false, NONE(), Absyn.MSG(info), 0);
        e := ValuesUtil.valueExp(v);
      then
        (e, DAE.C_PARAM(), attr);

    // a constant array indexed by a for iterator -> transform into an array of values. HACK! HACK! UGLY! TODO! FIXME!
    // handles things like fcall(data[i]) in 1:X where data is a package constant of the form:
    // data:={Common.SingleGasesData.N2,Common.SingleGasesData.H2,Common.SingleGasesData.CO,Common.SingleGasesData.O2,Common.SingleGasesData.H2O, Common.SingleGasesData.CO2}
    case (SCode.CONST(), _, DAE.EQBOUND(evaluatedExp = SOME(v), constant_ = DAE.C_CONST()),
        InstTypes.SPLICEDEXPDATA(SOME(DAE.CREF(componentRef = cr)), _))
      algorithm
        {DAE.INDEX(DAE.CREF(componentRef = subCr2)), slice as DAE.SLICE()} := ComponentReference.crefLastSubs(cr);
        {DAE.INDEX(index as DAE.CREF(componentRef = subCr1))} := ComponentReference.crefLastSubs(inCref);
        true := ComponentReference.crefEqual(subCr1, subCr2);
        DAE.SLICE(DAE.ARRAY()) := slice;
        e := ValuesUtil.valueExp(v);
        e := DAE.ASUB(e, {index});
      then
        (e, DAE.C_CONST(), inAttributes);

    // constants without value should not produce error if they are not in a simulation model!
    case (SCode.CONST(), _, DAE.UNBOUND(), _) guard(isNone(inIteratorConst))
      algorithm
        if Flags.isSet(Flags.STATIC) then
          s := ComponentReference.printComponentRefStr(inCref);
          scope := FGraph.printGraphPathStr(inEnv);
          pre_str := PrefixUtil.printPrefixStr2(inPrefix);
          s := pre_str + s;

          Debug.traceln("- Static.elabCref2 failed on: " + pre_str + s +
            " with no constant binding in scope: " + scope);
        end if;

        expTy := Types.simplifyType(inType);
        cr := fillCrefSubscripts(inCref, inType);
        e := Expression.makeCrefExp(cr, expTy);
      then
        (e, DAE.C_CONST(), inAttributes);

    // Everything else, vectorize the cref.
    case (_, _, _, InstTypes.SPLICEDEXPDATA(sexp, idTy))
      algorithm
        expTy := Types.simplifyType(inType);
        expIdTy := Types.simplifyType(idTy);
        cr := fillCrefSubscripts(inCref, inType);
        e := crefVectorize(inVectorize, Expression.makeCrefExp(cr, expTy), inType, sexp, expIdTy);
        const := Types.variabilityToConst(var);
      then
        (e, const, inAttributes);

    // failure!
    else
      algorithm
        true := Flags.isSet(Flags.FAILTRACE);
        pre_str := PrefixUtil.printPrefixStr2(inPrefix);
        Debug.traceln("- Static.elabCref2 failed for: " + pre_str +
          ComponentReference.printComponentRefStr(inCref) +
          "\n env:" + FGraph.printGraphStr(inEnv));
      then
        fail();

  end matchcontinue;
end elabCref2;

public function crefVectorize
"This function takes a DAE.Exp and a DAE.Type and if the expression
  is a ComponentRef and the type is an array it returns an array of
  component references with subscripts for each index.
  For instance, parameter Real x[3];
  gives cref_vectorize('x', <arraytype>) => '{x[1],x[2],x[3]}
  This is needed since the DAE does not know what the variable 'x' is,
  it only knows the variables 'x[1]', 'x[2]' and 'x[3]'.
  NOTE: Currently only works for one and two dimensions."
  input Boolean performVectorization "if false, return input";
  input DAE.Exp inExp;
  input DAE.Type inType;
  input Option<DAE.Exp> splicedExp;
  input DAE.Type crefIdType "the type of the last cref ident, without considering subscripts. picked up from splicedExpData and used for crefs in vectorized exp";
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (performVectorization,inExp,inType,splicedExp,crefIdType)
    local
      Boolean b1,b2;
      DAE.Type exptp;
      DAE.Exp e;
      DAE.ComponentRef cr;
      DAE.Type t;
      DAE.Dimension d1, d2;
      Integer ds, ds2;

    // no vectorization
    case(false, e, _, _,_) then e;

    // types extending basictype
    case (_,e,DAE.T_SUBTYPE_BASIC(complexType = t),_,_)
      equation
        e = crefVectorize(true,e,t,NONE(),crefIdType);
      then e;

    // component reference and an array type with dimensions less than vectorization limit
    case (_, _, DAE.T_ARRAY(dims = {d1}, ty = DAE.T_ARRAY(dims = {d2})),
        SOME(DAE.CREF(componentRef = cr)), _)
      equation
        b1 = (Expression.dimensionSize(d1) < Config.vectorizationLimit());
        b2 = (Expression.dimensionSize(d2) < Config.vectorizationLimit());
        true = boolAnd(b1, b2) or Config.vectorizationLimit() == 0;
        e = elabCrefSlice(cr,crefIdType);
        e = elabMatrixToMatrixExp(e);
      then
        e;

    case (_, _, DAE.T_ARRAY(dims = {d1}, ty = t),
        SOME(DAE.CREF(componentRef = cr)), _)
      equation
        false = Types.isArray(t);
        true = (Expression.dimensionSize(d1) < Config.vectorizationLimit()) or Config.vectorizationLimit() == 0;
        e = elabCrefSlice(cr,crefIdType);
      then
        e;

    // matrix sizes > vectorization limit is not vectorized
    case (_, DAE.CREF(componentRef = cr, ty = exptp),
         DAE.T_ARRAY(dims = {d1}, ty = t as DAE.T_ARRAY(dims = {d2})),
         _, _)
      equation
        ds = Expression.dimensionSize(d1);
        ds2 = Expression.dimensionSize(d2);
        b1 = (ds < Config.vectorizationLimit());
        b2 = (ds2 < Config.vectorizationLimit());
        true = boolAnd(b1, b2) or Config.vectorizationLimit() == 0;
        e = createCrefArray2d(cr, 1, ds, ds2, exptp, t,crefIdType);
      then
        e;

    // vectorsizes > vectorization limit is not vectorized
    case (_,DAE.CREF(componentRef = cr,ty = exptp),
         DAE.T_ARRAY(dims = {d1},ty = t),
         _,_)
      equation
        false = Types.isArray(t);
        ds = Expression.dimensionSize(d1);
        true = ds < Config.vectorizationLimit() or Config.vectorizationLimit() == 0;
        e = createCrefArray(cr, 1, ds, exptp, t,crefIdType);
      then
        e;
    else inExp;
  end matchcontinue;
end crefVectorize;

protected function extractDimensionOfChild
"A function for extracting the type-dimension of the child to *me* to dimension *my* array-size.
  Also returns wheter the array is a scalar or not."
  input DAE.Exp inExp;
  output DAE.Dimensions outExp;
  output Boolean isScalar;
algorithm
  (outExp,isScalar) := matchcontinue(inExp)
    local
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1,expl2;
      DAE.Type ety,ety2;
      DAE.Dimensions tl;
      Integer x;
      Boolean sc;

    case(DAE.ARRAY(ty = (DAE.T_ARRAY(dims=(tl))),scalar=sc))
    then (tl,sc);

    case(DAE.ARRAY(array=expl1 as ((exp2 as DAE.ARRAY(_,_,_)) :: _)))
      equation
        (tl,_) = extractDimensionOfChild(exp2);
        x = listLength(expl1);
      then
        (DAE.DIM_INTEGER(x)::tl, false );

    case(DAE.ARRAY(array=expl1))
      equation
        x = listLength(expl1);
      then ({DAE.DIM_INTEGER(x)},true);

    case(DAE.CREF(_ , _))
    then
      ({},true);
  end matchcontinue;
end extractDimensionOfChild;

protected function elabCrefSlice
"Bjozac, 2007-05-29  Main function from now for vectorizing output.
  the subscriptlist should contain either 'done slices' or numbers representing
 dimension entries.
Example:
1) a is a real[2,3] with no subscripts, the input here should be
CREF_IDENT('a',{DAE.SLICE(DAE.ARRAY(_,_,{1,2})), DAE.SLICE(DAE.ARRAY(_,_,{1,2,3}))})>
   ==> {{a[1,1],a[1,2],a[1,3]},{a[2,1],a[2,2],a[2,3]}}
2) a is a real[3,3] with subscripts {1,2},{1,3}, the input should be
CREF_IDENT('a',{DAE.SLICE(DAE.ARRAY(_,_,{DAE.INDEX(1),DAE.INDEX(2)})),
                DAE.SLICE(DAE.ARRAY(_,_,{DAE.INDEX(1),DAE.INDEX(3)}))})
   ==> {{a[1,1],a[1,3]},{a[2,1],a[2,3]}}"
  input DAE.ComponentRef inCref;
  input DAE.Type inType;
  output DAE.Exp outCref;
algorithm
  outCref := match(inCref, inType)
    local
      list<DAE.Subscript> ssl;
      String id;
      DAE.ComponentRef child;
      DAE.Exp exp1,childExp;
      DAE.Type ety, prety;

    case( DAE.CREF_IDENT(ident = id,subscriptLst = ssl),ety)
      equation
        exp1 = flattenSubscript(ssl,id,ety);
      then
        exp1;
    case( DAE.CREF_QUAL(ident = id, identType = prety, subscriptLst = ssl, componentRef = child),ety)
      equation
        childExp = elabCrefSlice(child,ety);
        exp1 = flattenSubscript(ssl,id,prety);
        exp1 = mergeQualWithRest(exp1,childExp,ety);
      then
        exp1;
  end match;
end elabCrefSlice;

protected function mergeQualWithRest
"Incase we have a qual with child references, this function merges them.
  The input should be an array, or just one CREF_QUAL, of arrays...of arrays
  of CREF_QUALS and the same goes for 'rest'. Also the flat type as input."
  input DAE.Exp qual;
  input DAE.Exp rest;
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := match(qual,rest,inType)
    local
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1;
      DAE.Type ety;
      DAE.Dimensions iLst;
      Boolean scalar;
    // a component reference
    case(exp1 as DAE.CREF(_,_),exp2,_)
      then mergeQualWithRest2(exp2,exp1);
    // an array
    case(DAE.ARRAY(_, _, expl1),exp2,ety)
      equation
        expl1 = List.map2(expl1,mergeQualWithRest,exp2,ety);

        exp2 = DAE.ARRAY(DAE.T_INTEGER_DEFAULT,false,expl1);
        (iLst, scalar) = extractDimensionOfChild(exp2);
        ety = Expression.arrayEltType(ety);
        exp2 = DAE.ARRAY(DAE.T_ARRAY(ety, iLst, DAE.emptyTypeSource), scalar, expl1);
    then exp2;
  end match;
end mergeQualWithRest;

protected function mergeQualWithRest2
"Helper to mergeQualWithRest, handles the case
  when the child-qual is arrays of arrays."
  input DAE.Exp rest;
  input DAE.Exp qual;
  output DAE.Exp outExp;
algorithm
  outExp := match(rest,qual)
    local
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1;
      list<DAE.Subscript> ssl;
      DAE.ComponentRef cref,cref_2;
      String id;
      DAE.Type ety,ty2;
      DAE.Dimensions iLst;
      Boolean scalar;
    // a component reference
    case(DAE.CREF(cref, ety),DAE.CREF(DAE.CREF_IDENT(id,ty2, ssl),_))
      equation
        cref_2 = ComponentReference.makeCrefQual(id,ty2, ssl,cref);
      then Expression.makeCrefExp(cref_2,ety);
    // an array
    case(exp1 as DAE.ARRAY(ety, _, expl1), exp2 as DAE.CREF(DAE.CREF_IDENT(_,_, _),_))
      equation
        expl1 = List.map1(expl1,mergeQualWithRest2,exp2);
        exp1 = DAE.ARRAY(DAE.T_INTEGER_DEFAULT,false,expl1);
        (_, scalar) = extractDimensionOfChild(exp1);
      then DAE.ARRAY(ety, scalar, expl1);
  end match;
end mergeQualWithRest2;

protected function flattenSubscript
"to catch subscript free CREF's."
  input list<DAE.Subscript> inSubs;
  input String name;
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inSubs,name, inType)
    local
      String id;
      list<DAE.Subscript> subs1;
      DAE.Exp exp1,exp2;
      DAE.Type ety;
      DAE.ComponentRef cref_;
    // empty list
    case({},id,ety)
      equation
        cref_ = ComponentReference.makeCrefIdent(id,ety,{});
        exp1 = Expression.makeCrefExp(cref_,ety);
      then
        exp1;
    // some subscripts present
    case(subs1,id,ety) // {1,2,3}
      equation
        exp2 = flattenSubscript2(subs1,id,ety);
      then
        exp2;
  end matchcontinue;
end flattenSubscript;

// BZ(2010-01-29): Changed to public to be able to vectorize crefs from other places
public function flattenSubscript2
"This function takes the created 'invalid' subscripts
  and the name of the CREF and returning the CREFS
  Example: flattenSubscript2({SLICE({1,2}},SLICE({1}),\"a\",tp) ==> {{a[1,1]},{a[2,1]}}.

  This is done in several function calls, this specific
  function extracts the numbers ( 1,2 and 1 ).
  "
  input list<DAE.Subscript> inSubs;
  input String name;
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inSubs,name, inType)
    local
      String id;
      DAE.Subscript sub1;
      list<DAE.Subscript> subs1;
      list<DAE.Exp> expl1,expl2;
      DAE.Exp exp1,exp2,exp3;
      DAE.Type ety;
      DAE.Dimensions iLst;
      Boolean scalar;

    // empty subscript
    case({},_,_) then DAE.ARRAY(DAE.T_UNKNOWN_DEFAULT,false,{});

    // first subscript integer, ety
    case( ( (DAE.INDEX(exp = exp1 as DAE.ICONST(_))) :: subs1),id,ety)
      equation
        exp2 = flattenSubscript2(subs1,id,ety);
        //print("1. flattened rest into "+ExpressionDump.dumpExpStr(exp2,0)+"\n");
        exp2 = applySubscript(exp1, exp2 ,id,Expression.unliftArray(ety));
        //print("1. applied this subscript into "+ExpressionDump.dumpExpStr(exp2,0)+"\n");
      then
        exp2;
    // special case for zero dimension...
    case( ((DAE.SLICE( DAE.ARRAY(_,_,(expl1 as DAE.ICONST(0)::{})) )):: subs1),id,ety) // {1,2,3}
      equation
        exp2 = flattenSubscript2(subs1,id,ety);
        expl2 = List.map3(expl1,applySubscript,exp2,id,ety);
        exp3 = listHead(expl2);
        //exp3 = removeDoubleEmptyArrays(exp3);
      then
        exp3;
    // normal case;
    case( ((DAE.SLICE( DAE.ARRAY(_,_,expl1) )):: subs1),id,ety) // {1,2,3}
      equation
        exp2 = flattenSubscript2(subs1,id,ety);
        expl2 = List.map3(expl1,applySubscript,exp2,id,ety);
        exp3 = DAE.ARRAY(DAE.T_INTEGER_DEFAULT,false,expl2);
        (iLst, scalar) = extractDimensionOfChild(exp3);
        ety = Expression.arrayEltType(ety);
        exp3 = DAE.ARRAY(DAE.T_ARRAY(ety, iLst, DAE.emptyTypeSource), scalar, expl2);
        //exp3 = removeDoubleEmptyArrays(exp3);
      then
        exp3;
  end matchcontinue;
end flattenSubscript2;

protected function removeDoubleEmptyArrays
" A help function, to prevent the {{}} look of empty arrays."
  input DAE.Exp inArr;
  output DAE.Exp  outArr;
algorithm
  outArr := matchcontinue(inArr)
    local
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1,expl2,expl3;
      DAE.Type ty1,ty2;
      Boolean sc;
    case(DAE.ARRAY(array =       ((exp2 as DAE.ARRAY(array={}))::{}) ))
      then
        exp2;
    case(DAE.ARRAY(ty = ty1,scalar=sc,array = expl1 as
      ((DAE.ARRAY())::expl3) ))
      equation
        expl3 = List.map(expl1,removeDoubleEmptyArrays);
        exp1 = DAE.ARRAY(ty1, sc, (expl3));
      then
        exp1;
    case(exp1) then exp1;
    case(exp1)
      equation
        print("- Static.removeDoubleEmptyArrays failure for: " + ExpressionDump.printExpStr(exp1) + "\n");
      then
        fail();
  end matchcontinue;
end removeDoubleEmptyArrays;

protected function applySubscript
"here we apply the subscripts to the IDENTS of the CREF's.
  Special case for adressing INDEX[0], make an empty array.
  If we have an array of subscript, we call applySubscript2"
  input DAE.Exp inSub "dim n ";
  input DAE.Exp inSubs "dim >n";
  input String name;
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inSub, inSubs ,name, inType)
    local
      String id;
      DAE.Exp exp1,exp2;
      DAE.Type ety,crty;
      DAE.Dimensions arrDim;
      DAE.ComponentRef cref_;

    case(_,exp1 as DAE.ARRAY(DAE.T_ARRAY(dims = arrDim) ,_,{}),_ ,_)
      equation
        true = Expression.arrayContainZeroDimension(arrDim);
      then exp1;

        /* add dimensions */
    case(DAE.ICONST(integer=0),DAE.ARRAY(DAE.T_ARRAY(dims = arrDim) ,_,_),_ ,ety)
      equation
        ety = Expression.arrayEltType(ety);
      then DAE.ARRAY(DAE.T_ARRAY(ety, DAE.DIM_INTEGER(0)::arrDim, DAE.emptyTypeSource),true,{});

    case(DAE.ICONST(integer=0),_,_ ,ety)
      equation
        ety = Expression.arrayEltType(ety);
      then DAE.ARRAY(DAE.T_ARRAY(ety,{DAE.DIM_INTEGER(0)}, DAE.emptyTypeSource),true,{});

    case(exp1,DAE.ARRAY(_,_,{}),id ,ety)
      equation
        true = Expression.isValidSubscript(exp1);
        crty = Expression.unliftArray(ety) "only subscripting one dimension, unlifting once ";
        cref_ = ComponentReference.makeCrefIdent(id,ety,{DAE.INDEX(exp1)});
      then Expression.makeCrefExp(cref_,crty);

    case(exp1, exp2, _ ,ety)
      equation
        true = Expression.isValidSubscript(exp1);
      then applySubscript2(exp1, exp2,ety);
  end matchcontinue;
end applySubscript;

protected function applySubscript2
"Handles multiple subscripts for the expression.
  If it is an array, we listmap applySubscript3"
  input DAE.Exp inSub "The subs to add";
  input DAE.Exp inSubs "The already created subs";
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := match(inSub, inSubs, inType )
    local
      String id;
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1;
      list<DAE.Subscript> subs;
      DAE.Type ety,ty2,crty;
      DAE.Dimensions iLst;
      Boolean scalar;
      DAE.ComponentRef cref_;

    case(exp1, DAE.CREF(DAE.CREF_IDENT(id,ty2,subs),_ ),_ )
      equation
        crty = Expression.unliftArrayTypeWithSubs(DAE.INDEX(exp1)::subs,ty2);
        cref_ = ComponentReference.makeCrefIdent(id,ty2,(DAE.INDEX(exp1)::subs));
        exp2 = Expression.makeCrefExp(cref_,crty);
      then exp2;

    case(exp1, DAE.ARRAY(_,_,expl1),ety )
      equation
        expl1 = List.map2(expl1,applySubscript3,exp1,ety);
        exp2 = DAE.ARRAY(DAE.T_INTEGER_DEFAULT,false,expl1);
        (iLst, scalar) = extractDimensionOfChild(exp2);
        ety = Expression.arrayEltType(ety);
        exp2 = DAE.ARRAY(DAE.T_ARRAY(ety, iLst, DAE.emptyTypeSource), scalar, expl1);
      then exp2;
  end match;
end applySubscript2;

protected function applySubscript3
"Final applySubscript function, here we call ourself
  recursive until we have the CREFS we are looking for."
  input DAE.Exp inSubs "The already created subs";
  input DAE.Exp inSub "The subs to add";
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := match(inSubs,inSub, inType )
    local
      String id;
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1;
      list<DAE.Subscript> subs;
      DAE.Type ety,ty2,crty;
      DAE.Dimensions iLst;
      Boolean scalar;
      DAE.ComponentRef cref_;

    case(DAE.CREF(DAE.CREF_IDENT(id,ty2,subs),_), exp1, _ )
      equation
        crty = Expression.unliftArrayTypeWithSubs(DAE.INDEX(exp1)::subs,ty2);
        cref_ = ComponentReference.makeCrefIdent(id,ty2,(DAE.INDEX(exp1)::subs));
        exp2 = Expression.makeCrefExp(cref_,crty);
      then exp2;

    case(DAE.ARRAY(_,_,expl1), exp1, ety)
      equation
        expl1 = List.map2(expl1,applySubscript3,exp1,ety);
        exp2 = DAE.ARRAY(DAE.T_INTEGER_DEFAULT,false,expl1);
        (iLst, scalar) = extractDimensionOfChild(exp2);
        ety = Expression.arrayEltType(ety);
        exp2 = DAE.ARRAY(DAE.T_ARRAY(ety, iLst, DAE.emptyTypeSource), scalar, expl1);
      then exp2;
  end match;
end applySubscript3;


protected function callVectorize
"author: PA

  Takes an expression that is a function call and an expresion list
  and maps the call to each expression in the list.
  For instance, call_vectorize(DAE.CALL(XX(\"der\",),...),{1,2,3}))
  => {DAE.CALL(XX(\"der\"),{1}), DAE.CALL(XX(\"der\"),{2}),DAE.CALL(XX(\"der\",{3}))}
  NOTE: the vectorized expression is inserted first in the argument list
 of the call, so if extra arguments should be passed these can be given as
 input to the call expression."
  input DAE.Exp inExp;
  input list<DAE.Exp> inExpExpLst;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := matchcontinue (inExp,inExpExpLst)
    local
      DAE.Exp e,callexp;
      list<DAE.Exp> es_1,args,es;
      Absyn.Path fn;
      Boolean tuple_,builtin;
      DAE.InlineType inl;
      DAE.Type tp;
      DAE.CallAttributes attr;
    // empty list
    case (_,{}) then {};
    // vectorize call
    case ((callexp as DAE.CALL(fn,args,attr)),(e :: es))
      equation
        es_1 = callVectorize(callexp, es);
      then
        (DAE.CALL(fn,(e :: args),attr) :: es_1);
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Static.callVectorize failed\n");
      then
        fail();
  end matchcontinue;
end callVectorize;

protected function createCrefArray
"helper function to crefVectorize, creates each individual cref,
  e.g. {x{1},x{2}, ...} from x."
  input DAE.ComponentRef inComponentRef1;
  input Integer inInteger2;
  input Integer inInteger3;
  input DAE.Type inType4;
  input DAE.Type inType5;
  input DAE.Type crefIdType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inComponentRef1,inInteger2,inInteger3,inType4,inType5,crefIdType)
    local
      DAE.ComponentRef cr,cr_1;
      Integer indx,ds,indx_1;
      DAE.Type et,elt_tp;
      DAE.Type t;
      list<DAE.Exp> expl;
      DAE.Exp e_1;
    // index iterator dimension size
    case (_,indx,ds,et,_,_)
      equation
        (indx > ds) = true;
      then
        DAE.ARRAY(et,true,{});
    // index
    /*
    case (cr,indx,ds,et,t,crefIdType)
      equation
        (DAE.INDEX(e_1) :: ss) = ComponentReference.crefLastSubs(cr);
        cr_1 = ComponentReference.crefStripLastSubs(cr);
        cr_1 = ComponentReference.subscriptCref(cr_1,ss);
        DAE.ARRAY(_,_,expl) = createCrefArray(cr_1, indx, ds, et, t,crefIdType);
        expl = List.map1(expl,Expression.prependSubscriptExp,DAE.INDEX(e_1));
      then
        DAE.ARRAY(et,true,expl);
    */
    // for crefs with wholedim
    case (cr,indx,ds,et,t,_)
      equation
        indx_1 = indx + 1;
        cr_1 = ComponentReference.replaceWholeDimSubscript(cr,indx);
        DAE.ARRAY(_,_,expl) = createCrefArray(cr, indx_1, ds, et, t,crefIdType);
        elt_tp = Expression.unliftArray(et);
        e_1 = crefVectorize(true,Expression.makeCrefExp(cr_1,elt_tp), t,NONE(),crefIdType);
      then
        DAE.ARRAY(et,true,(e_1 :: expl));
    // no subscript
    case (cr,indx,ds,et,t,_)
      equation
        indx_1 = indx + 1;
        // {} = ComponentReference.crefLastSubs(cr);
        DAE.ARRAY(_,_,expl) = createCrefArray(cr, indx_1, ds, et, t,crefIdType);
        e_1 = Expression.makeASUB(Expression.makeCrefExp(cr,et),{DAE.ICONST(indx)});
        (e_1,_) = ExpressionSimplify.simplify(e_1);
        e_1 = crefVectorize(true,e_1, t,NONE(),crefIdType);
      then
        DAE.ARRAY(et,true,(e_1 :: expl));
    // failure
    case (cr,_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("createCrefArray failed on:" + ComponentReference.printComponentRefStr(cr));
      then
        fail();
  end matchcontinue;
end createCrefArray;

protected function createCrefArray2d
"helper function to cref_vectorize, creates each
  individual cref, e.g. {x{1,1},x{2,1}, ...} from x."
  input DAE.ComponentRef inCref;
  input Integer inIndex;
  input Integer inDim1;
  input Integer inDim2;
  input DAE.Type inType5;
  input DAE.Type inType6;
  input DAE.Type crefIdType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inCref, inIndex, inDim1, inDim2, inType5,inType6,crefIdType)
    local
      DAE.ComponentRef cr,cr_1;
      Integer indx,ds,ds2,indx_1;
      DAE.Type et,tp,elt_tp;
      DAE.Type t;
      list<list<DAE.Exp>> ms;
      list<DAE.Exp> expl;
    // index iterator dimension size 1 dimension size 2
    case (_,indx,ds,_,et,_,_)
      equation
        (indx > ds) = true;
      then
        DAE.MATRIX(et,0,{});
    // increase the index dimension
    case (cr,indx,ds,ds2,et,t,_)
      equation
        indx_1 = indx + 1;
        DAE.MATRIX(matrix = ms) = createCrefArray2d(cr, indx_1, ds, ds2, et, t,crefIdType);
        cr_1 = ComponentReference.subscriptCref(cr, {DAE.INDEX(DAE.ICONST(indx))});
        elt_tp = Expression.unliftArray(et);
        DAE.ARRAY(_,true,expl) = crefVectorize(true,Expression.makeCrefExp(cr_1,elt_tp), t,NONE(),crefIdType);
      then
        DAE.MATRIX(et,ds,(expl :: ms));
    //
    case (cr,_,_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Static.createCrefArray2d failed on: " + ComponentReference.printComponentRefStr(cr));
      then
        fail();
  end matchcontinue;
end createCrefArray2d;

public function absynCrefToComponentReference "This function converts an absyn cref to a component reference"
  input Absyn.ComponentRef inComponentRef;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inComponentRef)
    local
      String i;
      Boolean b;
      Absyn.ComponentRef c;
      DAE.ComponentRef cref;

    case Absyn.CREF_IDENT(name = i,subscripts = {})
      equation
        cref = ComponentReference.makeCrefIdent(i, DAE.T_UNKNOWN_DEFAULT, {});
      then
        cref;

    case Absyn.CREF_QUAL(name = i,subscripts = {},componentRef = c)
      equation
        cref = absynCrefToComponentReference(c);
        cref = ComponentReference.makeCrefQual(i, DAE.T_UNKNOWN_DEFAULT, {}, cref);
      then
        cref;

    case Absyn.CREF_FULLYQUALIFIED(componentRef = c)
      equation
        cref = absynCrefToComponentReference(c);
      then
        cref;
  end match;
end absynCrefToComponentReference;

protected function elabCrefSubs
"This function elaborates on all subscripts in a component reference."
  input FCore.Cache inCache;
  input FCore.Graph inCrefEnv "search for the cref in this environment";
  input FCore.Graph inSubsEnv;
  input Absyn.ComponentRef inComponentRef;
  input Prefix.Prefix inTopPrefix "the top prefix, i.e. the one send down by elabCref1, needed to prefix expressions in subscript types!";
  input Prefix.Prefix inCrefPrefix "the accumulated cref, required for lookup";
  input Boolean inBoolean;
  input Boolean inHasZeroSizeDim;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.ComponentRef outComponentRef;
  output DAE.Const outConst "The constness of the subscripts. Note: This is not the same as
  the constness of a cref with subscripts! (just becase x[1,2] has a constant subscript list does
  not mean that the variable x[1,2] is constant)";
  output Boolean outHasZeroSizeDim;
algorithm
  (outCache,outComponentRef,outConst,outHasZeroSizeDim) := matchcontinue (inCache,inCrefEnv,inSubsEnv,inComponentRef,inTopPrefix,inCrefPrefix,inBoolean,inHasZeroSizeDim,info)
    local
      DAE.Type t;
      DAE.Dimensions sl;
      DAE.Const const,const1,const2;
      FCore.Graph crefEnv, crefSubs;
      String id;
      list<Absyn.Subscript> ss;
      Boolean impl, hasZeroSizeDim;
      DAE.ComponentRef cr;
      Absyn.ComponentRef absynCr;
      DAE.Type ty, id_ty;
      list<DAE.Subscript> ss_1;
      Absyn.ComponentRef restCref,absynCref;
      FCore.Cache cache;
      SCode.Variability vt;
      Prefix.Prefix crefPrefix;
      Prefix.Prefix topPrefix;

    // IDENT
    case (cache,crefEnv,crefSubs,Absyn.CREF_IDENT(name = id,subscripts = ss),topPrefix,crefPrefix,impl,hasZeroSizeDim,_)
      equation
        // Debug.traceln("Try elabSucscriptsDims " + id);
        (cache,cr) = PrefixUtil.prefixCref(cache,crefEnv,InnerOuter.emptyInstHierarchy,crefPrefix,
                                           ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{}));
        (cache,_,t,_,_,InstTypes.SPLICEDEXPDATA(identType = id_ty),_,_,_) = Lookup.lookupVar(cache, crefEnv, cr);
        // false = Types.isUnknownType(t);
        // print("elabCrefSubs type of: " + id + " is " + Types.printTypeStr(t) + "\n");
        // Debug.traceln("    elabSucscriptsDims " + id + " got var");
        // _ = Types.simplifyType(t);
        id_ty = Types.simplifyType(id_ty);
        hasZeroSizeDim = Types.isZeroLengthArray(id_ty);
        sl = Types.getDimensions(id_ty);
        // Constant evaluate subscripts on form x[1,p,q] where p,q are constants or parameters
        (cache,ss_1,const) = elabSubscriptsDims(cache, crefSubs, ss, sl, impl,
            topPrefix, inComponentRef, info);
      then
        (cache,ComponentReference.makeCrefIdent(id,id_ty,ss_1),const,hasZeroSizeDim);

    // QUAL,with no subscripts => looking for var in the top env!
    case (cache,crefEnv,crefSubs,Absyn.CREF_QUAL(name = id,subscripts = {},componentRef = restCref),topPrefix,crefPrefix,impl,hasZeroSizeDim,_)
      equation
        (cache,cr) = PrefixUtil.prefixCref(cache,crefEnv,InnerOuter.emptyInstHierarchy,crefPrefix,
                                           ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{}));
        //print("env:");print(FGraph.printGraphStr(env));print("\n");
        (cache,_,t,_,_,_,_,_,_) = Lookup.lookupVar(cache, crefEnv, cr);
        ty = Types.simplifyType(t);
        sl = Types.getDimensions(ty);
        crefPrefix = PrefixUtil.prefixAdd(id,sl,{},crefPrefix,SCode.VAR(),ClassInf.UNKNOWN(Absyn.IDENT(""))); // variability doesn't matter
        (cache,cr,const,hasZeroSizeDim) = elabCrefSubs(cache, crefEnv, crefSubs, restCref, topPrefix, crefPrefix, impl, hasZeroSizeDim, info);
      then
        (cache,ComponentReference.makeCrefQual(id,ty,{},cr),const,hasZeroSizeDim);

    // QUAL,with no subscripts second case => look for class
    case (cache,crefEnv,crefSubs,Absyn.CREF_QUAL(name = id,subscripts = {},componentRef = restCref),topPrefix,crefPrefix,impl,hasZeroSizeDim,_)
      equation
        crefPrefix = PrefixUtil.prefixAdd(id,{},{},crefPrefix,SCode.VAR(),ClassInf.UNKNOWN(Absyn.IDENT(""))); // variability doesn't matter
        (cache,cr,const,hasZeroSizeDim) = elabCrefSubs(cache, crefEnv, crefSubs, restCref, topPrefix, crefPrefix, impl, hasZeroSizeDim, info);
      then
        (cache,ComponentReference.makeCrefQual(id,DAE.T_COMPLEX_DEFAULT,{},cr),const,hasZeroSizeDim);

    // QUAL,with constant subscripts
    case (cache,crefEnv,crefSubs,Absyn.CREF_QUAL(name = id,subscripts = ss as _::_,componentRef = restCref),topPrefix,crefPrefix,impl,hasZeroSizeDim,_)
      equation
        (cache,cr) = PrefixUtil.prefixCref(cache,crefEnv,InnerOuter.emptyInstHierarchy,crefPrefix,
                                           ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{}));
        (cache,DAE.ATTR(variability = vt),t,_,_,InstTypes.SPLICEDEXPDATA(identType = id_ty),_,_,_) = Lookup.lookupVar(cache, crefEnv, cr);
        ty = Types.simplifyType(t);
        id_ty = Types.simplifyType(id_ty);
        sl = Types.getDimensions(id_ty);
        (cache,ss_1,const1) = elabSubscriptsDims(cache, crefSubs, ss, sl, impl,
            topPrefix, inComponentRef, info);
        crefPrefix = PrefixUtil.prefixAdd(id, sl, ss_1, crefPrefix, vt, ClassInf.UNKNOWN(Absyn.IDENT("")));
        (cache,cr,const2,hasZeroSizeDim) = elabCrefSubs(cache, crefEnv, crefSubs, restCref, topPrefix, crefPrefix, impl, hasZeroSizeDim, info);
        const = Types.constAnd(const1, const2);
      then
        (cache,ComponentReference.makeCrefQual(id,ty,ss_1,cr),const,hasZeroSizeDim);

    case (cache, crefEnv, crefSubs, Absyn.CREF_FULLYQUALIFIED(componentRef = absynCr), topPrefix, crefPrefix, impl, hasZeroSizeDim, _)
      equation
        crefEnv = FGraph.topScope(crefEnv);
        (cache, cr, const1, hasZeroSizeDim) = elabCrefSubs(cache, crefEnv, crefSubs, absynCr, topPrefix, crefPrefix, impl, hasZeroSizeDim, info);
      then
        (cache, cr, const1, hasZeroSizeDim);

    // failure
    case (_,crefEnv,_,absynCref,topPrefix,crefPrefix,_,_,_)
      equation
        // FAILTRACE REMOVE
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Static.elabCrefSubs failed on: " +
        "[top:" + PrefixUtil.printPrefixStr(topPrefix) + "]." +
        PrefixUtil.printPrefixStr(crefPrefix) + "." +
          Dump.printComponentRefStr(absynCref) + " env: " +
          FGraph.printGraphPathStr(crefEnv));
      then
        fail();
  end matchcontinue;
end elabCrefSubs;

public function elabSubscripts
"This function converts a list of Absyn.Subscript to a list of
  DAE.Subscript, and checks if all subscripts are constant.
  HJ: not checking for constant, returning if constant or not"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Subscript> inAbsynSubscriptLst;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output list<DAE.Subscript> outExpSubscriptLst;
  output DAE.Const outConst;
algorithm
  (outCache,outExpSubscriptLst,outConst) := match (inCache,inEnv,inAbsynSubscriptLst,inBoolean,inPrefix,info)
    local
      DAE.Subscript sub_1;
      DAE.Const const1,const2,const;
      list<DAE.Subscript> subs_1;
      FCore.Graph env;
      Absyn.Subscript sub;
      list<Absyn.Subscript> subs;
      Boolean impl;
      FCore.Cache cache;
      Prefix.Prefix pre;

    // empty list
    case (cache,_,{},_,_,_) then (cache,{},DAE.C_CONST());
    // elab a subscript then recurse
    case (cache,env,(sub :: subs),impl,pre,_)
      equation
        (cache,sub_1,const1, _) = elabSubscript(cache,env, sub, impl,pre,info);
        (cache,subs_1,const2) = elabSubscripts(cache,env, subs, impl,pre,info);
        const = Types.constAnd(const1, const2);
      then
        (cache,(sub_1 :: subs_1),const);
  end match;
end elabSubscripts;

protected function elabSubscriptsDims
  "Elaborates a list of subscripts and checks that they are valid for the given dimensions."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Subscript> inSubscripts;
  input list<DAE.Dimension> inDimensions;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.ComponentRef inCref;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output list<DAE.Subscript> outSubs = {};
  output DAE.Const outConst = DAE.C_CONST();
protected
  list<DAE.Dimension> rest_dims = inDimensions;
  DAE.Dimension dim;
  DAE.Subscript dsub;
  DAE.Const const;
  Option<DAE.Properties> prop;
  String subl_str, diml_str, cref_str;
  Integer nrdims, nrsubs;
algorithm
  for asub in inSubscripts loop
    if listEmpty(rest_dims) then
      // Check that we don't have more subscripts than there are dimensions.
      cref_str := Dump.printComponentRefStr(inCref);
      subl_str := intString(listLength(inSubscripts));
      diml_str := intString(listLength(inDimensions));

      Error.addSourceMessageAndFail(Error.WRONG_NUMBER_OF_SUBSCRIPTS,
        {cref_str, subl_str, diml_str}, inInfo);
    else
      dim :: rest_dims := rest_dims;
    end if;

    (outCache, dsub, const, prop) :=
      elabSubscript(outCache, inEnv, asub, inImpl, inPrefix, inInfo);
    outConst := Types.constAnd(const, outConst);
    (outCache, dsub) := elabSubscriptsDims2(outCache, inEnv, dsub, dim,
      outConst, prop, inImpl, inCref, inInfo);

    outSubs := dsub :: outSubs;
  end for;

  nrsubs := listLength(outSubs);

  // If there are subs and the number of subs is less than dims
  // then fill in whole dims for the missing subs. i.e. We have a slice.
  // If there are no subs then it is a whole array so we do nothing.
  if nrsubs > 0 then
    nrdims := listLength(inDimensions);
    while nrsubs < nrdims loop
      outSubs := DAE.WHOLEDIM()::outSubs;
      nrsubs := nrsubs + 1;
    end while;
  end if;

  outSubs := listReverse(outSubs);
end elabSubscriptsDims;

protected function elabSubscriptsDims2
  "Helper function to elabSubscriptsDims."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Subscript inSubscript;
  input DAE.Dimension inDimension;
  input DAE.Const inConst;
  input Option<DAE.Properties> inProperties;
  input Boolean inImpl;
  input Absyn.ComponentRef inCref;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Subscript outSubscript;
algorithm
  (outCache, outSubscript) := matchcontinue(inDimension, inProperties)
    local
      FCore.Cache cache;
      DAE.Subscript sub;
      Integer int_dim;
      DAE.Properties prop;
      DAE.Type ty;
      DAE.Exp e;
      String sub_str, dim_str, cref_str;

    // If in for iterator loop scope the subscript should never be evaluated to
    // a value (since the parameter/const value of iterator variables are not
    // available until expansion, which happens later on)
    // Note that for loops are expanded 'on the fly' and should therefore not be
    // treated in this way.
    case (_, _)
      equation
        true = FGraph.inForOrParforIterLoopScope(inEnv);
        true = Expression.dimensionKnown(inDimension);
      then
        (inCache, inSubscript);

    // Keep non-fixed parameters.
    case (_, SOME(prop))
      equation
        true = Types.isParameter(inConst);
        ty = Types.getPropType(prop);
        false = Types.getFixedVarAttributeParameterOrConstant(ty);
      then
        (inCache, inSubscript);

    /*/ Keep parameters as they are:
    // adrpo 2012-12-02 this does not work as we need to evaluate final parameters!
    //                  and we have now way yet of knowing which ones those are
    case (_, _, _, _, _, _, _, _, _)
      equation
        true = Types.isParameter(inConst);
      then
        (inCache, inSubscript);*/

    // If the subscript contains a const then it should be evaluated to
    // the value.
    case (_, _)
      equation
        int_dim = Expression.dimensionSize(inDimension);
        true = Types.isParameterOrConstant(inConst);
        (cache, sub) = Ceval.cevalSubscript(inCache, inEnv, inSubscript, int_dim, inImpl, Absyn.MSG(inInfo), 0);
      then
        (cache, sub);

    case (DAE.DIM_EXP(exp=e), _)
      equation
        true = Types.isParameterOrConstant(inConst);
        (_, Values.INTEGER(integer=int_dim), _) = Ceval.ceval(inCache,inEnv,e,true,NONE(),Absyn.MSG(inInfo),0);
        (cache, sub) = Ceval.cevalSubscript(inCache, inEnv, inSubscript, int_dim, inImpl, Absyn.MSG(inInfo), 0);
      then
        (cache, sub);

    // If the previous case failed and we're just checking the model, try again
    // but skip the constant evaluation.
    case (_, _)
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        true = Types.isParameterOrConstant(inConst);
      then
        (inCache, inSubscript);

    // Keep variables and parameters inside of for-loops as they are.
    case (_, _)
      equation
        true = Expression.dimensionKnown(inDimension);
        false = Types.isConstant(inConst) or
               (Types.isParameter(inConst) and not FGraph.inForLoopScope(inEnv));
      then
        (inCache, inSubscript);

    // For unknown dimensions, ':', keep as is.
    case (DAE.DIM_UNKNOWN(), _)
      then (inCache, inSubscript);
    case (DAE.DIM_EXP(_), _)
      then (inCache, inSubscript);

    else
      equation
        sub_str = ExpressionDump.printSubscriptStr(inSubscript);
        dim_str = ExpressionDump.dimensionString(inDimension);
        cref_str = Dump.printComponentRefStr(inCref);
        Error.addSourceMessage(Error.ILLEGAL_SUBSCRIPT, {sub_str, dim_str, cref_str}, inInfo);
      then
        fail();

  end matchcontinue;
end elabSubscriptsDims2;

protected function elabSubscript "This function converts an Absyn.Subscript to an
  DAE.Subscript."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Subscript inSubscript;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Subscript outSubscript;
  output DAE.Const outConst;
  output Option<DAE.Properties> outProperties;
algorithm
  (outCache, outSubscript, outConst, outProperties) :=
  matchcontinue(inCache, inEnv, inSubscript, inBoolean, inPrefix)
    local
      Boolean impl;
      DAE.Exp sub_1;
      DAE.Type ty;
      DAE.Const const;
      DAE.Subscript sub_2;
      FCore.Graph env;
      Absyn.Exp sub;
      FCore.Cache cache;
      DAE.Properties prop;
      Prefix.Prefix pre;

    // no subscript
    case (cache, _, Absyn.NOSUB(), _, _)
      then (cache, DAE.WHOLEDIM(), DAE.C_CONST(), NONE());

    // some subscript, try to elaborate it
    case (cache, env, Absyn.SUBSCRIPT(subscript = sub), impl, pre)
      equation
        (cache, sub_1, prop as DAE.PROP(constFlag = const), _) =
          elabExpInExpression(cache, env, sub, impl, NONE(), true, pre, info);
        (cache, sub_1, prop as DAE.PROP(type_ = ty)) =
          Ceval.cevalIfConstant(cache, env, sub_1, prop, impl, info);
        sub_2 = elabSubscriptType(ty, sub, sub_1, info);
      then
        (cache, sub_2, const, SOME(prop));

    // failtrace
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Static.elabSubscript failed on " +
          Dump.printSubscriptStr(inSubscript) + " in env: " +
          FGraph.printGraphPathStr(inEnv));
      then
        fail();
  end matchcontinue;
end elabSubscript;

protected function elabSubscriptType
  "This function is used to find the correct constructor for DAE.Subscript to
   use for an indexing expression.  If a scalar is given as index, DAE.INDEX()
   is used, and if an array is given, DAE.SLICE() is used."
  input DAE.Type inType;
  input Absyn.Exp inAbsynExp;
  input DAE.Exp inDaeExp;
  input SourceInfo inInfo;
  output DAE.Subscript outSubscript;
algorithm
  outSubscript := match(inType)
    local
      DAE.Exp sub;
      String e_str,t_str,p_str;

    case DAE.T_INTEGER() then DAE.INDEX(inDaeExp);
    case DAE.T_ENUMERATION() then DAE.INDEX(inDaeExp);
    case DAE.T_BOOL() then DAE.INDEX(inDaeExp);
    case DAE.T_ARRAY(ty = DAE.T_INTEGER()) then DAE.SLICE(inDaeExp);
    case DAE.T_ARRAY(ty = DAE.T_ENUMERATION()) then DAE.SLICE(inDaeExp);
    case DAE.T_ARRAY(ty = DAE.T_BOOL()) then DAE.SLICE(inDaeExp);
    case DAE.T_METABOXED()
      then elabSubscriptType(inType.ty, inAbsynExp, inDaeExp, inInfo);

    else
      equation
        e_str = Dump.printExpStr(inAbsynExp);
        t_str = Types.unparseType(inType);
        Error.addSourceMessage(Error.WRONG_DIMENSION_TYPE, {e_str, t_str}, inInfo);
      then
        fail();
  end match;
end elabSubscriptType;

protected function subscriptCrefType
"If a component of an array type is subscripted, the type of the
  component reference is of lower dimensionality than the
  component.  This function shows the function between the component
  type and the component reference expression type.

  This function might actually not be needed.
"
  input DAE.Exp inExp;
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inExp,inType)
    local
      DAE.Type t_1,t;
      DAE.ComponentRef c;
      DAE.Exp e;

    case (DAE.CREF(componentRef = c),t)
      equation
        t_1 = subscriptCrefType2(c, t);
      then
        t_1;

    else inType;
  end matchcontinue;
end subscriptCrefType;

protected function subscriptCrefType2
  input DAE.ComponentRef inComponentRef;
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match (inComponentRef,inType)
    local
      DAE.Type t,t_1;
      list<DAE.Subscript> subs;
      DAE.ComponentRef c;

    case (DAE.CREF_IDENT(subscriptLst = {}),t) then t;
    case (DAE.CREF_IDENT(subscriptLst = subs),t)
      equation
        t_1 = subscriptType(t, subs);
      then
        t_1;
    case (DAE.CREF_QUAL(componentRef = c),t)
      equation
        t_1 = subscriptCrefType2(c, t);
      then
        t_1;
  end match;
end subscriptCrefType2;

protected function subscriptType "Given an array dimensionality and a list of subscripts, this
  function reduces the dimensionality.
  This does not handle slices or check that subscripts are not out
  of bounds."
  input DAE.Type inType;
  input list<DAE.Subscript> inExpSubscriptLst;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inType,inExpSubscriptLst)
    local
      DAE.Type t,t_1;
      list<DAE.Subscript> subs;
      DAE.Dimension dim;
      DAE.TypeSource ts;

    case (t,{}) then t;

    case (DAE.T_ARRAY(dims = {DAE.DIM_INTEGER()}, ty = t),(DAE.INDEX() :: subs))
      equation
        t_1 = subscriptType(t, subs);
      then
        t_1;

    case (DAE.T_ARRAY(dims = {dim}, ty = t, source = ts),(DAE.SLICE() :: subs))
      equation
        t_1 = subscriptType(t, subs);
      then
        DAE.T_ARRAY(t_1,{dim},ts);

    case (DAE.T_ARRAY(dims = {dim}, ty = t, source = ts),(DAE.WHOLEDIM() :: subs))
      equation
        t_1 = subscriptType(t, subs);
      then
        DAE.T_ARRAY(t_1,{dim},ts);

    case (t,_)
      equation
        Print.printBuf("- subscript_type failed (");
        Print.printBuf(Types.printTypeStr(t));
        Print.printBuf(" , [...])\n");
      then
        fail();
  end matchcontinue;
end subscriptType;

protected function makeIfExp
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inCondition;
  input DAE.Properties inCondProp;
  input DAE.Exp inTrueBranch;
  input DAE.Properties inTrueProp;
  input DAE.Exp inFalseBranch;
  input DAE.Properties inFalseProp;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  Boolean ty_match, cond;
  DAE.Type cond_ty, true_ty, false_ty, true_ty2, false_ty2, exp_ty;
  DAE.Const cond_c, true_c, false_c, exp_c;
  String cond_str, cond_ty_str, e1_str, e2_str, ty1_str, ty2_str, pre_str;
  DAE.Exp cond_exp, true_exp, false_exp;
algorithm
  // Check that the condition is a boolean expression.
  DAE.PROP(type_ = cond_ty, constFlag = cond_c) := inCondProp;
  (cond_exp, _, ty_match) := Types.matchTypeNoFail(inCondition, cond_ty, DAE.T_BOOL_DEFAULT);

  // Print an error message and fail if the condition is not a boolean expression.
  if not ty_match then
    cond_str := ExpressionDump.printExpStr(inCondition);
    cond_ty_str := Types.unparseTypeNoAttr(cond_ty);
    Error.addSourceMessageAndFail(Error.IF_CONDITION_TYPE_ERROR,
      {cond_str, cond_ty_str}, inInfo);
  end if;

  // Check that both branches are type compatible.
  DAE.PROP(type_ = true_ty, constFlag = true_c) := inTrueProp;
  DAE.PROP(type_ = false_ty, constFlag = false_c) := inFalseProp;

  (true_exp, false_exp, exp_ty, ty_match) :=
    Types.checkTypeCompat(inTrueBranch, true_ty, inFalseBranch, false_ty);

  // If the compatible type is an array with some unknown dimensions, and we're
  // not in a function, then we need to choose one of the branches.
  if Types.arrayHasUnknownDims(exp_ty) and not FGraph.inFunctionScope(inEnv) then
    // Check if the condition is reasonably constant, so we can evaluate it.
    if Types.isParameterOrConstant(cond_c) then
      cond_c := DAE.C_CONST();
    else
      // Otherwise it's a type error.
      ty_match := false;
    end if;
  end if;

  // If the types are not matching, print an error and fail.
  if not ty_match then
    e1_str := ExpressionDump.printExpStr(inTrueBranch);
    e2_str := ExpressionDump.printExpStr(inFalseBranch);
    ty1_str := Types.unparseTypeNoAttr(true_ty);
    ty2_str := Types.unparseTypeNoAttr(false_ty);
    pre_str := PrefixUtil.printPrefixStr3(inPrefix);
   // print("True Type: " + anyString(true_ty) + "\n");
   // print("False Type: " + anyString(false_ty) + "\n");
    Error.addSourceMessageAndFail(Error.TYPE_MISMATCH_IF_EXP,
      {pre_str, e1_str, ty1_str, e2_str, ty2_str}, inInfo);
  end if;

  if Types.isConstant(cond_c) then
    // If the condition is constant, try to evaluate it and choose a branch.
    try
      (outCache, Values.BOOL(cond), _) := Ceval.ceval(inCache, inEnv, cond_exp,
        inImplicit, inST, Absyn.NO_MSG(), 0);

      if cond then
        outExp := true_exp;
        outProperties := inTrueProp;
      else
        outExp := false_exp;
        outProperties := inFalseProp;
      end if;

      // Evaluation succeeded, return the chosen branch.
      return;
    else
    end try;
  end if;

  // If the condition is not constant or ceval failed, create an if-expression.
  exp_c := Types.constAnd(c for c in {cond_c, false_c, true_c});
  outExp := DAE.IFEXP(cond_exp, true_exp, false_exp);
  outProperties := DAE.PROP(exp_ty, exp_c);
end makeIfExp;

protected function canonCref2 "This function relates a DAE.ComponentRef to its canonical form,
  which is when all subscripts are evaluated to constant values.
  If Such an evaluation is not possible, there is no canonical
  form and this function fails."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inComponentRef;
  input DAE.ComponentRef inPrefixCref;
  input Boolean inBoolean;
  output FCore.Cache outCache;
  output DAE.ComponentRef outComponentRef;
algorithm
  (outCache,outComponentRef) :=
  match (inCache,inEnv,inComponentRef,inPrefixCref,inBoolean)
    local
      list<DAE.Subscript> ss_1,ss;
      FCore.Graph env;
      String n;
      Boolean impl;
      FCore.Cache cache;
      DAE.ComponentRef prefixCr,cr;
      list<Integer> sl;
      DAE.Type t;
      DAE.Type ty2;
    case (cache,env,DAE.CREF_IDENT(ident = n,identType = ty2, subscriptLst = ss),prefixCr,impl) /* impl */
      equation
        cr = ComponentReference.crefPrependIdent(prefixCr,n,{},ty2);
        (cache,_,t) = Lookup.lookupVar(cache,env, cr);
        sl = Types.getDimensionSizes(t);
        (cache,ss_1) = Ceval.cevalSubscripts(cache,env, ss, sl, impl, Absyn.NO_MSG(),0);
      then
        (cache,ComponentReference.makeCrefIdent(n,ty2,ss_1));
  end match;
end canonCref2;

public function canonCref "Transform expression to canonical form
  by constant evaluating all subscripts."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inComponentRef;
  input Boolean inBoolean;
  output FCore.Cache outCache;
  output DAE.ComponentRef outComponentRef;
algorithm
  (outCache,outComponentRef) :=
  matchcontinue (inCache,inEnv,inComponentRef,inBoolean)
    local
      DAE.Type t;
      list<Integer> sl;
      list<DAE.Subscript> ss_1,ss;
      FCore.Graph env, componentEnv;
      String n;
      Boolean impl;
      DAE.ComponentRef c_1,c,cr;
      FCore.Cache cache;
      DAE.Type ty2;

    // handle wild _
    case (cache,_,DAE.WILD(),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
      then
        (cache,DAE.WILD());

    // an unqualified component reference
    case (cache,env,DAE.CREF_IDENT(ident = n,subscriptLst = ss),impl) /* impl */
      equation
        (cache,_,t,_,_,_,_,_,_) = Lookup.lookupVar(cache, env, ComponentReference.makeCrefIdent(n,DAE.T_UNKNOWN_DEFAULT,{}));
        sl = Types.getDimensionSizes(t);
        (cache,ss_1) = Ceval.cevalSubscripts(cache, env, ss, sl, impl, Absyn.NO_MSG(),0);
        ty2 = Types.simplifyType(t);
      then
        (cache,ComponentReference.makeCrefIdent(n,ty2,ss_1));

    // a qualified component reference
    case (cache,env,DAE.CREF_QUAL(ident = n,subscriptLst = ss,componentRef = c),impl)
      equation
        (cache,_,t,_,_,_,_,componentEnv,_) = Lookup.lookupVar(cache, env, ComponentReference.makeCrefIdent(n,DAE.T_UNKNOWN_DEFAULT,{}));
        ty2 = Types.simplifyType(t);
        sl = Types.getDimensionSizes(t);
        (cache,ss_1) = Ceval.cevalSubscripts(cache, env, ss, sl, impl, Absyn.NO_MSG(),0);
       //(cache,c_1) = canonCref2(cache, env, c, ComponentReference.makeCrefIdent(n,ty2,ss), impl);
       (cache, c_1) = canonCref(cache, componentEnv, c, impl);
      then
        (cache,ComponentReference.makeCrefQual(n,ty2, ss_1,c_1));

    // failtrace
    case (_,_,cr,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Static.canonCref failed, cr: ");
        Debug.traceln(ComponentReference.printComponentRefStr(cr));
      then
        fail();
  end matchcontinue;
end canonCref;

protected function unevaluatedFunctionVariability
  "In a function we might have input arguments with unknown dimensions, and in
  that case we can't expand calls such as fill. A function call is therefore
  created with variable variability. This function checks that we're inside a
  function and returns DAE.C_VAR(), or fails if we're not inside a function.

  The exception is if checkModel is used, in which case we don't know what the
  variability would have been had all parameters received a binding. We can't
  set the variability to variable or parameter because then we might get
  bindings with higher variability than the component, and we can't set it to
  constant because that would cause the compiler to try and constant evaluate
  the call. So we set it to DAE.C_UNKNOWN() instead."
  input FCore.Graph inEnv;
  output DAE.Const outConst;
algorithm
  if FGraph.inFunctionScope(inEnv) then
    outConst := DAE.C_VAR();
  elseif Flags.getConfigBool(Flags.CHECK_MODEL) or Config.splitArrays() then
    // bug #2113, seems that there is nothing in the specs
    // that requires that fill arguments are of parameter/constant
    // variability, so allow it.
    outConst := DAE.C_UNKNOWN();
  else
    fail();
  end if;
end unevaluatedFunctionVariability;

protected function slotAnd
"Use with listFold to check if all slots have been filled"
  input Slot s;
  input Boolean b;
  output Boolean res;
algorithm
  SLOT(slotFilled = res) := s;
  res := b and res;
end slotAnd;

public function elabCodeExp
  input Absyn.Exp exp;
  input FCore.Cache cache;
  input FCore.Graph env;
  input DAE.CodeType ct;
  input Option<GlobalScript.SymbolTable> st;
  input SourceInfo info;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (exp,ct)
    local
      String s1,s2;
      Absyn.ComponentRef cr;
      Absyn.Path path;
      list<DAE.Exp> es_1;
      list<Absyn.Exp> es;
      DAE.Type et;
      Integer i;
      DAE.Exp dexp;
      DAE.Properties prop;
      DAE.Type ty;
      DAE.CodeType ct2;

    // first; try to elaborate the exp (maybe there is a binding in the environment that says v is a VariableName
    case (_,_)
      equation
        // adrpo: be very careful with this as it can take quite a long time, for example a call to:
        //        getDerivedClassModifierValue(Modelica.Fluid.Vessels.BaseClasses.PartialLumpedVessel.Medium.MassFlowRate,unit);
        //        will instantiate Modelica.Fluid.Vessels.BaseClasses.PartialLumpedVessel.Medium.MassFlowRate
        //        if we're not careful
        dexp = elabCodeExp_dispatch(exp,cache,env,ct,st,info);
      then
        dexp;

    // Expression
    case (_,DAE.C_EXPRESSION())
      then DAE.CODE(Absyn.C_EXPRESSION(exp),DAE.T_UNKNOWN_DEFAULT);

    // Type Name
    case (Absyn.CREF(componentRef=cr),DAE.C_TYPENAME())
      equation
        path = Absyn.crefToPath(cr);
      then DAE.CODE(Absyn.C_TYPENAME(path),DAE.T_UNKNOWN_DEFAULT);

    // Variable Names
    case (Absyn.ARRAY(es),DAE.C_VARIABLENAMES())
      equation
        es_1 = List.map5(es,elabCodeExp,cache,env,DAE.C_VARIABLENAME(),st,info);
        i = listLength(es);
        et = DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT, {DAE.DIM_INTEGER(i)}, DAE.emptyTypeSource);
      then DAE.ARRAY(et,false,es_1);

    case (_,DAE.C_VARIABLENAMES())
      equation
        et = DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT, {DAE.DIM_INTEGER(1)}, DAE.emptyTypeSource);
        dexp = elabCodeExp(exp,cache,env,DAE.C_VARIABLENAME(),st,info);
      then DAE.ARRAY(et,false,{dexp});

    // Variable Name
    case (Absyn.CREF(componentRef=cr),DAE.C_VARIABLENAME())
      then DAE.CODE(Absyn.C_VARIABLENAME(cr),DAE.T_UNKNOWN_DEFAULT);

    case (Absyn.CALL(Absyn.CREF_IDENT("der",{}),Absyn.FUNCTIONARGS(args={Absyn.CREF()},argNames={})),DAE.C_VARIABLENAME())
      then DAE.CODE(Absyn.C_EXPRESSION(exp),DAE.T_UNKNOWN_DEFAULT);

    // failure
    else
      equation
        failure(DAE.C_VARIABLENAMES() = ct);
        s1 = Dump.printExpStr(exp);
        s2 = Types.printCodeTypeStr(ct);
        Error.addSourceMessage(Error.ELAB_CODE_EXP_FAILED, {s1,s2}, info);
      then fail();
  end matchcontinue;
end elabCodeExp;

public function elabCodeExp_dispatch
"@author: adrpo
 evaluate a code expression.
 be careful how much you lookup"
  input Absyn.Exp exp;
  input FCore.Cache cache;
  input FCore.Graph env;
  input DAE.CodeType ct;
  input Option<GlobalScript.SymbolTable> st;
  input Absyn.Info info;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue exp
    local
      String s1,s2;
      Absyn.ComponentRef cr;
      Absyn.Path path;
      list<DAE.Exp> es_1;
      list<Absyn.Exp> es;
      DAE.Type et;
      Integer i;
      DAE.Exp dexp;
      DAE.Properties prop;
      DAE.Type ty;
      DAE.CodeType ct2;
      Absyn.Ident id;

    // for a component reference make sure the first ident is either "OpenModelica" or not a class
    case Absyn.CREF(componentRef=cr)
      equation
        ErrorExt.setCheckpoint("elabCodeExp_dispatch1");
        id = Absyn.crefFirstIdent(cr);
        _ = matchcontinue()
          case () // if the first one is OpenModelica, search
            equation
              true = id == "OpenModelica";
              (_,dexp,prop,_) = elabExpInExpression(cache,env,exp,false,st,false,Prefix.NOPRE(),info);
            then
              ();

          case () // not a class or OpenModelica, continue
            equation
              failure((_,_,_) = Lookup.lookupClass(cache, env, Absyn.IDENT(id), false));
              (_,dexp,prop,_) = elabExpInExpression(cache,env,exp,false,st,false,Prefix.NOPRE(),info);
            then
              ();

          // a class which is not OpenModelica, fail
          else fail();
        end matchcontinue;
        DAE.T_CODE(ty=ct2) = Types.getPropType(prop);
        true = valueEq(ct,ct2);
        ErrorExt.delCheckpoint("elabCodeExp_dispatch1");
        // print(ExpressionDump.printExpStr(dexp) + " " + Types.unparseType(ty) + "\n");
      then dexp;

    case Absyn.CREF()
      equation
        ErrorExt.rollBack("elabCodeExp_dispatch1");
      then fail();

    case _
      equation
        false = Absyn.isCref(exp);
        ErrorExt.setCheckpoint("elabCodeExp_dispatch");
        (_,dexp,prop,_) = elabExpInExpression(cache,env,exp,false,st,false,Prefix.NOPRE(),info);
        DAE.T_CODE(ty=ct2) = Types.getPropType(prop);
        true = valueEq(ct,ct2);
        ErrorExt.delCheckpoint("elabCodeExp_dispatch");
        // print(ExpressionDump.printExpStr(dexp) + " " + Types.unparseType(ty) + "\n");
      then dexp;

    else
      equation
        false = Absyn.isCref(exp);
        ErrorExt.rollBack("elabCodeExp_dispatch");
      then fail();

  end matchcontinue;
end elabCodeExp_dispatch;

public function elabArrayDims
  "Elaborates a list of array dimensions."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Subscript> inDimensions;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Dimensions outDimensions;
algorithm
  (outCache, outDimensions) := elabArrayDims2(inCache, inEnv, inComponentRef,
    inDimensions, inImplicit, inST, inDoVect, inPrefix, inInfo, {});
end elabArrayDims;

protected function elabArrayDims2
  "Helper function to elabArrayDims. Needed because of tail recursion."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inCref;
  input list<Absyn.Subscript> inDimensions;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  input DAE.Dimensions inElaboratedDims;
  output FCore.Cache outCache;
  output DAE.Dimensions outDimensions;
algorithm
  (outCache, outDimensions) := match(inCache, inEnv, inCref, inDimensions,
      inImplicit, inST, inDoVect, inPrefix, inInfo, inElaboratedDims)
    local
      FCore.Cache cache;
      Absyn.Subscript dim;
      list<Absyn.Subscript> rest_dims;
      DAE.Dimension elab_dim;
      DAE.Dimensions elab_dims;

    case (_, _, _, {}, _, _, _, _, _, _)
      then (inCache, listReverse(inElaboratedDims));

    case (_, _, _, dim :: rest_dims, _, _, _, _, _, _)
      equation
        (cache, elab_dim) = elabArrayDim(inCache, inEnv, inCref, dim,
          inImplicit, inST, inDoVect, inPrefix, inInfo);
        elab_dims = elab_dim :: inElaboratedDims;
        (cache, elab_dims) = elabArrayDims2(cache, inEnv, inCref, rest_dims,
          inImplicit, inST, inDoVect, inPrefix, inInfo, elab_dims);
      then
        (cache, elab_dims);
  end match;
end elabArrayDims2;

protected function elabArrayDim
  "Elaborates a single array dimension."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inCref;
  input Absyn.Subscript inDimension;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Dimension outDimension;
algorithm
  (outCache, outDimension) := matchcontinue(inCache, inEnv, inCref, inDimension,
      inImpl, inST, inDoVect, inPrefix, inInfo)
    local
      Absyn.ComponentRef cr;
      DAE.Dimension dim;
      FCore.Cache cache;
      FCore.Graph cenv;
      SCode.Element cls;
      Absyn.Path type_path, enum_type_name;
      String name;
      list<String> enum_literals;
      Integer enum_size;
      list<SCode.Element> el;
      Absyn.Exp sub, cr_exp;
      DAE.Exp e, dim_exp;
      DAE.Properties prop;
      list<SCode.Enum> enum_lst;
      Absyn.Exp size_arg;
      DAE.Type t;

    // The : operator results in an unknown dimension.
    case (_, _, _, Absyn.NOSUB(), _, _, _, _, _)
      then (inCache, DAE.DIM_UNKNOWN());

    // Size expression that refers to the array itself, such as
    // Real x(:, size(x, 1)).
    case (_, _, _, Absyn.SUBSCRIPT(subscript = Absyn.CALL(function_ =
        Absyn.CREF_IDENT(name = "size"), functionArgs = Absyn.FUNCTIONARGS(args =
        {cr_exp as Absyn.CREF(componentRef = cr), size_arg}))), _, _, _, _, _)
      equation
        true = Absyn.crefEqual(inCref, cr);
        (cache, e, _, _) = elabExpInExpression(inCache, inEnv, cr_exp, inImpl, inST,
          inDoVect, inPrefix, inInfo);
        (cache, dim_exp, _, _) = elabExpInExpression(cache, inEnv, size_arg, inImpl, inST,
          inDoVect, inPrefix, inInfo);
        dim = DAE.DIM_EXP(DAE.SIZE(e, SOME(dim_exp)));
        //dim = DAE.DIM_UNKNOWN();
      then
        (inCache, dim);

    case (_, _, _, Absyn.SUBSCRIPT(subscript = Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = "Boolean"))), _, _, _, _, _)
      then
        (inCache, DAE.DIM_BOOLEAN());

    // Array dimension from a Boolean or enumeration.
    case (cache, _, _, Absyn.SUBSCRIPT(subscript = Absyn.CREF(cr)), _, _, _, _, _)
      equation
        type_path = Absyn.crefToPath(cr);
        cache = Lookup.lookupClass(cache, inEnv, type_path, false);
        (cache, t) = Lookup.lookupType(cache, inEnv, type_path, NONE());
        dim = match t
          case DAE.T_ENUMERATION(index=NONE())
            then DAE.DIM_ENUM(t.path, t.names, listLength(t.names));
          case DAE.T_BOOL()
            then DAE.DIM_BOOLEAN();
        end match;
      then
        (cache, dim);

    // For all other cases we need to elaborate the subscript expression, so the
    // expression is elaborated and passed on to elabArrayDim2 to avoid doing
    // the elaboration several times.
    case (_, _, _, Absyn.SUBSCRIPT(subscript = sub), _, _, _, _, _)
      equation
        (cache, e, prop, _) = elabExpInExpression(inCache, inEnv, sub, inImpl, inST,
          inDoVect, inPrefix, inInfo);
        (cache, SOME(dim)) = elabArrayDim2(cache, inEnv, inCref, e, prop, inImpl, inST,
          inDoVect, inPrefix, inInfo);
      then
        (cache, dim);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Static.elabArrayDim failed on: " +
          Absyn.printComponentRefStr(inCref) +
          Dump.printArraydimStr({inDimension}));
      then
        fail();

  end matchcontinue;
end elabArrayDim;

protected function elabArrayDim2
  "Helper function to elabArrayDim. Continues the work from the last case in
  elabArrayDim to avoid unnecessary elaboration."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inCref;
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output Option<DAE.Dimension> outDimension;
algorithm
  (outCache, outDimension) := matchcontinue(inCache, inEnv, inCref, inExp, inProperties,
      inImpl, inST, inDoVect, inPrefix, inInfo)
    local
      DAE.Const cnst;
      FCore.Cache cache;
      DAE.Exp e;
      DAE.Type ty;
      String e_str, t_str, a_str;
      Integer i;

    // Constant dimension creates DIM_INTEGER.
    case (_, _, _, _, DAE.PROP(DAE.T_INTEGER(), cnst), _, _, _, _, _)
      equation
        true = Types.isParameterOrConstant(cnst);
        (cache, Values.INTEGER(i), _) = Ceval.ceval(inCache, inEnv, inExp, inImpl, inST);
      then
        (cache, SOME(DAE.DIM_INTEGER(i)));

    // When arrays are non-expanded, non-constant parametric dimensions are allowed.
    case (_, _, _, _, DAE.PROP(DAE.T_INTEGER(), DAE.C_PARAM()), _, _, _, _, _)
      equation
        false = Config.splitArrays();
      then
        (inCache, SOME(DAE.DIM_EXP(inExp)));

    // When not implicit instantiation, array dimension must be constant.
    case (_, _, _, _, DAE.PROP(DAE.T_INTEGER(), DAE.C_VAR()), false, _, _, _, _)
      equation
        e_str = ExpressionDump.printExpStr(inExp);
        Error.addSourceMessage(Error.DIMENSION_NOT_KNOWN, {e_str}, inInfo);
      then
        (inCache, NONE());

    // Non-constant dimension creates DIM_EXP.
    case (_, _, _, _, DAE.PROP(DAE.T_INTEGER(), _), true, _, _, _, _)
      equation
        (cache, e, _) =
          Ceval.cevalIfConstant(inCache, inEnv, inExp, inProperties, inImpl, inInfo);
      then
        (cache, SOME(DAE.DIM_EXP(e)));

    case (_, _, _, _, _, _, _, _, _, _)
      equation
        (cache, e as DAE.SIZE(_, _), _) =
          Ceval.cevalIfConstant(inCache, inEnv, inExp, inProperties, inImpl, inInfo);
      then
        (cache, SOME(DAE.DIM_EXP(e)));

    case (_, _, _, _, _, _, _, _, _, _)
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
      then
        (inCache, SOME(DAE.DIM_UNKNOWN()));

    // an integer parameter with no binding
    case (_, _, _, _, DAE.PROP(DAE.T_INTEGER(), cnst), _, _, _, _, _)
      equation
        true = Types.isParameterOrConstant(cnst);
        e_str = ExpressionDump.printExpStr(inExp);
        a_str = Dump.printComponentRefStr(inCref) + "[" + e_str + "]";
        Error.addSourceMessage(Error.STRUCTURAL_PARAMETER_OR_CONSTANT_WITH_NO_BINDING, {e_str, a_str}, inInfo);
        //(_, _) = elabArrayDim2(inCache, inEnv, inCref, inExp, inProperties, inImpl, inST, inDoVect, inPrefix, inInfo);
      then
        (inCache, NONE());

    case (_, _, _, _, DAE.PROP(ty, _), _, _, _, _, _)
      equation
        e_str = ExpressionDump.printExpStr(inExp);
        t_str = Types.unparseType(ty);
        Types.typeErrorSanityCheck(t_str, "Integer", inInfo);
        Error.addSourceMessage(Error.ARRAY_DIMENSION_INTEGER,
          {e_str, t_str}, inInfo);
      then
        (inCache, NONE());

  end matchcontinue;
end elabArrayDim2;

protected function consStrippedCref
  input Absyn.Exp e;
  input list<Absyn.Exp> es;
  output list<Absyn.Exp> oes;
algorithm
  oes := match (e,es)
    local
      Absyn.ComponentRef cr;
    case (Absyn.CREF(cr),_)
      equation
        cr = Absyn.crefStripLastSubs(cr);
      then Absyn.CREF(cr)::es;
    else es;
  end match;
end consStrippedCref;

protected function replaceEnd
  "Replaces end-expressions in a cref with the appropriate size-expressions."
  input Absyn.ComponentRef inCref;
  output Absyn.ComponentRef outCref;
protected
  list<Absyn.ComponentRef> cr_parts;
  Absyn.ComponentRef cr, cr_no_subs;
algorithm
  //print("Before replace: " + Dump.printComponentRefStr(inCref) + "\n");
  outCref :: cr_parts := Absyn.crefExplode(inCref);

  if not Absyn.crefIsIdent(outCref) then
    outCref := inCref;
    return;
  end if;

  if Absyn.crefIsFullyQualified(inCref) then
    outCref := Absyn.crefMakeFullyQualified(outCref);
  end if;

  outCref := replaceEndInSubs(Absyn.crefStripLastSubs(outCref), Absyn.crefLastSubs(outCref));

  for cr in cr_parts loop
    cr_no_subs := Absyn.crefStripLastSubs(cr);
    outCref := Absyn.joinCrefs(outCref, cr_no_subs);
    outCref := replaceEndInSubs(outCref, Absyn.crefLastSubs(cr));
  end for;
  //print("After replace: " + Dump.printComponentRefStr(outCref) + "\n");
end replaceEnd;

protected function replaceEndInSubs
  input Absyn.ComponentRef inCref;
  input list<Absyn.Subscript> inSubscripts;
  output Absyn.ComponentRef outCref = inCref;
protected
  list<Absyn.Subscript> subs = {};
  Absyn.Subscript new_sub;
  Integer i = 1;
algorithm
  if listEmpty(inSubscripts) then
    return;
  end if;

  for sub in inSubscripts loop
    new_sub := replaceEndInSub(sub, i, inCref);
    subs := new_sub :: subs;
    i := i + 1;
  end for;

  outCref := Absyn.crefSetLastSubs(outCref, listReverse(subs));
end replaceEndInSubs;

protected function replaceEndInSub
  input Absyn.Subscript inSubscript;
  input Integer inDimIndex;
  input Absyn.ComponentRef inCref;
  output Absyn.Subscript outSubscript;
algorithm
  outSubscript := match inSubscript
    case Absyn.SUBSCRIPT()
      then Absyn.SUBSCRIPT(replaceEndTraverser(inSubscript.subscript, (inCref, inDimIndex)));

    else inSubscript;
  end match;
end replaceEndInSub;

protected function replaceEndTraverser
  input Absyn.Exp inExp;
  input tuple<Absyn.ComponentRef, Integer> inTuple;
  output Absyn.Exp outExp;
algorithm
  outExp := match inExp
    local
      Absyn.ComponentRef cr;
      Integer i;

    case Absyn.END()
      algorithm
        (cr, i) := inTuple;
      then
        Absyn.CALL(Absyn.CREF_IDENT("size", {}),
          Absyn.FUNCTIONARGS({Absyn.CREF(cr), Absyn.INTEGER(i)}, {}));

    case Absyn.CREF()
      then Absyn.CREF(replaceEnd(inExp.componentRef));

    else Absyn.traverseExpShallow(inExp, inTuple, replaceEndTraverser);

  end match;
end replaceEndTraverser;

protected function fixTupleMetaModelica
  input list<DAE.Exp> exps;
  input list<DAE.Type> types;
  input list<DAE.TupleConst> consts;
  output DAE.Exp exp;
  output DAE.Properties prop;
protected
  DAE.Const c;
  list<DAE.Type> tys2;
  list<DAE.Exp> exps2;
algorithm
  if Config.acceptMetaModelicaGrammar() then
    c := Types.tupleConstListToConst(consts);
    tys2 := list(Types.boxIfUnboxedType(ty) for ty in types);
    (exps2, tys2) := Types.matchTypeTuple(exps, types, tys2, false);
    exp := DAE.META_TUPLE(exps2);
    prop := DAE.PROP(DAE.T_METATUPLE(tys2, DAE.emptyTypeSource), c);
  else
    exp := DAE.TUPLE(exps);
    prop := DAE.PROP_TUPLE(DAE.T_TUPLE(types, NONE(), DAE.emptyTypeSource), DAE.TUPLE_CONST(consts));
  end if;
end fixTupleMetaModelica;

protected function checkBuiltinCallArgs
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Integer inExpectedArgs;
  input String inFnName;
  input Absyn.Info inInfo;
protected
  String args_str, msg_str;
  list<String> pos_args, named_args;
algorithm
  if listLength(inPosArgs) <> inExpectedArgs or not listEmpty(inNamedArgs) then
    Error.addSourceMessageAndFail(Error.WRONG_NO_OF_ARGS, {inFnName}, inInfo);
  end if;
end checkBuiltinCallArgs;

annotation(__OpenModelica_Interface="frontend");
end Static;
