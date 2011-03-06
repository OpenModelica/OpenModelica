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

#include "ShapeAnnotation.h"
#include "ProjectTabWidget.h"

ShapeAnnotation::ShapeAnnotation(QGraphicsItem *parent)
    : QGraphicsItem(parent)
{

}

ShapeAnnotation::ShapeAnnotation(GraphicsView *graphicsView, QGraphicsItem *parent)
    : QGraphicsItem(parent)
{
    mpGraphicsView = graphicsView;
}

ShapeAnnotation::~ShapeAnnotation()
{
    // delete all the corner items associated with item
    foreach (RectangleCornerItem *rectangleCornerItem, mRectangleCornerItemsList)
    {
        delete rectangleCornerItem;
    }
}

void ShapeAnnotation::initializeFields()
{
    // initialize the Line Patterns map.
    this->mLinePatternsMap.insert("None", Qt::NoPen);
    this->mLinePatternsMap.insert("Solid", Qt::SolidLine);
    this->mLinePatternsMap.insert("Dash", Qt::DashLine);
    this->mLinePatternsMap.insert("Dot", Qt::DotLine);
    this->mLinePatternsMap.insert("DashDot", Qt::DashDotLine);
    this->mLinePatternsMap.insert("DashDotDot", Qt::DashDotDotLine);

    // initialize the Fill Patterns map.
    this->mFillPatternsMap.insert("None", Qt::NoBrush);
    this->mFillPatternsMap.insert("Solid", Qt::SolidPattern);
    this->mFillPatternsMap.insert("Horizontal", Qt::HorPattern);
    this->mFillPatternsMap.insert("Vertical", Qt::VerPattern);
    this->mFillPatternsMap.insert("Cross", Qt::CrossPattern);
    this->mFillPatternsMap.insert("Forward", Qt::FDiagPattern);
    this->mFillPatternsMap.insert("Backward", Qt::BDiagPattern);
    this->mFillPatternsMap.insert("CrossDiag", Qt::DiagCrossPattern);
    this->mFillPatternsMap.insert("HorizontalCylinder", Qt::LinearGradientPattern);
    this->mFillPatternsMap.insert("VerticalCylinder", Qt::Dense1Pattern);
    this->mFillPatternsMap.insert("Sphere", Qt::RadialGradientPattern);

    this->mVisible = true;
    mOrigin.setX(0);
    mOrigin.setY(0);
    mRotation = 0;

    mLineColor = QColor (0, 0, 255);
    this->mFillColor = QColor (0, 0, 255);
    mLinePattern = Qt::SolidLine;
    this->mFillPattern = Qt::NoBrush;
    mThickness = 0.25;
    this->mBorderPattern = Qt::NoBrush;
    this->mCornerRadius = 0;
    mSmooth = false;

    mIsCustomShape = false;
    mIsFinishedCreatingShape = false;
    mIsRectangleCorneItemClicked = false;
}

void ShapeAnnotation::setSelectionBoxActive()
{
    foreach (RectangleCornerItem *rectangleCornerItem, mRectangleCornerItemsList)
    {
        rectangleCornerItem->setActive();
    }
}

void ShapeAnnotation::setSelectionBoxPassive()
{
    foreach (RectangleCornerItem *rectangleCornerItem, mRectangleCornerItemsList)
    {
        rectangleCornerItem->setPassive();
    }
}

void ShapeAnnotation::setSelectionBoxHover()
{
    foreach (RectangleCornerItem *rectangleCornerItem, mRectangleCornerItemsList)
    {
        rectangleCornerItem->setHovered();
    }
}

QString ShapeAnnotation::getShapeAnnotation()
{
    return QString();
}

QRectF ShapeAnnotation::getBoundingRect() const
{
    QPointF p1 = mExtent.at(0);
    QPointF p2 = mExtent.at(1);

    qreal left = qMin(p1.x(), p2.x());
    qreal top = qMin(p1.y(), p2.y());
    qreal width = fabs(p1.x() - p2.x());
    qreal height = fabs(p1.y() - p2.y());

    return QRectF (left, top, width, height);
}

QPainterPath ShapeAnnotation::addPathStroker(QPainterPath &path) const
{
    QPainterPathStroker stroker;
    stroker.setWidth(Helper::shapesStrokeWidth);
    return stroker.createStroke(path);
}

//! Tells the component to ask its parent to delete it.
void ShapeAnnotation::deleteMe()
{
    mpGraphicsView->deleteShapeObject(this);
    mpGraphicsView->scene()->removeItem(this);
    emit updateShapeAnnotation();
    delete this;
}

void ShapeAnnotation::doSelect()
{
    mIsRectangleCorneItemClicked = true;
    if (!this->isSelected())
        setSelectionBoxActive();
}

void ShapeAnnotation::doUnSelect()
{
    mIsRectangleCorneItemClicked = false;
    if (!this->isSelected())
        setSelectionBoxPassive();
}

//! Slot that moves component one pixel upwards
//! @see moveDown()
//! @see moveLeft()
//! @see moveRight()
void ShapeAnnotation::moveUp()
{
    this->setPos(this->pos().x(), this->mapFromScene(this->mapToScene(this->pos())).y()+1);
    mpGraphicsView->scene()->update();
    emit updateShapeAnnotation();
}

//! Slot that moves component one pixel downwards
//! @see moveUp()
//! @see moveLeft()
//! @see moveRight()
void ShapeAnnotation::moveDown()
{
    this->setPos(this->pos().x(), this->mapFromScene(this->mapToScene(this->pos())).y()-1);
    mpGraphicsView->scene()->update();
    emit updateShapeAnnotation();
}

