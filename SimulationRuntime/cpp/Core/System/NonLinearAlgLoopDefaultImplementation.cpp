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
{
}

NonLinearAlgLoopDefaultImplementation::~NonLinearAlgLoopDefaultImplementation()
{
  if(_res)
    delete [] _res;
}

/// Provide number (dimension) of variables according to data type
int NonLinearAlgLoopDefaultImplementation::getDimReal() const
{
  return _dimAEq;
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

//void NonLinearAlgLoopDefaultImplementation::getSparseAdata(double* data, int nonzeros)
//{
//  memcpy(data, _AData, sizeof(double) * nonzeros);
//}
/** @} */ // end of coreSystem
