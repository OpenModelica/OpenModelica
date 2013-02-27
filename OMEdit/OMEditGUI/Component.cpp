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
 * RCS: $Id$
 */

#include "Component.h"

Component::Component(QString value, QString name, QString className, QPointF position, int type, bool connector,
                     OMCProxy *omc, GraphicsView *graphicsView, Component *pParent)
  : ShapeAnnotation(graphicsView, pParent), mAnnotationString(value), mName(name), mClassName(className), mType(type),
    mIsConnector(connector), mpOMCProxy(omc), mpGraphicsView(graphicsView)
{
  mIsLibraryComponent = false;
  mpComponentProperties = 0;
  //QList<ComponentsProperties*> components = mpOMCProxy->getComponents(className);
  mpParentComponent = pParent;
  mIconParametersList.append(mpOMCProxy->getParameters(mpGraphicsView->mpParentProjectTab->mModelNameStructure, mClassName, mName));
  mpTransformation = 0;
  parseAnnotationString(this, value);
  mpTransformation = new Transformation(this);
  setTransform(mpTransformation->getTransformationMatrix());
  // if component is an icon
  if (mType == StringHandler::ICON)
  {
    setPos(position);
    if (mpGraphicsView->mpParentProjectTab->isReadOnly())
    {
      scale(Helper::globalDiagramXScale, Helper::globalDiagramYScale);
      getClassComponents(mClassName, mType);
    }
    else
    {
      scale(Helper::globalIconXScale, Helper::globalIconYScale);
      setComponentFlags();
      setAcceptHoverEvents(true);
      getClassComponents(mClassName, mType);
      createSelectionBox();
      createActions();
    }
  }
  // if component is a diagram
  else if ((mType == StringHandler::DIAGRAM))
  {
    scale(Helper::globalDiagramXScale, Helper::globalDiagramYScale);
    setPos(position);
    getClassComponents(mClassName, mType, this);
  }
  // if everything is fine with icon then add it to scene
  mpGraphicsView->scene()->addItem(this);

  // if type is diagram then allow connections not for icon view
  if (mType == StringHandler::ICON && mIsConnector)
    connect(this, SIGNAL(componentClicked(Component*)), mpGraphicsView, SLOT(addConnector(Component*)));
}

/* Called for inheritance annotation instance */
Component::Component(QString value, QString className, int type, bool connector, Component *pParent)
  : ShapeAnnotation(pParent), mAnnotationString(value), mClassName(className), mType(type), mIsConnector(connector)
{

  setFlag(QGraphicsItem::ItemStacksBehindParent);
  mIsLibraryComponent = false;
  mpParentComponent = pParent;
  mpOMCProxy = pParent->mpOMCProxy;
  mpGraphicsView = pParent->mpGraphicsView;
  mpComponentProperties = 0;
  mpTransformation = 0;
  parseAnnotationString(this, mAnnotationString);
  //mpChildComponentProperties = mpOMCProxy->getComponents(mClassName);
  //! @todo Since for some components we get empty annotations but its inherited componets does have annotations
  //! @todo so set the parent give the parent bounding box the value of inherited class boundingbox.
  if (mRectangle.width() > 1)
    getRootParentComponent()->mRectangle = mRectangle;
}

/* Called for component annotation instance */
Component::Component(QString value, QString transformationString, ComponentsProperties *pComponentProperties, int type,
                     bool connector, Component *pParent)
  : ShapeAnnotation(pParent), mAnnotationString(value), mTransformationString(transformationString),
    mpComponentProperties(pComponentProperties), mType(type), mIsConnector(connector)
{
  mName = mpComponentProperties->getName();
  mClassName = mpComponentProperties->getClassName();

  mIsLibraryComponent = false;
  mpParentComponent = pParent;
  mpOMCProxy = pParent->mpOMCProxy;
  mpGraphicsView = pParent->mpGraphicsView;
  mIconParametersList.append(mpOMCProxy->getParameters(mpGraphicsView->mpParentProjectTab->mModelNameStructure, mClassName, mName));
  mpTransformation = 0;
  parseAnnotationString(this, mAnnotationString);
  mpTransformation = new Transformation(this);
  setTransform(mpTransformation->getTransformationMatrix());
  //mpChildComponentProperties = mpOMCProxy->getComponents(mClassName);
  //! @todo Since for some components we get empty annotations but its inherited componets does have annotations
  //! @todo so give the parent bounding box the value of inherited class boundingbox.
  if (mRectangle.width() > 1)
    getRootParentComponent()->mRectangle = mRectangle;
  // if type is diagram then allow connections not for icon view
  if (mType == StringHandler::ICON && mIsConnector)
    connect(this, SIGNAL(componentClicked(Component*)), mpGraphicsView, SLOT(addConnector(Component*)));
}

/* Used for Library Component */
Component::Component(QString value, QString className, bool connector, OMCProxy *omc, Component *pParent)
  : ShapeAnnotation(pParent), mAnnotationString(value), mClassName(className), mIsConnector(connector), mpOMCProxy(omc)
{
  mIsLibraryComponent = true;
  mpParentComponent = pParent;
  mpComponentProperties = 0;
  mType = StringHandler::ICON;
  mIsConnector = false;

  parseAnnotationString(this, value, true);
  getClassComponents(mClassName, mType);
}

/* Used for Library Component. Called for inheritance annotation instance */
Component::Component(QString value, QString className, bool connector, Component *pParent)
  : ShapeAnnotation(pParent), mAnnotationString(value), mClassName(className), mIsConnector(connector)
{
  setFlag(QGraphicsItem::ItemStacksBehindParent);

  mIsLibraryComponent = true;
  mpParentComponent = pParent;
  mpOMCProxy = pParent->mpOMCProxy;
  mpComponentProperties = 0;
  mType = StringHandler::ICON;
  parseAnnotationString(this, mAnnotationString, true);
  //mpChildComponentProperties = mpOMCProxy->getComponents(mClassName);

  //! @todo Since for some components we get empty annotations but its inherited componets does have annotations
  //! @todo so give the parent bounding box the value of inherited class boundingbox.
  if (mRectangle.width() > 1)
    getRootParentComponent()->mRectangle = mRectangle;
}

