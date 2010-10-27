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
 *
 */

#include "IconAnnotation.h"

IconAnnotation::IconAnnotation(QString value, QString name, QString className, QPointF position, OMCProxy *omc,
                               GraphicsScene *graphicsScene, GraphicsView *graphicsView)
    : mIconAnnotationString(value), mName(name), mClassName(className), mIsClone(false), mpOMCProxy(omc),
      mpGraphicsScene(graphicsScene), mpGraphicsView(graphicsView)
{
    scale(Helper::globalXScale, Helper::globalYScale);
    mpGraphicsScene->addItem(this);
    setPos(position);
    setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable | QGraphicsItem::ItemSendsGeometryChanges);
    setAcceptHoverEvents(true);

    mpIconParametersList.append(mpOMCProxy->getParameters(mClassName));
    parseIconAnnotationString(this, value);
    getClassComponents(this->mClassName);
    createSelectionBox();
    createActions();

    connect(mpIconPropertiesAction, SIGNAL(triggered()), SLOT(openIconProperties()));
}

IconAnnotation::IconAnnotation(QString value, QString name, QString className, OMCProxy *omc)
    : mIconAnnotationString(value), mName(name), mClassName(className), mIsClone(false) , mpOMCProxy(omc)
{
    this->scale(Helper::globalXScale, Helper::globalYScale);
    parseIconAnnotationString(this, value);
}

IconAnnotation::IconAnnotation(const IconAnnotation *icon, QString name, QPointF position,
                               GraphicsScene *graphicsScene, GraphicsView *graphicsView)
    : mName(name), mIsClone(true), mpGraphicsScene(graphicsScene), mpGraphicsView(graphicsView)
{
    this->scale(Helper::globalXScale, Helper::globalYScale);
    mpGraphicsScene->addItem(this);
    setPos(position);
    setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable | QGraphicsItem::ItemSendsGeometryChanges);
    setAcceptHoverEvents(true);

    mIconAnnotationString = icon->mIconAnnotationString;
    mClassName = icon->mClassName;
    mpOMCProxy = icon->mpOMCProxy;

    parseIconAnnotationString(this, mIconAnnotationString);
    InheritanceAnnotation *inheritanceAnnotation;
    foreach (InheritanceAnnotation *inheritance, icon->mpInheritanceList)
    {
        inheritanceAnnotation = new InheritanceAnnotation(inheritance->mIconAnnotationString,
                                                          inheritance->mClassName, this);
        mpInheritanceList.append(inheritanceAnnotation);
    }

    ComponentAnnotation *componentAnnotation;
    foreach (ComponentAnnotation *component, icon->mpComponentsList)
    {
        componentAnnotation = new ComponentAnnotation(component->mIconAnnotationString, component->mClassName,
                                                      component->mTransformationString,
                                                      component->mpComponentProperties, this);
        mpComponentsList.append(componentAnnotation);
    }

    //getClassComponents(mClassName);
    createSelectionBox();
}

IconAnnotation::~IconAnnotation()
{
    delete mpTopLeftCornerItem;
    delete mpTopRightCornerItem;
    delete mpBottomLeftCornerItem;
    delete mpBottomRightCornerItem;
}

