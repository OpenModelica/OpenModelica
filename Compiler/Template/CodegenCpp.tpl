package CodegenCpp

import interface SimCodeTV;
import CodegenCppCommon.*;
import CodegenUtil.*;
import CodegenCppInit.*;
import ExpressionDumpTpl;

//
//  Generates Modelica system class with the fowling inheritance structure
//
//  Base class      : ModelicaSystem -> implements IContinuous, IEvent, IStepEvent, ITime, ISystemProperties
//  Derived class 1 : ModelicaSystemJacobian -> holds all Jacobian information
//  Derived class 2 : ModelicaSystemMixed -> implements IMixedSystems
//  Derived class 3 : ModelicaSystemStateSelection -> implements IStateSelection
//  Derived class 4 : ModelicaSystemStateWriteOutput -> implements IWriteOutput
//  Derived class 5 : ModelicaSystemStateInitialize  -> implements ISystemInitialization
//


template translateModel(SimCode simCode)
::=
  let stateDerVectorName = "__zDot"
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__)) then
        let target  = simulationCodeTarget()
        let &extraFuncs = buffer "" /*BUFD*/
        let &extraFuncsDecl = buffer "" /*BUFD*/
		let &extraResidualsFuncsDecl = buffer "" /*BUFD*/
        let &dummyTypeElemCreation = buffer "" //remove this workaround if GCC > 4.4 is the default compiler

        let className = lastIdentOfPath(modelInfo.name)
        let numRealVars = numRealvars(modelInfo)
        let numIntVars = numIntvars(modelInfo)
        let numBoolVars = numBoolvars(modelInfo)
        let numStringVars = numStringvars(modelInfo)

        let()= textFile(simulationMainFile(target, simCode , &extraFuncs , &extraFuncsDecl, "", "", "", "", numRealVars, numIntVars, numBoolVars, numStringVars, getPreVarsCount(modelInfo)), 'OMCpp<%fileNamePrefix%>Main.cpp')
        let()= textFile(simulationCppFile(simCode, contextOther, update(simCode , &extraFuncs , &extraFuncsDecl,  className, stateDerVectorName, false),
                        '<%numRealVars%> - 1', '<%numIntVars%> - 1', '<%numBoolVars%> - 1', '<%numStringVars%> - 1', &extraFuncs, &extraFuncsDecl, className, "", "", "",
                        stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>.cpp')
        let()= textFile(simulationHeaderFile(simCode , contextOther,&extraFuncs , &extraFuncsDecl, className, "", "", "",
                                             memberVariableDefine(modelInfo, varToArrayIndexMapping, '<%numRealVars%> - 1', '<%numIntVars%> - 1', '<%numBoolVars%> - 1', '<%numStringVars%> - 1', Flags.isSet(Flags.GEN_DEBUG_SYMBOLS), false),
                                             memberVariableDefinePreVariables(modelInfo, varToArrayIndexMapping, '<%numRealVars%> - 1', '<%numIntVars%> - 1', '<%numBoolVars%> - 1', '<%numStringVars%> - 1', Flags.isSet(Flags.GEN_DEBUG_SYMBOLS), false),
                                             false), 'OMCpp<%fileNamePrefix%>.h')
        let()= textFile(simulationTypesHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, "", &dummyTypeElemCreation, modelInfo.functions, literals, stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>Types.h')
        let()= textFile(simulationMakefile(target,simCode , &extraFuncs , &extraFuncsDecl, "","","","","",false), '<%fileNamePrefix%>.makefile')

        let &extraFuncsFun = buffer "" /*BUFD*/
        let &extraFuncsDeclFun = buffer "" /*BUFD*/
        let()= textFile(simulationFunctionsFile(simCode, &extraFuncsFun, &extraFuncsDeclFun, 'Functions', modelInfo.functions, literals, externalFunctionIncludes, stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>Functions.cpp')
        let()= textFile(simulationFunctionsHeaderFile(simCode, &extraFuncsFun, &extraFuncsDeclFun, 'Functions', modelInfo.functions, literals, stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>Functions.h')

        let &extraFuncsInit = buffer "" /*BUFD*/
        let &extraFuncsDeclInit = buffer "" /*BUFD*/
        let &complexStartExpressions = buffer ""
        let()= textFile(modelInitXMLFile(simCode, numRealVars, numIntVars, numBoolVars, numStringVars, "", "", "", false, "", complexStartExpressions, stateDerVectorName),'<%fileNamePrefix%>_init.xml')
        let()= textFile(simulationInitCppFile(simCode , &extraFuncsInit , &extraFuncsDeclInit, '<%className%>Initialize', dummyTypeElemCreation, stateDerVectorName, false, complexStartExpressions),'OMCpp<%fileNamePrefix%>Initialize.cpp')

        let _ = match boolOr(Flags.isSet(Flags.HARDCODED_START_VALUES), Flags.isSet(Flags.GEN_DEBUG_SYMBOLS))
          case true then
            let()= textFile(simulationInitParameterCppFile(simCode, &extraFuncsInit, &extraFuncsDeclInit, '<%className%>Initialize', stateDerVectorName, false),'OMCpp<%fileNamePrefix%>InitializeParameter.cpp')
            let()= textFile(simulationInitAlgVarsCppFile(simCode , &extraFuncsInit , &extraFuncsDeclInit, '<%className%>Initialize', stateDerVectorName, false),'OMCpp<%fileNamePrefix%>InitializeAlgVars.cpp')
            ""
          else
            ""

        let()= textFile(simulationInitExtVarsCppFile(simCode, &extraFuncsInit, &extraFuncsDeclInit, '<%className%>Initialize', stateDerVectorName, false),'OMCpp<%fileNamePrefix%>InitializeExtVars.cpp')
        let()= textFile(simulationInitHeaderFile(simCode , &extraFuncsInit , &extraFuncsDeclInit, '<%className%>Initialize'), 'OMCpp<%fileNamePrefix%>Initialize.h')

        let &jacobianVarsInit = buffer "" /*BUFD*/
        let()= textFile(simulationJacobianHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, "", &jacobianVarsInit, Flags.isSet(Flags.GEN_DEBUG_SYMBOLS)), 'OMCpp<%fileNamePrefix%>Jacobian.h')
        let()= textFile(simulationJacobianCppFile(simCode , &extraFuncs , &extraFuncsDecl, "", &jacobianVarsInit, stateDerVectorName, false),'OMCpp<%fileNamePrefix%>Jacobian.cpp')
        let()= textFile(simulationStateSelectionCppFile(simCode , &extraFuncs , &extraFuncsDecl, "", stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>StateSelection.cpp')
        let()= textFile(simulationStateSelectionHeaderFile(simCode , &extraFuncs , &extraFuncsDecl, ""),'OMCpp<%fileNamePrefix%>StateSelection.h')
        let()= textFile(simulationMixedSystemCppFile(simCode  ,  updateResiduals(simCode,extraFuncs,extraResidualsFuncsDecl,className,stateDerVectorName /*=__zDot*/, false)
		                                            ,&extraFuncs , &extraFuncsDecl, "", stateDerVectorName, false),'OMCpp<%fileNamePrefix%>Mixed.cpp')
		let()= textFile(simulationMixedSystemHeaderFile(simCode , &extraFuncs , &extraResidualsFuncsDecl, ""),'OMCpp<%fileNamePrefix%>Mixed.h')

        let()= textFile(simulationWriteOutputHeaderFile(simCode , &extraFuncs , &extraFuncsDecl, ""),'OMCpp<%fileNamePrefix%>WriteOutput.h')
        let()= textFile(simulationWriteOutputCppFile(simCode , &extraFuncs , &extraFuncsDecl, "", stateDerVectorName, false),'OMCpp<%fileNamePrefix%>WriteOutput.cpp')
        let()= textFile(simulationFactoryFile(simCode , &extraFuncs , &extraFuncsDecl, ""),'OMCpp<%fileNamePrefix%>FactoryExport.cpp')
        let()= textFile(simulationMainRunScript(simCode , &extraFuncs , &extraFuncsDecl, "", "", "", "exec"), '<%fileNamePrefix%><%simulationMainRunScriptSuffix(simCode , &extraFuncs , &extraFuncsDecl, "")%>')
        let jac =  (jacobianMatrixes |> (mat, _, _, _, _, _, _) =>
          (mat |> (eqs,_,_) =>  algloopfiles(eqs,simCode , &extraFuncs , &extraFuncsDecl, "",contextAlgloopJacobian, stateDerVectorName, false) ;separator="")
         ;separator="")

        let alg = algloopfiles(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl, "", contextAlgloop, stateDerVectorName, false)
        let()= textFile(algloopMainfile(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl, "",contextAlgloop), 'OMCpp<%fileNamePrefix%>AlgLoopMain.cpp')
        let()= textFile(calcHelperMainfile(simCode , &extraFuncs , &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>CalcHelperMain.cpp')

        match target
          case "vxworks69" then
            let()= textFile(functionBlock(simCode), '<%fileNamePrefix%>_PLCOPEN.xml')
            let()= textFile(ftp_script(simCode), '<%fileNamePrefix%>_ftp.bat')
            ""
          else ""

  end match
end translateModel;


template translateFunctions(FunctionCode functionCode)
 "Generates C code and Makefile for compiling and calling Modelica and
  MetaModelica functions."
::=
  match functionCode
  case FUNCTIONCODE(__) then

  "" // Return empty result since result written to files directly
end translateFunctions;

template simulationHeaderFile(SimCode simCode ,Context context,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, String additionalIncludes,
                              String additionalPublicMembers, String additionalProtectedMembers, String memberVariableDefinitions, String memberPreVariableDefinitions, Boolean useFlatArrayNotation)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(__) then
   <<
   <%generateHeaderIncludeString(simCode, &extraFuncs , &extraFuncsDecl, extraFuncsNamespace)%>
   <%additionalIncludes%>
   <%generateClassDeclarationCode(simCode ,context, &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, additionalPublicMembers, additionalProtectedMembers, memberVariableDefinitions, memberPreVariableDefinitions, useFlatArrayNotation)%>
   >>
end simulationHeaderFile;


template simulationInitHeaderFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(vars=SIMVARS(__)),fileNamePrefix=fileNamePrefix) then
let initeqs = generateEquationMemberFuncDecls(initialEquations,"initEquation")
let initparameqs = generateEquationMemberFuncDecls(parameterEquations,"initParameterEquation")
  match modelInfo
    case modelInfo as MODELINFO(vars=SIMVARS(__)) then
      let functionPrefix = if(Flags.isSet(Flags.HARDCODED_START_VALUES)) then "initialize" else "check"
    <<
    #pragma once

    /*****************************************************************************
    *
    * Simulation code to initialize the Modelica system
    *
    *****************************************************************************/

    class <%lastIdentOfPath(modelInfo.name)%>Initialize : public ISystemInitialization, public <%lastIdentOfPath(modelInfo.name)%>WriteOutput
    {
     public:
      <%lastIdentOfPath(modelInfo.name)%>Initialize(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects);
      <%lastIdentOfPath(modelInfo.name)%>Initialize(<%lastIdentOfPath(modelInfo.name)%>Initialize& instance);
      virtual ~<%lastIdentOfPath(modelInfo.name)%>Initialize();
      virtual bool initial();
      virtual void setInitial(bool);
      virtual void initialize();
      virtual void initializeMemory();
      virtual void initializeFreeVariables();
      virtual void initializeBoundVariables();
      virtual void initParameterEquations();
      virtual void initEquations();
      virtual IMixedSystem* clone();
      <%if(boolAnd(boolNot(Flags.isSet(Flags.HARDCODED_START_VALUES)), Flags.isSet(Flags.GEN_DEBUG_SYMBOLS))) then
        <<
        virtual void checkVariables();
        virtual void checkParameters();
        >>
      %>
    private:
      <%initeqs%>
      <%initparameqs%>
      <%initExtVarsDecl(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, false)%>

      void InitializeDummyTypeElems();

      <%if(boolOr(Flags.isSet(Flags.HARDCODED_START_VALUES), Flags.isSet(Flags.GEN_DEBUG_SYMBOLS))) then
        <<
        <%List.partition(vars.algVars, 100) |> ls hasindex idx => 'void <%functionPrefix%>AlgVars_<%idx%>();';separator="\n"%>

        void <%functionPrefix%>AlgVars();
        void <%functionPrefix%>DiscreteAlgVars();

        <%List.partition(vars.intAlgVars, 100) |> ls hasindex idx => 'void <%functionPrefix%>IntAlgVars_<%idx%>();';separator="\n"%>

        void <%functionPrefix%>IntAlgVars();
        void <%functionPrefix%>BoolAlgVars();

        <%List.partition(vars.stringAlgVars, 100) |> ls hasindex idx => 'void <%functionPrefix%>StringAlgVars_<%idx%>();';separator="\n"%>

        void <%functionPrefix%>StringAlgVars();

        <%List.partition(vars.aliasVars, 100) |> ls hasindex idx => 'void <%functionPrefix%>AliasVars_<%idx%>();';separator="\n"%>
        <%List.partition(vars.stringAliasVars, 100) |> ls hasindex idx => 'void <%functionPrefix%>StringAliasVars_<%idx%>();';separator="\n"%>
        void <%functionPrefix%>StringAliasVars();
        void <%functionPrefix%>AliasVars();
        void <%functionPrefix%>IntAliasVars();
        void <%functionPrefix%>BoolAliasVars();

        <%List.partition(vars.paramVars, 100) |> ls hasindex idx => 'void <%functionPrefix%>ParameterVars_<%idx%>();';separator="\n"%>
        <%List.partition(vars.intParamVars, 100) |> ls hasindex idx => 'void <%functionPrefix%>IntParameterVars_<%idx%>();';separator="\n"%>
        <%List.partition(vars.boolParamVars, 100) |> ls hasindex idx => 'void <%functionPrefix%>BoolParameterVars_<%idx%>();';separator="\n"%>
        <%List.partition(vars.stringParamVars, 100) |> ls hasindex idx => 'void <%functionPrefix%>StringParameterVars_<%idx%>();';separator="\n"%>
        void <%functionPrefix%>ParameterVars();
        void <%functionPrefix%>IntParameterVars();
        void <%functionPrefix%>BoolParameterVars();
        void <%functionPrefix%>StringParameterVars();
        void <%functionPrefix%>StateVars();
        void <%functionPrefix%>DerVars();
        >>
      %>
      /*extraFuncs*/
      <%extraFuncsDecl%>
    };
    >>
  end match
end simulationInitHeaderFile;

template simulationJacobianHeaderFile(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text& jacobianVarsInit, Boolean createDebugCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  let type = getConfigString(MATRIX_FORMAT)
  let matrixreturntype =  match type
    case ("dense") then
     "matrix_t"
    case ("sparse") then
     "sparsematrix_t"
    else "A matrix type is not supported"
    end match

  <<
  #pragma once

  /*****************************************************************************
  *
  * Simulation code to initialize the Modelica system
  *
  *****************************************************************************/

  class <%lastIdentOfPath(modelInfo.name)%>Jacobian : public <%lastIdentOfPath(modelInfo.name)%>
  {
  <% (jacobianMatrixes |> (mat, _, _, _, _, _, _) hasindex index0 =>
       (mat |> (eqs,_,_) =>  generatefriendAlgloops(eqs,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator="\n")
     ;separator="")
  %>
  public:
    <%lastIdentOfPath(modelInfo.name)%>Jacobian(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects);
    <%lastIdentOfPath(modelInfo.name)%>Jacobian(<%lastIdentOfPath(modelInfo.name)%>Jacobian& instance);
    virtual ~<%lastIdentOfPath(modelInfo.name)%>Jacobian();

  protected:
    void initialize();
    <%
    let jacobianfunctions = (jacobianMatrixes |> (_,_, name, _, _, _, _) hasindex index0 =>
    <<

    void calc<%name%>JacobianColumn();
    const <%matrixreturntype%>& get<%name%>Jacobian();
    >>
    ;separator="\n";empty)
    <<
    <%jacobianfunctions%>
    >>
    %>
    <%
    let jacobianvars = (jacobianMatrixes |> (_,_, name, _, _, _, _) hasindex index0 =>
      <<

      <%matrixreturntype%> _<%name%>jacobian;
      ublas::vector<double> _<%name%>jac_y;
      ublas::vector<double> _<%name%>jac_tmp;
      ublas::vector<double> _<%name%>jac_x;
      int* _<%name%>ColorOfColumn;
      int  _<%name%>MaxColors;
      >>
    ;separator="\n";empty)
    <<
    <%jacobianvars%>
    >>
    %>

    <%variableDefinitionsJacobians(jacobianMatrixes, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, &jacobianVarsInit, createDebugCode)%>

    /*testmaessig aus der Cruntime*/
    void initializeColoredJacobianA();

  };
  >>
end simulationJacobianHeaderFile;


template simulationStateSelectionHeaderFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  <<
  #pragma once

  /*****************************************************************************
  *
  * Simulation code to initialize the Modelica system
  *
  *****************************************************************************/
  class <%lastIdentOfPath(modelInfo.name)%>StateSelection: public IStateSelection, public <%lastIdentOfPath(modelInfo.name)%>Mixed
  {
  public:
    <%lastIdentOfPath(modelInfo.name)%>StateSelection(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects);
    virtual ~<%lastIdentOfPath(modelInfo.name)%>StateSelection();
    int getDimStateSets() const;
    int getDimStates(unsigned int index) const;
    int getDimCanditates(unsigned int index) const ;
    int getDimDummyStates(unsigned int index) const ;
    void getStates(unsigned int index,double* z);
    void setStates(unsigned int index,const double* z);
    void getStateCanditates(unsigned int index,double* z);
    bool getAMatrix(unsigned int index, DynArrayDim2<int>& A);
    void setAMatrix(unsigned int index, DynArrayDim2<int>& A);
    bool getAMatrix(unsigned int index, DynArrayDim1<int>& A);
    void setAMatrix(unsigned int index, DynArrayDim1<int>& A);

  protected:
    void initialize();
  };
  >>
end simulationStateSelectionHeaderFile;
/*

    */
template simulationWriteOutputHeaderFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__),simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
  <<
  #pragma once


  /*****************************************************************************
  *
  * Simulation code to write simulation file
  *
  *****************************************************************************/

  class <%lastIdentOfPath(modelInfo.name)%>WriteOutput : public IWriteOutput,public <%lastIdentOfPath(modelInfo.name)%>StateSelection
  {
  public:
    <%lastIdentOfPath(modelInfo.name)%>WriteOutput(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects);
    <%lastIdentOfPath(modelInfo.name)%>WriteOutput(<%lastIdentOfPath(modelInfo.name)%>WriteOutput& instance);
    virtual ~<%lastIdentOfPath(modelInfo.name)%>WriteOutput();


    /// Output routine (to be called by the solver after every successful integration step)
    virtual void writeOutput(const IWriteOutput::OUTPUT command = IWriteOutput::UNDEF_OUTPUT);
    virtual IHistory* getHistory();

  protected:
    void initialize();
   private:
    shared_ptr<IHistory> _writeOutput;
  };
  >>
end simulationWriteOutputHeaderFile;


template getPreVarsCount(ModelInfo modelInfo)
::=
  match modelInfo
    case MODELINFO(varInfo=VARINFO(__)) then
      let allVarCount = intAdd(stringInt(numRealvars(modelInfo)), intAdd(stringInt(numIntvars(modelInfo)), stringInt(numBoolvars(modelInfo))))
      <<
      <%allVarCount%>
      >>
    end match
end getPreVarsCount;


template simulationMixedSystemHeaderFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(vars = vars as SIMVARS(__))) then
  <<
  #pragma once
  /*****************************************************************************
  *
  * Simulation code
  *
  *****************************************************************************/
  class <%lastIdentOfPath(modelInfo.name)%>Mixed:  public IMixedSystem, public <%lastIdentOfPath(modelInfo.name)%>Jacobian
  {
  public:
     <%lastIdentOfPath(modelInfo.name)%>Mixed(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects);
     <%lastIdentOfPath(modelInfo.name)%>Mixed(<%lastIdentOfPath(modelInfo.name)%>Mixed &instance);
    virtual ~ <%lastIdentOfPath(modelInfo.name)%>Mixed();



    /// Provide Jacobian
    virtual const matrix_t& getJacobian() ;
    virtual const matrix_t& getJacobian(unsigned int index) ;
    virtual const sparsematrix_t& getSparseJacobian();
    virtual const sparsematrix_t& getSparseJacobian(unsigned int index);


    virtual  const matrix_t& getStateSetJacobian(unsigned int index);
    virtual  const sparsematrix_t& getStateSetSparseJacobian(unsigned int index);
    /// Called to handle all events occured at same time
    virtual bool handleSystemEvents(bool* events);
    //Saves all variables before an event is handled, is needed for the pre, edge and change operator
    virtual void saveAll();
    virtual void getAlgebraicDAEVars(double* y);
    virtual void setAlgebraicDAEVars(const double* y);
    virtual void getResidual(double* f);
	virtual void evaluateDAE(const UPDATETYPE command = UNDEF_UPDATE);

    /*colored jacobians*/
    virtual void getAColorOfColumn(int* aSparsePatternColorCols, int size);
    virtual int  getAMaxColors();

    virtual string getModelName();
   private:
     //update residual methods
    <%extraFuncsDecl%>
	<%simulationDAEMethodsDeclaration(simCode)%>
  };
  >>
end simulationMixedSystemHeaderFile;



template simulationFactoryFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO()) then
  <<
  #if defined(__TRICORE__) || defined(__vxworks)
  #include <Core/System/FactoryExport.h>
  #include <Core/DataExchange/SimData.h>
  #include <Core/System/SimVars.h>
  extern "C" IMixedSystem* createModelicaSystem(IGlobalSettings* globalSettings,shared_ptr<ISimObjects> simObjects)
  {
      return new <%lastIdentOfPath(modelInfo.name)%>Initialize(globalSettings, simObjects);
  }

  extern "C" ISimVars* createSimVars(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string, size_t dim_pre_vars, size_t dim_z, size_t z_i)
  {
      return new SimVars(dim_real, dim_int, dim_bool, dim_string, dim_pre_vars, dim_z, z_i);
  }

  extern "C" ISimData* createSimData()
  {
      return new SimData();
  }

  shared_ptr<ISimData> createSimDataFunction()
  {
    shared_ptr<ISimData> data( new SimData() );
    return data;
  }

  shared_ptr<ISimVars> createSimVarsFunction(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string, size_t dim_pre_vars, size_t dim_z, size_t z_i)
  {
    shared_ptr<ISimVars> var( new SimVars(dim_real, dim_int, dim_bool, dim_string, dim_pre_vars, dim_z, z_i) );
    return var;
  }

  #elif defined (RUNTIME_STATIC_LINKING)
  #include <Core/System/FactoryExport.h>
  #include <Core/DataExchange/SimData.h>
  #include <Core/System/SimVars.h>
    shared_ptr<ISimData> createSimDataFunction()
    {
        shared_ptr<ISimData> data( new SimData() );
        return data;
    }

    shared_ptr<ISimVars> createSimVarsFunction(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string, size_t dim_pre_vars, size_t dim_z, size_t z_i)
    {
        shared_ptr<ISimVars> var( new SimVars(dim_real, dim_int, dim_bool, dim_string, dim_pre_vars, dim_z, z_i) );
        return var;
    }

    shared_ptr<IMixedSystem> createSystemFunction(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects)
    {
        shared_ptr<IMixedSystem> system( new <%lastIdentOfPath(modelInfo.name)%>Initialize(globalSettings, simObjects) );
        return system;
    }

  #else

  BOOST_EXTENSION_TYPE_MAP_FUNCTION
  {
    typedef boost::extensions::factory<IMixedSystem,IGlobalSettings*, shared_ptr<ISimObjects> > system_factory;
    types.get<std::map<std::string, system_factory> >()["<%lastIdentOfPath(modelInfo.name)%>"]
      .system_factory::set<<%lastIdentOfPath(modelInfo.name)%>Initialize>();
  }
  #endif
  >>
end simulationFactoryFile;



template simulationInitCppFile(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text& dummyTypeElemCreation, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Text& complexStartExpressions)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
   <<
   <%algloopfilesInclude(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>

   <%lastIdentOfPath(modelInfo.name)%>Initialize::<%lastIdentOfPath(modelInfo.name)%>Initialize(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects)
   : <%lastIdentOfPath(modelInfo.name)%>WriteOutput(globalSettings, simObjects)
   , _constructedExternalObjects(false)
   {
     InitializeDummyTypeElems();
   }

   <%lastIdentOfPath(modelInfo.name)%>Initialize::<%lastIdentOfPath(modelInfo.name)%>Initialize(<%lastIdentOfPath(modelInfo.name)%>Initialize& instance)
   : <%lastIdentOfPath(modelInfo.name)%>WriteOutput(instance)
   {
     InitializeDummyTypeElems();
   }

   <%lastIdentOfPath(modelInfo.name)%>Initialize::~<%lastIdentOfPath(modelInfo.name)%>Initialize()
   {
     if (_constructedExternalObjects)
       destructExternalObjects();
   }

   void <%lastIdentOfPath(modelInfo.name)%>Initialize::InitializeDummyTypeElems()
   {
     //This is necessary to prevent linker errors that occur with GCC 4.4 if a complex type is not used in the code and contains arrays
     <%dummyTypeElemCreation%>
   }

   IMixedSystem* <%lastIdentOfPath(modelInfo.name)%>Initialize::clone()
   {
     return new <%lastIdentOfPath(modelInfo.name)%>Initialize(*this);
   }

   <%getIntialStatus(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)%>

   <%setIntialStatus(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)%>

   <%init(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation, complexStartExpressions)%>
  >>
end simulationInitCppFile;

template simulationInitParameterCppFile(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
  case SIMCODE(__) then
    match modelInfo
      case modelInfo as MODELINFO(vars=SIMVARS(__))  then
        let &varDecls10 = buffer "" /*BUFD*/
        let &varDecls11 = buffer "" /*BUFD*/
        let &varDecls12 = buffer "" /*BUFD*/
        let functionPrefix = if(Flags.isSet(Flags.HARDCODED_START_VALUES)) then 'initialize' else 'check'
        let init10  = initValstWithSplit(varDecls10, "Real", '<%lastIdentOfPath(modelInfo.name)%>Initialize::<%functionPrefix%>ParameterVars', vars.paramVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
        let init11  = initValstWithSplit(varDecls11, "Int", '<%lastIdentOfPath(modelInfo.name)%>Initialize::<%functionPrefix%>IntParameterVars', vars.intParamVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
        let init12  = initValstWithSplit(varDecls12, "Bool", '<%lastIdentOfPath(modelInfo.name)%>Initialize::<%functionPrefix%>BoolParameterVars', vars.boolParamVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
        let init13  = initValstWithSplit(varDecls12, "String", '<%lastIdentOfPath(modelInfo.name)%>Initialize::<%functionPrefix%>StringParameterVars', vars.stringParamVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
        <<
        <%varDecls10%>
        <%varDecls11%>
        <%varDecls12%>
        <%init10%>
        <%init11%>
        <%init12%>
        <%init13%>
        >>
end simulationInitParameterCppFile;

template simulationInitAlgVarsCppFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(__) then
match modelInfo
case modelInfo as MODELINFO(vars=SIMVARS(__))  then
   let &varDecls3 = buffer "" /*BUFD*/
   let &varDecls4 = buffer "" /*BUFD*/
   let &varDecls5 = buffer "" /*BUFD*/
   let &varDecls6 = buffer "" /*BUFD*/
   let &varDecls7 = buffer "" /*BUFD*/
   let functionPrefix = if Flags.isSet(Flags.HARDCODED_START_VALUES) then "initialize" else "check"

   let init3   = initValstWithSplit(varDecls3, "Real", '<%lastIdentOfPath(modelInfo.name)%>Initialize::<%functionPrefix%>AlgVars', vars.algVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
   let init4   = initValst(varDecls4, "Real", vars.discreteAlgVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace,contextOther, stateDerVectorName, useFlatArrayNotation)
   let init5   = initValstWithSplit(varDecls5, "Int", '<%lastIdentOfPath(modelInfo.name)%>Initialize::<%functionPrefix%>IntAlgVars', vars.intAlgVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
   let init6   = initValst(varDecls6, "Bool", vars.boolAlgVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
   let init7   = initValstWithSplit(varDecls7, "String", '<%lastIdentOfPath(modelInfo.name)%>Initialize::<%functionPrefix%>StringAlgVars', vars.stringAlgVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)

   <<

   <%init3%>

   void <%lastIdentOfPath(modelInfo.name)%>Initialize::<%functionPrefix%>DiscreteAlgVars()
   {
      <%varDecls4%>
      <%init4%>
   }

   <%init5%>

   void <%lastIdentOfPath(modelInfo.name)%>Initialize::<%functionPrefix%>BoolAlgVars()
   {
       <%varDecls6%>
       <%init6%>
   }

   <%init7%>
   >>
end simulationInitAlgVarsCppFile;


template simulationInitExtVarsCppFile(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
  initExtVars(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
end simulationInitExtVarsCppFile;


template simulationJacobianCppFile(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text &jacobianVarsInit, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
   let initialjacMats = (jacobianMatrixes |> (mat, vars, name, (sparsepattern,_), colorList, _, jacIndex) =>
    initialAnalyticJacobians(jacIndex, mat, vars, name, sparsepattern, colorList,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
    ;separator="\n";empty)
   <<

   <% (jacobianMatrixes |> (mat, _, _, _, _, _, _) hasindex index0 =>
       (mat |> (eqs,_,_) =>  algloopfilesInclude(eqs,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator="")
     ;separator="")
   %>
   <%lastIdentOfPath(modelInfo.name)%>Jacobian::<%lastIdentOfPath(modelInfo.name)%>Jacobian(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects)
       : <%lastIdentOfPath(modelInfo.name)%>(globalSettings,simObjects)
       , _AColorOfColumn(NULL)
       , _AMaxColors(0)
       <%initialjacMats%>
       <%jacobianVarsInit%>
   {
   }

   <%lastIdentOfPath(modelInfo.name)%>Jacobian::<%lastIdentOfPath(modelInfo.name)%>Jacobian(<%lastIdentOfPath(modelInfo.name)%>Jacobian& instance)
       : <%lastIdentOfPath(modelInfo.name)%>(instance)
       , _AColorOfColumn(NULL)
       , _AMaxColors(0)
       <%initialjacMats%>
       <%jacobianVarsInit%>
   {
   }

   <%lastIdentOfPath(modelInfo.name)%>Jacobian::~<%lastIdentOfPath(modelInfo.name)%>Jacobian()
   {
   if(_AColorOfColumn)
     delete []  _AColorOfColumn;
   }

   <%functionAnalyticJacobians(jacobianMatrixes,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>

   //testmaessig aus der cruntime
   /* Jacobians */


   void <%lastIdentOfPath(modelInfo.name)%>Jacobian::initializeColoredJacobianA()
   {
   <%functionAnalyticJacobians2(jacobianMatrixes, lastIdentOfPath(modelInfo.name),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
   }
   <%\n%>
   >>
end simulationJacobianCppFile;

template simulationStateSelectionCppFile(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
   <<

   <%lastIdentOfPath(modelInfo.name)%>StateSelection::<%lastIdentOfPath(modelInfo.name)%>StateSelection(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects)
       : <%lastIdentOfPath(modelInfo.name)%>Mixed(globalSettings, simObjects)
   {
   }

   <%lastIdentOfPath(modelInfo.name)%>StateSelection::~<%lastIdentOfPath(modelInfo.name)%>StateSelection()
   {
   }

   <%functionDimStateSets(stateSets, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)%>
   <%functionStateSets(stateSets, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
   >>
end simulationStateSelectionCppFile;


template simulationWriteOutputCppFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
   <<


   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::<%lastIdentOfPath(modelInfo.name)%>WriteOutput(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects)
       : <%lastIdentOfPath(modelInfo.name)%>StateSelection(globalSettings, simObjects)
   {



   }

   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::<%lastIdentOfPath(modelInfo.name)%>WriteOutput(<%lastIdentOfPath(modelInfo.name)%>WriteOutput& instance)
       : <%lastIdentOfPath(modelInfo.name)%>StateSelection(instance.getGlobalSettings(), instance.getSimObjects())
   {

   }

   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::~<%lastIdentOfPath(modelInfo.name)%>WriteOutput()
   {

   }

   IHistory* <%lastIdentOfPath(modelInfo.name)%>WriteOutput::getHistory()
   {
     return _writeOutput.get();
   }

   void <%lastIdentOfPath(modelInfo.name)%>WriteOutput::initialize()
   {
      if(getGlobalSettings()->getOutputPointType()!= OPT_NONE)
      {
        _writeOutput = getSimObjects()->LoadWriter(<%numAlgvars(modelInfo)%> + <%numAliasvars(modelInfo)%> + 2*<%numStatevars(modelInfo)%>).lock();
    _writeOutput->init();
        _writeOutput->clear();
      }
   }


   <%writeoutput(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
   >>
end simulationWriteOutputCppFile;
 /*
 map<unsigned int,string> var_ouputs_idx;
      <%outputIndices(modelInfo)%>
      _writeOutput->setOutputs(var_ouputs_idx);
*/


template simulationWriteOutputAlgVarsCppFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(__) then
match modelInfo
case modelInfo as MODELINFO(vars=SIMVARS(__)) then
 let className = lastIdentOfPath(modelInfo.name)
 let algVarsStart = "1"
 let discrAlgVarsStart = intAdd(stringInt(algVarsStart), stringInt(numProtectedRealAlgvars(modelInfo)))
 let intAlgVarsStart = intAdd(stringInt(discrAlgVarsStart), stringInt(numProtectedDiscreteAlgVars(modelInfo)))
 let boolAlgVarsStart = intAdd(stringInt(intAlgVarsStart), stringInt(numProtectedIntAlgvars(modelInfo)))
   <<
       void <%className%>WriteOutput::writeAlgVarsResultNames(vector<string>& names)
       {
        <% if protectedVars(vars.algVars) then
        'names += <%(vars.algVars |> SIMVAR(isProtected=false) =>
        '"<%crefStrForWriteOutput(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>

       }
       void <%className%>WriteOutput::writeDiscreteAlgVarsResultNames(vector<string>& names)
       {
        <% if  protectedVars(vars.discreteAlgVars) then
        'names += <%(vars.discreteAlgVars |> SIMVAR(isProtected=false) =>
        '"<%crefStrForWriteOutput(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>

       }
       void  <%className%>WriteOutput::writeIntAlgVarsResultNames(vector<string>& names)
        {
         <% if  protectedVars(vars.intAlgVars) then
         'names += <%(vars.intAlgVars |> SIMVAR(isProtected=false) =>
           '"<%crefStrForWriteOutput(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }
        void <%className%>WriteOutput::writeBoolAlgVarsResultNames(vector<string>& names)
        {
        <% if  protectedVars(vars.boolAlgVars) then
         'names +=<%(vars.boolAlgVars |> SIMVAR(isProtected=false) =>
           '"<%crefStrForWriteOutput(name)%>"'  ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }
       void <%className%>WriteOutput::writeAlgVarsResultDescription(vector<string>& description)
       {
        <% if  protectedVars(vars.algVars) then
        'description += <%(vars.algVars |> SIMVAR(isProtected=false) =>
        '"<%Util.escapeModelicaStringToCString(comment)%>"' ;separator=",";align=10;alignSeparator=";\n description += " )%>;' %>

       }
       void <%className%>WriteOutput::writeDiscreteAlgVarsResultDescription(vector<string>& description)
       {
        <% if  protectedVars(vars.discreteAlgVars) then
        'description += <%(vars.discreteAlgVars |> SIMVAR(isProtected=false) =>
        '"<%Util.escapeModelicaStringToCString(comment)%>"' ;separator=",";align=10;alignSeparator=";\n description += " )%>;' %>

       }
       void  <%className%>WriteOutput::writeIntAlgVarsResultDescription(vector<string>& description)
        {
         <% if  protectedVars(vars.intAlgVars) then
         'description += <%(vars.intAlgVars |> SIMVAR(isProtected=false) =>
           '"<%Util.escapeModelicaStringToCString(comment)%>"' ;separator=",";align=10;alignSeparator=";\n description += " )%>;' %>
        }
        void <%className%>WriteOutput::writeBoolAlgVarsResultDescription(vector<string>& description)
        {
        <% if  protectedVars(vars.boolAlgVars) then
         'description +=<%(vars.boolAlgVars |> SIMVAR(isProtected=false) =>
           '"<%Util.escapeModelicaStringToCString(comment)%>"'  ;separator=",";align=10;alignSeparator=";\n description += " )%>;' %>
        }
        <%writeOutputVarsWithSplit("writeAlgVarsValues", protectedVars(vars.algVars), stringInt(algVarsStart), '<%className%>WriteOutput', false, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
        <%writeOutputVarsWithSplit("writeDiscreteAlgVarsValues", protectedVars(vars.discreteAlgVars), stringInt(discrAlgVarsStart), '<%className%>WriteOutput', false, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
        <%writeOutputVarsWithSplit("writeIntAlgVarsValues", protectedVars(vars.intAlgVars), stringInt(intAlgVarsStart), '<%className%>WriteOutput', false, simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
        <%writeOutputVarsWithSplit("writeBoolAlgVarsValues", protectedVars(vars.boolAlgVars), stringInt(boolAlgVarsStart), '<%className%>WriteOutput', false, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>

   >>
end simulationWriteOutputAlgVarsCppFile;



template simulationWriteOutputParameterCppFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(__) then
match modelInfo
case modelInfo as MODELINFO(vars=SIMVARS(__)) then
   <<
        void   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeParametertNames(vector<string>& names)
        {
         /*workarround ced*/

         <% if  protectedVars(vars.paramVars) then
          'names += <%(vars.paramVars |> SIMVAR(isProtected=false) =>
          '"<%crefStrForWriteOutput(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>

        }

         void   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeIntParameterNames(vector<string>& names)
        {
         <% if  protectedVars(vars.intParamVars) then
          'names += <%(vars.intParamVars |> SIMVAR(isProtected=false) =>
          '"<%crefStrForWriteOutput(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }
         void   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeBoolParameterNames(vector<string>& names)
        {
         <% if  protectedVars(vars.boolParamVars) then
          'names += <%(vars.boolParamVars |> SIMVAR(isProtected=false) =>
          '"<%crefStrForWriteOutput(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }
        void   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeParameterDescription(vector<string>& names)
        {
         /*workarround ced*/
         <% if protectedVars(vars.paramVars) then
          'names += <%(vars.paramVars |> SIMVAR(isProtected=false) =>
          '"<%Util.escapeModelicaStringToCString(comment)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>

        }

         void   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeIntParameterDescription(vector<string>& names)
        {
         <% if protectedVars(vars.intParamVars) then
          'names += <%(vars.intParamVars |> SIMVAR(isProtected=false) =>
          '"<%Util.escapeModelicaStringToCString(comment)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }

         void   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeBoolParameterDescription(vector<string>& names)
        {
         <% if protectedVars(vars.boolParamVars) then
          'names += <%(vars.boolParamVars |> SIMVAR(isProtected=false) =>
          '"<%Util.escapeModelicaStringToCString(comment)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }
        <%writeoutputparams(modelInfo,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,contextOther,useFlatArrayNotation)%>
   >>
end simulationWriteOutputParameterCppFile;


template simulationWriteOutputAliasVarsCppFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(__) then
match modelInfo
case modelInfo as MODELINFO(vars=SIMVARS(__)) then
 let className = lastIdentOfPath(modelInfo.name)
 let algVarsStart = "1"
 let discrAlgVarsStart = intAdd(stringInt(algVarsStart), stringInt(numProtectedRealAlgvars(modelInfo)))
 let intAlgVarsStart = intAdd(stringInt(discrAlgVarsStart), stringInt(numProtectedDiscreteAlgVars(modelInfo)))
 let boolAlgVarsStart = intAdd(stringInt(intAlgVarsStart), stringInt(numProtectedIntAlgvars(modelInfo)))
 let aliasVarsStart = intAdd(stringInt(boolAlgVarsStart), stringInt(numProtectedBoolAlgvars(modelInfo)))
 let intAliasVarsStart = intAdd(stringInt(aliasVarsStart), stringInt(numProtectedRealAliasvars(modelInfo)))
 let boolAliasVarsStart = intAdd(stringInt(intAliasVarsStart), stringInt(numProtectedIntAliasvars(modelInfo)))
 let stateVarsStart = intAdd(stringInt(boolAliasVarsStart), stringInt(numProtectedBoolAliasvars(modelInfo)))
   <<
        void <%className%>WriteOutput::writeBoolAliasVarsResultNames(vector<string>& names)
        {
          <% if  protectedVars(vars.boolAliasVars) then
          'names += <%(vars.boolAliasVars |> SIMVAR(isProtected=false) =>
            '"<%crefStrForWriteOutput(name)%>"';separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }
        void  <%className%>WriteOutput::writeAliasVarsResultNames(vector<string>& names)
        {
         <% if  protectedVars(vars.aliasVars) then
         'names +=<%(vars.aliasVars |> SIMVAR(isProtected=false) =>
          '"<%crefStrForWriteOutput(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += "  )%>;' %>
        }

        void   <%className%>WriteOutput::writeIntAliasVarsResultNames(vector<string>& names)
        {
        <% if  protectedVars(vars.intAliasVars) then
           'names += <%(vars.intAliasVars |> SIMVAR(isProtected=false) =>
            '"<%crefStrForWriteOutput(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }





        void  <%className%>WriteOutput::writeAliasVarsResultDescription(vector<string>& description)
        {
         <% if  protectedVars(vars.aliasVars) then
         'description +=<%(vars.aliasVars |> SIMVAR(isProtected=false) =>
          '"<%Util.escapeModelicaStringToCString(comment)%>"' ;separator=",";align=10;alignSeparator=";\n description += "  )%>;' %>
        }

       void   <%className%>WriteOutput::writeIntAliasVarsResultDescription(vector<string>& description)
        {
        <% if  protectedVars(vars.intAliasVars) then
           'description += <%(vars.intAliasVars |> SIMVAR(isProtected=false) =>
            '"<%Util.escapeModelicaStringToCString(comment)%>"' ;separator=",";align=10;alignSeparator=";\n description += " )%>;' %>
        }

        void <%className%>WriteOutput::writeBoolAliasVarsResultDescription(vector<string>& description)
        {
          <% if protectedVars(vars.boolAliasVars) then
          'description += <%(vars.boolAliasVars |> SIMVAR(isProtected=false) =>
            '"<%Util.escapeModelicaStringToCString(comment)%>"';separator=",";align=10;alignSeparator=";\n description += " )%>;' %>
        }
        <%writeOutputVarsWithSplit("writeAliasVarsValues", protectedVars(vars.aliasVars), stringInt(aliasVarsStart), '<%className%>WriteOutput', true, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
        <%writeOutputVarsWithSplit("writeIntAliasVarsValues", protectedVars(vars.intAliasVars), stringInt(intAliasVarsStart), '<%className%>WriteOutput', true, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
        <%writeOutputVarsWithSplit("writeBoolAliasVarsValues", protectedVars(vars.boolAliasVars), stringInt(boolAliasVarsStart), '<%className%>WriteOutput', true, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>


   >>
end simulationWriteOutputAliasVarsCppFile;

template simulationMixedSystemCppFile(SimCode simCode , Text updateResidualFunctionsCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then


  let getJacobianForIndexMethods =   (jacobianMatrixes |> (mat, _,name, _,colorList, _, jacIndex) =>
          generateJacobianForIndex         (simCode,mat,colorList,jacIndex, name, &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    ;separator="\n\n";empty)
  let classname = lastIdentOfPath(modelInfo.name)
   let type = getConfigString(MATRIX_FORMAT)
      let getDenseMatrix =  match type
          case ("dense") then
            <<
            switch (index)
            {
                <%getJacobianForIndexMethods%>
                default:
                throw ModelicaSimulationError(MATH_FUNCTION,"Not supported jacobian matrix index");
            }
            >>
          case ("sparse") then
            'throw ModelicaSimulationError(MATH_FUNCTION,"Dense matrix is not activated");'
          else "A matrix type is not supported"
          end match
      let getSparseMatrix =  match type
          case ("dense") then
            'throw ModelicaSimulationError(MATH_FUNCTION,"Sparse matrix is not activated");'
          case ("sparse") then
            <<
            switch (index)
            {
                <%getJacobianForIndexMethods%>
                default:
                throw ModelicaSimulationError(MATH_FUNCTION,"Not supported jacobian matrix index");
            }
            >>
          else "A matrix type is not supported"
          end match

        let getDenseAMatrix =  match type
          case ("dense") then
            <<
                return getAJacobian();
            >>
          case ("sparse") then
            'throw ModelicaSimulationError(MATH_FUNCTION,"Dense matrix is not activated");'
          else "A matrix type is not supported"
          end match
      let getSparseAMatrix =  match type
          case ("dense") then
            'throw ModelicaSimulationError(MATH_FUNCTION,"Sparse matrix is not activated");'
          case ("sparse") then
            <<
                return getAJacobian();
            >>
          else "A matrix type is not supported"
          end match

     let statesetjacobian =
     (stateSets |> set hasindex i1 fromindex 0 => (match set
       case set as SES_STATESET(__) then
       match jacobianMatrix case (_,_,name,_,_,_,_) then
       match type
       case ("dense") then
       <<
       case <%i1%>:
         return get<%name%>Jacobian();
         break;
       >>
       case ("sparse") then
       'throw ModelicaSimulationError(MATH_FUNCTION,"Dense matrix is not activated");'
       else "A matrix type is not supported"
       )
       ;separator="\n")


 let statesetsparsejacobian =
     (stateSets |> set hasindex i1 fromindex 0 => (match set
       case set as SES_STATESET(__) then
       match jacobianMatrix case (_,_,name,_,_,_,_) then
       match type
       case ("dense") then
       'throw ModelicaSimulationError(MATH_FUNCTION,"Sparse matrix is not activated");'
       case ("sparse") then
       <<
       case <%i1%>:
         return get<%name%>Jacobian();
         break;
       >>

       else "A matrix type is not supported"
       )
       ;separator="\n")

   <<
   <%classname%>Mixed::<%classname%>Mixed(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects)
       : <%classname%>Jacobian(globalSettings, simObjects)



   {
   }

   <%classname%>Mixed::<%classname%>Mixed(<%classname%>Mixed& instance)
   : <%classname%>Jacobian(instance)
   {
   }

   <%classname%>Mixed::~<%classname%>Mixed()
   {
   }




   const matrix_t& <%classname%>Mixed::getJacobian( )
   {
        <%getDenseAMatrix%>
   }

   const matrix_t& <%classname%>Mixed::getJacobian(unsigned int index)
   {
      <%getDenseMatrix%>
   }
   const sparsematrix_t& <%classname%>Mixed::getSparseJacobian( )
   {
      <%getSparseAMatrix%>
   }

   const sparsematrix_t& <%classname%>Mixed::getSparseJacobian(unsigned int index)
   {
     <%getSparseMatrix%>
   }

   const matrix_t& <%classname%>Mixed::getStateSetJacobian(unsigned int index)
   {
     switch (index)
     {
       <%statesetjacobian%>
       default:
          throw ModelicaSimulationError(MATH_FUNCTION,"Not supported statset index");
      }
   }
   const sparsematrix_t& <%classname%>Mixed::getStateSetSparseJacobian(unsigned int index)
   {
     switch (index)
     {
       <%statesetsparsejacobian%>
       default:
          throw ModelicaSimulationError(MATH_FUNCTION,"Not supported statset index");
      }
   }
    <%handleSystemEvents(zeroCrossings,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>

   void <%classname%>Mixed::saveAll()
   {
     return <%classname%>::saveAll();
   }


   /*needed for colored jacobians*/

   void <%classname%>Mixed::getAColorOfColumn(int* aSparsePatternColorCols, int size)
   {
    memcpy(aSparsePatternColorCols, _AColorOfColumn, size * sizeof(int));
   }

   int <%classname%>Mixed::getAMaxColors()
   {
    return _AMaxColors;
   }

   string <%classname%>Mixed::getModelName()
   {
    return "<%fileNamePrefix%>";
   }
   <%updateResidualFunctionsCode%>





   >>


end simulationMixedSystemCppFile;


template generateJacobianForIndex(SimCode simCode, list<JacobianColumn> jacobianColumn, list<list<Integer>> colorList,Integer indexJacobian, String matrixName,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,                                Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates Matrixes for Linear Model."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then

let classname =  lastIdentOfPath(modelInfo.name)
match jacobianColumn
case {} then ""
case _ then
  match colorList
  case {} then ""
  case _ then
  <<
    case <%indexJacobian%>:
    {
        return get<%matrixName%>Jacobian();
    }
  >>

/*
  (match indexColumn case "1" then ' _<%matrixName%>jacobian(<%crefWithoutIndexOperator(cref)%>$pDER<%matrixName%>$indexdiff,0) = _<%matrixName%>jac_y(0); //1 <%cref(cref)%>'
           else ' _<%matrixName%>jacobian(<%index0%>,<%crefWithoutIndexOperator(cref)%>$pDER<%matrixName%>$indexdiff) = _<%matrixName%>jac_y(<%crefWithoutIndexOperator(cref)%>$pDER<%matrixName%>$indexdiff);//2 <%cref(cref)%>'

*/
end generateJacobianForIndex;

template functionDimStateSets(list<StateSet> stateSets,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
  "Generates functions in simulation file to initialize the stateset data."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
   let classname =  lastIdentOfPath(modelInfo.name)
   match stateSets
  case {} then
    <<
    int <%classname%>StateSelection::getDimStateSets() const
    {
      return 0;
    }

    int <%classname%>StateSelection::getDimStates(unsigned int index) const
    {
      return 0;
    }

    int <%classname%>StateSelection::getDimCanditates(unsigned int index) const
    {
      return 0;
    }

    int <%classname%>StateSelection::getDimDummyStates(unsigned int index) const
    {
      return 0;
    }
    >>
  else
    <<
    int <%classname%>StateSelection::getDimStateSets() const
    {
      return <%listLength(stateSets)%>;
    }

    int <%classname%>StateSelection::getDimStates(unsigned int index) const
    {
       switch (index)
       {
         <%(stateSets |> set hasindex i1 fromindex 0 => (match set
         case set as SES_STATESET(__) then
         <<
          case <%i1%>:
             return <%nStates%>;

       >>
       )
       ;separator="\n")
       %>
       default:
       throw ModelicaSimulationError(MATH_FUNCTION,"Not supported statset index");
      }

    }

    int <%classname%>StateSelection::getDimCanditates(unsigned int index) const
    {
       switch (index)
       {
         <%(stateSets |> set hasindex i1 fromindex 0 => (match set
         case set as SES_STATESET(__) then
         <<
          case <%i1%>:
             return  <%nCandidates%>;
         >>
       )
       ;separator="\n")
       %>
       default:
      throw ModelicaSimulationError(MATH_FUNCTION,"Not supported statset index");
      }

    }

    int <%classname%>StateSelection::getDimDummyStates(unsigned int index) const
    {
      switch (index)
      {
        <%(stateSets |> set hasindex i1 fromindex 0 => (match set
        case set as SES_STATESET(__) then
        <<
          case <%i1%>:
            return <%nCandidates%>-<%nStates%>;

        >>
       )
       ;separator="\n")
       %>
      default:
      throw ModelicaSimulationError(MATH_FUNCTION,"Not supported statset index");
      }

    }
  >>
 end functionDimStateSets;


template createAssignArray(DAE.ComponentRef sourceOrTargetArrayCref, String sourceArrayName, String targetArrayName, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Boolean useFlatArrayNotationSource, Boolean useFlatArrayNotationTarget, String dimsArrayName)
::=
  match cref2simvar(sourceOrTargetArrayCref, simCode)
    case v as SIMVAR(numArrayElement=num) then
        '<%targetArrayName%>.assign(<%sourceArrayName%>);'
end createAssignArray;

template functionStateSets(list<StateSet> stateSets, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  "Generates functions in simulation file to initialize the stateset data."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  let getAMatrix1 = (stateSets |> set hasindex i1 fromindex 0 => (match set
           case set as SES_STATESET(__) then
           let arrayname1 = arraycref(crA, useFlatArrayNotation)
           match nStates  case 1 then
             'case <%i1%>:
               <%createAssignArray(crA, arrayname1, "A", simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, useFlatArrayNotation, false, "dims")%>
               return true;
            '
            else ""
         ) ;separator="\n")

  let getAMatrix2 = (stateSets |> set hasindex i1 fromindex 0 => (match set
           case set as SES_STATESET(__) then
           let arrayname1 = arraycref(crA, useFlatArrayNotation)
           match nStates  case 1 then "" else
             'case <%i1%>:
               <%createAssignArray(crA, arrayname1, "A", simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, useFlatArrayNotation, false, "dims")%>
               return true;
            '

         ) ;separator="\n")

   let setAMatrix1 = (stateSets |> set hasindex i1 fromindex 0 => (match set
           case set as SES_STATESET(__) then
           let arrayname1 = arraycref(crA, useFlatArrayNotation)
           match nStates  case 1 then
             'case <%i1%>:
               <%createAssignArray(crA, "A", arrayname1, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, false, useFlatArrayNotation, "dims")%>
               break;
            '
            else ""
         ) ;separator="\n")

  let setAMatrix2 = (stateSets |> set hasindex i1 fromindex 0 => (match set
           case set as SES_STATESET(__) then
           let arrayname1 = arraycref(crA, useFlatArrayNotation)
           match nStates  case 1 then "" else
             'case <%i1%>:
               <%createAssignArray(crA, "A", arrayname1, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, false, useFlatArrayNotation, "dims")%>
               break;
            '

         ) ;separator="\n")



  let classname =  lastIdentOfPath(modelInfo.name)
  match stateSets
  case {} then
     <<
     void <%classname%>StateSelection::getStates(unsigned int index, double* z)
     {
     }

     void <%classname%>StateSelection::setStates(unsigned int index, const double* z)
     {
     }

     void <%classname%>StateSelection::getStateCanditates(unsigned int index, double* z)
     {

     }

     bool <%classname%>StateSelection::getAMatrix(unsigned int index, DynArrayDim2<int> & A)
     {
       return false;
     }

     bool <%classname%>StateSelection::getAMatrix(unsigned int index, DynArrayDim1<int> & A)
     {
       return false;
     }

     void <%classname%>StateSelection::setAMatrix(unsigned int index, DynArrayDim2<int>& A)
     {
     }

     void <%classname%>StateSelection::setAMatrix(unsigned int index, DynArrayDim1<int>& A)
     {
     }

     void <%classname%>StateSelection::initialize()
     {
     }
     >>
 else
    let &varDeclsCref = buffer "" /*BUFD*/
    <<
    void <%classname%>StateSelection::getStates(unsigned int index,double* z)
    {
      switch (index)
      {
        <%(stateSets |> set hasindex i1 fromindex 0 => (match set
        case set as SES_STATESET(__) then
        <<
          case <%i1%>:
            <%(states |> s hasindex i2 fromindex 0 => 'z[<%i2%>]=<%cref1(s, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>;' ;separator="\n")%>
            break;
        >>
       )
       ;separator="\n")
       %>
         default:
         throw ModelicaSimulationError(MATH_FUNCTION,"Not supported statset index");
      }
    }

    void <%classname%>StateSelection::setStates(unsigned int index,const double* z)
    {
      switch (index)
      {
        <%(stateSets |> set hasindex i1 fromindex 0 => (match set
        case set as SES_STATESET(__) then
        <<
          case <%i1%>:
            <%(states |> s hasindex i2 fromindex 0 => '<%cref1(s, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%> = z[<%i2%>];' ;separator="\n")%>
            break;
        >>
        )
        ;separator="\n")
        %>
        default:
        throw ModelicaSimulationError(MATH_FUNCTION,"Not supported statset index");
        }

       }
       void  <%classname%>StateSelection::getStateCanditates(unsigned int index,double* z)
       {

        switch (index)
        {
          <%(stateSets |> set hasindex i1 fromindex 0 => (match set
           case set as SES_STATESET(__) then
          <<
            case <%i1%>:
             <%(statescandidates |> cstate hasindex i2 fromindex 0 => 'z[<%i2%>]=<%cref1(cstate, simCode ,&extraFuncs ,&extraFuncsDecl, extraFuncsNamespace, contextOther, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>;' ;separator="\n")%>
             break;
         >>
        )
        ;separator="\n")
        %>
        default:
        throw ModelicaSimulationError(MATH_FUNCTION,"Not supported statset index");
        }

       }


       bool  <%classname%>StateSelection::getAMatrix(unsigned int index,DynArrayDim2<int> & A)
        {
        <%if useFlatArrayNotation then "std::vector<size_t> dims;" %>
        <%match getAMatrix2 case "" then 'return false;' else
        <<
         switch (index)
          {
            <%getAMatrix2%>
           default:
          throw ModelicaSimulationError(MATH_FUNCTION,"Not supported statset index");
          }
       >>
       %>
       }
       bool  <%classname%>StateSelection::getAMatrix(unsigned int index,DynArrayDim1<int> & A)
        {
        <%if useFlatArrayNotation then "std::vector<size_t> dims;" %>
       <%match getAMatrix1 case "" then 'return false;' else
        <<
        switch (index)
        {
           <%getAMatrix1%>
            default:
          throw ModelicaSimulationError(MATH_FUNCTION,"Not supported statset index");
          }
       >>
       %>
       }

       void  <%classname%>StateSelection::setAMatrix(unsigned int index,DynArrayDim2<int> & A)
        {
        <%if useFlatArrayNotation then "std::vector<size_t> dims;" %>
        <%match setAMatrix2 case "" then '' else
        <<
         switch (index)
          {
            <%setAMatrix2%>
           default:
          throw ModelicaSimulationError(MATH_FUNCTION,"Not supported statset index");
        }
       >>
       %>
       }
       void  <%classname%>StateSelection::setAMatrix(unsigned int index,DynArrayDim1<int> & A)
        {
        <%if useFlatArrayNotation then "std::vector<size_t> dims;" %>
       <%match setAMatrix1 case "" then '' else
        <<
        switch (index)
        {
          <%setAMatrix1%>
          default:
          throw ModelicaSimulationError(MATH_FUNCTION,"Not supported statset index");
        }
        >>
       %>
    }
    >>
end functionStateSets;




template simulationMainRunScript(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, String preRunCommandLinux, String preRunCommandWindows, String execCommandLinux)
 "Generates code for header file for simulation target."
::=
  match simCode
   case SIMCODE(modelInfo = MODELINFO(__), makefileParams = MAKEFILE_PARAMS(__), simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
    let start     = settings.startTime
    let end       = settings.stopTime
    let stepsize  = settings.stepSize
    let intervals = settings.numberOfIntervals
    let tol       = settings.tolerance
    let solver    = match simCode case SIMCODE(daeModeData=NONE()) then settings.method else 'ida' //for dae mode only ida is supported
    let moLib     =  makefileParams.compileDir
    let home      = makefileParams.omhome
  let outputformat = settings.outputFormat
    let execParameters = '-S <%start%> -E <%end%> -H <%stepsize%> -G <%intervals%> -P <%outputformat%> -T <%tol%> -I <%solver%> -R <%simulationLibDir(simulationCodeTarget(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%> -M <%moLib%> -r <%simulationResults(getRunningTestsuite(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>'
    let outputParameter = if (stringEq(settings.outputFormat, "empty")) then "-O none" else ""
    let fileNamePrefixx = fileNamePrefix

    let libFolder =simulationLibDir(simulationCodeTarget(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
    let libPaths = makefileParams.libPaths |> path => path; separator=";"

    match makefileParams.platform
      case  "linux32"
      case  "linux64" then
        <<
        #!/bin/sh
        <%preRunCommandLinux%>
        <%execCommandLinux%> ./<%fileNamePrefixx%> <%execParameters%> <%outputParameter%> $*
        >>
      case  "win32"
      case  "win64" then
        <<
        @echo off
        <%preRunCommandWindows%>
        REM ::export PATH=<%libFolder%>:$PATH REPLACE C: with /C/
        SET PATH=<%home%>/bin;<%libFolder%>;<%libPaths%>;%PATH%
        <%moLib%>/<%fileNamePrefixx%>.exe <%execParameters%> <%outputParameter%>
        >>
    end match
  end match
end simulationMainRunScript;


template simulationLibDir(String target, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates code for header file for simulation target."
::=
  match getGeneralTarget(target)
    case "debugrt"
    case "msvc" then
      match simCode
        case SIMCODE(makefileParams=MAKEFILE_PARAMS(__)) then
          '<%makefileParams.omhome%>/lib/<%getTriple()%>/omc/cpp/msvc'
      end match
    else
      match simCode
        case SIMCODE(makefileParams=MAKEFILE_PARAMS(__)) then
          '<%makefileParams.omhome%>/lib/<%getTriple()%>/omc/cpp/'
      end match
  end match
end simulationLibDir;


template simulationResults(Boolean test, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates code for header file for simulation target."
::=
  match simCode
    case SIMCODE(modelInfo=MODELINFO(__),makefileParams=MAKEFILE_PARAMS(__),simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
      let results = if test then ""  else '<%makefileParams.compileDir%>/'
      <<
      <%results%><%fileNamePrefix%>_res.<%settings.outputFormat%>
      >>
  end match
end simulationResults;


template simulationMainRunScriptSuffix(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE( makefileParams=params as MAKEFILE_PARAMS(__)) then
  (match params.platform
  case  "win32"
  case  "win64" then
  ".bat"
  else
  ".sh")
end simulationMainRunScriptSuffix;

template simulationMainFile(String target, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,
                            String additionalIncludes, String additionalPreRunCommands, String additionalPostRunCommands,
                            String numRealVars, String numIntVars, String numBoolVars, String numStringVars, String numPreVars)
 "Generates code for header file for simulation target."
::=
match target

case "debugrt" then
match simCode
case SIMCODE(modelInfo = MODELINFO(__), makefileParams = MAKEFILE_PARAMS(__), simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
let modelname = identOfPath(modelInfo.name)
let start     = settings.startTime
let end       = settings.stopTime
let stepsize  = settings.stepSize
let intervals = settings.numberOfIntervals
let tol       = settings.tolerance
let solver    = settings.method
let moLib     = makefileParams.compileDir
let home      = makefileParams.omhome
let &includeMeasure = buffer "" /*BUFD*/
<<
//Includes

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <stdio.h>
#include <string>

#include <Core/DataExchange/SimDouble.h>
#include <Core/DataExchange/SimBoolean.h>
#include <Core/SimController/ISimController.h>
#include <Core/System/FactoryExport.h>

#define PATH string

#include <tchar.h>
#include <fstream>

int _tmain(int argc, const _TCHAR* argv[])
{

  /*
  =============================================================================================================
  ==                 Initialization of SimCore
  =============================================================================================================
  */




    //nur testweise
    std::map<std::string, std::string> opts;
      opts["-s"] = "<%start%>";
      opts["-e"] = "<%end%>";
      opts["-f"] = "<%stepsize%>";
      opts["-v"] = "<%intervals%>";
      opts["-y"] = "<%tol%>";
      opts["-i"] = "<%solver%>";
      opts["-r"] = "<%simulationLibDir(simulationCodeTarget(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>";
      opts["-m"] = "<%moLib%>";
      opts["-R"] = "<%simulationResults(getRunningTestsuite(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>";





  shared_ptr<OMCFactory>  _factory =  shared_ptr<OMCFactory>(new OMCFactory());

  //SimController to start simulation

  std::pair<shared_ptr<ISimController>, SimSettings> simulation = _factory->createSimulation(argc, argv, opts);
  //Logger::initialize(simulation.second.logSettings);

  //create Modelica system
  shared_ptr<ISimObjects> simObjects= simulation.first->getSimObjects();
  weak_ptr<ISimData> simData = simObjects->LoadSimData("<%lastIdentOfPath(modelInfo.name)%>");
  weak_ptr<ISimVars> simVars = simObjects->LoadSimVars("<%lastIdentOfPath(modelInfo.name)%>",<%numRealVars%>,<%numIntVars%>,<%numBoolVars%>,<%numStringVars%>,<%numPreVars%>,<%numStatevars(modelInfo)%>,<%numStateVarIndex(modelInfo)%>);
  weak_ptr<IMixedSystem> system = simulation.first->LoadSystem("OMCpp<%fileNamePrefix%><%makefileParams.dllext%>  ","<%lastIdentOfPath(modelInfo.name)%>");


  // Declare Input specify initial_values if needed!!!
  <%defineInputVars(simCode)%>

  // Declare Output
  <%defineOutputVars(simCode)%>

  LogSettings logsetting;
    SimSettings settings = {"RTEuler","","newton",        0.0,      100.0,  0.004,      0.0025,      10.0,         0.0001, "<%lastIdentOfPath(modelInfo.name)%>",0,OPT_NONE, logsetting};
  //                       Solver,          nonlinearsolver starttime endtime stepsize   lower limit upper limit  tolerance


  try
  {
    simulation.first->StartVxWorks(settings, "<%lastIdentOfPath(modelInfo.name)%>");
  }
  catch(ModelicaSimulationError& ex)
  {
    throw std::runtime_error("error initialize");
  }
    std::fstream f;
    f.open("output_rt.csv", ios::out);


  for( int i = 0; i < 1000; i++)
  {
    try
    {
      simulation.first->calcOneStep();
      <%streamOutputVars(simCode)%>
    }
    catch(ModelicaSimulationError& ex)
    {
      f.close();
      throw std::runtime_error("error inside step");
    }
  }
  f.close();
  return 0;
}



>>
end match
case "vxworks69" then
match simCode
case SIMCODE(modelInfo = MODELINFO(__), makefileParams = MAKEFILE_PARAMS(__), simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
let modelname = identOfPath(modelInfo.name)
let start     = settings.startTime
let end       = settings.stopTime
let stepsize  = settings.stepSize
let intervals = settings.numberOfIntervals
let tol       = settings.tolerance
let solver    = settings.method
let moLib     = makefileParams.compileDir
let home      = makefileParams.omhome
let &includeMeasure = buffer "" /*BUFD*/

<<
//Includes

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <stdio.h>
#include <string>

#include <Core/DataExchange/SimDouble.h>
#include <Core/DataExchange/SimBoolean.h>
#include <Core/SimController/ISimController.h>
#include <Core/System/FactoryExport.h>

#define PATH string

#include <wvLib.h>

#include <util/bundle.h>
#include <util/vxwHelper.h>
#include <util/wchar16.h>

#include <mlpiApiLib.h>
#include <mlpiSystemLib.h>
#include <mlpiTaskLib.h>
#include <mlpiLogicLib.h>
#include <mlpiParameterLib.h>



extern "C"  ISimController* createSimController(PATH library_path, PATH modelicasystem_path);

// functions implemented in this file
extern "C"  int initSimulation(ISimController* &controller, ISimData* &data, double cycletime);
extern "C"  int motionTriggered(ISimController* &controller, ISimData* &data);
extern "C"  void runSimulation(void);
extern "C"  int getMotionCycle(double &cycletime);

// Structs
<%mlpiStructs(simCode)%>

extern "C"  int getMotionCycle(double &cycletime)
{
  MLPIHANDLE connection = MLPI_INVALIDHANDLE;
  MLPIRESULT result;
  ULONG cycletime_us = 0;

   result = mlpiApiConnect(MLPI_LOCALHOST, &connection); // replace localhost with control IP to connect to another control
  if (MLPI_FAILED(result))
  {
    printf("\nERROR: failed to connect to MLPI. ErrorCode: 0x%08x", (unsigned) result);
    return result;
  }

  result = mlpiParameterReadDataUlong(connection, 0, MLPI_SIDN_C(400), &cycletime_us);
  if (MLPI_FAILED(result))
  {
    printf("\nERROR: failed to connect to MLPI. ErrorCode: 0x%08x", (unsigned) result);
    return result;
  }

  // Convert mu_s to s
  cycletime = (double)cycletime_us/(1e6);

  result = mlpiApiDisconnect(&connection);
  {
    return result;
  }
  return 0;
}

extern "C"  void debugSimulation(void)
{
  timespec delay;
  delay.tv_sec =  0;
  delay.tv_nsec = 10000000;
  ISimController* simController;
  ISimData* simData;
  double cycletime;
  getMotionCycle(cycletime);

  initSimulation(simController, simData, 0.004);
  while(true)
  {
    try
    {
      nanosleep( &delay ,NULL);
      wvEvent(1,NULL,0);
      simController->calcOneStep();
      wvEvent(2,NULL,0);
    }
    catch(ModelicaSimulationError& ex)
    {
      break;
    }
  }
  delete simController;

}

extern "C"  void runSimulation(void)
{
  timespec delay;
  delay.tv_sec =  1;
  delay.tv_nsec = 0;
  nanosleep( &delay ,NULL);
  // Enable Telnet and Floatingpoint Unit
  enableTelnetPrintf();
  enableFpuSupport();

  ISimController* simController;
  ISimData* simData;

  double cycletime;
  getMotionCycle(cycletime);

  initSimulation(simController, simData, cycletime);
  motionTriggered(simController, simData);

  delete simController;
}

extern "C"  void spawnTask(void)
{
  taskSpawn("<%lastIdentOfPath(modelInfo.name)%>",    // name of task
            200,                                      // priority of task
            VX_FP_TASK,                               // options (executes with the floating-point coprocessor)
            0x200000,                                 // stacksize
            (FUNCPTR)& runSimulation,                 // entry point (function)
            0,                                        // arguments 1
            0,                                        // arguments 2
            0,                                        // arguments 3
            0,                                        // arguments 4
            0,                                        // arguments 5
            0,                                        // arguments 6
            0,                                        // arguments 7
            0,                                        // arguments 8
            0,                                        // arguments 9
            0);                                       // arguments 10
}


extern "C"  int initSimulation(ISimController* &controller, ISimData* &data, double cycletime)
{
  MLPIHANDLE connection = MLPI_INVALIDHANDLE;
  MLPIRESULT result;

  // connect to API
  result = mlpiApiConnect(MLPI_LOCALHOST, &connection); // replace localhost with control IP to connect to another control
  if (MLPI_FAILED(result))
  {
    printf("\nERROR: failed to connect to MLPI. ErrorCode: 0x%08x", (unsigned) result);
    return result;
  }


  /*
  =============================================================================================================
  ==                 Initialization of SimCore
  =============================================================================================================
  */
  wvEvent(0,NULL,0);
  printf("runSimulation started");

  PATH libraries_path = "";
  PATH modelicaSystem_path = "";
  shared_ptr<VxWorksFactory> factory = shared_ptr<VxWorksFactory>(new VxWorksFactory(libraries_path, modelicaSystem_path));
  ISimController* sim_controller = createSimController(libraries_path, modelicaSystem_path);
  shared_ptr<ISimObjects> simObjects= sim_controller->getSimObjects();
  weak_ptr<ISimData> simData = simObjects->LoadSimData("<%lastIdentOfPath(modelInfo.name)%>");
  weak_ptr<ISimVars> simVars = simObjects->LoadSimVars("<%lastIdentOfPath(modelInfo.name)%>",<%numRealVars%>,<%numIntVars%>,<%numBoolVars%>,<%numStringVars%>,<%numPreVars%>,<%numStatevars(modelInfo)%>,<%numStateVarIndex(modelInfo)%>);
  weak_ptr<IMixedSystem> system = sim_controller->LoadSystem("<%lastIdentOfPath(modelInfo.name)%>","<%lastIdentOfPath(modelInfo.name)%>");
  shared_ptr<ISimData> simData_shared = simData.lock();

  // Declare Input specify initial_values if needed!!!
  <%defineInputVars(simCode)%>

  // Declare Output
  <%defineOutputVars(simCode)%>

  LogSettings logsetting;
    SimSettings settings = {"RTEuler","","newton",        0.0,      100.0,  cycletime,      0.0025,      10.0,         0.0001, "<%lastIdentOfPath(modelInfo.name)%>",0,OPT_NONE, logsetting};
  //                       Solver,          nonlinearsolver starttime endtime stepsize   lower limit upper limit  tolerance
  try
  {
    sim_controller->StartVxWorks(settings, "<%lastIdentOfPath(modelInfo.name)%>");
  }
  catch(ModelicaSimulationError& ex)
  {
    string arg1 = string("Simulation failed for ") + settings.outputfile_name;
    string arg2 = ex.what();//ex.what();
    SIMULATION_ERROR arg3 = ex.getErrorID();
    std::string error = add_error_info(arg1,arg2,arg3);
    int lengthOfString = error.length();
    lengthOfString = (int) (lengthOfString / 60 ) + 1;



    for (int i = 0 ; i < lengthOfString ; i++ )
    {
      result = mlpiSystemSetDiagnosis(connection, MLPI_DIAGNOSIS_ERROR_FATAL, 1, A2W16( error.substr(0 + i * 60 ,60 + i * 60).c_str()) );
    }
    return -1;
  }

  printf("StartVxWorks finished");
  wvEvent(1,NULL,0);
  data = simData_shared.get();
  controller = sim_controller;
  return 0;
}

extern "C" int motionTriggered(ISimController* &controller, ISimData* &data)
{
  MLPIHANDLE connection = MLPI_INVALIDHANDLE;

  MLPIRESULT result;

  // connect to API
  result = mlpiApiConnect(MLPI_LOCALHOST, &connection); // replace localhost with control IP to connect to another control
  if (MLPI_FAILED(result))
  {
    printf("\nERROR: failed to connect to MLPI. ErrorCode: 0x%08x", (unsigned) result);
    return result;
  }


  //WCHAR16* application = L"Application";
  //MlpiApplicationState state = MLPI_STATE_NONE;
  //result = mlpiLogicGetStateOfApplication(connection, application, &state);

  // Set Priority of Task
  result = mlpiTaskSetCurrentPriority(connection,  MLPI_PRIORITY_HIGH_MAX);
  if (MLPI_FAILED(result))
  {
    printf("\ncall of MLPI function failed with 0x%08x!", (unsigned)result);
    return result;
  }

  MlpiSystemMode mode;
  // run simulation
  while(true)
  {
   // Wait for motion interrupt
    result = mlpiTaskWaitForEvent(connection, MLPI_TASKEVENT_MOTION_CYCLE, MLPI_INFINITE);

    //MLPIRESULT result = mlpiLogicGetStateOfApplication(connection, application, &state);

    if (MLPI_FAILED(result))
    {
      printf("\ncall of MLPI function failed with 0x%08x!", (unsigned)result);
      return result;
    }
    // Get Current Mode of PLC
    result = mlpiSystemGetCurrentMode(connection, &mode);
    if (MLPI_FAILED(result))
    {
      printf("\ncall of MLPI function failed with 0x%08x!", (unsigned)result);
      return result;
    }
    //if(state == MLPI_STATE_STOP)
    //{
    //  break;
    //}

    //if(mode == MLPI_SYSTEMMODE_BB) //
    //{
      //Write input
      /* do something with the inputs!*/
      /*
      <%setInputVars(simCode)%>
      */
      try
      {
        controller->calcOneStep();
      }
      catch(ModelicaSimulationError& ex)
      {
        string arg1 = string("Simulation failed for ") + "<%lastIdentOfPath(modelInfo.name)%>";
        string arg2 = ex.what();//ex.what();
        SIMULATION_ERROR arg3 = ex.getErrorID();
        std::string error = add_error_info(arg1,arg2,arg3);

        int lengthOfString = error.length();
        lengthOfString = (int) (lengthOfString / 60 ) + 1;

        for (int i = 0 ; i < lengthOfString ; i++ )
        {
          result = mlpiSystemSetDiagnosis(connection, MLPI_DIAGNOSIS_ERROR_FATAL, 1, A2W16( error.substr(0 + i * 60 ,60 + i * 60).c_str()) );
        }
        return -1;
      }
      //Write output
      <%getOutputVars(simCode)%>
    //}
  }

  result = mlpiApiDisconnect(&connection);
  {
    return result;
  }

  return 0;
}

extern "C" void <%modelname%>__Main(<%modelname%>_Main_struct* p)
{

  if (p->instance->controller != NULL)
  {

    // Eingangswerte aus IndraWorks FB lesen

    <%setMainFBInputVars(simCode)%>


    // Berechnung eines Controllersteps

    try
    {
      p->instance->controller->calcOneStep();
    }
    catch(ModelicaSimulationError& ex)
    {
      MLPIHANDLE connection;
      MLPIRESULT result = mlpiApiConnect(MLPI_LOCALHOST, &connection); // replace localhost with control IP to connect to another control
      if (MLPI_FAILED(result))
      {
        printf("\nERROR: failed to connect to MLPI. ErrorCode: 0x%08x", (unsigned) result);
      }

      string arg1 = string("Simulation failed for ") + "<%lastIdentOfPath(modelInfo.name)%>";
      string arg2 = ex.what();//ex.what();
      SIMULATION_ERROR arg3 = ex.getErrorID();
      std::string error = add_error_info(arg1,arg2,arg3);

      int lengthOfString = error.length();
      lengthOfString = (int) (lengthOfString / 60 ) + 1;

      for (int i = 0 ; i < lengthOfString ; i++ )
      {
        MLPIRESULT result = mlpiSystemSetDiagnosis(connection, MLPI_DIAGNOSIS_ERROR_FATAL, 1, A2W16( error.substr(0 + i * 60 ,60 + i * 60).c_str()) );
      }
      result = mlpiApiDisconnect(&connection);
      p->instance->bErrorOccured = TRUE;
    }

    <%setMainFBOutputVars(simCode)%>

  }

}

extern "C" void <%modelname%>__FB_Init(<%modelname%>_FB_Init_struct* p)
{
  p->instance->bErrorOccured = FALSE;
  ISimController* simController;
  ISimData* simData;

  //double cycletime = p->instance->cycletime;
  double cycletime;
  getMotionCycle(cycletime);
  int result = initSimulation(simController, simData, cycletime);
  if (result < 0)
  {
    p->instance->bErrorOccured = TRUE;
  }

  p->instance->simdata = simData;
  p->instance->controller = simController;
  p->instance->bAlreadyInitialized = TRUE;
  p->FB_Init = TRUE;
}

extern "C" void <%modelname%>__FB_Reinit(<%modelname%>_FB_Reinit_struct* p)
{
}

extern "C" void <%modelname%>__FB_Exit(<%modelname%>_FB_Exit_struct* p)
{
  if (p->instance->controller)
  {
    delete p->instance->controller;
  }
}


BUNDLE_INFO_BEGIN(com_boschrexroth_<%modelname%>)
BUNDLE_INFO_NAME (L"LoadLibraries_Bundle")
BUNDLE_INFO_VENDOR (L"Bosch Rexroth AG")
BUNDLE_INFO_DESCRIPTION (L"Load Libraries of SimCore Bundle")
BUNDLE_INFO_VERSION (1,0,0,0,L"Release 20140114")
BUNDLE_INFO_END(com_boschrexroth_<%modelname%>)

BUNDLE_EXPORT int com_boschrexroth_<%modelname%>_create(int param1, int param2, int param3)
{

  MLPIHANDLE connection = MLPI_INVALIDHANDLE;

  // connect to API
  MLPIRESULT resultconnect = mlpiApiConnect(MLPI_LOCALHOST, &connection); // replace localhost with control IP to connect to another control
  if (MLPI_FAILED(resultconnect))
  {
    printf("\nERROR: failed to connect to MLPI. ErrorCode: 0x%08x", (unsigned) resultconnect);
    return resultconnect;
  }

  WCHAR16 name[MLPI_APPLICATION_MAX_LENGTH_OF_POU_NAME] = L"<%modelname%>__Main";
  MLPIPOUFNCPTR function = (MLPIPOUFNCPTR) <%modelname%>__Main;
  MLPIRESULT result = mlpiLogicPouExtensionRegister(connection, name, function);
  if(MLPI_SUCCEEDED(result))
  {
    wcscpy16(name, L"<%modelname%>__FB_Init");
    function = (MLPIPOUFNCPTR) <%modelname%>__FB_Init;
    result = mlpiLogicPouExtensionRegister(connection, name, function);
  }
  if(MLPI_SUCCEEDED(result))
  {
    wcscpy16(name, L"<%modelname%>__FB_Reinit");
    function = (MLPIPOUFNCPTR) <%modelname%>__FB_Reinit;
    result = mlpiLogicPouExtensionRegister(connection, name, function);
  }
  if(MLPI_SUCCEEDED(result))
  {
    wcscpy16(name, L"<%modelname%>__FB_Exit");
    function = (MLPIPOUFNCPTR) <%modelname%>__FB_Exit;
    result = mlpiLogicPouExtensionRegister(connection, name, function);
  }
mlpiApiDisconnect(&connection);

printf("\n###################################################################");
printf("\n## onCreate #######################################################");
printf("\n###################################################################");
return 0;
}

BUNDLE_EXPORT int com_boschrexroth_<%modelname%>_start(int param1, int param2, int param3)
{
//spawnTask();
printf("\n###################################################################");
printf("\n## onStart ########################################################");
printf("\n###################################################################");
return 0;
}

BUNDLE_EXPORT int com_boschrexroth_<%modelname%>_stop(int param1, int param2, int param3)
{
printf("\n###################################################################");
printf("\n## onStop #########################################################");
printf("\n###################################################################");
return 0;
}

BUNDLE_EXPORT int com_boschrexroth_<%modelname%>_destroy(int param1, int param2, int param3)
{
printf("\n###################################################################");
printf("\n## onDestroy ######################################################");
printf("\n###################################################################");
return 0;
}
>>
end match
else
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
  let start     = settings.startTime
  let end       = settings.stopTime
  let stepsize  = settings.stepSize
  let intervals = settings.numberOfIntervals
  let tol       = settings.tolerance
  let solver    = settings.method
  let moLib     = makefileParams.compileDir
  let home      = makefileParams.omhome
  let &includeMeasure = buffer "" /*BUFD*/
  let outputtype = settings.outputFormat
  <<
  #include <Core/ModelicaDefine.h>
  #include <Core/Modelica.h>
  #include <Core/SimController/ISimController.h>
  #include <Core/System/FactoryExport.h>
  #include <Core/Utils/extension/logger.hpp>

  <%
  match(getConfigString(PROFILING_LEVEL))
     case("none") then ''
     case("all_perf") then
       <<
       #ifdef USE_SCOREP
         #include <Core/Utils/extension/measure_time_scorep.hpp>
       #else
         #include <Core/Utils/extension/measure_time_papi.hpp>
       #endif
       >>
     case("all_stat") then
       <<
       #ifdef USE_SCOREP
         #include <Core/Utils/extension/measure_time_scorep.hpp>
       #else
         #include <Core/Utils/extension/measure_time_statistic.hpp>
       #endif
       >>
     else
       <<
       #ifdef USE_SCOREP
         #include <Core/Utils/extension/measure_time_scorep.hpp>
       #else
         #include <Core/Utils/extension/measure_time_rdtsc.hpp>
       #endif
       >>
  end match
  %>
  <%additionalIncludes%>
  #ifdef RUNTIME_STATIC_LINKING
    #include "OMCpp<%fileNamePrefix%>CalcHelperMain.cpp"
    #include <SimCoreFactory/OMCFactory/StaticOMCFactory.h>
  #endif

  #ifdef USE_BOOST_THREAD
    #include <boost/thread.hpp>
    static long unsigned int getThreadNumber()
    {
       boost::hash<std::string> string_hash;
       return (long unsigned int)string_hash(boost::lexical_cast<std::string>(boost::this_thread::get_id()));
    }
  #else
    static long unsigned int getThreadNumber()
    {
       return 0;
    }
  #endif

  #if defined(_MSC_VER) || defined(__MINGW32__)
  #include <tchar.h>
  int _tmain(int argc, const _TCHAR* argv[])
  #else
  int main(int argc, const char* argv[])
  #endif
  {
      // default program options
      std::map<std::string, std::string> opts;
      opts["-S"] = "<%start%>";
      opts["-E"] = "<%end%>";
      opts["-H"] = "<%stepsize%>";
      opts["-G"] = "<%intervals%>";
      opts["-T"] = "<%tol%>";
      opts["-I"] = "<%solver%>";
      opts["-P"] = "<%outputtype%>";
      opts["-R"] = "<%simulationLibDir(simulationCodeTarget(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>";
      opts["-M"] = "<%moLib%>";
      opts["-F"] = "<%simulationResults(getRunningTestsuite(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>";
      opts["--solverThreads"] = "<%if(intGt(getConfigInt(NUM_PROC), 0)) then getConfigInt(NUM_PROC) else 1%>";
      <%if (stringEq(settings.outputFormat, "empty")) then 'opts["-O"] = "none";' else ""%>
      <%
      match(getConfigString(PROFILING_LEVEL))
          case("none") then '//no profiling used'
          case("all_perf") then
           <<
           #ifdef USE_SCOREP
             MeasureTimeScoreP::initialize();
           #else
             MeasureTimePAPI::initialize(getThreadNumber);
           #endif
           >>
          case("all_stat") then
          <<
           #ifdef USE_SCOREP
             MeasureTimeScoreP::initialize();
           #else
             MeasureTimeStatistic::initialize();
           #endif
          >>
          else
           <<
           #ifdef USE_SCOREP
             MeasureTimeScoreP::initialize();
           #else
             MeasureTimeRDTSC::initialize();
           #endif
           >>
      end match
      %>
      try
      {
            Logger::initialize();
            Logger::setEnabled(true);
            <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
                <<
                std::vector<MeasureTimeData*> *measureTimeArraySimulation = new std::vector<MeasureTimeData*>(size_t(2), NULL); //0 all, 1 setup
                (*measureTimeArraySimulation)[0] = new MeasureTimeData("all");
                (*measureTimeArraySimulation)[1] = new MeasureTimeData("setup");
                MeasureTimeValues *measuredSimStartValues, *measuredSimEndValues, *measuredSetupStartValues, *measuredSetupEndValues;

                MeasureTime::addResultContentBlock("<%dotPath(modelInfo.name)%>","main",measureTimeArraySimulation);

                measuredSimStartValues = MeasureTime::getZeroValues();
                measuredSimEndValues = MeasureTime::getZeroValues();
                measuredSetupStartValues = MeasureTime::getZeroValues();
                measuredSetupEndValues = MeasureTime::getZeroValues();

                <%generateMeasureTimeStartCode('measuredSimStartValues', "all", "")%>
                <%generateMeasureTimeStartCode('measuredSetupStartValues', "setup", "")%>

                >>
            %>
            <%additionalPreRunCommands%>

            #ifdef RUNTIME_STATIC_LINKING
              shared_ptr<StaticOMCFactory>  _factory =  shared_ptr<StaticOMCFactory>(new StaticOMCFactory());
            #else
              shared_ptr<OMCFactory>  _factory =  shared_ptr<OMCFactory>(new OMCFactory());
            #endif //RUNTIME_STATIC_LINKING
            //SimController to start simulation

            std::pair<shared_ptr<ISimController>, SimSettings> simulation = _factory->createSimulation(argc, argv, opts);
            Logger::initialize(simulation.second.logSettings);

            //create Modelica system
            shared_ptr<ISimObjects> simObjects= simulation.first->getSimObjects();
            weak_ptr<ISimData> simData = simObjects->LoadSimData("<%lastIdentOfPath(modelInfo.name)%>");
            weak_ptr<ISimVars> simVars = simObjects->LoadSimVars("<%lastIdentOfPath(modelInfo.name)%>",<%numRealVars%>,<%numIntVars%>,<%numBoolVars%>,<%numStringVars%>,<%numPreVars%>,<%numStatevars(modelInfo)%>,<%numStateVarIndex(modelInfo)%>);
            weak_ptr<IMixedSystem> system = simulation.first->LoadSystem("OMCpp<%fileNamePrefix%><%makefileParams.dllext%>","<%lastIdentOfPath(modelInfo.name)%>");
            <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
              <<
              <%generateMeasureTimeEndCode("measuredSetupStartValues", "measuredSetupEndValues", "(*measureTimeArraySimulation)[1]", "setup", "")%>
              >>
            %>
            simulation.first->Start(simulation.second, "<%lastIdentOfPath(modelInfo.name)%>");

            <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
              <<
              <%generateMeasureTimeEndCode("measuredSimStartValues", "measuredSimEndValues", "(*measureTimeArraySimulation)[0]", "all", "")%>
              MeasureTime::getInstance()->writeToJson();
              MeasureTime::deinitialize();

              delete measuredSimStartValues;
              delete measuredSimEndValues;
              delete measuredSetupStartValues;
              delete measuredSetupEndValues;
              >>
            %>

            return 0;

      }
      catch(ModelicaSimulationError& ex)
      {
          if(!ex.isSuppressed())
              std::cerr << "Simulation stopped with error in " << error_id_string(ex.getErrorID()) << ": "  << ex.what();
          return 1;
      }
  }
  >>
end simulationMainFile;

template defineInputVars(SimCode simCode )
::=
  let &varDecls = buffer "" /*BUFD*/
  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
   let inputs = match simCode
             case simCode as SIMCODE(__) then
                 match modelInfo
                   case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
                    let &varOptDecls = buffer "" /*BUFD*/
          let &optpreExp = buffer "" /*BUFD*/

          let inputnames = vars.inputVars |>  SIMVAR(__) hasindex i0 =>
      <<
      shared_ptr<SimDouble> sim_value_in<%cref(name, false)%>(new SimDouble(0.0)/*set start value here*/);
      simData_shared->Add("<%cref(name, false)%>", sim_value_in<%cref(name, false)%>);
      >>
      ;separator="\n"

      <<
      <%inputnames%>
          >>

  <<
  <%inputs%>
  >>

end defineInputVars;

template setInputVars(SimCode simCode )
::=
  let &varDecls = buffer "" /*BUFD*/
  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
   let inputs = match simCode
             case simCode as SIMCODE(__) then
                 match modelInfo
                   case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
                    let &varOptDecls = buffer "" /*BUFD*/
          let &optpreExp = buffer "" /*BUFD*/

          let inputnames = vars.inputVars |>  SIMVAR(__) hasindex i0 =>
      <<
      dynamic_cast<SimDouble*>(data->Get("<%cref(name, false)%>"))->getValue()   = //place variable here ;
      >>
      ;separator="\n"

    <<
    <%inputnames%>
    >>

  <<
  <%inputs%>
  >>

end setInputVars;

template setMainFBOutputVars(SimCode simCode )
::=
  let &varDecls = buffer "" /*BUFD*/
  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
   let outputs = match simCode
             case simCode as SIMCODE(__) then
                 match modelInfo
                   case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
                    let &varOptDecls = buffer "" /*BUFD*/
          let &optpreExp = buffer "" /*BUFD*/

          let outputnames = vars.outputVars |>  SIMVAR(__) hasindex i0 =>
      <<
      p->instance-><%crefST(name, false)%> = dynamic_cast<SimDouble*>(p->instance->simdata->Get("<%cref(name, false)%>"))->getValue();
      >>
      ;separator="\n"

    <<
    <%outputnames%>
    >>

  <<
  <%outputs%>
  >>

end setMainFBOutputVars;

template setMainFBInputVars(SimCode simCode )
::=
  let &varDecls = buffer "" /*BUFD*/
  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
   let inputs = match simCode
             case simCode as SIMCODE(__) then
                 match modelInfo
                   case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
                    let &varOptDecls = buffer "" /*BUFD*/
          let &optpreExp = buffer "" /*BUFD*/

          let inputnames = vars.inputVars |>  SIMVAR(__) hasindex i0 =>
      <<
      dynamic_cast<SimDouble*>(p->instance->simdata->Get("<%cref(name, false)%>"))->getValue() = p->instance-><%crefST(name, false)%>;
      >>
      ;separator="\n"

    <<
    <%inputnames%>
    >>

  <<
  <%inputs%>
  >>

end setMainFBInputVars;

template spsOutputVars(SimCode simCode )
::=
  let &varDecls = buffer "" /*BUFD*/
  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
   let outputs = match simCode
             case simCode as SIMCODE(__) then
                 match modelInfo
                   case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
                    let &varOptDecls = buffer "" /*BUFD*/
          let &optpreExp = buffer "" /*BUFD*/

          let outputnames = vars.outputVars |>  SIMVAR(__) hasindex i0 =>
      <<
      <variable name= "<%crefST(name, false)%>">
      <type>
          <<%crefTypeST(name)%>/>
      </type>
      </variable>
      >>
      ;separator="\n"

    <<
    <%outputnames%>
    >>

  <<
  <%outputs%>
  >>

end spsOutputVars;

template spsInputVars(SimCode simCode )
::=
  let &varDecls = buffer "" /*BUFD*/
  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
   let inputs = match simCode
             case simCode as SIMCODE(__) then
                 match modelInfo
                   case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
                    let &varOptDecls = buffer "" /*BUFD*/
          let &optpreExp = buffer "" /*BUFD*/

          let inputnames = vars.inputVars |>  SIMVAR(__) hasindex i0 =>
      <<
      <variable name= "<%crefST(name, false)%>">
        <type>
          <<%crefTypeST(name)%>/>
        </type>
      </variable>
      >>
      ;separator="\n"

    <<
    <%inputnames%>
    >>

  <<
  <%inputs%>
  >>

end spsInputVars;


template mlpiOutputVars(SimCode simCode )
::=
  let &varDecls = buffer "" /*BUFD*/
  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
   let outputs = match simCode
             case simCode as SIMCODE(__) then
                 match modelInfo
                   case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
                    let &varOptDecls = buffer "" /*BUFD*/
          let &optpreExp = buffer "" /*BUFD*/

          let outputnames = vars.outputVars |>  SIMVAR(__) hasindex i0 =>
      <<
      <%crefTypeMLPI(name)%> <%crefST(name, false)%>;
      >>
      ;separator="\n"

    <<
    <%outputnames%>
    >>

  <<
  <%outputs%>
  >>

end mlpiOutputVars;

template mlpiInputVars(SimCode simCode )
::=
  let &varDecls = buffer "" /*BUFD*/
  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
   let inputs = match simCode
             case simCode as SIMCODE(__) then
                 match modelInfo
                   case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
                    let &varOptDecls = buffer "" /*BUFD*/
          let &optpreExp = buffer "" /*BUFD*/

          let inputnames = vars.inputVars |>  SIMVAR(__) hasindex i0 =>
      <<
      <%crefTypeMLPI(name)%> <%crefST(name, false)%>;
      >>
      ;separator="\n"

    <<
    <%inputnames%>
    >>

  <<
  <%inputs%>
  >>
end mlpiInputVars;

template defineOutputVars(SimCode simCode )
::=
  let &varDecls = buffer "" /*BUFD*/
  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
   let outputs = match simCode
             case simCode as SIMCODE(__) then
                 match modelInfo
                   case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
                    let &varOptDecls = buffer "" /*BUFD*/
          let &optpreExp = buffer "" /*BUFD*/

          let outputnames = vars.outputVars |>  SIMVAR(__) hasindex i0 =>
      <<
      shared_ptr<SimDouble> sim_value_out<%cref(name, false)%>(new SimDouble(0.0));
      simData_shared->Add("<%cref(name, false)%>", sim_value_out<%cref(name, false)%>);
      >>
      ;separator="\n"

      <<
      <%outputnames%>
      >>

  <<
  <%outputs%>
  >>

end defineOutputVars;


template getOutputVars(SimCode simCode )
::=
  let &varDecls = buffer "" /*BUFD*/
  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
   let outputs = match simCode
             case simCode as SIMCODE(__) then
                 match modelInfo
                   case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
                    let &varOptDecls = buffer "" /*BUFD*/
          let &optpreExp = buffer "" /*BUFD*/

          let outputnames = vars.outputVars |>  SIMVAR(__) hasindex i0 =>
      <<
      place variable here  = dynamic_cast<SimDouble*>(data->Get("<%cref(name, false)%>"))->getValue();
      >>
      ;separator="\n"

    <<
      /* do something with the outputs!*/
    /*
    <%outputnames%>
        */
    >>

  <<
  <%outputs%>
  >>

end getOutputVars;

template streamOutputVars(SimCode simCode )
::=
  let &varDecls = buffer "" /*BUFD*/
  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
   let outputs = match simCode
             case simCode as SIMCODE(__) then
                 match modelInfo
                   case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
                    let &varOptDecls = buffer "" /*BUFD*/
          let &optpreExp = buffer "" /*BUFD*/

          let outputnames = vars.outputVars |>  SIMVAR(__) hasindex i0 =>
      <<
      f << dynamic_cast<SimDouble*>(data->Get("<%cref(name, false)%>"))->getValue() << ";" ;
      >>
      ;separator="\n"

    <<
    <%outputnames%>

    f << endl;
    >>

  <<
  <%outputs%>
  >>

end streamOutputVars;


template calcHelperMainfile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__)) then
    <<
    /*****************************************************************************
    *
    * Helper file that includes all generated calculation files, except the alg loops.
    * This file is generated by the OpenModelica Compiler and produced to speed-up the compile time.
    *
    *****************************************************************************/
    #include <Core/ModelicaDefine.h>
    #include <Core/Modelica.h>
    #include <Core/System/FactoryExport.h>
    #include <Core/System/DiscreteEvents.h>
    #include <Core/System/EventHandling.h>
    #include <Core/DataExchange/XmlPropertyReader.h>


    #include "OMCpp<%fileNamePrefix%>Types.h"
    #include "OMCpp<%fileNamePrefix%>Functions.h"
    #include "OMCpp<%fileNamePrefix%>.h"


    #include "OMCpp<%fileNamePrefix%>Jacobian.h"
    #include "OMCpp<%fileNamePrefix%>Mixed.h"
    #include "OMCpp<%fileNamePrefix%>StateSelection.h"
    #include "OMCpp<%fileNamePrefix%>WriteOutput.h"
    #include "OMCpp<%fileNamePrefix%>Initialize.h"


    #include "OMCpp<%fileNamePrefix%>AlgLoopMain.cpp"
    #include "OMCpp<%fileNamePrefix%>FactoryExport.cpp"
    #include "OMCpp<%fileNamePrefix%>Mixed.cpp"
    #include "OMCpp<%fileNamePrefix%>Functions.cpp"
    <%if(boolOr(Flags.isSet(Flags.HARDCODED_START_VALUES), Flags.isSet(Flags.GEN_DEBUG_SYMBOLS))) then
    <<
    #include "OMCpp<%fileNamePrefix%>InitializeParameter.cpp"
    #include "OMCpp<%fileNamePrefix%>InitializeAlgVars.cpp"
    >>
    %>
    #include "OMCpp<%fileNamePrefix%>InitializeExtVars.cpp"
    #include "OMCpp<%fileNamePrefix%>Initialize.cpp"
    #include "OMCpp<%fileNamePrefix%>WriteOutput.cpp"
    #include "OMCpp<%fileNamePrefix%>Jacobian.cpp"
    #include "OMCpp<%fileNamePrefix%>StateSelection.cpp"
    #include "OMCpp<%fileNamePrefix%>.cpp"
    >>
end calcHelperMainfile;

template algloopHeaderFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,SimEqSystem eq, Context context, Boolean useFlatArrayNotation)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(__) then
  <<
  <%generateAlgloopHeaderInlcudeString(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context)%>
  <%generateAlgloopClassDeclarationCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq,context,useFlatArrayNotation)%>
  >>
end algloopHeaderFile;

template simulationFunctionsFile(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, list<Function> functions, list<Exp> literals,list<String> includes, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates the content of the Cpp file for functions in the simulation case."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  <<

  <%externalFunctionIncludes(includes)%>

  //external functions
  extern "C" {
    <%externfunctionHeaderDefinition(functions)%>
  }

  Functions::Functions(double& simTime, double* z, double* zDot, bool& initial, bool& terminate)
      : _simTime(simTime)
      , __z(z)
      , __zDot(zDot)
      , _initial(initial)
      , _terminate(terminate)
  {
    <%literals |> literal hasindex i0 fromindex 0 => literalExpConstImpl(literal,i0) ; separator="\n";empty%>
  }

  Functions::~Functions()
  {
  }

  void Functions::Assert(bool cond, string msg)
  {
    if(!cond)
     throw ModelicaSimulationError(MODEL_EQ_SYSTEM,msg);
  }

  <%functionBodies(functions, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
  /*extraFuncs*/
  <%extraFuncs%>
  >>
end simulationFunctionsFile;


template externalFunctionIncludes(list<String> includes)
 "Generates external includes part in function files."
::=
  if includes then
  <<
  #ifdef __cplusplus
  extern "C" {
  #endif
  <% (includes ;separator="\n") %>
  #ifdef __cplusplus
  }
  #endif
  >>
end externalFunctionIncludes;

template simulationTypesHeaderFile(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text& dummyElemTypeCreation, list<Function> functions, list<Exp> literals, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  <<
  #pragma once

  /*****************************************************************************
  *
  * Simulation data types generated by the OpenModelica Compiler.
  *
  *****************************************************************************/

  <%functionHeaderBodies1(functions,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, dummyElemTypeCreation, stateDerVectorName, useFlatArrayNotation)%>
  >>
end simulationTypesHeaderFile;


template simulationFunctionsHeaderFile(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace,
                                       list<Function> functions, list<Exp> literals, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match simCode

case SIMCODE(modelInfo=MODELINFO(__)) then
  <<
  #pragma once

  /*****************************************************************************
  *
  * Simulation code for FunctionCall functions generated by the OpenModelica Compiler.
  *
  *****************************************************************************/

  class Functions
  {
  public:
    Functions(double& simTime, double* z, double* zDot, bool& initial, bool& terminate);
    ~Functions();
    //Modelica functions
    <%functionHeaderBodies2(functions,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>

    void Assert(bool cond,string msg);

    //Literals
    <%literals |> literal hasindex i0 fromindex 0 => literalExpConst(literal,i0) ; separator="\n";empty%>
  private:
    //Function return variables
    <%functionHeaderBodies3(functions,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
    double& _simTime;
    bool& _terminate;
    bool& _initial;
    double* __z;
    double* __zDot;
    /*extraFuncs*/
    <%extraFuncsDecl%>
  };
  >>
end simulationFunctionsHeaderFile;

template declFunParams( list<Function> functions, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Text stateDerVectorName /*=__zDot*/)
::=
let params = (functions |> fn => declFunParams2(fn, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,stateDerVectorName) ;separator="\n")
<<
<%params%>
>>
end declFunParams;

template declFunParams2(Function fn, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Text stateDerVectorName /*=__zDot*/)
::=
match fn
case FUNCTION(__) then
let params = (variableDeclarations |> var hasindex i1 fromindex 1 =>
      funParamDecl(var, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName) ; separator="" /* increase the counter! */)
<<
<%params%>
>>
end declFunParams2;

template funParamDecl(Variable var, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/)
::=
match var
case VARIABLE(__) then
  match kind
    case PARAM(__) then
    <<
      <%funParamDecl2(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, false)%>
    >>
    else
    ''
  end match
else
''
end funParamDecl;


template funParamDecl2(Variable var, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
 match var
case var as VARIABLE(__) then
  let varName = '<%contextCref(var.name, contextFunction, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  //let instDimsInit = (instDims |> exp => daeExp(exp, contextFunction, &varInits , &varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation);separator=",")
  funParamDecl3(var,varName,instDims,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)

end funParamDecl2;



template funParamDecl3(Variable var,String varName, list<DAE.Exp> instDims, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
 let &varDecls = buffer "" /*BUFD*/ //should be empty
  let &varInits = buffer "" /*BUFD*/ //should be empty
  let instDimsInit = (instDims |> exp => daeExp(exp, contextFunction, &varInits , &varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation);separator=",")
  match var
  case var as VARIABLE(__) then
  let type = '<%varType(var)%>'
  let testinstDimsInit = (instDims |> exp => testDaeDimensionExp(exp);separator="")
  let instDimsInit = (instDims |> exp => daeExp(exp, contextFunction, &varInits , &varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation);separator=",")
  let arrayexpression1 = (if instDims then 'StatArrayDim<%listLength(instDims)%><<%expTypeShort(var.ty)%>,<%instDimsInit%>> <%varName%>;/*testarray*/<%\n%>'
  else '<%type%> <%varName%>')
  let arrayexpression2 = (if instDims then 'DynArrayDim<%listLength(instDims)%><<%expTypeShort(var.ty)%>> <%varName%>;<%\n%>'
  else '<%type%> <%varName%>')
  let paramdecl= match testinstDimsInit
  case "" then
     arrayexpression1
  else
    arrayexpression2
  paramdecl
end funParamDecl3;




template initParams1(list<Function> functions, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/)
::=
let &varDecls = buffer "" /*BUFD*/
let &varInits = buffer "" /*BUFD*/
let _ = (functions |> fn => initParams2(fn, varDecls, varInits, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName) ;separator="\n")
<<
<%varDecls%>
<%varInits%>
>>
end initParams1;

template initParams2(Function fn, Text &varDecls, Text &varInits, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/)
::=
match fn
case FUNCTION(__) then
let _ = (variableDeclarations |> var hasindex i1 fromindex 1 =>
      paramInit2(var, "", i1, varDecls, varInits, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName) ; separator="" /* increase the counter! */)
""
end initParams2;

template paramInit2(Variable var, String outStruct, Integer i, Text &varDecls, Text &varInits, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/)
::=
match var
case VARIABLE(__) then
  match kind
    case PARAM(__) then  paramInit3(var, "", i, &varDecls, &varInits,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, false)
  else ''
else
''
end paramInit2;


template paramInit3(Variable var, String outStruct, Integer i, Text &varDecls, Text &varInits, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                    Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match var
case var as VARIABLE(__) then
  let varName = '<%contextCref(var.name, contextFunction, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'

  let instDimsInit = (instDims |> exp => daeExp(exp, contextFunction, &varInits, &varDecls,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation);separator=",")

  if instDims then
    let testinstDimsInit = (instDims |> exp => testDaeDimensionExp(exp);separator="")
    let temp = setDims(testinstDimsInit, varName , &varInits, instDimsInit)


  (match var.value
    case SOME(exp) then

  let defaultValue = varDefaultValue(var, outStruct, i, varName, &varDecls, &varInits,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let &varInits += defaultValue
  let var_name = if outStruct then
        '<%extVarName(var.name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' else
        '<%contextCref(var.name, contextFunction,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
   let defaultValue1 = '<%var_name%>.assign(<%daeExp(exp, contextFunction, &varInits  , &varDecls,simCode , &extraFuncs , &extraFuncsDecl, stateDerVectorName, extraFuncsNamespace, useFlatArrayNotation)%>);<%\n%>'
      let &varInits += defaultValue1
    ""
    else
      let defaultValue = varDefaultValue(var, outStruct, i, varName, &varDecls, &varInits, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      let &varInits += defaultValue
      ""
   )
  else
    (match var.value
    case SOME(exp) then
      let defaultValue = '<%contextCref(var.name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%> = <%daeExp(exp, contextFunction, &varInits, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>;<%\n%>'
      let &varInits += defaultValue
      " "
    else
      "")
case var as FUNCTION_PTR(__) then
  let &ignore = buffer ""
  let &varDecls += functionArg(var,&ignore)
  ""

end paramInit3;

template simulationMainDLLib(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match simCode
case SIMCODE(makefileParams=MAKEFILE_PARAMS(__)) then
<<
<%simulationMainDLLib2(makefileParams.platform)%>
>>
end simulationMainDLLib;

template simulationMainDLLib2(String platform)
::=
match platform
case "linux32"
case "linux64" then
<<
"-ldl"
>>
else
""
end simulationMainDLLib2;


template simulationMakefile(String target, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, String additionalLinkerFlags_GCC,
                            String additionalLinkerFlags_MSVC, String additionalCFlags_GCC,
                            String additionalCFlags_MSVC, Boolean compileForMPI)
 "Generates the contents of the makefile for the simulation case."
::=
let &timeMeasureLink = buffer "" /*BUFD*/
match getGeneralTarget(target)
case "debugrt"
case "msvc" then
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
  let dirExtra = if modelInfo.directory then '/LIBPATH:"<%modelInfo.directory%>"' //else ""
  let libsStr = (makefileParams.libs |> lib => lib ;separator=" ")
  let libsPos1 = if not dirExtra then libsStr //else ""
  let libsPos2 = if dirExtra then libsStr // else ""
  let ParModelicaLibs = if acceptParModelicaGrammar() then '-lOMOCLRuntime -lOpenCL' // else ""
  let &timeMeasureLink += "OMCppExtensionUtilities.lib"
  let extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then
    match s.method case "dassljac" then "-D_OMC_JACOBIAN "

  <<
  # Makefile generated by OpenModelica
  OMHOME=<%makefileParams.omhome%>
  # Simulations use -O3 by default
  SIM_OR_DYNLOAD_OPT_LEVEL=
  MODELICAUSERCFLAGS=
  CXX=cl
  EXEEXT=.exe
  DLLEXT=.dll
  include <%makefileParams.omhome%>/include/omc/cpp/ModelicaConfig_msvc.inc
  include <%makefileParams.omhome%>/include/omc/cpp/ModelicaLibraryConfig_msvc.inc
  # /Od - Optimization disabled
  # /EHa enable C++ EH (w/ SEH exceptions)
  # /fp:except - consider floating-point exceptions when generating code
  # /arch:SSE2 - enable use of instructions available with SSE2 enabled CPUs
  # /I - Include Directories
  # /DNOMINMAX - Define NOMINMAX (does what it says)
  # /TP - Use C++ Compiler
  !IF "$(PCH_FILE)" == ""
  CFLAGS=  $(SYSTEM_CFLAGS) /I"<%makefileParams.omhome%>/include/omc/cpp/" /I. <%makefileParams.includes%>  /I"$(BOOST_INCLUDE)" /I"$(UMFPACK_INCLUDE)" /I"$(SUNDIALS_INCLUDE)" /DNOMINMAX /TP /DNO_INTERACTIVE_DEPENDENCY <%additionalCFlags_MSVC%>
  !ELSE
  CFLAGS=  $(SYSTEM_CFLAGS) /I"<%makefileParams.omhome%>/include/omc/cpp/" /I. <%makefileParams.includes%>  /I"$(BOOST_INCLUDE)" /I"$(UMFPACK_INCLUDE)" /I"$(SUNDIALS_INCLUDE)" /DNOMINMAX /TP /DNO_INTERACTIVE_DEPENDENCY  /Fp<%makefileParams.omhome%>/include/omc/cpp/Core/$(PCH_FILE)  /YuCore/$(H_FILE) <%additionalCFlags_MSVC%>
  !ENDIF
  CPPFLAGS =
  # /ZI enable Edit and Continue debug info
  CDFLAGS = /ZI

  # /MD - link with MSVCRT.LIB
  # /link - [linker options and libraries]
  # /LIBPATH: - Directories where libs can be found
  #LDFLAGS=/MDd   /link /DLL /NOENTRY /LIBPATH:"<%makefileParams.omhome%>/lib/<%getTriple()%>/omc/cpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)" OMCppSystem.lib OMCppMath.lib
  #LDSYSTEMFLAGS=/MD /Debug  /link /DLL /NOENTRY /LIBPATH:"<%makefileParams.omhome%>/lib/<%getTriple()%>/omc/cpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)" OMCppSystem.lib OMCppModelicaUtilities.lib  OMCppMath.lib   OMCppOMCFactory.lib
  LDSYSTEMFLAGS=  /link /DLL /NOENTRY /LIBPATH:"<%makefileParams.omhome%>/lib/<%getTriple()%>/omc/cpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/lib/<%getTriple()%>/omc/msvc" /LIBPATH:"<%makefileParams.omhome%>/lib/<%getTriple()%>/omc/msvc/debug"  /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)" OMCppSystem.lib OMCppModelicaUtilities.lib  OMCppMath.lib OMCppDataExchange.lib  OMCppOMCFactory.lib <%timeMeasureLink%>
  #LDMAINFLAGS=/MD /Debug  /link /LIBPATH:"<%makefileParams.omhome%>/lib/<%getTriple()%>/omc/cpp/msvc" OMCppOMCFactory.lib  /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)"
  LDMAINFLAGS=/link /LIBPATH:"<%makefileParams.omhome%>/lib/<%getTriple()%>/omc/cpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/lib/<%getTriple()%>/omc/msvc" OMCppOMCFactory.lib OMCppModelicaUtilities.lib <%timeMeasureLink%> /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)"
  # /MDd link with MSVCRTD.LIB debug lib
  # lib names should not be appended with a d just switch to lib/omc/cpp



  FILEPREFIX=<%fileNamePrefix%>
  FUNCTIONFILE=OMCpp<%fileNamePrefix%>Functions.cpp
  INITFILE=OMCpp<%fileNamePrefix%>Initialize.cpp
  FACTORYFILE=OMCpp<%fileNamePrefix%>FactoryExport.cpp
  EXTENSIONFILE=OMCpp<%fileNamePrefix%>Extension.cpp
  JACOBIANFILE=OMCpp<%fileNamePrefix%>Jacobian.cpp
  STATESELECTIONFILE=OMCpp<%fileNamePrefix%>StateSelection.cpp
  WRITEOUTPUTFILE=OMCpp<%fileNamePrefix%>WriteOutput.cpp
  SYSTEMFILE=OMCpp<%fileNamePrefix%><% if acceptMetaModelicaGrammar() then ".conv"%>.cpp
  MAINFILE = OMCpp<%fileNamePrefix%>Main.cpp
  MAINOBJ=<%fileNamePrefix%>$(EXEEXT)
  SYSTEMOBJ=OMCpp<%fileNamePrefix%>$(DLLEXT)

  CALCHELPERMAINFILE=OMCpp<%fileNamePrefix%>CalcHelperMain.cpp
  ALGLOOPMAINFILE=OMCpp<%fileNamePrefix%>AlgLoopMain.cpp
  GENERATEDFILES=$(MAINFILE) $(FUNCTIONFILE) $(ALGLOOPMAINFILE)

  $(MODELICA_SYSTEM_LIB)$(DLLEXT):
  <%\t%>$(CXX)  /Fe$(SYSTEMOBJ) $(CALCHELPERMAINFILE) $(CFLAGS) $(LDSYSTEMFLAGS) <%dirExtra%> <%libsPos1%> <%libsPos2%>
  <%\t%>$(CXX) $(CPPFLAGS) /Fe$(MAINOBJ)  $(MAINFILE)   $(CFLAGS) $(LDMAINFLAGS)
  >>
end match
case "gcc" then
    match simCode
        case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
            let dirExtra = if modelInfo.directory then '-L"<%modelInfo.directory%>"' //else ""
            let libsStr = (makefileParams.libs |> lib => lib ;separator=" ")
            let libsPos1 = if not dirExtra then libsStr //else ""
            let libsPos2 = if dirExtra then libsStr // else ""
            let staticLibs = '-Wl,--start-group -lOMCppOMCFactory_static -lOMCppSystem_static -lOMCppSimController_static -Wl,--end-group -lOMCppSimulationSettings_static -lOMCppDataExchange_static -lOMCppNewton_static -lOMCppEuler_static -lOMCppKinsol_static -lOMCppCVode_static -lOMCppIDA_static -lOMCppSolver_static -lOMCppMath_static -lOMCppModelicaUtilities_static -lOMCppExtensionUtilities_static -L$(SUNDIALS_LIBS) -L$(UMFPACK_LIBS) -L$(LAPACK_LIBS)'
            let staticIncludes = '-I"$(SUNDIALS_INCLUDE)" -I"$(SUNDIALS_INCLUDE)/kinsol" -I"$(SUNDIALS_INCLUDE)/nvector"'
            let _extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then ""
            let extraCflags = '<%_extraCflags%><% if Flags.isSet(Flags.GEN_DEBUG_SYMBOLS) then " -g"%>'
            let papiLibs = ' -lOMCppExtensionUtilities_papi -lpapi'
            let CC = if (compileForMPI) then "mpicc" else '<%makefileParams.ccompiler%>'
            let CXX = if (compileForMPI) then "mpicxx" else '<%makefileParams.cxxcompiler%>'
            let extraCppFlags = (getConfigStringList(CPP_FLAGS) |> flag => '<%flag%>'; separator=" ")
            let MPIEnvVars = if (compileForMPI)
                then 'OMPI_MPICC=<%makefileParams.ccompiler%> <%\n%>OMPI_MPICXX=<%makefileParams.cxxcompiler%>' else ""
            <<
            # Makefile generated by OpenModelica
            OMHOME=<%makefileParams.omhome%>
            include $(OMHOME)/include/omc/cpp/ModelicaConfig_gcc.inc
            include $(OMHOME)/include/omc/cpp/ModelicaLibraryConfig_gcc.inc
            # Simulations use -O0 by default
            SIM_OR_DYNLOAD_OPT_LEVEL=-O0
            CC=<%CC%>
            CXX=<%CXX%> $(OPENMP_FLAGS)
            RUNTIME_STATIC_LINKING=<%if(Flags.isSet(Flags.RUNTIME_STATIC_LINKING)) then 'ON' else 'OFF'%>
            <%MPIEnvVars%>

            EXEEXT=<%makefileParams.exeext%>
            DLLEXT=<%makefileParams.dllext%>

            CFLAGS_COMMON=<%extraCflags%> -Winvalid-pch $(SYSTEM_CFLAGS) -I"$(SCOREP_INCLUDE)" -I"$(OMHOME)/include/omc/cpp/" -I. <%makefileParams.includes%> -I"$(BOOST_INCLUDE)" -I"$(UMFPACK_INCLUDE)" -I"$(SUNDIALS_INCLUDE)" <%makefileParams.includes ; separator=" "%> <%match sopt case SOME(s as SIMULATION_SETTINGS(__)) then s.cflags %> <%additionalCFlags_GCC%> <%extraCppFlags%>

            ifeq ($(USE_SCOREP),ON)
            $(eval CC=scorep --user --nocompiler $(CC))
            $(eval CXX=scorep --user --nocompiler $(CXX))
            else
            $(eval CFLAGS_COMMON=$(CFLAGS_COMMON) -DMEASURETIME_PROFILEBLOCKS)
            endif

            ifeq ($(USE_LOGGER),ON)
            $(eval CFLAGS_COMMON=$(CFLAGS_COMMON) -DUSE_LOGGER)
            endif

            CFLAGS_DYNAMIC=$(CFLAGS_COMMON)
            CFLAGS_STATIC=$(CFLAGS_COMMON) <%staticIncludes%> -DRUNTIME_STATIC_LINKING -DENABLE_SUNDIALS_STATIC

			MINGW_EXTRA_LIBS=<%if boolOr(stringEq(makefileParams.platform, "win32"),stringEq(makefileParams.platform, "win64")) then ' -lz -lhdf5' else ''%>
            MODELICA_EXTERNAL_LIBS=-lModelicaExternalC -lModelicaStandardTables -L$(LAPACK_LIBS) $(LAPACK_LIBRARIES) $(MINGW_EXTRA_LIBS)

            LDSYSTEMFLAGS_COMMON=-L"$(OMHOME)/lib/<%getTriple()%>/omc/cpp" $(BASE_LIB) <%additionalLinkerFlags_GCC%>  -Wl,-rpath,"$(OMHOME)/lib/<%getTriple()%>/omc/cpp" <%timeMeasureLink%> -L"$(BOOST_LIBS)" $(BOOST_LIBRARIES) $(LINUX_LIB_DL)
            LDMAINFLAGS_COMMON=-L"$(OMHOME)/lib/<%getTriple()%>/omc/cpp" -L"$(OMHOME)/bin" -L"$(BOOST_LIBS)" $(BOOST_LIBRARIES) $(LINUX_LIB_DL) <%additionalLinkerFlags_GCC%>  -Wl,-rpath,"$(OMHOME)/lib/<%getTriple()%>/omc/cpp"

            ifeq ($(USE_PAPI),ON)
            $(eval LDMAINFLAGS_COMMON=$(LDMAINFLAGS_COMMON) <%papiLibs%>)
            $(eval LDSYSTEMFLAGS_COMMON=$(LDSYSTEMFLAGS_COMMON) <%papiLibs%>)
            endif

            LDSYSTEMFLAGS_DYNAMIC=-lOMCppSystem -lOMCppModelicaUtilities -lOMCppDataExchange -lOMCppMath -lOMCppExtensionUtilities -lOMCppOMCFactory $(LDSYSTEMFLAGS_COMMON)
            LDSYSTEMFLAGS_STATIC=<%staticLibs%> $(LDSYSTEMFLAGS_COMMON)

            LDMAINFLAGS_DYNAMIC= -lOMCppOMCFactory -lOMCppModelicaUtilities -lOMCppExtensionUtilities $(LDMAINFLAGS_COMMON)
            LDMAINFLAGS_STATIC=<%staticLibs%> $(LDMAINFLAGS_COMMON) $(SUNDIALS_LIBRARIES) $(LAPACK_LIBRARIES)

            ifeq ($(RUNTIME_STATIC_LINKING),ON)
            $(eval CFLAGS=$(CFLAGS_STATIC))
            $(eval LDSYSTEMFLAGS=$(LDSYSTEMFLAGS_STATIC))
            $(eval LDMAINFLAGS=$(LDMAINFLAGS_STATIC))
            else
            $(eval CFLAGS=$(CFLAGS_DYNAMIC))
            $(eval LDSYSTEMFLAGS=$(LDSYSTEMFLAGS_DYNAMIC))
            $(eval LDMAINFLAGS=$(LDMAINFLAGS_DYNAMIC))
            endif

            CPPFLAGS=$(CFLAGS)

            SYSTEMFILE=OMCpp<%fileNamePrefix%><% if acceptMetaModelicaGrammar() then ".conv"%>.cpp
            MAINFILE = OMCpp<%fileNamePrefix%>Main.cpp
            MAINOBJ=<%fileNamePrefix%>$(EXEEXT)
            SYSTEMOBJ=OMCpp<%fileNamePrefix%>$(DLLEXT)

            CALCHELPERMAINFILE=OMCpp<%fileNamePrefix%>CalcHelperMain.cpp
            ALGLOOPSMAINFILE=OMCpp<%fileNamePrefix%>AlgLoopMain.cpp

            CPPFILES=$(CALCHELPERMAINFILE)
            OFILES=$(CPPFILES:.cpp=.o)

            .PHONY: <%lastIdentOfPath(modelInfo.name)%> $(CPPFILES)

            <%fileNamePrefix%>: $(MAINFILE) $(OFILES)

            ifeq ($(RUNTIME_STATIC_LINKING),ON)
            <%\t%>$(CXX) $(CFLAGS) -I. -o $(MAINOBJ) $(MAINFILE) $(LDMAINFLAGS) $(MODELICA_EXTERNAL_LIBS)
            else
            <%\t%>$(CXX) -shared -o $(SYSTEMOBJ) $(OFILES) <%dirExtra%> <%libsPos1%> <%libsPos2%> $(LDSYSTEMFLAGS) $(MODELICA_EXTERNAL_LIBS)
            <%\t%>$(CXX) $(CFLAGS) -I. -o $(MAINOBJ) $(MAINFILE) $(LDMAINFLAGS)
            endif

            <%if boolNot(boolOr(stringEq(makefileParams.platform, "win32"),stringEq(makefileParams.platform, "win64"))) then
                <<
                <%\t%>chmod +x <%fileNamePrefix%>.sh
                >>
            %>
            >>
  end match
case "vxworks69" then
    match simCode
        case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
      <<
      BUILD_SPEC=ATOMgnu
      DEBUG_MODE=1
      TRACE=1

      MODEL_NAME = <%fileNamePrefix%>

      OPENMODELICAHOME := $(subst \,/,$(OPENMODELICAHOME))
      WIND_HOME := $(subst \,/,$(WIND_HOME))
      WIND_BASE := $(WIND_HOME)/customBosch/vxworks-6.9
      export WIND_BASE
      MLPI_SDK_01 := $(subst \,/,$(MLPI_SDK_01))


      all : clean pre_build main_all post_build

      _clean ::
      <%\t%>@echo "make: removing targets and objects of `pwd`"

      TRACE=0
      TRACEON=$(TRACE:0=@)
      TRACE_FLAG=$(TRACEON:1=)

      JOBS?=1
      TARGET_JOBS?=$(JOBS)

      MAKEFILE := Makefile

      FLEXIBLE_BUILD := 1

      BUILD_SPEC = ATOMgnu
      DEBUG_MODE = 1
      ifeq ($(DEBUG_MODE),1)
      MODE_DIR := Debug
      else
      MODE_DIR := NonDebug
      endif
      OBJ_DIR := .




      #Global Build Macros
      PROJECT_TYPE = DKM
      DEFINES =
      EXPAND_DBG = 0


      #BuildSpec specific Build Macros
      VX_CPU_FAMILY = pentium
      CPU = ATOM
      TOOL_FAMILY = gnu
      TOOL = gnu
      TOOL_PATH = $(WIND_HOME)/gnu/4.3.3-vxworks-6.9/x86-win32/bin/
      CC_ARCH_SPEC = -march=atom -nostdlib -fno-builtin -fno-defer-pop -fno-implicit-fp
      VSB_DIR = $(WIND_BASE)/target/lib
      VSB_CONFIG_FILE = $(VSB_DIR)/h/config/vsbConfig.h
      LIBPATH =
      LIBS =

      IDE_INCLUDES = -I$(WIND_BASE)/target/h -I$(WIND_BASE)/target/h/wrn/coreip -I$(MLPI_SDK_01)/mlpiCore/include -I$(OPENMODELICAHOME)/include/omc/cpp -I$(OPENMODELICAHOME)/include/omc/cpp/Core -I$(OPENMODELICAHOME)/include/omc/cpp

      IDE_LIBRARIES = $(OPENMODELICAHOME)/lib/omc/cpp/vxworks/SimCore.a

      IDE_DEFINES = -DCPU=_VX_$(CPU) -DTOOL_FAMILY=$(TOOL_FAMILY) -DTOOL=$(TOOL) -D_WRS_KERNEL -D_VSB_CONFIG_FILE=\"$(VSB_DIR)/h/config/vsbConfig.h\"



      #BuildTool flags
      ifeq ($(DEBUG_MODE),1)
      DEBUGFLAGS_C-Compiler = -g
      DEBUGFLAGS_C++-Compiler = -g
      DEBUGFLAGS_Linker = -g
      DEBUGFLAGS_Partial-Image-Linker =
      DEBUGFLAGS_Librarian =
      DEBUGFLAGS_Assembler = -g
      else
      DEBUGFLAGS_C-Compiler =  -O2
      DEBUGFLAGS_C++-Compiler =  -O2
      DEBUGFLAGS_Linker =  -O2
      DEBUGFLAGS_Partial-Image-Linker =
      DEBUGFLAGS_Librarian =
      DEBUGFLAGS_Assembler =  -O2
      endif


      #Project Targets
      PROJECT_TARGETS = com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME).out \
      <%\t%>com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME)_partialImage.o


      #Rules

      # com.boschrexroth.$(MODEL_NAME)
      ifeq ($(DEBUG_MODE),1)
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : DEBUGFLAGS_C-Compiler = -g
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : DEBUGFLAGS_C++-Compiler = -g
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : DEBUGFLAGS_Linker = -g
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : DEBUGFLAGS_Partial-Image-Linker =
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : DEBUGFLAGS_Librarian =
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : DEBUGFLAGS_Assembler = -g
      else
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : DEBUGFLAGS_C-Compiler =  -O2
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : DEBUGFLAGS_C++-Compiler =  -O2
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : DEBUGFLAGS_Linker =  -O2
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : DEBUGFLAGS_Partial-Image-Linker =
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : DEBUGFLAGS_Librarian =
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : DEBUGFLAGS_Assembler =  -O2
      endif
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : IDE_INCLUDES = -I$(WIND_BASE)/target/h -I$(WIND_BASE)/target/h/wrn/coreip -I$(MLPI_SDK_01)/mlpiCore/include -I$(OPENMODELICAHOME)/include/omc/cpp -I$(OPENMODELICAHOME)/include/omc/cpp/Core -I$(OPENMODELICAHOME)/include/omc/cpp
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : IDE_LIBRARIES = $(OPENMODELICAHOME)/lib/omc/cpp/vxworks/SimCore.a
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : IDE_DEFINES = -DCPU=_VX_$(CPU) -DTOOL_FAMILY=$(TOOL_FAMILY) -DTOOL=$(TOOL) -D_WRS_KERNEL -D_VSB_CONFIG_FILE=\"$(VSB_DIR)/h/config/vsbConfig.h\"
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : PROJECT_TYPE = DKM
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : DEFINES =
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : EXPAND_DBG = 0
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : VX_CPU_FAMILY = pentium
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : CPU = ATOM
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : TOOL_FAMILY = gnu
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : TOOL = gnu
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : TOOL_PATH = $(WIND_HOME)/gnu/4.3.3-vxworks-6.9/x86-win32/bin/
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : CC_ARCH_SPEC = -march=atom -nostdlib -fno-builtin -fno-defer-pop -fno-implicit-fp
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : VSB_DIR = $(WIND_BASE)/target/lib
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : VSB_CONFIG_FILE = $(VSB_DIR)/h/config/vsbConfig.h
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : LIBPATH =
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : LIBS =
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : OBJ_DIR := com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)

      OBJECTS_com.boschrexroth.$(MODEL_NAME) = com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME)_partialImage.o

      ifeq ($(TARGET_JOBS),1)
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME).out : $(OBJECTS_com.boschrexroth.$(MODEL_NAME))
      <%\t%>$(TRACE_FLAG)if [ ! -d "`dirname "$@"`" ]; then mkdir -p "`dirname "$@"`"; fi;echo "building $@";rm -f "$@";nmpentium $(OBJECTS_com.boschrexroth.$(MODEL_NAME)) | $(WIND_HOME)/workbench-3.3/foundation/x86-win32/bin/tclsh $(WIND_BASE)/host/resource/hutils/tcl/munch.tcl -c pentium -tags $(VSB_DIR)/tags/pentium/ATOM/common/dkm.tags > $(OBJ_DIR)/ctdt.c; $(TOOL_PATH)ccpentium $(DEBUGFLAGS_Linker) $(CC_ARCH_SPEC) -fdollars-in-identifiers -Wall -Wsystem-headers  $(ADDED_CFLAGS) $(IDE_INCLUDES) $(ADDED_INCLUDES)  $(IDE_DEFINES) $(DEFINES) -o $(OBJ_DIR)/ctdt.o -c $(OBJ_DIR)/ctdt.c; $(TOOL_PATH)ccpentium -r -nostdlib -Wl,-X -T $(WIND_BASE)/target/h/tool/gnu/ldscripts/link.OUT -o "$@" $(OBJ_DIR)/ctdt.o $(OBJECTS_com.boschrexroth.$(MODEL_NAME)) $(IDE_LIBRARIES) $(LIBPATH) $(LIBS) $(ADDED_LIBPATH) $(ADDED_LIBS) && if [ "$(EXPAND_DBG)" = "1" ]; then plink "$@";fi

      else
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME).out : com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME).out_jobs

      endif
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME)_compile_file : $(FILE) ;

      _clean :: com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME)_clean

      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME)_clean :
      <%\t%>$(TRACE_FLAG)if [ -d "com.boschrexroth.$(MODEL_NAME)" ]; then cd "com.boschrexroth.$(MODEL_NAME)"; rm -rf $(MODE_DIR); fi


      # com.boschrexroth.$(MODEL_NAME)_partialImage
      ifeq ($(DEBUG_MODE),1)
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : DEBUGFLAGS_C-Compiler = -g
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : DEBUGFLAGS_C++-Compiler = -g
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : DEBUGFLAGS_Linker = -g
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : DEBUGFLAGS_Partial-Image-Linker =
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : DEBUGFLAGS_Librarian =
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : DEBUGFLAGS_Assembler = -g
      else
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : DEBUGFLAGS_C-Compiler =  -O2
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : DEBUGFLAGS_C++-Compiler =  -O2
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : DEBUGFLAGS_Linker =  -O2
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : DEBUGFLAGS_Partial-Image-Linker =
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : DEBUGFLAGS_Librarian =
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : DEBUGFLAGS_Assembler =  -O2
      endif
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : IDE_INCLUDES = -I$(WIND_BASE)/target/h -I$(WIND_BASE)/target/h/wrn/coreip -I$(MLPI_SDK_01)/mlpiCore/include -I$(OPENMODELICAHOME)/include/omc/cpp -I$(OPENMODELICAHOME)/include/omc/cpp/Core -I$(OPENMODELICAHOME)/include/omc/cpp
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : IDE_LIBRARIES = $(OPENMODELICAHOME)/lib/omc/cpp/vxworks/SimCore.a
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : IDE_DEFINES = -DCPU=_VX_$(CPU) -DTOOL_FAMILY=$(TOOL_FAMILY) -DTOOL=$(TOOL) -D_WRS_KERNEL -D_VSB_CONFIG_FILE=\"$(VSB_DIR)/h/config/vsbConfig.h\"
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : PROJECT_TYPE = DKM
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : DEFINES =
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : EXPAND_DBG = 0
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : VX_CPU_FAMILY = pentium
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : CPU = ATOM
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : TOOL_FAMILY = gnu
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : TOOL = gnu
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : TOOL_PATH = $(WIND_HOME)/gnu/4.3.3-vxworks-6.9/x86-win32/bin/
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : CC_ARCH_SPEC = -march=atom -nostdlib -fno-builtin -fno-defer-pop -fno-implicit-fp
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : VSB_DIR = $(WIND_BASE)/target/lib
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : VSB_CONFIG_FILE = $(VSB_DIR)/h/config/vsbConfig.h
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : LIBPATH =
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : LIBS =
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : OBJ_DIR := com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)



      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/Objects/com.boschrexroth.$(MODEL_NAME)/OMCpp$(MODEL_NAME)CalcHelperMain.o : OMCpp$(MODEL_NAME)CalcHelperMain.cpp $(FORCE_FILE_BUILD)
      <%\t%>$(TRACE_FLAG)if [ ! -d "`dirname "$@"`" ]; then mkdir -p "`dirname "$@"`"; fi;echo "building $@"; $(TOOL_PATH)ccpentium $(DEBUGFLAGS_C++-Compiler) $(CC_ARCH_SPEC) -ansi -fno-zero-initialized-in-bss  -Wall -Wsystem-headers   -MD -MP $(IDE_DEFINES) $(DEFINES) $(ADDED_C++FLAGS) $(IDE_INCLUDES) $(ADDED_INCLUDES) -o "$@" -c "$<"


      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/Objects/com.boschrexroth.$(MODEL_NAME)/OMCpp$(MODEL_NAME)Main.o : OMCpp$(MODEL_NAME)Main.cpp $(FORCE_FILE_BUILD)
      <%\t%>$(TRACE_FLAG)if [ ! -d "`dirname "$@"`" ]; then mkdir -p "`dirname "$@"`"; fi;echo "building $@"; $(TOOL_PATH)ccpentium $(DEBUGFLAGS_C++-Compiler) $(CC_ARCH_SPEC) -ansi -fno-zero-initialized-in-bss  -Wall -Wsystem-headers   -MD -MP $(IDE_DEFINES) $(DEFINES) $(ADDED_C++FLAGS) $(IDE_INCLUDES) $(ADDED_INCLUDES) -o "$@" -c "$<"


      OBJECTS_com.boschrexroth.$(MODEL_NAME)_partialImage = com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/Objects/com.boschrexroth.$(MODEL_NAME)/OMCpp$(MODEL_NAME)CalcHelperMain.o \
      <%\t%>com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/Objects/com.boschrexroth.$(MODEL_NAME)/OMCpp$(MODEL_NAME)Main.o

      ifeq ($(TARGET_JOBS),1)
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME)_partialImage.o : $(OBJECTS_com.boschrexroth.$(MODEL_NAME)_partialImage)
      <%\t%>$(TRACE_FLAG)if [ ! -d "`dirname "$@"`" ]; then mkdir -p "`dirname "$@"`"; fi;echo "building $@"; $(TOOL_PATH)ccpentium -r -nostdlib -Wl,-X  -o "$@" $(OBJECTS_com.boschrexroth.$(MODEL_NAME)_partialImage) $(ADDED_OBJECTS) $(IDE_LIBRARIES) $(LIBPATH) $(LIBS) $(ADDED_LIBPATH) $(ADDED_LIBS) && if [ "$(EXPAND_DBG)" = "1" ]; then plink "$@";fi

      else
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME)_partialImage.o : com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME)_partialImage.o_jobs

      endif
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME)_partialImage_compile_file : $(FILE) ;

      _clean :: com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME)_partialImage_clean

      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME)_partialImage_clean :
      <%\t%>$(TRACE_FLAG)if [ -d "com.boschrexroth.$(MODEL_NAME)_partialImage" ]; then cd "com.boschrexroth.$(MODEL_NAME)_partialImage"; rm -rf $(MODE_DIR); fi

      force :

      TARGET_JOBS_RULE?=echo "Update the makefile template via File > Import > Build Settings : Update makefile template";exit 1
      %_jobs :
      <%\t%>$(TRACE_FLAG)$(TARGET_JOBS_RULE)

      DEP_FILES := com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/Objects/com.boschrexroth.$(MODEL_NAME)/OMCpp$(MODEL_NAME)CalcHelperMain.d com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/Objects/com.boschrexroth.$(MODEL_NAME)/OMCpp$(MODEL_NAME)Main.d
      -include $(DEP_FILES)


      WIND_SCOPETOOLS_BASE := $(subst \,/,$(WIND_SCOPETOOLS_BASE))

      clean_scopetools :
      <%\t%>$(TRACE_FLAG)rm -rf .coveragescope/db

      CLEAN_STEP := clean_scopetools


      #-include *.makefile

      #-include *.makefile

      TARGET_JOBS_RULE=$(MAKE) -f $(MAKEFILE) --jobs $(TARGET_JOBS) $(MFLAGS) $* TARGET_JOBS=1
      ifeq ($(JOBS),1)
      main_all : external_build  $(PROJECT_TARGETS)
      <%\t%>@echo "make: built targets of `pwd`"
      else
      main_all : external_build
      <%\t%>@$(MAKE) -f $(MAKEFILE) --jobs $(JOBS) $(MFLAGS) $(PROJECT_TARGETS) TARGET_JOBS=1 &&\
      <%\t%>echo "make: built targets of `pwd`"
      endif

      # entry point for extending the build
      external_build ::
      <%\t%>@echo ""

      # main entry point for pre processing prior to the build
      pre_build :: $(PRE_BUILD_STEP) generate_sources
      <%\t%>@echo ""

      # entry point for generating sources prior to the build
      generate_sources ::
      <%\t%>@echo ""

      # main entry point for post processing after the build
      post_build :: $(POST_BUILD_STEP) deploy_output
      <%\t%>@echo ""

      # entry point for deploying output after the build
      deploy_output ::
      <%\t%>@echo ""

      clean :: external_clean $(CLEAN_STEP) _clean

      # entry point for extending the build clean
      external_clean ::
      <%\t%>@echo ""

      >>
end match
end simulationMakefile;



template simulationCppFile(SimCode simCode, Context context, Text updateFunctionsCode, Text indexForUndefinedReferencesReal, Text indexForUndefinedReferencesInt, Text indexForUndefinedReferencesBool,
                           Text indexForUndefinedReferencesString, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text additionalConstructorVarDefs, Text additionalConstructorBodyStatements,
                           Text additionalDestructorBodyStatements, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  /* Generates the c++ code for the model class, containing all equations, the evaluate methods for the time integration algorithm and variable definitions.
     Some getter and setter functions are generated as well. Additional functions can be passed via the "extraFuncs" variable. */
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let className = lastIdentOfPath(modelInfo.name)
  let &additionalConstructorVarDefsBuffer = buffer additionalConstructorVarDefs
  let memberVariableInitialize = memberVariableInitialize(modelInfo, varToArrayIndexMapping, indexForUndefinedReferencesReal, indexForUndefinedReferencesInt, indexForUndefinedReferencesBool, indexForUndefinedReferencesString, Flags.isSet(Flags.GEN_DEBUG_SYMBOLS), useFlatArrayNotation, additionalConstructorVarDefsBuffer, extraFuncsDecl)
  let constVariableInitialize = simulationInitFile(simCode, &extraFuncsDecl, stateDerVectorName, false)
    <<
    #if defined(__TRICORE__) || defined(__vxworks)
      #include <Core/DataExchange/SimDouble.h>
    #endif

    /* Constructor */
    <%className%>::<%className%>(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects)
        : SystemDefaultImplementation(globalSettings, simObjects, "<%className%>")
        , _algLoopSolverFactory(simObjects->getAlgLoopSolverFactory())
        , _pointerToRealVars(getSimVars()->getRealVarsVector())
        , _pointerToIntVars(getSimVars()->getIntVarsVector())
        , _pointerToBoolVars(getSimVars()->getBoolVarsVector())
        , _pointerToStringVars(getSimVars()->getStringVarsVector())
        <%additionalConstructorVarDefsBuffer%>
    {
        <%generateSimulationCppConstructorContent(simCode, context, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
        <%additionalConstructorBodyStatements%>
    }

    <%className%>::<%className%>(<%className%> &instance) : SystemDefaultImplementation(instance)
        , _algLoopSolverFactory(instance.getAlgLoopSolverFactory())
        , _pointerToRealVars(getSimVars()->getRealVarsVector())
        , _pointerToIntVars(getSimVars()->getIntVarsVector())
        , _pointerToBoolVars(getSimVars()->getBoolVarsVector())
        , _pointerToStringVars(getSimVars()->getStringVarsVector())
        <%additionalConstructorVarDefsBuffer%>
    {
        <%generateSimulationCppConstructorContent(simCode, context, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
        <%additionalConstructorBodyStatements%>
    }

    /* Destructor */
    <%className%>::~<%className%>()
    {
      deleteObjects();
      <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
        let numOfEqs = SimCodeUtil.getMaxSimEqSystemIndex(simCode)
        <<
        #ifdef MEASURETIME_PROFILEBLOCKS
        delete measuredProfileBlockStartValues;
        delete measuredProfileBlockEndValues;
        #endif //MEASURETIME_PROFILEBLOCKS

        #ifdef MEASURETIME_MODELFUNCTIONS
        delete measuredFunctionStartValues;
        delete measuredFunctionEndValues;
        #endif //MEASURETIME_MODELFUNCTIONS
        >>
      %>
      <%additionalDestructorBodyStatements%>
    }

    void <%className%>::deleteObjects()
    {

      if(_functions != NULL)
        delete _functions;

      deleteAlgloopSolverVariables();
    }

    shared_ptr<IAlgLoopSolverFactory> <%className%>::getAlgLoopSolverFactory()
    {
        return _algLoopSolverFactory;
    }

    <%generateInitAlgloopsolverVariables(jacobianMatrixes,listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,className)%>

    <%generateDeleteAlgloopsolverVariables(jacobianMatrixes,listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,className)%>

    <%updateFunctionsCode%>

    <%DefaultImplementationCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>

    <%checkForDiscreteEvents(discreteModelVars,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,stateDerVectorName,useFlatArrayNotation)%>
    <%giveZeroFunc1(zeroCrossings,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>

    <%setConditions(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
    <%getConditions(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
    <%isConsistent(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>

    <%generateStepCompleted(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
    <%generateStepStarted(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,useFlatArrayNotation)%>

    <%generateRestoreOldValues(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
    <%generateRestoreNewValues(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>

    <%generatehandleTimeEvent(timeEvents, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")))%>
    <%generateDimTimeEvent(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
    <%generateTimeEvent(timeEvents, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, true)%>

    <%isODE(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
    <%dimZeroFunc(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>

    <%getCondition(zeroCrossings,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>

    <%saveAll(modelInfo,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,stateDerVectorName,useFlatArrayNotation)%>


    <%labeledDAE(modelInfo.labels,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
    <%giveVariables(modelInfo, context,useFlatArrayNotation,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,stateDerVectorName)%>

    <%memberVariableInitialize%>
    <%constVariableInitialize%>
    <%extraFuncs%>
    >>
end simulationCppFile;

template partitionInfoInit(Integer numPartitions, Integer numStates, list<Integer> stateActivators)
::=
  let stateActs = (stateActivators |> act hasindex i0 => '_stateActivator[<%i0%>] = <%intSub(act,1)%>;' ;separator="\n")
  <<
  //partitioning of the system, all partitions are active at t0
  _dimPartitions = <%numPartitions%>;
  _partitionActivation = new bool[_dimPartitions]();
  memset(_partitionActivation,true,_dimPartitions*sizeof(bool));
  _stateActivator = new int[<%numStates%>]();
  <%stateActs%>
  >>
end partitionInfoInit;

template generateSimulationCppConstructorContent(SimCode simCode, Context context, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match simCode
  case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__)), partitionData=PARTITIONDATA(__)) then
    let className = lastIdentOfPath(modelInfo.name)
    let partitionInit = if Flags.isSet(Flags.MULTIRATE_PARTITION) then partitionInfoInit(partitionData.numPartitions, vi.numStateVars, partitionData.stateToActivators) else ""
      <<
      defineConstVals();
      defineStateVars();
      defineDerivativeVars();
      defineAlgVars();
      defineDiscreteAlgVars();
      defineIntAlgVars();
      defineBoolAlgVars();
      defineStringAlgVars();
      defineParameterRealVars();
      defineParameterIntVars();
      defineParameterBoolVars();
      defineParameterStringVars();
      defineAliasRealVars();
      defineAliasIntVars();
      defineAliasBoolVars();
      defineAliasStringVars();

      //Number of equations
      <%dimension1(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
      _dimZeroFunc = <%zeroCrossLength(simCode)%>;
      _dimClock = <%listLength(getSubPartitions(clockedPartitions))%>;
      // simplified treatment of clocks in model as time events
      _dimTimeEvent = <%timeEventLength(simCode)%>  + _dimClock;
      //Number of residues
       _event_handling= shared_ptr<EventHandling>(new EventHandling());
       initializeAlgloopSolverVariables(); //if we do not initialize it here, we get a segfault in the destructor if initialization of Solver or OMFactory has failed
      <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then
      <<
      _dimResidues = <%numResidues(allEquations)%>;
      >>
      %>
      <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
            let numOfEqs = SimCodeUtil.getMaxSimEqSystemIndex(simCode)
            <<
            #ifdef MEASURETIME_PROFILEBLOCKS
            measureTimeProfileBlocksArray = new std::vector<MeasureTimeData*>(size_t(<%numOfEqs%>), NULL);
            for(int i = 0; i < <%numOfEqs%>; i++)
            {
                ostringstream ss;
                ss << (i+1);
                (*measureTimeProfileBlocksArray)[i] = new MeasureTimeData(ss.str());
            }

            MeasureTime::addResultContentBlock("<%dotPath(modelInfo.name)%>","profileBlocks",measureTimeProfileBlocksArray);
            measuredProfileBlockStartValues = MeasureTime::getZeroValues();
            measuredProfileBlockEndValues = MeasureTime::getZeroValues();
            #endif //MEASURETIME_PROFILEBLOCKS

            #ifdef MEASURETIME_MODELFUNCTIONS
            measureTimeFunctionsArray = new std::vector<MeasureTimeData*>(size_t(5), NULL); //1 evaluateODE ; 2 evaluateAll; 3 writeOutput; 4 handleTimeEvents; 5 evaluateZeroFuncs
            MeasureTime::addResultContentBlock("<%dotPath(modelInfo.name)%>","functions",measureTimeFunctionsArray);
            (*measureTimeFunctionsArray)[0] = new MeasureTimeData("evaluateODE");
            (*measureTimeFunctionsArray)[1] = new MeasureTimeData("evaluateAll");
            (*measureTimeFunctionsArray)[2] = new MeasureTimeData("writeOutput");
            (*measureTimeFunctionsArray)[3] = new MeasureTimeData("handleTimeEvents");
            (*measureTimeFunctionsArray)[4] = new MeasureTimeData("evaluateZeroFuncs");

            measuredFunctionStartValues = MeasureTime::getZeroValues();
            measuredFunctionEndValues = MeasureTime::getZeroValues();
            #endif //MEASURETIME_MODELFUNCTIONS
            >>
        %>

        <%partitionInit%>

        //Initialize the state vector
        SystemDefaultImplementation::initialize();
        //Instantiate auxiliary object for event handling functionality
        //_event_handling.getCondition =  boost::bind(&<%className%>::getCondition, this, _1);

        //Todo: reindex all arrays removed  // arrayReindex(modelInfo,useFlatArrayNotation)

        _functions = new Functions(_simTime,__z,__zDot,_initial,_terminate);
        >>

end generateSimulationCppConstructorContent;

template algloopCppFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,SimEqSystem eq, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for algloop system ."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
   let modelname =  lastIdentOfPath(modelInfo.name)
   let filename = fileNamePrefix
   let modelfilename =  match context case  ALGLOOP_CONTEXT(genInitialisation=false,genJacobian=true)  then '<%filename%>Jacobian' else '<%filename%>'
   let &varDecls = buffer ""
   let &arrayInit = buffer ""
   let constructorParams = constructorParamAlgloop(modelInfo, useFlatArrayNotation)
   let iniAlgloopParamas = initAlgloopParams(modelInfo,arrayInit,useFlatArrayNotation)
   let systemname = match context case ALGLOOP_CONTEXT(genInitialisation=false,genJacobian=true)  then '<%modelname%>Jacobian' else '<%modelname%>'
   match eq
   case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
   <<
   <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then '#include "Math/ArrayOperations.h"'%>

   <%modelname%>Algloop<%ls.index%>::<%modelname%>Algloop<%ls.index%>(<%systemname%>* system, double* z, double* zDot, bool* conditions, shared_ptr<DiscreteEvents> discrete_events)
       : AlgLoopDefaultImplementation()
       , _system(system)
       , __z(z)
       , __zDot(zDot)
   <% match eq
     case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
     let size = listLength(ls.vars)
     let nonzeros = listLength(ls.simJac)
     let type = getConfigString(MATRIX_FORMAT)
     let helpdata = match ls.jacobianMatrix
     case SOME(__) then
     <<
     >>
     else
     <<
     _AData = new double[<%listLength(ls.simJac)%>];
     _bInitialized = false;
     _indexValue = new int[<%listLength(ls.simJac)%>];
     sortIndex();
     >>

      let inits =   match type
          case ("dense") then
            <<
            ,__A(ublas::zero_matrix<double>(<%size%>,<%size%>))
            , _useSparseFormat(false)
            , _conditions(conditions)
            , _discrete_events(discrete_events)
            , _functions(system->_functions)
            , _indexValue(NULL)
            {
              <%initAlgloopDimension(eq,varDecls)%>
            >>
          case ("sparse") then
            <<
            ,__A(<%size%>,<%size%>,<%nonzeros%>)
            , _useSparseFormat(true)
            , _conditions(conditions)
            , _discrete_events(discrete_events)
            , _functions(system->_functions)
            , _indexValue(NULL)
            {
              <%initAlgloopDimension(eq,varDecls)%>
              <%helpdata%>
            >>
          else "A matrix type is not supported"
          end match
     <<
     <%inits%>

       <%initAlgloopVarAttributes(eq, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)%>
     >>
    %>
   }

   <%modelname%>Algloop<%ls.index%>::~<%modelname%>Algloop<%ls.index%>()
   {
     if (_AData)
       delete [] _AData;
   }

   bool <%modelname%>Algloop<%ls.index%>::getUseSparseFormat()
   {
     return _useSparseFormat;
   }

   void <%modelname%>Algloop<%ls.index%>::setUseSparseFormat(bool value)
   {
     _useSparseFormat = value;
   }

   void <%modelname%>Algloop<%ls.index%>::getSparseAdata(double* data, int nonzeros)
   {
     memcpy(data, _AData, sizeof(double) * nonzeros);
   }

   <%algloopRHSCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>
   <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then algloopResiduals(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>
   <%initAlgloop(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, eq, context, stateDerVectorName, useFlatArrayNotation)%>
   <%queryDensity(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq,context, useFlatArrayNotation)%>
   <%updateAlgloop(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq,context, stateDerVectorName, useFlatArrayNotation)%>
   <%upateAlgloopNonLinear(simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, eq, context, stateDerVectorName, useFlatArrayNotation)%>

   <%algloopDefaultImplementationCode(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, eq, context, stateDerVectorName, useFlatArrayNotation)%>
   <%getAMatrixCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>
   <%isLinearCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>
   <%isLinearTearingCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>

   >>

   case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
   <<

   <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then '#include "Math/ArrayOperations.h"'%>

   <%modelname%>Algloop<%nls.index%>::<%modelname%>Algloop<%nls.index%>(<%systemname%>* system, double* z, double* zDot, bool* conditions, shared_ptr<DiscreteEvents> discrete_events)
       : AlgLoopDefaultImplementation()
       , _system(system)
       , __z(z)
       , __zDot(zDot)
       , _useSparseFormat(false)
       , _conditions(conditions)
       , _discrete_events(discrete_events)
       , _functions(system->_functions)
   {
     <%initAlgloopDimension(eq,varDecls)%>

     <%initAlgloopVarAttributes(eq, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)%>
   }

   <%modelname%>Algloop<%nls.index%>::~<%modelname%>Algloop<%nls.index%>()
   {

   }

   bool <%modelname%>Algloop<%nls.index%>::getUseSparseFormat()
   {
     return _useSparseFormat;
   }

   void <%modelname%>Algloop<%nls.index%>::setUseSparseFormat(bool value)
   {
     _useSparseFormat = value;
   }

   void <%modelname%>Algloop<%nls.index%>::getSparseAdata(double* data, int nonzeros)
   {
     throw ModelicaSimulationError(ALGLOOP_EQ_SYSTEM,"Adata not used in nonlinear algloop");
   }
   <%algloopRHSCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>
   <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then algloopResiduals(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>
   <%initAlgloop(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, eq, context, stateDerVectorName, useFlatArrayNotation)%>

   <%queryDensity(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq,context, useFlatArrayNotation)%>
   <%updateAlgloop(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq,context, stateDerVectorName, useFlatArrayNotation)%>
   <%upateAlgloopNonLinear(simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, eq, context, stateDerVectorName, useFlatArrayNotation)%>

   <%algloopDefaultImplementationCode(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, eq, context, stateDerVectorName, useFlatArrayNotation)%>
   <%getAMatrixCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>
   <%isLinearCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>
   <%isLinearTearingCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>

   >>
end algloopCppFile;

template queryDensity(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, SimEqSystem eqn, Context context,Boolean useFlatArrayNotation)
::=
match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
    let modelname = lastIdentOfPath(modelInfo.name)
    match eqn
      case eq as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
       <<
       float <%modelname%>Algloop<%nls.index%>::queryDensity()
       {
         return -1.;
       }
       >>
      case eq as SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
      match ls.jacobianMatrix
        case SOME(__) then
        <<
        float <%modelname%>Algloop<%ls.index%>::queryDensity()
        {
          return -1.;
        }
        >>
       else
      let size=listLength(ls.simJac)
      <<
      float <%modelname%>Algloop<%ls.index%>::queryDensity()
      {
        return 100.*<%size%>./_dimAEq/_dimAEq;
      }
      >>
end queryDensity;


template updateAlgloop(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,SimEqSystem eqn,Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
    let modelname = lastIdentOfPath(modelInfo.name)
    match eqn
      /*case eq as SES_NONLINEAR(__) then
        <<
        void <%modelname%>Algloop<%index%>::evaluate()
        {
           if(_useSparseFormat)
             evaluate(NULL);
           else
             evaluate(NULL);
        }
        >>
      */
  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
    let type = getConfigString(MATRIX_FORMAT)
    match ls.jacobianMatrix
       case SOME(__) then
         let &varDecls = buffer "" /*BUFD*/

     let prebody = (ls.residual |> eq2 =>
         functionExtraResidualsPreBody(eq2, &varDecls, context, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     ;separator="\n")
     let body = (ls.residual |> eq2 as SES_RESIDUAL(__) hasindex i0 =>
         let &preExp = buffer "" /*BUFD*/
         let expPart = daeExp(eq2.exp, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
         '<%preExp%>__xd[<%i0%>] = <%expPart%>;'

       ;separator="\n")
        <<

        void <%modelname%>Algloop<%ls.index%>::evaluate()
        {
           <%varDecls%>
           //prebody
           <%prebody%>
           //body
           <%body%>
        }
        >>
     else

        /*<<
        void <%modelname%>Algloop<%ls.index%>::evaluate()
        {
            deactivated: should be generated with code generation flag usematrix_t
           if(_useSparseFormat)
           {
             if(! __Asparse)
                __Asparse = shared_ptr<matrix_t>( new matrix_t);

             evaluate(__Asparse.get());
           }
           else
           {
             if(! __A )
                __A = shared_ptr<AMATRIX>( new AMATRIX());

             evaluate(__A.get());
           }



        }
        >>*/
     let uid = System.tmpTick()
  let size = listLength(ls.vars)
  let aname = 'A<%uid%>'
  let bname = 'b<%uid%>'
    let &varDecls = buffer "" /*BUFD*/

let &help = buffer ""
 let Amatrix=
    (ls.simJac |> (row, col, eq as SES_RESIDUAL(__)) hasindex i0 fromindex 0=>
      let &preExp = buffer "" /*BUFD*/
    let expPart = daeExp(eq.exp, context, &preExp, &varDecls, simCode, &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      match eq.exp
      case e as RCONST(__) then match type case "sparse" then
      let &help +=
      <<
      <%preExp%>
      /*comment out again!*///__A(<%row%>,<%col%>)=<%expPart%>;
      _AData[_indexValue[<%i0%>]] = <%expPart%>;
      >>
      <<
      <%preExp%>
      /*comment out again!*///__A(<%row%>,<%col%>)=<%expPart%>;
      //_AData[_indexValue[<%i0%>]] = <%expPart%>;
      >>
    else
    <<
    <%preExp%>
    /*comment out again!*/__A(<%row%>,<%col%>)=<%expPart%>;
    >>
    end match
      else match type case "sparse" then
    <<
    <%preExp%>
    /*comment out again!*///__A(<%row%>,<%col%>)=<%expPart%>;
    //_Ax[<%i0%>] = <%expPart%>;// to be commented in lateron
    _AData[_indexValue[<%i0%>]] = <%expPart%>;
    >>
    else
    <<
    <%preExp%>
    __A(<%row%>,<%col%>)=<%expPart%>;
    >>
    end match

  ;separator="\n")

 let bvector =  (ls.beqs |> exp hasindex i0 fromindex 1=>
     let &preExp = buffer "" /*BUFD*/
     let expPart = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     match exp
   case e as RCONST(__) then
   let &help +=  '/*comment out again!*/<%preExp%>__b(<%i0%>)=<%expPart%>; <%\n%>'
   <<
   //<%preExp%>__b(<%i0%>)=<%expPart%>;
   >>
   else

  '<%preExp%>__b(<%i0%>)=<%expPart%>;'
  ;separator="\n")

  <<
  void <%modelname%>Algloop<%ls.index%>::evaluate()
  {
      <%varDecls%>
      <%Amatrix%>
      //memcpy(Ax,_AData,sizeof(double)* <%listLength(ls.simJac)%> );
      <%bvector%>
      if (_bInitialized == false)
      {
        <%&help%>
        _bInitialized = true;
      }
  }
  >>
end updateAlgloop;

template upateAlgloopNonLinear(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, SimEqSystem eqn, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  "Generates functions in simulation file."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  //let () = System.tmpTickReset(0)
  let modelname = lastIdentOfPath(modelInfo.name)
  match eqn
     //case eq as SES_MIXED(__) then functionExtraResiduals(fill(eq.cont,1),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
     case eq as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
     let &varDecls = buffer "" /*BUFD*/
     /*let algs = (nls.eqs |> eq2 as SES_ALGORITHM(__) =>
         equation_(eq2, context, &varDecls ,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, useFlatArrayNotation)
       ;separator="\n")
     let prebody = (nls.eqs |> eq2 as SES_SIMPLE_ASSIGN(__) =>
         equation_(eq2, context, &varDecls ,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, useFlatArrayNotation)
       ;separator="\n")*/
     let prebody = (nls.eqs |> eq2 =>
         functionExtraResidualsPreBody(eq2, &varDecls, context, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     ;separator="\n")
     let body = (nls.eqs |> eq2 as SES_RESIDUAL(__) hasindex i0 =>
         let &preExp = buffer "" /*BUFD*/
         let expPart = daeExp(eq2.exp, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
         '<%preExp%>__xd[<%i0%>] = <%expPart%>;'

       ;separator="\n")


   <<
   <% match eq
   case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
   <<
   void <%modelname%>Algloop<%nls.index%>::evaluate()
   >>
   %>
   {
        <%varDecls%>

        //prebody
        <%prebody%>
        //body
        <%body%>
   }
   >>
end upateAlgloopNonLinear;

template functionExtraResidualsPreBody(SimEqSystem eq, Text &varDecls, Context context, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                                       Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates an equation."
::=
  match eq
  case e as SES_RESIDUAL(__)
  then ""
  else
  equation_(eq, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  end match
end functionExtraResidualsPreBody;



template upateAlgloopLinear(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, SimEqSystem eqn, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates functions in simulation file."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  //let () = System.tmpTickReset(0)
  let modelname = lastIdentOfPath(modelInfo.name)
 match eqn
 case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
  match ls.jacobianMatrix
       case SOME(__) then
         ""
  else

  let uid = System.tmpTick()
  let size = listLength(ls.vars)
  let aname = 'A<%uid%>'
  let bname = 'b<%uid%>'
    let &varDecls = buffer "" /*BUFD*/

 let Amatrix=
    (ls.simJac |> (row, col, eq as SES_RESIDUAL(__)) =>
      let &preExp = buffer "" /*BUFD*/
      let expPart = daeExp(eq.exp, context, &preExp, &varDecls, simCode, &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      '<%preExp%>(*__A)(<%row%>+1,<%col%>+1)=<%expPart%>;'
  ;separator="\n")

 let bvector =  (ls.beqs |> exp hasindex i0 fromindex 1=>
     let &preExp = buffer "" /*BUFD*/
     let expPart = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     '<%preExp%>__b(<%i0%>)=<%expPart%>;'
  ;separator="\n")

  <<
  template <typename T>
  void <%modelname%>Algloop<%ls.index%>::evaluate(T* __A)
  {
      <%varDecls%>
      <%Amatrix%>
      <%bvector%>
  }
  >>
end upateAlgloopLinear;

template functionBodies(list<Function> functions, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates the body for a set of functions."
::=
  (functions |> fn => functionBody(fn, false,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator="\n")
end functionBodies;

template functionBody(Function fn, Boolean inFunc, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates the body for a function."
::=
match fn
  /*workarround until we support these functions*/
  case fn as FUNCTION(__)
  case fn as EXTERNAL_FUNCTION(__)
  case fn as RECORD_CONSTRUCTOR(__)
  then
  let fname = underscorePath(name)
     match fname
        case "OpenModelica_Scripting_regexBool"
            then ""
       case  "Modelica_Utilities_Files_loadResource"
            then ""
       case  "OpenModelica_Scripting_directoryExists"
           then ""
       case "OpenModelica_Scripting_uriToFilename"
          then ""
       case "OpenModelica_Scripting_Internal_stat"
             then ""
       case "OpenModelica_Scripting_realpath"
              then ""
       case "OpenModelica_Scripting_regex"
             then ""
       else
 /* end workarround */
  match fn
  case fn as FUNCTION(__)           then functionBodyRegularFunction(fn, inFunc,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case fn as EXTERNAL_FUNCTION(__)  then functionBodyExternalFunction(fn, inFunc,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case fn as RECORD_CONSTRUCTOR(__) then functionBodyRecordConstructor(fn,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,useFlatArrayNotation)
end functionBody;

template externfunctionHeaderDefinition(list<Function> functions)
 "Generates the body for a set of functions."
::=
  (functions |> fn => extFunDef(fn) ;separator="\n")
end externfunctionHeaderDefinition;

template functionHeaderBodies1(list<Function> functions, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text& dummyElemTypeCreation, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates the body for a set of functions."
::=
  match simCode
    case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
      let recorddecls = (recordDecls |> rd => recordDeclarationHeader(rd,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, dummyElemTypeCreation, useFlatArrayNotation) ;separator="\n")
      let rettypedecls =  (functions |> fn => functionHeaderBody1(fn,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator="\n")
      <<
      <%recorddecls%>
      <%rettypedecls%>
      >>
end functionHeaderBodies1;

template functionHeaderBody1(Function fn, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates the body for a function."
::=
  match fn
  /*workarroung until we support these functions*/
  case fn as FUNCTION(__)
  case fn as EXTERNAL_FUNCTION(__)
  case fn as RECORD_CONSTRUCTOR(__)
  then
  let fname = underscorePath(name)
     match fname
        case "OpenModelica_Scripting_regexBool"
            then ""
       case  "Modelica_Utilities_Files_loadResource"
            then ""
       case  "OpenModelica_Scripting_directoryExists"
           then ""
       case "OpenModelica_Scripting_uriToFilename"
          then ""
       case "OpenModelica_Scripting_Internal_stat"
             then ""
       case "OpenModelica_Scripting_realpath"
              then ""
       case "OpenModelica_Scripting_regex"
             then ""
       else
 /* end workarroung */
  match fn
  case fn as FUNCTION(__)           then functionHeaderRegularFunction1(fn, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case fn as EXTERNAL_FUNCTION(__)  then functionHeaderExternFunction(fn, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)
  case fn as RECORD_CONSTRUCTOR(__) then  functionHeaderRegularFunction1(fn, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
end functionHeaderBody1;

template functionHeaderBodies2(list<Function> functions,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates the body for a set of functions."
::=
  (functions |> fn => functionHeaderBody2(fn,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator="\n")
end functionHeaderBodies2;

template functionHeaderBody2(Function fn,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates the body for a function."
::=
  match fn
  /*workarround until we support these functions*/
  case fn as FUNCTION(__)
  case fn as EXTERNAL_FUNCTION(__)
  case fn as RECORD_CONSTRUCTOR(__)
  then
  let fname = underscorePath(name)
     match fname
        case "OpenModelica_Scripting_regexBool"
            then ""
       case  "Modelica_Utilities_Files_loadResource"
            then ""
       case  "OpenModelica_Scripting_directoryExists"
           then ""
       case "OpenModelica_Scripting_uriToFilename"
          then ""
       case "OpenModelica_Scripting_Internal_stat"
             then ""
       case "OpenModelica_Scripting_realpath"
              then ""
       case "OpenModelica_Scripting_regex"
             then ""
       else
 /* end workarround */
  match fn
  case fn as FUNCTION(__)           then functionHeaderRegularFunction2(fn,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case fn as EXTERNAL_FUNCTION(__)  then functionHeaderRegularFunction2(fn,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case fn as RECORD_CONSTRUCTOR(__) then functionHeaderRecordConstruct(fn,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, useFlatArrayNotation)
end functionHeaderBody2;

template functionHeaderBodies3(list<Function> functions,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates the body for a set of functions."
::=
  (functions |> fn => functionHeaderBody3(fn,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator="\n")
end functionHeaderBodies3;

template functionHeaderBody3(Function fn,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates the body for a function."
::=
match fn
/*workarroung until we support these functions*/
  case fn as FUNCTION(__)
  case fn as EXTERNAL_FUNCTION(__)
  case fn as RECORD_CONSTRUCTOR(__)
  then
  let fname = underscorePath(name)
     match fname
        case "OpenModelica_Scripting_regexBool"
            then ""
       case  "Modelica_Utilities_Files_loadResource"
            then ""
       case  "OpenModelica_Scripting_directoryExists"
           then ""
       case "OpenModelica_Scripting_uriToFilename"
          then ""
       case "OpenModelica_Scripting_Internal_stat"
             then ""
       case "OpenModelica_Scripting_realpath"
              then ""
       case "OpenModelica_Scripting_regex"
             then ""
       else
 /* end workarroung */
  match fn
  case fn as FUNCTION(__)           then /*Function*/functionHeaderRegularFunction3(fn,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
  case fn as EXTERNAL_FUNCTION(__)  then /*External Function*/ functionHeaderRegularFunction3(fn,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
  case fn as RECORD_CONSTRUCTOR(__) then ""
end functionHeaderBody3;


template extFunDef(Function fn)
 "Generates function header for an external function."
::=
match fn

case func as EXTERNAL_FUNCTION(extReturn= return) then
 let fargsStr = extFunDefArgs(extArgs, language)
 match extName
 case "OpenModelica_regex"
 then ""

 else
  match fn
  case func as EXTERNAL_FUNCTION(__) then
  let fargsStrEscaped = '<%escapeCComments(fargsStr)%>'
  let includesStr = includes |> i => i ;separator=", "
  let fn_name = extFunctionName(extName, language)
  /*
   * adrpo:
   *   only declare the external function definition IF THERE WERE NO INCLUDES!
   *   i did not put includesStr string in the comment below as it might include
   *   entire files
   */
  if  includes then
    <<
    /*
     * The function has annotation(Include=...>)
     * the external function definition should be present
     * in one of these files and have this prototype:
     * extern <%extReturnType(extReturn)%> <%fn_name%>(<%fargsStrEscaped%>);
     */
    >>
   else
    <<
    extern <%extReturnType(return)%> <%fn_name%>(<%fargsStr%>);
    >>
  end match
end extFunDef;


template extFunctionName(String name, String language)
::=
  match language
  case "C" then '<%name%>'
  case "FORTRAN 77" then '<%name%>_'
  else error(sourceInfo(), 'Unsupported external language: <%language%>')
end extFunctionName;

template extFunDefArgs(list<SimExtArg> args, String language)
::=
  match language
  case "C"
  case "FORTRAN 77" then
    (args |> arg => extFunDefArg(arg, language); separator=", ")
  else error(sourceInfo(), 'Unsupported external language: <%language%>')
end extFunDefArgs;

template extFunDefArg(SimExtArg extArg, String language)
 "Generates the definition of an external function argument.
  Assume that language is C for now."
::=
  match extArg
  case SIMEXTARG(cref=c, isInput=ii, isArray=ia, type_=t) then
    let name = contextCref2(c,contextFunction)
    let typeStr = extType(t, language, true, ii, ia)
    <<
    <%typeStr%> /*<%name%>*/
    >>
  case SIMEXTARGEXP(__) then
    let typeStr = extType(type_, language, true, true, false)
    <<
    <%typeStr%>
    >>
  case SIMEXTARGSIZE(cref=c) then
    let typeStr = match language case "FORTRAN 77" then 'int*' else 'size_t'
    <<
    <%typeStr%>
    >>
end extFunDefArg;


template extType(Type type, String language, Boolean isReference,
                 Boolean isInput, Boolean isArray)
 "Generates type for external function argument or return value for C or F77."
::=
  match language
  case "C" then extType2(type, isInput, isArray)
  case "FORTRAN 77" then extTypeF77(type, isInput, isReference)
  else error(sourceInfo(), 'Unsupported external language: <%language%>')
end extType;


template extType2(Type type, Boolean isInput, Boolean isArray)
 "Generates type for external function argument or return value."
::=
  let s = match type
  case T_INTEGER(__)         then "int"
  case T_REAL(__)        then "double"
  case T_STRING(__)      then "const char*"
  case T_BOOL(__)        then "int"
  case T_ENUMERATION(__) then "int"
  case T_ARRAY(__)       then extType2(ty,isInput,true)
  case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__))
                      then "void *"
  case T_COMPLEX(complexClassType=RECORD(path=rname))
                      then 'struct <%underscorePath(rname)%>'
  case T_METATYPE(__) case T_METABOXED(__)    then "modelica_metatype"
  else error(sourceInfo(), 'Unknown external C type <%unparseType(type)%>')
  match type case T_ARRAY(__) then s else if isInput then (if isArray then '<%match s case "const char*" then "" else "const "%><%s%>*' else s) else '<%s%>*'
end extType2;


template extTypeF77(Type type, Boolean isInput, Boolean isReference)
  "Generates type for external function argument or return value for F77."
::=
  let s = match type
  case T_INTEGER(__)     then "int"
  case T_REAL(__)        then "double"
  case T_STRING(__)      then "const char*"
  case T_BOOL(__)        then "int"
  case T_ENUMERATION(__) then "int"
  case T_ARRAY(__)       then extTypeF77(ty, isInput, true)
  case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__))
                         then "void*"
  case T_COMPLEX(complexClassType=RECORD(path=rname))
                         then '<%underscorePath(rname)%>'
  case T_METATYPE(__) case T_METABOXED(__) then "void*"
  else error(sourceInfo(), 'Unknown external F77 type <%unparseType(type)%>')
  match type case T_ARRAY(__) case T_STRING(__) then s else if isReference then '<%if isInput then "const "%><%s%>*' else s
end extTypeF77;


template extReturnType(SimExtArg extArg)
 "Generates return type for external function."
::=
  match extArg
  case ex as SIMEXTARG(__)    then extType2(type_,true /*Treat this as an input (pass by value)*/,false)
  case SIMNOEXTARG(__)  then "void"
  case SIMEXTARGEXP(__) then error(sourceInfo(), 'Expression types are unsupported as return arguments <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')
  else error(sourceInfo(), "Unsupported return argument")
end extReturnType;


template functionHeaderRegularFunction1(Function fn, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match fn
 case FUNCTION(outVars={var}) then
 let fname = underscorePath(name)
    << /*default return type*/
    typedef <%funReturnDefinition1(var,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)%>  <%fname%>RetType /* functionHeaderRegularFunction1 */;
    typedef <%funReturnDefinition2(var,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>  <%fname%>RefRetType /* functionHeaderRegularFunction1 */;
    >>


case FUNCTION(outVars= vars as _::_) then

 let fname = underscorePath(name)
    << /*tuple return type*/
    struct <%fname%>Type/*RecordTypeTest*/
    {
      typedef tuple< <%vars |> var => funReturnDefinition1(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator=", "%> > TUPLE_ARRAY;

      <%fname%>Type& operator=(const <%fname%>Type& A)
      {
        <%vars |> var hasindex i0 => tupplearrayassign(var,i0) ;separator="\n "%>
        return *this;
      }
      TUPLE_ARRAY data;
    };
    typedef <%fname%>Type/*RecordTypeTest*/ <%fname%>RetType /* functionHeaderRegularFunction1 */;
    >>

 case RECORD_CONSTRUCTOR(__) then

      let fname = underscorePath(name)

      <<
      typedef <%fname%>Type <%fname%>RetType /* functionHeaderRegularFunction1 */;
      >>
 case PARALLEL_FUNCTION(__) then
    let fname = underscorePath(name)
     <<
     //PARALLEL_FUNCTION
     //typedef <%fname%>Type <%fname%>RetType out of functionHeaderRegularFunction1;
     >>
 case KERNEL_FUNCTION(__) then
    let fname = underscorePath(name)
     <<
     //KERNEL_FUNCTION
     //typedef <%fname%>Type <%fname%>RetType out of functionHeaderRegularFunction1;
     >>
 case EXTERNAL_FUNCTION(__) then
    let fname = underscorePath(name)
     <<
     //EXTERNAL_FUNCTION
     //typedef <%fname%>Type <%fname%>RetType out of functionHeaderRegularFunction1;
     >>
end functionHeaderRegularFunction1;

template tupplearrayassign(Variable var,Integer index)
::=
  match var
  case var as VARIABLE(__) then
  // previous multi_array      if instDims then 'assign_array(get<<%index%>>(data),get<<%index%>>(A.data));' else 'get<<%index%>>(data)= get<<%index%>>(A.data);
     if instDims then '(get<<%index%>>(data)).assign(get<<%index%>>(A.data));' else 'get<<%index%>>(data)= get<<%index%>>(A.data);'
end tupplearrayassign;

template functionHeaderRecordConstruct(Function fn,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
match fn
 case RECORD_CONSTRUCTOR(__) then
      let fname = underscorePath(name)
      let funArgsStr = (funArgs |> var as VARIABLE(__) =>
          '<%varType1(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%> <%crefStr(name)%>'
        ;separator=", ")
      <<
      void /*RecordTypetest*/ <%fname%>(<%funArgsStr%><%if funArgs then "," else ""%><%fname%>Type &output );
      >>
end functionHeaderRecordConstruct;

template functionHeaderExternFunction(Function fn,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match fn
case EXTERNAL_FUNCTION(outVars={var}) then

  let fname = underscorePath(name)
  <<
  typedef  <%funReturnDefinition1(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%> <%fname%>RetType /* functionHeaderExternFunction */;
  >>
 case EXTERNAL_FUNCTION(outVars=_::_) then

  let fname = underscorePath(name)
    << /*tuple return type*/
    struct <%fname%>Type
    {
       typedef tuple< <%outVars |> var => funReturnDefinition1(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator=", "%> > TUPLE_ARRAY;

      <%fname%>Type& operator=(const <%fname%>Type& A)
      {
        <%outVars |> var hasindex i0 => tupplearrayassign(var,i0) ;separator="\n "%>
        return *this;
      }
      TUPLE_ARRAY data;
    };
    typedef <%fname%>Type/*RecordTypeTest*/ <%fname%>RetType /* functionHeaderExternFunction */;
    >>
  /*
  <<
    typedef tuple< <%outVars |> var => funReturnDefinition1(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator=", "%> >  <%fname%>RetType /* functionHeaderExternFunction */;
  >>
  */
 case FUNCTION(outVars= vars as _::_) then
  let fname = underscorePath(name)
  <<
  //FUNCTION
  //typedef <%fname%>Type <%fname%>RetType out of functionHeaderExternFunction;
  >>

 case RECORD_CONSTRUCTOR(__) then
  let fname = underscorePath(name)
  <<
  //RECORD_CONSTRUCTOR
  //typedef <%fname%>Type <%fname%>RetType out of functionHeaderExternFunction;
  >>
 case PARALLEL_FUNCTION(__) then
  let fname = underscorePath(name)
  <<
  //PARALLEL_FUNCTION
  //typedef <%fname%>Type <%fname%>RetType out of functionHeaderExternFunction;
  >>
 case KERNEL_FUNCTION(__) then
  let fname = underscorePath(name)
  <<
  //KERNEL_FUNCTION
  //typedef <%fname%>Type <%fname%>RetType out of functionHeaderExternFunction;
  >>

end functionHeaderExternFunction;

template recordDeclarationHeader(RecordDeclaration recDecl, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text& dummyElemCreation, Boolean useFlatArrayNotation)
 "Generates structs for a record declaration."
::=
  match recDecl
    case r as RECORD_DECL_FULL(__) then
      match aliasName
        case SOME(str) then
          let &dummyElemCreation += '<%r.name%>Type dummy<%r.name%>Type;<%\n%>'
          <<
          typedef <%str%>Type <%r.name%>Type;
          >>
        else
          let &dummyElemCreation += '<%r.name%>Type dummy<%r.name%>Type;<%\n%>'
          <<
          struct <%r.name%>Type
          {
            <%r.variables |> var as VARIABLE(__) => '<%varType3(var, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)%> <%crefStr(var.name)%>;' ;separator="\n"%>
          };
          >>
    case RECORD_DECL_DEF(__) then
      <<
      RECORD DECL DEF
      >>
end recordDeclarationHeader;

template functionBodyRecordConstructor(Function fn,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Boolean useFlatArrayNotation)
 "Generates the body for a record constructor."
::=
match fn
case RECORD_CONSTRUCTOR(__) then
  //let()= System.tmpTickReset(1)
  let &varDecls = buffer "" /*BUFD*/
  let fname = underscorePath(name)
  let retType = '<%fname%>Type'
  let retVar = tempDecl(retType, &varDecls /*BUFD*/)
  let structType = '<%fname%>Type'
  let structVar = tempDecl(structType, &varDecls /*BUFD*/)

  <<
  void /*<%retType%>*/ Functions::<%fname%>(<%funArgs |> var as  VARIABLE(__) => '<%varType1(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%> <%crefStr(name)%>' ;separator=", "%><%if funArgs then "," else ""%><%retType%>& output )
  {

    <%funArgs |> VARIABLE(__) => '(output.<%crefStr(name)%>) = (<%crefStr(name)%>);' ;separator="\n"%>
    //output = <%structVar%>;
  //return <%structVar%>;
  }



  >>
end functionBodyRecordConstructor;



template functionHeaderRegularFunction2(Function fn,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match fn
case FUNCTION(outVars={}) then
  let fname = underscorePath(name)
  <<
  <%functionTemplates(functionArguments)%>
  void <%fname%>(<%functionArguments |> var => funArgDefinition(var, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator=", "%>);
  >>
case FUNCTION(outVars=_) then
  let fname = underscorePath(name)
  <<
  /* functionHeaderRegularFunction2 */
  <%functionTemplates(functionArguments)%>
  void /*<%fname%>RetType*/ <%fname%>(<%functionArguments |> var => funArgDefinition(var,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator=", "%><%if functionArguments then "," else ""%> <%fname%>RetType& output);
  >>
case EXTERNAL_FUNCTION(outVars=var::_) then
  let fname = underscorePath(name)
  <<
  /* functionHeaderRegularFunction2 */
  void /*<%fname%>RetType*/ <%fname%>(<%funArgs |> var => funArgDefinition(var,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator=", "%><%if funArgs then "," else ""%> <%fname%>RetType& output);
  >>
case EXTERNAL_FUNCTION(outVars={}) then
  let fname = underscorePath(name)
  <<
  void <%fname%>(<%funArgs |> var => funArgDefinition(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator=", "%>);
  >>
end functionHeaderRegularFunction2;

template functionHeaderRegularFunction3(Function fn,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match fn
case FUNCTION(outVars={}) then ""

case FUNCTION(outVars=_) then
  let fname = underscorePath(name)
  <<
  /* functionHeaderRegularFunction3 */
  <%fname%>RetType _<%fname%>;
  >>
case EXTERNAL_FUNCTION(outVars=var::_) then
  let fname = underscorePath(name)
  <<
  /* functionHeaderRegularFunction3 */
  <%fname%>RetType _<%fname%>;
  >>
end functionHeaderRegularFunction3;

template functionBodyRegularFunction(Function fn, Boolean inFunc, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates the body for a Modelica/MetaModelica function."
::=
match fn
case FUNCTION(__) then
  //let()= System.tmpTickReset(1)
  let fname = underscorePath(name)
  let retType = if outVars then '<%fname%>RetType ' else "void" /* functionBodyRegularFunction */
  let &varDecls = buffer "" /*BUFD*/


  let &varInits = buffer "" /*BUFD*/
  //let retVar = if outVars then tempDecl(retType, &varDecls /*BUFD*/)
  //let stateVar = if not acceptMetaModelicaGrammar() then tempDecl("state", &varDecls /*BUFD*/)
  let _ = (variableDeclarations |> var as  VARIABLE(__) hasindex i1 fromindex 1 =>
      varInit(var, "", i1, &varDecls, &varInits, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ; empty /* increase the counter! */)

  //let addRootsInputs = (functionArguments |> var => addRoots(var) ;separator="\n")
  //let addRootsOutputs = (outVars |> var => addRoots(var) ;separator="\n")
  //let funArgs = (functionArguments |> var => functionArg(var, &varInits) ;separator="\n")
  let bodyPart = funStatement(body, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let &outVarInits = buffer ""
  let &outVarCopy = buffer ""
  let &outVarAssign = buffer ""
     let _ =  match outVars   case {var} then (outVars |> var hasindex i1 fromindex 0 =>
                    varOutput(fn, var,i1, &varDecls, &outVarInits, &outVarCopy, &outVarAssign, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
                ;separator="\n"; empty /* increase the counter! */
     )
    else
      (outVars |> var hasindex i1 fromindex 0 =>
        varOutputTuple(fn, var,i1, &varDecls, &outVarInits, &outVarCopy, &outVarAssign, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      ;separator="\n"; empty /* increase the counter! */
     )
/* previous
  <%outVarAssign%>
    return <%if outVars then '_<%fname%>' %>;
  return <%if outVars then '<%outVarAssign%>' %>
*/

  //let boxedFn = if acceptMetaModelicaGrammar() then functionBodyBoxed(fn)
  <<
  //if outvars missing
  <%functionTemplates(functionArguments)%>
  void /*<%retType%>*/ Functions::<%fname%>(<%functionArguments |> var => funArgDefinition(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator=", "%><%if functionArguments then if outVars then "," else ""%><%if outVars then '<%retType%>& output' %> )
  {
    //functionBodyRegularFunction
    <%(functionArguments |> var => match var case FUNCTION_PTR(name=fnptrName) then 'typedef double <%fnptrName%>RetType;' ;separator="\n")%>
    <%varDecls%>
    //outvars
    <%outVarInits%>
    <%varInits%>
    do
    {
      <%bodyPart%>
    }
    while(false);
    <%outVarAssign%>
    <%if outVars then '/*output = _<%fname%>;*/' %>
  }

  <% if inFunc then
  <<
  int in_<%fname%>(type_description * inArgs, type_description * outVar)
  {
    <%functionArguments |> var => '<%funArgDefinition2(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>;' ;separator="\n"%>
    <%if outVars then '<%retType%> out;'%>

    //MMC_TRY_TOP()



    return 0;
  }
  >>
  %>
  >>
end functionBodyRegularFunction;


template functionBodyExternalFunction(Function fn, Boolean inFunc,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates the body for an external function (just a wrapper)."
::=
match fn
case efn as EXTERNAL_FUNCTION(extArgs=extArgs) then
  //let()= System.tmpTickReset(1)
  let fname = underscorePath(name)
  let retType = if outVars then '<%fname%>RetType' else "void"
  let &preExp = buffer "" /*BUFD*/
  let &varDeclsInit = buffer "" /*BUFD*/
  let &varDeclsExtFunCall = buffer "" /*BUFD*/
  let &varDeclsOutput = buffer "" /*BUFD*/
  let &varDeclsvOutputTuple = buffer "" /*BUFD*/

  let &inputAssign = buffer "" /*BUFD*/
  let &outputAssign = buffer "" /*BUFD*/
  let retVar = if outVars then match outVars case {var} then funArgName(var) else '_<%fname%>'
  let &outVarInits = buffer ""
  let callPart =  match outVars   case {var} then
                    extFunCall(fn, &preExp, &varDeclsExtFunCall, &inputAssign, &outputAssign, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation, false)
                  else
                    extFunCall(fn, &preExp, &varDeclsExtFunCall, &inputAssign, &outputAssign, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation, true)
  let _ = ( outVars |> var as  VARIABLE(__)  hasindex i1 fromindex 1 =>
            varInit(var, retVar, i1, &varDeclsInit, &outVarInits, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ///TOODOO
            ; empty /* increase the counter! */
          )
  let &outVarAssign = buffer ""
  let &outVarCopy = buffer ""
  let _ =  match outVars

  case {var} then
     //(outVars |> var hasindex i1 fromindex 0 =>
      varOutput(fn, var,0, &varDeclsOutput, &outVarInits, &outVarCopy, &outVarAssign, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     // ;separator="\n"; empty /* increase the counter! */
  else
    (List.restOrEmpty(outVars) |> var hasindex i1 fromindex 1 =>  varOutputTuple(fn, var, i1, &varDeclsvOutputTuple, &outVarInits, &outVarCopy, &outVarAssign, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    ;separator="\n"; empty /* increase the counter! */
    )
   end match

   let &outVarCopy1 = buffer ""
   let &outVarAssign1 = buffer ""

   let _ =  match outVars

   case {var} then "1"

   else
     (outVars |> var hasindex i1 fromindex 0 =>  varOutputTuple(fn, var, i1, &varDeclsvOutputTuple, &outVarInits, &outVarCopy1, &outVarAssign1, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     ;separator="\n"; empty /* increase the counter! */)
  end match
  let functionBodyExternalFunctionreturn = match outVarAssign1
    case "" then <<<%if retVar then 'output = <%retVar%>;' else '/*no output*/' %>>>
    else outVarAssign1

  let fnBody =
  <<
  void /*<%retType%>*/ Functions::<%fname%>(<%funArgs |> var => funArgDefinition(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator=", "%><%if funArgs then if outVars then "," else ""%> <%if retVar then '<%retType%>& output' %>)
  {
    /* functionBodyExternalFunction: varDecls */
    /*1*/
    <%varDeclsInit%>
    /*2*/
    <%varDeclsExtFunCall%>
    /*3*/
    <%varDeclsOutput%>
    /*4*/
    <%varDeclsvOutputTuple%>
    /* functionBodyExternalFunction: preExp */
    <%preExp%>
    /* functionBodyExternalFunction: outVarInits */
    <%outVarInits%>
    /* functionBodyExternalFunction: callPart */
    <%inputAssign%>
    <%callPart%>
    <%outputAssign%>
    /* functionBodyExternalFunction: return */
    <%functionBodyExternalFunctionreturn%>
  }
  >>
  <<
  <% if dynamicLoad then
  <<
  ptrT_<%extFunctionName(extName, language)%> ptr_<%extFunctionName(extName, language)%>=NULL;
  >> %>
  <%fnBody%>

  <% if inFunc then
  <<
  int in_<%fname%>(type_description * inArgs, type_description * outVar)
  {
    <%funArgs |> VARIABLE(__) => '<%expTypeArrayIf(ty)%> <%contextCref(name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>;' ;separator="\n"%>
    <%retType%> out;
    <%funArgs |> arg as VARIABLE(__) => readInVar(arg,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator="\n"%>
    MMC_TRY_TOP()
    out = _<%fname%>(<%funArgs |> VARIABLE(__) => contextCref(name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator=", "%>);
    MMC_CATCH_TOP(return 1)
    <%outVars |> var as VARIABLE(__) hasindex i1 fromindex 1 => writeOutVar(var, i1) ;separator="\n";empty%>
    return 0;
  }
  >> %>
  >>
end functionBodyExternalFunction;

template functionTemplates(list<Variable> functionArguments)
  "Generates template prefix for functions with function arguments"
::=
  // TODO: generate specific names if type of modelica_fnptr known
  let funcPtrs = (functionArguments |> var => match var case FUNCTION_PTR(__) then 'modelica_fnptr' ;separator=", ")
  '<%if funcPtrs then 'template <class modelica_fnptr>'%>'
end functionTemplates;

template funArgName(Variable var)
::=
  let &auxFunction = buffer ""
  match var
  case VARIABLE(__) then contextCref2(name,contextFunction)
  case FUNCTION_PTR(__) then '_' + name
end funArgName;

template writeOutVar(Variable var, Integer index)
 "Generates code for writing a variable to outVar."

::=
  match var
  case VARIABLE(ty=T_COMPLEX(complexClassType=RECORD(__))) then
    <<
    write_modelica_record(outVar, <%writeOutVarRecordMembers(ty, index, "")%>);
    >>
  case VARIABLE(__) then

    <<
    write_<%varType(var)%>(outVar, &out.targTest8<%index%>);
    >>
end writeOutVar;


template writeOutVarRecordMembers(Type type, Integer index, String prefix)
 "Helper to writeOutVar."
::=
match type
case T_COMPLEX(varLst=vl, complexClassType = n) then
  let basename = underscorePath(ClassInf.getStateName(n))
  let args = (vl |> subvar as TYPES_VAR(__) =>
      match ty case T_COMPLEX(__) then
        let newPrefix = '<%prefix%>.<%subvar.name%>'
        '<%expTypeRW(ty)%>, <%writeOutVarRecordMembers(ty, index, newPrefix)%>'
      else
        '<%expTypeRW(ty)%>, &(out.targTest7<%index%><%prefix%>.<%subvar.name%>)'
    ;separator=", ")
  <<
  &<%basename%>__desc<%if args then ', <%args%>'%>, TYPE_DESC_NONE
  >>
end writeOutVarRecordMembers;
template expTypeRW(DAE.Type type)
 "Helper to writeOutVarRecordMembers."
::=
  match type
  case T_INTEGER(__)         then "TYPE_DESC_INT"
  case T_REAL(__)        then "TYPE_DESC_REAL"
  case T_STRING(__)      then "TYPE_DESC_STRING"
  case T_BOOL(__)        then "TYPE_DESC_BOOL"
  case T_ENUMERATION(__) then "TYPE_DESC_INT"
  case T_ARRAY(__)       then '<%expTypeRW(ty)%>_ARRAY'
  case T_COMPLEX(complexClassType=RECORD(__))
                      then "TYPE_DESC_RECORD"
  case T_METATYPE(__) case T_METABOXED(__)    then "TYPE_DESC_MMC"
end expTypeRW;

template readInVar(Variable var,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for reading a variable from inArgs."
::=
  match var
  case VARIABLE(name=cr, ty=T_COMPLEX(complexClassType=RECORD(__))) then
    <<
    if (read_modelica_record(&inArgs, <%readInVarRecordMembers(ty, contextCref(cr,contextFunction,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation))%>)) return 1;
    >>
  case VARIABLE(name=cr, ty=T_STRING(__)) then
    <<
    if (read_<%expTypeArrayIf(ty)%>(&inArgs, <%if not acceptMetaModelicaGrammar() then "(char**)"%> &<%contextCref(name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>)) return 1;
    >>
  case VARIABLE(__) then
    <<
    if (read_<%expTypeArrayIf(ty)%>(&inArgs, &<%contextCref(name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>)) return 1;
    >>
end readInVar;


template readInVarRecordMembers(Type type, String prefix)
 "Helper to readInVar."
::=
match type
case T_COMPLEX(varLst=vl) then
  (vl |> subvar as TYPES_VAR(__) =>
    match ty case T_COMPLEX(__) then
      let newPrefix = '<%prefix%>.<%subvar.name%>'
      readInVarRecordMembers(ty, newPrefix)
    else
      '&(<%prefix%>.<%subvar.name%>)'
  ;separator=", ")
end readInVarRecordMembers;

template outDecl(String ty, Text &varDecls /*BUFP*/)
 "Declares a temporary variable in varDecls and returns the name."
::=
  let newVar = 'out'
  let &varDecls += '<%ty%> <%newVar%>;<%\n%>'
  newVar
end outDecl;


template extFunCall(Function fun, Text &preExp, Text &varDecls, Text &inputAssign, Text &outputAssign, SimCode simCode, Text& extraFuncs,
                    Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Boolean useTuple)
 "Generates the call to an external function."
::=
match fun
case EXTERNAL_FUNCTION(__) then
  let _ = (biVars |> bivar =>
           extFunCallBiVar(bivar, &preExp, &varDecls, simCode,
                           &extraFuncs, &extraFuncsDecl, extraFuncsNamespace,
                           stateDerVectorName, useFlatArrayNotation);
           separator="\n")
  match language
  case "C" then extFunCallC(fun, &preExp, &varDecls, &inputAssign, &outputAssign, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation, useTuple)
  case "FORTRAN 77" then extFunCallF77(fun, &preExp, &varDecls, &inputAssign, &outputAssign, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation, useTuple)
end extFunCall;


template extFunCallC(Function fun, Text &preExp, Text &varDecls, Text &inputAssign, Text &outputAssign, SimCode simCode, Text& extraFuncs,
                     Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Boolean useTuple)
 "Generates the call to an external C function."
::=
match fun
case EXTERNAL_FUNCTION(__) then
  /* adpro: 2011-06-24 do vardecls -> extArgs as there might be some sets in there! */
  let varDecs = (List.union(extArgs, extArgs) |> arg => extFunCallVardecl(arg, &varDecls /*BUFD*/) ;separator="\n")
  //let fname = if dynamicLoad then 'ptr_<%extFunctionName(extName, language)%>' else '<%extName%>'
  let fname = underscorePath(name)
  let dynamicCheck = if dynamicLoad then
  <<
  if (<%fname%>==NULL) {
    MODELICA_TERMINATE("dynamic external function <%extFunctionName(extName, language)%> not set!")
  } else
  >>
    else ''
  let args = (extArgs |> arg =>
      extArg(arg, &preExp, &varDecls, &inputAssign, &outputAssign, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    ;separator=", ")
  let returnAssign = match extReturn case SIMEXTARG(cref=c, type_=ty) then
     let extName = extVarName2(c)
     let &outputAssign += '<%contextCref2(c,contextFunction)%> = <%extName%>;<%\n%>'
     let &outputAssign += match ty case T_STRING(__) then
       '_ModelicaFreeStringIfAllocated(<%extName%>);<%\n%>' else ''
     '<%extName%> = '
    else
      ''
  <<
  <%varDecs%>
  <%match extReturn case SIMEXTARG(__) then extFunCallVardecl(extReturn, &varDecls /*BUFD*/)%>
  <%dynamicCheck%>
  <%returnAssign%><%extName%>(<%args%>);
  >>
end extFunCallC;


template extFunCallVarcopy(SimExtArg arg, String fnName,Boolean useTuple, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Helper to extFunCall."
::=
match arg
case SIMEXTARG(outputIndex=oi, isArray=false, type_=ty, cref=c) then
  match oi case 0 then
  "/*no ouput index */"
  else
   let cr = contextCref2(c,contextFunction)//'<%extVarName2(c)%>'
    match useTuple
    case true then
    let assginBegin = 'get<<%intAdd(-1,oi)%>>('
      let assginEnd = ')'


    /* <%assginBegin%>  output.data<%assginEnd%> = <%cr%>;*/
    <<
      <%contextCref(c,contextFunction,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%> =(<%expTypeModelica(ty)%>) <%cr%>;
    >>
    else
    <<
     _<%fnName%> = <%cr%>;
    >>
  case SIMEXTARG(outputIndex=oi, isArray=true, type_=ty, cref=c) then
  match oi case 0 then
  "/*no ouput index */"
  else
   let cr = contextCref2(c,contextFunction)//'<%extVarName2(c)%>'
    match useTuple
    case true then
    let assginBegin = 'get<<%intAdd(-1,oi)%>>('
      let assginEnd = ')'


    /* <%assginBegin%>  output.data<%assginEnd%> = <%cr%>;*/
    <<
     /*array assign*/
      <%contextCref(c,contextFunction,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>.assign(<%cr%>);
    >>

    else
    <<
    /*array assign*/
     _<%fnName%>.assign(<%cr%>);
    >>

    end match
end extFunCallVarcopy;



template extFunCallVarcopyTuple(SimExtArg arg, String fnName)
 "Helper to extFunCall."
::=
match arg
case SIMEXTARG(outputIndex=oi, isArray=false, type_=ty, cref=c) then
  match oi case 0 then
    ""
  else
    let cr = '<%extVarName2(c)%>'
    let assginBegin = 'get<<%intAdd(-1,oi)%>>('
      let assginEnd = ')'

    <<
     <%assginBegin%>_<%fnName%>.data<%assginEnd%> = <%cr%> ;
    >>

end extFunCallVarcopyTuple;

template extArg(SimExtArg extArg, Text &preExp, Text &varDecls, Text &inputAssign, Text &outputAssign, SimCode simCode, Text& extraFuncs,
                Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Helper to extFunCall."
::=
  match extArg
  case SIMEXTARG(isArray=true) then
    extCArrayArg(extArg, &preExp, &varDecls, &inputAssign, &outputAssign)

  case SIMEXTARG(cref=c, isInput=ii, outputIndex=0, type_=t) then
    let cr = '<%contextCref2(c,contextFunction)%>'
    if acceptMetaModelicaGrammar() then
      (match t case T_STRING(__) then 'MMC_STRINGDATA(<%cr%>)' else '<%cr%>_ext')
    else
      '<%cr%><%match t case T_STRING(__) then ".c_str()" else "_ext"%>'
  case SIMEXTARG(cref=c, isInput=ii, outputIndex=oi, type_=t) then
    let extName = extVarName2(c)
    let &outputAssign += '<%contextCref2(c,contextFunction)%> = <%extName%>;<%\n%>'
    '&<%extName%>'
  case SIMEXTARGEXP(__) then
    daeExternalCExp(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case SIMEXTARGSIZE(cref=c) then
    let typeStr = expTypeShort(type_)
    let name = contextCref2(c, contextFunction)
    let dim = daeExp(exp, contextFunction, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '<%name%>.getDim(<%dim%>)'
end extArg;


template extCArrayArg(SimExtArg extArg, Text &preExp, Text &varDecls /*BUFP*/, Text &inputAssign /*BUFD*/, Text &outputAssign /*BUFD*/)
 "Function to convert arrays to external C"
::=
match extArg
case SIMEXTARG(cref=c, isInput =iI, outputIndex=oi, isArray=true, type_=t)then
  let name = contextCref2(c,contextFunction)
  match type_
  case T_ARRAY(__)then
    let dimStr = listLength(dims)
    let dimsStr = checkDimension(dims)
    let elType = expTypeShort(ty)
    let extType = if stringEq(elType, "string") then elType else extType2(ty, true, false)
    if stringEq(elType, "string") then
      let extName = extVarName2(c)
      let &inputAssign += 'CStrArray <%extName%>(<%name%>);<%\n%>'
      let &outputAssign += if intGt(oi, 0) then '<%extName%>.writeBack(<%name%>);<%\n%>'
      '<%extName%>'
    else if boolOr(intGt(listLength(dims), 1), stringEq(elType, "bool")) then
      let tmp = match dimsStr
        case "" then
          tempDecl('DynArrayDim<%listLength(dims)%><<%extType%>>', &varDecls)
        else
          tempDecl('StatArrayDim<%dimStr%><<%extType%>, <%dimsStr%>>', &varDecls)
      let &inputAssign += 'convertArrayLayout(<%name%>, <%tmp%>);'
      let &outputAssign += if intGt(oi, 0) then 'convertArrayLayout(<%tmp%>, <%name%>);'
      '<%tmp%>.getData()'
    else
      <<<%if iI then 'ConstArray(<%name%>).getData()'
                else '<%name%>.getData()'%>>>
end extCArrayArg;


template daeExternalCExp(Exp exp, Context context, Text &preExp /*BUFP*/,Text &varDecls /*BUFP*/, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  "Like daeExp, but also converts the type to external C"
::=
  match typeof(exp)
    case T_ARRAY(__) then  // Array-expressions
      let shortTypeStr = expTypeShort(typeof(exp))
      '<%daeExp(exp, context, &preExp, &varDecls,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>.getData()'
    else daeExp(exp, context, &preExp, &varDecls,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
end daeExternalCExp;

template extFunCallVardecl(SimExtArg arg, Text &varDecls /*BUFP*/)
 "Helper to extFunCall."
::=
  match arg
  case SIMEXTARG(isInput=true, isArray=false, type_=ty, cref=c) then
    match ty case T_STRING(__) then
      ""
    else
      let &varDecls += '<%extType2(ty,true,false)%> <%extVarName2(c)%>;<%\n%> '
      <<
      <%extVarName2(c)%> = (<%extType2(ty,true,false)%>)<%contextCref2(c,contextFunction)%>;
      >>
  case SIMEXTARG(outputIndex=oi, isArray=false, type_=ty, cref=c) then
    match oi case 0 then
      ""
    else
      let &varDecls += '<%extType2(ty,true,false)%> <%extVarName2(c)%>;<%\n%> '
      ""
end extFunCallVardecl;


template extFunCallBiVar(Variable var, Text &preExp, Text &varDecls, SimCode simCode,
  Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace,
  Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Declare and initialize a local variable in &preExp"
::=
  match var
  case var as VARIABLE(__) then
    let varName = contextCref2(name, contextFunction)
    let defaultValue = match value
      case SOME(v) then
        daeExp(v, contextFunction, &preExp, &varDecls, simCode,
               &extraFuncs, &extraFuncsDecl, extraFuncsNamespace,
               stateDerVectorName, useFlatArrayNotation)
      else ""
    if instDims then
      let nDims = listLength(instDims)
      let dims = (instDims |> exp =>
        daeExp(exp, contextFunction, &preExp, &varDecls, simCode,
               &extraFuncs, &extraFuncsDecl, extraFuncsNamespace,
               stateDerVectorName, useFlatArrayNotation);
        separator=", ")
      let initializer = if defaultValue then ' = <%defaultValue%>' else '(<%dims%>)'
      let &preExp += 'DynArrayDim<%nDims%><<%varType(var)%>> <%varName%><%initializer%>;<%\n%>'
      ''
    else
      let initializer = if defaultValue then ' = <%defaultValue%>'
      let &preExp += '<%varType(var)%> <%varName%><%initializer%>;<%\n%>'
      ''
end extFunCallBiVar;


template extFunCallF77(Function fun, Text &preExp,
  Text &varDecls, Text &inputAssign, Text &outputAssign, SimCode simCode,
  Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace,
  Text stateDerVectorName /*=__zDot*/,
  Boolean useFlatArrayNotation, Boolean useTuple)
 "Generates the call to an external F77 function."
::=
  match fun
  case EXTERNAL_FUNCTION(__) then
    let funName = underscorePath(name)
    let args = (extArgs |> arg =>
      extArgF77(arg, &preExp, &varDecls, &inputAssign, &outputAssign, simCode,
                &extraFuncs, &extraFuncsDecl, extraFuncsNamespace,
                stateDerVectorName, useFlatArrayNotation);
      separator=", ")
    let returnVar = match extReturn
      case SIMEXTARG(cref=c) then '<%contextCref2(c, contextFunction)%>'
    let returnAssign = if returnVar then '<%returnVar%> = '
    <<
    <%returnAssign%><%extFunctionName(extName, language)%>(<%args%>);
    <%match useTuple case false then '<%funName%> = <%returnVar%>;'%>
    >>
end extFunCallF77;


template extArgF77(SimExtArg extArg, Text &preExp, Text &varDecls,
  Text &inputAssign, Text &outputAssign, SimCode simCode, Text& extraFuncs,
  Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName,
  Boolean useFlatArrayNotation)
 "Helper to extFunCall. Creates one F77 call argument."
::=
  match extArg
  case SIMEXTARG(cref=c, isInput=iI, outputIndex=oi, isArray=true, type_=t) then
    let varName = contextCref2(c, contextFunction)
    match type_
    case T_ARRAY(__) then
      let elType = expTypeShort(ty)
      let extType = extTypeF77(ty, false, false)
      let extName = '<%varName%>_ext'
      let nDims = listLength(dims)
      if stringEq(elType, "bool") then
        let &varDecls += 'DynArrayDim<%nDims%><<%extType%>> <%extName%>;<%\n%>'
        let &inputAssign += 'cast_array<bool, int>(<%varName%>, <%extName%>);<%\n%>'
        let &outputAssign += if intGt(oi, 0) then 'cast_array<int, bool>(<%extName%>, <%varName%>);<%\n%>'
        <<
        <%extName%>.getData()
        >>
      else
        let extName = if iI then 'ConstArray(<%varName%>)' else '<%varName%>'
        <<
        <%extName%>.getData()
        >>
    end match
  case SIMEXTARG(cref=c, type_=t) then
    let varName = contextCref2(c, contextFunction)
    let varType = expTypeShort(t)
    let extType = extTypeF77(t, false, false)
    let extName = '<%varName%>_ext'
    if stringEq(varType, extType) then
      <<
      &<%varName%>
      >>
    else
      let &varDecls += '<%extType%> <%extName%>;<%\n%>'
      let &inputAssign += '<%extName%> = <%varName%>;<%\n%>'
      <<
      &<%extName%>
      >>
  case SIMEXTARGEXP(type_=t) then
    // pass a pointer to a temporary variable
    let extType = extTypeF77(t, false, false)
    let extName = tempDecl(extType, &varDecls)
    let &inputAssign += '<%extName%> = <%daeExp(exp, contextFunction, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>;<%\n%>'
    <<
    <%match t case T_STRING(__) then '' else '&'%><%extName%>
    >>
  case SIMEXTARGSIZE(cref=c) then
    let varName = contextCref2(c, contextFunction)
    let extName = tempDecl('int', &varDecls)
    let dim = daeExp(exp, contextFunction, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let &inputAssign += '<%extName%> = <%varName%>.getDim(<%dim%>);<%\n%>'
    <<
    &<%extName%>
    >>
end extArgF77;


template varOutput(Function fn, Variable var, Integer ix, Text &varDecls, Text &varInits, Text &varCopy, Text &varAssign, SimCode simCode,
                   Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code to copy result value from a function to dest."
::=
match fn
case FUNCTION(__)
case EXTERNAL_FUNCTION(__) then
 let fname = underscorePath(name)
match var
/* The storage size of arrays is known at call time, so they can be allocated
 * before set_memory_state. Strings are not known, so we copy them, etc...
 */
case var as VARIABLE(ty = T_STRING(__)) then
    if not acceptMetaModelicaGrammar() then
      // We need to strdup() all strings, then allocate them on the memory pool again, then free the temporary string
      let strVar = tempDecl("string", &varDecls)

      let &varAssign +=
        <<
        //_<%fname%> = <%strVar%>;
        output = <%strVar%>;
        >>
      ""
    else
      let &varAssign += /*_<%fname%> */'output = <%contextCref(var.name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>;<%\n%>'
      ""
case var as VARIABLE(__) then
  let marker = '<%contextCref(var.name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  let &varInits += '/* varOutput varInits(<%marker%>) */ <%\n%>'
  //let &varAssign += '// varOutput varAssign(<%marker%>) <%\n%>'

  if instDims then
    let &varAssign += /*_<%fname%>*/'output.assign(<%contextCref(var.name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>);<%\n%>'
    //let &varAssign += '<%contextCref(var.name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>;<%\n%>'
    ""
  else
    let &varAssign += /*_<%fname%>*/ 'output  = <%contextCref(var.name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>;<%\n%>'
    //let &varAssign += '<%contextCref(var.name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>;<%\n%>'
    ""
  case var as FUNCTION_PTR(__) then
    let &varAssign += 'ToDo: Function Ptr assign'
    ""
  else "something"
end varOutput;


template varOutputTuple(Function fn, Variable var, Integer ix, Text &varDecls, Text &varInits, Text &varCopy, Text &varAssign, SimCode simCode,
                        Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code to copy result value from a function to dest."
::=
match fn
case FUNCTION(__)
case EXTERNAL_FUNCTION(__) then
 let fname = underscorePath(name)
match var
/* The storage size of arrays is known at call time, so they can be allocated
 * before set_memory_state. Strings are not known, so we copy them, etc...
 */
/*
 case var as VARIABLE(ty = T_STRING(__)) then
    if not acceptMetaModelicaGrammar() then
      // We need to strdup() all strings, then allocate them on the memory pool again, then free the temporary string
      let strVar = tempDecl("string", &varDecls)
      let &varAssign +=
        <<
       output = <%strVar%>;
       >>
      ""
    else
      let &varAssign += output= <%contextCref(var.name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,useFlatArrayNotation)%>;<%\n%>'
      ""
      */
case var as VARIABLE(__) then
  let marker = '<%contextCref(var.name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  let &varInits += '/* varOutputTuple varInits(<%marker%>) */ <%\n%>'
  let &varAssign += '// varOutput varAssign(<%marker%>) <%\n%>'
  let instDimsInit = (instDims |> exp =>
      daeExp(exp, contextFunction, &varInits, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    ;separator=",")
  let assginBegin = 'get<<%ix%>>'
  if instDims then
    let &varInits += '<%assginBegin%>(/*_<%fname%>*/output.data).setDims(<%instDimsInit%>);//todo setDims not for stat arrays
    <%\n%>'
    let &varAssign += '<%assginBegin%>(/*_<%fname%>*/output.data)=<%contextCref(var.name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,stateDerVectorName,useFlatArrayNotation)%>;<%\n%>'
    ""
  else
   // let &varInits += initRecordMembers(var)
    let &varAssign += ' <%assginBegin%>(/*_<%fname%>*/output.data) = <%contextCref(var.name,contextFunction,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>/*TestVarAssign5*/;<%\n%> '
    "/*testcase1*/"
case var as FUNCTION_PTR(__) then
    let &varAssign += '/*_<%fname%>*/ output = (modelica_fnptr) _<%var.name%>;<%\n%>'
    "/*testcase2*/"
else
let &varAssign += '/*iregendwas*/'
    "/*testcase3*/"
end varOutputTuple;


template varDeclForVarInit(Variable var,String varName, list<DAE.Exp> instDims, Text &varDecls, Text &varInits, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  //let instDimsInit = (instDims |> exp => daeExp(exp, contextFunction, &varInits, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName,  useFlatArrayNotation);separator=",")
  let instDimsInit = checkExpDimension(instDims)
    match var
        case var as VARIABLE(__) then
            let type = '<%varType(var)%>'
            let initVar =  match type case "modelica_metatype" then ' = NULL' else ''
            let addRoot =  match type case "modelica_metatype" then ' mmc_GC_add_root(&<%varName%>, mmc_GC_local_state, "<%varName%>");' else ''
            //let testinstDimsInit = (instDims |> exp => testDaeDimensionExp(exp);separator="")
            //let instDimsInit = (instDims |> exp => daeExp(exp, contextFunction, &varInits, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation);separator=",")
            let arrayexpression1 = (if instDims then 'StatArrayDim<%listLength(instDims)%><<%expTypeShort(var.ty)%>,<%instDimsInit%>> <%varName%>;/*testarray5*/<%\n%>'
        else '<%type%> <%varName%><%initVar%>;<%addRoot%><%\n%>')
            let arrayexpression2 = (if instDims then 'DynArrayDim<%listLength(instDims)%><<%expTypeShort(var.ty)%>> <%varName%>;<%\n%>'
        else '<%type%> <%varName%><%initVar%>;<%addRoot%><%\n%>'
  )

  match instDimsInit
    case "" then
        let &varDecls += arrayexpression2
        ""
    else
        let &varDecls += arrayexpression1
        ""
end varDeclForVarInit;


template varInit(Variable var, String outStruct, Integer i, Text &varDecls, Text &varInits, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)

 "Generates code to initialize variables.
  Does not return anything: just appends declarations to buffers."
::=

match var
case var as VARIABLE(__) then
  let varName = '<%contextCref(var.name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  let &preExp = buffer ""
  let recordInit = initRecordMembers(var, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let &varInits += if recordInit then
  <<
    //initRecordMembers <%varName%>
    <%preExp%>
    <%recordInit%>
  >>
  let instDimsInit = (instDims |> exp => daeExp(exp, contextFunction, &varInits , &varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation);separator=",")


  //let varName = if outStruct then 'ToDo: outStruct not implemented' else '<%contextCref(var.name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl, stateDerVectorName, extraFuncsNamespace)%>'
  let _ = varDeclForVarInit(var, varName, instDims, &varDecls, &varInits, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)

  if instDims then
    let testinstDimsInit = (instDims |> exp => testDaeDimensionExp(exp);separator="")
    let temp = setDims(testinstDimsInit, varName , &varInits, instDimsInit)


  (match var.value
    case SOME(exp) then

      let defaultValue1 = '<%varName%>.assign(<%daeExp(exp, contextFunction, &varInits, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>);<%\n%>'
      let &varInits += defaultValue1
    ""
    else
      let defaultValue = varDefaultValue(var, outStruct, i, varName, &varDecls, &varInits, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)

      let &varInits += defaultValue
      ""
   )
  else
    (match var.value
    case SOME(exp) then
      let defaultValue = '<%contextCref(var.name, contextFunction, simCode ,&extraFuncs ,&extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%> = <%daeExp(exp, contextFunction, &varInits, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>;<%\n%>'
      let &varInits += defaultValue
      " "
    else
      "")
case var as FUNCTION_PTR(__) then
  let &ignore = buffer ""
  let &varDecls += functionArg(var,&ignore)
  ""

end varInit;

template initRecordMembers(Variable var, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  "Initialize members of a record variable"
::=
  match var
  case VARIABLE(ty = T_COMPLEX(complexClassType = RECORD(__))) then
    let varName = contextCref(name, contextFunction, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    (ty.varLst |> v => recordMemberInit(v, varName, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator="\n")
end initRecordMembers;

template recordMemberInit(Var v, Text varName, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  "Initialize one record member"
::=
  match v
  case TYPES_VAR(__) then
    let vn = '<%varName%>.<%name%>'
    let defaultValue =
      match binding
      case VALBOUND(valBound = val) then
        '<%vn%> = <%daeExp(valueExp(val), contextOther, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>;'
      case EQBOUND(evaluatedExp = SOME(val)) then
        '<%vn%> = <%daeExp(valueExp(val), contextFunction, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>;'
      case EQBOUND(exp = exp) then
        '<%vn%> = <%daeExp(exp, contextFunction, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>;'
      else
        ''
      end match
    <<
    <%defaultValue%>
    >>
end recordMemberInit;

template setDims(Text testinstDimsInit, String varName , Text &varInits, String instDimsInit)
   ::=
  match testinstDimsInit
    case "" then let &varInits += ''
    ""
    else let &varInits += '<%varName%>.setDims(<%instDimsInit%>);<%\n%>'
    ""
    end match
end setDims;


template functionArg(Variable var, Text &varInit)
"Shared code for function arguments that are part of the function variables and valueblocks.
Valueblocks need to declare a reference to the function while input variables
need to initialize."
::=
match var
case var as FUNCTION_PTR(__) then
  let typelist = (args |> arg => mmcVarType(arg) ;separator=", ")
  let rettype = '<%name%>RetType /* functionArg */'
  match tys
    case {} then
      let &varInit += '_<%name%> = (void(*)(<%typelist%>)) <%name%><%\n%>;'
      'void(*_<%name%>)(<%typelist%>);<%\n%>'
    else

      let &varInit += '_<%name%> = (<%rettype%>(*)(<%typelist%>)) <%name%>;<%\n%>'
      <<
      <% tys |> arg hasindex i1 fromindex 1 => '#define <%rettype%>_<%i1%> targTest2<%i1%>' ; separator="\n" %>
      typedef struct <%rettype%>_s
      {
        <% tys |> ty hasindex i1 fromindex 1 => 'modelica_<%mmcTypeShort(ty)%> targTest1<%i1%>;' ; separator="\n" %>
      } <%rettype%>;
      <%rettype%>(*_<%name%>)(<%typelist%>);<%\n%>
      >>
  end match
end functionArg;

template mmcVarType(Variable var)
::=
  match var
  case VARIABLE(__) then 'modelica_<%mmcTypeShort(ty)%>'
  case FUNCTION_PTR(__) then 'modelica_fnptr'
end mmcVarType;

template mmcTypeShort(DAE.Type type)
::=
  match type
  case T_INTEGER(__)                     then "integer"
  case T_REAL(__)                    then "real"
  case T_STRING(__)                  then "string"
  case T_BOOL(__)                    then "integer"
  case T_ENUMERATION(__)             then "integer"
  case T_ARRAY(__)                   then "array"
  case T_METATYPE(__) case T_METABOXED(__)                then "metatype"
  case T_FUNCTION_REFERENCE_VAR(__)  then "fnptr"
  else "mmcTypeShort:ERROR"
end mmcTypeShort;

template extVarName(ComponentRef cr, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::= '<%contextCref(cr,contextFunction,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>_ext'
end extVarName;

template extVarName2(ComponentRef cr)
::= '<%contextCref2(cr,contextFunction)%>_ext'
end extVarName2;

template varDefaultValue(Variable var, String outStruct, Integer i, String lhsVarName, Text &varDecls, Text &varInits, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match var
case var as VARIABLE(__) then
  match value
  case SOME(CREF(componentRef = cr)) then
    '<%contextCref(cr,contextFunction, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%> =  <%outStruct%>.targTest9<%i%><%\n%>'
  case SOME(arr as ARRAY(__)) then
    let arrayExp = '<%daeExp(arr, contextFunction, &varInits, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
    <<
    <%lhsVarName%> = <%arrayExp%>;<%\n%>
    >>
end varDefaultValue;


template funArgDefinition(Variable var,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match var
  case VARIABLE(__) then '<%varType1(var, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%> <%contextCref(name, contextFunction, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  case FUNCTION_PTR(__) then 'modelica_fnptr <%name%>'
end funArgDefinition;

template funArgDefinition2(Variable var,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match var
  case VARIABLE(__) then '<%varType3(var, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%> <%contextCref(name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  case FUNCTION_PTR(__) then 'modelica_fnptr <%name%>'
end funArgDefinition2;

template funExtArgDefinition(SimExtArg extArg,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match extArg
  case SIMEXTARG(cref=c, isInput=ii, isArray=ia, type_=t) then
    let name = contextCref(c,contextFunction,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let typeStr = expTypeFlag(t,5)
    <<
    <%typeStr%> <%name%>
    >>
  case SIMEXTARGEXP(__) then
    let typeStr = expTypeFlag(type_,5)
    <<
    <%typeStr%>
    >>
  case SIMEXTARGSIZE(cref=c) then
    <<
    size_t
    >>
end funExtArgDefinition;

template funReturnDefinition1(Variable var,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  match var
  case VARIABLE(__) then '<%varType3(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>'
  case FUNCTION_PTR(__) then 'modelica_fnptr <%name%>'
end funReturnDefinition1;

template funReturnDefinition2(Variable var, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match var
  case VARIABLE(__) then '<%varType2(var, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  case FUNCTION_PTR(__) then 'modelica_fnptr <%name%>'
end funReturnDefinition2;

template varType(Variable var)
 "Generates type for a variable."
::=
match var
case var as VARIABLE(__) then
  if instDims then
    expTypeShort(var.ty)
  else
    expTypeArrayIf(var.ty)
end varType;


template varType1(Variable var,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match var
case var as VARIABLE(__) then
     /* previous multi_array
   if instDims then 'multi_array<<%expTypeShort(var.ty)%>,<%listLength(instDims)%>> ' else expTypeArrayIf(var.ty)
      */

     /*Always use BaseArray as function array argument types */
     if instDims then 'BaseArray<<%expTypeShort(ty)%>>&' else expTypeFlag(var.ty, 8)
     /* uses StatArrray if possible else Dynarray as function array argument types
     let &varDecls = buffer ""
     let &varInits = buffer ""
     let testinstDimsInit = (instDims |> exp => testDaeDimensionExp(exp);separator="")

     match testinstDimsInit
     case "" then
      let instDimsInit = (instDims |> exp => daeDimensionExp(exp);separator=",")
     if instDims then 'StatArrayDim<%listLength(instDims)%>< <%expTypeShort(var.ty)%>, <%instDimsInit%> > ' else expTypeFlag(var.ty, 8)
     else
     if instDims then 'DynArrayDim<%listLength(instDims)%><<%expTypeShort(var.ty)%>> ' else expTypeFlag(var.ty, 8)

     end match
     */
end varType1;

template varType2(Variable var,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match var
case var as VARIABLE(__) then
     /* previous multi_array
   if instDims then 'multi_array_ref<<%expTypeShort(var.ty)%>,<%listLength(instDims)%>> ' else expTypeFlag(var.ty, 5)
   */


      /*uses StatArrray if possible else Dynarray as function array argument types  */
     let &varDecls = buffer ""
     let &varInits = buffer ""
     let DimsTest = (instDims |> exp => daeDimensionExp(exp);separator="")
     let instDimsInit = (instDims |> exp => daeExp(exp, contextFunction, &varInits, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation);separator=",")
     match DimsTest
        case "" then if instDims then 'StatArrayDim<%listLength(instDims)%><<%expTypeShort(var.ty)%>, <%instDimsInit%>>& ' else expTypeFlag(var.ty, 5)
        else if instDims then 'DynArrayDim<%listLength(instDims)%><<%expTypeShort(var.ty)%>>&' else expTypeFlag(var.ty, 5)

end varType2;

template varType3(Variable var,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match var
case var as VARIABLE(__) then
     /* previous multi_array
   if instDims then 'multi_array<<%expTypeShort(var.ty)%>,<%listLength(instDims)%>> ' else expTypeArrayIf(var.ty)
      */
     let &varDecls = buffer "" /*should be empty herer*/
     let &varInits = buffer "" /*should be empty herer*/
     let testinstDimsInit = (instDims |> exp => testDaeDimensionExp(exp);separator="")

     match testinstDimsInit
     case "" then
      let instDimsInit = (instDims |> exp => daeDimensionExp(exp);separator=",")
     if instDims then 'StatArrayDim<%listLength(instDims)%>< <%expTypeShort(var.ty)%>, <%instDimsInit%>> /*testarray2*/' else expTypeArrayIf(var.ty)
     else
     if instDims then 'DynArrayDim<%listLength(instDims)%><<%expTypeShort(var.ty)%>> ' else expTypeArrayIf(var.ty)

     end match
end varType3;

template funStatement(list<DAE.Statement> statementLst, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates function statements."
::=
  statementLst |> stmt => algStatement(stmt, contextFunction, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ; separator="\n"
end funStatement;

template initExtVars(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__))  then
    let externalvarfuncs = functionCallExternalObjectsConstruct('<%lastIdentOfPath(modelInfo.name)%>Initialize', extObjInfo, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let externalvarsfunccalls = functionCallExternalObjectsCall('<%lastIdentOfPath(modelInfo.name)%>Initialize', extObjInfo, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation)
    <<
    <%externalvarfuncs%>
    <%externalvarsfunccalls%>
    <%extraFuncs%>
    >>
  end match
end initExtVars;

template initExtVarsDecl(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__))  then
    let externalobjsdecl = functionCallExternalObjectsDecl(extObjInfo, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation)
    <<
    <%externalobjsdecl%>

    void constructExternalObjects();
    void destructExternalObjects();
    bool _constructedExternalObjects;
    >>
  end match
end initExtVarsDecl;


template init(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Text& complexStartExpressions)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__),makefileParams = MAKEFILE_PARAMS(__))  then
   //let () = System.tmpTickReset(0)
   let &varDecls = buffer "" /*BUFD*/
   let modelname = identOfPathDot(modelInfo.name)
   let initFunctions = functionInitial(startValueEquations, varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
   let initZeroCrossings = functionOnlyZeroCrossing(zeroCrossings,varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace)
   let initEventHandling = eventHandlingInit(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
   let initClockIntervals = clockIntervalsInit(simCode, &varDecls, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)

   let initAlgloopSolvers = initAlgloopsolvers(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
   let initAlgloopvars = initAlgloopVars(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)

   let initialequations  = functionInitialEquations(initialEquations,"initEquation",simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation, false, true, false)
   let boundparameterequations  = functionInitialEquations(parameterEquations,"initParameterEquation",simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation, false, true, true)
   <<
   // convenience function for full initialization
   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initialize()
   {
      initializeMemory();
      initializeFreeVariables();
      initializeBoundVariables();
      saveAll();
   }

   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeMemory()
   {
      _discrete_events = _event_handling->initialize(this,getSimVars());

      //create and initialize Algloopsolvers
      <%generateAlgloopsolvers( listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>

      //initialize Algloop variables
      initializeAlgloopSolverVariables();
      //init alg loop vars
      <%initAlgloopvars%>
      <%lastIdentOfPath(modelInfo.name)%>WriteOutput::initialize();
      <%lastIdentOfPath(modelInfo.name)%>Jacobian::initialize();
      <%lastIdentOfPath(modelInfo.name)%>Jacobian::initializeColoredJacobianA();
   }

   <%if(boolAnd(boolNot(Flags.isSet(Flags.HARDCODED_START_VALUES)), Flags.isSet(Flags.GEN_DEBUG_SYMBOLS))) then
     <<
     void <%lastIdentOfPath(modelInfo.name)%>Initialize::checkParameters()
     {
        checkParameterVars();
        checkIntParameterVars();
        checkBoolParameterVars();
        checkStringParameterVars();
     }

     void <%lastIdentOfPath(modelInfo.name)%>Initialize::checkVariables()
     {
        /*check functions are only available if genDebugSymbols was selected*/
        checkAlgVars();
        checkDiscreteAlgVars();
        checkIntAlgVars();
        checkBoolAlgVars();
        checkStringAlgVars();
        //checkStateVars();
        //checkDerVars();
     }
     >>
   %>

   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeFreeVariables()
   {
      #if !defined(FMU_BUILD)
        #if defined(__vxworks)
        _reader  = shared_ptr<IPropertyReader>(new XmlPropertyReader("/SYSTEM/bundles/com.boschrexroth.<%modelname%>/<%fileNamePrefix%>_init.xml"));
        #else
        _reader  =  shared_ptr<IPropertyReader>(new XmlPropertyReader("<%makefileParams.compileDir%>/<%fileNamePrefix%>_init.xml"));
        #endif
        _reader->readInitialValues(*this, getSimVars());
      #endif

      _simTime = 0.0;
      _state_var_reinitialized = false;

      <%if (Flags.isSet(Flags.HARDCODED_START_VALUES)) then
      <<
      /*initialize parameter*/
      initializeParameterVars();
      initializeIntParameterVars();
      initializeBoolParameterVars();
      initializeStringParameterVars();
      initializeAlgVars();
      initializeDiscreteAlgVars();
      initializeIntAlgVars();
      initializeBoolAlgVars();
      initializeStateVars();
      initializeDerVars();
      >>
      %>
      /*external objects*/
      if (_constructedExternalObjects)
        destructExternalObjects();
      _constructedExternalObjects = false;

   #if defined(__TRICORE__) || defined(__vxworks)
      //init inputs
      stepStarted(0.0);
   #endif

      /*Start complex expressions */
      <%complexStartExpressions%>
      /* End complex expression */
      <%if(boolAnd(boolNot(Flags.isSet(Flags.HARDCODED_START_VALUES)), Flags.isSet(Flags.GEN_DEBUG_SYMBOLS))) then 'checkParameters();' else '//checkParameters();'%>
                                                                                      //delete reader;
   }

   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeBoundVariables()
   {
      //variable decls
      <%varDecls%>

      initParameterEquations();

      //construct external objects once
      if (!_constructedExternalObjects)
        constructExternalObjects();
      _constructedExternalObjects = true;

      //bound start values
      <%initFunctions%>

      //init event handling
      <%initEventHandling%>
      <%initClockIntervals%>

      //init equations
      initEquations();

      //init alg loop solvers
      <%initAlgloopSolvers%>

      for(int i = 0; i < _dimZeroFunc; i++)
      {
         getCondition(i);
      }

      //initialAnalyticJacobian();

      <%functionInitDelay(delayedExps,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>

      <%if(boolAnd(boolNot(Flags.isSet(Flags.HARDCODED_START_VALUES)), Flags.isSet(Flags.GEN_DEBUG_SYMBOLS))) then 'checkVariables();' else '//checkVariables();'%>
   }

   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initEquations()
   {
      <%(initialEquations |> eq  =>
                    equation_function_call(eq,  contextOther, &varDecls /*BUFC*/, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,"initEquation")
                    ;separator="\n")%>
   }
   <%initialequations%>
   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initParameterEquations()
   {
      <%(parameterEquations |> eq  =>
                    equation_function_call(eq,  contextOther, &varDecls /*BUFC*/, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,"initParameterEquation")
                    ;separator="\n")%>
   }
   <%boundparameterequations%>
   <%init2(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, modelInfo, stateDerVectorName, useFlatArrayNotation)%>
    >>
  end match
end init;


template init2(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, ModelInfo modelInfo, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match modelInfo
case modelInfo as MODELINFO(vars=SIMVARS(__))  then

   //let () = System.tmpTickReset(0)
   let &varDecls1 = buffer "" /*BUFD*/
   let &varDecls2 = buffer "" /*BUFD*/

   let functionPrefix = if Flags.isSet(Flags.HARDCODED_START_VALUES) then "initialize" else "check"
   let init1   = initValst(varDecls1, "Real", vars.stateVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
   let init2   = initValst(varDecls2, "Real", vars.derivativeVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)

   if(boolOr(Flags.isSet(Flags.HARDCODED_START_VALUES), Flags.isSet(Flags.GEN_DEBUG_SYMBOLS))) then
   <<
   void <%lastIdentOfPath(modelInfo.name)%>Initialize::<%functionPrefix%>StateVars()
   {
       <%varDecls1%>
       <%init1%>
   }
   void <%lastIdentOfPath(modelInfo.name)%>Initialize::<%functionPrefix%>DerVars()
   {
       <%varDecls2%>
       <%init2%>
   }
   >>
   else ''
end init2;


template functionCallExternalObjectsConstruct(Text className, ExtObjInfo extObjInfo, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  "Generates function in simulation file."
::=
  match extObjInfo
  case EXTOBJINFO(__) then
    let tors = (vars |> var as SIMVAR(initialValue=SOME(exp)) hasindex idx =>
      let &preExp = buffer "" /*BUFD*/
      let &varDecls = buffer "" /*BUFD*/
      let arg = daeExp(exp, contextOther, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      <<
      void <%className%>::constructExternalObject_<%idx%>()
      {
        <%varDecls%>
        <%preExp%>
        <%cref(var.name, useFlatArrayNotation)%> = <%arg%>;
      }

      >>
      ;separator="")
    tors
  end match
end functionCallExternalObjectsConstruct;


template functionCallExternalObjectsCall(Text className, ExtObjInfo extObjInfo, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
  "Generates function in simulation file."
::=
  match extObjInfo
  case EXTOBJINFO(__) then
    let &funDecls = buffer "" /*BUFD*/
    let &varDecls = buffer "" /*BUFD*/
    let ctorCalls = (vars |> var as SIMVAR(initialValue=SOME(exp)) hasindex idx =>
      <<
      constructExternalObject_<%idx%>();
      >>
      ;separator="\n")
    let dtorCalls = (vars |> var as SIMVAR(varKind=ext as EXTOBJ(), initialValue=SOME(exp)) hasindex idx =>
      <<
      _functions-><%underscorePath(ext.fullClassName)%>_destructor(<%cref(var.name, useFlatArrayNotation)%>);
      >>
      ;separator="\n")
    <<
    void <%className%>::constructExternalObjects()
    {
      <%ctorCalls%>
      <%aliases |> (var1, var2) => '<%cref(var1,useFlatArrayNotation)%> = <%cref(var2,useFlatArrayNotation)%>;' ;separator="\n"%>
    }

    void <%className%>::destructExternalObjects()
    {
      <%dtorCalls%>
    }

    >>
  end match
end functionCallExternalObjectsCall;


template functionCallExternalObjectsDecl(ExtObjInfo extObjInfo, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
  "Generates function in simulation file."
::=
  match extObjInfo
  case EXTOBJINFO(__) then
    let &funDecls = buffer "" /*BUFD*/
    let &varDecls = buffer "" /*BUFD*/
    let ctorCallsDecl = (vars |> var as SIMVAR(initialValue=SOME(exp)) hasindex idx =>
      <<
      void constructExternalObject_<%idx%>();
      >>
      ;separator="\n")
    let dtorCallsDecl = (vars |> var as SIMVAR(initialValue=SOME(exp)) hasindex idx =>
      <<
      void destructExternalObject_<%idx%>();
      >>
      ;separator="\n")
  <<
  <%ctorCallsDecl%>
  <%dtorCallsDecl%>
  >>
  end match
end functionCallExternalObjectsDecl;


template functionInitialEquations(list<SimEqSystem> initalEquations, Text methodName, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Boolean createMeasureTime, Boolean assignToStartValues, Boolean overwriteOldStartValues)
  "Generates function in simulation file."
::=
  let equation_func_calls = (initalEquations |> eq =>
        equation_function_create_single_func(eq, contextOther, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace,methodName, "Initialize", stateDerVectorName, useFlatArrayNotation, createMeasureTime, assignToStartValues, overwriteOldStartValues, "")
      ;separator="\n")

  <<
  <%equation_func_calls%>
  >>
end functionInitialEquations;

template initAlgloop(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, SimEqSystem eq, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)

  match eq
  case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
   let &varDecls = buffer ""
   let &preExp = buffer ""
     <<
     void <%modelname%>Algloop<%nls.index%>::initialize()
     {
       <%initAlgloopEquation(eq,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)%>
       // Don't update the equations once before start of simulation
       // evaluate();
     }
     >>
 case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
  let type = getConfigString(MATRIX_FORMAT)
  let sort = match type
  case "sparse" then
   <<
   void <%modelname%>Algloop<%ls.index%>::sortIndex()
   {
     /*jupp2*/
     <%initSort(eq, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)%>
   }
   >>
  else ''

  match ls.jacobianMatrix
       case SOME(__) then
        <<
        void <%modelname%>Algloop<%ls.index%>::initialize()
        {
          <%initAlgloopEquation(eq,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)%>
        }
        >>
   else
    /* deactivated: should be generated with codegeneration flag usematrix_t
   <<
     void <%modelname%>Algloop<%ls.index%>::initialize()
     {


        <%alocateLinearSystem(eq)%>
        if(_useSparseFormat)
          <%modelname%>Algloop<%ls.index%>::initialize(__Asparse.get());
        else
        {
          fill_array(*__A,0.0);
          <%modelname%>Algloop<%ls.index%>::initialize(__A.get());
        }


     }
   >>
   */
   <<
   <%sort%>

   void <%modelname%>Algloop<%ls.index%>::initialize()
   {
    <%initAlgloopEquation(eq, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)%>
   }
   >>
end initAlgloop;

template initAlgloopTemplate(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, SimEqSystem eq, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)
  //let &varDecls = buffer ""
  //let &preExp = buffer ""
  //let initalgvars = initAlgloopvars(preExp,varDecls,modelInfo,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,useFlatArrayNotation)

  match eq
  /*
  case SES_NONLINEAR(__) then
  <<
  template <typename T>
  void <%modelname%>Algloop<%index%>::initialize(T *__A)
  {
       <%initAlgloopEquation(eq,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,useFlatArrayNotation)%>
       AlgLoopDefaultImplementation::initialize();

    // Update the equations once before start of simulation
    evaluate();
   }
  >>
  */
 case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
 match ls.jacobianMatrix
       case SOME(__) then
       ""
   else
   <<
     template <typename T>
     void <%modelname%>Algloop<%ls.index%>::initialize(T *__A)
     {
        <%initAlgloopEquation(eq, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)%>
        // Update the equations once before start of simulation
        evaluate();
     }
   >>
end initAlgloopTemplate;


template getAMatrixCode(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, SimEqSystem eq)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelName = lastIdentOfPath(modelInfo.name)

  match eq
  case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(jacobianMatrix = SOME((_,_,_,_,_,_,index)))) then
  <<

  const matrix_t& <%modelName%>Algloop<%nls.index%>::getSystemMatrix()
  {
    return static_cast<<%modelName%>Mixed*>(_system)->getJacobian(<%index%>);
  }

  const sparsematrix_t& <%modelName%>Algloop<%nls.index%>::getSystemSparseMatrix()
  {
    throw ModelicaSimulationError(MATH_FUNCTION, "Sparse symbolic Jacobian is not suported yet");
  }
  >>

  case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
  <<

  const matrix_t& <%modelName%>Algloop<%nls.index%>::getSystemMatrix()
  {
    // return empty matrix to indicate that no symbolic Jacobian is available
    static matrix_t empty(0, 0);
    return empty;
  }

  const sparsematrix_t& <%modelName%>Algloop<%nls.index%>::getSystemSparseMatrix()
  {
    throw ModelicaSimulationError(MATH_FUNCTION, "Sparse symbolic Jacobian is not suported yet");
  }
  >>

  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
    match ls.jacobianMatrix
    case SOME((_,_,_,_,_,_,index)) then
      let type = getConfigString(MATRIX_FORMAT)
      let getDenseMatrix = match type
        case ("dense") then
          'return static_cast<<%modelName%>Mixed*>(_system)->getJacobian(<%index%>);'
        case ("sparse") then
          'throw ModelicaSimulationError(MATH_FUNCTION, "Dense matrix is not activated");'
        else "A matrix type is not supported"
        end match
      let getSparseMatrix =  match type
        case ("dense") then
          'throw ModelicaSimulationError(MATH_FUNCTION, "Sparse matrix is not activated");'
        case ("sparse") then
          'return static_cast<<%modelName%>Mixed*>(_system)->getSparseJacobian(<%index%>);'
        else "A matrix type is not supported"
        end match
    <<

    const matrix_t& <%modelName%>Algloop<%ls.index%>::getSystemMatrix()
    {
      <%getDenseMatrix%>
    }

    const sparsematrix_t& <%modelName%>Algloop<%ls.index%>::getSystemSparseMatrix( )
    {
      <%getSparseMatrix%>
    }
    >>

  else
    let type = getConfigString(MATRIX_FORMAT)
    let getDenseMatrix = match type
      case ("dense") then
        'return __A;'
      case ("sparse") then
        'throw ModelicaSimulationError(MATH_FUNCTION, "Dense matrix is not activated");'
      else "A matrix type is not supported"
      end match
    let getSparseMatrix = match type
      case ("dense") then
        'throw ModelicaSimulationError(MATH_FUNCTION, "Sparse matrix is not activated");'
      case ("sparse") then
        'return __A;'
      else "A matrix type is not supported"
      end match
     <<

     const matrix_t& <%modelName%>Algloop<%ls.index%>::getSystemMatrix()
     {
       <%getDenseMatrix%>
     }

     const sparsematrix_t& <%modelName%>Algloop<%ls.index%>::getSystemSparseMatrix()
     {
       <%getSparseMatrix%>
     }
     >>

end getAMatrixCode;


template algloopRHSCode(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,SimEqSystem eq)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)
  let &varDecls = buffer ""
  let &preExp = buffer ""


  match eq
  case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
   <<
    void <%modelname%>Algloop<%nls.index%>::getRHS(double* residuals) const
    {
         AlgLoopDefaultImplementation::getRHS(residuals);
    }

   >>
  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
    match ls.jacobianMatrix
       case SOME(__) then
      <<
      void <%modelname%>Algloop<%ls.index%>::getRHS(double* residuals) const
      {
         AlgLoopDefaultImplementation::getRHS(residuals);
      }

      >>
      else
      <<
      void <%modelname%>Algloop<%ls.index%>::getRHS(double* residuals) const
      {
        memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
      }
      >>
end algloopRHSCode;

template algloopResiduals(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,SimEqSystem eq)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)
match eq
 case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
   <<
    int <%modelname%>Algloop<%ls.index%>::getDimRHS()
    {
      return _dimAEq;
    }

    void <%modelname%>Algloop<%ls.index%>::getRHS(double* vars) const
    {
        ublas::matrix<double> A=toMatrix(_dimAEq,_dimAEq,__A->data());
        double* doubleUnknowns = new double[_dimAEq];
        getReal(doubleUnknowns);
        ublas::vector<double> x=toVector(_dimAEq,doubleUnknowns);
        ublas::vector<double> b=toVector(_dimAEq,__b.data());
        b=ublas::prod(ublas::trans(A),x)-b;
        if(vars) std::copy(b.data().begin(), b.data().end(), vars);
    }
   >>
 case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
    <<
    int <%modelname%>Algloop<%nls.index%>::giveDimRHS()
    {
      return _dimAEq;
    }

    void <%modelname%>Algloop<%nls.index%>::getRHS(double* vars) const
    {
      AlgLoopDefaultImplementation:::getRHS(vars)
    }
    >>
 case SES_MIXED(__) then algloopResiduals(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,cont)
end algloopResiduals;

template isLinearCode(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,SimEqSystem eq)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)
   let &varDecls = buffer ""
   let &preExp = buffer ""


  match eq
  case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
  <<

  bool <%modelname%>Algloop<%nls.index%>::isLinear()
  {
    return false;
  }
  >>

  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
  <<

  bool <%modelname%>Algloop<%ls.index%>::isLinear()
  {
    return true;
  }
  >>

end isLinearCode;


template isLinearTearingCode(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,SimEqSystem eq)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)
  let &varDecls = buffer ""
  let &preExp = buffer ""

  match eq
  case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
  <<

  bool <%modelname%>Algloop<%nls.index%>::isLinearTearing()
  {
    return false;
  }
  >>
 case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
   match ls.jacobianMatrix
     case SOME(__) then
     <<

     bool <%modelname%>Algloop<%ls.index%>::isLinearTearing()
     {
       return true;
     }
     >>
     else
     <<

     bool <%modelname%>Algloop<%ls.index%>::isLinearTearing()
     {
       return false;
     }
     >>
end isLinearTearingCode;


template initAlgloopEquation(SimEqSystem eq, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a non linear equation system."
::=
let &varDeclsCref = buffer "" /*BUFD*/
let type = getConfigString(MATRIX_FORMAT)
match eq
case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
  let size = listLength(nls.crefs)
  <<

   <%nls.crefs |> name hasindex i0 =>
    let namestr = contextCref(name, context, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    <<
    __xd[<%i0%>] = <%namestr%>;
     >>
  ;separator="\n"%>
   >>
 case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))then
   match ls.jacobianMatrix
       case SOME(__) then
       let &varDecls = buffer "" /*BUFD*/
       let prebody = (ls.residual |> eq2 =>
         functionExtraResidualsPreBody(eq2, &varDecls, context, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     ;separator="\n")
     let body = (ls.residual |> eq2 as SES_RESIDUAL(__) hasindex i0 =>
         let &preExp = buffer "" /*BUFD*/
         let expPart = daeExp(eq2.exp, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
         '<%preExp%>__xd[<%i0%>] = <%expPart%>;'
      ;separator="\n")
       <<

           <%varDecls%>
           //prebody
           <%prebody%>
           //body
           <%body%>
       >>
  else
   let &varDecls = buffer "" /*BUFD*/
   let Amatrix=
    (ls.simJac |> (row, col, eq as SES_RESIDUAL(__)) hasindex i0 fromindex 0 =>
      let &preExp = buffer "" /*BUFD*/
      let expPart = daeExp(eq.exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      match type case "sparse" then
      <<
      <%preExp%>__A(<%row%>,<%col%>)=<%expPart%>;
      _AData[_indexValue[<%i0%>]] = <%expPart%>;

      >>
      else
      <<
      <%preExp%>__A(<%row%>,<%col%>)=<%expPart%>;
      >>
  ;separator="\n")
   let getSparse = match type case "sparse" then
   <<
     getSparseMatrixData(__A, &_Ax);
   >>
   else
   <<
   >>


let bvector =  (ls.beqs |> exp hasindex i0 fromindex 1=>
     let &preExp = buffer "" /*BUFD*/
     let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     '<%preExp%>__b(<%i0%>)=<%expPart%>;'
  ;separator="\n")
 <<
     <%varDecls%>
      <%Amatrix%>
      <%getSparse%>
      <%bvector%>
  >>

end initAlgloopEquation;




template initSort(SimEqSystem eq, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a non linear equation system."
::=
let &varDeclsCref = buffer "" /*BUFD*/
match eq
 case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))then
   match ls.jacobianMatrix
       case SOME(__) then
<<
>>
  else

   let Amatrix=
    (ls.simJac |> (row, col, eq as SES_RESIDUAL(__)) hasindex i0 fromindex 0 =>
      <<
      //__A(<%row%>,<%col%>);
      data.push_back(mytuple(<%row%> + <%col%> * _dimAEq ,<%i0%>));
      >>
  ;separator="\n")


  <<
      std::vector<mytuple> data;
      <%Amatrix%>
      std::sort(data.begin(),data.end(),mycompare);
      std::vector<mytuple> data2;
      for (int i = 0; i < <%listLength(ls.simJac)%>; i++)
      {
        data2.push_back(mytuple((data[i].ele2),i));
      }
      std::sort(data2.begin(), data2.end(), mycompare);

      /*int help[<%listLength(ls.simJac)%>];
      for (int i = 0; i < <%listLength(ls.simJac)%>; i++)
      {
        help[i] = get<0>(data2[i]);
      }*/
      for (int i = 0; i < <%listLength(ls.simJac)%>; i++)
      {
         _indexValue[i] = (data2[i]).ele2;
      }

  >>

end initSort;

template getAlgloopVars(SimEqSystem eq, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a non linear equation system."
::=
let &varDeclsCref = buffer "" /*BUFD*/
match eq
case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
  let size = listLength(nls.crefs)
  <<

   <%nls.crefs |> name hasindex i0 =>
     let namestr = contextCref(name, context, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     <<
     vars[<%i0%>] = <%namestr%>;
     >>
     ;separator="\n"
   %>
  >>
 case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
   <<
   <%ls.vars |> SIMVAR(__) hasindex i0 => 'vars[<%i0%>] = <%cref1(name, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace,context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>;' ;separator="\n"%>
   >>
end getAlgloopVars;

template initAlgloopVarAttributes(SimEqSystem eq, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Initializes a vector of AlgLoopVar for the equation system."
::=
  let &preExp = buffer ""
  let &varDecls = buffer ""
  let vars = match eq
    case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
      (nls.crefs |> cref hasindex i0 =>
        let initializer = createAlgloopVarAttributes(cref2simvar(cref, simCode), preExp, varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)
        '_vars[<%i0%>] = <%initializer%>;'
      ;separator="\n")
    case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
      (ls.vars |> var hasindex i0 =>
        let initializer = createAlgloopVarAttributes(var, preExp, varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)
        '_vars[<%i0%>] = <%initializer%>;'
      ;separator="\n")
  <<
  <%varDecls%>
  <%preExp%>
  <%vars%>
  >>
end initAlgloopVarAttributes;

template createAlgloopVarAttributes(SimVar var, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Returns the initializer for one AlgLoopVar."
::=
  let nameStr = match var case SIMVAR(name=cref) then
    crefStrForWriteOutput(cref)

  let nominalStr = match var
    case SIMVAR(nominalValue=SOME(exp)) then
      let expPart = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      '<%expPart%>'
    else
      '1.0'

  let minStr = match var
    case SIMVAR(varKind=STATE_DER()) then
      '-HUGE_VAL'
    case SIMVAR(minValue=SOME(exp)) then
      let expPart = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      '<%expPart%>'
    else
      '-HUGE_VAL'

  let maxStr = match var
    case SIMVAR(varKind=STATE_DER()) then
      'HUGE_VAL'
    case SIMVAR(maxValue=SOME(exp)) then
      let expPart = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      '<%expPart%>'
    else
      'HUGE_VAL'

  'AlgloopVarAttributes("<%nameStr%>", <%nominalStr%>, <%minStr%>, <%maxStr%>)'
end createAlgloopVarAttributes;

template writeAlgloopvars(list<list<SimEqSystem>> continousEquations,list<SimEqSystem> discreteEquations, list<SimEqSystem> parameterEquations,
                          SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (continousEquations |> eqs => (eqs |> eq =>
      writeAlgloopvars2(eq, context, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation))
    ;separator=" ")

  <<
  <%algloopsolver%>
  >>
end writeAlgloopvars;


template writeAlgloopvars2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
    let size = listLength(nls.crefs)
  <<
   double algloopvars<%nls.index%>[<%size%>];
   _algLoop<%nls.index%>->getReal(algloopvars<%nls.index%>);
   <%nls.crefs |> name hasindex i0 =>
    let namestr = cref(name, useFlatArrayNotation)
    <<
     <%namestr%> = algloopvars<%nls.index%>[<%i0%>];
    >>
    ;separator="\n"%>

   >>
  case e as SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
    let size = listLength(ls.vars)
    let algloopid = ls.index
    let &varDeclsCref = buffer "" /*BUFD*/
  <<
   double algloopvars<%algloopid%>[<%size%>];
   _algLoop<%ls.index%>->getReal(algloopvars<%algloopid%>,NULL,NULL);

    <%ls.vars |> SIMVAR(__) hasindex i0 => '<%cref1(name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDeclsCref,stateDerVectorName,useFlatArrayNotation)%> = algloopvars<%algloopid%>[<%i0%>];' ;separator="\n"%>


   >>
 end writeAlgloopvars2;


template setAlgloopVars(SimEqSystem eq,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a non linear equation system."
::=
let &varDeclsCref = buffer "" /*BUFD*/
match eq
case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
  let size = listLength(nls.crefs)
  <<

   <%nls.crefs |> name hasindex i0 =>
    let namestr = cref1(name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDeclsCref,stateDerVectorName,useFlatArrayNotation)
    match name
    case CREF_QUAL(ident = "$PRE") then
      let varname = '_system-><%cref(componentRef, useFlatArrayNotation)%>'
      <<
      <%varname%> = vars[<%i0%>];
      _discrete_events->save(<%varname%>);
      >>
    else
      <<
      <%namestr%> = vars[<%i0%>];
      >>
   ;separator="\n"%>
  >>
  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
  <<
  <%ls.vars |> SIMVAR(__) hasindex i0 => '<%cref1(name, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%> = vars[<%i0%>];' ;separator="\n"%>
  >>
end setAlgloopVars;

template initAlgloopDimension(SimEqSystem eq, Text &varDecls /*BUFP*/)
 "Generates a non linear equation system."
::=
match eq
case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
  let size = listLength(nls.crefs)
  <<
  _dimAEq = <%size%>;
  AlgLoopDefaultImplementation::initialize();
  >>
  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
    match ls.jacobianMatrix
      case SOME(__) then
        let size = listLength(ls.vars)
        <<
        // Number of unknowns equations
        _dimAEq = <%size%>;
        AlgLoopDefaultImplementation::initialize();
        >>
      else
        let size = listLength(ls.vars)
        <<
        // Number of unknowns/equations according to type (0: double, 1: int, 2: bool)
        _dimAEq = <%size%>;
        AlgLoopDefaultImplementation::initialize();
        fill_array(__b, 0.0);
        >>
end initAlgloopDimension;

template alocateLinearSystem(SimEqSystem eq)
 "Generates a non linear equation system."
::=
match eq
case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
   let size = listLength(ls.vars)
   <<
    if(_useSparseFormat)
      __Asparse = shared_ptr<matrix_t> (new matrix_t);
    else
      __A = shared_ptr<AMATRIX>( new AMATRIX());
   >>
end alocateLinearSystem;

template alocateLinearSystemConstructor(SimEqSystem eq, Boolean useFlatArrayNotation)
 "Generates a non linear equation system."
::=
match eq
case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
   let size = listLength(ls.vars)
  <<
   ,__b(boost::extents[<%size%>])
  >>
end alocateLinearSystemConstructor;

template update(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(__) then
  <<
  <%equationFunctions(allEquations, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,contextSimulationDiscrete,stateDerVectorName,useFlatArrayNotation,boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")))%>

  <%clockedFunctions(getSubPartitions(clockedPartitions), simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextSimulationDiscrete, stateDerVectorName, useFlatArrayNotation, boolNot(stringEq(getConfigString(PROFILING_LEVEL), "none")))%>

  <%createEvaluateAll(allEquations, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,contextOther, stateDerVectorName, useFlatArrayNotation, boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")))%>

  <%createEvaluate(odeEquations, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,contextOther, boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")))%>

  <%createEvaluateZeroFuncs(equationsForZeroCrossings,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,contextOther)%>

  <%createEvaluateConditions(allEquations, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,contextOther, stateDerVectorName, useFlatArrayNotation)%>
  >>
end update;


template writeoutput(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__),simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
  let numParamvars = numProtectedParamVars(modelInfo)
  <<

   void <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeOutput(const IWriteOutput::OUTPUT command)
   {

     const output_int_vars_t& outputIntVars = _reader->getIntOutVars();
     const output_real_vars_t&  outputRealVars= _reader->getRealOutVars();
     const output_bool_vars_t& outputBoolVars = _reader->getBoolOutVars();
    //Write head line
    if (command & IWriteOutput::HEAD_LINE)
    {

      const all_names_t outputVarNames = make_tuple(outputRealVars.ourputVarNames,outputIntVars.ourputVarNames,outputBoolVars.ourputVarNames);
      const all_names_t outputVarDescription = make_tuple(outputRealVars.ourputVarDescription,outputIntVars.ourputVarDescription,outputBoolVars.ourputVarDescription);
      <%
      match   settings.outputFormat
        case "mat" then
        <<
         const all_names_t parameterVarNames =  make_tuple(outputRealVars.parameterNames,outputIntVars.parameterNames,outputBoolVars.parameterNames);
         const all_names_t parameterVarDescription =  make_tuple(outputRealVars.parameterDescription,outputIntVars.parameterDescription,outputBoolVars.parameterDescription);
        >>
       else
       <<
       const all_names_t parameterVarNames;
       const all_names_t parameterVarDescription;
       >>
      %>
      _writeOutput->write(outputVarNames,outputVarDescription,parameterVarNames,parameterVarDescription);

      <%
      match   settings.outputFormat
        case "mat" then
        <<
        const all_vars_t params = make_tuple(outputRealVars.outputParams,outputIntVars.outputParams,outputBoolVars.outputParams);

        >>
        else
        <<
        const all_vars_t params;
        >>
      %>
      _writeOutput->write(params,_global_settings->getStartTime(),_global_settings->getEndTime());
    }
    //Write the current values
    else
    {
      <%generateMeasureTimeStartCode("measuredFunctionStartValues", "writeOutput", "MEASURETIME_MODELFUNCTIONS")%>

      <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then
      <<
      HistoryImplType::value_type_r v3;
      <%(allEquations |> eqs => (eqs |> eq => writeoutputAlgloopsolvers(eq,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace));separator="\n")%>
      double residues [] = {<%(allEquations |> eqn => writeoutput3(eqn, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation));separator=","%>};
      for(int i=0;i<<%numResidues(allEquations)%>;i++) v3(i) = residues[i];

      <%generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "(*measureTimeFunctionsArray)[2]", "writeOutput", "MEASURETIME_MODELFUNCTIONS")%>

      _writeOutput->write(v,v2,v3,_simTime);
      >>
    else
      <<
      <%generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "(*measureTimeFunctionsArray)[2]",  "writeOutput", "MEASURETIME_MODELFUNCTIONS")%>
        write_data_t& container = _writeOutput->getFreeContainer();
        all_vars_time_t all_vars = make_tuple(outputRealVars.outputVars,outputIntVars.outputVars,outputBoolVars.outputVars,_simTime);
        neg_all_vars_t neg_all_vars =      make_tuple(outputRealVars.negateOutputVars,outputIntVars.negateOutputVars,outputBoolVars.negateOutputVars);
       _writeOutput->addContainerToWriteQueue(make_tuple(all_vars,neg_all_vars));
      >>
    %>
    }
   }

  >>
  //<%writeAlgloopvars(odeEquations,algebraicEquations, parameterEquations,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
end writeoutput;

template writeoutputAlgloopsolvers(SimEqSystem eq, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  match eq
  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
    then
      let num = ls.index
      match simCode
        case SIMCODE(modelInfo = MODELINFO(__)) then
        <<
        double* doubleResiduals<%num%> = new double[_algLoop<%num%>->getDimRHS()];
        _algLoop<%num%>->getRHS(doubleResiduals<%num%>);

        >>
      end match
  case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
    then
      let num = nls.index
      match simCode
        case SIMCODE(modelInfo = MODELINFO(__)) then
        <<
        double* doubleResiduals<%num%> = new double[_algLoop<%num%>->getDimRHS()];
        _algLoop<%num%>->getRHS(doubleResiduals<%num%>);

        >>
      end match
  case SES_MIXED(__)
    then
      let num = index
      match simCode
        case SIMCODE(modelInfo = MODELINFO(__)) then
        <<
        double* doubleResiduals<%num%> = new double[_algLoop<%num%>->getDimRHS()];
        _algLoop<%num%>->getRHS(doubleResiduals<%num%>);

        >>
      end match
  else
    " "
  end match
 end writeoutputAlgloopsolvers;

template writeoutput3(SimEqSystem eqn, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match eqn
  case SES_RESIDUAL(__) then
  <<
  >>
  case  SES_SIMPLE_ASSIGN(__) then
  let &varDeclsCref = buffer "" /*BUFD*/
  <<
  <%cref1(cref,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,contextOther,varDeclsCref,stateDerVectorName,useFlatArrayNotation)%>
  >>
  case SES_ARRAY_CALL_ASSIGN(__) then
  <<
  >>
  case SES_ALGORITHM(__) then
  <<
  >>
  case e as SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
  <<
  <%(ls.vars |> var hasindex myindex2 => writeoutput4(ls.index,myindex2));separator=",";empty%>
  >>
  case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
  <<
  <%(nls.eqs |> eq hasindex myindex2 => writeoutput4(nls.index,myindex2));separator=",";empty%>
  >>
  case SES_MIXED(__) then writeoutput3(cont,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case SES_WHEN(__) then
  <<
  >>
  else
  <<
  >>
end writeoutput3;

template writeoutput4(Integer index, Integer myindex2)
::=
 <<
 *(doubleResiduals<%index%>+<%myindex2%>)
 >>
end writeoutput4;

template generateHeaderIncludeString(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates header part of simulation file."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), extObjInfo=EXTOBJINFO(__)) then
  <<
  #pragma once
  #if defined(__TRICORE__) || defined(__vxworks)
    #define BOOST_EXTENSION_SYSTEM_DECL
    #define BOOST_EXTENSION_EVENTHANDLING_DECL
  #endif

  <%
  match(getConfigString(PROFILING_LEVEL))
     case("none") then ''
     case("all_perf") then
       <<
       #ifdef USE_SCOREP
         #include <Core/Utils/extension/measure_time_scorep.hpp>
       #else
         #include <Core/Utils/extension/measure_time_papi.hpp>
       #endif
       >>
     case("all_stat") then
       <<
       #ifdef USE_SCOREP
         #include <Core/Utils/extension/measure_time_scorep.hpp>
       #else
         #include <Core/Utils/extension/measure_time_statistic.hpp>
       #endif
       >>
     else
       <<
       #ifdef USE_SCOREP
         #include <Core/Utils/extension/measure_time_scorep.hpp>
       #else
         #include <Core/Utils/extension/measure_time_rdtsc.hpp>
       #endif
       >>
  end match
  %>

  #include <Core/System/SystemDefaultImplementation.h>

  //Forward declaration to speed-up the compilation process
  class Functions;
  class EventHandling;
  class DiscreteEvents;
  <%algloopForwardDeclaration(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>

  /*****************************************************************************
  *
  * Simulation code for <%lastIdentOfPath(modelInfo.name)%> generated by the OpenModelica Compiler.
  * System class <%lastIdentOfPath(modelInfo.name)%> implements the Interface IMixedSystem
  *
  *****************************************************************************/
  >>
end generateHeaderIncludeString;



template generateAlgloopHeaderInlcudeString(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Context context)
 "Generates header part of simulation file."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), extObjInfo=EXTOBJINFO(__)) then
   let modelname = lastIdentOfPath(modelInfo.name)
  let systemname = match context case  ALGLOOP_CONTEXT(genInitialisation=false,genJacobian=true) then '<%modelname%>Jacobian' else '<%modelname%>'
  <<
  #pragma once
  #if defined(__TRICORE__)
    #define BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL
    #define BOOST_EXTENSION_EVENTHANDLING_DECL
  #endif

  //class EventHandling;
  class <%systemname%>;
  class Functions;
  >>
end generateAlgloopHeaderInlcudeString;

template generateClassDeclarationCode(SimCode simCode,Context context,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,
                                      String additionalPublicMembers, String additionalProtectedMembers, String memberVariableDefinitions,
                                      String memberPreVariableDefinitions, Boolean useFlatArrayNotation)
 "Generates class declarations."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then

let friendclasses = generatefriendAlgloops(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
let algloopsolver = generateAlgloopsolverVariables(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace )
let jacalgloopsolver =  (jacobianMatrixes |> (mat, _, _, _, _, _, _) hasindex index0 =>
                        (mat |> (eqs,_,_) =>  generateAlgloopsolverVariables(eqs,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator="\n")
                        ;separator="")

let memberfuncs = generateEquationMemberFuncDecls(allEquations,"evaluate")
let clockedfuncs = generateClockedFuncDecls(getSubPartitions(clockedPartitions), "evaluate")
let conditionvariables =  conditionvariable(zeroCrossings,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)

match modelInfo
  case MODELINFO(vars=SIMVARS(__)) then
  let getstringvars = (List.partition(listAppend(listAppend(vars.stringAlgVars, vars.stringParamVars), vars.stringAliasVars), 100) |> ls hasindex idx =>
    <<
    void getString_<%idx%>(string* z);
    >>
    ;separator="\n")

  let initDeleteAlgloopSolverVars = (List.partition(listAppend(allEquations,initialEquations), 100) |> ls hasindex idx =>
    <<
    void initializeAlgloopSolverVariables_<%idx%>();
    void deleteAlgloopSolverVariables_<%idx%>();
    >>
    ;separator="\n")

  <<
  <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
  <<
  #define MEASURETIME_MODELFUNCTIONS
  >>%>

  class <%lastIdentOfPath(modelInfo.name)%>: public IContinuous, public IEvent, public IStepEvent, public ITime, public ISystemProperties <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then ', public IReduceDAE'%>, public SystemDefaultImplementation
  {
  <%friendclasses%>
  public:
      <%additionalPublicMembers%>

      <%lastIdentOfPath(modelInfo.name)%>(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects );
      <%lastIdentOfPath(modelInfo.name)%>(<%lastIdentOfPath(modelInfo.name)%> &instance);

      virtual ~<%lastIdentOfPath(modelInfo.name)%>();

      <%generateMethodDeclarationCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
      virtual bool getCondition(unsigned int index);

      shared_ptr<IAlgLoopSolverFactory> getAlgLoopSolverFactory();

  protected:
      //Methods:
      void initializeAlgloopSolverVariables();
      void initializeJacAlgloopSolverVariables();
      void deleteAlgloopSolverVariables();
      void deleteJacAlgloopSolverVariables();
      <%initDeleteAlgloopSolverVars%>
      <% /*match context case FMI_CONTEXT(__) then*/
      <<
      <%getstringvars%>
      >>
      %>
      bool isConsistent();

      //Saves all variables before an event is handled, is needed for the pre, edge and change operator
      void saveAll();

      void defineStateVars();
      void defineDerivativeVars();
      void defineAlgVars();
      void defineDiscreteAlgVars();
      void defineIntAlgVars();
      void defineBoolAlgVars();
      void defineStringAlgVars();
      void defineParameterRealVars();
      void defineParameterIntVars();
      void defineParameterBoolVars();
      void defineParameterStringVars();
      void defineAliasRealVars();
      void defineAliasIntVars();
      void defineAliasBoolVars();
      void defineAliasStringVars();

      void deleteObjects();

      //Variables:
      shared_ptr<EventHandling> _event_handling;
      shared_ptr<DiscreteEvents> _discrete_events;
      bool _state_var_reinitialized;

      //pointer to simVars-array to speedup simulation and compile time
      double* _pointerToRealVars;
      int* _pointerToIntVars;
      bool* _pointerToBoolVars;
      string* _pointerToStringVars;

      int _dimPartitions;
      bool* _partitionActivation;
      int* _stateActivator;

      <%memberVariableDefinitions%>
      <%memberPreVariableDefinitions%>
      <%conditionvariables%>
      Functions* _functions;

      shared_ptr<IPropertyReader> _reader;
      shared_ptr<IAlgLoopSolverFactory> _algLoopSolverFactory;    ///< Factory that provides an appropriate solver

      <%algloopsolver%>
      <%jacalgloopsolver%>
      <% if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
      <<
      #ifdef MEASURETIME_PROFILEBLOCKS
      std::vector<MeasureTimeData*> *measureTimeProfileBlocksArray;
      MeasureTimeValues *measuredProfileBlockStartValues, *measuredProfileBlockEndValues;
      #endif //MEASURETIME_PROFILEBLOCKS
      #ifdef MEASURETIME_MODELFUNCTIONS
      std::vector<MeasureTimeData*> *measureTimeFunctionsArray;
      MeasureTimeValues *measuredFunctionStartValues, *measuredFunctionEndValues;
      #endif //MEASURETIME_MODELFUNCTIONS
      >>%>
      /// Equations
      <%memberfuncs%>
      /// Clocked synchronous equations
      void evaluateClocked(int index);
      <%clockedfuncs%>
	  <%additionalProtectedMembers%>
      /*Additional member functions*/
	  <%extraFuncsDecl%>
   };
  >>
   /*! Equations Array. pointers to all the equation functions listed above stored in this
      array. It is used to randomly access and evaluate a single equation by index.
    */


    //void initialize_equations_array();
  /*

  typedef void (<%lastIdentOfPath(modelInfo.name)%>::*EquFuncPtr)();
    boost::array< EquFuncPtr, <%listLength(allEquations)%> > equations_array;
  */
end generateClassDeclarationCode;

template generateClockedFuncDecls(list<SubPartition> subPartitions, Text method)
::=
  let decls = (subPartitions |> subPartition hasindex i fromindex 1 =>
    match subPartition case SUBPARTITION(__) then
      <<
      /// Clocked partition <%i%>
      void evaluateClocked<%i%>(const UPDATETYPE command);


      <%generateEquationMemberFuncDecls(listAppend(equations, removedEquations), method)%>
      >>
      ; separator="\n")
  '<%decls%>'
end generateClockedFuncDecls;

template generateEquationMemberFuncDecls(list<SimEqSystem> allEquations,Text method)
::=
  match allEquations
  case _ then
    let equation_func_decls = (allEquations |> eq => generateEquationMemberFuncDecls2(eq,method) ;separator="\n")
    <<
    <%equation_func_decls%>
    >>
  end match
end generateEquationMemberFuncDecls;

template generateEquationMemberFuncDecls2(SimEqSystem eq,Text method)
::=
  match eq
  case  e as SES_MIXED(__) then
    <<
    void <%method%>_<%equationIndex(e.cont)%>();
    void <%method%>_<%equationIndex(eq)%>();
    >>
  else
    <<
    FORCE_INLINE void <%method%>_<%equationIndex(eq)%>();
    >>
  end match
end generateEquationMemberFuncDecls2;

template generateAlgloopClassDeclarationCode(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,SimEqSystem eq,Context context, Boolean useFlatArrayNotation)
 "Generates class declarations."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)
  let systemname = match context case  ALGLOOP_CONTEXT(genInitialisation=false,genJacobian=true)  then '<%modelname%>Jacobian' else '<%modelname%>'
  let amatrix =   match eq case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
    let size = listLength(ls.vars)
    let type = getConfigString(MATRIX_FORMAT)
    match type
    case ("dense") then
    <<
     matrix_t __A; //dense

     int * _indexValue;
     //b vector
     StatArrayDim1<double,<%size%>> __b;
    >>
    case ("sparse") then
    <<
     sparsematrix_t __A; //sparse

      int * _indexValue;
     //b vector
     StatArrayDim1<double,<%size%>> __b;
    >>
    else "A matrix type is not supported"
    end match
  let algvars = memberVariableAlgloop(modelInfo, useFlatArrayNotation)
  let constructorParams = constructorParamAlgloop(modelInfo, useFlatArrayNotation)
  match eq
 case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
   let type = getConfigString(MATRIX_FORMAT)

   let sortIndex = match ls.jacobianMatrix
       case SOME(__) then ''
   else match type case "sparse" then'virtual void  sortIndex();'
   end match
  <<
  class <%modelname%>Algloop<%ls.index%>: public IAlgLoop, public AlgLoopDefaultImplementation
  {
   public:
    <%modelname%>Algloop<%ls.index%>(<%systemname%>* system,
                                     double* z, double* zDot, bool* conditions,
                                     shared_ptr<DiscreteEvents> discrete_events);
    virtual ~<%modelname%>Algloop<%ls.index%>();

    <%generateAlgloopMethodDeclarationCode(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)%>

    bool getUseSparseFormat();

    <%sortIndex%>
    void setUseSparseFormat(bool value);
    float queryDensity();

   private:
    AlgloopVarAttributes _vars[<%listLength(ls.vars)%>];
    Functions* _functions;
    //states
    double* __z;
    //state derivatives
    double* __zDot;
    // A matrix
    <%amatrix%>
    bool* _conditions;
    shared_ptr<DiscreteEvents> _discrete_events;
    <%systemname%>* _system;
    bool _useSparseFormat;
  };
  >>
  case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
  <<
  class <%modelname%>Algloop<%nls.index%>: public IAlgLoop, public AlgLoopDefaultImplementation
  {
   public:
    <%modelname%>Algloop<%nls.index%>(<%systemname%>* system,
                                      double* z,double* zDot, bool* conditions,
                                      shared_ptr<DiscreteEvents> discrete_events);
    virtual ~<%modelname%>Algloop<%nls.index%>();

    <%generateAlgloopMethodDeclarationCode(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)%>

    bool getUseSparseFormat();
    void setUseSparseFormat(bool value);
    float queryDensity();

  private:
    AlgloopVarAttributes _vars[<%listLength(nls.crefs)%>];
    Functions* _functions;
    //states
    double* __z;
    //state derivatives
    double* __zDot;
    bool* _conditions;
    shared_ptr<DiscreteEvents> _discrete_events;
    <%systemname%>* _system;
    bool _useSparseFormat;
   };
  >>
end generateAlgloopClassDeclarationCode;

template DefaultImplementationCode(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(vars=SIMVARS(stateVars=states))) then
      <<
      // Release instance
      void <%lastIdentOfPath(modelInfo.name)%>::destroy()
      {
        delete this;
      }

      // Set current integration time
      void <%lastIdentOfPath(modelInfo.name)%>::setTime(const double& t)
      {
        SystemDefaultImplementation::setTime(t);
      }

      // Provide number (dimension) of variables according to the index
      int <%lastIdentOfPath(modelInfo.name)%>::getDimContinuousStates() const
      {
        return(SystemDefaultImplementation::getDimContinuousStates());
      }
	  int <%lastIdentOfPath(modelInfo.name)%>::getDimAE() const
      {
        return(SystemDefaultImplementation::getDimAE());
      }
      // Provide number (dimension) of variables according to the index
      int <%lastIdentOfPath(modelInfo.name)%>::getDimBoolean() const
      {
        return(SystemDefaultImplementation::getDimBoolean());
      }

      // Provide number (dimension) of variables according to the index
      int <%lastIdentOfPath(modelInfo.name)%>::getDimInteger() const
      {
        return(SystemDefaultImplementation::getDimInteger());
      }

      // Provide number (dimension) of variables according to the index
      int <%lastIdentOfPath(modelInfo.name)%>::getDimReal() const
      {
        return(SystemDefaultImplementation::getDimReal());
      }

      // Provide number (dimension) of variables according to the index
      int <%lastIdentOfPath(modelInfo.name)%>::getDimString() const
      {
        return(SystemDefaultImplementation::getDimString());
      }

      // Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
      int <%lastIdentOfPath(modelInfo.name)%>::getDimRHS() const
      {
        return(SystemDefaultImplementation::getDimRHS());
      }

      void <%lastIdentOfPath(modelInfo.name)%>::getContinuousStates(double* z)
      {
        SystemDefaultImplementation::getContinuousStates(z);
      }
      void <%lastIdentOfPath(modelInfo.name)%>::getNominalStates(double* z)
      {
        <%getNominalStateValues(states, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
      }

      // Set variables with given index to the system
      void <%lastIdentOfPath(modelInfo.name)%>::setContinuousStates(const double* z)
      {
        SystemDefaultImplementation::setContinuousStates(z);
      }

      double& <%lastIdentOfPath(modelInfo.name)%>::getRealStartValue(double& var)
      {
         return SystemDefaultImplementation::getRealStartValue(var);
       }

       bool& <%lastIdentOfPath(modelInfo.name)%>::getBoolStartValue(bool& var)
       {
         return SystemDefaultImplementation::getBoolStartValue(var);
       }

       int& <%lastIdentOfPath(modelInfo.name)%>::getIntStartValue(int& var)
       {
         return SystemDefaultImplementation::getIntStartValue(var);
       }

       string& <%lastIdentOfPath(modelInfo.name)%>::getStringStartValue(string& var)
       {
         return SystemDefaultImplementation::getStringStartValue(var);
       }

       void <%lastIdentOfPath(modelInfo.name)%>::setRealStartValue(double& var,double val)
       {
         SystemDefaultImplementation::setRealStartValue(var, val);
       }

       void <%lastIdentOfPath(modelInfo.name)%>::setBoolStartValue(bool& var,bool val)
       {
         SystemDefaultImplementation::setBoolStartValue(var, val);
       }

       void <%lastIdentOfPath(modelInfo.name)%>::setIntStartValue(int& var,int val)
       {
         SystemDefaultImplementation::setIntStartValue(var, val);
       }

       void <%lastIdentOfPath(modelInfo.name)%>::setStringStartValue(string& var,string val)
       {
         SystemDefaultImplementation::setStringStartValue(var, val);
       }

       void <%lastIdentOfPath(modelInfo.name)%>::setNumPartitions(int numPartitions)
       {
         _dimPartitions = numPartitions;
       }

       int <%lastIdentOfPath(modelInfo.name)%>::getNumPartitions()
       {
         return _dimPartitions;
       }
       void <%lastIdentOfPath(modelInfo.name)%>::setPartitionActivation(bool* partitions)
       {
         _partitionActivation = partitions;
       }

       void <%lastIdentOfPath(modelInfo.name)%>::getPartitionActivation(bool* partitions)
       {
         partitions = _partitionActivation;
       }

       int <%lastIdentOfPath(modelInfo.name)%>::getActivator(int state)
       {
         return (int)_stateActivator[state];
       }

      // Provide the right hand side (according to the index)
      void <%lastIdentOfPath(modelInfo.name)%>::getRHS(double* f)
      {
      <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then
      <<
      if(index == IContinuous::ALL_RESIDUES)
      {
        <%(allEquations |> eqs => (eqs |> eq => writeoutputAlgloopsolvers(eq,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace));separator="\n")%>
        double residues [] = {<%(allEquations |> eqn => writeoutput3(eqn, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation));separator=","%>};
        for(int i=0;i<<%numResidues(allEquations)%>;i++) *(f+i) = residues[i];
      }
      else SystemDefaultImplementation::getRHS(f);
      >>
      else
      <<
        SystemDefaultImplementation::getRHS(f);
      >>%>
      }

      void <%lastIdentOfPath(modelInfo.name)%>::setStateDerivatives(const double* f)
      {
        SystemDefaultImplementation::setStateDerivatives(f);
      }

      bool <%lastIdentOfPath(modelInfo.name)%>::isStepEvent()
      {
       throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"isStepEvent is not yet implemented");

      }

      void <%lastIdentOfPath(modelInfo.name)%>::setTerminal(bool terminal)
      {
        _terminal=terminal;
      }

      bool <%lastIdentOfPath(modelInfo.name)%>::terminal()
      {
        return _terminal;
      }

      bool <%lastIdentOfPath(modelInfo.name)%>::isAlgebraic()
      {
        return false; // Indexreduction is enabled
      }

      bool <%lastIdentOfPath(modelInfo.name)%>::provideSymbolicJacobian()
      {
        throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"provideSymbolicJacobian is not yet implemented");
      }

      void <%lastIdentOfPath(modelInfo.name)%>::handleEvent(const bool* events)
      {
        <%handleEvent(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
      }
      >>
  end match
end DefaultImplementationCode;


template getNominalStateValues(list<SimVar> stateVars,SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let nominalVars = stateVars |> SIMVAR(__) hasindex i0 =>
        match nominalValue
        case SOME(val)
        then
          let &preExp = buffer "" /*BUFD*/
          let &varDecls = buffer "" /*BUFD*/
          let value = '<%daeExp(val, contextOther, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
          <<
           <%varDecls%>
           <%preExp%>
           z[<%i0%>]=<%value%>;
          >>
        else
          <<
           z[<%i0%>] = 1.0;
          >>
       ;separator="\n"
<<
<%nominalVars%>
>>
end getNominalStateValues;


template algloopDefaultImplementationCode(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, SimEqSystem eq, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)

::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)
  let index = match eq
    case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then ls.index
    case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then nls.index
  let size = match eq
    case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then listLength(ls.vars)
    case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then listLength(nls.crefs)
  <<
  /// Provide index of equation
  int <%modelname%>Algloop<%index%>::getEquationIndex() const
  {
    return <%index%>;
  }

  /// Provide number (dimension) of variables according to data type
  int <%modelname%>Algloop<%index%>::getDimReal() const
  {
    return AlgLoopDefaultImplementation::getDimReal();
  }

  /// Provide number (dimension) of residuals according to data type
  int <%modelname%>Algloop<%index%>::getDimRHS() const
  {
    return AlgLoopDefaultImplementation::getDimRHS();
  }

  bool <%modelname%>Algloop<%index%>::isConsistent()
  {
    return _system->isConsistent();
  }

  /// Provide names of alg loop variables
  void <%modelname%>Algloop<%index%>::getNamesReal(const char** names) const
  {
    for (int i = 0; i < <%size%>; i++)
      names[i] = _vars[i].name;
  }

  /// Provide nominal values for alg loop variables
  void <%modelname%>Algloop<%index%>::getNominalReal(double* nominals) const
  {
    for (int i = 0; i < <%size%>; i++)
      nominals[i] = _vars[i].nominal;
  }

  /// Provide min values for alg loop variables
  void <%modelname%>Algloop<%index%>::getMinReal(double* mins) const
  {
    for (int i = 0; i < <%size%>; i++)
      mins[i] = _vars[i].min;
  }

  /// Provide max values for alg loop variables
  void <%modelname%>Algloop<%index%>::getMaxReal(double* maxs) const
  {
    for (int i = 0; i < <%size%>; i++)
      maxs[i] = _vars[i].max;
  }

  /// Return simulation time
  double <%modelname%>Algloop<%index%>::getSimTime() const
  {
    return _system->_simTime;
  }

  /// Provide variables with given index to the system
  void <%modelname%>Algloop<%index%>::getReal(double* vars) const
  {
    <%getAlgloopVars(eq, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)%>
  }

  /// Set variables with given index to the system
  void <%modelname%>Algloop<%index%>::setReal(const double* vars)
  {
    <%setAlgloopVars(eq,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)%>
  }

  >>
end algloopDefaultImplementationCode;


template generateMethodDeclarationCode(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(vars = vars as SIMVARS(__))) then
    <<
    /// Releases the Modelica System
    virtual void destroy();
    /// Provide number (dimension) of variables according to the index
    virtual int getDimContinuousStates() const;
	virtual int getDimAE() const;
    /// Provide number (dimension) of boolean variables
    virtual int getDimBoolean() const;
    /// Provide number (dimension) of integer variables
    virtual int getDimInteger() const;
    /// Provide number (dimension) of real variables
    virtual int getDimReal() const;
    /// Provide number (dimension) of string variables
    virtual int getDimString() const;
    /// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
    virtual int getDimRHS()const;
    virtual double& getRealStartValue(double& var);
    virtual bool& getBoolStartValue(bool& var);
    virtual int& getIntStartValue(int& var);
    virtual string& getStringStartValue(string& var);
    virtual void setRealStartValue(double& var,double val);
    virtual void setBoolStartValue(bool& var,bool val);
    virtual void setIntStartValue(int& var,int val);
    virtual void setStringStartValue(string& var,string val);

    virtual void setNumPartitions(int numPartitions);
    virtual int getNumPartitions();
    virtual void setPartitionActivation(bool* partitions);
    virtual void getPartitionActivation(bool* partitions);
    virtual int getActivator(int state);

    //Resets all time events

    // Provide variables with given index to the system
    virtual void getContinuousStates(double* z);
    virtual void getNominalStates(double* z);
    // Set variables with given index to the system
    virtual void setContinuousStates(const double* z);

    // Update transfer behavior of the system of equations according to command given by solver
    virtual bool evaluateAll(const UPDATETYPE command = IContinuous::UNDEF_UPDATE);
    virtual void evaluateODE(const UPDATETYPE command = IContinuous::UNDEF_UPDATE);
    virtual void evaluateZeroFuncs(const UPDATETYPE command = IContinuous::UNDEF_UPDATE);
    virtual bool evaluateConditions(const UPDATETYPE command);

    // Provide the right hand side (according to the index)
    virtual void getRHS(double* f);
    virtual void setStateDerivatives(const double* f);

    //Provide number (dimension) of zero functions
    virtual int getDimZeroFunc();
    //Provide number (dimension) of zero functions
    virtual int getDimClock();
    //Provides current values of root/zero functions
    virtual void getZeroFunc(double* f);
    virtual void setConditions(bool* c);
    virtual void getConditions(bool* c);
    virtual void getClockConditions(bool* c);

    //Called to handle an event
    virtual void handleEvent(const bool* events);
    //Checks if a discrete variable has changed and triggers an event
    virtual bool checkForDiscreteEvents();
    virtual bool isStepEvent();
    //sets the terminal status
    virtual void setTerminal(bool);
    //returns the terminal status
    virtual bool terminal();



    // M is regular
    virtual bool isODE();
    // M is singular
    virtual bool isAlgebraic();

    virtual int getDimTimeEvent() const;
    //gibt die Time events (Startzeit und Frequenz) zuruck
    virtual void getTimeEvent(time_event_type& time_events);
    //Wird vom Solver zur Behandlung der Time events aufgerufen (wenn zero_sign[i] = 0  kein time event,zero_sign[i] = n  Anzahl von vorgekommen time events )
    virtual void handleTimeEvent(int* time_events);
    /// Set current integration time
    virtual void setTime(const double& time);

    // System is able to provide the Jacobian symbolically
    virtual bool provideSymbolicJacobian();

    virtual void restoreOldValues();
    virtual void restoreNewValues();
    virtual bool stepCompleted(double time);
    virtual bool stepStarted(double time);

    <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then
    <<
    // Returns labels for a labeled DAE
    virtual label_list_type getLabels();
    // Sets all algebraic and state varibales for current time
    virtual void setVariables(const ublas::vector<double>& variables, const ublas::vector<double>& variables2);
    >>
    %>

    /// Provide boolean variables
    virtual void getBoolean(bool* z);
    /// Provide integer variables
    virtual void getInteger(int* z);
    /// Provide real variables
    virtual void getReal(double* z);
    /// Provide real variables
    virtual void getString(std::string* z);
    /// Provide boolean variables
    virtual void setBoolean(const bool* z);
    /// Provide integer variables
    virtual void setInteger(const int* z);
    /// Provide real variables
    virtual void setReal(const double* z);
    /// Provide real variables
    virtual void setString(const std::string* z);
    >>
end generateMethodDeclarationCode;
   /*
    deactivated: MethodDeclarationCode virtual void saveDiscreteVars();
    <%
    let discVarCount = intAdd(intAdd(listLength(vars.algVars), listLength(vars.discreteAlgVars)), intAdd( listLength(vars.intAlgVars) , listLength(vars.boolAlgVars )))
    let saveDiscreteVarFuncs = (List.partition(List.intRange(stringInt(discVarCount)), 100) |> ls hasindex idx => 'virtual void saveDiscreteVars_<%idx%>(double *discreteVars);';separator="\n")
    <<
    <%saveDiscreteVarFuncs%>
    >>
    %>
   */

 /*! Evaluates only the equations whose indices are passed to it. */
    //bool evaluate_selective(const std::vector<int>& indices);

    /*! Evaluates only a single equation by index. */
    //bool evaluate_single(const int index);
template generateAlgloopMethodDeclarationCode(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)

::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
    <<
    /// Provide index of equation
    virtual int getEquationIndex() const;
    /// Provide number (dimension) of variables according to data type
    virtual int getDimReal() const;
    /// Provide number (dimension) of residuals according to data type
    virtual int getDimRHS() const;
     /// (Re-) initialize the system of equations
    virtual void initialize();

    /// Provide names of alg loop variables
    virtual void getNamesReal(const char** names) const;
    /// Provide nominal values for alg loop variables
    virtual void getNominalReal(double* nominals) const;
    /// Provide min values for alg loop variables
    virtual void getMinReal(double* mins) const;
    /// Provide max values for alg loop variables
    virtual void getMaxReal(double* maxs) const;

    /// Return simulation time
    virtual double getSimTime() const;
    /// Provide variables with given index to the system
    virtual void getReal(double* vars) const;
    /// Set variables with given index to the system
    virtual void setReal(const double* vars);

    /// Evaluate equations for given variables
    virtual void evaluate();
    /// Provide the right hand side (residuals)
    virtual void getRHS(double* vars) const;
    <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then
    <<
    /// Provide dimensions of residuals for linear equation systems
    virtual int giveDimResiduals(int index);
    /// Provide the residuals for linear equation systems
    virtual void giveResiduals(double* vars);
    >>%>
    virtual const matrix_t& getSystemMatrix() ;
    virtual const sparsematrix_t& getSystemSparseMatrix() ;
    virtual bool isLinear();
    virtual bool isLinearTearing();
    virtual bool isConsistent();
    virtual void getSparseAdata(double* data, int nonzeros);

    >>
//void writeOutput(HistoryImplType::value_type_v& v ,vector<string>& head ,const IMixedSystem::OUTPUT command  = IMixedSystem::UNDEF_OUTPUT);
end generateAlgloopMethodDeclarationCode;

template memberVariableDefine(ModelInfo modelInfo, HashTableCrIListArray.HashTable varToArrayIndexMapping, Text indexForUndefinedReferencesReal, Text indexForUndefinedReferencesInt,
                        Text indexForUndefinedReferencesBool, Text indexForUndefinedReferencesString, Boolean createDebugCode, Boolean useFlatArrayNotation)
 /*Define membervariable in simulation file.*/
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
   <<
   /*state vars*/
   <%vars.stateVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, createDebugCode, "Real", true)
   ;separator="\n"%>
   /*derivative vars*/
   <%vars.derivativeVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, createDebugCode, "Real", true)
   ;separator="\n"%>
   /*parameter real vars*/
   <%vars.paramVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, createDebugCode, "Real", true)
   ;separator="\n"%>
   /*parameter int vars*/
   <%vars.intParamVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesInt, useFlatArrayNotation, createDebugCode, "Int", true)
   ;separator="\n"%>
   /*parameter bool vars*/
   <%vars.boolParamVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesBool, useFlatArrayNotation, createDebugCode, "Bool", true)
   ;separator="\n"%>
   /*string parameter variables*/
   <%vars.stringParamVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesString, useFlatArrayNotation, createDebugCode, "String", true)
   ;separator="\n"%>
   /*string alias variables*/
   <%vars.stringAliasVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesString, useFlatArrayNotation, createDebugCode, "String", true)
   ;separator="\n"%>
   /*external variables*/
   <%vars.extObjVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, createDebugCode, "Real", false)
   ;separator="\n"%>
   /*alias real vars*/
   <%vars.aliasVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, createDebugCode, "Real", true)
   ;separator="\n"%>
   /*alias int vars*/
   <%vars.intAliasVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesInt, useFlatArrayNotation, createDebugCode, "Int", true)
   ;separator="\n"%>
   /*alias bool vars*/
   <%vars.boolAliasVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesBool, useFlatArrayNotation, createDebugCode, "Bool", true)
   ;separator="\n"%>
   /*string algvars*/
   <%vars.stringAlgVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesString, useFlatArrayNotation, createDebugCode, "String", true)
   ;separator="\n"%>
   >>
end memberVariableDefine;

template memberVariableDefinePreVariables(ModelInfo modelInfo, HashTableCrIListArray.HashTable varToArrayIndexMapping, Text indexForUndefinedReferencesReal, Text indexForUndefinedReferencesInt,
                                    Text indexForUndefinedReferencesBool, Text indexForUndefinedReferencesString, Boolean createDebugCode, Boolean useFlatArrayNotation)
 "Define membervariable in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  //Variables saved for pre, edge and change operator
   /*real algvars*/
  <%vars.algVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, createDebugCode, "Real", true)
  ;separator="\n"%>
  /*discrete algvars*/
  <%vars.discreteAlgVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, createDebugCode, "Real", true)
  ;separator="\n"%>
   /*int algvars*/
   <%vars.intAlgVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesInt, useFlatArrayNotation, createDebugCode, "Int", true)
  ;separator="\n"%>
  /*bool algvars*/
  <%vars.boolAlgVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesBool, useFlatArrayNotation, createDebugCode, "Bool", true)
  ;separator="\n"%>
  >>
end memberVariableDefinePreVariables;

template memberVariableInitialize(ModelInfo modelInfo, HashTableCrIListArray.HashTable varToArrayIndexMapping, Text indexForUndefinedReferencesReal, Text indexForUndefinedReferencesInt,
                                  Text indexForUndefinedReferencesBool, Text indexForUndefinedReferencesString, Boolean createDebugCode, Boolean useFlatArrayNotation, Text& additionalConstructorVariables, Text& additionalFunctionDefinitions)
::=
  match modelInfo
    case MODELINFO(vars=SIMVARS(__),name=name) then
      let classname = lastIdentOfPath(name)
      let &additionalStateVarFunctionCalls = buffer ""
      let &additionalDerivativeVarFunctionCalls = buffer ""
      let &additionalAlgVarFunctionCalls = buffer ""
      let &additionalDiscreteAlgVarFunctionCalls = buffer ""
      let &additionalIntAlgVarFunctionCalls = buffer ""
      let &additionalBoolAlgVarFunctionCalls = buffer ""
      let &additionalStringAlgVarFunctionCalls = buffer ""
      let &additionalParameterRealVarFunctionCalls = buffer ""
      let &additionalParameterIntVarFunctionCalls = buffer ""
      let &additionalParameterBoolVarFunctionCalls = buffer ""
      let &additionalParameterStringVarFunctionCalls = buffer ""
      let &additionalAliasRealVarFunctionCalls = buffer ""
      let &additionalAliasIntVarFunctionCalls = buffer ""
      let &additionalAliasBoolVarFunctionCalls = buffer ""
      let &additionalAliasStringVarFunctionCalls = buffer ""
      let &returnValue = buffer ""

      <<
      //StateVars
      <%List.partition(vars.stateVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineStateVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, createDebugCode, "Real", additionalStateVarFunctionCalls, additionalConstructorVariables, additionalFunctionDefinitions) ;separator="\n"%>

      void <%classname%>::defineStateVars()
      {
        <%additionalStateVarFunctionCalls%>
      }

      //DerivativeVars
      <%List.partition(vars.derivativeVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineDerivativeVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, createDebugCode, "Real", additionalDerivativeVarFunctionCalls, additionalConstructorVariables, additionalFunctionDefinitions) ;separator="\n"%>

      void <%classname%>::defineDerivativeVars()
      {
        <%additionalDerivativeVarFunctionCalls%>
      }

      //AlgVars
      <%List.partition(vars.algVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineAlgVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, createDebugCode, "Real",
                                          additionalAlgVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>

      void <%classname%>::defineAlgVars()
      {
        <%additionalAlgVarFunctionCalls%>
      }

      //DiscreteAlgVars
      <%List.partition(vars.discreteAlgVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineDiscreteAlgVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, createDebugCode, "Real",
                                          additionalDiscreteAlgVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>

      void <%classname%>::defineDiscreteAlgVars()
      {
        <%additionalDiscreteAlgVarFunctionCalls%>
      }

      //IntAlgVars
      <%List.partition(vars.intAlgVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineIntAlgVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesInt, useFlatArrayNotation, createDebugCode, "Int",
                                          additionalIntAlgVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineIntAlgVars()
      {
        <%additionalIntAlgVarFunctionCalls%>
      }

      //BoolAlgVars
      <%List.partition(vars.boolAlgVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineBoolAlgVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesBool, useFlatArrayNotation, createDebugCode, "Bool",
                                          additionalBoolAlgVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineBoolAlgVars()
      {
        <%additionalBoolAlgVarFunctionCalls%>
      }

      //StringAlgVars
      <%List.partition(vars.stringAlgVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineStringAlgVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesString, useFlatArrayNotation, createDebugCode, "String",
                                          additionalStringAlgVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineStringAlgVars()
      {
        <%additionalStringAlgVarFunctionCalls%>
      }

      //ParameterRealVars
      <%List.partition(vars.paramVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineParameterRealVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, createDebugCode, "Real",
                                          additionalParameterRealVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineParameterRealVars()
      {
        <%additionalParameterRealVarFunctionCalls%>
      }

      //ParameterIntVars
      <%List.partition(vars.intParamVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineParameterIntVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesInt, useFlatArrayNotation, createDebugCode, "Int",
                                          additionalParameterIntVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineParameterIntVars()
      {
        <%additionalParameterIntVarFunctionCalls%>
      }

      //ParameterBoolVars
      <%List.partition(vars.boolParamVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineParameterBoolVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesBool, useFlatArrayNotation, createDebugCode, "Bool",
                                          additionalParameterBoolVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineParameterBoolVars()
      {
        <%additionalParameterBoolVarFunctionCalls%>
      }

      //ParameterStringVars
      <%List.partition(vars.stringParamVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineParameterStringVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesString, useFlatArrayNotation, createDebugCode, "String",
                                          additionalParameterStringVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineParameterStringVars()
      {
        <%additionalParameterStringVarFunctionCalls%>
      }

      //AliasRealVars
      <%List.partition(vars.aliasVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineAliasRealVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, createDebugCode, "Real",
                                          additionalAliasRealVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineAliasRealVars()
      {
        <%additionalAliasRealVarFunctionCalls%>
      }

      //AliasIntVars
      <%List.partition(vars.intAliasVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineAliasIntVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesInt, useFlatArrayNotation, createDebugCode, "Int",
                                          additionalAliasIntVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineAliasIntVars()
      {
        <%additionalAliasIntVarFunctionCalls%>
      }

      //AliasBoolVars
      <%List.partition(vars.boolAliasVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineAliasBoolVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesBool, useFlatArrayNotation, createDebugCode, "Bool",
                                          additionalAliasBoolVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineAliasBoolVars()
      {
        <%additionalAliasBoolVarFunctionCalls%>
      }

      //AliasStringVars
      <%List.partition(vars.stringAliasVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineAliasStringVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesString, useFlatArrayNotation, createDebugCode, "String",
                                          additionalAliasStringVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineAliasStringVars()
      {
        <%additionalAliasStringVarFunctionCalls%>
      }
      >>
end memberVariableInitialize;

template memberVariableInitializeWithSplit(list<SimVar> simVars, Text idx, Text functionPrefix, Text className, HashTableCrIListArray.HashTable varToArrayIndexMapping, Text indexForUndefinedReferences, Boolean useFlatArrayNotation,
                                   Boolean createDebugCode, String type, Text& additionalFunctionCalls, Text& additionalConstructorVariables, Text& additionalFunctionDefinitions)
::=
  let &additionalFunctionCalls += '  <%functionPrefix%>_<%idx%>();<%\n%>'
  let &additionalFunctionDefinitions += 'void <%functionPrefix%>_<%idx%>();<%\n%>'
  <<
  void <%className%>::<%functionPrefix%>_<%idx%>()
  {
    <%simVars |> var =>
        memberVariableInitialize2(var, varToArrayIndexMapping, indexForUndefinedReferences, useFlatArrayNotation, createDebugCode, type, additionalConstructorVariables)
        ;separator="\n"%>
  }
  >>
end memberVariableInitializeWithSplit;

template memberVariableInitialize2(SimVar simVar, HashTableCrIListArray.HashTable varToArrayIndexMapping, Text indexForUndefinedReferences, Boolean useFlatArrayNotation,
                                   Boolean createDebugCode, String type, Text& additionalConstructorVariables)
::=
  match simVar
    case SIMVAR(numArrayElement={},arrayCref=NONE(),name=CREF_IDENT(subscriptLst=_::_)) then ''

    case SIMVAR(numArrayElement={},arrayCref=NONE(),name=name) then
      match(createDebugCode)
        case true then
          let index = '<%listHead(SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,true,indexForUndefinedReferences))%>'
          let &additionalConstructorVariables += ',<%cref(name,useFlatArrayNotation)%>(getSimVars()->init<%type%>Var(<%index%>))<%\n%>'
          ""
        else ""
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(_),numArrayElement=num)
    case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(_),numArrayElement=num) then
      let &dims = buffer "" /*BUFD*/
      let arrayName = arraycref2(name,dims)
      let typeString = variableType(type_)
      let array_num_elem =  arrayNumElements(name, v.numArrayElement)
      if(useFlatArrayNotation) then
        let &additionalConstructorVariables += '"not implemented"<%\n%>'
        ""
      else
        match dims
          case "0" then
            match(createDebugCode)
              case true then
                let index = '<%listHead(SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,true,indexForUndefinedReferences))%>'
                let& additionalConstructorVariables += ',<%arrayName%>(getSimVars()->init<%type%>Var(<%index%>))'
                ""
              else ""
          else
            let size =  Util.mulStringDelimit2Int(array_num_elem,",")
            if SimCodeUtil.isVarIndexListConsecutive(varToArrayIndexMapping,name) then
              let arrayHeadIdx = listHead(SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,true,indexForUndefinedReferences))
              <<
              <%arrayName%> = StatArrayDim<%dims%><<%typeString%>, <%arrayextentDims(name, v.numArrayElement)%>, true>(&_pointerTo<%type%>Vars[<%arrayHeadIdx%>]);
              >>
            else
              let arrayIndices = SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,true,indexForUndefinedReferences) |> idx => '<%idx%>'; separator=" LIST_SEP "
              <<
              <%typeString%>* <%arrayName%>_ref_data[<%size%>];
              getSimVars()->init<%type%>AliasArray(LIST_OF <%arrayIndices%> LIST_END, <%arrayName%>_ref_data);
              <%arrayName%> = RefArrayDim<%dims%><<%typeString%>, <%arrayextentDims(name, v.numArrayElement)%>>(<%arrayName%>_ref_data);
              >>
   /*special case for variables that marked as array but are not arrays */
    case SIMVAR(numArrayElement=_::_) then

      let& dims = buffer "" /*BUFD*/
      let varName = arraycref2(name,dims)
      let varType = variableType(type_)
      match dims
        case "0" then
          match createDebugCode
            case true then
              let index = '<%listHead(SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,true,indexForUndefinedReferences))%>'
              let& additionalConstructorVariables += ',<%varName%>(getSimVars()->init<%type%>Var(<%index%>))'
              ""
            else ""
        else ''
      end match
end memberVariableInitialize2;


template memberVariableAlgloop(ModelInfo modelInfo, Boolean useFlatArrayNotation)
 "Define membervariable in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
<<  <%vars.algVars |> var =>
    memberVariableDefineReference2(var, "algebraics","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.algVars then ";" else ""%>
    <%vars.discreteAlgVars |> var =>
    memberVariableDefineReference2(var, "algebraics","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.discreteAlgVars then ";" else ""%>
   <%vars.paramVars |> var =>
    memberVariableDefineReference2(var, "parameters","",useFlatArrayNotation)
  ;separator=";\n"%> <%if vars.paramVars then ";" else ""%>
   <%vars.aliasVars |> var =>
    memberVariableDefineReference2(var, "aliasVars","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.aliasVars then ";" else ""%>
  <%vars.intAlgVars |> var =>
    memberVariableDefineReference("int", var, "intVariables.algebraics","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.intAlgVars then ";" else ""%>
  <%vars.intParamVars |> var =>
    memberVariableDefineReference("int", var, "intVariables.parameters","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.intParamVars then ";" else " "%>
   <%vars.intAliasVars |> var =>
   memberVariableDefineReference("int", var, "intVariables.AliasVars","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.intAliasVars then ";" else " "%>
  <%vars.boolAlgVars |> var =>
    memberVariableDefineReference("bool",var, "boolVariables.algebraics","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.boolAlgVars then ";" else ""%>
  <%vars.boolParamVars |> var =>
    memberVariableDefineReference("bool",var, "boolVariables.parameters","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.boolParamVars then ";" else " "%>
   <%vars.boolAliasVars |> var =>
     memberVariableDefineReference("bool ",var, "boolVariables.AliasVars","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.boolAliasVars then ";" else ""%>
  <%vars.stringAlgVars |> var =>
    memberVariableDefineReference("string",var, "stringVariables.algebraics","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.stringAlgVars then ";" else ""%>
  <%vars.stringParamVars |> var =>
    memberVariableDefineReference("string",var, "stringVariables.parameters","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.stringParamVars then ";" else " "%>
  <%vars.stringAliasVars |> var =>
    memberVariableDefineReference("string",var, "stringVariables.AliasVars","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.stringAliasVars then ";" else ""%>
  >>
end memberVariableAlgloop;


template constructorParamAlgloop(ModelInfo modelInfo, Boolean useFlatArrayNotation)
 "Define membervariable in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  <%vars.algVars |> var =>
    memberVariableDefineReference2(var, "algebraics","_",useFlatArrayNotation)
  ;separator=","%><%if vars.algVars then "," else ""%>
  <%vars.discreteAlgVars |> var =>
    memberVariableDefineReference2(var, "algebraics","_",useFlatArrayNotation)
  ;separator=","%><%if vars.discreteAlgVars then "," else ""%>
  <%vars.paramVars |> var =>
    memberVariableDefineReference2(var, "parameters","_",useFlatArrayNotation)
  ;separator=","%><%if vars.paramVars then "," else ""%>
  <%vars.aliasVars |> var =>
    memberVariableDefineReference2(var, "aliasVars","_",useFlatArrayNotation)
  ;separator=","%><%if vars.aliasVars then "," else ""%>
   <%vars.intAlgVars |> var =>
    memberVariableDefineReference("int", var, "intVariables.algebraics","_",useFlatArrayNotation)
  ;separator=","%> <%if vars.intAlgVars then "," else ""%>
  <%vars.intParamVars |> var =>
    memberVariableDefineReference("int", var, "intVariables.parameters","_",useFlatArrayNotation)
  ;separator=","%> <%if vars.intParamVars then "," else ""%>
  <%vars.intAliasVars |> var =>
    memberVariableDefineReference("int", var, "intVariables.AliasVars","_",useFlatArrayNotation)
  ;separator=","%><%if vars.intAliasVars then "," else ""%>
  <%vars.boolAlgVars |> var =>
    memberVariableDefineReference("bool",var, "boolVariables.algebraics","_",useFlatArrayNotation)
  ;separator=","%><%if vars.boolAlgVars then "," else ""%>
  <%vars.boolParamVars |> var =>
    memberVariableDefineReference("bool",var, "boolVariables.parameters","_",useFlatArrayNotation)
  ;separator=","%><%if vars.boolParamVars then "," else ""%>
   <%vars.boolAliasVars |> var =>
    memberVariableDefineReference("bool ",var, "boolVariables.AliasVars","_",useFlatArrayNotation)
  ;separator=","%><%if vars.boolAliasVars then "," else ""%>
  <%vars.stringAlgVars |> var =>
    memberVariableDefineReference("string",var, "stringVariables.algebraics","_",useFlatArrayNotation)
  ;separator=","%><%if vars.stringAlgVars then "," else "" %>
  <%vars.stringParamVars |> var =>
    memberVariableDefineReference("string",var, "stringVariables.parameters","_",useFlatArrayNotation)
  ;separator=","%><%if vars.stringParamVars then "," else ""%>
  <%vars.stringAliasVars |> var =>
    memberVariableDefineReference("string",var, "stringVariables.AliasVars","_",useFlatArrayNotation)
  ;separator=","%><%if vars.stringAliasVars then "," else ""%>

  >>
end constructorParamAlgloop;


template initAlgloopParams(ModelInfo modelInfo,Text& arrayInit, Boolean useFlatArrayNotation)
 "Define membervariable in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then

 <<
   /* vars.algVars */
   <%vars.algVars |> var =>
    initAlgloopParam(var, "algebraics",arrayInit, useFlatArrayNotation)
  ;separator=","%> <%if vars.algVars then "," else ""%>
   /* vars.discreteAlgVars */
  <%vars.discreteAlgVars |> var =>
    initAlgloopParam( var, "algebraics",arrayInit, useFlatArrayNotation)
  ;separator=","%> <%if vars.discreteAlgVars then "," else ""%>
   /* vars.paramVars */
  <%vars.paramVars |> var =>
    initAlgloopParam(var, "parameters",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.paramVars then "," else ""%>
   /* vars.aliasVars */
   <%vars.aliasVars |> var =>
    initAlgloopParam(var, "aliasVars",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.aliasVars then "," else ""%>
   /* vars.intAlgVars */
  <%vars.intAlgVars |> var =>
    initAlgloopParam( var, "intVariables.algebraics",arrayInit, useFlatArrayNotation)
  ;separator=","%> <%if vars.intAlgVars then "," else ""%>
   /* vars.intParamVars */
  <%vars.intParamVars |> var =>
    initAlgloopParam( var, "intVariables.parameters",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.intParamVars then "," else ""%>
   /* vars.intAliasVars */
  <%vars.intAliasVars |> var =>
    initAlgloopParam( var, "intVariables.AliasVars",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.intAliasVars then "," else ""%>
   /* vars.boolAlgVars */
  <%vars.boolAlgVars |> var =>
    initAlgloopParam(var, "boolVariables.algebraics",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.boolAlgVars then "," else ""%>
   /* vars.boolParamVars */
  <%vars.boolParamVars |> var =>
    initAlgloopParam(var, "boolVariables.parameters",arrayInit, useFlatArrayNotation)
  ;separator=","%> <%if vars.boolParamVars then "," else ""%>
   /* vars.boolAliasVars */
  <%vars.boolAliasVars |> var =>
    initAlgloopParam(var, "boolVariables.AliasVars",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.boolAliasVars then "," else ""%>
   /* vars.stringAlgVars */
   <%if vars.stringAlgVars then "," else ""%>
  <%vars.stringAlgVars |> var =>
    initAlgloopParam(var, "stringVariables.algebraics",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.stringAlgVars then "," else "" %>
   /* vars.stringParamVars */
   <%vars.stringParamVars |> var =>
    initAlgloopParam(var, "stringVariables.parameters",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.stringParamVars then "," else "" %>
   /* vars.stringAliasVars */
  <%vars.stringAliasVars |> var =>
    initAlgloopParam(var, "stringVariables.AliasVars",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.stringAliasVars then "," else "" %>
 >>
end initAlgloopParams;


template memberVariableDefineReference(String type,SimVar simVar, String arrayName,String pre, Boolean useFlatArrayNotation)
::=
match simVar

       case SIMVAR(numArrayElement={},arrayCref=NONE(),name=CREF_IDENT(subscriptLst=_::_)) then ''

      case SIMVAR(numArrayElement={}) then
      <<
      <%type%>& <%pre%><%cref(name,useFlatArrayNotation)%>
      >>
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(_),numArrayElement=num) then
      <<
      multi_array<<%variableType(type_)%>,<%listLength(num)%>>& <%pre%><%arraycref(name, useFlatArrayNotation)%>
      >>
     case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(_),numArrayElement=num) then
      <<
      multi_array<<%variableType(type_)%>,<%listLength(num)%>>& <%pre%><%arraycref(name, useFlatArrayNotation)%>
      >>
      case SIMVAR(numArrayElement=_::_) then
      let& dims = buffer "" /*BUFD*/
      let varName = arraycref2(name,dims)
      let varType = variableType(type_)
      match dims case "0" then  ''
end memberVariableDefineReference;


template memberVariableDefine2(SimVar simVar, HashTableCrIListArray.HashTable varToArrayIndexMapping, Text indexForUndefinedReferences,
                              Boolean useFlatArrayNotation, Boolean createDebugCode, String type, Boolean createRefVar)
::=
  match simVar
    case SIMVAR(numArrayElement={},arrayCref=NONE(),name=CREF_IDENT(subscriptLst=_::_)) then ''

    case SIMVAR(numArrayElement={},arrayCref=NONE(),name=name,type_=type_) then
      match createDebugCode
        case true then
          <<
          <%variableType(type_)%><%if createRefVar then '&' else ''%> <%cref(name,useFlatArrayNotation)%>;
          >>
        else
          if createRefVar then
            let index = '<%listHead(SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,true,indexForUndefinedReferences))%>'
            <<
            #define <%cref(name,useFlatArrayNotation)%> _pointerTo<%type%>Vars[<%index%>]
            >>
          else
            '<%variableType(type_)%> <%cref(name,useFlatArrayNotation)%>;'

    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(_),numArrayElement=num)
    case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(_),numArrayElement=num) then
      let &dims = buffer "" /*BUFD*/
      let arrayName = arraycref2(name,dims)
      let typeString = variableType(type_)
      let array_dimensions =  arrayextentDims(name, v.numArrayElement)
      match dims
      case "0" then
        match createDebugCode
          case true then
            <<
            <%typeString%><%if createRefVar then '&' else ''%> <%arrayName%>;
            >>
          else
            if createRefVar then
              let index = '<%listHead(SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,true,indexForUndefinedReferences))%>'
              <<
              #define <%arrayName%> _pointerTo<%type%>Vars[<%index%>]
              >>
            else
              '<%typeString%> <%arrayName%>;'
      else
        if SimCodeUtil.isVarIndexListConsecutive(varToArrayIndexMapping,name) then
          <<
          StatArrayDim<%dims%><<%typeString%>, <%array_dimensions%>, <%createRefVar%>> <%arrayName%>;
          >>
        else
          <<
          RefArrayDim<%dims%><<%typeString%>, <%array_dimensions%>> <%arrayName%>;
          >>
   /*special case for variables that marked as array but are not arrays */
    case SIMVAR(numArrayElement=_::_) then
      let& dims = buffer "" /*BUFD*/
      let varName = arraycref2(name,dims)
      let varType = variableType(type_)
      match dims
        case "0" then
          match createDebugCode
            case true then
              '<%varType%><%if createRefVar then '&' else ''%> <%varName%>;'
            else
              if createRefVar then
                let index = '<%listHead(SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,true,indexForUndefinedReferences))%>'
                '#define <%varName%> _pointerTo<%type%>Vars[<%index%>]'
              else
                '<%varType%> <%varName%>;'
        else ''
      end match
end memberVariableDefine2;


template initAlgloopParam(SimVar simVar, String arrayName,Text& arrayInit, Boolean useFlatArrayNotation)
::=
match simVar
      case SIMVAR(numArrayElement={}) then
      <<
      <%cref(name,useFlatArrayNotation)%>(_<%cref(name,useFlatArrayNotation)%>)
      >>
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(_),numArrayElement=num) then
      //let &arrayInit+= ',<%arraycref(name, useFlatArrayNotation)%>=_<%arraycref(name, useFlatArrayNotation)%>'
      '<%arraycref(name, useFlatArrayNotation)%>(_<%arraycref(name, useFlatArrayNotation)%>)'
    case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(_),numArrayElement=num) then
      //let &arrayInit+= ' ,<%arraycref(name, useFlatArrayNotation)%>= _<%arraycref(name, useFlatArrayNotation)%>'
      '<%arraycref(name, useFlatArrayNotation)%>( _<%arraycref(name, useFlatArrayNotation)%>)'
    /*special case for varibales that marked as array but are not arrays */
      case SIMVAR(numArrayElement=_::_) then
      let& dims = buffer "" /*BUFD*/
      let varName = arraycref2(name,dims)
      match dims case "0" then  '<%varName%>(_<%varName%>)'
end initAlgloopParam;


template memberVariableDefineReference2(SimVar simVar, String arrayName,String pre, Boolean useFlatArrayNotation)
::=
match simVar
      case SIMVAR(numArrayElement={}) then
      <<
      <%variableType(type_)%>& <%pre%><%cref(name, useFlatArrayNotation)%>
      >>
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(_),numArrayElement=num) then
      <<
      multi_array<<%variableType(type_)%>,<%listLength(num)%>>& <%pre%><%arraycref(name, useFlatArrayNotation)%>
      >>
    case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(_),numArrayElement=num) then
      <<
      multi_array<<%variableType(type_)%>,<%listLength(num)%>>& <%pre%><%arraycref(name, useFlatArrayNotation)%>
      >>
    /*special case for varibales that marked as array but are not arrays */
    case SIMVAR(numArrayElement=_::_) then
      let& dims = buffer "" /*BUFD*/
      let varName = arraycref2(name,dims)
      let varType = variableType(type_)
      match dims case "0" then  ''
end memberVariableDefineReference2;


template arrayConstruct(ModelInfo modelInfo, Boolean useFlatArrayNotation)
::=
match modelInfo
case MODELINFO(vars = vars as SIMVARS(__))
  then
  <<
  <%arrayConstruct1(vars.algVars, useFlatArrayNotation)%>
  <%arrayConstruct1(vars.discreteAlgVars, useFlatArrayNotation)%>
  <%arrayConstruct1(vars.intAlgVars, useFlatArrayNotation)%>
  <%arrayConstruct1(vars.boolAlgVars, useFlatArrayNotation)%>
  <%arrayConstruct1(vars.stringAlgVars, useFlatArrayNotation)%>
  <%arrayConstruct1(vars.paramVars, useFlatArrayNotation)%>
  <%arrayConstruct1(vars.intParamVars, useFlatArrayNotation)%>
  <%arrayConstruct1(vars.boolParamVars, useFlatArrayNotation)%>
  <%arrayConstruct1(vars.stringParamVars, useFlatArrayNotation)%>
  <%arrayConstruct1(vars.aliasVars, useFlatArrayNotation)%>
  <%arrayConstruct1(vars.intAliasVars, useFlatArrayNotation)%>
  <%arrayConstruct1(vars.boolAliasVars, useFlatArrayNotation)%>
  <%arrayConstruct1(vars.stringAliasVars, useFlatArrayNotation)%>
  >>
end arrayConstruct;

template arrayConstruct1(list<SimVar> varsLst, Boolean useFlatArrayNotation) ::=
  varsLst |> v as SIMVAR(arrayCref=SOME(_),numArrayElement=_::_) =>
  <<>>
  //,<%arraycref(name, useFlatArrayNotation)%>(boost::extents<%boostextentDims(name,v.numArrayElement)%>)
  ;separator="\n"
end arrayConstruct1;
//,<%arraycref(name)%>(boost::extents[<%v.numArrayElement;separator="]["%>])
template variableType(DAE.Type type)
 "Generates integer for use in arrays in global data section."
::=
  match type
  case T_REAL(__)        then "double"
  case T_STRING(__)      then "string"
  case T_INTEGER(__)         then "int"
  case T_BOOL(__)        then "bool"
  case T_ENUMERATION(__) then "int"
  case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__)) then "void*"
end variableType;

template lastIdentOfPath(Path modelName) ::=
  match modelName
  case QUALIFIED(__) then lastIdentOfPath(path)
  case IDENT(__)     then name
  case FULLYQUALIFIED(__) then lastIdentOfPath(path)
end lastIdentOfPath;

template identOfPath(Path modelName) ::=
  match modelName
  case QUALIFIED(__) then '<%name%>_<%lastIdentOfPath(path)%>'
  case IDENT(__)     then name
  case FULLYQUALIFIED(__) then lastIdentOfPath(path)
end identOfPath;

template identOfPathDot(Path modelName) ::=
  match modelName
  case QUALIFIED(__) then '<%name%>.<%lastIdentOfPath(path)%>'
  case IDENT(__)     then name
  case FULLYQUALIFIED(__) then lastIdentOfPath(path)
end identOfPathDot;

template lastIdentOfPathFromSimCode(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace) ::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
    lastIdentOfPath(modelInfo.name)
end lastIdentOfPathFromSimCode;











/*
template boostextentDims(ComponentRef cr, list<String> StatArrayDims)
::=
   match cr

case CREF_IDENT(subscriptLst={}) then
    '<%ident%>_NO_SUBS'
  case CREF_IDENT(__) then
   '[<%StatArrayDims;separator="]["%>]'
   //subscriptsToCStr(subscriptLst)
  case CREF_QUAL(componentRef=c) then
    match StatArrayDims
      case val::dims
        then boostextentDims(c,dims)
    end match
  else "CREF_NOT_IDENT_OR_QUAL"
end boostextentDims;
*/

template boostextentDims(ComponentRef cr, list<String> StatArrayDims)
::=
    match cr
case CREF_IDENT(subscriptLst={}) then
  '<%ident%>_NO_SUBS'
 //subscriptsToCStr(subscriptLst)
  case CREF_IDENT(subscriptLst=dims) then
  //    '_<%ident%>_INVALID_<%listLength(dims)%>_<%listLength(StatArrayDims)%>'
    '[<%List.lastN(StatArrayDims,listLength(dims));separator="]["%>]'
    //subscriptsToCStr(subscriptLst)
  case CREF_QUAL(componentRef=c) then
    boostextentDims(c,StatArrayDims)
  else "CREF_NOT_IDENT_OR_QUAL"
end boostextentDims;


template arrayextentDims(ComponentRef cr, list<String> array)
::=
    match cr
case CREF_IDENT(subscriptLst={}) then
  '<%ident%>_NO_SUBS'+ "/*hier1*/"
 //subscriptsToCStr(subscriptLst)
  case CREF_IDENT(subscriptLst=dims) then
  //    '_<%ident%>_INVALID_<%listLength(dims)%>_<%listLength(array)%>'
    '<%List.lastN(array,listLength(dims));separator=","%>'
    //subscriptsToCStr(subscriptLst)
  case CREF_QUAL(componentRef=c) then
    arrayextentDims(c,array)
  else "CREF_NOT_IDENT_OR_QUAL"
end arrayextentDims;


template arrayNumElements(ComponentRef cr, list<String> array)
::=
    match cr
case CREF_IDENT(subscriptLst={}) then
  '<%ident%>_NO_SUBS'+ "/*hier1*/"
 //subscriptsToCStr(subscriptLst)
  case CREF_IDENT(subscriptLst=dims) then
  //    '_<%ident%>_INVALID_<%listLength(dims)%>_<%listLength(array)%>'
    '<%List.lastN(array,listLength(dims));separator=","%>'
    //subscriptsToCStr(subscriptLst)
  case CREF_QUAL(componentRef=c) then
    arrayNumElements(c,array)
  else "CREF_NOT_IDENT_OR_QUAL"
end arrayNumElements;



/* record CREF_IDENT
    Ident ident;
    Type identType "type of the identifier, without considering the subscripts";
    list<Subscript> subscriptLst;
  end CREF_IDENT;

  record CREF_ITER "An iterator index; used in local scopes in for-loops and reductions"
    Ident ident;
    Integer index;
    Type identType "type of the identifier, without considering the subscripts";
    list<Subscript> subscriptLst;
  end CREF_ITER;*/



template simulationInitFile(SimCode simCode, Text& extraFuncsDecl, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__), vars = vars as SIMVARS(__), name=name))
  then
    let className = lastIdentOfPath(name)
    let &additionalConstVarFunctionCalls = buffer ""
    let &extraFuncsDecl += "void defineConstVals();"
    <<

    //String parameter <%listLength(vars.stringParamVars)%>
    <%List.partition(vars.stringParamVars, 100) |> varPartition hasindex i0 =>
          initConstValsWithSplit(varPartition, simCode, i0, className, additionalConstVarFunctionCalls, extraFuncsDecl, stateDerVectorName, useFlatArrayNotation) ;separator="\n"%>

    void <%className%>::defineConstVals()
    {
      <%additionalConstVarFunctionCalls%>
    }
    >>
end simulationInitFile;

template initConstValsWithSplit(list<SimVar> simVars, SimCode simCode, Text idx, Text className, Text& additionalFunctionCalls, Text& additionalFunctionDefinitions, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let &additionalFunctionCalls += '  defineConstVals_<%idx%>();<%\n%>'
  let &additionalFunctionDefinitions += 'void defineConstVals_<%idx%>();<%\n%>'
  <<
  void <%className%>::defineConstVals_<%idx%>()
  {
    <%simVars |> var =>
        initConstValue(var, simCode, stateDerVectorName, useFlatArrayNotation)
        ;separator="\n"%>
  }
  >>
end initConstValsWithSplit;

template initConstValue(SimVar var, SimCode simCode, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match var
    case SIMVAR(numArrayElement=_::_) then ''
    case SIMVAR(type_=type,name=name) then
      match initialValue
        case SOME(v) then '<%cref(name, useFlatArrayNotation)%> = <%initConstValue2(v, simCode, stateDerVectorName, useFlatArrayNotation)%>;'
        else
          match type
            case T_STRING(__) then '<%cref(name, useFlatArrayNotation)%> = "";'
            else '<%cref(name, useFlatArrayNotation)%> = 0;'
end initConstValue;

template initConstValue2(Exp initialValue, SimCode simCode, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match initialValue
    case v then
      let &preExp = buffer "" //dummy ... the value is always a constant
      let &varDecls = buffer ""
      let &extraFuncs = buffer ""
      let &extraFuncsDecl = buffer ""
      let &extraFuncsNamespace = buffer ""
      match daeExp(v, contextOther, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      case vStr as "0"
      case vStr as "0.0"
      case vStr as "(0)"
      case vStr as ""
      case vStr then
       '<%vStr%>'
  end match
end initConstValue2;

template initializeArrayElements(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__), vars = vars as SIMVARS(__)))
  then
  <<
  <%initValsArray(vars.constVars,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,useFlatArrayNotation)%>
  <%initValsArray(vars.intConstVars,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,useFlatArrayNotation)%>
  <%initValsArray(vars.boolConstVars,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,useFlatArrayNotation)%>
  <%initValsArray(vars.stringConstVars,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,useFlatArrayNotation)%>
  >>
end initializeArrayElements;

template initValsArray(list<SimVar> varsLst,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Boolean useFlatArrayNotation) ::=
  varsLst |> SIMVAR(numArrayElement=_::_,initialValue=SOME(v)) =>
  <<
  <%cref(name,useFlatArrayNotation)%> = <%initVal(v)%>;
  >>
  ;separator="\n"
end initValsArray;

template arrayInit(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Boolean useFlatArrayNotation)
 "Generates the contents of the makefile for the simulation case."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__), vars = vars as SIMVARS(__)))
  then
  <<
  <%initVals1(vars.paramVars,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, useFlatArrayNotation)%>
  <%initVals1(vars.intParamVars,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, useFlatArrayNotation)%>
  <%initVals1(vars.boolParamVars,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, useFlatArrayNotation)%>
  <%initVals1(vars.stringParamVars,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, useFlatArrayNotation)%>
  >>
end arrayInit;

template initVals1(list<SimVar> varsLst, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Boolean useFlatArrayNotation) ::=
  varsLst |> (var as SIMVAR(__)) =>
  initVals2(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,useFlatArrayNotation)
  ;separator="\n"
end initVals1;

template initVals2(SimVar var, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Boolean useFlatArrayNotation) ::=
  match var
  case SIMVAR(numArrayElement = {}) then ''
  case SIMVAR(__) then '<%cref(name, useFlatArrayNotation)%>=<%match initialValue
    case SOME(v) then initVal(v)
      else "0"
    %>;'
end initVals2;

/*
template arrayReindex(ModelInfo modelInfo, Boolean useFlatArrayNotation)
::=
match modelInfo
case MODELINFO(vars = vars as SIMVARS(__))
  then
  <<
  <%arrayReindex1(vars.algVars,useFlatArrayNotation)%>
  <%arrayReindex1(vars.discreteAlgVars,useFlatArrayNotation)%>
  <%arrayReindex1(vars.intAlgVars,useFlatArrayNotation)%>
  <%arrayReindex1(vars.boolAlgVars,useFlatArrayNotation)%>
  <%arrayReindex1(vars.stringAlgVars,useFlatArrayNotation)%>
  <%arrayReindex1(vars.paramVars,useFlatArrayNotation)%>
  <%arrayReindex1(vars.intParamVars,useFlatArrayNotation)%>
  <%arrayReindex1(vars.boolParamVars,useFlatArrayNotation)%>
  <%arrayReindex1(vars.stringParamVars,useFlatArrayNotation)%>
  <%arrayReindex1(vars.aliasVars,useFlatArrayNotation)%>
  <%arrayReindex1(vars.intAliasVars,useFlatArrayNotation)%>
  <%arrayReindex1(vars.boolAliasVars,useFlatArrayNotation)%>
  <%arrayReindex1(vars.stringAliasVars,useFlatArrayNotation)%>
  <%arrayReindex1(vars.constVars,useFlatArrayNotation)%>
  <%arrayReindex1(vars.intConstVars,useFlatArrayNotation)%>
  <%arrayReindex1(vars.boolConstVars,useFlatArrayNotation)%>
  <%arrayReindex1(vars.stringConstVars,useFlatArrayNotation)%>
  >>
end arrayReindex;
*/
/*
template arrayReindex1(list<SimVar> varsLst, Boolean useFlatArrayNotation)
::=
  if(boolNot(useFlatArrayNotation)) then (varsLst |> SIMVAR(arrayCref=SOME(_),numArrayElement=_::_) => '<%arraycref(name, useFlatArrayNotation)%>.reindex(1);';separator="\n")
end arrayReindex1;
*/

template initVal(Exp initialValue)
::=
  match initialValue
  case ICONST(__) then integer
  case RCONST(__) then real
  case SCONST(__) then '"<%Util.escapeModelicaStringToCString(string)%>"'
  case BCONST(__) then if bool then "true" else "false"
  case ENUM_LITERAL(__) then '<%index%>/*ENUM:<%dotPath(name)%>*/'
  else "*ERROR* initial value of unknown type"
end initVal;

template dotPath(Path path)
 "Generates paths with components separated by dots."
::=
  match path
  case QUALIFIED(__)      then '<%name%>.<%dotPath(path)%>'

  case IDENT(__)          then name
  case FULLYQUALIFIED(__) then dotPath(path)
end dotPath;

template writeoutput1(ModelInfo modelInfo)
::=
match modelInfo
case modelInfo as MODELINFO(vars=SIMVARS(__)) then
  <<



        void  <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeStateVarsResultNames(vector<string>& names)
        {
        <% if vars.stateVars then
          'names += <%(vars.stateVars |> SIMVAR(__) =>
           '"<%crefStrForWriteOutput(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }

        void   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeDerivativeVarsResultNames(vector<string>& names)
        {
         <% if  vars.derivativeVars then
          'names += <%(vars.derivativeVars |> SIMVAR(__) =>
          '"<%crefStrForWriteOutput(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }




        void  <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeStateVarsResultDescription(vector<string>& description)
        {
        <% if vars.stateVars then
          'description += <%(vars.stateVars |> SIMVAR(__) =>
           '"<%Util.escapeModelicaStringToCString(comment)%>"' ;separator=",";align=10;alignSeparator=";\n description += " )%>;' %>
        }

        void   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeDerivativeVarsResultDescription(vector<string>& description)
        {
         <% if vars.derivativeVars then
          'description += <%(vars.derivativeVars |> SIMVAR(__) =>
          '"<%Util.escapeModelicaStringToCString(comment)%>"' ;separator=",";align=10;alignSeparator=";\n description += " )%>;' %>
        }


  >>
end writeoutput1;

template numResidues(list<SimEqSystem> allEquations)
::=
(allEquations |> eqn => numResidues2(eqn);separator="+")
end numResidues;

template numResidues2(SimEqSystem eqn)
::=
match eqn
case SES_RESIDUAL(__) then
<<
>>
case  SES_SIMPLE_ASSIGN(__) then
<<
1
>>
case SES_ARRAY_CALL_ASSIGN(__) then
<<
>>
case SES_ALGORITHM(__) then
<<
>>
case lin as SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
<<
<%(ls.vars |> var => '1');separator="+"%>
>>
case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
<<
<%(nls.eqs |> eq => '1');separator="+"%>
>>
case SES_MIXED(__) then numResidues2(cont)
case SES_WHEN(__) then
<<
>>
else
<<
>>
end numResidues2;

template numStatevars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numStateVars%>
>>
end numStatevars;

template numAlgvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numAlgVars%>+<%varInfo.numDiscreteReal%>+<%varInfo.numIntAlgVars%>+<%varInfo.numBoolAlgVars%>
>>
end numAlgvars;

template numRealvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%intAdd(intMul(2,varInfo.numStateVars),intAdd(varInfo.numAlgVars,intAdd(varInfo.numParams,varInfo.numDiscreteReal)))
%>
>>
end numRealvars;

//return the start index of the state var vector in the simvars memory
template numStateVarIndex(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
0
>>
end numStateVarIndex;


template numIntvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%intAdd(varInfo.numIntAlgVars,varInfo.numIntParams)%>
>>
end numIntvars;

template numBoolvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%intAdd(varInfo.numBoolAlgVars,varInfo.numBoolParams)%>
>>
end numBoolvars;

template numStringvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%intAdd(varInfo.numStringAlgVars,varInfo.numStringParamVars)%>
>>
end numStringvars;

template numProtectedAlgvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
<<
<%listLength(protectedVars(vars.algVars))%>+<%listLength(protectedVars(vars.discreteAlgVars))%>+<%listLength(protectedVars(vars.intAlgVars))%>+<%listLength(protectedVars(vars.boolAlgVars))%>
>>
end numProtectedAlgvars;

template numParamVars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
 let n_vars = intAdd(varInfo.numParams,intAdd(varInfo.numIntParams,varInfo.numBoolParams))
<<
<%n_vars%>
>>
end numParamVars;

template numProtectedParamVars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
 let n_vars = intAdd(listLength(protectedVars(vars.paramVars)),intAdd(listLength(protectedVars(vars.intParamVars)),listLength(protectedVars(vars.boolParamVars))))
<<
<%n_vars%>
>>
end numProtectedParamVars;


template numProtectedRealParamVars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
 let n_vars = listLength(protectedVars(vars.paramVars))
<<
<%n_vars%>
>>
end numProtectedRealParamVars;

template numProtectedIntParamVars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
 let n_vars = listLength(protectedVars(vars.intParamVars))
<<
<%n_vars%>
>>
end numProtectedIntParamVars;




template numInOutvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numInVars%>+<%varInfo.numOutVars%>
>>
end numInOutvars;

template numAliasvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numAlgAliasVars%>+<%varInfo.numIntAliasVars%>+<%varInfo.numBoolAliasVars%>
>>
end numAliasvars;

template numProtectedAliasvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
<<
<%listLength(protectedVars(vars.aliasVars))%>+<%listLength(protectedVars(vars.intAliasVars))%>+<%listLength(protectedVars(vars.boolAliasVars))%>
>>
end numProtectedAliasvars;


template numAlgvar(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numAlgVars%>
>>
end numAlgvar;


template numProtectedRealAlgvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
<<
<%listLength(protectedVars(vars.algVars))%>
>>
end numProtectedRealAlgvars;

template numDiscreteAlgVar(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numDiscreteReal%>
>>
end numDiscreteAlgVar;

template numProtectedDiscreteAlgVars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
<<
<%listLength(protectedVars(vars.discreteAlgVars))%>
>>
end numProtectedDiscreteAlgVars;

template numIntAlgvar(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numIntAlgVars%>
>>
end numIntAlgvar;

template numProtectedIntAlgvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
<<
<%listLength(protectedVars(vars.intAlgVars))%>
>>
end numProtectedIntAlgvars;

template numBoolAlgvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numBoolAlgVars%>
>>
end numBoolAlgvars;


template numProtectedBoolAlgvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
<<
<%listLength(protectedVars(vars.boolAlgVars))%>
>>
end numProtectedBoolAlgvars;

template numInputvar(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numInVars%>
>>
end numInputvar;

template numOutputvar(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numOutVars%>
>>
end numOutputvar;

template numAliasvar(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numAlgAliasVars%>
>>
end numAliasvar;

template numProtectedRealAliasvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
<<
<%listLength(protectedVars(vars.aliasVars))%>
>>
end numProtectedRealAliasvars;


template numIntAliasvar(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numIntAliasVars%>
>>
end numIntAliasvar;

template numProtectedIntAliasvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
<<
<%listLength(protectedVars(vars.intAliasVars))%>
>>
end numProtectedIntAliasvars;

template numBoolAliasvar(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numBoolAliasVars%>
>>
end numBoolAliasvar;


template numProtectedBoolAliasvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
<<
<%listLength(protectedVars(vars.boolAliasVars))%>
>>
end numProtectedBoolAliasvars;

template numDerivativevars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numStateVars%>
>>
end numDerivativevars;

template getAliasSign(SimVar simVar)
  "Get sign of alias variable, considering its data type"
::=
match simVar
case SIMVAR(type_=type_) then
  match aliasvar
  case NEGATEDALIAS(__) then
    match type_ case T_BOOL(__) then '!' else '-'
  else ''
end getAliasSign;

template getAliasCRef(AliasVariable aliasvar, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Returns the alias Attribute of ScalarVariable."
::=
  let &varDeclsCref = buffer "" /*BUFD*/
  match aliasvar
    case ALIAS(__)
    case NEGATEDALIAS(__) then '<%cref1(varName, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>'
    else 'noAlias'
end getAliasCRef;

//template for write variables for each time step
template generateWriteOutputFunctionsForVars(ModelInfo modelInfo,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, String className, Boolean useFlatArrayNotation)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
 let &varDeclsCref = buffer "" /*BUFD*/
 let algVarsStart = "1"
 let discrAlgVarsStart = intAdd(stringInt(algVarsStart), stringInt(numProtectedRealAlgvars(modelInfo)))
 let intAlgVarsStart = intAdd(stringInt(discrAlgVarsStart), stringInt(numProtectedDiscreteAlgVars(modelInfo)))
 let boolAlgVarsStart = intAdd(stringInt(intAlgVarsStart), stringInt(numProtectedIntAlgvars(modelInfo)))
 let aliasVarsStart = intAdd(stringInt(boolAlgVarsStart), stringInt(numProtectedBoolAlgvars(modelInfo)))
 let intAliasVarsStart = intAdd(stringInt(aliasVarsStart), stringInt(numProtectedRealAliasvars(modelInfo)))
 let boolAliasVarsStart = intAdd(stringInt(intAliasVarsStart), stringInt(numProtectedIntAliasvars(modelInfo)))
 let stateVarsStart = intAdd(stringInt(boolAliasVarsStart), stringInt(numProtectedBoolAliasvars(modelInfo)))
 <<

 void <%className%>::writeStateValues(HistoryImplType::value_type_v *v, HistoryImplType::value_type_dv *v2)
 {
   <%(vars.stateVars      |> SIMVAR() hasindex i8 =>'(*v)(<%intAdd(stringInt(stateVarsStart), stringInt(i8))%>)=__z[<%index%>];';separator="\n")%>
   <%(vars.derivativeVars |> SIMVAR() hasindex i9 fromindex 1 =>'(*v2)(<%i9%>)=__zDot[<%index%>]; ';separator="\n")%>
 }
 >>
end generateWriteOutputFunctionsForVars;

/*
 const int algVarsStart = <%algVarsStart%>;
 const int discrAlgVarsStart  = <%discrAlgVarsStart%>;
 const int intAlgVarsStart    = <%intAlgVarsStart%>;
 const int boolAlgVarsStart   = <%boolAlgVarsStart%>;
 const int aliasVarsStart     = <%aliasVarsStart%>;
 const int intAliasVarsStart  = <%intAliasVarsStart%>;
 const int boolAliasVarsStart = <%boolAliasVarsStart%>;
 const int stateVarsStart     = <%stateVarsStart%>;
 */

//template to generate a function that writes all given variables
template writeOutputVars(String functionName, list<SimVar> vars, Integer startIndex, String className, Boolean areAliasVars, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  <<
  void <%className%>::<%functionName%>(HistoryImplType::value_type_v *v)
  {
    <%if(areAliasVars) then
    <<
    <%vars |> simVar as SIMVAR(isProtected=false) hasindex i1 =>'(*v)(<%intAdd(startIndex, stringInt(i1))%>) = <%getAliasSign(simVar)%><%getAliasCRef(aliasvar, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)%>;';separator="\n"%>
    >>
    else
    <<
    <%vars |> SIMVAR(isProtected=false) hasindex i0 =>'(*v)(<%intAdd(startIndex,stringInt(i0))%>)=<%cref(name, useFlatArrayNotation)%>;';separator="\n"%>
    >>%>
  }
  >>
end writeOutputVars;

template writeOutputVarsWithSplit(String functionName, list<SimVar> vars, Integer startIndex, String className, Boolean areAliasVars, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
 let &funcCalls = buffer "" /*BUFD*/
  let funcs = List.partition(vars, 100) |> ls hasindex idx =>
    let &varDecls = buffer "" /*BUFD*/
    let &funcCalls += '<%className%>::<%functionName%>_<%idx%>(v);'
    let init = writeValueValst(ls, startIndex, idx, 100, areAliasVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    <<
    void <%className%>::<%functionName%>_<%idx%>(HistoryImplType::value_type_v *v)
    {
       <%varDecls%>
       <%init%>
    }
    >>
    ;separator="\n"

  <<
  <%funcs%>

  void <%className%>::<%functionName%>(HistoryImplType::value_type_v *v)
  {
    //number of vars: <%listLength(vars)%>
    <%funcCalls%>
  }
  >>
end writeOutputVarsWithSplit;

template writeValueValst(list<SimVar> vars, Integer startIndex, Integer idx, Integer multiplicator, Boolean areAliasVars, SimCode simCode, Text& extraFuncs,
                         Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  if(areAliasVars) then
    <<
    <%vars |> simVar as SIMVAR(isProtected=false) hasindex i1 =>'(*v)(<%intAdd(intMul(idx,multiplicator),intAdd(startIndex, stringInt(i1)))%>) = <%getAliasSign(simVar)%><%getAliasCRef(aliasvar, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)%>;';separator="\n"%>
    >>
    else
    <<
    <%vars |> SIMVAR(isProtected=false) hasindex i0 =>'(*v)(<%intAdd(intMul(idx,multiplicator),intAdd(startIndex, stringInt(i0)))%>)=<%cref(name, useFlatArrayNotation)%>;';separator="\n"%>
    >>
end writeValueValst;

//template for write parameter values
template writeoutputparams(ModelInfo modelInfo,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context,  Boolean useFlatArrayNotation)

::=
match modelInfo
case MODELINFO(vars=SIMVARS(__),varInfo=VARINFO(__)) then
 let &varDeclsCref = buffer "" /*BUFD*/

    /*<<
    const int paramVarsStart = 1;
    const int intParamVarsStart  = paramVarsStart       + <%numProtectedRealParamVars(modelInfo)%>;
    const int boolparamVarsStart    = intParamVarsStart  + <%numProtectedIntParamVars(modelInfo)%>;

    <%vars.paramVars         |> SIMVAR(isProtected=false) hasindex i0 =>'params(paramVarsStart+<%i0%>)=<%cref(name, useFlatArrayNotation)%>;';align=8 %>
    <%vars.intParamVars |> SIMVAR(isProtected=false) hasindex i0 =>'params(intParamVarsStart+<%i0%>)=<%cref(name, useFlatArrayNotation)%>;';align=8 %>
    <%vars.boolParamVars      |> SIMVAR(isProtected=false) hasindex i1 =>'params(boolparamVarsStart+<%i1%>)=<%cref(name, useFlatArrayNotation)%>;';align=8%>
    >>*/
    let paramVarsStart = 1
    let intParamVarsStart = intAdd(1,stringInt(numProtectedRealParamVars(modelInfo)))
    let  boolparamVarsStart = intAdd(stringInt(intParamVarsStart),stringInt(numProtectedIntParamVars(modelInfo)))
    <<
    void <%lastIdentOfPath(name)%>WriteOutput::writeParams(HistoryImplType::value_type_p& params)
    {
     /*const int paramVarsStart = 1;
     const int intParamVarsStart  = paramVarsStart       + <%numProtectedRealParamVars(modelInfo)%>;
     const int boolparamVarsStart    = intParamVarsStart  + <%numProtectedIntParamVars(modelInfo)%>;
     */
     writeParamsReal(params);
     writeParamsInt(params);
     writeParamsBool(params);
    }
    <%writeoutputparamsWithSplit('<%lastIdentOfPath(name)%>WriteOutput::writeParams',stringInt(paramVarsStart),"Real",vars.paramVars,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,useFlatArrayNotation)%>
    <%writeoutputparamsWithSplit('<%lastIdentOfPath(name)%>WriteOutput::writeParams',stringInt(intParamVarsStart),"Int",vars.intParamVars,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,useFlatArrayNotation)%>
    <%writeoutputparamsWithSplit('<%lastIdentOfPath(name)%>WriteOutput::writeParams',stringInt(boolparamVarsStart),"Bool",vars.boolParamVars,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,useFlatArrayNotation)%>
    >>
end writeoutputparams;


template writeoutputparamsWithSplit(Text funcNamePrefix, Integer startindex,Text type, list<SimVar> varsLst, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Boolean useFlatArrayNotation) ::=
  let &funcCalls = buffer "" /*BUFD*/
  let funcs = List.partition(protectedVars(varsLst), 100) |> ls hasindex idx =>
    let &varDecls = buffer "" /*BUFD*/
    let &funcCalls += '<%funcNamePrefix%><%type%>_<%idx%>(params);'
    let init = writeParamValst(ls,startindex,idx,100,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, useFlatArrayNotation)
    <<
    void <%funcNamePrefix%><%type%>_<%idx%>( HistoryImplType::value_type_p& params  )
    {
       <%varDecls%>
       <%init%>
    }
    >>
    ;separator="\n"

  <<
  <%funcs%>

  void <%funcNamePrefix%><%type%>(HistoryImplType::value_type_p& params  )
  {
    //number of vars: <%listLength(varsLst)%>
    <%funcCalls%>
  }
  >>
end writeoutputparamsWithSplit;


template writeParamValst(list<SimVar> varsLst,Integer startindex,Integer idx, Integer multiplicator, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Boolean useFlatArrayNotation)
::=
  varsLst      |> SIMVAR(isProtected=false) hasindex i0 fromindex intAdd(startindex,intMul(idx,multiplicator)) =>'params(<%i0%>)=<%cref(name, useFlatArrayNotation)%>;';align=8
end writeParamValst;


template saveAll(ModelInfo modelInfo, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Text stateDerVectorName,Boolean useFlatArrayNotation)

::=
match simCode
case SIMCODE(modelInfo = MODELINFO(vars = vars as SIMVARS(__)))
  then
    let className = lastIdentOfPath(modelInfo.name)
    <<
    void <%className%>::saveAll()
    {
         getSimVars()->savePreVariables();
    }
    >>

end saveAll;

template saveDiscreteVars(ModelInfo modelInfo, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(vars = vars as SIMVARS(__)))
  then
  let n_vars = intAdd(intAdd(listLength(vars.algVars), listLength(vars.discreteAlgVars)), intAdd( listLength(vars.intAlgVars) , listLength(vars.boolAlgVars )))
  let className = lastIdentOfPath(modelInfo.name)
  match n_vars
  case "0" then
    <<
    void <%className%>::saveDiscreteVars()
    {
    }
    >>
  else
    let &funcCalls = buffer "" /*BUFD*/
    let saveDiscreteVarFuncs = (List.partition(listAppend(vars.algVars, listAppend(vars.discreteAlgVars, listAppend(vars.intAlgVars, vars.boolAlgVars))), 100) |> part hasindex i0 =>
      saveDiscreteVars1(part, i0, 100, &funcCalls ,useFlatArrayNotation, className);separator="\n")
    <<
    <%saveDiscreteVarFuncs%>

    void <%className%>::saveDiscreteVars()
    {
       double discreteVars[<%n_vars%>];

       <%funcCalls%>

      _event_handling->saveDiscretPreVars(discreteVars,<%n_vars%>);
    }

    >>
end saveDiscreteVars;

template saveDiscreteVars1(list<SimCodeVar.SimVar> partVars, Integer partIdx, Integer multiplicator, Text &funcCalls, Boolean useFlatArrayNotation, Text className)
::=
  <<
  void <%className%>::saveDiscreteVars_<%partIdx%>(double* discreteVars)
  {

  }
  >>
  /*
  let &funcCalls += 'saveDiscreteVars_<%partIdx%>(discreteVars);'
  Deactivated:
  <<
  void <%className%>::saveDiscreteVars_<%partIdx%>(double* discreteVars)
  {
     <%(partVars |> SIMVAR(__) hasindex i0 fromindex (intMul(partIdx, multiplicator)) =>
        'discreteVars[<%i0%>] = <%cref(name,useFlatArrayNotation)%>;';separator="\n")%>
  }
  >>
  */
end saveDiscreteVars1;

template initAlgloopvars(Text &preExp, Text &varDecls, ModelInfo modelInfo, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match modelInfo
  case MODELINFO(vars=SIMVARS(__)) then
    let &varDecls = buffer "" /*BUFD*/
    let &text = buffer "" /*BUFD*/
    let algvars = initValst(varDecls, "Real", vars.algVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)
    let discretealgvars = initValst(varDecls, "Real", vars.discreteAlgVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)
    let intvars = initValst(varDecls, "Int", vars.intAlgVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)
    let boolvars = initValst(varDecls, "Bool", vars.boolAlgVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)
    <<
    <%varDecls%>
    <%algvars%>
    <%discretealgvars%>
    <%intvars%>
    <%boolvars%>
    >>
end initAlgloopvars;

template boundParameters(list<SimEqSystem> parameterEquations, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace,
                         Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates function in simulation file."
::=
  let &tmp = buffer ""
  let body = (parameterEquations |> eq as SES_SIMPLE_ASSIGN(__) =>
      equation_(eq, contextSimulationDiscrete, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    ;separator="\n")
  let divbody = (parameterEquations |> eq as SES_ALGORITHM(__) =>
      equation_(eq, contextSimulationDiscrete, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    ;separator="\n")
    <<
    <%body%>
    <%divbody%>
    >>
end boundParameters;


template outputIndices(ModelInfo modelInfo)
::= match modelInfo
case MODELINFO(varInfo=VARINFO(__),vars=SIMVARS(__)) then
    if varInfo.numOutVars then
    <<
    var_ouputs_idx = MAP_LIST_OF <%
    {(vars.outputVars |> SIMVAR(__) =>  '<%index%>,"<%crefStr(name)%>"';separator=",") };separator=" MAP_LIST_SEP "%> MAP_LIST_END;
    >>
end outputIndices;


template isOutput(Causality c, Boolean useFlatArrayNotation)
 "Returns the Causality Attribute of a Variable."
::=
match c
  case OUTPUT(__) then "output"
end isOutput;


template initValstWithSplit(Text &varDecls, Text type, Text funcNamePrefix, list<SimVar> varsLst, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                            Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let &funcCalls = buffer "" /*BUFD*/
  let funcs = List.partition(varsLst, 100) |> ls hasindex idx =>
    let &varDecls = buffer "" /*BUFD*/
    let &funcCalls += '<%funcNamePrefix%>_<%idx%>();'
    let init = initValst(varDecls, type, ls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)
    <<
    void <%funcNamePrefix%>_<%idx%>()
    {
       <%varDecls%>
       <%init%>
    }
    >>
    ;separator="\n"

  <<
  <%funcs%>

  void <%funcNamePrefix%>()
  {
    <%funcCalls%>
  }
  >>
end initValstWithSplit;


template initValst(Text &varDecls, Text type, list<SimVar> varsLst, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  if(Flags.isSet(Flags.HARDCODED_START_VALUES)) then
   (varsLst |> sv as SIMVAR(__) =>
     let &preExp = buffer "" /*BUFD*/
     let &varDeclsCref = buffer "" /*BUFD*/
     let &startValue = buffer ""
     let crefStr = cref1(sv.name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDeclsCref, stateDerVectorName, useFlatArrayNotation)
     match initialValue
      case SOME(v) then
        match daeExp(v, contextOther, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
          case vStr as "0"
          case vStr as "0.0"
          case vStr as "(0)" then
          '<%preExp%>
           SystemDefaultImplementation::set<%type%>StartValue(<%crefStr%>,<%vStr%>);'
          case vStr as "" then
          '<%preExp%>
           SystemDefaultImplementation::set<%type%>StartValue(<%crefStr%>,<%vStr%>);'
          case vStr then
          '<%preExp%>
           SystemDefaultImplementation::set<%type%>StartValue(<%crefStr%>,<%vStr%>);'
        end match
      else
        '<%preExp%>
         SystemDefaultImplementation::set<%type%>StartValue(<%crefStr%>,<%startValue(sv.type_)%>);'
      ;separator="\n")
  else
    (varsLst |> sv as SIMVAR(__) =>
     let &preExp = buffer "" /*BUFD*/
     let &varDeclsCref = buffer "" /*BUFD*/
     let &startValue = buffer ""
     let crefStr = cref1(sv.name, simCode, &extraFuncs, &extraFuncsDecl,  extraFuncsNamespace,context,varDeclsCref, stateDerVectorName, useFlatArrayNotation)
     let checkStr = match initialValue
      case SOME(v) then
        let &startValue += daeExp(v, contextOther, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        '<%preExp%>
        if(!IsEqual(SystemDefaultImplementation::get<%type%>StartValue(<%crefStr%>), <%startValue%>))
          std::cerr << "Wrong start value for variable <%crefStr%> detected. Got " << SystemDefaultImplementation::get<%type%>StartValue(<%crefStr%>) << " Expected: " << <%startValue%> << std::endl;'
        else
          let &startValue += startValue(sv.type_)
        ''
     checkStr;separator="\n")
end initValst;


template startValue(DAE.Type ty)
::=
  match ty
  case ty as T_INTEGER(__) then '0'
  case ty as T_REAL(__) then '0.0'
  case ty as T_BOOL(__) then 'false'
  case ty as T_STRING(__) then '"empty"'
   case ty as T_ENUMERATION(__) then '0'
  else ""
end startValue;


template eventHandlingInit(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)

::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__))) then
      <<
      <%
      match vi.numZeroCrossings
        case 0 then ""
        else
          <<
          bool events[<%vi.numZeroCrossings%>];
          memset(events,true,<%vi.numZeroCrossings%>);
          for(int i=0;i<=<%vi.numZeroCrossings%>;++i) { handleEvent(events); }
          >>
      %>
      >>
end eventHandlingInit;


template clockIntervalsInit(SimCode simCode, Text& varDecls, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__), modelStructure = fmims) then
  let i = tempDecl('int', &varDecls)
  <<
  <%i%> = 0;
  <%(clockedPartitions |> partition =>
    match partition
    case CLOCKED_PARTITION(__) then
      let &preExp = buffer "" /*BUFD*/
      let spec = daeExp(getClockInterval(baseClock), contextOther, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      // use default clock, except for FMI clocks that may be inferred
      let intvl = match fmims case SOME(FmiModelStructure) then spec else
        match baseClock
        case REAL_CLOCK()
        case INTEGER_CLOCK()
        case BOOLEAN_CLOCK() then
          spec
        else "unspecified"
      let interval = match intvl case "unspecified" then '1.0' else intvl
      let warning = match intvl case "unspecified" then
        'ModelicaMessage("Using default Clock(1.0)!");'
      let subClocks = (subPartitions |> subPartition =>
        match subPartition
        case SUBPARTITION(subClock=SUBCLOCK(factor=RATIONAL(nom=fnom, denom=fres), shift=RATIONAL(nom=snom, denom=sres))) then
          <<
          <%preExp%>
          _clockInterval[<%i%>] = <%interval%> * <%fnom%>.0 / <%fres%>.0;
          _clockShift[<%i%>] = <%snom%>.0 / <%sres%>.0;
          _clockTime[<%i%>] = _simTime + _clockShift[<%i%>] * _clockInterval[<%i%>];
          _clockStart[<%i%>] = true;
          <%i%> ++;
          >>
      ; separator="\n")
      <<
      <%subClocks%>
      <%warning%>
      >>
    ; separator="\n")%>
  >>
end clockIntervalsInit;


template dimension1(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__)),daeModeData=SOME(DAEMODEDATA(algebraicDAEVars=algebraicDAEVars, residualVars=residualVars)), partitionData = PARTITIONDATA(__))
      then
        let numRealVars = numRealvars(modelInfo)
        let numIntVars = numIntvars(modelInfo)
        let numBoolVars = numBoolvars(modelInfo)
        let numStringVars = numStringvars(modelInfo)
        <<
        _dimContinuousStates = <%vi.numStateVars%>;
		_dimAE = <%listLength(algebraicDAEVars)%>;
        _dimRHS =  <%intAdd(vi.numStateVars,listLength(algebraicDAEVars))%>;
        _dimBoolean = <%numBoolVars%>;
        _dimInteger = <%numIntVars%>;
        _dimString = <%numStringVars%>;
        _dimReal = <%numRealVars%>;
        _dimPartitions = <%partitionData.numPartitions%>;
        >>
	 case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__)),daeModeData=NONE(), partitionData = PARTITIONDATA(__))
      then
        let numRealVars = numRealvars(modelInfo)
        let numIntVars = numIntvars(modelInfo)
        let numBoolVars = numBoolvars(modelInfo)
        let numStringVars = numStringvars(modelInfo)
        <<
        _dimContinuousStates = <%vi.numStateVars%>;
		_dimRHS =  <%vi.numStateVars%>;
        _dimBoolean = <%numBoolVars%>;
        _dimInteger = <%numIntVars%>;
        _dimString = <%numStringVars%>;
        _dimReal = <%numRealVars%>;
        _dimPartitions = <%partitionData.numPartitions%>;
        >>
end dimension1;

template isODE(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__)))
then
<<
bool <%lastIdentOfPath(modelInfo.name)%>::isODE()
{
  return <%vi.numStateVars%>>0 ;
}
>>
end isODE;

template testdimension(Dimension d)
::=
  match d
  case DAE.DIM_BOOLEAN(__) then ''
  case DAE.DIM_INTEGER(__) then ''
  case DAE.DIM_ENUM(__) then ''
  case DAE.DIM_EXP(exp=e) then
   match e
  case DAE.CREF(componentRef = cr) then ''
  else '-1'
  end match
  case DAE.DIM_UNKNOWN(__) then '-1'
  else '-1'
end testdimension;

/*
template underscorePath(Path path)
 "Generate paths with components separated by underscores.
  Replaces also the . in identifiers with _.
  The dot might happen for world.gravityAccleration"
::=
  match path
  case QUALIFIED(__) then
    '<%replaceDotAndUnderscore(name)%>_<%underscorePath(path)%>'
  case IDENT(__) then
    replaceDotAndUnderscore(name)
  case FULLYQUALIFIED(__) then
    underscorePath(path)
end underscorePath;
*/

template replaceDotAndUnderscore(String str)
 "Replace _ with __ and dot in identifiers with _"
::=
  match str
  case name then
    let str_dots = System.stringReplace(name,".", "_")
    let str_underscores = System.stringReplace(str_dots, "_", "__")
    '<%str_underscores%>'
end replaceDotAndUnderscore;

template functionInitial(list<SimEqSystem> startValueEquations, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let eqPart = (startValueEquations |> eq as SES_SIMPLE_ASSIGN(__) =>
      equationInitialization_(eq, contextSimulationDiscrete, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    ;separator="\n")
  <<
  <%eqPart%>
  >>
end functionInitial;

template equationInitialization_(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                   Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  equationString(eq, context, varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation, true, true)
end equationInitialization_;

template equation_(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                   Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  equationString(eq, context, varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation, false, false)
end equation_;

template equationString(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                   Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Boolean assignToStartValues, Boolean overwriteOldStartValue)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case e as SES_SIMPLE_ASSIGN(__)
    then equationSimpleAssign(e, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation, assignToStartValues, overwriteOldStartValue)
  case e as SES_ALGORITHM(__)
    then equationAlgorithm(e, context, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
   case e as SES_INVERSE_ALGORITHM(__)
    then equationAlgorithm(e, context, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as SES_WHEN(__)
    then equationWhen(e, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as SES_ARRAY_CALL_ASSIGN(__)
    then equationArrayCallAssign(e, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
    then
      let i = ls.index
      match context
        case  ALGLOOP_CONTEXT(genInitialisation=true)
          then
              <<
              try
              {
                _algLoopSolver<%ls.index%>->initialize();
                _algLoop<%ls.index%>->evaluate();
                for(int i=0; i<_dimZeroFunc; i++)
                {
                  getCondition(i);
                }
                IContinuous::UPDATETYPE calltype = _callType;
                _callType = IContinuous::CONTINUOUS;
                _algLoopSolver<%ls.index%>->solve();
                _callType = calltype;
              }
              catch(ModelicaSimulationError& ex)
              {

                   string error = add_error_info("Nonlinear solver <%ls.index%> stopped",ex.what(),ex.getErrorID(),_simTime);
                    throw ModelicaSimulationError(ALGLOOP_EQ_SYSTEM,error);
              }
              >>
            else
              <<
              bool restart<%ls.index%> = true;

              unsigned int iterations<%ls.index%> = 0;
              _algLoop<%ls.index%>->getReal(_algloop<%ls.index%>Vars);
              bool restatDiscrete<%ls.index%> = false;
              try
                {
                   _algLoop<%ls.index%>->evaluate();
                    if( _callType == IContinuous::DISCRETE )
                    {
                       while(restart<%ls.index%> && !(iterations<%ls.index%>++>500))
                       {
                         getConditions(_conditions0<%ls.index%>);
                         _callType = IContinuous::CONTINUOUS;
                         _algLoopSolver<%ls.index%>->solve();
                         _callType = IContinuous::DISCRETE;
                         for(int i=0;i<_dimZeroFunc;i++)
                         {
                           getCondition(i);
                         }
                         getConditions(_conditions1<%ls.index%>);
                         restart<%ls.index%> = !std::equal (_conditions1<%ls.index%>, _conditions1<%ls.index%>+_dimZeroFunc,_conditions0<%ls.index%>);
                       }
                    }
                    else
                       _algLoopSolver<%ls.index%>->solve();
                }
                catch(ModelicaSimulationError &ex)
                {
                  restatDiscrete<%ls.index%>=true;
                }

                if((restart<%ls.index%>&& iterations<%ls.index%> > 0)|| restatDiscrete<%ls.index%>)
                {
                      try
                       {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
                          IContinuous::UPDATETYPE calltype = _callType;
                         _callType = IContinuous::DISCRETE;
                           _algLoop<%ls.index%>->setReal(_algloop<%ls.index%>Vars );
                          _algLoopSolver<%ls.index%>->solve();
                         _callType = calltype;
                       }
                       catch(ModelicaSimulationError& ex)
                       {
                           string error = add_error_info("Nonlinear solver <%ls.index%> stopped",ex.what(),ex.getErrorID(),_simTime);
                           throw ModelicaSimulationError(ALGLOOP_EQ_SYSTEM,error);

                       }
                }
               >>
         end match

  case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
    then
      let i = nls.index
      match context
        case  ALGLOOP_CONTEXT(genInitialisation=true)
          then
              <<
              try
              {
                _algLoopSolver<%nls.index%>->initialize();
                _algLoop<%nls.index%>->evaluate();
                for(int i=0; i<_dimZeroFunc; i++)
                {
                  getCondition(i);
                }
                IContinuous::UPDATETYPE calltype = _callType;
                _callType = IContinuous::CONTINUOUS;
                _algLoopSolver<%nls.index%>->solve();
                _callType = calltype;
              }
              catch(ModelicaSimulationError& ex)
              {

                   string error = add_error_info("Nonlinear solver <%nls.index%> stopped",ex.what(),ex.getErrorID(),_simTime);
                    throw ModelicaSimulationError(ALGLOOP_EQ_SYSTEM,error);
              }
              >>
            else
              <<
              bool restart<%nls.index%> = true;

              unsigned int iterations<%nls.index%> = 0;
              _algLoop<%nls.index%>->getReal(_algloop<%nls.index%>Vars);
              bool restatDiscrete<%nls.index%> = false;
              try
                {
                   _algLoop<%nls.index%>->evaluate();
                    if( _callType == IContinuous::DISCRETE )
                    {
                       while(restart<%nls.index%> && !(iterations<%nls.index%>++>500))
                       {
                         getConditions(_conditions0<%nls.index%>);
                         _callType = IContinuous::CONTINUOUS;
                         _algLoopSolver<%nls.index%>->solve();
                         _callType = IContinuous::DISCRETE;
                         for(int i=0;i<_dimZeroFunc;i++)
                         {
                           getCondition(i);
                         }
                         getConditions(_conditions1<%nls.index%>);
                         restart<%nls.index%> = !std::equal (_conditions1<%nls.index%>, _conditions1<%nls.index%>+_dimZeroFunc,_conditions0<%nls.index%>);
                       }
                    }
                    else
                       _algLoopSolver<%nls.index%>->solve();
                }
                catch(ModelicaSimulationError &ex)
                {
                  restatDiscrete<%nls.index%>=true;
                }

                if((restart<%nls.index%>&& iterations<%nls.index%> > 0)|| restatDiscrete<%nls.index%>)
                {
                      try
                       {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
                          IContinuous::UPDATETYPE calltype = _callType;
                         _callType = IContinuous::DISCRETE;
                           _algLoop<%nls.index%>->setReal(_algloop<%nls.index%>Vars );
                          _algLoopSolver<%nls.index%>->solve();
                         _callType = calltype;
                       }
                       catch(ModelicaSimulationError& ex)
                       {
                           string error = add_error_info("Nonlinear solver <%nls.index%> stopped",ex.what(),ex.getErrorID(),_simTime);
                           throw ModelicaSimulationError(ALGLOOP_EQ_SYSTEM,error);

                       }
                }
               >>
         end match
  case e as SES_MIXED(__)
    /*<%equationMixed(e, context, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>*/
    then
    <<
     throw ModelicaSimulationError(ALGLOOP_EQ_SYSTEM,"Mixed systems are not supported yet");
    >>
  case e as SES_FOR_LOOP(__)
    then
    <<
    FOR LOOPS ARE NOT IMPLEMENTED
    >>
  case e as SES_IFEQUATION(__)
    then
    <<
    IF EQUATIONS ARE NOT IMPLEMENTED
    >>
  else
    "NOT IMPLEMENTED EQUATION 2"
end equationString;

template equation_function_call(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Text method)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=

    let ix_str = equationIndex(eq)
     <<
     <%method%>_<%ix_str%>();
     >>

end equation_function_call;

template equation_function_create_single_func(SimEqSystem eq, Context context, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace,
                                              Text method,Text classnameext, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Boolean createMeasureTime,
                                              Boolean assignToStartValues, Boolean overwriteOldStartValue, String defaultVarDeclsLocal)
::=
  let ix_str = equationIndex(eq)
  let ix_str_array = intSub(stringInt(ix_str),1) //equation index - 1
  let &varDeclsLocal = buffer defaultVarDeclsLocal /*BUFD*/
  let &additionalFuncs = buffer "" /*BUFD*/
  let &measureTimeStartVar = buffer "" /*BUFD*/
  let &measureTimeEndVar = buffer "" /*BUFD*/

  let body = match eq
   case e as SES_SIMPLE_ASSIGN(__)
     then
      equationSimpleAssign(e, context, &varDeclsLocal, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation, assignToStartValues, overwriteOldStartValue)
   case e as SES_IFEQUATION(__)
     then
     equationIfEquation(e, context, &varDeclsLocal, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
   case e as SES_ALGORITHM(__)
      then
      equationAlgorithm(e, context, &varDeclsLocal,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
   case e as SES_WHEN(__)
      then
      equationWhen(e, context, &varDeclsLocal, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    case e as SES_ARRAY_CALL_ASSIGN(__)
      then
      equationArrayCallAssign(e, context, &varDeclsLocal, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    case e as SES_LINEAR(__)
    case e as SES_NONLINEAR(__)
      then
      equationLinearOrNonLinear(e, context, &varDeclsLocal,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName)
    case e as SES_MIXED(__)
      then
      /*<%equationMixed(e, context, &varDeclsLocal, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>*/
      let &additionalFuncs += equation_function_create_single_func(e.cont, context, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, method, classnameext, stateDerVectorName, useFlatArrayNotation, createMeasureTime, assignToStartValues, overwriteOldStartValue, "")
      "throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,\"Mixed systems are not supported yet\");"
    case e as SES_FOR_LOOP(__)
      then
        equationForLoop(e, context, &varDeclsLocal,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    else
      "NOT IMPLEMENTED EQUATION"
  end match
  let &measureTimeStartVar += if createMeasureTime then generateMeasureTimeStartCode("measuredProfileBlockStartValues", 'evaluate<%ix_str%>', "MEASURETIME_PROFILEBLOCKS") else ""
  let &measureTimeEndVar += if createMeasureTime then generateMeasureTimeEndCode("measuredProfileBlockStartValues", "measuredProfileBlockEndValues", '(*measureTimeProfileBlocksArray)[<%ix_str_array%>]', 'evaluate<%ix_str%>', "MEASURETIME_PROFILEBLOCKS") else ""
    <<
    <%additionalFuncs%>
    /*
    <%dumpEqs(fill(eq,1))%>
    */
    void <%lastIdentOfPathFromSimCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%><%classnameext%>::<%method%>_<%ix_str%>()
    {
      <%varDeclsLocal%>
      <%if(createMeasureTime) then measureTimeStartVar%>
      <%body%>
      <%if(createMeasureTime) then measureTimeEndVar%>
    }
    >>
end equation_function_create_single_func;

template equationMixed(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                       Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a mixed equation system."
::=
match eq
case SES_MIXED(__) then
  let contEqs = equation_(cont, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let numDiscVarsStr = listLength(discVars)
//  let valuesLenStr = listLength(values)
  let &preDisc = buffer "" /*BUFD*/
  let num = index
  let discvars2 = (discEqs |> SES_SIMPLE_ASSIGN(__) hasindex i0 =>
      let expPart = daeExp(exp, context, &preDisc, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      <<
      <%cref(cref, useFlatArrayNotation)%> = <%expPart%>;
      new_disc_vars<%num%>[<%i0%>] = <%cref(cref, useFlatArrayNotation)%>;
      >>
    ;separator="\n")
  <<
    <% /*
      bool values<%num%>[<%valuesLenStr%>] = {<%values ;separator=", "%>};
      bool pre_disc_vars<%num%>[<%numDiscVarsStr%>];
      bool new_disc_vars<%num%>[<%numDiscVarsStr%>];
      bool restart<%num%> = true;
      int iter<%num%>=0;
      int max_iter<%num%> = (<%valuesLenStr%> / <%numDiscVarsStr%>)+1;
       while(restart<%num%> && !(iter<%num%> > max_iter<%num%>))
       {
         <%discVars |> SIMVAR(__) hasindex i0 => 'pre_disc_vars<%num%>[<%i0%>] = <%cref(name, useFlatArrayNotation)%>;' ;separator="\n"%>
          <%contEqs%>

          <%preDisc%>
         <%discvars2%>
         bool* cur_disc_vars<%num%>[<%numDiscVarsStr%>]= {<%discVars |> SIMVAR(__) => '&<%cref(name, useFlatArrayNotation)%>' ;separator=", "%>};
       restart<%num%>=!(_event_handling->CheckDiscreteValues(values<%num%>,pre_disc_vars<%num%>,new_disc_vars<%num%>,cur_disc_vars<%num%>,<%numDiscVarsStr%>,iter<%num%>,<%valuesLenStr%>));
       iter<%num%>++;
    }
    if(iter<%num%>>max_iter<%num%> && (restart<%num%> == true) )
    {
        //throw std::runtime_error("Number of iteration steps exceeded for discrete varibales check . ");
        cout << "Number of iteration steps exceeded for discrete varibales check at time " << time << std::endl;
    }
    */ %>
  >>
end equationMixed;

template generateStepCompleted(list<SimEqSystem> allEquations,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver =   generateStepCompleted2(allEquations,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
let store_delay_expr = functionStoreDelay(delayedExps, simCode ,&extraFuncs ,&extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)

   let outputBounds = match simCode
             case simCode as SIMCODE(__) then
                 match modelInfo
                   case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
                    let &varOptDecls = buffer "" /*BUFD*/
          let &optpreExp = buffer "" /*BUFD*/

          let outputnames = vars.outputVars |>  SIMVAR(__) hasindex i0 =>
             'dynamic_cast<SimDouble*>( _simObjects->getSimData(_modelName)->Get("<%cref(name, useFlatArrayNotation)%>"))->getValue() = <%cref(name, useFlatArrayNotation)%>;';separator="\n"
          <<
          #if defined(__TRICORE__) || defined(__vxworks)
              <%outputnames%>
          #endif
          >>

  <<
  bool <%lastIdentOfPath(modelInfo.name)%>::stepCompleted(double time)
  {
  <%algloopsolver%>
  <%store_delay_expr%>

  <%outputBounds%>

  saveAll();
  return _terminate;
  }
  >>

end generateStepCompleted;



template generateRestoreOldValues(list<SimEqSystem> allEquations,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver =   generateRestoreOldValues2(allEquations,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__))
  then
  <<
  void <%lastIdentOfPath(modelInfo.name)%>::restoreOldValues()
  {
    <%algloopsolver%>
  }
  >>

end generateRestoreOldValues;


template generateRestoreOldValues2(list<SimEqSystem> allEquations,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (allEquations |> eqs => (eqs |> eq =>
      generateRestoreOldValues3(eq, contextOther, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator="\n")
    ;separator="\n")

  <<
  <%algloopsolver%>
  >>

end generateRestoreOldValues2;


template generateRestoreOldValues3(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
    then
      let num = ls.index
      match simCode
      case SIMCODE(modelInfo = MODELINFO(__)) then
       <<
        _algLoopSolver<%num%>->restoreOldValues();
       >>
       end match
  case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
    then
      let num = nls.index
      match simCode
      case SIMCODE(modelInfo = MODELINFO(__)) then
       <<
        _algLoopSolver<%num%>->restoreOldValues();
       >>
       end match
  case e as SES_MIXED(cont = eq_sys)
      then
       <<
       <%generateRestoreOldValues3(eq_sys,context,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
       >>
  else
    ""
 end generateRestoreOldValues3;


template generateRestoreNewValues(list<SimEqSystem> allEquations,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver =   generateRestoreOldValues2(allEquations,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__))
  then
  <<
  void <%lastIdentOfPath(modelInfo.name)%>::restoreNewValues()
  {
    <%algloopsolver%>
  }
  >>

end generateRestoreNewValues;


template generateRestoreNewValues2(list<SimEqSystem> allEquations,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (allEquations |> eqs => (eqs |> eq =>
      generateRestoreNewValues3(eq, contextOther, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator="\n")
    ;separator="\n")

  <<
  <%algloopsolver%>
  >>

end generateRestoreNewValues2;


template generateRestoreNewValues3(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
    then
      let num = ls.index
      match simCode
      case SIMCODE(modelInfo = MODELINFO(__)) then
       <<
        _algLoopSolver<%num%>->restoreNewValues();
       >>
       end match
  case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
    then
      let num = nls.index
      match simCode
      case SIMCODE(modelInfo = MODELINFO(__)) then
       <<
        _algLoopSolver<%num%>->restoreNewValues();
       >>
       end match
  case e as SES_MIXED(cont = eq_sys)
      then
       <<
       <%generateRestoreNewValues3(eq_sys,context,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
       >>
  else
    ""
 end generateRestoreNewValues3;



template generateStepStarted(list<SimEqSystem> allEquations,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
   let inputBounds = match simCode
             case simCode as SIMCODE(__) then
                 match modelInfo
                   case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
                    let &varOptDecls = buffer "" /*BUFD*/
          let &optpreExp = buffer "" /*BUFD*/

          let inputnames = vars.inputVars |>  SIMVAR(__) hasindex i0 =>
             '<%cref(name, useFlatArrayNotation)%> = dynamic_cast<SimDouble*>(_simObjects->getSimData(_modelName)->Get("<%cref(name, useFlatArrayNotation)%>"))->getValue();';separator="\n"
          <<
          #if defined(__TRICORE__) || defined(__vxworks)
              <%inputnames%>
          #endif
          >>

  <<
  bool <%lastIdentOfPath(modelInfo.name)%>::stepStarted(double time)
  {
  <%inputBounds%>

  return true;
  }
  >>

end generateStepStarted;


template generatehandleTimeEvent(list<BackendDAE.TimeEvent> timeEvents, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Boolean createMeasureTime)
::=

  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
  let &measureTimeStartVar = buffer "" /*BUFD*/
  let &measureTimeEndVar = buffer "" /*BUFD*/
  let &measureTimeStartVar += if createMeasureTime then generateMeasureTimeStartCode("measuredFunctionStartValues", "handleTimeEvents", "MEASURETIME_MODELFUNCTIONS") else ""
  let &measureTimeEndVar += if createMeasureTime then generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "(*measureTimeFunctionsArray)[3]", "handleTimeEvents", "MEASURETIME_MODELFUNCTIONS") else ""
  <<
  void <%lastIdentOfPath(modelInfo.name)%>::handleTimeEvent(int* time_events)
  {
    <%measureTimeStartVar%>
    for(int i=0; i<_dimTimeEvent; i++)
    {
      if(time_events[i] != _time_event_counter[i])
        _time_conditions[i] = true;
      else
        _time_conditions[i] = false;
    }
    memcpy(_time_event_counter, time_events, (int)_dimTimeEvent*sizeof(int));
    <%measureTimeEndVar%>
  }
  >>

end generatehandleTimeEvent;

template generateDimTimeEvent(list<SimEqSystem> allEquations,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
  <<
  int <%lastIdentOfPath(modelInfo.name)%>::getDimTimeEvent() const
  {
    return _dimTimeEvent;
  }
  >>

end generateDimTimeEvent;


template generateTimeEvent(list<BackendDAE.TimeEvent> timeEvents, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__))
    then
      let &varDecls = buffer "" /*BUFD*/
      <<
      void <%lastIdentOfPath(modelInfo.name)%>::getTimeEvent(time_event_type& time_events)
      {
        <%(timeEvents |> timeEvent  =>
          match timeEvent
            case SAMPLE_TIME_EVENT(__) then
              let &preExp = buffer "" /*BUFD*/
              let e1 = daeExp(startExp, contextOther, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
              let e2 = daeExp(intervalExp, contextOther, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
              <<
              <%preExp%>
              time_events.push_back(std::make_pair(<%e1%>, <%e2%>));
              >>
            else ''
          ;separator="\n\n")%>
         // simplified treatment of clocks in model as time events
        for (int i = 0; i < _dimClock; i++)
          time_events.push_back(std::make_pair(_clockShift[i] * _clockInterval[i], _clockInterval[i]));
      }
      >>
end generateTimeEvent;


template generateStepCompleted2(list<SimEqSystem> allEquations,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (allEquations |> eqs => (eqs |> eq =>
      generateStepCompleted3(eq, contextOther, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator="\n")
    ;separator="\n")

  <<
  <%algloopsolver%>
  >>

end generateStepCompleted2;


template generateStepCompleted3(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
    then
      let num = ls.index
      match simCode
      case SIMCODE(modelInfo = MODELINFO(__)) then
       <<
        _algLoopSolver<%num%>->stepCompleted(_simTime);
       >>
       end match
  case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
    then
      let num = nls.index
      match simCode
      case SIMCODE(modelInfo = MODELINFO(__)) then
       <<
        _algLoopSolver<%num%>->stepCompleted(_simTime);
       >>
       end match
  case e as SES_MIXED(cont = eq_sys)
      then
       <<
       <%generateStepCompleted3(eq_sys,context,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
       >>
  else
    ""
 end generateStepCompleted3;



template generateAlgloopsolvers(list<SimEqSystem> allEquations,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (allEquations |> eqs => (eqs |> eq =>
      generateAlgloopsolvers2(eq, contextOther, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator="\n")
    ;separator="\n")

   <<
   <%algloopsolver%>
   >>

end generateAlgloopsolvers;


template generatefriendAlgloops(list<SimEqSystem> allEquations, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 ::=
    let friendalgloops = (allEquations |> eqs => (eqs |> eq =>
      generatefriendAlgloops2(eq, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator="\n")
    ;separator="\n")
  <<
  <%friendalgloops%>
  >>
 end generatefriendAlgloops;


 template generatefriendAlgloops2(SimEqSystem eq, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 ::=
  match eq
  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
    then
      let num = ls.index
      match simCode
      case SIMCODE(modelInfo = MODELINFO(__)) then
      <<
      friend class <%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>;
      >>
      end match
  case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
    then
      let num = nls.index
      match simCode
      case SIMCODE(modelInfo = MODELINFO(__)) then
      <<
      friend class <%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>;
      >>
      end match
  case e as SES_MIXED(cont = eq_sys)
    then
      <<
      <%generatefriendAlgloops2(eq_sys,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
      >>
  else
    ""
 end generatefriendAlgloops2;



template generateAlgloopsolvers2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
    then
      let num = ls.index
      match simCode
      case SIMCODE(modelInfo = MODELINFO(__)) then
      <<
      _algLoop<%num%> =  shared_ptr<IAlgLoop>(new <%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>(this,__z,__zDot,_conditions,_discrete_events));
      _algLoopSolver<%num%> = shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop<%num%>.get()));
      >>
      end match
  case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
    then
      let num = nls.index
      match simCode
      case SIMCODE(modelInfo = MODELINFO(__)) then
      <<
      _algLoop<%num%> =  shared_ptr<IAlgLoop>(new <%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>(this,__z,__zDot,_conditions,_discrete_events));
      _algLoopSolver<%num%> = shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop<%num%>.get()));
      >>
      end match
  case e as SES_MIXED(cont = eq_sys)
  then
   <<
   <%generateAlgloopsolvers2(eq_sys,context,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
   >>
  else
    ""
 end generateAlgloopsolvers2;
/*
let jacAlgloopsolver = (jacobianMatrixes |> (mat, _, _, _, _, _, _) hasindex index0 =>
       (mat |> (eqs,_,_) =>  generateAlgloopsolverVariables(eqs,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator="\n")
     ;separator="")
*/
template generateAlgloopsolverVariables(list<SimEqSystem> allEquationsPlusWhen,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (allEquationsPlusWhen |> eqs => (eqs |> eq =>
      generateAlgloopsolverVariables2(eq, contextOther, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace);separator="\n")
    ;separator="\n")



  <<
  <%algloopsolver%>

  >>
end generateAlgloopsolverVariables;


template generateAlgloopsolverVariables2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
   case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
     then
       let num = ls.index
       match simCode
       case SIMCODE(modelInfo = MODELINFO(__)) then
        <<
        shared_ptr<IAlgLoop>  //Algloop  which holds equation system
             _algLoop<%num%>;
        shared_ptr<IAlgLoopSolver>
             _algLoopSolver<%num%>;        ///< Solver for algebraic loop */
         bool* _conditions0<%num%>;
         bool* _conditions1<%num%>;
         double* _algloop<%num%>Vars;
        >>
        end match
   case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
     then
       let num = nls.index
       match simCode
       case SIMCODE(modelInfo = MODELINFO(__)) then
        <<
        shared_ptr<IAlgLoop>  //Algloop  which holds equation system
             _algLoop<%num%>;
        shared_ptr<IAlgLoopSolver>
             _algLoopSolver<%num%>;        ///< Solver for algebraic loop */
         bool* _conditions0<%num%>;
         bool* _conditions1<%num%>;
         double* _algloop<%num%>Vars;
        >>
        end match
   case e as SES_MIXED(cont = eq_sys)
     then
       <<
       <%generateAlgloopsolverVariables2(eq_sys,context,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
       >>
    else
      ""
 end generateAlgloopsolverVariables2;

template generateInitAlgloopsolverVariables(list<JacobianMatrix> jacobianMatrixes,list<SimEqSystem> allEquationsPlusWhen,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text className)
::=
  let &funcCalls = buffer "" /*BUFD*/
   let &jacFuncCalls = buffer "" /*BUFD*/
  let algloopsolverFuncs = (List.partition(allEquationsPlusWhen, 100) |> part hasindex i0 =>
      generateInitAlgloopsolverVariables1(part, i0, &funcCalls ,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, className);separator="\n")
  let &varDecls = buffer "" /*BUFD*/
  let jacAlgloopsolverFuncs  =  (jacobianMatrixes |> (mat, _, _, _, _, _, _) =>
          ( mat |> (eqs,_,_)  => (eqs |> eq => generateInitAlgloopsolverVariables2(eq, contextOther, varDecls ,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
          ) ;separator="\n")
         ;separator="")
  <<
  <%algloopsolverFuncs%>

  void <%className%>::initializeAlgloopSolverVariables()
  {
    <%funcCalls%>
    initializeJacAlgloopSolverVariables();
  }


  void <%className%>::initializeJacAlgloopSolverVariables()
  {
    <%jacAlgloopsolverFuncs%>
  }
  >>
end generateInitAlgloopsolverVariables;

//generateInitAlgloopsolverVariables2(eq, contextOther, varDecls ,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)

template generateInitAlgloopsolverVariables1(list<SimEqSystem> allEquationsPlusWhen, Integer partIdx, Text &funcCalls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text className)
::=
  let &varDecls = buffer "" /*BUFD*/

  let algloopsolver = (allEquationsPlusWhen |> eqs => (eqs |> eq =>
      generateInitAlgloopsolverVariables2(eq, contextOther, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace);separator="\n")
    ;separator="\n")

  let &funcCalls += 'initializeAlgloopSolverVariables_<%partIdx%>(); <%\n%>'
  <<
  void <%className%>::initializeAlgloopSolverVariables_<%partIdx%>()
  {
    <%algloopsolver%>
  }

  >>
end generateInitAlgloopsolverVariables1;


template generateInitAlgloopsolverVariables2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
    case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
      then
        let num = ls.index
        match simCode
          case SIMCODE(modelInfo = MODELINFO(__)) then
            <<
            _conditions0<%num%> = NULL;
            _conditions1<%num%> = NULL;
            _algloop<%num%>Vars = NULL;
            >>
        end match
    case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
      then
        let num = nls.index
        match simCode
          case SIMCODE(modelInfo = MODELINFO(__)) then
            <<
            _conditions0<%num%> = NULL;
            _conditions1<%num%> = NULL;
            _algloop<%num%>Vars = NULL;
            >>
        end match
    else ""
end generateInitAlgloopsolverVariables2;

template generateDeleteAlgloopsolverVariables(list<JacobianMatrix> jacobianMatrixes,list<SimEqSystem> allEquationsPlusWhen,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text className)
::=
  let &funcCalls = buffer "" /*BUFD*/
  let algloopsolverFuncs = (List.partition(allEquationsPlusWhen,100) |> part hasindex i0 =>
      generateDeleteAlgloopsolverVariables1(part, i0, &funcCalls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, className);separator="\n")
  let &varDecls = buffer "" /*BUFD*/
  let jacAlgloopsolverFuncs  =  (jacobianMatrixes |> (mat, _, _, _, _, _, _) =>
          ( mat |> (eqs,_,_)  => (eqs |> eq => generateDeleteAlgloopsolverVariables2(eq, contextOther, varDecls ,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
          ) ;separator="\n")
         ;separator="")

  <<
  <%algloopsolverFuncs%>

  void <%className%>::deleteAlgloopSolverVariables()
  {
    <%funcCalls%>
    deleteJacAlgloopSolverVariables();
  }
  void <%className%>::deleteJacAlgloopSolverVariables()
  {
    <%jacAlgloopsolverFuncs%>
  }
  >>
end generateDeleteAlgloopsolverVariables;

template generateDeleteAlgloopsolverVariables1(list<SimEqSystem> allEquationsPlusWhen, Integer partIdx, Text &funcCalls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text className)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (allEquationsPlusWhen |> eqs => (eqs |> eq =>
      generateDeleteAlgloopsolverVariables2(eq, contextOther, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace);separator="\n")
    ;separator="\n")
  let &funcCalls += 'deleteAlgloopSolverVariables_<%partIdx%>(); <%\n%>'
  <<
  void <%className%>::deleteAlgloopSolverVariables_<%partIdx%>()
  {
    <%algloopsolver%>

  }

  >>
end generateDeleteAlgloopsolverVariables1;

template generateDeleteAlgloopsolverVariables2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
   case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
    then
      let num = ls.index
      match simCode
      case SIMCODE(modelInfo = MODELINFO(__)) then
       <<
          if(_conditions0<%num%>)
            delete [] _conditions0<%num%>;
          if(_conditions1<%num%>)
            delete [] _conditions1<%num%>;
          if(_algloop<%num%>Vars)
            delete [] _algloop<%num%>Vars;
       >>
       end match
   case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
    then
      let num = nls.index
      match simCode
      case SIMCODE(modelInfo = MODELINFO(__)) then
       <<
          if(_conditions0<%num%>)
            delete [] _conditions0<%num%>;
          if(_conditions1<%num%>)
            delete [] _conditions1<%num%>;
          if(_algloop<%num%>Vars)
            delete [] _algloop<%num%>Vars;
       >>
       end match
  else
    ""
 end generateDeleteAlgloopsolverVariables2;



// shared_ptr<<%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>>  //Algloop  which holds equation system
template initAlgloopsolvers(list<SimEqSystem> allEquationsPlusWhen,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (allEquationsPlusWhen |> eqs => (eqs |> eq =>
      initAlgloopsolvers2(eq, contextOther, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace))
    ;separator="")

  <<
  <%algloopsolver%>
  >>
end initAlgloopsolvers;


template initAlgloopsolver(list<SimEqSystem> equations,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (equations |> eq =>
      initAlgloopsolvers2(eq, contextOther, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
    ;separator="")

  <<
  <%algloopsolver%>
  >>
end initAlgloopsolver;


template initAlgloopsolvers2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
   case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
     then
      let num = ls.index
      match simCode
      case SIMCODE(modelInfo = MODELINFO(__)) then
       <<
       if(_algLoopSolver<%num%>)
           _algLoopSolver<%num%>->initialize();<%\n%>
       >>
       end match
   case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
     then
      let num = nls.index
      match simCode
      case SIMCODE(modelInfo = MODELINFO(__)) then
       <<
       if(_algLoopSolver<%num%>)
           _algLoopSolver<%num%>->initialize();
       >>
       end match
   case e as SES_MIXED(cont = eq_sys)
     then
       <<
       <%initAlgloopsolvers2(eq_sys,context,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
       >>
   else
     ""
 end initAlgloopsolvers2;


template initAlgloopVars(list<SimEqSystem> allEquationsPlusWhen,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  let &varDecls = buffer "" /*BUFD*/
   let algloopsolver = (allEquationsPlusWhen |> eqs => (eqs |> eq =>
      initAlgloopVars2(eq, contextOther, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace))
    ;separator="")

  <<
  <%algloopsolver%>

  >>
end initAlgloopVars;


template initAlgloopVars2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
   case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
     then
       let num = ls.index
       match simCode
         case SIMCODE(modelInfo = MODELINFO(__)) then
          <<
            if(_algloop<%ls.index%>Vars)
              delete [] _algloop<%ls.index%>Vars;
            if(_conditions0<%ls.index%>)
              delete [] _conditions0<%ls.index%>;
            if(_conditions1<%ls.index%>)
              delete [] _conditions1<%ls.index%>;
            unsigned int dim<%ls.index%> = _algLoop<%ls.index%>->getDimReal();
            _algloop<%ls.index%>Vars = new double[dim<%ls.index%>];
            _conditions0<%ls.index%> = new bool[_dimZeroFunc];
            _conditions1<%ls.index%> = new bool[_dimZeroFunc];
          >>
        end match
   case  SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
     then
       let num = nls.index
       match simCode
         case SIMCODE(modelInfo = MODELINFO(__)) then
          <<
            if(_algloop<%nls.index%>Vars)
              delete [] _algloop<%nls.index%>Vars;
            if(_conditions0<%nls.index%>)
              delete [] _conditions0<%nls.index%>;
            if(_conditions1<%nls.index%>)
              delete [] _conditions1<%nls.index%>;
            unsigned int dim<%nls.index%> = _algLoop<%nls.index%>->getDimReal();
            _algloop<%nls.index%>Vars = new double[dim<%nls.index%>];
            _conditions0<%nls.index%> = new bool[_dimZeroFunc];
            _conditions1<%nls.index%> = new bool[_dimZeroFunc];
          >>
        end match
   case e as SES_MIXED(cont = eq_sys)
     then
       <<
       <%initAlgloopsolvers2(eq_sys,context,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
       >>
   else
     " "
end initAlgloopVars2;


template algloopForwardDeclaration(list<SimEqSystem> allEquations,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  let &varDecls = buffer "" /*BUFD*/
  <<
  <% allEquations |> eqs => (eqs |> eq =>
      algloopForwardDeclaration2(eq, contextOther, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator="\n" )
    ;separator="\n" %>
  >>
end algloopForwardDeclaration;

template algloopForwardDeclaration2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  match eq
   case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
     then
       let num = ls.index
       match simCode
           case SIMCODE(modelInfo = MODELINFO(__)) then
           <<
           class <%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>;
           >>
      end match
   case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
     then
       let num = nls.index
       match simCode
           case SIMCODE(modelInfo = MODELINFO(__)) then
           <<
           class <%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>;
           >>
      end match
  case e as SES_MIXED(cont = eq_sys)
    then
      <<
      <%algloopForwardDeclaration2(eq_sys,context,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
      >>
  else
       ""
end algloopForwardDeclaration2;

template algloopfilesInclude(list<SimEqSystem> allEquations,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  let &varDecls = buffer "" /*BUFD*/
  <<
  <% allEquations |> eqs => (eqs |> eq =>
      algloopfilesInclude2(eq, contextOther, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator="\n" )
    ;separator="\n" %>
  >>
end algloopfilesInclude;

template algloopfilesInclude2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
    then
      let num = ls.index
      match simCode
        case SIMCODE(modelInfo = MODELINFO(__)) then
          '#include "OMCpp<%fileNamePrefix%>Algloop<%num%>.h"<%\n%>'
      end match
  case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
    then
      let num = nls.index
      match simCode
        case SIMCODE(modelInfo = MODELINFO(__)) then
          '#include "OMCpp<%fileNamePrefix%>Algloop<%num%>.h"<%\n%>'
      end match
  case e as SES_MIXED(cont = eq_sys)
    then
      <<
      <%algloopfilesInclude2(eq_sys,context,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
      >>
  else
       ""
 end algloopfilesInclude2;


// use allEquations instead of odeEquations, because only allEquations are labeled for reduction algorithms
template algloopfiles(list<SimEqSystem> allEquations, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (allEquations |> eqs =>
      algloopfiles2(eqs, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    ;separator="\n")

  <<
  <%algloopsolver%>
  >>
end algloopfiles;


template algloopfiles2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
    then
      let num = ls.index
      match simCode
          case SIMCODE(modelInfo = MODELINFO(__)) then
              let()= textFile(algloopHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, eq, context, useFlatArrayNotation), 'OMCpp<%fileNamePrefix%>Algloop<%num%>.h')
              let()= textFile(algloopCppFile(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, eq, context, stateDerVectorName, useFlatArrayNotation), 'OMCpp<%fileNamePrefix%>Algloop<%num%>.cpp')
            " "
      end match
  case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
    then
      let num = nls.index
      match simCode
          case SIMCODE(modelInfo = MODELINFO(__)) then
              let()= textFile(algloopHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, eq, context, useFlatArrayNotation), 'OMCpp<%fileNamePrefix%>Algloop<%num%>.h')
              let()= textFile(algloopCppFile(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, eq, context, stateDerVectorName, useFlatArrayNotation), 'OMCpp<%fileNamePrefix%>Algloop<%num%>.cpp')
            " "
      end match
  case e as SES_MIXED(cont = eq_sys)
    then
       match simCode
          case SIMCODE(modelInfo = MODELINFO(__)) then
              let()= textFile(algloopHeaderFile(simCode ,&extraFuncs, &extraFuncsDecl, extraFuncsNamespace, eq_sys,context, useFlatArrayNotation), 'OMCpp<%fileNamePrefix%>Algloop<%algloopfilesindex(eq_sys)%>.h')
              let()= textFile(algloopCppFile(simCode ,&extraFuncs, &extraFuncsDecl, extraFuncsNamespace, eq_sys,context, stateDerVectorName, useFlatArrayNotation), 'OMCpp<%fileNamePrefix%>Algloop<%algloopfilesindex(eq_sys)%>.cpp')
            " "
        end match
  else
    " "
 end algloopfiles2;

template algloopMainfile(list<SimEqSystem> allEquations, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Context context)
::=
  match(simCode )
  case SIMCODE(modelInfo = MODELINFO(__)) then
    let modelname =  lastIdentOfPath(modelInfo.name)
    let filename = fileNamePrefix
    let modelfilename =  match context case  ALGLOOP_CONTEXT(genInitialisation=false,genJacobian=true)  then '<%filename%>Jacobian' else '<%filename%>'

    let jacfiles = (jacobianMatrixes |> (mat, _, _, _, _, _, _) hasindex index0 => (mat |> (eqs,_,_) =>  algloopMainfile1(eqs,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,filename) ;separator="") ;separator="")
    let algloopfiles = (listAppend(allEquations,initialEquations) |> eqs => algloopMainfile2(eqs, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, filename) ;separator="\n")

    <<
    /*****************************************************************************
    *
    * Helper file that includes all alg-loop files.
    * This file is generated by the OpenModelica Compiler and produced to speed-up the compile time.
    *
    *****************************************************************************/
    #include <Core/System/AlgLoopDefaultImplementation.h>
    //jac files
    <%jacfiles%>
    //alg loop files
    <%algloopfiles%>
    >>
end algloopMainfile;

template algloopMainfile1(list<SimEqSystem> allEquations, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, String filename)
::=
  let algloopfiles = (allEquations |> eqs => algloopMainfile2(eqs, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, filename); separator="\n")
  <<
  <%algloopfiles%>
  >>
end algloopMainfile1;

template algloopMainfile2(SimEqSystem eq, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, String filename)
::=
  match eq
  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
    let num = ls.index
    <<
    #include "OMCpp<%filename%>Algloop<%ls.index%>.h"
    #include "OMCpp<%filename%>Algloop<%ls.index%>.cpp"<%\n%>
    >>
  case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
    let num = nls.index
    <<
    #include "OMCpp<%filename%>Algloop<%nls.index%>.h"
    #include "OMCpp<%filename%>Algloop<%nls.index%>.cpp"<%\n%>
    >>
  else
    <<
    >>
end algloopMainfile2;

template algloopfilesindex(SimEqSystem eq)
"Generates an index for algloopfile.
  "
::=
  match eq
  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
    then
      <<<%ls.index%>>>
  case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
  then
      <<<%nls.index%>>>
  case e as SES_MIXED(__)
    then
      <<<%index%>>>
  else
    " "
 end algloopfilesindex;

template algloopcppfilenames(list<SimEqSystem> allEquations,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (allEquations |> eqs => (eqs |> eq =>
      algloopcppfilenames2(eq, contextOther, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace))
    ;separator="\t" ;align=10;alignSeparator="\\\n\t"  )

  <<
  <%algloopsolver%>
  >>
end algloopcppfilenames;


template algloopcppfilenames2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
   case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))
     then
       let num = ls.index
       match simCode
       case SIMCODE(modelInfo = MODELINFO(__)) then
        <<
        OMCpp<%fileNamePrefix%>Algloop<%num%>.cpp
        >>
        end match
   case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
     then
       let num = nls.index
       match simCode
       case SIMCODE(modelInfo = MODELINFO(__)) then
        <<
        OMCpp<%fileNamePrefix%>Algloop<%num%>.cpp
        >>
        end match
   case e as SES_MIXED(cont = eq_sys)
     then
       <<
       <%algloopcppfilenames2(eq_sys,context,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
       >>
   else
     ""
 end algloopcppfilenames2;





template equationArrayCallAssign(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs,
                                 Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates equation on form 'cref_array = call(...)'."
::=
let &varDeclsCref = buffer "" /*BUFD*/
match eq

case eqn as SES_ARRAY_CALL_ASSIGN(lhs=lhs as CREF(__)) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(exp, context, &preExp /*BUF  let &preExp = buffer "" /*BUFD*/
  let &helpInits = buffer "" /*BUFD*/
  let helpIf = (conditions |> (e, hidx) =>
      let helpInit = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, useFlatArrayNotation)
      let &helpInits += 'localData->helpVars[<%hidx%>] = <%helpInit%>;'
      'localData->helpVars[<%hidx%>] && !localData->helpVars_saved[<%hidx%>] /* edge */'
    ;separator=" || ")C*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match expTypeFromExpShort(eqn.exp)
  case "boolean" then


    <<
    <%preExp%>
    <%cref1(lhs.componentRef,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>=<%expPart%>;
    >>
  case "int" then

    <<
    <%preExp%>

    <%cref1(lhs.componentRef,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>=<%expPart%>;
    >>
  case "double" then
    <<
    <%preExp%>
    <%assignDerArray(context,expPart,lhs.componentRef,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
    >>
end equationArrayCallAssign;

template assignDerArray(Context context, String arr, ComponentRef c,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  cref2simvar(c, simCode ) |> var as SIMVAR(__) =>
   match varKind
    case STATE(__)        then
     let &varDeclsCref = buffer "" /*BUFD*/
     <<
     /*<%cref(c,useFlatArrayNotation)%>*/
     memcpy(&<%cref1(c,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>,<%arr%>.getData(),<%arr%>.getNumElems()*sizeof(double));
     >>
    case STATE_DER(__)   then
     let &varDeclsCref = buffer "" /*BUFD*/
    <<
    memcpy(&<%cref1(c,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>,<%arr%>.getData(),<%arr%>.getNumElems()*sizeof(double));
    >>
    else
     let &varDeclsCref = buffer "" /*BUFD*/
    <<
    <%cref1(c,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>.assign(<%arr%>);
    >>
end assignDerArray;

template equationWhen(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                      Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a when equation."
::=
  let &varDeclsCref = buffer "" /*BUFD*/
  let sysderef = match context case ALGLOOP_CONTEXT(__) then '_system->'
  match eq
     case SES_WHEN(whenStmtLst = whenStmtLst, conditions=conditions, elseWhen=NONE()) then
      let helpIf = (conditions |> e => ' || (<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%> && !_discrete_events->pre(<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>))')

        /*let initial_assign =
        if initialCall then
          whenAssign(left, typeof(right), right, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        else
           '<%cref1(left,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%> = _discrete_events->pre(<%cref1(left,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>);'*/
      let body = whenOperators(whenStmtLst, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      let pre_call = preCall(whenStmtLst, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      <<
      if (<%sysderef%>_initial)
      {
        <%pre_call%>
      }
      else if (0<%helpIf%>)
      {
        <%body%>
      }
      else
      {
        <%pre_call%>
      }
      >>
    case SES_WHEN(whenStmtLst = whenStmtLst, conditions=conditions, elseWhen=SOME(elseWhenEq)) then
       let helpIf = (conditions |> e => ' || (<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%> && !_discrete_events->pre(<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>))')
      let initial_assign =
        if initialCall then
          whenOperators(whenStmtLst, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        else
          preCall(whenStmtLst, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      let body = whenOperators(whenStmtLst, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      let elseWhen = equationElseWhen(elseWhenEq, context, varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      let pre_call = preCall(whenStmtLst, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      <<
      if (<%sysderef%>_initial)
      {
        <%initial_assign%>
      }
      else if(0<%helpIf%>)
      {
        <%body%>
      }
      <%elseWhen%>
      else
      {
       <%pre_call%>
      }
      >>
end equationWhen;


template preCall(list<WhenOperator> whenOps, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                    Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates assignment for when."
::=
  let body = (whenOps |> whenOp =>
    match whenOp
      case e as ASSIGN(left= lhs as DAE.CREF(componentRef = cr)) then
match typeof(e.right)
  case T_ARRAY(dims=dims) then
   let dimensions = checkDimension(dims)
   let i_tmp_var= System.tmpTick()
   let forLoopIteration = preCallForArray(dims,i_tmp_var)
   let forloop = match listLength(dims) case 1 then
   <<
    <%forLoopIteration%>
     <%cref1(cr, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>(i0_<%i_tmp_var%>) = _discrete_events->pre(<%cref1(cr, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>(i0_<%i_tmp_var%>));
   >>
   case 2 then
   <<
     <%forLoopIteration%>
        <%cref1(cr, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>(i0_<%i_tmp_var%>,i1_<%i_tmp_var%>) = _discrete_events->pre(<%cref1(cr, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>(i0_<%i_tmp_var%>,i1_<%i_tmp_var%>));
   >>
   else
    error(sourceInfo(), 'No support for this sort of pre call')
   end match
   forloop
   else
   <<
    <%cref1(cr, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%> = _discrete_events->pre(<%cref1(cr, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>);
   >>
end match
        else
          <<; // nothing to do>>
;separator="\n")
<<
  <%body%>
>>
end preCall;

template preCallForArray(Dimensions dims,String tmp)
::=
  let operatorCall= dims |> dim  hasindex i0   =>
    let dimindex = dimension(dim,contextOther)
  'for(int i<%i0%>_<%tmp%>=1;i<%i0%>_<%tmp%><= <%dimindex%>;++i<%i0%>_<%tmp%>)'
  ;separator="\n\t"
  <<
   <%operatorCall%>
  >>
end preCallForArray;


template whenAssign(ComponentRef left, Type ty, Exp right, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                    Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates assignment for when."
::=
    let &preExp = buffer "" /*BUFD*/
    let exp = daeExp(right, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let lhs = cref1(left, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)
    <<
    <%preExp%>
    <%lhs%> = <%exp%>;
    >>
end whenAssign;

template equationIfEquation(SimEqSystem eq, Context context,Text &varDecls /*BUFP*/, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates an if equation."
::=
match eq
case SES_IFEQUATION(ifbranches=ifbranches, elsebranch=elsebranch) then
  let &preExp = buffer ""
  let IfEquation = (ifbranches |> (e, eqns) hasindex index0 =>
    let condition = daeExp(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let ifequations = (eqns |> eqn =>
      let eqnStr = equation_(eqn, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, &extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      <<
      <%eqnStr%>
      >>
      ; separator="\n")
    let conditionline = if index0 then 'else if(<%condition%>)' else 'if(<%condition%>)'
    <<
    <%conditionline%>
    {
      <%ifequations%>
    }
    >>
    ; separator="\n")
  let elseequations = (elsebranch |> eqn =>
    let eqnStr = equation_(eqn, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, &extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    <<
    <%eqnStr%>
    >>
    ; separator="\n")
  <<
  <%preExp%>
  <%IfEquation%>
  else
  {
    <%elseequations%>
  }
  >>
end equationIfEquation;

template equationElseWhen(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                          Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a else when equation."
::=
let &varDeclsCref = buffer "" /*BUFD*/
match eq
case SES_WHEN(whenStmtLst = whenStmtLst, conditions=conditions, elseWhen=NONE()) then
  let helpIf =  (conditions |> e => ' || (<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%> && !_discrete_events->pre(<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>))')
  let body = whenOperators(whenStmtLst, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  <<
  else if(0<%helpIf%>)
  {
    <%body%>
  }
  >>
case SES_WHEN(whenStmtLst = whenStmtLst, conditions=conditions, elseWhen=SOME(elseWhenEq)) then
  let helpIf = (conditions |> e => ' || (<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%> && !_discrete_events->pre(<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>))')
  let body = whenOperators(whenStmtLst, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let elseWhen = equationElseWhen(elseWhenEq, context, varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  <<
  /else if(0<%helpIf%>)
  {
    <%body%>
  }
  <%elseWhen%>
  >>
end equationElseWhen;

template whenOperators(list<WhenOperator> whenOps, Context context, Text &varDecls /*BUFP*/, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates re-init statement for when equation."
::=
  let body = (whenOps |> whenOp =>
    match whenOp
      case ASSIGN(left = lhs as DAE.CREF(componentRef = left)) then whenAssign(left, typeof(right), right, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      case REINIT(__) then
        let &preExp = buffer "" /*BUFD*/
        let &varDeclsCref = buffer "" /*BUFD*/
        let val = daeExp(value, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        <<
        _state_var_reinitialized = true;
        <%preExp%>
        <%cref1(stateVar,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,contextOther,varDeclsCref,stateDerVectorName,useFlatArrayNotation)%> = <%val%>;
        >>
      case TERMINATE(__) then
        let &preExp = buffer "" /*BUFD*/
        let msgVar = daeExp(message, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        <<
        <%preExp%>
        MODELICA_TERMINATE(<%msgVar%>);
        >>
      case ASSERT(source=SOURCE(info=info)) then
        assertCommon(condition, message,level, contextSimulationDiscrete, &varDecls, info,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      case NORETCALL(__) then
      let &preExp = buffer ""
      let expPart = daeExp(exp, contextSimulationDiscrete, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      <<
      <%preExp%>
      <% if isCIdentifier(expPart) then "" else '<%expPart%>;' %>
      >>
    ;separator="\n")
  <<
  <%body%>
  >>
end whenOperators;

template preCref(ComponentRef cr, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName, Boolean useFlatArrayNotation) ::=
let &varDeclsCref = buffer "" /*BUFD*/
'pre<%representationCref(cr, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>'
end preCref;

template equationSimpleAssign(SimEqSystem eq, Context context,Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,
                              Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Boolean assignToStartValues, Boolean overwriteOldStartValue)
 "Generates an equation that is just a simple assignment."
::=
match eq
case SES_SIMPLE_ASSIGN(__) then
  let &preExp = buffer "" /*BUFD*/
  let startFixedExp = match cref2simvar(cref, simCode)
    case SIMVAR(varKind = CLOCKED_STATE(isStartFixed = true)) then
      "if (_clockStart[clockIndex - 1]) return;"
  let expPart = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)

  match cref
  case CREF_QUAL(ident = "$PRE")  then
    <<
    //<%cref(componentRef, useFlatArrayNotation)%> = <%expPart%>;
    //_discrete_events->save( <%cref(componentRef, useFlatArrayNotation)%>);
    _discrete_events->pre(<%cref(componentRef, useFlatArrayNotation)%>)=<%expPart%>;
    >>
  else
   match exp
  case CREF(ty = t as  T_ARRAY(__)) then
  <<
  //Array assign
  <%cref1(cref, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDecls, stateDerVectorName, useFlatArrayNotation)%> = <%expPart%>;
  >>
  else
  let &assignExp = buffer if(assignToStartValues) then 'SystemDefaultImplementation::set<%crefStartValueType(cref)%>StartValue(' else ''
  let &assignExp += cref1(cref, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)
  let &assignExp += if(assignToStartValues) then ',<%expPart%>,<%overwriteOldStartValue%>);' else ' = <%expPart%>;'
  <<
  <%if not assignToStartValues then '<%startFixedExp%>'%>
  <%preExp%>
  <%assignExp%>
  >>
 end match
end match
end equationSimpleAssign;


template equationLinearOrNonLinear(SimEqSystem eq, Context context,Text &varDecls,
                              SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/)
 "Generates an equations for a linear or non linear system."
::=
  match eq
    case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
      let i = ls.index
      match context
        case  ALGLOOP_CONTEXT(genInitialisation=true) then
           <<
           try
           {
               _algLoopSolver<%ls.index%>->initialize();
               _algLoop<%ls.index%>->evaluate();
               for(int i=0; i<_dimZeroFunc; i++) {
                   getCondition(i);
               }
               IContinuous::UPDATETYPE calltype = _callType;
               _callType = IContinuous::CONTINUOUS;
               _algLoopSolver<%ls.index%>->solve();
               _callType = calltype;
           }
           catch(ModelicaSimulationError&  ex)
           {
                string error = add_error_info("Nonlinear solver stopped",ex.what(),ex.getErrorID(),_simTime);
                throw ModelicaSimulationError(ALGLOOP_EQ_SYSTEM,error);
           }
           >>
        else
          <<
          bool restart<%ls.index%> = true;
          unsigned int iterations<%ls.index%> = 0;
          _algLoop<%ls.index%>->getReal(_algloop<%ls.index%>Vars );
          bool restatDiscrete<%ls.index%>= false;
          IContinuous::UPDATETYPE calltype = _callType;
          try
          {
           if( _callType == IContinuous::DISCRETE )
              {
                  _algLoop<%ls.index%>->evaluate();
                  while(restart<%ls.index%> && !(iterations<%ls.index%>++>500))
                  {
                      getConditions(_conditions0<%ls.index%>);
                      _callType = IContinuous::CONTINUOUS;
                      _algLoopSolver<%ls.index%>->solve();
                      _callType = IContinuous::DISCRETE;
                      for(int i=0;i<_dimZeroFunc;i++)
                      {
                          getCondition(i);
                      }

                      getConditions(_conditions1<%ls.index%>);
                      restart<%ls.index%> = !std::equal (_conditions1<%ls.index%>, _conditions1<%ls.index%>+_dimZeroFunc,_conditions0<%ls.index%>);
                  }
              }
              else
              _algLoopSolver<%ls.index%>->solve();

          }
          catch(ModelicaSimulationError &ex)
          {
               restatDiscrete<%ls.index%>=true;
          }

          if((restart<%ls.index%>&& iterations<%ls.index%> > 0)|| restatDiscrete<%ls.index%>)
          {
              try
              {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
                  _callType = IContinuous::DISCRETE;
                  _algLoop<%ls.index%>->setReal(_algloop<%ls.index%>Vars );
                  _algLoopSolver<%ls.index%>->solve();
                  _callType = calltype;
              }
              catch(ModelicaSimulationError& ex)
              {
                string error = add_error_info("Nonlinear solver <%ls.index%> stopped",ex.what(),ex.getErrorID(),_simTime);
                throw ModelicaSimulationError(ALGLOOP_EQ_SYSTEM,error);
              }

          }


          >>
        end match

    case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
      let i = nls.index
      match context
        case  ALGLOOP_CONTEXT(genInitialisation=true) then
           <<
           try
           {
               _algLoopSolver<%nls.index%>->initialize();
               _algLoop<%nls.index%>->evaluate();
               for(int i=0; i<_dimZeroFunc; i++) {
                   getCondition(i);
               }
               IContinuous::UPDATETYPE calltype = _callType;
               _callType = IContinuous::CONTINUOUS;
               _algLoopSolver<%nls.index%>->solve();
               _callType = calltype;
           }
           catch(ModelicaSimulationError&  ex)
           {
                string error = add_error_info("Nonlinear solver <%nls.index%> stopped",ex.what(),ex.getErrorID(),_simTime);
                throw ModelicaSimulationError(ALGLOOP_EQ_SYSTEM,error);
           }
           >>
        else
          <<
          bool restart<%nls.index%> = true;
          unsigned int iterations<%nls.index%> = 0;
          _algLoop<%nls.index%>->getReal(_algloop<%nls.index%>Vars );
          bool restatDiscrete<%nls.index%>= false;
          IContinuous::UPDATETYPE calltype = _callType;
          try
          {
           if( _callType == IContinuous::DISCRETE )
              {
                  _algLoop<%nls.index%>->evaluate();
                  while(restart<%nls.index%> && !(iterations<%nls.index%>++>500))
                  {
                      getConditions(_conditions0<%nls.index%>);
                      _callType = IContinuous::CONTINUOUS;
                      _algLoopSolver<%nls.index%>->solve();
                      _callType = IContinuous::DISCRETE;
                      for(int i=0;i<_dimZeroFunc;i++)
                      {
                          getCondition(i);
                      }

                      getConditions(_conditions1<%nls.index%>);
                      restart<%nls.index%> = !std::equal (_conditions1<%nls.index%>, _conditions1<%nls.index%>+_dimZeroFunc,_conditions0<%nls.index%>);
                  }
              }
              else
              _algLoopSolver<%nls.index%>->solve();

          }
          catch(ModelicaSimulationError &ex)
          {
               restatDiscrete<%nls.index%>=true;
          }

          if((restart<%nls.index%>&& iterations<%nls.index%> > 0)|| restatDiscrete<%nls.index%>)
          {
              try
              {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
                  _callType = IContinuous::DISCRETE;
                  _algLoop<%nls.index%>->setReal(_algloop<%nls.index%>Vars );
                  _algLoopSolver<%nls.index%>->solve();
                  _callType = calltype;
              }
              catch(ModelicaSimulationError& ex)
              {
                string error = add_error_info("Nonlinear solver <%nls.index%> stopped",ex.what(),ex.getErrorID(),_simTime);
                throw ModelicaSimulationError(ALGLOOP_EQ_SYSTEM,error);
              }

          }


          >>
        end match
  end match
end equationLinearOrNonLinear;


template equationForLoop(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match eq
    case SES_FOR_LOOP(__) then
      let &preExp = buffer ""
      let iterExp = daeExp(iter, context, preExp, varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, false)
      let startExp = daeExp(startIt, context, preExp, varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, false)
      let endExp = daeExp(endIt, context, preExp, varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, false)
      let expPart = daeExp(exp, context, preExp, varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, false)
      let crefPart = daeExp(crefExp(cref), context, preExp, varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, false)
      let crefWithIdx = crefWithIndex(cref, context, varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName /*=__zDot*/, useFlatArrayNotation)
      let lhs = getLHS(cref, startExp, useFlatArrayNotation)
      <<
      <%preExp%>
      //double *result = &<%cref(cref, false)%>[0];
      double *result = &<%lhs%>;
      for(int <%iterExp%> = <%startExp%>; <%iterExp%> != <%endExp%>+1; <%iterExp%>++)
        result[i] = <%expPart%>;
      >>
end equationForLoop;


template getLHS(ComponentRef cr, Text startExp, Boolean useFlatArrayNotation)
 "Returns the left hand side of a for loop with the right var index, e.g., _resistor1_P_i.
  Assumption: lhs = 'cref' + 'startIndex of for loop'."
::=
  match cr
    case CREF_QUAL(__) then
      //"_" + '<%ident%><%startExp%><%subscriptsToCStrForArray(subscriptLst)%>_P_<%crefToCStr(componentRef,useFlatArrayNotation)%>'
      "_" + '<%crefAppendedSubs(cr)%>'
    else "CREF_NOT_QUAL"
  end match
end getLHS;





template testDaeDimensionExp(Exp exp)
 "Generates code for an expression."
::=
  match exp
  case e as ICONST(__)          then ''
  case e as RCONST(__)          then '-1'
  case e as BCONST(__)          then '-1'
  case e as ENUM_LITERAL(__)    then '-1'
  case e as CREF(__)            then '-1'
  case e as CAST(__)            then '-1'
  case e as CONS(__)            then '-1'
  case e as SCONST(__)          then '-1'
  case e as UNARY(__)           then '-1'
  case e as LBINARY(__)         then '-1'
  case e as LUNARY(__)          then '-1'
  case e as BINARY(__)          then '-1'
  case e as IFEXP(__)           then '-1'
  case e as RELATION(__)        then '-1'
  case e as CALL(__)            then '-1'
  case e as RECORD(__)          then '-1'
  case e as ASUB(__)            then '-1'
  case e as MATRIX(__)          then '-1'
  case e as RANGE(__)           then '-1'
  case e as ASUB(__)            then '-1'
  case e as TSUB(__)            then '-1'
  case e as REDUCTION(__)       then '-1'
  case e as ARRAY(__)           then '-1'
  case e as SIZE(__)            then '-1'
  case e as SHARED_LITERAL(__)  then '-1'
  else '-1'
end testDaeDimensionExp;

template assertCommon(Exp condition, Exp message,Exp level, Context context, Text &varDecls, builtin.SourceInfo info, SimCode simCode,
                      Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let &preExpCond = buffer ""
  let &preExpMsg = buffer ""
  let condVar = daeExp(condition, context, &preExpCond, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let msgVar = daeExp(message, context, &preExpMsg, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
/* <<
  <%preExpCond%>
  if (!<%condVar%>) {
    <%preExpMsg%>
    omc_fileInfo info = {<%infoArgs(info)%>};
    MODELICA_ASSERT(info, <%if acceptMetaModelicaGrammar() then 'MMC_STRINGDATA(<%msgVar%>)' else msgVar%>);
  }
  >>
  */
  <<

  <%if msgVar then
      <<
       <%preExpCond%>
       if(!<%condVar%>)
       {
         <%preExpMsg%>
          <%match level case ENUM_LITERAL(index=2)
          then 'cerr <<"Warning: " << <%msgVar%>;'
          else
          'throw ModelicaSimulationError(MODEL_EQ_SYSTEM,<%msgVar%>);'
          %>

       }
      >>
      else
      <<
      if(!<%condVar%>)
      {
        <%preExpCond%>
        <%preExpMsg%>
        <%match level case ENUM_LITERAL(index=2)
         then 'cerr <<"Warning: >Assert in model equation";'
         else  'throw ModelicaSimulationError() << error_id(MODEL_EQ_SYSTEM);'
        %>
      }
      >>
   %>
  >>

end assertCommon;

template infoArgs(builtin.SourceInfo info)
::=
  match info
  case SOURCEINFO(__) then '"<%fileName%>",<%lineNumberStart%>,<%columnNumberStart%>,<%lineNumberEnd%>,<%columnNumberEnd%>,<%isReadOnly%>'
end infoArgs;


template underscorePrefix(Boolean builtin) ::=
  match builtin
  case true then ""
  case false then "_"
end underscorePrefix;



template functionBlock(SimCode simCode)
::=
let  inputVars = spsInputVars(simCode)
let outputVars = spsOutputVars(simCode)
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
let modelname = identOfPath(modelInfo.name)
'<?xml version="1.0" encoding="utf-8"?>
<project xmlns="http://www.plcopen.org/xml/tc6_0200">
  <fileHeader companyName="" productName="IndraLogic" productVersion="indralogic" creationDateTime="2015-11-19T11:21:48.0837805" />
  <contentHeader name="<%modelname%>">
    <coordinateInfo>
      <fbd>
        <scaling x="1" y="1" />
      </fbd>
      <ld>
        <scaling x="1" y="1" />
      </ld>
      <sfc>
        <scaling x="1" y="1" />
      </sfc>
    </coordinateInfo>
    <addData>
      <data name="http://www.3s-software.com/plcopenxml/projectinformation" handleUnknown="implementation">
        <ProjectInformation />
      </data>
    </addData>
  </contentHeader>
  <types>
    <dataTypes />
    <pous>
      <pou name="<%modelname%>" pouType="functionBlock">
        <interface>
          <inputVars>
            <%inputVars%>
          </inputVars>
          <outputVars>
            <%outputVars%>
          </outputVars>
          <localVars>
            <variable name="cycletime">
              <type>
                <LREAL />
              </type>
              <initialValue>
                <simpleValue value="0.004" />
              </initialValue>
            </variable>
            <variable name="bAlreadyInitialized">
              <type>
                <BOOL />
              </type>
            </variable>
            <variable name="bErrorOccured">
              <type>
                <BOOL />
              </type>
            </variable>
            <variable name="controller">
              <type>
                <DWORD />
              </type>
            </variable>
            <variable name="simdata">
              <type>
                <DWORD />
              </type>
            </variable>
          </localVars>
        </interface>
        <body>
          <ST>
            <xhtml xmlns="http://www.w3.org/1999/xhtml" />
          </ST>
        </body>
        <addData>
          <data name="http://www.3s-software.com/plcopenxml/method" handleUnknown="implementation">
            <Method name="FB_Init" ObjectId="102788a9-c3a0-4650-9ee8-e340b376c772">
              <interface>
                <returnType>
                  <BOOL />
                </returnType>
                <inputVars>
                  <variable name="bInitRetains">
                    <type>
                      <BOOL />
                    </type>
                  </variable>
                  <variable name="bInCopyCode">
                    <type>
                      <BOOL />
                    </type>
                  </variable>
                </inputVars>
                <addData>
                  <data name="http://www.3s-software.com/plcopenxml/attributes" handleUnknown="implementation">
                    <Attributes>
                      <Attribute Name="object_name" Value="FB_Init" />
                    </Attributes>
                  </data>
                </addData>
              </interface>
              <body>
                <ST>
                  <xhtml xmlns="http://www.w3.org/1999/xhtml" />
                </ST>
              </body>
              <BuildProperties>
                <ExternalImplementation>true</ExternalImplementation>
              </BuildProperties>
              <addData />
            </Method>
          </data>
          <data name="http://www.3s-software.com/plcopenxml/method" handleUnknown="implementation">
            <Method name="FB_Reinit" ObjectId="a9db0581-3a33-4426-9a31-453930d13eb7">
              <interface>
                <returnType>
                  <BOOL />
                </returnType>
                <addData>
                  <data name="http://www.3s-software.com/plcopenxml/attributes" handleUnknown="implementation">
                    <Attributes>
                      <Attribute Name="object_name" Value="FB_Reinit" />
                    </Attributes>
                  </data>
                </addData>
              </interface>
              <body>
                <ST>
                  <xhtml xmlns="http://www.w3.org/1999/xhtml" />
                </ST>
              </body>
              <BuildProperties>
                <ExternalImplementation>true</ExternalImplementation>
              </BuildProperties>
              <addData />
            </Method>
          </data>
          <data name="http://www.3s-software.com/plcopenxml/method" handleUnknown="implementation">
            <Method name="FB_Exit" ObjectId="c3ba1a8d-f305-4c9b-a3bf-e0c31a544d79">
              <interface>
                <returnType>
                  <BOOL />
                </returnType>
                <inputVars>
                  <variable name="bInCopyCode">
                    <type>
                      <BOOL />
                    </type>
                  </variable>
                </inputVars>
                <addData>
                  <data name="http://www.3s-software.com/plcopenxml/attributes" handleUnknown="implementation">
                    <Attributes>
                      <Attribute Name="object_name" Value="FB_Exit" />
                    </Attributes>
                  </data>
                </addData>
              </interface>
              <body>
                <ST>
                  <xhtml xmlns="http://www.w3.org/1999/xhtml" />
                </ST>
              </body>
              <BuildProperties>
                <ExternalImplementation>true</ExternalImplementation>
              </BuildProperties>
              <addData />
            </Method>
          </data>
          <data name="http://www.3s-software.com/plcopenxml/buildproperties" handleUnknown="implementation">
            <BuildProperties>
              <ExternalImplementation>true</ExternalImplementation>
            </BuildProperties>
          </data>
          <data name="http://www.3s-software.com/plcopenxml/objectid" handleUnknown="discard">
            <ObjectId>33609c54-38cc-4f33-9fa0-93f0a8b3a3b3</ObjectId>
          </data>
        </addData>
      </pou>
    </pous>
  </types>
  <instances>
    <configurations />
  </instances>
  <addData>
    <data name="http://www.3s-software.com/plcopenxml/projectstructure" handleUnknown="discard">
      <ProjectStructure>
        <Object Name="PController" ObjectId="33609c54-38cc-4f33-9fa0-93f0a8b3a3b3">
          <Object Name="FB_Init" ObjectId="102788a9-c3a0-4650-9ee8-e340b376c772" />
          <Object Name="FB_Reinit" ObjectId="a9db0581-3a33-4426-9a31-453930d13eb7" />
          <Object Name="FB_Exit" s="c3ba1a8d-f305-4c9b-a3bf-e0c31a544d79" />
        </Object>
      </ProjectStructure>
    </data>
  </addData>
</project>
'
end functionBlock;

template mlpiStructs(SimCode simCode)
::=
let  inputVars = mlpiInputVars(simCode)
let outputVars = mlpiOutputVars(simCode)
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
let modelname = identOfPath(modelInfo.name)
'
typedef struct <%modelname%>_struct
{
  void* __VFTABLEPOINTER;
  <%inputVars%>
  <%outputVars%>
  MLPI_IEC_LREAL cycletime;
  MLPI_IEC_BOOL bAlreadyInitialized;
  MLPI_IEC_BOOL bErrorOccured;
  ISimController* controller;
  ISimData* simdata;
}<%modelname%>_struct;

typedef struct <%modelname%>_Main_struct
{
  <%modelname%>_struct* instance; // Declaration of instance pointer
}<%modelname%>_Main_struct;

typedef struct <%modelname%>_FB_Init_struct
{
  <%modelname%>_struct* instance; // Declaration of instance pointer
  MLPI_IEC_BOOL bInitRetains; // Declaration of predefined method input (no matter if using BOOL8)
  MLPI_IEC_BOOL bInCopyCode; // Declaration of predefined method input (no matter if using BOOL8)
  MLPI_IEC_BOOL FB_Init; // Declaration of implicit method output (no matter if using BOOL8)
}<%modelname%>_FB_Init_struct;

typedef struct <%modelname%>_FB_Reinit_struct
{
  <%modelname%>_struct* instance; // Declaration of instance pointer
  MLPI_IEC_BOOL FB_Reinit; // Declaration of implicit method output (no matter if using BOOL8)
}<%modelname%>_FB_Reinit_struct;


typedef struct <%modelname%>_FB_Exit_struct
{
  <%modelname%>_struct* instance; // Declaration of instance pointer
  MLPI_IEC_BOOL bInCopyCode; // Declaration of predefined method input (no matter if using BOOL8)
  MLPI_IEC_BOOL FB_Exit; // Declaration of implicit method output (no matter if using BOOL8)
}<%modelname%>_FB_Exit_struct;
'
end mlpiStructs;



template ftp_script(SimCode simCode)
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__)) then
'
echo option confirm off >> script.tmp
echo open ftp:username:password@ip_address >> script.tmp
echo cd "SYSTEM/bundles"  >> script.tmp
echo rm com.boschrexroth.<%fileNamePrefix%> >> script.tmp
echo mkdir com.boschrexroth.<%fileNamePrefix%> >> script.tmp
echo cd com.boschrexroth.<%fileNamePrefix%> >> script.tmp
echo put "com.boschrexroth.<%fileNamePrefix%>\Debug\com.boschrexroth.<%fileNamePrefix%>.out" >> script.tmp
echo exit >> script.tmp
"C:\Program Files (x86)\WINSCP\WinSCP.com" /script=script.tmp
del script.tmp
'
end ftp_script;


template helpvarlength(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match simCode
case SIMCODE(__) then
  <<
  0
  >>
end helpvarlength;


template dimZeroFunc(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
  int <%lastIdentOfPath(modelInfo.name)%>::getDimZeroFunc()
  {
    return _dimZeroFunc;
  }
  int <%lastIdentOfPath(modelInfo.name)%>::getDimClock()
  {
    return _dimClock;
  }
  >>
end dimZeroFunc;


template setIntialStatus(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
   <<
   void <%lastIdentOfPath(modelInfo.name)%>Initialize::setInitial(bool status)
   {
     _initial = status;
     if(_initial)
       _callType = IContinuous::DISCRETE;
     else
       _callType = IContinuous::CONTINUOUS;
   }
   >>
end setIntialStatus;

template getIntialStatus(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
  bool <%lastIdentOfPath(modelInfo.name)%>Initialize::initial()
  {
    return _initial;
  }
  >>
end getIntialStatus;








template functionOnlyZeroCrossing(list<ZeroCrossing> zeroCrossings,Text& varDecls,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
  "Generates function in simulation file."
::=

  let zeroCrossingsCode = zeroCrossingsTpl2(zeroCrossings, &varDecls /*BUFD*/, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
  <<
  <%zeroCrossingsCode%>
  >>
end functionOnlyZeroCrossing;


template zeroCrossingsTpl2(list<ZeroCrossing> zeroCrossings, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates code for zero crossings."
::=

  (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 =>
    zeroCrossingTpl2(i0, relation_, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
  ;separator="\n";empty)
end zeroCrossingsTpl2;


template zeroCrossingTpl2(Integer index1, Exp relation, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates code for a zero crossing."
::=
  match relation
  case RELATION(index=zerocrossingIndex) then
    <<
    checkConditions(<%zerocrossingIndex%>,false);
    >>
end zeroCrossingTpl2;


template literalExpConst(Exp lit, Integer index) "These should all be declared static X const"
::=
  let name = '_OMC_LIT<%index%>'
  let tmp = '_OMC_LIT_STRUCT<%index%>'
  let meta = 'static modelica_metatype const <%name%>'

  match lit
  case SCONST(__) then

      <<
       string <%name%>;
      >>
  case lit as MATRIX(ty=ty as T_ARRAY(__))
  case lit as ARRAY(ty=ty as T_ARRAY(__)) then
    /*<< previous multi_array
     multi_array<<%expTypeShort(ty)%>,<%listLength(ty.dims)%>> <%name%>;
    >>*/
    <<
     StatArrayDim<%listLength(ty.dims)%><<%expTypeShort(ty)%>,<%(ty.dims |> dim as DIM_INTEGER(integer=i)  =>  '<%i%>';separator=",")%> > <%name%>;
    >>
  case BOX(exp=exp as RCONST(__)) then
    <<
    double <%name%>;
    >>
  else error(sourceInfo(), 'literalExpConst failed: <%ExpressionDumpTpl.dumpExp(lit,"\"")%>')
end literalExpConst;

template literalExpConstArrayVal(Exp lit)
::=
  match lit
  case ICONST(__) then integer
  case lit as BCONST(__) then if lit.bool then 1 else 0
  case RCONST(__) then real
  case ENUM_LITERAL(__) then index
  case lit as SHARED_LITERAL(__) then '_OMC_LIT<%lit.index%>'
  else error(sourceInfo(), 'literalExpConstArrayVal failed: <%ExpressionDumpTpl.dumpExp(lit,"\"")%>')
end literalExpConstArrayVal;

template literalExpConstImpl(Exp lit, Integer index) "These should all be declared static X const"
::=
  let name = '_OMC_LIT<%index%>'
  let tmp = '_OMC_LIT_STRUCT<%index%>'
  let meta = 'static modelica_metatype const <%name%>'

  match lit
  case SCONST(__) then
    let escstr = Util.escapeModelicaStringToCString(string)
      <<
        <%name%> = "<%escstr%>";
      >>
  case lit as MATRIX(ty=ty as T_ARRAY(__))
  case lit as ARRAY(ty=ty as T_ARRAY(__)) then
    let size = listLength(flattenArrayExpToList(lit))
    let ndim = listLength(ty.dims)
    let arrayTypeStr = expTypeShort(ty)
    let dims = (ty.dims |> dim => dimension(dim,contextOther) ;separator=", ")
    let instDimsInit = (ty.dims |> exp =>
     dimension(exp,contextOther);separator="][")
    let data = flattenArrayExpToList(lit) |> exp => literalExpConstArrayVal(exp) ; separator=", "
    match listLength(flattenArrayExpToList(lit))
    case 0 then ""
    else
  /*<< previous multi_array
      <%name%>.resize((boost::extents[<%instDimsInit%>]));
      <%name%>.reindex(1);
      <%arrayTypeStr%> <%name%>_data[]={<%data%>};
    //test2
       <%name%>.assign(<%name%>_data,<%name%>_data+<%size%>);
    >>*/
    <<
    //arrayflats
    <%arrayTypeStr%> <%name%>_data[] = {<%data%>};
    assignRowMajorData(<%name%>_data, <%name%>);
    >>
  case BOX(exp=exp as RCONST(__)) then
    <<
    <%name%> = <%exp.real%>;
    >>
  else error(sourceInfo(), 'literalExpConst failed: <%ExpressionDumpTpl.dumpExp(lit,"\"")%>')
end literalExpConstImpl;

template handleEvent(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match simCode
case SIMCODE(__) then
  <<
  >>
end handleEvent;

template checkConditions(list<ZeroCrossing> zeroCrossings, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let zeroCrossingsCode = checkConditions1(zeroCrossings, &varDecls /*BUFD*/, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
   <<
   bool <%lastIdentOfPath(modelInfo.name)%>::checkConditions()
   {
     _callType = IContinuous::DISCRETE;
      return _event_handling->checkConditions(0,true);
     _callType = IContinuous::CONTINUOUS;
   }
   >>
end checkConditions;


template getCondition(list<ZeroCrossing> zeroCrossings, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let zeroCrossingsCode = checkConditions1(zeroCrossings, &varDecls /*BUFD*/, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match zeroCrossings
    case {} then
      match simCode
        case SIMCODE(modelInfo = MODELINFO(__)) then
        <<
        bool <%lastIdentOfPath(modelInfo.name)%>::getCondition(unsigned int index)
        {
          return false;
        }
        >>
      end match
    else
      match simCode
        case SIMCODE(modelInfo = MODELINFO(__)) then
        <<
        bool <%lastIdentOfPath(modelInfo.name)%>::getCondition(unsigned int index)
        {
          <%varDecls%>
          switch(index)
          {
            <%zeroCrossingsCode%>
            default:
            {
              string error = string("Wrong condition index ") + to_string(index);
              throw ModelicaSimulationError(EVENT_HANDLING, error);
            }
          };
        }
        >>
      end match
end getCondition;

template checkConditions1(list<ZeroCrossing> zeroCrossings, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=

  (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 =>
    checkConditions2(i0, relation_, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  ;separator="\n";empty)
end checkConditions1;

template checkConditions2(Integer index1, Exp relation, Text &varDecls, SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match relation
  case RELATION(index=zerocrossingIndex) then
    let &preExp = buffer "" /*BUFD*/
    let e1 = daeExp(exp1, contextOther, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let op = zeroCrossingOpFunc(operator)
    let e2 = daeExp(exp2, contextOther, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let res = tempDecl("bool", &varDecls /*BUFC*/)
    <<
    case <%zerocrossingIndex%>:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           <%preExp%>
           <%res%>=(<%e1%><%op%><%e2%>);
           _conditions[<%zerocrossingIndex%>]=<%res%>;
           return <%res%>;
       }
       else
           return _conditions[<%zerocrossingIndex%>];
    }
    >>

end checkConditions2;

template handleSystemEvents(list<ZeroCrossing> zeroCrossings, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=

  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
  bool <%lastIdentOfPath(modelInfo.name)%>Mixed::handleSystemEvents(bool* events)
  {
    _callType = IContinuous::DISCRETE;

    bool restart = true;
    bool state_vars_reinitialized = false;
    bool clock_event_detected = false;

    int iter = 0;
    while(restart && !(iter++ > 100))
    {
        bool st_vars_reinit = false;
        //iterate and handle all events inside the eventqueue
        restart = _event_handling->startEventIteration(st_vars_reinit);
        state_vars_reinitialized = state_vars_reinitialized || st_vars_reinit;

        saveAll();
    }

    if (iter > 100 && restart) {
      string error = string("Number of event iteration steps exceeded at time: ") + to_string(_simTime);
      throw ModelicaSimulationError(EVENT_HANDLING, error);
    }
    _callType = IContinuous::CONTINUOUS;

    return state_vars_reinitialized;
  }
  >>
end handleSystemEvents;

template zeroCrossingOpFunc(Operator op)
 "Generates zero crossing function name for operator."
::=
  match op
  case LESS(__)      then "<"
  case GREATER(__)   then ">"
  case LESSEQ(__)    then "<="
  case GREATEREQ(__) then ">="
  case EQUAL(__)     then "=="
  case NEQUAL(__)    then "!="
end zeroCrossingOpFunc;

template giveZeroFunc1(list<ZeroCrossing> zeroCrossings,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let &prexp = buffer "" /*BUFD*/
  let zeroCrossingsCode = giveZeroFunc2(zeroCrossings, &varDecls /*BUFD*/,prexp, simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
 <<
 void <%lastIdentOfPath(modelInfo.name)%>::getZeroFunc(double* f)
 {
   <%varDecls%>
   <%prexp%>
   <%zeroCrossingsCode%>


 }
 >>
end giveZeroFunc1;

template setConditions(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
 match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
 <<
 void <%lastIdentOfPath(modelInfo.name)%>::setConditions(bool* c)
 {
   SystemDefaultImplementation::setConditions(c);
 }
 >>
end setConditions;

template getConditions(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
 match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
 <<
 void <%lastIdentOfPath(modelInfo.name)%>::getConditions(bool* c)
 {
     SystemDefaultImplementation::getConditions(c);
 }
 void <%lastIdentOfPath(modelInfo.name)%>::getClockConditions(bool* c)
 {
     SystemDefaultImplementation::getClockConditions(c);
 }
 >>
end getConditions;

template isConsistent(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
 match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
<<
bool <%lastIdentOfPath(modelInfo.name)%>::isConsistent()
{
  return SystemDefaultImplementation::isConsistent();
}
>>
end isConsistent;

template saveConditions(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
 match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
<<
void <%lastIdentOfPath(modelInfo.name)%>::saveConditions()
{
  SystemDefaultImplementation::saveConditions();
}
>>
end saveConditions;

template giveZeroFunc2(list<ZeroCrossing> zeroCrossings, Text &varDecls /*BUFP*/,Text &preExp,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=

  (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 =>
    giveZeroFunc3(i0, relation_, &varDecls /*BUFD*/,&preExp,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  ;separator="\n";empty)
end giveZeroFunc2;

template giveZeroFunc3(Integer index1, Exp relation, Text &varDecls /*BUFP*/,Text &preExp ,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=

  match relation
  case rel as  RELATION(index=zerocrossingIndex) then
      let e1 = daeExp(exp1, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      let e2 = daeExp(exp2, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      match rel.operator

      case LESS(__) then
        <<
        if(_conditions[<%zerocrossingIndex%>])
            f[<%index1%>]=(<%e1%> - 1e-9 - <%e2%>);
        else
            f[<%index1%>]=(<%e2%> - <%e1%> -  1e-9);
        >>
      case LESSEQ(__) then
        <<
        if(_conditions[<%zerocrossingIndex%>])
            f[<%index1%>] = (<%e1%> - 1e-9 - <%e2%>);
        else
            f[<%index1%>] = (<%e2%> - <%e1%> - 1e-9);
        >>
      case GREATER(__) then
        <<
        if(_conditions[<%zerocrossingIndex%>])
            f[<%index1%>] = (<%e2%> - <%e1%> - 1e-9);
        else
            f[<%index1%>] = (<%e1%> - 1e-9 - <%e2%>);
        >>
      case GREATEREQ(__) then
        <<
        if(_conditions[<%zerocrossingIndex%>])
            f[<%index1%>] = (<%e2%> - <%e1%> - 1e-9);
        else
            f[<%index1%>] = (<%e1%> - 1e-9 - <%e2%>);
        >>
    else
        <<
        f[<%index1%>] = -1;
        /*error(sourceInfo(), 'Unknown relation: <%ExpressionDumpTpl.dumpExp(rel,"\"")%> for <%index1%>')*/
        >>
      end match
  case CALL(path=IDENT(name="sample"), expLst={_, start, interval}) then
    //error(sourceInfo(), ' sample not supported for <%index1%> ')
    '//sample for <%index1%>'
  else
    error(sourceInfo(), ' UNKNOWN ZERO CROSSING for <%index1%> ')
  end match
end giveZeroFunc3;

template conditionvarZero(list<ZeroCrossing> zeroCrossings,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 =>
    conditionvarZero1(i0, relation_, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
  ;separator="\n";empty)
end conditionvarZero;

template conditionvarZero1(Integer index1, Exp relation,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  match relation
  case RELATION(index=zerocrossingIndex) then
    <<
    bool _condition<%zerocrossingIndex%>;
    >>
end conditionvarZero1;

template saveconditionvar(list<ZeroCrossing> zeroCrossings,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 =>
    saveconditionvar1(i0, relation_, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
  ;separator="\n";empty)
end saveconditionvar;

template saveconditionvar1(Integer index1, Exp relation,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  match relation
  case RELATION(index=zerocrossingIndex) then
    <<
    _discrete_events->save(_condition<%zerocrossingIndex%>);
    >>
end saveconditionvar1;




template conditionvarSample1(Integer index1, Exp relation, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  match relation
  case CALL(path=IDENT(name="sample"), expLst={ICONST(integer=index), start, interval}) then
    let &preExp = buffer "" /*BUFD*/
     <<
     bool _condition<%intSub(index, 1)%>;
     >>
end conditionvarSample1;

template conditionvariable(list<ZeroCrossing> zeroCrossings,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  let conditionvariable = conditionvarZero(zeroCrossings,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
  /*
  <<
   <%conditionvariable%>
  >>
  */
  <<
  >>
end conditionvariable;



template checkForDiscreteEvents(list<ComponentRef> discreteModelVars,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/,Boolean useFlatArrayNotation)
::=
   let &preExp = buffer ""
  let &varDecls = buffer ""
  let changediscreteVars = (discreteModelVars |> var => match var case CREF_QUAL(__) case CREF_IDENT(__) then
       'if (_discrete_events->changeDiscreteVar(<%cref(var, useFlatArrayNotation)%>)) {  return true; }'
       ;separator="\n")
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
  bool <%lastIdentOfPath(modelInfo.name)%>::checkForDiscreteEvents()
  {
    <%varDecls%>
    <%preExp%>
    <%changediscreteVars%>
    return false;
  }
  >>
end checkForDiscreteEvents;


template equationFunctions(list<SimEqSystem> allEquationsPlusWhen, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Boolean enableMeasureTime)
::=
  let equation_func_calls = (allEquationsPlusWhen |> eq =>
                    equation_function_create_single_func(eq, context/*BUFC*/, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,"evaluate","", stateDerVectorName, useFlatArrayNotation,enableMeasureTime,false,false, "")
                    ;separator="\n")
  <<
  <%equation_func_calls%>
  >>
end equationFunctions;

template clockedFunctions(list<SubPartition> subPartitions,  SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Boolean enableMeasureTime)
 "Evaluate clocked synchronous equations"
::=
  let className = lastIdentOfPathFromSimCode(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)


  let parts = subPartitions |> subPartition hasindex i fromindex 1 =>
    match subPartition
      case SUBPARTITION(__) then
        clockedPartFunctions(i, vars, listAppend(equations, removedEquations), simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextSimulationDiscrete, stateDerVectorName, useFlatArrayNotation, enableMeasureTime)
    ; separator = "\n"





  let cases = subPartitions |> subPartition hasindex i fromindex 1 =>
    <<
    case <%i%>:
      evaluateClocked<%i%>(IContinuous::UNDEF_UPDATE);
      break;
    >>; separator = "\n"
  <<

  <%parts%>

  /* Clocked synchronous equations */
  void <%className%>::evaluateClocked(int index)
  {
    switch (index) {
      <%cases%>
      default:
        throw ModelicaSimulationError(MODEL_EQ_SYSTEM, "Unknown partition");
        break;
    }
  }
  >>
end clockedFunctions;

template clockedPartFunctions(Integer i, list<tuple<SimCodeVar.SimVar, Boolean>> vars, list<SimEqSystem> equations,SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Boolean enableMeasureTime)
 "Evaluate functions that belong to a clocked partition"
::=
  let className = lastIdentOfPathFromSimCode(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)
  let funcs = equations |> eq =>
    equation_function_create_single_func(eq, context/*BUFC*/, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, "evaluate", "", stateDerVectorName, useFlatArrayNotation, enableMeasureTime, false, false, 'const int clockIndex = <%i%>;<%\n%>')
    ; separator="\n"
  let funcName = 'evaluateClocked<%i%>'
  let funcCalls = (List.partition(equations, 100) |> eqs hasindex i0 =>
                   createEvaluateWithSplit(i0, context, eqs, funcName,"evaluate", className, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)
                   ; separator="\n")
  let idx = intAdd(i, -1)
  <<
  <%funcs%>

  void <%className%>::<%funcName%>(const UPDATETYPE command)
  {
    if (_simTime > _clockTime[<%idx%>]) {
      _clockStart[<%idx%>] = false;
    }
    <%funcCalls%>
    if (_simTime > _clockTime[<%idx%>]) {
      _clockInterval[<%idx%>] = _simTime - _clockTime[<%idx%>];
      _clockTime[<%idx%>] = _simTime;
    }
  }
  >>
end clockedPartFunctions;

template createEvaluateAll( list<SimEqSystem> allEquationsPlusWhen, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Boolean createMeasureTime)
::=
  let className = lastIdentOfPathFromSimCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)

  let equation_all_func_calls = (List.partition(allEquationsPlusWhen, 100) |> eqs hasindex i0 =>
                                 createEvaluateWithSplit(i0, context, eqs, "evaluateAll","evaluate", className, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)
                                 ;separator="\n")

  <<
  bool <%className%>::evaluateAll(const UPDATETYPE command)
  {
    <%if createMeasureTime then generateMeasureTimeStartCode("measuredFunctionStartValues", "evaluateAll", "MEASURETIME_MODELFUNCTIONS") else ""%>

    <%createTimeConditionTreatments(timeEventLength(simCode))%>

    // Evaluate Equations
    <%equation_all_func_calls%>

    <%if createMeasureTime then generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "(*measureTimeFunctionsArray)[1]", "evaluateAll", "MEASURETIME_MODELFUNCTIONS") else ""%>

    return _state_var_reinitialized;
  }
  >>
end createEvaluateAll;

template createTimeConditionTreatments(String numberOfTimeEvents)
::=
  <<

  // treatment of clocks in model as time events
  for (int i = <%numberOfTimeEvents%>; i < _dimTimeEvent; i++) {
    if (_time_conditions[i]) {
      evaluateClocked(i - <%numberOfTimeEvents%> + 1);
      _time_conditions[i] = false; // reset clock after one evaluation

    }
  }
  >>
end createTimeConditionTreatments;

template createEvaluateConditions( list<SimEqSystem> allEquationsPlusWhen, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let className = lastIdentOfPathFromSimCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
  let &varDecls = buffer "" /*BUFD*/

  let &eqfuncs = buffer ""
  let equation_all_func_calls = (allEquationsPlusWhen |> eq  =>
                    equation_function_call(eq,  context, &varDecls /*BUFC*/, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,"evaluate")
                    ;separator="\n")

  <<
  bool <%className%>::evaluateConditions(const UPDATETYPE command)
  {
    return evaluateAll(command);
  }
  >>
end createEvaluateConditions;

template createEvaluate(list<list<SimEqSystem>> odeEquations, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Boolean createMeasureTime)
::=
  match simCode
  case SIMCODE(partitionData = PARTITIONDATA(partitions = partitions, activatorsForPartitions=activatorsForPartitions)) then
//case MODELINFO(vars = vars as SIMVARS(__))
  let className = lastIdentOfPathFromSimCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
  let &varDecls = buffer "" /*BUFD*/

  let equation_ode_func_calls = if not Flags.isSet(Flags.MULTIRATE_PARTITION) then (List.partition(List.flatten(odeEquations), 100) |> eqs hasindex i0 =>
                                 createEvaluateWithSplit(i0, context, eqs, "evaluateODE", "evaluate",className, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)
                                 ;separator="\n")
                else ( List.intRange(partitionData.numPartitions) |> partIdx =>
                createEvaluatePartitions(partIdx, context, List.flatten(odeEquations), listGet(partitions, partIdx),
                listGet(activatorsForPartitions,partIdx), className,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace) ;separator="\n")
  <<
  void <%className%>::evaluateODE(const UPDATETYPE command)
  {
    <%if createMeasureTime then generateMeasureTimeStartCode("measuredFunctionStartValues", "evaluateODE", "MEASURETIME_MODELFUNCTIONS") else ""%>
    <%varDecls%>
    // Evaluate Equations
    <%equation_ode_func_calls%>
    <%if createMeasureTime then generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "(*measureTimeFunctionsArray)[0]", "evaluateODE", "MEASURETIME_MODELFUNCTIONS") else ""%>
  }
  >>
end createEvaluate;

template createEvaluatePartitions(Integer partIdx, Context context, list<SimEqSystem> odeEquations, list<Integer> partition, list<Integer> activators, String className, SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  let &varDecls = buffer "" /*BUFD*/
  let condition = partitionCondition(activators)
  let equation_func_calls = (SimCodeUtil.getSimEqSystemsByIndexLst(partition,odeEquations) |> eq  =>
                    equation_function_call(eq, context, &varDecls /*BUFC*/, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, "evaluate")
                    ;separator="\n")
<<
// Partition <%partIdx%>
if (<%condition%>)
{
    <%varDecls%>
    <%equation_func_calls%>
}
>>
end createEvaluatePartitions;

template partitionCondition(list<Integer> partitions)
::=
let bVec = (partitions |> part =>  "_partitionActivation[" + intSub(part,1) + "]" ;separator=" || ")
<<
<%bVec%>
>>
end partitionCondition;

template createEvaluateZeroFuncs( list<SimEqSystem> equationsForZeroCrossings, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context)
::=
  let className = lastIdentOfPathFromSimCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
  let &varDecls = buffer "" /*BUFD*/

  let &eqfuncs = buffer ""
  let equation_zero_func_calls = (List.partition(equationsForZeroCrossings, 100) |> eqs hasindex i0 =>
                    createEvaluateWithSplit(i0, context, eqs, "evaluateZeroFuncs","evaluate", className, simCode, &extraFuncs , &extraFuncsDecl, extraFuncsNamespace)
                    ;separator="\n")

  <<
  void <%className%>::evaluateZeroFuncs(const UPDATETYPE command)
  {
    <%varDecls%>
    // Evaluate Equations
    <%equation_zero_func_calls%>
  }
  >>
end createEvaluateZeroFuncs;

template createEvaluateWithSplit(Integer sectionIndex, Context context, list<SimEqSystem> sectionEquations, String functionName,String functionCallName, String className, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  let &varDecls = buffer "" /*BUFD*/
  let equation_func_calls = (sectionEquations |> eq  =>
                    equation_function_call(eq, context, &varDecls /*BUFC*/, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace,functionCallName)
                    ;separator="\n")
  let &extraFuncs +=
  <<
  <%\n%>void <%className%>::<%functionName%>_<%sectionIndex%>(const UPDATETYPE command)
  {
    <%varDecls%>

    <%equation_func_calls%>
  }
  >>
  let &extraFuncsDecl +=
  <<
  void <%functionName%>_<%sectionIndex%>(const UPDATETYPE command);<%\n%>
  >>
  <<
  <%functionName%>_<%sectionIndex%>(command);
  >>
end createEvaluateWithSplit;


/*
 //! Evaluates only the equations whose indexs are passed to it.
  bool <%className%>::evaluate_selective(const std::vector<int>& indices) {
    std::vector<int>::const_iterator iter = indices.begin();
    int offset;
    for( ; iter != indices.end(); ++iter) {
        int offset = (*iter) - first_equation_index;
        (this->*equations_array[offset])();
    }
   return false;
  }

  //! Evaluates only a single equation by index.
  bool <%className%>::evaluate_single(const int index) {
    int offset = index - first_equation_index;
    (this->*equations_array[offset])();
    return false;
  }
  */

 /*Ranking: removed from update: if(command & IContinuous::RANKING) checkConditions();*/

template labeledDAE(list<String> labels, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
if Flags.isSet(Flags.WRITE_TO_BUFFER) then match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
<<


<%if labels then
<<
label_list_type <%lastIdentOfPath(modelInfo.name)%>::getLabels()
{
   label_list_type labels = TUPLE_LIST_OF
   <%(labels |> label hasindex index0 => '<%index0%>,&_<%label%>_1,&_<%label%>_2') ;separator=" TUPLE_LIST_SEP "%> TUPLE_LIST_END;
   return labels;
}
>>
else
<<
label_list_type <%lastIdentOfPath(modelInfo.name)%>::getLabels()
{
   return label_list_type();
}
>>%>

void <%lastIdentOfPath(modelInfo.name)%>::setVariables(const ublas::vector<double>& variables,const ublas::vector<double>& variables2)
{
   <%setVariables(modelInfo, useFlatArrayNotation)%>
}
>>
end labeledDAE;

template setVariables(ModelInfo modelInfo, Boolean useFlatArrayNotation)
::=
match modelInfo
case MODELINFO(vars = vars as SIMVARS(__))
then
<<
 <%{(vars.algVars |> SIMVAR(__) hasindex myindex =>
       '<%cref(name,useFlatArrayNotation)%>=variables(<%myindex%>);'
       ;separator="\n"),
    (vars.discreteAlgVars |> SIMVAR(__) hasindex myindex =>
       '<%cref(name,useFlatArrayNotation)%>=variables(<%numAlgvar(modelInfo)%>+<%myindex%>);'
       ;separator="\n"),
    (vars.intAlgVars |> SIMVAR(__) hasindex myindex =>
       '<%cref(name,useFlatArrayNotation)%>=variables(<%numAlgvar(modelInfo)%>+<%numDiscreteAlgVar(modelInfo)%>+<%myindex%>);'
       ;separator="\n"),
    (vars.boolAlgVars |> SIMVAR(__) hasindex myindex =>
       '<%cref(name,useFlatArrayNotation)%>=variables(<%numAlgvar(modelInfo)%>+<%numDiscreteAlgVar(modelInfo)%>+<%numIntAlgvar(modelInfo)%>+<%myindex%>);'
       ;separator="\n"),
    (vars.stateVars |> SIMVAR(__) hasindex myindex =>
       '__z[<%index%>]=variables(<%numAlgvars(modelInfo)%>+<%myindex%>);'
       ;separator="\n"),
    (vars.derivativeVars |> SIMVAR(__) hasindex myindex =>
      '__zDot[<%index%>]=variables2(<%myindex%>);'
      ;separator="\n")}
   ;separator="\n"%>
>>
end setVariables;



template functionAnalyticJacobians2(list<JacobianMatrix> JacobianMatrixes,String modelNamePrefix,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) "template functionAnalyticJacobians
  This template generates source code for all given jacobians."
::=
  let &varDecls = buffer "" /*BUFD*/
  let initialjacMats = (JacobianMatrixes |> (mat, vars, name, (sparsepattern,_), colorList, maxColor, indexJacobian) =>
    initialAnalyticJacobians2(mat, vars, name, sparsepattern, colorList, maxColor, modelNamePrefix); separator="\n")

   /*
  let jacMats = (JacobianMatrixes |> (mat, vars, name, sparsepattern, colorList, maxColor, indexJacobian) =>
    generateMatrix(mat, vars, name, modelNamePrefix) ;separator="\n")
*/
  <<
  <%initialjacMats%>

  >>

  //<%jacMats%>

end functionAnalyticJacobians2;


template initialAnalyticJacobians2(list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String matrixname, list<tuple<Integer,list<Integer>>> sparsepattern, list<list<Integer>> colorList, Integer maxColor, String modelNamePrefix)
"template initialAnalyticJacobians
  This template generates source code for functions that initialize the sparse-pattern for a single jacobian.
  This is a helper of template functionAnalyticJacobians"
::=
match seedVars
case {} then
<<
>>
case _ then
  match sparsepattern
  case _ then
  match matrixname
  case "A" then
      let colorArray = (colorList |> (indexes) hasindex index0 =>
      let colorCol = ( indexes |> i_index =>
        '_<%matrixname%>ColorOfColumn[<%i_index%>] = <%intAdd(index0,1)%>; '
        ;separator="\n")
      '<%colorCol%>'
      ;separator="\n")
      let index_ = listLength(seedVars)
      <<
        if(_AColorOfColumn)
          delete [] _AColorOfColumn;
        _AColorOfColumn = new int[<%index_%>];
        _AMaxColors = <%maxColor%>;

        /* write color array */
        <%colorArray%>
      >>
   end match
   end match


end match
end initialAnalyticJacobians2;

template symbolName(String modelNamePrefix, String symbolName)
  "Creates a unique name for the function"
::=
  modelNamePrefix + "_" + symbolName
end symbolName;


template functionAnalyticJacobiansHeader(list<JacobianMatrix> JacobianMatrixes,String modelNamePrefix) "template functionAnalyticJacobians
  This template generates source code for all given jacobians."
::=

  let initialjacMats = (JacobianMatrixes |> (mat, vars, name, (sparsepattern,_), colorList, maxColor, indexJacobian) =>
    initialAnalyticJacobiansHeader(mat, vars, name, sparsepattern, colorList, maxColor, modelNamePrefix); separator="\n")
/*
  let jacMats = (JacobianMatrixes |> (mat, vars, name, sparsepattern, colorList, maxColor, indexJacobian) =>
    generateMatrix(mat, vars, name, modelNamePrefix) ;separator="\n")
*/
  <<
  <%initialjacMats%>
  >>


end functionAnalyticJacobiansHeader;

template initialAnalyticJacobiansHeader(list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String matrixname, list<tuple<Integer,list<Integer>>> sparsepattern, list<list<Integer>> colorList, Integer maxColor, String modelNamePrefix)
"template initialAnalyticJacobians
  This template generates source code for functions that initialize the sparse-pattern for a single jacobian.
  This is a helper of template functionAnalyticJacobians"
::=
match seedVars
case {} then
<<
>>
case _ then
let help =  match sparsepattern

  case _ then
  match matrixname
  case "A" then
      <<
      public:
        void initializeColoredJacobian<%matrixname%>();
      >>
   end match
   end match
<<
<%help%>
>>
   end match

end initialAnalyticJacobiansHeader;



template mkSparseFunctionHeader(String matrixname, String matrixIndex, Integer cref, list<Integer> indexes, String modelNamePrefix)
"generate "
::=
match matrixname
 case "A" then
    <<
    void initializeColumnsColoredJacobian<%matrixname%>_<%matrixIndex%>();<%\n%>
    >>
end match
end mkSparseFunctionHeader;

template initialAnalyticJacobians(Integer indexJacobian, list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String matrixName, list<tuple<Integer,list<Integer>>> sparsepattern, list<list<Integer>> colorList, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates function that initialize the sparse-pattern for a jacobain matrix"
::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
    let classname =  lastIdentOfPath(modelInfo.name)

    match seedVars
      case {} then ""

      case _ then
        match colorList
        case {} then ""

        case _ then
          let sp_size_index =  lengthListElements(unzipSecond(sparsepattern))
          let indexColumn = (jacobianColumn |> (eqs,vars,indxColumn) => indxColumn;separator="\n")
          let tmpvarsSize = (jacobianColumn |> (_,vars,_) => listLength(vars);separator="\n")
          let index_ = listLength(seedVars)
          let type = getConfigString(MATRIX_FORMAT)
          let matrixinit =  match type
          case ("dense") then
            'ublas::zero_matrix<double> (<%indexColumn%>,<%index_%>)'
          case ("sparse") then
            '<%indexColumn%>,<%index_%>,<%sp_size_index%>'
          else "A matrix type is not supported"
          end match
          <<
          , _<%matrixName%>jacobian(<%matrixinit%>)
          , _<%matrixName%>jac_y(ublas::zero_vector<double>(<%indexColumn%>))
          , _<%matrixName%>jac_tmp(ublas::zero_vector<double>(<%tmpvarsSize%>))
          , _<%matrixName%>jac_x(ublas::zero_vector<double>(<%index_%>))
          >>
        end match
     end match
  end match
end initialAnalyticJacobians;


template functionAnalyticJacobians(list<JacobianMatrix> JacobianMatrixes, SimCode simCode, Text& extraFuncs,
                                   Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates Matrixes for Linear Model."
::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  let classname =  lastIdentOfPath(modelInfo.name)
   let &varDecls = buffer "" /*BUFD*/

 let jacMats = (JacobianMatrixes |> (mat, vars, name, (sparsepattern,_), colorList, maxColor, jacIndex) =>
    generateMatrix(jacIndex, mat, vars, name, sparsepattern, colorList, maxColor,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    ;separator="\n\n";empty)
 /*let initialStateSetJac = (stateSets |> set hasindex i1 fromindex 0 => (match set
       case set as SES_STATESET(__) then
              match jacobianMatrix case (_,_,name,_,_,_,_) then
            'initialAnalytic<%name%>Jacobian();') ;separator="\n")
   let initialJacMats = (JacobianMatrixes |> (mat, vars, name, (sparsepattern,_), colorList, maxColor, jacIndex) =>
    'initialAnalytic<%name%>Jacobian();'
    ;separator="\n";empty)
  */


<<

<%jacMats%>

void <%classname%>Jacobian::initialize()
{
   //create Algloopsolver for analytical Jacobians
      <% (jacobianMatrixes |> (mat, _, _, _, _, _, _) hasindex index0 =>
       (mat |> (eqs,_,_) =>  generateAlgloopsolvers(eqs,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator="")
      ;separator="")
      %>



   //initialize Algloopsolver for analytical Jacobians
      <% (jacobianMatrixes |> (mat, _, _, _, _, _, _) hasindex index0 =>
       (mat |> (eqs,_,_) =>  initAlgloopsolver(eqs,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator="")
       ;separator="")
      %>
      <% (JacobianMatrixes |> (mat, _, _, _, _, _, _) =>
          ( mat |> (eqs,_,_)  => (eqs |> eq => initAlgloopVars2(eq, contextOther, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
          ) ;separator="\n")
         ;separator="")
       %>

}
>>
end functionAnalyticJacobians;




template functionJac(list<SimEqSystem> jacEquations, list<SimVar> tmpVars, String columnLength, String matrixName, Integer indexJacobian, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates function in simulation file."
::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  let classname =  lastIdentOfPath(modelInfo.name)

  let &varDecls = buffer "" /*BUFD*/
  let &tmp = buffer ""
  let eqns_ = (jacEquations |> eq =>
      equation_(eq, contextJacobian, &varDecls /*BUFD*/, /*&tmp*/ simCode, &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      ;separator="\n")
  <<
  void <%classname%>Jacobian::calc<%matrixName%>JacobianColumn()
  {
    <%varDecls%>
    <%eqns_%>
  }
  >>
  end match

end functionJac;


template generateMatrix(Integer indexJacobian, list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String matrixname,
                        list<tuple<Integer,list<Integer>>> sparsepattern, list<list<Integer>>colorList, Integer maxColor,
                        SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates Matrixes for Linear Model."
::=

   match simCode
   case SIMCODE(modelInfo = MODELINFO(__)) then
         generateJacobianMatrix(modelInfo, indexJacobian, jacobianColumn, seedVars, matrixname, sparsepattern, colorList, maxColor, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
   end match


end generateMatrix;


template generateJacobianMatrix(ModelInfo modelInfo, Integer indexJacobian, list<JacobianColumn> jacobianColumn, list<SimVar> seedVars,
                                String matrixName, list<tuple<Integer,list<Integer>>> sparsepattern, list<list<Integer>> colorList,
                                Integer maxColor, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,
                                Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates Matrixes for Linear Model."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
let type = getConfigString(MATRIX_FORMAT)
  let matrixreturntype =  match type
    case ("dense") then
     "matrix_t"
    case ("sparse") then
     "sparsematrix_t"
    else "A matrix type is not supported"
    end match
let classname =  lastIdentOfPath(modelInfo.name)
match jacobianColumn
case {} then
  <<
  void <%classname%>Jacobian::calc<%matrixName%>JacobianColumn()
  {
    throw ModelicaSimulationError(MATH_FUNCTION, "Symbolic jacobians not is activated");

  }

  const <%matrixreturntype%>&  <%classname%>Jacobian::get<%matrixName%>Jacobian()
  {
    throw ModelicaSimulationError(MATH_FUNCTION, "Symbolic jacobians not is activated");
  }
  >>
case _ then
  match colorList
  case {} then
  <<
  void <%classname%>Jacobian::calc<%matrixName%>JacobianColumn()
  {
    throw ModelicaSimulationError(MATH_FUNCTION, "Symbolic jacobians not is activated");
  }

  const <%matrixreturntype%>&  <%classname%>Jacobian::get<%matrixName%>Jacobian()
  {
    throw ModelicaSimulationError(MATH_FUNCTION, "Symbolic jacobians not is activated");
  }
  >>
case _ then
  let jacMats = (jacobianColumn |> (eqs,vars,indxColumn) =>
    functionJac(eqs, vars, indxColumn, matrixName, indexJacobian,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    ;separator="\n")
  let indexColumn = (jacobianColumn |> (eqs,vars,indxColumn) =>
    indxColumn
    ;separator="\n")
  let eqsCount = (jacobianColumn |> (eqs,vars,indxColumn) =>
    listLength(eqs)
    ;separator="+")
  let jacvals = if stringEq(eqsCount, "0") then '' else
    (sparsepattern |> (index,indexes) hasindex index0 =>
      let jaccol = ( indexes |> i_index hasindex index1 =>
        (match indexColumn case "1" then '_<%matrixName%>jacobian(0,<%index%>) = _<%matrixName%>jac_y(0);/*test1<%index0%>,<%index1%>*/'
           else '_<%matrixName%>jacobian(<%i_index%>,<%index%>) = _<%matrixName%>jac_y(<%i_index%>);/*test2<%index0%>,<%index1%>*/'
           )
        ;separator="\n")
    <<
    _<%matrixName%>jac_x(<%index0%>) = 1;
    calc<%matrixName%>JacobianColumn();
    _<%matrixName%>jac_x.clear();
    <%jaccol%>
    >>
    ;separator="\n")
  <<
  <%jacMats%>

  const <%matrixreturntype%>&  <%classname%>Jacobian::get<%matrixName%>Jacobian()
  {
    /*Index <%indexJacobian%>*/
    <%jacvals%>
    return _<%matrixName%>jacobian;
  }
  >>

/*
  (match indexColumn case "1" then ' _<%matrixName%>jacobian(<%crefWithoutIndexOperator(cref)%>$pDER<%matrixName%>$indexdiff,0) = _<%matrixName%>jac_y(0); //1 <%cref(cref)%>'
           else ' _<%matrixName%>jacobian(<%index0%>,<%crefWithoutIndexOperator(cref)%>$pDER<%matrixName%>$indexdiff) = _<%matrixName%>jac_y(<%crefWithoutIndexOperator(cref)%>$pDER<%matrixName%>$indexdiff);//2 <%cref(cref)%>'

*/
end generateJacobianMatrix;



template variableDefinitionsJacobians(list<JacobianMatrix> JacobianMatrixes, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text &jacobianVarsInit, Boolean createDebugCode)
 "Generates defines for jacobian vars."
::=

  let analyticVars = (JacobianMatrixes |> (jacColumn, seedVars, name, (_,_), _, _, jacIndex) =>
    let varsDef = variableDefinitionsJacobians2(jacIndex, jacColumn, seedVars, name, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, &jacobianVarsInit, createDebugCode)
    <<
    <%varsDef%>
    >>
    ;separator="\n";empty)

    <<
    /* Jacobian Variables */
    <%analyticVars%>
    >>
end variableDefinitionsJacobians;

template variableDefinitionsJacobians2(Integer indexJacobian, list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String name, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text& jacobianVarsInit, Boolean createDebugCode)
 "Generates Matrixes for Linear Model."
::=
  let seedVarsResult = (seedVars |> var hasindex index0 =>
    jacobianVarDefine(var, "jacobianVarsSeed", indexJacobian, index0, name, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, &jacobianVarsInit, createDebugCode)
    ;separator="\n";empty)
  let columnVarsResult = (jacobianColumn |> (_,vars,_) =>
      (vars |> var hasindex index0 => jacobianVarDefine(var, "jacobianVars", indexJacobian, index0, name, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, &jacobianVarsInit, createDebugCode)
      ;separator="\n";empty)
    ;separator="\n\n")

<<
<%seedVarsResult%>
<%columnVarsResult%>
>>
end variableDefinitionsJacobians2;


template jacobianVarDefine(SimVar simVar, String array, Integer indexJac, Integer index0, String matrixName, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text& jacobianVarsInit, Boolean createDebugCode)
""
::=
match array
case "jacobianVars" then
  match simVar
  case SIMVAR(aliasvar=NOALIAS(),name=name) then
    match index
    case -1 then
      let jacobianVar = '_<%crefToCStr(name, false)%>'
      let &jacobianVarsInit += if createDebugCode then ', <%jacobianVar%>(_<%matrixName%>jac_tmp(<%index0%>))<%\n%>'
      if createDebugCode then
        'double& <%jacobianVar%>;' else
        '#define <%jacobianVar%> _<%matrixName%>jac_tmp(<%index0%>)'
    case _ then
      let jacobianVar = '_<%crefToCStr(name, false)%>'
      let &jacobianVarsInit += if createDebugCode then ', <%jacobianVar%>(_<%matrixName%>jac_y(<%index%>))<%\n%>'
      if createDebugCode then
        'double& <%jacobianVar%>;' else
        '#define <%jacobianVar%> _<%matrixName%>jac_y(<%index%>)'
    end match
  end match
case "jacobianVarsSeed" then
  match simVar
  case SIMVAR(aliasvar=NOALIAS()) then
    let jacobianVar = '_<%crefToCStr(name, false)%>'
    let &jacobianVarsInit += if createDebugCode then ', <%jacobianVar%>(_<%matrixName%>jac_x(<%index0%>))<%\n%>'
    if createDebugCode then
      'double& <%jacobianVar%>;' else
      '#define <%jacobianVar%> _<%matrixName%>jac_x(<%index0%>)'
  end match
end jacobianVarDefine;


template equationAlgorithm(SimEqSystem eq, Context context,Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates an equation that is an algorithm."
::=
match eq
case SES_ALGORITHM(__)
case SES_INVERSE_ALGORITHM(__) then
  (statements |> stmt =>
    algStatement(stmt, context, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  ;separator="\n")
end equationAlgorithm;
//Generation of Algorithm section
template algStatement(DAE.Statement stmt, Context context, Text &varDecls,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let res = match stmt
  case s as STMT_ASSIGN(exp1=PATTERN(__)) then "STMT_ASSIGN Pattern not supported yet"
  case s as STMT_ASSIGN(__)         then algStmtAssign(s, context, &varDecls /*BUFD*/,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case s as STMT_ASSIGN_ARR(__)     then algStmtAssignArr(s, context, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case s as STMT_TUPLE_ASSIGN(__)   then algStmtTupleAssign(s, context, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case s as STMT_IF(__)             then algStmtIf(s, context, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case s as STMT_FOR(__)            then algStmtFor(s, context, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case s as STMT_WHILE(__)          then algStmtWhile(s, context, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case s as STMT_ASSERT(__)         then algStmtAssert(s, context, &varDecls ,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case s as STMT_TERMINATE(__)      then algStmtTerminate(s, context, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case s as STMT_WHEN(__)           then algStmtWhen(s, context, &varDecls ,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case s as STMT_BREAK(__)          then 'break;<%\n%>'
  case s as STMT_FAILURE(__)        then "STMT FAILURE"
  case s as STMT_RETURN(__)         then "break;/*Todo stmt return*/"
  case s as STMT_NORETCALL(__)      then algStmtNoretcall(s, context, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case s as STMT_REINIT(__)         then algStmtReinit(s, context, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  else error(sourceInfo(), 'ALG_STATEMENT NYI')

  <<
  <%modelicaLine(getElementSourceFileInfo(getStatementSource(stmt)))%>
  <%res%>
  <%endModelicaLine()%>
  >>
end algStatement;

template algStmtWhile(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a while algorithm statement."
::=
match stmt
case STMT_WHILE(__) then
  let &preExp = buffer "" /*BUFD*/
  let var = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  <<
  while (1) {
    <%preExp%>
    if (!<%var%>) break;
    <%statementLst |> stmt => algStatement(stmt, context, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator="\n"%>
  }
  >>
end algStmtWhile;

template algStmtTerminate(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates an assert algorithm statement."
::=
match stmt
case STMT_TERMINATE(__) then
  let &preExp = buffer "" /*BUFD*/
  let msgVar = daeExp(msg, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  <<
  <%preExp%>
  _terminate=true;
  >>
end algStmtTerminate;

template modelicaLine(builtin.SourceInfo info)
::=
  match info
  case SOURCEINFO(columnNumberStart=0) then "/* Dummy Line */"
  else <<
  <% if boolOr(acceptMetaModelicaGrammar(), Flags.isSet(Flags.GEN_DEBUG_SYMBOLS)) then '/*#modelicaLine <%infoStr(info)%>*/'%>
  >>
end modelicaLine;

template endModelicaLine()
::=
  <<
  <% if boolOr(acceptMetaModelicaGrammar(), Flags.isSet(Flags.GEN_DEBUG_SYMBOLS)) then "/*#endModelicaLine*/"%>
  >>
end endModelicaLine;

template algStmtAssign(DAE.Statement stmt, Context context, Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates an assigment algorithm statement."
::=
  match stmt
  case STMT_ASSIGN(exp1=CREF(componentRef=WILD(__)), exp=e) then
    let &preExp = buffer "" /*BUFD*/
    let expPart = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    <<

    <%preExp%>
    >>
  case STMT_ASSIGN(exp1=CREF(ty = T_FUNCTION_REFERENCE_VAR(__)))
  case STMT_ASSIGN(exp1=CREF(ty = T_FUNCTION_REFERENCE_FUNC(__))) then
    let &preExp = buffer "" /*BUFD*/
    let varPart = scalarLhsCref(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    <<

    <%preExp%>
    <%varPart%> = (modelica_fnptr) <%expPart%>;
    >>
    /* Records need to be traversed, assigning each component by itself */
  case STMT_ASSIGN(exp1=CREF(componentRef=cr,ty = T_COMPLEX(varLst = varLst, complexClassType=RECORD(__)))) then
    let &preExp = buffer ""
    let rec = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    <<

    <%preExp%>
    <% varLst |> var as TYPES_VAR(__) =>
      let varNameStr = crefStr(makeUntypedCrefIdent(var.name))
      match var.ty
      case T_ARRAY(__) then
        copyArrayData(var.ty, '<%rec%>.<%varNameStr%>', appendStringCref(var.name, cr), context)
      else
        let varPart = contextCref(appendStringCref(var.name, cr), context, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        '<%varPart%> = <%rec%>.<%varNameStr%>;'
    ; separator="\n"
    %>
    >>
  case STMT_ASSIGN(exp1=CALL(path=path,expLst=expLst,attr=CALL_ATTR(ty= T_COMPLEX(varLst = varLst, complexClassType=RECORD(__))))) then
    let &preExp = buffer ""
    let rec = daeExp(exp, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    <<

    <%preExp%>
    <% varLst |> var as TYPES_VAR(__) hasindex i1 fromindex 2 =>
      let re = daeExp(listGet(expLst,i1), context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      '<%re%> = <%rec%>.<%var.name%>;'
    ; separator="\n"
    %>
    Record = func;
    >>
  case STMT_ASSIGN(exp1=CREF(__)) then
    let &preExp = buffer "" /*BUFD*/
    let varPart = scalarLhsCref(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    <<

    <%preExp%>
    <%varPart%> = <%expPart%> /*stmtAssign*/;

    >>
  case STMT_ASSIGN(exp1=exp1 as ASUB(__),exp=val) then
    (match expTypeFromExpShort(exp)
      case "metatype" then
        // MetaModelica Array
        (match exp case ASUB(exp=arr, sub={idx}) then
        let &preExp = buffer ""
        let arr1 = daeExp(arr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        let idx1 = daeExp(idx, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        let val1 = daeExp(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        <<

        <%preExp%>
        arrayUpdate(<%arr1%>,<%idx1%>,<%val1%>);
        >>)
        // Modelica Array
      else
        let &preExp = buffer "" /*BUFD*/
        let varPart = daeExpAsub(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        let expPart = daeExp(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        <<

        <%preExp%>
        <%varPart%> = <%expPart%>;
        >>
    )
  case STMT_ASSIGN(__) then
    let &preExp = buffer "" /*BUFD*/
    let expPart1 = daeExp(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let expPart2 = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    <<
    /*assign8*/
    <%preExp%>
    <%expPart1%> = <%expPart2%>;
    >>
end algStmtAssign;

template copyArrayData(DAE.Type ty, String exp, DAE.ComponentRef cr,
  Context context)

::=
  let type = expTypeShort(ty)
  let cref = contextArrayCref(cr, context)
  '<%cref%>.assign(<%exp%>);'
end copyArrayData;

template algStmtWhen(DAE.Statement when, Context context, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a when algorithm statement."
::=
match context
case SIMULATION_CONTEXT(__) then
  match when
  case STMT_WHEN(__) then
    let &varDeclsCref = buffer "" /*BUFD*/
    let helpIf = (conditions |> e => ' || (<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref,stateDerVectorName,useFlatArrayNotation)%> && !_discrete_events->pre(<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>))')
    let statements = (statementLst |> stmt =>
        algStatement(stmt, context, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      ;separator="\n")
    let else = algStatementWhenElse(elseWhen, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context, stateDerVectorName, useFlatArrayNotation)
    <<
    if (0<%helpIf%>) {
      <%statements%>
    }
    <%else%>
    >>
   end match
end match
end algStmtWhen;
template algStatementWhenElse(Option<DAE.Statement> stmt, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Helper to algStmtWhen."
::=
match stmt
case SOME(when as STMT_WHEN(__)) then
  let &varDeclsCref = buffer "" /*BUFD*/
  let elseCondStr = (when.conditions |> e => ' || (<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%> && !_discrete_events->pre(<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>))')
  <<
  else if (0<%elseCondStr%>) {
    <% when.statementLst |> stmt =>  algStatement(stmt, contextSimulationDiscrete,&varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
       ;separator="\n"%>
  }
  <%algStatementWhenElse(when.elseWhen, &varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context, stateDerVectorName, useFlatArrayNotation)%>
  >>
end algStatementWhenElse;

template algStmtAssert(DAE.Statement stmt, Context context, Text &varDecls,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates an assert algorithm statement."
::=
match stmt
case STMT_ASSERT(source=SOURCE(info=info)) then
  assertCommon(cond, msg, level, context, &varDecls, info,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
end algStmtAssert;


template algStmtReinit(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates an assigment algorithm statement."
::=
  match stmt
  case STMT_REINIT(__) then
    let &preExp = buffer "" /*BUFD*/
    let expPart1 = daeExp(var, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let expPart2 = daeExp(value, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    /*
    <<
    $P$PRE<%expPart1%> = <%expPart1%>;
    <%preExp%>
    <%expPart1%> = <%expPart2%>;
    >>
    */
    <<
    _discrete_events->save(<%expPart1%>);
     <%preExp%>
    <%expPart1%> = <%expPart2%>;
    >>
end algStmtReinit;

template algStmtIf(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates an if algorithm statement."
::=
match stmt
case STMT_IF(__) then
  let &preExp = buffer "" /*BUFD*/
  let condExp = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  <<
  <%preExp%>
  if <%encloseInParantheses(condExp)%> {
    <%statementLst |> stmt => algStatement(stmt, context, &varDecls /*BUFD*/, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation); separator="\n"%>
  }
  <%elseExpr(else_, context,&preExp , &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
  >>
end algStmtIf;

template elseExpr(DAE.Else it, Context context, Text &preExp, Text &varDecls,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Text stateDerVectorName /*=__zDot*/,Boolean useFlatArrayNotation) ::=
  match it
  case NOELSE(__) then ""
  case ELSEIF(__) then
    let &preExp = buffer ""
    let condExp = daeExp(exp, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    <<
    else {
      <%preExp%>
      if <%encloseInParantheses(condExp)%> {
        <%statementLst |> it => algStatement(it, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation); separator="\n"%>
      }
      <%elseExpr(else_, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
    }
    >>
  case ELSE(__) then
    <<
    else {
      <%statementLst |> it => algStatement(it, context, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      ;separator="\n"%>
    }
    >>
end elseExpr;

template algStmtFor(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a for algorithm statement."
::=
  match stmt
  case s as STMT_FOR(range=rng as RANGE(__)) then
    algStmtForRange(s, context, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case s as STMT_FOR(__) then
    algStmtForGeneric(s, context, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
end algStmtFor;


template algStmtForGeneric(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a for algorithm statement where range is not RANGE."
::=
match stmt
case STMT_FOR(__) then
  let iterType = expType(type_, iterIsArray)
  let arrayType = expTypeShort(type_)


  let stmtStr = (statementLst |> stmt =>
    algStatement(stmt, context, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator="\n")
  algStmtForGeneric_impl(range, iter, iterType, arrayType, iterIsArray, stmtStr,
    context, &varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
end algStmtForGeneric;


template algStmtForGeneric_impl(Exp exp, Ident iterator, String type,
  String arrayType, Boolean iterIsArray, Text &body, Context context, Text &varDecls,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "The implementation of algStmtForGeneric, which is also used by daeExpReduction."
::=
  let iterName = contextIteratorName(iterator, context)
  //let stateVar = if not acceptMetaModelicaGrammar() then tempDecl("state", &varDecls)
  //let tvar = tempDecl("int", &varDecls)
  //let ivar = tempDecl(type, &varDecls)
  let &preExp = buffer ""
  let &tmpVar = buffer ""
  let evar = daeExp(exp, context, &preExp, &tmpVar,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  //let stmtStuff = if iterIsArray then
  //    'simple_index_alloc_<%type%>1(&<%evar%>, <%tvar%>, &<%ivar%>);'
  //  else
  //    '<%iterName%> = *(<%arrayType%>_element_addr1(&<%evar%>, 1, <%tvar%>));'
  <<
  <%preExp%>
  FOREACH(<%type%> <%iterName%>, <%evar%>) {
    <%body%>
  }
  >>

end algStmtForGeneric_impl;

template algStmtNoretcall(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a no return call algorithm statement."
::=
match stmt
case STMT_NORETCALL(__) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  <<
  //No retcall
  <%preExp%>
  <%expPart%>;
    //No retcall
  >>
end algStmtNoretcall;


template algStmtForRange(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a for algorithm statement where range is RANGE."
::=
match stmt
case STMT_FOR(range=rng as RANGE(__)) then
  let identType = expType(type_, iterIsArray)
  let identTypeShort = expTypeShort(type_)
  let stmtStr = (statementLst |> stmt => algStatement(stmt, context, &varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
                 ;separator="\n")
  algStmtForRange_impl(rng, iter, identType, identTypeShort, stmtStr, context, &varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
end algStmtForRange;


template algStmtForRange_impl(Exp range, Ident iterator, String type, String shortType, Text body, Context context, Text &varDecls,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "The implementation of algStmtForRange, which is also used by daeExpReduction."
::=
match range
case RANGE(__) then
  let type = expTypeShort(ty)
  let iterVar = tempDecl('int', &varDecls)
  let iterName = contextIteratorName(iterator, context)
  let startVar = tempDecl(type, &varDecls)
  let stepVar = tempDecl(type, &varDecls)
  let stopVar = tempDecl(type, &varDecls)
  let &preExp = buffer ""
  let startValue = daeExp(start, context, &preExp, &varDecls,simCode, &extraFuncs ,&extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let stepValue = match step case SOME(eo) then
      daeExp(eo, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    else
      '1'
  let stopValue = daeExp(stop, context, &preExp, &varDecls,simCode, &extraFuncs ,&extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  <<
  <%preExp%>
  <%startVar%> = <%startValue%>; <%stepVar%> = <%stepValue%>; <%stopVar%> = <%stopValue%>;
  if(!<%stepVar%>)
  {


  }
  else if(!(((<%stepVar%> > 0) && (<%startVar%> > <%stopVar%>)) || ((<%stepVar%> < 0) && (<%startVar%> < <%stopVar%>))))
  {
    <%type%> <%iterName%>;
    int <%iterVar%>_end = <%if stringEq(type, "int") then
      '(<%stopVar%> - <%startVar%>) / <%stepVar%>;'
      else '(int)((<%stopVar%> - <%startVar%>) / <%stepVar%> + 1e-10);'%>
    for (<%iterVar%> = 0; <%iterVar%> <= <%iterVar%>_end; <%iterVar%>++) {
      <%iterName%> = <%startVar%> + <%iterVar%> * <%stepVar%>;
      <%body%>
    }
  }
  >> /* else we're looping over a zero-length range */
end algStmtForRange_impl;


template algStmtAssignArr(DAE.Statement stmt, Context context,
                 Text &varDecls /*BUFP*/,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates an array assigment algorithm statement."
::=
match stmt
case STMT_ASSIGN_ARR(exp=e, lhs=lhsexp as CREF(componentRef=cr), type_=t) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let dest = algStmtAssignArrCref(lhsexp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  <<
  <%preExp%>
  <%dest%>.assign(<%expPart%>);
  >>
end algStmtAssignArr;


template algStmtAssignArrCref(DAE.Exp exp, Context context,
  Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/, SimCode simCode,
  Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace,
  Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a component reference to an array or a slice of it."
::=
match exp
  case CREF(componentRef=cr, ty = T_ARRAY(ty=basety, dims=dims)) then
    let typeStr = expTypeShort(ty)
    let slice = if crefSubs(cr) then daeExpCrefIndexSpec(crefSubs(cr), context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    if slice then
      'ArraySlice<<%typeStr%>>(<%contextArrayCref(cr, context)%>, <%slice%>)'
    else
      '<%contextArrayCref(cr, context)%>'
end algStmtAssignArrCref;


template functionInitDelay(DelayedExpression delayed,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
   let &preExp = buffer "" /*BUFD*/
  let delay_id = (match delayed case DELAYED_EXPRESSIONS(__) then (delayedExps |> (id, (e, d, delayMax)) =>
     '<%id%>';separator=" LIST_SEP "))
  let delay_max = (match delayed case DELAYED_EXPRESSIONS(__) then (delayedExps |> (id, (e, d, delayMax)) =>
      let delayExpMax = daeExp(delayMax, contextSimulationNonDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     '<%delayExpMax%>';separator=" LIST_SEP "))
  if delay_id then
    <<
    //init delay expressions
    <%varDecls%>
    <%preExp%>
    vector<double> delay_max = LIST_OF <%delay_max%> LIST_END;
    vector<unsigned int> delay_ids = LIST_OF <%delay_id%> LIST_END;
    intDelay(delay_ids, delay_max);
    >>
  else " "
end functionInitDelay;


template functionStoreDelay(DelayedExpression delayed,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
   let storePart = (match delayed case DELAYED_EXPRESSIONS(__) then (delayedExps |> (id, (e, d, delayMax)) =>
      let &preExp = buffer "" /*BUFD*/
      let eRes = daeExp(e, contextSimulationNonDiscrete,
                      &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     <<

      <%preExp%>
       storeDelay(<%id%>, <%eRes%>,time);<%\n%>
      >>
    ))
  <<

    <%varDecls%>
    storeTime(time);
    <%storePart%>
  >>
end functionStoreDelay;
// generate Member Function get Real


template getVariablesWithSplit(Text funcNamePrefix, Text funcArgs, Text funcParams, list<SimVar> varsLst, Integer indexOffset, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text& funcCalls, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/ , Boolean useFlatArrayNotation)
::=
  let funcs =   List.partition(varsLst, 100) |> ls hasindex idx =>
                let &varDecls = buffer "" /*BUFD*/
                let &funcCalls += '<%funcNamePrefix%>_<%idx%>(<%funcParams%>);'
                let init = getVariablesWithSplit2(ls, simCode ,&varDecls, &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, stateDerVectorName,useFlatArrayNotation, idx, 100, indexOffset)
                <<
                void <%funcNamePrefix%>_<%idx%>(<%funcArgs%>)
                {
                   <%varDecls%>
                   <%init%>
                }
                >>
                ;separator="\n"


  <<
  <%funcs%>
  >>
end getVariablesWithSplit;


template getVariablesWithSplit2(list<SimVar> varsLst, SimCode simCode,Text& varDecls,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/ ,Boolean useFlatArrayNotation, Integer multiplicator, Integer partitionSize, Integer indexOffset)
::=
<<
 <%varsLst |>
        var hasindex i0 fromindex (intAdd(indexOffset, intMul(multiplicator, partitionSize))) => giveVariablesDefault(var, i0,simCode,varDecls, extraFuncs,extraFuncsDecl,extraFuncsNamespace,context, stateDerVectorName,useFlatArrayNotation)
        ;separator="\n"%>
 >>
end getVariablesWithSplit2;



template setVariablesWithSplit(Text funcNamePrefix, Text funcArgs, Text funcParams, list<SimVar> varsLst, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text& funcCalls, Integer indexOffset, Context context, Text stateDerVectorName /*=__zDot*/ ,  Boolean useFlatArrayNotation) ::=
  let funcs = List.partition(varsLst, 100) |> ls hasindex idx =>
    let &varDecls = buffer "" /*BUFD*/
    let &funcCalls += '<%funcNamePrefix%>_<%idx%>(<%funcParams%>);'
    let init = setVariablesWithSplit2(ls, simCode , varDecls,&extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context,stateDerVectorName, useFlatArrayNotation, idx, 100, indexOffset)
    <<
    void <%funcNamePrefix%>_<%idx%>(<%funcArgs%>)
    {
       <%varDecls%>
       <%init%>
    }
    >>
    ;separator="\n"

  <<
  <%funcs%>
  >>
end setVariablesWithSplit;


template setVariablesWithSplit2(list<SimVar> varsLst, SimCode simCode ,Text& varDecls,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/ ,  Boolean useFlatArrayNotation, Integer multiplicator, Integer partitionSize, Integer indexOffset)
::=
<<
 <%varsLst|>
        var hasindex i0 fromindex intMul(multiplicator, partitionSize) => setVariablesDefault(var, i0, indexOffset,simCode, varDecls,extraFuncs,extraFuncsDecl,extraFuncsNamespace,context,stateDerVectorName, useFlatArrayNotation)
        ;separator="\n"%>

 >>
end setVariablesWithSplit2;


template giveVariables(ModelInfo modelInfo, Context context,Boolean useFlatArrayNotation,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/ )
 "Define Memeber Function getReal off Cpp Target"
::=
//match context  case FMI_CONTEXT(__) then
  match modelInfo
    case MODELINFO(vars=SIMVARS(__)) then
      let &realFuncCalls = buffer ""
      let &setRealFuncCalls = buffer ""
      let &intFuncCalls = buffer ""
      let &boolFuncCalls = buffer ""
      let &stringFuncCalls = buffer ""
      /* changed: handled in SimVars class
      let stateVarCount = listLength(vars.stateVars)
      let getrealvariable = getVariablesWithSplit(lastIdentOfPath(name)+ "::getReal","double* z","z",listAppend(vars.algVars, listAppend(vars.discreteAlgVars, listAppend(vars.paramVars, vars.aliasVars))), listLength(listAppend(vars.stateVars, vars.derivativeVars)), simCode, &extraFuncs, &extraFuncsDecl, &realFuncCalls, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)
      let setrealvariable = setVariablesWithSplit(lastIdentOfPath(name)+ "::setReal","const double* z","z",listAppend(vars.algVars, listAppend(vars.discreteAlgVars, listAppend(vars.paramVars, vars.aliasVars))), simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, &setRealFuncCalls, listLength(listAppend(vars.stateVars, vars.derivativeVars)), context,stateDerVectorName, useFlatArrayNotation)

      let getStateVariables = (vars.stateVars |> var hasindex i0 fromindex 0 => getStateVariables(var, i0, "z", i0) ;separator="\n")
      let setStateVariables = (vars.stateVars |> var hasindex i0 fromindex 0 => setStateVariables(var, i0, "z", i0) ;separator="\n")

      let getStateDerVariables = (vars.derivativeVars |> var hasindex i0 fromindex 0 => getStateDerivativeVariables(var, i0, "z", i0, stringInt(stateVarCount)) ;separator="\n")
      let setStateDerVariables = (vars.derivativeVars |> var hasindex i0 fromindex 0 => setStateDerivativeVariables(var, i0, "z", i0, stringInt(stateVarCount)) ;separator="\n")

      let getintvariable = getVariablesWithSplit(lastIdentOfPath(name)+ "::getInteger","int* z","z",listAppend(listAppend( vars.intAlgVars, vars.intParamVars ), vars.intAliasVars ), 0, simCode , &extraFuncs , &extraFuncsDecl, &intFuncCalls, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)
      let getboolvariable = getVariablesWithSplit(lastIdentOfPath(name)+ "::getBoolean","bool* z","z",listAppend(listAppend( vars.boolAlgVars, vars.boolParamVars ), vars.boolAliasVars ), 0, simCode , &extraFuncs , &extraFuncsDecl, &boolFuncCalls, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)

      let getstringvariable = getVariablesWithSplit(lastIdentOfPath(name)+ "::getString","string* z","z",listAppend(listAppend( vars.stringAlgVars, vars.stringParamVars ), vars.stringAliasVars), 0, simCode ,&extraFuncs, &extraFuncsDecl, &stringFuncCalls, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)
      */
      let &varDeclsInt = buffer ""
      /* changed: handled in SimVars class
      let setIntVariables = (listAppend( listAppend( vars.intAlgVars, vars.intParamVars ), vars.intAliasVars ) |>
           var hasindex i0 fromindex 0 =>
           setVariablesDefault(var, i0, 0,simCode,varDeclsInt, extraFuncs,extraFuncsDecl,extraFuncsNamespace,context, stateDerVectorName,useFlatArrayNotation)
           ;separator="\n")
      let &varDeclsBool = buffer ""
      let setBoolVariables =     (listAppend( listAppend( vars.boolAlgVars, vars.boolParamVars ), vars.boolAliasVars ) |>
           var hasindex i0 fromindex 0 =>
           setVariablesDefault(var, i0,0,simCode,varDeclsBool, extraFuncs,extraFuncsDecl,extraFuncsNamespace,context, stateDerVectorName,useFlatArrayNotation)
           ;separator="\n")
        */
         let &varDeclsString = buffer ""
        let setStringVariables =  (listAppend(listAppend( vars.stringAlgVars, vars.stringParamVars ), vars.stringAliasVars) |>
           var hasindex i0 fromindex 0 =>
           setVariablesDefault(var, i0, 0,simCode,varDeclsString, extraFuncs,extraFuncsDecl,extraFuncsNamespace,context, stateDerVectorName,useFlatArrayNotation)
           ;separator="\n")

      <<

      void <%lastIdentOfPath(name)%>::getReal(double* z)
      {
        const double* real_vars = getSimVars()->getRealVarsVector();
        memcpy(z,real_vars,<%numRealvars(modelInfo)%>*sizeof(double));
      }

      void <%lastIdentOfPath(name)%>::setReal(const double* z)
      {
        getSimVars()->setRealVarsVector(z);
      }

      void <%lastIdentOfPath(name)%>::getInteger(int* z)
      {
        const int* int_vars = getSimVars()->getIntVarsVector();
        memcpy(z,int_vars,<%numIntvars(modelInfo)%>*sizeof(int));
      }

      void <%lastIdentOfPath(name)%>::getBoolean(bool* z)
      {
        const bool* bool_vars = getSimVars()->getBoolVarsVector();
        memcpy(z,bool_vars,<%numBoolvars(modelInfo)%>*sizeof(bool));
      }

      void <%lastIdentOfPath(name)%>::getString(string* z)
      {
        <%stringFuncCalls%>
      }

      void <%lastIdentOfPath(name)%>::setInteger(const int* z)
      {
         getSimVars()->setIntVarsVector(z);
      }

      void <%lastIdentOfPath(name)%>::setBoolean(const bool* z)
      {
        getSimVars()->setBoolVarsVector(z);
      }

      void <%lastIdentOfPath(name)%>::setString(const string* z)
      {
        <%setStringVariables%>
      }
      >>
  end match
end giveVariables;

template getStateVariables(SimVar simVar, Integer valueReference, String arrayName, Integer index)
 "Generates code for getting variables in cpp target for use in FMU. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  <<
  <%arrayName%>[<%index%>] = this->__z[<%valueReference%>]; <%description%>
  >>
end getStateVariables;

template setStateVariables(SimVar simVar, Integer valueReference, String arrayName, Integer index)
 "Generates code for getting variables in cpp target for use in FMU. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  <<
  this->__z[<%valueReference%>] = <%arrayName%>[<%index%>]; <%description%>
  >>
end setStateVariables;

template getStateDerivativeVariables(SimVar simVar, Integer valueReference, String arrayName, Integer index, Integer indexOffset)
 "Generates code for getting variables in cpp target for use in FMU. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  <<
  <%arrayName%>[<%intAdd(index,indexOffset)%>] = this->__zDot[<%valueReference%>]; <%description%>
  >>
end getStateDerivativeVariables;

template setStateDerivativeVariables(SimVar simVar, Integer valueReference, String arrayName, Integer index, Integer indexOffset)
 "Generates code for getting variables in cpp target for use in FMU. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  <<
  this->__zDot[<%valueReference%>] = <%arrayName%>[<%intAdd(index,indexOffset)%>]; <%description%>
  >>
end setStateDerivativeVariables;

template giveVariablesDefault(SimVar simVar, Integer valueReference,SimCode simCode,Text& varDecls, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/ ,Boolean useFlatArrayNotation)
 "Generates code for getting variables in cpp target for use in FMU. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '/* <%comment%> */'
  let varname = cref1(name, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)
  match aliasvar
    case ALIAS(__)
    case NEGATEDALIAS(__) then 'z[<%valueReference%>] = <%getAliasSign(simVar)%><%cref1(varName, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>; <%description%>'
  else
  <<
  z[<%valueReference%>] = <%varname%>; <%description%>
  >>
end giveVariablesDefault;

template setVariablesDefault(SimVar simVar, Integer valueReference, Integer indexOffset,SimCode simCode,Text& varDecls,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/ , Boolean useFlatArrayNotation)
 "Generates code for getting variables in cpp target for use in FMU. "
::=
  match simVar
    case SIMVAR(__) then
      let description = if comment then '/* "<%comment%>" */'
      let variablename = cref1(name, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, varDecls, stateDerVectorName, useFlatArrayNotation)
      match aliasvar
      case ALIAS(__)
      case NEGATEDALIAS(__) then '<%cref1(varName, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%> = <%getAliasSign(simVar)%>z[<%intAdd(indexOffset, valueReference)%>]; <%description%>'
      else
          <<
          <%variablename%> = z[<%intAdd(indexOffset, valueReference)%>]; <%description%>
          >>
  end match
end setVariablesDefault;







template generateMeasureTimeStartCode(String varNameStartValues, String sectionName, String defineName)
::=
  if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
   <<
   <%if stringEq(defineName, "") then '' else '#ifdef <%defineName%>'%>
     MEASURETIME_REGION_DEFINE(<%sectionName%>, "<%sectionName%>");
     MEASURETIME_START(<%varNameStartValues%>, <%sectionName%>, "<%sectionName%>");
   <%if stringEq(defineName, "") then '' else '#endif'%>
   >>
end generateMeasureTimeStartCode;

template generateMeasureTimeEndCode(String varNameStartValues, String varNameEndValues, String varNameTargetValues, String sectionName, String defineName)
::=
  if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
  <<
  <%if stringEq(defineName, "") then '' else '#ifdef <%defineName%>'%>
    MEASURETIME_END(<%varNameStartValues%>,<%varNameEndValues%>,<%varNameTargetValues%>, <%sectionName%>);
  <%if stringEq(defineName, "") then '' else '#endif'%>
  >>
end generateMeasureTimeEndCode;



/*daeMode templates*/






template simulationDAEMethodsDeclaration(SimCode simCode)
::=
match simCode
    case SIMCODE(modelInfo=MODELINFO(vars=SIMVARS(__)),
        daeModeData=SOME(DAEMODEDATA(daeEquations=daeEquations, sparsityPattern=sparsityPattern,
                                     algebraicDAEVars=algebraicDAEVars, residualVars=residualVars))) then
 <<
  <%generateDAEEquationMemberFuncDecls(daeEquations,"evaluateDAE")%>

 >>
end simulationDAEMethodsDeclaration;

template updateResiduals(SimCode simCode,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,  Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
 let &extraFuncsResidual = buffer "" /*BUFD*/
<<
<%simulationDAEMethods(simCode, extraFuncsResidual,extraFuncsDecl, extraFuncsNamespace,contextOther,stateDerVectorName,useFlatArrayNotation,boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")))%>

<%extraFuncsResidual%>




>>
end updateResiduals;

template generateDAEEquationMemberFuncDecls(list<list<SimEqSystem>> DAEEquations,Text method)
::=
  match DAEEquations
  case _ then
    let equation_func_decls = (DAEEquations |> eqsys =>  (eqsys |> eq =>
	generateEquationMemberFuncDecls2(eq,method) ;separator="\n"))
    <<
    <%equation_func_decls%>
    >>
  end match
end generateDAEEquationMemberFuncDecls;


template simulationDAEMethods(SimCode simCode,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Boolean enableMeasureTime)
"DAEmode equations generation"
::=
  match simCode
    case SIMCODE(modelInfo=MODELINFO(vars=SIMVARS(__)),
        daeModeData=SOME(DAEMODEDATA(daeEquations=daeEquations, sparsityPattern=sparsityPattern,
                                     algebraicDAEVars=algebraicDAEVars, residualVars=residualVars))) then
     let modelNamePrefixStr = lastIdentOfPath(modelInfo.name)

     <<



     <%algebraicDAEVar(algebraicDAEVars, modelNamePrefixStr)%>
     <%evaluateDAEResiduals(daeEquations, simCode ,extraFuncs,extraFuncsDecl,extraFuncsNamespace, context, enableMeasureTime)%>
	 <%equationResidualFunctions(daeEquations,simCode ,extraFuncs,extraFuncsDecl,extraFuncsNamespace, context, stateDerVectorName ,  useFlatArrayNotation,  enableMeasureTime)%>
	 void <%modelNamePrefixStr%>Mixed::getResidual(double* f)
     {
        SystemDefaultImplementation::getResidual(f);
	 }
	 >>
     /* adrpo: leave a newline at the end of file to get rid of the warning */
    case SIMCODE(modelInfo=MODELINFO(__),daeModeData=NONE()) then
    let modelNamePrefixStr = lastIdentOfPath(modelInfo.name)
    <<
    /* DAE residuals is empty */
    void <%modelNamePrefixStr%>Mixed::getResidual(double* f)
    {

	}
	void <%modelNamePrefixStr%>Mixed::setAlgebraicDAEVars(const double* y)
    {
    }
	/* get algebraic variables */
    void <%modelNamePrefixStr%>Mixed::getAlgebraicDAEVars( double* y)
    {
    }
	void <%modelNamePrefixStr%>Mixed::evaluateDAE(const UPDATETYPE command )
    {

    }
    >>
  end match
end simulationDAEMethods;



template algebraicDAEVar(list<SimVar> algVars, String className)
  "Generates function in simulation file."
::=
  let setVars = (algVars |> var hasindex i fromindex 0 =>
    (match var
    case SIMVAR(__) then
      '<%cref(name,false)%> = y[<%i%>];'
    end match)
  ;separator="\n")
  let getVars = (algVars |> var hasindex i fromindex 0 =>
    (match var
    case SIMVAR(__) then
      'y[<%i%>] = <%cref(name,false)%>;'
    end match)
  ;separator="\n")
  /*let nominalVars = (algVars |> var hasindex i fromindex 0 =>
    (match var
    case SIMVAR(__) then
      <<
      algebraicNominal[<%i%>] = <%crefAttributes(name)%>.nominal * data->simulationInfo->tolerance;
      infoStreamPrint(LOG_SOLVER, 0, "%s -> %g", <%crefVarInfo(name)%>.name, algebraicNominal[<%i%>]);
      >>
    end match)

  ;separator="\n")*/

  <<


  void <%className%>Mixed::setAlgebraicDAEVars(const double* y)
  {

    <%setVars%>

  }
  /* get algebraic variables */
  void <%className%>Mixed::getAlgebraicDAEVars( double* y)
  {

    <%getVars%>

  }
  >>
end algebraicDAEVar;


template evaluateDAEResiduals(list<list<SimEqSystem>> resEquations, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Boolean createMeasureTime)
  "Generates function in simulation file."
::=
  match simCode
  case SIMCODE(partitionData = PARTITIONDATA(partitions = partitions, activatorsForPartitions=activatorsForPartitions)) then
//case MODELINFO(vars = vars as SIMVARS(__))
  let className = '<%lastIdentOfPathFromSimCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>Mixed'
  let &varDecls = buffer ""

  let equation_dae_func_calls = if not Flags.isSet(Flags.MULTIRATE_PARTITION) then (List.partition(List.flatten(resEquations), 100) |> eqs hasindex i0 =>
                                 createEvaluateWithSplit(i0, context, eqs, "evaluateDAE","evaluateDAE", className, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)
                                 ;separator="\n")
                else ( List.intRange(partitionData.numPartitions) |> partIdx =>
                createEvaluatePartitions(partIdx, context, List.flatten(resEquations), listGet(partitions, partIdx),
                listGet(activatorsForPartitions,partIdx), className,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace) ;separator="\n")
  <<
  void <%className%>::evaluateDAE(const UPDATETYPE command )
  {
    <%if createMeasureTime then generateMeasureTimeStartCode("measuredFunctionStartValues", "evaluateDAE", "MEASURETIME_MODELFUNCTIONS") else ""%>
    <%varDecls%>
    // Evaluate Equations
    <%equation_dae_func_calls%>
    <%if createMeasureTime then generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "(*measureTimeFunctionsArray)[0]", "evaluateDAE", "MEASURETIME_MODELFUNCTIONS") else ""%>
  }
  >>
end evaluateDAEResiduals;



template equationResidualFunctions(list<list<SimEqSystem>> daeEquations, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Boolean enableMeasureTime)
::=

  let equation_func_calls = (daeEquations |> eqsys => (eqsys |> eq =>
                    equation_function_create_single_func(eq, context/*BUFC*/, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,"evaluateDAE","Mixed", stateDerVectorName, useFlatArrayNotation,enableMeasureTime,false,false, "")
                    ;separator="\n"))
  <<
  <%equation_func_calls%>
  >>
end equationResidualFunctions;

/*temporary template functions*/

template defineSimVarArray(SimVar simVar)
  "Generates a define statement for a parameter."
::=
 match simVar
  case SIMVAR(arrayCref=SOME(c),aliasvar=NOALIAS()) then
    <<
    /* <%crefStrNoUnderscore(c)%> */
    #define <%crefStr(c)%> __daeResidual<%index%>]

    /* <%crefStrNoUnderscore(name)%> */
    #define <%crefStr(name)%> __daeResidual[<%index%>]

    >>
  case SIMVAR(aliasvar=NOALIAS()) then
    <<
    /* <%crefStrNoUnderscore(name)%> */
    #define <%crefStr(name)%> __daeResidual[<%index%>]

    >>
  end match
end defineSimVarArray;

template simulationFile_dae_header(SimCode simCode)
"DAEmode header generation"
::=
  match simCode
    case simCode as SIMCODE(daeModeData=SOME(DAEMODEDATA(residualVars=residualVars))) then
    <<
    /* residual variable define for daeMode */
    <%residualVars |> var =>
      defineSimVarArray(var)
    ;separator="\n"%>
    >>
    /* adrpo: leave a newline at the end of file to get rid of the warning */
    case simCode as SIMCODE(__) then
    <<
    #ifndef <%fileNamePrefix%>_16DAE_H
    #define <%fileNamePrefix%>_16DAE_H
    #endif
    <%\n%>
    >>
  end match
end simulationFile_dae_header;





/*end daeMode templates*/

annotation(__OpenModelica_Interface="backend");
end CodegenCpp;
