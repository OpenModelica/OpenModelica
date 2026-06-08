/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package InstBasics
" file:        InstBasics.mo
  package:     InstBasics
  description: Instantiation utilities


  This package supports Inst*.mo and NFFrontend
"
import Absyn;
import DAE;
import SCode;
protected
import SCodeUtil;

public function commentIsInlineFunc
  input SCode.Comment cmt;
  output DAE.InlineType outInlineType;
algorithm
  outInlineType := matchcontinue cmt
    local
      list<SCode.SubMod> smlst;

    case SCode.COMMENT(annotation_=SOME(SCode.ANNOTATION(SCode.MOD(subModLst = smlst))))
      then isInlineFunc2(smlst);

    else DAE.DEFAULT_INLINE();
  end matchcontinue;
end commentIsInlineFunc;

protected function isInlineFunc2
  input list<SCode.SubMod> inSubModList;
  output DAE.InlineType res;
protected
  Boolean stop = false;
algorithm

  res := DAE.DEFAULT_INLINE();

  for tp in inSubModList loop
    stop := match tp

       case SCode.NAMEMOD("Inline",SCode.MOD(binding = SOME(Absyn.BOOL(true))))
         algorithm
           res := DAE.NORM_INLINE();
         then false;

       case SCode.NAMEMOD("Inline",SCode.MOD(binding = SOME(Absyn.BOOL(false))))
         algorithm
           res := DAE.NO_INLINE();
         then false;

       case SCode.NAMEMOD("LateInline",SCode.MOD(binding = SOME(Absyn.BOOL(true))))
         algorithm
          res := DAE.AFTER_INDEX_RED_INLINE();
         then true;

       case SCode.NAMEMOD("__MathCore_InlineAfterIndexReduction",SCode.MOD(binding = SOME(Absyn.BOOL(true))))
         algorithm
          res := DAE.AFTER_INDEX_RED_INLINE();
         then true;

       case SCode.NAMEMOD("__Dymola_InlineAfterIndexReduction",SCode.MOD(binding = SOME(Absyn.BOOL(true))))
         algorithm
          res := DAE.AFTER_INDEX_RED_INLINE();
         then true;

       case SCode.NAMEMOD("InlineAfterIndexReduction",SCode.MOD(binding = SOME(Absyn.BOOL(true))))
         algorithm
          res := DAE.AFTER_INDEX_RED_INLINE();
         then true;

       case SCode.NAMEMOD("__OpenModelica_EarlyInline",SCode.MOD(binding = SOME(Absyn.BOOL(true))))
         algorithm
          res := DAE.EARLY_INLINE();
         then true;
       else false;
       end match;

     if stop then
       break;
     end if;

  end for;

end isInlineFunc2;

public function commentGenerateEvents
  input SCode.Comment cmt;
  output Boolean generateEvents;
protected
  function commentGenerateEvents2
    input list<SCode.SubMod> inSubModList;
    output Boolean res;
  protected
    Boolean stop;
  algorithm
    res := false;

    for tp in inSubModList loop
      stop := match tp
        case SCode.NAMEMOD("GenerateEvents",SCode.MOD(binding = SOME(Absyn.BOOL(res)))) then false;
        else true;
      end match;

     if stop then break; end if;
    end for;
  end commentGenerateEvents2;
algorithm
  generateEvents := match cmt
    local
      list<SCode.SubMod> smlst;

    case SCode.COMMENT(annotation_=SOME(SCode.ANNOTATION(SCode.MOD(subModLst = smlst))))
      then commentGenerateEvents2(smlst);

    else false;
  end match;
end commentGenerateEvents;

public function getFunctionRestrictionPurity
  input Absyn.FunctionPurity purity;
  input SCode.Comment cmt;
  input Boolean newFrontend;
  output DAE.Purity outPurity;
algorithm
  outPurity := match purity
    case Absyn.FunctionPurity.PURE() then DAE.Purity.PURE;
    case Absyn.FunctionPurity.IMPURE() then DAE.Purity.IMPURE;
    else DAE.Purity.UNDEFINED;
  end match;

  if outPurity == DAE.Purity.UNDEFINED then
    if SCodeUtil.commentHasBooleanNamedAnnotation(cmt, "__ModelicaAssociation_Impure") then
      outPurity := DAE.Purity.IMPURE;
    elseif not newFrontend and SCodeUtil.commentHasBooleanNamedAnnotation(cmt, "__OpenModelica_Impure") then
      // __OpenModelica_Impure is only used for MetaModelica, which the NF doesn't care about.
      outPurity := DAE.Purity.OM_IMPURE;
    end if;
  end if;
end getFunctionRestrictionPurity;

annotation(__OpenModelica_Interface="frontend_dump");
end InstBasics;