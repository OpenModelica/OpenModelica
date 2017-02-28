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

AddShapeCommand::AddShapeCommand(ShapeAnnotation *pShapeAnnotation, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpShapeAnnotation = pShapeAnnotation;
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
  mpShapeAnnotation->getGraphicsView()->addShapeToList(mpShapeAnnotation);
  mpShapeAnnotation->getGraphicsView()->addItem(mpShapeAnnotation);
  mpShapeAnnotation->emitAdded();
  mpShapeAnnotation->getGraphicsView()->setAddClassAnnotationNeeded(true);
}

/*!
 * \brief AddShapeCommand::undo
 * Undo the AddShapeCommand.
 */
void AddShapeCommand::undo()
{
  mpShapeAnnotation->getGraphicsView()->deleteShapeFromList(mpShapeAnnotation);
  mpShapeAnnotation->getGraphicsView()->removeItem(mpShapeAnnotation);
  mpShapeAnnotation->emitDeleted();
  mpShapeAnnotation->getGraphicsView()->setAddClassAnnotationNeeded(true);
}

UpdateShapeCommand::UpdateShapeCommand(ShapeAnnotation *pShapeAnnotation, QString oldAnnotaton, QString newAnnotation, QUndoCommand *pParent)
  : QUndoCommand(pParent)
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
  mpShapeAnnotation->emitChanged();
  mpShapeAnnotation->getGraphicsView()->setAddClassAnnotationNeeded(true);
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
  mpShapeAnnotation->emitChanged();
  mpShapeAnnotation->getGraphicsView()->setAddClassAnnotationNeeded(true);
}

DeleteShapeCommand::DeleteShapeCommand(ShapeAnnotation *pShapeAnnotation, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpShapeAnnotation = pShapeAnnotation;
}

/*!
 * \brief DeleteShapeCommand::redo
 * Redo the DeleteShapeCommand.
 */
void DeleteShapeCommand::redo()
{
  mpShapeAnnotation->getGraphicsView()->deleteShapeFromList(mpShapeAnnotation);
  mpShapeAnnotation->getGraphicsView()->removeItem(mpShapeAnnotation);
  mpShapeAnnotation->emitDeleted();
  mpShapeAnnotation->getGraphicsView()->setAddClassAnnotationNeeded(true);
}

/*!
 * \brief DeleteShapeCommand::undo
 * Undo the DeleteShapeCommand.
 */
void DeleteShapeCommand::undo()
{
  mpShapeAnnotation->getGraphicsView()->addShapeToList(mpShapeAnnotation);
  mpShapeAnnotation->getGraphicsView()->addItem(mpShapeAnnotation);
  mpShapeAnnotation->emitAdded();
  mpShapeAnnotation->getGraphicsView()->setAddClassAnnotationNeeded(true);
}

