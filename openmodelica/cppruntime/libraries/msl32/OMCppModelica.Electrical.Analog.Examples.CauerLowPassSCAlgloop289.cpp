/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop289.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop289::CauerLowPassSCAlgloop289(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop289::~CauerLowPassSCAlgloop289()
{
}

bool CauerLowPassSCAlgloop289::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop289::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop289::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop289::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop289::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop289::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop289::initialize(T *__A)
  {
         double tmp227;
         double tmp228;
         double tmp229;
         double tmp230;
         double tmp231;
         double tmp232;
         double tmp233;
         double tmp234;
          (*__A)(0+1,6+1)=1.0;
          if (_system->_R1_P_BooleanPulse1_P_y) {
            tmp227 = 1.0;
          } else {
            tmp227 = _system->_R1_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(0+1,10+1)=(-tmp227);
          (*__A)(1+1,9+1)=1.0;
          if (_system->_R1_P_BooleanPulse1_P_y) {
            tmp228 = _system->_R1_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp228 = 1.0;
          }
          (*__A)(1+1,10+1)=tmp228;
          (*__A)(2+1,2+1)=1.0;
          (*__A)(2+1,8+1)=-1.0;
          (*__A)(2+1,9+1)=-1.0;
          if (_system->_R1_P_BooleanPulse1_P_y) {
            tmp229 = 1.0;
          } else {
            tmp229 = _system->_R1_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(3+1,7+1)=tmp229;
          (*__A)(3+1,8+1)=1.0;
          (*__A)(4+1,6+1)=1.0;
          if (_system->_R1_P_BooleanPulse1_P_y) {
            tmp230 = _system->_R1_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp230 = 1.0;
          }
          (*__A)(4+1,7+1)=(-tmp230);
          (*__A)(5+1,5+1)=1.0;
          (*__A)(5+1,6+1)=-1.0;
          if (_system->_R1_P_BooleanPulse1_P_y) {
            tmp231 = _system->_R1_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp231 = 1.0;
          }
          (*__A)(6+1,4+1)=(-tmp231);
          (*__A)(6+1,5+1)=1.0;
          (*__A)(7+1,3+1)=1.0;
          if (_system->_R1_P_BooleanPulse1_P_y) {
            tmp232 = 1.0;
          } else {
            tmp232 = _system->_R1_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(7+1,4+1)=tmp232;
          (*__A)(8+1,0+1)=-1.0;
          (*__A)(8+1,2+1)=-1.0;
          (*__A)(8+1,3+1)=-1.0;
          if (_system->_R1_P_BooleanPulse1_P_y) {
            tmp233 = 1.0;
          } else {
            tmp233 = _system->_R1_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(9+1,1+1)=(-tmp233);
          (*__A)(9+1,5+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R1_P_BooleanPulse1_P_y) {
            tmp234 = _system->_R1_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp234 = 1.0;
          }
          (*__A)(10+1,1+1)=tmp234;
          __b(1)=(-_system->_V_P_v);
          __b(2)=-0.0;
          __b(3)=0.0;
          __b(4)=-0.0;
          __b(5)=-0.0;
          __b(6)=(-__z[5]);
          __b(7)=-0.0;
          __b(8)=-0.0;
          __b(9)=0.0;
          __b(10)=-0.0;
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop289::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop289::evaluate()
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
void CauerLowPassSCAlgloop289::evaluate(T* __A)
{
    double tmp236;
    double tmp237;
    double tmp238;
    double tmp239;
    double tmp240;
    double tmp241;
    double tmp242;
    double tmp243;
    (*__A)(0+1,6+1)=1.0;
    if (_system->_R1_P_BooleanPulse1_P_y) {
      tmp236 = 1.0;
    } else {
      tmp236 = _system->_R1_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(0+1,10+1)=(-tmp236);
    (*__A)(1+1,9+1)=1.0;
    if (_system->_R1_P_BooleanPulse1_P_y) {
      tmp237 = _system->_R1_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp237 = 1.0;
    }
    (*__A)(1+1,10+1)=tmp237;
    (*__A)(2+1,2+1)=1.0;
    (*__A)(2+1,8+1)=-1.0;
    (*__A)(2+1,9+1)=-1.0;
    if (_system->_R1_P_BooleanPulse1_P_y) {
      tmp238 = 1.0;
    } else {
      tmp238 = _system->_R1_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(3+1,7+1)=tmp238;
    (*__A)(3+1,8+1)=1.0;
    (*__A)(4+1,6+1)=1.0;
    if (_system->_R1_P_BooleanPulse1_P_y) {
      tmp239 = _system->_R1_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp239 = 1.0;
    }
    (*__A)(4+1,7+1)=(-tmp239);
    (*__A)(5+1,5+1)=1.0;
    (*__A)(5+1,6+1)=-1.0;
    if (_system->_R1_P_BooleanPulse1_P_y) {
      tmp240 = _system->_R1_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp240 = 1.0;
    }
    (*__A)(6+1,4+1)=(-tmp240);
    (*__A)(6+1,5+1)=1.0;
    (*__A)(7+1,3+1)=1.0;
    if (_system->_R1_P_BooleanPulse1_P_y) {
      tmp241 = 1.0;
    } else {
      tmp241 = _system->_R1_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(7+1,4+1)=tmp241;
    (*__A)(8+1,0+1)=-1.0;
    (*__A)(8+1,2+1)=-1.0;
    (*__A)(8+1,3+1)=-1.0;
    if (_system->_R1_P_BooleanPulse1_P_y) {
      tmp242 = 1.0;
    } else {
      tmp242 = _system->_R1_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(9+1,1+1)=(-tmp242);
    (*__A)(9+1,5+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R1_P_BooleanPulse1_P_y) {
      tmp243 = _system->_R1_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp243 = 1.0;
    }
    (*__A)(10+1,1+1)=tmp243;
    __b(1)=(-_system->_V_P_v);
    __b(2)=-0.0;
    __b(3)=0.0;
    __b(4)=-0.0;
    __b(5)=-0.0;
    __b(6)=(-__z[5]);
    __b(7)=-0.0;
    __b(8)=-0.0;
    __b(9)=0.0;
    __b(10)=-0.0;
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop289::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop289::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop289::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop289::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R1_P_n2_P_i;
       vars[1] =_system->_R1_P_IdealCommutingSwitch2_P_s1;
       vars[2] =_system->_R1_P_Capacitor1_P_i;
       vars[3] =_system->_R1_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[4] =_system->_R1_P_IdealCommutingSwitch2_P_s2;
       vars[5] =_system->_R1_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R1_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R1_P_IdealCommutingSwitch1_P_s2;
       vars[8] =_system->_R1_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[9] =_system->_V_P_i;
       vars[10] =_system->_R1_P_IdealCommutingSwitch1_P_s1;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop289::getNominalReal(double* vars)
{
       vars[0] =_system->_R1_P_n2_P_i;
       vars[1] =_system->_R1_P_IdealCommutingSwitch2_P_s1;
       vars[2] =_system->_R1_P_Capacitor1_P_i;
       vars[3] =_system->_R1_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[4] =_system->_R1_P_IdealCommutingSwitch2_P_s2;
       vars[5] =_system->_R1_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R1_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R1_P_IdealCommutingSwitch1_P_s2;
       vars[8] =_system->_R1_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[9] =_system->_V_P_i;
       vars[10] =_system->_R1_P_IdealCommutingSwitch1_P_s1;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop289::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R1_P_n2_P_i=vars[0];
     _system->_R1_P_IdealCommutingSwitch2_P_s1=vars[1];
     _system->_R1_P_Capacitor1_P_i=vars[2];
     _system->_R1_P_IdealCommutingSwitch2_P_n2_P_i=vars[3];
     _system->_R1_P_IdealCommutingSwitch2_P_s2=vars[4];
     _system->_R1_P_Capacitor1_P_n_P_v=vars[5];
     _system->_R1_P_Capacitor1_P_p_P_v=vars[6];
     _system->_R1_P_IdealCommutingSwitch1_P_s2=vars[7];
     _system->_R1_P_IdealCommutingSwitch1_P_n2_P_i=vars[8];
     _system->_V_P_i=vars[9];
     _system->_R1_P_IdealCommutingSwitch1_P_s1=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop289::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop289::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop289::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop289::isLinearTearing()
  {
       return false;
  }