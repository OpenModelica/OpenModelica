/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop152.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop152::CauerLowPassSCAlgloop152(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop152::~CauerLowPassSCAlgloop152()
{
}

bool CauerLowPassSCAlgloop152::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop152::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop152::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop152::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop152::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop152::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop152::initialize(T *__A)
  {
         double tmp313;
         double tmp314;
         double tmp315;
         double tmp316;
         double tmp317;
         double tmp318;
         double tmp319;
         double tmp320;
          (*__A)(0+1,2+1)=1.0;
          if (_system->_R3_P_BooleanPulse1_P_y) {
            tmp313 = 1.0;
          } else {
            tmp313 = _system->_R3_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(0+1,10+1)=(-tmp313);
          (*__A)(1+1,9+1)=1.0;
          if (_system->_R3_P_BooleanPulse1_P_y) {
            tmp314 = _system->_R3_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp314 = 1.0;
          }
          (*__A)(1+1,10+1)=tmp314;
          (*__A)(2+1,0+1)=-1.0;
          (*__A)(2+1,8+1)=1.0;
          (*__A)(2+1,9+1)=-1.0;
          (*__A)(3+1,3+1)=-1.0;
          (*__A)(3+1,7+1)=-1.0;
          (*__A)(3+1,8+1)=-1.0;
          if (_system->_R3_P_BooleanPulse1_P_y) {
            tmp315 = 1.0;
          } else {
            tmp315 = _system->_R3_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(4+1,6+1)=tmp315;
          (*__A)(4+1,7+1)=1.0;
          (*__A)(5+1,5+1)=1.0;
          if (_system->_R3_P_BooleanPulse1_P_y) {
            tmp316 = _system->_R3_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp316 = 1.0;
          }
          (*__A)(5+1,6+1)=(-tmp316);
          if (_system->_R3_P_BooleanPulse1_P_y) {
            tmp317 = 1.0;
          } else {
            tmp317 = _system->_R3_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(6+1,4+1)=(-tmp317);
          (*__A)(6+1,5+1)=1.0;
          (*__A)(7+1,3+1)=1.0;
          if (_system->_R3_P_BooleanPulse1_P_y) {
            tmp318 = _system->_R3_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp318 = 1.0;
          }
          (*__A)(7+1,4+1)=tmp318;
          (*__A)(8+1,2+1)=-1.0;
          (*__A)(8+1,5+1)=1.0;
          if (_system->_R3_P_BooleanPulse1_P_y) {
            tmp319 = _system->_R3_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp319 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp319);
          (*__A)(9+1,2+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R3_P_BooleanPulse1_P_y) {
            tmp320 = 1.0;
          } else {
            tmp320 = _system->_R3_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp320;
          __b(1)=-0.0;
          __b(2)=-0.0;
          __b(3)=0.0;
          __b(4)=0.0;
          __b(5)=-0.0;
          __b(6)=-0.0;
          __b(7)=(-__z[0]);
          __b(8)=-0.0;
          __b(9)=(-__z[9]);
          __b(10)=-0.0;
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop152::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop152::evaluate()
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
void CauerLowPassSCAlgloop152::evaluate(T* __A)
{
    double tmp322;
    double tmp323;
    double tmp324;
    double tmp325;
    double tmp326;
    double tmp327;
    double tmp328;
    double tmp329;
    (*__A)(0+1,2+1)=1.0;
    if (_system->_R3_P_BooleanPulse1_P_y) {
      tmp322 = 1.0;
    } else {
      tmp322 = _system->_R3_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(0+1,10+1)=(-tmp322);
    (*__A)(1+1,9+1)=1.0;
    if (_system->_R3_P_BooleanPulse1_P_y) {
      tmp323 = _system->_R3_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp323 = 1.0;
    }
    (*__A)(1+1,10+1)=tmp323;
    (*__A)(2+1,0+1)=-1.0;
    (*__A)(2+1,8+1)=1.0;
    (*__A)(2+1,9+1)=-1.0;
    (*__A)(3+1,3+1)=-1.0;
    (*__A)(3+1,7+1)=-1.0;
    (*__A)(3+1,8+1)=-1.0;
    if (_system->_R3_P_BooleanPulse1_P_y) {
      tmp324 = 1.0;
    } else {
      tmp324 = _system->_R3_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(4+1,6+1)=tmp324;
    (*__A)(4+1,7+1)=1.0;
    (*__A)(5+1,5+1)=1.0;
    if (_system->_R3_P_BooleanPulse1_P_y) {
      tmp325 = _system->_R3_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp325 = 1.0;
    }
    (*__A)(5+1,6+1)=(-tmp325);
    if (_system->_R3_P_BooleanPulse1_P_y) {
      tmp326 = 1.0;
    } else {
      tmp326 = _system->_R3_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(6+1,4+1)=(-tmp326);
    (*__A)(6+1,5+1)=1.0;
    (*__A)(7+1,3+1)=1.0;
    if (_system->_R3_P_BooleanPulse1_P_y) {
      tmp327 = _system->_R3_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp327 = 1.0;
    }
    (*__A)(7+1,4+1)=tmp327;
    (*__A)(8+1,2+1)=-1.0;
    (*__A)(8+1,5+1)=1.0;
    if (_system->_R3_P_BooleanPulse1_P_y) {
      tmp328 = _system->_R3_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp328 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp328);
    (*__A)(9+1,2+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R3_P_BooleanPulse1_P_y) {
      tmp329 = 1.0;
    } else {
      tmp329 = _system->_R3_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp329;
    __b(1)=-0.0;
    __b(2)=-0.0;
    __b(3)=0.0;
    __b(4)=0.0;
    __b(5)=-0.0;
    __b(6)=-0.0;
    __b(7)=(-__z[0]);
    __b(8)=-0.0;
    __b(9)=(-__z[9]);
    __b(10)=-0.0;
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop152::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop152::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop152::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop152::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R3_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[1] =_system->_R3_P_IdealCommutingSwitch1_P_s2;
       vars[2] =_system->_R3_P_Capacitor1_P_p_P_v;
       vars[3] =_system->_R3_P_n2_P_i;
       vars[4] =_system->_R3_P_IdealCommutingSwitch2_P_s1;
       vars[5] =_system->_R3_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R3_P_IdealCommutingSwitch2_P_s2;
       vars[7] =_system->_R3_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[8] =_system->_R3_P_Capacitor1_P_i;
       vars[9] =_system->_R3_P_n1_P_i;
       vars[10] =_system->_R3_P_IdealCommutingSwitch1_P_s1;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop152::getNominalReal(double* vars)
{
       vars[0] =_system->_R3_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[1] =_system->_R3_P_IdealCommutingSwitch1_P_s2;
       vars[2] =_system->_R3_P_Capacitor1_P_p_P_v;
       vars[3] =_system->_R3_P_n2_P_i;
       vars[4] =_system->_R3_P_IdealCommutingSwitch2_P_s1;
       vars[5] =_system->_R3_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R3_P_IdealCommutingSwitch2_P_s2;
       vars[7] =_system->_R3_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[8] =_system->_R3_P_Capacitor1_P_i;
       vars[9] =_system->_R3_P_n1_P_i;
       vars[10] =_system->_R3_P_IdealCommutingSwitch1_P_s1;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop152::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R3_P_IdealCommutingSwitch1_P_n2_P_i=vars[0];
     _system->_R3_P_IdealCommutingSwitch1_P_s2=vars[1];
     _system->_R3_P_Capacitor1_P_p_P_v=vars[2];
     _system->_R3_P_n2_P_i=vars[3];
     _system->_R3_P_IdealCommutingSwitch2_P_s1=vars[4];
     _system->_R3_P_Capacitor1_P_n_P_v=vars[5];
     _system->_R3_P_IdealCommutingSwitch2_P_s2=vars[6];
     _system->_R3_P_IdealCommutingSwitch2_P_n2_P_i=vars[7];
     _system->_R3_P_Capacitor1_P_i=vars[8];
     _system->_R3_P_n1_P_i=vars[9];
     _system->_R3_P_IdealCommutingSwitch1_P_s1=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop152::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop152::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop152::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop152::isLinearTearing()
  {
       return false;
  }