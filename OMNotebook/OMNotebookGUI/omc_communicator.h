/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
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

