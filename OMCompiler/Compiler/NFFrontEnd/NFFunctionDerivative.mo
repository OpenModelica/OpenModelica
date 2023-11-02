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

encapsulated uniontype NFFunctionDerivative
  import Absyn;
  import AbsynUtil;
  import SCode;
  import NFInstNode.InstNode;
  import NFFunction.Function;
  import Expression = NFExpression;
  import Type = NFType;
  import Util;

protected
  import SCodeDump;
  import SCodeUtil;
  import Inst = NFInst;
  import Typing = NFTyping;
  import TypeCheck = NFTypeCheck;
  import MatchKind = NFTypeCheck.MatchKind;
  import Ceval = NFCeval;
  import EvalTarget = NFCeval.EvalTarget;
  import Prefixes = NFPrefixes;
  import NFPrefixes.Variability;
  import InstContext = NFInstContext;

  import FunctionDerivative = NFFunctionDerivative;

public
  type Condition = enumeration(ZERO_DERIVATIVE, NO_DERIVATIVE);

  record FUNCTION_DER
    InstNode derivativeFn;
    InstNode derivedFn;
    Expression order "Is evaluated to a literal Integer during typing";
    list<tuple<Integer, String, Condition>> conditions;
    list<InstNode> lowerOrderDerivatives;
  end FUNCTION_DER;

  function instDerivatives
    input InstNode fnNode;
    input Function fn;
    output list<FunctionDerivative> ders = {};
  protected
    list<SCode.Mod> der_mods;
    InstNode scope;
  algorithm
    der_mods := getDerivativeAnnotations(InstNode.definition(fnNode));
    scope := InstNode.parent(fnNode);

    for m in der_mods loop
      ders := instDerivativeMod(m, fnNode, fn, scope, ders);
    end for;
  end instDerivatives;

  function typeDerivative
    input FunctionDerivative fnDer;
  protected
    MatchKind mk;
    Expression order;
    Type order_ty;
    Variability var;
    SourceInfo info;
  algorithm
    Function.typeNodeCache(fnDer.derivativeFn);
    info := InstNode.info(fnDer.derivedFn);

    (order, order_ty, var) := Typing.typeExp(fnDer.order, NFInstContext.FUNCTION, info);
    (order, _, mk) := TypeCheck.matchTypes(order_ty, Type.INTEGER(), order);

    if TypeCheck.isIncompatibleMatch(mk) then
      Error.addSourceMessage(Error.VARIABLE_BINDING_TYPE_MISMATCH,
        {"order", Expression.toString(order), "Integer", Type.toString(order_ty)}, info);
      fail();
    end if;

    if var > Variability.CONSTANT then
      Error.addSourceMessage(Error.HIGHER_VARIABILITY_BINDING,
        {"order", Prefixes.variabilityString(Variability.CONSTANT),
         Expression.toString(order), Prefixes.variabilityString(var)}, info);
      fail();
    end if;

    order := Ceval.evalExp(order, EvalTarget.GENERIC(info));
  end typeDerivative;

  function toDAE
    input FunctionDerivative fnDer;
    output DAE.FunctionDefinition derDef;
  protected
    Integer order;
  algorithm
    Expression.INTEGER(order) := fnDer.order;

    derDef := DAE.FunctionDefinition.FUNCTION_DER_MAPPER(
      Function.name(listHead(Function.getCachedFuncs(fnDer.derivedFn))),
      Function.name(listHead(Function.getCachedFuncs(fnDer.derivativeFn))),
      order,
      list(conditionToDAE(c) for c in fnDer.conditions),
      // TODO: Figure out if the two fields below are needed.
      NONE(),
      list(Function.name(listHead(Function.getCachedFuncs(fn))) for fn in fnDer.lowerOrderDerivatives)
    );
  end toDAE;

  function conditionToDAE
    input tuple<Integer, String, Condition> cond;
    output tuple<Integer, DAE.derivativeCond> daeCond;
  protected
    Integer idx;
    Condition c;
  algorithm
    (idx, _, c) := cond;

    daeCond := match c
      case Condition.ZERO_DERIVATIVE
        then (idx, DAE.derivativeCond.ZERO_DERIVATIVE());
      // TODO: DAE.NO_DERIVATIVE contains an expression for historical reasons,
      //       but this was changed in Modelica 3.2 rev2 and should be removed
      //       from the DAE (it doesn't seem to have ever been used anyway).
      case Condition.NO_DERIVATIVE
        then (idx, DAE.derivativeCond.NO_DERIVATIVE(DAE.Exp.ICONST(99)));
    end match;
  end conditionToDAE;

  function toSubMod
    input FunctionDerivative fnDer;
    output SCode.SubMod subMod;
  protected
    tuple<Integer,Condition> tpl;
    Condition condition;
    String id;
    SCode.Mod mod;
    SCode.SubMod orderMod;
    list<SCode.SubMod> subMods;
    Integer order;
    SourceInfo info;
  algorithm
    info := InstNode.info(fnDer.derivedFn);
    Expression.INTEGER(order) := fnDer.order;
    orderMod := SCode.NAMEMOD("order", SCode.MOD(SCode.NOT_FINAL(), SCode.NOT_EACH(), {}, SOME(Absyn.INTEGER(order)), info));

    subMods := {};

    for tpl in fnDer.conditions loop
      (_, id, condition) := tpl;
      subMods := SCode.NAMEMOD(conditionToString(condition), SCode.MOD(SCode.NOT_FINAL(), SCode.NOT_EACH(), {}, SOME(Absyn.CREF(Absyn.CREF_IDENT(id, {}))), info)) :: subMods;
    end for;

    mod := SCode.MOD(SCode.NOT_FINAL(), SCode.NOT_EACH(), orderMod::subMods, SOME(Absyn.CREF(Absyn.CREF_IDENT(AbsynUtil.pathString(InstNode.scopePath(fnDer.derivativeFn)),{}))), info);
    subMod := SCode.NAMEMOD("derivative", mod);
  end toSubMod;

  function perfectFit
    "checks if the derivative is a perfect fit for specified interface map"
    input FunctionDerivative fnDer;
    input UnorderedMap<String, Boolean> interface_map;
    output Boolean b = true;
  protected
    String name;
    Condition cond;
  algorithm
    for condition in fnDer.conditions loop
      (_, name, cond) := condition;
      // if a zero derivative is required but the argument is not in the map
      // this function derivative cannot be used
      if cond == Condition.ZERO_DERIVATIVE and not UnorderedMap.contains(name, interface_map) then
        b := false;
        return;
      end if;
    end for;
    // the function derivative is a perfect fit, add all conditions to the interface
    for condition in fnDer.conditions loop
      (_, name, _) := condition;
      UnorderedMap.add(name, true, interface_map);
    end for;
  end perfectFit;

