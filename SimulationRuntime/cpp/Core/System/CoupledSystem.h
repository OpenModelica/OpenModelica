

#pragma once
 #define BOOST_EXTENSION_SYSTEM_DECL BOOST_EXTENSION_EXPORT_DECL
 #define BOOST_EXTENSION_EVENTHANDLING_DECL BOOST_EXTENSION_EXPORT_DECL

#include <Object/Object.h>
#include <System/IContinuous.h>
#include <System/ICoupledSystem.h>
#include <System/IEvent.h>
#include <System/ITimeEvent.h>
#include <System/IMixedSystem.h>
#include <System/SystemDefaultImplementation.h>




/* Vorübergehen logs deaktiviert

enum system_severity_level
{
system_info,
system_normal,
system_notification,
system_warning,
system_error,
system_critical
};

//  Global logger declaration
//BOOST_LOG_INLINE_GLOBAL_LOGGER_CTOR_ARGS(test_lg, src::severity_logger< >)
BOOST_LOG_INLINE_GLOBAL_LOGGER_CTOR_ARGS(
system_lg,
src::severity_channel_logger_mt< >,
(keywords::severity = system_normal)(keywords::channel = "Core.system"))

*/


/*****************************************************************************/
/**

Verschaltung von Knoten, Kanten und Systemen zu einem gekoppelten System.
Das gekoppelte System dient entweder der Abbildung von Subsystemen 
innerhalb eines übergeordneten Systems oder als Instanz, die im Falle einer
Co-Simulation die Koppelung zwischen den von unterschiedlichen Solvern
gelösten Subsystemen beschreibt.
*/
class CoupledSystem : public ICoupledSystem, public IContinuous, public IEvent, public ITimeEvent, public IMixedSystem , public Object, public SystemDefaultImplementation
{
public:
    CoupledSystem(UIDSTR uid, std::string name,IGlobalSettings& globalSettings);

    virtual ~CoupledSystem();

    /// Fügt das übergebene Objekt als Knoten und/oder AcrossEdge hinzu
    void addAcross(IObject&);

    /// Fügt das übergebene Objekt als Knoten und/oder ThroughEdge hinzu
    void addThrough(IObject&);

    virtual void writeSimulationInfo();
private:
    void addObject(IObject& new_obj);        ///< fügt das Objekt der Objekt-Liste hinzu, sofern noch nicht vorhanden
    void addTimeEvent(ITimeEvent& new_event); ///< fügt ein Bauteil mit time event hinzu, sofern noch nicht vorhanden
    void addContinuous(IContinuous&);                    ///< fügt den Knoten der Knoten-Liste hinzu, sofern noch nicht vorhanden*/

    void addAcrossObject(IContinuous&);                ///< fügt die Kante der Across-Kanten-Liste hinzu
    void addAcrossObject(IEvent&);            ///< fügt die Kante der Event-Liste hinzu, sofern noch nicht vorhanden


    void addThroughObject(IContinuous&);            ///< fügt die Kante der Through-Kanten-Liste hinzu
    void addThroughObject(IEvent&);            ///< fügt die Kante der Event-Liste hinzu, sofern noch nicht vorhanden
    

public:
    // geerbt von Object
    //------------------------
    virtual void init();                                                ///< assemble für alle Kanten            


    // geerbt von IEdge
    //------------------------------
    virtual void setTime(const double& t);
    virtual void update(IContinuous::UPDATE action = IContinuous::UNDEF_UPDATE);            ///< für alle Kanten

    virtual int getDimTimeEvent() const;
    virtual void getTimeEvent(time_event_type& time_events);
    virtual void handleTimeEvent(int* time_events);

    // geerbt von IEvent
    //------------------------------
    virtual void handleEvent(const bool* events);
    /// Provide number (dimension) of zero functions
    virtual int getDimZeroFunc() const;
    virtual void giveZeroFunc(double* f);
    virtual void giveConditions(bool* c);
    virtual void checkConditions(const bool* events, bool all);
    ///Checks if a discrete variable has changed and triggered an event, returns true if a second event iteration is needed
    virtual bool checkForDiscreteEvents();    



    virtual void setVars(const double* y);
    virtual void giveVars(double* y);
    virtual void giveRHS(double* yd);

    /// Output routine (to be called by the solver after every successful integration step)
    virtual void writeOutput(const OUTPUT command = UNDEF_OUTPUT);
      /// Provide Jacobian
    virtual void giveJacobian(SparseMatrix& matrix);
    /// Provide mass matrix
    virtual void giveMassMatrix(SparseMatrix& matrix);
    /// Provide global constraint jacobian
    virtual void giveConstraint(SparseMatrix matrix);
    virtual IHistory* getHistory();
    /// Called to handle all  events occured at same time 
    virtual void handleSystemEvents(bool* events);
     //Saves all variables before an event is handled, is needed for the pre, edge and change operator
    virtual void saveAll();
    virtual void saveDiscreteVars();

private:

    
    

    

    std::vector<IObject*>        
        _allObjectArray;                ///< Jedes Objekt nur einmal

    


    std::vector<IContinuous*>            
        _continuousArray;

    std::vector<IContinuous*>            
        _acrossArray,                ///< Kanten + Systeme zur Berechnung der internen Across-Ausgänge
        _throughArray;                ///< Kanten + Systeme zur Berechnung der internen Through-Ausgänge


    std::vector<IEvent*>        
        _eventArray;                    ///< einmalig alle Kanten + Systeme die eine Nullstellenfunktion beinhalten

    
    std::vector<ITimeEvent*>            ///< Alle Bauteile mit einem time event
        _timeEvents;

    
    

    bool 
        _firstCall;

    double
        _tUpdateStart,                ///< Temporary        - Zeitmessung für update Aurufe Start
        _tUpdateCallEnd,                ///< Temporary        - Zeitmessung für Fortran Radau Aurufe  Ende
        _tUpdateCallTime,                    ///< Temüorary        - Zeitmeesung für Fortran Radau Aufrufe gesamte Zeit 
        _tGiveFuncStart,                ///< Temporary        - Zeitmessung für giveFunc Aufrufe Start
        _tGiveFuncCallEnd,                ///< Temporary        - Zeitmessung für Fortran Radau Aufrufe  Ende
        _tGiveFuncTime,                    ///< Temüorary        - Zeitmeesung für Fortran Radau Aufrufe gesamte Zeit 
        _tHandleEventStart,                ///< Temporary        - Zeitmessung für event Behandlung Start
        _tHandleEventCallEnd,                ///< Temporary        - Zeitmessung für event Behandlung Aufrufe  Ende
        _tHandleEventTime,                    ///< Temüorary        - Zeitmeesung für event Behandlung Aufrufe gesamte Zeit 
        _tSetVarsStart,                ///< Temporary        - Zeitmessung für event Behandlung Start
        _tSetVarsEnd,                ///< Temporary        - Zeitmessung für event Behandlung Aufrufe  Ende
        _tSetVarsTime,                    ///< Temüorary        - Zeitmeesung für event Behandlung Aufrufe gesamte Zeit 
        _tSetTimeStart,                ///< Temporary        - Zeitmessung für event Behandlung Start
        _tSetTimeEnd,                ///< Temporary        - Zeitmessung für event Behandlung Aufrufe  Ende
        _tSetTime;                    ///< Temüorary        - Zeitmeesung für event Behandlung Aufrufe gesamte Zeit 
};
