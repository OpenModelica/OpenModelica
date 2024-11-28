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

#include "Commands.h"
#include "MainWindow.h"
#include "DocumentationWidget.h"

#include <QDockWidget>
#include <QMessageBox>
#include <functional>

UndoCommand::UndoCommand(QUndoCommand *pParent)
  : QUndoCommand(pParent), mFailed(false), mEnabled(true)
{
  setFailed(false);
  setEnabled(true);
}

/*!
 * \brief UndoCommand::redo
 * Redo the command.
 */
void UndoCommand::redo()
{
  if (!isEnabled()) {
    return;
  }
  redoInternal();
}

AddShapeCommand::AddShapeCommand(ShapeAnnotation *pShapeAnnotation, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpShapeAnnotation = pShapeAnnotation;
  mIndex = -1;
  if (dynamic_cast<LineAnnotation*>(pShapeAnnotation)) {
    setText("Add Line Shape");
  } else if (dynamic_cast<PolygonAnnotation*>(pShapeAnnotation)) {
    setText("Add Polygon Shape");
  } else if (dynamic_cast<RectangleAnnotation*>(pShapeAnnotation)) {
    setText("Add Rectangle Shape");
  } else if (dynamic_cast<EllipseAnnotation*>(pShapeAnnotation)) {
    setText("Add Ellipse Shape");
  } else if (dynamic_cast<TextAnnotation*>(pShapeAnnotation)) {
    setText("Add Text Shape");
  } else if (dynamic_cast<BitmapAnnotation*>(pShapeAnnotation)) {
    setText("Add Bitmap Shape");
  }
}

/*!
 * \brief AddShapeCommand::redoInternal
 * redoInternal the AddShapeCommand.
 */
void AddShapeCommand::redoInternal()
{
  if (mpShapeAnnotation->isInheritedShape()) {
    mpShapeAnnotation->getGraphicsView()->addInheritedShapeToList(mpShapeAnnotation);
  } else {
    mpShapeAnnotation->getGraphicsView()->addShapeToList(mpShapeAnnotation, mIndex);
    mpShapeAnnotation->getGraphicsView()->deleteShapeFromOutOfSceneList(mpShapeAnnotation);
  }
  mpShapeAnnotation->getGraphicsView()->addItem(mpShapeAnnotation);
  mpShapeAnnotation->getGraphicsView()->addItem(mpShapeAnnotation->getOriginItem());
  mpShapeAnnotation->getGraphicsView()->setAddClassAnnotationNeeded(true);
  mpShapeAnnotation->getGraphicsView()->reOrderShapes();
}

/*!
 * \brief AddShapeCommand::undo
 * Undo the AddShapeCommand.
 */
void AddShapeCommand::undo()
{
  mIndex = mpShapeAnnotation->getGraphicsView()->deleteShapeFromList(mpShapeAnnotation);
  mpShapeAnnotation->getGraphicsView()->addShapeToOutOfSceneList(mpShapeAnnotation);
  mpShapeAnnotation->getGraphicsView()->removeItem(mpShapeAnnotation);
  mpShapeAnnotation->getGraphicsView()->removeItem(mpShapeAnnotation->getOriginItem());
  mpShapeAnnotation->getGraphicsView()->setAddClassAnnotationNeeded(true);
  mpShapeAnnotation->getGraphicsView()->reOrderShapes();
}

UpdateShapeCommand::UpdateShapeCommand(ShapeAnnotation *pShapeAnnotation, QString oldAnnotaton, QString newAnnotation, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpShapeAnnotation = pShapeAnnotation;
  mOldAnnotation = oldAnnotaton;
  mNewAnnotation = newAnnotation;
  if (dynamic_cast<LineAnnotation*>(pShapeAnnotation)) {
    setText("Update Line Shape");
  } else if (dynamic_cast<PolygonAnnotation*>(pShapeAnnotation)) {
    setText("Update Polygon Shape");
  } else if (dynamic_cast<RectangleAnnotation*>(pShapeAnnotation)) {
    setText("Update Rectangle Shape");
  } else if (dynamic_cast<EllipseAnnotation*>(pShapeAnnotation)) {
    setText("Update Ellipse Shape");
  } else if (dynamic_cast<TextAnnotation*>(pShapeAnnotation)) {
    setText("Update Text Shape");
  } else if (dynamic_cast<BitmapAnnotation*>(pShapeAnnotation)) {
    setText("Update Bitmap Shape");
  }
}

/*!
 * \brief UpdateShapeCommand::redoInternal
 * redoInternal the UpdateShapeCommand.
 */
void UpdateShapeCommand::redoInternal()
{
  mpShapeAnnotation->GraphicItem::setDefaults();
  mpShapeAnnotation->FilledShape::setDefaults();
  mpShapeAnnotation->setDefaults();
  mpShapeAnnotation->setUserDefaults();
  mpShapeAnnotation->parseShapeAnnotation(mNewAnnotation);
  /* If the shape is LineAnnotation then remove and draw the corner items
   * since they might have been changed in number based on the annotation.
   */
  LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(mpShapeAnnotation);
  if (pLineAnnotation) {
    pLineAnnotation->removeCornerItems();
    pLineAnnotation->drawCornerItems();
  }
  mpShapeAnnotation->setCornerItemsActiveOrPassive();
  mpShapeAnnotation->applyTransformation();
  mpShapeAnnotation->getGraphicsView()->setAddClassAnnotationNeeded(true);
}

