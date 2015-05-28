



CoupledInductorsAlgloop53::CoupledInductorsAlgloop53(CoupledInductors* system, double* z,double* zDot,bool* conditions, boost::shared_ptr<DiscreteEvents> discrete_events )
    : AlgLoopDefaultImplementation()
    , _system(system)
    , __z(z)
    , __zDot(zDot)
 ,__Asparse()

// ,__b(boost::extents[12])
    , _conditions(conditions)
    , _discrete_events(discrete_events)
    , _useSparseFormat(false)
    , _functions(system->_functions)
{
    // Number of unknowns/equations according to type (0: double, 1: int, 2: bool)
    _dimAEq = 12;
    fill_array(__b,0.0);
}

CoupledInductorsAlgloop53::~CoupledInductorsAlgloop53()
{
}

bool CoupledInductorsAlgloop53::getUseSparseFormat()
{
  return _useSparseFormat;
}

void CoupledInductorsAlgloop53::setUseSparseFormat(bool value)
{
  _useSparseFormat = value;
}

void CoupledInductorsAlgloop53::getRHS(double* residuals)
  {

         memcpy(residuals,__b.getData(),sizeof(double)* _dimAEq);
  }
  void CoupledInductorsAlgloop53::initialize()
  {
      if(_useSparseFormat)
        __Asparse = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
      else
        __A = boost::shared_ptr<AMATRIX>( new AMATRIX());
     if(_useSparseFormat)
       CoupledInductorsAlgloop53::initialize(__Asparse.get());
     else
     {
       fill_array(*__A,0.0);
       CoupledInductorsAlgloop53::initialize(__A.get());
     }
  }
  template <typename T>
  void CoupledInductorsAlgloop53::initialize(T *__A)
  {
          (*__A)(0+1,3+1)=_system->_L1_P_L;
          (*__A)(0+1,11+1)=-1.0;
          (*__A)(1+1,1+1)=1.0;
          (*__A)(1+1,10+1)=1.0;
          (*__A)(1+1,11+1)=1.0;
          (*__A)(2+1,9+1)=_system->_k2_P_M;
          (*__A)(2+1,10+1)=1.0;
          (*__A)(3+1,8+1)=1.0;
          (*__A)(3+1,9+1)=_system->_k3_P_M;
          (*__A)(4+1,2+1)=1.0;
          (*__A)(4+1,7+1)=1.0;
          (*__A)(4+1,8+1)=1.0;
          (*__A)(5+1,6+1)=_system->_L2_P_L;
          (*__A)(5+1,7+1)=-1.0;
          (*__A)(6+1,5+1)=1.0;
          (*__A)(6+1,6+1)=_system->_k3_P_M;
          (*__A)(7+1,0+1)=1.0;
          (*__A)(7+1,4+1)=1.0;
          (*__A)(7+1,5+1)=1.0;
          (*__A)(8+1,3+1)=_system->_k2_P_M;
          (*__A)(8+1,4+1)=1.0;
          (*__A)(9+1,2+1)=1.0;
          (*__A)(9+1,3+1)=_system->_k1_P_M;
          (*__A)(10+1,1+1)=1.0;
          (*__A)(10+1,6+1)=_system->_k1_P_M;
          (*__A)(11+1,0+1)=-1.0;
          (*__A)(11+1,9+1)=_system->_L3_P_L;
          __b(1)=_system->_L1_P_v;
          __b(2)=-0.0;
          __b(3)=-0.0;
          __b(4)=-0.0;
          __b(5)=-0.0;
          __b(6)=_system->_L2_P_v;
          __b(7)=-0.0;
          __b(8)=-0.0;
          __b(9)=-0.0;
          __b(10)=-0.0;
          __b(11)=-0.0;
          __b(12)=_system->_L3_P_v;
     // Update the equations once before start of simulation
     evaluate();
  }
float CoupledInductorsAlgloop53::queryDensity()
{
  return 100.*27./_dimAEq/_dimAEq;
}
void CoupledInductorsAlgloop53::evaluate()
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
void CoupledInductorsAlgloop53::evaluate(T* __A)
{
    (*__A)(0+1,3+1)=_system->_L1_P_L;
    (*__A)(0+1,11+1)=-1.0;
    (*__A)(1+1,1+1)=1.0;
    (*__A)(1+1,10+1)=1.0;
    (*__A)(1+1,11+1)=1.0;
    (*__A)(2+1,9+1)=_system->_k2_P_M;
    (*__A)(2+1,10+1)=1.0;
    (*__A)(3+1,8+1)=1.0;
    (*__A)(3+1,9+1)=_system->_k3_P_M;
    (*__A)(4+1,2+1)=1.0;
    (*__A)(4+1,7+1)=1.0;
    (*__A)(4+1,8+1)=1.0;
    (*__A)(5+1,6+1)=_system->_L2_P_L;
    (*__A)(5+1,7+1)=-1.0;
    (*__A)(6+1,5+1)=1.0;
    (*__A)(6+1,6+1)=_system->_k3_P_M;
    (*__A)(7+1,0+1)=1.0;
    (*__A)(7+1,4+1)=1.0;
    (*__A)(7+1,5+1)=1.0;
    (*__A)(8+1,3+1)=_system->_k2_P_M;
    (*__A)(8+1,4+1)=1.0;
    (*__A)(9+1,2+1)=1.0;
    (*__A)(9+1,3+1)=_system->_k1_P_M;
    (*__A)(10+1,1+1)=1.0;
    (*__A)(10+1,6+1)=_system->_k1_P_M;
    (*__A)(11+1,0+1)=-1.0;
    (*__A)(11+1,9+1)=_system->_L3_P_L;
    __b(1)=_system->_L1_P_v;
    __b(2)=-0.0;
    __b(3)=-0.0;
    __b(4)=-0.0;
    __b(5)=-0.0;
    __b(6)=_system->_L2_P_v;
    __b(7)=-0.0;
    __b(8)=-0.0;
    __b(9)=-0.0;
    __b(10)=-0.0;
    __b(11)=-0.0;
    __b(12)=_system->_L3_P_v;
}
/// Provide number (dimension) of variables according to data type
int  CoupledInductorsAlgloop53::getDimReal() const
{
    return(AlgLoopDefaultImplementation::getDimReal());
};

