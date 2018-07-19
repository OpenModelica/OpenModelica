#include <Core/ModelicaDefine.h>
/** @addtogroup solverCvode
*
*  @{
*/
#include <Core/Modelica.h>
#include <Solver/Hybrj/Hybrj.h>

#include <Core/Math/ILapack.h>        // needed for solution of linear system with Lapack
#include <Core/Math/Constants.h>        // definition of constants like uround
#include <algorithm>    // std::max

Hybrj::Hybrj(INonLinSolverSettings* settings,shared_ptr<INonLinearAlgLoop> algLoop)
    :AlgLoopSolverDefaultImplementation()
	, _algLoop            (algLoop)
	, _newtonSettings    ((INonLinSolverSettings*)settings)
	, _x                (NULL)
	, _xHelp            (NULL)
	, _f                (NULL)
	, _fHelp            (NULL)
	, _iHelp            (NULL)
	, _jac                (NULL)
	,_diag(NULL)
	,_r(NULL)
	,_qtf(NULL)
	,_wa1(NULL)
	,_wa2(NULL)
	,_wa3(NULL)
	,_wa4(NULL)

	, _firstCall(true)
	, _iterationStatus(CONTINUE)
	,_x0(NULL)
	,_x1(NULL)
	,_x2(NULL)
	,_x_ex(NULL)
	,_x_nom(NULL)
	,_x_scale(NULL)
	,_x_restart(NULL)
	,_initial_factor(100)
	,_usescale(false)
{
	_data = ((void*)this);
	if (_algLoop)
	{
		AlgLoopSolverDefaultImplementation::initialize(_algLoop->getDimZeroFunc(),_algLoop->getDimReal());
	}
	else
	{
		throw ModelicaSimulationError(ALGLOOP_SOLVER, "solve for single instance is not supported");
	}
}

Hybrj::~Hybrj()
{
	if(_x)         delete []    _x;
	if(_xHelp)    delete []    _xHelp;
	if(_f)        delete []    _f;
	if(_fHelp)    delete []    _fHelp;
	if(_iHelp)    delete []    _iHelp;
	if(_jac)    delete []    _jac;
	if( _diag ) delete[] _diag;
	if(_r) delete[] _r;
	if(_qtf) delete[] _qtf;
	if(_wa1)delete[]  _wa1;
	if(_wa2)delete[]  _wa2;
	if(_wa3)delete[]  _wa3;
	if( _wa4)delete[] _wa4;
	if(_x0) delete[] _x0;
	if(_x1) delete[] _x1;
	if(_x2) delete[] _x2;
	if(_x_nom) delete[] _x_nom;
	if(_x_scale) delete[] _x_scale;
	if(_x_ex) delete[] _x_ex;
}

void Hybrj::stepCompleted(double time)
{
	saveVars(time);
	extrapolateVars();
}

void Hybrj::initialize()
{
	_firstCall = false;

	//(Re-) Initialization of algebraic loop
	 if(_algLoop)
      _algLoop->initialize();
    else
	  throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");

	// Dimension of the system (number of variables)
	 _dimSys    = _algLoop->getDimReal();

		if(_dimSys > 0)
		{
			// Initialization of vector of unknowns
			if(_x)         delete []    _x;
			if(_f)        delete []    _f;
			if(_xHelp)    delete []    _xHelp;
			if(_fHelp)    delete []    _fHelp;
			if(_iHelp)    delete []    _iHelp;
			if(_jac)    delete []    _jac;
			if(_x0) delete[] _x0;
			if(_x1) delete[] _x1;
			if(_x2) delete[] _x2;
			if(_x_nom) delete[] _x_nom;
			if(_x_scale) delete[] _x_scale;
			if(_x_ex) delete[] _x_ex;
			if(_x_restart) delete[] _x_restart;
			_x            = new double[_dimSys];
			_f            = new double[_dimSys];
			_xHelp        = new double[_dimSys];
			_fHelp        = new double[_dimSys];
			_iHelp        = new long int[_dimSys];
			_jac        = new double[_dimSys*_dimSys];
			_x0 = new double[_dimSys];
			_x1 = new double[_dimSys];
			_x2 = new double[_dimSys];
			_x_nom = new double[_dimSys];
			_x_scale = new double[_dimSys];
			_x_ex = new double[_dimSys];
			_x_restart = new double[_dimSys];
			//ToDo: nominal variablen abfragen
			_algLoop->getReal(_x0);
			_algLoop->getReal(_x1);
			_algLoop->getReal(_x2);
			_algLoop->getReal(_x);
			_algLoop->getReal(_x_ex);
			_algLoop->getReal(_x_restart);
			_algLoop->getNominalReal(_x_nom);
			std::fill_n(_f,_dimSys,0.0);
			std::fill_n(_x_scale,_dimSys,1.0);

			std::fill_n(_xHelp,_dimSys,0.0);
			std::fill_n(_fHelp,_dimSys,0.0);
			std::fill_n(_jac,_dimSys*_dimSys,0.0);


			_lr = (_dimSys*(_dimSys + 1)) / 2;
			_ldfjac= _dimSys;
			_xtol = 1e-12;
			_maxfev = _dimSys*10000;
			_factor = 100;
			_nprint=-1;
			_mode=1;
			if( _diag ) delete[] _diag;
			if(_r) delete[] _r;
			if(_qtf) delete[] _qtf;
			if(_wa1)delete[]  _wa1;
			if(_wa2)delete[]  _wa2;
			if(_wa3)delete[]  _wa3;
			if( _wa4)delete[] _wa4;
			_diag = new double[_dimSys];
			_r= new double[(_dimSys*(_dimSys + 1)) / 2];
			_qtf= new double[_dimSys];
			_wa1= new double[_dimSys];
			_wa2= new double[_dimSys];
			_wa3= new double[_dimSys];
			_wa4= new double[_dimSys];



		}


}