/*!
 * \brief UpdateShapeCommand::undo
 * Undo the UpdateShapeCommand.
 */
void UpdateShapeCommand::undo()
{
  mpShapeAnnotation->GraphicItem::setDefaults();
  mpShapeAnnotation->FilledShape::setDefaults();
  mpShapeAnnotation->setDefaults();
  mpShapeAnnotation->setUserDefaults();
  mpShapeAnnotation->parseShapeAnnotation(mOldAnnotation);
  /* If the shape is LineAnnotation then remove and draw the corner items
   * since they might have been changed in number based on the annotation.
   */
  LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(mpShapeAnnotation);
  if (pLineAnnotation) {
    pLineAnnotation->removeCornerItems();
    pLineAnnotation->drawCornerItems();
  }
  mpShapeAnnotation->setCornerItemsActiveOrPassive();
  mpShapeAnnotation->applyTransformation();
  mpShapeAnnotation->getGraphicsView()->setAddClassAnnotationNeeded(true);
}

DeleteShapeCommand::DeleteShapeCommand(ShapeAnnotation *pShapeAnnotation, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpShapeAnnotation = pShapeAnnotation;
  mIndex = -1;
}

/*!
 * \brief DeleteShapeCommand::redoInternal
 * redoInternal the DeleteShapeCommand.
 */
void DeleteShapeCommand::redoInternal()
{
  mIndex = mpShapeAnnotation->getGraphicsView()->deleteShapeFromList(mpShapeAnnotation);
  mpShapeAnnotation->getGraphicsView()->addShapeToOutOfSceneList(mpShapeAnnotation);
  mpShapeAnnotation->getGraphicsView()->removeItem(mpShapeAnnotation);
  mpShapeAnnotation->getGraphicsView()->removeItem(mpShapeAnnotation->getOriginItem());
  mpShapeAnnotation->getGraphicsView()->setAddClassAnnotationNeeded(true);
  mpShapeAnnotation->getGraphicsView()->reOrderShapes();
}

/*!
 * \brief DeleteShapeCommand::undo
 * Undo the DeleteShapeCommand.
 */
void DeleteShapeCommand::undo()
{
  mpShapeAnnotation->getGraphicsView()->addShapeToList(mpShapeAnnotation, mIndex);
  mpShapeAnnotation->getGraphicsView()->deleteShapeFromOutOfSceneList(mpShapeAnnotation);
  mpShapeAnnotation->getGraphicsView()->addItem(mpShapeAnnotation);
  mpShapeAnnotation->getGraphicsView()->addItem(mpShapeAnnotation->getOriginItem());
  mpShapeAnnotation->getGraphicsView()->setAddClassAnnotationNeeded(true);
  mpShapeAnnotation->getGraphicsView()->reOrderShapes();
}

UpdateComponentTransformationsCommand::UpdateComponentTransformationsCommand(Element *pComponent, Transformation oldTransformation, Transformation newTransformation,
                                                                             const bool positionChanged, const bool moveConnectorsTogether, UndoCommand *pParent)
  : UndoCommand(pParent),
    mpComponent(pComponent),
    mOldTransformation(std::move(oldTransformation)),
    mNewTransformation(std::move(newTransformation)),
    mPositionChanged(positionChanged),
    mMoveConnectorsTogether(moveConnectorsTogether)
{
  setText(QString("Update Component %1 Transformations").arg(mpComponent->getName()));
}

/*!
 * \brief UpdateComponentTransformationsCommand::redoInternal
 * redoInternal the UpdateComponentTransformationsCommand.
 */
void UpdateComponentTransformationsCommand::redoInternal()
{
  ModelWidget *pModelWidget = mpComponent->getGraphicsView()->getModelWidget();
  if (mMoveConnectorsTogether && pModelWidget->getLibraryTreeItem()->isModelica()
      && ((mpComponent->getLibraryTreeItem() && mpComponent->getLibraryTreeItem()->isConnector())
          || (mpComponent->getModel() && mpComponent->getModel()->isConnector()))) {
    GraphicsView *pGraphicsView;
    if (mpComponent->getGraphicsView()->isIconView()) {
      pGraphicsView = pModelWidget->getDiagramGraphicsView();
    } else {
      pGraphicsView = pModelWidget->getIconGraphicsView();
    }
    Element *pComponent = pGraphicsView->getElementObject(mpComponent->getName());
    if (pComponent && (mOldTransformation == pComponent->mTransformation)) {
      pComponent->resetTransform();
      bool state = pComponent->flags().testFlag(QGraphicsItem::ItemSendsGeometryChanges);
      pComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, false);
      pComponent->setPos(0, 0);
      pComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, state);
      pComponent->setTransform(mNewTransformation.getTransformationMatrix());
      pComponent->mTransformation = mNewTransformation;
      pComponent->emitTransformChange(mPositionChanged);
    }
  }
  mpComponent->resetTransform();
  bool state = mpComponent->flags().testFlag(QGraphicsItem::ItemSendsGeometryChanges);
  mpComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, false);
  mpComponent->setPos(0, 0);
  mpComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, state);
  mpComponent->setTransform(mNewTransformation.getTransformationMatrix());
  mpComponent->mTransformation = mNewTransformation;
  mpComponent->emitTransformChange(mPositionChanged);
  mpComponent->emitTransformHasChanged();
  if (mpComponent->getGraphicsView()->isDiagramView()) {
    pModelWidget->setHandleCollidingConnectionsNeeded(true);
  }
}

