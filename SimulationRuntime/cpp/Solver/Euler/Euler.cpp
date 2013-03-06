#include "stdafx.h"

#include "Euler.h"
#include "EulerSettings.h"
#include <Math/Functions.h>
#include <Math/Constants.h>
#include <System/ISystemProperties.h>

Euler::Euler(IMixedSystem* system, ISolverSettings* settings)
    : SolverDefaultImplementation(system, settings)
    , _eulerSettings        (dynamic_cast<IEulerSettings*>(_settings))
    , _z                    (NULL)
    , _z0                    (NULL)
    , _z1                    (NULL)
    , _zInit                (NULL)
    , _zLastSucess            (NULL)
    , _zLargeStep            (NULL)
    , _zWrite                (NULL)
    , _denseOutPolynominal    (NULL)
    , _dimSys                (0)
    , _outputStps            (0)
    , _polynominalDegree    (0)
    , _idid                    (0)
    , _hOut                    (0.0)
    , _hZero                (0.0)
    , _hUpLim                (0.0)
    , _hZeroCrossing        (0.0)
    , _hUpLimZeroCrossing    (0.0)
    , _tOut                    (0.0)
    , _tLastZero            (0.0)
    , _tRealInitZero        (0.0)
    , _doubleZeroDistance    (0.0)
    , _doubleZero            (false)
    , _h00                    (0.0)
    , _h01                    (0.0)
    , _h10                    (0.0)
    , _h11                    (0.0)
    , _f0                    (NULL)
    , _f1                    (NULL)
    , _zeroSignIter            (NULL)
    , _Cond                    (NULL)
    ,_zeroInit                (NULL)
{
}

Euler::~Euler()
{
    if(_z)
        delete [] _z;
    if(_z0)
        delete [] _z0;
    if(_z1)
        delete [] _z1;
    if(_zInit)
        delete [] _zInit;
    if(_zLastSucess)
        delete [] _zLastSucess;
    if(_zLargeStep)
        delete [] _zLargeStep;
    if(_zWrite)
        delete [] _zWrite;
    if(_denseOutPolynominal)
        delete [] _denseOutPolynominal;
    if(_zeroSignIter)
        delete [] _zeroSignIter;
    if(_f0)
        delete [] _f0;
    if(_f1)
        delete [] _f1;
    if(_Cond)
        delete [] _Cond;
    if(_zeroInit)
        delete [] _zeroInit;

}


void Euler::init()
{
    // Kennzeichnung, dass assemble() (vor der Integration) aufgerufen wurde
    _idid = 5000;
    ISystemProperties* properties = dynamic_cast<ISystemProperties*>(_system);
    IContinuous* continous_system = dynamic_cast<IContinuous*>(_system);
    //(Re-) Initialization of solver -> call default implementation service
    SolverDefaultImplementation::init();

    // Dimension of the system (number of variables)
    _dimSys    = continous_system->getDimVars();

    // Check system dimension
    if(_dimSys <= 0 || !(properties->isODE()) || (properties->isAlgebraic()) || !(properties->isExplicit()) )
    {
        _idid = -1;
        throw std::invalid_argument("Euler::assemble() error");
    }
    else
    {
        // Allocate state vectors, stages and temporary arrays
        if(_z)                delete [] _z;
        if(_zInit)            delete [] _zInit;
        if(_zLastSucess)    delete [] _zLastSucess;
        if(_zLargeStep)        delete [] _zLargeStep;
        if(_Cond)            delete [] _Cond;
        if(_zWrite)            delete [] _zWrite;
        if(_zeroInit)        delete [] _zeroInit;

        _z                = new double[_dimSys];
        _zInit            = new double[_dimSys];
        _zLastSucess    = new double[_dimSys];
        _zLargeStep        = new double[_dimSys];
        _zWrite            = new double[_dimSys];
        _f0                = new double[_dimSys];
        _f1                = new double[_dimSys];
        _zeroSignIter    = new int[_dimZeroFunc];
        _Cond            = new bool[_dimZeroFunc];
        _zeroInit        = new bool[_dimZeroFunc];

        memset(_z,0,_dimSys*sizeof(double));
        memset(_f0,0,_dimSys*sizeof(double));
        memset(_f1,0,_dimSys*sizeof(double));
        memset(_zInit,0,_dimSys*sizeof(double));
        memset(_zLastSucess,0,_dimSys*sizeof(double));
        memset(_zLargeStep,0,_dimSys*sizeof(double));

        // Arrays für Zustandswerte an den Berechnungsintervallgrenzen

        if(_z0)        delete [] _z0;
        if(_z1)        delete [] _z1;

        _z0 = new double[_dimSys];
        _z1 = new double[_dimSys];

        memset(_z0,0,sizeof(double));
        memset(_z1,0,sizeof(double));

        // Counter initialisieren
        _outputStps    = 0;

        if( _eulerSettings->getDenseOutput())
        {
            // Ausgabeschrittweite
            _hOut        =  dynamic_cast<ISolverSettings*>(_eulerSettings)->getGlobalSettings()->gethOutput();

        }
    }
}

/// Set start t for numerical solution
void Euler::setStartTime(const double& t)
{
    SolverDefaultImplementation::setStartTime(t);
};

/// Set end t for numerical solution
void Euler::setEndTime(const double& t)
{
    SolverDefaultImplementation::setEndTime(t);
};

/// Set the initial step size (needed for reinitialization after external zero search)
void Euler::setInitStepSize(const double& h)
{
    SolverDefaultImplementation::setInitStepSize(h);
};


