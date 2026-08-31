/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#pragma once

#include <Core/Object/IObject.h>
#include <Core/Object/DCSAPI.h>

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

  typedef map<string,shared_ptr<IObject> > PtrMap;
  typedef vector< shared_ptr<IObject> > PtrVector;

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
  template <class T> static T& lookUp(const PtrMap& map, std::string obj_id, std::string param_id)
  {
    shared_ptr<T> pType;
    std::string id = obj_id + "." + param_id;
    PtrMap::const_iterator iter = map.find(id);
    if (iter== map.end())
      //throw SimModelException(SimModelException::WRONG_OBJECT_ID, "  ID: " + id);
      throw ModelicaSimulationError(MODEL_EQ_SYSTEM,string("WRONG_OBJECT_ID") +id );
    if (pType = dynamic_pointer_cast<T>(iter->second))
      return *pType.get();
    else
      //throw SimModelException(SimModelException::WRONG_OBJECT_TYPE, "  ID: " + id + "  type: " + typeid(pType).name() + " ; instead of: " + typeid(iter->second).name());
      throw ModelicaSimulationError(MODEL_EQ_SYSTEM,string("WRONG_OBJECT_ID") +id );
  };

protected:
    std::string _name;        ///< Userdefinierter Bezeichner.
};

typedef std::vector<Object*> ObjectPtrArray;
