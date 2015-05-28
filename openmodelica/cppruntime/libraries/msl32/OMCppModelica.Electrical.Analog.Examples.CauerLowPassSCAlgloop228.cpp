/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop228.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop228::CauerLowPassSCAlgloop228(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop228::~CauerLowPassSCAlgloop228()
{
}

bool CauerLowPassSCAlgloop228::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop228::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop228::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop228::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop228::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop228::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop228::initialize(T *__A)
  {
         double tmp74;
         double tmp75;
         double tmp76;
         double tmp77;
         double tmp78;
         double tmp79;
         double tmp80;
         double tmp81;
          (*__A)(0+1,2+1)=-1.0;
          (*__A)(0+1,4+1)=-1.0;
          (*__A)(0+1,10+1)=1.0;
          (*__A)(1+1,0+1)=-1.0;
          (*__A)(1+1,9+1)=-1.0;
          (*__A)(1+1,10+1)=-1.0;
          if (_system->_R10_P_BooleanPulse1_P_y) {
            tmp74 = _system->_R10_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp74 = 1.0;
          }
          (*__A)(2+1,8+1)=tmp74;
          (*__A)(2+1,9+1)=1.0;
          (*__A)(3+1,7+1)=1.0;
          if (_system->_R10_P_BooleanPulse1_P_y) {
            tmp75 = 1.0;
          } else {
            tmp75 = _system->_R10_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(3+1,8+1)=(-tmp75);
          (*__A)(4+1,6+1)=-1.0;
          (*__A)(4+1,7+1)=1.0;
          if (_system->_R10_P_BooleanPulse1_P_y) {
            tmp76 = _system->_R10_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp76 = 1.0;
          }
          (*__A)(5+1,5+1)=(-tmp76);
          (*__A)(5+1,6+1)=1.0;
          (*__A)(6+1,4+1)=1.0;
          if (_system->_R10_P_BooleanPulse1_P_y) {
            tmp77 = 1.0;
          } else {
            tmp77 = _system->_R10_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(6+1,5+1)=tmp77;
          if (_system->_R10_P_BooleanPulse1_P_y) {
            tmp78 = 1.0;
          } else {
            tmp78 = _system->_R10_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(7+1,3+1)=(-tmp78);
          (*__A)(7+1,6+1)=1.0;
          (*__A)(8+1,2+1)=1.0;
          if (_system->_R10_P_BooleanPulse1_P_y) {
            tmp79 = _system->_R10_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp79 = 1.0;
          }
          (*__A)(8+1,3+1)=tmp79;
          if (_system->_R10_P_BooleanPulse1_P_y) {
            tmp80 = _system->_R10_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp80 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp80);
          (*__A)(9+1,7+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R10_P_BooleanPulse1_P_y) {
            tmp81 = 1.0;
          } else {
            tmp81 = _system->_R10_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp81;
          __b(1)=0.0;
          __b(2)=0.0;
          __b(3)=-0.0;
          __b(4)=-0.0;
          __b(5)=(-__z[6]);
          __b(6)=-0.0;
          __b(7)=-0.0;
          __b(8)=(-__z[4]);
          __b(9)=-0.0;
          __b(10)=-0.0;
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop228::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop228::evaluate()
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
void CauerLowPassSCAlgloop228::evaluate(T* __A)
{
    double tmp83;
    double tmp84;
    double tmp85;
    double tmp86;
    double tmp87;
    double tmp88;
    double tmp89;
    double tmp90;
    (*__A)(0+1,2+1)=-1.0;
    (*__A)(0+1,4+1)=-1.0;
    (*__A)(0+1,10+1)=1.0;
    (*__A)(1+1,0+1)=-1.0;
    (*__A)(1+1,9+1)=-1.0;
    (*__A)(1+1,10+1)=-1.0;
    if (_system->_R10_P_BooleanPulse1_P_y) {
      tmp83 = _system->_R10_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp83 = 1.0;
    }
    (*__A)(2+1,8+1)=tmp83;
    (*__A)(2+1,9+1)=1.0;
    (*__A)(3+1,7+1)=1.0;
    if (_system->_R10_P_BooleanPulse1_P_y) {
      tmp84 = 1.0;
    } else {
      tmp84 = _system->_R10_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(3+1,8+1)=(-tmp84);
    (*__A)(4+1,6+1)=-1.0;
    (*__A)(4+1,7+1)=1.0;
    if (_system->_R10_P_BooleanPulse1_P_y) {
      tmp85 = _system->_R10_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp85 = 1.0;
    }
    (*__A)(5+1,5+1)=(-tmp85);
    (*__A)(5+1,6+1)=1.0;
    (*__A)(6+1,4+1)=1.0;
    if (_system->_R10_P_BooleanPulse1_P_y) {
      tmp86 = 1.0;
    } else {
      tmp86 = _system->_R10_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(6+1,5+1)=tmp86;
    if (_system->_R10_P_BooleanPulse1_P_y) {
      tmp87 = 1.0;
    } else {
      tmp87 = _system->_R10_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(7+1,3+1)=(-tmp87);
    (*__A)(7+1,6+1)=1.0;
    (*__A)(8+1,2+1)=1.0;
    if (_system->_R10_P_BooleanPulse1_P_y) {
      tmp88 = _system->_R10_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp88 = 1.0;
    }
    (*__A)(8+1,3+1)=tmp88;
    if (_system->_R10_P_BooleanPulse1_P_y) {
      tmp89 = _system->_R10_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp89 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp89);
    (*__A)(9+1,7+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R10_P_BooleanPulse1_P_y) {
      tmp90 = 1.0;
    } else {
      tmp90 = _system->_R10_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp90;
    __b(1)=0.0;
    __b(2)=0.0;
    __b(3)=-0.0;
    __b(4)=-0.0;
    __b(5)=(-__z[6]);
    __b(6)=-0.0;
    __b(7)=-0.0;
    __b(8)=(-__z[4]);
    __b(9)=-0.0;
    __b(10)=-0.0;
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop228::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop228::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop228::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop228::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R10_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R10_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R10_P_n1_P_i;
       vars[3] =_system->_R10_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R10_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[5] =_system->_R10_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R10_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R10_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R10_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_R10_P_n2_P_i;
       vars[10] =_system->_R10_P_Capacitor1_P_i;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop228::getNominalReal(double* vars)
{
       vars[0] =_system->_R10_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R10_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R10_P_n1_P_i;
       vars[3] =_system->_R10_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R10_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[5] =_system->_R10_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R10_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R10_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R10_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_R10_P_n2_P_i;
       vars[10] =_system->_R10_P_Capacitor1_P_i;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop228::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R10_P_IdealCommutingSwitch2_P_n2_P_i=vars[0];
     _system->_R10_P_IdealCommutingSwitch2_P_s2=vars[1];
     _system->_R10_P_n1_P_i=vars[2];
     _system->_R10_P_IdealCommutingSwitch1_P_s1=vars[3];
     _system->_R10_P_IdealCommutingSwitch1_P_n2_P_i=vars[4];
     _system->_R10_P_IdealCommutingSwitch1_P_s2=vars[5];
     _system->_R10_P_Capacitor1_P_p_P_v=vars[6];
     _system->_R10_P_Capacitor1_P_n_P_v=vars[7];
     _system->_R10_P_IdealCommutingSwitch2_P_s1=vars[8];
     _system->_R10_P_n2_P_i=vars[9];
     _system->_R10_P_Capacitor1_P_i=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop228::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop228::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop228::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop228::isLinearTearing()
  {
       return false;
  }