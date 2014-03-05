
#include "stdafx.h"
#include "SimManager.h"

SimManager::SimManager(boost::shared_ptr<IMixedSystem> system,Configuration* config)
      :_mixed_system(system)
      ,_config(config)
      ,_timeeventcounter(NULL)
      , _events(NULL)
{
  
      _solver = _config->createSelectedSolver(system.get());
  
      _initialization = new Initialization(boost::dynamic_pointer_cast<ISystemInitialization>(_mixed_system),_solver);
  
}
SimManager::~SimManager()
{
      if(_timeeventcounter)
            delete _timeeventcounter;
      if(_events)
            delete [] _events;
}

void SimManager::initialize()
{

      boost::shared_ptr<ISystemInitialization> system_obj = boost::dynamic_pointer_cast<ISystemInitialization>(_mixed_system);
      boost::shared_ptr<IContinuous> cont_system = boost::dynamic_pointer_cast<IContinuous>(_mixed_system);
      boost::shared_ptr<ITime> timeevent_system = boost::dynamic_pointer_cast<ITime>(_mixed_system);
      boost::shared_ptr<IEvent> event_system = boost::dynamic_pointer_cast<IEvent>(_mixed_system);
      /* Logs temporarily disabled
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_info) << "start init";*/

      // Flag für Endlossimulaton (wird gesetzt wenn Solver zurückkommt)
      _continueSimulation = true; 

      // Reset debug ID
      _idid = 0;

      try
      {
            // System zusammenbauen und einmal updaten
            //system_obj->initialize(_config->getGlobalSettings()->getStartTime(),_config->getGlobalSettings()->getEndTime());
            //cont_system->update(IContinuous::UPDATE(IContinuous::ACROSS|IContinuous::THROUGH));
            _initialization->initializeSystem();
      }
      catch(std::exception& ex)
      {
            std::string msg = ex.what();
            throw std::invalid_argument(msg);
      }

      _totStps = 0 ;
      _accStps = 0;
      _rejStps =0;

      if(timeevent_system)
      {
            _dimtimeevent = timeevent_system->getDimTimeEvent();
            if(_timeeventcounter)
                  delete _timeeventcounter;
            _timeeventcounter = new int[_dimtimeevent];
      }
      else
            _dimtimeevent =0;
      _tStart      = _config->getGlobalSettings()->getStartTime();
      _tEnd      =_config->getGlobalSettings()->getEndTime();
      //// Task: WRITE und FIRST_CALL+LAST_CALL, da es nur einen Solver (und somit keine Koppelschritte) gibt
      _solverTask = ISolver::SOLVERCALL(ISolver::FIRST_CALL);
      if (_dimZeroFunc= event_system->getDimZeroFunc() )
      { 
            if(_events)
                  delete [] _events;
            _events                        = new bool[_dimZeroFunc];
            memset(_events,false,_dimZeroFunc*sizeof(bool));
      }

      /* Logs vorübergehend deaktiviert
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_info) << "Assemble completed";*/
}
void SimManager::runSimulation()
{
      try
      {
            /* Logs temporarily disabled
            BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal) << "Start simulation at t= " << _tStart;
            */
            runSingleProcess();
            // Zeit messen, Ausgabe der SimInfos
            ISolver::SOLVERSTATUS  status = _solver->getSolverStatus(); 
            if(status & ISolver::DONE ||  status & ISolver::USER_STOP)
            {
                  /* Logs temporarily disabled
                  BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal) << "Simulation done at t= " << _tEnd;
                  BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal) <<  "Number of steps: " << _totStps.at(0); 
                  BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal) << "Simulationsdauer: " << (_tClockEnd-_tClockStart)/1000.0; 
                  */
                  writeProperties();
            }
      }
      catch(std::exception& ex) 
      {
            /* Logs temporarily disabled
            BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal) << "Simulation finish with errors at t= " << _tEnd;
            BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal) <<  "Number of steps: " << _totStps.at(0); 
            */
            writeProperties();
            std::string simmgr_error_simmgr_info = ex.what();
            /* Logs temporarily disabled
            BOOST_LOG_SEV(simmgr_lg::get(), simmgr_critical) << "SimManger simmgr_error: " + simmgr_error_simmgr_info;
            */
            throw;
      }
}
void SimManager::writeProperties()
{
      /* Logs temporarily disabled

      {
      BOOST_LOG_SCOPED_LOGGER_TAG(simmgr_lg::get(),"Tag", std::string, "computationTime");
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal) << "Geforderte Simulationszeit:                        " << _tEnd ;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Rechenzeit in Sekunden:                 " << (_tClockEnd-_tClockStart);
      }
      BOOST_LOG_SCOPED_LOGGER_TAG(simmgr_lg::get(),"SimTag", std::string, "sim info");

      // Zeit 
      if(_settings->_globalSettings->bEndlessSim)
      {
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)<< "Geforderte Simulationszeit: endlos";
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Rechenzeit:                 " << (_tClockEnd-_tClockStart);
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Endzeit Toleranz:           " <<_config->getSimControllerSettings()->dTendTol;
      }
      else
      {
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)       << "Geforderte Simulationszeit: " << _tEnd ;
      //_infoStream << "Rechenzeit:                 " << (_tClockEnd-_tClockStart);
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Rechenzeit:                 " << (_tClockEnd-_tClockStart);
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Endzeit Toleranz:           " <<_config->getSimControllerSettings()->dTendTol;
      }

      if(_settings->_globalSettings->bRealtimeSim)
      {
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)<< "Echtzeit Simulationszeit aktiv:";
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Faktor:                 " << (_settings->_globalSettings->dRealtimeFactor);
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Aktive Rechenzeit (Pause Zeit):           " << (_tClockEnd-_tClockStart-_dataPool->getPauseDelay()) <<"(" << _dataPool->getPauseDelay() << ")";
      }
      if(_dimSolver == 1)
      {
      if(!(_solver->getSolverStatus() & ISolver::ERROR_STOP))
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)       << "Simulation erfolgreich.";
      else
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Fehler bei der Simulation!";

      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Schritte insgesamt des Solvers:   " << _totStps.at(0);
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Akzeptierte Schritte des Solvers: " << _accStps.at(0);
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Verworfene Schritte  des Solvers: " << _rejStps.at(0);

      // Solver-Properties
      _solver->writeSimulationInfo(os);

      }
      else
      {
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Anzahl Solver: " <<  _dimSolver << "  ";

      if(_completelyDecoupledSystems || !(_settings->bDynCouplingStepSize))
      {
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Koppelschrittweitensteuerung: fix ";
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Ausgabeschrittweite:          " << _config->getGlobalSettings()->gethOutput();
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Koppelschrittweite:           " << _settings->dHcpl ;

      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Anzahl Koppelschritte: " << _totCouplStps ;

      if(abs(_settings->_globalSettings->tEnd - _tEnd) < 10*UROUND)
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Integration erfolgreich. IDID= " << _idid << "  ";
      else
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Solver run time simmgr_error. ";

      }
      else
      {
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Koppelschrittweitensteuerung:            dynamisch";
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Ausgabeschrittweite:                     " << _config->getGlobalSettings()->gethOutput();
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Koppelschrittweite für nächsten Schritt: " << _H ;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)   << "Maximal verwendete Schrittweite:         " << _Hmax ;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)   << "Minimal verwendete Schrittweite:         " << _Hmin ;

      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)   << "Obere Grenze für Schrittweite:           " << _settings->dHuplim;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)   << "Untere Grenze für Schrittweite:          " << _settings->dHlowlim;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "k-Faktor für Schrittweite:               " << _settings->dK;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Savety-Faktor:                           " << _settings->dC;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Upscale-Faktor:                          " << _settings->dCmax;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Downscale-Faktor:                        " << _settings->dCmin;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Fehlertoleranz:                          " << _settings->dErrTol;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Fehlertoleranz für Single Step:          " << _settings->dSingleStepTol;

      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Anzahl Koppelschritte insgesamt:         " << _totCouplStps ;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Anzahl Einfach-Schritte:                 " << _singleStps ;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Davon akzeptierte Schritte:              " << _accCouplStps;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Davon verworfene Schritte:               " << _rejCouplStps ;

      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Max. nacheinander verwerfbare Schritte:  " << _settings->iMaxRejSteps ;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Max. nacheinander verworfene Schritte:   " << _rejCouplStpsRow ;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Zeitpunkt meiste verworfene Schritte:    " << _tRejCouplStpsRow ;

      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Anfangsschrittweite:                     " << _Hinit;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "bei einem Fehler:                        " << _simmgr_errorInit ;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "nach verworfenen Schritten:              " << _rejCouplStpsInit ;

      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Wenn Fehler knapp unter 1+ErrTol bei 0 verworf. Schritte, dann war Anfangsschrittweite gut gewählt.\n\n";

      if(_idid == 0 && (abs(_settings->_globalSettings->tEnd - _tEnd) < 10*UROUND))
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Integration erfolgreich. IDID= " << _idid << "\n\n";
      else if(_idid == -1)
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Integration abgebrochen. Fehlerbetrag zu groß (ev. Kopplung zu starr?). IDID= " << _idid ;
      else if(_idid == -2)
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Integration abgebrochen. Mehr als " << _settings->iMaxRejSteps << " dirket nacheinander verworfenen Schritte. IDID= " << _idid ;
      else if(_idid == -3)
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Integration abgebrochen. Koppelschrittweite kleiner als " << _settings->dHlowlim << ". IDID= " << _idid ;
      else
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Solver run time simmgr_error";

      }

      // Schritte der Solver
      for(int i=0; i<_dimSolver; ++i)
      {
      if(!(_solver[i]->getSolverStatus() & ISolver::ERROR_STOP))
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Simulation mit Solver[" << i << "] erfolgreich." ;
      else
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Fehler bei der Simulation in Solver[" << i << "]!" ;

      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Schritte insgesamt Solver[" << i << "]:   " <<  _totStps.at(i);
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Akzeptierte Schritte Solver[" << i << "]: " << _accStps.at(i) ;
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "Verworfene Schritte  Solver[" << i << "]: " << _rejStps.at(i);

      }

      // Solver-Properties
      for(int i=0; i<_dimSolver; ++i)
      {
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "-----------------------------------------";
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal)      << "simmgr_info Ausgabe Solver[" << i << "]";

      _solver[i]->writeSimulationInfo(os);
      }
      }

      */

}


