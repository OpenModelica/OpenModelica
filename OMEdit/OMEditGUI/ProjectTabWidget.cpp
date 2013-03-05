/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 * Contributors 2011: Abhinn Kothari
 */

/*
 * HopsanGUI
 * Fluid and Mechatronic Systems, Department of Management and Engineering, Linkoping University
 * Main Authors 2009-2010:  Robert Braun, Bjorn Eriksson, Peter Nordin
 * Contributors 2009-2010:  Mikael Axin, Alessandro Dell'Amico, Karl Pettersson, Ingo Staack
 */

/*
 * RCS: $Id$
 */

#include <QtGui>
#include <QMap>

#include "ProjectTabWidget.h"
#include "LibraryWidget.h"
#include "mainwindow.h"

//! @class GraphicsView
//! @brief The GraphicsView class is a class which display the content of a scene of components.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
GraphicsView::GraphicsView(int iconType, ProjectTab *parent)
  : QGraphicsView(parent), mIconType(iconType), mSkipBackground(false)
{
  mpParentProjectTab = parent;
  setFrameShape(QGraphicsView::NoFrame);
  setDragMode(QGraphicsView::RubberBandDrag);
  setInteractive(true);
  setEnabled(true);
  setAcceptDrops(true);
  mIsCreatingConnector = false;
  mIsMovingComponents = false;
  mIsCreatingLine = false;
  mIsCreatingPolygon = false;
  mIsCreatingRectangle = false;
  mIsCreatingEllipse = false;
  mIsCreatingText = false;
  mIsCreatingBitmap = false;
  mCustomScale = false;
  setViewportUpdateMode(QGraphicsView::FullViewportUpdate);
  setTransformationAnchor(QGraphicsView::AnchorUnderMouse);
  setSceneRect(-100.0, -100.0, 200.0, 200.0);
  centerOn(sceneRect().center());
  createActions();
  scale(1.0, -1.0);
  // if user is viewing some readonly component then dont draw backgrounds.
  if (!mpParentProjectTab->isReadOnly())
  {
    if (mIconType == StringHandler::DIAGRAM)
    {
      setStyleSheet(QString("background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1").append(", stop: 0 lightGray, stop: 1 gray);"));
    }
    // change the background shade if user is in Icon View
    else if (mIconType == StringHandler::ICON)
    {
      setStyleSheet(QString("background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1").append(", stop: 0 gray, stop: 1 lightGray);"));
    }
  }
  connect(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpGridLinesAction, SIGNAL(toggled(bool)), this,
          SLOT(showGridLines(bool)));
  connect(this, SIGNAL(currentChange(int)),mpParentProjectTab->mpParentProjectTabWidget, SLOT(tabChanged()));
}

void GraphicsView::drawBackground(QPainter *painter, const QRectF &rect)
{
  Q_UNUSED(rect);

  if (mpParentProjectTab->isReadOnly() || mSkipBackground)
    return;
  // draw scene rectangle
  painter->setPen(Qt::black);
  painter->setBrush(QBrush(Qt::white, Qt::SolidPattern));
  painter->drawRect(sceneRect());
  //! @todo Grid Lines changes when resize the window. Update it.
  if (mpParentProjectTab->mpParentProjectTabWidget->mShowLines)
  {
    painter->setBrush(Qt::NoBrush);
    painter->setPen(Qt::gray);

    int xAxis = sceneRect().x();
    int yAxis = sceneRect().y();
    // Horizontal Lines
    yAxis += 20;
    while (yAxis < sceneRect().right())
    {
      painter->drawLine(xAxis, yAxis, sceneRect().right(), yAxis);
      yAxis += 20;
    }
    // Vertical Lines
    yAxis = sceneRect().y();
    xAxis += 20;
    while (xAxis < sceneRect().bottom())
    {
      painter->drawLine(xAxis, yAxis, xAxis, sceneRect().bottom());
      xAxis += 20;
    }
  }
  //draw scene rectangle again without brush
  painter->setPen(Qt::black);
  painter->setBrush(Qt::NoBrush);
  painter->drawRect(sceneRect());
}

//! Defines what happens when moving an object in a GraphicsView.
//! @param event contains information of the drag operation.
void GraphicsView::dragMoveEvent(QDragMoveEvent *event)
{
  // check if the view is readonly or not
  if (mpParentProjectTab->isReadOnly())
  {
    event->ignore();
    return;
  }

  if (event->mimeData()->hasFormat("image/modelica-component") || event->mimeData()->hasFormat("text/uri-list"))
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
  MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
  ProblemsWidget *pMessageWidget = pMainWindow->mpMessageWidget;
  // check if the view is readonly or not
  if (mpParentProjectTab->isReadOnly())
  {
    event->ignore();
    return;
  }

  if (!event->mimeData()->hasFormat("image/modelica-component") && !event->mimeData()->hasFormat("text/uri-list"))
  {
    event->ignore();
    return;
  }
  else
  {
    if (event->mimeData()->hasFormat("text/uri-list"))
    {
      bool fileOpened = false;
      foreach (QUrl fileUrl, event->mimeData()->urls())
      {
        QFileInfo fileInfo(fileUrl.toLocalFile());
        if (fileInfo.suffix().compare("mo", Qt::CaseInsensitive) == 0)
        {
          mpParentProjectTab->mpParentProjectTabWidget->openFile(fileInfo.absoluteFilePath());
          fileOpened = true;
        }
        else
        {
          QString message = QString(GUIMessages::getMessage(GUIMessages::FILE_FORMAT_NOT_SUPPORTED).arg(fileInfo.fileName()));
          pMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0, message, Helper::scriptingKind, Helper::errorLevel,
                                                        0, pMessageWidget->mpProblem));
        }
      }
      // if one file is valid and opened then accept the event
      if (fileOpened)
      {
        event->accept();
        return;
      }
      // if all files are invalid Modelica files ignore the event.
      else
      {
        event->ignore();
        return;
      }
    }
    else
    {
      QByteArray itemData = event->mimeData()->data("image/modelica-component");
      QDataStream dataStream(&itemData, QIODevice::ReadOnly);

      QString name, classname;
      int type;
      QPointF point (mapToScene(event->pos()));
      dataStream >> name >> classname >> type;

      //item not to be dropped on itself
      name = StringHandler::getLastWordAfterDot(name);
      if (name != mpParentProjectTab->mModelName)
      {
        // get the model defaultComponentPrefixes
        QString defaultPrefix = pMainWindow->mpOMCProxy->getDefaultComponentPrefixes(classname);
        // get the model defaultComponentName
        QString defaultName = pMainWindow->mpOMCProxy->getDefaultComponentName(classname);
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
            if (defaultPrefix.compare("inner") == 0)
            {
              pMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0,
                                                            GUIMessages::getMessage(GUIMessages::INNER_MODEL_NAME_CHANGED)
                                                            .arg(defaultName).arg(name).arg(defaultPrefix),
                                                            Helper::scriptingKind, Helper::errorLevel, 0, pMessageWidget->mpProblem));
            }
          }
        }
        // if dropping an item on the diagram layer
        if (mIconType == StringHandler::DIAGRAM)
        {
          // if item is a class, model, block, connector or record. then we can drop it to the graphicsview
          if ((type == StringHandler::CLASS) or (type == StringHandler::MODEL) or (type == StringHandler::BLOCK) or
              (type == StringHandler::CONNECTOR) or (type == StringHandler::RECORD))
          {
            if (type == StringHandler::CONNECTOR)
            {
              mpParentProjectTab->mpIconGraphicsView->addComponentoView(name, classname, point, true, false);
              addComponentoView(name, classname, point, true, true, true);
              mpParentProjectTab->mpIconGraphicsView->addClassAnnotation();
            }
            else
            {
              addComponentoView(name, classname, point);
            }
            event->accept();
            emit currentChange(1);
          }
          else
          {
            pMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::DIAGRAM_VIEW_DROP_MSG)
                                                          .arg(classname).arg(StringHandler::getModelicaClassType(type)),
                                                          Helper::scriptingKind, Helper::notificationLevel, 0, pMessageWidget->mpProblem));
            event->ignore();
          }
        }
        // if dropping an item on the icon layer
        else if (mIconType == StringHandler::ICON)
        {
          // if item is a connector. then we can drop it to the graphicsview
          if (type == StringHandler::CONNECTOR)
          {
            addComponentoView(name, classname, point, true, false);
            mpParentProjectTab->mpDiagramGraphicsView->addComponentoView(name, classname, point, true, true, true);
            addClassAnnotation();
            event->accept();
            emit currentChange(1);
          }
          else
          {
            pMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::ICON_VIEW_DROP_MSG).arg(classname)
                                                          .arg(StringHandler::getModelicaClassType(type)),Helper::scriptingKind,
                                                          Helper::notificationLevel, 0, pMessageWidget->mpProblem));
            event->ignore();
          }
        }
      }
      //if dropping an item on itself
      else
      {
        pMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0,
                                                      GUIMessages::getMessage(GUIMessages::ITEM_DROPPED_ON_ITSELF),
                                                      Helper::scriptingKind, Helper::notificationLevel, 0, pMessageWidget->mpProblem));
        event->ignore();
      }
    }
  }
}

void GraphicsView::addComponentoView(QString name, QString className, QPointF point, bool isConnector, bool addObject, bool diagram)
{
  MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
  // Check if the icon is already loaded.
  Component *oldComponent = pMainWindow->mpLibrary->getComponentObject(className);
  Component *newComponent;

  // if the item is a connector then we need to get the diagram annotation of it
  if (diagram)
  {
    QString result = pMainWindow->mpOMCProxy->getDiagramAnnotation(className);
    newComponent = new Component(result, name, className, point, StringHandler::ICON, isConnector, pMainWindow->mpOMCProxy, this);
  }
  else
  {
    if (!oldComponent)
    {
      LibraryComponent *libComponent;
      QString result = pMainWindow->mpOMCProxy->getIconAnnotation(className);
      libComponent = new LibraryComponent(result, className, pMainWindow->mpOMCProxy);
      // add the component to library widget components lists
      pMainWindow->mpLibrary->addComponentObject(libComponent);
      // create a new component now.
      newComponent = new Component(result, name, className, point, StringHandler::ICON, isConnector, pMainWindow->mpOMCProxy, this);
    }
    else
    {
      newComponent = new Component(oldComponent, name, point, StringHandler::ICON, isConnector, this);
    }
  }
  if (addObject)
    addComponentObject(newComponent);
  else
    mComponentsList.append(newComponent);
}

void GraphicsView::addComponentObject(Component *component)
{
  MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
  // Add the component to model in OMC Global Scope.
  pMainWindow->mpOMCProxy->addComponent(component->getName(), component->getClassName(), mpParentProjectTab->mModelNameStructure);
  // add the annotations of icon
  if (component->getIsConnector())
    component->updateAnnotationString(true);
  else
    component->updateAnnotationString(false);
  // only update the modelicatext of model if its a diagram view
  // for icon view the modeltext is updated in updateannotationstring->addclassannotation
  if (mIconType == StringHandler::DIAGRAM)
    mpParentProjectTab->mpModelicaEditor->setPlainText(pMainWindow->mpOMCProxy->list(mpParentProjectTab->mModelNameStructure));
  // add the component to the local list
  mComponentsList.append(component);
  // emit currentchange signal so that componentbrowsertree is updated
  //emit currentChange(1);
}

//! Delete the component and its corresponding connectors from the components list and OMC.
//! @param component is the object to be deleted.
//! @param update flag is used to check whether we need to update the modelica editor text or not.
//! @see deleteAllComponentObjects()
void GraphicsView::deleteComponentObject(Component *component, bool update)
{
  // First Remove the Connector associated to this icon
  int i = 0;
  while(i != mConnectorsVector.size())
  {
    if((mConnectorsVector[i]->getStartComponent()->getParentComponent()->getName() == component->getName()) or
       (mConnectorsVector[i]->getEndComponent()->getParentComponent()->getName() == component->getName()))
    {
      removeConnector(mConnectorsVector[i], update);
      i = 0;   //Restart iteration if map has changed
    }
    else
    {
      ++i;
    }
  }
  // remove the icon now from local list
  mComponentsList.removeOne(component);
  OMCProxy *pOMCProxy = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy;
  // delete the component from OMC
  pOMCProxy->deleteComponent(component->getName(), mpParentProjectTab->mModelNameStructure);
  if (update)
  {
    mpParentProjectTab->mpModelicaEditor->setPlainText(pOMCProxy->list(mpParentProjectTab->mModelNameStructure));
    // emit currentchange signal so that componentbrowsertree is updated
    emit currentChange(1);
  }
}

