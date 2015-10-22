/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#include <QNetworkReply>

#include "ModelWidgetContainer.h"
#include "LibraryTreeWidget.h"
#include "MainWindow.h"
#include "ShapePropertiesDialog.h"
#include "ComponentProperties.h"
#include "Commands.h"

CoOrdinateSystem::CoOrdinateSystem()
{
  QList<QPointF> extents;
  extents << QPointF(-100, -100) << QPointF(100, 100);
  setExtent(extents);
  setPreserveAspectRatio(true);
  setInitialScale(0.1);
  setGrid(QPointF(2, 2));
}

qreal CoOrdinateSystem::getHorizontalGridStep()
{
  if (mGrid.x() < 1)
    return 2;
  return mGrid.x();
}

qreal CoOrdinateSystem::getVerticalGridStep()
{
  if (mGrid.y() < 1)
    return 2;
  return mGrid.y();
}

//! @class GraphicsScene
//! @brief The GraphicsScene class is a container for graphicsl components in a simulationmodel.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
GraphicsScene::GraphicsScene(StringHandler::ViewType viewType, ModelWidget *pModelWidget)
  : QGraphicsScene(pModelWidget), mViewType(viewType)
{
  mpModelWidget = pModelWidget;
}

//! @class GraphicsView
//! @brief The GraphicsView class is a class which display the content of a scene of components.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
GraphicsView::GraphicsView(StringHandler::ViewType viewType, ModelWidget *parent)
  : QGraphicsView(parent), mViewType(viewType), mSkipBackground(false)
{
  /* Ticket #3275
   * Set the scroll bars policy to always on to avoid unnecessary resize events.
   */
  setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
  setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
  setFrameShape(QFrame::StyledPanel);
  setDragMode(QGraphicsView::RubberBandDrag);
  setAcceptDrops(true);
  setViewportUpdateMode(QGraphicsView::FullViewportUpdate);
  setMouseTracking(true);
  mpModelWidget = parent;
  // set the coOrdinate System
  mpCoOrdinateSystem = new CoOrdinateSystem;
  GraphicalViewsPage *pGraphicalViewsPage;
  pGraphicalViewsPage = mpModelWidget->getModelWidgetContainer()->getMainWindow()->getOptionsDialog()->getGraphicalViewsPage();
  QList<QPointF> extent;
  qreal left = (mViewType == StringHandler::Icon) ? pGraphicalViewsPage->getIconViewExtentLeft() : pGraphicalViewsPage->getDiagramViewExtentLeft();
  qreal bottom = (mViewType == StringHandler::Icon) ? pGraphicalViewsPage->getIconViewExtentBottom() : pGraphicalViewsPage->getDiagramViewExtentBottom();
  qreal right = (mViewType == StringHandler::Icon) ? pGraphicalViewsPage->getIconViewExtentRight() : pGraphicalViewsPage->getDiagramViewExtentRight();
  qreal top = (mViewType == StringHandler::Icon) ? pGraphicalViewsPage->getIconViewExtentTop() : pGraphicalViewsPage->getDiagramViewExtentTop();
  extent << QPointF(left, bottom) << QPointF(right, top);
  mpCoOrdinateSystem->setExtent(extent);
  mpCoOrdinateSystem->setPreserveAspectRatio((mViewType == StringHandler::Icon) ? pGraphicalViewsPage->getIconViewPreserveAspectRation() : pGraphicalViewsPage->getDiagramViewPreserveAspectRation());
  mpCoOrdinateSystem->setInitialScale((mViewType == StringHandler::Icon) ? pGraphicalViewsPage->getIconViewScaleFactor() : pGraphicalViewsPage->getDiagramViewScaleFactor());
  qreal horizontal = (mViewType == StringHandler::Icon) ? pGraphicalViewsPage->getIconViewGridHorizontal() : pGraphicalViewsPage->getDiagramViewGridHorizontal();
  qreal vertical = (mViewType == StringHandler::Icon) ? pGraphicalViewsPage->getIconViewGridVertical() : pGraphicalViewsPage->getDiagramViewGridVertical();
  mpCoOrdinateSystem->setGrid(QPointF(horizontal, vertical));
  setExtentRectangle(left, bottom, right, top);
  centerOn(sceneRect().center());
  scale(1.0, -1.0);     // invert the drawing area.
  setIsCustomScale(false);
  setAddClassAnnotationNeeded(false);
  setIsCreatingConnection(false);
  mIsCreatingLineShape = false;
  mIsCreatingPolygonShape = false;
  mIsCreatingRectangleShape = false;
  mIsCreatingEllipseShape = false;
  mIsCreatingTextShape = false;
  mIsCreatingBitmapShape = false;
  mpClickedComponent = 0;
  setIsMovingComponentsAndShapes(false);
  setRenderingLibraryPixmap(false);
  createActions();
}

void GraphicsView::setExtentRectangle(qreal left, qreal bottom, qreal right, qreal top)
{
  mExtentRectangle = QRectF(left, bottom, fabs(left - right), fabs(bottom - top));
  QRectF sceneRectangle = mExtentRectangle.adjusted(left * 2, bottom * 2, right * 2, top * 2);
  setSceneRect(sceneRectangle);
}

void GraphicsView::setIsCreatingConnection(bool enable)
{
  mIsCreatingConnection = enable;
  if (enable) {
    setDragMode(QGraphicsView::NoDrag);
  } else {
    setDragMode(QGraphicsView::RubberBandDrag);
  }
  setItemsFlags(!enable);
}

void GraphicsView::setIsCreatingLineShape(bool enable)
{
  mIsCreatingLineShape = enable;
  if (enable) {
    setDragMode(QGraphicsView::NoDrag);
  } else {
    setDragMode(QGraphicsView::RubberBandDrag);
  }
  setItemsFlags(!enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsCreatingPolygonShape(bool enable)
{
  mIsCreatingPolygonShape = enable;
  if (enable) {
    setDragMode(QGraphicsView::NoDrag);
  } else {
    setDragMode(QGraphicsView::RubberBandDrag);
  }
  setItemsFlags(!enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsCreatingRectangleShape(bool enable)
{
  mIsCreatingRectangleShape = enable;
  if (enable) {
    setDragMode(QGraphicsView::NoDrag);
  } else {
    setDragMode(QGraphicsView::RubberBandDrag);
  }
  setItemsFlags(!enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsCreatingEllipseShape(bool enable)
{
  mIsCreatingEllipseShape = enable;
  if (enable) {
    setDragMode(QGraphicsView::NoDrag);
  } else {
    setDragMode(QGraphicsView::RubberBandDrag);
  }
  setItemsFlags(!enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsCreatingTextShape(bool enable)
{
  mIsCreatingTextShape = enable;
  if (enable) {
    setDragMode(QGraphicsView::NoDrag);
  } else {
    setDragMode(QGraphicsView::RubberBandDrag);
  }
  setItemsFlags(!enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsCreatingBitmapShape(bool enable)
{
  mIsCreatingBitmapShape = enable;
  if (enable) {
    setDragMode(QGraphicsView::NoDrag);
  } else {
    setDragMode(QGraphicsView::RubberBandDrag);
  }
  setItemsFlags(!enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setItemsFlags(bool enable)
{
  // set components, shapes and connection flags accordingly
  foreach(Component *pComponent, mComponentsList) {
    pComponent->setComponentFlags(enable);
  }
  foreach(ShapeAnnotation *pShapeAnnotation, mShapesList){
    pShapeAnnotation->setShapeFlags(enable);
  }
  foreach(LineAnnotation *pLineAnnotation, mConnectionsList) {
    pLineAnnotation->setShapeFlags(enable);
  }
}

/*!
 * \brief GraphicsView::updateUndoRedoActions
 * Updates the Undo Redo actions depending shape(s) creation state.
 * \param enable
 */
void GraphicsView::updateUndoRedoActions(bool enable)
{
  if (enable) {
    mpModelWidget->getModelWidgetContainer()->getMainWindow()->getUndoAction()->setEnabled(!enable);
    mpModelWidget->getModelWidgetContainer()->getMainWindow()->getRedoAction()->setEnabled(!enable);
  } else {
    mpModelWidget->updateUndoRedoActions();
  }
}

bool GraphicsView::addComponent(QString className, QPointF position)
{
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
  LibraryTreeItem *pLibraryTreeItem = pMainWindow->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(className);
  if (!pLibraryTreeItem) {
    return false;
  }
  // if we are dropping something on meta-model editor then we can skip Modelica stuff.
  if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::TLM) {
    if (pLibraryTreeItem->getFileName().isEmpty()) {
      QMessageBox::information(pMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::information),
                               tr("The class <b>%1</b> is not saved. You can only drag & drop saved classes.")
                               .arg(pLibraryTreeItem->getNameStructure()), Helper::ok);
      return false;
    } else {
      // item not to be dropped on itself; if dropping an item on itself
      if (isClassDroppedOnItself(pLibraryTreeItem)) {
        return false;
      }
      QString name = getUniqueComponentName(StringHandler::toCamelCase(pLibraryTreeItem->getName()));
      addComponentToView(name, pLibraryTreeItem, "", position, new ComponentInfo(""), true, false);
      return true;
    }
  } else {
    StringHandler::ModelicaClasses type = pLibraryTreeItem->getRestriction();
    OptionsDialog *pOptionsDialog = mpModelWidget->getModelWidgetContainer()->getMainWindow()->getOptionsDialog();
    // item not to be dropped on itself; if dropping an item on itself
    if (isClassDroppedOnItself(pLibraryTreeItem)) {
      return false;
    } else { // check if the model is partial
      QString name;
      if (pLibraryTreeItem->isPartial()) {
        if (pOptionsDialog->getNotificationsPage()->getReplaceableIfPartialCheckBox()->isChecked()) {
          NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::ReplaceableIfPartial,
                                                                              NotificationsDialog::InformationIcon,
                                                                              mpModelWidget->getModelWidgetContainer()->getMainWindow());
          pNotificationsDialog->setNotificationLabelString(GUIMessages::getMessage(GUIMessages::MAKE_REPLACEABLE_IF_PARTIAL)
                                                           .arg(StringHandler::getModelicaClassType(type).toLower()).arg(name));
          if (!pNotificationsDialog->exec()) {
            return false;
          }
        }
      }
      // get the model defaultComponentPrefixes
      QString defaultPrefix = pMainWindow->getOMCProxy()->getDefaultComponentPrefixes(pLibraryTreeItem->getNameStructure());
      // get the model defaultComponentName
      QString defaultName = pMainWindow->getOMCProxy()->getDefaultComponentName(pLibraryTreeItem->getNameStructure());
      if (defaultName.isEmpty()) {
        name = getUniqueComponentName(StringHandler::toCamelCase(pLibraryTreeItem->getName()));
      } else {
        if (checkComponentName(defaultName)) {
          name = defaultName;
        } else {
          name = getUniqueComponentName(defaultName);
          // show the information to the user if we have changed the name of some inner component.
          if (defaultPrefix.contains("inner")) {
            if (pOptionsDialog->getNotificationsPage()->getInnerModelNameChangedCheckBox()->isChecked()) {
              NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::InnerModelNameChanged,
                                                                                  NotificationsDialog::InformationIcon,
                                                                                  mpModelWidget->getModelWidgetContainer()->getMainWindow());
              pNotificationsDialog->setNotificationLabelString(GUIMessages::getMessage(GUIMessages::INNER_MODEL_NAME_CHANGED)
                                                               .arg(defaultName).arg(name));
              if (!pNotificationsDialog->exec()) {
                return false;
              }
            }
          }
        }
      }
      // if dropping an item on the diagram layer
      if (mViewType == StringHandler::Diagram) {
        // if item is a class, model, block, connector or record. then we can drop it to the graphicsview
        if ((type == StringHandler::Class) || (type == StringHandler::Model) || (type == StringHandler::Block) ||
            (type == StringHandler::ExpandableConnector) || (type == StringHandler::Connector) || (type == StringHandler::Record)) {
          addComponentToView(name, pLibraryTreeItem, "", position, new ComponentInfo(""));
          return true;
        } else {
          QMessageBox::information(pMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::information),
                                   GUIMessages::getMessage(GUIMessages::DIAGRAM_VIEW_DROP_MSG).arg(pLibraryTreeItem->getNameStructure())
                                   .arg(StringHandler::getModelicaClassType(type)), Helper::ok);
          return false;
        }
      } else if (mViewType == StringHandler::Icon) { // if dropping an item on the icon layer
        // if item is a connector. then we can drop it to the graphicsview
        if (type == StringHandler::Connector || type == StringHandler::ExpandableConnector) {
          addComponentToView(name, pLibraryTreeItem, "", position, new ComponentInfo(""));
          return true;
        } else {
          QMessageBox::information(pMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::information),
                                   GUIMessages::getMessage(GUIMessages::ICON_VIEW_DROP_MSG).arg(pLibraryTreeItem->getNameStructure())
                                   .arg(StringHandler::getModelicaClassType(type)), Helper::ok);
          return false;
        }
      }
    }
  }
  return false;
}

/*!
 * \brief GraphicsView::addComponentToView
 * Adds the Component to the Graphical Views.
 * \param name
 * \param className
 * \param transformationString
 * \param point
 * \param pComponentInfo
 * \param type
 * \param addObject
 * \param openingClass
 * \param inheritedClass
 * \param inheritedClassName
 * \param fileName
 */
void GraphicsView::addComponentToView(QString name, LibraryTreeItem *pLibraryTreeItem, QString transformationString, QPointF position,
                                      ComponentInfo *pComponentInfo, bool addObject, bool openingClass)
{
  AddComponentCommand *pAddComponentCommand;
  pAddComponentCommand = new AddComponentCommand(name, pLibraryTreeItem, transformationString, position, pComponentInfo, addObject,
                                                 openingClass, this);
  mpModelWidget->getUndoStack()->push(pAddComponentCommand);
  if (!openingClass) {
    mpModelWidget->updateModelicaText();
  }
}

/*!
 * \brief GraphicsView::addComponentToList
 * Adds the Component to components list.
 * \param pComponent
 */
void GraphicsView::addComponentToList(Component *pComponent)
{
  mComponentsList.append(pComponent);
}

void GraphicsView::addComponentToClass(Component *pComponent)
{
  if (mpModelWidget->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::Modelica) {
    MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
    // Add the component to model in OMC Global Scope.
    QString className = StringHandler::makeClassNameRelative(pComponent->getLibraryTreeItem()->getNameStructure(),
                                                             mpModelWidget->getLibraryTreeItem()->getNameStructure());
    pMainWindow->getOMCProxy()->addComponent(pComponent->getName(), className, mpModelWidget->getLibraryTreeItem()->getNameStructure(),
                                             pComponent->getPlacementAnnotation());
  } else if (mpModelWidget->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::TLM) {
    TLMEditor *pTLMEditor = dynamic_cast<TLMEditor*>(mpModelWidget->getEditor());
    QFileInfo fileInfo(pComponent->getLibraryTreeItem()->getFileName());
    // create StartCommand depending on the external model file extension.
    QString startCommand;
    if (fileInfo.suffix().compare("mo") == 0) {
      startCommand = "StartTLMOpenModelica";
    } else if (fileInfo.suffix().compare("in") == 0) {
      startCommand = "StartTLMBeast";
    } else {
      startCommand = "";
    }
    QString visible = pComponent->mTransformation.getVisible() ? "true" : "false";
    // add SubModel Element
    pTLMEditor->addSubModel(pComponent->getName(), "false", fileInfo.fileName(), startCommand, visible, pComponent->getTransformationOrigin(),
                            pComponent->getTransformationExtent(), QString::number(pComponent->mTransformation.getRotateAngle()));
  }
  // make the model modified
  mpModelWidget->setModelModified();
}

/*!
 * \brief GraphicsView::deleteComponent
 * Delete the component and its corresponding connectors from the components list and OMC.
 * \param component is the object to be deleted.
 */
void GraphicsView::deleteComponent(Component *pComponent)
{
  mpModelWidget->getUndoStack()->push(new DeleteComponentCommand(pComponent, this));
  // First Remove the Connector associated to this component
  int i = 0;
  while(i != mConnectionsList.size()) {
    QString startComponentName, endComponentName = "";
    if (mConnectionsList[i]->getStartComponent()) {
      startComponentName = mConnectionsList[i]->getStartComponent()->getRootParentComponent()->getName();
    }
    if (mConnectionsList[i]->getEndComponent()) {
      endComponentName = mConnectionsList[i]->getEndComponent()->getRootParentComponent()->getName();
    }
    if (startComponentName == pComponent->getName() || endComponentName == pComponent->getName()) {
      deleteConnection(mConnectionsList[i]);
      i = 0;   //Restart iteration if map has changed
    } else {
      ++i;
    }
  }
}

/*!
 * \brief GraphicsView::deleteComponentObject
 * Deletes the Component.
 * \param pComponent
 */
void GraphicsView::deleteComponentFromClass(Component *pComponent)
{
  if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    OMCProxy *pOMCProxy = mpModelWidget->getModelWidgetContainer()->getMainWindow()->getOMCProxy();
    // delete the component from OMC
    pOMCProxy->deleteComponent(pComponent->getName(), mpModelWidget->getLibraryTreeItem()->getNameStructure());
  } else if (mpModelWidget->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::TLM) {
    TLMEditor *pTLMEditor = dynamic_cast<TLMEditor*>(mpModelWidget->getEditor());
    pTLMEditor->deleteSubModel(pComponent->getName());
  }
  // make the model modified
  mpModelWidget->setModelModified();
}

/*!
 * \brief GraphicsView::deleteComponentFromList
 * Deletes the Component from components list.
 * \param pComponent
 */
void GraphicsView::deleteComponentFromList(Component *pComponent)
{
  mComponentsList.removeOne(pComponent);
}

/*!
 * \brief GraphicsView::getComponentObject
 * Finds the Component
 * \param componentName
 * \return
 */
Component* GraphicsView::getComponentObject(QString componentName)
{
  foreach (ModelWidget::InheritedClass *pInheritedClass, mpModelWidget->getInheritedClassesList()) {
    if (mViewType == StringHandler::Icon) {
      foreach (Component *pComponent, pInheritedClass->mIconComponentsList) {
        if (pComponent->getName().compare(componentName) == 0) {
          return pComponent;
        }
      }
    } else {
      foreach (Component *pComponent, pInheritedClass->mDiagramComponentsList) {
        if (pComponent->getName().compare(componentName) == 0) {
          return pComponent;
        }
      }
    }
  }
  foreach (Component *pComponent, mComponentsList) {
    if (pComponent->getName().compare(componentName) == 0) {
      return pComponent;
    }
  }
  return 0;
}

QString GraphicsView::getUniqueComponentName(QString componentName, int number)
{
  QString name;
  name = QString(componentName).append(QString::number(number));
  foreach (Component *pComponent, mComponentsList)
  {
    if (pComponent->getName().compare(name, Qt::CaseSensitive) == 0)
    {
      name = getUniqueComponentName(componentName, ++number);
      break;
    }
  }
  return name;
}

bool GraphicsView::checkComponentName(QString componentName)
{
  foreach (Component *pComponent, mComponentsList)
    if (pComponent->getName().compare(componentName, Qt::CaseSensitive) == 0)
      return false;
  return true;
}

/*!
 * \brief GraphicsView::addConnectionToOMC
 * Adds the connection to class.
 * \param pConnectionLineAnnotation - the connection to add.
 */
void GraphicsView::addConnectionToClass(LineAnnotation *pConnectionLineAnnotation)
{
  if (mpModelWidget->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::TLM) {
    // show TLM connection attributes dialog
    MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
    TLMConnectionAttributes *pTLMConnectionAttributes = new TLMConnectionAttributes(pConnectionLineAnnotation, pMainWindow);
    pTLMConnectionAttributes->show();
  } else {
    MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
    if (pMainWindow->getOMCProxy()->addConnection(pConnectionLineAnnotation->getStartComponentName(),
                                                  pConnectionLineAnnotation->getEndComponentName(),
                                                  mpModelWidget->getLibraryTreeItem()->getNameStructure(),
                                                  QString("annotate=").append(pConnectionLineAnnotation->getShapeAnnotation()))) {
      /* Ticket #2450
       * Do not check for the ports compatibility via instantiatemodel. Just let the user create the connection.
       */
      //pMainWindow->getOMCProxy()->instantiateModelSucceeds(mpModelWidget->getNameStructure());
    }
  }
  // make the model modified
  mpModelWidget->setModelModified();
}

/*!
 * \brief GraphicsView::deleteConnectionFromOMC
 * Deletes the connection from OMC.
 * \param pConnectonLineAnnotation - the connection to delete.
 */
void GraphicsView::deleteConnectionFromClass(LineAnnotation *pConnectonLineAnnotation)
{
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
  if(mpModelWidget->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::TLM) {
    TLMEditor *pTLMEditor = dynamic_cast<TLMEditor*>(mpModelWidget->getEditor());
    pTLMEditor->deleteConnection(pConnectonLineAnnotation->getStartComponentName(), pConnectonLineAnnotation->getEndComponentName());
  } else {
    pMainWindow->getOMCProxy()->deleteConnection(pConnectonLineAnnotation->getStartComponentName(),
                                                 pConnectonLineAnnotation->getEndComponentName(),
                                                 mpModelWidget->getLibraryTreeItem()->getNameStructure());
  }
  // make the model modified
  mpModelWidget->setModelModified();
}

void GraphicsView::deleteShape(ShapeAnnotation *pShape)
{
  mpModelWidget->getUndoStack()->push(new DeleteShapeCommand(pShape, this));
}

void GraphicsView::reOrderItems()
{
  int zValue = 0;
  // set stacking order for inherited items
  QList<ModelWidget::InheritedClass*> inheritedClasses = mpModelWidget->getInheritedClassesList();
  foreach (ModelWidget::InheritedClass *pInheritedClass, inheritedClasses) {
    QList<ShapeAnnotation*> inheritedShapesList;
    if (mViewType == StringHandler::Icon) {
      inheritedShapesList = pInheritedClass->mIconShapesList;
    } else {
      inheritedShapesList = pInheritedClass->mDiagramShapesList;
    }
    foreach (ShapeAnnotation *pShapeAnnotation, inheritedShapesList) {
      zValue++;
      pShapeAnnotation->setZValue(zValue);
    }
  }
  // set stacking order for shapes.
  foreach (ShapeAnnotation *pShapeAnnotation, mShapesList) {
    zValue++;
    pShapeAnnotation->setZValue(zValue);
  }
}

/*!
 * \brief GraphicsView::bringToFront
 * \param pShape
 * Brings the shape to front of all other shapes.
 */
void GraphicsView::bringToFront(ShapeAnnotation *pShape)
{
  deleteShapeFromList(pShape);
  int i = 0;
  // update the shapes z index
  for (; i < mShapesList.size() ; i++) {
    mShapesList.at(i)->setZValue(i + 1);
  }
  pShape->setZValue(i + 1);
  mShapesList.append(pShape);
  // update class annotation.
  addClassAnnotation();
}

/*!
 * \brief GraphicsView::bringForward
 * \param pShape
 * Brings the shape one level forward.
 */
void GraphicsView::bringForward(ShapeAnnotation *pShape)
{
  int shapeIndex = mShapesList.indexOf(pShape);
  if (shapeIndex == -1 || shapeIndex == mShapesList.size() - 1) { // if the shape is already at top.
    return;
  }
  // swap the shapes in the list
  mShapesList.swap(shapeIndex, shapeIndex + 1);
  // update the shapes z index
  for (int i = 0 ; i < mShapesList.size() ; i++) {
    mShapesList.at(i)->setZValue(i + 1);
  }
  // update class annotation.
  addClassAnnotation();
}

/*!
 * \brief GraphicsView::sendToBack
 * \param pShape
 * Sends the shape to back of all other shapes.
 */
void GraphicsView::sendToBack(ShapeAnnotation *pShape)
{
  deleteShapeFromList(pShape);
  int i = 0;
  pShape->setZValue(i + 1);
  mShapesList.prepend(pShape);
  // update the shapes z index
  for (i = 1 ; i < mShapesList.size() ; i++) {
    mShapesList.at(i)->setZValue(i + 1);
  }
  // update class annotation.
  addClassAnnotation();
}

/*!
 * \brief GraphicsView::sendBackward
 * \param pShape
 * Sends the shape one level backward.
 */
void GraphicsView::sendBackward(ShapeAnnotation *pShape)
{
  int shapeIndex = mShapesList.indexOf(pShape);
  if (shapeIndex <= 0) { // if the shape is already at bottom.
    return;
  }
  // swap the shapes in the list
  mShapesList.swap(shapeIndex - 1, shapeIndex);
  // update the shapes z index
  for (int i = 0 ; i < mShapesList.size() ; i++) {
    mShapesList.at(i)->setZValue(i + 1);
  }
  // update class annotation.
  addClassAnnotation();
}

void GraphicsView::removeAllComponents()
{
  mComponentsList.clear();
}

void GraphicsView::removeAllShapes()
{
  mShapesList.clear();
}

void GraphicsView::removeAllConnections()
{
  mConnectionsList.clear();
}

void GraphicsView::createLineShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary()) {
    return;
  }

  if (!isCreatingLineShape()) {
    mpLineShapeAnnotation = new LineAnnotation("", this);
    mpModelWidget->getUndoStack()->push(new AddShapeCommand(mpLineShapeAnnotation, this));
    reOrderItems();
    setIsCreatingLineShape(true);
    mpLineShapeAnnotation->addPoint(point);
    mpLineShapeAnnotation->addPoint(point);
  } else {  // if we are already creating a line then only add one point.
    mpLineShapeAnnotation->addPoint(point);
  }
}

void GraphicsView::createPolygonShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary()) {
    return;
  }

  if (!isCreatingPolygonShape()) {
    mpPolygonShapeAnnotation = new PolygonAnnotation("", this);
    mpModelWidget->getUndoStack()->push(new AddShapeCommand(mpPolygonShapeAnnotation, this));
    reOrderItems();
    setIsCreatingPolygonShape(true);
    mpPolygonShapeAnnotation->addPoint(point);
    mpPolygonShapeAnnotation->addPoint(point);
    mpPolygonShapeAnnotation->addPoint(point);
  } else { // if we are already creating a polygon then only add one point.
    mpPolygonShapeAnnotation->addPoint(point);
  }
}

void GraphicsView::createRectangleShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary()) {
    return;
  }

  if (!isCreatingRectangleShape()) {
    mpRectangleShapeAnnotation = new RectangleAnnotation("", this);
    mpModelWidget->getUndoStack()->push(new AddShapeCommand(mpRectangleShapeAnnotation, this));
    reOrderItems();
    setIsCreatingRectangleShape(true);
    mpRectangleShapeAnnotation->replaceExtent(0, point);
    mpRectangleShapeAnnotation->replaceExtent(1, point);
  } else { // if we are already creating a rectangle then finish creating it.
    // finish creating the rectangle
    setIsCreatingRectangleShape(false);
    MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
    // set the transformation matrix
    mpRectangleShapeAnnotation->setOrigin(mpRectangleShapeAnnotation->sceneBoundingRect().center());
    mpRectangleShapeAnnotation->adjustExtentsWithOrigin();
    mpRectangleShapeAnnotation->initializeTransformation();
    // draw corner items for the rectangle shape
    mpRectangleShapeAnnotation->drawCornerItems();
    mpRectangleShapeAnnotation->setSelected(true);
    // make the toolbar button of rectangle unchecked
    pMainWindow->getRectangleShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    mpModelWidget->getLibraryTreeItem()->emitShapeAdded(mpRectangleShapeAnnotation, this);
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
  }
}