AddComponentCommand::AddComponentCommand(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, QPointF position,
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
    mpIconComponent = new Component(name, pLibraryTreeItem, annotation, position, pComponentInfo, mpIconGraphicsView);
    mpDiagramComponent = new Component(name, pLibraryTreeItem, annotation, position, pComponentInfo, mpDiagramGraphicsView);
  } else {
    mpDiagramComponent = new Component(name, pLibraryTreeItem, annotation, position, pComponentInfo, mpDiagramGraphicsView);
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
    // first create the component for Icon View
    mpIconGraphicsView->addItem(mpIconComponent);
    mpIconGraphicsView->addItem(mpIconComponent->getOriginItem());
    mpIconGraphicsView->addComponentToList(mpIconComponent);
    mpIconComponent->emitAdded();
    // hide the component if it is connector and is protected
    mpIconComponent->setVisible(!mpComponentInfo->getProtected());
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
    // first create the component for Icon View
    mpIconGraphicsView->removeItem(mpIconComponent);
    mpIconGraphicsView->removeItem(mpIconComponent->getOriginItem());
    mpIconGraphicsView->deleteComponentFromList(mpIconComponent);
    mpIconComponent->emitDeleted();
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
                                                                   const ComponentInfo &newComponentInfo, bool duplicate, QUndoCommand *pParent)
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

  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
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
    if (mpComponent->getGraphicsView()->getViewType() == StringHandler::Icon) {
      if (mpComponent->getComponentInfo()->getProtected()) {
        mpComponent->setVisible(false);
        mpComponent->emitDeleted();
      } else {
        mpComponent->setVisible(true);
        mpComponent->emitAdded();
      }
    } else {
      Component *pComponent = 0;
      pComponent = mpComponent->getGraphicsView()->getModelWidget()->getIconGraphicsView()->getComponentObject(mpComponent->getName());
      if (pComponent) {
        if (pComponent->getComponentInfo()->getProtected()) {
          pComponent->setVisible(false);
          pComponent->emitDeleted();
        } else {
          pComponent->setVisible(true);
          pComponent->emitAdded();
        }
      }
    }
  } else {
    QMessageBox::critical(MainWindow::instance(),
                          QString(Helper::applicationName).append(" - ").append(Helper::error), pOMCProxy->getResult(), Helper::ok);
    pOMCProxy->printMessagesStringInternal();
  }
  // update the component comment only if its changed.
  if (mpComponent->getComponentInfo()->getComment().compare(mNewComponentInfo.getComment()) != 0) {
    QString comment = StringHandler::escapeString(mNewComponentInfo.getComment());
    if (pOMCProxy->setComponentComment(modelName, mpComponent->getComponentInfo()->getName(), comment)) {
      mpComponent->getComponentInfo()->setComment(comment);
      mpComponent->componentCommentHasChanged();
      if (mpComponent->getLibraryTreeItem()->isConnector()) {
        if (mpComponent->getGraphicsView()->getViewType() == StringHandler::Icon) {
          Component *pComponent = 0;
          pComponent = mpComponent->getGraphicsView()->getModelWidget()->getDiagramGraphicsView()->getComponentObject(mpComponent->getName());
          if (pComponent) {
            pComponent->componentCommentHasChanged();
          }
        } else {
          Component *pComponent = 0;
          pComponent = mpComponent->getGraphicsView()->getModelWidget()->getIconGraphicsView()->getComponentObject(mpComponent->getName());
          if (pComponent) {
            pComponent->componentCommentHasChanged();
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
  if (mpComponent->getComponentInfo()->getName().compare(mNewComponentInfo.getName()) != 0) {
    // if renameComponentInClass command is successful update the component with new name
    if (pOMCProxy->renameComponentInClass(modelName, mpComponent->getComponentInfo()->getName(), mNewComponentInfo.getName())) {
      mpComponent->renameComponentInConnections(mNewComponentInfo.getName());
      mpComponent->getComponentInfo()->setName(mNewComponentInfo.getName());
      mpComponent->componentNameHasChanged();
      if (mpComponent->getLibraryTreeItem()->isConnector()) {
        if (mpComponent->getGraphicsView()->getViewType() == StringHandler::Icon) {
          Component *pComponent = 0;
          pComponent = mpComponent->getGraphicsView()->getModelWidget()->getDiagramGraphicsView()->getComponentObject(mpComponent->getName());
          if (pComponent) {
            pComponent->componentNameHasChanged();
          }
        } else {
          Component *pComponent = 0;
          pComponent = mpComponent->getGraphicsView()->getModelWidget()->getIconGraphicsView()->getComponentObject(mpComponent->getName());
          if (pComponent) {
            pComponent->componentNameHasChanged();
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
  if (mpComponent->getComponentInfo()->getArrayIndex().compare(mNewComponentInfo.getArrayIndex()) != 0) {
    if (pOMCProxy->setComponentDimensions(modelName, mpComponent->getComponentInfo()->getName(), mNewComponentInfo.getArrayIndex())) {
      mpComponent->getComponentInfo()->setArrayIndex(mNewComponentInfo.getArrayIndex());
    } else {
      QMessageBox::critical(MainWindow::instance(),
                            QString(Helper::applicationName).append(" - ").append(Helper::error), pOMCProxy->getResult(), Helper::ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
  // apply Component modifiers if duplicate case
  if (mDuplicate) {
    bool modifierValueChanged = false;
    QMap<QString, QString> modifiers = mNewComponentInfo.getModifiersMapWithoutFetching();
    QMap<QString, QString>::iterator modifiersIterator;
    for (modifiersIterator = modifiers.begin(); modifiersIterator != modifiers.end(); ++modifiersIterator) {
      QString modifierName = QString(mpComponent->getName()).append(".").append(modifiersIterator.key());
      QString modifierValue = modifiersIterator.value();
      if (pOMCProxy->setComponentModifierValue(modelName, modifierName, modifierValue)) {
        modifierValueChanged = true;
      }
    }
    if (modifierValueChanged) {
      mpComponent->componentParameterHasChanged();
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

  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
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
    if (mpComponent->getGraphicsView()->getViewType() == StringHandler::Icon) {
      if (mpComponent->getComponentInfo()->getProtected()) {
        mpComponent->setVisible(false);
        mpComponent->emitDeleted();
      } else {
        mpComponent->setVisible(true);
        mpComponent->emitAdded();
      }
    } else {
      Component *pComponent = 0;
      pComponent = mpComponent->getGraphicsView()->getModelWidget()->getIconGraphicsView()->getComponentObject(mpComponent->getName());
      if (pComponent) {
        if (pComponent->getComponentInfo()->getProtected()) {
          pComponent->setVisible(false);
          pComponent->emitDeleted();
        } else {
          pComponent->setVisible(true);
          pComponent->emitAdded();
        }
      }
    }
  } else {
    QMessageBox::critical(MainWindow::instance(),
                          QString(Helper::applicationName).append(" - ").append(Helper::error), pOMCProxy->getResult(), Helper::ok);
    pOMCProxy->printMessagesStringInternal();
  }
  // update the component comment only if its changed.
  if (mpComponent->getComponentInfo()->getComment().compare(mOldComponentInfo.getComment()) != 0) {
    QString comment = StringHandler::escapeString(mOldComponentInfo.getComment());
    if (pOMCProxy->setComponentComment(modelName, mpComponent->getComponentInfo()->getName(), comment)) {
      mpComponent->getComponentInfo()->setComment(comment);
      mpComponent->componentCommentHasChanged();
      if (mpComponent->getLibraryTreeItem()->isConnector()) {
        if (mpComponent->getGraphicsView()->getViewType() == StringHandler::Icon) {
          Component *pComponent = 0;
          pComponent = mpComponent->getGraphicsView()->getModelWidget()->getDiagramGraphicsView()->getComponentObject(mpComponent->getName());
          if (pComponent) {
            pComponent->componentCommentHasChanged();
          }
        } else {
          Component *pComponent = 0;
          pComponent = mpComponent->getGraphicsView()->getModelWidget()->getIconGraphicsView()->getComponentObject(mpComponent->getName());
          if (pComponent) {
            pComponent->componentCommentHasChanged();
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
  if (mpComponent->getComponentInfo()->getName().compare(mOldComponentInfo.getName()) != 0) {
    // if renameComponentInClass command is successful update the component with new name
    if (pOMCProxy->renameComponentInClass(modelName, mpComponent->getComponentInfo()->getName(), mOldComponentInfo.getName())) {
      mpComponent->renameComponentInConnections(mOldComponentInfo.getName());
      mpComponent->getComponentInfo()->setName(mOldComponentInfo.getName());
      mpComponent->componentNameHasChanged();
      if (mpComponent->getLibraryTreeItem()->isConnector()) {
        if (mpComponent->getGraphicsView()->getViewType() == StringHandler::Icon) {
          Component *pComponent = 0;
          pComponent = mpComponent->getGraphicsView()->getModelWidget()->getDiagramGraphicsView()->getComponentObject(mpComponent->getName());
          if (pComponent) {
            pComponent->componentNameHasChanged();
          }
        } else {
          Component *pComponent = 0;
          pComponent = mpComponent->getGraphicsView()->getModelWidget()->getIconGraphicsView()->getComponentObject(mpComponent->getName());
          if (pComponent) {
            pComponent->componentNameHasChanged();
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
  if (mpComponent->getComponentInfo()->getArrayIndex().compare(mOldComponentInfo.getArrayIndex()) != 0) {
    if (pOMCProxy->setComponentDimensions(modelName, mpComponent->getComponentInfo()->getName(), mOldComponentInfo.getArrayIndex())) {
      mpComponent->getComponentInfo()->setArrayIndex(mOldComponentInfo.getArrayIndex());
    } else {
      QMessageBox::critical(MainWindow::instance(),
                            QString(Helper::applicationName).append(" - ").append(Helper::error), pOMCProxy->getResult(), Helper::ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
}

UpdateComponentParametersCommand::UpdateComponentParametersCommand(Component *pComponent, QMap<QString, QString> oldComponentModifiersMap,
                                                                   QMap<QString, QString> oldComponentExtendsModifiersMap,
                                                                   QMap<QString, QString> newComponentModifiersMap,
                                                                   QMap<QString, QString> newComponentExtendsModifiersMap,
                                                                   QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpComponent = pComponent;
  mOldComponentModifiersMap = oldComponentModifiersMap;
  mOldComponentExtendsModifiersMap = oldComponentExtendsModifiersMap;
  mNewComponentModifiersMap = newComponentModifiersMap;
  mNewComponentExtendsModifiersMap = newComponentExtendsModifiersMap;
  setText(QString("Update Component %1 Parameters").arg(mpComponent->getName()));
}

/*!
 * \brief UpdateComponentParametersCommand::redo
 * Redo the UpdateComponentParametersCommand.
 */
void UpdateComponentParametersCommand::redo()
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
    mpComponent->getComponentInfo()->fetchModifiers(pOMCProxy, className, mpComponent);
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
    mpComponent->getComponentInfo()->fetchModifiers(pOMCProxy, className, mpComponent);
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

DeleteComponentCommand::DeleteComponentCommand(Component *pComponent, GraphicsView *pGraphicsView, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpComponent = pComponent;
  mpIconComponent = 0;
  mpDiagramComponent = 0;
  mpIconGraphicsView = pGraphicsView->getModelWidget()->getIconGraphicsView();
  mpDiagramGraphicsView = pGraphicsView->getModelWidget()->getDiagramGraphicsView();
  mpGraphicsView = pGraphicsView;

  //Save sub-model parameters for composite models
  if(pGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    CompositeModelEditor *pEditor = qobject_cast<CompositeModelEditor*>(pGraphicsView->getModelWidget()->getEditor());
    mParameterNames = pEditor->getParameterNames(pComponent->getName());  //Assume submodel; otherwise returned list is empty
    foreach(QString parName, mParameterNames) {
      mParameterValues.append(pEditor->getParameterValue(pComponent->getName(), parName));
    }
  }
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

  //Restore sub-model parameters for composite models
  if(pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    CompositeModelEditor *pEditor = qobject_cast<CompositeModelEditor*>(pModelWidget->getEditor());
    for(int i=0; i<mParameterNames.size(); ++i) {
      pEditor->setParameterValue(mpComponent->getName(),mParameterNames[i],mParameterValues[i]);
    }
  }
}

AddConnectionCommand::AddConnectionCommand(LineAnnotation *pConnectionLineAnnotation, bool addConnection, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  mAddConnection = addConnection;
  setText(QString("Add Connection connect(%1, %2)").arg(mpConnectionLineAnnotation->getStartComponentName(),
                                                        mpConnectionLineAnnotation->getEndComponentName()));

  mpConnectionLineAnnotation->setToolTip(QString("<b>connect</b>(%1, %2)").arg(mpConnectionLineAnnotation->getStartComponentName())
                                         .arg(mpConnectionLineAnnotation->getEndComponentName()));
  mpConnectionLineAnnotation->drawCornerItems();
  mpConnectionLineAnnotation->setCornerItemsActiveOrPassive();
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
  if (pEndComponent->getRootParentComponent()) {
    pEndComponent->getRootParentComponent()->addConnectionDetails(mpConnectionLineAnnotation);
  } else {
    pEndComponent->addConnectionDetails(mpConnectionLineAnnotation);
  }
  mpConnectionLineAnnotation->getGraphicsView()->addConnectionToList(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->getGraphicsView()->addItem(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->emitAdded();
  if (mAddConnection) {
    mpConnectionLineAnnotation->getGraphicsView()->addConnectionToClass(mpConnectionLineAnnotation);
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
  if (pEndComponent->getRootParentComponent()) {
    pEndComponent->getRootParentComponent()->removeConnectionDetails(mpConnectionLineAnnotation);
  } else {
    pEndComponent->removeConnectionDetails(mpConnectionLineAnnotation);
  }
  mpConnectionLineAnnotation->getGraphicsView()->deleteConnectionFromList(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->getGraphicsView()->removeItem(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->emitDeleted();
  mpConnectionLineAnnotation->getGraphicsView()->deleteConnectionFromClass(mpConnectionLineAnnotation);
}

UpdateConnectionCommand::UpdateConnectionCommand(LineAnnotation *pConnectionLineAnnotation, QString oldAnnotaton, QString newAnnotation,
                                                 QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  mOldAnnotation = oldAnnotaton;
  mNewAnnotation = newAnnotation;
  setText(QString("Update Connection connect(%1, %2)").arg(mpConnectionLineAnnotation->getStartComponentName(),
                                                           mpConnectionLineAnnotation->getEndComponentName()));
}

/*!
 * \brief UpdateConnectionCommand::redo
 * Redo the UpdateConnectionCommand.
 */
void UpdateConnectionCommand::redo()
{
  mpConnectionLineAnnotation->parseShapeAnnotation(mNewAnnotation);
  mpConnectionLineAnnotation->initializeTransformation();
  mpConnectionLineAnnotation->removeCornerItems();
  mpConnectionLineAnnotation->drawCornerItems();
  mpConnectionLineAnnotation->adjustGeometries();
  mpConnectionLineAnnotation->setCornerItemsActiveOrPassive();
  mpConnectionLineAnnotation->update();
  mpConnectionLineAnnotation->emitChanged();
  mpConnectionLineAnnotation->updateConnectionAnnotation();
}

/*!
 * \brief UpdateConnectionCommand::undo
 * Undo the UpdateConnectionCommand.
 */
void UpdateConnectionCommand::undo()
{
  mpConnectionLineAnnotation->parseShapeAnnotation(mOldAnnotation);
  mpConnectionLineAnnotation->initializeTransformation();
  mpConnectionLineAnnotation->removeCornerItems();
  mpConnectionLineAnnotation->drawCornerItems();
  mpConnectionLineAnnotation->adjustGeometries();
  mpConnectionLineAnnotation->setCornerItemsActiveOrPassive();
  mpConnectionLineAnnotation->update();
  mpConnectionLineAnnotation->emitChanged();
  mpConnectionLineAnnotation->updateConnectionAnnotation();
}

UpdateCompositeModelConnection::UpdateCompositeModelConnection(LineAnnotation *pConnectionLineAnnotation,
                                                               CompositeModelConnection oldCompositeModelConnection,
                                                               CompositeModelConnection newCompositeModelConnection, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  mOldCompositeModelConnection = oldCompositeModelConnection;
  mNewCompositeModelConnection = newCompositeModelConnection;
  setText(QString("Update CompositeModel Connection connect(%1, %2)").arg(mpConnectionLineAnnotation->getStartComponentName(),
                                                                          mpConnectionLineAnnotation->getEndComponentName()));
}

/*!
 * \brief UpdateCompositeModelConnection::redo
 * Redo the UpdateCompositeModelConnection.
 */
void UpdateCompositeModelConnection::redo()
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

DeleteConnectionCommand::DeleteConnectionCommand(LineAnnotation *pConnectionLineAnnotation, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
}

/*!
 * \brief DeleteConnectionCommand::redo
 * Redo the DeleteConnectionCommand.
 */
void DeleteConnectionCommand::redo()
{
  // Remove the start component connection details.
  Component *pStartComponent = mpConnectionLineAnnotation->getStartComponent();
  if (pStartComponent && pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->removeConnectionDetails(mpConnectionLineAnnotation);
  } else if (pStartComponent) {
    pStartComponent->removeConnectionDetails(mpConnectionLineAnnotation);
  }
  // Remove the end component connection details.
  Component *pEndComponent = mpConnectionLineAnnotation->getEndComponent();
  if (pEndComponent && pEndComponent->getRootParentComponent()) {
    pEndComponent->getRootParentComponent()->removeConnectionDetails(mpConnectionLineAnnotation);
  } else if (pEndComponent) {
    pEndComponent->removeConnectionDetails(mpConnectionLineAnnotation);
  }
  mpConnectionLineAnnotation->getGraphicsView()->deleteConnectionFromList(mpConnectionLineAnnotation);
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
  Component *pStartComponent = mpConnectionLineAnnotation->getStartComponent();
  if (pStartComponent && pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->addConnectionDetails(mpConnectionLineAnnotation);
  } else if (pStartComponent) {
    pStartComponent->addConnectionDetails(mpConnectionLineAnnotation);
  }
  // Add the end component connection details.
  Component *pEndComponent = mpConnectionLineAnnotation->getEndComponent();
  if (pEndComponent && pEndComponent->getRootParentComponent()) {
    pEndComponent->getRootParentComponent()->addConnectionDetails(mpConnectionLineAnnotation);
  } else if (pEndComponent) {
    pEndComponent->addConnectionDetails(mpConnectionLineAnnotation);
  }
  mpConnectionLineAnnotation->getGraphicsView()->addConnectionToList(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->getGraphicsView()->addItem(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->emitAdded();
  mpConnectionLineAnnotation->getGraphicsView()->addConnectionToClass(mpConnectionLineAnnotation);
}

UpdateCoOrdinateSystemCommand::UpdateCoOrdinateSystemCommand(GraphicsView *pGraphicsView, CoOrdinateSystem oldCoOrdinateSystem,
                                                             CoOrdinateSystem newCoOrdinateSystem, bool copyProperties, QString oldVersion,
                                                             QString newVersion, QString oldUsesAnnotationString,
                                                             QString newUsesAnnotationString, QString oldOMCFlags, QString newOMCFlags,
                                                             QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpGraphicsView = pGraphicsView;
  mOldCoOrdinateSystem = oldCoOrdinateSystem;
  mNewCoOrdinateSystem = newCoOrdinateSystem;
  mCopyProperties = copyProperties;
  mOldVersion = oldVersion;
  mNewVersion = newVersion;
  mOldUsesAnnotationString = oldUsesAnnotationString;
  mNewUsesAnnotationString = newUsesAnnotationString;
  mOldOMCFlags = oldOMCFlags;
  mNewOMCFlags = newOMCFlags;
  setText(QString("Update %1 CoOrdinate System").arg(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure()));
}

/*!
 * \brief UpdateClassCoOrdinateSystemCommand::redo
 * Redo the UpdateClassCoOrdinateSystemCommand.
 */
void UpdateCoOrdinateSystemCommand::redo()
{
  mpGraphicsView->mCoOrdinateSystem = mNewCoOrdinateSystem;
  qreal left = mNewCoOrdinateSystem.getExtent().at(0).x();
  qreal bottom = mNewCoOrdinateSystem.getExtent().at(0).y();
  qreal right = mNewCoOrdinateSystem.getExtent().at(1).x();
  qreal top = mNewCoOrdinateSystem.getExtent().at(1).y();
  mpGraphicsView->setExtentRectangle(left, bottom, right, top);
  mpGraphicsView->addClassAnnotation();
  mpGraphicsView->fitInViewInternal();
  mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitCoOrdinateSystemUpdated(mpGraphicsView);
  // if copy properties is true
  if (mCopyProperties) {
    GraphicsView *pGraphicsView;
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      pGraphicsView = mpGraphicsView->getModelWidget()->getDiagramGraphicsView();
    } else {
      pGraphicsView = mpGraphicsView->getModelWidget()->getIconGraphicsView();
    }
    pGraphicsView->mCoOrdinateSystem = mNewCoOrdinateSystem;
    pGraphicsView->setExtentRectangle(left, bottom, right, top);
    pGraphicsView->addClassAnnotation();
    pGraphicsView->fitInViewInternal();
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
  // omc flags
  QString flagsAnnotation = QString("annotate=__OpenModelica_commandLineOptions(\"%1\")").arg(mNewOMCFlags);
  pOMCProxy->addClassAnnotation(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), flagsAnnotation);
}

/*!
 * \brief UpdateClassCoOrdinateSystemCommand::undo
 * Undo the UpdateClassCoOrdinateSystemCommand.
 */
void UpdateCoOrdinateSystemCommand::undo()
{
  mpGraphicsView->mCoOrdinateSystem = mOldCoOrdinateSystem;
  qreal left = mOldCoOrdinateSystem.getExtent().at(0).x();
  qreal bottom = mOldCoOrdinateSystem.getExtent().at(0).y();
  qreal right = mOldCoOrdinateSystem.getExtent().at(1).x();
  qreal top = mOldCoOrdinateSystem.getExtent().at(1).y();

  if (!mpGraphicsView->mCoOrdinateSystem.isValid()) {
    mpGraphicsView->getModelWidget()->drawBaseCoOrdinateSystem(mpGraphicsView->getModelWidget(), mpGraphicsView);
  } else {
    mpGraphicsView->setExtentRectangle(left, bottom, right, top);
  }
  mpGraphicsView->addClassAnnotation();
  mpGraphicsView->fitInViewInternal();
  mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitCoOrdinateSystemUpdated(mpGraphicsView);
  // if copy properties is true
  if (mCopyProperties) {
    GraphicsView *pGraphicsView;
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      pGraphicsView = mpGraphicsView->getModelWidget()->getDiagramGraphicsView();
    } else {
      pGraphicsView = mpGraphicsView->getModelWidget()->getIconGraphicsView();
    }
    pGraphicsView->mCoOrdinateSystem = mOldCoOrdinateSystem;
    if (!pGraphicsView->mCoOrdinateSystem.isValid()) {
      pGraphicsView->getModelWidget()->drawBaseCoOrdinateSystem(pGraphicsView->getModelWidget(), pGraphicsView);
    } else {
      pGraphicsView->setExtentRectangle(left, bottom, right, top);
    }
    pGraphicsView->addClassAnnotation();
    pGraphicsView->fitInViewInternal();
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
  // omc flags
  QString flagsAnnotation = QString("annotate=__OpenModelica_commandLineOptions(\"%1\")").arg(mOldOMCFlags);
  pOMCProxy->addClassAnnotation(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), flagsAnnotation);
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
                                                           QString newAnnotaiton, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  mOldAnnotation = oldAnnotation;
  mNewAnnotation = newAnnotaiton;
  setText(QString("Update %1 annotation").arg(mpLibraryTreeItem->getNameStructure()));
}

/*!
 * \brief UpdateClassAnnotationCommand::redo
 * Redo the UpdateClassAnnotationCommand.
 */
void UpdateClassAnnotationCommand::redo()
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
                                                                                         QString newSimulationFlags, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  mOldSimulationFlags = oldSimulationFlags;
  mNewSimulationFlags = newSimulationFlags;
  setText(QString("Update %1 simulation flags annotation").arg(mpLibraryTreeItem->getNameStructure()));
}

/*!
 * \brief UpdateClassSimulationFlagsAnnotationCommand::redo
 * Redo the UpdateClassSimulationFlagsAnnotationCommand.
 */
void UpdateClassSimulationFlagsAnnotationCommand::redo()
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

UpdateSubModelAttributesCommand::UpdateSubModelAttributesCommand(Component *pComponent, const ComponentInfo &oldComponentInfo,
                                                                 const ComponentInfo &newComponentInfo,
                                                                 QStringList &parameterNames, QStringList &oldParameterValues,
                                                                 QStringList &newParameterValues, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpComponent = pComponent;
  mOldComponentInfo.updateComponentInfo(&oldComponentInfo);
  mNewComponentInfo.updateComponentInfo(&newComponentInfo);
  setText(QString("Update SubModel %1 Attributes").arg(mpComponent->getName()));

  //Save sub-model parameters for composite models
  mParameterNames = parameterNames;
  mOldParameterValues = oldParameterValues;
  mNewParameterValues = newParameterValues;
}

/*!
 * \brief UpdateSubModelAttributesCommand::redo
 * Redo the UpdateSubModelAttributesCommand.
 */
void UpdateSubModelAttributesCommand::redo()
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
                                                             QString newStopTime, QUndoCommand *pParent )
  : QUndoCommand(pParent)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  mOldStartTime = oldStartTime;
  mNewStartTime = newStartTime;
  mOldStopTime = oldStopTime;
  mNewStopTime = newStopTime;
  setText(QString("Update %1 simulation parameter").arg(mpLibraryTreeItem->getNameStructure()));
}

/*!
 * \brief UpdateSimulationParamsCommand::redo
 * Redo the UpdateSimulationParamsCommand.
 */
void UpdateSimulationParamsCommand::redo()
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
                                               LineAnnotation *pConnectionLineAnnotation, QUndoCommand *pParent)
  : QUndoCommand(pParent)
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
 * \brief AlignInterfacesCommand::redo
 * Redo the align interfaces command
 */
void AlignInterfacesCommand::redo()
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
                                                         QString newCompositeModelName, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpCompositeModelEditor = pCompositeModelEditor;
  mOldCompositeModelName = oldCompositeModelName;
  mNewCompositeModelName = newCompositeModelName;
  setText(QString("Rename CompositeModel %1").arg(mpCompositeModelEditor->getModelWidget()->getLibraryTreeItem()->getName()));
}

/*!
 * \brief RenameCompositeModelCommand::redo
 * Redo the rename CompositeModel command
 */
void RenameCompositeModelCommand::redo()
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
