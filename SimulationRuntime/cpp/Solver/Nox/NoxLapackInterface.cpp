#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Solver/Nox/NoxLapackInterface.h>

//! Constructor


NoxLapackInterface::NoxLapackInterface(INonLinearAlgLoop *algLoop, int numberofhomotopytries)//second argument unnecessary. Just initialize _lambda to 1.0
	:_algLoop(algLoop)
	,_generateoutput(false)
	,_useDomainScaling(false)
	,_useFunctionValueScaling(true)
	,_yScale(NULL)
	,_fScale(NULL)
	,_lambda(1.0)//set to 1.0 in case we do not use homotopy.
	,_computedinitialguess(false)
	,_numberofhomotopytries(numberofhomotopytries)
	,_evaluatedJacobianAtInitialGuess(false)
{
	_dimSys = _algLoop->getDimReal();
	_initialGuess = Teuchos::rcp(new NOX::LAPACK::Vector(_dimSys));
	_J = Teuchos::rcp(new NOX::LAPACK::Matrix<double>(_dimSys,_dimSys));

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
	//no need to delete the alglooppointer, since the algloop passed is passed as a shared pointer.
}

const NOX::LAPACK::Vector& NoxLapackInterface::getInitialGuess()
{
	checkdimensionof(*_initialGuess);

	if (!_computedinitialguess){
		double* x = new double[_dimSys];


		// alternative calculation of huge values.
		// _algLoop->getRHS(_hugeabsolutevalues);
		// for(int i=0;i<_dimSys;i++){
			// _hugeabsolutevalues[i]= ((_hugeabsolutevalues[i]==0.0) ? 1000000.0 : (1000000.0*std::abs(_hugeabsolutevalues[i])));
		// }
		// with call to
		// for(int i=0;i<_dimSys;i++){
			// rhs[i] *= ((rhs[i]>0.0) ? _hugeabsolutevalues[i] : -_hugeabsolutevalues[i]);
		// }



		_algLoop->getReal(x);
		_algLoop->evaluate();


		// //variables for error handling when dividing by zero at evaluation of initial guess
		// bool foundvalidinitialguess=false;
		// int variedcoords=0;
		// bool oneortenpercent=true;//true: 1%, false: 10%
		// bool didnotcopyoriginalinitialguess=true;
		// double *xtemp = new double[_dimSys];

		// _algLoop->getReal(x);

		// while (!foundvalidinitialguess){
			// try{
				// _algLoop->evaluate();
				// foundvalidinitialguess=true;
			// }
			// catch(const std::exception &e){
				// if(variedcoords==_dimSys){
					// delete [] x;
					// delete [] xtemp;
					// std::cout << "no coordinates left that can be changed" << std::endl;
					// throw;
				// }

				// if (didnotcopyoriginalinitialguess){
					// _algLoop->getReal(xtemp);
					// didnotcopyoriginalinitialguess=false;
				// }
				// std::string divbyzero = "Division by zero";
				// std::string errorstring(e.what());
				// //we only do the error handling by variation of initial guess in case of division by zero at evaluation of initial guess
				// if(errorstring.find(divbyzero)!=std::string::npos){
					// std::cout << errorstring << std::endl;
					// std::cout << "Trying to resolve issue by varying initial guess!" << std::endl;
					// //resetting x
					// memcpy(x,xtemp,_dimSys*sizeof(double));
					// if(oneortenpercent){
						// std::cout << "Varying initial guess by 1%:" << std::endl;
						// if(x[variedcoords]!=0.0){
							// x[variedcoords]+=0.01*x[variedcoords];
						// }else{
							// x[variedcoords]=0.01;
						// }
						// oneortenpercent = false;
					// }else{
						// std::cout << "Varying initial guess by 10%:" << std::endl;
						// if(x[variedcoords]!=0.0){
							// x[variedcoords]+=0.1*x[variedcoords];
						// }else{
							// x[variedcoords]=0.1;
						// }
						// oneortenpercent = true;
						// variedcoords++;
					// }
					// _algLoop->setReal(x);
				// }else{
					// delete [] x;
					// delete [] xtemp;
					// throw;
				// }
			// }
		// }

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

		/*
		if ((_algLoop->getEquationIndex()==856) && (_algLoop->getSimTime()<0.1)){
			(*_initialGuess)(0)=0.3084;
			(*_initialGuess)(1)=0.2592;
			(*_initialGuess)(2)=0.0931;
			(*_initialGuess)(3)=1.5740;
			(*_initialGuess)(4)=0.1787;
			(*_initialGuess)(5)=-0.1523;
			(*_initialGuess)(6)=6.0283;
		}*/

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
		_computedinitialguess=true;
	}
	return *_initialGuess;
};