/*!
 * \brief UpdateComponentTransformationsCommand::undo
 * Undo the UpdateComponentTransformationsCommand.
 */
void UpdateComponentTransformationsCommand::undo()
{
  ModelWidget *pModelWidget = mpComponent->getGraphicsView()->getModelWidget();
  if (mMoveConnectorsTogether && pModelWidget->getLibraryTreeItem()->isModelica()
      && ((mpComponent->getLibraryTreeItem() && mpComponent->getLibraryTreeItem()->isConnector())
          || (mpComponent->getModel() && mpComponent->getModel()->isConnector()))) {
    GraphicsView *pGraphicsView;
    if (mpComponent->getGraphicsView()->isIconView()) {
      pGraphicsView = pModelWidget->getDiagramGraphicsView();
    } else {
      pGraphicsView = pModelWidget->getIconGraphicsView();
    }
    Element *pComponent = pGraphicsView->getElementObject(mpComponent->getName());
    if (pComponent && (mpComponent->mTransformation == pComponent->mTransformation)) {
      pComponent->resetTransform();
      bool state = pComponent->flags().testFlag(QGraphicsItem::ItemSendsGeometryChanges);
      pComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, false);
      pComponent->setPos(0, 0);
      pComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, state);
      pComponent->setTransform(mOldTransformation.getTransformationMatrix());
      pComponent->mTransformation = mOldTransformation;
      pComponent->emitTransformChange(mPositionChanged);
    }
  }
  mpComponent->resetTransform();
  bool state = mpComponent->flags().testFlag(QGraphicsItem::ItemSendsGeometryChanges);
  mpComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, false);
  mpComponent->setPos(0, 0);
  mpComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, state);
  mpComponent->setTransform(mOldTransformation.getTransformationMatrix());
  mpComponent->mTransformation = mOldTransformation;
  mpComponent->emitTransformChange(mPositionChanged);
  mpComponent->emitTransformHasChanged();
  if (mpComponent->getGraphicsView()->isDiagramView()/* && pModelWidget->isNewApi()*/) {
    pModelWidget->setHandleCollidingConnectionsNeeded(true);
  }
}

DeleteComponentCommand::DeleteComponentCommand(Element *pComponent, GraphicsView *pGraphicsView, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpComponent = pComponent;
  mpGraphicsView = pGraphicsView;
}

/*!
 * \brief DeleteComponentCommand::redoInternal
 * redoInternal the DeleteComponentCommand.
 */
void DeleteComponentCommand::redoInternal()
{
  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  // if component is of connector type && containing class is Modelica type.
  if (mpComponent->getLibraryTreeItem() && mpComponent->getLibraryTreeItem()->isConnector() && pModelWidget->getLibraryTreeItem()->isModelica()) {
    // Connector type components exists on both icon and diagram views
    GraphicsView *pGraphicsView;
    if (mpGraphicsView->isIconView()) {
      pGraphicsView = mpGraphicsView->getModelWidget()->getDiagramGraphicsView();
    } else {
      pGraphicsView = mpGraphicsView->getModelWidget()->getIconGraphicsView();
    }
    Element *pComponent = pGraphicsView->getElementObject(mpComponent->getName());
    if (pComponent) {
      pGraphicsView->removeElementItem(pComponent);
      pGraphicsView->deleteElementFromList(pComponent);
      pGraphicsView->addElementToOutOfSceneList(pComponent);
      pComponent->emitDeleted();
    }
  }
  mpGraphicsView->removeElementItem(mpComponent);
  mpGraphicsView->deleteElementFromList(mpComponent);
  mpGraphicsView->addElementToOutOfSceneList(mpComponent);
  mpComponent->emitDeleted();
  mpGraphicsView->deleteElementFromClass(mpComponent);
}

/*!
 * \brief DeleteComponentCommand::undo
 * Undo the DeleteComponentCommand.
 */
void DeleteComponentCommand::undo()
{
  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  // if component is of connector type && containing class is Modelica type.
  if (mpComponent->getLibraryTreeItem() && mpComponent->getLibraryTreeItem()->isConnector() && pModelWidget->getLibraryTreeItem()->isModelica()) {
    // Connector type components exists on both icon and diagram views
    GraphicsView *pGraphicsView;
    if (mpGraphicsView->isIconView()) {
      pGraphicsView = mpGraphicsView->getModelWidget()->getDiagramGraphicsView();
    } else {
      pGraphicsView = mpGraphicsView->getModelWidget()->getIconGraphicsView();
    }
    Element *pComponent = pGraphicsView->getElementObject(mpComponent->getName());
    if (pComponent) {
      pGraphicsView->addElementItem(pComponent);
      pGraphicsView->addElementToList(pComponent);
      pGraphicsView->deleteElementFromOutOfSceneList(pComponent);
    }
  }
  mpGraphicsView->addElementItem(mpComponent);
  mpGraphicsView->addElementToList(mpComponent);
  mpGraphicsView->deleteElementFromOutOfSceneList(mpComponent);
  mpGraphicsView->addElementToClass(mpComponent);
}

AddConnectionCommand::AddConnectionCommand(LineAnnotation *pConnectionLineAnnotation, bool addConnection, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  mAddConnection = addConnection;
  setText(QString("Add Connection connect(%1, %2)").arg(mpConnectionLineAnnotation->getStartElementName(), mpConnectionLineAnnotation->getEndElementName()));

  mpConnectionLineAnnotation->drawCornerItems();
  mpConnectionLineAnnotation->setCornerItemsActiveOrPassive();
}

