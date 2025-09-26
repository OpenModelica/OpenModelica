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
  description: This package gathers all information about visualization objects from the MultiBody lib and outputs them as an XML file.
               This can be used together with the result file to visualize the system.



"

protected

import Absyn;
import AbsynUtil;
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

public
uniontype Visualization
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

  record VECTOR
    DAE.ComponentRef ident;
    array<list<DAE.Exp>> T;
    array<DAE.Exp> r;
    array<DAE.Exp> coordinates;
    array<DAE.Exp> color;
    DAE.Exp specularCoeff;
    DAE.Exp quantity;
    DAE.Exp headAtOrigin;
    DAE.Exp twoHeadedArrow;
  end VECTOR;

  record SURFACE
    DAE.ComponentRef ident;
    array<list<DAE.Exp>> T;
    array<DAE.Exp> r_0;
    DAE.Exp nu;
    DAE.Exp nv;
    // surfaceCharacteristic
    DAE.Exp wireframe;
    DAE.Exp multiColored;
    array<DAE.Exp> color;
    DAE.Exp specularCoeff;
    DAE.Exp transparency;
  end SURFACE;
end Visualization;

//-------------------------
// dump visualization xml
//-------------------------

public
function visualizationInfoXML"dumps an xml containing information about visualization objects.
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
  list<tuple<DAE.ComponentRef, String>> allVisuals;
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
  visuals := List.mapFold2(allVisuals, fillVisualizationObjects,allVarLst, program);
  //some expressions refer to other known parameters, get them
  visuals := List.map2(visuals,replaceVisualBinding,globalKnownVars,program);
    //print("\nvisuals :\n"+stringDelimitList(List.map(visuals,printVisualization),"\n")+"\n");

  //dump xml file
  dumpVis(listArray(visuals), fileName+"_visual.xml");

  //update the variabels
  globalKnownVars := BackendVariable.traverseBackendDAEVarsWithUpdate(globalKnownVars, setVisVarsPublic,"");
  aliasVars := BackendVariable.traverseBackendDAEVarsWithUpdate(aliasVars, setVisVarsPublic,"");
  daeOut := BackendDAE.DAE(eqs=eqs, shared=shared);
end visualizationInfoXML;

protected
function replaceVisualBinding
  "Replace the cref binding for the given visualization shapeType with the constant expression of its alias.
   author: vwaurich 2016-10"
  input output Visualization vis;
  input BackendDAE.Variables varArray;
  input Absyn.Program program;
algorithm
  () := matchcontinue vis
    local
      DAE.ComponentRef cr;
      String s;

    case SHAPE(shapeType = DAE.CREF(componentRef = cr))
      algorithm
        vis.shapeType := getConstCrefBinding(cr, varArray);
      then
        ();

    case SHAPE(shapeType = DAE.SCONST(string=s))
      algorithm
        vis.shapeType := DAE.SCONST(getFullCADFilePath(s, program));
      then
        ();

    else ();
  end matchcontinue;
end replaceVisualBinding;

function getConstCrefBinding
  "Get the const binding for the cref. It has to be somewhere in the vars.
   author: vwaurich 2016-10"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  output DAE.Exp eOut;
protected
  String s;
  DAE.Exp e;
  BackendDAE.Var var;
algorithm
  try
    ({var},_) := BackendVariable.getVar(cr,vars);
    e := BackendVariable.varBindExp(var);
    eOut := matchcontinue e
      case _  guard Expression.isConst(e) then e;
      case DAE.CREF(_) then getConstCrefBinding(Expression.expCref(e),vars);
          /*
      case(DAE.CALL(Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("Modelica",Absyn.QUALIFIED("Utilities",Absyn.QUALIFIED("Files",Absyn.IDENT("fullPathName"))))),{DAE.SCONST(s)},_))
        equation
        then System.realpath(s);
        */
      else
        equation
          Error.addCompilerWarning("The binding expression "+ExpressionDump.printExpStr(e)+" of the visualization type component " +ComponentReference.crefStr(cr)+ "  cannot be evaluated. Please specify a visualization type (CAD files are specified as modelica://packagename/filename.stl)");
        then e;
    end matchcontinue;
  else
    Error.addInternalError("VisualXMl.getConstCrefBinding failed for "+ComponentReference.crefStr(cr)+"\n", sourceInfo());
  end try;
