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
  description: VisualXML


  RCS: $Id: VisualXML 2014-02-04 waurich $
"

protected import Absyn;
protected import Array;
protected import BackendDAE;
protected import BackendDAEUtil;
protected import BackendVariable;
protected import ComponentReference;
protected import DAE;
protected import DAEUtil;
protected import ExpressionDump;
protected import List;
protected import Util;
protected import Tpl;
protected import VisualXMLTpl;

//----------------------------
//  Visualization types
//----------------------------

public uniontype Visualization
  record SHAPE
    String ident;
    String shapeType;
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
protected
  BackendDAE.EqSystems eqs;
  BackendDAE.Shared shared;
  BackendDAE.Variables knownVars, aliasVars;
  list<BackendDAE.Var> knownVarLst, allVarLst, aliasVarLst;
  list<Visualization> visuals;
  list<String> allVisuals;
algorithm
  BackendDAE.DAE(eqs=eqs, shared=shared) := daeIn;
  BackendDAE.SHARED(knownVars=knownVars,aliasVars=aliasVars) := shared;
  //get all variables that contain visualization vars
  knownVarLst := BackendVariable.varList(knownVars);
  aliasVarLst := BackendVariable.varList(aliasVars);
  allVarLst := List.flatten(List.map(List.map(eqs, BackendVariable.daeVars),BackendVariable.varList));

  //collect all visualization objects
  (knownVarLst,allVisuals) := List.fold(knownVarLst,isVisualizationVar,({},{}));
    //print("ALL VISUALS "+stringDelimitList(allVisuals," |")+"\n");
  (allVarLst,_) := List.fold(allVarLst,isVisualizationVar,({},{}));
  (aliasVarLst,_) := List.fold(aliasVarLst,isVisualizationVar,({},{}));

  //fill theses visualization objects with information
  allVarLst := listAppend(listAppend(knownVarLst,allVarLst),aliasVarLst);
  (visuals,_) := List.mapFold(allVisuals, fillVisualizationObjects,allVarLst);
    //print("\nvisuals :\n"+stringDelimitList(List.map(visuals,printViusalization),"\n")+"\n");

  //dump xml file
  dumpVis(listArray(visuals), fileName+"_visual.xml");
end visualizationInfoXML;

protected function fillVisualizationObjects"gets the identifier of a visualization object as an input and collects all information from allVars.
author:Waurich TUD 2015-04"
  input String nameIn;
  input list<BackendDAE.Var> allVarsIn;
  output Visualization visOut;
  output list<BackendDAE.Var> allVarsOut;
algorithm
  (visOut,allVarsOut) := matchcontinue(nameIn,allVarsIn)
    local
      String name;
      list<String> nameChars,prefix;
      Visualization vis;
      list<BackendDAE.Var> allVars;
  case(_,_)
    algorithm
      nameChars := stringListStringChar(nameIn);
      (prefix,nameChars) := List.split(nameChars,6);
      name := stringCharListString(nameChars);
      name := Util.stringReplaceChar(name,"$",".");
      true := stringEqual(stringCharListString(prefix),"Shape$");
      vis := SHAPE(name,"",arrayCreate(3,{DAE.RCONST(-1),DAE.RCONST(-1),DAE.RCONST(-1)}),
                           arrayCreate(3,DAE.RCONST(-1)), arrayCreate(3,DAE.RCONST(-1)), arrayCreate(3,DAE.RCONST(-1)),arrayCreate(3,DAE.RCONST(-1)),
                           DAE.RCONST(-1),DAE.RCONST(-1),DAE.RCONST(-1),DAE.RCONST(-1), arrayCreate(3,DAE.RCONST(-1)), DAE.RCONST(-1));
      (allVars,vis) := List.fold(allVarsIn,fillVisualizationObjects1,({},vis));
    then (vis,allVarsIn);
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
      DAE.Ident ident1,ident2;
      DAE.ComponentRef crefCut1, crefIn1;
  case(DAE.CREF_QUAL(ident=ident1, componentRef=crefIn1),DAE.CREF_QUAL(ident=ident2, componentRef=crefCut1))
    equation
      // the crefs are not equal, check the next cref in crefIn
      true = not stringEq(ident1,ident2);
    then splitCrefAfter(crefIn1,crefCut);
  case(DAE.CREF_QUAL(ident=ident1, componentRef=crefIn1),DAE.CREF_QUAL(ident=ident2, componentRef=crefCut1))
    equation
      // the crefs are equal, continue checking
      true = stringEq(ident1,ident2);
    then splitCrefAfter(crefIn1,crefCut1);
  case(DAE.CREF_QUAL(ident=ident1, componentRef=crefIn1),DAE.CREF_IDENT(ident=ident2))
    equation
      // the cref has to be cut after this step
      true = stringEq(ident1,ident2);
    then (crefIn1,true);
  case(DAE.CREF_QUAL(ident=ident1, componentRef=crefIn1),DAE.CREF_IDENT(ident=ident2))
    equation
      // there is no identical cref
      true = not stringEq(ident1,ident2);
    then (crefIn1,false);
   else
     then (crefCut,false);
  end matchcontinue;
