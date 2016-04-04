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

encapsulated package InstDAE
" file:        InstDAE.mo
  package:     InstDAE
  description: DAE generation


  This module is responsible for generating the DAE.

  "

public import Absyn;
public import ClassInf;
public import DAE;
public import FCore;
public import FGraph;
public import InnerOuter;
public import SCode;

protected import ComponentReference;
protected import Config;
protected import DAEUtil;
protected import Debug;
protected import ElementSource;
protected import Error;
protected import Flags;
protected import InstBinding;
protected import InstUtil;
protected import List;
protected import Types;
protected import DAEDump;
protected import System;
protected import Util;

protected type Ident = DAE.Ident "an identifier";
protected type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";
protected type InstDims = list<list<DAE.Dimension>>;

public function daeDeclare
"Given a global component name, a type, and a set of attributes, this function declares a component for the DAE result.
  Altough this function returns a list of DAE.Element, only one component is actually declared.
  The functions daeDeclare2 and daeDeclare3 below are helper functions that perform parts of the task.
  Note: Currently, this function can only declare scalar variables, i.e. the element type of an array type is used. To indicate that the variable
  is an array, the InstDims attribute is used. This will need to be redesigned in the futurue, when array variables should not be flattened out in the frontend."
  input FCore.Cache inCache;
  input FCore.Graph inParentEnv;
  input FCore.Graph inClassEnv;
  input DAE.ComponentRef inComponentRef;
  input ClassInf.State inState;
  input DAE.Type inType;
  input SCode.Attributes inAttributes;
  input SCode.Visibility visibility;
  input Option<DAE.Exp> inBinding;
  input list<list<DAE.Dimension>> inInstDims;
  input DAE.StartValue inStartValue;
  input Option<DAE.VariableAttributes> inVarAttr;
  input Option<SCode.Comment> inComment;
  input Absyn.InnerOuter io;
  input SCode.Final finalPrefix;
  input DAE.ElementSource source "the origin of the element";
  input Boolean declareComplexVars "if true, declare variables for complex variables, e.g. record vars in functions";
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(inCache, inParentEnv, inClassEnv, inComponentRef, inState, inType, inAttributes,
      visibility, inBinding, inInstDims, inStartValue, inVarAttr, inComment, io,
      finalPrefix, source, declareComplexVars)
    local
      DAE.ConnectorType ct1;
      DAE.DAElist dae;
      DAE.ComponentRef vn;
      DAE.VarParallelism daeParallelism;
      ClassInf.State ci_state;
      DAE.Type ty;
      SCode.ConnectorType ct;
      SCode.Visibility vis;
      SCode.Variability var;
      SCode.Parallelism prl;
      Absyn.Direction dir;
      Option<DAE.Exp> e,start;
      InstDims inst_dims;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      SourceInfo info;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.VarVisibility vv;

    case (_,_,_,vn,ci_state,ty,
          SCode.ATTR(connectorType = ct, parallelism = prl, variability = var,
            direction = dir),
          vis,e,inst_dims,start,dae_var_attr,comment,_,_,_,_)
      equation
        DAE.SOURCE(info,_,_,_,_,_,_) = source;
        ct1 = DAEUtil.toConnectorType(ct, ci_state);
        daeParallelism = DAEUtil.toDaeParallelism(vn,prl,ci_state,info);
        vk = InstUtil.makeDaeVariability(var);
        vd = InstUtil.makeDaeDirection(dir);
        vv = InstUtil.makeDaeProt(vis);
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr, SCode.finalBool(finalPrefix));
        dae = daeDeclare2(vn, ty, ct1, vk, vd, daeParallelism, vv, e, inst_dims, start, dae_var_attr, comment, io, source, declareComplexVars);

        showDAE(inCache,inParentEnv,inClassEnv,inState,dae);
      then
        dae;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Inst.daeDeclare failed\n");
      then
        fail();

  end matchcontinue;
end daeDeclare;

