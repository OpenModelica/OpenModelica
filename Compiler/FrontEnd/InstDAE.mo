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

encapsulated package InstDAE
" file:        InstDAE.mo
  package:     InstDAE
  description: DAE generation

  RCS: $Id: InstDAE.mo 17556 2013-10-05 23:58:57Z adrpo $

  This module is responsible for generating the DAE.
  
  "

public import Absyn;
public import ClassInf;
public import DAE;
public import Env;
public import InnerOuter;
public import SCode;

protected type Ident = DAE.Ident "an identifier";
protected type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";
protected type InstDims = list<list<DAE.Subscript>>;

protected import DAEUtil;
protected import List;
protected import InstBinding;
protected import InstUtil;
protected import Config;
protected import ComponentReference;
protected import Error;
protected import Types;
protected import Debug;
protected import Flags;

public function daeDeclare
"Given a global component name, a type, and a set of attributes, this function declares a component for the DAE result.
  Altough this function returns a list of DAE.Element, only one component is actually declared.
  The functions daeDeclare2 and daeDeclare3 below are helper functions that perform parts of the task.
  Note: Currently, this function can only declare scalar variables, i.e. the element type of an array type is used. To indicate that the variable
  is an array, the InstDims attribute is used. This will need to be redesigned in the futurue, when array variables should not be flattened out in the frontend.
  "
  input DAE.ComponentRef inComponentRef;
  input ClassInf.State inState;
  input DAE.Type inType;
  input SCode.Attributes inAttributes;
  input SCode.Visibility visibility;
  input Option<DAE.Exp> inExpExpOption;
  input list<list<DAE.Subscript>>inInstDims;
  input DAE.StartValue inStartValue;
  input Option<DAE.VariableAttributes> inDAEVariableAttributesOption;
  input Option<SCode.Comment> inAbsynCommentOption;
  input Absyn.InnerOuter io;
  input SCode.Final finalPrefix;
  input DAE.ElementSource source "the origin of the element";
  input Boolean declareComplexVars "if true, declare variables for complex variables, e.g. record vars in functions";
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue (inComponentRef,inState,inType,inAttributes,visibility,inExpExpOption,
                                     inInstDims,inStartValue,inDAEVariableAttributesOption,inAbsynCommentOption,
                                     io,finalPrefix,source,declareComplexVars )
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
      Absyn.Info info;

    case (vn,ci_state,ty,
          SCode.ATTR(connectorType = ct, parallelism = prl, variability = var,
            direction = dir),
          vis,e,inst_dims,start,dae_var_attr,comment,_,_,_,_)
      equation
        DAE.SOURCE(info,_,_,_,_,_,_) = source;
        ct1 = DAEUtil.toConnectorType(ct, ci_state);
        daeParallelism = DAEUtil.toDaeParallelism(vn,prl,ci_state,info);
        dae = daeDeclare2(vn, ty, ct1, var, dir, daeParallelism, vis, e, inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,declareComplexVars );
      then
        dae;
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- Inst.daeDeclare failed");
      then
        fail();
  end matchcontinue;
end daeDeclare;

