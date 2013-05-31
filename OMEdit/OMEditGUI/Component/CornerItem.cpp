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

#include "CornerItem.h"

/*!
  \class CornerItem
  \brief Corner items for each point of LineAnnotation and PolygonAnnotation type shapes.
  */
/*!
  \param x - the x-axis position of the point.
  \param y - the y-axis position of the point.
  \param connectedPointIndex - the index value of the point.
  \param pParent - pointer to ShapeAnnotation
  */
CornerItem::CornerItem(qreal x, qreal y, int connectedPointIndex, ShapeAnnotation *pParent)
  : QGraphicsItem(pParent), mConnectedPointIndex(connectedPointIndex)
{
  setFlags(QGraphicsItem::ItemIgnoresTransformations | QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable
           | QGraphicsItem::ItemSendsGeometryChanges);
  setCursor(Qt::ArrowCursor);
  setToolTip(Helper::clickAndDragToResize);
  setPos(x, y);
  mRectangle = QRectF (-3, -3, 6, 6);
  mpShapeAnnotation = pParent;
  /* Only shapes manipulation via CornerItem's if the class is not a system library class. */
  if (!mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeNode()->isSystemLibrary())
  {
    connect(this, SIGNAL(cornerItemMoved(int,QPointF)), mpShapeAnnotation, SLOT(updateCornerItemPoint(int,QPointF)));
    connect(this, SIGNAL(cornerItemPress()), mpShapeAnnotation, SLOT(cornerItemPressed()));
    connect(this, SIGNAL(cornerItemRelease()), mpShapeAnnotation, SLOT(cornerItemReleased()));
    /*
      if Line type is connection then don't connect the addClassAnnotation SLOT.
      instead connect the updateConnectionAnnotation SLOT of LineAnnotation.
      */
    LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(mpShapeAnnotation);
    LineAnnotation::LineType lineType = LineAnnotation::ShapeType;
    if (pLineAnnotation)
      lineType = pLineAnnotation->getLineType();
    if (lineType == LineAnnotation::ConnectionType)
      connect(this, SIGNAL(cornerItemPositionChanged()), pLineAnnotation, SLOT(updateConnectionAnnotation()));
    else
      connect(this, SIGNAL(cornerItemPositionChanged()), mpShapeAnnotation->getGraphicsView(), SLOT(addClassAnnotation()));
  }
}

/*!
  Returns the bounding rectangle of the CornerItem.
  \return the bounding rectangle.
  */
QRectF CornerItem::boundingRect() const
{
  return mRectangle;
}

/*!
  Reimplementation of paint.\n
  Draws the rectangle shape for the CornerItem.
  \param painter - pointer to QPainter
  \param option - pointer to QStyleOptionGraphicsItem
  \param widget - pointer to QWidget
  */
void CornerItem::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(option);
  Q_UNUSED(widget);
  QPen pen(Qt::red);
  painter->setPen(pen);
  painter->setBrush(pen.color());
  painter->drawRect(mRectangle);
}

/*!
  Reimplementation of mousePressEvent.\n
  Emits the CornerItem::CornerItemPress SIGNAL. Stores the old position of the CornerItem.
  \param event - pointer to QGraphicsSceneMouseEvent
  */
void CornerItem::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
  if (event->button() == Qt::LeftButton)
  {
    emit cornerItemPress();
    mClickPos = mapToScene(event->pos());
  }
  QGraphicsItem::mousePressEvent(event);
}

/*!
  Reimplementation of mouseReleaseEvent.\n
  Emits the CornerItem::CornerItemRelease SIGNAL.\n
  Checks the CornerItem old postion with the current postion.
  If the position is changed then emits the CornerItem::CornerItemPositionChanged SIGNAL.
  \param event - pointer to QGraphicsSceneMouseEvent
  */
void CornerItem::mouseReleaseEvent(QGraphicsSceneMouseEvent *event)
{
  QGraphicsItem::mouseReleaseEvent(event);
  if (event->button() == Qt::LeftButton)
  {
    emit cornerItemRelease();
    if (mClickPos != mapToScene(event->pos()))
    {
      emit cornerItemPositionChanged();
      mpShapeAnnotation->getGraphicsView()->setCanAddClassAnnotation(true);
    }
  }
}

/*!
  Reimplementation of itemChange.\n
  If CornerItem position has changed then emits the CornerItem::CornerItemMoved SIGNAL.
  \param change - GraphicsItemChange
  \param value - QVariant
  */