void GraphicsView::createEllipseShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary()) {
    return;
  }

  if (!isCreatingEllipseShape()) {
    mpEllipseShapeAnnotation = new EllipseAnnotation("", this);
    mpModelWidget->getUndoStack()->push(new AddShapeCommand(mpEllipseShapeAnnotation, this));
    reOrderItems();
    setIsCreatingEllipseShape(true);
    mpEllipseShapeAnnotation->replaceExtent(0, point);
    mpEllipseShapeAnnotation->replaceExtent(1, point);
  } else { // if we are already creating an ellipse then finish creating it.
    // finish creating the ellipse
    setIsCreatingEllipseShape(false);
    MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
    // set the transformation matrix
    mpEllipseShapeAnnotation->setOrigin(mpEllipseShapeAnnotation->sceneBoundingRect().center());
    mpEllipseShapeAnnotation->adjustExtentsWithOrigin();
    mpEllipseShapeAnnotation->initializeTransformation();
    // draw corner items for the ellipse shape
    mpEllipseShapeAnnotation->drawCornerItems();
    mpEllipseShapeAnnotation->setSelected(true);
    // make the toolbar button of ellipse unchecked
    pMainWindow->getEllipseShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    mpModelWidget->getLibraryTreeItem()->emitShapeAdded(mpEllipseShapeAnnotation, this);
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
  }
}

void GraphicsView::createTextShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary()) {
    return;
  }

  if (!isCreatingTextShape()) {
    mpTextShapeAnnotation = new TextAnnotation("", this);
    mpModelWidget->getUndoStack()->push(new AddShapeCommand(mpTextShapeAnnotation, this));
    reOrderItems();
    setIsCreatingTextShape(true);
    mpTextShapeAnnotation->setTextString("text");
    mpTextShapeAnnotation->replaceExtent(0, point);
    mpTextShapeAnnotation->replaceExtent(1, point);
  } else { // if we are already creating a text then finish creating it.
    // finish creating the text
    setIsCreatingTextShape(false);
    MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
    // set the transformation matrix
    mpTextShapeAnnotation->setOrigin(mpTextShapeAnnotation->sceneBoundingRect().center());
    mpTextShapeAnnotation->adjustExtentsWithOrigin();
    mpTextShapeAnnotation->initializeTransformation();
    // draw corner items for the text shape
    mpTextShapeAnnotation->drawCornerItems();
    // make the toolbar button of text unchecked
    pMainWindow->getTextShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    mpModelWidget->getLibraryTreeItem()->emitShapeAdded(mpTextShapeAnnotation, this);
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
    mpTextShapeAnnotation->showShapeProperties();
    mpTextShapeAnnotation->setSelected(true);
  }
}

void GraphicsView::createBitmapShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary()) {
    return;
  }

  if (!isCreatingBitmapShape()) {
    mpBitmapShapeAnnotation = new BitmapAnnotation(mpModelWidget->getLibraryTreeItem()->getFileName(), "", this);
    mpModelWidget->getUndoStack()->push(new AddShapeCommand(mpBitmapShapeAnnotation, this));
    reOrderItems();
    setIsCreatingBitmapShape(true);
    mpBitmapShapeAnnotation->replaceExtent(0, point);
    mpBitmapShapeAnnotation->replaceExtent(1, point);
  } else { // if we are already creating a bitmap then finish creating it.
    // finish creating the bitmap
    setIsCreatingBitmapShape(false);
    MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
    // set the transformation matrix
    mpBitmapShapeAnnotation->setOrigin(mpBitmapShapeAnnotation->sceneBoundingRect().center());
    mpBitmapShapeAnnotation->adjustExtentsWithOrigin();
    mpBitmapShapeAnnotation->initializeTransformation();
    // draw corner items for the bitmap shape
    mpBitmapShapeAnnotation->drawCornerItems();
    // make the toolbar button of text unchecked
    pMainWindow->getBitmapShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    mpModelWidget->getLibraryTreeItem()->emitShapeAdded(mpBitmapShapeAnnotation, this);
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
    mpBitmapShapeAnnotation->showShapeProperties();
    mpBitmapShapeAnnotation->setSelected(true);
  }
}

//! Gets the bounding rectangle of all the items added to the view, excluding background and so on
QRectF GraphicsView::itemsBoundingRect()
{
  QRectF rect;
  foreach(QGraphicsItem *item, mComponentsList){
    rect |= item->sceneBoundingRect();
  }
  foreach(QGraphicsItem *item, mShapesList){
    rect |= item->sceneBoundingRect();
  }
  foreach(QGraphicsItem *item, mConnectionsList){
    rect |= item->sceneBoundingRect();
  }
  return mapFromScene(rect).boundingRect();
}

QPointF GraphicsView::snapPointToGrid(QPointF point)
{
  qreal stepX = mpCoOrdinateSystem->getHorizontalGridStep();
  qreal stepY = mpCoOrdinateSystem->getVerticalGridStep();
  point.setX(stepX * qFloor((point.x() / stepX) + 0.5));
  point.setY(stepY * qFloor((point.y() / stepY) + 0.5));
  return point;
}

QPointF GraphicsView::movePointByGrid(QPointF point)
{
  qreal stepX = mpCoOrdinateSystem->getHorizontalGridStep();
  qreal stepY = mpCoOrdinateSystem->getVerticalGridStep();
  point.setX(qRound(point.x() / stepX) * stepX);
  point.setY(qRound(point.y() / stepY) * stepY);
  return point;
}

QPointF GraphicsView::roundPoint(QPointF point)
{
  qreal divisor = 0.5;
  qreal x = (fmod(point.x(), divisor) == 0) ? point.x() : qRound(point.x());
  qreal y = (fmod(point.y(), divisor) == 0) ? point.y() : qRound(point.y());
  return QPointF(x, y);
}

/*!
 * \brief GraphicsView::hasIconAnnotation
 * Checks if class has annotation.
 * \return
 */
bool GraphicsView::hasAnnotation()
{
  foreach (ModelWidget::InheritedClass *pInheritedClass, mpModelWidget->getInheritedClassesList()) {
    if (mViewType == StringHandler::Icon) {
      if (pInheritedClass->mIconShapesList.size() > 0) {
        return true;
      } else {
        foreach (Component *pInheritedComponent, pInheritedClass->mIconComponentsList) {
          if (pInheritedComponent->hasShapeAnnotation(pInheritedComponent)) {
            return true;
          }
        }
      }
    } else if (mViewType == StringHandler::Diagram && pInheritedClass->mDiagramShapesList.size() > 0) {
      return true;
    }
  }
  if (!mShapesList.isEmpty()) {
    return true;
  }
  foreach (Component *pComponent, mComponentsList) {
    if (pComponent->hasShapeAnnotation(pComponent)) {
      return true;
    }
  }
  return false;
}

void GraphicsView::addItem(QGraphicsItem *pGraphicsItem)
{
  if (!scene()->items().contains(pGraphicsItem)) {
    scene()->addItem(pGraphicsItem);
  }
}

void GraphicsView::removeItem(QGraphicsItem *pGraphicsItem)
{
  if (scene()->items().contains(pGraphicsItem)) {
    scene()->removeItem(pGraphicsItem);
  }
}

void GraphicsView::createActions()
{
  bool isSystemLibrary = mpModelWidget->getLibraryTreeItem()->isSystemLibrary();
  // Graphics View Properties Action
  mpPropertiesAction = new QAction(Helper::properties, this);
  connect(mpPropertiesAction, SIGNAL(triggered()), SLOT(showGraphicsViewProperties()));
  // Actions for shapes and Components
  // Manhattanize Action
  mpManhattanizeAction = new QAction(tr("Manhattanize"), this);
  mpManhattanizeAction->setStatusTip(tr("Manhattanize the lines"));
  mpManhattanizeAction->setDisabled(isSystemLibrary);
  connect(mpManhattanizeAction, SIGNAL(triggered()), SLOT(manhattanizeItems()));
  // Delete Action
  mpDeleteAction = new QAction(QIcon(":/Resources/icons/delete.svg"), Helper::deleteStr, this);
  mpDeleteAction->setStatusTip(tr("Deletes the item"));
  mpDeleteAction->setShortcut(QKeySequence::Delete);
  mpDeleteAction->setDisabled(isSystemLibrary);
  connect(mpDeleteAction, SIGNAL(triggered()), SLOT(deleteItems()));
  // Duplicate Action
  mpDuplicateAction = new QAction(QIcon(":/Resources/icons/duplicate.svg"), Helper::duplicate, this);
  mpDuplicateAction->setStatusTip(Helper::duplicateTip);
  mpDuplicateAction->setShortcut(QKeySequence("Ctrl+d"));
  mpDuplicateAction->setDisabled(isSystemLibrary);
  // Bring To Front Action
  mpBringToFrontAction = new QAction(QIcon(":/Resources/icons/bring-to-front.svg"), tr("Bring to Front"), this);
  mpBringToFrontAction->setStatusTip(tr("Brings the item to front"));
  mpBringToFrontAction->setDisabled(isSystemLibrary);
  mpBringToFrontAction->setDisabled(true);
  // Bring Forward Action
  mpBringForwardAction = new QAction(QIcon(":/Resources/icons/bring-forward.svg"), tr("Bring Forward"), this);
  mpBringForwardAction->setStatusTip(tr("Brings the item one level forward"));
  mpBringForwardAction->setDisabled(isSystemLibrary);
  mpBringForwardAction->setDisabled(true);
  // Send To Back Action
  mpSendToBackAction = new QAction(QIcon(":/Resources/icons/send-to-back.svg"), tr("Send to Back"), this);
  mpSendToBackAction->setStatusTip(tr("Sends the item to back"));
  mpSendToBackAction->setDisabled(isSystemLibrary);
  mpSendToBackAction->setDisabled(true);
  // Send Backward Action
  mpSendBackwardAction = new QAction(QIcon(":/Resources/icons/send-backward.svg"), tr("Send Backward"), this);
  mpSendBackwardAction->setStatusTip(tr("Sends the item one level backward"));
  mpSendBackwardAction->setDisabled(isSystemLibrary);
  mpSendBackwardAction->setDisabled(true);
  // Rotate ClockWise Action
  mpRotateClockwiseAction = new QAction(QIcon(":/Resources/icons/rotateclockwise.svg"), tr("Rotate Clockwise"), this);
  mpRotateClockwiseAction->setStatusTip(tr("Rotates the item clockwise"));
  mpRotateClockwiseAction->setShortcut(QKeySequence("Ctrl+r"));
  mpRotateClockwiseAction->setDisabled(isSystemLibrary);
  connect(mpRotateClockwiseAction, SIGNAL(triggered()), SLOT(rotateClockwise()));
  // Rotate Anti-ClockWise Action
  mpRotateAntiClockwiseAction = new QAction(QIcon(":/Resources/icons/rotateanticlockwise.svg"), tr("Rotate Anticlockwise"), this);
  mpRotateAntiClockwiseAction->setStatusTip(tr("Rotates the item anticlockwise"));
  mpRotateAntiClockwiseAction->setShortcut(QKeySequence("Ctrl+Shift+r"));
  mpRotateAntiClockwiseAction->setDisabled(isSystemLibrary);
  connect(mpRotateAntiClockwiseAction, SIGNAL(triggered()), SLOT(rotateAntiClockwise()));
  // Flip Horizontal Action
  mpFlipHorizontalAction = new QAction(QIcon(":/Resources/icons/flip-horizontal.svg"), tr("Flip Horizontal"), this);
  mpFlipHorizontalAction->setStatusTip(tr("Flips the item horizontally"));
  mpFlipHorizontalAction->setDisabled(isSystemLibrary);
  // Flip Vertical Action
  mpFlipVerticalAction = new QAction(QIcon(":/Resources/icons/flip-vertical.svg"), tr("Flip Vertical"), this);
  mpFlipVerticalAction->setStatusTip(tr("Flips the item vertically"));
  mpFlipVerticalAction->setDisabled(isSystemLibrary);
}

/*!
 * \brief GraphicsView::isItemDroppedOnItself
 * Checks if item is dropped on itself.
 * \param pLibraryTreeItem
 * \return
 */
bool GraphicsView::isClassDroppedOnItself(LibraryTreeItem *pLibraryTreeItem)
{
  OptionsDialog *pOptionsDialog = mpModelWidget->getModelWidgetContainer()->getMainWindow()->getOptionsDialog();
  if (mpModelWidget->getLibraryTreeItem()->getNameStructure().compare(pLibraryTreeItem->getNameStructure()) == 0) {
    if (pOptionsDialog->getNotificationsPage()->getItemDroppedOnItselfCheckBox()->isChecked()) {
      NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::ItemDroppedOnItself,
                                                                          NotificationsDialog::InformationIcon,
                                                                          mpModelWidget->getModelWidgetContainer()->getMainWindow());
      pNotificationsDialog->exec();
    }
    return true;
  }
  return false;
}

/*!
 * \brief GraphicsView::isAnyItemSelectedAndEditable
 * If the class is system library then returns false.
 * Checks all the selected items. If the selected item is not inherited then returns true otherwise false.
 * \param key
 * \return
 */
bool GraphicsView::isAnyItemSelectedAndEditable(int key)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary()) {
    return false;
  }
  QList<QGraphicsItem*> selectedItems = scene()->selectedItems();
  for (int i = 0 ; i < selectedItems.size() ; i++) {
    // check the selected components.
    Component *pComponent = dynamic_cast<Component*>(selectedItems.at(i));
    if (pComponent && !pComponent->isInheritedComponent()) {
      return true;
    }
    // check the selected connections and shapes.
    ShapeAnnotation *pShapeAnnotation = dynamic_cast<ShapeAnnotation*>(selectedItems.at(i));
    if (pShapeAnnotation && !pShapeAnnotation->isInheritedShape()) {
      LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(pShapeAnnotation);
      // if the shape is connection line then we only return true for certain cases.
      if (pLineAnnotation && pLineAnnotation->getLineType() == LineAnnotation::ConnectionType) {
        switch (key) {
          case Qt::Key_Delete:
            return true;
          default:
            return false;
        }
      } else {
        return true;
      }
    }
  }
  return false;
}

void GraphicsView::addConnection(Component *pComponent)
{
  // When clicking the start component
  if (!isCreatingConnection()) {
    QPointF startPos = snapPointToGrid(pComponent->mapToScene(pComponent->boundingRect().center()));
    mpConnectionLineAnnotation = new LineAnnotation(pComponent, this);
    setIsCreatingConnection(true);
    mpConnectionLineAnnotation->addPoint(startPos);
    mpConnectionLineAnnotation->addPoint(startPos);
    mpConnectionLineAnnotation->addPoint(startPos);
  } else if (isCreatingConnection()) { // When clicking the end component
    mpConnectionLineAnnotation->setEndComponent(pComponent);
    // update the last point to the center of component
    QPointF newPos = snapPointToGrid(pComponent->mapToScene(pComponent->boundingRect().center()));
    mpConnectionLineAnnotation->updateEndPoint(newPos);
    mpConnectionLineAnnotation->update();
    // check if connection is valid
    Component *pStartComponent = mpConnectionLineAnnotation->getStartComponent();
    MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
    if (pStartComponent == pComponent) {
      QMessageBox::information(pMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::information),
                               GUIMessages::getMessage(GUIMessages::SAME_COMPONENT_CONNECT), Helper::ok);
      removeCurrentConnection();
    } else {
      bool showConnectionArrayDialog = false;
      if (pStartComponent->getComponentInfo()) {
        if (pStartComponent->getComponentInfo()->isArray()) {
          showConnectionArrayDialog = true;
        }
      }
      if (pComponent->getComponentInfo()) {
        if (pComponent->getComponentInfo()->isArray()) {
          showConnectionArrayDialog = true;
        }
      }
      if (showConnectionArrayDialog) {
        ConnectionArray *pConnectionArray = new ConnectionArray(this, mpConnectionLineAnnotation,
                                                                mpModelWidget->getModelWidgetContainer()->getMainWindow());
        pConnectionArray->exec();
      } else {
        QString startComponentName, endComponentName;
        if (pStartComponent->getParentComponent()) {
          startComponentName = QString(pStartComponent->getRootParentComponent()->getName()).append(".").append(pStartComponent->getName());
        } else {
          startComponentName = pStartComponent->getName();
        }
        if (pComponent->getParentComponent()) {
          endComponentName = QString(pComponent->getRootParentComponent()->getName()).append(".").append(pComponent->getName());
        } else {
          endComponentName = pComponent->getName();
        }
        mpConnectionLineAnnotation->setStartComponentName(startComponentName);
        mpConnectionLineAnnotation->setEndComponentName(endComponentName);
        mpModelWidget->getUndoStack()->push(new AddConnectionCommand(mpConnectionLineAnnotation, true, this));
        mpModelWidget->updateModelicaText();
      }
      setIsCreatingConnection(false);
    }
  }
}

/*!
 * \brief GraphicsView::removeCurrentConnection
 * Removes the current connecting connector from the model.
 */