/*!
 * \brief AddConnectionCommand::redoInternal
 * redoInternal the AddConnectionCommand.
 */
void AddConnectionCommand::redoInternal()
{
  mpConnectionLineAnnotation->getGraphicsView()->addConnectionToView(mpConnectionLineAnnotation, false);
  if (mAddConnection) {
    if (!mpConnectionLineAnnotation->getGraphicsView()->addConnectionToClass(mpConnectionLineAnnotation)) {
      setFailed(true);
      return;
    }
  }
  mpConnectionLineAnnotation->getGraphicsView()->getModelWidget()->setHandleCollidingConnectionsNeeded(true);
}

/*!
 * \brief AddConnectionCommand::undo
 * Undo the AddConnectionCommand.
 */
void AddConnectionCommand::undo()
{
  mpConnectionLineAnnotation->getGraphicsView()->removeConnectionFromView(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->getGraphicsView()->deleteConnectionFromClass(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->getGraphicsView()->getModelWidget()->setHandleCollidingConnectionsNeeded(true);
}

UpdateConnectionCommand::UpdateConnectionCommand(LineAnnotation *pConnectionLineAnnotation, QString oldAnnotaton, QString newAnnotation, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  mOldAnnotation = oldAnnotaton;
  mNewAnnotation = newAnnotation;
  setText(QString("Update Connection connect(%1, %2)").arg(mpConnectionLineAnnotation->getStartElementName(), mpConnectionLineAnnotation->getEndElementName()));
}

/*!
 * \brief UpdateConnectionCommand::redoInternal
 * redoInternal the UpdateConnectionCommand.
 */
void UpdateConnectionCommand::redoInternal()
{
  redrawConnectionWithAnnotation(mNewAnnotation);
}

/*!
 * \brief UpdateConnectionCommand::undo
 * Undo the UpdateConnectionCommand.
 */
void UpdateConnectionCommand::undo()
{
  redrawConnectionWithAnnotation(mOldAnnotation);
}

void UpdateConnectionCommand::redrawConnectionWithAnnotation(QString const& annotation)
{
  auto updateFunction = std::bind(&LineAnnotation::updateConnectionAnnotation, mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->redraw(annotation, updateFunction);
}

DeleteConnectionCommand::DeleteConnectionCommand(LineAnnotation *pConnectionLineAnnotation, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  setText(QString("Delete Connection connect(%1, %2)").arg(mpConnectionLineAnnotation->getStartElementName(), mpConnectionLineAnnotation->getEndElementName()));
}

/*!
 * \brief DeleteConnectionCommand::redoInternal
 * redoInternal the DeleteConnectionCommand.
 */
void DeleteConnectionCommand::redoInternal()
{
  mpConnectionLineAnnotation->getGraphicsView()->removeConnectionFromView(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->getGraphicsView()->deleteConnectionFromClass(mpConnectionLineAnnotation);
}

/*!
 * \brief DeleteConnectionCommand::undo
 * Undo the DeleteConnectionCommand.
 */
void DeleteConnectionCommand::undo()
{
  mpConnectionLineAnnotation->getGraphicsView()->addConnectionToView(mpConnectionLineAnnotation, false);
  mpConnectionLineAnnotation->getGraphicsView()->addConnectionToClass(mpConnectionLineAnnotation, true);
}

AddTransitionCommand::AddTransitionCommand(LineAnnotation *pTransitionLineAnnotation, bool addTransition, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpTransitionLineAnnotation = pTransitionLineAnnotation;
  mAddTransition = addTransition;
  setText(QString("Add Transition transition(%1, %2)").arg(mpTransitionLineAnnotation->getStartElementName(), mpTransitionLineAnnotation->getEndElementName()));

  mpTransitionLineAnnotation->updateToolTip();
  mpTransitionLineAnnotation->drawCornerItems();
  mpTransitionLineAnnotation->setCornerItemsActiveOrPassive();
}

/*!
 * \brief AddTransitionCommand::redoInternal
 * redoInternal the AddTransitionCommand.
 */
void AddTransitionCommand::redoInternal()
{
  mpTransitionLineAnnotation->getGraphicsView()->addTransitionToView(mpTransitionLineAnnotation, false);
  if (mAddTransition) {
    mpTransitionLineAnnotation->getGraphicsView()->addTransitionToClass(mpTransitionLineAnnotation);
  }
}

/*!
 * \brief AddTransitionCommand::undo
 * Undo the AddTransitionCommand.
 */
void AddTransitionCommand::undo()
{
  mpTransitionLineAnnotation->getGraphicsView()->removeTransitionFromView(mpTransitionLineAnnotation);
  mpTransitionLineAnnotation->getGraphicsView()->deleteTransitionFromClass(mpTransitionLineAnnotation);
}

UpdateTransitionCommand::UpdateTransitionCommand(LineAnnotation *pTransitionLineAnnotation, QString oldCondition, bool oldImmediate,
                                                 bool oldReset, bool oldSynchronize, int oldPriority, QString oldAnnotaton,
                                                 QString newCondition, bool newImmediate, bool newReset, bool newSynchronize, int newPriority,
                                                 QString newAnnotation, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpTransitionLineAnnotation = pTransitionLineAnnotation;
  mOldCondition = oldCondition;
  mOldImmediate = oldImmediate;
  mOldReset = oldReset;
  mOldSynchronize = oldSynchronize;
  mOldPriority = oldPriority;
  mOldAnnotation = oldAnnotaton;
  mNewCondition = newCondition;
  mNewImmediate = newImmediate;
  mNewReset = newReset;
  mNewSynchronize = newSynchronize;
  mNewPriority = newPriority;
  mNewAnnotation = newAnnotation;
  setText(QString("Update Transition transition(%1, %2)").arg(mpTransitionLineAnnotation->getStartElementName(),
                                                              mpTransitionLineAnnotation->getEndElementName()));
}

/*!
 * \brief UpdateTransitionCommand::redoInternal
 * redoInternal the UpdateTransitionCommand.
 */
void UpdateTransitionCommand::redoInternal()
{
  redrawTransitionWithUpdateFunction(mNewAnnotation, std::bind(&UpdateTransitionCommand::updateTransistionWithNewConditions, this));
}

/*!
 * \brief UpdateTransitionCommand::undo
 * Undo the UpdateTransitionCommand.
 */
void UpdateTransitionCommand::undo()
{
  redrawTransitionWithUpdateFunction(mOldAnnotation, std::bind(&UpdateTransitionCommand::updateTransistionWithOldConditions, this));
}

void UpdateTransitionCommand::redrawTransitionWithUpdateFunction(const QString& annotation, std::function<void()> updateFunction)
{
  mpTransitionLineAnnotation->redraw(annotation, updateFunction);
}

void UpdateTransitionCommand::updateTransistionWithNewConditions()
{
  mpTransitionLineAnnotation->setProperties(mNewCondition, mNewImmediate, mNewReset, mNewSynchronize, mNewPriority);
  mpTransitionLineAnnotation->updateTransistion(mOldCondition, mOldImmediate, mOldReset, mOldSynchronize, mOldPriority);
}

void UpdateTransitionCommand::updateTransistionWithOldConditions()
{
  mpTransitionLineAnnotation->setProperties(mOldCondition, mOldImmediate, mOldReset, mOldSynchronize, mOldPriority);
  mpTransitionLineAnnotation->updateTransistion(mNewCondition, mNewImmediate, mNewReset, mNewSynchronize, mNewPriority);
}

DeleteTransitionCommand::DeleteTransitionCommand(LineAnnotation *pTransitionLineAnnotation, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpTransitionLineAnnotation = pTransitionLineAnnotation;
}

/*!
 * \brief DeleteTransitionCommand::redoInternal
 * redoInternal the DeleteTransitionCommand.
 */
void DeleteTransitionCommand::redoInternal()
{
  mpTransitionLineAnnotation->getGraphicsView()->removeTransitionFromView(mpTransitionLineAnnotation);
  mpTransitionLineAnnotation->getGraphicsView()->deleteTransitionFromClass(mpTransitionLineAnnotation);
}

/*!
 * \brief DeleteTransitionCommand::undo
 * Undo the DeleteTransitionCommand.
 */
void DeleteTransitionCommand::undo()
{
  mpTransitionLineAnnotation->getGraphicsView()->addTransitionToView(mpTransitionLineAnnotation, false);
  mpTransitionLineAnnotation->getGraphicsView()->addTransitionToClass(mpTransitionLineAnnotation);
}

AddInitialStateCommand::AddInitialStateCommand(LineAnnotation *pInitialStateLineAnnotation, bool addInitialState, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpInitialStateLineAnnotation = pInitialStateLineAnnotation;
  mAddInitialState = addInitialState;
  setText(QString("Add InitialState initialState(%1)").arg(mpInitialStateLineAnnotation->getStartElementName()));

  mpInitialStateLineAnnotation->setToolTip(QString("<b>initialState</b>(%1)").arg(mpInitialStateLineAnnotation->getStartElementName()));
  mpInitialStateLineAnnotation->drawCornerItems();
  mpInitialStateLineAnnotation->setCornerItemsActiveOrPassive();
}

/*!
 * \brief AddInitialStateCommand::redoInternal
 * redoInternal the AddInitialStateCommand.
 */
void AddInitialStateCommand::redoInternal()
{
  mpInitialStateLineAnnotation->getGraphicsView()->addInitialStateToView(mpInitialStateLineAnnotation, false);
  if (mAddInitialState) {
    mpInitialStateLineAnnotation->getGraphicsView()->addInitialStateToClass(mpInitialStateLineAnnotation);
  }
}

/*!
 * \brief AddInitialStateCommand::undo
 * Undo the AddInitialStateCommand.
 */
void AddInitialStateCommand::undo()
{
  mpInitialStateLineAnnotation->getGraphicsView()->removeInitialStateFromView(mpInitialStateLineAnnotation);
  mpInitialStateLineAnnotation->getGraphicsView()->deleteInitialStateFromClass(mpInitialStateLineAnnotation);
}

UpdateInitialStateCommand::UpdateInitialStateCommand(LineAnnotation *pInitialStateLineAnnotation, QString oldAnnotaton, QString newAnnotation, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpInitialStateLineAnnotation = pInitialStateLineAnnotation;
  mOldAnnotation = oldAnnotaton;
  mNewAnnotation = newAnnotation;
  setText(QString("Update InitialState initialState(%1)").arg(mpInitialStateLineAnnotation->getStartElementName()));
}

/*!
 * \brief UpdateInitialStateCommand::redoInternal
 * redoInternal the UpdateInitialStateCommand.
 */
void UpdateInitialStateCommand::redoInternal()
{
  redrawInitialStateWithAnnotation(mNewAnnotation);
}

/*!
 * \brief UpdateInitialStateCommand::undo
 * Undo the UpdateInitialStateCommand.
 */
void UpdateInitialStateCommand::undo()
{
  redrawInitialStateWithAnnotation(mOldAnnotation);
}

void UpdateInitialStateCommand::redrawInitialStateWithAnnotation(const QString& annotation)
{
  auto updateFunction = std::bind(&LineAnnotation::updateInitialStateAnnotation ,mpInitialStateLineAnnotation);
  mpInitialStateLineAnnotation->redraw(annotation, updateFunction);
}

DeleteInitialStateCommand::DeleteInitialStateCommand(LineAnnotation *pInitialStateLineAnnotation, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpInitialStateLineAnnotation = pInitialStateLineAnnotation;
}

/*!
 * \brief DeleteInitialStateCommand::redoInternal
 * redoInternal the DeleteInitialStateCommand.
 */
void DeleteInitialStateCommand::redoInternal()
{
  mpInitialStateLineAnnotation->getGraphicsView()->removeInitialStateFromView(mpInitialStateLineAnnotation);
  mpInitialStateLineAnnotation->getGraphicsView()->deleteInitialStateFromClass(mpInitialStateLineAnnotation);
}

/*!
 * \brief DeleteInitialStateCommand::undo
 * Undo the DeleteInitialStateCommand.
 */
void DeleteInitialStateCommand::undo()
{
  mpInitialStateLineAnnotation->getGraphicsView()->addInitialStateToView(mpInitialStateLineAnnotation, false);
  mpInitialStateLineAnnotation->getGraphicsView()->addInitialStateToClass(mpInitialStateLineAnnotation);
}

UpdateCoordinateSystemCommand::UpdateCoordinateSystemCommand(GraphicsView *pGraphicsView, const ModelInstance::CoordinateSystem oldCoordinateSystem,
                                                             const ModelInstance::CoordinateSystem newCoordinateSystem, bool copyProperties, const QString &oldVersion,
                                                             const QString &newVersion, const QString &oldUsesAnnotationString,
                                                             const QString &newUsesAnnotationString, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpGraphicsView = pGraphicsView;
  mOldCoordinateSystem = oldCoordinateSystem;
  mNewCoordinateSystem = newCoordinateSystem;
  mCopyProperties = copyProperties;
  mOldVersion = oldVersion;
  mNewVersion = newVersion;
  mOldUsesAnnotationString = oldUsesAnnotationString;
  mNewUsesAnnotationString = newUsesAnnotationString;
  setText(QString("Update %1 CoOrdinate System").arg(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure()));
}

/*!
 * \brief UpdateClassCoordinateSystemCommand::redoInternal
 * redoInternal the UpdateClassCoordinateSystemCommand.
 */
void UpdateCoordinateSystemCommand::redoInternal()
{
  updateCoordinateSystem(mNewCoordinateSystem);
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  // only add version and uses annotation to top level class.
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isTopLevel()) {
    // version
    QString versionAnnotation = QString("annotate=version(\"%1\")").arg(mNewVersion);
    if (pOMCProxy->addClassAnnotation(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), versionAnnotation)) {
      mpGraphicsView->getModelWidget()->getLibraryTreeItem()->mClassInformation.version = mNewVersion;
      // if documentation view is visible then update it
      if (MainWindow::instance()->getDocumentationDockWidget()->isVisible()) {
        MainWindow::instance()->getDocumentationWidget()->showDocumentation(mpGraphicsView->getModelWidget()->getLibraryTreeItem());
      }
    }
    // uses annotation
    pOMCProxy->addClassAnnotation(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), mNewUsesAnnotationString);
  }
}

/*!
 * \brief UpdateClassCoordinateSystemCommand::undo
 * Undo the UpdateClassCoordinateSystemCommand.
 */
void UpdateCoordinateSystemCommand::undo()
{
  updateCoordinateSystem(mOldCoordinateSystem);
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  // only add version and uses annotation to top level class.
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isTopLevel()) {
    // version
    QString versionAnnotation = QString("annotate=version(\"%1\")").arg(mOldVersion);
    if (pOMCProxy->addClassAnnotation(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), versionAnnotation)) {
      mpGraphicsView->getModelWidget()->getLibraryTreeItem()->mClassInformation.version = mOldVersion;
      // if documentation view is visible then update it
      if (MainWindow::instance()->getDocumentationDockWidget()->isVisible()) {
        MainWindow::instance()->getDocumentationWidget()->showDocumentation(mpGraphicsView->getModelWidget()->getLibraryTreeItem());
      }
    }
    // uses annotation
    pOMCProxy->addClassAnnotation(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), mOldUsesAnnotationString);
  }
}

