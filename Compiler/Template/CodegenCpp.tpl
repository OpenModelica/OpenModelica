package CodegenCpp

import interface SimCodeTV;

// SECTION: SIMULATION TARGET, ROOT TEMPLATE

template translateModel(SimCode simCode) ::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  let target  = simulationCodeTarget()
   let()= textFile(simulationMainFile(simCode), 'OMCpp<%fileNamePrefix%>Main.cpp')
  let()= textFile(simulationHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>.h')
  let()= textFile(simulationCppFile(simCode), 'OMCpp<%fileNamePrefix%>.cpp')
  let()= textFile(simulationFunctionsHeaderFile(simCode,modelInfo.functions,literals), 'OMCpp<%fileNamePrefix%>Functions.h')
  let()= textFile(simulationFunctionsFile(simCode, modelInfo.functions,literals,externalFunctionIncludes), 'OMCpp<%fileNamePrefix%>Functions.cpp')
  let()= textFile(simulationMakefile(target,simCode), '<%fileNamePrefix%>.makefile')
  let()= textFile(simulationInitHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>Initialize.h')
  let()= textFile(simulationInitCppFile(simCode),'OMCpp<%fileNamePrefix%>Initialize.cpp')
  let()= textFile(simulationJacobianHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>Jacobian.h')
  let()= textFile(simulationJacobianCppFile(simCode),'OMCpp<%fileNamePrefix%>Jacobian.cpp')
  let()= textFile(simulationStateSelectionCppFile(simCode), 'OMCpp<%fileNamePrefix%>StateSelection.cpp')
  let()= textFile(simulationStateSelectionHeaderFile(simCode),'OMCpp<%fileNamePrefix%>StateSelection.h')
  let()= textFile(simulationExtensionHeaderFile(simCode),'OMCpp<%fileNamePrefix%>Extension.h')
  let()= textFile(simulationExtensionCppFile(simCode),'OMCpp<%fileNamePrefix%>Extension.cpp')
  let()= textFile(simulationWriteOutputHeaderFile(simCode),'OMCpp<%fileNamePrefix%>WriteOutput.h')
  let()= textFile(simulationWriteOutputCppFile(simCode),'OMCpp<%fileNamePrefix%>WriteOutput.cpp')
  let()= textFile(simulationFactoryFile(simCode),'OMCpp<%fileNamePrefix%>FactoryExport.cpp')
  let()= textFile(simulationMainRunScrip(simCode), '<%fileNamePrefix%><%simulationMainRunScripSuffix(simCode)%>')
  algloopfiles(listAppend(allEquations,initialEquations),simCode)
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

template simulationHeaderFile(SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(__) then
  <<
   <%generateHeaderInlcudeString(simCode)%>
   <%generateClassDeclarationCode(simCode)%>


   >>
end simulationHeaderFile;


template simulationInitHeaderFile(SimCode simCode)
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
  class <%lastIdentOfPath(modelInfo.name)%>Initialize: virtual public  <%lastIdentOfPath(modelInfo.name)%>
  {
     public:
    <%lastIdentOfPath(modelInfo.name)%>Initialize(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData);
    ~<%lastIdentOfPath(modelInfo.name)%>Initialize();
    virtual bool initial();
    virtual void setInitial(bool);
    virtual void initialize();
    virtual  void initEquations();
   private:
   
    void initializeAlgVars();
    void initializeIntAlgVars();
    void initializeBoolAlgVars();
    void initializeAliasVars();
    void initializeIntAliasVars();
    void initializeBoolAliasVars();
    void initializeParameterVars();
     void initializeStateVars();
    void initializeDerVars();
  };
 >>
end simulationInitHeaderFile;



template simulationJacobianHeaderFile(SimCode simCode)
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
  class <%lastIdentOfPath(modelInfo.name)%>Jacobian: virtual public  <%lastIdentOfPath(modelInfo.name)%>
  {
     public:
    <%lastIdentOfPath(modelInfo.name)%>Jacobian(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData);
    ~<%lastIdentOfPath(modelInfo.name)%>Jacobian();
   protected:
    <%
    let jacobianfunctions = (jacobianMatrixes |> (_,_, name, _, _, _) hasindex index0 =>
    <<
     void initialAnalytic<%name%>Jacobian();
     void calc<%name%>JacobianColumn();
     void get<%name%>Jacobian(SparseMatrix& matrix);
    >>
    ;separator="\n";empty)
   <<
      <%jacobianfunctions%>
   >>
   %> 
   private:
    
  
    
    <%
    let jacobianvars = (jacobianMatrixes |> (_,_, name, _, _, _) hasindex index0 =>
    <<
     SparseMatrix _<%name%>jacobian;
     ublas::vector<double> _<%name%>jac_y;
     ublas::vector<double> _<%name%>jac_tmp;
     ublas::vector<double> _<%name%>jac_x;
    >>
    ;separator="\n";empty)
   <<
     <%jacobianvars%>
   >>
   %> 
   //workaround for jacobian variables
   <%variableDefinitionsJacobians(jacobianMatrixes,simCode)%> 
    
  };
 >>
end simulationJacobianHeaderFile;



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
    ~<%lastIdentOfPath(modelInfo.name)%>StateSelection();
    int getDimStateSets() const;
    int getDimStates(unsigned int index) const;
    int getDimCanditates(unsigned int index) const ;
    int getDimDummyStates(unsigned int index) const ;
    void getStates(unsigned int index,double* z);
    void setStates(unsigned int index,const double* z);
    void getStateCanditates(unsigned int index,double* z);
    void getAMatrix(unsigned int index,multi_array<int,2> & A) ;
    void setAMatrix(unsigned int index,multi_array<int,2>& A);
    protected:
     void  initialize();
  };
 >>
end simulationStateSelectionHeaderFile;



template simulationWriteOutputHeaderFile(SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  <<
   #pragma once
    #include "OMCpp<%fileNamePrefix%>.h"
    <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then
  <<
  #include "ReduceDAE/Interfaces/IReduceDAE.h"
  #include "DataExchange/Policies/BufferReaderWriter.h"
  typedef HistoryImpl<BufferReaderWriter,<%numAlgvars(modelInfo)%>+<%numInOutvars(modelInfo)%>+<%numAliasvars(modelInfo)%>+<%numStatevars(modelInfo)%>,<%numDerivativevars(modelInfo)%>,<%numResidues(allEquations)%>> HistoryImplType;

  >>
  else
  <<
  #include "DataExchange/Policies/TextfileWriter.h"
  typedef HistoryImpl<TextFileWriter,<%numAlgvars(modelInfo)%>+<%numInOutvars(modelInfo)%>+<%numAliasvars(modelInfo)%>+<%numStatevars(modelInfo)%>,<%numDerivativevars(modelInfo)%>,0> HistoryImplType;

  >>%>
  /*****************************************************************************
  *
  * Simulation code to write simulation file
  *
  *****************************************************************************/
  class <%lastIdentOfPath(modelInfo.name)%>WriteOutput: virtual public  <%lastIdentOfPath(modelInfo.name)%>
  {
     public:
    <%lastIdentOfPath(modelInfo.name)%>WriteOutput(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData);
    ~<%lastIdentOfPath(modelInfo.name)%>WriteOutput();
     /// Output routine (to be called by the solver after every successful integration step)
    virtual void writeOutput(const IWriteOutput::OUTPUT command = IWriteOutput::UNDEF_OUTPUT);
    virtual IHistory* getHistory();
  protected:
    void initialize();
  private:
       void writeAlgVarsResultNames(vector<string>& names);
       void writeIntAlgVarsResultNames(vector<string>& names);
       void writeBoolAlgVarsResultNames(vector<string>& names);
       void writeIntputVarsResultNames(vector<string>& names);
       void writeOutputVarsResultNames(vector<string>& names);
       void writeAliasVarsResultNames(vector<string>& names);
       void writeIntAliasVarsResultNames(vector<string>& names);
       void writeBoolAliasVarsResultNames(vector<string>& names);
       void writeStateVarsResultNames(vector<string>& names);
       void writeDerivativeVarsResultNames(vector<string>& names);
       
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
    ~<%lastIdentOfPath(modelInfo.name)%>Extension();
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
    virtual void getAMatrix(unsigned int index,multi_array<int,2>& A);
    virtual void setAMatrix(unsigned int index,multi_array<int,2>& A);
    
    
  };
 >>
end simulationExtensionHeaderFile;



template simulationFactoryFile(SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  <<
   #pragma once
   #include "Modelica.h"
   #include "OMCpp<%fileNamePrefix%>Extension.h"



  using boost::extensions::factory;
   BOOST_EXTENSION_TYPE_MAP_FUNCTION {
    types.get<std::map<std::string, factory<IMixedSystem,IGlobalSettings*,boost::shared_ptr<IAlgLoopSolverFactory>,boost::shared_ptr<ISimData> > > >()
    ["<%lastIdentOfPath(modelInfo.name)%>"].set<<%lastIdentOfPath(modelInfo.name)%>Extension>();
    }
 >>
end simulationFactoryFile;



template simulationInitCppFile(SimCode simCode)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
   #include "Modelica.h"
   #include "OMCpp<%fileNamePrefix%>Initialize.h"
   <%lastIdentOfPath(modelInfo.name)%>Initialize::<%lastIdentOfPath(modelInfo.name)%>Initialize(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData) 
   : <%lastIdentOfPath(modelInfo.name)%>(globalSettings,nonlinsolverfactory,simData)
   {
   }
  
  
   <%lastIdentOfPath(modelInfo.name)%>Initialize::~<%lastIdentOfPath(modelInfo.name)%>Initialize()
    {
    
    }
  
   
   <%GetIntialStatus(simCode)%>
   <%SetIntialStatus(simCode)%>
    <%init(simCode)%>
 >>
end simulationInitCppFile;

template simulationJacobianCppFile(SimCode simCode)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
   #include "Modelica.h"
   #include "OMCpp<%fileNamePrefix%>Jacobian.h"
   <%lastIdentOfPath(modelInfo.name)%>Jacobian::<%lastIdentOfPath(modelInfo.name)%>Jacobian(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData) 
   : <%lastIdentOfPath(modelInfo.name)%>(globalSettings,nonlinsolverfactory,simData)
   {
   }
  
  
   <%lastIdentOfPath(modelInfo.name)%>Jacobian::~<%lastIdentOfPath(modelInfo.name)%>Jacobian()
    {
    
    }
    <%functionAnalyticJacobians(jacobianMatrixes,simCode)%>
 >>
end simulationJacobianCppFile;




template simulationStateSelectionCppFile(SimCode simCode)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
   #include "Modelica.h"
   #include "OMCpp<%fileNamePrefix%>StateSelection.h"
   <%lastIdentOfPath(modelInfo.name)%>StateSelection::<%lastIdentOfPath(modelInfo.name)%>StateSelection(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData) 
   : <%lastIdentOfPath(modelInfo.name)%>(globalSettings,nonlinsolverfactory,simData)
   {
   }
  
  
   <%lastIdentOfPath(modelInfo.name)%>StateSelection::~<%lastIdentOfPath(modelInfo.name)%>StateSelection()
    {
    
    }
   <%functionDimStateSets(stateSets, simCode)%> 
   <%functionStateSets(stateSets, simCode)%> 
 >>
end simulationStateSelectionCppFile;






template simulationWriteOutputCppFile(SimCode simCode)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
   #include "Modelica.h"
   #include "OMCpp<%fileNamePrefix%>WriteOutput.h"
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
     <%writeoutput(simCode)%>

 >>
end simulationWriteOutputCppFile;




template simulationExtensionCppFile(SimCode simCode)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let classname = lastIdentOfPath(modelInfo.name)
  let initialStateSetJac = (stateSets |> set hasindex i1 fromindex 0 => (match set
       case set as SES_STATESET(__) then
              match jacobianMatrix case (_,_,name,_,_,_) then 
            'initialAnalytic<%name%>Jacobian();') ;separator="\n\n")
      
  
  <<
   #include "Modelica.h"
   #include "OMCpp<%fileNamePrefix%>Extension.h"
   <%lastIdentOfPath(modelInfo.name)%>Extension::<%lastIdentOfPath(modelInfo.name)%>Extension(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData) 
   : <%lastIdentOfPath(modelInfo.name)%>WriteOutput(globalSettings,nonlinsolverfactory,simData)
   , <%lastIdentOfPath(modelInfo.name)%>Initialize(globalSettings,nonlinsolverfactory,simData)
   , <%lastIdentOfPath(modelInfo.name)%>Jacobian(globalSettings,nonlinsolverfactory,simData)
   , <%lastIdentOfPath(modelInfo.name)%>StateSelection(globalSettings,nonlinsolverfactory,simData)
   , <%lastIdentOfPath(modelInfo.name)%>(globalSettings,nonlinsolverfactory,simData)
   
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
       <%lastIdentOfPath(modelInfo.name)%>StateSelection::initialize();
     <%initialStateSetJac%>
      
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
       	match jacobianMatrix case (_,_,name,_,_,_) then 
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
   
   void <%lastIdentOfPath(modelInfo.name)%>Extension::getAMatrix(unsigned int index,multi_array<int,2> & A) 
   {
      <%lastIdentOfPath(modelInfo.name)%>StateSelection::getAMatrix(index,A);
   }
  
   void <%lastIdentOfPath(modelInfo.name)%>Extension::setAMatrix(unsigned int index,multi_array<int,2> & A) 
   {
      <%lastIdentOfPath(modelInfo.name)%>StateSelection::setAMatrix(index,A);
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



 template functionStateSets(list<StateSet> stateSets,SimCode simCode)
  "Generates functions in simulation file to initialize the stateset data."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
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
     void  <%classname%>StateSelection::getAMatrix(unsigned int index,multi_array<int,2> & A) 
     {
     
     
     }
     void  <%classname%>StateSelection::setAMatrix(unsigned int index,multi_array<int,2>& A)
     {
     
     }
     void <%classname%>StateSelection::initialize()
     {
     
     }
     >>
 else
  let stateset = (stateSets |> set hasindex i1 fromindex 0 => (match set
       case set as SES_STATESET(__) then
       let statesvarsset = (states |> s hasindex i2 fromindex 0 => 'z[<%i2%>]=<%cref1(s,simCode,contextOther)%>;' ;separator="\n")
       let statesvarsget = (states |> s hasindex i2 fromindex 0 => '<%cref1(s,simCode,contextOther)%> = z[<%i2%>];' ;separator="\n")
       let statescandidatesvarsset = (statescandidates |> cstate hasindex i2 fromindex 0 => 'z[<%i2%>]=<%cref1(cstate,simCode,contextOther)%>;' ;separator="\n")
      
       <<
       
       >>
   )
   ;separator="\n\n")
   
   

   
  <<
     
  
    
     void  <%classname%>StateSelection::getStates(unsigned int index,double* z)
      {
       switch (index)
       { 
       	<%(stateSets |> set hasindex i1 fromindex 0 => (match set
       	case set as SES_STATESET(__) then
       	<<
       	  case <%i1%>:
       	  	<%(states |> s hasindex i2 fromindex 0 => 'z[<%i2%>]=<%cref1(s,simCode,contextOther)%>;' ;separator="\n")%>
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
       	  	<%(states |> s hasindex i2 fromindex 0 => '<%cref1(s,simCode,contextOther)%> = z[<%i2%>];' ;separator="\n")%>
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
       	  	<%(statescandidates |> cstate hasindex i2 fromindex 0 => 'z[<%i2%>]=<%cref1(cstate,simCode,contextOther)%>;' ;separator="\n")%>
       	  	break;
         >>
        )
        ;separator="\n")
        %>
      	default:
        	throw std::invalid_argument("Not supported statset index");
        }
         
       }
       void  <%classname%>StateSelection::getAMatrix(unsigned int index,multi_array<int,2> & A) 
       {
         switch (index)
         { 
       		<%(stateSets |> set hasindex i1 fromindex 0 => (match set
       		case set as SES_STATESET(__) then
       		<<
        	   case <%i1%>:
             	assign_array(A,<%arraycref(crA)%>);
             	break;
     	
       		>>
  	   		)
       	   ;separator="\n")
          %>
         default:
         throw std::invalid_argument("Not supported statset index");
      }
         
       }
       void  <%classname%>StateSelection::setAMatrix(unsigned int index,multi_array<int,2>& A)
       {
       	 switch (index)
         { 
       		<%(stateSets |> set hasindex i1 fromindex 0 => (match set
       		case set as SES_STATESET(__) then
       		<<
        	   case <%i1%>:
             	assign_array(<%arraycref(crA)%>,A);
             	break;
     	
       		>>
  	   		)
       	   ;separator="\n")
          %>
         default:
         throw std::invalid_argument("Not supported statset index");
        }
      }
       void <%classname%>StateSelection::initialize()
       {
       		<%(stateSets |> set hasindex i1 fromindex 0 => (match set
       		case set as SES_STATESET(__) then
       		<<
        	   fill_array<int,2 >( <%arraycref(crA)%>,0);
            >>
  	   		)
       	   ;separator="\n")
          %>
          
       }
    
    
   
   
   
 >>
end functionStateSets;




template simulationMainRunScrip(SimCode simCode)
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
exec ./OMCpp<%fileNamePrefix%>Main -s <%start%> -e <%end%> -f <%stepsize%> -v <%intervals%> -y <%tol%> -i <%solver%> -r <%simulationLibDir(simulationCodeTarget(),simCode)%> -m <%moLib%> -R <%simulationResults(getRunningTestsuite(),simCode)%> $*
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
<<
@echo off
<%moLib%>/OMCpp<%fileNamePrefix%>Main.exe -s <%start%> -e <%end%> -f <%stepsize%> -v <%intervals%> -y <%tol%> -i <%solver%> -r <%simulationLibDir(simulationCodeTarget(),simCode)%> -m <%moLib%> -R <%simulationResults(getRunningTestsuite(),simCode)%>
>>
end match)
end simulationMainRunScrip;


template simulationLibDir(String target, SimCode simCode)
 "Generates code for header file for simulation target."
::=
match target
case "msvc" then
match simCode
case SIMCODE(makefileParams=MAKEFILE_PARAMS(__)) then
<< <%makefileParams.omhome%>/lib/omc/cpp/msvc >>
end match
else
match simCode
case SIMCODE(makefileParams=MAKEFILE_PARAMS(__)) then
<<<%makefileParams.omhome%>/lib/omc/cpp/ >>
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



template simulationMainRunScripSuffix(SimCode simCode)
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
end simulationMainRunScripSuffix;

template simulationMainFile(SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__)) then
  <<

    #ifndef BOOST_ALL_DYN_LINK
  #define BOOST_ALL_DYN_LINK
    #endif
  #include <boost/shared_ptr.hpp>
  #include <boost/weak_ptr.hpp>
  #include <boost/numeric/ublas/vector.hpp>
  #include <boost/numeric/ublas/matrix.hpp>
  #include <string>
  #include <vector>
  #include <map>
  using std::string;
  using std::vector;
  using std::map;
  namespace ublas = boost::numeric::ublas;
  #include <SimCoreFactory/Policies/FactoryConfig.h>
  #include <SimController/ISimController.h>
  #if defined(_MSC_VER) || defined(__MINGW32__)
  #include <tchar.h>
  int _tmain(int argc, const _TCHAR* argv[])
  #else
  int main(int argc, const char* argv[])
  #endif
  {
      try
      {
      boost::shared_ptr<OMCFactory>  _factory =  boost::shared_ptr<OMCFactory>(new OMCFactory());
            //SimController to start simulation
            
            std::pair<boost::shared_ptr<ISimController>,SimSettings> simulation =  _factory->createSimulation(argc,argv);
           
      
        //create Modelica system
            std::pair<boost::weak_ptr<IMixedSystem>,boost::weak_ptr<ISimData> > system = simulation.first->LoadSystem("OMCpp<%fileNamePrefix%><%makefileParams.dllext%>","<%lastIdentOfPath(modelInfo.name)%>");
       
            simulation.first->Start(system.first,simulation.second);
       

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


template algloopHeaderFile(SimCode simCode,SimEqSystem eq)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(__) then
  <<
   <%generateAlgloopHeaderInlcudeString(simCode)%>
   <%generateAlgloopClassDeclarationCode(simCode,eq)%>

   >>
end algloopHeaderFile;

template simulationFunctionsFile(SimCode simCode, list<Function> functions, list<Exp> literals,list<String> includes)
 "Generates the content of the Cpp file for functions in the simulation case."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  <<
  #include "Modelica.h"
  #include "OMCpp<%fileNamePrefix%>Functions.h"

  <%externalFunctionIncludes(includes)%>

   Functions::Functions()
   {
     <%literals |> literal hasindex i0 fromindex 0 => literalExpConstImpl(literal,i0) ; separator="\n";empty%>
   }

   Functions::~Functions()
   {
   }
    void Functions::Assert(bool cond,string msg)
    {
        if(!cond)
            throw std::runtime_error(msg);
    }
    <%functionBodies(functions,simCode)%>
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

template simulationFunctionsHeaderFile(SimCode simCode, list<Function> functions, list<Exp> literals)
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  <<
  #pragma once
  #include "Math/ArrayOperations.h"
  #include "Math/Functions.h"
  #include "Math/Utility.h"
  #include "LibrariesConfig.h"
  /*****************************************************************************
  *
  * Simulation code for FunctionCall functions generated by the OpenModelica Compiler.
  *
  *****************************************************************************/
  //external c functions
  extern "C" {
      <%externfunctionHeaderDefinition(functions)%>
  }
  <%functionHeaderBodies1(functions,simCode)%>

  class Functions
     {
      public:
        Functions();
       ~Functions();
       //Modelica functions
       <%functionHeaderBodies2(functions,simCode)%>

       void Assert(bool cond,string msg);

       //Literals
        <%literals |> literal hasindex i0 fromindex 0 => literalExpConst(literal,i0) ; separator="\n";empty%>
     private:
    
       //Function return variables
       <%functionHeaderBodies3(functions,simCode)%>

     };
  >>

end simulationFunctionsHeaderFile;

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







template simulationMakefile(String target,SimCode simCode)
 "Generates the contents of the makefile for the simulation case."
::=
match target
case "msvc" then
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
   let dirExtra = if modelInfo.directory then '/LIBPATH:"<%modelInfo.directory%>"' //else ""
  let libsStr = (makefileParams.libs |> lib => lib ;separator=" ")
  let libsPos1 = if not dirExtra then libsStr //else ""
  let libsPos2 = if dirExtra then libsStr // else ""
  let ParModelicaLibs = if acceptParModelicaGrammar() then '-lOMOCLRuntime -lOpenCL' // else ""
  let extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then
    '<%if s.measureTime then "-D_OMC_MEASURE_TIME "%> <%match s.method
       case "inline-euler" then "-D_OMC_INLINE_EULER "
       case "inline-rungekutta" then "-D_OMC_INLINE_RK "
       case "dassljac" then "-D_OMC_JACOBIAN "%>'
    
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
  CFLAGS=  /ZI /Od /EHa /MP /fp:except /I"<%makefileParams.omhome%>/include/omc/cpp/Core/" /I"<%makefileParams.omhome%>/include/omc/cpp/" -I. <%makefileParams.includes%>  -I"$(BOOST_INCLUDE)" /I. /DNOMINMAX /TP /DNO_INTERACTIVE_DEPENDENCY
    
  CPPFLAGS = /DOMC_BUILD
  # /ZI enable Edit and Continue debug info 
  CDFLAGS = /ZI

  # /MD - link with MSVCRT.LIB
  # /link - [linker options and libraries]
  # /LIBPATH: - Directories where libs can be found
  #LDFLAGS=/MDd   /link /DLL /NOENTRY /LIBPATH:"<%makefileParams.omhome%>/lib/omc/cpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)" OMCppSystem.lib OMCppMath.lib 
  LDSYTEMFLAGS=/MD /Debug  /link /DLL /NOENTRY /LIBPATH:"<%makefileParams.omhome%>/lib/omc/cpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)" OMCppSystem.lib OMCppModelicaUtilities.lib  OMCppMath.lib   OMCppOMCFactory.lib
  LDMAINFLAGS=/MD /Debug  /link /LIBPATH:"<%makefileParams.omhome%>/lib/omc/cpp/msvc" OMCppOMCFactory.lib  /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)"    
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
  GENERATEDFILES=$(MAINFILE) $(FUNCTIONFILE)  <%algloopcppfilenames(allEquations,simCode)%> 
 
  $(MODELICA_SYSTEM_LIB)$(DLLEXT): 
  <%\t%>$(CXX)  /Fe$(SYSTEMOBJ) $(SYSTEMFILE) $(FUNCTIONFILE)   <%algloopcppfilenames(listAppend(allEquations,initialEquations),simCode)%> $(INITFILE) $(FACTORYFILE)  $(EXTENSIONFILE) $(WRITEOUTPUTFILE) $(JACOBIANFILE) $(STATESELECTIONFILE) $(CFLAGS)     $(LDSYTEMFLAGS) <%dirExtra%> <%libsPos1%> <%libsPos2%>
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
let _extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then
    '<%if s.measureTime then "-D_OMC_MEASURE_TIME "%> <%match s.method
       case "inline-euler" then "-D_OMC_INLINE_EULER"
       case "inline-rungekutta" then "-D_OMC_INLINE_RK"%>'
let extraCflags = '<%_extraCflags%><% if Flags.isSet(Flags.GEN_DEBUG_SYMBOLS) then " -g"%>'
<<
# Makefile generated by OpenModelica
include <%makefileParams.omhome%>/include/omc/cpp/ModelicaConfig.inc
# Simulations use -O0 by default
SIM_OR_DYNLOAD_OPT_LEVEL=-O0
CC=<%makefileParams.ccompiler%>
CXX=<%makefileParams.cxxcompiler%>
LINK=<%makefileParams.linker%>
EXEEXT=<%makefileParams.exeext%>
DLLEXT=<%makefileParams.dllext%>
CFLAGS_BASED_ON_INIT_FILE=<%extraCflags%>
CFLAGS=$(CFLAGS_BASED_ON_INIT_FILE) -I"<%makefileParams.omhome%>/include/omc/cpp/Core" -I"<%makefileParams.omhome%>/include/omc/cpp/"   -I. <%makefileParams.includes%> -I"$(BOOST_INCLUDE)" <%makefileParams.includes ; separator=" "%> <%makefileParams.cflags%> <%match sopt case SOME(s as SIMULATION_SETTINGS(__)) then s.cflags %>
LDSYTEMFLAGS=-L"<%makefileParams.omhome%>/lib/omc/cpp"    -L"$(BOOST_LIBS)"
LDMAINFLAGS=-L"<%makefileParams.omhome%>/lib/omc/cpp" <%simulationMainDLLib(simCode)%> -L"<%makefileParams.omhome%>/bin" -lOMCppOMCFactory -L"$(BOOST_LIBS)" $(BOOST_SYSTEM_LIB) $(BOOST_FILESYSTEM_LIB) $(BOOST_PROGRAM_OPTIONS_LIB)   
CPPFLAGS = $(CFLAGS) -DOMC_BUILD -DBOOST_SYSTEM_NO_DEPRICATED
SYSTEMFILE=OMCpp<%fileNamePrefix%><% if acceptMetaModelicaGrammar() then ".conv"%>.cpp
FUNCTIONFILE=OMCpp<%fileNamePrefix%>Functions.cpp
INITFILE=OMCpp<%fileNamePrefix%>Initialize.cpp
EXTENSIONFILE=OMCpp<%fileNamePrefix%>Extension.cpp
WRITEOUTPUTFILE=OMCpp<%fileNamePrefix%>WriteOutput.cpp
JACOBIANFILE=OMCpp<%fileNamePrefix%>Jacobian.cpp
STATESELECTIONFILE=OMCpp<%fileNamePrefix%>StateSelection.cpp
FACTORYFILE=OMCpp<%fileNamePrefix%>FactoryExport.cpp
MAINFILE = OMCpp<%fileNamePrefix%>Main.cpp
MAINOBJ=OMCpp<%fileNamePrefix%>Main$(EXEEXT)
SYSTEMOBJ=OMCpp<%fileNamePrefix%>$(DLLEXT)



CPPFILES=$(SYSTEMFILE) $(FUNCTIONFILE) $(INITFILE) $(WRITEOUTPUTFILE) $(EXTENSIONFILE) $(FACTORYFILE) $(JACOBIANFILE) $(STATESELECTIONFILE) <%algloopcppfilenames(listAppend(allEquations,initialEquations),simCode)%>
OFILES=$(CPPFILES:.cpp=.o)

.PHONY: <%lastIdentOfPath(modelInfo.name)%> $(CPPFILES)

<%fileNamePrefix%>: $(MAINFILE) $(OFILES)
<%\t%>$(CXX) -shared -I. -o $(SYSTEMOBJ) $(OFILES) $(CPPFLAGS) $(LDSYTEMFLAGS)  <%dirExtra%> <%libsPos1%> <%libsPos2%> -lOMCppSystem -lOMCppModelicaUtilities -lOMCppMath 
<%\t%>$(CXX) $(CPPFLAGS) -I. -o $(MAINOBJ) $(MAINFILE) $(LDMAINFLAGS)
<% if boolNot(stringEq(makefileParams.platform, "win32")) then
  <<
  <%\t%>chmod +x <%fileNamePrefix%>.sh
  <%\t%>ln -s <%fileNamePrefix%>.sh <%fileNamePrefix%>
  >>
%>
>>

end simulationMakefile;

   

template simulationCppFile(SimCode simCode)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
   #include "Modelica.h"
   #include "OMCpp<%fileNamePrefix%>.h"



 
    
    <%lastIdentOfPath(modelInfo.name)%>::<%lastIdentOfPath(modelInfo.name)%>(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData) 
   :SystemDefaultImplementation(*globalSettings)
    ,_algLoopSolverFactory(nonlinsolverfactory)
    ,_simData(simData)
    <%simulationInitFile(simCode)%>
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
    //DAE's are not supported yet, Index reduction is enabled
    _dimAE = 0; // algebraic equations
    //Initialize the state vector
    SystemDefaultImplementation::initialize();
    //Instantiate auxiliary object for event handling functionality
    _event_handling.getCondition =  boost::bind(&<%lastIdentOfPath(modelInfo.name)%>::getCondition, this, _1);
     <%arrayReindex(modelInfo)%>
    //Initialize array elements
    <%initializeArrayElements(simCode)%>
   
   

    }
    <%lastIdentOfPath(modelInfo.name)%>::~<%lastIdentOfPath(modelInfo.name)%>()
    {
   
    }
  
  
   <%Update(simCode)%>
  
   <%DefaultImplementationCode(simCode)%>
   <%checkForDiscreteEvents(discreteModelVars,simCode)%>
   <%giveZeroFunc1(zeroCrossings,simCode)%>
   <%setConditions(simCode)%>
   <%geConditions(simCode)%>
   <%isConsistent(simCode)%>
   <%generateStepCompleted(listAppend(allEquations,initialEquations),simCode)%>
   <%generatehandleTimeEvent(timeEvents, simCode)%>
   <%generateDimTimeEvent(listAppend(allEquations,initialEquations),simCode)%>
   <%generateTimeEvent(timeEvents, simCode)%>
   
   
   <%isODE(simCode)%>
   <%DimZeroFunc(simCode)%>
  
   
  
   <%getCondition(zeroCrossings,whenClauses,simCode)%>
   <%handleSystemEvents(zeroCrossings,whenClauses,simCode)%>
   <%saveall(modelInfo,simCode)%>
   <%savediscreteVars(modelInfo,simCode)%>
   <%LabeledDAE(modelInfo.labels,simCode)%>
    <%giveVariables(modelInfo)%>
   >>
end simulationCppFile;
/* <%saveConditions(simCode)%>*/
  /*<%arrayInit(simCode)%>*/

    /* */
  /* <%modelname%>Algloop<%index%>::<%modelname%>Algloop<%index%>(<%constructorParams%> double* z,double* zDot,EventHandling& event_handling )
  ,<%iniAlgloopParamas%>*/
template algloopCppFile(SimCode simCode,SimEqSystem eq)
 "Generates code for main cpp file for algloop system ."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname =  lastIdentOfPath(modelInfo.name)
  let modelfilename =  fileNamePrefix
   let &varDecls = buffer ""
   let &arrayInit = buffer ""
   let constructorParams = ConstructorParamAlgloop(modelInfo)
   let iniAlgloopParamas = InitAlgloopParams(modelInfo,arrayInit)

match eq
    case SES_LINEAR(__)
    case SES_NONLINEAR(__) then

  <<
   #include "Modelica.h"
   #include "OMCpp<%modelfilename%>Algloop<%index%>.h"
   #include "OMCpp<%modelfilename%>.h"
   <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then '#include "Math/ArrayOperations.h"'%>



    <%modelname%>Algloop<%index%>::<%modelname%>Algloop<%index%>(<%modelname%>* system, double* z,double* zDot,bool* conditions, EventHandling& event_handling )
   :AlgLoopDefaultImplementation()
   ,_system(system)
   ,__z(z)
   ,__zDot(zDot)
   ,_conditions(conditions)
   ,_event_handling(event_handling)
   <%alocateLinearSystem(eq)%>

    {

      <%initAlgloopDimension(eq,varDecls)%>

    }

   <%modelname%>Algloop<%index%>::~<%modelname%>Algloop<%index%>()
    {

    }
   <%algloopRHSCode(simCode,eq)%>
   <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then algloopResiduals(simCode,eq)%>
   <%initAlgloop(simCode,eq)%>
   <%upateAlgloopNonLinear(simCode,eq)%>
   <%upateAlgloopLinear(simCode,eq)%>
   <%AlgloopDefaultImplementationCode(simCode,eq)%>
   <%getAMatrixCode(simCode,eq)%>
   <%isLinearCode(simCode,eq)%>
    >>
end algloopCppFile;


template upateAlgloopNonLinear( SimCode simCode,SimEqSystem eqn)
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
     let algs = (eq.eqs |> eq2 as SES_ALGORITHM(__) =>
         equation_(eq2, contextAlgloop, &varDecls /*BUFD*/,simCode)
       ;separator="\n")
     let prebody = (eq.eqs |> eq2 as SES_SIMPLE_ASSIGN(__) =>
         equation_(eq2, contextAlgloop, &varDecls /*BUFD*/,simCode)
       ;separator="\n")
      let extraresidual = (eq.eqs |> eq2 =>
         functionExtraResidualsPreBody(eq2, &varDecls /*BUFD*/,contextAlgloop,simCode)
      ;separator="\n")
     let body = (eq.eqs |> eq2 as SES_RESIDUAL(__) hasindex i0 =>
         let &preExp = buffer "" /*BUFD*/
         let expPart = daeExp(eq2.exp, contextAlgloop,
                            &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
         '<%preExp%>__xd[<%i0%>] = <%expPart%>;'

       ;separator="\n")
       

  <<
  void <%modelname%>Algloop<%index%>::evaluate(const IContinuous::UPDATETYPE command)
  {
        <%varDecls%>
     

         <%algs%>
        <%extraresidual%>
        <%prebody%>
           <%body%>
      

  }
  >>
end upateAlgloopNonLinear;


template functionExtraResidualsPreBody(SimEqSystem eq, Text &varDecls /*BUFP*/, Context context, SimCode simCode)
 "Generates an equation."
::=
  match eq
  case e as SES_RESIDUAL(__)
  then ""
  else
  equation_(eq, context, &varDecls /*BUFD*/, simCode)
  end match
end functionExtraResidualsPreBody;





template upateAlgloopLinear( SimCode simCode,SimEqSystem eqn)
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
     let &preExp = buffer "" /*BUFD*/



 let Amatrix=
    (simJac |> (row, col, eq as SES_RESIDUAL(__)) =>
      let expPart = daeExp(eq.exp, contextAlgloop, &preExp /*BUFC*/,  &varDecls /*BUFD*/,simCode)
      '<%preExp%>__A[<%row%>][<%col%>]=<%expPart%>;'
  ;separator="\n")



 let bvector =  (beqs |> exp hasindex i0 =>

     let expPart = daeExp(exp, contextAlgloop, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
     '<%preExp%>__b[<%i0%>]=<%expPart%>;'
  ;separator="\n")


 <<
   void <%modelname%>Algloop<%index%>::evaluate(const IContinuous::UPDATETYPE command)
  {
      <%varDecls%>
      <%Amatrix%>
      <%bvector%>

  }

     >>

end upateAlgloopLinear;

template inlineVars(Context context, list<SimVar> simvars)
::= match context case INLINE_CONTEXT(__) then match simvars
case {} then ''
else <<

<%simvars |> var => match var case SIMVAR(name = cr as CREF_QUAL(ident = "$DER")) then 'inline_integrate(<%cref(cr)%>);' ;separator="\n"%>
>>
end inlineVars;

template functionBodies(list<Function> functions,SimCode simCode)
 "Generates the body for a set of functions."
::=
  (functions |> fn => functionBody(fn, false,simCode) ;separator="\n")
end functionBodies;

template functionBody(Function fn, Boolean inFunc,SimCode simCode)
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
  case fn as FUNCTION(__)           then functionBodyRegularFunction(fn, inFunc,simCode)
  case fn as EXTERNAL_FUNCTION(__)  then functionBodyExternalFunction(fn, inFunc,simCode)
  case fn as RECORD_CONSTRUCTOR(__) then functionBodyRecordConstructor(fn)
end functionBody;

template externfunctionHeaderDefinition(list<Function> functions)
 "Generates the body for a set of functions."
::=
  (functions |> fn => extFunDef(fn) ;separator="\n")
end externfunctionHeaderDefinition;

template functionHeaderBodies1(list<Function> functions,SimCode simCode)
 "Generates the body for a set of functions."
::=
match simCode
    case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
   let recorddecls = (recordDecls |> rd => recordDeclarationHeader(rd,simCode) ;separator="\n")
   let rettypedecls =  (functions |> fn => functionHeaderBody1(fn,simCode) ;separator="\n")
   <<
   <%recorddecls%>
   <%rettypedecls%>
   >>
end    functionHeaderBodies1;

template functionHeaderBody1(Function fn,SimCode simCode)
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
  case fn as FUNCTION(__)           then functionHeaderRegularFunction1(fn,simCode)
  case fn as EXTERNAL_FUNCTION(__)  then functionHeaderExternFunction(fn,simCode)
  case fn as RECORD_CONSTRUCTOR(__) then  functionHeaderRegularFunction1(fn,simCode)
end functionHeaderBody1;

template functionHeaderBodies2(list<Function> functions,SimCode simCode)
 "Generates the body for a set of functions."
::=
  (functions |> fn => functionHeaderBody2(fn,simCode) ;separator="\n")
end functionHeaderBodies2;

template functionHeaderBody2(Function fn,SimCode simCode)
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
  case fn as FUNCTION(__)           then functionHeaderRegularFunction2(fn,simCode)
  case fn as EXTERNAL_FUNCTION(__)  then functionHeaderRegularFunction2(fn,simCode)
  case fn as RECORD_CONSTRUCTOR(__) then functionHeaderRecordConstruct(fn,simCode)
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
 case "ModelicaInternal_stat"
 then ""
 case "ModelicaInternal_fullPathName"
 then ""
 else 
  //let fn_name = extFunctionName(extName, language)
  <<
  extern <%extReturnType(return)%> <%extName%>(<%fargsStr%>);
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
  match type case T_ARRAY(__) then s else if isInput then (if isArray then '<%match s case "const char*" then "" else "const "%><%s%>*' else s) else '<%s%>*'
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


template functionHeaderRegularFunction1(Function fn,SimCode simCode)
::=
match fn
 case FUNCTION(outVars={var}) then
 let fname = underscorePath(name)
  << /*default return type*/
    typedef <%funReturnDefinition1(var,simCode)%>  <%fname%>RetType;
    typedef <%funReturnDefinition2(var,simCode)%>  <%fname%>RefRetType;
  >>

  
case FUNCTION(outVars= vars as _::_) then 

 let fname = underscorePath(name)
  << /*tuple return type*/
    struct <%fname%>Type
    {
       typedef boost::tuple< <%vars |> var => funReturnDefinition1(var,simCode) ;separator=", "%> > TUPLE_ARRAY;
   
      <%fname%>Type& operator=(const <%fname%>Type& A)
      {
        <%vars |> var hasindex i0 => tupplearrayassign(var,i0) ;separator="\n "%>
        return *this;
      }
      TUPLE_ARRAY data;
    };
    typedef <%fname%>Type <%fname%>RetType;
  >>

 case RECORD_CONSTRUCTOR(__) then
      
      let fname = underscorePath(name)
      
      <<

      typedef <%fname%>Type <%fname%>RetType;
      >>
end functionHeaderRegularFunction1;

template tupplearrayassign(Variable var,Integer index)
::=
  match var
  case var as VARIABLE(__) then
     if instDims then 'assign_array(get<<%index%>>(data),get<<%index%>>(A.data));' else 'get<<%index%>>(data)= get<<%index%>>(A.data);'
end tupplearrayassign;

template functionHeaderRecordConstruct(Function fn,SimCode simCode)
::=
match fn
 case RECORD_CONSTRUCTOR(__) then
      let fname = underscorePath(name)
      let funArgsStr = (funArgs |> var as VARIABLE(__) =>
          '<%varType2(var)%> <%crefStr(name)%>'
        ;separator=", ")
      <<
      <%fname%>Type <%fname%>(<%funArgsStr%>);
      >>
end functionHeaderRecordConstruct;

template functionHeaderExternFunction(Function fn,SimCode simCode)
::=
match fn
case EXTERNAL_FUNCTION(outVars={var}) then

  let fname = underscorePath(name)
  <<
    typedef  <%funReturnDefinition1(var,simCode)%> <%fname%>RetType;
  >>
 case EXTERNAL_FUNCTION(outVars=_::_) then

  let fname = underscorePath(name)
  <<
    typedef boost::tuple< <%outVars |> var => funReturnDefinition1(var,simCode) ;separator=", "%> >  <%fname%>RetType;
  >>
end functionHeaderExternFunction;

template recordDeclarationHeader(RecordDeclaration recDecl,SimCode simCode)
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
             <%variables |> var as VARIABLE(__) => '<%recordDeclarationHeaderArrayAllocate(var,simCode)%>' ;separator="\n"%>
        }
        //Public  Members
        <%variables |> var as VARIABLE(__) => '<%varType1(var)%> <%crefStr(var.name)%>;' ;separator="\n"%>
    };
    >>
  case RECORD_DECL_DEF(__) then
    <<
    RECORD DECL DEF
    >>
end recordDeclarationHeader;

template recordDeclarationHeaderArrayAllocate(Variable v,SimCode simCode)
 "Generates structs for a record declaration."
::=
  match v
  case var as VARIABLE(ty=ty as T_ARRAY(__)) then
  let instDimsInit = (ty.dims |> exp =>
     dimension(exp);separator="][")
     let arrayname = crefStr(name)
  <<
   <%arrayname%>.resize((boost::extents[<%instDimsInit%>]));
   <%arrayname%>.reindex(1);
  >>
end recordDeclarationHeaderArrayAllocate;

template functionBodyRecordConstructor(Function fn)
 "Generates the body for a record constructor."
::=
match fn
case RECORD_CONSTRUCTOR(__) then
  let()= System.tmpTickReset(1)
  let &varDecls = buffer "" /*BUFD*/
  let fname = underscorePath(name)
  let retType = '<%fname%>Type'
  let retVar = tempDecl(retType, &varDecls /*BUFD*/)
  let structType = '<%fname%>Type'
  let structVar = tempDecl(structType, &varDecls /*BUFD*/)

  <<
  <%retType%> Functions::<%fname%>(<%funArgs |> var as  VARIABLE(__) => '<%varType2(var)%> <%crefStr(name)%>' ;separator=", "%>)
  {

    <%varDecls%>
    <%funArgs |> VARIABLE(__) => '<%structVar%>.<%crefStr(name)%> = <%crefStr(name)%>;' ;separator="\n"%>
    return <%structVar%>;
  }



  >>
end functionBodyRecordConstructor;

template daeExpSharedLiteral(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for a match expression."
::=
match exp case exp as SHARED_LITERAL(__) then
 match context case FUNCTION_CONTEXT(__) then
 ' _OMC_LIT<%exp.index%>'
 else
'_functions._OMC_LIT<%exp.index%>'
end daeExpSharedLiteral;


template functionHeaderRegularFunction2(Function fn,SimCode simCode)
::=
match fn
case FUNCTION(outVars=_) then
  let fname = underscorePath(name)
  <<
        <%fname%>RetType <%fname%>(<%functionArguments |> var => funArgDefinition(var,simCode) ;separator=", "%>);
  >>
case EXTERNAL_FUNCTION(outVars=var::_) then
let fname = underscorePath(name)
   <<
        <%fname%>RetType <%fname%>(<%funArgs |> var => funArgDefinition(var,simCode) ;separator=", "%>);
   >>
case EXTERNAL_FUNCTION(outVars={}) then
let fname = underscorePath(name)
   <<
        void <%fname%>(<%funArgs |> var => funArgDefinition(var,simCode) ;separator=", "%>);
   >>
end functionHeaderRegularFunction2;

template functionHeaderRegularFunction3(Function fn,SimCode simCode)
::=
match fn
case FUNCTION(outVars=_) then
  let fname = underscorePath(name)
  <<
        <%fname%>RetType _<%fname%>;
  >>
 case EXTERNAL_FUNCTION(outVars=var::_) then
 let fname = underscorePath(name)
 <<
        <%fname%>RetType _<%fname%>;
  >>
end functionHeaderRegularFunction3;

template functionBodyRegularFunction(Function fn, Boolean inFunc,SimCode simCode)
 "Generates the body for a Modelica/MetaModelica function."
::=
match fn
case FUNCTION(__) then
  let()= System.tmpTickReset(1)
  let fname = underscorePath(name)
  let retType = if outVars then '<%fname%>RetType' else "void"
  let &varDecls = buffer "" /*BUFD*/
  let &varInits = buffer "" /*BUFD*/
  //let retVar = if outVars then tempDecl(retType, &varDecls /*BUFD*/)
  //let stateVar = if not acceptMetaModelicaGrammar() then tempDecl("state", &varDecls /*BUFD*/)
  let _ = (variableDeclarations |> var hasindex i1 fromindex 1 =>
      varInit(var, "", i1, &varDecls /*BUFD*/, &varInits /*BUFC*/,simCode) ; empty /* increase the counter! */
    )
  //let addRootsInputs = (functionArguments |> var => addRoots(var) ;separator="\n")
  //let addRootsOutputs = (outVars |> var => addRoots(var) ;separator="\n")
  //let funArgs = (functionArguments |> var => functionArg(var, &varInits) ;separator="\n")
  let bodyPart = (body |> stmt  => funStatement(stmt, &varDecls /*BUFD*/,simCode) ;separator="\n")
  let &outVarInits = buffer ""
  let &outVarCopy = buffer ""
  let &outVarAssign = buffer ""
     let _ =  match outVars   case {var} then (outVars |> var hasindex i1 fromindex 0 =>
     varOutput(fn, var,i1, &varDecls, &outVarInits, &outVarCopy, &outVarAssign, simCode)
      ;separator="\n"; empty /* increase the counter! */
     )
    else
      (outVars |> var hasindex i1 fromindex 0 =>
     varOutputTuple(fn, var,i1, &varDecls, &outVarInits, &outVarCopy, &outVarAssign, simCode)
      ;separator="\n"; empty /* increase the counter! */
     )






  //let boxedFn = if acceptMetaModelicaGrammar() then functionBodyBoxed(fn)
  <<
  <%retType%> Functions::<%fname%>(<%functionArguments |> var => funArgDefinition(var,simCode) ;separator=", "%>)
  {
    <%varDecls%>
    <%outVarInits%>
    <%varInits%>
    do
    {
        <%bodyPart%>
    }
    while(false);
    <%outVarAssign%>
    return <%if outVars then '_<%fname%>' %>;
  }

  <% if inFunc then
  <<
  int in_<%fname%>(type_description * inArgs, type_description * outVar)
  {
    <%functionArguments |> var => '<%funArgDefinition(var,simCode)%>;' ;separator="\n"%>
    <%if outVars then '<%retType%> out;'%>

    //MMC_TRY_TOP()



    return 0;
  }
  >>
  %>


  >>
end functionBodyRegularFunction;


template functionBodyExternalFunction(Function fn, Boolean inFunc,SimCode simCode)
 "Generates the body for an external function (just a wrapper)."
::=
match fn
case efn as EXTERNAL_FUNCTION(__) then
  let()= System.tmpTickReset(1)
  let fname = underscorePath(name)
  let retType = if outVars then '<%fname%>RetType' else "void"
  let &preExp = buffer "" /*BUFD*/
  let &varDecls = buffer "" /*BUFD*/
  // make sure the variable is named "out", doh!
   let retVar = if outVars then '_<%fname%>'
  let &outVarInits = buffer ""
  let callPart = extFunCall(fn, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  let _ = ( outVars |> var hasindex i1 fromindex 1 =>
            varInit(var, retVar, i1, &varDecls /*BUFD*/, &outVarInits /*BUFC*/,simCode)
            ; empty /* increase the counter! */
          )

  let fnBody = <<
  <%retType%> Functions::<%fname%>(<%funArgs |> var => funArgDefinition(var,simCode) ;separator=", "%>)
  {
    /* functionBodyExternalFunction: varDecls */
    <%varDecls%>
    /* functionBodyExternalFunction: preExp */
    <%preExp%>
    /* functionBodyExternalFunction: outputAlloc */
    <%outVarInits%>
    /* functionBodyExternalFunction: callPart */
    <%callPart%>
     /* functionBodyExternalFunction: return */
     return <%retVar%>;
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
    <%funArgs |> VARIABLE(__) => '<%expTypeArrayIf(ty)%> <%contextCref(name,contextFunction,simCode)%>;' ;separator="\n"%>
    <%retType%> out;
    <%funArgs |> arg as VARIABLE(__) => readInVar(arg,simCode) ;separator="\n"%>
    MMC_TRY_TOP()
    out = _<%fname%>(<%funArgs |> VARIABLE(__) => contextCref(name,contextFunction,simCode) ;separator=", "%>);
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

template readInVar(Variable var,SimCode simCode)
 "Generates code for reading a variable from inArgs."
::=
  match var
  case VARIABLE(name=cr, ty=T_COMPLEX(complexClassType=RECORD(__))) then
    <<
    if (read_modelica_record(&inArgs, <%readInVarRecordMembers(ty, contextCref(cr,contextFunction,simCode))%>)) return 1;
    >>
  case VARIABLE(name=cr, ty=T_STRING(__)) then
    <<
    if (read_<%expTypeArrayIf(ty)%>(&inArgs, <%if not acceptMetaModelicaGrammar() then "(char**)"%> &<%contextCref(name,contextFunction,simCode)%>)) return 1;
    >>
  case VARIABLE(__) then
    <<
    if (read_<%expTypeArrayIf(ty)%>(&inArgs, &<%contextCref(name,contextFunction,simCode)%>)) return 1;
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

template extFunCall(Function fun, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates the call to an external function."
::=
match fun
case EXTERNAL_FUNCTION(__) then
  match language
  case "C" then extFunCallC(fun, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
 end extFunCall;



template extFunCallC(Function fun, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode)
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
      extArg(arg, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
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
  <%extArgs |> arg => extFunCallVarcopy(arg,fname) ;separator="\n"%>

  <%match extReturn case SIMEXTARG(__) then extFunCallVarcopy(extReturn,fname)%>
  >>
end extFunCallC;

template extFunCallVarcopy(SimExtArg arg, String fnName)
 "Helper to extFunCall."
::=
match arg
case SIMEXTARG(outputIndex=oi, isArray=false, type_=ty, cref=c) then
  match oi case 0 then
    ""
  else
    let cr = '<%extVarName2(c)%>'
    <<
     _<%fnName%> = <%cr%>;
    >>
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
     <%assginBegin%>_<%fnName%>.data<%assginEnd%> = <%cr%>;
    >>
end extFunCallVarcopyTuple;

template expTypeModelica(DAE.Type ty)
 "Generate type helper."
::=
  expTypeFlag(ty, 2)
end expTypeModelica;


template extArg(SimExtArg extArg, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode)
 "Helper to extFunCall."
::=
  match extArg
  case SIMEXTARG(cref=c, outputIndex=oi, isArray=true, type_=t) then
    let name = if oi then 'out.targTest5<%oi%>' else contextCref2(c,contextFunction)
    let shortTypeStr = expTypeShort(t)
    ' <%name%>.data()'
  case SIMEXTARG(cref=c, isInput=ii, outputIndex=0, type_=t) then
    let cr = '<%contextCref2(c,contextFunction)%>'
    if acceptMetaModelicaGrammar() then
      (match t case T_STRING(__) then 'MMC_STRINGDATA(<%cr%>)' else '<%cr%>_ext')
    else
      '<%cr%><%match t case T_STRING(__) then ".c_str()" else "_ext"%>'
  case SIMEXTARG(cref=c, isInput=ii, outputIndex=oi, type_=t) then
    '&<%extVarName2(c)%>'
  case SIMEXTARGEXP(__) then
    daeExternalCExp(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  case SIMEXTARGSIZE(cref=c) then
    let typeStr = expTypeShort(type_)
    let name = if outputIndex then 'out.targTest4<%outputIndex%>' else contextCref2(c,contextFunction)
    let dim = daeExp(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    '<%name%>.shape()[<%dim%> -1]'

end extArg;


template daeExternalCExp(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode)
  "Like daeExp, but also converts the type to external C"
::=
  match typeof(exp)
    case T_ARRAY(__) then  // Array-expressions
      let shortTypeStr = expTypeShort(typeof(exp))
      '<%daeExp(exp, context, &preExp, &varDecls,simCode)%>).data()'
    else daeExp(exp, context, &preExp, &varDecls,simCode)


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
          Text &varInits, Text &varCopy, Text &varAssign, SimCode simCode)
 "Generates code to copy result value from a function to dest."
::=
match fn
case FUNCTION(__) then
 let fname = underscorePath(name)
match var
/* The storage size of arrays is known at call time, so they can be allocated
 * before set_memory_state. Strings are not known, so we copy them, etc...
 */
case var as VARIABLE(ty = T_STRING(__)) then
    if not acceptMetaModelicaGrammar() then
      // We need to strdup() all strings, then allocate them on the memory pool again, then free the temporary string
      let strVar = tempDecl("modelica_string_t", &varDecls)
      let &varCopy += '<%strVar%> = strdup(<%contextCref(var.name,contextFunction,simCode)%>);<%\n%>'
      let &varAssign +=
        <<
        _<%fname%> = init_modelica_string(<%strVar%>);
        free(<%strVar%>);<%\n%>
        >>
      ""
    else
      let &varAssign += '_<%fname%>= <%contextCref(var.name,contextFunction,simCode)%>;<%\n%>'
      ""
case var as VARIABLE(__) then
  let marker = '<%contextCref(var.name,contextFunction,simCode)%>'
  let &varInits += '/* varOutput varInits(<%marker%>) */ <%\n%>'
  let &varAssign += '/* varOutput varAssign(<%marker%>) */ <%\n%>'
  let instDimsInit = (instDims |> exp =>
      daeExp(exp, contextFunction, &varInits /*BUFC*/, &varDecls /*BUFD*/,simCode)
    ;separator="][")
 if instDims then
    let &varInits += '_<%fname%>.resize((boost::extents[<%instDimsInit%>]));
    _<%fname%>.reindex(1);<%\n%>'
    let &varAssign += '_<%fname%>=<%contextCref(var.name,contextFunction,simCode)%>;<%\n%>'
    ""
  else
   // let &varInits += initRecordMembers(var)
    let &varAssign += '_<%fname%> = <%contextCref(var.name,contextFunction,simCode)%>;<%\n%>'
    ""
case var as FUNCTION_PTR(__) then
    let &varAssign += '_<%fname%> = (modelica_fnptr) _<%var.name%>;<%\n%>'
    ""
end varOutput;




template varOutputTuple(Function fn, Variable var, Integer ix, Text &varDecls,
          Text &varInits, Text &varCopy, Text &varAssign, SimCode simCode)
 "Generates code to copy result value from a function to dest."
::=
match fn
case FUNCTION(__) then
 let fname = underscorePath(name)
match var
/* The storage size of arrays is known at call time, so they can be allocated
 * before set_memory_state. Strings are not known, so we copy them, etc...
 */
case var as VARIABLE(ty = T_STRING(__)) then
    if not acceptMetaModelicaGrammar() then
      // We need to strdup() all strings, then allocate them on the memory pool again, then free the temporary string
      let strVar = tempDecl("modelica_string_t", &varDecls)
      let &varCopy += '<%strVar%> = strdup(<%contextCref(var.name,contextFunction,simCode)%>);<%\n%>'
      let &varAssign +=
        <<
        _<%fname%> = init_modelica_string(<%strVar%>);
        free(<%strVar%>);<%\n%>
        >>
      ""
    else
      let &varAssign += '_<%fname%>= <%contextCref(var.name,contextFunction,simCode)%>;<%\n%>'
      ""
case var as VARIABLE(__) then
  let marker = '<%contextCref(var.name,contextFunction,simCode)%>'
  let &varInits += '/* varOutput varInits(<%marker%>) */ <%\n%>'
  let &varAssign += '/* varOutput varAssign(<%marker%>) */ <%\n%>'
  let instDimsInit = (instDims |> exp =>
      daeExp(exp, contextFunction, &varInits /*BUFC*/, &varDecls /*BUFD*/,simCode)
    ;separator="][")
  let assginBegin = 'get<<%ix%>>('
  let assginEnd = ')'
  if instDims then
    let &varInits += '<%assginBegin%>_<%fname%>.data<%assginEnd%>.resize((boost::extents[<%instDimsInit%>]));
    <%assginBegin%>_<%fname%>.data<%assginEnd%>.reindex(1);<%\n%>'
    let &varAssign += '<%assginBegin%>_<%fname%>.data<%assginEnd%>=<%contextCref(var.name,contextFunction,simCode)%>;<%\n%>'
    ""
  else
   // let &varInits += initRecordMembers(var)
    let &varAssign += ' <%assginBegin%>_<%fname%>.data<%assginEnd%> = <%contextCref(var.name,contextFunction,simCode)%>;<%\n%>'
    ""
case var as FUNCTION_PTR(__) then
    let &varAssign += '_<%fname%> = (modelica_fnptr) _<%var.name%>;<%\n%>'
    ""
end varOutputTuple;

template varInit(Variable var, String outStruct, Integer i, Text &varDecls /*BUFP*/, Text &varInits /*BUFP*/, SimCode simCode)
 "Generates code to initialize variables.
  Does not return anything: just appends declarations to buffers."
::=
match var
case var as VARIABLE(__) then
  let varName = '<%contextCref(var.name,contextFunction,simCode)%>'
  let typ = '<%varType(var)%>'
  let initVar = match typ case "modelica_metatype" then ' = NULL' else ''
  let addRoot = match typ case "modelica_metatype" then ' mmc_GC_add_root(&<%varName%>, mmc_GC_local_state, "<%varName%>");' else ''
  let &varDecls += if instDims then 'multi_array<<%expTypeShort(var.ty)%>,<%listLength(instDims)%>> <%varName%><%initVar%>;<%addRoot%><%\n%>' else '<%typ%> <%varName%><%initVar%>;<%addRoot%><%\n%>'
  let varName = if outStruct then '<%outStruct%>.targTest3<%i%>' else '<%contextCref(var.name,contextFunction,simCode)%>'
  let instDimsInit = (instDims |> exp =>
      daeExp(exp, contextFunction, &varInits /*BUFC*/, &varDecls /*BUFD*/,simCode)
    ;separator="][")
  if instDims then
    (match var.value
    case SOME(exp) then
      let &varInits += '<%varName%>.resize((boost::extents[<%instDimsInit%>]));
      <%varName%>.reindex(1);<%\n%>'
      let defaultValue = varDefaultValue(var, outStruct, i, varName, &varDecls, &varInits,simCode)
      let &varInits += defaultValue
      let var_name = if outStruct then
        '<%extVarName(var.name,simCode)%>' else
        '<%contextCref(var.name, contextFunction,simCode)%>'
      let defaultValue1 = '<%var_name%> = <%daeExp(exp, contextFunction, &varInits  /*BUFC*/, &varDecls /*BUFD*/,simCode)%>;<%\n%>'
      let &varInits += defaultValue1
      " "
    else
      let &varInits += '<%varName%>.resize((boost::extents[<%instDimsInit%>]));
      <%varName%>.reindex(1);<%\n%>'
      let defaultValue = varDefaultValue(var, outStruct, i, varName, &varDecls, &varInits,simCode)
     let &varInits += defaultValue
      "")
  else
    (match var.value
    case SOME(exp) then
      let defaultValue = '<%contextCref(var.name,contextFunction,simCode)%> = <%daeExp(exp, contextFunction, &varInits  /*BUFC*/, &varDecls /*BUFD*/,simCode)%>;<%\n%>'
      let &varInits += defaultValue

      " "
    else
      "")
case var as FUNCTION_PTR(__) then
  let &ignore = buffer ""
  let &varDecls += functionArg(var,&ignore)
  ""

end varInit;

template functionArg(Variable var, Text &varInit)
"Shared code for function arguments that are part of the function variables and valueblocks.
Valueblocks need to declare a reference to the function while input variables
need to initialize."
::=
match var
case var as FUNCTION_PTR(__) then
  let typelist = (args |> arg => mmcVarType(arg) ;separator=", ")
  let rettype = '<%name%>RetType'
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

template extVarName(ComponentRef cr, SimCode simCode)
::= '<%contextCref(cr,contextFunction,simCode)%>_ext'
end extVarName;

template extVarName2(ComponentRef cr)
::= '<%contextCref2(cr,contextFunction)%>_ext'
end extVarName2;

template varDefaultValue(Variable var, String outStruct, Integer i, String lhsVarName,  Text &varDecls /*BUFP*/, Text &varInits /*BUFP*/,SimCode simCode)
::=
match var
case var as VARIABLE(__) then
  match value
  case SOME(CREF(componentRef = cr)) then
    '<%contextCref(cr,contextFunction,simCode)%> =  <%outStruct%>.targTest9<%i%><%\n%>'
  case SOME(arr as ARRAY(__)) then
    let arrayExp = '<%daeExp(arr, contextFunction, &varInits /*BUFC*/, &varDecls /*BUFD*/,simCode)%>'
    <<
    <%lhsVarName%> = <%arrayExp%>;<%\n%>
    >>
end varDefaultValue;


template funArgDefinition(Variable var,SimCode simCode)
::=
  match var
  case VARIABLE(__) then '<%varType1(var)%> <%contextCref(name,contextFunction,simCode)%>'
  case FUNCTION_PTR(__) then 'modelica_fnptr <%name%>'
end funArgDefinition;

template funExtArgDefinition(SimExtArg extArg,SimCode simCode)
::=
  match extArg
  case SIMEXTARG(cref=c, isInput=ii, isArray=ia, type_=t) then
    let name = contextCref(c,contextFunction,simCode)
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
  case VARIABLE(__) then '<%varType1(var)%>'
  case FUNCTION_PTR(__) then 'modelica_fnptr <%name%>'
end funReturnDefinition1;

template funReturnDefinition2(Variable var,SimCode simCode)
::=
  match var
  case VARIABLE(__) then '<%varType2(var)%>'
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


template varType1(Variable var)
::=
match var
case var as VARIABLE(__) then
     if instDims then 'multi_array<<%expTypeShort(var.ty)%>,<%listLength(instDims)%>> ' else expTypeFlag(var.ty, 6)

end varType1;

template varType2(Variable var)
::=
match var
case var as VARIABLE(__) then
     if instDims then 'multi_array_ref<<%expTypeShort(var.ty)%>,<%listLength(instDims)%>> ' else expTypeFlag(var.ty, 5)
end varType2;




template funStatement(Statement stmt, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates function statements."
::=
  match stmt
  case ALGORITHM(__) then
    (statementLst |> stmt =>
      algStatement(stmt, contextFunction, &varDecls /*BUFD*/,simCode)
    ;separator="\n")
  else
    "NOT IMPLEMENTED FUN STATEMENT"
end funStatement;
  
template init(SimCode simCode)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__))  then
   let () = System.tmpTickReset(0)
   let &varDecls = buffer "" /*BUFD*/
  
   let initFunctions = functionInitial(startValueEquations,varDecls,simCode)
   let initZeroCrossings = functionOnlyZeroCrossing(zeroCrossings,varDecls,simCode)
   let initEventHandling = eventHandlingInit(simCode)
   
   /*let initBoundParameters = boundParameters(parameterEquations,varDecls,simCode)*/
   let initALgloopSolvers = initAlgloopsolvers(odeEquations,algebraicEquations,whenClauses,parameterEquations,simCode)

   let initialequations  = functionInitialEquations(initialEquations,simCode)
   let initextvars = functionCallExternalObjectConstructors(extObjInfo,simCode)
  <<
   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initialize()
   {
   
      <%generateAlgloopsolvers( listAppend(allEquations,initialEquations),simCode)%>
      _simTime = 0.0;
 
    <%varDecls%>
    
     initializeAlgVars();
  initializeIntAlgVars();
  initializeBoolAlgVars();
  initializeAliasVars();
  initializeIntAliasVars();
  initializeBoolAliasVars();
  initializeParameterVars();
    initializeStateVars();
     initializeDerVars();
   <%initFunctions%>
     _event_handling.initialize(this,<%helpvarlength(simCode)%>);
    
    
   
    <%initEventHandling%>
     
   <%initextvars%>
   initEquations();
   
      <%initALgloopSolvers%>
    for(int i=0;i<_dimZeroFunc;i++)
    {
       getCondition(i);
    }
  //initialAnalyticJacobian();
  saveAll();
 
  <%functionInitDelay(delayedExps,simCode)%>
  
    }
  
   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initEquations()
   {
    <%initialequations%>
   }
   <%init2(simCode,modelInfo)%>
    >>
end init;



template init2(SimCode simCode,ModelInfo modelInfo)
::=
match modelInfo
case modelInfo as MODELINFO(vars=SIMVARS(__))  then

   let () = System.tmpTickReset(0)
   let &varDecls1 = buffer "" /*BUFD*/
   let &varDecls2 = buffer "" /*BUFD*/
   let &varDecls3 = buffer "" /*BUFD*/
   let &varDecls4 = buffer "" /*BUFD*/
   let &varDecls5 = buffer "" /*BUFD*/
   let &varDecls6 = buffer "" /*BUFD*/
   let &varDecls7 = buffer "" /*BUFD*/
   let &varDecls8 = buffer "" /*BUFD*/
   let &varDecls9 = buffer "" /*BUFD*/
   let init1  = initValst(varDecls1,vars.stateVars, simCode,contextOther)
   let init2  = initValst(varDecls2,vars.derivativeVars, simCode,contextOther)
   let init3  = initValst(varDecls3,vars.algVars, simCode,contextOther)
   let init4  = initValst(varDecls4,vars.intAlgVars, simCode,contextOther)
   let init5  =initValst(varDecls5,vars.boolAlgVars, simCode,contextOther)
   let init6  =initValst(varDecls6,vars.aliasVars, simCode,contextOther)
   let init7  =initValst(varDecls7,vars.intAliasVars, simCode,contextOther)
   let init8  =initValst(varDecls8,vars.boolAliasVars, simCode,contextOther)
   let init9  =initValst(varDecls9,vars.paramVars, simCode,contextOther)
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
   void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeIntAlgVars()
   {
     <%varDecls4%>
       <%init4%>
   }
    void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeBoolAlgVars()
   {
        <%varDecls5%>
       <%init5%>
   }
    void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeAliasVars()
   {
       <%varDecls6%>
       <%init6%> 
   }
     void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeIntAliasVars()
    {
       <%varDecls7%>
       <%init7%>
    }
    void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeBoolAliasVars()
    {
      <%varDecls8%>
       <%init8%>
    }
    
    void <%lastIdentOfPath(modelInfo.name)%>Initialize::initializeParameterVars()
    {
       <%varDecls9%>
       <%init9%>
    }  
   >>
end init2;


template functionCallExternalObjectConstructors(ExtObjInfo extObjInfo,SimCode simCode)
  "Generates function in simulation file."
::=
  match extObjInfo
  case EXTOBJINFO(__) then
    let &funDecls = buffer "" /*BUFD*/
    let &varDecls = buffer "" /*BUFD*/
    let ctorCalls = (vars |> var as SIMVAR(initialValue=SOME(exp)) =>
        let &preExp = buffer "" /*BUFD*/
        let arg = daeExp(exp, contextOther, &preExp, &varDecls,simCode)
        /* Restore the memory state after each object has been initialized. Then we can
         * initalize a really large number of external objects that play with strings :)
         */
        <<
        <%preExp%>
        <%cref(var.name)%> = <%arg%>;
        >>
      ;separator="\n")

    <<
  
      <%varDecls%>
     
     
      <%ctorCalls%>
      <%aliases |> (var1, var2) => '<%cref(var1)%> = <%cref(var2)%>;' ;separator="\n"%>
      
  
    >>
  end match
end functionCallExternalObjectConstructors;


template functionInitialEquations(list<SimEqSystem> initalEquations, SimCode simCode)
  "Generates function in simulation file."
::=
  
  let &varDecls = buffer "" /*BUFD*/
  let body = (initalEquations |> eq  =>
      equation_(eq, contextAlgloopInitialisation, &varDecls /*BUFD*/,simCode)
    ;separator="\n")  
  <<
    <%varDecls%>
  /*Initial equations*/
    <%body%>
   /*Initial equations end*/
   
 
  >>
end functionInitialEquations;

template initAlgloop(SimCode simCode,SimEqSystem eq)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)
  let &varDecls = buffer ""
  let &preExp = buffer ""
  let initalgvars = initAlgloopvars(preExp,varDecls,modelInfo,simCode)
  
  match eq
  case SES_NONLINEAR(__) then
  <<
  void <%modelname%>Algloop<%index%>::initialize()
  {

         <%initAlgloopEquation(eq,varDecls,simCode)%>
       AlgLoopDefaultImplementation::initialize();

    // Update the equations once before start of simulation
    evaluate(IContinuous::ALL);
   }
  >>
 case SES_LINEAR(__) then
   <<
     void <%modelname%>Algloop<%index%>::initialize()
     {

         <%initAlgloopEquation(eq,varDecls,simCode)%>
        // Update the equations once before start of simulation
        evaluate(IContinuous::ALL);
     }
   >>

end initAlgloop;


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
  >>
 case SES_LINEAR(__) then
   <<
     void <%modelname%>Algloop<%index%>::getSystemMatrix(double* A_matrix)
     {
          memcpy(A_matrix,__A.data(),_dimAEq*_dimAEq*sizeof(double));
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
  let initalgvars = initAlgloopvars(preExp,varDecls,modelInfo,simCode)

  match eq
  case SES_NONLINEAR(__)
  case SES_LINEAR(__) then
  <<
  void <%modelname%>Algloop<%index%>::getRHS(double* residuals)
    {
        if (isLinear())
        {
            for(size_t i=0; i<_dimAEq; ++i)
                residuals[i] = __b[i];
        }
        else
            AlgLoopDefaultImplementation::getRHS(residuals); 
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
        ublas::matrix<double> A=toMatrix(_dimAEq,_dimAEq,__A.data());
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
  let initalgvars = initAlgloopvars(preExp,varDecls,modelInfo,simCode)
 
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


template initAlgloopEquation(SimEqSystem eq, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates a non linear equation system."
::=
match eq
case SES_NONLINEAR(__) then
  let size = listLength(crefs)
  <<

   <%crefs |> name hasindex i0 =>
    let namestr = cref1(name,simCode,contextAlgloop)
    <<
    __xd[<%i0%>] = <%namestr%>;
     >>
  ;separator="\n"%>
   >>
 case SES_LINEAR(__)then
  let &varDecls = buffer "" /*BUFD*/
     let &preExp = buffer "" /*BUFD*/
 let Amatrix=
    (simJac |> (row, col, eq as SES_RESIDUAL(__)) =>
      let expPart = daeExp(eq.exp, contextAlgloop, &preExp /*BUFC*/,  &varDecls /*BUFD*/,simCode)
      '<%preExp%>__A[<%row%>][<%col%>]=<%expPart%>;'
  ;separator="\n")

 let bvector =  (beqs |> exp hasindex i0 =>

     let expPart = daeExp(exp, contextAlgloop, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
     '<%preExp%>__b[<%i0%>]=<%expPart%>;'
  ;separator="\n")

 <<
      <%varDecls%>
      <%Amatrix%>
      <%bvector%>
  >>

end initAlgloopEquation;






template giveAlgloopvars(SimEqSystem eq,SimCode simCode)
 "Generates a non linear equation system."
::=
match eq
case SES_NONLINEAR(__) then
  let size = listLength(crefs)
  <<

   <%crefs |> name hasindex i0 =>
     let namestr = cref1(name,simCode,contextAlgloop)
     <<
       vars[<%i0%>] = <%namestr%>;
     >>
     ;separator="\n"
   %>
  >>
 case SES_LINEAR(__) then
   <<
      <%vars |> SIMVAR(__) hasindex i0 => 'vars[<%i0%>] =<%cref1(name,simCode,contextAlgloop)%>;' ;separator="\n"%><%inlineVars(contextSimulationNonDiscrete,vars)%>
   >>

end giveAlgloopvars;




template writeAlgloopvars(list<list<SimEqSystem>> continousEquations,list<SimEqSystem> discreteEquations,list<SimWhenClause> whenClauses,list<SimEqSystem> parameterEquations,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (continousEquations |> eqs => (eqs |> eq =>
      writeAlgloopvars2(eq, contextOther, &varDecls /*BUFC*/,simCode))
    ;separator=" ")

  <<
  <%algloopsolver%>
  >>
end writeAlgloopvars;


template writeAlgloopvars2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode)
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
    let namestr = cref(name)
    <<
     <%namestr%> = algloopvars<%index%>[<%i0%>];
    >>
    ;separator="\n"%>

   >>
  case e as SES_LINEAR(__) then
    let size = listLength(vars)
    let algloopid = index
  <<
   double algloopvars<%algloopid%>[<%size%>];
   _algLoop<%index%>->getReal(algloopvars<%algloopid%>,NULL,NULL);

    <%vars |> SIMVAR(__) hasindex i0 => '<%cref1(name,simCode,contextAlgloop)%> = algloopvars<%algloopid%>[<%i0%>];' ;separator="\n"%>


   >>
 end writeAlgloopvars2;





template setAlgloopvars(SimEqSystem eq,SimCode simCode)
 "Generates a non linear equation system."
::=
match eq
case SES_NONLINEAR(__) then
  let size = listLength(crefs)
  <<

   <%crefs |> name hasindex i0 =>
    let namestr = cref1(name,simCode,contextAlgloop)
    <<
    <%namestr%>  = vars[<%i0%>];
    >>
   ;separator="\n"%>
  >>
  case SES_LINEAR(__) then
  <<

   <%vars |> SIMVAR(__) hasindex i0 => '<%cref1(name,simCode,contextAlgloop)%>=vars[<%i0%>];' ;separator="\n"%><%inlineVars(contextSimulationNonDiscrete,vars)%>

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
    fill_array(__A,0.0);
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
    ,__A(boost::extents[<%size%>][<%size%>],boost::fortran_storage_order())
   ,__b(boost::extents[<%size%>])
  >>

end alocateLinearSystem;

template Update(SimCode simCode)
::=
match simCode
case SIMCODE(__) then
  <<
  <%update(allEquations,whenClauses,simCode,contextOther)%>
  >>
end Update;
/*<%update(odeEquations,algebraicEquations,whenClauses,parameterEquations,simCode)%>*/


template writeoutput(SimCode simCode)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
   void <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeOutput(const IWriteOutput::OUTPUT command)
   {

    //Write head line
    if (command & IWriteOutput::HEAD_LINE)
    {
      vector<string> head;
      writeAlgVarsResultNames(head);
      writeIntAlgVarsResultNames(head);
      writeBoolAlgVarsResultNames(head);
      writeIntputVarsResultNames(head);
      writeOutputVarsResultNames(head);
      writeAliasVarsResultNames(head);
      writeIntAliasVarsResultNames(head);
      writeBoolAliasVarsResultNames(head);
      writeStateVarsResultNames(head);
      writeDerivativeVarsResultNames(head);
     
     
     
      _historyImpl->write(head);
    }
    //Write the current values
    else
    {
      HistoryImplType::value_type_v v(<%numAlgvars(modelInfo)%>+<%numInOutvars(modelInfo)%>+<%numAliasvars(modelInfo)%>+<%numStatevars(modelInfo)%>);
      HistoryImplType::value_type_dv v2(<%numDerivativevars(modelInfo)%>);
      <%writeoutput2(modelInfo,simCode)%>
      <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then
      <<
      HistoryImplType::value_type_r v3(<%numResidues(allEquations)%>);
      <%(allEquations |> eqs => (eqs |> eq => writeoutputAlgloopsolvers(eq,simCode));separator="\n")%>
      double residues [] = {<%(allEquations |> eqn => writeoutput3(eqn, simCode));separator=","%>};
      for(int i=0;i<<%numResidues(allEquations)%>;i++) v3(i) = residues[i];
      _historyImpl->write(v,v2,v3,_simTime);
      >>
    else
      <<
      _historyImpl->write(v,v2,_simTime);
      >>
    %>
    }
     saveAll();
   }
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

template writeoutput3(SimEqSystem eqn, SimCode simCode)
::=
  match eqn
  case SES_RESIDUAL(__) then
  <<
  >>
  case  SES_SIMPLE_ASSIGN(__) then
  <<
  <%cref1(cref,simCode,contextOther)%>
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
  case SES_MIXED(__) then writeoutput3(cont,simCode)
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

template generateHeaderInlcudeString(SimCode simCode)
 "Generates header part of simulation file."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), extObjInfo=EXTOBJINFO(__)) then
  <<
  #pragma once
  #define BOOST_EXTENSION_SYSTEM_DECL BOOST_EXTENSION_EXPORT_DECL
  #define BOOST_EXTENSION_EVENTHANDLING_DECL BOOST_EXTENSION_EXPORT_DECL
  #include "System/EventHandling.h"
  #include "System/SystemDefaultImplementation.h"
  #include "OMCpp<%fileNamePrefix%>Functions.h"
  #include "HistoryImpl.h"
  <%algloopfilesInclude(listAppend(allEquations,initialEquations),simCode)%>
  
  /*****************************************************************************
  *
  * Simulation code for <%lastIdentOfPath(modelInfo.name)%> generated by the OpenModelica Compiler.
  * System class <%lastIdentOfPath(modelInfo.name)%> implements the Interface IMixedSystem
  *
  *****************************************************************************/
   >>
end generateHeaderInlcudeString;



template generateAlgloopHeaderInlcudeString(SimCode simCode)
 "Generates header part of simulation file."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), extObjInfo=EXTOBJINFO(__)) then
  <<
  #pragma once
  #define BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL BOOST_EXTENSION_EXPORT_DECL
  #define BOOST_EXTENSION_EVENTHANDLING_DECL BOOST_EXTENSION_EXPORT_DECL
  #include "System/IMixedSystem.h"
  #include "System/AlgLoopDefaultImplementation.h"
  #include "System/EventHandling.h"
  #include "OMCpp<%fileNamePrefix%>Functions.h"
  class <%lastIdentOfPath(modelInfo.name)%>;
  >>
end generateAlgloopHeaderInlcudeString;

template generateClassDeclarationCode(SimCode simCode)
 "Generates class declarations."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
  class <%lastIdentOfPath(modelInfo.name)%>: public IContinuous, public IEvent,  public ITime, public ISystemProperties <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then ', public IReduceDAE'%>, public SystemDefaultImplementation
  {

   <%generatefriendAlgloops(listAppend(allEquations,initialEquations),simCode)%>

  public: 
      <%lastIdentOfPath(modelInfo.name)%>(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactor,boost::shared_ptr<ISimData>); 

      ~<%lastIdentOfPath(modelInfo.name)%>();

       <%generateMethodDeclarationCode(simCode)%>
     virtual  bool getCondition(unsigned int index);
  protected:
    //Methods:
    
     bool isConsistent();
    //Called to handle all  events occured at same time
    bool handleSystemEvents( bool* events);
     //Saves all variables before an event is handled, is needed for the pre, edge and change operator
    void saveAll();
    void getJacobian(SparseMatrix& matrix);
    
    
     //Variables:
     EventHandling _event_handling;

     <%MemberVariable(modelInfo)%>
     <%conditionvariable(zeroCrossings,simCode)%>
     Functions _functions;
  
  
     boost::shared_ptr<IAlgLoopSolverFactory>
        _algLoopSolverFactory;    ///< Factory that provides an appropriate solver
     <%generateAlgloopsolverVariables(listAppend(allEquations,initialEquations),simCode)%>
   
    boost::shared_ptr<ISimData> _simData;

   };
  >>
end generateClassDeclarationCode;
 /*
 <%modelname%>Algloop<%index%>(
                                       <%constructorParams%>
                                        double* z,double* zDot
                                       ,EventHandling& event_handling
                                      );
                                      */

template generateAlgloopClassDeclarationCode(SimCode simCode,SimEqSystem eq)
 "Generates class declarations."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let modelname = lastIdentOfPath(modelInfo.name)
  let algvars = MemberVariableAlgloop(modelInfo)
  let constructorParams = ConstructorParamAlgloop(modelInfo)
  match eq
      case SES_LINEAR(__)
    case SES_NONLINEAR(__) then
  <<
  class <%modelname%>Algloop<%index%>: public IAlgLoop, public AlgLoopDefaultImplementation
  {
  public:
      <%modelname%>Algloop<%index%>(    <%modelname%>* system
                                        ,double* z,double* zDot, bool* conditions
                                       ,EventHandling& event_handling
                                      );
      ~<%modelname%>Algloop<%index%>();

       <%generateAlgloopMethodDeclarationCode(simCode)%>

  private:
    Functions _functions;
    //states
    double* __z;
    //state derivatives
    double* __zDot;
    // A matrix
    boost::multi_array<double,2> __A;
    //b vector
    boost::multi_array<double,1> __b;
    bool* _conditions;

    EventHandling& _event_handling;

     <%modelname%>* _system;
   };
  >>
end generateAlgloopClassDeclarationCode;
/*
  <%algvars%>
  */
template DefaultImplementationCode(SimCode simCode)

::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
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
    double residues [] = {<%(allEquations |> eqn => writeoutput3(eqn, simCode));separator=","%>};
    for(int i=0;i<<%numResidues(allEquations)%>;i++) *(f+i) = residues[i];
}
else SystemDefaultImplementation::getRHS(f);
>>
else
<<
    SystemDefaultImplementation::getRHS(f);
>>%>
}




bool <%lastIdentOfPath(modelInfo.name)%>::isStepEvent()
{
    throw std::runtime_error("isAutonomous is not yet implemented");    
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


template AlgloopDefaultImplementationCode(SimCode simCode,SimEqSystem eq)

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
    <%giveAlgloopvars(eq,simCode)%>
};

/// Set variables with given index to the system
void  <%modelname%>Algloop<%index%>::setReal(const double* vars)
{

    //workaround until names of algloop vars are replaced in simcode  

    <%setAlgloopvars(eq,simCode)%>
    AlgLoopDefaultImplementation::setReal(vars);
};




/// Set stream for output
void  <%modelname%>Algloop<%index%>::setOutput(ostream* outputStream)
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
     //Releases the Modelica System
    virtual void destroy();
    //provide number (dimension) of variables according to the index
    virtual int getDimContinuousStates() const;
      /// Provide number (dimension) of boolean variables
    virtual int getDimBoolean() const;
    /// Provide number (dimension) of integer variables
    virtual int getDimInteger() const;
    /// Provide number (dimension) of real variables
    virtual int getDimReal() const ;
    /// Provide number (dimension) of string variables
    virtual int getDimString() const ;
    //Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
    virtual int getDimRHS()const;
      //Resets all time events
   
   
    //Provide variables with given index to the system
    virtual void getContinuousStates(double* z);
    //Set variables with given index to the system
    virtual void setContinuousStates(const double* z);
    //Update transfer behavior of the system of equations according to command given by solver
    virtual bool evaluate(const UPDATETYPE command =IContinuous::UNDEF_UPDATE);

    //Provide the right hand side (according to the index)
    virtual void getRHS(double* f);
   
   
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
    
    virtual void saveDiscreteVars();
    // M is regular
    virtual bool isODE();
    // M is singular
    virtual bool isAlgebraic();
  
    
    virtual int getDimTimeEvent() const;
    //gibt die Time events (Startzeit und Frequenz) zurück
    virtual void getTimeEvent(time_event_type& time_events);
    //Wird vom Solver zur Behandlung der Time events aufgerufen (wenn zero_sign[i] = 0  kein time event,zero_sign[i] = n  Anzahl von vorgekommen time events )
    virtual void handleTimeEvent(int* time_events);
    /// Set current integration time
    virtual void setTime(const double& time);
      
    // System is able to provide the Jacobian symbolically
    virtual bool provideSymbolicJacobian();

   virtual void stepCompleted(double time);
    <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then
    <<


    // Returns labels for a labeled DAE
    virtual label_list_type getLabels();
    //Sets all algebraic and state varibales for current time
    virtual void setVariables(const ublas::vector<double>& variables, const ublas::vector<double>& variables2);

    >>%>
    
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
    /// Provide variables with given index to the system
    virtual void getReal(double* vars)    ;
    /// Set variables with given index to the system
    virtual void setReal(const double* vars)    ;
    /// Update transfer behavior of the system of equations according to command given by solver
    virtual void evaluate(const  IContinuous::UPDATETYPE command =IContinuous::UNDEF_UPDATE);
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
    virtual bool isLinear();
    virtual bool isConsistent();
    /// Set stream for output
    virtual void setOutput(ostream* outputStream)     ;

>>
//void writeOutput(HistoryImplType::value_type_v& v ,vector<string>& head ,const IMixedSystem::OUTPUT command  = IMixedSystem::UNDEF_OUTPUT);
end generateAlgloopMethodDeclarationCode;

template MemberVariable(ModelInfo modelInfo)
 "Define membervariable in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  <%vars.algVars |> var =>
    MemberVariableDefine2(var, "algebraics")
  ;separator="\n"%>
  <%vars.paramVars |> var =>
    MemberVariableDefine2(var, "parameters")
  ;separator="\n"%>
   <%vars.aliasVars |> var =>
    MemberVariableDefine2(var, "aliasVars")
  ;separator="\n"%>
  <%vars.intAlgVars |> var =>
    MemberVariableDefine("int", var, "intVariables.algebraics")
  ;separator="\n"%>
  <%vars.intParamVars |> var =>
    MemberVariableDefine("int", var, "intVariables.parameters")
  ;separator="\n"%>
   <%vars.intAliasVars |> var =>
    MemberVariableDefine("int", var, "intVariables.AliasVars")
  ;separator="\n"%>
  <%vars.boolAlgVars |> var =>
    MemberVariableDefine("bool",var, "boolVariables.algebraics")
  ;separator="\n"%>
  <%vars.boolParamVars |> var =>
    MemberVariableDefine("bool",var, "boolVariables.parameters")
  ;separator="\n"%>
   <%vars.boolAliasVars |> var =>
    MemberVariableDefine("bool ",var, "boolVariables.AliasVars")
  ;separator="\n"%>
  <%vars.stringAlgVars |> var =>
    MemberVariableDefine("string",var, "stringVariables.algebraics")
  ;separator="\n"%>
  <%vars.stringParamVars |> var =>
    MemberVariableDefine("string",var, "stringVariables.parameters")
  ;separator="\n"%>
  <%vars.stringAliasVars |> var =>
    MemberVariableDefine("string",var, "stringVariables.AliasVars")
  ;separator="\n"%>
   <%vars.constVars |> var =>
    MemberVariableDefine2(var, "constvariables")
  ;separator="\n"%>
   <%vars.intConstVars |> var =>
    MemberVariableDefine("const int", var, "intConstvariables")
  ;separator="\n"%>
   <%vars.boolConstVars |> var =>
    MemberVariableDefine("const bool", var, "boolConstvariables")
  ;separator="\n"%>
   <%vars.stringConstVars |> var =>
    MemberVariableDefine("const string",var, "stringConstvariables")
  ;separator="\n"%>
   <%vars.extObjVars |> var =>
    MemberVariableDefine("void*",var, "extObjVars")
  ;separator="\n"%>
  
  >>
end MemberVariable;

template VariableAliasDefinition(SimVar simVar)
"make a #define to the state vector"
::=
  match simVar
    case SIMVAR(varKind=STATE(__)) then
    <<
    #define <%cref(name)%> __z[<%index%>];
    >>
    case SIMVAR(varKind=STATE_DER(__)) then
    <<
    #define <%cref(name)%> __zDot[<%index%>];
    >>
  end match
end VariableAliasDefinition;

template MemberVariableAlgloop(ModelInfo modelInfo)
 "Define membervariable in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
<<  <%vars.algVars |> var =>
    MemberVariableDefineReference2(var, "algebraics","")
  ;separator=";\n"%><%if vars.algVars then ";" else ""%>
   <%vars.paramVars |> var =>
    MemberVariableDefineReference2(var, "parameters","")
  ;separator=";\n"%> <%if vars.paramVars then ";" else ""%>
   <%vars.aliasVars |> var =>
    MemberVariableDefineReference2(var, "aliasVars","")
  ;separator=";\n"%><%if vars.aliasVars then ";" else ""%>
  <%vars.intAlgVars |> var =>
    MemberVariableDefineReference("int", var, "intVariables.algebraics","")
  ;separator=";\n"%><%if vars.intAlgVars then ";" else ""%>
  <%vars.intParamVars |> var =>
    MemberVariableDefineReference("int", var, "intVariables.parameters","")
  ;separator=";\n"%><%if vars.intParamVars then ";" else " "%>
   <%vars.intAliasVars |> var =>
   MemberVariableDefineReference("int", var, "intVariables.AliasVars","")
  ;separator=";\n"%><%if vars.intAliasVars then ";" else " "%>
  <%vars.boolAlgVars |> var =>
    MemberVariableDefineReference("bool",var, "boolVariables.algebraics","")
  ;separator=";\n"%><%if vars.boolAlgVars then ";" else ""%>
  <%vars.boolParamVars |> var =>
    MemberVariableDefineReference("bool",var, "boolVariables.parameters","")
  ;separator=";\n"%><%if vars.boolParamVars then ";" else " "%>
   <%vars.boolAliasVars |> var =>
     MemberVariableDefineReference("bool ",var, "boolVariables.AliasVars","")
  ;separator=";\n"%><%if vars.boolAliasVars then ";" else ""%>
  <%vars.stringAlgVars |> var =>
    MemberVariableDefineReference("string",var, "stringVariables.algebraics","")
  ;separator=";\n"%><%if vars.stringAlgVars then ";" else ""%>
  <%vars.stringParamVars |> var =>
    MemberVariableDefineReference("string",var, "stringVariables.parameters","")
  ;separator=";\n"%><%if vars.stringParamVars then ";" else " "%>
  <%vars.stringAliasVars |> var =>
    MemberVariableDefineReference("string",var, "stringVariables.AliasVars","")
  ;separator=";\n"%><%if vars.stringAliasVars then ";" else ""%>
   <%vars.constVars |> var =>
    MemberVariableDefineReference2(var, "constvariables","")
  ;separator=";\n"%><%if vars.constVars then ";" else " "%>
   <%vars.intConstVars |> var =>
    MemberVariableDefineReference("const int", var, "intConstvariables","")
  ;separator=";\n"%><%if vars.intConstVars then ";" else ""%>
   <%vars.boolConstVars |> var =>
    MemberVariableDefineReference("const bool", var, "boolConstvariables","")
  ;separator=";\n"%><%if vars.boolConstVars then ";" else ""%>
   <%vars.stringConstVars |> var =>
    MemberVariableDefineReference("const string",var, "stringConstvariables","")
  ;separator=";\n"%><%if vars.stringConstVars then ";" else ""%>
  >>
end MemberVariableAlgloop;



template ConstructorParamAlgloop(ModelInfo modelInfo)
 "Define membervariable in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  <%vars.algVars |> var =>
    MemberVariableDefineReference2(var, "algebraics","_")
  ;separator=","%><%if vars.algVars then "," else ""%>
  <%vars.paramVars |> var =>
    MemberVariableDefineReference2(var, "parameters","_")
  ;separator=","%><%if vars.paramVars then "," else ""%>
  <%vars.aliasVars |> var =>
    MemberVariableDefineReference2(var, "aliasVars","_")
  ;separator=","%><%if vars.aliasVars then "," else ""%>
   <%vars.intAlgVars |> var =>
    MemberVariableDefineReference("int", var, "intVariables.algebraics","_")
  ;separator=","%> <%if vars.intAlgVars then "," else ""%>
  <%vars.intParamVars |> var =>
    MemberVariableDefineReference("int", var, "intVariables.parameters","_")
  ;separator=","%> <%if vars.intParamVars then "," else ""%>
  <%vars.intAliasVars |> var =>
    MemberVariableDefineReference("int", var, "intVariables.AliasVars","_")
  ;separator=","%><%if vars.intAliasVars then "," else ""%>
  <%vars.boolAlgVars |> var =>
    MemberVariableDefineReference("bool",var, "boolVariables.algebraics","_")
  ;separator=","%><%if vars.boolAlgVars then "," else ""%>
  <%vars.boolParamVars |> var =>
    MemberVariableDefineReference("bool",var, "boolVariables.parameters","_")
  ;separator=","%><%if vars.boolParamVars then "," else ""%>
   <%vars.boolAliasVars |> var =>
    MemberVariableDefineReference("bool ",var, "boolVariables.AliasVars","_")
  ;separator=","%><%if vars.boolAliasVars then "," else ""%>
  <%vars.stringAlgVars |> var =>
    MemberVariableDefineReference("string",var, "stringVariables.algebraics","_")
  ;separator=","%><%if vars.stringAlgVars then "," else "" %>
  <%vars.stringParamVars |> var =>
    MemberVariableDefineReference("string",var, "stringVariables.parameters","_")
  ;separator=","%><%if vars.stringParamVars then "," else ""%>
  <%vars.stringAliasVars |> var =>
    MemberVariableDefineReference("string",var, "stringVariables.AliasVars","_")
  ;separator=","%><%if vars.stringAliasVars then "," else ""%>
  <%vars.constVars |> var =>
    MemberVariableDefineReference2(var, "constvariables","_")
  ;separator=","%><%if vars.constVars then "," else ""%>
  <%vars.intConstVars |> var =>
    MemberVariableDefineReference("const int", var, "intConstvariables","_")
  ;separator=","%><%if vars.intConstVars then "," else ""%>
  <%vars.boolConstVars |> var =>
    MemberVariableDefineReference("const bool", var, "boolConstvariables","_")
  ;separator=","%> <%if vars.boolConstVars then "," else "" %>
  <%vars.stringConstVars |> var =>
    MemberVariableDefineReference("const string",var, "stringConstvariables","_")
  ;separator=","%><%if vars.stringConstVars then "," else ""%>
  >>
end ConstructorParamAlgloop;

template CallAlgloopParams(ModelInfo modelInfo)
 "Define membervariable in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
 << <%vars.algVars |> var =>
    CallAlgloopParam(var)
  ;separator=","%> <%if vars.algVars then "," else ""%>
  <%vars.paramVars |> var =>
    CallAlgloopParam(var)
  ;separator=","%> <%if vars.paramVars then "," else ""%>
  <%vars.aliasVars |> var =>
    CallAlgloopParam(var)
  ;separator=","%><%if vars.aliasVars then "," else ""%>
  <%vars.intAlgVars |> var =>
    CallAlgloopParam(var)
  ;separator=","%><%if vars.intAlgVars then "," else ""%>
  <%vars.intParamVars |> var =>
    CallAlgloopParam(var)
  ;separator=","%><%if vars.intParamVars then "," else ""%>
  <%vars.intAliasVars |> var =>
    CallAlgloopParam( var)
  ;separator=","%><%if vars.intAliasVars then "," else ""%>
  <%vars.boolAlgVars |> var =>
    CallAlgloopParam(var)
  ;separator=","%><%if vars.boolAlgVars then "," else ""%>
  <%vars.boolParamVars |> var =>
    CallAlgloopParam(var)
  ;separator=","%><%if vars.boolParamVars then "," else ""%>
  <%vars.boolAliasVars |> var =>
    CallAlgloopParam(var)
  ;separator=","%> <%if vars.boolAliasVars then "," else ""%>
  <%vars.stringAlgVars |> var =>
    CallAlgloopParam(var)
  ;separator=","%><%if vars.stringAlgVars then "," else "" %>
  <%vars.stringParamVars |> var =>
    CallAlgloopParam(var)
  ;separator=","%><%if vars.stringParamVars then "," else ""%>
  <%vars.stringAliasVars |> var =>
    CallAlgloopParam(var)
  ;separator=","%><%if vars.stringAliasVars then "," else ""%>
  <%vars.constVars |> var =>
    CallAlgloopParam(var)
  ;separator=","%><%if vars.constVars then "," else ""%>
  <%vars.intConstVars |> var =>
    CallAlgloopParam(var)
  ;separator=","%><%if vars.intConstVars then "," else ""%>
  <%vars.boolConstVars |> var =>
    CallAlgloopParam(var)
  ;separator=","%><%if vars.boolConstVars then "," else "" %>
  <%vars.stringConstVars |> var =>
    CallAlgloopParam(var)
  ;separator=","%> <%if vars.stringConstVars then "," else "" %>>>
end CallAlgloopParams;



template InitAlgloopParams(ModelInfo modelInfo,Text& arrayInit)
 "Define membervariable in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then

 <<
   /* vars.algVars */
   <%vars.algVars |> var =>
    InitAlgloopParam(var, "algebraics",arrayInit)
  ;separator=","%> <%if vars.algVars then "," else ""%>
   /* vars.paramVars */
  <%vars.paramVars |> var =>
    InitAlgloopParam(var, "parameters",arrayInit)
  ;separator=","%><%if vars.paramVars then "," else ""%>
   /* vars.aliasVars */
   <%vars.aliasVars |> var =>
    InitAlgloopParam(var, "aliasVars",arrayInit)
  ;separator=","%><%if vars.aliasVars then "," else ""%>
   /* vars.intAlgVars */
  <%vars.intAlgVars |> var =>
    InitAlgloopParam( var, "intVariables.algebraics",arrayInit)
  ;separator=","%> <%if vars.intAlgVars then "," else ""%>
   /* vars.intParamVars */
  <%vars.intParamVars |> var =>
    InitAlgloopParam( var, "intVariables.parameters",arrayInit)
  ;separator=","%><%if vars.intParamVars then "," else ""%>
   /* vars.intAliasVars */
  <%vars.intAliasVars |> var =>
    InitAlgloopParam( var, "intVariables.AliasVars",arrayInit)
  ;separator=","%><%if vars.intAliasVars then "," else ""%>
   /* vars.boolAlgVars */
  <%vars.boolAlgVars |> var =>
    InitAlgloopParam(var, "boolVariables.algebraics",arrayInit)
  ;separator=","%><%if vars.boolAlgVars then "," else ""%>
   /* vars.boolParamVars */
  <%vars.boolParamVars |> var =>
    InitAlgloopParam(var, "boolVariables.parameters",arrayInit)
  ;separator=","%> <%if vars.boolParamVars then "," else ""%>
   /* vars.boolAliasVars */
  <%vars.boolAliasVars |> var =>
    InitAlgloopParam(var, "boolVariables.AliasVars",arrayInit)
  ;separator=","%><%if vars.boolAliasVars then "," else ""%>
   /* vars.stringAlgVars */
   <%if vars.stringAlgVars then "," else ""%>
  <%vars.stringAlgVars |> var =>
    InitAlgloopParam(var, "stringVariables.algebraics",arrayInit)
  ;separator=","%><%if vars.stringAlgVars then "," else "" %>
   /* vars.stringParamVars */
   <%vars.stringParamVars |> var =>
    InitAlgloopParam(var, "stringVariables.parameters",arrayInit)
  ;separator=","%><%if vars.stringParamVars then "," else "" %>
   /* vars.stringAliasVars */
  <%vars.stringAliasVars |> var =>
    InitAlgloopParam(var, "stringVariables.AliasVars",arrayInit)
  ;separator=","%><%if vars.stringAliasVars then "," else "" %>
   /* vars.constVars */
  <%vars.constVars |> var =>
    InitAlgloopParam(var, "constvariables",arrayInit)
  ;separator=","%><%if vars.constVars then "," else ""%>
   /* vars.intConstVars */
  <%vars.intConstVars |> var =>
    InitAlgloopParam( var, "intConstvariables",arrayInit)
  ;separator=","%> <%if vars.intConstVars then "," else ""%>
   /* vars.boolConstVars */
  <%vars.boolConstVars |> var =>
    InitAlgloopParam( var, "boolConstvariables",arrayInit)
  ;separator=","%><%if vars.boolConstVars then "," else ""%>
   /* vars.stringConstVars */
   <%vars.stringConstVars |> var =>
    InitAlgloopParam(var, "stringConstvariables",arrayInit)
  ;separator=","%><%if vars.stringConstVars then "," else ""%> >>
 end InitAlgloopParams;

template MemberVariableDefine(String type,SimVar simVar, String arrayName)
::=
match simVar
      
     case SIMVAR(numArrayElement={},arrayCref=NONE(),name=CREF_IDENT(subscriptLst=_::_)) then ''
        
    case SIMVAR(numArrayElement={},arrayCref=NONE()) then
      <<
      <%type%> <%cref(name)%>; 
      >>
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(_),numArrayElement=num) 
    then
      let &dims = buffer "" /*BUFD*/
      let arrayName = arraycref2(name,dims)
      <<
      multi_array<<%variableType(type_)%>,<%dims%>>  <%arrayName%>;
      >>
    case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(_),numArrayElement=num) then
      let &dims = buffer "" /*BUFD*/
      let arrayName = arraycref2(name,dims)
      <<
      multi_array<<%variableType(type_)%>,<%dims%>> <%arrayName%>; 
      >>
    case SIMVAR(numArrayElement=_::_) then
      let& dims = buffer "" /*BUFD*/
      let varName = arraycref2(name,dims)
      let varType = variableType(type_)
      match dims
        case "0" then  '<%varType%> <%varName%>;'
        else ''
end MemberVariableDefine;

template MemberVariableDefineReference(String type,SimVar simVar, String arrayName,String pre)
::=
match simVar
      
       case SIMVAR(numArrayElement={},arrayCref=NONE(),name=CREF_IDENT(subscriptLst=_::_)) then ''
     
      case SIMVAR(numArrayElement={}) then
      <<
      <%type%>& <%pre%><%cref(name)%>
      >>
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(_),numArrayElement=num) then
      <<
      multi_array<<%variableType(type_)%>,<%listLength(num)%>>& <%pre%><%arraycref(name)%>
      >>
     case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(_),numArrayElement=num) then
      <<
      multi_array<<%variableType(type_)%>,<%listLength(num)%>>& <%pre%><%arraycref(name)%>
      >>
       case SIMVAR(numArrayElement=_::_) then
      let& dims = buffer "" /*BUFD*/
      let varName = arraycref2(name,dims)
      let varType = variableType(type_)
      match dims case "0" then  ''
end MemberVariableDefineReference;


template MemberVariableDefine2(SimVar simVar, String arrayName)
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
      <%variableType(type_)%> <%cref(name)%>;
      >>
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(_),numArrayElement=num)
     then
      let &dims = buffer "" /*BUFD*/
      let arrayName = arraycref2(name,dims)
      <<
      multi_array<<%variableType(type_)%>,<%dims%>>  <%arrayName%>;
      >>
    case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(_),numArrayElement=num) then
      let &dims = buffer "" /*BUFD*/
      let arrayName = arraycref2(name,dims)
      <<
      multi_array<<%variableType(type_)%>,<%dims%>> <%arrayName%>; 
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


template InitAlgloopParam(SimVar simVar, String arrayName,Text& arrayInit)
::=
match simVar
      case SIMVAR(numArrayElement={}) then
      <<
      <%cref(name)%>(_<%cref(name)%>)
      >>
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(_),numArrayElement=num) then
      //let &arrayInit+= ',<%arraycref(name)%>=_<%arraycref(name)%>'
      '<%arraycref(name)%>(_<%arraycref(name)%>)'
    case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(_),numArrayElement=num) then
      //let &arrayInit+= ' ,<%arraycref(name)%>= _<%arraycref(name)%>'
      '<%arraycref(name)%>( _<%arraycref(name)%>)'
    /*special case for varibales that marked as array but are not arrays */
      case SIMVAR(numArrayElement=_::_) then
      let& dims = buffer "" /*BUFD*/
      let varName = arraycref2(name,dims)
      match dims case "0" then  '<%varName%>(_<%varName%>)'
