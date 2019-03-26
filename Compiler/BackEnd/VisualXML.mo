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

encapsulated package VisualXML
" file:        VisualXML
  package:     VisualXML
  description: This package gathers alle information about visualization objects from the MultiBody lib and outputs them as an XML file.
               This can be used additionally to the result file to visualize the system.



"

protected

import Absyn;
import BackendDAE;
import BackendDAEUtil;
import BackendEquation;
import BackendVariable;
import CevalScript;
import ComponentReference;
import DAE;
import DAEUtil;
import ElementSource;
import ExpressionDump;
import ExpressionSolve;
import List;
import Util;
import Tpl;
import VisualXMLTpl;
import System;

//----------------------------
//  Visualization types
//----------------------------

public uniontype Visualization
  record SHAPE
    DAE.ComponentRef ident;
    DAE.Exp shapeType;
    array<list<DAE.Exp>> T;
    array<DAE.Exp> r;
    array<DAE.Exp> r_shape;
    array<DAE.Exp> lengthDir;
    array<DAE.Exp> widthDir;
    DAE.Exp length;
    DAE.Exp width;
    DAE.Exp height;
    DAE.Exp extra;
    array<DAE.Exp> color;
    DAE.Exp specularCoeff;
  end SHAPE;
end Visualization;

//-------------------------
// dump visualization xml
//-------------------------

public function visualizationInfoXML"dumps an xml containing information about visualization objects.
author:Waurich TUD 2015-04"
  input BackendDAE.BackendDAE daeIn;
  input String fileName;
  input Absyn.Program program;
  output BackendDAE.BackendDAE daeOut;
protected
  BackendDAE.EqSystems eqs, eqs0;
  BackendDAE.Shared shared;
  BackendDAE.Variables globalKnownVars, aliasVars;
  list<BackendDAE.Var> globalKnownVarLst, allVarLst, aliasVarLst;
  list<Visualization> visuals;
  list<DAE.ComponentRef> allVisuals;
algorithm
  BackendDAE.DAE(eqs=eqs0, shared=shared) := daeIn;
  BackendDAE.SHARED(globalKnownVars=globalKnownVars,aliasVars=aliasVars) := shared;
  //in case we have a time dependent, protected variable, set the solved equation as binding
  eqs := List.map(eqs0,BackendDAEUtil.copyEqSystem);
  eqs := List.map(eqs,setBindingForProtectedVars);

  //get all variables that contain visualization vars
  globalKnownVarLst := BackendVariable.varList(globalKnownVars);
  aliasVarLst := BackendVariable.varList(aliasVars);
  allVarLst := List.flatten(List.mapMap(eqs, BackendVariable.daeVars,BackendVariable.varList));

  //collect all visualization objects
  (globalKnownVarLst,allVisuals) := List.fold(globalKnownVarLst,isVisualizationVarFold,({},{}));
  (allVarLst,allVisuals) := List.fold(allVarLst,isVisualizationVarFold,({},allVisuals));
  (aliasVarLst,allVisuals) := List.fold(aliasVarLst,isVisualizationVarFold,({},allVisuals));
    //print("ALL VISUALS "+stringDelimitList(List.map(allVisuals,ComponentReference.printComponentRefStr)," |")+"\n");

  //fill theses visualization objects with information
  allVarLst := listAppend(globalKnownVarLst,listAppend(allVarLst,aliasVarLst));
  (visuals,_,_) := List.mapFold2(allVisuals, fillVisualizationObjects,allVarLst, program);
  //some expressions refer to other known parameters, get them
  visuals := List.map2(visuals,replaceVisualBinding,globalKnownVars,program);
    //print("\nvisuals :\n"+stringDelimitList(List.map(visuals,printVisualization),"\n")+"\n");

  //dump xml file
  dumpVis(listArray(visuals), fileName+"_visual.xml");

  //update the variabels
  (globalKnownVars,_) := BackendVariable.traverseBackendDAEVarsWithUpdate(globalKnownVars, setVisVarsPublic,"");
  (aliasVars,_) := BackendVariable.traverseBackendDAEVarsWithUpdate(aliasVars, setVisVarsPublic,"");
  daeOut := BackendDAE.DAE(eqs=eqs, shared=shared);