//! Parses the result of getIconAnnotation command.
//! @param value is the result of getIconAnnotation command obtained from OMC.
void IconAnnotation::parseIconAnnotationString(ShapeAnnotation *item, QString value)
{
    value = StringHandler::removeFirstLastCurlBrackets(value);
    if (value.isEmpty())
    {
        return;
    }
    QStringList list = StringHandler::getStrings(value);

    if (mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
    {
        if (list.size() < 9)
            return;
    }
    else if (mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION2X)
    {
        if (list.size() < 4)
            return;
    }
    qreal x1, x2, y1, y2, width, height;
    x1 = static_cast<QString>(list.at(0)).toFloat();
    y1 = static_cast<QString>(list.at(1)).toFloat();
    x2 = static_cast<QString>(list.at(2)).toFloat();
    y2 = static_cast<QString>(list.at(3)).toFloat();
    width = fabs(x1 - x2);
    height = fabs(y1 - y2);

    if (dynamic_cast<IconAnnotation*>(item))
        (dynamic_cast<IconAnnotation*>(item))->mRectangle = QRectF (x1, y1, width, height);
    else if (dynamic_cast<InheritanceAnnotation*>(item))
        (dynamic_cast<InheritanceAnnotation*>(item))->mRectangle = QRectF (x1, y1, width, height);
    else if (dynamic_cast<ComponentAnnotation*>(item))
        (dynamic_cast<ComponentAnnotation*>(item))->mRectangle = QRectF (x1, y1, width, height);

    if (list.size() < 5)
    {
        return;
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
            LineAnnotation *lineAnnotation = new LineAnnotation(shape, mpOMCProxy, item);

            if (dynamic_cast<IconAnnotation*>(item))
                (dynamic_cast<IconAnnotation*>(item))->mpLinesList.append(lineAnnotation);
            else if (dynamic_cast<InheritanceAnnotation*>(item))
                (dynamic_cast<InheritanceAnnotation*>(item))->mpLinesList.append(lineAnnotation);
            else if (dynamic_cast<ComponentAnnotation*>(item))
                (dynamic_cast<ComponentAnnotation*>(item))->mpLinesList.append(lineAnnotation);
        }
        if (shape.startsWith("Polygon"))
        {
            shape = shape.mid(QString("Polygon").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            PolygonAnnotation *polygonAnnotation = new PolygonAnnotation(shape, mpOMCProxy, item);

            if (dynamic_cast<IconAnnotation*>(item))
                (dynamic_cast<IconAnnotation*>(item))->mpPolygonsList.append(polygonAnnotation);
            else if (dynamic_cast<InheritanceAnnotation*>(item))
                (dynamic_cast<InheritanceAnnotation*>(item))->mpPolygonsList.append(polygonAnnotation);
            else if (dynamic_cast<ComponentAnnotation*>(item))
                (dynamic_cast<ComponentAnnotation*>(item))->mpPolygonsList.append(polygonAnnotation);
        }
        if (shape.startsWith("Rectangle"))
        {
            shape = shape.mid(QString("Rectangle").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            RectangleAnnotation *rectangleAnnotation = new RectangleAnnotation(shape, mpOMCProxy, item);

            if (dynamic_cast<IconAnnotation*>(item))
                (dynamic_cast<IconAnnotation*>(item))->mpRectanglesList.append(rectangleAnnotation);
            else if (dynamic_cast<InheritanceAnnotation*>(item))
                (dynamic_cast<InheritanceAnnotation*>(item))->mpRectanglesList.append(rectangleAnnotation);
            else if (dynamic_cast<ComponentAnnotation*>(item))
                (dynamic_cast<ComponentAnnotation*>(item))->mpRectanglesList.append(rectangleAnnotation);
        }
        if (shape.startsWith("Ellipse"))
        {
            shape = shape.mid(QString("Ellipse").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            EllipseAnnotation *ellipseAnnotation = new EllipseAnnotation(shape, mpOMCProxy, item);

            if (dynamic_cast<IconAnnotation*>(item))
                (dynamic_cast<IconAnnotation*>(item))->mpEllipsesList.append(ellipseAnnotation);
            else if (dynamic_cast<InheritanceAnnotation*>(item))
                (dynamic_cast<InheritanceAnnotation*>(item))->mpEllipsesList.append(ellipseAnnotation);
            else if (dynamic_cast<ComponentAnnotation*>(item))
                (dynamic_cast<ComponentAnnotation*>(item))->mpEllipsesList.append(ellipseAnnotation);
        }
        if (shape.startsWith("Text"))
        {
            shape = shape.mid(QString("Text").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            TextAnnotation *textAnnotation = new TextAnnotation(shape, mpOMCProxy, item);

            if (dynamic_cast<IconAnnotation*>(item))
                (dynamic_cast<IconAnnotation*>(item))->mpTextsList.append(textAnnotation);
            else if (dynamic_cast<InheritanceAnnotation*>(item))
                (dynamic_cast<InheritanceAnnotation*>(item))->mpTextsList.append(textAnnotation);
            else if (dynamic_cast<ComponentAnnotation*>(item))
                (dynamic_cast<ComponentAnnotation*>(item))->mpTextsList.append(textAnnotation);
        }
    }
}

QRectF IconAnnotation::boundingRect() const
{
    return this->mRectangle;
}

void IconAnnotation::createSelectionBox()
{
    qreal x1, y1, x2, y2;
    boundingRect().getCoords(&x1, &y1, &x2, &y2);

    mpTopLeftCornerItem = new CornerItem(x1, y2, Qt::TopLeftCorner, this);
    connect(mpTopLeftCornerItem, SIGNAL(iconSelected()), this, SLOT(showSelectionBox()));
    connect(mpTopLeftCornerItem, SIGNAL(iconResized(qreal, qreal)), this, SLOT(resizeIcon(qreal, qreal)));
    // create top right selection box
    mpTopRightCornerItem = new CornerItem(x2, y2, Qt::TopRightCorner, this);
    connect(mpTopRightCornerItem, SIGNAL(iconSelected()), this, SLOT(showSelectionBox()));
    connect(mpTopRightCornerItem, SIGNAL(iconResized(qreal, qreal)), this, SLOT(resizeIcon(qreal, qreal)));
    // create bottom left selection box
    mpBottomLeftCornerItem = new CornerItem(x1, y1, Qt::BottomLeftCorner, this);
    connect(mpBottomLeftCornerItem, SIGNAL(iconSelected()), this, SLOT(showSelectionBox()));
    connect(mpBottomLeftCornerItem, SIGNAL(iconResized(qreal, qreal)), this, SLOT(resizeIcon(qreal, qreal)));
    // create bottom right selection box
    mpBottomRightCornerItem = new CornerItem(x2, y1, Qt::BottomRightCorner, this);
    connect(mpBottomRightCornerItem, SIGNAL(iconSelected()), this, SLOT(showSelectionBox()));
    connect(mpBottomRightCornerItem, SIGNAL(iconResized(qreal, qreal)), this, SLOT(resizeIcon(qreal, qreal)));
}

void IconAnnotation::createActions()
{
    // Icon Properties Action
    mpIconPropertiesAction = new QAction(QIcon(":/Resources/icons/tool.png"), tr("Properties"), this);
}

void IconAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(painter);
    Q_UNUSED(option);
    Q_UNUSED(widget);
}

//! Event when mouse cursor enters component icon.
void IconAnnotation::hoverEnterEvent(QGraphicsSceneHoverEvent *event)
{
    if(!this->isSelected())
        setSelectionBoxHover();
}

//! Event when mouse cursor leaves component icon.
void IconAnnotation::hoverLeaveEvent(QGraphicsSceneHoverEvent *event)
{
    if(!this->isSelected())
        setSelectionBoxPassive();
}

void IconAnnotation::contextMenuEvent(QGraphicsSceneContextMenuEvent *event)
{
    this->setSelected(true);
    QMenu menu(mpGraphicsView);
    menu.addAction(mpGraphicsView->mpRotateIconAction);
    menu.addAction(mpGraphicsView->mpRotateAntiIconAction);
    menu.addAction(mpGraphicsView->mpResetRotation);
    menu.addSeparator();
    menu.addAction(mpGraphicsView->mpDeleteIconAction);
    menu.addSeparator();
    menu.addAction(mpIconPropertiesAction);
    menu.exec(event->screenPos());
}

QVariant IconAnnotation::itemChange(GraphicsItemChange change, const QVariant &value)
{
    if (change == QGraphicsItem::ItemSelectedHasChanged)
    {
        if (this->isSelected())
        {
            setSelectionBoxActive();
            setCursor(Qt::SizeAllCursor);
            connect(mpGraphicsView->mpRotateIconAction, SIGNAL(triggered()), SLOT(rotateClockwise()));
            connect(mpGraphicsView->mpRotateAntiIconAction, SIGNAL(triggered()), SLOT(rotateAntiClockwise()));
            connect(mpGraphicsView->mpResetRotation, SIGNAL(triggered()), SLOT(resetRotation()));
            connect(mpGraphicsView->mpDeleteIconAction, SIGNAL(triggered()), SLOT(deleteMe()));
            connect(this->mpGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()));
            connect(this->mpGraphicsView, SIGNAL(keyPressUp()), this, SLOT(moveUp()));
            connect(this->mpGraphicsView, SIGNAL(keyPressDown()), this, SLOT(moveDown()));
            connect(this->mpGraphicsView, SIGNAL(keyPressLeft()), this, SLOT(moveLeft()));
            connect(this->mpGraphicsView, SIGNAL(keyPressRight()), this, SLOT(moveRight()));
            connect(this->mpGraphicsView, SIGNAL(keyPressRotateClockwise()), this, SLOT(rotateClockwise()));
            connect(this->mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()));
        }
        else
        {
            setSelectionBoxPassive();
            unsetCursor();
            disconnect(mpGraphicsView->mpRotateIconAction, SIGNAL(triggered()), this, SLOT(rotateClockwise()));
            disconnect(mpGraphicsView->mpRotateAntiIconAction, SIGNAL(triggered()), this, SLOT(rotateAntiClockwise()));
            disconnect(mpGraphicsView->mpResetRotation, SIGNAL(triggered()), this, SLOT(resetRotation()));
            disconnect(mpGraphicsView->mpDeleteIconAction, SIGNAL(triggered()), this, SLOT(deleteMe()));
            disconnect(this->mpGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()));
            disconnect(this->mpGraphicsView, SIGNAL(keyPressUp()), this, SLOT(moveUp()));
            disconnect(this->mpGraphicsView, SIGNAL(keyPressDown()), this, SLOT(moveDown()));
            disconnect(this->mpGraphicsView, SIGNAL(keyPressLeft()), this, SLOT(moveLeft()));
            disconnect(this->mpGraphicsView, SIGNAL(keyPressRight()), this, SLOT(moveRight()));
            disconnect(this->mpGraphicsView, SIGNAL(keyPressRotateClockwise()), this, SLOT(rotateClockwise()));
            disconnect(this->mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()));
        }
    }
    else if (change == QGraphicsItem::ItemPositionHasChanged)
    {
        emit componentMoved();
    }
    else if (change == QGraphicsItem::ItemRotationHasChanged)
    {
        emit componentRotated(true);
        updateSelectionBox();
    }
    else if (change == QGraphicsItem::ItemScaleHasChanged)
    {
        emit componentScaled();
        /*updateSelectionBox();*/
    }
    return QGraphicsItem::itemChange(change, value);
}