protected function daeDeclare2
"Helper function to daeDeclare."
  input DAE.ComponentRef inComponentRef;
  input DAE.Type inType;
  input DAE.ConnectorType inConnectorType;
  input SCode.Variability inVariability;
  input Absyn.Direction inDirection;
  input DAE.VarParallelism inParallelism;
  input SCode.Visibility visibility;
  input Option<DAE.Exp> inExpExpOption;
  input list<list<DAE.Subscript>>inInstDims;
  input DAE.StartValue inStartValue;
  input Option<DAE.VariableAttributes> inDAEVariableAttributesOption;
  input Option<SCode.Comment> inAbsynCommentOption;
  input Absyn.InnerOuter io;
  input SCode.Final finalPrefix;
  input DAE.ElementSource source "the origin of the element";
  input Boolean declareComplexVars;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue (inComponentRef,inType,inConnectorType,inVariability,inDirection,inParallelism,visibility,inExpExpOption,
                           inInstDims,inStartValue,inDAEVariableAttributesOption,inAbsynCommentOption,io,finalPrefix,
                           source,declareComplexVars)
    local
      DAE.DAElist dae;
      DAE.ComponentRef vn;
      DAE.Type ty;
      DAE.ConnectorType ct;
      DAE.VarParallelism daePrl;
      Absyn.Direction dir;
      Option<DAE.Exp> e,start;
      InstDims inst_dims;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      SCode.Visibility vis;

    case (vn,ty,ct,SCode.VAR(),dir,daePrl,vis,e,inst_dims,start,dae_var_attr,comment,_,_,_,_)
      equation
        dae = daeDeclare3(vn, ty, ct, DAE.VARIABLE(), dir, daePrl, vis, e, inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,declareComplexVars);
      then
        dae;
    case (vn,ty,ct,SCode.DISCRETE(),dir,daePrl,vis,e,inst_dims,start,dae_var_attr,comment,_,_,_,_)
      equation
        dae = daeDeclare3(vn, ty, ct, DAE.DISCRETE(), dir, daePrl, vis, e, inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,declareComplexVars );
      then
        dae;
    case (vn,ty,ct,SCode.PARAM(),dir,daePrl,vis,e,inst_dims,start,dae_var_attr,comment,_,_,_,_)
      equation
        dae = daeDeclare3(vn, ty, ct, DAE.PARAM(), dir, daePrl, vis, e, inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,declareComplexVars );
      then
        dae;
    case (vn,ty,ct,SCode.CONST(),dir,daePrl,vis,e,inst_dims,start,dae_var_attr,comment,_,_,_,_)
      equation
        dae = daeDeclare3(vn, ty, ct,DAE.CONST(), dir, daePrl, vis, e, inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,declareComplexVars );
      then
        dae;
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- Inst.daeDeclare2 failed");
      then
        fail();
  end matchcontinue;
end daeDeclare2;

protected function daeDeclare3
"Helper function to daeDeclare2."
  input DAE.ComponentRef inComponentRef;
  input DAE.Type inType;
  input DAE.ConnectorType inConnectorType;
  input DAE.VarKind inVarKind;
  input Absyn.Direction inDirection;
  input DAE.VarParallelism inParallelism;
  input SCode.Visibility visibility;
  input Option<DAE.Exp> inExpExpOption;
  input list<list<DAE.Subscript>>inInstDims;
  input DAE.StartValue inStartValue;
  input Option<DAE.VariableAttributes> inDAEVariableAttributesOption;
  input Option<SCode.Comment> inAbsynCommentOption;
  input Absyn.InnerOuter io;
  input SCode.Final finalPrefix;
  input DAE.ElementSource source "the origin of the element";
  input Boolean declareComplexVars;
  output DAE.DAElist outDae;
algorithm
  outDae := match (inComponentRef,inType,inConnectorType,inVarKind,inDirection,inParallelism,visibility,inExpExpOption,inInstDims,
                   inStartValue,inDAEVariableAttributesOption,inAbsynCommentOption,io,finalPrefix,source,declareComplexVars)
    local
      DAE.DAElist dae;
      DAE.ComponentRef vn;
      DAE.Type ty;
      DAE.ConnectorType ct;
      DAE.VarKind vk;
      DAE.VarParallelism daePrl;
      Option<DAE.Exp> e,start;
      InstDims inst_dims;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      SCode.Visibility vis;
      DAE.VarVisibility prot1;

    case (vn,ty,ct,vk,Absyn.INPUT(),daePrl,vis,e,inst_dims,start,dae_var_attr,comment,_,_,_,_)
      equation
        prot1 = InstUtil.makeDaeProt(vis);
        dae = daeDeclare4(vn, ty, ct, vk, DAE.INPUT(), daePrl, prot1, e, inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,declareComplexVars);
      then
        dae;
    case (vn,ty,ct,vk,Absyn.OUTPUT(), daePrl, vis,e,inst_dims,start,dae_var_attr,comment,_,_,_,_)
      equation
        prot1 = InstUtil.makeDaeProt(vis);
        dae = daeDeclare4(vn, ty, ct, vk, DAE.OUTPUT(), daePrl, prot1, e, inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,declareComplexVars);
      then
        dae;
    case (vn,ty,ct,vk,Absyn.BIDIR(), daePrl, vis,e,inst_dims,start,dae_var_attr,comment,_,_,_,_)
      equation
        prot1 = InstUtil.makeDaeProt(vis);
        dae = daeDeclare4(vn, ty, ct, vk, DAE.BIDIR(), daePrl, prot1, e, inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,declareComplexVars);
      then
        dae;
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        //Debug.fprintln(Flags.FAILTRACE, "- Inst.daeDeclare3 failed");
      then
        fail();
  end match;