end visualizationInfoXML;

protected function replaceVisualBinding"Replace the cref binding for the given visualization shapeType with the constant expression of its alias.
author: vwaurich 2016-10"
  input Visualization visIn;
  input BackendDAE.Variables varArray;
  input Absyn.Program program;
  output Visualization visOut;
algorithm
  visOut := matchcontinue(visIn,varArray,program)
    local
      DAE.ComponentRef cr, ident;
      DAE.Exp exp, length, width, height, extra, specularCoeff, shapeType;
      Real rvalue;
      String s;
      array<DAE.Exp> color, r, lengthDir, widthDir, r_shape ;
      array<list<DAE.Exp>> T;
  case(SHAPE(ident=ident, shapeType=DAE.CREF(componentRef = cr), T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir,
     length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff),_,_)
     equation
       DAE.SCONST(string=s) = getConstCrefBinding(cr,varArray);
       s = getFullCADFilePath(s,program);
    then (SHAPE(ident, DAE.SCONST(s), T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));
  case(SHAPE(ident=ident, shapeType=DAE.SCONST(string=s), T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir,
     length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff),_,_)
     equation
       s = getFullCADFilePath(s,program);
    then (SHAPE(ident, DAE.SCONST(s), T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));
  else
    then visIn;
  end matchcontinue;
end replaceVisualBinding;

protected function getConstCrefBinding"Get the const binding for the cref. It has to be somewhere in the vars.
author: vwaurich 2016-10"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  output DAE.Exp eOut;
protected
  DAE.Exp e;
  BackendDAE.Var var;
algorithm
  try
    ({var},_) := BackendVariable.getVar(cr,vars);
    e := BackendVariable.varBindExp(var);
    if Expression.isConst(e) then
      eOut := e;
    elseif Expression.isCref(e) then
      eOut := getConstCrefBinding(Expression.expCref(e),vars);
    else
      Error.addInternalError("VisualXMl.getConstCrefBinding failed for "+ExpressionDump.printExpStr(e)+"\n", sourceInfo());
    end if;
  else
    Error.addInternalError("VisualXMl.getConstCrefBinding failed for "+ComponentReference.crefStr(cr)+"\n", sourceInfo());
  end try;
end getConstCrefBinding;

public function setVisVarsPublic "Sets the VariableAttributes of protected visualization vars to public.
author: waurich TUD 08-2016"
  input BackendDAE.Var inVar;
  input String dummyArgIn;
  output BackendDAE.Var outVar = inVar;
  output String dummyArgOut = dummyArgIn;
algorithm
  if isVisualizationVar(inVar) then
    outVar := makeVarPublicHideResultFalse(inVar);
  end if;
end setVisVarsPublic;

protected function makeVarPublicHideResultFalse "Sets the VariableAttributes to public and hideResult to false
author: waurich TUD 08-2016"
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
protected
    Option<DAE.VariableAttributes> vals;
algorithm
  vals := inVar.values;
  vals := DAEUtil.setProtectedAttr(vals,false);
  outVar := BackendVariable.setVarAttributes(inVar,vals);
  outVar := BackendVariable.setHideResult(outVar,DAE.BCONST(false));
end makeVarPublicHideResultFalse;

protected function setBindingForProtectedVars "searches for protected vars and sets the binding exp with their equation.
This is needed since protected, time-dependent variables are not stored in result files (in OMC and Dymola)"
  input BackendDAE.EqSystem eqSysIn;
  output BackendDAE.EqSystem eqSysOut;
protected
  array<Integer> ass1;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqs;