/// Provides the status of the solver after returning
const IDAESolver::SOLVERSTATUS Euler::getSolverStatus()
{
    return (SolverDefaultImplementation::getSolverStatus());
};
void Euler::solve(const SOLVERCALL command)
{

    if (_eulerSettings && _system)
    {
        IEvent* event_system =  dynamic_cast<IEvent*>(_system);

        // Prepare solver and system for integration
        if (command & IDAESolver::FIRST_CALL)
        {
            init();
            saveInitState();
            _tLastWrite = 0;
        }

        // Causes the solver to read the states from the system in the very first step
        if (command & IDAESolver::RECALL)
            _firstStep = true;

        // Set command for calling writeToFile. Depends wheter solve is called during zero search or ordninary integration
        if (command & IDAESolver::REPEATED_CALL)
            _outputCommand = IMixedSystem::OVERWRITE;
        else if (command & IDAESolver::REGULAR_CALL)
            _outputCommand = IMixedSystem::WRITE;
        else
            _outputCommand = IMixedSystem::UNDEF_OUTPUT;

        // Reset status flag
        _solverStatus = IDAESolver::CONTINUE;

        while ( _solverStatus & IDAESolver::CONTINUE )
        {
            // Limit step size to borders (during zero search, step size may be changed)
            if(!_zeroSearchActive)
                _h = std::max(std::min(_h, dynamic_cast<ISolverSettings*>(_eulerSettings)->getUpperLimit()), dynamic_cast<ISolverSettings*>(_eulerSettings)->getLowerLimit());

            // Zuvor wurde assemble aufgerufen und hat funktioniert => RESET IDID
            if(_idid == 5000)
                _idid = 0;


            // Call solver
            //-------------
            if(_idid == 0)
            {
                // Reset counter
                _accStps = 0;

                // Get initial values from system, write out initial state vector
                solverOutput(_accStps,_tCurrent,_z,_h);

                //Deaktiviert wird nicht mehr benötigt
                // Nullstellen identifizieren, bei denen zu Beginn der Simulation der Zustand nicht entschieden werden kann
                //event_system->giveZeroFunc(_zeroValLastSuccess);
                //event_system->giveConditions(_Cond);
                //for(int i=0;i<_dimZeroFunc;i++)
                //{
                //    _Cond[i] = !_Cond[i];
                //}
                //event_system->setConditions(_Cond);
                /*event_system->giveZeroFunc(_zeroVal);
                for(int i=0;i<_dimZeroFunc;i++)
                {
                    if(_zeroValLastSuccess[i] == _zeroVal[i])
                    {
                        _zeroInit[i] = true;
                    }else
                    {
                        _zeroInit[i] = false;
                    }
                }
                for(int i=0;i<_dimZeroFunc;i++)
                {
                    _Cond[i] = !_Cond[i];
                }
                event_system->setConditions(_Cond);*/

                //

                // Choose integration method
                if (_eulerSettings->getEulerMethod()  == EulerSettings::EULERFORWARD)
                    doEulerForward();
                else if (_eulerSettings->getEulerMethod()  == EulerSettings::EULERBACKWARD)
                    doEulerBackward();
                else
                    doMidpoint();
            }


            // Integration was not sucessfull (=0) or was terminated by the user (=1)
            if(_idid != 0 && _idid !=1)
            {
                _solverStatus = IDAESolver::SOLVERERROR;
            }

            // Stopping criterion (end time reached)
            else if    ( (_tEnd - _tCurrent) <= dynamic_cast<ISolverSettings*>(_eulerSettings)->getEndTimeTol())
                _solverStatus = IDAESolver::DONE;
        }

        _firstCall = false;

        // Termination after last call only (optional)
        if ( (command & IDAESolver::LAST_CALL) || (_solverStatus & IDAESolver::USER_STOP))
        {
        }
    }
    else
    {
        // Invalid system
        _idid = -3;
    }
}



void Euler::doEulerForward()
{
    IEvent* event_system =  dynamic_cast<IEvent*>(_system);
    IMixedSystem* mixed_system =  dynamic_cast<IMixedSystem*>(_system);
    double *k1    = new double[_dimSys];
    double tHelp;


    //while( (_tEnd - _tCurrent) > dynamic_cast<ISolverSettings*>(_eulerSettings)->getEndTimeTol() && _idid == 0)
    while( _idid == 0 && _solverStatus != USER_STOP)
    {

        // Letzten Schritt ggf. anpassen
        if((_tCurrent + _h) > _tEnd)
            _h = (_tEnd - _tCurrent);

        tHelp = _tCurrent + _h;

        // 1. Stufe
        calcFunction(_tCurrent, _z, k1);

        // alten Zustandsvektor zwischenspeichern
        memcpy(_z0,_z,(int)_dimSys*sizeof(double));


        // Berechnung des neuen y
        for(int i = 0; i < _dimSys; ++i)
            _z[i] += _h * k1[i];


        ++ _totStps;
        ++ _accStps;


        memcpy(_z1,_z,_dimSys*sizeof(double));

        solverOutput(_accStps,tHelp,_z,_h);
        doMyZeroSearch();

        if (((_tEnd - _tCurrent) < dynamic_cast<ISolverSettings*>(_eulerSettings)->getEndTimeTol()))
            break;

        if (_zeroStatus ==EQUAL_ZERO && _tZero > -1)    // Nullstelle gefunden --> voller Schritt bis zum Ende
        {
            _firstStep            = true;
            _hUpLim = dynamic_cast<ISolverSettings*>(_eulerSettings)->getUpperLimit();
            _h = dynamic_cast<ISolverSettings*>(_eulerSettings)->gethInit() * dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroRatio();

            //handle all events that occured at this t
            //update_events_type update_event = boost::bind(&SolverDefaultImplementation::updateEventState, this);
            mixed_system->handleSystemEvents(_events/*,boost::ref(update_event)*/);

            _zeroStatus = EQUAL_ZERO;
            memcpy(_zeroValLastSuccess,_zeroVal,_dimZeroFunc*sizeof(double));

        }


        if (_tZero > -1)
        {

            solverOutput(_accStps,_tCurrent,_z,_h);
            saveLastSuccessfullState();
            _tCurrent = _tZero;
            _tZero=-1;
        }else

        {
            //_tCurrent += _h;
            _tCurrent = tHelp;
        }
        /*Old
        if (_zeroStatus == EQUAL_ZERO && _tZero > -1)    // Nullstelle gefunden --> voller Schritt bis zum Ende
        {
        _hUpLim = dynamic_cast<ISolverSettings*>(_eulerSettings)->getUpperLimit();
        _h = dynamic_cast<ISolverSettings*>(_eulerSettings)->gethInit() * dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroRatio();
        std::cout << "start event iteration at " << _tCurrent << "with " << _events[0] << ", " << _events[1] << (event_system != NULL ) << std::endl;
        //handle all events that occured at this t
        update_events_type update_event = boost::bind(&SolverDefaultImplementation::updateEventState, this);
        event_system->handleSystemEvents(_events,boost::ref(update_event));
        _firstStep =true;
        }


        if (_tZero > -1)
        {

        solverOutput(_accStps,_tCurrent,_z,_h);
        saveLastSuccessfullState();
        }
        else
        {
        std::cout << "event iteration  finished at " << _tCurrent << "with " << _tZero;
        }

        _tCurrent += _h;
        */


        doTimeEvents();
    }

    delete [] k1;
}







