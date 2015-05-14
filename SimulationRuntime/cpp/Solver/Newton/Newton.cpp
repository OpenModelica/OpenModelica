#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
#include <Solver/Newton/Newton.h>

#include <Core/Math/ILapack.h>        // needed for solution of linear system with Lapack
#include <Core/Math/Constants.h>        // definitializeion of constants like uround


Newton::Newton(IAlgLoop* algLoop, INonLinSolverSettings* settings)
: _algLoop            (algLoop)
, _newtonSettings    ((INonLinSolverSettings*)settings)
, _y                (NULL)
, _yHelp            (NULL)
, _f                (NULL)
, _fHelp            (NULL)
,_iHelp        (NULL)
, _jac                (NULL)
, _dimSys            (0)
, _firstCall        (true)
, _iterationStatus    (CONTINUE)
{
}

Newton::~Newton()
{
    if(_y)         delete []    _y;
    if(_yHelp)    delete []    _yHelp;
    if(_f)        delete []    _f;
    if(_fHelp)    delete []    _fHelp;
  if(_iHelp)    delete []    _iHelp;
    if(_jac)    delete []    _jac;
}

void Newton::initialize()
{
    _firstCall = false;

    //(Re-) initializeialization of algebraic loop
    _algLoop->initialize();

    // Dimension of the system (number of variables)
    int
        dimDouble    = _algLoop->getDimReal(),
        dimInt        = 0,
        dimBool        = 0;

    // Check system dimension
    if (dimDouble != _dimSys)
    {
        _dimSys = dimDouble;

        if(_dimSys > 0)
        {
            // initializeialization of vector of unknowns
            if(_y)         delete []    _y;
            if(_f)        delete []    _f;
            if(_yHelp)    delete []    _yHelp;
            if(_fHelp)    delete []    _fHelp;
      if(_iHelp)    delete []    _iHelp;
            if(_jac)    delete []    _jac;

            _y            = new double[_dimSys];
            _f            = new double[_dimSys];
            _yHelp        = new double[_dimSys];
            _fHelp        = new double[_dimSys];
      _iHelp       = new long int[_dimSys];
            _jac        = new double[_dimSys*_dimSys];

            _algLoop->getReal(_y);
            memset(_f,0,_dimSys*sizeof(double));
            memset(_yHelp,0,_dimSys*sizeof(double));
            memset(_fHelp,0,_dimSys*sizeof(double));
            memset(_jac,0,_dimSys*_dimSys*sizeof(double));
        }
        else
        {
            _iterationStatus = SOLVERERROR;
        }
    }


}

void Newton::solve()
{
    long int
        dimRHS    = 1,                    // Dimension of right hand side of linear system (=b)
        irtrn    = 0;                    // Retrun-flag of Fortran code

    int
        totStps    = 0;                    // Total number of steps

    // If initialize() was not called yet
    if (_firstCall)
        initialize();

    // Get initializeial values from system
    _algLoop->getReal(_y);
    //_algLoop->evaluate(command);
    _algLoop->getRHS(_f);


    // Reset status flag
    _iterationStatus = CONTINUE;

    while(_iterationStatus == CONTINUE)
    {
        _iterationStatus = DONE;
        // Check stopping criterion
        calcFunction(_y,_f);
        if(totStps)
        {
            for(int i=0; i<_dimSys; ++i)
            {
                if(fabs(_f[i]) > _newtonSettings->getAtol() +_newtonSettings->getRtol() * ( fabs(_f[i])))
                {
                    _iterationStatus = CONTINUE;
                    break;
                }
            }
        }
        else
            _iterationStatus = CONTINUE;

        // New right hand side
  //calcFunction(_y,_f);

        if(_iterationStatus == CONTINUE)
        {
            if(totStps < _newtonSettings->getNewtMax())
            {
                // Determination of Jacobian (Fortran-format)
                if(_algLoop->isLinear())
                {
                    //calcFunction(_yHelp,_fHelp);
                    _algLoop->getSystemMatrix(_jac);
                    dgesv_(&_dimSys,&dimRHS,_jac,&_dimSys,_iHelp,_f,&_dimSys,&irtrn);
                    memcpy(_y,_f,_dimSys*sizeof(double));
                    _algLoop->setReal(_y);
                    _iterationStatus = DONE;
                    break;

                }
                else
                {
                    calcJacobian();
                }
                // Solve linear System
                dgesv_(&_dimSys,&dimRHS,_jac,&_dimSys,_iHelp,_f,&_dimSys,&irtrn);

                if(irtrn!=0)
                {
                    // TODO: Throw an error message here.
                    _iterationStatus = SOLVERERROR;
                    break;
                }

                // Increase counter
                ++ totStps;

                // New solution
                for(int i=0; i<_dimSys; ++i)
                    _y[i] -= _newtonSettings->getDelta() * _f[i];

            }
            else
                _iterationStatus = SOLVERERROR;
        }
    }
}

IAlgLoopSolver::ITERATIONSTATUS Newton::getIterationStatus()
{
    return _iterationStatus;
}


void Newton::calcFunction(const double *y, double *residual)
{
    _algLoop->setReal(y);
    _algLoop->evaluate();
    _algLoop->getRHS(residual);
}

void Newton::stepCompleted(double time)
{

}



void Newton::calcJacobian()
{
    for(int j=0; j<_dimSys; ++j)
    {
        // Reset variables for every column
        memcpy(_yHelp,_y,_dimSys*sizeof(double));
        double stepsize=1.e-6;//+(1.e-6*_yHelp[j]);


        // Finitializee difference
        _yHelp[j] += stepsize;

        calcFunction(_yHelp,_fHelp);

        // Build Jacobian in Fortran format
        for(int i=0; i<_dimSys; ++i)
            _jac[i+j*_dimSys] = (_fHelp[i] - _f[i]) / stepsize;

        _yHelp[j] -=stepsize;
    }
}


