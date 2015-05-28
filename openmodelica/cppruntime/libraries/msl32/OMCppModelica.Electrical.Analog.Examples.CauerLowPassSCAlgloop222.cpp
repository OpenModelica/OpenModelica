/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop222.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop222::CauerLowPassSCAlgloop222(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop222::~CauerLowPassSCAlgloop222()
{
}

bool CauerLowPassSCAlgloop222::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop222::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop222::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop222::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop222::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop222::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop222::initialize(T *__A)
  {
         double tmp57;
         double tmp58;
         double tmp59;
         double tmp60;
         double tmp61;
         double tmp62;
         double tmp63;
         double tmp64;
          (*__A)(0+1,2+1)=-1.0;
          (*__A)(0+1,4+1)=-1.0;
          (*__A)(0+1,10+1)=1.0;
          (*__A)(1+1,0+1)=-1.0;
          (*__A)(1+1,9+1)=-1.0;
          (*__A)(1+1,10+1)=-1.0;
          if (_system->_R11_P_BooleanPulse1_P_y) {
            tmp57 = _system->_R11_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp57 = 1.0;
          }
          (*__A)(2+1,8+1)=tmp57;
          (*__A)(2+1,9+1)=1.0;
          (*__A)(3+1,7+1)=1.0;
          if (_system->_R11_P_BooleanPulse1_P_y) {
            tmp58 = 1.0;
          } else {
            tmp58 = _system->_R11_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(3+1,8+1)=(-tmp58);
          (*__A)(4+1,6+1)=-1.0;
          (*__A)(4+1,7+1)=1.0;
          if (_system->_R11_P_BooleanPulse1_P_y) {
            tmp59 = _system->_R11_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp59 = 1.0;
          }
          (*__A)(5+1,5+1)=(-tmp59);
          (*__A)(5+1,6+1)=1.0;
          (*__A)(6+1,4+1)=1.0;
          if (_system->_R11_P_BooleanPulse1_P_y) {
            tmp60 = 1.0;
          } else {
            tmp60 = _system->_R11_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(6+1,5+1)=tmp60;
          if (_system->_R11_P_BooleanPulse1_P_y) {
            tmp61 = 1.0;
          } else {
            tmp61 = _system->_R11_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(7+1,3+1)=(-tmp61);
          (*__A)(7+1,6+1)=1.0;
          (*__A)(8+1,2+1)=1.0;
          if (_system->_R11_P_BooleanPulse1_P_y) {
            tmp62 = _system->_R11_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp62 = 1.0;
          }
          (*__A)(8+1,3+1)=tmp62;
          if (_system->_R11_P_BooleanPulse1_P_y) {
            tmp63 = _system->_R11_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp63 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp63);
          (*__A)(9+1,7+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R11_P_BooleanPulse1_P_y) {
            tmp64 = 1.0;
          } else {
            tmp64 = _system->_R11_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp64;
          __b(1)=0.0;
          __b(2)=0.0;
          __b(3)=-0.0;
          __b(4)=__z[3];
          __b(5)=(-__z[7]);
          __b(6)=-0.0;
          __b(7)=-0.0;
          __b(8)=-0.0;
          __b(9)=-0.0;
          __b(10)=-0.0;
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop222::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop222::evaluate()
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
void CauerLowPassSCAlgloop222::evaluate(T* __A)
{
    double tmp66;
    double tmp67;
    double tmp68;
    double tmp69;
    double tmp70;
    double tmp71;
    double tmp72;
    double tmp73;
    (*__A)(0+1,2+1)=-1.0;
    (*__A)(0+1,4+1)=-1.0;
    (*__A)(0+1,10+1)=1.0;
    (*__A)(1+1,0+1)=-1.0;
    (*__A)(1+1,9+1)=-1.0;
    (*__A)(1+1,10+1)=-1.0;
    if (_system->_R11_P_BooleanPulse1_P_y) {
      tmp66 = _system->_R11_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp66 = 1.0;
    }
    (*__A)(2+1,8+1)=tmp66;
    (*__A)(2+1,9+1)=1.0;
    (*__A)(3+1,7+1)=1.0;
    if (_system->_R11_P_BooleanPulse1_P_y) {
      tmp67 = 1.0;
    } else {
      tmp67 = _system->_R11_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(3+1,8+1)=(-tmp67);
    (*__A)(4+1,6+1)=-1.0;
    (*__A)(4+1,7+1)=1.0;
    if (_system->_R11_P_BooleanPulse1_P_y) {
      tmp68 = _system->_R11_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp68 = 1.0;
    }
    (*__A)(5+1,5+1)=(-tmp68);
    (*__A)(5+1,6+1)=1.0;
    (*__A)(6+1,4+1)=1.0;
    if (_system->_R11_P_BooleanPulse1_P_y) {
      tmp69 = 1.0;
    } else {
      tmp69 = _system->_R11_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(6+1,5+1)=tmp69;
    if (_system->_R11_P_BooleanPulse1_P_y) {
      tmp70 = 1.0;
    } else {
      tmp70 = _system->_R11_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(7+1,3+1)=(-tmp70);
    (*__A)(7+1,6+1)=1.0;
    (*__A)(8+1,2+1)=1.0;
    if (_system->_R11_P_BooleanPulse1_P_y) {
      tmp71 = _system->_R11_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp71 = 1.0;
    }
    (*__A)(8+1,3+1)=tmp71;
    if (_system->_R11_P_BooleanPulse1_P_y) {
      tmp72 = _system->_R11_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp72 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp72);
    (*__A)(9+1,7+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R11_P_BooleanPulse1_P_y) {
      tmp73 = 1.0;
    } else {
      tmp73 = _system->_R11_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp73;
    __b(1)=0.0;
    __b(2)=0.0;
    __b(3)=-0.0;
    __b(4)=__z[3];
    __b(5)=(-__z[7]);
    __b(6)=-0.0;
    __b(7)=-0.0;
    __b(8)=-0.0;
    __b(9)=-0.0;
    __b(10)=-0.0;
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop222::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop222::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop222::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop222::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R11_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R11_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R11_P_n1_P_i;
       vars[3] =_system->_R11_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R11_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[5] =_system->_R11_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R11_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R11_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R11_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_R11_P_n2_P_i;
       vars[10] =_system->_R11_P_Capacitor1_P_i;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop222::getNominalReal(double* vars)
{
       vars[0] =_system->_R11_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R11_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R11_P_n1_P_i;
       vars[3] =_system->_R11_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R11_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[5] =_system->_R11_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R11_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R11_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R11_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_R11_P_n2_P_i;
       vars[10] =_system->_R11_P_Capacitor1_P_i;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop222::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R11_P_IdealCommutingSwitch2_P_n2_P_i=vars[0];
     _system->_R11_P_IdealCommutingSwitch2_P_s2=vars[1];
     _system->_R11_P_n1_P_i=vars[2];
     _system->_R11_P_IdealCommutingSwitch1_P_s1=vars[3];
     _system->_R11_P_IdealCommutingSwitch1_P_n2_P_i=vars[4];
     _system->_R11_P_IdealCommutingSwitch1_P_s2=vars[5];
     _system->_R11_P_Capacitor1_P_p_P_v=vars[6];
     _system->_R11_P_Capacitor1_P_n_P_v=vars[7];
     _system->_R11_P_IdealCommutingSwitch2_P_s1=vars[8];
     _system->_R11_P_n2_P_i=vars[9];
     _system->_R11_P_Capacitor1_P_i=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop222::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop222::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop222::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop222::isLinearTearing()
  {
       return false;
  }