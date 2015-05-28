/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop131.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop131::CauerLowPassSCAlgloop131(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop131::~CauerLowPassSCAlgloop131()
{
}

bool CauerLowPassSCAlgloop131::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop131::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop131::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop131::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop131::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop131::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop131::initialize(T *__A)
  {
         double tmp262;
         double tmp263;
         double tmp264;
         double tmp265;
         double tmp266;
         double tmp267;
         double tmp268;
         double tmp269;
          (*__A)(0+1,6+1)=1.0;
          if (_system->_R10_P_BooleanPulse1_P_y) {
            tmp262 = 1.0;
          } else {
            tmp262 = _system->_R10_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(0+1,10+1)=(-tmp262);
          (*__A)(1+1,9+1)=1.0;
          if (_system->_R10_P_BooleanPulse1_P_y) {
            tmp263 = _system->_R10_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp263 = 1.0;
          }
          (*__A)(1+1,10+1)=tmp263;
          (*__A)(2+1,2+1)=1.0;
          (*__A)(2+1,8+1)=-1.0;
          (*__A)(2+1,9+1)=-1.0;
          if (_system->_R10_P_BooleanPulse1_P_y) {
            tmp264 = 1.0;
          } else {
            tmp264 = _system->_R10_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(3+1,7+1)=tmp264;
          (*__A)(3+1,8+1)=1.0;
          (*__A)(4+1,6+1)=1.0;
          if (_system->_R10_P_BooleanPulse1_P_y) {
            tmp265 = _system->_R10_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp265 = 1.0;
          }
          (*__A)(4+1,7+1)=(-tmp265);
          (*__A)(5+1,5+1)=1.0;
          (*__A)(5+1,6+1)=-1.0;
          if (_system->_R10_P_BooleanPulse1_P_y) {
            tmp266 = 1.0;
          } else {
            tmp266 = _system->_R10_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(6+1,4+1)=(-tmp266);
          (*__A)(6+1,5+1)=1.0;
          (*__A)(7+1,3+1)=1.0;
          if (_system->_R10_P_BooleanPulse1_P_y) {
            tmp267 = _system->_R10_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp267 = 1.0;
          }
          (*__A)(7+1,4+1)=tmp267;
          (*__A)(8+1,0+1)=-1.0;
          (*__A)(8+1,2+1)=-1.0;
          (*__A)(8+1,3+1)=-1.0;
          if (_system->_R10_P_BooleanPulse1_P_y) {
            tmp268 = _system->_R10_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp268 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp268);
          (*__A)(9+1,5+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R10_P_BooleanPulse1_P_y) {
            tmp269 = 1.0;
          } else {
            tmp269 = _system->_R10_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp269;
          __b(1)=(-__z[4]);
          __b(2)=-0.0;
          __b(3)=0.0;
          __b(4)=-0.0;
          __b(5)=-0.0;
          __b(6)=(-__z[6]);
          __b(7)=-0.0;
          __b(8)=-0.0;
          __b(9)=0.0;
          __b(10)=-0.0;
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop131::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop131::evaluate()
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
void CauerLowPassSCAlgloop131::evaluate(T* __A)
{
    double tmp271;
    double tmp272;
    double tmp273;
    double tmp274;
    double tmp275;
    double tmp276;
    double tmp277;
    double tmp278;
    (*__A)(0+1,6+1)=1.0;
    if (_system->_R10_P_BooleanPulse1_P_y) {
      tmp271 = 1.0;
    } else {
      tmp271 = _system->_R10_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(0+1,10+1)=(-tmp271);
    (*__A)(1+1,9+1)=1.0;
    if (_system->_R10_P_BooleanPulse1_P_y) {
      tmp272 = _system->_R10_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp272 = 1.0;
    }
    (*__A)(1+1,10+1)=tmp272;
    (*__A)(2+1,2+1)=1.0;
    (*__A)(2+1,8+1)=-1.0;
    (*__A)(2+1,9+1)=-1.0;
    if (_system->_R10_P_BooleanPulse1_P_y) {
      tmp273 = 1.0;
    } else {
      tmp273 = _system->_R10_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(3+1,7+1)=tmp273;
    (*__A)(3+1,8+1)=1.0;
    (*__A)(4+1,6+1)=1.0;
    if (_system->_R10_P_BooleanPulse1_P_y) {
      tmp274 = _system->_R10_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp274 = 1.0;
    }
    (*__A)(4+1,7+1)=(-tmp274);
    (*__A)(5+1,5+1)=1.0;
    (*__A)(5+1,6+1)=-1.0;
    if (_system->_R10_P_BooleanPulse1_P_y) {
      tmp275 = 1.0;
    } else {
      tmp275 = _system->_R10_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(6+1,4+1)=(-tmp275);
    (*__A)(6+1,5+1)=1.0;
    (*__A)(7+1,3+1)=1.0;
    if (_system->_R10_P_BooleanPulse1_P_y) {
      tmp276 = _system->_R10_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp276 = 1.0;
    }
    (*__A)(7+1,4+1)=tmp276;
    (*__A)(8+1,0+1)=-1.0;
    (*__A)(8+1,2+1)=-1.0;
    (*__A)(8+1,3+1)=-1.0;
    if (_system->_R10_P_BooleanPulse1_P_y) {
      tmp277 = _system->_R10_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp277 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp277);
    (*__A)(9+1,5+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R10_P_BooleanPulse1_P_y) {
      tmp278 = 1.0;
    } else {
      tmp278 = _system->_R10_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp278;
    __b(1)=(-__z[4]);
    __b(2)=-0.0;
    __b(3)=0.0;
    __b(4)=-0.0;
    __b(5)=-0.0;
    __b(6)=(-__z[6]);
    __b(7)=-0.0;
    __b(8)=-0.0;
    __b(9)=0.0;
    __b(10)=-0.0;
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop131::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop131::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop131::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop131::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R10_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R10_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R10_P_Capacitor1_P_i;
       vars[3] =_system->_R10_P_n2_P_i;
       vars[4] =_system->_R10_P_IdealCommutingSwitch2_P_s1;
       vars[5] =_system->_R10_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R10_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R10_P_IdealCommutingSwitch1_P_s2;
       vars[8] =_system->_R10_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[9] =_system->_R10_P_n1_P_i;
       vars[10] =_system->_R10_P_IdealCommutingSwitch1_P_s1;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop131::getNominalReal(double* vars)
{
       vars[0] =_system->_R10_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R10_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R10_P_Capacitor1_P_i;
       vars[3] =_system->_R10_P_n2_P_i;
       vars[4] =_system->_R10_P_IdealCommutingSwitch2_P_s1;
       vars[5] =_system->_R10_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R10_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R10_P_IdealCommutingSwitch1_P_s2;
       vars[8] =_system->_R10_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[9] =_system->_R10_P_n1_P_i;
       vars[10] =_system->_R10_P_IdealCommutingSwitch1_P_s1;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop131::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R10_P_IdealCommutingSwitch2_P_n2_P_i=vars[0];
     _system->_R10_P_IdealCommutingSwitch2_P_s2=vars[1];
     _system->_R10_P_Capacitor1_P_i=vars[2];
     _system->_R10_P_n2_P_i=vars[3];
     _system->_R10_P_IdealCommutingSwitch2_P_s1=vars[4];
     _system->_R10_P_Capacitor1_P_n_P_v=vars[5];
     _system->_R10_P_Capacitor1_P_p_P_v=vars[6];
     _system->_R10_P_IdealCommutingSwitch1_P_s2=vars[7];
     _system->_R10_P_IdealCommutingSwitch1_P_n2_P_i=vars[8];
     _system->_R10_P_n1_P_i=vars[9];
     _system->_R10_P_IdealCommutingSwitch1_P_s1=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop131::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop131::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop131::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop131::isLinearTearing()
  {
       return false;
  }