/*!
 * \brief UpdateCoordinateSystemCommand::updateCoordinateSystem
 * Updates the coordinatesystem
 * \param coordinateSystem
 */
void UpdateCoordinateSystemCommand::updateCoordinateSystem(const ModelInstance::CoordinateSystem coordinateSystem)
{
  if (mCopyProperties) {
    mpGraphicsView->getModelWidget()->getModelInstance()->getAnnotation()->getIconAnnotation()->mCoordinateSystem = coordinateSystem;
    mpGraphicsView->getModelWidget()->getModelInstance()->getAnnotation()->getIconAnnotation()->mMergedCoordinateSystem = coordinateSystem;

    mpGraphicsView->getModelWidget()->getModelInstance()->getAnnotation()->getDiagramAnnotation()->mCoordinateSystem = coordinateSystem;
    mpGraphicsView->getModelWidget()->getModelInstance()->getAnnotation()->getDiagramAnnotation()->mMergedCoordinateSystem = coordinateSystem;
  } else if (mpGraphicsView->isIconView()) {
    mpGraphicsView->getModelWidget()->getModelInstance()->getAnnotation()->getIconAnnotation()->mCoordinateSystem = coordinateSystem;
    mpGraphicsView->getModelWidget()->getModelInstance()->getAnnotation()->getIconAnnotation()->mMergedCoordinateSystem = coordinateSystem;
  } else {
    mpGraphicsView->getModelWidget()->getModelInstance()->getAnnotation()->getDiagramAnnotation()->mCoordinateSystem = coordinateSystem;
    mpGraphicsView->getModelWidget()->getModelInstance()->getAnnotation()->getDiagramAnnotation()->mMergedCoordinateSystem = coordinateSystem;
  }
  mpGraphicsView->getModelWidget()->getModelInstance()->updateMergedCoordinateSystem();

  mpGraphicsView->drawCoordinateSystem();
  mpGraphicsView->addClassAnnotation();
  mpGraphicsView->fitInViewInternal();
  // if copy properties is true
  if (mCopyProperties) {
    GraphicsView *pGraphicsView;
    if (mpGraphicsView->isIconView()) {
      pGraphicsView = mpGraphicsView->getModelWidget()->getDiagramGraphicsView();
    } else {
      pGraphicsView = mpGraphicsView->getModelWidget()->getIconGraphicsView();
    }
    pGraphicsView->drawCoordinateSystem();
    pGraphicsView->addClassAnnotation();
    pGraphicsView->fitInViewInternal();
  }
}

