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
                                         ElementInfo *pComponentInfo, bool addObject, bool openingClass, GraphicsView *pGraphicsView, UndoCommand *pParent)
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
    if (mpIconComponent->mTransformation.isValid() && mpIconComponent->mTransformation.getVisible()) {
      mpIconGraphicsView->addItem(mpIconComponent);
      mpIconGraphicsView->addItem(mpIconComponent->getOriginItem());
    }
    mpIconGraphicsView->addElementToList(mpIconComponent);
    mpIconGraphicsView->deleteElementFromOutOfSceneList(mpIconComponent);
    mpIconComponent->emitAdded();
    // hide the component if it is connector and is protected
    mpIconComponent->setVisible(!mpComponentInfo->getProtected());
  }
  if (mpDiagramComponent->mTransformation.isValid() && mpDiagramComponent->mTransformation.getVisible()) {
    mpDiagramGraphicsView->addItem(mpDiagramComponent);
    mpDiagramGraphicsView->addItem(mpDiagramComponent->getOriginItem());
  }
  mpDiagramGraphicsView->addElementToList(mpDiagramComponent);
  mpDiagramGraphicsView->deleteElementFromOutOfSceneList(mpDiagramComponent);
  mpDiagramComponent->emitAdded();
  if (mAddObject) {
    mpDiagramGraphicsView->addElementToClass(mpDiagramComponent);
    UpdateComponentAttributesCommand::updateComponentModifiers(mpDiagramComponent, *mpDiagramComponent->getComponentInfo());
    if (mpDiagramComponent->getComponentInfo()->isArray()) {
      QString modelName = pModelWidget->getLibraryTreeItem()->getNameStructure();
      OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
      const QString arrayIndex = QString("{%1}").arg(mpDiagramComponent->getComponentInfo()->getArrayIndex());
      if (!pOMCProxy->setComponentDimensions(modelName, mpDiagramComponent->getComponentInfo()->getName(), arrayIndex)) {
        QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), Helper::ok);
        pOMCProxy->printMessagesStringInternal();
      }
    }

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
    mpIconGraphicsView->deleteElementFromList(mpIconComponent);
    mpIconGraphicsView->addElementToOutOfSceneList(mpIconComponent);
    mpIconComponent->emitDeleted();
  }
  mpDiagramGraphicsView->removeItem(mpDiagramComponent);
  mpDiagramGraphicsView->removeItem(mpDiagramComponent->getOriginItem());
  mpDiagramGraphicsView->deleteElementFromList(mpDiagramComponent);
  mpDiagramGraphicsView->addElementToOutOfSceneList(mpDiagramComponent);
  mpDiagramComponent->emitDeleted();
  mpDiagramGraphicsView->deleteElementFromClass(mpDiagramComponent);
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
  if (pOMCProxy->setComponentProperties(modelName, pComponent->getComponentInfo()->getName(), isFinal, flow, isProtected, isReplaceAble, variability, isInner, isOuter, causality)) {
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
      pIconComponent = pComponent->getGraphicsView()->getModelWidget()->getIconGraphicsView()->getElementObject(pComponent->getName());
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
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), Helper::ok);
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
          Element *pDiagramComponent = pComponent->getGraphicsView()->getModelWidget()->getDiagramGraphicsView()->getElementObject(pComponent->getName());
          if (pDiagramComponent) {
            pDiagramComponent->componentCommentHasChanged();
          }
        } else {
          Element *pIconComponent = pComponent->getGraphicsView()->getModelWidget()->getIconGraphicsView()->getElementObject(pComponent->getName());
          if (pIconComponent) {
            pIconComponent->componentCommentHasChanged();
          }
        }
      }
    } else {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), Helper::ok);
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
          Element *pDiagramComponent = pComponent->getGraphicsView()->getModelWidget()->getDiagramGraphicsView()->getElementObject(pComponent->getName());
          if (pDiagramComponent) {
            pDiagramComponent->componentNameHasChanged();
          }
        } else {
          Element *pIconComponent = pComponent->getGraphicsView()->getModelWidget()->getIconGraphicsView()->getElementObject(pComponent->getName());
          if (pIconComponent) {
            pIconComponent->componentNameHasChanged();
          }
        }
      }
    } else {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), Helper::ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
  // update the component dimensions
  if (pComponent->getComponentInfo()->getArrayIndex().compare(componentInfo.getArrayIndex()) != 0) {
    const QString arrayIndex = QString("{%1}").arg(componentInfo.getArrayIndex());
    if (pOMCProxy->setComponentDimensions(modelName, pComponent->getComponentInfo()->getName(), arrayIndex)) {
      pComponent->getComponentInfo()->setArrayIndex(arrayIndex);
    } else {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), Helper::ok);
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
    Element *pComponent = pGraphicsView->getElementObject(mpComponent->getName());
    if (pComponent) {
      pGraphicsView->removeItem(pComponent);
      pGraphicsView->removeItem(pComponent->getOriginItem());
      pGraphicsView->deleteElementFromList(pComponent);
      pGraphicsView->addElementToOutOfSceneList(pComponent);
      pComponent->emitDeleted();
    }
  }
  mpGraphicsView->removeItem(mpComponent);
  mpGraphicsView->removeItem(mpComponent->getOriginItem());
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
  if (mpComponent->getLibraryTreeItem() && mpComponent->getLibraryTreeItem()->isConnector() && pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    // Connector type components exists on both icon and diagram views
    GraphicsView *pGraphicsView;
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      pGraphicsView = mpGraphicsView->getModelWidget()->getDiagramGraphicsView();
    } else {
      pGraphicsView = mpGraphicsView->getModelWidget()->getIconGraphicsView();
    }
    Element *pComponent = pGraphicsView->getElementObject(mpComponent->getName());
    if (pComponent) {
      pGraphicsView->addItem(pComponent);
      pGraphicsView->addItem(pComponent->getOriginItem());
      pGraphicsView->addElementToList(pComponent);
      pGraphicsView->deleteElementFromOutOfSceneList(pComponent);
      pComponent->emitAdded();
    }
  }
  mpGraphicsView->addItem(mpComponent);
  mpGraphicsView->addItem(mpComponent->getOriginItem());
  mpGraphicsView->addElementToList(mpComponent);
  mpGraphicsView->deleteElementFromOutOfSceneList(mpComponent);
  mpComponent->emitAdded();
  mpGraphicsView->addElementToClass(mpComponent);
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

  mpConnectionLineAnnotation->drawCornerItems();
  mpConnectionLineAnnotation->setCornerItemsActiveOrPassive();
}