void GraphicsView::removeCurrentConnection()
{
  if (isCreatingConnection()) {
    setIsCreatingConnection(false);
    delete mpConnectionLineAnnotation;
    mpConnectionLineAnnotation = 0;
  }
}

/*!
 * \brief GraphicsView::deleteConnection
 * Deletes the connection from the class.
 * \param pConnectionLineAnnotation - is a pointer to the connection to delete.
 */
void GraphicsView::deleteConnection(LineAnnotation *pConnectionLineAnnotation)
{
  mpModelWidget->getUndoStack()->push(new DeleteConnectionCommand(pConnectionLineAnnotation, this));
}

//! Resets zoom factor to 100%.
//! @see zoomIn()
//! @see zoomOut()
void GraphicsView::resetZoom()
{
  resetMatrix();
  scale(1.0, -1.0);
  setIsCustomScale(false);
  resizeEvent(new QResizeEvent(QSize(0,0), QSize(0,0)));
}

//! Increases zoom factor by 12%.
//! @see resetZoom()
//! @see zoomOut()
void GraphicsView::zoomIn()
{
  // zoom in limitation max: 1000%
  if (matrix().m11() < 34 && matrix().m22() > -34) {
    scale(1.12, 1.12);
    setIsCustomScale(true);
  }
}

//! Decreases zoom factor by 12%.
//! @see resetZoom()
//! @see zoomIn()
void GraphicsView::zoomOut()
{
  // zoom out limitation min: 10%
  if (matrix().m11() > 0.2 && matrix().m22() < -0.2) {
    scale(1/1.12, 1/1.12);
    setIsCustomScale(true);
  }
}

/*!
 * \brief GraphicsView::selectAll
 * Selects all shapes, components and connectors.
 */
void GraphicsView::selectAll()
{
  foreach (QGraphicsItem *pItem, items()) {
    pItem->setSelected(true);
  }
}

/*!
 * \brief GraphicsView::clearSelection
 * Clears the selection of all shapes, components and connectors.
 */
void GraphicsView::clearSelection()
{
  foreach (QGraphicsItem *pItem, items()) {
    pItem->setSelected(false);
  }
}

//! Adds the annotation string of Icon and Diagram layer to the model. Also creates the model icon in the tree.
//! If some custom models are cross referenced then update them accordingly.
void GraphicsView::addClassAnnotation(bool updateModelicaText)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary())
    return;
  /* Build the annotation string */
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
  QString annotationString;
  annotationString.append("annotate=");
  if (mViewType == StringHandler::Icon) {
    annotationString.append("Icon(");
  } else if (mViewType == StringHandler::Diagram) {
    annotationString.append("Diagram(");
  }
  // add the coordinate system first
  QList<QPointF> extent = mpCoOrdinateSystem->getExtent();
  annotationString.append("coordinateSystem=CoordinateSystem(extent={");
  annotationString.append("{").append(QString::number(extent.at(0).x())).append(", ").append(QString::number(extent.at(0).y())).append("}, ");
  annotationString.append("{").append(QString::number(extent.at(1).x())).append(", ").append(QString::number(extent.at(1).y())).append("}");
  annotationString.append("}");
  // add the preserveAspectRatio
  annotationString.append(", preserveAspectRatio=").append(mpCoOrdinateSystem->getPreserveAspectRatio() ? "true" : "false");
  // add the initial scale
  annotationString.append(", initialScale=").append(QString::number(mpCoOrdinateSystem->getInitialScale()));
  // add the grid
  QPointF grid = mpCoOrdinateSystem->getGrid();
  annotationString.append(", grid=").append("{").append(QString::number(grid.x())).append(", ").append(QString::number(grid.y())).append("})");
  // add the graphics annotations
  int counter = 0;
  if (mShapesList.size() > 0) {
    annotationString.append(", graphics={");
    foreach (ShapeAnnotation *pShapeAnnotation, mShapesList) {
      /* Don't add the inherited shape to the addClassAnnotation. */
      if (pShapeAnnotation->isInheritedShape()) {
        counter++;
        continue;
      }
      annotationString.append(pShapeAnnotation->getShapeAnnotation());
      if (counter < mShapesList.size() - 1)
        annotationString.append(",");
      counter++;
    }
    annotationString.append("}");
  }
  annotationString.append(")");
  // add the class annotation to model through OMC
  if (pMainWindow->getOMCProxy()->addClassAnnotation(mpModelWidget->getLibraryTreeItem()->getNameStructure(), annotationString)) {
    if (updateModelicaText) {
      mpModelWidget->updateModelicaText();
    }
    mpModelWidget->setModelModified();
    /* When something is added/changed in the icon layer then update the LibraryTreeItem in the Library Browser */
    if (mViewType == StringHandler::Icon) {
      mpModelWidget->getLibraryTreeItem()->handleIconUpdated();
    }
  } else {
    pMainWindow->getMessagesWidget()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                                tr("Error in class annotation ") + pMainWindow->getOMCProxy()->getResult(),
                                                                Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief GraphicsView::showGraphicsViewProperties
 * Opens the GraphicsViewProperties dialog.
 */
void GraphicsView::showGraphicsViewProperties()
{
  GraphicsViewProperties *pGraphicsViewProperties = new GraphicsViewProperties(this);
  pGraphicsViewProperties->show();
}

/*!
 * \brief GraphicsView::manhattanizeItems
 * Manhattanize the selected items by emitting GraphicsView::mouseManhattanize() SIGNAL.
 */
void GraphicsView::manhattanizeItems()
{
  mpModelWidget->getUndoStack()->beginMacro("Manhattanize by mouse");
  emit mouseManhattanize();
  mpModelWidget->updateClassAnnotationIfNeeded();
  mpModelWidget->updateModelicaText();
  mpModelWidget->getUndoStack()->endMacro();
}

/*!
 * \brief GraphicsView::deleteItems
 * Deletes the selected items by emitting GraphicsView::mouseDelete() SIGNAL.
 */
void GraphicsView::deleteItems()
{
  mpModelWidget->getUndoStack()->beginMacro("Deleting by mouse");
  emit mouseDelete();
  mpModelWidget->updateClassAnnotationIfNeeded();
  mpModelWidget->updateModelicaText();
  mpModelWidget->getUndoStack()->endMacro();
}

/*!
 * \brief GraphicsView::rotateClockwise
 * Rotates the selected items clockwise by emitting GraphicsView::mouseRotateClockwise() SIGNAL.
 */
void GraphicsView::rotateClockwise()
{
  mpModelWidget->getUndoStack()->beginMacro("Rotate clockwise by mouse");
  emit mouseRotateClockwise();
  mpModelWidget->updateClassAnnotationIfNeeded();
  mpModelWidget->updateModelicaText();
  mpModelWidget->getUndoStack()->endMacro();
}

/*!
 * \brief GraphicsView::rotateAntiClockwise
 * Rotates the selected items anti clockwise by emitting GraphicsView::mouseRotateAntiClockwise() SIGNAL.
 */
void GraphicsView::rotateAntiClockwise()
{
  mpModelWidget->getUndoStack()->beginMacro("Rotate anti clockwise by mouse");
  emit mouseRotateAntiClockwise();
  mpModelWidget->updateClassAnnotationIfNeeded();
  mpModelWidget->updateModelicaText();
  mpModelWidget->getUndoStack()->endMacro();
}

/*!
 * \brief GraphicsView::dragMoveEvent
 * Defines what happens when dragged and moved an object in a GraphicsView.
 * \param event - contains information of the drag operation.
 */
void GraphicsView::dragMoveEvent(QDragMoveEvent *event)
{
  // check if the class is system library
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary()) {
    event->ignore();
    return;
  }
  // read the mime data from the event
  if (event->mimeData()->hasFormat(Helper::modelicaComponentFormat) || event->mimeData()->hasFormat(Helper::modelicaFileFormat)) {
    event->setDropAction(Qt::CopyAction);
    event->accept();
  } else {
    event->ignore();
  }
}

/*!
 * \brief GraphicsView::dropEvent
 * Defines what happens when an object is dropped in a GraphicsView.
 * \param event - contains information of the drop operation.
 */
void GraphicsView::dropEvent(QDropEvent *event)
{
  setFocus();
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
  // check mimeData
  if (!event->mimeData()->hasFormat(Helper::modelicaComponentFormat) && !event->mimeData()->hasFormat(Helper::modelicaFileFormat)) {
    event->ignore();
    return;
  } else if (event->mimeData()->hasFormat(Helper::modelicaFileFormat)) {
    pMainWindow->openDroppedFile(event);
    event->accept();
  } else if (event->mimeData()->hasFormat(Helper::modelicaComponentFormat)) {
    // check if the class is system library
    if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary()) {
      event->ignore();
      return;
    }
    QByteArray itemData = event->mimeData()->data(Helper::modelicaComponentFormat);
    QDataStream dataStream(&itemData, QIODevice::ReadOnly);
    QString className;
    dataStream >> className;
    if (addComponent(className, mapToScene(event->pos()))) {
      event->accept();
    } else {
      event->ignore();
    }
  } else {
    event->ignore();
  }
}

void GraphicsView::drawBackground(QPainter *painter, const QRectF &rect)
{
  if (mSkipBackground || mpModelWidget->getLibraryTreeItem()->isSystemLibrary()) {
    return;
  }
  // draw scene rectangle white background
  painter->setPen(Qt::NoPen);
  if (mViewType == StringHandler::Icon) {
    painter->setBrush(QBrush(QColor(229, 244, 255), Qt::SolidPattern));
  } else {
    painter->setBrush(QBrush(QColor(242, 242, 242), Qt::SolidPattern));
  }
  painter->drawRect(rect);
  painter->setBrush(QBrush(Qt::white, Qt::SolidPattern));
  painter->drawRect(getExtentRectangle());
  if (mpModelWidget->getModelWidgetContainer()->isShowGridLines()) {
    painter->setBrush(Qt::NoBrush);
    painter->setPen(QColor(229, 229, 229));
    /* Draw left half vertical lines */
    int horizontalGridStep = mpCoOrdinateSystem->getHorizontalGridStep() * 10;
    qreal xAxisStep = 0;
    qreal yAxisStep = rect.y();
    xAxisStep -= horizontalGridStep;
    while (xAxisStep > rect.left()) {
      painter->drawLine(QPointF(xAxisStep, yAxisStep), QPointF(xAxisStep, rect.bottom()));
      xAxisStep -= horizontalGridStep;
    }
    /* Draw right half vertical lines */
    xAxisStep = 0;
    while (xAxisStep < rect.right()) {
      painter->drawLine(QPointF(xAxisStep, yAxisStep), QPointF(xAxisStep, rect.bottom()));
      xAxisStep += horizontalGridStep;
    }
    /* Draw left half horizontal lines */
    int verticalGridStep = mpCoOrdinateSystem->getVerticalGridStep() * 10;
    xAxisStep = rect.x();
    yAxisStep = 0;
    yAxisStep += verticalGridStep;
    while (yAxisStep < rect.bottom()) {
      painter->drawLine(QPointF(xAxisStep, yAxisStep), QPointF(rect.right(), yAxisStep));
      yAxisStep += verticalGridStep;
    }
    /* Draw right half horizontal lines */
    yAxisStep = 0;
    while (yAxisStep > rect.top()) {
      painter->drawLine(QPointF(xAxisStep, yAxisStep), QPointF(rect.right(), yAxisStep));
      yAxisStep -= verticalGridStep;
    }
    /* set the middle horizontal and vertical line gray */
    painter->setPen(QColor(192, 192, 192));
    painter->drawLine(QPointF(rect.left(), 0), QPointF(rect.right(), 0));
    painter->drawLine(QPointF(0, rect.top()), QPointF(0, rect.bottom()));
  }
  // draw scene rectangle
  painter->setPen(QColor(192, 192, 192));
  painter->drawRect(getExtentRectangle());
}

//! Defines what happens when clicking in a GraphicsView.
//! @param event contains information of the mouse click operation.
void GraphicsView::mousePressEvent(QMouseEvent *event)
{
  if (event->button() == Qt::RightButton) {
    return;
  }
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
  QPointF snappedPoint = snapPointToGrid(mapToScene(event->pos()));
  bool eventConsumed = false;
  // if left button presses and we are creating a connector
  if (isCreatingConnection()) {
    mpConnectionLineAnnotation->addPoint(snappedPoint);
    eventConsumed = true;
  } else if (pMainWindow->getLineShapeAction()->isChecked()) {
    /* if line shape tool button is checked then create a line */
    createLineShape(snappedPoint);
  } else if (pMainWindow->getPolygonShapeAction()->isChecked()) {
    /* if polygon shape tool button is checked then create a polygon */
    createPolygonShape(snappedPoint);
  } else if (pMainWindow->getRectangleShapeAction()->isChecked()) {
    /* if rectangle shape tool button is checked then create a rectangle */
    createRectangleShape(snappedPoint);
  } else if (pMainWindow->getEllipseShapeAction()->isChecked()) {
    /* if ellipse shape tool button is checked then create an ellipse */
    createEllipseShape(snappedPoint);
  } else if (pMainWindow->getTextShapeAction()->isChecked()) {
    /* if text shape tool button is checked then create a text */
    createTextShape(snappedPoint);
    eventConsumed = true;
  } else if (pMainWindow->getBitmapShapeAction()->isChecked()) {
    /* if bitmap shape tool button is checked then create a bitmap */
    createBitmapShape(snappedPoint);
    eventConsumed = true;
  } else if (dynamic_cast<ResizerItem*>(itemAt(event->pos()))) {
    // do nothing if resizer item is clicked. It will be handled in its class mousePressEvent();
  } else {
    // this flag is just used to have seperate identity for if statement in mouse release event of graphicsview
    setIsMovingComponentsAndShapes(true);
    // save the position of all components
    foreach (Component *pComponent, mComponentsList) {
      pComponent->setOldPosition(pComponent->pos());
      pComponent->setOldScenePosition(pComponent->scenePos());
    }
    // save the position of all shapes
    foreach (ShapeAnnotation *pShapeAnnotation, mShapesList) {
      pShapeAnnotation->setOldScenePosition(pShapeAnnotation->scenePos());
    }
  }
  // if some item is clicked
  if (itemAt(event->pos())) {
    QGraphicsItem *pGraphicsItem = itemAt(event->pos());
    if (pGraphicsItem && pGraphicsItem->parentItem()) {
      Component *pComponent = dynamic_cast<Component*>(pGraphicsItem->parentItem());
      if (pComponent && !pComponent->isSelected()) {
        if (pMainWindow->getConnectModeAction()->isChecked() && mViewType == StringHandler::Diagram &&
            pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->isConnector() &&
            !mpModelWidget->getLibraryTreeItem()->isSystemLibrary()) {
          if (!isCreatingConnection()) {
            mpClickedComponent = pComponent;
          } else if (isCreatingConnection()) {
            addConnection(pComponent);  // end the connection
            eventConsumed = true; // consume the event so that connection line or end component will not become selected
          }
        }
      }
    }
  }
  if (!eventConsumed) {
    QGraphicsView::mousePressEvent(event);
  }
}

//! Defines what happens when the mouse is moving in a GraphicsView.
//! @param event contains information of the mouse moving operation.
void GraphicsView::mouseMoveEvent(QMouseEvent *event)
{
  /* update the pointer position labels */
  Label *pPointerXPositionLabel = mpModelWidget->getModelWidgetContainer()->getMainWindow()->getPointerXPositionLabel();
  pPointerXPositionLabel->setText(QString("X: %1").arg(QString::number(mapToScene(event->pos()).x(), 'f', 2)));
  Label *pPointerYPositionLabel = mpModelWidget->getModelWidgetContainer()->getMainWindow()->getPointerYPositionLabel();
  pPointerYPositionLabel->setText(QString("Y: %1").arg(QString::number(mapToScene(event->pos()).y(), 'f', 2)));

  QPointF snappedPoint = snapPointToGrid(mapToScene(event->pos()));
  // if user mouse over connector show Qt::CrossCursor.
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
  bool setCrossCursor = false;
  if (itemAt(event->pos())) {
    QGraphicsItem *pGraphicsItem = itemAt(event->pos());
    if (pGraphicsItem && pGraphicsItem->parentItem()) {
      Component *pComponent = dynamic_cast<Component*>(pGraphicsItem->parentItem());
      if (pComponent && !pComponent->isSelected()) {
        if (pMainWindow->getConnectModeAction()->isChecked() && mViewType == StringHandler::Diagram &&
            pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->isConnector() &&
            !mpModelWidget->getLibraryTreeItem()->isSystemLibrary()) {
          setCrossCursor = true;
          /* If setOverrideCursor() has been called twice, calling restoreOverrideCursor() will activate the first cursor set.
           * Calling this function a second time restores the original widgets' cursors.
           * So we only set the cursor if it is not already Qt::CrossCursor.
           */
          if (!QApplication::overrideCursor() || QApplication::overrideCursor()->shape() != Qt::CrossCursor) {
            QApplication::setOverrideCursor(Qt::CrossCursor);
          }
        }
      }
    }
  }
  // if user mouse is not on connector then reset the cursor.
  if (!setCrossCursor && QApplication::overrideCursor()) {
    QApplication::restoreOverrideCursor();
  }
  //If creating connector, the end port shall be updated to the mouse position.
  if (isCreatingConnection()) {
    mpConnectionLineAnnotation->updateEndPoint(snappedPoint);
    mpConnectionLineAnnotation->update();
  } else if (isCreatingLineShape()) {
    mpLineShapeAnnotation->updateEndPoint(snappedPoint);
    mpLineShapeAnnotation->update();
  } else if (isCreatingPolygonShape()) {
    mpPolygonShapeAnnotation->updateEndPoint(snappedPoint);
    mpPolygonShapeAnnotation->update();
  } else if (isCreatingRectangleShape()) {
    mpRectangleShapeAnnotation->updateEndExtent(snappedPoint);
    mpRectangleShapeAnnotation->update();
  } else if (isCreatingEllipseShape()) {
    mpEllipseShapeAnnotation->updateEndExtent(snappedPoint);
    mpEllipseShapeAnnotation->update();
  } else if (isCreatingTextShape()) {
    mpTextShapeAnnotation->updateEndExtent(snappedPoint);
    mpTextShapeAnnotation->update();
  } else if (isCreatingBitmapShape()) {
    mpBitmapShapeAnnotation->updateEndExtent(snappedPoint);
    mpBitmapShapeAnnotation->update();
  } else if (mpClickedComponent) {
    addConnection(mpClickedComponent);  // start the connection
    if (mpClickedComponent) { // if we creating a connection then don't select the starting component.
      mpClickedComponent->setSelected(false);
    }
  }
  QGraphicsView::mouseMoveEvent(event);
}

void GraphicsView::mouseReleaseEvent(QMouseEvent *event)
{
  if (event->button() == Qt::RightButton) {
    return;
  }
  mpClickedComponent = 0;
  if (isMovingComponentsAndShapes()) {
    setIsMovingComponentsAndShapes(false);
    bool hasComponentMoved = false;
    bool hasShapeMoved = false;
    bool beginMacro = false;
    // if component position is really changed then update component annotation
    foreach (Component *pComponent, mComponentsList) {
      if (pComponent->getOldPosition() != pComponent->pos()) {
        if (!beginMacro) {
          mpModelWidget->getUndoStack()->beginMacro("Move items by mouse");
          beginMacro = true;
        }
        Transformation oldTransformation = pComponent->mTransformation;
        QPointF positionDifference = pComponent->scenePos() - pComponent->getOldScenePosition();
        pComponent->mTransformation.adjustPosition(positionDifference.x(), positionDifference.y());
        mpModelWidget->getUndoStack()->push(new UpdateComponentCommand(pComponent, oldTransformation, pComponent->mTransformation, this));
        hasComponentMoved = true;
      }
    }
    // if shape position is changed then update class annotation
    foreach (ShapeAnnotation *pShapeAnnotation, mShapesList) {
      if (pShapeAnnotation->getOldScenePosition() != pShapeAnnotation->scenePos()) {
        if (!beginMacro) {
          mpModelWidget->getUndoStack()->beginMacro("Move items by mouse");
          beginMacro = true;
        }
        QString oldAnnotation = pShapeAnnotation->getOMCShapeAnnotation();
        pShapeAnnotation->mTransformation.setOrigin(pShapeAnnotation->scenePos());
        bool state = pShapeAnnotation->flags().testFlag(QGraphicsItem::ItemSendsGeometryChanges);
        pShapeAnnotation->setFlag(QGraphicsItem::ItemSendsGeometryChanges, false);
        pShapeAnnotation->setPos(0, 0);
        pShapeAnnotation->setFlag(QGraphicsItem::ItemSendsGeometryChanges, state);
        pShapeAnnotation->setTransform(pShapeAnnotation->mTransformation.getTransformationMatrix());
        pShapeAnnotation->setOrigin(pShapeAnnotation->mTransformation.getPosition());
        QString newAnnotation = pShapeAnnotation->getOMCShapeAnnotation();
        mpModelWidget->getUndoStack()->push(new UpdateShapeCommand(pShapeAnnotation, oldAnnotation, newAnnotation, this));
        hasShapeMoved = true;
      }
    }
    if (hasShapeMoved) {
      addClassAnnotation(!hasComponentMoved);
    }
    if (hasComponentMoved || hasShapeMoved) {
      mpModelWidget->updateModelicaText();
      mpModelWidget->setModelModified();
    }
    // if we have started he undo stack macro then we should end it.
    if (beginMacro) {
      mpModelWidget->getUndoStack()->endMacro();
    }
  }
  QGraphicsView::mouseReleaseEvent(event);
}

