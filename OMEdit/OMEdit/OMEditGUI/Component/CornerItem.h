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

#ifndef CORNERITEM_H
#define CORNERITEM_H

#include "Annotations/ShapeAnnotation.h"
#include <QObject>
#include <QGraphicsItem>
#include <QPen>
#include <QGraphicsSceneMouseEvent>

class CornerItem : public QObject, public QGraphicsItem
{
  Q_OBJECT
  Q_INTERFACES(QGraphicsItem)
private:
  ShapeAnnotation *mpShapeAnnotation;
  QRectF mRectangle;
  QString mOldAnnotation;
  QPointF mClickPos;
  int mConnectedPointIndex;
public:
  CornerItem(qreal x, qreal y, int connectedPointIndex, ShapeAnnotation *pParent);
  void setConnectedPointIndex(int connectedPointIndex) {mConnectedPointIndex = connectedPointIndex;}
  int getConnectetPointIndex() {return mConnectedPointIndex;}
  QRectF boundingRect() const;
  void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
signals:
  void cornerItemMoved(int index, QPointF point);
  void cornerItemPress();
  void cornerItemRelease();
  void cornerItemPositionChanged();
protected:
  virtual void mousePressEvent(QGraphicsSceneMouseEvent *event);
  virtual void mouseReleaseEvent(QGraphicsSceneMouseEvent *event);
  QVariant itemChange(GraphicsItemChange change, const QVariant &value);
};

class ResizerItem : public QObject, public QGraphicsItem
{
  Q_OBJECT
  Q_INTERFACES(QGraphicsItem)
public:
  enum ResizePositions {None, BottomLeft, TopLeft, TopRight, BottomRight};
  ResizerItem(Component *pComponent);
  void setResizePosition(ResizePositions position);
  ResizePositions getResizePosition();
  void setActive();
  void setPassive();
  QRectF boundingRect() const;
  void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
  bool isPressed();
private:
  Component *mpComponent;
  QRectF mRectangle;
  QPen mPen;
  QPen mActivePen;
  QPen mInheritedActivePen;
  QPen mPassivePen;
  bool mIsPressed;
  QPointF mResizerItemOldPosition;
  ResizePositions mResizeposition;
signals:
  void resizerItemPressed(ResizerItem *pResizerItem);
  void resizerItemMoved(QPointF newPosition);
  void resizerItemReleased();
  void resizerItemPositionChanged();
protected:
  virtual void mousePressEvent(QGraphicsSceneMouseEvent *event);
  virtual void mouseMoveEvent(QGraphicsSceneMouseEvent *event);
  virtual void mouseReleaseEvent(QGraphicsSceneMouseEvent *event);
};

class OriginItem : public QGraphicsItem
{
public:
  OriginItem(Component *pComponent);
  void setActive();
  void setPassive();
  QRectF boundingRect() const {return mRectangle;}
  void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
private:
  Component *mpComponent;
  QRectF mRectangle;
  QPen mPen;
  QPen mActivePen;
  QPen mInheritedActivePen;
  QPen mPassivePen;
};

#endif // CORNERITEM_H
