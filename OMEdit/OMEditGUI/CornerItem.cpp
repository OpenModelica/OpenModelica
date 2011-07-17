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

#include "CornerItem.h"

CornerItem::CornerItem(qreal x, qreal y, Qt::Corner corner, QGraphicsItem *parent)
    : QGraphicsItem(parent), mItemClicked(false), mCorner(corner), mScaleIncrementBy(1.10), mScaleDecrementBy(1/1.10)
{
    setFlags(QGraphicsItem::ItemIgnoresTransformations);
    this->scale(1.0, -1.0);
    this->mActivePen = QPen(Qt::red, 3);
    this->mHoverPen = QPen(Qt::darkRed, 3);
    updateCornerItem(x, y, corner);
    setPassive();
}

void CornerItem::updateCornerItem(qreal x, qreal y, Qt::Corner corner)
{
    this->setPos(x, y);

    qreal startx = 0;
    qreal starty = 0;
    qreal height = 4;
    qreal width = 4;
    QPointF point1, point2, point3;

    switch (corner)
    {
    case Qt::TopLeftCorner:
        {
            setCursor(Qt::SizeFDiagCursor);
            point1 = QPointF(startx, starty);
            point2 = QPointF(startx, starty - height);
            point3 = QPointF(startx + width, starty);
            starty = starty - height;
            break;
        }
    case Qt::TopRightCorner:
        {
            setCursor(Qt::SizeBDiagCursor);
            point1 = QPointF(startx, starty);
            point2 = QPointF(startx, starty - height);
            point3 = QPointF(startx - width, starty);
            startx = startx - width;
            starty = starty - height;
            break;
        }
    case Qt::BottomLeftCorner:
        {
            setCursor(Qt::SizeBDiagCursor);
            point1 = QPointF(startx, starty);
            point2 = QPointF(startx, starty + height);
            point3 = QPointF(startx + width, starty);
            break;
        }
    case Qt::BottomRightCorner:
        {
            setCursor(Qt::SizeFDiagCursor);
            point1 = QPointF(startx, starty);
            point2 = QPointF(startx, starty + height);
            point3 = QPointF(startx - width, starty);
            startx = startx - width;
            break;
        }
    }
    mLines.append(point1);
    mLines.append(point2);
    mLines.append(point3);
    this->mRectangle = QRectF (startx, starty, width, height);
}

//! Tells the box to become visible and use active style.
//! @see setPassive();
//! @see setHovered();
void CornerItem::setActive()
{
    this->setVisible(true);
    mPen = mActivePen;
}

//! Tells the box to become invisible.
//! @see setActive();
//! @see setHovered();
void CornerItem::setPassive()
{
    this->setVisible(false);
}

//! Tells the box to become visible and use hovered style.
//! @see setActive();
//! @see setPassive();
void CornerItem::setHovered()
{
    this->setVisible(true);
    mPen = mHoverPen;
}

QRectF CornerItem::boundingRect() const
{
    return mRectangle;
}

void CornerItem::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(option);
    Q_UNUSED(widget);

    painter->setPen(mPen);
    painter->drawLine(mLines.at(0), mLines.at(1));
    painter->drawLine(mLines.at(0), mLines.at(2));
}

void CornerItem::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
    if (event->button() != Qt::LeftButton)
        return;

    emit iconSelected();
    this->mItemClicked = true;
    this->mClickPos = event->pos();
}

void CornerItem::mouseMoveEvent(QGraphicsSceneMouseEvent *event)
{
    if (this->mItemClicked)
    {
        qreal resizeFactorX = 1.0;
        qreal resizeFactorY = 1.0;
        switch (this->mCorner)
        {
        case Qt::TopLeftCorner:
            {
                if ((this->mClickPos.x() < event->pos().x()) and (this->mClickPos.y() > event->pos().y()))
                {
                    resizeFactorX = this->mScaleDecrementBy;
                    resizeFactorY = this->mScaleDecrementBy;
                }
                else if ((this->mClickPos.x() > event->pos().x()) and (this->mClickPos.y() < event->pos().y()))
                {
                    resizeFactorX = this->mScaleIncrementBy;
                    resizeFactorY = this->mScaleIncrementBy;
                }
                break;
            }
        case Qt::TopRightCorner:
            {
                if ((this->mClickPos.x() > event->pos().x()) and (this->mClickPos.y() > event->pos().y()))
                {
                    resizeFactorX = this->mScaleDecrementBy;
                    resizeFactorY = this->mScaleDecrementBy;
                }
                else if ((this->mClickPos.x() < event->pos().x()) and (this->mClickPos.y() < event->pos().y()))
                {
                    resizeFactorX = this->mScaleIncrementBy;
                    resizeFactorY = this->mScaleIncrementBy;
                }
                break;
            }
        case Qt::BottomLeftCorner:
            {
                if ((this->mClickPos.x() < event->pos().x()) and (this->mClickPos.y() < event->pos().y()))
                {
                    resizeFactorX = this->mScaleDecrementBy;
                    resizeFactorY = this->mScaleDecrementBy;
                }
                else if ((this->mClickPos.x() > event->pos().x()) and (this->mClickPos.y() > event->pos().y()))
                {
                    resizeFactorX = this->mScaleIncrementBy;
                    resizeFactorY = this->mScaleIncrementBy;
                }
                break;
            }
        case Qt::BottomRightCorner:
            {
                if ((this->mClickPos.x() > event->pos().x()) and (this->mClickPos.y() < event->pos().y()))
                {
                    resizeFactorX = this->mScaleDecrementBy;
                    resizeFactorY = this->mScaleDecrementBy;
                }
                else if ((this->mClickPos.x() < event->pos().x()) and (this->mClickPos.y() > event->pos().y()))
                {
                    resizeFactorX = this->mScaleIncrementBy;
                    resizeFactorY = this->mScaleIncrementBy;
                }
                break;
            }
        }
        // finally emit the signal
        emit iconResized(resizeFactorX, resizeFactorY);
    }
}