protected

  function conditionToString
    input Condition condition;
    output String str;
  algorithm
    str := match condition
      case Condition.NO_DERIVATIVE then "noDerivative";
      case Condition.ZERO_DERIVATIVE then "zeroDerivative";
      else String(condition);
    end match;
  end conditionToString;

  function getDerivativeAnnotations
    input SCode.Element definition;
    output list<SCode.Mod> derMods;
  algorithm
    derMods := match definition
      local
        SCode.Annotation ann;

      case SCode.Element.CLASS(classDef = SCode.ClassDef.PARTS(
          externalDecl = SOME(SCode.ExternalDecl.EXTERNALDECL(annotation_ = SOME(ann)))))
        then SCodeUtil.lookupAnnotations(ann, "derivative");

      case SCode.Element.CLASS(cmt = SCode.Comment.COMMENT(annotation_ = SOME(ann)))
        then SCodeUtil.lookupAnnotations(ann, "derivative");

      else {};
    end match;
  end getDerivativeAnnotations;

  function instDerivativeMod
    input SCode.Mod mod;
    input InstNode fnNode;
    input Function fn;
    input InstNode scope;
    input output list<FunctionDerivative> fnDers;
  algorithm
    fnDers := match mod
      local
        list<SCode.SubMod> attrs;
        Absyn.ComponentRef acref;
        InstNode der_node;
        Expression order;
        list<tuple<Integer, String, Condition>> conds;

      case SCode.Mod.MOD(subModLst = attrs, binding = SOME(Absyn.CREF(acref)))
        algorithm
          (_, der_node) := Function.instFunction(acref, scope, NFInstContext.NO_CONTEXT, mod.info);
          addLowerOrderDerivative(der_node, fnNode);
          (order, conds) := getDerivativeAttributes(attrs, fn, fnNode, mod.info);
        then
          FUNCTION_DER(der_node, fnNode, order, conds, {}) :: fnDers;

      // Give a warning if the derivative annotation doesn't specify a function name.
      case SCode.Mod.MOD()
        algorithm
          Error.addStrictMessage(Error.MISSING_FUNCTION_DERIVATIVE_NAME,
            {AbsynUtil.pathString(Function.name(fn))}, mod.info);
        then
          fnDers;

      // We shouldn't get any NOMODs here since they're filtered out when
      // translating Absyn to SCode, and redeclare isn't allowed by the syntax.
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got invalid modifier", sourceInfo());
        then
          fail();

    end match;
  end instDerivativeMod;

  function getDerivativeAttributes
    input list<SCode.SubMod> attrs;
    input Function fn;
    input InstNode scope;
    input SourceInfo info;
    output Expression order = Expression.EMPTY(Type.UNKNOWN());
    output list<tuple<Integer, String, Condition>> conditions = {};
  protected
    String id;
    SCode.Mod mod;
    Absyn.Exp aexp;
    Absyn.ComponentRef acref;
    Integer index;
  algorithm
    for attr in attrs loop
      SCode.SubMod.NAMEMOD(id, mod) := attr;

      () := match (id, mod)
        case ("order", SCode.Mod.MOD(binding = SOME(aexp)))
          algorithm
            if not Expression.isEmpty(order) then
              Error.addSourceMessage(Error.DUPLICATE_MODIFICATIONS,
                {id, "derivative"}, info);
            end if;

            order := Inst.instExp(aexp, scope, NFInstContext.NO_CONTEXT, info);
          then
            ();

        case ("noDerivative", SCode.Mod.MOD(binding = SOME(Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = id)))))
          algorithm
            index := getInputIndex(id, fn, info);
            conditions := (index, id, Condition.NO_DERIVATIVE) :: conditions;
          then
            ();

        case ("zeroDerivative", SCode.Mod.MOD(binding = SOME(Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = id)))))
          algorithm
            index := getInputIndex(id, fn, info);
            conditions := (index, id, Condition.ZERO_DERIVATIVE) :: conditions;
          then
            ();

        else
          algorithm
            Error.addStrictMessage(Error.INVALID_FUNCTION_ANNOTATION_ATTR,
              {id + (if SCodeUtil.isEmptyMod(mod) then "" else " = " + SCodeDump.printModStr(mod)), "derivative"}, info);
          then
            ();

      end match;
    end for;

    if Expression.isEmpty(order) then
      order := Expression.INTEGER(1);
    end if;
  end getDerivativeAttributes;

  function getInputIndex
    input String name;
    input Function fn;
    input SourceInfo info;
    output Integer index = 1;
  algorithm
    for i in fn.inputs loop
      if InstNode.name(i) == name then
        return;
      end if;

      index := index + 1;
    end for;

    Error.addSourceMessage(Error.INVALID_FUNCTION_ANNOTATION_INPUT,
      {name, AbsynUtil.pathString(Function.name(fn))}, info);
    fail();
  end getInputIndex;

  function addLowerOrderDerivative
    input InstNode fnNode;
    input InstNode lowerDerNode;
  algorithm
    Function.mapCachedFuncs(fnNode, function addLowerOrderDerivative2(lowerDerNode = lowerDerNode));
  end addLowerOrderDerivative;

  function addLowerOrderDerivative2
    input output Function fn;
    input InstNode lowerDerNode;
  algorithm
    fn.derivatives := list(
        match fn_der
          case FUNCTION_DER()
            algorithm
              fn_der.lowerOrderDerivatives := lowerDerNode :: fn_der.lowerOrderDerivatives;
            then
              fn_der;
        end match
      for fn_der in fn.derivatives);
  end addLowerOrderDerivative2;

  annotation(__OpenModelica_Interface="frontend");
end NFFunctionDerivative;