/* Used for Library Component. Called for component annotation instance */
Component::Component(QString value, QString transformationString, ComponentsProperties *pComponentProperties, bool connector,
                     Component *pParent)
  : ShapeAnnotation(pParent), mAnnotationString(value), mTransformationString(transformationString),
    mpComponentProperties(pComponentProperties), mIsConnector(connector)
{
  mName = mpComponentProperties->getName();
  mClassName = mpComponentProperties->getClassName();
  mIsLibraryComponent = true;
  mpParentComponent = pParent;
  mpOMCProxy = pParent->mpOMCProxy;
  mType = StringHandler::ICON;

  mpTransformation = 0;
  parseAnnotationString(this, mAnnotationString, true);
  //mpChildComponentProperties = mpOMCProxy->getComponents(mClassName);
  mpTransformation = new Transformation(this);
  setTransform(mpTransformation->getTransformationMatrix());


  //! @todo Since for some components we get empty annotations but its inherited componets does have annotations
  //! @todo so set the parent give the parent bounding box the value of inherited class boundingbox.
  if (mRectangle.width() > 1)
    getRootParentComponent()->mRectangle = mRectangle;
}

Component::Component(Component *pComponent, QString name, QPointF position, int type, bool connector,
                     GraphicsView *graphicsView, Component *pParent)
  : ShapeAnnotation(graphicsView, pParent), mName(name), mType(type), mIsConnector(connector), mpGraphicsView(graphicsView)
{
  mpParentComponent = pParent;
  mClassName = pComponent->mClassName;
  mpOMCProxy = mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy;
  mAnnotationString = pComponent->mAnnotationString;

  // Assing the Graphics View of this component to passed component. In order to avoid exceptions
  pComponent->mpGraphicsView = mpGraphicsView;
  // get the component parameters
  mIconParametersList.append(mpOMCProxy->getParameters(mpGraphicsView->mpParentProjectTab->mModelNameStructure, mClassName, mName));
  mpTransformation = 0;
  parseAnnotationString(this, mAnnotationString);
  mpTransformation = new Transformation(this);
  setTransform(mpTransformation->getTransformationMatrix());
  mpChildComponentProperties = pComponent->mpChildComponentProperties;
  // if component is an icon
  if ((mType == StringHandler::ICON))
  {
    setPos(position);
    if (mpGraphicsView->mpParentProjectTab->isReadOnly())
    {
      scale(Helper::globalDiagramXScale, Helper::globalDiagramYScale);
      copyClassComponents(pComponent);
    }
    else
    {
      scale(Helper::globalIconXScale, Helper::globalIconYScale);
      setComponentFlags();
      setAcceptHoverEvents(true);
      copyClassComponents(pComponent);
      createSelectionBox();
      createActions();
    }
  }
  // if component is a diagram
  else if ((mType == StringHandler::DIAGRAM))
  {
    scale(Helper::globalDiagramXScale, Helper::globalDiagramYScale);
    setPos(position);
    copyClassComponents(pComponent);
  }
  // if everything is fine with icon then add it to scene
  mpGraphicsView->scene()->addItem(this);
}

Component::~Component()
{
  // delete all the list of shapes
  foreach(ShapeAnnotation *shape, mpShapesList)
  {
    delete shape;
  }

  //    // delete the list of all components
  //    foreach(Component *component, mpComponentsList)
  //        delete component;

  //    // delete the list of all inherited components
  //    foreach(Component *component, mpInheritanceList)
  //        delete component;
}

bool Component::getIsConnector()
{
  return mIsConnector;
}

