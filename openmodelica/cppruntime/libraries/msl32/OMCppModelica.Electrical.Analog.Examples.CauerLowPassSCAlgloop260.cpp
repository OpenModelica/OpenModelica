/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop260.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop260::CauerLowPassSCAlgloop260(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
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

CauerLowPassSCAlgloop260::~CauerLowPassSCAlgloop260()
{
}

bool CauerLowPassSCAlgloop260::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop260::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop260::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop260::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop260::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop260::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop260::initialize(T *__A)
  {
         double tmp159;
         double tmp160;
         double tmp161;
         double tmp162;
         double tmp163;
         double tmp164;
         double tmp165;
         double tmp166;
          (*__A)(0+1,2+1)=-1.0;
          (*__A)(0+1,4+1)=-1.0;
          (*__A)(0+1,10+1)=1.0;
          (*__A)(1+1,0+1)=-1.0;
          (*__A)(1+1,9+1)=-1.0;
          (*__A)(1+1,10+1)=-1.0;
          if (_system->_R9_P_BooleanPulse1_P_y) {
            tmp159 = _system->_R9_P_IdealCommutingSwitch2_P_Goff;
          } else {
            tmp159 = 1.0;
          }
          (*__A)(2+1,8+1)=tmp159;
          (*__A)(2+1,9+1)=1.0;
          (*__A)(3+1,7+1)=1.0;
          if (_system->_R9_P_BooleanPulse1_P_y) {
            tmp160 = 1.0;
          } else {
            tmp160 = _system->_R9_P_IdealCommutingSwitch2_P_Ron;
          }
          (*__A)(3+1,8+1)=(-tmp160);
          (*__A)(4+1,6+1)=-1.0;
          (*__A)(4+1,7+1)=1.0;
          if (_system->_R9_P_BooleanPulse1_P_y) {
            tmp161 = _system->_R9_P_IdealCommutingSwitch1_P_Ron;
          } else {
            tmp161 = 1.0;
          }
          (*__A)(5+1,5+1)=(-tmp161);
          (*__A)(5+1,6+1)=1.0;
          (*__A)(6+1,4+1)=1.0;
          if (_system->_R9_P_BooleanPulse1_P_y) {
            tmp162 = 1.0;
          } else {
            tmp162 = _system->_R9_P_IdealCommutingSwitch1_P_Goff;
          }
          (*__A)(6+1,5+1)=tmp162;
          if (_system->_R9_P_BooleanPulse1_P_y) {
            tmp163 = 1.0;
          } else {
            tmp163 = _system->_R9_P_IdealCommutingSwitch1_P_Ron;
          }
          (*__A)(7+1,3+1)=(-tmp163);
          (*__A)(7+1,6+1)=1.0;
          (*__A)(8+1,2+1)=1.0;
          if (_system->_R9_P_BooleanPulse1_P_y) {
            tmp164 = _system->_R9_P_IdealCommutingSwitch1_P_Goff;
          } else {
            tmp164 = 1.0;
          }
          (*__A)(8+1,3+1)=tmp164;
          if (_system->_R9_P_BooleanPulse1_P_y) {
            tmp165 = _system->_R9_P_IdealCommutingSwitch2_P_Ron;
          } else {
            tmp165 = 1.0;
          }
          (*__A)(9+1,1+1)=(-tmp165);
          (*__A)(9+1,7+1)=1.0;
          (*__A)(10+1,0+1)=1.0;
          if (_system->_R9_P_BooleanPulse1_P_y) {
            tmp166 = 1.0;
          } else {
            tmp166 = _system->_R9_P_IdealCommutingSwitch2_P_Goff;
          }
          (*__A)(10+1,1+1)=tmp166;
          __b(1)=0.0;
          __b(2)=0.0;
          __b(3)=-0.0;
          __b(4)=-0.0;
          __b(5)=(-__z[14]);
          __b(6)=__z[1];
          __b(7)=-0.0;
          __b(8)=-0.0;
          __b(9)=-0.0;
          __b(10)=-0.0;
          __b(11)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop260::queryDensity()
{
  return 100.*24./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop260::evaluate()
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
void CauerLowPassSCAlgloop260::evaluate(T* __A)
{
    double tmp168;
    double tmp169;
    double tmp170;
    double tmp171;
    double tmp172;
    double tmp173;
    double tmp174;
    double tmp175;
    (*__A)(0+1,2+1)=-1.0;
    (*__A)(0+1,4+1)=-1.0;
    (*__A)(0+1,10+1)=1.0;
    (*__A)(1+1,0+1)=-1.0;
    (*__A)(1+1,9+1)=-1.0;
    (*__A)(1+1,10+1)=-1.0;
    if (_system->_R9_P_BooleanPulse1_P_y) {
      tmp168 = _system->_R9_P_IdealCommutingSwitch2_P_Goff;
    } else {
      tmp168 = 1.0;
    }
    (*__A)(2+1,8+1)=tmp168;
    (*__A)(2+1,9+1)=1.0;
    (*__A)(3+1,7+1)=1.0;
    if (_system->_R9_P_BooleanPulse1_P_y) {
      tmp169 = 1.0;
    } else {
      tmp169 = _system->_R9_P_IdealCommutingSwitch2_P_Ron;
    }
    (*__A)(3+1,8+1)=(-tmp169);
    (*__A)(4+1,6+1)=-1.0;
    (*__A)(4+1,7+1)=1.0;
    if (_system->_R9_P_BooleanPulse1_P_y) {
      tmp170 = _system->_R9_P_IdealCommutingSwitch1_P_Ron;
    } else {
      tmp170 = 1.0;
    }
    (*__A)(5+1,5+1)=(-tmp170);
    (*__A)(5+1,6+1)=1.0;
    (*__A)(6+1,4+1)=1.0;
    if (_system->_R9_P_BooleanPulse1_P_y) {
      tmp171 = 1.0;
    } else {
      tmp171 = _system->_R9_P_IdealCommutingSwitch1_P_Goff;
    }
    (*__A)(6+1,5+1)=tmp171;
    if (_system->_R9_P_BooleanPulse1_P_y) {
      tmp172 = 1.0;
    } else {
      tmp172 = _system->_R9_P_IdealCommutingSwitch1_P_Ron;
    }
    (*__A)(7+1,3+1)=(-tmp172);
    (*__A)(7+1,6+1)=1.0;
    (*__A)(8+1,2+1)=1.0;
    if (_system->_R9_P_BooleanPulse1_P_y) {
      tmp173 = _system->_R9_P_IdealCommutingSwitch1_P_Goff;
    } else {
      tmp173 = 1.0;
    }
    (*__A)(8+1,3+1)=tmp173;
    if (_system->_R9_P_BooleanPulse1_P_y) {
      tmp174 = _system->_R9_P_IdealCommutingSwitch2_P_Ron;
    } else {
      tmp174 = 1.0;
    }
    (*__A)(9+1,1+1)=(-tmp174);
    (*__A)(9+1,7+1)=1.0;
    (*__A)(10+1,0+1)=1.0;
    if (_system->_R9_P_BooleanPulse1_P_y) {
      tmp175 = 1.0;
    } else {
      tmp175 = _system->_R9_P_IdealCommutingSwitch2_P_Goff;
    }
    (*__A)(10+1,1+1)=tmp175;
    __b(1)=0.0;
    __b(2)=0.0;
    __b(3)=-0.0;
    __b(4)=-0.0;
    __b(5)=(-__z[14]);
    __b(6)=__z[1];
    __b(7)=-0.0;
    __b(8)=-0.0;
    __b(9)=-0.0;
    __b(10)=-0.0;
    __b(11)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop260::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop260::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop260::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop260::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_R9_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R9_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R9_P_IdealCommutingSwitch1_P_n1_P_i;
       vars[3] =_system->_R9_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R9_P_n1_P_i;
       vars[5] =_system->_R9_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R9_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R9_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R9_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_R9_P_n2_P_i;
       vars[10] =_system->_R9_P_Capacitor1_P_i;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop260::getNominalReal(double* vars)
{
       vars[0] =_system->_R9_P_IdealCommutingSwitch2_P_n2_P_i;
       vars[1] =_system->_R9_P_IdealCommutingSwitch2_P_s2;
       vars[2] =_system->_R9_P_IdealCommutingSwitch1_P_n1_P_i;
       vars[3] =_system->_R9_P_IdealCommutingSwitch1_P_s1;
       vars[4] =_system->_R9_P_n1_P_i;
       vars[5] =_system->_R9_P_IdealCommutingSwitch1_P_s2;
       vars[6] =_system->_R9_P_Capacitor1_P_p_P_v;
       vars[7] =_system->_R9_P_Capacitor1_P_n_P_v;
       vars[8] =_system->_R9_P_IdealCommutingSwitch2_P_s1;
       vars[9] =_system->_R9_P_n2_P_i;
       vars[10] =_system->_R9_P_Capacitor1_P_i;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop260::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_R9_P_IdealCommutingSwitch2_P_n2_P_i=vars[0];
     _system->_R9_P_IdealCommutingSwitch2_P_s2=vars[1];
     _system->_R9_P_IdealCommutingSwitch1_P_n1_P_i=vars[2];
     _system->_R9_P_IdealCommutingSwitch1_P_s1=vars[3];
     _system->_R9_P_n1_P_i=vars[4];
     _system->_R9_P_IdealCommutingSwitch1_P_s2=vars[5];
     _system->_R9_P_Capacitor1_P_p_P_v=vars[6];
     _system->_R9_P_Capacitor1_P_n_P_v=vars[7];
     _system->_R9_P_IdealCommutingSwitch2_P_s1=vars[8];
     _system->_R9_P_n2_P_i=vars[9];
     _system->_R9_P_Capacitor1_P_i=vars[10];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop260::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop260::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop260::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop260::isLinearTearing()
  {
       return false;
  }