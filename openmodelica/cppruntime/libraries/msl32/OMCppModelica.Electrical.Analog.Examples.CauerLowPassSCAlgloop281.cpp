/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop281.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop281::CauerLowPassSCAlgloop281(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop281::~CauerLowPassSCAlgloop281()
{
}

bool CauerLowPassSCAlgloop281::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop281::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop281::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop281::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop281::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop281::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop281::initialize(T *__A)
  {
         double tmp210;
         double tmp211;
         double tmp212;
         double tmp213;
         double tmp214;
         double tmp215;
         double tmp216;
         double tmp217;
          (*__A)(0+1,2+1)=1.0;
          (*__A)(0+1,4+1)=-1.0;
          (*__A)(0+1,10+1)=1.0;
          (*__A)(1+1,0+1)=-1.0;
          (*__A)(1+1,9+1)=-1.0;
          (*__A)(1+1,10+1)=-1.0;
          if (_system->_R4_P_BooleanPulse1_P_y) {
            tmp210 = _system->_R4_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp210 = 1.0;
          }
          (*__A)(2+1,8+1)=tmp210;
          (*__A)(2+1,9+1)=1.0;
          (*__A)(3+1,7+1)=1.0;
          if (_system->_R4_P_BooleanPulse1_P_y) {
            tmp211 = 1.0;
          } else {
            tmp211 = _system->_R4_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(3+1,8+1)=(-tmp211);
          (*__A)(4+1,6+1)=-1.0;
          (*__A)(4+1,7+1)=1.0;
          if (_system->_R4_P_BooleanPulse1_P_y) {
            tmp212 = _system->_R4_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp212 = 1.0;
          }
          (*__A)(5+1,5+1)=(-tmp212);
          (*__A)(5+1,6+1)=1.0;
          (*__A)(6+1,4+1)=1.0;
          if (_system->_R4_P_BooleanPulse1_P_y) {
            tmp213 = 1.0;
          } else {
            tmp213 = _system->_R4_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(6+1,5+1)=tmp213;
          if (_system->_R4_P_BooleanPulse1_P_y) {
            tmp214 = 1.0;
          } else {
            tmp214 = _system->_R4_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(7+1,3+1)=(-tmp214);
          (*__A)(7+1,6+1)=1.0;
          (*__A)(8+1,2+1)=-1.0;
          if (_system->_R4_P_BooleanPulse1_P_y) {
            tmp215 = _system->_R4_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp215 = 1.0;
          }
          (*__A)(8+1,3+1)=tmp215;
          if (_system->_R4_P_BooleanPulse1_P_y) {
            tmp216 = _system->_R4_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp216 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp216);
          (*__A)(9+1,7+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R4_P_BooleanPulse1_P_y) {
            tmp217 = 1.0;
          } else {
            tmp217 = _system->_R4_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp217;
          __b(1)=-0.0;
          __b(2)=0.0;
          __b(3)=-0.0;
          __b(4)=-0.0;
          __b(5)=(-__z[10]);
          __b(6)=(-__z[0]);
          __b(7)=-0.0;
          __b(8)=-0.0;
          __b(9)=-0.0;
          __b(10)=-0.0;
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop281::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop281::evaluate()
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
void CauerLowPassSCAlgloop281::evaluate(T* __A)
{
    double tmp219;
    double tmp220;
    double tmp221;
    double tmp222;
    double tmp223;
    double tmp224;
    double tmp225;
    double tmp226;
    (*__A)(0+1,2+1)=1.0;
    (*__A)(0+1,4+1)=-1.0;
    (*__A)(0+1,10+1)=1.0;
    (*__A)(1+1,0+1)=-1.0;
    (*__A)(1+1,9+1)=-1.0;
    (*__A)(1+1,10+1)=-1.0;
    if (_system->_R4_P_BooleanPulse1_P_y) {
      tmp219 = _system->_R4_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp219 = 1.0;
    }
    (*__A)(2+1,8+1)=tmp219;
    (*__A)(2+1,9+1)=1.0;
    (*__A)(3+1,7+1)=1.0;
    if (_system->_R4_P_BooleanPulse1_P_y) {
      tmp220 = 1.0;
    } else {
      tmp220 = _system->_R4_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(3+1,8+1)=(-tmp220);
    (*__A)(4+1,6+1)=-1.0;
    (*__A)(4+1,7+1)=1.0;
    if (_system->_R4_P_BooleanPulse1_P_y) {
      tmp221 = _system->_R4_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp221 = 1.0;
    }
    (*__A)(5+1,5+1)=(-tmp221);
    (*__A)(5+1,6+1)=1.0;
    (*__A)(6+1,4+1)=1.0;
    if (_system->_R4_P_BooleanPulse1_P_y) {
      tmp222 = 1.0;
    } else {
      tmp222 = _system->_R4_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(6+1,5+1)=tmp222;
    if (_system->_R4_P_BooleanPulse1_P_y) {
      tmp223 = 1.0;
    } else {
      tmp223 = _system->_R4_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(7+1,3+1)=(-tmp223);
    (*__A)(7+1,6+1)=1.0;
    (*__A)(8+1,2+1)=-1.0;
    if (_system->_R4_P_BooleanPulse1_P_y) {
      tmp224 = _system->_R4_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp224 = 1.0;
    }
    (*__A)(8+1,3+1)=tmp224;
    if (_system->_R4_P_BooleanPulse1_P_y) {
      tmp225 = _system->_R4_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp225 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp225);
    (*__A)(9+1,7+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R4_P_BooleanPulse1_P_y) {
      tmp226 = 1.0;
    } else {
      tmp226 = _system->_R4_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp226;
    __b(1)=-0.0;
    __b(2)=0.0;
    __b(3)=-0.0;
    __b(4)=-0.0;
    __b(5)=(-__z[10]);
    __b(6)=(-__z[0]);
    __b(7)=-0.0;
    __b(8)=-0.0;
    __b(9)=-0.0;
    __b(10)=-0.0;
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop281::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop281::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop281::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop281::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R4_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R4_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R4_P_Ground1_P_p_P_i;
       vars[3] =_system->_R4_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R4_P_n1_P_i;
       vars[5] =_system->_R4_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R4_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R4_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R4_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_R4_P_n2_P_i;
       vars[10] =_system->_R4_P_Capacitor1_P_i;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop281::getNominalReal(double* vars)
{
       vars[0] =_system->_R4_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R4_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R4_P_Ground1_P_p_P_i;
       vars[3] =_system->_R4_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R4_P_n1_P_i;
       vars[5] =_system->_R4_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R4_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R4_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R4_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_R4_P_n2_P_i;
       vars[10] =_system->_R4_P_Capacitor1_P_i;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop281::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R4_P_IdealCommutingSwitch2_P_n2_P_i=vars[0];
     _system->_R4_P_IdealCommutingSwitch2_P_s2=vars[1];
     _system->_R4_P_Ground1_P_p_P_i=vars[2];
     _system->_R4_P_IdealCommutingSwitch1_P_s1=vars[3];
     _system->_R4_P_n1_P_i=vars[4];
     _system->_R4_P_IdealCommutingSwitch1_P_s2=vars[5];
     _system->_R4_P_Capacitor1_P_p_P_v=vars[6];
     _system->_R4_P_Capacitor1_P_n_P_v=vars[7];
     _system->_R4_P_IdealCommutingSwitch2_P_s1=vars[8];
     _system->_R4_P_n2_P_i=vars[9];
     _system->_R4_P_Capacitor1_P_i=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop281::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop281::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop281::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop281::isLinearTearing()
  {
       return false;
  }