end InitAlgloopParam;

template CallAlgloopParam(SimVar simVar)
::=
match simVar
      case SIMVAR(numArrayElement={}) then
      <<
      <%cref(name)%>
      >>
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(_),numArrayElement=num) then
      //let &arrayInit+= ',<%arraycref(name)%>=_<%arraycref(name)%>'
      '<%arraycref(name)%>'
    case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(_),numArrayElement=num) then
      //let &arrayInit+= ' ,<%arraycref(name)%>= _<%arraycref(name)%>'
      '<%arraycref(name)%>'
    /*special case for varibales that marked as array but are not arrays */
    case SIMVAR(numArrayElement=_::_) then
      let& dims = buffer "" /*BUFD*/
      let varName = arraycref2(name,dims)
      match dims case "0" then  '<%varName%>'


end CallAlgloopParam;

template MemberVariableDefineReference2(SimVar simVar, String arrayName,String pre)
::=
match simVar
      case SIMVAR(numArrayElement={}) then
      <<
      <%variableType(type_)%>& <%pre%><%cref(name)%>
      >>
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(_),numArrayElement=num) then
      <<
      multi_array<<%variableType(type_)%>,<%listLength(num)%>>& <%pre%><%arraycref(name)%>
      >>
    case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(_),numArrayElement=num) then
      <<
      multi_array<<%variableType(type_)%>,<%listLength(num)%>>& <%pre%><%arraycref(name)%>
      >>
    /*special case for varibales that marked as array but are not arrays */
    case SIMVAR(numArrayElement=_::_) then
      let& dims = buffer "" /*BUFD*/
      let varName = arraycref2(name,dims)
      let varType = variableType(type_)
      match dims case "0" then  ''
