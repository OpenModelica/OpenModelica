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
  ,_x0(NULL)
 , _firstcall(true)
{

}

LinearAlgLoopDefaultImplementation::~LinearAlgLoopDefaultImplementation()
{
  if(_b)
    delete [] _b;
 if (_x0)
	 delete [] _x0;
}

/// Provide number (dimension) of variables according to data type
int LinearAlgLoopDefaultImplementation::getDimReal() const
{
  return _dimAEq;
}

int LinearAlgLoopDefaultImplementation::getDimZeroFunc() const
{
   return _dimZeroFunc;
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
  if(_x0)
	  delete [] _x0;
  _x0 = new double[_dimAEq];
};

void LinearAlgLoopDefaultImplementation::getb(double* res) const
{
  memcpy(res, _b, sizeof(double) * _dimAEq);
}


bool LinearAlgLoopDefaultImplementation::getUseSparseFormat(){
  return _useSparseFormat;
}

void LinearAlgLoopDefaultImplementation::setUseSparseFormat(bool value){
  _useSparseFormat = value;
}
void LinearAlgLoopDefaultImplementation::getRealStartValues(double* vars) const
{
    memcpy(vars, _x0, sizeof(double) * _dimAEq);
}


//void LinearAlgLoopDefaultImplementation::getSparseAdata(double* data, int nonzeros)
//{
//  memcpy(data, _AData, sizeof(double) * nonzeros);
//}
/** @} */ // end of coreSystem