//! Parses the result of getIconAnnotation command.
//! @param value is the result of getIconAnnotation command obtained from OMC.
bool Component::parseAnnotationString(Component *item, QString value, bool libraryIcon)
{
  foreach(ShapeAnnotation *shape, mpShapesList)
  {
    mpShapesList.removeOne(shape);
    delete shape;
  }

  value = StringHandler::removeFirstLastCurlBrackets(value);
  if (value.isEmpty())
  {
    return false;
  }
  QStringList list = StringHandler::getStrings(value);

  if (mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
  {
    if (list.size() < 9)
      return false;
  }
  else if (mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION2X)
  {
    if (list.size() < 4)
      return false;
  }
  qreal x1, x2, y1, y2, width, height;
  x1 = static_cast<QString>(list.at(0)).toFloat();
  y1 = static_cast<QString>(list.at(1)).toFloat();
  x2 = static_cast<QString>(list.at(2)).toFloat();
  y2 = static_cast<QString>(list.at(3)).toFloat();
  width = fabs(x1 - x2);
  height = fabs(y1 - y2);

  item->mRectangle = QRectF (x1, y1, width, height);

  if (list.size() < 5)
  {
    return true;
  }

  QStringList shapesList;

  if (mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
  {
    mPreserveAspectRatio = static_cast<QString>(list.at(4)).contains("true");
    mInitialScale = static_cast<QString>(list.at(5)).toFloat();
    mGrid.append(static_cast<QString>(list.at(6)).toFloat());
    mGrid.append(static_cast<QString>(list.at(7)).toFloat());
    shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(8)), '(', ')');
  }
  else if (mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION2X)
  {
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
      LineAnnotation *lineAnnotation = new LineAnnotation(shape, item);
      item->mpShapesList.append(lineAnnotation);
    }
    if (shape.startsWith("Polygon"))
    {
      shape = shape.mid(QString("Polygon").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      PolygonAnnotation *polygonAnnotation = new PolygonAnnotation(shape, item);
      item->mpShapesList.append(polygonAnnotation);
    }
    if (shape.startsWith("Rectangle"))
    {
      shape = shape.mid(QString("Rectangle").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      RectangleAnnotation *rectangleAnnotation = new RectangleAnnotation(shape, item);
      item->mpShapesList.append(rectangleAnnotation);
    }
    if (shape.startsWith("Ellipse"))
    {
      shape = shape.mid(QString("Ellipse").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      EllipseAnnotation *ellipseAnnotation = new EllipseAnnotation(shape, item);
      item->mpShapesList.append(ellipseAnnotation);
    }
    // don't parse the text annotation for library icon
    //! @todo We don't show text for Library Icons.
    if (!libraryIcon)
    {
      if (shape.startsWith("Text"))
      {
        shape = shape.mid(QString("Text").length());
        shape = StringHandler::removeFirstLastBrackets(shape);
        TextAnnotation *textAnnotation = new TextAnnotation(shape, item);
        item->mpShapesList.append(textAnnotation);
      }
    }
    if (shape.startsWith("Bitmap"))
    {
      shape = shape.mid(QString("Bitmap").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      BitmapAnnotation *bitmapAnnotation = new BitmapAnnotation(shape, item);
      item->mpShapesList.append(bitmapAnnotation);
    }
  }
}

QRectF Component::boundingRect() const
{
  if (mRectangle.isEmpty())
    return QRectF(-100.0, -100.0, 200.0, 200.0);      // needed for empty annotations. We draw red boxes for them.
  return mRectangle;
}

void Component::createSelectionBox()
{
  qreal x1, y1, x2, y2;
  boundingRect().getCoords(&x1, &y1, &x2, &y2);

  mpTopLeftCornerItem = new CornerItem(x1, y2, Qt::TopLeftCorner, this);
  connect(mpTopLeftCornerItem, SIGNAL(iconSelected()), this, SLOT(showSelectionBox()));
  connect(mpTopLeftCornerItem, SIGNAL(iconResized(qreal, qreal)), this, SLOT(resizeComponent(qreal, qreal)));
  // create top right selection box
  mpTopRightCornerItem = new CornerItem(x2, y2, Qt::TopRightCorner, this);
  connect(mpTopRightCornerItem, SIGNAL(iconSelected()), this, SLOT(showSelectionBox()));
  connect(mpTopRightCornerItem, SIGNAL(iconResized(qreal, qreal)), this, SLOT(resizeComponent(qreal, qreal)));
  // create bottom left selection box
  mpBottomLeftCornerItem = new CornerItem(x1, y1, Qt::BottomLeftCorner, this);
  connect(mpBottomLeftCornerItem, SIGNAL(iconSelected()), this, SLOT(showSelectionBox()));
  connect(mpBottomLeftCornerItem, SIGNAL(iconResized(qreal, qreal)), this, SLOT(resizeComponent(qreal, qreal)));
  // create bottom right selection box
  mpBottomRightCornerItem = new CornerItem(x2, y1, Qt::BottomRightCorner, this);
  connect(mpBottomRightCornerItem, SIGNAL(iconSelected()), this, SLOT(showSelectionBox()));
  connect(mpBottomRightCornerItem, SIGNAL(iconResized(qreal, qreal)), this, SLOT(resizeComponent(qreal, qreal)));
}

void Component::createActions()
{
  // Icon Attributes Action
  mpIconAttributesAction = new QAction(Helper::attributes, mpGraphicsView);
  mpIconAttributesAction->setStatusTip(tr("Shows the item attributes"));
  connect(mpIconAttributesAction, SIGNAL(triggered()), SLOT(openIconAttributes()));
  // Icon Properties Action
  mpIconPropertiesAction = new QAction(QIcon(":/Resources/icons/tool.png"), Helper::properties, mpGraphicsView);
  mpIconPropertiesAction->setStatusTip(tr("Shows the item properties"));
  connect(mpIconPropertiesAction, SIGNAL(triggered()), SLOT(openIconProperties()));
}

void Component::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(painter);
  Q_UNUSED(option);
  Q_UNUSED(widget);

  if (!mpParentComponent)     // only check for root components i.e the one that doesn't have a parent.
  {
    if (canDrawRedBox(this))
    {
      QPen pen(Qt::red);
      pen.setCosmetic(true);
      painter->setPen(pen);
      painter->drawRect(boundingRect());
      painter->drawLine(QPointF(-100, -100), QPointF(100,100));
      painter->drawLine(QPointF(-100, 100), QPointF(100,-100));
    }
  }
}

void Component::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
  MainWindow *pMainWindow = mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
  // if user is viewing the component in Icon View
  if ((mpGraphicsView->mIconType == StringHandler::ICON) or (mpGraphicsView->mpParentProjectTab->isReadOnly()))
    return;
  // if component is a connector type then emit the componentClicked signal
  if (event->button() == Qt::LeftButton  && pMainWindow->mpConnectAction->isChecked() && mIsConnector)
  {
    emit componentClicked(this);
  }
  // if we are creating the connector then make sure user can not select and move components
  if ((mpGraphicsView->mIsCreatingConnector) and !mpParentComponent)
  {
    unsetComponentFlags();
    return;
  }
  // if user not creating connector then check if the item flags are active or not
  else if (!mpParentComponent)
  {
    setComponentFlags();
  }
  // call the mouse press event only if component is the root component
  if (!mpParentComponent)
  {
    QGraphicsItem::mousePressEvent(event);
  }
}

void Component::mouseDoubleClickEvent(QGraphicsSceneMouseEvent *event)
{
  openIconProperties();
}

//! Event when mouse cursor enters component icon.
void Component::hoverEnterEvent(QGraphicsSceneHoverEvent *event)
{
  Q_UNUSED(event);

  // if we are creating the connector then don't show selection box on hover events
  if (mpGraphicsView->mIsCreatingConnector)
    return;

  if(!isSelected())
    setSelectionBoxHover();
}

//! Event when mouse cursor leaves component icon.
void Component::hoverLeaveEvent(QGraphicsSceneHoverEvent *event)
{
  Q_UNUSED(event);

  if(!isSelected())
    setSelectionBoxPassive();
}

void Component::contextMenuEvent(QGraphicsSceneContextMenuEvent *event)
{
  // if we are viewing some readonly component then don't show the contextmenu
  if (mpGraphicsView->mpParentProjectTab->isReadOnly())
    return;
  // get the root component, it could be either icon or diagram
  Component *pComponent = getRootParentComponent();

  QMenu menu(pComponent->mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
  menu.addAction(pComponent->mpGraphicsView->mpRotateIconAction);
  menu.addAction(pComponent->mpGraphicsView->mpRotateAntiIconAction);
  menu.addAction(pComponent->mpGraphicsView->mpResetRotation);
  //menu.addAction(pComponent->mpGraphicsView->mpHorizontalFlipAction);
  //menu.addAction(pComponent->mpGraphicsView->mpVerticalFlipAction);
  menu.addSeparator();
  menu.addAction(pComponent->mpGraphicsView->mpDeleteIconAction);
  if (pComponent->mType == StringHandler::ICON)
  {
    menu.addSeparator();
    menu.addAction(pComponent->mpIconAttributesAction);
    menu.addAction(pComponent->mpIconPropertiesAction);
    menu.addSeparator();
  }
  menu.exec(event->screenPos());
}

QVariant Component::itemChange(GraphicsItemChange change, const QVariant &value)
{
  QGraphicsItem::itemChange(change, value);

  if (change == QGraphicsItem::ItemSelectedHasChanged)
  {
    if (isSelected())
    {
      setSelectionBoxActive();
      setCursor(Qt::SizeAllCursor);
      connect(mpGraphicsView->mpHorizontalFlipAction, SIGNAL(triggered()), SLOT(flipHorizontal()));
      connect(mpGraphicsView->mpVerticalFlipAction, SIGNAL(triggered()), SLOT(flipVertical()));
      connect(mpGraphicsView->mpRotateIconAction, SIGNAL(triggered()), SLOT(rotateClockwise()));
      connect(mpGraphicsView->mpRotateAntiIconAction, SIGNAL(triggered()), SLOT(rotateAntiClockwise()));
      connect(mpGraphicsView->mpResetRotation, SIGNAL(triggered()), SLOT(resetRotation()));
      connect(mpGraphicsView->mpDeleteIconAction, SIGNAL(triggered()), SLOT(deleteMe()));
      connect(mpGraphicsView, SIGNAL(keyPressDelete()), SLOT(deleteMe()));
      connect(mpGraphicsView, SIGNAL(keyPressUp()), SLOT(moveUp()));
      connect(mpGraphicsView, SIGNAL(keyPressDown()), SLOT(moveDown()));
      connect(mpGraphicsView, SIGNAL(keyPressLeft()), SLOT(moveLeft()));
      connect(mpGraphicsView, SIGNAL(keyPressRight()), SLOT(moveRight()));
      connect(mpGraphicsView, SIGNAL(keyPressRotateClockwise()), SLOT(rotateClockwise()));
      connect(mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), SLOT(rotateAntiClockwise()));
    }
    else
    {
      setSelectionBoxPassive();
      unsetCursor();
      disconnect(mpGraphicsView->mpHorizontalFlipAction, SIGNAL(triggered()), this, SLOT(flipHorizontal()));
      disconnect(mpGraphicsView->mpVerticalFlipAction, SIGNAL(triggered()), this, SLOT(flipVertical()));
      disconnect(mpGraphicsView->mpRotateIconAction, SIGNAL(triggered()), this, SLOT(rotateClockwise()));
      disconnect(mpGraphicsView->mpRotateAntiIconAction, SIGNAL(triggered()), this, SLOT(rotateAntiClockwise()));
      disconnect(mpGraphicsView->mpResetRotation, SIGNAL(triggered()), this, SLOT(resetRotation()));
      disconnect(mpGraphicsView->mpDeleteIconAction, SIGNAL(triggered()), this, SLOT(deleteMe()));
      disconnect(mpGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()));
      disconnect(mpGraphicsView, SIGNAL(keyPressUp()), this, SLOT(moveUp()));
      disconnect(mpGraphicsView, SIGNAL(keyPressDown()), this, SLOT(moveDown()));
      disconnect(mpGraphicsView, SIGNAL(keyPressLeft()), this, SLOT(moveLeft()));
      disconnect(mpGraphicsView, SIGNAL(keyPressRight()), this, SLOT(moveRight()));
      disconnect(mpGraphicsView, SIGNAL(keyPressRotateClockwise()), this, SLOT(rotateClockwise()));
      disconnect(mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()));
    }
  }
  else if (change == QGraphicsItem::ItemPositionHasChanged)
  {
    emit componentMoved();
    // if user has changed the postion using the keyboard then update annotations
    // if user changes the position with mouse we handle it in mouse events of graphicsview
    if (!isMousePressed)
    {
      if (mIsConnector)
      {
        Component *pComponent;
        if (mpGraphicsView->mIconType == StringHandler::ICON)
        {
          pComponent = mpGraphicsView->mpParentProjectTab->mpDiagramGraphicsView->getComponentObject(getName());
          pComponent->setPos(pos());
        }
        else if(mpGraphicsView->mIconType == StringHandler::DIAGRAM)
        {
          pComponent = mpGraphicsView->mpParentProjectTab->mpIconGraphicsView->getComponentObject(getName());
          pComponent->setPos(pos());
        }
        //if component is a connector, synchronize the position in its diagram view with the icon view
        pComponent->updateAnnotationString();
      }
      updateAnnotationString();
      // update connectors annotations that are associated to this component
      emit componentPositionChanged();
      ProjectTab *pProjectTab = mpGraphicsView->mpParentProjectTab;
      pProjectTab->mpModelicaEditor->setPlainText(mpOMCProxy->list(pProjectTab->mModelNameStructure));
    }
  }