void CornerItem::mouseReleaseEvent(QGraphicsSceneMouseEvent *event)
{
    Q_UNUSED(event);
    this->mItemClicked = false;
}

RectangleCornerItem::RectangleCornerItem(qreal x, qreal y, int connectedPointIndex, ShapeAnnotation *pParent)
    : QGraphicsItem(pParent), mItemClicked(false), mConnectedPointIndex(connectedPointIndex)
{
    setFlags(QGraphicsItem::ItemIgnoresTransformations | QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable
             | QGraphicsItem::ItemSendsGeometryChanges);
    setAcceptHoverEvents(true);
    this->scale(1.0, -1.0);
    this->mActivePen = QPen(Qt::red);
    this->mHoverPen = QPen(Qt::darkRed);
    this->setPos(x, y);
    this->mRectangle = QRectF (-3, -3, 6, 6);
    setActive();

    mpShapeAnnotation = pParent;
    connect(this, SIGNAL(itemMoved(int,QPointF)), mpShapeAnnotation, SLOT(updatePoint(int,QPointF)));
    connect(this, SIGNAL(itemClicked()), mpShapeAnnotation, SLOT(doSelect()));
    connect(this, SIGNAL(itemUnClicked()), mpShapeAnnotation, SLOT(doUnSelect()));
    connect(this, SIGNAL(itemPositionUpdate()), mpShapeAnnotation->mpGraphicsView, SLOT(addClassAnnotation()));
}

//! Tells the box to become visible and use active style.
//! @see setPassive();
//! @see setHovered();
void RectangleCornerItem::setActive()
{
    this->setVisible(true);
    mPen = mActivePen;
    update();
}

//! Tells the box to become invisible.
//! @see setActive();
//! @see setHovered();
void RectangleCornerItem::setPassive()
{
    this->setVisible(false);
}

//! Tells the box to become visible and use hovered style.
//! @see setActive();
//! @see setPassive();
void RectangleCornerItem::setHovered()
{
    this->setVisible(true);
    mPen = mHoverPen;
}

QRectF RectangleCornerItem::boundingRect() const
{
    return mRectangle;
}

void RectangleCornerItem::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(option);
    Q_UNUSED(widget);

    painter->setPen(mPen);
    painter->setBrush(mPen.color());
    painter->drawRect(mRectangle);
}

//! Event when mouse cursor enters component icon.
void RectangleCornerItem::hoverEnterEvent(QGraphicsSceneHoverEvent *event)
{
    Q_UNUSED(event);

    setCursor(Qt::ArrowCursor);
}

//! Event when mouse cursor leaves component icon.
void RectangleCornerItem::hoverLeaveEvent(QGraphicsSceneHoverEvent *event)
{
    Q_UNUSED(event);

    unsetCursor();
}

void RectangleCornerItem::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
    emit itemClicked();
    mClickPos = mapToScene(event->pos());
    QGraphicsItem::mousePressEvent(event);
}

void RectangleCornerItem::mouseReleaseEvent(QGraphicsSceneMouseEvent *event)
{
    emit itemUnClicked();
    if (mClickPos != mapToScene(event->pos()))
    {
        emit itemPositionUpdate();
    }
    mpShapeAnnotation->setSelected(true);
    QGraphicsItem::mouseReleaseEvent(event);
}

QVariant RectangleCornerItem::itemChange(GraphicsItemChange change, const QVariant &value)
{
    QGraphicsItem::itemChange(change, value);



    if (change == QGraphicsItem::ItemPositionHasChanged)
    {

        emit itemMoved(mConnectedPointIndex, value.toPointF());
    }
    return value;
}
