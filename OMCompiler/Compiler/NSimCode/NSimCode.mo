/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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
encapsulated package NSimCode
"file:        NSimCode.mo
 package:     NSimCode
 description: This file contains the main data type for the backend containing
              all data. It further contains the lower and solve main function.
"

protected
  // NF imports
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;

  // Backend imports
  import BackendDAE = NBackendDAE;

  // SimCode imports
  import SimStrongComponent = NSimStrongComponent;
  import NSimVar.SimVar;

public
    uniontype SimCode
    record SIM_CODE
      //ModelInfo modelInfo;
      list<Expression> literals                         "shared literals";
      //list<SimCodeFunction.RecordDeclaration> recordDecls;
      list<String> externalFunctionIncludes             "Names of all external functions that are called";
      list<SimStrongComponent.Block> independent        "state and strictly input dependent variables. they are not inserted into any partion";
      list<SimStrongComponent.Block> allSim             "All simulation system blocks";
      // kabdelhak: why nested lists?
      list<list<SimStrongComponent.Block>> ode          "Only ode blocks for integrator";
      list<list<SimStrongComponent.Block>> algebraic    "Additional purely algebraic blocks";
      //list<ClockedPartition> clockedPartitions;
      list<SimStrongComponent.Block> nominal            "Blocks for nominal value equations";
      list<SimStrongComponent.Block> min                "Blocks for min value equations";
      list<SimStrongComponent.Block> max                "Blocks for max value equations";
      list<SimStrongComponent.Block> param              "Blocks for parameter equations";
      list<SimStrongComponent.Block> no_ret             "Blocks for equations without return value";
      list<SimStrongComponent.Block> algorithms         "Blocks for algorithms and asserts";
      list<SimStrongComponent.Block> zero_cross         "Blocks for zero crossing functions";
      list<SimStrongComponent.Block> jac_blocks         "Blocks for jacobian equations";
      list<SimStrongComponent.Block> start              "Blocks for start value equations";
      list<SimStrongComponent.Block> init               "Blocks for initial equations";
      list<SimStrongComponent.Block> init_0             "Blocks for initial lambda 0 equations (homotopy)";
      list<SimStrongComponent.Block> init_no_ret        "Blocks for initial equations without return value";
      //list<DAE.Statement> algorithmAndEquationAsserts;
      //list<StateSet> stateSets;
      //list<DAE.Constraint> constraints;
      //list<DAE.ClassAttributes> classAttributes;
      //list<BackendDAE.ZeroCrossing> zeroCrossings;
      //list<BackendDAE.ZeroCrossing> relations "only used by c runtime";
      //list<BackendDAE.TimeEvent> timeEvents "only used by c runtime yet";
      list<ComponentRef> discreteVars                   "List of discrete variables";
      //ExtObjInfo extObjInfo;
      //SimCodeFunction.MakefileParams makefileParams;
      //DelayedExpression delayedExps;
      list<SimStrongComponent.Jacobian> jacobians       "List of symbolic jacobians";
      //Option<SimulationSettings> simulationSettingsOpt;
      //String fileNamePrefix, fullPathPrefix "Used in FMI where files are generated in a special directory";
      //String fmuTargetName;
      //HpcOmSimCode.HpcOmData hpcomData;
      //AvlTreeCRToInt.Tree valueReferences "Used in FMI";
      //maps each variable to an array of storage indices (with this information, arrays must not be unrolled) and a list for the array-dimensions
      //if the variable is not part of an array (if it is a scalar value), then the array has size 1
      //HashTableCrIListArray.HashTable varToArrayIndexMapping;
      //*** a protected section *** not exported to SimCodeTV
      //HashTableCrILst.HashTable varToIndexMapping;
      //HashTableCrefToSimVar crefToSimVarHT "hidden from typeview - used by cref2simvar() for cref -> SIMVAR lookup available in templates.";
      //HashTable.HashTable crefToClockIndexHT "map variables to clock indices";
      //Option<BackendMapping> backendMapping;
      //FMI 2.0 data for model structure
      //Option<FmiModelStructure> modelStructure;
      //PartitionData partitionData;
      Option<DaeModeData> daeModeData                   "Simulation system in case of DAEMode";
      list<SimStrongComponent.Block> inlineEquations; // ToDo: what exactly is this?
      //Option<OMSIData> omsiData "used for OMSI to generate equations code";
    end SIM_CODE;

    function create
      input BackendDAE.BackendDAE bdae;
      output SimCode simCode;
    protected
      list<Expression> literals;
      list<String> externalFunctionIncludes;
      list<SimStrongComponent.Block> independent, allSim, nominal, min, max, param, no_ret, algorithms;
      list<SimStrongComponent.Block> zero_cross, jac_blocks;
      list<SimStrongComponent.Block> init, init_0, init_no_ret, start;
      list<list<SimStrongComponent.Block>> ode, algebraic;
      list<ComponentRef> discreteVars;
      list<SimStrongComponent.Jacobian> jacobians;
      Option<DaeModeData> daeModeData;
      list<SimStrongComponent.Block> inlineEquations; // ToDo: what exactly is this?
    algorithm
      // ToDo: fill this with meaningful stuff
      literals := {};
      externalFunctionIncludes := {};
      independent := {};
      allSim := {};
      nominal := {};
      min := {};
      max := {};
      param := {};
      no_ret := {};
      algorithms := {};
      zero_cross := {};
      jac_blocks := {};
      init := {};
      init_0 := {};
      init_no_ret := {};
      start := {};
      ode := {};
      algebraic := {};
      discreteVars := {};
      jacobians := {};
      daeModeData := NONE();
      inlineEquations := {};

      simCode := SIM_CODE(literals,
                          externalFunctionIncludes,
                          independent,
                          allSim,
                          ode,
                          algebraic,
                          nominal,
                          min,
                          max,
                          param,
                          no_ret,
                          algorithms,
                          zero_cross,
                          jac_blocks,
                          init,
                          init_0,
                          init_no_ret,
                          start,
                          discreteVars,
                          jacobians,
                          daeModeData,
                          inlineEquations
                        );
    end create;
  end SimCode;

  uniontype DaeModeData
    "contains data that belongs to the dae mode"
    record DAEMODEDATA
      list<list<SimStrongComponent.Block>> daeEquations "daeModel residuals equations";
      Option<SimStrongComponent.Jacobian> sparsityPattern "contains the sparsity pattern for the daeMode";
      list<SimVar> residualVars "variable used to calculate residuals of a DAE form, they are real";
      list<SimVar> algebraicVars;
      list<SimVar> auxiliaryVars;
      DaeModeConfig modeCreated;
    end DAEMODEDATA;
  end DaeModeData;

  type DaeModeConfig = enumeration(ALL, DYNAMIC);
  annotation(__OpenModelica_Interface="backend");
end NSimCode;
