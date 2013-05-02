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

encapsulated package FFlatten
" file:  FFlatten.mo
  package:     FFlatten
  description: SCode flattening

  RCS: $Id: FFlatten.mo 14085 2012-11-27 12:12:40Z adrpo $

  This module flattens the SCode representation by removing all extends, imports
  and redeclares, and fully qualifying class names.
"

public import Absyn;
public import SCode;
public import Env;
public import FDependency;
public import FFlattenImports;

protected import Debug;
protected import FEnvExtends;
protected import Flags;
protected import List;
protected import System;
protected import FLookup;
protected import FEnv;
protected import Builtin;

public type Env = Env.Env;

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
  output Env outEnv;
algorithm
  (outProgram, outEnv) := matchcontinue(inClassName, inProgram)
    local
      Env env;
      SCode.Program prog;

    case (_, prog)
      equation
  //System.startTimer();
  System.tmpTickResetIndex(0, Env.tmpTickIndex);
  System.tmpTickResetIndex(1, Env.extendsTickIndex);

  (_, env) = Builtin.initialEnv(Env.emptyCache());
  env = FEnv.extendEnvWithClasses(prog, env);
  env = FEnvExtends.update(env);

  (prog, env) = FDependency.analyse(inClassName, env, prog);
  checkForCardinality(env);
  (prog, env) = FFlattenImports.flattenProgram(prog, env);

  //System.stopTimer();
  //Debug.traceln("FFlatten.flattenClassInProgram took " +&
  //  realString(System.getTimerIntervalTime()) +& " seconds");

      then
  (prog, env);

    else
      equation
  Debug.fprintln(Flags.FAILTRACE, "FFlatten.flattenClassInProgram failed on " +&
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
  (_, _, _, _) = FLookup.lookupNameSilent(Absyn.IDENT("cardinality"),
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
  (_, env) = Builtin.initialEnv(Env.emptyCache());
  env = FEnv.extendEnvWithClasses(prog, env);
  env = FEnvExtends.update(env);
  (prog, env) = FFlattenImports.flattenProgram(prog, env);
      then
  prog;

    else
      equation
  Debug.fprintln(Flags.FAILTRACE, "FFlatten.flattenCompleteProgram failed");
      then
  fail();

  end matchcontinue;
end flattenCompleteProgram;

end FFlatten;