void SimManager::computeEndTimes(std::vector<std::pair<double,int> > &tStopsSub)
{      
      boost::shared_ptr<ITime> timeevent_system = boost::dynamic_pointer_cast<ITime>(_mixed_system);
      int
            counterTimes = 0,
            counterEvents = 0;
      time_event_type                  timeEventPairs;                        ///<             - Beinhaltet Frequenzen und Startzeit der Time-Events
      _writeFinalState = true;

      if(tStopsSub.size()==0)
      {
            timeevent_system->getTimeEvent(timeEventPairs);
            std::vector<std::pair<double,double> >::iterator iter;
            iter = timeEventPairs.begin();
            for(; iter != timeEventPairs.end(); ++iter)
            {
                  if( iter->second != 0)
                  {
                        counterTimes = 0;
                        if (iter->first <= UROUND)
                        {
                              _timeeventcounter[counterEvents]++;
                              counterTimes++;
                              _solverTask = ISolver::SOLVERCALL(_solverTask | ISolver::RECALL);
                        }
                        while(iter->first + counterTimes * (iter->second) < (_tEnd +_config->getSimControllerSettings()->dTendTol))
                        {
                              tStopsSub.push_back(std::make_pair(iter->first + counterTimes * (iter->second),counterEvents));
                              counterTimes++;
                        }
                  }
                  else
                  {
                        if (iter->first <= UROUND)
                        {
                              _timeeventcounter[counterEvents]++;
                              counterTimes++;
                              _solverTask = ISolver::SOLVERCALL(_solverTask |ISolver::RECALL);
                        }else
                        {
                              if (iter->first <= _tEnd)
                                    tStopsSub.push_back(std::make_pair(iter->first,counterEvents));
                        }
                  }
                  counterEvents++;
            } // end for iter tStops
            sort(tStopsSub.begin(),tStopsSub.end());
            if (tStopsSub.size() ==0)
            {
                  tStopsSub.push_back(std::make_pair(_tEnd,0));
                  _writeFinalState = false;                  
            }
      } // end if endlessSim
      else
      {
            tStopsSub.erase(tStopsSub.begin(),tStopsSub.end());
            std::vector<std::pair<double,double> >::iterator iter;
            iter = timeEventPairs.begin();
            for(; iter != timeEventPairs.end(); ++iter)
            {
                  if( iter->second != 0)
                  {
                        counterTimes = 1;
                        if (abs(iter->first) <= UROUND)
                        {
                              counterTimes++;
                              _solverTask = ISolver::SOLVERCALL(_solverTask | ISolver::RECALL);
                        }
                        while(_tStart + iter->first + counterTimes * (iter->second) < _tEnd +_config->getSimControllerSettings()->dTendTol)
                        {
                              tStopsSub.push_back(std::make_pair(_tStart + iter->first + counterTimes * (iter->second),counterEvents));
                              counterTimes++;
                        }
                  }
                  else
                  {
                        if (iter->first < _tStart)
                        {
                              continue;
                        }else
                        {
                              if (iter->first <= _tEnd)
                                    tStopsSub.push_back(std::make_pair(iter->first,counterEvents));
                              if (abs(iter->first) <= UROUND)
                                    _solverTask = ISolver::SOLVERCALL(_solverTask |ISolver::RECALL);
                        }
                  }
                  counterEvents++;
            } // end for iter tStops
            sort(tStopsSub.begin(),tStopsSub.end());
            if (tStopsSub.size() ==0)
            {
                  tStopsSub.push_back(std::make_pair(_tEnd,0));
                  _writeFinalState = false;                  
            }
      }
}




