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

#ifndef ANNOTATIONS_H
#define ANNOTATIONS_H

#include <QtCore>
#include <QtGui>

#include "OMCProxy.h"
#include "CornerItem.h"

class OMCProxy;
class GraphicsScene;
class GraphicsView;
class CornerItem;

// Base class for all shapes annotations
class ShapeAnnotation : public QObject, public QGraphicsItem
{
public:
    ShapeAnnotation(QGraphicsItem *parent = 0);
protected:
    qreal mScaleX;
    qreal mScaleY;
};

// Class for Line Annotation
class LineAnnotation : public ShapeAnnotation
{
private:
    QColor mLineColor;
    qreal mThickness;
    bool mSmooth;
    bool mVisible;
    QList<QPointF> mPoints;
    QMap<QString, Qt::PenStyle> mLinePatternsMap;
    Qt::PenStyle mLinePattern;
public:
    LineAnnotation(QString shape, QGraphicsItem *parent = 0);
    QRectF boundingRect() const;
    void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
    void drawLineAnnotaion(QPainter *painter);
};

// Class for Polygon Annotation
class PolygonAnnotation : public ShapeAnnotation
{
private:
    bool mVisible;
    QColor mLineColor;
    QColor mFillColor;
    QMap<QString, Qt::PenStyle> mLinePatternsMap;
    Qt::PenStyle mLinePattern;
    QMap<QString, Qt::BrushStyle> mFillPatternsMap;
    Qt::BrushStyle mFillPattern;
    qreal mThickness;
    QMap<QString, Qt::BrushStyle> mBorderPatternsMap;
    Qt::BrushStyle mBorderPattern;
    QList<QPointF> mPoints;
    bool mSmooth;
public:
    PolygonAnnotation(QString shape, QGraphicsItem *parent = 0);
    QRectF boundingRect() const;
    void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
};

// Class for Rectangle Annotation
class RectangleAnnotation : public ShapeAnnotation
{
private:
    bool mVisible;
    QColor mLineColor;
    QColor mFillColor;
    QMap<QString, Qt::PenStyle> mLinePatternsMap;
    Qt::PenStyle mLinePattern;
    QMap<QString, Qt::BrushStyle> mFillPatternsMap;
    Qt::BrushStyle mFillPattern;
    qreal mThickness;
    QMap<QString, Qt::BrushStyle> mBorderPatternsMap;
    Qt::BrushStyle mBorderPattern;
    QList<QPointF> mExtent;
    qreal mCornerRadius;
public:
    RectangleAnnotation(QString shape, QGraphicsItem *parent = 0);
    QRectF boundingRect() const;
    void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
};

// Class for Ellipse Annotation
class EllipseAnnotation : public ShapeAnnotation
{
private:
    bool mVisible;
    QColor mLineColor;
    QColor mFillColor;
    QMap<QString, Qt::PenStyle> mLinePatternsMap;
    Qt::PenStyle mLinePattern;
    QMap<QString, Qt::BrushStyle> mFillPatternsMap;
    Qt::BrushStyle mFillPattern;
    qreal mThickness;
    QList<QPointF> mExtent;
public:
    EllipseAnnotation(QString shape, QGraphicsItem *parent = 0);
    QRectF boundingRect() const;
    void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
};

// Class for Text Annotation
class TextAnnotation : public ShapeAnnotation
{
private:
    bool mVisible;
    QColor mLineColor;
    QColor mFillColor;
    QMap<QString, Qt::PenStyle> mLinePatternsMap;
    Qt::PenStyle mLinePattern;
    QMap<QString, Qt::BrushStyle> mFillPatternsMap;
    Qt::BrushStyle mFillPattern;
    qreal mThickness;
    QList<QPointF> mExtent;
    QString mTextString;
    int mFontSize;
    QString mFontName;
    int mFontWeight;
    bool mFontItalic;
    int mDefaultFontSize;
public:
    TextAnnotation(QString shape, QGraphicsItem *parent = 0);
    QRectF boundingRect() const;
    void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
};

//class for Components Annotation
class ComponentAnnotation : public ShapeAnnotation
{
    Q_OBJECT
private:
    QLineF line;
    QString className;
    QRectF mRectangle;
    OMCProxy *mpOMCProxy;
    GraphicsScene *mpGraphicsScene;
    GraphicsView *mpGraphicsView;
    bool mVisible;
    qreal mPositionX;
    qreal mPositionY;
    qreal mScale;
    qreal mAspectRatio;
    bool mFlipHorizontal;
    bool mFlipVertical;
    qreal mRotateAngle;
public:
    ComponentAnnotation(QString value, QString className, QString transformationStr, OMCProxy *omc, GraphicsScene *graphicsScene, GraphicsView *graphicsView, QGraphicsItem *parent = 0);
    void parseTransformationString(QString value);
    void parseIconAnnotationString(QString value);
    QRectF boundingRect() const;
    void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
    qreal getRotateAngle();
protected:
    virtual void mousePressEvent(QGraphicsSceneMouseEvent *event);
    virtual void mouseReleaseEvent(QGraphicsSceneMouseEvent *event);
signals:
    void componentClicked(ComponentAnnotation*);
};

// Class for Icon Annotation
class IconAnnotation : public ShapeAnnotation
{
    Q_OBJECT
private:
    QString mClassName;
    QRectF mRectangle;
    QPixmap mIconPixmap;
    OMCProxy *mpOMCProxy;
    GraphicsScene *mpGraphicsScene;
    GraphicsView *mpGraphicsView;
    CornerItem *mpTopLeftCornerItem;
    CornerItem *mpTopRightCornerItem;
    CornerItem *mpBottomLeftCornerItem;
    CornerItem *mpBottomRightCornerItem;
public:
    IconAnnotation(QString value, QString className, QPointF position, OMCProxy *omc, GraphicsScene *graphicsScene, GraphicsView *graphicsView);
    void parseIconAnnotationString(QString value);
    QRectF boundingRect() const;
    void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
    virtual void hoverEnterEvent(QGraphicsSceneHoverEvent *event);
    virtual void hoverLeaveEvent(QGraphicsSceneHoverEvent *event);
    virtual QVariant itemChange(GraphicsItemChange change, const QVariant &value);
    QPixmap getIcon();
    void getClassComponents(QString className);
    QList<QPointF> getBoundingRect();
    void setSelectionBoxActive();
    void setSelectionBoxPassive();
    void setSelectionBoxHover();
    void updateSelectionBox();
private slots:
    void showSelectionBox();
    void resizeIcon(qreal resizeFactorX, qreal resizeFactorY);
};

// Class for Diagram Annotation
class DiagramAnnotation : public ShapeAnnotation
{
private:
    QString className;
    QRect mRectangle;
    QPixmap mIconPixmap;
public:
    DiagramAnnotation(QString value, QString className);
    void parseDiagramAnnotationString(QString value);
    QRectF boundingRect() const;
    void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
};

#endif // ANNOTATIONS_H
