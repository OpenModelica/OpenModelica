/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop124.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop124::CauerLowPassSCAlgloop124(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop124::~CauerLowPassSCAlgloop124()
{
}

bool CauerLowPassSCAlgloop124::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop124::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop124::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop124::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop124::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop124::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop124::initialize(T *__A)
  {
         double tmp245;
         double tmp246;
         double tmp247;
         double tmp248;
         double tmp249;
         double tmp250;
         double tmp251;
         double tmp252;
          (*__A)(0+1,2+1)=1.0;
          if (_system->_R11_P_BooleanPulse1_P_y) {
            tmp245 = 1.0;
          } else {
            tmp245 = _system->_R11_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(0+1,10+1)=(-tmp245);
          (*__A)(1+1,9+1)=1.0;
          if (_system->_R11_P_BooleanPulse1_P_y) {
            tmp246 = _system->_R11_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp246 = 1.0;
          }
          (*__A)(1+1,10+1)=tmp246;
          (*__A)(2+1,0+1)=-1.0;
          (*__A)(2+1,8+1)=1.0;
          (*__A)(2+1,9+1)=-1.0;
          (*__A)(3+1,3+1)=-1.0;
          (*__A)(3+1,7+1)=-1.0;
          (*__A)(3+1,8+1)=-1.0;
          if (_system->_R11_P_BooleanPulse1_P_y) {
            tmp247 = 1.0;
          } else {
            tmp247 = _system->_R11_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(4+1,6+1)=tmp247;
          (*__A)(4+1,7+1)=1.0;
          (*__A)(5+1,5+1)=1.0;
          if (_system->_R11_P_BooleanPulse1_P_y) {
            tmp248 = _system->_R11_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp248 = 1.0;
          }
          (*__A)(5+1,6+1)=(-tmp248);
          if (_system->_R11_P_BooleanPulse1_P_y) {
            tmp249 = 1.0;
          } else {
            tmp249 = _system->_R11_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(6+1,4+1)=(-tmp249);
          (*__A)(6+1,5+1)=1.0;
          (*__A)(7+1,3+1)=1.0;
          if (_system->_R11_P_BooleanPulse1_P_y) {
            tmp250 = _system->_R11_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp250 = 1.0;
          }
          (*__A)(7+1,4+1)=tmp250;
          (*__A)(8+1,2+1)=-1.0;
          (*__A)(8+1,5+1)=1.0;
          if (_system->_R11_P_BooleanPulse1_P_y) {
            tmp251 = _system->_R11_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp251 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp251);
          (*__A)(9+1,2+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R11_P_BooleanPulse1_P_y) {
            tmp252 = 1.0;
          } else {
            tmp252 = _system->_R11_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp252;
          __b(1)=-0.0;
          __b(2)=-0.0;
          __b(3)=0.0;
          __b(4)=0.0;
          __b(5)=-0.0;
          __b(6)=-0.0;
          __b(7)=__z[3];
          __b(8)=-0.0;
          __b(9)=(-__z[7]);
          __b(10)=-0.0;
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop124::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop124::evaluate()
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
void CauerLowPassSCAlgloop124::evaluate(T* __A)
{
    double tmp254;
    double tmp255;
    double tmp256;
    double tmp257;
    double tmp258;
    double tmp259;
    double tmp260;
    double tmp261;
    (*__A)(0+1,2+1)=1.0;
    if (_system->_R11_P_BooleanPulse1_P_y) {
      tmp254 = 1.0;
    } else {
      tmp254 = _system->_R11_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(0+1,10+1)=(-tmp254);
    (*__A)(1+1,9+1)=1.0;
    if (_system->_R11_P_BooleanPulse1_P_y) {
      tmp255 = _system->_R11_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp255 = 1.0;
    }
    (*__A)(1+1,10+1)=tmp255;
    (*__A)(2+1,0+1)=-1.0;
    (*__A)(2+1,8+1)=1.0;
    (*__A)(2+1,9+1)=-1.0;
    (*__A)(3+1,3+1)=-1.0;
    (*__A)(3+1,7+1)=-1.0;
    (*__A)(3+1,8+1)=-1.0;
    if (_system->_R11_P_BooleanPulse1_P_y) {
      tmp256 = 1.0;
    } else {
      tmp256 = _system->_R11_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(4+1,6+1)=tmp256;
    (*__A)(4+1,7+1)=1.0;
    (*__A)(5+1,5+1)=1.0;
    if (_system->_R11_P_BooleanPulse1_P_y) {
      tmp257 = _system->_R11_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp257 = 1.0;
    }
    (*__A)(5+1,6+1)=(-tmp257);
    if (_system->_R11_P_BooleanPulse1_P_y) {
      tmp258 = 1.0;
    } else {
      tmp258 = _system->_R11_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(6+1,4+1)=(-tmp258);
    (*__A)(6+1,5+1)=1.0;
    (*__A)(7+1,3+1)=1.0;
    if (_system->_R11_P_BooleanPulse1_P_y) {
      tmp259 = _system->_R11_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp259 = 1.0;
    }
    (*__A)(7+1,4+1)=tmp259;
    (*__A)(8+1,2+1)=-1.0;
    (*__A)(8+1,5+1)=1.0;
    if (_system->_R11_P_BooleanPulse1_P_y) {
      tmp260 = _system->_R11_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp260 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp260);
    (*__A)(9+1,2+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R11_P_BooleanPulse1_P_y) {
      tmp261 = 1.0;
    } else {
      tmp261 = _system->_R11_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp261;
    __b(1)=-0.0;
    __b(2)=-0.0;
    __b(3)=0.0;
    __b(4)=0.0;
    __b(5)=-0.0;
    __b(6)=-0.0;
    __b(7)=__z[3];
    __b(8)=-0.0;
    __b(9)=(-__z[7]);
    __b(10)=-0.0;
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop124::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop124::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop124::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop124::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R11_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[1] =_system->_R11_P_IdealCommutingSwitch1_P_s2;
       vars[2] =_system->_R11_P_Capacitor1_P_p_P_v;
       vars[3] =_system->_R11_P_n2_P_i;
       vars[4] =_system->_R11_P_IdealCommutingSwitch2_P_s1;
       vars[5] =_system->_R11_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R11_P_IdealCommutingSwitch2_P_s2;
       vars[7] =_system->_R11_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[8] =_system->_R11_P_Capacitor1_P_i;
       vars[9] =_system->_R11_P_n1_P_i;
       vars[10] =_system->_R11_P_IdealCommutingSwitch1_P_s1;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop124::getNominalReal(double* vars)
{
       vars[0] =_system->_R11_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[1] =_system->_R11_P_IdealCommutingSwitch1_P_s2;
       vars[2] =_system->_R11_P_Capacitor1_P_p_P_v;
       vars[3] =_system->_R11_P_n2_P_i;
       vars[4] =_system->_R11_P_IdealCommutingSwitch2_P_s1;
       vars[5] =_system->_R11_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R11_P_IdealCommutingSwitch2_P_s2;
       vars[7] =_system->_R11_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[8] =_system->_R11_P_Capacitor1_P_i;
       vars[9] =_system->_R11_P_n1_P_i;
       vars[10] =_system->_R11_P_IdealCommutingSwitch1_P_s1;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop124::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R11_P_IdealCommutingSwitch1_P_n2_P_i=vars[0];
     _system->_R11_P_IdealCommutingSwitch1_P_s2=vars[1];
     _system->_R11_P_Capacitor1_P_p_P_v=vars[2];
     _system->_R11_P_n2_P_i=vars[3];
     _system->_R11_P_IdealCommutingSwitch2_P_s1=vars[4];
     _system->_R11_P_Capacitor1_P_n_P_v=vars[5];
     _system->_R11_P_IdealCommutingSwitch2_P_s2=vars[6];
     _system->_R11_P_IdealCommutingSwitch2_P_n2_P_i=vars[7];
     _system->_R11_P_Capacitor1_P_i=vars[8];
     _system->_R11_P_n1_P_i=vars[9];
     _system->_R11_P_IdealCommutingSwitch1_P_s1=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop124::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop124::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop124::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop124::isLinearTearing()
  {
       return false;
  }