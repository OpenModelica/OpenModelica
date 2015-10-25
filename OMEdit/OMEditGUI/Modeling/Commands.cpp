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
  setText(QString("Add Component %1").arg(name));

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

UpdateComponentTransformationsCommand::UpdateComponentTransformationsCommand(Component *pComponent, const Transformation &oldTransformation,
                                                                             const Transformation &newTransformation, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpComponent = pComponent;
  mOldTransformation = oldTransformation;
  mNewTransformation = newTransformation;
  setText(QString("Update Component %1 Transformations").arg(mpComponent->getName()));
}

/*!
 * \brief UpdateComponentTransformationsCommand::redo
 * Redo the UpdateComponentTransformationsCommand.
 */
void UpdateComponentTransformationsCommand::redo()
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
 * \brief UpdateComponentTransformationsCommand::undo
 * Undo the UpdateComponentTransformationsCommand.
 */
void UpdateComponentTransformationsCommand::undo()
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

UpdateComponentAttributesCommand::UpdateComponentAttributesCommand(Component *pComponent, const ComponentInfo &oldComponentInfo,
                                                                   const ComponentInfo &newComponentInfo, bool duplicate,
                                                                   QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpComponent = pComponent;
  mOldComponentInfo.updateComponentInfo(&oldComponentInfo);
  mNewComponentInfo.updateComponentInfo(&newComponentInfo);
  mDuplicate = duplicate;
  setText(QString("Update Component %1 Attributes").arg(mpComponent->getName()));
}

/*!
 * \brief UpdateComponentAttributesCommand::redo
 * Redo the UpdateComponentAttributesCommand.
 */