protected function showDAE
  input FCore.Cache inCache;
  input FCore.Graph inParentEnv;
  input FCore.Graph inClassEnv;
  input ClassInf.State inState;
  input DAE.DAElist inDAE;
algorithm
  _ := matchcontinue(inCache, inParentEnv, inClassEnv, inState, inDAE)
    local
      String str, sstr;
      DAE.Element comp;
      DAE.DAElist dae;
      list<DAE.Element> els;

    case (_, _, _, _, _)
      equation
        false = Flags.isSet(Flags.SHOW_DAE_GENERATION);
      then
        ();

    case (_, _, _, _, _)
      equation
        els = DAEUtil.daeElements(inDAE);
        sstr = ClassInf.printStateStr(inState);
        sstr = "'" + sstr + "'";
        comp = DAE.COMP(sstr, els, DAE.emptyElementSource, NONE());
        dae = DAE.DAE({comp});
        str = if System.getPartialInstantiation() then " partial" else " full";
        print("DAE: parent: " + FGraph.getGraphNameStr(inParentEnv) +
              " class: " + FGraph.getGraphNameStr(inClassEnv) + " state: " + sstr + str + "\n" +
              DAEDump.dumpStr(dae, DAE.emptyFuncTree) + "\n");
      then
        ();

    case (_, _, _, _, _)
      equation
        str = if System.getPartialInstantiation() then " partial" else " full";
        print("DAE: " + ClassInf.printStateStr(inState) + str + " - could not print\n");
      then ();

    else ();

  end matchcontinue;
end showDAE;

protected function daeDeclare2
"Helper function to daeDeclare."
  input DAE.ComponentRef inComponentRef;
  input DAE.Type inType;
  input DAE.ConnectorType inConnectorType;
  input DAE.VarKind inVarKind;
  input DAE.VarDirection inVarDirection;
  input DAE.VarParallelism inParallelism;
  input DAE.VarVisibility protection;
  input Option<DAE.Exp> inExpExpOption;
  input list<list<DAE.Dimension>> inInstDims;
  input DAE.StartValue inStartValue;
  input Option<DAE.VariableAttributes> inAttr;
  input Option<SCode.Comment> inComment;
  input Absyn.InnerOuter io;
  input DAE.ElementSource source "the origin of the element";
  input Boolean declareComplexVars;
  output DAE.DAElist outDAe;
