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

#ifndef CORNERITEM_H
#define CORNERITEM_H

#include <QtCore>
#include <QtGui>
#include "ProjectTabWidget.h"

class GraphicsScene;
class GraphicsView;

//class for Icon Selection Box
class CornerItem : public QObject, public QGraphicsItem
{
    Q_OBJECT
    Q_INTERFACES(QGraphicsItem)
private:
    GraphicsScene *mpGraphicsScene;
    GraphicsView *mpGraphicsView;
    QVector<QPointF> mLines;
    QRectF mRectangle;
    QPen mPen;
    QPen mActivePen;
    QPen mHoverPen;
    bool mItemClicked;
    QPointF mClickPos;
    Qt::Corner mCorner;
    qreal mScaleIncrementBy;
    qreal mScaleDecrementBy;
public:
    CornerItem(qreal x, qreal y, Qt::Corner corner, GraphicsScene *graphicsScene, GraphicsView *graphicsView, QGraphicsItem *parent = 0);
    void updateCornerItem(qreal x, qreal y, Qt::Corner corner);
    void setActive();
    void setPassive();
    void setHovered();
    QRectF boundingRect() const;
    void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
    virtual void mousePressEvent(QGraphicsSceneMouseEvent *event);
    virtual void mouseMoveEvent(QGraphicsSceneMouseEvent *event);
    virtual void mouseReleaseEvent(QGraphicsSceneMouseEvent *event);
signals:
    void iconSelected();
    void iconResized(qreal resizeFactorX, qreal resizeFactorY);
};

#endif // CORNERITEM_H