end getConstCrefBinding;

function setVisVarsPublic
  "Sets the VariableAttributes of protected visualization vars to public.
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

function makeVarPublicHideResultFalse
  "Sets the VariableAttributes to public and hideResult to false
   author: waurich TUD 08-2016"
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
protected
  Option<DAE.VariableAttributes> vals;
algorithm
  vals := inVar.values;
  vals := DAEUtil.setProtectedAttr(vals,false);
  outVar := BackendVariable.setVarAttributes(inVar,vals);
  outVar := BackendVariable.setHideResult(outVar,SOME(DAE.BCONST(false)));
end makeVarPublicHideResultFalse;

function setBindingForProtectedVars
  "searches for protected vars and sets the binding exp with their equation.
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

function setBindingForProtectedVars1
  "checks if the var is protected and sets the binding (i.e. the solved equation)"
  input BackendDAE.Var varIn;
  input tuple<Integer,array<Integer>,BackendDAE.EquationArray> tplIn;
  output BackendDAE.Var varOut;
  output tuple<Integer,array<Integer>,BackendDAE.EquationArray> tplOut;
algorithm
  (varOut, tplOut) := matchcontinue (varIn, tplIn)
    local
      Integer idx, eqIdx;
      array<Integer> ass1;
      BackendDAE.EquationArray eqs;
      BackendDAE.Equation eq;
      BackendDAE.Var var;
      DAE.Exp exp1, exp2;

  case (BackendDAE.VAR(bindExp=NONE(), values=SOME(_)) , (idx, ass1, eqs))
      guard BackendVariable.isProtectedVar(varIn) and isVisualizationVar(varIn)
    algorithm
      eq := BackendEquation.get(eqs, arrayGet(ass1, idx));
      BackendDAE.EQUATION(exp=exp1, scalar=exp2) := eq;
      (exp1,_) := ExpressionSolve.solve(exp1, exp2, BackendVariable.varExp(varIn));
      var := BackendVariable.setBindExp(varIn, SOME(exp1));
      var := makeVarPublicHideResultFalse(var);
    then
      (var, (idx+1, ass1, eqs));

  case (_, (idx, ass1, eqs))
    equation
      if (BackendVariable.isProtectedVar(varIn) and isVisualizationVar(varIn)) then
        var = makeVarPublicHideResultFalse(varIn);
      else
        var = varIn;
      end if;
    then (var, (idx+1, ass1, eqs));
  end matchcontinue;
end setBindingForProtectedVars1;

function fillVisualizationObjects
  "gets the identifier of a visualization object as an input and collects all information from allVars.
   author:Waurich TUD 2015-04"
  input tuple<DAE.ComponentRef, String> visVar;
  input list<BackendDAE.Var> allVarsIn;
  input Absyn.Program programIn;
  output Visualization visOut;
  output list<BackendDAE.Var> allVarsOut = allVarsIn;
  output Absyn.Program programOut = programIn;
protected
  DAE.ComponentRef cref;
  String name, vis_name;
  list<String> nameChars,prefix;
  Visualization vis;
  list<BackendDAE.Var> allVars;
algorithm
  try
    //nameChars := stringListStringChar(nameIn);
    //(prefix,nameChars) := List.split(nameChars,6);
    //name := stringCharListString(nameChars);
    //name := Util.stringReplaceChar(name,"$",".");
    //true := stringEqual(stringCharListString(prefix),"Shape$");
    //name := ComponentReference.printComponentRefStr(crefIn);
    (cref, vis_name) := visVar;
    vis := newVisualizer(cref, vis_name);
    (_, visOut) := List.fold2(allVarsIn,fillVisualizationObjects1,true,programIn,({},vis));
  else
    print("fillVisualizationObjects failed! - not yet supported type");
    fail();
  end try;
end fillVisualizationObjects;

function newVisualizer
  input DAE.ComponentRef cref;
  input String visualizerName;
  output Visualization vis;