/*!
 * \class UpdateClassAnnotationCommand
 * \brief A class for updating the class annotation e.g. experiment, documentation etc.
 */
/*!
 * \brief UpdateClassAnnotationCommand::UpdateClassAnnotationCommand
 * \param pLibraryTreeItem
 * \param oldAnnotation
 * \param newAnnotaiton
 * \param pParent
 */
UpdateClassAnnotationCommand::UpdateClassAnnotationCommand(LibraryTreeItem *pLibraryTreeItem, QString oldAnnotation,
                                                           QString newAnnotaiton, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  mOldAnnotation = oldAnnotation;
  mNewAnnotation = newAnnotaiton;
  setText(QString("Update %1 annotation").arg(mpLibraryTreeItem->getNameStructure()));
}

/*!
 * \brief UpdateClassAnnotationCommand::redoInternal
 * redoInternal the UpdateClassAnnotationCommand.
 */
void UpdateClassAnnotationCommand::redoInternal()
{
  MainWindow::instance()->getOMCProxy()->addClassAnnotation(mpLibraryTreeItem->getNameStructure(), mNewAnnotation);
}

/*!
 * \brief UpdateClassAnnotationCommand::undo
 * Undo the UpdateClassAnnotationCommand.
 */
void UpdateClassAnnotationCommand::undo()
{
  MainWindow::instance()->getOMCProxy()->addClassAnnotation(mpLibraryTreeItem->getNameStructure(), mOldAnnotation);
}