//! Delete all the component and their corresponding connectors from the model.
//! @see deleteComponentObject(Component *component, bool update)
void GraphicsView::deleteAllComponentObjects()
{
  mComponentsList.clear();
  //    foreach (Component *component, mComponentsList)
  //    {
  //        component->deleteMe(false);
  //    }
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

QString GraphicsView::getUniqueComponentName(QString iconName, int number)
{
  QString name;
  name = QString(iconName).append(QString::number(number));

  foreach (Component *icon, mComponentsList)
  {
    if (icon->getName().compare(name, Qt::CaseSensitive) == 0)
    {
      name = getUniqueComponentName(iconName, ++number);
      break;
    }
  }
  return name;
}

bool GraphicsView::checkComponentName(QString iconName)
{
  foreach (Component *icon, mComponentsList)
  {
    if (icon->getName().compare(iconName, Qt::CaseSensitive) == 0)
    {
      return false;
    }
  }

  return true;
}

void GraphicsView::addShapeObject(ShapeAnnotation *shape)
{
  mShapesList.append(shape);
}

void GraphicsView::deleteShapeObject(ShapeAnnotation *shape)
{
  mShapesList.removeOne(shape);
}

void GraphicsView::deleteAllShapesObject()
{
  mShapesList.clear();
  //    foreach (ShapeAnnotation *shape, mShapesList)
  //    {
  //        shape->deleteMe();
  //    }
}

void GraphicsView::removeAllConnectors()
{
  mConnectorsVector.clear();
  //    int i = 0;
  //    while(i != mConnectorsVector.size())
  //    {
  //        removeConnector(mConnectorsVector[i], false);
  //        i = 0;   //Restart iteration if map has changed
  //    }
}

//! Defines what happens when the mouse is moving in a GraphicsView.
//! @param event contains information of the mouse moving operation.
void GraphicsView::mouseMoveEvent(QMouseEvent *event)
{
  // don't send mouse move events to items if we are creating something
  if (!mIsCreatingConnector and !mIsCreatingLine and !mIsCreatingPolygon and !mIsCreatingRectangle
      and !mIsCreatingEllipse and !mIsCreatingText and !mIsCreatingBitmap)
  {
    QGraphicsView::mouseMoveEvent(event);
  }

  //If creating connector, the end port shall be updated to the mouse position.
  if (mIsCreatingConnector)
  {
    mpConnector->updateEndPoint(mapToScene(event->pos()));
    mpConnector->drawConnector();
  }
  //If creating line shape, the end points shall be updated to the mouse position.
  else if (mIsCreatingLine)
  {
    mpLineShape->updateEndPoint(mapToScene(event->pos()));
    mpLineShape->update();
  }
  //If creating polygon shape, the end points shall be updated to the mouse position.
  else if (mIsCreatingPolygon)
  {
    mpPolygonShape->updateEndPoint(mapToScene(event->pos()));
    mpPolygonShape->update();
  }
  //If creating rectangle shape, the end points shall be updated to the mouse position.
  else if (mIsCreatingRectangle)
  {
    mpRectangleShape->updateEndPoint(mapToScene(event->pos()));
    mpRectangleShape->update();
  }
  //If creating ellipse shape, the end points shall be updated to the mouse position.
  else if (mIsCreatingEllipse)
  {
    mpEllipseShape->updateEndPoint(mapToScene(event->pos()));
    mpEllipseShape->update();
  }
  //If creating text shape, the end points shall be updated to the mouse position.
  else if (mIsCreatingText)
  {
    mpTextShape->updateEndPoint(mapToScene(event->pos()));
    mpTextShape->update();
  }
  //If creating bitmap shape, the end points shall be updated to the mouse position.
  else if (mIsCreatingBitmap)
  {
    mpBitmapShape->updateEndPoint(mapToScene(event->pos()));
    mpBitmapShape->update();
  }
}

//! Defines what happens when clicking in a GraphicsView.
//! @param event contains information of the mouse click operation.
void GraphicsView::mousePressEvent(QMouseEvent *event)
{

  MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
  // if left button presses and we are creating a connector
  if ((event->button() == Qt::LeftButton) && (mIsCreatingConnector))
  {
    mpConnector->addPoint(mapToScene(event->pos()));

  }
  // if left button presses and we are starting to create a Line
  else if ((event->button() == Qt::LeftButton) && pMainWindow->mpLineAction->isChecked())
  {
    // if we are starting to create a line then create line object and add to graphicsview
    createLineShape(mapToScene(event->pos()));
  }
  // if left button presses and we are starting to create a Polygon
  else if ((event->button() == Qt::LeftButton) && pMainWindow->mpPolygonAction->isChecked())
  {
    // if we are starting to create a polygon then create line object and add to graphicsview
    createPolygonShape(mapToScene(event->pos()));
  }
  // if left button presses and we are starting to create a Rectangle
  else if ((event->button() == Qt::LeftButton) && pMainWindow->mpRectangleAction->isChecked())
  {
    // if we are starting to create a rectangle then create rectangle object and add to graphicsview
    createRectangleShape(mapToScene(event->pos()));
  }
  // if left button presses and we are starting to create an Ellipse
  else if ((event->button() == Qt::LeftButton) && pMainWindow->mpEllipseAction->isChecked())
  {
    // if we are starting to create a rectangle then create rectangle object and add to graphicsview
    createEllipseShape(mapToScene(event->pos()));
  }
  // if left button presses and we are starting to create a Text
  else if ((event->button() == Qt::LeftButton) && pMainWindow->mpTextAction->isChecked())
  {
    // if we are starting to create a text then create text object and add to graphicsview
    createTextShape(mapToScene(event->pos()));
  }
  // if left button presses and we are starting to create a BITMAP
  else if ((event->button() == Qt::LeftButton) && pMainWindow->mpBitmapAction->isChecked())
  {
    // if we are starting to create a BITMAP then create BITMAP object and add to graphicsview
    createBitmapShape(mapToScene(event->pos()));
  }
  // if left button presses and we are not creating a connector
  else if ((event->button() == Qt::LeftButton))
  {
    // this flag is just used to have seperate identify for if statement in mouse release event of graphicsview
    mIsMovingComponents = true;
    // save the position of all components

    foreach (Component *component, mComponentsList)
    {
      component->mOldPosition = component->pos();
      component->isMousePressed = true;
    }
  }
  /* don't send mouse press events to items if we are creating something, only send them if creating a connector
       because for connector we need to select end port */
  if (!mIsCreatingLine and !mIsCreatingPolygon and !mIsCreatingRectangle and !mIsCreatingEllipse
      and !mIsCreatingText and !mIsCreatingBitmap)
  {
    QGraphicsView::mousePressEvent(event);
  }
}

void GraphicsView::mouseReleaseEvent(QMouseEvent *event)
{

  if ((event->button() == Qt::LeftButton) && (mIsMovingComponents))
  {
    mIsMovingComponents = false;
    // if component position is changed then update annotations
    foreach (Component *component, mComponentsList)
    {
      if (component->mOldPosition != component->pos())
      {
        if(component->getIsConnector())
        {
          Component *pComponent;
          if (mIconType == StringHandler::ICON)
          {
            pComponent = mpParentProjectTab->mpDiagramGraphicsView->getComponentObject(component->getName());
            pComponent->setPos(component->pos());
          }
          else if(mIconType == StringHandler::DIAGRAM)
          {
            pComponent = mpParentProjectTab->mpIconGraphicsView->getComponentObject(component->getName());
            pComponent->setPos(component->pos());
          }
          pComponent->updateAnnotationString();

        }
        component->updateAnnotationString();
        // if there are any connectors associated to component update their annotations as well.
        foreach (Connector *connector, mConnectorsVector)
        {
          if ((connector->getStartComponent()->mpParentComponent == component) or
              (connector->getEndComponent()->mpParentComponent == component) or (connector->getStartComponent() == component) or
              (connector->getEndComponent() == component))
          {
            connector->updateConnectionAnnotationString();
          }

        }
        mpParentProjectTab->mpModelicaEditor->setPlainText(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy->list(mpParentProjectTab->mModelNameStructure));
      }
      component->isMousePressed = false;
    }
  }
  QGraphicsView::mouseReleaseEvent(event);
}

void GraphicsView::mouseDoubleClickEvent(QMouseEvent *event)
{
  MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
  if (mIsCreatingLine)
  {
    // finish creating the line
    mIsCreatingLine = false;
    // add the line to shapes list
    addShapeObject(mpLineShape);
    mpLineShape->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
    mpLineShape->drawRectangleCornerItems();
    // make the toolbar button of line unchecked
    pMainWindow->mpLineAction->setChecked(false);
  }
  else if (mIsCreatingPolygon)
  {
    // finish creating the line
    mIsCreatingPolygon = false;
    // add the line to shapes list
    addShapeObject(mpPolygonShape);
    mpPolygonShape->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
    mpPolygonShape->drawRectangleCornerItems();
    // make the toolbar button of line unchecked
    pMainWindow->mpPolygonAction->setChecked(false);
  }
  QGraphicsView::mouseDoubleClickEvent(event);
}

void GraphicsView::keyPressEvent(QKeyEvent *event)
{
  if (event->key() == Qt::Key_Delete)
  {
    emit keyPressDelete();
    // once all selected items are deleted simply update the icon/diagram annotations.
    //addClassAnnotation();
  }
  else if(event->key() == Qt::Key_Up)
  {
    emit keyPressUp();
  }
  else if(event->key() == Qt::Key_Down)
  {
    emit keyPressDown();
  }
  else if(event->key() == Qt::Key_Left)
  {
    emit keyPressLeft();
  }
  else if(event->key() == Qt::Key_Right)
  {
    emit keyPressRight();
  }
  else if (event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_A)
  {
    selectAll();
  }
  else if (!event->modifiers().testFlag(Qt::ShiftModifier) and event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_R)
  {
    emit keyPressRotateClockwise();
  }
  else if (event->modifiers().testFlag(Qt::ShiftModifier) and event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_R)
  {
    emit keyPressRotateAntiClockwise();
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
  QGraphicsView::keyReleaseEvent(event);
}

void GraphicsView::createActions()
{
  // Connection Delete Action
  mpCancelConnectionAction = new QAction(QIcon(":/Resources/icons/delete.png"), "", this);
  mpCancelConnectionAction->setStatusTip(tr("Cancels the current connection"));
  connect(mpCancelConnectionAction, SIGNAL(triggered()), SLOT(removeConnector()));
  // Icon Rotate ClockWise Action
  mpRotateIconAction = new QAction(QIcon(":/Resources/icons/rotateclockwise.png"), tr("Rotate Clockwise"), this);
  mpRotateIconAction->setStatusTip(tr("Rotate the item clockwise"));
  mpRotateIconAction->setShortcut(QKeySequence("Ctrl+r"));
  // Icon Horizontal Flip Action
  mpHorizontalFlipAction = new QAction(tr("Horizontal Flip"), this);
  //mpHorizontalFlipAction->toggle();
  mpHorizontalFlipAction->setStatusTip(tr("Flip the item horizontally"));
  // Icon Vertical Flip Action
  mpVerticalFlipAction = new QAction(tr("Vertical Flip"), this);
  mpVerticalFlipAction->setStatusTip(tr("Flip the item vertically"));
  // Icon Rotate Anti-ClockWise Action
  mpRotateAntiIconAction = new QAction(QIcon(":/Resources/icons/rotateanticlockwise.png"), tr("Rotate Anticlockwise"), this);
  mpRotateAntiIconAction->setStatusTip(tr("Rotate the item anticlockwise"));
  mpRotateAntiIconAction->setShortcut(QKeySequence("Ctrl+Shift+r"));
  // Icon Reset Rotation Action
  mpResetRotation = new QAction(tr("Reset Rotation"), this);
  mpResetRotation->setStatusTip(tr("Reset the item rotation"));
  // Icon Delete Action
  mpDeleteIconAction = new QAction(QIcon(":/Resources/icons/delete.png"), Helper::Delete, this);
  mpDeleteIconAction->setStatusTip(tr("Delete the item"));
  mpDeleteIconAction->setShortcut(QKeySequence::Delete);
}

void GraphicsView::createLineShape(QPointF point)
{
  if (mpParentProjectTab->isReadOnly())
    return;

  if (!mIsCreatingLine)
  {
    mIsCreatingLine = true;
    mpLineShape = new LineAnnotation(this);
    mpLineShape->addPoint(point);
    mpLineShape->addPoint(point);
    scene()->addItem(mpLineShape);
  }
  // if we are already creating a line then only add one point.
  else
  {
    mpLineShape->addPoint(point);
  }
}

void GraphicsView::createPolygonShape(QPointF point)
{
  if (mpParentProjectTab->isReadOnly())
    return;

  if (!mIsCreatingPolygon)
  {
    mIsCreatingPolygon = true;
    mpPolygonShape = new PolygonAnnotation(this);
    mpPolygonShape->addPoint(point);
    mpPolygonShape->addPoint(point);
    mpPolygonShape->addPoint(point);
    scene()->addItem(mpPolygonShape);
  }
  // if we are already creating a polygon then only add one point.
  else
  {
    mpPolygonShape->addPoint(point);
  }
}

void GraphicsView::createRectangleShape(QPointF point)
{
  if (mpParentProjectTab->isReadOnly())
    return;

  if (!mIsCreatingRectangle)
  {
    mIsCreatingRectangle = true;
    mpRectangleShape = new RectangleAnnotation(this);
    mpRectangleShape->addPoint(point);
    mpRectangleShape->addPoint(point);
    scene()->addItem(mpRectangleShape);
  }
  // if we are already creating a rectangle then simply finish creating it.
  else
  {
    // finish creating the rectangle
    mIsCreatingRectangle = false;
    // add the line to shapes list
    addShapeObject(mpRectangleShape);
    mpRectangleShape->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
    mpRectangleShape->drawRectangleCornerItems();
    // make the toolbar button of line unchecked
    mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpRectangleAction->setChecked(false);
  }
}

void GraphicsView::createEllipseShape(QPointF point)
{
  if (mpParentProjectTab->isReadOnly())
    return;

  if (!mIsCreatingEllipse)
  {
    mIsCreatingEllipse = true;
    mpEllipseShape = new EllipseAnnotation(this);
    mpEllipseShape->addPoint(point);
    mpEllipseShape->addPoint(point);
    scene()->addItem(mpEllipseShape);
  }
  // if we are already creating a rectangle then simply finish creating it.
  else
  {
    // finish creating the rectangle
    mIsCreatingEllipse = false;
    // add the line to shapes list
    addShapeObject(mpEllipseShape);
    mpEllipseShape->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
    mpEllipseShape->drawRectangleCornerItems();
    // make the toolbar button of line unchecked
    mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpEllipseAction->setChecked(false);
  }
}

void GraphicsView::createTextShape(QPointF point)
{
  if (mpParentProjectTab->isReadOnly())
    return;

  if (!mIsCreatingText)
  {
    mIsCreatingText = true;
    mpTextShape = new TextAnnotation(this);
    mpTextShape->addPoint(point);
    mpTextShape->addPoint(point);
    scene()->addItem(mpTextShape);
  }
  // if we are already creating a text then simply finish creating it.
  else
  {
    // finish creating the text
    mIsCreatingText = false;
    // add the line to shapes list
    addShapeObject(mpTextShape);
    mpTextShape->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
    mpTextShape->drawRectangleCornerItems();
    // make the toolbar button of line unchecked
    mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpTextAction->setChecked(false);
    // open the text properties dialog
    mpTextWidget = new TextWidget(mpTextShape, mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
    mpTextWidget->show();
  }
}

void GraphicsView::createBitmapShape(QPointF point)
{
  if (mpParentProjectTab->isReadOnly())
    return;

  if (!mIsCreatingBitmap)
  {
    //If  model doesnt exist, then alert the user...
    if(mpParentProjectTab->mModelFileName.isEmpty())
    {
      QMessageBox::information(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow,
                               QString(Helper::applicationName).append(" - ").append(Helper::information),
                               tr("The class needs to be saved before you can insert a bitmap."), Helper::ok);
      mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpBitmapAction->setChecked(false);
      return;
    }

    mIsCreatingBitmap = true;
    mpBitmapShape = new BitmapAnnotation(this);
    mpBitmapShape->addPoint(point);
    mpBitmapShape->addPoint(point);
    scene()->addItem(mpBitmapShape);
  }
  else
  {
    // finish creating the bitmap
    mIsCreatingBitmap = false;
    // add the line to shapes list
    addShapeObject(mpBitmapShape);
    mpBitmapShape->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
    mpBitmapShape->drawRectangleCornerItems();
    // make the toolbar button of line unchecked
    mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpBitmapAction->setChecked(false);

    mpBitmapWidget = new BitmapWidget(mpBitmapShape, mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
    mpBitmapWidget->show();
  }
}

void GraphicsView::contextMenuEvent(QContextMenuEvent *event)
{
  if (mIsCreatingConnector)
  {
    QMenu menu(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
    mpCancelConnectionAction->setText(tr("Cancel Connection"));
    menu.addAction(mpCancelConnectionAction);
    menu.exec(event->globalPos());
    return;         // return from it because at a time we only want one context menu.
  }
  // if some item is right clicked then don't show graphics view context menu
  ShapeAnnotation *pShape = static_cast<ShapeAnnotation*>(itemAt(event->pos()));
  if (!pShape)
  {
    QMenu menu(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
    mpCancelConnectionAction->setText("Context Menu");
    menu.addAction(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpExportAsImageAction);
    menu.addSeparator();
    menu.addAction(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpExportToOMNotebookAction);
    menu.exec(event->globalPos());
    return;         // return from it because at a time we only want one context menu.
  }
  QGraphicsView::contextMenuEvent(event);
}

void GraphicsView::resizeEvent(QResizeEvent *event)
{
  setStyleSheet(styleSheet().append(QString(" border: 1px solid gray;")));
  // only resize the view if user has not set any custom scaling like zoom in and zoom out.
  if (!mCustomScale)
  {
    // since some Modelica components have diagrams larger i.e chaucircuit.
    // so for such components we need to scale itemsbounding rect :) this case is only valid for modelica libray components.
    if (mpParentProjectTab->isReadOnly())
    {
      if ((sceneRect().width() < scene()->itemsBoundingRect().width()) || (sceneRect().width() < scene()->itemsBoundingRect().width()))
        fitInView(scene()->itemsBoundingRect(), Qt::KeepAspectRatio);
      else
        fitInView(sceneRect(), Qt::KeepAspectRatio);
    }
    else
    {
      fitInView(sceneRect(), Qt::KeepAspectRatio);
    }
  }
  QGraphicsView::resizeEvent(event);
}

//! Begins creation of connector or complete creation of connector depending on the mIsCreatingConnector flag.
//! @param pComponent is a pointer to the clicked Component, either start or end depending on the mIsCreatingConnector flag.
void GraphicsView::addConnector(Component *pComponent)
{
  //When clicking start port
  if (!mIsCreatingConnector)
  {
    QPointF startPos = pComponent->mapToScene(pComponent->boundingRect().center());
    mpConnector = new Connector(pComponent, this);
    scene()->addItem(mpConnector);
    mIsCreatingConnector = true;
    //if component is a connector
    if (pComponent->mpParentComponent)
      pComponent->getParentComponent()->addConnector(mpConnector);
    else
      pComponent->addConnector(mpConnector);

    mpConnector->setStartComponent(pComponent);
    mpConnector->addPoint(startPos);
    mpConnector->addPoint(startPos);
    mpConnector->drawConnector();
  }
  // When clicking end port
  else
  {
    Component *pStartComponent = mpConnector->getStartComponent();
    QString startIconName, startIconCompName, endIconName, endIconCompName;
    if (pStartComponent->mpParentComponent)
    {
      startIconName = QString(pStartComponent->mpParentComponent->getName()).append(".");
      startIconCompName = pStartComponent->mpComponentProperties->getName();
    }
    else
    {
      startIconCompName = pStartComponent->getName();
    }
    if (pComponent->mpParentComponent)
    {
      endIconName = QString(pComponent->mpParentComponent->getName()).append(".");
      endIconCompName = pComponent->mpComponentProperties->getName();
    }
    else
    {
      endIconCompName = pComponent->getName();
    }

    MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
    QList<ComponentsProperties*> startcomponents = pStartComponent->getParentComponent()->mpChildComponentProperties;
    if (startcomponents.isEmpty())
    {
      startcomponents = pMainWindow->mpOMCProxy->getComponents(pStartComponent->getParentComponent()->getClassName());
    }
    //to check whether the component is an array of connectors
    foreach(ComponentsProperties *pComponentProperties , startcomponents)
    {
      //to check whether the component is an array of connectors
      if (pComponentProperties->getName() == startIconCompName)
      {
        if (pComponentProperties->getIndexValue() != -1)
        {
          mpConnector->setStartConnectorisArray(true);
        }
      }
    }

    QList<ComponentsProperties*> endcomponents = pComponent->getParentComponent()->mpChildComponentProperties;
    if(endcomponents.isEmpty())
    {
      endcomponents = pMainWindow->mpOMCProxy->getComponents(pComponent->getParentComponent()->getClassName());
    }
    //to check whether the component is an array of connectors
    foreach(ComponentsProperties *pComponentProperties , endcomponents)
    {
      if (pComponentProperties->getName() == endIconCompName)
      {
        if (pComponentProperties->getIndexValue() != -1)
        {
          mpConnector->setEndConnectorisArray(true);
        }
      }
    }
    //if atleast one of the port is an array of connectors
    if (mpConnector->getEndConnectorisArray() || mpConnector->getStartConnectorisArray())
    {
      mpConnector->setEndComponent(pComponent);
      //shows the connector array menu for adding the index for the array
      mpConnector->mpConnectorArrayMenu->show();
    }
    else
    {
      createConnection(pStartComponent, QString(startIconName).append(startIconCompName),
                       pComponent, QString(endIconName).append(endIconCompName));
    }
  }
}

void GraphicsView::createConnection(Component *pStartComponent, QString startIconCompName, Component *pComponent, QString endIconCompName)
{
  MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
  // If both components are same
  if (pStartComponent == pComponent)
  {
    removeConnector();
    pMainWindow->mpMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0,
                                                                GUIMessages::getMessage(GUIMessages::SAME_PORT_CONNECT), Helper::scriptingKind,
                                                                Helper::errorLevel, 0, pMainWindow->mpMessageWidget->mpProblem));
  }
  else
  {
    if (pMainWindow->mpOMCProxy->addConnection(startIconCompName, endIconCompName, mpParentProjectTab->mModelNameStructure))
    {
      // Check if both ports connected are compatible or not.
      if (pMainWindow->mpOMCProxy->instantiateModelSucceeds(mpParentProjectTab->mModelNameStructure))
      {
        mIsCreatingConnector = false;
        QPointF newPos = pComponent->mapToScene(pComponent->boundingRect().center());
        mpConnector->updateEndPoint(newPos);
        if (pComponent->mpParentComponent)
          pComponent->getParentComponent()->addConnector(mpConnector);
        else
          pComponent->addConnector(mpConnector);
        mpConnector->setEndComponent(pComponent);
        // update the last point to the center of component
        mpConnector->updateEndPoint(pComponent->boundingRect().center());
        mpConnector->drawConnector(false);
        mConnectorsVector.append(mpConnector);
        // add the connection annotation to OMC
        mpConnector->updateConnectionAnnotationString();
        mpParentProjectTab->mpModelicaEditor->setPlainText(pMainWindow->mpOMCProxy->list(mpParentProjectTab->mModelNameStructure));
      }
      else
      {
        removeConnector();
        // since this is an on purpose connection delete so dont make model unsaved :)
        // so to avoid model unsaving we have to blovk signals of Modelica editor
        mpParentProjectTab->mpModelicaEditor->blockSignals(true);
        // remove the connection from model
        pMainWindow->mpOMCProxy->deleteConnection(startIconCompName, endIconCompName, mpParentProjectTab->mModelNameStructure);
        mpParentProjectTab->mpModelicaEditor->blockSignals(false);
      }
    }
  }
}
//add connector function in case atleast one port is an array
//! @param pStartComponent is
void GraphicsView::addConnectorForArray(Component *pStartComponent,Component *pEndComponent ,int startindex , int endindex)
{
  //if user pressed cancel in the array menu, remove the connection
  if(startindex==-1 && endindex==-1)
  {
    removeConnector();
  }

  else
  {
    QString startIndexStr = QString::number(startindex);
    QString endIndexStr = QString::number(endindex);
    mpConnector->mpConnectorArrayMenu->setStartConnectorIndex(startIndexStr);
    mpConnector->mpConnectorArrayMenu->setEndConnectorIndex(endIndexStr);
    QString startIconName, startIconCompName, endIconName, endIconCompName;
    // appending the indices if it is an array of connectors;
    if (pStartComponent->mpParentComponent)
    {
      startIconName = QString(pStartComponent->mpParentComponent->getName()).append(".");
      if(!mpConnector->getStartConnectorisArray())
        startIconCompName = pStartComponent->mpComponentProperties->getName();
      else
        startIconCompName = pStartComponent->mpComponentProperties->getName() + "[" + mpConnector->mpConnectorArrayMenu->getStartConnectorIndex() + "]";
    }
    else
    {
      if(!mpConnector->getStartConnectorisArray())
        startIconCompName = pStartComponent->getName();
      else
        startIconCompName = pStartComponent->getName() + "[" + startIndexStr + "]";
    }

    if (pEndComponent->mpParentComponent)
    {
      endIconName = QString(pEndComponent->mpParentComponent->getName()).append(".");
      if(!mpConnector->getEndConnectorisArray())
        endIconCompName = pEndComponent->mpComponentProperties->getName();
      else
        endIconCompName = pEndComponent->mpComponentProperties->getName() + "[" + mpConnector->mpConnectorArrayMenu->getEndConnectorIndex() + "]";
    }
    else
    {

      if(!mpConnector->getEndConnectorisArray())
        endIconCompName = pEndComponent->getName();
      else
        endIconCompName = pEndComponent->getName() + "[" + endIndexStr + "]";
    }

    createConnection(pStartComponent, QString(startIconName).append(startIconCompName),
                     pEndComponent, QString(endIconName).append(endIconCompName));

  }
}

//! Removes the current connecting connector from the model.
void GraphicsView::removeConnector()
{
  if (mIsCreatingConnector)
  {
    scene()->removeItem(mpConnector);
    delete mpConnector;
    mIsCreatingConnector = false;
  }
  else
  {
    int i = 0;
    while(i != mConnectorsVector.size())
    {
      if(mConnectorsVector[i]->isActive())
      {
        removeConnector(mConnectorsVector[i]);
        i = 0;   //Restart iteration if map has changed
      }
      else
      {
        ++i;
      }
    }
  }
}

//! Removes the connector from the model.
//! @param pConnector is a pointer to the connector to remove.
void GraphicsView::removeConnector(Connector *pConnector, bool update)
{
  bool doDelete = false;
  int i;

  for(i = 0; i != mConnectorsVector.size(); ++i)
  {
    if(mConnectorsVector[i] == pConnector)
    {
      scene()->removeItem(pConnector);
      doDelete = true;
      break;
    }
    if(mConnectorsVector.empty())
      break;
  }
  if (doDelete)
  {
    // If GUI delete is successful then remove the connection from omc as well.
    QString startIconName, startIconCompName, endIconName, endIconCompName;
    if (pConnector->getStartComponent()->mpParentComponent)
    {
      startIconName = QString(pConnector->getStartComponent()->mpParentComponent->getName()).append(".");
      if(!pConnector->getStartConnectorisArray())
        startIconCompName =pConnector->getStartComponent()->mpComponentProperties->getName();
      else
        startIconCompName = pConnector->getStartComponent()->mpComponentProperties->getName() + "[" + pConnector->mpConnectorArrayMenu->getStartConnectorIndex() + "]";
    }
    else
    {
      startIconCompName = pConnector->getStartComponent()->getName();
      if(!pConnector->getStartConnectorisArray())
        startIconCompName =pConnector->getStartComponent()->getName();
      else
        startIconCompName = pConnector->getStartComponent()->getName() + "[" + pConnector->mpConnectorArrayMenu->getStartConnectorIndex() + "]";
    }
    if (pConnector->getEndComponent()->mpParentComponent)
    {
      endIconName = QString(pConnector->getEndComponent()->mpParentComponent->getName()).append(".");
      if(!pConnector->getEndConnectorisArray())
        endIconCompName = pConnector->getEndComponent()->mpComponentProperties->getName();
      else
        endIconCompName = pConnector->getEndComponent()->mpComponentProperties->getName() + "[" + pConnector->mpConnectorArrayMenu->getEndConnectorIndex() + "]";
    }
    else
    {
      if(!pConnector->getEndConnectorisArray())
        endIconCompName = pConnector->getEndComponent()->getName();
      else
        endIconCompName = pConnector->getEndComponent()->getName() + "[" + pConnector->mpConnectorArrayMenu->getEndConnectorIndex() + "]";
    }
    // delete Connection
    deleteConnection(QString(startIconName).append(startIconCompName), QString(endIconName).append(endIconCompName), update);
    // delete the connector object
    delete pConnector;
    // remove connector object from local connector vector
    mConnectorsVector.remove(i);
  }
}

//! Deletes the connection from OMC.
//! @param startIconCompName is starting component name string.
//! @param endIconCompName is ending component name string.
//! @param update flag is used to check whether we need to update the modelica editor text or not.
//! @see removeConnector()
//! @see removeConnector(Connector *pConnector, bool update)
void GraphicsView::deleteConnection(QString startIconCompName, QString endIconCompName, bool update)
{
  MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;

  if (pMainWindow->mpOMCProxy->deleteConnection(startIconCompName, endIconCompName, mpParentProjectTab->mModelNameStructure))
  {
    if (update)
      mpParentProjectTab->mpModelicaEditor->setPlainText(pMainWindow->mpOMCProxy->list(mpParentProjectTab->mModelNameStructure));
  }
}

//! Gets the bounding rectangle of all the items added to the view, excluding background and so on
QRectF GraphicsView::iconBoundingRect()
{
  QRectF rect;
  foreach(QGraphicsItem *item, mComponentsList){
    rect |= item->sceneBoundingRect();
  }
  foreach(QGraphicsItem *item, mShapesList){
    rect |= item->sceneBoundingRect();
  }
  return mapFromScene(rect).boundingRect();
}

//! Resets zoom factor to 100%.
//! @see zoomIn()
//! @see zoomOut()
void GraphicsView::resetZoom()
{
  resetMatrix();
  scale(1.0, -1.0);
  mCustomScale = false;
  resizeEvent(new QResizeEvent(QSize(0,0), QSize(0,0)));
}

//! Increases zoom factor by 15%.
//! @see resetZoom()
//! @see zoomOut()
void GraphicsView::zoomIn()
{
  scale(1.12, 1.12);
  mCustomScale = true;
}

//! Decreases zoom factor by 13.04% (1 - 1/1.15).
//! @see resetZoom()
//! @see zoomIn()
void GraphicsView::zoomOut()
{
  scale(1/1.12, 1/1.12);
  mCustomScale = true;
}

void GraphicsView::showGridLines(bool showLines)
{
  mpParentProjectTab->mpParentProjectTabWidget->mShowLines = showLines;
  scene()->update();
}

//! Selects all objects and connectors.
void GraphicsView::selectAll()
{
  //Select all components
  foreach (Component *icon, mComponentsList)
  {
    icon->setSelected(true);
  }

  // Select all connectors
  foreach (Connector *connector, mConnectorsVector)
  {
    // just make one line of connector selected, it will make the whole connector selected
    foreach (ConnectorLine *connectorLine, connector->mpLines)
    {
      connectorLine->setSelected(true);
      break;
    }
  }

  // select all shapes like line, rectangle, polygon etc...
  foreach (ShapeAnnotation *pShape, mShapesList)
  {
    pShape->setSelected(true);
  }
}

//! Adds the annotation string of Icon and Diagram layer to the model. Also creates the model icon in the tree.
//! If some custom models are cross referenced then update them accordingly.
//! @param update flag is used to check whether we need to update the modelica editor text or not.
void GraphicsView::addClassAnnotation(bool update)
{
  if (mpParentProjectTab->mOpenMode || mpParentProjectTab->isReadOnly())
    return;

  MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
  int counter = 0;
  QString annotationString;

  annotationString.append("annotate=");
  if (mIconType == StringHandler::ICON)
  {
    annotationString.append("Icon(");
  }
  else if (mIconType == StringHandler::DIAGRAM)
  {
    annotationString.append("Diagram(");
  }
  // add the coordinate system first
  //    annotationString.append("coordinateSystem=CoordinateSystem(extent={");
  //    annotationString.append("{").append(QString::number(sceneRect().x())).append(", ").append(QString::number(sceneRect().y())).append("}, ");
  //    annotationString.append("{").append(QString::number(sceneRect().width() - fabs(sceneRect().x()))).append(", ")
  //            .append(QString::number(sceneRect().height() - fabs(sceneRect().y()))).append("}})");
  // add the graphics annotations
  if (mShapesList.size() > 0)
  {
    annotationString.append("graphics={");
    foreach (ShapeAnnotation *shape, mShapesList)
    {
      annotationString.append(shape->getShapeAnnotation());
      if (counter < mShapesList.size() - 1)
        annotationString.append(",");
      counter++;
    }
    annotationString.append("}");
  }
  annotationString.append(")");

  // add the class annotation to model through OMC
  if (pMainWindow->mpOMCProxy->addClassAnnotation(mpParentProjectTab->mModelNameStructure, annotationString))
  {
    // update modelicatext of model
    if (update)
      mpParentProjectTab->mpModelicaEditor->setPlainText(pMainWindow->mpOMCProxy->list(mpParentProjectTab->mModelNameStructure));
  }
  else
  {
    pMainWindow->mpMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0,
                                                                tr("Error in class annotation ") + pMainWindow->mpOMCProxy->getResult(),
                                                                Helper::scriptingKind, Helper::errorLevel, 0, pMainWindow->mpMessageWidget->mpProblem));
  }
  // update model icon if something is changed in icon view
  ModelicaTree *pModelicaTree = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpLibrary->mpModelicaTree;
  ModelicaTreeNode *pModelicaTreeNode = pModelicaTree->getNode(mpParentProjectTab->mModelNameStructure);

  if (!pModelicaTreeNode)
    return;

  if (mIconType == StringHandler::ICON)
  {
    LibraryLoader *libraryLoader = new LibraryLoader(pModelicaTreeNode, mpParentProjectTab->mModelNameStructure, pModelicaTree);
    libraryLoader->start(QThread::HighestPriority);
    while (libraryLoader->isRunning())
      qApp->processEvents(QEventLoop::ExcludeUserInputEvents);
  }

  /* since the icon of this model has changed in some way so it might be possible that this model is being used in some other models,
       so we look through the modelica files tree and check the components of all models against our current model.
       If a match is found we get the icon annotation of the model and update it.
       */
  /*  QList<ModelicaTreeNode*> pModelicaTreeNodes = pModelicaTree->getModelicaTreeNodes();
        QList<Component*> componentslist;
        QString result;
        result= pMainWindow->mpOMCProxy->getIconAnnotation(mpParentProjectTab->mModelNameStructure);

        foreach (ModelicaTreeNode *node, pModelicaTreeNodes)
        {
           ProjectTab *projectTab = mpParentProjectTab->mpParentProjectTabWidget->getTabByName(node->mNameStructure);
           if (projectTab)
           {
               componentslist = projectTab->mpDiagramGraphicsView->mComponentsList;
               foreach (Component *component, componentslist)
               {
                   if (component->getClassName().compare(mpParentProjectTab->mModelNameStructure) == 0)
                   {
                       result = pMainWindow->mpOMCProxy->getIconAnnotation(mpParentProjectTab->mModelNameStructure);
                       component->parseAnnotationString(component, result);
                       projectTab->mpDiagramGraphicsView->scene()->update();
                   }
               }
           }
        }
    */

  if (mIconType == StringHandler::ICON && pModelicaTreeNode->mType != StringHandler::CONNECTOR)
  {
    QList<ModelicaTreeNode*> pModelicaTreeNodes = pModelicaTree->getModelicaTreeNodes();
    QList<Component*> componentslist;
    QString result;
    result= pMainWindow->mpOMCProxy->getIconAnnotation(mpParentProjectTab->mModelNameStructure);
    foreach (ModelicaTreeNode *node, pModelicaTreeNodes)
    {
      ProjectTab *projectTab= mpParentProjectTab->mpParentProjectTabWidget->getTabByName(node->mNameStructure);
      if(projectTab)
      {
        componentslist=projectTab->mpDiagramGraphicsView->mComponentsList;
        foreach (Component *component, componentslist)
        {
          if(component->getClassName()==mpParentProjectTab->mModelNameStructure)
          {
            component->parseAnnotationString(component,result);
            projectTab->mpDiagramGraphicsView->scene()->update();
          }
        }
      }
    }
  }
  else if (mIconType == StringHandler::ICON && pModelicaTreeNode->mType == StringHandler::CONNECTOR)
  {
    QList<ModelicaTreeNode*> pModelicaTreeNodes = pModelicaTree->getModelicaTreeNodes();
    QList<Component*> componentslist;
    QString result;
    result= pMainWindow->mpOMCProxy->getIconAnnotation(mpParentProjectTab->mModelNameStructure);
    foreach (ModelicaTreeNode *node, pModelicaTreeNodes)
    {
      ProjectTab *projectTab= mpParentProjectTab->mpParentProjectTabWidget->getTabByName(node->mNameStructure);
      if(projectTab)
      {
        componentslist=projectTab->mpIconGraphicsView->mComponentsList;
        foreach (Component *component, componentslist)
        {
          if(component->getClassName()==mpParentProjectTab->mModelNameStructure)
          {
            component->parseAnnotationString(component,result);
            projectTab->mpIconGraphicsView->scene()->update();
          }
        }
      }
    }
  }
  else if (mIconType == StringHandler::DIAGRAM && pModelicaTreeNode->mType == StringHandler::CONNECTOR )
  {
    QList<ModelicaTreeNode*> pModelicaTreeNodes = pModelicaTree->getModelicaTreeNodes();
    QList<Component*> componentslist;
    QString result= pMainWindow->mpOMCProxy->getDiagramAnnotation(mpParentProjectTab->mModelNameStructure);
    foreach (ModelicaTreeNode *node, pModelicaTreeNodes)
    {
      ProjectTab *projectTab= mpParentProjectTab->mpParentProjectTabWidget->getTabByName(node->mNameStructure);
      if(projectTab)
      {
        componentslist=projectTab->mpDiagramGraphicsView->mComponentsList;
        foreach (Component *component, componentslist)
        {
          if(component->getClassName()==mpParentProjectTab->mModelNameStructure)
          {
            component->parseAnnotationString(component,result);
            projectTab->mpDiagramGraphicsView->scene()->update();
          }
        }
      }
    }
  }
}

//! @class GraphicsScene
//! @brief The GraphicsScene class is a container for graphicsl components in a simulationmodel.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
GraphicsScene::GraphicsScene(int iconType, ProjectTab *parent)
  : QGraphicsScene(parent), mIconType(iconType)
{
  mpParentProjectTab = parent;
}

//! @class ProjectTab
//! @brief The ProjectTab class is a Widget to contain a simulation model

//! ProjectTab contains a drawing space to create models.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
ProjectTab::ProjectTab(QString name, QString nameStructure, int modelicaType, int iconType, bool readOnly, bool isChild, bool openMode,
                       ProjectTabWidget *parent)
  : QWidget(parent)
{
  mIsSaved = false;
  mModelFileName.clear();
  mpParentProjectTabWidget = parent;
  mModelName = name;
  mModelNameStructure = nameStructure;
  mModelicaType = modelicaType;
  mIconType = iconType;
  mOpenMode = openMode;
  setReadOnly(readOnly);
  setIsChild(isChild);
  // create a modelica text editor for modelica text
  mpModelicaEditor = new ModelicaEditor(this);
  MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
  mpModelicaTextHighlighter = new ModelicaTextHighlighter(pMainWindow->mpOptionsWidget->mpModelicaTextSettings, mpModelicaEditor->document());
  connect(pMainWindow->mpOptionsWidget, SIGNAL(modelicaTextSettingsChanged()), mpModelicaTextHighlighter, SLOT(settingsChanged()));
  // icon graphics framework
  mpDiagramGraphicsScene = new GraphicsScene(StringHandler::DIAGRAM, this);
  mpDiagramGraphicsView = new GraphicsView(StringHandler::DIAGRAM, this);
  mpDiagramGraphicsView->setScene(mpDiagramGraphicsScene);
  // diagram graphics framework
  mpIconGraphicsScene = new GraphicsScene(StringHandler::ICON, this);
  mpIconGraphicsView = new GraphicsView(StringHandler::ICON, this);
  mpIconGraphicsView->setScene(mpIconGraphicsScene);
  // set Project Status Bar lables
  mpReadOnlyLabel = isReadOnly() ? new QLabel(Helper::readOnly) : new QLabel(Helper::writable);
  mpReadOnlyLabel->setTextInteractionFlags(Qt::TextSelectableByMouse);
  mpModelicaTypeLabel = new QLabel(StringHandler::getModelicaClassType(mModelicaType));
  mpModelicaTypeLabel->setTextInteractionFlags(Qt::TextSelectableByMouse);
  mpViewTypeLabel = new QLabel(StringHandler::getViewType(mIconType));
  mpViewTypeLabel->setTextInteractionFlags(Qt::TextSelectableByMouse);
  mpModelFilePathLabel = new QLabel;
  mpModelFilePathLabel->setWordWrap(true);
  mpModelFilePathLabel->setTextInteractionFlags(Qt::TextSelectableByMouse);
  // frame to contain view buttons
  QFrame *viewsButtonsFrame = new QFrame;
  QHBoxLayout *viewsButtonsHorizontalLayout = new QHBoxLayout;
  viewsButtonsHorizontalLayout->setContentsMargins(0, 0, 0, 0);
  // icon view tool button
  mpDiagramToolButton = new QToolButton;
  mpDiagramToolButton->setText(Helper::iconView);
  mpDiagramToolButton->setIcon(QIcon(":/Resources/icons/model.png"));
  mpDiagramToolButton->setIconSize(Helper::buttonIconSize);
  mpDiagramToolButton->setToolTip(Helper::iconView);
  mpDiagramToolButton->setAutoRaise(true);
  mpDiagramToolButton->setCheckable(true);
  connect(mpDiagramToolButton, SIGNAL(clicked(bool)), SLOT(showIconView(bool)));
  viewsButtonsHorizontalLayout->addWidget(mpDiagramToolButton);
  // diagram view tool button
  mpIconToolButton = new QToolButton;
  mpIconToolButton->setText(Helper::diagramView);
  mpIconToolButton->setIcon(QIcon(":/Resources/icons/omeditor.png"));
  mpIconToolButton->setIconSize(Helper::buttonIconSize);
  mpIconToolButton->setToolTip(Helper::diagramView);
  mpIconToolButton->setAutoRaise(true);
  mpIconToolButton->setCheckable(true);
  connect(mpIconToolButton, SIGNAL(clicked(bool)), SLOT(showDiagramView(bool)));
  viewsButtonsHorizontalLayout->addWidget(mpIconToolButton);
  // modelica text view tool button
  mpModelicaTextToolButton = new QToolButton;
  mpModelicaTextToolButton->setText(Helper::modelicaTextView);
  mpModelicaTextToolButton->setIcon(QIcon(":/Resources/icons/modeltext.png"));
  mpModelicaTextToolButton->setIconSize(Helper::buttonIconSize);
  mpModelicaTextToolButton->setToolTip(Helper::modelicaTextView);
  mpModelicaTextToolButton->setAutoRaise(true);
  mpModelicaTextToolButton->setCheckable(true);
  connect(mpModelicaTextToolButton, SIGNAL(clicked(bool)), SLOT(showModelicaTextView(bool)));
  viewsButtonsHorizontalLayout->addWidget(mpModelicaTextToolButton);
  // documentation view tool button
  mpDocumentationViewToolButton = new QToolButton;
  mpDocumentationViewToolButton->setText(Helper::documentationView);
  mpDocumentationViewToolButton->setIcon(QIcon(":/Resources/icons/info-icon.png"));
  mpDocumentationViewToolButton->setIconSize(Helper::buttonIconSize);
  mpDocumentationViewToolButton->setToolTip(Helper::documentationView);
  mpDocumentationViewToolButton->setAutoRaise(true);
  connect(mpDocumentationViewToolButton, SIGNAL(clicked()), SLOT(showDocumentationView()));
  viewsButtonsHorizontalLayout->addWidget(mpDocumentationViewToolButton);
  viewsButtonsFrame->setLayout(viewsButtonsHorizontalLayout);
  // view buttons box
  mpViewsButtonGroup = new QButtonGroup;
  mpViewsButtonGroup->setExclusive(true);
  mpViewsButtonGroup->addButton(mpIconToolButton);
  mpViewsButtonGroup->addButton(mpDiagramToolButton);
  mpViewsButtonGroup->addButton(mpModelicaTextToolButton);
  // create project status bar
  mpProjectStatusBar = new QStatusBar;
  mpProjectStatusBar->setObjectName("ProjectStatusBar");
  mpProjectStatusBar->setSizeGripEnabled(false);
  mpProjectStatusBar->addPermanentWidget(viewsButtonsFrame, 5);
  mpProjectStatusBar->addPermanentWidget(mpReadOnlyLabel, 6);
  mpProjectStatusBar->addPermanentWidget(mpModelicaTypeLabel, 6);
  mpProjectStatusBar->addPermanentWidget(mpViewTypeLabel, 10);
  mpProjectStatusBar->addPermanentWidget(mpModelFilePathLabel, 73);
  // create the layout for Modelica Editor
  QHBoxLayout *modelicaEditorHorizontalLayout = new QHBoxLayout;
  modelicaEditorHorizontalLayout->setContentsMargins(0, 0, 0, 0);
  modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpSearchLabelImage);
  modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpSearchLabel);
  modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpSearchTextBox);
  modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpPreviuosButton);
  modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpNextButton);
  modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpMatchCaseCheckBox);
  modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpMatchWholeWordCheckBox);
  modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpCloseButton);
  mpModelicaEditor->mpFindWidget->setLayout(modelicaEditorHorizontalLayout);
  QVBoxLayout *modelicaEditorVerticalLayout = new QVBoxLayout;
  modelicaEditorVerticalLayout->setContentsMargins(0, 0, 0, 0);
  modelicaEditorVerticalLayout->addWidget(mpModelicaEditor);
  modelicaEditorVerticalLayout->addWidget(mpModelicaEditor->mpFindWidget);
  mpModelicaEditorWidget = new QWidget;
  mpModelicaEditorWidget->setLayout(modelicaEditorVerticalLayout);
  // set layout
  QVBoxLayout *tabLayout = new QVBoxLayout;
  tabLayout->setContentsMargins(2, 2, 2, 2);
  tabLayout->addWidget(mpProjectStatusBar);
  tabLayout->addWidget(mpDiagramGraphicsView);
  tabLayout->addWidget(mpIconGraphicsView);
  tabLayout->addWidget(mpModelicaEditorWidget);
  setLayout(tabLayout);
  // Hide the modelica text view, icon view and show diagram view
  mpModelicaEditorWidget->hide();
  mpIconGraphicsView->hide();
  mpIconToolButton->setChecked(true);
}