bool NoxLapackInterface::computeActualF(NOX::LAPACK::Vector& f, const NOX::LAPACK::Vector &x){

	checkdimensionof(x);

	double* rhs = new double[_dimSys];//stores f(x)
	double* xp = new double[_dimSys];//stores x temporarily
	for (int i=0;i<_dimSys;i++){
		if (_useDomainScaling){
			xp[i]=x(i)/_yScale[i];
		}else{
			xp[i]=x(i);
		}
	}

	if (_generateoutput){
		std::cout << "we are at position x=(";
		for (int i=0;i<_dimSys;i++){
			std::cout << std::setprecision (std::numeric_limits<double>::digits10 + 8) << x(i) << " ";
		}
		std::cout << ")" << std::endl;
		std::cout << std::endl;
	}

	_algLoop->setReal(xp);
	_algLoop->getRHS(rhs);
	try{
		_algLoop->evaluate();
		_algLoop->getRHS(rhs);
	}catch(const std::exception &ex)
	{
		if (_generateoutput) std::cout << "calculating right hand side failed with error message:" << std::endl << ex.what() << std::endl;
		//the following should be done when some to be implemented flag like "continue if function evaluation fails" is activated.
		if (_generateoutput) std::cout << "setting high values into right hand side:" << std::endl << "(";
		for(int i=0;i<_dimSys;i++){
			if (rhs[i]==0.0){
				rhs[i]=1000000.0;
			}else{
				rhs[i]=1000000.0*rhs[i];
			}
			if (_generateoutput) std::cout << rhs[i] << " ";
		}
		if (_generateoutput) std::cout << ")" << std::endl;
	}


	if (_generateoutput){
		std::cout << "the right hand side is given by (";
		for (int i=0;i<_dimSys;i++){
			std::cout << rhs[i] << " ";
		}
		std::cout << ")" << std::endl;
		std::cout << std::endl;
	}


	if (_generateoutput){
		std::cout << "the right hand side seen by NOX is given by (";
	}
	for (int i=0;i<_dimSys;i++){

		if (_useFunctionValueScaling){
			f(i)=rhs[i]/_fScale[i];
		}else{
			f(i)=rhs[i];
		}
		if (f(i)>=std::numeric_limits<double>::max()) f(i)=1.0e6;
		if (f(i)<=-std::numeric_limits<double>::max()) f(i)=-1.0e6;
		if (!(f(i)==f(i))) f(i)=1.0e6;
		if (_generateoutput) std::cout << f(i) << " ";
	}
	if (_generateoutput){
		std::cout << ")" << std::endl;
		std::cout << std::endl;
	}
	delete [] rhs;
	delete [] xp;
	return true;
}

