/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop167.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h" */



CauerLowPassSCAlgloop167::CauerLowPassSCAlgloop167(CauerLowPassSC* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
    : AlgLoopDefaultImplementation()
    , _system(system)
    , __z(z)
    , __zDot(zDot)
 ,__Asparse()

// ,__b(boost::extents[10])
    , _conditions(conditions)
    , _discrete_events(discrete_events)
    , _useSparseFormat(false)
    , _functions(system->_functions)
{
    // Number of unknowns/equations according to type (0: double, 1: int, 2: bool)
    _dimAEq = 10;
    fill_array(__b,0.0);
}

CauerLowPassSCAlgloop167::~CauerLowPassSCAlgloop167()
{
}

bool CauerLowPassSCAlgloop167::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CauerLowPassSCAlgloop167::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CauerLowPassSCAlgloop167::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CauerLowPassSCAlgloop167::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CauerLowPassSCAlgloop167::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CauerLowPassSCAlgloop167::initialize(__A.get());
     }
  }
  template <typename T>
  void CauerLowPassSCAlgloop167::initialize(T *__A)
  {
          (*__A)(0+1,4+1)=1.0;
          (*__A)(0+1,9+1)=-1.0;
          (*__A)(1+1,8+1)=(-_system->_C2_P_C);
          (*__A)(1+1,9+1)=1.0;
          (*__A)(2+1,7+1)=1.0;
          (*__A)(2+1,8+1)=_system->_C6_P_C;
          (*__A)(3+1,0+1)=-1.0;
          (*__A)(3+1,6+1)=-1.0;
          (*__A)(3+1,7+1)=1.0;
          (*__A)(4+1,5+1)=_system->_C5_P_C;
          (*__A)(4+1,6+1)=1.0;
          (*__A)(5+1,4+1)=1.0;
          (*__A)(5+1,5+1)=(-_system->_C1_P_C);
          (*__A)(6+1,3+1)=1.0;
          (*__A)(6+1,8+1)=(-_system->_C8_P_C);
          (*__A)(7+1,2+1)=1.0;
          (*__A)(7+1,3+1)=-1.0;
          (*__A)(8+1,1+1)=_system->_C9_P_C;
          (*__A)(8+1,2+1)=1.0;
          (*__A)(9+1,0+1)=1.0;
          (*__A)(9+1,1+1)=(-_system->_C4_P_C);
          __b(1)=(((-_system->_R1_P_n2_P_i) - _system->_R2_P_n2_P_i) - _system->_R3_P_n1_P_i);
          __b(2)=-0.0;
          __b(3)=-0.0;
          __b(4)=((-_system->_Rp1_P_n2_P_i) - _system->_R7_P_n2_P_i);
          __b(5)=-0.0;
          __b(6)=-0.0;
          __b(7)=-0.0;
          __b(8)=((-_system->_R11_P_n1_P_i) - _system->_R10_P_n2_P_i);
          __b(9)=-0.0;
          __b(10)=-0.0;
     // Update the equations once before start of simulation
     evaluate();
  }
float CauerLowPassSCAlgloop167::queryDensity()
{
  return 100.*21./_dimAEq/_dimAEq;
}
void CauerLowPassSCAlgloop167::evaluate()
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
void CauerLowPassSCAlgloop167::evaluate(T* __A)
{
    (*__A)(0+1,4+1)=1.0;
    (*__A)(0+1,9+1)=-1.0;
    (*__A)(1+1,8+1)=(-_system->_C2_P_C);
    (*__A)(1+1,9+1)=1.0;
    (*__A)(2+1,7+1)=1.0;
    (*__A)(2+1,8+1)=_system->_C6_P_C;
    (*__A)(3+1,0+1)=-1.0;
    (*__A)(3+1,6+1)=-1.0;
    (*__A)(3+1,7+1)=1.0;
    (*__A)(4+1,5+1)=_system->_C5_P_C;
    (*__A)(4+1,6+1)=1.0;
    (*__A)(5+1,4+1)=1.0;
    (*__A)(5+1,5+1)=(-_system->_C1_P_C);
    (*__A)(6+1,3+1)=1.0;
    (*__A)(6+1,8+1)=(-_system->_C8_P_C);
    (*__A)(7+1,2+1)=1.0;
    (*__A)(7+1,3+1)=-1.0;
    (*__A)(8+1,1+1)=_system->_C9_P_C;
    (*__A)(8+1,2+1)=1.0;
    (*__A)(9+1,0+1)=1.0;
    (*__A)(9+1,1+1)=(-_system->_C4_P_C);
    __b(1)=(((-_system->_R1_P_n2_P_i) - _system->_R2_P_n2_P_i) - _system->_R3_P_n1_P_i);
    __b(2)=-0.0;
    __b(3)=-0.0;
    __b(4)=((-_system->_Rp1_P_n2_P_i) - _system->_R7_P_n2_P_i);
    __b(5)=-0.0;
    __b(6)=-0.0;
    __b(7)=-0.0;
    __b(8)=((-_system->_R11_P_n1_P_i) - _system->_R10_P_n2_P_i);
    __b(9)=-0.0;
    __b(10)=-0.0;
}
/// Provide number (dimension) of variables according to data type
int  CauerLowPassSCAlgloop167::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CauerLowPassSCAlgloop167::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CauerLowPassSCAlgloop167::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CauerLowPassSCAlgloop167::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_C4_P_i;
       vars[1] = __zDot[3] ;
       vars[2] =_system->_C9_P_i;
       vars[3] =_system->_C8_P_i;
       vars[4] =_system->_C1_P_i;
       vars[5] = __zDot[0] ;
       vars[6] =_system->_C5_P_i;
       vars[7] =_system->_C6_P_i;
       vars[8] = __zDot[1] ;
       vars[9] =_system->_C2_P_i;
};

/// Provide nominal variables with given index to the system
void  CauerLowPassSCAlgloop167::getNominalReal(double* vars)
{
       vars[0] =_system->_C4_P_i;
       vars[1] = __zDot[3] ;
       vars[2] =_system->_C9_P_i;
       vars[3] =_system->_C8_P_i;
       vars[4] =_system->_C1_P_i;
       vars[5] = __zDot[0] ;
       vars[6] =_system->_C5_P_i;
       vars[7] =_system->_C6_P_i;
       vars[8] = __zDot[1] ;
       vars[9] =_system->_C2_P_i;
};

/// Set variables with given index to the system
void  CauerLowPassSCAlgloop167::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_C4_P_i=vars[0];
      __zDot[3] =vars[1];
     _system->_C9_P_i=vars[2];
     _system->_C8_P_i=vars[3];
     _system->_C1_P_i=vars[4];
      __zDot[0] =vars[5];
     _system->_C5_P_i=vars[6];
     _system->_C6_P_i=vars[7];
      __zDot[1] =vars[8];
     _system->_C2_P_i=vars[9];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CauerLowPassSCAlgloop167::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CauerLowPassSCAlgloop167::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CauerLowPassSCAlgloop167::isLinear()
  {
       return true;
  }
  bool CauerLowPassSCAlgloop167::isLinearTearing()
  {
       return false;
  }