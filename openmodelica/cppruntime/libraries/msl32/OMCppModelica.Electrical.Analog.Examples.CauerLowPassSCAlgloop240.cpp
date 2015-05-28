/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop240.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop240::CauerLowPassSCAlgloop240(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop240::~CauerLowPassSCAlgloop240()
{
}

bool CauerLowPassSCAlgloop240::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop240::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop240::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop240::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop240::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop240::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop240::initialize(T *__A)
  {
         double tmp108;
         double tmp109;
         double tmp110;
         double tmp111;
         double tmp112;
         double tmp113;
         double tmp114;
         double tmp115;
          (*__A)(0+1,2+1)=-1.0;
          (*__A)(0+1,4+1)=-1.0;
          (*__A)(0+1,10+1)=1.0;
          (*__A)(1+1,0+1)=-1.0;
          (*__A)(1+1,9+1)=-1.0;
          (*__A)(1+1,10+1)=-1.0;
          if (_system->_Rp1_P_BooleanPulse1_P_y) {
            tmp108 = _system->_Rp1_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp108 = 1.0;
          }
          (*__A)(2+1,8+1)=tmp108;
          (*__A)(2+1,9+1)=1.0;
          (*__A)(3+1,7+1)=1.0;
          if (_system->_Rp1_P_BooleanPulse1_P_y) {
            tmp109 = 1.0;
          } else {
            tmp109 = _system->_Rp1_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(3+1,8+1)=(-tmp109);
          (*__A)(4+1,6+1)=-1.0;
          (*__A)(4+1,7+1)=1.0;
          if (_system->_Rp1_P_BooleanPulse1_P_y) {
            tmp110 = _system->_Rp1_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp110 = 1.0;
          }
          (*__A)(5+1,5+1)=(-tmp110);
          (*__A)(5+1,6+1)=1.0;
          (*__A)(6+1,4+1)=1.0;
          if (_system->_Rp1_P_BooleanPulse1_P_y) {
            tmp111 = 1.0;
          } else {
            tmp111 = _system->_Rp1_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(6+1,5+1)=tmp111;
          if (_system->_Rp1_P_BooleanPulse1_P_y) {
            tmp112 = 1.0;
          } else {
            tmp112 = _system->_Rp1_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(7+1,3+1)=(-tmp112);
          (*__A)(7+1,6+1)=1.0;
          (*__A)(8+1,2+1)=1.0;
          if (_system->_Rp1_P_BooleanPulse1_P_y) {
            tmp113 = _system->_Rp1_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp113 = 1.0;
          }
          (*__A)(8+1,3+1)=tmp113;
          if (_system->_Rp1_P_BooleanPulse1_P_y) {
            tmp114 = _system->_Rp1_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp114 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp114);
          (*__A)(9+1,7+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_Rp1_P_BooleanPulse1_P_y) {
            tmp115 = 1.0;
          } else {
            tmp115 = _system->_Rp1_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp115;
          __b(1)=0.0;
          __b(2)=0.0;
          __b(3)=-0.0;
          __b(4)=-0.0;
          __b(5)=(-__z[15]);
          __b(6)=-0.0;
          __b(7)=-0.0;
          __b(8)=(-__z[4]);
          __b(9)=-0.0;
          __b(10)=-0.0;
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop240::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop240::evaluate()
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
void CauerLowPassSCAlgloop240::evaluate(T* __A)
{
    double tmp117;
    double tmp118;
    double tmp119;
    double tmp120;
    double tmp121;
    double tmp122;
    double tmp123;
    double tmp124;
    (*__A)(0+1,2+1)=-1.0;
    (*__A)(0+1,4+1)=-1.0;
    (*__A)(0+1,10+1)=1.0;
    (*__A)(1+1,0+1)=-1.0;
    (*__A)(1+1,9+1)=-1.0;
    (*__A)(1+1,10+1)=-1.0;
    if (_system->_Rp1_P_BooleanPulse1_P_y) {
      tmp117 = _system->_Rp1_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp117 = 1.0;
    }
    (*__A)(2+1,8+1)=tmp117;
    (*__A)(2+1,9+1)=1.0;
    (*__A)(3+1,7+1)=1.0;
    if (_system->_Rp1_P_BooleanPulse1_P_y) {
      tmp118 = 1.0;
    } else {
      tmp118 = _system->_Rp1_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(3+1,8+1)=(-tmp118);
    (*__A)(4+1,6+1)=-1.0;
    (*__A)(4+1,7+1)=1.0;
    if (_system->_Rp1_P_BooleanPulse1_P_y) {
      tmp119 = _system->_Rp1_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp119 = 1.0;
    }
    (*__A)(5+1,5+1)=(-tmp119);
    (*__A)(5+1,6+1)=1.0;
    (*__A)(6+1,4+1)=1.0;
    if (_system->_Rp1_P_BooleanPulse1_P_y) {
      tmp120 = 1.0;
    } else {
      tmp120 = _system->_Rp1_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(6+1,5+1)=tmp120;
    if (_system->_Rp1_P_BooleanPulse1_P_y) {
      tmp121 = 1.0;
    } else {
      tmp121 = _system->_Rp1_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(7+1,3+1)=(-tmp121);
    (*__A)(7+1,6+1)=1.0;
    (*__A)(8+1,2+1)=1.0;
    if (_system->_Rp1_P_BooleanPulse1_P_y) {
      tmp122 = _system->_Rp1_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp122 = 1.0;
    }
    (*__A)(8+1,3+1)=tmp122;
    if (_system->_Rp1_P_BooleanPulse1_P_y) {
      tmp123 = _system->_Rp1_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp123 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp123);
    (*__A)(9+1,7+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_Rp1_P_BooleanPulse1_P_y) {
      tmp124 = 1.0;
    } else {
      tmp124 = _system->_Rp1_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp124;
    __b(1)=0.0;
    __b(2)=0.0;
    __b(3)=-0.0;
    __b(4)=-0.0;
    __b(5)=(-__z[15]);
    __b(6)=-0.0;
    __b(7)=-0.0;
    __b(8)=(-__z[4]);
    __b(9)=-0.0;
    __b(10)=-0.0;
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop240::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop240::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop240::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop240::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_Rp1_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_Rp1_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_Rp1_P_n1_P_i;
       vars[3] =_system->_Rp1_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_Rp1_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[5] =_system->_Rp1_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_Rp1_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_Rp1_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_Rp1_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_Rp1_P_n2_P_i;
       vars[10] =_system->_Rp1_P_Capacitor1_P_i;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop240::getNominalReal(double* vars)
{
       vars[0] =_system->_Rp1_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_Rp1_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_Rp1_P_n1_P_i;
       vars[3] =_system->_Rp1_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_Rp1_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[5] =_system->_Rp1_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_Rp1_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_Rp1_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_Rp1_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_Rp1_P_n2_P_i;
       vars[10] =_system->_Rp1_P_Capacitor1_P_i;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop240::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_Rp1_P_IdealCommutingSwitch2_P_n2_P_i=vars[0];
     _system->_Rp1_P_IdealCommutingSwitch2_P_s2=vars[1];
     _system->_Rp1_P_n1_P_i=vars[2];
     _system->_Rp1_P_IdealCommutingSwitch1_P_s1=vars[3];
     _system->_Rp1_P_IdealCommutingSwitch1_P_n2_P_i=vars[4];
     _system->_Rp1_P_IdealCommutingSwitch1_P_s2=vars[5];
     _system->_Rp1_P_Capacitor1_P_p_P_v=vars[6];
     _system->_Rp1_P_Capacitor1_P_n_P_v=vars[7];
     _system->_Rp1_P_IdealCommutingSwitch2_P_s1=vars[8];
     _system->_Rp1_P_n2_P_i=vars[9];
     _system->_Rp1_P_Capacitor1_P_i=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop240::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop240::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop240::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop240::isLinearTearing()
  {
       return false;
  }