ProjectTab::~ProjectTab()
{
  delete mpProjectStatusBar;
}

void ProjectTab::updateTabName(QString name, QString nameStructure)
{
  mModelName = name;
  mModelNameStructure = nameStructure;

  if (mIsSaved)
    mpParentProjectTabWidget->setTabText(mTabPosition, mModelName);
  else
    mpParentProjectTabWidget->setTabText(mTabPosition, QString(mModelName).append("*"));
}

void ProjectTab::updateModel(QString name)
{
  MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
  QString newNameStructure;
  QString oldModelName = mModelName;
  // rename the model, if user has changed the name
  if (pMainWindow->mpOMCProxy->renameClass(mModelNameStructure, name))
  {
    newNameStructure = StringHandler::removeFirstLastCurlBrackets(pMainWindow->mpOMCProxy->getResult());
    // Change the name in tree
    ModelicaTreeNode *node = pMainWindow->mpLibrary->mpModelicaTree->getNode(mModelNameStructure);
    pMainWindow->mpLibrary->updateNodeText(name, newNameStructure, node);
  }
}

void ProjectTab::showIconView(bool checked)
{
  // validate the modelica text before switching to diagram view
  if (!mpModelicaEditor->validateText())
  {
    mpModelicaTextToolButton->setChecked(true);
    return;
  }

  mpIconGraphicsView->setFocus();
  if (!checked or (checked and mpIconGraphicsView->isVisible()))
    return;

  mpModelicaEditorWidget->hide();
  mpDiagramGraphicsView->hide();
  mpIconGraphicsView->show();
  mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::ICON));
}

