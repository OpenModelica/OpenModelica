/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCJacobian.h" */
CauerLowPassSCJacobian::CauerLowPassSCJacobian(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
    : CauerLowPassSC(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
    , _AColorOfColumn(NULL)
     
     
     
     ,_C1_vSeedA( _Ajac_x(0))
     ,_C2_vSeedA( _Ajac_x(1))
     ,_C3_vSeedA( _Ajac_x(2))
     ,_C4_vSeedA( _Ajac_x(3))
     ,_C7_vSeedA( _Ajac_x(4))
     ,_R1_Capacitor1_vSeedA( _Ajac_x(5))
     ,_R10_Capacitor1_vSeedA( _Ajac_x(6))
     ,_R11_Capacitor1_vSeedA( _Ajac_x(7))
     ,_R2_Capacitor1_vSeedA( _Ajac_x(8))
     ,_R3_Capacitor1_vSeedA( _Ajac_x(9))
     ,_R4_Capacitor1_vSeedA( _Ajac_x(10))
     ,_R5_Capacitor1_vSeedA( _Ajac_x(11))
     ,_R7_Capacitor1_vSeedA( _Ajac_x(12))
     ,_R8_Capacitor1_vSeedA( _Ajac_x(13))
     ,_R9_Capacitor1_vSeedA( _Ajac_x(14))
     ,_Rp1_Capacitor1_vSeedA( _Ajac_x(15))
      ,_Ajacobian(SparseMatrix(16,16,62))
      ,_Ajac_y(ublas::zero_vector<double>(16))
      ,_Ajac_tmp(ublas::zero_vector<double>(0))
      ,_Ajac_x(ublas::zero_vector<double>(16))
{
}

CauerLowPassSCJacobian::~CauerLowPassSCJacobian()
{
if(_AColorOfColumn)
  delete []  _AColorOfColumn;
}


void CauerLowPassSCJacobian::calcDJacobianColumn()
{
}

void CauerLowPassSCJacobian::getDJacobian(SparseMatrix& matrix)
{
}

void CauerLowPassSCJacobian::calcCJacobianColumn()
{
}

void CauerLowPassSCJacobian::getCJacobian(SparseMatrix& matrix)
{
}

void CauerLowPassSCJacobian::calcBJacobianColumn()
{
}

void CauerLowPassSCJacobian::getBJacobian(SparseMatrix& matrix)
{
}

void CauerLowPassSCJacobian::calcAJacobianColumn()
{
}

void CauerLowPassSCJacobian::getAJacobian(SparseMatrix& matrix)
{

  _Ajac_x(0) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(0,0) = _Ajac_y(0);/*test20,0*/
  _Ajacobian(0,1) = _Ajac_y(1);/*test20,1*/
  _Ajacobian(0,2) = _Ajac_y(2);/*test20,2*/
  _Ajacobian(0,3) = _Ajac_y(3);/*test20,3*/
  _Ajacobian(0,9) = _Ajac_y(9);/*test20,4*/
  _Ajacobian(0,10) = _Ajac_y(10);/*test20,5*/
  _Ajac_x(1) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(1,2) = _Ajac_y(2);/*test21,0*/
  _Ajacobian(1,4) = _Ajac_y(4);/*test21,1*/
  _Ajacobian(1,11) = _Ajac_y(11);/*test21,2*/
  _Ajacobian(1,14) = _Ajac_y(14);/*test21,3*/
  _Ajac_x(2) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(2,0) = _Ajac_y(0);/*test22,0*/
  _Ajacobian(2,1) = _Ajac_y(1);/*test22,1*/
  _Ajacobian(2,3) = _Ajac_y(3);/*test22,2*/
  _Ajacobian(2,8) = _Ajac_y(8);/*test22,3*/
  _Ajacobian(2,12) = _Ajac_y(12);/*test22,4*/
  _Ajac_x(3) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(3,0) = _Ajac_y(0);/*test23,0*/
  _Ajacobian(3,1) = _Ajac_y(1);/*test23,1*/
  _Ajacobian(3,3) = _Ajac_y(3);/*test23,2*/
  _Ajacobian(3,4) = _Ajac_y(4);/*test23,3*/
  _Ajacobian(3,7) = _Ajac_y(7);/*test23,4*/
  _Ajacobian(3,13) = _Ajac_y(13);/*test23,5*/
  _Ajac_x(4) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(4,0) = _Ajac_y(0);/*test24,0*/
  _Ajacobian(4,1) = _Ajac_y(1);/*test24,1*/
  _Ajacobian(4,3) = _Ajac_y(3);/*test24,2*/
  _Ajacobian(4,6) = _Ajac_y(6);/*test24,3*/
  _Ajacobian(4,15) = _Ajac_y(15);/*test24,4*/
  _Ajac_x(5) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(5,0) = _Ajac_y(0);/*test25,0*/
  _Ajacobian(5,1) = _Ajac_y(1);/*test25,1*/
  _Ajacobian(5,3) = _Ajac_y(3);/*test25,2*/
  _Ajacobian(5,5) = _Ajac_y(5);/*test25,3*/
  _Ajac_x(6) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(6,0) = _Ajac_y(0);/*test26,0*/
  _Ajacobian(6,1) = _Ajac_y(1);/*test26,1*/
  _Ajacobian(6,3) = _Ajac_y(3);/*test26,2*/
  _Ajacobian(6,6) = _Ajac_y(6);/*test26,3*/
  _Ajac_x(7) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(7,0) = _Ajac_y(0);/*test27,0*/
  _Ajacobian(7,1) = _Ajac_y(1);/*test27,1*/
  _Ajacobian(7,3) = _Ajac_y(3);/*test27,2*/
  _Ajacobian(7,7) = _Ajac_y(7);/*test27,3*/
  _Ajac_x(8) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(8,0) = _Ajac_y(0);/*test28,0*/
  _Ajacobian(8,1) = _Ajac_y(1);/*test28,1*/
  _Ajacobian(8,3) = _Ajac_y(3);/*test28,2*/
  _Ajacobian(8,8) = _Ajac_y(8);/*test28,3*/
  _Ajac_x(9) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(9,0) = _Ajac_y(0);/*test29,0*/
  _Ajacobian(9,1) = _Ajac_y(1);/*test29,1*/
  _Ajacobian(9,3) = _Ajac_y(3);/*test29,2*/
  _Ajacobian(9,9) = _Ajac_y(9);/*test29,3*/
  _Ajac_x(10) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(10,2) = _Ajac_y(2);/*test210,0*/
  _Ajacobian(10,10) = _Ajac_y(10);/*test210,1*/
  _Ajac_x(11) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(11,2) = _Ajac_y(2);/*test211,0*/
  _Ajacobian(11,11) = _Ajac_y(11);/*test211,1*/
  _Ajac_x(12) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(12,0) = _Ajac_y(0);/*test212,0*/
  _Ajacobian(12,1) = _Ajac_y(1);/*test212,1*/
  _Ajacobian(12,3) = _Ajac_y(3);/*test212,2*/
  _Ajacobian(12,12) = _Ajac_y(12);/*test212,3*/
  _Ajac_x(13) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(13,4) = _Ajac_y(4);/*test213,0*/
  _Ajacobian(13,13) = _Ajac_y(13);/*test213,1*/
  _Ajac_x(14) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(14,4) = _Ajac_y(4);/*test214,0*/
  _Ajacobian(14,14) = _Ajac_y(14);/*test214,1*/
  _Ajac_x(15) = 1;
  calcAJacobianColumn();
  _Ajac_x.clear();
  _Ajacobian(15,0) = _Ajac_y(0);/*test215,0*/
  _Ajacobian(15,1) = _Ajac_y(1);/*test215,1*/
  _Ajacobian(15,3) = _Ajac_y(3);/*test215,2*/
  _Ajacobian(15,15) = _Ajac_y(15);/*test215,3*/
  matrix = _Ajacobian;
}

void CauerLowPassSCJacobian::initialize()
{
   //create Algloopsolver for analytical Jacobians
      
      
      
   //initialize Algloopsolver for analytical Jacobians

}

//testmaessig aus der cruntime
/* Jacobians */


void CauerLowPassSCJacobian::initializeColoredJacobianA()
{
  if(_AColorOfColumn)
    delete [] _AColorOfColumn;
  _AColorOfColumn = new int[16];
  _AMaxColors = 11;
  
  /* write color array */
  _AColorOfColumn[7] = 1; 
  _AColorOfColumn[6] = 2; 
  _AColorOfColumn[12] = 3; 
  _AColorOfColumn[15] = 4; 
  _AColorOfColumn[9] = 5; 
  _AColorOfColumn[8] = 6; 
  _AColorOfColumn[5] = 7; 
  _AColorOfColumn[4] = 8; 
  _AColorOfColumn[11] = 8; 
  _AColorOfColumn[14] = 8; 
  _AColorOfColumn[3] = 9; 
  _AColorOfColumn[10] = 9; 
  _AColorOfColumn[1] = 10; 
  _AColorOfColumn[2] = 10; 
  _AColorOfColumn[0] = 11; 
  _AColorOfColumn[13] = 11; 

}

