/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop166.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop166::CauerLowPassSCAlgloop166(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop166::~CauerLowPassSCAlgloop166()
{
}

bool CauerLowPassSCAlgloop166::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop166::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop166::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop166::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop166::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop166::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop166::initialize(T *__A)
  {
         double tmp347;
         double tmp348;
         double tmp349;
         double tmp350;
         double tmp351;
         double tmp352;
         double tmp353;
         double tmp354;
          (*__A)(0+1,6+1)=1.0;
          if (_system->_R1_P_BooleanPulse1_P_y) {
            tmp347 = 1.0;
          } else {
            tmp347 = _system->_R1_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(0+1,10+1)=(-tmp347);
          (*__A)(1+1,9+1)=1.0;
          if (_system->_R1_P_BooleanPulse1_P_y) {
            tmp348 = _system->_R1_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp348 = 1.0;
          }
          (*__A)(1+1,10+1)=tmp348;
          (*__A)(2+1,2+1)=1.0;
          (*__A)(2+1,8+1)=-1.0;
          (*__A)(2+1,9+1)=-1.0;
          if (_system->_R1_P_BooleanPulse1_P_y) {
            tmp349 = 1.0;
          } else {
            tmp349 = _system->_R1_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(3+1,7+1)=tmp349;
          (*__A)(3+1,8+1)=1.0;
          (*__A)(4+1,6+1)=1.0;
          if (_system->_R1_P_BooleanPulse1_P_y) {
            tmp350 = _system->_R1_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp350 = 1.0;
          }
          (*__A)(4+1,7+1)=(-tmp350);
          (*__A)(5+1,5+1)=1.0;
          (*__A)(5+1,6+1)=-1.0;
          if (_system->_R1_P_BooleanPulse1_P_y) {
            tmp351 = 1.0;
          } else {
            tmp351 = _system->_R1_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(6+1,4+1)=(-tmp351);
          (*__A)(6+1,5+1)=1.0;
          (*__A)(7+1,3+1)=1.0;
          if (_system->_R1_P_BooleanPulse1_P_y) {
            tmp352 = _system->_R1_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp352 = 1.0;
          }
          (*__A)(7+1,4+1)=tmp352;
          (*__A)(8+1,0+1)=-1.0;
          (*__A)(8+1,2+1)=-1.0;
          (*__A)(8+1,3+1)=-1.0;
          if (_system->_R1_P_BooleanPulse1_P_y) {
            tmp353 = _system->_R1_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp353 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp353);
          (*__A)(9+1,5+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R1_P_BooleanPulse1_P_y) {
            tmp354 = 1.0;
          } else {
            tmp354 = _system->_R1_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp354;
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
float CauerLowPassSCAlgloop166::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop166::evaluate()
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
void CauerLowPassSCAlgloop166::evaluate(T* __A)
{
    double tmp356;
    double tmp357;
    double tmp358;
    double tmp359;
    double tmp360;
    double tmp361;
    double tmp362;
    double tmp363;
    (*__A)(0+1,6+1)=1.0;
    if (_system->_R1_P_BooleanPulse1_P_y) {
      tmp356 = 1.0;
    } else {
      tmp356 = _system->_R1_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(0+1,10+1)=(-tmp356);
    (*__A)(1+1,9+1)=1.0;
    if (_system->_R1_P_BooleanPulse1_P_y) {
      tmp357 = _system->_R1_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp357 = 1.0;
    }
    (*__A)(1+1,10+1)=tmp357;
    (*__A)(2+1,2+1)=1.0;
    (*__A)(2+1,8+1)=-1.0;
    (*__A)(2+1,9+1)=-1.0;
    if (_system->_R1_P_BooleanPulse1_P_y) {
      tmp358 = 1.0;
    } else {
      tmp358 = _system->_R1_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(3+1,7+1)=tmp358;
    (*__A)(3+1,8+1)=1.0;
    (*__A)(4+1,6+1)=1.0;
    if (_system->_R1_P_BooleanPulse1_P_y) {
      tmp359 = _system->_R1_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp359 = 1.0;
    }
    (*__A)(4+1,7+1)=(-tmp359);
    (*__A)(5+1,5+1)=1.0;
    (*__A)(5+1,6+1)=-1.0;
    if (_system->_R1_P_BooleanPulse1_P_y) {
      tmp360 = 1.0;
    } else {
      tmp360 = _system->_R1_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(6+1,4+1)=(-tmp360);
    (*__A)(6+1,5+1)=1.0;
    (*__A)(7+1,3+1)=1.0;
    if (_system->_R1_P_BooleanPulse1_P_y) {
      tmp361 = _system->_R1_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp361 = 1.0;
    }
    (*__A)(7+1,4+1)=tmp361;
    (*__A)(8+1,0+1)=-1.0;
    (*__A)(8+1,2+1)=-1.0;
    (*__A)(8+1,3+1)=-1.0;
    if (_system->_R1_P_BooleanPulse1_P_y) {
      tmp362 = _system->_R1_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp362 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp362);
    (*__A)(9+1,5+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R1_P_BooleanPulse1_P_y) {
      tmp363 = 1.0;
    } else {
      tmp363 = _system->_R1_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp363;
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
int  CauerLowPassSCAlgloop166::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop166::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop166::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop166::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R1_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R1_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R1_P_Capacitor1_P_i;
       vars[3] =_system->_R1_P_n2_P_i;
       vars[4] =_system->_R1_P_IdealCommutingSwitch2_P_s1;
       vars[5] =_system->_R1_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R1_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R1_P_IdealCommutingSwitch1_P_s2;
       vars[8] =_system->_R1_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[9] =_system->_V_P_i;
       vars[10] =_system->_R1_P_IdealCommutingSwitch1_P_s1;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop166::getNominalReal(double* vars)
{
       vars[0] =_system->_R1_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R1_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R1_P_Capacitor1_P_i;
       vars[3] =_system->_R1_P_n2_P_i;
       vars[4] =_system->_R1_P_IdealCommutingSwitch2_P_s1;
       vars[5] =_system->_R1_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R1_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R1_P_IdealCommutingSwitch1_P_s2;
       vars[8] =_system->_R1_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[9] =_system->_V_P_i;
       vars[10] =_system->_R1_P_IdealCommutingSwitch1_P_s1;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop166::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R1_P_IdealCommutingSwitch2_P_n2_P_i=vars[0];
     _system->_R1_P_IdealCommutingSwitch2_P_s2=vars[1];
     _system->_R1_P_Capacitor1_P_i=vars[2];
     _system->_R1_P_n2_P_i=vars[3];
     _system->_R1_P_IdealCommutingSwitch2_P_s1=vars[4];
     _system->_R1_P_Capacitor1_P_n_P_v=vars[5];
     _system->_R1_P_Capacitor1_P_p_P_v=vars[6];
     _system->_R1_P_IdealCommutingSwitch1_P_s2=vars[7];
     _system->_R1_P_IdealCommutingSwitch1_P_n2_P_i=vars[8];
     _system->_V_P_i=vars[9];
     _system->_R1_P_IdealCommutingSwitch1_P_s1=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop166::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop166::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop166::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop166::isLinearTearing()
  {
       return false;
  }