/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop159.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop159::CauerLowPassSCAlgloop159(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop159::~CauerLowPassSCAlgloop159()
{
}

bool CauerLowPassSCAlgloop159::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop159::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop159::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop159::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop159::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop159::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop159::initialize(T *__A)
  {
         double tmp330;
         double tmp331;
         double tmp332;
         double tmp333;
         double tmp334;
         double tmp335;
         double tmp336;
         double tmp337;
          (*__A)(0+1,2+1)=1.0;
          if (_system->_R2_P_BooleanPulse1_P_y) {
            tmp330 = 1.0;
          } else {
            tmp330 = _system->_R2_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(0+1,10+1)=(-tmp330);
          (*__A)(1+1,9+1)=1.0;
          if (_system->_R2_P_BooleanPulse1_P_y) {
            tmp331 = _system->_R2_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp331 = 1.0;
          }
          (*__A)(1+1,10+1)=tmp331;
          (*__A)(2+1,0+1)=-1.0;
          (*__A)(2+1,8+1)=1.0;
          (*__A)(2+1,9+1)=-1.0;
          (*__A)(3+1,3+1)=-1.0;
          (*__A)(3+1,7+1)=-1.0;
          (*__A)(3+1,8+1)=-1.0;
          if (_system->_R2_P_BooleanPulse1_P_y) {
            tmp332 = _system->_R2_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp332 = 1.0;
          }
          (*__A)(4+1,6+1)=tmp332;
          (*__A)(4+1,7+1)=1.0;
          (*__A)(5+1,5+1)=1.0;
          if (_system->_R2_P_BooleanPulse1_P_y) {
            tmp333 = 1.0;
          } else {
            tmp333 = _system->_R2_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(5+1,6+1)=(-tmp333);
          if (_system->_R2_P_BooleanPulse1_P_y) {
            tmp334 = _system->_R2_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp334 = 1.0;
          }
          (*__A)(6+1,4+1)=(-tmp334);
          (*__A)(6+1,5+1)=1.0;
          (*__A)(7+1,3+1)=1.0;
          if (_system->_R2_P_BooleanPulse1_P_y) {
            tmp335 = 1.0;
          } else {
            tmp335 = _system->_R2_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(7+1,4+1)=tmp335;
          (*__A)(8+1,2+1)=-1.0;
          (*__A)(8+1,5+1)=1.0;
          if (_system->_R2_P_BooleanPulse1_P_y) {
            tmp336 = _system->_R2_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp336 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp336);
          (*__A)(9+1,2+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R2_P_BooleanPulse1_P_y) {
            tmp337 = 1.0;
          } else {
            tmp337 = _system->_R2_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp337;
          __b(1)=(-__z[2]);
          __b(2)=-0.0;
          __b(3)=0.0;
          __b(4)=0.0;
          __b(5)=-0.0;
          __b(6)=-0.0;
          __b(7)=-0.0;
          __b(8)=-0.0;
          __b(9)=(-__z[8]);
          __b(10)=-0.0;
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop159::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop159::evaluate()
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
void CauerLowPassSCAlgloop159::evaluate(T* __A)
{
    double tmp339;
    double tmp340;
    double tmp341;
    double tmp342;
    double tmp343;
    double tmp344;
    double tmp345;
    double tmp346;
    (*__A)(0+1,2+1)=1.0;
    if (_system->_R2_P_BooleanPulse1_P_y) {
      tmp339 = 1.0;
    } else {
      tmp339 = _system->_R2_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(0+1,10+1)=(-tmp339);
    (*__A)(1+1,9+1)=1.0;
    if (_system->_R2_P_BooleanPulse1_P_y) {
      tmp340 = _system->_R2_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp340 = 1.0;
    }
    (*__A)(1+1,10+1)=tmp340;
    (*__A)(2+1,0+1)=-1.0;
    (*__A)(2+1,8+1)=1.0;
    (*__A)(2+1,9+1)=-1.0;
    (*__A)(3+1,3+1)=-1.0;
    (*__A)(3+1,7+1)=-1.0;
    (*__A)(3+1,8+1)=-1.0;
    if (_system->_R2_P_BooleanPulse1_P_y) {
      tmp341 = _system->_R2_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp341 = 1.0;
    }
    (*__A)(4+1,6+1)=tmp341;
    (*__A)(4+1,7+1)=1.0;
    (*__A)(5+1,5+1)=1.0;
    if (_system->_R2_P_BooleanPulse1_P_y) {
      tmp342 = 1.0;
    } else {
      tmp342 = _system->_R2_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(5+1,6+1)=(-tmp342);
    if (_system->_R2_P_BooleanPulse1_P_y) {
      tmp343 = _system->_R2_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp343 = 1.0;
    }
    (*__A)(6+1,4+1)=(-tmp343);
    (*__A)(6+1,5+1)=1.0;
    (*__A)(7+1,3+1)=1.0;
    if (_system->_R2_P_BooleanPulse1_P_y) {
      tmp344 = 1.0;
    } else {
      tmp344 = _system->_R2_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(7+1,4+1)=tmp344;
    (*__A)(8+1,2+1)=-1.0;
    (*__A)(8+1,5+1)=1.0;
    if (_system->_R2_P_BooleanPulse1_P_y) {
      tmp345 = _system->_R2_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp345 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp345);
    (*__A)(9+1,2+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R2_P_BooleanPulse1_P_y) {
      tmp346 = 1.0;
    } else {
      tmp346 = _system->_R2_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp346;
    __b(1)=(-__z[2]);
    __b(2)=-0.0;
    __b(3)=0.0;
    __b(4)=0.0;
    __b(5)=-0.0;
    __b(6)=-0.0;
    __b(7)=-0.0;
    __b(8)=-0.0;
    __b(9)=(-__z[8]);
    __b(10)=-0.0;
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop159::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop159::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop159::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop159::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R2_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[1] =_system->_R2_P_IdealCommutingSwitch1_P_s2;
       vars[2] =_system->_R2_P_Capacitor1_P_p_P_v;
       vars[3] =_system->_R2_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[4] =_system->_R2_P_IdealCommutingSwitch2_P_s2;
       vars[5] =_system->_R2_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R2_P_IdealCommutingSwitch2_P_s1;
       vars[7] =_system->_R2_P_n2_P_i;
       vars[8] =_system->_R2_P_Capacitor1_P_i;
       vars[9] =_system->_R2_P_n1_P_i;
       vars[10] =_system->_R2_P_IdealCommutingSwitch1_P_s1;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop159::getNominalReal(double* vars)
{
       vars[0] =_system->_R2_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[1] =_system->_R2_P_IdealCommutingSwitch1_P_s2;
       vars[2] =_system->_R2_P_Capacitor1_P_p_P_v;
       vars[3] =_system->_R2_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[4] =_system->_R2_P_IdealCommutingSwitch2_P_s2;
       vars[5] =_system->_R2_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R2_P_IdealCommutingSwitch2_P_s1;
       vars[7] =_system->_R2_P_n2_P_i;
       vars[8] =_system->_R2_P_Capacitor1_P_i;
       vars[9] =_system->_R2_P_n1_P_i;
       vars[10] =_system->_R2_P_IdealCommutingSwitch1_P_s1;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop159::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R2_P_IdealCommutingSwitch1_P_n2_P_i=vars[0];
     _system->_R2_P_IdealCommutingSwitch1_P_s2=vars[1];
     _system->_R2_P_Capacitor1_P_p_P_v=vars[2];
     _system->_R2_P_IdealCommutingSwitch2_P_n2_P_i=vars[3];
     _system->_R2_P_IdealCommutingSwitch2_P_s2=vars[4];
     _system->_R2_P_Capacitor1_P_n_P_v=vars[5];
     _system->_R2_P_IdealCommutingSwitch2_P_s1=vars[6];
     _system->_R2_P_n2_P_i=vars[7];
     _system->_R2_P_Capacitor1_P_i=vars[8];
     _system->_R2_P_n1_P_i=vars[9];
     _system->_R2_P_IdealCommutingSwitch1_P_s1=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop159::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop159::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop159::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop159::isLinearTearing()
  {
       return false;
  }