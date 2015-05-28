#pragma once

/*****************************************************************************
*
* Simulation code to initialize the Modelica system
*
*****************************************************************************/

class BouncingBallJacobian : virtual public BouncingBall
{
public:
  BouncingBallJacobian(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars);
  virtual ~BouncingBallJacobian();
  
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
  
  
  
  double& _hSeedA;
  double& _vSeedA;
  
  
  
  /*testmaessig aus der Cruntime*/
void initializeColoredJacobianA();

  };