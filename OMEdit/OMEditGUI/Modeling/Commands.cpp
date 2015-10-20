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

AddShapeCommand::AddShapeCommand(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpShapeAnnotation = pShapeAnnotation;
  mpGraphicsView = pGraphicsView;
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
 * \brief AddShapeCommand::redo
 * Redo the AddShapeCommand.
 */
void AddShapeCommand::redo()
{
  mpGraphicsView->addShapeToList(mpShapeAnnotation);
  mpGraphicsView->addItem(mpShapeAnnotation);
  mpShapeAnnotation->emitAdded();
  mpGraphicsView->setAddClassAnnotationNeeded(true);
}

/*!
 * \brief AddShapeCommand::undo
 * Undo the AddShapeCommand.
 */
void AddShapeCommand::undo()
{
  mpGraphicsView->deleteShapeFromList(mpShapeAnnotation);
  mpGraphicsView->removeItem(mpShapeAnnotation);
  mpShapeAnnotation->emitDeleted();
  mpGraphicsView->setAddClassAnnotationNeeded(true);
}

UpdateShapeCommand::UpdateShapeCommand(ShapeAnnotation *pShapeAnnotation, QString oldAnnotaton, QString newAnnotation,
                                         GraphicsView *pGraphicsView, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpShapeAnnotation = pShapeAnnotation;
  mOldAnnotation = oldAnnotaton;
  mNewAnnotation = newAnnotation;
  mpGraphicsView = pGraphicsView;
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
 * \brief UpdateShapeCommand::redo
 * Redo the UpdateShapeCommand.
 */
void UpdateShapeCommand::redo()
{
  mpShapeAnnotation->parseShapeAnnotation(mNewAnnotation);
  mpShapeAnnotation->initializeTransformation();
  mpShapeAnnotation->removeCornerItems();
  mpShapeAnnotation->drawCornerItems();
  mpShapeAnnotation->setCornerItemsActiveOrPassive();
  mpShapeAnnotation->update();
  mpShapeAnnotation->emitChanged();
  mpGraphicsView->setAddClassAnnotationNeeded(true);
}

/*!
 * \brief UpdateShapeCommand::undo
 * Undo the UpdateShapeCommand.
 */
void UpdateShapeCommand::undo()
{
  mpShapeAnnotation->parseShapeAnnotation(mOldAnnotation);
  mpShapeAnnotation->initializeTransformation();
  mpShapeAnnotation->removeCornerItems();
  mpShapeAnnotation->drawCornerItems();
  mpShapeAnnotation->setCornerItemsActiveOrPassive();
  mpShapeAnnotation->update();
  mpShapeAnnotation->emitChanged();
  mpGraphicsView->setAddClassAnnotationNeeded(true);
}

DeleteShapeCommand::DeleteShapeCommand(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpShapeAnnotation = pShapeAnnotation;
  mpGraphicsView = pGraphicsView;
}

/*!
 * \brief DeleteShapeCommand::redo
 * Redo the DeleteShapeCommand.
 */
void DeleteShapeCommand::redo()
{
  mpGraphicsView->deleteShapeFromList(mpShapeAnnotation);
  mpGraphicsView->removeItem(mpShapeAnnotation);
  mpShapeAnnotation->emitDeleted();
  mpGraphicsView->setAddClassAnnotationNeeded(true);
}

/*!
 * \brief DeleteShapeCommand::undo
 * Undo the DeleteShapeCommand.
 */
void DeleteShapeCommand::undo()
{
  mpGraphicsView->addShapeToList(mpShapeAnnotation);
  mpGraphicsView->addItem(mpShapeAnnotation);
  mpShapeAnnotation->emitAdded();
  mpGraphicsView->setAddClassAnnotationNeeded(true);
}

AddComponentCommand::AddComponentCommand(QString name, LibraryTreeItem *pLibraryTreeItem, QString transformationString, QPointF position,
                                         ComponentInfo *pComponentInfo, bool addObject, bool openingClass, GraphicsView *pGraphicsView,
                                         QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  mAddObject = addObject;
  mpComponentInfo = pComponentInfo;
  mpIconComponent = 0;
  mpDiagramComponent = 0;
  mpIconGraphicsView = pGraphicsView->getModelWidget()->getIconGraphicsView();
  mpDiagramGraphicsView = pGraphicsView->getModelWidget()->getDiagramGraphicsView();
  mpGraphicsView = pGraphicsView;
  setText(QString("Added Component %1").arg(name));

  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  // if component is of connector type && containing class is Modelica type.
  if (mpLibraryTreeItem && mpLibraryTreeItem->isConnector() &&
      pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    // first create the component for Icon View
    mpIconComponent = new Component(name, pLibraryTreeItem, transformationString, position, pComponentInfo, mpIconGraphicsView);
    pModelWidget->getLibraryTreeItem()->emitComponentAdded(mpIconComponent, mpIconGraphicsView);
    mpDiagramComponent = new Component(name, pLibraryTreeItem, transformationString, position, pComponentInfo, mpDiagramGraphicsView);
    pModelWidget->getLibraryTreeItem()->emitComponentAdded(mpDiagramComponent, mpDiagramGraphicsView);
  } else {
    mpDiagramComponent = new Component(name, pLibraryTreeItem, transformationString, position, pComponentInfo, mpDiagramGraphicsView);
    pModelWidget->getLibraryTreeItem()->emitComponentAdded(mpDiagramComponent, mpDiagramGraphicsView);
  }
  // only select the component of the active Icon/Diagram View
  if (!openingClass) {
    // unselect all items
    foreach (QGraphicsItem *pItem, mpGraphicsView->items()) {
      pItem->setSelected(false);
    }
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      mpIconComponent->setSelected(true);
    } else {
      mpDiagramComponent->setSelected(true);
    }
  }
}

/*!
 * \brief AddComponentCommand::redo
 * Redo the AddComponentCommand.
 */
void AddComponentCommand::redo()
{
  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  // if component is of connector type && containing class is Modelica type.
  if (mpLibraryTreeItem && mpLibraryTreeItem->isConnector() &&
      pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    // first create the component for Icon View only if connector is not protected
    if (!mpComponentInfo->getProtected()) {
      mpIconGraphicsView->addItem(mpIconComponent);
      mpIconGraphicsView->addItem(mpIconComponent->getOriginItem());
      mpIconGraphicsView->addComponentToList(mpIconComponent);
      mpIconComponent->emitAdded();
    }
    // now add the component to Diagram View
    mpDiagramGraphicsView->addItem(mpDiagramComponent);
    mpDiagramGraphicsView->addItem(mpDiagramComponent->getOriginItem());
    mpDiagramGraphicsView->addComponentToList(mpDiagramComponent);
    mpDiagramComponent->emitAdded();
  } else {
    mpDiagramGraphicsView->addItem(mpDiagramComponent);
    mpDiagramGraphicsView->addItem(mpDiagramComponent->getOriginItem());
    mpDiagramGraphicsView->addComponentToList(mpDiagramComponent);
    mpDiagramComponent->emitAdded();
  }
  if (mAddObject) {
    mpDiagramGraphicsView->addComponentToClass(mpDiagramComponent);
  }
}

/*!
 * \brief AddComponentCommand::undo
 * Undo the AddComponentCommand.
 */
void AddComponentCommand::undo()
{
  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  // if component is of connector type && containing class is Modelica type.
  if (mpLibraryTreeItem && mpLibraryTreeItem->isConnector() &&
      pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    // first create the component for Icon View only if connector is not protected
    if (!mpComponentInfo->getProtected()) {
      mpIconGraphicsView->removeItem(mpIconComponent);
      mpIconGraphicsView->removeItem(mpIconComponent->getOriginItem());
      mpIconGraphicsView->deleteComponentFromList(mpIconComponent);
      mpIconComponent->emitDeleted();
    }
    // now remove the component from Diagram View
    mpDiagramGraphicsView->removeItem(mpDiagramComponent);
    mpDiagramGraphicsView->removeItem(mpDiagramComponent->getOriginItem());
    mpDiagramGraphicsView->deleteComponentFromList(mpDiagramComponent);
    mpDiagramComponent->emitDeleted();
  } else {
    mpDiagramGraphicsView->removeItem(mpDiagramComponent);
    mpDiagramGraphicsView->removeItem(mpDiagramComponent->getOriginItem());
    mpDiagramGraphicsView->deleteComponentFromList(mpDiagramComponent);
    mpDiagramComponent->emitDeleted();
  }
  mpGraphicsView->deleteComponentFromClass(mpDiagramComponent);
}

UpdateComponentCommand::UpdateComponentCommand(Component *pComponent, const Transformation &oldTransformation,
                                               const Transformation &newTransformation, GraphicsView *pGraphicsView, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpComponent = pComponent;
  mOldTransformation = oldTransformation;
  mNewTransformation = newTransformation;
  mpGraphicsView = pGraphicsView;
}

/*!
 * \brief UpdateComponentCommand::redo
 * Redo the UpdateComponentCommand.
 */
void UpdateComponentCommand::redo()
{
  mpComponent->resetTransform();
  bool state = mpComponent->flags().testFlag(QGraphicsItem::ItemSendsGeometryChanges);
  mpComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, false);
  mpComponent->setPos(0, 0);
  mpComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, state);
  mpComponent->setTransform(mNewTransformation.getTransformationMatrix());
  mpComponent->mTransformation = mNewTransformation;
  mpComponent->emitTransformChange();
  mpComponent->emitTransformHasChanged();
}