void ProjectTab::showDiagramView(bool checked)
{
  // validate the modelica text before switching to icon view
  if (!mpModelicaEditor->validateText())
  {
    mpModelicaTextToolButton->setChecked(true);
    return;
  }

  mpDiagramGraphicsView->setFocus();
  if (!checked or (checked and mpDiagramGraphicsView->isVisible()))
    return;

  mpModelicaEditorWidget->hide();
  mpIconGraphicsView->hide();
  mpDiagramGraphicsView->show();
  mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::DIAGRAM));
}

void ProjectTab::showModelicaTextView(bool checked)
{
  if (!checked or (checked and mpModelicaEditorWidget->isVisible()))
    return;

  mpDiagramGraphicsView->hide();
  mpIconGraphicsView->hide();
  mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::MODELICATEXT));
  // get the modelica text of the model
  mpModelicaEditor->blockSignals(true);
  mpModelicaEditor->setPlainText(mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy->list(mModelNameStructure));
  mpModelicaEditor->blockSignals(false);
  mpModelicaEditor->mLastValidText = mpModelicaEditor->toPlainText();
  mpModelicaEditor->setFocus();
  mpModelicaEditorWidget->show();
}

void ProjectTab::showDocumentationView()
{
  mpParentProjectTabWidget->mpParentMainWindow->mpDocumentationDockWidget->show();
  mpParentProjectTabWidget->mpParentMainWindow->mpDocumentationWidget->show(mModelNameStructure,true);
}

bool ProjectTab::loadModelFromText(QString modelName)
{
  MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
  QString modelNameStructure;
  // if a model is a sub model then
  if (mModelNameStructure.contains("."))
  {
    modelNameStructure = StringHandler::removeLastWordAfterDot(mModelNameStructure)
        .append(".").append(modelName);
    // if model with this name already exists
    if (mModelNameStructure.compare(modelNameStructure) != 0)
    {
      if (!pMainWindow->mpOMCProxy->existClass(modelNameStructure))
      {
        return loadSubModel(modelName);
      }
      else
      {
        pMainWindow->mpOMCProxy->setResult(GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS));
        return false;
      }
    }
  }
  // if a model is a root model then
  else
  {
    modelNameStructure = modelName;
    if (mModelNameStructure.compare(modelNameStructure) != 0)
    {
      if (!pMainWindow->mpOMCProxy->existClass(modelNameStructure))
      {
        return loadRootModel(mpModelicaEditor->toPlainText());
      }
      else
      {
        pMainWindow->mpOMCProxy->setResult(GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS));
        return false;
      }
    }
  }
}

bool ProjectTab::loadRootModel(QString model)
{
  MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
  // if model text is fine then
  //    if (pMainWindow->mpOMCProxy->saveModifiedModel(model))
  //    {
  updateModel(model);
  return true;
  //    }
  //    // if there is some error in model then dont accept it
  //    else
  //        return false;
}

