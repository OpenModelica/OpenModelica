/** @addtogroup coreSystem
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
#include <Core/System/FactoryExport.h>
#include <Core/System/LinearAlgLoopDefaultImplementation.h>

LinearAlgLoopDefaultImplementation::LinearAlgLoopDefaultImplementation()
  : _dimAEq         (0)
  ,_b(NULL)
  ,_AData(NULL)
  ,_Ax(NULL)
{
}

LinearAlgLoopDefaultImplementation::~LinearAlgLoopDefaultImplementation()
{
  if(_b)
    delete [] _b;
}

/// Provide number (dimension) of variables according to data type
int LinearAlgLoopDefaultImplementation::getDimReal() const
{
  return _dimAEq;
}

/// (Re-) initialize the system of equations
void LinearAlgLoopDefaultImplementation::initialize()
{
  if ( _dimAEq == 0 )
    throw ModelicaSimulationError(ALGLOOP_EQ_SYSTEM,"AlgLoop::initialize(): No constraint defined.");

  if(_b)
    delete [] _b;
  _b     = new double[_dimAEq];
  memset(_b,0,_dimAEq*sizeof(double));
};

void LinearAlgLoopDefaultImplementation::getRHS(double* res) const
{
  memcpy(res, _b, sizeof(double) * _dimAEq);
}


bool LinearAlgLoopDefaultImplementation::getUseSparseFormat(){
  return _useSparseFormat;
}

void LinearAlgLoopDefaultImplementation::setUseSparseFormat(bool value){
  _useSparseFormat = value;
}



//void LinearAlgLoopDefaultImplementation::getSparseAdata(double* data, int nonzeros)
//{
//  memcpy(data, _AData, sizeof(double) * nonzeros);
//}
/** @} */ // end of coreSystem