end MemberVariableDefineReference2;


template arrayConstruct(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(vars = vars as SIMVARS(__))
  then
  <<
  <%arrayConstruct1(vars.algVars)%>
  <%arrayConstruct1(vars.intAlgVars)%>
  <%arrayConstruct1(vars.boolAlgVars)%>
  <%arrayConstruct1(vars.stringAlgVars)%>
  <%arrayConstruct1(vars.paramVars)%>
  <%arrayConstruct1(vars.intParamVars)%>
  <%arrayConstruct1(vars.boolParamVars)%>
  <%arrayConstruct1(vars.stringParamVars)%>
  <%arrayConstruct1(vars.aliasVars)%>
  <%arrayConstruct1(vars.intAliasVars)%>
  <%arrayConstruct1(vars.boolAliasVars)%>
  <%arrayConstruct1(vars.stringAliasVars)%>
  <%arrayConstruct1(vars.constVars)%>
  <%arrayConstruct1(vars.intConstVars)%>
  <%arrayConstruct1(vars.boolConstVars)%>
  <%arrayConstruct1(vars.stringConstVars)%>
  >>
end arrayConstruct;

template arrayConstruct1(list<SimVar> varsLst) ::=
  varsLst |> v as SIMVAR(arrayCref=SOME(_),numArrayElement=_::_) =>
  <<
  ,<%arraycref(name)%>(boost::extents<%boostextentDims(name,v.numArrayElement)%>)
  >>
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
end variableType;

template lastIdentOfPath(Path modelName) ::=
  match modelName
  case QUALIFIED(__) then lastIdentOfPath(path)
  case IDENT(__)     then name
  case FULLYQUALIFIED(__) then lastIdentOfPath(path)
end lastIdentOfPath;

template cref(ComponentRef cr)
 "Generates C equivalent name for component reference."
::=
  match cr
  case CREF_IDENT(ident = "time") then "_simTime"
  case WILD(__) then ''
  else "_"+crefToCStr(cr)
end cref;

template localcref(ComponentRef cr)
 "Generates C equivalent name for component reference."
::=
  match cr
  case CREF_IDENT(ident = "time") then "_simTime"
  case WILD(__) then ''
  else crefToCStr(cr)
end localcref;

template cref2(ComponentRef cr)
 "Generates C equivalent name for component reference."
::=
  match cr
  case CREF_IDENT(ident = "xloc") then '<%crefStr(cr)%>'
  case CREF_IDENT(ident = "time") then "time"
  case WILD(__) then ''
  else "_"+crefToCStr(cr)
end cref2;

template crefToCStr(ComponentRef cr)
 "Helper function to cref."
::=
  match cr
  case CREF_IDENT(__) then '<%ident%><%subscriptsToCStr(subscriptLst)%>'
  case CREF_QUAL(__) then '<%ident%><%subscriptsToCStrForArray(subscriptLst)%>_P_<%crefToCStr(componentRef)%>'
  case WILD(__) then ''
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStr;

template subscriptsToCStr(list<Subscript> subscripts)
::=
  if subscripts then
    '[<%subscripts |> s => subscriptToCStr(s) ;separator="]["%>]'
end subscriptsToCStr;

template subscriptToCStr(Subscript subscript)
::=
  match subscript
  case INDEX(exp=ICONST(integer=i)) then i
  case SLICE(exp=ICONST(integer=i)) then i
  case WHOLEDIM(__) then "WHOLEDIM"
  else "UNKNOWN_SUBSCRIPT"
end subscriptToCStr;

template arraycref(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(ident = "xloc") then crefStr(cr)
  case CREF_IDENT(ident = "time") then "time"
  case WILD(__) then ''
  else "_"+crefToCStr1(cr)
end arraycref;


template arraycref2(ComponentRef cr, Text& dims)
::=
  match cr
  case CREF_IDENT(ident = "xloc") then crefStr(cr)
  case CREF_IDENT(ident = "time") then "time"
  case WILD(__) then ''
  else "_"+crefToCStrForArray(cr,dims)
end arraycref2;    
/*
template boostextentDims(ComponentRef cr, list<String> arraydims)
::=
   match cr
   
case CREF_IDENT(subscriptLst={}) then
    '<%ident%>_NO_SUBS'
  case CREF_IDENT(__) then
   '[<%arraydims;separator="]["%>]'
   //subscriptsToCStr(subscriptLst)
  case CREF_QUAL(componentRef=c) then
    match arraydims
      case val::dims
        then boostextentDims(c,dims)
    end match
  else "CREF_NOT_IDENT_OR_QUAL"
end boostextentDims;
*/

template boostextentDims(ComponentRef cr, list<String> arraydims)
::=
    match cr
case CREF_IDENT(subscriptLst={}) then
  '<%ident%>_NO_SUBS'
 //subscriptsToCStr(subscriptLst)
  case CREF_IDENT(subscriptLst=dims) then
  //    '_<%ident%>_INVALID_<%listLength(dims)%>_<%listLength(arraydims)%>'
    '[<%List.lastN(arraydims,listLength(dims));separator="]["%>]'
    //subscriptsToCStr(subscriptLst)
  case CREF_QUAL(componentRef=c) then
    boostextentDims(c,arraydims)
  else "CREF_NOT_IDENT_OR_QUAL"
end boostextentDims;

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


template crefToCStr1(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(__) then '<%ident%>'
 case CREF_QUAL(__) then               '<%ident%><%subscriptsToCStrForArray(subscriptLst)%>_P_<%crefToCStr1(componentRef)%>'

  case WILD(__) then ' '
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStr1;

template subscriptsToCStrForArray(list<Subscript> subscripts)
::=
  if subscripts then
    '<%subscripts |> s => subscriptToCStr(s) ;separator="$c"%>'
end subscriptsToCStrForArray;

template crefStr(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(ident = "xloc") then '__xd<%subscriptsStr(subscriptLst)%>'
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
    '[<%subscripts |> s => subscriptStr(s) ;separator=","%>]'
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

template simulationInitFile(SimCode simCode)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__), vars = vars as SIMVARS(__)))
  then
  <<
  <%arrayConstruct(modelInfo)%>
  <%initconstVals(vars.constVars,simCode)%>
  <%initconstVals(vars.intConstVars,simCode)%>
  <%initconstVals(vars.boolConstVars,simCode)%>
  <%initconstVals(vars.stringConstVars,simCode)%>
  <%initconstVals(vars.paramVars,simCode)%>
  <%initconstVals(vars.intParamVars,simCode)%>
  <%initconstVals(vars.boolParamVars,simCode)%>
  <%initconstVals(vars.stringParamVars,simCode)%>
  >>
end simulationInitFile;

template initconstVals(list<SimVar> varsLst,SimCode simCode) ::=
  varsLst |> (var as SIMVAR(__)) =>
  initconstValue(var,simCode)
  ;separator="\n"
end initconstVals;

template initconstValue(SimVar var,SimCode simCode) ::=
 match var
  case SIMVAR(numArrayElement=_::_) then ''
  case SIMVAR(type_=type) then ',<%cref(name)%>
    <%match initialValue
    case SOME(v) then initconstValue2(v,simCode)
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

template initconstValue2(Exp initialValue,SimCode simCode)
::=
  match initialValue
    case v then
      let &preExp = buffer "" //dummy ... the value is always a constant
      let &varDecls = buffer ""
      match daeExp(v, contextOther, &preExp, &varDecls,simCode)
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


template initializeArrayElements(SimCode simCode)
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__), vars = vars as SIMVARS(__)))
  then
  <<
  <%initValsArray(vars.constVars,simCode)%>
  <%initValsArray(vars.intConstVars,simCode)%>
  <%initValsArray(vars.boolConstVars,simCode)%>
  <%initValsArray(vars.stringConstVars,simCode)%>
  <%initValsArray(vars.paramVars,simCode)%>
  <%initValsArray(vars.intParamVars,simCode)%>
  <%initValsArray(vars.boolParamVars,simCode)%>
  <%initValsArray(vars.stringParamVars,simCode)%>
  >>