bool ProjectTab::loadSubModel(QString model)
{
  MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
  // if model text is fine then
  if (pMainWindow->mpOMCProxy->updateSubClass(StringHandler::removeLastWordAfterDot(mModelNameStructure), model))
  {
    QString modelName = StringHandler::getFirstWordBeforeDot(StringHandler::removeFirstLastCurlBrackets(pMainWindow->mpOMCProxy->getResult()));
    updateModel(modelName);
    //! @todo since we have created an extra model with the same name so delete it. Fix this ugly thing.
    pMainWindow->mpOMCProxy->deleteClass(mModelNameStructure);
    return true;
  }
  // if there is some error in model then dont accept it
  else
    return false;
}

//! Gets the components of the model and place them in the GraphicsView.
void ProjectTab::getModelComponents(QString modelName)
{
  MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
  // get the inherited components of the Model
  int inheritanceCount = pMainWindow->mpOMCProxy->getInheritanceCount(modelName);

  for(int i = 1 ; i <= inheritanceCount ; i++)
  {
    QString inheritedClass = pMainWindow->mpOMCProxy->getNthInheritedClass(modelName, i);
    // If the inherited class is one of the builtin type such as Real we can
    // stop here, because the class can not contain any components, etc.
    if (pMainWindow->mpOMCProxy->isBuiltinType(inheritedClass) || inheritedClass.compare(modelName) == 0)
    {
      return;
    }
    getModelComponents(inheritedClass);
  }

  QList<ComponentsProperties*> components = pMainWindow->mpOMCProxy->getComponents(modelName);
  QStringList componentsAnnotationsList = pMainWindow->mpOMCProxy->getComponentAnnotations(modelName);

  int i = 0;
  foreach (ComponentsProperties *componentProperties, components)
  {
    if (pMainWindow->mpOMCProxy->isWhat(StringHandler::CONNECTOR, componentProperties->getClassName()))
    {
      mpDiagramGraphicsView->addComponentoView(componentProperties->getName(), componentProperties->getClassName(), QPointF(0.0, 0.0),
                                               true, false, true);
      mpIconGraphicsView->addComponentoView(componentProperties->getName(), componentProperties->getClassName(), QPointF(0.0, 0.0),
                                            true, false);

      if (!static_cast<QString>(componentsAnnotationsList.at(i)).toLower().contains("error"))
      {
        // get the diagram component object we just created
        Component *pDiagramComponent = mpDiagramGraphicsView->getComponentObject(componentProperties->getName());
        // get the icon component object we just created
        Component *pIconComponent = mpIconGraphicsView->getComponentObject(componentProperties->getName());
        // if component annotation is found then place it according to annotation
        if (StringHandler::removeFirstLastCurlBrackets(componentsAnnotationsList.at(i)).length() > 0)
        {
          Transformation *transformation;
          if (pDiagramComponent)
          {
            pDiagramComponent->mTransformationString = componentsAnnotationsList.at(i);
            transformation = new Transformation(pDiagramComponent);
            // unset the ItemSendsGeometryChanges flag otherwise we will get alot of itemchange events which are not needed here.
            pDiagramComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, false);
            // We need to reset the matrix before applying tranformations.
            pDiagramComponent->resetTransform();
            pDiagramComponent->scale(transformation->getScale(), transformation->getScale());
            pDiagramComponent->setPos(transformation->getPositionX(), transformation->getPositionY());
            pDiagramComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, true);
            pDiagramComponent->setRotation(transformation->getRotateAngle());
          }
          if (pIconComponent)
          {
            pIconComponent->mTransformationString = componentsAnnotationsList.at(i);
            // unset the ItemSendsGeometryChanges flag otherwise we will get alot of itemchange events which are not needed here.
            pIconComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, false);
            // We need to reset the matrix before applying tranformations.
            pIconComponent->resetTransform();
            pIconComponent->scale(transformation->getScaleIcon(), transformation->getScaleIcon());
            pIconComponent->setPos(transformation->getPositionXIcon(), transformation->getPositionYIcon());
            pIconComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, true);
            pIconComponent->setRotation(transformation->getRotateAngleIcon());
          }
        }
      }
    }
    else
    {
      mpDiagramGraphicsView->addComponentoView(componentProperties->getName(), componentProperties->getClassName(), QPointF(0.0, 0.0),
                                               false, false, false);
      if (!static_cast<QString>(componentsAnnotationsList.at(i)).toLower().contains("error"))
      {
        // get the diagram component object we just created
        Component *pDiagramComponent = mpDiagramGraphicsView->getComponentObject(componentProperties->getName());
        if (pDiagramComponent)
        {
          // if component annotation is found then place it according to annotation
          if (StringHandler::removeFirstLastCurlBrackets(componentsAnnotationsList.at(i)).length() > 0)
          {
            pDiagramComponent->mTransformationString = componentsAnnotationsList.at(i);
            Transformation *transformation = new Transformation(pDiagramComponent);
            // unset the ItemSendsGeometryChanges flag otherwise we will get alot of itemchange events which are not needed here.
            pDiagramComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, false);
            //! @todo We need to reset the matrix before applying tranformations.
            pDiagramComponent->resetTransform();
            pDiagramComponent->scale(transformation->getScale(), transformation->getScale());
            pDiagramComponent->setPos(transformation->getPositionX(), transformation->getPositionY());
            pDiagramComponent->setFlag(QGraphicsItem::ItemSendsGeometryChanges, true);
            pDiagramComponent->setRotation(transformation->getRotateAngle());
          }
        }
      }
    }
    i++;
  }
}

//! Gets the connections of the model and place them in the GraphicsView.
void ProjectTab::getModelConnections()
{
  MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
  int connectionsCount = pMainWindow->mpOMCProxy->getConnectionCount(mModelNameStructure);
  int startindex=-1,endindex=-1;
  for (int i = 1 ; i <= connectionsCount ; i++)
  {
    // get the connection from OMC
    QString connectionString;
    QStringList connectionList;
    connectionString = pMainWindow->mpOMCProxy->getNthConnection(mModelNameStructure, i);
    connectionList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(connectionString));
    // if the connectionString only contains two items then continue the loop,
    // because connection is not valid then
    if (connectionList.size() < 3)
      continue;

    // get start and end components
    QStringList startComponentList = static_cast<QString>(connectionList.at(0)).split(".");
    QStringList endComponentList = static_cast<QString>(connectionList.at(1)).split(".");

    Component *pStartComponent = mpDiagramGraphicsView->getComponentObject(startComponentList.at(0));
    Component *pEndComponent = mpDiagramGraphicsView->getComponentObject(endComponentList.at(0));

    // if Start component and end component not found then continue the loop
    if (!pStartComponent or !pEndComponent)
      continue;

    // get start and end ports
    Component *pStartPort = 0;
    Component *pEndPort = 0;
    // if a connector type is connected then we only get one item in startComponentList and endComponentList
    // check the startcomponentlist
    if (startComponentList.size() < 2)
    {
      pStartPort = pStartComponent;
    }
    // look for port from the parent component
    else
    {
      foreach (Component *component, pStartComponent->mpComponentsList)
      {
        int startbrac = startComponentList.at(1).indexOf("[");
        if(startbrac == -1)
        {
          if (component->mpComponentProperties->getName() == startComponentList.at(1))
            pStartPort = component;
        }
        //if the start port is a connector array
        else
        {   bool ok;
          int endbrac = startComponentList.at(1).indexOf("]");
          QString arrayPort = startComponentList.at(1).left(startbrac);
          startindex = startComponentList.at(1).mid(startbrac+1,endbrac-startbrac-1).toInt(&ok,10);

          if (component->mpComponentProperties->getName() == arrayPort)
            pStartPort = component;
        }
      }
    }
    // if a connector type is connected then we only get one item in startComponentList and endComponentList
    // check the startcomponentlist
    if (endComponentList.size() < 2)
    {
      pEndPort = pEndComponent;
    }
    // look for port from the parent component
    else
    {
      foreach (Component *component, pEndComponent->mpComponentsList)
      {
        int startbrac = endComponentList.at(1).indexOf("[");
        if(startbrac == -1)
        {
          if (component->mpComponentProperties->getName() == endComponentList.at(1))
            pEndPort = component;
        }
        //if the end port is a connector array
        else
        {   bool ok;
          int endbrac = endComponentList.at(1).indexOf("]");
          QString arrayPort = endComponentList.at(1).left(startbrac);
          endindex = endComponentList.at(1).mid(startbrac+1,endbrac-startbrac-1).toInt(&ok,10);
          if (component->mpComponentProperties->getName() == arrayPort)
            pEndPort = component;
        }
      }
    }

    // if Start port and end port not found then continue the loop
    if (!pStartPort or !pEndPort)
      continue;

    // get the connector annotations from OMC
    QString connectionAnnotationString;
    QStringList connectionAnnotationList, shapesList;
    connectionAnnotationString = pMainWindow->mpOMCProxy->getNthConnectionAnnotation(mModelNameStructure, i);
    shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(connectionAnnotationString), '(', ')');
    // Now parse the shapes available in list
    foreach (QString shape, shapesList)
    {
      shape = StringHandler::removeFirstLastCurlBrackets(shape);
      if (shape.startsWith("Line"))
      {
        shape = shape.mid(QString("Line").length());
        connectionAnnotationString = StringHandler::removeFirstLastBrackets(shape);
      }
    }
    connectionAnnotationList = StringHandler::getStrings(connectionAnnotationString);
    // if the connectionAnnotationString is empty then continue the loop,
    // because connection is not valid then
    if (connectionAnnotationList.size() < 8)
      continue;

    // create a QVector<QPointF> of annotation string to pass to connector
    QStringList pointsList;
    QVector<QPointF> points;
    pointsList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(connectionAnnotationList.at(3)));

    foreach (QString point, pointsList)
    {
      QStringList linePoints = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(point));
      if (linePoints.size() < 2)
        continue;

      qreal x = static_cast<QString>(linePoints.at(0)).toFloat();
      qreal y = static_cast<QString>(linePoints.at(1)).toFloat();
      QPointF p (x, y);
      points.append(p);
    }
    // create a connector now
    Connector *pConnector = new Connector(pStartPort, pEndPort, mpDiagramGraphicsView, points);
    //checking for the created connector to be a connector array
    if(startindex>=0)
      pConnector->setStartConnectorisArray(true);
    if(endindex>=0)
      pConnector->setEndConnectorisArray(true);
    //storing array indices for the connector array
    pConnector->mpConnectorArrayMenu->setStartConnectorIndex(QString::number(startindex));
    pConnector->mpConnectorArrayMenu->setEndConnectorIndex(QString::number(endindex));
    mpDiagramGraphicsView->mConnectorsVector.append(pConnector);
    mpDiagramGraphicsView->scene()->addItem(pConnector);
  }
}