void Euler::doEulerBackward()
{
    IEvent* event_system =  dynamic_cast<IEvent*>(_system);
    IMixedSystem* mixed_system =  dynamic_cast<IMixedSystem*>(_system);
    int            numberOfIterations = 0;
    double        tHelp;
    double        nu,
        theta;
    double        nu_old = 1e6;
    long int    dimRHS = 1;                            // Dimension der rechten Seite zur Lösung LGS

    double
        *Z        = new double[_dimSys],                // Steigung (1. Stufe)
        *deltaZ    = new double[_dimSys],                // Hilfsvariable
        *LSErhs    = new double[_dimSys],                // Hilfsvariale y-Wert
        *T        = new double[_dimSys*_dimSys],            // Iterationsmatrix
        *jac    = new double[_dimSys*_dimSys],        // Jacobimatrix
        *yHelp    = new double[_dimSys],
        *fHelp  = new double[_dimSys],
        *pHelp    = new double[_dimSys];                // Hilfsvariale Pivotisierun
    memset(pHelp,0,_dimSys*sizeof(double));

    while(  _idid == 0 && _solverStatus != USER_STOP )
    {

        nu = 1e12;
        // Letzten Schritt ggf. anpassen
        if((_tCurrent + _h) > _tEnd)
            _h = (_tEnd - _tCurrent);

        // neue Stelle
        tHelp = _tCurrent + _h;

        // Startwerte setzten
        memset(Z,0,_dimSys*sizeof(double));
        for (int i=0;i<_dimSys;i++)
            deltaZ[i] = 1e15;


        // alten Zustandsvektor zwischenspeichren
        //if (_eulerSettings-> getDenseOutput())
        memcpy(_z0,_z,(int)_dimSys*sizeof(double));

        calcFunction(_tCurrent,_z,_f0);
        // Jacobimatrix aufstellen
        if(numberOfIterations == 0)
            calcJac(yHelp,fHelp,_f0,jac,false);
        else
        {
            /*ToDo
            if(_eulerSettings->iJacUpdate == 0 )
            {*/
            if(numberOfIterations == 1)
                calcJac(yHelp,fHelp,_f0,jac,false);
            /*Todo
            }

            else if(_accStps % _eulerSettings->iJacUpdate == 0)
            calcJac(yHelp,fHelp,_f0,jac,false);
            }
            */
        }
        //Iterationsmatrix aufstellen
        for(int j=0; j<_dimSys; ++j)
        {
            for(int i=0; i<_dimSys; ++i)
            {
                if (i==j)
                    T[i+j*_dimSys] = 1-_h*jac[i+j*_dimSys];
                else
                    T[i+j*_dimSys] = -_h*jac[i+j*_dimSys];
            }
        }

        // Iteration
        numberOfIterations = 0;
        while ( nu*euclidNorm(_dimSys,deltaZ) > _eulerSettings->getIterTol()*1e-3 && _idid == 0)
        {

            for (int i=0;i<_dimSys;i++)
                yHelp[i] = _z[i] + Z[i];

            calcFunction(tHelp, yHelp, fHelp);
            // Rechte Seite des LGS (k_diff)
            for(int i=0; i<_dimSys; ++i)
                LSErhs[i] =-Z[i] + _h*fHelp[i];

            // Löse das LGS (delta_Z wird in LSErhs geschrieben)
             dgesv_(&_dimSys,&dimRHS,T,&_dimSys,pHelp,LSErhs,&_dimSys,&_idid);

            // Konvergenzcheck
            if (numberOfIterations > 0)
            {
                theta = euclidNorm(_dimSys,LSErhs)/euclidNorm(_dimSys,deltaZ);
                nu = theta/(1-theta);
            }
            else
            {
                nu = max(nu_old,UROUND);
            }

            // Neue Iterierte
            for(int i=0; i<_dimSys; ++i)
            {
                Z[i] +=  LSErhs[i];
            }

            memcpy(deltaZ,LSErhs,_dimSys*sizeof(double));


            ++ numberOfIterations;


            if (numberOfIterations > 100 )
                _idid = -5000;
        }

        if (_idid < 0/*ToDo && _eulerSettings->bContinue*/)
        {
            _idid = 0;
        }

        nu_old = nu;


        // Berechnung des neuen y
        for(int i = 0; i < _dimSys; ++i)
            _z[i] += Z[i];

        calcFunction(tHelp,_z,_f1);
        memcpy(_z1,_z,_dimSys*sizeof(double));

        ////Beachtung von kritischen (mit Null initialisierten) Nullstellen
        //if(_tCurrent == 0.0)
        //{
        //    for(int i=0;i<_dimZeroFunc;i++)
        //    {
        //        if(_zeroInit[i])
        //        {
        //            event_system->checkConditions(i,false);
        //        }
        //    }
        //event_system->saveConditions();
        //}

        if (_idid != 0)
            throw invalid_argument("Euler::doEulerBackward() error" );

        ++_totStps;
        ++_accStps;

        solverOutput(_accStps,tHelp,_z,_h);
        doMyZeroSearch();

        if (((_tEnd - _tCurrent) < dynamic_cast<ISolverSettings*>(_eulerSettings)->getEndTimeTol()))
            break;


        if ((_zeroStatus == IDAESolver::EQUAL_ZERO) && (_tZero > -1))    // Nullstelle gefunden --> voller Schritt bis zum Ende
        {

            //_zeroSearchActive    = false;
            _firstStep            = true;

            // Originale maximale Schrittweite wiederherstellen,
            // Startschrittweite mit Verhältnis multiplizieren. Dadurch wird zu großer Startschritt vermieden.
            // Dies kann z.B. bei Diode zu großen rechten Seiten führen.
            _hUpLim = dynamic_cast<ISolverSettings*>(_eulerSettings)->getUpperLimit();
            _h = dynamic_cast<ISolverSettings*>(_eulerSettings)->gethInit() * dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroRatio();

            //handle all events that occured at this t
            //update_events_type update_event = boost::bind(&SolverDefaultImplementation::updateEventState, this);
            mixed_system->handleSystemEvents(_events/*,boost::ref(update_event)*/);
            _zeroStatus = IDAESolver::EQUAL_ZERO;

        }


        if (_tZero > -1)
        {

            solverOutput(_accStps,_tCurrent,_z,_h);
            saveLastSuccessfullState();
            _tCurrent = _tZero;
            _tZero=-1;
        }else
        {
            //_tCurrent += _h;
            _tCurrent = tHelp;
        }

        doTimeEvents();

    }


    delete [] Z;
    delete [] deltaZ;
    delete [] LSErhs;
    delete [] pHelp;
    delete [] T;
    delete [] jac;
    delete [] fHelp;

    delete [] yHelp;
}

