/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop246.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop246::CauerLowPassSCAlgloop246(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
    : AlgLoopDefaultImplementation()
    , _system(system)
    , __z(z)
    , __zDot(zDot)
 ,__Asparse()

// ,__b(boost::extents[11])
    , _conditions(conditions)
    , _discrete_events(discrete_events)
    , _useSparseFormat(false)
    , _functions(system->_functions)
{
    // Number of unknowns/equations according to type (0: double, 1: int, 2: bool)
    _dimAEq = 11;
    fill_array(__b,0.0);
}

CauerLowPassSCAlgloop246::~CauerLowPassSCAlgloop246()
{
}

bool CauerLowPassSCAlgloop246::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop246::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop246::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop246::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop246::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop246::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop246::initialize(T *__A)
  {
         double tmp125;
         double tmp126;
         double tmp127;
         double tmp128;
         double tmp129;
         double tmp130;
         double tmp131;
         double tmp132;
          (*__A)(0+1,2+1)=-1.0;
          (*__A)(0+1,4+1)=-1.0;
          (*__A)(0+1,10+1)=1.0;
          (*__A)(1+1,0+1)=-1.0;
          (*__A)(1+1,9+1)=-1.0;
          (*__A)(1+1,10+1)=-1.0;
          if (_system->_R3_P_BooleanPulse1_P_y) {
            tmp125 = 1.0;
          } else {
            tmp125 = _system->_R3_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(2+1,8+1)=tmp125;
          (*__A)(2+1,9+1)=1.0;
          (*__A)(3+1,7+1)=1.0;
          if (_system->_R3_P_BooleanPulse1_P_y) {
            tmp126 = _system->_R3_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp126 = 1.0;
          }
          (*__A)(3+1,8+1)=(-tmp126);
          (*__A)(4+1,6+1)=-1.0;
          (*__A)(4+1,7+1)=1.0;
          if (_system->_R3_P_BooleanPulse1_P_y) {
            tmp127 = _system->_R3_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp127 = 1.0;
          }
          (*__A)(5+1,5+1)=(-tmp127);
          (*__A)(5+1,6+1)=1.0;
          (*__A)(6+1,4+1)=1.0;
          if (_system->_R3_P_BooleanPulse1_P_y) {
            tmp128 = 1.0;
          } else {
            tmp128 = _system->_R3_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(6+1,5+1)=tmp128;
          if (_system->_R3_P_BooleanPulse1_P_y) {
            tmp129 = 1.0;
          } else {
            tmp129 = _system->_R3_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(7+1,3+1)=(-tmp129);
          (*__A)(7+1,6+1)=1.0;
          (*__A)(8+1,2+1)=1.0;
          if (_system->_R3_P_BooleanPulse1_P_y) {
            tmp130 = _system->_R3_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp130 = 1.0;
          }
          (*__A)(8+1,3+1)=tmp130;
          if (_system->_R3_P_BooleanPulse1_P_y) {
            tmp131 = 1.0;
          } else {
            tmp131 = _system->_R3_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(9+1,1+1)=(-tmp131);
          (*__A)(9+1,7+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R3_P_BooleanPulse1_P_y) {
            tmp132 = _system->_R3_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp132 = 1.0;
          }
          (*__A)(10+1,1+1)=tmp132;
          __b(1)=0.0;
          __b(2)=0.0;
          __b(3)=-0.0;
          __b(4)=-0.0;
          __b(5)=(-__z[9]);
          __b(6)=-0.0;
          __b(7)=-0.0;
          __b(8)=-0.0;
          __b(9)=-0.0;
          __b(10)=(-__z[0]);
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop246::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop246::evaluate()
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
template <typename T>
void CauerLowPassSCAlgloop246::evaluate(T* __A)
{
    double tmp134;
    double tmp135;
    double tmp136;
    double tmp137;
    double tmp138;
    double tmp139;
    double tmp140;
    double tmp141;
    (*__A)(0+1,2+1)=-1.0;
    (*__A)(0+1,4+1)=-1.0;
    (*__A)(0+1,10+1)=1.0;
    (*__A)(1+1,0+1)=-1.0;
    (*__A)(1+1,9+1)=-1.0;
    (*__A)(1+1,10+1)=-1.0;
    if (_system->_R3_P_BooleanPulse1_P_y) {
      tmp134 = 1.0;
    } else {
      tmp134 = _system->_R3_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(2+1,8+1)=tmp134;
    (*__A)(2+1,9+1)=1.0;
    (*__A)(3+1,7+1)=1.0;
    if (_system->_R3_P_BooleanPulse1_P_y) {
      tmp135 = _system->_R3_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp135 = 1.0;
    }
    (*__A)(3+1,8+1)=(-tmp135);
    (*__A)(4+1,6+1)=-1.0;
    (*__A)(4+1,7+1)=1.0;
    if (_system->_R3_P_BooleanPulse1_P_y) {
      tmp136 = _system->_R3_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp136 = 1.0;
    }
    (*__A)(5+1,5+1)=(-tmp136);
    (*__A)(5+1,6+1)=1.0;
    (*__A)(6+1,4+1)=1.0;
    if (_system->_R3_P_BooleanPulse1_P_y) {
      tmp137 = 1.0;
    } else {
      tmp137 = _system->_R3_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(6+1,5+1)=tmp137;
    if (_system->_R3_P_BooleanPulse1_P_y) {
      tmp138 = 1.0;
    } else {
      tmp138 = _system->_R3_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(7+1,3+1)=(-tmp138);
    (*__A)(7+1,6+1)=1.0;
    (*__A)(8+1,2+1)=1.0;
    if (_system->_R3_P_BooleanPulse1_P_y) {
      tmp139 = _system->_R3_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp139 = 1.0;
    }
    (*__A)(8+1,3+1)=tmp139;
    if (_system->_R3_P_BooleanPulse1_P_y) {
      tmp140 = 1.0;
    } else {
      tmp140 = _system->_R3_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(9+1,1+1)=(-tmp140);
    (*__A)(9+1,7+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R3_P_BooleanPulse1_P_y) {
      tmp141 = _system->_R3_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp141 = 1.0;
    }
    (*__A)(10+1,1+1)=tmp141;
    __b(1)=0.0;
    __b(2)=0.0;
    __b(3)=-0.0;
    __b(4)=-0.0;
    __b(5)=(-__z[9]);
    __b(6)=-0.0;
    __b(7)=-0.0;
    __b(8)=-0.0;
    __b(9)=-0.0;
    __b(10)=(-__z[0]);
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop246::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop246::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop246::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop246::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R3_P_n2_P_i;
       vars[1] =_system->_R3_P_IdealCommutingSwitch2_P_s1;
       vars[2] =_system->_R3_P_n1_P_i;
       vars[3] =_system->_R3_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R3_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[5] =_system->_R3_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R3_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R3_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R3_P_IdealCommutingSwitch2_P_s2;
       vars[9] =_system->_R3_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[10] =_system->_R3_P_Capacitor1_P_i;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop246::getNominalReal(double* vars)
{
       vars[0] =_system->_R3_P_n2_P_i;
       vars[1] =_system->_R3_P_IdealCommutingSwitch2_P_s1;
       vars[2] =_system->_R3_P_n1_P_i;
       vars[3] =_system->_R3_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R3_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[5] =_system->_R3_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R3_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R3_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R3_P_IdealCommutingSwitch2_P_s2;
       vars[9] =_system->_R3_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[10] =_system->_R3_P_Capacitor1_P_i;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop246::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R3_P_n2_P_i=vars[0];
     _system->_R3_P_IdealCommutingSwitch2_P_s1=vars[1];
     _system->_R3_P_n1_P_i=vars[2];
     _system->_R3_P_IdealCommutingSwitch1_P_s1=vars[3];
     _system->_R3_P_IdealCommutingSwitch1_P_n2_P_i=vars[4];
     _system->_R3_P_IdealCommutingSwitch1_P_s2=vars[5];
     _system->_R3_P_Capacitor1_P_p_P_v=vars[6];
     _system->_R3_P_Capacitor1_P_n_P_v=vars[7];
     _system->_R3_P_IdealCommutingSwitch2_P_s2=vars[8];
     _system->_R3_P_IdealCommutingSwitch2_P_n2_P_i=vars[9];
     _system->_R3_P_Capacitor1_P_i=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop246::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop246::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop246::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop246::isLinearTearing()
  {
       return false;
  }