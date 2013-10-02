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
 * 
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#include "Component.h"
#include "ComponentProperties.h"

Component::Component(QString annotation, QString name, QString className, StringHandler::ModelicaClasses type, QString transformation,
                     QPointF position, bool inheritedComponent, QString inheritedClassName, OMCProxy *pOMCProxy,
                     GraphicsView *pGraphicsView, Component *pParent)
  : QGraphicsItem(pParent), mName(name), mClassName(className), mType(type), mpOMCProxy(pOMCProxy), mpGraphicsView(pGraphicsView),
    mpParentComponent(pParent)
{
  setZValue(2000);
  mIsLibraryComponent = false;
  mIsInheritedComponent = inheritedComponent;
  mInheritedClassName = inheritedClassName;
  mComponentType = Component::Root;
  initialize();
  mpComponentInfo = 0;
  setComponentFlags();
  setAcceptHoverEvents(true);
  getClassInheritedComponents(true);
  parseAnnotationString(annotation);
  getClassComponents();
  /* if component doesn't exists show it as red cross box. */
  if (!mpOMCProxy->existClass(className))
    parseAnnotationString(Helper::errorComponentAnnotationString);
  /* if component doesn't have any annotation then assign it a default one. */
  else if (canUseDefaultAnnotation(this))
    parseAnnotationString(Helper::defaultComponentAnnotationString);
  // transformation
  mpTransformation = new Transformation(mpGraphicsView->getViewType());
  mpTransformation->parseTransformationString(transformation, boundingRect().width(), boundingRect().height());
  if (transformation.isEmpty())
  {
    mpTransformation->setOrigin(position);
    qreal initialScale = mpCoOrdinateSystem->getInitialScale();
    mpTransformation->setExtent1(QPointF(initialScale * boundingRect().left(), initialScale * boundingRect().top()));
    mpTransformation->setExtent2(QPointF(initialScale * boundingRect().right(), initialScale * boundingRect().bottom()));
    mpTransformation->setRotateAngle(0.0);
  }
  setTransform(mpTransformation->getTransformationMatrix());
  createActions();
  createResizerItems();
  setToolTip(QString("<b>").append(mClassName).append("</b> <i>").append(mName).append("</i>"));
  // if everything is fine with icon then add it to scene
  mpGraphicsView->scene()->addItem(this);
  connect(this, SIGNAL(componentTransformHasChanged()), SLOT(updatePlacementAnnotation()));
  // if type is connector and component is not a library component and not a system library class.
  bool isSystemLibrary = mpGraphicsView->getModelWidget()->getLibraryTreeNode()->isSystemLibrary();
  if (mType == StringHandler::Connector && !isLibraryComponent() && !isSystemLibrary)
    connect(this, SIGNAL(componentClicked(Component*)), mpGraphicsView, SLOT(addConnection(Component*)));
}

/* Called for inheritance annotation instance */
Component::Component(QString annotation, QString className, StringHandler::ModelicaClasses type, Component *pParent)
  : QGraphicsItem(pParent), mName(""), mClassName(className), mType(type), mpParentComponent(pParent)
{
  mIsLibraryComponent = mpParentComponent->isLibraryComponent() ? true : false;
  mIsInheritedComponent = mpParentComponent->isInheritedComponent() ? true : false;
  mComponentType = Component::Extend;
  mpComponentInfo = 0;
  mpTransformation = 0;
  mpOMCProxy = pParent->getOMCProxy();
  mpGraphicsView = isLibraryComponent() ? 0 : pParent->getGraphicsView();
  initialize();
  setAcceptHoverEvents(true);
  getClassInheritedComponents();
  parseAnnotationString(annotation);
  // if type is connector and component is not a library component and not a system library class.
//  bool isSystemLibrary = mpGraphicsView ? mpGraphicsView->getModelWidget()->getLibraryTreeNode()->isSystemLibrary() : false;
//  if (mType == StringHandler::Connector && !isLibraryComponent() && !isSystemLibrary)
//    connect(this, SIGNAL(componentClicked(Component*)), mpGraphicsView, SLOT(addConnection(Component*)));
}

/* Called for component annotation instance */
Component::Component(QString annotation, QString transformationString, ComponentInfo *pComponentInfo, StringHandler::ModelicaClasses type,
                     Component *pParent)
  : QGraphicsItem(pParent), mpComponentInfo(pComponentInfo), mType(type), mpParentComponent(pParent)
{
  mName = mpComponentInfo->getName();
  mClassName = mpComponentInfo->getClassName();
  mIsLibraryComponent = mpParentComponent->isLibraryComponent() ? true : false;
  mIsInheritedComponent = mpParentComponent->isInheritedComponent() ? true : false;
  mComponentType = Component::Port;
  mpOMCProxy = pParent->getOMCProxy();
  mpGraphicsView = isLibraryComponent() ? 0 : pParent->getGraphicsView();
  initialize();
  setAcceptHoverEvents(true);
  getClassInheritedComponents(false, true);
  parseAnnotationString(annotation);
  mpTransformation = new Transformation(StringHandler::Icon);
  mpTransformation->parseTransformationString(transformationString, boundingRect().width(), boundingRect().height());
  setTransform(mpTransformation->getTransformationMatrix());
  setToolTip(QString("<b>").append(mClassName).append("</b> <i>").append(mName).append("</i>"));
  // if type is connector and component is not a library component and not a system library class.
  bool isSystemLibrary = mpGraphicsView ? mpGraphicsView->getModelWidget()->getLibraryTreeNode()->isSystemLibrary() : false;
  if (mType == StringHandler::Connector && !isLibraryComponent() && !isSystemLibrary)
    connect(this, SIGNAL(componentClicked(Component*)), mpGraphicsView, SLOT(addConnection(Component*)));
}

/* Used for Library Component */
Component::Component(QString annotation, QString className, OMCProxy *pOMCProxy, Component *pParent)
  : QGraphicsItem(pParent), mName(className), mClassName(className), mpParentComponent(pParent)
{
  mIsLibraryComponent = true;
  mIsInheritedComponent = false;
  mInheritedClassName = "";
  mComponentType = Component::Root;
  mpGraphicsView = 0;
  initialize();
  mpParentComponent = pParent;
  mpComponentInfo = 0;
  mpOMCProxy = pOMCProxy;
  mpTransformation = 0;
  // parse the annotation string
  getClassInheritedComponents(true);
  parseAnnotationString(annotation);
  getClassComponents();
}

Component::~Component()
{
  if (mpCoOrdinateSystem) delete mpCoOrdinateSystem;
  if (mpComponentInfo) delete mpComponentInfo;
  if (mpTransformation) delete mpTransformation;
}

void Component::initialize()
{
  // set the coOrdinate System
  mpCoOrdinateSystem = new CoOrdinateSystem;
  QList<QPointF> extent;
  qreal left = -100;
  qreal bottom = -100;
  qreal right = 100;
  qreal top = 100;
  extent << QPointF(left, bottom) << QPointF(right, top);
  mpCoOrdinateSystem->setExtent(extent);
  if (mpGraphicsView)
  {
    mpCoOrdinateSystem->setPreserveAspectRatio(mpGraphicsView->getCoOrdinateSystem()->getPreserveAspectRatio());
    mpCoOrdinateSystem->setInitialScale(mpGraphicsView->getCoOrdinateSystem()->getInitialScale());
  }
  else
  {
    mpCoOrdinateSystem->setPreserveAspectRatio(true);
    mpCoOrdinateSystem->setInitialScale(0.1);
  }
  mpCoOrdinateSystem->setGrid(QPointF(2, 2));
  //Construct the temporary polygon that is shown when scaling
  mpResizerRectangle = new QGraphicsRectItem;
  mpResizerRectangle->setZValue(3000);  // set to a very high value
  if (mpGraphicsView) mpGraphicsView->scene()->addItem(mpResizerRectangle);
  QPen pen;
  pen.setStyle(Qt::DotLine);
  pen.setColor(Qt::transparent);
  mpResizerRectangle->setPen(pen);
  setOldPosition(QPointF(0, 0));
}

bool Component::isLibraryComponent()
{
  return mIsLibraryComponent;
}

bool Component::isInheritedComponent()
{
  return mIsInheritedComponent;
}

QString Component::getInheritedClassName()
{
  return mInheritedClassName;
}