algorithm
  try
  BackendDAE.EQSYSTEM(orderedEqs=eqs, orderedVars=vars, matching=BackendDAE.MATCHING(ass1=ass1)) := eqSysIn;
  BackendVariable.traverseBackendDAEVarsWithUpdate(vars, setBindingForProtectedVars1, (1, ass1, eqs));
  else
  end try;
  eqSysOut := eqSysIn;
end setBindingForProtectedVars;

protected function setBindingForProtectedVars1 "checks if the var is protected and sets the binding (i.e. the solved equation)"
  input BackendDAE.Var varIn;
  input tuple<Integer,array<Integer>,BackendDAE.EquationArray> tplIn;
  output BackendDAE.Var varOut;
  output tuple<Integer,array<Integer>,BackendDAE.EquationArray> tplOut;
algorithm
  (varOut,tplOut) := matchcontinue(varIn,tplIn)
    local
      Integer idx, eqIdx;
      array<Integer> ass1;
      BackendDAE.EquationArray eqs;
      BackendDAE.Equation eq;
      BackendDAE.Var var;
      DAE.Exp exp1, exp2;
  case(BackendDAE.VAR(bindExp=NONE(), values=SOME(_)),(idx,ass1,eqs))
    equation
      true = (BackendVariable.isProtectedVar(varIn) and isVisualizationVar(varIn));
      eq = BackendEquation.get(eqs,arrayGet(ass1,idx));
      BackendDAE.EQUATION(exp=exp1, scalar=exp2) = eq;
      (exp1,_) =  ExpressionSolve.solve(exp1,exp2,BackendVariable.varExp(varIn));
      var = BackendVariable.setBindExp(varIn,SOME(exp1));
      var = makeVarPublicHideResultFalse(var);
    then (var,(idx+1,ass1,eqs));
  case(_,(idx,ass1,eqs))
    equation
      if (BackendVariable.isProtectedVar(varIn) and isVisualizationVar(varIn)) then
        var = makeVarPublicHideResultFalse(varIn);
      else
        var = varIn;
      end if;
    then (var,(idx+1,ass1,eqs));
  end matchcontinue;
end setBindingForProtectedVars1;

protected function fillVisualizationObjects"gets the identifier of a visualization object as an input and collects all information from allVars.
author:Waurich TUD 2015-04"
  input DAE.ComponentRef crefIn;
  input list<BackendDAE.Var> allVarsIn;
  input Absyn.Program programIn;
  output Visualization visOut;
  output list<BackendDAE.Var> allVarsOut;
  output Absyn.Program programOut;
algorithm
  (visOut,allVarsOut,programOut) := matchcontinue(crefIn,allVarsIn,programIn)
    local
      String name;
      list<String> nameChars,prefix;
      Visualization vis;
      list<BackendDAE.Var> allVars;
  case(_,_,_)
    algorithm
      //nameChars := stringListStringChar(nameIn);
      //(prefix,nameChars) := List.split(nameChars,6);
      //name := stringCharListString(nameChars);
      //name := Util.stringReplaceChar(name,"$",".");
      //true := stringEqual(stringCharListString(prefix),"Shape$");
      //name := ComponentReference.printComponentRefStr(crefIn);
      vis := SHAPE(crefIn,DAE.SCONST("DUMMY"),arrayCreate(3,{DAE.RCONST(-1),DAE.RCONST(-1),DAE.RCONST(-1)}),
                           arrayCreate(3,DAE.RCONST(-1)), arrayCreate(3,DAE.RCONST(-1)), arrayCreate(3,DAE.RCONST(-1)),arrayCreate(3,DAE.RCONST(-1)),
                           DAE.RCONST(-1),DAE.RCONST(-1),DAE.RCONST(-1),DAE.RCONST(-1), arrayCreate(3,DAE.RCONST(-1)), DAE.RCONST(-1));
      (_,vis) := List.fold2(allVarsIn,fillVisualizationObjects1,true,programIn,({},vis));
    then (vis,allVarsIn,programIn);
  else
    algorithm
    print("fillVisualizationObjects failed! - not yet supported type");
   then fail();
  end matchcontinue;