void GraphicsView::mouseDoubleClickEvent(QMouseEvent *event)
{
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
  if (isCreatingLineShape()) {
    // finish creating the line
    setIsCreatingLineShape(false);
    // set the transformation matrix
    mpLineShapeAnnotation->setOrigin(mpLineShapeAnnotation->sceneBoundingRect().center());
    mpLineShapeAnnotation->adjustPointsWithOrigin();
    mpLineShapeAnnotation->initializeTransformation();
    // draw corner items for the Line shape
    mpLineShapeAnnotation->removePoint(mpLineShapeAnnotation->getPoints().size() - 1);
    mpLineShapeAnnotation->drawCornerItems();
    mpLineShapeAnnotation->setSelected(true);
    // make the toolbar button of line unchecked
    pMainWindow->getLineShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    mpModelWidget->getLibraryTreeItem()->emitShapeAdded(mpLineShapeAnnotation, this);
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
    return;
  } else if (isCreatingPolygonShape()) {
    // finish creating the polygon
    setIsCreatingPolygonShape(false);
    // set the transformation matrix
    mpPolygonShapeAnnotation->setOrigin(mpPolygonShapeAnnotation->sceneBoundingRect().center());
    mpPolygonShapeAnnotation->adjustPointsWithOrigin();
    mpPolygonShapeAnnotation->initializeTransformation();
    // draw corner items for the polygon shape
    mpPolygonShapeAnnotation->removePoint(mpPolygonShapeAnnotation->getPoints().size() - 1);
    mpPolygonShapeAnnotation->drawCornerItems();
    mpPolygonShapeAnnotation->setSelected(true);
    // make the toolbar button of polygon unchecked
    pMainWindow->getPolygonShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    mpModelWidget->getLibraryTreeItem()->emitShapeAdded(mpPolygonShapeAnnotation, this);
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
    return;
  }
  ShapeAnnotation *pShapeAnnotation = dynamic_cast<ShapeAnnotation*>(itemAt(event->pos()));
  if (pShapeAnnotation) {
    /*
      Double click on Component also end up here.
      But we don't have GraphicsView for the shapes inside the Component so we can go out of this block.
      */
    if (pShapeAnnotation->getGraphicsView()) {
      pShapeAnnotation->showShapeProperties();
      return;
    }
  }
  QGraphicsView::mouseDoubleClickEvent(event);
}

/*!
 * \brief GraphicsView::focusOutEvent
 * \param event
 */
void GraphicsView::focusOutEvent(QFocusEvent *event)
{
  // makesure we reset the Qt::CrossCursor
  if (QApplication::overrideCursor() && QApplication::overrideCursor()->shape() == Qt::CrossCursor) {
    QApplication::restoreOverrideCursor();
  }
  QGraphicsView::focusOutEvent(event);
}

void GraphicsView::keyPressEvent(QKeyEvent *event)
{
  bool shiftModifier = event->modifiers().testFlag(Qt::ShiftModifier);
  bool controlModifier = event->modifiers().testFlag(Qt::ControlModifier);
  if (event->key() == Qt::Key_Delete && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->getUndoStack()->beginMacro("Deleting by key press");
    emit keyPressDelete();
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
    mpModelWidget->getUndoStack()->endMacro();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Up && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->getUndoStack()->beginMacro("Move up by key press");
    emit keyPressUp();
    mpModelWidget->getUndoStack()->endMacro();
  } else if (shiftModifier && !controlModifier && event->key() == Qt::Key_Up && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->getUndoStack()->beginMacro("Move shift up by key press");
    emit keyPressShiftUp();
    mpModelWidget->getUndoStack()->endMacro();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_Up && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->getUndoStack()->beginMacro("Move control up by key press");
    emit keyPressCtrlUp();
    mpModelWidget->getUndoStack()->endMacro();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Down && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->getUndoStack()->beginMacro("Move down by key press");
    emit keyPressDown();
    mpModelWidget->getUndoStack()->endMacro();
  } else if (shiftModifier && !controlModifier && event->key() == Qt::Key_Down && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->getUndoStack()->beginMacro("Move shift down by key press");
    emit keyPressShiftDown();
    mpModelWidget->getUndoStack()->endMacro();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_Down && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->getUndoStack()->beginMacro("Move control down by key press");
    emit keyPressCtrlDown();
    mpModelWidget->getUndoStack()->endMacro();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Left && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->getUndoStack()->beginMacro("Move left by key press");
    emit keyPressLeft();
    mpModelWidget->getUndoStack()->endMacro();
  } else if (shiftModifier && !controlModifier && event->key() == Qt::Key_Left && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->getUndoStack()->beginMacro("Move shift left by key press");
    emit keyPressShiftLeft();
    mpModelWidget->getUndoStack()->endMacro();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_Left && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->getUndoStack()->beginMacro("Move control left by key press");
    emit keyPressCtrlLeft();
    mpModelWidget->getUndoStack()->endMacro();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Right && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->getUndoStack()->beginMacro("Move right by key press");
    emit keyPressRight();
    mpModelWidget->getUndoStack()->endMacro();
  } else if (shiftModifier && !controlModifier && event->key() == Qt::Key_Right && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->getUndoStack()->beginMacro("Move shift right by key press");
    emit keyPressShiftRight();
    mpModelWidget->getUndoStack()->endMacro();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_Right && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->getUndoStack()->beginMacro("Move control right by key press");
    emit keyPressCtrlRight();
    mpModelWidget->getUndoStack()->endMacro();
  } else if (controlModifier && event->key() == Qt::Key_A) {
    selectAll();
  } else if (controlModifier && event->key() == Qt::Key_D) {
    emit keyPressDuplicate();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_R && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->getUndoStack()->beginMacro("Rotate clockwise by key press");
    emit keyPressRotateClockwise();
    mpModelWidget->getUndoStack()->endMacro();
  } else if (shiftModifier && controlModifier && event->key() == Qt::Key_R && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->getUndoStack()->beginMacro("Rotate anti clockwise by key press");
    emit keyPressRotateAntiClockwise();
    mpModelWidget->getUndoStack()->endMacro();
  } else if (event->key() == Qt::Key_Escape && isCreatingConnection()) {
    removeCurrentConnection();
  } else {
    QGraphicsView::keyPressEvent(event);
  }
}

//! Defines what shall happen when a key is released.
//! @param event contains information about the keypress operation.
void GraphicsView::keyReleaseEvent(QKeyEvent *event)
{
  /* if user has pressed and hold the key. */
  if (event->isAutoRepeat()) {
    return QGraphicsView::keyReleaseEvent(event);
  }
  bool shiftModifier = event->modifiers().testFlag(Qt::ShiftModifier);
  bool controlModifier = event->modifiers().testFlag(Qt::ControlModifier);
  /* handle keys */
  if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Up && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
  } else if (shiftModifier && !controlModifier && event->key() == Qt::Key_Up && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_Up && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Down && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
  } else if (shiftModifier && !controlModifier && event->key() == Qt::Key_Down && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_Down && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Left && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
  } else if (shiftModifier && !controlModifier && event->key() == Qt::Key_Left && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_Left && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Right && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
  } else if (shiftModifier && !controlModifier && event->key() == Qt::Key_Right && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_Right && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_R && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
  } else if (shiftModifier && controlModifier && event->key() == Qt::Key_R && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelicaText();
  } else {
    QGraphicsView::keyReleaseEvent(event);
  }
}

void GraphicsView::contextMenuEvent(QContextMenuEvent *event)
{
  /* If we are creating the connection OR creating any shape then don't show context menu */
  if (isCreatingConnection() ||
      isCreatingLineShape() ||
      isCreatingPolygonShape() ||
      isCreatingRectangleShape() ||
      isCreatingEllipseShape() ||
      isCreatingTextShape()) {
    return;
  }
  // if some item is right clicked then don't show graphics view context menu
  if (!itemAt(event->pos())) {
    QMenu menu(mpModelWidget->getModelWidgetContainer()->getMainWindow());
    menu.addAction(mpModelWidget->getModelWidgetContainer()->getMainWindow()->getExportAsImageAction());
    menu.addAction(mpModelWidget->getModelWidgetContainer()->getMainWindow()->getExportToClipboardAction());
    menu.addSeparator();
    menu.addAction(mpModelWidget->getModelWidgetContainer()->getMainWindow()->getExportToOMNotebookAction());
    menu.addSeparator();
    menu.addAction(mpModelWidget->getModelWidgetContainer()->getMainWindow()->getPrintModelAction());
    menu.addSeparator();
    menu.addAction(mpPropertiesAction);
    menu.exec(event->globalPos());
    return;         // return from it because at a time we only want one context menu.
  }
  QGraphicsView::contextMenuEvent(event);
}

void GraphicsView::resizeEvent(QResizeEvent *event)
{
  // only resize the view if user has not set any custom scaling like zoom in and zoom out.
  if (!isCustomScale()) {
    // make the fitInView rectangle bigger so that the scene rectangle will show up properly on the screen.
    QRectF extentRectangle = getExtentRectangle();
    qreal x1, y1, x2, y2;
    extentRectangle.getCoords(&x1, &y1, &x2, &y2);
    extentRectangle.setCoords(x1 -5, y1 -5, x2 + 5, y2 + 5);
    fitInView(extentRectangle, Qt::KeepAspectRatio);
  }
  QGraphicsView::resizeEvent(event);
}

/*!
  Reimplementation of QGraphicsView::wheelEvent.
  */
void GraphicsView::wheelEvent(QWheelEvent *event)
{
  int numDegrees = event->delta() / 8;
  int numSteps = numDegrees * 3;
  bool controlModifier = event->modifiers().testFlag(Qt::ControlModifier);
  bool shiftModifier = event->modifiers().testFlag(Qt::ShiftModifier);
  // If Ctrl key is pressed and user has scrolled vertically then Zoom In/Out based on the scroll distance.
  if (event->orientation() == Qt::Vertical && controlModifier) {
    if (event->delta() > 0) {
      zoomIn();
    } else {
      zoomOut();
    }
  } else if ((event->orientation() == Qt::Horizontal) || (event->orientation() == Qt::Vertical && shiftModifier)) {
    // If Shift key is pressed and user has scrolled vertically then scroll the horizontal scrollbars.
    // If user has scrolled horizontally then scroll the horizontal scrollbars.
    horizontalScrollBar()->setValue(horizontalScrollBar()->value() - numSteps);
  } else if (event->orientation() == Qt::Vertical) {
    // If user has scrolled vertically then scroll the vertical scrollbars.
    verticalScrollBar()->setValue(verticalScrollBar()->value() - numSteps);
  } else {
    QGraphicsView::wheelEvent(event);
  }
}

WelcomePageWidget::WelcomePageWidget(MainWindow *parent)
  : QWidget(parent)
{
  setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
  mpMainWindow = parent;
  // main frame
  mpMainFrame = new QFrame;
  mpMainFrame->setContentsMargins(0, 0, 0, 0);
  mpMainFrame->setStyleSheet("QFrame{color:gray;}");
  // top frame
  mpTopFrame = new QFrame;
  mpTopFrame->setMaximumHeight(95);
  mpTopFrame->setStyleSheet("QFrame{background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #828282, stop: 1 #5e5e5e);}");
  // top frame pixmap
  mpPixmapLabel = new Label;
  QPixmap pixmap(":/Resources/icons/omedit.png");
  mpPixmapLabel->setPixmap(pixmap.scaled(75, 72, Qt::KeepAspectRatio, Qt::SmoothTransformation));
  mpPixmapLabel->setStyleSheet("background-color : transparent;");
  // top frame heading
  mpHeadingLabel = new Label(QString(Helper::applicationName).append(" - ").append(Helper::applicationIntroText));
  mpHeadingLabel->setFont(QFont(Helper::systemFontInfo.family(), Helper::headingFontSize));
  mpHeadingLabel->setStyleSheet("background-color : transparent; color : white;");
#ifndef Q_OS_MAC
  mpHeadingLabel->setGraphicsEffect(new QGraphicsDropShadowEffect);
#endif
  // top frame layout
  QHBoxLayout *topFrameLayout = new QHBoxLayout;
  topFrameLayout->setAlignment(Qt::AlignLeft);
  topFrameLayout->addWidget(mpPixmapLabel);
  topFrameLayout->addWidget(mpHeadingLabel);
  mpTopFrame->setLayout(topFrameLayout);
  // RecentFiles Frame
  mpRecentFilesFrame = new QFrame;
  mpRecentFilesFrame->setFrameShape(QFrame::StyledPanel);
  mpRecentFilesFrame->setStyleSheet("QFrame{background-color: white;}");
  // recent items list
  mpRecentFilesLabel = new Label(tr("Recent Files"));
  mpRecentFilesLabel->setFont(QFont(Helper::systemFontInfo.family(), Helper::headingFontSize));
  mpNoRecentFileLabel = new Label(tr("No recent files found."));
  mpRecentItemsList = new QListWidget;
  mpRecentItemsList->setObjectName("RecentItemsList");
  mpRecentItemsList->setContentsMargins(0, 0, 0, 0);
  mpRecentItemsList->setSpacing(5);
  mpRecentItemsList->setFrameStyle(QFrame::NoFrame);
  mpRecentItemsList->setViewMode(QListView::ListMode);
  mpRecentItemsList->setMovement(QListView::Static);
  mpRecentItemsList->setIconSize(Helper::iconSize);
  mpRecentItemsList->setCurrentRow(0, QItemSelectionModel::Select);
  connect(mpRecentItemsList, SIGNAL(itemClicked(QListWidgetItem*)), SLOT(openRecentFileItem(QListWidgetItem*)));
  mpClearRecentFilesListButton = new QPushButton(tr("Clear Recent Files"));
  mpClearRecentFilesListButton->setStyleSheet("QPushButton{padding: 5px 15px 5px 15px;}");
  connect(mpClearRecentFilesListButton, SIGNAL(clicked()), mpMainWindow, SLOT(clearRecentFilesList()));
  // RecentFiles Frame layout
  QVBoxLayout *recentFilesFrameVBLayout = new QVBoxLayout;
  recentFilesFrameVBLayout->addWidget(mpRecentFilesLabel);
  recentFilesFrameVBLayout->addWidget(mpNoRecentFileLabel);
  recentFilesFrameVBLayout->addWidget(mpRecentItemsList);
  QHBoxLayout *recentFilesHBLayout = new QHBoxLayout;
  recentFilesHBLayout->addWidget(mpClearRecentFilesListButton, 0, Qt::AlignLeft);
  recentFilesFrameVBLayout->addLayout(recentFilesHBLayout);
  mpRecentFilesFrame->setLayout(recentFilesFrameVBLayout);
  // LatestNews Frame
  mpLatestNewsFrame = new QFrame;
  mpLatestNewsFrame->setFrameShape(QFrame::StyledPanel);
  mpLatestNewsFrame->setStyleSheet("QFrame{background-color: white;}");
  /* Read the show latest news settings */
  if (!mpMainWindow->getOptionsDialog()->getGeneralSettingsPage()->getShowLatestNewsCheckBox()->isChecked())
    mpLatestNewsFrame->setVisible(false);
  // latest news
  mpLatestNewsLabel = new Label(tr("Latest News"));
  mpLatestNewsLabel->setFont(QFont(Helper::systemFontInfo.family(), Helper::headingFontSize));
  mpNoLatestNewsLabel = new Label;
  mpLatestNewsListWidget = new QListWidget;
  mpLatestNewsListWidget->setObjectName("LatestNewsList");
  mpLatestNewsListWidget->setContentsMargins(0, 0, 0, 0);
  mpLatestNewsListWidget->setSpacing(5);
  mpLatestNewsListWidget->setFrameStyle(QFrame::NoFrame);
  mpLatestNewsListWidget->setViewMode(QListView::ListMode);
  mpLatestNewsListWidget->setMovement(QListView::Static);
  mpLatestNewsListWidget->setIconSize(Helper::iconSize);
  mpLatestNewsListWidget->setCurrentRow(0, QItemSelectionModel::Select);
  mpReloadLatestNewsButton = new QPushButton(Helper::reload);
  mpReloadLatestNewsButton->setStyleSheet("QPushButton{padding: 5px 15px 5px 15px;}");
  connect(mpReloadLatestNewsButton, SIGNAL(clicked()), SLOT(addLatestNewsListItems()));
  mpVisitWebsiteLabel = new Label(tr("For more details visit our website <u><a href=\"http://www.openmodelica.org\">www.openmodelica.org</a></u>"));
  mpVisitWebsiteLabel->setTextFormat(Qt::RichText);
  mpVisitWebsiteLabel->setTextInteractionFlags(mpVisitWebsiteLabel->textInteractionFlags() | Qt::LinksAccessibleByMouse | Qt::LinksAccessibleByKeyboard);
  mpVisitWebsiteLabel->setOpenExternalLinks(true);
  connect(mpLatestNewsListWidget, SIGNAL(itemClicked(QListWidgetItem*)), SLOT(openLatestNewsItem(QListWidgetItem*)));
  // Latest News Frame layout
  QVBoxLayout *latestNewsFrameVBLayout = new QVBoxLayout;
  latestNewsFrameVBLayout->addWidget(mpLatestNewsLabel);
  latestNewsFrameVBLayout->addWidget(mpNoLatestNewsLabel);
  latestNewsFrameVBLayout->addWidget(mpLatestNewsListWidget);
  QHBoxLayout *latestNewsFrameHBLayout = new QHBoxLayout;
  latestNewsFrameHBLayout->addWidget(mpReloadLatestNewsButton, 0, Qt::AlignLeft);
  latestNewsFrameHBLayout->addWidget(mpVisitWebsiteLabel, 0, Qt::AlignRight);
  latestNewsFrameVBLayout->addLayout(latestNewsFrameHBLayout);
  mpLatestNewsFrame->setLayout(latestNewsFrameVBLayout);
  // create http object for request
  mpLatestNewsNetworkAccessManager = new QNetworkAccessManager;
  connect(mpLatestNewsNetworkAccessManager, SIGNAL(finished(QNetworkReply*)), SLOT(readLatestNewsXML(QNetworkReply*)));
  addLatestNewsListItems();
  // splitter
  mpSplitter = new QSplitter;
  /* Read the welcome page view settings */
  switch (mpMainWindow->getOptionsDialog()->getGeneralSettingsPage()->getWelcomePageView())
  {
    case 2:
      mpSplitter->setOrientation(Qt::Vertical);
      break;
    case 1:
    default:
      mpSplitter->setOrientation(Qt::Horizontal);
      break;
  }
  mpSplitter->setChildrenCollapsible(false);
  mpSplitter->setHandleWidth(4);
  mpSplitter->setContentsMargins(0, 0, 0, 0);
  mpSplitter->addWidget(mpRecentFilesFrame);
  mpSplitter->addWidget(mpLatestNewsFrame);
  // bottom frame
  mpBottomFrame = new QFrame;
  mpBottomFrame->setMaximumHeight(50);
  mpBottomFrame->setStyleSheet("QFrame{background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #828282, stop: 1 #5e5e5e);}");
  // bottom frame create and open buttons buttons
  mpCreateModelButton = new QPushButton(Helper::createNewModelicaClass);
  mpCreateModelButton->setStyleSheet("QPushButton{padding: 5px 15px 5px 15px;}");
  connect(mpCreateModelButton, SIGNAL(clicked()), mpMainWindow, SLOT(createNewModelicaClass()));
  mpOpenModelButton = new QPushButton(Helper::openModelicaFiles);
  mpOpenModelButton->setStyleSheet("QPushButton{padding: 5px 15px 5px 15px;}");
  connect(mpOpenModelButton, SIGNAL(clicked()), mpMainWindow, SLOT(openModelicaFile()));
  // bottom frame layout
  QHBoxLayout *bottomFrameLayout = new QHBoxLayout;
  bottomFrameLayout->addWidget(mpCreateModelButton, 0, Qt::AlignLeft);
  bottomFrameLayout->addWidget(mpOpenModelButton, 0, Qt::AlignRight);
  mpBottomFrame->setLayout(bottomFrameLayout);
  // vertical layout for frames
  QVBoxLayout *verticalLayout = new QVBoxLayout;
  verticalLayout->setSpacing(4);
  verticalLayout->setContentsMargins(0, 0, 0, 0);
  verticalLayout->addWidget(mpTopFrame);
  verticalLayout->addWidget(mpSplitter);
  verticalLayout->addWidget(mpBottomFrame);
  // main frame layout
  mpMainFrame->setLayout(verticalLayout);
  QHBoxLayout *layout = new QHBoxLayout;
  layout->setContentsMargins(0, 0, 0, 0);
  layout->addWidget(mpMainFrame);
  setLayout(layout);
}

void WelcomePageWidget::addRecentFilesListItems()
{
  // remove list items first
  mpRecentItemsList->clear();
  QSettings *pSettings = OpenModelica::getApplicationSettings();
  QList<QVariant> files = pSettings->value("recentFilesList/files").toList();
  int numRecentFiles = qMin(files.size(), (int)mpMainWindow->MaxRecentFiles);
  for (int i = 0; i < numRecentFiles; ++i)
  {
    RecentFile recentFile = qvariant_cast<RecentFile>(files[i]);
    QListWidgetItem *listItem = new QListWidgetItem(mpRecentItemsList);
    listItem->setIcon(QIcon(":/Resources/icons/next.svg"));
    listItem->setText(recentFile.fileName);
    listItem->setData(Qt::UserRole, recentFile.encoding);
  }
  if (files.size() > 0)
    mpNoRecentFileLabel->setVisible(false);
  else
    mpNoRecentFileLabel->setVisible(true);
}

QFrame* WelcomePageWidget::getLatestNewsFrame()
{
  return mpLatestNewsFrame;
}

QSplitter* WelcomePageWidget::getSplitter()
{
  return mpSplitter;
}

void WelcomePageWidget::addLatestNewsListItems()
{
  mpLatestNewsListWidget->clear();
  /* if show latest news settings is not set then don't fetch the latest news items. */
  if (mpMainWindow->getOptionsDialog()->getGeneralSettingsPage()->getShowLatestNewsCheckBox()->isChecked())
  {
    QUrl newsUrl("https://openmodelica.org/index.php?option=com_content&view=category&id=23&format=feed&amp;type=rss");
    QNetworkReply *pNetworkReply = mpLatestNewsNetworkAccessManager->get(QNetworkRequest(newsUrl));
    pNetworkReply->ignoreSslErrors();
  }
}

