/** @addtogroup solverNox
 *  @{
 *
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Solver/Nox/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>
#include <Solver/Nox/NoxLapackInterface.h>

//! Constructor
NoxLapackInterface::NoxLapackInterface(INonLinearAlgLoop *algLoop)//second argument unnecessary. Just initialize _lambda to 1.0
	:_algLoop(algLoop)
	,_useDomainScaling(false)
	,_useFunctionValueScaling(true)
	,_yScale(NULL)
	,_fScale(NULL)
	,_xtemp(NULL)
	,_rhs(NULL)
	,_lambda(1.0)//set to 1.0 in case we do not use homotopy.
	,_computedinitialguess(false)
	,_evaluatedJacobianAtInitialGuess(false)
  ,_UseAccurateJacobian(false)
  ,_numberofhomotopytries(-1)
  , _lc(LC_NLS)
{
	_dimSys = _algLoop->getDimReal();
	_initialGuess = Teuchos::rcp(new NOX::LAPACK::Vector(_dimSys));
	_J = Teuchos::rcp(new NOX::LAPACK::Matrix<double>(_dimSys,_dimSys));
	_rhs = new double[_dimSys];//stores f(x)
	_xtemp = new double[_dimSys];//stores x temporarily

	//getting scaling factors
	if (_useDomainScaling){
		if(_yScale) delete [] _yScale;
		_yScale = new double[_dimSys];
		_algLoop->getNominalReal(_yScale);//in Kinsol, this is issued in the function Kinsol::initialize(). I hope this works as well.
		for (int i=0; i<_dimSys; i++){
			if(_yScale[i] != 0)
				_yScale[i] = 1/_yScale[i];
			else
				_yScale[i] = 1;
		}
	}

	if (_useFunctionValueScaling){
		if(_fScale) delete [] _fScale;
		_fScale = new double[_dimSys];
	}

}

//! Destructor
NoxLapackInterface::~NoxLapackInterface()
{
    if(_yScale) delete [] _yScale;
    if(_fScale) delete [] _fScale;
	if (_rhs) delete [] _rhs;
	if (_xtemp) delete [] _xtemp;
}

//we could replace this by the x0 in Nox.cpp
/**
 *  \brief stores initial guess from algebraic loop and scaling vectors for F.
 *
 *  \return Initial guess
 *
 *  \details Details
 */
const NOX::LAPACK::Vector& NoxLapackInterface::getInitialGuess()
{
	if (!_computedinitialguess){
		double* x = new double[_dimSys];

		_algLoop->getReal(x);
		_algLoop->evaluate();

		for(int i=0;i<_dimSys;i++){
			if (_useDomainScaling) {
				(*_initialGuess)(i)=x[i]*_yScale[i];
			}else{
				(*_initialGuess)(i)=x[i];
			}
		}

		if (_useFunctionValueScaling){
			_algLoop->evaluate();
			_algLoop->getRHS(_fScale);
			for(int i=0;i<_dimSys;i++){
				if (std::abs(_fScale[i])<1.0)
					_fScale[i]=1.0;
			}
      LOGGER_WRITE_VECTOR("_fScale=", _fScale, _dimSys, _lc, LL_DEBUG);

		}

		delete [] x;
		_computedinitialguess=true;
	}
	return *_initialGuess;
};
/**
 *  \brief get F
 *
 *  \param [out] f right hand side
 *  \param [in] x current position
 *  \return true
 *
 *  \details sets high values in F if evaluation yields errors.
 */
bool NoxLapackInterface::computeActualF(NOX::LAPACK::Vector& f, const NOX::LAPACK::Vector &x){
	for (int i=0;i<_dimSys;i++){
		if (_useDomainScaling){
			_xtemp[i]=x(i)/_yScale[i];
		}else{
			_xtemp[i]=x(i);
		}
	}

  LOGGER_WRITE_VECTOR("x",_xtemp, _dimSys, _lc, LL_DEBUG);

	_algLoop->setReal(_xtemp);
	_algLoop->getRHS(_rhs);
	try{
		_algLoop->evaluate();
		_algLoop->getRHS(_rhs);
	}catch(const std::exception &ex)
	{
    LOGGER_WRITE("calculating right hand side failed with error message: " + std::string(ex.what()),_lc, LL_DEBUG);
		//the following should be done when some to be implemented flag like "continue if function evaluation fails" is activated.
		for(int i=0;i<_dimSys;i++){
			_rhs[i]= ((_rhs[i]<0.0) ? -1.0e12 : 1.0e12);
		}
	}

  LOGGER_WRITE_VECTOR("_rhs",_rhs, _dimSys, _lc, LL_DEBUG);

	for (int i=0;i<_dimSys;i++){

		if (_useFunctionValueScaling){
			f(i)=_rhs[i]/_fScale[i];
		}else{
			f(i)=_rhs[i];
		}
		//checking for infinity.
		if (f(i)>=std::numeric_limits<double>::max()) f(i)=1.0e12;
		if (f(i)<=-std::numeric_limits<double>::max()) f(i)=-1.0e12;
		//checking for NaN. Do NOT delete the next line, it makes sense.
		if (!(f(i)==f(i))) f(i)=1.0e12;
	}
	return true;
}
/**
 *  \brief get jacobian
 *
 *  \param [out] J Jacobian
 *  \param [in] x current position
 *  \return true
 *
 *  \details calls computeF repeatedly
 */