//! Slot that moves component one pixel leftwards
//! @see moveUp()
//! @see moveDown()
//! @see moveRight()
void ShapeAnnotation::moveLeft()
{
    this->setPos(this->mapFromScene(this->mapToScene(this->pos())).x()-1, this->pos().y());
    mpGraphicsView->scene()->update();
    emit updateShapeAnnotation();
}

//! Slot that moves component one pixel rightwards
//! @see moveUp()
//! @see moveDown()
//! @see moveLeft()
void ShapeAnnotation::moveRight()
{
    this->setPos(this->mapFromScene(this->mapToScene(this->pos())).x()+1, this->pos().y());
    mpGraphicsView->scene()->update();
    emit updateShapeAnnotation();
}

void ShapeAnnotation::rotateClockwise()
{
    qreal rotation = this->rotation();
    qreal rotateIncrement = -90;

    if (rotation == -270)
        this->setRotation(0);
    else
        this->setRotation(rotation + rotateIncrement);
}

void ShapeAnnotation::rotateAntiClockwise()
{

    qreal rotation = this->rotation();
    qreal rotateIncrement = 90;

    if (rotation == 270)
        this->setRotation(0);
    else
        this->setRotation(rotation + rotateIncrement);
}

void ShapeAnnotation::resetRotation()
{
    this->setRotation(0);
}

//! Event when mouse cursor enters component icon.
void ShapeAnnotation::hoverEnterEvent(QGraphicsSceneHoverEvent *event)
{
    Q_UNUSED(event);

    // only use hover events for user defined lines
    if (!mIsCustomShape)
        return;

    if(!this->isSelected())
        setSelectionBoxHover();
}

//! Event when mouse cursor leaves component icon.
void ShapeAnnotation::hoverLeaveEvent(QGraphicsSceneHoverEvent *event)
{
    Q_UNUSED(event);

    // only use hover events for user defined lines
    if (!mIsCustomShape)
        return;

    if(!this->isSelected())
        setSelectionBoxPassive();
}

void ShapeAnnotation::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
    if (event->button() != Qt::LeftButton)
        return;
    // only use mouse events for user defined lines
    if (!mIsCustomShape or !mIsFinishedCreatingShape)
    {
        QGraphicsItem::mousePressEvent(event);
        return;
    }

    mClickPos = mapToScene(event->pos());
    mIsItemClicked = true;
    setCursor(Qt::SizeAllCursor);
    QGraphicsItem::mousePressEvent(event);
}

void ShapeAnnotation::mouseReleaseEvent(QGraphicsSceneMouseEvent *event)
{
    // only use mouse events for user defined lines
    if (!mIsCustomShape or !mIsFinishedCreatingShape)
    {
        QGraphicsItem::mouseReleaseEvent(event);
        return;
    }

    if (mClickPos != mapToScene(event->pos()))
    {
        mIsItemClicked = false;
        emit updateShapeAnnotation();
    }
    unsetCursor();
    QGraphicsItem::mouseReleaseEvent(event);
}

QVariant ShapeAnnotation::itemChange(GraphicsItemChange change, const QVariant &value)
{
    QGraphicsItem::itemChange(change, value);
    if (change == QGraphicsItem::ItemSelectedHasChanged)
    {
        if (this->isSelected())
        {
            setSelectionBoxActive();
            // we first need to disconnect just to make sure we don't make connections two times.
            /* since we dont do the disconnect when user click on corner item so selecting the item back can
               create two connections */
            disconnect(mpGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()));
            disconnect(mpGraphicsView, SIGNAL(keyPressUp()), this, SLOT(moveUp()));
            disconnect(mpGraphicsView, SIGNAL(keyPressDown()), this, SLOT(moveDown()));
            disconnect(mpGraphicsView, SIGNAL(keyPressLeft()), this, SLOT(moveLeft()));
            disconnect(mpGraphicsView, SIGNAL(keyPressRight()), this, SLOT(moveRight()));
            disconnect(mpGraphicsView, SIGNAL(keyPressRotateClockwise()), this, SLOT(rotateClockwise()));
            disconnect(mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()));
            // make the connections now
            connect(mpGraphicsView, SIGNAL(keyPressDelete()), SLOT(deleteMe()));
            connect(mpGraphicsView, SIGNAL(keyPressUp()), SLOT(moveUp()));
            connect(mpGraphicsView, SIGNAL(keyPressDown()), SLOT(moveDown()));
            connect(mpGraphicsView, SIGNAL(keyPressLeft()), SLOT(moveLeft()));
            connect(mpGraphicsView, SIGNAL(keyPressRight()), SLOT(moveRight()));
            connect(mpGraphicsView, SIGNAL(keyPressRotateClockwise()), SLOT(rotateClockwise()));
            connect(mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), SLOT(rotateAntiClockwise()));
        }
        // if use has clicked on corner item then dont make it passive
        else if (!mIsRectangleCorneItemClicked)
        {
            setSelectionBoxPassive();
            disconnect(mpGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()));
            disconnect(mpGraphicsView, SIGNAL(keyPressUp()), this, SLOT(moveUp()));
            disconnect(mpGraphicsView, SIGNAL(keyPressDown()), this, SLOT(moveDown()));
            disconnect(mpGraphicsView, SIGNAL(keyPressLeft()), this, SLOT(moveLeft()));
            disconnect(mpGraphicsView, SIGNAL(keyPressRight()), this, SLOT(moveRight()));
            disconnect(mpGraphicsView, SIGNAL(keyPressRotateClockwise()), this, SLOT(rotateClockwise()));
            disconnect(mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()));

        }
    }
    return value;
}
