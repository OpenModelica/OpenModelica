/** @addtogroup coreSystem
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
#include <Core/System/FactoryExport.h>
#include <Core/System/AlgLoopDefaultImplementation.h>

bool BOOST_EXTENSION_EXPORT_DECL mycompare ( mytuple lhs, mytuple rhs)
{
	return lhs.ele1 < rhs.ele1;
}

AlgLoopDefaultImplementation::AlgLoopDefaultImplementation()
  : _dimAEq         (0)
  , _constraintType(IAlgLoop::UNDEF)
  ,__xd(NULL)
  ,_xd_init(NULL)
  ,_AData(NULL)
  ,_Ax(NULL)
{
}

AlgLoopDefaultImplementation::~AlgLoopDefaultImplementation()
{
  if(__xd)
    delete [] __xd;
  if(_xd_init)
    delete [] _xd_init;
}

/// Provide number (dimension) of variables according to data type
int AlgLoopDefaultImplementation::getDimReal() const
{
  return _dimAEq;
};

/// Provide number (dimension) of residuals according to data type
int AlgLoopDefaultImplementation::getDimRHS() const
{
  return _dimAEq;
};

/// (Re-) initialize the system of equations
void AlgLoopDefaultImplementation::initialize()
{
  if ( _dimAEq == 0 )
    throw ModelicaSimulationError(ALGLOOP_EQ_SYSTEM,"AlgLoop::initialize(): No constraint defined.");
  _constraintType = IAlgLoop::REAL;
  if(__xd)
    delete [] __xd;
  if(_xd_init)
    delete [] _xd_init;
  __xd     = new double[_dimAEq];
  _xd_init = new double[_dimAEq];
  memset(__xd,0,_dimAEq*sizeof(double));
  memset(_xd_init,0,_dimAEq*sizeof(double));
};

/// Output routine (to be called by the solver after every successful integration step)
void AlgLoopDefaultImplementation::writeOutput(const OUTPUT command )
{
};

//in algloop default verschieben
void AlgLoopDefaultImplementation::setReal(const double* lambda)
{
  memcpy(__xd, lambda, sizeof(double) * _dimAEq);
}

//in algloop default verschieben
void AlgLoopDefaultImplementation::getReal(double* lambda)
{
  memcpy(lambda, __xd, sizeof(double) * _dimAEq);
}

//in algloop default verschieben
void AlgLoopDefaultImplementation::getRHS(double* res)
{
  memcpy(res, __xd, sizeof(double) * _dimAEq);
}
//void AlgLoopDefaultImplementation::getSparseAdata(double* data, int nonzeros)
//{
//  memcpy(data, _AData, sizeof(double) * nonzeros);
//}
/** @} */ // end of coreSystem