//! Gets the shapes contained in the annotation string.
void ProjectTab::getModelShapes(QString annotationString, int type)
{
  MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
  qreal x1, y1, x2, y2, width, height;
  bool valuesSwaped = false;
  annotationString = StringHandler::removeFirstLastCurlBrackets(annotationString);
  if (annotationString.isEmpty())
  {
    return;
  }
  QStringList list = StringHandler::getStrings(annotationString);
  QStringList shapesList;

  if (pMainWindow->mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
  {
    //        if (list.size() < 8)
    //            return;
    //        // read the coordinate system values
    //        x1 = static_cast<QString>(list.at(0)).toFloat();
    //        y1 = static_cast<QString>(list.at(1)).toFloat();
    //        x2 = static_cast<QString>(list.at(2)).toFloat();
    //        y2 = static_cast<QString>(list.at(3)).toFloat();
    //        // according to modelica annotation standard, the first point of coordinate system should always be less than the second one.
    //        if (x1 > x2)
    //        {
    //            qSwap(x1, x2);
    //            valuesSwaped = true;
    //        }
    //        if (y1 > y2)
    //        {
    //            qSwap(y1, y2);
    //            valuesSwaped = true;
    //        }
    //        width = x2 - x1;
    //        height = y2 - y1;

    //        if (type == StringHandler::ICON)
    //        {
    //            mpIconGraphicsView->setSceneRect(x1, y1, width, height);
    //            if (valuesSwaped)
    //                mpIconGraphicsView->addClassAnnotation();
    //        }
    //        else if (type == StringHandler::DIAGRAM)
    //        {
    //            mpDiagramGraphicsView->setSceneRect(x1, y1, width, height);
    //            if (valuesSwaped)
    //                mpIconGraphicsView->addClassAnnotation();
    //        }

    if (list.size() < 9)
      return;
    // read the shapes
    shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(8)), '(', ')');
  }
  else if (pMainWindow->mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION2X)
  {
    if (list.size() < 4)
      return;

    // read the coordinate system values
    //        x1 = static_cast<QString>(list.at(0)).toFloat();
    //        y1 = static_cast<QString>(list.at(1)).toFloat();
    //        x2 = static_cast<QString>(list.at(2)).toFloat();
    //        y2 = static_cast<QString>(list.at(3)).toFloat();
    //        // according to modelica annotation standard, the first point of coordinate system should always be less than the second one.
    //        if (x1 > x2)
    //        {
    //            qSwap(x1, x2);
    //            valuesSwaped = true;
    //        }
    //        if (y1 > y2)
    //        {
    //            qSwap(y1, y2);
    //            valuesSwaped = true;
    //        }
    //        width = x2 - x1;
    //        height = y2 - y1;

    //        if (type == StringHandler::ICON)
    //        {
    //            mpIconGraphicsView->setSceneRect(x1, y1, width, height);
    //            if (valuesSwaped)
    //                mpIconGraphicsView->addClassAnnotation();
    //        }
    //        else if (type == StringHandler::DIAGRAM)
    //        {
    //            mpDiagramGraphicsView->setSceneRect(x1, y1, width, height);
    //            if (valuesSwaped)
    //                mpIconGraphicsView->addClassAnnotation();
    //        }

    if (list.size() < 5)
      return;
    // read the shapes
    shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(4)), '(', ')');
  }

  // Now parse the shapes available in list
  foreach (QString shape, shapesList)
  {
    shape = StringHandler::removeFirstLastCurlBrackets(shape);
    if (shape.startsWith("Line"))
    {
      shape = shape.mid(QString("Line").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      LineAnnotation *lineAnnotation;
      // add the shapeannotation item to shapes list
      if (type == StringHandler::ICON)
      {
        lineAnnotation = new LineAnnotation(shape, mpIconGraphicsView);
        lineAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpIconGraphicsView->addShapeObject(lineAnnotation);
        mpIconGraphicsView->scene()->addItem(lineAnnotation);
      }
      else if (type == StringHandler::DIAGRAM)
      {
        lineAnnotation = new LineAnnotation(shape, mpDiagramGraphicsView);
        lineAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpDiagramGraphicsView->addShapeObject(lineAnnotation);
        mpDiagramGraphicsView->scene()->addItem(lineAnnotation);
      }
      /*
                before drawing the rectangle corner items add one point to line since drawrectanglecorneritems
                deletes the one point. Why? because we end the line shape with double click which adds an extra
                point to it. so we need to delete this point.
            */
      lineAnnotation->addPoint(QPoint(0, 0));
      lineAnnotation->drawRectangleCornerItems();
      lineAnnotation->setSelectionBoxPassive();
    }
    if (shape.startsWith("Polygon"))
    {
      shape = shape.mid(QString("Polygon").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      PolygonAnnotation *polygonAnnotation;
      // add the shapeannotation item to shapes list
      if (type == StringHandler::ICON)
      {
        polygonAnnotation = new PolygonAnnotation(shape, mpIconGraphicsView);
        polygonAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpIconGraphicsView->addShapeObject(polygonAnnotation);
        mpIconGraphicsView->scene()->addItem(polygonAnnotation);
      }
      else if (type == StringHandler::DIAGRAM)
      {
        polygonAnnotation = new PolygonAnnotation(shape, mpDiagramGraphicsView);
        polygonAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpDiagramGraphicsView->addShapeObject(polygonAnnotation);
        mpDiagramGraphicsView->scene()->addItem(polygonAnnotation);
      }
      /*
                before drawing the rectangle corner items add one point to polygon since drawrectanglecorneritems
                deletes the one point. Why? because we end the polygon shape with double click which adds an extra
                point to it. so we need to delete this point.
            */
      polygonAnnotation->addPoint(QPoint(0, 0));
      polygonAnnotation->drawRectangleCornerItems();
      polygonAnnotation->setSelectionBoxPassive();
    }
    if (shape.startsWith("Rectangle"))
    {
      shape = shape.mid(QString("Rectangle").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      RectangleAnnotation *rectangleAnnotation;
      // add the shapeannotation item to shapes list
      if (type == StringHandler::ICON)
      {
        rectangleAnnotation = new RectangleAnnotation(shape, mpIconGraphicsView);
        rectangleAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpIconGraphicsView->addShapeObject(rectangleAnnotation);
        mpIconGraphicsView->scene()->addItem(rectangleAnnotation);
      }
      else if (type == StringHandler::DIAGRAM)
      {
        rectangleAnnotation = new RectangleAnnotation(shape, mpDiagramGraphicsView);
        rectangleAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpDiagramGraphicsView->addShapeObject(rectangleAnnotation);
        mpDiagramGraphicsView->scene()->addItem(rectangleAnnotation);
      }
      rectangleAnnotation->drawRectangleCornerItems();
      rectangleAnnotation->setSelectionBoxPassive();
    }
    if (shape.startsWith("Ellipse"))
    {
      shape = shape.mid(QString("Ellipse").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      EllipseAnnotation *ellipseAnnotation;
      // add the shapeannotation item to shapes list
      if (type == StringHandler::ICON)
      {
        ellipseAnnotation = new EllipseAnnotation(shape, mpIconGraphicsView);
        ellipseAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpIconGraphicsView->addShapeObject(ellipseAnnotation);
        mpIconGraphicsView->scene()->addItem(ellipseAnnotation);
      }
      else if (type == StringHandler::DIAGRAM)
      {
        ellipseAnnotation = new EllipseAnnotation(shape, mpDiagramGraphicsView);
        ellipseAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpDiagramGraphicsView->addShapeObject(ellipseAnnotation);
        mpDiagramGraphicsView->scene()->addItem(ellipseAnnotation);
      }
      ellipseAnnotation->drawRectangleCornerItems();
      ellipseAnnotation->setSelectionBoxPassive();
    }
    if (shape.startsWith("Text"))
    {
      shape = shape.mid(QString("Text").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      TextAnnotation *textAnnotation;
      // add the shapeannotation item to shapes list
      if (type == StringHandler::ICON)
      {
        textAnnotation = new TextAnnotation(shape, mpIconGraphicsView);
        textAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpIconGraphicsView->addShapeObject(textAnnotation);
        mpIconGraphicsView->scene()->addItem(textAnnotation);
      }
      else if (type == StringHandler::DIAGRAM)
      {
        textAnnotation = new TextAnnotation(shape, mpDiagramGraphicsView);
        textAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpDiagramGraphicsView->addShapeObject(textAnnotation);
        mpDiagramGraphicsView->scene()->addItem(textAnnotation);
      }
      textAnnotation->drawRectangleCornerItems();
      textAnnotation->setSelectionBoxPassive();
    }
    if (shape.startsWith("Bitmap"))
    {
      shape = shape.mid(QString("Bitmap").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      BitmapAnnotation *bitmapAnnotation;
      // add the shapeannotation item to shapes list
      if (type == StringHandler::ICON)
      {
        bitmapAnnotation = new BitmapAnnotation(shape, mpIconGraphicsView);
        bitmapAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpIconGraphicsView->addShapeObject(bitmapAnnotation);
        mpIconGraphicsView->scene()->addItem(bitmapAnnotation);
      }
      else if (type == StringHandler::DIAGRAM)
      {
        bitmapAnnotation = new BitmapAnnotation(shape, mpDiagramGraphicsView);
        bitmapAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpDiagramGraphicsView->addShapeObject(bitmapAnnotation);
        mpDiagramGraphicsView->scene()->addItem(bitmapAnnotation);
      }
      bitmapAnnotation->drawRectangleCornerItems();
      bitmapAnnotation->setSelectionBoxPassive();
    }
  }
}

//! Gets the Icon and Diagram Annotation of the model and place them in the GraphicsView (Icon View).
void ProjectTab::getModelIconDiagram()
{
  MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
  QString iconAnnotationString = pMainWindow->mpOMCProxy->getIconAnnotation(mModelNameStructure);
  getModelShapes(iconAnnotationString, StringHandler::ICON);
  QString diagramAnnotationString = pMainWindow->mpOMCProxy->getDiagramAnnotation(mModelNameStructure);
  getModelShapes(diagramAnnotationString, StringHandler::DIAGRAM);
}

void ProjectTab::setReadOnly(bool readOnly)
{
  mReadOnly = readOnly;
}

bool ProjectTab::isReadOnly()
{
  return mReadOnly;
}

void ProjectTab::setIsChild(bool isChild)
{
  mIsChild = isChild;
}

bool ProjectTab::isChild()
{
  return mIsChild;
}

void ProjectTab::setModelFilePathLabel(QString filePath)
{
  mpModelFilePathLabel->setText(filePath);
}

QString ProjectTab::getModelicaTypeLabel()
{
  return mpModelicaTypeLabel->text();
}

QToolButton* ProjectTab::getModelicaTextToolButton()
{
  return mpModelicaTextToolButton;
}

//! Notifies the model that its corresponding text has changed.
//! @see loadRootModel(QString model)
//! @see loadSubModel(QString model)
//! @see updateModel(QString name)
bool ProjectTab::modelicaEditorTextChanged()
{
  mOpenMode = true;
  MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
  QStringList models = mpModelicaEditor->getModelsNames();
  // if there was some error in modelicatext then
  if (models.size() == 0)
  {
    pMainWindow->mpOMCProxy->setResult(mpModelicaEditor->mErrorString);
    return false;
  }
  QString modelNameStructure = mModelNameStructure;
  mModelNameStructure = models.first();
  if (mModelNameStructure.compare(modelNameStructure) != 0) {
    updateTabName(StringHandler::getLastWordAfterDot(mModelNameStructure), mModelNameStructure);
  }
  // remove the tree node
  ModelicaTree *pTree = pMainWindow->mpLibrary->mpModelicaTree;
  ModelicaTreeNode *pTreeNode = pTree->getNode(modelNameStructure);
  QModelIndex nodeModelIndex = pTree->getNodeModelIndex(pTreeNode);
  pTree->deleteNodeTriggered(pTreeNode, false, false);
  pTree->clearSelection();
  QString modelText;
  if (isChild()) {
    modelText = "within " + StringHandler::removeLastWordAfterDot(modelNameStructure) + ";" + mpModelicaEditor->toPlainText();
  } else {
    modelText = mpModelicaEditor->toPlainText();
  }
  // load the model text in OMC
  if (!pMainWindow->mpOMCProxy->loadString(modelText))
  {
    QString message = QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_MODEL).append(" ").arg(modelText))
        .append("\n").append(pMainWindow->mpOMCProxy->getResult());
    pMainWindow->mpMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0, message, Helper::scriptingKind,
                                                                Helper::errorLevel, 0, pMainWindow->mpMessageWidget->mpProblem));
    return false;
  }
  // add tree node again
  if (isChild()) {
    pMainWindow->mpLibrary->addModelFiles(StringHandler::getLastWordAfterDot(mModelNameStructure),
                                          StringHandler::removeLastWordAfterDot(mModelNameStructure), mModelNameStructure,
                                          nodeModelIndex.row());
  } else {
    pMainWindow->mpLibrary->addModelFiles(mModelNameStructure, "", "", nodeModelIndex.row());
  }
  // clear the complete view before loading the models again
  mpIconGraphicsView->removeAllConnectors();
  mpIconGraphicsView->deleteAllComponentObjects();
  mpIconGraphicsView->deleteAllShapesObject();
  mpIconGraphicsView->scene()->clear();
  mpDiagramGraphicsView->removeAllConnectors();
  mpDiagramGraphicsView->deleteAllComponentObjects();
  mpDiagramGraphicsView->deleteAllShapesObject();
  mpDiagramGraphicsView->scene()->clear();
  // get the model components and connectors now
  getModelComponents(mModelNameStructure);
  getModelConnections();
  getModelIconDiagram();
  // change the model type label in the status bar of projecttab
  mpModelicaTypeLabel->setText(StringHandler::getModelicaClassType(mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy->getClassRestriction(mModelNameStructure)));
  mOpenMode = false;
  // since we have processed the first item so remove it from the list now.
  models.removeFirst();
  foreach (QString model, models) {
    if (isChild()) {
      pMainWindow->mpLibrary->addModelFiles(StringHandler::getLastWordAfterDot(model), StringHandler::removeLastWordAfterDot(model), model);
    } else {
      pMainWindow->mpLibrary->addModelFiles(model, "", "");
    }
  }
  // update the Model Browser
  mpParentProjectTabWidget->tabChanged();
  return true;

  //    // first delete the node from tree and delete the model from omc
  //    QString modelNameStructure = mModelNameStructure;
  //    mModelNameStructure = "";
  //    ModelicaTree *pTree = pMainWindow->mpLibrary->mpModelicaTree;
  //    pTree->deleteNodeTriggered(pTree->getNode(modelNameStructure), false);
  //    // if the modelicatext is fine then do the processing on the list of models we get
  //    if (isChild()) {
  //        pMainWindow->mpLibrary->loadModel("within " + StringHandler::removeLastWordAfterDot(modelNameStructure) + ";"
  //                                          + mpModelicaEditor->toPlainText(), models);
  //    } else {
  //        pMainWindow->mpLibrary->loadModel(mpModelicaEditor->toPlainText(), models);
  //    }
  //    // now update the current opened tab
  //    mModelNameStructure = models.first();
  //    updateTabName(StringHandler::getLastWordAfterDot(mModelNameStructure), mModelNameStructure);
  //    // clear the complete view before loading the models again
  //    mpIconGraphicsView->removeAllConnectors();
  //    mpIconGraphicsView->deleteAllComponentObjects();
  //    mpIconGraphicsView->deleteAllShapesObject();
  //    mpIconGraphicsView->scene()->clear();
  //    mpDiagramGraphicsView->removeAllConnectors();
  //    mpDiagramGraphicsView->deleteAllComponentObjects();
  //    mpDiagramGraphicsView->deleteAllShapesObject();
  //    mpDiagramGraphicsView->scene()->clear();
  //    //mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy->loadString(modelsText);
  //    // get the model components and connectors now
  //    getModelComponents(mModelNameStructure);
  //    getModelConnections();
  //    getModelIconDiagram();
  //    // change the model type label in the status bar of projecttab
  //    mpModelicaTypeLabel->setText(StringHandler::getModelicaClassType(mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy->getClassRestriction(mModelNameStructure)));
  //    mOpenMode = false;
  //    return true;
  /*
    if (!modelName.isEmpty())
    {
        QString modelNameStructure;
        // if a model is a sub model then
        if (mModelNameStructure.contains("."))
        {
            modelNameStructure = StringHandler::removeLastWordAfterDot(mModelNameStructure)
                                 .append(".").append(modelName);
            // if model with this name already exists
            if (mModelNameStructure.compare(modelNameStructure) != 0)
            {
                if (!pMainWindow->mpOMCProxy->existClass(modelNameStructure))
                {
                    if (!loadSubModel(mpModelicaEditor->toPlainText()))
                        return false;
                }
                else
                {
                    pMainWindow->mpOMCProxy->setResult(GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS));
                    return false;
                }
            }
            if (pMainWindow->mpOMCProxy->updateSubClass(StringHandler::removeLastWordAfterDot(mModelNameStructure),
                                                        mpModelicaEditor->toPlainText()))
            {
                // clear the complete view before loading the models again
                mpIconGraphicsView->removeAllConnectors();
                mpIconGraphicsView->deleteAllComponentObjects();
                mpIconGraphicsView->deleteAllShapesObject();
                mpDiagramGraphicsView->removeAllConnectors();
                mpDiagramGraphicsView->deleteAllComponentObjects();
                mpDiagramGraphicsView->deleteAllShapesObject();
                // load model again so that we have models and connectors correctly.
                pMainWindow->mpOMCProxy->updateSubClass(StringHandler::removeLastWordAfterDot(mModelNameStructure),
                                                        mpModelicaEditor->toPlainText());
                // get the model components and connectors now
                getModelComponents();
                getModelConnections();
                getModelIconDiagram();
                // change the modelica tree node type accordingly
                ModelicaTreeNode *node = pMainWindow->mpLibrary->mpModelicaTree->getNode(mModelNameStructure);
                node->mType = pMainWindow->mpOMCProxy->getClassRestriction(mModelNameStructure);
                node->setIcon(0, node->getModelicaNodeIcon(node->mType));
                // if mType is package then check the child models
                if (node->mType == StringHandler::PACKAGE)
                {
                    pMainWindow->mpLibrary->mpModelicaTree->removeChildNodes(node);
                    QStringList modelsList = pMainWindow->mpOMCProxy->getClassNames(mModelNameStructure);
                    foreach (QString model, modelsList)
                    {
                        pMainWindow->mpLibrary->addModelFiles(model, mModelNameStructure,
                                                              mModelNameStructure + "." + model);
                    }

                }
                return true;
            }
            else
            {
                return false;
            }
        }
        // if a model is a root model then
        else
        {
            modelNameStructure = modelName;
            if (mModelNameStructure.compare(modelNameStructure) != 0)
            {
                if (!pMainWindow->mpOMCProxy->existClass(modelNameStructure))
                {
                    if (!loadRootModel(modelNameStructure))
                        return false;
                }
                else
                {
                    pMainWindow->mpOMCProxy->setResult(GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS));
                    return false;
                }
            }
            if (pMainWindow->mpOMCProxy->saveModifiedModel(mpModelicaEditor->toPlainText()))
            {
                // clear the complete view before loading the models again
                mpIconGraphicsView->removeAllConnectors();
                mpIconGraphicsView->deleteAllComponentObjects();
                mpIconGraphicsView->deleteAllShapesObject();
                mpDiagramGraphicsView->removeAllConnectors();
                mpDiagramGraphicsView->deleteAllComponentObjects();
                mpDiagramGraphicsView->deleteAllShapesObject();
                // load model again so that we have models and connectors correctly.
                pMainWindow->mpOMCProxy->saveModifiedModel(mpModelicaEditor->toPlainText());
                // get the model components and connectors now
                getModelComponents();
                getModelConnections();
                getModelIconDiagram();
                // change the modelica tree node type accordingly
                ModelicaTreeNode *node = pMainWindow->mpLibrary->mpModelicaTree->getNode(mModelNameStructure);
                node->mType = pMainWindow->mpOMCProxy->getClassRestriction(mModelNameStructure);
                node->setIcon(0, node->getModelicaNodeIcon(node->mType));
                // if mType is package then check the child models
                if (node->mType == StringHandler::PACKAGE)
                {
                    pMainWindow->mpLibrary->mpModelicaTree->removeChildNodes(node);
                    QStringList modelsList = pMainWindow->mpOMCProxy->getClassNames(mModelNameStructure);
                    foreach (QString model, modelsList)
                    {
                        pMainWindow->mpLibrary->addModelFiles(model,
                                                          StringHandler::removeLastWordAfterDot(mModelNameStructure),
                                                          StringHandler::removeLastWordAfterDot(mModelNameStructure)
                                                          + "." + model);
                    }
                }
                return true;
            }
            else
            {
                return false;
            }
        }
    }
    else
    {
        pMainWindow->mpOMCProxy->setResult(mpModelicaEditor->mErrorString);
        return false;
    }
    */
}

WelcomePageWidget::WelcomePageWidget(MainWindow *parent)
  : QWidget(parent)
{
  mpParentMainWindow = parent;
  // main frame
  mpMainFrame = new QFrame;
  //mpMainFrame->setMaximumWidth(600);
  mpMainFrame->setFrameShape(QFrame::Box);
  mpMainFrame->setContentsMargins(0, 0, 0, 0);
  mpMainFrame->setStyleSheet("QFrame{color:gray;}");
  // top frame
  mpTopFrame = new QFrame;
  mpTopFrame->setFrameShape(QFrame::Box);
  mpTopFrame->setMaximumHeight(95);
  mpTopFrame->setStyleSheet("QFrame{background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #828282, stop: 1 #5e5e5e);}");
  // top frame pixmap
  mpPixmapLabel = new QLabel;
  QPixmap pixmap(":/Resources/icons/omeditor.png");
  mpPixmapLabel->setPixmap(pixmap.scaled(75, 72, Qt::KeepAspectRatio, Qt::SmoothTransformation));
  mpPixmapLabel->setStyleSheet("background-color : transparent;");
  // top frame heading
  mpHeadingLabel = new QLabel(QString(Helper::applicationName).append(" - ").append(Helper::applicationIntroText));
  mpHeadingLabel->setFont(QFont("Helvetica", 16));
  mpHeadingLabel->setStyleSheet("background-color : transparent; color : white;");
  mpHeadingLabel->setGraphicsEffect(new QGraphicsDropShadowEffect);
  // top frame layout
  QHBoxLayout *topFrameLayout = new QHBoxLayout;
  topFrameLayout->setAlignment(Qt::AlignLeft);
  topFrameLayout->addWidget(mpPixmapLabel);
  topFrameLayout->addWidget(mpHeadingLabel);
  mpTopFrame->setLayout(topFrameLayout);
  // middle frame
  mpMiddleFrame = new QFrame;
  mpMiddleFrame->setFrameShape(QFrame::Box);
  mpMiddleFrame->setStyleSheet("QFrame{background-color: white;}");
  // recent items list
  mpRecentFilesLabel = new QLabel(tr("Recent Files"));
  mpRecentFilesLabel->setFont(QFont("", Helper::headingFontSize));
  mpNoRecentFileLabel = new QLabel(tr("No recent files found."));
  mpRecentItemsList = new QListWidget;
  mpRecentItemsList->setObjectName("RecentItemsList");
  mpRecentItemsList->setContentsMargins(0, 0, 0, 0);
  mpRecentItemsList->setSpacing(5);
  mpRecentItemsList->setFrameStyle(QFrame::NoFrame);
  mpRecentItemsList->setViewMode(QListView::ListMode);
  mpRecentItemsList->setMovement(QListView::Static);
  mpRecentItemsList->setIconSize(Helper::iconSize);
  mpRecentItemsList->setCurrentRow(0, QItemSelectionModel::Select);
  connect(mpRecentItemsList, SIGNAL(itemPressed(QListWidgetItem*)), SLOT(openRecentItem(QListWidgetItem*)));
  // middle frame layout
  QVBoxLayout *middleFrameLayout = new QVBoxLayout;
  middleFrameLayout->addWidget(mpRecentFilesLabel);
  middleFrameLayout->addWidget(mpNoRecentFileLabel);
  middleFrameLayout->addWidget(mpRecentItemsList);
  mpMiddleFrame->setLayout(middleFrameLayout);
  // bottom frame
  mpBottomFrame = new QFrame;
  mpBottomFrame->setFrameShape(QFrame::Box);
  mpBottomFrame->setMaximumHeight(50);
  mpBottomFrame->setStyleSheet("QFrame{background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #828282, stop: 1 #5e5e5e);}");
  // bottom frame create and open buttons buttons
  mpCreateModelButton = new QPushButton(tr("Create Model"));
  mpCreateModelButton->setStyleSheet("QPushButton{padding: 5px 15px 5px 15px;}");
  connect(mpCreateModelButton, SIGNAL(clicked()), mpParentMainWindow, SLOT(openNewModel()));
  mpOpenModelButton = new QPushButton(tr("Open Model"));
  mpOpenModelButton->setStyleSheet("QPushButton{padding: 5px 15px 5px 15px;}");
  connect(mpOpenModelButton, SIGNAL(clicked()), mpParentMainWindow->mpProjectTabs, SLOT(openFile()));
  // bottom frame layout
  QHBoxLayout *bottomFrameLayout = new QHBoxLayout;
  bottomFrameLayout->addWidget(mpCreateModelButton, 0, Qt::AlignLeft);
  bottomFrameLayout->addWidget(mpOpenModelButton, 0, Qt::AlignRight);
  mpBottomFrame->setLayout(bottomFrameLayout);
  // vertical layout for frames
  QVBoxLayout *verticalLayout = new QVBoxLayout;
  verticalLayout->setContentsMargins(0, 0, 0, 0);
  verticalLayout->addWidget(mpTopFrame);
  verticalLayout->addWidget(mpMiddleFrame);
  verticalLayout->addWidget(mpBottomFrame);
  // main frame layout
  mpMainFrame->setLayout(verticalLayout);
  QHBoxLayout *layout = new QHBoxLayout;
  layout->addWidget(mpMainFrame);
  layout->setContentsMargins(8, 8, 8, 8);
  setLayout(layout);
}

void WelcomePageWidget::addListItems()
{
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "omedit");
  QStringList files = settings.value("recentFileList/files").toStringList();

  int numRecentFiles = qMin(files.size(), (int)mpParentMainWindow->MaxRecentFiles);

  // remove list items first
  mpRecentItemsList->clear();
  // add new items now
  for (int i = 0; i < numRecentFiles; ++i) {
    QListWidgetItem *listItem = new QListWidgetItem(mpRecentItemsList);
    listItem->setIcon(QIcon(":/Resources/icons/next.png"));
    listItem->setText(files[i]);
  }

  if (numRecentFiles > 0)
    mpNoRecentFileLabel->setVisible(false);
  else
    mpNoRecentFileLabel->setVisible(true);
}

