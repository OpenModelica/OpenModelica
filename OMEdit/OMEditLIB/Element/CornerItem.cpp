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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "CornerItem.h"
#include "Element.h"
#include "Modeling/Commands.h"

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
  : QGraphicsItem(pParent), mpShapeAnnotation(pParent)
{
  mOldScenePosition = QPointF();
  setConnectedPointIndex(connectedPointIndex);
  setCursor(Qt::ArrowCursor);
  setToolTip(Helper::clickAndDragToResize + QString::number(mConnectedPointIndex));
  setPos(x, y);
  setFlags(QGraphicsItem::ItemIgnoresTransformations | QGraphicsItem::ItemIsSelectable);
  mRectangle = QRectF (-3, -3, 6, 6);
  /* Only shapes manipulation via CornerItem's if the class is not a system library class
   * AND not an inherited shape
   * AND not a OMS connector i.e., input/output signals of fmu
   */
  if (!mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() &&
      !mpShapeAnnotation->isInheritedShape() &&
      !(mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS &&
        (mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getOMSConnector()
         || mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getOMSBusConnector()
         || mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getOMSTLMBusConnector()))) {
    connect(this, SIGNAL(cornerItemMoved(int,QPointF)), mpShapeAnnotation, SLOT(updateCornerItemPoint(int,QPointF)));
    connect(this, SIGNAL(cornerItemPress(int)), mpShapeAnnotation, SLOT(cornerItemPressed(int)));
    connect(this, SIGNAL(cornerItemRelease(bool)), mpShapeAnnotation, SLOT(cornerItemReleased(bool)));
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

  if (mpShapeAnnotation->getGraphicsView()->isRenderingLibraryPixmap()) {
    return;
  }
  QPen pen;
  if (mpShapeAnnotation->isInheritedShape()
      || (mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS
          && (mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getOMSConnector()
              || mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getOMSBusConnector()
              || mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getOMSTLMBusConnector()))) {
    pen.setColor(Qt::darkRed);
  } else {
    pen.setColor(Qt::red);
  }
  painter->setPen(pen);
  painter->setBrush(pen.color());
  painter->drawRect(mRectangle);
}

/*!
 * Reimplementation of mousePressEvent.\n
 * Emits the CornerItem::CornerItemPress SIGNAL. Stores the old position of the CornerItem.
 * \brief CornerItem::mousePressEvent
 * \param event - pointer to QGraphicsSceneMouseEvent
 */
void CornerItem::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
  if (event->button() == Qt::LeftButton && !mpShapeAnnotation->getGraphicsView()->isVisualizationView()) {
    if (!signalsBlocked()) {
      emit cornerItemPress(mConnectedPointIndex);
    }
    mOldScenePosition = scenePos();
  }
  QGraphicsItem::mousePressEvent(event);
}

/*!
 * \brief CornerItem::mouseMoveEvent
 * \param event
 * Reimplementation of mouseMoveEvent.\n
 * If CornerItem position has changed then emits the CornerItem::CornerItemMoved SIGNAL.
 */
void CornerItem::mouseMoveEvent(QGraphicsSceneMouseEvent *event)
{
  if (mpShapeAnnotation->isInheritedShape() && mpShapeAnnotation->getGraphicsView()->isVisualizationView()
      || (mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS
          && (mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getOMSConnector()
              || mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getOMSBusConnector()
              || mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getOMSTLMBusConnector()))) {
    QGraphicsItem::mouseMoveEvent(event);
    return;
  }
  /* if line is a connection or transition then make the first and last point non movable.
   * if line is initial state then make the first point non movable.
   */
  LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(mpShapeAnnotation);
  if (pLineAnnotation) {
    QList<QPointF> points = pLineAnnotation->getPoints();
    LineAnnotation::LineType lineType = pLineAnnotation->getLineType();
    if ((((lineType == LineAnnotation::ConnectionType || lineType == LineAnnotation::TransitionType) && (mConnectedPointIndex == 0 || mConnectedPointIndex == points.size() - 1))
         || (lineType == LineAnnotation::InitialStateType && mConnectedPointIndex == 0))) {
      QGraphicsItem::mouseMoveEvent(event);
      return;
    }
  }
  // indicates that user is dragging the resizer item
  if (mpShapeAnnotation->isCornerItemClicked()) {
    if (!signalsBlocked()) {
      QPointF positionDifference = mpShapeAnnotation->getGraphicsView()->movePointByGrid(event->scenePos() - scenePos());
      if (scenePos() != scenePos() + positionDifference) {
        emit cornerItemMoved(mConnectedPointIndex, scenePos() + positionDifference);
      }
    }
  }
  QGraphicsItem::mouseMoveEvent(event);
}

/*!
 * Reimplementation of mouseReleaseEvent.\n
 * Emits the CornerItem::CornerItemRelease SIGNAL.\n
 * Checks the CornerItem old position with the current position.
 * \brief CornerItem::mouseReleaseEvent
 * \param event - pointer to QGraphicsSceneMouseEvent
 */
void CornerItem::mouseReleaseEvent(QGraphicsSceneMouseEvent *event)
{
  QGraphicsItem::mouseReleaseEvent(event);
  if (event->button() == Qt::LeftButton && !mpShapeAnnotation->getGraphicsView()->isVisualizationView()) {
    if (!signalsBlocked()) {
      emit cornerItemRelease(mOldScenePosition != scenePos());
    }
  }
}