#if (QT_VERSION >= QT_VERSION_CHECK(4, 7, 0))
  else if (change == QGraphicsItem::ItemRotationHasChanged)
  {
    emit componentRotated(true);
    updateAnnotationString();
    updateSelectionBox();
    ProjectTab *pProjectTab = mpGraphicsView->mpParentProjectTab;
    pProjectTab->mpModelicaEditor->setPlainText(mpOMCProxy->list(pProjectTab->mModelNameStructure));
  }
#endif
  return value;
}

void Component::setSelectionBoxActive()
{
  mpTopLeftCornerItem->setActive();
  mpTopRightCornerItem->setActive();
  mpBottomLeftCornerItem->setActive();
  mpBottomRightCornerItem->setActive();
}

void Component::setSelectionBoxPassive()
{
  mpTopLeftCornerItem->setPassive();
  mpTopRightCornerItem->setPassive();
  mpBottomLeftCornerItem->setPassive();
  mpBottomRightCornerItem->setPassive();
}

void Component::setSelectionBoxHover()
{
  mpTopLeftCornerItem->setHovered();
  mpTopRightCornerItem->setHovered();
  mpBottomLeftCornerItem->setHovered();
  mpBottomRightCornerItem->setHovered();
}

void Component::showSelectionBox()
{
  setSelectionBoxActive();
}