/// Provide number (dimension) of residuals according to data type
int  CoupledInductorsAlgloop53::getDimRHS() const
{
    return(AlgLoopDefaultImplementation::getDimRHS());
};

bool  CoupledInductorsAlgloop53::isConsistent()
{
    return _system->isConsistent();
};

/// Provide variables with given index to the system
void  CoupledInductorsAlgloop53::getReal(double* vars)
{
    AlgLoopDefaultImplementation::getReal(vars);
    //workaroud until names of algloop vars are replaced in simcode
       vars[0] =_system->_L3_P_ICP_P_v;
       vars[1] =_system->_k1_P_inductiveCouplePin1_P_v;
       vars[2] =_system->_k1_P_inductiveCouplePin2_P_v;
       vars[3] =_system->_L1_P_ICP_P_di;
       vars[4] =_system->_k2_P_inductiveCouplePin2_P_v;
       vars[5] =_system->_k3_P_inductiveCouplePin1_P_v;
       vars[6] =_system->_L2_P_ICP_P_di;
       vars[7] =_system->_L2_P_ICP_P_v;
       vars[8] =_system->_k3_P_inductiveCouplePin2_P_v;
       vars[9] =_system->_L3_P_ICP_P_di;
       vars[10] =_system->_k2_P_inductiveCouplePin1_P_v;
       vars[11] =_system->_L1_P_ICP_P_v;
};

/// Provide nominal variables with given index to the system
void  CoupledInductorsAlgloop53::getNominalReal(double* vars)
{
       vars[0] =_system->_L3_P_ICP_P_v;
       vars[1] =_system->_k1_P_inductiveCouplePin1_P_v;
       vars[2] =_system->_k1_P_inductiveCouplePin2_P_v;
       vars[3] =_system->_L1_P_ICP_P_di;
       vars[4] =_system->_k2_P_inductiveCouplePin2_P_v;
       vars[5] =_system->_k3_P_inductiveCouplePin1_P_v;
       vars[6] =_system->_L2_P_ICP_P_di;
       vars[7] =_system->_L2_P_ICP_P_v;
       vars[8] =_system->_k3_P_inductiveCouplePin2_P_v;
       vars[9] =_system->_L3_P_ICP_P_di;
       vars[10] =_system->_k2_P_inductiveCouplePin1_P_v;
       vars[11] =_system->_L1_P_ICP_P_v;
};

/// Set variables with given index to the system
void  CoupledInductorsAlgloop53::setReal(const double* vars)
{
    //workaround until names of algloop vars are replaced in simcode


     _system->_L3_P_ICP_P_v=vars[0];
     _system->_k1_P_inductiveCouplePin1_P_v=vars[1];
     _system->_k1_P_inductiveCouplePin2_P_v=vars[2];
     _system->_L1_P_ICP_P_di=vars[3];
     _system->_k2_P_inductiveCouplePin2_P_v=vars[4];
     _system->_k3_P_inductiveCouplePin1_P_v=vars[5];
     _system->_L2_P_ICP_P_di=vars[6];
     _system->_L2_P_ICP_P_v=vars[7];
     _system->_k3_P_inductiveCouplePin2_P_v=vars[8];
     _system->_L3_P_ICP_P_di=vars[9];
     _system->_k2_P_inductiveCouplePin1_P_v=vars[10];
     _system->_L1_P_ICP_P_v=vars[11];

    AlgLoopDefaultImplementation::setReal(vars);
};


  void CoupledInductorsAlgloop53::getSystemMatrix(double* A_matrix)
  {
       memcpy(A_matrix,__A->getData(),_dimAEq*_dimAEq*sizeof(double));
  }
  void CoupledInductorsAlgloop53::getSystemMatrix(SparseMatrix* A_matrix)
  {
       *A_matrix=*__Asparse;
  }
  bool CoupledInductorsAlgloop53::isLinear()
  {
       return true;
  }
  bool CoupledInductorsAlgloop53::isLinearTearing()
  {
       return false;
  }