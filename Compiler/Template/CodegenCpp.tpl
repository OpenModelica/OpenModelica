package CodegenCpp

import interface SimCodeTV;
import CodegenUtil.*;
import CodegenCppInit.*;




template translateModel(SimCode simCode)
::=
  let stateDerVectorName = "__zDot"
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__)) then
        let target  = simulationCodeTarget()
        let &extraFuncs = buffer "" /*BUFD*/
        let &extraFuncsDecl = buffer "" /*BUFD*/

        let className = lastIdentOfPath(modelInfo.name)
        let numRealVars = numRealvars(modelInfo)
        let numIntVars = numIntvars(modelInfo)
        let numBoolVars = numBoolvars(modelInfo)

        let()= textFile(simulationMainFile(target, simCode , &extraFuncs , &extraFuncsDecl, "", "", "", "", numRealVars, numIntVars, numBoolVars, getPreVarsCount(modelInfo)), 'OMCpp<%fileNamePrefix%>Main.cpp')
        let()= textFile(simulationCppFile(simCode, contextOther, update(simCode , &extraFuncs , &extraFuncsDecl,  className, stateDerVectorName, false),
                        '<%numRealVars%> - 1', '<%numIntVars%> - 1', '<%numBoolVars%> - 1', &extraFuncs, &extraFuncsDecl, className, "", "", "",
                        stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>.cpp')
        let()= textFile(simulationHeaderFile(simCode , contextOther,&extraFuncs , &extraFuncsDecl, className, "", "", "",
                                             memberVariableDefine(modelInfo, varToArrayIndexMapping, '<%numRealVars%> - 1', '<%numIntVars%> - 1', '<%numBoolVars%> - 1', false),
                                             memberVariableDefinePreVariables(modelInfo, varToArrayIndexMapping, '<%numRealVars%> - 1', '<%numIntVars%> - 1', '<%numBoolVars%> - 1', false),
                                             false), 'OMCpp<%fileNamePrefix%>.h')
        let()= textFile(simulationTypesHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, "", modelInfo.functions, literals, stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>Types.h')
        let()= textFile(simulationMakefile(target,simCode , &extraFuncs , &extraFuncsDecl, "","","","","",false), '<%fileNamePrefix%>.makefile')

        let &extraFuncsFun = buffer "" /*BUFD*/
        let &extraFuncsDeclFun = buffer "" /*BUFD*/
        let()= textFile(simulationFunctionsFile(simCode, &extraFuncsFun, &extraFuncsDeclFun, 'Functions', modelInfo.functions, literals, externalFunctionIncludes, stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>Functions.cpp')
        let()= textFile(simulationFunctionsHeaderFile(simCode, &extraFuncsFun, &extraFuncsDeclFun, 'Functions', modelInfo.functions, literals, stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>Functions.h')

        let &extraFuncsInit = buffer "" /*BUFD*/
        let &extraFuncsDeclInit = buffer "" /*BUFD*/
        let()= textFile(simulationInitCppFile(simCode , &extraFuncsInit , &extraFuncsDeclInit, '<%className%>Initialize', stateDerVectorName, false),'OMCpp<%fileNamePrefix%>Initialize.cpp')
        let()= textFile(simulationInitParameterCppFile(simCode, &extraFuncsInit, &extraFuncsDeclInit, '<%className%>Initialize', stateDerVectorName, false),'OMCpp<%fileNamePrefix%>InitializeParameter.cpp')
        let()= textFile(simulationInitAliasVarsCppFile(simCode, &extraFuncsInit, &extraFuncsDeclInit, '<%className%>Initialize', stateDerVectorName, false),'OMCpp<%fileNamePrefix%>InitializeAliasVars.cpp')
        let()= textFile(simulationInitAlgVarsCppFile(simCode , &extraFuncsInit , &extraFuncsDeclInit, '<%className%>Initialize', stateDerVectorName, false),'OMCpp<%fileNamePrefix%>InitializeAlgVars.cpp')
        let()= textFile(simulationInitExtVarsCppFile(simCode, &extraFuncsInit, &extraFuncsDeclInit, '<%className%>Initialize', stateDerVectorName, false),'OMCpp<%fileNamePrefix%>InitializeExtVars.cpp')
        let()= textFile(simulationInitHeaderFile(simCode , &extraFuncsInit , &extraFuncsDeclInit, '<%className%>Initialize'), 'OMCpp<%fileNamePrefix%>Initialize.h')

        let()= textFile(simulationJacobianHeaderFile(simCode , &extraFuncs , &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>Jacobian.h')
        let()= textFile(simulationJacobianCppFile(simCode , &extraFuncs , &extraFuncsDecl, "", stateDerVectorName, false),'OMCpp<%fileNamePrefix%>Jacobian.cpp')
        let()= textFile(simulationStateSelectionCppFile(simCode , &extraFuncs , &extraFuncsDecl, "", stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>StateSelection.cpp')
        let()= textFile(simulationStateSelectionHeaderFile(simCode , &extraFuncs , &extraFuncsDecl, ""),'OMCpp<%fileNamePrefix%>StateSelection.h')
        let()= textFile(simulationExtensionHeaderFile(simCode , &extraFuncs , &extraFuncsDecl, ""),'OMCpp<%fileNamePrefix%>Extension.h')
        let()= textFile(simulationExtensionCppFile(simCode , &extraFuncs , &extraFuncsDecl, ""),'OMCpp<%fileNamePrefix%>Extension.cpp')
        let()= textFile(simulationWriteOutputHeaderFile(simCode , &extraFuncs , &extraFuncsDecl, ""),'OMCpp<%fileNamePrefix%>WriteOutput.h')
        let()= textFile(simulationWriteOutputCppFile(simCode , &extraFuncs , &extraFuncsDecl, "", stateDerVectorName, false),'OMCpp<%fileNamePrefix%>WriteOutput.cpp')
        let()= textFile(simulationWriteOutputAlgVarsCppFile(simCode , &extraFuncs , &extraFuncsDecl, "", stateDerVectorName, false),'OMCpp<%fileNamePrefix%>WriteOutputAlgVars.cpp')
        let()= textFile(simulationWriteOutputParameterCppFile(simCode , &extraFuncs , &extraFuncsDecl, "", false),'OMCpp<%fileNamePrefix%>WriteOutputParameter.cpp')
        let()= textFile(simulationWriteOutputAliasVarsCppFile(simCode , &extraFuncs , &extraFuncsDecl, "", stateDerVectorName, false),'OMCpp<%fileNamePrefix%>WriteOutputAliasVars.cpp')
        let()= textFile(simulationFactoryFile(simCode , &extraFuncs , &extraFuncsDecl, ""),'OMCpp<%fileNamePrefix%>FactoryExport.cpp')
        let()= textFile(modelInitXMLFile(simCode, numRealVars, numIntVars, numBoolVars),'OMCpp<%fileNamePrefix%>Init.xml')
        let()= textFile(simulationMainRunScript(simCode , &extraFuncs , &extraFuncsDecl, "", "", "", "exec"), '<%fileNamePrefix%><%simulationMainRunScriptSuffix(simCode , &extraFuncs , &extraFuncsDecl, "")%>')
        let jac =  (jacobianMatrixes |> (mat, _, _, _, _, _, _) =>
          (mat |> (eqs,_,_) =>  algloopfiles(eqs,simCode , &extraFuncs , &extraFuncsDecl, "",contextAlgloopJacobian, stateDerVectorName, false) ;separator="")
         ;separator="")

        let alg = algloopfiles(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl, "", contextAlgloop, stateDerVectorName, false)
        let()= textFile(algloopMainfile(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl, "",contextAlgloop), 'OMCpp<%fileNamePrefix%>AlgLoopMain.cpp')
        let()= textFile(calcHelperMainfile(simCode , &extraFuncs , &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>CalcHelperMain.cpp')
    match target
    case "vxworks69" then
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
  match modelInfo
  case modelInfo as MODELINFO(vars=SIMVARS(__)) then
  <<
  #pragma once

  /*****************************************************************************
  *
  * Simulation code to initialize the Modelica system
  *
  *****************************************************************************/

  class <%lastIdentOfPath(modelInfo.name)%>Initialize : virtual public <%lastIdentOfPath(modelInfo.name)%>
  {
  public:
    <%lastIdentOfPath(modelInfo.name)%>Initialize(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars);
    virtual ~<%lastIdentOfPath(modelInfo.name)%>Initialize();
    virtual bool initial();
    virtual void setInitial(bool);
    virtual void initialize();
    virtual void initializeMemory();
    virtual void initializeFreeVariables();
    virtual void initializeBoundVariables();
    virtual void initEquations();

  private:
    <%initeqs%>

    <%List.partition(vars.algVars, 100) |> ls hasindex idx => 'void initializeAlgVars_<%idx%>();';separator="\n"%>
    <%initExtVarsDecl(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, false)%>
    void initializeAlgVars();
    void initializeDiscreteAlgVars();

    <%List.partition(vars.intAlgVars, 100) |> ls hasindex idx => 'void initializeIntAlgVars_<%idx%>();';separator="\n"%>

    void initializeIntAlgVars();
    void initializeBoolAlgVars();

    <%List.partition(vars.aliasVars, 100) |> ls hasindex idx => 'void initializeAliasVars_<%idx%>();';separator="\n"%>
    <%List.partition(vars.stringAliasVars, 100) |> ls hasindex idx => 'void initializeStringAliasVars_<%idx%>();';separator="\n"%>
    void initializeStringAliasVars();
    void initializeAliasVars();
    void initializeIntAliasVars();
    void initializeBoolAliasVars();

    <%List.partition(vars.paramVars, 100) |> ls hasindex idx => 'void initializeParameterVars_<%idx%>();';separator="\n"%>
    <%List.partition(vars.intParamVars, 100) |> ls hasindex idx => 'void initializeIntParameterVars_<%idx%>();';separator="\n"%>
    <%List.partition(vars.boolParamVars, 100) |> ls hasindex idx => 'void initializeBoolParameterVars_<%idx%>();';separator="\n"%>
    <%List.partition(vars.stringParamVars, 100) |> ls hasindex idx => 'void initializeStringParameterVars_<%idx%>();';separator="\n"%>
    void initializeParameterVars();
    void initializeIntParameterVars();
    void initializeBoolParameterVars();
    void initializeStringParameterVars();
    void initializeStateVars();
    void initializeDerVars();

    /*extraFuncs*/
    <%extraFuncsDecl%>
  };
  >>
  end match
end simulationInitHeaderFile;

template simulationJacobianHeaderFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
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

  class <%lastIdentOfPath(modelInfo.name)%>Jacobian : virtual public <%lastIdentOfPath(modelInfo.name)%>
  {
  <% (jacobianMatrixes |> (mat, _, _, _, _, _, _) hasindex index0 =>
       (mat |> (eqs,_,_) =>  generatefriendAlgloops(eqs,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator="\n")
     ;separator="")
  %>
  public:
    <%lastIdentOfPath(modelInfo.name)%>Jacobian(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars);
    virtual ~<%lastIdentOfPath(modelInfo.name)%>Jacobian();

  protected:
    void initialize();
    <%
    let jacobianfunctions = (jacobianMatrixes |> (_,_, name, _, _, _, _) hasindex index0 =>
    <<
    void calc<%name%>JacobianColumn();
    void get<%name%>Jacobian(SparseMatrix& matrix);
    /*needed for colored Jacs*/
    >>
    ;separator="\n";empty)
    <<
    <%jacobianfunctions%>
    >>
    %>

    <%
    let jacobianvars = (jacobianMatrixes |> (_,_, name, _, _, _, _) hasindex index0 =>
    <<
    private:
      SparseMatrix _<%name%>jacobian;
      ublas::vector<double> _<%name%>jac_y;
      ublas::vector<double> _<%name%>jac_tmp;
      ublas::vector<double> _<%name%>jac_x;

    public:
      /*needed for colored Jacs*/
      int* _<%name%>ColorOfColumn;
      int  _<%name%>MaxColors;
    >>
    ;separator="\n";empty)
    <<
    <%jacobianvars%>
    >>
    %>

    <%variableDefinitionsJacobians(jacobianMatrixes,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>



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
  class <%lastIdentOfPath(modelInfo.name)%>StateSelection: virtual public  <%lastIdentOfPath(modelInfo.name)%>
  {
  public:
    <%lastIdentOfPath(modelInfo.name)%>StateSelection(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars);
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
  let n = numProtectedParamVars(modelInfo)
  let outputtype = match   settings.outputFormat case "mat" then "MatFileWriter" case "buffer"  then "BufferReaderWriter" else "TextFileWriter"
  let numparams = match   settings.outputFormat case "csv" then "1" else n
  <<
  #pragma once
  typedef HistoryImpl<<%outputtype%>,<%numProtectedAlgvars(modelInfo)%>+<%numProtectedAliasvars(modelInfo)%>+<%numStatevars(modelInfo)%>,<%numDerivativevars(modelInfo)%>,0,<%numparams%>> HistoryImplType;

  /*****************************************************************************
  *
  * Simulation code to write simulation file
  *
  *****************************************************************************/

  class <%lastIdentOfPath(modelInfo.name)%>WriteOutput : virtual public <%lastIdentOfPath(modelInfo.name)%>
  {
  public:
    <%lastIdentOfPath(modelInfo.name)%>WriteOutput(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars);
    virtual ~<%lastIdentOfPath(modelInfo.name)%>WriteOutput();


    /// Output routine (to be called by the solver after every successful integration step)
    virtual void writeOutput(const IWriteOutput::OUTPUT command = IWriteOutput::UNDEF_OUTPUT);
    virtual IHistory* getHistory();

  protected:
    void initialize();
   private:
    <% match modelInfo case MODELINFO(vars=SIMVARS(__)) then
    <<
        void writeParams(HistoryImplType::value_type_p& params);
        <%List.partition(protectedVars(vars.paramVars), 100) |> ls hasindex idx => 'void writeParamsReal_<%idx%>(HistoryImplType::value_type_p& params );';separator="\n"%>
        void writeParamsReal(HistoryImplType::value_type_p& params  );
        <%List.partition(protectedVars(vars.intParamVars), 100) |> ls hasindex idx => 'void writeParamsInt_<%idx%>(HistoryImplType::value_type_p& params  );';separator="\n"%>
        void writeParamsInt(HistoryImplType::value_type_p& params  );
        <%List.partition(protectedVars(vars.boolParamVars), 100) |> ls hasindex idx => 'void writeParamsBool_<%idx%>(HistoryImplType::value_type_p& params  );';separator="\n"%>
        void writeParamsBool(HistoryImplType::value_type_p& params  );


        void writeAlgVarsValues(HistoryImplType::value_type_v *v);
        <%List.partition( protectedVars(vars.algVars), 100) |> ls hasindex idx => 'void writeAlgVarsValues_<%idx%>(HistoryImplType::value_type_v *v);';separator="\n"    %>
        void writeDiscreteAlgVarsValues(HistoryImplType::value_type_v *v);
        <%List.partition( protectedVars(vars.discreteAlgVars), 100) |> ls hasindex idx => 'void writeDiscreteAlgVarsValues_<%idx%>(HistoryImplType::value_type_v *v);';separator="\n"    %>
        void writeIntAlgVarsValues(HistoryImplType::value_type_v *v);
        <%List.partition( protectedVars(vars.intAlgVars), 100) |> ls hasindex idx => 'void writeIntAlgVarsValues_<%idx%>(HistoryImplType::value_type_v *v);';separator="\n"    %>
        void writeBoolAlgVarsValues(HistoryImplType::value_type_v *v);
        <%List.partition( protectedVars(vars.boolAlgVars), 100) |> ls hasindex idx => 'void writeBoolAlgVarsValues_<%idx%>(HistoryImplType::value_type_v *v);';separator="\n"    %>
        void writeAliasVarsValues(HistoryImplType::value_type_v *v);
        <%List.partition( protectedVars(vars.aliasVars), 100) |> ls hasindex idx => 'void writeAliasVarsValues_<%idx%>(HistoryImplType::value_type_v *v);';separator="\n"    %>
        void writeIntAliasVarsValues(HistoryImplType::value_type_v *v);
        <%List.partition( protectedVars(vars.intAliasVars), 100) |> ls hasindex idx => 'void writeIntAliasVarsValues_<%idx%>(HistoryImplType::value_type_v *v);';separator="\n"    %>
        void writeBoolAliasVarsValues(HistoryImplType::value_type_v *v);
        <%List.partition( protectedVars(vars.boolAliasVars), 100) |> ls hasindex idx => 'void writeBoolAliasVarsValues_<%idx%>(HistoryImplType::value_type_v *v);';separator="\n"    %>
        void writeStateValues(HistoryImplType::value_type_v *v, HistoryImplType::value_type_dv *v2);

    >>
    end match%>

    void writeAlgVarsResultNames(vector<string>& names);
    void writeDiscreteAlgVarsResultNames(vector<string>& names);
    void writeIntAlgVarsResultNames(vector<string>& names);
    void writeBoolAlgVarsResultNames(vector<string>& names);
    void writeAliasVarsResultNames(vector<string>& names);
    void writeIntAliasVarsResultNames(vector<string>& names);
    void writeBoolAliasVarsResultNames(vector<string>& names);
    void writeStateVarsResultNames(vector<string>& names);
    void writeDerivativeVarsResultNames(vector<string>& names);
    void writeParametertNames(vector<string>& names);
    void writeIntParameterNames(vector<string>& names);
    void writeBoolParameterNames(vector<string>& names);

    void writeAlgVarsResultDescription(vector<string>& names);
    void writeDiscreteAlgVarsResultDescription(vector<string>& names);
    void writeIntAlgVarsResultDescription(vector<string>& names);
    void writeBoolAlgVarsResultDescription(vector<string>& names);
    void writeAliasVarsResultDescription(vector<string>& names);
    void writeIntAliasVarsResultDescription(vector<string>& names);
    void writeBoolAliasVarsResultDescription(vector<string>& names);
    void writeStateVarsResultDescription(vector<string>& names);
    void writeDerivativeVarsResultDescription(vector<string>& names);
    void writeParameterDescription(vector<string>& names);
    void writeIntParameterDescription(vector<string>& names);
    void writeBoolParameterDescription(vector<string>& names);

    HistoryImplType* _historyImpl;
  };
  >>
end simulationWriteOutputHeaderFile;


template getPreVarsCount(ModelInfo modelInfo)
::=
  match modelInfo
    case MODELINFO(varInfo=VARINFO(__)) then
      let allVarCount = intAdd(stringInt(numRealvars(modelInfo)), intAdd(stringInt(numIntvars(modelInfo)), stringInt(numBoolvars(modelInfo))))
      //let allVarCount = intAdd(intAdd(intAdd(varInfo.numAlgAliasVars,varInfo.numAlgVars),varInfo.numDiscreteReal ), intAdd(intAdd(varInfo.numIntAliasVars,varInfo.numIntAlgVars), intAdd(varInfo.numBoolAlgVars,intAdd(varInfo.numBoolAliasVars, intMul(2,varInfo.numStateVars)))))
      <<
      <%allVarCount%>
      >>
    end match
end getPreVarsCount;




template simulationExtensionHeaderFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
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
  class <%lastIdentOfPath(modelInfo.name)%>Extension: public ISystemInitialization, public IMixedSystem,public IWriteOutput, public IStateSelection, public <%lastIdentOfPath(modelInfo.name)%>WriteOutput, public <%lastIdentOfPath(modelInfo.name)%>Initialize, public <%lastIdentOfPath(modelInfo.name)%>Jacobian,public <%lastIdentOfPath(modelInfo.name)%>StateSelection
  {
  public:
    <%lastIdentOfPath(modelInfo.name)%>Extension(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars);
    virtual ~<%lastIdentOfPath(modelInfo.name)%>Extension();

    ///Intialization methods from ISystemInitialization
    virtual bool initial();
    virtual void setInitial(bool);
    virtual void initialize();
    virtual void initEquations();

    ///Write simulation results methods from IWriteOutput
    /// Output routine (to be called by the solver after every successful integration step)
    virtual void writeOutput(const IWriteOutput::OUTPUT command = IWriteOutput::UNDEF_OUTPUT);
    virtual IHistory* getHistory();
    /// Provide Jacobian
    virtual void getJacobian(SparseMatrix& matrix);
    virtual void getStateSetJacobian(unsigned int index,SparseMatrix& matrix);
    /// Called to handle all events occured at same time
    virtual bool handleSystemEvents(bool* events);
    //Saves all variables before an event is handled, is needed for the pre, edge and change operator
    virtual void saveAll();

    //StateSelction methods
    virtual int getDimStateSets() const;
    virtual int getDimStates(unsigned int index) const;
    virtual int getDimCanditates(unsigned int index) const ;
    virtual int getDimDummyStates(unsigned int index) const ;
    virtual void getStates(unsigned int index,double* z);
    virtual void setStates(unsigned int index,const double* z);
    virtual void getStateCanditates(unsigned int index,double* z);
    virtual bool getAMatrix(unsigned int index,DynArrayDim2<int>& A);
    virtual void setAMatrix(unsigned int index, DynArrayDim2<int>& A);
    virtual bool getAMatrix(unsigned int index,DynArrayDim1<int>& A);
    virtual void setAMatrix(unsigned int index,DynArrayDim1<int>& A);


    /*colored jacobians*/
    virtual void getAColorOfColumn(int* aSparsePatternColorCols, int size);
    virtual int  getAMaxColors();

    virtual string getModelName();
  };
  >>
end simulationExtensionHeaderFile;



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
  extern "C" IMixedSystem* createModelicaSystem(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> algLoopSolverFactory, boost::shared_ptr<ISimData> simData, boost::shared_ptr<ISimVars> simVars)
  {
      return new <%lastIdentOfPath(modelInfo.name)%>Extension(globalSettings, algLoopSolverFactory, simData, simVars);
  }

  extern "C" ISimVars* createSimVars(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_pre_vars, size_t dim_z, size_t z_i)
  {
      return new SimVars(dim_real, dim_int, dim_bool, dim_pre_vars, dim_z, z_i);
  }

  extern "C" ISimData* createSimData()
  {
      return new SimData();
  }

  #elif defined (RUNTIME_STATIC_LINKING)
    boost::shared_ptr<ISimData> createSimDataFunction()
    {
        boost::shared_ptr<ISimData> data( new SimData() );
        return data;
    }

    boost::shared_ptr<ISimVars> createSimVarsFunction(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_pre_vars, size_t dim_z, size_t z_i)
    {
        boost::shared_ptr<ISimVars> var( new SimVars(dim_real, dim_int, dim_bool, dim_pre_vars, dim_z, z_i) );
        return var;
    }

    boost::shared_ptr<IMixedSystem> createSystemFunction(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> algLoopSolverFactory, boost::shared_ptr<ISimData> simData,boost::shared_ptr<ISimVars> simVars)
    {
        boost::shared_ptr<IMixedSystem> system( new <%lastIdentOfPath(modelInfo.name)%>Extension(globalSettings, algLoopSolverFactory, simData,simVars) );
        return system;
    }

  #else

  BOOST_EXTENSION_TYPE_MAP_FUNCTION
  {
    typedef boost::extensions::factory<IMixedSystem,IGlobalSettings*, boost::shared_ptr<IAlgLoopSolverFactory>, boost::shared_ptr<ISimData>, boost::shared_ptr<ISimVars> > system_factory;
    types.get<std::map<std::string, system_factory> >()["<%lastIdentOfPath(modelInfo.name)%>"]
      .system_factory::set<<%lastIdentOfPath(modelInfo.name)%>Extension>();
  }
  #endif
  >>
end simulationFactoryFile;



template simulationInitCppFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
   <<
   <%algloopfilesInclude(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>

   <%lastIdentOfPath(modelInfo.name)%>Initialize::<%lastIdentOfPath(modelInfo.name)%>Initialize(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
   : <%lastIdentOfPath(modelInfo.name)%>(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
   {
   }

   <%lastIdentOfPath(modelInfo.name)%>Initialize::~<%lastIdentOfPath(modelInfo.name)%>Initialize()
   {
   }

   <%getIntialStatus(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)%>
   <%setIntialStatus(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)%>

   <%init(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
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
   let init10  = initValstWithSplit(varDecls10, "Real", '<%lastIdentOfPath(modelInfo.name)%>Initialize::initializeParameterVars', vars.paramVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
   let init11  = initValstWithSplit(varDecls11, "Int", '<%lastIdentOfPath(modelInfo.name)%>Initialize::initializeIntParameterVars', vars.intParamVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
   let init12  = initValstWithSplit(varDecls12, "Bool", '<%lastIdentOfPath(modelInfo.name)%>Initialize::initializeBoolParameterVars', vars.boolParamVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
    let init13  = initValstWithSplit(varDecls12, "String", '<%lastIdentOfPath(modelInfo.name)%>Initialize::initializeStringParameterVars', vars.stringParamVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
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

template simulationInitAliasVarsCppFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(__) then
match modelInfo
case modelInfo as MODELINFO(vars=SIMVARS(__))  then

   let &varDecls8 = buffer "" /*BUFD*/
   let &varDecls9 = buffer "" /*BUFD*/
   let &varDecls10 = buffer "" /*BUFD*/
   let &varDecls11 = buffer "" /*BUFD*/
   let init7   = initAliasValstWithSplit("Real", '<%lastIdentOfPath(modelInfo.name)%>Initialize::initializeAliasVars', vars.aliasVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
   let init8   = initAliasValst(varDecls8, "Int", vars.intAliasVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
   let init9   = initValst(varDecls9, "Bool",vars.boolAliasVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
   let init10   = initStringAliasValstWithSplit("String", '<%lastIdentOfPath(modelInfo.name)%>Initialize::initializeStringAliasVars', vars.stringAliasVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)


  <<

    <%init7%>
    /*string alias*/
    <%init10%>


    void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeIntAliasVars()
    {
       <%varDecls8%>
       <%init8%>
    }
    void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeBoolAliasVars()
    {
      <%varDecls9%>
       <%init9%>
    }


   >>

end simulationInitAliasVarsCppFile;


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
   let init3   = initValstWithSplit(varDecls3, "Real", '<%lastIdentOfPath(modelInfo.name)%>Initialize::initializeAlgVars', vars.algVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
   let init4   = initValst(varDecls4, "Real", vars.discreteAlgVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace,contextOther, stateDerVectorName, useFlatArrayNotation)
   let init5   = initValstWithSplit(varDecls5, "Int", '<%lastIdentOfPath(modelInfo.name)%>Initialize::initializeIntAlgVars', vars.intAlgVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
   let init6   = initValst(varDecls6, "Bool", vars.boolAlgVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
   //let init7  = initValstWithSplit(varDecls3, "String", '<%lastIdentOfPath(modelInfo.name)%>Initialize::initializeStringAlgVars', vars.stringParamVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
   <<

     <%init3%>

   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeDiscreteAlgVars()
   {
      <%varDecls4%>
      <%init4%>
   }

   <%init5%>

    void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeBoolAlgVars()
   {
       <%varDecls6%>
       <%init6%>
   }
   >>

end simulationInitAlgVarsCppFile;


template simulationInitExtVarsCppFile(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
  initExtVars(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
end simulationInitExtVarsCppFile;


template simulationJacobianCppFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
   let initialjacMats = (jacobianMatrixes |> (mat, vars, name, (sparsepattern,_), colorList, _, jacIndex) =>
    initialAnalyticJacobians(jacIndex, mat, vars, name, sparsepattern, colorList,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
    ;separator="";empty)
   <<

   <% (jacobianMatrixes |> (mat, _, _, _, _, _, _) hasindex index0 =>
       (mat |> (eqs,_,_) =>  algloopfilesInclude(eqs,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator="")
     ;separator="")
   %>
   <%lastIdentOfPath(modelInfo.name)%>Jacobian::<%lastIdentOfPath(modelInfo.name)%>Jacobian(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
       : <%lastIdentOfPath(modelInfo.name)%>(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
       , _AColorOfColumn(NULL)
       <%jacobiansVariableInit(jacobianMatrixes,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
       <%initialjacMats%>
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

   <%lastIdentOfPath(modelInfo.name)%>StateSelection::<%lastIdentOfPath(modelInfo.name)%>StateSelection(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
       : <%lastIdentOfPath(modelInfo.name)%>(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
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


   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::<%lastIdentOfPath(modelInfo.name)%>WriteOutput(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
       : <%lastIdentOfPath(modelInfo.name)%>(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
   {
     _historyImpl = new HistoryImplType(*globalSettings);
   }

   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::~<%lastIdentOfPath(modelInfo.name)%>WriteOutput()
   {
     delete _historyImpl;
   }

   IHistory* <%lastIdentOfPath(modelInfo.name)%>WriteOutput::getHistory()
   {
     return _historyImpl;
   }

   void <%lastIdentOfPath(modelInfo.name)%>WriteOutput::initialize()
   {
      _historyImpl->init();


      _historyImpl->clear();
   }
   <%writeoutput(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
   >>
end simulationWriteOutputCppFile;
 /*
 map<unsigned int,string> var_ouputs_idx;
      <%outputIndices(modelInfo)%>
      _historyImpl->setOutputs(var_ouputs_idx);
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

template simulationExtensionCppFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(vars=SIMVARS(__))) then
  let classname = lastIdentOfPath(modelInfo.name)
   <<

   <%classname%>Extension::<%classname%>Extension(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
       : <%classname%>(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
       , <%classname%>WriteOutput(globalSettings,nonlinsolverfactory, sim_data,sim_vars)
       , <%classname%>Initialize(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
       , <%classname%>Jacobian(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
       , <%classname%>StateSelection(globalSettings, nonlinsolverfactory, sim_data,sim_vars)

   {
   }

   <%classname%>Extension::~<%classname%>Extension()
   {
   }

   bool <%classname%>Extension::initial()
   {
      return <%classname%>Initialize::initial();
   }
   void <%classname%>Extension::setInitial(bool value)
   {
      <%classname%>Initialize::setInitial(value);
   }

   void <%classname%>Extension::initialize()
   {
     <%classname%>WriteOutput::initialize();
     <%classname%>Initialize::initialize();
     <%classname%>Jacobian::initialize();

     <%classname%>Jacobian::initializeColoredJacobianA();
   }

   void <%classname%>Extension::getJacobian(SparseMatrix& matrix)
   {
     getAJacobian(matrix);

   }

   void <%classname%>Extension::getStateSetJacobian(unsigned int index,SparseMatrix& matrix)
   {
     switch (index)
     {
       <%(stateSets |> set hasindex i1 fromindex 0 => (match set
       case set as SES_STATESET(__) then
       match jacobianMatrix case (_,_,name,_,_,_,_) then
       <<
       case <%i1%>:
         get<%name%>Jacobian(matrix);
         break;
       >>
       )
       ;separator="\n")
       %>
       default:
          throw ModelicaSimulationError(MATH_FUNCTION,"Not supported statset index");
      }
   }

   bool <%classname%>Extension::handleSystemEvents(bool* events)
   {
     return <%classname%>::handleSystemEvents(events);
   }

   void <%classname%>Extension::saveAll()
   {
     return <%classname%>::saveAll();
   }

   void <%classname%>Extension::initEquations()
   {
     <%classname%>Initialize::initEquations();
   }

   void <%classname%>Extension::writeOutput(const IWriteOutput::OUTPUT command)
   {
     <%classname%>WriteOutput::writeOutput(command);
   }

   IHistory* <%classname%>Extension::getHistory()
   {
     return <%classname%>WriteOutput::getHistory();
   }

   int <%classname%>Extension::getDimStateSets() const
   {
     return <%classname%>StateSelection::getDimStateSets();
   }

   int <%classname%>Extension::getDimStates(unsigned int index) const
   {
     return <%classname%>StateSelection::getDimStates(index);
   }

   int <%classname%>Extension::getDimCanditates(unsigned int index) const
   {
     return <%classname%>StateSelection::getDimCanditates(index);
   }

   int <%classname%>Extension::getDimDummyStates(unsigned int index) const
   {
     return <%classname%>StateSelection::getDimDummyStates(index);
   }

   void <%classname%>Extension::getStates(unsigned int index,double* z)
   {
     <%classname%>StateSelection::getStates(index,z);
   }

   void <%classname%>Extension::setStates(unsigned int index,const double* z)
   {
     <%classname%>StateSelection::setStates(index,z);
   }

   void <%classname%>Extension::getStateCanditates(unsigned int index,double* z)
   {
     <%classname%>StateSelection::getStateCanditates(index,z);
   }

   bool <%classname%>Extension::getAMatrix(unsigned int index,DynArrayDim2<int> & A)
   {
     return <%classname%>StateSelection::getAMatrix(index,A);
   }

   void <%classname%>Extension::setAMatrix(unsigned int index,DynArrayDim2<int> & A)
   {
     <%classname%>StateSelection::setAMatrix(index,A);
   }

   bool <%classname%>Extension::getAMatrix(unsigned int index,DynArrayDim1<int> & A)
   {
     return <%classname%>StateSelection::getAMatrix(index,A);
   }

   void <%classname%>Extension::setAMatrix(unsigned int index,DynArrayDim1<int> & A)
   {
     <%classname%>StateSelection::setAMatrix(index,A);
   }

   /*needed for colored jacobians*/

   void <%classname%>Extension::getAColorOfColumn(int* aSparsePatternColorCols, int size)
   {
    memcpy(aSparsePatternColorCols, _AColorOfColumn, size * sizeof(int));
   }

   int <%classname%>Extension::getAMaxColors()
   {
    return _AMaxColors;
   }

   /*********************************************************************************************/

   string <%classname%>Extension::getModelName()
   {
    return "<%fileNamePrefix%>";
   }
   >>
end simulationExtensionCppFile;


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

template crefType(ComponentRef cr) "template crefType
  Like cref but with cast if type is integer."
::=
  match cr
    case CREF_IDENT(__) then '<%expTypeFlag(identType,6)%>'
    case CREF_QUAL(__)  then '<%crefType(componentRef)%>'
    else "crefType:ERROR"
  end match
end crefType;


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
    let solver    = settings.method
    let moLib     =  makefileParams.compileDir
    let home      = makefileParams.omhome
    let execParameters = '-s <%start%> -e <%end%> -f <%stepsize%> -v <%intervals%> -y <%tol%> -i <%solver%> -r <%simulationLibDir(simulationCodeTarget(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%> -m <%moLib%> -R <%simulationResults(getRunningTestsuite(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%> -o <%settings.outputFormat%>'
    let fileNamePrefixx = fileNamePrefix

    let libFolder =simulationLibDir(simulationCodeTarget(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
    let libPaths = makefileParams.libPaths |> path => path; separator=";"

    match makefileParams.platform
      case  "linux32"
      case  "linux64" then
        <<
        #!/bin/sh
        <%preRunCommandLinux%>
        <%execCommandLinux%> ./<%fileNamePrefixx%> <%execParameters%> $*
        >>
      case  "win32"
      case  "win64" then
        <<
        @echo off
        <%preRunCommandWindows%>
        REM ::export PATH=<%libFolder%>:$PATH REPLACE C: with /C/
        SET PATH=<%home%>/bin;<%libFolder%>;<%libPaths%>;%PATH%
        <%moLib%>/<%fileNamePrefixx%>.exe <%execParameters%>
        >>
    end match
  end match
end simulationMainRunScript;


template simulationLibDir(String target, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates code for header file for simulation target."
::=
  match target
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
                            String numRealVars, String numIntVars, String numBoolVars, String numPreVars)
 "Generates code for header file for simulation target."
::=
match target

case "vxworks69" then
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
let modelname = identOfPath(modelInfo.name)

<<
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <stdio.h>
#include <string>

#include <Core/DataExchange/SimDouble.h>
#include <Core/DataExchange/SimBoolean.h>
#include <Core/SimController/ISimController.h>

#include <wvLib.h>
#define PATH string


#include <util/bundle.h>
#include <util/vxwHelper.h>
#include <util/wchar16.h>

#include <mlpiApiLib.h>
#include <mlpiSystemLib.h>
#include <mlpiTaskLib.h>
#include <mlpiLogicLib.h>
#include <mlpiParameterLib.h>


extern "C" ISimController* createSimController(PATH library_path, PATH modelicasystem_path);

extern "C"  int runSimulation(void)
{
  // Enable Telnet and Floatingpoint Unit
  enableTelnetPrintf();
  enableFpuSupport();

  // Wait 10 seconds
  timespec delay;
  delay.tv_sec = 10;
  delay.tv_nsec = 0;
  nanosleep( &delay ,NULL);

  MLPIHANDLE connection = MLPI_INVALIDHANDLE;

  MLPIRESULT result;

  // connect to API
  result = mlpiApiConnect(MLPI_LOCALHOST, &connection); // replace localhost with control IP to connect to another control
  if (MLPI_FAILED(result))
  {
    printf("\nERROR: failed to connect to MLPI. ErrorCode: 0x%08x", (unsigned) result);

    //////////////////////////////////////
    //  Place error handling here       //
    //////////////////////////////////////

    return result;
  }

  // Get MotionCycle time
  ULONG cycletime_us = 0;
  result = mlpiParameterReadDataUlong(connection, 0, MLPI_SIDN_C(400), &cycletime_us);
  if (MLPI_FAILED(result))
  {
    printf("\nERROR: failed to connect to MLPI. ErrorCode: 0x%08x", (unsigned) result);

    //////////////////////////////////////
    //  Place error handling here       //
    //////////////////////////////////////

    return result;
  }

  // Convert mu_s to s
  double cycletime = (double)cycletime_us/(1e6);

  /*
  =============================================================================================================
  ==                 Initialization of SimCore
  =============================================================================================================
  */
  wvEvent(0,NULL,0);
  printf("runSimulation started");

  PATH libraries_path = "";
  PATH modelicaSystem_path = "";
  boost::shared_ptr<VxWorksFactory> factory = boost::shared_ptr<VxWorksFactory>(new VxWorksFactory(libraries_path, modelicaSystem_path));
  ISimController* sim_controller = createSimController(libraries_path, modelicaSystem_path);
  boost::weak_ptr<ISimData> simData = sim_controller->LoadSimData("model2");
  boost::weak_ptr<IMixedSystem> system = sim_controller->LoadSystem("model2","model2");
  boost::shared_ptr<ISimData> simData_shared = simData.lock();



  // Declare Input specify initial_values if needed!!!
  <%defineInputVars(simCode)%>

  // Declare Output
  <%defineOutputVars(simCode)%>


  // Set simulation Settings: mainly stepsize important
    SimSettings settings = {"RTEuler","","Kinsol",        0.0,      100.0,  cycletime,      0.0025,      10.0,         0.0001, "model2",EMPTY, 100,EMPTY2, OFF};
  //                       Solver,          nonlinearsolver starttime endtime stepsize   lower limit upper limit  tolerance
  try
  {
    sim_controller->StartVxWorks(settings, "model2");
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
    //////////////////////////////////////
    //  Place error handling here       //
    //////////////////////////////////////
    }


    return -1;
  }
  printf("StartVxWorks finished");
  wvEvent(1,NULL,0);




  result = mlpiSystemSetTargetMode(connection, MLPI_SYSTEMMODE_P2);
  if (MLPI_FAILED(result))
  {
    printf("\ncall of MLPI function failed with 0x%08x!", (unsigned)result);
    //////////////////////////////////////
    //  Place error handling here       //
    //////////////////////////////////////
    return result;
  }



  // Set Priority of Task
  result = mlpiTaskSetCurrentPriority(connection,  MLPI_PRIORITY_HIGH_MAX );
  if (MLPI_FAILED(result))
  {
    printf("\ncall of MLPI function failed with 0x%08x!", (unsigned)result);
    //////////////////////////////////////
    //  Place error handling here       //
    //////////////////////////////////////
    return result;
  }

  MlpiSystemMode mode;
  // run simulation
  while(true)
  {

    // Wait for motion interrupt
    result = mlpiTaskWaitForEvent(connection, MLPI_TASKEVENT_MOTION_CYCLE, MLPI_INFINITE);
    if (MLPI_FAILED(result))
    {
      printf("\ncall of MLPI function failed with 0x%08x!", (unsigned)result);
      //////////////////////////////////////
      //  Place error handling here       //
      //////////////////////////////////////
      return result;
    }
    // Get Current Mode of PLC
    result = mlpiSystemGetCurrentMode(connection, &mode);
    if (MLPI_FAILED(result))
    {
      printf("\ncall of MLPI function failed with 0x%08x!", (unsigned)result);
      //////////////////////////////////////
      //  Place error handling here       //
      //////////////////////////////////////
      return result;
    }


    // Only compute one step if PLC is in mode P4
    if(mode == MLPI_SYSTEMMODE_BB) //
    {
      //Write input
      /* do something with the inputs!*/
      /*
      <%setInputVars(simCode)%>
      */

      //Calculate one step
      try
      {
        sim_controller->calcOneStep();
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
          //////////////////////////////////////
          //  Place error handling here       //
          //////////////////////////////////////

        }
        return -1;
        }

      //Write output
      <%getOutputVars(simCode)%>

    }
  }

  delete sim_controller;

  result = mlpiApiDisconnect(&connection);
  {
    //////////////////////////////////////
    //  Place error handling here       //
    //////////////////////////////////////
    return result;
  }
  return 0;
}






BUNDLE_INFO_BEGIN(com_boschrexroth_<%modelname%>)
BUNDLE_INFO_NAME (L"LoadLibraries_Bundle")
BUNDLE_INFO_VENDOR (L"Bosch Rexroth AG")
BUNDLE_INFO_DESCRIPTION (L"Load Libraries of SimCore Bundle")
BUNDLE_INFO_VERSION (1,0,0,0,L"Release 20140114")
BUNDLE_INFO_END(com_boschrexroth_<%modelname%>)

BUNDLE_EXPORT int com_boschrexroth_<%modelname%>_create(int param1, int param2, int param3)
{
printf("\n###################################################################");
printf("\n## onCreate #######################################################");
printf("\n###################################################################");
return 0;
}

BUNDLE_EXPORT int com_boschrexroth_<%modelname%>_start(int param1, int param2, int param3)
{
taskSpawn(  "<%lastIdentOfPath(modelInfo.name)%>",           // name of task
      200,                      // priority of task
      VX_FP_TASK,                         // options (executes with the floating-point coprocessor)
      0x200000,               // stacksize
      (FUNCPTR)& runSimulation,        // entry point (function)
      0,                   // arguments 1
      0,                  // arguments 2
      0,                                  // arguments 3
      0,                                  // arguments 4
      0,                                  // arguments 5
      0,                                  // arguments 6
      0,                                  // arguments 7
      0,                                  // arguments 8
      0,                                  // arguments 9
      0);                                 // arguments 10

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
  <<
  #include <Core/ModelicaDefine.h>
  #include <Core/Modelica.h>
  #include <Core/SimController/ISimController.h>
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
      opts["-s"] = "<%start%>";
      opts["-e"] = "<%end%>";
      opts["-f"] = "<%stepsize%>";
      opts["-v"] = "<%intervals%>";
      opts["-y"] = "<%tol%>";
      opts["-i"] = "<%solver%>";
      opts["-r"] = "<%simulationLibDir(simulationCodeTarget(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>";
      opts["-m"] = "<%moLib%>";
      opts["-R"] = "<%simulationResults(getRunningTestsuite(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>";
      opts["-o"] = "<%settings.outputFormat%>";

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
            <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
                <<
                std::vector<MeasureTimeData> measureTimeArraySimulation = std::vector<MeasureTimeData>(2); //0 all, 1 setup
                MeasureTimeValues *measuredSimStartValues, *measuredSimEndValues, *measuredSetupStartValues, *measuredSetupEndValues;

                MeasureTime::addResultContentBlock("<%dotPath(modelInfo.name)%>","main",&measureTimeArraySimulation);

                measuredSimStartValues = MeasureTime::getZeroValues();
                measuredSimEndValues = MeasureTime::getZeroValues();
                measuredSetupStartValues = MeasureTime::getZeroValues();
                measuredSetupEndValues = MeasureTime::getZeroValues();

                measureTimeArraySimulation[0] = MeasureTimeData("all");
                measureTimeArraySimulation[1] = MeasureTimeData("setup");

                <%generateMeasureTimeStartCode('measuredSimStartValues', "all", "")%>
                <%generateMeasureTimeStartCode('measuredSetupStartValues', "setup", "")%>
                >>
            %>
            <%additionalPreRunCommands%>

            #ifdef RUNTIME_STATIC_LINKING
              boost::shared_ptr<StaticOMCFactory>  _factory =  boost::shared_ptr<StaticOMCFactory>(new StaticOMCFactory());
            #else
              boost::shared_ptr<OMCFactory>  _factory =  boost::shared_ptr<OMCFactory>(new OMCFactory());
            #endif
            //SimController to start simulation

            std::pair<boost::shared_ptr<ISimController>, SimSettings> simulation = _factory->createSimulation(argc, argv, opts);
            Logger::initialize(simulation.second.logSettings);

            //create Modelica system
            boost::weak_ptr<ISimData> simData = simulation.first->LoadSimData("<%lastIdentOfPath(modelInfo.name)%>");
            boost::weak_ptr<ISimVars> simVars = simulation.first->LoadSimVars("<%lastIdentOfPath(modelInfo.name)%>",<%numRealVars%>,<%numIntVars%>,<%numBoolVars%>,<%numPreVars%>,<%numStatevars(modelInfo)%>,<%numStateVarIndex(modelInfo)%>);
            boost::weak_ptr<IMixedSystem> system = simulation.first->LoadSystem("OMCpp<%fileNamePrefix%><%makefileParams.dllext%>","<%lastIdentOfPath(modelInfo.name)%>");
            <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
              <<
              <%generateMeasureTimeEndCode("measuredSetupStartValues", "measuredSetupEndValues", "measureTimeArraySimulation[1]", "setup", "")%>
              >>
            %>
            simulation.first->Start(simulation.second, "<%lastIdentOfPath(modelInfo.name)%>");

            <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
              <<
              <%generateMeasureTimeEndCode("measuredSimStartValues", "measuredSimEndValues", "measureTimeArraySimulation[0]", "all", "")%>
              MeasureTime::getInstance()->writeToJson();
              >>
            %>

            return 0;

      }
      catch(ModelicaSimulationError& ex)
      {

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
      boost::shared_ptr<SimDouble> sim_value_in<%cref(name, false)%>(new SimDouble(0.0)/*set start value here*/);
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
      (dynamic_cast<SimDouble*>(simData_shared->Get("<%cref(name, false)%>")))->getValue()   = //place variable here ;
      >>
      ;separator="\n"

    <<
    <%inputnames%>
        >>

  <<
  <%inputs%>
  >>

end setInputVars;

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
      boost::shared_ptr<SimDouble> sim_value_out<%cref(name, false)%>(new SimDouble(0.0));
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
      place variable here  = dynamic_cast<SimDouble*>simData_shared->Get("<%cref(name, false)%>"))->getValue();
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
    #include <Core/DataExchange/SimData.h>
    #include <Core/DataExchange/XmlPropertyReader.h>
    #include <Core/System/SimVars.h>
    #include <Core/System/DiscreteEvents.h>
    #include <Core/System/EventHandling.h>

    #include "OMCpp<%fileNamePrefix%>Types.h"
    #include "OMCpp<%fileNamePrefix%>.h"
    #include "OMCpp<%fileNamePrefix%>Functions.h"
    #include "OMCpp<%fileNamePrefix%>Jacobian.h"
    #include "OMCpp<%fileNamePrefix%>StateSelection.h"
    #include "OMCpp<%fileNamePrefix%>WriteOutput.h"
    #include "OMCpp<%fileNamePrefix%>Initialize.h"
    #include "OMCpp<%fileNamePrefix%>Extension.h"

    #include "OMCpp<%fileNamePrefix%>AlgLoopMain.cpp"
    #include "OMCpp<%fileNamePrefix%>FactoryExport.cpp"
    #include "OMCpp<%fileNamePrefix%>Extension.cpp"
    #include "OMCpp<%fileNamePrefix%>Functions.cpp"
    #include "OMCpp<%fileNamePrefix%>InitializeParameter.cpp"
    #include "OMCpp<%fileNamePrefix%>InitializeAlgVars.cpp"
    #include "OMCpp<%fileNamePrefix%>InitializeAliasVars.cpp"
    #include "OMCpp<%fileNamePrefix%>InitializeExtVars.cpp"
    #include "OMCpp<%fileNamePrefix%>Initialize.cpp"
    #include "OMCpp<%fileNamePrefix%>WriteOutput.cpp"
    #include "OMCpp<%fileNamePrefix%>WriteOutputAlgVars.cpp"
    #include "OMCpp<%fileNamePrefix%>WriteOutputParameter.cpp"
    #include "OMCpp<%fileNamePrefix%>WriteOutputAliasVars.cpp"
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

template simulationTypesHeaderFile(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, list<Function> functions, list<Exp> literals, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
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
  //external functions
  extern "C" {
    <%externfunctionHeaderDefinition(functions)%>
  }
  <%functionHeaderBodies1(functions,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
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
  //external functions
  extern "C" {
    <%externfunctionHeaderDefinition(functions)%>
  }

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
  let arrayexpression1 = (if instDims then 'StatArrayDim<%listLength(instDims)%><<%expTypeShort(var.ty)%>,<%instDimsInit%>> <%varName%>;<%\n%>'
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
match target
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
  # /Od - Optimization disabled
  # /EHa enable C++ EH (w/ SEH exceptions)
  # /fp:except - consider floating-point exceptions when generating code
  # /arch:SSE2 - enable use of instructions available with SSE2 enabled CPUs
  # /I - Include Directories
  # /DNOMINMAX - Define NOMINMAX (does what it says)
  # /TP - Use C++ Compiler
  !IF "$(PCH_FILE)" == ""
  CFLAGS=  $(SYSTEM_CFLAGS) /I"<%makefileParams.omhome%>/include/omc/cpp/" /I. <%makefileParams.includes%>  /I"$(BOOST_INCLUDE)" /I"$(UMFPACK_INCLUDE)" /DNOMINMAX /TP /DNO_INTERACTIVE_DEPENDENCY <%additionalCFlags_MSVC%>
  !ELSE
  CFLAGS=  $(SYSTEM_CFLAGS) /I"<%makefileParams.omhome%>/include/omc/cpp/" /I. <%makefileParams.includes%>  /I"$(BOOST_INCLUDE)" /I"$(UMFPACK_INCLUDE)" /DNOMINMAX /TP /DNO_INTERACTIVE_DEPENDENCY  /Fp<%makefileParams.omhome%>/include/omc/cpp/Core/$(PCH_FILE)  /YuCore/$(H_FILE) <%additionalCFlags_MSVC%>
  !ENDIF
  CPPFLAGS =
  # /ZI enable Edit and Continue debug info
  CDFLAGS = /ZI

  # /MD - link with MSVCRT.LIB
  # /link - [linker options and libraries]
  # /LIBPATH: - Directories where libs can be found
  #LDFLAGS=/MDd   /link /DLL /NOENTRY /LIBPATH:"<%makefileParams.omhome%>/lib/<%getTriple()%>/omc/cpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)" OMCppSystem.lib OMCppMath.lib
  #LDSYSTEMFLAGS=/MD /Debug  /link /DLL /NOENTRY /LIBPATH:"<%makefileParams.omhome%>/lib/<%getTriple()%>/omc/cpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)" OMCppSystem.lib OMCppModelicaUtilities.lib  OMCppMath.lib   OMCppOMCFactory.lib
  LDSYSTEMFLAGS=  /link /DLL /NOENTRY /LIBPATH:"<%makefileParams.omhome%>/lib/<%getTriple()%>/omc/cpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)" OMCppSystem.lib OMCppModelicaUtilities.lib  OMCppMath.lib OMCppDataExchange_static.lib  OMCppOMCFactory_static.lib <%timeMeasureLink%>
  #LDMAINFLAGS=/MD /Debug  /link /LIBPATH:"<%makefileParams.omhome%>/lib/<%getTriple()%>/omc/cpp/msvc" OMCppOMCFactory.lib  /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)"
  LDMAINFLAGS=/link /LIBPATH:"<%makefileParams.omhome%>/lib/<%getTriple()%>/omc/cpp/msvc" OMCppOMCFactory_static.lib OMCppModelicaUtilities.lib <%timeMeasureLink%> /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)"
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
            let staticLibs = '-Wl,--start-group -lOMCppOMCFactory_static -lOMCppSystem_static -lOMCppSimController_static -Wl,--end-group -lOMCppSimulationSettings_static -lOMCppNewton_static -lOMCppEuler_static -lOMCppKinsol_static -lOMCppCVode_static -lOMCppSolver_static -lOMCppMath_static -lOMCppModelicaUtilities_static -lOMCppExtensionUtilities_static -L$(SUNDIALS_LIBS) -L$(UMFPACK_LIBS) -L$(LAPACK_LIBS)'
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
            include $(OMHOME)/include/omc/cpp/ModelicaLibraryConfig.inc
            # Simulations use -O0 by default
            SIM_OR_DYNLOAD_OPT_LEVEL=-O0
            CC=<%CC%>
            CXX=<%CXX%>
            RUNTIME_STATIC_LINKING=<%if(Flags.isSet(Flags.RUNTIME_STATIC_LINKING)) then 'ON' else 'OFF'%>
            <%MPIEnvVars%>

            EXEEXT=<%makefileParams.exeext%>
            DLLEXT=<%makefileParams.dllext%>

            CFLAGS_COMMON=<%extraCflags%> -Winvalid-pch $(SYSTEM_CFLAGS) -I"$(SCOREP_INCLUDE)" -I"$(OMHOME)/include/omc/cpp/" -I. <%makefileParams.includes%> -I"$(BOOST_INCLUDE)" -I"$(UMFPACK_INCLUDE)" <%makefileParams.includes ; separator=" "%> <%match sopt case SOME(s as SIMULATION_SETTINGS(__)) then s.cflags %> <%additionalCFlags_GCC%> <%extraCppFlags%>

            ifeq ($(USE_SCOREP),ON)
            $(eval CC=scorep --user --nocompiler $(CC))
            $(eval CXX=scorep --user --nocompiler $(CXX))
            else
            $(eval CFLAGS_COMMON=$(CFLAGS_COMMON) -DMEASURETIME_PROFILEBLOCKS)
            endif

            CFLAGS_DYNAMIC=$(CFLAGS_COMMON)
            CFLAGS_STATIC=$(CFLAGS_COMMON) <%staticIncludes%> -DRUNTIME_STATIC_LINKING

            MODELICA_EXTERNAL_LIBS=-lModelicaExternalC -lModelicaStandardTables -L$(LAPACK_LIBS) $(LAPACK_LIBRARIES)

            LDSYSTEMFLAGS_COMMON=-L"$(OMHOME)/lib/<%getTriple()%>/omc/cpp" $(BASE_LIB) <%additionalLinkerFlags_GCC%> -lOMCppDataExchange_static -Wl,-rpath,"$(OMHOME)/lib/<%getTriple()%>/omc/cpp" <%timeMeasureLink%> -L"$(BOOST_LIBS)" $(BOOST_LIBRARIES) $(LINUX_LIB_DL)
            LDMAINFLAGS_COMMON=-L"$(OMHOME)/lib/<%getTriple()%>/omc/cpp" -L"$(OMHOME)/bin" -L"$(BOOST_LIBS)" $(BOOST_LIBRARIES) $(LINUX_LIB_DL) <%additionalLinkerFlags_GCC%>  -lOMCppDataExchange_static -Wl,-rpath,"$(OMHOME)/lib/<%getTriple()%>/omc/cpp"

            ifeq ($(USE_PAPI),ON)
            $(eval LDMAINFLAGS_COMMON=$(LDMAINFLAGS_COMMON) <%papiLibs%>)
            $(eval LDSYSTEMFLAGS_COMMON=$(LDSYSTEMFLAGS_COMMON) <%papiLibs%>)
            endif

            LDSYSTEMFLAGS_DYNAMIC=-lOMCppSystem -lOMCppModelicaUtilities -lOMCppMath -lOMCppExtensionUtilities -lOMCppOMCFactory $(LDSYSTEMFLAGS_COMMON)
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

            <%if boolNot(stringEq(makefileParams.platform, "win32")) then
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


      WIND_HOME := $(subst \,/,$(WIND_HOME))
      WIND_BASE := $(subst \,/,$(WIND_BASE))

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
      TOOL_PATH =
      CC_ARCH_SPEC = -march=atom -nostdlib -fno-builtin -fno-defer-pop -fno-implicit-fp
      VSB_DIR = $(WIND_BASE)/target/lib
      VSB_CONFIG_FILE = $(VSB_DIR)/h/config/vsbConfig.h
      LIBPATH =
      LIBS =

      IDE_INCLUDES = -I$(WIND_BASE)/target/h -I$(WIND_BASE)/target/h/wrn/coreip -ID:/Windriver_Projekte/1.10.1.0/mlpiCore/include -IC:/OMdev/lib/3rdParty/boost-1_49 -IC:/cpp_runtime_for_xm22/Include/SimCoreFactory -IC:/cpp_runtime_for_xm22/Include/Core -IC:/cpp_runtime_for_xm22/Include/

      IDE_LIBRARIES = C:/wb335_BoschOEM/workspace/MATH_BIB/ATOMgnu/MATH_BIB/Debug/MATH_BIB.a C:/wb335_BoschOEM/workspace/ModelicaExternalC/ATOMgnu/ModelicaExternalC/Debug/ModelicaExternalC.a C:/wb335_BoschOEM/workspace/Math/ATOMgnu/Math/Debug/Math.a C:/wb335_BoschOEM/workspace/VxWorksFactory/ATOMgnu/VxWorksFactory/Debug/VxWorksFactory.a C:/wb335_BoschOEM/workspace/SimController/ATOMgnu/SimulationController/Debug/SimulationController.a C:/wb335_BoschOEM/workspace/DataExchange/ATOMgnu/DataExchange/Debug/DataExchange.a C:/wb335_BoschOEM/workspace/SimulationSettings/ATOMgnu/SimulationSettings/Debug/SimulationSettings.a C:/wb335_BoschOEM/workspace/Solver/ATOMgnu/Solver/Debug/Solver.a C:/wb335_BoschOEM/workspace/System/ATOMgnu/System/Debug/System.a C:/wb335_BoschOEM/workspace/RTSolver/ATOMgnu/RTSolver/Debug/RTSolver.a C:/wb335_BoschOEM/workspace/Kinsol_Sources/ATOMgnu/Kinsol_Sources/Debug/Kinsol_Sources.a C:/wb335_BoschOEM/workspace/Kinsol/ATOMgnu/Kinsol/Debug/Kinsol.a

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
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : IDE_INCLUDES = -I$(WIND_BASE)/target/h -I$(WIND_BASE)/target/h/wrn/coreip -ID:/Windriver_Projekte/1.10.1.0/mlpiCore/include -IC:/OMdev/lib/3rdParty/boost-1_49 -IC:/cpp_runtime_for_xm22/Include/SimCoreFactory -IC:/cpp_runtime_for_xm22/Include/Core -IC:/cpp_runtime_for_xm22/Include/
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : IDE_LIBRARIES = C:/wb335_BoschOEM/workspace/MATH_BIB/ATOMgnu/MATH_BIB/Debug/MATH_BIB.a C:/wb335_BoschOEM/workspace/ModelicaExternalC/ATOMgnu/ModelicaExternalC/Debug/ModelicaExternalC.a C:/wb335_BoschOEM/workspace/Math/ATOMgnu/Math/Debug/Math.a C:/wb335_BoschOEM/workspace/VxWorksFactory/ATOMgnu/VxWorksFactory/Debug/VxWorksFactory.a C:/wb335_BoschOEM/workspace/SimController/ATOMgnu/SimulationController/Debug/SimulationController.a C:/wb335_BoschOEM/workspace/DataExchange/ATOMgnu/DataExchange/Debug/DataExchange.a C:/wb335_BoschOEM/workspace/SimulationSettings/ATOMgnu/SimulationSettings/Debug/SimulationSettings.a C:/wb335_BoschOEM/workspace/Solver/ATOMgnu/Solver/Debug/Solver.a C:/wb335_BoschOEM/workspace/System/ATOMgnu/System/Debug/System.a C:/wb335_BoschOEM/workspace/RTSolver/ATOMgnu/RTSolver/Debug/RTSolver.a C:/wb335_BoschOEM/workspace/Kinsol_Sources/ATOMgnu/Kinsol_Sources/Debug/Kinsol_Sources.a C:/wb335_BoschOEM/workspace/Kinsol/ATOMgnu/Kinsol/Debug/Kinsol.a
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : IDE_DEFINES = -DCPU=_VX_$(CPU) -DTOOL_FAMILY=$(TOOL_FAMILY) -DTOOL=$(TOOL) -D_WRS_KERNEL -D_VSB_CONFIG_FILE=\"$(VSB_DIR)/h/config/vsbConfig.h\"
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : PROJECT_TYPE = DKM
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : DEFINES =
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : EXPAND_DBG = 0
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : VX_CPU_FAMILY = pentium
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : CPU = ATOM
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : TOOL_FAMILY = gnu
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : TOOL = gnu
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : TOOL_PATH =
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : CC_ARCH_SPEC = -march=atom -nostdlib -fno-builtin -fno-defer-pop -fno-implicit-fp
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : VSB_DIR = $(WIND_BASE)/target/lib
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : VSB_CONFIG_FILE = $(VSB_DIR)/h/config/vsbConfig.h
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : LIBPATH =
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : LIBS =
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/% : OBJ_DIR := com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)

      OBJECTS_com.boschrexroth.$(MODEL_NAME) = com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME)_partialImage.o

      ifeq ($(TARGET_JOBS),1)
      com.boschrexroth.$(MODEL_NAME)/$(MODE_DIR)/com.boschrexroth.$(MODEL_NAME).out : $(OBJECTS_com.boschrexroth.$(MODEL_NAME))
      <%\t%>$(TRACE_FLAG)if [ ! -d "`dirname "$@"`" ]; then mkdir -p "`dirname "$@"`"; fi;echo "building $@";rm -f "$@";nmpentium $(OBJECTS_com.boschrexroth.$(MODEL_NAME)) | tclsh $(WIND_BASE)/host/resource/hutils/tcl/munch.tcl -c pentium -tags $(VSB_DIR)/tags/pentium/ATOM/common/dkm.tags > $(OBJ_DIR)/ctdt.c; $(TOOL_PATH)ccpentium $(DEBUGFLAGS_Linker) $(CC_ARCH_SPEC) -fdollars-in-identifiers -Wall -Wsystem-headers  $(ADDED_CFLAGS) $(IDE_INCLUDES) $(ADDED_INCLUDES)  $(IDE_DEFINES) $(DEFINES) -o $(OBJ_DIR)/ctdt.o -c $(OBJ_DIR)/ctdt.c; $(TOOL_PATH)ccpentium -r -nostdlib -Wl,-X -T $(WIND_BASE)/target/h/tool/gnu/ldscripts/link.OUT -o "$@" $(OBJ_DIR)/ctdt.o $(OBJECTS_com.boschrexroth.$(MODEL_NAME)) $(IDE_LIBRARIES) $(LIBPATH) $(LIBS) $(ADDED_LIBPATH) $(ADDED_LIBS) && if [ "$(EXPAND_DBG)" = "1" ]; then plink "$@";fi

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
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : IDE_INCLUDES = -I$(WIND_BASE)/target/h -I$(WIND_BASE)/target/h/wrn/coreip -ID:/Windriver_Projekte/1.10.1.0/mlpiCore/include -IC:/OMdev/lib/3rdParty/boost-1_49 -IC:/cpp_runtime_for_xm22/Include/SimCoreFactory -IC:/cpp_runtime_for_xm22/Include/Core -IC:/cpp_runtime_for_xm22/Include/
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : IDE_LIBRARIES = C:/wb335_BoschOEM/workspace/MATH_BIB/ATOMgnu/MATH_BIB/Debug/MATH_BIB.a C:/wb335_BoschOEM/workspace/ModelicaExternalC/ATOMgnu/ModelicaExternalC/Debug/ModelicaExternalC.a C:/wb335_BoschOEM/workspace/Math/ATOMgnu/Math/Debug/Math.a C:/wb335_BoschOEM/workspace/VxWorksFactory/ATOMgnu/VxWorksFactory/Debug/VxWorksFactory.a C:/wb335_BoschOEM/workspace/SimController/ATOMgnu/SimulationController/Debug/SimulationController.a C:/wb335_BoschOEM/workspace/DataExchange/ATOMgnu/DataExchange/Debug/DataExchange.a C:/wb335_BoschOEM/workspace/SimulationSettings/ATOMgnu/SimulationSettings/Debug/SimulationSettings.a C:/wb335_BoschOEM/workspace/Solver/ATOMgnu/Solver/Debug/Solver.a C:/wb335_BoschOEM/workspace/System/ATOMgnu/System/Debug/System.a C:/wb335_BoschOEM/workspace/RTSolver/ATOMgnu/RTSolver/Debug/RTSolver.a C:/wb335_BoschOEM/workspace/Kinsol_Sources/ATOMgnu/Kinsol_Sources/Debug/Kinsol_Sources.a C:/wb335_BoschOEM/workspace/Kinsol/ATOMgnu/Kinsol/Debug/Kinsol.a
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : IDE_DEFINES = -DCPU=_VX_$(CPU) -DTOOL_FAMILY=$(TOOL_FAMILY) -DTOOL=$(TOOL) -D_WRS_KERNEL -D_VSB_CONFIG_FILE=\"$(VSB_DIR)/h/config/vsbConfig.h\"
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : PROJECT_TYPE = DKM
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : DEFINES =
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : EXPAND_DBG = 0
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : VX_CPU_FAMILY = pentium
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : CPU = ATOM
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : TOOL_FAMILY = gnu
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : TOOL = gnu
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : TOOL_PATH =
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : CC_ARCH_SPEC = -march=atom -nostdlib -fno-builtin -fno-defer-pop -fno-implicit-fp
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : VSB_DIR = $(WIND_BASE)/target/lib
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : VSB_CONFIG_FILE = $(VSB_DIR)/h/config/vsbConfig.h
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : LIBPATH =
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : LIBS =
      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/% : OBJ_DIR := com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)

      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/Objects/com.boschrexroth.$(MODEL_NAME)/OMCpp$(MODEL_NAME).o : OMCpp$(MODEL_NAME).cpp $(FORCE_FILE_BUILD)
      <%\t%>$(TRACE_FLAG)if [ ! -d "`dirname "$@"`" ]; then mkdir -p "`dirname "$@"`"; fi;echo "building $@"; $(TOOL_PATH)ccpentium $(DEBUGFLAGS_C++-Compiler) $(CC_ARCH_SPEC) -ansi -fno-zero-initialized-in-bss  -Wall -Wsystem-headers   -MD -MP $(IDE_DEFINES) $(DEFINES) $(ADDED_C++FLAGS) $(IDE_INCLUDES) $(ADDED_INCLUDES) -o "$@" -c "$<"


      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/Objects/com.boschrexroth.$(MODEL_NAME)/OMCpp$(MODEL_NAME)CalcHelperMain.o : OMCpp$(MODEL_NAME)CalcHelperMain.cpp $(FORCE_FILE_BUILD)
      <%\t%>$(TRACE_FLAG)if [ ! -d "`dirname "$@"`" ]; then mkdir -p "`dirname "$@"`"; fi;echo "building $@"; $(TOOL_PATH)ccpentium $(DEBUGFLAGS_C++-Compiler) $(CC_ARCH_SPEC) -ansi -fno-zero-initialized-in-bss  -Wall -Wsystem-headers   -MD -MP $(IDE_DEFINES) $(DEFINES) $(ADDED_C++FLAGS) $(IDE_INCLUDES) $(ADDED_INCLUDES) -o "$@" -c "$<"


      com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/Objects/com.boschrexroth.$(MODEL_NAME)/OMCpp$(MODEL_NAME)Main.o : OMCpp$(MODEL_NAME)Main.cpp $(FORCE_FILE_BUILD)
      <%\t%>$(TRACE_FLAG)if [ ! -d "`dirname "$@"`" ]; then mkdir -p "`dirname "$@"`"; fi;echo "building $@"; $(TOOL_PATH)ccpentium $(DEBUGFLAGS_C++-Compiler) $(CC_ARCH_SPEC) -ansi -fno-zero-initialized-in-bss  -Wall -Wsystem-headers   -MD -MP $(IDE_DEFINES) $(DEFINES) $(ADDED_C++FLAGS) $(IDE_INCLUDES) $(ADDED_INCLUDES) -o "$@" -c "$<"


      OBJECTS_com.boschrexroth.$(MODEL_NAME)_partialImage = com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/Objects/com.boschrexroth.$(MODEL_NAME)/OMCpp$(MODEL_NAME).o \
      <%\t%>com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/Objects/com.boschrexroth.$(MODEL_NAME)/OMCpp$(MODEL_NAME)CalcHelperMain.o \
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

      DEP_FILES := com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/Objects/com.boschrexroth.$(MODEL_NAME)/OMCpp$(MODEL_NAME).d com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/Objects/com.boschrexroth.$(MODEL_NAME)/OMCpp$(MODEL_NAME)CalcHelperMain.d \
      <%\t%>com.boschrexroth.$(MODEL_NAME)_partialImage/$(MODE_DIR)/Objects/com.boschrexroth.$(MODEL_NAME)/com.boschrexroth.$(MODEL_NAME).d
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
                           Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text additionalConstructorVarDefs, Text additionalConstructorBodyStatements,
                           Text additionalDestructorBodyStatements, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  /* Generates the c++ code for the model class, containing all equations, the evaluate methods for the time integration algorithm and variable definitions.
     Some getter and setter functions are generated as well. Additional functions can be passed via the "extraFuncs" variable. */
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let className = lastIdentOfPath(modelInfo.name)
  let &additionalConstructorVarDefsBuffer = buffer additionalConstructorVarDefs
  let memberVariableInitialize = memberVariableInitialize(modelInfo, varToArrayIndexMapping, indexForUndefinedReferencesReal, indexForUndefinedReferencesInt, indexForUndefinedReferencesBool, useFlatArrayNotation, additionalConstructorVarDefsBuffer, extraFuncsDecl)
  let constVariableInitialize = simulationInitFile(simCode, &extraFuncsDecl, stateDerVectorName, false)
    <<
    #if defined(__TRICORE__) || defined(__vxworks)
      #include <DataExchange/SimDouble.h>
    #endif

    /* Constructor */
    <%className%>::<%className%>(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
        : SystemDefaultImplementation(globalSettings,sim_data,sim_vars)
        , _algLoopSolverFactory(nonlinsolverfactory)
        , _pointerToRealVars(sim_vars->getRealVarsVector())
        , _pointerToIntVars(sim_vars->getIntVarsVector())
        , _pointerToBoolVars(sim_vars->getBoolVarsVector())
        <%additionalConstructorVarDefsBuffer%>
    {
        <%generateSimulationCppConstructorContent(simCode, context, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
        <%additionalConstructorBodyStatements%>
    }

    <%className%>::<%className%>(<%className%> &instance) : SystemDefaultImplementation(instance.getGlobalSettings(),instance._sim_data,instance._sim_vars)
        , _algLoopSolverFactory(instance.getAlgLoopSolverFactory())
        <%additionalConstructorVarDefsBuffer%>
    {
        <%generateSimulationCppConstructorContent(simCode, context, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
        <%match modelInfo
            case MODELINFO(vars=SIMVARS(__)) then
              <<
              double* realVars = new double[<%listLength(listAppend(vars.algVars, listAppend(vars.discreteAlgVars, listAppend(vars.aliasVars, vars.paramVars))))%> + _dimContinuousStates + _dimContinuousStates];
              int* integerVars = new int[<%listLength(listAppend(listAppend(vars.intAlgVars, vars.intParamVars), vars.intAliasVars))%>];
              bool* booleanVars = new bool[<%listLength(listAppend(listAppend(vars.boolAlgVars, vars.boolParamVars), vars.boolAliasVars))%>];
              string* stringVars = new string[<%listLength(listAppend(listAppend(vars.stringAlgVars, vars.stringParamVars), vars.stringAliasVars))%>];
              instance.getReal(realVars);
              instance.getInteger(integerVars);
              instance.getBoolean(booleanVars);
              instance.getString(stringVars);
              setReal(realVars);
              setInteger(integerVars);
              setBoolean(booleanVars);
              setString(stringVars);
              delete[] realVars;
              delete[] integerVars;
              delete[] booleanVars;
              delete[] stringVars;
              >>
         %>
         <%additionalConstructorBodyStatements%>
    }

    /* Destructor */
    <%className%>::~<%className%>()
    {
      deleteObjects();
      <%additionalDestructorBodyStatements%>
    }

    void <%className%>::deleteObjects()
    {

      if(_functions != NULL)
        delete _functions;

      deleteAlgloopSolverVariables();
    }

    boost::shared_ptr<IAlgLoopSolverFactory> <%className%>::getAlgLoopSolverFactory()
    {
        return _algLoopSolverFactory;
    }

    boost::shared_ptr<ISimData> <%className%>::getSimData()
    {
        return _sim_data;
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

    <%generatehandleTimeEvent(timeEvents, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")))%>
    <%generateDimTimeEvent(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
    <%generateTimeEvent(timeEvents, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, true)%>

    <%isODE(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
    <%dimZeroFunc(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>

    <%getCondition(zeroCrossings,whenClauses,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
    <%handleSystemEvents(zeroCrossings,whenClauses,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
    <%saveAll(modelInfo,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,stateDerVectorName,useFlatArrayNotation)%>


    <%labeledDAE(modelInfo.labels,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
    <%giveVariables(modelInfo, context,useFlatArrayNotation,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,stateDerVectorName)%>

    <%memberVariableInitialize%>
    <%constVariableInitialize%>
    <%extraFuncs%>
    >>
end simulationCppFile;

template generateSimulationCppConstructorContent(SimCode simCode, Context context, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
    let className = lastIdentOfPath(modelInfo.name)
      <<
      defineConstVals();
      defineAlgVars();
      defineDiscreteAlgVars();
      defineIntAlgVars();
      defineBoolAlgVars();
      defineParameterRealVars();
      defineParameterIntVars();
      defineParameterBoolVars();
      defineMixedArrayVars();
      defineAliasRealVars();
      defineAliasIntVars();
      defineAliasBoolVars();

      //Number of equations
      <%dimension1(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
      _dimZeroFunc = <%zerocrosslength(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>;
      _dimTimeEvent = <%timeeventlength(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>;
      //Number of residues
       _event_handling= boost::shared_ptr<EventHandling>(new EventHandling());
      <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then
      <<
      _dimResidues = <%numResidues(allEquations)%>;
      >>
      %>
      <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
            let numOfEqs = SimCodeUtil.getMaxSimEqSystemIndex(simCode)
            <<
            #ifdef MEASURETIME_PROFILEBLOCKS
            measureTimeProfileBlocksArray = std::vector<MeasureTimeData>(<%numOfEqs%>);
            MeasureTime::addResultContentBlock("<%dotPath(modelInfo.name)%>","profileBlocks",&measureTimeProfileBlocksArray);
            measuredProfileBlockStartValues = MeasureTime::getZeroValues();
            measuredProfileBlockEndValues = MeasureTime::getZeroValues();

            for(int i = 0; i < <%numOfEqs%>; i++)
            {
                ostringstream ss;
                ss << (i+1);
                measureTimeProfileBlocksArray[i] = MeasureTimeData(ss.str());
            }
            #endif //MEASURETIME_PROFILEBLOCKS

            #ifdef MEASURETIME_MODELFUNCTIONS
            MeasureTime::addResultContentBlock("<%dotPath(modelInfo.name)%>","functions",&measureTimeFunctionsArray);
            measureTimeFunctionsArray = std::vector<MeasureTimeData>(4); //1 evaluateODE ; 2 evaluateAll; 3 writeOutput; 4 handleTimeEvents
            measuredFunctionStartValues = MeasureTime::getZeroValues();
            measuredFunctionEndValues = MeasureTime::getZeroValues();

            measureTimeFunctionsArray[0] = MeasureTimeData("evaluateODE");
            measureTimeFunctionsArray[1] = MeasureTimeData("evaluateAll");
            measureTimeFunctionsArray[2] = MeasureTimeData("writeOutput");
            measureTimeFunctionsArray[3] = MeasureTimeData("handleTimeEvents");
            #endif //MEASURETIME_MODELFUNCTIONS
            >>
        %>
        //DAEs are not supported yet, Index reduction is enabled
        _dimAE = 0; // algebraic equations
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



   <%modelname%>Algloop<%ls.index%>::<%modelname%>Algloop<%ls.index%>(<%systemname%>* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
       : AlgLoopDefaultImplementation()
       , _system(system)
       , __z(z)
       , __zDot(zDot)
   <% match eq

     case SES_LINEAR(__) then
    <<
     ,__Asparse()
    >>
    %>

   //<%alocateLinearSystemConstructor(eq, useFlatArrayNotation)%>
       , _conditions(conditions)
       , _discrete_events(discrete_events)
       , _useSparseFormat(false)
       , _functions(system->_functions)
   {
     <%initAlgloopDimension(eq,varDecls)%>
   }

   <%modelname%>Algloop<%ls.index%>::~<%modelname%>Algloop<%ls.index%>()
   {
     <% match eq
      case SES_LINEAR(__) then
      <<
      >>
     %>
   }

   bool <%modelname%>Algloop<%ls.index%>::getUseSparseFormat()
   {
     return _useSparseFormat;
   }

   void <%modelname%>Algloop<%ls.index%>::setUseSparseFormat(bool value)
   {
     _useSparseFormat = value;
   }

   <%algloopRHSCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>
   <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then algloopResiduals(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>
   <%initAlgloop(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, eq, context, stateDerVectorName, useFlatArrayNotation)%>
   <%initAlgloopTemplate(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, eq, context, stateDerVectorName, useFlatArrayNotation)%>
   <%queryDensity(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq,context, useFlatArrayNotation)%>
   <%updateAlgloop(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq,context)%>
   <%upateAlgloopNonLinear(simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, eq, context, stateDerVectorName, useFlatArrayNotation)%>
   <%upateAlgloopLinear(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq,context, stateDerVectorName, useFlatArrayNotation)%>
   <%algloopDefaultImplementationCode(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, eq, context, stateDerVectorName, useFlatArrayNotation)%>
   <%getAMatrixCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>
   <%isLinearCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>
   <%isLinearTearingCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>
   >>

    case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
   <<

   <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then '#include "Math/ArrayOperations.h"'%>



   <%modelname%>Algloop<%nls.index%>::<%modelname%>Algloop<%nls.index%>(<%systemname%>* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
       : AlgLoopDefaultImplementation()
       , _system(system)
       , __z(z)
       , __zDot(zDot)
   <% match eq

     case SES_LINEAR(__) then
    <<
     ,__Asparse()
    >>
    %>

   //<%alocateLinearSystemConstructor(eq, useFlatArrayNotation)%>
       , _conditions(conditions)
       , _discrete_events(discrete_events)
       , _useSparseFormat(false)
       , _functions(system->_functions)
   {
     <%initAlgloopDimension(eq,varDecls)%>
   }

   <%modelname%>Algloop<%nls.index%>::~<%modelname%>Algloop<%nls.index%>()
   {
     <% match eq
      case SES_LINEAR(__) then
      <<
      >>
     %>
   }

   bool <%modelname%>Algloop<%nls.index%>::getUseSparseFormat()
   {
     return _useSparseFormat;
   }

   void <%modelname%>Algloop<%nls.index%>::setUseSparseFormat(bool value)
   {
     _useSparseFormat = value;
   }

   <%algloopRHSCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>
   <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then algloopResiduals(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq)%>
   <%initAlgloop(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, eq, context, stateDerVectorName, useFlatArrayNotation)%>
   <%initAlgloopTemplate(simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, eq, context, stateDerVectorName, useFlatArrayNotation)%>
   <%queryDensity(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq,context, useFlatArrayNotation)%>
   <%updateAlgloop(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq,context)%>
   <%upateAlgloopNonLinear(simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, eq, context, stateDerVectorName, useFlatArrayNotation)%>
   <%upateAlgloopLinear(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,eq,context, stateDerVectorName, useFlatArrayNotation)%>
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
      let size=listLength(ls.simJac)
      <<
      float <%modelname%>Algloop<%ls.index%>::queryDensity()
      {
        return 100.*<%size%>./_dimAEq/_dimAEq;
      }
      >>
end queryDensity;


template updateAlgloop(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,SimEqSystem eqn,Context context)
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
      case eq as SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
        <<
        void <%modelname%>Algloop<%ls.index%>::evaluate()
        {
           if(_useSparseFormat)
           {
             if(! __Asparse)
                __Asparse = boost::shared_ptr<SparseMatrix>( new SparseMatrix);

             evaluate(__Asparse.get());
           }
           else
           {
             if(! __A )
                __A = boost::shared_ptr<AMATRIX>( new AMATRIX());

             evaluate(__A.get());
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
   case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
   <<
   template <typename T>
   void <%modelname%>Algloop<%ls.index%>::evaluate(T *__A)
   >>
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

template functionHeaderBodies1(list<Function> functions,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates the body for a set of functions."
::=
match simCode
    case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
   let recorddecls = (recordDecls |> rd => recordDeclarationHeader(rd,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation) ;separator="\n")
   let rettypedecls =  (functions |> fn => functionHeaderBody1(fn,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator="\n")
   <<
   <%recorddecls%>
   <%rettypedecls%>
   >>
end    functionHeaderBodies1;

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
  case "FORTRAN 77" then extTypeF77(type, isReference)
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
  match type case T_ARRAY(__) then s else if isInput then (if isArray then '<%match s case "const char*" then "" else "/*const*/ "%><%s%>*' else s) else '<%s%>*'
end extType2;


template extTypeF77(Type type, Boolean isReference)
  "Generates type for external function argument or return value for F77."
::=
  let s = match type
  case T_INTEGER(__)     then "int"
  case T_REAL(__)        then "double"
  case T_STRING(__)      then "char"
  case T_BOOL(__)        then "int"
  case T_ENUMERATION(__) then "int"
  case T_ARRAY(__)       then extTypeF77(ty, true)
  case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__))
                         then "void*"
  case T_COMPLEX(complexClassType=RECORD(path=rname))
                         then '<%underscorePath(rname)%>'
  case T_METATYPE(__) case T_METABOXED(__) then "void*"
  else error(sourceInfo(), 'Unknown external F77 type <%unparseType(type)%>')
  match type case T_ARRAY(__) then s else if isReference then '<%s%>*' else s
end extTypeF77;


template extReturnType(SimExtArg extArg)
 "Generates return type for external function."
::=
  match extArg
  case ex as SIMEXTARG(__)    then extType2(type_,true /*Treat this as an input (pass by value)*/,false)
  case SIMNOEXTARG(__)  then "void"
  case SIMEXTARGEXP(__) then error(sourceInfo(), 'Expression types are unsupported as return arguments <%printExpStr(exp)%>')
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
      typedef boost::tuple< <%vars |> var => funReturnDefinition1(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator=", "%> > TUPLE_ARRAY;

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
  // previous multi_array      if instDims then 'assign_array(boost::get<<%index%>>(data),boost::get<<%index%>>(A.data));' else 'boost::get<<%index%>>(data)= boost::get<<%index%>>(A.data);
     if instDims then '(boost::get<<%index%>>(data)).assign(boost::get<<%index%>>(A.data));' else 'boost::get<<%index%>>(data)= boost::get<<%index%>>(A.data);'
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
       typedef boost::tuple< <%outVars |> var => funReturnDefinition1(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator=", "%> > TUPLE_ARRAY;

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
    typedef boost::tuple< <%outVars |> var => funReturnDefinition1(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace) ;separator=", "%> >  <%fname%>RetType /* functionHeaderExternFunction */;
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

template recordDeclarationHeader(RecordDeclaration recDecl,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Boolean useFlatArrayNotation)
 "Generates structs for a record declaration."
::=
  match recDecl
  case RECORD_DECL_FULL(__) then
    <<
     struct <%name%>Type
     {
        //Constructor allocates arrays
        <%name%>Type()
        {
            /* <%variables |> var as VARIABLE(__) => '<%recordDeclarationHeaderArrayAllocate(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,contextOther, useFlatArrayNotation)%>' ;separator="\n"%> */
        }
        //Public  Members
        <%variables |> var as VARIABLE(__) => '<%varType3(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%> <%crefStr(var.name)%>;' ;separator="\n"%>
    };
    >>
  case RECORD_DECL_DEF(__) then
    <<
    RECORD DECL DEF
    >>
end recordDeclarationHeader;

template recordDeclarationHeaderArrayAllocate(Variable v,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context,Boolean useFlatArrayNotation)
 "Generates structs for a record declaration."
::=
  match v
  case var as VARIABLE(ty=ty as T_ARRAY(__)) then
  let instDimsInit = (ty.dims |> exp =>
     dimension(exp,context);separator="][")
     let arrayname = crefStr(name)
  <<
  <%arrayname%>.resize((boost::extents[<%instDimsInit%>]));
  <%arrayname%>.reindex(1);
  >>
end recordDeclarationHeaderArrayAllocate;

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

template daeExpSharedLiteral(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/, Boolean useFlatArrayNotation)
 "Generates code for a match expression."
::=
  match exp case exp as SHARED_LITERAL(__) then
    match context case FUNCTION_CONTEXT(__) then
      ' _OMC_LIT<%exp.index%>'
    else
      '_functions->_OMC_LIT<%exp.index%>'
end daeExpSharedLiteral;


template daeExpSum(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                   Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a match expression."
::=
  match exp case exp as SUM(__) then
    let bodyExp = daeExp(body, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let iterExp = daeExp(iterator, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let startItExp = daeExp(startIt, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let endItExp = daeExp(endIt, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let &preExp += 'double sum = 0.0;<%\n%>for(size_t <%iterExp%> = <%startItExp%>; <%iterExp%> != <%endItExp%>+1; <%iterExp%>++)<%\n%>  sum += <%bodyExp%>[<%iterExp%>]<%\n%>'
    <<
    sum
    >>

  //C-Codegen:
  //let start = printExpStr(startIt)
  //let &anotherPre = buffer ""
  //let stop = printExpStr(endIt)
  //let bodyStr = daeExpIteratedCref(body)
  //let summationVar = <<sum>>
  //let iterVar = printExpStr(iterator)
  //let &preExp +=<<

  //modelica_integer  $P<%iterVar%> = 0; // the iterator
  //modelica_real <%summationVar%> = 0.0; //the sum
  //for($P<%iterVar%> = <%start%>; $P<%iterVar%> < <%stop%>; $P<%iterVar%>++)
  //{
  //  <%summationVar%> += <%bodyStr%>($P<%iterVar%>);
  //}
end daeExpSum;


template functionHeaderRegularFunction2(Function fn,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match fn
case FUNCTION(outVars={}) then
  let fname = underscorePath(name)
  <<
        void <%fname%>(<%functionArguments |> var => funArgDefinition(var, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator=", "%>);
  >>
case FUNCTION(outVars=_) then
  let fname = underscorePath(name)
  <<
        /* functionHeaderRegularFunction2 */
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
  let bodyPart = (body |> stmt  => funStatement(stmt, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator="\n")
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
  void /*<%retType%>*/ Functions::<%fname%>(<%functionArguments |> var => funArgDefinition(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator=", "%><%if functionArguments then if outVars then "," else ""%><%if outVars then '<%retType%>& output' %> )
  {
    //functionBodyRegularFunction
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
  // make sure the variable is named "out", doh!
   let retVar = if outVars then '_<%fname%>'
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



   let &varDecls1 = buffer ""
   let &outVarInits1 = buffer ""
   let &outVarCopy1 = buffer ""
   let &outVarAssign1 = buffer ""

   let _ =  match outVars

   case {var} then "1"

   else
     //(List.restOrEmpty(outVars) |> var hasindex i1 fromindex 1 =>  varOutputTuple(fn, var,i1, &varDecls1, &outVarInits1, &outVarCopy1, &outVarAssign1, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, useFlatArrayNotation)
     (outVars |> var hasindex i1 fromindex 0 =>  varOutputTuple(fn, var, i1, &varDeclsvOutputTuple, &outVarInits, &outVarCopy1, &outVarAssign1, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     ;separator="\n"; empty /* increase the counter! */)
  end match
    let functionBodyExternalFunctionreturn = match outVarAssign1
   case "" then << <%if retVar then 'output = <%retVar%>;' else '/*no output*/' %> >>
   else outVarAssign1




  let fnBody = <<
  void /*<%retType%>*/ Functions::<%fname%>(<%funArgs |> var => funArgDefinition(var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator=", "%><%if funArgs then if outVars then "," else ""%> <%if retVar then '<%retType%>& output' %>)/*function2*/
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
    <%inputAssign%>
    /* functionBodyExternalFunction: outVarInits */
    <%outVarInits%>
    /* functionBodyExternalFunction: callPart */
    <%callPart%>

    <%outVarAssign%>

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
  let returnAssign = match extReturn case SIMEXTARG(cref=c) then
     '<%contextCref2(c,contextFunction)%> ='// '<%extVarName2(c)%> = '
    else
      ""



  <<
  <%varDecs%>
  <%match extReturn case SIMEXTARG(__) then extFunCallVardecl(extReturn, &varDecls /*BUFD*/)%>
  <%dynamicCheck%>
  /*test0*/
  <%returnAssign%><%extName%>(<%args%>);
  >>
   /*test1*/
 // <%extArgs |> arg => extFunCallVarcopy(arg,fname,useTuple, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator="\n"%>
  /*test2*/
  //<%match extReturn case SIMEXTARG(__) then extFunCallVarcopy(extReturn,fname,useTuple, simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
  /*test3*/

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
    let assginBegin = 'boost::get<<%intAdd(-1,oi)%>>('
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
    let assginBegin = 'boost::get<<%intAdd(-1,oi)%>>('
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
    let assginBegin = 'boost::get<<%intAdd(-1,oi)%>>('
      let assginEnd = ')'

    <<
     <%assginBegin%>_<%fnName%>.data<%assginEnd%> = <%cr%> ;
    >>

end extFunCallVarcopyTuple;

template expTypeModelica(DAE.Type ty)
 "Generate type helper."
::=
  expTypeFlag(ty, 2)
end expTypeModelica;


template extArg(SimExtArg extArg, Text &preExp, Text &varDecls, Text &inputAssign, Text &outputAssign, SimCode simCode, Text& extraFuncs,
                Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Helper to extFunCall."
::=
  match extArg
  case SIMEXTARG(cref=c, outputIndex=oi, isArray=true, type_=t) then
    //let name = if oi then 'out.targTest5<%oi%>' else contextCref2(c,contextFunction)
  let arrayArg = extCArrayArg(extArg, &preExp, &varDecls, &inputAssign /*BUFD*/, &outputAssign /*BUFD*/)
  <<
  <%arrayArg%>/*testarray*/
  >>

  case SIMEXTARG(cref=c, isInput=ii, outputIndex=0, type_=t) then
    let cr = '<%contextCref2(c,contextFunction)%>'
    if acceptMetaModelicaGrammar() then
      (match t case T_STRING(__) then 'MMC_STRINGDATA(<%cr%>)' else '<%cr%>_ext')
    else
      '<%cr%><%match t case T_STRING(__) then ".c_str()" else "_ext"%>'
  case SIMEXTARG(cref=c, isInput=ii, outputIndex=oi, type_=t) then
    '&<%extVarName2(c)%>'
  case SIMEXTARGEXP(__) then
    daeExternalCExp(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case SIMEXTARGSIZE(cref=c) then
    let typeStr = expTypeShort(type_)
    let name = if outputIndex then 'out.targTest4<%outputIndex%>' else contextCref2(c,contextFunction)
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
    let extType = extType2(ty, true, false)
    let extCStr = if stringEq(elType, "string") then 'CStrArray'
    if boolOr(intGt(listLength(dims), 1), stringEq(elType, "bool")) then
      let tmp = match dimsStr
        case "" then
          tempDecl('DynArrayDim<%listLength(dims)%><<%extType%>>', &varDecls /*BUFD*/)
        else
          tempDecl('StatArrayDim<%dimStr%><<%extType%>, <%dimsStr%>>', &varDecls /*BUFD*/)
      let &inputAssign += 'convertArrayLayout(<%name%>, <%tmp%>);'
      let &outputAssign += if intGt(oi, 0) then 'convertArrayLayout(<%tmp%>, <%name%>);'
      let arg = if extCStr then 'CStrArray(<%tmp%>)' else '<%tmp%>.getData()'
      '<%arg%>'
    else
      let arg = if extCStr then 'CStrArray(<%name%>)' else '<%name%>.getData()/*testconvert*/'
      '<%arg%>'
end extCArrayArg;


template daeExternalCExp(Exp exp, Context context, Text &preExp /*BUFP*/,Text &varDecls /*BUFP*/, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  "Like daeExp, but also converts the type to external C"
::=
  match typeof(exp)
    case T_ARRAY(__) then  // Array-expressions
      let shortTypeStr = expTypeShort(typeof(exp))
      '<%daeExp(exp, context, &preExp, &varDecls,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>).data()'
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
  case SIMEXTARG(cref=c, outputIndex=oi, isArray=true, type_=t) then
    let varName = contextCref2(c, contextFunction)
    match type_
    case T_ARRAY(__) then
      let elType = expTypeShort(ty)
      let extType = extTypeF77(ty, false)
      let extName = '<%varName%>_ext'
      let nDims = listLength(dims)
      if stringEq(elType, "bool") then
        let &varDecls += 'DynArrayDim<%nDims%><<%extType%>> <%extName%>;<%\n%>'
        let &inputAssign += 'convertBoolToInt(<%varName%>, <%extName%>);<%\n%>'
        let &outputAssign += if intGt(oi, 0) then 'convertIntToBool(<%extName%>, <%varName%>);<%\n%>'
        <<
        <%extName%>.getData()
        >>
      else
        <<
        <%varName%>.getData()
        >>
    end match
  case SIMEXTARG(cref=c, type_=t) then
    let varName = contextCref2(c, contextFunction)
    let varType = expTypeShort(t)
    let extType = extTypeF77(t, false)
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
  case SIMEXTARGEXP(__) then
    // pass a pointer to a temporary variable
    let extType = extTypeF77(type_, false)
    let extName = tempDecl(extType, &varDecls)
    let &inputAssign += '<%extName%> = <%daeExp(exp, contextFunction, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>;<%\n%>'
    <<
    &<%extName%>
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
  let assginBegin = 'boost::get<<%ix%>>'
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
  let instDimsInit = (instDims |> exp => daeExp(exp, contextFunction, &varInits, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation);separator=",")
    match var
        case var as VARIABLE(__) then
            let type = '<%varType(var)%>'
            let initVar =  match type case "modelica_metatype" then ' = NULL' else ''
            let addRoot =  match type case "modelica_metatype" then ' mmc_GC_add_root(&<%varName%>, mmc_GC_local_state, "<%varName%>");' else ''
            let testinstDimsInit = (instDims |> exp => testDaeDimensionExp(exp);separator="")
            let instDimsInit = (instDims |> exp => daeExp(exp, contextFunction, &varInits, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation);separator=",")
            let arrayexpression1 = (if instDims then 'StatArrayDim<%listLength(instDims)%><<%expTypeShort(var.ty)%>,<%instDimsInit%>> <%varName%>;<%\n%>'
        else '<%type%> <%varName%><%initVar%>;<%addRoot%><%\n%>')
            let arrayexpression2 = (if instDims then 'DynArrayDim<%listLength(instDims)%><<%expTypeShort(var.ty)%>> <%varName%>;<%\n%>'
        else '<%type%> <%varName%><%initVar%>;<%addRoot%><%\n%>'
  )

  match testinstDimsInit
    case "" then
        let &varDecls += arrayexpression1
        ""
    else
        let &varDecls += arrayexpression2
        ""
end varDeclForVarInit;


template varInit(Variable var, String outStruct, Integer i, Text &varDecls, Text &varInits, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)

 "Generates code to initialize variables.
  Does not return anything: just appends declarations to buffers."
::=

match var
case var as VARIABLE(__) then
  let varName = '<%contextCref(var.name,contextFunction,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'

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
    expTypeArray(var.ty)
  else
    expTypeArrayIf(var.ty)
end varType;


template varType1(Variable var,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match var
case var as VARIABLE(__) then
     /* previous multi_array
   if instDims then 'multi_array<<%expTypeShort(var.ty)%>,<%listLength(instDims)%>> ' else expTypeFlag(var.ty, 6)
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
   if instDims then 'multi_array<<%expTypeShort(var.ty)%>,<%listLength(instDims)%>> ' else expTypeFlag(var.ty, 6)
      */
     let &varDecls = buffer "" /*should be empty herer*/
     let &varInits = buffer "" /*should be empty herer*/
     let testinstDimsInit = (instDims |> exp => testDaeDimensionExp(exp);separator="")

     match testinstDimsInit
     case "" then
      let instDimsInit = (instDims |> exp => daeDimensionExp(exp);separator=",")
     if instDims then 'StatArrayDim<%listLength(instDims)%>< <%expTypeShort(var.ty)%>, <%instDimsInit%>> ' else expTypeFlag(var.ty, 6)
     else
     if instDims then 'DynArrayDim<%listLength(instDims)%><<%expTypeShort(var.ty)%>> ' else expTypeFlag(var.ty, 6)

     end match
end varType3;

template funStatement(Statement stmt, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates function statements."
::=
  match stmt
  case ALGORITHM(__) then
    (statementLst |> stmt =>
      algStatement(stmt, contextFunction, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    ;separator="\n")
  else
    "NOT IMPLEMENTED FUN STATEMENT"
end funStatement;

template initExtVars(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__))  then
    let externalvarfuncs = functionCallExternalObjectConstructors('<%lastIdentOfPath(modelInfo.name)%>Initialize::initializeExternalVar', extObjInfo, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let externalvarsfunccalls = functionCallExternalObjectConstructorsCall('<%lastIdentOfPath(modelInfo.name)%>Initialize','initializeExternalVar', extObjInfo, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation)
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
  let externalvarsdecl = functionCallExternalObjectConstructorsDecl('initializeExternalVar',extObjInfo,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,useFlatArrayNotation)
   <<
    <%externalvarsdecl%>
    void initializeExternalVar();
   >>
 end match
end initExtVarsDecl;


template init(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__))  then
   //let () = System.tmpTickReset(0)
   let &varDecls = buffer "" /*BUFD*/

   let initFunctions = functionInitial(startValueEquations, varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
   let initZeroCrossings = functionOnlyZeroCrossing(zeroCrossings,varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace)
   let initEventHandling = eventHandlingInit(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)

   let initAlgloopSolvers = initAlgloopsolvers(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
   let initAlgloopvars = initAlgloopVars(listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)

   let initialequations  = functionInitialEquations(initialEquations,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation, false)
   <<
   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initialize()
   {
      initializeMemory();
      //IPropertyReader *reader = new XmlPropertyReader("OMCpp<%fileNamePrefix%>Init.xml");
      //reader->readInitialValues(_sim_vars);
      initializeFreeVariables();
      initializeBoundVariables();
      saveAll();
      //delete reader;
   }

   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeMemory()
   {
      _discrete_events = _event_handling->initialize(this,_sim_vars);

      //create and initialize Algloopsolvers
      <%generateAlgloopsolvers( listAppend(allEquations,initialEquations),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>

      //initialize Algloop variables
      initializeAlgloopSolverVariables();
      //init alg loop vars
      <%initAlgloopvars%>
   }

   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeFreeVariables()
   {
      _simTime = 0.0;

      /*initialize parameter*/
      initializeParameterVars();
      initializeIntParameterVars();
      initializeBoolParameterVars();
      initializeStringParameterVars();
      initializeAlgVars();
      initializeDiscreteAlgVars();
      initializeIntAlgVars();
      initializeBoolAlgVars();
      //initializeAliasVars();
      //initializeIntAliasVars();
      //initializeBoolAliasVars();
      initializeStringAliasVars();
      initializeStateVars();
      initializeDerVars();
       /*external vars decls*/
      initializeExternalVar();

   #if defined(__TRICORE__) || defined(__vxworks)
      //init inputs
      stepStarted(0.0);
   #endif
   }

   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeBoundVariables()
   {
      //variable decls
      <%varDecls%>

      //bound start values
      <%initFunctions%>

      //init event handling
      <%initEventHandling%>

      //init equations
      initEquations();

      //init alg loop solvers
      <%initAlgloopSolvers%>

      for(int i=0;i<_dimZeroFunc;i++)
      {
         getCondition(i);
      }

      //initialAnalyticJacobian();

      <%functionInitDelay(delayedExps,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
   }

   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initEquations()
   {
      <%(initialEquations |> eq  =>
                    equation_function_call(eq,  contextOther, &varDecls /*BUFC*/, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,"initEquation")
                    ;separator="\n")%>
   }
   <%initialequations%>
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

   let init1   = initValst(varDecls1, "Real", vars.stateVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)
   let init2   = initValst(varDecls2, "Real", vars.derivativeVars, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)

   <<
   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeStateVars()
   {
       <%varDecls1%>
       <%init1%>
   }
   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeDerVars()
   {
       <%varDecls2%>
       <%init2%>
   }
   >>
end init2;


template functionCallExternalObjectConstructors(Text funcNamePrefix, ExtObjInfo extObjInfo, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  "Generates function in simulation file."
::=
  match extObjInfo
  case EXTOBJINFO(__) then


    let ctorCalls = (vars |> var as SIMVAR(initialValue=SOME(exp))  hasindex idx=>
        let &preExp = buffer "" /*BUFD*/
        let &varDecls = buffer "" /*BUFD*/
        let arg = daeExp(exp, contextOther, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        /* Restore the memory state after each object has been initialized. Then we can
         * initalize a really large number of external objects that play with strings :)
         */
        <<
         void <%funcNamePrefix%>_<%idx%>()
         {
           <%varDecls%>
           <%preExp%>
           <%cref(var.name,useFlatArrayNotation)%> = <%arg%>;
         }
        >>
        ;separator="")
   ctorCalls
  end match
end functionCallExternalObjectConstructors;


template functionCallExternalObjectConstructorsCall(Text classname,Text funcNamePrefix,ExtObjInfo extObjInfo,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Boolean useFlatArrayNotation)
  "Generates function in simulation file."
::=
  match extObjInfo
  case EXTOBJINFO(__) then
    let &funDecls = buffer "" /*BUFD*/
    let &varDecls = buffer "" /*BUFD*/
    let ctorCalls = (vars |> var as SIMVAR(initialValue=SOME(exp))  hasindex idx=>
        <<
         <%funcNamePrefix%>_<%idx%>();
        >>
      ;separator="")
   <<
    void <%classname%>::<%funcNamePrefix%>()
    {
       <%ctorCalls%>
       <%aliases |> (var1, var2) => '<%cref(var1,useFlatArrayNotation)%> = <%cref(var2,useFlatArrayNotation)%>;' ;separator="\n"%>
    }
   >>
  end match
end functionCallExternalObjectConstructorsCall;


template functionCallExternalObjectConstructorsDecl(Text funcNamePrefix,ExtObjInfo extObjInfo,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Boolean useFlatArrayNotation)
  "Generates function in simulation file."
::=
  match extObjInfo
  case EXTOBJINFO(__) then
    let &funDecls = buffer "" /*BUFD*/
    let &varDecls = buffer "" /*BUFD*/
    let ctorCallsDecl = (vars |> var as SIMVAR(initialValue=SOME(exp))  hasindex idx=>
        <<
         void <%funcNamePrefix%>_<%idx%>();
        >>
      ;separator="\n")
   ctorCallsDecl
  end match
end functionCallExternalObjectConstructorsDecl;


template functionInitialEquations(list<SimEqSystem> initalEquations, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Boolean createMeasureTime)
  "Generates function in simulation file."
::=
  let equation_func_calls = (initalEquations |> eq =>
        equation_function_create_single_func(eq, contextOther, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, "initEquation", "Initialize", stateDerVectorName, useFlatArrayNotation, createMeasureTime)
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
         AlgLoopDefaultImplementation::initialize();

        // Update the equations once before start of simulation
        evaluate();
     }
   >>
 case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
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
 case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)
) then
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


template getAMatrixCode(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,SimEqSystem eq)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)
   let &varDecls = buffer ""
   let &preExp= buffer ""


  match eq
  case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
  <<
  void <%modelname%>Algloop<%nls.index%>::getSystemMatrix(double* A_matrix)
  {

   }
  void <%modelname%>Algloop<%nls.index%>::getSystemMatrix(SparseMatrix* A_matrix)
  {

   }
  >>
 case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)
) then
   <<
     void <%modelname%>Algloop<%ls.index%>::getSystemMatrix(double* A_matrix)
     {
          <% match eq
           case SES_LINEAR(__) then
           "memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));"
          %>
     }
     void <%modelname%>Algloop<%ls.index%>::getSystemMatrix(SparseMatrix* A_matrix)
     {
          <% match eq
          case SES_LINEAR(__) then
          "*A_matrix=*__Asparse;"
          %>
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
  void <%modelname%>Algloop<%nls.index%>::getRHS(double* residuals)
    {

        <% match eq
        case SES_LINEAR(__) then
        <<
           memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
        >>
        else
        <<
          AlgLoopDefaultImplementation::getRHS(residuals);
        >>
        %>
    }
  >>

  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
  <<
  void <%modelname%>Algloop<%ls.index%>::getRHS(double* residuals)
    {

        <% match eq
        case SES_LINEAR(__) then
        <<
           memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
        >>
        else
        <<
          AlgLoopDefaultImplementation::getRHS(residuals);
        >>
        %>
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

    void <%modelname%>Algloop<%ls.index%>::getRHS(double* vars)
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

    void <%modelname%>Algloop<%nls.index%>::getRHS(double* vars)
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
  let lineartearing = if nls.linearTearing then 'true' else 'false'
  <<
  bool <%modelname%>Algloop<%nls.index%>::isLinearTearing()
  {
        return <%lineartearing%>;
   }
  >>
 case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
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
     let &varDecls = buffer "" /*BUFD*/

 let Amatrix=
    (ls.simJac |> (row, col, eq as SES_RESIDUAL(__)) =>
      let &preExp = buffer "" /*BUFD*/
      let expPart = daeExp(eq.exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      '<%preExp%>(*__A)(<%row%>+1,<%col%>+1)=<%expPart%>;'
  ;separator="\n")


let bvector =  (ls.beqs |> exp hasindex i0 fromindex 1=>
     let &preExp = buffer "" /*BUFD*/
     let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     '<%preExp%>__b(<%i0%>)=<%expPart%>;'
  ;separator="\n")
 <<
     <%varDecls%>
      <%Amatrix%>
      <%bvector%>
  >>

end initAlgloopEquation;


template giveAlgloopvars(SimEqSystem eq, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
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
      <%ls.vars |> SIMVAR(__) hasindex i0 => 'vars[<%i0%>] =<%cref1(name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDeclsCref,stateDerVectorName,useFlatArrayNotation)%>;' ;separator="\n"%>
   >>

end giveAlgloopvars;


template giveAlgloopNominalvars(SimEqSystem eq, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a non linear equation system."
::=
match eq
case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
  let size = listLength(nls.crefs)
  let &preExp = buffer "" //dummy ... the value is always a constant
  let &varDecls = buffer "" /*BUFD*/
  let nominalVars = (nls.crefs |> name hasindex i0 =>
       let namestr = giveAlgloopNominalvars2(name, preExp, varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)
       'vars[<%i0%>] = <%namestr%>;'
    ;separator="\n")
  <<
   <%varDecls%>
   <%preExp%>
   <%nominalVars%>
     >>
 case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
   let &varDecls = buffer "" /*BUFD*/
   <<
      <%ls.vars |> SIMVAR(__) hasindex i0 => 'vars[<%i0%>] =<%cref1(name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDecls, stateDerVectorName,useFlatArrayNotation)%>;' ;separator="\n"%>
   >>

end giveAlgloopNominalvars;


template giveAlgloopNominalvars2(ComponentRef inCref, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a non linear equation system."
::=
 cref2simvar(inCref, simCode ) |> var  =>
 match var
 case SIMVAR(nominalValue=SOME(exp)) then


  let expPart = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  <<
  <%expPart%>
  >>
  else
  "1.0"
end giveAlgloopNominalvars2;


template writeAlgloopvars(list<list<SimEqSystem>> continousEquations,list<SimEqSystem> discreteEquations,list<SimWhenClause> whenClauses,list<SimEqSystem> parameterEquations,
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


template setAlgloopvars(SimEqSystem eq,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
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

   <%ls.vars |> SIMVAR(__) hasindex i0 => '<%cref1(name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDeclsCref,stateDerVectorName,useFlatArrayNotation)%>=vars[<%i0%>];' ;separator="\n"%>

  >>
end setAlgloopvars;

template initAlgloopDimension(SimEqSystem eq, Text &varDecls /*BUFP*/)
 "Generates a non linear equation system."
::=
match eq
case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
  let size = listLength(nls.crefs)
  <<
    // Number of unknowns equations
    _dimAEq = <%size%>;
    _constraintType = IAlgLoop::REAL;
    __xd.resize(<%size%>);
   _xd_init.resize(<%size%>);
  >>
  case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
  let size = listLength(ls.vars)
  <<
    // Number of unknowns/equations according to type (0: double, 1: int, 2: bool)
    _dimAEq = <%size%>;
    fill_array(__b,0.0);
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
      __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
    else
      __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
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
  <%equationFunctions(allEquations,whenClauses,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,contextSimulationDiscrete,stateDerVectorName,useFlatArrayNotation,boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")))%>

  <%createEvaluateAll(allEquations,whenClauses,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,contextOther, stateDerVectorName, useFlatArrayNotation, boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")))%>

  <%createEvaluate(odeEquations,whenClauses,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,contextOther, boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")))%>

  <%createEvaluateZeroFuncs(equationsForZeroCrossings,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,contextOther)%>

  <%createEvaluateConditions(allEquations,whenClauses,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,contextOther, stateDerVectorName, useFlatArrayNotation)%>
  >>
end update;


template InitializeEquationsArray(list<SimEqSystem> allEquations, String className)
::=
  match allEquations
  case feq::_ then

    let equation_inits = (allEquations |> eq hasindex i0 =>
                    'equations_array[<%i0%>] = &<%className%>::evaluate_<%equationIndex(eq)%>;' ; separator="\n")

    <<
    void <%className%>::initialize_equations_array() {
      /*! Index of the first equation. We use this to calculate the offset of an equation in the
        equation array given the index of the equation.*/
      first_equation_index = <%equationIndex(feq)%>;

      <%equation_inits%>
    }
    >>
  end match
end InitializeEquationsArray;



template writeoutput(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__),simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
  let numParamvars = numProtectedParamVars(modelInfo)
  <<

   void <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeOutput(const IWriteOutput::OUTPUT command)
   {
    //Write head line
    if (command & IWriteOutput::HEAD_LINE)
    {
      vector<string> varsnames;
      vector<string> vardescs;
      vector<string> paramnames;
      vector<string> paramdecs;
      writeAlgVarsResultNames(varsnames);
      writeDiscreteAlgVarsResultNames(varsnames);
      writeIntAlgVarsResultNames(varsnames);
      writeBoolAlgVarsResultNames(varsnames);
      writeAliasVarsResultNames(varsnames);
      writeIntAliasVarsResultNames(varsnames);
      writeBoolAliasVarsResultNames(varsnames);
      writeStateVarsResultNames(varsnames);
      writeDerivativeVarsResultNames(varsnames);

      <%
      match   settings.outputFormat case "mat"
      then
      <<
      writeParametertNames(paramnames);
      writeIntParameterNames(paramnames);
      writeBoolParameterNames(paramnames);
      writeAlgVarsResultDescription(vardescs);
      writeDiscreteAlgVarsResultDescription(vardescs);
      writeIntAlgVarsResultDescription(vardescs);
      writeBoolAlgVarsResultDescription(vardescs);
      writeAliasVarsResultDescription(vardescs);
      writeIntAliasVarsResultDescription(vardescs);
      writeBoolAliasVarsResultDescription(vardescs);
      writeStateVarsResultDescription(vardescs);
      writeDerivativeVarsResultDescription(vardescs);
      writeParameterDescription(paramdecs);
      writeIntParameterDescription(paramdecs);
      writeBoolParameterDescription(paramdecs);
      >>
      %>
      _historyImpl->write(varsnames,vardescs,paramnames,paramdecs);
      <%
      match   settings.outputFormat case "mat"
      then
      <<
        HistoryImplType::value_type_p params;

        writeParams(params);
      >>
      else
      <<
       HistoryImplType::value_type_p params;
      >>
      %>
       _historyImpl->write(params,_global_settings->getStartTime(),_global_settings->getEndTime());
    }
    //Write the current values
    else
    {
      <%generateMeasureTimeStartCode("measuredFunctionStartValues", "writeOutput", "MEASURETIME_MODELFUNCTIONS")%>
      /* HistoryImplType::value_type_v v;
      HistoryImplType::value_type_dv v2; */

      boost::shared_ptr<HistoryImplType::values_type> container = _historyImpl->getFreeContainer();
      boost::shared_ptr<HistoryImplType::value_type_v> v = container->get<0>();
       boost::shared_ptr<HistoryImplType::value_type_dv> v2 = container->get<1>();
      container->get<2>() = _simTime;

      writeAlgVarsValues(v.get());
      writeDiscreteAlgVarsValues(v.get());
      writeIntAlgVarsValues(v.get());
      writeBoolAlgVarsValues(v.get());
      writeAliasVarsValues(v.get());
      writeIntAliasVarsValues(v.get());
      writeBoolAliasVarsValues(v.get());
      writeStateValues(v.get(),v2.get());

      <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then
      <<
      HistoryImplType::value_type_r v3;
      <%(allEquations |> eqs => (eqs |> eq => writeoutputAlgloopsolvers(eq,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace));separator="\n")%>
      double residues [] = {<%(allEquations |> eqn => writeoutput3(eqn, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation));separator=","%>};
      for(int i=0;i<<%numResidues(allEquations)%>;i++) v3(i) = residues[i];

      <%generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "measureTimeFunctionsArray[2]", "writeOutput", "MEASURETIME_MODELFUNCTIONS")%>

      _historyImpl->write(v,v2,v3,_simTime);
      >>
    else
      <<
      <%generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "measureTimeFunctionsArray[2]", "writeOutput", "MEASURETIME_MODELFUNCTIONS")%>

      //_historyImpl->write(v,v2,_simTime);
      _historyImpl->addContainerToWriteQueue(container);
      >>
    %>
    }
   }
   <%generateWriteOutputFunctionsForVars(modelInfo, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, '<%lastIdentOfPath(modelInfo.name)%>WriteOutput', useFlatArrayNotation)%>

   <%writeoutput1(modelInfo)%>
  >>
  //<%writeAlgloopvars(odeEquations,algebraicEquations,whenClauses,parameterEquations,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
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
let conditionvariables =  conditionvariable(zeroCrossings,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)

match modelInfo
  case MODELINFO(vars=SIMVARS(__)) then

/* changed: handled in SimVars class
  let getrealvars =
  (List.partition(listAppend(vars.algVars, listAppend(vars.discreteAlgVars, listAppend(vars.aliasVars, vars.paramVars))), 100) |> ls hasindex idx =>
    <<
    void getReal_<%idx%>(double* z);
    void setReal_<%idx%>(const double* z);
    >>
    ;separator="\n")
  let getintvars = (List.partition(listAppend(listAppend(vars.intAlgVars, vars.intParamVars), vars.intAliasVars), 100) |> ls hasindex idx =>
    <<
    void getInteger_<%idx%>(int* z);
    >>
    ;separator="\n")
  let getboolvars = (List.partition(listAppend(listAppend(vars.boolAlgVars, vars.boolParamVars), vars.boolAliasVars), 100) |> ls hasindex idx =>
    <<
    void getBoolean_<%idx%>(bool* z);
    >>
    ;separator="\n")
  */
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

      <%lastIdentOfPath(modelInfo.name)%>(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactor, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars);
      <%lastIdentOfPath(modelInfo.name)%>(<%lastIdentOfPath(modelInfo.name)%> &instance);

      virtual ~<%lastIdentOfPath(modelInfo.name)%>();

      <%generateMethodDeclarationCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>
      virtual bool getCondition(unsigned int index);

      boost::shared_ptr<IAlgLoopSolverFactory> getAlgLoopSolverFactory();
      boost::shared_ptr<ISimData> getSimData();

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
      //Called to handle all events occured at same time
      bool handleSystemEvents(bool* events);
      //Saves all variables before an event is handled, is needed for the pre, edge and change operator
      void saveAll();

      void defineAlgVars();
      void defineDiscreteAlgVars();
      void defineIntAlgVars();
      void defineBoolAlgVars();
      void defineParameterRealVars();
      void defineParameterIntVars();
      void defineParameterBoolVars();
      void defineAliasRealVars();
      void defineAliasIntVars();
      void defineAliasBoolVars();
      void defineMixedArrayVars();

      void getJacobian(SparseMatrix& matrix);
      void deleteObjects();

      //Variables:
      boost::shared_ptr<EventHandling> _event_handling;
      boost::shared_ptr<DiscreteEvents> _discrete_events;

      //pointer to simVars-array to speedup simulation and compile time
      double* _pointerToRealVars;
      int* _pointerToIntVars;
      bool* _pointerToBoolVars;

      <%memberVariableDefinitions%>
      <%memberPreVariableDefinitions%>
      <%conditionvariables%>
      Functions* _functions;

      boost::shared_ptr<IAlgLoopSolverFactory> _algLoopSolverFactory;    ///< Factory that provides an appropriate solver
      <%algloopsolver%>
      <%jacalgloopsolver%>

      <% if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
      <<
      #ifdef MEASURETIME_PROFILEBLOCKS
      std::vector<MeasureTimeData> measureTimeProfileBlocksArray;
      MeasureTimeValues *measuredProfileBlockStartValues, *measuredProfileBlockEndValues;
      #endif //MEASURETIME_PROFILEBLOCKS
      #ifdef MEASURETIME_MODELFUNCTIONS
      std::vector<MeasureTimeData> measureTimeFunctionsArray;
      MeasureTimeValues *measuredFunctionStartValues, *measuredFunctionEndValues;
      #endif //MEASURETIME_MODELFUNCTIONS
      >>%>

      <%memberfuncs%>
      <%additionalProtectedMembers%>
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

template generateEquationMemberFuncDecls(list<SimEqSystem> allEquations,Text method)
::=
  match allEquations
  case _ then
    let equation_func_decls = (allEquations |> eq => generateEquationMemberFuncDecls2(eq,method) ;separator="\n")
    <<
    /*! Index of the first equation. We use this to calculate the offset of an equation in the
       equation array given the index of the equation.*/
     int first_equation_index;
      <%equation_func_decls%>
    >>
  end match
end generateEquationMemberFuncDecls;



template generateEquationMemberFuncDecls2(SimEqSystem eq,Text method)
::=
    match eq
    case  e as SES_MIXED(__)
    then
     <<
     /*! Equations*/
     void <%method%>_<%equationIndex(e.cont)%>();
     void <%method%>_<%equationIndex(eq)%>();
     >>
     else
     <<
     /*! Equations*/
     FORCE_INLINE void <%method%>_<%equationIndex(eq)%>();
     >>
  end match
end generateEquationMemberFuncDecls2;

 /*
 <%modelname%>Algloop<%index%>(
                                       <%constructorParams%>
                                        double* z,double* zDot
                                       ,EventHandling& event_handling
                                      );
                                      */

template generateAlgloopClassDeclarationCode(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,SimEqSystem eq,Context context, Boolean useFlatArrayNotation)
 "Generates class declarations."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)

  let systemname = match context case  ALGLOOP_CONTEXT(genInitialisation=false,genJacobian=true)  then '<%modelname%>Jacobian' else '<%modelname%>'

  let algvars = memberVariableAlgloop(modelInfo, useFlatArrayNotation)
  let constructorParams = constructorParamAlgloop(modelInfo, useFlatArrayNotation)
  match eq
    case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
  <<
  class <%modelname%>Algloop<%ls.index%>: public IAlgLoop, public AlgLoopDefaultImplementation
  {
  public:
     //typedef for A- Matrix
    <%match eq case SES_LINEAR(__) then
        let size = listLength(ls.vars)
        <<
        typedef StatArrayDim2<double,<%size%>,<%size%>> AMATRIX;
        >>
    %>

      <%modelname%>Algloop<%ls.index%>( <%systemname%>* system
                                        ,double* z,double* zDot, bool* conditions
                                       ,boost::shared_ptr<DiscreteEvents> discrete_events
                                      );
      virtual ~<%modelname%>Algloop<%ls.index%>();

       <%generateAlgloopMethodDeclarationCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>

      bool getUseSparseFormat();
      void setUseSparseFormat(bool value);
    float queryDensity();

  protected:
   <% match eq
    case SES_LINEAR(__) then
    <<
    template <typename T>
    void evaluate(T* __A);
    >>
   %>
  private:
    Functions* _functions;

    //states
    double* __z;
    //state derivatives
    double* __zDot;
    // A matrix
    //boost::multi_array<double,2> *__A; //dense
    <%match eq case SES_LINEAR(__) then
    let size = listLength(ls.vars)
    <<

      boost::shared_ptr<AMATRIX> __A; //dense
     //b vector
     StatArrayDim1<double,<%size%>> __b;
    >>
    %>


    boost::shared_ptr<SparseMatrix> __Asparse; //sparse


    bool* _conditions;

     boost::shared_ptr<DiscreteEvents> _discrete_events;
     <%systemname%>* _system;

     bool _useSparseFormat;
   };
  >>

    case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
  <<
  class <%modelname%>Algloop<%nls.index%>: public IAlgLoop, public AlgLoopDefaultImplementation
  {
  public:
     //typedef for A- Matrix
    <%match eq case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
        let size = listLength(ls.vars)
        <<
        typedef StatArrayDim2<double,<%size%>,<%size%>> AMATRIX;
        >>
    %>

      <%modelname%>Algloop<%nls.index%>( <%systemname%>* system
                                        ,double* z,double* zDot, bool* conditions
                                       ,boost::shared_ptr<DiscreteEvents> discrete_events
                                      );
      virtual ~<%modelname%>Algloop<%nls.index%>();

       <%generateAlgloopMethodDeclarationCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>

      bool getUseSparseFormat();
      void setUseSparseFormat(bool value);
    float queryDensity();

  protected:
   <% match eq
    case SES_LINEAR(__) then
    <<
    template <typename T>
    void evaluate(T* __A);
    >>
   %>
  private:
    Functions* _functions;

    //states
    double* __z;
    //state derivatives
    double* __zDot;
    // A matrix
    //boost::multi_array<double,2> *__A; //dense
    <%match eq case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
    let size = listLength(ls.vars)
    <<

      boost::shared_ptr<AMATRIX> __A; //dense
     //b vector
     StatArrayDim1<double,<%size%>> __b;
    >>
    %>


    boost::shared_ptr<SparseMatrix> __Asparse; //sparse


    bool* _conditions;

     boost::shared_ptr<DiscreteEvents> _discrete_events;
     <%systemname%>* _system;

     bool _useSparseFormat;
   };
  >>
end generateAlgloopClassDeclarationCode;
/*
  <%algvars%>
  */
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

      void <%lastIdentOfPath(modelInfo.name)%>::setRHS(const double* f)
      {
        SystemDefaultImplementation::setRHS(f);
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
match eq
case SES_LINEAR(lSystem = ls as LINEARSYSTEM(__)) then
<<
/// Provide number (dimension) of variables according to data type
int  <%modelname%>Algloop<%ls.index%>::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  <%modelname%>Algloop<%ls.index%>::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  <%modelname%>Algloop<%ls.index%>::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  <%modelname%>Algloop<%ls.index%>::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
    <%giveAlgloopvars(eq, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)%>
};

/// Provide nominal variables with given index to the system
void  <%modelname%>Algloop<%ls.index%>::getNominalReal(double* vars)
{
    <%giveAlgloopNominalvars(eq, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)%>
};

/// Set variables with given index to the system
void  <%modelname%>Algloop<%ls.index%>::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode

    <%setAlgloopvars(eq,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)%>
    AlgLoopDefaultImplementation::setReal(vars);
};


>>
case SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__)) then
<<
/// Provide number (dimension) of variables according to data type
int  <%modelname%>Algloop<%nls.index%>::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  <%modelname%>Algloop<%nls.index%>::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  <%modelname%>Algloop<%nls.index%>::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  <%modelname%>Algloop<%nls.index%>::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
    <%giveAlgloopvars(eq, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)%>
};

/// Provide nominal variables with given index to the system
void  <%modelname%>Algloop<%nls.index%>::getNominalReal(double* vars)
{
    <%giveAlgloopNominalvars(eq, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)%>
};

/// Set variables with given index to the system
void  <%modelname%>Algloop<%nls.index%>::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode

    <%setAlgloopvars(eq,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)%>
    AlgLoopDefaultImplementation::setReal(vars);
};


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
    /// Provide number (dimension) of boolean variables
    virtual int getDimBoolean() const;
    /// Provide number (dimension) of integer variables
    virtual int getDimInteger() const;
    /// Provide number (dimension) of real variables
    virtual int getDimReal() const ;
    /// Provide number (dimension) of string variables
    virtual int getDimString() const ;
    /// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
    virtual int getDimRHS()const;

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
    virtual void setRHS(const double* f);

    //Provide number (dimension) of zero functions
    virtual int getDimZeroFunc();
    //Provides current values of root/zero functions
    virtual void getZeroFunc(double* f);
    virtual void setConditions(bool* c);
    virtual void getConditions(bool* c);

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
    /// Provide number (dimension) of variables according to data type
    virtual int getDimReal() const;
    /// Provide number (dimension) of residuals according to data type
    virtual int getDimRHS() const;
     /// (Re-) initialize the system of equations
    virtual void initialize();

    template <typename T>
    void initialize(T *__A);

    /// Provide variables with given index to the system
    virtual void getReal(double* vars);
     /// Provide variables with given index to the system
    virtual void getNominalReal(double* vars);
    /// Set variables with given index to the system
    virtual void setReal(const double* vars);
    /// Update transfer behavior of the system of equations according to command given by solver
    virtual void evaluate();
    /// Provide the right hand side (according to the index)
    virtual void getRHS(double* vars);
    <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then
    <<
    /// Provide dimensions of residuals for linear equation systems
    virtual int giveDimResiduals(int index);
    /// Provide the residuals for linear equation systems
    virtual void giveResiduals(double* vars);
    >>%>
    /// Output routine (to be called by the solver after every successful integration step)
    virtual void getSystemMatrix(double* A_matrix);
    virtual void getSystemMatrix(SparseMatrix* A_matrix);
    virtual bool isLinear();
    virtual bool isLinearTearing();
    virtual bool isConsistent();

>>
//void writeOutput(HistoryImplType::value_type_v& v ,vector<string>& head ,const IMixedSystem::OUTPUT command  = IMixedSystem::UNDEF_OUTPUT);
end generateAlgloopMethodDeclarationCode;

template memberVariableDefine(ModelInfo modelInfo, HashTableCrIListArray.HashTable varToArrayIndexMapping, Text indexForUndefinedReferencesReal, Text indexForUndefinedReferencesInt,
                        Text indexForUndefinedReferencesBool, Boolean useFlatArrayNotation)
 /*Define membervariable in simulation file.*/
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
   /*parameter real vars*/
   <%vars.paramVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, "Real", true)
   ;separator="\n"%>
   /*parameter int vars*/
   <%vars.intParamVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesInt, useFlatArrayNotation, "Int", true)
  ;separator="\n"%>
   /*parameter bool vars*/
   <%vars.boolParamVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesBool, useFlatArrayNotation, "Bool", true)
  ;separator="\n"%>
  /*string parameter variables*/
   <%vars.stringParamVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, "0", useFlatArrayNotation, "String", false)
  ;separator="\n"%>
   /*string alias variables*/
   <%vars.stringAliasVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, "0", useFlatArrayNotation, "String", false)
   ;separator="\n"%>
   /*external variables*/
   <%vars.extObjVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, "Real",  false)
   ;separator="\n"%>
   /*alias real vars*/
   <%vars.aliasVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, "Real", true)
   ;separator="\n"%>
   /*alias int vars*/
   <%vars.intAliasVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesInt, useFlatArrayNotation, "Int", true)
   ;separator="\n"%>
    /*alias bool vars*/
   <%vars.boolAliasVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesBool, useFlatArrayNotation, "Bool", true)
   ;separator="\n"%>
   /*string algvars*/
   <%vars.stringAlgVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, "0", useFlatArrayNotation, "String", true)
  ;separator="\n"%>
 >>
end memberVariableDefine;

template memberVariableDefinePreVariables(ModelInfo modelInfo, HashTableCrIListArray.HashTable varToArrayIndexMapping, Text indexForUndefinedReferencesReal, Text indexForUndefinedReferencesInt,
                                    Text indexForUndefinedReferencesBool, Boolean useFlatArrayNotation)
 "Define membervariable in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  //Variables saved for pre, edge and change operator
   /*real algvars*/
  <%vars.algVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, "Real", true)
  ;separator="\n"%>
  /*discrete algvars*/
  <%vars.discreteAlgVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, "Real", true)
  ;separator="\n"%>
   /*int algvars*/
   <%vars.intAlgVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesInt, useFlatArrayNotation, "Int", true)
  ;separator="\n"%>
  /*bool algvars*/
  <%vars.boolAlgVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesBool, useFlatArrayNotation, "Bool", true)
  ;separator="\n"%>
   /*mixed array variables*/
   <%vars.mixedArrayVars |> var =>
    memberVariableDefine2(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, "Real", true)
   ;separator="\n"%>
  >>
end memberVariableDefinePreVariables;

template memberVariableInitialize(ModelInfo modelInfo, HashTableCrIListArray.HashTable varToArrayIndexMapping, Text indexForUndefinedReferencesReal, Text indexForUndefinedReferencesInt,
                                  Text indexForUndefinedReferencesBool, Boolean useFlatArrayNotation, Text& additionalConstructorVariables, Text& additionalFunctionDefinitions)
::=
  match modelInfo
    case MODELINFO(vars=SIMVARS(__),name=name) then
      let classname = lastIdentOfPath(name)
      let &additionalAlgVarFunctionCalls = buffer ""
      let &additionalDiscreteAlgVarFunctionCalls = buffer ""
      let &additionalIntAlgVarFunctionCalls = buffer ""
      let &additionalBoolAlgVarFunctionCalls = buffer ""
      let &additionalParameterRealVarFunctionCalls = buffer ""
      let &additionalParameterIntVarFunctionCalls = buffer ""
      let &additionalParameterBoolVarFunctionCalls = buffer ""
      let &additionalAliasRealVarFunctionCalls = buffer ""
      let &additionalAliasIntVarFunctionCalls = buffer ""
      let &additionalAliasBoolVarFunctionCalls = buffer ""
      let &additionalMixedArrayVarFunctionCalls = buffer ""
      let &returnValue = buffer ""

      <<
      //AlgVars
      <%List.partition(vars.algVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineAlgVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, "Real",
                                          true, additionalAlgVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>

      void <%classname%>::defineAlgVars()
      {
        <%additionalAlgVarFunctionCalls%>
      }

      //DiscreteAlgVars
      <%List.partition(vars.discreteAlgVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineDiscreteAlgVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, "Real",
                                          true, additionalDiscreteAlgVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>

      void <%classname%>::defineDiscreteAlgVars()
      {
        <%additionalDiscreteAlgVarFunctionCalls%>
      }

      //IntAlgVars
      <%List.partition(vars.intAlgVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineIntAlgVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesInt, useFlatArrayNotation, "Int",
                                          true, additionalIntAlgVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineIntAlgVars()
      {
        <%additionalIntAlgVarFunctionCalls%>
      }

      //BoolAlgVars
      <%List.partition(vars.boolAlgVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineBoolAlgVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesBool, useFlatArrayNotation, "Bool",
                                          true, additionalBoolAlgVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineBoolAlgVars()
      {
        <%additionalBoolAlgVarFunctionCalls%>
      }

      //ParameterRealVars
      <%List.partition(vars.paramVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineParameterRealVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, "Real",
                                          true, additionalParameterRealVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineParameterRealVars()
      {
        <%additionalParameterRealVarFunctionCalls%>
      }

      //ParameterIntVars
      <%List.partition(vars.intParamVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineParameterIntVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesInt, useFlatArrayNotation, "Int",
                                          true, additionalParameterIntVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineParameterIntVars()
      {
        <%additionalParameterIntVarFunctionCalls%>
      }

      //ParameterBoolVars
      <%List.partition(vars.boolParamVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineParameterBoolVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesBool, useFlatArrayNotation, "Bool",
                                          true, additionalParameterBoolVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineParameterBoolVars()
      {
        <%additionalParameterBoolVarFunctionCalls%>
      }

      //AliasRealVars
      <%List.partition(vars.aliasVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineAliasRealVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, "Real",
                                          true, additionalAliasRealVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineAliasRealVars()
      {
        <%additionalAliasRealVarFunctionCalls%>
      }

      //AliasIntVars
      <%List.partition(vars.intAliasVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineAliasIntVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesInt, useFlatArrayNotation, "Int",
                                          true, additionalAliasIntVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineAliasIntVars()
      {
        <%additionalAliasIntVarFunctionCalls%>
      }

      //AliasBoolVars
      <%List.partition(vars.boolAliasVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineAliasBoolVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesBool, useFlatArrayNotation, "Bool",
                                          true, additionalAliasBoolVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineAliasBoolVars()
      {
        <%additionalAliasBoolVarFunctionCalls%>
      }

      //MixedArrayVars
      <%List.partition(vars.mixedArrayVars, 100) |> varPartition hasindex i0 =>
        memberVariableInitializeWithSplit(varPartition, i0, "defineMixedArrayVars", classname, varToArrayIndexMapping, indexForUndefinedReferencesReal, useFlatArrayNotation, "Real",
                                          true, additionalMixedArrayVarFunctionCalls,additionalConstructorVariables,additionalFunctionDefinitions) ;separator="\n"%>
      void <%classname%>::defineMixedArrayVars()
      {
        <%additionalMixedArrayVarFunctionCalls%>
      }
      >>
end memberVariableInitialize;

template memberVariableInitializeWithSplit(list<SimVar> simVars, Text idx, Text functionPrefix, Text className, HashTableCrIListArray.HashTable varToArrayIndexMapping, Text indexForUndefinedReferences, Boolean useFlatArrayNotation,
                                   String type, Boolean createRefVar, Text& additionalFunctionCalls, Text& additionalConstructorVariables, Text& additionalFunctionDefinitions)
::=
  let &additionalFunctionCalls += '  <%functionPrefix%>_<%idx%>();<%\n%>'
  let &additionalFunctionDefinitions += 'void <%functionPrefix%>_<%idx%>();<%\n%>'
  <<
  void <%className%>::<%functionPrefix%>_<%idx%>()
  {
    <%simVars |> var =>
        memberVariableInitialize2(var, varToArrayIndexMapping, indexForUndefinedReferences, useFlatArrayNotation, type, createRefVar, additionalConstructorVariables)
        ;separator="\n"%>
  }
  >>
end memberVariableInitializeWithSplit;

template memberVariableInitialize2(SimVar simVar, HashTableCrIListArray.HashTable varToArrayIndexMapping, Text indexForUndefinedReferences, Boolean useFlatArrayNotation,
                                   String type, Boolean createRefVar, Text& additionalConstructorVariables)
::=

match simVar
    case SIMVAR(numArrayElement={},arrayCref=NONE(),name=CREF_IDENT(subscriptLst=_::_)) then ''

    case SIMVAR(numArrayElement={},arrayCref=NONE()) then
      //let index = '<%listHead(SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,indexForUndefinedReferences))%>'
      //let &additionalConstructorVariables += ',<%cref(name,useFlatArrayNotation)%>(_sim_vars->init<%type%>Var(<%index%>))<%\n%>'
      ""
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
            //let index = '<%listHead(SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,indexForUndefinedReferences))%>'
            //let& additionalConstructorVariables += ',<%arrayName%>(_sim_vars->init<%type%>Var(<%index%>))'
            ""
          else
            let size =  Util.mulStringDelimit2Int(array_num_elem,",")
            if SimCodeUtil.isVarIndexListConsecutive(varToArrayIndexMapping,name) then
              let arrayHeadIdx = listHead(SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,indexForUndefinedReferences))
              <<
              <%arrayName%> = StatRefArrayDim<%dims%><<%typeString%>, <%arrayextentDims(name, v.numArrayElement)%>>(&_pointerTo<%type%>Vars[<%arrayHeadIdx%>]);
              >>
            else
              let arrayIndices = SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,indexForUndefinedReferences) |> idx => '(<%idx%>)'; separator=""
              <<
              <%typeString%>* <%arrayName%>_ref_data[<%size%>];
              _sim_vars->init<%type%>AliasArray(boost::assign::list_of<%arrayIndices%>,<%arrayName%>_ref_data);
              <%arrayName%> = RefArrayDim<%dims%><<%typeString%>, <%arrayextentDims(name, v.numArrayElement)%>>(<%arrayName%>_ref_data);
              >>
   /*special case for variables that marked as array but are not arrays */
    case SIMVAR(numArrayElement=_::_) then

      let& dims = buffer "" /*BUFD*/
      let varName = arraycref2(name,dims)
      let varType = variableType(type_)
      match dims
        case "0" then
          //let index = '<%listHead(SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,indexForUndefinedReferences))%>'
          //let& additionalConstructorVariables += ',<%varName%>(_sim_vars->init<%type%>Var(<%index%>))'
          ""
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
                              Boolean useFlatArrayNotation, String type, Boolean createRefVar)
::=
  match simVar
    case SIMVAR(numArrayElement={},arrayCref=NONE(),name=CREF_IDENT(subscriptLst=_::_)) then ''

    case SIMVAR(numArrayElement={},arrayCref=NONE()) then
      /*
      <<
      <%variableType(type_)%><%if createRefVar then '&' else ''%> <%cref(name,useFlatArrayNotation)%>;
      >>
      */
      if createRefVar then
        let index = '<%listHead(SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,indexForUndefinedReferences))%>'
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
        /*
        <<
        <%typeString%><%if createRefVar then '&' else ''%> <%arrayName%>;
        >>
        */
        if createRefVar then
          let index = '<%listHead(SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,indexForUndefinedReferences))%>'
          <<
          #define <%arrayName%> _pointerTo<%type%>Vars[<%index%>]
          >>
        else
          '<%typeString%> <%arrayName%>;'
      else
        if SimCodeUtil.isVarIndexListConsecutive(varToArrayIndexMapping,name) then
          <<
          StatRefArrayDim<%dims%><<%typeString%>, <%array_dimensions%>> <%arrayName%>;
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
          //'<%varType%><%if createRefVar then '&' else ''%> <%varName%>;'
          if createRefVar then
            let index = '<%listHead(SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,indexForUndefinedReferences))%>'
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

template lastIdentOfPathFromSimCode(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace) ::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
    lastIdentOfPath(modelInfo.name)
end lastIdentOfPathFromSimCode;

template cref(ComponentRef cr, Boolean useFlatArrayNotation)
 "Generates C equivalent name for component reference."
::=
  match cr
  case CREF_IDENT(ident = "time") then "_simTime"
  case WILD(__) then ''
  else "_"+crefToCStr(cr, useFlatArrayNotation)
end cref;

template varToString(ComponentRef cr,Context context, Boolean useFlatArrayNotation)
 "Generates C equivalent name for component reference."
::=
 match context
    case JACOBIAN_CONTEXT()
              //then   <<<%crefWithoutIndexOperator(cr)%>>>
              then   '_<%crefToCStr(cr,false)%>'
 else
  match cr
   case CREF_IDENT(ident = "time") then "_simTime"
   case WILD(__) then ''
   else "_"+crefToCStr(cr, useFlatArrayNotation)
end varToString;

template localcref(ComponentRef cr, Boolean useFlatArrayNotation)
 "Generates C equivalent name for component reference."
::=
  match cr
  case CREF_IDENT(ident = "time") then "_simTime"
  case WILD(__) then ''
  else crefToCStr(cr,useFlatArrayNotation)
end localcref;


template cref2(ComponentRef cr, Boolean useFlatArrayNotation)
 "Generates C equivalent name for component reference."
::=
  match cr
  case CREF_IDENT(ident = "xloc") then '<%crefStr(cr)%>'
  case CREF_IDENT(ident = "time") then "_simTime"
  case WILD(__) then ''
  else "_"+crefToCStr(cr,useFlatArrayNotation)
end cref2;

template crefToCStr(ComponentRef cr, Boolean useFlatArrayNotation)
 "Helper function to cref."
::=
  match cr
  case CREF_IDENT(__) then '<%ident%><%subscriptsToCStr(subscriptLst, useFlatArrayNotation)%>'
  case CREF_QUAL(__) then '<%ident%><%subscriptsToCStrForArray(subscriptLst)%>_P_<%crefToCStr(componentRef,useFlatArrayNotation)%>'
  case WILD(__) then ''
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStr;


template subscriptsToCStr(list<Subscript> subscripts, Boolean useFlatArrayNotation)
::=
  if subscripts then

    if useFlatArrayNotation then
        '_<%subscripts |> s => subscriptToCStr(s) ;separator="_"%>'
    else
        '(<%subscripts |> s => subscriptToCStr(s) ;separator=","%>)'
end subscriptsToCStr;

template subscriptToCStr(Subscript subscript)
::=
  match subscript
  case SLICE(exp=ICONST(integer=i)) then i
  case WHOLEDIM(__) then "WHOLEDIM"
  case INDEX(__) then
   match exp
    case ICONST(integer=i) then i
    case ENUM_LITERAL(index=i) then i
    end match
  else "UNKNOWN_SUBSCRIPT"
end subscriptToCStr;



template arraycref(ComponentRef cr, Boolean useFlatArrayNotation)
::=
  match cr
  case CREF_IDENT(ident = "xloc") then crefStr(cr)
  case CREF_IDENT(ident = "time") then "_simTime"
  case WILD(__) then ''
  else "_"+crefToCStr1(cr, useFlatArrayNotation)
end arraycref;


template arraycref2(ComponentRef cr, Text& dims)
::=
  match cr
  case CREF_IDENT(ident = "xloc") then crefStr(cr)
  case CREF_IDENT(ident = "time") then "_simTime"
  case WILD(__) then ''
  else "_"+crefToCStrForArray(cr,dims)
end arraycref2;
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

template crefToCStrForArray(ComponentRef cr, Text& dims)
::=
  match cr
  case CREF_IDENT(__) then
  let &dims+=listLength(subscriptLst)
  '<%ident%>'
 case CREF_QUAL(__) then               '<%ident%><%subscriptsToCStrForArray(subscriptLst)%>_P_<%crefToCStrForArray(componentRef,dims)%>'

  case WILD(__) then ' '
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStrForArray;


template crefToCStr1(ComponentRef cr, Boolean useFlatArrayNotation)
::=
  match cr
  case CREF_IDENT(__) then '<%ident%>'
 case CREF_QUAL(__) then               '<%ident%><%subscriptsToCStrForArray(subscriptLst)%>_P_<%crefToCStr1(componentRef,useFlatArrayNotation)%>'

  case WILD(__) then ' '
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStr1;

template subscriptsToCStrForArray(list<Subscript> subscripts)
::=
  if subscripts then
    '<%subscripts |> s => subscriptToCStr(s) ;separator="$c"%>'
end subscriptsToCStrForArray;
/*
tempalte for writing output variable names in mat or csv files
*/
template crefStrForWriteOutput(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(ident = "xloc") then '__xd<%subscriptsStrForWriteOutput(subscriptLst)%>'
  case CREF_IDENT(ident = "time") then "_simTime"
  case CREF_IDENT(__) then '<%ident%><%subscriptsStrForWriteOutput(subscriptLst)%>'
  // Are these even needed? Function context should only have CREF_IDENT :)
  case CREF_QUAL(ident = "$DER") then 'der(<%crefStrForWriteOutput(componentRef)%>)'
  case CREF_QUAL(__) then '<%ident%><%subscriptsStrForWriteOutput(subscriptLst)%>.<%crefStrForWriteOutput(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end crefStrForWriteOutput;

template subscriptsStrForWriteOutput(list<Subscript> subscripts)
 "Generares subscript part of the name."
::=
  if subscripts then
    '[<%subscripts |> s => subscriptStr(s) ;separator=","%>]'//previous multi_array     '[<%subscripts |> s => subscriptStr(s) ;separator=","%>]'
end subscriptsStrForWriteOutput;

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

template crefStr(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(ident = "xloc") then '__xd<%subscriptsStr(subscriptLst)%>'
  case CREF_IDENT(ident = "time") then "_simTime"
  //filter key words for variable names
  case CREF_IDENT(ident = "unsigned") then 'unsigned_'
  case CREF_IDENT(ident = "string") then 'string_'
  case CREF_IDENT(ident = "int") then 'int_'
  case CREF_IDENT(__) then '<%ident%><%subscriptsStr(subscriptLst)%>'
  // Are these even needed? Function context should only have CREF_IDENT :)
  case CREF_QUAL(ident = "$DER") then 'der(<%crefStr(componentRef)%>)'
  case CREF_QUAL(__) then '<%ident%><%subscriptsStr(subscriptLst)%>.<%crefStr(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end crefStr;

template subscriptsStr(list<Subscript> subscripts)
 "Generares subscript part of the name."
::=
  if subscripts then
    '(<%subscripts |> s => subscriptStr(s) ;separator=","%>)'//previous multi_array     '[<%subscripts |> s => subscriptStr(s) ;separator=","%>]'
end subscriptsStr;

template subscriptStr(Subscript subscript)
 "Generates a single subscript.
  Only works for constant integer indicies."
::=
  match subscript
  case INDEX(exp=ICONST(integer=i)) then i
  case SLICE(exp=ICONST(integer=i)) then i
  case WHOLEDIM(__) then "WHOLEDIM"
  else "UNKNOWN_SUBSCRIPT"
end subscriptStr;

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
//the index 0 is reserved for undefined references
<<
<%intAdd(1, intAdd(varInfo.numOptimizeFinalConstraints, intAdd(varInfo.numOptimizeConstraints, intAdd(varInfo.numOutVars, intAdd(varInfo.numInVars ,intAdd(intMul(2,varInfo.numStateVars),intAdd(varInfo.numAlgVars,intAdd(varInfo.numParams,varInfo.numDiscreteReal))))))))
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
//the index 0 is reserved for undefined references
<<
<%intAdd(1, intAdd(varInfo.numIntAlgVars,varInfo.numIntParams))%>
>>
end numIntvars;

template numBoolvars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
//the index 0 is reserved for undefined references
<<
<%intAdd(1, intAdd(varInfo.numBoolAlgVars,varInfo.numBoolParams))%>
>>
end numBoolvars;

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
         _sim_vars->savePreVariables();
    }
    >>

end saveAll;








/*
 <<
  void <%className%>::initPreVars_<%partIdx%>(unordered_map<double* const,unsigned int>& vars1, unordered_map<double* const,unsigned int>& vars2)
  {
      insert(vars1)
      <%(partVars |> SIMVAR(__) hasindex i0 fromindex (intMul(partIdx, multiplicator)) =>
        '<%\t%>(&<%cref(name, useFlatArrayNotation)%>,<%i0%>)'
        ;separator="\n")%>;
      <%if (intLt(intMul(partIdx, multiplicator), stateVarStartIdx)) then
        <<
        insert(vars2)
        <%(partVars |> SIMVAR(__) hasindex i0 fromindex (intMul(partIdx, multiplicator)) =>
          if (intLt(i0, stateVarStartIdx)) then
              '<%\t%>(&<%cref(name, useFlatArrayNotation)%>,<%i0%>)'
          else ''
          ;separator="\n")%>;
         >>
      %>
  }
  >>
*/

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
    var_ouputs_idx =  boost::assign::map_list_of <%
    {(vars.outputVars |> SIMVAR(__) =>  '(<%index%>,"<%crefStr(name)%>")';separator=",") };separator=","%>;
    >>
end outputIndices;


template isOutput(Causality c, Boolean useFlatArrayNotation)
 "Returns the Causality Attribute of a Variable."
::=
match c
  case OUTPUT(__) then "output"
end isOutput;


template initAliasValstWithSplit(Text type, Text funcNamePrefix, list<SimVar> varsLst, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                                 Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
  let &funcCalls = buffer "" /*BUFD*/
  let funcs = List.partition(varsLst, 100) |> ls hasindex idx =>
    let &varDecls = buffer "" /*BUFD*/
    let &funcCalls += '<%funcNamePrefix%>_<%idx%>();'
    let init = initAliasValst(varDecls, type, ls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)
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
end initAliasValstWithSplit;


template initStringAliasValstWithSplit(Text type, Text funcNamePrefix, list<SimVar> varsLst, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                                 Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
  let &funcCalls = buffer "" /*BUFD*/
  let funcs = List.partition(varsLst, 100) |> ls hasindex idx =>
    let &varDecls = buffer "" /*BUFD*/
    let &funcCalls += '<%funcNamePrefix%>_<%idx%>();'
    let init = initStringAliasValst(varDecls, type, ls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)
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
end initStringAliasValstWithSplit;

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


template initValst(Text &varDecls, Text type, list<SimVar> varsLst, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
   varsLst |> sv as SIMVAR(__) =>
     let &preExp = buffer "" /*BUFD*/
     let &varDeclsCref = buffer "" /*BUFD*/

     match initialValue
      case SOME(v) then
        match daeExp(v, contextOther, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
          case vStr as "0"
          case vStr as "0.0"
          case vStr as "(0)" then
          '<%preExp%>
           set<%type%>StartValue(<%cref1(sv.name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>,<%vStr%>);'
          case vStr as "" then
          '<%preExp%>
           set<%type%>StartValue(<%cref1(sv.name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>,<%vStr%>);'
          case vStr then
          '<%preExp%>

           set<%type%>StartValue(<%cref1(sv.name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>,<%vStr%>);'
        end match
      else
        '<%preExp%>

         set<%type%>StartValue(<%cref1(sv.name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>,<%startValue(sv.type_)%>);'
      ;separator="\n"
end initValst;


template initAliasValst(Text &varDecls, Text type, list<SimVar> varsLst, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace,
                        Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
  varsLst |> sv as SIMVAR(__) =>
       let &preExp = buffer ""
       let &varDeclsCref = buffer ""
       let initval = getAliasInitVal(sv.aliasvar, contextOther, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
       <<
       <%preExp%>
       set<%type%>StartValue(<%getAliasCRef(sv.aliasvar, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName, useFlatArrayNotation)%>, <%initval%>);
       >>
    ;separator="\n"
end initAliasValst;


template initStringAliasValst(Text &varDecls, Text type, list<SimVar> varsLst, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace,
                        Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
  varsLst |> sv as SIMVAR(__) =>
       let &preExp = buffer ""
       let initval = getAliasInitVal(sv.aliasvar, contextOther, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        '<%preExp%>
         set<%type%>StartValue(<%cref1(sv.name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDecls, stateDerVectorName, useFlatArrayNotation)%>,<%initval%>);'
    ;separator="\n"
end initStringAliasValst;


template getAliasInitVal(AliasVariable aliasvar, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                         Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Returns the alias Attribute of ScalarVariable."
::=
   match aliasvar
    case ALIAS(__)
    case NEGATEDALIAS(__) then getAliasInitVal2(varName, context, preExp, varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    else 'noAlias'

end getAliasInitVal;

template getAliasInitVal2(ComponentRef aliascref, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                          Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Returns the alias Attribute of ScalarVariable."
::=
cref2simvar(aliascref, simCode ) |> var  as SIMVAR(__)=>
 match initialValue
   case SOME(v) then
       daeExp(v, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
   else
       startValue(var.type_)
end getAliasInitVal2;


template getVarFromAliasName(ComponentRef varname, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                         Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Returns the alias Attribute of ScalarVariable."
::=
 cref2simvar(varname, simCode ) |> var  as SIMVAR(__)=>
 getVarFromAliasName2(var.aliasvar,varname,context, &preExp, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName,useFlatArrayNotation)
end getVarFromAliasName;


template getVarFromAliasName2(AliasVariable aliasvar,ComponentRef origvarname, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                         Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Returns the alias Attribute of ScalarVariable."
::=
 match aliasvar
    case NOALIAS(__) then '<%cref1(origvarname, simCode ,&extraFuncs ,&extraFuncsDecl, extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>'
    case ALIAS(__)
    case NEGATEDALIAS(__) then '<%cref1(varName, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>'
end getVarFromAliasName2;

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


template dimension1(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__)))
      then
        let numRealVars = numRealvars(modelInfo)
        let numIntVars = numIntvars(modelInfo)
        let numBoolVars = numBoolvars(modelInfo)
        <<
        _dimContinuousStates = <%vi.numStateVars%>;
        _dimRHS = <%vi.numStateVars%>;
        _dimBoolean = <%numBoolVars%>;
        _dimInteger = <%numIntVars%>;
        _dimString = <%vi.numStringAlgVars%> + <%vi.numStringParamVars%>;
        _dimReal = <%numRealVars%>;
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


template contextArrayCref(ComponentRef cr, Context context)
 "Generates code for an array component reference depending on the context."
::=
  match context
  case FUNCTION_CONTEXT(__) then arrayCrefStr(cr)
  else arrayCrefCStr(cr,context)
end contextArrayCref;

template arrayCrefStr(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(ident = "time") then "_simTime"
  case CREF_IDENT(__) then '<%ident%>'
  case CREF_QUAL(__) then '<%ident%>.<%arrayCrefStr(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end arrayCrefStr;

template expTypeFlag(DAE.Type ty, Integer flag)

::=
  match flag
  case 1 then
    // we want the short typesmuwww.
    expTypeShort(ty)
  case 2 then
    // we want the "modelica type"
    match ty case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__)) then
      '<%expTypeShort(ty)%>'
    else match ty case T_COMPLEX(complexClassType=RECORD(path=rname)) then
      '<%underscorePath(rname)%>Type'
    else match ty case T_COMPLEX(__) then
      '<%underscorePath(ClassInf.getStateName(complexClassType))%>'
     else
      '<%expTypeShort(ty)%>'
  case 3 then
    // we want the "array type"
    '<%expTypeShort(ty)%>'
  case 4 then
    match ty
    case T_ARRAY(__) then '<%expTypeShort(ty)%>'
    else expTypeFlag(ty, 2)
    end match
  case 5 then
    match ty
  /* previous multiarray
    case T_ARRAY(dims=dims) then 'multi_array_ref<<%expTypeShort(ty)%>,<%listLength(dims)%>>'
    */
  case T_ARRAY(dims=dims) then
  //let testbasearray = dims |> dim =>  '<%testdimension(dim)%>' ;separator=''
  let dimstr = checkDimension(dims)
  match dimstr
  case "" then 'DynArrayDim<%listLength(dims)%><<%expTypeShort(ty)%>>'
  else 'StatArrayDim<%listLength(dims)%><<%expTypeShort(ty)%>,<%dimstr%>>&'
  else expTypeFlag(ty, 2)
    end match




  case 6 then
    match ty

    //case T_ARRAY(dims=dims) then 'StatArrayDim<%listLength(dims)%><<%expTypeShort(ty)%>,<%(dims |> dim as DIM_INTEGER(integer=i)  =>  '<%i%>';separator=",")%>>' //'multi_array<<%expTypeShort(ty)%>,<%listLength(dims)%>>'
    //let dimstr = dims |> dim => match dim   case DIM_INTEGER(__) then '<%integer%>'  else 'error index';separator=','

  case T_ARRAY(dims=dims,ty=type) then
   //let testbasearray = dims |> dim =>  '<%testdimension(dim)%>' ;separator=''
   //let dimstr = dims |> dim =>  '<%dimension(dim)%>' ;separator=','
   let dimstr = checkDimension(dims)
   match dimstr
   case "" then 'DynArrayDim<%listLength(dims)%><<%expTypeShort(type)%>>'
   //case
   else   'StatArrayDim<%listLength(dims)%><<%expTypeShort(type)%>,<%dimstr%>>'
    end match
   else expTypeFlag(ty, 2)
    end match

  case 7 then
     match ty
    case T_ARRAY(dims=dims)
    then
     'multi_array<<%expTypeShort(ty)%>,<%listLength(dims)%>>'
    end match

  case 8 then
    match ty
  case T_ARRAY(dims=dims) then'BaseArray<<%expTypeShort(ty)%>>&'
  else expTypeFlag(ty, 9)
    end match

  case 9 then
  // we want the "modelica type"
  match ty case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__)) then
    '<%expTypeShort(ty)%>'
  else match ty case T_COMPLEX(complexClassType=RECORD(path=rname)) then
    '<%underscorePath(rname)%>Type &'
  else match ty case T_COMPLEX(__) then
    '<%underscorePath(ClassInf.getStateName(complexClassType))%> &'
   else
    '<%expTypeShort(ty)%>'

end expTypeFlag;


template allocateDimensions(DAE.Type ty,Context context)
::=
 match ty
     case T_ARRAY(dims=dims) then
     let dimstr = dims |> dim =>  '<%dimension(dim,context)%>'  ;separator=','
    <<
    <%dimstr%>
    >>

end allocateDimensions;

template expTypeArray(DAE.Type ty)

::=
  expTypeFlag(ty, 3)
end expTypeArray;

template expTypeArrayforDim(DAE.Type ty)

::=
  expTypeFlag(ty, 6)
end expTypeArrayforDim;

template expTypeShort(DAE.Type type)

::=
  match type
  case T_INTEGER(__)         then "int"
  case T_REAL(__)        then "double"
  case T_STRING(__)      then if acceptMetaModelicaGrammar() then "metatype" else "string"
  case T_BOOL(__)        then "bool"
  case T_ENUMERATION(__) then "int"
  /* assumming real for uknown type! */
  case T_UNKNOWN(__)     then "double /*W1*/"
  case T_ANYTYPE(__)     then "complex2"
  case T_ARRAY(__)       then expTypeShort(ty)
  case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__))
                      then "void*"
  case T_COMPLEX(__)     then '<%underscorePath(ClassInf.getStateName(complexClassType))%>Type'
  case T_METATYPE(__) case T_METABOXED(__)    then "metatype"
  case T_FUNCTION_REFERENCE_VAR(__) then "fnptr"
  else "expTypeShort:ERROR"
end expTypeShort;

template dimension(Dimension d,Context context)
::=
  match d
  case DAE.DIM_BOOLEAN(__) then '2'
  case DAE.DIM_INTEGER(__) then integer
  case DAE.DIM_ENUM(__) then size
  case DAE.DIM_EXP(exp=e) then dimensionExp(e,context, false)
  case DAE.DIM_UNKNOWN(__) then '-1'//error(sourceInfo(),"Unknown dimensions may not be part of generated code. This is most likely an error on the part of OpenModelica. Please submit a detailed bug-report.")
  else error(sourceInfo(), 'dimension: INVALID_DIMENSION')
end dimension;

template checkDimension(Dimensions dims)
::=
  dimensionsList(dims) |> dim as Integer   =>  '<%dim%>';separator=","

end checkDimension;



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

template dimensionExp(DAE.Exp dimExp,Context context,Boolean useFlatArrayNotation)
::=
  match dimExp
  case DAE.CREF(componentRef = cr) then
   match context
    case FUNCTION_CONTEXT(__) then System.unquoteIdentifier(crefStr(cr))
   else '<%cref(cr, useFlatArrayNotation)%>'
  else '/* fehler dimensionExp: INVALID_DIMENSION <%printExpStr(dimExp)%>*/' //error(sourceInfo(), 'dimensionExp: INVALID_DIMENSION <%printExpStr(dimExp)%>')
end dimensionExp;

template arrayCrefCStr(ComponentRef cr,Context context)
::=
match context
case ALGLOOP_CONTEXT(genInitialisation = false) then
 let& dims = buffer "" /*BUFD*/
<< _system->_<%crefToCStrForArray(cr,dims)%> >>
else
let& dims = buffer "" /*BUFD*/
'_<%crefToCStrForArray(cr,dims)%>'
end arrayCrefCStr;

template arrayCrefCStr2(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(__) then '<%unquoteIdentifier(ident)%>'
  case CREF_QUAL(__) then '<%unquoteIdentifier(ident)%>_P_<%arrayCrefCStr2(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end arrayCrefCStr2;
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

template tempDecl(String ty, Text &varDecls /*BUFP*/)
 "Declares a temporary variable in varDecls and returns the name."
::=
  let newVar = 'tmp<%System.tmpTick()%>'
  let &varDecls += '<%ty%> <%newVar%>;<%\n%>'
  newVar
end tempDecl;

template tempDeclAssign(String ty, Text &varDecls /*BUFP*/,String assign)
 "Declares a temporary variable in varDecls and returns the name."
::=
  let newVar = 'tmp<%System.tmpTick()%>'
  let &varDecls += '<%ty%> <%newVar%> = <%assign%>;<%\n%>'
  newVar
end tempDeclAssign;

template contextCref(ComponentRef cr, Context context,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  "Generates code for a component reference depending on which context we're in."
::=
match cr
case CREF_QUAL(ident = "$PRE") then
   '_discrete_events->pre(<%contextCref(componentRef,context,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>)'
 else
  let &varDeclsCref = buffer "" /*BUFD*/
  match context
  case FUNCTION_CONTEXT(__) then System.unquoteIdentifier(crefStr(cr))
  else '<%cref1(cr,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDeclsCref,stateDerVectorName,useFlatArrayNotation)%>'
end contextCref;

template contextCref2(ComponentRef cr, Context context)
  "Generates code for a component reference depending on which context we're in."
::=
  match context
  case FUNCTION_CONTEXT(__) then crefStr(cr)
  else ""
end contextCref2;

template crefFunctionName(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(__) then
    System.stringReplace(unquoteIdentifier(ident), "_", "__")
  case CREF_QUAL(__) then
    '<%System.stringReplace(unquoteIdentifier(ident), "_", "__")%>_<%crefFunctionName(componentRef)%>'
end crefFunctionName;

template functionInitial(list<SimEqSystem> startValueEquations, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let eqPart = (startValueEquations |> eq as SES_SIMPLE_ASSIGN(__) =>
      equation_(eq, contextSimulationDiscrete, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    ;separator="\n")
  <<
  <%eqPart%>
  >>
end functionInitial;


template equation_(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                   Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case e as SES_SIMPLE_ASSIGN(__)
    then equationSimpleAssign(e, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as SES_ALGORITHM(__)
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

                   string error = add_error_info("Nonlinear solver stopped",ex.what(),ex.getErrorID(),_simTime);
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
                           string error = add_error_info("Nonlinear solver stopped",ex.what(),ex.getErrorID(),_simTime);
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

                   string error = add_error_info("Nonlinear solver stopped",ex.what(),ex.getErrorID(),_simTime);
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
                           string error = add_error_info("Nonlinear solver stopped",ex.what(),ex.getErrorID(),_simTime);
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
    "NOT IMPLEMENTED EQUATION"
end equation_;

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
                                              Text method,Text classnameext, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Boolean createMeasureTime)
::=
  let ix_str = equationIndex(eq)
  let ix_str_array = intSub(stringInt(ix_str),1) //equation index - 1
  let &varDeclsLocal = buffer "" /*BUFD*/
  let &additionalFuncs = buffer "" /*BUFD*/
  let &measureTimeStartVar = buffer "" /*BUFD*/
  let &measureTimeEndVar = buffer "" /*BUFD*/

  let body = match eq
   case e as SES_SIMPLE_ASSIGN(__)
     then
      equationSimpleAssign(e, context, &varDeclsLocal, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
   case e as SES_IFEQUATION(__)
    then "SES_IFEQUATION"
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
      let &additionalFuncs += equation_function_create_single_func(e.cont, context, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, method, classnameext, stateDerVectorName, useFlatArrayNotation, createMeasureTime)
      "throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,\"Mixed systems are not supported yet\");"
    case e as SES_FOR_LOOP(__)
      then
        equationForLoop(e, context, &varDeclsLocal,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    else
      "NOT IMPLEMENTED EQUATION"
  end match
  let &measureTimeStartVar += if createMeasureTime then generateMeasureTimeStartCode("measuredProfileBlockStartValues", 'evaluate<%ix_str%>', "MEASURETIME_PROFILEBLOCKS") else ""
  let &measureTimeEndVar += if createMeasureTime then generateMeasureTimeEndCode("measuredProfileBlockStartValues", "measuredProfileBlockEndValues", 'measureTimeProfileBlocksArray[<%ix_str_array%>]', 'evaluate<%ix_str%>', "MEASURETIME_PROFILEBLOCKS") else ""
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
             'dynamic_cast<SimDouble*>(_sim_data->Get("<%cref(name, useFlatArrayNotation)%>"))->getValue() = <%cref(name, useFlatArrayNotation)%>;';separator="\n"
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
             '<%cref(name, useFlatArrayNotation)%> = dynamic_cast<SimDouble*>(_sim_data->Get("<%cref(name, useFlatArrayNotation)%>"))->getValue();';separator="\n"
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
  let &measureTimeEndVar += if createMeasureTime then generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "measureTimeFunctionsArray[3]", "handleTimeEvents", "MEASURETIME_MODELFUNCTIONS") else ""
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
      _algLoop<%num%> =  boost::shared_ptr<IAlgLoop>(new <%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>(this,__z,__zDot,_conditions,_discrete_events));
      _algLoopSolver<%num%> = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop<%num%>.get()));
      >>
      end match
  case e as SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))
    then
      let num = nls.index
      match simCode
      case SIMCODE(modelInfo = MODELINFO(__)) then
      <<
      _algLoop<%num%> =  boost::shared_ptr<IAlgLoop>(new <%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>(this,__z,__zDot,_conditions,_discrete_events));
      _algLoopSolver<%num%> = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop<%num%>.get()));
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
        boost::shared_ptr<IAlgLoop>  //Algloop  which holds equation system
             _algLoop<%num%>;
        boost::shared_ptr<IAlgLoopSolver>
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
        boost::shared_ptr<IAlgLoop>  //Algloop  which holds equation system
             _algLoop<%num%>;
        boost::shared_ptr<IAlgLoopSolver>
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

  let &funcCalls += 'initializeAlgloopSolverVariables_<%partIdx%>();'
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
  let &funcCalls += 'deleteAlgloopSolverVariables_<%partIdx%>();'
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



// boost::shared_ptr<<%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>>  //Algloop  which holds equation system
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
           _algLoopSolver<%num%>->initialize();
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
  match eq
     case SES_WHEN(left=left, right=right, conditions=conditions, elseWhen=NONE()) then
      let helpIf = (conditions |> e => ' || (<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%> && !_discrete_events->pre(<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>))')

        /*let initial_assign =
        if initialCall then
          whenAssign(left, typeof(right), right, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        else
           '<%cref1(left,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%> = _discrete_events->pre(<%cref1(left,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>);'*/
      let assign = whenAssign(left,typeof(right),right,context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      let pre_call = preCall(left, typeof(right), right, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      <<
      if(_initial)
      {
        <%pre_call%>
      }
      else if (0<%helpIf%>)
      {
        <%assign%>;
      }
      else
      {
            <%pre_call%>
       }
      >>
    case SES_WHEN(left=left, right=right, conditions=conditions, elseWhen=SOME(elseWhenEq)) then
       let helpIf = (conditions |> e => ' || (<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%> && !_discrete_events->pre(<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>))')
      let initial_assign =
        if initialCall then
          whenAssign(left,typeof(right),right,context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        else
         '<%cref1(left,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%> = _discrete_events->pre(<%cref1(left,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>);'
      let assign = whenAssign(left, typeof(right), right, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      let elseWhen = equationElseWhen(elseWhenEq, context, varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)

      <<
      if(_initial)
      {
        <%initial_assign%>
      }
      else if(0<%helpIf%>)
      {
        <%assign%>
      }
      <%elseWhen%>
      else
      {

         <%cref1(left,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%> = _discrete_events->pre(<%cref1(left,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>);
      }
      >>
end equationWhen;


template preCall(ComponentRef left, Type ty, Exp right, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                    Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates assignment for when."
::=
match ty
  case T_ARRAY(dims=dims) then
   let dimensions = checkDimension(dims)
   let i_tmp_var= System.tmpTick()
   let forLoopIteration = preCallForArray(dims,i_tmp_var)
   let forloop = match listLength(dims) case 1 then
   <<
    <%forLoopIteration%>
     <%cref1(left,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>(i0_<%i_tmp_var%>) = _discrete_events->pre(<%cref1(left,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>(i0_<%i_tmp_var%>));
   >>
   case 2 then
   <<
     <%forLoopIteration%>
        <%cref1(left,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>(i0_<%i_tmp_var%>,i1_<%i_tmp_var%>) = _discrete_events->pre(<%cref1(left,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>(i0_<%i_tmp_var%>,i1_<%i_tmp_var%>));
   >>
   else
    error(sourceInfo(), 'No support for this sort of pre call')
   end match
   forloop
   else
   <<
    <%cref1(left,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%> = _discrete_events->pre(<%cref1(left,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>);
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
    <<
    <%preExp%>
    <%cref(left, useFlatArrayNotation)%> = <%exp%>;
    >>
end whenAssign;

template equationElseWhen(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                          Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a else when equation."
::=
let &varDeclsCref = buffer "" /*BUFD*/
match eq
case SES_WHEN(left=left, right=right, conditions=conditions, elseWhen=NONE()) then
  let helpIf =  (conditions |> e => ' || (<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%> && !_discrete_events->pre(<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>))')
  let assign = whenAssign(left, typeof(right), right, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  <<
  else if(0<%helpIf%>)
  {
    <%assign%>
  }
  >>
case SES_WHEN(left=left, right=right, conditions=conditions, elseWhen=SOME(elseWhenEq)) then
  let helpIf = (conditions |> e => ' || (<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%> && !_discrete_events->pre(<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>))')
  let assign = whenAssign(left, typeof(right), right, context, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let elseWhen = equationElseWhen(elseWhenEq, context, varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  <<
  else if(0<%helpIf%>)
  {
    <%assign%>
  }
  <%elseWhen%>
  >>
end equationElseWhen;

template helpvarvector(list<SimWhenClause> whenClauses,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,
                       Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let reinit = (whenClauses |> when hasindex i0 =>
      helpvarvector1(when, contextOther,&varDecls,i0,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    ;separator="";empty)
  <<
  <%reinit%>
  >>
end helpvarvector;

template helpvarvector1(SimWhenClause whenClauses,Context context, Text &varDecls,Integer int,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,
                        Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match whenClauses
case SIM_WHEN_CLAUSE(__) then
  let &preExp = buffer "" /*BUFD*/
  let &helpInits = buffer "" /*BUFD*/
  let &varDeclsCref = buffer "" /*BUFD*/
  let helpIf = (conditions |> e =>
      let helpInit = cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)
      ""
   ;separator="")
<<
<%preExp%>
<%helpIf%>
>>
end helpvarvector1;



template preCref(ComponentRef cr, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName, Boolean useFlatArrayNotation) ::=
let &varDeclsCref = buffer "" /*BUFD*/
'pre<%representationCref(cr, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDeclsCref, stateDerVectorName, useFlatArrayNotation)%>'
end preCref;

template equationSimpleAssign(SimEqSystem eq, Context context,Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates an equation that is just a simple assignment."
::=
match eq
case SES_SIMPLE_ASSIGN(__) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)

  match cref
  case CREF_QUAL(ident = "$PRE")  then
    <<
    <%cref(componentRef, useFlatArrayNotation)%> = <%expPart%>;
    _discrete_events->save( <%cref(componentRef, useFlatArrayNotation)%>);
    >>
  else
   match exp
  case CREF(ty = t as  T_ARRAY(__)) then
  <<
  //Array assign
  <%cref1(cref, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDecls, stateDerVectorName, useFlatArrayNotation)%> = <%expPart%>;
  >>
  else
  <<
  <%preExp%>
  <%cref1(cref, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%> = <%expPart%>;
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
                string error = add_error_info("Nonlinear solver stopped",ex.what(),ex.getErrorID(),_simTime);
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
                string error = add_error_info("Nonlinear solver stopped",ex.what(),ex.getErrorID(),_simTime);
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
                string error = add_error_info("Nonlinear solver stopped",ex.what(),ex.getErrorID(),_simTime);
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

template crefWithIndex(ComponentRef cr, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                       Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Return cref with index for the lhs of a for loop, i.e., _resistori_P_i."
::=
  match cr
    case CREF_QUAL(__) then
      "_" + crefToCStrWithIndex(cr, context, varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName /*=__zDot*/, useFlatArrayNotation)
  end match
end crefWithIndex;

template crefToCStrWithIndex(ComponentRef cr, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                             Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Helper function to crefWithIndex."
::=
  let &preExp = buffer ""
  let tmp = ""
  match cr
    case CREF_QUAL(__) then
      let identTmp = '<%ident%>'
      match listHead(subscriptLst)
        case INDEX(__) then
          match exp case e as CREF(__) then
            let tmp = daeExpCrefRhs(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
            '<%identTmp%><%tmp%><%subscriptsToCStrForArray(subscriptLst)%>_P_<%crefToCStr(componentRef,useFlatArrayNotation)%>'
          end match
      end match
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStrWithIndex;



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


template daeDimensionExp(Exp exp)
 "Generates code for an expression."
::=
  match exp
  case e as ICONST(__)          then '<%integer%>'
  else '-1'
end daeDimensionExp;


template daeExp(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for an expression."
::=
  match exp

  case e as ICONST(__)          then    '<%integer%>' /* Yes, we need to cast int to long on 64-bit arch... */
  case e as RCONST(__)          then    real
  case e as BCONST(__)          then    if bool then "true" else "false"
  case e as ENUM_LITERAL(__)    then    index
  case e as CREF(__)            then    daeExpCrefRhs(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as CAST(__)            then    daeExpCast(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as CONS(__)            then    "Cons not supported yet"
  case e as SCONST(__)          then     daeExpSconst(string, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as UNARY(__)           then     daeExpUnary(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as LBINARY(__)         then     daeExpLbinary(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as LUNARY(__)          then     daeExpLunary(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as BINARY(__)          then     daeExpBinary(operator, exp1, exp2, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as IFEXP(__)           then     daeExpIf(expCond, expThen, expElse, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as RELATION(__)        then     daeExpRelation(e, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as CALL(__)            then     daeExpCall(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as RECORD(__)          then     daeExpRecord(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as ASUB(__)            then     '/*t1*/<%daeExpAsub(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  case e as MATRIX(__)          then     daeExpMatrix(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as RANGE(__)           then     '/*t2*/<%daeExpRange(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  case e as TSUB(__)            then     '/*t3*/<%daeExpTsub(e, context,  &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation )%>'
  case e as REDUCTION(__)       then     daeExpReduction(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as ARRAY(__)           then     '/*t4*/<%daeExpArray(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  case e as SIZE(__)            then     daeExpSize(e, context, &preExp, &varDecls, simCode , &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as SHARED_LITERAL(__)  then     daeExpSharedLiteral(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, useFlatArrayNotation)
  case e as SUM(__)             then     daeExpSum(e, context, &preExp, &varDecls, simCode , &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)

  else error(sourceInfo(), 'Unknown exp:<%printExpStr(exp)%>')
end daeExp;


template daeExpRange(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                     Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a range expression."
::=
  match exp
  case RANGE(__) then
    let ty_str = expTypeArray(ty)
    let start_exp = daeExp(start, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let stop_exp = daeExp(stop, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    //previous multi_array     let tmp = tempDecl('multi_array<<%ty_str%>,1>', &varDecls /*BUFD*/)
    let tmp = tempDecl('DynArrayDim1<<%ty_str%>>', &varDecls /*BUFD*/)
    let step_exp = match step case SOME(stepExp) then daeExp(stepExp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) else "1"
    /* previous multi_array
  let &preExp += 'int num_elems =(<%stop_exp%>-<%start_exp%>)/<%step_exp%>+1;
    <%tmp%>.resize((boost::extents[num_elems]));
    <%tmp%>.reindex(1);
    for(int i= 1;i<=num_elems;i++)
        <%tmp%>[i] =<%start_exp%>+(i-1)*<%step_exp%>;
    '
    '<%tmp%>'
  */
  let &preExp += 'int <%tmp%>_num_elems =(<%stop_exp%>-<%start_exp%>)/<%step_exp%>+1;
    <%tmp%>.setDims(<%tmp%>_num_elems)/*setDims 2*/;
    for (int <%tmp%>_i = 1; <%tmp%>_i <= <%tmp%>_num_elems; <%tmp%>_i++)
      <%tmp%>(<%tmp%>_i) = <%start_exp%>+(<%tmp%>_i-1)*<%step_exp%>;
    '
    '<%tmp%>'
end daeExpRange;


template daeExpReduction(Exp exp, Context context, Text &preExp,
                         Text &varDecls,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a reduction expression. The code is quite messy because it handles all
  special reduction functions (list, listReverse, array) and handles both list and array as input"
::=
  match exp
  case r as REDUCTION(reductionInfo=ri as REDUCTIONINFO(iterType=THREAD()),iterators=iterators)
  case r as REDUCTION(reductionInfo=ri as REDUCTIONINFO(iterType=COMBINE()),iterators=iterators as {_}) then
  (
  let &tmpVarDecls = buffer ""
  let &tmpExpPre = buffer ""
  let &bodyExpPre = buffer ""
  let &rangeExpPre = buffer ""
  let arrayTypeResult = expTypeFromExpArray(r)
  let arrIndex = match ri.path case IDENT(name="array") then tempDecl("int",&tmpVarDecls)
  let foundFirst = if not ri.defaultValue then tempDecl("int",&tmpVarDecls)
  let resType = expTypeArrayIf(typeof(exp))
  let res = contextCref(makeUntypedCrefIdent(ri.resultName), context,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let &tmpVarDecls += '<%resType%> <%res%>;<%\n%>'
  let resTmp = tempDecl(resType,&varDecls)
  let &preDefault = buffer ""
  let resTail = (match ri.path case IDENT(name="list") then tempDecl("modelica_metatype*",&tmpVarDecls))
  let defaultValue = (match ri.path
    case IDENT(name="array") then ""
    else (match ri.defaultValue
          case SOME(v) then daeExp(valueExp(v), context, &preDefault, &tmpVarDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)))
  let reductionBodyExpr = contextCref(makeUntypedCrefIdent(ri.foldName), context,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let bodyExprType = expTypeArrayIf(typeof(r.expr))
  let reductionBodyExprWork = daeExp(r.expr, context, &bodyExpPre, &tmpVarDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let &tmpVarDecls += '<%bodyExprType%> <%reductionBodyExpr%>;<%\n%>'
  let &bodyExpPre += '<%reductionBodyExpr%> = <%reductionBodyExprWork%>;<%\n%>'
  let foldExp = (match ri.path
    case IDENT(name="list") then
    <<
    *<%resTail%> = mmc_mk_cons(<%reductionBodyExpr%>,0);
    <%resTail%> = &MMC_CDR(*<%resTail%>);
    >>
    case IDENT(name="listReverse") then // This is too easy; the damn list is already in the correct order
      '<%res%> = mmc_mk_cons(<%reductionBodyExpr%>,<%res%>);'
    case IDENT(name="array") then
      match typeof(r.expr)
        case T_COMPLEX(complexClassType = record_state) then
          let rec_name = '<%underscorePath(ClassInf.getStateName(record_state))%>'
          '*((<%rec_name%>*)generic_array_element_addr(&<%res%>, sizeof(<%rec_name%>), 1, <%arrIndex%>++)) = <%reductionBodyExpr%>;'
        case T_ARRAY(__) then
          let tmp_shape = tempDecl("vector<size_t>", &varDecls /*BUFD*/)
          let tmp_indeces = tempDecl("idx_type", &varDecls /*BUFD*/)
          /*let idx_str = (dims |> dim =>
            let tmp_idx = tempDecl("vector<size_t>", &varDecls)
            let &preExp += '<%tmp_shape%>.push_back(1);<%\n%>
                       <%tmp_indeces%>.push_back(<%tmp_idx%>);<%\n%>'
                       ''
                       )*/
          let tmp_idx = tempDecl("vector<size_t>", &varDecls /*BUFD*/)
          /*let &preExp += '<%tmp_shape%>.push_back(0);<%\n%>
                        <%tmp_idx%>.push_back(<%arrIndex%>++);<%\n%>
                        <%tmp_indeces%>.push_back(<%tmp_idx%>);<%\n%>'
          let tmp = 'make_pair(<%tmp_shape%>,<%tmp_indeces%>)'
          */

          <<
          <%(dims |> dim =>
            let tmp_idx = tempDecl("vector<size_t>", &varDecls /*BUFD*/)
                       '<%tmp_shape%>.push_back(1);<%\n%>
                       <%tmp_indeces%>.push_back(<%tmp_idx%>);<%\n%>'
            )%>
          <%tmp_shape%>.push_back(0);<%\n%>
          <%tmp_idx%>.push_back(<%arrIndex%>++);<%\n%>
          <%tmp_indeces%>.push_back(<%tmp_idx%>);<%\n%>
          create_array_from_shape(make_pair(<%tmp_shape%>,<%tmp_indeces%>),<%reductionBodyExpr%>,<%res%>);
          >>
        else
          '<%res%>(<%arrIndex%>++) = <%reductionBodyExpr%>;'
    else match ri.foldExp case SOME(fExp) then
      let &foldExpPre = buffer ""
      let fExpStr = daeExp(fExp, context, &bodyExpPre, &tmpVarDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      if not ri.defaultValue then
      <<
      if(<%foundFirst%>)
      {
        <%res%> = <%fExpStr%>;
      }
      else
      {
        <%res%> = <%reductionBodyExpr%>;
        <%foundFirst%> = 1;
      }
      >>
      else '<%res%> = <%fExpStr%>;')
  let endLoop = tempDecl("int",&tmpVarDecls)
  let loopHeadIter = (iterators |> iter as REDUCTIONITER(__) =>
    let identType = expTypeFromExpModelica(iter.exp)
    let ty_str = expTypeArray(ty)
    let arrayType = 'DynArrayDim1<<%ty_str%>>'//expTypeFromExpArray(iter.exp)
    let loopVar = '<%iter.id%>_loopVar'
    let &guardExpPre = buffer ""
    let &tmpVarDecls += '<%arrayType%> <%loopVar%>;/*testloopvar*/<%\n%>'
    let firstIndex = tempDecl("int",&tmpVarDecls)
    let rangeExp = daeExp(iter.exp, context, &rangeExpPre, &tmpVarDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let &rangeExpPre += '<%loopVar%> = <%rangeExp%>/*testloopvar2*/;<%\n%>'
    let &rangeExpPre += if firstIndex then '<%firstIndex%> = 1;<%\n%>'
    let guardCond = (match iter.guardExp case SOME(grd) then daeExp(grd, context, &guardExpPre, &tmpVarDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) else "1")
    let empty = '0 == (<%loopVar%>.getDim(2))'
    let iteratorName = contextIteratorName(iter.id, context)
    let &tmpVarDecls += '<%identType%> <%iteratorName%>;<%\n%>'
    let guardExp =
      <<
      <%&guardExpPre%>
      if(<%guardCond%>) { /* found non-guarded */
        <%endLoop%>--;
        break;
      }
      >>
      let addr = match iter.ty
        case T_ARRAY(ty=T_COMPLEX(complexClassType = record_state)) then
          let rec_name = '<%underscorePath(ClassInf.getStateName(record_state))%>'
          '*((<%rec_name%>*)generic_array_element_addr(&<%loopVar%>, sizeof(<%rec_name%>), 1, <%firstIndex%>++))'
        else
          '<%loopVar%>( <%firstIndex%>++)'
      <<
      while(<%firstIndex%> <=  <%loopVar%>.getDim(1)) {
        <%iteratorName%> = <%addr%>;
        <%guardExp%>
      }
      >>)
  let firstValue = (match ri.path
     case IDENT(name="array") then
       let length = tempDecl("int", &tmpVarDecls)
       let &rangeExpPre += '<%length%> = 0;<%\n%>'
       let _ = (iterators |> iter as REDUCTIONITER(__) =>
         let loopVar = '<%iter.id%>_loopVar'
         let &rangeExpPre += '<%length%> = max(<%length%>, <%loopVar%>.getDim(1));<%\n%>'
         "")
      <<
       <%arrIndex%> = 1;
       <% match typeof(r.expr)
        case T_COMPLEX(complexClassType = record_state) then
          let rec_name = '<%underscorePath(ClassInf.getStateName(record_state))%>'
          'alloc_generic_array(&<%res%>,sizeof(<%rec_name%>),1,<%length%>);'
        case T_ARRAY(__) then
          let dim_vec = tempDecl("std::vector<size_t>",&tmpVarDecls)
          let dimSizes = dims |> dim => match dim
            case DIM_INTEGER(__) then '<%dim_vec%>.push_back(<%integer%>);'
            case DIM_BOOLEAN(__) then '<%dim_vec%>.push_back(2);'
            case DIM_ENUM(__) then '<%dim_vec%>.push_back(<%size%>);'
            else error(sourceInfo(), 'array reduction unable to generate code for element of unknown dimension sizes; type <%unparseType(typeof(r.expr))%>: <%ExpressionDump.printExpStr(r.expr)%>')
            ; separator = ", "
          '<%dimSizes%>
           <%res%>.setDims(<%dim_vec%>);'

        else
          '<%res%>.setDims(<%length%>);'%>
      >>
     else if ri.defaultValue then
     <<
     <%&preDefault%>
     <%res%> = <%defaultValue%>; /* defaultValue */
     >>
     else
     <<
     <%foundFirst%> = 0; /* <%dotPath(ri.path)%> lacks default-value */
     >>)
  let loop =
    <<
    while(1) {
      <%endLoop%> = <%listLength(iterators)%>;
      <%loopHeadIter%>
      if (<%endLoop%> == 0) {
        <%&bodyExpPre%>
        <%foldExp%>
      } <% match iterators case _::_ then
      <<
      else if (<%endLoop%> == <%listLength(iterators)%>) {
        break;
      } else {
        throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Internal error");
      }
      >> %>
    }
    >>
  let &preExp += <<
  {
    <%&tmpVarDecls%>
    <%&rangeExpPre%>
    <%firstValue%>
    <% if resTail then '<%resTail%> = &<%res%>;' %>
    <%loop%>
    <% if not ri.defaultValue then 'if (!<%foundFirst%>) MMC_THROW_INTERNAL();' %>
    <% if resTail then '*<%resTail%> = mmc_mk_nil();' %>
    <% resTmp %> = <% res %>;
  }<%\n%>
  >>
  resTmp)
  else error(sourceInfo(), 'Code generation does not support multiple iterators: <%printExpStr(exp)%>')
end daeExpReduction;


template daeExpSize(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                    Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a size expression."
::=
  match exp
  case SIZE(exp=CREF(__), sz=SOME(dim)) then
    let expPart = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let dimPart = daeExp(dim, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '<%expPart%>.getDim(<%dimPart%>)'
  case SIZE(exp=CREF(__)) then
    let expPart = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let tmp = tempDecl("vector<size_t>", &varDecls)
    let &preExp +=
      <<
      <%tmp%> = <%expPart%>.getDims();
      DynArrayDim1<int> <%tmp%>_size(<%tmp%>.size());
      for (size_t <%tmp%>_i = 1; <%tmp%>_i <= <%tmp%>.size(); <%tmp%>_i++)
        <%tmp%>_size(<%tmp%>_i) = (int)<%tmp%>[<%tmp%>_i-1];<%\n%>
      >>
    '<%tmp%>_size'
  else "size(X) not implemented"
end daeExpSize;


template daeExpMatrix(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs,
                      Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a matrix expression."
::=
  match exp
  case MATRIX(matrix={{}})  // special case for empty matrix: create dimensional array Real[0,1]
  case MATRIX(matrix={})    // special case for empty array: create dimensional array Real[0,1]
    then
    let typestr = expTypeArray(ty)
    let arrayTypeStr = 'DynArrayDim2<<%typestr%>>'
    let tmp = tempDecl(arrayTypeStr, &varDecls /*BUFD*/)
   // let &preExp += 'alloc_<%arrayTypeStr%>(&<%tmp%>, test2, 0, 1);<%\n%>'
    tmp
   case m as MATRIX(matrix=(row1::_)) then
     let arrayTypeStr = expTypeArray(ty)
       let StatArrayDim = expTypeArrayforDim(ty)
       let &tmp = buffer "" /*BUFD*/
     let arrayVar = tempDecl(arrayTypeStr, &tmp /*BUFD*/)
     let &vals = buffer "" /*BUFD*/
       let dim_cols = listLength(row1)

/*
/////////////////////////////////////////////////NonCED
    let params = (m.matrix |> row =>
        let vars = daeExpMatrixRow(row, context, &varDecls,&preExp,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,useFlatArrayNotation)
        '<%vars%>'
      ;separator=",")
  let &preExp += '
    <%StatArrayDim%><%arrayVar%>;
    <%arrayTypeStr%> <%arrayVar%>_data[]={<%params%>};
    <%arrayVar%>.assign( <%arrayVar%>_data );<%\n%>'
   arrayVar
/////////////////////////////////////////////////NonCED
*/

///////////////////////////////////////////////CED
 let matrixassign = match m.matrix
    case row::_ then
        let vars = daeExpMatrixRow(m.matrix,context,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName)
        match vars
        case "NO_ASSIGN"
        then
           let params = (m.matrix |> row =>
           let vars = daeExpMatrixRow2(row, context, &varDecls, &preExp, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
              '<%vars%>'
           ;separator=",")
           let &preExp +=
             <<
             //default matrix assign
             <%StatArrayDim%> <%arrayVar%>;
             <%arrayTypeStr%> <%arrayVar%>_data[] = {<%params%>};
             assignRowMajorData(<%arrayVar%>_data, <%arrayVar%>);<%\n%>
             >>
           ''
        else
           let &preExp +=
             <<
             //optimized matrix assign
             <%StatArrayDim%> <%arrayVar%>;
             <%arrayVar%>.assign( <%vars%> );<%\n%>
             >>
        ''
  end match


  //let &preExp += '
 //  <%StatArrayDim%><%arrayVar%>;
 //   <%arrayVar%>.assign( <%matrixassign%> );<%\n%>'


     arrayVar
end daeExpMatrix;


template daeExpMatrixRow2(list<Exp> row, Context context, Text &varDecls, Text &preExp, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                          Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Helper to daeExpMatrix."
::=
   let varLstStr = (row |> e =>
      let expVar = daeExp(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      '<%expVar%>'
    ;separator=",")
  varLstStr
end daeExpMatrixRow2;
/////////////////////////////////////////////////CED

/*
/////////////////////////////////////////////////NonCED functions
template daeExpMatrixRow(list<Exp> row,
                         Context context,
                         Text &varDecls ,Text &preExp ,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Boolean useFlatArrayNotation)
 "Helper to daeExpMatrix."
::=

   let varLstStr = (row |> e =>

      let expVar = daeExp(e, context, &preExp , &varDecls ,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,useFlatArrayNotation)
      '<%expVar%>'
    ;separator=",")
  varLstStr
end daeExpMatrixRow;
/////////////////////////////////////////////////NonCED functions
*/

////////////////////////////////////////////////////////////////////////CED Functions
template daeExpMatrixRow(list<list<Exp>> matrix,Context context,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Text stateDerVectorName /*=__zDot*/)
 "Helper to daeExpMatrix."
::=
if isCrefListWithEqualIdents(List.flatten(matrix)) then
  match matrix
  case row::_ then
      daeExpMatrixName(row,context,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName)
  else
   "NO_ASSIGN"
   end match
  else
   "NO_ASSIGN"
end daeExpMatrixRow;

template daeExpMatrixName(list<Exp> row,Context context,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl, Text stateDerVectorName /*=__zDot*/, Text extraFuncsNamespace)
::=
  let &varDecls = buffer "" /*BUFD*/
  let &preExp = buffer "" /*BUFD*/
  match row
   case CREF(componentRef = cr)::_ then
      contextCref(crefStripLastSubs(cr),context,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, false)
   /*
   match context
   case FUNCTION_CONTEXT(__) then
    cref2(cr,false) //daeExpMatrixName2(cr) //assign array complete to the function therefore false as second argument
   else
   "_"+cref2(cr,false)//daeExpMatrixName2(cr) //assign array complete to function therefore false as second argument
  else
  "NO_ASSIGN"
  */
end daeExpMatrixName;


template daeExpMatrixName2(ComponentRef cr)
::=

  match cr
  case CREF_IDENT(__) then
    '<%ident%>'
 case CREF_QUAL(__) then               '<%ident%><%subscriptsToCStrForArray(subscriptLst)%>_P_<%daeExpMatrixName2(componentRef)%>'

  case WILD(__) then ' '
  else "CREF_NOT_IDENT_OR_QUAL"
end daeExpMatrixName2;
////////////////////////////////////////////////////////////////////////CED Functions


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
template daeExpArray(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                     Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for an array expression."
::=
match exp
case ARRAY(array=_::_, ty = arraytype) then
  let arrayTypeStr = expTypeArray(ty)
  let ArrayType = expTypeArrayforDim(ty)
  let &tmpVar = buffer ""
  let arrayVar = tempDecl(arrayTypeStr, &tmpVar /*BUFD*/)
  let arrayassign =  if scalar then
                     let params =    daeExpArray2(array,arrayVar,ArrayType,arrayTypeStr,context,preExp,varDecls,simCode, &extraFuncs,&extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
                          ""
                      else
                              let funcCalls = daeExpSubArray(array, arrayVar, ArrayType, context, preExp, varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
                              let &extraFuncsDecl += 'void createArray_<%arrayVar%>(<%ArrayType%>& <%arrayVar%>);<%\n%>'
                              let &extraFuncs +=
                               <<
                               void <%extraFuncsNamespace%>::createArray_<%arrayVar%>(<%ArrayType%>& <%arrayVar%>)
                               {
                                 <%arrayVar%>.setDims(<%allocateDimensions(arraytype,context)%>);
                                 <%funcCalls%>
                               }<%\n%>
                               >>
                               <<
                               <%ArrayType%> <%arrayVar%>;
                               createArray_<%arrayVar%>(<%arrayVar%>);<%\n%>
                               >>

  let &preExp += '<%arrayassign%>'
  arrayVar
case ARRAY(__) then
  let arrayTypeStr = expTypeArray(ty)
  let arrayDef = expTypeArrayforDim(ty)
  let &tmpdecl = buffer ""
  let arrayVar = tempDecl(arrayTypeStr, &tmpdecl )
  let &tmpVar = buffer ""
   let &preExp += '
   //tmp array
   <%arrayDef%><%arrayVar%>;<%\n%>'
  arrayVar
end daeExpArray;





template daeExpSubArray(list<Exp> array, String arrayVar, String ArrayType, Context context, Text &preExp, Text &varDecls, SimCode simCode,
                        Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for an array expression."
::=
(List.partition(array,50) |> subarray hasindex i0 fromindex 0 =>
   daeExpSubArray2(subarray,i0,50,arrayVar,ArrayType,context,preExp,varDecls,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
   ;separator ="\n")
end daeExpSubArray;



template daeExpArray2(list<Exp> array,String arrayVar,String ArrayType,String arrayTypeStr, Context context, Text &preExp,
                     Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for an array expression."
::=
let params = (array |> e =>  '<%daeExp(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
let &preExp +=
  <<
  <%arrayTypeStr%> <%arrayVar%>_data[]={<%params%>};
  <%ArrayType%> <%arrayVar%>(<%arrayVar%>_data);<%\n%>
  >>

params
end daeExpArray2;


template daeExpSubArray2(list<Exp> array, Integer idx, Integer multiplicator, String arrayVar, String ArrayType, Context context, Text &preExp,
                     Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for an array expression."
::=
let func = 'void createArray_<%arrayVar%>_<%idx%>(<%ArrayType%>& <%arrayVar%>);'
let &extraFuncsDecl += '<%func%><%\n%>'
let funcCall = 'createArray_<%arrayVar%>_<%idx%>(<%arrayVar%>);'
let &funcVarDecls = buffer ""
let &preExpSubArrays = buffer ""
let funcs = (array |> e hasindex i0 fromindex intAdd(intMul(idx, multiplicator),1) =>
       let subArraycall = daeExp(e, context, &preExpSubArrays, &funcVarDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
       <<
       <%arrayVar%>.append(<%i0%>, <%subArraycall%>);
       >> ;separator="\n")
       let &extraFuncs +=
       <<
       void <%extraFuncsNamespace%>::createArray_<%arrayVar%>_<%idx%>(<%ArrayType%>& <%arrayVar%>)
       {
         <%funcVarDecls%>
         <%preExpSubArrays%>
         <%funcs%>
       }<%\n%>
       >>
funcCall
end daeExpSubArray2;






template daeExpAsub(Exp inExp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                    Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for an asub expression."
::=
  match expTypeFromExpShort(inExp)
  case "metatype" then
  // MetaModelica Array
    (match inExp case ASUB(exp=e, sub={idx}) then
      let e1 = daeExp(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      let idx1 = daeExp(idx, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      'arrayGet(<%e1%>,<%idx1%>) /* DAE.ASUB */')
  // Modelica Array
  else
  match inExp

  case ASUB(exp=ASUB(__)) then
    error(sourceInfo(),'Nested array subscripting *should* have been handled by the routine creating the asub, but for some reason it was not: <%printExpStr(exp)%>')

  // Faster asub: Do not construct a whole new array just to access one subscript
  case ASUB(exp=exp as ARRAY(scalar=true), sub={idx}) then
    let res = tempDecl(expTypeFromExpModelica(exp),&varDecls)
    let idx1 = daeExp(idx, context, &preExp, &varDecls,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let expl = (exp.array |> e hasindex i1 fromindex 1 =>
      let &caseVarDecls = buffer ""
      let &casePreExp = buffer ""
      let v =daeExp(e, context, &casePreExp, &caseVarDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      <<
      case <%i1%>: {
        <%&caseVarDecls%>
        <%&casePreExp%>
        <%res%> = <%v%>;
        break;
      }
      >> ; separator = "\n")
    let &preExp +=
    <<
    switch (<%idx1%>) { /* ASUB */
    <%expl%>
    default:
      assert(NULL == "index out of bounds");
    }
    >>
   '<%res%>'

  case ASUB(exp=RANGE(ty=t), sub={idx}) then
    error(sourceInfo(),'ASUB_EASY_CASE <%printExpStr(exp)%>')

 case ASUB(exp=ecr as CREF(__), sub=subs) then
    let arrName =  daeExpCrefRhs(buildCrefExpFromAsub(ecr, subs), context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    match context case FUNCTION_CONTEXT(__)  then
      arrName
    else
      '<%arrayScalarRhs(ecr.ty, subs, arrName, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  case ASUB(exp=e, sub=indexes) then
  let exp = daeExp(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  // let typeShort = expTypeFromExpShort(e)
  let expIndexes = (indexes |> index => '<%daeExpASubIndex(index, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=",")
   //'<%typeShort%>_get<%match listLength(indexes) case 1 then "" case i then '_<%i%>D'%>(&<%exp%>, <%expIndexes%>)'
  '(<%exp%>)(<%expIndexes%>)'
  case exp then
    error(sourceInfo(),'OTHER_ASUB <%printExpStr(exp)%>')
end daeExpAsub;



template daeExpASubIndex(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                         Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match exp
  case ICONST(__) then integer
  case ENUM_LITERAL(__) then index
  else daeExp(exp, context, &preExp, &varDecls, simCode ,&extraFuncs ,&extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
end daeExpASubIndex;


template arrayScalarRhs(Type ty, list<Exp> subs, String arrName, Context context,
               Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Helper to daeExpAsub."
::=
  /* match exp
   case ASUB(exp=ecr as CREF(__)) then*/
  let arrayType = expTypeArray(ty)
  let dimsLenStr = listLength(subs)
  let dimsValuesStr = (subs |> exp =>
      daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator=",")
    //previous multi_array ;separator="][")


  match arrayType
    case "metatype_array" then
      'arrayGet(<%arrName%>,<%dimsValuesStr%>) /*arrayScalarRhs*/'
    else
      //ToDo before used <%arrayCrefCStr(ecr.componentRef)%>[<%dimsValuesStr%>]
      << <%arrName%>(<%dimsValuesStr%>) >>
end arrayScalarRhs;

template daeExpCast(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a cast expression."
::=
match exp
case CAST(__) then
  let expVar = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match ty
  case T_INTEGER(__)   then '((int)<%expVar%>)'
  case T_REAL(__)  then '((double)<%expVar%>)'
  case T_ENUMERATION(__)   then '((modelica_integer)<%expVar%>)'
  case T_BOOL(__)   then '((bool)<%expVar%>)'
  case T_ARRAY(__) then
    let arrayTypeStr = expTypeArrayforDim(ty)
    let tvar = tempDecl(arrayTypeStr, &varDecls /*BUFD*/)
    let to = expTypeShort(ty)
    let from = expTypeFromExpShort(exp)
    let &preExp += 'cast_<%from%>_array_to_<%to%>(&<%expVar%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'

  //'(*((<%underscorePath(rec.path)%>*)&<%expVar%>))'
  case T_COMPLEX(varLst=vl,complexClassType=rec as RECORD(__))   then

      let tvar = tempDecl(underscorePath(rec.path)+"Type", &varDecls /*BUFD*/)
      let &preExp += '<%structParams(expVar,tvar,vl)%><%\n%>'
     '<%tvar%>'
   else
    '(<%expVar%>) /* could not cast, using the variable as it is */'
end daeExpCast;


template structParams(String structName,String varName,list<Var>  exps)
::=
   let  params = (exps |> e => match e
    case TYPES_VAR(__) then
    '<%varName%>.<%name%>=<%structName%>.<%name%>;'
    ;separator="\n" )
  params
end structParams;

template daeExpRecord(Exp rec, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                      Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match rec
  case RECORD(__) then
  let name = tempDecl(underscorePath(path) + "Type", &varDecls)
  let ass = threadTuple(exps,comp) |>  (exp,compn) => '<%name%>.<%compn%> = <%daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>;<%\n%>'
  let &preExp += ass
  name
end daeExpRecord;

template daeExpCall(Exp call, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,
                    Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a function call."
::=
  //<%name%>
  match call
  // special builtins

  case CALL(path=IDENT(name="edge"),
            expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '_discrete_events.edge(<%var1%>)'

  case CALL(path=IDENT(name="pre"),
            expLst={arg as CREF(__)}) then
    let var1 = daeExp(arg, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '_discrete_events->pre(<%var1%>)'

  case CALL(path=IDENT(name="sample"), expLst={ICONST(integer=index), start, interval}) then
    let &preExp = buffer "" /*BUFD*/
    let eStart = daeExp(start, contextOther, &preExp, &varDecls, simCode, &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let eInterval = daeExp(interval, contextOther, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    match context
     case  ALGLOOP_CONTEXT(genInitialisation=false) then
     '_system->_time_conditions[<%intSub(index, 1)%>]'
     else
     '_time_conditions[<%intSub(index, 1)%>]'
  case CALL(path=IDENT(name="initial") ) then
     match context

    case ALGLOOP_CONTEXT(genInitialisation = false)

        then  '_system->_initial'
    else
          '_initial'
  case CALL(path=IDENT(name="terminal") ) then
     match context

    case ALGLOOP_CONTEXT(genInitialisation = false)

        then  '_system->_terminal'
    else
          '_terminal'

   case CALL(path=IDENT(name="DIVISION"),
            expLst={e1, e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var3 = Util.escapeModelicaStringToCString(printExpStr(e2))
    'division(<%var1%>,<%var2%>,"<%var3%>")'

   case CALL(path=IDENT(name="sign"),
            expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     'sgn(<%var1%>)'

   case CALL(attr=CALL_ATTR(ty=ty as T_ARRAY(dims=dims)),
            path=IDENT(name="DIVISION_ARRAY_SCALAR"),
            expLst={e1, e2}) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "int"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "int"
                        else "double"

    let var = tempDecl('multi_array<<%type%>,<%listLength(dims)%>>', &varDecls /*BUFD*/)
    let var1 = daeExp(e1, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var3 = Util.escapeModelicaStringToCString(printExpStr(e2))
    let &preExp += 'assign_array(<%var%>,divide_array<<%type%>,<%listLength(dims)%>>(<%var1%>, <%var2%>));<%\n%>'
    //let &preExp += 'division_alloc_<%type%>_scalar(&<%var1%>, <%var2%>, &<%var%>, "<%var3%>");<%\n%>'
    '<%var%>'


  case CALL(path=IDENT(name="der"), expLst={arg as CREF(__)}) then
    representationCrefDerVar(arg.componentRef, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, stateDerVectorName)
  case CALL(path=IDENT(name="pre"), expLst={arg as CREF(__)}) then
    let retType = '<%expTypeArrayIf(arg.ty)%>'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let cast = match arg.ty case T_INTEGER(__) then "(int)"
                            case T_ENUMERATION(__) then "(int)" //else ""
    let &preExp += '<%retVar%> = <%cast%>pre(<%cref(arg.componentRef, useFlatArrayNotation)%>);<%\n%>'
    '<%retVar%>'

  case CALL(path=IDENT(name="print"), expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    if acceptMetaModelicaGrammar() then 'print(<%var1%>)' else 'puts(<%var1%>)'


  case CALL(path=IDENT(name="integer"), expLst={inExp,index}) then
    let exp = daeExp(inExp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
   // let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,useFlatArrayNotation)
    'boost::numeric_cast<int>(<%exp%>)'


  case CALL(path=IDENT(name="floor"), expLst={inExp,index}, attr=CALL_ATTR(ty = ty)) then
    let exp = daeExp(inExp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    //let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'std::floor(<%exp%>)'
 case CALL(path=IDENT(name="floor"), expLst={inExp}, attr=CALL_ATTR(ty = ty)) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    //let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'std::floor(<%exp%>)'
  case CALL(path=IDENT(name="ceil"), expLst={inExp,index}, attr=CALL_ATTR(ty = ty)) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    //let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'std::ceil(<%exp%>)'
  case CALL(path=IDENT(name="ceil"), expLst={inExp}, attr=CALL_ATTR(ty = ty)) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl , extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    //let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'std::ceil(<%exp%>)'

  case CALL(path=IDENT(name="integer"), expLst={inExp}) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
   'boost::numeric_cast<int>(<%exp%>)'

   case CALL(path=IDENT(name="modelica_mod_int"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '<%var1%>%<%var2%>)'

  case CALL(path=IDENT(name="max"), attr=CALL_ATTR(ty = T_REAL(__)), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'max(<%var1%>,<%var2%>)'

  case CALL(path=IDENT(name="max"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'max(<%var1%>,<%var2%>)'

  case CALL(attr=CALL_ATTR(ty = T_REAL(__)),
            path=IDENT(name="min"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'min(<%var1%>,<%var2%>)'

  case CALL(path=IDENT(name="min"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'min(<%var1%>,<%var2%>)'

  case CALL(path=IDENT(name="abs"), expLst={e1}, attr=CALL_ATTR(ty = T_INTEGER(__))) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'labs(<%var1%>)'

  case CALL(path=IDENT(name="abs"), expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'std::abs(<%var1%>)'

  case CALL(path=IDENT(name="sqrt"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let typeStr = expTypeShort(attr.ty )
    let retVar = tempDecl(typeStr, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = sqrt(<%argStr%>);<%\n%>'
    '<%retVar%>'

  case CALL(path=IDENT(name="sin"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

   case CALL(path=IDENT(name="sinh"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'
   case CALL(path=IDENT(name="asin"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'
   case CALL(path=IDENT(name="cos"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'
 case CALL(path=IDENT(name="cosh"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'
   case CALL(path=IDENT(name="log"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

   case CALL(path=IDENT(name="log10"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'



   case CALL(path=IDENT(name="acos"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

   case CALL(path=IDENT(name="tan"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

    case CALL(path=IDENT(name="tanh"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

   case CALL(path=IDENT(name="atan"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

   case CALL(path=IDENT(name="atan2"),
            expLst={e1,e2},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")

    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = std::atan2(<%argStr%>);<%\n%>'
    '<%retVar%>'
    case CALL(path=IDENT(name="smooth"),
            expLst={e1,e2},attr=attr as CALL_ATTR(__)) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '<%var2%>'
    case CALL(path=IDENT(name="homotopy"),
            expLst={e1,e2},attr=attr as CALL_ATTR(__)) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '<%var1%>'
     case CALL(path=IDENT(name="homotopyParameter"),
            expLst={},attr=attr as CALL_ATTR(__)) then
     '1.0'

   case CALL(path=IDENT(name="exp"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

  case CALL(path=IDENT(name="div"), expLst={e1,e2}, attr=CALL_ATTR(ty = T_INTEGER(__))) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'ldiv(<%var1%>,<%var2%>).quot'

  case CALL(path=IDENT(name="div"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'boost::math::trunc(<%var1%>/<%var2%>)'

  case CALL(path=IDENT(name="mod"), expLst={e1,e2}, attr=attr as CALL_ATTR(__)) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'modelica_mod_<%expTypeShort(attr.ty)%>(<%var1%>,<%var2%>)'

   case CALL(path=IDENT(name="semiLinear"), expLst={e1,e2,e3}, attr=attr as CALL_ATTR(__)) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var3 = daeExp(e3, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'semiLinear(<%var1%>,<%var2%>,<%var3%>)'

  case CALL(path=IDENT(name="max"), attr=CALL_ATTR(ty = ty), expLst={array}) then
    //let &tmpVar = buffer "" /*BUFD*/
    let expVar = daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let arr_tp_str = expTypeShort(ty)
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = min_max<<%arr_tp_str%>>(<%expVar%>).second;<%\n%>'
    '<%tvar%>'
  case CALL(path=IDENT(name="sum"), attr=CALL_ATTR(ty = ty), expLst={array}) then
    //let &tmpVar = buffer "" /*BUFD*/
    let expVar = daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let arr_tp_str = expTypeShort(ty)
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = sum_array<<%arr_tp_str%>>(<%expVar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="min"), attr=CALL_ATTR(ty = ty), expLst={array}) then
    //let &tmpVar = buffer "" /*BUFD*/
    let expVar = daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let arr_tp_str = expTypeShort(ty)
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = min_max<<%arr_tp_str%>>(<%expVar%>).first;<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="fill"), expLst=val::dims, attr=attr as CALL_ATTR(__)) then
    let valExp = daeExp(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let dimsExp = (dims |> dim =>    daeExp(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator="][")

    let ty_str = '<%expTypeShort(attr.ty)%>'
  //previous multi_array
  // let tmp_type_str =  'multi_array<<%ty_str%>,<%listLength(dims)%>>'
    let tmp_type_str =  'DynArrayDim<%listLength(dims)%><<%ty_str%>>'

    let tvar = tempDecl(tmp_type_str, &varDecls /*BUFD*/)

    let &preExp += '<%tvar%>.setDims(<%dimsExp%>);<%\n%>'

    let &preExp += 'fill_array<<%ty_str%>>(<%tvar%>, <%valExp%>);<%\n%>'
    '<%tvar%>'
  case CALL(path=IDENT(name="$_start"), expLst={arg}) then
    daeExpCallStart(arg, context, preExp, varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)


  case CALL(path=IDENT(name="cat"), expLst=dim::a0::arrays, attr=attr as CALL_ATTR(__)) then
    let dim_exp = daeExp(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let& dimstr = buffer ""
    let tmp_type_str = match typeof(a0)
      case ty as T_ARRAY(dims=dims) then
        let &dimstr += listLength(dims)
        'DynArrayDim<%listLength(dims)%><<%expTypeShort(ty)%>>'
        else
        let &dimstr += 'error array dims'
        'array error'
    let ty_str = '<%expTypeArray(attr.ty)%>'
    let tvar = tempDecl(tmp_type_str, &varDecls /*BUFD*/)
    let a0str = daeExp(a0, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let arrays_exp = (arrays |> array =>
    '<%tvar%>_list.push_back(&<%daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>);' ;separator="\n")
    let &preExp +=
    'vector<const BaseArray<<%ty_str%>>*> <%tvar%>_list;
     <%tvar%>_list.push_back(&<%a0str%>);
     <%arrays_exp%>
     cat_array<<%ty_str%>>(<%dim_exp%>, <%tvar%>_list, <%tvar%>);
    '
    '<%tvar%>'

  case CALL(path=IDENT(name="promote"), expLst={A, n}, attr=attr as CALL_ATTR(ty=ty)) then
  //match A
    //case component as CREF(componentRef=cr, ty=ty) then
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(n, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    //let temp = tempDeclAssign('const size_t*', &varDecls /*BUFD*/,'<%var1%>.shape()')
    //let temp_ex = tempDecl('std::vector<size_t>', &varDecls /*BUFD*/)
    let arrayType = /*expTypeArray(ty)*/expTypeFlag(ty,6)
    //let dimstr = listLength(crefSubs(cr))
    let tmp = tempDecl('<%arrayType%>', &varDecls /*BUFD*/)

   // let arr_tp_str = '<%expTypeFromExpArray(A)%>'
    //let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'promote_array(<%var2%>,<%var1%>, <%tmp%>);<%\n%>'


    '<%tmp%> '
   //else
   //'promote array error'
  case CALL(path=IDENT(name="transpose"), expLst={A}) then
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let type_str = expTypeFromExpShort(A)
    let arr_tp_str = '<%expTypeFromExpArray(A)%>'
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'transpose_array<<%type_str%>>(<%var1%>, <%tvar%>);<%\n%>'
    '<%tvar%>'

   case CALL(path=IDENT(name="cross"), expLst={v1, v2},attr=CALL_ATTR(ty=ty as T_ARRAY(dims=dims))) then
    let var1 = daeExp(v1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(v2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then 'int'
                        case T_ARRAY(ty=T_ENUMERATION(__)) then 'int'
                        else 'double'
    let tvar = tempDecl('multi_array<<%type%>,<%listLength(dims)%>>', &varDecls /*BUFD*/)
    let &preExp += 'assign_array(<%tvar%>,cross_array<<%type%>>(<%var1%>,<%var2%>));<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="identity"), expLst={A}) then
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let arr_tp_str = '<%expTypeFromExpArray(A)%>'
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'identity_alloc_<%arr_tp_str%>(<%var1%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'

   case CALL(path=IDENT(name="rem"),
             expLst={e1, e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let typeStr = expTypeFromExpShort(e1)
    'modelica_rem_<%typeStr%>(<%var1%>,<%var2%>)'


   case CALL(path=IDENT(name="String"),
             expLst={s, format}) then
    let emptybuf = ""
  let tvar = tempDecl("string", &varDecls /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let formatExp = daeExp(format, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let typeStr = expTypeFromExpModelica(s)
    let &preExp += 'string <%tvar%> = lexical_cast<std::string>(<%sExp%>);<%\n%>'
    '<%tvar%>'

   case CALL(path=IDENT(name="String"),
             expLst={s, minlen, leftjust}) then
    let emptybuf = ""
    let tvar = tempDecl("string", &emptybuf /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let minlenExp = daeExp(minlen, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let leftjustExp = daeExp(leftjust, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let typeStr = expTypeFromExpModelica(s)
    let &preExp += 'string <%tvar%> = lexical_cast<string>(<%sExp%>);<%\n%>'
    '<%tvar%>'


  //hierhier todo
  case CALL(path=IDENT(name="String"),
            expLst={s, minlen, leftjust, signdig}) then
  let emptybuf = ""
    let tvar = tempDecl("string", &emptybuf /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let minlenExp = daeExp(minlen, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let leftjustExp = daeExp(leftjust, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let signdigExp = daeExp(signdig, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let &preExp +=  'string <%tvar%> = lexical_cast<string>(<%sExp%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="delay"),
            expLst={ICONST(integer=index), e, d, delayMax}) then
    let tvar = tempDecl("double", &varDecls /*BUFD*/)
    let var1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(d, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var3 = daeExp(delayMax, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let &preExp += '<%tvar%> = delay(<%index%>, <%var1%>,  <%var2%>, <%var3%>);<%\n%>'
    '<%tvar%>'


  case CALL(path=IDENT(name="integer"),
            expLst={toBeCasted}) then
    let castedVar = daeExp(toBeCasted, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '((int)<%castedVar%>)'

   case CALL(path=IDENT(name="Integer"),
             expLst={toBeCasted}) then
    let castedVar = daeExp(toBeCasted, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '((int)<%castedVar%>)'

  case CALL(path=IDENT(name="clock"), expLst={}) then
    'mmc_clock()'

  case CALL(path=IDENT(name="noEvent"),
            expLst={e1}) then
    daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)

  case CALL(path=IDENT(name="anyString"),
            expLst={e1}) then
    'mmc_anyString(<%daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>)'

  case CALL(path=IDENT(name="mmc_get_field"),
            expLst={s1, ICONST(integer=i)}) then
    let tvar = tempDecl("modelica_metatype", &varDecls /*BUFD*/)
    let expPart = daeExp(s1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let &preExp += '<%tvar%> = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%expPart%>), <%i%>));<%\n%>'
    '<%tvar%>'

  case exp as CALL(attr=attr as CALL_ATTR(ty=T_NORETCALL(__))) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let &preExp += match context
                        case FUNCTION_CONTEXT(__) then '<%funName%>(<%argStr%>);<%\n%>'
            /*multi_array else 'assign_array(<%retVar%> ,_functions.<%funName%>(<%argStr%>));<%\n%>'*/
                        else '_functions-><%funName%>(<%argStr%>);<%\n%>'
    ""
    /*Function calls with array return type*/
    case exp as CALL(attr=attr as CALL_ATTR(ty=T_ARRAY(ty=ty,dims=dims))) then

    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=",")
    let funName = '<%underscorePath(path)%>'
    let retType = '<%funName%>RetType /* undefined */'
    let retVar = tempDecl(retType, &varDecls)
    let &preExp += match context
                        case FUNCTION_CONTEXT(__) then '(<%funName%>(<%argStr%><%if expLst then if retVar then "," %><%retVar%>));<%\n%>/*funccall*/'
            /*multi_array else 'assign_array(<%retVar%> ,_functions.<%funName%>(<%argStr%>));<%\n%>'*/
                        else '_functions-><%funName%>(<%argStr%><%if expLst then if retVar then "," %><%retVar%>);<%\n%>'



    '<%retVar%>'
   /*Function calls with tuple return type
   case exp as CALL(attr=attr as CALL_ATTR(ty=T_TUPLE(__))) then
     then  "Tuple not supported yet"
   */
    /*Function calls with default type*/
    case exp as CALL(expLst = explist,attr=attr as CALL_ATTR(ty =ty)) then

    let funName = '<%underscorePath(path)%>'
    /*workaround until we support this*/
    match funName
    case "Modelica_Utilities_Files_loadResource"
    then
    '"noName"'
    else
    /*end workaround*/
    let argStr = (explist |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let retType = '<%funName%>RetType /* undefined */'
    let retVar = tempDecl(retType, &varDecls)
    let &preExp += match context case FUNCTION_CONTEXT(__) then'<%funName%>(<%argStr%><%if explist then if retVar then "," %><%if retVar then '<%retVar%>'%>);<%\n%>'
    else '_functions-><%funName%>(<%argStr%><%if explist then if retVar then "," %> <%if retVar then '<%retVar%>'%>);<%\n%>'
     '<%retVar%>'

end daeExpCall;

template daeExpCallStart(Exp exp, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  "Generates code for an asub of a cref, which becomes cref + offset."
::=
  let &varDeclsCref = buffer "" /*BUFD*/
  match exp
  case cr as CREF(__) then
  match context
    case  ALGLOOP_CONTEXT(genInitialisation=false) then
    '_system->get<%crefStartValueType(cr.componentRef)%>StartValue(<%cref1(cr.componentRef, simCode , extraFuncs, extraFuncsDecl, extraFuncsNamespace,  context,  &varDecls,  stateDerVectorName ,  useFlatArrayNotation)%>)'
    else
    'get<%crefStartValueType(cr.componentRef)%>StartValue(<%cref1(cr.componentRef, simCode , extraFuncs, extraFuncsDecl, extraFuncsNamespace,  context,  &varDecls,  stateDerVectorName ,  useFlatArrayNotation)%>)'
  case ASUB(exp = cr as CREF(__), sub = {sub_exp}) then
    let offset = daeExp(sub_exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let cref = cref1(cr.componentRef,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDeclsCref,stateDerVectorName,useFlatArrayNotation)
    '*(&$P$ATTRIBUTE<%cref(cr.componentRef, useFlatArrayNotation)%>.start + <%offset%>)'
  else
    error(sourceInfo(), 'Code generation does not support start(<%printExpStr(exp)%>)')
end daeExpCallStart;


template crefStartValueType(ComponentRef cr) "template crefType
  Like cref but with cast if type is integer."
::=
  match cr
  case CREF_IDENT(__) then '<%crefStartValueType2(identType)%>'
  case CREF_QUAL(__)  then '<%crefStartValueType(componentRef)%>'
  else "crefType:ERROR"
  end match
end crefStartValueType;





template crefStartValueType2(DAE.Type ty)
::=
  match ty
    case T_INTEGER(__) then 'Int'
    case T_REAL(__) then 'Real'
    case T_BOOL(__) then 'Bool'
    case T_ENUMERATION(__) then 'Int'
    case T_ARRAY(ty=T_INTEGER(__)) then 'Int'
    case T_ARRAY(ty=T_REAL(__)) then 'Real'
    case T_ARRAY(ty=T_BOOL(__)) then 'Bool'
  else "error start value type"
end match


end crefStartValueType2;






template expTypeFromExpShort(Exp exp)

::=
  expTypeFromExpFlag(exp, 1)
end expTypeFromExpShort;

template expTypeFromExpModelica(Exp exp)

::=
  expTypeFromExpFlag(exp, 2)
end expTypeFromExpModelica;

template expTypeFromExpArray(Exp exp)

::=
  expTypeFromExpFlag(exp, 6)
end expTypeFromExpArray;

template assertCommon(Exp condition, Exp message, Context context, Text &varDecls, builtin.SourceInfo info, SimCode simCode,
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
        throw ModelicaSimulationError(MODEL_EQ_SYSTEM,<%msgVar%>);

       }
      >>
      else
      <<
      if(!<%condVar%>)
      {
        <%preExpCond%>
        <%preExpMsg%>
       throw ModelicaSimulationError() << error_id(MODEL_EQ_SYSTEM);
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

template daeExpCallBuiltinPrefix(Boolean builtin)
 "Helper to daeExpCall."
::=
  match builtin
  case true  then ""
  case false then "_"
end daeExpCallBuiltinPrefix;


template daeExpLunary(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                      Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a logical unary expression."
::=
match exp
case LUNARY(__) then
  let e = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match operator
  case NOT(__) then '(!<%e%>)'
end daeExpLunary;

template daeExpLbinary(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,
                       Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a logical binary expression."
::=
match exp
case LBINARY(__) then
  let e1 = daeExp(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let e2 = daeExp(exp2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match operator
  case AND(__) then '(<%e1%> && <%e2%>)'
  case OR(__)  then '(<%e1%> || <%e2%>)'
  else "daeExpLbinary:ERR"
end daeExpLbinary;

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

template daeExpBinary(Operator it, Exp exp1, Exp exp2, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                      Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let e1 = daeExp(exp1, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let e2 = daeExp(exp2, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match it
  case ADD(__) then '(<%e1%> + <%e2%>)'
  case SUB(__) then '(<%e1%> - <%e2%>)'
  case MUL(__) then '(<%e1%> * <%e2%>)'
  case DIV(__) then '(<%e1%> / <%e2%>)'
  case POW(__) then 'std::pow(<%e1%>, <%e2%>)'
  case AND(__) then '(<%e1%> && <%e2%>)'
  case OR(__)  then '(<%e1%> || <%e2%>)'
  case MUL_ARRAY_SCALAR(ty=T_ARRAY(dims=dims)) then
    //let dimensions = (dims |> dim as DIM_INTEGER(integer=i)  =>  '<%i%>';separator=",")
    let dimensions = checkDimension(dims)
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then 'multi_array<int,<%listLength(dims)%>>'
                        case T_ARRAY(ty=T_ENUMERATION(__)) then 'multi_array<int,<%listLength(dims)%>>'
            //previous multi_array multi_array<double,<%listLength(dims)%>>
                        else match dimensions
                case "" then 'DynArrayDim<%listLength(dims)%><double>'
                else 'StatArrayDim<%listLength(dims)%><double, <%dimensions%> > '



  let type1 = match ty case T_ARRAY(ty=T_INTEGER(__)) then "int"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "int"
                        else "double"
    //let var = tempDecl(type,&varDecls /*BUFD*/)
    let var1 = tempDecl1(type,e1,&varDecls /*BUFD*/)
    //let &preExp += '<%var1%>=multiply_array<<%type1%>,<%listLength(dims)%>>(<%e1%>, <%e2%>);<%\n%>'
  // previous multiarray let &preExp += 'assign_array(<%var1%>,multiply_array<<%type1%>,<%listLength(dims)%>>(<%e1%>, <%e2%>));<%\n%>'
    let &preExp +='multiply_array<<%type1%>>(<%e1%>, <%e2%>, <%var1%>);<%\n%>'
    '<%var1%>'
  case MUL_MATRIX_PRODUCT(ty=T_ARRAY(dims=dims)) then
    //let dimensions = (dims |> dim as DIM_INTEGER(integer=i)  =>  '<%i%>';separator=",")
     let dimstr = checkDimension(dims)
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then 'multi_array<int,<%listLength(dims)%>>'
                        case T_ARRAY(ty=T_ENUMERATION(__)) then 'multi_array<int,<%listLength(dims)%>>'
                        else match dimstr
                case "" then 'DynArrayDim<%listLength(dims)%><double>'
                else 'StatArrayDim<%listLength(dims)%><double, <%dimstr%> >'
    let type1 = match ty case T_ARRAY(ty=T_INTEGER(__)) then "int"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "int"
                        else "double"
    //let var = tempDecl(type,&varDecls /*BUFD*/)
    let var1 = tempDecl1(type,e1,&varDecls /*BUFD*/)
  // previous multi_array let &preExp += 'assign_array(<%var1%>,multiply_array<<%type1%>,<%listLength(dims)%>>(<%e1%>, <%e2%>));<%\n%>'
    let &preExp +='multiply_array<<%type1%>>(<%e1%>, <%e2%>, <%var1%>);<%\n%>'
    '<%var1%>'
  case DIV_ARRAY_SCALAR(ty=T_ARRAY(dims=dims)) then
 //let dimensions = (dims |> dim as DIM_INTEGER(integer=i)  =>  '<%i%>';separator=",")
    let dimensions = checkDimension(dims)
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then 'multi_array<int,<%listLength(dims)%>>'
                        case T_ARRAY(ty=T_ENUMERATION(__)) then 'multi_array<int,<%listLength(dims)%>>'
            //previous multi_array multi_array<double,<%listLength(dims)%>>
                        else match dimensions
                case "" then 'DynArrayDim<%listLength(dims)%><double>'
                else 'StatArrayDim<%listLength(dims)%><double, <%dimensions%> >'



  let type1 = match ty case T_ARRAY(ty=T_INTEGER(__)) then "int"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "int"
                        else "double"
    //let var = tempDecl(type,&varDecls /*BUFD*/)
  let &tempvarDecl = buffer ""
    let var1 = tempDecl(type,&tempvarDecl /*BUFD*/)
  let &preExp +='<%tempvarDecl%><%\n%> '
    //let &preExp += '<%var1%>=multiply_array<<%type1%>,<%listLength(dims)%>>(<%e1%>, <%e2%>);<%\n%>'
  // previous multiarray let &preExp += 'assign_array(<%var1%>,multiply_array<<%type1%>,<%listLength(dims)%>>(<%e1%>, <%e2%>));<%\n%>'
    let &preExp +='divide_array<<%type1%>>(<%e1%>, <%e2%>, <%var1%>);<%\n%>'
    '<%var1%>'
  case DIV_SCALAR_ARRAY(ty=T_ARRAY(dims=dims)) then
    //let dimensions = (dims |> dim as DIM_INTEGER(integer=i)  =>  '<%i%>';separator=",")
    let dimstr = checkDimension(dims)
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then 'int'
                        case T_ARRAY(ty=T_ENUMERATION(__)) then 'int'
                        else 'double'
  let var =  match dimstr
        case "" then tempDecl('DynArrayDim<%listLength(dims)%><<%type%>>', &varDecls /*BUFD*/)
        else tempDecl('StatArrayDim<%listLength(dims)%><<%type%>, <%dimstr%> > ', &varDecls /*BUFD*/)
    //let var = tempDecl1(type,e1,&varDecls /*BUFD*/)
    //let &preExp += 'assign_array(<%var%>,divide_array<<%type%>,<%listLength(dims)%>>(<%e2%>, <%e1%>));<%\n%>'
    '<%var%>'
  case UMINUS(__) then "daeExpBinary:ERR UMINUS not supported"
  case UMINUS_ARR(__) then "daeExpBinary:ERR UMINUS_ARR not supported"

  case ADD_ARR(ty=T_ARRAY(dims=dims)) then
  //let dimensions = (dims |> dim as DIM_INTEGER(integer=i)  =>  '<%i%>';separator=",")
   let dimstr = checkDimension(dims)
  let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "int"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "int"
                        else "double"
  let var =  match dimstr
          case "" then tempDecl('DynArrayDim<%listLength(dims)%><<%type%>>', &varDecls /*BUFD*/)
          else tempDecl('StatArrayDim<%listLength(dims)%><<%type%>, <%dimstr%> > ', &varDecls /*BUFD*/)
    //let var = tempDecl1(type,e1,&varDecls /*BUFD*/)
    let &preExp += 'add_array<<%type%>>(<%e1%>, <%e2%>,<%var%>);<%\n%>'
    '<%var%>'
  case SUB_ARR(ty=T_ARRAY(dims=dims)) then
  //let dimensions = (dims |> dim as DIM_INTEGER(integer=i)  =>  '<%i%>';separator=",")
  let dimstr = checkDimension(dims)
  let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "int"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then  "int"
                        else "double"
  let var =  match dimstr
        case "" then tempDecl('DynArrayDim<%listLength(dims)%><<%type%>>', &varDecls /*BUFD*/)
        else tempDecl('StatArrayDim<%listLength(dims)%><<%type%>, <%dimstr%>> ', &varDecls /*BUFD*/)

    //let var = tempDecl1(type,e1,&varDecls /*BUFD*/)
    let &preExp += 'subtract_array<<%type%>>(<%e1%>, <%e2%>, <%var%>);<%\n%>'
    '<%var%>'
  case MUL_ARR(__) then "daeExpBinary:ERR MUL_ARR not supported"
  case DIV_ARR(__) then "daeExpBinary:ERR DIV_ARR not supported"
  case ADD_ARRAY_SCALAR(__) then "daeExpBinary:ERR ADD_ARRAY_SCALAR not supported"
  case SUB_SCALAR_ARRAY(__) then "daeExpBinary:ERR SUB_SCALAR_ARRAY not supported"
  case MUL_SCALAR_PRODUCT(__) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then 'int'
                        case T_ARRAY(ty=T_ENUMERATION(__)) then 'int'
                        else 'double'
    'dot_array<<%type%>>(<%e1%>, <%e2%>)'
  case DIV_SCALAR_ARRAY(__) then "daeExpBinary:ERR DIV_SCALAR_ARRAY not supported"
  case POW_ARRAY_SCALAR(ty=T_ARRAY(dims=dims)) then
    let dimstr = checkDimension(dims)
    let type = "double"
    let var = match dimstr // copy to contiguous memory and pow in situ
      case "" then tempDecl1('DynArrayDim<%listLength(dims)%><<%type%>>', e1, &preExp)
      else tempDecl1('StatArrayDim<%listLength(dims)%><<%type%>, <%dimstr%>>', e1, &preExp)
    let &preExp += 'pow_array_scalar(<%var%>, <%e2%>, <%var%>);<%\n%>'
    '<%var%>'
  case POW_SCALAR_ARRAY(__) then "daeExpBinary:ERR POW_SCALAR_ARRAY not supported"
  case POW_ARR(__) then "daeExpBinary:ERR POW_ARR not supported"
  case POW_ARR2(__) then "daeExpBinary:ERR POW_ARR2 not supported"
  case NOT(__) then "daeExpBinary:ERR NOT not supported"
  case LESS(__) then "daeExpBinary:ERR LESS not supported"
  case LESSEQ(__) then "daeExpBinary:ERR LESSEQ not supported"
  case GREATER(__) then "daeExpBinary:ERR GREATER not supported"
  case GREATEREQ(__) then "daeExpBinary:ERR GREATEREQ not supported"
  case EQUAL(__) then "daeExpBinary:ERR EQUAL not supported"
  case NEQUAL(__) then "daeExpBinary:ERR NEQUAL not supported"
  case USERDEFINED(__) then "daeExpBinary:ERR POW_ARR not supported"
  case _   then 'daeExpBinary:ERR'
end daeExpBinary;

template tempDecl1(String ty, String exp, Text &varDecls /*BUFP*/)
 "Declares a temporary variable in varDecls and returns the name."
::=
  let newVar = 'tmp<%System.tmpTick()%>'
  let newVar1 = '<%newVar%>(<%exp%>)'
  let &varDecls += '<%ty%> <%newVar1%>;<%\n%>'
  newVar
end tempDecl1;


template daeExpSconst(String string, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                      Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a string constant."
::=
  '"<%Util.escapeModelicaStringToCString(string)%>"'
end daeExpSconst;

template daeExpUnary(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs,
                     Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a unary expression."
::=
match exp
case UNARY(__) then
  let e = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match operator
  case UMINUS(__)     then '(-<%e%>)'
  case UMINUS_ARR(ty=T_ARRAY(ty=T_REAL(__))) then

    let dimensions = (ty.dims |> dim as DIM_INTEGER(integer=i)  =>  '<%i%>';separator=",")
    let listlength = listLength(ty.dims)
  let tmp_type_str =  match dimensions
        case "" then 'DynArrayDim<%listlength%><double>'
        else 'StatArrayDim<%listlength%><double, <%dimensions%>>'


   //previous multi_array let tmp_type_str =  'multi_array<double,<%listLength(ty.dims)%>>'

   let tvar = tempDecl(tmp_type_str, &varDecls /*BUFD*/)
    let &preExp += 'usub_array<double>(<%e%>,<%tvar%>);<%\n%>'
    '<%tvar%>'
  case UMINUS_ARR(ty=T_ARRAY(ty=T_INTEGER(__))) then
    let tmp_type_str =  'multi_array<int,<%listLength(ty.dims)%>>/*multi3*/'
    let tvar = tempDecl(tmp_type_str, &varDecls /*BUFD*/)
    let &preExp += 'usub_array<int>(<%e%>,<%tvar%>);<%\n%>'
    '<%tvar%>'
  case UMINUS_ARR(__) then 'unary minus for non-real arrays not implemented'
  else "daeExpUnary:ERR"
end daeExpUnary;


template daeExpCrefRhs(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs,
                       Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a component reference on the right hand side of an
 expression."
::=
  match exp

   // A record cref without subscripts (i.e. a record instance) is handled
  // by daeExpRecordCrefRhs only in a simulation context, not in a function.
  case CREF(componentRef = cr, ty = t as T_COMPLEX(complexClassType = RECORD(path = _))) then
    match context case FUNCTION_CONTEXT(__) then
      '<%daeExpCrefRhs2(exp, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
    else
      daeExpRecordCrefRhs(t, cr, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)

  case CREF(componentRef = cr, ty = T_FUNCTION_REFERENCE_FUNC(__)) then
    '((modelica_fnptr)boxptr_<%crefFunctionName(cr)%>)'
  case CREF(componentRef = cr, ty = T_FUNCTION_REFERENCE_VAR(__)) then
    '((modelica_fnptr) _<%crefStr(cr)%>)'
  else '<%daeExpCrefRhs2(exp, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
end daeExpCrefRhs;

template daeExpRecordCrefRhs(DAE.Type ty, ComponentRef cr, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs,
                             Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match ty
case T_COMPLEX(complexClassType = record_state, varLst = var_lst) then
  let vars = var_lst |> v => daeExp(makeCrefRecordExp(cr,v), context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
             ;separator=", "
  let record_type_name = underscorePath(ClassInf.getStateName(record_state))
  let ret_type = '<%record_type_name%>RetType'
  let ret_var = tempDecl(ret_type, &varDecls)
  let &preExp += '_functions-><%record_type_name%>(<%vars%>,<%ret_var%>);<%\n%>/*testfunction*/'
  '<%ret_var%>'
end daeExpRecordCrefRhs;


template daeExpCrefRhs2(Exp ecr, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs,
                        Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a component reference."
::=
  match ecr
  case component as CREF(componentRef=cr, ty=ty) then
    let box = daeExpCrefRhsArrayBox(cr,ty, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
    if box then
     box
    else if crefIsScalar(cr, context) then
      let cast = match ty case T_INTEGER(__) then ""
                          case T_ENUMERATION(__) then "" //else ""
      '<%cast%><%contextCref(cr,context,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
    else
     if crefSubIsScalar(cr) then
      // The array subscript results in a scalar
      let arrName = contextCref(crefStripLastSubs(cr), context,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      let arrayType = expTypeArray(ty)
      //let dimsLenStr = listLength(crefSubs(cr))
    // previous multi_array ;separator="][")
      let dimsValuesStr = (crefSubs(cr) |> INDEX(__) =>
          daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        ;separator=",")
      match arrayType
        case "metatype_array" then
          'arrayGet(<%arrName%>,<%dimsValuesStr%>) /* DAE.CREF */'
        else
    /*
      <<
          <%arrName%>[<%dimsValuesStr%>]
          >>
    */
         <<
         <%arrName%>(<%dimsValuesStr%>)
         >>
    else
      // The array subscript denotes a slice
      let arrName = contextArrayCref(cr, context)
      let typeStr = expTypeArray(ty)
      let slice = daeExpCrefIndexSpec(crefSubs(cr), context, &preExp,
        &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace,
        stateDerVectorName, useFlatArrayNotation)
      let &preExp += 'ArraySlice<<%typeStr%>> <%slice%>_as(<%arrName%>, <%slice%>);<%\n%>'
      '<%slice%>_as'
      // old code making a copy of the slice using create_array_from_shape
      //let arrayType = expTypeFlag(ty, 6)
      /* let dimstr = listLength(crefSubs(cr))
      let dimsValuesStr = (crefSubs(cr) |> INDEX(__) =>
          daeExp(exp, context, &preExp , &varDecls ,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        ;separator="][")*/
      //let tmp = tempDecl(arrayType, &varDecls /*BUFD*/)
      //let spec1 = daeExpCrefRhsIndexSpec(crefSubs(cr), context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      //let &preExp += 'create_array_from_shape(<%spec1%>,<%arrName%>,<%tmp%>);<%\n%>'
      //tmp
end daeExpCrefRhs2;

template daeExpCrefRhsIndexSpec(list<Subscript> subs, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs,
                                Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Helper to daeExpCrefRhs. Bogus and not used (#3263)."
::=

  let nridx_str = listLength(subs)
  //let tmp = tempDecl("index_type", &varDecls /*BUFD*/)
  let tmp_shape = tempDecl("vector<size_t>", &varDecls /*BUFD*/)
  let tmp_indeces = tempDecl("idx_type", &varDecls /*BUFD*/)
  let idx_str = (subs |> sub  hasindex i1 =>
      match sub
      case INDEX(__) then
         let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        let tmp_idx = tempDecl("vector<size_t>", &varDecls /*BUFD*/)
        let &preExp += '<%tmp_shape%>.push_back(0);<%\n%>
                        <%tmp_idx%>.push_back(<%expPart%>);<%\n%>
                        <%tmp_indeces%>.push_back(<%tmp_idx%>);<%\n%>'
      ''
      case WHOLEDIM(__) then
       let tmp_idx = tempDecl("vector<size_t>", &varDecls /*BUFD*/)
       let &preExp += '<%tmp_shape%>.push_back(1);<%\n%>
                       <%tmp_indeces%>.push_back(<%tmp_idx%>);<%\n%>'
       ''
      case SLICE(__) then
        let tmp_idx = tempDecl("vector<size_t>", &varDecls /*BUFD*/)
        let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        let &preExp +=  '<%tmp_idx%>.assign(<%expPart%>.getData(),<%expPart%>.getData()+<%expPart%>.getNumElems());<%\n%>
                         <%tmp_shape%>.push_back(<%expPart%>.getDim(1));<%\n%>
                         <%tmp_indeces%>.push_back(<%tmp_idx%>);<%\n%>'
       ''
    ;separator="\n ")
   << make_pair(<%tmp_shape%>,<%tmp_indeces%>) >>
end daeExpCrefRhsIndexSpec;


template daeExpCrefRhsArrayBox(ComponentRef cr,DAE.Type ty, Context context, Text &preExp /*BUFP*/,
                               Text &varDecls /*BUFP*/,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Helper to daeExpCrefRhs."
::=
 cref2simvar(cr, simCode) |> var as SIMVAR(index=i) =>
    match varKind
        case STATE(__)     then
              let statvar = '__z[<%i%>]'
              let tmpArr = '<%daeExpCrefRhsArrayBox2(statvar,ty,context,preExp,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>'
              tmpArr
        case STATE_DER(__)      then
              let statvar = '__zDot[<%i%>]'
              let tmpArr = '<%daeExpCrefRhsArrayBox2(statvar,ty,context,preExp,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%>'
              tmpArr
        else
          match context
          case FUNCTION_CONTEXT(__) then ''
          else
            match ty
            case t as T_ARRAY(ty=aty, dims=dims) then
              match cr
              case CREF_QUAL(ident = "$PRE") then
                let arr = arrayCrefCStr(componentRef, context)
                let ndims = listLength(dims)
                let dimstr = checkDimension(dims)
                let T = expTypeShort(aty)
                let &preExp +=
                  <<
                  StatArrayDim<%ndims%><<%T%>, <%dimstr%>> <%arr%>_pre;
                  std::transform(<%arr%>.getDataRefs(),
                                 <%arr%>.getDataRefs() + <%arr%>.getNumElems(),
                                 <%arr%>_pre.getData(),
                                 PreRefArray2CArray<<%T%>>(_discrete_events));
                  >>
                '<%arr%>_pre'
              else
                arrayCrefCStr(cr,context)
            else ''
end daeExpCrefRhsArrayBox;


template daeExpCrefRhsArrayBox2(Text var,DAE.Type type, Context context, Text &preExp /*BUFP*/,
                               Text &varDecls /*BUFP*/,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace) ::=
 match type
  case t as T_ARRAY(ty=aty,dims=dims)        then

    let dimstr = checkDimension(dims)

    let arraytype =   match dimstr
      case "" then 'DynArrayDim<%listLength(dims)%><<%expTypeShort(type)%>>'
      else   'StatArrayDim<%listLength(dims)%><<%expTypeShort(type)%>,<%dimstr%>>'
      end match
    let &tmpdecl = buffer "" /*BUFD*/
    let arrayVar = tempDecl(arraytype, &tmpdecl /*BUFD*/)
    let boostExtents = '<%arraytype%><%arrayVar%>;'
    //let size = (dims |> dim => dimension(dim) ;separator="+")
   // let arrayassign =  '<%arrayVar%>.assign(&<%var%>,&<%var%>+(<%size%>));<%\n%>'
    let arrayassign =  '<%arrayVar%>.assign(&<%var%>);<%\n%>'
    let &preExp += '
          //tmp array3
          <%boostExtents%>
         <%arrayassign%>'
    arrayVar
  else
    var
end daeExpCrefRhsArrayBox2;


template daeExpCrefIndexSpec(list<Subscript> subs, Context context,
  Text &preExp, Text &varDecls, SimCode simCode,
  Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace,
  Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates index spec of an array as temporary vector<Slice>."
::=
  let tmp_slice = tempDecl("vector<Slice>", &varDecls /*BUFD*/)
  let &preExp += '<%tmp_slice%>.clear();<%\n%>'
  let idx_str = (subs |> sub hasindex i1 =>
    match sub
      case INDEX(__) then
        let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        let &preExp += '<%tmp_slice%>.push_back(Slice(<%expPart%>));<%\n%>'
        ''
      case WHOLEDIM(__) then
        let &preExp += '<%tmp_slice%>.push_back(Slice());<%\n%>'
        ''
      case SLICE(__) then
        let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        let &preExp += '<%tmp_slice%>.push_back(Slice(<%expPart%>));<%\n%>'
        ''
    ;separator="\n ")
  <<<%tmp_slice%>>>
end daeExpCrefIndexSpec;


template cref1(ComponentRef cr, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text &varDecls, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
  match cr
  case CREF_IDENT(ident = "xloc") then '<%representationCref(cr, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>'
  case CREF_IDENT(ident = "time") then
   match context
    case  ALGLOOP_CONTEXT(genInitialisation=false)
    then "_system->_simTime"
    else
    "_simTime"
    end match
  //filter key words for variable names
  case CREF_IDENT(ident = "unsigned") then 'unsigned_'
  case CREF_IDENT(ident = "string") then 'string_'
  case CREF_IDENT(ident = "int") then 'int_'
  else '<%representationCref(cr, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context, varDecls, stateDerVectorName, useFlatArrayNotation) %>'
end cref1;

template representationCref(ComponentRef inCref, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text &varDecls, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
  cref2simvar(inCref, simCode) |> var as SIMVAR(__) =>
  match varKind
    case STATE(__)        then
        << <%representationCref1(inCref,var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context, useFlatArrayNotation)%> >>
    case STATE_DER(__)   then
        << <%representationCref2(inCref,var,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context, stateDerVectorName)%> >>
    case VARIABLE(__) then
      match var
        case SIMVAR(index=-2) then
          match context
            case JACOBIAN_CONTEXT() then
              '_<%crefToCStr(inCref,false)%>'
            case ALGLOOP_CONTEXT(__) then
              '_system->_<%crefToCStr(inCref,false)%>'
            else
              '<%localcref(inCref, useFlatArrayNotation)%>'
          end match
        else
          match context
            case ALGLOOP_CONTEXT(genInitialisation = false, genJacobian=false) then
              '_system-><%cref(inCref, useFlatArrayNotation)%>'
            case ALGLOOP_CONTEXT(genInitialisation = false, genJacobian=true) then
              '_system->_<%crefToCStr(inCref,false)%>'
            else
              '<%varToString(inCref,context, useFlatArrayNotation)%>'
      else
        match context
          case ALGLOOP_CONTEXT(genInitialisation = false) then
            let &varDecls += '//_system-><%cref(inCref, useFlatArrayNotation)%>; definition of global variable<%\n%>'
            '_system-><%cref(inCref, useFlatArrayNotation)%>'
          else
            '<%cref(inCref, useFlatArrayNotation)%>'
end representationCref;


template representationCrefDerVar(ComponentRef inCref, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot */) ::=
  cref2simvar(inCref, simCode ) |> SIMVAR(__) =>'<%stateDerVectorName%>[<%index%>]'
end representationCrefDerVar;


template representationCref1(ComponentRef inCref,SimVar var, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Boolean useFlatArrayNotation) ::=
   match var
    case SIMVAR(index=i) then
    match i
   case -1 then
  '<%cref2(inCref, useFlatArrayNotation)%>'
   case _  then
   << __z[<%i%>] >>
end representationCref1;

template representationCref2(ComponentRef inCref, SimVar var,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot */) ::=
 match var
case(SIMVAR(index=i)) then
  match context
         case JACOBIAN_CONTEXT()
                //then   <<<%crefWithoutIndexOperator(inCref)%>>>
                then  '_<%crefToCStr(inCref,false)%>'
        else
             <<<%stateDerVectorName%>[<%i%>]>>
end representationCref2;

template helpvarlength(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match simCode
case SIMCODE(__) then
  <<
  0
  >>
end helpvarlength;

template zerocrosslength(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__))) then
   let size = listLength(zeroCrossings)
  <<
  <%intSub(listLength(zeroCrossings), vi.numTimeEvents)%>
  >>
end zerocrosslength;


template timeeventlength(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__))) then

  <<
  <%vi.numTimeEvents%>
  >>
end timeeventlength;



template dimZeroFunc(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
  int <%lastIdentOfPath(modelInfo.name)%>::getDimZeroFunc()
  {
    return _dimZeroFunc;
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

template daeExpRelation(Exp exp, Context context, Text &preExp,Text &varDecls,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match exp
case rel as RELATION(__) then
match rel.optionExpisASUB
 case NONE() then
    daeExpRelation2(rel.operator,rel.index,rel.exp1,rel.exp2, context, preExp,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
 case SOME((exp,i,j)) then
    let e1 = daeExp(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let e2 = daeExp(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    match context
    case ALGLOOP_CONTEXT(genInitialisation = false) then
       match rel.operator
       case LESS(__) then
          '_system->getCondition(<%rel.index%>) && (<%e1%> < <%e2%>)'

        case LESSEQ(__) then
          '_system->getCondition(<%rel.index%>) && (<%e1%> <= <%e2%>)'

        case GREATER(__) then
          '_system->getCondition(<%rel.index%>) && (<%e1%> > <%e2%>)'

        case GREATEREQ(__) then
         '_system->getCondition(<%rel.index%>)  && (<%e1%> >= <%e2%>)'
            end match
   else
          match rel.operator
        case LESS(__) then
          'getCondition(<%rel.index%>) && (<%e1%> < <%e2%>)'

        case LESSEQ(__) then
          'getCondition(<%rel.index%>) && (<%e1%> <= <%e2%>)'

        case GREATER(__) then
          'getCondition(<%rel.index%>) && (<%e1%> > <%e2%>)'

        case GREATEREQ(__) then
         'getCondition(<%rel.index%>) && (<%e1%> >= <%e2%>)'
            end match
end daeExpRelation;


template daeExpRelation3(Context context,Integer index) ::=
match context
    case ALGLOOP_CONTEXT(genInitialisation = false)
        then  <<_system->getCondition(<%index%>)>>
    else
       <<getCondition(<%index%>)>>
end daeExpRelation3;


template daeExpRelation2(Operator op, Integer index,Exp exp1, Exp exp2, Context context, Text &preExp,Text &varDecls,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
  let e1 = daeExp(exp1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let e2 = daeExp(exp2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match index
  case -1 then
     match op
    case LESS(ty = T_BOOL(__))        then '(!<%e1%> && <%e2%>)'
    case LESS(ty = T_STRING(__))      then "# string comparison not supported\n"
    case LESS(ty = T_INTEGER(__))
    case LESS(ty = T_REAL(__))        then '(<%e1%> < <%e2%>)'
    case LESS(ty = T_ENUMERATION(__))      then '(<%e1%> < <%e2%>)'

    case GREATER(ty = T_BOOL(__))     then '(<%e1%> && !<%e2%>)'
    case GREATER(ty = T_STRING(__))   then "# string comparison not supported\n"
    case GREATER(ty = T_INTEGER(__))
    case GREATER(ty = T_REAL(__))     then '(<%e1%> > <%e2%>)'
     case GREATER(ty = T_ENUMERATION(__))   then '(<%e1%> > <%e2%>)'

    case LESSEQ(ty = T_BOOL(__))      then '(!<%e1%> || <%e2%>)'
    case LESSEQ(ty = T_STRING(__))    then "# string comparison not supported\n"
    case LESSEQ(ty = T_INTEGER(__))
    case LESSEQ(ty = T_REAL(__))       then '(<%e1%> <= <%e2%>)'
    case LESSEQ(ty = T_ENUMERATION(__))    then '(<%e1%> <= <%e2%>)'

    case GREATEREQ(ty = T_BOOL(__))   then '(<%e1%> || !<%e2%>)'
    case GREATEREQ(ty = T_STRING(__)) then "# string comparison not supported\n"
    case GREATEREQ(ty = T_INTEGER(__))
    case GREATEREQ(ty = T_REAL(__))   then '(<%e1%> >= <%e2%>)'
     case GREATEREQ(ty = T_ENUMERATION(__)) then '(<%e1%> >= <%e2%>)'

    case EQUAL(ty = T_BOOL(__))       then '((!<%e1%> && !<%e2%>) || (<%e1%> && <%e2%>))'
    case EQUAL(ty = T_STRING(__))
    case EQUAL(ty = T_INTEGER(__))
    case EQUAL(ty = T_REAL(__))       then '(<%e1%> == <%e2%>)'
    case EQUAL(ty = T_ENUMERATION(__))     then '(<%e1%> == <%e2%>)'

    case NEQUAL(ty = T_BOOL(__))      then '((!<%e1%> && <%e2%>) || (<%e1%> && !<%e2%>))'
    case NEQUAL(ty = T_STRING(__))
    case NEQUAL(ty = T_INTEGER(__))
    case NEQUAL(ty = T_REAL(__))      then '(<%e1%> != <%e2%>)'
    case NEQUAL(ty = T_ENUMERATION(__))    then '(<%e1%> != <%e2%>)'

    case _                            then "daeExpRelation:ERR"
      end match
  case _ then
     match op
    case LESS(ty = T_BOOL(__))        then daeExpRelation3(context,index)
    case LESS(ty = T_STRING(__))      then "# string comparison not supported\n"
    case LESS(ty = T_INTEGER(__))
    case LESS(ty = T_REAL(__))        then daeExpRelation3(context,index)

    case GREATER(ty = T_BOOL(__))     then daeExpRelation3(context,index)
    case GREATER(ty = T_STRING(__))   then "# string comparison not supported\n"
    case GREATER(ty = T_INTEGER(__))
    case GREATER(ty = T_REAL(__))     then daeExpRelation3(context,index)

    case LESSEQ(ty = T_BOOL(__))      then daeExpRelation3(context,index)
    case LESSEQ(ty = T_STRING(__))    then "# string comparison not supported\n"
    case LESSEQ(ty = T_INTEGER(__))
    case LESSEQ(ty = T_REAL(__))       then daeExpRelation3(context,index)

    case GREATEREQ(ty = T_BOOL(__))   then daeExpRelation3(context,index)
    case GREATEREQ(ty = T_STRING(__)) then "# string comparison not supported\n"
    case GREATEREQ(ty = T_INTEGER(__))
    case GREATEREQ(ty = T_REAL(__))   then daeExpRelation3(context,index)

    case EQUAL(ty = T_BOOL(__))       then daeExpRelation3(context,index)
    case EQUAL(ty = T_STRING(__))
    case EQUAL(ty = T_INTEGER(__))
    case EQUAL(ty = T_REAL(__))       then daeExpRelation3(context,index)

    case NEQUAL(ty = T_BOOL(__))      then daeExpRelation3(context,index)
    case NEQUAL(ty = T_STRING(__))
    case NEQUAL(ty = T_INTEGER(__))
    case NEQUAL(ty = T_REAL(__))      then daeExpRelation3(context,index)
    case _                         then "daeExpRelationCondition:ERR"
      end match
end daeExpRelation2;


template daeExpIf(Exp cond, Exp then_, Exp else_, Context context, Text &preExp, Text &varDecls,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
  let condExp = daeExp(cond, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let &preExpThen = buffer ""
  let eThen = daeExp(then_, context, &preExpThen, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let &preExpElse = buffer ""
  let eElse = daeExp(else_, context, &preExpElse /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      //let resVarType = expTypeFromExpArrayIf(else_,context,preExp,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
      let resVar  = expTypeFromExpArrayIf(else_,context,preExp,varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      /*previous multi_array instead of .assign:
    'assign_array(<%resVar%>,<%eThen%>);'
    */
    let &preExp +=
      <<
      if <%encloseInParantheses(condExp)%> {
        <%preExpThen%>
        <% match typeof(then_)
            case T_ARRAY(dims=dims) then
              '<%resVar%>.assign(<%eThen%>);'
                else
                '<%resVar%> = <%eThen%>;'
                %>
      } else {
        <%preExpElse%>
        <%match typeof(else_)
            case T_ARRAY(dims=dims) then
              '<%resVar%>.assign(<%eElse%>);'
                else
                '<%resVar%> = <%eElse%>;'
        %>
      }<%\n%>
      >>
      resVar
end daeExpIf;


template encloseInParantheses(String expStr)
 "Encloses expression in paranthesis if not yet given"
::=
if intEq(stringGet(expStr, 1), stringGet("(", 1)) then '<%expStr%>' else '(<%expStr%>)'
end encloseInParantheses;


template expTypeFromExpArrayIf(Exp exp, Context context, Text &preExp, Text &varDecls,SimCode simCode,
                               Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for an array expression."
::=
match exp
case ARRAY(__) then
  let arrayTypeStr = expTypeArray(ty)
  let StatArrayDim = expTypeArrayforDim(ty)
  let &tmpdecl = buffer "" /*BUFD*/
  let arrayVar = tempDecl(arrayTypeStr, &tmpdecl /*BUFD*/)
  // let scalarPrefix = if scalar then "scalar_" else ""
  //let scalarRef = if scalar then "&" else ""
  let &tmpVar = buffer ""
  let params = (array |> e =>
    '<%daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
   ;separator=", ")
   /* previous multi_array
      //tmp array
   <%StatArrayDim%><%arrayVar%>(boost::extents[<%listLength(array)%>]);
   <%arrayVar%>.reindex(1);'
   */
   let &preExp += '
   //tmp array
   <%StatArrayDim%><%arrayVar%>;<%\n%>'
  arrayVar
  else
    match typeof(exp)
      case ty as T_ARRAY(dims=dims) then
    // previous multi_array let resVarType = 'multi_array<<%expTypeShort(ty)%>,<%listLength(dims)%>>'
      let resVarType = 'DynArrayDim<%listLength(dims)%><<%expTypeShort(ty)%>>'//TODO evtl statarray
       let resVar = tempDecl(resVarType, &varDecls /*BUFD*/)

      resVar
     else
    let resVarType = expTypeFlag(typeof(exp), 2)
    let resVar = tempDecl(resVarType, &varDecls /*BUFD*/)
   resVar
   end match
  end match
end expTypeFromExpArrayIf;



template expTypeFromExp(Exp it) ::=
  match it
  case ICONST(__)    then "int"
  case ENUM_LITERAL(__)    then "int"
  case RCONST(__)    then "double"
  case SCONST(__)    then "string"
  case BCONST(__)    then "bool"
  case BINARY(__)
  case UNARY(__)
  case LBINARY(__)
  case LUNARY(__)     then expTypeFromOp(operator)
  case RELATION(__)   then "bool" //TODO: a HACK, it was expTypeFromOp(operator)
  case IFEXP(__)      then expTypeFromExp(expThen)
  case CALL(attr=CALL_ATTR(__))       then expTypeShort(attr.ty)
  case ARRAY(__)
  case MATRIX(__)
  case RANGE(__)
  case CAST(__)
  case CREF(__)
  case CODE(__)       then expTypeShort(ty)
  case ASUB(__)       then expTypeFromExp(exp)
  case REDUCTION(__)  then expTypeFromExp(expr)

  case TUPLE(__) then "expTypeFromExp:ERROR TUPLE unsupported"
  case TSUB(__) then "expTypeFromExp:ERROR TSUB unsupported"
  case SIZE(__) then "expTypeFromExp:ERROR SIZE unsupported"

  /* Part of MetaModelica extension. KS */
  case LIST(__) then "expTypeFromExp:ERROR LIST unsupported"
  case CONS(__) then "expTypeFromExp:ERROR CONS unsupported"
  case META_TUPLE(__) then "expTypeFromExp:ERROR META_TUPLE unsupported"
  case META_OPTION(__) then "expTypeFromExp:ERROR META_OPTION unsupported"
  case METARECORDCALL(__) then "expTypeFromExp:ERROR METARECORDCALL unsupported"
  case MATCHEXPRESSION(__) then "expTypeFromExp:ERROR MATCHEXPRESSION unsupported"
  case BOX(__) then "expTypeFromExp:ERROR BOX unsupported"
  case UNBOX(__) then "expTypeFromExp:ERROR UNBOX unsupported"
  case SHARED_LITERAL(__) then expTypeFromExp(exp)
  case PATTERN(__) then "expTypeFromExp:ERROR PATTERN unsupported"

  case _          then "expTypeFromExp:ERROR"
end expTypeFromExp;


template expTypeFromOp(Operator it) ::=
  match it
  case ADD(__)
  case SUB(__)
  case MUL(__)
  case DIV(__)
  case POW(__)
  case UMINUS(__)
  case UMINUS_ARR(__)
  case ADD_ARR(__)
  case SUB_ARR(__)
  case MUL_ARR(__)
  case DIV_ARR(__)
  case MUL_ARRAY_SCALAR(__)
  case ADD_ARRAY_SCALAR(__)
  case SUB_SCALAR_ARRAY(__)
  case MUL_SCALAR_PRODUCT(__)
  case MUL_MATRIX_PRODUCT(__)
  case DIV_ARRAY_SCALAR(__)
  case DIV_SCALAR_ARRAY(__)
  case POW_ARRAY_SCALAR(__)
  case POW_SCALAR_ARRAY(__)
  case POW_ARR(__)
  case POW_ARR2(__)
  case LESS(__)
  case LESSEQ(__)
  case GREATER(__)
  case GREATEREQ(__)
  case EQUAL(__)
  case NEQUAL(__)       then  expTypeShort(ty)
  case AND(__)
  case OR(__)
  case NOT(__) then "bool"
  case _ then "expTypeFromOp:ERROR"
end expTypeFromOp;

template equationAlgorithm(SimEqSystem eq, Context context,Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates an equation that is an algorithm."
::=
match eq
case SES_ALGORITHM(__) then
  (statements |> stmt =>
    algStatement(stmt, context, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  ;separator="\n")
end equationAlgorithm;


template algStmtTupleAssign(DAE.Statement stmt, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a tuple assigment algorithm statement."
::=
match stmt
case STMT_TUPLE_ASSIGN(exp=CALL(__)) then
  let &preExp = buffer "" /*BUFD*/
  let &afterExp = buffer "" /*BUFD*/
  let crefs = (expExpLst |> e => ExpressionDump.printExpStr(e) ;separator=", ")
  let marker = '(<%crefs%>) = <%ExpressionDump.printExpStr(exp)%>'
  let retStruct = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  //previous multi_array let rhsStr = 'boost::get<<%i1%>>(<%retStruct%>.data)'

  let lhsCrefs = (expExpLst |> cr hasindex i1 fromindex 0 =>
                    let rhsStr = 'boost::get<<%i1%>>(<%retStruct%>.data)'
                    writeLhsCref(cr, rhsStr, context, &afterExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
                  ;separator="\n";empty)
  <<
  // algStmtTupleAssign: preExp printout <%marker%>
  <%preExp%>
  // algStmtTupleAssign: writeLhsCref
  <%lhsCrefs%>
  // algStmtTupleAssign: afterExp
  <%afterExp%>
  >>

else error(sourceInfo(), 'algStmtTupleAssign failed')
end algStmtTupleAssign;



template error(builtin.SourceInfo srcInfo, String errMessage)
"Example source template error reporting template to be used together with the sourceInfo() magic function.
Usage: error(sourceInfo(), <<message>>) "
::=
let() = Tpl.addSourceTemplateError(errMessage, srcInfo)
<<
#error "<% Error.infoStr(srcInfo) %> <% errMessage %>"<%\n%>
>>
end error;

//for completeness; although the error() template above is preferable
template errorMsg(String errMessage)
"Example template error reporting template
 that is reporting only the error message without the usage of source infotmation."
::=
let() = Tpl.addTemplateError(errMessage)
<<
#error "<% errMessage %>"<%\n%>
>>
end errorMsg;




template contextIteratorName(Ident name, Context context)
  "Generates code for an iterator variable."
::=
 name
end contextIteratorName;




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


template writeLhsCref(Exp exp, String rhsStr, Context context, Text &preExp, Text &varDecls, SimCode simCode,
                      Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName, Boolean useFlatArrayNotation)
 "Generates code for writing a returnStructur to var."
::=
match exp
case ecr as CREF(componentRef=WILD(__)) then
  ''
case ecr as CREF(ty= t as DAE.T_ARRAY(__)) then
  let lhsStr = scalarLhsCref(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  <<
  <%lhsStr%>.assign(<%rhsStr%>);
  >>
case UNARY(exp = e as CREF(ty= t as DAE.T_ARRAY(__))) then
  let lhsStr = scalarLhsCref(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match context
  case SIMULATION_CONTEXT(__) then
    <<
    usub_<%expTypeShort(t)%>_array(&<%rhsStr%>);<%\n%>
    copy_<%expTypeShort(t)%>_array_data_mem(&<%rhsStr%>, &<%lhsStr%>);
    >>
  else
    '<%lhsStr%> = -<%rhsStr%>;'
case CREF(__) then
  let lhsStr = scalarLhsCref(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  <<
  <%lhsStr%> = <%rhsStr%> /*writeLhsCref1*/;
  >>
case UNARY(exp = e as CREF(__)) then
  let lhsStr = scalarLhsCref(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  <<
  <%lhsStr%> = -<%rhsStr%>;
  >>
case ARRAY(array = {}) then
  <<

  >>
case ARRAY(ty=T_ARRAY(ty=ty,dims=dims),array=expl) then
  let typeShort = expTypeFromExpShort(exp)
  let fcallsuf = match listLength(dims) case 1 then "" case i then '_<%i%>D'
  let body = (threadTuple(expl,dimsToAllIndexes(dims)) |>  (lhs,indxs) =>
                 let lhsstr = scalarLhsCref(lhs, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
                 let indxstr = (indxs |> i => '<%i%>' ;separator=",")
                 '<%lhsstr%> = <%typeShort%>_get<%fcallsuf%>(&<%rhsStr%>, <%indxstr%>);/*writeLhsCref2*/'
              ;separator="\n")
  <<
  <%body%>
  >>
case ASUB(__) then
  error(sourceInfo(), 'writeLhsCref UNHANDLED ASUB (should never be part of a lhs expression): <%ExpressionDump.printExpStr(exp)%> = <%rhsStr%>')
else
  error(sourceInfo(), 'writeLhsCref UNHANDLED: <%ExpressionDump.printExpStr(exp)%> = <%rhsStr%>')

end writeLhsCref;



template scalarLhsCref(Exp ecr, Context context, Text &preExp,Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
match ecr
case ecr as CREF(componentRef=CREF_IDENT(subscriptLst=subs)) then
  if crefNoSub(ecr.componentRef) then
    contextCref(ecr.componentRef, context,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  else
    daeExpCrefRhs(ecr, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
case ecr as CREF(componentRef=cr as CREF_QUAL(__)) then
    if crefIsScalar(cr, context) then
      contextCref(ecr.componentRef, context,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    else
      let arrName = contextCref(crefStripSubs(cr), context, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      <<
      <%arrName%>(<%threadDimSubList(crefDims(cr),crefSubs(cr),context,&preExp,&varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>)
      >>

case ecr as CREF(componentRef=CREF_QUAL(__)) then
    contextCref(ecr.componentRef, context,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
else
    "ONLY_IDENT_OR_QUAL_CREF_SUPPORTED_SLHS"
end scalarLhsCref;



template threadDimSubList(list<Dimension> dims, list<Subscript> subs, Context context, Text &preExp, Text &varDecls,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  "Do direct indexing since sizes are known during compile-time"
::=
  match subs
  case {} then error(sourceInfo(),"Empty dimensions in indexing cref?")

  case {sub as INDEX(__)} then
    match dims
    case {dim} then
       let estr = daeExp(sub.exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      '<%estr%>'
    else error(sourceInfo(),"Less subscripts that dimensions in indexing cref? That's odd!")

  case (sub as INDEX(__))::subrest then
    match dims
      case _::dimrest
      then

        let estr = daeExp(sub.exp, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        '<%estr%><%match subrest case {} then "" else ',<%threadDimSubList(dimrest, subrest, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'%>'
        /*'((<%estr%><%
          dimrest |> dim =>
          match dim
          case DIM_INTEGER(__) then ')*<%integer%>'
          case DIM_BOOLEAN(__) then '*2'
          case DIM_ENUM(__) then '*<%size%>'
          else error(sourceInfo(),"Non-constant dimension in simulation context")
        %>)<%match subrest case {} then "" else ',<%threadDimSubList(dimrest, subrest, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, useFlatArrayNotation)%>'%>'
        */
      else error(sourceInfo(),"Less subscripts that dimensions in indexing cref? That's odd!")
  else error(sourceInfo(),"Non-index subscript in indexing cref? That's odd!")
end threadDimSubList;


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


template expType(DAE.Type ty, Boolean isArray)
 "Generate type helper."
::=
  if isArray
  then 'expType_<%expTypeArray1(ty,0)%>_NOT_YET'
  else expTypeShort(ty)
end expType;


template expTypeArrayIf(DAE.Type ty)
 "Generate type helper."
::=
  expTypeFlag(ty, 6)
end expTypeArrayIf;

template expTypeArray1(DAE.Type ty, Integer dims) ::=
<<
SimArray<%dims%><<%expTypeShort(ty)%>>
>>
end expTypeArray1;


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
  else error(sourceInfo(), 'literalExpConst failed: <%printExpStr(lit)%>')
end literalExpConst;

template literalExpConstArrayVal(Exp lit)
::=
  match lit
  case ICONST(__) then integer
  case lit as BCONST(__) then if lit.bool then 1 else 0
  case RCONST(__) then real
  case ENUM_LITERAL(__) then index
  case lit as SHARED_LITERAL(__) then '_OMC_LIT<%lit.index%>'
  else error(sourceInfo(), 'literalExpConstArrayVal failed: <%printExpStr(lit)%>')
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

  else error(sourceInfo(), 'literalExpConst failed: <%printExpStr(lit)%>')
end literalExpConstImpl;







template handleEvent(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
match simCode
case SIMCODE(__) then
  <<
  >>
end handleEvent;

template checkConditions(list<ZeroCrossing> zeroCrossings,list<SimWhenClause> whenClauses,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
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


template getCondition(list<ZeroCrossing> zeroCrossings,list<SimWhenClause> whenClauses,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
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
          string error =string("Wrong condition index ") + boost::lexical_cast<string>(index);
         throw ModelicaSimulationError(EVENT_HANDLING,error);
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

template handleSystemEvents(list<ZeroCrossing> zeroCrossings,list<SimWhenClause> whenClauses,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=

  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
  bool <%lastIdentOfPath(modelInfo.name)%>::handleSystemEvents(bool* events)
  {
    _callType = IContinuous::DISCRETE;

    bool restart = true;
    bool state_vars_reinitialized = false;
    int iter = 0;

    while(restart && !(iter++ > 100))
    {
        bool st_vars_reinit = false;
        //iterate and handle all events inside the eventqueue
        restart = _event_handling->startEventIteration(st_vars_reinit);
        state_vars_reinitialized = state_vars_reinitialized || st_vars_reinit;

        saveAll();
    }

    if(iter>100 && restart ){
     string error = string("Number of event iteration steps exceeded at time: ") + boost::lexical_cast<string>(_simTime);
    throw ModelicaSimulationError(EVENT_HANDLING,error);
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
        /*error(sourceInfo(), 'Unknown relation: <%printExpStr(rel)%> for <%index1%>')*/
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

template expTypeFromExpFlag(Exp exp, Integer flag)
::=
  match exp
  case ICONST(__)        then match flag case 8 then "int" case 1 then "int" else "int"
  case RCONST(__)        then match flag case 1 then "double" else "double"
  case SCONST(__)        then if acceptMetaModelicaGrammar() then
                                (match flag case 1 then "metatype" else "modelica_metatype")
                              else
                                (match flag case 1 then "string" else "modelica_string")
  case BCONST(__)        then match flag case 1 then "bool" else "modelica_boolean"
  case ENUM_LITERAL(__)  then match flag case 8 then "int" case 1 then "int" else "int"
  case e as BINARY(__)
  case e as UNARY(__)
  case e as LBINARY(__)
  case e as LUNARY(__)
  case e as RELATION(__) then expTypeFromOpFlag(e.operator, flag)
  case IFEXP(__)         then expTypeFromExpFlag(expThen, flag)
  case CALL(attr=CALL_ATTR(__))          then expTypeFlag(attr.ty, flag)
  case c as ARRAY(__)
  case c as MATRIX(__)
  case c as RANGE(__)
  case c as CAST(__)
  case c as CREF(__)
  case c as CODE(__)     then expTypeFlag(c.ty, flag)
  case ASUB(__)          then expTypeFromExpFlag(exp, flag)
  case REDUCTION(__)     then expTypeFlag(typeof(exp), flag)
  case BOX(__)
  case CONS(__)
  case LIST(__)

  case META_TUPLE(__)
  case META_OPTION(__)
  case MATCHEXPRESSION(__)
  case METARECORDCALL(__)
  case BOX(__)           then match flag case 1 then "metatype" else "modelica_metatype"
  case c as UNBOX(__)    then expTypeFlag(c.ty, flag)
  case c as SHARED_LITERAL(__) then expTypeFromExpFlag(c.exp, flag)
  else ""
end expTypeFromExpFlag;

template expTypeFromOpFlag(Operator op, Integer flag)
 "Generate type helper."
::=
  match op
  case o as ADD(__)
  case o as SUB(__)
  case o as MUL(__)
  case o as DIV(__)
  case o as POW(__)

  case o as UMINUS(__)
  case o as UMINUS_ARR(__)
  case o as ADD_ARR(__)
  case o as SUB_ARR(__)
  case o as MUL_ARR(__)
  case o as DIV_ARR(__)
  case o as MUL_ARRAY_SCALAR(__)
  case o as ADD_ARRAY_SCALAR(__)
  case o as SUB_SCALAR_ARRAY(__)
  case o as MUL_SCALAR_PRODUCT(__)
  case o as MUL_MATRIX_PRODUCT(__)
  case o as DIV_ARRAY_SCALAR(__)
  case o as DIV_SCALAR_ARRAY(__)
  case o as POW_ARRAY_SCALAR(__)
  case o as POW_SCALAR_ARRAY(__)
  case o as POW_ARR(__)
  case o as POW_ARR2(__)
  case o as LESS(__)
  case o as LESSEQ(__)
  case o as GREATER(__)
  case o as GREATEREQ(__)
  case o as EQUAL(__)
  case o as NEQUAL(__) then
    expTypeFlag(o.ty, flag)
  case o as AND(__)
  case o as OR(__)
  case o as NOT(__) then
    match flag case 1 then "bool" else "modelica_boolean"
  else "expTypeFromOpFlag:ERROR"
end expTypeFromOpFlag;

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


template equationFunctions(list<SimEqSystem> allEquationsPlusWhen,list<SimWhenClause> whenClauses, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Boolean enableMeasureTime)
::=
  let equation_func_calls = (allEquationsPlusWhen |> eq =>
                    equation_function_create_single_func(eq, context/*BUFC*/, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,"evaluate","", stateDerVectorName, useFlatArrayNotation,enableMeasureTime)
                    ;separator="\n")
  <<
  <%equation_func_calls%>
  >>
end equationFunctions;

template createEvaluateAll( list<SimEqSystem> allEquationsPlusWhen,list<SimWhenClause> whenClauses, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation, Boolean createMeasureTime)
::=
  let &varDecls = buffer "" /*BUFD*/
  let className = lastIdentOfPathFromSimCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)

  let equation_all_func_calls = (List.partition(allEquationsPlusWhen, 100) |> eqs hasindex i0 =>
                                 createEvaluateWithSplit(i0, context, eqs, "evaluateAll", className, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)
                                 ;separator="\n")

  let reinit = (whenClauses |> when hasindex i0 =>
         genreinits(when, &varDecls,i0,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context, stateDerVectorName, useFlatArrayNotation)
    ;separator="\n";empty)

  <<
  bool <%className%>::evaluateAll(const UPDATETYPE command)
  {
    <%if createMeasureTime then generateMeasureTimeStartCode("measuredFunctionStartValues", "evaluateAll", "MEASURETIME_MODELFUNCTIONS") else ""%>
    bool state_var_reinitialized = false;

    <%varDecls%>
    /* Evaluate Equations*/
    <%equation_all_func_calls%>
    // Reinits
    <%reinit%>

    <%if createMeasureTime then generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "measureTimeFunctionsArray[1]", "evaluateAll", "MEASURETIME_MODELFUNCTIONS") else ""%>
    return state_var_reinitialized;
  }
  >>
end createEvaluateAll;

template createEvaluateConditions( list<SimEqSystem> allEquationsPlusWhen,list<SimWhenClause> whenClauses, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let className = lastIdentOfPathFromSimCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
  let &varDecls = buffer "" /*BUFD*/

  let &eqfuncs = buffer ""
  let equation_all_func_calls = (allEquationsPlusWhen |> eq  =>
                    equation_function_call(eq,  context, &varDecls /*BUFC*/, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,"evaluate")
                    ;separator="\n")


  let reinit = (whenClauses |> when hasindex i0 =>
         genreinits(when, &varDecls,i0,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,stateDerVectorName,useFlatArrayNotation)
    ;separator="\n";empty)

  <<
  bool <%className%>::evaluateConditions(const UPDATETYPE command)
  {
    return evaluateAll(command);
  }
  >>
end createEvaluateConditions;

template createEvaluate(list<list<SimEqSystem>> odeEquations,list<SimWhenClause> whenClauses, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Boolean createMeasureTime)
::=
  let className = lastIdentOfPathFromSimCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
  let &varDecls = buffer "" /*BUFD*/

  let equation_ode_func_calls = (List.partition(List.flatten(odeEquations), 100) |> eqs hasindex i0 =>
                                 createEvaluateWithSplit(i0, context, eqs, "evaluateODE", className, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)
                                 ;separator="\n")
  <<
  void <%className%>::evaluateODE(const UPDATETYPE command)
  {
    <%if createMeasureTime then generateMeasureTimeStartCode("measuredFunctionStartValues", "evaluateODE", "MEASURETIME_MODELFUNCTIONS") else ""%>
    <%varDecls%>
    /* Evaluate Equations*/
    <%equation_ode_func_calls%>
    <%if createMeasureTime then generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "measureTimeFunctionsArray[0]", "evaluateODE", "MEASURETIME_MODELFUNCTIONS") else ""%>
  }
  >>
end createEvaluate;

template createEvaluateZeroFuncs( list<SimEqSystem> equationsForZeroCrossings, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context)
::=
  let className = lastIdentOfPathFromSimCode(simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
  let &varDecls = buffer "" /*BUFD*/

  let &eqfuncs = buffer ""
  let equation_zero_func_calls = (List.partition(equationsForZeroCrossings, 100) |> eqs hasindex i0 =>
                    createEvaluateWithSplit(i0, context, eqs, "evaluateZeroFuncs", className, simCode, &extraFuncs , &extraFuncsDecl, extraFuncsNamespace)
                    ;separator="\n")

  <<
  void <%className%>::evaluateZeroFuncs(const UPDATETYPE command)
  {
    <%varDecls%>
    /* Evaluate Equations*/
    <%equation_zero_func_calls%>
  }
  >>
end createEvaluateZeroFuncs;

template createEvaluateWithSplit(Integer sectionIndex, Context context, list<SimEqSystem> sectionEquations, String functionName, String className, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
::=
  let &varDecls = buffer "" /*BUFD*/
  let equation_func_calls = (sectionEquations |> eq  =>
                    equation_function_call(eq, context, &varDecls /*BUFC*/, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, "evaluate")
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

template genreinits(SimWhenClause whenClauses, Text &varDecls, Integer int,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match whenClauses
    case SIM_WHEN_CLAUSE(__) then
      let &varDeclsCref = buffer "" /*BUFD*/
      let helpIf = (conditions |> e => ' || (<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context, varDeclsCref, stateDerVectorName, useFlatArrayNotation)%> && !_discrete_events->pre(<%cref1(e, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, context,varDeclsCref,stateDerVectorName,useFlatArrayNotation)%>))')
      let ifthen = functionWhenReinitStatementThen(reinits, &varDecls /*BUFP*/, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      let initial_assign = match initialCall
        case true then functionWhenReinitStatementThen(reinits, &varDecls /*BUFP*/, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        else '; // nothing to do'

      if reinits then
      <<
      //For whenclause index: <%int%>
      if(_initial)
      {
        <%initial_assign%>
      }
      else if (0<%helpIf%>) {
        <%ifthen%>
      }
      >>
end genreinits;

template functionWhenReinitStatementThen(list<WhenOperator> reinits, Text &varDecls /*BUFP*/, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates re-init statement for when equation."
::=
  let body = (reinits |> reinit =>
    match reinit
      case REINIT(__) then
        let &preExp = buffer "" /*BUFD*/
        let &varDeclsCref = buffer "" /*BUFD*/
        let val = daeExp(value, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        <<
        state_var_reinitialized = true;
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
        assertCommon(condition, message, contextSimulationDiscrete, &varDecls, info,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
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
end functionWhenReinitStatementThen;

template labeledDAE(list<String> labels, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
if Flags.isSet(Flags.WRITE_TO_BUFFER) then match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
<<


<%if labels then
<<
label_list_type <%lastIdentOfPath(modelInfo.name)%>::getLabels()
{
   label_list_type labels = tuple_list_of
   <%(labels |> label hasindex index0 => '(<%index0%>,&_<%label%>_1,&_<%label%>_2)') ;separator=" "%>;
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
          <<
            ,_<%matrixName%>jacobian(SparseMatrix(<%index_%>,<%indexColumn%>,<%sp_size_index%>))
            ,_<%matrixName%>jac_y(ublas::zero_vector<double>(<%index_%>))
            ,_<%matrixName%>jac_tmp(ublas::zero_vector<double>(<%tmpvarsSize%>))
            ,_<%matrixName%>jac_x(ublas::zero_vector<double>(<%index_%>))
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

let classname =  lastIdentOfPath(modelInfo.name)
match jacobianColumn
case {} then
  <<
  void <%classname%>Jacobian::calc<%matrixName%>JacobianColumn()
  {
  }

  void <%classname%>Jacobian::get<%matrixName%>Jacobian(SparseMatrix& matrix)
  {
  }
  >>
case _ then
  match colorList
  case {} then
  <<
  void <%classname%>Jacobian::calc<%matrixName%>JacobianColumn()
  {
  }

  void <%classname%>Jacobian::get<%matrixName%>Jacobian(SparseMatrix& matrix)
  {
  }
  >>
  case _ then

  let jacMats = (jacobianColumn |> (eqs,vars,indxColumn) =>
    functionJac(eqs, vars, indxColumn, matrixName, indexJacobian,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    ;separator="\n")
  let indexColumn = (jacobianColumn |> (eqs,vars,indxColumn) =>
    indxColumn
    ;separator="\n")


    let jacvals = ( sparsepattern |> (index,indexes) hasindex index0 =>
    let jaccol = ( indexes |> i_index hasindex index1 =>
        (match indexColumn case "1" then '_<%matrixName%>jacobian(<%index%>,0) = _<%matrixName%>jac_y(0);/*test1<%index0%>,<%index1%>*/'
           else '_<%matrixName%>jacobian(<%index%>,<%i_index%>) = _<%matrixName%>jac_y(<%i_index%>);/*test2<%index0%>,<%index1%>*/'
           )
          ;separator="\n" )
    '_<%matrixName%>jac_x(<%index0%>) = 1;
calc<%matrixName%>JacobianColumn();
_<%matrixName%>jac_x.clear();
<%jaccol%>'
      ;separator="\n")


  <<
  <%jacMats%>

  void <%classname%>Jacobian::get<%matrixName%>Jacobian(SparseMatrix& matrix)
  {

    <%jacvals%>
    matrix = _<%matrixName%>jacobian;
  }
  >>

/*
  (match indexColumn case "1" then ' _<%matrixName%>jacobian(<%crefWithoutIndexOperator(cref)%>$pDER<%matrixName%>$indexdiff,0) = _<%matrixName%>jac_y(0); //1 <%cref(cref)%>'
           else ' _<%matrixName%>jacobian(<%index0%>,<%crefWithoutIndexOperator(cref)%>$pDER<%matrixName%>$indexdiff) = _<%matrixName%>jac_y(<%crefWithoutIndexOperator(cref)%>$pDER<%matrixName%>$indexdiff);//2 <%cref(cref)%>'

*/
end generateJacobianMatrix;



template variableDefinitionsJacobians(list<JacobianMatrix> JacobianMatrixes,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates defines for jacobian vars."
::=

  let analyticVars = (JacobianMatrixes |> (jacColumn, seedVars, name, (_,_), _, _, jacIndex) =>
    let varsDef = variableDefinitionsJacobians2(jacIndex, jacColumn, seedVars, name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
    <<
    <%varsDef%>
    >>
    ;separator="\n";empty)

    <<
    /* Jacobian Variables */
    <%analyticVars%>
    >>
end variableDefinitionsJacobians;

template variableDefinitionsJacobians2(Integer indexJacobian, list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String name,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates Matrixes for Linear Model."
::=
  let seedVarsResult = (seedVars |> var hasindex index0 =>
    jacobianVarDefine(var, "jacobianVarsSeed", indexJacobian, index0, name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
    ;separator="\n";empty)
  let columnVarsResult = (jacobianColumn |> (_,vars,_) =>
      (vars |> var hasindex index0 => jacobianVarDefine(var, "jacobianVars", indexJacobian, index0,name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
      ;separator="\n";empty)
    ;separator="\n\n")

<<
<%seedVarsResult%>
<%columnVarsResult%>
>>
end variableDefinitionsJacobians2;


template jacobianVarDefine(SimVar simVar, String array, Integer indexJac, Integer index0,String matrixName,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
""
::=
match array
case "jacobianVars" then
  match simVar
  case SIMVAR(aliasvar=NOALIAS(),name=name) then
    match index
    case -1 then
      <<
      double& _<%crefToCStr(name,false)%>;
      >>
    case _ then
      <<
      double& _<%crefToCStr(name,false)%>;
      >>
    end match
  end match
case "jacobianVarsSeed" then
  match simVar
  case SIMVAR(aliasvar=NOALIAS()) then
  let tmp = System.tmpTick()
    <<
    double& _<%crefToCStr(name,false)%>;
    >>
  end match
end jacobianVarDefine;



template jacobiansVariableInit(list<JacobianMatrix> JacobianMatrixes,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates defines for jacobian vars."
::=

  let analyticVars = (JacobianMatrixes |> (jacColumn, seedVars, name, (_,_), _, _, jacIndex) =>
    let varsDef = jacobiansVariableInit2(jacIndex, jacColumn, seedVars, name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
    <<
    <%varsDef%>
    >>
    ;separator="\n";empty)

    <<
     <%analyticVars%>
    >>
end jacobiansVariableInit;

template jacobiansVariableInit2(Integer indexJacobian, list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String name,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates Matrixes for Linear Model."
::=
  let seedVarsResult = (seedVars |> var hasindex index0 =>
    jacobianVarInit(var, "jacobianVarsSeed", indexJacobian, index0, name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
    ;separator="\n";empty)
  let columnVarsResult = (jacobianColumn |> (_,vars,_) =>
      (vars |> var hasindex index0 => jacobianVarInit(var, "jacobianVars", indexJacobian, index0,name,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
      ;separator="\n";empty)
    ;separator="\n")

<<
<%seedVarsResult%>
<%columnVarsResult%>
>>
end jacobiansVariableInit2;


template jacobianVarInit(SimVar simVar, String array, Integer indexJac, Integer index0,String matrixName,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
""
::=
match array
case "jacobianVars" then
  match simVar
  case SIMVAR(aliasvar=NOALIAS(),name=name) then
    match index
    case -1 then
      <<
       ,_<%crefToCStr(name,false)%>(_<%matrixName%>jac_tmp(<%index0%>))
      >>
    case _ then
      <<
      ,_<%crefToCStr(name,false)%>(_<%matrixName%>jac_y(<%index%>))
      >>
    end match
  end match
case "jacobianVarsSeed" then
  match simVar
  case SIMVAR(aliasvar=NOALIAS()) then
  let tmp = System.tmpTick()
    <<
    ,_<%crefToCStr(name,false)%>( _<%matrixName%>jac_x(<%index0%>))
    >>
  end match
end jacobianVarInit;

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
    let rec = daeExp(exp, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    <<

    <%preExp%>
    <% varLst |> var as TYPES_VAR(__) =>
      match var.ty
      case T_ARRAY(__) then
        copyArrayData(var.ty, '<%rec%>.<%var.name%>', appendStringCref(var.name,cr), context)
      else
        let varPart = contextCref(appendStringCref(var.name,cr),context,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        '<%varPart%> = <%rec%>.<%var.name%>;'
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
  let type = expTypeArray(ty)
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


template algStmtAssert(DAE.Statement stmt, Context context, Text &varDecls,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates an assert algorithm statement."
::=
match stmt
case STMT_ASSERT(source=SOURCE(info=info)) then
  assertCommon(cond, msg, context, &varDecls, info,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
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
  let arrayType = expTypeArray(type_)


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
    <%type%> <%iterName%>;
    BOOST_FOREACH(<%iterName%>, <%evar%>) {
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
  let type = expTypeArray(ty)
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
    let typeStr = expTypeArray(ty)
    let slice = if crefSubs(cr) then daeExpCrefIndexSpec(crefSubs(cr), context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    if slice then
      'ArraySlice<<%typeStr%>>(<%contextArrayCref(cr, context)%>, <%slice%>)'
    else
      '<%contextArrayCref(cr, context)%>'
end algStmtAssignArrCref;


template indexSpecFromCref(ComponentRef cr, Context context, Text &preExp /*BUFP*/,
                  Text &varDecls /*BUFP*/,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Helper to algStmtAssignArr. Not used.
  Currently works only for CREF_IDENT." ::=
match cr
case CREF_IDENT(subscriptLst=subs as (_ :: _)) then
  daeExpCrefRhsIndexSpec(subs, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
end indexSpecFromCref;


template functionInitDelay(DelayedExpression delayed,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
   let &preExp = buffer "" /*BUFD*/
  let delay_id = (match delayed case DELAYED_EXPRESSIONS(__) then (delayedExps |> (id, (e, d, delayMax)) =>
     '<%id%>';separator=","))
  let delay_max = (match delayed case DELAYED_EXPRESSIONS(__) then (delayedExps |> (id, (e, d, delayMax)) =>
      let delayExpMax = daeExp(delayMax, contextSimulationNonDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     '<%delayExpMax%>';separator=","))
  if delay_id then
   <<
    //init delay expressions
     <%varDecls%>
    <%preExp%>
    vector<double> delay_max;
    vector<unsigned int > delay_ids;
    delay_ids+= <%delay_id%>;
    delay_max+=<%delay_max%>;
    intDelay(delay_ids,delay_max);

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
        const double* real_vars = _sim_vars->getRealVarsVector();
        memcpy(z,real_vars,<%numRealvars(modelInfo)%>);
      }



      void <%lastIdentOfPath(name)%>::setReal(const double* z)
      {
         _sim_vars->setRealVarsVector(z);
      }



      void <%lastIdentOfPath(name)%>::getInteger(int* z)
      {
        const int* int_vars = _sim_vars->getIntVarsVector();
        memcpy(z,int_vars,<%numIntvars(modelInfo)%>);
      }



      void <%lastIdentOfPath(name)%>::getBoolean(bool* z)
      {
        const bool* bool_vars = _sim_vars->getBoolVarsVector();
        memcpy(z,bool_vars,<%numBoolvars(modelInfo)%>);
      }



      void <%lastIdentOfPath(name)%>::getString(string* z)
      {
        <%stringFuncCalls%>
      }

      void <%lastIdentOfPath(name)%>::setInteger(const int* z)
      {
         _sim_vars->setIntVarsVector(z);
      }

      void <%lastIdentOfPath(name)%>::setBoolean(const bool* z)
      {
        _sim_vars->setBoolVarsVector(z);
      }

      void <%lastIdentOfPath(name)%>::setString(const string* z)
      {
        <%setStringVariables%>
      }
      >>
  end match
/*  else
    match modelInfo
      case MODELINFO(vars=SIMVARS(__)) then
      <<
      void <%lastIdentOfPath(name)%>::getReal(double* z)
      {
         throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"getReal is not implemented yet");
      }

      void <%lastIdentOfPath(name)%>::getInteger(int* z)
      {
         throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"getInteger is not implemented yet");
      }

      void <%lastIdentOfPath(name)%>::getBoolean(bool* z)
      {
         throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"getBoolean is not implemented yet");
      }

      void <%lastIdentOfPath(name)%>::getString(string* z)
      {
         throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"getString is not implemented yet");
      }

      void <%lastIdentOfPath(name)%>::setReal(const double* z)
      {
         throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"setReal is not implemented yet");
      }

      void <%lastIdentOfPath(name)%>::setInteger(const int* z)
      {
         throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"setInteger is not implemented yet");
      }

      void <%lastIdentOfPath(name)%>::setBoolean(const bool* z)
      {
         throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"setBoolean is not implemented yet");
      }

      void <%lastIdentOfPath(name)%>::setString(const string* z)
      {
         throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"setString is not implemented yet");
      }
      >>
  */
  /*
  <%System.tmpTickReset(0)%>
  <%vars.stringAlgVars |> var => giveVariablesDefault(var, System.tmpTick()) ;separator="\n"%>
  <%vars.stringParamVars |> var => giveVariablesDefault(var, System.tmpTick()) ;separator="\n"%>
  <%vars.stringAliasVars |> var => giveVariablesDefault(var, System.tmpTick()) ;separator="\n"%>
  */
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

template crefWithoutIndexOperator(ComponentRef cr)
 "Generates C equivalent name for component reference."
::=
   match cr
    case CREF_IDENT(ident = "xloc") then crefStr(cr)
    case CREF_IDENT(ident = "time") then "_simTime"
    case WILD(__) then ''
    else crefToCStrWithoutIndexOperator(cr)
end crefWithoutIndexOperator;

template crefToCStrWithoutIndexOperator(ComponentRef cr)
 "Helper function to cref."
::=
  match cr
  case CREF_IDENT(__) then '<%unquoteIdentifier(ident)%><%subscriptsToCStrWithoutIndexOperator(subscriptLst)%>'
  case CREF_QUAL(__) then '<%unquoteIdentifier(ident)%><%subscriptsToCStrWithoutIndexOperator(subscriptLst)%>$P<%crefToCStrWithoutIndexOperator(componentRef)%>'
  case WILD(__) then ''
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStrWithoutIndexOperator;

template subscriptsToCStrWithoutIndexOperator(list<Subscript> subscripts)
::=
  if subscripts then
    '$lB<%subscripts |> s => subscriptToCStrWithoutIndexOperator(s) ;separator="$c"%>$rB'
end subscriptsToCStrWithoutIndexOperator;

template subscriptToCStrWithoutIndexOperator(Subscript subscript)
::=
  match subscript
  case SLICE(exp=ICONST(integer=i)) then i
  case WHOLEDIM(__) then "WHOLEDIM"
  case INDEX(__) then
   match exp
    case ICONST(integer=i) then i
    case ENUM_LITERAL(index=i) then i
      end match
  else "UNKNOWN_SUBSCRIPT"
end subscriptToCStrWithoutIndexOperator;

template daeExpTsub(Exp inExp, Context context, Text &preExp,
                    Text &varDecls,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for an tsub expression."
::=
  match inExp
  case TSUB(ix=1) then
    let tuple_val = daeExp(exp, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     'boost::get<0>(<%tuple_val%>.data)'
  //case TSUB(exp=CALL(attr=CALL_ATTR(ty=T_TUPLE(types=tys)))) then
  case TSUB(exp=CALL(path=p,attr=CALL_ATTR(ty=tys as T_TUPLE(__)))) then
    //let v = tempDecl(expTypeArrayIf(listGet(tys,ix)), &varDecls)
    //let additionalOutputs = List.restOrEmpty(tys) |> ty hasindex i1 fromindex 2 => if intEq(i1,ix) then ', &<%v%>' else ", NULL"
     let retType = '<%underscorePath(p)%>RetType /* undefined */'
    let retVar = tempDecl(retType, &varDecls)
     let res = daeExpCallTuple(exp,retVar, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let &preExp += '<%res%>;<%\n%>'
    'boost::get<<%intAdd(-1,ix)%>>(<%retVar%>.data)'

  case TSUB(__) then
    error(sourceInfo(), '<%printExpStr(inExp)%>: TSUB only makes sense if the subscripted expression is a function call of tuple type')
end daeExpTsub;

template daeExpCallTuple(Exp call , Text additionalOutputs/* arguments 2..N */, Context context, Text &preExp, Text &varDecls,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match call
  case exp as CALL(attr=attr as CALL_ATTR(__)) then


    let argStr = if boolOr(attr.builtin,isParallelFunctionContext(context))
                   then (expLst |> exp => '<%daeExp(exp, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
                 else ((expLst |> exp => (daeExp(exp, context, preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation));separator=", "))
    if attr.isFunctionPointerCall
      then
        let typeCast1 = generateTypeCast(attr.ty, expLst, true,preExp, varDecls,context, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        let typeCast2 = generateTypeCast(attr.ty, expLst, false, preExp, varDecls,context,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        let name = '_<%underscorePath(path)%>'
        let func = '(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%name%>), 1)))'
        let closure = '(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%name%>), 2)))'
        let argStrPointer = ('threadData, <%closure%>' + (expLst |> exp => (", " + daeExp(exp, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation))))
        //'<%name%>(<%argStr%><%additionalOutputs%>)'
        '/*Closure?*/<%closure%> ? (<%typeCast1%> <%func%>) (<%argStrPointer%><%additionalOutputs%>) : (<%typeCast2%> <%func%>) (<%argStr%><%additionalOutputs%>)'
      else
          '_functions-><%underscorePath(path)%>(<%argStr%>,<%additionalOutputs%>)'
end daeExpCallTuple;

template generateTypeCast(Type ty, list<DAE.Exp> es, Boolean isClosure, Text &preExp /*BUFP*/,
                     Text &varDecls, Context context,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let ret = (match ty
    case T_NORETCALL(__) then "void"
    else "modelica_metatype")
  let inputs = es |> e => ', <%expTypeFromExpArrayIf(e,context, &preExp ,&varDecls ,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  let outputs = match ty
    case T_TUPLE(types=_::tys) then (tys |> t => ', <%expTypeArrayIf(t)%>')
  '(<%ret%>(*)(threadData_t*<%if isClosure then ", modelica_metatype"%><%inputs%><%outputs%>))'
end generateTypeCast;

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

annotation(__OpenModelica_Interface="backend");
end CodegenCpp;