void WelcomePageWidget::readLatestNewsXML(QNetworkReply *pNetworkReply)
{
  if (pNetworkReply->error() == QNetworkReply::HostNotFoundError)
  {
    mpNoLatestNewsLabel->setVisible(true);
    mpNoLatestNewsLabel->setText(tr("Sorry, no internet no news items."));
  }
  else if (pNetworkReply->error() == QNetworkReply::NoError)
  {
    QByteArray response(pNetworkReply->readAll());
    QXmlStreamReader xml(response);
    int count = 0;
    QString title, link;
    while (!xml.atEnd())
    {
      mpNoLatestNewsLabel->setVisible(false);
      xml.readNext();
      if (xml.tokenType() == QXmlStreamReader::StartElement)
      {
        if (xml.name() == "item")
        {
          while (!xml.atEnd())
          {
            xml.readNext();
            if (xml.tokenType() == QXmlStreamReader::StartElement)
            {
              if (xml.name() == "title")
                title = xml.readElementText();
              if (xml.name() == "link")
              {
                link = xml.readElementText();
                if (count >= (int)mpMainWindow->MaxRecentFiles)
                  break;
                count++;
                QListWidgetItem *listItem = new QListWidgetItem(mpLatestNewsListWidget);
                listItem->setIcon(QIcon(":/Resources/icons/next.svg"));
                listItem->setText(title);
                listItem->setData(Qt::UserRole, link);
                break;
              }
            }
          }
        }
      }
      if (count >= (int)mpMainWindow->MaxRecentFiles)
        break;
    }
  }
  else
  {
    mpNoLatestNewsLabel->setVisible(true);
    mpNoLatestNewsLabel->setText(QString(Helper::error).append(" - ").append(pNetworkReply->errorString()));
  }
}

void WelcomePageWidget::openRecentFileItem(QListWidgetItem *pItem)
{
  mpMainWindow->getLibraryWidget()->openFile(pItem->text(), pItem->data(Qt::UserRole).toString(), true, true);
}

void WelcomePageWidget::openLatestNewsItem(QListWidgetItem *pItem)
{
  QUrl url(pItem->data(Qt::UserRole).toString());
  QDesktopServices::openUrl(url);
}

ModelWidget::ModelWidget(LibraryTreeItem* pLibraryTreeItem, ModelWidgetContainer *pModelWidgetContainer, QString text)
  : QWidget(pModelWidgetContainer), mpModelWidgetContainer(pModelWidgetContainer), mpLibraryTreeItem(pLibraryTreeItem),
    mloadWidgetComponents(false), mReloadNeeded(false)
{
  // create widgets based on library type
  if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
    // icon graphics framework
    mpIconGraphicsScene = new GraphicsScene(StringHandler::Icon, this);
    mpIconGraphicsView = new GraphicsView(StringHandler::Icon, this);
    mpIconGraphicsView->setScene(mpIconGraphicsScene);
    mpIconGraphicsView->hide();
    // diagram graphics framework
    mpDiagramGraphicsScene = new GraphicsScene(StringHandler::Diagram, this);
    mpDiagramGraphicsView = new GraphicsView(StringHandler::Diagram, this);
    mpDiagramGraphicsView->setScene(mpDiagramGraphicsScene);
    mpDiagramGraphicsView->hide();
    // Undo stack for model
    mpUndoStack = new QUndoStack;
    connect(mpUndoStack, SIGNAL(canUndoChanged(bool)), SLOT(handleCanUndoChanged(bool)));
    connect(mpUndoStack, SIGNAL(canRedoChanged(bool)), SLOT(handleCanRedoChanged(bool)));
    mpUndoView = new QUndoView(mpUndoStack);
    loadModelWidget();
    mpEditor = 0;
  } else {
    // icon graphics framework
    mpIconGraphicsScene = 0;
    mpIconGraphicsView = 0;
    // diagram graphics framework
    mpDiagramGraphicsScene = 0;
    mpDiagramGraphicsView = 0;
    // undo stack for model
    mpUndoStack = 0;
    mpUndoView = 0;
    mpEditor = 0;
  }
  // store the text of LibraryTreeItem::Text
  if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Text && mpLibraryTreeItem->getFileName().isEmpty()) {
    mpLibraryTreeItem->setClassText(text);
  }
}

void ModelWidget::loadModelWidget()
{
  if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
    mpLibraryTreeItem->removeAllInheritedClasses();
    mpIconGraphicsView->removeAllShapes();
    mpIconGraphicsView->removeAllComponents();
    mpIconGraphicsView->removeAllConnections();
    mpIconGraphicsView->scene()->clear();
    mpDiagramGraphicsView->removeAllShapes();
    mpDiagramGraphicsView->removeAllComponents();
    mpDiagramGraphicsView->removeAllConnections();
    mpDiagramGraphicsView->scene()->clear();
    getModelInheritedClasses(mpLibraryTreeItem);
    drawModelInheritedClasses();
    getModelIconDiagramShapes();
    drawModelInheritedComponents();
    getModelComponents();
    drawModelInheritedConnections();
    getModelConnections();
    mpUndoStack->clear();
    if (mloadWidgetComponents) {
      // set Project Status Bar lables
      mpReadOnlyLabel->setText(mpLibraryTreeItem->isReadOnly() ? Helper::readOnly : tr("Writable"));
      setModelFilePathLabel(mpLibraryTreeItem->getFileName());
      // documentation view tool button
      mpFileLockToolButton->setIcon(QIcon(mpLibraryTreeItem->isReadOnly() ? ":/Resources/icons/lock.svg" : ":/Resources/icons/unlock.svg"));
      mpFileLockToolButton->setText(mpLibraryTreeItem->isReadOnly() ? tr("Make writable") : tr("File is writable"));
      mpFileLockToolButton->setToolTip(mpFileLockToolButton->text());
      mpFileLockToolButton->setEnabled(mpLibraryTreeItem->isReadOnly() && !mpLibraryTreeItem->isSystemLibrary());
      mpModelicaTypeLabel->setText(StringHandler::getModelicaClassType(mpLibraryTreeItem->getRestriction()));
      // modelica text editor
      ModelicaTextEditor *pModelicaTextEditor = dynamic_cast<ModelicaTextEditor*>(mpEditor);
      pModelicaTextEditor->setPlainText(mpLibraryTreeItem->getClassText());
    }
  }
}

void ModelWidget::addInheritedClass(LibraryTreeItem *pLibraryTreeItem)
{
  foreach (InheritedClass *pInheritedClass, mInheritedClassesList) {
    if (pInheritedClass->mpLibraryTreeItem->getNameStructure().compare(pLibraryTreeItem->getNameStructure()) == 0) {
      removeInheritedClass(pInheritedClass);
      break;
    }
  }
  mInheritedClassesList.append(new InheritedClass(pLibraryTreeItem));
}

ModelWidget::InheritedClass* ModelWidget::findInheritedClass(LibraryTreeItem *pLibraryTreeItem)
{
  foreach (InheritedClass *pInheritedClass, mInheritedClassesList) {
    if (pInheritedClass->mpLibraryTreeItem->getNameStructure().compare(pLibraryTreeItem->getNameStructure()) == 0) {
      return pInheritedClass;
    }
  }
  return 0;
}

/*!
 * \brief ModelWidget::setModelModified
 * Sets the model state to modified. Adds a trailing * to model name and also mark it as not saved.
 */
void ModelWidget::setModelModified()
{
  // Add a * in the model window title.
  setWindowTitle(QString(mpLibraryTreeItem->getNameStructure()).append("*"));
  // set the library node not saved.
  mpLibraryTreeItem->setIsSaved(false);
  LibraryTreeModel *pLibraryTreeModel = mpModelWidgetContainer->getMainWindow()->getLibraryWidget()->getLibraryTreeModel();
  pLibraryTreeModel->updateLibraryTreeItem(mpLibraryTreeItem);
}

/*!
 * \brief ModelWidget::modelInheritedClassLoaded
 * Adds the inherited class shapes when it is loaded.
 * \param pInheritedClass
 */
void ModelWidget::modelInheritedClassLoaded(InheritedClass *pInheritedClass)
{
  MainWindow *pMainWindow = mpModelWidgetContainer->getMainWindow();
  if (!pInheritedClass->mpLibraryTreeItem->getModelWidget() || pInheritedClass->mpLibraryTreeItem->getModelWidget()->isReloadNeeded()) {
    pMainWindow->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pInheritedClass->mpLibraryTreeItem, "", false);
  }
  drawModelInheritedClassShapes(pInheritedClass, StringHandler::Icon);
  drawModelInheritedClassShapes(pInheritedClass, StringHandler::Diagram);
  drawModelInheritedClassComponents(pInheritedClass);
  drawModelInheritedClassConnections(pInheritedClass);
  mpIconGraphicsView->reOrderItems();
  mpDiagramGraphicsView->reOrderItems();
}

/*!
 * \brief ModelWidget::modelInheritedClassUnLoaded
 * Handles the case when inherited class is unloaded.
 * \param pInheritedClass
 */
void ModelWidget::modelInheritedClassUnLoaded(InheritedClass *pInheritedClass)
{
  drawModelInheritedClassShapes(pInheritedClass, StringHandler::Icon);
  drawModelInheritedClassShapes(pInheritedClass, StringHandler::Diagram);
  removeInheritedClassComponents(pInheritedClass);
  removeInheritedClassConnections(pInheritedClass);
  //! @note Do we really need to call GraphicsView::reOrderItems() here?
}

/*!
 * \brief ModelWidget::createNonExistingInheritedShape
 * Creates a red cross for non-existing inherited class shape.
 * \param pGraphicsView
 * \return
 */
ShapeAnnotation* ModelWidget::createNonExistingInheritedShape(GraphicsView *pGraphicsView)
{
  LineAnnotation *pLineAnnotation = new LineAnnotation(pGraphicsView);
  pLineAnnotation->initializeTransformation();
  pLineAnnotation->drawCornerItems();
  pLineAnnotation->setCornerItemsActiveOrPassive();
  return pLineAnnotation;
}

/*!
 * \brief ModelWidget::createInheritedShape
 * Creates the inherited class shape.
 * \param pShapeAnnotation
 * \param pGraphicsView
 * \return
 */
ShapeAnnotation* ModelWidget::createInheritedShape(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView)
{
  if (dynamic_cast<LineAnnotation*>(pShapeAnnotation)) {
    LineAnnotation *pLineAnnotation = new LineAnnotation(pShapeAnnotation, pGraphicsView);
    pLineAnnotation->initializeTransformation();
    pLineAnnotation->drawCornerItems();
    pLineAnnotation->setCornerItemsActiveOrPassive();
    return pLineAnnotation;
  } else if (dynamic_cast<PolygonAnnotation*>(pShapeAnnotation)) {
    PolygonAnnotation *pPolygonAnnotation = new PolygonAnnotation(pShapeAnnotation, pGraphicsView);
    pPolygonAnnotation->initializeTransformation();
    pPolygonAnnotation->drawCornerItems();
    pPolygonAnnotation->setCornerItemsActiveOrPassive();
    return pPolygonAnnotation;
  } else if (dynamic_cast<RectangleAnnotation*>(pShapeAnnotation)) {
    RectangleAnnotation *pRectangleAnnotation = new RectangleAnnotation(pShapeAnnotation, pGraphicsView);
    pRectangleAnnotation->initializeTransformation();
    pRectangleAnnotation->drawCornerItems();
    pRectangleAnnotation->setCornerItemsActiveOrPassive();
    return pRectangleAnnotation;
  } else if (dynamic_cast<EllipseAnnotation*>(pShapeAnnotation)) {
    EllipseAnnotation *pEllipseAnnotation = new EllipseAnnotation(pShapeAnnotation, pGraphicsView);
    pEllipseAnnotation->initializeTransformation();
    pEllipseAnnotation->drawCornerItems();
    pEllipseAnnotation->setCornerItemsActiveOrPassive();
    return pEllipseAnnotation;
  } else if (dynamic_cast<TextAnnotation*>(pShapeAnnotation)) {
    TextAnnotation *pTextAnnotation = new TextAnnotation(pShapeAnnotation, pGraphicsView);
    pTextAnnotation->initializeTransformation();
    pTextAnnotation->drawCornerItems();
    pTextAnnotation->setCornerItemsActiveOrPassive();
    return pTextAnnotation;
  } else if (dynamic_cast<BitmapAnnotation*>(pShapeAnnotation)) {
    BitmapAnnotation *pBitmapAnnotation = new BitmapAnnotation(pShapeAnnotation, pGraphicsView);
    pBitmapAnnotation->initializeTransformation();
    pBitmapAnnotation->drawCornerItems();
    pBitmapAnnotation->setCornerItemsActiveOrPassive();
    return pBitmapAnnotation;
  }
  return 0;
}

/*!
 * \brief ModelWidget::createInheritedComponent
 * Creates the inherited component.
 * \param pComponent
 * \param pGraphicsView
 * \return
 */
Component* ModelWidget::createInheritedComponent(Component *pComponent, GraphicsView *pGraphicsView)
{
  return new Component(pComponent, pGraphicsView);
}

/*!
 * \brief ModelWidget::createInheritedConnection
 * Creates the inherited connection.
 * \param pConnectionLineAnnotation
 * \return
 */
LineAnnotation* ModelWidget::createInheritedConnection(LineAnnotation *pConnectionLineAnnotation, LibraryTreeItem *pInheritedLibraryTreeItem)
{
  LineAnnotation *pInheritedConnectionLineAnnotation = new LineAnnotation(pConnectionLineAnnotation, mpDiagramGraphicsView);
  pInheritedConnectionLineAnnotation->setToolTip(QString("<b>connect</b>(%1, %2)<br /><br />%3 %4")
                                                 .arg(pInheritedConnectionLineAnnotation->getStartComponentName())
                                                 .arg(pInheritedConnectionLineAnnotation->getEndComponentName())
                                                 .arg(tr("Connection declared in"))
                                                 .arg(pInheritedLibraryTreeItem->getNameStructure()));
  pInheritedConnectionLineAnnotation->drawCornerItems();
  pInheritedConnectionLineAnnotation->setCornerItemsActiveOrPassive();
  // Add the start component connection details.
  Component *pStartComponent = pInheritedConnectionLineAnnotation->getStartComponent();
  if (pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->addConnectionDetails(pInheritedConnectionLineAnnotation);
  } else {
    pStartComponent->addConnectionDetails(pInheritedConnectionLineAnnotation);
  }
  // Add the end component connection details.
  Component *pEndComponent = pInheritedConnectionLineAnnotation->getEndComponent();
  if (pEndComponent->getParentComponent()) {
    pEndComponent->getParentComponent()->addConnectionDetails(pInheritedConnectionLineAnnotation);
  } else {
    pEndComponent->addConnectionDetails(pInheritedConnectionLineAnnotation);
  }
  return pInheritedConnectionLineAnnotation;
}

/*!
 * \brief ModelWidget::loadWidgetComponents
 * Creates the widgets for the ModelWidget.
 */
void ModelWidget::createWidgetComponents()
{
  if (!mloadWidgetComponents) {
    // icon view tool button
    mpIconViewToolButton = new QToolButton;
    mpIconViewToolButton->setText(Helper::iconView);
    mpIconViewToolButton->setIcon(QIcon(":/Resources/icons/model.svg"));
    mpIconViewToolButton->setIconSize(Helper::buttonIconSize);
    mpIconViewToolButton->setToolTip(Helper::iconView);
    mpIconViewToolButton->setAutoRaise(true);
    mpIconViewToolButton->setCheckable(true);
    // diagram view tool button
    mpDiagramViewToolButton = new QToolButton;
    mpDiagramViewToolButton->setText(Helper::diagramView);
    mpDiagramViewToolButton->setIcon(QIcon(":/Resources/icons/modeling.png"));
    mpDiagramViewToolButton->setIconSize(Helper::buttonIconSize);
    mpDiagramViewToolButton->setToolTip(Helper::diagramView);
    mpDiagramViewToolButton->setAutoRaise(true);
    mpDiagramViewToolButton->setCheckable(true);
    // modelica text view tool button
    mpTextViewToolButton = new QToolButton;
    mpTextViewToolButton->setText(Helper::textView);
    mpTextViewToolButton->setIcon(QIcon(":/Resources/icons/modeltext.svg"));
    mpTextViewToolButton->setIconSize(Helper::buttonIconSize);
    mpTextViewToolButton->setToolTip(Helper::textView);
    mpTextViewToolButton->setAutoRaise(true);
    mpTextViewToolButton->setCheckable(true);
    // documentation view tool button
    mpDocumentationViewToolButton = new QToolButton;
    mpDocumentationViewToolButton->setText(Helper::documentationView);
    mpDocumentationViewToolButton->setIcon(QIcon(":/Resources/icons/info-icon.svg"));
    mpDocumentationViewToolButton->setIconSize(Helper::buttonIconSize);
    mpDocumentationViewToolButton->setToolTip(Helper::documentationView);
    mpDocumentationViewToolButton->setAutoRaise(true);
    // view buttons box
    mpViewsButtonGroup = new QButtonGroup;
    mpViewsButtonGroup->setExclusive(true);
    mpViewsButtonGroup->addButton(mpDiagramViewToolButton);
    mpViewsButtonGroup->addButton(mpIconViewToolButton);
    mpViewsButtonGroup->addButton(mpTextViewToolButton);
    mpViewsButtonGroup->addButton(mpDocumentationViewToolButton);
    // frame to contain view buttons
    QFrame *pViewButtonsFrame = new QFrame;
    QHBoxLayout *pViewButtonsHorizontalLayout = new QHBoxLayout;
    pViewButtonsHorizontalLayout->setContentsMargins(0, 0, 0, 0);
    pViewButtonsHorizontalLayout->setSpacing(0);
    pViewButtonsFrame->setLayout(pViewButtonsHorizontalLayout);
    // set Project Status Bar lables
    mpReadOnlyLabel = mpLibraryTreeItem->isReadOnly() ? new Label(Helper::readOnly) : new Label(tr("Writable"));
    mpModelicaTypeLabel = new Label;
    mpViewTypeLabel = new Label;
    mpModelFilePathLabel = new Label(mpLibraryTreeItem->getFileName());
    mpModelFilePathLabel->setElideMode(Qt::ElideMiddle);
    mpCursorPositionLabel = new Label;
    // documentation view tool button
    mpFileLockToolButton = new QToolButton;
    mpFileLockToolButton->setIconSize(Helper::buttonIconSize);
    mpFileLockToolButton->setIcon(QIcon(mpLibraryTreeItem->isReadOnly() ? ":/Resources/icons/lock.svg" : ":/Resources/icons/unlock.svg"));
    mpFileLockToolButton->setText(mpLibraryTreeItem->isReadOnly() ? tr("Make writable") : tr("File is writable"));
    mpFileLockToolButton->setToolTip(mpFileLockToolButton->text());
    mpFileLockToolButton->setEnabled(mpLibraryTreeItem->isReadOnly() && !mpLibraryTreeItem->isSystemLibrary());
    mpFileLockToolButton->setAutoRaise(true);
    connect(mpFileLockToolButton, SIGNAL(clicked()), SLOT(makeFileWritAble()));
    // create project status bar
    mpModelStatusBar = new QStatusBar;
    mpModelStatusBar->setObjectName("ModelStatusBar");
    mpModelStatusBar->setSizeGripEnabled(false);
    mpModelStatusBar->addPermanentWidget(pViewButtonsFrame, 0);
    // create the main layout
    QVBoxLayout *pMainLayout = new QVBoxLayout;
    pMainLayout->setContentsMargins(0, 0, 0, 0);
    pMainLayout->setSpacing(4);
    pMainLayout->addWidget(mpModelStatusBar);
    setLayout(pMainLayout);
    // show hide widgets based on library type
    if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
      connect(mpIconViewToolButton, SIGNAL(toggled(bool)), SLOT(showIconView(bool)));
      connect(mpDiagramViewToolButton, SIGNAL(toggled(bool)), SLOT(showDiagramView(bool)));
      connect(mpTextViewToolButton, SIGNAL(toggled(bool)), SLOT(showTextView(bool)));
      connect(mpDocumentationViewToolButton, SIGNAL(clicked()), SLOT(showDocumentationView()));
      pViewButtonsHorizontalLayout->addWidget(mpIconViewToolButton);
      pViewButtonsHorizontalLayout->addWidget(mpDiagramViewToolButton);
      pViewButtonsHorizontalLayout->addWidget(mpTextViewToolButton);
      pViewButtonsHorizontalLayout->addWidget(mpDocumentationViewToolButton);
      mpModelicaTypeLabel->setText(StringHandler::getModelicaClassType(mpLibraryTreeItem->getRestriction()));
      mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::Diagram));
      // modelica text editor
      mpEditor = new ModelicaTextEditor(this);
      MainWindow *pMainWindow = mpModelWidgetContainer->getMainWindow();
      mpModelicaTextHighlighter = new ModelicaTextHighlighter(pMainWindow->getOptionsDialog()->getModelicaTextEditorPage(),
                                                              mpEditor->getPlainTextEdit());
      ModelicaTextEditor *pModelicaTextEditor = dynamic_cast<ModelicaTextEditor*>(mpEditor);
      pModelicaTextEditor->setPlainText(mpLibraryTreeItem->getClassText());
      mpEditor->hide(); // set it hidden so that Find/Replace action can get correct value.
      connect(pMainWindow->getOptionsDialog(), SIGNAL(modelicaTextSettingsChanged()), mpModelicaTextHighlighter, SLOT(settingsChanged()));
      mpModelStatusBar->addPermanentWidget(mpReadOnlyLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpModelicaTypeLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpViewTypeLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpModelFilePathLabel, 1);
      mpModelStatusBar->addPermanentWidget(mpCursorPositionLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpFileLockToolButton, 0);
      // set layout
      pMainLayout->addWidget(mpUndoView);
      pMainLayout->addWidget(mpDiagramGraphicsView, 1);
      pMainLayout->addWidget(mpIconGraphicsView, 1);
    } else if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Text) {
      pViewButtonsHorizontalLayout->addWidget(mpTextViewToolButton);
      mpEditor = new TextEditor(this);
      TextEditor *pTextEditor = dynamic_cast<TextEditor*>(mpEditor);
      pTextEditor->setPlainText(mpLibraryTreeItem->getClassText());
      mpModelStatusBar->addPermanentWidget(mpReadOnlyLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpModelFilePathLabel, 1);
      mpModelStatusBar->addPermanentWidget(mpCursorPositionLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpFileLockToolButton, 0);
      // set layout
      pMainLayout->addWidget(mpModelStatusBar);
    } else if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::TLM) {
      connect(mpDiagramViewToolButton, SIGNAL(toggled(bool)), SLOT(showDiagramView(bool)));
      connect(mpTextViewToolButton, SIGNAL(toggled(bool)), SLOT(showTextView(bool)));
      pViewButtonsHorizontalLayout->addWidget(mpDiagramViewToolButton);
      pViewButtonsHorizontalLayout->addWidget(mpTextViewToolButton);
      // icon graphics framework
      mpIconGraphicsScene = new GraphicsScene(StringHandler::Icon, this);
      mpIconGraphicsView = new GraphicsView(StringHandler::Icon, this);
      mpIconGraphicsView->setScene(mpIconGraphicsScene);
      mpIconGraphicsView->hide();
      // diagram graphics framework
      mpDiagramGraphicsScene = new GraphicsScene(StringHandler::Diagram, this);
      mpDiagramGraphicsView = new GraphicsView(StringHandler::Diagram, this);
      mpDiagramGraphicsView->setScene(mpDiagramGraphicsScene);
      mpDiagramGraphicsView->hide();
      // Undo stack for model
      mpUndoStack = new QUndoStack;
      connect(mpUndoStack, SIGNAL(canUndoChanged(bool)), SLOT(handleCanUndoChanged(bool)));
      connect(mpUndoStack, SIGNAL(canRedoChanged(bool)), SLOT(handleCanRedoChanged(bool)));
      mpUndoView = new QUndoView(mpUndoStack);
      // create an xml editor for TLM
      mpEditor = new TLMEditor(this);
      TLMEditor *pTLMEditor = dynamic_cast<TLMEditor*>(mpEditor);
      if (mpLibraryTreeItem->getFileName().isEmpty()) {
        QString defaultMetaModelText = QString("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                                               "<!-- The root node is the meta-model -->\n"
                                               "<Model Name=\"%1\">\n"
                                               "  <!-- List of connected sub-models -->\n"
                                               "  <SubModels>\n\n"
                                               "  </SubModels>\n"
                                               "  <!-- List of TLM connections -->\n"
                                               "  <Connections>\n\n"
                                               "  </Connections>\n"
                                               "  <!-- Parameters for the simulation -->\n"
                                               "  <SimulationParams StartTime=\"0\" StopTime=\"1\" />\n"
                                               "</Model>").arg(mpLibraryTreeItem->getName());
        pTLMEditor->setPlainText(defaultMetaModelText);
        mpLibraryTreeItem->setClassText(defaultMetaModelText);
      } else {
        pTLMEditor->setPlainText(mpLibraryTreeItem->getClassText());
      }
      MainWindow *pMainWindow = mpModelWidgetContainer->getMainWindow();
      mpTLMHighlighter = new TLMHighlighter(pMainWindow->getOptionsDialog()->getTLMEditorPage(), mpEditor->getPlainTextEdit());
      mpEditor->hide(); // set it hidden so that Find/Replace action can get correct value.
      connect(pMainWindow->getOptionsDialog(), SIGNAL(TLMEditorSettingsChanged()), mpTLMHighlighter, SLOT(settingsChanged()));
      // only get the TLM components and connectors if the TLM is not a new class.
      if (!mpLibraryTreeItem->getFileName().isEmpty()) {
        getTLMComponents();
        getTLMConnections();
        TLMEditorTextChanged();
      }
      mpIconGraphicsScene->clearSelection();
      mpDiagramGraphicsScene->clearSelection();
      mpModelStatusBar->addPermanentWidget(mpReadOnlyLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpViewTypeLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpModelFilePathLabel, 1);
      mpModelStatusBar->addPermanentWidget(mpCursorPositionLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpFileLockToolButton, 0);
      // set layout
      pMainLayout->addWidget(mpModelStatusBar);
      pMainLayout->addWidget(mpUndoView);
      pMainLayout->addWidget(mpDiagramGraphicsView, 1);
    }
    pMainLayout->addWidget(mpEditor, 1);
    mloadWidgetComponents = true;
  }
}