QVariant CornerItem::itemChange(GraphicsItemChange change, const QVariant &value)
{
  QGraphicsItem::itemChange(change, value);
  if (change == QGraphicsItem::ItemPositionHasChanged)
  {
    emit cornerItemMoved(mConnectedPointIndex, value.toPointF());
  }
  return value;
}

/*!
  \class ResizerItem
  \brief Represents a red rectangle box around the Component, RectangleAnnotation, EllipseAnnotation, TextAnnotation and BitmapAnnotation.
  */
/*!
  \param pParent - pointer to QGraphicsItem.
  */
ResizerItem::ResizerItem(QGraphicsItem *pParent)
  : QGraphicsItem(pParent), mIsPressed(false)
{
  setFlags(QGraphicsItem::ItemIgnoresTransformations | QGraphicsItem::ItemIsSelectable);
  setCursor(Qt::ArrowCursor);
  setToolTip(Helper::clickAndDragToResize);
  mActivePen = QPen(Qt::red);
  mPassivePen = QPen(Qt::transparent);
  mRectangle = QRectF (-3, -3, 6, 6);
  setPassive();
}

/*!
  Sets the ResizerItem position i.e top, left, right or bottom.
  \param position - ResizePositions
  */
void ResizerItem::setResizePosition(ResizePositions position)
{
  mResizeposition = position;
}

/*!
  Returns the CornerItem position i.e top, left, right or bottom.
  \return the ResizerItem position.
  */
ResizerItem::ResizePositions ResizerItem::getResizePosition()
{
  return mResizeposition;
}

/*!
  Sets the active pen for drawing.
  \see setPassive();
  */
void ResizerItem::setActive()
{
  mPen = mActivePen;
}

/*!
  Sets the passive pen for drawing.
  \see setPassive();
  */
void ResizerItem::setPassive()
{
  mPen = mPassivePen;
}

/*!
  Returns the bounding rectangle of the CornerItem.
  \return the bounding rectangle.
  */
QRectF ResizerItem::boundingRect() const
{
  return mRectangle;
}

/*!
  Reimplementation of paint.\n
  Draws the rectangle shape for the ResizerItem.
  \param painter - pointer to QPainter
  \param option - pointer to QStyleOptionGraphicsItem
  \param widget - pointer to QWidget
  */
void ResizerItem::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(option);
  Q_UNUSED(widget);
  painter->setPen(mPen);
  painter->setBrush(mPen.color());
  painter->drawRect(mRectangle);
}

/*!
  Returns true if the mouse is pressed on ResizerItem.
  \return true/false
  */
bool ResizerItem::isPressed()
{
  return mIsPressed;
}

/*!
  Reimplementation of mousePressEvent.\n
  Emits the ResizerItem::resizerItemPressed SIGNAL. Stores the old position of the ResizerItem.
  \param event - pointer to QGraphicsSceneMouseEvent
  */
void ResizerItem::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
  if (event->button() == Qt::LeftButton)
  {
    emit resizerItemPressed(this);
    mIsPressed = true;
    mResizerItemOldPosition = event->scenePos();
  }
  QGraphicsItem::mousePressEvent(event);
}

/*!
  Reimplementation of mouseMoveEvent.\n
  Emits the ResizerItem::resizerItemMoved SIGNAL if mouse is pressed on ResizerItem.
  \param event - pointer to QGraphicsSceneMouseEvent
  */
void ResizerItem::mouseMoveEvent(QGraphicsSceneMouseEvent *event)
{
  if (mIsPressed)     // indicates that user is dragging the corner item
    emit resizerItemMoved(mIndex, event->scenePos());
  QGraphicsItem::mouseMoveEvent(event);
}

/*!
  Reimplementation of mouseReleaseEvent.\n
  Emits the ResizerItem::resizerItemMoved SIGNAL if mouse is pressed on ResizerItem.
  \param event - pointer to QGraphicsSceneMouseEvent
  */
void ResizerItem::mouseReleaseEvent(QGraphicsSceneMouseEvent *event)
{
  QGraphicsItem::mouseReleaseEvent(event);
  if (event->button() == Qt::LeftButton)
  {
    mIsPressed = false;
    emit resizerItemReleased();
    if (mResizerItemOldPosition != event->scenePos())
      emit resizerItemPositionChanged();
  }
}
