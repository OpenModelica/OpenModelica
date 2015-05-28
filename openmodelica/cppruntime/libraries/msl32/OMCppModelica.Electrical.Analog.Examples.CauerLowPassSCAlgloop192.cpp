/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop192.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop192::CauerLowPassSCAlgloop192(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop192::~CauerLowPassSCAlgloop192()
{
}

bool CauerLowPassSCAlgloop192::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop192::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop192::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop192::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop192::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop192::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop192::initialize(T *__A)
  {
         double tmp399;
         double tmp400;
         double tmp401;
         double tmp402;
         double tmp403;
         double tmp404;
         double tmp405;
         double tmp406;
          (*__A)(0+1,2+1)=1.0;
          if (_system->_R5_P_BooleanPulse1_P_y) {
            tmp399 = 1.0;
          } else {
            tmp399 = _system->_R5_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(0+1,10+1)=(-tmp399);
          (*__A)(1+1,9+1)=1.0;
          if (_system->_R5_P_BooleanPulse1_P_y) {
            tmp400 = _system->_R5_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp400 = 1.0;
          }
          (*__A)(1+1,10+1)=tmp400;
          (*__A)(2+1,0+1)=-1.0;
          (*__A)(2+1,8+1)=1.0;
          (*__A)(2+1,9+1)=-1.0;
          (*__A)(3+1,3+1)=-1.0;
          (*__A)(3+1,7+1)=-1.0;
          (*__A)(3+1,8+1)=-1.0;
          if (_system->_R5_P_BooleanPulse1_P_y) {
            tmp401 = 1.0;
          } else {
            tmp401 = _system->_R5_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(4+1,6+1)=tmp401;
          (*__A)(4+1,7+1)=1.0;
          (*__A)(5+1,5+1)=1.0;
          if (_system->_R5_P_BooleanPulse1_P_y) {
            tmp402 = _system->_R5_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp402 = 1.0;
          }
          (*__A)(5+1,6+1)=(-tmp402);
          if (_system->_R5_P_BooleanPulse1_P_y) {
            tmp403 = 1.0;
          } else {
            tmp403 = _system->_R5_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(6+1,4+1)=(-tmp403);
          (*__A)(6+1,5+1)=1.0;
          (*__A)(7+1,3+1)=1.0;
          if (_system->_R5_P_BooleanPulse1_P_y) {
            tmp404 = _system->_R5_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp404 = 1.0;
          }
          (*__A)(7+1,4+1)=tmp404;
          (*__A)(8+1,2+1)=-1.0;
          (*__A)(8+1,5+1)=1.0;
          if (_system->_R5_P_BooleanPulse1_P_y) {
            tmp405 = _system->_R5_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp405 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp405);
          (*__A)(9+1,2+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R5_P_BooleanPulse1_P_y) {
            tmp406 = 1.0;
          } else {
            tmp406 = _system->_R5_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp406;
          __b(1)=-0.0;
          __b(2)=-0.0;
          __b(3)=0.0;
          __b(4)=0.0;
          __b(5)=-0.0;
          __b(6)=-0.0;
          __b(7)=-0.0;
          __b(8)=-0.0;
          __b(9)=(-__z[11]);
          __b(10)=__z[1];
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop192::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop192::evaluate()
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
void CauerLowPassSCAlgloop192::evaluate(T* __A)
{
    double tmp408;
    double tmp409;
    double tmp410;
    double tmp411;
    double tmp412;
    double tmp413;
    double tmp414;
    double tmp415;
    (*__A)(0+1,2+1)=1.0;
    if (_system->_R5_P_BooleanPulse1_P_y) {
      tmp408 = 1.0;
    } else {
      tmp408 = _system->_R5_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(0+1,10+1)=(-tmp408);
    (*__A)(1+1,9+1)=1.0;
    if (_system->_R5_P_BooleanPulse1_P_y) {
      tmp409 = _system->_R5_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp409 = 1.0;
    }
    (*__A)(1+1,10+1)=tmp409;
    (*__A)(2+1,0+1)=-1.0;
    (*__A)(2+1,8+1)=1.0;
    (*__A)(2+1,9+1)=-1.0;
    (*__A)(3+1,3+1)=-1.0;
    (*__A)(3+1,7+1)=-1.0;
    (*__A)(3+1,8+1)=-1.0;
    if (_system->_R5_P_BooleanPulse1_P_y) {
      tmp410 = 1.0;
    } else {
      tmp410 = _system->_R5_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(4+1,6+1)=tmp410;
    (*__A)(4+1,7+1)=1.0;
    (*__A)(5+1,5+1)=1.0;
    if (_system->_R5_P_BooleanPulse1_P_y) {
      tmp411 = _system->_R5_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp411 = 1.0;
    }
    (*__A)(5+1,6+1)=(-tmp411);
    if (_system->_R5_P_BooleanPulse1_P_y) {
      tmp412 = 1.0;
    } else {
      tmp412 = _system->_R5_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(6+1,4+1)=(-tmp412);
    (*__A)(6+1,5+1)=1.0;
    (*__A)(7+1,3+1)=1.0;
    if (_system->_R5_P_BooleanPulse1_P_y) {
      tmp413 = _system->_R5_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp413 = 1.0;
    }
    (*__A)(7+1,4+1)=tmp413;
    (*__A)(8+1,2+1)=-1.0;
    (*__A)(8+1,5+1)=1.0;
    if (_system->_R5_P_BooleanPulse1_P_y) {
      tmp414 = _system->_R5_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp414 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp414);
    (*__A)(9+1,2+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R5_P_BooleanPulse1_P_y) {
      tmp415 = 1.0;
    } else {
      tmp415 = _system->_R5_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp415;
    __b(1)=-0.0;
    __b(2)=-0.0;
    __b(3)=0.0;
    __b(4)=0.0;
    __b(5)=-0.0;
    __b(6)=-0.0;
    __b(7)=-0.0;
    __b(8)=-0.0;
    __b(9)=(-__z[11]);
    __b(10)=__z[1];
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop192::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop192::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop192::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop192::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R5_P_n1_P_i;
       vars[1] =_system->_R5_P_IdealCommutingSwitch1_P_s2;
       vars[2] =_system->_R5_P_Capacitor1_P_p_P_v;
       vars[3] =_system->_R5_P_n2_P_i;
       vars[4] =_system->_R5_P_IdealCommutingSwitch2_P_s1;
       vars[5] =_system->_R5_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R5_P_IdealCommutingSwitch2_P_s2;
       vars[7] =_system->_R5_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[8] =_system->_R5_P_Capacitor1_P_i;
       vars[9] =_system->_R5_P_IdealCommutingSwitch1_P_n1_P_i;
       vars[10] =_system->_R5_P_IdealCommutingSwitch1_P_s1;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop192::getNominalReal(double* vars)
{
       vars[0] =_system->_R5_P_n1_P_i;
       vars[1] =_system->_R5_P_IdealCommutingSwitch1_P_s2;
       vars[2] =_system->_R5_P_Capacitor1_P_p_P_v;
       vars[3] =_system->_R5_P_n2_P_i;
       vars[4] =_system->_R5_P_IdealCommutingSwitch2_P_s1;
       vars[5] =_system->_R5_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R5_P_IdealCommutingSwitch2_P_s2;
       vars[7] =_system->_R5_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[8] =_system->_R5_P_Capacitor1_P_i;
       vars[9] =_system->_R5_P_IdealCommutingSwitch1_P_n1_P_i;
       vars[10] =_system->_R5_P_IdealCommutingSwitch1_P_s1;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop192::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R5_P_n1_P_i=vars[0];
     _system->_R5_P_IdealCommutingSwitch1_P_s2=vars[1];
     _system->_R5_P_Capacitor1_P_p_P_v=vars[2];
     _system->_R5_P_n2_P_i=vars[3];
     _system->_R5_P_IdealCommutingSwitch2_P_s1=vars[4];
     _system->_R5_P_Capacitor1_P_n_P_v=vars[5];
     _system->_R5_P_IdealCommutingSwitch2_P_s2=vars[6];
     _system->_R5_P_IdealCommutingSwitch2_P_n2_P_i=vars[7];
     _system->_R5_P_Capacitor1_P_i=vars[8];
     _system->_R5_P_IdealCommutingSwitch1_P_n1_P_i=vars[9];
     _system->_R5_P_IdealCommutingSwitch1_P_s1=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop192::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop192::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop192::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop192::isLinearTearing()
  {
       return false;
  }