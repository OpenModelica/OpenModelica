package CodegenCpp

import interface SimCodeTV;
import CodegenUtil.*;
// SECTION: SIMULATION TARGET, ROOT TEMPLATE




template translateModel(SimCode simCode, Boolean useFlatArrayNotation)
::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  let target  = simulationCodeTarget()
   let()= textFile(simulationMainFile(simCode), 'OMCpp<%fileNamePrefix%>Main.cpp')
  let()= textFile(simulationHeaderFile(simCode, "", "", true, false), 'OMCpp<%fileNamePrefix%>.h')
  let()= textFile(simulationCppFile(simCode,false), 'OMCpp<%fileNamePrefix%>.cpp')
  let()= textFile(simulationFunctionsHeaderFile(simCode,modelInfo.functions,literals,false), 'OMCpp<%fileNamePrefix%>Functions.h')
  let()= textFile(simulationFunctionsFile(simCode, modelInfo.functions,literals,externalFunctionIncludes, false), 'OMCpp<%fileNamePrefix%>Functions.cpp')
  let()= textFile(simulationTypesHeaderFile(simCode,modelInfo.functions,literals, useFlatArrayNotation), 'OMCpp<%fileNamePrefix%>Types.h')
  let()= textFile(simulationMakefile(target,simCode,"","","","",false), '<%fileNamePrefix%>.makefile')
  let()= textFile(simulationInitHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>Initialize.h')
  let()= textFile(simulationInitCppFile(simCode,false),'OMCpp<%fileNamePrefix%>Initialize.cpp')
  let()= textFile(simulationJacobianHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>Jacobian.h')
  let()= textFile(simulationJacobianCppFile(simCode,false),'OMCpp<%fileNamePrefix%>Jacobian.cpp')
  let()= textFile(simulationStateSelectionCppFile(simCode, false), 'OMCpp<%fileNamePrefix%>StateSelection.cpp')
  let()= textFile(simulationStateSelectionHeaderFile(simCode),'OMCpp<%fileNamePrefix%>StateSelection.h')
  let()= textFile(simulationExtensionHeaderFile(simCode),'OMCpp<%fileNamePrefix%>Extension.h')
  let()= textFile(simulationExtensionCppFile(simCode),'OMCpp<%fileNamePrefix%>Extension.cpp')
  let()= textFile(simulationWriteOutputHeaderFile(simCode),'OMCpp<%fileNamePrefix%>WriteOutput.h')
  let()= textFile(simulationWriteOutputCppFile(simCode, false),'OMCpp<%fileNamePrefix%>WriteOutput.cpp')
  let()= textFile(simulationFactoryFile(simCode),'OMCpp<%fileNamePrefix%>FactoryExport.cpp')
  let()= textFile(simulationMainRunScript(simCode), '<%fileNamePrefix%><%simulationMainRunScriptSuffix(simCode)%>')
  let jac =  (jacobianMatrixes |> (mat, _, _, _, _, _, _) =>
          (mat |> (eqs,_,_) =>  algloopfiles(eqs,simCode,contextAlgloopJacobian,false) ;separator="")
         ;separator="")
  let alg = algloopfiles(listAppend(allEquations,initialEquations),simCode,contextAlgloop,false)
  let()= textFile(algloopMainfile(listAppend(allEquations,initialEquations),simCode,contextAlgloop), 'OMCpp<%fileNamePrefix%>AlgLoopMain.cpp')
  let()= textFile(calcHelperMainfile(simCode), 'OMCpp<%fileNamePrefix%>CalcHelperMain.cpp')
 ""
  // empty result of the top-level template .., only side effects
end translateModel;


template translateFunctions(FunctionCode functionCode)
 "Generates C code and Makefile for compiling and calling Modelica and
  MetaModelica functions."
::=
  match functionCode
  case FUNCTIONCODE(__) then

  "" // Return empty result since result written to files directly
end translateFunctions;

template simulationHeaderFile(SimCode simCode, String additionalIncludes, String additionalProtectedMembers, Boolean useDefaultMemberVariables, Boolean useFlatArrayNotation)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(__) then
  <<
   <%generateHeaderIncludeString(simCode)%>
   <%additionalIncludes%>
   <%generateClassDeclarationCode(simCode, additionalProtectedMembers, useDefaultMemberVariables, useFlatArrayNotation)%>


   >>
end simulationHeaderFile;


template simulationInitHeaderFile(SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(vars=SIMVARS(__)),fileNamePrefix=fileNamePrefix) then
let initeqs = generateEquationMemberFuncDecls(initialEquations,"initEquation")
  match modelInfo
  case modelInfo as MODELINFO(vars=SIMVARS(__)) then
  <<
   #pragma once
   #include "OMCpp<%fileNamePrefix%>.h"

  /*****************************************************************************
  *
  * Simulation code to initialize the Modelica system
  *
  *****************************************************************************/
  class <%lastIdentOfPath(modelInfo.name)%>Initialize: virtual public  <%lastIdentOfPath(modelInfo.name)%>
  {
     public:
    <%lastIdentOfPath(modelInfo.name)%>Initialize(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData);
    virtual ~<%lastIdentOfPath(modelInfo.name)%>Initialize();
    virtual bool initial();
    virtual void setInitial(bool);
    virtual void initialize();
    virtual  void initEquations();
   private:
    <%initeqs%>
    void initializeAlgVars();
    void initializeDiscreteAlgVars();
    void initializeIntAlgVars();
    void initializeBoolAlgVars();
    void initializeAliasVars();
    void initializeIntAliasVars();
    void initializeBoolAliasVars();

    <%List.partition(vars.paramVars, 100) |> ls hasindex idx => 'void initializeParameterVars_<%idx%>();';separator="\n"%>
    <%List.partition(vars.intParamVars, 100) |> ls hasindex idx => 'void initializeIntParameterVars_<%idx%>();';separator="\n"%>
    <%List.partition(vars.boolParamVars, 100) |> ls hasindex idx => 'void initializeBoolParameterVars_<%idx%>();';separator="\n"%>


    void initializeParameterVars();
    void initializeIntParameterVars();
    void initializeBoolParameterVars();
    void initializeStateVars();
    void initializeDerVars();
  };
  >>
  end match
end simulationInitHeaderFile;



template simulationJacobianHeaderFile(SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  <<
   #pragma once
    #include "OMCpp<%fileNamePrefix%>.h"




    <% (jacobianMatrixes |> (mat, _, _, _, _, _, _) hasindex index0 =>
       (mat |> (eqs,_,_) =>  algloopfilesInclude(eqs,simCode) ;separator="\n")
     ;separator="")
    %>
  /*****************************************************************************
  *
  * Simulation code to initialize the Modelica system
  *
  *****************************************************************************/
  class <%lastIdentOfPath(modelInfo.name)%>Jacobian: virtual public  <%lastIdentOfPath(modelInfo.name)%>
  {


    <% (jacobianMatrixes |> (mat, _, _, _, _, _, _) hasindex index0 =>
       (mat |> (eqs,_,_) =>  generatefriendAlgloops(eqs,simCode) ;separator="\n")
     ;separator="")
    %>
     public:
    <%lastIdentOfPath(modelInfo.name)%>Jacobian(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData);
    virtual ~<%lastIdentOfPath(modelInfo.name)%>Jacobian();
   protected:
    void initialize();
    <%
    let jacobianfunctions = (jacobianMatrixes |> (_,_, name, _, _, _, _) hasindex index0 =>
    <<
     void initialAnalytic<%name%>Jacobian();
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

       int  _<%name%>_sizeCols;
         int  _<%name%>_sizeRows;
       int* _<%name%>_sparsePattern_leadindex;
       int  _<%name%>_sizeof_sparsePattern_leadindex;
         int* _<%name%>_sparsePattern_index;
       int  _<%name%>_sizeof_sparsePattern_index;
         int* _<%name%>_sparsePattern_colorCols;
       int  _<%name%>_sizeof_sparsePattern_colorCols;
       int  _<%name%>_sparsePattern_maxColors;


    >>
    ;separator="\n";empty)
   <<
     <%jacobianvars%>
   >>
   %>
   //workaround for jacobian variables
   <%variableDefinitionsJacobians(jacobianMatrixes,simCode)%>



    <% (jacobianMatrixes |> (mat, _, _, _, _, _, _) hasindex index0 =>
       (mat |> (eqs,_,_) =>  generateAlgloopsolverVariables(eqs,simCode) ;separator="\n")
     ;separator="")
    %>

  /*testmaessig aus der Cruntime*/

  <%functionAnalyticJacobiansHeader(jacobianMatrixes, modelNamePrefix(simCode))%>

  };
 >>
end simulationJacobianHeaderFile;


//template initialAnalyticJacobiansHeader(list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String matrixname, list<tuple<DAE.ComponentRef,list<DAE.ComponentRef>>> sparsepattern, list<list<DAE.ComponentRef>> colorList, Integer maxColor, String modelNamePrefix)
/*"template initialAnalyticJacobians
  This template generates source code for functions that initialize the sparse-pattern for a single jacobian.
  This is a helper of template functionAnalyticJacobians"
*/
  //::=
/*match seedVars
case {} then
<<
>>
case _ then
  match sparsepattern
  case {(_,{})} then
    <<
  //sinnloser Kommentar
    >>
  case _ then
  match matrixname
  case "A" then
      let &eachCrefParts = buffer ""

      let indexElems = ( sparsepattern |> (cref,indexes) hasindex index0 =>
        let &eachCrefParts += mkSparseFunctionHeader(matrixname, index0, cref, indexes, modelNamePrefix)
        <<
    initializeColumnsColoredJacobian<%matrixname%>_<%index0%>();
        >>


      ;separator="\n")
      let colorArray = (colorList |> (indexes) hasindex index0 =>
        let colorCol = ( indexes |> i_index =>
        '_<%matrixname%>_sparsePattern_colorCols[<%cref(i_index, false)%>$pDER<%matrixname%>$indexdiff] = <%intAdd(index0,1)%>; '
        ;separator="\n")
      '<%colorCol%>'
      ;separator="\n")
      let indexColumn = (jacobianColumn |> (eqs,vars,indxColumn) => indxColumn;separator="\n")
      let index_ = listLength(seedVars)
      let sp_size_index =  lengthListElements(splitTuple212List(sparsepattern))
      let sizeleadindex = listLength(sparsepattern)


      <<
    public:
      <%eachCrefParts%>
      void initializeColoredJacobian<%matrixname%>();

      int  _<%matrixname%>_sizeCols;
      int  _<%matrixname%>_sizeRows;


      //_<%matrixname%>_sparsePattern_leadindex = new int[];
        //_<%matrixname%>_sparsePattern_index = new int[];
        //_<%matrixname%>_sparsePattern_colorCols = new int[<%index_%>];


      int  _<%matrixname%>_sparsePattern_leadindex[<%sizeleadindex%>];

    int  _<%matrixname%>_sizeof_sparsePattern_leadindex;

      int  _<%matrixname%>_sparsePattern_index[<%sp_size_index%>];

    int  _<%matrixname%>_sizeof_sparsePattern_index;

      int  _<%matrixname%>_sparsePattern_colorCols[<%index_%>];

    int  _<%matrixname%>_sizeof_sparsePattern_colorCols;

    int  _<%matrixname%>_sparsePattern_maxColors;


      >>
   end match
   end match
end match*/
//end initialAnalyticJacobiansHeader;


template simulationStateSelectionHeaderFile(SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  <<
   #pragma once
    #include "OMCpp<%fileNamePrefix%>.h"
  /*****************************************************************************
  *
  * Simulation code to initialize the Modelica system
  *
  *****************************************************************************/
  class <%lastIdentOfPath(modelInfo.name)%>StateSelection: virtual public  <%lastIdentOfPath(modelInfo.name)%>
  {
     public:
    <%lastIdentOfPath(modelInfo.name)%>StateSelection(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData);
    virtual ~<%lastIdentOfPath(modelInfo.name)%>StateSelection();
    int getDimStateSets() const;
    int getDimStates(unsigned int index) const;
    int getDimCanditates(unsigned int index) const ;
    int getDimDummyStates(unsigned int index) const ;
    void getStates(unsigned int index,double* z);
    void setStates(unsigned int index,const double* z);
    void getStateCanditates(unsigned int index,double* z);
    bool getAMatrix(unsigned int index,DynArrayDim2<int> & A) ;
    void setAMatrix(unsigned int index ,DynArrayDim2<int>& A);
     bool getAMatrix(unsigned int index,DynArrayDim1<int> & A) ;
    void setAMatrix(unsigned int index,DynArrayDim1<int>& A);
    protected:
     void  initialize();
  };
 >>
end simulationStateSelectionHeaderFile;






template simulationWriteOutputHeaderFile(SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__),simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
  let n = numProtectedParamVars(modelInfo)
  let outputtype = match   settings.outputFormat case "mat" then "MatFileWriter" else "TextFileWriter"
  let numparams = match   settings.outputFormat case "csv" then "1" else n
  <<
   #pragma once
    #include "OMCpp<%fileNamePrefix%>.h"
    typedef HistoryImpl<<%outputtype%>,<%numProtectedAlgvars(modelInfo)%>+<%numProtectedAliasvars(modelInfo)%>+<%numStatevars(modelInfo)%>,<%numDerivativevars(modelInfo)%>,0,<%numparams%>> HistoryImplType;



  /*****************************************************************************
  *
  * Simulation code to write simulation file
  *
  *****************************************************************************/


  class <%lastIdentOfPath(modelInfo.name)%>WriteOutput: virtual public  <%lastIdentOfPath(modelInfo.name)%>
  {
  public:
       <%lastIdentOfPath(modelInfo.name)%>WriteOutput(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData);
       virtual ~<%lastIdentOfPath(modelInfo.name)%>WriteOutput();
       /// Output routine (to be called by the solver after every successful integration step)
       virtual void writeOutput(const IWriteOutput::OUTPUT command = IWriteOutput::UNDEF_OUTPUT);
       virtual IHistory* getHistory();

  protected:
       void initialize();

  private:
       void writeAlgVarsValues(HistoryImplType::value_type_v *v);
       void writeDiscreteAlgVarsValues(HistoryImplType::value_type_v *v);
       void writeIntAlgVarsValues(HistoryImplType::value_type_v *v);
       void writeBoolAlgVarsValues(HistoryImplType::value_type_v *v);
       void writeAliasVarsValues(HistoryImplType::value_type_v *v);
       void writeIntAliasVarsValues(HistoryImplType::value_type_v *v);
       void writeBoolAliasVarsValues(HistoryImplType::value_type_v *v);
       void writeStateValues(HistoryImplType::value_type_v *v, HistoryImplType::value_type_dv *v2);

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


template simulationExtensionHeaderFile(SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  <<
   #pragma once
  #include "OMCpp<%fileNamePrefix%>WriteOutput.h"
  #include "OMCpp<%fileNamePrefix%>Initialize.h"
   #include "OMCpp<%fileNamePrefix%>Jacobian.h"
   #include "OMCpp<%fileNamePrefix%>StateSelection.h"
  /*****************************************************************************
  *
  * Simulation code
  *
  *****************************************************************************/
  class <%lastIdentOfPath(modelInfo.name)%>Extension: public ISystemInitialization, public IMixedSystem,public IWriteOutput, public IStateSelection, public <%lastIdentOfPath(modelInfo.name)%>WriteOutput, public <%lastIdentOfPath(modelInfo.name)%>Initialize, public <%lastIdentOfPath(modelInfo.name)%>Jacobian,public <%lastIdentOfPath(modelInfo.name)%>StateSelection
  {
     public:
    <%lastIdentOfPath(modelInfo.name)%>Extension(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData);
    virtual ~<%lastIdentOfPath(modelInfo.name)%>Extension();
    ///Intialization mehtods from ISystemInitialization
    virtual bool initial();
    virtual void setInitial(bool);
    virtual void initialize();
    virtual  void initEquations();
    ///Write simulation results mehtods from IWriteuutput
    /// Output routine (to be called by the solver after every successful integration step)
    virtual void writeOutput(const IWriteOutput::OUTPUT command = IWriteOutput::UNDEF_OUTPUT);
    virtual IHistory* getHistory();
     /// Provide Jacobian
    virtual void getJacobian(SparseMatrix& matrix);
    virtual void getStateSetJacobian(unsigned int index,SparseMatrix& matrix);
   /// Called to handle all  events occured at same time
    virtual bool handleSystemEvents(bool* events);
    //Saves all variables before an event is handled, is needed for the pre, edge and change operator
    virtual void saveAll();
    //StateSelction mehtods
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
    virtual void getA_sparsePattern_leadindex(int* A_sparsePattern_leadindex, int size);
  virtual int  getA_sizeof_sparsePattern_leadindex();
    virtual void getA_sparsePattern_index(int* A_sparsePattern_index, int size);
  virtual int  getA_sizeof_sparsePattern_index();
    virtual void getA_sparsePattern_colorCols(int* A_sparsePattern_colorCols, int size);
  virtual int  getA_sizeof_sparsePattern_colorCols();
    virtual int  getA_sparsePattern_maxColors();





  };
 >>
end simulationExtensionHeaderFile;



template simulationFactoryFile(SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  <<
   /* #include <Core/Modelica.h>
   #include <Core/ModelicaDefine.h>
   #include "OMCpp<%fileNamePrefix%>Extension.h" */



  using boost::extensions::factory;
   BOOST_EXTENSION_TYPE_MAP_FUNCTION {
    types.get<std::map<std::string, factory<IMixedSystem,IGlobalSettings*,boost::shared_ptr<IAlgLoopSolverFactory>,boost::shared_ptr<ISimData> > > >()
    ["<%lastIdentOfPath(modelInfo.name)%>"].set<<%lastIdentOfPath(modelInfo.name)%>Extension>();
    }
 >>
end simulationFactoryFile;



template simulationInitCppFile(SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
   /* #include <Core/Modelica.h>
   #include <Core/ModelicaDefine.h>
   #include "OMCpp<%fileNamePrefix%>Initialize.h" */

   <%algloopfilesInclude(listAppend(allEquations,initialEquations),simCode)%>

   <%lastIdentOfPath(modelInfo.name)%>Initialize::<%lastIdentOfPath(modelInfo.name)%>Initialize(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData)
   : <%lastIdentOfPath(modelInfo.name)%>(globalSettings,nonlinsolverfactory,simData)
   {
   }


   <%lastIdentOfPath(modelInfo.name)%>Initialize::~<%lastIdentOfPath(modelInfo.name)%>Initialize()
    {

    }


   <%GetIntialStatus(simCode)%>
   <%SetIntialStatus(simCode)%>
    <%init(simCode, useFlatArrayNotation)%>
 >>
end simulationInitCppFile;

template simulationJacobianCppFile(SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
   /* #include <Core/Modelica.h>
   #include <Core/ModelicaDefine.h>
   #include "OMCpp<%fileNamePrefix%>Jacobian.h" */
   <%lastIdentOfPath(modelInfo.name)%>Jacobian::<%lastIdentOfPath(modelInfo.name)%>Jacobian(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData)
   : <%lastIdentOfPath(modelInfo.name)%>(globalSettings,nonlinsolverfactory,simData)
   ,_A_sparsePattern_leadindex(NULL)
   ,_A_sparsePattern_index(NULL)
   ,_A_sparsePattern_colorCols(NULL)
   {
   }


   <%lastIdentOfPath(modelInfo.name)%>Jacobian::~<%lastIdentOfPath(modelInfo.name)%>Jacobian()
    {
    if(_A_sparsePattern_leadindex)
      delete []  _A_sparsePattern_leadindex;
    if(_A_sparsePattern_index)
      delete []  _A_sparsePattern_index;
    if(_A_sparsePattern_colorCols)
      delete []  _A_sparsePattern_colorCols;

    }
    <%functionAnalyticJacobians(jacobianMatrixes,simCode,useFlatArrayNotation)%>


    //testmaessig aus der cruntime
    /* Jacobians */

    <%functionAnalyticJacobians2(jacobianMatrixes, lastIdentOfPath(modelInfo.name))%>

    <%\n%>



 >>
end simulationJacobianCppFile;

template simulationStateSelectionCppFile(SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
   /* #include <Core/Modelica.h>
   #include <Core/ModelicaDefine.h>
   #include "OMCpp<%fileNamePrefix%>StateSelection.h" */
   <%lastIdentOfPath(modelInfo.name)%>StateSelection::<%lastIdentOfPath(modelInfo.name)%>StateSelection(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData)
   : <%lastIdentOfPath(modelInfo.name)%>(globalSettings,nonlinsolverfactory,simData)
   {
   }


   <%lastIdentOfPath(modelInfo.name)%>StateSelection::~<%lastIdentOfPath(modelInfo.name)%>StateSelection()
    {

    }
   <%functionDimStateSets(stateSets, simCode)%>
   <%functionStateSets(stateSets, simCode,useFlatArrayNotation)%>
 >>
end simulationStateSelectionCppFile;






template simulationWriteOutputCppFile(SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
   /* #include <Core/Modelica.h>
   #include <Core/ModelicaDefine.h>
   #include "OMCpp<%fileNamePrefix%>WriteOutput.h" */

   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::<%lastIdentOfPath(modelInfo.name)%>WriteOutput(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData)
   : <%lastIdentOfPath(modelInfo.name)%>(globalSettings,nonlinsolverfactory,simData)
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
         map<unsigned int,string> var_ouputs_idx;
       <%outputIndices(modelInfo)%>
       _historyImpl->setOutputs(var_ouputs_idx);
       _historyImpl->clear();
    }
     <%writeoutput(simCode,useFlatArrayNotation)%>

 >>
end simulationWriteOutputCppFile;




template simulationExtensionCppFile(SimCode simCode)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let classname = lastIdentOfPath(modelInfo.name)



  <<
   /* #include <Core/Modelica.h>
   #include <Core/ModelicaDefine.h>
   #include "OMCpp<%fileNamePrefix%>Extension.h" */
   <%lastIdentOfPath(modelInfo.name)%>Extension::<%lastIdentOfPath(modelInfo.name)%>Extension(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData)
   : <%lastIdentOfPath(modelInfo.name)%>(globalSettings,nonlinsolverfactory,simData)
   , <%lastIdentOfPath(modelInfo.name)%>WriteOutput(globalSettings,nonlinsolverfactory,simData)
   , <%lastIdentOfPath(modelInfo.name)%>Initialize(globalSettings,nonlinsolverfactory,simData)
   , <%lastIdentOfPath(modelInfo.name)%>Jacobian(globalSettings,nonlinsolverfactory,simData)
   , <%lastIdentOfPath(modelInfo.name)%>StateSelection(globalSettings,nonlinsolverfactory,simData)


   {
   }
   <%lastIdentOfPath(modelInfo.name)%>Extension::~<%lastIdentOfPath(modelInfo.name)%>Extension()
    {

    }



    bool <%lastIdentOfPath(modelInfo.name)%>Extension::initial()
    {
      return <%lastIdentOfPath(modelInfo.name)%>Initialize::initial();
    }
    void <%lastIdentOfPath(modelInfo.name)%>Extension::setInitial(bool value)
    {
      <%lastIdentOfPath(modelInfo.name)%>Initialize::setInitial(value);
    }


    void <%lastIdentOfPath(modelInfo.name)%>Extension::initialize()
    {
      <%lastIdentOfPath(modelInfo.name)%>WriteOutput::initialize();
      <%lastIdentOfPath(modelInfo.name)%>Initialize::initialize();
      <%lastIdentOfPath(modelInfo.name)%>Jacobian::initialize();


    <%lastIdentOfPath(modelInfo.name)%>Jacobian::initializeColoredJacobianA();

    }

  void <%lastIdentOfPath(modelInfo.name)%>Extension::getJacobian(SparseMatrix& matrix)
  {
          getAJacobian(matrix);

  }
  void <%lastIdentOfPath(modelInfo.name)%>Extension::getStateSetJacobian(unsigned int index,SparseMatrix& matrix)
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
        throw std::invalid_argument("Not supported statset index");
      }
  }
  bool <%lastIdentOfPath(modelInfo.name)%>Extension::handleSystemEvents(bool* events)
  {
      return <%lastIdentOfPath(modelInfo.name)%>::handleSystemEvents(events);
  }

  void <%lastIdentOfPath(modelInfo.name)%>Extension::saveAll()
  {
      return <%lastIdentOfPath(modelInfo.name)%>::saveAll();
  }



    void <%lastIdentOfPath(modelInfo.name)%>Extension::initEquations()
    {
      <%lastIdentOfPath(modelInfo.name)%>Initialize::initEquations();
    }


    void <%lastIdentOfPath(modelInfo.name)%>Extension::writeOutput(const IWriteOutput::OUTPUT command )
    {
        <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeOutput(command);
    }

     IHistory* <%lastIdentOfPath(modelInfo.name)%>Extension::getHistory( )
    {
      return    <%lastIdentOfPath(modelInfo.name)%>WriteOutput::getHistory();
    }
   int <%lastIdentOfPath(modelInfo.name)%>Extension::getDimStateSets() const
   {
     return    <%lastIdentOfPath(modelInfo.name)%>StateSelection::getDimStateSets();
   }
   int <%lastIdentOfPath(modelInfo.name)%>Extension::getDimStates(unsigned int index) const
   {
     return    <%lastIdentOfPath(modelInfo.name)%>StateSelection::getDimStates(index);
   }
   int <%lastIdentOfPath(modelInfo.name)%>Extension::getDimCanditates(unsigned int index) const
   {
     return    <%lastIdentOfPath(modelInfo.name)%>StateSelection::getDimCanditates(index);
   }
   int <%lastIdentOfPath(modelInfo.name)%>Extension::getDimDummyStates(unsigned int index) const
   {
     return    <%lastIdentOfPath(modelInfo.name)%>StateSelection::getDimDummyStates(index);
   }



   void <%lastIdentOfPath(modelInfo.name)%>Extension::getStates(unsigned int index,double* z)
   {
      <%lastIdentOfPath(modelInfo.name)%>StateSelection::getStates(index,z);
   }


   void <%lastIdentOfPath(modelInfo.name)%>Extension::setStates(unsigned int index,const double* z)
   {
      <%lastIdentOfPath(modelInfo.name)%>StateSelection::setStates(index,z);
   }

   void <%lastIdentOfPath(modelInfo.name)%>Extension::getStateCanditates(unsigned int index,double* z)
   {
      <%lastIdentOfPath(modelInfo.name)%>StateSelection::getStateCanditates(index,z);
   }

   bool <%lastIdentOfPath(modelInfo.name)%>Extension::getAMatrix(unsigned int index,DynArrayDim2<int> & A)
   {
      return <%lastIdentOfPath(modelInfo.name)%>StateSelection::getAMatrix(index,A);
   }

   void <%lastIdentOfPath(modelInfo.name)%>Extension::setAMatrix(unsigned int index,DynArrayDim2<int> & A)
   {
      <%lastIdentOfPath(modelInfo.name)%>StateSelection::setAMatrix(index,A);
   }
   bool <%lastIdentOfPath(modelInfo.name)%>Extension::getAMatrix(unsigned int index,DynArrayDim1<int> & A)
   {
      return <%lastIdentOfPath(modelInfo.name)%>StateSelection::getAMatrix(index,A);
   }

   void <%lastIdentOfPath(modelInfo.name)%>Extension::setAMatrix(unsigned int index,DynArrayDim1<int> & A)
   {
      <%lastIdentOfPath(modelInfo.name)%>StateSelection::setAMatrix(index,A);
   }

   /*needed for colored jacobians*/

   void <%lastIdentOfPath(modelInfo.name)%>Extension::getA_sparsePattern_leadindex(int* A_sparsePattern_leadindex, int size)
   {
    memcpy(A_sparsePattern_leadindex, _A_sparsePattern_leadindex, size * sizeof(int));
   }

   void <%lastIdentOfPath(modelInfo.name)%>Extension::getA_sparsePattern_index(int* A_sparsePattern_index, int size)
   {
    memcpy(A_sparsePattern_index, _A_sparsePattern_index, size * sizeof(int));
   }

   void <%lastIdentOfPath(modelInfo.name)%>Extension::getA_sparsePattern_colorCols(int* A_sparsePattern_colorCols, int size)
   {
    memcpy(A_sparsePattern_colorCols, _A_sparsePattern_colorCols, size * sizeof(int));
   }

   int <%lastIdentOfPath(modelInfo.name)%>Extension::getA_sparsePattern_maxColors()
   {
    return _A_sparsePattern_maxColors;
   }

   /*********************************************************************************************/

   int <%lastIdentOfPath(modelInfo.name)%>Extension::getA_sizeof_sparsePattern_colorCols()
   {
    return _A_sizeof_sparsePattern_colorCols;
   }

   int <%lastIdentOfPath(modelInfo.name)%>Extension::getA_sizeof_sparsePattern_leadindex()
   {
    return _A_sizeof_sparsePattern_leadindex ;
   }

   int <%lastIdentOfPath(modelInfo.name)%>Extension::getA_sizeof_sparsePattern_index()
   {
    return _A_sizeof_sparsePattern_index;
   }
 >>
end simulationExtensionCppFile;


 template functionDimStateSets(list<StateSet> stateSets,SimCode simCode)
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
        throw std::invalid_argument("Not supported statset index");
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
        throw std::invalid_argument("Not supported statset index");
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
        throw std::invalid_argument("Not supported statset index");
      }

    }
  >>
 end functionDimStateSets;


template createAssignArray(DAE.ComponentRef sourceOrTargetArrayCref, String sourceArrayName, String targetArrayName, SimCode simCode, Boolean useFlatArrayNotationSource, Boolean useFlatArrayNotationTarget)
::=
  match SimCodeUtil.cref2simvar(sourceOrTargetArrayCref, simCode)
    case v as SIMVAR(numArrayElement=num) then
      if boolOr(useFlatArrayNotationSource,useFlatArrayNotationTarget) then (
        <<
        <%HpcOmMemory.getSubscriptListOfArrayCref(sourceOrTargetArrayCref, num) |> ai => '<%targetArrayName%><%subscriptsToCStr(ai,useFlatArrayNotationTarget)%> = <%sourceArrayName%><%subscriptsToCStr(ai,useFlatArrayNotationSource)%>;';separator="\n"%>
        >>
      )
      else (
        '<%targetArrayName%>.assign(<%sourceArrayName%>);'
      )
end createAssignArray;

template functionStateSets(list<StateSet> stateSets,SimCode simCode, Boolean useFlatArrayNotation)
  "Generates functions in simulation file to initialize the stateset data."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  let getAMatrix1 = (stateSets |> set hasindex i1 fromindex 0 => (match set
           case set as SES_STATESET(__) then
           let arrayname1 = arraycref(crA, useFlatArrayNotation)
           match nStates  case 1 then
             'case <%i1%>:
               <%createAssignArray(crA, arrayname1, "A", simCode, useFlatArrayNotation, false)%>
               return true;
            '
            else ""
         ) ;separator="\n")

  let getAMatrix2 = (stateSets |> set hasindex i1 fromindex 0 => (match set
           case set as SES_STATESET(__) then
           let arrayname1 = arraycref(crA, useFlatArrayNotation)
           match nStates  case 1 then "" else
             'case <%i1%>:
               <%createAssignArray(crA, arrayname1, "A", simCode, useFlatArrayNotation, false)%>
               return true;
            '

         ) ;separator="\n")

   let setAMatrix1 = (stateSets |> set hasindex i1 fromindex 0 => (match set
           case set as SES_STATESET(__) then
           let arrayname1 = arraycref(crA, useFlatArrayNotation)
           match nStates  case 1 then
             'case <%i1%>:
               <%createAssignArray(crA, "A", arrayname1, simCode, false, useFlatArrayNotation)%>
               break;
            '
            else ""
         ) ;separator="\n")

  let setAMatrix2 = (stateSets |> set hasindex i1 fromindex 0 => (match set
           case set as SES_STATESET(__) then
           let arrayname1 = arraycref(crA, useFlatArrayNotation)
           match nStates  case 1 then "" else
             'case <%i1%>:
               <%createAssignArray(crA, "A", arrayname1, simCode, false, useFlatArrayNotation)%>
               break;
            '

         ) ;separator="\n")



  let classname =  lastIdentOfPath(modelInfo.name)
  match stateSets
  case {} then
     <<
     void  <%classname%>StateSelection::getStates(unsigned int index,double* z)
     {


     }
     void  <%classname%>StateSelection::setStates(unsigned int index,const double* z)
     {

     }
     void  <%classname%>StateSelection::getStateCanditates(unsigned int index,double* z)
     {

     }
     bool  <%classname%>StateSelection::getAMatrix(unsigned int index,DynArrayDim2<int> & A)
     {

        return false;
     }
      bool  <%classname%>StateSelection::getAMatrix(unsigned int index,DynArrayDim1<int> & A)
     {

       return false;
     }
     void  <%classname%>StateSelection::setAMatrix(unsigned int index,DynArrayDim2<int>& A)
     {

     }
      void  <%classname%>StateSelection::setAMatrix(unsigned int index,DynArrayDim1<int>& A)
     {

     }
     void <%classname%>StateSelection::initialize()
     {

     }
     >>
 else
    let &varDeclsCref = buffer "" /*BUFD*/
  <<



     void  <%classname%>StateSelection::getStates(unsigned int index,double* z)
      {
       switch (index)
       {
         <%(stateSets |> set hasindex i1 fromindex 0 => (match set
         case set as SES_STATESET(__) then
         <<
           case <%i1%>:
             <%(states |> s hasindex i2 fromindex 0 => 'z[<%i2%>]=<%cref1(s,simCode,contextOther,varDeclsCref, useFlatArrayNotation)%>;' ;separator="\n")%>
             break;
        >>
       )
       ;separator="\n")
       %>
        default:
          throw std::invalid_argument("Not supported statset index");
       }

     }

       void  <%classname%>StateSelection::setStates(unsigned int index,const double* z)
       {
        switch (index)
        {
          <%(stateSets |> set hasindex i1 fromindex 0 => (match set
           case set as SES_STATESET(__) then
          <<
            case <%i1%>:
             <%(states |> s hasindex i2 fromindex 0 => '<%cref1(s,simCode,contextOther,varDeclsCref, useFlatArrayNotation)%> = z[<%i2%>];' ;separator="\n")%>
             break;
         >>
        )
        ;separator="\n")
        %>
        default:
          throw std::invalid_argument("Not supported statset index");
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
             <%(statescandidates |> cstate hasindex i2 fromindex 0 => 'z[<%i2%>]=<%cref1(cstate,simCode,contextOther,varDeclsCref,useFlatArrayNotation)%>;' ;separator="\n")%>
             break;
         >>
        )
        ;separator="\n")
        %>
        default:
          throw std::invalid_argument("Not supported statset index");
        }

       }


       bool  <%classname%>StateSelection::getAMatrix(unsigned int index,DynArrayDim2<int> & A)
        {
        <%match getAMatrix2 case "" then 'return false;' else
        <<
         switch (index)
          {
            <%getAMatrix2%>
           default:
            throw std::invalid_argument("Not supported statset index");
          }
       >>
       %>
       }
       bool  <%classname%>StateSelection::getAMatrix(unsigned int index,DynArrayDim1<int> & A)
        {
       <%match getAMatrix1 case "" then 'return false;' else
        <<
        switch (index)
        {
           <%getAMatrix1%>
            default:
            throw std::invalid_argument("Not supported statset index");
          }
       >>
       %>
       }

       void  <%classname%>StateSelection::setAMatrix(unsigned int index,DynArrayDim2<int> & A)
        {
        <%match setAMatrix2 case "" then '' else
        <<
         switch (index)
          {
            <%setAMatrix2%>
           default:
            throw std::invalid_argument("Not supported statset index");
        }
       >>
       %>
       }
       void  <%classname%>StateSelection::setAMatrix(unsigned int index,DynArrayDim1<int> & A)
        {
       <%match setAMatrix1 case "" then '' else
        <<
        switch (index)
        {
           <%setAMatrix1%>
            default:
            throw std::invalid_argument("Not supported statset index");
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


template simulationMainRunScript(SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(makefileParams=MAKEFILE_PARAMS(__)) then
(match makefileParams.platform
case  "linux64"
case  "linux32" then
(match simCode
case SIMCODE(modelInfo=MODELINFO(__),makefileParams=MAKEFILE_PARAMS(__),simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
let start = settings.startTime
let end = settings.stopTime
let stepsize = settings.stepSize
let intervals = settings.numberOfIntervals
let tol = settings.tolerance
let solver = settings.method
let moLib =  makefileParams.compileDir
let home = makefileParams.omhome
<<
#!/bin/sh
exec ./OMCpp<%fileNamePrefix%>Main -s <%start%> -e <%end%> -f <%stepsize%> -v <%intervals%> -y <%tol%> -i <%solver%> -r <%simulationLibDir(simulationCodeTarget(),simCode)%> -m <%moLib%> -R <%simulationResults(getRunningTestsuite(),simCode)%> -o <%settings.outputFormat%> $*
>>
end match)
case  "win32"
case  "win64" then
match simCode
case SIMCODE(modelInfo=MODELINFO(__),makefileParams=MAKEFILE_PARAMS(__),simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
let start = settings.startTime
let end = settings.stopTime
let stepsize = settings.stepSize
let intervals = settings.numberOfIntervals
let tol = settings.tolerance
let solver = settings.method
let moLib =  makefileParams.compileDir
let home = makefileParams.omhome
let libFolder =simulationLibDir(simulationCodeTarget(),simCode)
<<
@echo off
REM ::export PATH=<%libFolder%>:$PATH REPLACE C: with /C/
SET PATH=<%makefileParams.omhome%>/bin;<%libFolder%>;%PATH%
<%moLib%>/OMCpp<%fileNamePrefix%>Main.exe -s <%start%> -e <%end%> -f <%stepsize%> -v <%intervals%> -y <%tol%> -i <%solver%> -r <%simulationLibDir(simulationCodeTarget(),simCode)%> -m <%moLib%> -R <%simulationResults(getRunningTestsuite(),simCode)%> -o <%settings.outputFormat%>
>>
end match)
end simulationMainRunScript;


template simulationLibDir(String target, SimCode simCode)
 "Generates code for header file for simulation target."
::=
match target
case "msvc" then
match simCode
case SIMCODE(makefileParams=MAKEFILE_PARAMS(__)) then
'<%makefileParams.omhome%>/lib/omc/cpp/msvc'
end match
else
match simCode
case SIMCODE(makefileParams=MAKEFILE_PARAMS(__)) then
'<%makefileParams.omhome%>/lib/omc/cpp/'
end match
end simulationLibDir;


template simulationResults(Boolean test, SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__),makefileParams=MAKEFILE_PARAMS(__),simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
let results = if test then ""  else '<%makefileParams.compileDir%>/'
<<
<%results%><%fileNamePrefix%>_res.<%settings.outputFormat%>
>>
end simulationResults;



template simulationMainRunScriptSuffix(SimCode simCode)
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

template simulationMainFile(SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__)) then
  <<

  #ifndef BOOST_ALL_DYN_LINK
    #define BOOST_ALL_DYN_LINK
  #endif
  #include <Core/Modelica.h>
  #include <Core/ModelicaDefine.h>
  #include <SimCoreFactory/Policies/FactoryConfig.h>
  #include <SimController/ISimController.h>
  <%
    match(getConfigString(PROFILING_LEVEL))
        case("none") then ''
        case("all_perf") then '#include "Core/Utils/extension/measure_time_papi.hpp"'
        else '#include "Core/Utils/extension/measure_time_rdtsc.hpp"'
    end match
  %>
  #if defined(_MSC_VER) || defined(__MINGW32__)
  #include <tchar.h>
  int _tmain(int argc, const _TCHAR* argv[])
  #else
  int main(int argc, const char* argv[])
  #endif
  {
      <%
      match(getConfigString(PROFILING_LEVEL))
          case("none") then ''
          case("all_perf") then 'MeasureTimePAPI::initialize();'
          else 'MeasureTimeRDTSC::initialize();'
      end match
      %>
      try
      {
            boost::shared_ptr<OMCFactory>  _factory =  boost::shared_ptr<OMCFactory>(new OMCFactory());
            //SimController to start simulation

            std::pair<boost::shared_ptr<ISimController>,SimSettings> simulation =  _factory->createSimulation(argc,argv);

            //create Modelica system
            std::pair<boost::shared_ptr<IMixedSystem>,boost::shared_ptr<ISimData> > system = simulation.first->LoadSystem("OMCpp<%fileNamePrefix%><%makefileParams.dllext%>","<%lastIdentOfPath(modelInfo.name)%>");

            simulation.first->Start(system.first,simulation.second,"<%lastIdentOfPath(modelInfo.name)%>");

            <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
                <<
                MeasureTime::getInstance()->writeToJson();
                //MeasureTimeRDTSC::deinitialize();
                >>
            %>
            return 0;

      }
      catch(std::exception& ex)
      {
          std::string error = ex.what();
          std::cerr << "Simulation stopped: "<<  error ;
          return 1;
      }
  }
>>
end simulationMainFile;


template calcHelperMainfile(SimCode simCode)
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

    #include <Core/Modelica.h>
    #include <Core/ModelicaDefine.h>

    #include "OMCpp<%fileNamePrefix%>Types.h"
    #include "OMCpp<%fileNamePrefix%>Extension.h"
    #include "OMCpp<%fileNamePrefix%>Extension.cpp"
    #include "OMCpp<%fileNamePrefix%>FactoryExport.cpp"
    #include "OMCpp<%fileNamePrefix%>Functions.h"
    #include "OMCpp<%fileNamePrefix%>Functions.cpp"
    #include "OMCpp<%fileNamePrefix%>Initialize.h"
    #include "OMCpp<%fileNamePrefix%>Initialize.cpp"
    #include "OMCpp<%fileNamePrefix%>Jacobian.h"
    #include "OMCpp<%fileNamePrefix%>Jacobian.cpp"
    #include "OMCpp<%fileNamePrefix%>StateSelection.h"
    #include "OMCpp<%fileNamePrefix%>StateSelection.cpp"
    #include "OMCpp<%fileNamePrefix%>WriteOutput.h"
    #include "OMCpp<%fileNamePrefix%>WriteOutput.cpp"
    >>
end calcHelperMainfile;

template algloopHeaderFile(SimCode simCode,SimEqSystem eq, Context context, Boolean useFlatArrayNotation)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(__) then
  <<
   <%generateAlgloopHeaderInlcudeString(simCode,context)%>
   <%generateAlgloopClassDeclarationCode(simCode,eq,context,useFlatArrayNotation)%>

   >>
end algloopHeaderFile;

template simulationFunctionsFile(SimCode simCode, list<Function> functions, list<Exp> literals,list<String> includes, Boolean useFlatArrayNotation)
 "Generates the content of the Cpp file for functions in the simulation case."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  <<
  /* #include <Core/Modelica.h>
  #include <Core/ModelicaDefine.h>
  #include "OMCpp<%fileNamePrefix%>Functions.h" */

  <%externalFunctionIncludes(includes)%>

   Functions::Functions(double& simTime,double* z,double* zDot,bool& initial,bool& terminate)
   :_simTime(simTime)
   ,__z(z)
   ,__zDot(zDot)
   ,_initial(initial)
   ,_terminate(terminate)
   {
     <%literals |> literal hasindex i0 fromindex 0 => literalExpConstImpl(literal,i0) ; separator="\n";empty%>
   initialize();
   }

   Functions::~Functions()
   {
   }
    void Functions::Assert(bool cond,string msg)
    {
        if(!cond)
            throw std::runtime_error(msg);
    }

  void Functions::initialize()
  {
    <%initParams1(functions, simCode)%>
  }

    <%functionBodies(functions,simCode,useFlatArrayNotation)%>
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

template simulationTypesHeaderFile(SimCode simCode, list<Function> functions, list<Exp> literals, Boolean useFlatArrayNotation)
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
  //external c functions
  extern "C" {
      <%externfunctionHeaderDefinition(functions)%>
  }
  <%functionHeaderBodies1(functions,simCode,useFlatArrayNotation)%>
  >>

end simulationTypesHeaderFile;

template simulationFunctionsHeaderFile(SimCode simCode, list<Function> functions, list<Exp> literals, Boolean useFlatArrayNotation)
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
  //external c functions
  extern "C" {
      <%externfunctionHeaderDefinition(functions)%>
  }
  #include "OMCpp<%fileNamePrefix%>Types.h"

  class Functions
     {
      public:
        Functions(double& simTime,double* z,double* zDot,bool& initial,bool& terminate);
       ~Functions();
       //Modelica functions
       <%functionHeaderBodies2(functions,simCode, useFlatArrayNotation)%>

       void Assert(bool cond,string msg);

       //Literals
        <%literals |> literal hasindex i0 fromindex 0 => literalExpConst(literal,i0) ; separator="\n";empty%>
     private:
     void initialize();

       //Function return variables
       <%functionHeaderBodies3(functions,simCode)%>
       double& _simTime;
       bool& _terminate;
       bool& _initial;
       double* __z;
       double* __zDot;

     // function paramter variables
     <%allocateParams1(functions, simCode)%>

     };
  >>

end simulationFunctionsHeaderFile;

template allocateParams1( list<Function> functions, SimCode simCode)
::=
let params = (functions |> fn => allocateParams2(fn, simCode) ;separator="\n")
<<
<%params%>
>>
end allocateParams1;

template allocateParams2(Function fn, SimCode simCode)
::=
match fn
case FUNCTION(__) then
let params = (variableDeclarations |> var hasindex i1 fromindex 1 =>
      paramInit(var, "", i1,simCode) ; separator="" /* increase the counter! */)
<<
<%params%>
>>
end allocateParams2;

template paramInit(Variable var, String outStruct, Integer i,SimCode simCode)
::=
let &varDecls = buffer "" /*BUFD*/
let &varInits = buffer "" /*BUFD*/
let dump  = match var
case VARIABLE(__) then
  match kind
    case PARAM(__) then  varInit(var, "", i, &varDecls /*BUFD*/, &varInits /*BUFC*/,simCode, false)
    //case CONST(__) then  varInit(var, "", i, &varDecls /*BUFD*/, &varInits /*BUFC*/,simCode, false)
  end match
end match
<<
<%varDecls%>
>>
end paramInit;

template initParams1( list<Function> functions, SimCode simCode)
::=
let params = (functions |> fn => initParams2(fn, simCode) ;separator="\n")
<<
<%params%>
>>
end initParams1;

template initParams2(Function fn, SimCode simCode)
::=
match fn
case FUNCTION(__) then
let params = (variableDeclarations |> var hasindex i1 fromindex 1 =>
      paramInit2(var, "", i1,simCode) ; separator="" /* increase the counter! */)
<<
<%params%>
>>
end initParams2;

template paramInit2(Variable var, String outStruct, Integer i,SimCode simCode)
::=
let &varDecls = buffer "" /*BUFD*/
let &varInits = buffer "" /*BUFD*/
let dump  = match var
case VARIABLE(__) then
  match kind
    case PARAM(__) then  varInit(var, "", i, &varDecls /*BUFD*/, &varInits /*BUFC*/,simCode, false)
    //case CONST(__) then  varInit(var, "", i, &varDecls /*BUFD*/, &varInits /*BUFC*/,simCode, false)
  end match
end match
<<
<%varInits%>
>>
end paramInit2;



template notparamInit(Variable var, String outStruct, Integer i, Text &varDecls /*BUFP*/, Text &varInits /*BUFP*/, SimCode simCode, Boolean useFlatArrayNotation)
::=
let dump  = match var
case VARIABLE(__) then
  match kind
    case VARIABLE(__) then  varInit(var, "", i, &varDecls /*BUFD*/, &varInits /*BUFC*/,simCode, true)
    case DISCRETE(__) then  varInit(var, "", i, &varDecls /*BUFD*/, &varInits /*BUFC*/,simCode, true)
  end match
end match
""
end notparamInit;



template simulationMainDLLib(SimCode simCode)
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
case "linux64"
case "linux32" then
<<
"-ldl"
>>
else
""
end simulationMainDLLib2;


template simulationMakefile(String target, SimCode simCode, String additionalLinkerFlags_GCC,
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

  # Simulations use -O3 by default
  SIM_OR_DYNLOAD_OPT_LEVEL=
  MODELICAUSERCFLAGS=
  CXX=cl
  EXEEXT=.exe
  DLLEXT=.dll
  include <%makefileParams.omhome%>/include/omc/cpp/ModelicaConfig.inc
  # /Od - Optimization disabled
  # /EHa enable C++ EH (w/ SEH exceptions)
  # /fp:except - consider floating-point exceptions when generating code
  # /arch:SSE2 - enable use of instructions available with SSE2 enabled CPUs
  # /I - Include Directories
  # /DNOMINMAX - Define NOMINMAX (does what it says)
  # /TP - Use C++ Compiler
  !IF "$(PCH_FILE)" == ""
  CFLAGS=  $(SYSTEM_CFLAGS) /I"<%makefileParams.omhome%>/include/omc/cpp/Core/" /I"<%makefileParams.omhome%>/include/omc/cpp/" /I. <%makefileParams.includes%>  /I"$(BOOST_INCLUDE)" /I"$(SUITESPARSE_INCLUDE)" /DNOMINMAX /TP /DNO_INTERACTIVE_DEPENDENCY <%additionalCFlags_MSVC%>
  !ELSE
  CFLAGS=  $(SYSTEM_CFLAGS) /I"<%makefileParams.omhome%>/include/omc/cpp/Core/" /I"<%makefileParams.omhome%>/include/omc/cpp/" /I. <%makefileParams.includes%>  /I"$(BOOST_INCLUDE)" /I"$(SUITESPARSE_INCLUDE)" /DNOMINMAX /TP /DNO_INTERACTIVE_DEPENDENCY  /Fp<%makefileParams.omhome%>/include/omc/cpp/Core/$(PCH_FILE)  /YuCore/$(H_FILE) <%additionalCFlags_MSVC%>
  !ENDIF
  CPPFLAGS =
  # /ZI enable Edit and Continue debug info
  CDFLAGS = /ZI

  # /MD - link with MSVCRT.LIB
  # /link - [linker options and libraries]
  # /LIBPATH: - Directories where libs can be found
  #LDFLAGS=/MDd   /link /DLL /NOENTRY /LIBPATH:"<%makefileParams.omhome%>/lib/omc/cpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)" OMCppSystem.lib OMCppMath.lib
  #LDSYTEMFLAGS=/MD /Debug  /link /DLL /NOENTRY /LIBPATH:"<%makefileParams.omhome%>/lib/omc/cpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)" OMCppSystem.lib OMCppModelicaUtilities.lib  OMCppMath.lib   OMCppOMCFactory.lib
  LDSYTEMFLAGS=  /link /DLL /NOENTRY /LIBPATH:"<%makefileParams.omhome%>/lib/omc/cpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)" OMCppSystem.lib OMCppModelicaUtilities.lib  OMCppMath.lib   OMCppOMCFactory.lib <%timeMeasureLink%>
  #LDMAINFLAGS=/MD /Debug  /link /LIBPATH:"<%makefileParams.omhome%>/lib/omc/cpp/msvc" OMCppOMCFactory.lib  /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)"
  LDMAINFLAGS=/link /LIBPATH:"<%makefileParams.omhome%>/lib/omc/cpp/msvc" OMCppOMCFactory.lib <%timeMeasureLink%> /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)"
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
  MAINOBJ=OMCpp<%fileNamePrefix%>Main$(EXEEXT)
  SYSTEMOBJ=OMCpp<%fileNamePrefix%>$(DLLEXT)

  CALCHELPERMAINFILE=OMCpp<%fileNamePrefix%>CalcHelperMain.cpp
  ALGLOOPMAINFILE=OMCpp<%fileNamePrefix%>AlgLoopMain.cpp
  GENERATEDFILES=$(MAINFILE) $(FUNCTIONFILE) $(ALGLOOPMAINFILE)

  $(MODELICA_SYSTEM_LIB)$(DLLEXT):
  <%\t%>$(CXX)  /Fe$(SYSTEMOBJ) $(SYSTEMFILE) $(CALCHELPERMAINFILE) $(ALGLOOPMAINFILE) $(CFLAGS) $(LDSYTEMFLAGS) <%dirExtra%> <%libsPos1%> <%libsPos2%>
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
            let _extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then ""
            let extraCflags = '<%_extraCflags%><% if Flags.isSet(Flags.GEN_DEBUG_SYMBOLS) then " -g"%>'
            let omHome = makefileParams.omhome
            let &timeMeasureLink +=
                match(getConfigString(PROFILING_LEVEL))
                    case("all_perf") then ' -Wl,-rpath,"<%omHome%>/lib/omc/cpp" -lOMCppExtensionUtilities -lOMCppExtensionUtilities_papi -lpapi'
                    else ' -Wl,-rpath,"<%omHome%>/lib/omc/cpp" -lOMCppExtensionUtilities'
                end match
            let CC = if (compileForMPI) then "mpicc" else '<%makefileParams.ccompiler%>'
            let CXX = if (compileForMPI) then "mpicxx" else '<%makefileParams.cxxcompiler%>'
            let MPIEnvVars = if (compileForMPI)
                then 'OMPI_MPICC=<%makefileParams.ccompiler%> <%\n%>OMPI_MPICXX=<%makefileParams.cxxcompiler%>' else ""
            <<
            # Makefile generated by OpenModelica
            OMHOME=<%makefileParams.omhome%>
            include <%makefileParams.omhome%>/include/omc/cpp/ModelicaConfig.inc
            include <%makefileParams.omhome%>/include/omc/cpp/ModelicaLibraryConfig.inc
            # Simulations use -O0 by default
            SIM_OR_DYNLOAD_OPT_LEVEL=-O0
            CC=<%CC%>
            CXX=<%CXX%>
            <%MPIEnvVars%>
            LINK=<%makefileParams.linker%>
            EXEEXT=<%makefileParams.exeext%>
            DLLEXT=<%makefileParams.dllext%>
            CFLAGS_BASED_ON_INIT_FILE=<%extraCflags%>
            CFLAGS=$(CFLAGS_BASED_ON_INIT_FILE) -Winvalid-pch $(SYSTEM_CFLAGS) -I"<%makefileParams.omhome%>/include/omc/cpp/Core" -I"<%makefileParams.omhome%>/include/omc/cpp/"   -I. <%makefileParams.includes%> -I"$(BOOST_INCLUDE)" -I"$(SUITESPARSE_INCLUDE)" <%makefileParams.includes ; separator=" "%> <%match sopt case SOME(s as SIMULATION_SETTINGS(__)) then s.cflags %> <%additionalCFlags_GCC%>
            LDSYTEMFLAGS=-L"<%makefileParams.omhome%>/lib/omc/cpp" $(BASE_LIB)  -lOMCppOMCFactory -lOMCppSystem -lOMCppModelicaUtilities -lOMCppMath <%timeMeasureLink%> -L"$(BOOST_LIBS)"  $(BOOST_SYSTEM_LIB) $(BOOST_FILESYSTEM_LIB) $(BOOST_PROGRAM_OPTIONS_LIB) $(BOOST_LOG_LIB) $(BOOST_THREAD_LIB) $(LINUX_LIB_DL)
            LDMAINFLAGS=-L"<%makefileParams.omhome%>/lib/omc/cpp" -L"<%makefileParams.omhome%>/bin" -lOMCppOMCFactory <%timeMeasureLink%> -L"$(BOOST_LIBS)" $(BOOST_SYSTEM_LIB) $(BOOST_FILESYSTEM_LIB) $(BOOST_PROGRAM_OPTIONS_LIB) $(LINUX_LIB_DL) <%additionalLinkerFlags_GCC%>
            CPPFLAGS = $(CFLAGS)
            SYSTEMFILE=OMCpp<%fileNamePrefix%><% if acceptMetaModelicaGrammar() then ".conv"%>.cpp
            MAINFILE = OMCpp<%fileNamePrefix%>Main.cpp
            MAINOBJ=OMCpp<%fileNamePrefix%>Main$(EXEEXT)
            SYSTEMOBJ=OMCpp<%fileNamePrefix%>$(DLLEXT)

            CALCHELPERMAINFILE=OMCpp<%fileNamePrefix%>CalcHelperMain.cpp
            ALGLOOPSMAINFILE=OMCpp<%fileNamePrefix%>AlgLoopMain.cpp

            CPPFILES=$(SYSTEMFILE) $(CALCHELPERMAINFILE) $(ALGLOOPSMAINFILE)
            OFILES=$(CPPFILES:.cpp=.o)

            .PHONY: <%lastIdentOfPath(modelInfo.name)%> $(CPPFILES)

            <%fileNamePrefix%>: $(MAINFILE) $(OFILES)
            <%\t%>$(CXX) -shared -I. -o $(SYSTEMOBJ) $(OFILES) $(CPPFLAGS)  <%dirExtra%> <%libsPos1%> <%libsPos2%>  $(LDSYTEMFLAGS)
            <%\t%>$(CXX) $(CPPFLAGS) -I. -o $(MAINOBJ) $(MAINFILE) $(LDMAINFLAGS)

            <%if boolNot(stringEq(makefileParams.platform, "win32")) then
                <<
                <%\t%>chmod +x <%fileNamePrefix%>.sh
                <%\t%>ln -s <%fileNamePrefix%>.sh <%fileNamePrefix%>
                >>
            %>
            >>
end simulationMakefile;



template simulationCppFile(SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let className = lastIdentOfPath(modelInfo.name)

  <<
   #include <Core/Modelica.h>
   #include <Core/ModelicaDefine.h>
   #include "OMCpp<%fileNamePrefix%>.h"
   #include "OMCpp<%fileNamePrefix%>Functions.h"



    /* Constructor */
    <%className%>::<%className%>(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData)
        :SystemDefaultImplementation(globalSettings)
        ,_algLoopSolverFactory(nonlinsolverfactory)
        ,_simData(simData)
        <%simulationInitFile(simCode, false)%>
    {
        //Number of equations
        <%dimension1(simCode)%>
        _dimZeroFunc= <%zerocrosslength(simCode)%>;
        _dimTimeEvent = <%timeeventlength(simCode)%>;
        //Number of residues
        <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then
        <<
        _dimResidues=<%numResidues(allEquations)%>;
        >>
        %>
        <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
            let numOfEqs = SimCodeUtil.getMaxSimEqSystemIndex(simCode)
            <<
            measureTimeProfileBlocksArray = std::vector<MeasureTimeData>(<%numOfEqs%>);
            MeasureTime::addResultContentBlock("<%dotPath(modelInfo.name)%>","profileBlocks",&measureTimeProfileBlocksArray);
            measureTimeFunctionsArray = std::vector<MeasureTimeData>(3); //1 evaluateODE ; 2 evaluateAll; 3 writeOutput
            MeasureTime::addResultContentBlock("<%dotPath(modelInfo.name)%>","functions",&measureTimeFunctionsArray);
            measuredProfileBlockStartValues = MeasureTime::getZeroValues();
            measuredProfileBlockEndValues = MeasureTime::getZeroValues();
            measuredFunctionStartValues = MeasureTime::getZeroValues();
            measuredFunctionEndValues = MeasureTime::getZeroValues();

            for(int i = 0; i < <%numOfEqs%>; i++)
            {
                ostringstream ss;
                ss << i;
                measureTimeProfileBlocksArray[i] = MeasureTimeData(ss.str());
            }

            measureTimeFunctionsArray[0] = MeasureTimeData("evaluateODE");
            measureTimeFunctionsArray[1] = MeasureTimeData("evaluateAll");
            measureTimeFunctionsArray[2] = MeasureTimeData("writeOutput");
            >>
        %>
        //DAE's are not supported yet, Index reduction is enabled
        _dimAE = 0; // algebraic equations
        //Initialize the state vector
        SystemDefaultImplementation::initialize();
        //Instantiate auxiliary object for event handling functionality
        //_event_handling.getCondition =  boost::bind(&<%className%>::getCondition, this, _1);

        //Todo: reindex all arrays removed  // arrayReindex(modelInfo,useFlatArrayNotation)

        _functions = new Functions(_simTime,__z,__zDot,_initial,_terminate);
    }


    /* Destructor */
    <%className%>::~<%className%>()
    {
        if(_functions != NULL)
            delete _functions;
    }



   <%Update(simCode,useFlatArrayNotation)%>

   <%DefaultImplementationCode(simCode,useFlatArrayNotation)%>
   <%checkForDiscreteEvents(discreteModelVars,simCode,useFlatArrayNotation)%>
   <%giveZeroFunc1(zeroCrossings,simCode,useFlatArrayNotation)%>
   <%setConditions(simCode)%>
   <%geConditions(simCode)%>
   <%isConsistent(simCode)%>
   <%generateStepCompleted(listAppend(allEquations,initialEquations),simCode,useFlatArrayNotation)%>
   <%generatehandleTimeEvent(timeEvents, simCode)%>
   <%generateDimTimeEvent(listAppend(allEquations,initialEquations),simCode)%>
   <%generateTimeEvent(timeEvents, simCode, true)%>


   <%isODE(simCode)%>
   <%DimZeroFunc(simCode)%>



   <%getCondition(zeroCrossings,whenClauses,simCode, useFlatArrayNotation)%>
   <%handleSystemEvents(zeroCrossings,whenClauses,simCode)%>
   <%saveall(modelInfo,simCode,useFlatArrayNotation)%>
   <%initPrevars(modelInfo,simCode,useFlatArrayNotation)%>
   <%savediscreteVars(modelInfo,simCode,useFlatArrayNotation)%>
   <%LabeledDAE(modelInfo.labels,simCode, useFlatArrayNotation)%>
    <%giveVariables(modelInfo, useFlatArrayNotation,simCode)%>
   >>
end simulationCppFile;
   /*Initialize the equations array. Point to each equation function*/
    /*initialize_equations_array();*/
 /*<%InitializeEquationsArray(allEquations, className)%>*/


/* <%saveConditions(simCode)%>*/
  /*<%arrayInit(simCode)%>*/

    /* */
  /* <%modelname%>Algloop<%index%>::<%modelname%>Algloop<%index%>(<%constructorParams%> double* z,double* zDot,EventHandling& event_handling )
  ,<%iniAlgloopParamas%>*/


template algloopCppFile(SimCode simCode,SimEqSystem eq, Context context, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for algloop system ."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname =  lastIdentOfPath(modelInfo.name)
  let filename = fileNamePrefix
  let modelfilename =  match context case  ALGLOOP_CONTEXT(genInitialisation=false,genJacobian=true)  then '<%filename%>Jacobian' else '<%filename%>'
   let &varDecls = buffer ""
   let &arrayInit = buffer ""
   let constructorParams = ConstructorParamAlgloop(modelInfo, useFlatArrayNotation)
   let iniAlgloopParamas = InitAlgloopParams(modelInfo,arrayInit,useFlatArrayNotation)
   let systemname = match context case ALGLOOP_CONTEXT(genInitialisation=false,genJacobian=true)  then '<%modelname%>Jacobian' else '<%modelname%>'
match eq
    case SES_LINEAR(__)
    case SES_NONLINEAR(__) then
  <<
   /* #include <Core/Modelica.h>
   #include <Core/ModelicaDefine.h>
   #include "OMCpp<%fileNamePrefix%>Extension.h"
   #include "OMCpp<%filename%>Algloop<%index%>.h"
   #include "OMCpp<%modelfilename%>.h" */
   <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then '#include "Math/ArrayOperations.h"'%>



    <%modelname%>Algloop<%index%>::<%modelname%>Algloop<%index%>(<%systemname%>* system, double* z,double* zDot,bool* conditions, EventHandling& event_handling )
   :AlgLoopDefaultImplementation()
   ,_system(system)
   ,__z(z)
   ,__zDot(zDot)
   <% match eq
     case SES_LINEAR(__) then
    <<
    ,__A(0)
     ,__Asparse(0)
    >>
    %>

   //<%alocateLinearSystemConstructor(eq, useFlatArrayNotation)%>
   ,_conditions(conditions)
   ,_event_handling(event_handling)
   ,_useSparseFormat(false)
   ,_functions(system->_functions)
    {
      <%initAlgloopDimension(eq,varDecls)%>

    }

   <%modelname%>Algloop<%index%>::~<%modelname%>Algloop<%index%>()
    {

     <% match eq
      case SES_LINEAR(__) then
      <<
      if(__Asparse != 0)
          delete __Asparse;

       if(__A != 0)
          delete __A;
      >>
     %>
    }

    bool <%modelname%>Algloop<%index%>::getUseSparseFormat()
    {
       return _useSparseFormat;
    }

    void <%modelname%>Algloop<%index%>::setUseSparseFormat(bool value)
    {
       _useSparseFormat = value;
    }

   <%algloopRHSCode(simCode,eq)%>
   <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then algloopResiduals(simCode,eq)%>
   <%initAlgloop(simCode,eq,context,useFlatArrayNotation)%>
   <%initAlgloopTemplate(simCode,eq,context,useFlatArrayNotation)%>
   <%queryDensity(simCode,eq,context, useFlatArrayNotation)%>
   <%updateAlgloop(simCode,eq,context)%>
   <%upateAlgloopNonLinear(simCode,eq,context, useFlatArrayNotation)%>
   <%upateAlgloopLinear(simCode,eq,context, useFlatArrayNotation)%>
   <%AlgloopDefaultImplementationCode(simCode,eq,context,useFlatArrayNotation)%>
   <%getAMatrixCode(simCode,eq)%>
   <%isLinearCode(simCode,eq)%>
   <%isLinearTearingCode(simCode,eq)%>

    >>
end algloopCppFile;

template queryDensity(SimCode simCode, SimEqSystem eqn, Context context,Boolean useFlatArrayNotation)
::=
match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
    let modelname = lastIdentOfPath(modelInfo.name)
    match eqn
      case eq as SES_NONLINEAR(__) then
       <<

        float <%modelname%>Algloop<%index%>::queryDensity()
        {
          return -1.;
        }

      >>
      case eq as SES_LINEAR(__) then
      let size=listLength(simJac)
      <<

        float <%modelname%>Algloop<%index%>::queryDensity()
        {
          return 100.*<%size%>./_dimAEq/_dimAEq;
        }

      >>
end queryDensity;

template updateAlgloop(SimCode simCode,SimEqSystem eqn,Context context)
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
      case eq as SES_LINEAR(__) then
        <<
        void <%modelname%>Algloop<%index%>::evaluate()
        {
           if(_useSparseFormat)
           {
             if(__Asparse == 0)
             {
               //sometimes initialize was not called before
               <%alocateLinearSystem(eq)%>
             }
             evaluate(__Asparse);
           }
           else
           {
             if(__A == 0)
             {
               //sometimes initialize was not called before
               <%alocateLinearSystem(eq)%>
             }
             evaluate(__A);
           }
        }
        >>
end updateAlgloop;

template upateAlgloopNonLinear( SimCode simCode,SimEqSystem eqn,Context context, Boolean useFlatArrayNotation)
  "Generates functions in simulation file."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let () = System.tmpTickReset(0)
  let modelname = lastIdentOfPath(modelInfo.name)
  match eqn
     //case eq as SES_MIXED(__) then functionExtraResiduals(fill(eq.cont,1),simCode)
     case eq as SES_NONLINEAR(__) then
     let &varDecls = buffer "" /*BUFD*/
     /*let algs = (eq.eqs |> eq2 as SES_ALGORITHM(__) =>
         equation_(eq2, context, &varDecls ,simCode, useFlatArrayNotation)
       ;separator="\n")
     let prebody = (eq.eqs |> eq2 as SES_SIMPLE_ASSIGN(__) =>
         equation_(eq2, context, &varDecls ,simCode, useFlatArrayNotation)
       ;separator="\n")*/
      let prebody = (eq.eqs |> eq2 =>
         functionExtraResidualsPreBody(eq2, &varDecls /*BUFD*/,context,simCode,useFlatArrayNotation)
      ;separator="\n")
     let body = (eq.eqs |> eq2 as SES_RESIDUAL(__) hasindex i0 =>
         let &preExp = buffer "" /*BUFD*/
         let expPart = daeExp(eq2.exp, context,
                            &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
         '<%preExp%>__xd[<%i0%>] = <%expPart%>;'

       ;separator="\n")


  <<
  <% match eq
   case SES_LINEAR(__) then
   <<
    template <typename T>
    void <%modelname%>Algloop<%index%>::evaluate(T *__A)
   >>
   case SES_NONLINEAR(__) then
   <<
    void <%modelname%>Algloop<%index%>::evaluate()
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


template functionExtraResidualsPreBody(SimEqSystem eq, Text &varDecls /*BUFP*/, Context context, SimCode simCode, Boolean useFlatArrayNotation)
 "Generates an equation."
::=
  match eq
  case e as SES_RESIDUAL(__)
  then ""
  else
  equation_(eq, context, &varDecls /*BUFD*/, simCode, useFlatArrayNotation)
  end match
end functionExtraResidualsPreBody;





template upateAlgloopLinear( SimCode simCode,SimEqSystem eqn,Context context,Boolean useFlatArrayNotation)
 "Generates functions in simulation file."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let () = System.tmpTickReset(0)
  let modelname = lastIdentOfPath(modelInfo.name)
 match eqn
 case SES_LINEAR(__) then
  let uid = System.tmpTick()
  let size = listLength(vars)
  let aname = 'A<%uid%>'
  let bname = 'b<%uid%>'
    let &varDecls = buffer "" /*BUFD*/

 let Amatrix=
    (simJac |> (row, col, eq as SES_RESIDUAL(__)) =>
      let &preExp = buffer "" /*BUFD*/
      let expPart = daeExp(eq.exp, context, &preExp /*BUFC*/,  &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
      '<%preExp%>(*__A)(<%row%>+1,<%col%>+1)=<%expPart%>;'
  ;separator="\n")

 let bvector =  (beqs |> exp hasindex i0 fromindex 1=>
     let &preExp = buffer "" /*BUFD*/
     let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
     '<%preExp%>__b(<%i0%>)=<%expPart%>;'
  ;separator="\n")

  <<
  template <typename T>
  void <%modelname%>Algloop<%index%>::evaluate(T* __A)
  {
      <%varDecls%>
      <%Amatrix%>
      <%bvector%>

  }
  >>
end upateAlgloopLinear;

template functionBodies(list<Function> functions,SimCode simCode,Boolean useFlatArrayNotation)
 "Generates the body for a set of functions."
::=
  (functions |> fn => functionBody(fn, false,simCode,useFlatArrayNotation) ;separator="\n")
end functionBodies;

template functionBody(Function fn, Boolean inFunc,SimCode simCode,Boolean useFlatArrayNotation)
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
  case fn as FUNCTION(__)           then functionBodyRegularFunction(fn, inFunc,simCode,useFlatArrayNotation)
  case fn as EXTERNAL_FUNCTION(__)  then functionBodyExternalFunction(fn, inFunc,simCode,useFlatArrayNotation)
  case fn as RECORD_CONSTRUCTOR(__) then functionBodyRecordConstructor(fn,simCode,useFlatArrayNotation)
end functionBody;

template externfunctionHeaderDefinition(list<Function> functions)
 "Generates the body for a set of functions."
::=
  (functions |> fn => extFunDef(fn) ;separator="\n")
end externfunctionHeaderDefinition;

template functionHeaderBodies1(list<Function> functions,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates the body for a set of functions."
::=
match simCode
    case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
   let recorddecls = (recordDecls |> rd => recordDeclarationHeader(rd,simCode, useFlatArrayNotation) ;separator="\n")
   let rettypedecls =  (functions |> fn => functionHeaderBody1(fn,simCode,useFlatArrayNotation) ;separator="\n")
   <<
   <%recorddecls%>
   <%rettypedecls%>
   >>
end    functionHeaderBodies1;

template functionHeaderBody1(Function fn,SimCode simCode, Boolean useFlatArrayNotation)
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
  case fn as FUNCTION(__)           then functionHeaderRegularFunction1(fn,simCode,useFlatArrayNotation)
  case fn as EXTERNAL_FUNCTION(__)  then functionHeaderExternFunction(fn,simCode)
  case fn as RECORD_CONSTRUCTOR(__) then  functionHeaderRegularFunction1(fn,simCode,useFlatArrayNotation)
end functionHeaderBody1;

template functionHeaderBodies2(list<Function> functions,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates the body for a set of functions."
::=
  (functions |> fn => functionHeaderBody2(fn,simCode,useFlatArrayNotation) ;separator="\n")
end functionHeaderBodies2;

template functionHeaderBody2(Function fn,SimCode simCode, Boolean useFlatArrayNotation)
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
  case fn as FUNCTION(__)           then functionHeaderRegularFunction2(fn,simCode, useFlatArrayNotation)
  case fn as EXTERNAL_FUNCTION(__)  then functionHeaderRegularFunction2(fn,simCode, useFlatArrayNotation)
  case fn as RECORD_CONSTRUCTOR(__) then functionHeaderRecordConstruct(fn,simCode, useFlatArrayNotation)
end functionHeaderBody2;

template functionHeaderBodies3(list<Function> functions,SimCode simCode)
 "Generates the body for a set of functions."
::=
  (functions |> fn => functionHeaderBody3(fn,simCode) ;separator="\n")
end functionHeaderBodies3;

template functionHeaderBody3(Function fn,SimCode simCode)
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
  case fn as FUNCTION(__)           then /*Function*/functionHeaderRegularFunction3(fn,simCode)
  case fn as EXTERNAL_FUNCTION(__)  then /*External Function*/ functionHeaderRegularFunction3(fn,simCode)
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
  extern <%extReturnType(return)%> <%extName%>(<%fargsStr%>);/*extern c*/
  >>
  end match
end extFunDef;



template extFunctionName(String name, String language)
::=
  match language
  case "C" then '<%name%>'
  else error(sourceInfo(), 'Unsupport external language: <%language%>')
end extFunctionName;

template extFunDefArgs(list<SimExtArg> args, String language)
::=
  match language
  case "C" then (args |> arg => extFunDefArg(arg) ;separator=", ")
  else error(sourceInfo(), 'Unsupport external language: <%language%>')
end extFunDefArgs;

template extFunDefArg(SimExtArg extArg)
 "Generates the definition of an external function argument.
  Assume that language is C for now."
::=
  match extArg
  case SIMEXTARG(cref=c, isInput=ii, isArray=ia, type_=t) then
    let name = contextCref2(c,contextFunction)
    let typeStr = extType2(t,ii,ia)
    <<
    <%typeStr%> /*<%name%>*/
    >>
  case SIMEXTARGEXP(__) then
    let typeStr = extType2(type_,true,false)
    <<
    <%typeStr%>
    >>
  case SIMEXTARGSIZE(cref=c) then
    <<
    size_t
    >>
end extFunDefArg;



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

template extReturnType(SimExtArg extArg)
 "Generates return type for external function."
::=
  match extArg
  case ex as SIMEXTARG(__)    then extType2(type_,true /*Treat this as an input (pass by value)*/,false)
  case SIMNOEXTARG(__)  then "void"
  case SIMEXTARGEXP(__) then error(sourceInfo(), 'Expression types are unsupported as return arguments <%printExpStr(exp)%>')
  else error(sourceInfo(), "Unsupported return argument")
end extReturnType;


template functionHeaderRegularFunction1(Function fn,SimCode simCode, Boolean useFlatArrayNotation)
::=
match fn
 case FUNCTION(outVars={var}) then
 let fname = underscorePath(name)
  << /*default return type*/
    typedef <%funReturnDefinition1(var,simCode)%>  <%fname%>RetType /* functionHeaderRegularFunction1 */;
    typedef <%funReturnDefinition2(var,simCode,useFlatArrayNotation)%>  <%fname%>RefRetType /* functionHeaderRegularFunction1 */;
  >>


case FUNCTION(outVars= vars as _::_) then

 let fname = underscorePath(name)
  << /*tuple return type*/
    struct <%fname%>Type/*RecordTypeTest*/
    {
       typedef boost::tuple< <%vars |> var => funReturnDefinition1(var,simCode) ;separator=", "%> > TUPLE_ARRAY;

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

template functionHeaderRecordConstruct(Function fn,SimCode simCode, Boolean useFlatArrayNotation)
::=
match fn
 case RECORD_CONSTRUCTOR(__) then
      let fname = underscorePath(name)
      let funArgsStr = (funArgs |> var as VARIABLE(__) =>
          '<%varType1(var,simCode)%> <%crefStr(name)%>'
        ;separator=", ")
      <<
      void /*RecordTypetest*/ <%fname%>(<%funArgsStr%><%if funArgs then "," else ""%><%fname%>Type &output );
      >>
end functionHeaderRecordConstruct;

template functionHeaderExternFunction(Function fn,SimCode simCode)
::=
match fn
case EXTERNAL_FUNCTION(outVars={var}) then

  let fname = underscorePath(name)
  <<
    typedef  <%funReturnDefinition1(var,simCode)%> <%fname%>RetType /* functionHeaderExternFunction */;
  >>
 case EXTERNAL_FUNCTION(outVars=_::_) then

  let fname = underscorePath(name)
   << /*tuple return type*/
    struct <%fname%>Type
    {
       typedef boost::tuple< <%outVars |> var => funReturnDefinition1(var,simCode) ;separator=", "%> > TUPLE_ARRAY;

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
    typedef boost::tuple< <%outVars |> var => funReturnDefinition1(var,simCode) ;separator=", "%> >  <%fname%>RetType /* functionHeaderExternFunction */;
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

template recordDeclarationHeader(RecordDeclaration recDecl,SimCode simCode, Boolean useFlatArrayNotation)
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
            /* <%variables |> var as VARIABLE(__) => '<%recordDeclarationHeaderArrayAllocate(var,simCode,contextOther, useFlatArrayNotation)%>' ;separator="\n"%> */
        }
        //Public  Members
        <%variables |> var as VARIABLE(__) => '<%varType3(var,simCode)%> <%crefStr(var.name)%>;' ;separator="\n"%>
    };
    >>
  case RECORD_DECL_DEF(__) then
    <<
    RECORD DECL DEF
    >>
end recordDeclarationHeader;

template recordDeclarationHeaderArrayAllocate(Variable v,SimCode simCode, Context context,Boolean useFlatArrayNotation)
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

template functionBodyRecordConstructor(Function fn,SimCode simCode, Boolean useFlatArrayNotation)
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
  void /*<%retType%>*/ Functions::<%fname%>(<%funArgs |> var as  VARIABLE(__) => '<%varType1(var,simCode)%> <%crefStr(name)%>' ;separator=", "%><%if funArgs then "," else ""%><%retType%>& output )
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


template functionHeaderRegularFunction2(Function fn,SimCode simCode, Boolean useFlatArrayNotation)
::=
match fn
case FUNCTION(outVars={}) then
  let fname = underscorePath(name)
  <<
        void <%fname%>(<%functionArguments |> var => funArgDefinition(var,simCode,useFlatArrayNotation) ;separator=", "%>);
  >>
case FUNCTION(outVars=_) then
  let fname = underscorePath(name)
  <<
        /* functionHeaderRegularFunction2 */
        void /*<%fname%>RetType*/ <%fname%>(<%functionArguments |> var => funArgDefinition(var,simCode,useFlatArrayNotation) ;separator=", "%><%if functionArguments then "," else ""%> <%fname%>RetType& output);
  >>
case EXTERNAL_FUNCTION(outVars=var::_) then
let fname = underscorePath(name)
   <<
        /* functionHeaderRegularFunction2 */
        void /*<%fname%>RetType*/ <%fname%>(<%funArgs |> var => funArgDefinition(var,simCode,useFlatArrayNotation) ;separator=", "%><%if funArgs then "," else ""%> <%fname%>RetType& output);
   >>
case EXTERNAL_FUNCTION(outVars={}) then
let fname = underscorePath(name)
   <<
        void <%fname%>(<%funArgs |> var => funArgDefinition(var,simCode,useFlatArrayNotation) ;separator=", "%>);
   >>
end functionHeaderRegularFunction2;

template functionHeaderRegularFunction3(Function fn,SimCode simCode)
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

template functionBodyRegularFunction(Function fn, Boolean inFunc,SimCode simCode,Boolean useFlatArrayNotation)
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
  let _ = (variableDeclarations |> var hasindex i1 fromindex 1 =>
      notparamInit(var, "", i1, &varDecls /*BUFD*/, &varInits /*BUFC*/,simCode, useFlatArrayNotation) ; empty /* increase the counter! */)

  //let addRootsInputs = (functionArguments |> var => addRoots(var) ;separator="\n")
  //let addRootsOutputs = (outVars |> var => addRoots(var) ;separator="\n")
  //let funArgs = (functionArguments |> var => functionArg(var, &varInits) ;separator="\n")
  let bodyPart = (body |> stmt  => funStatement(stmt, &varDecls /*BUFD*/,simCode,useFlatArrayNotation) ;separator="\n")
  let &outVarInits = buffer ""
  let &outVarCopy = buffer ""
  let &outVarAssign = buffer ""
     let _ =  match outVars   case {var} then (outVars |> var hasindex i1 fromindex 0 =>
     varOutput(fn, var,i1, &varDecls, &outVarInits, &outVarCopy, &outVarAssign, simCode, useFlatArrayNotation)
      ;separator="\n"; empty /* increase the counter! */
     )
    else
      (outVars |> var hasindex i1 fromindex 0 =>
     varOutputTuple(fn, var,i1, &varDecls, &outVarInits, &outVarCopy, &outVarAssign, simCode, useFlatArrayNotation)
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
  void /*<%retType%>*/ Functions::<%fname%>(<%functionArguments |> var => funArgDefinition(var,simCode,useFlatArrayNotation) ;separator=", "%><%if functionArguments then if outVars then "," else ""%><%if outVars then '<%retType%>& output' %> )
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
    <%functionArguments |> var => '<%funArgDefinition2(var,simCode,useFlatArrayNotation)%>;' ;separator="\n"%>
    <%if outVars then '<%retType%> out;'%>

    //MMC_TRY_TOP()



    return 0;
  }
  >>
  %>


  >>
end functionBodyRegularFunction;


template functionBodyExternalFunction(Function fn, Boolean inFunc,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates the body for an external function (just a wrapper)."
::=
match fn
case efn as EXTERNAL_FUNCTION(extArgs=extArgs) then
  //let()= System.tmpTickReset(1)
  let fname = underscorePath(name)
  let retType = if outVars then '<%fname%>RetType' else "void"
  let &preExp = buffer "" /*BUFD*/
  let &varDecls = buffer "" /*BUFD*/
  let &inputAssign = buffer "" /*BUFD*/
  let &outputAssign = buffer "" /*BUFD*/
  // make sure the variable is named "out", doh!
   let retVar = if outVars then '_<%fname%>'
  let &outVarInits = buffer ""
  let callPart =  match outVars   case {var} then
                   extFunCall(fn, &preExp /*BUFC*/, &varDecls /*BUFD*/, &inputAssign /*BUFD*/, &outputAssign /*BUFD*/, simCode, useFlatArrayNotation,false)
                  else
                  extFunCall(fn, &preExp /*BUFC*/, &varDecls /*BUFD*/, &inputAssign /*BUFD*/, &outputAssign /*BUFD*/, simCode, useFlatArrayNotation,true)
  let _ = ( outVars |> var hasindex i1 fromindex 1 =>
            notparamInit(var, retVar, i1, &varDecls /*BUFD*/, &outVarInits /*BUFC*/,simCode,useFlatArrayNotation) ///TOODOO
            ; empty /* increase the counter! */
          )
  let &outVarAssign = buffer ""
  let &outVarCopy = buffer ""
  let _ =  match outVars

  case {var} then
     //(outVars |> var hasindex i1 fromindex 0 =>
      varOutput(fn, var,0, &varDecls, &outVarInits, &outVarCopy, &outVarAssign, simCode, useFlatArrayNotation)
     // ;separator="\n"; empty /* increase the counter! */



  else
    (List.restOrEmpty(outVars) |> var hasindex i1 fromindex 1 =>  varOutputTuple(fn, var,i1, &varDecls, &outVarInits, &outVarCopy, &outVarAssign, simCode, useFlatArrayNotation)
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
    (List.restOrEmpty(outVars) |> var hasindex i1 fromindex 1 =>  varOutputTuple(fn, var,i1, &varDecls1, &outVarInits1, &outVarCopy1, &outVarAssign1, simCode, useFlatArrayNotation)
    ;separator="\n"; empty /* increase the counter! */
    )
  end match

   let functionBodyExternalFunctionreturn = match outVarAssign1
   case "" then << <%if retVar then 'output = <%retVar%>;' %>  >>
   else (extArgs |> extArg =>
  match extArg
  case SIMEXTARG(cref=c, isInput =iI, outputIndex=oi, isArray=true, type_=t) then
    match t
    case T_ARRAY(__)then
     match ty
      case T_BOOL(__) then
      if(iI)
        then ""
        else
          << <%outVarAssign1%> >>
    )

   end match

  let fnBody = <<
  void /*<%retType%>*/ Functions::<%fname%>(<%funArgs |> var => funArgDefinition(var,simCode,useFlatArrayNotation) ;separator=", "%><%if funArgs then if outVars then "," else ""%> <%if retVar then '<%retType%>& output' %>)/*function2*/
  {
    /* functionBodyExternalFunction: varDecls */
    <%varDecls%>
    /* functionBodyExternalFunction: preExp */
    <%preExp%>
  <%inputAssign%>
    /* functionBodyExternalFunction: outputAlloc */
    <%outVarInits%>
    /* functionBodyExternalFunction: callPart */
    <%callPart%>
  <%outputAssign%>
  /*testout1*/



  /*testout ende*/
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
    <%funArgs |> VARIABLE(__) => '<%expTypeArrayIf(ty)%> <%contextCref(name,contextFunction,simCode,useFlatArrayNotation)%>;' ;separator="\n"%>
    <%retType%> out;
    <%funArgs |> arg as VARIABLE(__) => readInVar(arg,simCode,useFlatArrayNotation) ;separator="\n"%>
    MMC_TRY_TOP()
    out = _<%fname%>(<%funArgs |> VARIABLE(__) => contextCref(name,contextFunction,simCode,useFlatArrayNotation) ;separator=", "%>);
    MMC_CATCH_TOP(return 1)
    <%outVars |> var as VARIABLE(__) hasindex i1 fromindex 1 => writeOutVar(var, i1) ;separator="\n";empty%>
    return 0;
  }
  >> %>


  >>
end functionBodyExternalFunction;

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

template readInVar(Variable var,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for reading a variable from inArgs."
::=
  match var
  case VARIABLE(name=cr, ty=T_COMPLEX(complexClassType=RECORD(__))) then
    <<
    if (read_modelica_record(&inArgs, <%readInVarRecordMembers(ty, contextCref(cr,contextFunction,simCode,useFlatArrayNotation))%>)) return 1;
    >>
  case VARIABLE(name=cr, ty=T_STRING(__)) then
    <<
    if (read_<%expTypeArrayIf(ty)%>(&inArgs, <%if not acceptMetaModelicaGrammar() then "(char**)"%> &<%contextCref(name,contextFunction,simCode,useFlatArrayNotation)%>)) return 1;
    >>
  case VARIABLE(__) then
    <<
    if (read_<%expTypeArrayIf(ty)%>(&inArgs, &<%contextCref(name,contextFunction,simCode,useFlatArrayNotation)%>)) return 1;
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

template extFunCall(Function fun, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/, Text &inputAssign /*BUFD*/, Text &outputAssign /*BUFD*/, SimCode simCode,Boolean useFlatArrayNotation,Boolean useTuple)
 "Generates the call to an external function."
::=
match fun
case EXTERNAL_FUNCTION(__) then
  match language
  case "C" then extFunCallC(fun, &preExp /*BUFC*/, &varDecls /*BUFD*/,&inputAssign /*BUFD*/, &outputAssign /*BUFD*/,simCode,useFlatArrayNotation,useTuple)
 end extFunCall;



template extFunCallC(Function fun, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/, Text &inputAssign /*BUFD*/, Text &outputAssign /*BUFD*/, SimCode simCode,Boolean useFlatArrayNotation,Boolean useTuple)
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
      extArg(arg, &preExp /*BUFC*/, &varDecls /*BUFD*/, &inputAssign /*BUFD*/, &outputAssign /*BUFD*/, simCode,useFlatArrayNotation)
    ;separator=", ")
  let returnAssign = match extReturn case SIMEXTARG(cref=c) then
      '<%extVarName2(c)%> = '
    else
      ""
  <<
  <%varDecs%>
  <%match extReturn case SIMEXTARG(__) then extFunCallVardecl(extReturn, &varDecls /*BUFD*/)%>
  <%dynamicCheck%>
  <%returnAssign%><%extName%>(<%args%>);
  <%extArgs |> arg => extFunCallVarcopy(arg,fname,useTuple) ;separator="\n"%>
  <%match extReturn case SIMEXTARG(__) then extFunCallVarcopy(extReturn,fname,useTuple)%>
  >>
end extFunCallC;

template extFunCallVarcopy(SimExtArg arg, String fnName,Boolean useTuple)
 "Helper to extFunCall."
::=
match arg
case SIMEXTARG(outputIndex=oi, isArray=false, type_=ty, cref=c) then
  match oi case 0 then
    <<
   /*testarg<%extVarName2(c)%>*/
  >>
  else
    let cr = '<%extVarName2(c)%>'
    match useTuple
    case true then
    let assginBegin = 'boost::get<<%intAdd(-1,oi)%>>('
      let assginEnd = ')'

    <<
     <%assginBegin%>/*_<%fnName%>.data*/output.data<%assginEnd%> = <%cr%>;
    >>
    else
    <<
     _<%fnName%> = <%cr%>;
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
     <%assginBegin%>_<%fnName%>.data<%assginEnd%> = <%cr%>;
    >>
end extFunCallVarcopyTuple;

template expTypeModelica(DAE.Type ty)
 "Generate type helper."
::=
  expTypeFlag(ty, 2)
end expTypeModelica;


template extArg(SimExtArg extArg, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/, Text &inputAssign /*BUFD*/, Text &outputAssign /*BUFD*/, SimCode simCode, Boolean useFlatArrayNotation)
 "Helper to extFunCall."
::=
  match extArg
  case SIMEXTARG(cref=c, outputIndex=oi, isArray=true, type_=t) then
    //let name = if oi then 'out.targTest5<%oi%>' else contextCref2(c,contextFunction)
  let name = contextCref2(c,contextFunction)
    let shortTypeStr = expTypeShort(t)
  let boolCast = extCBoolCast(extArg, &preExp, &varDecls, &inputAssign /*BUFD*/, &outputAssign /*BUFD*/)
  <<
  <%boolCast%>
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
    daeExternalCExp(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  case SIMEXTARGSIZE(cref=c) then
    let typeStr = expTypeShort(type_)
    let name = if outputIndex then 'out.targTest4<%outputIndex%>' else contextCref2(c,contextFunction)
    let dim = daeExp(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    '<%name%>.getDims()[<%dim%> - 1]'

end extArg;


template extCBoolCast(SimExtArg extArg, Text &preExp, Text &varDecls /*BUFP*/, Text &inputAssign /*BUFD*/, Text &outputAssign /*BUFD*/)
::=
  match extArg
  case SIMEXTARG(cref=c, isInput =iI, outputIndex=oi, isArray=true, type_=t)then
  let name = contextCref2(c,contextFunction)
   match type_
    case T_ARRAY(__)then
    let dimsStr = dimensionsList(dims) |> dim as Integer   =>  '<%dim%>';separator=","
     let dimStr = listLength(dims)
    match ty
       case T_BOOL(__) then
     let tmp = tempDecl('StatArrayDim<%dimStr%><int, <%dimsStr%> > ', &varDecls /*BUFD*/)

      if(iI)
        then
          <<
           <%tmp%>.getData()
           <%inputAssignTest(c, contextFunction, tmp, &inputAssign)%>
          >>
        else
        <<
         <%tmp%>.getData()
         <%outputAssignTest(c, contextFunction, tmp, &outputAssign)%>
        >>
    end match

  else
    '(<%extType2(t,iI,true)%>)<%name%>.getData() '
end extCBoolCast;

template inputAssignTest(DAE.ComponentRef cref, Context context, Text tmp, Text &inputAssign /*BUFD*/)
::=
  let &inputAssign += 'convertBoolToInt(<%contextCref2(cref,context)%>, <%tmp%>); '
  <<
  >>
end inputAssignTest;

template outputAssignTest(DAE.ComponentRef cref, Context context, Text tmp, Text &outputAssign /*BUFD*/)
::=
  let &outputAssign += 'convertIntToBool(<%tmp%>,<%contextCref2(cref,context)%>); '
  <<
  >>
end outputAssignTest;

template daeExternalCExp(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
  "Like daeExp, but also converts the type to external C"
::=
  match typeof(exp)
    case T_ARRAY(__) then  // Array-expressions
      let shortTypeStr = expTypeShort(typeof(exp))
      '<%daeExp(exp, context, &preExp, &varDecls,simCode,useFlatArrayNotation)%>).data()'
    else daeExp(exp, context, &preExp, &varDecls,simCode,useFlatArrayNotation)


end daeExternalCExp;

template extFunCallVardecl(SimExtArg arg, Text &varDecls /*BUFP*/)
 "Helper to extFunCall."
::=
  match arg
  case SIMEXTARG(isInput=true, isArray=false, type_=ty, cref=c) then
    match ty case T_STRING(__) then
      ""
    else
      let &varDecls += '<%extType2(ty,true,false)%> <%extVarName2(c)%>;<%\n%>'
      <<
      <%extVarName2(c)%> = (<%extType2(ty,true,false)%>)<%contextCref2(c,contextFunction)%>;
      >>
  case SIMEXTARG(outputIndex=oi, isArray=false, type_=ty, cref=c) then
    match oi case 0 then
      ""
    else
      let &varDecls += '<%extType2(ty,true,false)%> <%extVarName2(c)%>;<%\n%>'
      ""
end extFunCallVardecl;





template varOutput(Function fn, Variable var, Integer ix, Text &varDecls,
          Text &varInits, Text &varCopy, Text &varAssign, SimCode simCode, Boolean useFlatArrayNotation)
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
      let &varAssign += 'output /*_<%fname%> */= <%contextCref(var.name,contextFunction,simCode,useFlatArrayNotation)%>;<%\n%>'
      ""
case var as VARIABLE(__) then
  let marker = '<%contextCref(var.name,contextFunction,simCode,useFlatArrayNotation)%>'
  let &varInits += '/* varOutput varInits(<%marker%>) */ <%\n%>'
  //let &varAssign += '// varOutput varAssign(<%marker%>) <%\n%>'

  /*previous multi_array
  let instDimsInit = (instDims |> exp =>

      daeExp(exp, contextFunction, &varInits , &varDecls ,simCode,useFlatArrayNotation)

    ;separator="][")
 if instDims then
    let &varInits += '_<%fname%>.resize((boost::extents[<%instDimsInit%>]));
    _<%fname%>.reindex(1);<%\n%>'
    let &varAssign += '_<%fname%>=<%contextCref(var.name,contextFunction,simCode,useFlatArrayNotation)%>;<%\n%>'
    ""
  else
   // let &varInits += initRecordMembers(var)
    let &varAssign += '_<%fname%> = <%contextCref(var.name,contextFunction,simCode,useFlatArrayNotation)%>;<%\n%>'
    ""
*/
 if instDims then
 let &varAssign += '/*_<%fname%>*/ output.assign(<%contextCref(var.name,contextFunction,simCode,useFlatArrayNotation)%>);<%\n%>'
 //let &varAssign += '<%contextCref(var.name,contextFunction,simCode)%>;<%\n%>'
 ""
 else
 let &varAssign += 'output /*_<%fname%>*/ = <%contextCref(var.name,contextFunction,simCode,useFlatArrayNotation)%>;<%\n%>'
 //let &varAssign += '<%contextCref(var.name,contextFunction,simCode)%>;<%\n%>'
 ""
case var as FUNCTION_PTR(__) then
    let &varAssign += 'ToDo: Function Ptr assign'
    ""
  else "irgendwas"
end varOutput;







template varOutputTuple(Function fn, Variable var, Integer ix, Text &varDecls,
          Text &varInits, Text &varCopy, Text &varAssign, SimCode simCode, Boolean useFlatArrayNotation)
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
        /*_<%fname%>*/ output = <%strVar%>;
       >>
      ""
    else
      let &varAssign += '/*_<%fname%>*/ output= <%contextCref(var.name,contextFunction,simCode,useFlatArrayNotation)%>;<%\n%>'
      ""
case var as VARIABLE(__) then
  let marker = '<%contextCref(var.name,contextFunction,simCode,useFlatArrayNotation)%>'
  let &varInits += '/* varOutputTuple varInits(<%marker%>) */ <%\n%>'
  let &varAssign += '// varOutput varAssign(<%marker%>) <%\n%>'
  let instDimsInit = (instDims |> exp =>
      daeExp(exp, contextFunction, &varInits /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    ;separator=",")
  let assginBegin = 'boost::get<<%ix%>>'
  if instDims then
    let &varInits += '<%assginBegin%>(/*_<%fname%>*/output.data).setDims(<%instDimsInit%>);//todo setDims not for stat arrays
    <%\n%>'
    let &varAssign += '<%assginBegin%>(/*_<%fname%>*/output.data)=<%contextCref(var.name,contextFunction,simCode,useFlatArrayNotation)%>;<%\n%>'
    ""
  else
   // let &varInits += initRecordMembers(var)
    let &varAssign += ' <%assginBegin%>(/*_<%fname%>*/output.data) = <%contextCref(var.name,contextFunction,simCode,useFlatArrayNotation)%>;<%\n%>'
    ""
case var as FUNCTION_PTR(__) then
    let &varAssign += '/*_<%fname%>*/ output = (modelica_fnptr) _<%var.name%>;<%\n%>'
    ""
else
let &varAssign += '/*iregendwas*/'
    ""
end varOutputTuple;


template varDeclForVarInit(Variable var,String varName, list<DAE.Exp> instDims,  Text &varDecls /*BUFP*/, Text &varInits /*BUFP*/, SimCode simCode, Boolean useFlatArrayNotation)

 /* previous multi_array
  let &varDecls += if instDims then 'multi_array<<%expTypeShort(var.ty)%>,<%listLength(instDims)%>> <%varName%><%initVar%>;<%addRoot%><%\n%>'
   let instDimsInit = (instDims |> exp =>
      daeExp(exp, contextFunction, &varInits , &varDecls,simCode)
    ;separator="][")
  */
::=
  let instDimsInit = (instDims |> exp => daeExp(exp, contextFunction, &varInits , &varDecls,simCode,useFlatArrayNotation);separator=",")
  match var
  case var as VARIABLE(__) then
  let type = '<%varType(var)%>'
  let initVar =  match type case "modelica_metatype" then ' = NULL' else ''
  let addRoot =  match type case "modelica_metatype" then ' mmc_GC_add_root(&<%varName%>, mmc_GC_local_state, "<%varName%>");' else ''
  let testinstDimsInit = (instDims |> exp => testDaeDimensionExp(exp);separator="")
  let instDimsInit = (instDims |> exp => daeExp(exp, contextFunction, &varInits , &varDecls,simCode, useFlatArrayNotation);separator=",")
  let arrayexpression1 = (if instDims then 'StatArrayDim<%listLength(instDims)%><<%expTypeShort(var.ty)%>,<%instDimsInit%>> <%varName%>;<%\n%>'
  else '<%type%> <%varName%><%initVar%>;<%addRoot%><%\n%>')
  let arrayexpression2 = (if instDims then 'DynArrayDim<%listLength(instDims)%><<%expTypeShort(var.ty)%>> <%varName%>;<%\n%>'
  else '<%type%> <%varName%><%initVar%>;<%addRoot%><%\n%>')


  match testinstDimsInit
  case "" then
    let &varDecls += arrayexpression1
    ""
  else
    let &varDecls += arrayexpression2
    ""
end varDeclForVarInit;


template varInit(Variable var, String outStruct, Integer i, Text &varDecls /*BUFP*/, Text &varInits /*BUFP*/, SimCode simCode, Boolean useFlatArrayNotation)

 "Generates code to initialize variables.
  Does not return anything: just appends declarations to buffers."
::=

match var
case var as VARIABLE(__) then
  let varName = '<%contextCref(var.name,contextFunction,simCode,useFlatArrayNotation)%>'

  let instDimsInit = (instDims |> exp => daeExp(exp, contextFunction, &varInits , &varDecls,simCode, useFlatArrayNotation);separator=",")


 //let varName = if outStruct then 'ToDo: outStruct not implemented' else '<%contextCref(var.name,contextFunction,simCode)%>'
 let _ = varDeclForVarInit(var,varName,instDims,&varDecls,&varInits,simCode, useFlatArrayNotation)

 /*previous multi_array


  if instDims then
    (match var.value
    case SOME(exp) then

      let &varInits += '<%varName%>.resize((boost::extents[<%instDimsInit%>]));
      <%varName%>.reindex(1);<%\n%>'
      let defaultValue = varDefaultValue(var, outStruct, i, varName, &varDecls, &varInits, simCode, useFlatArrayNotation)
      let &varInits += defaultValue
      let var_name = if outStruct then

        '<%extVarName(var.name,simCode,useFlatArrayNotation)%>' else
        '<%contextCref(var.name, contextFunction,simCode,useFlatArrayNotation)%>'
      let defaultValue1 = '<%var_name%> = <%daeExp(exp, contextFunction, &varInits, &varDecls,simCode,useFlatArrayNotation)%>;<%\n%>'
      let &varInits += defaultValue1
    */

  if instDims then
    let testinstDimsInit = (instDims |> exp => testDaeDimensionExp(exp);separator="")
    let temp = setDims(testinstDimsInit, varName , &varInits, instDimsInit)


  (match var.value
    case SOME(exp) then

  let defaultValue = varDefaultValue(var, outStruct, i, varName, &varDecls, &varInits,simCode, useFlatArrayNotation)
    let &varInits += defaultValue
  let var_name = if outStruct then
        '<%extVarName(var.name,simCode, useFlatArrayNotation)%>' else
        '<%contextCref(var.name, contextFunction,simCode, useFlatArrayNotation)%>'
  // previous multi_array     let defaultValue1 = '<%var_name%> = <%daeExp(exp, contextFunction, &varInits  , &varDecls,simCode)%>;<%\n%>'
    let defaultValue1 = '<%var_name%>.assign(<%daeExp(exp, contextFunction, &varInits  , &varDecls,simCode, useFlatArrayNotation)%>);<%\n%>'
      let &varInits += defaultValue1
    ""
    else
      /*previous multi_array
    let &varInits += '<%varName%>.resize((boost::extents[<%instDimsInit%>]));
      <%varName%>.reindex(1);<%\n%>'
    */
      let defaultValue = varDefaultValue(var, outStruct, i, varName, &varDecls, &varInits, simCode, useFlatArrayNotation)

      let &varInits += defaultValue
      ""
   )
  else
    (match var.value
    case SOME(exp) then
      let defaultValue = '<%contextCref(var.name,contextFunction,simCode,useFlatArrayNotation)%> = <%daeExp(exp, contextFunction, &varInits  /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>;<%\n%>'
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
    else let &varInits += '<%varName%>.setDims(<%instDimsInit%>);/*setDims 1*/'
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

template extVarName(ComponentRef cr, SimCode simCode, Boolean useFlatArrayNotation)
::= '<%contextCref(cr,contextFunction,simCode,useFlatArrayNotation)%>_ext'
end extVarName;

template extVarName2(ComponentRef cr)
::= '<%contextCref2(cr,contextFunction)%>_ext'
end extVarName2;

template varDefaultValue(Variable var, String outStruct, Integer i, String lhsVarName,  Text &varDecls /*BUFP*/, Text &varInits /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
::=
match var
case var as VARIABLE(__) then
  match value
  case SOME(CREF(componentRef = cr)) then
    '<%contextCref(cr,contextFunction,simCode,useFlatArrayNotation)%> =  <%outStruct%>.targTest9<%i%><%\n%>'
  case SOME(arr as ARRAY(__)) then
    let arrayExp = '<%daeExp(arr, contextFunction, &varInits /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>'
    <<
    <%lhsVarName%> = <%arrayExp%>;<%\n%>
    >>
end varDefaultValue;


template funArgDefinition(Variable var,SimCode simCode, Boolean useFlatArrayNotation)
::=
  match var
  case VARIABLE(__) then '<%varType1(var, simCode)%> <%contextCref(name,contextFunction,simCode,useFlatArrayNotation)%> /*test1*/'
  case FUNCTION_PTR(__) then 'modelica_fnptr <%name%>'
end funArgDefinition;

template funArgDefinition2(Variable var,SimCode simCode, Boolean useFlatArrayNotation)
::=
  match var
  case VARIABLE(__) then '<%varType3(var, simCode)%> <%contextCref(name,contextFunction,simCode,useFlatArrayNotation)%>'
  case FUNCTION_PTR(__) then 'modelica_fnptr <%name%>'
end funArgDefinition2;

template funExtArgDefinition(SimExtArg extArg,SimCode simCode,Boolean useFlatArrayNotation)
::=
  match extArg
  case SIMEXTARG(cref=c, isInput=ii, isArray=ia, type_=t) then
    let name = contextCref(c,contextFunction,simCode,useFlatArrayNotation)
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

template funReturnDefinition1(Variable var,SimCode simCode)
::=
  match var
  case VARIABLE(__) then '<%varType3(var,simCode)%>'
  case FUNCTION_PTR(__) then 'modelica_fnptr <%name%>'
end funReturnDefinition1;

template funReturnDefinition2(Variable var,SimCode simCode, Boolean useFlatArrayNotation)
::=
  match var
  case VARIABLE(__) then '<%varType2(var,simCode,useFlatArrayNotation)%>'
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


template varType1(Variable var,SimCode simCode)
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

template varType2(Variable var,SimCode simCode, Boolean useFlatArrayNotation)
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
     let instDimsInit = (instDims |> exp => daeExp(exp, contextFunction, &varInits , &varDecls,simCode,useFlatArrayNotation);separator=",")
     match DimsTest
     case "" then if instDims then 'StatArrayDim<%listLength(instDims)%><<%expTypeShort(var.ty)%>, <%instDimsInit%>>& ' else expTypeFlag(var.ty, 5)
     else if instDims then 'DynArrayDim<%listLength(instDims)%><<%expTypeShort(var.ty)%>>&' else expTypeFlag(var.ty, 5)

end varType2;

template varType3(Variable var,SimCode simCode)
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



template funStatement(Statement stmt, Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
 "Generates function statements."
::=
  match stmt
  case ALGORITHM(__) then
    (statementLst |> stmt =>
      algStatement(stmt, contextFunction, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    ;separator="\n")
  else
    "NOT IMPLEMENTED FUN STATEMENT"
end funStatement;

template init(SimCode simCode, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__))  then
   let () = System.tmpTickReset(0)
   let &varDecls = buffer "" /*BUFD*/

   let initFunctions = functionInitial(startValueEquations,varDecls,simCode, useFlatArrayNotation)
   let initZeroCrossings = functionOnlyZeroCrossing(zeroCrossings,varDecls,simCode)
   let initEventHandling = eventHandlingInit(simCode)

   let initALgloopSolvers = initAlgloopsolvers(odeEquations,simCode)

   let initialequations  = functionInitialEquations(initialEquations,simCode, useFlatArrayNotation)
   let initextvars = functionCallExternalObjectConstructors(extObjInfo,simCode,useFlatArrayNotation)
  <<
   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initialize()
   {

      <%generateAlgloopsolvers( listAppend(allEquations,initialEquations),simCode)%>
      _simTime = 0.0;

    <%varDecls%>

   <%initextvars%>
    initializeAlgVars();
    initializeDiscreteAlgVars();
    initializeIntAlgVars();
    initializeBoolAlgVars();
    initializeAliasVars();
    initializeIntAliasVars();
    initializeBoolAliasVars();
    initializeParameterVars();
    initializeIntParameterVars();
    initializeBoolParameterVars();
    initializeStateVars();
    initializeDerVars();
    <%initFunctions%>
    //_event_handling.initialize(this,<%helpvarlength(simCode)%>,boost::bind(&<%lastIdentOfPath(modelInfo.name)%>::initPreVars, this, _1,_2));
  _event_handling.initialize(this,<%helpvarlength(simCode)%>);


    <%initEventHandling%>

   initEquations();

      <%initALgloopSolvers%>
    for(int i=0;i<_dimZeroFunc;i++)
    {
       getCondition(i);
    }
  //initialAnalyticJacobian();
  saveAll();

  <%functionInitDelay(delayedExps,simCode,useFlatArrayNotation)%>

    }

   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initEquations()
   {
      <%(initialEquations |> eq  =>
                    equation_function_call(eq,  contextOther, &varDecls /*BUFC*/, simCode,"initEquation")
                    ;separator="\n")%>
   }
   <%initialequations%>
   <%init2(simCode,modelInfo,useFlatArrayNotation)%>
    >>
  end match
end init;



template init2(SimCode simCode,ModelInfo modelInfo,Boolean useFlatArrayNotation)
::=
match modelInfo
case modelInfo as MODELINFO(vars=SIMVARS(__))  then

   //let () = System.tmpTickReset(0)
   let &varDecls1 = buffer "" /*BUFD*/
   let &varDecls2 = buffer "" /*BUFD*/
   let &varDecls3 = buffer "" /*BUFD*/
   let &varDecls4 = buffer "" /*BUFD*/
   let &varDecls5 = buffer "" /*BUFD*/
   let &varDecls6 = buffer "" /*BUFD*/
   let &varDecls7 = buffer "" /*BUFD*/
   let &varDecls8 = buffer "" /*BUFD*/
   let &varDecls9 = buffer "" /*BUFD*/
   let &varDecls10 = buffer "" /*BUFD*/
   let &varDecls11 = buffer "" /*BUFD*/
   let &varDecls12 = buffer "" /*BUFD*/
   let &varDecls13 = buffer "" /*BUFD*/
   let init1  = initValst(varDecls1,"Real",vars.stateVars, simCode,contextOther,useFlatArrayNotation)
   let init2  = initValst(varDecls2,"Real",vars.derivativeVars, simCode,contextOther,useFlatArrayNotation)
   let init3  = initValst(varDecls3,"Real",vars.algVars, simCode,contextOther,useFlatArrayNotation)
   let init4  = initValst(varDecls4,"Real",vars.discreteAlgVars, simCode,contextOther,useFlatArrayNotation)
   let init5  = initValst(varDecls5,"Int",vars.intAlgVars, simCode,contextOther,useFlatArrayNotation)
   let init6  =initValst(varDecls6,"Bool",vars.boolAlgVars, simCode,contextOther,useFlatArrayNotation)
   let init7  =initAliasValst(varDecls7,"Real",vars.aliasVars, simCode,contextOther,useFlatArrayNotation)
   let init8  =initAliasValst(varDecls8,"Int",vars.intAliasVars, simCode,contextOther,useFlatArrayNotation)
   let init9  =initValst(varDecls9,"Bool",vars.boolAliasVars, simCode,contextOther,useFlatArrayNotation)
   let init10  =initValstWithSplit(varDecls10,"Real",'<%lastIdentOfPath(modelInfo.name)%>Initialize::initializeParameterVars',vars.paramVars, simCode,contextOther,useFlatArrayNotation)
   let init11  =initValstWithSplit(varDecls11,"Int",'<%lastIdentOfPath(modelInfo.name)%>Initialize::initializeIntParameterVars',vars.intParamVars, simCode,contextOther,useFlatArrayNotation)
   let init12  =initValstWithSplit(varDecls12,"Bool",'<%lastIdentOfPath(modelInfo.name)%>Initialize::initializeBoolParameterVars',vars.boolParamVars, simCode,contextOther,useFlatArrayNotation)

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
   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeAlgVars()
   {
      <%varDecls3%>
       <%init3%>
   }
   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeDiscreteAlgVars()
   {
      <%varDecls4%>
      <%init4%>
   }
   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeIntAlgVars()
   {
      <%varDecls5%>
      <%init5%>
   }
    void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeBoolAlgVars()
   {
       <%varDecls6%>
       <%init6%>
   }
    void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeAliasVars()
   {
       <%varDecls7%>
       <%init7%>
   }
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

    <%init10%>
    <%init11%>
    <%init12%>

   >>
end init2;


template functionCallExternalObjectConstructors(ExtObjInfo extObjInfo,SimCode simCode,Boolean useFlatArrayNotation)
  "Generates function in simulation file."
::=
  match extObjInfo
  case EXTOBJINFO(__) then
    let &funDecls = buffer "" /*BUFD*/
    let &varDecls = buffer "" /*BUFD*/
    let ctorCalls = (vars |> var as SIMVAR(initialValue=SOME(exp)) =>
        let &preExp = buffer "" /*BUFD*/
        let arg = daeExp(exp, contextOther, &preExp, &varDecls,simCode,useFlatArrayNotation)
        /* Restore the memory state after each object has been initialized. Then we can
         * initalize a really large number of external objects that play with strings :)
         */
        <<
        <%preExp%>
        <%cref(var.name,useFlatArrayNotation)%> = <%arg%>;
        >>
      ;separator="\n")

    <<

      <%varDecls%>


      <%ctorCalls%>
      <%aliases |> (var1, var2) => '<%cref(var1,useFlatArrayNotation)%> = <%cref(var2,useFlatArrayNotation)%>;' ;separator="\n"%>


    >>
  end match
end functionCallExternalObjectConstructors;


template functionInitialEquations(list<SimEqSystem> initalEquations, SimCode simCode, Boolean useFlatArrayNotation)
  "Generates function in simulation file."
::=
        let equation_func_calls = (initalEquations |> eq =>
                    equation_function_create_single_func(eq, contextOther/*BUFC*/, simCode, "initEquation","Initialize",useFlatArrayNotation,true,true)
                    ;separator="\n")
  /*
  let &varDecls = buffer ""
  let body = (initalEquations |> eq  =>
      equation_(eq, contextAlgloopInitialisation, &varDecls ,simCode, useFlatArrayNotation)
    ;separator="\n")
  */
  <<
   <%equation_func_calls%>
  >>
end functionInitialEquations;

template initAlgloop(SimCode simCode,SimEqSystem eq,Context context,Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)

  match eq
  case SES_NONLINEAR(__) then
   let &varDecls = buffer ""
   let &preExp = buffer ""
   <<
     void <%modelname%>Algloop<%index%>::initialize()
     {

         <%initAlgloopEquation(eq,simCode,context,useFlatArrayNotation)%>
         AlgLoopDefaultImplementation::initialize();

        // Update the equations once before start of simulation
        evaluate();
     }
   >>
 case SES_LINEAR(__) then
   <<
     void <%modelname%>Algloop<%index%>::initialize()
     {
        <%alocateLinearSystem(eq)%>
        if(_useSparseFormat)
          <%modelname%>Algloop<%index%>::initialize(__Asparse);
        else
        {
          fill_array(*__A,0.0);
          <%modelname%>Algloop<%index%>::initialize(__A);
        }
     }
   >>
end initAlgloop;

template initAlgloopTemplate(SimCode simCode,SimEqSystem eq,Context context,Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)
  //let &varDecls = buffer ""
  //let &preExp = buffer ""
  //let initalgvars = initAlgloopvars(preExp,varDecls,modelInfo,simCode,context,useFlatArrayNotation)

  match eq
  /*
  case SES_NONLINEAR(__) then
  <<
  template <typename T>
  void <%modelname%>Algloop<%index%>::initialize(T *__A)
  {
       <%initAlgloopEquation(eq,varDecls,simCode,context,useFlatArrayNotation)%>
       AlgLoopDefaultImplementation::initialize();

    // Update the equations once before start of simulation
    evaluate();
   }
  >>
  */
 case SES_LINEAR(__) then
   <<
     template <typename T>
     void <%modelname%>Algloop<%index%>::initialize(T *__A)
     {
        <%initAlgloopEquation(eq,simCode,context,useFlatArrayNotation)%>
        // Update the equations once before start of simulation
        evaluate();
     }
   >>
end initAlgloopTemplate;


template getAMatrixCode(SimCode simCode,SimEqSystem eq)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)
   let &varDecls = buffer ""
   let &preExp= buffer ""


  match eq
  case SES_NONLINEAR(__) then
  <<
  void <%modelname%>Algloop<%index%>::getSystemMatrix(double* A_matrix)
  {

   }
  void <%modelname%>Algloop<%index%>::getSystemMatrix(sparse_matrix* A_matrix)
  {

   }
  >>
 case SES_LINEAR(__) then
   <<
     void <%modelname%>Algloop<%index%>::getSystemMatrix(double* A_matrix)
     {
          <% match eq
           case SES_LINEAR(__) then
           "memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));"
          %>
     }
     void <%modelname%>Algloop<%index%>::getSystemMatrix(sparse_matrix* A_matrix)
     {
          <% match eq
          case SES_LINEAR(__) then
          "A_matrix->build(*__Asparse);"
          %>
     }
   >>

end getAMatrixCode;


template algloopRHSCode(SimCode simCode,SimEqSystem eq)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)
  let &varDecls = buffer ""
  let &preExp = buffer ""


  match eq
  case SES_NONLINEAR(__)
  case SES_LINEAR(__) then
  <<
  void <%modelname%>Algloop<%index%>::getRHS(double* residuals)
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


template algloopResiduals(SimCode simCode,SimEqSystem eq)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)
match eq
 case SES_LINEAR(__) then
   <<
    int <%modelname%>Algloop<%index%>::getDimRHS()
    {
      return _dimAEq;
    }

    void <%modelname%>Algloop<%index%>::getRHS(double* vars)
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
 case SES_NONLINEAR(__) then
    <<
    int <%modelname%>Algloop<%index%>::giveDimRHS()
    {
      return _dimAEq;

    }

    void <%modelname%>Algloop<%index%>::getRHS(double* vars)
    {
          AlgLoopDefaultImplementation:::getRHS(vars)
    }
   >>
 case SES_MIXED(__) then algloopResiduals(simCode,cont)
end algloopResiduals;

template isLinearCode(SimCode simCode,SimEqSystem eq)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)
   let &varDecls = buffer ""
   let &preExp = buffer ""


  match eq
  case SES_NONLINEAR(__) then
  <<
  bool <%modelname%>Algloop<%index%>::isLinear()
  {
         return false;
   }
  >>

 case SES_LINEAR(__) then
   <<
     bool <%modelname%>Algloop<%index%>::isLinear()
     {
          return true;
     }
   >>

end isLinearCode;

template isLinearTearingCode(SimCode simCode,SimEqSystem eq)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)
   let &varDecls = buffer ""
   let &preExp = buffer ""


  match eq
  case SES_NONLINEAR(__) then
  let lineartearing = if linearTearing then 'true' else 'false'
  <<
  bool <%modelname%>Algloop<%index%>::isLinearTearing()
  {
        return <%lineartearing%>;
   }
  >>
 case SES_LINEAR(__) then
   <<
     bool <%modelname%>Algloop<%index%>::isLinearTearing()
     {
          return false;
     }
   >>

end isLinearTearingCode;



template initAlgloopEquation(SimEqSystem eq, SimCode simCode,Context context, Boolean useFlatArrayNotation)
 "Generates a non linear equation system."
::=
let &varDeclsCref = buffer "" /*BUFD*/
match eq
case SES_NONLINEAR(__) then
  let size = listLength(crefs)
  <<

   <%crefs |> name hasindex i0 =>
    let namestr = cref1(name,simCode,context,varDeclsCref,useFlatArrayNotation)
    <<
    __xd[<%i0%>] = <%namestr%>;
     >>
  ;separator="\n"%>
   >>
 case SES_LINEAR(__)then
     let &varDecls = buffer "" /*BUFD*/

 let Amatrix=
    (simJac |> (row, col, eq as SES_RESIDUAL(__)) =>
      let &preExp = buffer "" /*BUFD*/
      let expPart = daeExp(eq.exp, context, &preExp /*BUFC*/,  &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
      '<%preExp%>(*__A)(<%row%>+1,<%col%>+1)=<%expPart%>;'
  ;separator="\n")


let bvector =  (beqs |> exp hasindex i0 fromindex 1=>
     let &preExp = buffer "" /*BUFD*/
     let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
     '<%preExp%>__b(<%i0%>)=<%expPart%>;'
  ;separator="\n")
 <<
     <%varDecls%>
      <%Amatrix%>
      <%bvector%>
  >>

end initAlgloopEquation;






template giveAlgloopvars(SimEqSystem eq,SimCode simCode,Context context, Boolean useFlatArrayNotation)
 "Generates a non linear equation system."
::=
let &varDeclsCref = buffer "" /*BUFD*/
match eq
case SES_NONLINEAR(__) then
  let size = listLength(crefs)
  <<

   <%crefs |> name hasindex i0 =>
     let namestr = cref1(name,simCode,context,varDeclsCref,useFlatArrayNotation)
     <<
       vars[<%i0%>] = <%namestr%>;
     >>
     ;separator="\n"
   %>
  >>
 case SES_LINEAR(__) then
   <<
      <%vars |> SIMVAR(__) hasindex i0 => 'vars[<%i0%>] =<%cref1(name,simCode,context,varDeclsCref,useFlatArrayNotation)%>;' ;separator="\n"%>
   >>

end giveAlgloopvars;


template giveAlgloopNominalvars(SimEqSystem eq,SimCode simCode,Context context, Boolean useFlatArrayNotation)
 "Generates a non linear equation system."
::=
match eq
case SES_NONLINEAR(__) then
  let size = listLength(crefs)
  let &preExp = buffer "" //dummy ... the value is always a constant
  let &varDecls = buffer "" /*BUFD*/
  let nominalVars = (crefs |> name hasindex i0 =>
     let namestr = giveAlgloopNominalvars2(name,preExp,varDecls,simCode,context,useFlatArrayNotation)
            'vars[<%i0%>] = <%namestr%>;'
     ;separator="\n")
  <<
   <%varDecls%>
   <%preExp%>
   <%nominalVars%>
     >>
 case SES_LINEAR(__) then
   let &varDecls = buffer "" /*BUFD*/
   <<
      <%vars |> SIMVAR(__) hasindex i0 => 'vars[<%i0%>] =<%cref1(name,simCode,context,varDecls,useFlatArrayNotation)%>;' ;separator="\n"%>
   >>

end giveAlgloopNominalvars;


template giveAlgloopNominalvars2(ComponentRef inCref,Text &preExp,Text &varDecls,SimCode simCode,Context context,Boolean useFlatArrayNotation)
 "Generates a non linear equation system."
::=
 cref2simvar(inCref, simCode) |> var  =>
 match var
 case SIMVAR(nominalValue=SOME(exp)) then


   let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  <<
  <%expPart%>
  >>
  else
  "1.0"
end giveAlgloopNominalvars2;


template writeAlgloopvars(list<list<SimEqSystem>> continousEquations,list<SimEqSystem> discreteEquations,list<SimWhenClause> whenClauses,list<SimEqSystem> parameterEquations,SimCode simCode,Context context, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (continousEquations |> eqs => (eqs |> eq =>
      writeAlgloopvars2(eq, context, &varDecls /*BUFC*/,simCode, useFlatArrayNotation))
    ;separator=" ")

  <<
  <%algloopsolver%>
  >>
end writeAlgloopvars;


template writeAlgloopvars2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case e as SES_NONLINEAR(__) then
    let size = listLength(crefs)
  <<
   double algloopvars<%index%>[<%size%>];
   _algLoop<%index%>->getReal(algloopvars<%index%>);
   <%crefs |> name hasindex i0 =>
    let namestr = cref(name, useFlatArrayNotation)
    <<
     <%namestr%> = algloopvars<%index%>[<%i0%>];
    >>
    ;separator="\n"%>

   >>
  case e as SES_LINEAR(__) then
    let size = listLength(vars)
    let algloopid = index
    let &varDeclsCref = buffer "" /*BUFD*/
  <<
   double algloopvars<%algloopid%>[<%size%>];
   _algLoop<%index%>->getReal(algloopvars<%algloopid%>,NULL,NULL);

    <%vars |> SIMVAR(__) hasindex i0 => '<%cref1(name,simCode,context,varDeclsCref,useFlatArrayNotation)%> = algloopvars<%algloopid%>[<%i0%>];' ;separator="\n"%>


   >>
 end writeAlgloopvars2;





template setAlgloopvars(SimEqSystem eq,SimCode simCode,Context context, Boolean useFlatArrayNotation)
 "Generates a non linear equation system."
::=
let &varDeclsCref = buffer "" /*BUFD*/
match eq
case SES_NONLINEAR(__) then
  let size = listLength(crefs)
  <<

   <%crefs |> name hasindex i0 =>
    let namestr = cref1(name,simCode,context,varDeclsCref,useFlatArrayNotation)
    <<
    <%namestr%>  = vars[<%i0%>];
    >>
   ;separator="\n"%>
  >>
  case SES_LINEAR(__) then
  <<

   <%vars |> SIMVAR(__) hasindex i0 => '<%cref1(name,simCode,context,varDeclsCref,useFlatArrayNotation)%>=vars[<%i0%>];' ;separator="\n"%>

  >>
end setAlgloopvars;

template initAlgloopDimension(SimEqSystem eq, Text &varDecls /*BUFP*/)
 "Generates a non linear equation system."
::=
match eq
case SES_NONLINEAR(__) then
  let size = listLength(crefs)
  <<
    // Number of unknowns equations
    _dimAEq = <%size%>;
    _constraintType = IAlgLoop::REAL;
    __xd.resize(<%size%>);
   _xd_init.resize(<%size%>);
  >>
  case SES_LINEAR(__) then
  let size = listLength(vars)
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
case SES_LINEAR(__) then
   let size = listLength(vars)
   <<
    if(_useSparseFormat)
      __Asparse = new sparse_inserter;
    else
      __A = new StatArrayDim2<double,<%size%>,<%size%> ,true>(); //boost::multi_array<double,2>(boost::extents[<%size%>][<%size%>],boost::fortran_storage_order());
   >>
end alocateLinearSystem;

template alocateLinearSystemConstructor(SimEqSystem eq, Boolean useFlatArrayNotation)
 "Generates a non linear equation system."
::=
match eq
case SES_LINEAR(__) then
   let size = listLength(vars)
  <<
   ,__b(boost::extents[<%size%>])
  >>
end alocateLinearSystemConstructor;

template Update(SimCode simCode, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(__) then
  <<
  <%equationFunctions(allEquations,whenClauses,simCode,contextSimulationDiscrete,useFlatArrayNotation,false)%>
  <%createEvaluateAll(allEquations,whenClauses,simCode,contextOther,useFlatArrayNotation)%>
  <%createEvaluate(odeEquations,whenClauses,simCode,contextOther)%>
  <%createEvaluateZeroFuncs(equationsForZeroCrossings,simCode,contextOther)%>
  <%createEvaluateConditions(allEquations,whenClauses,simCode,contextOther,useFlatArrayNotation)%>
  >>
end Update;
/*<%update(odeEquations,algebraicEquations,whenClauses,parameterEquations,simCode)%>*/


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



template writeoutput(SimCode simCode, Boolean useFlatArrayNotation)
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
       <%writeoutputparams(modelInfo,simCode,useFlatArrayNotation)%>
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
      <%generateMeasureTimeStartCode("measuredFunctionStartValues")%>
      /* HistoryImplType::value_type_v v;
      HistoryImplType::value_type_dv v2; */

      boost::tuple<HistoryImplType::value_type_v*, HistoryImplType::value_type_dv*, double> *container = _historyImpl->getFreeContainer();
      HistoryImplType::value_type_v *v = container->get<0>();
      HistoryImplType::value_type_dv *v2 = container->get<1>();
      container->get<2>() = _simTime;

      writeAlgVarsValues(v);
      writeDiscreteAlgVarsValues(v);
      writeIntAlgVarsValues(v);
      writeBoolAlgVarsValues(v);
      writeAliasVarsValues(v);
      writeIntAliasVarsValues(v);
      writeBoolAliasVarsValues(v);
      writeStateValues(v,v2);

      <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then
      <<
      HistoryImplType::value_type_r v3;
      <%(allEquations |> eqs => (eqs |> eq => writeoutputAlgloopsolvers(eq,simCode));separator="\n")%>
      double residues [] = {<%(allEquations |> eqn => writeoutput3(eqn, simCode, useFlatArrayNotation));separator=","%>};
      for(int i=0;i<<%numResidues(allEquations)%>;i++) v3(i) = residues[i];

      <%generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "measureTimeFunctionsArray[2]")%>

      _historyImpl->write(v,v2,v3,_simTime);
      >>
    else
      <<
      <%generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "measureTimeFunctionsArray[2]")%>

      //_historyImpl->write(v,v2,_simTime);
      _historyImpl->addContainerToWriteQueue(container);
      >>
    %>
    }
   }
   <%generateWriteOutputFunctionsForVars(modelInfo, simCode, '<%lastIdentOfPath(modelInfo.name)%>WriteOutput', useFlatArrayNotation)%>

   <%writeoutput1(modelInfo)%>
  >>
  //<%writeAlgloopvars(odeEquations,algebraicEquations,whenClauses,parameterEquations,simCode)%>
end writeoutput;

template writeoutputAlgloopsolvers(SimEqSystem eq, SimCode simCode)
::=
  match eq
  case SES_LINEAR(__)
  case SES_NONLINEAR(__)
  case SES_MIXED(__)
    then
    let num = index
    match simCode
    case SIMCODE(modelInfo = MODELINFO(__)) then
    <<
    double* doubleResiduals<%num%> = new double[_algLoop<%num%>->getDimRHS()];
    _algLoop<%num%>->getRHS(doubleResiduals<%num%>);

    >>
  else
    " "
 end writeoutputAlgloopsolvers;

template writeoutput3(SimEqSystem eqn, SimCode simCode, Boolean useFlatArrayNotation)
::=
  match eqn
  case SES_RESIDUAL(__) then
  <<
  >>
  case  SES_SIMPLE_ASSIGN(__) then
  let &varDeclsCref = buffer "" /*BUFD*/
  <<
  <%cref1(cref,simCode,contextOther,varDeclsCref,useFlatArrayNotation)%>
  >>
  case SES_ARRAY_CALL_ASSIGN(__) then
  <<
  >>
  case SES_ALGORITHM(__) then
  <<
  >>
  case e as SES_LINEAR(__) then
  <<
  <%(vars |> var hasindex myindex2 => writeoutput4(e.index,myindex2));separator=",";empty%>
  >>
  case e as SES_NONLINEAR(__) then
  <<
  <%(eqs |> eq hasindex myindex2 => writeoutput4(e.index,myindex2));separator=",";empty%>
  >>
  case SES_MIXED(__) then writeoutput3(cont,simCode,useFlatArrayNotation)
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

template generateHeaderIncludeString(SimCode simCode)
 "Generates header part of simulation file."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), extObjInfo=EXTOBJINFO(__)) then
  <<
  #pragma once
  #define BOOST_EXTENSION_SYSTEM_DECL BOOST_EXTENSION_IMPORT_DECL
  #define BOOST_EXTENSION_EVENTHANDLING_DECL BOOST_EXTENSION_IMPORT_DECL
  #include "System/EventHandling.h"
  #include "System/SystemDefaultImplementation.h"
  #include "Core/Utils/extension/measure_time.hpp"

  //Forward declaration to speed-up the compilation process
  class Functions;

  <%algloopForwardDeclaration(listAppend(allEquations,initialEquations),simCode)%>

  /*****************************************************************************
  *
  * Simulation code for <%lastIdentOfPath(modelInfo.name)%> generated by the OpenModelica Compiler.
  * System class <%lastIdentOfPath(modelInfo.name)%> implements the Interface IMixedSystem
  *
  *****************************************************************************/
   >>
end generateHeaderIncludeString;



template generateAlgloopHeaderInlcudeString(SimCode simCode,Context context)
 "Generates header part of simulation file."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), extObjInfo=EXTOBJINFO(__)) then
   let modelname = lastIdentOfPath(modelInfo.name)
  let systemname = match context case  ALGLOOP_CONTEXT(genInitialisation=false,genJacobian=true) then '<%modelname%>Jacobian' else '<%modelname%>'
  <<
  #pragma once
  #define BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL BOOST_EXTENSION_IMPORT_DECL
  #define BOOST_EXTENSION_EVENTHANDLING_DECL BOOST_EXTENSION_IMPORT_DECL
  #include "System/AlgLoopDefaultImplementation.h"

  class EventHandling;
  class <%systemname%>;
  class Functions;
  >>
end generateAlgloopHeaderInlcudeString;

template generateClassDeclarationCode(SimCode simCode, String additionalProtectedMembers, Boolean useDefaultMemberVariables, Boolean useFlatArrayNotation)
 "Generates class declarations."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then

let friendclasses = generatefriendAlgloops(listAppend(allEquations,initialEquations),simCode)
let algloopsolver = generateAlgloopsolverVariables(listAppend(allEquations,initialEquations),simCode )
let memberfuncs = generateEquationMemberFuncDecls(allEquations,"evaluate")
let conditionvariables =  conditionvariable(zeroCrossings,simCode)

match modelInfo
  case MODELINFO(vars=SIMVARS(__)) then
  let getrealvars = (List.partition(listAppend(listAppend(vars.algVars, vars.discreteAlgVars), vars.paramVars), 100) |> ls hasindex idx =>
    <<
    void getReal_<%idx%>(double* z);
    void setReal_<%idx%>(const double* z);
    >>
    ;separator="\n")
  let getintvars = (List.partition(listAppend(listAppend(vars.intAlgVars, vars.intParamVars), vars.intAliasVars), 100) |> ls hasindex idx => 'void getInteger_<%idx%>(int* z);';separator="\n")
  <<
  class <%lastIdentOfPath(modelInfo.name)%>: public IContinuous, public IEvent, public IStepEvent, public ITime, public ISystemProperties <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then ', public IReduceDAE'%>, public SystemDefaultImplementation
  {

  <%friendclasses%>
  public:
      <%lastIdentOfPath(modelInfo.name)%>(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactor,boost::shared_ptr<ISimData>);

      virtual ~<%lastIdentOfPath(modelInfo.name)%>();

      <%generateMethodDeclarationCode(simCode)%>
      virtual  bool getCondition(unsigned int index);
      virtual void initPreVars(unordered_map<string,unsigned int>&,unordered_map<string,unsigned int>&);

  protected:
      //Methods:
      <%getrealvars%>
      <%getintvars%>

      bool isConsistent();
      //Called to handle all  events occured at same time
      bool handleSystemEvents( bool* events);
      //Saves all variables before an event is handled, is needed for the pre, edge and change operator
      void saveAll();
      void getJacobian(SparseMatrix& matrix);

      //Variables:
      EventHandling _event_handling;

      <%if(useDefaultMemberVariables) then '<%MemberVariable(modelInfo, useFlatArrayNotation)%>'%>
      <%conditionvariables%>
      Functions* _functions;


      boost::shared_ptr<IAlgLoopSolverFactory> _algLoopSolverFactory;    ///< Factory that provides an appropriate solver
      <%algloopsolver%>

      boost::shared_ptr<ISimData> _simData;

      <% if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
      <<
      std::vector<MeasureTimeData> measureTimeProfileBlocksArray;
      std::vector<MeasureTimeData> measureTimeFunctionsArray;
      MeasureTimeValues *measuredProfileBlockStartValues, *measuredProfileBlockEndValues, *measuredFunctionStartValues, *measuredFunctionEndValues;
      >>%>

      <%memberfuncs%>

      <%additionalProtectedMembers%>
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
     FORCE_INLINE inline void <%method%>_<%equationIndex(eq)%>();
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

template generateAlgloopClassDeclarationCode(SimCode simCode,SimEqSystem eq,Context context, Boolean useFlatArrayNotation)
 "Generates class declarations."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)

  let systemname = match context case  ALGLOOP_CONTEXT(genInitialisation=false,genJacobian=true)  then '<%modelname%>Jacobian' else '<%modelname%>'
  let algvars = MemberVariableAlgloop(modelInfo, useFlatArrayNotation)
  let constructorParams = ConstructorParamAlgloop(modelInfo, useFlatArrayNotation)
  match eq
      case SES_LINEAR(__)
    case SES_NONLINEAR(__) then
  <<
  class <%modelname%>Algloop<%index%>: public IAlgLoop, public AlgLoopDefaultImplementation
  {
  public:
      <%modelname%>Algloop<%index%>( <%systemname%>* system
                                        ,double* z,double* zDot, bool* conditions
                                       ,EventHandling& event_handling
                                      );
      virtual ~<%modelname%>Algloop<%index%>();

       <%generateAlgloopMethodDeclarationCode(simCode)%>

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
    let size = listLength(vars)
    <<
     StatArrayDim2<double,<%size%>,<%size%>,true>* __A; //dense
     //b vector
     StatArrayDim1<double,<%size%> > __b;
    >>
    %>

    sparse_inserter *__Asparse; //sparse

    //b vector
    //boost::multi_array<double,1> __b;
    bool* _conditions;

    EventHandling& _event_handling;

     <%systemname%>* _system;

     bool _useSparseFormat;
   };
  >>
end generateAlgloopClassDeclarationCode;
/*
  <%algvars%>
  */
template DefaultImplementationCode(SimCode simCode, Boolean useFlatArrayNotation)

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
   <%getNominalStateValues(states,simCode,useFlatArrayNotation)%>
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
    <%(allEquations |> eqs => (eqs |> eq => writeoutputAlgloopsolvers(eq,simCode));separator="\n")%>
    double residues [] = {<%(allEquations |> eqn => writeoutput3(eqn, simCode, useFlatArrayNotation));separator=","%>};
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
    throw std::runtime_error("isStepEvent is not yet implemented");
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
  throw std::runtime_error("provideSymbolicJacobian is not yet implemented");
}

void <%lastIdentOfPath(modelInfo.name)%>::handleEvent(const bool* events)
{
 <%handleEvent(simCode)%>
}

>>
end DefaultImplementationCode;


template getNominalStateValues( list<SimVar> stateVars,SimCode simCode,Boolean useFlatArrayNotation)

::=

  let nominalVars = stateVars |> SIMVAR(__) hasindex i0 =>
        match nominalValue
        case SOME(val)
        then
          let &preExp = buffer "" /*BUFD*/
          let &varDecls = buffer "" /*BUFD*/
          let value = '<%daeExp(val, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>'
          <<
           <%varDecls%>
           <%preExp%>
           z[<%i0%>]=<%value%>;
          >>
        else
          <<
           z[<%i0%>]=1.0;
          >>
       ;separator="\n"
<<
 <%nominalVars%>
>>
end getNominalStateValues;




template AlgloopDefaultImplementationCode(SimCode simCode,SimEqSystem eq,Context context, Boolean useFlatArrayNotation)

::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
let modelname = lastIdentOfPath(modelInfo.name)
match eq
case SES_LINEAR(__)
case SES_NONLINEAR(__) then
<<

/// Provide number (dimension) of variables according to data type
int  <%modelname%>Algloop<%index%>::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  <%modelname%>Algloop<%index%>::getDimRHS( ) const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  <%modelname%>Algloop<%index%>::isConsistent( )
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  <%modelname%>Algloop<%index%>::getReal(double* vars)
{

    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
    <%giveAlgloopvars(eq,simCode,context,useFlatArrayNotation)%>
};

/// Provide nominal variables with given index to the system
void  <%modelname%>Algloop<%index%>::getNominalReal(double* vars)
{

       <%giveAlgloopNominalvars(eq,simCode,context,useFlatArrayNotation)%>
};




/// Set variables with given index to the system
void  <%modelname%>Algloop<%index%>::setReal(const double* vars)
{

    //workaround until names of algloop vars are replaced in simcode

    <%setAlgloopvars(eq,simCode,context,useFlatArrayNotation)%>
    AlgLoopDefaultImplementation::setReal(vars);
};




/// Set stream for output
void  <%modelname%>Algloop<%index%>::setOutput(std::ostream* outputStream)
{
    AlgLoopDefaultImplementation::setOutput(outputStream);
};
>>
end AlgloopDefaultImplementationCode;


template generateMethodDeclarationCode(SimCode simCode)

::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
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
    virtual bool evaluateAll(const UPDATETYPE command =IContinuous::UNDEF_UPDATE);
    virtual void evaluateODE(const UPDATETYPE command =IContinuous::UNDEF_UPDATE);
    virtual void evaluateZeroFuncs(const UPDATETYPE command =IContinuous::UNDEF_UPDATE);
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

    virtual void saveDiscreteVars();
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
 /*! Evaluates only the equations whose indices are passed to it. */
    //bool evaluate_selective(const std::vector<int>& indices);

    /*! Evaluates only a single equation by index. */
    //bool evaluate_single(const int index);
template generateAlgloopMethodDeclarationCode(SimCode simCode)

::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
<<
    /// Provide number (dimension) of variables according to data type
    virtual int getDimReal() const    ;
    /// Provide number (dimension) of residuals according to data type
    virtual int getDimRHS() const    ;
     /// (Re-) initialize the system of equations
    virtual void initialize();

    template <typename T>
    void initialize(T *__A);

    /// Provide variables with given index to the system
    virtual void getReal(double* vars)    ;
     /// Provide variables with given index to the system
    virtual void getNominalReal(double* vars)    ;
    /// Set variables with given index to the system
    virtual void setReal(const double* vars)    ;
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
    virtual void getSystemMatrix(sparse_matrix* A_matrix);
    virtual bool isLinear();
     virtual bool isLinearTearing();
    virtual bool isConsistent();
    /// Set stream for output
    virtual void setOutput(std::ostream* outputStream)     ;

>>
//void writeOutput(HistoryImplType::value_type_v& v ,vector<string>& head ,const IMixedSystem::OUTPUT command  = IMixedSystem::UNDEF_OUTPUT);
end generateAlgloopMethodDeclarationCode;

template MemberVariable(ModelInfo modelInfo, Boolean useFlatArrayNotation)
 "Define membervariable in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  <%vars.algVars |> var =>
    MemberVariableDefine2(var, "algebraics", useFlatArrayNotation)
  ;separator="\n"%>
  <%vars.discreteAlgVars |> var =>
    MemberVariableDefine2(var, "algebraics", useFlatArrayNotation)
  ;separator="\n"%>
  <%vars.paramVars |> var =>
    MemberVariableDefine2(var, "parameters", useFlatArrayNotation)
  ;separator="\n"%>
   <%vars.aliasVars |> var =>
    MemberVariableDefine2(var, "aliasVars", useFlatArrayNotation)
  ;separator="\n"%>
  <%vars.intAlgVars |> var =>
    MemberVariableDefine("int", var, "intVariables.algebraics", useFlatArrayNotation)
  ;separator="\n"%>
  <%vars.intParamVars |> var =>
    MemberVariableDefine("int", var, "intVariables.parameters", useFlatArrayNotation)
  ;separator="\n"%>
   <%vars.intAliasVars |> var =>
    MemberVariableDefine("int", var, "intVariables.AliasVars", useFlatArrayNotation)
  ;separator="\n"%>
  <%vars.boolAlgVars |> var =>
    MemberVariableDefine("bool",var, "boolVariables.algebraics", useFlatArrayNotation)
  ;separator="\n"%>
  <%vars.boolParamVars |> var =>
    MemberVariableDefine("bool",var, "boolVariables.parameters", useFlatArrayNotation)
  ;separator="\n"%>
   <%vars.boolAliasVars |> var =>
    MemberVariableDefine("bool ",var, "boolVariables.AliasVars", useFlatArrayNotation)
  ;separator="\n"%>
  <%vars.stringAlgVars |> var =>
    MemberVariableDefine("string",var, "stringVariables.algebraics", useFlatArrayNotation)
  ;separator="\n"%>
  <%vars.stringParamVars |> var =>
    MemberVariableDefine("string",var, "stringVariables.parameters", useFlatArrayNotation)
  ;separator="\n"%>
  <%vars.stringAliasVars |> var =>
    MemberVariableDefine("string",var, "stringVariables.AliasVars", useFlatArrayNotation)
  ;separator="\n"%>
  <%vars.extObjVars |> var =>
    MemberVariableDefine("void*",var, "extObjVars", useFlatArrayNotation)
  ;separator="\n"%>

  >>
end MemberVariable;

template VariableAliasDefinition(SimVar simVar, Boolean useFlatArrayNotation)
"make a #define to the state vector"
::=
  match simVar
    case SIMVAR(varKind=STATE(__)) then
    <<
    #define <%cref(name,useFlatArrayNotation)%> __z[<%index%>];
    >>
    case SIMVAR(varKind=STATE_DER(__)) then
    <<
    #define <%cref(name,useFlatArrayNotation)%> __zDot[<%index%>];
    >>
  end match
end VariableAliasDefinition;

template MemberVariableAlgloop(ModelInfo modelInfo, Boolean useFlatArrayNotation)
 "Define membervariable in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
<<  <%vars.algVars |> var =>
    MemberVariableDefineReference2(var, "algebraics","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.algVars then ";" else ""%>
    <%vars.discreteAlgVars |> var =>
    MemberVariableDefineReference2(var, "algebraics","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.discreteAlgVars then ";" else ""%>
   <%vars.paramVars |> var =>
    MemberVariableDefineReference2(var, "parameters","",useFlatArrayNotation)
  ;separator=";\n"%> <%if vars.paramVars then ";" else ""%>
   <%vars.aliasVars |> var =>
    MemberVariableDefineReference2(var, "aliasVars","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.aliasVars then ";" else ""%>
  <%vars.intAlgVars |> var =>
    MemberVariableDefineReference("int", var, "intVariables.algebraics","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.intAlgVars then ";" else ""%>
  <%vars.intParamVars |> var =>
    MemberVariableDefineReference("int", var, "intVariables.parameters","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.intParamVars then ";" else " "%>
   <%vars.intAliasVars |> var =>
   MemberVariableDefineReference("int", var, "intVariables.AliasVars","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.intAliasVars then ";" else " "%>
  <%vars.boolAlgVars |> var =>
    MemberVariableDefineReference("bool",var, "boolVariables.algebraics","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.boolAlgVars then ";" else ""%>
  <%vars.boolParamVars |> var =>
    MemberVariableDefineReference("bool",var, "boolVariables.parameters","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.boolParamVars then ";" else " "%>
   <%vars.boolAliasVars |> var =>
     MemberVariableDefineReference("bool ",var, "boolVariables.AliasVars","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.boolAliasVars then ";" else ""%>
  <%vars.stringAlgVars |> var =>
    MemberVariableDefineReference("string",var, "stringVariables.algebraics","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.stringAlgVars then ";" else ""%>
  <%vars.stringParamVars |> var =>
    MemberVariableDefineReference("string",var, "stringVariables.parameters","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.stringParamVars then ";" else " "%>
  <%vars.stringAliasVars |> var =>
    MemberVariableDefineReference("string",var, "stringVariables.AliasVars","",useFlatArrayNotation)
  ;separator=";\n"%><%if vars.stringAliasVars then ";" else ""%>

  >>
end MemberVariableAlgloop;



template ConstructorParamAlgloop(ModelInfo modelInfo, Boolean useFlatArrayNotation)
 "Define membervariable in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  <%vars.algVars |> var =>
    MemberVariableDefineReference2(var, "algebraics","_",useFlatArrayNotation)
  ;separator=","%><%if vars.algVars then "," else ""%>
  <%vars.discreteAlgVars |> var =>
    MemberVariableDefineReference2(var, "algebraics","_",useFlatArrayNotation)
  ;separator=","%><%if vars.discreteAlgVars then "," else ""%>
  <%vars.paramVars |> var =>
    MemberVariableDefineReference2(var, "parameters","_",useFlatArrayNotation)
  ;separator=","%><%if vars.paramVars then "," else ""%>
  <%vars.aliasVars |> var =>
    MemberVariableDefineReference2(var, "aliasVars","_",useFlatArrayNotation)
  ;separator=","%><%if vars.aliasVars then "," else ""%>
   <%vars.intAlgVars |> var =>
    MemberVariableDefineReference("int", var, "intVariables.algebraics","_",useFlatArrayNotation)
  ;separator=","%> <%if vars.intAlgVars then "," else ""%>
  <%vars.intParamVars |> var =>
    MemberVariableDefineReference("int", var, "intVariables.parameters","_",useFlatArrayNotation)
  ;separator=","%> <%if vars.intParamVars then "," else ""%>
  <%vars.intAliasVars |> var =>
    MemberVariableDefineReference("int", var, "intVariables.AliasVars","_",useFlatArrayNotation)
  ;separator=","%><%if vars.intAliasVars then "," else ""%>
  <%vars.boolAlgVars |> var =>
    MemberVariableDefineReference("bool",var, "boolVariables.algebraics","_",useFlatArrayNotation)
  ;separator=","%><%if vars.boolAlgVars then "," else ""%>
  <%vars.boolParamVars |> var =>
    MemberVariableDefineReference("bool",var, "boolVariables.parameters","_",useFlatArrayNotation)
  ;separator=","%><%if vars.boolParamVars then "," else ""%>
   <%vars.boolAliasVars |> var =>
    MemberVariableDefineReference("bool ",var, "boolVariables.AliasVars","_",useFlatArrayNotation)
  ;separator=","%><%if vars.boolAliasVars then "," else ""%>
  <%vars.stringAlgVars |> var =>
    MemberVariableDefineReference("string",var, "stringVariables.algebraics","_",useFlatArrayNotation)
  ;separator=","%><%if vars.stringAlgVars then "," else "" %>
  <%vars.stringParamVars |> var =>
    MemberVariableDefineReference("string",var, "stringVariables.parameters","_",useFlatArrayNotation)
  ;separator=","%><%if vars.stringParamVars then "," else ""%>
  <%vars.stringAliasVars |> var =>
    MemberVariableDefineReference("string",var, "stringVariables.AliasVars","_",useFlatArrayNotation)
  ;separator=","%><%if vars.stringAliasVars then "," else ""%>

  >>
end ConstructorParamAlgloop;

template CallAlgloopParams(ModelInfo modelInfo, Boolean useFlatArrayNotation)
 "Define membervariable in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
 << <%vars.algVars |> var =>
    CallAlgloopParam(var, useFlatArrayNotation)
  ;separator=","%> <%if vars.algVars then "," else ""%>
  <%vars.discreteAlgVars |> var =>
    CallAlgloopParam(var,useFlatArrayNotation)
  ;separator=","%> <%if vars.discreteAlgVars then "," else ""%>
  <%vars.paramVars |> var =>
    CallAlgloopParam(var, useFlatArrayNotation)
  ;separator=","%> <%if vars.paramVars then "," else ""%>
  <%vars.aliasVars |> var =>
    CallAlgloopParam(var, useFlatArrayNotation)
  ;separator=","%><%if vars.aliasVars then "," else ""%>
  <%vars.intAlgVars |> var =>
    CallAlgloopParam(var, useFlatArrayNotation)
  ;separator=","%><%if vars.intAlgVars then "," else ""%>
  <%vars.intParamVars |> var =>
    CallAlgloopParam(var, useFlatArrayNotation)
  ;separator=","%><%if vars.intParamVars then "," else ""%>
  <%vars.intAliasVars |> var =>
    CallAlgloopParam(var, useFlatArrayNotation)
  ;separator=","%><%if vars.intAliasVars then "," else ""%>
  <%vars.boolAlgVars |> var =>
    CallAlgloopParam(var, useFlatArrayNotation)
  ;separator=","%><%if vars.boolAlgVars then "," else ""%>
  <%vars.boolParamVars |> var =>
    CallAlgloopParam(var, useFlatArrayNotation)
  ;separator=","%><%if vars.boolParamVars then "," else ""%>
  <%vars.boolAliasVars |> var =>
    CallAlgloopParam(var, useFlatArrayNotation)
  ;separator=","%> <%if vars.boolAliasVars then "," else ""%>
  <%vars.stringAlgVars |> var =>
    CallAlgloopParam(var, useFlatArrayNotation)
  ;separator=","%><%if vars.stringAlgVars then "," else "" %>
  <%vars.stringParamVars |> var =>
    CallAlgloopParam(var, useFlatArrayNotation)
  ;separator=","%><%if vars.stringParamVars then "," else ""%>
  <%vars.stringAliasVars |> var =>
    CallAlgloopParam(var, useFlatArrayNotation)
  ;separator=","%><%if vars.stringAliasVars then "," else ""%>
 >>
end CallAlgloopParams;



template InitAlgloopParams(ModelInfo modelInfo,Text& arrayInit, Boolean useFlatArrayNotation)
 "Define membervariable in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then

 <<
   /* vars.algVars */
   <%vars.algVars |> var =>
    InitAlgloopParam(var, "algebraics",arrayInit, useFlatArrayNotation)
  ;separator=","%> <%if vars.algVars then "," else ""%>
   /* vars.discreteAlgVars */
  <%vars.discreteAlgVars |> var =>
    InitAlgloopParam( var, "algebraics",arrayInit, useFlatArrayNotation)
  ;separator=","%> <%if vars.discreteAlgVars then "," else ""%>
   /* vars.paramVars */
  <%vars.paramVars |> var =>
    InitAlgloopParam(var, "parameters",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.paramVars then "," else ""%>
   /* vars.aliasVars */
   <%vars.aliasVars |> var =>
    InitAlgloopParam(var, "aliasVars",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.aliasVars then "," else ""%>
   /* vars.intAlgVars */
  <%vars.intAlgVars |> var =>
    InitAlgloopParam( var, "intVariables.algebraics",arrayInit, useFlatArrayNotation)
  ;separator=","%> <%if vars.intAlgVars then "," else ""%>
   /* vars.intParamVars */
  <%vars.intParamVars |> var =>
    InitAlgloopParam( var, "intVariables.parameters",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.intParamVars then "," else ""%>
   /* vars.intAliasVars */
  <%vars.intAliasVars |> var =>
    InitAlgloopParam( var, "intVariables.AliasVars",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.intAliasVars then "," else ""%>
   /* vars.boolAlgVars */
  <%vars.boolAlgVars |> var =>
    InitAlgloopParam(var, "boolVariables.algebraics",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.boolAlgVars then "," else ""%>
   /* vars.boolParamVars */
  <%vars.boolParamVars |> var =>
    InitAlgloopParam(var, "boolVariables.parameters",arrayInit, useFlatArrayNotation)
  ;separator=","%> <%if vars.boolParamVars then "," else ""%>
   /* vars.boolAliasVars */
  <%vars.boolAliasVars |> var =>
    InitAlgloopParam(var, "boolVariables.AliasVars",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.boolAliasVars then "," else ""%>
   /* vars.stringAlgVars */
   <%if vars.stringAlgVars then "," else ""%>
  <%vars.stringAlgVars |> var =>
    InitAlgloopParam(var, "stringVariables.algebraics",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.stringAlgVars then "," else "" %>
   /* vars.stringParamVars */
   <%vars.stringParamVars |> var =>
    InitAlgloopParam(var, "stringVariables.parameters",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.stringParamVars then "," else "" %>
   /* vars.stringAliasVars */
  <%vars.stringAliasVars |> var =>
    InitAlgloopParam(var, "stringVariables.AliasVars",arrayInit, useFlatArrayNotation)
  ;separator=","%><%if vars.stringAliasVars then "," else "" %>
 >>
 end InitAlgloopParams;

template MemberVariableDefine(String type,SimVar simVar, String arrayName, Boolean useFlatArrayNotation)
::=
match simVar

     case SIMVAR(numArrayElement={},arrayCref=NONE(),name=CREF_IDENT(subscriptLst=_::_)) then ''

    case SIMVAR(numArrayElement={},arrayCref=NONE()) then
      <<
      <%type%> <%cref(name,useFlatArrayNotation)%>;
      >>
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(_),numArrayElement=num)
    then
      let &dims = buffer "" /*BUFD*/
      let arrayName = arraycref2(name,dims)
    let arraysize = arrayextentDims(name,v.numArrayElement)
      <<
      StatArrayDim<%dims%><<%variableType(type_)%>, <%arraysize%> >  <%arrayName%>;
      >>
    case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(_),numArrayElement=num) then
      let &dims = buffer "" /*BUFD*/
      let arrayName = arraycref2(name,dims)
    let arraysize = arrayextentDims(name,v.numArrayElement)
    /*previous multiarray
    <<
      multi_array<<%variableType(type_)%>,<%dims%>> <%arrayName%>;
      >>*/
    //
    let test = v.numArrayElement |> index =>  '<%index%>'; separator=","
      <<
      StatArrayDim<%dims%><<%variableType(type_)%>, <%arraysize%> >  <%arrayName%>  /*testarray3 <%test%> */;
      >>
    case SIMVAR(numArrayElement=_::_) then
      let& dims = buffer "" /*BUFD*/
      let varName = arraycref2(name,dims)
      let varType = variableType(type_)
      match dims
        case "0" then  '<%varType%> <%varName%>;'
        else ''
end MemberVariableDefine;

template MemberVariableDefineReference(String type,SimVar simVar, String arrayName,String pre, Boolean useFlatArrayNotation)
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
end MemberVariableDefineReference;


template MemberVariableDefine2(SimVar simVar, String arrayName, Boolean useFlatArrayNotation)
::=

match simVar


    /*case SIMVAR(arrayCref=NONE()) then
       <<
       <%variableType(type_)%> <%cref(name)%>;
       >>
    */
      case SIMVAR(numArrayElement={},arrayCref=NONE(),name=CREF_IDENT(subscriptLst=_::_)) then ''

      case SIMVAR(numArrayElement={},arrayCref=NONE()) then
      <<
      <%variableType(type_)%> <%cref(name,useFlatArrayNotation)%>;
      >>
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(_),numArrayElement=num)
     then
      let &dims = buffer "" /*BUFD*/
      let arrayName = arraycref2(name,dims)
    let typeString = variableType(type_)
    let arraysize = arrayextentDims(name,v.numArrayElement)
    <<
    StatArrayDim<%dims%><<%typeString%>,<%arraysize%>>  <%arrayName%>/*testarray2*/;
    >>
    case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(_),numArrayElement=num) then
      let &dims = buffer "" /*BUFD*/
      let arrayName = arraycref2(name,dims)

    //ComponentRef cr, Text& dims
    let array_dimensions =  arrayextentDims(name, v.numArrayElement)
    //numArrayElement

    /*previous multi_array<<
      multi_array<<%variableType(type_)%>,<%dims%>> <%arrayName%>;
      >>
    */
      <<
      StatArrayDim<%dims%><<%variableType(type_)%>, <%array_dimensions%>> <%arrayName%> /*testarray*/;
      >>
   /*special case for varibales that marked as array but are not arrays */
    case SIMVAR(numArrayElement=_::_) then
      let& dims = buffer "" /*BUFD*/
      let varName = arraycref2(name,dims)
      let varType = variableType(type_)
      match dims
        case "0" then  '<%varType%> <%varName%>;'
        else ''
      end match


end MemberVariableDefine2;


template InitAlgloopParam(SimVar simVar, String arrayName,Text& arrayInit, Boolean useFlatArrayNotation)
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
end InitAlgloopParam;

template CallAlgloopParam(SimVar simVar, Boolean useFlatArrayNotation)
::=
match simVar
      case SIMVAR(numArrayElement={}) then
      <<
      <%cref(name, useFlatArrayNotation)%>
      >>
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(_),numArrayElement=num) then
      //let &arrayInit+= ',<%arraycref(name, useFlatArrayNotation)%>=_<%arraycref(name, useFlatArrayNotation)%>'
      '<%arraycref(name, useFlatArrayNotation)%>'
    case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(_),numArrayElement=num) then
      //let &arrayInit+= ' ,<%arraycref(name, useFlatArrayNotation)%>= _<%arraycref(name, useFlatArrayNotation)%>'
      '<%arraycref(name, useFlatArrayNotation)%>'
    /*special case for varibales that marked as array but are not arrays */
    case SIMVAR(numArrayElement=_::_) then
      let& dims = buffer "" /*BUFD*/
      let varName = arraycref2(name,dims)
      match dims case "0" then  '<%varName%>'


end CallAlgloopParam;

template MemberVariableDefineReference2(SimVar simVar, String arrayName,String pre, Boolean useFlatArrayNotation)
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
end MemberVariableDefineReference2;


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

template lastIdentOfPathFromSimCode(SimCode simCode) ::=
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
              then   <<<%crefWithoutIndexOperator(cr)%>>>
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



template crefStr(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(ident = "xloc") then '__xd<%subscriptsStr(subscriptLst)%>'
  case CREF_IDENT(ident = "time") then "_simTime"
   //filter key words for variable names
   case CREF_IDENT(ident = "unsigned") then
   'unsigned_'
   case CREF_IDENT(ident = "string") then
   'string_'
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

template simulationInitFile(SimCode simCode, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__), vars = vars as SIMVARS(__)))
  then
  <<

  <%if (boolNot(useFlatArrayNotation)) then arrayConstruct(modelInfo, useFlatArrayNotation) else ""%>
  <%initconstVals(vars.stringParamVars,simCode,useFlatArrayNotation)%>
  >>
end simulationInitFile;

template initconstVals(list<SimVar> varsLst,SimCode simCode,Boolean useFlatArrayNotation) ::=
  varsLst |> (var as SIMVAR(__)) =>
  initconstValue(var,simCode,useFlatArrayNotation)
  ;separator="\n"
end initconstVals;

template initconstValue(SimVar var,SimCode simCode, Boolean useFlatArrayNotation) ::=
 match var
  case SIMVAR(numArrayElement=_::_) then ''
  case SIMVAR(type_=type) then ',<%cref(name, useFlatArrayNotation)%>
    <%match initialValue
    case SOME(v) then initconstValue2(v,simCode,useFlatArrayNotation)
      else match type
      case T_STRING(__) then '("")'
      else '(0)'
    %>'
end initconstValue;

template crefToCStrOrig(ComponentRef cr)
 "Helper function to cref."
::=
  match cr
  case CREF_IDENT(__) then '<%unquoteIdentifier(ident)%><%subscriptsToCStrOrig(subscriptLst)%>'
  case CREF_QUAL(__) then '<%unquoteIdentifier(ident)%><%subscriptsToCStrOrig(subscriptLst)%>$P<%crefToCStrOrig(componentRef)%>'
  case WILD(__) then ''
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStrOrig;
template subscriptsToCStrOrig(list<Subscript> subscripts)
::=
  if subscripts then
    '$lB<%subscripts |> s => subscriptToCStr(s) ;separator="$c"%>$rB'
end subscriptsToCStrOrig;

template initconstValue2(Exp initialValue,SimCode simCode,Boolean useFlatArrayNotation)
::=
  match initialValue
    case v then
      let &preExp = buffer "" //dummy ... the value is always a constant
      let &varDecls = buffer ""
      match daeExp(v, contextOther, &preExp, &varDecls,simCode,useFlatArrayNotation)
      case vStr as "0"
      case vStr as "0.0"
      case vStr as "(0)" then
       '(<%vStr%>)'
      case vStr as "" then
       '(<%vStr%>)'
      case vStr then
       '(<%vStr%>)'
     end match

end initconstValue2;


template initializeArrayElements(SimCode simCode, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__), vars = vars as SIMVARS(__)))
  then
  <<
  <%initValsArray(vars.constVars,simCode,useFlatArrayNotation)%>
  <%initValsArray(vars.intConstVars,simCode,useFlatArrayNotation)%>
  <%initValsArray(vars.boolConstVars,simCode,useFlatArrayNotation)%>
  <%initValsArray(vars.stringConstVars,simCode,useFlatArrayNotation)%>
  >>
end initializeArrayElements;

template initValsArray(list<SimVar> varsLst,SimCode simCode,Boolean useFlatArrayNotation) ::=
  varsLst |> SIMVAR(numArrayElement=_::_,initialValue=SOME(v)) =>
  <<
  <%cref(name,useFlatArrayNotation)%> = <%initVal(v)%>;
  >>
  ;separator="\n"
end initValsArray;

template arrayInit(SimCode simCode, Boolean useFlatArrayNotation)
 "Generates the contents of the makefile for the simulation case."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__), vars = vars as SIMVARS(__)))
  then
  <<
  <%initVals1(vars.paramVars,simCode, useFlatArrayNotation)%>
  <%initVals1(vars.intParamVars,simCode, useFlatArrayNotation)%>
  <%initVals1(vars.boolParamVars,simCode, useFlatArrayNotation)%>
  <%initVals1(vars.stringParamVars,simCode, useFlatArrayNotation)%>
   >>
end arrayInit;

template initVals1(list<SimVar> varsLst, SimCode simCode, Boolean useFlatArrayNotation) ::=
  varsLst |> (var as SIMVAR(__)) =>
  initVals2(var,simCode,useFlatArrayNotation)
  ;separator="\n"
end initVals1;

template initVals2(SimVar var, SimCode simCode, Boolean useFlatArrayNotation) ::=
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
       void <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeAlgVarsResultNames(vector<string>& names)
       {
        <% if protectedVars(vars.algVars) then
        'names += <%(vars.algVars |> SIMVAR(isProtected=false) =>
        '"<%crefStrForWriteOutput(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>

       }
       void <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeDiscreteAlgVarsResultNames(vector<string>& names)
       {
        <% if  protectedVars(vars.discreteAlgVars) then
        'names += <%(vars.discreteAlgVars |> SIMVAR(isProtected=false) =>
        '"<%crefStrForWriteOutput(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>

       }
       void  <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeIntAlgVarsResultNames(vector<string>& names)
        {
         <% if  protectedVars(vars.intAlgVars) then
         'names += <%(vars.intAlgVars |> SIMVAR(isProtected=false) =>
           '"<%crefStrForWriteOutput(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }
        void <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeBoolAlgVarsResultNames(vector<string>& names)
        {
        <% if  protectedVars(vars.boolAlgVars) then
         'names +=<%(vars.boolAlgVars |> SIMVAR(isProtected=false) =>
           '"<%crefStrForWriteOutput(name)%>"'  ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }


        void  <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeAliasVarsResultNames(vector<string>& names)
        {
         <% if  protectedVars(vars.aliasVars) then
         'names +=<%(vars.aliasVars |> SIMVAR(isProtected=false) =>
          '"<%crefStrForWriteOutput(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += "  )%>;' %>
        }

       void   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeIntAliasVarsResultNames(vector<string>& names)
        {
        <% if  protectedVars(vars.intAliasVars) then
           'names += <%(vars.intAliasVars |> SIMVAR(isProtected=false) =>
            '"<%crefStrForWriteOutput(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }

        void <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeBoolAliasVarsResultNames(vector<string>& names)
        {
          <% if  protectedVars(vars.boolAliasVars) then
          'names += <%(vars.boolAliasVars |> SIMVAR(isProtected=false) =>
            '"<%crefStrForWriteOutput(name)%>"';separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }

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



        void <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeAlgVarsResultDescription(vector<string>& description)
       {
        <% if  protectedVars(vars.algVars) then
        'description += <%(vars.algVars |> SIMVAR(isProtected=false) =>
        '"<%Util.escapeModelicaStringToCString(comment)%>"' ;separator=",";align=10;alignSeparator=";\n description += " )%>;' %>

       }
       void <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeDiscreteAlgVarsResultDescription(vector<string>& description)
       {
        <% if  protectedVars(vars.discreteAlgVars) then
        'description += <%(vars.discreteAlgVars |> SIMVAR(isProtected=false) =>
        '"<%Util.escapeModelicaStringToCString(comment)%>"' ;separator=",";align=10;alignSeparator=";\n description += " )%>;' %>

       }
       void  <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeIntAlgVarsResultDescription(vector<string>& description)
        {
         <% if  protectedVars(vars.intAlgVars) then
         'description += <%(vars.intAlgVars |> SIMVAR(isProtected=false) =>
           '"<%Util.escapeModelicaStringToCString(comment)%>"' ;separator=",";align=10;alignSeparator=";\n description += " )%>;' %>
        }
        void <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeBoolAlgVarsResultDescription(vector<string>& description)
        {
        <% if  protectedVars(vars.boolAlgVars) then
         'description +=<%(vars.boolAlgVars |> SIMVAR(isProtected=false) =>
           '"<%Util.escapeModelicaStringToCString(comment)%>"'  ;separator=",";align=10;alignSeparator=";\n description += " )%>;' %>
        }



        void  <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeAliasVarsResultDescription(vector<string>& description)
        {
         <% if  protectedVars(vars.aliasVars) then
         'description +=<%(vars.aliasVars |> SIMVAR(isProtected=false) =>
          '"<%Util.escapeModelicaStringToCString(comment)%>"' ;separator=",";align=10;alignSeparator=";\n description += "  )%>;' %>
        }

       void   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeIntAliasVarsResultDescription(vector<string>& description)
        {
        <% if  protectedVars(vars.intAliasVars) then
           'description += <%(vars.intAliasVars |> SIMVAR(isProtected=false) =>
            '"<%Util.escapeModelicaStringToCString(comment)%>"' ;separator=",";align=10;alignSeparator=";\n description += " )%>;' %>
        }

        void <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeBoolAliasVarsResultDescription(vector<string>& description)
        {
          <% if protectedVars(vars.boolAliasVars) then
          'description += <%(vars.boolAliasVars |> SIMVAR(isProtected=false) =>
            '"<%Util.escapeModelicaStringToCString(comment)%>"';separator=",";align=10;alignSeparator=";\n description += " )%>;' %>
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
case lin as SES_LINEAR(__) then
<<
<%(vars |> var => '1');separator="+"%>
>>
case SES_NONLINEAR(__) then
<<
<%(eqs |> eq => '1');separator="+"%>
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

template numBoolAlgvar(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numBoolAlgVars%>
>>
end numBoolAlgvar;


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

template getAliasVar(AliasVariable aliasvar, SimCode simCode,Context context, Boolean useFlatArrayNotation)
 "Returns the alias Attribute of ScalarVariable."
::=
  let &varDeclsCref = buffer "" /*BUFD*/
  match aliasvar
    case NOALIAS(__) then 'noAlias'
    case ALIAS(__) then '<%cref1(varName,simCode,context,varDeclsCref,useFlatArrayNotation)%>'
    case NEGATEDALIAS(__) then '-<%cref1(varName,simCode,context,varDeclsCref,useFlatArrayNotation)%>'
    else 'noAlias'
end getAliasVar;


template getAliasVarName(AliasVariable aliasvar, SimCode simCode,Context context, Boolean useFlatArrayNotation)
 "Returns the alias Attribute of ScalarVariable."
::=
  let &varDeclsCref = buffer "" /*BUFD*/
  match aliasvar
    case NOALIAS(__) then 'noAlias'
    case ALIAS(__) then '<%cref1(varName,simCode,context,varDeclsCref, useFlatArrayNotation)%>'
    case NEGATEDALIAS(__) then '<%cref1(varName,simCode,context,varDeclsCref, useFlatArrayNotation)%>'
    else 'noAlias'
end getAliasVarName;

//template for write variables for each time step
template generateWriteOutputFunctionsForVars(ModelInfo modelInfo,SimCode simCode, String className, Boolean useFlatArrayNotation)
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
 /* const int algVarsStart = <%algVarsStart%>;
 const int discrAlgVarsStart  = <%discrAlgVarsStart%>;
 const int intAlgVarsStart    = <%intAlgVarsStart%>;
 const int boolAlgVarsStart   = <%boolAlgVarsStart%>;
 const int aliasVarsStart     = <%aliasVarsStart%>;
 const int intAliasVarsStart  = <%intAliasVarsStart%>;
 const int boolAliasVarsStart = <%boolAliasVarsStart%>;
 const int stateVarsStart     = <%stateVarsStart%>; */

 <%writeOutputVars("writeAlgVarsValues", vars.algVars, stringInt(algVarsStart), className, false, simCode, useFlatArrayNotation)%>
 <%writeOutputVars("writeDiscreteAlgVarsValues", vars.discreteAlgVars, stringInt(discrAlgVarsStart), className, false, simCode, useFlatArrayNotation)%>
 <%writeOutputVars("writeIntAlgVarsValues", vars.intAlgVars, stringInt(intAlgVarsStart), className, false, simCode, useFlatArrayNotation)%>
 <%writeOutputVars("writeBoolAlgVarsValues", vars.boolAlgVars, stringInt(boolAlgVarsStart), className, false, simCode, useFlatArrayNotation)%>

 <%writeOutputVars("writeAliasVarsValues", vars.aliasVars, stringInt(aliasVarsStart), className, true, simCode, useFlatArrayNotation)%>
 <%writeOutputVars("writeIntAliasVarsValues", vars.intAliasVars, stringInt(intAliasVarsStart), className, true, simCode, useFlatArrayNotation)%>
 <%writeOutputVars("writeBoolAliasVarsValues", vars.boolAliasVars, stringInt(boolAliasVarsStart), className, true, simCode, useFlatArrayNotation)%>

 void <%className%>::writeStateValues(HistoryImplType::value_type_v *v, HistoryImplType::value_type_dv *v2)
 {
   <%(vars.stateVars      |> SIMVAR() hasindex i8 =>'(*v)(<%intAdd(stringInt(stateVarsStart), stringInt(i8))%>)=__z[<%index%>];';separator="\n")%>
   <%(vars.derivativeVars |> SIMVAR() hasindex i9 fromindex 1 =>'(*v2)(<%i9%>)=__zDot[<%index%>]; ';separator="\n")%>
 }
 >>
end generateWriteOutputFunctionsForVars;

//template to generate a function that writes all given variables
template writeOutputVars(String functionName, list<SimVar> vars, Integer startIndex, String className, Boolean areAliasVars, SimCode simCode, Boolean useFlatArrayNotation)
::=
  <<
  void <%className%>::<%functionName%>(HistoryImplType::value_type_v *v)
  {
    <%if(areAliasVars) then
    <<
    <%vars |> SIMVAR(isProtected=false) hasindex i1 =>'(*v)(<%intAdd(startIndex, stringInt(i1))%>)=<%getAliasVar(aliasvar, simCode, contextOther, useFlatArrayNotation)%>;';separator="\n"%>
    >>
    else
    <<
    <%vars |> SIMVAR(isProtected=false) hasindex i0 =>'(*v)(<%intAdd(startIndex,stringInt(i0))%>)=<%cref(name, useFlatArrayNotation)%>;';separator="\n"%>
    >>%>
  }
  >>
end writeOutputVars;

//template for write parameter values
template writeoutputparams(ModelInfo modelInfo,SimCode simCode, Boolean useFlatArrayNotation)

::=
match modelInfo
case MODELINFO(vars=SIMVARS(__),varInfo=VARINFO(__)) then
 let &varDeclsCref = buffer "" /*BUFD*/

 <<
     const int paramVarsStart = 1;
     const int intParamVarsStart  = paramVarsStart       + <%numProtectedRealParamVars(modelInfo)%>;
     const int boolparamVarsStart    = intParamVarsStart  + <%numProtectedIntParamVars(modelInfo)%>;



     <%vars.paramVars         |> SIMVAR(isProtected=false) hasindex i0 =>'params(paramVarsStart+<%i0%>)=<%cref(name, useFlatArrayNotation)%>;';align=8 %>
     <%vars.intParamVars |> SIMVAR(isProtected=false) hasindex i0 =>'params(intParamVarsStart+<%i0%>)=<%cref(name, useFlatArrayNotation)%>;';align=8 %>
     <%vars.boolParamVars      |> SIMVAR(isProtected=false) hasindex i1 =>'params(boolparamVarsStart+<%i1%>)=<%cref(name, useFlatArrayNotation)%>;';align=8%>



 >>
end writeoutputparams;
//const int stringParamVarsStart   = boolparamVarsStart    + <%varInfo.numBoolParams%>;
 //<%vars.stringParamVars     |> SIMVAR(__) hasindex i2 =>'params(stringParamVarsStart+<%i2%>)=<%cref(name, useFlatArrayNotation)%>;';align=8 %>
template saveall(ModelInfo modelInfo, SimCode simCode, Boolean useFlatArrayNotation)

::=
match simCode
case SIMCODE(modelInfo = MODELINFO(vars = vars as SIMVARS(__)))
  then
  let n_vars = intAdd( intAdd(listLength(vars.algVars), listLength(vars.discreteAlgVars)), intAdd( listLength(vars.intAlgVars) , intAdd(listLength(vars.boolAlgVars ), listLength(vars.stateVars ))))
  <<
    void <%lastIdentOfPath(modelInfo.name)%>::saveAll()
    {
      unsigned int n = <%n_vars%>;
      double  pre_vars[] = {
      <%{(vars.algVars |> SIMVAR(__) =>
        '<%cref(name, useFlatArrayNotation)%>'
      ;separator=","; align=10;alignSeparator=",\n"  ),
      (vars.discreteAlgVars |> SIMVAR(__) =>
       '<%cref(name, useFlatArrayNotation)%>'
      ;separator=","; align=10;alignSeparator=",\n"  ),
      (vars.intAlgVars |> SIMVAR(__) =>
       '<%cref(name, useFlatArrayNotation)%>'
      ;separator=","; align=10;alignSeparator=",\n"  ),
      (vars.boolAlgVars |> SIMVAR(__) =>
        '<%cref(name, useFlatArrayNotation)%>'
      ;separator=","; align=10;alignSeparator=",\n"  ),
      (vars.stateVars |> SIMVAR(__)   =>
        '__z[<%index%>]'
      ;separator=","; align=10;alignSeparator=",\n"   )}
     ;separator=","%>
     };
        _event_handling.savePreVars(pre_vars,n);
    }
  >>
  /*
  //save all zero crossing condtions
   <%saveconditionvar(zeroCrossings,simCode)%>
   */
end saveall;

template initPrevars(ModelInfo modelInfo, SimCode simCode, Boolean useFlatArrayNotation)

::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo=VARINFO(numAlgVars= numAlgVars, numDiscreteReal=numDiscreteReal, numIntAlgVars = numIntAlgVars, numBoolAlgVars = numBoolAlgVars), vars = vars as SIMVARS(__)))
  then
  let n1 = numAlgVars
  let n2 = intAdd(numAlgVars, numDiscreteReal)
  let n3 = intAdd(intAdd(numAlgVars, numDiscreteReal),numIntAlgVars)
  let n4 = intAdd(intAdd(intAdd(numAlgVars, numDiscreteReal),numIntAlgVars), numBoolAlgVars)
  <<
    void <%lastIdentOfPath(modelInfo.name)%>::initPreVars(unordered_map<string,unsigned int>& vars1, unordered_map<string,unsigned int>& vars2)
    {
      insert( vars1 )
      <%{(vars.algVars |> SIMVAR(__) hasindex i0  =>
        '("<%cref(name, useFlatArrayNotation)%>",<%i0%>)'
      ;separator=" "; align=10;alignSeparator=";\n insert( vars1 ) \n"  ),
      (vars.discreteAlgVars |> SIMVAR(__)  hasindex i1  =>
       '("<%cref(name, useFlatArrayNotation)%>",(<%i1%>+<%n1%>))'
      ;separator=" "; align=10;alignSeparator=";\n insert( vars1 ) \n"  ),
      (vars.intAlgVars |> SIMVAR(__)  hasindex i2  =>
       '("<%cref(name, useFlatArrayNotation)%>",(<%i2%>+<%n2%>))'
      ;separator=" "; align=10;alignSeparator=";\n insert( vars1 ) \n"  ),
      (vars.boolAlgVars |> SIMVAR(__) hasindex i3=>
        '("<%cref(name, useFlatArrayNotation)%>",(<%i3%>+<%n3%>))'
      ;separator=" "; align=10;alignSeparator=";\n insert( vars1 ) \n"  ),
      (vars.stateVars |> SIMVAR(__) hasindex i4  =>
        '("<%cref(name, useFlatArrayNotation)%>",(<%i4%>+<%n4%>))'
      ;separator=" "; align=10;alignSeparator="\n"   )}
     ;separator=" "%>;



      insert( vars2 )
      <%{
       (vars.algVars |> SIMVAR(__) hasindex i0 =>
        '("<%cref(name, useFlatArrayNotation)%>",<%i0%>)'
      ;separator=" ";align=10;alignSeparator=";\n insert( vars2 ) \n"),
      (vars.discreteAlgVars |> SIMVAR(__) hasindex i1=>
       '("<%cref(name, useFlatArrayNotation)%>",(<%i1%>+<%n1%>))'
      ;separator=" ";align=10;alignSeparator=";\n insert( vars2 ) \n"),
      (vars.intAlgVars |> SIMVAR(__) hasindex i2=>
       '("<%cref(name, useFlatArrayNotation)%>",(<%i2%>+<%n2%>))'
      ;separator=" ";align=10;alignSeparator=";\n insert( vars2 ) \n"),
      (vars.boolAlgVars |> SIMVAR(__) hasindex i3 =>
        '("<%cref(name, useFlatArrayNotation)%>",(<%i3%>+<%n3%>))'
      ;separator=" ";align=10;alignSeparator=";\n insert( vars2 ) \n")}
     ;separator=" ";align=10;alignSeparator=" \n"
     %>;



    }
  >>
 end initPrevars;



/*
<%{(vars.algVars |> SIMVAR(__) =>
        '_event_handling.save(<%cref(name)%>,"<%cref(name)%>");'
      ;separator="\n"),
      (vars.intAlgVars |> SIMVAR(__) =>
       '_event_handling.save(<%cref(name)%>,"<%cref(name)%>");'
      ;separator="\n"),
      (vars.boolAlgVars |> SIMVAR(__) =>
        '_event_handling.save(<%cref(name)%>,"<%cref(name)%>");'
      ;separator="\n"),
      (vars.stateVars |> SIMVAR(__) =>
        '_event_handling.save(__z[<%index%>],"<%cref(name)%>");'
      ;separator="\n")}
     ;separator="\n"%>

     _event_handling.saveH();
   */
template savediscreteVars(ModelInfo modelInfo, SimCode simCode, Boolean useFlatArrayNotation)

::=
match simCode
case SIMCODE(modelInfo = MODELINFO(vars = vars as SIMVARS(__)))
  then
  let n_vars = intAdd(intAdd(listLength(vars.algVars), listLength(vars.discreteAlgVars)), intAdd( listLength(vars.intAlgVars) , listLength(vars.boolAlgVars )))
  let modelname = lastIdentOfPath(modelInfo.name)
  match n_vars
  case "0" then
  <<
    void <%modelname%>::saveDiscreteVars()
    {
    }
  >>
  else
  <<
    void <%modelname%>::saveDiscreteVars()
    {
       unsigned int n = <%n_vars%>;
       double  pre_vars[] = {
      <%{
       (vars.algVars |> SIMVAR(__) =>
        '<%cref(name,useFlatArrayNotation)%>'
      ;separator=",";align=10;alignSeparator=",\n"),
      (vars.discreteAlgVars |> SIMVAR(__) =>
       '<%cref(name, useFlatArrayNotation)%>'
      ;separator=",";align=10;alignSeparator=",\n"),
      (vars.intAlgVars |> SIMVAR(__) =>
       '<%cref(name, useFlatArrayNotation)%>'
      ;separator=",";align=10;alignSeparator=",\n"),
      (vars.boolAlgVars |> SIMVAR(__) =>
        '<%cref(name, useFlatArrayNotation)%>'
      ;separator=",";align=10;alignSeparator=",\n")}
     ;separator=",";align=10;alignSeparator=",\n"%>
       };
     _event_handling.saveDiscretPreVars(pre_vars,n);

    }
  >>
 end savediscreteVars;




template initAlgloopvars( Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,ModelInfo modelInfo,SimCode simCode,Context context,Boolean useFlatArrayNotation)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  let &varDecls = buffer "" /*BUFD*/

 let algvars =initValst(varDecls,"Real",vars.algVars, simCode,context,useFlatArrayNotation)
 let discretealgvars = initValst(varDecls,"Real",vars.discreteAlgVars, simCode,context,useFlatArrayNotation)
 let intvars = initValst(varDecls,"Int",vars.intAlgVars, simCode,context,useFlatArrayNotation)
 let boolvars = initValst(varDecls,"Bool",vars.boolAlgVars, simCode,context,useFlatArrayNotation)
 <<
  <%varDecls%>

  <%algvars%>
  <%discretealgvars%>
  <%intvars%>
  <%boolvars%>
  >>
end initAlgloopvars;

template boundParameters(list<SimEqSystem> parameterEquations,Text &varDecls,SimCode simCode,Boolean useFlatArrayNotation)
 "Generates function in simulation file."
::=

  let &tmp = buffer ""
  let body = (parameterEquations |> eq as SES_SIMPLE_ASSIGN(__) =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFD*/, simCode,useFlatArrayNotation)
    ;separator="\n")
  let divbody = (parameterEquations |> eq as SES_ALGORITHM(__) =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFD*/, simCode,useFlatArrayNotation)
    ;separator="\n")
  <<

    <%body%>
    <%divbody%>
   >>
end boundParameters;
/*
template outputIndices(ModelInfo modelInfo)
::= match modelInfo
case MODELINFO(varInfo=VARINFO(__),vars=SIMVARS(__)) then
    if varInfo.numOutVars then
    <<
    var_ouputs_idx=<%
    {(vars.algVars |> SIMVAR(__) => if isOutput(causality) then '<%index%>';separator=","),
    (vars.discreteAlgVars |> SIMVAR(__) => if isOutput(causality) then '<%index%>';separator=","),
    (vars.intAlgVars |> SIMVAR(__) => if isOutput(causality) then '<%numAlgvar(modelInfo)%>+<%index%>';separator=","),
    (vars.boolAlgVars |> SIMVAR(__) => if isOutput(causality) then '<%numAlgvar(modelInfo)%>+<%numIntAlgvar(modelInfo)%>+<%index%>';separator=","),
    (vars.stateVars  |> SIMVAR(__) => if isOutput(causality) then '<%numAlgvars(modelInfo)%>+<%index%>';separator=","),
    (vars.derivativeVars  |> SIMVAR(__) => if isOutput(causality) then '<%numAlgvars(modelInfo)%>+<%numStatevars(modelInfo)%>+<%index%>';separator=",")};separator=","%>;
    >>
end outputIndices;
*/

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



template initValstWithSplit(Text &varDecls /*BUFP*/, Text type ,Text funcNamePrefix, list<SimVar> varsLst, SimCode simCode, Context context, Boolean useFlatArrayNotation) ::=
  let &funcCalls = buffer "" /*BUFD*/
  let extraFuncs = List.partition(varsLst, 100) |> ls hasindex idx =>
    let &varDecls = buffer "" /*BUFD*/
    let &funcCalls += '<%funcNamePrefix%>_<%idx%>();'
    let init = initValst(varDecls, type, ls, simCode, context, useFlatArrayNotation)
    <<
    void <%funcNamePrefix%>_<%idx%>()
    {
       <%varDecls%>
       <%init%>
    }
    >>
    ;separator="\n"

  <<
  <%extraFuncs%>

  void <%funcNamePrefix%>()
  {
    <%funcCalls%>
  }
  >>
end initValstWithSplit;


template initValst(Text &varDecls /*BUFP*/,Text type, list<SimVar> varsLst, SimCode simCode, Context context, Boolean useFlatArrayNotation) ::=
   varsLst |> sv as SIMVAR(__) =>
   //varsLst |> sv as SIMVAR(numArrayElement={}) =>
     let &preExp = buffer "" /*BUFD*/
      let &varDeclsCref = buffer "" /*BUFD*/
    match initialValue
      case SOME(v) then
      match daeExp(v, contextOther, &preExp, &varDecls,simCode,useFlatArrayNotation)
      case vStr as "0"
      case vStr as "0.0"
      case vStr as "(0)" then
       '<%preExp%>
       set<%type%>StartValue(<%cref1(sv.name,simCode,context,varDeclsCref,useFlatArrayNotation)%>,<%vStr%>,"<%cref(sv.name, useFlatArrayNotation)%>");'
      case vStr as "" then
       '<%preExp%>
        set<%type%>StartValue(<%cref1(sv.name,simCode,context,varDeclsCref,useFlatArrayNotation)%>,<%vStr%>,"<%cref(sv.name, useFlatArrayNotation)%>");'
      case vStr then
       '<%preExp%>
       set<%type%>StartValue(<%cref1(sv.name,simCode,context,varDeclsCref,useFlatArrayNotation)%>,<%vStr%>,"<%cref(sv.name, useFlatArrayNotation)%>");'
        end match
      else
        '<%preExp%>
       set<%type%>StartValue(<%cref1(sv.name,simCode,context,varDeclsCref,useFlatArrayNotation)%>,<%startValue(sv.type_)%> ,"<%cref(sv.name, useFlatArrayNotation)%>");'
      ;separator="\n"
end initValst;
/*
template initValst(Text &varDecls , list<SimVar> varsLst, SimCode simCode, Context context, Boolean useFlatArrayNotation) ::=
  varsLst |> sv as SIMVAR(__) =>
      let &preExp = buffer ""
      let &varDeclsCref = buffer ""
    match initialValue
      case SOME(v) then
      match daeExp(v, contextOther, &preExp, &varDecls,simCode,useFlatArrayNotation)
      case vStr as "0"
      case vStr as "0.0"
      case vStr as "(0)" then
       '<%preExp%>
        <%cref1(sv.name,simCode,context,varDeclsCref,useFlatArrayNotation)%>=<%vStr%>;//<%cref(sv.name, useFlatArrayNotation)%>
       _start_values["<%cref(sv.name)%>"]=<%vStr%>;'
      case vStr as "" then
       '<%preExp%>
       <%cref1(sv.name,simCode,context,varDeclsCref,useFlatArrayNotation)%>=0;//<%cref(sv.name, useFlatArrayNotation)%>
        _start_values["<%cref(sv.name)%>"]=<%vStr%>;'
      case vStr then
       '<%preExp%>
       <%cref1(sv.name,simCode,context,varDeclsCref,useFlatArrayNotation)%>=<%vStr%>;//<%cref(sv.name, useFlatArrayNotation)%>
       _start_values["<%cref(sv.name)%>"]=<%vStr%>;'
        end match
      else
        '<%preExp%>
        <%cref1(sv.name,simCode,context,varDeclsCref,useFlatArrayNotation)%>=<%startValue(sv.type_)%>;////<%crefStr(sv.name)%>
       _start_values["<%cref(sv.name, useFlatArrayNotation)%>"]=<%startValue(sv.type_)%>;'
  ;separator="\n"
end initValst;
*/
/*
template initAliasValst(Text &varDecls ,list<SimVar> varsLst, SimCode simCode, Context context, Boolean useFlatArrayNotation) ::=
  varsLst |> sv as SIMVAR(__) =>
      let &preExp = buffer ""
      let &varDeclsCref = buffer ""
    match initialValue
      case SOME(v) then
      match daeExp(v, contextOther, &preExp, &varDecls,simCode, useFlatArrayNotation)
      case vStr as "0"
      case vStr as "0.0"
      case vStr as "(0)" then
       '<%preExp%>
        <%getAliasVarName(sv.aliasvar, simCode,context)%>=<%vStr%>;//<%cref(sv.name, useFlatArrayNotation)%>
       _start_values["<%cref(sv.name)%>"]=<%vStr%>;'
      case vStr as "" then
       '<%preExp%>
       <%getAliasVarName(sv.aliasvar, simCode,context)%>=0;//<%cref(sv.name, useFlatArrayNotation)%>
        _start_values["<%cref(sv.name)%>"]=<%vStr%>;'
      case vStr then
       '<%preExp%>
       <%getAliasVarName(sv.aliasvar, simCode,context)%>=<%vStr%>;//<%cref(sv.name, useFlatArrayNotation)%>
       _start_values["<%cref(sv.name)%>"]=<%vStr%>;'
        end match
      else
        '<%preExp%>
        <%getAliasVarName(sv.aliasvar, simCode,context)%>=<%startValue(sv.type_)%>;////<%crefStr(sv.name)%>
       _start_values["<%cref(sv.name, useFlatArrayNotation)%>"]=<%startValue(sv.type_)%>;'
  ;separator="\n"
end initAliasValst;
*/
template initAliasValst(Text &varDecls ,Text type,list<SimVar> varsLst, SimCode simCode, Context context, Boolean useFlatArrayNotation) ::=
  varsLst |> sv as SIMVAR(__) =>

      let &varDeclsCref = buffer "" /*BUFD*/
    match initialValue
      case SOME(v) then
       let &preExp = buffer "" /*BUFD*/
      match daeExp(v, contextOther, &preExp, &varDecls,simCode, useFlatArrayNotation)
      case vStr as "0"
      case vStr as "0.0"
      case vStr as "(0)" then
       '<%preExp%>
        set<%type%>StartValue(<%getAliasVarName(sv.aliasvar, simCode,context, useFlatArrayNotation)%>,<%vStr%>,"<%cref(sv.name, useFlatArrayNotation)%>");'


      case vStr as "" then
       '<%preExp%>
        set<%type%>StartValue(<%getAliasVarName(sv.aliasvar, simCode,context, useFlatArrayNotation)%>,<%vStr%>,"<%cref(sv.name, useFlatArrayNotation)%>");'

      case vStr then
       '<%preExp%>
       set<%type%>StartValue(<%getAliasVarName(sv.aliasvar, simCode,context, useFlatArrayNotation)%>,<%vStr%>,"<%cref(sv.name, useFlatArrayNotation)%>");'
           end match
      else
       let &preExp = buffer "" /*BUFD*/
       let initval = getAliasInitVal(sv.aliasvar, contextOther, &preExp, &varDecls,simCode,useFlatArrayNotation)
        '<%preExp%>
         set<%type%>StartValue(<%getAliasVarName(sv.aliasvar, simCode,context,useFlatArrayNotation)%>,<%initval%>,"<%cref(sv.name, useFlatArrayNotation)%>");'
    ;separator="\n"
end initAliasValst;

template getAliasInitVal(AliasVariable aliasvar,Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/, SimCode simCode, Boolean useFlatArrayNotation)
 "Returns the alias Attribute of ScalarVariable."
::=
   match aliasvar
    case NOALIAS(__) then 'noAlias'
    case ALIAS(__) then  getAliasInitVal2(varName, context, preExp, varDecls,simCode,useFlatArrayNotation)
    case NEGATEDALIAS(__) then  getAliasInitVal2(varName,context, preExp , varDecls ,simCode, useFlatArrayNotation)
    else 'noAlias'

end getAliasInitVal;

template getAliasInitVal2(ComponentRef aliascref,Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/, SimCode simCode, Boolean useFlatArrayNotation)
 "Returns the alias Attribute of ScalarVariable."
::=
cref2simvar(aliascref, simCode) |> var  as SIMVAR(__)=>
 match initialValue
      case SOME(v) then
     daeExp(v, context, &preExp, &varDecls,simCode, useFlatArrayNotation)
     else
      startValue(var.type_)
end getAliasInitVal2;


//template initValst1(list<SimVar> varsLst, SimCode simCode) ::=
  //varsLst |> sv as SIMVAR(__) =>
    // match aliasvar
      //case ALIAS(__) then
       //'<%cref1(sv.name,simCode)%>=$<%crefStr(varName)%>;'
       //else
      //'<%initValst(varsLst,simCode)%>'
//end initValst1;

template startValue(DAE.Type ty)
::=
  match ty
  case ty as T_INTEGER(__) then '0'
  case ty as T_REAL(__) then '0.0'
  case ty as T_BOOL(__) then 'false'
  case ty as T_STRING(__) then 'empty'
   case ty as T_ENUMERATION(__) then '0'
  else ""
end startValue;


template eventHandlingInit(SimCode simCode)

::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__))) then
  <<
      <% match vi.numZeroCrossings
      case 0 then ""
      else
        'bool events[<%vi.numZeroCrossings%>];
       memset(events,true,<%vi.numZeroCrossings%>);
      for(int i=0;i<=<%vi.numZeroCrossings%>;++i) { handleEvent(events); }'
      %>
  >>
end eventHandlingInit;


template dimension1(SimCode simCode)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__)))
then
    <<
    _dimContinuousStates = <%vi.numStateVars%>;
    _dimRHS = <%vi.numStateVars%>;
    _dimBoolean = <%vi.numBoolAlgVars%> + <%vi.numBoolParams%>;
    _dimInteger = <%vi.numIntAlgVars%>  + <%vi.numIntParams%>;
    _dimString = <%vi.numStringAlgVars%> + <%vi.numStringParamVars%>;
    _dimReal = <%vi.numAlgVars%> + <%vi.numDiscreteReal%> + <%vi.numParams%>;
    >>
end dimension1;

template isODE(SimCode simCode)
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
  case T_COMPLEX(__)     then 'ComplexType'
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

template contextCref(ComponentRef cr, Context context,SimCode simCode, Boolean useFlatArrayNotation)
  "Generates code for a component reference depending on which context we're in."
::=
match cr
case CREF_QUAL(ident = "$PRE") then
   '_event_handling.pre(<%contextCref(componentRef,context,simCode,useFlatArrayNotation)%>,"<%cref(componentRef, useFlatArrayNotation)%>")'
 else
  let &varDeclsCref = buffer "" /*BUFD*/
  match context
  case FUNCTION_CONTEXT(__) then System.unquoteIdentifier(crefStr(cr))
  else '<%cref1(cr,simCode,context,varDeclsCref,useFlatArrayNotation)%>'
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

template functionInitial(list<SimEqSystem> startValueEquations,Text &varDecls,SimCode simCode,Boolean useFlatArrayNotation)

::=


  let eqPart = (startValueEquations |> eq as SES_SIMPLE_ASSIGN(__) =>
      equation_(eq, contextSimulationDiscrete, &varDecls,simCode,useFlatArrayNotation)
    ;separator="\n")
  <<

    <%eqPart%>
  >>
end functionInitial;


template equation_(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case e as SES_SIMPLE_ASSIGN(__)
    then equationSimpleAssign(e, context,&varDecls,simCode,useFlatArrayNotation)
  case e as SES_ALGORITHM(__)
    then equationAlgorithm(e, context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  case e as SES_WHEN(__)
    then equationWhen(e, context, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  case e as SES_ARRAY_CALL_ASSIGN(__)
    then equationArrayCallAssign(e, context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  case e as SES_LINEAR(__)
  case e as SES_NONLINEAR(__)

    then

    let i = index
    match context
    case  ALGLOOP_CONTEXT(genInitialisation=true)
    then
    <<



      try
      {
        _algLoopSolver<%index%>->initialize();
        _algLoop<%index%>->evaluate();
         for(int i=0;i<_dimZeroFunc;i++)
          {
             getCondition(i);
          }
          IContinuous::UPDATETYPE calltype = _callType;
         _callType = IContinuous::CONTINUOUS;
        _algLoopSolver<%index%>->solve();
          _callType = calltype;
      }
      catch(std::exception &ex)
      {

          throw std::invalid_argument("Nonlinear solver stopped at time " + boost::lexical_cast<string>(_simTime) + " with error: " + ex.what());
      }

    >>
    else
    <<

    bool restart<%index%>=true;
    bool* conditions0<%index%> = new bool[_dimZeroFunc];
    bool* conditions1<%index%> = new bool[_dimZeroFunc];
    unsigned int iterations<%index%> = 0;
    unsigned int dim<%index%> =   _algLoop<%index%>->getDimReal();
    double* algloop<%index%>Vars = new double[dim<%index%>];
    _algLoop<%index%>->getReal(algloop<%index%>Vars );
    bool restatDiscrete<%index%>= false;
    try
      {

         _algLoop<%index%>->evaluate();


          if( _callType == IContinuous::DISCRETE )
          {
             while(restart<%index%> && !(iterations<%index%>++>500))
             {

              getConditions(conditions0<%index%>);
                _callType = IContinuous::CONTINUOUS;
              _algLoopSolver<%index%>->solve();
             _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                 getCondition(i);
              }

              getConditions(conditions1<%index%>);
              restart<%index%> = !std::equal (conditions1<%index%>, conditions1<%index%>+_dimZeroFunc,conditions0<%index%>);
            }
          }
          else
             _algLoopSolver<%index%>->solve();

      }
      catch(std::exception &ex)
       {

          restatDiscrete<%index%>=true;

       }

       if((restart<%index%>&& iterations<%index%> > 0)|| restatDiscrete<%index%>)
       {
            try
             {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
                IContinuous::UPDATETYPE calltype = _callType;
               _callType = IContinuous::DISCRETE;
                 _algLoop<%index%>->setReal(algloop<%index%>Vars );
                _algLoopSolver<%index%>->solve();
               _callType = calltype;
             }
             catch(std::exception &ex)
             {
                delete[] algloop<%index%>Vars;
                delete[] conditions0<%index%>;
                delete[] conditions1<%index%>;
                throw std::invalid_argument("Nonlinear solver stopped at time " + boost::lexical_cast<string>(_simTime) + " with error: " + ex.what());
             }

       }
        delete[] algloop<%index%>Vars;
        delete[] conditions0<%index%>;
        delete[] conditions1<%index%>;
      >>
    end match


  case e as SES_MIXED(__)
    /*<%equationMixed(e, context, &varDecls, simCode)%>*/
    then
    <<


        throw std::runtime_error("Mixed systems are not supported yet");
     >>
  else
    "NOT IMPLEMENTED EQUATION"
end equation_;
/*ranking: removed from equation_ before try block:
   if(!(command & IContinuous::RANKING))
    {

     }
       else _algLoop<%i%>->initialize();
 */



template equation_function_call(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode,Text method)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=

    let ix_str = equationIndex(eq)
     <<
      <%method%>_<%ix_str%>();
    >>

end equation_function_call;

template equation_function_create_single_func(SimEqSystem eq, Context context, SimCode simCode,Text method,Text classnameext, Boolean useFlatArrayNotation, Boolean createMeasureTime, Boolean enableMeasureTime)
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
      equationSimpleAssign(e, context,&varDeclsLocal,simCode,useFlatArrayNotation)
   case e as SES_IFEQUATION(__)
    then "SES_IFEQUATION"
   case e as SES_ALGORITHM(__)
      then
      equationAlgorithm(e, context, &varDeclsLocal,simCode, useFlatArrayNotation)
   case e as SES_WHEN(__)
      then
      equationWhen(e, context, &varDeclsLocal,simCode, useFlatArrayNotation)
    case e as SES_ARRAY_CALL_ASSIGN(__)
      then
      equationArrayCallAssign(e, context, &varDeclsLocal,simCode, useFlatArrayNotation)
    case e as SES_LINEAR(__)
    case e as SES_NONLINEAR(__)
      then
      equationLinearOrNonLinear(e, context, &varDeclsLocal,simCode)
    case e as SES_MIXED(__)
      then
      /*<%equationMixed(e, context, &varDeclsLocal, simCode)%>*/
      let &additionalFuncs += equation_function_create_single_func(e.cont,context,simCode,method,classnameext, useFlatArrayNotation, false, true)
      "throw std::runtime_error(\"Mixed systems are not supported yet\");"
    else
      "NOT IMPLEMENTED EQUATION"
  end match
  let &measureTimeStartVar += if boolAnd(boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")),createMeasureTime) then generateMeasureTimeStartCode("measuredProfileBlockStartValues") //else ""
  let &measureTimeEndVar += if boolAnd(boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")),createMeasureTime) then generateMeasureTimeEndCode("measuredProfileBlockStartValues", "measuredProfileBlockEndValues", 'measureTimeProfileBlocksArray[<%ix_str_array%>]') //else ""
  <<
    <%additionalFuncs%>
    /*
    <%dumpEqs(fill(eq,1))%>
    */
    void <%lastIdentOfPathFromSimCode(simCode)%><%classnameext%>::<%method%>_<%ix_str%>()
    {
      <%varDeclsLocal%>

      <%if(enableMeasureTime) then measureTimeStartVar else ''%>
      <%body%>
      <%if(enableMeasureTime) then measureTimeEndVar else ''%>
    }
  >>

end equation_function_create_single_func;

template equationMixed(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/, SimCode simCode, Boolean useFlatArrayNotation)
 "Generates a mixed equation system."
::=
match eq
case SES_MIXED(__) then
  let contEqs = equation_(cont, context, &varDecls /*BUFD*/, simCode, useFlatArrayNotation)
  let numDiscVarsStr = listLength(discVars)
//  let valuesLenStr = listLength(values)
  let &preDisc = buffer "" /*BUFD*/
  let num = index
  let discvars2 = (discEqs |> SES_SIMPLE_ASSIGN(__) hasindex i0 =>
      let expPart = daeExp(exp, context, &preDisc /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
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
       restart<%num%>=!(_event_handling.CheckDiscreteValues(values<%num%>,pre_disc_vars<%num%>,new_disc_vars<%num%>,cur_disc_vars<%num%>,<%numDiscVarsStr%>,iter<%num%>,<%valuesLenStr%>));
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

template generateStepCompleted(list<SimEqSystem> allEquations,SimCode simCode, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver =   generateStepCompleted2(allEquations,simCode)
  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
let store_delay_expr = functionStoreDelay(delayedExps,simCode, useFlatArrayNotation)
  <<
  bool <%lastIdentOfPath(modelInfo.name)%>::stepCompleted(double time)
  {
   <%algloopsolver%>
     <%store_delay_expr%>
   saveAll();
   return _terminate;
   }
  >>

end generateStepCompleted;


template generatehandleTimeEvent(list<BackendDAE.TimeEvent> timeEvents, SimCode simCode)
::=

  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
  <<
  void <%lastIdentOfPath(modelInfo.name)%>::handleTimeEvent(int* time_events)
  {
    for(int i=0; i<_dimTimeEvent; i++)
    {
      if(time_events[i] != _time_event_counter[i])
        _time_conditions[i] = true;
      else
        _time_conditions[i] = false;
    }
    memcpy(_time_event_counter, time_events, (int)_dimTimeEvent*sizeof(int));
  }
  >>

end generatehandleTimeEvent;

template generateDimTimeEvent(list<SimEqSystem> allEquations,SimCode simCode)
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


template generateTimeEvent(list<BackendDAE.TimeEvent> timeEvents, SimCode simCode, Boolean useFlatArrayNotation)
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
              let e1 = daeExp(startExp, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
              let e2 = daeExp(intervalExp, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
              <<
              <%preExp%>
              time_events.push_back(std::make_pair(<%e1%>, <%e2%>));
              >>
            else ''
          ;separator="\n\n")%>
       }
      >>
end generateTimeEvent;




template generateStepCompleted2(list<SimEqSystem> allEquations,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (allEquations |> eqs => (eqs |> eq =>
      generateStepCompleted3(eq, contextOther, &varDecls /*BUFC*/,simCode) ;separator="\n")
    ;separator="\n")

  <<
   <%algloopsolver%>
  >>

end generateStepCompleted2;


template generateStepCompleted3(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case SES_LINEAR(__)
  case e as SES_NONLINEAR(__)
    then
  let num = index
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
    _algLoopSolver<%num%>->stepCompleted(_simTime);
   >>
   end match
  case e as SES_MIXED(cont = eq_sys)
  then
   <<
   <%generateStepCompleted3(eq_sys,context,varDecls,simCode)%>
   >>
  else
    ""
 end generateStepCompleted3;



template generateAlgloopsolvers(list<SimEqSystem> allEquations,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (allEquations |> eqs => (eqs |> eq =>
      generateAlgloopsolvers2(eq, contextOther, &varDecls /*BUFC*/,simCode) ;separator="\n")
    ;separator="\n")

  <<
   <%algloopsolver%>
  >>

end generateAlgloopsolvers;


template generatefriendAlgloops(list<SimEqSystem> allEquations, SimCode simCode)
 ::=
    let friendalgloops = (allEquations |> eqs => (eqs |> eq =>
      generatefriendAlgloops2(eq, simCode) ;separator="\n")
    ;separator="\n")
  <<
  <%friendalgloops%>
  >>
 end generatefriendAlgloops;


 template generatefriendAlgloops2(SimEqSystem eq, SimCode simCode)
 ::=
  match eq
  case SES_LINEAR(__)
  case e as SES_NONLINEAR(__)
    then
  let num = index
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
  friend class <%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>;
   >>
   end match
  case e as SES_MIXED(cont = eq_sys)
  then
   <<
   <%generatefriendAlgloops2(eq_sys,simCode)%>
   >>
  else
    ""
 end generatefriendAlgloops2;



template generateAlgloopsolvers2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case SES_LINEAR(__)
  case e as SES_NONLINEAR(__)
    then
  let num = index
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  <<

  _algLoop<%num%> =  boost::shared_ptr<IAlgLoop>(new <%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>(this,__z,__zDot,_conditions,_event_handling )
                                                                                                                                  );
  _algLoopSolver<%num%> = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop<%num%>.get()));
   >>
   end match
  case e as SES_MIXED(cont = eq_sys)
  then
   <<
   <%generateAlgloopsolvers2(eq_sys,context,varDecls,simCode)%>
   >>
  else
    ""
 end generateAlgloopsolvers2;

//_algLoop<%num%> =  boost::shared_ptr<<%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>>(new <%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>(this,__z,__zDot,_conditions,_event_handling )

template generateAlgloopsolverVariables(list<SimEqSystem> allEquationsPlusWhen,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (allEquationsPlusWhen |> eqs => (eqs |> eq =>
      generateAlgloopsolverVariables2(eq, contextOther, &varDecls /*BUFC*/,simCode);separator="\n")
    ;separator="\n")

  <<
  <%algloopsolver%>
  >>
end generateAlgloopsolverVariables;


template generateAlgloopsolverVariables2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
   case SES_LINEAR(__)
  case e as SES_NONLINEAR(__)
    then
  let num = index
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
     boost::shared_ptr<IAlgLoop>  //Algloop  which holds equation system
        _algLoop<%num%>;
    boost::shared_ptr<IAlgLoopSolver>
        _algLoopSolver<%num%>;        ///< Solver for algebraic loop */
   >>
   end match
   case e as SES_MIXED(cont = eq_sys)
  then
   <<
   <%generateAlgloopsolverVariables2(eq_sys,context,varDecls,simCode)%>
   >>
  else
    ""
 end generateAlgloopsolverVariables2;

// boost::shared_ptr<<%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>>  //Algloop  which holds equation system
template initAlgloopsolvers(list<list<SimEqSystem>> continousEquations,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (continousEquations |> eqs => (eqs |> eq =>
      initAlgloopsolvers2(eq, contextOther, &varDecls /*BUFC*/,simCode))
    ;separator="\n")

  <<
  <%algloopsolver%>
  >>
end initAlgloopsolvers;


template initAlgloopsolver(list<SimEqSystem> equations,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (equations |> eq =>
      initAlgloopsolvers2(eq, contextOther, &varDecls /*BUFC*/,simCode)
    ;separator="\n")

  <<
  <%algloopsolver%>
  >>
end initAlgloopsolver;


template initAlgloopsolvers2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
   case SES_LINEAR(__)
  case e as SES_NONLINEAR(__)
    then
  let num = index
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
      // Initialize the solver
    if(_algLoopSolver<%num%>)
        _algLoopSolver<%num%>->initialize();
  >>
   end match
   case e as SES_MIXED(cont = eq_sys)
  then
   <<
   <%initAlgloopsolvers2(eq_sys,context,varDecls,simCode)%>
   >>
  else
    " "
 end initAlgloopsolvers2;


template algloopForwardDeclaration(list<SimEqSystem> allEquations,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  <<
  <% allEquations |> eqs => (eqs |> eq =>
      algloopForwardDeclaration2(eq, contextOther, &varDecls /*BUFC*/,simCode) ;separator="\n" )
    ;separator="\n" %>
  >>
end algloopForwardDeclaration;

template algloopForwardDeclaration2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode)
::=
  match eq
   case SES_LINEAR(__)
  case e as SES_NONLINEAR(__)
    then
      let num = index
      match simCode
          case SIMCODE(modelInfo = MODELINFO(__)) then
          <<
          class <%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>;
          >>
   end match
  case e as SES_MIXED(cont = eq_sys)
  then
   <<
   <%algloopForwardDeclaration2(eq_sys,context,varDecls,simCode)%>
   >>
  else
       ""
end algloopForwardDeclaration2;

template algloopfilesInclude(list<SimEqSystem> allEquations,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  <<
  <% allEquations |> eqs => (eqs |> eq =>
      algloopfilesInclude2(eq, contextOther, &varDecls /*BUFC*/,simCode) ;separator="\n" )
    ;separator="\n" %>
  >>
end algloopfilesInclude;

template algloopfilesInclude2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
   case SES_LINEAR(__)
  case e as SES_NONLINEAR(__)
    then
      let num = index
      match simCode
          case SIMCODE(modelInfo = MODELINFO(__)) then
         <<#include "OMCpp<%fileNamePrefix%>Algloop<%num%>.h">>
   end match
  case e as SES_MIXED(cont = eq_sys)
  then
   <<
   <%algloopfilesInclude2(eq_sys,context,varDecls,simCode)%>
   >>
  else
       ""
 end algloopfilesInclude2;

/*
template algloopfiles(list<list<SimEqSystem>> continousEquations,list<SimEqSystem> discreteEquations,list<SimWhenClause> whenClauses,list<SimEqSystem> parameterEquations,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (continousEquations |> eqs => (eqs |> eq =>
      algloopfiles2(eq, contextOther, &varDecls /*BUFC*/,simCode))
    ;separator="\n")

  <<
  <%algloopsolver%>
  >>
end algloopfiles;
*/




// use allEquations instead of odeEquations, because only allEquations are labeled for reduction algorithms
template algloopfiles(list<SimEqSystem> allEquations, SimCode simCode,Context context, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (allEquations |> eqs =>
      algloopfiles2(eqs, context, &varDecls /*BUFC*/,simCode,useFlatArrayNotation)
    ;separator="\n")

  <<
  <%algloopsolver%>
  >>
end algloopfiles;


template algloopfiles2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case SES_LINEAR(__)
  case e as SES_NONLINEAR(__)
    then
  let num = index
      match simCode
          case SIMCODE(modelInfo = MODELINFO(__)) then
              let()= textFile(algloopHeaderFile(simCode,eq,context,useFlatArrayNotation), 'OMCpp<%fileNamePrefix%>Algloop<%num%>.h')
              let()= textFile(algloopCppFile(simCode,eq,context,useFlatArrayNotation), 'OMCpp<%fileNamePrefix%>Algloop<%num%>.cpp')
            " "
        end match
  case e as SES_MIXED(cont = eq_sys)
    then
       match simCode
          case SIMCODE(modelInfo = MODELINFO(__)) then
              let()= textFile(algloopHeaderFile(simCode, eq_sys,context,useFlatArrayNotation), 'OMCpp<%fileNamePrefix%>Algloop<%algloopfilesindex(eq_sys)%>.h')
              let()= textFile(algloopCppFile(simCode, eq_sys,context,useFlatArrayNotation), 'OMCpp<%fileNamePrefix%>Algloop<%algloopfilesindex(eq_sys)%>.cpp')
            " "
        end match
  else
    " "
 end algloopfiles2;

template algloopMainfile(list<SimEqSystem> allEquations, SimCode simCode,Context context)
::=
  match(simCode)
  case SIMCODE(modelInfo = MODELINFO(__)) then
    let modelname =  lastIdentOfPath(modelInfo.name)
    let filename = fileNamePrefix
    let modelfilename =  match context case  ALGLOOP_CONTEXT(genInitialisation=false,genJacobian=true)  then '<%filename%>Jacobian' else '<%filename%>'

    let jacfiles = (jacobianMatrixes |> (mat, _, _, _, _, _, _) hasindex index0 => (mat |> (eqs,_,_) =>  algloopMainfile1(eqs,simCode,filename) ;separator="") ;separator="")
    let algloopfiles = (listAppend(allEquations,initialEquations) |> eqs => algloopMainfile2(eqs, simCode, filename) ;separator="\n")

    <<
    /*****************************************************************************
    *
    * Helper file that includes all alg-loop files.
    * This file is generated by the OpenModelica Compiler and produced to speed-up the compile time.
    *
    *****************************************************************************/

    #include <Core/Modelica.h>
    #include <Core/ModelicaDefine.h>
    #include "OMCpp<%fileNamePrefix%>Extension.h"
    #include "OMCpp<%modelfilename%>.h"
    #include "OMCpp<%modelfilename%>Functions.h"

    //jac files
    <%jacfiles%>
    //alg loop files
    <%algloopfiles%>
    >>
end algloopMainfile;

template algloopMainfile1(list<SimEqSystem> allEquations, SimCode simCode, String filename)
::=
  let algloopfiles = (allEquations |> eqs => algloopMainfile2(eqs, simCode, filename); separator="\n")
  <<
  <%algloopfiles%>
  >>
end algloopMainfile1;

template algloopMainfile2(SimEqSystem eq, SimCode simCode, String filename)
::=
  match eq
  case SES_LINEAR(__)
  case e as SES_NONLINEAR(__) then
    let num = index
    <<
    #include "OMCpp<%filename%>Algloop<%index%>.h"
    #include "OMCpp<%filename%>Algloop<%index%>.cpp"
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
  case SES_LINEAR(__)
  case e as SES_NONLINEAR(__)
  case e as SES_MIXED(__)
    then
      <<<%index%>>>
  else
    " "
 end algloopfilesindex;

template algloopcppfilenames(list<SimEqSystem> allEquations,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (allEquations |> eqs => (eqs |> eq =>
      algloopcppfilenames2(eq, contextOther, &varDecls /*BUFC*/,simCode))
    ;separator="\t" ;align=10;alignSeparator="\\\n\t"  )

  <<
  <%algloopsolver%>
  >>
end algloopcppfilenames;


template algloopcppfilenames2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
   case SES_LINEAR(__)
  case e as SES_NONLINEAR(__)
    then
  let num = index
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
   <<
   OMCpp<%fileNamePrefix%>Algloop<%num%>.cpp
   >>
   end match
   case e as SES_MIXED(cont = eq_sys)
  then
   <<
   <%algloopcppfilenames2(eq_sys,context,varDecls,simCode)%>
   >>
 else
    ""
 end algloopcppfilenames2;





template equationArrayCallAssign(SimEqSystem eq, Context context,
                                 Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates equation on form 'cref_array = call(...)'."
::=
let &varDeclsCref = buffer "" /*BUFD*/
match eq

case eqn as SES_ARRAY_CALL_ASSIGN(__) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(exp, context, &preExp /*BUF  let &preExp = buffer "" /*BUFD*/
  let &helpInits = buffer "" /*BUFD*/
  let helpIf = (conditions |> (e, hidx) =>
      let helpInit = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
      let &helpInits += 'localData->helpVars[<%hidx%>] = <%helpInit%>;'
      'localData->helpVars[<%hidx%>] && !localData->helpVars_saved[<%hidx%>] /* edge */'
    ;separator=" || ")C*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  match expTypeFromExpShort(eqn.exp)
  case "boolean" then
    let tvar = tempDecl("boolean_array", &varDecls /*BUFD*/)
    //let &preExp += 'cast_integer_array_to_real(&<%expPart%>, &<%tvar%>);<%\n%>'
    <<
    <%preExp%>
    <%cref1(eqn.componentRef,simCode, context, varDeclsCref, useFlatArrayNotation)%>=<%expPart%>;
    >>
  case "int" then
    let tvar = tempDecl("integer_array", &varDecls /*BUFD*/)
    <<
      <%preExp%>
      <%cref1(eqn.componentRef,simCode, context, varDeclsCref, useFlatArrayNotation)%>=<%expPart%>;
    >>
  case "double" then
   <<
        <%preExp%>
       <%assignDerArray(context,expPart,eqn.componentRef,simCode,useFlatArrayNotation)%>
   >>
 end equationArrayCallAssign;
  /*<%cref1(eqn.componentRef,simCode, context, varDeclsCref, useFlatArrayNotation)%>=<%expPart%>;*/


template assignDerArray(Context context, String arr, ComponentRef c,SimCode simCode, Boolean useFlatArrayNotation)
::=
  cref2simvar(c, simCode) |> var as SIMVAR(__) =>
   match varKind
    case STATE(__)        then
     let &varDeclsCref = buffer "" /*BUFD*/
     <<
        /*<%cref(c,useFlatArrayNotation)%>*/
        memcpy(&<%cref1(c,simCode, context, varDeclsCref, useFlatArrayNotation)%>,<%arr%>.getData(),<%arr%>.getNumElems()*sizeof(double));
     >>
    case STATE_DER(__)   then
     let &varDeclsCref = buffer "" /*BUFD*/
    <<
      memcpy(&<%cref1(c,simCode, context, varDeclsCref, useFlatArrayNotation)%>,<%arr%>.getData(),<%arr%>.getNumElems()*sizeof(double));
    >>
    else
     let &varDeclsCref = buffer "" /*BUFD*/
    <<
       <%cref1(c,simCode, context, varDeclsCref, useFlatArrayNotation)%>.assign(<%arr%>);
    >>
end assignDerArray;

template equationWhen(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates a when equation."
::=
  let &varDeclsCref = buffer "" /*BUFD*/
  match eq
     case SES_WHEN(left=left, right=right, conditions=conditions, elseWhen=NONE()) then
      let helpIf = (conditions |> e => ' || (<%cref1(e, simCode, context, varDeclsCref, useFlatArrayNotation)%> && !_event_handling.pre(<%cref1(e, simCode, context, varDeclsCref, useFlatArrayNotation)%>,"<%cref1(e, simCode, context, varDeclsCref, useFlatArrayNotation)%>"))')

        let initial_assign =
        if initialCall then
          whenAssign(left,typeof(right),right,context, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
        else
           '<%cref1(left,simCode, context, varDeclsCref, useFlatArrayNotation)%> = _event_handling.pre(<%cref1(left,simCode, context, varDeclsCref, useFlatArrayNotation)%>,"<%cref1(left,simCode, context, varDeclsCref, useFlatArrayNotation)%>");'
       let assign = whenAssign(left,typeof(right),right,context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
      <<

      if(_initial)
      {
        <%initial_assign%>;
      }
       else if (0<%helpIf%>)
       {
        <%assign%>;
      }
      else
      {
        <%cref1(left,simCode, context, varDeclsCref, useFlatArrayNotation)%> = _event_handling.pre(<%cref1(left,simCode, context, varDeclsCref, useFlatArrayNotation)%>,"<%cref1(left,simCode, context, varDeclsCref, useFlatArrayNotation)%>");
      }
           >>
    case SES_WHEN(left=left, right=right, conditions=conditions, elseWhen=SOME(elseWhenEq)) then
       let helpIf = (conditions |> e => ' || (<%cref1(e, simCode, context, varDeclsCref, useFlatArrayNotation)%> && !_event_handling.pre(<%cref1(e, simCode, context, varDeclsCref, useFlatArrayNotation)%>,"<%cref1(e, simCode, context, varDeclsCref, useFlatArrayNotation)%>"))')
      let initial_assign =
        if initialCall then
          whenAssign(left,typeof(right),right,context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
        else
         '<%cref1(left,simCode, context, varDeclsCref, useFlatArrayNotation)%> = _event_handling.pre(<%cref1(left,simCode, context, varDeclsCref, useFlatArrayNotation)%>,"<%cref1(left,simCode, context, varDeclsCref, useFlatArrayNotation)%>");'
      let assign = whenAssign(left,typeof(right),right,context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
      let elseWhen = equationElseWhen(elseWhenEq,context,varDecls,simCode,useFlatArrayNotation)
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
         <%cref1(left,simCode, context, varDeclsCref, useFlatArrayNotation)%> = _event_handling.pre(<%cref1(left,simCode, context, varDeclsCref, useFlatArrayNotation)%>,"<%cref1(left,simCode, context, varDeclsCref, useFlatArrayNotation)%>");
      }
      >>
end equationWhen;


template whenAssign(ComponentRef left, Type ty, Exp right, Context context,  Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates assignment for when."
::=
match ty
  case T_ARRAY(__) then
    let &preExp = buffer "" /*BUFD*/
    let expPart = daeExp(right, context, &preExp, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
    match expTypeFromExpShort(right)
    case "boolean" then
      let tvar = tempDecl("boolean_array", &varDecls /*BUFD*/)
      //let &preExp += 'cast_integer_array_to_real(&<%expPart%>, &<%tvar%>);<%\n%>'
      <<
      <%preExp%>
      copy_boolean_array_data_mem(&<%expPart%>, &<%cref(left, useFlatArrayNotation)%>);
      >>
    case "integer" then
      let tvar = tempDecl("integer_array", &varDecls /*BUFD*/)
      //let &preExp += 'cast_integer_array_to_real(&<%expPart%>, &<%tvar%>);<%\n%>'
      <<
      <%preExp%>
      copy_integer_array_data_mem(&<%expPart%>, &<%cref(left, useFlatArrayNotation)%>);
      >>
    case "real" then
      <<
      <%preExp%>
      copy_real_array_data_mem(&<%expPart%>, &<%cref(left, useFlatArrayNotation)%>);
      >>
    case "string" then
      <<
      <%preExp%>
      copy_string_array_data_mem(&<%expPart%>, &<%cref(left, useFlatArrayNotation)%>);
      >>
    else
      error(sourceInfo(), 'No runtime support for this sort of array call: <%cref(left, useFlatArrayNotation)%> = <%printExpStr(right)%>')
    end match
  else
    let &preExp = buffer "" /*BUFD*/
    let exp = daeExp(right, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    <<
    <%preExp%>
    <%cref(left, useFlatArrayNotation)%> = <%exp%>;
   >>
end whenAssign;

template equationElseWhen(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates a else when equation."
::=
let &varDeclsCref = buffer "" /*BUFD*/
match eq
case SES_WHEN(left=left, right=right, conditions=conditions, elseWhen=NONE()) then
  let helpIf =  (conditions |> e => ' || (<%cref1(e, simCode, context, varDeclsCref, useFlatArrayNotation)%> && !_event_handling.pre(<%cref1(e, simCode, context, varDeclsCref, useFlatArrayNotation)%>,"<%cref1(e, simCode, context, varDeclsCref, useFlatArrayNotation)%>"))')
  let assign = whenAssign(left,typeof(right),right,context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  <<
  else if(0<%helpIf%>)
  {
    <%assign%>
  }
  >>
case SES_WHEN(left=left, right=right, conditions=conditions, elseWhen=SOME(elseWhenEq)) then
  let helpIf = (conditions |> e => ' || (<%cref1(e, simCode, context, varDeclsCref, useFlatArrayNotation)%> && !_event_handling.pre(<%cref1(e, simCode, context, varDeclsCref, useFlatArrayNotation)%>,"<%cref1(e, simCode, context, varDeclsCref, useFlatArrayNotation)%>"))')
  let assign = whenAssign(left,typeof(right),right,context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  let elseWhen = equationElseWhen(elseWhenEq,context,varDecls,simCode,useFlatArrayNotation)
  <<
  else if(0<%helpIf%>)
  {
    <%assign%>
  }
  <%elseWhen%>
  >>
end equationElseWhen;

template helpvarvector(list<SimWhenClause> whenClauses,SimCode simCode, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let reinit = (whenClauses |> when hasindex i0 =>
      helpvarvector1(when, contextOther,&varDecls,i0,simCode, useFlatArrayNotation)
    ;separator="";empty)
  <<
    <%reinit%>
  >>
end helpvarvector;

template helpvarvector1(SimWhenClause whenClauses,Context context, Text &varDecls,Integer int,SimCode simCode, Boolean useFlatArrayNotation)
::=
match whenClauses
case SIM_WHEN_CLAUSE(__) then
  let &preExp = buffer "" /*BUFD*/
  let &helpInits = buffer "" /*BUFD*/
  let &varDeclsCref = buffer "" /*BUFD*/
  let helpIf = (conditions |> e =>
      let helpInit = cref1(e, simCode, context, varDeclsCref, useFlatArrayNotation)
      ""
   ;separator="")
<<
 <%preExp%>
 <%helpIf%>
>>
end helpvarvector1;



template preCref(ComponentRef cr, SimCode simCode, Context context, Boolean useFlatArrayNotation) ::=
let &varDeclsCref = buffer "" /*BUFD*/
'pre<%representationCref(cr, simCode,context,varDeclsCref, useFlatArrayNotation)%>'
end preCref;

template equationSimpleAssign(SimEqSystem eq, Context context,Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
 "Generates an equation that is just a simple assignment."
::=
match eq
case SES_SIMPLE_ASSIGN(__) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)

  match cref
  case CREF_QUAL(ident = "$PRE")  then
  <<
    <%preExp%>
      _event_handling.save(<%expPart%>,"<%cref(componentRef, useFlatArrayNotation)%>");
  >>
  else
   match exp
  case CREF(ty = t as  T_ARRAY(__)) then
  <<
  //Array assign
  <%cref1(cref, simCode,context,varDecls, useFlatArrayNotation)%> = <%expPart%>;
  >>
  else
  <<

  <%preExp%>

  <%cref1(cref, simCode, context, varDecls,useFlatArrayNotation)%> = <%expPart%>;

  >>
 end match
end match
end equationSimpleAssign;

template equationLinearOrNonLinear(SimEqSystem eq, Context context,Text &varDecls,
                              SimCode simCode)
 "Generates an equations for a linear or non linear system."
::=
  match eq
    case SES_LINEAR(__)
    case SES_NONLINEAR(__) then
    let i = index
    match context
      case  ALGLOOP_CONTEXT(genInitialisation=true) then
         <<
         try
         {
             _algLoopSolver<%index%>->initialize();
             _algLoop<%index%>->evaluate();
             for(int i=0; i<_dimZeroFunc; i++) {
                 getCondition(i);
             }
             IContinuous::UPDATETYPE calltype = _callType;
             _callType = IContinuous::CONTINUOUS;
             _algLoopSolver<%index%>->solve();
             _callType = calltype;
         }
         catch(std::exception& ex)
         {
             throw std::invalid_argument("Nonlinear solver stopped at time " + boost::lexical_cast<string>(_simTime) + " with error: " + ex.what());
         }

         >>

      else
        <<
        bool restart<%index%> = true;
        bool* conditions0<%index%> = new bool[_dimZeroFunc];
        bool* conditions1<%index%> = new bool[_dimZeroFunc];
        unsigned int iterations<%index%> = 0;
        unsigned int dim<%index%> = _algLoop<%index%>->getDimReal();
        double* algloop<%index%>Vars = new double[dim<%index%>];
        _algLoop<%index%>->getReal(algloop<%index%>Vars );
        bool restatDiscrete<%index%>= false;
        IContinuous::UPDATETYPE calltype = _callType;
        try
        {


            if( _callType == IContinuous::DISCRETE )
            {
                _algLoop<%index%>->evaluate();
                while(restart<%index%> && !(iterations<%index%>++>500))
                {

                    getConditions(conditions0<%index%>);
                    _callType = IContinuous::CONTINUOUS;
                    _algLoopSolver<%index%>->solve();
                    _callType = IContinuous::DISCRETE;
                    for(int i=0;i<_dimZeroFunc;i++)
                    {
                        getCondition(i);
                    }

                    getConditions(conditions1<%index%>);
                    restart<%index%> = !std::equal (conditions1<%index%>, conditions1<%index%>+_dimZeroFunc,conditions0<%index%>);
                }
            }
            else
            _algLoopSolver<%index%>->solve();

        }
        catch(std::exception &ex)
        {
             restatDiscrete<%index%>=true;
        }



        if((restart<%index%>&& iterations<%index%> > 0)|| restatDiscrete<%index%>)
        {
            try
            {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
                _callType = IContinuous::DISCRETE;
                _algLoop<%index%>->setReal(algloop<%index%>Vars );
                _algLoopSolver<%index%>->solve();
                _callType = calltype;
            }
            catch(std::exception& ex)
            {
                delete[] algloop<%index%>Vars;
                delete[] conditions0<%index%>;
                delete[] conditions1<%index%>;
                throw std::invalid_argument("Nonlinear solver stopped at time " + boost::lexical_cast<string>(_simTime) + " with error: " + ex.what());
            }

        }
        delete[] algloop<%index%>Vars;
        delete[] conditions0<%index%>;
        delete[] conditions1<%index%>;
        >>
      end match
  end match
end equationLinearOrNonLinear;

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



template daeExp(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for an expression."
::=
  match exp

  case e as ICONST(__)          then    '<%integer%>' /* Yes, we need to cast int to long on 64-bit arch... */
  case e as RCONST(__)          then    real
  case e as BCONST(__)          then    if bool then "true" else "false"
  case e as ENUM_LITERAL(__)    then    index
  case e as CREF(__)            then    daeExpCrefRhs(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  case e as CAST(__)            then    daeExpCast(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  case e as CONS(__)            then    "Cons not supported yet"
  case e as SCONST(__)          then     daeExpSconst(string, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  case e as UNARY(__)           then     daeExpUnary(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  case e as LBINARY(__)         then     daeExpLbinary(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  case e as LUNARY(__)          then     daeExpLunary(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  case e as BINARY(__)          then     daeExpBinary(operator, exp1, exp2, context, &preExp, &varDecls,simCode, useFlatArrayNotation)
  case e as IFEXP(__)           then     daeExpIf(expCond, expThen, expElse, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode, useFlatArrayNotation)
  case e as RELATION(__)        then     daeExpRelation(e, context, &preExp, &varDecls,simCode, useFlatArrayNotation)
  case e as CALL(__)            then     daeExpCall(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  case e as RECORD(__)          then     daeExpRecord(e, context, &preExp, &varDecls,simCode, useFlatArrayNotation)
  case e as ASUB(__)            then     daeExpAsub(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  case e as MATRIX(__)          then     daeExpMatrix(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  case e as RANGE(__)           then     daeExpRange(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  case e as TSUB(__)            then     daeExpTsub(e, context,  &preExp, &varDecls, simCode, useFlatArrayNotation )
  case e as REDUCTION(__)       then     daeExpReduction(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  case e as ARRAY(__)           then     daeExpArray(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  case e as SIZE(__)            then     daeExpSize(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  case e as SHARED_LITERAL(__)  then     daeExpSharedLiteral(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, useFlatArrayNotation)

  else error(sourceInfo(), 'Unknown exp:<%printExpStr(exp)%>')
end daeExp;

template daeExpRange(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for a range expression."
::=
  match exp
  case RANGE(__) then
    let ty_str = expTypeArray(ty)
    let start_exp = daeExp(start, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let stop_exp = daeExp(stop, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
  //previous multi_array     let tmp = tempDecl('multi_array<<%ty_str%>,1>', &varDecls /*BUFD*/)
    let tmp = tempDecl('DynArrayDim1<<%ty_str%>>', &varDecls /*BUFD*/)
    let step_exp = match step case SOME(stepExp) then daeExp(stepExp, context, &preExp, &varDecls,simCode,useFlatArrayNotation) else "1"
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
     for(int i= 1;i<=<%tmp%>_num_elems;i++)
        <%tmp%>(i) =<%start_exp%>+(i-1)*<%step_exp%>;
    '
    '<%tmp%>'
end daeExpRange;






template daeExpReduction(Exp exp, Context context, Text &preExp /*BUFP*/,
                         Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for a reduction expression. The code is quite messy because it handles all
  special reduction functions (list, listReverse, array) and handles both list and array as input"
::=
  match exp
  case r as REDUCTION(reductionInfo=ri as REDUCTIONINFO(__),iterators={iter as REDUCTIONITER(__)}) then
  let &tmpVarDecls = buffer ""
  let &tmpExpPre = buffer ""
  let &bodyExpPre = buffer ""
  let &guardExpPre = buffer ""
  let &rangeExpPre = buffer ""

  let identType = expTypeFromExpModelica(iter.exp)
  let arrayType ="Test"
  let loopVar = expTypeFromExpArrayIf(iter.exp,context,rangeExpPre,tmpVarDecls,simCode,useFlatArrayNotation)
  let arrayTypeResult = expTypeFromExpArray(r)
  /*let loopVar = match identType
    case "modelica_metatype" then tempDecl(identType,&tmpVarDecls)
    else tempDecl(arrayType,&tmpVarDecls)*/
  let firstIndex = match identType case "modelica_metatype" then "" else tempDecl("int",&tmpVarDecls)
  let arrIndex = match ri.path case IDENT(name="array") then tempDecl("int",&tmpVarDecls)
  let foundFirst = if not ri.defaultValue then tempDecl("int",&tmpVarDecls)
  let rangeExp = daeExp(iter.exp,context,&rangeExpPre,&tmpVarDecls,simCode,useFlatArrayNotation)
  let resType = expTypeArrayIf(typeof(exp))
  let res = contextCref(makeUntypedCrefIdent(ri.resultName), context,simCode,useFlatArrayNotation)
  let &tmpVarDecls += '<%resType%> <%res%>;<%\n%>'
  let resTmp = tempDecl(resType,&varDecls)
  let &preDefault = buffer ""
  let resTail = match ri.path case IDENT(name="list") then tempDecl("modelica_metatype*",&tmpVarDecls)
  let defaultValue = match ri.path case IDENT(name="array") then "" else match ri.defaultValue
    case SOME(v) then daeExp(valueExp(v),context,&preDefault,&tmpVarDecls,simCode,useFlatArrayNotation)
    end match
  let guardCond = match iter.guardExp case SOME(grd) then daeExp(grd, context, &guardExpPre, &tmpVarDecls,simCode,useFlatArrayNotation) else "1"
  let empty = match identType case "modelica_metatype" then 'listEmpty(<%loopVar%>)' else '0 == <%loopVar%>.getDims()[0]'
  let length = match identType case "modelica_metatype" then 'listLength(<%loopVar%>)' else '<%loopVar%>.getDims()[0]'
  let reductionBodyExpr = contextCref(makeUntypedCrefIdent(ri.foldName), context,simCode,useFlatArrayNotation)
  let bodyExprType = expTypeArrayIf(typeof(r.expr))
  let reductionBodyExprWork = daeExp(r.expr, context, &bodyExpPre, &tmpVarDecls,simCode,useFlatArrayNotation)
  let &tmpVarDecls += '<%bodyExprType%> <%reductionBodyExpr%>;<%\n%>'
  let &bodyExpPre += '<%reductionBodyExpr%> = <%reductionBodyExprWork%>;<%\n%>'
  let foldExp = match ri.path
    case IDENT(name="list") then
    <<
    *<%resTail%> = mmc_mk_cons(<%reductionBodyExpr%>,0);
    <%resTail%> = &MMC_CDR(*<%resTail%>);
    >>
    case IDENT(name="listReverse") then // This is too easy; the damn list is already in the correct order
      '<%res%> = mmc_mk_cons(<%reductionBodyExpr%>,<%res%>);'
    case IDENT(name="array") then
  //previous multi_array      '<%res%>[<%arrIndex%>++] = <%reductionBodyExpr%>;'
      '<%res%>(<%arrIndex%>++) = <%reductionBodyExpr%>;'
    else match ri.foldExp case SOME(fExp) then
      let &foldExpPre = buffer ""
      let fExpStr = daeExp(fExp, context, &bodyExpPre, &tmpVarDecls,simCode,useFlatArrayNotation)
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
      else '<%res%> = <%fExpStr%>;'
  let firstValue = match ri.path
  /*previous multiarray
     case IDENT(name="array") then
     <<
     <%arrIndex%> = 1;
     <%res%>.resize(boost::extents[<%length%>]);
     <%res%>.reindex(1)/;
     >>
  */
     case IDENT(name="array") then
     <<
     <%arrIndex%> = 1;
     <%res%>.setDims(<%length%>)/*setDims 3*/;
     >>
     else if ri.defaultValue then
     <<
     <%&preDefault%>
     <%res%> = <%defaultValue%>; /* defaultValue */
     >>
     else
     <<
     <%foundFirst%> = 0; /* <%dotPath(ri.path)%> lacks default-value */
     >>
  let iteratorName = contextIteratorName(iter.id, context)
  let loopHead = match identType
    case "modelica_metatype" then
    <<
    while(!<%empty%>)
    {
      <%identType%> <%iteratorName%>;
      <%iteratorName%> = MMC_CAR(<%loopVar%>);
      <%loopVar%> = MMC_CDR(<%loopVar%>);
    >>
  /*previous multi_array
  <<
    while(<%firstIndex%> <= <%loopVar%>.getDims[0])
    {
      <%identType%> <%iteratorName%>;
      <%iteratorName%> = <%loopVar%>(<%firstIndex%>++);

    >>
  */
    else
    <<
    while(<%firstIndex%> <= <%loopVar%>.getDims()[0])
    {
      <%identType%> <%iteratorName%>;
      <%iteratorName%> = <%loopVar%>(<%firstIndex%>++);

    >>
   let loopTail = '}'
  let loopvarassign =
     match typeof(iter.exp)
      case ty as T_ARRAY(__) then
    //previous multi_array       'assign_array( <%loopVar%>,<%rangeExp%>);'
      '<%loopVar%>.assign(<%rangeExp%>);'
      else
       '<%loopVar%> = <%rangeExp%>;'
       end match

    let assign_res = match ri.path
     case IDENT(name="array")  then
   //previous multi_array 'assign_array(<% resTmp %>, <% res %>);'
        '<% resTmp %>.assign(<% res %>);'
        else
         '<% resTmp %> = <% res %>;'
  let &preExp += <<
  {
    <%&tmpVarDecls%>
    <%&rangeExpPre%>
    <%loopvarassign%>

    <% if firstIndex then '<%firstIndex%> = 1;' %>
    <%firstValue%>
    <% if resTail then '<%resTail%> = &<%res%>;' %>
    <%loopHead%>
      <%&guardExpPre%>
      if(<%guardCond%>)
      {
        <%&bodyExpPre%>
        <%foldExp%>
      }
      <%loopTail%>
    <% if not ri.defaultValue then 'if (!<%foundFirst%>) MMC_THROW();' %>
    <% if resTail then '*<%resTail%> = mmc_mk_nil();' %>
   <%assign_res%>
  }<%\n%>
  >>
  resTmp
  else error(sourceInfo(), 'Code generation does not support multiple iterators: <%printExpStr(exp)%>')
end daeExpReduction;

template daeExpSize(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
 "Generates code for a size expression."
::=
  match exp
  case SIZE(exp=CREF(__), sz=SOME(dim)) then
    let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let dimPart = daeExp(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let resVar = tempDecl("size_t", &varDecls /*BUFD*/)
    let typeStr = '<%expTypeArray(exp.ty)%>'
  //previous multiarray let &preExp += '<%resVar%> = <%expPart%>.shape()[<%dimPart%>-1];<%\n%>'
    //previous multiarray
  let &preExp += '<%resVar%> = <%expPart%>.getDims()[<%dimPart%>-1];<%\n%>'
    resVar
  else "size(X) not implemented"
end daeExpSize;


template daeExpMatrix(Exp exp, Context context, Text &preExp /*BUFP*/,
                      Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
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

  // previous multiarray

  /* previous multiarray
     let &preExp += '
     <%StatArrayDim%><%arrayVar%>(boost::extents[<%listLength(m.matrix)%>][<%dim_cols%>]);
     <%arrayVar%>.reindex(1);
     <%arrayTypeStr%> <%arrayVar%>_data[]={<%params%>};
    <%arrayVar%>.assign(<%arrayVar%>_data,<%arrayVar%>_data+ (<%listLength(m.matrix)%> * <%dim_cols%>));<%\n%>'
  */

/*
/////////////////////////////////////////////////NonCED
    let params = (m.matrix |> row =>
        let vars = daeExpMatrixRow(row, context, &varDecls,&preExp,simCode,useFlatArrayNotation)
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
        let vars = daeExpMatrixRow(m.matrix,context,simCode)
        match vars
        case "NO_ASSIGN"
        then
           let params = (m.matrix |> row =>
           let vars = daeExpMatrixRow2(row, context, &varDecls,&preExp,simCode,useFlatArrayNotation)
              '<%vars%>'
           ;separator=",")
           let &preExp += '
           //default matrix assign
           <%StatArrayDim%><%arrayVar%>;
           <%arrayTypeStr%> <%arrayVar%>_data[]={<%params%>};
           <%arrayVar%>.assign( <%arrayVar%>_data );<%\n%>'
           ''
        else
           let &preExp += '
            //optimized matrix assign/
            <%StatArrayDim%><%arrayVar%>;
            <%arrayVar%>.assign( <%vars%> );<%\n%>'
        ''
  end match


  //let &preExp += '
 //  <%StatArrayDim%><%arrayVar%>;
 //   <%arrayVar%>.assign( <%matrixassign%> );<%\n%>'


     arrayVar
end daeExpMatrix;


template daeExpMatrixRow2(list<Exp> row,
                         Context context,
                         Text &varDecls ,Text &preExp ,SimCode simCode,Boolean useFlatArrayNotation)
 "Helper to daeExpMatrix."
::=

   let varLstStr = (row |> e =>

      let expVar = daeExp(e, context, &preExp , &varDecls ,simCode,useFlatArrayNotation)
      '<%expVar%>'
    ;separator=",")
  varLstStr
end daeExpMatrixRow2;
/////////////////////////////////////////////////CED

/*
/////////////////////////////////////////////////NonCED functions
template daeExpMatrixRow(list<Exp> row,
                         Context context,
                         Text &varDecls ,Text &preExp ,SimCode simCode,Boolean useFlatArrayNotation)
 "Helper to daeExpMatrix."
::=

   let varLstStr = (row |> e =>

      let expVar = daeExp(e, context, &preExp , &varDecls ,simCode,useFlatArrayNotation)
      '<%expVar%>'
    ;separator=",")
  varLstStr
end daeExpMatrixRow;
/////////////////////////////////////////////////NonCED functions
*/

////////////////////////////////////////////////////////////////////////CED Functions
template daeExpMatrixRow(list<list<Exp>> matrix,Context context,SimCode simCode)
 "Helper to daeExpMatrix."
::=
if isCrefListWithEqualIdents(List.flatten(matrix)) then
  match matrix
  case row::_ then
      daeExpMatrixName(row,context,simCode)
  else
   "NO_ASSIGN"
   end match
  else
   "NO_ASSIGN"
end daeExpMatrixRow;

template daeExpMatrixName(list<Exp> row,Context context,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let &preExp = buffer "" /*BUFD*/
  match row
   case CREF(componentRef = cr)::_ then
      contextCref(crefStripLastSubs(cr),context,simCode,false)
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
template daeExpArray(Exp exp, Context context, Text &preExp /*BUFP*/,
                     Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
 "Generates code for an array expression."
::=
match exp
case ARRAY(array=_::_, ty = arraytype) then
  let arrayTypeStr = expTypeArray(ty)
  let ArrayType = expTypeArrayforDim(ty)
 // let &tmpdecl = buffer "" /*BUFD*/
  let &tmpVar = buffer ""
  let arrayVar = tempDecl(arrayTypeStr, &tmpVar /*BUFD*/)
  // let scalarPrefix = if scalar then "scalar_" else ""
  //let scalarRef = if scalar then "&" else ""


  let params = if scalar then (array |> e =>
    '<%daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>';separator=", ")
               else
                (array |> e hasindex i0 fromindex 1 =>
                '<%arrayVar%>.append(<%i0%>,<%daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>);' //previous multiarray'<%arrayVar%>[<%i0%>)=<%daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>;'
                ;separator="\n")

  // previous mulit_array
  //  let boostExtents = if scalar then '<%ArrayType%> <%arrayVar%>({<%params%>});'
  //                   else        '<%ArrayType%> <%arrayVar%>(<%boostExtents(arraytype)%>/*,boost::fortran_storage_order()*/);'

 /*  previous mulit_array
 let arrayassign =  if scalar then '<%arrayTypeStr%> <%arrayVar%>_data[]={<%params%>};
 <%arrayVar%>.assign(<%arrayVar%>_data,<%arrayVar%>_data+<%listLength(array)%>);<%\n%>'
 */
   let arrayassign =  if scalar then '<%arrayTypeStr%> <%arrayVar%>_data[]={<%params%>};
    <%ArrayType%> <%arrayVar%>(<%arrayVar%>_data);<%\n%>'
                      else    '<%ArrayType%> <%arrayVar%>;
                               <%arrayVar%>.setDims(<%allocateDimensions(arraytype,context)%>);
                               <%params%>'

   let &preExp += '
   //tmp array1
    <%arrayassign%>
  '
  arrayVar
case ARRAY(__) then
  let arrayTypeStr = expTypeArray(ty)
  let arrayDef = expTypeArrayforDim(ty)
  let &tmpdecl = buffer "" /*BUFD*/
  let arrayVar = tempDecl(arrayTypeStr, &tmpdecl /*BUFD*/)
  // let scalarPrefix = if scalar then "scalar_" else ""
  //let scalarRef = if scalar then "&" else ""
  let &tmpVar = buffer ""
  /*previous multiarray
     //tmp array
   <%StatArrayDim%><%arrayVar%>(boost::extents[<%listLength(array)%>]);
   <%arrayVar%>.reindex(1);<%\n%>'
  */
  let &preExp += '
   //tmp array
   <%arrayDef%><%arrayVar%>;<%\n%>'
  arrayVar
end daeExpArray;











template daeExpAsub(Exp inExp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
 "Generates code for an asub expression."
::=
  match expTypeFromExpShort(inExp)
  case "metatype" then
  // MetaModelica Array
    (match inExp case ASUB(exp=e, sub={idx}) then
      let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
      let idx1 = daeExp(idx, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
      'arrayGet(<%e1%>,<%idx1%>) /* DAE.ASUB */')
  // Modelica Array
  else
  match inExp

  case ASUB(exp=ASUB(__)) then
    error(sourceInfo(),'Nested array subscripting *should* have been handled by the routine creating the asub, but for some reason it was not: <%printExpStr(exp)%>')

  // Faster asub: Do not construct a whole new array just to access one subscript
  case ASUB(exp=exp as ARRAY(scalar=true), sub={idx}) then
    let res = tempDecl(expTypeFromExpModelica(exp),&varDecls)
    let idx1 = daeExp(idx, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let expl = (exp.array |> e hasindex i1 fromindex 1 =>
      let &caseVarDecls = buffer ""
      let &casePreExp = buffer ""
      let v =daeExp(e, context, &casePreExp, &caseVarDecls,simCode,useFlatArrayNotation)
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
    let arrName =  daeExpCrefRhs(buildCrefExpFromAsub(ecr, subs), context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    match context case FUNCTION_CONTEXT(__)  then
      arrName
    else

      '<%arrayScalarRhs(ecr.ty, subs, arrName, context, &preExp, &varDecls,simCode,useFlatArrayNotation)%>'


  case ASUB(exp=e, sub=indexes) then
  let exp = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
 // let typeShort = expTypeFromExpShort(e)
  let expIndexes = (indexes |> index => '<%daeExpASubIndex(index, context, &preExp, &varDecls,simCode,useFlatArrayNotation)%>' ;separator=",")
   //'<%typeShort%>_get<%match listLength(indexes) case 1 then "" case i then '_<%i%>D'%>(&<%exp%>, <%expIndexes%>)'
  '(<%exp%>)(<%expIndexes%>)'
  case exp then
    error(sourceInfo(),'OTHER_ASUB <%printExpStr(exp)%>')
end daeExpAsub;



template daeExpASubIndex(Exp exp, Context context, Text &preExp, Text &varDecls,SimCode simCode,Boolean useFlatArrayNotation)
::=
match exp
  case ICONST(__) then integer
  case ENUM_LITERAL(__) then index
  else daeExp(exp,context,&preExp,&varDecls,simCode,useFlatArrayNotation)
end daeExpASubIndex;


template arrayScalarRhs(Type ty, list<Exp> subs, String arrName, Context context,
               Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
 "Helper to daeExpAsub."
::=
  /* match exp
   case ASUB(exp=ecr as CREF(__)) then*/
  let arrayType = expTypeArray(ty)
  let dimsLenStr = listLength(subs)
  let dimsValuesStr = (subs |> exp =>
      daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation) ;separator=",")
    //previous multi_array ;separator="][")


  match arrayType
    case "metatype_array" then
      'arrayGet(<%arrName%>,<%dimsValuesStr%>) /*arrayScalarRhs*/'
    else
      //ToDo before used <%arrayCrefCStr(ecr.componentRef)%>[<%dimsValuesStr%>]
      << <%arrName%>(<%dimsValuesStr%>) >>
end arrayScalarRhs;

template daeExpCast(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for a cast expression."
::=
match exp
case CAST(__) then
  let expVar = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
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

template daeExpRecord(Exp rec, Context context, Text &preExp, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
::=
  match rec
  case RECORD(__) then
  let name = tempDecl(underscorePath(path) + "Type", &varDecls)
  let ass = threadTuple(exps,comp) |>  (exp,compn) => '<%name%>.<%compn%> = <%daeExp(exp, context, &preExp, &varDecls, simCode,useFlatArrayNotation)%>;<%\n%>'
  let &preExp += ass
  name
end daeExpRecord;

template daeExpCall(Exp call, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
 "Generates code for a function call."
::=
  //<%name%>
  match call
  // special builtins

  case CALL(path=IDENT(name="edge"),
            expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    '_event_handling.edge(<%var1%>,"<%var1%>")'

  case CALL(path=IDENT(name="pre"),
            expLst={arg as CREF(__)}) then
    let var1 = daeExp(arg, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    '_event_handling.pre(<%var1%>,"<%cref(arg.componentRef, useFlatArrayNotation)%>")'

  case CALL(path=IDENT(name="sample"), expLst={ICONST(integer=index), start, interval}) then
    let &preExp = buffer "" /*BUFD*/
    let eStart = daeExp(start, contextOther, &preExp, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let eInterval = daeExp(interval, contextOther, &preExp, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
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
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var3 = Util.escapeModelicaStringToCString(printExpStr(e2))
    'division(<%var1%>,<%var2%>,"<%var3%>")'

   case CALL(path=IDENT(name="sign"),
            expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
     'sgn(<%var1%>)'

   case CALL(attr=CALL_ATTR(ty=ty as T_ARRAY(dims=dims)),
            path=IDENT(name="DIVISION_ARRAY_SCALAR"),
            expLst={e1, e2}) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "int"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "int"
                        else "double"

    let var = tempDecl('multi_array<<%type%>,<%listLength(dims)%>>', &varDecls /*BUFD*/)
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var3 = Util.escapeModelicaStringToCString(printExpStr(e2))
    let &preExp += 'assign_array(<%var%>,divide_array<<%type%>,<%listLength(dims)%>>(<%var1%>, <%var2%>));<%\n%>'
    //let &preExp += 'division_alloc_<%type%>_scalar(&<%var1%>, <%var2%>, &<%var%>, "<%var3%>");<%\n%>'
    '<%var%>'


  case CALL(path=IDENT(name="der"), expLst={arg as CREF(__)}) then
    representationCrefDerVar(arg.componentRef,simCode,context)
  case CALL(path=IDENT(name="pre"), expLst={arg as CREF(__)}) then
    let retType = '<%expTypeArrayIf(arg.ty)%>'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let cast = match arg.ty case T_INTEGER(__) then "(int)"
                            case T_ENUMERATION(__) then "(int)" //else ""
    let &preExp += '<%retVar%> = <%cast%>pre(<%cref(arg.componentRef, useFlatArrayNotation)%>);<%\n%>'
    '<%retVar%>'

  case CALL(path=IDENT(name="print"), expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    if acceptMetaModelicaGrammar() then 'print(<%var1%>)' else 'puts(<%var1%>)'


  case CALL(path=IDENT(name="integer"), expLst={inExp,index}) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
   // let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    'boost::numeric_cast<int>(<%exp%>)'


  case CALL(path=IDENT(name="floor"), expLst={inExp,index}, attr=CALL_ATTR(ty = ty)) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    //let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    'std::floor(<%exp%>)'
 case CALL(path=IDENT(name="floor"), expLst={inExp}, attr=CALL_ATTR(ty = ty)) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    //let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    'std::floor(<%exp%>)'
  case CALL(path=IDENT(name="ceil"), expLst={inExp,index}, attr=CALL_ATTR(ty = ty)) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    //let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    'std::ceil(<%exp%>)'
  case CALL(path=IDENT(name="ceil"), expLst={inExp}, attr=CALL_ATTR(ty = ty)) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    //let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    'std::ceil(<%exp%>)'

  case CALL(path=IDENT(name="integer"), expLst={inExp}) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
   'boost::numeric_cast<int>(<%exp%>)'

   case CALL(path=IDENT(name="modelica_mod_int"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    '<%var1%>%<%var2%>)'

  case CALL(path=IDENT(name="max"), attr=CALL_ATTR(ty = T_REAL(__)), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    'max(<%var1%>,<%var2%>)'

  case CALL(path=IDENT(name="max"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    'max(<%var1%>,<%var2%>)'

  case CALL(attr=CALL_ATTR(ty = T_REAL(__)),
            path=IDENT(name="min"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    'min(<%var1%>,<%var2%>)'

  case CALL(path=IDENT(name="min"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    'min(<%var1%>,<%var2%>)'

  case CALL(path=IDENT(name="abs"), expLst={e1}, attr=CALL_ATTR(ty = T_INTEGER(__))) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    'labs(<%var1%>)'

  case CALL(path=IDENT(name="abs"), expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    'std::abs(<%var1%>)'

  case CALL(path=IDENT(name="sqrt"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>' ;separator=", ")
    let typeStr = expTypeShort(attr.ty )
    let retVar = tempDecl(typeStr, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = sqrt(<%argStr%>);<%\n%>'
    '<%retVar%>'

  case CALL(path=IDENT(name="sin"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

     case CALL(path=IDENT(name="sinh"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

   case CALL(path=IDENT(name="cos"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'
 case CALL(path=IDENT(name="cosh"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'
   case CALL(path=IDENT(name="log"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

   case CALL(path=IDENT(name="log10"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'



   case CALL(path=IDENT(name="acos"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

   case CALL(path=IDENT(name="tan"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

    case CALL(path=IDENT(name="tanh"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

   case CALL(path=IDENT(name="atan"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

   case CALL(path=IDENT(name="atan2"),
            expLst={e1,e2},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>' ;separator=", ")

    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = std::atan2(<%argStr%>);<%\n%>'
    '<%retVar%>'
    case CALL(path=IDENT(name="smooth"),
            expLst={e1,e2},attr=attr as CALL_ATTR(__)) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    '<%var2%>'
    case CALL(path=IDENT(name="homotopy"),
            expLst={e1,e2},attr=attr as CALL_ATTR(__)) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    '<%var1%>'
     case CALL(path=IDENT(name="homotopyParameter"),
            expLst={},attr=attr as CALL_ATTR(__)) then
     '1.0'

   case CALL(path=IDENT(name="exp"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

  case CALL(path=IDENT(name="div"), expLst={e1,e2}, attr=CALL_ATTR(ty = T_INTEGER(__))) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    'ldiv(<%var1%>,<%var2%>).quot'

  case CALL(path=IDENT(name="div"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    'boost::math::trunc(<%var1%>/<%var2%>)'

  case CALL(path=IDENT(name="mod"), expLst={e1,e2}, attr=attr as CALL_ATTR(__)) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    'modelica_mod_<%expTypeShort(attr.ty)%>(<%var1%>,<%var2%>)'

   case CALL(path=IDENT(name="semiLinear"), expLst={e1,e2,e3}, attr=attr as CALL_ATTR(__)) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var3 = daeExp(e3, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    'semiLinear(<%var1%>,<%var2%>,<%var3%>)'

  case CALL(path=IDENT(name="max"), expLst={array}) then
    //let &tmpVar = buffer "" /*BUFD*/
    let expVar = daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
    let arr_tp_str = expTypeFromExpShort(array)
    let tvar = tempDecl(expTypeFromExpModelica(array), &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = min_max<<%arr_tp_str%>>(<%expVar%>).second;<%\n%>'
    '<%tvar%>'
  case CALL(path=IDENT(name="sum"), expLst={array}) then
    //let &tmpVar = buffer "" /*BUFD*/
    let expVar = daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
    let arr_tp_str = expTypeFromExpShort(array)
    let tvar = tempDecl(expTypeFromExpModelica(array), &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = sum_array<<%arr_tp_str%>>(<%expVar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="min"), expLst={array}) then
    //let &tmpVar = buffer "" /*BUFD*/
    let expVar = daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
    let arr_tp_str = expTypeFromExpShort(array)
    let tvar = tempDecl(expTypeFromExpModelica(array), &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = min_max<<%arr_tp_str%>>(<%expVar%>).first;<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="fill"), expLst=val::dims, attr=attr as CALL_ATTR(__)) then
    let valExp = daeExp(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
    let dimsExp = (dims |> dim =>    daeExp(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation) ;separator="][")

    let ty_str = '<%expTypeShort(attr.ty)%>'
  //previous multi_array
  // let tmp_type_str =  'multi_array<<%ty_str%>,<%listLength(dims)%>>'
    let tmp_type_str =  'DynArrayDim<%listLength(dims)%><<%ty_str%>>'

    let tvar = tempDecl(tmp_type_str, &varDecls /*BUFD*/)

    let &preExp += '<%tvar%>.setDims(<%dimsExp%>);<%\n%>'

    let &preExp += 'fill_array<<%ty_str%>>(<%tvar%>, <%valExp%>);<%\n%>'
    '<%tvar%>'
  case CALL(path=IDENT(name="$_start"), expLst={arg}) then
    daeExpCallStart(arg, context, preExp, varDecls,simCode,useFlatArrayNotation)


  case CALL(path=IDENT(name="cat"), expLst=dim::a0::arrays, attr=attr as CALL_ATTR(__)) then
    let dim_exp = daeExp(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
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
    let a0str = daeExp(a0, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
    let arrays_exp = (arrays |> array =>
    '<%tvar%>_list.push_back(&<%daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)%>);' ;separator="\n")
    let &preExp +=
    'vector<BaseArray<<%ty_str%>>* > <%tvar%>_list;
     <%tvar%>_list.push_back(&<%a0str%>);
     <%arrays_exp%>
     cat_array<<%ty_str%> >(<%dim_exp%>,<%tvar%>, <%tvar%>_list );
    '
    '<%tvar%>'

  case CALL(path=IDENT(name="promote"), expLst={A, n}, attr=attr as CALL_ATTR(ty=ty)) then
  //match A
    //case component as CREF(componentRef=cr, ty=ty) then
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let var2 = daeExp(n, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
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
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let type_str = expTypeFromExpShort(A)
    let arr_tp_str = '<%expTypeFromExpArray(A)%>'
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'transpose_array< <%type_str%> >(<%tvar%>,<%var1%>);<%\n%>'
    '<%tvar%>'

   case CALL(path=IDENT(name="cross"), expLst={v1, v2},attr=CALL_ATTR(ty=ty as T_ARRAY(dims=dims))) then
    let var1 = daeExp(v1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let var2 = daeExp(v2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then 'int'
                        case T_ARRAY(ty=T_ENUMERATION(__)) then 'int'
                        else 'double'
    let tvar = tempDecl('multi_array<<%type%>,<%listLength(dims)%>>', &varDecls /*BUFD*/)
    let &preExp += 'assign_array(<%tvar%>,cross_array<<%type%>>(<%var1%>,<%var2%>));<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="identity"), expLst={A}) then
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let arr_tp_str = '<%expTypeFromExpArray(A)%>'
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'identity_alloc_<%arr_tp_str%>(<%var1%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'

   case CALL(path=IDENT(name="rem"),
             expLst={e1, e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    let typeStr = expTypeFromExpShort(e1)
    'modelica_rem_<%typeStr%>(<%var1%>,<%var2%>)'


   case CALL(path=IDENT(name="String"),
             expLst={s, format}) then
    let emptybuf = ""
  let tvar = tempDecl("string", &varDecls /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let formatExp = daeExp(format, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let typeStr = expTypeFromExpModelica(s)
    let &preExp += 'string <%tvar%> = lexical_cast<std::string>(<%sExp%>);<%\n%>'
    '<%tvar%>'

   case CALL(path=IDENT(name="String"),
             expLst={s, minlen, leftjust}) then
    let emptybuf = ""
    let tvar = tempDecl("string", &emptybuf /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let minlenExp = daeExp(minlen, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let leftjustExp = daeExp(leftjust, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let typeStr = expTypeFromExpModelica(s)
    let &preExp += 'string <%tvar%> = lexical_cast<string>(<%sExp%>);<%\n%>'
    '<%tvar%>'


  //hierhier todo
  case CALL(path=IDENT(name="String"),
            expLst={s, minlen, leftjust, signdig}) then
  let emptybuf = ""
    let tvar = tempDecl("string", &emptybuf /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let minlenExp = daeExp(minlen, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let leftjustExp = daeExp(leftjust, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let signdigExp = daeExp(signdig, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let &preExp +=  'string <%tvar%> = lexical_cast<string>(<%sExp%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="delay"),
            expLst={ICONST(integer=index), e, d, delayMax}) then
    let tvar = tempDecl("double", &varDecls /*BUFD*/)
    let var1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let var2 = daeExp(d, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let var3 = daeExp(delayMax, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let &preExp += '<%tvar%> = delay(<%index%>, <%var1%>,  <%var2%>, <%var3%>);<%\n%>'
    '<%tvar%>'


  case CALL(path=IDENT(name="integer"),
            expLst={toBeCasted}) then
    let castedVar = daeExp(toBeCasted, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    '((int)<%castedVar%>)'

   case CALL(path=IDENT(name="Integer"),
             expLst={toBeCasted}) then
    let castedVar = daeExp(toBeCasted, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    '((int)<%castedVar%>)'

  case CALL(path=IDENT(name="clock"), expLst={}) then
    'mmc_clock()'

  case CALL(path=IDENT(name="noEvent"),
            expLst={e1}) then
    daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)

  case CALL(path=IDENT(name="anyString"),
            expLst={e1}) then
    'mmc_anyString(<%daeExp(e1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)%>)'

  case CALL(path=IDENT(name="mmc_get_field"),
            expLst={s1, ICONST(integer=i)}) then
    let tvar = tempDecl("modelica_metatype", &varDecls /*BUFD*/)
    let expPart = daeExp(s1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let &preExp += '<%tvar%> = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%expPart%>), <%i%>));<%\n%>'
    '<%tvar%>'

  case exp as CALL(attr=attr as CALL_ATTR(ty=T_NORETCALL(__))) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let &preExp += match context
                        case FUNCTION_CONTEXT(__) then '<%funName%>(<%argStr%>);<%\n%>'
            /*multi_array else 'assign_array(<%retVar%> ,_functions.<%funName%>(<%argStr%>));<%\n%>'*/
                        else '_functions-><%funName%>(<%argStr%>);<%\n%>'
    ""
    /*Function calls with array return type*/
    case exp as CALL(attr=attr as CALL_ATTR(ty=T_ARRAY(ty=ty,dims=dims))) then

    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>' ;separator=",")
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
    let argStr = (explist |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>' ;separator=", ")
    let retType = '<%funName%>RetType /* undefined */'
    let retVar = tempDecl(retType, &varDecls)
    let &preExp += match context case FUNCTION_CONTEXT(__) then'<%funName%>(<%argStr%><%if explist then if retVar then "," %><%if retVar then '<%retVar%>'%>);<%\n%>'
    else '_functions-><%funName%>(<%argStr%><%if explist then if retVar then "," %> <%if retVar then '<%retVar%>'%>);<%\n%>'
     '<%retVar%>'

end daeExpCall;

template daeExpCallStart(Exp exp, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
  "Generates code for an asub of a cref, which becomes cref + offset."
::=
  let &varDeclsCref = buffer "" /*BUFD*/
  match exp
  case cr as CREF(__) then
    'get<%crefStartValueType(cr.componentRef)%>StartValue("<%cref(cr.componentRef, useFlatArrayNotation)%>")'
  case ASUB(exp = cr as CREF(__), sub = {sub_exp}) then
    let offset = daeExp(sub_exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let cref = cref1(cr.componentRef,simCode,context,varDeclsCref,useFlatArrayNotation)
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

template assertCommon(Exp condition, Exp message, Context context, Text &varDecls, Info info,SimCode simCode,Boolean useFlatArrayNotation)
::=
  let &preExpCond = buffer ""
  let &preExpMsg = buffer ""
  let condVar = daeExp(condition, context, &preExpCond, &varDecls,simCode,useFlatArrayNotation)
  let msgVar = daeExp(message, context, &preExpMsg, &varDecls,simCode,useFlatArrayNotation)
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
  <%preExpCond%>
  <%preExpMsg%>
  <%if msgVar then
      <<if(!<%condVar%>)
        throw std::runtime_error(<%msgVar%>);>>
      else
      <<if(!<%condVar%>)
        throw std::runtime_error();>>%>
  >>

end assertCommon;

template infoArgs(Info info)
::=
  match info
  case INFO(__) then '"<%fileName%>",<%lineNumberStart%>,<%columnNumberStart%>,<%lineNumberEnd%>,<%columnNumberEnd%>,<%isReadOnly%>'
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


template daeExpLunary(Exp exp, Context context, Text &preExp /*BUFP*/,
                      Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for a logical unary expression."
::=
match exp
case LUNARY(__) then
  let e = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  match operator
  case NOT(__) then '(!<%e%>)'
end daeExpLunary;

template daeExpLbinary(Exp exp, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
 "Generates code for a logical binary expression."
::=
match exp
case LBINARY(__) then
  let e1 = daeExp(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  let e2 = daeExp(exp2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  match operator
  case AND(__) then '(<%e1%> && <%e2%>)'
  case OR(__)  then '(<%e1%> || <%e2%>)'
  else "daeExpLbinary:ERR"
end daeExpLbinary;

template daeExpBinary(Operator it, Exp exp1, Exp exp2, Context context, Text &preExp,Text &varDecls /*BUFP*/, SimCode simCode, Boolean useFlatArrayNotation) ::=
  let e1 = daeExp(exp1, context, &preExp, &varDecls, simCode, useFlatArrayNotation)
  let e2 = daeExp(exp2, context, &preExp, &varDecls, simCode, useFlatArrayNotation)
  match it
  case ADD(__) then '(<%e1%> + <%e2%>)'
  case SUB(__) then '(<%e1%> - <%e2%>)'
  case MUL(__) then '(<%e1%> * <%e2%>)'
  case DIV(__) then '(<%e1%> / <%e2%>)'
  case POW(__) then 'pow(<%e1%>, <%e2%>)'
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
  // previous multiarray let &preExp += 'assign_array(<%var1%>,multiply_array<<%type1%>,<%listLength(dims)%>>(<%e1%>, <%e2%>));//testhier1<%\n%>'
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
  // previous multi_array let &preExp += 'assign_array(<%var1%>,multiply_array<<%type1%>,<%listLength(dims)%>>(<%e1%>, <%e2%>));//testhier1<%\n%>'
    let &preExp +='multiply_array<<%type1%>>(<%e1%>, <%e2%>, <%var1%>);//testhier1<%\n%>'
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
  // previous multiarray let &preExp += 'assign_array(<%var1%>,multiply_array<<%type1%>,<%listLength(dims)%>>(<%e1%>, <%e2%>));//testhier1<%\n%>'
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
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then 'int>'
                        case T_ARRAY(ty=T_ENUMERATION(__)) then 'int'
                        else 'double'
    'dot_array<<%type%>>(<%e1%>, <%e2%>)'
  case DIV_SCALAR_ARRAY(__) then "daeExpBinary:ERR DIV_SCALAR_ARRAY not supported"
  case POW_ARRAY_SCALAR(__) then "daeExpBinary:ERR POW_ARRAY_SCALAR not supported"
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


template daeExpSconst(String string, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for a string constant."
::=
  '"<%Util.escapeModelicaStringToCString(string)%>"'
end daeExpSconst;

template daeExpUnary(Exp exp, Context context, Text &preExp /*BUFP*/,
                     Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for a unary expression."
::=
match exp
case UNARY(__) then
  let e = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
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


template daeExpCrefRhs(Exp exp, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for a component reference on the right hand side of an
 expression."
::=
  match exp

   // A record cref without subscripts (i.e. a record instance) is handled
  // by daeExpRecordCrefRhs only in a simulation context, not in a function.
  case CREF(componentRef = cr, ty = t as T_COMPLEX(complexClassType = RECORD(path = _))) then
    match context case FUNCTION_CONTEXT(__) then
      '<%daeExpCrefRhs2(exp, context, &preExp, &varDecls,simCode,useFlatArrayNotation)%>'
    else
      daeExpRecordCrefRhs(t, cr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)

  case CREF(componentRef = cr, ty = T_FUNCTION_REFERENCE_FUNC(__)) then
    '((modelica_fnptr)boxptr_<%crefFunctionName(cr)%>)'
  case CREF(componentRef = cr, ty = T_FUNCTION_REFERENCE_VAR(__)) then
    '((modelica_fnptr) _<%crefStr(cr)%>)'
  else '<%daeExpCrefRhs2(exp, context, &preExp, &varDecls,simCode,useFlatArrayNotation)%>'
end daeExpCrefRhs;

template daeExpRecordCrefRhs(DAE.Type ty, ComponentRef cr, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
::=
match ty
case T_COMPLEX(complexClassType = record_state, varLst = var_lst) then
  let vars = var_lst |> v => daeExp(makeCrefRecordExp(cr,v), context, &preExp, &varDecls,simCode,useFlatArrayNotation)
             ;separator=", "
  let record_type_name = underscorePath(ClassInf.getStateName(record_state))
  let ret_type = '<%record_type_name%>RetType'
  let ret_var = tempDecl(ret_type, &varDecls)
  let &preExp += '_functions-><%record_type_name%>(<%vars%>,<%ret_var%>);<%\n%>/*testfunction*/'
  '<%ret_var%>'
end daeExpRecordCrefRhs;


template daeExpCrefRhs2(Exp ecr, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for a component reference."
::=
  match ecr
  case component as CREF(componentRef=cr, ty=ty) then
    let box = daeExpCrefRhsArrayBox(cr,ty, context, &preExp, &varDecls,simCode)
    if box then
     box
    else if crefIsScalar(cr, context) then
      let cast = match ty case T_INTEGER(__) then ""
                          case T_ENUMERATION(__) then "" //else ""
      '<%cast%><%contextCref(cr,context,simCode,useFlatArrayNotation)%>'
    else
     if crefSubIsScalar(cr) then
      // The array subscript results in a scalar
      let arrName = contextCref(crefStripLastSubs(cr), context,simCode,useFlatArrayNotation)
      let arrayType = expTypeArray(ty)
      //let dimsLenStr = listLength(crefSubs(cr))
    // previous multi_array ;separator="][")
      let dimsValuesStr = (crefSubs(cr) |> INDEX(__) =>
          daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
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
      let arrName = contextArrayCref(cr, context)
      let arrayType = expTypeFlag(ty, 6)
      /* let dimstr = listLength(crefSubs(cr))
      let dimsValuesStr = (crefSubs(cr) |> INDEX(__) =>
          daeExp(exp, context, &preExp , &varDecls ,simCode, useFlatArrayNotation)
        ;separator="][")*/
      let tmp = tempDecl(arrayType, &varDecls /*BUFD*/)
      let spec1 = daeExpCrefRhsIndexSpec(crefSubs(cr), context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
      let &preExp += 'create_array_from_shape(<%spec1%>,<%arrName%>,<%tmp%>);<%\n%>'
      tmp
end daeExpCrefRhs2;

template daeExpCrefRhsIndexSpec(list<Subscript> subs, Context context,
                                Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Helper to daeExpCrefRhs."
::=

  let nridx_str = listLength(subs)
  //let tmp = tempDecl("index_type", &varDecls /*BUFD*/)
  let tmp_shape = tempDecl("vector<size_t>", &varDecls /*BUFD*/)
  let tmp_indeces = tempDecl("idx_type", &varDecls /*BUFD*/)
  let idx_str = (subs |> sub  hasindex i1 =>
      match sub
      case INDEX(__) then
         let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
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
        let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
        let &preExp +=  '<%tmp_idx%>.assign(<%expPart%>.getData(),<%expPart%>.getData()+<%expPart%>.getNumElems());<%\n%>
                         <%tmp_shape%>.push_back(<%expPart%>.getDims()[0]);<%\n%>
                         <%tmp_indeces%>.push_back(<%tmp_idx%>);<%\n%>'
       ''
    ;separator="\n ")
   << make_pair(<%tmp_shape%>,<%tmp_indeces%>) >>
end daeExpCrefRhsIndexSpec;





template daeExpCrefRhsArrayBox(ComponentRef cr,DAE.Type ty, Context context, Text &preExp /*BUFP*/,
                               Text &varDecls /*BUFP*/,SimCode simCode)
 "Helper to daeExpCrefRhs."
::=
 cref2simvar(cr, simCode) |> var as SIMVAR(index=i) =>
    match varKind
        case STATE(__)     then
              let statvar = '__z[<%i%>]'
              let tmpArr = '<%daeExpCrefRhsArrayBox2(statvar,ty,context,preExp,varDecls,simCode)%>'
              tmpArr
        case STATE_DER(__)      then
              let statvar = '__zDot[<%i%>]'
              let tmpArr = '<%daeExpCrefRhsArrayBox2(statvar,ty,context,preExp,varDecls,simCode)%>'
              tmpArr
        else
            match context
              case FUNCTION_CONTEXT(__) then ''
            else
            match ty
            case t as T_ARRAY(ty=aty,dims=dims)        then
            let tmpArr ='<%arrayCrefCStr(cr,context)%>'
            tmpArr
            else ''

end daeExpCrefRhsArrayBox;


template daeExpCrefRhsArrayBox2(Text var,DAE.Type type, Context context, Text &preExp /*BUFP*/,
                               Text &varDecls /*BUFP*/,SimCode simCode) ::=
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

template cref1(ComponentRef cr, SimCode simCode, Context context, Text &varDecls, Boolean useFlatArrayNotation) ::=
  match cr
  case CREF_IDENT(ident = "xloc") then '<%representationCref(cr, simCode,context,varDecls, useFlatArrayNotation)%>'
  case CREF_IDENT(ident = "time") then
   match context
    case  ALGLOOP_CONTEXT(genInitialisation=false)
    then "_system->_simTime"
    else
    "_simTime"
    end match
   //filter key words for variable names
   case CREF_IDENT(ident = "unsigned") then
   'unsigned_'
   case CREF_IDENT(ident = "string") then
   'string_'

  else '<%representationCref(cr, simCode,context, varDecls, useFlatArrayNotation) %>'
end cref1;

template representationCref(ComponentRef inCref, SimCode simCode, Context context, Text &varDecls, Boolean useFlatArrayNotation) ::=
  cref2simvar(inCref, simCode) |> var as SIMVAR(__) =>
  match varKind
    case STATE(__)        then
        << <%representationCref1(inCref,var,simCode,context, useFlatArrayNotation)%> >>
    case STATE_DER(__)   then
        << <%representationCref2(inCref,var,simCode,context)%> >>
    case VARIABLE(__) then
     match var
        case SIMVAR(index=-2) then
         '<%localcref(inCref, useFlatArrayNotation)%>'
    else
        match context
            case ALGLOOP_CONTEXT(genInitialisation = false, genJacobian=false)
                then  '_system-><%cref(inCref, useFlatArrayNotation)%>'
            case ALGLOOP_CONTEXT(genInitialisation = false, genJacobian=true)
                then  '_system-><%crefWithoutIndexOperator(inCref)%>'
        else
            '<%varToString(inCref,context, useFlatArrayNotation)%>'
  else
    match context
    case ALGLOOP_CONTEXT(genInitialisation = false)
        then
        let &varDecls += '//_system-><%cref(inCref, useFlatArrayNotation)%>; definition of global variable<%\n%>'
        '_system-><%cref(inCref, useFlatArrayNotation)%>'
    else
        '<%cref(inCref, useFlatArrayNotation)%>'
end representationCref;



template representationCrefDerVar(ComponentRef inCref, SimCode simCode, Context context) ::=
  cref2simvar(inCref, simCode) |> SIMVAR(__) =>'__zDot[<%index%>]'
end representationCrefDerVar;



template representationCref1(ComponentRef inCref,SimVar var, SimCode simCode, Context context, Boolean useFlatArrayNotation) ::=
   match var
    case SIMVAR(index=i) then
    match i
   case -1 then
  '<%cref2(inCref, useFlatArrayNotation)%>'
   case _  then
   << __z[<%i%>] >>
end representationCref1;

template representationCref2(ComponentRef inCref, SimVar var,SimCode simCode, Context context) ::=
 match var
case(SIMVAR(index=i)) then
  match context
         case JACOBIAN_CONTEXT()
                then   <<<%crefWithoutIndexOperator(inCref)%>>>
        else
             <<__zDot[<%i%>]>>
end representationCref2;

template helpvarlength(SimCode simCode)
::=
match simCode
case SIMCODE(__) then
  <<
  0
  >>
end helpvarlength;

template zerocrosslength(SimCode simCode)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__))) then
   let size = listLength(zeroCrossings)
  <<
   <%intSub(listLength(zeroCrossings), vi.numTimeEvents)%>
  >>
end zerocrosslength;


template timeeventlength(SimCode simCode)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__))) then

  <<
  <%vi.numTimeEvents%>
  >>
end timeeventlength;



template DimZeroFunc(SimCode simCode)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
  int <%lastIdentOfPath(modelInfo.name)%>::getDimZeroFunc()
  {
    return _dimZeroFunc;
  }
  >>
end DimZeroFunc;








template SetIntialStatus(SimCode simCode)
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
end SetIntialStatus;

template GetIntialStatus(SimCode simCode)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
   bool <%lastIdentOfPath(modelInfo.name)%>Initialize::initial()
    {
      return _initial;
    }
  >>
end GetIntialStatus;

template daeExpRelation(Exp exp, Context context, Text &preExp,Text &varDecls,SimCode simCode,Boolean useFlatArrayNotation)
::=
match exp
case rel as RELATION(__) then
match rel.optionExpisASUB
 case NONE() then
    daeExpRelation2(rel.operator,rel.index,rel.exp1,rel.exp2, context, preExp,varDecls,simCode, useFlatArrayNotation)
 case SOME((exp,i,j)) then
    let e1 = daeExp(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/,simCode,useFlatArrayNotation)
    let e2 = daeExp(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/,simCode,useFlatArrayNotation)
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
template daeExpRelation2(Operator op, Integer index,Exp exp1, Exp exp2, Context context, Text &preExp,Text &varDecls,SimCode simCode, Boolean useFlatArrayNotation) ::=
  let e1 = daeExp(exp1, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
  let e2 = daeExp(exp2, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
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


template daeExpIf(Exp cond, Exp then_, Exp else_, Context context, Text &preExp, Text &varDecls,SimCode simCode,Boolean useFlatArrayNotation) ::=
  let condExp = daeExp(cond, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
  let &preExpThen = buffer ""
  let eThen = daeExp(then_, context, &preExpThen, &varDecls,simCode,useFlatArrayNotation)
  let &preExpElse = buffer ""
  let eElse = daeExp(else_, context, &preExpElse /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
      let condVar = tempDecl("bool", &varDecls /*BUFD*/)
      //let resVarType = expTypeFromExpArrayIf(else_,context,preExp,varDecls,simCode)
      let resVar  = expTypeFromExpArrayIf(else_,context,preExp,varDecls,simCode, useFlatArrayNotation)
      /*previous multi_array instead of .assign:
    'assign_array(<%resVar%>,<%eThen%>);'
    */
    let &preExp +=
      <<
      <%condVar%> = <%condExp%>;
      if (<%condVar%>) {
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




template expTypeFromExpArrayIf(Exp exp, Context context, Text &preExp /*BUFP*/,
                     Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
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
    '<%daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>'
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

template equationAlgorithm(SimEqSystem eq, Context context,Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
 "Generates an equation that is an algorithm."
::=
match eq
case SES_ALGORITHM(__) then
  (statements |> stmt =>
    algStatement(stmt, context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  ;separator="\n")
end equationAlgorithm;


template algStmtTupleAssign(DAE.Statement stmt, Context context,
                   Text &varDecls /*BUFP*/, SimCode simCode, Boolean useFlatArrayNotation)
 "Generates a tuple assigment algorithm statement."
::=
match stmt
case STMT_TUPLE_ASSIGN(exp=CALL(__)) then
  let &preExp = buffer "" /*BUFD*/
  let &afterExp = buffer "" /*BUFD*/
  let crefs = (expExpLst |> e => ExpressionDump.printExpStr(e) ;separator=", ")
  let marker = '(<%crefs%>) = <%ExpressionDump.printExpStr(exp)%>'
  let &preExp += '/* algStmtTupleAssign: preExp buffer created for <%marker%> */<%\n%>'
  let &afterExp += '/* algStmtTupleAssign: afterExp buffer created for <%marker%> */<%\n%>'
  let retStruct = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode, useFlatArrayNotation)
  //previous multi_array let rhsStr = 'boost::get<<%i1%>>(<%retStruct%>.data)'

  let lhsCrefs = (expExpLst |> cr hasindex i1 fromindex 0 =>
                    let rhsStr = 'boost::get<<%i1%>>(<%retStruct%>.data)/*testhier*/'
                    writeLhsCref(cr, rhsStr, context, &afterExp /*BUFC*/, &varDecls /*BUFD*/ , simCode, useFlatArrayNotation)
                  ;separator="\n";empty)
  <<
  /* algStmtTupleAssign: preExp printout <%marker%>*/

  <%preExp%>
  /* algStmtTupleAssign: writeLhsCref <%marker%> */
  <%lhsCrefs%>
  /* algStmtTupleAssign: afterExp printout <%marker%> */
  <%afterExp%>
  >>

else error(sourceInfo(), 'algStmtTupleAssign failed')
end algStmtTupleAssign;



template error(Absyn.Info srcInfo, String errMessage)
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




template algStatementWhenElse(Option<DAE.Statement> stmt, Text &varDecls /*BUFP*/,SimCode simCode,Context context,Boolean useFlatArrayNotation)
 "Helper to algStmtWhen."
::=
match stmt
case SOME(when as STMT_WHEN(__)) then
  let &varDeclsCref = buffer "" /*BUFD*/
  let elseCondStr = (when.conditions |> e => ' || (<%cref1(e, simCode, context, varDeclsCref,useFlatArrayNotation)%> && !_event_handling.pre(<%cref1(e, simCode, context, varDeclsCref,useFlatArrayNotation)%>,"<%cref1(e, simCode, context, varDeclsCref,useFlatArrayNotation)%>"))')
  <<
  else if (0<%elseCondStr%>) {
    <% when.statementLst |> stmt =>  algStatement(stmt, contextSimulationDiscrete,&varDecls,simCode,useFlatArrayNotation)
       ;separator="\n"%>
  }
  <%algStatementWhenElse(when.elseWhen, &varDecls,simCode,context,useFlatArrayNotation)%>
  >>
end algStatementWhenElse;


template writeLhsCref(Exp exp, String rhsStr, Context context, Text &preExp /*BUFP*/,
              Text &varDecls /*BUFP*/, SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for writing a returnStructur to var."
::=
match exp
case ecr as CREF(componentRef=WILD(__)) then
  ''
case CREF(ty= t as DAE.T_ARRAY(__)) then
  let lhsStr = scalarLhsCref(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  match context
  case SIMULATION_CONTEXT(__) then
    <<
   <%lhsStr%>.assign(<%rhsStr%> )/*blabla*/;
    >>
  else
    '<%lhsStr%>.assign(<%rhsStr%>);'
  //previous multi_array '<%lhsStr%> = <%rhsStr%>;' '<%lhsStr%>.assign(<%rhsStr%>);'
case UNARY(exp = e as CREF(ty= t as DAE.T_ARRAY(__))) then
  let lhsStr = scalarLhsCref(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  match context
  case SIMULATION_CONTEXT(__) then
    <<
    usub_<%expTypeShort(t)%>_array(&<%rhsStr%>);<%\n%>
    copy_<%expTypeShort(t)%>_array_data_mem(&<%rhsStr%>, &<%lhsStr%>);
    >>
  else
    '<%lhsStr%> = -<%rhsStr%>;'
case CREF(__) then
  let lhsStr = scalarLhsCref(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  <<
  <%lhsStr%> = <%rhsStr%>;
  >>
case UNARY(exp = e as CREF(__)) then
  let lhsStr = scalarLhsCref(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
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
                 let lhsstr = scalarLhsCref(lhs, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
                 let indxstr = (indxs |> i => '<%i%>' ;separator=",")
                 '<%lhsstr%> = <%typeShort%>_get<%fcallsuf%>(&<%rhsStr%>, <%indxstr%>);'
              ;separator="\n")
  <<
  <%body%>
  >>
case ASUB(__) then
  error(sourceInfo(), 'writeLhsCref UNHANDLED ASUB (should never be part of a lhs expression): <%ExpressionDump.printExpStr(exp)%> = <%rhsStr%>')
else
  error(sourceInfo(), 'writeLhsCref UNHANDLED: <%ExpressionDump.printExpStr(exp)%> = <%rhsStr%>')

end writeLhsCref;


template scalarLhsCref(Exp ecr, Context context, Text &preExp,Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation) ::=
match ecr
case ecr as CREF(componentRef=CREF_IDENT(subscriptLst=subs)) then
  if crefNoSub(ecr.componentRef) then
    contextCref(ecr.componentRef, context,simCode,useFlatArrayNotation)
  else
    daeExpCrefRhs(ecr, context, &preExp, &varDecls, simCode, useFlatArrayNotation)
case ecr as CREF(componentRef=cr as CREF_QUAL(__)) then
    if crefIsScalar(cr, context) then
      contextCref(ecr.componentRef, context,simCode,useFlatArrayNotation)
    else
      let arrName = contextCref(crefStripSubs(cr), context, simCode,useFlatArrayNotation)
      <<
       <%arrName%>(<%threadDimSubList(crefDims(cr),crefSubs(cr),context,&preExp,&varDecls,simCode, useFlatArrayNotation)%>)
      >>

case ecr as CREF(componentRef=CREF_QUAL(__)) then
    contextCref(ecr.componentRef, context,simCode,useFlatArrayNotation)
else
    "ONLY_IDENT_OR_QUAL_CREF_SUPPORTED_SLHS"
end scalarLhsCref;



template threadDimSubList(list<Dimension> dims, list<Subscript> subs, Context context, Text &preExp, Text &varDecls,SimCode simCode, Boolean useFlatArrayNotation)
  "Do direct indexing since sizes are known during compile-time"
::=
  match subs
  case {} then error(sourceInfo(),"Empty dimensions in indexing cref?")

  case {sub as INDEX(__)} then
    match dims
    case {dim} then
       let estr = daeExp(sub.exp, context, &preExp, &varDecls, simCode, useFlatArrayNotation)
      '<%estr%>'
    else error(sourceInfo(),"Less subscripts that dimensions in indexing cref? That's odd!")

  case (sub as INDEX(__))::subrest then
    match dims
      case _::dimrest
      then

        let estr = daeExp(sub.exp, context, &preExp, &varDecls, simCode, useFlatArrayNotation)
        '((<%estr%><%
          dimrest |> dim =>
          match dim
          case DIM_INTEGER(__) then '-1)*<%integer%>'
          case DIM_BOOLEAN(__) then '*2'
          case DIM_ENUM(__) then '*<%size%>'
          else error(sourceInfo(),"Non-constant dimension in simulation context")
        %>)<%match subrest case {} then "" else '+<%threadDimSubList(dimrest, subrest, context, &preExp, &varDecls, simCode, useFlatArrayNotation)%>'%>'
      else error(sourceInfo(),"Less subscripts that dimensions in indexing cref? That's odd!")
  else error(sourceInfo(),"Non-index subscript in indexing cref? That's odd!")
end threadDimSubList;


template elseExpr(DAE.Else it, Context context, Text &preExp, Text &varDecls,SimCode simCode,Boolean useFlatArrayNotation) ::=
  match it
  case NOELSE(__) then ""
  case ELSEIF(__) then
    let &preExp = buffer ""
    let condExp = daeExp(exp, context, &preExp, &varDecls,simCode, useFlatArrayNotation)
    <<
    else {
    <%preExp%>
    if (<%condExp%>) {

      <%statementLst |> it => algStatement(it, context, &varDecls,simCode,useFlatArrayNotation)
      ;separator="\n"%>

    }
    <%elseExpr(else_, context, &preExp, &varDecls,simCode,useFlatArrayNotation)%>
    }
    >>
  case ELSE(__) then
    <<
    else {
      <%statementLst |> it => algStatement(it, context, &varDecls,simCode,useFlatArrayNotation)
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


template functionOnlyZeroCrossing(list<ZeroCrossing> zeroCrossings,Text& varDecls,SimCode simCode)
  "Generates function in simulation file."
::=

  let zeroCrossingsCode = zeroCrossingsTpl2(zeroCrossings, &varDecls /*BUFD*/, simCode)
  <<

    <%zeroCrossingsCode%>
  >>
end functionOnlyZeroCrossing;


template zeroCrossingsTpl2(list<ZeroCrossing> zeroCrossings, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for zero crossings."
::=

  (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 =>
    zeroCrossingTpl2(i0, relation_, &varDecls /*BUFD*/,simCode)
  ;separator="\n";empty)
end zeroCrossingsTpl2;

/*
template zeroCrossingTpl2(Integer index1, Exp relation, Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
 "Generates code for a zero crossing."
::=
  match relation
  case RELATION(index=zerocrossingIndex) then
    let &preExp = buffer "" /*BUFD*/
    let e1 = daeExp(exp1, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let op = zeroCrossingOpFunc(operator)
    let e2 = daeExp(exp2, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let res = tempDecl("bool", &varDecls /*BUFC*/)
    <<
    <%preExp%>
    <%res%>=(<%e1%><%op%><%e2%>);
    _condition<%zerocrossingIndex%>=<%res%>;
    >>
end zeroCrossingTpl2;
*/


template zeroCrossingTpl2(Integer index1, Exp relation, Text &varDecls /*BUFP*/,SimCode simCode)
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
      <%name%>.assign(<%name%>_data);
    >>

  else error(sourceInfo(), 'literalExpConst failed: <%printExpStr(lit)%>')
end literalExpConstImpl;



/*
template timeEventcondition(list<SampleCondition> sampleConditions,Text &varDecls /*BUFP*/,SimCode simCode)
::=
  (sampleConditions |> (relation_,index)  =>
    timeEventcondition1(index, relation_, &varDecls /*BUFD*/,simCode)
  ;separator="\n")
end timeEventcondition;

template timeEventcondition1(Integer index1, Exp relation, Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
::=
  match relation
  case CALL(path=IDENT(name="sample"), expLst={ICONST(integer=index), start, interval}) then
    let &preExp = buffer "" /*BUFD*/
    let eStart = daeExp(start, contextOther, &preExp, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let eInterval = daeExp(interval, contextOther, &preExp, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let res = tempDecl("bool", &varDecls /*BUFC*/)
     <<
     <%preExp%>
     <%res%>= false;
     _condition<%intSub(index, 1)%> = <%res%>;
      event_times_type sample<%intSub(index, 1)%> = _event_handling.makePeriodeEvents(<%eStart%>,te,<%eInterval%>,<%intSub(index, 1)%>);
     _event_handling.addTimeEvents(sample<%intSub(index, 1)%>);
    >>
end timeEventcondition1;
*/



template handleEvent(SimCode simCode)
::=
match simCode
case SIMCODE(__) then
  <<
  >>
end handleEvent;

template checkConditions(list<ZeroCrossing> zeroCrossings,list<SimWhenClause> whenClauses,SimCode simCode, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let zeroCrossingsCode = checkConditions1(zeroCrossings, &varDecls /*BUFD*/, simCode, useFlatArrayNotation)
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
<<
   bool <%lastIdentOfPath(modelInfo.name)%>::checkConditions()
   {
   _callType = IContinuous::DISCRETE;
    return  _event_handling.checkConditions(0,true);
      _callType = IContinuous::CONTINUOUS;
   }
>>
end checkConditions;


template getCondition(list<ZeroCrossing> zeroCrossings,list<SimWhenClause> whenClauses,SimCode simCode, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let zeroCrossingsCode = checkConditions1(zeroCrossings, &varDecls /*BUFD*/, simCode, useFlatArrayNotation)
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
            throw std::runtime_error("Wrong condition index " + boost::lexical_cast<string>(index) );

       };

   }
>>
end match
end getCondition;

template checkConditions1(list<ZeroCrossing> zeroCrossings, Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
::=

  (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 =>
    checkConditions2(i0, relation_, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  ;separator="\n";empty)
end checkConditions1;

template checkConditions2(Integer index1, Exp relation, Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
::=
  match relation
  case RELATION(index=zerocrossingIndex) then
    let &preExp = buffer "" /*BUFD*/
    let e1 = daeExp(exp1, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let op = zeroCrossingOpFunc(operator)
    let e2 = daeExp(exp2, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
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

template handleSystemEvents(list<ZeroCrossing> zeroCrossings,list<SimWhenClause> whenClauses,SimCode simCode)
::=

  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
  bool <%lastIdentOfPath(modelInfo.name)%>::handleSystemEvents(bool* events)
  {
    _callType = IContinuous::DISCRETE;

    bool restart=true;
    bool state_vars_reinitialized = false;
    int iter=0;

    while(restart && !(iter++ > 100))
    {
            bool st_vars_reinit = false;
            //iterate and handle all events inside the eventqueue
            restart=_event_handling.IterateEventQueue(st_vars_reinit);
            state_vars_reinitialized = state_vars_reinitialized || st_vars_reinit;

            saveAll();
     }

    if(iter>100 && restart ){
     throw std::runtime_error("Number of event iteration steps exceeded at time: " + boost::lexical_cast<string>(_simTime) );}
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

template giveZeroFunc1(list<ZeroCrossing> zeroCrossings,SimCode simCode, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let &prexp = buffer "" /*BUFD*/
  let zeroCrossingsCode = giveZeroFunc2(zeroCrossings, &varDecls /*BUFD*/,prexp, simCode, useFlatArrayNotation)
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

template setConditions(SimCode simCode)
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

template geConditions(SimCode simCode)
::=
 match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
<<
 void <%lastIdentOfPath(modelInfo.name)%>::getConditions(bool* c)
  {
     SystemDefaultImplementation::getConditions(c);
  }
>>
end geConditions;

template isConsistent(SimCode simCode)
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

template saveConditions(SimCode simCode)
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

template giveZeroFunc2(list<ZeroCrossing> zeroCrossings, Text &varDecls /*BUFP*/,Text &preExp,SimCode simCode, Boolean useFlatArrayNotation)
::=

  (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 =>
    giveZeroFunc3(i0, relation_, &varDecls /*BUFD*/,&preExp,simCode, useFlatArrayNotation)
  ;separator="\n";empty)
end giveZeroFunc2;

template giveZeroFunc3(Integer index1, Exp relation, Text &varDecls /*BUFP*/,Text &preExp ,SimCode simCode,Boolean useFlatArrayNotation)
::=

  match relation
  case rel as  RELATION(index=zerocrossingIndex) then
      let e1 = daeExp(exp1, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
      let e2 = daeExp(exp2, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
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
                f[<%index1%>]=(<%e1%> - 1e-9 - <%e2%>);
           else
                f[<%index1%>]=(<%e2%> - <%e1%> - 1e-9);
       >>
      case GREATER(__) then
       <<
         if(_conditions[<%zerocrossingIndex%>])
                f[<%index1%>]=(<%e2%> - <%e1%> - 1e-9);
           else
                f[<%index1%>]=(<%e1%> - 1e-9 - <%e2%>);
         >>
      case GREATEREQ(__) then
        <<
         if(_conditions[<%zerocrossingIndex%>])
                f[<%index1%>]=(<%e2%> - <%e1%> - 1e-9);
           else
                f[<%index1%>]=(<%e1%> - 1e-9 - <%e2%>);
         >>
    else
       <<
          f[<%index1%>]=-1;
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

/*
template giveZeroFunc3(Integer index1, Exp relation, Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
::=
 let &preExp = buffer "" /*BUFD*/
  match relation
  case rel as  RELATION(index=zerocrossingIndex) then
       let e1 = daeExp(exp1, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
      let e2 = daeExp(exp2, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
       match rel.operator

        case LESS(__)
        case LESSEQ(__) then
       <<
         if(_event_handling.pre(_condition<%zerocrossingIndex%>,"_condition<%zerocrossingIndex%>"))
                f[<%index1%>]=(<%e1%>-1e-11-<%e2%>);
           else
                f[<%index1%>]=(<%e2%>-<%e1%>-1e-11);
      >>
      case GREATER(__)
      case GREATEREQ(__) then
        <<
         if(_event_handling.pre(_condition<%zerocrossingIndex%>,"_condition<%zerocrossingIndex%>"))
                f[<%index1%>]=(<%e2%>-<%e1%>-1e-11);
           else
                f[<%index1%>]=(<%e1%>-1e-11-<%e2%>);
         >>
     end match
end giveZeroFunc3;
*/

template conditionvarZero(list<ZeroCrossing> zeroCrossings,SimCode simCode)
::=
  (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 =>
    conditionvarZero1(i0, relation_, simCode)
  ;separator="\n";empty)
end conditionvarZero;

template conditionvarZero1(Integer index1, Exp relation,SimCode simCode)
::=
  match relation
  case RELATION(index=zerocrossingIndex) then
    <<
     bool _condition<%zerocrossingIndex%>;
    >>
end conditionvarZero1;

template saveconditionvar(list<ZeroCrossing> zeroCrossings,SimCode simCode)
::=
  (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 =>
    saveconditionvar1(i0, relation_, simCode)
  ;separator="\n";empty)
end saveconditionvar;

template saveconditionvar1(Integer index1, Exp relation,SimCode simCode)
::=
  match relation
  case RELATION(index=zerocrossingIndex) then
    <<
     _event_handling.save(_condition<%zerocrossingIndex%>,"_condition<%zerocrossingIndex%>");
    >>
end saveconditionvar1;




template conditionvarSample1(Integer index1, Exp relation, Text &varDecls /*BUFP*/,SimCode simCode)
::=
  match relation
  case CALL(path=IDENT(name="sample"), expLst={ICONST(integer=index), start, interval}) then
    let &preExp = buffer "" /*BUFD*/
     <<
     bool _condition<%intSub(index, 1)%>;
    >>
end conditionvarSample1;

template conditionvariable(list<ZeroCrossing> zeroCrossings,SimCode simCode)
::=
  let conditionvariable = conditionvarZero(zeroCrossings,simCode)
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

template checkForDiscreteEvents(list<ComponentRef> discreteModelVars,SimCode simCode,Boolean useFlatArrayNotation)
::=

  let changediscreteVars = (discreteModelVars |> var => match var case CREF_QUAL(__) case CREF_IDENT(__) then
       'if (_event_handling.changeDiscreteVar(<%cref(var, useFlatArrayNotation)%>,"<%cref(var, useFlatArrayNotation)%>")) {  return true; }'
       ;separator="\n")
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
  bool <%lastIdentOfPath(modelInfo.name)%>::checkForDiscreteEvents()
  {
    <%changediscreteVars%>
    return false;
  }
  >>
end checkForDiscreteEvents;
/*
template update(list<list<SimEqSystem>> continousEquations,list<SimEqSystem> discreteEquations,list<SimWhenClause> whenClauses,list<SimEqSystem> parameterEquations,SimCode simCode,Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let continous = (continousEquations |> eqs => (eqs |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFC*/,simCode,useFlatArrayNotation))
    ;separator="\n")
  let paraEquations = (parameterEquations |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    ;separator="\n")
  let discrete = (discreteEquations |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFC*/,simCode,useFlatArrayNotation)
    ;separator="\n")
  let reinit = (whenClauses |> when hasindex i0 =>
         genreinits(when, &varDecls,i0,simCode)
    ;separator="\n";empty)
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
  void <%lastIdentOfPath(modelInfo.name)%>::evaluate(const UPDATETYPE command)
  {
    <%varDecls%>

   if(command & CONTINOUS)
  {
    <%paraEquations%>
    <%continous%>
  }
   if (command & DISCRETE)
  {
    <%discrete%>
    <%reinit%>
  }
  }
  >>
end update;
*/


template equationFunctions( list<SimEqSystem> allEquationsPlusWhen,list<SimWhenClause> whenClauses, SimCode simCode, Context context, Boolean useFlatArrayNotation, Boolean enableMeasureTime)
::=

 let equation_func_calls = (allEquationsPlusWhen |> eq =>
                    equation_function_create_single_func(eq, context/*BUFC*/, simCode,"evaluate","", useFlatArrayNotation,true,enableMeasureTime)
                    ;separator="\n")





<<

 <%equation_func_calls%>
>>
end equationFunctions;

template createEvaluateAll( list<SimEqSystem> allEquationsPlusWhen,list<SimWhenClause> whenClauses, SimCode simCode, Context context, Boolean useFlatArrayNotation)
::=
  let className = lastIdentOfPathFromSimCode(simCode)
  let &varDecls = buffer "" /*BUFD*/

  let &eqfuncs = buffer ""
  let equation_all_func_calls = (allEquationsPlusWhen |> eq  =>
                    equation_function_call(eq,  context, &varDecls /*BUFC*/, simCode,"evaluate")
                    ;separator="\n")


  let reinit = (whenClauses |> when hasindex i0 =>
         genreinits(when, &varDecls,i0,simCode,context, useFlatArrayNotation)
    ;separator="\n";empty)

  <<
  bool <%className%>::evaluateAll(const UPDATETYPE command)
  {
    <%generateMeasureTimeStartCode("measuredFunctionStartValues")%>
    bool state_var_reinitialized = false;
    <%varDecls%>
    /* Evaluate Equations*/
    <%equation_all_func_calls%>
    /* Reinits */
    <%reinit%>

    <%generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "measureTimeFunctionsArray[1]")%>
    return state_var_reinitialized;
  }
 >>
end createEvaluateAll;

template createEvaluateConditions( list<SimEqSystem> allEquationsPlusWhen,list<SimWhenClause> whenClauses, SimCode simCode, Context context, Boolean useFlatArrayNotation)
::=
  let className = lastIdentOfPathFromSimCode(simCode)
  let &varDecls = buffer "" /*BUFD*/

  let &eqfuncs = buffer ""
  let equation_all_func_calls = (allEquationsPlusWhen |> eq  =>
                    equation_function_call(eq,  context, &varDecls /*BUFC*/, simCode,"evaluate")
                    ;separator="\n")


  let reinit = (whenClauses |> when hasindex i0 =>
         genreinits(when, &varDecls,i0,simCode,context,useFlatArrayNotation)
    ;separator="\n";empty)

  <<
  bool <%className%>::evaluateConditions(const UPDATETYPE command)
  {
    //the same as evaluateAll at the moment
    bool state_var_reinitialized = false;
    <%varDecls%>
    /* Evaluate Equations*/
    <%equation_all_func_calls%>
    /* Reinits */
    <%reinit%>
    return state_var_reinitialized;
  }
 >>
end createEvaluateConditions;

template createEvaluate(list<list<SimEqSystem>> odeEquations,list<SimWhenClause> whenClauses, SimCode simCode, Context context)
::=
  let className = lastIdentOfPathFromSimCode(simCode)
  let &varDecls = buffer "" /*BUFD*/




   let equation_ode_func_calls = (odeEquations |> eqs => (eqs |> eq  =>
                    equation_function_call(eq, context, &varDecls /*BUFC*/, simCode,"evaluate");separator="\n")
                   )

  <<
  void <%className%>::evaluateODE(const UPDATETYPE command)
  {
    <%generateMeasureTimeStartCode("measuredFunctionStartValues")%>
    <%varDecls%>
    /* Evaluate Equations*/
    <%equation_ode_func_calls%>
    <%generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "measureTimeFunctionsArray[0]")%>
  }
  >>
end createEvaluate;

template createEvaluateZeroFuncs( list<SimEqSystem> equationsForZeroCrossings, SimCode simCode, Context context)
::=
  let className = lastIdentOfPathFromSimCode(simCode)
  let &varDecls = buffer "" /*BUFD*/

  let &eqfuncs = buffer ""
  let equation_zero_func_calls = (equationsForZeroCrossings |> eq  =>
                    equation_function_call(eq,  context, &varDecls /*BUFC*/, simCode,"evaluate")
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

template genreinits(SimWhenClause whenClauses, Text &varDecls, Integer int,SimCode simCode, Context context, Boolean useFlatArrayNotation)
::=
  match whenClauses
    case SIM_WHEN_CLAUSE(__) then
      let &varDeclsCref = buffer "" /*BUFD*/
      let helpIf = (conditions |> e => ' || (<%cref1(e, simCode, context, varDeclsCref,useFlatArrayNotation)%> && !_event_handling.pre(<%cref1(e, simCode, context,varDeclsCref,useFlatArrayNotation)%>, "<%cref(e,useFlatArrayNotation)%>"))')
      let ifthen = functionWhenReinitStatementThen(reinits, &varDecls /*BUFP*/, simCode, useFlatArrayNotation)
      let initial_assign = match initialCall
        case true then functionWhenReinitStatementThen(reinits, &varDecls /*BUFP*/, simCode, useFlatArrayNotation)
        else '; /* nothing to do */'

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

template functionWhenReinitStatementThen(list<WhenOperator> reinits, Text &varDecls /*BUFP*/, SimCode simCode, Boolean useFlatArrayNotation)
 "Generates re-init statement for when equation."
::=
  let body = (reinits |> reinit =>
    match reinit
      case REINIT(__) then
        let &preExp = buffer "" /*BUFD*/
        let &varDeclsCref = buffer "" /*BUFD*/
        let val = daeExp(value, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
        <<
        state_var_reinitialized = true;
        <%preExp%>
        <%cref1(stateVar,simCode,contextOther,varDeclsCref,useFlatArrayNotation)%> = <%val%>;
        >>
      case TERMINATE(__) then
        let &preExp = buffer "" /*BUFD*/
        let msgVar = daeExp(message, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
        <<
        <%preExp%>
        MODELICA_TERMINATE(<%msgVar%>);
        >>
      case ASSERT(source=SOURCE(info=info)) then
        assertCommon(condition, message, contextSimulationDiscrete, &varDecls, info,simCode,useFlatArrayNotation)
      case NORETCALL(__) then
      let &preExp = buffer ""
      let expPart = daeExp(exp, contextSimulationDiscrete, &preExp, &varDecls,simCode,useFlatArrayNotation)
      <<
      <%preExp%>
      <% if isCIdentifier(expPart) then "" else '<%expPart%>;' %>
      >>
    ;separator="\n")
  <<
  <%body%>
  >>
end functionWhenReinitStatementThen;

template LabeledDAE(list<String> labels, SimCode simCode, Boolean useFlatArrayNotation) ::=
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
end LabeledDAE;

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



template functionAnalyticJacobians2(list<JacobianMatrix> JacobianMatrixes,String modelNamePrefix) "template functionAnalyticJacobians
  This template generates source code for all given jacobians."
::=

  let initialjacMats = (JacobianMatrixes |> (mat, vars, name, (sparsepattern,_,(_,_)), colorList, maxColor, indexJacobian) =>
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


template initialAnalyticJacobians2(list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String matrixname, list<tuple<DAE.ComponentRef,list<DAE.ComponentRef>>> sparsepattern, list<list<DAE.ComponentRef>> colorList, Integer maxColor, String modelNamePrefix)
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
//  case {(_,{})} then
//    <<
//  /*sinnloser Kommentar*/
//    >>
  case _ then
  match matrixname
  case "A" then
      let &eachCrefParts = buffer ""
      let sp_size_index =  lengthListElements(splitTuple212List(sparsepattern))
      let sizeleadindex = listLength(sparsepattern)
      let leadindex = (sparsepattern |> (cref,indexes) hasindex index0 =>
      <<
        _<%matrixname%>_sparsePattern_leadindex[<%crefWithoutIndexOperator(cref)%>$pDER<%matrixname%>$indexdiff] = <%listLength(indexes)%>;
      >>



      ;separator="\n")
      let indexElems = ( sparsepattern |> (cref,indexes) hasindex index0 =>
        let &eachCrefParts += mkSparseFunction(matrixname, index0, cref, indexes, modelNamePrefix)
        <<
          initializeColumnsColoredJacobian<%matrixname%>_<%index0%>();
        >>


      ;separator="\n")
      let colorArray = (colorList |> (indexes) hasindex index0 =>
        let colorCol = ( indexes |> i_index =>
        '_<%matrixname%>_sparsePattern_colorCols[<%crefWithoutIndexOperator(i_index)%>$pDER<%matrixname%>$indexdiff] = <%intAdd(index0,1)%>; '
        ;separator="\n")
      '<%colorCol%>'
      ;separator="\n")
      let indexColumn = (jacobianColumn |> (eqs,vars,indxColumn) => indxColumn;separator="\n")
      let tmpvarsSize = (jacobianColumn |> (_,vars,_) => listLength(vars);separator="\n")
      let index_ = listLength(seedVars)
      <<

      <%eachCrefParts%>

      void <%modelNamePrefix%>Jacobian::initializeColoredJacobian<%matrixname%>()
      {

        if(_A_sparsePattern_leadindex)
            delete []  _A_sparsePattern_leadindex;
        if(_A_sparsePattern_index)
            delete []  _A_sparsePattern_index;
        if(_A_sparsePattern_colorCols)
            delete []  _A_sparsePattern_colorCols;

        _<%matrixname%>_sparsePattern_leadindex = new int[<%sizeleadindex%>];
        _<%matrixname%>_sparsePattern_index = new int[<%sp_size_index%>];
        _<%matrixname%>_sparsePattern_colorCols = new int[<%index_%>];
        _<%matrixname%>_sparsePattern_maxColors = <%maxColor%>;

        _<%matrixname%>_sizeof_sparsePattern_leadindex = <%sizeleadindex%>;
        _<%matrixname%>_sizeof_sparsePattern_index = <%sp_size_index%>;
        _<%matrixname%>_sizeof_sparsePattern_colorCols = <%index_%>;

        /* write column ptr of compressed sparse column*/
        <%leadindex%>
        for(int i = 1; i < <%sizeleadindex%> ; i++)
            _<%matrixname%>_sparsePattern_leadindex[i] += _<%matrixname%>_sparsePattern_leadindex[i-1];

        /* call functions to write index for each cref */
        <%indexElems%>

        /* write color array */
        <%colorArray%>
      }
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


template mkSparseFunction(String matrixname, String matrixIndex, DAE.ComponentRef cref, list<DAE.ComponentRef> indexes, String modelNamePrefix)
"generate "
::=
match matrixname
 case "A" then
    let indexrows = ( indexes |> indexrow hasindex index0 =>
    <<
      i = _<%matrixname%>_sparsePattern_leadindex[<%crefWithoutIndexOperator(cref)%>$pDER<%matrixname%>$indexdiff] - <%listLength(indexes)%>;
      _<%matrixname%>_sparsePattern_index[i+<%index0%>] = <%crefWithoutIndexOperator(indexrow)%>$pDER<%matrixname%>$indexdiffed;
      >>
      ;separator="\n")

    <<
    void <%modelNamePrefix%>Jacobian::initializeColumnsColoredJacobian<%matrixname%>_<%matrixIndex%>()
    {
      int i;


      /* write index for cref: <%cref(cref , false)%> */


      <%indexrows%>
    }
    <%\n%>
    >>
end match
end mkSparseFunction;


template functionAnalyticJacobiansHeader(list<JacobianMatrix> JacobianMatrixes,String modelNamePrefix) "template functionAnalyticJacobians
  This template generates source code for all given jacobians."
::=

  let initialjacMats = (JacobianMatrixes |> (mat, vars, name, (sparsepattern,_,(_,_)), colorList, maxColor, indexJacobian) =>
    initialAnalyticJacobiansHeader(mat, vars, name, sparsepattern, colorList, maxColor, modelNamePrefix); separator="\n")
/*
  let jacMats = (JacobianMatrixes |> (mat, vars, name, sparsepattern, colorList, maxColor, indexJacobian) =>
    generateMatrix(mat, vars, name, modelNamePrefix) ;separator="\n")
*/
  <<

  <%initialjacMats%>

  >>


end functionAnalyticJacobiansHeader;

template initialAnalyticJacobiansHeader(list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String matrixname, list<tuple<DAE.ComponentRef,list<DAE.ComponentRef>>> sparsepattern, list<list<DAE.ComponentRef>> colorList, Integer maxColor, String modelNamePrefix)
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
      let &eachCrefParts = buffer ""

      let indexElems = ( sparsepattern |> (cref,indexes) hasindex index0 =>
        let &eachCrefParts += mkSparseFunctionHeader(matrixname, index0, cref, indexes, modelNamePrefix)
        <<
        initializeColumnsColoredJacobian<%matrixname%>_<%index0%>();
        >>


      ;separator="\n")
      let colorArray = (colorList |> (indexes) hasindex index0 =>
        let colorCol = ( indexes |> i_index =>
        '_<%matrixname%>_sparsePattern_colorCols[<%cref(i_index, false)%>$pDER<%matrixname%>$indexdiff] = <%intAdd(index0,1)%>; '
        ;separator="\n")
      '<%colorCol%>'
      ;separator="\n")
      let indexColumn = (jacobianColumn |> (eqs,vars,indxColumn) => indxColumn;separator="\n")
      let index_ = listLength(seedVars)
      let sp_size_index =  lengthListElements(splitTuple212List(sparsepattern))
      let sizeleadindex = listLength(sparsepattern)


      <<
      public:
        <%eachCrefParts%>
        void initializeColoredJacobian<%matrixname%>();

        //int  _<%matrixname%>_sizeCols;
        //int  _<%matrixname%>_sizeRows;


        //_<%matrixname%>_sparsePattern_leadindex = new int[];
          //_<%matrixname%>_sparsePattern_index = new int[];
          //_<%matrixname%>_sparsePattern_colorCols = new int[<%index_%>];


        //int  _<%matrixname%>_sparsePattern_leadindex[<%sizeleadindex%>];
        //int  _<%matrixname%>_sizeof_sparsePattern_leadindex;
        //int  _<%matrixname%>_sparsePattern_index[<%sp_size_index%>];
        //int  _<%matrixname%>_sizeof_sparsePattern_index;
        //int  _<%matrixname%>_sparsePattern_colorCols[<%index_%>];
        //int  _<%matrixname%>_sizeof_sparsePattern_colorCols;
        //int  _<%matrixname%>_sparsePattern_maxColors;


      >>
   end match
   end match


end initialAnalyticJacobiansHeader;


































template mkSparseFunctionHeader(String matrixname, String matrixIndex, DAE.ComponentRef cref, list<DAE.ComponentRef> indexes, String modelNamePrefix)
"generate "
::=
match matrixname
 case "A" then
    <<
    void initializeColumnsColoredJacobian<%matrixname%>_<%matrixIndex%>();<%\n%>
    >>
end match
end mkSparseFunctionHeader;

template initialAnalyticJacobians(Integer indexJacobian, list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String matrixName, list<tuple<DAE.ComponentRef,list<DAE.ComponentRef>>> sparsepattern, list<list<DAE.ComponentRef>> colorList,SimCode simCode)
 "Generates function that initialize the sparse-pattern for a jacobain matrix"
::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  let classname =  lastIdentOfPath(modelInfo.name)

     match seedVars
        case {} then
         <<
          void <%classname%>Jacobian::initialAnalytic<%matrixName%>Jacobian()
          {

          }
         >>
       case _ then
         match colorList
          case {} then
           <<
           void <%classname%>Jacobian::initialAnalytic<%matrixName%>Jacobian()
           {
           }
           >>
         case _ then
          let sp_size_index =  lengthListElements(splitTuple212List(sparsepattern))
          let indexColumn = (jacobianColumn |> (eqs,vars,indxColumn) => indxColumn;separator="\n")
          let tmpvarsSize = (jacobianColumn |> (_,vars,_) => listLength(vars);separator="\n")
          let index_ = listLength(seedVars)
          <<
          void <%classname%>Jacobian::initialAnalytic<%matrixName%>Jacobian()
          {
             _<%matrixName%>jacobian = SparseMatrix(<%index_%>,<%indexColumn%>,<%sp_size_index%>);
             _<%matrixName%>jac_y =  ublas::zero_vector<double>(<%index_%>);
             _<%matrixName%>jac_tmp =  ublas::zero_vector<double>(<%tmpvarsSize%>);
             _<%matrixName%>jac_x =  ublas::zero_vector<double>(<%index_%>);

           }
           >>
  end match
end match
end match
end initialAnalyticJacobians;


template functionAnalyticJacobians(list<JacobianMatrix> JacobianMatrixes, SimCode simCode, Boolean useFlatArrayNotation)
 "Generates Matrixes for Linear Model."
::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  let classname =  lastIdentOfPath(modelInfo.name)
  let initialjacMats = (JacobianMatrixes |> (mat, vars, name, (sparsepattern,_,(_,_)), colorList, _, jacIndex) =>
    initialAnalyticJacobians(jacIndex, mat, vars, name, sparsepattern, colorList,simCode)
    ;separator="\n\n";empty)
 let jacMats = (JacobianMatrixes |> (mat, vars, name, (sparsepattern,_,(_,_)), colorList, maxColor, jacIndex) =>
    generateMatrix(jacIndex, mat, vars, name, sparsepattern, colorList, maxColor,simCode, useFlatArrayNotation)
    ;separator="\n\n";empty)
 let initialStateSetJac = (stateSets |> set hasindex i1 fromindex 0 => (match set
       case set as SES_STATESET(__) then
              match jacobianMatrix case (_,_,name,_,_,_,_) then
            'initialAnalytic<%name%>Jacobian();') ;separator="\n\n")


<<
<%initialjacMats%>
<%jacMats%>
void <%classname%>Jacobian::initialize()
{

    <%initialStateSetJac%>
   <% (jacobianMatrixes |> (mat, _, _, _, _, _, _) hasindex index0 =>
       (mat |> (eqs,_,_) =>  generateAlgloopsolvers(eqs,simCode) ;separator="")
     ;separator="")
    %>
     <% (jacobianMatrixes |> (mat, _, _, _, _, _, _) hasindex index0 =>
       (mat |> (eqs,_,_) =>  initAlgloopsolver(eqs,simCode) ;separator="")
     ;separator="")
    %>

}

>>

end functionAnalyticJacobians;





template functionJac(list<SimEqSystem> jacEquations, list<SimVar> tmpVars, String columnLength, String matrixName, Integer indexJacobian, SimCode simCode, Boolean useFlatArrayNotation)
 "Generates function in simulation file."
::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  let classname =  lastIdentOfPath(modelInfo.name)

  let &varDecls = buffer "" /*BUFD*/
  let &tmp = buffer ""
  let eqns_ = (jacEquations |> eq =>
      equation_(eq, contextJacobian, &varDecls /*BUFD*/, /*&tmp*/ simCode,useFlatArrayNotation)
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


template generateMatrix(Integer indexJacobian, list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String matrixname, list<tuple<DAE.ComponentRef,list<DAE.ComponentRef>>> sparsepattern, list<list<DAE.ComponentRef>>colorList, Integer maxColor, SimCode simCode, Boolean useFlatArrayNotation)
 "Generates Matrixes for Linear Model."
::=

   match simCode
   case SIMCODE(modelInfo = MODELINFO(__)) then
         generateJacobianMatrix(modelInfo, indexJacobian, jacobianColumn, seedVars, matrixname, sparsepattern, colorList, maxColor, simCode, useFlatArrayNotation)
   end match


end generateMatrix;





template generateJacobianMatrix(ModelInfo modelInfo, Integer indexJacobian, list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String matrixName, list<tuple<DAE.ComponentRef,list<DAE.ComponentRef>>> sparsepattern, list<list<DAE.ComponentRef>>colorList, Integer maxColor, SimCode simCode, Boolean useFlatArrayNotation)
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
    functionJac(eqs, vars, indxColumn, matrixName, indexJacobian,simCode, useFlatArrayNotation)
    ;separator="\n")
 let indexColumn = (jacobianColumn |> (eqs,vars,indxColumn) =>
    indxColumn
    ;separator="\n")

    let jacvals = ( sparsepattern |> (cref,indexes) hasindex index0 =>
    let jaccol = ( indexes |> i_index hasindex index1 =>
        (match indexColumn case "1" then ' _<%matrixName%>jacobian(<%crefWithoutIndexOperator(cref)%>$pDER<%matrixName%>$indexdiff,0) = _<%matrixName%>jac_y(0);'
           else ' _<%matrixName%>jacobian(<%crefWithoutIndexOperator(cref)%>$pDER<%matrixName%>$indexdiff,<%crefWithoutIndexOperator(i_index)%>$pDER<%matrixName%>$indexdiffed) = _<%matrixName%>jac_y(<%crefWithoutIndexOperator(i_index)%>$pDER<%matrixName%>$indexdiffed);'
           )
          ;separator="\n" )


    ' _<%matrixName%>jac_x(<%index0%>)=1;
  calc<%matrixName%>JacobianColumn();
  _<%matrixName%>jac_x.clear();
  <%jaccol%>'
      ;separator="\n")


  <<



    <%jacMats%>
    void <%classname%>Jacobian::get<%matrixName%>Jacobian(SparseMatrix& matrix)
     {
        <%jacvals%>
        matrix=_<%matrixName%>jacobian;
     }
  >>

/*
  (match indexColumn case "1" then ' _<%matrixName%>jacobian(<%crefWithoutIndexOperator(cref)%>$pDER<%matrixName%>$indexdiff,0) = _<%matrixName%>jac_y(0); //1 <%cref(cref)%>'
           else ' _<%matrixName%>jacobian(<%index0%>,<%crefWithoutIndexOperator(cref)%>$pDER<%matrixName%>$indexdiff) = _<%matrixName%>jac_y(<%crefWithoutIndexOperator(cref)%>$pDER<%matrixName%>$indexdiff);//2 <%cref(cref)%>'

*/
end generateJacobianMatrix;



template variableDefinitionsJacobians(list<JacobianMatrix> JacobianMatrixes,SimCode simCode)
 "Generates defines for jacobian vars."
::=

  let analyticVars = (JacobianMatrixes |> (jacColumn, seedVars, name, (_,_,(diffVars,diffedVars)), _, _, jacIndex) =>
    let varsDef = variableDefinitionsJacobians2(jacIndex, jacColumn, seedVars, name,simCode)
    let sparseDef = defineSparseIndexes(diffVars, diffedVars, name,simCode)
    <<
    <%varsDef%>
    <%sparseDef%>
    >>
    ;separator="\n";empty)

  <<
    /* Jacobian Variables */
    <%analyticVars%>
  >>

end variableDefinitionsJacobians;

template variableDefinitionsJacobians2(Integer indexJacobian, list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String name,SimCode simCode)
 "Generates Matrixes for Linear Model."
::=
  let seedVarsResult = (seedVars |> var hasindex index0 =>
    jacobianVarDefine(var, "jacobianVarsSeed", indexJacobian, index0, name,simCode)
    ;separator="\n";empty)
  let columnVarsResult = (jacobianColumn |> (_,vars,_) =>
      (vars |> var hasindex index0 => jacobianVarDefine(var, "jacobianVars", indexJacobian, index0,name,simCode)
      ;separator="\n";empty)
    ;separator="\n\n")

<<
<%seedVarsResult%>
<%columnVarsResult%>
>>
end variableDefinitionsJacobians2;


template jacobianVarDefine(SimVar simVar, String array, Integer indexJac, Integer index0,String matrixName,SimCode simCode)
""
::=
match array
case "jacobianVars" then
  match simVar
  case SIMVAR(aliasvar=NOALIAS(),name=name) then
    match index
    case -1 then
      <<
      #define <%crefWithoutIndexOperator(name)%> _<%matrixName%>jac_tmp(<%index0%>)
      >>
    case _ then
      <<
      #define <%crefWithoutIndexOperator(name)%> _<%matrixName%>jac_y(<%index%>)
      >>
    end match
  end match
case "jacobianVarsSeed" then
  match simVar
  case SIMVAR(aliasvar=NOALIAS()) then
  let tmp = System.tmpTick()
    <<
    #define <%crefWithoutIndexOperator(name)%>$pDER<%matrixName%>$P<%crefWithoutIndexOperator(name)%> _<%matrixName%>jac_x(<%index0%>)
    >>
  end match
end jacobianVarDefine;




template defineSparseIndexes(list<SimVar> diffVars, list<SimVar> diffedVars, String matrixName,SimCode simCode) "template variableDefinitionsJacobians2
  Generates Matrixes for Linear Model."
::=
  let diffVarsResult = (diffVars |> var as SIMVAR(name=name) hasindex index0 =>
     '#define <%crefWithoutIndexOperator(name)%>$pDER<%matrixName%>$indexdiff <%index0%>'
    ;separator="\n")
    let diffedVarsResult = (diffedVars |> var as SIMVAR(name=name) hasindex index0 =>
     '#define <%crefWithoutIndexOperator(name)%>$pDER<%matrixName%>$indexdiffed <%index0%>'
    ;separator="\n")
   /* generate at least one print command to have the same index and avoid the strange side effect */
  <<
  /* <%matrixName%> sparse indexes */
   <%diffVarsResult%>
   <%diffedVarsResult%>
  >>

end defineSparseIndexes;


//Generation of Algorithm section
template algStatement(DAE.Statement stmt, Context context, Text &varDecls,SimCode simCode, Boolean useFlatArrayNotation)
::=
  let res = match stmt
  case s as STMT_ASSIGN(exp1=PATTERN(__)) then "STMT_ASSIGN Pattern not supported yet"
  case s as STMT_ASSIGN(__)         then algStmtAssign(s, context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  case s as STMT_ASSIGN_ARR(__)     then algStmtAssignArr(s, context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  case s as STMT_TUPLE_ASSIGN(__)   then algStmtTupleAssign(s, context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  case s as STMT_IF(__)             then algStmtIf(s, context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  case s as STMT_FOR(__)            then algStmtFor(s, context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  case s as STMT_WHILE(__)          then algStmtWhile(s, context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  case s as STMT_ASSERT(__)         then algStmtAssert(s, context, &varDecls ,simCode,useFlatArrayNotation)
  case s as STMT_TERMINATE(__)      then algStmtTerminate(s, context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  case s as STMT_WHEN(__)           then algStmtWhen(s, context, &varDecls ,simCode,useFlatArrayNotation)
  case s as STMT_BREAK(__)          then 'break;<%\n%>'
  case s as STMT_FAILURE(__)        then "STMT FAILURE"
  case s as STMT_RETURN(__)         then "break;/*Todo stmt return*/"
  case s as STMT_NORETCALL(__)      then algStmtNoretcall(s, context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  case s as STMT_REINIT(__)         then algStmtReinit(s, context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  else error(sourceInfo(), 'ALG_STATEMENT NYI')

  <<
  <%modelicaLine(getElementSourceFileInfo(getStatementSource(stmt)))%>
  <%res%>
  <%endModelicaLine()%>
  >>



end algStatement;

template algStmtWhile(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates a while algorithm statement."
::=
match stmt
case STMT_WHILE(__) then
  let &preExp = buffer "" /*BUFD*/
  let var = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  <<
  while (1) {
    <%preExp%>
    if (!<%var%>) break;
    <%statementLst |> stmt => algStatement(stmt, context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation) ;separator="\n"%>
  }
  >>
end algStmtWhile;

template algStmtTerminate(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
 "Generates an assert algorithm statement."
::=
match stmt
case STMT_TERMINATE(__) then
  let &preExp = buffer "" /*BUFD*/
  let msgVar = daeExp(msg, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  <<
  <%preExp%>
  _terminate=true;
  >>
end algStmtTerminate;

template modelicaLine(Info info)
::=
  match info
  case INFO(columnNumberStart=0) then "/* Dummy Line */"
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

template algStmtAssign(DAE.Statement stmt, Context context, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
 "Generates an assigment algorithm statement."
::=
  match stmt
  case STMT_ASSIGN(exp1=CREF(componentRef=WILD(__)), exp=e) then
    let &preExp = buffer "" /*BUFD*/
    let expPart = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    <<

    <%preExp%>
    >>
  case STMT_ASSIGN(exp1=CREF(ty = T_FUNCTION_REFERENCE_VAR(__)))
  case STMT_ASSIGN(exp1=CREF(ty = T_FUNCTION_REFERENCE_FUNC(__))) then
    let &preExp = buffer "" /*BUFD*/
    let varPart = scalarLhsCref(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
    let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    <<

    <%preExp%>
    <%varPart%> = (modelica_fnptr) <%expPart%>;
    >>
    /* Records need to be traversed, assigning each component by itself */
  case STMT_ASSIGN(exp1=CREF(componentRef=cr,ty = T_COMPLEX(varLst = varLst, complexClassType=RECORD(__)))) then
    let &preExp = buffer ""
    let rec = daeExp(exp, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    <<

    <%preExp%>
    <% varLst |> var as TYPES_VAR(__) =>
      match var.ty
      case T_ARRAY(__) then
        copyArrayData(var.ty, '<%rec%>.<%var.name%>', appendStringCref(var.name,cr), context)
      else
        let varPart = contextCref(appendStringCref(var.name,cr),context,simCode,useFlatArrayNotation)
        '<%varPart%> = <%rec%>.<%var.name%>;'
    ; separator="\n"
    %>
    >>
  case STMT_ASSIGN(exp1=CALL(path=path,expLst=expLst,attr=CALL_ATTR(ty= T_COMPLEX(varLst = varLst, complexClassType=RECORD(__))))) then
    let &preExp = buffer ""
    let rec = daeExp(exp, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    <<

    <%preExp%>
    <% varLst |> var as TYPES_VAR(__) hasindex i1 fromindex 1 =>
      let re = daeExp(listNth(expLst,i1), context, &preExp, &varDecls,simCode,useFlatArrayNotation)
      '<%re%> = <%rec%>.<%var.name%>;'
    ; separator="\n"
    %>
    Record = func;
    >>
  case STMT_ASSIGN(exp1=CREF(__)) then
    let &preExp = buffer "" /*BUFD*/
    let varPart = scalarLhsCref(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
    let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    <<

    <%preExp%>
    <%varPart%> = <%expPart%>;

    >>
  case STMT_ASSIGN(exp1=exp1 as ASUB(__),exp=val) then
    (match expTypeFromExpShort(exp)
      case "metatype" then
        // MetaModelica Array
        (match exp case ASUB(exp=arr, sub={idx}) then
        let &preExp = buffer ""
        let arr1 = daeExp(arr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
        let idx1 = daeExp(idx, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
        let val1 = daeExp(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
        <<

        <%preExp%>
        arrayUpdate(<%arr1%>,<%idx1%>,<%val1%>);
        >>)
        // Modelica Array
      else
        let &preExp = buffer "" /*BUFD*/
        let varPart = daeExpAsub(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
        let expPart = daeExp(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
        <<

        <%preExp%>
        <%varPart%> = <%expPart%>;
        >>
    )
  case STMT_ASSIGN(__) then
    let &preExp = buffer "" /*BUFD*/
    let expPart1 = daeExp(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let expPart2 = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
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

template algStmtWhen(DAE.Statement when, Context context, Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates a when algorithm statement."
::=
match context
case SIMULATION_CONTEXT(__) then
  match when
  case STMT_WHEN(__) then
    let &varDeclsCref = buffer "" /*BUFD*/
    let helpIf = (conditions |> e => ' || (<%cref1(e, simCode, context, varDeclsCref,useFlatArrayNotation)%> && !_event_handling.pre(<%cref1(e, simCode, context, varDeclsCref,useFlatArrayNotation)%>,"<%cref(e,useFlatArrayNotation)%>"))')
    let statements = (statementLst |> stmt =>
        algStatement(stmt, context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
      ;separator="\n")
    let else = algStatementWhenElse(elseWhen, &varDecls /*BUFD*/,simCode,context,useFlatArrayNotation)
    <<
    if (0<%helpIf%>) {
      <%statements%>
    }
    <%else%>
    >>
   end match
end match
end algStmtWhen;


template algStmtAssert(DAE.Statement stmt, Context context, Text &varDecls,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates an assert algorithm statement."
::=
match stmt
case STMT_ASSERT(source=SOURCE(info=info)) then
  assertCommon(cond, msg, context, &varDecls, info,simCode,useFlatArrayNotation)
end algStmtAssert;


template algStmtReinit(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
 "Generates an assigment algorithm statement."
::=
  match stmt
  case STMT_REINIT(__) then
    let &preExp = buffer "" /*BUFD*/
    let expPart1 = daeExp(var, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    let expPart2 = daeExp(value, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
    /*
    <<
    $P$PRE<%expPart1%> = <%expPart1%>;
    <%preExp%>
    <%expPart1%> = <%expPart2%>;
    >>
    */
    <<
    _event_handling.save(<%expPart1%>,"<%expPart1%>");
     <%preExp%>
    <%expPart1%> = <%expPart2%>;
    >>
end algStmtReinit;

template algStmtIf(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates an if algorithm statement."
::=
match stmt
case STMT_IF(__) then
  let &preExp = buffer "" /*BUFD*/
  let condExp = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  <<
  <%preExp%>
  if (<%condExp%>) {
    <%statementLst |> stmt => algStatement(stmt, context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation) ;separator="\n"%>
  }
   <%elseExpr(else_, context,&preExp , &varDecls /*BUFD*/,simCode,useFlatArrayNotation)%>
  >>
end algStmtIf;


template algStmtFor(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates a for algorithm statement."
::=
  match stmt
  case s as STMT_FOR(range=rng as RANGE(__)) then
    algStmtForRange(s, context, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
  case s as STMT_FOR(__) then
    algStmtForGeneric(s, context, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
end algStmtFor;

template algStmtForGeneric(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates a for algorithm statement where range is not RANGE."
::=
match stmt
case STMT_FOR(__) then
  let iterType = expType(type_, iterIsArray)
  let arrayType = expTypeArray(type_)


  let stmtStr = (statementLst |> stmt =>
    algStatement(stmt, context, &varDecls,simCode,useFlatArrayNotation) ;separator="\n")
  algStmtForGeneric_impl(range, iter, iterType, arrayType, iterIsArray, stmtStr,
    context, &varDecls,simCode,useFlatArrayNotation)
end algStmtForGeneric;






template algStmtForGeneric_impl(Exp exp, Ident iterator, String type,
  String arrayType, Boolean iterIsArray, Text &body, Context context, Text &varDecls,SimCode simCode,Boolean useFlatArrayNotation)
 "The implementation of algStmtForGeneric, which is also used by daeExpReduction."
::=
  let iterName = contextIteratorName(iterator, context)
  //let stateVar = if not acceptMetaModelicaGrammar() then tempDecl("state", &varDecls)
  //let tvar = tempDecl("int", &varDecls)
  //let ivar = tempDecl(type, &varDecls)
  let &preExp = buffer ""
  let &tmpVar = buffer ""
  let evar = daeExp(exp, context, &preExp, &tmpVar,simCode,useFlatArrayNotation)
  //let stmtStuff = if iterIsArray then
  //    'simple_index_alloc_<%type%>1(&<%evar%>, <%tvar%>, &<%ivar%>);'
  //  else
  //    '<%iterName%> = *(<%arrayType%>_element_addr1(&<%evar%>, 1, <%tvar%>));'
  <<
  <%preExp%>
    <%type%> <%iterName%>;
   BOOST_FOREACH( short <%iterName%>,  <%evar%> ){
      <%body%>
    }
  >>

end algStmtForGeneric_impl;

template algStmtNoretcall(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
 "Generates a no return call algorithm statement."
::=
match stmt
case STMT_NORETCALL(__) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode,useFlatArrayNotation)
  <<
  //No retcall
  <%preExp%>
  <%expPart%>;
    //No retcall
  >>
end algStmtNoretcall;

template algStmtForRange(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates a for algorithm statement where range is RANGE."
::=
match stmt
case STMT_FOR(range=rng as RANGE(__)) then
  let identType = expType(type_, iterIsArray)
  let identTypeShort = expTypeShort(type_)
  let stmtStr = (statementLst |> stmt => algStatement(stmt, context, &varDecls,simCode, useFlatArrayNotation)
                 ;separator="\n")
  algStmtForRange_impl(rng, iter, identType, identTypeShort, stmtStr, context, &varDecls,simCode, useFlatArrayNotation)
end algStmtForRange;




template algStmtForRange_impl(Exp range, Ident iterator, String type, String shortType, Text body, Context context, Text &varDecls,SimCode simCode, Boolean useFlatArrayNotation)
 "The implementation of algStmtForRange, which is also used by daeExpReduction."
::=
match range
case RANGE(__) then
  let iterName = contextIteratorName(iterator, context)
  let startVar = tempDecl(type, &varDecls)
  let stepVar = tempDecl(type, &varDecls)
  let stopVar = tempDecl(type, &varDecls)
  let &preExp = buffer ""
  let startValue = daeExp(start, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
  let stepValue = match step case SOME(eo) then
      daeExp(eo, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
    else
      "(1)"
  let stopValue = daeExp(stop, context, &preExp, &varDecls,simCode,useFlatArrayNotation)
  <<
  <%preExp%>
  <%startVar%> = <%startValue%>; <%stepVar%> = <%stepValue%>; <%stopVar%> = <%stopValue%>;
  if(!<%stepVar%>)
  {


  }
  else if(!(((<%stepVar%> > 0) && (<%startVar%> > <%stopVar%>)) || ((<%stepVar%> < 0) && (<%startVar%> < <%stopVar%>))))
  {
    <%type%> <%iterName%>;
                               //half-open range

  BOOST_FOREACH(<%iterName%>,boost::irange( <%startValue%>,(int)<%stopValue%>+1,(int)<%stepVar%>))
    {

      <%body%>

    }
  }
  >> /* else we're looping over a zero-length range */
end algStmtForRange_impl;


template algStmtAssignArr(DAE.Statement stmt, Context context,
                 Text &varDecls /*BUFP*/,SimCode simCode,Boolean useFlatArrayNotation)
 "Generates an array assigment algorithm statement."
::=
match stmt
case STMT_ASSIGN_ARR(exp=RANGE(__), componentRef=cr, type_=t) then
  <<
  STMT_ASSIGN_ARR  RANGE
  fillArrayFromRange(t,exp,cr,context,&varDecls)
  >>
case STMT_ASSIGN_ARR(exp=e as CALL(__), componentRef=cr, type_=t) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode,useFlatArrayNotation)

  let cref = contextArrayCref(cr, context)
    /*previous multi_array
  <<
     <%preExp%>
       assign_array(<%cref%>,<%expPart%>);
    >>
  */
  <<
     <%preExp%>
     <%cref%>.assign(<%expPart%>);
    >>
case STMT_ASSIGN_ARR(exp=e, componentRef=cr, type_=t) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode, useFlatArrayNotation)
    /*previous multi_array
    <<
    <%preExp%>
    assign_array(<%contextArrayCref(cr, context)%>,<%expPart%>);
    >>
  */
  <<
     <%preExp%>
     <%contextArrayCref(cr, context)%>.assign(<%expPart%>);
    >>
end algStmtAssignArr;

template indexSpecFromCref(ComponentRef cr, Context context, Text &preExp /*BUFP*/,
                  Text &varDecls /*BUFP*/,SimCode simCode, Boolean useFlatArrayNotation)
 "Helper to algStmtAssignArr.
  Currently works only for CREF_IDENT." ::=
match cr
case CREF_IDENT(subscriptLst=subs as (_ :: _)) then
  daeExpCrefRhsIndexSpec(subs, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
end indexSpecFromCref;




template functionInitDelay(DelayedExpression delayed,SimCode simCode, Boolean useFlatArrayNotation)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
   let &preExp = buffer "" /*BUFD*/
  let delay_id = (match delayed case DELAYED_EXPRESSIONS(__) then (delayedExps |> (id, (e, d, delayMax)) =>
     '<%id%>';separator=","))
  let delay_max = (match delayed case DELAYED_EXPRESSIONS(__) then (delayedExps |> (id, (e, d, delayMax)) =>
      let delayExpMax = daeExp(delayMax, contextSimulationNonDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
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


template functionStoreDelay(DelayedExpression delayed,SimCode simCode, Boolean useFlatArrayNotation)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
   let storePart = (match delayed case DELAYED_EXPRESSIONS(__) then (delayedExps |> (id, (e, d, delayMax)) =>
      let &preExp = buffer "" /*BUFD*/
      let eRes = daeExp(e, contextSimulationNonDiscrete,
                      &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, useFlatArrayNotation)
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


template giveVariablesWithSplit(Text funcNamePrefix, Text funcArgs,Text funcParams,list<SimVar> varsLst, SimCode simCode, Context context, Boolean useFlatArrayNotation) ::=
  let &funcCalls = buffer "" /*BUFD*/
  let extraFuncs = List.partition(varsLst, 100) |> ls hasindex idx =>
    let &varDecls = buffer "" /*BUFD*/
    let &funcCalls += '<%funcNamePrefix%>_<%idx%>(<%funcParams%>);'
    let init = giveVariablesWithSplit2(ls, simCode, context, useFlatArrayNotation)
    <<
    void <%funcNamePrefix%>_<%idx%>(<%funcArgs%>)
    {
       <%varDecls%>
       <%init%>
    }
    >>
    ;separator="\n"

  <<
  <%extraFuncs%>

  void <%funcNamePrefix%>(<%funcArgs%>)
  {
    <%funcCalls%>
  }
  >>
end giveVariablesWithSplit;


template giveVariablesWithSplit2(list<SimVar> varsLst, SimCode simCode, Context context, Boolean useFlatArrayNotation)
::=
<<
 <%varsLst |>
        var hasindex i0 fromindex 0 => giveVariablesDefault(var, i0, useFlatArrayNotation)
        ;separator="\n"%>
 >>
end giveVariablesWithSplit2;



template setVariablesWithSplit(Text funcNamePrefix, Text funcArgs,Text funcParams,list<SimVar> varsLst, SimCode simCode, Context context, Boolean useFlatArrayNotation) ::=
  let &funcCalls = buffer "" /*BUFD*/
  let extraFuncs = List.partition(varsLst, 100) |> ls hasindex idx =>
    let &varDecls = buffer "" /*BUFD*/
    let &funcCalls += '<%funcNamePrefix%>_<%idx%>(<%funcParams%>);'
    let init = setVariablesWithSplit2(ls, simCode, context, useFlatArrayNotation)
    <<
    void <%funcNamePrefix%>_<%idx%>(<%funcArgs%>)
    {
       <%varDecls%>
       <%init%>
    }
    >>
    ;separator="\n"

  <<
  <%extraFuncs%>

  void <%funcNamePrefix%>(<%funcArgs%>)
  {
    <%funcCalls%>
  }
  >>
end setVariablesWithSplit;


template setVariablesWithSplit2(list<SimVar> varsLst, SimCode simCode, Context context, Boolean useFlatArrayNotation)
::=
<<
 <%varsLst|>
        var hasindex i0 fromindex 0 => setVariablesDefault(var, i0, useFlatArrayNotation)
        ;separator="\n"%>

 >>
end setVariablesWithSplit2;




template giveVariables(ModelInfo modelInfo, Boolean useFlatArrayNotation,SimCode simCode)
 "Define Memeber Function getReal off Cpp Target"
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then


  let getrealvariable = giveVariablesWithSplit(lastIdentOfPath(name)+ "::getReal","double* z","z",listAppend( listAppend(vars.algVars, vars.discreteAlgVars), vars.paramVars ), simCode, contextOther, useFlatArrayNotation)
  let setrealvariable = setVariablesWithSplit(lastIdentOfPath(name)+ "::setReal","const double* z","z",listAppend( listAppend(vars.algVars, vars.discreteAlgVars), vars.paramVars ), simCode, contextOther, useFlatArrayNotation)

  let getintvariable = giveVariablesWithSplit(lastIdentOfPath(name)+ "::getInteger","int* z","z",listAppend(listAppend( vars.intAlgVars, vars.intParamVars ), vars.intAliasVars ), simCode, contextOther, useFlatArrayNotation)
  <<

  <%getrealvariable%>
  <%setrealvariable%>

  <%getintvariable%>

  void <%lastIdentOfPath(name)%>::getBoolean(bool* z)
  {
    <%listAppend( listAppend( vars.boolAlgVars, vars.boolParamVars ), vars.boolAliasVars ) |>
        var hasindex i0 fromindex 0 => giveVariablesDefault(var, i0, useFlatArrayNotation)
        ;separator="\n"%>
  }

  void <%lastIdentOfPath(name)%>::getString(string* z)
  {

  <%System.tmpTickReset(0)%>
  <%vars.stringAlgVars |> var => giveVariablesDefault(var, System.tmpTick(), useFlatArrayNotation) ;separator="\n"%>
  <%vars.stringParamVars |> var => giveVariablesDefault(var, System.tmpTick(), useFlatArrayNotation) ;separator="\n"%>
  <%vars.stringAliasVars |> var => giveVariablesDefault(var, System.tmpTick(), useFlatArrayNotation) ;separator="\n"%>

  }


  void <%lastIdentOfPath(name)%>::setInteger(const int* z)
  {
    <%listAppend( listAppend( vars.intAlgVars, vars.intParamVars ), vars.intAliasVars ) |>
        var hasindex i0 fromindex 0 => setVariablesDefault(var, i0, useFlatArrayNotation)
        ;separator="\n"%>
  }

  void <%lastIdentOfPath(name)%>::setBoolean(const bool* z)
  {
    <%listAppend( listAppend( vars.boolAlgVars, vars.boolParamVars ), vars.boolAliasVars ) |>
        var hasindex i0 fromindex 0 => setVariablesDefault(var, i0, useFlatArrayNotation)
        ;separator="\n"%>
  }

  void <%lastIdentOfPath(name)%>::setString(const string* z)
  {

  }

  >>
  /*
  <%System.tmpTickReset(0)%>
  <%vars.stringAlgVars |> var => giveVariablesDefault(var, System.tmpTick()) ;separator="\n"%>
  <%vars.stringParamVars |> var => giveVariablesDefault(var, System.tmpTick()) ;separator="\n"%>
  <%vars.stringAliasVars |> var => giveVariablesDefault(var, System.tmpTick()) ;separator="\n"%>
  */
end giveVariables;

template giveVariablesState(SimVar simVar, Integer valueReference, String arrayName, Integer index)
 "Generates code for getting variables in cpp target for use in FMU. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  <<
  z[<%valueReference%>] = <%arrayName%>[<%index%>]; <%description%>
  >>
end giveVariablesState;

template giveVariablesDefault(SimVar simVar, Integer valueReference, Boolean useFlatArrayNotation)
 "Generates code for getting variables in cpp target for use in FMU. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '/* <%comment%> */'
  <<
  z[<%valueReference%>] = <%cref(name, useFlatArrayNotation)%>; <%description%>
  >>
end giveVariablesDefault;

template setVariablesDefault(SimVar simVar, Integer valueReference, Boolean useFlatArrayNotation)
 "Generates code for getting variables in cpp target for use in FMU. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  let variablename = cref(name, useFlatArrayNotation)
  match causality
    case INPUT() then
      <<
      <%variablename%> = z[<%valueReference%>]; <%description%>
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
                    Text &varDecls,SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for an tsub expression."
::=
  match inExp
  case TSUB(ix=1) then
    let tuple_val = daeExp(exp, context, &preExp, &varDecls, simCode, useFlatArrayNotation)
     'boost::get<0>(<%tuple_val%>.data)'
  //case TSUB(exp=CALL(attr=CALL_ATTR(ty=T_TUPLE(tupleType=tys)))) then
  case TSUB(exp=CALL(path=p,attr=CALL_ATTR(ty=tys as T_TUPLE(__)))) then
    //let v = tempDecl(expTypeArrayIf(listGet(tys,ix)), &varDecls)
    //let additionalOutputs = List.restOrEmpty(tys) |> ty hasindex i1 fromindex 2 => if intEq(i1,ix) then ', &<%v%>' else ", NULL"
     let retType = '<%underscorePath(p)%>RetType /* undefined */'
    let retVar = tempDecl(retType, &varDecls)
     let res = daeExpCallTuple(exp,retVar, context, &preExp, &varDecls, simCode, useFlatArrayNotation)
    let &preExp += '<%res%>;<%\n%>'
    'boost::get<<%intAdd(-1,ix)%>>(<%retVar%>.data)'

  case TSUB(__) then
    error(sourceInfo(), '<%printExpStr(inExp)%>: TSUB only makes sense if the subscripted expression is a function call of tuple type')
end daeExpTsub;

template daeExpCallTuple(Exp call , Text additionalOutputs/* arguments 2..N */, Context context, Text &preExp, Text &varDecls,SimCode simCode, Boolean useFlatArrayNotation)
::=
  match call
  case exp as CALL(attr=attr as CALL_ATTR(__)) then


    let argStr = if boolOr(attr.builtin,isParallelFunctionContext(context))
                   then (expLst |> exp => '<%daeExp(exp, context, &preExp, &varDecls, simCode, useFlatArrayNotation)%>' ;separator=", ")
                 else ((expLst |> exp => (daeExp(exp, context, preExp, &varDecls, simCode, useFlatArrayNotation));separator=", "))
    if attr.isFunctionPointerCall
      then
        let typeCast1 = generateTypeCast(attr.ty, expLst, true,preExp, varDecls,context, simCode, useFlatArrayNotation)
        let typeCast2 = generateTypeCast(attr.ty, expLst, false, preExp, varDecls,context,simCode, useFlatArrayNotation)
        let name = '_<%underscorePath(path)%>'
        let func = '(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%name%>), 1)))'
        let closure = '(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%name%>), 2)))'
        let argStrPointer = ('threadData, <%closure%>' + (expLst |> exp => (", " + daeExp(exp, context, &preExp, &varDecls,simCode, useFlatArrayNotation))))
        //'<%name%>(<%argStr%><%additionalOutputs%>)'
        '/*Closure?*/<%closure%> ? (<%typeCast1%> <%func%>) (<%argStrPointer%><%additionalOutputs%>) : (<%typeCast2%> <%func%>) (<%argStr%><%additionalOutputs%>)'
      else
          '_functions-><%underscorePath(path)%>(<%argStr%>,<%additionalOutputs%>)'
end daeExpCallTuple;

template generateTypeCast(Type ty, list<DAE.Exp> es, Boolean isClosure, Text &preExp /*BUFP*/,
                     Text &varDecls, Context context,SimCode simCode, Boolean useFlatArrayNotation)
::=
  let ret = (match ty
    case T_NORETCALL(__) then "void"
    else "modelica_metatype")
  let inputs = es |> e => ', <%expTypeFromExpArrayIf(e,context, &preExp ,&varDecls ,simCode, useFlatArrayNotation)%>'
  let outputs = match ty
    case T_TUPLE(tupleType=_::tys) then (tys |> t => ', <%expTypeArrayIf(t)%>')
  '(<%ret%>(*)(threadData_t*<%if isClosure then ", modelica_metatype"%><%inputs%><%outputs%>))'
end generateTypeCast;

template generateMeasureTimeStartCode(String varNameStartValues)
::=
  if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
  <<
  MeasureTime::getTimeValuesStart(<%varNameStartValues%>);
  >>
end generateMeasureTimeStartCode;

template generateMeasureTimeEndCode(String varNameStartValues, String varNameEndValues, String varNameTargetValues)
::=
  if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
  <<
  MeasureTime::getTimeValuesEnd(<%varNameEndValues%>);
  <%varNameEndValues%>->sub(<%varNameStartValues%>);
  <%varNameEndValues%>->sub(MeasureTime::getOverhead());
  <%varNameTargetValues%>.sumMeasuredValues->add(<%varNameEndValues%>);
  ++(<%varNameTargetValues%>.numCalcs);
  >>
end generateMeasureTimeEndCode;

annotation(__OpenModelica_Interface="backend");
end CodegenCpp;