algorithm
  vis := match visualizerName
    case "Shape"
      then SHAPE(cref,
             DAE.SCONST("DUMMY"),
             arrayCreate(3, {DAE.RCONST(-1),DAE.RCONST(-1),DAE.RCONST(-1)}),
             arrayCreate(3, DAE.RCONST(-1)),
             arrayCreate(3, DAE.RCONST(-1)),
             arrayCreate(3, DAE.RCONST(-1)),
             arrayCreate(3, DAE.RCONST(-1)),
             DAE.RCONST(-1),
             DAE.RCONST(-1),
             DAE.RCONST(-1),
             DAE.RCONST(-1),
             arrayCreate(3, DAE.RCONST(-1)),
             DAE.RCONST(-1));

    case "Vector"
      then VECTOR(cref,
             arrayCreate(3, {DAE.RCONST(-1), DAE.RCONST(-1), DAE.RCONST(-1)}),
             arrayCreate(3, DAE.RCONST(-1)),
             arrayCreate(3, DAE.RCONST(-1)),
             arrayCreate(3, DAE.RCONST(-1)),
             DAE.RCONST(-1),
             DAE.RCONST(-1),
             DAE.BCONST(false),
             DAE.BCONST(false));

    case "Surface"
      then SURFACE(cref,
             arrayCreate(3, {DAE.RCONST(-1), DAE.RCONST(-1), DAE.RCONST(-1)}),
             arrayCreate(3, DAE.RCONST(-1)),
             DAE.ICONST(-1),
             DAE.ICONST(-1),
             // surfaceCharacteristic
             DAE.BCONST(false),
             DAE.BCONST(false),
             arrayCreate(3, DAE.RCONST(-1)),
             DAE.RCONST(-1),
             DAE.RCONST(-1));

    else
      algorithm
        Error.addInternalError(getInstanceName() + " failed on " +
          visualizerName + "\n", sourceInfo());
      then
        fail();
  end match;
end newVisualizer;

function makeCrefQualFromString
  "generates a qualified cref from the '.' separated string.
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

function splitCrefAfter
  "checks if crefCut exists in the crefIn and outputs the appending crefs
   author:Waurich TUD 2015-04"
  input DAE.ComponentRef crefIn;
  input DAE.ComponentRef crefCut;
  output DAE.ComponentRef crefOut;
  output Boolean wasCut;
algorithm
  (crefOut, wasCut) := matchcontinue(crefIn, crefCut)
    local
      DAE.ComponentRef crefCut1, crefIn1;
/* Issue #5953
    case(DAE.CREF_QUAL(componentRef=crefIn1),DAE.CREF_QUAL())
      algorithm
        // the crefs are not equal, check the next cref in crefIn
        true := not ComponentReference.crefFirstCrefEqual(crefIn,crefCut);
      then
        splitCrefAfter(crefIn1,crefCut);
*/
    case(DAE.CREF_QUAL(componentRef=crefIn1),DAE.CREF_QUAL(componentRef=crefCut1))
      algorithm
        // the crefs are equal, continue checking
        true := ComponentReference.crefFirstCrefEqual(crefIn,crefCut);
      then
        splitCrefAfter(crefIn1,crefCut1);

    case(DAE.CREF_QUAL(componentRef=crefIn1),DAE.CREF_IDENT(_))
      algorithm
        // the cref has to be cut after this step
        true := ComponentReference.crefFirstCrefEqual(crefIn,crefCut);
      then
        (crefIn1, true);

    case(DAE.CREF_QUAL(componentRef=crefIn1),DAE.CREF_IDENT(_))
      algorithm
        // there is no identical cref
        true := not ComponentReference.crefFirstCrefEqual(crefIn,crefCut);
      then
        (crefIn1, false);

    else (crefCut, false);
  end matchcontinue;
end splitCrefAfter;

function fillVisualizationObjects1
  "checks if a variable belongs to a certain visualization var. if true, add information to the visualization object
   author:Waurich TUD 2015-04"
  input BackendDAE.Var varIn; //check this var
  input Boolean storeProtectedCrefs; // if you want to store the protected crefs instead of the bidning expression
  input Absyn.Program program;
  input tuple<list<BackendDAE.Var>,Visualization> tplIn; // fold <vars for other visualization objects, the current visualization >
  output tuple<list<BackendDAE.Var>,Visualization> tplOut;