/*!
  \class ResizerItem
  \brief Represents a red rectangle box around the Component.
  */
/*!
  \param pComponent - pointer to Component.
  */
ResizerItem::ResizerItem(Element *pComponent)
  : QGraphicsItem(pComponent), mIsPressed(false)
{
  setZValue(2999);
  setFlags(QGraphicsItem::ItemIgnoresTransformations | QGraphicsItem::ItemIsSelectable);
  setCursor(Qt::ArrowCursor);
  setToolTip(Helper::clickAndDragToResize);
  mpComponent = pComponent;
  mActivePen = QPen(Qt::red);
  mInheritedActivePen = QPen(Qt::darkRed);
  mPassivePen = QPen(Qt::transparent);
  mRectangle = QRectF (-3, -3, 6, 6);
  mPen = mPassivePen;
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
  if (mpComponent->isInheritedComponent()
      || (mpComponent->getLibraryTreeItem() && mpComponent->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS
          && (mpComponent->getLibraryTreeItem()->getOMSConnector()
              || mpComponent->getLibraryTreeItem()->getOMSBusConnector()
              || mpComponent->getLibraryTreeItem()->getOMSTLMBusConnector()))) {
    mPen = mInheritedActivePen;
  } else {
    mPen = mActivePen;
  }
  setToolTip(Helper::clickAndDragToResize);
  setVisible(true);
}

/*!
  Sets the passive pen for drawing.
  \see setPassive();
  */
void ResizerItem::setPassive()
{
  mPen = mPassivePen;
  setToolTip("");
  setVisible(false);
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
  if (mpComponent->getGraphicsView()->isRenderingLibraryPixmap()) {
    return;
  }
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
  if (event->button() == Qt::LeftButton && !mpComponent->getGraphicsView()->isVisualizationView()) {
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
  // indicates that user is dragging the resizer item
  if (mIsPressed) {
    QPointF positionDifference = mpComponent->getGraphicsView()->movePointByGrid(event->scenePos() - scenePos());
    emit resizerItemMoved(scenePos() + positionDifference);
  }
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
  if (event->button() == Qt::LeftButton && !mpComponent->getGraphicsView()->isVisualizationView()) {
    mIsPressed = false;
    emit resizerItemReleased();
    if (mResizerItemOldPosition != mpComponent->getGraphicsView()->snapPointToGrid(event->scenePos())) {
      emit resizerItemPositionChanged();
    }
  }
}

/*!
  \class OriginItem
  \brief Represents a cross at the origin of the Component.
  */
/*!
  \param pComponent - pointer to Component.
  */
OriginItem::OriginItem(Element *pComponent)
{
  mpComponent = pComponent;
  mpShapeAnnotation = 0;
  initialize();
}

/*!
 * \brief OriginItem::OriginItem
 * \param pShapeAnnotation
 */
OriginItem::OriginItem(ShapeAnnotation *pShapeAnnotation)
{
  mpComponent = 0;
  mpShapeAnnotation = pShapeAnnotation;
  initialize();
}

/*!
 * \brief OriginItem::initialize
 */
void OriginItem::initialize()
{
  setZValue(3000);
  mActivePen = QPen(Qt::red, 2);
  mActivePen.setCosmetic(true);
  mInheritedActivePen = QPen(Qt::darkRed, 2);
  mInheritedActivePen.setCosmetic(true);
  mPassivePen = QPen(Qt::transparent);
  mRectangle = QRectF (-1.5, -1.5, 3, 3);
  mPen = mPassivePen;
}

/*!
 * \brief OriginItem::setActive
 * Sets the pen to active color.
 * Sets the zValue of item to 3000 so that it shows on top of everything.
 */
void OriginItem::setActive()
{
  setZValue(3000);
  if ((mpShapeAnnotation && mpShapeAnnotation->isInheritedShape())
      || (mpComponent && (mpComponent->isInheritedComponent()
                          || (mpComponent->getLibraryTreeItem() && mpComponent->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS
                              && (mpComponent->getLibraryTreeItem()->getOMSConnector()
                                  || mpComponent->getLibraryTreeItem()->getOMSBusConnector()
                                  || mpComponent->getLibraryTreeItem()->getOMSTLMBusConnector()))))) {
    mPen = mInheritedActivePen;
  } else {
    mPen = mActivePen;
  }
}

/*!
 * \brief OriginItem::setPassive
 * Sets the pen to passive color.
 * Sets the zValue of item to -3000 so that it shows on bottom of everything.
 */
void OriginItem::setPassive()
{
  setZValue(-3000);
  mPen = mPassivePen;
}

/*!
  Reimplementation of paint.\n
  Draws the cross shape for the OriginItem.
  \param painter - pointer to QPainter
  \param option - pointer to QStyleOptionGraphicsItem
  \param widget - pointer to QWidget
  */
void OriginItem::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(option);
  Q_UNUSED(widget);
  if ((mpShapeAnnotation && mpShapeAnnotation->getGraphicsView() && mpShapeAnnotation->getGraphicsView()->isRenderingLibraryPixmap())
      || (mpComponent && mpComponent->getGraphicsView() && mpComponent->getGraphicsView()->isRenderingLibraryPixmap())) {
    return;
  }
  painter->setRenderHint(QPainter::Antialiasing);
  painter->setPen(mPen);
  // draw horizontal Line
  painter->drawLine(-1, 0, 1, 0);
  // draw vertical Line
  painter->drawLine(0, -1, 0, 1);
}