end splitCrefAfter;

protected function fillVisualizationObjects1"checks if a variable belongs to a certain visualization var. if true, add information to the visualization object
author:Waurich TUD 2015-04"
  input BackendDAE.Var varIn; //check this var
  input tuple<list<BackendDAE.Var>,Visualization> tplIn; // fold <vars for other visualization objects, the current visualization >
  output tuple<list<BackendDAE.Var>,Visualization> tplOut;
algorithm
   tplOut := matchcontinue(varIn,tplIn)
    local
      String ident, compIdent;
      list<BackendDAE.Var> vars;
      DAE.ComponentRef cref,crefIdent,cref0,cref1;
      Visualization vis;
  case(BackendDAE.VAR(varName=cref),(vars, vis as SHAPE(ident=ident)))
    algorithm
      //this var belongs to the visualization object
      crefIdent := makeCrefQualFromString(ident); // make a qualified cref out of the shape ident
      (cref1,true) := splitCrefAfter(cref,crefIdent); // check if this occures in the qualified var cref
      vis := fillShapeObject(cref1,varIn,vis);
    then (vars, vis);
  else
    algorithm
      (vars,vis) := tplIn;
    then (varIn::vars, vis);
  end matchcontinue;
end fillVisualizationObjects1;

protected function fillShapeObject"sets the visualization info in the visualization object
author:Waurich TUD 2015-04"
  input DAE.ComponentRef cref;
  input BackendDAE.Var var;
  input Visualization visIn;
  output Visualization visOut;
