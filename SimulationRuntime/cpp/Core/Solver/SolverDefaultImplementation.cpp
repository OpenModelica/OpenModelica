#include "stdafx.h"
#define BOOST_EXTENSION_SOLVER_DECL BOOST_EXTENSION_EXPORT_DECL
#define BOOST_EXTENSION_SOLVERSETTINGS_DECL BOOST_EXTENSION_EXPORT_DECL

#include <Solver/SolverDefaultImplementation.h>
#include <Solver/SolverSettings.h>
#include <SimulationSettings/IGlobalSettings.h>
//#include "../Interfaces/API.h"
#include <Math/Constants.h>

SolverDefaultImplementation::SolverDefaultImplementation(IMixedSystem* system, ISolverSettings* settings)
: _system                (system)
, _settings                ((ISolverSettings*)settings)

, _tInit                (0.0)
, _tCurrent                (0.0)
, _tEnd                    (0.0)
, _tLastSuccess            (0.0)
, _tLastUnsucess        (0.0)
, _tLargeStep            (0.0)
, _h                    (0.0)

//, _firstCall            (true)
, _firstStep            (true)

, _totStps                (0)
, _accStps                (0)
, _rejStps                (0)
, _zeroStps                (0)
, _zeros                (0)

, _zeroStatus            (IDAESolver::UNCHANGED_SIGN)
, _zeroValInit            (NULL)
, _dimZeroFunc            (0)
, _zeroVal                (NULL)
, _zeroValLastSuccess    (NULL)
, _zeroValLargeStep        (NULL)
, _events                (NULL)
, _zeroSearchActive        (false)

, _outputCommand        (IMixedSystem::WRITE)

{
    _initialization = new Initialization(dynamic_cast<ISystemInitialization*>(_system));
}
SolverDefaultImplementation::~SolverDefaultImplementation()
{
    if(_zeroVal)
        delete [] _zeroVal;
    if(_zeroValInit)
        delete [] _zeroValInit;
    if(_zeroValLastSuccess)
        delete [] _zeroValLastSuccess;
    if(_events)
        delete [] _events;
    delete _initialization;
}

        void SolverDefaultImplementation::setStartTime(const double& t)
    {
        _tCurrent = t;
    };

     void SolverDefaultImplementation::setEndTime(const double& t)
    {
        _tEnd = t;
    };

     void SolverDefaultImplementation::setInitStepSize(const double& h)
    {
        _h = h;
    };



    const IDAESolver::SOLVERSTATUS SolverDefaultImplementation::getSolverStatus()
    {
        return _solverStatus;
    };
void SolverDefaultImplementation::init()
{
    IContinuous* continous_system = dynamic_cast<IContinuous*>(_system);
    IEvent* event_system =  dynamic_cast<IEvent*>(_system);
    ISystemInitialization* init_system = dynamic_cast<ISystemInitialization*>(_system);
    // Set current start time to the system
    continous_system->setTime(_tCurrent);

    // Assemble the system
    //init_system->init(_settings->getGlobalSettings()->getStartTime(),_settings->getGlobalSettings()->getEndTime());
    _initialization->initializeSystem(_settings->getGlobalSettings()->getStartTime(),_settings->getGlobalSettings()->getEndTime());


    //// Write out head line
    //if (_outputStream)
    //{
    //    // Write head line (step time step size) into output stream
    //    *_outputStream << "step\t time\t h";
    //
    //    // Prompt system to write out its results
    //    _system->writeOutput(IMixedSystem::HEAD_LINE);

    //    // Write a line break into output stream
    //    *_outputStream << std::endl;
    //}
   _system->writeOutput(IMixedSystem::HEAD_LINE);

    // Allocate array with values of zero functions
    if (_dimZeroFunc != event_system->getDimZeroFunc())
    {
        // Number (dimension) of zero functions
        _dimZeroFunc = event_system->getDimZeroFunc();

        if(_zeroVal)
            delete [] _zeroVal;
        if(_zeroValInit)
            delete [] _zeroValInit;
        if(_zeroValLastSuccess)
            delete [] _zeroValLastSuccess;
        if(_events)
            delete [] _events;

        _zeroVal            = new double[_dimZeroFunc];
        _zeroValLastSuccess    = new double[_dimZeroFunc];
        _events                = new bool[_dimZeroFunc];
        _zeroValInit            = new double[_dimZeroFunc];
        _zeroValLargeStep        = new double[_dimZeroFunc];
        event_system->giveZeroFunc(_zeroVal);
        memcpy(_zeroValLastSuccess,_zeroVal,_dimZeroFunc*sizeof(double));
        memcpy(_zeroValInit,_zeroVal,_dimZeroFunc*sizeof(double));
        memset(_events,false,_dimZeroFunc*sizeof(bool));
        memcpy(_zeroValLargeStep,_zeroVal,_dimZeroFunc*sizeof(double));
    }

     // Set flags
    _firstCall            = true;
    _firstStep            = true;
    _zeroSearchActive    = false;

    // Reset counter
    _totStps     = 0;
    _accStps     = 0;
    _rejStps    = 0;
    _zeroStps    = 0;
    _zeros        = 0;

    // Set initial step size
    //_h = _settings->_globalSettings->_hOutput;
}