algorithm
   tplOut := matchcontinue(varIn, tplIn)
    local
      String compIdent;
      list<BackendDAE.Var> vars;
      DAE.ComponentRef cref,crefIdent,cref1,ident;
      Visualization vis, filled_vis;

    case (BackendDAE.VAR(varName=cref), (vars, vis as SHAPE(ident=ident)))
      algorithm
        //this var belongs to the visualization object
        //crefIdent := makeCrefQualFromString(ident); // make a qualified cref out of the visualizer ident
        (cref1,true) := splitCrefAfter(cref,ident); // check if this occurs in the qualified var cref
        filled_vis := fillShapeObject(cref1,varIn,storeProtectedCrefs,program,vis);
      then
        (vars, filled_vis);

    case (BackendDAE.VAR(varName=cref), (vars, vis as VECTOR(ident=ident)))
      algorithm
        //this var belongs to the visualization object
        //crefIdent := makeCrefQualFromString(ident); // make a qualified cref out of the visualizer ident
        (cref1,true) := splitCrefAfter(cref,ident); // check if this occurs in the qualified var cref
        filled_vis := fillVectorObject(cref1,varIn,storeProtectedCrefs,program,vis);
      then
        (vars, filled_vis);

    case (BackendDAE.VAR(varName=cref), (vars, vis as SURFACE(ident=ident)))
      algorithm
        //this var belongs to the visualization object
        //crefIdent := makeCrefQualFromString(ident); // make a qualified cref out of the visualizer ident
        (cref1,true) := splitCrefAfter(cref,ident); // check if this occurs in the qualified var cref
        filled_vis := fillSurfaceObject(cref1,varIn,storeProtectedCrefs,program,vis);
      then
        (vars, filled_vis);

    else
      algorithm
        (vars, vis) := tplIn;
      then
        (varIn::vars, vis);

  end matchcontinue;
end fillVisualizationObjects1;

function getFullCADFilePath
  "Get the absolute path for the given modelica uri.
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
    sOut := "file://"+CevalScript.getFullPathFromUri(program,sIn,true);
  end if;
end getFullCADFilePath;

function fillShapeObject
  "sets the visualization info in the visualization object
   author:Waurich TUD 2015-04"
  input DAE.ComponentRef cref;
  input BackendDAE.Var var;
  input Boolean storeProtectedCrefs;
  input Absyn.Program program;
  input output Visualization vis;
algorithm
  () := matchcontinue (cref, vis)
    local
      Option<DAE.Exp> bind;
      DAE.Exp exp;
      Integer pos, pos1;
      list<DAE.Exp> T0;

    case (DAE.CREF_IDENT(ident="shapeType"), SHAPE())
      algorithm
        BackendDAE.VAR(bindExp = bind) := var;

        if isSome(bind) then
          vis.shapeType := Util.getOption(bind);
        end if;
      then
        ();

    case (DAE.CREF_QUAL(ident="R", componentRef=DAE.CREF_IDENT(ident="T",
            subscriptLst = {DAE.INDEX(DAE.ICONST(pos)), DAE.INDEX(DAE.ICONST(pos1))})), SHAPE())
      algorithm
        exp := getVariableBinding(var, storeProtectedCrefs);
        T0 := arrayGet(vis.T, pos);
        T0 := List.replaceAt(exp, pos1, T0);
        arrayUpdate(vis.T, pos, T0);
      then
        ();

    case (DAE.CREF_IDENT(ident="r", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}), SHAPE())
      algorithm
        exp := getVariableBinding(var, storeProtectedCrefs);
        arrayUpdate(vis.r, pos, exp);
      then
        ();

    case (DAE.CREF_IDENT(ident="r_shape", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}), SHAPE())
      algorithm
        exp := getVariableBinding(var, storeProtectedCrefs);
        arrayUpdate(vis.r_shape, pos, exp);
      then
        ();

    case (DAE.CREF_IDENT(ident="lengthDirection", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}), SHAPE())
      algorithm
        exp := getVariableBinding(var, storeProtectedCrefs);
        arrayUpdate(vis.lengthDir, pos, exp);
      then
        ();

    case (DAE.CREF_IDENT(ident="widthDirection", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}), SHAPE())
      algorithm
        exp := getVariableBinding(var, storeProtectedCrefs);
        arrayUpdate(vis.widthDir, pos, exp);
      then
        ();

    case (DAE.CREF_IDENT(ident="length"), SHAPE())
      algorithm
        vis.length := getVariableBinding(var, storeProtectedCrefs);
      then
        ();

    case (DAE.CREF_IDENT(ident="width"), SHAPE())
      algorithm
        vis.width := getVariableBinding(var, storeProtectedCrefs);
      then
        ();

    case (DAE.CREF_IDENT(ident="height"), SHAPE())
      algorithm
        vis.height := getVariableBinding(var, storeProtectedCrefs);
      then
        ();

     case (DAE.CREF_IDENT(ident="extra"), SHAPE())
      algorithm
        vis.extra := getVariableBinding(var, storeProtectedCrefs);
      then
        ();

    case (DAE.CREF_IDENT(ident="color", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}), SHAPE())
      algorithm
        exp := getVariableBinding(var, storeProtectedCrefs);
        arrayUpdate(vis.color, pos, exp);
      then
        ();

    case (DAE.CREF_IDENT(ident="specularCoefficient"), SHAPE())
      algorithm
        vis.specularCoeff := getVariableBinding(var, storeProtectedCrefs);
      then
        ();

    else ();
  end matchcontinue;
