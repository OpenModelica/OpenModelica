#pragma once

/*****************************************************************************
*
* Simulation code to initialize the Modelica system
*
*****************************************************************************/

class BouncingBallInitialize : virtual public BouncingBall
{
public:
  BouncingBallInitialize(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars);
  virtual ~BouncingBallInitialize();
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

   void initializeExternalVar();
  void initializeAlgVars();
  void initializeDiscreteAlgVars();
  
  void initializeIntAlgVars_0();
  
  void initializeIntAlgVars();
  void initializeBoolAlgVars();
  
  void initializeStringAliasVars();
  void initializeAliasVars();
  void initializeIntAliasVars();
  void initializeBoolAliasVars();
  
  void initializeParameterVars_0();
  void initializeParameterVars();
  void initializeIntParameterVars();
  void initializeBoolParameterVars();
  void initializeStringParameterVars();
  void initializeStateVars();
  void initializeDerVars();
  
  /*extraFuncs*/
};