void Hybrj::solve(shared_ptr<INonLinearAlgLoop> algLoop,bool first_solve)
{
	throw ModelicaSimulationError(ALGLOOP_SOLVER, "solve for single instance is not supported");
}

bool* Hybrj::getConditionsWorkArray()
{
	return AlgLoopSolverDefaultImplementation::getConditionsWorkArray();

}
bool* Hybrj::getConditions2WorkArray()
{

	return AlgLoopSolverDefaultImplementation::getConditions2WorkArray();
 }


 double* Hybrj::getVariableWorkArray()
 {

	return AlgLoopSolverDefaultImplementation::getVariableWorkArray();

 }
void Hybrj::solve()
{

 	// If initialize() was not called yet
    if (_firstCall)
		initialize();



	bool restart =true;
	int iter = 0;
	int iter_retry = 0;
	int iter_retry2 = 0;
	int info;
	_iterationStatus = CONTINUE;
	bool isConsistent = true;
	double local_tol = 1e-12;
	int dimSys = _dimSys;
	while(_iterationStatus == CONTINUE)
	{
		/* Scaling x vector */
		if(_usescale)
			std::transform (_x, _x+dimSys, _x_scale,_x, std::divides<double>());
		__minpack_func__(hybrj)((minpack_funcder_nn)fcn, &dimSys, _x, _f, _jac, &_ldfjac, &_xtol, &_maxfev, _diag,
			&_mode, &_factor, &_nprint, &info, &_nfev, &_njev, _r, &_lr, _qtf,
			_wa1, _wa2, _wa3, _wa4,_data);
		//check if  the conditions of the system has changed
		if(isConsistent)
		{
			isConsistent = _algLoop->isConsistent();
			if(!isConsistent)
				_algLoop->getReal(_x_restart);
		}
		/* re-scaling x vector */
		if(_usescale)
			std::transform (_x, _x+dimSys, _x_scale, _x, std::multiplies<double>());


		_fnorm = __minpack_func__(enorm)(&dimSys, _f);
		/*solution was found*/
		if(info==1  || (_fnorm <= local_tol))
			_iterationStatus = DONE;

		/* first try to decrease factor */
		else if((info==4 || info == 5) && iter<3)
		{
			_algLoop->getReal(_x);
			_iterationStatus = CONTINUE;
			_factor/=10;
			iter++;
			// cout << " - iteration making no progress:\t decreasing initial step bound to "<< _factor << std::endl ;
		}
		/* try to vary the initial values */
		else if((info==4 || info == 5) && iter<4)
		{
			_factor=_initial_factor;
			for(int i = 0; i < dimSys; i++)
				_x[i] += _x_nom[i] * 0.1;
			iter++;
			//  cout <<"iteration making no progress:\t vary solution point by 1%%"<< std::endl ;
		}
		/* try old values as x-Scaling factors */
		else if((info==4 || info == 5) && iter<5)
		{
			for(int i = 0; i < dimSys; i++)
				_x_scale[i] = std::max(_x0[i], _x_nom[i]);
			iter++;
			//cout << "iteration making no progress:\t try without scaling at all."<< std::endl ;

		}
		/* try to disable x-Scaling */
		else if((info==4 || info == 5) && iter<6)
		{
			_usescale = false;
			memcpy(_x_scale, _x_nom,dimSys*(sizeof(double)));
			iter++;
			// cout << "iteration making no progress:\t try without scaling at all."<< std::endl ;
		}
		/*try with old values (instead of extrapolating )*/
		else if((info==4 || info == 5) && iter_retry<1)
		{
			memcpy(_x, _x0, dimSys*(sizeof(double)));
			iter=0;
			iter_retry++;
			// cout << "- iteration making no progress:\t use old values instead extrapolated."<< std::endl ;
		}
		/* try to vary the initial values */
		else if((info==4 || info == 5) && iter_retry<2)
		{
			memcpy(_x, _x_ex, dimSys*(sizeof(double)));
			for(int i = 0; i < dimSys; i++)
			{
				_x[i] *= 1.01;
			}
			iter = 0;
			iter_retry++;
			//cout << "- iteration making no progress:\t vary initial point by adding 1%%."<< std::endl ;

		}
		/* try to vary the initial values */
		else if((info==4 || info == 5) && iter_retry<3)
		{
			memcpy(_x, _x_ex, dimSys*(sizeof(double)));
			for(int i = 0; i < dimSys; i++)
			{
				_x[i] *= 0.99;
			}
			iter = 0;
			iter_retry++;
			//cout << "-  iteration making no progress:\t vary initial point by -1%%."<< std::endl ;

		}
		/* try to vary the initial values */
		else if((info==4 || info == 5) && iter_retry<4)
		{
			memcpy(_x, _x_nom, dimSys*(sizeof(double)));
			iter = 0;
			iter_retry++;
			// cout << "-   iteration making no progress:\t try scaling factor as initial point."<< std::endl ;
		}
		/* try own scaling factors */
		else if((info==4 || info == 5) && iter_retry<5)
		{
			memcpy(_x, _x_ex, dimSys*(sizeof(double)));
			for(int i = 0; i < dimSys; i++)
			{
				_diag[i] = fabs(_x_scale[i]);
				if(_diag[i] <= 0)
					_diag[i] = 1e-16;
			}
			_mode = 2;
			iter = 0;
			iter_retry++;
			// cout << "-   iteration making no progress:\t try with own scaling factors."<< std::endl ;
		}
		/* try without internal scaling */
		else if((info==4 || info == 5) && iter_retry2<2)
		{
			memcpy(_x, _x_ex, dimSys*(sizeof(double)));
			for(int i = 0; i < dimSys; i++)
			{
				_diag[i] = 1.0;
			}
			_mode=2;
			_usescale=true;
			iter = 0;
			iter_retry=0;
			iter_retry2++;
			// cout << "-  - iteration making no progress:\t disable solver internal scaling."<< std::endl ;
		}
		/* try to reduce the tolerance a bit */
		else if((info==4 || info == 5) && iter_retry2<6)
		{
			memcpy(_x, _x_ex, dimSys*(sizeof(double)));
			_xtol*=10;
			_factor = _initial_factor;
			iter = 0;
			iter_retry=0;
			iter_retry2++;
			_mode=1;
			//  cout << " - iteration making no progress:\t reduce the tolerance slightly to %e."<< std::endl ;
		}
		else
			_iterationStatus = SOLVERERROR;

	}
	if(_iterationStatus == SOLVERERROR)
	{
		if(!isConsistent)
		{
			_algLoop->setReal(_x_restart);
		}
		else
			throw ModelicaSimulationError(ALGLOOP_SOLVER,"Unsuccessful termination of HYBRJ, iteration is making no progress ");


	}

	/* if(iter>4)
	{
	std::cout << " iterations: " << iter << " , " <<iter_retry << " , " << iter_retry2 <<  " norm: " <<_fnorm << std::endl;
	}*/
	_factor=100;
	_mode=1;


}