end fillShapeObject;

function fillVectorObject
  "sets the visualization info in the visualization object"
  input DAE.ComponentRef cref;
  input BackendDAE.Var var;
  input Boolean storeProtectedCrefs;
  input Absyn.Program program;
  input output Visualization vis;
algorithm
  () := matchcontinue (cref, vis)
    local
      Option<DAE.Exp> bind;
      DAE.Exp exp;
      Integer pos, pos1;
      list<DAE.Exp> T0;

    case (DAE.CREF_QUAL(ident="R", componentRef=DAE.CREF_IDENT(ident="T",
            subscriptLst = {DAE.INDEX(DAE.ICONST(pos)), DAE.INDEX(DAE.ICONST(pos1))})), VECTOR())
      algorithm
        exp := getVariableBinding(var, storeProtectedCrefs);
        T0 := arrayGet(vis.T, pos);
        T0 := List.replaceAt(exp, pos1, T0);
        arrayUpdate(vis.T, pos, T0);
      then
        ();

    case (DAE.CREF_IDENT(ident="r", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}), VECTOR())
      algorithm
        exp := getVariableBinding(var, storeProtectedCrefs);
        arrayUpdate(vis.r, pos, exp);
      then
        ();

    case (DAE.CREF_IDENT(ident="coordinates", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}), VECTOR())
      algorithm
        exp := getVariableBinding(var, storeProtectedCrefs);
        arrayUpdate(vis.coordinates, pos, exp);
      then
        ();

    case (DAE.CREF_IDENT(ident="color", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}), VECTOR())
      algorithm
        exp := getVariableBinding(var, storeProtectedCrefs);
        arrayUpdate(vis.color, pos, exp);
      then
        ();

    case (DAE.CREF_IDENT(ident="specularCoefficient"), VECTOR())
      algorithm
        vis.specularCoeff := getVariableBinding(var, storeProtectedCrefs);
      then
        ();

    case (DAE.CREF_IDENT(ident="quantity"), VECTOR())
      algorithm
        vis.quantity := getVariableBinding(var, storeProtectedCrefs);
      then
        ();

    case (DAE.CREF_IDENT(ident="headAtOrigin"), VECTOR())
      algorithm
        vis.headAtOrigin := getVariableBinding(var, storeProtectedCrefs);
      then
        ();

    case (DAE.CREF_IDENT(ident="twoHeadedArrow"), VECTOR())
      algorithm
        vis.twoHeadedArrow := getVariableBinding(var, storeProtectedCrefs);
      then
        ();

    else ();
  end matchcontinue;
end fillVectorObject;

function fillSurfaceObject
  "sets the visualization info in the visualization object"
  input DAE.ComponentRef cref;
  input BackendDAE.Var var;
  input Boolean storeProtectedCrefs;
  input Absyn.Program program;
  input output Visualization vis;
