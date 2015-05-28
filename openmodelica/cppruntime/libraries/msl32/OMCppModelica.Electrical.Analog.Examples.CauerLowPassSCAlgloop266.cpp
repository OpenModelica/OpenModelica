/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop266.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop266::CauerLowPassSCAlgloop266(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop266::~CauerLowPassSCAlgloop266()
{
}

bool CauerLowPassSCAlgloop266::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop266::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop266::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop266::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop266::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop266::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop266::initialize(T *__A)
  {
         double tmp176;
         double tmp177;
         double tmp178;
         double tmp179;
         double tmp180;
         double tmp181;
         double tmp182;
         double tmp183;
          (*__A)(0+1,2+1)=-1.0;
          (*__A)(0+1,4+1)=-1.0;
          (*__A)(0+1,10+1)=1.0;
          (*__A)(1+1,0+1)=-1.0;
          (*__A)(1+1,9+1)=-1.0;
          (*__A)(1+1,10+1)=-1.0;
          if (_system->_R8_P_BooleanPulse1_P_y) {
            tmp176 = _system->_R8_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp176 = 1.0;
          }
          (*__A)(2+1,8+1)=tmp176;
          (*__A)(2+1,9+1)=1.0;
          (*__A)(3+1,7+1)=1.0;
          if (_system->_R8_P_BooleanPulse1_P_y) {
            tmp177 = 1.0;
          } else {
            tmp177 = _system->_R8_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(3+1,8+1)=(-tmp177);
          (*__A)(4+1,6+1)=-1.0;
          (*__A)(4+1,7+1)=1.0;
          if (_system->_R8_P_BooleanPulse1_P_y) {
            tmp178 = _system->_R8_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp178 = 1.0;
          }
          (*__A)(5+1,5+1)=(-tmp178);
          (*__A)(5+1,6+1)=1.0;
          (*__A)(6+1,4+1)=1.0;
          if (_system->_R8_P_BooleanPulse1_P_y) {
            tmp179 = 1.0;
          } else {
            tmp179 = _system->_R8_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(6+1,5+1)=tmp179;
          if (_system->_R8_P_BooleanPulse1_P_y) {
            tmp180 = 1.0;
          } else {
            tmp180 = _system->_R8_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(7+1,3+1)=(-tmp180);
          (*__A)(7+1,6+1)=1.0;
          (*__A)(8+1,2+1)=1.0;
          if (_system->_R8_P_BooleanPulse1_P_y) {
            tmp181 = _system->_R8_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp181 = 1.0;
          }
          (*__A)(8+1,3+1)=tmp181;
          if (_system->_R8_P_BooleanPulse1_P_y) {
            tmp182 = _system->_R8_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp182 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp182);
          (*__A)(9+1,7+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R8_P_BooleanPulse1_P_y) {
            tmp183 = 1.0;
          } else {
            tmp183 = _system->_R8_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp183;
          __b(1)=0.0;
          __b(2)=0.0;
          __b(3)=-0.0;
          __b(4)=-0.0;
          __b(5)=(-__z[13]);
          __b(6)=__z[3];
          __b(7)=-0.0;
          __b(8)=-0.0;
          __b(9)=-0.0;
          __b(10)=-0.0;
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop266::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop266::evaluate()
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
void CauerLowPassSCAlgloop266::evaluate(T* __A)
{
    double tmp185;
    double tmp186;
    double tmp187;
    double tmp188;
    double tmp189;
    double tmp190;
    double tmp191;
    double tmp192;
    (*__A)(0+1,2+1)=-1.0;
    (*__A)(0+1,4+1)=-1.0;
    (*__A)(0+1,10+1)=1.0;
    (*__A)(1+1,0+1)=-1.0;
    (*__A)(1+1,9+1)=-1.0;
    (*__A)(1+1,10+1)=-1.0;
    if (_system->_R8_P_BooleanPulse1_P_y) {
      tmp185 = _system->_R8_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp185 = 1.0;
    }
    (*__A)(2+1,8+1)=tmp185;
    (*__A)(2+1,9+1)=1.0;
    (*__A)(3+1,7+1)=1.0;
    if (_system->_R8_P_BooleanPulse1_P_y) {
      tmp186 = 1.0;
    } else {
      tmp186 = _system->_R8_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(3+1,8+1)=(-tmp186);
    (*__A)(4+1,6+1)=-1.0;
    (*__A)(4+1,7+1)=1.0;
    if (_system->_R8_P_BooleanPulse1_P_y) {
      tmp187 = _system->_R8_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp187 = 1.0;
    }
    (*__A)(5+1,5+1)=(-tmp187);
    (*__A)(5+1,6+1)=1.0;
    (*__A)(6+1,4+1)=1.0;
    if (_system->_R8_P_BooleanPulse1_P_y) {
      tmp188 = 1.0;
    } else {
      tmp188 = _system->_R8_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(6+1,5+1)=tmp188;
    if (_system->_R8_P_BooleanPulse1_P_y) {
      tmp189 = 1.0;
    } else {
      tmp189 = _system->_R8_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(7+1,3+1)=(-tmp189);
    (*__A)(7+1,6+1)=1.0;
    (*__A)(8+1,2+1)=1.0;
    if (_system->_R8_P_BooleanPulse1_P_y) {
      tmp190 = _system->_R8_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp190 = 1.0;
    }
    (*__A)(8+1,3+1)=tmp190;
    if (_system->_R8_P_BooleanPulse1_P_y) {
      tmp191 = _system->_R8_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp191 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp191);
    (*__A)(9+1,7+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R8_P_BooleanPulse1_P_y) {
      tmp192 = 1.0;
    } else {
      tmp192 = _system->_R8_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp192;
    __b(1)=0.0;
    __b(2)=0.0;
    __b(3)=-0.0;
    __b(4)=-0.0;
    __b(5)=(-__z[13]);
    __b(6)=__z[3];
    __b(7)=-0.0;
    __b(8)=-0.0;
    __b(9)=-0.0;
    __b(10)=-0.0;
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop266::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop266::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop266::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop266::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R8_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R8_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R8_P_IdealCommutingSwitch1_P_n1_P_i;
       vars[3] =_system->_R8_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R8_P_n1_P_i;
       vars[5] =_system->_R8_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R8_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R8_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R8_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_R8_P_n2_P_i;
       vars[10] =_system->_R8_P_Capacitor1_P_i;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop266::getNominalReal(double* vars)
{
       vars[0] =_system->_R8_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R8_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R8_P_IdealCommutingSwitch1_P_n1_P_i;
       vars[3] =_system->_R8_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R8_P_n1_P_i;
       vars[5] =_system->_R8_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R8_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R8_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R8_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_R8_P_n2_P_i;
       vars[10] =_system->_R8_P_Capacitor1_P_i;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop266::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R8_P_IdealCommutingSwitch2_P_n2_P_i=vars[0];
     _system->_R8_P_IdealCommutingSwitch2_P_s2=vars[1];
     _system->_R8_P_IdealCommutingSwitch1_P_n1_P_i=vars[2];
     _system->_R8_P_IdealCommutingSwitch1_P_s1=vars[3];
     _system->_R8_P_n1_P_i=vars[4];
     _system->_R8_P_IdealCommutingSwitch1_P_s2=vars[5];
     _system->_R8_P_Capacitor1_P_p_P_v=vars[6];
     _system->_R8_P_Capacitor1_P_n_P_v=vars[7];
     _system->_R8_P_IdealCommutingSwitch2_P_s1=vars[8];
     _system->_R8_P_n2_P_i=vars[9];
     _system->_R8_P_Capacitor1_P_i=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop266::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop266::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop266::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop266::isLinearTearing()
  {
       return false;
  }