void Component::getClassInheritedComponents(bool isRootComponent, bool isPortComponent)
{
  // read the component inheritance
  int inheritanceCount = mpOMCProxy->getInheritanceCount(mClassName);
  for(int i = 1 ; i <= inheritanceCount ; i++)
  {
    QString inheritedClass = mpOMCProxy->getNthInheritedClass(mClassName, i);
    // avoid cycles
    if (inheritedClass.compare(mClassName) == 0)
      return;
    // If the inherited class is one of the builtin type such as Real we can
    // stop here, because the class can not contain any components, etc.
    if (mpOMCProxy->isBuiltinType(inheritedClass))
      return;
    // get the inherited class annotation
    StringHandler::ModelicaClasses type = mpOMCProxy->getClassRestriction(inheritedClass);
    QString annotationString;
    if (isLibraryComponent() || !isRootComponent)
      annotationString = mpOMCProxy->getIconAnnotation(inheritedClass);
    else if (type == StringHandler::Connector && mpGraphicsView->getViewType() == StringHandler::Diagram)
      annotationString = mpOMCProxy->getDiagramAnnotation(inheritedClass);
    else
      annotationString = mpOMCProxy->getIconAnnotation(inheritedClass);
    Component *pInheritedComponent;
    pInheritedComponent  = new Component(annotationString, inheritedClass, type, this);
    /* if component is the port component and it has inherited components then stack its inherited components behind it. */
    if (isPortComponent)
      pInheritedComponent->setFlag(QGraphicsItem::ItemStacksBehindParent);
    mpInheritanceList.append(pInheritedComponent);
  }
}

