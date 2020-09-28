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
  mpShapeAnnotation->getGraphicsView()->addShapeToList(mpShapeAnnotation, mIndex);
  mpShapeAnnotation->getGraphicsView()->deleteShapeFromOutOfSceneList(mpShapeAnnotation);
  mpShapeAnnotation->getGraphicsView()->addItem(mpShapeAnnotation);
  mpShapeAnnotation->getGraphicsView()->addItem(mpShapeAnnotation->getOriginItem());
  mpShapeAnnotation->emitAdded();
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
  mpShapeAnnotation->emitDeleted();
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
  mpShapeAnnotation->emitChanged();
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
  mpShapeAnnotation->emitChanged();
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
  mpShapeAnnotation->emitDeleted();
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
  mpShapeAnnotation->emitAdded();
  mpShapeAnnotation->getGraphicsView()->setAddClassAnnotationNeeded(true);
  mpShapeAnnotation->getGraphicsView()->reOrderShapes();
}

AddComponentCommand::AddComponentCommand(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, QPointF position,
                                         ElementInfo *pComponentInfo, bool addObject, bool openingClass, GraphicsView *pGraphicsView,
                                         UndoCommand *pParent)
  : UndoCommand(pParent)
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
  if (mpLibraryTreeItem && mpLibraryTreeItem->isConnector() && pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    // Connector type components exists on icon view as well
    mpIconComponent = new Element(name, pLibraryTreeItem, annotation, position, pComponentInfo, mpIconGraphicsView);
  }
  mpDiagramComponent = new Element(name, pLibraryTreeItem, annotation, position, pComponentInfo, mpDiagramGraphicsView);
  // only select the component of the active Icon/Diagram View
  if (!openingClass) {
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      mpGraphicsView->clearSelection(mpIconComponent);
    } else {
      mpGraphicsView->clearSelection(mpDiagramComponent);
    }
  }
}

/*!
 * \brief AddComponentCommand::redoInternal
 * redoInternal the AddComponentCommand.
 */
