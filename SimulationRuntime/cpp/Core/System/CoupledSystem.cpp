

#include "stdafx.h"
#include "CoupledSystem.h"
/**Zeimessung vorübergehend deaktiviert #include <Core/Timer/Time.h>                        ///< für Zeitmessung*/
#include <Solver/IDAESolver.h>





CoupledSystem::CoupledSystem(UIDSTR uid, std::string name,IGlobalSettings& globalSettings)
    : Object(uid, name)
    , SystemDefaultImplementation(globalSettings)
{
    _firstCall = true;
}


CoupledSystem::~CoupledSystem()
{
}

// addObject
//------------------------
void CoupledSystem::addAcross(IObject& new_obj)
{

    if (IContinuous* con_obj = dynamic_cast<IContinuous*>(&new_obj))
        addContinuous(*con_obj);

    /*if (IContinuous* con_obj = dynamic_cast<IContinuous* >(&new_obj))
    addAcrossEdge(*p_edge);*/

    if (IEvent* p_event = dynamic_cast<IEvent*>(&new_obj))
        addAcrossObject(*p_event);
    if (ITimeEvent* p_time_event = dynamic_cast<ITimeEvent*>(&new_obj))
        addTimeEvent(*p_time_event);



    // Die Prüfung auf System entfällt, da ein System eine Vereinigung aus Knot, Edge und Event ist.

    // zusätzlich immer auch als allg. Objekt hinzufügen
    addObject(new_obj);
    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "Add across element "<< new_obj.getName(); */
}

void CoupledSystem::addThrough(IObject& new_obj)
{
    if (IContinuous* con_obj = dynamic_cast<IContinuous*>(&new_obj))
        addContinuous(*con_obj);

    /*if (IContinuous* con_obj = dynamic_cast<IContinuous* >(&new_obj))
    addThroughEdge(*p_edge);*/

    if (IEvent* p_event = dynamic_cast<IEvent*>(&new_obj))
        addThroughObject(*p_event);
    if (ITimeEvent* p_time_event = dynamic_cast<ITimeEvent*>(&new_obj))
        addTimeEvent(*p_time_event);


    // zusätzlich immer auch als allg. Objekt hinzufügen
    addObject(new_obj);
    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "Add trough element "<< new_obj.getName();*/
}
void CoupledSystem::getTimeEvent(time_event_type& time_events)
{
    std::vector<ITimeEvent*>::iterator iter;
    for(iter=_timeEvents.begin();iter!=_timeEvents.end();++iter)
    {
        (*iter)->getTimeEvent(time_events);
    }
}
void CoupledSystem::handleTimeEvent(int* time_events)
{
    int n=0;
    std::vector<ITimeEvent*>::iterator iter = _timeEvents.begin();
    for (; iter != _timeEvents.end(); ++iter)
    {
        (*iter)->handleTimeEvent(&time_events[n]);
        n += (*iter)->getDimTimeEvent();
    }
    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "Handeld all time events";*/
}
void CoupledSystem::giveConditions(bool* c)
{
    int n=0;
    std::vector<IEvent*>::iterator iter = _eventArray.begin();
    for (; iter != _eventArray.end(); ++iter)
    {
        (*iter)->giveConditions(&c[n]);
        n += (*iter)->getDimZeroFunc();
    }
}
void CoupledSystem::addObject(IObject& new_obj)
{
    // nur hinzufügen sofern noch nicht vorhanden
    std::vector<IObject*>::iterator iter = _allObjectArray.begin();
    for (;iter != _allObjectArray.end(); ++iter)
        if (*iter == &new_obj)
            break;
    if (iter == _allObjectArray.end())
        _allObjectArray.push_back(&new_obj);
    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "Add  obj "<< new_obj.getName();*/
}

// addKnot
//------------------------
void CoupledSystem::addContinuous(IContinuous& new_knot)
{
    // nur hinzufügen sofern noch nicht vorhanden
    std::vector<IContinuous*>::iterator iter = _continuousArray.begin();
    for (; iter != _continuousArray.end(); ++iter)
        if (*iter == &new_knot)
            break;
    if (iter == _continuousArray.end())
        _continuousArray.push_back(&new_knot);
    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "Add knot  ";*/
}