void Euler::doMidpoint()
{
    IMixedSystem* mixed_system =  dynamic_cast<IMixedSystem*>(_system);
    int            numberOfIterations;
    double        tHelp,
        nu,
        theta,
        nu_old = 1e6,
        C = 1.5;
    long int    dimRHS    = 1;                                // Dimension rechte Seite zur Lösung LGS

    double
        *jac    = new double[_dimSys*_dimSys],        // Jacobimatrix
        *T        = new double[_dimSys*_dimSys],            // Iterationsmatrix
        *yHelp    = new double[_dimSys],                    // Hilfsvariable für y
        *Z        = new double[_dimSys],                    // Hilfsvariable für Stufe
        *deltaZ    = new double[_dimSys],                    // Hilfsvariable für Stufe
        *f0        = new double[_dimSys],
        *LSErhs    = new double[_dimSys],
        *pHelp    = new double[_dimSys],
        *fHelp    = new double[_dimSys];                    // Hilfsvariable für rechte Seite

    IEvent* event_system =  dynamic_cast<IEvent*>(_system);
    // Rechte Seite
    double* k1 = new double[_dimSys];

    while( _idid == 0)
    {
        // Letzten Schritt ggf. anpassen
        if((_tCurrent + _h) > _tEnd)
            _h = (_tEnd - _tCurrent);

        // neue Stelle
        tHelp = _tCurrent + _h;

        // Counter initialisieren
        numberOfIterations = 0;


        // alten Zustandsvektor für Dense-Output zwischenspeichern
        memcpy(_z0,_z,(int)_dimSys*sizeof(double));



        // Newton-Iteration
        if(_eulerSettings->getUseNewtonIteration())
        {

            nu = 1e12;
            // Initiale rechte Seite in k-Vektor schreiben
            calcFunction(_tCurrent,_z,f0);

            // Startwerte
            memset(Z,0,_dimSys*sizeof(double));
            for (int i=0;i<_dimSys;i++)
                deltaZ[i] = 1e15;

            // Jacobimatrix
            calcJac(yHelp,fHelp,f0,jac,true);
            // T = (E-hAJ)
            for(int j=0; j<_dimSys; ++j)
                for(int i=0; i<_dimSys; ++i)
                    if(i==j)
                        T[i+j*_dimSys] = 1.0 - C/(C+1)*_h*jac[i+j*_dimSys];
                    else
                        T[i+j*_dimSys] = - C/(C+1)*_h*jac[i+j*_dimSys];


            // Iteration
            while ( nu*euclidNorm(_dimSys,deltaZ) > _eulerSettings->getIterTol() && _idid == 0)
            {
                for (int i=0;i<_dimSys;i++)
                    yHelp[i] = _z[i] + Z[i];

                calcFunction(tHelp, yHelp, fHelp);

                // Rechte Seite des LGS (k_diff)
                for(int i=0; i<_dimSys; ++i)
                    LSErhs[i] =-Z[i] + C/(C+1)*_h*fHelp[i] + (1-C/(C+1))*_h*f0[i] ;

                // Löse das LGS (delta_Z wird in LSErhs geschrieben)
                dgesv_(&_dimSys,&dimRHS,T,&_dimSys,pHelp,LSErhs,&_dimSys,&_idid);

                // Konvergenzcheck
                if (numberOfIterations > 0)
                {
                    theta = euclidNorm(_dimSys,LSErhs)/euclidNorm(_dimSys,deltaZ);
                    nu = theta/(1-theta);
                }
                else
                {
                    nu = std::max(nu_old,UROUND);
                }

                // Neue Iterierte
                for(int i=0; i<_dimSys; ++i)
                {
                    Z[i] +=  LSErhs[i];
                }

                memcpy(deltaZ,LSErhs,_dimSys*sizeof(double));


                ++ numberOfIterations;


                if (numberOfIterations > 100 )
                    _idid = -5000;
            }

            nu_old = nu;


            // Berechnung des neuen y
            for (int i=0;i<_dimSys;i++)
                yHelp[i] = _z[i] + Z[i];

            calcFunction(tHelp, yHelp, fHelp);

            for(int i = 0; i < _dimSys; ++i)
            {
                _z[i]    += _h*(1-C/(C+1))*f0[i] + _h*C/(C+1)*fHelp[i];
            }


        }

        if (_idid != 0)
            throw invalid_argument("Euler::doMidpoint() error");


        ++ _totStps;
        ++ _accStps;


        memcpy(_z1,_z,_dimSys*sizeof(double));

        solverOutput(_accStps,tHelp,_z,_h);
        doMyZeroSearch();

        if (((_tEnd - _tCurrent) < dynamic_cast<ISolverSettings*>(_eulerSettings)->getEndTimeTol()))
            break;

        if (_zeroStatus == EQUAL_ZERO && _tZero > -1)    // Nullstelle gefunden --> voller Schritt bis zum Ende
        {

            //_zeroSearchActive    = false;
            //_firstStep            = true;

            // Originale maximale Schrittweite wiederherstellen,
            // Startschrittweite mit Verhältnis multiplizieren. Dadurch wird zu großer Startschritt vermieden.
            // Dies kann z.B. bei Diode zu großen rechten Seiten führen.
            _hUpLim = dynamic_cast<ISolverSettings*>(_eulerSettings)->getUpperLimit();
            _h = dynamic_cast<ISolverSettings*>(_eulerSettings)->gethInit()* dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroRatio();

            //update_events_type update_event = boost::bind(&SolverDefaultImplementation::updateEventState, this);
            mixed_system->handleSystemEvents(_events/*,boost::ref(update_event)*/);


        }


        if (_tZero > -1)
        {

            solverOutput(_accStps,_tCurrent,_z,_h);
            saveLastSuccessfullState();
        }

        _tCurrent += _h;
        doTimeEvents();


    }
    delete    [] jac;
    delete    [] T;
    delete    [] yHelp;
    delete    [] Z;
    delete    [] deltaZ;
    delete    [] fHelp;
    delete    [] f0;
    delete    [] LSErhs;
    delete    [] pHelp;
}