void SimManager::runSingleProcess()
{
      
      boost::shared_ptr<IEvent> event_system = boost::dynamic_pointer_cast<IEvent>(_mixed_system);
      boost::shared_ptr<IContinuous> cont_system = boost::dynamic_pointer_cast<IContinuous>(_mixed_system);
      boost::shared_ptr<ITime> timeevent_system = boost::dynamic_pointer_cast<ITime>(_mixed_system);
      double 
            startTime,
            endTime,
            *zeroVal_0,
            *zeroVal_new;
      int 
            dimZeroF;

      std::vector<std::pair<double,int> >
            tStopsSub;

      _H =_tEnd;
      _solverTask = ISolver::SOLVERCALL(_solverTask | ISolver::RECORDCALL);
      _solver->setStartTime(_tStart);
      _solver->setEndTime(_tEnd);
     
    _solver->solve(_solverTask);
      _solverTask = ISolver::SOLVERCALL(_solverTask ^ ISolver::RECORDCALL);
      /* Logs temporarily disabled
      BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal) <<"Run single process." ; */
      // Zeitinvervall speichern
      //_H =_tEnd - _tStart;

  

            memset(_timeeventcounter,0,_dimtimeevent*sizeof(int));
            computeEndTimes(tStopsSub);
            _tStops.push_back(tStopsSub);
            dimZeroF = event_system->getDimZeroFunc();
            zeroVal_new = new double[dimZeroF];
            timeevent_system->setTime(_tStart);
          if (_dimtimeevent)
          {
             timeevent_system->handleTimeEvent(_timeeventcounter);
          }
            cont_system->evaluate(IContinuous::CONTINUOUS);      // vxworksupdate
            event_system->getZeroFunc(zeroVal_new);

            for(int i=0;i<_dimZeroFunc;i++)
                  _events[i] = bool(zeroVal_new[i]);
            _mixed_system->handleSystemEvents(_events);
      // Reset the time-events
      if (_dimtimeevent)
          {
             timeevent_system->handleTimeEvent(_timeeventcounter);
          }


            std::vector<std::pair<double,int> >::iterator iter;
            iter = _tStops[0].begin();
            /* time measurement temporary disabled
            // Startzeit messen
            _tClockStart = Time::Time().getSeconds();
            */
            startTime = _tStart;
            bool user_stop = false;
           
      while(_continueSimulation)
            {
                  for(; iter != _tStops[0].end(); ++iter)
                  {
                        endTime = iter->first;
                        if (endTime - startTime < UROUND)
                        {
                              startTime = endTime;
                              _timeeventcounter[iter->second]++;
                              timeevent_system->handleTimeEvent(_timeeventcounter);
                              cont_system->evaluate(IContinuous::CONTINUOUS);   // vxworksupdate
                              event_system->getZeroFunc(zeroVal_new);
                              for(int i=0;i<_dimZeroFunc;i++)
                                    _events[i] = bool(zeroVal_new[i]);
                              _mixed_system->handleSystemEvents(_events);
                //reset time-events
                timeevent_system->handleTimeEvent(_timeeventcounter);
                        }
                        else
                        {
                              // Setzen von Start- bzw. Endzeit und initial step size
                              _solver->setStartTime(startTime);
                              _solver->setEndTime(endTime);
                              _solver->setInitStepSize(_config->getGlobalSettings()->gethOutput());
                              _solver->solve(_solverTask);

                              if(_solverTask & ISolver::FIRST_CALL)
                              {
                                    _solverTask = ISolver::SOLVERCALL(_solverTask ^ ISolver::FIRST_CALL);
                                    _solverTask = ISolver::SOLVERCALL(_solverTask | ISolver::RECALL);
                              }
                              startTime = endTime;
                              if (_dimtimeevent)
                              {
                                    _timeeventcounter[iter->second]++;
                                    timeevent_system->handleTimeEvent(_timeeventcounter);
                                    cont_system->evaluate(IContinuous::CONTINUOUS);   // vxworksupdate
                                    event_system->getZeroFunc(zeroVal_new);
                                    for(int i=0;i<_dimZeroFunc;i++)
                                          _events[i] = bool(zeroVal_new[i]);
                                    _mixed_system->handleSystemEvents(_events);
                  //reset time-events
                    timeevent_system->handleTimeEvent(_timeeventcounter);
                              }

                        }


                        user_stop = (_solver->getSolverStatus() & ISolver::USER_STOP);
                        if (user_stop)
                              break;
                  } // end for time events
                  if (abs(_tEnd-endTime) >_config->getSimControllerSettings()->dTendTol && !user_stop)
                  {
                        startTime = endTime;
                        _solver->setStartTime(startTime);
                        _solver->setEndTime(_tEnd);
                        _solver->setInitStepSize(_config->getGlobalSettings()->gethOutput());
                        _solver->solve(_solverTask);
                        // In _solverTask FIRST_CALL Bit löschen und RECALL Bit setzen
                        if(_solverTask & ISolver::FIRST_CALL)
                        {
                              _solverTask = ISolver::SOLVERCALL(_solverTask ^ ISolver::FIRST_CALL);
                              _solverTask = ISolver::SOLVERCALL(_solverTask | ISolver::RECALL);
                        }
                        if (user_stop)
                              break;
                  } // end if weiter nach Time Events
                  else // Event am Schluss recorden.
                  {
                        if(_writeFinalState)
                        {      
                              _solverTask = ISolver::SOLVERCALL(ISolver::RECORDCALL);
                              _solver->solve(_solverTask);
                        }
                  }

                  // Beendigung der Simulation
                  if((!(_config->getGlobalSettings()->useEndlessSim()))
                        || (_solver->getSolverStatus() & ISolver::SOLVERERROR) 
                        || (_solver->getSolverStatus() & ISolver::USER_STOP) )
                  {
                        _continueSimulation = false; 
                  }

                  // Endlossimulation
                  else
                  {
                        // Zeitinvervall hochzählen
                        _tStart = _tEnd;
                        _tEnd += _H;

                        computeEndTimes(tStopsSub);
                        _tStops.push_back(tStopsSub);
                        if (_dimtimeevent)
                        {      
                              if(zeroVal_new)
                              {
                                    timeevent_system->handleTimeEvent(_timeeventcounter);
                                    cont_system->evaluate(IContinuous::CONTINUOUS);   // vxworksupdate
                                    event_system->getZeroFunc(zeroVal_new);
                                    for(int i=0;i<_dimZeroFunc;i++)
                                          _events[i] = bool(zeroVal_new[i]);
                                    _mixed_system->handleSystemEvents(_events);
                  //reset time-events
                  timeevent_system->handleTimeEvent(_timeeventcounter);
                              }
                        }

                        iter = _tStops[0].begin();
                  }

            } // end while continue


            if(zeroVal_new)
                  delete [] zeroVal_new;

} // end singleprocess