// addAcrossEdge
//------------------------
void CoupledSystem::addAcrossObject(IContinuous& new_edge)
{
    _acrossArray.push_back(&new_edge);

    // nur hinzufügen sofern noch nicht vorhanden
    std::vector<IContinuous*>::iterator iter = _continuousArray.begin();
    for (; iter != _continuousArray.end(); ++iter)
        if (*iter == &new_edge)
            break;
    if (iter == _continuousArray.end())
        _continuousArray.push_back(&new_edge);
    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "Add across edge";*/
}

void CoupledSystem::addAcrossObject(IEvent& new_event)
{
    // nur hinzufügen sofern noch nicht vorhanden
    std::vector<IEvent*>::iterator iter = _eventArray.begin();
    for (; iter != _eventArray.end(); ++iter)
        if (*iter == &new_event)
            break;
    if (iter == _eventArray.end())
    {
        // enthält nur die Edges, die DimZeroF>0 liefern
        int n = new_event.getDimZeroFunc();
        if (n>0)
        {
            _eventArray.push_back(&new_event);
            _dimZeroFunc += n;
        }
    }
    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "Add across edge";*/
}


// addThroughEdge
//------------------------
void CoupledSystem::addThroughObject(IContinuous& new_edge)
{
    _throughArray.push_back(&new_edge);

    // nur hinzufügen sofern noch nicht vorhanden
    std::vector<IContinuous*>::iterator iter = _throughArray.begin();
    for (; iter != _throughArray.end(); ++iter)
        if (*iter == &new_edge)
            break;
    if (iter == _throughArray.end())
        _throughArray.push_back(&new_edge);
    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "Add through edge";*/

    // EventArray wird erst in assemble gefüllt
}

void CoupledSystem::addThroughObject(IEvent& new_event)
{
    // nur hinzufügen sofern noch nicht vorhanden (also noch nicht in addAcross hinzugefügt)
    std::vector<IEvent*>::iterator iter  = _eventArray.begin();
    for (; iter != _eventArray.end(); ++iter)
        if (*iter == &new_event)
            break;
    if (iter == _eventArray.end())
    {
        // enthält nur die Edges, die DimZeroF>0 liefern
        int n = new_event.getDimZeroFunc();
        if (n>0)
        {
            _eventArray.push_back(&new_event);
            _dimZeroFunc += n;
        }
    }
    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "Add through edge"; */
}
void CoupledSystem::addTimeEvent(ITimeEvent& new_event)
{
    std::vector<ITimeEvent*>::iterator iter;
    iter = _timeEvents.begin();
    for (; iter != _timeEvents.end(); ++iter)
        if (*iter == &new_event)
            break;
    if (iter == _timeEvents.end())
    {
        int n = new_event.getDimTimeEvent();
        if (n>0)
        {
            _timeEvents.push_back(&new_event);
            _dimTimeEvent += n;
        }
    }
    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "Add time event "; */
}





void CoupledSystem::init()
{
    _tGiveFuncTime = 0.0;
    _tUpdateCallTime = 0.0;
    _tHandleEventTime = 0.0;
    _tSetVarsTime =0.0;
    _tSetTime = 0.0;


    // Zusammenbau sämtlicher Objekte veranlassen
    /*Log vorübergehend deaktiviert  BOOST_LOG_SEV(system_lg::get(), system_normal) << "start assemble whole system";*/
    std::vector<IObject*>::iterator iter =  _allObjectArray.begin();
    for (; iter != _allObjectArray.end(); ++iter)
    {
        (*iter)->init();
    }
    update(IContinuous::UPDATE(ALL|IDAESolver::FIRST_CALL));

    iter = _allObjectArray.begin();
    for (; iter != _allObjectArray.end(); ++iter)
    {
        (*iter)->init();
    }

    std::vector<IContinuous*>::iterator con_iter  = _continuousArray.begin( ) ;
    for ( ; con_iter != _continuousArray.end( ) ; ++con_iter )
    {
        // Summe über alle Knoten bilden für jeden möglichen Index
        _dimVars  += (*con_iter)->getDimVars();
        _dimFunc += (*con_iter)->getDimRHS();
    }
    // System 1 mal auswerten, um sicher zu sein, dass Systemaufbau abgeschlossen ist.
    update(IContinuous::UPDATE(ALL|IDAESolver::FIRST_CALL));
    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_normal) << "assemble whole system ended";*/
    _event_handling.init(this,0);
    SystemDefaultImplementation::init();
}

