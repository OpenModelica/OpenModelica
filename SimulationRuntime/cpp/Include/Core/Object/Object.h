// ObjectBase.h: Schnittstelle für die Klasse Object.
//
//////////////////////////////////////////////////////////////////////

#pragma once


#include <Object/IObject.h>
#include <Object/uid.h>
#include <Object/DCSAPI.h>

using std::ostream;
using std::endl;




/*****************************************************************************/
/**

Basisklasse aller Elemente. Hält einen userdefinierten Namen und
eine eindeutige ID als std::string.

*/

class Object : public IObject
{
public:

    typedef map<string,boost::shared_ptr<IObject> > PtrMap;
    typedef vector< boost::shared_ptr<IObject> > PtrVector;

    /// Zur Unterscheidung unterschiedlicher Berechnungsaufrufe in updateOutput bzw. writeOutput
    DCS_API Object(UIDSTR uid, string name);

    DCS_API virtual ~Object();

    DCS_API virtual void destroy();

    DCS_API virtual UIDSTR getUID() const;

    DCS_API virtual std::string getName() const;

    DCS_API virtual void setName(const string name);


    /// (Re-)Initialisiert das Objekt und schließt den Aufbau ab
    DCS_API virtual void init();






    /*! Sicheres Auslesen einer Object::PtrMap.
    \param map:  map in dem das gesuchte Objekt enthalten ist
    \param obj_id:    Bezeichner des übergeordneten Objektes
    \param param_id:    Innerhalb des Objektes verwendeter Bezeichners des Parameters
    */
    template <class T>  static T& lookUp(const PtrMap& map, std::string obj_id, std::string param_id)
    {
  boost::shared_ptr<T> pType;
  std::string id = obj_id + "." + param_id;
  PtrMap::const_iterator iter = map.find(id);
  if (iter== map.end())
      throw SimModelException(SimModelException::WRONG_OBJECT_ID, "  ID: " + id);
  if (pType = boost::dynamic_pointer_cast<T>(iter->second))
      return *pType.get();
  else
      throw SimModelException(SimModelException::WRONG_OBJECT_TYPE, "  ID: " + id + "  type: " + typeid(pType).name() + " ; instead of: " + typeid(iter->second).name());
    };



protected:
    UIDSTR
  _uid;        ///< Zur eindeutige Zuordnung zu Preprozessorobjekten.

    std::string
  _name;        ///< Userdefinierter Bezeichner.

};



/** Map allgemeiner Objekte (Bauteil-Objektliste).
Physikalische Anschlüsse, andere Container oder Funktionsobjekte, die
sich nicht auf einen ISimType<T> abbilden lassen, können als Objekte übergeben
werden. Die dazu verwendete Map verwendet als Schlüssel einen ID-String der
sich wie folgt zusammen setzt:

Physikalischer Anschluss
id = <Bauteilname>.<Bezeichner des Anschluss-Typs>_<fortlaufende Nummer>

allg. Objekte
id = <Bezeichner des Objekt-Typs>_<fortlaufende Nummer>

Innerhalb der create-Methode des Bauteils werden die Objekte von ObjectBase*
auf den entsprechenden Typ gecastet und dereferenziert um den eigentlichen
Konstruktor mit ein Referenz auf den "echten" Typen aufrufen zu können.
Übersichtshalber werden die Objekte in der folgenden Reihenfolge übergeben:

Physikalische Eingänge:
CInputHyd:  hydraulisch
CInputLin:  transl. mechanisch
CInputAng:  angular mechanisch
CInputMech3D:    räumlich mechanisch

Physikalische Ausgänge:
COutputHyd:  hydraulisch
COutputLin:  transl. mechanisch
COutputAng:  angular mechanisch
COutputMech3D:    räumlich mechanisch

Andere Objekte:
*/
typedef std::vector<Object*> ObjectPtrArray;