end fillVisualizationObjects;

protected function makeCrefQualFromString"generates a qualified cref from the '.' separated string.
author: Waurich TUD 2015-04"
  input String s;
  output DAE.ComponentRef crefOut;
protected
  list<String> sLst;
  DAE.ComponentRef cref;
  list<DAE.ComponentRef> crefs;
algorithm
  sLst := Util.stringSplitAtChar(s,".");
  crefs := List.map2(sLst,ComponentReference.makeCrefIdent,DAE.T_REAL_DEFAULT,{});
  cref::crefs := crefs;
  crefOut := List.foldr(crefs,ComponentReference.joinCrefs,cref);
end makeCrefQualFromString;

protected function splitCrefAfter"checks if crefCut exists in the crefIn and outputs the appending crefs
author:Waurich TUD 2015-04"
  input DAE.ComponentRef crefIn;
  input DAE.ComponentRef crefCut;
  output DAE.ComponentRef crefOut;
  output Boolean wasCut;
algorithm
  (crefOut,wasCut) := matchcontinue(crefIn,crefCut)
    local
      DAE.ComponentRef crefCut1, crefIn1;
  case(DAE.CREF_QUAL(componentRef=crefIn1),DAE.CREF_QUAL())
    equation
      // the crefs are not equal, check the next cref in crefIn
      true = not ComponentReference.crefFirstCrefEqual(crefIn,crefCut);
    then splitCrefAfter(crefIn1,crefCut);
  case(DAE.CREF_QUAL(componentRef=crefIn1),DAE.CREF_QUAL(componentRef=crefCut1))
    equation
      // the crefs are equal, continue checking
      true = ComponentReference.crefFirstCrefEqual(crefIn,crefCut);
    then splitCrefAfter(crefIn1,crefCut1);
  case(DAE.CREF_QUAL(componentRef=crefIn1),DAE.CREF_IDENT(_))
    equation
      // the cref has to be cut after this step
      true = ComponentReference.crefFirstCrefEqual(crefIn,crefCut);
    then (crefIn1,true);
  case(DAE.CREF_QUAL(componentRef=crefIn1),DAE.CREF_IDENT(_))
    equation
      // there is no identical cref
      true = not ComponentReference.crefFirstCrefEqual(crefIn,crefCut);
    then (crefIn1,false);
   else
     then (crefCut,false);
  end matchcontinue;
end splitCrefAfter;

protected function fillVisualizationObjects1"checks if a variable belongs to a certain visualization var. if true, add information to the visualization object
author:Waurich TUD 2015-04"
  input BackendDAE.Var varIn; //check this var
  input Boolean storeProtectedCrefs; // if you want to store the protected crefs instead of the bidning expression
  input Absyn.Program program;
  input tuple<list<BackendDAE.Var>,Visualization> tplIn; // fold <vars for other visualization objects, the current visualization >
  output tuple<list<BackendDAE.Var>,Visualization> tplOut;
algorithm
   tplOut := matchcontinue(varIn,storeProtectedCrefs,tplIn)
    local
      String compIdent;
      list<BackendDAE.Var> vars;
      DAE.ComponentRef cref,crefIdent,cref1,ident;
      Visualization vis;
  case(BackendDAE.VAR(varName=cref),_,(vars, vis as SHAPE(ident=ident)))
    algorithm
      //this var belongs to the visualization object
      //crefIdent := makeCrefQualFromString(ident); // make a qualified cref out of the shape ident
      (cref1,true) := splitCrefAfter(cref,ident); // check if this occures in the qualified var cref
      vis := fillShapeObject(cref1,varIn,storeProtectedCrefs,program,vis);
    then (vars, vis);
  else
    algorithm
      (vars,vis) := tplIn;
    then (varIn::vars, vis);
  end matchcontinue;
