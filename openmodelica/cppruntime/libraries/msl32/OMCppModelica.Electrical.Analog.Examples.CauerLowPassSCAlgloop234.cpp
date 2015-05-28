/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop234.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop234::CauerLowPassSCAlgloop234(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop234::~CauerLowPassSCAlgloop234()
{
}

bool CauerLowPassSCAlgloop234::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop234::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop234::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop234::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop234::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop234::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop234::initialize(T *__A)
  {
         double tmp91;
         double tmp92;
         double tmp93;
         double tmp94;
         double tmp95;
         double tmp96;
         double tmp97;
         double tmp98;
          (*__A)(0+1,2+1)=-1.0;
          (*__A)(0+1,4+1)=-1.0;
          (*__A)(0+1,10+1)=1.0;
          (*__A)(1+1,0+1)=-1.0;
          (*__A)(1+1,9+1)=-1.0;
          (*__A)(1+1,10+1)=-1.0;
          if (_system->_R7_P_BooleanPulse1_P_y) {
            tmp91 = _system->_R7_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp91 = 1.0;
          }
          (*__A)(2+1,8+1)=tmp91;
          (*__A)(2+1,9+1)=1.0;
          (*__A)(3+1,7+1)=1.0;
          if (_system->_R7_P_BooleanPulse1_P_y) {
            tmp92 = 1.0;
          } else {
            tmp92 = _system->_R7_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(3+1,8+1)=(-tmp92);
          (*__A)(4+1,6+1)=-1.0;
          (*__A)(4+1,7+1)=1.0;
          if (_system->_R7_P_BooleanPulse1_P_y) {
            tmp93 = _system->_R7_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp93 = 1.0;
          }
          (*__A)(5+1,5+1)=(-tmp93);
          (*__A)(5+1,6+1)=1.0;
          (*__A)(6+1,4+1)=1.0;
          if (_system->_R7_P_BooleanPulse1_P_y) {
            tmp94 = 1.0;
          } else {
            tmp94 = _system->_R7_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(6+1,5+1)=tmp94;
          if (_system->_R7_P_BooleanPulse1_P_y) {
            tmp95 = 1.0;
          } else {
            tmp95 = _system->_R7_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(7+1,3+1)=(-tmp95);
          (*__A)(7+1,6+1)=1.0;
          (*__A)(8+1,2+1)=1.0;
          if (_system->_R7_P_BooleanPulse1_P_y) {
            tmp96 = _system->_R7_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp96 = 1.0;
          }
          (*__A)(8+1,3+1)=tmp96;
          if (_system->_R7_P_BooleanPulse1_P_y) {
            tmp97 = _system->_R7_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp97 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp97);
          (*__A)(9+1,7+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R7_P_BooleanPulse1_P_y) {
            tmp98 = 1.0;
          } else {
            tmp98 = _system->_R7_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp98;
          __b(1)=0.0;
          __b(2)=0.0;
          __b(3)=-0.0;
          __b(4)=-0.0;
          __b(5)=(-__z[12]);
          __b(6)=-0.0;
          __b(7)=-0.0;
          __b(8)=(-__z[2]);
          __b(9)=-0.0;
          __b(10)=-0.0;
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop234::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop234::evaluate()
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
void CauerLowPassSCAlgloop234::evaluate(T* __A)
{
    double tmp100;
    double tmp101;
    double tmp102;
    double tmp103;
    double tmp104;
    double tmp105;
    double tmp106;
    double tmp107;
    (*__A)(0+1,2+1)=-1.0;
    (*__A)(0+1,4+1)=-1.0;
    (*__A)(0+1,10+1)=1.0;
    (*__A)(1+1,0+1)=-1.0;
    (*__A)(1+1,9+1)=-1.0;
    (*__A)(1+1,10+1)=-1.0;
    if (_system->_R7_P_BooleanPulse1_P_y) {
      tmp100 = _system->_R7_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp100 = 1.0;
    }
    (*__A)(2+1,8+1)=tmp100;
    (*__A)(2+1,9+1)=1.0;
    (*__A)(3+1,7+1)=1.0;
    if (_system->_R7_P_BooleanPulse1_P_y) {
      tmp101 = 1.0;
    } else {
      tmp101 = _system->_R7_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(3+1,8+1)=(-tmp101);
    (*__A)(4+1,6+1)=-1.0;
    (*__A)(4+1,7+1)=1.0;
    if (_system->_R7_P_BooleanPulse1_P_y) {
      tmp102 = _system->_R7_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp102 = 1.0;
    }
    (*__A)(5+1,5+1)=(-tmp102);
    (*__A)(5+1,6+1)=1.0;
    (*__A)(6+1,4+1)=1.0;
    if (_system->_R7_P_BooleanPulse1_P_y) {
      tmp103 = 1.0;
    } else {
      tmp103 = _system->_R7_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(6+1,5+1)=tmp103;
    if (_system->_R7_P_BooleanPulse1_P_y) {
      tmp104 = 1.0;
    } else {
      tmp104 = _system->_R7_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(7+1,3+1)=(-tmp104);
    (*__A)(7+1,6+1)=1.0;
    (*__A)(8+1,2+1)=1.0;
    if (_system->_R7_P_BooleanPulse1_P_y) {
      tmp105 = _system->_R7_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp105 = 1.0;
    }
    (*__A)(8+1,3+1)=tmp105;
    if (_system->_R7_P_BooleanPulse1_P_y) {
      tmp106 = _system->_R7_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp106 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp106);
    (*__A)(9+1,7+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R7_P_BooleanPulse1_P_y) {
      tmp107 = 1.0;
    } else {
      tmp107 = _system->_R7_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp107;
    __b(1)=0.0;
    __b(2)=0.0;
    __b(3)=-0.0;
    __b(4)=-0.0;
    __b(5)=(-__z[12]);
    __b(6)=-0.0;
    __b(7)=-0.0;
    __b(8)=(-__z[2]);
    __b(9)=-0.0;
    __b(10)=-0.0;
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop234::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop234::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop234::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop234::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R7_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R7_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R7_P_n1_P_i;
       vars[3] =_system->_R7_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R7_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[5] =_system->_R7_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R7_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R7_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R7_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_R7_P_n2_P_i;
       vars[10] =_system->_R7_P_Capacitor1_P_i;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop234::getNominalReal(double* vars)
{
       vars[0] =_system->_R7_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R7_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R7_P_n1_P_i;
       vars[3] =_system->_R7_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R7_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[5] =_system->_R7_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R7_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R7_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R7_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_R7_P_n2_P_i;
       vars[10] =_system->_R7_P_Capacitor1_P_i;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop234::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R7_P_IdealCommutingSwitch2_P_n2_P_i=vars[0];
     _system->_R7_P_IdealCommutingSwitch2_P_s2=vars[1];
     _system->_R7_P_n1_P_i=vars[2];
     _system->_R7_P_IdealCommutingSwitch1_P_s1=vars[3];
     _system->_R7_P_IdealCommutingSwitch1_P_n2_P_i=vars[4];
     _system->_R7_P_IdealCommutingSwitch1_P_s2=vars[5];
     _system->_R7_P_Capacitor1_P_p_P_v=vars[6];
     _system->_R7_P_Capacitor1_P_n_P_v=vars[7];
     _system->_R7_P_IdealCommutingSwitch2_P_s1=vars[8];
     _system->_R7_P_n2_P_i=vars[9];
     _system->_R7_P_Capacitor1_P_i=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop234::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop234::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop234::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop234::isLinearTearing()
  {
       return false;
  }