void Component::parseAnnotationString(QString annotation)
{
  // parse the annotation string
  annotation = StringHandler::removeFirstLastCurlBrackets(annotation);
  if (annotation.isEmpty())
    return;
  QStringList list = StringHandler::getStrings(annotation);
  if (list.size() < 4)
    return;
  // read the coordinate system
  qreal left = qMin(list.at(0).toFloat(), list.at(2).toFloat());
  qreal bottom = qMin(list.at(1).toFloat(), list.at(3).toFloat());
  qreal right = qMax(list.at(0).toFloat(), list.at(2).toFloat());
  qreal top = qMax(list.at(1).toFloat(), list.at(3).toFloat());
  QList<QPointF> extent;
  extent << QPointF(left, bottom) << QPointF(right, top);
  mpCoOrdinateSystem->setExtent(extent);
  // if the list is less that 5 then return
  if (list.size() < 8)
    return;
  // read aspectratio, scale, grid
  //! @note Don't get the preserAspectRatio and InitialScale. Use the values defined for the layer.
  //  mpCoOrdinateSystem->setPreserveAspectRatio(list.at(4).contains("true"));
  //  mpCoOrdinateSystem->setInitialScale(list.at(5).toFloat());
  qreal horizontal = list.at(6).toFloat();
  qreal vertical = list.at(7).toFloat();
  mpCoOrdinateSystem->setGrid(QPointF(horizontal, vertical));
  // read the shapes
  if (list.size() < 9)
    return;
  QStringList shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(8)), '(', ')');
  // Now parse the shapes available in list
  foreach (QString shape, shapesList)
  {
    shape = StringHandler::removeFirstLastCurlBrackets(shape);
    if (shape.startsWith("Line"))
    {
      shape = shape.mid(QString("Line").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      LineAnnotation *pLineAnnotation = new LineAnnotation(shape, this);
      mpShapesList.append(pLineAnnotation);
    }
    else if (shape.startsWith("Polygon"))
    {
      shape = shape.mid(QString("Polygon").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      PolygonAnnotation *pPolygonAnnotation = new PolygonAnnotation(shape, this);
      mpShapesList.append(pPolygonAnnotation);
    }
    else if (shape.startsWith("Rectangle"))
    {
      shape = shape.mid(QString("Rectangle").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      RectangleAnnotation *pRectangleAnnotation = new RectangleAnnotation(shape, this);
      mpShapesList.append(pRectangleAnnotation);
    }
    else if (shape.startsWith("Ellipse"))
    {
      shape = shape.mid(QString("Ellipse").length());
      shape = StringHandler::removeFirstLastBrackets(shape);
      EllipseAnnotation *pEllipseAnnotation = new EllipseAnnotation(shape, this);
      mpShapesList.append(pEllipseAnnotation);
    }
    else if (shape.startsWith("Text"))
    {
      QString textShapeAnnotation = shape.mid(QString("Text").length());
      textShapeAnnotation = StringHandler::removeFirstLastBrackets(textShapeAnnotation);
      //! @note We don't show text annotation that contains % for Library Icons. Only static text for functions are shown.
      if (isLibraryComponent())
      {
        if (mType != StringHandler::Function)
          continue;
        QStringList list = StringHandler::getStrings(textShapeAnnotation);
        if (list.size() < 11)
          continue;
        if (list.at(9).contains("%"))
          continue;
      }
      TextAnnotation *pTextAnnotation = new TextAnnotation(shape, this);
      mpShapesList.append(pTextAnnotation);
    }
    else if (shape.startsWith("Bitmap"))
    {
      //! @note No Bitmaps for library icons.
      if (!isLibraryComponent())
      {
        shape = shape.mid(QString("Bitmap").length());
        shape = StringHandler::removeFirstLastBrackets(shape);
        BitmapAnnotation *pBitmapAnnotation = new BitmapAnnotation(shape, this);
        mpShapesList.append(pBitmapAnnotation);
      }
    }
  }
}

void Component::getClassComponents()
{
  foreach (Component *pInheritedComponent, mpInheritanceList)
  {
    pInheritedComponent->getClassComponents();
  }
  // get components
  QList<ComponentInfo*> componentInfoList = mpOMCProxy->getComponents(mClassName);
  if (componentInfoList.isEmpty())
    return;
  QStringList componentsAnnotations = mpOMCProxy->getComponentAnnotations(mClassName);
  int i = 0;
  foreach (ComponentInfo *pComponentInfo, componentInfoList)
  {
    // just to be on safe-side.
    if (componentsAnnotations.size() <= i)
      continue;
    // if component is protected we don't show it in the icon layer.
    if (componentsAnnotations.at(i).toLower().contains("error") || pComponentInfo->getProtected() ||
        mpOMCProxy->isBuiltinType(pComponentInfo->getClassName()))
    {
      i++;
      continue;
    }
    if (StringHandler::removeFirstLastCurlBrackets(componentsAnnotations.at(i)).length() > 0)
    {
      if (mpOMCProxy->isWhat(StringHandler::Connector, pComponentInfo->getClassName()))
      {
        QString result = mpOMCProxy->getIconAnnotation(pComponentInfo->getClassName());
        Component *pComponent = new Component(result, componentsAnnotations.at(i), pComponentInfo, StringHandler::Connector,
                                              getRootParentComponent());
        mpComponentsList.append(pComponent);
      }
    }
    i++;
  }
}

bool Component::canUseDefaultAnnotation(Component *pComponent)
{
  bool draw = false;
  if (pComponent->mpShapesList.isEmpty())
    draw = true;
  else
    return false;
  // check components list
  foreach (Component *pChildComponent, pComponent->mpComponentsList)
  {
    draw = canUseDefaultAnnotation(pChildComponent);
    if (!draw)
      return draw;    // return whenever we get false
  }
  // check inherited components list
  foreach (Component *pInheritedComponent, pComponent->mpInheritanceList)
  {
    draw = canUseDefaultAnnotation(pInheritedComponent);
    if (!draw)
      return draw;    // return whenever we get false
  }
  return draw;
}

void Component::createActions()
{
  // Parameters Action
  mpParametersAction = new QAction(Helper::parameters, mpGraphicsView);
  mpParametersAction->setStatusTip(tr("Shows the component parameters"));
  connect(mpParametersAction, SIGNAL(triggered()), SLOT(showParameters()));
  // Attributes Action
  mpAttributesAction = new QAction(Helper::attributes, mpGraphicsView);
  mpAttributesAction->setStatusTip(tr("Shows the component attributes"));
  connect(mpAttributesAction, SIGNAL(triggered()), SLOT(showAttributes()));
  // View Class Action
  mpViewClassAction = new QAction(QIcon(":/Resources/icons/model.png"), Helper::viewClass, mpGraphicsView);
  mpViewClassAction->setStatusTip(Helper::viewClassTip);
  connect(mpViewClassAction, SIGNAL(triggered()), SLOT(viewClass()));
  // View Documentation Action
  mpViewDocumentationAction = new QAction(QIcon(":/Resources/icons/info-icon.png"), Helper::viewDocumentation, mpGraphicsView);
  mpViewDocumentationAction->setStatusTip(Helper::viewDocumentationTip);
  connect(mpViewDocumentationAction, SIGNAL(triggered()), SLOT(viewDocumentation()));
}

void Component::createResizerItems()
{
  bool isSystemLibrary = mpGraphicsView->getModelWidget()->getLibraryTreeNode()->isSystemLibrary();
  qreal x1, y1, x2, y2;
  getResizerItemsPositions(&x1, &y1, &x2, &y2);
  //Bottom left resizer
  mpBottomLeftResizerItem = new ResizerItem(this);
  mpBottomLeftResizerItem->setPos(mapFromScene(x1, y1));
  mpBottomLeftResizerItem->setResizePosition(ResizerItem::BottomLeft);
  connect(mpBottomLeftResizerItem, SIGNAL(resizerItemPressed(ResizerItem*)), SLOT(prepareResizeComponent(ResizerItem*)));
  connect(mpBottomLeftResizerItem, SIGNAL(resizerItemMoved(int,QPointF)), SLOT(resizeComponent(int,QPointF)));
  connect(mpBottomLeftResizerItem, SIGNAL(resizerItemReleased()), SLOT(finishResizeComponent()));
  connect(mpBottomLeftResizerItem, SIGNAL(resizerItemPositionChanged()), SIGNAL(componentTransformHasChanged()));
  mpBottomLeftResizerItem->blockSignals(isSystemLibrary || isInheritedComponent());
  //Top left resizer
  mpTopLeftResizerItem = new ResizerItem(this);
  mpTopLeftResizerItem->setPos(mapFromScene(x1, y2));
  mpTopLeftResizerItem->setResizePosition(ResizerItem::TopLeft);
  connect(mpTopLeftResizerItem, SIGNAL(resizerItemPressed(ResizerItem*)), SLOT(prepareResizeComponent(ResizerItem*)));
  connect(mpTopLeftResizerItem, SIGNAL(resizerItemMoved(int,QPointF)), SLOT(resizeComponent(int,QPointF)));
  connect(mpTopLeftResizerItem, SIGNAL(resizerItemReleased()), SLOT(finishResizeComponent()));
  connect(mpTopLeftResizerItem, SIGNAL(resizerItemPositionChanged()), SIGNAL(componentTransformHasChanged()));
  mpTopLeftResizerItem->blockSignals(isSystemLibrary || isInheritedComponent());
  //Top Right resizer
  mpTopRightResizerItem = new ResizerItem(this);
  mpTopRightResizerItem->setPos(mapFromScene(x2, y2));
  mpTopRightResizerItem->setResizePosition(ResizerItem::TopRight);
  connect(mpTopRightResizerItem, SIGNAL(resizerItemPressed(ResizerItem*)), SLOT(prepareResizeComponent(ResizerItem*)));
  connect(mpTopRightResizerItem, SIGNAL(resizerItemMoved(int,QPointF)), SLOT(resizeComponent(int,QPointF)));
  connect(mpTopRightResizerItem, SIGNAL(resizerItemReleased()), SLOT(finishResizeComponent()));
  connect(mpTopRightResizerItem, SIGNAL(resizerItemPositionChanged()), SIGNAL(componentTransformHasChanged()));
  mpTopRightResizerItem->blockSignals(isSystemLibrary || isInheritedComponent());
  //Bottom Right resizer
  mpBottomRightResizerItem = new ResizerItem(this);
  mpBottomRightResizerItem->setPos(mapFromScene(x2, y1));
  mpBottomRightResizerItem->setResizePosition(ResizerItem::BottomRight);
  connect(mpBottomRightResizerItem, SIGNAL(resizerItemPressed(ResizerItem*)), SLOT(prepareResizeComponent(ResizerItem*)));
  connect(mpBottomRightResizerItem, SIGNAL(resizerItemMoved(int,QPointF)), SLOT(resizeComponent(int,QPointF)));
  connect(mpBottomRightResizerItem, SIGNAL(resizerItemReleased()), SLOT(finishResizeComponent()));
  connect(mpBottomRightResizerItem, SIGNAL(resizerItemPositionChanged()), SIGNAL(componentTransformHasChanged()));
  mpBottomRightResizerItem->blockSignals(isSystemLibrary || isInheritedComponent());
}

void Component::getResizerItemsPositions(qreal *x1, qreal *y1, qreal *x2, qreal *y2)
{
  qreal x11, y11, x22, y22;
  sceneBoundingRect().getCoords(&x11, &y11, &x22, &y22);
  if (x11 < x22)
  {
    *x1 = x11;
    *x2 = x22;
  }
  else
  {
    *x1 = x22;
    *x2 = x11;
  }
  if (y11 < y22)
  {
    *y1 = y11;
    *y2 = y22;
  }
  else
  {
    *y1 = y22;
    *y2 = y11;
  }
}

void Component::showResizerItems()
{
  qreal x1, y1, x2, y2;
  getResizerItemsPositions(&x1, &y1, &x2, &y2);
  //Bottom left resizer
  mpBottomLeftResizerItem->setPos(mapFromScene(x1, y1));
  mpBottomLeftResizerItem->setActive();
  //Top left resizer
  mpTopLeftResizerItem->setPos(mapFromScene(x1, y2));
  mpTopLeftResizerItem->setActive();
  //Top Right resizer
  mpTopRightResizerItem->setPos(mapFromScene(x2, y2));
  mpTopRightResizerItem->setActive();
  //Bottom Right resizer
  mpBottomRightResizerItem->setPos(mapFromScene(x2, y1));
  mpBottomRightResizerItem->setActive();
}

void Component::hideResizerItems()
{
  mpBottomLeftResizerItem->setPassive();
  mpTopLeftResizerItem->setPassive();
  mpTopRightResizerItem->setPassive();
  mpBottomRightResizerItem->setPassive();
}

QRectF Component::boundingRect() const
{
  qreal left = mpCoOrdinateSystem->getExtent().at(0).x();
  qreal bottom = mpCoOrdinateSystem->getExtent().at(0).y();
  qreal right = mpCoOrdinateSystem->getExtent().at(1).x();
  qreal top = mpCoOrdinateSystem->getExtent().at(1).y();
  return QRectF(left, bottom, fabs(left - right), fabs(bottom - top));
}

void Component::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(painter);
  Q_UNUSED(option);
  Q_UNUSED(widget);
  if (mpTransformation)
    setVisible(mpTransformation->getVisible());
}

QString Component::getName()
{
  return mName;
}

QString Component::getClassName()
{
  return mClassName;
}

StringHandler::ModelicaClasses Component::getType()
{
  return mType;
}

OMCProxy* Component::getOMCProxy()
{
  return mpOMCProxy;
}

GraphicsView* Component::getGraphicsView()
{
  return mpGraphicsView;
}

Component* Component::getParentComponent()
{
  return mpParentComponent;
}

Component* Component::getRootParentComponent()
{
  Component *pComponent;
  pComponent = this;
  while (pComponent->mpParentComponent)
    pComponent = pComponent->mpParentComponent;
  return pComponent;
}

Transformation* Component::getTransformation()
{
  return mpTransformation;
}

QAction* Component::getParametersAction()
{
  return mpParametersAction;
}

QAction* Component::getAttributesAction()
{
  return mpAttributesAction;
}

QAction* Component::getViewClassAction()
{
  return mpViewClassAction;
}

QAction* Component::getViewDocumentationAction()
{
  return mpViewDocumentationAction;
}

ComponentInfo* Component::getComponentInfo()
{
  return mpComponentInfo;
}

QList<Component*> Component::getInheritanceList()
{
  return mpInheritanceList;
}

QList<ShapeAnnotation*> Component::getShapesList()
{
  return mpShapesList;
}

QList<Component*> Component::getComponentsList()
{
  return mpComponentsList;
}

void Component::setOldPosition(QPointF oldPosition)
{
  mOldPosition = oldPosition;
}

QPointF Component::getOldPosition()
{
  return mOldPosition;
}

void Component::setComponentFlags()
{
  // set the item flags
  /* Set the ItemIsMovable flag on component if the class is not a system library class OR component is not an inherited component. */
  if (!mpGraphicsView->getModelWidget()->getLibraryTreeNode()->isSystemLibrary() && !isInheritedComponent())
  {
    if(!flags().testFlag((QGraphicsItem::ItemIsMovable)))
      setFlag(QGraphicsItem::ItemIsMovable);
  }
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

void Component::getExtents(QPointF *pExtent1, QPointF *pExtent2)
{
  qreal x1, y1, x2, y2;
  boundingRect().getCoords(&x1, &y1, &x2, &y2);
  pExtent1->setX(mapToScene(x1, y1).x() - scenePos().x());
  pExtent1->setY(mapToScene(x1, y1).y() - scenePos().y());
  pExtent2->setX(mapToScene(x2, y2).x() - scenePos().x());
  pExtent2->setY(mapToScene(x2, y2).y() - scenePos().y());
  if (mpTransformation->getFlipHorizontal())
  {
    pExtent1->setX(fabs(pExtent1->x()));
    pExtent2->setX(-(fabs(pExtent2->x())));
  }
  else
  {
    pExtent1->setX(-(fabs(pExtent1->x())));
    pExtent2->setX(fabs(pExtent2->x()));
  }
  if (mpTransformation->getFlipVertical())
  {
    pExtent1->setY(fabs(pExtent1->y()));
    pExtent2->setY(-(fabs(pExtent2->y())));
  }
  else
  {
    pExtent1->setY(-(fabs(pExtent1->y())));
    pExtent2->setY(fabs(pExtent2->y()));
  }
}

QString Component::getTransformationAnnotationString()
{
  QString annotationString;
  if (mpGraphicsView->getViewType() == StringHandler::Icon)
    annotationString.append("iconTransformation=transformation(origin=");
  else if (mpGraphicsView->getViewType() == StringHandler::Diagram)
    annotationString.append("transformation=transformation(origin=");
  // add the icon origin
  annotationString.append("{").append(QString::number(scenePos().x())).append(",");
  annotationString.append(QString::number(scenePos().y())).append("}, ");
  // add extent points
  QPointF extent1, extent2;
  getExtents(&extent1, &extent2);
  annotationString.append("extent={").append("{").append(QString::number(extent1.x()));
  annotationString.append(",").append(QString::number(extent1.y())).append("},");
  annotationString.append("{").append(QString::number(extent2.x())).append(",");
  annotationString.append(QString::number(extent2.y())).append("}}, ");
  // add icon rotation
  annotationString.append("rotation=").append(QString::number(mpTransformation->getRotateAngle())).append(")");
  return annotationString;
}

QString Component::getPlacementAnnotation()
{
  // create the placement annotation string
  QString placementAnnotationString = "annotate=Placement(";
  if (mpTransformation)
    placementAnnotationString.append("visible=").append(mpTransformation->getVisible() ? "true" : "false");
  if (mType == StringHandler::Connector)
  {
    if (mpGraphicsView->getViewType() == StringHandler::Icon)
    {
      // first get the component from diagram view and get the transformations
      Component *pComponent;
      pComponent = mpGraphicsView->getModelWidget()->getDiagramGraphicsView()->getComponentObject(getName());
      if (pComponent)
        placementAnnotationString.append(", ").append(pComponent->getTransformationAnnotationString());
      // then get the icon transformations
      placementAnnotationString.append(", ").append(getTransformationAnnotationString());
    }
    else if (mpGraphicsView->getViewType() == StringHandler::Diagram)
    {
      // first get the component from diagram view and get the transformations
      placementAnnotationString.append(", ").append(getTransformationAnnotationString());
      // then get the icon transformations
      Component *pComponent;
      pComponent = mpGraphicsView->getModelWidget()->getIconGraphicsView()->getComponentObject(getName());
      if (pComponent)
        placementAnnotationString.append(", ").append(pComponent->getTransformationAnnotationString());
    }
  }
  else
  {
    placementAnnotationString.append(", ").append(getTransformationAnnotationString());
  }
  placementAnnotationString.append(")");
  return placementAnnotationString;
}

void Component::applyRotation(qreal angle)
{
  mpTransformation->setRotateAngle(angle);
  setTransform(mpTransformation->getTransformationMatrix());
  showResizerItems();
}

void Component::addConnectionDetails(LineAnnotation *pConnectorLineAnnotation)
{
  // handle component position, rotation and scale changes
  connect(this, SIGNAL(componentTransformChange()), pConnectorLineAnnotation, SLOT(handleComponentMoved()));
  connect(this, SIGNAL(componentRotationChange()), pConnectorLineAnnotation, SLOT(handleComponentRotation()));
  connect(this, SIGNAL(componentTransformHasChanged()), pConnectorLineAnnotation, SLOT(updateConnectionAnnotation()));
}

void Component::updateConnection()
{
  emit componentTransformHasChanged();
}

void Component::componentNameHasChanged(QString newName)
{
  mName = newName;
  setToolTip(QString("<b>").append(mClassName).append("</b> <i>").append(mName).append("</i>"));
  emit componentDisplayTextChanged();
}

void Component::componentParameterHasChanged()
{
  emit componentDisplayTextChanged();
}

/*!
  Creates an object of ComponentParameters and uses it to read the parameters of the component.\n
  Returns the parameter string which can be either R=%R or %R.
  \param parameterString - the parameter string to look for.
  \return the parameter string with value.
  */
QString Component::getParameterDisplayString(QString parameterName)
{
  /*
    Use the ComponentParameters class to get the parameters list and then check the parameterString against them.
    Don't call show of the ComponentParameters class.
    */
  MainWindow *pMainWindow = mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow();
  ComponentParameters *pComponentParameters = new ComponentParameters(false, this, pMainWindow);
  QList<Parameter*> parametersList = pComponentParameters->getParametersList();
  QString result;
  foreach (Parameter *pParameter, parametersList)
  {
    if (pParameter->getNameLabel()->text().compare(parameterName) == 0)
    {
      result = pParameter->getValueTextBox()->text();
      break;
    }
  }
  pComponentParameters->deleteLater();
  return result;
}

void Component::duplicateHelper(GraphicsView *pGraphicsView)
{
  Component *pComponent = pGraphicsView->getComponentList().last();
  if (pComponent)
  {
    /* set the original component transformation to the duplicated one. */
    pComponent->getTransformation()->setExtent1(mpTransformation->getExtent1());
    pComponent->getTransformation()->setExtent2(mpTransformation->getExtent2());
    pComponent->getTransformation()->setRotateAngle(mpTransformation->getRotateAngle());
    pComponent->setTransform(pComponent->getTransformation()->getTransformationMatrix());
    /* get the original component attributes */
    QString className = pGraphicsView->getModelWidget()->getLibraryTreeNode()->getNameStructure();
    QList<ComponentInfo*> componentInfoList = mpOMCProxy->getComponents(className);
    foreach (ComponentInfo *pComponentInfo, componentInfoList)
    {
      if (pComponentInfo->getName() == mName)
      {
        QString isFinal = pComponentInfo->getFinal() ? "true" : "false";
        QString isFlow = pComponentInfo->getFlow() ? "true" : "false";
        QString isProtected = pComponentInfo->getProtected() ? "true" : "false";
        QString isReplaceAble = pComponentInfo->getReplaceable() ? "true" : "false";
        QString variability = pComponentInfo->getVariablity();
        QString isInner = pComponentInfo->getInner() ? "true" : "false";
        QString isOuter = pComponentInfo->getOuter() ? "true" : "false";
        QString causality = pComponentInfo->getCasuality();
        // update duplicated component attributes
        if (!mpOMCProxy->setComponentProperties(className, pComponent->getName(), isFinal, isFlow, isProtected, isReplaceAble,
                                                variability, isInner, isOuter, causality))
        {
          QMessageBox::critical(pGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow(),
                                QString(Helper::applicationName).append(" - ").append(Helper::error), mpOMCProxy->getResult(),
                                Helper::ok);
          mpOMCProxy->printMessagesStringInternal();
        }
        break;
      }
    }
    /* get original component modifiers and apply them to duplicated one. */
    QStringList componentModifiersList = mpOMCProxy->getComponentModifierNames(className, mName);
    bool modifierValueChanged = false;
    foreach (QString componentModifier, componentModifiersList)
    {
      QString originalModifierName = QString(mName).append(".").append(componentModifier);
      QString duplicatedModifierName = QString(pComponent->getName()).append(".").append(componentModifier);
      if (mpOMCProxy->setComponentModifierValue(className, duplicatedModifierName,
                                                mpOMCProxy->getComponentModifierValue(className, originalModifierName).prepend("=")))
        modifierValueChanged = true;

    }
    if (modifierValueChanged)
    {
      pComponent->componentParameterHasChanged();
      pComponent->update();
    }
    pGraphicsView->getModelWidget()->setModelModified();
  }
}

void Component::updatePlacementAnnotation()
{
  // Add component annotation.
  mpOMCProxy->updateComponent(mName, mClassName, mpGraphicsView->getModelWidget()->getLibraryTreeNode()->getNameStructure(),
                              getPlacementAnnotation());
  // set the model modified
  mpGraphicsView->getModelWidget()->setModelModified();
  /* When something is changed in the icon layer then update the LibraryTreeNode in the Library Browser */
  if (mpGraphicsView->getViewType() == StringHandler::Icon)
  {
    MainWindow *pMainWindow = mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow();
    pMainWindow->getLibraryTreeWidget()->loadLibraryComponent(mpGraphicsView->getModelWidget()->getLibraryTreeNode());
  }
}

void Component::prepareResizeComponent(ResizerItem *pResizerItem)
{
  mpSelectedResizerItem = pResizerItem;
  mTransform = transform();
  mSceneBoundingRect = sceneBoundingRect();
  mTransformationStartPosition = scenePos();
  mPivotPoint = sceneBoundingRect().center();
  if (mpSelectedResizerItem->getResizePosition() == ResizerItem::BottomLeft)
  {
    mTransformationStartPosition = sceneBoundingRect().topLeft();
    mPivotPoint = sceneBoundingRect().bottomRight();
  }
  else if (mpSelectedResizerItem->getResizePosition() == ResizerItem::TopLeft)
  {
    mTransformationStartPosition = sceneBoundingRect().bottomLeft();
    mPivotPoint = sceneBoundingRect().topRight();
  }
  else if (mpSelectedResizerItem->getResizePosition() == ResizerItem::TopRight)
  {
    mTransformationStartPosition = sceneBoundingRect().bottomRight();
    mPivotPoint = sceneBoundingRect().topLeft();
  }
  else if (mpSelectedResizerItem->getResizePosition() == ResizerItem::BottomRight)
  {
    mTransformationStartPosition = sceneBoundingRect().topRight();
    mPivotPoint = sceneBoundingRect().bottomLeft();
  }
  mpResizerRectangle->setRect(boundingRect()); //Sets the current item to the temporary rect
  mpResizerRectangle->setTransform(transform()); //Set the same matrix of this item to the temporary item
  mpResizerRectangle->setPos(pos());
}

void Component::resizeComponent(int index, QPointF newPosition)
{
  Q_UNUSED(index);
  float xDistance; //X distance between the current position of the mouse and the starting position mouse
  float yDistance; //Y distance between the current position of the mouse and the starting position mouse
  //Calculates the X distance
  xDistance = newPosition.x() - mTransformationStartPosition.x();
  if (mTransformationStartPosition.x() < mPivotPoint.x()) //If the starting point is on the negative side of the X plane we do an inverse of the value
  {
    xDistance = xDistance * -1;
  }
  //Calculates the Y distance
  yDistance = newPosition.y() - mTransformationStartPosition.y();
  if (mTransformationStartPosition.y() < mPivotPoint.y()) //If the starting point is on the negative side of the Y plane we do an inverse of the value
  {
    yDistance = yDistance * -1;
  }
  //Calculate the factors by dividing the distances againts the original size of this container
  mXFactor = 0;
  mYFactor = 0;
  mXFactor = xDistance / mSceneBoundingRect.width();
  mYFactor = yDistance / mSceneBoundingRect.height();
  mXFactor = 1 + mXFactor;
  mYFactor = 1 + mYFactor;
  // if preserveAspectRatio is true then resize equally
  if (mpGraphicsView->getCoOrdinateSystem()->getPreserveAspectRatio())
  {
    qreal factor = qMax(fabs(mXFactor), fabs(mYFactor));
    mXFactor = mXFactor < 0 ? mXFactor = factor * -1 : mXFactor = factor;
    mYFactor = mYFactor < 0 ? mYFactor = factor * -1 : mYFactor = factor;
  }
  // Apply the transformation to the temporary polygon using the new scaling factors
  QPointF pivot = mPivotPoint - pos();
  //Creates a temporaty transformation
  QTransform tmpTransform = QTransform().translate(pivot.x(), pivot.y()).rotate(0)
      .scale(mXFactor, mYFactor)
      .translate(-pivot.x(), -pivot.y());
  mpResizerRectangle->setTransform(mTransform * tmpTransform); //Multiplies the previous matrix * the temporary
  setTransform(mTransform * tmpTransform);
  emit componentTransformChange();
}

void Component::finishResizeComponent()
{
  qreal x1, y1, x2, y2;
  boundingRect().getCoords(&x1, &y1, &x2, &y2);
  QPointF extent1, extent2;
  extent1.setX(mapToScene(x1, y1).x() - scenePos().x());
  extent1.setY(mapToScene(x1, y1).y() - scenePos().y());
  extent2.setX(mapToScene(x2, y2).x() - scenePos().x());
  extent2.setY(mapToScene(x2, y2).y() - scenePos().y());
  if (mXFactor < 0)
  {
    if (!mpTransformation->getFlipHorizontal())
    {
      extent1.setX(fabs(extent1.x()));
      extent2.setX(-(fabs(extent2.x())));
    }
    else
    {
      extent1.setX(-(fabs(extent1.x())));
      extent2.setX(fabs(extent2.x()));
    }
  }
  else
  {
    if (!mpTransformation->getFlipHorizontal())
    {
      extent1.setX(-(fabs(extent1.x())));
      extent2.setX(fabs(extent2.x()));
    }
    else
    {
      extent1.setX(fabs(extent1.x()));
      extent2.setX(-(fabs(extent2.x())));
    }
  }
  if (mYFactor < 0)
  {
    if (!mpTransformation->getFlipVertical())
    {
      extent1.setY(fabs(extent1.y()));
      extent2.setY(-(fabs(extent2.y())));
    }
    else
    {
      extent1.setY(-(fabs(extent1.y())));
      extent2.setY(fabs(extent2.y()));
    }
  }
  else
  {
    if (!mpTransformation->getFlipVertical())
    {
      extent1.setY(-(fabs(extent1.y())));
      extent2.setY(fabs(extent2.y()));
    }
    else
    {
      extent1.setY(fabs(extent1.y()));
      extent2.setY(-(fabs(extent2.y())));
    }
  }
  mpTransformation->setOrigin(QPointF(transform().m31(), transform().m32())); //Sets this item position as the temporary polygon
  mpTransformation->setExtent1(extent1);
  mpTransformation->setExtent2(extent2);
  setTransform(mpTransformation->getTransformationMatrix());
  if (isSelected())
    showResizerItems();
  else
    setSelected(true);
}

void Component::deleteMe()
{
  // delete the component from model
  mpGraphicsView->deleteComponentObject(this);
  deleteLater();
  // make the model modified
  mpGraphicsView->getModelWidget()->setModelModified();
  /* When something is deleted from the icon layer then update the LibraryTreeNode in the Library Browser */
  if (mpGraphicsView->getViewType() == StringHandler::Icon)
  {
    MainWindow *pMainWindow = mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow();
    pMainWindow->getLibraryTreeWidget()->loadLibraryComponent(mpGraphicsView->getModelWidget()->getLibraryTreeNode());
  }
}

void Component::duplicate()
{
  QPointF gridStep(mpGraphicsView->getCoOrdinateSystem()->getHorizontalGridStep(),
                   mpGraphicsView->getCoOrdinateSystem()->getVerticalGridStep());
  if (mpGraphicsView->addComponent(mClassName, scenePos() + gridStep))
  {
    if (mType == StringHandler::Connector)
    {
      if (mpGraphicsView->getViewType() == StringHandler::Diagram)
      {
        duplicateHelper(mpGraphicsView);
        duplicateHelper(mpGraphicsView->getModelWidget()->getIconGraphicsView());
      }
      else
      {
        duplicateHelper(mpGraphicsView);
        duplicateHelper(mpGraphicsView->getModelWidget()->getDiagramGraphicsView());
      }
    }
    else
    {
      duplicateHelper(mpGraphicsView);
    }
  }
}

void Component::rotateClockwise()
{
  qreal oldRotation = StringHandler::getNormalizedAngle(mpTransformation->getRotateAngle());
  qreal rotateIncrement = -90;
  qreal angle = oldRotation + rotateIncrement;
  applyRotation(angle);
  emit componentRotationChange();
}

void Component::rotateAntiClockwise()
{
  qreal oldRotation = StringHandler::getNormalizedAngle(mpTransformation->getRotateAngle());
  qreal rotateIncrement = 90;
  qreal angle = oldRotation + rotateIncrement;
  applyRotation(angle);
  emit componentRotationChange();
}

void Component::flipHorizontal()
{
  QPointF extent1, extent2;
  getExtents(&extent1, &extent2);
  qreal angle = StringHandler::getNormalizedAngle(mpTransformation->getRotateAngle());
  bool flip = false;
  if ((angle >= 0 && angle < 90) || (angle >= 180 && angle < 270))
  {
    mpTransformation->setExtent1(QPointF(extent2.x(), extent1.y()));
    mpTransformation->setExtent2(QPointF(extent1.x(), extent2.y()));
    flip = true;
  }
  else if ((angle >= 90 && angle < 180) || (angle >= 270 && angle < 360))
  {
    mpTransformation->setExtent1(QPointF(extent1.x(), extent2.y()));
    mpTransformation->setExtent2(QPointF(extent2.x(), extent1.y()));
    flip = true;
  }
  if (flip)
  {
    setTransform(mpTransformation->getTransformationMatrix());
    emit componentRotationChange();
    emit componentTransformHasChanged();
    showResizerItems();
  }
}

void Component::flipVertical()
{
  QPointF extent1, extent2;
  getExtents(&extent1, &extent2);
  qreal angle = StringHandler::getNormalizedAngle(mpTransformation->getRotateAngle());
  bool flip = false;
  if ((angle >= 0 && angle < 90) || (angle >= 180 && angle < 270))
  {
    mpTransformation->setExtent1(QPointF(extent1.x(), extent2.y()));
    mpTransformation->setExtent2(QPointF(extent2.x(), extent1.y()));
    flip = true;
  }
  else if ((angle >= 90 && angle < 180) || (angle >= 270 && angle < 360))
  {
    mpTransformation->setExtent1(QPointF(extent2.x(), extent1.y()));
    mpTransformation->setExtent2(QPointF(extent1.x(), extent2.y()));
    flip = true;
  }
  if (flip)
  {
    setTransform(mpTransformation->getTransformationMatrix());
    emit componentRotationChange();
    emit componentTransformHasChanged();
    showResizerItems();
  }
}

/*!
  Slot that moves component upwards depending on the grid step size value
  \see moveDown()
  \see moveLeft()
  \see moveRight()
  \see moveShiftDown()
  \see moveShiftLeft()
  \see moveShiftRight()
  */
void Component::moveUp()
{
  int verticalStep = mpGraphicsView->getCoOrdinateSystem()->getVerticalGridStep();
  mpTransformation->setOrigin(QPointF(mpTransformation->getOrigin().x(), mpTransformation->getOrigin().y() + verticalStep));
  setTransform(mpTransformation->getTransformationMatrix());
  emit componentTransformChange();
}

/*!
  Slot that moves component one pixel upwards
  \see moveDown()
  \see moveLeft()
  \see moveRight()
  \see moveShiftDown()
  \see moveShiftLeft()
  \see moveShiftRight()
  */
void Component::moveShiftUp()
{
  mpTransformation->setOrigin(QPointF(mpTransformation->getOrigin().x(), mpTransformation->getOrigin().y() + 1));
  setTransform(mpTransformation->getTransformationMatrix());
  emit componentTransformChange();
}

/*!
  Slot that moves component downwards depending on the grid step size value
  \see moveUp()
  \see moveLeft()
  \see moveRight()
  \see moveShiftUp()
  \see moveShiftLeft()
  \see moveShiftRight()
  */
void Component::moveDown()
{
  int verticalStep = mpGraphicsView->getCoOrdinateSystem()->getVerticalGridStep();
  mpTransformation->setOrigin(QPointF(mpTransformation->getOrigin().x(), mpTransformation->getOrigin().y() - verticalStep));
  setTransform(mpTransformation->getTransformationMatrix());
  emit componentTransformChange();
}

/*!
  Slot that moves component one pixel downwards
  \see moveUp()
  \see moveLeft()
  \see moveRight()
  \see moveShiftUp()
  \see moveShiftLeft()
  \see moveShiftRight()
  */
void Component::moveShiftDown()
{
  mpTransformation->setOrigin(QPointF(mpTransformation->getOrigin().x(), mpTransformation->getOrigin().y() - 1));
  setTransform(mpTransformation->getTransformationMatrix());
  emit componentTransformChange();
}

/*!
  Slot that moves component leftwards depending on the grid step size
  \see moveUp()
  \see moveDown()
  \see moveRight()
  \see moveShiftUp()
  \see moveShiftDown()
  \see moveShiftRight()
  */
void Component::moveLeft()
{
  int horizontalStep = mpGraphicsView->getCoOrdinateSystem()->getHorizontalGridStep();
  mpTransformation->setOrigin(QPointF(mpTransformation->getOrigin().x() - horizontalStep, mpTransformation->getOrigin().y()));
  setTransform(mpTransformation->getTransformationMatrix());
  emit componentTransformChange();
}

/*!
  Slot that moves component one pixel leftwards
  \see moveUp()
  \see moveDown()
  \see moveRight()
  \see moveShiftUp()
  \see moveShiftDown()
  \see moveShiftRight()
  */
void Component::moveShiftLeft()
{
  mpTransformation->setOrigin(QPointF(mpTransformation->getOrigin().x() - 1, mpTransformation->getOrigin().y()));
  setTransform(mpTransformation->getTransformationMatrix());
  emit componentTransformChange();
}

/*!
  Slot that moves component rightwards depending on the grid step size
  \see moveUp()
  \see moveDown()
  \see moveLeft()
  \see moveShiftUp()
  \see moveShiftDown()
  \see moveShiftLeft()
  */
void Component::moveRight()
{
  int horizontalStep = mpGraphicsView->getCoOrdinateSystem()->getHorizontalGridStep();
  mpTransformation->setOrigin(QPointF(mpTransformation->getOrigin().x() + horizontalStep, mpTransformation->getOrigin().y()));
  setTransform(mpTransformation->getTransformationMatrix());
  emit componentTransformChange();
}

/*!
  Slot that moves component one pixel rightwards
  \see moveUp()
  \see moveDown()
  \see moveLeft()
  \see moveShiftUp()
  \see moveShiftDown()
  \see moveShiftLeft()
  */
void Component::moveShiftRight()
{
  mpTransformation->setOrigin(QPointF(mpTransformation->getOrigin().x() + 1, mpTransformation->getOrigin().y()));
  setTransform(mpTransformation->getTransformationMatrix());
  emit componentTransformChange();
}

//! Slot that opens up the component parameters dialog.
//! @see showAttributes()
void Component::showParameters()
{
  MainWindow *pMainWindow = mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow();
  ComponentParameters *pComponentParameters = new ComponentParameters(true, this, pMainWindow);
  pComponentParameters->show();
}

//! Slot that opens up the component attributes dialog.
//! @see showParameters()
void Component::showAttributes()
{
  MainWindow *pMainWindow = mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow();
  ComponentAttributes *pComponentAttributes = new ComponentAttributes(this, pMainWindow);
  pComponentAttributes->show();
}

//! Slot that opens up the component Modelica class in a new tab/window.
void Component::viewClass()
{
  mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow()->getLibraryTreeWidget()->openLibraryTreeNode(getClassName());
}

//! Slot that opens up the component Modelica class in a documentation view.
void Component::viewDocumentation()
{
  mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow()->getDocumentationWidget()->showDocumentation(getClassName());
  mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow()->getDocumentationDockWidget()->show();
}

void Component::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
  // if user is viewing the component in Icon View
  if (mpGraphicsView->getViewType() == StringHandler::Icon)
    return;
  // if component is a connector type then emit the componentClicked signal
  MainWindow *pMainWindow = mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow();
  /*
    #2236
    If a user has a connector with components that are also connectors then we need to consume the event and don't propogate it.
    So we can get the correct clicked component.
    */
  /* Do not consume the event for inherited/extends component as they don't have connection to componentClicked SIGNAL. */
  bool eventConsumed = false;
  if (event->button() == Qt::LeftButton && pMainWindow->getConnectModeAction()->isChecked() && mType == StringHandler::Connector &&
      mComponentType != Component::Extend)
  {
    emit componentClicked(this);
    eventConsumed = true;
  }
  // if we are creating the connector then make sure user can not select and move components
  if ((mpGraphicsView->isCreatingConnection()) && !mpParentComponent)
  {
    unsetComponentFlags();
    return;
  }
  // if user not creating connector then check if the item flags are active or not
  else if (!mpParentComponent)
  {
    setComponentFlags();
  }
  if (!eventConsumed)
    QGraphicsItem::mousePressEvent(event);
}

/*! Event when mouse is double clicked on a component.
 *  Shows the component properties dialog.
 */
void Component::mouseDoubleClickEvent(QGraphicsSceneMouseEvent *event)
{
  MainWindow *pMainWindow = mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow();
  if (!pMainWindow->getConnectModeAction()->isChecked())
    getRootParentComponent()->showParameters(); /* if user has double clicked on a component and not on a connector. */
  QGraphicsItem::mouseDoubleClickEvent(event);
}

//! Event when mouse cursor enters component icon.
void Component::hoverEnterEvent(QGraphicsSceneHoverEvent *event)
{
  Q_UNUSED(event);
  MainWindow *pMainWindow = mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow();
  if ((mType == StringHandler::Connector) &&
      (pMainWindow->getConnectModeAction()->isChecked()) &&
      (mpGraphicsView->getViewType() == StringHandler::Diagram) &&
      (!mpGraphicsView->getModelWidget()->getLibraryTreeNode()->isSystemLibrary()))
    QApplication::setOverrideCursor(Qt::CrossCursor);
}

//! Event when mouse cursor leaves component icon.
void Component::hoverLeaveEvent(QGraphicsSceneHoverEvent *event)
{
  Q_UNUSED(event);
  QApplication::restoreOverrideCursor();
}

void Component::contextMenuEvent(QGraphicsSceneContextMenuEvent *event)
{
  Component *pComponent = getRootParentComponent();
  if (pComponent->isSelected())
    pComponent->showResizerItems();
  else
  {
    // unselect all items
    foreach (QGraphicsItem *pItem, mpGraphicsView->items())
    {
      pItem->setSelected(false);
    }
    pComponent->setSelected(true);
  }
  QMenu menu(mpGraphicsView);
  menu.addAction(pComponent->getParametersAction());
  menu.addAction(pComponent->getAttributesAction());
  menu.addSeparator();
  menu.addAction(pComponent->getViewClassAction());
  menu.addAction(pComponent->getViewDocumentationAction());
  menu.addSeparator();
  if (pComponent->isInheritedComponent())
  {
    mpGraphicsView->getDeleteAction()->setDisabled(true);
    mpGraphicsView->getDuplicateAction()->setDisabled(true);
    mpGraphicsView->getRotateClockwiseAction()->setDisabled(true);
    mpGraphicsView->getRotateAntiClockwiseAction()->setDisabled(true);
    mpGraphicsView->getFlipHorizontalAction()->setDisabled(true);
    mpGraphicsView->getFlipVerticalAction()->setDisabled(true);
  }
  menu.addAction(mpGraphicsView->getDeleteAction());
  menu.addAction(mpGraphicsView->getDuplicateAction());
  menu.addSeparator();
  menu.addAction(mpGraphicsView->getRotateClockwiseAction());
  menu.addAction(mpGraphicsView->getRotateAntiClockwiseAction());
  menu.addAction(mpGraphicsView->getFlipHorizontalAction());
  menu.addAction(mpGraphicsView->getFlipVerticalAction());
  menu.exec(event->screenPos());
}

QVariant Component::itemChange(GraphicsItemChange change, const QVariant &value)
{
  QGraphicsItem::itemChange(change, value);
  if (change == QGraphicsItem::ItemSelectedHasChanged)
  {
    if (isSelected())
    {
      showResizerItems();
      setCursor(Qt::SizeAllCursor);
      /* Only allow manipulations on component if the class is not a system library class OR component is not an inherited component. */
      if (!mpGraphicsView->getModelWidget()->getLibraryTreeNode()->isSystemLibrary() && !isInheritedComponent())
      {
        connect(mpGraphicsView->getDeleteAction(), SIGNAL(triggered()), SLOT(deleteMe()), Qt::UniqueConnection);
        connect(mpGraphicsView->getDuplicateAction(), SIGNAL(triggered()), SLOT(duplicate()), Qt::UniqueConnection);
        connect(mpGraphicsView->getRotateClockwiseAction(), SIGNAL(triggered()), SLOT(rotateClockwise()), Qt::UniqueConnection);
        connect(mpGraphicsView->getRotateClockwiseAction(), SIGNAL(triggered()), SIGNAL(componentTransformHasChanged()), Qt::UniqueConnection);
        connect(mpGraphicsView->getRotateAntiClockwiseAction(), SIGNAL(triggered()), SLOT(rotateAntiClockwise()), Qt::UniqueConnection);
        connect(mpGraphicsView->getRotateAntiClockwiseAction(), SIGNAL(triggered()), SIGNAL(componentTransformHasChanged()), Qt::UniqueConnection);
        connect(mpGraphicsView->getFlipHorizontalAction(), SIGNAL(triggered()), SLOT(flipHorizontal()), Qt::UniqueConnection);
        connect(mpGraphicsView->getFlipVerticalAction(), SIGNAL(triggered()), SLOT(flipVertical()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressDelete()), SLOT(deleteMe()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressDuplicate()), SLOT(duplicate()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressRotateClockwise()), SLOT(rotateClockwise()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyReleaseRotateClockwise()), SIGNAL(componentTransformHasChanged()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), SLOT(rotateAntiClockwise()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyReleaseRotateAntiClockwise()), SIGNAL(componentTransformHasChanged()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressUp()), SLOT(moveUp()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyReleaseUp()), SIGNAL(componentTransformHasChanged()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressShiftUp()), SLOT(moveShiftUp()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyReleaseShiftUp()), SIGNAL(componentTransformHasChanged()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressDown()), SLOT(moveDown()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyReleaseDown()), SIGNAL(componentTransformHasChanged()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressShiftDown()), SLOT(moveShiftDown()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyReleaseShiftDown()), SIGNAL(componentTransformHasChanged()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressLeft()), SLOT(moveLeft()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyReleaseLeft()), SIGNAL(componentTransformHasChanged()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressShiftLeft()), SLOT(moveShiftLeft()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyReleaseShiftLeft()), SIGNAL(componentTransformHasChanged()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressRight()), SLOT(moveRight()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyReleaseRight()), SIGNAL(componentTransformHasChanged()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressShiftRight()), SLOT(moveShiftRight()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyReleaseShiftRight()), SIGNAL(componentTransformHasChanged()), Qt::UniqueConnection);
      }
    }
    else
    {
      if (!mpBottomLeftResizerItem->isPressed())
        if (!mpTopLeftResizerItem->isPressed())
          if (!mpTopRightResizerItem->isPressed())
            if (!mpBottomRightResizerItem->isPressed())
              hideResizerItems();
      /* Always hide ResizerItem's for system library class and inherited components. */
      if (mpGraphicsView->getModelWidget()->getLibraryTreeNode()->isSystemLibrary() || isInheritedComponent())
        hideResizerItems();
      unsetCursor();
      /* Only allow manipulations on component if the class is not a system library class OR component is not an inherited component. */
      if (!mpGraphicsView->getModelWidget()->getLibraryTreeNode()->isSystemLibrary() && !isInheritedComponent())
      {
        disconnect(mpGraphicsView->getDeleteAction(), SIGNAL(triggered()), this, SLOT(deleteMe()));
        disconnect(mpGraphicsView->getDuplicateAction(), SIGNAL(triggered()), this, SLOT(duplicate()));
        disconnect(mpGraphicsView->getRotateClockwiseAction(), SIGNAL(triggered()), this, SLOT(rotateClockwise()));
        disconnect(mpGraphicsView->getRotateClockwiseAction(), SIGNAL(triggered()), this, SIGNAL(componentTransformHasChanged()));
        disconnect(mpGraphicsView->getRotateAntiClockwiseAction(), SIGNAL(triggered()), this, SLOT(rotateAntiClockwise()));
        disconnect(mpGraphicsView->getRotateAntiClockwiseAction(), SIGNAL(triggered()), this, SIGNAL(componentTransformHasChanged()));
        disconnect(mpGraphicsView->getFlipHorizontalAction(), SIGNAL(triggered()), this, SLOT(flipHorizontal()));
        disconnect(mpGraphicsView->getFlipVerticalAction(), SIGNAL(triggered()), this, SLOT(flipVertical()));
        disconnect(mpGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()));
        disconnect(mpGraphicsView, SIGNAL(keyPressDuplicate()), this, SLOT(duplicate()));
        disconnect(mpGraphicsView, SIGNAL(keyPressRotateClockwise()), this, SLOT(rotateClockwise()));
        disconnect(mpGraphicsView, SIGNAL(keyReleaseRotateClockwise()), this, SIGNAL(componentTransformHasChanged()));
        disconnect(mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()));
        disconnect(mpGraphicsView, SIGNAL(keyReleaseRotateAntiClockwise()), this, SIGNAL(componentTransformHasChanged()));
        disconnect(mpGraphicsView, SIGNAL(keyPressUp()), this, SLOT(moveUp()));
        disconnect(mpGraphicsView, SIGNAL(keyReleaseUp()), this, SIGNAL(componentTransformHasChanged()));
        disconnect(mpGraphicsView, SIGNAL(keyPressShiftUp()), this, SLOT(moveShiftUp()));
        disconnect(mpGraphicsView, SIGNAL(keyReleaseShiftUp()), this, SIGNAL(componentTransformHasChanged()));
        disconnect(mpGraphicsView, SIGNAL(keyPressDown()), this, SLOT(moveDown()));
        disconnect(mpGraphicsView, SIGNAL(keyReleaseDown()), this, SIGNAL(componentTransformHasChanged()));
        disconnect(mpGraphicsView, SIGNAL(keyPressShiftDown()), this, SLOT(moveShiftDown()));
        disconnect(mpGraphicsView, SIGNAL(keyReleaseShiftDown()), this, SIGNAL(componentTransformHasChanged()));
        disconnect(mpGraphicsView, SIGNAL(keyPressLeft()), this, SLOT(moveLeft()));
        disconnect(mpGraphicsView, SIGNAL(keyReleaseLeft()), this, SIGNAL(componentTransformHasChanged()));
        disconnect(mpGraphicsView, SIGNAL(keyPressShiftLeft()), this, SLOT(moveShiftLeft()));
        disconnect(mpGraphicsView, SIGNAL(keyReleaseShiftLeft()), this, SIGNAL(componentTransformHasChanged()));
        disconnect(mpGraphicsView, SIGNAL(keyPressRight()), this, SLOT(moveRight()));
        disconnect(mpGraphicsView, SIGNAL(keyReleaseRight()), this, SIGNAL(componentTransformHasChanged()));
        disconnect(mpGraphicsView, SIGNAL(keyPressShiftRight()), this, SLOT(moveShiftRight()));
        disconnect(mpGraphicsView, SIGNAL(keyReleaseShiftRight()), this, SIGNAL(componentTransformHasChanged()));
      }
    }
  }
  else if (change == QGraphicsItem::ItemPositionHasChanged)
  {
    emit componentTransformChange();
  }
  return value;
}