algorithm
  () := matchcontinue (cref, vis)
    local
      Option<DAE.Exp> bind;
      DAE.Exp exp;
      Integer pos, pos1;
      list<DAE.Exp> T0;

    case (DAE.CREF_QUAL(ident="R", componentRef=DAE.CREF_IDENT(ident="T",
            subscriptLst = {DAE.INDEX(DAE.ICONST(pos)), DAE.INDEX(DAE.ICONST(pos1))})), SURFACE())
      algorithm
        exp := getVariableBinding(var, storeProtectedCrefs);
        T0 := arrayGet(vis.T, pos);
        T0 := List.replaceAt(exp, pos1, T0);
        arrayUpdate(vis.T, pos, T0);
      then
        ();

    case (DAE.CREF_IDENT(ident="r_0", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}), SURFACE())
      algorithm
        exp := getVariableBinding(var, storeProtectedCrefs);
        arrayUpdate(vis.r_0, pos, exp);
      then
        ();

    case (DAE.CREF_IDENT(ident="nu"), SURFACE())
      algorithm
        vis.nu := getVariableBinding(var, storeProtectedCrefs);
      then
        ();

    case (DAE.CREF_IDENT(ident="nv"), SURFACE())
      algorithm
        vis.nv := getVariableBinding(var, storeProtectedCrefs);
      then
        ();

    //case (DAE.CREF_IDENT(ident="surfaceCharacteristic"), SURFACE())
    //  algorithm
    //  then
    //    ();

    case (DAE.CREF_IDENT(ident="wireframe"), SURFACE())
      algorithm
        vis.wireframe := getVariableBinding(var, storeProtectedCrefs);
      then
        ();

    case (DAE.CREF_IDENT(ident="multiColored"), SURFACE())
      algorithm
        vis.multiColored := getVariableBinding(var, storeProtectedCrefs);
      then
        ();

    case (DAE.CREF_IDENT(ident="color", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}), SURFACE())
      algorithm
        exp := getVariableBinding(var, storeProtectedCrefs);
        arrayUpdate(vis.color, pos, exp);
      then
        ();

    case (DAE.CREF_IDENT(ident="specularCoefficient"), SURFACE())
      algorithm
        vis.specularCoeff := getVariableBinding(var, storeProtectedCrefs);
      then
        ();

    case (DAE.CREF_IDENT(ident="transparency"), SURFACE())
      algorithm
        vis.transparency := getVariableBinding(var, storeProtectedCrefs);
      then
        ();

    else ();
  end matchcontinue;
end fillSurfaceObject;

function getVariableBinding
  input BackendDAE.Var var;
  input Boolean storeProtectedCrefs;
  output DAE.Exp exp;
protected
  Option<DAE.Exp> binding;
algorithm
  BackendDAE.VAR(bindExp = binding) := var;

  if isSome(binding) then
    SOME(exp) := binding;

    if not Expression.isConstValue(exp) and storeProtectedCrefs then
      exp := BackendVariable.varExp(var);
    end if;
  else
    exp := BackendVariable.varExp(var);
  end if;
end getVariableBinding;

function printVisualization
  "printing function for debugging.
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
  then ("SHAPE "+ComponentReference.printComponentRefStr(ident)+" '"+ExpressionDump.printExpStr(shapeType) + "'\n r{"+stringDelimitList(list(ExpressionDump.dumpExpStr(e, 0) for e in r),",")+"}" +
        "\nlD{"+stringDelimitList(List.mapArray(lengthDir, ExpressionDump.printExpStr),",")+"}"+" wD{"+stringDelimitList(List.mapArray(widthDir, ExpressionDump.printExpStr),",")+"}"+
        "\ncolor("+stringDelimitList(List.mapArray(color, ExpressionDump.printExpStr),",")+")"+" w: "+ExpressionDump.printExpStr(width)+" h: "+ExpressionDump.printExpStr(height)+" l: "+ExpressionDump.printExpStr(length) +
        "\nT {"+ stringDelimitList(List.map(List.flatten(arrayList(T)),ExpressionDump.printExpStr),", ")+"}"+"\nextra{"+ExpressionDump.printExpStr(extra)+"}");
  else
    then "-";
  end match;
