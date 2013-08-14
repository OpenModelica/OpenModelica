// ObjectBase.h: Schnittstelle für die Klasse Object.
//
//////////////////////////////////////////////////////////////////////

#pragma once


#include <Object/IObject.h>

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
  DCS_API Object(string name);

    DCS_API virtual ~Object();

    DCS_API virtual void destroy();

  DCS_API virtual std::string getName() const;

    DCS_API virtual void setName(const string name);

  
  /// (Re-)Initialisiert das Objekt und schließt den Aufbau ab
  DCS_API virtual void initialize();






  /*! Sicheres Auslesen einer Object::PtrMap.
  \param map:    map in dem das gesuchte Objekt enthalten ist
  \param obj_id:  Bezeichner des übergeordneten Objektes
  \param param_id:  Innerhalb des Objektes verwendeter Bezeichners des Parameters
  */
  template <class T>  static T& lookUp(const PtrMap& map, std::string obj_id, std::string param_id)
  {
    boost::shared_ptr<T> pType;
    std::string id = obj_id + "." + param_id;
    PtrMap::const_iterator iter = map.find(id);
    if (iter== map.end())
      //throw SimModelException(SimModelException::WRONG_OBJECT_ID, "  ID: " + id);
      throw std::runtime_error("bla");
    if (pType = boost::dynamic_pointer_cast<T>(iter->second))
      return *pType.get();
    else
      //throw SimModelException(SimModelException::WRONG_OBJECT_TYPE, "  ID: " + id + "  type: " + typeid(pType).name() + " ; instead of: " + typeid(iter->second).name());
      throw std::runtime_error("bla");
  };



protected:

    std::string
        _name;        ///< Userdefinierter Bezeichner.

};



typedef std::vector<Object*> ObjectPtrArray;


