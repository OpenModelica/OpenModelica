/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop174.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop174::CauerLowPassSCAlgloop174(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop174::~CauerLowPassSCAlgloop174()
{
}

bool CauerLowPassSCAlgloop174::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop174::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop174::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop174::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop174::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop174::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop174::initialize(T *__A)
  {
         double tmp365;
         double tmp366;
         double tmp367;
         double tmp368;
         double tmp369;
         double tmp370;
         double tmp371;
         double tmp372;
          (*__A)(0+1,2+1)=1.0;
          if (_system->_R9_P_BooleanPulse1_P_y) {
            tmp365 = 1.0;
          } else {
            tmp365 = _system->_R9_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(0+1,10+1)=(-tmp365);
          (*__A)(1+1,9+1)=1.0;
          if (_system->_R9_P_BooleanPulse1_P_y) {
            tmp366 = _system->_R9_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp366 = 1.0;
          }
          (*__A)(1+1,10+1)=tmp366;
          (*__A)(2+1,0+1)=-1.0;
          (*__A)(2+1,8+1)=1.0;
          (*__A)(2+1,9+1)=-1.0;
          (*__A)(3+1,3+1)=-1.0;
          (*__A)(3+1,7+1)=-1.0;
          (*__A)(3+1,8+1)=-1.0;
          if (_system->_R9_P_BooleanPulse1_P_y) {
            tmp367 = 1.0;
          } else {
            tmp367 = _system->_R9_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(4+1,6+1)=tmp367;
          (*__A)(4+1,7+1)=1.0;
          (*__A)(5+1,5+1)=1.0;
          if (_system->_R9_P_BooleanPulse1_P_y) {
            tmp368 = _system->_R9_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp368 = 1.0;
          }
          (*__A)(5+1,6+1)=(-tmp368);
          if (_system->_R9_P_BooleanPulse1_P_y) {
            tmp369 = 1.0;
          } else {
            tmp369 = _system->_R9_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(6+1,4+1)=(-tmp369);
          (*__A)(6+1,5+1)=1.0;
          (*__A)(7+1,3+1)=1.0;
          if (_system->_R9_P_BooleanPulse1_P_y) {
            tmp370 = _system->_R9_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp370 = 1.0;
          }
          (*__A)(7+1,4+1)=tmp370;
          (*__A)(8+1,2+1)=-1.0;
          (*__A)(8+1,5+1)=1.0;
          if (_system->_R9_P_BooleanPulse1_P_y) {
            tmp371 = _system->_R9_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp371 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp371);
          (*__A)(9+1,2+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R9_P_BooleanPulse1_P_y) {
            tmp372 = 1.0;
          } else {
            tmp372 = _system->_R9_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp372;
          __b(1)=-0.0;
          __b(2)=-0.0;
          __b(3)=0.0;
          __b(4)=0.0;
          __b(5)=-0.0;
          __b(6)=-0.0;
          __b(7)=-0.0;
          __b(8)=-0.0;
          __b(9)=(-__z[14]);
          __b(10)=__z[1];
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop174::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop174::evaluate()
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
void CauerLowPassSCAlgloop174::evaluate(T* __A)
{
    double tmp374;
    double tmp375;
    double tmp376;
    double tmp377;
    double tmp378;
    double tmp379;
    double tmp380;
    double tmp381;
    (*__A)(0+1,2+1)=1.0;
    if (_system->_R9_P_BooleanPulse1_P_y) {
      tmp374 = 1.0;
    } else {
      tmp374 = _system->_R9_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(0+1,10+1)=(-tmp374);
    (*__A)(1+1,9+1)=1.0;
    if (_system->_R9_P_BooleanPulse1_P_y) {
      tmp375 = _system->_R9_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp375 = 1.0;
    }
    (*__A)(1+1,10+1)=tmp375;
    (*__A)(2+1,0+1)=-1.0;
    (*__A)(2+1,8+1)=1.0;
    (*__A)(2+1,9+1)=-1.0;
    (*__A)(3+1,3+1)=-1.0;
    (*__A)(3+1,7+1)=-1.0;
    (*__A)(3+1,8+1)=-1.0;
    if (_system->_R9_P_BooleanPulse1_P_y) {
      tmp376 = 1.0;
    } else {
      tmp376 = _system->_R9_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(4+1,6+1)=tmp376;
    (*__A)(4+1,7+1)=1.0;
    (*__A)(5+1,5+1)=1.0;
    if (_system->_R9_P_BooleanPulse1_P_y) {
      tmp377 = _system->_R9_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp377 = 1.0;
    }
    (*__A)(5+1,6+1)=(-tmp377);
    if (_system->_R9_P_BooleanPulse1_P_y) {
      tmp378 = 1.0;
    } else {
      tmp378 = _system->_R9_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(6+1,4+1)=(-tmp378);
    (*__A)(6+1,5+1)=1.0;
    (*__A)(7+1,3+1)=1.0;
    if (_system->_R9_P_BooleanPulse1_P_y) {
      tmp379 = _system->_R9_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp379 = 1.0;
    }
    (*__A)(7+1,4+1)=tmp379;
    (*__A)(8+1,2+1)=-1.0;
    (*__A)(8+1,5+1)=1.0;
    if (_system->_R9_P_BooleanPulse1_P_y) {
      tmp380 = _system->_R9_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp380 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp380);
    (*__A)(9+1,2+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R9_P_BooleanPulse1_P_y) {
      tmp381 = 1.0;
    } else {
      tmp381 = _system->_R9_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp381;
    __b(1)=-0.0;
    __b(2)=-0.0;
    __b(3)=0.0;
    __b(4)=0.0;
    __b(5)=-0.0;
    __b(6)=-0.0;
    __b(7)=-0.0;
    __b(8)=-0.0;
    __b(9)=(-__z[14]);
    __b(10)=__z[1];
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop174::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop174::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop174::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop174::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R9_P_n1_P_i;
       vars[1] =_system->_R9_P_IdealCommutingSwitch1_P_s2;
       vars[2] =_system->_R9_P_Capacitor1_P_p_P_v;
       vars[3] =_system->_R9_P_n2_P_i;
       vars[4] =_system->_R9_P_IdealCommutingSwitch2_P_s1;
       vars[5] =_system->_R9_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R9_P_IdealCommutingSwitch2_P_s2;
       vars[7] =_system->_R9_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[8] =_system->_R9_P_Capacitor1_P_i;
       vars[9] =_system->_R9_P_IdealCommutingSwitch1_P_n1_P_i;
       vars[10] =_system->_R9_P_IdealCommutingSwitch1_P_s1;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop174::getNominalReal(double* vars)
{
       vars[0] =_system->_R9_P_n1_P_i;
       vars[1] =_system->_R9_P_IdealCommutingSwitch1_P_s2;
       vars[2] =_system->_R9_P_Capacitor1_P_p_P_v;
       vars[3] =_system->_R9_P_n2_P_i;
       vars[4] =_system->_R9_P_IdealCommutingSwitch2_P_s1;
       vars[5] =_system->_R9_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R9_P_IdealCommutingSwitch2_P_s2;
       vars[7] =_system->_R9_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[8] =_system->_R9_P_Capacitor1_P_i;
       vars[9] =_system->_R9_P_IdealCommutingSwitch1_P_n1_P_i;
       vars[10] =_system->_R9_P_IdealCommutingSwitch1_P_s1;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop174::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R9_P_n1_P_i=vars[0];
     _system->_R9_P_IdealCommutingSwitch1_P_s2=vars[1];
     _system->_R9_P_Capacitor1_P_p_P_v=vars[2];
     _system->_R9_P_n2_P_i=vars[3];
     _system->_R9_P_IdealCommutingSwitch2_P_s1=vars[4];
     _system->_R9_P_Capacitor1_P_n_P_v=vars[5];
     _system->_R9_P_IdealCommutingSwitch2_P_s2=vars[6];
     _system->_R9_P_IdealCommutingSwitch2_P_n2_P_i=vars[7];
     _system->_R9_P_Capacitor1_P_i=vars[8];
     _system->_R9_P_IdealCommutingSwitch1_P_n1_P_i=vars[9];
     _system->_R9_P_IdealCommutingSwitch1_P_s1=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop174::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop174::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop174::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop174::isLinearTearing()
  {
       return false;
  }