end printVisualization;

function isVisualizationVar
  "the var inherits from an visualization object. Therefore, the paths are checked.
   author:Waurich TUD 2015-04"
  input BackendDAE.Var var;
  output Boolean isVisVar;
algorithm
  isVisVar := matchcontinue var
    local
      Boolean b;
      DAE.ElementSource source;
      String obj;
      list<Absyn.Path> paths;
      list<String> paths_lst;

    case BackendDAE.VAR(source=source)
      algorithm
        paths := ElementSource.getElementSourceTypes(source);
        //_ := list(AbsynUtil.pathString(p) for p in paths);
        //print("paths_lst "+stringDelimitList(paths_lst, "; ")+"\n");
        obj := hasVisPath(paths, 1);
      then
        Util.stringNotEqual(obj, "");

    else false;
  end matchcontinue;
end isVisualizationVar;

function isVisualizationVarFold
  "the var inherits from an visualization object. Therefore, the paths are checked.
   author:Waurich TUD 2015-04"
  input BackendDAE.Var var;
  input tuple<list<BackendDAE.Var>,list<tuple<DAE.ComponentRef, String>>> tplIn;//visualizationVars, visualization Identifiers
  output tuple<list<BackendDAE.Var>,list<tuple<DAE.ComponentRef, String>>> tplOut;
algorithm
  tplOut := matchcontinue(var,tplIn)
    local
      Integer idx;
      DAE.ComponentRef varName, cref;
      list<tuple<DAE.ComponentRef, String>> crefs;
      DAE.ElementSource source;
      list<BackendDAE.Var> varLst;
      String obj;
      list<Absyn.Path> paths;

    case (BackendDAE.VAR(varName=varName, source=source), (varLst,crefs))
      algorithm
        paths := ElementSource.getElementSourceTypes(source);
        //print("Component " + ComponentReference.printComponentRefStr(varName) + ":\n");
        //print(List.toString(paths, AbsynUtil.pathStringDefault, "", "  ", "\n  ", "", false) + "\n");
        (obj, idx) := hasVisPath(paths, 1);
        true := Util.stringNotEqual(obj, "");
        //print("ComponentRef "+ComponentReference.printComponentRefStr(varName)+" path: "+obj+ " idx: "+intString(idx)+"\n");
        cref := ComponentReference.firstNCrefs(varName, idx-1);
        crefs := List.unique((cref, obj)::crefs);
      then
        (var::varLst, crefs);

    else tplIn;
  end matchcontinue;
end isVisualizationVarFold;

function hasVisPath
  "checks if the path is Modelica.Mechanics.MultiBody.Visualizers.Advanced.* and
   outputs * if true. outputs which path is the vis path
   author:Waurich TUD 2015-04"
  input  list<Absyn.Path> pathsIn;
  input Integer numIn;
  output String visPath;
  output Integer numOut;
algorithm
  (visPath, numOut) := matchcontinue pathsIn
    local
      String name, shapeIdent;
      Integer num;
      Boolean b;
      Absyn.Path path;
      list<Absyn.Path> rest;

    case {} then ("", -1);
    case Absyn.FULLYQUALIFIED(path=path)::rest then hasVisPath(path::rest, numIn);

    case Absyn.QUALIFIED(name="Modelica",
        path=Absyn.QUALIFIED(name="Mechanics",
          path=Absyn.QUALIFIED(name="MultiBody",
            path=Absyn.QUALIFIED(name="Visualizers",
              path=Absyn.QUALIFIED(name="Advanced",
                path=Absyn.IDENT(name=name))))))::_
        guard match name
          case "Shape" then true;
          case "Vector" then true;
          case "Surface" then true;
          else false;
        end match
      then
        (name, numIn);

    case _::rest then hasVisPath(rest,numIn+1);
  end matchcontinue;
end hasVisPath;

function dumpVis
  "author: waurich TUD
   Dumps the graph into a *.xml-file."
  input array<Visualization> visIn;
  input String iFileName;
algorithm
  print("");
  Tpl.tplNoret2(VisualXMLTpl.dumpVisXML, visIn, iFileName);
end dumpVis;

annotation(__OpenModelica_Interface="backend");
end VisualXML;
