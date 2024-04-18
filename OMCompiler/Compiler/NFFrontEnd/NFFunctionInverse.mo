/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated uniontype NFFunctionInverse
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFFunction.Function;
  import NFInstNode.InstNode;
  import SCode;
  import Type = NFType;

protected
  import Inst = NFInst;
  import Lookup = NFLookup;
  import SCodeUtil;
  import Typing = NFTyping;

  import FunctionInverse = NFFunctionInverse;

public
  record FUNCTION_INV
    ComponentRef inputParam;
    Expression inverseCall;
    SourceInfo info;
  end FUNCTION_INV;

  function instInverses
    input InstNode fnNode;
    input Function fn;
    output array<FunctionInverse> inverses;
  protected
    list<SCode.Mod> inv_mods;
    list<FunctionInverse> invs = {};
  algorithm
    inv_mods := getInverseAnnotations(InstNode.definition(fnNode));

    if not listEmpty(inv_mods) and not listLength(fn.outputs) == 1 then
      Error.addSourceMessage(Error.FUNCTION_INVALID_OUTPUTS_FOR_INVERSE,
        {AbsynUtil.pathString(Function.name(fn))},
        SCodeUtil.getModifierInfo(listHead(inv_mods)));
      fail();
    end if;

    for m in inv_mods loop
      invs := instInverseMod(m, fnNode, fn, invs);
    end for;

    inverses := listArray(invs);
  end instInverses;

  function typeInverse
    input output FunctionInverse fnInv;
  algorithm
    fnInv.inputParam := Typing.typeCref(fnInv.inputParam, NFInstContext.RELAXED, fnInv.info);
    fnInv.inverseCall := Typing.typeExp(fnInv.inverseCall, NFInstContext.RELAXED, fnInv.info);
  end typeInverse;

  function toDAE
    input FunctionInverse fnInv;
    output DAE.FunctionDefinition invDef;
  algorithm
    invDef := DAE.FunctionDefinition.FUNCTION_INVERSE(
      ComponentRef.toDAE(fnInv.inputParam), Expression.toDAE(fnInv.inverseCall));
  end toDAE;

  function toSubMod
    input FunctionInverse fnInv;
    output SCode.SubMod subMod;
  protected
    SCode.SubMod inv_mod;
    Absyn.Exp call_exp;
  algorithm
    call_exp := Expression.toAbsyn(fnInv.inverseCall);
    inv_mod := SCode.SubMod.NAMEMOD(ComponentRef.firstName(fnInv.inputParam),
      SCode.Mod.MOD(SCode.Final.NOT_FINAL(), SCode.Each.NOT_EACH(), {}, SOME(call_exp), fnInv.info));
    subMod := SCode.SubMod.NAMEMOD("inverse",
      SCode.Mod.MOD(SCode.Final.NOT_FINAL(), SCode.Each.NOT_EACH(), {inv_mod}, NONE(), fnInv.info));
  end toSubMod;

protected
  function getInverseAnnotations
    input SCode.Element definition;
    output list<SCode.Mod> invMods;
  algorithm
    invMods := match definition
      local
        SCode.Annotation ann;

      case SCode.Element.CLASS(classDef = SCode.ClassDef.PARTS(
          externalDecl = SOME(SCode.ExternalDecl.EXTERNALDECL(annotation_ = SOME(ann)))))
        then SCodeUtil.lookupAnnotations(ann, "inverse");

      case SCode.Element.CLASS(cmt = SCode.Comment.COMMENT(annotation_ = SOME(ann)))
        then SCodeUtil.lookupAnnotations(ann, "inverse");

      else {};
    end match;
  end getInverseAnnotations;

  function instInverseMod
    input SCode.Mod mod;
    input InstNode fnNode;
    input Function fn;
    input output list<FunctionInverse> fnInvs;
  algorithm
    fnInvs := match mod
      case SCode.Mod.MOD()
        algorithm
          for s in mod.subModLst loop
            fnInvs := instInverseSubMod(s, fnNode, fn, mod.info, fnInvs);
          end for;
        then
          fnInvs;

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got invalid modifier", sourceInfo());
        then
          fail();

    end match;
  end instInverseMod;

  function instInverseSubMod
    input SCode.SubMod submod;
    input InstNode fnNode;
    input Function fn;
    input SourceInfo info;
    input output list<FunctionInverse> fnInvs;
  protected
    String name;
    Absyn.ComponentRef aparam;
    ComponentRef param;
    Absyn.Exp call_aexp;
    Expression call_exp;
  algorithm
    fnInvs := match submod
      // inverse(u = fn(...))
      case SCode.SubMod.NAMEMOD(ident = name, mod = SCode.Mod.MOD(
          subModLst = {}, binding = SOME(call_aexp as Absyn.Exp.CALL())))
        algorithm
          aparam := Absyn.ComponentRef.CREF_IDENT(name, {});

          // u must be an input parameter of the function that contains the inverse annotation.
          try
            param := Lookup.lookupLocalCref(aparam, fnNode, NFInstContext.RELAXED, info);
            true := InstNode.isInput(ComponentRef.node(param));
          else
            Error.addSourceMessage(Error.INVALID_FUNCTION_ANNOTATION_INPUT,
              {name, AbsynUtil.pathString(Function.name(fn))}, info);
            fail();
          end try;

          call_exp := Inst.instExp(call_aexp, fnNode, NFInstContext.RELAXED, info);
        then
          FUNCTION_INV(param, call_exp, info) :: fnInvs;

      case SCode.SubMod.NAMEMOD()
        algorithm
          Error.addStrictMessage(Error.INVALID_FUNCTION_ANNOTATION_ATTR,
            {submod.ident + SCodeDump.printModStr(submod.mod), "inverse"}, info);
        then
          fnInvs;

    end match;
  end instInverseSubMod;

  annotation(__OpenModelica_Interface="frontend");
end NFFunctionInverse;
