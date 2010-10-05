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

#ifndef ICONANNOTATION_H
#define ICONANNOTATION_H

#include "ShapeAnnotation.h"
#include "ProjectTabWidget.h"
#include "OMCProxy.h"
#include "CornerItem.h"
#include "ConnectorWidget.h"
#include "LineAnnotation.h"
#include "PolygonAnnotation.h"
#include "RectangleAnnotation.h"
#include "EllipseAnnotation.h"
#include "TextAnnotation.h"

class OMCProxy;
class GraphicsScene;
class GraphicsView;
class CornerItem;
class Connector;
class LineAnnotation;
class PolygonAnnotation;
class RectangleAnnotation;
class EllipseAnnotation;
class TextAnnotation;

class IconAnnotation : public ShapeAnnotation
{
    Q_OBJECT
private:
    QString mIconAnnotationString;
    QString mName;
    QString mClassName;
    QRectF mRectangle;
    QPixmap mIconPixmap;
    CornerItem *mpTopLeftCornerItem;
    CornerItem *mpTopRightCornerItem;
    CornerItem *mpBottomLeftCornerItem;
    CornerItem *mpBottomRightCornerItem;
public:
    IconAnnotation(QString value, QString name, QString className, QPointF position, OMCProxy *omc,
                   GraphicsScene *graphicsScene, GraphicsView *graphicsView);
    IconAnnotation(const IconAnnotation *icon, QString name, QPointF position, GraphicsScene *graphicsScene,
                   GraphicsView *graphicsView);
    ~IconAnnotation();

    OMCProxy *mpOMCProxy;
    GraphicsScene *mpGraphicsScene;
    GraphicsView *mpGraphicsView;

    void parseIconAnnotationString(QGraphicsItem *item, QString value);
    QRectF boundingRect() const;
    void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
    virtual void hoverEnterEvent(QGraphicsSceneHoverEvent *event);
    virtual void hoverLeaveEvent(QGraphicsSceneHoverEvent *event);
    virtual QVariant itemChange(GraphicsItemChange change, const QVariant &value);
    QPixmap getIcon();
    QString getName();
    QString getClassName();
    void getClassComponents(QString className);
    QList<QPointF> getBoundingRect();
    void createSelectionBox();
    void setSelectionBoxActive();
    void setSelectionBoxPassive();
    void setSelectionBoxHover();
    void updateSelectionBox();
    void addConnector(Connector *item);
signals:
    void componentMoved();
    void componentDeleted();
    void componentSelected();
public slots:
    void showSelectionBox();
    void resizeIcon(qreal resizeFactorX, qreal resizeFactorY);
    void deleteMe();
    void moveUp();
    void moveDown();
    void moveLeft();
    void moveRight();
};

#endif // ICONANNOTATION_H
