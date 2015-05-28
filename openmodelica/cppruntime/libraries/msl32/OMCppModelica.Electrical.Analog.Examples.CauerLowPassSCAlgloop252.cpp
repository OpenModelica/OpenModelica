/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop252.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop252::CauerLowPassSCAlgloop252(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop252::~CauerLowPassSCAlgloop252()
{
}

bool CauerLowPassSCAlgloop252::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop252::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop252::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop252::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop252::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop252::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop252::initialize(T *__A)
  {
         double tmp142;
         double tmp143;
         double tmp144;
         double tmp145;
         double tmp146;
         double tmp147;
         double tmp148;
         double tmp149;
          (*__A)(0+1,2+1)=-1.0;
          (*__A)(0+1,4+1)=-1.0;
          (*__A)(0+1,10+1)=1.0;
          (*__A)(1+1,0+1)=-1.0;
          (*__A)(1+1,9+1)=-1.0;
          (*__A)(1+1,10+1)=-1.0;
          if (_system->_R2_P_BooleanPulse1_P_y) {
            tmp142 = _system->_R2_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp142 = 1.0;
          }
          (*__A)(2+1,8+1)=tmp142;
          (*__A)(2+1,9+1)=1.0;
          (*__A)(3+1,7+1)=1.0;
          if (_system->_R2_P_BooleanPulse1_P_y) {
            tmp143 = 1.0;
          } else {
            tmp143 = _system->_R2_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(3+1,8+1)=(-tmp143);
          (*__A)(4+1,6+1)=-1.0;
          (*__A)(4+1,7+1)=1.0;
          if (_system->_R2_P_BooleanPulse1_P_y) {
            tmp144 = _system->_R2_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp144 = 1.0;
          }
          (*__A)(5+1,5+1)=(-tmp144);
          (*__A)(5+1,6+1)=1.0;
          (*__A)(6+1,4+1)=1.0;
          if (_system->_R2_P_BooleanPulse1_P_y) {
            tmp145 = 1.0;
          } else {
            tmp145 = _system->_R2_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(6+1,5+1)=tmp145;
          if (_system->_R2_P_BooleanPulse1_P_y) {
            tmp146 = 1.0;
          } else {
            tmp146 = _system->_R2_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(7+1,3+1)=(-tmp146);
          (*__A)(7+1,6+1)=1.0;
          (*__A)(8+1,2+1)=1.0;
          if (_system->_R2_P_BooleanPulse1_P_y) {
            tmp147 = _system->_R2_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp147 = 1.0;
          }
          (*__A)(8+1,3+1)=tmp147;
          if (_system->_R2_P_BooleanPulse1_P_y) {
            tmp148 = _system->_R2_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp148 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp148);
          (*__A)(9+1,7+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R2_P_BooleanPulse1_P_y) {
            tmp149 = 1.0;
          } else {
            tmp149 = _system->_R2_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp149;
          __b(1)=0.0;
          __b(2)=0.0;
          __b(3)=-0.0;
          __b(4)=-0.0;
          __b(5)=(-__z[8]);
          __b(6)=-0.0;
          __b(7)=-0.0;
          __b(8)=(-__z[2]);
          __b(9)=-0.0;
          __b(10)=-0.0;
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop252::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop252::evaluate()
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
void CauerLowPassSCAlgloop252::evaluate(T* __A)
{
    double tmp151;
    double tmp152;
    double tmp153;
    double tmp154;
    double tmp155;
    double tmp156;
    double tmp157;
    double tmp158;
    (*__A)(0+1,2+1)=-1.0;
    (*__A)(0+1,4+1)=-1.0;
    (*__A)(0+1,10+1)=1.0;
    (*__A)(1+1,0+1)=-1.0;
    (*__A)(1+1,9+1)=-1.0;
    (*__A)(1+1,10+1)=-1.0;
    if (_system->_R2_P_BooleanPulse1_P_y) {
      tmp151 = _system->_R2_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp151 = 1.0;
    }
    (*__A)(2+1,8+1)=tmp151;
    (*__A)(2+1,9+1)=1.0;
    (*__A)(3+1,7+1)=1.0;
    if (_system->_R2_P_BooleanPulse1_P_y) {
      tmp152 = 1.0;
    } else {
      tmp152 = _system->_R2_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(3+1,8+1)=(-tmp152);
    (*__A)(4+1,6+1)=-1.0;
    (*__A)(4+1,7+1)=1.0;
    if (_system->_R2_P_BooleanPulse1_P_y) {
      tmp153 = _system->_R2_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp153 = 1.0;
    }
    (*__A)(5+1,5+1)=(-tmp153);
    (*__A)(5+1,6+1)=1.0;
    (*__A)(6+1,4+1)=1.0;
    if (_system->_R2_P_BooleanPulse1_P_y) {
      tmp154 = 1.0;
    } else {
      tmp154 = _system->_R2_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(6+1,5+1)=tmp154;
    if (_system->_R2_P_BooleanPulse1_P_y) {
      tmp155 = 1.0;
    } else {
      tmp155 = _system->_R2_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(7+1,3+1)=(-tmp155);
    (*__A)(7+1,6+1)=1.0;
    (*__A)(8+1,2+1)=1.0;
    if (_system->_R2_P_BooleanPulse1_P_y) {
      tmp156 = _system->_R2_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp156 = 1.0;
    }
    (*__A)(8+1,3+1)=tmp156;
    if (_system->_R2_P_BooleanPulse1_P_y) {
      tmp157 = _system->_R2_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp157 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp157);
    (*__A)(9+1,7+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R2_P_BooleanPulse1_P_y) {
      tmp158 = 1.0;
    } else {
      tmp158 = _system->_R2_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp158;
    __b(1)=0.0;
    __b(2)=0.0;
    __b(3)=-0.0;
    __b(4)=-0.0;
    __b(5)=(-__z[8]);
    __b(6)=-0.0;
    __b(7)=-0.0;
    __b(8)=(-__z[2]);
    __b(9)=-0.0;
    __b(10)=-0.0;
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop252::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop252::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop252::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop252::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R2_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R2_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R2_P_n1_P_i;
       vars[3] =_system->_R2_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R2_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[5] =_system->_R2_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R2_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R2_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R2_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_R2_P_n2_P_i;
       vars[10] =_system->_R2_P_Capacitor1_P_i;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop252::getNominalReal(double* vars)
{
       vars[0] =_system->_R2_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R2_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R2_P_n1_P_i;
       vars[3] =_system->_R2_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R2_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[5] =_system->_R2_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R2_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R2_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R2_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_R2_P_n2_P_i;
       vars[10] =_system->_R2_P_Capacitor1_P_i;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop252::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R2_P_IdealCommutingSwitch2_P_n2_P_i=vars[0];
     _system->_R2_P_IdealCommutingSwitch2_P_s2=vars[1];
     _system->_R2_P_n1_P_i=vars[2];
     _system->_R2_P_IdealCommutingSwitch1_P_s1=vars[3];
     _system->_R2_P_IdealCommutingSwitch1_P_n2_P_i=vars[4];
     _system->_R2_P_IdealCommutingSwitch1_P_s2=vars[5];
     _system->_R2_P_Capacitor1_P_p_P_v=vars[6];
     _system->_R2_P_Capacitor1_P_n_P_v=vars[7];
     _system->_R2_P_IdealCommutingSwitch2_P_s1=vars[8];
     _system->_R2_P_n2_P_i=vars[9];
     _system->_R2_P_Capacitor1_P_i=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop252::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop252::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop252::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop252::isLinearTearing()
  {
       return false;
  }