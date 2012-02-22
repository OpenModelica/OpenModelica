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

encapsulated package SCodeFlatten
" file:        SCodeFlatten.mo
  package:     SCodeFlatten
  description: SCode flattening

  RCS: $Id$

  This module flattens the SCode representation by removing all extends, imports
  and redeclares, and fully qualifying class names.
"

public import Absyn;
public import SCode;
public import SCodeDependency;
public import SCodeFlattenImports;
public import SCodeFlattenExtends;
public import SCodeFlattenRedeclare;

protected import Debug;
protected import Flags;
protected import List;
protected import SCodeEnv;
protected import System;
protected import SCodeLookup;
protected import SCodeDump;
protected import SCodeInst;

protected type Env = SCodeEnv.Env;

public function flattenProgram
  "Flattens the last class in a program."
  input SCode.Program inProgram;
  output SCode.Program outProgram;
protected
  Absyn.Path cls_path;
algorithm
  cls_path := getLastClassNameInProgram(inProgram);
  outProgram := flattenClassInProgram(cls_path, inProgram);
end flattenProgram;

protected function getLastClassNameInProgram
  "Returns the name of the last class in the program."
  input SCode.Program inProgram;
  output Absyn.Path outClassName;
protected
  SCode.Program prog;
  String name;
algorithm
  prog := listReverse(inProgram);
  SCode.CLASS(name = name) := List.selectFirst(prog, isClass);
  outClassName := Absyn.IDENT(name);
end getLastClassNameInProgram;

protected function isClass
  "Checks if the given SCode.Class is a class, i.e. not a function."
  input SCode.Element inClass;
  output Boolean outIsClass;
algorithm
  outIsClass := match(inClass)
    case SCode.CLASS(restriction = SCode.R_FUNCTION(_)) then false;
    else then true;
  end match;
end isClass;

public function flattenClass
  "Flattens a single class."
  input SCode.Element inClass;
  output SCode.Element outClass;
algorithm
  {outClass} := flattenProgram({inClass});
end flattenClass;

public function flattenClassInProgram
  "Flattens a specific class in a program."
  input Absyn.Path inClassName;
  input SCode.Program inProgram;
  output SCode.Program outProgram;
algorithm
  outProgram := matchcontinue(inClassName, inProgram)
    local
      Env env, env2, env3;
      SCode.Program prog;
      list<Absyn.Path> consts;
      

    case (_, prog)
      equation
        //System.startTimer();

        env = SCodeEnv.buildInitialEnv();
        env = SCodeEnv.extendEnvWithClasses(prog, env);
        env = SCodeEnv.updateExtendsInEnv(env);
        
        (prog, env, consts) = SCodeDependency.analyse(inClassName, env, prog);
        checkForCardinality(env);
        //print(SCodeDump.programStr(prog) +& "\n");
        (prog, env) = SCodeFlattenImports.flattenProgram(prog, env);

        SCodeInst.instClass(inClassName, env, consts);
        prog = SCodeFlattenExtends.flattenProgram(inClassName, prog, env);
        
        //System.stopTimer();
        //Debug.traceln("SCodeFlatten.flattenClassInProgram took " +& 
        //  realString(System.getTimerIntervalTime()) +& " seconds");
        
      then
        prog;

    else
      equation
        Debug.fprintln(Flags.FAILTRACE, "SCodeFlatten.flattenClassInProgram failed on " +&
          Absyn.pathString(inClassName));
      then
        fail();

  end matchcontinue;
end flattenClassInProgram;

protected function checkForCardinality
  "Checks if the cardinality operator is used or not and sets the system flag,
  so that some work can be avoided in Inst if cardinality isn't used."
  input Env inEnv;
algorithm
  _ := matchcontinue(inEnv)
    case _
      equation
        (_, _, _, _) = SCodeLookup.lookupName(Absyn.IDENT("cardinality"), inEnv,
          Absyn.dummyInfo, NONE());
        System.setUsesCardinality(true);
      then
        ();

    else
      equation
        System.setUsesCardinality(false);
      then
        ();

  end matchcontinue;
end checkForCardinality;

public function flattenCompleteProgram
  input SCode.Program inProgram;
  output SCode.Program outProgram;
algorithm
  outProgram := matchcontinue(inProgram)
    local
      Env env;
      SCode.Program prog;

    case (prog)
      equation
        env = SCodeEnv.buildInitialEnv();
        env = SCodeEnv.extendEnvWithClasses(prog, env);
        env = SCodeEnv.updateExtendsInEnv(env);
        (prog, env) = SCodeFlattenImports.flattenProgram(prog, env);
      then
        prog;

    else
      equation
        Debug.fprintln(Flags.FAILTRACE, "SCodeFlatten.flattenCompleteProgram failed");
      then
        fail();

  end matchcontinue;
end flattenCompleteProgram;

end SCodeFlatten;
