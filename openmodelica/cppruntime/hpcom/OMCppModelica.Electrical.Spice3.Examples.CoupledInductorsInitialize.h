#pragma once

/*****************************************************************************
*
* Simulation code to initialize the Modelica system
*
*****************************************************************************/

class CoupledInductorsInitialize : virtual public CoupledInductors
{
public:
  CoupledInductorsInitialize(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars);
  virtual ~CoupledInductorsInitialize();
  virtual bool initial();
  virtual void setInitial(bool);
  virtual void initialize();
  virtual void initializeMemory();
  virtual void initializeFreeVariables();
  virtual void initializeBoundVariables();
  virtual void initEquations();
  
private:
  /*! Index of the first equation. We use this to calculate the offset of an equation in the
     equation array given the index of the equation.*/
   int first_equation_index;
    /*! Equations*/
    FORCE_INLINE void initEquation_1();
    /*! Equations*/
    FORCE_INLINE void initEquation_2();
    /*! Equations*/
    FORCE_INLINE void initEquation_3();
    /*! Equations*/
    FORCE_INLINE void initEquation_4();
    /*! Equations*/
    FORCE_INLINE void initEquation_5();
    /*! Equations*/
    FORCE_INLINE void initEquation_6();
    /*! Equations*/
    FORCE_INLINE void initEquation_7();
    /*! Equations*/
    FORCE_INLINE void initEquation_8();
    /*! Equations*/
    FORCE_INLINE void initEquation_9();
    /*! Equations*/
    FORCE_INLINE void initEquation_10();
    /*! Equations*/
    FORCE_INLINE void initEquation_11();
    /*! Equations*/
    FORCE_INLINE void initEquation_12();
    /*! Equations*/
    FORCE_INLINE void initEquation_13();
    /*! Equations*/
    FORCE_INLINE void initEquation_14();
    /*! Equations*/
    FORCE_INLINE void initEquation_15();
    /*! Equations*/
    FORCE_INLINE void initEquation_16();
    /*! Equations*/
    FORCE_INLINE void initEquation_17();
    /*! Equations*/
    FORCE_INLINE void initEquation_18();
    /*! Equations*/
    FORCE_INLINE void initEquation_19();
    /*! Equations*/
    FORCE_INLINE void initEquation_20();
    /*! Equations*/
    FORCE_INLINE void initEquation_21();
    /*! Equations*/
    FORCE_INLINE void initEquation_22();
    /*! Equations*/
    FORCE_INLINE void initEquation_23();
    /*! Equations*/
    FORCE_INLINE void initEquation_24();
    /*! Equations*/
    FORCE_INLINE void initEquation_25();
    /*! Equations*/
    FORCE_INLINE void initEquation_26();
    /*! Equations*/
    FORCE_INLINE void initEquation_27();
    /*! Equations*/
    FORCE_INLINE void initEquation_28();
    /*! Equations*/
    FORCE_INLINE void initEquation_29();
    /*! Equations*/
    FORCE_INLINE void initEquation_30();
    /*! Equations*/
    FORCE_INLINE void initEquation_31();
    /*! Equations*/
    FORCE_INLINE void initEquation_32();
    /*! Equations*/
    FORCE_INLINE void initEquation_33();
    /*! Equations*/
    FORCE_INLINE void initEquation_34();
    /*! Equations*/
    FORCE_INLINE void initEquation_35();
    /*! Equations*/
    FORCE_INLINE void initEquation_36();
    /*! Equations*/
    FORCE_INLINE void initEquation_37();
    /*! Equations*/
    FORCE_INLINE void initEquation_38();

  void initializeAlgVars_0();
   void initializeExternalVar();
  void initializeAlgVars();
  void initializeDiscreteAlgVars();
  
  
  void initializeIntAlgVars();
  void initializeBoolAlgVars();
  
  void initializeAliasVars_0();
  void initializeStringAliasVars();
  void initializeAliasVars();
  void initializeIntAliasVars();
  void initializeBoolAliasVars();
  
  void initializeParameterVars_0();
  void initializeBoolParameterVars_0();
  void initializeParameterVars();
  void initializeIntParameterVars();
  void initializeBoolParameterVars();
  void initializeStringParameterVars();
  void initializeStateVars();
  void initializeDerVars();
  
  /*extraFuncs*/
};