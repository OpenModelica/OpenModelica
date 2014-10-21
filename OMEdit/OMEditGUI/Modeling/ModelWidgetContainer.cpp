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

CoOrdinateSystem::CoOrdinateSystem()
{

}

void CoOrdinateSystem::setExtent(QList<QPointF> extent)
{
  mExtent = extent;
}

QList<QPointF> CoOrdinateSystem::getExtent()
{
  return mExtent;
}

void CoOrdinateSystem::setPreserveAspectRatio(bool PreserveAspectRatio)
{
  mPreserveAspectRatio = PreserveAspectRatio;
}

bool CoOrdinateSystem::getPreserveAspectRatio()
{
  return mPreserveAspectRatio;
}

void CoOrdinateSystem::setInitialScale(qreal initialScale)
{
  mInitialScale = initialScale;
}

qreal CoOrdinateSystem::getInitialScale()
{
  return mInitialScale;
}

void CoOrdinateSystem::setGrid(QPointF grid)
{
  mGrid = grid;
}

QPointF CoOrdinateSystem::getGrid()
{
  return mGrid;
}

qreal CoOrdinateSystem::getHorizontalGridStep()
{
  if (mGrid.x() < 1)
    return 20;
  return mGrid.x() * 10;
}

qreal CoOrdinateSystem::getVerticalGridStep()
{
  if (mGrid.y() < 1)
    return 20;
  return mGrid.y() * 10;
}

//! @class GraphicsScene
//! @brief The GraphicsScene class is a container for graphicsl components in a simulationmodel.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
GraphicsScene::GraphicsScene(int iconType, ModelWidget *parent)
  : QGraphicsScene(parent), mIconType(iconType)
{
  mpModelWidget = parent;
}

//! @class GraphicsView
//! @brief The GraphicsView class is a class which display the content of a scene of components.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
GraphicsView::GraphicsView(StringHandler::ViewType viewType, ModelWidget *parent)
  : QGraphicsView(parent), mViewType(viewType), mSkipBackground(false)
{
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
  setSceneRect(left, bottom, fabs(left - right), fabs(bottom - top));
  centerOn(sceneRect().center());
  scale(1.0, -1.0);     // invert the drawing area.
  setStyleSheet(QString("QGraphicsView{background-color: lightGray;}"));
  setIsCustomScale(false);
  setCanAddClassAnnotation(true);
  setIsCreatingConnection(false);
  setDeleteCreatingConnection(false);
  setIsCreatingLineShape(false);
  setIsCreatingPolygonShape(false);
  setIsCreatingRectangleShape(false);
  setIsCreatingEllipseShape(false);
  setIsCreatingTextShape(false);
  setIsCreatingBitmapShape(false);
  setIsMovingComponentsAndShapes(false);
  createActions();
}

StringHandler::ViewType GraphicsView::getViewType()
{
  return mViewType;
}

ModelWidget* GraphicsView::getModelWidget()
{
  return mpModelWidget;
}

CoOrdinateSystem* GraphicsView::getCoOrdinateSystem()
{
  return mpCoOrdinateSystem;
}

void GraphicsView::setIsCustomScale(bool enable)
{
  mIsCustomScale = enable;
}

bool GraphicsView::isCustomScale()
{
  return mIsCustomScale;
}

void GraphicsView::setCanAddClassAnnotation(bool enable)
{
  mCanAddClassAnnotation = enable;
}

bool GraphicsView::canAddClassAnnotation()
{
  return mCanAddClassAnnotation;
}

void GraphicsView::setIsCreatingConnection(bool enable)
{
  mIsCreatingConnection = enable;
}

bool GraphicsView::isCreatingConnection()
{
  return mIsCreatingConnection;
}

void GraphicsView::setDeleteCreatingConnection(bool enable)
{
  mDeleteCreatingConnection = enable;
}

bool GraphicsView::canDeleteCreatingConnection()
{
  return mDeleteCreatingConnection;
}

void GraphicsView::setIsCreatingLineShape(bool enable)
{
  mIsCreatingLineShape = enable;
}

bool GraphicsView::isCreatingLineShape()
{
  return mIsCreatingLineShape;
}

void GraphicsView::setIsCreatingPolygonShape(bool enable)
{
  mIsCreatingPolygonShape = enable;
}

bool GraphicsView::isCreatingPolygonShape()
{
  return mIsCreatingPolygonShape;
}

void GraphicsView::setIsCreatingRectangleShape(bool enable)
{
  mIsCreatingRectangleShape = enable;
}

bool GraphicsView::isCreatingRectangleShape()
{
  return mIsCreatingRectangleShape;
}

void GraphicsView::setIsCreatingEllipseShape(bool enable)
{
  mIsCreatingEllipseShape = enable;
}

bool GraphicsView::isCreatingEllipseShape()
{
  return mIsCreatingEllipseShape;
}

void GraphicsView::setIsCreatingTextShape(bool enable)
{
  mIsCreatingTextShape = enable;
}

bool GraphicsView::isCreatingTextShape()
{
  return mIsCreatingTextShape;
}

void GraphicsView::setIsCreatingBitmapShape(bool enable)
{
  mIsCreatingBitmapShape = enable;
}

bool GraphicsView::isCreatingBitmapShape()
{
  return mIsCreatingBitmapShape;
}

void GraphicsView::setIsMovingComponentsAndShapes(bool enable)
{
  mIsMovingComponentsAndShapes = enable;
}

bool GraphicsView::isMovingComponentsAndShapes()
{
  return mIsMovingComponentsAndShapes;
}

QAction* GraphicsView::getDeleteConnectionAction()
{
  return mpDeleteConnectionAction;
}

QAction* GraphicsView::getDeleteAction()
{
  return mpDeleteAction;
}

QAction* GraphicsView::getDuplicateAction()
{
  return mpDuplicateAction;
}

QAction* GraphicsView::getRotateClockwiseAction()
{
  return mpRotateClockwiseAction;
}

QAction* GraphicsView::getRotateAntiClockwiseAction()
{
  return mpRotateAntiClockwiseAction;
}

QAction* GraphicsView::getFlipHorizontalAction()
{
  return mpFlipHorizontalAction;
}

QAction* GraphicsView::getFlipVerticalAction()
{
  return mpFlipVerticalAction;
}

bool GraphicsView::addComponent(QString className, QPointF position)
{
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
  LibraryTreeNode *pLibraryTreeNode;
  pLibraryTreeNode = mpModelWidget->getModelWidgetContainer()->getMainWindow()->getLibraryTreeWidget()->getLibraryTreeNode(className);
  if (!pLibraryTreeNode)
    return false;
  StringHandler::ModelicaClasses type = pLibraryTreeNode->getModelicaType();
  QString name = pLibraryTreeNode->getName();
  OptionsDialog *pOptionsDialog = mpModelWidget->getModelWidgetContainer()->getMainWindow()->getOptionsDialog();
  // item not to be dropped on itself; if dropping an item on itself
  if (mpModelWidget->getLibraryTreeNode()->getNameStructure().compare(pLibraryTreeNode->getNameStructure()) == 0)
  {
    if (pOptionsDialog->getNotificationsPage()->getItemDroppedOnItselfCheckBox()->isChecked())
    {
      NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::ItemDroppedOnItself,
                                                                          NotificationsDialog::InformationIcon,
                                                                          mpModelWidget->getModelWidgetContainer()->getMainWindow());
      pNotificationsDialog->exec();
    }
    return false;
  }
  else
  {
    // check if the model is partial
    if (pMainWindow->getOMCProxy()->isPartial(className))
    {
      if (pOptionsDialog->getNotificationsPage()->getReplaceableIfPartialCheckBox()->isChecked())
      {
        NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::ReplaceableIfPartial,
                                                                            NotificationsDialog::InformationIcon,
                                                                            mpModelWidget->getModelWidgetContainer()->getMainWindow());
        pNotificationsDialog->setNotificationLabelString(GUIMessages::getMessage(GUIMessages::MAKE_REPLACEABLE_IF_PARTIAL)
                                                         .arg(StringHandler::getModelicaClassType(type).toLower()).arg(name));
        if (!pNotificationsDialog->exec())
          return false;
      }
    }
    // get the model defaultComponentPrefixes
    QString defaultPrefix = pMainWindow->getOMCProxy()->getDefaultComponentPrefixes(className);
    // get the model defaultComponentName
    QString defaultName = pMainWindow->getOMCProxy()->getDefaultComponentName(className);
    if (defaultName.isEmpty())
    {
      name = getUniqueComponentName(name.toLower());
    }
    else
    {
      if (checkComponentName(defaultName))
        name = defaultName;
      else
      {
        name = getUniqueComponentName(name.toLower());
        // show the information to the user if we have changed the name of some inner component.
        if (defaultPrefix.contains("inner"))
        {
          if (pOptionsDialog->getNotificationsPage()->getInnerModelNameChangedCheckBox()->isChecked())
          {
            NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::InnerModelNameChanged,
                                                                                NotificationsDialog::InformationIcon,
                                                                                mpModelWidget->getModelWidgetContainer()->getMainWindow());
            pNotificationsDialog->setNotificationLabelString(GUIMessages::getMessage(GUIMessages::INNER_MODEL_NAME_CHANGED)
                                                             .arg(defaultName).arg(name));
            if (!pNotificationsDialog->exec())
              return false;
          }
        }
      }
    }
    // if dropping an item on the diagram layer
    if (mViewType == StringHandler::Diagram)
    {
      // if item is a class, model, block, connector or record. then we can drop it to the graphicsview
      if ((type == StringHandler::Class) or (type == StringHandler::Model) or (type == StringHandler::Block) or
          (type == StringHandler::Connector) or (type == StringHandler::Record))
      {
        if (type == StringHandler::Connector)
        {
          addComponentToView(name, className, "", position, 0, type, false);
          mpModelWidget->getIconGraphicsView()->addComponentToView(name, className, "", position, 0, type);
          /* When something is added in the icon layer then update the LibraryTreeNode in the Library Browser */
          pMainWindow->getLibraryTreeWidget()->loadLibraryComponent(mpModelWidget->getLibraryTreeNode());
        }
        else
        {
          addComponentToView(name, className, "", position, 0, type);
        }
        return true;
      }
      else
      {
        QMessageBox::information(pMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::information),
                                 GUIMessages::getMessage(GUIMessages::DIAGRAM_VIEW_DROP_MSG).arg(className)
                                 .arg(StringHandler::getModelicaClassType(type)), Helper::ok);
        return false;
      }
    }
    // if dropping an item on the icon layer
    else if (mViewType == StringHandler::Icon)
    {
      // if item is a connector. then we can drop it to the graphicsview
      if (type == StringHandler::Connector)
      {
        addComponentToView(name, className, "", position, 0, type, false);
        mpModelWidget->getDiagramGraphicsView()->addComponentToView(name, className, "", position, 0, type);
        /* When something is added in the icon layer then update the LibraryTreeNode in the Library Browser */
        pMainWindow->getLibraryTreeWidget()->loadLibraryComponent(mpModelWidget->getLibraryTreeNode());
        return true;
      }
      else
      {
        QMessageBox::information(pMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::information),
                                 GUIMessages::getMessage(GUIMessages::ICON_VIEW_DROP_MSG).arg(className)
                                 .arg(StringHandler::getModelicaClassType(type)), Helper::ok);
        return false;
      }
    }
  }
  return false;
}

void GraphicsView::addComponentToView(QString name, QString className, QString transformationString, QPointF point,
                                      ComponentInfo *pComponentInfo, StringHandler::ModelicaClasses type, bool addObject, bool openingClass,
                                      bool inheritedClass, QString inheritedClassName)
{
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
  QString annotation;
  // if the component is a connector then we nned to get the diagram annotation of it.
  if (type == StringHandler::Connector && mViewType == StringHandler::Diagram)
    annotation = pMainWindow->getOMCProxy()->getDiagramAnnotation(className);
  else
    annotation = pMainWindow->getOMCProxy()->getIconAnnotation(className);
  Component *pComponent = new Component(annotation, name, className, pComponentInfo, type, transformationString, point, inheritedClass,
                                        inheritedClassName, pMainWindow->getOMCProxy(), this);
  if (!openingClass)
  {
    // unselect all items
    foreach (QGraphicsItem *pItem, items())
    {
      pItem->setSelected(false);
    }
    pComponent->setSelected(true);
  }
  if (addObject)
    addComponentObject(pComponent);
  else
    mComponentsList.append(pComponent);
}

void GraphicsView::addComponentObject(Component *pComponent)
{
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
  // Add the component to model in OMC Global Scope.
  pMainWindow->getOMCProxy()->addComponent(pComponent->getName(), pComponent->getClassName(),
                                           mpModelWidget->getLibraryTreeNode()->getNameStructure(), pComponent->getPlacementAnnotation());
  // make the model modified
  mpModelWidget->setModelModified();
  // add the component to the local list
  mComponentsList.append(pComponent);
}

//! Delete the component and its corresponding connectors from the components list and OMC.
//! @param component is the object to be deleted.
//! @param update flag is used to check whether we need to update the modelica editor text or not.
//! @see deleteAllComponentObjects()
void GraphicsView::deleteComponentObject(Component *pComponent)
{
  // First Remove the Connector associated to this component
  int i = 0;
  while(i != mConnectionsList.size())
  {
    QString startComponentName, endComponentName = "";
    if (mConnectionsList[i]->getStartComponent())
      startComponentName = mConnectionsList[i]->getStartComponent()->getRootParentComponent()->getName();
    if (mConnectionsList[i]->getEndComponent())
      endComponentName = mConnectionsList[i]->getEndComponent()->getRootParentComponent()->getName();

    if (startComponentName == pComponent->getName() || endComponentName == pComponent->getName())
    {
      removeConnection(mConnectionsList[i]);
      i = 0;   //Restart iteration if map has changed
    }
    else
    {
      ++i;
    }
  }
  // remove the component now from local list
  mComponentsList.removeOne(pComponent);
  OMCProxy *pOMCProxy = mpModelWidget->getModelWidgetContainer()->getMainWindow()->getOMCProxy();
  // delete the component from OMC
  pOMCProxy->deleteComponent(pComponent->getName(), mpModelWidget->getLibraryTreeNode()->getNameStructure());
}

