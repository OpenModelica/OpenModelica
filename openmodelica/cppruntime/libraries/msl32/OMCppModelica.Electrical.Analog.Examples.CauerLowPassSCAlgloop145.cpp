/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop145.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop145::CauerLowPassSCAlgloop145(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop145::~CauerLowPassSCAlgloop145()
{
}

bool CauerLowPassSCAlgloop145::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop145::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop145::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop145::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop145::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop145::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop145::initialize(T *__A)
  {
         double tmp296;
         double tmp297;
         double tmp298;
         double tmp299;
         double tmp300;
         double tmp301;
         double tmp302;
         double tmp303;
          (*__A)(0+1,2+1)=1.0;
          if (_system->_Rp1_P_BooleanPulse1_P_y) {
            tmp296 = 1.0;
          } else {
            tmp296 = _system->_Rp1_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(0+1,10+1)=(-tmp296);
          (*__A)(1+1,9+1)=1.0;
          if (_system->_Rp1_P_BooleanPulse1_P_y) {
            tmp297 = _system->_Rp1_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp297 = 1.0;
          }
          (*__A)(1+1,10+1)=tmp297;
          (*__A)(2+1,0+1)=-1.0;
          (*__A)(2+1,8+1)=1.0;
          (*__A)(2+1,9+1)=-1.0;
          (*__A)(3+1,3+1)=-1.0;
          (*__A)(3+1,7+1)=-1.0;
          (*__A)(3+1,8+1)=-1.0;
          if (_system->_Rp1_P_BooleanPulse1_P_y) {
            tmp298 = _system->_Rp1_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp298 = 1.0;
          }
          (*__A)(4+1,6+1)=tmp298;
          (*__A)(4+1,7+1)=1.0;
          (*__A)(5+1,5+1)=1.0;
          if (_system->_Rp1_P_BooleanPulse1_P_y) {
            tmp299 = 1.0;
          } else {
            tmp299 = _system->_Rp1_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(5+1,6+1)=(-tmp299);
          if (_system->_Rp1_P_BooleanPulse1_P_y) {
            tmp300 = _system->_Rp1_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp300 = 1.0;
          }
          (*__A)(6+1,4+1)=(-tmp300);
          (*__A)(6+1,5+1)=1.0;
          (*__A)(7+1,3+1)=1.0;
          if (_system->_Rp1_P_BooleanPulse1_P_y) {
            tmp301 = 1.0;
          } else {
            tmp301 = _system->_Rp1_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(7+1,4+1)=tmp301;
          (*__A)(8+1,2+1)=-1.0;
          (*__A)(8+1,5+1)=1.0;
          if (_system->_Rp1_P_BooleanPulse1_P_y) {
            tmp302 = _system->_Rp1_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp302 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp302);
          (*__A)(9+1,2+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_Rp1_P_BooleanPulse1_P_y) {
            tmp303 = 1.0;
          } else {
            tmp303 = _system->_Rp1_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp303;
          __b(1)=(-__z[4]);
          __b(2)=-0.0;
          __b(3)=0.0;
          __b(4)=0.0;
          __b(5)=-0.0;
          __b(6)=-0.0;
          __b(7)=-0.0;
          __b(8)=-0.0;
          __b(9)=(-__z[15]);
          __b(10)=-0.0;
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop145::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop145::evaluate()
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
void CauerLowPassSCAlgloop145::evaluate(T* __A)
{
    double tmp305;
    double tmp306;
    double tmp307;
    double tmp308;
    double tmp309;
    double tmp310;
    double tmp311;
    double tmp312;
    (*__A)(0+1,2+1)=1.0;
    if (_system->_Rp1_P_BooleanPulse1_P_y) {
      tmp305 = 1.0;
    } else {
      tmp305 = _system->_Rp1_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(0+1,10+1)=(-tmp305);
    (*__A)(1+1,9+1)=1.0;
    if (_system->_Rp1_P_BooleanPulse1_P_y) {
      tmp306 = _system->_Rp1_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp306 = 1.0;
    }
    (*__A)(1+1,10+1)=tmp306;
    (*__A)(2+1,0+1)=-1.0;
    (*__A)(2+1,8+1)=1.0;
    (*__A)(2+1,9+1)=-1.0;
    (*__A)(3+1,3+1)=-1.0;
    (*__A)(3+1,7+1)=-1.0;
    (*__A)(3+1,8+1)=-1.0;
    if (_system->_Rp1_P_BooleanPulse1_P_y) {
      tmp307 = _system->_Rp1_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp307 = 1.0;
    }
    (*__A)(4+1,6+1)=tmp307;
    (*__A)(4+1,7+1)=1.0;
    (*__A)(5+1,5+1)=1.0;
    if (_system->_Rp1_P_BooleanPulse1_P_y) {
      tmp308 = 1.0;
    } else {
      tmp308 = _system->_Rp1_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(5+1,6+1)=(-tmp308);
    if (_system->_Rp1_P_BooleanPulse1_P_y) {
      tmp309 = _system->_Rp1_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp309 = 1.0;
    }
    (*__A)(6+1,4+1)=(-tmp309);
    (*__A)(6+1,5+1)=1.0;
    (*__A)(7+1,3+1)=1.0;
    if (_system->_Rp1_P_BooleanPulse1_P_y) {
      tmp310 = 1.0;
    } else {
      tmp310 = _system->_Rp1_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(7+1,4+1)=tmp310;
    (*__A)(8+1,2+1)=-1.0;
    (*__A)(8+1,5+1)=1.0;
    if (_system->_Rp1_P_BooleanPulse1_P_y) {
      tmp311 = _system->_Rp1_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp311 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp311);
    (*__A)(9+1,2+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_Rp1_P_BooleanPulse1_P_y) {
      tmp312 = 1.0;
    } else {
      tmp312 = _system->_Rp1_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp312;
    __b(1)=(-__z[4]);
    __b(2)=-0.0;
    __b(3)=0.0;
    __b(4)=0.0;
    __b(5)=-0.0;
    __b(6)=-0.0;
    __b(7)=-0.0;
    __b(8)=-0.0;
    __b(9)=(-__z[15]);
    __b(10)=-0.0;
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop145::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop145::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop145::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop145::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_Rp1_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[1] =_system->_Rp1_P_IdealCommutingSwitch1_P_s2;
       vars[2] =_system->_Rp1_P_Capacitor1_P_p_P_v;
       vars[3] =_system->_Rp1_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[4] =_system->_Rp1_P_IdealCommutingSwitch2_P_s2;
       vars[5] =_system->_Rp1_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_Rp1_P_IdealCommutingSwitch2_P_s1;
       vars[7] =_system->_Rp1_P_n2_P_i;
       vars[8] =_system->_Rp1_P_Capacitor1_P_i;
       vars[9] =_system->_Rp1_P_n1_P_i;
       vars[10] =_system->_Rp1_P_IdealCommutingSwitch1_P_s1;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop145::getNominalReal(double* vars)
{
       vars[0] =_system->_Rp1_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[1] =_system->_Rp1_P_IdealCommutingSwitch1_P_s2;
       vars[2] =_system->_Rp1_P_Capacitor1_P_p_P_v;
       vars[3] =_system->_Rp1_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[4] =_system->_Rp1_P_IdealCommutingSwitch2_P_s2;
       vars[5] =_system->_Rp1_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_Rp1_P_IdealCommutingSwitch2_P_s1;
       vars[7] =_system->_Rp1_P_n2_P_i;
       vars[8] =_system->_Rp1_P_Capacitor1_P_i;
       vars[9] =_system->_Rp1_P_n1_P_i;
       vars[10] =_system->_Rp1_P_IdealCommutingSwitch1_P_s1;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop145::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_Rp1_P_IdealCommutingSwitch1_P_n2_P_i=vars[0];
     _system->_Rp1_P_IdealCommutingSwitch1_P_s2=vars[1];
     _system->_Rp1_P_Capacitor1_P_p_P_v=vars[2];
     _system->_Rp1_P_IdealCommutingSwitch2_P_n2_P_i=vars[3];
     _system->_Rp1_P_IdealCommutingSwitch2_P_s2=vars[4];
     _system->_Rp1_P_Capacitor1_P_n_P_v=vars[5];
     _system->_Rp1_P_IdealCommutingSwitch2_P_s1=vars[6];
     _system->_Rp1_P_n2_P_i=vars[7];
     _system->_Rp1_P_Capacitor1_P_i=vars[8];
     _system->_Rp1_P_n1_P_i=vars[9];
     _system->_Rp1_P_IdealCommutingSwitch1_P_s1=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop145::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop145::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop145::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop145::isLinearTearing()
  {
       return false;
  }