void AddComponentCommand::redoInternal()
{
  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  // if component is of connector type && containing class is Modelica type.
  if (mpLibraryTreeItem && mpLibraryTreeItem->isConnector() && pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    // Connector type components exists on icon view as well
    mpIconGraphicsView->addItem(mpIconComponent);
    mpIconGraphicsView->addItem(mpIconComponent->getOriginItem());
    mpIconGraphicsView->addComponentToList(mpIconComponent);
    mpIconGraphicsView->deleteComponentFromOutOfSceneList(mpIconComponent);
    mpIconComponent->emitAdded();
    // hide the component if it is connector and is protected
    mpIconComponent->setVisible(!mpComponentInfo->getProtected());
  }
  mpDiagramGraphicsView->addItem(mpDiagramComponent);
  mpDiagramGraphicsView->addItem(mpDiagramComponent->getOriginItem());
  mpDiagramGraphicsView->addComponentToList(mpDiagramComponent);
  mpDiagramGraphicsView->deleteComponentFromOutOfSceneList(mpDiagramComponent);
  mpDiagramComponent->emitAdded();
  if (mAddObject) {
    mpDiagramGraphicsView->addComponentToClass(mpDiagramComponent);
    UpdateComponentAttributesCommand::updateComponentModifiers(mpDiagramComponent, *mpDiagramComponent->getComponentInfo());
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
  if (mpLibraryTreeItem && mpLibraryTreeItem->isConnector() && pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    // Connector type components exists on icon view as well
    mpIconGraphicsView->removeItem(mpIconComponent);
    mpIconGraphicsView->removeItem(mpIconComponent->getOriginItem());
    mpIconGraphicsView->deleteComponentFromList(mpIconComponent);
    mpIconGraphicsView->addComponentToOutOfSceneList(mpIconComponent);
    mpIconComponent->emitDeleted();
  }
  mpDiagramGraphicsView->removeItem(mpDiagramComponent);
  mpDiagramGraphicsView->removeItem(mpDiagramComponent->getOriginItem());
  mpDiagramGraphicsView->deleteComponentFromList(mpDiagramComponent);
  mpDiagramGraphicsView->addComponentToOutOfSceneList(mpDiagramComponent);
  mpDiagramComponent->emitDeleted();
  mpDiagramGraphicsView->deleteComponentFromClass(mpDiagramComponent);
}

UpdateComponentTransformationsCommand::UpdateComponentTransformationsCommand(Element *pComponent, const Transformation &oldTransformation, const Transformation &newTransformation,
                                                                             const bool positionChanged, const bool moveConnectorsTogether, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpComponent = pComponent;
  mOldTransformation = oldTransformation;
  mNewTransformation = newTransformation;
  mPositionChanged = positionChanged;
  mMoveConnectorsTogether = moveConnectorsTogether;
  setText(QString("Update Component %1 Transformations").arg(mpComponent->getName()));
}

/*!
 * \brief UpdateComponentTransformationsCommand::redoInternal
 * redoInternal the UpdateComponentTransformationsCommand.
 */
void UpdateComponentTransformationsCommand::redoInternal()
{
  ModelWidget *pModelWidget = mpComponent->getGraphicsView()->getModelWidget();
  if (mpComponent->getLibraryTreeItem() && mpComponent->getLibraryTreeItem()->isConnector() && mMoveConnectorsTogether &&
      pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    GraphicsView *pGraphicsView;
    if (mpComponent->getGraphicsView()->getViewType() == StringHandler::Icon) {
      pGraphicsView = pModelWidget->getDiagramGraphicsView();
    } else {
      pGraphicsView = pModelWidget->getIconGraphicsView();
    }
    Element *pComponent = pGraphicsView->getComponentObject(mpComponent->getName());
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
}

/*!
 * \brief UpdateComponentTransformationsCommand::undo
 * Undo the UpdateComponentTransformationsCommand.
 */
void UpdateComponentTransformationsCommand::undo()
{
  ModelWidget *pModelWidget = mpComponent->getGraphicsView()->getModelWidget();
  if (mpComponent->getLibraryTreeItem() && mpComponent->getLibraryTreeItem()->isConnector() && mMoveConnectorsTogether &&
      pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    GraphicsView *pGraphicsView;
    if (mpComponent->getGraphicsView()->getViewType() == StringHandler::Icon) {
      pGraphicsView = pModelWidget->getDiagramGraphicsView();
    } else {
      pGraphicsView = pModelWidget->getIconGraphicsView();
    }
    Element *pComponent = pGraphicsView->getComponentObject(mpComponent->getName());
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
}

UpdateComponentAttributesCommand::UpdateComponentAttributesCommand(Element *pComponent, const ElementInfo &oldComponentInfo, const ElementInfo &newComponentInfo, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpComponent = pComponent;
  mOldComponentInfo.updateElementInfo(&oldComponentInfo);
  mNewComponentInfo.updateElementInfo(&newComponentInfo);
  setText(QString("Update Component %1 Attributes").arg(mpComponent->getName()));
}

/*!
 * \brief UpdateComponentAttributesCommand::redoInternal
 * redoInternal the UpdateComponentAttributesCommand.
 */
void UpdateComponentAttributesCommand::redoInternal()
{
  updateComponentAttributes(mpComponent, mNewComponentInfo);
}

/*!
 * \brief UpdateComponentAttributesCommand::undo
 * Undo the UpdateComponentAttributesCommand.
 */
void UpdateComponentAttributesCommand::undo()
{
  updateComponentAttributes(mpComponent, mOldComponentInfo);
}

/*!
 * \brief UpdateComponentAttributesCommand::updateComponentAttributes
 * Updates the component attributes based on the ElementInfo
 * \param pComponent
 * \param componentInfo
 */
void UpdateComponentAttributesCommand::updateComponentAttributes(Element *pComponent, const ElementInfo &componentInfo)
{
  QString modelName = pComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  QString isFinal = componentInfo.getFinal() ? "true" : "false";
  QString flow = componentInfo.getFlow() ? "true" : "false";
  QString isProtected = componentInfo.getProtected() ? "true" : "false";
  QString isReplaceAble = componentInfo.getReplaceable() ? "true" : "false";
  QString variability = componentInfo.getVariablity();
  QString isInner = componentInfo.getInner() ? "true" : "false";
  QString isOuter = componentInfo.getOuter() ? "true" : "false";
  QString causality = componentInfo.getCausality();

  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  // update component attributes
  if (pOMCProxy->setComponentProperties(modelName, pComponent->getComponentInfo()->getName(), isFinal, flow, isProtected, isReplaceAble,
                                        variability, isInner, isOuter, causality)) {
    pComponent->getComponentInfo()->setFinal(componentInfo.getFinal());
    pComponent->getComponentInfo()->setProtected(componentInfo.getProtected());
    pComponent->getComponentInfo()->setReplaceable(componentInfo.getReplaceable());
    pComponent->getComponentInfo()->setVariablity(variability);
    pComponent->getComponentInfo()->setInner(componentInfo.getInner());
    pComponent->getComponentInfo()->setOuter(componentInfo.getOuter());
    pComponent->getComponentInfo()->setCausality(causality);
    if (pComponent->getGraphicsView()->getViewType() == StringHandler::Icon) {
      if (pComponent->getComponentInfo()->getProtected()) {
        pComponent->setVisible(false);
        pComponent->emitDeleted();
      } else {
        pComponent->setVisible(true);
        pComponent->emitAdded();
      }
    } else {
      Element *pIconComponent = 0;
      pIconComponent = pComponent->getGraphicsView()->getModelWidget()->getIconGraphicsView()->getComponentObject(pComponent->getName());
      if (pIconComponent) {
        if (pIconComponent->getComponentInfo()->getProtected()) {
          pIconComponent->setVisible(false);
          pIconComponent->emitDeleted();
        } else {
          pIconComponent->setVisible(true);
          pIconComponent->emitAdded();
        }
      }
    }
  } else {
    QMessageBox::critical(MainWindow::instance(),
                          QString(Helper::applicationName).append(" - ").append(Helper::error), pOMCProxy->getResult(), Helper::ok);
    pOMCProxy->printMessagesStringInternal();
  }
  // update the component comment only if its changed.
  if (pComponent->getComponentInfo()->getComment().compare(componentInfo.getComment()) != 0) {
    QString comment = StringHandler::escapeString(componentInfo.getComment());
    if (pOMCProxy->setComponentComment(modelName, pComponent->getComponentInfo()->getName(), comment)) {
      pComponent->getComponentInfo()->setComment(comment);
      pComponent->componentCommentHasChanged();
      if (pComponent->getLibraryTreeItem()->isConnector()) {
        if (pComponent->getGraphicsView()->getViewType() == StringHandler::Icon) {
          Element *pDiagramComponent = 0;
          pDiagramComponent = pComponent->getGraphicsView()->getModelWidget()->getDiagramGraphicsView()->getComponentObject(pComponent->getName());
          if (pDiagramComponent) {
            pDiagramComponent->componentCommentHasChanged();
          }
        } else {
          Element *pIconComponent = 0;
          pIconComponent = pComponent->getGraphicsView()->getModelWidget()->getIconGraphicsView()->getComponentObject(pComponent->getName());
          if (pIconComponent) {
            pIconComponent->componentCommentHasChanged();
          }
        }
      }
    } else {
      QMessageBox::critical(MainWindow::instance(),
                            QString(Helper::applicationName).append(" - ").append(Helper::error), pOMCProxy->getResult(), Helper::ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
  // update the component name only if its changed.
  if (pComponent->getComponentInfo()->getName().compare(componentInfo.getName()) != 0) {
    // if renameComponentInClass command is successful update the component with new name
    if (pOMCProxy->renameComponentInClass(modelName, pComponent->getComponentInfo()->getName(), componentInfo.getName())) {
      pComponent->renameComponentInConnections(componentInfo.getName());
      pComponent->getComponentInfo()->setName(componentInfo.getName());
      pComponent->componentNameHasChanged();
      if (pComponent->getLibraryTreeItem()->isConnector()) {
        if (pComponent->getGraphicsView()->getViewType() == StringHandler::Icon) {
          Element *pDiagramComponent = 0;
          pDiagramComponent = pComponent->getGraphicsView()->getModelWidget()->getDiagramGraphicsView()->getComponentObject(pComponent->getName());
          if (pDiagramComponent) {
            pDiagramComponent->componentNameHasChanged();
          }
        } else {
          Element *pIconComponent = 0;
          pIconComponent = pComponent->getGraphicsView()->getModelWidget()->getIconGraphicsView()->getComponentObject(pComponent->getName());
          if (pIconComponent) {
            pIconComponent->componentNameHasChanged();
          }
        }
      }
    } else {
      QMessageBox::critical(MainWindow::instance(),
                            QString(Helper::applicationName).append(" - ").append(Helper::error), pOMCProxy->getResult(), Helper::ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
  // update the component dimensions
  if (pComponent->getComponentInfo()->getArrayIndex().compare(componentInfo.getArrayIndex()) != 0) {
    const QString arrayIndex = QString("{%1}").arg(componentInfo.getArrayIndex());
    if (pOMCProxy->setComponentDimensions(modelName, pComponent->getComponentInfo()->getName(), arrayIndex)) {
      pComponent->getComponentInfo()->setArrayIndex(arrayIndex);
    } else {
      QMessageBox::critical(MainWindow::instance(),
                            QString(Helper::applicationName).append(" - ").append(Helper::error), pOMCProxy->getResult(), Helper::ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
}

/*!
 * \brief UpdateComponentAttributesCommand::updateComponentModifiers
 * Applies Component modifiers
 * \param pComponent
 * \param componentInfo
 */
void UpdateComponentAttributesCommand::updateComponentModifiers(Element *pComponent, const ElementInfo &componentInfo)
{
  QString modelName = pComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  bool modifierValueChanged = false;
  QMap<QString, QString> modifiers = componentInfo.getModifiersMapWithoutFetching();
  QMap<QString, QString>::iterator modifiersIterator;
  for (modifiersIterator = modifiers.begin(); modifiersIterator != modifiers.end(); ++modifiersIterator) {
    QString modifierName = QString(pComponent->getName()).append(".").append(modifiersIterator.key());
    QString modifierValue = modifiersIterator.value();
    if (MainWindow::instance()->getOMCProxy()->setComponentModifierValue(modelName, modifierName, modifierValue)) {
      modifierValueChanged = true;
    }
  }
  if (modifierValueChanged) {
    pComponent->componentParameterHasChanged();
  }
}

UpdateComponentParametersCommand::UpdateComponentParametersCommand(Element *pComponent, QMap<QString, QString> oldComponentModifiersMap,
                                                                   QMap<QString, QString> oldComponentExtendsModifiersMap,
                                                                   QMap<QString, QString> newComponentModifiersMap,
                                                                   QMap<QString, QString> newComponentExtendsModifiersMap,
                                                                   UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpComponent = pComponent;
  mOldComponentModifiersMap = oldComponentModifiersMap;
  mOldComponentExtendsModifiersMap = oldComponentExtendsModifiersMap;
  mNewComponentModifiersMap = newComponentModifiersMap;
  mNewComponentExtendsModifiersMap = newComponentExtendsModifiersMap;
  setText(QString("Update Component %1 Parameters").arg(mpComponent->getName()));
}

/*!
 * \brief UpdateComponentParametersCommand::redoInternal
 * redoInternal the UpdateComponentParametersCommand.
 */
void UpdateComponentParametersCommand::redoInternal()
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QString className = mpComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  if (!mpComponent->getReferenceComponent()) {
    // remove all the modifiers of a component.
    pOMCProxy->removeComponentModifiers(className, mpComponent->getName());
    // apply the new Component modifiers if any
    QMap<QString, QString>::iterator componentModifier;
    for (componentModifier = mNewComponentModifiersMap.begin(); componentModifier != mNewComponentModifiersMap.end(); ++componentModifier) {
      QString modifierValue = componentModifier.value();
      QString modifierKey = QString(mpComponent->getName()).append(".").append(componentModifier.key());
      pOMCProxy->setComponentModifierValue(className, modifierKey, modifierValue);
    }
    // we want to load modifiers even if they are loaded already
    mpComponent->getComponentInfo()->setModifiersLoaded(false);
    mpComponent->getComponentInfo()->getModifiersMap(pOMCProxy, className, mpComponent);
  } else {
    QString inheritedClassName;
    inheritedClassName = mpComponent->getReferenceComponent()->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
    // apply the new Component extends modifiers if any
    QMap<QString, QString>::iterator componentExtendsModifier;
    for (componentExtendsModifier = mNewComponentExtendsModifiersMap.begin(); componentExtendsModifier != mNewComponentExtendsModifiersMap.end(); ++componentExtendsModifier) {
      QString modifierValue = componentExtendsModifier.value();
      pOMCProxy->setExtendsModifierValue(className, inheritedClassName, componentExtendsModifier.key(), modifierValue);
    }
    mpComponent->getGraphicsView()->getModelWidget()->fetchExtendsModifiers(inheritedClassName);
  }
  mpComponent->componentParameterHasChanged();
}

/*!
 * \brief UpdateComponentParametersCommand::undo
 * Undo the UpdateComponentParametersCommand.
 */
void UpdateComponentParametersCommand::undo()
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QString className = mpComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  if (!mpComponent->getReferenceComponent()) {
    // remove all the modifiers of a component.
    pOMCProxy->removeComponentModifiers(className, mpComponent->getName());
    // apply the old Component modifiers if any
    QMap<QString, QString>::iterator componentModifier;
    for (componentModifier = mOldComponentModifiersMap.begin(); componentModifier != mOldComponentModifiersMap.end(); ++componentModifier) {
      QString modifierValue = componentModifier.value();
      QString modifierKey = QString(mpComponent->getName()).append(".").append(componentModifier.key());
      pOMCProxy->setComponentModifierValue(className, modifierKey, modifierValue);
    }
    // we want to load modifiers even if they are loaded already
    mpComponent->getComponentInfo()->setModifiersLoaded(false);
    mpComponent->getComponentInfo()->getModifiersMap(pOMCProxy, className, mpComponent);
  } else {
    QString inheritedClassName;
    inheritedClassName = mpComponent->getReferenceComponent()->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
    // remove all the extends modifiers.
    pOMCProxy->removeExtendsModifiers(className, inheritedClassName);
    // apply the new Component extends modifiers if any
    QMap<QString, QString>::iterator componentExtendsModifier;
    for (componentExtendsModifier = mOldComponentExtendsModifiersMap.begin(); componentExtendsModifier != mOldComponentExtendsModifiersMap.end(); ++componentExtendsModifier) {
      QString modifierValue = componentExtendsModifier.value();
      pOMCProxy->setExtendsModifierValue(className, inheritedClassName, componentExtendsModifier.key(), modifierValue);
    }
    mpComponent->getGraphicsView()->getModelWidget()->fetchExtendsModifiers(inheritedClassName);
  }
  mpComponent->componentParameterHasChanged();
}

DeleteComponentCommand::DeleteComponentCommand(Element *pComponent, GraphicsView *pGraphicsView, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpComponent = pComponent;
  mpGraphicsView = pGraphicsView;
  // save component modifiers before deleting if any
  mpComponent->getComponentInfo()->getModifiersMap(MainWindow::instance()->getOMCProxy(), mpComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure(), mpComponent);
  //Save sub-model parameters for composite models
  if (pGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    CompositeModelEditor *pEditor = qobject_cast<CompositeModelEditor*>(pGraphicsView->getModelWidget()->getEditor());
    mParameterNames = pEditor->getParameterNames(pComponent->getName());  //Assume submodel; otherwise returned list is empty
    foreach(QString parName, mParameterNames) {
      mParameterValues.append(pEditor->getParameterValue(pComponent->getName(), parName));
    }
  }
}

/*!
 * \brief DeleteComponentCommand::redoInternal
 * redoInternal the DeleteComponentCommand.
 */
void DeleteComponentCommand::redoInternal()
{
  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  // if component is of connector type && containing class is Modelica type.
  if (mpComponent->getLibraryTreeItem() && mpComponent->getLibraryTreeItem()->isConnector() && pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    // Connector type components exists on both icon and diagram views
    GraphicsView *pGraphicsView;
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      pGraphicsView = mpGraphicsView->getModelWidget()->getDiagramGraphicsView();
    } else {
      pGraphicsView = mpGraphicsView->getModelWidget()->getIconGraphicsView();
    }
    Element *pComponent = pGraphicsView->getComponentObject(mpComponent->getName());
    if (pComponent) {
      pGraphicsView->removeItem(pComponent);
      pGraphicsView->removeItem(pComponent->getOriginItem());
      pGraphicsView->deleteComponentFromList(pComponent);
      pGraphicsView->addComponentToOutOfSceneList(pComponent);
      pComponent->emitDeleted();
    }
  }
  mpGraphicsView->removeItem(mpComponent);
  mpGraphicsView->removeItem(mpComponent->getOriginItem());
  mpGraphicsView->deleteComponentFromList(mpComponent);
  mpGraphicsView->addComponentToOutOfSceneList(mpComponent);
  mpComponent->emitDeleted();
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
  if (mpComponent->getLibraryTreeItem() && mpComponent->getLibraryTreeItem()->isConnector() && pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    // Connector type components exists on both icon and diagram views
    GraphicsView *pGraphicsView;
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      pGraphicsView = mpGraphicsView->getModelWidget()->getDiagramGraphicsView();
    } else {
      pGraphicsView = mpGraphicsView->getModelWidget()->getIconGraphicsView();
    }
    Element *pComponent = pGraphicsView->getComponentObject(mpComponent->getName());
    if (pComponent) {
      pGraphicsView->addItem(pComponent);
      pGraphicsView->addItem(pComponent->getOriginItem());
      pGraphicsView->addComponentToList(pComponent);
      pGraphicsView->deleteComponentFromOutOfSceneList(pComponent);
      pComponent->emitAdded();
    }
  }
  mpGraphicsView->addItem(mpComponent);
  mpGraphicsView->addItem(mpComponent->getOriginItem());
  mpGraphicsView->addComponentToList(mpComponent);
  mpGraphicsView->deleteComponentFromOutOfSceneList(mpComponent);
  mpComponent->emitAdded();
  mpGraphicsView->addComponentToClass(mpComponent);
  UpdateComponentAttributesCommand::updateComponentModifiers(mpComponent, *mpComponent->getComponentInfo());
  // Restore sub-model parameters for composite models
  if (pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    CompositeModelEditor *pEditor = qobject_cast<CompositeModelEditor*>(pModelWidget->getEditor());
    for(int i=0; i<mParameterNames.size(); ++i) {
      pEditor->setParameterValue(mpComponent->getName(),mParameterNames[i],mParameterValues[i]);
    }
  }
}

AddConnectionCommand::AddConnectionCommand(LineAnnotation *pConnectionLineAnnotation, bool addConnection, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  mAddConnection = addConnection;
  setText(QString("Add Connection connect(%1, %2)").arg(mpConnectionLineAnnotation->getStartComponentName(), mpConnectionLineAnnotation->getEndComponentName()));

  mpConnectionLineAnnotation->updateToolTip();
  mpConnectionLineAnnotation->drawCornerItems();
  mpConnectionLineAnnotation->setCornerItemsActiveOrPassive();
}

/*!
 * \brief AddConnectionCommand::redoInternal
 * redoInternal the AddConnectionCommand.
 */
void AddConnectionCommand::redoInternal()
{
  // Add the start component connection details.
  Element *pStartComponent = mpConnectionLineAnnotation->getStartComponent();
  if (pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->addConnectionDetails(mpConnectionLineAnnotation);
  } else {
    pStartComponent->addConnectionDetails(mpConnectionLineAnnotation);
  }
  // Add the end component connection details.
  Element *pEndComponent = mpConnectionLineAnnotation->getEndComponent();
  if (pEndComponent->getRootParentComponent()) {
    pEndComponent->getRootParentComponent()->addConnectionDetails(mpConnectionLineAnnotation);
  } else {
    pEndComponent->addConnectionDetails(mpConnectionLineAnnotation);
  }
  mpConnectionLineAnnotation->getGraphicsView()->addConnectionToList(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->getGraphicsView()->deleteConnectionFromOutOfSceneList(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->getGraphicsView()->addItem(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->emitAdded();
  if (mAddConnection) {
    if (!mpConnectionLineAnnotation->getGraphicsView()->addConnectionToClass(mpConnectionLineAnnotation)) {
      setFailed(true);
      return;
    }
  }
}

/*!
 * \brief AddConnectionCommand::undo
 * Undo the AddConnectionCommand.
 */
void AddConnectionCommand::undo()
{
  // Remove the start component connection details.
  Element *pStartComponent = mpConnectionLineAnnotation->getStartComponent();
  if (pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->removeConnectionDetails(mpConnectionLineAnnotation);
  } else {
    pStartComponent->removeConnectionDetails(mpConnectionLineAnnotation);
  }
  // Remove the end component connection details.
  Element *pEndComponent = mpConnectionLineAnnotation->getEndComponent();
  if (pEndComponent->getRootParentComponent()) {
    pEndComponent->getRootParentComponent()->removeConnectionDetails(mpConnectionLineAnnotation);
  } else {
    pEndComponent->removeConnectionDetails(mpConnectionLineAnnotation);
  }
  mpConnectionLineAnnotation->getGraphicsView()->deleteConnectionFromList(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->getGraphicsView()->addConnectionToOutOfSceneList(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->getGraphicsView()->removeItem(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->emitDeleted();
  mpConnectionLineAnnotation->getGraphicsView()->deleteConnectionFromClass(mpConnectionLineAnnotation);
}

UpdateConnectionCommand::UpdateConnectionCommand(LineAnnotation *pConnectionLineAnnotation, QString oldAnnotaton, QString newAnnotation,
                                                 UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  mOldAnnotation = oldAnnotaton;
  mNewAnnotation = newAnnotation;
  setText(QString("Update Connection connect(%1, %2)").arg(mpConnectionLineAnnotation->getStartComponentName(),
                                                           mpConnectionLineAnnotation->getEndComponentName()));
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
  auto updateFunction = std::bind(&LineAnnotation::updateConnectionAnnotation ,mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->redraw(annotation, updateFunction);
}

UpdateCompositeModelConnection::UpdateCompositeModelConnection(LineAnnotation *pConnectionLineAnnotation,
                                                               CompositeModelConnection oldCompositeModelConnection,
                                                               CompositeModelConnection newCompositeModelConnection, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  mOldCompositeModelConnection = oldCompositeModelConnection;
  mNewCompositeModelConnection = newCompositeModelConnection;
  setText(QString("Update CompositeModel Connection connect(%1, %2)").arg(mpConnectionLineAnnotation->getStartComponentName(),
                                                                          mpConnectionLineAnnotation->getEndComponentName()));
}

/*!
 * \brief UpdateCompositeModelConnection::redoInternal
 * redoInternal the UpdateCompositeModelConnection.
 */
void UpdateCompositeModelConnection::redoInternal()
{
  mpConnectionLineAnnotation->setDelay(mNewCompositeModelConnection.mDelay);
  mpConnectionLineAnnotation->setZf(mNewCompositeModelConnection.mZf);
  mpConnectionLineAnnotation->setZfr(mNewCompositeModelConnection.mZfr);
  mpConnectionLineAnnotation->setAlpha(mNewCompositeModelConnection.mAlpha);
  mpConnectionLineAnnotation->getGraphicsView()->updateConnectionInClass(mpConnectionLineAnnotation);
}

/*!
 * \brief UpdateCompositeModelConnection::undo
 * Undo the UpdateCompositeModelConnection.
 */
void UpdateCompositeModelConnection::undo()
{
  mpConnectionLineAnnotation->setDelay(mOldCompositeModelConnection.mDelay);
  mpConnectionLineAnnotation->setZf(mOldCompositeModelConnection.mZf);
  mpConnectionLineAnnotation->setZfr(mOldCompositeModelConnection.mZfr);
  mpConnectionLineAnnotation->setAlpha(mOldCompositeModelConnection.mAlpha);
  mpConnectionLineAnnotation->getGraphicsView()->updateConnectionInClass(mpConnectionLineAnnotation);
}

DeleteConnectionCommand::DeleteConnectionCommand(LineAnnotation *pConnectionLineAnnotation, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  setText(QString("Delete Connection connect(%1, %2)").arg(mpConnectionLineAnnotation->getStartComponentName(),
                                                           mpConnectionLineAnnotation->getEndComponentName()));
}

/*!
 * \brief DeleteConnectionCommand::redoInternal
 * redoInternal the DeleteConnectionCommand.
 */
void DeleteConnectionCommand::redoInternal()
{
  // Remove the start component connection details.
  Element *pStartComponent = mpConnectionLineAnnotation->getStartComponent();
  if (pStartComponent && pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->removeConnectionDetails(mpConnectionLineAnnotation);
  } else if (pStartComponent) {
    pStartComponent->removeConnectionDetails(mpConnectionLineAnnotation);
  }
  // Remove the end component connection details.
  Element *pEndComponent = mpConnectionLineAnnotation->getEndComponent();
  if (pEndComponent && pEndComponent->getRootParentComponent()) {
    pEndComponent->getRootParentComponent()->removeConnectionDetails(mpConnectionLineAnnotation);
  } else if (pEndComponent) {
    pEndComponent->removeConnectionDetails(mpConnectionLineAnnotation);
  }
  mpConnectionLineAnnotation->getGraphicsView()->deleteConnectionFromList(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->getGraphicsView()->addConnectionToOutOfSceneList(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->getGraphicsView()->removeItem(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->emitDeleted();
  mpConnectionLineAnnotation->getGraphicsView()->deleteConnectionFromClass(mpConnectionLineAnnotation);
}

/*!
 * \brief DeleteConnectionCommand::undo
 * Undo the DeleteConnectionCommand.
 */
void DeleteConnectionCommand::undo()
{
  // Add the start component connection details.
  Element *pStartComponent = mpConnectionLineAnnotation->getStartComponent();
  if (pStartComponent && pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->addConnectionDetails(mpConnectionLineAnnotation);
  } else if (pStartComponent) {
    pStartComponent->addConnectionDetails(mpConnectionLineAnnotation);
  }
  // Add the end component connection details.
  Element *pEndComponent = mpConnectionLineAnnotation->getEndComponent();
  if (pEndComponent && pEndComponent->getRootParentComponent()) {
    pEndComponent->getRootParentComponent()->addConnectionDetails(mpConnectionLineAnnotation);
  } else if (pEndComponent) {
    pEndComponent->addConnectionDetails(mpConnectionLineAnnotation);
  }
  mpConnectionLineAnnotation->getGraphicsView()->addConnectionToList(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->getGraphicsView()->deleteConnectionFromOutOfSceneList(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->getGraphicsView()->addItem(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->emitAdded();
  mpConnectionLineAnnotation->getGraphicsView()->addConnectionToClass(mpConnectionLineAnnotation, true);
}

AddTransitionCommand::AddTransitionCommand(LineAnnotation *pTransitionLineAnnotation, bool addTransition, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpTransitionLineAnnotation = pTransitionLineAnnotation;
  mAddTransition = addTransition;
  setText(QString("Add Transition transition(%1, %2)").arg(mpTransitionLineAnnotation->getStartComponentName(),
                                                           mpTransitionLineAnnotation->getEndComponentName()));

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
  mpTransitionLineAnnotation->getGraphicsView()->addTransitionToList(mpTransitionLineAnnotation);
  mpTransitionLineAnnotation->getGraphicsView()->deleteTransitionFromOutOfSceneList(mpTransitionLineAnnotation);
  // Add the start component transition details.
  Element *pStartComponent = mpTransitionLineAnnotation->getStartComponent();
  if (pStartComponent && pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->addConnectionDetails(mpTransitionLineAnnotation);
    pStartComponent->getRootParentComponent()->setHasTransition(true);
  } else if (pStartComponent) {
    pStartComponent->addConnectionDetails(mpTransitionLineAnnotation);
    pStartComponent->setHasTransition(true);
  }
  // Add the end component connection details.
  Element *pEndComponent = mpTransitionLineAnnotation->getEndComponent();
  if (pEndComponent && pEndComponent->getRootParentComponent()) {
    pEndComponent->getRootParentComponent()->addConnectionDetails(mpTransitionLineAnnotation);
    pEndComponent->getRootParentComponent()->setHasTransition(true);
  } else if (pEndComponent) {
    pEndComponent->addConnectionDetails(mpTransitionLineAnnotation);
    pEndComponent->setHasTransition(true);
  }
  mpTransitionLineAnnotation->getTextAnnotation()->setTextString("%condition");
  mpTransitionLineAnnotation->getTextAnnotation()->updateTextString();
  mpTransitionLineAnnotation->updateTransitionTextPosition();
  mpTransitionLineAnnotation->getGraphicsView()->addItem(mpTransitionLineAnnotation);
  mpTransitionLineAnnotation->emitAdded();
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
  mpTransitionLineAnnotation->getGraphicsView()->deleteTransitionFromList(mpTransitionLineAnnotation);
  mpTransitionLineAnnotation->getGraphicsView()->addTransitionToOutOfSceneList(mpTransitionLineAnnotation);
  // Remove the start component connection details.
  Element *pStartComponent = mpTransitionLineAnnotation->getStartComponent();
  if (pStartComponent && pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->removeConnectionDetails(mpTransitionLineAnnotation);
    pStartComponent->getRootParentComponent()->setHasTransition(false);
  } else if (pStartComponent) {
    pStartComponent->removeConnectionDetails(mpTransitionLineAnnotation);
    pStartComponent->setHasTransition(false);
  }
  // Remove the end component connection details.
  Element *pEndComponent = mpTransitionLineAnnotation->getEndComponent();
  if (pEndComponent && pEndComponent->getRootParentComponent()) {
    pEndComponent->getRootParentComponent()->removeConnectionDetails(mpTransitionLineAnnotation);
    pEndComponent->getRootParentComponent()->setHasTransition(false);
  } else if (pEndComponent) {
    pEndComponent->removeConnectionDetails(mpTransitionLineAnnotation);
    pEndComponent->setHasTransition(false);
  }
  mpTransitionLineAnnotation->getTextAnnotation()->setTextString("%condition");
  mpTransitionLineAnnotation->getTextAnnotation()->updateTextString();
  mpTransitionLineAnnotation->updateTransitionTextPosition();
  mpTransitionLineAnnotation->getGraphicsView()->removeItem(mpTransitionLineAnnotation);
  mpTransitionLineAnnotation->emitDeleted();
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
  setText(QString("Update Transition transition(%1, %2)").arg(mpTransitionLineAnnotation->getStartComponentName(),
                                                              mpTransitionLineAnnotation->getEndComponentName()));
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
  mpTransitionLineAnnotation->getGraphicsView()->deleteTransitionFromList(mpTransitionLineAnnotation);
  mpTransitionLineAnnotation->getGraphicsView()->addTransitionToOutOfSceneList(mpTransitionLineAnnotation);
  // Remove the start component connection details.
  Element *pStartComponent = mpTransitionLineAnnotation->getStartComponent();
  if (pStartComponent && pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->removeConnectionDetails(mpTransitionLineAnnotation);
    pStartComponent->getRootParentComponent()->setHasTransition(false);
  } else if (pStartComponent) {
    pStartComponent->removeConnectionDetails(mpTransitionLineAnnotation);
    pStartComponent->setHasTransition(false);
  }
  // Remove the end component connection details.
  Element *pEndComponent = mpTransitionLineAnnotation->getEndComponent();
  if (pEndComponent && pEndComponent->getRootParentComponent()) {
    pEndComponent->getRootParentComponent()->removeConnectionDetails(mpTransitionLineAnnotation);
    pEndComponent->getRootParentComponent()->setHasTransition(false);
  } else if (pEndComponent) {
    pEndComponent->removeConnectionDetails(mpTransitionLineAnnotation);
    pEndComponent->setHasTransition(false);
  }
  mpTransitionLineAnnotation->getGraphicsView()->removeItem(mpTransitionLineAnnotation);
  mpTransitionLineAnnotation->emitDeleted();
  mpTransitionLineAnnotation->getGraphicsView()->deleteTransitionFromClass(mpTransitionLineAnnotation);
}

/*!
 * \brief DeleteTransitionCommand::undo
 * Undo the DeleteTransitionCommand.
 */
void DeleteTransitionCommand::undo()
{
  mpTransitionLineAnnotation->getGraphicsView()->addTransitionToList(mpTransitionLineAnnotation);
  mpTransitionLineAnnotation->getGraphicsView()->deleteTransitionFromOutOfSceneList(mpTransitionLineAnnotation);
  // Add the start component connection details.
  Element *pStartComponent = mpTransitionLineAnnotation->getStartComponent();
  if (pStartComponent && pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->addConnectionDetails(mpTransitionLineAnnotation);
    pStartComponent->getRootParentComponent()->setHasTransition(true);
  } else if (pStartComponent) {
    pStartComponent->addConnectionDetails(mpTransitionLineAnnotation);
    pStartComponent->setHasTransition(true);
  }
  // Add the end component connection details.
  Element *pEndComponent = mpTransitionLineAnnotation->getEndComponent();
  if (pEndComponent && pEndComponent->getRootParentComponent()) {
    pEndComponent->getRootParentComponent()->addConnectionDetails(mpTransitionLineAnnotation);
    pEndComponent->getRootParentComponent()->setHasTransition(true);
  } else if (pEndComponent) {
    pEndComponent->addConnectionDetails(mpTransitionLineAnnotation);
    pEndComponent->setHasTransition(true);
  }
  mpTransitionLineAnnotation->getGraphicsView()->addItem(mpTransitionLineAnnotation);
  mpTransitionLineAnnotation->emitAdded();
  mpTransitionLineAnnotation->getGraphicsView()->addTransitionToClass(mpTransitionLineAnnotation);
}

AddInitialStateCommand::AddInitialStateCommand(LineAnnotation *pInitialStateLineAnnotation, bool addInitialState, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpInitialStateLineAnnotation = pInitialStateLineAnnotation;
  mAddInitialState = addInitialState;
  setText(QString("Add InitialState initialState(%1)").arg(mpInitialStateLineAnnotation->getStartComponentName()));

  mpInitialStateLineAnnotation->setToolTip(QString("<b>initialState</b>(%1)").arg(mpInitialStateLineAnnotation->getStartComponentName()));
  mpInitialStateLineAnnotation->drawCornerItems();
  mpInitialStateLineAnnotation->setCornerItemsActiveOrPassive();
}

/*!
 * \brief AddInitialStateCommand::redoInternal
 * redoInternal the AddInitialStateCommand.
 */
void AddInitialStateCommand::redoInternal()
{
  mpInitialStateLineAnnotation->getGraphicsView()->addInitialStateToList(mpInitialStateLineAnnotation);
  mpInitialStateLineAnnotation->getGraphicsView()->deleteInitialStateFromOutOfSceneList(mpInitialStateLineAnnotation);
  // Add the start component transition details.
  Element *pStartComponent = mpInitialStateLineAnnotation->getStartComponent();
  if (pStartComponent && pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->addConnectionDetails(mpInitialStateLineAnnotation);
    pStartComponent->getRootParentComponent()->setIsInitialState(true);
  } else if (pStartComponent) {
    pStartComponent->addConnectionDetails(mpInitialStateLineAnnotation);
    pStartComponent->setIsInitialState(true);
  }
  mpInitialStateLineAnnotation->getGraphicsView()->addItem(mpInitialStateLineAnnotation);
  mpInitialStateLineAnnotation->emitAdded();
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
  mpInitialStateLineAnnotation->getGraphicsView()->deleteInitialStateFromList(mpInitialStateLineAnnotation);
  mpInitialStateLineAnnotation->getGraphicsView()->addInitialStateToOutOfSceneList(mpInitialStateLineAnnotation);
  // Remove the start component connection details.
  Element *pStartComponent = mpInitialStateLineAnnotation->getStartComponent();
  if (pStartComponent && pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->removeConnectionDetails(mpInitialStateLineAnnotation);
    pStartComponent->getRootParentComponent()->setIsInitialState(false);
  } else if (pStartComponent) {
    pStartComponent->removeConnectionDetails(mpInitialStateLineAnnotation);
    pStartComponent->setIsInitialState(false);
  }
  mpInitialStateLineAnnotation->getGraphicsView()->removeItem(mpInitialStateLineAnnotation);
  mpInitialStateLineAnnotation->emitDeleted();
  mpInitialStateLineAnnotation->getGraphicsView()->deleteInitialStateFromClass(mpInitialStateLineAnnotation);
}

UpdateInitialStateCommand::UpdateInitialStateCommand(LineAnnotation *pInitialStateLineAnnotation, QString oldAnnotaton, QString newAnnotation,
                                                     UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpInitialStateLineAnnotation = pInitialStateLineAnnotation;
  mOldAnnotation = oldAnnotaton;
  mNewAnnotation = newAnnotation;
  setText(QString("Update InitialState initialState(%1)").arg(mpInitialStateLineAnnotation->getStartComponentName()));
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
  mpInitialStateLineAnnotation->getGraphicsView()->deleteInitialStateFromList(mpInitialStateLineAnnotation);
  mpInitialStateLineAnnotation->getGraphicsView()->addInitialStateToOutOfSceneList(mpInitialStateLineAnnotation);
  // Remove the start component connection details.
  Element *pStartComponent = mpInitialStateLineAnnotation->getStartComponent();
  if (pStartComponent && pStartComponent->getRootParentComponent()) {
//    pStartComponent->getRootParentComponent()->removeConnectionDetails(mpTransitionLineAnnotation);
    pStartComponent->getRootParentComponent()->setIsInitialState(false);
  } else if (pStartComponent) {
    //pStartComponent->removeConnectionDetails(mpTransitionLineAnnotation);
    pStartComponent->setIsInitialState(false);
  }
  mpInitialStateLineAnnotation->getGraphicsView()->removeItem(mpInitialStateLineAnnotation);
  mpInitialStateLineAnnotation->emitDeleted();
  mpInitialStateLineAnnotation->getGraphicsView()->deleteInitialStateFromClass(mpInitialStateLineAnnotation);
}

/*!
 * \brief DeleteInitialStateCommand::undo
 * Undo the DeleteInitialStateCommand.
 */
void DeleteInitialStateCommand::undo()
{
  mpInitialStateLineAnnotation->getGraphicsView()->addInitialStateToList(mpInitialStateLineAnnotation);
  mpInitialStateLineAnnotation->getGraphicsView()->deleteInitialStateFromOutOfSceneList(mpInitialStateLineAnnotation);
  // Add the start component connection details.
  Element *pStartComponent = mpInitialStateLineAnnotation->getStartComponent();
  if (pStartComponent && pStartComponent->getRootParentComponent()) {
//    pStartComponent->getRootParentComponent()->addConnectionDetails(mpTransitionLineAnnotation);
    pStartComponent->getRootParentComponent()->setIsInitialState(true);
  } else if (pStartComponent) {
//    pStartComponent->addConnectionDetails(mpTransitionLineAnnotation);
    pStartComponent->setIsInitialState(true);
  }
  mpInitialStateLineAnnotation->getGraphicsView()->addItem(mpInitialStateLineAnnotation);
  mpInitialStateLineAnnotation->emitAdded();
  mpInitialStateLineAnnotation->getGraphicsView()->addInitialStateToClass(mpInitialStateLineAnnotation);
}

UpdateCoOrdinateSystemCommand::UpdateCoOrdinateSystemCommand(GraphicsView *pGraphicsView, CoOrdinateSystem oldCoOrdinateSystem,
                                                             CoOrdinateSystem newCoOrdinateSystem, bool copyProperties, const QString &oldVersion,
                                                             const QString &newVersion, const QString &oldUsesAnnotationString,
                                                             const QString &newUsesAnnotationString, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpGraphicsView = pGraphicsView;
  mOldCoOrdinateSystem = oldCoOrdinateSystem;
  mNewCoOrdinateSystem = newCoOrdinateSystem;
  mCopyProperties = copyProperties;
  mOldVersion = oldVersion;
  mNewVersion = newVersion;
  mOldUsesAnnotationString = oldUsesAnnotationString;
  mNewUsesAnnotationString = newUsesAnnotationString;
  setText(QString("Update %1 CoOrdinate System").arg(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure()));
}

/*!
 * \brief UpdateClassCoOrdinateSystemCommand::redoInternal
 * redoInternal the UpdateClassCoOrdinateSystemCommand.
 */
void UpdateCoOrdinateSystemCommand::redoInternal()
{
  mpGraphicsView->setCoOrdinateSystem(mNewCoOrdinateSystem);
  mpGraphicsView->getModelWidget()->drawModelCoOrdinateSystem(mpGraphicsView);
  mpGraphicsView->addClassAnnotation();
  mpGraphicsView->fitInViewInternal();
  updateReferencedShapes(mpGraphicsView);
  mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitCoOrdinateSystemUpdated(mpGraphicsView);
  // if copy properties is true
  if (mCopyProperties) {
    GraphicsView *pGraphicsView;
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      pGraphicsView = mpGraphicsView->getModelWidget()->getDiagramGraphicsView();
    } else {
      pGraphicsView = mpGraphicsView->getModelWidget()->getIconGraphicsView();
    }
    pGraphicsView->setCoOrdinateSystem(mNewCoOrdinateSystem);
    pGraphicsView->getModelWidget()->drawModelCoOrdinateSystem(pGraphicsView);
    pGraphicsView->addClassAnnotation();
    pGraphicsView->fitInViewInternal();
    updateReferencedShapes(pGraphicsView);
    pGraphicsView->getModelWidget()->getLibraryTreeItem()->emitCoOrdinateSystemUpdated(pGraphicsView);
  }
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  // only add version and uses annotation to top level class.
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isTopLevel()) {
    // version
    QString versionAnnotation = QString("annotate=version(\"%1\")").arg(mNewVersion);
    if (pOMCProxy->addClassAnnotation(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), versionAnnotation)) {
      mpGraphicsView->getModelWidget()->getLibraryTreeItem()->mClassInformation.version = mNewVersion;
    }
    // uses annotation
    pOMCProxy->addClassAnnotation(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), mNewUsesAnnotationString);
  }
}

/*!
 * \brief UpdateClassCoOrdinateSystemCommand::undo
 * Undo the UpdateClassCoOrdinateSystemCommand.
 */
void UpdateCoOrdinateSystemCommand::undo()
{
  mpGraphicsView->setCoOrdinateSystem(mOldCoOrdinateSystem);
  mpGraphicsView->getModelWidget()->drawModelCoOrdinateSystem(mpGraphicsView);
  mpGraphicsView->addClassAnnotation();
  mpGraphicsView->fitInViewInternal();
  updateReferencedShapes(mpGraphicsView);
  mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitCoOrdinateSystemUpdated(mpGraphicsView);
  // if copy properties is true
  if (mCopyProperties) {
    GraphicsView *pGraphicsView;
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      pGraphicsView = mpGraphicsView->getModelWidget()->getDiagramGraphicsView();
    } else {
      pGraphicsView = mpGraphicsView->getModelWidget()->getIconGraphicsView();
    }
    pGraphicsView->setCoOrdinateSystem(mOldCoOrdinateSystem);
    pGraphicsView->getModelWidget()->drawModelCoOrdinateSystem(pGraphicsView);
    pGraphicsView->addClassAnnotation();
    pGraphicsView->fitInViewInternal();
    updateReferencedShapes(pGraphicsView);
    pGraphicsView->getModelWidget()->getLibraryTreeItem()->emitCoOrdinateSystemUpdated(pGraphicsView);
  }
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  // only add version and uses annotation to top level class.
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isTopLevel()) {
    // version
    QString versionAnnotation = QString("annotate=version(\"%1\")").arg(mOldVersion);
    if (pOMCProxy->addClassAnnotation(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), versionAnnotation)) {
      mpGraphicsView->getModelWidget()->getLibraryTreeItem()->mClassInformation.version = mOldVersion;
    }
    // uses annotation
    pOMCProxy->addClassAnnotation(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), mOldUsesAnnotationString);
  }
}

/*!
 * \brief UpdateCoOrdinateSystemCommand::updateReferencedShapes
 * \param pGraphicsView
 */
void UpdateCoOrdinateSystemCommand::updateReferencedShapes(GraphicsView *pGraphicsView)
{
  /* If preserveAspectRatio is changed emit changed signal of all the shapes so that
   * the inherited items gets updated accordingly using the iconmap/diagrammap
   */
  if (mNewCoOrdinateSystem.getPreserveAspectRatio() != mOldCoOrdinateSystem.getPreserveAspectRatio()) {
    foreach (ShapeAnnotation *pShapeAnnotation, pGraphicsView->getShapesList()) {
      pShapeAnnotation->emitChanged();
    }
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

UpdateSubModelAttributesCommand::UpdateSubModelAttributesCommand(Element *pComponent, const ElementInfo &oldComponentInfo,
                                                                 const ElementInfo &newComponentInfo,
                                                                 QStringList &parameterNames, QStringList &oldParameterValues,
                                                                 QStringList &newParameterValues, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpComponent = pComponent;
  mOldComponentInfo.updateElementInfo(&oldComponentInfo);
  mNewComponentInfo.updateElementInfo(&newComponentInfo);
  setText(QString("Update SubModel %1 Attributes").arg(mpComponent->getName()));

  //Save sub-model parameters for composite models
  mParameterNames = parameterNames;
  mOldParameterValues = oldParameterValues;
  mNewParameterValues = newParameterValues;
}

/*!
 * \brief UpdateSubModelAttributesCommand::redoInternal
 * redoInternal the UpdateSubModelAttributesCommand.
 */
void UpdateSubModelAttributesCommand::redoInternal()
{
  CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpComponent->getGraphicsView()->getModelWidget()->getEditor());
  pCompositeModelEditor->updateSubModelParameters(mpComponent->getName(), mNewComponentInfo.getStartCommand(),
                                                  mNewComponentInfo.getExactStep() ? "true" : "false", mNewComponentInfo.getGeometryFile());
  mpComponent->getComponentInfo()->setStartCommand(mNewComponentInfo.getStartCommand());
  mpComponent->getComponentInfo()->setExactStep(mNewComponentInfo.getExactStep());
  mpComponent->getComponentInfo()->setGeometryFile(mNewComponentInfo.getGeometryFile());

  if(mpComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    for(int i=0; i<mParameterNames.size(); ++i) {
      pCompositeModelEditor->setParameterValue(mpComponent->getName(), mParameterNames[i], mNewParameterValues[i]);
    }
  }
}

/*!
 * \brief UpdateSubModelAttributesCommand::undo
 * Undo the UpdateSubModelAttributesCommand.
 */
void UpdateSubModelAttributesCommand::undo()
{
  CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpComponent->getGraphicsView()->getModelWidget()->getEditor());
  pCompositeModelEditor->updateSubModelParameters(mpComponent->getName(), mOldComponentInfo.getStartCommand(),
                                                  mOldComponentInfo.getExactStep() ? "true" : "false", mOldComponentInfo.getGeometryFile());
  mpComponent->getComponentInfo()->setStartCommand(mOldComponentInfo.getStartCommand());
  mpComponent->getComponentInfo()->setExactStep(mOldComponentInfo.getExactStep());
  mpComponent->getComponentInfo()->setGeometryFile(mOldComponentInfo.getGeometryFile());

  if(mpComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    for(int i=0; i<mParameterNames.size(); ++i) {
      pCompositeModelEditor->setParameterValue(mpComponent->getName(), mParameterNames[i], mOldParameterValues[i]);
    }
  }
}

UpdateSimulationParamsCommand::UpdateSimulationParamsCommand(LibraryTreeItem *pLibraryTreeItem, QString oldStartTime, QString newStartTime, QString oldStopTime,
                                                             QString newStopTime, UndoCommand *pParent )
  : UndoCommand(pParent)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  mOldStartTime = oldStartTime;
  mNewStartTime = newStartTime;
  mOldStopTime = oldStopTime;
  mNewStopTime = newStopTime;
  setText(QString("Update %1 simulation parameter").arg(mpLibraryTreeItem->getNameStructure()));
}

/*!
 * \brief UpdateSimulationParamsCommand::redoInternal
 * redoInternal the UpdateSimulationParamsCommand.
 */
void UpdateSimulationParamsCommand::redoInternal()
{
  CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpLibraryTreeItem->getModelWidget()->getEditor());
  pCompositeModelEditor->updateSimulationParams(mNewStartTime, mNewStopTime);
}

/*!
 * \brief UpdateSimulationParamsCommand::undo
 * Undo the UpdateSimulationParamsCommand.
 */
void UpdateSimulationParamsCommand::undo()
{
  CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpLibraryTreeItem->getModelWidget()->getEditor());
  pCompositeModelEditor->updateSimulationParams(mOldStartTime, mOldStopTime);
}

/*!
 * \brief AlignInterfacesCommand::AlignInterfacesCommand
 * \param pEditor
 * \param oldText
 * \param newText
 * \param pParent
 */
AlignInterfacesCommand::AlignInterfacesCommand(CompositeModelEditor *pCompositeModelEditor, QString fromInterface, QString toInterface,
                                               QGenericMatrix<3,1,double> oldPos, QGenericMatrix<3,1,double> oldRot,
                                               QGenericMatrix<3,1,double> newPos, QGenericMatrix<3,1,double> newRot,
                                               LineAnnotation *pConnectionLineAnnotation, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpCompositeModelEditor = pCompositeModelEditor;
  mFromInterface = fromInterface;
  mToInterface = toInterface;
  mOldPos = oldPos;
  mOldRot = oldRot;
  mNewPos = newPos;
  mNewRot = newRot;
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
}

/*!
 * \brief AlignInterfacesCommand::redoInternal
 * redoInternal the align interfaces command
 */
void AlignInterfacesCommand::redoInternal()
{
  mpCompositeModelEditor->updateSubModelOrientation(mFromInterface.split(".").first(), mNewPos, mNewRot);
  //qDebug() << mpCompositeModelEditor->interfacesAligned(mFromInterface, mToInterface);
  if (mpConnectionLineAnnotation) {
    mpConnectionLineAnnotation->setAligned(mpCompositeModelEditor->interfacesAligned(mFromInterface, mToInterface));
  }
}

/*!
 * \brief AlignInterfacesCommand::undo
 * Undo the align interfaces command
 */
void AlignInterfacesCommand::undo()
{
  mpCompositeModelEditor->updateSubModelOrientation(mFromInterface.split(".").first(), mOldPos, mOldRot);
  //qDebug() << mpCompositeModelEditor->interfacesAligned(mFromInterface, mToInterface);
  if (mpConnectionLineAnnotation) {
    mpConnectionLineAnnotation->setAligned(mpCompositeModelEditor->interfacesAligned(mFromInterface, mToInterface));
  }
}

RenameCompositeModelCommand::RenameCompositeModelCommand(CompositeModelEditor *pCompositeModelEditor, QString oldCompositeModelName,
                                                         QString newCompositeModelName, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpCompositeModelEditor = pCompositeModelEditor;
  mOldCompositeModelName = oldCompositeModelName;
  mNewCompositeModelName = newCompositeModelName;
  setText(QString("Rename CompositeModel %1").arg(mpCompositeModelEditor->getModelWidget()->getLibraryTreeItem()->getName()));
}

/*!
 * \brief RenameCompositeModelCommand::redoInternal
 * redoInternal the rename CompositeModel command
 */
void RenameCompositeModelCommand::redoInternal()
{
  mpCompositeModelEditor->setCompositeModelName(mNewCompositeModelName);
  mpCompositeModelEditor->getModelWidget()->getLibraryTreeItem()->setName(mNewCompositeModelName);
  mpCompositeModelEditor->getModelWidget()->setWindowTitle(mNewCompositeModelName);
}

/*!
 * \brief RenameCompositeModelCommand::undo
 * Undo the rename CompositeModel command
 */
void RenameCompositeModelCommand::undo()
{
  mpCompositeModelEditor->setCompositeModelName(mOldCompositeModelName);
  mpCompositeModelEditor->getModelWidget()->getLibraryTreeItem()->setName(mOldCompositeModelName);
  mpCompositeModelEditor->getModelWidget()->setWindowTitle(mOldCompositeModelName);
}

/*!
 * \brief AddSystemCommand::AddSystemCommand
 * Adds a system to a model.
 * \param name
 * \param pLibraryTreeItem
 * \param annotation
 * \param pGraphicsView
 * \param openingClass
 * \param type
 * \param pParent
 */
AddSystemCommand::AddSystemCommand(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, GraphicsView *pGraphicsView,
                                   bool openingClass, oms_system_enu_t type, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mName = name;
  mpLibraryTreeItem = pLibraryTreeItem;
  mAnnotation = annotation;
  mpGraphicsView = pGraphicsView;
  mOpeningClass = openingClass;
  mType = type;
  setText(QString("Add system %1").arg(name));
}

/*!
 * \brief AddSystemCommand::redoInternal
 * redoInternal the AddSystemCommand.
 */
void AddSystemCommand::redoInternal()
{
  LibraryTreeItem *pParentLibraryTreeItem = mpGraphicsView->getModelWidget()->getLibraryTreeItem();
  QString nameStructure = QString("%1.%2").arg(pParentLibraryTreeItem->getNameStructure()).arg(mName);
  if (!mOpeningClass) {
    if (!OMSProxy::instance()->addSystem(nameStructure, mType)) {
      setFailed(true);
      return;
    }
  }
  if (!mpLibraryTreeItem) {
    // get the oms_element_t
    oms_element_t *pOMSElement = 0;
    OMSProxy::instance()->getElement(nameStructure, &pOMSElement);
    // Create a LibraryTreeItem for system
    LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
    mpLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(mName, nameStructure, pParentLibraryTreeItem->getFileName(),
                                                                 pParentLibraryTreeItem->isSaved(), pParentLibraryTreeItem, pOMSElement);
    if (!mOpeningClass) {
      mpLibraryTreeItem->handleIconUpdated();
    }
  }
  // add the FMU to view
  ElementInfo *pComponentInfo = new ElementInfo;
  pComponentInfo->setName(mpLibraryTreeItem->getName());
  pComponentInfo->setClassName(mpLibraryTreeItem->getNameStructure());
  mpComponent = new Element(mName, mpLibraryTreeItem, mAnnotation, QPointF(0, 0), pComponentInfo, mpGraphicsView);
  mpGraphicsView->addItem(mpComponent);
  mpGraphicsView->addItem(mpComponent->getOriginItem());
  mpGraphicsView->addComponentToList(mpComponent);
  // select the component when not opening class.
  if (!mOpeningClass) {
    mpGraphicsView->clearSelection(mpComponent);
  }
}

/*!
 * \brief AddSystemCommand::undo
 * Undo the AddSystemCommand.
 */
void AddSystemCommand::undo()
{
  qDebug() << "AddSystemCommand::undo() not implemented.";
}

/*!
 * \brief AddSubModelCommand::AddSubModelCommand
 * Adds a submodel to fmi model.
 * \param name
 * \param path
 * \param pLibraryTreeItem
 * \param openingClass
 * \param pGraphicsView
 * \param pParent
 */
AddSubModelCommand::AddSubModelCommand(QString name, QString path, QString startScript, LibraryTreeItem *pLibraryTreeItem, QString annotation,
                                       bool openingClass, GraphicsView *pGraphicsView, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mName = name;
  mPath = path;
  mStartScript = startScript;
  mpLibraryTreeItem = pLibraryTreeItem;
  mAnnotation = annotation;
  mOpeningClass = openingClass;
  mpGraphicsView = pGraphicsView;
  setText(QString("Add submodel %1").arg(name));
}

/*!
 * \brief AddSubModelCommand::redoInternal
 * redoInternal the AddSubModelCommand.
 */
void AddSubModelCommand::redoInternal()
{
  LibraryTreeItem *pParentLibraryTreeItem = mpGraphicsView->getModelWidget()->getLibraryTreeItem();
  QString nameStructure = QString("%1.%2").arg(pParentLibraryTreeItem->getNameStructure()).arg(mName);
  if (!mOpeningClass) {
    QFileInfo fileInfo(mPath);
    if(mStartScript.isEmpty()) {
      if (!OMSProxy::instance()->addSubModel(nameStructure, fileInfo.absoluteFilePath())) {
        setFailed(true);
        return;
      }
    }
    else {
      if (!OMSProxy::instance()->addExternalTLMModel(nameStructure, mStartScript, fileInfo.absoluteFilePath())) {
        setFailed(true);
        return;
      }
    }
    //mpGraphicsView->addSubModel(mName, mPath);
  }
  if (!mpLibraryTreeItem) {
    // get the oms_element_t
    oms_element_t *pOMSElement = 0;
    OMSProxy::instance()->getElement(nameStructure, &pOMSElement);
    // Create a LibraryTreeItem for system
    LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
    mpLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(mName, nameStructure, pParentLibraryTreeItem->getFileName(),
                                                                 mOpeningClass, pParentLibraryTreeItem, pOMSElement);
    if (!mOpeningClass) {
      mpLibraryTreeItem->handleIconUpdated();
    }
  }
  // add the FMU to view
  ElementInfo *pComponentInfo = new ElementInfo;
  pComponentInfo->setName(mpLibraryTreeItem->getName());
  pComponentInfo->setClassName(mpLibraryTreeItem->getNameStructure());
  mpComponent = new Element(mName, mpLibraryTreeItem, mAnnotation, QPointF(0, 0), pComponentInfo, mpGraphicsView);
  mpGraphicsView->addItem(mpComponent);
  mpGraphicsView->addItem(mpComponent->getOriginItem());
  mpGraphicsView->addComponentToList(mpComponent);
  // select the component when not opening class.
  if (!mOpeningClass) {
    mpGraphicsView->clearSelection(mpComponent);
  }
}

/*!
 * \brief AddSubModelCommand::undo
 * Undo the AddSubModelCommand.
 */
void AddSubModelCommand::undo()
{
  qDebug() << "AddSubModelCommand::undo() not implemented.";

}

/*!
 * \brief DeleteSubModelCommand::DeleteSubModelCommand
 * Used to delete the OMS submodel(s).
 * \param pComponent
 * \param pGraphicsView
 * \param pParent
 */
DeleteSubModelCommand::DeleteSubModelCommand(Element *pComponent, GraphicsView *pGraphicsView, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpComponent = pComponent;
  mpGraphicsView = pGraphicsView;
  mName = mpComponent->getName();
  mPath = mpComponent->getLibraryTreeItem()->getFileName();
  mAnnotation = mpComponent->getTransformationString();
}

/*!
 * \brief DeleteSubModelCommand::redoInternal
 * redoInternal the DeleteSubModelCommand.
 */
void DeleteSubModelCommand::redoInternal()
{
  qDebug() << "DeleteSubModelCommand::redoInternal() not implemented.";
}

/*!
 * \brief DeleteSubModelCommand::undo
 * Undo the DeleteSubModelCommand.
 */
void DeleteSubModelCommand::undo()
{
  qDebug() << "DeleteSubModelCommand::undo() not implemented.";
}

/*!
 * \brief AddConnectorCommand::AddConnectorCommand
 * Adds a connector.
 * \param name
 * \param pLibraryTreeItem
 * \param annotation
 * \param pGraphicsView
 * \param openingClass
 * \param causality
 * \param type
 * \param pParent
 */
AddConnectorCommand::AddConnectorCommand(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, GraphicsView *pGraphicsView,
                                         bool openingClass, oms_causality_enu_t causality, oms_signal_type_enu_t type, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mName = name;
  mpLibraryTreeItem = pLibraryTreeItem;
  mAnnotation = annotation;
  mpGraphicsView = pGraphicsView;
  mpIconGraphicsView = pGraphicsView->getModelWidget()->getIconGraphicsView();
  mpDiagramGraphicsView = pGraphicsView->getModelWidget()->getDiagramGraphicsView();
  mOpeningClass = openingClass;
  mCausality = causality;
  mType = type;
  setText(QString("Add connector %1").arg(name));
}

/*!
 * \brief AddConnectorCommand::redoInternal
 * redoInternal the AddConnectorCommand.
 */
void AddConnectorCommand::redoInternal()
{
  LibraryTreeItem *pParentLibraryTreeItem = mpIconGraphicsView->getModelWidget()->getLibraryTreeItem();
  QString nameStructure = QString("%1.%2").arg(pParentLibraryTreeItem->getNameStructure()).arg(mName);
  if (!mOpeningClass) {
    if (!OMSProxy::instance()->addConnector(nameStructure, mCausality, mType)) {
      setFailed(true);
      return;
    }
  }
  if (!mpLibraryTreeItem) {
    // get oms_connector_t
    oms_connector_t *pOMSConnector = 0;
    OMSProxy::instance()->getConnector(nameStructure, &pOMSConnector);
    // Create a LibraryTreeItem for connector
    LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
    mpLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(mName, nameStructure, pParentLibraryTreeItem->getFileName(),
                                                                 true, pParentLibraryTreeItem, 0, pOMSConnector);
  }
  ElementInfo *pComponentInfo = new ElementInfo;
  pComponentInfo->setName(mpLibraryTreeItem->getName());
  pComponentInfo->setClassName(mpLibraryTreeItem->getNameStructure());
  // add the connector to icon view
  mpIconComponent = new Element(mName, mpLibraryTreeItem, mAnnotation, QPointF(0, 0), pComponentInfo, mpIconGraphicsView);
  mpIconGraphicsView->addItem(mpIconComponent);
  mpIconGraphicsView->addItem(mpIconComponent->getOriginItem());
  mpIconGraphicsView->addComponentToList(mpIconComponent);
  if (!mOpeningClass) {
    mpIconComponent->emitAdded();
  }
  // add the connector to diagram view
  mpDiagramComponent = new Element(mName, mpLibraryTreeItem, mAnnotation, QPointF(0, 0), pComponentInfo, mpDiagramGraphicsView);
  mpDiagramGraphicsView->addItem(mpDiagramComponent);
  mpDiagramGraphicsView->addItem(mpDiagramComponent->getOriginItem());
  mpDiagramGraphicsView->addComponentToList(mpDiagramComponent);
  if (!mOpeningClass) {
    mpDiagramComponent->emitAdded();
  }
  // only select the component of the active Icon/Diagram View
  if (!mOpeningClass) {
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      mpGraphicsView->clearSelection(mpIconComponent);
    } else {
      mpGraphicsView->clearSelection(mpDiagramComponent);
    }
  }
}

/*!
 * \brief AddConnectorCommand::undo
 * Undo the AddConnectorCommand.
 */
void AddConnectorCommand::undo()
{
    qDebug() << "AddConnectorCommand::undo() not implemented.";
}

ElementPropertiesCommand::ElementPropertiesCommand(Element *pComponent, QString name, ElementProperties oldElementProperties,
                                                   ElementProperties newElementProperties, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  Q_UNUSED(name);
  mpComponent = pComponent;
  mOldElementProperties = oldElementProperties;
  mNewElementProperties = newElementProperties;
  setText(QString("Update Element %1 Parameters").arg(mpComponent->getName()));
}

/*!
 * \brief ElementPropertiesCommand::redoInternal
 * redoInternal the ElementPropertiesCommand
 */
void ElementPropertiesCommand::redoInternal()
{
  // Parameters
  int parametersIndex = 0;
  int inputsIndex = 0;
  if (mpComponent->getLibraryTreeItem()->getOMSElement() && mpComponent->getLibraryTreeItem()->getOMSElement()->connectors) {
    oms_connector_t** pInterfaces = mpComponent->getLibraryTreeItem()->getOMSElement()->connectors;
    for (int i = 0 ; pInterfaces[i] ; i++) {
      QString nameStructure = QString("%1.%2").arg(mpComponent->getLibraryTreeItem()->getNameStructure(), QString(pInterfaces[i]->name));
      if (pInterfaces[i]->causality == oms_causality_parameter) {
        QString parameterValue = mNewElementProperties.mParameterValues.at(parametersIndex);
        parametersIndex++;
        if (pInterfaces[i]->type == oms_signal_type_real) {
          OMSProxy::instance()->setReal(nameStructure, parameterValue.toDouble());
        } else if (pInterfaces[i]->type == oms_signal_type_integer) {
          OMSProxy::instance()->setInteger(nameStructure, parameterValue.toInt());
        } else if (pInterfaces[i]->type == oms_signal_type_boolean) {
          OMSProxy::instance()->setBoolean(nameStructure, parameterValue.toInt());
        } else if (pInterfaces[i]->type == oms_signal_type_string) {
          qDebug() << "ElementPropertiesCommand::redoInternal() oms_signal_type_string not implemented yet.";
        } else if (pInterfaces[i]->type == oms_signal_type_enum) {
          qDebug() << "ElementPropertiesCommand::redoInternal() oms_signal_type_enum not implemented yet.";
        } else if (pInterfaces[i]->type == oms_signal_type_bus) {
          qDebug() << "ElementPropertiesCommand::redoInternal() oms_signal_type_bus not implemented yet.";
        } else {
          qDebug() << "ElementPropertiesCommand::redoInternal() unknown oms_signal_type_enu_t.";
        }
      } else if (pInterfaces[i]->causality == oms_causality_input) {
        QString inputValue = mNewElementProperties.mInputValues.at(inputsIndex);
        inputsIndex++;
        if (pInterfaces[i]->type == oms_signal_type_real) {
          OMSProxy::instance()->setReal(nameStructure, inputValue.toDouble());
        } else if (pInterfaces[i]->type == oms_signal_type_integer) {
          OMSProxy::instance()->setInteger(nameStructure, inputValue.toInt());
        } else if (pInterfaces[i]->type == oms_signal_type_boolean) {
          OMSProxy::instance()->setBoolean(nameStructure, inputValue.toInt());
        } else if (pInterfaces[i]->type == oms_signal_type_string) {
          qDebug() << "ElementPropertiesCommand::redoInternal() oms_signal_type_string not implemented yet.";
        } else if (pInterfaces[i]->type == oms_signal_type_enum) {
          qDebug() << "ElementPropertiesCommand::redoInternal() oms_signal_type_enum not implemented yet.";
        } else if (pInterfaces[i]->type == oms_signal_type_bus) {
          qDebug() << "ElementPropertiesCommand::redoInternal() oms_signal_type_bus not implemented yet.";
        } else {
          qDebug() << "ElementPropertiesCommand::redoInternal() unknown oms_signal_type_enu_t.";
        }
      }
    }
  }
}

/*!
 * \brief ElementPropertiesCommand::undo
 * Undo the ElementPropertiesCommand
 */
void ElementPropertiesCommand::undo()
{
  // Parameters
  int parametersIndex = 0;
  int inputsIndex = 0;
  if (mpComponent->getLibraryTreeItem()->getOMSElement() && mpComponent->getLibraryTreeItem()->getOMSElement()->connectors) {
    oms_connector_t** pInterfaces = mpComponent->getLibraryTreeItem()->getOMSElement()->connectors;
    for (int i = 0 ; pInterfaces[i] ; i++) {
      QString nameStructure = QString("%1.%2").arg(mpComponent->getLibraryTreeItem()->getNameStructure(), QString(pInterfaces[i]->name));
      if (pInterfaces[i]->causality == oms_causality_parameter) {
        QString parameterValue = mOldElementProperties.mParameterValues.at(parametersIndex);
        parametersIndex++;
        if (pInterfaces[i]->type == oms_signal_type_real) {
          OMSProxy::instance()->setReal(nameStructure, parameterValue.toDouble());
        } else if (pInterfaces[i]->type == oms_signal_type_integer) {
          OMSProxy::instance()->setInteger(nameStructure, parameterValue.toInt());
        } else if (pInterfaces[i]->type == oms_signal_type_boolean) {
          OMSProxy::instance()->setBoolean(nameStructure, parameterValue.toInt());
        } else if (pInterfaces[i]->type == oms_signal_type_string) {
          qDebug() << "ElementPropertiesCommand::undo() oms_signal_type_string not implemented yet.";
        } else if (pInterfaces[i]->type == oms_signal_type_enum) {
          qDebug() << "ElementPropertiesCommand::undo() oms_signal_type_enum not implemented yet.";
        } else if (pInterfaces[i]->type == oms_signal_type_bus) {
          qDebug() << "ElementPropertiesCommand::undo() oms_signal_type_bus not implemented yet.";
        } else {
          qDebug() << "ElementPropertiesCommand::undo() unknown oms_signal_type_enu_t.";
        }
      } else if (pInterfaces[i]->causality == oms_causality_input) {
        QString inputValue = mOldElementProperties.mInputValues.at(inputsIndex);
        inputsIndex++;
        if (pInterfaces[i]->type == oms_signal_type_real) {
          OMSProxy::instance()->setReal(nameStructure, inputValue.toDouble());
        } else if (pInterfaces[i]->type == oms_signal_type_integer) {
          OMSProxy::instance()->setInteger(nameStructure, inputValue.toInt());
        } else if (pInterfaces[i]->type == oms_signal_type_boolean) {
          OMSProxy::instance()->setBoolean(nameStructure, inputValue.toInt());
        } else if (pInterfaces[i]->type == oms_signal_type_string) {
          qDebug() << "ElementPropertiesCommand::undo() oms_signal_type_string not implemented yet.";
        } else if (pInterfaces[i]->type == oms_signal_type_enum) {
          qDebug() << "ElementPropertiesCommand::undo() oms_signal_type_enum not implemented yet.";
        } else if (pInterfaces[i]->type == oms_signal_type_bus) {
          qDebug() << "ElementPropertiesCommand::undo() oms_signal_type_bus not implemented yet.";
        } else {
          qDebug() << "ElementPropertiesCommand::undo() unknown oms_signal_type_enu_t.";
        }
      }
    }
  }
}

AddIconCommand::AddIconCommand(QString icon, GraphicsView *pGraphicsView, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mIcon = icon;
  mpGraphicsView = pGraphicsView;
  setText(QString("Add Icon"));
}

/*!
 * \brief AddIconCommand::redoInternal
 * redoInternal the AddIconCommand
 */
void AddIconCommand::redoInternal()
{
  // update element ssd_element_geometry_t
  LibraryTreeItem *pElementLibraryTreeItem = mpGraphicsView->getModelWidget()->getLibraryTreeItem();
  if (pElementLibraryTreeItem && pElementLibraryTreeItem->getOMSElement() && pElementLibraryTreeItem->getOMSElement()->geometry) {
    ssd_element_geometry_t elementGeometry = pElementLibraryTreeItem->getOMSElementGeometry();
    QString fileURI = "file:///" + mIcon;
    if (elementGeometry.iconSource) {
      delete[] elementGeometry.iconSource;
    }
    size_t size = fileURI.toStdString().size() + 1;
    elementGeometry.iconSource = new char[size];
    memcpy(elementGeometry.iconSource, fileURI.toStdString().c_str(), size*sizeof(char));
    if (OMSProxy::instance()->setElementGeometry(pElementLibraryTreeItem->getNameStructure(), &elementGeometry)) {
      // clear all shapes first
      foreach (ShapeAnnotation *pShapeAnnotation, mpGraphicsView->getShapesList()) {
        mpGraphicsView->deleteShapeFromList(pShapeAnnotation);
        mpGraphicsView->removeItem(pShapeAnnotation);
        mpGraphicsView->removeItem(pShapeAnnotation->getOriginItem());
      }
      ShapeAnnotation *pShapeAnnotation = mpGraphicsView->getModelWidget()->drawOMSModelElement();
      pElementLibraryTreeItem->handleIconUpdated();
      pElementLibraryTreeItem->emitShapeAdded(pShapeAnnotation, mpGraphicsView);
    }
  }
}

/*!
 * \brief AddIconCommand::undo
 * Undo the AddIconCommand
 */
void AddIconCommand::undo()
{
  // update element ssd_element_geometry_t
  LibraryTreeItem *pElementLibraryTreeItem = mpGraphicsView->getModelWidget()->getLibraryTreeItem();
  if (pElementLibraryTreeItem && pElementLibraryTreeItem->getOMSElement() && pElementLibraryTreeItem->getOMSElement()->geometry) {
    ssd_element_geometry_t elementGeometry = pElementLibraryTreeItem->getOMSElementGeometry();
    if (elementGeometry.iconSource) {
      delete[] elementGeometry.iconSource;
    }
    elementGeometry.iconSource = NULL;
    if (OMSProxy::instance()->setElementGeometry(pElementLibraryTreeItem->getNameStructure(), &elementGeometry)) {
      // clear all shapes first
      foreach (ShapeAnnotation *pShapeAnnotation, mpGraphicsView->getShapesList()) {
        mpGraphicsView->deleteShapeFromList(pShapeAnnotation);
        mpGraphicsView->removeItem(pShapeAnnotation);
        mpGraphicsView->removeItem(pShapeAnnotation->getOriginItem());
      }
      ShapeAnnotation *pShapeAnnotation = mpGraphicsView->getModelWidget()->drawOMSModelElement();
      pElementLibraryTreeItem->handleIconUpdated();
      pElementLibraryTreeItem->emitShapeAdded(pShapeAnnotation, mpGraphicsView);
    }
  }
}

UpdateIconCommand::UpdateIconCommand(QString oldIcon, QString newIcon, ShapeAnnotation *pShapeAnnotation, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mOldIcon = oldIcon;
  mNewIcon = newIcon;
  mpShapeAnnotation = pShapeAnnotation;
  setText(QString("Update Icon"));
}

/*!
 * \brief UpdateIconCommand::redoInternal
 * redoInternal the UpdateIconCommand
 */
void UpdateIconCommand::redoInternal()
{
  // update element ssd_element_geometry_t
  LibraryTreeItem *pElementLibraryTreeItem = mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem();
  if (pElementLibraryTreeItem && pElementLibraryTreeItem->getOMSElement() && pElementLibraryTreeItem->getOMSElement()->geometry) {
    ssd_element_geometry_t elementGeometry = pElementLibraryTreeItem->getOMSElementGeometry();
    QString fileURI = "file:///" + mNewIcon;
    if (elementGeometry.iconSource) {
      delete[] elementGeometry.iconSource;
    }
    size_t size = fileURI.toStdString().size() + 1;
    elementGeometry.iconSource = new char[size];
    memcpy(elementGeometry.iconSource, fileURI.toStdString().c_str(), size*sizeof(char));
    if (OMSProxy::instance()->setElementGeometry(pElementLibraryTreeItem->getNameStructure(), &elementGeometry)) {
      mpShapeAnnotation->setFileName(mNewIcon);
      QPixmap pixmap;
      pixmap.load(mNewIcon);
      mpShapeAnnotation->setImage(pixmap.toImage());
      mpShapeAnnotation->update();
      pElementLibraryTreeItem->handleIconUpdated();
      mpShapeAnnotation->emitChanged();
    }
  }
}

/*!
 * \brief UpdateIconCommand::undo
 * Undo the UpdateIconCommand
 */
void UpdateIconCommand::undo()
{
  // update element ssd_element_geometry_t
  LibraryTreeItem *pElementLibraryTreeItem = mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem();
  if (pElementLibraryTreeItem && pElementLibraryTreeItem->getOMSElement() && pElementLibraryTreeItem->getOMSElement()->geometry) {
    ssd_element_geometry_t elementGeometry = pElementLibraryTreeItem->getOMSElementGeometry();
    QString fileURI = "file:///" + mOldIcon;
    if (elementGeometry.iconSource) {
      delete[] elementGeometry.iconSource;
    }
    size_t size = fileURI.toStdString().size() + 1;
    elementGeometry.iconSource = new char[size];
    memcpy(elementGeometry.iconSource, fileURI.toStdString().c_str(), size*sizeof(char));
    if (OMSProxy::instance()->setElementGeometry(pElementLibraryTreeItem->getNameStructure(), &elementGeometry)) {
      mpShapeAnnotation->setFileName(mOldIcon);
      QPixmap pixmap;
      pixmap.load(mOldIcon);
      mpShapeAnnotation->setImage(pixmap.toImage());
      mpShapeAnnotation->update();
      pElementLibraryTreeItem->handleIconUpdated();
      mpShapeAnnotation->emitChanged();
    }
  }
}

DeleteIconCommand::DeleteIconCommand(QString icon, GraphicsView *pGraphicsView, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mIcon = icon;
  mpGraphicsView = pGraphicsView;
  setText(QString("Delete Icon"));
}

/*!
 * \brief DeleteIconCommand::redoInternal
 * redoInternal the DeleteIconCommand
 */
void DeleteIconCommand::redoInternal()
{
  // update element ssd_element_geometry_t
  LibraryTreeItem *pElementLibraryTreeItem = mpGraphicsView->getModelWidget()->getLibraryTreeItem();
  if (pElementLibraryTreeItem && pElementLibraryTreeItem->getOMSElement() && pElementLibraryTreeItem->getOMSElement()->geometry) {
    ssd_element_geometry_t elementGeometry = pElementLibraryTreeItem->getOMSElementGeometry();
    if (elementGeometry.iconSource) {
      delete[] elementGeometry.iconSource;
    }
    elementGeometry.iconSource = NULL;
    if (OMSProxy::instance()->setElementGeometry(pElementLibraryTreeItem->getNameStructure(), &elementGeometry)) {
      // clear all shapes first
      foreach (ShapeAnnotation *pShapeAnnotation, mpGraphicsView->getShapesList()) {
        mpGraphicsView->deleteShapeFromList(pShapeAnnotation);
        mpGraphicsView->removeItem(pShapeAnnotation);
        mpGraphicsView->removeItem(pShapeAnnotation->getOriginItem());
      }
      ShapeAnnotation *pShapeAnnotation = mpGraphicsView->getModelWidget()->drawOMSModelElement();
      pElementLibraryTreeItem->handleIconUpdated();
      pElementLibraryTreeItem->emitShapeAdded(pShapeAnnotation, mpGraphicsView);
    }
  }
}

/*!
 * \brief DeleteIconCommand::undo
 * Undo the DeleteIconCommand
 */
void DeleteIconCommand::undo()
{
  // update element ssd_element_geometry_t
  LibraryTreeItem *pElementLibraryTreeItem = mpGraphicsView->getModelWidget()->getLibraryTreeItem();
  if (pElementLibraryTreeItem && pElementLibraryTreeItem->getOMSElement() && pElementLibraryTreeItem->getOMSElement()->geometry) {
    ssd_element_geometry_t elementGeometry = pElementLibraryTreeItem->getOMSElementGeometry();
    QString fileURI = "file:///" + mIcon;
    if (elementGeometry.iconSource) {
      delete[] elementGeometry.iconSource;
    }
    size_t size = fileURI.toStdString().size() + 1;
    elementGeometry.iconSource = new char[size];
    memcpy(elementGeometry.iconSource, fileURI.toStdString().c_str(), size*sizeof(char));
    if (OMSProxy::instance()->setElementGeometry(pElementLibraryTreeItem->getNameStructure(), &elementGeometry)) {
      // clear all shapes first
      foreach (ShapeAnnotation *pShapeAnnotation, mpGraphicsView->getShapesList()) {
        mpGraphicsView->deleteShapeFromList(pShapeAnnotation);
        mpGraphicsView->removeItem(pShapeAnnotation);
        mpGraphicsView->removeItem(pShapeAnnotation->getOriginItem());
      }
      ShapeAnnotation *pShapeAnnotation = mpGraphicsView->getModelWidget()->drawOMSModelElement();
      pElementLibraryTreeItem->handleIconUpdated();
      pElementLibraryTreeItem->emitShapeAdded(pShapeAnnotation, mpGraphicsView);
    }
  }
}

OMSRenameCommand::OMSRenameCommand(LibraryTreeItem *pLibraryTreeItem, QString name, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  mOldName = mpLibraryTreeItem->getName();
  mNewName = name;
  setText("OMS rename");
}

/*!
 * \brief OMSRenameCommand::redoInternal
 * redoInternal the OMSRenameCommand
 */
void OMSRenameCommand::redoInternal()
{
  qDebug() << "OMSRenameCommand::redoInternal() not implemented.";
}

/*
 * \brief OMSRenameCommand::undo
 * Undo the OMSRenameCommand
 */
void OMSRenameCommand::undo()
{
  qDebug() << "OMSRenameCommand::undo() not implemented.";
}

/*!
 * \brief AddBusCommand::AddBusCommand
 * Adds a bus.
 * \param name
 * \param pLibraryTreeItem
 * \param annotation
 * \param pGraphicsView
 * \param openingClass
 * \param causality
 * \param type
 * \param pParent
 */
AddBusCommand::AddBusCommand(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, GraphicsView *pGraphicsView,
                             bool openingClass, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mName = name;
  mpLibraryTreeItem = pLibraryTreeItem;
  mAnnotation = annotation;
  mpGraphicsView = pGraphicsView;
  mpIconGraphicsView = pGraphicsView->getModelWidget()->getIconGraphicsView();
  mpDiagramGraphicsView = pGraphicsView->getModelWidget()->getDiagramGraphicsView();
  mOpeningClass = openingClass;
  setText(QString("Add bus %1").arg(name));
}

/*!
 * \brief AddBusCommand::redoInternal
 * redoInternal the AddBusCommand.
 */
void AddBusCommand::redoInternal()
{
  LibraryTreeItem *pParentLibraryTreeItem = mpIconGraphicsView->getModelWidget()->getLibraryTreeItem();
  QString nameStructure = QString("%1.%2").arg(pParentLibraryTreeItem->getNameStructure()).arg(mName);
  if (!mOpeningClass) {
    if (!OMSProxy::instance()->addBus(nameStructure)) {
      setFailed(true);
      return;
    }
  }
  if (!mpLibraryTreeItem) {
    // get oms_busconnector_t
    oms_busconnector_t *pOMSBusConnector = 0;
    OMSProxy::instance()->getBus(nameStructure, &pOMSBusConnector);
    // Create a LibraryTreeItem for bus connector
    LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
    mpLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(mName, nameStructure, pParentLibraryTreeItem->getFileName(),
                                                                 true, pParentLibraryTreeItem, 0, 0, pOMSBusConnector);
  }
  ElementInfo *pComponentInfo = new ElementInfo;
  pComponentInfo->setName(mpLibraryTreeItem->getName());
  pComponentInfo->setClassName(mpLibraryTreeItem->getNameStructure());
  // add the connector to icon view
  mpIconComponent = new Element(mName, mpLibraryTreeItem, mAnnotation, QPointF(0, 0), pComponentInfo, mpIconGraphicsView);
  mpIconGraphicsView->addItem(mpIconComponent);
  mpIconGraphicsView->addItem(mpIconComponent->getOriginItem());
  mpIconGraphicsView->addComponentToList(mpIconComponent);
  // add the connector to diagram view
  mpDiagramComponent = new Element(mName, mpLibraryTreeItem, mAnnotation, QPointF(0, 0), pComponentInfo, mpDiagramGraphicsView);
  mpDiagramGraphicsView->addItem(mpDiagramComponent);
  mpDiagramGraphicsView->addItem(mpDiagramComponent->getOriginItem());
  mpDiagramGraphicsView->addComponentToList(mpDiagramComponent);
  // only select the component of the active Icon/Diagram View
  if (!mOpeningClass) {
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      mpGraphicsView->clearSelection(mpIconComponent);
    } else {
      mpGraphicsView->clearSelection(mpDiagramComponent);
    }
  }
}

/*!
 * \brief AddBusCommand::undo
 * Undo the AddBusCommand.
 */
void AddBusCommand::undo()
{

}

AddConnectorToBusCommand::AddConnectorToBusCommand(QString bus, QString connector, GraphicsView *pGraphicsView, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mBus = bus;
  mConnector = connector;
  mpGraphicsView = pGraphicsView;
  setText(QString("Add connector %1 to bus %2").arg(mConnector, mBus));
}

/*!
 * \brief AddConnectorToBusCommand::redoInternal
 * redoInternal the AddConnectorToBusCommand.
 */
void AddConnectorToBusCommand::redoInternal()
{
  if (!OMSProxy::instance()->addConnectorToBus(mBus.toStdString().c_str(), mConnector.toStdString().c_str())) {
    setFailed(true);
    return;
  }
  mpGraphicsView->getModelWidget()->associateBusWithConnector(StringHandler::getLastWordAfterDot(mBus),
                                                              StringHandler::getLastWordAfterDot(mConnector));
}

/*!
 * \brief AddConnectorToBusCommand::undo
 * Undo the AddConnectorToBusCommand.
 */
void AddConnectorToBusCommand::undo()
{
  OMSProxy::instance()->deleteConnectorFromBus(mBus.toStdString().c_str(), mConnector.toStdString().c_str());
  mpGraphicsView->getModelWidget()->dissociateBusWithConnector(StringHandler::getLastWordAfterDot(mBus),
                                                               StringHandler::getLastWordAfterDot(mConnector));
}

DeleteConnectorFromBusCommand::DeleteConnectorFromBusCommand(QString bus, QString connector, GraphicsView *pGraphicsView, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mBus = bus;
  mConnector = connector;
  mpGraphicsView = pGraphicsView;
  setText(QString("Delete connector %1 from bus %2").arg(mConnector, mBus));
}

/*!
 * \brief DeleteConnectorFromBusCommand::redoInternal
 * redoInternal the DeleteConnectorFromBusCommand.
 */
void DeleteConnectorFromBusCommand::redoInternal()
{
  if (!OMSProxy::instance()->deleteConnectorFromBus(mBus.toStdString().c_str(), mConnector.toStdString().c_str())) {
    setFailed(true);
    return;
  }
  mpGraphicsView->getModelWidget()->dissociateBusWithConnector(StringHandler::getLastWordAfterDot(mBus),
                                                               StringHandler::getLastWordAfterDot(mConnector));
}

/*!
 * \brief DeleteConnectorFromBusCommand::undo
 * Undo the DeleteConnectorFromBusCommand.
 */
void DeleteConnectorFromBusCommand::undo()
{
  OMSProxy::instance()->addConnectorToBus(mBus.toStdString().c_str(), mConnector.toStdString().c_str());
  mpGraphicsView->getModelWidget()->associateBusWithConnector(StringHandler::getLastWordAfterDot(mBus),
                                                              StringHandler::getLastWordAfterDot(mConnector));
}

/*!
 * \brief AddTLMBusCommand::AddTLMBusCommand
 * Adds a tlm bus.
 * \param name
 * \param pLibraryTreeItem
 * \param annotation
 * \param pGraphicsView
 * \param openingClass
 * \param causality
 * \param type
 * \param pParent
 */
AddTLMBusCommand::AddTLMBusCommand(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, GraphicsView *pGraphicsView,
                                   bool openingClass, oms_tlm_domain_t domain, int dimension, oms_tlm_interpolation_t interpolation,
                                   UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mName = name;
  mpLibraryTreeItem = pLibraryTreeItem;
  mAnnotation = annotation;
  mpGraphicsView = pGraphicsView;
  mpIconGraphicsView = pGraphicsView->getModelWidget()->getIconGraphicsView();
  mpDiagramGraphicsView = pGraphicsView->getModelWidget()->getDiagramGraphicsView();
  mOpeningClass = openingClass;
  mDomain = domain;
  mDimension = dimension;
  mInterpolation = interpolation;
  setText(QString("Add tlm bus %1").arg(name));
}

/*!
 * \brief AddTLMBusCommand::redoInternal
 * redoInternal the AddTLMBusCommand.
 */
void AddTLMBusCommand::redoInternal()
{
  LibraryTreeItem *pParentLibraryTreeItem = mpIconGraphicsView->getModelWidget()->getLibraryTreeItem();
  QString nameStructure = QString("%1.%2").arg(pParentLibraryTreeItem->getNameStructure()).arg(mName);
  if (!mOpeningClass) {
    if (!OMSProxy::instance()->addTLMBus(nameStructure, mDomain, mDimension, mInterpolation)) {
      setFailed(true);
      return;
    }
  }
  if (!mpLibraryTreeItem) {
    // get oms_busconnector_t
    oms_tlmbusconnector_t *pOMSTLMBusConnector = 0;
    OMSProxy::instance()->getTLMBus(nameStructure, &pOMSTLMBusConnector);
    // Create a LibraryTreeItem for bus connector
    LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
    mpLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(mName, nameStructure, pParentLibraryTreeItem->getFileName(),
                                                                 true, pParentLibraryTreeItem, 0, 0, 0, pOMSTLMBusConnector);
  }
  ElementInfo *pComponentInfo = new ElementInfo;
  pComponentInfo->setName(mpLibraryTreeItem->getName());
  pComponentInfo->setClassName(mpLibraryTreeItem->getNameStructure());
  // add the connector to icon view
  mpIconComponent = new Element(mName, mpLibraryTreeItem, mAnnotation, QPointF(0, 0), pComponentInfo, mpIconGraphicsView);
  mpIconGraphicsView->addItem(mpIconComponent);
  mpIconGraphicsView->addItem(mpIconComponent->getOriginItem());
  mpIconGraphicsView->addComponentToList(mpIconComponent);
  // add the connector to diagram view
  mpDiagramComponent = new Element(mName, mpLibraryTreeItem, mAnnotation, QPointF(0, 0), pComponentInfo, mpDiagramGraphicsView);
  mpDiagramGraphicsView->addItem(mpDiagramComponent);
  mpDiagramGraphicsView->addItem(mpDiagramComponent->getOriginItem());
  mpDiagramGraphicsView->addComponentToList(mpDiagramComponent);
  // only select the component of the active Icon/Diagram View
  if (!mOpeningClass) {
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      mpGraphicsView->clearSelection(mpIconComponent);
    } else {
      mpGraphicsView->clearSelection(mpDiagramComponent);
    }
  }
}

/*!
 * \brief AddTLMBusCommand::undo
 * Undo the AddTLMBusCommand.
 */
void AddTLMBusCommand::undo()
{

}

AddConnectorToTLMBusCommand::AddConnectorToTLMBusCommand(QString tlmBus, QString connectorName, QString connectorType,
                                                         GraphicsView *pGraphicsView, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mTLMBus = tlmBus;
  mConnectorName = connectorName;
  mConnectorType = connectorType;
  mpGraphicsView = pGraphicsView;
  setText(QString("Add connector %1 to tlm bus %2").arg(mConnectorName, mTLMBus));
}

/*!
 * \brief AddConnectorToTLMBusCommand::redoInternal
 * redoInternal the AddConnectorToTLMBusCommand.
 */
void AddConnectorToTLMBusCommand::redoInternal()
{
  if (!OMSProxy::instance()->addConnectorToTLMBus(mTLMBus.toStdString().c_str(), mConnectorName.toStdString().c_str(),
                                                  mConnectorType.toStdString().c_str())) {
    setFailed(true);
    return;
  }
  mpGraphicsView->getModelWidget()->associateBusWithConnector(StringHandler::getLastWordAfterDot(mTLMBus),
                                                              StringHandler::getLastWordAfterDot(mConnectorName));
}

/*!
 * \brief AddConnectorToTLMBusCommand::undo
 * Undo the AddConnectorToTLMBusCommand.
 */
void AddConnectorToTLMBusCommand::undo()
{
  OMSProxy::instance()->deleteConnectorFromTLMBus(mTLMBus.toStdString().c_str(), mConnectorName.toStdString().c_str());
  mpGraphicsView->getModelWidget()->dissociateBusWithConnector(StringHandler::getLastWordAfterDot(mTLMBus),
                                                               StringHandler::getLastWordAfterDot(mConnectorName));
}

DeleteConnectorFromTLMBusCommand::DeleteConnectorFromTLMBusCommand(QString bus, QString connectorName, QString connectorType,
                                                                   GraphicsView *pGraphicsView, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mTLMBus = bus;
  mConnectorName = connectorName;
  mConnectorType = connectorType;
  mpGraphicsView = pGraphicsView;
  setText(QString("Delete connector %1 from tlm bus %2").arg(mConnectorName, mTLMBus));
}

/*!
 * \brief DeleteConnectorFromTLMBusCommand::redoInternal
 * redoInternal the DeleteConnectorFromTLMBusCommand.
 */
void DeleteConnectorFromTLMBusCommand::redoInternal()
{
  if (!OMSProxy::instance()->deleteConnectorFromTLMBus(mTLMBus.toStdString().c_str(), mConnectorName.toStdString().c_str())) {
    setFailed(true);
    return;
  }
  mpGraphicsView->getModelWidget()->dissociateBusWithConnector(StringHandler::getLastWordAfterDot(mTLMBus),
                                                               StringHandler::getLastWordAfterDot(mConnectorName));
}

/*!
 * \brief DeleteConnectorFromTLMBusCommand::undo
 * Undo the DeleteConnectorFromTLMBusCommand.
 */
void DeleteConnectorFromTLMBusCommand::undo()
{
  OMSProxy::instance()->addConnectorToTLMBus(mTLMBus.toStdString().c_str(), mConnectorName.toStdString().c_str(),
                                             mConnectorType.toStdString().c_str());
  mpGraphicsView->getModelWidget()->associateBusWithConnector(StringHandler::getLastWordAfterDot(mTLMBus),
                                                              StringHandler::getLastWordAfterDot(mConnectorName));
}

UpdateTLMParametersCommand::UpdateTLMParametersCommand(LineAnnotation *pConnectionLineAnnotation,
                                                       const oms_tlm_connection_parameters_t oldTLMParameters,
                                                       const oms_tlm_connection_parameters_t newTLMParameters, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  mOldTLMParameters = oldTLMParameters;
  mNewTLMParameters = newTLMParameters;
  setText(QString("Update TLM connection connect(%1, %2) parameters").arg(mpConnectionLineAnnotation->getStartComponentName(),
                                                                            mpConnectionLineAnnotation->getEndComponentName()));
}

/*!
 * \brief UpdateTLMParametersCommand::redoInternal
 * redoInternal the UpdateTLMParametersCommand.
 */
void UpdateTLMParametersCommand::redoInternal()
{
  if (!OMSProxy::instance()->setTLMConnectionParameters(mpConnectionLineAnnotation->getStartComponentName(),
                                                        mpConnectionLineAnnotation->getEndComponentName(), &mNewTLMParameters)) {
    setFailed(true);
    return;
  }

  mpConnectionLineAnnotation->setDelay(QString::number(mNewTLMParameters.delay));
  mpConnectionLineAnnotation->setAlpha(QString::number(mNewTLMParameters.alpha));
  mpConnectionLineAnnotation->setZf(QString::number(mNewTLMParameters.linearimpedance));
  mpConnectionLineAnnotation->setZfr(QString::number(mNewTLMParameters.angularimpedance));
}

/*!
 * \brief UpdateTLMParametersCommand::undo
 * Undo the UpdateTLMParametersCommand.
 */
void UpdateTLMParametersCommand::undo()
{
  OMSProxy::instance()->setTLMConnectionParameters(mpConnectionLineAnnotation->getStartComponentName(),
                                                   mpConnectionLineAnnotation->getEndComponentName(), &mOldTLMParameters);

  mpConnectionLineAnnotation->setDelay(QString::number(mOldTLMParameters.delay));
  mpConnectionLineAnnotation->setAlpha(QString::number(mOldTLMParameters.alpha));
  mpConnectionLineAnnotation->setZf(QString::number(mOldTLMParameters.linearimpedance));
  mpConnectionLineAnnotation->setZfr(QString::number(mOldTLMParameters.angularimpedance));
}


SystemSimulationInformationCommand::SystemSimulationInformationCommand(TLMSystemSimulationInformation *pTLMSystemSimulationInformation,
                                                                       WCSCSystemSimulationInformation *pWCSCSystemSimulationInformation,
                                                                       LibraryTreeItem *pLibraryTreeItem, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpTLMSystemSimulationInformation = pTLMSystemSimulationInformation;
  mpWCSCSystemSimulationInformation = pWCSCSystemSimulationInformation;
  mpLibraryTreeItem = pLibraryTreeItem;
  setText(QString("System %1 simulation information").arg(mpLibraryTreeItem->getNameStructure()));
}

/*!
 * \brief SystemSimulationInformationCommand::redoInternal
 * redoInternal the SystemSimulationInformationCommand.
 */
void SystemSimulationInformationCommand::redoInternal()
{
  if (mpLibraryTreeItem->isTLMSystem()) {
    if (!OMSProxy::instance()->setTLMSocketData(mpLibraryTreeItem->getNameStructure(), mpTLMSystemSimulationInformation->mIpAddress,
                                                mpTLMSystemSimulationInformation->mManagerPort,
                                                mpTLMSystemSimulationInformation->mMonitorPort)) {
      setFailed(true);
      return;
    }
  } else if (mpLibraryTreeItem->isWCSystem() || mpLibraryTreeItem->isSCSystem()) {
    // set solver
    if (!OMSProxy::instance()->setSolver(mpLibraryTreeItem->getNameStructure(), mpWCSCSystemSimulationInformation->mDescription)) {
      setFailed(true);
      return;
    }
    // set step size
    switch (mpWCSCSystemSimulationInformation->mDescription) {
      case oms_solver_wc_mav:
      case oms_solver_wc_mav2:
      case oms_solver_sc_cvode:
        if (!OMSProxy::instance()->setVariableStepSize(mpLibraryTreeItem->getNameStructure(),
                                                       mpWCSCSystemSimulationInformation->mInitialStepSize,
                                                       mpWCSCSystemSimulationInformation->mMinimumStepSize,
                                                       mpWCSCSystemSimulationInformation->mMaximumStepSize)) {
          setFailed(true);
          return;
        }
        break;
      case oms_solver_wc_ma:
      case oms_solver_sc_explicit_euler:
      default:
        if (!OMSProxy::instance()->setFixedStepSize(mpLibraryTreeItem->getNameStructure(),
                                                    mpWCSCSystemSimulationInformation->mFixedStepSize)) {
          setFailed(true);
          return;
        }
        break;
    }
    // set tolerance
    if (!OMSProxy::instance()->setTolerance(mpLibraryTreeItem->getNameStructure(), mpWCSCSystemSimulationInformation->mAbsoluteTolerance,
                                            mpWCSCSystemSimulationInformation->mRelativeTolerance)) {
      setFailed(true);
      return;
    }
  }
}

/*!
 * \brief SystemSimulationInformationCommand::undo
 * Undo the SystemSimulationInformationCommand.
 */
void SystemSimulationInformationCommand::undo()
{
  qDebug() << "SystemSimulationInformationCommand::undo() not implemented.";
}