Component* GraphicsView::getComponentObject(QString componentName)
{
  foreach (Component *component, mComponentsList)
  {
    if (component->getName() == componentName)
      return component;
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

QList<Component*> GraphicsView::getComponentList()
{
  return mComponentsList;
}

void GraphicsView::createConnection(QString startComponentName, QString endComponentName)
{
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
  if (pMainWindow->getOMCProxy()->addConnection(startComponentName, endComponentName, mpModelWidget->getLibraryTreeNode()->getNameStructure(),
                                                QString("annotate=").append(mpConnectionLineAnnotation->getShapeAnnotation())))
  {
    /* Ticket #2450
       Do not check for the ports compatibility via instantiatemodel. Just let the user create the connection.
       //pMainWindow->getOMCProxy()->instantiateModelSucceeds(mpModelWidget->getNameStructure());
      */
    /* complete the connection */
    setIsCreatingConnection(false);
    mpConnectionLineAnnotation->setStartComponentName(startComponentName);
    mpConnectionLineAnnotation->setEndComponentName(endComponentName);
    Component *pEndComponent = mpConnectionLineAnnotation->getEndComponent();
    if (pEndComponent->getParentComponent())
      pEndComponent->getParentComponent()->addConnectionDetails(mpConnectionLineAnnotation);
    else
      pEndComponent->addConnectionDetails(mpConnectionLineAnnotation);
    // update the last point to the center of component
    QPointF newPos = pEndComponent->mapToScene(pEndComponent->boundingRect().center());
    mpConnectionLineAnnotation->updateEndPoint(newPos);
    mpConnectionLineAnnotation->update();
    mConnectionsList.append(mpConnectionLineAnnotation);
    // make the model modified
    mpModelWidget->setModelModified();
  }
}

//! Deletes the connection from OMC.
//! @param startComponentName is starting component name string.
//! @param endComponentName is ending component name string.
void GraphicsView::deleteConnection(QString startComponentName, QString endComponentName)
{
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
  pMainWindow->getOMCProxy()->deleteConnection(startComponentName, endComponentName, mpModelWidget->getLibraryTreeNode()->getNameStructure());
  // make the model modified
  mpModelWidget->setModelModified();
}

void GraphicsView::addConnectionObject(LineAnnotation *pConnectionLineAnnotation)
{
  mConnectionsList.append(pConnectionLineAnnotation);
}

void GraphicsView::deleteConnectionObject(LineAnnotation *pConnectionLineAnnotation)
{
  mConnectionsList.removeOne(pConnectionLineAnnotation);
}

void GraphicsView::addShapeObject(ShapeAnnotation *pShape)
{
  mShapesList.append(pShape);
}

void GraphicsView::deleteShapeObject(ShapeAnnotation *pShape)
{
  // remove the shape from local list
  mShapesList.removeOne(pShape);
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
  if (mpModelWidget->getLibraryTreeNode()->isSystemLibrary())
    return;

  if (!isCreatingLineShape())
  {
    setIsCreatingLineShape(true);
    mpLineShapeAnnotation = new LineAnnotation("", false, this);
    mpLineShapeAnnotation->addPoint(point);
    mpLineShapeAnnotation->addPoint(point);
  }
  // if we are already creating a line then only add one point.
  else
  {
    mpLineShapeAnnotation->addPoint(point);
  }
}

void GraphicsView::createPolygonShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeNode()->isSystemLibrary())
    return;

  if (!isCreatingPolygonShape())
  {
    setIsCreatingPolygonShape(true);
    mpPolygonShapeAnnotation = new PolygonAnnotation("", false, this);
    mpPolygonShapeAnnotation->addPoint(point);
    mpPolygonShapeAnnotation->addPoint(point);
    mpPolygonShapeAnnotation->addPoint(point);
  }
  // if we are already creating a polygon then only add one point.
  else
  {
    mpPolygonShapeAnnotation->addPoint(point);
  }
}

void GraphicsView::createRectangleShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeNode()->isSystemLibrary())
    return;

  if (!isCreatingRectangleShape())
  {
    setIsCreatingRectangleShape(true);
    mpRectangleShapeAnnotation = new RectangleAnnotation("", false, this);
    mpRectangleShapeAnnotation->replaceExtent(0, point);
    mpRectangleShapeAnnotation->replaceExtent(1, point);
  }
  // if we are already creating a rectangle then finish creating it.
  else
  {
    MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
    // set the transformation matrix
    mpRectangleShapeAnnotation->setOrigin(mpRectangleShapeAnnotation->sceneBoundingRect().center());
    mpRectangleShapeAnnotation->adjustExtentsWithOrigin();
    mpRectangleShapeAnnotation->initializeTransformation();
    // draw corner items for the rectangle shape
    mpRectangleShapeAnnotation->drawCornerItems();
    mpRectangleShapeAnnotation->setSelected(true);
    // finish creating the rectangle
    setIsCreatingRectangleShape(false);
    // make the toolbar button of rectangle unchecked
    pMainWindow->getRectangleShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    addClassAnnotation();
    setCanAddClassAnnotation(true);
  }
}

void GraphicsView::createEllipseShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeNode()->isSystemLibrary())
    return;

  if (!isCreatingEllipseShape())
  {
    setIsCreatingEllipseShape(true);
    mpEllipseShapeAnnotation = new EllipseAnnotation("", false, this);
    mpEllipseShapeAnnotation->replaceExtent(0, point);
    mpEllipseShapeAnnotation->replaceExtent(1, point);
  }
  // if we are already creating an ellipse then finish creating it.
  else
  {
    MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
    // set the transformation matrix
    mpEllipseShapeAnnotation->setOrigin(mpEllipseShapeAnnotation->sceneBoundingRect().center());
    mpEllipseShapeAnnotation->adjustExtentsWithOrigin();
    mpEllipseShapeAnnotation->initializeTransformation();
    // draw corner items for the ellipse shape
    mpEllipseShapeAnnotation->drawCornerItems();
    mpEllipseShapeAnnotation->setSelected(true);
    // finish creating the ellipse
    setIsCreatingEllipseShape(false);
    // make the toolbar button of ellipse unchecked
    pMainWindow->getEllipseShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    addClassAnnotation();
    setCanAddClassAnnotation(true);
  }
}

void GraphicsView::createTextShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeNode()->isSystemLibrary())
    return;

  if (!isCreatingTextShape())
  {
    setIsCreatingTextShape(true);
    mpTextShapeAnnotation = new TextAnnotation("", false, this);
    mpTextShapeAnnotation->setTextString("text");
    mpTextShapeAnnotation->replaceExtent(0, point);
    mpTextShapeAnnotation->replaceExtent(1, point);
  }
  // if we are already creating a text then finish creating it.
  else
  {
    MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
    // set the transformation matrix
    mpTextShapeAnnotation->setOrigin(mpTextShapeAnnotation->sceneBoundingRect().center());
    mpTextShapeAnnotation->adjustExtentsWithOrigin();
    mpTextShapeAnnotation->initializeTransformation();
    // draw corner items for the text shape
    mpTextShapeAnnotation->drawCornerItems();
    mpTextShapeAnnotation->setSelected(true);
    // finish creating the text
    setIsCreatingTextShape(false);
    // make the toolbar button of text unchecked
    pMainWindow->getTextShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    addClassAnnotation();
    setCanAddClassAnnotation(true);
    mpTextShapeAnnotation->showShapeProperties();
  }
}

void GraphicsView::createBitmapShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeNode()->isSystemLibrary())
    return;

  if (!isCreatingBitmapShape())
  {
    setIsCreatingBitmapShape(true);
    mpBitmapShapeAnnotation = new BitmapAnnotation(mpModelWidget->getLibraryTreeNode()->getFileName(), "", false, this);
    mpBitmapShapeAnnotation->replaceExtent(0, point);
    mpBitmapShapeAnnotation->replaceExtent(1, point);
  }
  // if we are already creating a bitmap then finish creating it.
  else
  {
    MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
    // set the transformation matrix
    mpBitmapShapeAnnotation->setOrigin(mpBitmapShapeAnnotation->sceneBoundingRect().center());
    mpBitmapShapeAnnotation->adjustExtentsWithOrigin();
    mpBitmapShapeAnnotation->initializeTransformation();
    // draw corner items for the bitmap shape
    mpBitmapShapeAnnotation->drawCornerItems();
    mpBitmapShapeAnnotation->setSelected(true);
    // finish creating the bitmap
    setIsCreatingBitmapShape(false);
    ShapePropertiesDialog *pShapePropertiesDialog;
    pShapePropertiesDialog = new ShapePropertiesDialog(mpBitmapShapeAnnotation,
                                                       mpModelWidget->getModelWidgetContainer()->getMainWindow());
    if (!pShapePropertiesDialog->exec())
    {
      /* if user cancels the bitmap shape properties then remove the bitmap shape from the scene */
      deleteShapeObject(mpBitmapShapeAnnotation);
      mpBitmapShapeAnnotation->deleteLater();
    }
    // make the toolbar button of text unchecked
    pMainWindow->getBitmapShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
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

void GraphicsView::createActions()
{
  bool isSystemLibrary = mpModelWidget->getLibraryTreeNode()->isSystemLibrary();
  // Graphics View Properties Action
  mpPropertiesAction = new QAction(Helper::properties, this);
  connect(mpPropertiesAction, SIGNAL(triggered()), SLOT(showGraphicsViewProperties()));
  // Connection Delete Action
  mpCancelConnectionAction = new QAction(QIcon(":/Resources/icons/delete.svg"), tr("Cancel Connection"), this);
  mpCancelConnectionAction->setStatusTip(tr("Cancels the current connection"));
  connect(mpCancelConnectionAction, SIGNAL(triggered()), SLOT(removeConnection()));
  // Connection Delete Action
  mpDeleteConnectionAction = new QAction(QIcon(":/Resources/icons/delete.svg"), tr("Delete Connection"), this);
  mpDeleteConnectionAction->setStatusTip(tr("Deletes the connection"));
  mpDeleteConnectionAction->setShortcut(QKeySequence::Delete);
  mpDeleteConnectionAction->setDisabled(isSystemLibrary);
  // Actions for Components
  // Delete Action
  mpDeleteAction = new QAction(QIcon(":/Resources/icons/delete.svg"), Helper::deleteStr, this);
  mpDeleteAction->setStatusTip(tr("Deletes the item"));
  mpDeleteAction->setShortcut(QKeySequence::Delete);
  mpDeleteAction->setDisabled(isSystemLibrary);
  // Duplicate Action
  mpDuplicateAction = new QAction(QIcon(":/Resources/icons/duplicate.png"), tr("Duplicate"), this);
  mpDuplicateAction->setStatusTip(tr("Duplicates the item"));
  mpDuplicateAction->setShortcut(QKeySequence("Ctrl+d"));
  mpDuplicateAction->setDisabled(isSystemLibrary);
  // Rotate ClockWise Action
  mpRotateClockwiseAction = new QAction(QIcon(":/Resources/icons/rotateclockwise.png"), tr("Rotate Clockwise"), this);
  mpRotateClockwiseAction->setStatusTip(tr("Rotates the item clockwise"));
  mpRotateClockwiseAction->setShortcut(QKeySequence("Ctrl+r"));
  mpRotateClockwiseAction->setDisabled(isSystemLibrary);
  // Rotate Anti-ClockWise Action
  mpRotateAntiClockwiseAction = new QAction(QIcon(":/Resources/icons/rotateanticlockwise.png"), tr("Rotate Anticlockwise"), this);
  mpRotateAntiClockwiseAction->setStatusTip(tr("Rotates the item anticlockwise"));
  mpRotateAntiClockwiseAction->setShortcut(QKeySequence("Ctrl+Shift+r"));
  mpRotateAntiClockwiseAction->setDisabled(isSystemLibrary);
  // Flip Horizontal Action
  mpFlipHorizontalAction = new QAction(QIcon(":/Resources/icons/flip-horizontal.png"), tr("Flip Horizontal"), this);
  mpFlipHorizontalAction->setStatusTip(tr("Flips the item horizontally"));
  mpFlipHorizontalAction->setDisabled(isSystemLibrary);
  // Flip Vertical Action
  mpFlipVerticalAction = new QAction(QIcon(":/Resources/icons/flip-vertical.png"), tr("Flip Vertical"), this);
  mpFlipVerticalAction->setStatusTip(tr("Flips the item vertically"));
  mpFlipVerticalAction->setDisabled(isSystemLibrary);
}

void GraphicsView::addConnection(Component *pComponent)
{
  // When clicking the start component
  if (!isCreatingConnection())
  {
    QPointF startPos = pComponent->mapToScene(pComponent->boundingRect().center());
    mpConnectionLineAnnotation = new LineAnnotation(pComponent, this);
    setIsCreatingConnection(true);
    // if component is a connector
    Component *pRootParentComponent = pComponent->getRootParentComponent();
    if (pRootParentComponent)
      pRootParentComponent->addConnectionDetails(mpConnectionLineAnnotation);
    else
      pComponent->addConnectionDetails(mpConnectionLineAnnotation);
    mpConnectionLineAnnotation->addPoint(startPos);
    mpConnectionLineAnnotation->addPoint(startPos);
    mpConnectionLineAnnotation->addPoint(startPos);
  }
  // When clicking the end component
  else if (isCreatingConnection())
  {
    mpConnectionLineAnnotation->setEndComponent(pComponent);
    Component *pStartComponent = mpConnectionLineAnnotation->getStartComponent();
    MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
    if (pStartComponent == pComponent)
    {
      QMessageBox::information(pMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::information),
                               GUIMessages::getMessage(GUIMessages::SAME_COMPONENT_CONNECT), Helper::ok);
      /* Ticket #2162 : We don't delete the connection here instead we set the flag and delete the connection in mousepressevent.
         Deleting the connection here raises weird mousemoveevent segfaults, i don't know why :).
        */
      setDeleteCreatingConnection(true);
    }
    else
    {
      bool showConnectionArrayDialog = false;
      if (pStartComponent->getComponentInfo())
        if (pStartComponent->getComponentInfo()->isArray())
          showConnectionArrayDialog = true;
      if (pComponent->getComponentInfo())
        if (pComponent->getComponentInfo()->isArray())
          showConnectionArrayDialog = true;
      if (showConnectionArrayDialog)
      {
        ConnectionArray *pConnectionArray = new ConnectionArray(this, mpConnectionLineAnnotation,
                                                                getModelWidget()->getModelWidgetContainer()->getMainWindow());
        pConnectionArray->show();
      }
      else
      {
        QString startComponentName, endComponentName;
        if (pStartComponent->getParentComponent())
          startComponentName = QString(pStartComponent->getRootParentComponent()->getName()).append(".").append(pStartComponent->getComponentInfo()->getName());
        else
          startComponentName = pStartComponent->getName();
        if (pComponent->getParentComponent())
          endComponentName = QString(pComponent->getRootParentComponent()->getName()).append(".").append(pComponent->getComponentInfo()->getName());
        else
          endComponentName = pComponent->getName();
        createConnection(startComponentName, endComponentName);
        mpConnectionLineAnnotation->addPoint(QPointF(0, 0));
        mpConnectionLineAnnotation->drawCornerItems();
        mpConnectionLineAnnotation->setCornerItemsPassive();
      }
    }
  }
}