/*!
 * \brief ModelWidget::getConnectorComponent
 * Finds the Port Component within the Component.
 * \param pConnectorComponent
 * \param connectorName
 * \return
 */
Component* ModelWidget::getConnectorComponent(Component *pConnectorComponent, QString connectorName)
{
  Component *pConnectorComponentFound = 0;
  foreach (Component *pComponent, pConnectorComponent->getComponentsList()) {
    if (pComponent->getName().compare(connectorName) == 0) {
      pConnectorComponentFound = pComponent;
      return pConnectorComponentFound;
    }
  }
  /* if port is not found in components list then look into the inherited components list. */
  foreach (Component *pInheritedComponent, pConnectorComponent->getInheritanceList()) {
    pConnectorComponentFound = getConnectorComponent(pInheritedComponent, connectorName);
    if (pConnectorComponentFound) {
      return pConnectorComponentFound;
    }
  }
  return pConnectorComponentFound;
}

void ModelWidget::refresh()
{
  QApplication::setOverrideCursor(Qt::WaitCursor);
  /* set the LibraryTreeItem filename, type & tooltip */
  OMCProxy *pOMCProxy = mpModelWidgetContainer->getMainWindow()->getOMCProxy();
  pOMCProxy->setSourceFile(mpLibraryTreeItem->getNameStructure(), mpLibraryTreeItem->getFileName());
  mpLibraryTreeItem->setClassInformation(pOMCProxy->getClassInformation(mpLibraryTreeItem->getNameStructure()));
  bool isDocumentationClass = mpModelWidgetContainer->getMainWindow()->getOMCProxy()->getDocumentationClassAnnotation(mpLibraryTreeItem->getNameStructure());
  mpLibraryTreeItem->setIsDocumentationClass(isDocumentationClass);
  mpLibraryTreeItem->updateAttributes();
//  mpModelWidgetContainer->getMainWindow()->getLibraryWidget()->loadLibraryComponent(mpLibraryTreeItem);
  /* remove everything from the icon view */
  mpIconGraphicsView->removeAllComponents();
  mpIconGraphicsView->removeAllShapes();
  mpIconGraphicsView->removeAllConnections();
  mpIconGraphicsView->scene()->clear();
  /* remove everything from the diagram view */
  mpDiagramGraphicsView->removeAllComponents();
  mpDiagramGraphicsView->removeAllShapes();
  mpDiagramGraphicsView->removeAllConnections();
  mpDiagramGraphicsView->scene()->clear();
  /* get model components, connection and shapes. */
  if (getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::TLM)
  {
    getTLMComponents();
    getTLMConnections();
  }
  else
  {
    getModelInheritedClasses(getLibraryTreeItem());
    //getModelIconDiagramShapes(getLibraryTreeItem()->getNameStructure());
    getModelComponents();
  }

  QApplication::restoreOverrideCursor();
}

/*!
 * \brief ModelWidget::validateText
 * Validates the text of the editor.
 * \return Returns true if validation is successful otherwise return false.
 */
bool ModelWidget::validateText()
{
  ModelicaTextEditor *pModelicaTextEditor = dynamic_cast<ModelicaTextEditor*>(mpEditor);
  if (pModelicaTextEditor) {
    return pModelicaTextEditor->validateText();
  }
  TLMEditor *pTLMEditor = dynamic_cast<TLMEditor*>(mpEditor);
  if (pTLMEditor) {
    return pTLMEditor->validateMetaModelText();
  }
  return false;
}

bool ModelWidget::modelicaEditorTextChanged()
{
  QString errorString;
  ModelicaTextEditor *pModelicaTextEditor = dynamic_cast<ModelicaTextEditor*>(mpEditor);
  QStringList classNames = pModelicaTextEditor->getClassNames(&errorString);
  LibraryTreeModel *pLibraryTreeModel = mpModelWidgetContainer->getMainWindow()->getLibraryWidget()->getLibraryTreeModel();
  OMCProxy *pOMCProxy = mpModelWidgetContainer->getMainWindow()->getOMCProxy();
  if (classNames.size() == 0) {
    if (!errorString.isEmpty()) {
      MessagesWidget *pMessagesWidget = getModelWidgetContainer()->getMainWindow()->getMessagesWidget();
      pMessagesWidget->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, errorString, Helper::syntaxKind, Helper::errorLevel));
    }
    return false;
  }
  /* if no errors are found with the Modelica Text then load it in OMC */
  QString modelicaText = pModelicaTextEditor->getPlainTextEdit()->toPlainText();
  if (!pOMCProxy->loadString("within " + mpLibraryTreeItem->parent()->getNameStructure() + ";" + modelicaText, classNames.at(0))) {
    return false;
  }
  /* first handle the current class */
  /* if user has changed the class then refresh it. */
  if (classNames.contains(mpLibraryTreeItem->getNameStructure())) {
    /* if class has children then delete them. */
    pLibraryTreeModel->unloadClass(mpLibraryTreeItem, false);
    classNames.removeOne(mpLibraryTreeItem->getNameStructure());
    refresh();
    /* if class has children then create them. */
    pLibraryTreeModel->createLibraryTreeItems(mpLibraryTreeItem);
    setModelModified();
  }
  /*
    if user has changed the class name then delete this class.
    Update the LibraryTreeItem with new class name and then refresh it.
    */
  else
  {
    /* if class has children then delete them. */
    pLibraryTreeModel->unloadClass(mpLibraryTreeItem, false);
    /* call setModelModified before deleting the class so we can get rid of cache commands of this object. */
    setModelModified();
    pOMCProxy->deleteClass(mpLibraryTreeItem->getNameStructure());
    QString className = classNames.first();
    classNames.removeFirst();
    /* set the LibraryTreeItem name & text */
    mpLibraryTreeItem->setName(StringHandler::getLastWordAfterDot(className));
    mpLibraryTreeItem->setNameStructure(className);
    setModelModified();
    /* get the model components, shapes & connectors */
    refresh();
    /* if class has children then create them. */
    pLibraryTreeModel->createLibraryTreeItems(mpLibraryTreeItem);
  }
  return true;
}

/*!
 * \brief ModelWidget::clearSelection
 * Clears the selection Icon and Diagram layers.
 */
void ModelWidget::clearSelection()
{
  if (mpIconGraphicsView) {
    mpIconGraphicsView->clearSelection();
  }
  if (mpDiagramGraphicsView) {
    mpDiagramGraphicsView->clearSelection();
  }
}

/*!
 * \brief ModelWidget::updateClassAnnotationIfNeeded
 * Updates the class annotation for both icon and diagram views if needed.
 */
void ModelWidget::updateClassAnnotationIfNeeded()
{
  if (mpIconGraphicsView && mpIconGraphicsView->isAddClassAnnotationNeeded()) {
    mpIconGraphicsView->addClassAnnotation(false);
    mpIconGraphicsView->setAddClassAnnotationNeeded(false);
  }
  if (mpDiagramGraphicsView && mpDiagramGraphicsView->isAddClassAnnotationNeeded()) {
    mpDiagramGraphicsView->addClassAnnotation(false);
    mpDiagramGraphicsView->setAddClassAnnotationNeeded(false);
  }
}

/*!
 * \brief ModelWidget::updateModelicaText
 * Updates the Modelica Text of the class.
 * Uses OMCProxy::listFile() and OMCProxy::diffModelicaFileListings() to get the correct Modelica Text.
 * \sa OMCProxy::listFile()
 * \sa OMCProxy::diffModelicaFileListings()
 */
void ModelWidget::updateModelicaText()
{
  LibraryTreeModel *pLibraryTreeModel = mpModelWidgetContainer->getMainWindow()->getLibraryWidget()->getLibraryTreeModel();
  pLibraryTreeModel->updateLibraryTreeItemClassText(mpLibraryTreeItem);
}

/*!
 * \brief ModelWidget::updateUndoRedoActions
 * Enables/disables the Undo/Redo actions based on the stack situation.
 */
void ModelWidget::updateUndoRedoActions()
{
  if (mpIconGraphicsView && mpIconGraphicsView->isVisible()) {
    mpModelWidgetContainer->getMainWindow()->getUndoAction()->setEnabled(mpUndoStack->canUndo());
    mpModelWidgetContainer->getMainWindow()->getRedoAction()->setEnabled(mpUndoStack->canRedo());
  } else if (mpDiagramGraphicsView && mpDiagramGraphicsView->isVisible()) {
    mpModelWidgetContainer->getMainWindow()->getUndoAction()->setEnabled(mpUndoStack->canUndo());
    mpModelWidgetContainer->getMainWindow()->getRedoAction()->setEnabled(mpUndoStack->canRedo());
  } else {
    mpModelWidgetContainer->getMainWindow()->getUndoAction()->setEnabled(false);
    mpModelWidgetContainer->getMainWindow()->getRedoAction()->setEnabled(false);
  }
}

/*!
 * \brief ModelWidget::getModelInheritedClasses
 * Gets the class inherited classes.
 * \param className
 */
void ModelWidget::getModelInheritedClasses(LibraryTreeItem *pLibraryTreeItem)
{
  MainWindow *pMainWindow = mpModelWidgetContainer->getMainWindow();
  // get the inherited classes of the class
  if (pLibraryTreeItem == mpLibraryTreeItem) {
    QList<QString> inheritedClasses = pMainWindow->getOMCProxy()->getInheritedClasses(pLibraryTreeItem->getNameStructure());
    foreach (QString inheritedClass, inheritedClasses) {
      /* If the inherited class is one of the builtin type such as Real we can
       * stop here, because the class can not contain any classes, etc.
       * Also check for cyclic loops.
       */
      if (!(pMainWindow->getOMCProxy()->isBuiltinType(inheritedClass) || inheritedClass.compare(pLibraryTreeItem->getNameStructure()) == 0)) {
        LibraryTreeItem *pInheritedClass = pMainWindow->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(inheritedClass);
        if (!pInheritedClass) {
          pInheritedClass = pMainWindow->getLibraryWidget()->getLibraryTreeModel()->createNonExistingLibraryTreeItem(inheritedClass);
        }
        if (!pInheritedClass->getModelWidget() || pInheritedClass->getModelWidget()->isReloadNeeded()) {
          pMainWindow->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pInheritedClass, "", false);
        }
        mpLibraryTreeItem->addInheritedClass(pInheritedClass);
        getModelInheritedClasses(pInheritedClass);
        addInheritedClass(pInheritedClass);
      }
    }
  } else {
    QList<LibraryTreeItem*> inheritedClasses = pLibraryTreeItem->getInheritedClasses();
    foreach (LibraryTreeItem *pInheritedClass, inheritedClasses) {
      if ((!pInheritedClass->getModelWidget() || pInheritedClass->getModelWidget()->isReloadNeeded()) && !pInheritedClass->isNonExisting()) {
        pMainWindow->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pInheritedClass, "", false);
      }
      mpLibraryTreeItem->addInheritedClass(pInheritedClass);
      getModelInheritedClasses(pInheritedClass);
      addInheritedClass(pInheritedClass);
    }
  }
}

/*!
 * \brief ModelWidget::drawModelInheritedClasses
 * Draws the inherited classes.
 */
void ModelWidget::drawModelInheritedClasses()
{
  foreach (InheritedClass *pInheritedClass, mInheritedClassesList) {
    drawModelInheritedClassShapes(pInheritedClass, StringHandler::Icon);
    drawModelInheritedClassShapes(pInheritedClass, StringHandler::Diagram);
  }
}

/*!
 * \brief ModelWidget::removeInheritedClassShapes
 * Removes the inherited class shapes.
 * \param pInheritedClass
 */
void ModelWidget::removeInheritedClassShapes(InheritedClass *pInheritedClass, StringHandler::ViewType viewType)
{
  if (viewType == StringHandler::Icon) {
    foreach (ShapeAnnotation *pShapeAnnotation, pInheritedClass->mIconShapesList) {
      mpIconGraphicsView->removeItem(pShapeAnnotation);
    }
    pInheritedClass->mIconShapesList.clear();
  } else {
    foreach (ShapeAnnotation *pShapeAnnotation, pInheritedClass->mDiagramShapesList) {
      mpDiagramGraphicsView->removeItem(pShapeAnnotation);
    }
    pInheritedClass->mDiagramShapesList.clear();
  }
}

/*!
 * \brief ModelWidget::parseModelInheritedClass
 * Parses the inherited class shape and draws its items on the appropriate view.
 * \param pLibraryTreeItem
 * \param viewType
 */
void ModelWidget::drawModelInheritedClassShapes(InheritedClass *pInheritedClass, StringHandler::ViewType viewType)
{
  removeInheritedClassShapes(pInheritedClass, viewType);
  LibraryTreeItem *pLibraryTreeItem = pInheritedClass->mpLibraryTreeItem;
  if (pLibraryTreeItem) {
    GraphicsView *pInheritedGraphicsView, *pGraphicsView;
    if (pLibraryTreeItem->isNonExisting()) {
      if (viewType == StringHandler::Icon) {
        pGraphicsView = mpIconGraphicsView;
        pInheritedClass->mIconShapesList.append(createNonExistingInheritedShape(pGraphicsView));
      } else {
        pGraphicsView = mpDiagramGraphicsView;
        pInheritedClass->mDiagramShapesList.append(createNonExistingInheritedShape(pGraphicsView));
      }
    } else {
      if (viewType == StringHandler::Icon) {
        pInheritedGraphicsView = pLibraryTreeItem->getModelWidget()->getIconGraphicsView();
        pGraphicsView = mpIconGraphicsView;
      } else {
        pInheritedGraphicsView = pLibraryTreeItem->getModelWidget()->getDiagramGraphicsView();
        pGraphicsView = mpDiagramGraphicsView;
      }
      // loop through the inherited class shapes
      foreach (ShapeAnnotation *pShapeAnnotation, pInheritedGraphicsView->getShapesList()) {
        if (viewType == StringHandler::Icon) {
          pInheritedClass->mIconShapesList.append(createInheritedShape(pShapeAnnotation, pGraphicsView));
        } else {
          pInheritedClass->mDiagramShapesList.append(createInheritedShape(pShapeAnnotation, pGraphicsView));
        }
      }
    }
  }
}

/*!
 * \brief ModelWidget::getModelIconShapes
 * Gets the Modelica model icon & diagram shapes.
 */
void ModelWidget::getModelIconDiagramShapes()
{
  OMCProxy *pOMCProxy = mpModelWidgetContainer->getMainWindow()->getOMCProxy();
  QString iconAnnotationString = pOMCProxy->getIconAnnotation(mpLibraryTreeItem->getNameStructure());
  parseModelIconDiagramShapes(iconAnnotationString, StringHandler::Icon);
  QString diagramAnnotationString = pOMCProxy->getDiagramAnnotation(mpLibraryTreeItem->getNameStructure());
  parseModelIconDiagramShapes(diagramAnnotationString, StringHandler::Diagram);
}

/*!
 * \brief ModelWidget::parseModelIconDiagramShapes
 * Parses the Modelica icon/diagram annotation and creates shapes for it on appropriate GraphicsView.
 * \param annotationString
 * \param viewType
 */
