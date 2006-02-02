/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet,
Department of Computer and Information Science, PELAB
See also: www.ida.liu.se/projects/OpenModelica

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    
	* Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

    * Neither the name of Linköpings universitet nor the names of its contributors
      may be used to endorse or promote products derived from this software without
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

For more information about the Qt-library visit TrollTech:s webpage regarding
licence: http://www.trolltech.com/products/qt/licensing.html

------------------------------------------------------------------------------------
*/

#ifndef OMC_COMMUNICATOR_HPP_
#define OMC_COMMUNICATOR_HPP_

// MME includes
//#include "main.hpp"
//#include "exceptions.hpp"

// QT includes
#include <QtCore/QObject>

/*
// MME forward declarations
class AnnotationCompiler;
class PlacementAnnotation;
class DiagramLayerAnnotation;
class GraphicalLayerAnnotation;
class IconLayerAnnotation;
class Line;
class Modification;
*/

// QT forward declarations
//class QString; //AF, removed
//class QStringList; //AF, removed

// Omc communication interface
#include "omc_communication.h"

/**
 *
 */

/*
  struct ComponentDeclaration
  {
  ComponentDeclaration(QString type, QString name, QString comment) : type_(type), name_(name), comment_(comment) {};
  
  QString type_;
  QString name_;
  QString comment_;
  };
*/  
//------------------------------------------------------------------------------------

/**
 * \brief
 * The OmcCommunicator handles all low level communication with Omc.
 *
 * This class is a singleton class, use the static getInstance() member function to obtain a
 * reference to its instance.
 */
class OmcCommunicator : public QObject
{
  Q_OBJECT

public:
  ~OmcCommunicator();
   static OmcCommunicator& getInstance();
   
   bool establishConnection();
   void closeConnection();
   bool isConnected() const;
  
   QString callOmc(const QString& fnCall); 

/*
  void loadFile(const QString& file);
  bool loadClass(const QString& ref);
  void saveClass(const QString& file, const QString& ref);

  void createPackage(const QString& ref, const QStringList& baseClassRefs,
  const QString& comment, bool encapsulated, bool partial);
  void createConnector(const QString& ref, const QStringList& baseClassRefs,
  const QString& comment, bool encapsulated, bool partial);
  void createModel(const QString& ref, const QStringList& baseClassRefs,
  const QString& comment, bool encapsulated, bool partial);
  void createBlock(const QString& ref, const QStringList& baseClassRefs,
  const QString& comment, bool encapsulated, bool partial);
  void createRecord(const QString& ref, const QStringList& baseClassRefs,
  const QString& comment, bool encapsulated, bool partial);
  void createFunction(const QString& ref, const QStringList& baseClassRefs,
  const QString& comment, bool encapsulated, bool partial);
  
  bool deleteClass(const QString& ref);

  bool existsClass(const QString& ref);
  bool isBlock(const QString& ref);
  bool isClass(const QString& ref);
  bool isConnector(const QString& ref);
  bool isFunction(const QString& ref);
  bool isModel(const QString& ref);
  bool isPackage(const QString& ref);
  bool isRecord(const QString& ref);
  bool isType(const QString& ref);
  bool isPrimitive(const QString& ref);

  QString getClassNames(const QString& ref);

  IconLayerAnnotation* getIconLayerAnnotation(const QString& ref);
  DiagramLayerAnnotation* getDiagramLayerAnnotation(const QString& ref);
  void setClassLayerAnnotation(const QString& ref, const QString& annotation);

  int getInheritanceCount(const QString& ref);
  QString getNthInheritedClass(const QString& ref, int index);

  int getComponentCount(const QString& ref);
  std::vector<ComponentDeclaration> getComponents(const QString& ref);
  Modification* getNthComponentModification(const QString& ref, int index, const QString& name);
  std::vector<PlacementAnnotation*> getComponentAnnotations(const QString& ref);
  
  void addComponent(const QString& name, const QString& type, const QString& ref,
  const QString& annotation);
  void updateComponent(const QString& name, const QString& type, const QString& ref,
  const QString& comment, const QString& annotation = "");
  void deleteComponent(const QString& name, const QString& ref);
  bool isProtected(const QString& name, const QString& ref);
  
  int getConnectionCount(const QString& ref);
  QString getNthConnection(const QString& ref, int index);
  Line* getNthConnectionAnnotation(const QString& ref, int index);
  
  void addConnection(const QString& sourceConnectorRef, const QString& destinationConnectorRef,
  const QString& ref, const QString& annotation = "");
  void updateConnection(const QString& sourceConnectorRef,
  const QString& destinationConnectorRef, const QString& ref, const QString& annotation);
  void deleteConnection(const QString& sourceConnectorRef,
  const QString& destinationConnectorRef, const QString& ref);
  
  QString list(const QString& ref);
  void quit();
  
  void updateClassDefinition(const QString& ref, const QString& definition);


signals:
  void omcInput(const QString&);
  void omcOutput(const QString&);
*/
private:
   // Enforce the singleon's uniqueness.
   OmcCommunicator();
   OmcCommunicator(const OmcCommunicator&);
   OmcCommunicator& operator=(const OmcCommunicator&);
   
//   QString callOmc(const QString& fnCall);

private:
   OmcCommunication_var omc_;
   //AnnotationCompiler* compiler_;
};

#endif