/**
Check for time events
*/
void Euler::doTimeEvents()
{

    IEvent* event_system =  dynamic_cast<IEvent*>(_system);
    IMixedSystem* mixed_system =  dynamic_cast<IMixedSystem*>(_system);
    if(_time_events.size()>0)
    {
        event_times_type::iterator iter;

        iter = find_if( _time_events.begin(), _time_events.end(), floatCompare<double>(_tCurrent,dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroTimeTol()) );

        //Time event is reached
        if(iter!=_time_events.end())
        {
            //Handle time event
            /*event_system->handleEvent(iter->second);*/
            //Handle all events that occured at this time
            //update_events_type update_event = boost::bind(&SolverDefaultImplementation::updateEventState, this);
            mixed_system->handleSystemEvents(_events/*,boost::ref(update_event)*/);

            //Check if old time events were overrned because step size is not adequate
            if(distance(_time_events.begin(),iter)>0)
                throw std::runtime_error("Time event was not reached, please check solver step size");
            //Erase old time entries
            _time_events.erase(iter);
        }

    }

}

void Euler::giveZeroVal(const double &t,const double *y,double *zeroValue)
{
    IContinuous* continous_system = dynamic_cast<IContinuous*>(_system);
    IEvent* event_system =  dynamic_cast<IEvent*>(_system);
    continous_system->setTime(t);
    continous_system->setVars(y);

    // System aktualisieren
    continous_system->update(IContinuous::CONTINOUS);
    event_system->giveZeroFunc(zeroValue);
}

void Euler::giveZeroIdx(double *vL,double *vR,int *zeroIdx, int &zeroExist)
{
    zeroExist = 0;
    for (int i=0; i<_dimZeroFunc; i++)
    {
        // Überprüfung auf Vorzeichenwechsel
        if (vL[i] * vR[i] <= 0 && abs(vL[i]- vR[i])>UROUND)
        {
            zeroIdx[i] = 1;
            zeroExist++;
        }
        else
            zeroIdx[i] = 0;
    }
}