void IconAnnotation::setSelectionBoxActive()
{
    this->mpTopLeftCornerItem->setActive();
    this->mpTopRightCornerItem->setActive();
    this->mpBottomLeftCornerItem->setActive();
    this->mpBottomRightCornerItem->setActive();
}

void IconAnnotation::setSelectionBoxPassive()
{
    this->mpTopLeftCornerItem->setPassive();
    this->mpTopRightCornerItem->setPassive();
    this->mpBottomLeftCornerItem->setPassive();
    this->mpBottomRightCornerItem->setPassive();
}

void IconAnnotation::setSelectionBoxHover()
{
    this->mpTopLeftCornerItem->setHovered();
    this->mpTopRightCornerItem->setHovered();
    this->mpBottomLeftCornerItem->setHovered();
    this->mpBottomRightCornerItem->setHovered();
}

void IconAnnotation::showSelectionBox()
{
    setSelectionBoxActive();
}

void IconAnnotation::updateSelectionBox()
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

void IconAnnotation::addConnector(Connector *item)
{
    connect(this, SIGNAL(componentMoved()), item, SLOT(drawConnector()));
    connect(this, SIGNAL(componentRotated(bool)), item, SLOT(drawConnector(bool)));
}

QString IconAnnotation::getAnnotationString()
{
    // create the annotation string
    QString annotationString = "annotate=Placement(transformation(origin=";
    // add the icon origin
    annotationString.append("{").append(QString::number(pos().x())).append(",").append(QString::number(pos().x())).append("},");
    // add icon rotation
    annotationString.append("rotation=").append(QString::number(rotation())).append("))");

    return annotationString;
}

