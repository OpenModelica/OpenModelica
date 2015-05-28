#pragma once
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h"



/*****************************************************************************
*
* Simulation code to initialize the Modelica system
*
*****************************************************************************/

class CauerLowPassSCJacobian : virtual public CauerLowPassSC
{
public:
  CauerLowPassSCJacobian(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars);
  virtual ~CauerLowPassSCJacobian();
  
protected:
  void initialize();
  void calcDJacobianColumn();
  void getDJacobian(SparseMatrix& matrix);
  /*needed for colored Jacs*/
  void calcCJacobianColumn();
  void getCJacobian(SparseMatrix& matrix);
  /*needed for colored Jacs*/
  void calcBJacobianColumn();
  void getBJacobian(SparseMatrix& matrix);
  /*needed for colored Jacs*/
  void calcAJacobianColumn();
  void getAJacobian(SparseMatrix& matrix);
  /*needed for colored Jacs*/

  private:
    SparseMatrix _Djacobian;
    ublas::vector<double> _Djac_y;
    ublas::vector<double> _Djac_tmp;
    ublas::vector<double> _Djac_x;
    
  public:
    /*needed for colored Jacs*/
    int* _DColorOfColumn;
    int  _DMaxColors;
  private:
    SparseMatrix _Cjacobian;
    ublas::vector<double> _Cjac_y;
    ublas::vector<double> _Cjac_tmp;
    ublas::vector<double> _Cjac_x;
    
  public:
    /*needed for colored Jacs*/
    int* _CColorOfColumn;
    int  _CMaxColors;
  private:
    SparseMatrix _Bjacobian;
    ublas::vector<double> _Bjac_y;
    ublas::vector<double> _Bjac_tmp;
    ublas::vector<double> _Bjac_x;
    
  public:
    /*needed for colored Jacs*/
    int* _BColorOfColumn;
    int  _BMaxColors;
  private:
    SparseMatrix _Ajacobian;
    ublas::vector<double> _Ajac_y;
    ublas::vector<double> _Ajac_tmp;
    ublas::vector<double> _Ajac_x;
    
  public:
    /*needed for colored Jacs*/
    int* _AColorOfColumn;
    int  _AMaxColors;

  /* Jacobian Variables */
  
  
  
  double& _C1_vSeedA;
  double& _C2_vSeedA;
  double& _C3_vSeedA;
  double& _C4_vSeedA;
  double& _C7_vSeedA;
  double& _R1_Capacitor1_vSeedA;
  double& _R10_Capacitor1_vSeedA;
  double& _R11_Capacitor1_vSeedA;
  double& _R2_Capacitor1_vSeedA;
  double& _R3_Capacitor1_vSeedA;
  double& _R4_Capacitor1_vSeedA;
  double& _R5_Capacitor1_vSeedA;
  double& _R7_Capacitor1_vSeedA;
  double& _R8_Capacitor1_vSeedA;
  double& _R9_Capacitor1_vSeedA;
  double& _Rp1_Capacitor1_vSeedA;
  
  
  
  /*testmaessig aus der Cruntime*/
void initializeColoredJacobianA();

  };