void Euler::doMyZeroSearch()
{

    if (_zeroStatus == ZERO_CROSSING)
    {

        double  tL = _tCurrent,
            tR = _tCurrent+_h,
            tDelta,
            tTry,
            tSwap,
            maybe,
            change,
            lastMoved,
            *yL,
            *yR,
            *yTry,
            *ySwap,
            *vL,
            *vR,
            *vTry,
            *vSwap,
            *IllinoisV;

        int    zeroExist,
            leftZero,
            *zeroIdx;
        bool notDone = true;

        yL = new double[_dimSys];
        yR = new double[_dimSys];
        yTry = new double[_dimSys];
        ySwap = new double[_dimSys];
        vL = new double[_dimZeroFunc];
        vR = new double[_dimZeroFunc];
        vTry = new double[_dimZeroFunc];
        vSwap = new double[_dimZeroFunc];
        IllinoisV = new double[_dimZeroFunc];
        zeroIdx = new int[_dimZeroFunc];

        // Initialisierung der benötigten Größen
        //
        //tL,tR: Zeit am linken/rechten Intervallrans
        //yL,yR: Zustand am linken/rechten Intervallrand
        //vL,vR: Nullstellenfunktion am ...
        //

        memcpy(yL,_z0,_dimSys*sizeof(double));
        memcpy(yR,_z,_dimSys*sizeof(double));
        memcpy(vL,_zeroValLastSuccess,_dimZeroFunc*sizeof(double));
        memcpy(vR,_zeroVal,_dimZeroFunc*sizeof(double));


        // DBG
        //for (long int i=1;i<=_dimSys;i++)
        //            yL[i-1] = CONTR5(&i,&tR,cont,lrc);

        //


        _tZero = -1;
        tTry = tR;
        while(true)
        {
            lastMoved = 0;

            // Finde die Nullstelle
            while(true)
            {
                notDone = false;
                giveZeroIdx(vL,vR,zeroIdx,zeroExist);
                if ( zeroExist == 0)
                    return;
                //Ist das Zeitintervall noch groß genug ?
                tDelta = tR - tL;

                for (int i=0;i<_dimZeroFunc;i++)
                    if ((zeroIdx[i] == 1) && ((abs(vR[i]) >dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroTol())))
                        notDone = true;

                if ((tDelta <=dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroTimeTol()))
                    notDone = false;

                if (notDone==false)
                    break;

                leftZero = 0;
                for (int i=0;i<_dimZeroFunc;i++)
                    if ((zeroIdx[i] == 1) && ((abs(vL[i]) < UROUND) & (abs(vR[i]) >= UROUND)))
                        leftZero = 1;

                if((tL==_tCurrent) & leftZero)
                    tTry = tL + 0.5*dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroTimeTol();
                else
                {
                    // Regula Falsi
                    change = 1;
                    for (int i=0;i<_dimZeroFunc;i++)
                    {
                        if (zeroIdx[i] == 0)
                            continue;
                        // Falls vL oder vR Null ist, altes tTry verwenden
                        if (abs(vL[i])<UROUND)
                        {
                            if (tTry>tR && vTry[i] != vR[i])
                            {
                                maybe = 1-vR[i]*(tTry-tR)/((vTry[i]-vR[i])*tDelta);
                                if (maybe < 0 || maybe > 1)
                                    maybe = 0.5;
                            }
                            else
                            {
                                maybe = 0.5;
                            }

                        }
                        else
                        {
                            if (abs(vR[i] < UROUND))
                            {
                                if (tTry<tL && vTry[i] != vL[i])
                                {
                                    maybe = vL[i]*(tL-tTry)/((vTry[i]-vL[i])*tDelta);
                                    if (maybe < 0 || maybe > 1)
                                        maybe = 0.5;
                                }
                                else
                                {
                                    maybe = 0.5;
                                }

                            }
                            else
                            {
                                maybe = -vL[i]/(vR[i]-vL[i]);
                            }
                        }
                        // die Nullstelle die weitesten links liegt wird betrachtet
                        if (maybe < change)
                            change = maybe;
                    } //end for

                    change = change*abs(tDelta);
                    change = std::max(0.5*dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroTimeTol(),min(change,abs(tDelta)-0.5*dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroTimeTol()));

                    tTry = tL + change;

                }// end if tL== tOld

                // vTry berechnen
                interp1(tTry,yTry);
                giveZeroVal(tTry,yTry,vTry);

                // Nullstellendurchgänge zwischen tL und tTry
                giveZeroIdx(vL,vTry,zeroIdx,zeroExist);

                if (zeroExist)
                {
                    // rechte Intervallgrenze nach links schieben
                    tSwap = tR;
                    tR = tTry;
                    tTry = tSwap;

                    memcpy(ySwap,yR,_dimSys*sizeof(double));
                    memcpy(yR,yTry,_dimSys*sizeof(double));
                    memcpy(yTry,ySwap,_dimSys*sizeof(double));

                    memcpy(vSwap,vR,_dimZeroFunc*sizeof(double));
                    memcpy(vR,vTry,_dimZeroFunc*sizeof(double));
                    memcpy(vTry,vSwap,_dimZeroFunc*sizeof(double));

                    // falls zweimal in Folge nach links verschoben wurde, wird vL halbiert (nächstes mal wird weiter gerückt)
                    if (lastMoved == 2)
                    {
                        for (int i=0;i<_dimZeroFunc;i++)
                        {
                            IllinoisV[i] = 0.5*vL[i];
                            if (abs(IllinoisV[i]) >=UROUND)
                                vL[i] = IllinoisV[i];
                        }
                    }
                    lastMoved = 2;
                }
                else
                {
                    // linke Intervallgrenze nach rechts schieben
                    tSwap = tL;
                    tL = tTry;
                    tTry = tSwap;

                    memcpy(ySwap,yL,_dimSys*sizeof(double));
                    memcpy(yL,yTry,_dimSys*sizeof(double));
                    memcpy(yTry,ySwap,_dimSys*sizeof(double));

                    memcpy(vSwap,vL,_dimZeroFunc*sizeof(double));
                    memcpy(vL,vTry,_dimZeroFunc*sizeof(double));
                    memcpy(vTry,vSwap,_dimZeroFunc*sizeof(double));

                    // falls zweimal in Folge nach rechts verschoben wurde, wird vR halbiert (nächstes mal wird weiter gerückt)
                    if (lastMoved == 1)
                    {
                        for (int i=0;i<_dimZeroFunc;i++)
                        {
                            IllinoisV[i] = 0.5*vR[i];
                            if (abs(IllinoisV[i]) >=UROUND)
                                vR[i] = IllinoisV[i];
                        }
                    }
                    lastMoved = 1;
                }// end for zeroExist
            }// end while REGULA-FALSI

            _tZero = tR;

            if (_tInit != tL)
            {
                memcpy(_zeroVal,vR,_dimZeroFunc*sizeof(double));
                break;
            }
            else
            {
                memcpy(_zeroVal,vR,_dimZeroFunc*sizeof(double));
                //tZero = -1;
                break;
            }
            if (abs(_tCurrent+_h-tR) < dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroTimeTol())
            {
                memcpy(_zeroVal,vR,_dimZeroFunc*sizeof(double));
                break;
            }
            else
            { // betrachte [tR+0.5*tol tnew]
                tTry = tR;
                yTry = yR;
                vTry = vR;
                tL = tR + 0.5*dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroTimeTol();
                interp1(tL,yL);
                giveZeroVal(tL,yL,vL);
                tR = _tCurrent+_h;
                yR = _z;
                memcpy(vR,_zeroVal,_dimZeroFunc*sizeof(double));
            }


        }//end while terminal

        /*
        for (int i=0;i<_dimZeroFunc;i++)
        {
        if (zeroIdx[i] ==0)
        _zeroSign[i] = 0;
        else
        _zeroSign[i] = sgn(_zeroVal[i]-_zeroValLastSuccess[i]);
        if ( abs(_zeroVal[i]) == 0 )
        _zeroVal[i] = -sgn(_zeroValLastSuccess[i]) * UROUND;
        }
        */
        interp1(_tZero,_z);
        _tLastSuccess = tL;
        _tCurrent = _tZero;
        setZeroState();

        IContinuous* continous_system = dynamic_cast<IContinuous*>(_system);
        continous_system->setTime(_tCurrent);
        continous_system->setVars(_z);
        continous_system->update(IContinuous::CONTINOUS);


        delete [] yL;
        delete [] yR;
        delete [] yTry;
        delete [] ySwap;
        delete [] vL;
        delete [] vR;
        delete [] vTry;
        delete [] vSwap;
        delete [] IllinoisV;
        delete [] zeroIdx;

    }// end if ZERO_STATE
    else if (_zeroStatus == EQUAL_ZERO)
    {

        _tZero = _tCurrent+_h;
        _tCurrent = _tZero;
    }
}