end daeDeclare3;

protected function daeDeclare4
"Helper function to daeDeclare3."
  input DAE.ComponentRef inComponentRef;
  input DAE.Type inType;
  input DAE.ConnectorType inConnectorType;
  input DAE.VarKind inVarKind;
  input DAE.VarDirection inVarDirection;
  input DAE.VarParallelism inParallelism;
  input DAE.VarVisibility protection;
  input Option<DAE.Exp> inExpExpOption;
  input list<list<DAE.Subscript>>inInstDims;
  input DAE.StartValue inStartValue;
  input Option<DAE.VariableAttributes> inDAEVariableAttributesOption;
  input Option<SCode.Comment> inAbsynCommentOption;
  input Absyn.InnerOuter io;
  input SCode.Final finalPrefix;
  input DAE.ElementSource source "the origin of the element";
  input Boolean declareComplexVars;
  output DAE.DAElist outDAe;
algorithm
  outDAe :=
  matchcontinue (inComponentRef,inType,inConnectorType,inVarKind,inVarDirection,inParallelism,protection,inExpExpOption,inInstDims,
                 inStartValue,inDAEVariableAttributesOption,inAbsynCommentOption,io,finalPrefix,source,declareComplexVars)
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
      list<DAE.Subscript> finst_dims;
      Absyn.Path path;
      DAE.Type tty;
      Absyn.Info info;

    case (_,_,_,_,_,_,_,_,_,_,dae_var_attr,_,_,_,_,_)
      equation
        // print("daeDeclare4: " +& ComponentReference.printComponentRefStr(vn) +& " " +& SCode.finalStr(finalPrefix) +& "\n");
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,SCode.finalBool(finalPrefix));
      then
        fail();

    case (vn,DAE.T_INTEGER(varLst = _),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_,_)
      equation
        finst_dims = List.flatten(inst_dims);
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,SCode.finalBool(finalPrefix));
      then DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,DAE.T_INTEGER_DEFAULT,e,finst_dims,ct,source,dae_var_attr,comment,io)});

    case (vn,DAE.T_REAL(varLst = _),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_,_)
      equation
        finst_dims = List.flatten(inst_dims);
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,SCode.finalBool(finalPrefix));
      then DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,DAE.T_REAL_DEFAULT,e,finst_dims,ct,source,dae_var_attr,comment,io)});

    case (vn,DAE.T_BOOL(varLst = _),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_,_)
      equation
        finst_dims = List.flatten(inst_dims);
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,SCode.finalBool(finalPrefix));
      then DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,DAE.T_BOOL_DEFAULT,e,finst_dims,ct,source,dae_var_attr,comment,io)});

    case (vn,DAE.T_STRING(varLst = _),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_,_)
      equation
        finst_dims = List.flatten(inst_dims);
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,SCode.finalBool(finalPrefix));
      then DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,DAE.T_STRING_DEFAULT,e,finst_dims,ct,source,dae_var_attr,comment,io)});

    case (_,DAE.T_ENUMERATION(index = SOME(_)),_,_,_,_,_,_,_,_,_,_,_,_,_,_)
    then DAE.emptyDae;

    // We should not declare each enumeration value of an enumeration when instantiating,
    // e.g Myenum my !=> constant EnumType my.enum1,... {DAE.VAR(vn, kind, dir, DAE.ENUM, e, inst_dims)}
    // instantiation of complex type extending from basic type
    case (vn,ty as DAE.T_ENUMERATION(names = _),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_,_)
      equation
        finst_dims = List.flatten(inst_dims);
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,SCode.finalBool(finalPrefix));
      then DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,ty,e,finst_dims,ct,source,dae_var_attr,comment,io)});

     // complex type that is ExternalObject
     case (vn, ty as DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_)),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_,_)
       equation
         finst_dims = List.flatten(inst_dims);
         dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,SCode.finalBool(finalPrefix));
       then DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,ty,e,finst_dims,ct,source,dae_var_attr,comment,io)});

    // instantiation of complex type extending from basic type
    case (vn,DAE.T_SUBTYPE_BASIC(complexClassType = _,complexType = tp),ct,kind,dir,daePrl,prot,e,inst_dims,start,dae_var_attr,comment,_,_,_,_)
      equation
        (_,dae_var_attr) = InstBinding.instDaeVariableAttributes(Env.emptyCache(),Env.emptyEnv, DAE.NOMOD(), tp, {});
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,SCode.finalBool(finalPrefix));
        dae = daeDeclare4(vn,tp,ct,kind,dir,daePrl,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars);
    then dae;

    // array that extends basic type
    case (vn,DAE.T_ARRAY(dims = {DAE.DIM_INTEGER(integer = _)},ty = tp),ct,kind,dir,daePrl,prot,e,inst_dims,start,dae_var_attr,comment,_,_,_,_)
      equation
        dae = daeDeclare4(vn, tp, ct, kind, dir, daePrl, prot,e, inst_dims, start, dae_var_attr,comment,io,finalPrefix,source,declareComplexVars);
      then dae;

    // Arrays with unknown dimension are allowed if not expanded
    case (vn,DAE.T_ARRAY(dims = _, ty = tp),ct,kind,dir,daePrl,prot,e,inst_dims,start,dae_var_attr,comment,_,_,_,_)
      equation
        false = Config.splitArrays();
        dae = daeDeclare4(vn, tp, ct, kind, dir, daePrl, prot,e, inst_dims, start, dae_var_attr,comment,io,finalPrefix,source,declareComplexVars);
      then
        dae;

    // if arrays are expanded and dimension is unknown, report an error
    case (vn,DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()}, ty = _),_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = Config.splitArrays();
        s = ComponentReference.printComponentRefStr(vn);
        info = DAEUtil.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.DIMENSION_NOT_KNOWN, {s}, info);
      then
        fail();

    // Complex/Record components, only if declareComplexVars is true
    case(vn,ty as DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_,true)
      equation
        finst_dims = List.flatten(inst_dims);
      then
        DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,ty,e,finst_dims,ct,source,dae_var_attr,comment,io)});

    // MetaModelica extensions
    case (vn,tty as DAE.T_FUNCTION(funcArg = _),ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_,_)
      equation
        finst_dims = List.flatten(inst_dims);
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,SCode.finalBool(finalPrefix));
        path = ComponentReference.crefToPath(vn);
        ty = Types.setTypeSource(tty,Types.mkTypeSource(SOME(path)));
      then
        DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,ty,e,finst_dims,ct,source,dae_var_attr,comment,io)});

    // MetaModelica extension
    case (vn,ty,ct,kind,dir,daePrl,prot,e,inst_dims,_,dae_var_attr,comment,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        true = Types.isBoxedType(ty);
        finst_dims = List.flatten(inst_dims);
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,SCode.finalBool(finalPrefix));
      then
        DAE.DAE({DAE.VAR(vn,kind,dir,daePrl,prot,ty,e,finst_dims,ct,source,dae_var_attr,comment,io)});
    /*----------------------------*/

    case (_,ty,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = Types.isBoxedType(ty);
      then
        fail();

    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_) then DAE.emptyDae;
  end matchcontinue;
end daeDeclare4;

end InstDAE;
