/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop138.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop138::CauerLowPassSCAlgloop138(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop138::~CauerLowPassSCAlgloop138()
{
}

bool CauerLowPassSCAlgloop138::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop138::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop138::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop138::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop138::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop138::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop138::initialize(T *__A)
  {
         double tmp279;
         double tmp280;
         double tmp281;
         double tmp282;
         double tmp283;
         double tmp284;
         double tmp285;
         double tmp286;
          if (_system->_R7_P_BooleanPulse1_P_y) {
            tmp279 = 1.0;
          } else {
            tmp279 = _system->_R7_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(0+1,6+1)=(-tmp279);
          (*__A)(0+1,10+1)=1.0;
          if (_system->_R7_P_BooleanPulse1_P_y) {
            tmp280 = _system->_R7_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp280 = 1.0;
          }
          (*__A)(1+1,9+1)=(-tmp280);
          (*__A)(1+1,10+1)=1.0;
          (*__A)(2+1,8+1)=1.0;
          if (_system->_R7_P_BooleanPulse1_P_y) {
            tmp281 = 1.0;
          } else {
            tmp281 = _system->_R7_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(2+1,9+1)=tmp281;
          (*__A)(3+1,2+1)=1.0;
          (*__A)(3+1,7+1)=-1.0;
          (*__A)(3+1,8+1)=-1.0;
          if (_system->_R7_P_BooleanPulse1_P_y) {
            tmp282 = _system->_R7_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp282 = 1.0;
          }
          (*__A)(4+1,6+1)=tmp282;
          (*__A)(4+1,7+1)=1.0;
          (*__A)(5+1,5+1)=1.0;
          (*__A)(5+1,10+1)=-1.0;
          if (_system->_R7_P_BooleanPulse1_P_y) {
            tmp283 = 1.0;
          } else {
            tmp283 = _system->_R7_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(6+1,4+1)=(-tmp283);
          (*__A)(6+1,5+1)=1.0;
          (*__A)(7+1,3+1)=1.0;
          if (_system->_R7_P_BooleanPulse1_P_y) {
            tmp284 = _system->_R7_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp284 = 1.0;
          }
          (*__A)(7+1,4+1)=tmp284;
          (*__A)(8+1,0+1)=-1.0;
          (*__A)(8+1,2+1)=-1.0;
          (*__A)(8+1,3+1)=-1.0;
          if (_system->_R7_P_BooleanPulse1_P_y) {
            tmp285 = _system->_R7_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp285 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp285);
          (*__A)(9+1,5+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R7_P_BooleanPulse1_P_y) {
            tmp286 = 1.0;
          } else {
            tmp286 = _system->_R7_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp286;
          __b(1)=(-__z[2]);
          __b(2)=-0.0;
          __b(3)=-0.0;
          __b(4)=0.0;
          __b(5)=-0.0;
          __b(6)=(-__z[12]);
          __b(7)=-0.0;
          __b(8)=-0.0;
          __b(9)=0.0;
          __b(10)=-0.0;
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop138::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop138::evaluate()
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
void CauerLowPassSCAlgloop138::evaluate(T* __A)
{
    double tmp288;
    double tmp289;
    double tmp290;
    double tmp291;
    double tmp292;
    double tmp293;
    double tmp294;
    double tmp295;
    if (_system->_R7_P_BooleanPulse1_P_y) {
      tmp288 = 1.0;
    } else {
      tmp288 = _system->_R7_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(0+1,6+1)=(-tmp288);
    (*__A)(0+1,10+1)=1.0;
    if (_system->_R7_P_BooleanPulse1_P_y) {
      tmp289 = _system->_R7_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp289 = 1.0;
    }
    (*__A)(1+1,9+1)=(-tmp289);
    (*__A)(1+1,10+1)=1.0;
    (*__A)(2+1,8+1)=1.0;
    if (_system->_R7_P_BooleanPulse1_P_y) {
      tmp290 = 1.0;
    } else {
      tmp290 = _system->_R7_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(2+1,9+1)=tmp290;
    (*__A)(3+1,2+1)=1.0;
    (*__A)(3+1,7+1)=-1.0;
    (*__A)(3+1,8+1)=-1.0;
    if (_system->_R7_P_BooleanPulse1_P_y) {
      tmp291 = _system->_R7_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp291 = 1.0;
    }
    (*__A)(4+1,6+1)=tmp291;
    (*__A)(4+1,7+1)=1.0;
    (*__A)(5+1,5+1)=1.0;
    (*__A)(5+1,10+1)=-1.0;
    if (_system->_R7_P_BooleanPulse1_P_y) {
      tmp292 = 1.0;
    } else {
      tmp292 = _system->_R7_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(6+1,4+1)=(-tmp292);
    (*__A)(6+1,5+1)=1.0;
    (*__A)(7+1,3+1)=1.0;
    if (_system->_R7_P_BooleanPulse1_P_y) {
      tmp293 = _system->_R7_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp293 = 1.0;
    }
    (*__A)(7+1,4+1)=tmp293;
    (*__A)(8+1,0+1)=-1.0;
    (*__A)(8+1,2+1)=-1.0;
    (*__A)(8+1,3+1)=-1.0;
    if (_system->_R7_P_BooleanPulse1_P_y) {
      tmp294 = _system->_R7_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp294 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp294);
    (*__A)(9+1,5+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R7_P_BooleanPulse1_P_y) {
      tmp295 = 1.0;
    } else {
      tmp295 = _system->_R7_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp295;
    __b(1)=(-__z[2]);
    __b(2)=-0.0;
    __b(3)=-0.0;
    __b(4)=0.0;
    __b(5)=-0.0;
    __b(6)=(-__z[12]);
    __b(7)=-0.0;
    __b(8)=-0.0;
    __b(9)=0.0;
    __b(10)=-0.0;
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop138::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop138::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop138::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop138::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R7_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R7_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R7_P_Capacitor1_P_i;
       vars[3] =_system->_R7_P_n2_P_i;
       vars[4] =_system->_R7_P_IdealCommutingSwitch2_P_s1;
       vars[5] =_system->_R7_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R7_P_IdealCommutingSwitch1_P_s1;
       vars[7] =_system->_R7_P_n1_P_i;
       vars[8] =_system->_R7_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[9] =_system->_R7_P_IdealCommutingSwitch1_P_s2;
       vars[10] =_system->_R7_P_Capacitor1_P_p_P_v;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop138::getNominalReal(double* vars)
{
       vars[0] =_system->_R7_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R7_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R7_P_Capacitor1_P_i;
       vars[3] =_system->_R7_P_n2_P_i;
       vars[4] =_system->_R7_P_IdealCommutingSwitch2_P_s1;
       vars[5] =_system->_R7_P_Capacitor1_P_n_P_v;
       vars[6] =_system->_R7_P_IdealCommutingSwitch1_P_s1;
       vars[7] =_system->_R7_P_n1_P_i;
       vars[8] =_system->_R7_P_IdealCommutingSwitch1_P_n2_P_i;
       vars[9] =_system->_R7_P_IdealCommutingSwitch1_P_s2;
       vars[10] =_system->_R7_P_Capacitor1_P_p_P_v;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop138::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R7_P_IdealCommutingSwitch2_P_n2_P_i=vars[0];
     _system->_R7_P_IdealCommutingSwitch2_P_s2=vars[1];
     _system->_R7_P_Capacitor1_P_i=vars[2];
     _system->_R7_P_n2_P_i=vars[3];
     _system->_R7_P_IdealCommutingSwitch2_P_s1=vars[4];
     _system->_R7_P_Capacitor1_P_n_P_v=vars[5];
     _system->_R7_P_IdealCommutingSwitch1_P_s1=vars[6];
     _system->_R7_P_n1_P_i=vars[7];
     _system->_R7_P_IdealCommutingSwitch1_P_n2_P_i=vars[8];
     _system->_R7_P_IdealCommutingSwitch1_P_s2=vars[9];
     _system->_R7_P_Capacitor1_P_p_P_v=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop138::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop138::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop138::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop138::isLinearTearing()
  {
       return false;
  }