algorithm
  visOut := matchcontinue(cref,var,visIn)
    local
      Option<DAE.Exp> bind;
      DAE.Exp exp, length, width, height, extra, specularCoeff;
      String ident, shapeType, svalue;
      Integer ivalue, pos, pos1;
      Real rvalue;
      array<DAE.Exp> color, r, lengthDir, widthDir, r_shape ;
      list<DAE.Exp> T0;
      array<list<DAE.Exp>> T;
  case(DAE.CREF_IDENT(ident="shapeType"),BackendDAE.VAR(bindExp=SOME(DAE.SCONST(svalue))), SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    then (SHAPE(ident, svalue, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

  case(DAE.CREF_QUAL(ident="R",componentRef=DAE.CREF_IDENT(ident="T", subscriptLst = {DAE.INDEX(DAE.ICONST(pos)),DAE.INDEX(DAE.ICONST(pos1))})),BackendDAE.VAR(bindExp=bind), SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if Util.isSome(bind) then exp := Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
      T0 := arrayGet(T,pos);
      T0 := List.replaceAt(exp,pos1,T0);
      T := arrayUpdate(T,pos,T0);
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

  case(DAE.CREF_IDENT(ident="r", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}),BackendDAE.VAR(bindExp=bind), SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if Util.isSome(bind) then exp := Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
      r := arrayUpdate(r,pos,exp);
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

  case(DAE.CREF_IDENT(ident="r_shape", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}),BackendDAE.VAR(bindExp=bind), SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if Util.isSome(bind) then exp := Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
      r_shape := arrayUpdate(r_shape,pos,exp);
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

  case(DAE.CREF_IDENT(ident="lengthDirection", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}),BackendDAE.VAR(bindExp=bind), SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if Util.isSome(bind) then exp := Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
      lengthDir := arrayUpdate(lengthDir,pos,exp);
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

  case(DAE.CREF_IDENT(ident="widthDirection", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}),BackendDAE.VAR(bindExp=bind), SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if Util.isSome(bind) then exp := Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
      widthDir := arrayUpdate(widthDir,pos,exp);
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

  case(DAE.CREF_IDENT(ident="length"),BackendDAE.VAR(bindExp=bind), SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if Util.isSome(bind) then length := Util.getOption(bind);
      else length := BackendVariable.varExp(var);
      end if;
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

  case(DAE.CREF_IDENT(ident="width"),BackendDAE.VAR(bindExp=bind), SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if Util.isSome(bind) then width := Util.getOption(bind);
      else width := BackendVariable.varExp(var);
      end if;
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

  case(DAE.CREF_IDENT(ident="height"),BackendDAE.VAR(bindExp=bind), SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if Util.isSome(bind) then height := Util.getOption(bind);
      else height := BackendVariable.varExp(var);
      end if;
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

   case(DAE.CREF_IDENT(ident="extra"),BackendDAE.VAR(bindExp=bind), SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if Util.isSome(bind) then extra := Util.getOption(bind);
      else extra := BackendVariable.varExp(var);
      end if;
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

  case(DAE.CREF_IDENT(ident="color", subscriptLst = {DAE.INDEX(DAE.ICONST(pos))}),BackendDAE.VAR(bindExp=bind), SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if Util.isSome(bind) then exp := Util.getOption(bind);
      else exp := BackendVariable.varExp(var);
      end if;
      color := arrayUpdate(color,pos,exp);
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

   case(DAE.CREF_IDENT(ident="specularCoefficient"),BackendDAE.VAR(bindExp=bind), SHAPE(ident=ident, shapeType=shapeType, T=T, r=r, r_shape=r_shape, lengthDir=lengthDir, widthDir=widthDir, length=length, width=width, height=height, extra=extra, color=color, specularCoeff=specularCoeff))
    algorithm
      if Util.isSome(bind) then specularCoeff := Util.getOption(bind);
      else specularCoeff := BackendVariable.varExp(var);
      end if;
    then (SHAPE(ident, shapeType, T, r, r_shape, lengthDir, widthDir, length, width, height, extra, color, specularCoeff));

  else
    algorithm
      BackendDAE.VAR(bindExp=bind) := var;
      if Util.isSome(bind) then exp := Util.getOption(bind);
      else exp := DAE.SCONST("NO_BINDING");
      end if;
       //print("whats this? :"+ComponentReference.printComponentRefStr(cref)+" with binding: "+ExpressionDump.printExpStr(exp)+"\n");
    then visIn;
  end matchcontinue;
end fillShapeObject;

protected function printViusalization"printing function for debugging.
author:Waurich TUD 2015-04"
  input Visualization vis;
  output String s;
algorithm
  s := match(vis)
    local
      String ident, shapeType;
      DAE.Exp length, width, height;
      array<DAE.Exp> color, r, widthDir, lengthDir;
      array<list<DAE.Exp>> T;
  case(SHAPE(ident=ident, shapeType=shapeType, color=color, r=r, lengthDir=lengthDir, widthDir=widthDir, T=T, length=length, width=width, height=height))
  then ("SHAPE "+ident+" '"+shapeType + "' r{"+stringDelimitList(List.map(arrayList(r),ExpressionDump.printExpStr),",")+"}" +
        " lD{"+stringDelimitList(List.map(arrayList(lengthDir),ExpressionDump.printExpStr),",")+"}"+" wD{"+stringDelimitList(List.map(arrayList(widthDir),ExpressionDump.printExpStr),",")+"}"+
        " color("+stringDelimitList(List.map(arrayList(color),ExpressionDump.printExpStr),",")+")"+" w: "+ExpressionDump.printExpStr(width)+" h: "+ExpressionDump.printExpStr(height)+" l: "+ExpressionDump.printExpStr(length) +
        " T {"+ stringDelimitList(List.map(List.flatten(arrayList(T)),ExpressionDump.printExpStr),", ")+"}");
  else
    then "-";
  end match;
end printViusalization;

protected function isVisualizationVar"the var inherits from an visualization object. Therefore, the paths are checked.
author:Waurich TUD 2015-04"
  input BackendDAE.Var var;
  input tuple<list<BackendDAE.Var>,list<String>> tplIn;//visualizationVars, types
  output tuple<list<BackendDAE.Var>,list<String>> tplOut;
algorithm
  tplOut := matchcontinue(var,tplIn)
  local
    Boolean b;
    BackendDAE.Type varType;
    DAE.ComponentRef varName;
    DAE.ElementSource source;
    list<BackendDAE.Var> varLst;
    String obj;
    list<Absyn.Path> paths;
    list<String> paths_lst, typeLst;
    case(BackendDAE.VAR(varName=varName, varType = varType, source=source), (varLst,typeLst))
      algorithm
       paths := DAEUtil.getElementSourceTypes(source);
       paths_lst := List.map(paths, Absyn.pathString);
       obj := hasVisPath(paths);
       true := Util.stringNotEqual(obj,"");
       typeLst := List.unique(obj::typeLst);
    then (var::varLst,typeLst);
    else
      then tplIn;
  end matchcontinue;
end isVisualizationVar;

protected function hasVisPath"checks if the path is Modelica.Mechanics.MultiBody.Visualizers.Advanced.* and outputs * if true.
author:Waurich TUD 2015-04"
  input  list<Absyn.Path> pathsIn;
  output String visPath;
algorithm
  visPath := matchcontinue(pathsIn)
    local
      String name;
      Boolean b;
      Absyn.Path path;
      list<Absyn.Path> rest;
  case({})
    then "";
  case(Absyn.FULLYQUALIFIED(path=path)::rest)
    algorithm
    (name) := hasVisPath(path::rest);
    then name;
  case(Absyn.QUALIFIED(name="Modelica",path=Absyn.QUALIFIED(name="Mechanics",path=Absyn.QUALIFIED(name="MultiBody",path=Absyn.QUALIFIED(name="Visualizers",path=Absyn.QUALIFIED(name="Advanced",path=Absyn.IDENT(name=name))))))::_)
    algorithm
    then name;
  case(_::rest)
    algorithm
      (name) := hasVisPath(rest);
    then name;
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