end initializeArrayElements;

template initValsArray(list<SimVar> varsLst,SimCode simCode) ::=
  varsLst |> SIMVAR(numArrayElement=_::_,initialValue=SOME(v)) =>
  <<
  <%cref(name)%> = <%initVal(v)%>;
  >>
  ;separator="\n"
end initValsArray;

template arrayInit(SimCode simCode)
 "Generates the contents of the makefile for the simulation case."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__), vars = vars as SIMVARS(__)))
  then
  <<
  <%initVals1(vars.paramVars,simCode)%>
  <%initVals1(vars.intParamVars,simCode)%>
  <%initVals1(vars.boolParamVars,simCode)%>
  <%initVals1(vars.stringParamVars,simCode)%>
  <%initVals1(vars.constVars,simCode)%>
  <%initVals1(vars.intConstVars,simCode)%>
  <%initVals1(vars.boolConstVars,simCode)%>
  <%initVals1(vars.stringConstVars,simCode)%>
  >>
end arrayInit;

template initVals1(list<SimVar> varsLst, SimCode simCode) ::=
  varsLst |> (var as SIMVAR(__)) =>
  initVals2(var,simCode)
  ;separator="\n"
end initVals1;

template initVals2(SimVar var, SimCode simCode) ::=
  match var
  case SIMVAR(numArrayElement = {}) then ''
  case SIMVAR(__) then '<%cref(name)%>=<%match initialValue
    case SOME(v) then initVal(v)
      else "0"
    %>;'