void IconAnnotation::resizeIcon(qreal resizeFactorX, qreal resizeFactorY)
{
    if (resizeFactorX > 0 && resizeFactorY > 0)
    {
        prepareGeometryChange();
        //this->scale(resizeFactorX, resizeFactorY);
        update();
        //updateSelectionBox();
    }
}

//! Tells the component to ask its parent to delete it.
void IconAnnotation::deleteMe()
{
    mpGraphicsView->deleteIconObject(this);
    mpGraphicsScene->removeItem(this);
    delete(this);
}

//! Slot that moves component one pixel upwards
//! @see moveDown()
//! @see moveLeft()
//! @see moveRight()
void IconAnnotation::moveUp()
{
    this->setPos(this->pos().x(), this->mapFromScene(this->mapToScene(this->pos())).y()+1);
    mpGraphicsScene->update();
}

//! Slot that moves component one pixel downwards
//! @see moveUp()
//! @see moveLeft()
//! @see moveRight()
void IconAnnotation::moveDown()
{
    this->setPos(this->pos().x(), this->mapFromScene(this->mapToScene(this->pos())).y()-1);
    mpGraphicsScene->update();
}

//! Slot that moves component one pixel leftwards
//! @see moveUp()
//! @see moveDown()
//! @see moveRight()
void IconAnnotation::moveLeft()
{
    this->setPos(this->mapFromScene(this->mapToScene(this->pos())).x()-1, this->pos().y());
    mpGraphicsScene->update();
}

