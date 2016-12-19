#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Solver/Nox/NoxLapackInterface.h>

//! Constructor


NoxLapackInterface::NoxLapackInterface(INonLinearAlgLoop *algLoop)
	:_algLoop(algLoop)
	,_generateoutput(false)
	,_useScale(true)
	,_yScale(NULL)
{
	_dimSys = _algLoop->getDimReal();
	_initialGuess = Teuchos::rcp(new NOX::LAPACK::Vector(_dimSys));

	double* x = new double[_dimSys];
	_algLoop->getReal(x);

	for(int i=0;i<_dimSys;i++){
		(*_initialGuess)(i)=x[i];//I don't need this, NoxLapackInterface::getInitialGuess() is called anyway at the beginning.
	}
	//(*_initialGuess)(0)=-0.305315;
	//(*_initialGuess)(1)=1.40775;

	//std::cout << "Initial guess is given by " << std::endl;
	//for(int i=0;i<_dimSys;i++) std::cout << (*_initialGuess)(i) << " ";
	//std::cout << std::endl;

	delete [] x;
}

//! Destructor
NoxLapackInterface::~NoxLapackInterface()
{
	//nothing to delete, since the algloop passed is passed as a shared pointer.
}

const NOX::LAPACK::Vector& NoxLapackInterface::getInitialGuess()
{
	double* x = new double[_dimSys];
	_algLoop->getReal(x);

	if (_generateoutput) std::cout << "computing initial guess" << std::endl;

	for(int i=0;i<_dimSys;i++){
		(*_initialGuess)(i)=x[i];
	}
	//(*_initialGuess)(0)=-0.305315;
	//(*_initialGuess)(1)=1.40775;

	if (_generateoutput) {
		std::cout << "Initial guess is given by " << std::endl;
		for(int i=0;i<_dimSys;i++) std::cout << (*_initialGuess)(i) << " ";
		std::cout << std::endl;
	}

	delete [] x;
	return *_initialGuess;
};

bool NoxLapackInterface::computeF(NOX::LAPACK::Vector& f, const NOX::LAPACK::Vector &x){
	double* rhs = new double[_dimSys];//stores f(x)
	double* xp = new double[_dimSys];//stores x temporarily
	for (int i=0;i<_dimSys;i++)
		xp[i]=x(i);

	_algLoop->setReal(xp);
	_algLoop->evaluate();
	_algLoop->getRHS(rhs);

	if (_generateoutput) {
		std::cout << "we are at position x=(";
		for (int i=0;i<_dimSys;i++){
			std::cout << xp[i] << " ";
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
		f(i)=rhs[i];
	}

	delete [] rhs;
	delete [] xp;
	return true;
}

bool NoxLapackInterface::computeJacobian(NOX::LAPACK::Matrix<double>& J, const NOX::LAPACK::Vector & x){
	//setting the forward difference parameters. We divide by alpha*|x_i|+beta during computation of the difference quotient. It is similar to the Finite Difference implementation by Nox, which can be found under https://trilinos.org/docs/dev/packages/nox/doc/html/classNOX_1_1Epetra_1_1FiniteDifference.html
	double alpha=1.0e-11;
	double beta=1.0e-9;
	double* f1 = new double[_dimSys];//f(x+(alpha*|x_i|+beta)*e_i)
	double* f2 = new double[_dimSys];//f(x)
	double* xplushei = new double[_dimSys];//x+(alpha*|x_i|+beta)*e_i


	for (int i=0;i<_dimSys;i++)
		xplushei[i]=x(i);
	_algLoop->setReal(xplushei);
	_algLoop->evaluate();
	_algLoop->getRHS(f2);

	if (_generateoutput) {
		std::cout << "we are at position x=(";
		for (int i=0;i<_dimSys;i++){
			std::cout << xplushei[i] << " ";
		}
		std::cout << ")" << std::endl;
		std::cout << std::endl;

		std::cout << "the Jacobian is given by " << std::endl;
	}

	for (int i=0;i<_dimSys;i++){
		xplushei[i]+=alpha*std::abs(xplushei[i])+beta;//I hope that at some point, cmath is included
		_algLoop->setReal(xplushei);
		_algLoop->evaluate();
		_algLoop->getRHS(f1);

		for (int j=0;j<_dimSys;j++){
			J(j,i) = (f1[j]-f2[j])/(xplushei[i]-x(i));//=\partial_i f_j
			if (_generateoutput) std::cout << J(j,i) << " ";
		}
		if (_generateoutput) std::cout << std::endl;
		xplushei[i]=x(i);//reset xplushei
	}

	if (_generateoutput) std::cout << std::endl;

	delete [] f1;
	delete [] f2;
	delete [] xplushei;
	return true;
}