void UpdateComponentAttributesCommand::redo()
{
  ModelWidget *pModelWidget = mpComponent->getGraphicsView()->getModelWidget();
  QString modelName = pModelWidget->getLibraryTreeItem()->getNameStructure();
  QString isFinal = mNewComponentInfo.getFinal() ? "true" : "false";
  QString flow = mNewComponentInfo.getFlow() ? "true" : "false";
  QString isProtected = mNewComponentInfo.getProtected() ? "true" : "false";
  QString isReplaceAble = mNewComponentInfo.getReplaceable() ? "true" : "false";
  QString variability = mNewComponentInfo.getVariablity();
  QString isInner = mNewComponentInfo.getInner() ? "true" : "false";
  QString isOuter = mNewComponentInfo.getOuter() ? "true" : "false";
  QString causality = mNewComponentInfo.getCausality();

  OMCProxy *pOMCProxy = pModelWidget->getModelWidgetContainer()->getMainWindow()->getOMCProxy();
  // update component attributes
  if (pOMCProxy->setComponentProperties(modelName, mpComponent->getComponentInfo()->getName(), isFinal, flow, isProtected, isReplaceAble,
                                        variability, isInner, isOuter, causality)) {
    mpComponent->getComponentInfo()->setFinal(mNewComponentInfo.getFinal());
    mpComponent->getComponentInfo()->setProtected(mNewComponentInfo.getProtected());
    mpComponent->getComponentInfo()->setReplaceable(mNewComponentInfo.getReplaceable());
    mpComponent->getComponentInfo()->setVariablity(variability);
    mpComponent->getComponentInfo()->setInner(mNewComponentInfo.getInner());
    mpComponent->getComponentInfo()->setOuter(mNewComponentInfo.getOuter());
    mpComponent->getComponentInfo()->setCausality(causality);
  } else {
    QMessageBox::critical(pModelWidget->getModelWidgetContainer()->getMainWindow(),
                          QString(Helper::applicationName).append(" - ").append(Helper::error), pOMCProxy->getResult(), Helper::ok);
    pOMCProxy->printMessagesStringInternal();
  }
  // update the component comment only if its changed.
  if (mpComponent->getComponentInfo()->getComment().compare(mNewComponentInfo.getComment()) != 0) {
    QString comment = StringHandler::escapeString(mNewComponentInfo.getComment());
    if (pOMCProxy->setComponentComment(modelName, mpComponent->getComponentInfo()->getName(), comment)) {
      mpComponent->getComponentInfo()->setComment(comment);
    } else {
      QMessageBox::critical(pModelWidget->getModelWidgetContainer()->getMainWindow(),
                            QString(Helper::applicationName).append(" - ").append(Helper::error), pOMCProxy->getResult(), Helper::ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
  // update the component name only if its changed.
  if (mpComponent->getComponentInfo()->getName().compare(mNewComponentInfo.getName()) != 0) {
    // if renameComponentInClass command is successful update the component with new name
    if (pOMCProxy->renameComponentInClass(modelName, mpComponent->getComponentInfo()->getName(), mNewComponentInfo.getName())) {
      mpComponent->getComponentInfo()->setName(mNewComponentInfo.getName());
      mpComponent->componentNameHasChanged();
    } else {
      QMessageBox::critical(pModelWidget->getModelWidgetContainer()->getMainWindow(),
                            QString(Helper::applicationName).append(" - ").append(Helper::error), pOMCProxy->getResult(), Helper::ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
  // update the component dimensions
  if (mpComponent->getComponentInfo()->getArrayIndex().compare(mNewComponentInfo.getArrayIndex()) != 0) {
    if (pOMCProxy->setComponentDimensions(modelName, mpComponent->getComponentInfo()->getName(), mNewComponentInfo.getArrayIndex())) {
      mpComponent->getComponentInfo()->setArrayIndex(mNewComponentInfo.getArrayIndex());
    } else {
      QMessageBox::critical(pModelWidget->getModelWidgetContainer()->getMainWindow(),
                            QString(Helper::applicationName).append(" - ").append(Helper::error), pOMCProxy->getResult(), Helper::ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
}

/*!
 * \brief UpdateComponentAttributesCommand::undo
 * Undo the UpdateComponentAttributesCommand.
 */
void UpdateComponentAttributesCommand::undo()
{
  /* We don't do anything if command is done for duplicate component action. Because when we undo duplicate component it will call
   * AddComponentCommand::undo() which will eventually delete the component. So there is no point to undo attributes.
   */
  if (mDuplicate) {
    return;
  }
  ModelWidget *pModelWidget = mpComponent->getGraphicsView()->getModelWidget();
  QString modelName = pModelWidget->getLibraryTreeItem()->getNameStructure();
  QString isFinal = mOldComponentInfo.getFinal() ? "true" : "false";
  QString flow = mNewComponentInfo.getFlow() ? "true" : "false";
  QString isProtected = mOldComponentInfo.getProtected() ? "true" : "false";
  QString isReplaceAble = mOldComponentInfo.getReplaceable() ? "true" : "false";
  QString variability = mOldComponentInfo.getVariablity();
  QString isInner = mOldComponentInfo.getInner() ? "true" : "false";
  QString isOuter = mOldComponentInfo.getOuter() ? "true" : "false";
  QString causality = mOldComponentInfo.getCausality();

  OMCProxy *pOMCProxy = pModelWidget->getModelWidgetContainer()->getMainWindow()->getOMCProxy();
  // update component attributes
  if (pOMCProxy->setComponentProperties(modelName, mpComponent->getComponentInfo()->getName(), isFinal, flow, isProtected, isReplaceAble,
                                        variability, isInner, isOuter, causality)) {
    mpComponent->getComponentInfo()->setFinal(mOldComponentInfo.getFinal());
    mpComponent->getComponentInfo()->setProtected(mOldComponentInfo.getProtected());
    mpComponent->getComponentInfo()->setReplaceable(mOldComponentInfo.getReplaceable());
    mpComponent->getComponentInfo()->setVariablity(variability);
    mpComponent->getComponentInfo()->setInner(mOldComponentInfo.getInner());
    mpComponent->getComponentInfo()->setOuter(mOldComponentInfo.getOuter());
    mpComponent->getComponentInfo()->setCausality(causality);
  } else {
    QMessageBox::critical(pModelWidget->getModelWidgetContainer()->getMainWindow(),
                          QString(Helper::applicationName).append(" - ").append(Helper::error), pOMCProxy->getResult(), Helper::ok);
    pOMCProxy->printMessagesStringInternal();
  }
  // update the component comment only if its changed.
  if (mpComponent->getComponentInfo()->getComment().compare(mOldComponentInfo.getComment()) != 0) {
    QString comment = StringHandler::escapeString(mOldComponentInfo.getComment());
    if (pOMCProxy->setComponentComment(modelName, mpComponent->getComponentInfo()->getName(), comment)) {
      mpComponent->getComponentInfo()->setComment(comment);
    } else {
      QMessageBox::critical(pModelWidget->getModelWidgetContainer()->getMainWindow(),
                            QString(Helper::applicationName).append(" - ").append(Helper::error), pOMCProxy->getResult(), Helper::ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
  // update the component name only if its changed.
  if (mpComponent->getComponentInfo()->getName().compare(mOldComponentInfo.getName()) != 0) {
    // if renameComponentInClass command is successful update the component with new name
    if (pOMCProxy->renameComponentInClass(modelName, mpComponent->getComponentInfo()->getName(), mOldComponentInfo.getName())) {
      mpComponent->getComponentInfo()->setName(mOldComponentInfo.getName());
      mpComponent->componentNameHasChanged();
    } else {
      QMessageBox::critical(pModelWidget->getModelWidgetContainer()->getMainWindow(),
                            QString(Helper::applicationName).append(" - ").append(Helper::error), pOMCProxy->getResult(), Helper::ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
  // update the component dimensions
  if (mpComponent->getComponentInfo()->getArrayIndex().compare(mOldComponentInfo.getArrayIndex()) != 0) {
    if (pOMCProxy->setComponentDimensions(modelName, mpComponent->getComponentInfo()->getName(), mOldComponentInfo.getArrayIndex())) {
      mpComponent->getComponentInfo()->setArrayIndex(mOldComponentInfo.getArrayIndex());
    } else {
      QMessageBox::critical(pModelWidget->getModelWidgetContainer()->getMainWindow(),
                            QString(Helper::applicationName).append(" - ").append(Helper::error), pOMCProxy->getResult(), Helper::ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
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