void SolverDefaultImplementation::setZeroState()
{

        // Reset Zero-State
    _zeroStatus = IDAESolver::UNCHANGED_SIGN;;

    // Alle Elemente im ZeroFunction-Array durchgehen
    for (int i=0; i<_dimZeroFunc; ++i)
    {
        // Überprüfung auf Vorzeichenwechsel
        // wenn _zeroVal[i] = _zeroValLastSuccess[i] = 0 ist.
        //if (_zeroVal[i] * _zeroValLastSuccess[i] <= 0 && (_zeroVal[i]!= 0.0 || _zeroValLastSuccess[i] != 0.0))
        if (_zeroVal[i] * _zeroValLastSuccess[i] <= 0 && abs(_zeroVal[i]-_zeroValLastSuccess[i])>UROUND)
        {

            // Überprüfung, ob rechte Seite kleiner als vorgegebene Toleranz ist
            if ( (fabs(_zeroVal[i])) < _settings->getZeroTol() || (_tCurrent != 0 && (_tCurrent-_tLastSuccess) < _settings->getZeroTimeTol()) )
            {

                //  Eintrag im Array liegt innerhalb Toleranzbereich und gilt als =0
                _zeroStatus = IDAESolver::EQUAL_ZERO;
                _events[i] = true;
                // ZeroVal darf nicht null werden, da sonst im nächsten Schritt
                // die Richtung des Vorzeichenwechsels nicht erkannt werden kann
                if ( _zeroVal[i] == 0.0 )
                    _zeroVal[i] = -sgn(_zeroValLastSuccess[i]) * UROUND;
            }
            else
            {

                // Vorzeichenwechsel, aber Eintrag ist größer (oder kleiner) als Toleranzbereich
                _zeroStatus = IDAESolver::ZERO_CROSSING;

                // Rest ZeroSign
                _events[i] = false;

                // Zeitpunkt des letzten verworfenen Schrittes abspeichern
                _tLastUnsucess = _tCurrent;
                break;
            }
        }
        else
            _events[i] = false;
    }
    // Bei erstem Schritt können gleichzeitig meherere Vorzeichenwechsel auftreten, hier gilt für den Fall :
    //_zeroVal[i]-_zeroValLastSuccess[i])<UROUND
    if (_tLastSuccess == 0.0 && _zeroStatus == IDAESolver::EQUAL_ZERO)
    {
        for (int i=0; i<_dimZeroFunc; ++i)
        {
        // Überprüfung auf Vorzeichenwechsel
        if (_zeroVal[i] * _zeroValLastSuccess[i] <= 0)
        {
            // Überprüfung, ob rechte Seite kleiner als vorgegebene Toleranz ist
            if ( (fabs(_zeroVal[i])) < _settings->getZeroTol()  || (_tCurrent != 0 && (_tCurrent-_tLastSuccess) <_settings->getZeroTimeTol()) )
            {

                //  Eintrag im Array liegt innerhalb Toleranzbereich und gilt als =0
                _zeroStatus = IDAESolver::EQUAL_ZERO;
                _events[i] = true;
                // ZeroVal darf nicht null werden, da sonst im nächsten Schritt
                // die Richtung des Vorzeichenwechsels nicht erkannt werden kann
                if ( _zeroVal[i] == 0.0 )
                    _zeroVal[i] = -sgn(_zeroValLastSuccess[i]) * UROUND;
            }
            else
            {

                // Vorzeichenwechsel, aber Eintrag ist größer (oder kleiner) als Toleranzbereich
                _zeroStatus = IDAESolver::ZERO_CROSSING;

                // Rest ZeroSign
                _events[i] = false;

                // Zeitpunkt des letzten verworfenen Schrittes abspeichern
                _tLastUnsucess = _tCurrent;
                break;
            }
        }
        else
            _events[i] = false;
        }
    }
    // Sofern Nullstellensuche aktiv, wird überprüft ob über den Punkt wo ZeroCrossing war schon drüber ist.
    // Wenn ja, gab es wohl doch keine Nullstelle (Berechnungsfehler wg. zu großer Schrittweite)
    if (_zeroSearchActive && (_tCurrent > _tLastUnsucess))
        _zeroStatus = IDAESolver::NO_ZERO;

}



void SolverDefaultImplementation::writeToFile(const int& stp, const double& t, const double& h)
{

    //if (_outputStream && _settings->_globalSettings->_resultsOutput)
    //{
    //    // Reset curser within output stream to last valid position (before zero crossing)
    //    if(_outputCommand & IContinuous::RESET)
    //        if(stp == 1)
    //            _outputStream->seekp(_curserPosition);

    //    if(_outputCommand & IContinuous::WRITE)
    //    {
    //        // In the first step, tell (inital) curser position within output stream
    //        if(stp == 1)
    //            _curserPosition = _outputStream->tellp();

    //        // Write current step, time and step size into output stream
    //        *_outputStream << stp << "\t" << t << "\t" << h;

    //        // Write out output stream
    //        _system->writeOutput(_outputCommand);
    //
    //        // Write a line break into output stream
    //        *_outputStream << std::endl;
    //    }
    //}

    if(_outputCommand & IMixedSystem::WRITE)
    {
        _system->writeOutput(_outputCommand);
    }
}
void SolverDefaultImplementation::updateEventState()
{
    dynamic_cast<IEvent*>(_system)->giveZeroFunc(_zeroVal);
    setZeroState();
    if (_zeroStatus == IDAESolver::ZERO_CROSSING)     // An event triggered an other event
    {
        _tLastSuccess = _tCurrent;         // Concurrently occured events are in the time tollerance
        setZeroState();                     // Upate status of events vector
    }
}
using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<SolverDefaultImplementation,IMixedSystem*, ISolverSettings*> > >()
    ["DefaultsolverImpl"].set<SolverDefaultImplementation>();
  types.get<std::map<std::string, factory<ISolverSettings, IGlobalSettings* > > >()
    ["SolverSettings"].set<SolverSettings>();
}
