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

#ifndef SHAPEANNOTATION_H
#define SHAPEANNOTATION_H

#include <QtCore>
#include <QtGui>

#include "StringHandler.h"

class GraphicsView;
class RectangleCornerItem;

// Base class for all shapes annotations
class ShapeAnnotation : public QObject, public QGraphicsItem
{
    Q_OBJECT
    Q_INTERFACES(QGraphicsItem)
public:
    ShapeAnnotation(QGraphicsItem *parent = 0);
    ShapeAnnotation(GraphicsView *graphicsView, QGraphicsItem *parent = 0);
    ~ShapeAnnotation();
    void initializeFields();
    void setSelectionBoxActive();
    void setSelectionBoxPassive();
    void setSelectionBoxHover();
    virtual QString getShapeAnnotation();

    GraphicsView *mpGraphicsView;
signals:
   void updateShapeAnnotation();
public slots:
    void deleteMe();
    void doSelect();
    void doUnSelect();
    void moveUp();
    void moveDown();
    void moveLeft();
    void moveRight();
    void rotateClockwise();
    void rotateAntiClockwise();
    void resetRotation();
protected:
    bool mVisible;
    QPointF mOrigin;
    qreal mRotation;
    QColor mLineColor;
    QColor mFillColor;
    QMap<QString, Qt::PenStyle> mLinePatternsMap;
    Qt::PenStyle mLinePattern;
    QMap<QString, Qt::BrushStyle> mFillPatternsMap;
    Qt::BrushStyle mFillPattern;
    qreal mThickness;
    QMap<QString, Qt::BrushStyle> mBorderPatternsMap;
    Qt::BrushStyle mBorderPattern;
    QVector<QPointF> mPoints;
    QList<QPointF> mExtent;
    qreal mCornerRadius;
    bool mSmooth;

    QList<RectangleCornerItem*> mRectangleCornerItemsList;
    bool mIsCustomShape;
    bool mIsFinishedCreatingShape;
    bool mIsRectangleCorneItemClicked;
    bool mIsItemClicked;
    QPointF mClickPos;

    virtual void hoverEnterEvent(QGraphicsSceneHoverEvent *event);
    virtual void hoverLeaveEvent(QGraphicsSceneHoverEvent *event);
    virtual void mousePressEvent(QGraphicsSceneMouseEvent *event);
    virtual void mouseReleaseEvent(QGraphicsSceneMouseEvent *event);
    virtual QVariant itemChange(GraphicsItemChange change, const QVariant &value);
};

#endif // SHAPEANNOTATION_H