void Component::updateSelectionBox()
{
  qreal x1, y1, x2, y2;
  boundingRect().getCoords(&x1, &y1, &x2, &y2);


  if (rotation() == 0)
  {
    mpBottomLeftCornerItem->updateCornerItem(x1, y1, Qt::BottomLeftCorner);
    mpTopLeftCornerItem->updateCornerItem(x1, y2, Qt::TopLeftCorner);
    mpTopRightCornerItem->updateCornerItem(x2, y2, Qt::TopRightCorner);
    mpBottomRightCornerItem->updateCornerItem(x2, y1, Qt::BottomRightCorner);
  }
  // Clockwise rotation angles
  else if (rotation() == -90)
  {
    mpBottomLeftCornerItem->updateCornerItem(x2, y1, Qt::BottomLeftCorner);
    mpTopLeftCornerItem->updateCornerItem(x1, y1, Qt::TopLeftCorner);
    mpTopRightCornerItem->updateCornerItem(x1, y2, Qt::TopRightCorner);
    mpBottomRightCornerItem->updateCornerItem(x2, y2, Qt::BottomRightCorner);
  }
  else if (rotation() == -180)
  {
    mpBottomLeftCornerItem->updateCornerItem(x2, y2, Qt::BottomLeftCorner);
    mpTopLeftCornerItem->updateCornerItem(x2, y1, Qt::TopLeftCorner);
    mpTopRightCornerItem->updateCornerItem(x1, y1, Qt::TopRightCorner);
    mpBottomRightCornerItem->updateCornerItem(x1, y2, Qt::BottomRightCorner);
  }
  else if (rotation() == -270)
  {
    mpBottomLeftCornerItem->updateCornerItem(x1, y2, Qt::BottomLeftCorner);
    mpTopLeftCornerItem->updateCornerItem(x2, y2, Qt::TopLeftCorner);
    mpTopRightCornerItem->updateCornerItem(x2, y1, Qt::TopRightCorner);
    mpBottomRightCornerItem->updateCornerItem(x1, y1, Qt::BottomRightCorner);
  }
  // AntiClockwise rotation angles
  else if (rotation() == 90)
  {
    mpBottomLeftCornerItem->updateCornerItem(x1, y2, Qt::BottomLeftCorner);
    mpTopLeftCornerItem->updateCornerItem(x2, y2, Qt::TopLeftCorner);
    mpTopRightCornerItem->updateCornerItem(x2, y1, Qt::TopRightCorner);
    mpBottomRightCornerItem->updateCornerItem(x1, y1, Qt::BottomRightCorner);
  }
  else if (rotation() == 180)
  {
    mpBottomLeftCornerItem->updateCornerItem(x2, y2, Qt::BottomLeftCorner);
    mpTopLeftCornerItem->updateCornerItem(x2, y1, Qt::TopLeftCorner);
    mpTopRightCornerItem->updateCornerItem(x1, y1, Qt::TopRightCorner);
    mpBottomRightCornerItem->updateCornerItem(x1, y2, Qt::BottomRightCorner);
  }
  else if (rotation() == 270)
  {
    mpBottomLeftCornerItem->updateCornerItem(x2, y1, Qt::BottomLeftCorner);
    mpTopLeftCornerItem->updateCornerItem(x1, y1, Qt::TopLeftCorner);
    mpTopRightCornerItem->updateCornerItem(x1, y2, Qt::TopRightCorner);
    mpBottomRightCornerItem->updateCornerItem(x2, y2, Qt::BottomRightCorner);
  }
}

void Component::addConnector(Connector *item)
{
  connect(this, SIGNAL(componentMoved()), item, SLOT(drawConnector()));
  connect(this, SIGNAL(componentPositionChanged()), item, SLOT(updateConnectionAnnotationString()));

  connect(this, SIGNAL(componentRotated(bool)), item, SLOT(drawConnector(bool)));
  connect(this, SIGNAL(componentRotated(bool)), item, SLOT(updateConnectionAnnotationString()));

  connect(this, SIGNAL(componentScaled()), item, SLOT(drawConnector()));
  connect(this, SIGNAL(componentScaled()), item, SLOT(updateConnectionAnnotationString()));
}

void Component::setComponentFlags()
{
  // set the item flags
  if(!flags().testFlag((QGraphicsItem::ItemIsMovable)))
    setFlag(QGraphicsItem::ItemIsMovable);
  if(!flags().testFlag((QGraphicsItem::ItemIsSelectable)))
    setFlag(QGraphicsItem::ItemIsSelectable);
  if(!flags().testFlag((QGraphicsItem::ItemSendsGeometryChanges)))
    setFlag(QGraphicsItem::ItemSendsGeometryChanges);
}

