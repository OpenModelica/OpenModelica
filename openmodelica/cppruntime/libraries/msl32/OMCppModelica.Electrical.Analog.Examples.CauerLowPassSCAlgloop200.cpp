/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop200.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop200::CauerLowPassSCAlgloop200(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop200::~CauerLowPassSCAlgloop200()
{
}

bool CauerLowPassSCAlgloop200::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop200::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop200::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop200::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop200::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop200::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop200::initialize(T *__A)
  {
         double tmp416;
         double tmp417;
         double tmp418;
         double tmp419;
         double tmp420;
         double tmp421;
         double tmp422;
         double tmp423;
          (*__A)(0+1,2+1)=1.0;
          if (_system->_R4_P_BooleanPulse1_P_y) {
            tmp416 = 1.0;
          } else {
            tmp416 = _system->_R4_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(0+1,10+1)=(-tmp416);
          (*__A)(1+1,9+1)=-1.0;
          if (_system->_R4_P_BooleanPulse1_P_y) {
            tmp417 = _system->_R4_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp417 = 1.0;
          }
          (*__A)(1+1,10+1)=tmp417;
          (*__A)(2+1,0+1)=-1.0;
          (*__A)(2+1,8+1)=1.0;
          (*__A)(2+1,9+1)=1.0;
          (*__A)(3+1,3+1)=-1.0;
          (*__A)(3+1,7+1)=-1.0;
          (*__A)(3+1,8+1)=-1.0;
          if (_system->_R4_P_BooleanPulse1_P_y) {
            tmp418 = 1.0;
          } else {
            tmp418 = _system->_R4_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(4+1,6+1)=tmp418;
          (*__A)(4+1,7+1)=1.0;
          (*__A)(5+1,5+1)=1.0;
          if (_system->_R4_P_BooleanPulse1_P_y) {
            tmp419 = _system->_R4_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp419 = 1.0;
          }
          (*__A)(5+1,6+1)=(-tmp419);
          if (_system->_R4_P_BooleanPulse1_P_y) {
            tmp420 = 1.0;
          } else {
            tmp420 = _system->_R4_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(6+1,4+1)=(-tmp420);
          (*__A)(6+1,5+1)=1.0;
          (*__A)(7+1,3+1)=1.0;
          if (_system->_R4_P_BooleanPulse1_P_y) {
            tmp421 = _system->_R4_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp421 = 1.0;
          }
          (*__A)(7+1,4+1)=tmp421;
          (*__A)(8+1,2+1)=-1.0;
          (*__A)(8+1,5+1)=1.0;
          if (_system->_R4_P_BooleanPulse1_P_y) {
            tmp422 = _system->_R4_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp422 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp422);
          (*__A)(9+1,2+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R4_P_BooleanPulse1_P_y) {
            tmp423 = 1.0;
          } else {
            tmp423 = _system->_R4_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp423;
          __b(1)=-0.0;
          __b(2)=-0.0;
          __b(3)=-0.0;
          __b(4)=0.0;
          __b(5)=-0.0;
          __b(6)=-0.0;
          __b(7)=-0.0;
          __b(8)=-0.0;
          __b(9)=(-__z[10]);
          __b(10)=(-__z[0]);
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop200::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop200::evaluate()
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
void CauerLowPassSCAlgloop200::evaluate(T* __A)
{
    double tmp425;
    double tmp426;
    double tmp427;
    double tmp428;
    double tmp429;
    double tmp430;
    double tmp431;
    double tmp432;
    (*__A)(0+1,2+1)=1.0;
    if (_system->_R4_P_BooleanPulse1_P_y) {
      tmp425 = 1.0;
    } else {
      tmp425 = _system->_R4_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(0+1,10+1)=(-tmp425);
    (*__A)(1+1,9+1)=-1.0;
    if (_system->_R4_P_BooleanPulse1_P_y) {
      tmp426 = _system->_R4_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp426 = 1.0;
    }
    (*__A)(1+1,10+1)=tmp426;
    (*__A)(2+1,0+1)=-1.0;
    (*__A)(2+1,8+1)=1.0;
    (*__A)(2+1,9+1)=1.0;
    (*__A)(3+1,3+1)=-1.0;
    (*__A)(3+1,7+1)=-1.0;
    (*__A)(3+1,8+1)=-1.0;
    if (_system->_R4_P_BooleanPulse1_P_y) {
      tmp427 = 1.0;
    } else {
      tmp427 = _system->_R4_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(4+1,6+1)=tmp427;
    (*__A)(4+1,7+1)=1.0;
    (*__A)(5+1,5+1)=1.0;
    if (_system->_R4_P_BooleanPulse1_P_y) {
      tmp428 = _system->_R4_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp428 = 1.0;
    }
    (*__A)(5+1,6+1)=(-tmp428);
    if (_system->_R4_P_BooleanPulse1_P_y) {
      tmp429 = 1.0;
    } else {
      tmp429 = _system->_R4_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(6+1,4+1)=(-tmp429);
    (*__A)(6+1,5+1)=1.0;
    (*__A)(7+1,3+1)=1.0;
    if (_system->_R4_P_BooleanPulse1_P_y) {
      tmp430 = _system->_R4_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp430 = 1.0;
    }
    (*__A)(7+1,4+1)=tmp430;
    (*__A)(8+1,2+1)=-1.0;
    (*__A)(8+1,5+1)=1.0;
    if (_system->_R4_P_BooleanPulse1_P_y) {
      tmp431 = _system->_R4_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp431 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp431);
    (*__A)(9+1,2+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R4_P_BooleanPulse1_P_y) {
      tmp432 = 1.0;
    } else {
      tmp432 = _system->_R4_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp432;
    __b(1)=-0.0;
    __b(2)=-0.0;
    __b(3)=-0.0;
    __b(4)=0.0;
    __b(5)=-0.0;
    __b(6)=-0.0;
    __b(7)=-0.0;
    __b(8)=-0.0;
    __b(9)=(-__z[10]);
    __b(10)=(-__z[0]);
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop200::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop200::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop200::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop200::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R4_P_n1_P_i;
       vars[1] =_system->_R4_P_IdealCommutingSwitch1_P_s2;
       vars[2] =_system->_R4_P_Capacitor1_P_p_P_v;
       vars[3] =_system->_R4_P_n2_P_i;
       vars[4] =_system->_R4_P_IdealCommutingSwitch2_P_s1;
       vars[5] =_system->_R4_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R4_P_IdealCommutingSwitch2_P_s2;
       vars[7] =_system->_R4_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[8] =_system->_R4_P_Capacitor1_P_i;
       vars[9] =_system->_R4_P_Ground1_P_p_P_i;
       vars[10] =_system->_R4_P_IdealCommutingSwitch1_P_s1;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop200::getNominalReal(double* vars)
{
       vars[0] =_system->_R4_P_n1_P_i;
       vars[1] =_system->_R4_P_IdealCommutingSwitch1_P_s2;
       vars[2] =_system->_R4_P_Capacitor1_P_p_P_v;
       vars[3] =_system->_R4_P_n2_P_i;
       vars[4] =_system->_R4_P_IdealCommutingSwitch2_P_s1;
       vars[5] =_system->_R4_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R4_P_IdealCommutingSwitch2_P_s2;
       vars[7] =_system->_R4_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[8] =_system->_R4_P_Capacitor1_P_i;
       vars[9] =_system->_R4_P_Ground1_P_p_P_i;
       vars[10] =_system->_R4_P_IdealCommutingSwitch1_P_s1;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop200::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R4_P_n1_P_i=vars[0];
     _system->_R4_P_IdealCommutingSwitch1_P_s2=vars[1];
     _system->_R4_P_Capacitor1_P_p_P_v=vars[2];
     _system->_R4_P_n2_P_i=vars[3];
     _system->_R4_P_IdealCommutingSwitch2_P_s1=vars[4];
     _system->_R4_P_Capacitor1_P_n_P_v=vars[5];
     _system->_R4_P_IdealCommutingSwitch2_P_s2=vars[6];
     _system->_R4_P_IdealCommutingSwitch2_P_n2_P_i=vars[7];
     _system->_R4_P_Capacitor1_P_i=vars[8];
     _system->_R4_P_Ground1_P_p_P_i=vars[9];
     _system->_R4_P_IdealCommutingSwitch1_P_s1=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop200::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop200::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop200::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop200::isLinearTearing()
  {
       return false;
  }