end initVals2;


template arrayReindex(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(vars = vars as SIMVARS(__))
  then
  <<
  <%arrayReindex1(vars.algVars)%>
  <%arrayReindex1(vars.intAlgVars)%>
  <%arrayReindex1(vars.boolAlgVars)%>
  <%arrayReindex1(vars.stringAlgVars)%>
  <%arrayReindex1(vars.paramVars)%>
  <%arrayReindex1(vars.intParamVars)%>
  <%arrayReindex1(vars.boolParamVars)%>
  <%arrayReindex1(vars.stringParamVars)%>
  <%arrayReindex1(vars.aliasVars)%>
  <%arrayReindex1(vars.intAliasVars)%>
  <%arrayReindex1(vars.boolAliasVars)%>
  <%arrayReindex1(vars.stringAliasVars)%>
  <%arrayReindex1(vars.constVars)%>
  <%arrayReindex1(vars.intConstVars)%>
  <%arrayReindex1(vars.boolConstVars)%>
  <%arrayReindex1(vars.stringConstVars)%>
  >>
end arrayReindex;

template arrayReindex1(list<SimVar> varsLst) ::=
 
  varsLst |> SIMVAR(arrayCref=SOME(_),numArrayElement=_::_) =>
  <<
  <%arraycref(name)%>.reindex(1);
  >>
  ;separator="\n"
end arrayReindex1;


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
        <% if vars.algVars then
        'names += <%(vars.algVars |> SIMVAR(__) =>
        '"<%crefStr(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
      
       }
       void  <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeIntAlgVarsResultNames(vector<string>& names)
        {
         <% if vars.intAlgVars then
         'names += <%(vars.intAlgVars |> SIMVAR(__) =>
           '"<%crefStr(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }
        void <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeBoolAlgVarsResultNames(vector<string>& names)
        {
        <% if vars.boolAlgVars then
         'names +=<%(vars.boolAlgVars |> SIMVAR(__) =>  
           '"<%crefStr(name)%>"'  ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }
        
        void  <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeIntputVarsResultNames(vector<string>& names)
        {
          <% if vars.inputVars then
          'names += <%(vars.inputVars |> SIMVAR(__) =>
           '"<%crefStr(name)%>"'  ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }
        
        void  <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeOutputVarsResultNames(vector<string>& names)
        {
          <% if vars.outputVars then
          'names += <%(vars.outputVars |> SIMVAR(__) =>
           '"<%crefStr(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }
        
        void  <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeAliasVarsResultNames(vector<string>& names)
        {
         <% if vars.aliasVars then
         'names +=<%(vars.aliasVars |> SIMVAR(__) =>
          '"<%crefStr(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += "  )%>;' %>
        }
        
       void   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeIntAliasVarsResultNames(vector<string>& names)
        {
        <% if vars.intAliasVars then
           'names += <%(vars.intAliasVars |> SIMVAR(__) =>
            '"<%crefStr(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }
        
        void <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeBoolAliasVarsResultNames(vector<string>& names)
        {
          <% if vars.boolAliasVars then
          'names += <%(vars.boolAliasVars |> SIMVAR(__) =>
            '"<%crefStr(name)%>"';separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }
        
        void  <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeStateVarsResultNames(vector<string>& names)
        {
        <% if vars.stateVars then
          'names += <%(vars.stateVars |> SIMVAR(__) =>
           '"<%crefStr(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
        }
        
        void   <%lastIdentOfPath(modelInfo.name)%>WriteOutput::writeDerivativeVarsResultNames(vector<string>& names)
        {
         <% if vars.derivativeVars then
          'names += <%(vars.derivativeVars |> SIMVAR(__) =>
          '"<%crefStr(name)%>"' ;separator=",";align=10;alignSeparator=";\n names += " )%>;' %>
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
<%varInfo.numAlgVars%>+<%varInfo.numIntAlgVars%>+<%varInfo.numBoolAlgVars%>
>>
end numAlgvars;

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

template numAlgvar(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numAlgVars%>
>>
end numAlgvar;

template numIntAlgvar(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numIntAlgVars%>
>>
end numIntAlgvar;

template numBoolAlgvar(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numBoolAlgVars%>
>>
end numBoolAlgvar;

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

template numIntAliasvar(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numIntAliasVars%>
>>
end numIntAliasvar;

template numBoolAliasvar(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numBoolAliasVars%>
>>
end numBoolAliasvar;

template numDerivativevars(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__)) then
<<
<%varInfo.numStateVars%>
>>
end numDerivativevars;

template getAliasVar(AliasVariable aliasvar, SimCode simCode,Context context)
 "Returns the alias Attribute of ScalarVariable."
::=
  match aliasvar
    case NOALIAS(__) then 'noAlias'
    case ALIAS(__) then '<%cref1(varName,simCode,context)%>'
    case NEGATEDALIAS(__) then '-<%cref1(varName,simCode,context)%>'
    else 'noAlias'
end getAliasVar;

template writeoutput2(ModelInfo modelInfo,SimCode simCode)

::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then


 <<
     const int algVarsStart = 0;
     const int intAlgVarsStart    = algVarsStart       + <%numAlgvar(modelInfo)%>;
     const int boolAlgVarsStart   = intAlgVarsStart    + <%numIntAlgvar(modelInfo)%>;
     const int inputVarsStart     = boolAlgVarsStart   + <%numBoolAlgvar(modelInfo)%>;
     const int outputVarsStart    = inputVarsStart     + <%numInputvar(modelInfo)%>;
     const int aliasVarsStart     = outputVarsStart    + <%numOutputvar(modelInfo)%>;     
     const int intAliasVarsStart  = aliasVarsStart     + <%numAliasvar(modelInfo)%>;
     const int boolAliasVarsStart = intAliasVarsStart  + <%numIntAliasvar(modelInfo)%>;
     const int stateVarsStart     = boolAliasVarsStart + <%numBoolAliasvar(modelInfo)%>;
     
     <%vars.algVars         |> SIMVAR(__) hasindex i0 =>'v(algVarsStart+<%i0%>)=<%cref(name)%>;';align=8 %>
     <%vars.intAlgVars      |> SIMVAR(__) hasindex i1 =>'v(intAlgVarsStart+<%i1%>)=<%cref(name)%>;';align=8%>
     <%vars.boolAlgVars     |> SIMVAR(__) hasindex i2 =>'v(boolAlgVarsStart+<%i2%>)=<%cref(name)%>;';align=8 %>
    
     <%vars.inputVars       |> SIMVAR(__) hasindex i3 =>'v(inputVarsStart+<%i3%>)=<%cref(name)%>;';align=8 %>
     <%vars.outputVars      |> SIMVAR(__) hasindex i4 =>'v(outputVarsStart+<%i4%>)=<%cref(name)%>;';align=8 %>

     <%vars.aliasVars       |> SIMVAR(__) hasindex i5 =>'v(aliasVarsStart+<%i5%>)=<%getAliasVar(aliasvar, simCode,contextOther)%>;';align=8 %>
     <%vars.intAliasVars    |> SIMVAR(__) hasindex i6 =>'v(intAliasVarsStart+<%i6%>)=<%getAliasVar(aliasvar, simCode,contextOther)%>;';align=8 %>
     <%vars.boolAliasVars   |> SIMVAR(__) hasindex i7 =>'v(boolAliasVarsStart+<%i7%>)=<%getAliasVar(aliasvar, simCode,contextOther)%>;';align=8 %>
     
     <%(vars.stateVars      |> SIMVAR(__) hasindex i8 =>'v(stateVarsStart+<%i8%>)=__z[<%index%>]; ';align=8 )%>
     <%(vars.derivativeVars |> SIMVAR(__) hasindex i9 =>'v2(<%i9%>)=__zDot[<%index%>]; ';align=8 )%>
 >>
end writeoutput2;


template saveall(ModelInfo modelInfo, SimCode simCode)

::=
match simCode
case SIMCODE(modelInfo = MODELINFO(vars = vars as SIMVARS(__)))
  then
  <<
    void <%lastIdentOfPath(modelInfo.name)%>::saveAll()
    {
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

    }
  >>
  /*
  //save all zero crossing condtions
   <%saveconditionvar(zeroCrossings,simCode)%>
   */
end saveall;

template savediscreteVars(ModelInfo modelInfo, SimCode simCode)

::=
match simCode
case SIMCODE(modelInfo = MODELINFO(vars = vars as SIMVARS(__)))
  then
  <<
    void <%lastIdentOfPath(modelInfo.name)%>::saveDiscreteVars()
    {

      <%{
       (vars.algVars |> SIMVAR(__) =>
        '_event_handling.saveDiscreteVar(<%cref(name)%>,"<%cref(name)%>");'
      ;separator="\n"),
      (vars.intAlgVars |> SIMVAR(__) =>
       '_event_handling.saveDiscreteVar(<%cref(name)%>,"<%cref(name)%>");'
      ;separator="\n"),
      (vars.boolAlgVars |> SIMVAR(__) =>
        '_event_handling.saveDiscreteVar(<%cref(name)%>,"<%cref(name)%>");'
      ;separator="\n")}
     ;separator="\n"%>



    }
  >>
 end savediscreteVars;

template initvar( Text &varDecls /*BUFP*/,ModelInfo modelInfo,SimCode simCode)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
 <<
  <%initValst(varDecls,vars.stateVars, simCode,contextOther)%>
  <%initValst(varDecls,vars.derivativeVars, simCode,contextOther)%>
  <%initValst(varDecls,vars.algVars, simCode,contextOther)%>
  <%initValst(varDecls,vars.intAlgVars, simCode,contextOther)%>
  <%initValst(varDecls,vars.boolAlgVars, simCode,contextOther)%>
  <%initValst(varDecls,vars.aliasVars, simCode,contextOther)%>
  <%initValst(varDecls,vars.intAliasVars, simCode,contextOther)%>
  <%initValst(varDecls,vars.boolAliasVars, simCode,contextOther)%>
  <%initValst(varDecls,vars.paramVars, simCode,contextOther)%>
  
 >>
end initvar;

template initvarExtVar( Text &varDecls /*BUFP*/,ModelInfo modelInfo,SimCode simCode)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
 <<
  <%initValst(varDecls,vars.extObjVars, simCode,contextOther)%>
  
 >>
end initvarExtVar;

template initAlgloopvars( Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,ModelInfo modelInfo,SimCode simCode)
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  let &varDecls = buffer "" /*BUFD*/
  
 let algvars =initValst(varDecls,vars.algVars, simCode,contextAlgloop)
 let intvars = initValst(varDecls,vars.intAlgVars, simCode,contextAlgloop)
 let boolvars = initValst(varDecls,vars.boolAlgVars, simCode,contextAlgloop)
 <<
  <%varDecls%>
  
  <%algvars%>
  <%intvars%>
  <%boolvars%>
  >>
end initAlgloopvars;

template boundParameters(list<SimEqSystem> parameterEquations,Text &varDecls,SimCode simCode)
 "Generates function in simulation file."
::=

  let &tmp = buffer ""
  let body = (parameterEquations |> eq as SES_SIMPLE_ASSIGN(__) =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFD*/, simCode)
    ;separator="\n")
  let divbody = (parameterEquations |> eq as SES_ALGORITHM(__) =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFD*/, simCode)
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


template isOutput(Causality c)
 "Returns the Causality Attribute of a Variable."
::=
match c
  case OUTPUT(__) then "output"
end isOutput;

template initValst(Text &varDecls /*BUFP*/,list<SimVar> varsLst, SimCode simCode, Context context) ::=
  varsLst |> sv as SIMVAR(__) =>
      let &preExp = buffer "" /*BUFD*/
    match initialValue
      case SOME(v) then
      match daeExp(v, contextOther, &preExp, &varDecls,simCode)
      case vStr as "0"
      case vStr as "0.0"
      case vStr as "(0)" then
       '<%preExp%>
        <%cref1(sv.name,simCode,context)%>=<%vStr%>;//<%cref(sv.name)%>
       _start_values["<%cref(sv.name)%>"]=<%vStr%>;'
      case vStr as "" then
       '<%preExp%>
       <%cref1(sv.name,simCode,context)%>=0;//<%cref(sv.name)%>
        _start_values["<%cref(sv.name)%>"]=<%vStr%>;'
      case vStr then
       '<%preExp%>
       <%cref1(sv.name,simCode,context)%>=<%vStr%>;//<%cref(sv.name)%>
       _start_values["<%cref(sv.name)%>"]=<%vStr%>;'
        end match
      else
        '<%preExp%>
        <%cref1(sv.name,simCode,context)%>=<%startValue(sv.type_)%>;
       _start_values["<%cref(sv.name)%>"]=<%startValue(sv.type_)%>;'
  ;separator="\n"
end initValst;

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
    _dimBoolean =<%vi.numBoolAlgVars%> + <%vi.numBoolParams%>;
    _dimInteger =<%vi.numIntAlgVars%>  + <%vi.numIntParams%>;
    _dimString =<%vi.numStringAlgVars%> + <%vi.numStringParamVars%>;
     _dimReal =<%vi.numAlgVars%> + <%vi.numParams%>;
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
    case T_ARRAY(dims=dims) then 'multi_array_ref<<%expTypeShort(ty)%>,<%listLength(dims)%>>'
    else expTypeFlag(ty, 2)
    end match
  case 6 then
    match ty
    case T_ARRAY(dims=dims) then 'multi_array<<%expTypeShort(ty)%>,<%listLength(dims)%>>'
    else expTypeFlag(ty, 2)
    end match
  case 7 then
     match ty
    case T_ARRAY(dims=dims)
    then
     'multi_array<<%expTypeShort(ty)%>,<%listLength(dims)%>>'
    end match

end expTypeFlag;


template boostExtents(DAE.Type ty)
::=
 match ty
    case T_ARRAY(dims=dims) then
    << 
    boost::extents[<%(dims |> dim as DIM_INTEGER(integer=i)  =>  '<%i%>';separator="][")%>]
    >>
    
end boostExtents;

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
  case T_UNKNOWN(__)     then "complex"
  case T_ANYTYPE(__)     then "complex"
  case T_ARRAY(__)       then expTypeShort(ty)
  case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__))
                      then "void*"
  case T_COMPLEX(__)     then 'complex'
  case T_METATYPE(__) case T_METABOXED(__)    then "metatype"
  case T_FUNCTION_REFERENCE_VAR(__) then "fnptr"
  else "expTypeShort:ERROR"
end expTypeShort;

template dimension(Dimension d)
::=
  match d
  case DAE.DIM_INTEGER(__) then integer
  case DAE.DIM_ENUM(__) then size
  case DAE.DIM_UNKNOWN(__) then ":"
  else "INVALID_DIMENSION"
end dimension;

template arrayCrefCStr(ComponentRef cr,Context context)
::=
match context
case ALGLOOP_CONTEXT(genInitialisation = false) 
then << _system->_<%arrayCrefCStr2(cr)%> >>
else
'_<%arrayCrefCStr2(cr)%>'
end arrayCrefCStr;

template arrayCrefCStr2(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(__) then '<%unquoteIdentifier(ident)%>'
  case CREF_QUAL(__) then '<%unquoteIdentifier(ident)%>_P_<%arrayCrefCStr2(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end arrayCrefCStr2;

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


template contextCref(ComponentRef cr, Context context,SimCode simCode)
  "Generates code for a component reference depending on which context we're in."
::=
match cr
case CREF_QUAL(ident = "$PRE") then 
   '_event_handling.pre(<%contextCref(componentRef,context,simCode)%>,"<%cref(componentRef)%>")'
 else
  match context
  case FUNCTION_CONTEXT(__) then System.unquoteIdentifier(crefStr(cr))
  else '<%cref1(cr,simCode,context)%>'
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

template functionInitial(list<SimEqSystem> startValueEquations,Text &varDecls,SimCode simCode)

::=


  let eqPart = (startValueEquations |> eq as SES_SIMPLE_ASSIGN(__) =>
      equation_(eq, contextSimulationDiscrete, &varDecls,simCode)
    ;separator="\n")
  <<

    <%eqPart%>
  >>
end functionInitial;


template equation_(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case e as SES_SIMPLE_ASSIGN(__)
    then equationSimpleAssign(e, context,&varDecls,simCode)
  case e as SES_ALGORITHM(__)
    then equationAlgorithm(e, context, &varDecls /*BUFD*/,simCode)
  case e as SES_WHEN(__)
    then equationWhen(e, context, &varDecls /*BUFD*/,simCode)
  case e as SES_ARRAY_CALL_ASSIGN(__)
    then equationArrayCallAssign(e, context, &varDecls /*BUFD*/,simCode)
  case SES_LINEAR(__)
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
          delete[] conditions0<%index%>;
          delete[] conditions1<%index%>;
          throw std::invalid_argument("Nonlinear solver stopped at time " + boost::lexical_cast<string>(_simTime) + " with error: " + ex.what());
                         
       } 
       delete[] conditions0<%index%>;
       delete[] conditions1<%index%>;
       if(restart<%index%>&& iterations<%index%> > 0)
       {
            try
             {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
                IContinuous::UPDATETYPE calltype = _callType;
               _callType = IContinuous::DISCRETE;
                 _algLoop<%index%>->setReal(algloop<%index%>Vars );
                _algLoopSolver<%index%>->solve(command);
               _callType = calltype;   
             }
             catch(std::exception &ex)
             { 
                delete[] algloop<%index%>Vars; 
                throw std::invalid_argument("Nonlinear solver stopped at time " + boost::lexical_cast<string>(_simTime) + " with error: " + ex.what());
             }
        
       }
        delete[] algloop<%index%>Vars; 
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
 





template equationMixed(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/, SimCode simCode)
 "Generates a mixed equation system."
::=
match eq
case SES_MIXED(__) then
  let contEqs = equation_(cont, context, &varDecls /*BUFD*/, simCode)
  let numDiscVarsStr = listLength(discVars)
//  let valuesLenStr = listLength(values)
  let &preDisc = buffer "" /*BUFD*/
  let num = index
  let discvars2 = (discEqs |> SES_SIMPLE_ASSIGN(__) hasindex i0 =>
      let expPart = daeExp(exp, context, &preDisc /*BUFC*/, &varDecls /*BUFD*/,simCode)
      <<
      <%cref(cref)%> = <%expPart%>;
      new_disc_vars<%num%>[<%i0%>] = <%cref(cref)%>;
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
         <%discVars |> SIMVAR(__) hasindex i0 => 'pre_disc_vars<%num%>[<%i0%>] = <%cref(name)%>;' ;separator="\n"%>
          <%contEqs%>
         
          <%preDisc%>
         <%discvars2%>
         bool* cur_disc_vars<%num%>[<%numDiscVarsStr%>]= {<%discVars |> SIMVAR(__) => '&<%cref(name)%>' ;separator=", "%>};
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

template generateStepCompleted(list<SimEqSystem> allEquations,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver =   generateStepCompleted2(allEquations,simCode)
  match simCode
case SIMCODE(modelInfo = MODELINFO(__))
then
let store_delay_expr = functionStoreDelay(delayedExps,simCode)
  <<
  void <%lastIdentOfPath(modelInfo.name)%>::stepCompleted(double time)
  {
   <%algloopsolver%>
     <%store_delay_expr%>
   saveAll();
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


template generateTimeEvent(list<BackendDAE.TimeEvent> timeEvents, SimCode simCode)
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
              let e1 = daeExp(startExp, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
              let e2 = daeExp(intervalExp, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
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

  _algLoop<%num%> =  boost::shared_ptr<<%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>>(new <%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>(this,__z,__zDot,_conditions,_event_handling )
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

/*_algLoop<%num%> =  boost::shared_ptr<<%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>>(new <%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>(<%CallAlgloopParams(modelInfo)%>__z,__zDot,_event_handling )*/


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
      boost::shared_ptr<<%lastIdentOfPath(modelInfo.name)%>Algloop<%num%>>  //Algloop  which holds equation system
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


template initAlgloopsolvers(list<list<SimEqSystem>> continousEquations,list<list<SimEqSystem>> discreteEquations,list<SimWhenClause> whenClauses,list<SimEqSystem> parameterEquations,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (continousEquations |> eqs => (eqs |> eq =>
      initAlgloopsolvers2(eq, contextOther, &varDecls /*BUFC*/,simCode))
    ;separator="\n")

  <<
  <%algloopsolver%>
  >>
end initAlgloopsolvers;


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
template algloopfiles(list<SimEqSystem> allEquations, SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let algloopsolver = (allEquations |> eqs =>
      algloopfiles2(eqs, contextOther, &varDecls /*BUFC*/,simCode)
    ;separator="\n")

  <<
  <%algloopsolver%>
  >>
end algloopfiles;




template algloopfiles2(SimEqSystem eq, Context context, Text &varDecls, SimCode simCode)
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
              let()= textFile(algloopHeaderFile(simCode,eq), 'OMCpp<%fileNamePrefix%>Algloop<%num%>.h')
              let()= textFile(algloopCppFile(simCode,eq), 'OMCpp<%fileNamePrefix%>Algloop<%num%>.cpp')
            " "
        end match
  case e as SES_MIXED(cont = eq_sys)
    then
       match simCode
          case SIMCODE(modelInfo = MODELINFO(__)) then
              let()= textFile(algloopHeaderFile(simCode, eq_sys), 'OMCpp<%fileNamePrefix%>Algloop<%algloopfilesindex(eq_sys)%>.h')
              let()= textFile(algloopCppFile(simCode, eq_sys), 'OMCpp<%fileNamePrefix%>Algloop<%algloopfilesindex(eq_sys)%>.cpp')
            " "
        end match
  else
    " "
 end algloopfiles2;

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
    ;separator=" ")

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
                                 Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates equation on form 'cref_array = call(...)'."
::=
match eq

case eqn as SES_ARRAY_CALL_ASSIGN(__) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(exp, context, &preExp /*BUF  let &preExp = buffer "" /*BUFD*/
  let &helpInits = buffer "" /*BUFD*/
  let helpIf = (conditions |> (e, hidx) =>
      let helpInit = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
      let &helpInits += 'localData->helpVars[<%hidx%>] = <%helpInit%>;'
      'localData->helpVars[<%hidx%>] && !localData->helpVars_saved[<%hidx%>] /* edge */'
    ;separator=" || ")C*/, &varDecls /*BUFD*/,simCode)
  match expTypeFromExpShort(eqn.exp)
  case "boolean" then
    let tvar = tempDecl("boolean_array", &varDecls /*BUFD*/)
    //let &preExp += 'cast_integer_array_to_real(&<%expPart%>, &<%tvar%>);<%\n%>'
    <<
    <%preExp%>
    <%cref1(eqn.componentRef,simCode, context)%>=<%expPart%>;
    >>
  case "int" then
    let tvar = tempDecl("integer_array", &varDecls /*BUFD*/)
    <<
      <%preExp%>
      <%cref1(eqn.componentRef,simCode, context)%>=<%expPart%>;
    >>
  case "double" then
   <<
        <%preExp%>
       <%assignDerArray(context,expPart,eqn.componentRef,simCode)%>
   >>
 end equationArrayCallAssign;
  /*<%cref1(eqn.componentRef,simCode, context)%>=<%expPart%>;*/


template assignDerArray(Context context, String arr, ComponentRef c,SimCode simCode)
::=
  cref2simvar(c, simCode) |> var as SIMVAR(__) =>
   match varKind
    case STATE(__)        then
     <<
        /*<%cref(c)%>*/
        memcpy(&<%cref1(c,simCode, context)%>,<%arr%>.data(),<%arr%>.shape()[0]*sizeof(double));
     >>
    case STATE_DER(__)   then
    <<
      memcpy(&<%cref1(c,simCode, context)%>,<%arr%>.data(),<%arr%>.shape()[0]*sizeof(double));
    >>
    else
    <<
       <%cref1(c,simCode, context)%>=<%arr%>;
    >>
end assignDerArray;

template equationWhen(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates a when equation."
::=
  match eq
     case SES_WHEN(left=left, right=right, conditions=conditions, elseWhen=NONE()) then
      let helpIf = (conditions |> e => ' || (<%cref1(e, simCode, context)%> && !_event_handling.pre(<%cref1(e, simCode, context)%>,"<%cref1(e, simCode, context)%>"))')
      
        let initial_assign = 
        if initialCall then
          whenAssign(left,typeof(right),right,context, &varDecls /*BUFD*/,simCode)
        else 
           '<%cref1(left,simCode, context)%> = _event_handling.pre(<%cref1(left,simCode, context)%>,"<%cref1(left,simCode, context)%>");'
       let assign = whenAssign(left,typeof(right),right,context, &varDecls /*BUFD*/,simCode)
      <<
    
      if(_initial) 
      {
        <%initialCall%>; 
      }
       else if (0<%helpIf%>)
       {
        <%assign%>;
      }
      else
      {
        <%cref1(left,simCode, context)%> = _event_handling.pre(<%cref1(left,simCode, context)%>,"<%cref1(left,simCode, context)%>");
      }
           >>
    case SES_WHEN(left=left, right=right, conditions=conditions, elseWhen=SOME(elseWhenEq)) then
       let helpIf = (conditions |> e => ' || (<%cref1(e, simCode, context)%> && !_event_handling.pre(<%cref1(e, simCode, context)%>,"<%cref1(e, simCode, context)%>"))')
      let initial_assign = 
        if initialCall then
          whenAssign(left,typeof(right),right,context, &varDecls /*BUFD*/,simCode)
        else 
         '<%cref1(left,simCode, context)%> = _event_handling.pre(<%cref1(left,simCode, context)%>,"<%cref1(left,simCode, context)%>");'
      let assign = whenAssign(left,typeof(right),right,context, &varDecls /*BUFD*/,simCode)
      let elseWhen = equationElseWhen(elseWhenEq,context,varDecls,simCode)
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
         <%cref1(left,simCode, context)%> = _event_handling.pre(<%cref1(left,simCode, context)%>,"<%cref1(left,simCode, context)%>");
      }
      >>
end equationWhen;


template whenAssign(ComponentRef left, Type ty, Exp right, Context context,  Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates assignment for when."
::=
match ty
  case T_ARRAY(__) then
    let &preExp = buffer "" /*BUFD*/
    let expPart = daeExp(right, context, &preExp, &varDecls /*BUFD*/,simCode)
    match expTypeFromExpShort(right)
    case "boolean" then
      let tvar = tempDecl("boolean_array", &varDecls /*BUFD*/)
      //let &preExp += 'cast_integer_array_to_real(&<%expPart%>, &<%tvar%>);<%\n%>'
      <<
      <%preExp%>
      copy_boolean_array_data_mem(&<%expPart%>, &<%cref(left)%>);<%inlineArray(context,tvar,left)%>
      >>
    case "integer" then
      let tvar = tempDecl("integer_array", &varDecls /*BUFD*/)
      //let &preExp += 'cast_integer_array_to_real(&<%expPart%>, &<%tvar%>);<%\n%>'
      <<
      <%preExp%>
      copy_integer_array_data_mem(&<%expPart%>, &<%cref(left)%>);<%inlineArray(context,tvar,left)%>
      >>
    case "real" then
      <<
      <%preExp%>
      copy_real_array_data_mem(&<%expPart%>, &<%cref(left)%>);<%inlineArray(context,expPart,left)%>
      >>
    case "string" then
      <<
      <%preExp%>
      copy_string_array_data_mem(&<%expPart%>, &<%cref(left)%>);<%inlineArray(context,expPart,left)%>
      >>
    else
      error(sourceInfo(), 'No runtime support for this sort of array call: <%cref(left)%> = <%printExpStr(right)%>')
    end match
  else
    let &preExp = buffer "" /*BUFD*/
    let exp = daeExp(right, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    <<
    <%preExp%>
    <%cref(left)%> = <%exp%>;
   >>
end whenAssign;
template inlineArray(Context context, String arr, ComponentRef c)
::= match context case INLINE_CONTEXT(__) then match c
case CREF_QUAL(ident = "$DER") then <<

inline_integrate_array(size_of_dimension_real_array(&<%arr%>,1),<%cref(c)%>);
>>
end inlineArray;

template equationElseWhen(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates a else when equation."
::=
match eq
case SES_WHEN(left=left, right=right, conditions=conditions, elseWhen=NONE()) then
  let helpIf =  (conditions |> e => ' || (<%cref1(e, simCode, context)%> && !_event_handling.pre(<%cref1(e, simCode, context)%>,"<%cref1(e, simCode, context)%>"))')
  let assign = whenAssign(left,typeof(right),right,context, &varDecls /*BUFD*/,simCode)
  <<
  else if(0<%helpIf%>)
  {
    <%assign%>
  }
  >>
case SES_WHEN(left=left, right=right, conditions=conditions, elseWhen=SOME(elseWhenEq)) then
  let helpIf = (conditions |> e => ' || (<%cref1(e, simCode, context)%> && !_event_handling.pre(<%cref1(e, simCode, context)%>,"<%cref1(e, simCode, context)%>"))')
  let assign = whenAssign(left,typeof(right),right,context, &varDecls /*BUFD*/,simCode)
  let elseWhen = equationElseWhen(elseWhenEq,context,varDecls,simCode)
  <<
  else if(0<%helpIf%>)
  {
    <%assign%>
  }
  <%elseWhen%>
  >>
end equationElseWhen;

template helpvarvector(list<SimWhenClause> whenClauses,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let reinit = (whenClauses |> when hasindex i0 =>
      helpvarvector1(when, contextOther,&varDecls,i0,simCode)
    ;separator="";empty)
  <<
    <%reinit%>
  >>
end helpvarvector;

template helpvarvector1(SimWhenClause whenClauses,Context context, Text &varDecls,Integer int,SimCode simCode)
::=
match whenClauses
case SIM_WHEN_CLAUSE(__) then
  let &preExp = buffer "" /*BUFD*/
  let &helpInits = buffer "" /*BUFD*/
  let helpIf = (conditions |> e =>
      let helpInit = cref1(e, simCode, context)
      ""
   ;separator="")
<<
 <%preExp%>
 <%helpIf%>
>>
end helpvarvector1;



template preCref(ComponentRef cr, SimCode simCode, Context context) ::=
'pre<%representationCref(cr, simCode,context)%>'
end preCref;

template equationSimpleAssign(SimEqSystem eq, Context context,Text &varDecls,
                              SimCode simCode)
 "Generates an equation that is just a simple assignment."
::=
match eq
case SES_SIMPLE_ASSIGN(__) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)

  match cref
  case CREF_QUAL(ident = "$PRE")  then 
  << 
    <%preExp%>
      _event_handling.save(<%expPart%>,"<%cref(componentRef)%>");
  >>
  else
   match exp
  case CREF(ty = t as  T_ARRAY(__)) then
  <<
  //Array assign
  <%cref1(cref, simCode,context)%>=<%expPart%>;
  >>
  else
  <<
  <%preExp%>
  <%cref1(cref, simCode,context)%>=<%expPart%>;
  >>
 end match
end match  
end equationSimpleAssign;





template daeExp(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for an expression."
::=
  match exp
  case e as ICONST(__)          then '<%integer%>' /* Yes, we need to cast int to long on 64-bit arch... */
  case e as RCONST(__)          then real
  case e as BCONST(__)          then if bool then "true" else "false"
  case e as ENUM_LITERAL(__)    then index
  case e as CREF(__)            then daeExpCrefRhs(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  case e as CAST(__)            then daeExpCast(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  case e as CONS(__)            then "Cons not supported yet"
  case e as SCONST(__)          then daeExpSconst(string, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  case e as UNARY(__)           then daeExpUnary(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  case e as LBINARY(__)         then daeExpLbinary(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  case e as LUNARY(__)          then daeExpLunary(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  case e as BINARY(__)          then daeExpBinary(operator, exp1, exp2, context, &preExp, &varDecls,simCode)
  case e as IFEXP(__)           then daeExpIf(expCond, expThen, expElse, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode)
  case e as RELATION(__)        then daeExpRelation(e, context, &preExp, &varDecls,simCode)
  case e as CALL(__)            then daeExpCall(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  case e as RECORD(__)          then daeExpRecord(e, context, &preExp, &varDecls,simCode)
  case e as ASUB(__)            then daeExpAsub(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  case e as MATRIX(__)          then daeExpMatrix(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  case e as RANGE(__)           then daeExpRange(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  case e as ASUB(__)            then "Asub not supported yet"
  case e as TSUB(__)            then "Tsub not supported yet"
  case e as REDUCTION(__)       then daeExpReduction(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  case e as ARRAY(__)           then daeExpArray(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  case e as SIZE(__)            then daeExpSize(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  case e as SHARED_LITERAL(__)  then daeExpSharedLiteral(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  else error(sourceInfo(), 'Unknown exp:<%printExpStr(exp)%>')
end daeExp;

template daeExpRange(Exp exp, Context context, Text &preExp /*BUFP*/,
                      Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for a range expression."
::=
  match exp
  case RANGE(__) then
    let ty_str = expTypeArray(ty)
    let start_exp = daeExp(start, context, &preExp, &varDecls,simCode)
    let stop_exp = daeExp(stop, context, &preExp, &varDecls,simCode)
    let tmp = tempDecl('multi_array<<%ty_str%>,1>', &varDecls /*BUFD*/)
    let step_exp = match step case SOME(stepExp) then daeExp(stepExp, context, &preExp, &varDecls,simCode) else "1"
    let &preExp += 'int num_elems =(<%stop_exp%>-<%start_exp%>)/<%step_exp%>+1;
    <%tmp%>.resize((boost::extents[num_elems]));
    <%tmp%>.reindex(1); 
    for(int i= 1;i<=num_elems;i++)
        <%tmp%>[i] =<%start_exp%>+(i-1)*<%step_exp%>;
    '
    '<%tmp%>'
end daeExpRange;






template daeExpReduction(Exp exp, Context context, Text &preExp /*BUFP*/,
                         Text &varDecls /*BUFP*/,SimCode simCode)
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
  let loopVar = expTypeFromExpArrayIf(iter.exp,context,rangeExpPre,tmpVarDecls,simCode)
  let arrayTypeResult = expTypeFromExpArray(r)
  /*let loopVar = match identType
    case "modelica_metatype" then tempDecl(identType,&tmpVarDecls)
    else tempDecl(arrayType,&tmpVarDecls)*/
  let firstIndex = match identType case "modelica_metatype" then "" else tempDecl("int",&tmpVarDecls)
  let arrIndex = match ri.path case IDENT(name="array") then tempDecl("int",&tmpVarDecls)
  let foundFirst = if not ri.defaultValue then tempDecl("int",&tmpVarDecls)
  let rangeExp = daeExp(iter.exp,context,&rangeExpPre,&tmpVarDecls,simCode)
  let resType = expTypeArrayIf(typeof(exp))
  let res = contextCref(makeUntypedCrefIdent("$reductionFoldTmpB"), context,simCode)
  let &tmpVarDecls += '<%resType%> <%res%>;<%\n%>'
  let resTmp = tempDecl(resType,&varDecls)
  let &preDefault = buffer ""
  let resTail = match ri.path case IDENT(name="list") then tempDecl("modelica_metatype*",&tmpVarDecls)
  let defaultValue = match ri.path case IDENT(name="array") then "" else match ri.defaultValue
    case SOME(v) then daeExp(valueExp(v),context,&preDefault,&tmpVarDecls,simCode)
    end match
  let guardCond = match iter.guardExp case SOME(grd) then daeExp(grd, context, &guardExpPre, &tmpVarDecls,simCode) else "1"
  let empty = match identType case "modelica_metatype" then 'listEmpty(<%loopVar%>)' else '0 == <%loopVar%>.shape()[0]'
  let length = match identType case "modelica_metatype" then 'listLength(<%loopVar%>)' else '<%loopVar%>.shape()[0]'
  let reductionBodyExpr = contextCref(makeUntypedCrefIdent("$reductionFoldTmpA"), context,simCode)
  let bodyExprType = expTypeArrayIf(typeof(r.expr))
  let reductionBodyExprWork = daeExp(r.expr, context, &bodyExpPre, &tmpVarDecls,simCode)
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
      '<%res%>[<%arrIndex%>++] = <%reductionBodyExpr%>;'
    else match ri.foldExp case SOME(fExp) then
      let &foldExpPre = buffer ""
      let fExpStr = daeExp(fExp, context, &bodyExpPre, &tmpVarDecls,simCode)
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
     case IDENT(name="array") then
     <<
     <%arrIndex%> = 1;
     <%res%>.resize(boost::extents[<%length%>]);
     <%res%>.reindex(1);
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
    else
    <<
    while(<%firstIndex%> <= <%loopVar%>.shape()[0])
    {
      <%identType%> <%iteratorName%>;
      <%iteratorName%> = <%loopVar%>[<%firstIndex%>++];
  
    >>
   let loopTail = '}'
  let loopvarassign = 
     match typeof(iter.exp)
      case ty as T_ARRAY(__) then
      'assign_array( <%loopVar%>,<%rangeExp%>);'
      else 
       '<%loopVar%> = <%rangeExp%>;'
       end match
  
    let assign_res = match ri.path
     case IDENT(name="array")  then
        'assign_array(<% resTmp %>, <% res %>);'
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
                    Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for a size expression."
::=
  match exp
  case SIZE(exp=CREF(__), sz=SOME(dim)) then
    let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let dimPart = daeExp(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let resVar = tempDecl("size_t", &varDecls /*BUFD*/)
    let typeStr = '<%expTypeArray(exp.ty)%>'
    let &preExp += '<%resVar%> = <%expPart%>.shape()[<%dimPart%>-1];<%\n%>'
    resVar
  else "size(X) not implemented"
end daeExpSize;


template daeExpMatrix(Exp exp, Context context, Text &preExp /*BUFP*/,
                      Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for a matrix expression."
::=
  match exp
  case MATRIX(matrix={{}})  // special case for empty matrix: create dimensional array Real[0,1]
  case MATRIX(matrix={})    // special case for empty array: create dimensional array Real[0,1]
    then
    let typestr = expTypeArray(ty)
    let arrayTypeStr = 'boost::multi_array<<%typestr%>,2>'
    let tmp = tempDecl(arrayTypeStr, &varDecls /*BUFD*/)
   // let &preExp += 'alloc_<%arrayTypeStr%>(&<%tmp%>, test2, 0, 1);<%\n%>'
    tmp
   case m as MATRIX(matrix=(row1::_)) then
     let arrayTypeStr = expTypeArray(ty)
       let arrayDim = expTypeArrayforDim(ty)
       let &tmp = buffer "" /*BUFD*/
     let arrayVar = tempDecl(arrayTypeStr, &tmp /*BUFD*/)
     let &vals = buffer "" /*BUFD*/
       let dim_cols = listLength(row1)

    let params = (m.matrix |> row =>
        let vars = daeExpMatrixRow(row, context, &varDecls,&preExp,simCode)
        '<%vars%>'
      ;separator=",")

     let &preExp += '
     <%arrayDim%><%arrayVar%>(boost::extents[<%listLength(m.matrix)%>][<%dim_cols%>]);
     <%arrayVar%>.reindex(1);
     <%arrayTypeStr%> <%arrayVar%>_data[]={<%params%>};
    <%arrayVar%>.assign(<%arrayVar%>_data,<%arrayVar%>_data+ (<%listLength(m.matrix)%> * <%dim_cols%>));<%\n%>'

     arrayVar
end daeExpMatrix;


template daeExpMatrixRow(list<Exp> row,
                         Context context,
                         Text &varDecls /*BUFP*/,Text &preExp /*BUFP*/,SimCode simCode)
 "Helper to daeExpMatrix."
::=

   let varLstStr = (row |> e =>
      let expVar = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
      '<%expVar%>'
    ;separator=",")
  varLstStr
end daeExpMatrixRow;


template daeExpArray(Exp exp, Context context, Text &preExp /*BUFP*/,
                     Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for an array expression."
::=
match exp
case ARRAY(array=_::_, ty = arraytype) then
  let arrayTypeStr = expTypeArray(ty)
  let arrayDim = expTypeArrayforDim(ty)
  let &tmpdecl = buffer "" /*BUFD*/
  let arrayVar = tempDecl(arrayTypeStr, &tmpdecl /*BUFD*/)
  // let scalarPrefix = if scalar then "scalar_" else ""
  //let scalarRef = if scalar then "&" else ""
  let &tmpVar = buffer ""
  
  let params = if scalar then (array |> e =>
    '<%daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>';separator=", ")
               else
                (array |> e hasindex i0 fromindex 1 =>
                '<%arrayVar%>[<%i0%>]=<%daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>;'
                ;separator="\n")
   
   let boostExtents = if scalar then '<%arrayDim%><%arrayVar%>(boost::extents[<%listLength(array)%>]);' 
                      else        '<%arrayDim%><%arrayVar%>(<%boostExtents(arraytype)%>/*,boost::fortran_storage_order()*/);'
                      
   let arrayassign =  if scalar then '<%arrayTypeStr%> <%arrayVar%>_data[]={<%params%>}; 
<%arrayVar%>.assign(<%arrayVar%>_data,<%arrayVar%>_data+<%listLength(array)%>);<%\n%>'
                                     
                      else    '<%params%>'           
  
   let &preExp += '
   //tmp array
   <%boostExtents%>
   <%arrayVar%>.reindex(1);
   <%arrayassign%>'
  arrayVar
case ARRAY(__) then
  let arrayTypeStr = expTypeArray(ty)
  let arrayDim = expTypeArrayforDim(ty)
  let &tmpdecl = buffer "" /*BUFD*/
  let arrayVar = tempDecl(arrayTypeStr, &tmpdecl /*BUFD*/)
  // let scalarPrefix = if scalar then "scalar_" else ""
  //let scalarRef = if scalar then "&" else ""
  let &tmpVar = buffer ""
  let &preExp += '
   //tmp array
   <%arrayDim%><%arrayVar%>(boost::extents[<%listLength(array)%>]);
   <%arrayVar%>.reindex(1);<%\n%>'
  arrayVar
end daeExpArray;








//template daeExpAsub(Exp exp, Context context, Text &preExp /*BUFP*/,
//                    Text &varDecls /*BUFP*/,SimCode simCode)
// "Generates code for an asub expression."
//::=
// match exp
//   case ASUB(exp=ecr as CREF(__), sub=subs) then
//    let arrName = daeExpCrefRhs(buildCrefExpFromAsub(ecr, subs), context,
//                              &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
//    match context case FUNCTION_CONTEXT(__)  then
//      arrName
//    else
//      arrayScalarRhs(exp, subs, arrName, context, &preExp, &varDecls,simCode)

//end daeExpAsub;


template daeExpAsub(Exp inExp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for an asub expression."
::=
  match expTypeFromExpShort(inExp)
  case "metatype" then
  // MetaModelica Array
    (match inExp case ASUB(exp=e, sub={idx}) then
      let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
      let idx1 = daeExp(idx, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
      'arrayGet(<%e1%>,<%idx1%>) /* DAE.ASUB */')
  // Modelica Array
  else
  match inExp

  case ASUB(exp=ASUB(__)) then
    error(sourceInfo(),'Nested array subscripting *should* have been handled by the routine creating the asub, but for some reason it was not: <%printExpStr(exp)%>')

  // Faster asub: Do not construct a whole new array just to access one subscript
  case ASUB(exp=exp as ARRAY(scalar=true), sub={idx}) then
    let res = tempDecl(expTypeFromExpModelica(exp),&varDecls)
    let idx1 = daeExp(idx, context, &preExp, &varDecls,simCode)
    let expl = (exp.array |> e hasindex i1 fromindex 1 =>
      let &caseVarDecls = buffer ""
      let &casePreExp = buffer ""
      let v = daeExp(e, context, &casePreExp, &caseVarDecls,simCode)
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
    let arrName = daeExpCrefRhs(buildCrefExpFromAsub(ecr, subs), context,
                              &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    match context case FUNCTION_CONTEXT(__)  then
      arrName
    else
    
      '<%arrayScalarRhs(ecr.ty, subs, arrName, context, &preExp, &varDecls,simCode)%>'


  case ASUB(exp=e, sub=indexes) then
  let exp = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
 // let typeShort = expTypeFromExpShort(e)
  let expIndexes = (indexes |> index => '<%daeExpASubIndex(index, context, &preExp, &varDecls,simCode)%>' ;separator="][")
   //'<%typeShort%>_get<%match listLength(indexes) case 1 then "" case i then '_<%i%>D'%>(&<%exp%>, <%expIndexes%>)'
  '(<%exp%>)[<%expIndexes%>]'
  case exp then
    error(sourceInfo(),'OTHER_ASUB <%printExpStr(exp)%>')
end daeExpAsub;

template daeExpASubIndex(Exp exp, Context context, Text &preExp, Text &varDecls,SimCode simCode)
::=
match exp
  case ICONST(__) then integer
  case ENUM_LITERAL(__) then index
  else daeExp(exp,context,&preExp,&varDecls,simCode)
end daeExpASubIndex;


template arrayScalarRhs(Type ty, list<Exp> subs, String arrName, Context context,
               Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode)
 "Helper to daeExpAsub."
::=
  /* match exp
   case ASUB(exp=ecr as CREF(__)) then*/
  let arrayType = expTypeArray(ty)
  let dimsLenStr = listLength(subs)
  let dimsValuesStr = (subs |> exp =>
      daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)

    ;separator="][")
  match arrayType
    case "metatype_array" then
      'arrayGet(<%arrName%>,<%dimsValuesStr%>) /*arrayScalarRhs*/'
    else
      //ToDo before used <%arrayCrefCStr(ecr.componentRef)%>[<%dimsValuesStr%>]
      << <%arrName%>[<%dimsValuesStr%>] >>
end arrayScalarRhs;

template daeExpCast(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for a cast expression."
::=
match exp
case CAST(__) then
  let expVar = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  match ty
  case T_INTEGER(__)   then '((int)<%expVar%>)'
  case T_REAL(__)  then '((double)<%expVar%>)'
  case T_ENUMERATION(__)   then '((modelica_integer)<%expVar%>)'
  case T_BOOL(__)   then '((bool)<%expVar%>)'
  case T_ARRAY(__) then
    let arrayTypeStr = expTypeArray(ty)
    let tvar = tempDecl(arrayTypeStr, &varDecls /*BUFD*/)
    let to = expTypeShort(ty)
    let from = expTypeFromExpShort(exp)
    let &preExp += 'cast_<%from%>_array_to_<%to%>(&<%expVar%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'
  case T_COMPLEX(complexClassType=rec as RECORD(__))   then '(*((<%underscorePath(rec.path)%>*)&<%expVar%>))'
  else
    '(<%expVar%>) /* could not cast, using the variable as it is */'
end daeExpCast;

template daeExpRecord(Exp rec, Context context, Text &preExp, Text &varDecls, SimCode simCode)
::=
  match rec
  case RECORD(__) then
  let name = tempDecl(underscorePath(path) + "Type", &varDecls)
  let ass = threadTuple(exps,comp) |>  (exp,compn) => '<%name%>.<%compn%> = <%daeExp(exp, context, &preExp, &varDecls, simCode)%>;<%\n%>'
  let &preExp += ass
  name
end daeExpRecord;

template daeExpCall(Exp call, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for a function call."
::=
  //<%name%>
  match call
  // special builtins

  case CALL(path=IDENT(name="edge"),
            expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    '_event_handling.edge(<%var1%>,"<%var1%>")'

  case CALL(path=IDENT(name="pre"),
            expLst={arg as CREF(__)}) then
    let var1 = daeExp(arg, context, &preExp, &varDecls,simCode)
    '_event_handling.pre(<%var1%>,"<%cref(arg.componentRef)%>")'

  case CALL(path=IDENT(name="sample"), expLst={ICONST(integer=index), start, interval}) then
    let &preExp = buffer "" /*BUFD*/
    let eStart = daeExp(start, contextOther, &preExp, &varDecls /*BUFD*/,simCode)
    let eInterval = daeExp(interval, contextOther, &preExp, &varDecls /*BUFD*/,simCode)
     '_time_conditions[<%intSub(index, 1)%>]'
  case CALL(path=IDENT(name="initial") ) then
     match context

    case ALGLOOP_CONTEXT(genInitialisation = false) 

        then  '_system->_initial'
    else
          '_initial'

   case CALL(path=IDENT(name="DIVISION"),
            expLst={e1, e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode)
    let var3 = Util.escapeModelicaStringToCString(printExpStr(e2))
    'division(<%var1%>,<%var2%>,"<%var3%>")'

   case CALL(path=IDENT(name="sign"),
            expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
     'sgn(<%var1%>)'

   case CALL(attr=CALL_ATTR(ty=ty as T_ARRAY(dims=dims)),
            path=IDENT(name="DIVISION_ARRAY_SCALAR"),
            expLst={e1, e2}) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "int"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "int"
                        else "double"

    let var = tempDecl('multi_array<<%type%>,<%listLength(dims)%>>', &varDecls /*BUFD*/)
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode)
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
    let &preExp += '<%retVar%> = <%cast%>pre(<%cref(arg.componentRef)%>);<%\n%>'
    '<%retVar%>'

  case CALL(path=IDENT(name="print"), expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    if acceptMetaModelicaGrammar() then 'print(<%var1%>)' else 'puts(<%var1%>)'
  
  

 case CALL(path=IDENT(name="integer"), expLst={inExp,index}) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    'boost::numeric_cast<int>(<%exp%>)'

  case CALL(path=IDENT(name="floor"), expLst={inExp,index}, attr=CALL_ATTR(ty = ty)) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    'std::floor(<%exp%>)'

  case CALL(path=IDENT(name="ceil"), expLst={inExp,index}, attr=CALL_ATTR(ty = ty)) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    'std::ceil(<%exp%>)'

  
  case CALL(path=IDENT(name="integer"), expLst={inExp}) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
   'boost::numeric_cast<int>(<%exp%>)'
  
   case CALL(path=IDENT(name="modelica_mod_int"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode)
    '<%var1%>%<%var2%>)'

  case CALL(path=IDENT(name="max"), attr=CALL_ATTR(ty = T_REAL(__)), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode)
    'max(<%var1%>,<%var2%>)'

  case CALL(path=IDENT(name="max"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode)
    'int_max((int)<%var1%>,(int)<%var2%>)'

  case CALL(attr=CALL_ATTR(ty = T_REAL(__)),
            path=IDENT(name="min"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode)
    'min(<%var1%>,<%var2%>)'

  case CALL(path=IDENT(name="min"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode)
    'int_min((int)<%var1%>,(int)<%var2%>)'

  case CALL(path=IDENT(name="abs"), expLst={e1}, attr=CALL_ATTR(ty = T_INTEGER(__))) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    'labs(<%var1%>)'

  case CALL(path=IDENT(name="abs"), expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    'fabs(<%var1%>)'

  case CALL(path=IDENT(name="sqrt"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>' ;separator=", ")
    let typeStr = expTypeShort(attr.ty )
    let retVar = tempDecl(typeStr, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = sqrt(<%argStr%>);<%\n%>'
    '<%retVar%>'

  case CALL(path=IDENT(name="sin"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'
    
     case CALL(path=IDENT(name="sinh"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

   case CALL(path=IDENT(name="cos"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'
 case CALL(path=IDENT(name="cosh"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'
   case CALL(path=IDENT(name="log"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'
   case CALL(path=IDENT(name="acos"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

   case CALL(path=IDENT(name="tan"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

    case CALL(path=IDENT(name="tanh"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

   case CALL(path=IDENT(name="atan"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

   case CALL(path=IDENT(name="atan2"),
            expLst={e1,e2},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>' ;separator=", ")

    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = std::atan2(<%argStr%>);<%\n%>'
    '<%retVar%>'
    case CALL(path=IDENT(name="smooth"),
            expLst={e1,e2},attr=attr as CALL_ATTR(__)) then
    /*let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>' ;separator=", ")

    let retType = expTypeShort(attr.ty)
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = smooth(<%argStr%>);<%\n%>'
    '<%retVar%>'
    */
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode)
    '<%var2%>'
   case CALL(path=IDENT(name="exp"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'

  case CALL(path=IDENT(name="div"), expLst={e1,e2}, attr=CALL_ATTR(ty = T_INTEGER(__))) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode)
    'ldiv(<%var1%>,<%var2%>).quot'

  case CALL(path=IDENT(name="div"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode)
    'boost::math::trunc(<%var1%>/<%var2%>)'

  case CALL(path=IDENT(name="mod"), expLst={e1,e2}, attr=attr as CALL_ATTR(__)) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode)
    'modelica_mod_<%expTypeShort(attr.ty)%>(<%var1%>,<%var2%>)'
    
   case CALL(path=IDENT(name="semiLinear"), expLst={e1,e2,e3}, attr=attr as CALL_ATTR(__)) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode)
    let var3 = daeExp(e2, context, &preExp, &varDecls,simCode)
    'semiLinear(<%var1%>,<%var2%>,<%var3%>)'

  case CALL(path=IDENT(name="max"), expLst={array}) then
    let &tmpVar = buffer "" /*BUFD*/
    let expVar = daeExp(array, context, &preExp /*BUFC*/, &tmpVar /*BUFD*/,simCode)
    let arr_tp_str = '<%expTypeFromExpArray(array)%>'
    let tvar = tempDecl(expTypeFromExpModelica(array), &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = min_max<<%arr_tp_str%>,1>(<%expVar%>).second;<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="min"), expLst={array}) then
    let &tmpVar = buffer "" /*BUFD*/
    let expVar = daeExp(array, context, &preExp /*BUFC*/, &tmpVar /*BUFD*/,simCode)
    let arr_tp_str = '<%expTypeFromExpArray(array)%>'
    let tvar = tempDecl(expTypeFromExpModelica(array), &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = min_max<<%arr_tp_str%>,1>(<%expVar%>).first;<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="fill"), expLst=val::dims, attr=attr as CALL_ATTR(__)) then
    let valExp = daeExp(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let dimsExp = (dims |> dim =>
      daeExp(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode) ;separator="][")
    let ty_str = '<%expTypeArray(attr.ty)%>'
    let tmp_type_str =  'multi_array<<%ty_str%>,<%listLength(dims)%>>'

    let tvar = tempDecl(tmp_type_str, &varDecls /*BUFD*/)

    let &varDecls += '<%tvar%>.resize((boost::extents[<%dimsExp%>]));
    <%tvar%>.reindex(1);<%\n%>'

    let &preExp += 'fill_array<<%ty_str%>,<%listLength(dims)%>>(<%tvar%>, <%valExp%>);<%\n%>'
    '<%tvar%>'
  case CALL(path=IDENT(name="$_start"), expLst={arg}) then
    daeExpCallStart(arg, context, preExp, varDecls,simCode)

  case CALL(path=IDENT(name="cat"), expLst=dim::arrays, attr=attr as CALL_ATTR(__)) then
    let dim_exp = daeExp(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let arrays_exp = (arrays |> array =>
      daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode) ;separator=", &")
    let ty_str = '<%expTypeArray(attr.ty)%>'
    let tvar = tempDecl(ty_str, &varDecls /*BUFD*/)
    let &preExp += 'cat_alloc_<%ty_str%>(<%dim_exp%>, &<%tvar%>, <%listLength(arrays)%>, &<%arrays_exp%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="promote"), expLst={A, n}) then
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let var2 = daeExp(n, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let arr_tp_str = '<%expTypeFromExpArray(A)%>'
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'promote_alloc_<%arr_tp_str%>(&<%var1%>, <%var2%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="transpose"), expLst={A}) then
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let arr_tp_str = '<%expTypeFromExpArray(A)%>'
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'transpose_alloc_<%arr_tp_str%>(&<%var1%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'

   case CALL(path=IDENT(name="cross"), expLst={v1, v2},attr=CALL_ATTR(ty=ty as T_ARRAY(dims=dims))) then
    let var1 = daeExp(v1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let var2 = daeExp(v2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then 'int'
                        case T_ARRAY(ty=T_ENUMERATION(__)) then 'int'
                        else 'double'
    let tvar = tempDecl('multi_array<<%type%>,<%listLength(dims)%>>', &varDecls /*BUFD*/)
    let &preExp += 'assign_array(<%tvar%>,cross_array<<%type%>>(<%var1%>,<%var2%>));<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="identity"), expLst={A}) then
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let arr_tp_str = '<%expTypeFromExpArray(A)%>'
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'identity_alloc_<%arr_tp_str%>(<%var1%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'

   case CALL(path=IDENT(name="rem"),
             expLst={e1, e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode)
    let typeStr = expTypeFromExpShort(e1)
    'modelica_rem_<%typeStr%>(<%var1%>,<%var2%>)'

   case CALL(path=IDENT(name="String"),
             expLst={s, format}) then
    let tvar = tempDecl("string", &varDecls /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let formatExp = daeExp(format, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let typeStr = expTypeFromExpModelica(s)
    let &preExp += '<%tvar%> = lexical_cast<std::string>(<%sExp%>);<%\n%>'
    '<%tvar%>'

   case CALL(path=IDENT(name="String"),
             expLst={s, minlen, leftjust}) then
    let tvar = tempDecl("string", &varDecls /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let minlenExp = daeExp(minlen, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let leftjustExp = daeExp(leftjust, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let typeStr = expTypeFromExpModelica(s)
    let &preExp += '<%tvar%> = lexical_cast<string>(<%sExp%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="String"),
            expLst={s, minlen, leftjust, signdig}) then
    let tvar = tempDecl("string", &varDecls /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let minlenExp = daeExp(minlen, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let leftjustExp = daeExp(leftjust, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let signdigExp = daeExp(signdig, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let &preExp += '<%tvar%> = lexical_cast<string>(<%sExp%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="delay"),
            expLst={ICONST(integer=index), e, d, delayMax}) then
    let tvar = tempDecl("double", &varDecls /*BUFD*/)
    let var1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let var2 = daeExp(d, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let var3 = daeExp(delayMax, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let &preExp += '<%tvar%> = delay(<%index%>, <%var1%>,  <%var2%>, <%var3%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="integer"),
            expLst={toBeCasted}) then
    let castedVar = daeExp(toBeCasted, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    '((int)<%castedVar%>)'

   case CALL(path=IDENT(name="Integer"),
             expLst={toBeCasted}) then
    let castedVar = daeExp(toBeCasted, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    '((int)<%castedVar%>)'

  case CALL(path=IDENT(name="clock"), expLst={}) then
    'mmc_clock()'

  case CALL(path=IDENT(name="noEvent"),
            expLst={e1}) then
    daeExp(e1, context, &preExp, &varDecls,simCode)

  case CALL(path=IDENT(name="anyString"),
            expLst={e1}) then
    'mmc_anyString(<%daeExp(e1, context, &preExp, &varDecls,simCode)%>)'

  case CALL(path=IDENT(name="mmc_get_field"),
            expLst={s1, ICONST(integer=i)}) then
    let tvar = tempDecl("modelica_metatype", &varDecls /*BUFD*/)
    let expPart = daeExp(s1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let &preExp += '<%tvar%> = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%expPart%>), <%i%>));<%\n%>'
    '<%tvar%>'

  case exp as CALL(attr=attr as CALL_ATTR(ty=T_NORETCALL(__))) then
  ""
  /*Function calls with array return type*/
  case exp as CALL(attr=attr as CALL_ATTR(ty=T_ARRAY(ty=ty,dims=dims))) then

    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = '<%funName%>RetType'
    let retVar = tempDecl(retType, &varDecls)
    let arraytpye =  'multi_array_ref<<%expTypeShort(ty)%>,<%listLength(dims)%>>'
    let &preExp += match context
                        case FUNCTION_CONTEXT(__) then 'assign_array(<%retVar%>,<%funName%>(<%argStr%>));<%\n%>'
                        else 'assign_array(<%retVar%> ,_functions.<%funName%>(<%argStr%>));<%\n%>'


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
    let argStr = (explist |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>' ;separator=", ")
    let retType = '<%funName%>RetType'
    let retVar = tempDecl(retType, &varDecls)
    let &preExp += match context case FUNCTION_CONTEXT(__) then'<%if retVar then '<%retVar%> = '%><%funName%>(<%argStr%>);<%\n%>'
    else '<%if retVar then '<%retVar%> = '%>(_functions.<%funName%>(<%argStr%>));<%\n%>'
     '<%retVar%>'


    /*match exp
      // no return calls
      case CALL(attr=CALL_ATTR(ty=T_NORETCALL(__))) then '/* NORETCALL */'
      // non tuple calls (single return value)
      case CALL(attr=CALL_ATTR(tuple_=false)) then
       if attr.builtin then '<%retVar%>' else  match ty case T_COMPLEX(__) then'(<%retVar%>)' else 'get<0>(<%retVar%>)'
      // tuple calls (multiple return values)
      case CALL(attr=CALL_ATTR(tuple_=true)) then
        '<%retVar%>'
     */

end daeExpCall;

template daeExpCallStart(Exp exp, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/,SimCode simCode)
  "Generates code for an asub of a cref, which becomes cref + offset."
::=
  match exp
  case cr as CREF(__) then
    'getStartValue(<%cref1(cr.componentRef,simCode,context)%>,"<%cref(cr.componentRef)%>")'
  case ASUB(exp = cr as CREF(__), sub = {sub_exp}) then
    let offset = daeExp(sub_exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let cref = cref1(cr.componentRef,simCode,context)
    '*(&$P$ATTRIBUTE<%cref(cr.componentRef)%>.start + <%offset%>)'
  else
    error(sourceInfo(), 'Code generation does not support start(<%printExpStr(exp)%>)')
end daeExpCallStart;

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
  expTypeFromExpFlag(exp, 3)
end expTypeFromExpArray;

template assertCommon(Exp condition, Exp message, Context context, Text &varDecls, Info info,SimCode simCode)
::=
  let &preExpCond = buffer ""
  let &preExpMsg = buffer ""
  let condVar = daeExp(condition, context, &preExpCond, &varDecls,simCode)
  let msgVar = daeExp(message, context, &preExpMsg, &varDecls,simCode)
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
  <%if msgVar then 'Assert(<%condVar%>,<%msgVar%>);' else 'Assert(<%condVar%>,"");'%>
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
                      Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for a logical unary expression."
::=
match exp
case LUNARY(__) then
  let e = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  match operator
  case NOT(__) then '(!<%e%>)'
end daeExpLunary;

template daeExpLbinary(Exp exp, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for a logical binary expression."
::=
match exp
case LBINARY(__) then
  let e1 = daeExp(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  let e2 = daeExp(exp2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  match operator
  case AND(__) then '(<%e1%> && <%e2%>)'
  case OR(__)  then '(<%e1%> || <%e2%>)'
  else "daeExpLbinary:ERR"
end daeExpLbinary;

template daeExpBinary(Operator it, Exp exp1, Exp exp2, Context context, Text &preExp,Text &varDecls /*BUFP*/, SimCode simCode) ::=
  let e1 = daeExp(exp1, context, &preExp, &varDecls, simCode)
  let e2 = daeExp(exp2, context, &preExp, &varDecls, simCode)
  match it
  case ADD(__) then '(<%e1%> + <%e2%>)'
  case SUB(__) then '(<%e1%> - <%e2%>)'
  case MUL(__) then '(<%e1%> * <%e2%>)'
  case DIV(__) then '(<%e1%> / <%e2%>)'
  case POW(__) then 'pow(<%e1%>, <%e2%>)'
  case AND(__) then '(<%e1%> && <%e2%>)'
  case OR(__)  then '(<%e1%> || <%e2%>)'
  case MUL_ARRAY_SCALAR(ty=T_ARRAY(dims=dims)) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then 'multi_array<int,<%listLength(dims)%>>'
                        case T_ARRAY(ty=T_ENUMERATION(__)) then 'multi_array<int,<%listLength(dims)%>>'
                        else 'multi_array<double,<%listLength(dims)%>>'
    let type1 = match ty case T_ARRAY(ty=T_INTEGER(__)) then "int"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "int"
                        else "double"
    //let var = tempDecl(type,&varDecls /*BUFD*/)
    let var1 = tempDecl1(type,e1,&varDecls /*BUFD*/)
    //let &preExp += '<%var1%>=multiply_array<<%type1%>,<%listLength(dims)%>>(<%e1%>, <%e2%>);<%\n%>'
    let &preExp += 'assign_array(<%var1%>,multiply_array<<%type1%>,<%listLength(dims)%>>(<%e1%>, <%e2%>));<%\n%>'
    '<%var1%>'
  case MUL_MATRIX_PRODUCT(ty=T_ARRAY(dims=dims)) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then 'multi_array<int,<%listLength(dims)%>>'
                        case T_ARRAY(ty=T_ENUMERATION(__)) then 'multi_array<int,<%listLength(dims)%>>'
                        else 'multi_array<double,<%listLength(dims)%>>'
    let type1 = match ty case T_ARRAY(ty=T_INTEGER(__)) then "int"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "int"
                        else "double"
    //let var = tempDecl(type,&varDecls /*BUFD*/)
    let var1 = tempDecl1(type,e1,&varDecls /*BUFD*/)
    let &preExp += 'assign_array(<%var1%>,multiply_array<<%type1%>,<%listLength(dims)%>>(<%e1%>, <%e2%>));<%\n%>'
    '<%var1%>'
  case DIV_ARRAY_SCALAR(ty=T_ARRAY(dims=dims)) then
  let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then 'int'
                        case T_ARRAY(ty=T_ENUMERATION(__)) then 'int'
                        else 'double'
    let var = tempDecl('multi_array<<%type%>,<%listLength(dims)%>>', &varDecls /*BUFD*/)
    //let var = tempDecl1(type,e1,&varDecls /*BUFD*/)
    let &preExp += 'assign_array(<%var%>,divide_array<<%type%>,<%listLength(dims)%>>(<%e1%>, <%e2%>));<%\n%>'
    '<%var%>'
  case DIV_SCALAR_ARRAY(ty=T_ARRAY(dims=dims)) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then 'int'
                        case T_ARRAY(ty=T_ENUMERATION(__)) then 'int'
                        else 'double'
    let var = tempDecl('multi_array<<%type%>,<%listLength(dims)%>>', &varDecls /*BUFD*/)
    //let var = tempDecl1(type,e1,&varDecls /*BUFD*/)
    //let &preExp += 'assign_array(<%var%>,divide_array<<%type%>,<%listLength(dims)%>>(<%e2%>, <%e1%>));<%\n%>'
    '<%var%>'
  case UMINUS(__) then "daeExpBinary:ERR UMINUS not supported"
  case UMINUS_ARR(__) then "daeExpBinary:ERR UMINUS_ARR not supported"

  case ADD_ARR(ty=T_ARRAY(dims=dims)) then
  let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "int"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "int"
                        else "double"
  let var = tempDecl('multi_array<<%type%>,<%listLength(dims)%>>', &varDecls /*BUFD*/)
    //let var = tempDecl1(type,e1,&varDecls /*BUFD*/)
    let &preExp += 'assign_array(<%var%>,add_array<<%type%>,<%listLength(dims)%>>(<%e1%>, <%e2%>));<%\n%>'
    '<%var%>'
  case SUB_ARR(ty=T_ARRAY(dims=dims)) then
  let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "int"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then  "int"
                        else "double"
  let var = tempDecl('multi_array<<%type%>,<%listLength(dims)%>>', &varDecls /*BUFD*/)
    //let var = tempDecl1(type,e1,&varDecls /*BUFD*/)
    let &preExp += 'assign_array(<%var%>,subtract_array<<%type%>,<%listLength(dims)%>>(<%e1%>, <%e2%>));<%\n%>'
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


template daeExpSconst(String string, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for a string constant."
::=
  '"<%Util.escapeModelicaStringToCString(string)%>"'
end daeExpSconst;

template daeExpUnary(Exp exp, Context context, Text &preExp /*BUFP*/,
                     Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for a unary expression."
::=
match exp
case UNARY(__) then
  let e = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  match operator
  case UMINUS(__)     then '(-<%e%>)'
  case UMINUS_ARR(ty=T_ARRAY(ty=T_REAL(__))) then
    let &preExp += 'usub_array<double,<%listLength(ty.dims)%>>(<%e%>);<%\n%>'
    '<%e%>'
  case UMINUS_ARR(ty=T_ARRAY(ty=T_INTEGER(__))) then
    let &preExp += 'usub_array<int,<%listLength(ty.dims)%>>(<%e%>);<%\n%>'
    '<%e%>'
  case UMINUS_ARR(__) then 'unary minus for non-real arrays not implemented'
  else "daeExpUnary:ERR"
end daeExpUnary;


template daeExpCrefRhs(Exp exp, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for a component reference on the right hand side of an
 expression."
::=
  match exp
  
   // A record cref without subscripts (i.e. a record instance) is handled
  // by daeExpRecordCrefRhs only in a simulation context, not in a function.
  case CREF(componentRef = cr, ty = t as T_COMPLEX(complexClassType = RECORD(path = _))) then
    match context case FUNCTION_CONTEXT(__) then
      '<%daeExpCrefRhs2(exp, context, &preExp, &varDecls,simCode)%>'
    else
      daeExpRecordCrefRhs(t, cr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
      
  case CREF(componentRef = cr, ty = T_FUNCTION_REFERENCE_FUNC(__)) then
    '((modelica_fnptr)boxptr_<%crefFunctionName(cr)%>)'
  case CREF(componentRef = cr, ty = T_FUNCTION_REFERENCE_VAR(__)) then
    '((modelica_fnptr) _<%crefStr(cr)%>)'
  else '<%daeExpCrefRhs2(exp, context, &preExp, &varDecls,simCode)%>'
end daeExpCrefRhs;

template daeExpRecordCrefRhs(DAE.Type ty, ComponentRef cr, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/,SimCode simCode)
::=
match ty
case T_COMPLEX(complexClassType = record_state, varLst = var_lst) then
  let vars = var_lst |> v => daeExp(makeCrefRecordExp(cr,v), context, &preExp, &varDecls,simCode)
             ;separator=", "
  let record_type_name = underscorePath(ClassInf.getStateName(record_state))
  let ret_type = '<%record_type_name%>'
  let ret_var = tempDecl(ret_type, &varDecls)
  let &preExp += '<%ret_var%> = _functions.<%record_type_name%>(<%vars%>);<%\n%>'
  '<%ret_var%>'
end daeExpRecordCrefRhs;

template daeExpCrefRhs2(Exp ecr, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for a component reference."
::=
  match ecr
  case ecr as CREF(componentRef=cr, ty=ty) then
      let box = daeExpCrefRhsArrayBox(ecr, context, &preExp, &varDecls,simCode)
    if box then
      box
    else if crefIsScalar(cr, context) then
      let cast = match ty case T_INTEGER(__) then ""
                          case T_ENUMERATION(__) then "" //else ""
      '<%cast%><%contextCref(cr,context,simCode)%>'
    else
     if crefSubIsScalar(cr) then
      // The array subscript results in a scalar
      let arrName = contextCref(crefStripLastSubs(cr), context,simCode)
      let arrayType = expTypeArray(ty)
      //let dimsLenStr = listLength(crefSubs(cr))
      let dimsValuesStr = (crefSubs(cr) |> INDEX(__) =>
          daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
        ;separator="][")
      match arrayType
        case "metatype_array" then
          'arrayGet(<%arrName%>,<%dimsValuesStr%>) /* DAE.CREF */'
        else
         <<
          <%arrName%>[<%dimsValuesStr%>]
          >>
    else
      // The array subscript denotes a slice
      let arrName = contextArrayCref(cr, context)
      let arrayType = expTypeArray(ty)
      let tmp = tempDecl(arrayType, &varDecls /*BUFD*/)
      let spec1 = daeExpCrefRhsIndexSpec(crefSubs(cr), context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
      let &preExp += 'index_alloc_<%arrayType%>(&<%arrName%>, &<%spec1%>, &<%tmp%>);<%\n%>'
      tmp
end daeExpCrefRhs2;

template daeExpCrefRhsIndexSpec(list<Subscript> subs, Context context,
                                Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode)
 "Helper to daeExpCrefRhs."
::=
  let nridx_str = listLength(subs)
  let idx_str = (subs |> sub =>
      match sub
      case INDEX(__) then
        let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
        <<
        (0), make_index_array(1, (int) <%expPart%>), 'S'

        >>
      case WHOLEDIM(__) then
        <<
        (1), (int*)0, 'W'
        >>
      case SLICE(__) then
        let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
        let tmp = tempDecl("int", &varDecls /*BUFD*/)
        let &preExp += '<%tmp%> = <%expPart%>.shape()[0]'
        <<
        (int) <%tmp%>, integer_array_make_index_array(&<%expPart%>), 'A'
        >>
    ;separator=", ")
  let tmp = tempDecl("index_spec_t", &varDecls /*BUFD*/)
  let &preExp += 'create_index_spec(&<%tmp%>, <%nridx_str%>, <%idx_str%>);<%\n%>'
  tmp
end daeExpCrefRhsIndexSpec;

template daeExpCrefRhsArrayBox(Exp ecr, Context context, Text &preExp /*BUFP*/,
                               Text &varDecls /*BUFP*/,SimCode simCode)
 "Helper to daeExpCrefRhs."
::=
match ecr
case ecr as CREF(ty=T_ARRAY(ty=aty,dims=dims)) then
  match context
  case FUNCTION_CONTEXT(__) then ''
  else
    // For context simulation and other array variables must be boxed into a real_array
    // object since they are represented only in a double array.
    let tmpArr = '<%arrayCrefCStr(ecr.componentRef,context)%>'
    tmpArr
end daeExpCrefRhsArrayBox;

template cref1(ComponentRef cr, SimCode simCode, Context context) ::=
  match cr
  case CREF_IDENT(ident = "xloc") then '<%representationCref(cr, simCode,context) %>'
  case CREF_IDENT(ident = "time") then
   match context
    case  ALGLOOP_CONTEXT(genInitialisation=false)
    then "_system->_simTime"
    else
    "_simTime"
    end match
  else '<%representationCref(cr, simCode,context) %>'
end cref1;

template representationCref(ComponentRef inCref, SimCode simCode, Context context) ::=
  cref2simvar(inCref, simCode) |> var as SIMVAR(__) =>
  match varKind
    case STATE(__)        then
        << <%representationCref1(inCref,var,simCode,context)%> >>
    case STATE_DER(__)   then
        << <%representationCref2(inCref,var,simCode,context)%> >>
    case VARIABLE(__) then
     match var 
        case SIMVAR(index=-2) then
         <<<%localcref(inCref)%> >>
    else  
        match context
            case ALGLOOP_CONTEXT(genInitialisation = false) 
                then  <<_system-><%cref(inCref)%>>>
        else
            <<<%cref(inCref)%>>>
  else  
    match context
    case ALGLOOP_CONTEXT(genInitialisation = false) 
        then  <<_system-><%cref(inCref)%>>>
    else
        <<<%cref(inCref)%>>>
end representationCref;

template representationCrefDerVar(ComponentRef inCref, SimCode simCode, Context context) ::=
  cref2simvar(inCref, simCode) |> SIMVAR(__) =>'__zDot[<%index%>]'
end representationCrefDerVar;



template representationCref1(ComponentRef inCref,SimVar var, SimCode simCode, Context context) ::=
   match var
    case SIMVAR(index=i) then
    match i
   case -1 then
   << <%cref2(inCref)%> >>
   case _  then
   << __z[<%i%>] >>
end representationCref1;

template representationCref2(ComponentRef inCref, SimVar var,SimCode simCode, Context context) ::=
 match var
case(SIMVAR(index=i)) then
  match context
         case JACOBIAN_CONTEXT() 
                then   <<<%crefWithoutIndexOperator(inCref,simCode)%>>>
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

template daeExpRelation(Exp exp, Context context, Text &preExp,Text &varDecls,SimCode simCode) 
::=
match exp
case rel as RELATION(__) then
match rel.optionExpisASUB
 case NONE() then
    daeExpRelation2(rel.operator,rel.index,rel.exp1,rel.exp2, context, preExp,varDecls,simCode)
 case SOME((exp,i,j)) then
    let e1 = daeExp(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/,simCode)
    let e2 = daeExp(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/,simCode)
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
template daeExpRelation2(Operator op, Integer index,Exp exp1, Exp exp2, Context context, Text &preExp,Text &varDecls,SimCode simCode) ::=
  let e1 = daeExp(exp1, context, &preExp, &varDecls,simCode)
  let e2 = daeExp(exp2, context, &preExp, &varDecls,simCode)
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


template daeExpIf(Exp cond, Exp then_, Exp else_, Context context, Text &preExp, Text &varDecls,SimCode simCode) ::=
  let condExp = daeExp(cond, context, &preExp, &varDecls,simCode)
  let &preExpThen = buffer ""
  let eThen = daeExp(then_, context, &preExpThen, &varDecls,simCode)
  let &preExpElse = buffer ""
  let eElse = daeExp(else_, context, &preExpElse /*BUFC*/, &varDecls /*BUFD*/,simCode)
      let condVar = tempDecl("bool", &varDecls /*BUFD*/)
      //let resVarType = expTypeFromExpArrayIf(else_,context,preExp,varDecls,simCode)
      let resVar  = expTypeFromExpArrayIf(else_,context,preExp,varDecls,simCode)
      let &preExp +=
      <<
      <%condVar%> = <%condExp%>;
      if (<%condVar%>) {
        <%preExpThen%>
        <% match typeof(then_)
            case T_ARRAY(dims=dims) then
              'assign_array(<%resVar%>,<%eThen%>);'
                else
                '<%resVar%> = <%eThen%>;'
                %>
      } else {
        <%preExpElse%>
         <%match typeof(else_)
            case T_ARRAY(dims=dims) then
              'assign_array(<%resVar%>,<%eElse%>);'
                else
                '<%resVar%> = <%eElse%>;'
        %>
      }<%\n%>
      >>
      resVar
end daeExpIf;




template expTypeFromExpArrayIf(Exp exp, Context context, Text &preExp /*BUFP*/,
                     Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for an array expression."
::=
match exp
case ARRAY(__) then
  let arrayTypeStr = expTypeArray(ty)
  let arrayDim = expTypeArrayforDim(ty)
  let &tmpdecl = buffer "" /*BUFD*/
  let arrayVar = tempDecl(arrayTypeStr, &tmpdecl /*BUFD*/)
  // let scalarPrefix = if scalar then "scalar_" else ""
  //let scalarRef = if scalar then "&" else ""
  let &tmpVar = buffer ""
  let params = (array |> e =>
    '<%daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)%>'
   ;separator=", ")
   let &preExp += '
   //tmp array
   <%arrayDim%><%arrayVar%>(boost::extents[<%listLength(array)%>]);
   <%arrayVar%>.reindex(1);'
  arrayVar
  else
    match typeof(exp)
      case ty as T_ARRAY(dims=dims) then
      let resVarType = 'multi_array<<%expTypeShort(ty)%>,<%listLength(dims)%>>'
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
  case SHARED_LITERAL(__) then expTypeFlag(ty,6)
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

template equationAlgorithm(SimEqSystem eq, Context context,Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates an equation that is an algorithm."
::=
match eq
case SES_ALGORITHM(__) then
  (statements |> stmt =>
    algStatement(stmt, context, &varDecls /*BUFD*/,simCode)
  ;separator="\n")
end equationAlgorithm;




template algStmtTupleAssign(DAE.Statement stmt, Context context,
                   Text &varDecls /*BUFP*/, SimCode simCode)
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
  let retStruct = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode)
  let lhsCrefs = (expExpLst |> cr hasindex i1 fromindex 0 =>
                    let rhsStr = 'get<<%i1%>>(<%retStruct%>.data)'
                    writeLhsCref(cr, rhsStr, context, &afterExp /*BUFC*/, &varDecls /*BUFD*/ , simCode)
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




template algStatementWhenElse(Option<DAE.Statement> stmt, Text &varDecls /*BUFP*/,SimCode simCode,Context context)
 "Helper to algStmtWhen."
::=
match stmt
case SOME(when as STMT_WHEN(__)) then
  let elseCondStr = (when.conditions |> e => ' || (<%cref1(e, simCode, context)%> && !_event_handling.pre(<%cref1(e, simCode, context)%>,"<%cref1(e, simCode, context)%>"))')
  <<
  else if (0<%elseCondStr%>) {
    <% when.statementLst |> stmt =>  algStatement(stmt, contextSimulationDiscrete,&varDecls,simCode)
       ;separator="\n"%>
  }
  <%algStatementWhenElse(when.elseWhen, &varDecls,simCode,context)%>
  >>
end algStatementWhenElse;





template writeLhsCref(Exp exp, String rhsStr, Context context, Text &preExp /*BUFP*/,
              Text &varDecls /*BUFP*/, SimCode simCode)
 "Generates code for writing a returnStructur to var."
::=
match exp
case ecr as CREF(componentRef=WILD(__)) then
  ''
case CREF(ty= t as DAE.T_ARRAY(__)) then
  let lhsStr = scalarLhsCref(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  match context
  case SIMULATION_CONTEXT(__) then
    <<
    assign_array(<%lhsStr%>,<%rhsStr%> );
    >>
  else
    '<%lhsStr%> = <%rhsStr%>;'
case UNARY(exp = e as CREF(ty= t as DAE.T_ARRAY(__))) then
  let lhsStr = scalarLhsCref(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  match context
  case SIMULATION_CONTEXT(__) then
    <<
    usub_<%expTypeShort(t)%>_array(&<%rhsStr%>);<%\n%>
    copy_<%expTypeShort(t)%>_array_data_mem(&<%rhsStr%>, &<%lhsStr%>);
    >>
  else
    '<%lhsStr%> = -<%rhsStr%>;'
case CREF(__) then
  let lhsStr = scalarLhsCref(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  <<
  <%lhsStr%> = <%rhsStr%>;
  >>
case UNARY(exp = e as CREF(__)) then
  let lhsStr = scalarLhsCref(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
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
                 let lhsstr = scalarLhsCref(lhs, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
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


template scalarLhsCref(Exp ecr, Context context, Text &preExp,Text &varDecls, SimCode simCode) ::=
match ecr
case ecr as CREF(componentRef=CREF_IDENT(subscriptLst=subs)) then
  if crefNoSub(ecr.componentRef) then
    contextCref(ecr.componentRef, context,simCode)
  else
    daeExpCrefRhs(ecr, context, &preExp, &varDecls, simCode)
case ecr as CREF(componentRef=CREF_QUAL(__)) then
    contextCref(ecr.componentRef, context,simCode)
else
    "ONLY_IDENT_OR_QUAL_CREF_SUPPORTED_SLHS"
end scalarLhsCref;






template elseExpr(DAE.Else it, Context context, Text &preExp, Text &varDecls,SimCode simCode) ::=
  match it
  case NOELSE(__) then ""
  case ELSEIF(__) then
    let &preExp = buffer ""
    let condExp = daeExp(exp, context, &preExp, &varDecls,simCode)
    <<
    else {
    <%preExp%>
    if (<%condExp%>) {
      <%statementLst |> it => algStatement(it, context, &varDecls,simCode)
      ;separator="\n"%>
    }
    <%elseExpr(else_, context, &preExp, &varDecls,simCode)%>
    }
    >>
  case ELSE(__) then
    <<
    else {
      <%statementLst |> it => algStatement(it, context, &varDecls,simCode)
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
template zeroCrossingTpl2(Integer index1, Exp relation, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates code for a zero crossing."
::=
  match relation
  case RELATION(index=zerocrossingIndex) then
    let &preExp = buffer "" /*BUFD*/
    let e1 = daeExp(exp1, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let op = zeroCrossingOpFunc(operator)
    let e2 = daeExp(exp2, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
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

    <<
     multi_array<<%expTypeShort(ty)%>,<%listLength(ty.dims)%>> <%name%>;
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
    let dims = (ty.dims |> dim => dimension(dim) ;separator=", ")
    let instDimsInit = (ty.dims |> exp =>
     dimension(exp);separator="][")
    let data = flattenArrayExpToList(lit) |> exp => literalExpConstArrayVal(exp) ; separator=", "
    match listLength(flattenArrayExpToList(lit))
    case 0 then ""
    else
    <<
      <%name%>.resize((boost::extents[<%instDimsInit%>]));
      <%name%>.reindex(1);
      <%arrayTypeStr%> <%name%>_data[]={<%data%>};
       <%name%>.assign(<%name%>_data,<%name%>_data+<%size%>);
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

template timeEventcondition1(Integer index1, Exp relation, Text &varDecls /*BUFP*/,SimCode simCode)
::=
  match relation
  case CALL(path=IDENT(name="sample"), expLst={ICONST(integer=index), start, interval}) then
    let &preExp = buffer "" /*BUFD*/
    let eStart = daeExp(start, contextOther, &preExp, &varDecls /*BUFD*/,simCode)
    let eInterval = daeExp(interval, contextOther, &preExp, &varDecls /*BUFD*/,simCode)
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

template checkConditions(list<ZeroCrossing> zeroCrossings,list<SimWhenClause> whenClauses,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let zeroCrossingsCode = checkConditions1(zeroCrossings, &varDecls /*BUFD*/, simCode)
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


template getCondition(list<ZeroCrossing> zeroCrossings,list<SimWhenClause> whenClauses,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let zeroCrossingsCode = checkConditions1(zeroCrossings, &varDecls /*BUFD*/, simCode)
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

template checkConditions1(list<ZeroCrossing> zeroCrossings, Text &varDecls /*BUFP*/,SimCode simCode)
::=

  (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 =>
    checkConditions2(i0, relation_, &varDecls /*BUFD*/,simCode)
  ;separator="\n";empty)
end checkConditions1;

template checkConditions2(Integer index1, Exp relation, Text &varDecls /*BUFP*/,SimCode simCode)
::=
  match relation
  case RELATION(index=zerocrossingIndex) then
    let &preExp = buffer "" /*BUFD*/
    let e1 = daeExp(exp1, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let op = zeroCrossingOpFunc(operator)
    let e2 = daeExp(exp2, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
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

template giveZeroFunc1(list<ZeroCrossing> zeroCrossings,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let &prexp = buffer "" /*BUFD*/
  let zeroCrossingsCode = giveZeroFunc2(zeroCrossings, &varDecls /*BUFD*/,prexp, simCode)
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

template giveZeroFunc2(list<ZeroCrossing> zeroCrossings, Text &varDecls /*BUFP*/,Text &preExp,SimCode simCode)
::=

  (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 =>
    giveZeroFunc3(i0, relation_, &varDecls /*BUFD*/,&preExp,simCode)
  ;separator="\n";empty)
end giveZeroFunc2;

template giveZeroFunc3(Integer index1, Exp relation, Text &varDecls /*BUFP*/,Text &preExp ,SimCode simCode)
::=

  match relation
  case rel as  RELATION(index=zerocrossingIndex) then
      let e1 = daeExp(exp1, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
      let e2 = daeExp(exp2, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
      match rel.operator

      case LESS(__) then
      <<
         if(_conditions[<%zerocrossingIndex%>])
                f[<%index1%>]=(<%e1%> -EPSILON - <%e2%>);
           else
                f[<%index1%>]=(<%e2%> - <%e1%> -  10*EPSILON);
       >>
      case LESSEQ(__) then
       <<
         if(_conditions[<%zerocrossingIndex%>])
                f[<%index1%>]=(<%e1%> - EPSILON - <%e2%>);
           else
                f[<%index1%>]=(<%e2%> - <%e1%> - EPSILON);
       >>
      case GREATER(__) then
       <<
         if(_conditions[<%zerocrossingIndex%>])
                f[<%index1%>]=(<%e2%> - <%e1%> - EPSILON);
           else
                f[<%index1%>]=(<%e1%> -10*EPSILON - <%e2%>);
         >>
      case GREATEREQ(__) then
        <<
         if(_conditions[<%zerocrossingIndex%>])
                f[<%index1%>]=(<%e2%> - <%e1%> - EPSILON);
           else
                f[<%index1%>]=(<%e1%> - EPSILON - <%e2%>);
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
template giveZeroFunc3(Integer index1, Exp relation, Text &varDecls /*BUFP*/,SimCode simCode)
::=
 let &preExp = buffer "" /*BUFD*/
  match relation
  case rel as  RELATION(index=zerocrossingIndex) then
       let e1 = daeExp(exp1, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
      let e2 = daeExp(exp2, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
       match rel.operator

        case LESS(__)
        case LESSEQ(__) then
       <<
         if(_event_handling.pre(_condition<%zerocrossingIndex%>,"_condition<%zerocrossingIndex%>"))
                f[<%index1%>]=(<%e1%>-EPSILON-<%e2%>);
           else
                f[<%index1%>]=(<%e2%>-<%e1%>-EPSILON);
      >>
      case GREATER(__)
      case GREATEREQ(__) then
        <<
         if(_event_handling.pre(_condition<%zerocrossingIndex%>,"_condition<%zerocrossingIndex%>"))
                f[<%index1%>]=(<%e2%>-<%e1%>-EPSILON);
           else
                f[<%index1%>]=(<%e1%>-EPSILON-<%e2%>);
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
  case c as SHARED_LITERAL(__) then expTypeFlag(c.ty, flag)
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

template checkForDiscreteEvents(list<ComponentRef> discreteModelVars,SimCode simCode)
::=

  let changediscreteVars = (discreteModelVars |> var => match var case CREF_QUAL(__) case CREF_IDENT(__) then
       'if (_event_handling.changeDiscreteVar(<%cref(var)%>,"<%cref(var)%>")) {  restart=true; }'
       ;separator="\n")
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
  bool <%lastIdentOfPath(modelInfo.name)%>::checkForDiscreteEvents()
  {
    bool restart = false;
    <%changediscreteVars%>
    return restart;
  }
  >>
end checkForDiscreteEvents;
/*
template update(list<list<SimEqSystem>> continousEquations,list<SimEqSystem> discreteEquations,list<SimWhenClause> whenClauses,list<SimEqSystem> parameterEquations,SimCode simCode)
::=
  let &varDecls = buffer "" /*BUFD*/
  let continous = (continousEquations |> eqs => (eqs |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFC*/,simCode))
    ;separator="\n")
  let paraEquations = (parameterEquations |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFD*/,simCode)
    ;separator="\n")
  let discrete = (discreteEquations |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFC*/,simCode)
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
template update( list<SimEqSystem> allEquationsPlusWhen,list<SimWhenClause> whenClauses,SimCode simCode, Context context)
::=
  let &varDecls = buffer "" /*BUFD*/
  let all_equations = (allEquationsPlusWhen |> eqs => (eqs |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFC*/,simCode))
    ;separator="\n")

  let reinit = (whenClauses |> when hasindex i0 =>
         genreinits(when, &varDecls,i0,simCode,context)
    ;separator="\n";empty)
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
 
  <<

  bool <%lastIdentOfPath(modelInfo.name)%>::evaluate(const UPDATETYPE command)

  {
    bool state_var_reinitialized = false;
    <%varDecls%>
      <%all_equations%>
    <%reinit%>
   
    return state_var_reinitialized;
  }
  >>
end update;
 /*Ranking: removed from update: if(command & IContinuous::RANKING) checkConditions();*/

template genreinits(SimWhenClause whenClauses, Text &varDecls, Integer int,SimCode simCode, Context context)
::=
  match whenClauses
    case SIM_WHEN_CLAUSE(__) then
      let helpIf = (conditions |> e => ' || (<%cref1(e, simCode, context)%> && !_event_handling.pre(<%cref1(e, simCode, context)%>, "<%cref(e)%>"))')
      let ifthen = functionWhenReinitStatementThen(reinits, &varDecls /*BUFP*/, simCode)
      let initial_assign = match initialCall
        case true then functionWhenReinitStatementThen(reinits, &varDecls /*BUFP*/, simCode)
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

template functionWhenReinitStatementThen(list<WhenOperator> reinits, Text &varDecls /*BUFP*/, SimCode simCode)
 "Generates re-init statement for when equation."
::=
  let body = (reinits |> reinit =>
    match reinit
      case REINIT(__) then
        let &preExp = buffer "" /*BUFD*/
        let val = daeExp(value, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
        <<
        state_var_reinitialized = true;
        <%preExp%>
        <%cref1(stateVar,simCode,contextOther)%> = <%val%>;
        >>
      case TERMINATE(__) then
        let &preExp = buffer "" /*BUFD*/
        let msgVar = daeExp(message, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
        <<
        <%preExp%>
        MODELICA_TERMINATE(<%msgVar%>);
        >>
      case ASSERT(source=SOURCE(info=info)) then
        assertCommon(condition, message, contextSimulationDiscrete, &varDecls, info,simCode)
    ;separator="\n")
  <<
  <%body%>
  >>
end functionWhenReinitStatementThen;

template LabeledDAE(list<String> labels, SimCode simCode) ::=
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
   <%setVariables(modelInfo)%>
}
>>
end LabeledDAE;

template setVariables(ModelInfo modelInfo)
::=
match modelInfo
case MODELINFO(vars = vars as SIMVARS(__))
then
<<
 <%{(vars.algVars |> SIMVAR(__) hasindex myindex =>
       '<%cref(name)%>=variables(<%myindex%>);'
       ;separator="\n"),
    (vars.intAlgVars |> SIMVAR(__) hasindex myindex =>
       '<%cref(name)%>=variables(<%numAlgvar(modelInfo)%>+<%myindex%>);'
       ;separator="\n"),
    (vars.boolAlgVars |> SIMVAR(__) hasindex myindex =>
       '<%cref(name)%>=variables(<%numAlgvar(modelInfo)%>+<%numIntAlgvar(modelInfo)%>+<%myindex%>);'
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


template functionAnalyticJacobians(list<JacobianMatrix> JacobianMatrixes, SimCode simCode)
 "Generates Matrixes for Linear Model."
::=
 let initialjacMats = (JacobianMatrixes |> (mat, vars, name, (sparsepattern,(_,_)), colorList, _) hasindex index0 =>
    initialAnalyticJacobians(index0, mat, vars, name, sparsepattern, colorList,simCode)
    ;separator="\n\n";empty)
 let jacMats = (JacobianMatrixes |> (mat, vars, name, (sparsepattern,(_,_)), colorList, maxColor) hasindex index0  =>
    generateMatrix(index0, mat, vars, name, sparsepattern, colorList, maxColor,simCode)
    ;separator="\n\n";empty)
<<
<%initialjacMats%>
<%jacMats%>
>>

end functionAnalyticJacobians;





template functionJac(list<SimEqSystem> jacEquations, list<SimVar> tmpVars, String columnLength, String matrixName, Integer indexJacobian, SimCode simCode)
 "Generates function in simulation file."
::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  let classname =  lastIdentOfPath(modelInfo.name)

  let &varDecls = buffer "" /*BUFD*/
  let &tmp = buffer ""
  let eqns_ = (jacEquations |> eq =>
      equation_(eq, contextJacobian, &varDecls /*BUFD*/, /*&tmp*/ simCode)
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


template generateMatrix(Integer indexJacobian, list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String matrixname, list<tuple<DAE.ComponentRef,list<DAE.ComponentRef>>> sparsepattern, list<list<DAE.ComponentRef>>colorList, Integer maxColor, SimCode simCode)
 "Generates Matrixes for Linear Model."
::=

   match simCode
   case SIMCODE(modelInfo = MODELINFO(__)) then
         generateJacobianMatrix(modelInfo,indexJacobian, jacobianColumn, seedVars, matrixname, sparsepattern, colorList, maxColor, simCode)
   end match
 
  
end generateMatrix;





template generateJacobianMatrix(ModelInfo modelInfo,Integer indexJacobian, list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String matrixName, list<tuple<DAE.ComponentRef,list<DAE.ComponentRef>>> sparsepattern, list<list<DAE.ComponentRef>>colorList, Integer maxColor, SimCode simCode)
 "Generates Matrixes for Linear Model."
::=
match modelInfo
case MODELINFO(__) then
let classname =  lastIdentOfPath(name)
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
    functionJac(eqs, vars, indxColumn, matrixName, indexJacobian,simCode)
    ;separator="\n")
 let indexColumn = (jacobianColumn |> (eqs,vars,indxColumn) =>
    indxColumn
    ;separator="\n")
 
    let jacvals = ( sparsepattern |> (cref,indexes) hasindex index0 =>
    let jaccol = ( indexes |> i_index =>
        (match indexColumn case "1" then ' _<%matrixName%>jacobian(<%crefWithoutIndexOperator(cref,simCode)%>$pDER<%matrixName%>$indexdiff,0) = _<%matrixName%>jac_y(0);'
           else ' _<%matrixName%>jacobian(<%index0%>,<%crefWithoutIndexOperator(cref,simCode)%>$pDER<%matrixName%>$indexdiff) = _<%matrixName%>jac_y(<%crefWithoutIndexOperator(cref,simCode)%>$pDER<%matrixName%>$indexdiff);'
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
 

  
  
end generateJacobianMatrix;



template variableDefinitionsJacobians(list<JacobianMatrix> JacobianMatrixes,SimCode simCode)
 "Generates defines for jacobian vars."
::=

  let analyticVars = (JacobianMatrixes |> (jacColumn, seedVars, name, (_,(diffVars,diffedVars)), _, _) hasindex index0 =>
    let varsDef = variableDefinitionsJacobians2(index0, jacColumn, seedVars, name,simCode)
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
    jacobianVarDefine(var, "jacobianVarsSeed", indexJacobian, index0,name,simCode)
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
      #define <%crefWithoutIndexOperator(name,simCode)%> _<%matrixName%>jac_tmp(<%index0%>)
      >>
    case _ then
      <<
      #define <%crefWithoutIndexOperator(name,simCode)%> _<%matrixName%>jac_y(<%index%>)
      >>
    end match
  end match
case "jacobianVarsSeed" then
  match simVar
  case SIMVAR(aliasvar=NOALIAS()) then
  let tmp = System.tmpTick()
    <<
    #define <%crefWithoutIndexOperator(name,simCode)%>$pDER<%matrixName%>$P<%crefWithoutIndexOperator(name,simCode)%> _<%matrixName%>jac_x(<%index0%>)
    >>
  end match
end jacobianVarDefine;




template defineSparseIndexes(list<SimVar> diffVars, list<SimVar> diffedVars, String matrixName,SimCode simCode) "template variableDefinitionsJacobians2
  Generates Matrixes for Linear Model."
::=
  let diffVarsResult = (diffVars |> var as SIMVAR(name=name) hasindex index0 =>
     '#define <%crefWithoutIndexOperator(name,simCode)%>$pDER<%matrixName%>$indexdiff <%index0%>'
    ;separator="\n")
    let diffedVarsResult = (diffedVars |> var as SIMVAR(name=name) hasindex index0 =>
     '#define <%crefWithoutIndexOperator(name,simCode)%>$pDER<%matrixName%>$indexdiffed <%index0%>'
    ;separator="\n")
   /* generate at least one print command to have the same index and avoid the strange side effect */
  <<
  /* <%matrixName%> sparse indexes */
   <%diffVarsResult%>
   <%diffedVarsResult%>
  >>

end defineSparseIndexes;


//Generation of Algorithm section
template algStatement(DAE.Statement stmt, Context context, Text &varDecls,SimCode simCode)
::=
  let res = match stmt
  case s as STMT_ASSIGN(exp1=PATTERN(__)) then "STMT_ASSIGN Pattern not supported yet"
  case s as STMT_ASSIGN(__)         then algStmtAssign(s, context, &varDecls /*BUFD*/,simCode)
  case s as STMT_ASSIGN_ARR(__)     then algStmtAssignArr(s, context, &varDecls /*BUFD*/,simCode)
  case s as STMT_TUPLE_ASSIGN(__)   then algStmtTupleAssign(s, context, &varDecls /*BUFD*/,simCode)
  case s as STMT_IF(__)             then algStmtIf(s, context, &varDecls /*BUFD*/,simCode)
  case s as STMT_FOR(__)            then algStmtFor(s, context, &varDecls /*BUFD*/,simCode)
  case s as STMT_WHILE(__)           then algStmtWhile(s, context, &varDecls /*BUFD*/,simCode)
  case s as STMT_ASSERT(__)         then algStmtAssert(s, context, &varDecls ,simCode)
  case s as STMT_TERMINATE(__)      then algStmtTerminate(s, context, &varDecls /*BUFD*/,simCode)
  case s as STMT_WHEN(__)           then algStmtWhen(s, context, &varDecls ,simCode)
  case s as STMT_BREAK(__)          then 'break;<%\n%>'
  case s as STMT_FAILURE(__)        then "STMT FAILURE"
  case s as STMT_TRY(__)            then "STMT TRY"
  case s as STMT_CATCH(__)          then "STMT CATCH"
  case s as STMT_THROW(__)          then "STMT THROW"
  case s as STMT_RETURN(__)         then "break;/*Todo stmt return*/"
  case s as STMT_NORETCALL(__)      then algStmtNoretcall(s, context, &varDecls /*BUFD*/,simCode)
  case s as STMT_REINIT(__)         then algStmtReinit(s, context, &varDecls /*BUFD*/,simCode)
  else error(sourceInfo(), 'ALG_STATEMENT NYI')
  
  <<
  <%modelicaLine(getElementSourceFileInfo(getStatementSource(stmt)))%>
  <%res%>
  <%endModelicaLine()%>
  >>

end algStatement;

template algStmtWhile(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates a while algorithm statement."
::=
match stmt
case STMT_WHILE(__) then
  let &preExp = buffer "" /*BUFD*/
  let var = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  <<
  while (1) {
    <%preExp%>
    if (!<%var%>) break;
    <%statementLst |> stmt => algStatement(stmt, context, &varDecls /*BUFD*/,simCode) ;separator="\n"%>
  }
  >>
end algStmtWhile;

template algStmtTerminate(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates an assert algorithm statement."
::=
match stmt
case STMT_TERMINATE(__) then
  let &preExp = buffer "" /*BUFD*/
  let msgVar = daeExp(msg, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  <<
  <%preExp%>
  Terminate(<%msgVar%>);
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

template algStmtAssign(DAE.Statement stmt, Context context, Text &varDecls, SimCode simCode)
 "Generates an assigment algorithm statement."
::=
  match stmt
  case STMT_ASSIGN(exp1=CREF(componentRef=WILD(__)), exp=e) then
    let &preExp = buffer "" /*BUFD*/
    let expPart = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    <<
    <%preExp%>
    >>
  case STMT_ASSIGN(exp1=CREF(ty = T_FUNCTION_REFERENCE_VAR(__)))
  case STMT_ASSIGN(exp1=CREF(ty = T_FUNCTION_REFERENCE_FUNC(__))) then
    let &preExp = buffer "" /*BUFD*/
    let varPart = scalarLhsCref(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    <<
    <%preExp%>
    <%varPart%> = (modelica_fnptr) <%expPart%>;
    >>
    /* Records need to be traversed, assigning each component by itself */
  case STMT_ASSIGN(exp1=CREF(componentRef=cr,ty = T_COMPLEX(varLst = varLst, complexClassType=RECORD(__)))) then
    let &preExp = buffer ""
    let rec = daeExp(exp, context, &preExp, &varDecls,simCode)
    <<
    <%preExp%>
    <% varLst |> var as TYPES_VAR(__) =>
      match var.ty
      case T_ARRAY(__) then
        copyArrayData(var.ty, '<%rec%>.<%var.name%>', appendStringCref(var.name,cr), context)
      else
        let varPart = contextCref(appendStringCref(var.name,cr),context,simCode)
        '<%varPart%> = <%rec%>.<%var.name%>;'
    ; separator="\n"
    %>
    >>
  case STMT_ASSIGN(exp1=CALL(path=path,expLst=expLst,attr=CALL_ATTR(ty= T_COMPLEX(varLst = varLst, complexClassType=RECORD(__))))) then
    let &preExp = buffer ""
    let rec = daeExp(exp, context, &preExp, &varDecls,simCode)
    <<
    <%preExp%>
    <% varLst |> var as TYPES_VAR(__) hasindex i1 fromindex 1 =>
      let re = daeExp(listNth(expLst,i1), context, &preExp, &varDecls,simCode)
      '<%re%> = <%rec%>.<%var.name%>;'
    ; separator="\n"
    %>
    Record = func;
    >>
  case STMT_ASSIGN(exp1=CREF(__)) then
    let &preExp = buffer "" /*BUFD*/
    let varPart = scalarLhsCref(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
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
        let arr1 = daeExp(arr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
        let idx1 = daeExp(idx, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
        let val1 = daeExp(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
        <<
        <%preExp%>
        arrayUpdate(<%arr1%>,<%idx1%>,<%val1%>);
        >>)
        // Modelica Array
      else
        let &preExp = buffer "" /*BUFD*/
        let varPart = daeExpAsub(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
        let expPart = daeExp(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
        <<
        <%preExp%>
        <%varPart%> = <%expPart%>;
        >>
    )
  case STMT_ASSIGN(__) then
    let &preExp = buffer "" /*BUFD*/
    let expPart1 = daeExp(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let expPart2 = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    <<
    <%preExp%>
    <%expPart1%> = <%expPart2%>;
    >>
end algStmtAssign;

template copyArrayData(DAE.Type ty, String exp, DAE.ComponentRef cr,
  Context context)

::=
  let type = expTypeArray(ty)
  let cref = contextArrayCref(cr, context)
  match context
  case FUNCTION_CONTEXT(__) then
    'assign_array(<%cref%>,<%exp%>);'
  else
    'assign_array(<%cref%>,<%exp%>);'
end copyArrayData;

template algStmtWhen(DAE.Statement when, Context context, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates a when algorithm statement."
::=
match context
case SIMULATION_CONTEXT(__) then
  match when
  case STMT_WHEN(__) then
    let helpIf = (conditions |> e => ' || (<%cref1(e, simCode, context)%> && !_event_handling.pre(<%cref1(e, simCode, context)%>,"<%cref(e)%>"))')
    let statements = (statementLst |> stmt =>
        algStatement(stmt, context, &varDecls /*BUFD*/,simCode)
      ;separator="\n")
    let else = algStatementWhenElse(elseWhen, &varDecls /*BUFD*/,simCode,context)
    <<
    if (0<%helpIf%>) {
      <%statements%>
    }
    <%else%>
    >>
   end match
end match
end algStmtWhen;


template algStmtAssert(DAE.Statement stmt, Context context, Text &varDecls,SimCode simCode)
 "Generates an assert algorithm statement."
::=
match stmt
case STMT_ASSERT(source=SOURCE(info=info)) then
  assertCommon(cond, msg, context, &varDecls, info,simCode)
end algStmtAssert;


template algStmtReinit(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates an assigment algorithm statement."
::=
  match stmt
  case STMT_REINIT(__) then
    let &preExp = buffer "" /*BUFD*/
    let expPart1 = daeExp(var, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
    let expPart2 = daeExp(value, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
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

template algStmtIf(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates an if algorithm statement."
::=
match stmt
case STMT_IF(__) then
  let &preExp = buffer "" /*BUFD*/
  let condExp = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  <<
  <%preExp%>
  if (<%condExp%>) {
    <%statementLst |> stmt => algStatement(stmt, context, &varDecls /*BUFD*/,simCode) ;separator="\n"%>
  }
   <%elseExpr(else_, context,&preExp , &varDecls /*BUFD*/,simCode)%>
  >>
end algStmtIf;


template algStmtFor(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates a for algorithm statement."
::=
  match stmt
  case s as STMT_FOR(range=rng as RANGE(__)) then
    algStmtForRange(s, context, &varDecls /*BUFD*/,simCode)
  case s as STMT_FOR(__) then
    algStmtForGeneric(s, context, &varDecls /*BUFD*/,simCode)
end algStmtFor;

template algStmtForGeneric(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates a for algorithm statement where range is not RANGE."
::=
match stmt
case STMT_FOR(__) then
  let iterType = expType(type_, iterIsArray)
  let arrayType = expTypeArray(type_)


  let stmtStr = (statementLst |> stmt =>
    algStatement(stmt, context, &varDecls,simCode) ;separator="\n")
  algStmtForGeneric_impl(range, iter, iterType, arrayType, iterIsArray, stmtStr,
    context, &varDecls,simCode)
end algStmtForGeneric;






template algStmtForGeneric_impl(Exp exp, Ident iterator, String type,
  String arrayType, Boolean iterIsArray, Text &body, Context context, Text &varDecls,SimCode simCode)
 "The implementation of algStmtForGeneric, which is also used by daeExpReduction."
::=
  let iterName = contextIteratorName(iterator, context)
  //let stateVar = if not acceptMetaModelicaGrammar() then tempDecl("state", &varDecls)
  //let tvar = tempDecl("int", &varDecls)
  //let ivar = tempDecl(type, &varDecls)
  let &preExp = buffer ""
  let &tmpVar = buffer ""
  let evar = daeExp(exp, context, &preExp, &tmpVar,simCode)
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

template algStmtNoretcall(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates a no return call algorithm statement."
::=
match stmt
case STMT_NORETCALL(__) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  <<
  //No retcall
  <%preExp%>
  <%expPart%>;
  >>
end algStmtNoretcall;

template algStmtForRange(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/,SimCode simCode)
 "Generates a for algorithm statement where range is RANGE."
::=
match stmt
case STMT_FOR(range=rng as RANGE(__)) then
  let identType = expType(type_, iterIsArray)
  let identTypeShort = expTypeShort(type_)
  let stmtStr = (statementLst |> stmt => algStatement(stmt, context, &varDecls,simCode)
                 ;separator="\n")
  algStmtForRange_impl(rng, iter, identType, identTypeShort, stmtStr, context, &varDecls,simCode)
end algStmtForRange;




template algStmtForRange_impl(Exp range, Ident iterator, String type, String shortType, Text body, Context context, Text &varDecls,SimCode simCode)
 "The implementation of algStmtForRange, which is also used by daeExpReduction."
::=
match range
case RANGE(__) then
  let iterName = contextIteratorName(iterator, context)
  let startVar = tempDecl(type, &varDecls)
  let stepVar = tempDecl(type, &varDecls)
  let stopVar = tempDecl(type, &varDecls)
  let &preExp = buffer ""
  let startValue = daeExp(start, context, &preExp, &varDecls,simCode)
  let stepValue = match step case SOME(eo) then
      daeExp(eo, context, &preExp, &varDecls,simCode)
    else
      "(1)"
  let stopValue = daeExp(stop, context, &preExp, &varDecls,simCode)
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
                 Text &varDecls /*BUFP*/,SimCode simCode)
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
  let expPart = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode)
  /*let ispec = indexSpecFromCref(cr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  if ispec then
    <<
    STMT_ASSIGN_ARR CALL ispec
    <%preExp%>
    indexedAssign(t, expPart, cr, ispec, context, &varDecls)
    >>
  else*/
  let cref = contextArrayCref(cr, context)
    <<
     <%preExp%>
       assign_array(<%cref%>,<%expPart%>);
    >>
case STMT_ASSIGN_ARR(exp=e, componentRef=cr, type_=t) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode)
  /*let ispec = indexSpecFromCref(cr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
  if ispec then
    <<
    STMT_ASSIGN_ARR cr ispec
    <%preExp%>
    indexedAssign(t, expPart, cr, ispec, context, &varDecls)
    >>
  else*/
    <<
    <%preExp%>
    assign_array(<%contextArrayCref(cr, context)%>,<%expPart%>);
    >>
end algStmtAssignArr;

template indexSpecFromCref(ComponentRef cr, Context context, Text &preExp /*BUFP*/,
                  Text &varDecls /*BUFP*/,SimCode simCode)
 "Helper to algStmtAssignArr.
  Currently works only for CREF_IDENT." ::=
match cr
case CREF_IDENT(subscriptLst=subs as (_ :: _)) then
  daeExpCrefRhsIndexSpec(subs, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
end indexSpecFromCref;




template functionInitDelay(DelayedExpression delayed,SimCode simCode)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
   let &preExp = buffer "" /*BUFD*/
  let delay_id = (match delayed case DELAYED_EXPRESSIONS(__) then (delayedExps |> (id, (e, d, delayMax)) =>
     '<%id%>';separator=","))
  let delay_max = (match delayed case DELAYED_EXPRESSIONS(__) then (delayedExps |> (id, (e, d, delayMax)) =>
      let delayExpMax = daeExp(delayMax, contextSimulationNonDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
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


template functionStoreDelay(DelayedExpression delayed,SimCode simCode)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
   let storePart = (match delayed case DELAYED_EXPRESSIONS(__) then (delayedExps |> (id, (e, d, delayMax)) =>
      let &preExp = buffer "" /*BUFD*/
      let eRes = daeExp(e, contextSimulationNonDiscrete,
                      &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode)
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

template giveVariables(ModelInfo modelInfo)
 "Define Memeber Function getReal off Cpp Target"
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<

  void <%lastIdentOfPath(name)%>::getReal(double* z)
  {
    <%listAppend( vars.algVars, vars.paramVars ) |>
        var hasindex i0 fromindex 0 => giveVariablesDefault(var, i0)
        ;separator="\n"%>
  }

  void <%lastIdentOfPath(name)%>::getInteger(int* z)
  {
    <%listAppend( listAppend( vars.intAlgVars, vars.intParamVars ), vars.intAliasVars ) |>
        var hasindex i0 fromindex 0 => giveVariablesDefault(var, i0)
        ;separator="\n"%>
  }

  void <%lastIdentOfPath(name)%>::getBoolean(bool* z)
  {
    <%listAppend( listAppend( vars.boolAlgVars, vars.boolParamVars ), vars.boolAliasVars ) |>
        var hasindex i0 fromindex 0 => giveVariablesDefault(var, i0)
        ;separator="\n"%>
  }
  
  void <%lastIdentOfPath(name)%>::getString(string* z)
  {
  /*
  <%System.tmpTickReset(0)%>
  <%vars.stringAlgVars |> var => giveVariablesDefault(var, System.tmpTick()) ;separator="\n"%>
  <%vars.stringParamVars |> var => giveVariablesDefault(var, System.tmpTick()) ;separator="\n"%>
  <%vars.stringAliasVars |> var => giveVariablesDefault(var, System.tmpTick()) ;separator="\n"%>
  */
  }
  
  void <%lastIdentOfPath(name)%>::setReal(const double* z)
  {
    <%listAppend(vars.algVars, vars.paramVars) |>
        var hasindex i0 fromindex 0 => setVariablesDefault(var, i0)
        ;separator="\n"%>
  }

  void <%lastIdentOfPath(name)%>::setInteger(const int* z)
  {
    <%listAppend( listAppend( vars.intAlgVars, vars.intParamVars ), vars.intAliasVars ) |>
        var hasindex i0 fromindex 0 => setVariablesDefault(var, i0)
        ;separator="\n"%>
  }

  void <%lastIdentOfPath(name)%>::setBoolean(const bool* z)
  {
    <%listAppend( listAppend( vars.boolAlgVars, vars.boolParamVars ), vars.boolAliasVars ) |>
        var hasindex i0 fromindex 0 => setVariablesDefault(var, i0)
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

template giveVariablesDefault(SimVar simVar, Integer valueReference)
 "Generates code for getting variables in cpp target for use in FMU. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  <<
  z[<%valueReference%>] = <%cref(name)%>; <%description%>
  >>
end giveVariablesDefault;

template setVariablesDefault(SimVar simVar, Integer valueReference)
 "Generates code for getting variables in cpp target for use in FMU. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  let variablename = cref(name)
  match causality
    case INPUT() then 
      <<
      <%variablename%> = z[<%valueReference%>]; <%description%>
      >>
   
  end match
end setVariablesDefault;

template crefWithoutIndexOperator(ComponentRef cr,SimCode simCode)
 "Generates C equivalent name for component reference."
::=
   match cr
    case CREF_IDENT(ident = "xloc") then crefStr(cr)
    case CREF_IDENT(ident = "time") then "time"
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


end CodegenCpp;

