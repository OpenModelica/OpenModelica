/** @addtogroup coreSystem
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
#include <Core/System/FactoryExport.h>
#include <Core/System/NonLinearAlgLoopDefaultImplementation.h>

/*bool BOOST_EXTENSION_EXPORT_DECL mycompare ( mytuple lhs, mytuple rhs)
{
	return lhs.ele1 < rhs.ele1;
}*/

NonLinearAlgLoopDefaultImplementation::NonLinearAlgLoopDefaultImplementation()
  : _dimAEq         (0)
  ,_res(NULL)
  ,_AData(NULL)
  ,_Ax(NULL)
  ,_x0(NULL)
, _firstcall(true)
{
}

NonLinearAlgLoopDefaultImplementation::~NonLinearAlgLoopDefaultImplementation()
{
  if(_res)
    delete [] _res;
if (_x0)
	 delete _x0;
}

/// Provide number (dimension) of variables according to data type
int NonLinearAlgLoopDefaultImplementation::getDimReal() const
{
  return _dimAEq;
}

int NonLinearAlgLoopDefaultImplementation::getDimZeroFunc() const
{
   return _dimZeroFunc;
}

/// (Re-) initialize the system of equations
void NonLinearAlgLoopDefaultImplementation::initialize()
{
  if ( _dimAEq == 0 )
    throw ModelicaSimulationError(ALGLOOP_EQ_SYSTEM,"AlgLoop::initialize(): No constraint defined.");

  if(_res)
    delete [] _res;
  _res     = new double[_dimAEq];
  memset(_res,0,_dimAEq*sizeof(double));
   if(_x0)
	  delete [] _x0;
   _x0 = new double[_dimAEq];
};

//in algloop default verschieben
void NonLinearAlgLoopDefaultImplementation::getRHS(double* res) const
{
  memcpy(res, _res, sizeof(double) * _dimAEq);
}

bool NonLinearAlgLoopDefaultImplementation::getUseSparseFormat(){
  return _useSparseFormat;
}

void NonLinearAlgLoopDefaultImplementation::setUseSparseFormat(bool value){
  _useSparseFormat = value;
}

void NonLinearAlgLoopDefaultImplementation::getRealStartValues(double* vars) const
{

	 memcpy(vars, _x0, sizeof(double) * _dimAEq);
}


//void NonLinearAlgLoopDefaultImplementation::getSparseAdata(double* data, int nonzeros)
//{
//  memcpy(data, _AData, sizeof(double) * nonzeros);
//}
/** @} */ // end of coreSystem