//! Removes the current connecting connector from the model.
void GraphicsView::removeConnection()
{
  if (isCreatingConnection())
  {
    setIsCreatingConnection(false);
    mpConnectionLineAnnotation->deleteLater();
  }
}

//! Removes the connector from the model.
//! @param pConnector is a pointer to the connector to remove.
void GraphicsView::removeConnection(LineAnnotation *pConnection)
{
  bool doDelete = false;
  int i;
  for(i = 0; i != mConnectionsList.size(); ++i)
  {
    if(mConnectionsList[i] == pConnection)
    {
      doDelete = true;
      break;
    }
  }
  if (doDelete)
  {
    // If GUI delete is successful then delete the connection from omc as well.
    deleteConnection(pConnection->getStartComponentName(), pConnection->getEndComponentName());
    // delete the connector object
    pConnection->deleteLater();
    // remove connector object from local connector vector
    mConnectionsList.removeAt(i);
  }
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

//! Increases zoom factor by 15%.
//! @see resetZoom()
//! @see zoomOut()
void GraphicsView::zoomIn()
{
  scale(1.12, 1.12);
  setIsCustomScale(true);
}

//! Decreases zoom factor by 13.04% (1 - 1/1.15).
//! @see resetZoom()
//! @see zoomIn()
void GraphicsView::zoomOut()
{
  scale(1/1.12, 1/1.12);
  setIsCustomScale(true);
}

//! Selects all objects and connectors.
void GraphicsView::selectAll()
{
  foreach (QGraphicsItem *pItem, items())
  {
    pItem->setSelected(true);
  }
}

//! Adds the annotation string of Icon and Diagram layer to the model. Also creates the model icon in the tree.
//! If some custom models are cross referenced then update them accordingly.
void GraphicsView::addClassAnnotation()
{
  if (mpModelWidget->getLibraryTreeNode()->isSystemLibrary())
    return;
  /*
    When several selected shapes are moved via key press events then this function is called for each of them.
    Just set the canAddClassAnnotation flag to false to make sure this function is only used once.
    We enable back this function in the key release event.
    */
  if (canAddClassAnnotation())
    setCanAddClassAnnotation(false);
  else
    return;
  /* Build the annotation string */
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
  QString annotationString;
  annotationString.append("annotate=");
  if (mViewType == StringHandler::Icon)
  {
    annotationString.append("Icon(");
  }
  else if (mViewType == StringHandler::Diagram)
  {
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
  if (mShapesList.size() > 0)
  {
    annotationString.append(", graphics={");
    foreach (ShapeAnnotation *pShapeAnnotation, mShapesList)
    {
      /* Don't add the inherited shape to the addClassAnnotation. */
      if (pShapeAnnotation->isInheritedShape())
      {
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
  if (pMainWindow->getOMCProxy()->addClassAnnotation(mpModelWidget->getLibraryTreeNode()->getNameStructure(), annotationString))
  {
    mpModelWidget->setModelModified();
    /* When something is added/changed in the icon layer then update the LibraryTreeNode in the Library Browser */
    if (mViewType == StringHandler::Icon)
    {
      pMainWindow->getLibraryTreeWidget()->loadLibraryComponent(mpModelWidget->getLibraryTreeNode());
    }
  }
  else
  {
    pMainWindow->getMessagesWidget()->addGUIMessage(new MessagesTreeItem("", false, 0, 0, 0, 0,
                                                                         tr("Error in class annotation ") + pMainWindow->getOMCProxy()->getResult(),
                                                                         Helper::scriptingKind, Helper::errorLevel, 0,
                                                                         pMainWindow->getMessagesWidget()->getMessagesTreeWidget()));
  }
}

void GraphicsView::showGraphicsViewProperties()
{
  GraphicsViewProperties *pGraphicsViewProperties = new GraphicsViewProperties(this);
  pGraphicsViewProperties->show();
}

//! Defines what happens when moving an object in a GraphicsView.
//! @param event contains information of the drag operation.
void GraphicsView::dragMoveEvent(QDragMoveEvent *event)
{
  // check if the class is system library
  if (mpModelWidget->getLibraryTreeNode()->isSystemLibrary())
  {
    event->ignore();
    return;
  }
  // read the mime data from the event
  if (event->mimeData()->hasFormat(Helper::modelicaComponentFormat) || event->mimeData()->hasFormat(Helper::modelicaFileFormat))
  {
    event->setDropAction(Qt::CopyAction);
    event->accept();
  }
  else
  {
    event->ignore();
  }
}

//! Defines what happens when drop an object in a GraphicsView.
//! @param event contains information of the drop operation.
void GraphicsView::dropEvent(QDropEvent *event)
{
  setFocus();
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
  // check mimeData
  if (!event->mimeData()->hasFormat(Helper::modelicaComponentFormat) && !event->mimeData()->hasFormat(Helper::modelicaFileFormat))
  {
    event->ignore();
    return;
  }
  else if (event->mimeData()->hasFormat(Helper::modelicaFileFormat))
  {
    pMainWindow->openDroppedFile(event);
    event->accept();
  }
  else if (event->mimeData()->hasFormat(Helper::modelicaComponentFormat))
  {
    // check if the class is system library
    if (mpModelWidget->getLibraryTreeNode()->isSystemLibrary())
    {
      event->ignore();
      return;
    }
    QByteArray itemData = event->mimeData()->data(Helper::modelicaComponentFormat);
    QDataStream dataStream(&itemData, QIODevice::ReadOnly);
    QString className;
    dataStream >> className;
    if (addComponent(className, mapToScene(event->pos())))
      event->accept();
    else
      event->ignore();
  }
  else
  {
    event->ignore();
  }
}

void GraphicsView::drawBackground(QPainter *painter, const QRectF &rect)
{
  if (mSkipBackground)
    return;
  // draw scene rectangle white background
  painter->setPen(Qt::NoPen);
  painter->setBrush(QBrush(Qt::white, Qt::SolidPattern));
  painter->drawRect(sceneRect());
  if (mpModelWidget->getModelWidgetContainer()->isShowGridLines())
  {
    painter->setBrush(Qt::NoBrush);
    painter->setPen(Qt::lightGray);
    /* Draw left half vertical lines */
    int horizontalGridStep = mpCoOrdinateSystem->getHorizontalGridStep();
    qreal xAxisStep = 0;
    qreal yAxisStep = rect.y();
    xAxisStep -= horizontalGridStep;
    while (xAxisStep > rect.left())
    {
      painter->drawLine(QPointF(xAxisStep, yAxisStep), QPointF(xAxisStep, rect.bottom()));
      xAxisStep -= horizontalGridStep;
    }
    /* Draw right half vertical lines */
    xAxisStep = 0;
    while (xAxisStep < rect.right())
    {
      painter->drawLine(QPointF(xAxisStep, yAxisStep), QPointF(xAxisStep, rect.bottom()));
      xAxisStep += horizontalGridStep;
    }
    /* Draw left half horizontal lines */
    int verticalGridStep = mpCoOrdinateSystem->getVerticalGridStep();
    xAxisStep = rect.x();
    yAxisStep = 0;
    yAxisStep += verticalGridStep;
    while (yAxisStep < rect.bottom())
    {
      painter->drawLine(QPointF(xAxisStep, yAxisStep), QPointF(rect.right(), yAxisStep));
      yAxisStep += verticalGridStep;
    }
    /* Draw right half horizontal lines */
    yAxisStep = 0;
    while (yAxisStep > rect.top())
    {
      painter->drawLine(QPointF(xAxisStep, yAxisStep), QPointF(rect.right(), yAxisStep));
      yAxisStep -= verticalGridStep;
    }
    /* set the middle horizontal and vertical line gray */
    painter->setPen(Qt::darkGray);
    painter->drawLine(QPointF(rect.left(), 0), QPointF(rect.right(), 0));
    painter->drawLine(QPointF(0, rect.top()), QPointF(0, rect.bottom()));
  }
  // draw scene rectangle
  painter->setPen(Qt::darkGray);
  painter->drawRect(sceneRect());
}

//! Defines what happens when clicking in a GraphicsView.
//! @param event contains information of the mouse click operation.
void GraphicsView::mousePressEvent(QMouseEvent *event)
{
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
  /*
    Component multi selection context menu has problems if the following condition is removed.
    Unexpected Component::itemChange events are raised.
    */
  if (event->button() == Qt::RightButton)
    return;
  bool creatingShape = false;
  // if left button presses and we are creating a connector
  if (isCreatingConnection())
  {
    mpConnectionLineAnnotation->addPoint(mapToScene(event->pos()));
  }
  /*
    The creatingShape flag is used to stop the propagation of mousePressEvent.
    When we start creating the shape, creatingShape will get false value and we propogate the mousePressEvent.
    When we finish creating a shape, creatingShape will get true value and we do not propogate the mousePressEvent.
    */
  /* if line shape tool button is checked then create a line */
  else if (pMainWindow->getLineShapeAction()->isChecked())
  {
    creatingShape = isCreatingLineShape();
    createLineShape(mapToScene(event->pos()));
    if (creatingShape) return;
  }
  /* if polygon shape tool button is checked then create a polygon */
  else if (pMainWindow->getPolygonShapeAction()->isChecked())
  {
    creatingShape = isCreatingPolygonShape();
    createPolygonShape(mapToScene(event->pos()));
    if (creatingShape) return;
  }
  /* if rectangle shape tool button is checked then create a rectangle */
  else if (pMainWindow->getRectangleShapeAction()->isChecked())
  {
    creatingShape = isCreatingRectangleShape();
    createRectangleShape(mapToScene(event->pos()));
    if (creatingShape) return;
  }
  /* if ellipse shape tool button is checked then create an ellipse */
  else if (pMainWindow->getEllipseShapeAction()->isChecked())
  {
    creatingShape = isCreatingEllipseShape();
    createEllipseShape(mapToScene(event->pos()));
    if (creatingShape) return;
  }
  /* if text shape tool button is checked then create a text */
  else if (pMainWindow->getTextShapeAction()->isChecked())
  {
    creatingShape = isCreatingTextShape();
    createTextShape(mapToScene(event->pos()));
    if (creatingShape) return;
  }
  /* if bitmap shape tool button is checked then create a bitmap */
  else if (pMainWindow->getBitmapShapeAction()->isChecked())
  {
    creatingShape = isCreatingBitmapShape();
    createBitmapShape(mapToScene(event->pos()));
    if (creatingShape) return;
  }
  // if we are not creating a connector
  else
  {
    // this flag is just used to have seperate identify for if statement in mouse release event of graphicsview
    setIsMovingComponentsAndShapes(true);
    // save the position of all components
    foreach (Component *pComponent, mComponentsList)
    {
      pComponent->setOldPosition(pComponent->pos());
    }
    foreach (ShapeAnnotation *pShapeAnnotation, mShapesList)
    {
      pShapeAnnotation->setOldPosition(pShapeAnnotation->pos());
    }
  }
  QGraphicsView::mousePressEvent(event);
  /* Ticket #2162 : Delete the same component connect connection here. */
  if (isCreatingConnection() && canDeleteCreatingConnection())
  {
    setDeleteCreatingConnection(false);
    removeConnection();
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
  //If creating connector, the end port shall be updated to the mouse position.
  if (isCreatingConnection())
  {
    mpConnectionLineAnnotation->updateEndPoint(mapToScene(event->pos()));
    mpConnectionLineAnnotation->update();
  }
  else if (isCreatingLineShape())
  {
    mpLineShapeAnnotation->updateEndPoint(mapToScene(event->pos()));
    mpLineShapeAnnotation->update();
  }
  else if (isCreatingPolygonShape())
  {
    mpPolygonShapeAnnotation->updateEndPoint(mapToScene(event->pos()));
    mpPolygonShapeAnnotation->update();
  }
  else if (isCreatingRectangleShape())
  {
    mpRectangleShapeAnnotation->updateEndExtent(mapToScene(event->pos()));
    mpRectangleShapeAnnotation->update();
  }
  else if (isCreatingEllipseShape())
  {
    mpEllipseShapeAnnotation->updateEndExtent(mapToScene(event->pos()));
    mpEllipseShapeAnnotation->update();
  }
  else if (isCreatingTextShape())
  {
    mpTextShapeAnnotation->updateEndExtent(mapToScene(event->pos()));
    mpTextShapeAnnotation->update();
  }
  else if (isCreatingBitmapShape())
  {
    mpBitmapShapeAnnotation->updateEndExtent(mapToScene(event->pos()));
    mpBitmapShapeAnnotation->update();
  }
  QGraphicsView::mouseMoveEvent(event);
}

void GraphicsView::mouseReleaseEvent(QMouseEvent *event)
{
  /*
    Component multi selection context menu has problems if the following condition is removed.
    Unexpected Component::itemChange events are raised.
    */
  if (event->button() == Qt::RightButton)
    return;
  if (isMovingComponentsAndShapes())
  {
    setIsMovingComponentsAndShapes(false);
    bool hasMoved = false;
    // if component position is changed then update component annotation
    foreach (Component *pComponent, mComponentsList)
    {
      if (pComponent->getOldPosition() != pComponent->pos())
      {
        pComponent->updatePlacementAnnotation();
        // if there are any connectors associated to component update their annotations as well.
        pComponent->updateConnection();
        hasMoved = true;
      }
    }
    if (hasMoved) mpModelWidget->setModelModified();
    hasMoved = false;
    // if shape position is changed then update class annotation
    foreach (ShapeAnnotation *pShapeAnnotation, mShapesList)
    {
      if (pShapeAnnotation->getOldPosition() != pShapeAnnotation->pos())
      {
        pShapeAnnotation->getTransformation()->setOrigin(pShapeAnnotation->scenePos());
        pShapeAnnotation->setPos(0, 0);
        pShapeAnnotation->setTransform(pShapeAnnotation->getTransformation()->getTransformationMatrix());
        pShapeAnnotation->setOrigin(pShapeAnnotation->getTransformation()->getOrigin());
        hasMoved = true;
      }
    }
    if (hasMoved)
    {
      addClassAnnotation();
      setCanAddClassAnnotation(true);
      mpModelWidget->setModelModified();
    }
  }
  QGraphicsView::mouseReleaseEvent(event);
}

void GraphicsView::mouseDoubleClickEvent(QMouseEvent *event)
{
  if (event->button() == Qt::RightButton)
    return;
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
  if (isCreatingLineShape())
  {
    // set the transformation matrix
    mpLineShapeAnnotation->setOrigin(mpLineShapeAnnotation->sceneBoundingRect().center());
    mpLineShapeAnnotation->adjustPointsWithOrigin();
    mpLineShapeAnnotation->initializeTransformation();
    // draw corner items for the Line shape
    mpLineShapeAnnotation->drawCornerItems();
    mpLineShapeAnnotation->setSelected(true);
    // finish creating the line
    setIsCreatingLineShape(false);
    // make the toolbar button of line unchecked
    pMainWindow->getLineShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    addClassAnnotation();
    setCanAddClassAnnotation(true);
    return;
  }
  else if (isCreatingPolygonShape())
  {
    // set the transformation matrix
    mpPolygonShapeAnnotation->setOrigin(mpPolygonShapeAnnotation->sceneBoundingRect().center());
    mpPolygonShapeAnnotation->adjustPointsWithOrigin();
    mpPolygonShapeAnnotation->initializeTransformation();
    // draw corner items for the polygon shape
    mpPolygonShapeAnnotation->drawCornerItems();
    mpPolygonShapeAnnotation->setSelected(true);
    // finish creating the polygon
    setIsCreatingPolygonShape(false);
    // make the toolbar button of polygon unchecked
    pMainWindow->getPolygonShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    addClassAnnotation();
    setCanAddClassAnnotation(true);
    return;
  }
  ShapeAnnotation *pShapeAnnotation = dynamic_cast<ShapeAnnotation*>(itemAt(event->pos()));
  if (pShapeAnnotation)
  {
    /*
        Double click on Component also end up here.
        But we don't have GraphicsView for the shapes inside the Component so we can go out of this block.
        */
    if (pShapeAnnotation->getGraphicsView())
    {
      pShapeAnnotation->showShapeProperties();
      return;
    }
  }
  QGraphicsView::mouseDoubleClickEvent(event);
}

void GraphicsView::keyPressEvent(QKeyEvent *event)
{
  if (event->key() == Qt::Key_Delete)
  {
    emit keyPressDelete();
  }
  else if(!event->modifiers().testFlag(Qt::ShiftModifier) && event->key() == Qt::Key_Up)
  {
    emit keyPressUp();
  }
  else if(!event->modifiers().testFlag(Qt::ShiftModifier) && event->key() == Qt::Key_Down)
  {
    emit keyPressDown();
  }
  else if(!event->modifiers().testFlag(Qt::ShiftModifier) && event->key() == Qt::Key_Left)
  {
    emit keyPressLeft();
  }
  else if(!event->modifiers().testFlag(Qt::ShiftModifier) && event->key() == Qt::Key_Right)
  {
    emit keyPressRight();
  }
  else if (event->modifiers().testFlag(Qt::ShiftModifier) && event->key() == Qt::Key_Up)
  {
    emit keyPressShiftUp();
  }
  else if (event->modifiers().testFlag(Qt::ShiftModifier) && event->key() == Qt::Key_Down)
  {
    emit keyPressShiftDown();
  }
  else if (event->modifiers().testFlag(Qt::ShiftModifier) && event->key() == Qt::Key_Left)
  {
    emit keyPressShiftLeft();
  }
  else if (event->modifiers().testFlag(Qt::ShiftModifier) && event->key() == Qt::Key_Right)
  {
    emit keyPressShiftRight();
  }
  else if (event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_A)
  {
    selectAll();
  }
  else if (event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_D)
  {
    emit keyPressDuplicate();
  }
  else if (!event->modifiers().testFlag(Qt::ShiftModifier) and event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_R)
  {
    emit keyPressRotateClockwise();
  }
  else if (event->modifiers().testFlag(Qt::ShiftModifier) and event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_R)
  {
    emit keyPressRotateAntiClockwise();
  }
  else if (event->key() == Qt::Key_Escape && isCreatingConnection())
  {
    removeConnection();
  }
  else
  {
    QGraphicsView::keyPressEvent(event);
  }
}

//! Defines what shall happen when a key is released.
//! @param event contains information about the keypress operation.
void GraphicsView::keyReleaseEvent(QKeyEvent *event)
{
  /* if user has pressed and hold the key. */
  if (event->isAutoRepeat())
    return QGraphicsView::keyReleaseEvent(event);
  /* handle keys */
  if(!event->modifiers().testFlag(Qt::ShiftModifier) && event->key() == Qt::Key_Up)
  {
    emit keyReleaseUp();
    setCanAddClassAnnotation(true);
  }
  else if(!event->modifiers().testFlag(Qt::ShiftModifier) && event->key() == Qt::Key_Down)
  {
    emit keyReleaseDown();
    setCanAddClassAnnotation(true);
  }
  else if(!event->modifiers().testFlag(Qt::ShiftModifier) && event->key() == Qt::Key_Left)
  {
    emit keyReleaseLeft();
    setCanAddClassAnnotation(true);
  }
  else if(!event->modifiers().testFlag(Qt::ShiftModifier) && event->key() == Qt::Key_Right)
  {
    emit keyReleaseRight();
    setCanAddClassAnnotation(true);
  }
  else if (event->modifiers().testFlag(Qt::ShiftModifier) && event->key() == Qt::Key_Up)
  {
    emit keyReleaseShiftUp();
    setCanAddClassAnnotation(true);
  }
  else if (event->modifiers().testFlag(Qt::ShiftModifier) && event->key() == Qt::Key_Down)
  {
    emit keyReleaseShiftDown();
    setCanAddClassAnnotation(true);
  }
  else if (event->modifiers().testFlag(Qt::ShiftModifier) && event->key() == Qt::Key_Left)
  {
    emit keyReleaseShiftLeft();
    setCanAddClassAnnotation(true);
  }
  else if (event->modifiers().testFlag(Qt::ShiftModifier) && event->key() == Qt::Key_Right)
  {
    emit keyReleaseShiftRight();
    setCanAddClassAnnotation(true);
  }
  else if (!event->modifiers().testFlag(Qt::ShiftModifier) && event->modifiers().testFlag(Qt::ControlModifier) && event->key() == Qt::Key_R)
  {
    emit keyReleaseRotateClockwise();
    setCanAddClassAnnotation(true);
  }
  else if (event->modifiers().testFlag(Qt::ShiftModifier) && event->modifiers().testFlag(Qt::ControlModifier) && event->key() == Qt::Key_R)
  {
    emit keyReleaseRotateAntiClockwise();
    setCanAddClassAnnotation(true);
  }
  else
  {
    QGraphicsView::keyReleaseEvent(event);
  }
}

void GraphicsView::contextMenuEvent(QContextMenuEvent *event)
{
  /* If we are creating any shape then don't show context menu */
  if (isCreatingLineShape() ||
      isCreatingPolygonShape() ||
      isCreatingRectangleShape() ||
      isCreatingEllipseShape() ||
      isCreatingTextShape())
    return;
  /* If we are creating the connection then show the connection context menu */
  if (isCreatingConnection())
  {
    QMenu menu(mpModelWidget->getModelWidgetContainer()->getMainWindow());
    menu.addAction(mpCancelConnectionAction);
    menu.exec(event->globalPos());
    return;         // return from it because at a time we only want one context menu.
  }
  // if some item is right clicked then don't show graphics view context menu
  if (!itemAt(event->pos()))
  {
    QMenu menu(mpModelWidget->getModelWidgetContainer()->getMainWindow());
    menu.addAction(mpModelWidget->getModelWidgetContainer()->getMainWindow()->getExportAsImageAction());
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
  if (!isCustomScale())
    fitInView(sceneRect(), Qt::KeepAspectRatio);
  QGraphicsView::resizeEvent(event);
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
    listItem->setIcon(QIcon(":/Resources/icons/next.png"));
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
                listItem->setIcon(QIcon(":/Resources/icons/next.png"));
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
  mpMainWindow->getLibraryTreeWidget()->openFile(pItem->text(), pItem->data(Qt::UserRole).toString(), true, true);
}

void WelcomePageWidget::openLatestNewsItem(QListWidgetItem *pItem)
{
  QUrl url(pItem->data(Qt::UserRole).toString());
  QDesktopServices::openUrl(url);
}

ModelWidget::ModelWidget(bool newClass, bool extendsClass, LibraryTreeNode *pLibraryTreeNode, ModelWidgetContainer *pParent)
  : QWidget(pParent)
{
  mpModelWidgetContainer = pParent;
  mpLibraryTreeNode = pLibraryTreeNode;
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
  // create a modelica text editor for modelica text
  mpCursorPositionLabel = new Label;
  mpModelicaTextEditor = new ModelicaTextEditor(this);
  MainWindow *pMainWindow = mpModelWidgetContainer->getMainWindow();
  mpModelicaTextHighlighter = new ModelicaTextHighlighter(pMainWindow->getOptionsDialog()->getModelicaTextSettings(), pMainWindow,
                                                          mpModelicaTextEditor->document());
  mpModelicaTextEditor->hide(); // set it hidden so that Find/Replace action can get correct value.
  connect(pMainWindow->getOptionsDialog(), SIGNAL(modelicaTextSettingsChanged()), mpModelicaTextHighlighter, SLOT(settingsChanged()));
  // set Project Status Bar lables
  mpReadOnlyLabel = mpLibraryTreeNode->isReadOnly() ? new Label(Helper::readOnly) : new Label(tr("Writeable"));
  mpModelicaTypeLabel = new Label(StringHandler::getModelicaClassType(pLibraryTreeNode->getModelicaType()));
  mpViewTypeLabel = new Label(StringHandler::getViewType(StringHandler::Diagram));
  mpModelFilePathLabel = new Label(pLibraryTreeNode->getFileName());
  mpModelFilePathLabel->setElideMode(Qt::ElideMiddle);
  // documentation view tool button
  mpFileLockToolButton = new QToolButton;
  mpFileLockToolButton->setText(mpLibraryTreeNode->isReadOnly() ? tr("Make writable") : tr("File is writable"));
  mpFileLockToolButton->setIcon(QIcon(mpLibraryTreeNode->isReadOnly() ? ":/Resources/icons/lock.png" : ":/Resources/icons/unlock.png"));
  mpFileLockToolButton->setEnabled(mpLibraryTreeNode->isReadOnly());
  /* should be disabled for system library */
  if (mpLibraryTreeNode->isSystemLibrary())
    mpFileLockToolButton->setEnabled(false);
  mpFileLockToolButton->setIconSize(Helper::buttonIconSize);
  mpFileLockToolButton->setToolTip(mpFileLockToolButton->text());
  mpFileLockToolButton->setAutoRaise(true);
  connect(mpFileLockToolButton, SIGNAL(clicked()), SLOT(makeFileWritAble()));
  // frame to contain view buttons
  QFrame *pViewButtonsFrame = new QFrame;
  QHBoxLayout *pViewButtonsHorizontalLayout = new QHBoxLayout;
  pViewButtonsHorizontalLayout->setContentsMargins(0, 0, 0, 0);
  pViewButtonsHorizontalLayout->setSpacing(0);
  // icon view tool button
  mpIconViewToolButton = new QToolButton;
  mpIconViewToolButton->setText(Helper::iconView);
  mpIconViewToolButton->setIcon(QIcon(":/Resources/icons/model.png"));
  mpIconViewToolButton->setIconSize(Helper::buttonIconSize);
  mpIconViewToolButton->setToolTip(Helper::iconView);
  mpIconViewToolButton->setAutoRaise(true);
  mpIconViewToolButton->setCheckable(true);
  connect(mpIconViewToolButton, SIGNAL(toggled(bool)), SLOT(showIconView(bool)));
  pViewButtonsHorizontalLayout->addWidget(mpIconViewToolButton);
  // diagram view tool button
  mpDiagramViewToolButton = new QToolButton;
  mpDiagramViewToolButton->setText(Helper::diagramView);
  mpDiagramViewToolButton->setIcon(QIcon(":/Resources/icons/modeling.png"));
  mpDiagramViewToolButton->setIconSize(Helper::buttonIconSize);
  mpDiagramViewToolButton->setToolTip(Helper::diagramView);
  mpDiagramViewToolButton->setAutoRaise(true);
  mpDiagramViewToolButton->setCheckable(true);
  connect(mpDiagramViewToolButton, SIGNAL(toggled(bool)), SLOT(showDiagramView(bool)));
  pViewButtonsHorizontalLayout->addWidget(mpDiagramViewToolButton);
  // modelica text view tool button
  mpTextViewToolButton = new QToolButton;
  mpTextViewToolButton->setText(Helper::textView);
  mpTextViewToolButton->setIcon(QIcon(":/Resources/icons/modeltext.png"));
  mpTextViewToolButton->setIconSize(Helper::buttonIconSize);
  mpTextViewToolButton->setToolTip(Helper::textView);
  mpTextViewToolButton->setAutoRaise(true);
  mpTextViewToolButton->setCheckable(true);
  connect(mpTextViewToolButton, SIGNAL(toggled(bool)), SLOT(showModelicaTextView(bool)));
  pViewButtonsHorizontalLayout->addWidget(mpTextViewToolButton);
  // documentation view tool button
  mpDocumentationViewToolButton = new QToolButton;
  mpDocumentationViewToolButton->setText(Helper::documentationView);
  mpDocumentationViewToolButton->setIcon(QIcon(":/Resources/icons/info-icon.png"));
  mpDocumentationViewToolButton->setIconSize(Helper::buttonIconSize);
  mpDocumentationViewToolButton->setToolTip(Helper::documentationView);
  mpDocumentationViewToolButton->setAutoRaise(true);
  connect(mpDocumentationViewToolButton, SIGNAL(clicked()), SLOT(showDocumentationView()));
  pViewButtonsHorizontalLayout->addWidget(mpDocumentationViewToolButton);
  pViewButtonsFrame->setLayout(pViewButtonsHorizontalLayout);
  // view buttons box
  mpViewsButtonGroup = new QButtonGroup;
  mpViewsButtonGroup->setExclusive(true);
  mpViewsButtonGroup->addButton(mpDiagramViewToolButton);
  mpViewsButtonGroup->addButton(mpIconViewToolButton);
  mpViewsButtonGroup->addButton(mpTextViewToolButton);
  mpViewsButtonGroup->addButton(mpDocumentationViewToolButton);
  // create project status bar
  mpModelStatusBar = new QStatusBar;
  mpModelStatusBar->setObjectName("ModelStatusBar");
  mpModelStatusBar->setSizeGripEnabled(false);
  mpModelStatusBar->addPermanentWidget(pViewButtonsFrame, 0);
  mpModelStatusBar->addPermanentWidget(mpReadOnlyLabel, 0);
  mpModelStatusBar->addPermanentWidget(mpModelicaTypeLabel, 0);
  mpModelStatusBar->addPermanentWidget(mpViewTypeLabel, 0);
  mpModelStatusBar->addPermanentWidget(mpModelFilePathLabel, 1);
  mpModelStatusBar->addPermanentWidget(mpCursorPositionLabel, 0);
  mpModelStatusBar->addPermanentWidget(mpFileLockToolButton, 0);
  // only get the model components, connectors and shapes if the class is not a new class or class is an extends class.
  if (newClass)
  {
    mpIconGraphicsView->addClassAnnotation();
    mpIconGraphicsView->setCanAddClassAnnotation(true);
    mpDiagramGraphicsView->addClassAnnotation();
    mpDiagramGraphicsView->setCanAddClassAnnotation(true);
  }
  if (!newClass || extendsClass)
  {
    getModelIconDiagramShapes(getLibraryTreeNode()->getNameStructure());
    getModelComponents(getLibraryTreeNode()->getNameStructure());
    getModelConnections(getLibraryTreeNode()->getNameStructure());
  }
  mpIconGraphicsScene->clearSelection();
  mpDiagramGraphicsScene->clearSelection();
  // set layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setSpacing(4);
  pMainLayout->addWidget(mpModelStatusBar);
  pMainLayout->addWidget(mpDiagramGraphicsView, 1);
  pMainLayout->addWidget(mpIconGraphicsView, 1);
  pMainLayout->addWidget(mpModelicaTextEditor, 1);
  setLayout(pMainLayout);
}

ModelWidget::ModelWidget(QString text, LibraryTreeNode *pLibraryTreeNode, ModelWidgetContainer *pParent)
  : QWidget(pParent)
{
  mpModelWidgetContainer = pParent;
  mpLibraryTreeNode = pLibraryTreeNode;
  // icon graphics framework
  mpIconGraphicsScene = 0;
  mpIconGraphicsView = 0;
  // diagram graphics framework
  mpDiagramGraphicsScene = 0;
  mpDiagramGraphicsView = 0;
  // create a modelica text editor for modelica text
  mpCursorPositionLabel = new Label;
  mpModelicaTextEditor = 0;
  mpTextEditor = new TextEditor(this);
  mpTextEditor->setPlainText(text);
  mpModelicaTypeLabel = 0;
  mpViewTypeLabel = 0;
  mpReadOnlyLabel = new Label(tr("Writeable"));
  mpModelFilePathLabel = new Label;
  mpModelFilePathLabel->setElideMode(Qt::ElideMiddle);
  // documentation view tool button
  mpFileLockToolButton = new QToolButton;
  mpFileLockToolButton->setText(tr("File is writable"));
  mpFileLockToolButton->setIcon(QIcon(":/Resources/icons/unlock.png"));
  mpFileLockToolButton->setEnabled(false);
  mpFileLockToolButton->setIconSize(Helper::buttonIconSize);
  mpFileLockToolButton->setToolTip(mpFileLockToolButton->text());
  mpFileLockToolButton->setAutoRaise(true);
  connect(mpFileLockToolButton, SIGNAL(clicked()), SLOT(makeFileWritAble()));
  // frame to contain view buttons
  QFrame *pViewButtonsFrame = new QFrame;
  QHBoxLayout *pViewButtonsHorizontalLayout = new QHBoxLayout;
  pViewButtonsHorizontalLayout->setContentsMargins(0, 0, 0, 0);
  pViewButtonsHorizontalLayout->setSpacing(0);
  // text view tool button
  mpTextViewToolButton = new QToolButton;
  mpTextViewToolButton->setText(Helper::textView);
  mpTextViewToolButton->setIcon(QIcon(":/Resources/icons/modeltext.png"));
  mpTextViewToolButton->setIconSize(Helper::buttonIconSize);
  mpTextViewToolButton->setToolTip(Helper::textView);
  mpTextViewToolButton->setAutoRaise(true);
  mpTextViewToolButton->setCheckable(true);
  mpTextViewToolButton->setChecked(true);
  pViewButtonsHorizontalLayout->addWidget(mpTextViewToolButton);
  pViewButtonsFrame->setLayout(pViewButtonsHorizontalLayout);
  // view buttons box
  mpViewsButtonGroup = new QButtonGroup;
  mpViewsButtonGroup->setExclusive(true);
  mpViewsButtonGroup->addButton(mpTextViewToolButton);
  // create project status bar
  mpModelStatusBar = new QStatusBar;
  mpModelStatusBar->setObjectName("ModelStatusBar");
  mpModelStatusBar->setSizeGripEnabled(false);
  mpModelStatusBar->addPermanentWidget(pViewButtonsFrame, 0);
  mpModelStatusBar->addPermanentWidget(mpReadOnlyLabel, 0);
  mpModelStatusBar->addPermanentWidget(mpModelFilePathLabel, 1);
  mpModelStatusBar->addPermanentWidget(mpCursorPositionLabel, 0);
  mpModelStatusBar->addPermanentWidget(mpFileLockToolButton, 0);
  // set layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setSpacing(4);
  pMainLayout->addWidget(mpModelStatusBar);
  pMainLayout->addWidget(mpTextEditor, 1);
  setLayout(pMainLayout);
}

ModelWidget::ModelWidget(QString text, QString Xml, LibraryTreeNode *pLibraryTreeNode, ModelWidgetContainer *pParent)
  : QWidget(pParent)
{
  mpModelWidgetContainer = pParent;
  mpLibraryTreeNode = pLibraryTreeNode;
  // icon graphics framework
  mpIconGraphicsScene = 0;
  mpIconGraphicsView = 0;
  // diagram graphics framework
  mpDiagramGraphicsScene = new GraphicsScene(StringHandler::Diagram, this);
  mpDiagramGraphicsView = new GraphicsView(StringHandler::Diagram, this);
  mpDiagramGraphicsView->setScene(mpDiagramGraphicsScene);
  mpDiagramGraphicsView->hide();
  // create an xml editor for TLM
  mpCursorPositionLabel = new Label;
  mpModelicaTextEditor = 0;
  mpTLMEditor = new TLMEditor(this);
  mpTLMEditor->setPlainText(text);
  MainWindow *pMainWindow = mpModelWidgetContainer->getMainWindow();
  mpTLMHighlighter = new TLMHighlighter(pMainWindow->getOptionsDialog()->getModelicaTextSettings(), pMainWindow,
                                                          mpTLMEditor->document());
//  mpTLMEditor->hide(); // set it hidden so that Find/Replace action can get correct value.
  connect(pMainWindow->getOptionsDialog(), SIGNAL(modelicaTextSettingsChanged()), mpTLMHighlighter, SLOT(settingsChanged()));

  mpModelicaTypeLabel = 0;
  mpViewTypeLabel = 0;
  mpReadOnlyLabel = new Label(tr("Writeable"));
  mpModelFilePathLabel = new Label;
  mpModelFilePathLabel->setElideMode(Qt::ElideMiddle);
  // documentation view tool button
  mpFileLockToolButton = new QToolButton;
  mpFileLockToolButton->setText(tr("File is writable"));
  mpFileLockToolButton->setIcon(QIcon(":/Resources/icons/unlock.png"));
  mpFileLockToolButton->setEnabled(false);
  mpFileLockToolButton->setIconSize(Helper::buttonIconSize);
  mpFileLockToolButton->setToolTip(mpFileLockToolButton->text());
  mpFileLockToolButton->setAutoRaise(true);
  connect(mpFileLockToolButton, SIGNAL(clicked()), SLOT(makeFileWritAble()));
  // frame to contain view buttons
  QFrame *pViewButtonsFrame = new QFrame;
  QHBoxLayout *pViewButtonsHorizontalLayout = new QHBoxLayout;
  pViewButtonsHorizontalLayout->setContentsMargins(0, 0, 0, 0);
  pViewButtonsHorizontalLayout->setSpacing(0);
  // diagram view tool button
  mpDiagramViewToolButton = new QToolButton;
  mpDiagramViewToolButton->setText(Helper::diagramView);
  mpDiagramViewToolButton->setIcon(QIcon(":/Resources/icons/modeling.png"));
  mpDiagramViewToolButton->setIconSize(Helper::buttonIconSize);
  mpDiagramViewToolButton->setToolTip(Helper::diagramView);
  mpDiagramViewToolButton->setAutoRaise(true);
  mpDiagramViewToolButton->setCheckable(true);
  pViewButtonsHorizontalLayout->addWidget(mpDiagramViewToolButton);
  // xml view tool button
  mpTextViewToolButton = new QToolButton;
  mpTextViewToolButton->setText(Helper::textView);
  mpTextViewToolButton->setIcon(QIcon(":/Resources/icons/modeltext.png"));
  mpTextViewToolButton->setIconSize(Helper::buttonIconSize);
  mpTextViewToolButton->setToolTip(Helper::textView);
  mpTextViewToolButton->setAutoRaise(true);
  mpTextViewToolButton->setCheckable(true);
  mpTextViewToolButton->setChecked(true);
  pViewButtonsHorizontalLayout->addWidget(mpTextViewToolButton);
  pViewButtonsFrame->setLayout(pViewButtonsHorizontalLayout);
  // view buttons box
  mpViewsButtonGroup = new QButtonGroup;
  mpViewsButtonGroup->setExclusive(true);
  mpViewsButtonGroup->addButton(mpTextViewToolButton);
  // create project status bar
  mpModelStatusBar = new QStatusBar;
  mpModelStatusBar->setObjectName("ModelStatusBar");
  mpModelStatusBar->setSizeGripEnabled(false);
  mpModelStatusBar->addPermanentWidget(pViewButtonsFrame, 0);
  mpModelStatusBar->addPermanentWidget(mpReadOnlyLabel, 0);
  mpModelStatusBar->addPermanentWidget(mpModelFilePathLabel, 1);
  mpModelStatusBar->addPermanentWidget(mpCursorPositionLabel, 0);
  mpModelStatusBar->addPermanentWidget(mpFileLockToolButton, 0);
  // set layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setSpacing(4);
  pMainLayout->addWidget(mpModelStatusBar);
  pMainLayout->addWidget(mpTLMEditor, 1);
  setLayout(pMainLayout);
}

void ModelWidget::setModelFilePathLabel(QString path)
{
  mpModelFilePathLabel->setText(path);
}

void ModelWidget::setModelModified()
{
  // Add a * in the model window title.
  setWindowTitle(QString(mpLibraryTreeNode->getNameStructure()).append("*"));
  // set the library node not saved.
  mpLibraryTreeNode->setIsSaved(false);
  // clean up the OMC cache for this particular model classname.
  mpModelWidgetContainer->getMainWindow()->getOMCProxy()->removeCachedOMCCommand(mpLibraryTreeNode->getNameStructure());
  /*
    If this model is a child model inside a package.
    Then get the root package. If the package is saved in one file then set the package unsaved.
    */
  LibraryTreeWidget *pLibraryTreeWidget = mpModelWidgetContainer->getMainWindow()->getLibraryTreeWidget();
  LibraryTreeNode *pLibraryTreeNode;
  pLibraryTreeNode = pLibraryTreeWidget->getLibraryTreeNode(StringHandler::getFirstWordBeforeDot(mpLibraryTreeNode->getNameStructure()));
  if (pLibraryTreeNode->getFileName().compare(mpLibraryTreeNode->getFileName()) == 0) {
    // Add a * in the model window title.
    if (pLibraryTreeNode->getModelWidget()) {
      pLibraryTreeNode->getModelWidget()->setWindowTitle(QString(pLibraryTreeNode->getNameStructure()).append("*"));
    }
    pLibraryTreeNode->setIsSaved(false);
  }
  /*
    If this model is child model inside a package then reflect the change in the text view of the package as well.
    */
  if (!mpLibraryTreeNode->getParentName().isEmpty()) {
    updateParentModelsText(mpLibraryTreeNode->getNameStructure());
  }
}

void ModelWidget::updateParentModelsText(QString className)
{
  LibraryTreeWidget *pLibraryTreeWidget = mpModelWidgetContainer->getMainWindow()->getLibraryTreeWidget();
  className = StringHandler::removeLastWordAfterDot(className);
  LibraryTreeNode *pLibraryTreeNode;
  pLibraryTreeNode = pLibraryTreeWidget->getLibraryTreeNode(className);
  if (pLibraryTreeNode)
  {
    /* if the parent model's modelica text view is visible then update it. */
    if (pLibraryTreeNode->getModelWidget())
    {
      // clean up the OMC cache for this particular model classname.
      mpModelWidgetContainer->getMainWindow()->getOMCProxy()->removeCachedOMCCommand(className);
      if (pLibraryTreeNode->getModelWidget()->getModelicaTextEditor()->isVisible())
      {
        mpModelWidgetContainer->getMainWindow()->getOMCProxy()->enableCanUseEventLoop(false);
        pLibraryTreeNode->getModelWidget()->getModelicaTextEditor()->setPlainText(mpModelWidgetContainer->getMainWindow()->getOMCProxy()->list(className));
        mpModelWidgetContainer->getMainWindow()->getOMCProxy()->enableCanUseEventLoop(true);
      }
    }
    if (!pLibraryTreeNode->getParentName().isEmpty())
      updateParentModelsText(className);
  }
}

/*!
  Gets the components of the model and place them in the diagram and icon GraphicsView.
  */
void ModelWidget::getModelComponents(QString className, bool inheritedCycle)
{
  MainWindow *pMainWindow = mpModelWidgetContainer->getMainWindow();
  // get the inherited components of the class
  int inheritanceCount = pMainWindow->getOMCProxy()->getInheritanceCount(className);
  for(int i = 1 ; i <= inheritanceCount ; i++)
  {
    QString inheritedClass = pMainWindow->getOMCProxy()->getNthInheritedClass(className, i);
    /*
      If the inherited class is one of the builtin type such as Real we can
      stop here, because the class can not contain any components, etc.
      Also check for cyclic loops.
      */
    if (pMainWindow->getOMCProxy()->isBuiltinType(inheritedClass) || inheritedClass.compare(className) == 0)
      return;
    getModelComponents(inheritedClass, true);
  }
  // get the components
  QList<ComponentInfo*> componentsList = pMainWindow->getOMCProxy()->getComponents(className);
  // get the components annotations
  QStringList componentsAnnotationsList = pMainWindow->getOMCProxy()->getComponentAnnotations(className);
  int i = 0;
  foreach (ComponentInfo *pComponentInfo, componentsList)
  {
    /* if the component type is one of the builtin type then don't show it */
    if (pMainWindow->getOMCProxy()->isBuiltinType(pComponentInfo->getClassName()))
    {
      i++;
      continue;
    }
    StringHandler::ModelicaClasses type = pMainWindow->getOMCProxy()->getClassRestriction(pComponentInfo->getClassName());
    /* Only model, class, connector, record or block is allowed on the diagram layer. */
    if (!(type == StringHandler::Model ||
          type == StringHandler::Class ||
          type == StringHandler::Connector ||
          type == StringHandler::Record ||
          type == StringHandler::Block))
    {
      i++;
      continue;
    }
    // just to be on safe-side.
    if (componentsAnnotationsList.size() <= i)
      continue;
    QString transformation = StringHandler::getPlacementAnnotation(componentsAnnotationsList.at(i));
    // add the component to the diagram view.
    if (!transformation.isEmpty())
    {
      mpDiagramGraphicsView->addComponentToView(pComponentInfo->getName(), pComponentInfo->getClassName(), transformation,
                                                QPointF(0.0, 0.0), pComponentInfo, type, false, true, inheritedCycle, className);
      if (type == StringHandler::Connector && !pComponentInfo->getProtected())
      {
        // add the component to the icon view.
        mpIconGraphicsView->addComponentToView(pComponentInfo->getName(), pComponentInfo->getClassName(), transformation,
                                               QPointF(0.0, 0.0), new ComponentInfo(pComponentInfo), type, false, true, inheritedCycle, className);
      }
    }
    i++;
  }
}

void ModelWidget::getModelIconDiagramShapes(QString className, bool inheritedCycle)
{
  MainWindow *pMainWindow = mpModelWidgetContainer->getMainWindow();
  // get the inherited components of the class
  int inheritanceCount = pMainWindow->getOMCProxy()->getInheritanceCount(className);
  for(int i = 1 ; i <= inheritanceCount ; i++)
  {
    QString inheritedClass = pMainWindow->getOMCProxy()->getNthInheritedClass(className, i);
    /*
      If the inherited class is one of the builtin type such as Real we can
      stop here, because the class can not contain any components, etc.
      Also check for cyclic loops.
      */
    if (pMainWindow->getOMCProxy()->isBuiltinType(inheritedClass) || inheritedClass.compare(className) == 0)
      return;
    getModelIconDiagramShapes(inheritedClass, true);
  }
  OMCProxy *pOMCProxy = mpModelWidgetContainer->getMainWindow()->getOMCProxy();
  QString iconAnnotationString = pOMCProxy->getIconAnnotation(className);
  getModelIconDiagramShapes(className, iconAnnotationString, StringHandler::Icon, inheritedCycle);
  QString diagramAnnotationString = pOMCProxy->getDiagramAnnotation(className);
  getModelIconDiagramShapes(className, diagramAnnotationString, StringHandler::Diagram, inheritedCycle);
}

void ModelWidget::getModelIconDiagramShapes(QString className, QString annotationString, StringHandler::ViewType viewType, bool inheritedCycle)
{
  annotationString = StringHandler::removeFirstLastCurlBrackets(annotationString);
  if (annotationString.isEmpty())
  {
    return;
  }
  QStringList list = StringHandler::getStrings(annotationString);
  // read the coordinate system
  if (list.size() < 8)
    return;
  GraphicsView *pGraphicsView;
  if (viewType == StringHandler::Icon)
    pGraphicsView = mpIconGraphicsView;
  else
    pGraphicsView = mpDiagramGraphicsView;
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
  pGraphicsView->setSceneRect(left, bottom, fabs(left - right), fabs(bottom - top));
  pGraphicsView->fitInView(pGraphicsView->sceneRect(), Qt::KeepAspectRatio);
  pGraphicsView->setIsCustomScale(false);
  // read the shapes
  if (list.size() < 9)
    return;
  QStringList shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(8)), '(', ')');
  // Now parse the shapes available in list
  foreach (QString shape, shapesList)
  {
    if (shape.startsWith("Line"))
    {
      shape = shape.mid(QString("Line").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      LineAnnotation *pLineAnnotation = new LineAnnotation(shape, inheritedCycle, pGraphicsView);
      /*
        before drawing the corner items add one point to line since drawcorneritems
        deletes one point. Why? because we end the line shape with double click which adds an extra
        point to it. so we need to delete this point.
        */
      pLineAnnotation->initializeTransformation();
      pLineAnnotation->addPoint(QPoint(0, 0));
      pLineAnnotation->drawCornerItems();
      pLineAnnotation->setCornerItemsPassive();
    }
    else if (shape.startsWith("Polygon"))
    {
      shape = shape.mid(QString("Polygon").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      PolygonAnnotation *pPolygonAnnotation = new PolygonAnnotation(shape, inheritedCycle, pGraphicsView);
      /*
        before drawing the corner items add one point to polygon since drawcorneritems
        deletes one point. Why? because we end the polygon shape with double click which adds an extra
        point to it. so we need to delete this point.
        */
      pPolygonAnnotation->initializeTransformation();
      pPolygonAnnotation->addPoint(QPoint(0, 0));
      pPolygonAnnotation->drawCornerItems();
      pPolygonAnnotation->setCornerItemsPassive();
    }
    else if (shape.startsWith("Rectangle"))
    {
      shape = shape.mid(QString("Rectangle").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      RectangleAnnotation *pRectangleAnnotation = new RectangleAnnotation(shape, inheritedCycle, pGraphicsView);
      pRectangleAnnotation->initializeTransformation();
      pRectangleAnnotation->drawCornerItems();
      pRectangleAnnotation->setCornerItemsPassive();
    }
    else if (shape.startsWith("Ellipse"))
    {
      shape = shape.mid(QString("Ellipse").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      EllipseAnnotation *pEllipseAnnotation = new EllipseAnnotation(shape, inheritedCycle, pGraphicsView);
      pEllipseAnnotation->initializeTransformation();
      pEllipseAnnotation->drawCornerItems();
      pEllipseAnnotation->setCornerItemsPassive();
    }
    else if (shape.startsWith("Text"))
    {
      shape = shape.mid(QString("Text").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      TextAnnotation *pTextAnnotation = new TextAnnotation(shape, inheritedCycle, pGraphicsView);
      pTextAnnotation->initializeTransformation();
      pTextAnnotation->drawCornerItems();
      pTextAnnotation->setCornerItemsPassive();
    }
    else if (shape.startsWith("Bitmap"))
    {
      /* get the class file path */
      QString classFileName;
      QStringList classInformation = mpModelWidgetContainer->getMainWindow()->getOMCProxy()->getClassInformation(className);
      if (classInformation.size() > 2)
        classFileName = classInformation.at(2);
      /* create the bitmap shape */
      shape = shape.mid(QString("Bitmap").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      BitmapAnnotation *pBitmapAnnotation = new BitmapAnnotation(classFileName, shape, inheritedCycle, pGraphicsView);
      pBitmapAnnotation->initializeTransformation();
      pBitmapAnnotation->drawCornerItems();
      pBitmapAnnotation->setCornerItemsPassive();
    }
  }
}

void ModelWidget::getModelConnections(QString className, bool inheritedCycle)
{
  MainWindow *pMainWindow = mpModelWidgetContainer->getMainWindow();
  // get the inherited connections of the class
  int inheritanceCount = pMainWindow->getOMCProxy()->getInheritanceCount(className);
  for(int i = 1 ; i <= inheritanceCount ; i++)
  {
    QString inheritedClass = pMainWindow->getOMCProxy()->getNthInheritedClass(className, i);
    /*
      If the inherited class is one of the builtin type such as Real we can
      stop here, because the class can not contain any components, etc.
      Also check for cyclic loops.
      */
    if (pMainWindow->getOMCProxy()->isBuiltinType(inheritedClass) || inheritedClass.compare(className) == 0)
      return;
    getModelConnections(inheritedClass, true);
  }
  int connectionCount = pMainWindow->getOMCProxy()->getConnectionCount(className);
  for (int i = 1 ; i <= connectionCount ; i++)
  {
    // get the connection from OMC
    QString connectionString;
    QStringList connectionList;
    connectionString = pMainWindow->getOMCProxy()->getNthConnection(className, i);
    connectionList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(connectionString));
    // if the connectionString only contains two items then continue the loop,
    // because connection is not valid then
    if (connectionList.size() < 3)
      continue;
    // get start and end components
    QStringList startComponentList = connectionList.at(0).split(".");
    QStringList endComponentList = connectionList.at(1).split(".");
    // get start component
    Component *pStartComponent = 0;
    if (startComponentList.size() > 0)
      pStartComponent = mpDiagramGraphicsView->getComponentObject(startComponentList.at(0));
    // get end component
    Component *pEndComponent = 0;
    if (endComponentList.size() > 0)
      pEndComponent = mpDiagramGraphicsView->getComponentObject(endComponentList.at(0));
    // get start and end connectors
    Component *pStartConnectorComponent = 0;
    Component *pEndConnectorComponent = 0;
    bool isExpandableConnector = false;
    if (pStartComponent)
    {
      pMainWindow->getOMCProxy()->sendCommand("getClassRestriction(" + pStartComponent->getClassName() + ")");
      isExpandableConnector = pMainWindow->getOMCProxy()->getResult().toLower().contains("expandable connector");
      // if a component type is connector then we only get one item in startComponentList
      // check the startcomponentlist
      if (startComponentList.size() < 2 || isExpandableConnector)
      {
        pStartConnectorComponent = pStartComponent;
      }
      /* if class doesn't exist then connect with the red cross box */
      else if (!pMainWindow->getOMCProxy()->existClass(pStartComponent->getClassName()))
      {
        pStartConnectorComponent = pStartComponent;
      }
      // look for port from the parent component
      else
      {
        QString startComponentName = startComponentList.at(1);
        if (startComponentName.contains("["))
          startComponentName = startComponentName.mid(0, startComponentName.indexOf("["));
        pStartConnectorComponent = getConnectorComponent(pStartComponent, startComponentName);
      }
    }
    if (pEndComponent)
    {
      // if a component type is connector then we only get one item in endComponentList
      // check the endcomponentlist
      isExpandableConnector = false;
      pMainWindow->getOMCProxy()->sendCommand("getClassRestriction(" + pEndComponent->getClassName() + ")");
      isExpandableConnector = pMainWindow->getOMCProxy()->getResult().toLower().contains("expandable connector");
      if (endComponentList.size() < 2 || isExpandableConnector)
      {
        pEndConnectorComponent = pEndComponent;
      }
      /* if class doesn't exist then connect with the red cross box */
      else if (!pMainWindow->getOMCProxy()->existClass(pEndComponent->getClassName()))
      {
        pEndConnectorComponent = pEndComponent;
      }
      else
      {
        QString endComponentName = endComponentList.at(1);
        if (endComponentName.contains("["))
          endComponentName = endComponentName.mid(0, endComponentName.indexOf("["));
        pEndConnectorComponent = getConnectorComponent(pEndComponent, endComponentName);
      }
    }
    // get the connector annotations from OMC
    QString connectionAnnotationString = pMainWindow->getOMCProxy()->getNthConnectionAnnotation(className, i);
    QStringList shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(connectionAnnotationString), '(', ')');
    // Now parse the shapes available in list
    foreach (QString shape, shapesList)
    {
      if (shape.startsWith("Line"))
      {
        shape = shape.mid(QString("Line").length());
        shape = StringHandler::removeFirstLastBrackets(shape);
        LineAnnotation *pConnectionLineAnnotation = new LineAnnotation(shape, inheritedCycle, pStartConnectorComponent,
                                                                       pEndConnectorComponent, mpDiagramGraphicsView);
        if (pStartConnectorComponent)
          pStartConnectorComponent->getRootParentComponent()->addConnectionDetails(pConnectionLineAnnotation);
        pConnectionLineAnnotation->setStartComponentName(connectionList.at(0));
        if (pEndConnectorComponent)
          pEndConnectorComponent->getRootParentComponent()->addConnectionDetails(pConnectionLineAnnotation);
        pConnectionLineAnnotation->setEndComponentName(connectionList.at(1));
        pConnectionLineAnnotation->addPoint(QPointF(0, 0));
        pConnectionLineAnnotation->drawCornerItems();
        pConnectionLineAnnotation->setCornerItemsPassive();
        mpDiagramGraphicsView->addConnectionObject(pConnectionLineAnnotation);
      }
    }
  }
}

Component* ModelWidget::getConnectorComponent(Component *pConnectorComponent, QString connectorName)
{
  Component *pConnectorComponentFound = 0;
  foreach (Component *pComponent, pConnectorComponent->getComponentsList())
  {
    if (pComponent->getName().compare(connectorName) == 0)
    {
      pConnectorComponentFound = pComponent;
      return pConnectorComponentFound;
    }
  }
  /* if port is not found in components list then look into the inherited components list. */
  foreach (Component *pInheritedComponent, pConnectorComponent->getInheritanceList())
  {
    pConnectorComponentFound = getConnectorComponent(pInheritedComponent, connectorName);
    if (pConnectorComponentFound)
      return pConnectorComponentFound;
  }
  return pConnectorComponentFound;
}

void ModelWidget::refresh()
{
  QApplication::setOverrideCursor(Qt::WaitCursor);
  /* Clear the OMC commands cache for this class */
  OMCProxy *pOMCProxy = mpModelWidgetContainer->getMainWindow()->getOMCProxy();
  pOMCProxy->removeCachedOMCCommand(mpLibraryTreeNode->getNameStructure());
  /* set the LibraryTreeNode filename, type & tooltip */
  pOMCProxy->setSourceFile(mpLibraryTreeNode->getNameStructure(), mpLibraryTreeNode->getFileName());
  QStringList info = pOMCProxy->getClassInformation(mpLibraryTreeNode->getNameStructure());
  StringHandler::ModelicaClasses type = info.size() < 3 ? pOMCProxy->getClassRestriction(mpLibraryTreeNode->getNameStructure()) : StringHandler::getModelicaClassType(info.at(0));
  mpLibraryTreeNode->setModelicaType(type);
  mpLibraryTreeNode->setToolTip(0, StringHandler::createTooltip(info, mpLibraryTreeNode->getName(), mpLibraryTreeNode->getNameStructure()));
  /* set the LibraryTreeNode icon */
  bool isDocumentationClass = mpModelWidgetContainer->getMainWindow()->getOMCProxy()->getDocumentationClassAnnotation(mpLibraryTreeNode->getNameStructure());
  mpLibraryTreeNode->setIsDocumentationClass(isDocumentationClass);
  mpModelWidgetContainer->getMainWindow()->getLibraryTreeWidget()->loadLibraryComponent(mpLibraryTreeNode);
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
  getModelIconDiagramShapes(getLibraryTreeNode()->getNameStructure());
  getModelComponents(getLibraryTreeNode()->getNameStructure());
  getModelConnections(getLibraryTreeNode()->getNameStructure());
  QApplication::restoreOverrideCursor();
}

void ModelWidget::makeFileWritAble()
{
  const QString &fileName = mpLibraryTreeNode->getFileName();
  const bool permsOk = QFile::setPermissions(fileName, QFile::permissions(fileName) | QFile::WriteUser);
  if (!permsOk)
    QMessageBox::warning(this, tr("Cannot Set Permissions"),  tr("Cannot set permissions to writable."));
  else
  {
    mpLibraryTreeNode->setReadOnly(false);
    mpFileLockToolButton->setText(tr("File is writable"));
    mpFileLockToolButton->setIcon(QIcon(":/Resources/icons/unlock.png"));
    mpFileLockToolButton->setEnabled(false);
    mpFileLockToolButton->setToolTip(mpFileLockToolButton->text());
  }
}

void ModelWidget::showIconView(bool checked)
{
  // validate the modelica text before switching to icon view
  if (checked)
  {
    if (!mpModelicaTextEditor->validateModelicaText())
    {
      mpTextViewToolButton->setChecked(true);
      return;
    }
  }
  QMdiSubWindow *pSubWindow = mpModelWidgetContainer->getCurrentMdiSubWindow();
  if (pSubWindow)
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/model.png"));
  mpIconGraphicsView->setFocus();
  if (!checked or (checked and mpIconGraphicsView->isVisible()))
    return;
  mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::Icon));
  mpDiagramGraphicsView->hide();
  mpModelicaTextEditor->hide();
  mpModelWidgetContainer->getMainWindow()->getFindReplaceAction()->setEnabled(false);
  mpModelWidgetContainer->getMainWindow()->getGotoLineNumberAction()->setEnabled(false);
  mpIconGraphicsView->show();
  mpModelWidgetContainer->setPreviousViewType(StringHandler::Icon);
}

void ModelWidget::showDiagramView(bool checked)
{
  // validate the modelica text before switching to diagram view
  if (checked)
  {
    if (!mpModelicaTextEditor->validateModelicaText())
    {
      mpTextViewToolButton->setChecked(true);
      return;
    }
  }
  QMdiSubWindow *pSubWindow = mpModelWidgetContainer->getCurrentMdiSubWindow();
  if (pSubWindow)
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/modeling.png"));
  mpDiagramGraphicsView->setFocus();
  if (!checked or (checked and mpDiagramGraphicsView->isVisible()))
    return;
  mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::Diagram));
  mpIconGraphicsView->hide();
  mpModelicaTextEditor->hide();
  mpModelWidgetContainer->getMainWindow()->getFindReplaceAction()->setEnabled(false);
  mpModelWidgetContainer->getMainWindow()->getGotoLineNumberAction()->setEnabled(false);
  mpDiagramGraphicsView->show();
  mpModelWidgetContainer->setPreviousViewType(StringHandler::Diagram);
}

void ModelWidget::showModelicaTextView(bool checked)
{
  QMdiSubWindow *pSubWindow = mpModelWidgetContainer->getCurrentMdiSubWindow();
  if (pSubWindow)
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/modeltext.png"));
  if (!checked or (checked and mpModelicaTextEditor->isVisible()))
    return;
  mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::ModelicaText));
  // get the modelica text of the model
  mpModelicaTextEditor->setPlainText(mpModelWidgetContainer->getMainWindow()->getOMCProxy()->list(getLibraryTreeNode()->getNameStructure()));
  mpModelicaTextEditor->setLastValidText(mpModelicaTextEditor->toPlainText());
  mpIconGraphicsView->hide();
  mpDiagramGraphicsView->hide();
  mpModelicaTextEditor->show();
  mpModelWidgetContainer->getMainWindow()->getFindReplaceAction()->setEnabled(true);
  mpModelWidgetContainer->getMainWindow()->getGotoLineNumberAction()->setEnabled(true);
  mpModelicaTextEditor->setFocus();
  mpModelWidgetContainer->setPreviousViewType(StringHandler::ModelicaText);
}

void ModelWidget::showDocumentationView()
{
  // validate the modelica text before switching to documentation view
  if (!mpModelicaTextEditor->validateModelicaText())
  {
    mpTextViewToolButton->setChecked(true);
    return;
  }
  mpModelWidgetContainer->getMainWindow()->getDocumentationWidget()->showDocumentation(getLibraryTreeNode()->getNameStructure());
  mpModelWidgetContainer->getMainWindow()->getDocumentationDockWidget()->show();
}

bool ModelWidget::modelicaEditorTextChanged()
{
  QString errorString;
  QStringList classNames = mpModelicaTextEditor->getClassNames(&errorString);
  LibraryTreeWidget *pLibraryTreeWidget = mpModelWidgetContainer->getMainWindow()->getLibraryTreeWidget();
  OMCProxy *pOMCProxy = mpModelWidgetContainer->getMainWindow()->getOMCProxy();
  if (classNames.size() == 0)
  {
    if (!errorString.isEmpty())
    {
      MessagesWidget *pMessagesWidget = getModelWidgetContainer()->getMainWindow()->getMessagesWidget();
      pMessagesWidget->addGUIMessage(new MessagesTreeItem("", false, 0, 0, 0, 0, errorString, Helper::syntaxKind, Helper::errorLevel, 0,
                                                          pMessagesWidget->getMessagesTreeWidget()));
    }
    return false;
  }
  /* if no errors are found with the Modelica Text then load it in OMC */
  QString modelicaText = mpModelicaTextEditor->toPlainText();
  if (mpLibraryTreeNode->getParentName().isEmpty())
  {
    if (!pOMCProxy->loadString(StringHandler::escapeString(modelicaText)))
      return false;
  }
  else
  {
    if (!pOMCProxy->loadString("within " + mpLibraryTreeNode->getParentName() + ";" + StringHandler::escapeString(modelicaText)))
      return false;
  }
  /* first handle the current class */
  /* if user has changed the class then refresh it. */
  if (classNames.contains(mpLibraryTreeNode->getNameStructure()))
  {
    /* if class has children then delete them. */
    pLibraryTreeWidget->unloadClassHelper(mpLibraryTreeNode);
    qDeleteAll(mpLibraryTreeNode->takeChildren());
    classNames.removeOne(mpLibraryTreeNode->getNameStructure());
    pLibraryTreeWidget->removeFromExpandedLibraryTreeNodesList(mpLibraryTreeNode);
    mpLibraryTreeNode->setExpanded(false);
    refresh();
    /* if class has children then create them. */
    pLibraryTreeWidget->createLibraryTreeNodes(mpLibraryTreeNode);
  }
  /*
    if user has changed the class name then delete this class.
    Update the LibraryTreeNode with new class name and then refresh it.
    */
  else
  {
    /* if class has children then delete them. */
    pLibraryTreeWidget->unloadClassHelper(mpLibraryTreeNode);
    qDeleteAll(mpLibraryTreeNode->takeChildren());
    /* call setModelModified before deleting the class so we can get rid of cache commands of this object. */
    setModelModified();
    pOMCProxy->deleteClass(mpLibraryTreeNode->getNameStructure());
    QString className = classNames.first();
    classNames.removeFirst();
    /*
      if user has used within keyword in the text to move the class in a package then,
      - Find the current parent of the class and then remove the class from it and move it to the new parent.
      - If the class is top level then remove it from the top level and add it to the new parent.
      */
    LibraryTreeNode *pCurrentParentLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(mpLibraryTreeNode->parent());
    LibraryTreeNode *pNewParentLibraryTreeNode = pLibraryTreeWidget->getLibraryTreeNode(StringHandler::removeLastWordAfterDot(className));
    /* If really a within is used then the following condition should be true. */
    if ((pNewParentLibraryTreeNode) && (pNewParentLibraryTreeNode != mpLibraryTreeNode))
    {
      /* If the class has parent then use it otherwise use the tree widget to remove the class. */
      if (pCurrentParentLibraryTreeNode)
      {
        pCurrentParentLibraryTreeNode->takeChild(pCurrentParentLibraryTreeNode->indexOfChild(mpLibraryTreeNode));
        /* Remove the cache of the current parent. */
        if (pCurrentParentLibraryTreeNode->getModelWidget())
        {
          pCurrentParentLibraryTreeNode->getModelWidget()->setModelModified();
          /* update the text of the class */
          ModelicaTextEditor *pModelicaTextEditor = pCurrentParentLibraryTreeNode->getModelWidget()->getModelicaTextEditor();
          if (pModelicaTextEditor->isVisible())
            pModelicaTextEditor->setPlainText(pOMCProxy->list(pCurrentParentLibraryTreeNode->getNameStructure()));
        }
      }
      else
      {
        pLibraryTreeWidget->takeTopLevelItem(pLibraryTreeWidget->indexOfTopLevelItem(mpLibraryTreeNode));
      }
      /* Add the class to the new parent. */
      pNewParentLibraryTreeNode->addChild(mpLibraryTreeNode);
      /* Remove the cache of the new parent. */
      if (pNewParentLibraryTreeNode->getModelWidget())
      {
        pNewParentLibraryTreeNode->getModelWidget()->setModelModified();
        /* update the text of the class */
        ModelicaTextEditor *pModelicaTextEditor = pNewParentLibraryTreeNode->getModelWidget()->getModelicaTextEditor();
        if (pModelicaTextEditor->isVisible())
          pModelicaTextEditor->setPlainText(pOMCProxy->list(pNewParentLibraryTreeNode->getNameStructure()));
      }
    }
    /* set the LibraryTreeNode name & text */
    mpLibraryTreeNode->setName(StringHandler::getLastWordAfterDot(className));
    mpLibraryTreeNode->setText(0, mpLibraryTreeNode->getName());
    mpLibraryTreeNode->setNameStructure(className);
    setModelModified();
    /* get the model components, shapes & connectors */
    refresh();
    /* if class has children then create them. */
    pLibraryTreeWidget->createLibraryTreeNodes(mpLibraryTreeNode);
  }
  /* create the rest of the classes */
  foreach (QString className, classNames)
  {
    QString modelName = StringHandler::getLastWordAfterDot(className);
    QString parentName = StringHandler::removeLastWordAfterDot(className);
    if (modelName.compare(parentName) == 0)
      parentName = "";
    LibraryTreeNode *pLibraryTreeNode;
    pLibraryTreeNode = pLibraryTreeWidget->addLibraryTreeNode(modelName, pOMCProxy->getClassRestriction(modelName), parentName, false);
    pLibraryTreeWidget->createLibraryTreeNodes(pLibraryTreeNode);
  }
  return true;
}

void ModelWidget::closeEvent(QCloseEvent *event)
{
  Q_UNUSED(event);
  mpModelWidgetContainer->removeSubWindow(this);
}

ModelWidgetContainer::ModelWidgetContainer(MainWindow *pParent)
  : MdiArea(pParent), mPreviousViewType(StringHandler::NoView), mShowGridLines(false)
{
  if (mpMainWindow->getOptionsDialog()->getGeneralSettingsPage()->getModelingViewMode().compare(Helper::subWindow) == 0)
    setViewMode(QMdiArea::SubWindowView);
  else
    setViewMode(QMdiArea::TabbedView);
  // dont show this widget at startup
  setVisible(false);
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
  if (pModelWidget->isVisible() || pModelWidget->isMinimized())
  {
    QList<QMdiSubWindow*> subWindowsList = subWindowList(QMdiArea::ActivationHistoryOrder);
    for (int i = subWindowsList.size() - 1 ; i >= 0 ; i--)
    {
      ModelWidget *pSubModelWidget = qobject_cast<ModelWidget*>(subWindowsList.at(i)->widget());
      if (pSubModelWidget == pModelWidget)
      {
        pModelWidget->show();
        pModelWidget->setWindowState(Qt::WindowMaximized);
        setActiveSubWindow(subWindowsList.at(i));
      }
    }
  }
  else
  {
    QMdiSubWindow *pSubWindow = addSubWindow(pModelWidget);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/modeling.png"));
    //! @note remove the Stay on &Top Menu item from subwindows. They raise strange exceptions.
    if (pSubWindow->systemMenu()->actions().size() > 6)
    {
      if (pSubWindow->systemMenu()->actions().at(5)->text().compare("Stay on &Top") == 0)
      {
        pSubWindow->systemMenu()->removeAction(pSubWindow->systemMenu()->actions().at(5));
      }
    }
    pModelWidget->show();
    pModelWidget->setWindowState(Qt::WindowMaximized);
    setActiveSubWindow(pSubWindow);
  }
  if (!checkPreferedView || pModelWidget->getLibraryTreeNode()->getLibraryType() != LibraryTreeNode::Modelica)
    return;
  // get the preferred view to display
  mpMainWindow->getOMCProxy()->sendCommand(QString("getNamedAnnotation(").append(pModelWidget->getLibraryTreeNode()->getNameStructure()).append(", preferredView)"));
  QStringList preferredViewList = StringHandler::unparseStrings(mpMainWindow->getOMCProxy()->getResult());
  if (!preferredViewList.isEmpty())
  {
    QString preferredView = preferredViewList.at(0);
    if (preferredView.compare("info") == 0)
    {
      pModelWidget->showDocumentationView();
      loadPreviousViewType(pModelWidget);
    }
    else if (preferredView.compare("text") == 0)
    {
      pModelWidget->getTextViewToolButton()->setChecked(true);
    }
    else
    {
      pModelWidget->getDiagramViewToolButton()->setChecked(true);
    }
  }
  else if (pModelWidget->getLibraryTreeNode()->isDocumentationClass())
  {
    pModelWidget->showDocumentationView();
    loadPreviousViewType(pModelWidget);
  }
  else if (pModelWidget->getModelWidgetContainer()->getPreviousViewType() != StringHandler::NoView)
  {
    loadPreviousViewType(pModelWidget);
  }
  else
  {
    QString defaultView = mpMainWindow->getOptionsDialog()->getGeneralSettingsPage()->getDefaultView();
    if (defaultView.compare(Helper::iconView) == 0)
    {
      pModelWidget->getIconViewToolButton()->setChecked(true);
    }
    else if (defaultView.compare(Helper::textView) == 0)
    {
      pModelWidget->getTextViewToolButton()->setChecked(true);
    }
    else if (defaultView.compare(Helper::documentationView) == 0)
    {
      pModelWidget->showDocumentationView();
      loadPreviousViewType(pModelWidget);
    }
    else
    {
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
  if (!object || isHidden() || qApp->activeWindow() != mpMainWindow)
    return QMdiArea::eventFilter(object, event);
  // Global key events with Ctrl modifier.
  if (event->type() == QEvent::KeyPress || event->type() == QEvent::KeyRelease)
  {
    if (subWindowList(QMdiArea::ActivationHistoryOrder).size() > 0)
    {
      QKeyEvent *keyEvent = static_cast<QKeyEvent*>(event);
      // Ingore key events without a Ctrl modifier (except for press/release on the modifier itself).
#ifdef Q_OS_MAC
      if (!(keyEvent->modifiers() & Qt::AltModifier) && keyEvent->key() != Qt::Key_Alt)
#else
      if (!(keyEvent->modifiers() & Qt::ControlModifier) && keyEvent->key() != Qt::Key_Control)
#endif
        return QMdiArea::eventFilter(object, event);
      // check key press
      const bool keyPress = (event->type() == QEvent::KeyPress) ? true : false;
      switch (keyEvent->key()) {
#ifdef Q_OS_MAC
        case Qt::Key_Alt:
#else
        case Qt::Key_Control:
#endif
          if (keyPress)
          {
            // add items to mpRecentModelsList to show in mpModelSwitcherDialog
            mpRecentModelsList->clear();
            QList<QMdiSubWindow*> subWindowsList = subWindowList(QMdiArea::ActivationHistoryOrder);
            for (int i = subWindowsList.size() - 1 ; i >= 0 ; i--)
            {
              ModelWidget *pModelWidget = qobject_cast<ModelWidget*>(subWindowsList.at(i)->widget());
              QListWidgetItem *listItem = new QListWidgetItem(mpRecentModelsList);
              listItem->setText(pModelWidget->getLibraryTreeNode()->getNameStructure());
              listItem->setData(Qt::UserRole, pModelWidget->getLibraryTreeNode()->getNameStructure());
            }
          }
          else
          {
            if (!mpRecentModelsList->selectedItems().isEmpty())
              openRecentModelWidget(mpRecentModelsList->selectedItems().at(0));
            mpModelSwitcherDialog->hide();
          }
          break;
        case Qt::Key_Tab:
        case Qt::Key_Backtab:
          if (keyPress)
          {
            if (keyEvent->key() == Qt::Key_Tab)
              changeRecentModelsListSelection(true);
            else
              changeRecentModelsListSelection(false);
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
  if (count < 1)
    return;
  int currentRow = mpRecentModelsList->currentRow();
  if (moveDown)
  {
    if (currentRow < count - 1)
      mpRecentModelsList->setCurrentRow(currentRow + 1);
    else
      mpRecentModelsList->setCurrentRow(0);
  }
  else if (!moveDown)
  {
    if (currentRow == 0)
      mpRecentModelsList->setCurrentRow(count - 1);
    else
      mpRecentModelsList->setCurrentRow(currentRow - 1);
  }
}

void ModelWidgetContainer::loadPreviousViewType(ModelWidget *pModelWidget)
{
  switch (pModelWidget->getModelWidgetContainer()->getPreviousViewType())
  {
    case StringHandler::Diagram:
      pModelWidget->getDiagramViewToolButton()->setChecked(true);
      break;
    case StringHandler::Icon:
      pModelWidget->getIconViewToolButton()->setChecked(true);
      break;
    case StringHandler::ModelicaText:
      pModelWidget->getTextViewToolButton()->setChecked(true);
      break;
    default:
      pModelWidget->getDiagramViewToolButton()->setChecked(true);
      break;
  }
}

void ModelWidgetContainer::saveModelicaModelWidget(ModelWidget *pModelWidget)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (!pModelWidget->getModelicaTextEditor()->validateModelicaText()) {
    return;
  }
  if (pModelWidget->getModelicaTextEditor()->isVisible()) {
    QString text = mpMainWindow->getOMCProxy()->list(pModelWidget->getLibraryTreeNode()->getNameStructure());
    pModelWidget->getModelicaTextEditor()->setPlainText(text);
  }
  mpMainWindow->getLibraryTreeWidget()->saveLibraryTreeNode(pModelWidget->getLibraryTreeNode());
}

void ModelWidgetContainer::saveTextModelWidget(ModelWidget *pModelWidget)
{
  mpMainWindow->getLibraryTreeWidget()->saveLibraryTreeNode(pModelWidget->getLibraryTreeNode());
}

void ModelWidgetContainer::openRecentModelWidget(QListWidgetItem *pItem)
{
  LibraryTreeNode *pLibraryTreeNode = mpMainWindow->getLibraryTreeWidget()->getLibraryTreeNode(pItem->data(Qt::UserRole).toString());
  addModelWidget(pLibraryTreeNode->getModelWidget(), false);
}

void ModelWidgetContainer::currentModelWidgetChanged(QMdiSubWindow *pSubWindow)
{
  bool enabled, modelica, text, xml;
  ModelWidget *pModelWidget;
  LibraryTreeNode *pLibraryTreeNode;
  if (pSubWindow)
  {
    enabled = true;
    pModelWidget = qobject_cast<ModelWidget*>(pSubWindow->widget());
    pLibraryTreeNode = pModelWidget->getLibraryTreeNode();
    if (pLibraryTreeNode->getLibraryType() == LibraryTreeNode::Modelica)
    {
      modelica = true;
      text = false;
      xml = false;
    }
    else if (pLibraryTreeNode->getLibraryType() == LibraryTreeNode::Text)
    {
      modelica = false;
      text = true;
      xml = false;
    }
    else
    {
      modelica = false;
      text = false;
      xml = true;
    }
  }
  else
  {
    enabled = false;
    modelica = false;
    text = false;
    xml = false;
    pModelWidget = 0;
    pLibraryTreeNode = 0;
  }
  // update the actions of the menu and toolbars
  getMainWindow()->getSaveAction()->setEnabled(enabled);
  //  getMainWindow()->getSaveAsAction()->setEnabled(enabled);
  //  getMainWindow()->getSaveAllAction()->setEnabled(enabled);
  getMainWindow()->getSaveTotalModelAction()->setEnabled(enabled && modelica);
  getMainWindow()->getShowGridLinesAction()->setEnabled(enabled && modelica);
  getMainWindow()->getResetZoomAction()->setEnabled(enabled && modelica);
  getMainWindow()->getZoomInAction()->setEnabled(enabled && modelica);
  getMainWindow()->getZoomOutAction()->setEnabled(enabled && modelica);
  getMainWindow()->getSimulateModelAction()->setEnabled(enabled && modelica);
  getMainWindow()->getSimulateWithAlgorithmicDebuggerAction()->setEnabled(enabled && modelica);
  getMainWindow()->getSimulationSetupAction()->setEnabled(enabled && modelica);
  getMainWindow()->getInstantiateModelAction()->setEnabled(enabled && modelica);
  getMainWindow()->getCheckModelAction()->setEnabled(enabled && modelica);
  getMainWindow()->getCheckAllModelsAction()->setEnabled(enabled && modelica);
  getMainWindow()->getExportFMUAction()->setEnabled(enabled && modelica);
  getMainWindow()->getExportXMLAction()->setEnabled(enabled && modelica);
  getMainWindow()->getExportFigaroAction()->setEnabled(enabled && modelica);
  getMainWindow()->getExportToOMNotebookAction()->setEnabled(enabled && modelica);
  getMainWindow()->getExportAsImageAction()->setEnabled(enabled && modelica);
  getMainWindow()->getPrintModelAction()->setEnabled(enabled);
  /* disable the save actions if class is a system library class. */
  if (pModelWidget)
  {
    if (pModelWidget->getLibraryTreeNode()->isSystemLibrary())
    {
      getMainWindow()->getSaveAction()->setEnabled(false);
      getMainWindow()->getSaveAsAction()->setEnabled(false);
      getMainWindow()->getSaveAllAction()->setEnabled(false);
    }
  }
  /* enable/disable the find/replace and goto line actions depending on the text editor visibility. */
  if (pModelWidget)
  {
    if (pModelWidget->getLibraryTreeNode()->getLibraryType() == LibraryTreeNode::Modelica && pModelWidget->getModelicaTextEditor()->isVisible())
      enabled = true;
    else if (pModelWidget->getLibraryTreeNode()->getLibraryType() == LibraryTreeNode::Text && pModelWidget->getTextEditor()->isVisible())
      enabled = true;
    else if (pModelWidget->getLibraryTreeNode()->getLibraryType() == LibraryTreeNode::TLM && pModelWidget->getTLMEditor()->isVisible())
      enabled = true;
    else
      enabled = false;
  }
  else
  {
    enabled = false;
  }
  getMainWindow()->getFindReplaceAction()->setEnabled(enabled);
  getMainWindow()->getGotoLineNumberAction()->setEnabled(enabled);
}

void ModelWidgetContainer::saveModelWidget()
{
  ModelWidget *pModelWidget = getCurrentModelWidget();
  // if pModelWidget = 0
  if (!pModelWidget)
  {
    QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                             GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN).arg(tr("saving")), Helper::ok);
    return;
  }
  LibraryTreeNode *pLibraryTreeNode = pModelWidget->getLibraryTreeNode();
  if (pLibraryTreeNode && pLibraryTreeNode->getLibraryType() == LibraryTreeNode::Modelica) {
    saveModelicaModelWidget(pModelWidget);
  } else if (pLibraryTreeNode && pLibraryTreeNode->getLibraryType() == LibraryTreeNode::Text) {
    saveTextModelWidget(pModelWidget);
  } else if (pLibraryTreeNode && pLibraryTreeNode->getLibraryType() == LibraryTreeNode::TLM) {
    saveTextModelWidget(pModelWidget);
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
  if (!pModelWidget->getModelicaTextEditor()->validateModelicaText())
    return;
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
  if (!pModelWidget->getModelicaTextEditor()->validateModelicaText())
    return;
  if (pModelWidget->getModelicaTextEditor()->isVisible())
    pModelWidget->getModelicaTextEditor()->setPlainText(mpMainWindow->getOMCProxy()->list(pModelWidget->getLibraryTreeNode()->getNameStructure()));
  /* save total model */
  LibraryTreeNode *pLibraryTreeNode = pModelWidget->getLibraryTreeNode();
  mpMainWindow->getStatusBar()->showMessage(QString(tr("Saving")).append(" ").append(pLibraryTreeNode->getNameStructure()));
  mpMainWindow->showProgressBar();
  QString fileName;
  QString name = pLibraryTreeNode->getName();
  fileName = StringHandler::getSaveFileName(this, QString(Helper::applicationName).append(" - ").append(tr("Save Total Model")), NULL,
                                            Helper::omFileTypes, NULL, "mo", &name);
  if (fileName.isEmpty())   // if user press ESC
    return;
  /* if user has done some changes in the Modelica text view then save & validate it in the AST before saving it to file. */
  if (pLibraryTreeNode->getModelWidget())
  {
    if (!pLibraryTreeNode->getModelWidget()->getModelicaTextEditor()->validateModelicaText())
      return;
  }
  // save the model through OMC
  mpMainWindow->getOMCProxy()->saveTotalSCode(fileName, pLibraryTreeNode->getNameStructure());
  mpMainWindow->getStatusBar()->clearMessage();
  mpMainWindow->hideProgressBar();
}

void ModelWidgetContainer::printModel()
{
#ifndef QT_NO_PRINTER
  if (ModelWidget *pModelWidget = getCurrentModelWidget())
  {
    QPrinter printer(QPrinter::ScreenResolution);

    if (pModelWidget->getModelicaTextEditor()->isVisible())
    {
      ModelicaTextEditor  *pModelicaTextEdit = pModelWidget->getModelicaTextEditor();
      QPrintDialog *pPrintDialog = new QPrintDialog(&printer, this);
      pPrintDialog->setWindowTitle(tr("Print Document"));
      if (pModelicaTextEdit->textCursor().hasSelection())
        pPrintDialog->addEnabledOption(QAbstractPrintDialog::PrintSelection);
      if (pPrintDialog->exec() == QDialog::Accepted)
        pModelicaTextEdit->print(&printer);
      delete pPrintDialog;
    }
    else
    {
      GraphicsView *pGraphicsView;
      if (pModelWidget->getIconGraphicsView()->isVisible())
        pGraphicsView = pModelWidget->getIconGraphicsView();
      else
        pGraphicsView = pModelWidget->getDiagramGraphicsView();

      printer.setPageSize(QPrinter::A4);
      if (QPrintDialog(&printer).exec() == QDialog::Accepted)
      {
        QPainter painter(&printer);
        painter.setRenderHint(QPainter::HighQualityAntialiasing);
        pGraphicsView->render(&painter);
        painter.end();
      }
    }
  }
#endif
}