void ModelWidget::parseModelIconDiagramShapes(QString annotationString, StringHandler::ViewType viewType)
{
  annotationString = StringHandler::removeFirstLastCurlBrackets(annotationString);
  if (annotationString.isEmpty()) {
    return;
  }
  QStringList list = StringHandler::getStrings(annotationString);
  // read the coordinate system
  if (list.size() < 8) {
    return;
  }
  GraphicsView *pGraphicsView;
  if (viewType == StringHandler::Icon) {
    pGraphicsView = mpIconGraphicsView;
  } else {
    pGraphicsView = mpDiagramGraphicsView;
  }
  qreal left = qMin(list.at(0).toFloat(), list.at(2).toFloat());
  qreal bottom = qMin(list.at(1).toFloat(), list.at(3).toFloat());
  qreal right = qMax(list.at(0).toFloat(), list.at(2).toFloat());
  qreal top = qMax(list.at(1).toFloat(), list.at(3).toFloat());
  QList<QPointF> extent;
  extent << QPointF(left, bottom) << QPointF(right, top);
  pGraphicsView->getCoOrdinateSystem()->setExtent(extent);
  pGraphicsView->getCoOrdinateSystem()->setPreserveAspectRatio((list.at(4).compare("true") == 0) ? true : false);
  pGraphicsView->getCoOrdinateSystem()->setInitialScale(list.at(5).toFloat());
  qreal horizontal = list.at(6).toFloat();
  qreal vertical = list.at(7).toFloat();
  pGraphicsView->getCoOrdinateSystem()->setGrid(QPointF(horizontal, vertical));
  pGraphicsView->setExtentRectangle(left, bottom, right, top);
  pGraphicsView->fitInView(pGraphicsView->getExtentRectangle(), Qt::KeepAspectRatio);
  pGraphicsView->setIsCustomScale(false);
  // read the shapes
  if (list.size() < 9)
    return;
  QStringList shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(8)), '(', ')');
  // Now parse the shapes available in list
  foreach (QString shape, shapesList) {
    if (shape.startsWith("Line")) {
      shape = shape.mid(QString("Line").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      LineAnnotation *pLineAnnotation = new LineAnnotation(shape, pGraphicsView);
      pLineAnnotation->initializeTransformation();
      pLineAnnotation->drawCornerItems();
      pLineAnnotation->setCornerItemsActiveOrPassive();
      pGraphicsView->addShapeToList(pLineAnnotation);
      pGraphicsView->addItem(pLineAnnotation);
    } else if (shape.startsWith("Polygon")) {
      shape = shape.mid(QString("Polygon").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      PolygonAnnotation *pPolygonAnnotation = new PolygonAnnotation(shape, pGraphicsView);
      pPolygonAnnotation->initializeTransformation();
      pPolygonAnnotation->drawCornerItems();
      pPolygonAnnotation->setCornerItemsActiveOrPassive();
      pGraphicsView->addShapeToList(pPolygonAnnotation);
      pGraphicsView->addItem(pPolygonAnnotation);
    } else if (shape.startsWith("Rectangle")) {
      shape = shape.mid(QString("Rectangle").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      RectangleAnnotation *pRectangleAnnotation = new RectangleAnnotation(shape, pGraphicsView);
      pRectangleAnnotation->initializeTransformation();
      pRectangleAnnotation->drawCornerItems();
      pRectangleAnnotation->setCornerItemsActiveOrPassive();
      pGraphicsView->addShapeToList(pRectangleAnnotation);
      pGraphicsView->addItem(pRectangleAnnotation);
    } else if (shape.startsWith("Ellipse")) {
      shape = shape.mid(QString("Ellipse").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      EllipseAnnotation *pEllipseAnnotation = new EllipseAnnotation(shape, pGraphicsView);
      pEllipseAnnotation->initializeTransformation();
      pEllipseAnnotation->drawCornerItems();
      pEllipseAnnotation->setCornerItemsActiveOrPassive();
      pGraphicsView->addShapeToList(pEllipseAnnotation);
      pGraphicsView->addItem(pEllipseAnnotation);
    } else if (shape.startsWith("Text")) {
      shape = shape.mid(QString("Text").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      TextAnnotation *pTextAnnotation = new TextAnnotation(shape, pGraphicsView);
      pTextAnnotation->initializeTransformation();
      pTextAnnotation->drawCornerItems();
      pTextAnnotation->setCornerItemsActiveOrPassive();
      pGraphicsView->addShapeToList(pTextAnnotation);
      pGraphicsView->addItem(pTextAnnotation);
    } else if (shape.startsWith("Bitmap")) {
      /* create the bitmap shape */
      shape = shape.mid(QString("Bitmap").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      BitmapAnnotation *pBitmapAnnotation = new BitmapAnnotation(mpLibraryTreeItem->getClassInformation().fileName, shape, pGraphicsView);
      pBitmapAnnotation->initializeTransformation();
      pBitmapAnnotation->drawCornerItems();
      pBitmapAnnotation->setCornerItemsActiveOrPassive();
      pGraphicsView->addShapeToList(pBitmapAnnotation);
      pGraphicsView->addItem(pBitmapAnnotation);
    }
  }
}

/*!
 * \brief ModelWidget::drawModelInheritedComponents
 * Loops through the class inhertited classes and draws the components for all.
 * \sa ModelWidget::drawModelInheritedClassComponents()
 */
void ModelWidget::drawModelInheritedComponents()
{
  foreach (InheritedClass *pInheritedClass, mInheritedClassesList) {
    drawModelInheritedClassComponents(pInheritedClass);
  }
}

/*!
 * \brief ModelWidget::removeInheritedClassComponents
 * Removes the class inherited class components.
 * \param pInheritedClass - the inherited class.
 */
void ModelWidget::removeInheritedClassComponents(InheritedClass *pInheritedClass)
{
  foreach (Component *pComponent, pInheritedClass->mIconComponentsList) {
    mpIconGraphicsView->removeItem(pComponent);
  }
  pInheritedClass->mIconComponentsList.clear();
  foreach (Component *pComponent, pInheritedClass->mDiagramComponentsList) {
    mpDiagramGraphicsView->removeItem(pComponent);
  }
  pInheritedClass->mDiagramComponentsList.clear();
}

/*!
 * \brief ModelWidget::drawModelInheritedClassComponents
 * Draws the class inherited components.
 * \param pInheritedClass - the inherited class.
 */
void ModelWidget::drawModelInheritedClassComponents(InheritedClass *pInheritedClass)
{
  removeInheritedClassComponents(pInheritedClass);
  LibraryTreeItem *pInheritedLibraryTreeItem = pInheritedClass->mpLibraryTreeItem;
  foreach (Component *pInheritedComponent, pInheritedLibraryTreeItem->getModelWidget()->getIconGraphicsView()->getComponentsList()) {
    pInheritedClass->mIconComponentsList.append(createInheritedComponent(pInheritedComponent, mpIconGraphicsView));
  }
  foreach (Component *pInheritedComponent, pInheritedLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->getComponentsList()) {
    pInheritedClass->mDiagramComponentsList.append(createInheritedComponent(pInheritedComponent, mpDiagramGraphicsView));
  }
}

/*!
 * \brief ModelWidget::getModelComponents
 * Gets the components of the model and place them in the diagram and icon GraphicsView.
 */
void ModelWidget::getModelComponents()
{
  MainWindow *pMainWindow = mpModelWidgetContainer->getMainWindow();
  // get the components
  QList<ComponentInfo*> componentsList = pMainWindow->getOMCProxy()->getComponents(mpLibraryTreeItem->getNameStructure());
  // get the components annotations
  QStringList componentsAnnotationsList = pMainWindow->getOMCProxy()->getComponentAnnotations(mpLibraryTreeItem->getNameStructure());
  int i = 0;
  foreach (ComponentInfo *pComponentInfo, componentsList) {
    /* if the component type is one of the builtin type then don't show it */
    LibraryTreeItem *pLibraryTreeItem = 0;
    if (!pMainWindow->getOMCProxy()->isBuiltinType(pComponentInfo->getClassName())) {
      LibraryTreeModel *pLibraryTreeModel = pMainWindow->getLibraryWidget()->getLibraryTreeModel();
      pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(pComponentInfo->getClassName());
      if (!pLibraryTreeItem) {
        pLibraryTreeItem = pLibraryTreeModel->createNonExistingLibraryTreeItem(pComponentInfo->getClassName());
      }
      if (!pLibraryTreeItem->getModelWidget() || pLibraryTreeItem->getModelWidget()->isReloadNeeded()) {
        pLibraryTreeModel->showModelWidget(pLibraryTreeItem, "", false);
      }
    }
    QString transformation = "";
    if (componentsAnnotationsList.size() >= i) {
      transformation = StringHandler::getPlacementAnnotation(componentsAnnotationsList.at(i));
      if (transformation.isEmpty()) {
        transformation = "Placement(false,0.0,0.0,-10.0,-10.0,10.0,10.0,0.0,-,-,-,-,-,-,)";
      }
    }
    mpDiagramGraphicsView->addComponentToView(pComponentInfo->getName(), pLibraryTreeItem, transformation, QPointF(0, 0), pComponentInfo,
                                              false, true);
    i++;
  }
}

/*!
 * \brief ModelWidget::drawModelInheritedConnections
 * Loops through the class inhertited classes and draws the connections for all.
 * \sa ModelWidget::drawModelInheritedClassConnections()
 */
void ModelWidget::drawModelInheritedConnections()
{
  foreach (InheritedClass *pInheritedClass, mInheritedClassesList) {
    drawModelInheritedClassConnections(pInheritedClass);
  }
}

/*!
 * \brief ModelWidget::removeInheritedClassConnections
 * Removes the class inherited class connections.
 * \param pInheritedClass - the inherited class.
 */
void ModelWidget::removeInheritedClassConnections(InheritedClass *pInheritedClass)
{
  foreach (LineAnnotation *pConnectionLineAnnotation, pInheritedClass->mConnectionsList) {
    mpDiagramGraphicsView->removeItem(pConnectionLineAnnotation);
  }
  pInheritedClass->mConnectionsList.clear();
}

/*!
 * \brief ModelWidget::drawModelInheritedClassConnections
 * Draws the class inherited connections.
 * \param pInheritedClass - the inherited class.
 */
void ModelWidget::drawModelInheritedClassConnections(InheritedClass *pInheritedClass)
{
  removeInheritedClassConnections(pInheritedClass);
  LibraryTreeItem *pInheritedLibraryTreeItem = pInheritedClass->mpLibraryTreeItem;
  foreach (LineAnnotation *pConnection, pInheritedLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->getConnectionsList()) {
    pInheritedClass->mConnectionsList.append(createInheritedConnection(pConnection, pInheritedLibraryTreeItem));
  }
}

/*!
 * \brief ModelWidget::getModelConnections
 * Gets the connections of the model and place them in the diagram GraphicsView.
 */
void ModelWidget::getModelConnections()
{
  MainWindow *pMainWindow = mpModelWidgetContainer->getMainWindow();
  int connectionCount = pMainWindow->getOMCProxy()->getConnectionCount(mpLibraryTreeItem->getNameStructure());
  for (int i = 1 ; i <= connectionCount ; i++) {
    // get the connection from OMC
    QString connectionString;
    QStringList connectionList;
    connectionString = pMainWindow->getOMCProxy()->getNthConnection(mpLibraryTreeItem->getNameStructure(), i);
    connectionList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(connectionString));
    // if the connectionString only contains two items then continue the loop,
    // because connection is not valid then
    if (connectionList.size() < 3) {
      continue;
    }
    // get start and end components
    QStringList startComponentList = connectionList.at(0).split(".");
    QStringList endComponentList = connectionList.at(1).split(".");
    // get start component
    Component *pStartComponent = 0;
    if (startComponentList.size() > 0) {
      pStartComponent = mpDiagramGraphicsView->getComponentObject(startComponentList.at(0));
    }
    // get end component
    Component *pEndComponent = 0;
    if (endComponentList.size() > 0) {
      pEndComponent = mpDiagramGraphicsView->getComponentObject(endComponentList.at(0));
    }
    // get start and end connectors
    Component *pStartConnectorComponent = 0;
    Component *pEndConnectorComponent = 0;
    if (pStartComponent) {
      // if a component type is connector then we only get one item in startComponentList
      // check the startcomponentlist
      if (startComponentList.size() < 2 || pStartComponent->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) {
        pStartConnectorComponent = pStartComponent;
      } else if (!pMainWindow->getOMCProxy()->existClass(pStartComponent->getLibraryTreeItem()->getNameStructure())) {
        /* if class doesn't exist then connect with the red cross box */
        pStartConnectorComponent = pStartComponent;
      } else {
        // look for port from the parent component
        QString startComponentName = startComponentList.at(1);
        if (startComponentName.contains("[")) {
          startComponentName = startComponentName.mid(0, startComponentName.indexOf("["));
        }
        pStartConnectorComponent = getConnectorComponent(pStartComponent, startComponentName);
      }
    }
    if (pEndComponent) {
      // if a component type is connector then we only get one item in endComponentList
      // check the endcomponentlist
      if (endComponentList.size() < 2 || pEndComponent->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) {
        pEndConnectorComponent = pEndComponent;
      } else if (!pMainWindow->getOMCProxy()->existClass(pEndComponent->getLibraryTreeItem()->getNameStructure())) {
        /* if class doesn't exist then connect with the red cross box */
        pEndConnectorComponent = pEndComponent;
      } else {
        QString endComponentName = endComponentList.at(1);
        if (endComponentName.contains("[")) {
          endComponentName = endComponentName.mid(0, endComponentName.indexOf("["));
        }
        pEndConnectorComponent = getConnectorComponent(pEndComponent, endComponentName);
      }
    }
    // get the connector annotations from OMC
    QString connectionAnnotationString = pMainWindow->getOMCProxy()->getNthConnectionAnnotation(mpLibraryTreeItem->getNameStructure(), i);
    QStringList shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(connectionAnnotationString), '(', ')');
    // Now parse the shapes available in list
    foreach (QString shape, shapesList) {
      if (shape.startsWith("Line")) {
        shape = shape.mid(QString("Line").length());
        shape = StringHandler::removeFirstLastBrackets(shape);
        LineAnnotation *pConnectionLineAnnotation;
        pConnectionLineAnnotation = new LineAnnotation(shape, pStartConnectorComponent, pEndConnectorComponent, mpDiagramGraphicsView);
        pConnectionLineAnnotation->setStartComponentName(connectionList.at(0));
        pConnectionLineAnnotation->setEndComponentName(connectionList.at(1));
        mpUndoStack->push(new AddConnectionCommand(pConnectionLineAnnotation, false, mpDiagramGraphicsView));
      }
    }
  }
}

/*!
 * \brief ModelWidget::getTLMComponents
 * Gets the components of the TLM and place them in the diagram GraphicsView.
 */
void ModelWidget::getTLMComponents()
{
  TLMEditor *pTLMEditor = dynamic_cast<TLMEditor*>(mpEditor);
  QDomNodeList subModels = pTLMEditor->getSubModels();
  for (int i = 0; i < subModels.size(); i++) {
    QString transformation;
    bool annotationFound = false;
    QDomElement subModel = subModels.at(i).toElement();
    QDomNodeList subModelChildren = subModel.childNodes();
    for (int j = 0 ; j < subModelChildren.size() ; j++) {
      QDomElement annotationElement = subModelChildren.at(j).toElement();
      if (annotationElement.tagName().compare("Annotation") == 0) {
        annotationFound = true;
        transformation = "Placement(";
        transformation.append(annotationElement.attribute("Visible")).append(",");
        transformation.append(StringHandler::removeFirstLastCurlBrackets(annotationElement.attribute("Origin"))).append(",");
        transformation.append(StringHandler::removeFirstLastCurlBrackets(annotationElement.attribute("Extent"))).append(",");
        transformation.append(StringHandler::removeFirstLastCurlBrackets(annotationElement.attribute("Rotation"))).append(",");
        transformation.append("-,-,-,-,-,-,");
      }
    }
    if (!annotationFound) {
      transformation = "Placement(true, 0.0, 0.0, -10.0, -10.0, 10.0, 10.0, 0.0, -, -, -, -, -, -,";
      pTLMEditor->createAnnotationElement(subModel, "true", "{0,0}", "{-10,-10,10,10}", "0");
      setModelModified();
    }
    QFileInfo fileInfo(mpLibraryTreeItem->getFileName());
    QString fileName = fileInfo.absolutePath() + "/" + subModel.attribute("Name") + "/" + subModel.attribute("ModelFile");
    // add the component to the the diagram view.
//    mpDiagramGraphicsView->addComponentToView(subModel.attribute("Name"), subModel.attribute("Name"), transformation, QPointF(0.0, 0.0),
//                                              new ComponentInfo(""), StringHandler::Connector, false, false, false, "", fileName);
  }
}

void ModelWidget::getTLMConnections()
{
  TLMEditor *pTLMEditor = dynamic_cast<TLMEditor*>(mpEditor);
  QDomNodeList connections = pTLMEditor->getConnections();
  for (int i = 0; i < connections.size(); i++) {
    QDomElement connection = connections.at(i).toElement();
    QDomNodeList connectionChildren = connection.childNodes();
    for (int j = 0 ; j < connectionChildren.size() ; j++) {
      QDomElement annotationElement = connectionChildren.at(j).toElement();
      if (annotationElement.tagName().compare("Annotation") == 0) {
        // get start component
        Component *pStartComponent = 0;
        pStartComponent = mpDiagramGraphicsView->getComponentObject(StringHandler::getSubStringBeforeDots(connection.attribute("From")));
        // get end component
        Component *pEndComponent = 0;
        pEndComponent = mpDiagramGraphicsView->getComponentObject(StringHandler::getSubStringBeforeDots(connection.attribute("To")));
        // get start and end connectors
        Component *pStartConnectorComponent = 0;
        Component *pEndConnectorComponent = 0;
        if (pStartComponent)
          pStartConnectorComponent = pStartComponent;
         if (pEndComponent)
           pEndConnectorComponent = pEndComponent;
         // get the connector annotations
         QString connectionAnnotationString;
         connectionAnnotationString.append("{Line(true, {0.0, 0.0}, 0, ").append(annotationElement.attribute("Points"));
         connectionAnnotationString.append(", {0, 0, 0}, LinePattern.Solid, 0.25, {Arrow.None, Arrow.None}, 3, Smooth.None)}");
         QStringList shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(connectionAnnotationString), '(', ')');
         // Now parse the shapes available in list
         foreach (QString shape, shapesList) {
           if (shape.startsWith("Line")) {
             shape = shape.mid(QString("Line").length());
             shape = StringHandler::removeFirstLastBrackets(shape);
             LineAnnotation *pConnectionLineAnnotation;
             pConnectionLineAnnotation = new LineAnnotation(shape, pStartConnectorComponent, pEndConnectorComponent, mpDiagramGraphicsView);
             if (pStartConnectorComponent)
               pStartConnectorComponent->getRootParentComponent()->addConnectionDetails(pConnectionLineAnnotation);
             pConnectionLineAnnotation->setStartComponentName(StringHandler::getSubStringBeforeDots(connection.attribute("From")));
             if (pEndConnectorComponent)
               pEndConnectorComponent->getRootParentComponent()->addConnectionDetails(pConnectionLineAnnotation);
             pConnectionLineAnnotation->setEndComponentName(StringHandler::getSubStringBeforeDots(connection.attribute("To")));
             pConnectionLineAnnotation->addPoint(QPointF(0, 0));
             pConnectionLineAnnotation->drawCornerItems();
             pConnectionLineAnnotation->setCornerItemsActiveOrPassive();
             mpDiagramGraphicsView->addConnectionToList(pConnectionLineAnnotation);
          }
        }
      }
    }
  }
}

/*!
 * \brief ModelWidget::showIconView
 * \param checked
 * Slot activated when mpIconViewToolButton toggled SIGNAL is raised. Shows the icon view.
 */
void ModelWidget::showIconView(bool checked)
{
  // validate the modelica text before switching to icon view
  if (checked) {
    if (!validateText()) {
      mpTextViewToolButton->setChecked(true);
      return;
    }
  }
  QMdiSubWindow *pSubWindow = mpModelWidgetContainer->getCurrentMdiSubWindow();
  if (pSubWindow) {
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/model.svg"));
  }
  mpIconGraphicsView->setFocus();
  if (!checked || (checked && mpIconGraphicsView->isVisible())) {
    return;
  }
  mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::Icon));
  mpDiagramGraphicsView->hide();
  mpEditor->hide();
  mpIconGraphicsView->show();
  mpModelWidgetContainer->setPreviousViewType(StringHandler::Icon);
  updateUndoRedoActions();
}

/*!
 * \brief ModelWidget::showDiagramView
 * \param checked
 * Slot activated when mpDiagramViewToolButton toggled SIGNAL is raised. Shows the diagram view.
 */
void ModelWidget::showDiagramView(bool checked)
{
  // validate the modelica text before switching to diagram view
  if (checked) {
    if (!validateText()) {
      mpTextViewToolButton->setChecked(true);
      return;
    }
  }
  QMdiSubWindow *pSubWindow = mpModelWidgetContainer->getCurrentMdiSubWindow();
  if (pSubWindow) {
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/modeling.png"));
  }
  mpDiagramGraphicsView->setFocus();
  if (!checked || (checked && mpDiagramGraphicsView->isVisible())) {
    return;
  }
  mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::Diagram));
  mpIconGraphicsView->hide();
  mpEditor->hide();
  mpDiagramGraphicsView->show();
  mpModelWidgetContainer->setPreviousViewType(StringHandler::Diagram);
  updateUndoRedoActions();
}

/*!
 * \brief ModelWidget::showTextView
 * \param checked
 * Slot activated when mpTextViewToolButton toggled SIGNAL is raised. Shows the text view.
 */
void ModelWidget::showTextView(bool checked)
{
  QMdiSubWindow *pSubWindow = mpModelWidgetContainer->getCurrentMdiSubWindow();
  if (pSubWindow) {
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/modeltext.svg"));
  }
  if (!checked || (checked && mpEditor->isVisible())) {
    return;
  }
  mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::ModelicaText));
  mpIconGraphicsView->hide();
  mpDiagramGraphicsView->hide();
  mpEditor->show();
  mpEditor->getPlainTextEdit()->setFocus();
  mpModelWidgetContainer->setPreviousViewType(StringHandler::ModelicaText);
  updateUndoRedoActions();
}

void ModelWidget::makeFileWritAble()
{
  const QString &fileName = mpLibraryTreeItem->getFileName();
  const bool permsOk = QFile::setPermissions(fileName, QFile::permissions(fileName) | QFile::WriteUser);
  if (!permsOk)
    QMessageBox::warning(this, tr("Cannot Set Permissions"),  tr("Cannot set permissions to writable."));
  else
  {
    mpLibraryTreeItem->setReadOnly(false);
    mpFileLockToolButton->setText(tr("File is writable"));
    mpFileLockToolButton->setIcon(QIcon(":/Resources/icons/unlock.svg"));
    mpFileLockToolButton->setEnabled(false);
    mpFileLockToolButton->setToolTip(mpFileLockToolButton->text());
  }
}

void ModelWidget::showDocumentationView()
{
  // validate the modelica text before switching to documentation view
  ModelicaTextEditor *pModelicaTextEditor = dynamic_cast<ModelicaTextEditor*>(mpEditor);
  if (pModelicaTextEditor && !pModelicaTextEditor->validateText()) {
    mpTextViewToolButton->setChecked(true);
    return;
  }
  mpModelWidgetContainer->getMainWindow()->getDocumentationWidget()->showDocumentation(getLibraryTreeItem()->getNameStructure());
  mpModelWidgetContainer->getMainWindow()->getDocumentationDockWidget()->show();
}

bool ModelWidget::TLMEditorTextChanged()
{
  QFile schemaFile(QString(":/Resources/XMLSchema/tlmModelDescription.xsd"));
  schemaFile.open(QIODevice::ReadOnly);
  const QString schemaText(QString::fromUtf8(schemaFile.readAll()));
  const QByteArray schemaData = schemaText.toUtf8();
  const QByteArray instanceData = mpEditor->getPlainTextEdit()->toPlainText().toUtf8();

  MessageHandler messageHandler;
  QXmlSchema schema;
  schema.setMessageHandler(&messageHandler);
  schema.load(schemaData);

  bool errorOccurred = false;
  if (!schema.isValid()) {
    errorOccurred = true;
  } else {
    QXmlSchemaValidator validator(schema);
    if (!validator.validate(instanceData))
      errorOccurred = true;
  }

  if (errorOccurred) {
    MessagesWidget *pMessagesWidget = getModelWidgetContainer()->getMainWindow()->getMessagesWidget();
    pMessagesWidget->addGUIMessage(MessageItem(MessageItem::TLM, getLibraryTreeItem()->getName(), false, messageHandler.line(), messageHandler.column(), 0, 0, messageHandler.statusMessage(), Helper::syntaxKind, Helper::errorLevel));
    return false;
  }
  /* get the model components and connectors */
  refresh();
  return true;
}

/*!
 * \brief ModelWidget::handleCanUndoChanged
 * Enables/disables the Edit menu Undo action depending on the stack situation.
 * \param canUndo
 */
void ModelWidget::handleCanUndoChanged(bool canUndo)
{
  mpModelWidgetContainer->getMainWindow()->getUndoAction()->setEnabled(canUndo);
}

/*!
 * \brief ModelWidget::handleCanRedoChanged
 * Enables/disables the Edit menu Redo action depending on the stack situation.
 * \param canRedo
 */
void ModelWidget::handleCanRedoChanged(bool canRedo)
{
  mpModelWidgetContainer->getMainWindow()->getRedoAction()->setEnabled(canRedo);
}