void Euler::calcFunction(const double& t, const double* z, double* f)
{
    IContinuous* continous_system = dynamic_cast<IContinuous*>(_system);
    continous_system->setTime(t);
    continous_system->setVars(z);
    continous_system->update(IContinuous::CONTINOUS);
    continous_system->giveRHS(f);
}

void Euler::solverOutput(const int& stp, const double& t, double* z, const double& h)
{
    IContinuous* continous_system = dynamic_cast<IContinuous*>(_system);
    IEvent* event_system =  dynamic_cast<IEvent*>(_system);
    continous_system->setTime(t);

    // (Re-)start of integration => First step: read state vector from the system
    if (_firstStep)
    {
        _firstStep    = false;

        // Update the system
        continous_system->update(IContinuous::CONTINOUS);

        // read variables from the system
        continous_system->giveVars(z);



        if (_zeroVal)
        {
            // read values of zero functions
            event_system->giveZeroFunc(_zeroVal);

            // Determine the sign and hence the status of zero crossings
            SolverDefaultImplementation::setZeroState();
        }

        // Ensures that solver is started with right sign of zero function
        _zeroStatus = UNCHANGED_SIGN;

    }


    // During integration: write state vector to the system
    else
    {
        // set variables to the system
        continous_system->setVars(z);

        // Update the system
        continous_system->update(IContinuous::CONTINOUS);


        if(_zeroVal && (stp > 0))
        {
            // read values of zero functions
            event_system->giveZeroFunc(_zeroVal);

            // Determine the sign and hence the status of zero crossings
            SolverDefaultImplementation::setZeroState();
        }
        if (abs(t-_tEnd) <= dynamic_cast<ISolverSettings*>(_eulerSettings)->getEndTimeTol())
            _zeroStatus = UNCHANGED_SIGN;
    }


    if (_zeroStatus == UNCHANGED_SIGN || _zeroStatus == EQUAL_ZERO)
    {
        if (_eulerSettings->getDenseOutput())
        {
            if (t == 0)
                SolverDefaultImplementation::writeToFile(stp, t, h);
            else
            {
                while (_tLastWrite + dynamic_cast<ISolverSettings*>(_eulerSettings)->getGlobalSettings()->gethOutput() -t -dynamic_cast<ISolverSettings*>(_eulerSettings)->getEndTimeTol() <= 0)
                {
                    // Zeitpunkt an dem geschrieben wird
                    _tLastWrite = _tLastWrite +  dynamic_cast<ISolverSettings*>(_eulerSettings)->getGlobalSettings()->gethOutput();

                    // System in den richtigen Zustand bringen
                    interp1(_tLastWrite,_zWrite);

                    // setTime
                    continous_system->setTime(_tLastWrite);

                    // setVars
                    continous_system->setVars(_zWrite);

                    // System aktualisieren
                    continous_system->update(IContinuous::CONTINOUS);

                    SolverDefaultImplementation::writeToFile(stp, _tLastWrite, h);

                }//end while t -_tLastWritten
                // System in den alten Zustand zurück versetzen

                // setTime
                continous_system->setTime(t);

                // setVars
                continous_system->setVars(z);

                continous_system->update(IContinuous::CONTINOUS);

            }
        }
        else
            SolverDefaultImplementation::writeToFile(stp, t, h);

        // Zähler für die Anzahl der ausgegebenen Schritte erhöhen
        ++ _outputStps;

        saveLastSuccessfullState();
    }

    // Ensures that no user stop occurs in the very first step, when the solver has not done at least one step
    if (stp == 0)
        _zeroStatus = UNCHANGED_SIGN;
}





void Euler::interp1(double time, double *value)
{

    double t = (time-_tCurrent)/_h;

    _h00 = 2*pow(t,3)-3*pow(t,2)+1;
    _h10= pow(t,3)-2*pow(t,2)+t;
    _h01 = -2*pow(t,3)+3*pow(t,2);
    _h11 = pow(t,3)-pow(t,2);

    for (int i=0;i<_dimSys;i++)
        value[i] = _h00*_z0[i] + _h10*_h*_f0[i]  + _h01*_z1[i] + _h11*_h*_f1[i];
}




void Euler::saveInitState()
{
    IContinuous* continous_system = dynamic_cast<IContinuous*>(_system);

    // Aktuellen Zeitpunkt als initialen Zeitpunkt (Anfangszeit des gesamten Integrationsintervalls) abspeichern
    _tInit= _tCurrent;

    // ZeroFunction-Vector abspeichern
    if (_zeroVal)
        memcpy(_zeroValInit,_zeroVal,_dimZeroFunc*sizeof(double));

    // Zustandsvektor abspeichern
    continous_system->giveVars(_zInit);
}

