/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef COMMANDS_H
#define COMMANDS_H

#include "Modeling/ModelWidgetContainer.h"
#include "OMS/ElementPropertiesDialog.h"
#include "OMS/SystemSimulationInformationDialog.h"

class UndoCommand : public QUndoCommand
{
public:
  UndoCommand(QUndoCommand *pParent = 0);
  void setFailed(bool failed) {mFailed = failed;}
  bool isFailed() const {return mFailed;}
  void setEnabled(bool enabled) {mEnabled = enabled;}
  bool isEnabled() const {return mEnabled;}
  void redo();
  virtual void redoInternal() = 0;
private:
  bool mFailed;
  bool mEnabled;
};

class AddShapeCommand : public UndoCommand
{
public:
  AddShapeCommand(ShapeAnnotation *pShapeAnnotation, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  ShapeAnnotation *mpShapeAnnotation;
  int mIndex;
};

class UpdateShapeCommand : public UndoCommand
{
public:
  UpdateShapeCommand(ShapeAnnotation *pShapeAnnotation, QString oldAnnotaton, QString newAnnotation, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  ShapeAnnotation *mpShapeAnnotation;
  QString mOldAnnotation;
  QString mNewAnnotation;
};

class DeleteShapeCommand : public UndoCommand
{
public:
  DeleteShapeCommand(ShapeAnnotation *pShapeAnnotation, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  ShapeAnnotation *mpShapeAnnotation;
  int mIndex;
};

class AddComponentCommand : public UndoCommand
{
public:
  AddComponentCommand(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, QPointF position, ComponentInfo *pComponentInfo,
                      bool addObject, bool openingClass, GraphicsView *pGraphicsView, UndoCommand *pParent = 0);
  Component* getComponent() {return mpDiagramComponent;}
  void redoInternal();
  void undo();
private:
  LibraryTreeItem *mpLibraryTreeItem;
  StringHandler::ModelicaClasses mType;
  bool mAddObject;
  ComponentInfo *mpComponentInfo;
  Component *mpIconComponent;
  Component *mpDiagramComponent;
  GraphicsView *mpIconGraphicsView;
  GraphicsView *mpDiagramGraphicsView;
  GraphicsView *mpGraphicsView;
};

class UpdateComponentTransformationsCommand : public UndoCommand
{
public:
  UpdateComponentTransformationsCommand(Component *pComponent, const Transformation &oldTransformation,
                                        const Transformation &newTransformation, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  Component *mpComponent;
  Component *mpIconOrDiagramComponent;
  Transformation mOldTransformation;
  Transformation mNewTransformation;
};

class UpdateComponentAttributesCommand : public UndoCommand
{
public:
  UpdateComponentAttributesCommand(Component *pComponent, const ComponentInfo &oldComponentInfo, const ComponentInfo &newComponentInfo,
                                   bool duplicate = false, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  Component *mpComponent;
  ComponentInfo mOldComponentInfo;
  ComponentInfo mNewComponentInfo;
  bool mDuplicate;
};

class UpdateComponentParametersCommand : public UndoCommand
{
public:
  UpdateComponentParametersCommand(Component *pComponent, QMap<QString, QString> oldComponentModifiersMap,
                                   QMap<QString, QString> oldComponentExtendsModifiersMap, QMap<QString, QString> newComponentModifiersMap,
                                   QMap<QString, QString> newComponentExtendsModifiersMap, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  Component *mpComponent;
  QMap<QString, QString> mOldComponentModifiersMap;
  QMap<QString, QString> mOldComponentExtendsModifiersMap;
  QMap<QString, QString> mNewComponentModifiersMap;
  QMap<QString, QString> mNewComponentExtendsModifiersMap;
};

class DeleteComponentCommand : public UndoCommand
{
public:
  DeleteComponentCommand(Component *pComponent, GraphicsView *pGraphicsView, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  Component *mpComponent;
  Component *mpIconComponent;
  Component *mpDiagramComponent;
  GraphicsView *mpIconGraphicsView;
  GraphicsView *mpDiagramGraphicsView;
  GraphicsView *mpGraphicsView;
  QStringList mParameterNames;
  QStringList mParameterValues;
};

class AddConnectionCommand : public UndoCommand
{
public:
  AddConnectionCommand(LineAnnotation *pConnectionLineAnnotation, bool addConnection, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  LineAnnotation *mpConnectionLineAnnotation;
  bool mAddConnection;
};

class UpdateConnectionCommand : public UndoCommand
{
public:
  UpdateConnectionCommand(LineAnnotation *pConnectionLineAnnotation, QString oldAnnotaton, QString newAnnotation, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  LineAnnotation *mpConnectionLineAnnotation;
  QString mOldAnnotation;
  QString mNewAnnotation;
};

class UpdateCompositeModelConnection : public UndoCommand
{
public:
  UpdateCompositeModelConnection(LineAnnotation *pConnectionLineAnnotation, CompositeModelConnection oldCompositeModelConnection,
                                 CompositeModelConnection newCompositeModelConnection, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  LineAnnotation *mpConnectionLineAnnotation;
  CompositeModelConnection mOldCompositeModelConnection;
  CompositeModelConnection mNewCompositeModelConnection;
};

class DeleteConnectionCommand : public UndoCommand
{
public:
  DeleteConnectionCommand(LineAnnotation *pConnectionLineAnnotation, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  LineAnnotation *mpConnectionLineAnnotation;
  GraphicsView *mpGraphicsView;
};

class AddTransitionCommand : public UndoCommand
{
public:
  AddTransitionCommand(LineAnnotation *pTransitionLineAnnotation, bool addTransition, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  LineAnnotation *mpTransitionLineAnnotation;
  bool mAddTransition;
};

class UpdateTransitionCommand : public UndoCommand
{
public:
  UpdateTransitionCommand(LineAnnotation *pTransitionLineAnnotation, QString oldCondition, bool oldImmediate, bool oldReset,
                          bool oldSynchronize, int oldPriority, QString oldAnnotaton, QString newCondition, bool newImmediate, bool newReset,
                          bool newSynchronize, int newPriority, QString newAnnotation, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  LineAnnotation *mpTransitionLineAnnotation;
  QString mOldCondition;
  bool mOldImmediate;
  bool mOldReset;
  bool mOldSynchronize;
  int mOldPriority;
  QString mOldAnnotation;
  QString mNewCondition;
  bool mNewImmediate;
  bool mNewReset;
  bool mNewSynchronize;
  int mNewPriority;
  QString mNewAnnotation;
};

class DeleteTransitionCommand : public UndoCommand
{
public:
  DeleteTransitionCommand(LineAnnotation *pTransitionLineAnnotation, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  LineAnnotation *mpTransitionLineAnnotation;
  GraphicsView *mpGraphicsView;
};

class AddInitialStateCommand : public UndoCommand
{
public:
  AddInitialStateCommand(LineAnnotation *pInitialStateLineAnnotation, bool addInitialState, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  LineAnnotation *mpInitialStateLineAnnotation;
  bool mAddInitialState;
};

class UpdateInitialStateCommand : public UndoCommand
{
public:
  UpdateInitialStateCommand(LineAnnotation *pInitialStateLineAnnotation, QString oldAnnotaton, QString newAnnotation, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  LineAnnotation *mpInitialStateLineAnnotation;
  QString mOldAnnotation;
  QString mNewAnnotation;
};

class DeleteInitialStateCommand : public UndoCommand
{
public:
  DeleteInitialStateCommand(LineAnnotation *pInitialStateLineAnnotation, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  LineAnnotation *mpInitialStateLineAnnotation;
  GraphicsView *mpGraphicsView;
};

class UpdateCoOrdinateSystemCommand : public UndoCommand
{
public:
  UpdateCoOrdinateSystemCommand(GraphicsView *pGraphicsView, CoOrdinateSystem oldCoOrdinateSystem, CoOrdinateSystem newCoOrdinateSystem,
                                bool copyProperties, QString oldVersion, QString newVersion, QString oldUsesAnnotationString,
                                QString newUsesAnnotationString, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  GraphicsView *mpGraphicsView;
  CoOrdinateSystem mOldCoOrdinateSystem;
  CoOrdinateSystem mNewCoOrdinateSystem;
  bool mCopyProperties;
  QString mOldVersion;
  QString mNewVersion;
  QString mOldUsesAnnotationString;
  QString mNewUsesAnnotationString;
};

class UpdateClassAnnotationCommand : public UndoCommand
{
public:
  UpdateClassAnnotationCommand(LibraryTreeItem *pLibraryTreeItem, QString oldAnnotation, QString newAnnotaiton, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  LibraryTreeItem *mpLibraryTreeItem;
  QString mOldAnnotation;
  QString mNewAnnotation;
};

class UpdateClassSimulationFlagsAnnotationCommand : public UndoCommand
{
public:
  UpdateClassSimulationFlagsAnnotationCommand(LibraryTreeItem *pLibraryTreeItem, QString oldSimulationFlags, QString newSimulationFlags,
                                              UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  LibraryTreeItem *mpLibraryTreeItem;
  QString mOldSimulationFlags;
  QString mNewSimulationFlags;
};

class UpdateSubModelAttributesCommand : public UndoCommand
{
public:
  UpdateSubModelAttributesCommand(Component *pComponent, const ComponentInfo &oldComponentInfo, const ComponentInfo &newComponentInfo,
                                  QStringList &parameterNames, QStringList &oldParameterValues,
                                  QStringList &newParameterValues, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  Component *mpComponent;
  ComponentInfo mOldComponentInfo;
  ComponentInfo mNewComponentInfo;
  QStringList mParameterNames;
  QStringList mOldParameterValues;
  QStringList mNewParameterValues;
};

class UpdateSimulationParamsCommand : public UndoCommand
{
public:
  UpdateSimulationParamsCommand(LibraryTreeItem *pLibraryTreeItem, QString oldStartTime, QString newStartTime, QString oldStopTime,
                                QString newStopTime, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  LibraryTreeItem *mpLibraryTreeItem;
  QString mOldStartTime;
  QString mNewStartTime;
  QString mOldStopTime;
  QString mNewStopTime;
};

class AlignInterfacesCommand : public UndoCommand
{
public:
  AlignInterfacesCommand(CompositeModelEditor *pCompositeModelEditor, QString fromInterface, QString toInterface,
                         QGenericMatrix<3,1,double> oldPos, QGenericMatrix<3,1,double> oldRot, QGenericMatrix<3,1,double> newPos,
                         QGenericMatrix<3,1,double> newRot, LineAnnotation *pConnectionLineAnnotation, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  CompositeModelEditor *mpCompositeModelEditor;
  QString mFromInterface;
  QString mToInterface;
  QGenericMatrix<3,1,double> mOldPos;
  QGenericMatrix<3,1,double> mOldRot;
  QGenericMatrix<3,1,double> mNewPos;
  QGenericMatrix<3,1,double> mNewRot;
  LineAnnotation *mpConnectionLineAnnotation;
};

class RenameCompositeModelCommand : public UndoCommand
{
public:
  RenameCompositeModelCommand(CompositeModelEditor *pCompositeModelEditor, QString oldCompositeModelName, QString newCompositeModelName,
                              UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  CompositeModelEditor *mpCompositeModelEditor;
  QString mOldCompositeModelName;
  QString mNewCompositeModelName;
};

class AddSystemCommand : public UndoCommand
{
public:
  AddSystemCommand(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, GraphicsView *pGraphicsView,
                   bool openingClass, oms_system_enu_t type, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  QString mName;
  LibraryTreeItem *mpLibraryTreeItem;
  QString mAnnotation;
  GraphicsView *mpGraphicsView;
  bool mOpeningClass;
  oms_system_enu_t mType;
  Component *mpComponent;
};

class AddSubModelCommand : public UndoCommand
{
public:
  AddSubModelCommand(QString name, QString path, LibraryTreeItem *pLibraryTreeItem, QString annotation, bool openingClass,
                     GraphicsView *pGraphicsView, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  QString mName;
  QString mPath;
  LibraryTreeItem *mpLibraryTreeItem;
  QString mAnnotation;
  bool mOpeningClass;
  Component *mpComponent;
  GraphicsView *mpGraphicsView;
};

class DeleteSubModelCommand : public UndoCommand
{
public:
  DeleteSubModelCommand(Component *pComponent, GraphicsView *pGraphicsView, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  Component *mpComponent;
  GraphicsView *mpGraphicsView;
  QString mName;
  QString mPath;
  QString mAnnotation;
};

class AddConnectorCommand : public UndoCommand
{
public:
  AddConnectorCommand(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, GraphicsView *pGraphicsView,
                      bool openingClass, oms_causality_enu_t causality, oms_signal_type_enu_t type, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  QString mName;
  LibraryTreeItem *mpLibraryTreeItem;
  QString mAnnotation;
  GraphicsView *mpIconGraphicsView;
  GraphicsView *mpDiagramGraphicsView;
  bool mOpeningClass;
  oms_causality_enu_t mCausality;
  oms_signal_type_enu_t mType;
  GraphicsView *mpGraphicsView;
  Component *mpIconComponent;
  Component *mpDiagramComponent;
};

class ElementPropertiesCommand : public UndoCommand
{
public:
  ElementPropertiesCommand(Component *pComponent, QString name, ElementProperties oldElementProperties,
                           ElementProperties newElementProperties, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  Component *mpComponent;
  ElementProperties mOldElementProperties;
  ElementProperties mNewElementProperties;
};

class AddIconCommand : public UndoCommand
{
public:
  AddIconCommand(QString icon, GraphicsView *pGraphicsView, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  QString mIcon;
  GraphicsView *mpGraphicsView;
};

class UpdateIconCommand : public UndoCommand
{
public:
  UpdateIconCommand(QString oldIcon, QString newIcon, ShapeAnnotation *pShapeAnnotation, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  QString mOldIcon;
  QString mNewIcon;
  ShapeAnnotation *mpShapeAnnotation;
};

class DeleteIconCommand : public UndoCommand
{
public:
  DeleteIconCommand(QString icon, GraphicsView *pGraphicsView, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  QString mIcon;
  GraphicsView *mpGraphicsView;
};

class OMSRenameCommand : public UndoCommand
{
public:
  OMSRenameCommand(LibraryTreeItem *pLibraryTreeItem, QString name, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  LibraryTreeItem *mpLibraryTreeItem;
  QString mOldName;
  QString mNewName;
};

class AddBusCommand : public UndoCommand
{
public:
  AddBusCommand(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, GraphicsView *pGraphicsView,
                bool openingClass, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  QString mName;
  LibraryTreeItem *mpLibraryTreeItem;
  QString mAnnotation;
  GraphicsView *mpIconGraphicsView;
  GraphicsView *mpDiagramGraphicsView;
  bool mOpeningClass;
  GraphicsView *mpGraphicsView;
  Component *mpIconComponent;
  Component *mpDiagramComponent;
};

class AddConnectorToBusCommand : public UndoCommand
{
public:
  AddConnectorToBusCommand(QString bus, QString connector, GraphicsView *pGraphicsView, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  QString mBus;
  QString mConnector;
  GraphicsView *mpGraphicsView;
};

class DeleteConnectorFromBusCommand : public UndoCommand
{
public:
  DeleteConnectorFromBusCommand(QString bus, QString connector, GraphicsView *pGraphicsView, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  QString mBus;
  QString mConnector;
  GraphicsView *mpGraphicsView;
};

class AddTLMBusCommand : public UndoCommand
{
public:
  AddTLMBusCommand(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, GraphicsView *pGraphicsView,
                   bool openingClass, oms_tlm_domain_t domain, int dimension, oms_tlm_interpolation_t interpolation, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  QString mName;
  LibraryTreeItem *mpLibraryTreeItem;
  QString mAnnotation;
  GraphicsView *mpIconGraphicsView;
  GraphicsView *mpDiagramGraphicsView;
  bool mOpeningClass;
  GraphicsView *mpGraphicsView;
  oms_tlm_domain_t mDomain;
  int mDimension;
  oms_tlm_interpolation_t mInterpolation;
  Component *mpIconComponent;
  Component *mpDiagramComponent;
};

class AddConnectorToTLMBusCommand : public UndoCommand
{
public:
  AddConnectorToTLMBusCommand(QString tlmBus, QString connectorName, QString connectorType, GraphicsView *pGraphicsView,
                              UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  QString mTLMBus;
  QString mConnectorName;
  QString mConnectorType;
  GraphicsView *mpGraphicsView;
};

class DeleteConnectorFromTLMBusCommand : public UndoCommand
{
public:
  DeleteConnectorFromTLMBusCommand(QString bus, QString connectorName, QString connectorType, GraphicsView *pGraphicsView,
                                   UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  QString mTLMBus;
  QString mConnectorName;
  QString mConnectorType;
  GraphicsView *mpGraphicsView;
};

class UpdateTLMParametersCommand : public UndoCommand
{
public:
  UpdateTLMParametersCommand(LineAnnotation *pConnectionLineAnnotation, const oms_tlm_connection_parameters_t oldTLMParameters,
                             const oms_tlm_connection_parameters_t newTLMParameters, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  LineAnnotation *mpConnectionLineAnnotation;
  oms_tlm_connection_parameters_t mOldTLMParameters;
  oms_tlm_connection_parameters_t mNewTLMParameters;
};

class SystemSimulationInformationCommand : public UndoCommand
{
public:
  SystemSimulationInformationCommand(TLMSystemSimulationInformation *pTLMSystemSimulationInformation,
                                     WCSCSystemSimulationInformation *pWCSCSystemSimulationInformation,
                                     LibraryTreeItem *pLibraryTreeItem, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  TLMSystemSimulationInformation *mpTLMSystemSimulationInformation;
  WCSCSystemSimulationInformation *mpWCSCSystemSimulationInformation;
  LibraryTreeItem *mpLibraryTreeItem;
};

#endif // COMMANDS_H