void WelcomePageWidget::paintEvent(QPaintEvent *event)
{
  Q_UNUSED(event);
  QPainter painter (this);
  painter.setPen(Qt::gray);
  QRect rectangle = rect();
  rectangle.setWidth(rect().width() - 2);
  rectangle.setHeight(rect().height() - 2);
  painter.drawRect(rectangle);
}

void WelcomePageWidget::openRecentItem(QListWidgetItem *item)
{
  mpParentMainWindow->mpProjectTabs->openFile(item->text());
}

//! @class ProjectTabWidget
//! @brief The ProjectTabWidget class is a container class for ProjectTab class

//! ProjectTabWidget contains ProjectTab widgets.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
ProjectTabWidget::ProjectTabWidget(MainWindow *parent)
  : QTabWidget(parent)
{
  mpParentMainWindow = parent;
  setTabsClosable(true);
  setContentsMargins(0, 0, 0, 0);
  setVisible(false);
  mShowLines = false;
  mToolBarEnabled = true;
  // make connections
  connect(mpParentMainWindow->mpOpenAction, SIGNAL(triggered()), this,SLOT(openFile()));
  connect(mpParentMainWindow->mpSaveAction, SIGNAL(triggered()), this,SLOT(saveProjectTab()));
  connect(mpParentMainWindow->mpSaveAsAction, SIGNAL(triggered()), this,SLOT(saveProjectTabAs()));
  connect(this,SIGNAL(tabCloseRequested(int)),SLOT(closeProjectTab(int)));
  connect(this, SIGNAL(tabAdded()), SLOT(enableProjectToolbar()));
  connect(this, SIGNAL(tabRemoved()), SLOT(disableProjectToolbar()));
  connect(this, SIGNAL(currentChanged(int)), SLOT(tabChanged()));
  emit tabRemoved();
  connect(mpParentMainWindow->mpResetZoomAction, SIGNAL(triggered()),this,SLOT(resetZoom()));
  connect(mpParentMainWindow->mpZoomInAction, SIGNAL(triggered()),this,SLOT(zoomIn()));
  connect(mpParentMainWindow->mpZoomOutAction, SIGNAL(triggered()),this,SLOT(zoomOut()));
  connect(mpParentMainWindow->mpLibrary->mpModelicaTree, SIGNAL(nodeDeleted()), SLOT(updateTabIndexes()));
  connect(this, SIGNAL(modelSaved(QString,QString)), mpParentMainWindow->mpLibrary->mpModelicaTree, SLOT(saveChildModels(QString,QString)));
}

ProjectTabWidget::~ProjectTabWidget()
{
  // delete all the tabs opened currently
  while(count() > 0)
  {
    delete widget(count() - 1);
  }
  // delete all the removed tabs as well.
  foreach (ProjectTab *pCurrentTab, mRemovedTabsList)
  {
    delete pCurrentTab;
  }
}

//! Returns a pointer to the currently active project tab
ProjectTab* ProjectTabWidget::getCurrentTab()
{
  return qobject_cast<ProjectTab *>(currentWidget());
}

ProjectTab* ProjectTabWidget::getProjectTab(QString name)
{
  ProjectTab *pProjectTab = getTabByName(name);
  if (pProjectTab)
    return pProjectTab;
  else
  {
    pProjectTab = getRemovedTabByName(name);
    if (pProjectTab)
      return pProjectTab;
    else
      return 0;
  }
}

ProjectTab* ProjectTabWidget::getTabByName(QString name)
{
  for (int i = 0; i < count() ; i++)
  {
    ProjectTab *pCurrentTab = dynamic_cast<ProjectTab*>(widget(i));
    if (!pCurrentTab)
      continue;
    if (pCurrentTab->mModelNameStructure == name)
    {
      return pCurrentTab;
    }
  }
  return 0;
}

ProjectTab* ProjectTabWidget::getRemovedTabByName(QString name)
{
  foreach (ProjectTab *pCurrentTab, mRemovedTabsList)
  {
    if (!pCurrentTab)
      continue;
    if (pCurrentTab->mModelNameStructure == name)
    {
      return pCurrentTab;
    }
  }
  return 0;
}

//! Reimplemented function to add the Project Tab.
int ProjectTabWidget::addTab(ProjectTab *tab, QString tabName)
{
  int position;
  tabName = StringHandler::getLastWordAfterDot(tabName);
  // if tab is not saved then add the star with the name
  position = QTabWidget::addTab(tab, QString(tabName).append(tab->mIsSaved ? "" : "*"));
  emit tabAdded();
  return position;
}

//! Reimplemented function to remove the Tab.
void ProjectTabWidget::removeTab(int index)
{
  // if tab is saved and user is just closing it then save it to mRemovedTabsList, so that we can open it later on
  ProjectTab *pCurrentTab = qobject_cast<ProjectTab *>(widget(index));
  QTabWidget::removeTab(index);
  mRemovedTabsList.append(pCurrentTab);
  emit tabRemoved();
}

void ProjectTabWidget::disableTabs(bool disable)
{
  int i = count();
  while(i > 0)
  {
    i = i - 1;
    if (i != currentIndex())
      setTabEnabled(i, !disable);
  }
}

void ProjectTabWidget::setSourceFile(QString modelName, QString modelFileName)
{
  if (mpParentMainWindow->mpOMCProxy->isPackage(modelName))
  {
    // set the source file name
    mpParentMainWindow->mpOMCProxy->setSourceFile(modelName, modelFileName);
    // get the class names of this package
    QStringList modelsList = mpParentMainWindow->mpOMCProxy->getClassNames(modelName);

    foreach (QString model, modelsList)
      setSourceFile(modelName + "." + model, modelFileName);
  }
  else
  {
    // set the source file name
    mpParentMainWindow->mpOMCProxy->setSourceFile(modelName, modelFileName);
  }
}

void ProjectTabWidget::saveChilds(ProjectTab *pProjectTab)
{
  // get the corresponding tree node first
  ModelicaTreeNode *item = mpParentMainWindow->mpLibrary->mpModelicaTree->getNode(pProjectTab->mModelNameStructure);
  // loop through all the childs of the tree node.
  int count = item->childCount();
  // Close the corresponding tabs if open
  for (int i = 0 ; i < count ; i++)
  {
    ModelicaTreeNode *treeNode = dynamic_cast<ModelicaTreeNode*>(item->child(i));
    ProjectTab *pProjectTab = getProjectTab(treeNode->mNameStructure);
    if (pProjectTab)
    {
      QString tabName = tabText(pProjectTab->mTabPosition);
      // make sure we only trim * and not any letter of model name.
      if (tabName.endsWith('*'))
        tabName.chop(1);

      setTabText(pProjectTab->mTabPosition, tabName);
      pProjectTab->mIsSaved = true;
      saveChilds(pProjectTab);
    }
  }
}

//! Adds an existing ProjectTab object to itself.
//! @see closeProjectTab(int index)
void ProjectTabWidget::addProjectTab(ProjectTab *projectTab, QString modelName, QString modelStructure)
{
  projectTab->mIsSaved = true;
  projectTab->mModelName = modelName;
  projectTab->mModelNameStructure = modelStructure;
  projectTab->mModelFileName = mpParentMainWindow->mpOMCProxy->getSourceFile(modelStructure);
  projectTab->setModelFilePathLabel(projectTab->mModelFileName);
  projectTab->mpDiagramGraphicsScene->blockSignals(true);
  projectTab->mpIconGraphicsScene->blockSignals(true);
  projectTab->mTabPosition = addTab(projectTab, modelName);
  projectTab->mpModelicaEditor->blockSignals(true);
  projectTab->getModelComponents(projectTab->mModelNameStructure);
  projectTab->getModelConnections();
  projectTab->getModelIconDiagram();
  projectTab->mpModelicaEditor->blockSignals(false);
  setCurrentWidget(projectTab);
  projectTab->mpDiagramGraphicsScene->blockSignals(false);
  projectTab->mpIconGraphicsScene->blockSignals(false);
}

//! Adds a ProjectTab object (a new tab) to itself.
//! @see closeProjectTab(int index)
void ProjectTabWidget::addNewProjectTab(QString modelName, QString modelStructure, int modelicaType)
{
  ProjectTab *newTab = new ProjectTab(modelName, modelStructure + modelName, modelicaType, StringHandler::ICON, false,
                                      modelStructure.isEmpty() ? false : true, false, this);
  newTab->mpModelicaEditor->setPlainText(mpParentMainWindow->mpOMCProxy->list(newTab->mModelNameStructure));
  newTab->mTabPosition = addTab(newTab, modelName);
  setCurrentWidget(newTab);
  // make the icon view visible and focused for key press events
  newTab->showDiagramView(true);
}

void ProjectTabWidget::addDiagramViewTab(QTreeWidgetItem *item, int column)
{
  Q_UNUSED(column);

  LibraryTreeNode *treeNode = dynamic_cast<LibraryTreeNode*>(item);
  ProjectTab *newTab = new ProjectTab(treeNode->mName, treeNode->mNameStructure,
                                      mpParentMainWindow->mpOMCProxy->getClassRestriction(treeNode->mNameStructure), StringHandler::DIAGRAM,
                                      true, false, false, this);
  newTab->mIsSaved = true;
  newTab->mTabPosition = addTab(newTab, treeNode->mName);

  Component *diagram;
  QString result = mpParentMainWindow->mpOMCProxy->getDiagramAnnotation(treeNode->mNameStructure);
  diagram = new Component(result, newTab->mModelName, newTab->mModelNameStructure, QPointF (0,0),
                          StringHandler::DIAGRAM, false, mpParentMainWindow->mpOMCProxy,
                          newTab->mpDiagramGraphicsView);

  Component *oldIconComponent = mpParentMainWindow->mpLibrary->getComponentObject(newTab->mModelNameStructure);
  Component *newIconComponent;

  if (!oldIconComponent)
  {
    QString result = mpParentMainWindow->mpOMCProxy->getIconAnnotation(newTab->mModelNameStructure);
    newIconComponent = new Component(result, newTab->mModelName, newTab->mModelNameStructure, QPointF (0,0),
                                     StringHandler::ICON, false, mpParentMainWindow->mpOMCProxy,
                                     newTab->mpIconGraphicsView);
  }
  else
  {
    newIconComponent = new Component(oldIconComponent, newTab->mModelName, QPointF (0,0), StringHandler::ICON,
                                     false, newTab->mpIconGraphicsView);
  }
  newTab->mpModelicaEditor->setPlainText(mpParentMainWindow->mpOMCProxy->list(newTab->mModelNameStructure));
  // set document modified state to false for empty models otherwise Start and End modifiers are different error is raised.
  newTab->mpModelicaEditor->document()->setModified(false);
  setCurrentWidget(newTab);
  // make the icon view visible and focused for key press events
  newTab->showDiagramView(true);
}

//! Saves current project.
//! @see saveProjectTab(int index)
void ProjectTabWidget::saveProjectTab()
{
  saveProjectTab(currentIndex(), false);
}

