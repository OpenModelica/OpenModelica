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
  AddComponentCommand(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, QPointF position, ElementInfo *pComponentInfo,
                      bool addObject, bool openingClass, GraphicsView *pGraphicsView, UndoCommand *pParent = 0);
  Element* getComponent() {return mpDiagramComponent;}
  void redoInternal();
  void undo();
private:
  LibraryTreeItem *mpLibraryTreeItem;
  bool mAddObject;
  ElementInfo *mpComponentInfo;
  Element *mpIconComponent;
  Element *mpDiagramComponent;
  GraphicsView *mpIconGraphicsView;
  GraphicsView *mpDiagramGraphicsView;
  GraphicsView *mpGraphicsView;
};

class UpdateComponentTransformationsCommand : public UndoCommand
{
public:
  UpdateComponentTransformationsCommand(Element *pComponent, Transformation oldTransformation, Transformation newTransformation,
                                        const bool positionChanged, const bool moveConnectorsTogether, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  Element *mpComponent;
  Transformation mOldTransformation;
  Transformation mNewTransformation;
  bool mPositionChanged;
  bool mMoveConnectorsTogether;
};

class DeleteComponentCommand : public UndoCommand
{
public:
  DeleteComponentCommand(Element *pComponent, GraphicsView *pGraphicsView, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  Element *mpComponent;
  GraphicsView *mpGraphicsView;
};

class UpdateConnectionCommand : public UndoCommand
{
public:
  UpdateConnectionCommand(LineAnnotation *pConnectionLineAnnotation, QString oldAnnotaton, QString newAnnotation, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
  void redrawConnectionWithAnnotation(QString const& annotation);
private:
  LineAnnotation *mpConnectionLineAnnotation;
  QString mOldAnnotation;
  QString mNewAnnotation;
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
  void updateTransistionWithNewConditions();
  void updateTransistionWithOldConditions();
  void redrawTransitionWithUpdateFunction(const QString& annotation, std::function<void()> updateFunction);
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

class UpdateInitialStateCommand : public UndoCommand
{
public:
  UpdateInitialStateCommand(LineAnnotation *pInitialStateLineAnnotation, QString oldAnnotaton, QString newAnnotation, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
  void redrawInitialStateWithAnnotation(QString const& annotation);
private:
  LineAnnotation *mpInitialStateLineAnnotation;
  QString mOldAnnotation;
  QString mNewAnnotation;
};

class UpdateCoordinateSystemCommand : public UndoCommand
{
public:
  UpdateCoordinateSystemCommand(GraphicsView *pGraphicsView, const ModelInstance::CoordinateSystem oldCoordinateSystem,
                                const ModelInstance::CoordinateSystem newCoordinateSystem, const bool copyProperties, const QString &oldVersion,
                                const QString &newVersion, const QString &oldUsesAnnotationString, const QString &newUsesAnnotationString, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  GraphicsView *mpGraphicsView;
  ModelInstance::CoordinateSystem mOldCoordinateSystem;
  ModelInstance::CoordinateSystem mNewCoordinateSystem;
  bool mCopyProperties;
  QString mOldVersion;
  QString mNewVersion;
  QString mOldUsesAnnotationString;
  QString mNewUsesAnnotationString;

  void updateCoordinateSystem(const ModelInstance::CoordinateSystem coordinateSystem);
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

class OMSimulatorUndoCommand : public UndoCommand
{
public:
  OMSimulatorUndoCommand(const QString &modelName, const QString &oldSnapshot, const QString &newSnapshot, const QString &editedCref, const bool doSnapShot,
                         const bool switchToEdited, const QString oldEditedCref, const QString newEditedCref, const QString &commandText, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  QString mModelName;
  QString mOldSnapshot;
  QString mNewSnapshot;
  QString mEditedCref;
  bool mDoSnapShot;
  bool mSwitchToEdited;
  QString mOldEditedCref;
  QString mNewEditedCref;
  QStringList mExpandedLibraryTreeItemsList;
  QHash<QString, QPair<QStringList, QStringList> > mOpenedModelWidgetsAndSelectedElements;

  void switchToEditedModelWidget();
};

class OMCUndoCommand : public UndoCommand
{
public:
  OMCUndoCommand(LibraryTreeItem *pLibraryTreeItem, const ModelInfo &oldModelInfo, const ModelInfo &newModelInfo, const QString &commandText,
                 bool skipGetModelInstance = false, UndoCommand *pParent = 0);
  void redoInternal();
  void undo();
private:
  LibraryTreeItem *mpLibraryTreeItem;
  LibraryTreeItem *mpParentContainingLibraryTreeItem;
  QString mOldModelText;
  ModelInfo mOldModelInfo;
  QString mNewModelText;
  ModelInfo mNewModelInfo;
  bool mSkipGetModelInstance = false;
  bool mUndoCalledOnce = false;
};

#endif // COMMANDS_H
