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

encapsulated package Builtin
" file:        Builtin.mo
  package:     Builtin
  description: Builting tyepes and variables


  This module defines the builtin types, variables and functions in Modelica.

  There are several builtin attributes defined in the builtin types, such as unit, start, etc."

import Absyn;
import DAE;
import SCode;
import FCore;
import FGraph;

protected

import ClassInf;
import Config;
import FBuiltin;
import Flags;
import FGraphBuildEnv;
import Global;
import Util;

public function variableIsBuiltin
 "Returns true if cref is a builtin variable.
  Currently only 'time' is a builtin variable."
  input DAE.ComponentRef cref;
  output Boolean b;
algorithm
  b := match cref
    local
      String id;
    case DAE.CREF_IDENT(ident=id) then variableNameIsBuiltin(id);
    else false;
  end match;
end variableIsBuiltin;

public function variableNameIsBuiltin
 "Returns true if cref is a builtin variable.
  Currently only 'time' is a builtin variable."
  input String name;
  output Boolean b;
algorithm
  b := match name
    case "time" then true;
    //If accepting Optimica then these variabels are also builtin
    case "startTime" then Config.acceptOptimicaGrammar();
    case "finalTime" then Config.acceptOptimicaGrammar();
    case "objective" then Config.acceptOptimicaGrammar();
    case "objectiveIntegrand" then Config.acceptOptimicaGrammar();
    else false;
  end match;
end variableNameIsBuiltin;

public function isDer
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    local Absyn.Path path;
    case (Absyn.IDENT(name = "der")) then ();
    case (Absyn.FULLYQUALIFIED(path)) equation isDer(path); then ();
  end match;
end isDer;

public function initialGraph
"The initial environment where instantiation takes place is built
  up using this function.  It creates an empty environment and adds
  all the built-in definitions to it.
  NOTE:
    The following built in operators can not be described in
    the type system, since they e.g. have arbitrary arguments, etc.
  - fill
  - cat
    These operators are catched in the elabBuiltinHandler, along with all
    others."
  input FCore.Cache inCache;
  output FCore.Cache outCache;
  output FGraph.Graph graph;
protected
  FCore.Cache cache;
  constant DAE.Type anyNonExpandableConnector2int =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x", DAE.T_ANYTYPE(SOME(ClassInf.CONNECTOR(Absyn.IDENT("$dummy$"),false))),DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_INTEGER_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            Absyn.IDENT("cardinality"));

  constant DAE.Type anyExpandableConnector2int =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",DAE.T_ANYTYPE(SOME(ClassInf.CONNECTOR(Absyn.IDENT("$dummy$"),true))),DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_INTEGER_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            Absyn.IDENT("cardinality"));
algorithm
  (outCache, graph) := matchcontinue(inCache)
    local
      list<Absyn.Class> initialClasses;
      SCode.Program initialProgram;
      list<SCode.Element> types;

    // First look for cached version
    case (cache) equation
      graph = FCore.getCachedInitialGraph(cache);
      // we have references in the graph so we need to clone it before giving it away
      graph = FGraph.clone(graph);
    then (cache,graph);

    // then look in the global roots[builtinEnvIndex]
    case (cache)
      equation
        graph = getSetInitialGraph(NONE());
      then
        (cache, graph);

    // if no cached version found create initial graph.
    case (cache)
      equation
        graph = FGraph.new("graph", FCore.dummyTopModel);
        graph = FGraphBuildEnv.mkProgramGraph(FBuiltin.getBasicTypes(), FCore.BASIC_TYPE(), graph);

        graph = FBuiltin.initialGraphModelica(graph, FGraphBuildEnv.mkTypeNode, FGraphBuildEnv.mkCompNode);

        (_, initialProgram) = FBuiltin.getInitialFunctions();
        // add the ModelicaBuiltin/MetaModelicaBuiltin classes in the initial graph
        graph = FGraphBuildEnv.mkProgramGraph(initialProgram, FCore.BUILTIN(), graph);

        graph = FBuiltin.initialGraphOptimica(graph, FGraphBuildEnv.mkCompNode);
        graph = FBuiltin.initialGraphMetaModelica(graph, FGraphBuildEnv.mkTypeNode);

        cache = FCore.setCachedInitialGraph(cache,graph);
        _ = getSetInitialGraph(SOME(graph));

        graph = FGraph.clone(graph); // we have references in the graph so we need to clone it before returning it
      then
        (cache,graph);

  end matchcontinue;
end initialGraph;

protected function getSetInitialGraph
"gets/sets the initial environment depending on grammar flags"
  input Option<FGraph.Graph> inEnvOpt;
  output FGraph.Graph initialEnv;
algorithm
  initialEnv := matchcontinue (inEnvOpt)
    local
      list<tuple<Integer,FGraph.Graph>> assocLst;
      FGraph.Graph graph;
      Integer f;

    // nothing there
    case (_)
      equation
        failure(_ = getGlobalRoot(Global.builtinGraphIndex));
        setGlobalRoot(Global.builtinGraphIndex, {});
      then
        fail();

    // return the correct graph depending on flags
    case (NONE())
      equation
        assocLst = getGlobalRoot(Global.builtinGraphIndex);
        // we have references in the graph so we need to clone it before giving it away
        graph = FGraph.clone(Util.assoc(Flags.getConfigEnum(Flags.GRAMMAR), assocLst));
      then
        graph;

    case (SOME(graph))
      equation
        assocLst = getGlobalRoot(Global.builtinGraphIndex);
        f = Flags.getConfigEnum(Flags.GRAMMAR);
        assocLst = if f == Flags.METAMODELICA
                   then (Flags.METAMODELICA,graph)::assocLst
                   else if f == Flags.PARMODELICA
                        then (Flags.PARMODELICA,graph)::assocLst
                        else if f == Flags.MODELICA
                             then (Flags.MODELICA,graph)::assocLst
                             else assocLst;
        setGlobalRoot(Global.builtinGraphIndex, assocLst);
      then
        graph;

  end matchcontinue;
end getSetInitialGraph;

public function clearInitialGraph
algorithm
  setGlobalRoot(Global.builtinGraphIndex, {});
end clearInitialGraph;

annotation(__OpenModelica_Interface="frontend");
end Builtin;