//! Saves current project to a new model file.
//! @see saveProjectTab(int index)
void ProjectTabWidget::saveProjectTabAs()
{
  saveProjectTab(currentIndex(), true);
}

//! Saves project at index.
//! @param index defines which project to save.
//! @see saveProjectTab()
void ProjectTabWidget::saveProjectTab(int index, bool saveAs)
{
  ProjectTab *pCurrentTab = qobject_cast<ProjectTab *>(widget(index));
  if (!pCurrentTab)
    return;
  // if the model is readonly then simply return.........e.g Ground, Inertia, EMF etc.
  if (pCurrentTab->isReadOnly())
    return;
  // validate the modelica text before saving the model
  if (!pCurrentTab->mpModelicaEditor->validateText())
    return;
  // if model is a child model then give user a message and return
  if (pCurrentTab->isChild())
  {
    ProblemsWidget *pMessageWidget = pCurrentTab->mpParentProjectTabWidget->mpParentMainWindow->mpMessageWidget;
    pMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0, GUIMessages::getMessage(GUIMessages::CHILD_MODEL_SAVE)
                                                  .arg(pCurrentTab->getModelicaTypeLabel()).arg(pCurrentTab->mModelName),
                                                  Helper::scriptingKind, Helper::notificationLevel, 0, pMessageWidget->mpProblem));
    return;
  }

  QString tabName = tabText(index);

  if (saveAs)
  {
    if (saveModel(saveAs))
    {
      // make sure we only trim * and not any letter of model name.
      if (tabName.endsWith('*'))
        tabName.chop(1);

      setTabText(index, tabName);
      pCurrentTab->mIsSaved = true;
      // since the saving of package is successfull so now we go through all the childs of package and make them saved.
      saveChilds(pCurrentTab);
    }
  }
  // if not saveAs then
  else
  {
    // if user presses ctrl + s and model is already saved
    if (!pCurrentTab->mIsSaved || pCurrentTab->mModelicaType == StringHandler::PACKAGE)
    {
      if (saveModel(saveAs))
      {
        // make sure we only trim * and not any letter of model name.
        if (tabName.endsWith('*'))
          tabName.chop(1);

        setTabText(index, tabName);
        pCurrentTab->mIsSaved = true;
        // since the saving of package is successfull so now we go through all the childs of package and make them saved.
        saveChilds(pCurrentTab);
      }
    }
  }
  QString oldModelName = pCurrentTab->mModelName;
  QString oldModelNameStructure = pCurrentTab->mModelNameStructure;
  ModelicaTreeNode *node = pCurrentTab->mpParentProjectTabWidget->mpParentMainWindow->mpLibrary->mpModelicaTree->getNode(pCurrentTab->mModelNameStructure);
  pCurrentTab->mpParentProjectTabWidget->mpParentMainWindow->mpLibrary->updateNodeText(oldModelName, oldModelNameStructure, node);
}

//! Saves the model in the active project tab to a model file.
//! @param saveAs tells whether or not an already existing file name shall be used
//! @see saveProjectTab()
//! @see loadModel()
bool ProjectTabWidget::saveModel(bool saveAs)
{
  ProjectTab *pCurrentTab = qobject_cast<ProjectTab *>(currentWidget());
  MainWindow *pMainWindow = pCurrentTab->mpParentProjectTabWidget->mpParentMainWindow;

  QString modelFileName;
  // if first time save or doing a saveas
  if(pCurrentTab->mModelFileName.isEmpty() | saveAs)
  {
    modelFileName = StringHandler::getSaveFileName(this, saveAs ? tr("Save File As") : tr("Save File"), NULL, Helper::omFileTypes, NULL,
                                                   "mo", &pCurrentTab->mModelName);

    if (modelFileName.isEmpty())
    {
      return false;
    } else {
      // set the source file in OMC
      pMainWindow->mpOMCProxy->setSourceFile(pCurrentTab->mModelNameStructure, modelFileName);
      // if opened tab is a package save all of its child models
      if (pCurrentTab->mModelicaType == StringHandler::PACKAGE)
        emit modelSaved(pCurrentTab->mModelNameStructure, modelFileName);
      // finally save the model through OMC
      if (pMainWindow->mpOMCProxy->save(pCurrentTab->mModelNameStructure))
      {
        pCurrentTab->mModelFileName = modelFileName;
        pCurrentTab->setModelFilePathLabel(modelFileName);
        // put the newly saved file in recent files list.
        pMainWindow->setCurrentFile(modelFileName);
        return true;
      }
      // if OMC is unable to save the file
      else
      {
        pMainWindow->mpOMCProxy->printMessagesStringInternal();
        return false;
      }
    }
  }
  // if saving the file second time
  else
  {
    // set the source file in OMC
    pMainWindow->mpOMCProxy->setSourceFile(pCurrentTab->mModelNameStructure, pCurrentTab->mModelFileName);
    // if opened tab is a package save all of its child models
    if (pCurrentTab->mModelicaType == StringHandler::PACKAGE)
      emit modelSaved(pCurrentTab->mModelNameStructure, pCurrentTab->mModelFileName);
    // finally save the model through OMC
    if (pMainWindow->mpOMCProxy->save(pCurrentTab->mModelNameStructure))
    {
      return true;
    }
    // if OMC is unable to save the file
    else
    {
      pMainWindow->mpOMCProxy->printMessagesStringInternal();
      return false;
    }
  }
}

//! Closes current project.
//! @param index defines which project to close.
//! @return true if closing went ok. false if the user canceled the operation.
//! @see closeAllProjectTabs()
bool ProjectTabWidget::closeProjectTab(int index)
{
  //    ModelicaTree *pTree = mpParentMainWindow->mpLibrary->mpModelicaTree;
  //    ProjectTab *pCurrentTab = dynamic_cast<ProjectTab*>(widget(index));
  //    if (!(pCurrentTab->mIsSaved))
  //    {
  //        QString modelName;
  //        modelName = tabText(index);
  //        modelName.chop(1);
  //        QMessageBox *msgBox = new QMessageBox(mpParentMainWindow);
  //        msgBox->setWindowTitle(QString(Helper::applicationName).append(" - Question"));
  //        msgBox->setIcon(QMessageBox::Question);
  //        msgBox->setText(QString(GUIMessages::getMessage(GUIMessages::SAVED_MODEL))
  //                        .arg(pCurrentTab->getModelicaTypeLabel()).arg(pCurrentTab->mModelName));
  //        msgBox->setInformativeText(GUIMessages::getMessage(GUIMessages::SAVE_CHANGES));
  //        msgBox->setStandardButtons(QMessageBox::Save | QMessageBox::Discard | QMessageBox::Cancel);
  //        msgBox->setDefaultButton(QMessageBox::Save);

  //        int answer = msgBox->exec();

  //        switch (answer)
  //        {
  //        case QMessageBox::Save:
  //            // Save was clicked
  //            saveProjectTab(index, false);
  //            removeTab(index);
  //            return true;
  //        case QMessageBox::Discard:
  //            // Don't Save was clicked
  //            //if (pTree->deleteNodeTriggered(pTree->getNode(pCurrentTab->mModelNameStructure)))
  //                //removeTab(index);
  //            pTree->deleteNodeTriggered(pTree->getNode(pCurrentTab->mModelNameStructure), false);
  //            return true;
  //        case QMessageBox::Cancel:
  //            // Cancel was clicked
  //            return false;
  //        default:
  //            // should never be reached
  //            return false;
  //        }
  //    }
  //    else
  //    {
  removeTab(index);
  return true;
  //    }
}

//! Closes all opened projects.
//! @return true if closing went ok. false if the user canceled the operation.
//! @see closeProjectTab(int index)
//! @see saveProjectTab()
bool ProjectTabWidget::closeAllProjectTabs()
{
  for (int i = 0 ; i < count() ; i++)
  {
    ProjectTab *pProjectTab = dynamic_cast<ProjectTab*>(widget(i));
    if (pProjectTab)
    {
      if (!pProjectTab->mIsSaved)
      {
        QMessageBox *msgBox = new QMessageBox(mpParentMainWindow);
        msgBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::question));
        msgBox->setIcon(QMessageBox::Question);
        msgBox->setText(tr("There are unsaved models opened. Do you still want to quit?"));
        msgBox->setStandardButtons(QMessageBox::Yes | QMessageBox::No);
        msgBox->setDefaultButton(QMessageBox::No);

        int answer = msgBox->exec();
        msgBox->raise();

        switch (answer)
        {
          case QMessageBox::Yes:
            return true;
          case QMessageBox::No:
            return false;
          default:
            // should never be reached
            return false;
        }
      }
    }
  }
  return true;
}

//! Loads a model from a file and opens it in a new project tab.
//! @see saveModel(bool saveAs)
void ProjectTabWidget::openFile(QString fileName)
{
  if (fileName.isEmpty())
  {
    QString name = StringHandler::getOpenFileName(this, Helper::chooseFile, NULL, Helper::omFileTypes, NULL);
    if (name.isEmpty())
      return;
    else
      fileName = name;
  }
  // get the class names now to check if they are already loaded or not
  QStringList existingmodelsList;
  if (!mpParentMainWindow->mpOMCProxy->parseFile(fileName))
  {
    return;
  }
  QString result = StringHandler::removeFirstLastCurlBrackets(mpParentMainWindow->mpOMCProxy->getResult());
  QStringList modelsList = result.split(",", QString::SkipEmptyParts);
  bool existModel = false;
  // check if the model already exists
  foreach(QString model, modelsList)
  {
    if (mpParentMainWindow->mpOMCProxy->existClass(model))
    {
      existingmodelsList.append(model);
      existModel = true;
    }
  }

  // check if existModel is true
  if (existModel)
  {
    QMessageBox *msgBox = new QMessageBox(mpParentMainWindow);
    msgBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::information));
    msgBox->setIcon(QMessageBox::Information);
    msgBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg("")));
    msgBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::REDEFINING_EXISTING_MODELS))
                               .arg(existingmodelsList.join(",")).append("\n").append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD)));
    msgBox->setStandardButtons(QMessageBox::Ok);
    msgBox->exec();
  }
  // if no conflicting model found then just load the file simply
  else
  {
    mpParentMainWindow->mpLibrary->loadFile(fileName, modelsList);
    mpParentMainWindow->switchToModelingView();
  }
}

//! Loads a model and opens it in a new project tab.
//! @see saveModel(bool saveAs)
void ProjectTabWidget::openModel(QString modelText)
{
  QStringList modelsList = mpParentMainWindow->mpOMCProxy->parseString(modelText);
  if (modelsList.size() == 0)
    return;

  QStringList existingmodelsList;
  bool existModel = false;
  // check if the model already exists
  foreach(QString model, modelsList)
  {
    if (mpParentMainWindow->mpOMCProxy->existClass(model))
    {
      existingmodelsList.append(model);
      existModel = true;
    }
  }

  // check if existModel is true
  if (existModel)
  {
    QMessageBox *msgBox = new QMessageBox(mpParentMainWindow);
    msgBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::information));
    msgBox->setIcon(QMessageBox::Information);
    msgBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_MODEL).arg("")));
    msgBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::REDEFINING_EXISTING_MODELS))
                               .arg(existingmodelsList.join(",")).append("\n").append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD)));
    msgBox->setStandardButtons(QMessageBox::Ok);
    msgBox->exec();
  }
  // if no conflicting model found then just load the file simply
  else
  {
    mpParentMainWindow->mpLibrary->loadModel(modelText, modelsList);
  }
}

//! Tells the current tab to reset zoom to 100%.
//! @see zoomIn()
//! @see zoomOut()
void ProjectTabWidget::resetZoom()
{
  ProjectTab *pCurrentTab = getCurrentTab();
  if (pCurrentTab)
  {
    if (pCurrentTab->mpDiagramGraphicsView->isVisible())
      pCurrentTab->mpDiagramGraphicsView->resetZoom();
    else if (pCurrentTab->mpIconGraphicsView->isVisible())
      pCurrentTab->mpIconGraphicsView->resetZoom();
  }
}

//! Tells the current tab to increase its zoom factor.
//! @see resetZoom()
//! @see zoomOut()
void ProjectTabWidget::zoomIn()
{
  ProjectTab *pCurrentTab = getCurrentTab();
  if (pCurrentTab)
  {
    if (pCurrentTab->mpDiagramGraphicsView->isVisible())
      pCurrentTab->mpDiagramGraphicsView->zoomIn();
    else if (pCurrentTab->mpIconGraphicsView->isVisible())
      pCurrentTab->mpIconGraphicsView->zoomIn();
  }
}

//! Tells the current tab to decrease its zoom factor.
//! @see resetZoom()
//! @see zoomIn()
void ProjectTabWidget::zoomOut()
{
  ProjectTab *pCurrentTab = getCurrentTab();
  if (pCurrentTab)
  {
    if (pCurrentTab->mpDiagramGraphicsView->isVisible())
      pCurrentTab->mpDiagramGraphicsView->zoomOut();
    else if (pCurrentTab->mpIconGraphicsView->isVisible())
      pCurrentTab->mpIconGraphicsView->zoomOut();
  }
}

void ProjectTabWidget::updateTabIndexes()
{
  for (int i = 0 ; i < count() ; i++)
  {
    (dynamic_cast<ProjectTab*>(widget(i)))->mTabPosition = i;
  }

}

void ProjectTabWidget::enableProjectToolbar()
{
  if (!mToolBarEnabled)
  {
    mpParentMainWindow->mpGridLinesAction->setEnabled(true);
    mpParentMainWindow->mpResetZoomAction->setEnabled(true);
    mpParentMainWindow->mpZoomInAction->setEnabled(true);
    mpParentMainWindow->mpZoomOutAction->setEnabled(true);
    mpParentMainWindow->mpFlatModelAction->setEnabled(true);
    mpParentMainWindow->mpCheckModelAction->setEnabled(true);
    // enable the shapes tool bar
    mpParentMainWindow->mpShapesToolBar->setEnabled(true);
    // enable the export as image action
    mpParentMainWindow->mpExportAsImageAction->setEnabled(true);
    // enable the export to omnotebook action
    mpParentMainWindow->mpExportToOMNotebookAction->setEnabled(true);
    // enable the export FMI
    mpParentMainWindow->mpExportFMIAction->setEnabled(true);
    mToolBarEnabled = true;
  }
}

void ProjectTabWidget::disableProjectToolbar()
{
  if (mToolBarEnabled and (count() == 0))
  {
    mpParentMainWindow->mpGridLinesAction->setEnabled(false);
    mpParentMainWindow->mpResetZoomAction->setEnabled(false);
    mpParentMainWindow->mpZoomInAction->setEnabled(false);
    mpParentMainWindow->mpZoomOutAction->setEnabled(false);
    mpParentMainWindow->mpFlatModelAction->setEnabled(false);
    mpParentMainWindow->mpCheckModelAction->setEnabled(false);
    // disable the shapes tool bar
    mpParentMainWindow->mpShapesToolBar->setEnabled(false);
    // disable the export as image action
    mpParentMainWindow->mpExportAsImageAction->setEnabled(false);
    // disable the export to omnotebook action
    mpParentMainWindow->mpExportToOMNotebookAction->setEnabled(false);
    // disable the export FMI
    mpParentMainWindow->mpExportFMIAction->setEnabled(false);
    mToolBarEnabled = false;
  }
}

void ProjectTabWidget::tabChanged()
{
  mpParentMainWindow->mpModelBrowser->addModelBrowserNode();
}

void ProjectTabWidget::keyPressEvent(QKeyEvent *event)
{
  ProjectTab *pCurrentTab = getCurrentTab();
  if (!pCurrentTab)
    return;

  if (pCurrentTab->mpModelicaEditorWidget->isVisible())
  {
    if (event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_F)
    {
      pCurrentTab->mpModelicaEditor->mpFindWidget->show();
      pCurrentTab->mpModelicaEditor->mpSearchTextBox->setFocus();
    }
    else if (event->key() == Qt::Key_Escape)
    {
      pCurrentTab->mpModelicaEditor->mpFindWidget->hide();
    }
    else if (event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_L)
    {
      GotoLineWidget *pGotoLineWidget = new GotoLineWidget(pCurrentTab->mpModelicaEditor);
      pGotoLineWidget->show();
    }
  }

  QTabWidget::keyPressEvent(event);
}