/*!
 * \brief AddConnectionCommand::redoInternal
 * redoInternal the AddConnectionCommand.
 */
void AddConnectionCommand::redoInternal()
{
  mpConnectionLineAnnotation->getGraphicsView()->addConnectionToView(mpConnectionLineAnnotation);
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
  mpConnectionLineAnnotation->getGraphicsView()->removeConnectionFromView(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->getGraphicsView()->deleteConnectionFromClass(mpConnectionLineAnnotation);
}

UpdateConnectionCommand::UpdateConnectionCommand(LineAnnotation *pConnectionLineAnnotation, QString oldAnnotaton, QString newAnnotation, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  mOldAnnotation = oldAnnotaton;
  mNewAnnotation = newAnnotation;
  setText(QString("Update Connection connect(%1, %2)").arg(mpConnectionLineAnnotation->getStartComponentName(), mpConnectionLineAnnotation->getEndComponentName()));
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

UpdateCompositeModelConnection::UpdateCompositeModelConnection(LineAnnotation *pConnectionLineAnnotation, CompositeModelConnection oldCompositeModelConnection,
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
  setText(QString("Delete Connection connect(%1, %2)").arg(mpConnectionLineAnnotation->getStartComponentName(), mpConnectionLineAnnotation->getEndComponentName()));
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
  mpConnectionLineAnnotation->getGraphicsView()->addConnectionToView(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->getGraphicsView()->addConnectionToClass(mpConnectionLineAnnotation, true);
}

AddTransitionCommand::AddTransitionCommand(LineAnnotation *pTransitionLineAnnotation, bool addTransition, UndoCommand *pParent)
  : UndoCommand(pParent)
{
  mpTransitionLineAnnotation = pTransitionLineAnnotation;
  mAddTransition = addTransition;
  setText(QString("Add Transition transition(%1, %2)").arg(mpTransitionLineAnnotation->getStartComponentName(), mpTransitionLineAnnotation->getEndComponentName()));

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
  mOpenedModelWidgetsList.clear();
  mIconSelectedItemsList.clear();
  mDiagramSelectedItemsList.clear();
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
  // save the selected components
  MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidgetSelectedComponents(&mIconSelectedItemsList, &mDiagramSelectedItemsList);
  // save the opened ModelWidgets that belong to this model
  MainWindow::instance()->getModelWidgetContainer()->getOpenedModelWidgetsOfOMSimulatorModel(mModelName, &mOpenedModelWidgetsList);
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
  // Restore the selected components
  MainWindow::instance()->getModelWidgetContainer()->selectCurrentModelWidgetComponents(mIconSelectedItemsList, mDiagramSelectedItemsList);
  // Restore the closed ModelWidgets
  restoreClosedModelWidgets();
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
  // Restore the closed ModelWidgets
  restoreClosedModelWidgets();
  // switch to the ModelWidget where the change happened
  switchToEditedModelWidget();
}

/*!
 * \brief OMSimulatorUndoCommand::restoreClosedModelWidgets
 * Restores the closed ModelWidgets
 */
void OMSimulatorUndoCommand::restoreClosedModelWidgets()
{
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  foreach (QString modelWidgetName, mOpenedModelWidgetsList) {
    LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(modelWidgetName);
    if (pLibraryTreeItem) {
      pLibraryTreeModel->showModelWidget(pLibraryTreeItem);
    }
  }
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