/*!
 * \brief UpdateComponentCommand::undo
 * Undo the UpdateComponentCommand.
 */
void UpdateComponentCommand::undo()
{
  mpComponent->resetTransform();
  bool state = mpComponent->flags().testFlag(QGraphicsItem::ItemSendsGeometryChanges);
  mpComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, false);
  mpComponent->setPos(0, 0);
  mpComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, state);
  mpComponent->setTransform(mOldTransformation.getTransformationMatrix());
  mpComponent->mTransformation = mOldTransformation;
  mpComponent->emitTransformChange();
  mpComponent->emitTransformHasChanged();
}

DeleteComponentCommand::DeleteComponentCommand(Component *pComponent, GraphicsView *pGraphicsView, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpComponent = pComponent;
  mpIconComponent = 0;
  mpDiagramComponent = 0;
  mpIconGraphicsView = pGraphicsView->getModelWidget()->getIconGraphicsView();
  mpDiagramGraphicsView = pGraphicsView->getModelWidget()->getDiagramGraphicsView();
  mpGraphicsView = pGraphicsView;
}

/*!
 * \brief DeleteComponentCommand::redo
 * Redo the DeleteComponentCommand.
 */
void DeleteComponentCommand::redo()
{
  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  // if component is of connector type && containing class is Modelica type.
  if (mpComponent->getLibraryTreeItem() && mpComponent->getLibraryTreeItem()->isConnector() &&
      pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    // first remove the component from Icon View
    mpIconComponent = mpIconGraphicsView->getComponentObject(mpComponent->getName());
    if (mpIconComponent) {
      mpIconGraphicsView->removeItem(mpIconComponent);
      mpIconGraphicsView->removeItem(mpIconComponent->getOriginItem());
      mpIconGraphicsView->deleteComponentFromList(mpIconComponent);
      mpIconComponent->emitDeleted();
    }
    // now remove the component from Diagram View
    mpDiagramComponent = mpDiagramGraphicsView->getComponentObject(mpComponent->getName());
    if (mpDiagramComponent) {
      mpDiagramGraphicsView->removeItem(mpDiagramComponent);
      mpDiagramGraphicsView->removeItem(mpDiagramComponent->getOriginItem());
      mpDiagramGraphicsView->deleteComponentFromList(mpDiagramComponent);
      mpDiagramComponent->emitDeleted();
    }
  } else {
    mpDiagramGraphicsView->removeItem(mpComponent);
    mpDiagramGraphicsView->removeItem(mpComponent->getOriginItem());
    mpDiagramGraphicsView->deleteComponentFromList(mpComponent);
    mpComponent->emitDeleted();
  }
  mpGraphicsView->deleteComponentFromClass(mpComponent);
}

