#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Solver/Nox/NoxLapackInterface.h>

//! Constructor


NoxLapackInterface::NoxLapackInterface(INonLinearAlgLoop *algLoop)
	:_algLoop(algLoop)
	,_generateoutput(false)
	,_useDomainScaling(false)
	,_useFunctionValueScaling(true)
	,_yScale(NULL)
	,_fScale(NULL)
{
	_dimSys = _algLoop->getDimReal();
	_initialGuess = Teuchos::rcp(new NOX::LAPACK::Vector(_dimSys));

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
	//no need to delete the alglooppointer, since the algloop passed is passed as a shared pointer.
}

const NOX::LAPACK::Vector& NoxLapackInterface::getInitialGuess()
{
	double* x = new double[_dimSys];
	_algLoop->getReal(x);

	if (_generateoutput) std::cout << "computing initial guess" << std::endl;

	for(int i=0;i<_dimSys;i++){
		if (_useDomainScaling) {
			(*_initialGuess)(i)=x[i]*_yScale[i];
		}else{
			(*_initialGuess)(i)=x[i];
		}

		//quick test whether the scaling worked correctly
		if (_useDomainScaling) if ((*_initialGuess)(i)>1e4 || ((*_initialGuess)(i)<1e-4 && (*_initialGuess)(i)>1e-12)) std::cout << "scaling initial guess failed. Initial Guess (" << i << ")=" << (*_initialGuess)(i) << std::endl;
	}

	if (_generateoutput) {
		std::cout << "Initial guess is given by " << std::endl;
		for(int i=0;i<_dimSys;i++) std::cout << (*_initialGuess)(i) << " ";
		std::cout << std::endl;
	}

	if (_useFunctionValueScaling){
		_algLoop->evaluate();
		_algLoop->getRHS(_fScale);
		if (_generateoutput) std::cout << "_fScale = (";
		for(int i=0;i<_dimSys;i++){
			if (std::abs(_fScale[i])<1.0)
				_fScale[i]=1.0;
			if (_generateoutput) std::cout << " " << _fScale[i];
		}
		if (_generateoutput) std::cout << ")" << std::endl;
	}

	delete [] x;
	return *_initialGuess;
};

bool NoxLapackInterface::computeF(NOX::LAPACK::Vector& f, const NOX::LAPACK::Vector &x){
	double* rhs = new double[_dimSys];//stores f(x)
	double* xp = new double[_dimSys];//stores x temporarily
	for (int i=0;i<_dimSys;i++){
		if (_useDomainScaling){
			xp[i]=x(i)/_yScale[i];
		}else{
			xp[i]=x(i);
		}
	}

	_algLoop->setReal(xp);
	_algLoop->evaluate();
	_algLoop->getRHS(rhs);

	if (_generateoutput) {
		std::cout << "we are at position x=(";
		for (int i=0;i<_dimSys;i++){
			std::cout << x(i) << " ";
		}
		std::cout << ")" << std::endl;
		std::cout << std::endl;

		std::cout << "the right hand side is given by (";
		for (int i=0;i<_dimSys;i++){
			std::cout << rhs[i] << " ";
		}
		std::cout << ")" << std::endl;
		std::cout << std::endl;
	}

	for (int i=0;i<_dimSys;i++){

		if (_useFunctionValueScaling){
			f(i)=rhs[i]/_fScale[i];
		}else{
			f(i)=rhs[i];
		}


	}

	delete [] rhs;
	delete [] xp;
	return true;
}

bool NoxLapackInterface::computeJacobian(NOX::LAPACK::Matrix<double>& J, const NOX::LAPACK::Vector & x){
	//setting the forward difference parameters. We divide by the denominator alpha*|x_i|+beta in the computation of the difference quotient. It is similar to the Finite Difference implementation by Nox, which can be found under https://trilinos.org/docs/dev/packages/nox/doc/html/classNOX_1_1Epetra_1_1FiniteDifference.html
	double alpha=1.0e-11;
	double beta=1.0e-9;
	double* f1 = new double[_dimSys];//f(x+(alpha*|x_i|+beta)*e_i)
	double* f2 = new double[_dimSys];//f(x)
	double* xplushei = new double[_dimSys];//x+(alpha*|x_i|+beta)*e_i

	for (int i=0;i<_dimSys;i++){
		if (_useDomainScaling){
			xplushei[i]=x(i)/_yScale[i];
		}else{
			xplushei[i]=x(i);
		}
	}
	_algLoop->setReal(xplushei);
	_algLoop->evaluate();
	_algLoop->getRHS(f2);

	if (_generateoutput) {
		std::cout << "we are at position x=(";
		for (int i=0;i<_dimSys;i++){
			std::cout << x(i) << " ";
		}
		std::cout << ")" << std::endl;
		std::cout << std::endl;

		std::cout << "the Jacobian is given by " << std::endl;
	}

	for (int i=0;i<_dimSys;i++){
		//adding the denominator of the difference quotient

		if (_useDomainScaling){
			//variant 1
			//xplushei[i]+=(alpha*std::abs(xplushei[i])+beta)/_yScale[i];
			//variant 2
			xplushei[i]+=(alpha*std::abs(xplushei[i]*_yScale[i])+beta)/_yScale[i];
		}else{
			xplushei[i]+=alpha*std::abs(xplushei[i])+beta;
		}

		_algLoop->setReal(xplushei);
		_algLoop->evaluate();
		_algLoop->getRHS(f1);

		for (int j=0;j<_dimSys;j++){
			if (_useDomainScaling){
				//variant 1
				//J(j,i) = _yScale[i]*(f1[j]-f2[j])/(xplushei[i]-x(i)/_yScale[i]);//=\partial_i f_j
				//variant 2
				//J(j,i) = (f1[j]-f2[j])/(xplushei[i]-x(i)/_yScale[i]);//=\partial_i f_j
				//variant 3
				if (_useFunctionValueScaling){
					J(j,i) = (f1[j]-f2[j])/(_fScale[j]*(_yScale[i]*xplushei[i]-x(i)));//=\partial_i f_j
				}else{
					J(j,i) = (f1[j]-f2[j])/(_yScale[i]*xplushei[i]-x(i));//=\partial_i f_j
				}
			}else{
				if (_useFunctionValueScaling){
					J(j,i) = (f1[j]-f2[j])/(_fScale[j]*(xplushei[i]-x(i)));//=\partial_i f_j
				}else{
					J(j,i) = (f1[j]-f2[j])/(xplushei[i]-x(i));//=\partial_i f_j
				}
			}

			if (_generateoutput) std::cout << J(j,i) << " ";
		}
		if (_generateoutput) std::cout << std::endl;

		//reset xplushei
		if (_useDomainScaling){
			xplushei[i]=x(i)/_yScale[i];
		}else{
			xplushei[i]=x(i);
		}
	}

	if (_generateoutput) std::cout << std::endl;

	if (_generateoutput) std::cout << "done computing Jacobian" << std::endl;

	_algLoop->setReal(xplushei);
	_algLoop->evaluate();

	delete [] f1;
	delete [] f2;
	delete [] xplushei;
	return true;
}