end fillVisualizationObjects1;

protected function getFullCADFilePath "Get the absolute path for the given modelica uri.
author: vwaurich TUD 2016-10"
  input String sIn;
  input Absyn.Program program;
  output String sOut = sIn;
protected
  String head,packName,file, path;
  list<String> hierarchy, chars;
algorithm
  chars := stringListStringChar(sIn);
  if listLength(chars) > 11 and stringEqual(stringDelimitList(List.firstN(chars,11),""),"modelica://") then
    sOut := "modelica://"+CevalScript.getFullPathFromUri(program,sIn,true);
  end if;
end getFullCADFilePath;

protected function fillShapeObject"sets the visualization info in the visualization object
author:Waurich TUD 2015-04"
  input DAE.ComponentRef cref;
  input BackendDAE.Var var;
  input Boolean storeProtectedCrefs;
  input Absyn.Program program;
  input Visualization visIn;
  output Visualization visOut;
algorithm
  visOut := matchcontinue(cref,var,storeProtectedCrefs,program,visIn)
    local
      Option<DAE.Exp> bind;
      DAE.ComponentRef ident;
      DAE.Exp exp, length, width, height, extra, specularCoeff, shapeType;
      Integer ivalue, pos, pos1;
      Real rvalue;
      array<DAE.Exp> color, r, lengthDir, widthDir, r_shape ;
      list<DAE.Exp> T0;
      array<list<DAE.Exp>> T;

  case(DAE.CREF_IDENT(ident="shapeType"),BackendDAE.VAR(bindExp=SOME(exp)),_ ,_ , SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
    then (SHAPE(ident, exp, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

  case(DAE.CREF_QUAL(ident="R",componentRef=DAE.CREF_IDENT(ident="T", subscriptLst = {DAE.INDEX(DAE.ICONST(pos)),DAE.INDEX(DAE.ICONST(pos1))})),BackendDAE.VAR(bindExp=bind),_ ,_ , SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if isSome(bind) then
        exp := if not Expression.isConstValue(Util.getOption(bind)) and storeProtectedCrefs then BackendVariable.varExp(var) else Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
      T0 := arrayGet(T,pos);
      T0 := List.replaceAt(exp,pos1,T0);
      T := arrayUpdate(T,pos,T0);
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

  case(DAE.CREF_IDENT(ident="r", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}),BackendDAE.VAR(bindExp=bind), _ ,_ , SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if isSome(bind) then
        exp := if not Expression.isConstValue(Util.getOption(bind)) and storeProtectedCrefs then BackendVariable.varExp(var) else Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
      r := arrayUpdate(r,pos,exp);
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

  case(DAE.CREF_IDENT(ident="r_shape", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}),BackendDAE.VAR(bindExp=bind), _ ,_ , SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if isSome(bind) then
        exp := if not Expression.isConstValue(Util.getOption(bind)) and storeProtectedCrefs then BackendVariable.varExp(var) else Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
      r_shape := arrayUpdate(r_shape,pos,exp);
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

  case(DAE.CREF_IDENT(ident="lengthDirection", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}),BackendDAE.VAR(bindExp=bind), _ ,_ , SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if isSome(bind) then
        exp := if not Expression.isConstValue(Util.getOption(bind)) and storeProtectedCrefs then BackendVariable.varExp(var) else Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
      lengthDir := arrayUpdate(lengthDir,pos,exp);
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

  case(DAE.CREF_IDENT(ident="widthDirection", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}),BackendDAE.VAR(bindExp=bind), _ ,_ , SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if isSome(bind) then
        exp := if not Expression.isConstValue(Util.getOption(bind)) and storeProtectedCrefs then BackendVariable.varExp(var) else Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
      widthDir := arrayUpdate(widthDir,pos,exp);
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

  case(DAE.CREF_IDENT(ident="length"),BackendDAE.VAR(bindExp=bind), _ ,_ , SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if isSome(bind) then
        exp := if not Expression.isConstValue(Util.getOption(bind)) and storeProtectedCrefs then BackendVariable.varExp(var) else Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, exp, width, height, extra, color, specularCoeff));

  case(DAE.CREF_IDENT(ident="width"),BackendDAE.VAR(bindExp=bind), _ ,_ , SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if isSome(bind) then
        exp := if not Expression.isConstValue(Util.getOption(bind)) and storeProtectedCrefs then BackendVariable.varExp(var) else Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, exp, height, extra, color, specularCoeff));

  case(DAE.CREF_IDENT(ident="height"),BackendDAE.VAR(bindExp=bind), _ ,_ , SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if isSome(bind) then
        exp := if not Expression.isConstValue(Util.getOption(bind)) and storeProtectedCrefs then BackendVariable.varExp(var) else Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, exp, extra, color, specularCoeff));

   case(DAE.CREF_IDENT(ident="extra"),BackendDAE.VAR(bindExp=bind), _ ,_ , SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if isSome(bind) then
        exp := if not Expression.isConstValue(Util.getOption(bind)) and storeProtectedCrefs then BackendVariable.varExp(var) else Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, exp, color, specularCoeff));

  case(DAE.CREF_IDENT(ident="color", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}),BackendDAE.VAR(bindExp=bind), _ ,_ , SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if isSome(bind) then
        exp := if not Expression.isConstValue(Util.getOption(bind)) and storeProtectedCrefs then BackendVariable.varExp(var) else Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
      color := arrayUpdate(color,pos,exp);
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

   case(DAE.CREF_IDENT(ident="specularCoefficient"),BackendDAE.VAR(bindExp=bind), _ ,_ , SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color))
    algorithm
      if isSome(bind) then
        exp := if not Expression.isConstValue(Util.getOption(bind)) and storeProtectedCrefs then BackendVariable.varExp(var) else Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, exp));

  else visIn;
  end matchcontinue;