UpdateClassSimulationFlagsAnnotationCommand::UpdateClassSimulationFlagsAnnotationCommand(LibraryTreeItem *pLibraryTreeItem,
                                                                                         QString oldSimulationFlags,
                                                                                         QString newSimulationFlags, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  mOldSimulationFlags = oldSimulationFlags;
  mNewSimulationFlags = newSimulationFlags;
  setText(QString("Update %1 simulation flags annotation").arg(mpLibraryTreeItem->getNameStructure()));
}

/*!
 * \brief UpdateClassSimulationFlagsAnnotationCommand::redoInternal
 * redoInternal the UpdateClassSimulationFlagsAnnotationCommand.
 */
void UpdateClassSimulationFlagsAnnotationCommand::redoInternal()
{
  MainWindow::instance()->getOMCProxy()->addClassAnnotation(mpLibraryTreeItem->getNameStructure(), mNewSimulationFlags);
}

/*!
 * \brief UpdateClassSimulationFlagsAnnotationCommand::undo
 * Undo the UpdateClassSimulationFlagsAnnotationCommand.
 */
void UpdateClassSimulationFlagsAnnotationCommand::undo()
{
  MainWindow::instance()->getOMCProxy()->addClassAnnotation(mpLibraryTreeItem->getNameStructure(), mOldSimulationFlags);
}

/*!
 * \brief OMSimulatorUndoCommand::OMSimulatorUndoCommand
 * \param modelName
 * \param oldSnapshot
 * \param newSnapshot
 * \param editedCref - Cref where the change has happened.
 * \param doSnapShot
 * \param switchToEdited
 * \param commandText
 * \param pParent
 */
OMSimulatorUndoCommand::OMSimulatorUndoCommand(const QString &modelName, const QString &oldSnapshot, const QString &newSnapshot, const QString &editedCref,
                                               const bool doSnapShot, const bool switchToEdited, const QString oldEditedCref, const QString newEditedCref,
                                               const QString &commandText, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mModelName = modelName;
  mOldSnapshot = oldSnapshot;
  mNewSnapshot = newSnapshot;
  mEditedCref = editedCref;
  mDoSnapShot = doSnapShot;
  mSwitchToEdited = switchToEdited;
  mOldEditedCref = oldEditedCref;
  mNewEditedCref = newEditedCref;
  mExpandedLibraryTreeItemsList.clear();
  mOpenedModelWidgetsAndSelectedElements.clear();
  setText(commandText);
}