algorithm
  outDAe := matchcontinue(inComponentRef, inType, inConnectorType, inVarKind,
      inVarDirection, inParallelism, protection, inExpExpOption, inInstDims,
      inStartValue, inAttr, inComment, io, source, declareComplexVars)
    local
      DAE.ComponentRef vn,c;
      DAE.ConnectorType ct;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.VarParallelism daePrl;
      Option<DAE.Exp> e,start;
      InstDims inst_dims;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      list<String> l;
      DAE.DAElist dae;
      ClassInf.State ci;
      Integer dim;
      String s;
      DAE.Type ty,tp;
      DAE.VarVisibility prot;
      list<DAE.Dimension> finst_dims;
      Absyn.Path path;
      DAE.Type tty;
      SourceInfo info;

    case (vn,DAE.T_INTEGER(),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_)
      equation
        finst_dims = List.flatten(inst_dims);
      then DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,DAE.T_INTEGER_DEFAULT,e,finst_dims,ct,source,dae_var_attr,comment,io)});

    case (vn,DAE.T_REAL(),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_)
      equation
        finst_dims = List.flatten(inst_dims);
      then DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,DAE.T_REAL_DEFAULT,e,finst_dims,ct,source,dae_var_attr,comment,io)});

    case (vn,DAE.T_BOOL(),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_)
      equation
        finst_dims = List.flatten(inst_dims);
      then DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,DAE.T_BOOL_DEFAULT,e,finst_dims,ct,source,dae_var_attr,comment,io)});
    // BTH
    case (vn,DAE.T_CLOCK(),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_)
      equation
        finst_dims = List.flatten(inst_dims);
      then DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,DAE.T_CLOCK_DEFAULT,e,finst_dims,ct,source,dae_var_attr,comment,io)});

    case (vn,DAE.T_STRING(),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_)
      equation
        finst_dims = List.flatten(inst_dims);
      then DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,DAE.T_STRING_DEFAULT,e,finst_dims,ct,source,dae_var_attr,comment,io)});

    case (_,DAE.T_ENUMERATION(index = SOME(_)),_,_,_,_,_,_,_,_,_,_,_,_,_)
    then DAE.emptyDae;

    // We should not declare each enumeration value of an enumeration when instantiating,
    // e.g Myenum my !=> constant EnumType my.enum1,... {DAE.VAR(vn, kind, dir, DAE.ENUM, e, inst_dims)}
    // instantiation of complex type extending from basic type
    case (vn,ty as DAE.T_ENUMERATION(),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_)
      equation
        finst_dims = List.flatten(inst_dims);
      then DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,ty,e,finst_dims,ct,source,dae_var_attr,comment,io)});

     // complex type that is ExternalObject
    case (vn, ty as DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_)),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_)
       equation
         finst_dims = List.flatten(inst_dims);
      then
      DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,ty,e,finst_dims,ct,source,dae_var_attr,comment,io)});

    // instantiation of complex type extending from basic type
    case (vn,DAE.T_SUBTYPE_BASIC(complexType = tp),ct,kind,dir,daePrl,prot,e,inst_dims,start,dae_var_attr,comment,_,_,_)
      equation
        (_,dae_var_attr) = InstBinding.instDaeVariableAttributes(FCore.emptyCache(),FGraph.empty(), DAE.NOMOD(), tp, {});
        dae = daeDeclare2(vn,tp,ct,kind,dir,daePrl,prot,e,inst_dims,start,dae_var_attr,comment,io,source,declareComplexVars);
    then dae;

    // array that extends basic type
    case (vn,DAE.T_ARRAY(dims = {DAE.DIM_INTEGER()},ty = tp),ct,kind,dir,daePrl,prot,e,inst_dims,start,dae_var_attr,comment,_,_,_)
      equation
        dae = daeDeclare2(vn, tp, ct, kind, dir, daePrl, prot,e, inst_dims, start, dae_var_attr,comment,io,source,declareComplexVars);
      then dae;

    // Arrays with unknown dimension are allowed if not expanded
    case (vn,DAE.T_ARRAY(ty = tp),ct,kind,dir,daePrl,prot,e,inst_dims,start,dae_var_attr,comment,_,_,_)
      equation
        false = Config.splitArrays();
        dae = daeDeclare2(vn, tp, ct, kind, dir, daePrl, prot,e, inst_dims, start, dae_var_attr,comment,io,source,declareComplexVars);
      then
        dae;

    // if arrays are expanded and dimension is unknown, report an error
    case (vn,DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()}),_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = Config.splitArrays();
        s = ComponentReference.printComponentRefStr(vn);
        info = ElementSource.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.DIMENSION_NOT_KNOWN, {s}, info);
      then
        fail();

    // Complex/Record components, only if declareComplexVars is true
    case(vn,ty as DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,true)
      equation
        finst_dims = List.flatten(inst_dims);
      then
        DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,ty,e,finst_dims,ct,source,dae_var_attr,comment,io)});

    // MetaModelica extensions
    case (vn,tty as DAE.T_FUNCTION(),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_)
      equation
        finst_dims = List.flatten(inst_dims);
        path = ComponentReference.crefToPath(vn);
        ty = Types.setTypeSource(tty,Types.mkTypeSource(SOME(path)));
      then
        DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,ty,e,finst_dims,ct,source,dae_var_attr,comment,io)});

    // MetaModelica extension
    case (vn,ty,ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        true = Types.isBoxedType(ty);
        finst_dims = List.flatten(inst_dims);
      then
        DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,ty,e,finst_dims,ct,source,dae_var_attr,comment,io)});
    /*----------------------------*/

    else DAE.emptyDae;
  end matchcontinue;
end daeDeclare2;

annotation(__OpenModelica_Interface="frontend");
end InstDAE;