/*!
 * \brief DeleteComponentCommand::undo
 * Undo the DeleteComponentCommand.
 */
void DeleteComponentCommand::undo()
{
  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  // if component is of connector type && containing class is Modelica type.
  if (mpComponent->getLibraryTreeItem() && mpComponent->getLibraryTreeItem()->isConnector() &&
      pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    // first add the component to Icon View
    if (mpIconComponent) {
      mpIconGraphicsView->addItem(mpIconComponent);
      mpIconGraphicsView->addItem(mpIconComponent->getOriginItem());
      mpIconGraphicsView->addComponentToList(mpIconComponent);
      mpIconComponent->emitAdded();
    }
    // now add the component to Diagram View
    if (mpDiagramComponent) {
      mpDiagramGraphicsView->addItem(mpDiagramComponent);
      mpDiagramGraphicsView->addItem(mpDiagramComponent->getOriginItem());
      mpDiagramGraphicsView->addComponentToList(mpDiagramComponent);
      mpDiagramComponent->emitAdded();
    }
  } else {
    mpDiagramGraphicsView->addItem(mpComponent);
    mpDiagramGraphicsView->addItem(mpComponent->getOriginItem());
    mpDiagramGraphicsView->addComponentToList(mpComponent);
    mpComponent->emitAdded();
  }
  mpGraphicsView->addComponentToClass(mpComponent);
}

AddConnectionCommand::AddConnectionCommand(LineAnnotation *pConnectionLineAnnotation, bool addConnection, GraphicsView *pGraphicsView,
                                           QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  mAddConnection = addConnection;
  mpGraphicsView = pGraphicsView;
  setText(QString("Add Connection connect(%1, %2)").arg(mpConnectionLineAnnotation->getStartComponentName(),
                                                        mpConnectionLineAnnotation->getEndComponentName()));

  mpConnectionLineAnnotation->setToolTip(QString("<b>connect</b>(%1, %2)").arg(mpConnectionLineAnnotation->getStartComponentName())
                                         .arg(mpConnectionLineAnnotation->getEndComponentName()));
  mpConnectionLineAnnotation->drawCornerItems();
  mpConnectionLineAnnotation->setCornerItemsActiveOrPassive();
  pGraphicsView->getModelWidget()->getLibraryTreeItem()->emitConnectionAdded(mpConnectionLineAnnotation);
}

