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

encapsulated package NFSCodeFlatten
" file:        NFSCodeFlatten.mo
  package:     NFSCodeFlatten
  description: SCode flattening


  This module flattens the SCode representation by removing all extends, imports
  and redeclares, and fully qualifying class names.
"

public import Absyn;
public import SCode;
public import NFSCodeDependency;
public import NFSCodeEnv;
public import NFSCodeFlattenImports;

protected import Debug;
protected import NFEnvExtends;
protected import Flags;
protected import List;
protected import System;
protected import NFSCodeLookup;

public type Env = NFSCodeEnv.Env;

public function flattenProgram
  "Flattens the last class in a program."
  input SCode.Program inProgram;
  output SCode.Program outProgram;
protected
  Absyn.Path cls_path;
algorithm
  cls_path := getLastClassNameInProgram(inProgram);
  (outProgram, _) := flattenClassInProgram(cls_path, inProgram);
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
  SCode.CLASS(name = name) := List.find(prog, isClass);
  outClassName := Absyn.IDENT(name);
end getLastClassNameInProgram;

protected function isClass
  "Checks if the given SCode.Class is a class, i.e. not a function."
  input SCode.Element inClass;
  output Boolean outIsClass;
algorithm
  outIsClass := match(inClass)
    case SCode.CLASS(restriction = SCode.R_FUNCTION(_)) then false;
    else true;
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
  output Env outEnv;
algorithm
  (outProgram, outEnv) := matchcontinue(inClassName, inProgram)
    local
      Env env;
      SCode.Program prog;

    case (_, prog)
      equation
        //System.startTimer();
        System.tmpTickResetIndex(0, NFSCodeEnv.tmpTickIndex);
        System.tmpTickResetIndex(1, NFSCodeEnv.extendsTickIndex);
        // TODO: Enable this when NFSCodeEnv.tmpTickIndex is removed.
        //System.tmpTickResetIndex(0, NFSCodeEnv.tmpTickIndex);

        env = NFSCodeEnv.buildInitialEnv();
        env = NFSCodeEnv.extendEnvWithClasses(prog, env);
        env = NFEnvExtends.update(env);

        (prog, env) = NFSCodeDependency.analyse(inClassName, env, prog);
        checkForCardinality(env);
        (prog, env) = NFSCodeFlattenImports.flattenProgram(prog, env);

        //System.stopTimer();
        //Debug.traceln("NFSCodeFlatten.flattenClassInProgram took " +
        //  realString(System.getTimerIntervalTime()) + " seconds");

      then
        (prog, env);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("NFSCodeFlatten.flattenClassInProgram failed on " +
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
        (_, _, _) = NFSCodeLookup.lookupNameSilent(Absyn.IDENT("cardinality"),
          inEnv, Absyn.dummyInfo);
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
        env = NFSCodeEnv.buildInitialEnv();
        env = NFSCodeEnv.extendEnvWithClasses(prog, env);
        env = NFEnvExtends.update(env);
        (prog, env) = NFSCodeFlattenImports.flattenProgram(prog, env);
      then
        prog;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("NFSCodeFlatten.flattenCompleteProgram failed\n");
      then
        fail();

  end matchcontinue;
end flattenCompleteProgram;

annotation(__OpenModelica_Interface="frontend");
end NFSCodeFlatten;