bool NoxLapackInterface::computeJacobian(NOX::LAPACK::Matrix<double>& J, const NOX::LAPACK::Vector & x){

	checkdimensionof(x);

	//we have to replace the original computeJacobian function in case of homotopy. This also reduces maintainance efforts, since this function does not depend on the boolean variable _useFunctionValueScaling anymore.
	//setting the forward difference parameters. We divide by the denominator alpha*|x_i|+beta in the computation of the difference quotient. It is similar to the Finite Difference implementation by Nox, which can be found under https://trilinos.org/docs/dev/packages/nox/doc/html/classNOX_1_1Epetra_1_1FiniteDifference.html
	double alpha=1.0e-11;
	double beta=1.0e-9;
	NOX::LAPACK::Vector f1(_dimSys);//f(x+(alpha*|x_i|+beta)*e_i)
	NOX::LAPACK::Vector f2(_dimSys);//f(x)
	NOX::LAPACK::Vector xplushei(x);//x+(alpha*|x_i|+beta)*e_i

	computeF(f2,x);

	if (_generateoutput){
		std::cout << "we are at simtime " << _algLoop->getSimTime() << " and at position x=(";
		for (int i=0;i<_dimSys;i++){
			std::cout << x(i) << " ";
		}
		std::cout << ")" << std::endl;
		std::cout << std::endl;
	}

	for (int i=0;i<_dimSys;i++){
		//adding the denominator of the difference quotient
		xplushei(i)+=alpha*std::abs(xplushei(i))+beta;
		computeF(f1,xplushei);
		for (int j=0;j<_dimSys;j++){
			J(j,i) = (f1(j)-f2(j))/(xplushei(i)-x(i));//=\partial_i f_j
		}
		xplushei(i)=x(i);
	}


	if (_generateoutput){
		std::cout << "the Jacobian is given by " << std::endl;
		for (int i=0;i<_dimSys;i++){
			for (int j=0;j<_dimSys;j++){
				std::cout << J(j,i) << " ";
			}
			std::cout << std::endl;
		}
		std::cout << std::endl << "done computing Jacobian" << std::endl;
	}

	return true;



	/* //setting the forward difference parameters. We divide by the denominator alpha*|x_i|+beta in the computation of the difference quotient. It is similar to the Finite Difference implementation by Nox, which can be found under https://trilinos.org/docs/dev/packages/nox/doc/html/classNOX_1_1Epetra_1_1FiniteDifference.html
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
	return true; */
}

void NoxLapackInterface::setParams(const LOCA::ParameterVector& p) {
	_lambda = p.getValue("lambda");
}


void NoxLapackInterface::printSolution(const NOX::LAPACK::Vector &x, const double conParam)
{
	if(_generateoutput){
		std::cout << "At parameter value: " << std::setprecision(8) << conParam << " the solution vector (norm=" << x.norm() << ") is" << std::endl;
		for (int i=0; i<_dimSys; i++) std::cout << " " << x(i);
		std::cout << std::endl;
		std::cout << "Simtime: " << _algLoop->getSimTime() << std::endl;
	}
}

//replace this function once it is implemented in Trilinos
NOX::LAPACK::Vector NoxLapackInterface::applyMatrixtoVector(const NOX::LAPACK::Matrix<double> &A, const NOX::LAPACK::Vector &x){
	NOX::LAPACK::Vector result(A.numRows());
	//check whether the dimensions match
	if (A.numCols()!=x.length())
		throw ModelicaSimulationError(ALGLOOP_SOLVER, "Dimension mismatch during computing matrix-vector-product!");
	for(int i=0;i<A.numRows();i++){
		for(int j=0;j<A.numCols();j++){
			result(i)+=A(i,j)*x(j);
		}
	}
	return result;
}

bool NoxLapackInterface::computeSimplifiedF(NOX::LAPACK::Vector& f, const NOX::LAPACK::Vector &x){
	NOX::LAPACK::Vector zeroandtempvec(_dimSys);
	double templambda=_lambda;//storing _lambda temporarily.

	checkdimensionof(x);

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
			if (_generateoutput) std::cout << "We are at AlgLoop " << _algLoop->getEquationIndex() << " and simtime " << _algLoop->getSimTime() << std::endl;
			throw ModelicaSimulationError(ALGLOOP_SOLVER,"Running out of homotopy methods!");
			break;
	}
	return true;
}

bool NoxLapackInterface::computeF(NOX::LAPACK::Vector& f, const NOX::LAPACK::Vector &x){
	NOX::LAPACK::Vector g(_dimSys);
	NOX::LAPACK::Vector h(_dimSys);

	computeActualF(g,x);
	computeSimplifiedF(h,x);

	//f(x)=lambda*g(x)+(1-lambda)*h(x)
	f.update(_lambda, g, 1.0-_lambda, h);
	return true;
}

void NoxLapackInterface::checkdimensionof(const NOX::LAPACK::Vector &x){
	if (_dimSys!=x.length()) throw ModelicaSimulationError(ALGLOOP_SOLVER,"Dimension of solution vector is wrong in method of NoxLapackInterface!");
}