ComponentInfo::ComponentInfo(QString value)
{
  mClassName = "";
  mName = "";
  mComment = "";
  mIsProtected = false;
  mIsFinal = false;
  mIsFlow = false;
  mIsStream = false;
  mIsReplaceable = false;
  mVariabilityMap.insert("constant", "constant");
  mVariabilityMap.insert("discrete", "discrete");
  mVariabilityMap.insert("parameter", "parameter");
  mVariabilityMap.insert("unspecified", "default");
  mVariability = "";
  mIsInner = false;
  mIsOuter = false;
  mCasualityMap.insert("input", "input");
  mCasualityMap.insert("output", "output");
  mCasualityMap.insert("unspecified", "none");
  mCasuality = "";
  mArrayIndex = "";
  mIsArray = false;
  parseComponentInfoString(value);
}

void ComponentInfo::parseComponentInfoString(QString value)
{
  if (value.isEmpty())
    return;
  QStringList list = StringHandler::unparseStrings(value);
  // read the class name
  if (list.size() > 0)
    mClassName = list.at(0);
  else
    return;
  // read the name
  if (list.size() > 1)
    mName = list.at(1);
  else
    return;
  // read the class comment
  if (list.size() > 2)
    mComment = list.at(2);
  else
    return;
  // read the class access
  if (list.size() > 3)
    mIsProtected = StringHandler::removeFirstLastQuotes(list.at(3)).contains("protected");
  else
    return;
  // read the final attribute
  if (list.size() > 4)
    mIsFinal = list.at(4).contains("true");
  else
    return;
  // read the flow attribute
  if (list.size() > 5)
    mIsFlow = list.at(5).contains("true");
  else
    return;
  // read the stream attribute
  if (list.size() > 6)
    mIsStream = list.at(6).contains("true");
  else
    return;
  // read the replaceable attribute
  if (list.size() > 7)
    mIsReplaceable = list.at(7).contains("true");
  else
    return;
  // read the variability attribute
  if (list.size() > 8)
  {
    QMap<QString, QString>::iterator variability_it;
    for (variability_it = mVariabilityMap.begin(); variability_it != mVariabilityMap.end(); ++variability_it)
    {
      if (variability_it.key().compare(StringHandler::removeFirstLastQuotes(list.at(8))) == 0)
      {
        mVariability = variability_it.value();
        break;
      }
    }
  }
  // read the inner attribute
  if (list.size() > 9)
  {
    mIsInner = list.at(9).contains("inner");
    mIsOuter = list.at(9).contains("outer");
  }
  else
    return;
  // read the casuality attribute
  if (list.size() > 10)
  {
    QMap<QString, QString>::iterator casuality_it;
    for (casuality_it = mCasualityMap.begin(); casuality_it != mCasualityMap.end(); ++casuality_it)
    {
      if (casuality_it.key().compare(StringHandler::removeFirstLastQuotes(list.at(10))) == 0)
      {
        mCasuality = casuality_it.value();
        break;
      }
    }
  }
  // read the array index value
  mArrayIndex = StringHandler::removeFirstLastCurlBrackets(list.at(11));
  if (!mArrayIndex.isEmpty())
    mIsArray = true;
}

QString ComponentInfo::getClassName()
{
  return mClassName;
}

QString ComponentInfo::getName()
{
  return mName;
}

QString ComponentInfo::getComment()
{
  return StringHandler::removeFirstLastQuotes(mComment);
}

bool ComponentInfo::getProtected()
{
  return mIsProtected;
}

bool ComponentInfo::getFinal()
{
  return mIsFinal;
}

bool ComponentInfo::getFlow()
{
  return mIsFlow;
}

bool ComponentInfo::getStream()
{
  return mIsStream;
}

bool ComponentInfo::getReplaceable()
{
  return mIsReplaceable;
}

QString ComponentInfo::getVariablity()
{
  return mVariability;
}

bool ComponentInfo::getInner()
{
  return mIsInner;
}

bool ComponentInfo::getOuter()
{
  return mIsOuter;
}

QString ComponentInfo::getCasuality()
{
  return mCasuality;
}

QString ComponentInfo::getArrayIndex()
{
  return mArrayIndex;
}

bool ComponentInfo::isArray()
{
  return mIsArray;
}