//! Slot that moves component one pixel rightwards
//! @see moveUp()
//! @see moveDown()
//! @see moveLeft()
void IconAnnotation::moveRight()
{
    this->setPos(this->mapFromScene(this->mapToScene(this->pos())).x()+1, this->pos().y());
    mpGraphicsScene->update();
}

void IconAnnotation::rotateClockwise()
{
    qreal rotation = this->rotation();
    qreal rotateIncrement = 90;

    if (rotation == -270)
        this->setRotation(0);
    else
        this->setRotation(rotation - rotateIncrement);
}

void IconAnnotation::rotateAntiClockwise()
{
    qreal rotation = this->rotation();
    qreal rotateIncrement = -90;

    if (rotation == 270)
        this->setRotation(0);
    else
        this->setRotation(rotation - rotateIncrement);
}

void IconAnnotation::resetRotation()
{
    this->setRotation(0);
}

void IconAnnotation::openIconProperties()
{
    IconProperties *iconProperties = new IconProperties(this, mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
    iconProperties->show();
}

QString IconAnnotation::getName()
{
    return mName;
}

void IconAnnotation::updateName(QString newName)
{
    // check in icon text annotation
    foreach (TextAnnotation *textAnnotation, mpTextsList)
        if (textAnnotation->getTextString() == mName)
        {
            textAnnotation->setTextString(newName);
            mName = newName;
            return;
        }

    // check in icon's inheritance text annotation
    foreach (InheritanceAnnotation *inheritance, mpInheritanceList)
        foreach (TextAnnotation *textAnnotation, inheritance->mpTextsList)
            if (textAnnotation->getTextString() == mName)
            {
                textAnnotation->setTextString(newName);
                mName = newName;
                return;
            }

    // check in icon's components text annotation
    foreach (ComponentAnnotation *component, mpComponentsList)
        foreach (TextAnnotation *textAnnotation, component->mpTextsList)
            if (textAnnotation->getTextString() == mName)
            {
                textAnnotation->setTextString(newName);
                mName = newName;
                return;
            }
}

void IconAnnotation::updateParameterValue(QString oldValue, QString newValue)
{
    // check in icon text annotation
    foreach (TextAnnotation *textAnnotation, mpTextsList)
        if (textAnnotation->getTextString() == oldValue)
        {
            textAnnotation->setTextString(newValue);
            return;
        }
}

QString IconAnnotation::getClassName()
{
    return mClassName;
}

void IconAnnotation::getClassComponents(QString className, bool libraryIcon)
{
    int inheritanceCount = this->mpOMCProxy->getInheritanceCount(className);

    for(int i = 1 ; i <= inheritanceCount ; i++)
    {
        QString result = this->mpOMCProxy->getNthInheritedClass(className, i);
        QString annotationString = this->mpOMCProxy->getIconAnnotation(result);
        InheritanceAnnotation *inheritanceAnnotation = new InheritanceAnnotation(annotationString, result, this);
        mpInheritanceList.append(inheritanceAnnotation);
        getClassComponents(result, libraryIcon);
    }

    QList<ComponentsProperties*> components = this->mpOMCProxy->getComponents(className);
    QStringList componentsAnnotationsList = this->mpOMCProxy->getComponentAnnotations(className);
    int i = 0;
    foreach (ComponentsProperties *component, components)
    {
        if (StringHandler::removeFirstLastCurlBrackets(componentsAnnotationsList.at(i)).length() > 0)
        {
            if (this->mpOMCProxy->isWhat(StringHandler::CONNECTOR, component->getClassName()))
            {
                QString result = this->mpOMCProxy->getIconAnnotation(component->getClassName());
                ComponentAnnotation *componentAnnotation;
                if (libraryIcon)
                {
                    componentAnnotation = new ComponentAnnotation(result, component->getClassName(),
                                                                  componentsAnnotationsList.at(i),
                                                                  component, this, libraryIcon);
                }
                else
                {
                    componentAnnotation = new ComponentAnnotation(result, component->getClassName(),
                                                                  componentsAnnotationsList.at(i),
                                                                  component, this);
                }
                mpComponentsList.append(componentAnnotation);
            }
        }
        else
        {
            //! @todo Change it to add all components.............
            mpComponentProperties = components.at(0);
        }
        i++;
    }
}
