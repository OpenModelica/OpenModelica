
CoupledInductorsJacobian::CoupledInductorsJacobian(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
    : CoupledInductors(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
    , _AColorOfColumn(NULL)
     
     
     
     ,_C1_vinternalSeedA( _Ajac_x(0))
     ,_C2_vinternalSeedA( _Ajac_x(1))
     ,_L1_iinternalSeedA( _Ajac_x(2))
     ,_L2_iinternalSeedA( _Ajac_x(3))
     ,_L3_iinternalSeedA( _Ajac_x(4))
      ,_Ajacobian(SparseMatrix(5,5,19))
      ,_Ajac_y(ublas::zero_vector<double>(5))
      ,_Ajac_tmp(ublas::zero_vector<double>(0))
      ,_Ajac_x(ublas::zero_vector<double>(5))
{
}

CoupledInductorsJacobian::~CoupledInductorsJacobian()
{
if(_AColorOfColumn)
  delete []  _AColorOfColumn;
}


void CoupledInductorsJacobian::calcDJacobianColumn()
{
}

void CoupledInductorsJacobian::getDJacobian(SparseMatrix& matrix)
{
}

void CoupledInductorsJacobian::calcCJacobianColumn()
{
}

void CoupledInductorsJacobian::getCJacobian(SparseMatrix& matrix)
{
}

void CoupledInductorsJacobian::calcBJacobianColumn()
{
}

void CoupledInductorsJacobian::getBJacobian(SparseMatrix& matrix)
{
}

void CoupledInductorsJacobian::calcAJacobianColumn()
{
}

void CoupledInductorsJacobian::getAJacobian(SparseMatrix& matrix)
{

  _Ajac_x(0) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(0,0) = _Ajac_y(0);/*test20,0*/
  _Ajacobian(0,2) = _Ajac_y(2);/*test20,1*/
  _Ajacobian(0,3) = _Ajac_y(3);/*test20,2*/
  _Ajacobian(0,4) = _Ajac_y(4);/*test20,3*/
  _Ajac_x(1) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(1,1) = _Ajac_y(1);/*test21,0*/
  _Ajacobian(1,2) = _Ajac_y(2);/*test21,1*/
  _Ajacobian(1,3) = _Ajac_y(3);/*test21,2*/
  _Ajacobian(1,4) = _Ajac_y(4);/*test21,3*/
  _Ajac_x(2) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(2,2) = _Ajac_y(2);/*test22,0*/
  _Ajacobian(2,3) = _Ajac_y(3);/*test22,1*/
  _Ajacobian(2,4) = _Ajac_y(4);/*test22,2*/
  _Ajac_x(3) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(3,0) = _Ajac_y(0);/*test23,0*/
  _Ajacobian(3,2) = _Ajac_y(2);/*test23,1*/
  _Ajacobian(3,3) = _Ajac_y(3);/*test23,2*/
  _Ajacobian(3,4) = _Ajac_y(4);/*test23,3*/
  _Ajac_x(4) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(4,1) = _Ajac_y(1);/*test24,0*/
  _Ajacobian(4,2) = _Ajac_y(2);/*test24,1*/
  _Ajacobian(4,3) = _Ajac_y(3);/*test24,2*/
  _Ajacobian(4,4) = _Ajac_y(4);/*test24,3*/
  matrix = _Ajacobian;
}

void CoupledInductorsJacobian::initialize()
{
   //create Algloopsolver for analytical Jacobians
      
      
      
   //initialize Algloopsolver for analytical Jacobians

}

//testmaessig aus der cruntime
/* Jacobians */


void CoupledInductorsJacobian::initializeColoredJacobianA()
{
  if(_AColorOfColumn)
    delete [] _AColorOfColumn;
  _AColorOfColumn = new int[5];
  _AMaxColors = 5;
  
  /* write color array */
  _AColorOfColumn[1] = 1; 
  _AColorOfColumn[4] = 2; 
  _AColorOfColumn[0] = 3; 
  _AColorOfColumn[3] = 4; 
  _AColorOfColumn[2] = 5; 

}