end fillShapeObject;

protected function printVisualization"printing function for debugging.
author:Waurich TUD 2015-04"
  input Visualization vis;
  output String s;
algorithm
  s := match(vis)
    local
      DAE.ComponentRef ident;
      DAE.Exp length, width, height, extra, shapeType;
      array<DAE.Exp> color, r, widthDir, lengthDir;
      array<list<DAE.Exp>> T;
  case(SHAPE(ident=ident, shapeType=shapeType, color=color, r=r, lengthDir=lengthDir, widthDir=widthDir, T=T, length=length, width=width, height=height, extra=extra))
  then ("SHAPE "+ComponentReference.printComponentRefStr(ident)+" '"+ExpressionDump.printExpStr(shapeType) + "'\n r{"+stringDelimitList(List.map1(arrayList(r),ExpressionDump.dumpExpStr,0),",")+"}" +
        "\nlD{"+stringDelimitList(List.map(arrayList(lengthDir),ExpressionDump.printExpStr),",")+"}"+" wD{"+stringDelimitList(List.map(arrayList(widthDir),ExpressionDump.printExpStr),",")+"}"+
        "\ncolor("+stringDelimitList(List.map(arrayList(color),ExpressionDump.printExpStr),",")+")"+" w: "+ExpressionDump.printExpStr(width)+" h: "+ExpressionDump.printExpStr(height)+" l: "+ExpressionDump.printExpStr(length) +
        "\nT {"+ stringDelimitList(List.map(List.flatten(arrayList(T)),ExpressionDump.printExpStr),", ")+"}"+"\nextra{"+ExpressionDump.printExpStr(extra)+"}");
  else
    then "-";
  end match;
end printVisualization;

protected function isVisualizationVar"the var inherits from an visualization object. Therefore, the paths are checked.
author:Waurich TUD 2015-04"
  input BackendDAE.Var var;
  output Boolean isVisVar;