void Component::unsetComponentFlags()
{
  // unset the item flags
  if(flags().testFlag((QGraphicsItem::ItemIsMovable)))
    setFlag(QGraphicsItem::ItemIsMovable, false);
  if(flags().testFlag((QGraphicsItem::ItemIsSelectable)))
    setFlag(QGraphicsItem::ItemIsSelectable, false);
  if(flags().testFlag((QGraphicsItem::ItemSendsGeometryChanges)))
    setFlag(QGraphicsItem::ItemSendsGeometryChanges, false);
}

QString Component::getTransformationString()
{
  QString annotationString;
  if (mpGraphicsView->mIconType == StringHandler::ICON)
    annotationString.append("iconTransformation=transformation(origin=");
  else if (mpGraphicsView->mIconType == StringHandler::DIAGRAM)
    annotationString.append("transformation=transformation(origin=");
  // add the icon origin
  annotationString.append("{").append(QString::number(pos().x())).append(",");
  annotationString.append(QString::number(pos().y())).append("}, ");
  // add extent points
  qreal x1, y1, x2, y2;
  boundingRect().getCoords(&x1, &y1, &x2, &y2);
  QPointF extent1, extent2;
  extent1.setX(mapToScene(x1, y1).x() - pos().x());
  extent1.setY(mapToScene(x1, y1).y() - pos().y());
  extent2.setX(mapToScene(x2, y2).x() - pos().x());
  extent2.setY(mapToScene(x2, y2).y() - pos().y());

  annotationString.append("extent={").append("{").append(QString::number(extent1.x()));
  annotationString.append(",").append(QString::number(extent1.y())).append("},");
  annotationString.append("{").append(QString::number(extent2.x())).append(",");
  annotationString.append(QString::number(extent2.y())).append("}}, ");
  // add icon rotation
  annotationString.append("rotation=").append(QString::number(rotation())).append(")");

  return annotationString;
}

bool Component::canDrawRedBox(Component *pComponent)
{
  bool draw = false;
  if (pComponent->mpShapesList.isEmpty())
    draw = true;
  else
    return false;
  // check components list
  foreach (Component *pChildComponent, pComponent->mpComponentsList)
  {
    draw = canDrawRedBox(pChildComponent);
    if (!draw)
      return draw;    // return whenever we get false
  }
  // check inherited components list
  foreach (Component *pInheritedComponent, pComponent->mpInheritanceList)
  {
    draw = canDrawRedBox(pInheritedComponent);
    if (!draw)
      return draw;    // return whenever we get false
  }
  return draw;
}

void Component::updateAnnotationString(bool updateBothViews)
{
  // create the annotation string
  QString annotationString = "annotate=Placement(";
  if (mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
  {
    annotationString.append("visible=true, ");
  }
  if (mIsConnector and updateBothViews)
  {

    if (mpGraphicsView->mIconType == StringHandler::ICON)
    {
      // first get the component from diagram view and get the transformations
      Component *pComponent;
      pComponent = mpGraphicsView->mpParentProjectTab->mpDiagramGraphicsView->getComponentObject(getName());
      if (pComponent)
        annotationString.append(pComponent->getTransformationString());
      // then get the icon transformations
      annotationString.append(QString(", ").append(getTransformationString()));
    }
    else if (mpGraphicsView->mIconType == StringHandler::DIAGRAM)
    {
      // first get the component from diagram view and get the transformations
      annotationString.append(getTransformationString());
      // then get the icon transformations
      Component *pComponent;
      pComponent = mpGraphicsView->mpParentProjectTab->mpIconGraphicsView->getComponentObject(getName());
      if (pComponent)
        annotationString.append(QString(", ").append(pComponent->getTransformationString()));
    }
  }
  else
  {
    annotationString.append(getTransformationString());
  }
  annotationString.append(")");
  // Add component annotation.
  mpOMCProxy->updateComponent(mName, mClassName, mpGraphicsView->mpParentProjectTab->mModelNameStructure, annotationString);
  // call the addclassannotation if the graphicsview is icon, so the icon in the tree is also updated
  if (mpGraphicsView->mIconType == StringHandler::ICON || mIsConnector)
    mpGraphicsView->addClassAnnotation();
}

void Component::resizeComponent(qreal resizeFactorX, qreal resizeFactorY)
{
  if (resizeFactorX > 0 && resizeFactorY > 0)
  {
    scale(resizeFactorX, resizeFactorY);
    emit componentScaled();
    updateAnnotationString();
    ProjectTab *pProjectTab = mpGraphicsView->mpParentProjectTab;
    pProjectTab->mpModelicaEditor->setPlainText(mpOMCProxy->list(pProjectTab->mModelNameStructure));
  }
}

//! Tells the component to ask its parent to delete it.
void Component::deleteMe(bool update)
{
  // make sure you disconnect all signals before deleting the object
  disconnect(mpGraphicsView->mpHorizontalFlipAction, SIGNAL(triggered()), this, SLOT(flipHorizontal()));
  disconnect(mpGraphicsView->mpVerticalFlipAction, SIGNAL(triggered()), this, SLOT(flipVertical()));
  disconnect(mpGraphicsView->mpRotateIconAction, SIGNAL(triggered()), this, SLOT(rotateClockwise()));
  disconnect(mpGraphicsView->mpRotateAntiIconAction, SIGNAL(triggered()), this, SLOT(rotateAntiClockwise()));
  disconnect(mpGraphicsView->mpResetRotation, SIGNAL(triggered()), this, SLOT(resetRotation()));
  disconnect(mpGraphicsView->mpDeleteIconAction, SIGNAL(triggered()), this, SLOT(deleteMe()));
  disconnect(mpGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()));
  disconnect(mpGraphicsView, SIGNAL(keyPressUp()), this, SLOT(moveUp()));
  disconnect(mpGraphicsView, SIGNAL(keyPressDown()), this, SLOT(moveDown()));
  disconnect(mpGraphicsView, SIGNAL(keyPressLeft()), this, SLOT(moveLeft()));
  disconnect(mpGraphicsView, SIGNAL(keyPressRight()), this, SLOT(moveRight()));
  disconnect(mpGraphicsView, SIGNAL(keyPressRotateClockwise()), this, SLOT(rotateClockwise()));
  disconnect(mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()));
  // delete the object
  GraphicsView *pGraphicsView = qobject_cast<GraphicsView*>(const_cast<QObject*>(sender()));
  // delete the component from model
  mpGraphicsView->deleteComponentObject(this, update);
  // remove the component from the scene
  mpGraphicsView->scene()->removeItem(this);
  // if the signal is not send by graphicsview then call addclassannotation
  if (!pGraphicsView)
  {
    if (mpGraphicsView->mIconType == StringHandler::ICON)
      mpGraphicsView->addClassAnnotation(update);
  }
  deleteLater();
}