bool NoxLapackInterface::computeJacobian(NOX::LAPACK::Matrix<double>& J, const NOX::LAPACK::Vector & x){
	//setting the forward difference parameters. We divide by the denominator alpha*|x_i|+beta in the computation of the difference quotient. It is similar to the Finite Difference implementation by Nox, which can be found under https://trilinos.org/docs/dev/packages/nox/doc/html/classNOX_1_1Epetra_1_1FiniteDifference.html
	double alpha=1.0e-11;
	double beta=1.0e-9;
	NOX::LAPACK::Vector f1(_dimSys);//f(x+(alpha*|x_i|+beta)*e_i)
	NOX::LAPACK::Vector f2(_dimSys);//f(x)
	NOX::LAPACK::Vector f3(_dimSys);//f(x)
	NOX::LAPACK::Vector f4(_dimSys);//f(x)
	NOX::LAPACK::Vector xplushei(x);//x+(alpha*|x_i|+beta)*e_i

  if(_UseAccurateJacobian){
    for (int i=0;i<_dimSys;i++){
      double h = std::max(1.0e-3,1.0e-10*std::abs(xplushei(i)));
      //adding the denominator of the difference quotient
      xplushei(i)+=h;
      computeF(f2,xplushei);
      xplushei(i)+=h;
      computeF(f1,xplushei);
      xplushei(i)=x(i);

      xplushei(i)-=h;
      computeF(f3,xplushei);
      xplushei(i)-=h;
      computeF(f4,xplushei);

      for (int j=0;j<_dimSys;j++){
        //J(j,i) = (f1(j)-f2(j))/(xplushei(i)-x(i));//=\partial_i f_j
        J(j,i) = (8*(f2(j)-f3(j))-(f1(j)-f4(j)))/(6.0*(x(i)-xplushei(i)));//=\partial_i f_j
      }
      xplushei(i)=x(i);
    }
  }else{
    computeF(f2,x);
    for (int i=0;i<_dimSys;i++){
      //adding the denominator of the difference quotient
      xplushei(i)+=alpha*std::abs(xplushei(i))+beta;
      computeF(f1,xplushei);
      for (int j=0;j<_dimSys;j++){
        J(j,i) = (f1(j)-f2(j))/(xplushei(i)-x(i));//=\partial_i f_j
      }
      xplushei(i)=x(i);
    }
  }

	return true;
}
/**
 *  \brief sets continuation parameters
 *
 *  \param [in] p parameters
 *  \return void
 *
 *  \details Homotopy parameter
 */
void NoxLapackInterface::setParams(const LOCA::ParameterVector& p) {
	_lambda = p.getValue("lambda");
}

/**
 *  \brief does nothing
 *
 *  \param [in] x current position
 *  \param [in] conParam does nothing
 *  \return Return_Description
 *
 *  \details does nothing
 */
void NoxLapackInterface::printSolution(const NOX::LAPACK::Vector &x, const double conParam)
{

}
/**
 *  \brief computes matrix vector product
 *
 *  \param [in] A Matrix
 *  \param [in] x Vector
 *  \return A*x
 *
 *  \details requires number of columns of A to be equal to dimension of x
 */
NOX::LAPACK::Vector NoxLapackInterface::applyMatrixtoVector(const NOX::LAPACK::Matrix<double> &A, const NOX::LAPACK::Vector &x){
	NOX::LAPACK::Vector result(A.numRows());
	for(int i=0;i<A.numRows();i++){
		for(int j=0;j<A.numCols();j++){
			result(i)+=A(i,j)*x(j);
		}
	}
	return result;
}
/**
 *  \brief Brief
 *
 *  \return number of simple functions for homotopy
 *
 *  \details see also NoxLapackInterface::computeSimplifiedF()
 */
int NoxLapackInterface::getMaxNumberOfHomotopyTries(){
  return 6;
}
/**
 *  \brief Brief
 *
 *  \param [in] number number of simple function for homotopy
 *  \return void
 *
 *  \details see also NoxLapackInterface::computeSimplifiedF()
 */
void NoxLapackInterface::setNumberOfHomotopyTries(const int & number){
  if ((number>-1) && (number < getMaxNumberOfHomotopyTries())){
    _numberofhomotopytries=number;
  }else{
    LOGGER_WRITE("set illegal value for number of homotopy tries. Abort",_lc, LL_DEBUG);
    throw ModelicaSimulationError(ALGLOOP_SOLVER,"set illegal value for number of homotopy tries. Abort!");
  }
}