// geerbt von IEvent
//------------------------------
void CoupledSystem::giveZeroFunc(double* f)
{
    int n=0;
    std::vector<IEvent*>::iterator iter = _eventArray.begin();
    for (; iter != _eventArray.end(); ++iter)
    {
        (*iter)->giveZeroFunc(&f[n]);
        n += (*iter)->getDimZeroFunc();
    }
    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "Returned zero functions";*/
}

void CoupledSystem::handleEvent(const bool* events)
{
    /*Zeitmessung vorübergehend deaktiviert _tHandleEventStart =  Time::Time().getSeconds();*/
    int n=0;
    std::vector<IEvent*>::iterator iter = _eventArray.begin();
    for (; iter != _eventArray.end(); ++iter)
    {
        (*iter)->handleEvent(&events[n]);
        n += (*iter)->getDimZeroFunc();
    }
    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "Handeld all events";*/
    /* Zeitmessung vorübergehend deaktiviert_tHandleEventCallEnd = Time::Time().getSeconds();
    _tHandleEventTime += (_tHandleEventCallEnd-_tHandleEventStart);*/
}


// geerbt von IEdge
//------------------------------
void CoupledSystem::setTime(const double& t)
{
    /* Zeitmessung vorübergehend deaktiviert_tSetTimeStart  = Time::Time().getSeconds();*/
    std::vector<IContinuous*>::iterator iter = _continuousArray.begin( ) ;
    for ( ; iter != _continuousArray.end( ) ; ++iter )
        (*iter)->setTime(t);
    /* Zeitmessung vorübergehend deaktiviert _tSetTimeEnd  = Time::Time().getSeconds();
    _tSetTime += ( _tSetTimeEnd -_tSetTimeStart);*/
}



void CoupledSystem::update(IContinuous::UPDATE action)
{
    /* Zeitmessung vorübergehend deaktiviert_tUpdateStart =  Time::Time().getSeconds();*/

    // setzt die Across und Through Bits auf 0
    int local_action = action & ~(ACROSS|THROUGH);
    if (action & ACROSS)
    {
        /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "start update all across elements ";*/
        // nur intern verschaltete Objekte müssen immer ihre Ausgänge aktualisieren
        /* Zeitmessung vorübergehend deaktiviertm_EdgeIter = _acrossArray.begin( ) ;*/
        std::vector<IContinuous*>::iterator across_iter = _acrossArray.begin();
        for ( ; across_iter != _acrossArray.end( ) ; ++across_iter )
            (*across_iter)->update(IContinuous::UPDATE(local_action|ACROSS));

    }
    if (action & THROUGH)
    {
        /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "start update all through elements "; */
        // nur intern verschaltete Objekte müssen immer ihre Ausgänge aktualisieren
        std::vector<IContinuous*>::iterator through_iter = _throughArray.begin( ) ;
        for ( ; through_iter != _throughArray.end( ) ; ++through_iter )
            (*through_iter)->update(IContinuous::UPDATE(local_action|THROUGH));

    }
    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "update all systems ended";*/
    /* Zeitmessung vorübergehend deaktiviert_tUpdateCallEnd = Time::Time().getSeconds();
    _tUpdateCallTime += (_tUpdateCallEnd- _tUpdateStart);*/
}

// geerbt von IKnot
//--------------------------------------
void CoupledSystem::setVars(const double* y)
{
    /* Zeitmessung vorübergehend deaktiviert _tSetVarsStart = Time::Time().getSeconds();*/

    if (_dimVars > 0)
    {
        unsigned int    n(0),    // Zeile im Zustandsvektor
            _n;        // Zwischengröße

        std::vector<IContinuous*>::iterator iter  = _continuousArray.begin( ) ;
        for ( ; iter != _continuousArray.end( ) ; ++iter )
        {
            if ( (_n=(*iter)->getDimVars()) > 0)
            {
                (*iter)->setVars(&y[n]);
                n += _n;
            }
        }
    }

    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "set all vars";*/
    /* Zeitmessung vorübergehend deaktiviert_tSetVarsEnd =   Time::Time().getSeconds();
    _tSetVarsTime += (_tSetVarsEnd -_tSetVarsStart);*/
}
/// Output routine (to be called by the solver after every successful integration step)
void CoupledSystem::writeOutput(const OUTPUT command)
{

}

/// Provide Jacobian
void CoupledSystem::giveJacobian(SparseMatrix& matrix)
{
    throw std::invalid_argument("giveJacobian is not implemented yet");
}

/// Provide mass matrix
void CoupledSystem::giveMassMatrix(SparseMatrix& matrix)
{
    throw std::invalid_argument("giveMassMatrix is not implemented yet");
}

