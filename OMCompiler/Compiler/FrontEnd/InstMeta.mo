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

encapsulated package InstMeta
" file:        InstMeta.mo
  package:     InstMeta
  description: Different MetaModelica extension functions, for instantiation and later parts of the compiler.
"

import ClassInf;
import DAE;
import FCore;
import SCode;

protected

import Flags;
import Lookup;
import SCodeUtil;
import Types;

public function fixUniontype
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input ClassInf.State inState;
  input SCode.ClassDef inClassDef;
  output FCore.Cache cache = inCache;
  output Option<DAE.Type> outType;
algorithm
  outType := match (inState, inClassDef)
    local
      Absyn.Path p, p2, utPathOfRestriction, utPath;
      Boolean isSingleton;
      DAE.EvaluateSingletonType singletonType;
      FCore.Graph env_1;
      SCode.Element c;
      String name;
      list<Absyn.Path> paths;
      list<DAE.Type> typeVarsTypes;
      list<String> names, typeVars;
    case (ClassInf.META_UNIONTYPE(typeVars=typeVars), SCode.PARTS())
      algorithm
        utPath := inState.path;
        p := AbsynUtil.makeFullyQualified(inState.path);
        names := SCodeUtil.elementNames(list(
                                             e for e
                                               guard match e
                                                 case SCode.CLASS(restriction=SCode.R_METARECORD(name = utPathOfRestriction))
                                                   then AbsynUtil.pathSuffixOf(utPathOfRestriction, utPath);
                                                 else false;
                                               end match
                                        in inClassDef.elementLst));
        paths := list(AbsynUtil.suffixPath(p, n) for n in names);
        isSingleton := listLength(paths) == 1;
        if isSingleton then
          p2 := listGet(paths, 1);
          singletonType := DAE.EVAL_SINGLETON_TYPE_FUNCTION(function fixUniontype2(arr=arrayCreate(1, (cache, inEnv, p2, NONE()))));
        else
          singletonType := DAE.NOT_SINGLETON();
        end if;
        typeVarsTypes := list(DAE.T_METAPOLYMORPHIC(tv) for tv in typeVars);
      then
        SOME(DAE.T_METAUNIONTYPE(paths, typeVarsTypes, isSingleton, singletonType, p));
    else NONE();
  end match;
end fixUniontype;

protected function fixUniontype2
  input array<tuple<FCore.Cache, FCore.Graph, Absyn.Path, Option<DAE.Type>>> arr;
  output DAE.Type singletonType;
protected
  FCore.Cache cache;
  FCore.Graph env;
  Absyn.Path p;
  Option<DAE.Type> ot;
algorithm
  (cache,env,p,ot) := arrayGet(arr, 1);
  if isNone(ot) then
    (_, singletonType) := Lookup.lookupType(cache, env, p, SOME(sourceInfo()));
    arrayUpdate(arr, 1, (cache,env,p,SOME(singletonType)));
  else
    SOME(singletonType) := ot;
  end if;
end fixUniontype2;

public function checkArrayType
  "Checks that an array type is valid."
  input DAE.Type inType;
protected
  DAE.Type el_ty;
algorithm
  el_ty := Types.arrayElementType(inType);
  false := (not Types.isString(el_ty) and Types.isBoxedType(el_ty)) or
    Flags.isSet(Flags.RML);
end checkArrayType;

annotation(__OpenModelica_Interface="frontend");
end InstMeta;