void Euler::writeSimulationInfo()
{
    //// Solver
    //outputStream
    //    << "Solver:                       Euler\n"
    //    << "Method:                       ";

    //if(_eulerSettings->getEulerMethod() == IEulerSettings::EULERFORWARD)
    //    outputStream << "Explicit Euler";
    //else if(_eulerSettings->getEulerMethod() == IEulerSettings::EULERBACKWARD)
    //    outputStream << "Implicite Euler";
    //else if(_eulerSettings->getEulerMethod() ==IEulerSettings::MIDPOINT)
    //    outputStream << "Mitpoint rule";


    //outputStream << std::endl;

    //// Time
    //outputStream
    //    << "Simulation end t:          " << _tCurrent << " \n"
    //    << "Step size:                    " << dynamic_cast<ISolverSettings*>(_eulerSettings)->gethInit() << " \n"
    //    << "Output step size:             " << dynamic_cast<ISolverSettings*>(_eulerSettings)->getGlobalSettings()->gethOutput();

    //outputStream << std::endl;

    //// System
    //outputStream
    //    << "Number of equations (ODE):    " << (int)_dimSys << " \n"
    //    << "Number of zero functions:     " << _dimZeroFunc;

    //outputStream << std::endl;

    //// Root finding
    //if (!(_zeroVal) && _eulerSettings->getZeroSearchMethod() == IEulerSettings::NO_ZERO_SEARCH)
    //{
    //    outputStream << "\nZero search method:           No zero search\n" << std::endl;
    //}
    //else
    //{
    //    if (_eulerSettings->getZeroSearchMethod() == IEulerSettings::BISECTION)
    //    {
    //        outputStream << "Zero search method:           Bisection" << std::endl;
    //    }
    //    else
    //    {
    //        outputStream << "Zero search method:           Linear Interpolation" << std::endl;
    //    }

    //    outputStream
    //        << "Zero function tolerance:      " << dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroTol() << " \n"
    //        << "Zero t tolerance:          " << dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroTimeTol() << " \n"
    //        << "Number of zero search steps:  " << _zeroStps << " \n"
    //        << "Number of zeros in interval:  " << _zeros << std::endl;
    //}

    //if(_eulerSettings->getEulerMethod() == IEulerSettings::EULERBACKWARD || _eulerSettings->getEulerMethod() == IEulerSettings::MIDPOINT && _eulerSettings->getUseNewtonIteration() == true)
    //    outputStream    << "Iteration tolerance:          " << _eulerSettings->getIterTol() << std::endl;

    //// Steps
    //outputStream
    //    << "Total number of steps:        " << _totStps << "\n"
    //    << "Number of output steps:       " << _outputStps << "\n"
    //    << "Status:                       " << _idid;

    //outputStream << std::endl;
}
const int Euler::reportErrorMessage(ostream& messageStream)
{
    if(_solverStatus == IDAESolver::SOLVERERROR)
    {
        if(_idid == -1)
            messageStream << "Invalid system dimension." << std::endl;
        if(_idid == -2)
            messageStream << "Method not implemented." << std::endl;
        if(_idid == -3)
            messageStream << "No valid system/settings available." << std::endl;
        if(_idid == -11)
            messageStream << "Step size too small." << std::endl;
    }

    else if(_solverStatus == IDAESolver::USER_STOP)
    {
        messageStream << "Simulation terminated by user at t: " << _tCurrent << std::endl;
    }

    return _idid;
}
void Euler::restoreInitState()
{
    IContinuous* continous_system = dynamic_cast<IContinuous*>(_system);
    // Initialen Zeitpunkt wiederherstellen
    _tCurrent = _tInit;

    // Einträge im ZeroFunction-Vektor wiederherstellen
    if (_zeroVal)
        memcpy(_zeroVal,_zeroValInit,_dimZeroFunc*sizeof(double));

    // Initialen Zustandsvektor wiederherstellen
    continous_system->setVars(_zInit);

}

void Euler::saveLastSuccessfullState()
{
    // Save current time step as "last sucessfull"
    _tLastSuccess = _tCurrent;

    // Save current zero function values
    if (_zeroVal)
        memcpy(_zeroValLastSuccess,_zeroVal,_dimZeroFunc*sizeof(double));

    // Save current state as "last sucessfull" one
    memcpy(_zLastSucess,_z,_dimSys*sizeof(double));
}

void Euler::restoreLastSuccessfullState()
{
    // Restore last sucessfull time step
    _tCurrent = _tLastSuccess;

    // Restore zero values of last successfull time step
    if (_zeroVal)
        memcpy(_zeroVal,_zeroValLastSuccess,_dimZeroFunc*sizeof(double));

    // Restore state vector of last sucessfull time step
    memcpy(_z,_zLastSucess,_dimSys*sizeof(double));
}
void Euler::calcJac(double* yHelp, double* _fHelp, const double* _f, double* jac, const bool& flag)
{
    for(int j=0; j<_dimSys; ++j)
    {
        // reset m_pYhelp for every colum
        memcpy(yHelp,_z,_dimSys*sizeof(double));

        yHelp[j] += 1e-8;

        // delta_f berechnen
        calcFunction(_tCurrent, yHelp, _fHelp);

        // Jacobimatrix aufbauen
        for(int i=0; i<_dimSys; ++i)
        {
            jac[i+j*_dimSys] = (_fHelp[i] - _f[i]) / 1e-8;
        }
    }
}

using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
    types.get<std::map<std::string, factory<SolverDefaultImplementation,IMixedSystem*, ISolverSettings*> > >()
        ["DefaultsolverImpl"].set<SolverDefaultImplementation>();
    types.get<std::map<std::string, factory<IDAESolver,IMixedSystem*, ISolverSettings*> > >()
        ["EulerSolver"].set<Euler>();
    types.get<std::map<std::string, factory<ISolverSettings, IGlobalSettings* > > >()
        ["EulerSettings"].set<EulerSettings>();
}