/*!
 * \brief OMSimulatorUndoCommand::redoInternal
 * redoInternal the OMSimulatorUndoCommand
 */
void OMSimulatorUndoCommand::redoInternal()
{
  // Get the model LibraryTreeItem
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pModelLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItemOneLevel(mModelName);
  assert(pModelLibraryTreeItem);
  // Save the expanded LibraryTreeItems list
  pLibraryTreeModel->getExpandedLibraryTreeItemsList(pModelLibraryTreeItem, &mExpandedLibraryTreeItemsList);
  // save the opened ModelWidgets that belong to this model and save the selected elements
  MainWindow::instance()->getModelWidgetContainer()->getOpenedModelWidgetsAndSelectedElementsOfClass(mModelName, &mOpenedModelWidgetsAndSelectedElements);
  // load the new snapshot
  if (mDoSnapShot) {
    OMSProxy::instance()->importSnapshot(mModelName, mNewSnapshot, &mModelName);
  }
  // reload/redraw the OMSimulator model
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->reLoadOMSimulatorModel(mModelName, mEditedCref, mNewSnapshot, mOldEditedCref, mNewEditedCref);
  // Get the new model LibraryTreeItem
  LibraryTreeItem *pNewModelLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItemOneLevel(mModelName);
  assert(pNewModelLibraryTreeItem);
  // Restore the expanded LibraryTreeItems list
  pLibraryTreeModel->expandLibraryTreeItems(pNewModelLibraryTreeItem, mExpandedLibraryTreeItemsList);
  // Restore the closed ModelWidgets and select elements in them
  MainWindow::instance()->getModelWidgetContainer()->openModelWidgetsAndSelectElement(mOpenedModelWidgetsAndSelectedElements);
  // switch to the ModelWidget where the change happened
  switchToEditedModelWidget();
}

/*!
 * \brief OMSimulatorUndoCommand::undo
 * Undo the OMSimulatorUndoCommand
 */
void OMSimulatorUndoCommand::undo()
{
  // load the old snapshot
  if (mDoSnapShot) {
    OMSProxy::instance()->importSnapshot(mModelName, mOldSnapshot, &mModelName);
  }
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->reLoadOMSimulatorModel(mModelName, mEditedCref, mOldSnapshot, mNewEditedCref, mOldEditedCref);
  // Get the new model LibraryTreeItem
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pNewModelLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItemOneLevel(mModelName);
  assert(pNewModelLibraryTreeItem);
  // Restore the expanded LibraryTreeItems list
  pLibraryTreeModel->expandLibraryTreeItems(pNewModelLibraryTreeItem, mExpandedLibraryTreeItemsList);
  // Restore the closed ModelWidgets but do not select elements
  MainWindow::instance()->getModelWidgetContainer()->openModelWidgetsAndSelectElement(mOpenedModelWidgetsAndSelectedElements, true);
  // switch to the ModelWidget where the change happened
  switchToEditedModelWidget();
}

/*!
 * \brief OMSimulatorUndoCommand::switchToEditedModelWidget
 * Switches the view to the ModelWidget where the change happened
 */
void OMSimulatorUndoCommand::switchToEditedModelWidget()
{
  if (mSwitchToEdited) {
    LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
    LibraryTreeItem *pEditedLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(mEditedCref);
    if (pEditedLibraryTreeItem) {
      pLibraryTreeModel->showModelWidget(pEditedLibraryTreeItem);
    }
  }
}

/*!
 * \brief OMCUndoCommand::OMCUndoCommand
 * Undo command used with the instance API.
 * \param pLibraryTreeItem
 * \param oldModelInfo
 * \param newModelInfo
 * \param commandText
 * \param commandType
 * \param pParent
 */
OMCUndoCommand::OMCUndoCommand(LibraryTreeItem *pLibraryTreeItem, const ModelInfo &oldModelInfo, const ModelInfo &newModelInfo, const QString &commandText,
                               bool skipGetModelInstance, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  // get the containing parent LibraryTreeItem
  mpParentContainingLibraryTreeItem = pLibraryTreeModel->getContainingFileParentLibraryTreeItem(mpLibraryTreeItem);
  mOldModelText = mpParentContainingLibraryTreeItem->getClassText(pLibraryTreeModel);
  mOldModelInfo = oldModelInfo;
  mNewModelText = MainWindow::instance()->getOMCProxy()->listFile(mpParentContainingLibraryTreeItem->getNameStructure());
  mNewModelInfo = newModelInfo;
  setText(commandText);
  mSkipGetModelInstance = skipGetModelInstance;
}

/*!
 * \brief OMCUndoCommand::redoInternal
 * Loads the new model text and redraws the model.
 */
void OMCUndoCommand::redoInternal()
{
  MainWindow::instance()->getOMCProxy()->loadString(mNewModelText, mpParentContainingLibraryTreeItem->getFileName());
  if (!mSkipGetModelInstance || mUndoCalledOnce) {
    mpLibraryTreeItem->getModelWidget()->reDrawModelWidget(mNewModelInfo);
  }
}

/*!
 * \brief OMCUndoCommand::undo
 * Loads the old model text and redraws the model.
 */
void OMCUndoCommand::undo()
{
  mUndoCalledOnce = true;
  MainWindow::instance()->getOMCProxy()->loadString(mOldModelText, mpParentContainingLibraryTreeItem->getFileName());
  mpLibraryTreeItem->getModelWidget()->reDrawModelWidget(mOldModelInfo);
}