algorithm
  isVisVar := matchcontinue(var)
  local
    Boolean b;
    DAE.ElementSource source;
    String obj;
    list<Absyn.Path> paths;
    list<String> paths_lst;
    case(BackendDAE.VAR(source=source))
      algorithm
       paths := ElementSource.getElementSourceTypes(source);
       //_ := list(Absyn.pathString(p) for p in paths);
       //print("paths_lst "+stringDelimitList(paths_lst, "; ")+"\n");
       (obj,_) := hasVisPath(paths,1);
    then Util.stringNotEqual(obj,"");
    else
      then false;
  end matchcontinue;
end isVisualizationVar;


protected function isVisualizationVarFold"the var inherits from an visualization object. Therefore, the paths are checked.
author:Waurich TUD 2015-04"
  input BackendDAE.Var var;
  input tuple<list<BackendDAE.Var>,list<DAE.ComponentRef>> tplIn;//visualizationVars, visualization Identifiers
  output tuple<list<BackendDAE.Var>,list<DAE.ComponentRef>> tplOut;
algorithm
  tplOut := matchcontinue(var,tplIn)
    local
      Integer idx;
      DAE.ComponentRef varName, cref;
      list<DAE.ComponentRef> crefs;
      DAE.ElementSource source;
      list<BackendDAE.Var> varLst;
      String obj;
      list<Absyn.Path> paths;

    case (BackendDAE.VAR(varName=varName,  source=source), (varLst,crefs))
      algorithm
        paths := ElementSource.getElementSourceTypes(source);
        //print("Component " + ComponentReference.printComponentRefStr(varName) + ":\n");
        //print(List.toString(paths, Absyn.pathStringDefault, "", "  ", "\n  ", "", false) + "\n");
        (obj,idx) := hasVisPath(paths,1);
        true := Util.stringNotEqual(obj,"");
        //print("ComponentRef "+ComponentReference.printComponentRefStr(varName)+" path: "+obj+ " idx: "+intString(idx)+"\n");
        cref := ComponentReference.firstNCrefs(varName,idx-1);
        crefs := List.unique(cref::crefs);
      then
        (var::varLst, crefs);

    else tplIn;
  end matchcontinue;
end isVisualizationVarFold;

protected function hasVisPath"checks if the path is Modelica.Mechanics.MultiBody.Visualizers.Advanced.* and outputs * if true. outputs which path is the vis path
author:Waurich TUD 2015-04"
  input  list<Absyn.Path> pathsIn;
  input Integer numIn;
  output String visPath;
  output Integer numOut;
algorithm
  (visPath,numOut) := matchcontinue(pathsIn,numIn)
    local
      String name, shapeIdent;
      Integer num;
      Boolean b;
      Absyn.Path path;
      list<Absyn.Path> rest;
  case({},_)
    then ("",-1);
  case(Absyn.FULLYQUALIFIED(path=path)::rest,_)
    algorithm
    (name,num) := hasVisPath(path::rest,numIn);
    then (name,num);
  case(Absyn.QUALIFIED(name="Modelica",path=Absyn.QUALIFIED(name="Mechanics",path=Absyn.QUALIFIED(name="MultiBody",path=Absyn.QUALIFIED(name="Visualizers",path=Absyn.QUALIFIED(name="Advanced",path=Absyn.IDENT(name=name))))))::_,_)
    algorithm
      shapeIdent := substring(name, 1, 5);
      true := stringEqual(shapeIdent,"Shape");
    then (name,numIn);
  case(_::rest,_)
    algorithm
      (name,num) := hasVisPath(rest,numIn+1);
    then (name,num);
  end matchcontinue;
end hasVisPath;


public function dumpVis "author: waurich TUD
  Dumps the graph into a *.xml-file."
  input array<Visualization> visIn;
  input String iFileName;
algorithm
  print("");
  Tpl.tplNoret2(VisualXMLTpl.dumpVisXML, visIn, iFileName);
end dumpVis;

annotation(__OpenModelica_Interface="backend");
end VisualXML;
