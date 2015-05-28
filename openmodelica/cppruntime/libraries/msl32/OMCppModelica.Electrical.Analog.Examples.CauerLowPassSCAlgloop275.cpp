/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop275.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop275::CauerLowPassSCAlgloop275(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop275::~CauerLowPassSCAlgloop275()
{
}

bool CauerLowPassSCAlgloop275::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop275::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop275::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop275::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop275::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop275::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop275::initialize(T *__A)
  {
         double tmp193;
         double tmp194;
         double tmp195;
         double tmp196;
         double tmp197;
         double tmp198;
         double tmp199;
         double tmp200;
          (*__A)(0+1,2+1)=-1.0;
          (*__A)(0+1,4+1)=-1.0;
          (*__A)(0+1,10+1)=1.0;
          (*__A)(1+1,0+1)=-1.0;
          (*__A)(1+1,9+1)=-1.0;
          (*__A)(1+1,10+1)=-1.0;
          if (_system->_R5_P_BooleanPulse1_P_y) {
            tmp193 = _system->_R5_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp193 = 1.0;
          }
          (*__A)(2+1,8+1)=tmp193;
          (*__A)(2+1,9+1)=1.0;
          (*__A)(3+1,7+1)=1.0;
          if (_system->_R5_P_BooleanPulse1_P_y) {
            tmp194 = 1.0;
          } else {
            tmp194 = _system->_R5_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(3+1,8+1)=(-tmp194);
          (*__A)(4+1,6+1)=-1.0;
          (*__A)(4+1,7+1)=1.0;
          if (_system->_R5_P_BooleanPulse1_P_y) {
            tmp195 = _system->_R5_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp195 = 1.0;
          }
          (*__A)(5+1,5+1)=(-tmp195);
          (*__A)(5+1,6+1)=1.0;
          (*__A)(6+1,4+1)=1.0;
          if (_system->_R5_P_BooleanPulse1_P_y) {
            tmp196 = 1.0;
          } else {
            tmp196 = _system->_R5_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(6+1,5+1)=tmp196;
          if (_system->_R5_P_BooleanPulse1_P_y) {
            tmp197 = 1.0;
          } else {
            tmp197 = _system->_R5_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(7+1,3+1)=(-tmp197);
          (*__A)(7+1,6+1)=1.0;
          (*__A)(8+1,2+1)=1.0;
          if (_system->_R5_P_BooleanPulse1_P_y) {
            tmp198 = _system->_R5_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp198 = 1.0;
          }
          (*__A)(8+1,3+1)=tmp198;
          if (_system->_R5_P_BooleanPulse1_P_y) {
            tmp199 = _system->_R5_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp199 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp199);
          (*__A)(9+1,7+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R5_P_BooleanPulse1_P_y) {
            tmp200 = 1.0;
          } else {
            tmp200 = _system->_R5_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp200;
          __b(1)=0.0;
          __b(2)=0.0;
          __b(3)=-0.0;
          __b(4)=-0.0;
          __b(5)=(-__z[11]);
          __b(6)=__z[1];
          __b(7)=-0.0;
          __b(8)=-0.0;
          __b(9)=-0.0;
          __b(10)=-0.0;
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop275::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop275::evaluate()
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
void CauerLowPassSCAlgloop275::evaluate(T* __A)
{
    double tmp202;
    double tmp203;
    double tmp204;
    double tmp205;
    double tmp206;
    double tmp207;
    double tmp208;
    double tmp209;
    (*__A)(0+1,2+1)=-1.0;
    (*__A)(0+1,4+1)=-1.0;
    (*__A)(0+1,10+1)=1.0;
    (*__A)(1+1,0+1)=-1.0;
    (*__A)(1+1,9+1)=-1.0;
    (*__A)(1+1,10+1)=-1.0;
    if (_system->_R5_P_BooleanPulse1_P_y) {
      tmp202 = _system->_R5_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp202 = 1.0;
    }
    (*__A)(2+1,8+1)=tmp202;
    (*__A)(2+1,9+1)=1.0;
    (*__A)(3+1,7+1)=1.0;
    if (_system->_R5_P_BooleanPulse1_P_y) {
      tmp203 = 1.0;
    } else {
      tmp203 = _system->_R5_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(3+1,8+1)=(-tmp203);
    (*__A)(4+1,6+1)=-1.0;
    (*__A)(4+1,7+1)=1.0;
    if (_system->_R5_P_BooleanPulse1_P_y) {
      tmp204 = _system->_R5_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp204 = 1.0;
    }
    (*__A)(5+1,5+1)=(-tmp204);
    (*__A)(5+1,6+1)=1.0;
    (*__A)(6+1,4+1)=1.0;
    if (_system->_R5_P_BooleanPulse1_P_y) {
      tmp205 = 1.0;
    } else {
      tmp205 = _system->_R5_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(6+1,5+1)=tmp205;
    if (_system->_R5_P_BooleanPulse1_P_y) {
      tmp206 = 1.0;
    } else {
      tmp206 = _system->_R5_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(7+1,3+1)=(-tmp206);
    (*__A)(7+1,6+1)=1.0;
    (*__A)(8+1,2+1)=1.0;
    if (_system->_R5_P_BooleanPulse1_P_y) {
      tmp207 = _system->_R5_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp207 = 1.0;
    }
    (*__A)(8+1,3+1)=tmp207;
    if (_system->_R5_P_BooleanPulse1_P_y) {
      tmp208 = _system->_R5_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp208 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp208);
    (*__A)(9+1,7+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R5_P_BooleanPulse1_P_y) {
      tmp209 = 1.0;
    } else {
      tmp209 = _system->_R5_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp209;
    __b(1)=0.0;
    __b(2)=0.0;
    __b(3)=-0.0;
    __b(4)=-0.0;
    __b(5)=(-__z[11]);
    __b(6)=__z[1];
    __b(7)=-0.0;
    __b(8)=-0.0;
    __b(9)=-0.0;
    __b(10)=-0.0;
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop275::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop275::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop275::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop275::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R5_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R5_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R5_P_IdealCommutingSwitch1_P_n1_P_i;
       vars[3] =_system->_R5_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R5_P_n1_P_i;
       vars[5] =_system->_R5_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R5_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R5_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R5_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_R5_P_n2_P_i;
       vars[10] =_system->_R5_P_Capacitor1_P_i;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop275::getNominalReal(double* vars)
{
       vars[0] =_system->_R5_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R5_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R5_P_IdealCommutingSwitch1_P_n1_P_i;
       vars[3] =_system->_R5_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R5_P_n1_P_i;
       vars[5] =_system->_R5_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R5_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R5_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R5_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_R5_P_n2_P_i;
       vars[10] =_system->_R5_P_Capacitor1_P_i;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop275::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R5_P_IdealCommutingSwitch2_P_n2_P_i=vars[0];
     _system->_R5_P_IdealCommutingSwitch2_P_s2=vars[1];
     _system->_R5_P_IdealCommutingSwitch1_P_n1_P_i=vars[2];
     _system->_R5_P_IdealCommutingSwitch1_P_s1=vars[3];
     _system->_R5_P_n1_P_i=vars[4];
     _system->_R5_P_IdealCommutingSwitch1_P_s2=vars[5];
     _system->_R5_P_Capacitor1_P_p_P_v=vars[6];
     _system->_R5_P_Capacitor1_P_n_P_v=vars[7];
     _system->_R5_P_IdealCommutingSwitch2_P_s1=vars[8];
     _system->_R5_P_n2_P_i=vars[9];
     _system->_R5_P_Capacitor1_P_i=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop275::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop275::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop275::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop275::isLinearTearing()
  {
       return false;
  }