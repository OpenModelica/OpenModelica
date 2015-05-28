
BouncingBallJacobian::BouncingBallJacobian(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
    : BouncingBall(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
    , _AColorOfColumn(NULL)
     
     
     
     ,_hSeedA( _Ajac_x(0))
     ,_vSeedA( _Ajac_x(1))
      ,_Ajacobian(SparseMatrix(2,2,3))
      ,_Ajac_y(ublas::zero_vector<double>(2))
      ,_Ajac_tmp(ublas::zero_vector<double>(0))
      ,_Ajac_x(ublas::zero_vector<double>(2))
{
}

BouncingBallJacobian::~BouncingBallJacobian()
{
if(_AColorOfColumn)
  delete []  _AColorOfColumn;
}


void BouncingBallJacobian::calcDJacobianColumn()
{
}

void BouncingBallJacobian::getDJacobian(SparseMatrix& matrix)
{
}

void BouncingBallJacobian::calcCJacobianColumn()
{
}

void BouncingBallJacobian::getCJacobian(SparseMatrix& matrix)
{
}

void BouncingBallJacobian::calcBJacobianColumn()
{
}

void BouncingBallJacobian::getBJacobian(SparseMatrix& matrix)
{
}

void BouncingBallJacobian::calcAJacobianColumn()
{
}

void BouncingBallJacobian::getAJacobian(SparseMatrix& matrix)
{

  _Ajac_x(0) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(0,1) = _Ajac_y(1);/*test20,0*/
  _Ajac_x(1) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(1,0) = _Ajac_y(0);/*test21,0*/
  _Ajacobian(1,1) = _Ajac_y(1);/*test21,1*/
  matrix = _Ajacobian;
}

void BouncingBallJacobian::initialize()
{
   //create Algloopsolver for analytical Jacobians
      
      
      
   //initialize Algloopsolver for analytical Jacobians

}

//testmaessig aus der cruntime
/* Jacobians */


void BouncingBallJacobian::initializeColoredJacobianA()
{
  if(_AColorOfColumn)
    delete [] _AColorOfColumn;
  _AColorOfColumn = new int[2];
  _AMaxColors = 2;
  
  /* write color array */
  _AColorOfColumn[1] = 1; 
  _AColorOfColumn[0] = 2; 

}