void ModelWidget::closeEvent(QCloseEvent *event)
{
  Q_UNUSED(event);
  mpModelWidgetContainer->removeSubWindow(this);
}

ModelWidgetContainer::ModelWidgetContainer(MainWindow *pParent)
  : MdiArea(pParent), mPreviousViewType(StringHandler::NoView), mShowGridLines(true)
{
  if (mpMainWindow->getOptionsDialog()->getGeneralSettingsPage()->getModelingViewMode().compare(Helper::subWindow) == 0) {
    setViewMode(QMdiArea::SubWindowView);
  } else {
    setViewMode(QMdiArea::TabbedView);
  }
  // create a Model Swicther Dialog
  mpModelSwitcherDialog = new QDialog(this, Qt::Popup);
  mpRecentModelsList = new QListWidget(this);
  mpRecentModelsList->setItemDelegate(new ItemDelegate(mpRecentModelsList));
  mpRecentModelsList->setTextElideMode(Qt::ElideMiddle);
  mpRecentModelsList->setViewMode(QListView::ListMode);
  mpRecentModelsList->setMovement(QListView::Static);
  connect(mpRecentModelsList, SIGNAL(itemClicked(QListWidgetItem*)), SLOT(openRecentModelWidget(QListWidgetItem*)));
  QGridLayout *pModelSwitcherLayout = new QGridLayout;
  pModelSwitcherLayout->setContentsMargins(0, 0, 0, 0);
  pModelSwitcherLayout->addWidget(mpRecentModelsList, 0, 0);
  mpModelSwitcherDialog->setLayout(pModelSwitcherLayout);
  // install QApplication event filter to handle the ctrl+tab and ctrl+shift+tab
  QApplication::instance()->installEventFilter(this);
  connect(this, SIGNAL(subWindowActivated(QMdiSubWindow*)), SLOT(currentModelWidgetChanged(QMdiSubWindow*)));
  connect(this, SIGNAL(subWindowActivated(QMdiSubWindow*)), mpMainWindow, SLOT(updateModelSwitcherMenu(QMdiSubWindow*)));
  // add actions
  connect(mpMainWindow->getSaveAction(), SIGNAL(triggered()), SLOT(saveModelWidget()));
  connect(mpMainWindow->getSaveAsAction(), SIGNAL(triggered()), SLOT(saveAsModelWidget()));
  connect(mpMainWindow->getSaveTotalModelAction(), SIGNAL(triggered()), SLOT(saveTotalModelWidget()));
  connect(mpMainWindow->getPrintModelAction(), SIGNAL(triggered()), SLOT(printModel()));
}

void ModelWidgetContainer::addModelWidget(ModelWidget *pModelWidget, bool checkPreferedView)
{
  if (pModelWidget->isVisible() || pModelWidget->isMinimized()) {
    QList<QMdiSubWindow*> subWindowsList = subWindowList(QMdiArea::ActivationHistoryOrder);
    for (int i = subWindowsList.size() - 1 ; i >= 0 ; i--) {
      ModelWidget *pSubModelWidget = qobject_cast<ModelWidget*>(subWindowsList.at(i)->widget());
      if (pSubModelWidget == pModelWidget) {
        pModelWidget->createWidgetComponents();
        pModelWidget->show();
        setActiveSubWindow(subWindowsList.at(i));
      }
    }
  } else {
    int subWindowsSize = subWindowList(QMdiArea::ActivationHistoryOrder).size();
    QMdiSubWindow *pSubWindow = addSubWindow(pModelWidget);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/modeling.png"));
    pModelWidget->createWidgetComponents();
    pModelWidget->show();
    if (subWindowsSize == 0) {
      pModelWidget->setWindowState(Qt::WindowMaximized);
    }
    setActiveSubWindow(pSubWindow);
  }
  if (pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Text) {
    pModelWidget->getTextViewToolButton()->setChecked(true);
  }
  else if (pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::TLM) {
    if (pModelWidget->getModelWidgetContainer()->getPreviousViewType() != StringHandler::NoView) {
      loadPreviousViewType(pModelWidget);
    } else {
      pModelWidget->getDiagramViewToolButton()->setChecked(true);
    }
  }
  if (!checkPreferedView || pModelWidget->getLibraryTreeItem()->getLibraryType() != LibraryTreeItem::Modelica) {
    return;
  }
  // get the preferred view to display
  mpMainWindow->getOMCProxy()->sendCommand(QString("getNamedAnnotation(").append(pModelWidget->getLibraryTreeItem()->getNameStructure()).append(", preferredView)"));
  QStringList preferredViewList = StringHandler::unparseStrings(mpMainWindow->getOMCProxy()->getResult());
  if (!preferredViewList.isEmpty()) {
    QString preferredView = preferredViewList.at(0);
    if (preferredView.compare("info") == 0) {
      pModelWidget->showDocumentationView();
      loadPreviousViewType(pModelWidget);
    } else if (preferredView.compare("text") == 0) {
      pModelWidget->getTextViewToolButton()->setChecked(true);
    } else {
      pModelWidget->getDiagramViewToolButton()->setChecked(true);
    }
  } else if (pModelWidget->getLibraryTreeItem()->isDocumentationClass()) {
    pModelWidget->showDocumentationView();
    loadPreviousViewType(pModelWidget);
  } else if (pModelWidget->getModelWidgetContainer()->getPreviousViewType() != StringHandler::NoView) {
    loadPreviousViewType(pModelWidget);
  } else {
    QString defaultView = mpMainWindow->getOptionsDialog()->getGeneralSettingsPage()->getDefaultView();
    if (defaultView.compare(Helper::iconView) == 0) {
      pModelWidget->getIconViewToolButton()->setChecked(true);
    } else if (defaultView.compare(Helper::textView) == 0) {
      pModelWidget->getTextViewToolButton()->setChecked(true);
    } else if (defaultView.compare(Helper::documentationView) == 0) {
      pModelWidget->showDocumentationView();
      loadPreviousViewType(pModelWidget);
    } else {
      pModelWidget->getDiagramViewToolButton()->setChecked(true);
    }
  }
}

ModelWidget* ModelWidgetContainer::getCurrentModelWidget()
{
  if (subWindowList(QMdiArea::ActivationHistoryOrder).size() == 0)
    return 0;
  else
    return qobject_cast<ModelWidget*>(subWindowList(QMdiArea::ActivationHistoryOrder).last()->widget());
}

QMdiSubWindow* ModelWidgetContainer::getCurrentMdiSubWindow()
{
  if (subWindowList(QMdiArea::ActivationHistoryOrder).size() == 0)
    return 0;
  else
    return subWindowList(QMdiArea::ActivationHistoryOrder).last();
}

QMdiSubWindow* ModelWidgetContainer::getMdiSubWindow(ModelWidget *pModelWidget)
{
  if (subWindowList(QMdiArea::ActivationHistoryOrder).size() == 0)
    return 0;
  QList<QMdiSubWindow*> mdiSubWindowsList = subWindowList(QMdiArea::ActivationHistoryOrder);
  foreach (QMdiSubWindow *pMdiSubWindow, mdiSubWindowsList)
  {
    if (pMdiSubWindow->widget() == pModelWidget)
      return pMdiSubWindow;
  }
  return 0;
}

void ModelWidgetContainer::setPreviousViewType(StringHandler::ViewType viewType)
{
  mPreviousViewType = viewType;
}

StringHandler::ViewType ModelWidgetContainer::getPreviousViewType()
{
  return mPreviousViewType;
}

void ModelWidgetContainer::setShowGridLines(bool On)
{
  mShowGridLines = On;
}

bool ModelWidgetContainer::isShowGridLines()
{
  return mShowGridLines;
}

bool ModelWidgetContainer::eventFilter(QObject *object, QEvent *event)
{
  if (!object || isHidden() || qApp->activeWindow() != mpMainWindow) {
    return QMdiArea::eventFilter(object, event);
  }
  // Global key events with Ctrl modifier.
  if (event->type() == QEvent::KeyPress || event->type() == QEvent::KeyRelease) {
    if (subWindowList(QMdiArea::ActivationHistoryOrder).size() > 0) {
      QKeyEvent *keyEvent = static_cast<QKeyEvent*>(event);
      // Ingore key events without a Ctrl modifier (except for press/release on the modifier itself).
#ifdef Q_OS_MAC
      if (!(keyEvent->modifiers() & Qt::AltModifier) && keyEvent->key() != Qt::Key_Alt) {
#else
      if (!(keyEvent->modifiers() & Qt::ControlModifier) && keyEvent->key() != Qt::Key_Control) {
#endif
        return QMdiArea::eventFilter(object, event);
      }
      // check key press
      const bool keyPress = (event->type() == QEvent::KeyPress) ? true : false;
      ModelWidget *pCurrentModelWidget = getCurrentModelWidget();
      switch (keyEvent->key()) {
#ifdef Q_OS_MAC
        case Qt::Key_Alt:
#else
        case Qt::Key_Control:
#endif
          if (keyPress) {
            // add items to mpRecentModelsList to show in mpModelSwitcherDialog
            mpRecentModelsList->clear();
            QList<QMdiSubWindow*> subWindowsList = subWindowList(QMdiArea::ActivationHistoryOrder);
            for (int i = subWindowsList.size() - 1 ; i >= 0 ; i--) {
              ModelWidget *pModelWidget = qobject_cast<ModelWidget*>(subWindowsList.at(i)->widget());
              QListWidgetItem *listItem = new QListWidgetItem(mpRecentModelsList);
              listItem->setText(pModelWidget->getLibraryTreeItem()->getNameStructure());
              listItem->setData(Qt::UserRole, pModelWidget->getLibraryTreeItem()->getNameStructure());
            }
          } else {
            if (!mpRecentModelsList->selectedItems().isEmpty()) {
              openRecentModelWidget(mpRecentModelsList->selectedItems().at(0));
            }
            mpModelSwitcherDialog->hide();
          }
          break;
        case Qt::Key_1: // Ctrl+1 switches to icon view
          if (pCurrentModelWidget) {
            pCurrentModelWidget->getIconViewToolButton()->setChecked(true);
          }
          return true;
        case Qt::Key_2: // Ctrl+2 switches to diagram view
          if (pCurrentModelWidget) {
            pCurrentModelWidget->getDiagramViewToolButton()->setChecked(true);
          }
          return true;
        case Qt::Key_3: // Ctrl+3 switches to text view
          if (pCurrentModelWidget) {
            pCurrentModelWidget->getTextViewToolButton()->setChecked(true);
          }
          return true;
        case Qt::Key_4: // Ctrl+4 shows the documentation view
          if (pCurrentModelWidget) {
            pCurrentModelWidget->showDocumentationView();
          }
          return true;
        case Qt::Key_Tab:
        case Qt::Key_Backtab:
          if (keyPress) {
            if (keyEvent->key() == Qt::Key_Tab) {
              changeRecentModelsListSelection(true);
            } else {
              changeRecentModelsListSelection(false);
            }
          }
          return true;
#ifndef QT_NO_RUBBERBAND
        case Qt::Key_Escape:
          mpModelSwitcherDialog->hide();
          break;
#endif
        default:
          break;
      }
      return QMdiArea::eventFilter(object, event);
    }
  }
  return QMdiArea::eventFilter(object, event);
}

void ModelWidgetContainer::changeRecentModelsListSelection(bool moveDown)
{
  mpModelSwitcherDialog->show();
  mpRecentModelsList->setFocus();
  int count = mpRecentModelsList->count();
  if (count < 1) {
    return;
  }
  int currentRow = mpRecentModelsList->currentRow();
  if (moveDown) {
    if (currentRow < count - 1) {
      mpRecentModelsList->setCurrentRow(currentRow + 1);
    } else {
      mpRecentModelsList->setCurrentRow(0);
    }
  } else if (!moveDown) {
    if (currentRow == 0) {
      mpRecentModelsList->setCurrentRow(count - 1);
    } else {
      mpRecentModelsList->setCurrentRow(currentRow - 1);
    }
  }
}

/*!
 * \brief ModelWidgetContainer::loadPreviousViewType
 * Opens the ModelWidget using the previous view type used by user.
 * \param pModelWidget
 */
void ModelWidgetContainer::loadPreviousViewType(ModelWidget *pModelWidget)
{
  switch (pModelWidget->getModelWidgetContainer()->getPreviousViewType()) {
    case StringHandler::Icon:
      pModelWidget->getIconViewToolButton()->setChecked(true);
      break;
    case StringHandler::ModelicaText:
      pModelWidget->getTextViewToolButton()->setChecked(true);
      break;
    case StringHandler::Diagram:
    default:
      pModelWidget->getDiagramViewToolButton()->setChecked(true);
      break;
  }
}

void ModelWidgetContainer::saveModelicaModelWidget(ModelWidget *pModelWidget)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (!pModelWidget->validateText()) {
    return;
  }
  mpMainWindow->getLibraryWidget()->saveLibraryTreeItem(pModelWidget->getLibraryTreeItem());
}

void ModelWidgetContainer::saveTextModelWidget(ModelWidget *pModelWidget)
{
  mpMainWindow->getLibraryWidget()->saveLibraryTreeItem(pModelWidget->getLibraryTreeItem());
}

void ModelWidgetContainer::saveTLMModelWidget(ModelWidget *pModelWidget)
{
  mpMainWindow->getLibraryWidget()->saveLibraryTreeItem(pModelWidget->getLibraryTreeItem());
}

void ModelWidgetContainer::openRecentModelWidget(QListWidgetItem *pItem)
{
  LibraryTreeItem *pLibraryTreeItem = mpMainWindow->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(pItem->data(Qt::UserRole).toString());
  addModelWidget(pLibraryTreeItem->getModelWidget(), false);
}

void ModelWidgetContainer::currentModelWidgetChanged(QMdiSubWindow *pSubWindow)
{
  bool enabled, modelica, text, TLM;
  ModelWidget *pModelWidget;
  LibraryTreeItem *pLibraryTreeItem;
  if (pSubWindow) {
    enabled = true;
    pModelWidget = qobject_cast<ModelWidget*>(pSubWindow->widget());
    pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
    if (pLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
      modelica = true;
      text = false;
      TLM = false;
    } else if (pLibraryTreeItem->getLibraryType() == LibraryTreeItem::Text) {
      modelica = false;
      text = true;
      TLM = false;
    } else {
      modelica = false;
      text = false;
      TLM = true;
    }
  } else {
    enabled = false;
    modelica = false;
    text = false;
    TLM = false;
    pModelWidget = 0;
    pLibraryTreeItem = 0;
  }
  // update the actions of the menu and toolbars
  getMainWindow()->getSaveAction()->setEnabled(enabled);
  //  getMainWindow()->getSaveAsAction()->setEnabled(enabled);
  //  getMainWindow()->getSaveAllAction()->setEnabled(enabled);
  getMainWindow()->getSaveTotalModelAction()->setEnabled(enabled && modelica);
  getMainWindow()->getShowGridLinesAction()->setEnabled(enabled && !pModelWidget->getLibraryTreeItem()->isSystemLibrary());
  getMainWindow()->getResetZoomAction()->setEnabled(enabled && modelica);
  getMainWindow()->getZoomInAction()->setEnabled(enabled && modelica);
  getMainWindow()->getZoomOutAction()->setEnabled(enabled && modelica);
  getMainWindow()->getSimulateModelAction()->setEnabled(enabled && modelica && pLibraryTreeItem->isSimulationAllowed());
  getMainWindow()->getSimulateWithTransformationalDebuggerAction()->setEnabled(enabled && modelica && pLibraryTreeItem->isSimulationAllowed());
  getMainWindow()->getSimulateWithAlgorithmicDebuggerAction()->setEnabled(enabled && modelica && pLibraryTreeItem->isSimulationAllowed());
  getMainWindow()->getSimulationSetupAction()->setEnabled(enabled && modelica && pLibraryTreeItem->isSimulationAllowed());
  getMainWindow()->getInstantiateModelAction()->setEnabled(enabled && modelica);
  getMainWindow()->getCheckModelAction()->setEnabled(enabled && modelica);
  getMainWindow()->getCheckAllModelsAction()->setEnabled(enabled && modelica);
  getMainWindow()->getExportFMUAction()->setEnabled(enabled && modelica);
  getMainWindow()->getExportXMLAction()->setEnabled(enabled && modelica);
  getMainWindow()->getExportFigaroAction()->setEnabled(enabled && modelica);
  getMainWindow()->getExportToOMNotebookAction()->setEnabled(enabled && modelica);
  getMainWindow()->getExportAsImageAction()->setEnabled(enabled && modelica);
  getMainWindow()->getExportToClipboardAction()->setEnabled(enabled && modelica);
  getMainWindow()->getPrintModelAction()->setEnabled(enabled);
  getMainWindow()->getFetchInterfaceDataAction()->setEnabled(enabled && TLM);
  getMainWindow()->getTLMSimulationAction()->setEnabled(enabled && TLM);
  /* disable the save actions if class is a system library class. */
  if (pModelWidget) {
    if (pModelWidget->getLibraryTreeItem()->isSystemLibrary()) {
      getMainWindow()->getSaveAction()->setEnabled(false);
      getMainWindow()->getSaveAsAction()->setEnabled(false);
      getMainWindow()->getSaveAllAction()->setEnabled(false);
    }
    // update the Undo/Redo actions
    pModelWidget->updateUndoRedoActions();
  }
  /* enable/disable the find/replace and goto line actions depending on the text editor visibility. */
  if (pModelWidget && pModelWidget->getEditor()->isVisible()) {
    if (pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
      enabled = true;
    } else if (pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Text) {
      enabled = true;
    } else {
      enabled = false;
    }
  } else {
    enabled = false;
  }
}

void ModelWidgetContainer::saveModelWidget()
{
  ModelWidget *pModelWidget = getCurrentModelWidget();
  // if pModelWidget = 0
  if (!pModelWidget) {
    QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                             GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN).arg(tr("saving")), Helper::ok);
    return;
  }
  LibraryTreeItem *pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
  if (pLibraryTreeItem && pLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
    saveModelicaModelWidget(pModelWidget);
  } else if (pLibraryTreeItem && pLibraryTreeItem->getLibraryType() == LibraryTreeItem::Text) {
    saveTextModelWidget(pModelWidget);
  } else if (pLibraryTreeItem && pLibraryTreeItem->getLibraryType() == LibraryTreeItem::TLM) {
    saveTLMModelWidget(pModelWidget);
  }
}

void ModelWidgetContainer::saveAsModelWidget()
{
  ModelWidget *pModelWidget = getCurrentModelWidget();
  // if pModelWidget = 0
  if (!pModelWidget)
  {
    QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                             GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN).arg(tr("save as")), Helper::ok);
    return;
  }
  /* if user has done some changes in the Modelica text view then save & validate it in the AST before saving it to file. */
  ModelicaTextEditor *pModelicaTextEditor = dynamic_cast<ModelicaTextEditor*>(pModelWidget->getEditor());
  if (pModelicaTextEditor && !pModelicaTextEditor->validateText()) {
    return;
  }
  SaveAsClassDialog *pSaveAsClassDialog = new SaveAsClassDialog(pModelWidget, mpMainWindow);
  pSaveAsClassDialog->exec();
  saveModelWidget();
}

void ModelWidgetContainer::saveTotalModelWidget()
{
  ModelWidget *pModelWidget = getCurrentModelWidget();
  // if pModelWidget = 0
  if (!pModelWidget)
  {
    QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                             GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN).arg(tr("saving")), Helper::ok);
    return;
  }
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (!pModelWidget->validateText()) {
    return;
  }
  /* save total model */
  LibraryTreeItem *pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
  mpMainWindow->getStatusBar()->showMessage(QString(tr("Saving")).append(" ").append(pLibraryTreeItem->getNameStructure()));
  mpMainWindow->showProgressBar();
  QString fileName;
  QString name = pLibraryTreeItem->getName();
  fileName = StringHandler::getSaveFileName(this, QString(Helper::applicationName).append(" - ").append(tr("Save Total Model")), NULL,
                                            Helper::omFileTypes, NULL, "mo", &name);
  if (fileName.isEmpty()) { // if user press ESC
    return;
  }
  // save the model through OMC
  mpMainWindow->getOMCProxy()->saveTotalSCode(fileName, pLibraryTreeItem->getNameStructure());
  mpMainWindow->getStatusBar()->clearMessage();
  mpMainWindow->hideProgressBar();
}

/*!
  Slot activated when MainWindow::mpPrintModelAction triggered SIGNAL is raised.
  Prints the model Icon/Diagram/Text depending on which one is visible.
  */
void ModelWidgetContainer::printModel()
{
#ifndef QT_NO_PRINTER
  if (ModelWidget *pModelWidget = getCurrentModelWidget()) {
    QPrinter printer(QPrinter::ScreenResolution);
    QPrintDialog *pPrintDialog = new QPrintDialog(&printer);

    // print the text of the model if it is visible
    if (pModelWidget->getEditor()->isVisible()) {
      ModelicaTextEditor *pModelicaTextEditor = dynamic_cast<ModelicaTextEditor*>(pModelWidget->getEditor());
      // set print options if text is selected
      if (pModelicaTextEditor->getPlainTextEdit()->textCursor().hasSelection()) {
        pPrintDialog->addEnabledOption(QAbstractPrintDialog::PrintSelection);
      }
      // open print dialog
      if (pPrintDialog->exec() == QDialog::Accepted) {
        pModelicaTextEditor->getPlainTextEdit()->print(&printer);
      }
    } else {
      // print the model Diagram/Icon
      GraphicsView *pGraphicsView = 0;
      if (pModelWidget->getIconGraphicsView()->isVisible()) {
        pGraphicsView = pModelWidget->getIconGraphicsView();
      } else {
        pGraphicsView = pModelWidget->getDiagramGraphicsView();
      }
      // hide the background of the view for printing
      bool oldSkipDrawBackground = pGraphicsView->mSkipBackground;
      pGraphicsView->mSkipBackground = true;
      // open print dialog
      if (pPrintDialog->exec() == QDialog::Accepted) {
        QPainter painter(&printer);
        painter.setRenderHints(QPainter::Antialiasing);
        pGraphicsView->render(&painter);
        painter.end();
      }
      pGraphicsView->mSkipBackground = oldSkipDrawBackground;
    }
    delete pPrintDialog;
  }
#endif
}