void Component::openIconProperties()
{
  IconProperties *iconProperties = new IconProperties(this, mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
  iconProperties->show();
}

void Component::openIconAttributes()
{
  IconAttributes *iconAttributes = new IconAttributes(this, mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
  iconAttributes->show();
}

QString Component::getName()
{
  return mName;
}

void Component::updateName(QString newName)
{
  // check in icon text annotation
  foreach (ShapeAnnotation *shapeAnnotation, mpShapesList)
  {
    if (dynamic_cast<TextAnnotation*>(shapeAnnotation))
    {
      TextAnnotation *textAnnotation = dynamic_cast<TextAnnotation*>(shapeAnnotation);
      if (textAnnotation->getTextString() == mName)
      {
        textAnnotation->setTextString(newName);
        mName = newName;
        return;
      }
    }
  }
  // check in icon's inheritance text annotation
  foreach (Component *inheritance, mpInheritanceList)
  {
    foreach (ShapeAnnotation *shapeAnnotation, inheritance->mpShapesList)
    {
      if (dynamic_cast<TextAnnotation*>(shapeAnnotation))
      {
        TextAnnotation *textAnnotation = dynamic_cast<TextAnnotation*>(shapeAnnotation);
        if (textAnnotation->getTextString() == mName)
        {
          textAnnotation->setTextString(newName);
          mName = newName;
          return;
        }
      }
    }
  }
  // check in icon's components text annotation
  foreach (Component *component, mpComponentsList)
  {
    foreach (ShapeAnnotation *shapeAnnotation, component->mpShapesList)
    {
      if (dynamic_cast<TextAnnotation*>(shapeAnnotation))
      {
        TextAnnotation *textAnnotation = dynamic_cast<TextAnnotation*>(shapeAnnotation);
        if (textAnnotation->getTextString() == mName)
        {
          textAnnotation->setTextString(newName);
          mName = newName;
          return;
        }
      }
    }
  }
}

void Component::updateParameterValue(QString oldValue, QString newValue)
{
  // check in icon text annotation
  foreach (ShapeAnnotation *shapeAnnotation, mpShapesList)
  {
    if (dynamic_cast<TextAnnotation*>(shapeAnnotation))
    {
      TextAnnotation *textAnnotation = dynamic_cast<TextAnnotation*>(shapeAnnotation);
      if (textAnnotation->getTextString() == oldValue)
      {
        textAnnotation->setTextString(newValue);
        return;
      }
    }
  }
}

QString Component::getClassName()
{
  return mClassName;
}

Component* Component::getParentComponent()
{
  if (!mpParentComponent)
    return this;
  else
    return mpParentComponent;
}

Component* Component::getRootParentComponent(bool secondLast)
{
  Component *pComponent, *pPreviousComponent;
  pComponent = this;
  pPreviousComponent = this;
  while (pComponent->mpParentComponent)
  {
    pPreviousComponent = pComponent;
    pComponent = pComponent->mpParentComponent;
  }

  if (secondLast)
    return pPreviousComponent;
  else
    return pComponent;
}

//! this function is called for icon view
void Component::getClassComponents(QString className, int type)
{
  int inheritanceCount = mpOMCProxy->getInheritanceCount(className);

  for(int i = 1 ; i <= inheritanceCount ; i++)
  {
    QString inheritedClass = mpOMCProxy->getNthInheritedClass(className, i);
    // If the inherited class is one of the builtin type such as Real we can
    // stop here, because the class can not contain any components, etc.
    if (mpOMCProxy->isBuiltinType(inheritedClass))
    {
      mpInheritanceList.append(new Component("", inheritedClass, mpOMCProxy->isWhat(StringHandler::CONNECTOR, inheritedClass), this));
      return;
    }

    QString annotationString = mpOMCProxy->getIconAnnotation(inheritedClass);

    Component *inheritance;
    if (mIsLibraryComponent)
    {
      inheritance  = new Component(annotationString, inheritedClass, mpOMCProxy->isWhat(StringHandler::CONNECTOR, inheritedClass), this);
    }
    else
    {
      inheritance = new Component(annotationString, inheritedClass, type, mpOMCProxy->isWhat(StringHandler::CONNECTOR, inheritedClass), this);
    }
    mpInheritanceList.append(inheritance);
    // avoid cycles
    if (inheritedClass.compare(className) == 0)
    {
      return;
    }
    getClassComponents(inheritedClass, type);
  }

  QList<ComponentsProperties*> components = mpOMCProxy->getComponents(className);
  mpChildComponentProperties = components;
  QStringList componentsAnnotationsList = mpOMCProxy->getComponentAnnotations(className);
  int i = 0;
  foreach (ComponentsProperties *componentProperties, components)
  {
    if (componentsAnnotationsList.size() <= i)
      continue;

    if (static_cast<QString>(componentsAnnotationsList.at(i)).toLower().contains("error"))
    {
      i++;
      continue;
    }

    // if component is protected we don't show it in the icon layer.
    if (componentProperties->getProtected())
    {
      i++;
      continue;
    }

    if (StringHandler::removeFirstLastCurlBrackets(componentsAnnotationsList.at(i)).length() > 0)
    {
      if (mpOMCProxy->isWhat(StringHandler::CONNECTOR, componentProperties->getClassName()))
      {
        QString result = mpOMCProxy->getIconAnnotation(componentProperties->getClassName());

        Component *component;
        if (mIsLibraryComponent)
        {
          component = new Component(result, componentsAnnotationsList.at(i), componentProperties, true, this);
        }
        else
        {
          component = new Component(result, componentsAnnotationsList.at(i), componentProperties,
                                    StringHandler::ICON, true, this);
        }
        mpComponentsList.append(component);
        //! @todo commented it to make the library load fast.....
        //getClassComponents(componentProperties->getClassName(), type);
      }
    }
    //        else
    //        {
    //            //! @todo Change it to add all components.............
    //            if (!mIsLibraryComponent)
    //                mpComponentProperties = components.at(0);
    //        }
    i++;
  }
}

//! this function is called for diagram view
void Component::getClassComponents(QString className, int type, Component *pParent)
{
  // if component type is diagram then
  if (type == StringHandler::DIAGRAM)
  {
    // get the diagram connections
    int connections = mpOMCProxy->getConnectionCount(className);

    for (int i = 1 ; i <= connections ; i++)
    {
      QString result = mpOMCProxy->getNthConnectionAnnotation(className, i);
      QStringList shapesList;
      shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(result), '(', ')');
      // Now parse the shapes available in list
      foreach (QString shape, shapesList)
      {
        shape = StringHandler::removeFirstLastCurlBrackets(shape);
        if (shape.startsWith("Line"))
        {
          shape = shape.mid(QString("Line").length());
          result = StringHandler::removeFirstLastBrackets(shape);
          LineAnnotation *lineAnnotation = new LineAnnotation(result, pParent);
          Q_UNUSED(lineAnnotation);
        }
      }
    }
  }

  int inheritanceCount = mpOMCProxy->getInheritanceCount(className);

  for(int i = 1 ; i <= inheritanceCount ; i++)
  {
    QString inheritedClass = mpOMCProxy->getNthInheritedClass(className, i);
    QString annotationString;

    // If the inherited class is one of the builtin type such as Real we can
    // stop here, because the class can not contain any components, etc.
    if (mpOMCProxy->isBuiltinType(inheritedClass))
    {
      mpInheritanceList.append(new Component("", inheritedClass, mpOMCProxy->isWhat(StringHandler::CONNECTOR, inheritedClass), this));
      return;
    }

    if (type == StringHandler::ICON)
      annotationString = mpOMCProxy->getIconAnnotation(inheritedClass);
    else if (type == StringHandler::DIAGRAM)
      annotationString = mpOMCProxy->getDiagramAnnotation(inheritedClass);

    Component *inheritance = new Component(annotationString, inheritedClass, type,
                                           mpOMCProxy->isWhat(StringHandler::CONNECTOR, inheritedClass), pParent);
    mpInheritanceList.append(inheritance);
    // avoid cycles
    if (inheritedClass.compare(className) == 0)
    {
      return;
    }
    getClassComponents(inheritedClass, type, inheritance);
  }

  QList<ComponentsProperties*> components = mpOMCProxy->getComponents(className);
  mpChildComponentProperties=components;

  QStringList componentsAnnotationsList = mpOMCProxy->getComponentAnnotations(className);
  int i = 0;
  foreach (ComponentsProperties *componentProperties, components)
  {
    if (static_cast<QString>(componentsAnnotationsList.at(i)).toLower().contains("error"))
    {
      i++;
      continue;
    }
    if (type == StringHandler::ICON)
    {
      if (StringHandler::removeFirstLastCurlBrackets(componentsAnnotationsList.at(i)).length() > 0)
      {
        if (mpOMCProxy->isWhat(StringHandler::CONNECTOR, componentProperties->getClassName()))
        {
          QString result = mpOMCProxy->getIconAnnotation(componentProperties->getClassName());
          Component *component;
          component = new Component(result, componentsAnnotationsList.at(i), componentProperties, StringHandler::ICON, true, pParent);
          mpComponentsList.append(component);
          getClassComponents(componentProperties->getClassName(), StringHandler::ICON, component);
        }
      }
      else
      {
        //! @todo Change it to add all components.............
        mpComponentProperties = components.at(0);
      }
    }
    else if (type == StringHandler::DIAGRAM)
    {
      if (StringHandler::removeFirstLastCurlBrackets(componentsAnnotationsList.at(i)).length() > 0)
      {
        if (mpOMCProxy->isWhat(StringHandler::CONNECTOR, componentProperties->getClassName()))
        {
          QString result = mpOMCProxy->getDiagramAnnotation(componentProperties->getClassName());
          Component *component;
          component = new Component(result, componentsAnnotationsList.at(i), componentProperties, StringHandler::DIAGRAM, true, pParent);
          mpComponentsList.append(component);
          getClassComponents(componentProperties->getClassName(), StringHandler::DIAGRAM, component);
        }
        else
        {
          QString result = mpOMCProxy->getIconAnnotation(componentProperties->getClassName());
          Component *component;
          component = new Component(result, componentsAnnotationsList.at(i), componentProperties, StringHandler::DIAGRAM, true, pParent);
          mpComponentsList.append(component);
          getClassComponents(componentProperties->getClassName(), StringHandler::ICON, component);
        }
      }
    }
    i++;
  }
}

//! this function is called when we need to create a copy of one component
void Component::copyClassComponents(Component *pComponent)
{
  foreach(Component *inheritance, pComponent->mpInheritanceList)
  {
    Component *inheritanceComponent = new Component(inheritance->mAnnotationString, inheritance->mClassName, inheritance->mType,
                                                    inheritance->mIsConnector, this);
    mpInheritanceList.append(inheritanceComponent);
    copyClassComponents(inheritance);
  }

  foreach(Component *component, pComponent->mpComponentsList)
  {
    Component *portComponent = new Component(component->mAnnotationString, component->mTransformationString, component->mpComponentProperties,
                                             component->mType, component->mIsConnector, this);
    mpComponentsList.append(portComponent);
    copyClassComponents(component);
  }
}