/**
 *  \brief computes G(x), where G is the simple function in homotopy
 *
 *  \param [out] f rhs of simple function at position x
 *  \param [in] x postion
 *  \return void
 *
 *  \details there are getMaxNumberOfHomotopyTries() many simple functions for homotopy + the zero function, which means no homotopy at all. These are:
 *  Simple Function -1: G(x)=0
 *  Simple Function 0: G(x)=x-x0
 *  Simple Function 1: G(x)=x0-x
 *  Simple Function 2: G(x)=F(x)-F(x0)
 *  Simple Function 3: G(x)=F(x0)-F(x)
 *  Simple Function 4: G(x)=F'(x0)(F(x)-F(x0))
 *  Simple Function 5: G(x)=F'(x0)(F(x0)-F(x))
 *  x0 denotes the initial guess
 */
bool NoxLapackInterface::computeSimplifiedF(NOX::LAPACK::Vector& f, const NOX::LAPACK::Vector &x){
	NOX::LAPACK::Vector zeroandtempvec(_dimSys);
	double templambda=_lambda;//storing _lambda temporarily.

	switch(_numberofhomotopytries){
		case -1:
			f=zeroandtempvec;
			break;
		case 0:
			//This is Fixed Point Homotopy, so we take f(x)=x-x_0.
			f.update(1.0,x,-1.0,getInitialGuess());
			break;
		case 1://This is Fixed Point Homotopy, so we take f(x)=x_0-x.
			f.update(-1.0,x,1.0,getInitialGuess());
			break;
		case 2:
			//This is Newton Homotopy, so we take f(x)=F(x)-F(x_0).
			computeActualF(f,x);
			computeActualF(zeroandtempvec,getInitialGuess());
			f.update(-1.0,zeroandtempvec,1.0);
			break;
		case 3:
			//This is Newton Homotopy, so we take f(x)=F(x_0)-F(x).
			computeActualF(f,x);
			computeActualF(zeroandtempvec,getInitialGuess());
			f.update(1.0,zeroandtempvec,-1.0);
			break;
		case 4:
			//This is Affine Homotopy, so we take f(x)=F'(x_0)(x-x_0)=F'(x_0)x-F'(x_0)x_0
			if(!_evaluatedJacobianAtInitialGuess){
        _lambda=1.0;//setting _lambda such that computeJacobian returns F'(x_0) instead of _lambda*F(x)+(1-_lambda)*f(x)
				_evaluatedJacobianAtInitialGuess=true;
				computeJacobian(*_J,getInitialGuess());
			_lambda=templambda;
			}
			f.update(1.0,applyMatrixtoVector(*_J,x),-1.0,applyMatrixtoVector(*_J,getInitialGuess()));
			break;
		case 5:
			//This is Affine Homotopy, so we take f(x)=F'(x_0)(x-x_0)=F'(x_0)x_0-F'(x_0)x
			if(!_evaluatedJacobianAtInitialGuess){
        _lambda=1.0;//setting _lambda such that computeJacobian returns F'(x_0) instead of _lambda*F(x)+(1-_lambda)*f(x)
				_evaluatedJacobianAtInitialGuess=true;
				computeJacobian(*_J,getInitialGuess());
			_lambda=templambda;
			}
			f.update(-1.0,applyMatrixtoVector(*_J,x),1.0,applyMatrixtoVector(*_J,getInitialGuess()));
			break;
		default:
			throw ModelicaSimulationError(ALGLOOP_SOLVER,"_numberofhomotopytries has illegal value!");
			break;
	}
	return true;
}

/**
 *  \brief Brief
 *
 *  \param [in] f Parameter_Description
 *  \param [in] x Parameter_Description
 *  \return Return_Description
 *  \brief Jacobian based scaling
 *
 *  \return void
 *
 *  \details uses maximum entry in each row of the jacobian as scaling value for F.
 */
void NoxLapackInterface::setFunctionScalingValues(){
  if(_useFunctionValueScaling){
    NOX::LAPACK::Matrix<double> jac(_dimSys,_dimSys);
    computeJacobian(jac,getInitialGuess());
    double MaxEntry=0;
    for (int i=0;i<_dimSys;i++){
      for (int j=0;j<_dimSys;j++){
        MaxEntry=std::max(MaxEntry,std::abs(jac(j,i)));
      }
      _fScale[i]=MaxEntry;
    }
    std::for_each(_fScale,_fScale+_dimSys,[](double &a){a=std::max(1.0,a);});
    LOGGER_WRITE_VECTOR("_fScale", _fScale, _dimSys, _lc, LL_DEBUG);
  }
}
/**
 *  \brief computes F
 *
 *  \param [out] f right hand side F
 *  \param [in] x position x
 *  \return true
 *
 *  \details calculates F as convex combination of simplified function and actual right hand side.
 */
bool NoxLapackInterface::computeF(NOX::LAPACK::Vector& f, const NOX::LAPACK::Vector &x){
	NOX::LAPACK::Vector g(_dimSys);
	NOX::LAPACK::Vector h(_dimSys);

	computeActualF(g,x);
	computeSimplifiedF(h,x);

	//f(x)=lambda*g(x)+(1-lambda)*h(x)
	f.update(_lambda, g, 1.0-_lambda, h);
	return true;
}

/** @} */ // end of solverNoxLapackInterface