/// Provide global constraint jacobian
void CoupledSystem::giveConstraint(SparseMatrix matrix)
{
    throw std::invalid_argument("giveConstraint is not implemented yet");
}

IHistory* CoupledSystem::getHistory()
{
    throw std::invalid_argument("getHistory is not implemented yet");
}
/// Called to handle all  events occured at same time 
void CoupledSystem::handleSystemEvents(bool* events)
{
    bool restart=true;
    int iter=0;
    checkConditions(events,false);
    handleEvent(events);

    while(restart && !(iter++ > 15))
    {

        //iterate and handle all events inside the eventqueue
        giveConditions(_conditions);
        restart=_event_handling.IterateEventQueue(_conditions);

    }
    saveAll();
    if(iter>_dimZeroFunc && restart ){
        throw std::runtime_error("Number of event iteration steps exceeded. " );}
}
//Saves all variables before an event is handled, is needed for the pre, edge and change operator
void CoupledSystem::saveAll()
{
}

void CoupledSystem::saveDiscreteVars()
{
}
void CoupledSystem::giveVars(double* y)
{


    if (_dimVars> 0)
    {
        unsigned int    n(0),    // Zeile im Zustandsvektor
            _n;

        std::vector<IContinuous*>::iterator iter  = _continuousArray.begin( ) ;
        for ( ; iter != _continuousArray.end( ) ; ++iter )
        {
            if ( (_n=(*iter)->getDimVars()) > 0)
            {
                (*iter)->giveVars(&y[n]);
                n += _n;
            }
        }
    }

    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "returned all vars";*/
}

void CoupledSystem::giveRHS(double* yd)
{
    /* Zeitmessung vorübergehend deaktiviert_tGiveFuncStart = Time::Time().getSeconds();*/

    if (_dimFunc > 0)
    {
        unsigned int    n(0),    // Zeile im Zustandsvektor
            _n;

        std::vector<IContinuous*>::iterator iter  = _continuousArray.begin( ) ;
        for ( ; iter != _continuousArray.end( ) ; ++iter )
        {
            if ( (_n=(*iter)->getDimRHS()) > 0)
            {
                (*iter)->giveRHS(&yd[n]);
                n += _n;
            }
        }
    }

    /*Log vorübergehend deaktiviert BOOST_LOG_SEV(system_lg::get(), system_info) << "returned rhs";*/
    /* Zeitmessung vorübergehend deaktiviert _tGiveFuncCallEnd  = Time::Time().getSeconds();
    _tGiveFuncTime += (_tGiveFuncCallEnd-_tGiveFuncStart);*/
}

int CoupledSystem::getDimTimeEvent() const
{
    return _dimTimeEvent;    
};
int CoupledSystem::getDimZeroFunc() const    
{
    return _dimZeroFunc;    
};



void CoupledSystem::checkConditions(const bool* events, bool all)
{
    int n=0;
    std::vector<IEvent*>::iterator iter = _eventArray.begin();
    for (; iter != _eventArray.end(); ++iter)
    {
        (*iter)->checkConditions(&events[n],all);
        n += (*iter)->getDimZeroFunc();
    }
}

bool CoupledSystem::checkForDiscreteEvents()
{
    //Komponenten haben noch keine diskrete Variablen
    return false;
}

void  CoupledSystem::writeSimulationInfo()
{
    /* logs vorübergehend deaktiviert
    BOOST_LOG_SCOPED_LOGGER_TAG(system_lg::get(),"Tag", std::string, "computationTime");
    BOOST_LOG_SEV(system_lg::get(), system_info) << "Zeit für gesamte event Behandlung in Sekunden:             " <<  _tHandleEventTime;
    BOOST_LOG_SEV(system_lg::get(), system_info) << "Zeit für gesamte update Aufrufe in Sekunden:                 "   <<  _tUpdateCallTime;
    BOOST_LOG_SEV(system_lg::get(), system_info) << "Zeit für gesamte Berechnung dere rechte Seite  in Sekunden:"    << _tGiveFuncTime;
    BOOST_LOG_SEV(system_lg::get(), system_info) << "Zeit für gesamte setzen der Zustände Seite  in Sekunden:   "    << _tSetVarsTime;
    BOOST_LOG_SEV(system_lg::get(), system_info) << "Zeit für gesamte setzen der Zeit in Sekunden:   "    << _tSetTime;
    */


}