INonLinearAlgLoopSolver::ITERATIONSTATUS Hybrj::getIterationStatus()
{
	return _iterationStatus;
}


void Hybrj::calcFunction(const double *y, double *residual)
{
	if(!_algLoop)
      throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
	_algLoop->setReal(y);
	_algLoop->evaluate();
	_algLoop->getRHS(residual);
}

void  Hybrj::saveVars(double time)
{

	 if(!_algLoop)
      throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
	_algLoop->getReal(_x);
	memcpy(_x2,_x1,_dimSys*sizeof(double));
	memcpy(_x1,_x0,_dimSys*sizeof(double));
	memcpy(_x0,_x,_dimSys*sizeof(double));
	_t2=_t1;
	_t1=_t0;
	_t0= time;
}
void  Hybrj::extrapolateVars()
{
    if(!_algLoop)
      throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
	if (_t1 == _t2)
	{

		memcpy(_x_ex, _x1, _dimSys*(sizeof(double)));
	}
	else
	{
		for(int i = 0; i < _dimSys; i++)
			_x_ex[i]= _x2[i] + (_t0 -_t2) / (_t1-_t2)*(_x1[i]-_x2[i]);
	}
}

void Hybrj::calcJacobian(double *fjac)
{
	if(!_algLoop)
      throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
	for(int j=0; j<_dimSys; ++j)
	{
		// Reset variables for every column
		memcpy(_xHelp,_x,_dimSys*sizeof(double));

		// Finite difference
		double delta =sqrt(UROUND*std::max(1e-5,std::abs(_x[j])));
		_xHelp[j] +=delta;

		calcFunction(_xHelp,_fHelp);

		// Build Jacobian in Fortran format
		for(int i=0; i<_dimSys; ++i)
			fjac[i+j*_dimSys] = (_fHelp[i] - _f[i]) /delta;
	}

}

void Hybrj::fcn(const int *n, const double *x, double *fvec, double *fjac, const int *ldfjac, int *iflag, void* userdata)
{

	if(*iflag == 1)
	{
		((Hybrj*)userdata)->calcFunction(x,fvec);
	}
	else if(*iflag == 2)
	{
		((Hybrj*)userdata)->calcJacobian(fjac);

	}

}
void Hybrj::restoreOldValues()
{

}

void Hybrj::restoreNewValues()
{

}

/** @} */ // end of solverHybrj