/*!
 * \brief AddConnectionCommand::redo
 * Redo the AddConnectionCommand.
 */
void AddConnectionCommand::redo()
{
  // Add the start component connection details.
  Component *pStartComponent = mpConnectionLineAnnotation->getStartComponent();
  if (pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->addConnectionDetails(mpConnectionLineAnnotation);
  } else {
    pStartComponent->addConnectionDetails(mpConnectionLineAnnotation);
  }
  // Add the end component connection details.
  Component *pEndComponent = mpConnectionLineAnnotation->getEndComponent();
  if (pEndComponent->getParentComponent()) {
    pEndComponent->getParentComponent()->addConnectionDetails(mpConnectionLineAnnotation);
  } else {
    pEndComponent->addConnectionDetails(mpConnectionLineAnnotation);
  }
  mpGraphicsView->addConnectionToList(mpConnectionLineAnnotation);
  mpGraphicsView->addItem(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->emitAdded();
  if (mAddConnection) {
    mpGraphicsView->addConnectionToClass(mpConnectionLineAnnotation);
  }
}

/*!
 * \brief AddConnectionCommand::undo
 * Undo the AddConnectionCommand.
 */
void AddConnectionCommand::undo()
{
  // Remove the start component connection details.
  Component *pStartComponent = mpConnectionLineAnnotation->getStartComponent();
  if (pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->removeConnectionDetails(mpConnectionLineAnnotation);
  } else {
    pStartComponent->removeConnectionDetails(mpConnectionLineAnnotation);
  }
  // Remove the end component connection details.
  Component *pEndComponent = mpConnectionLineAnnotation->getEndComponent();
  if (pEndComponent->getParentComponent()) {
    pEndComponent->getParentComponent()->removeConnectionDetails(mpConnectionLineAnnotation);
  } else {
    pEndComponent->removeConnectionDetails(mpConnectionLineAnnotation);
  }
  mpGraphicsView->deleteConnectionFromList(mpConnectionLineAnnotation);
  mpGraphicsView->removeItem(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->emitDeleted();
  mpGraphicsView->deleteConnectionFromClass(mpConnectionLineAnnotation);
}

DeleteConnectionCommand::DeleteConnectionCommand(LineAnnotation *pConnectionLineAnnotation, GraphicsView *pGraphicsView, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  mpGraphicsView = pGraphicsView;
}

/*!
 * \brief DeleteConnectionCommand::redo
 * Redo the DeleteConnectionCommand.
 */
void DeleteConnectionCommand::redo()
{
  // Remove the start component connection details.
  Component *pStartComponent = mpConnectionLineAnnotation->getStartComponent();
  if (pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->removeConnectionDetails(mpConnectionLineAnnotation);
  } else {
    pStartComponent->removeConnectionDetails(mpConnectionLineAnnotation);
  }
  // Remove the end component connection details.
  Component *pEndComponent = mpConnectionLineAnnotation->getEndComponent();
  if (pEndComponent->getParentComponent()) {
    pEndComponent->getParentComponent()->removeConnectionDetails(mpConnectionLineAnnotation);
  } else {
    pEndComponent->removeConnectionDetails(mpConnectionLineAnnotation);
  }
  mpGraphicsView->deleteConnectionFromList(mpConnectionLineAnnotation);
  mpGraphicsView->removeItem(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->emitDeleted();
  mpGraphicsView->deleteConnectionFromClass(mpConnectionLineAnnotation);
}

/*!
 * \brief DeleteConnectionCommand::undo
 * Undo the DeleteConnectionCommand.
 */
void DeleteConnectionCommand::undo()
{
  // Add the start component connection details.
  Component *pStartComponent = mpConnectionLineAnnotation->getStartComponent();
  if (pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->addConnectionDetails(mpConnectionLineAnnotation);
  } else {
    pStartComponent->addConnectionDetails(mpConnectionLineAnnotation);
  }
  // Add the end component connection details.
  Component *pEndComponent = mpConnectionLineAnnotation->getEndComponent();
  if (pEndComponent->getParentComponent()) {
    pEndComponent->getParentComponent()->addConnectionDetails(mpConnectionLineAnnotation);
  } else {
    pEndComponent->addConnectionDetails(mpConnectionLineAnnotation);
  }
  mpGraphicsView->addConnectionToList(mpConnectionLineAnnotation);
  mpGraphicsView->addItem(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->emitAdded();
  mpGraphicsView->addConnectionToClass(mpConnectionLineAnnotation);
}
