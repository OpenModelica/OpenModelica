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

#ifndef CONNECTORWIDGET_H
#define CONNECTORWIDGET_H

#include <QtCore>
#include <QtGui>
#include "Annotations.h"

class ConnectorLine;
class GraphicsView;
class ComponentAnnotation;

class Connector : public QGraphicsWidget
{
    Q_OBJECT
public:
    Connector(ComponentAnnotation *pComponent, GraphicsView *parentView, QGraphicsItem *parent = 0);

    enum geometryType {VERTICAL, HORIZONTAL, DIAGONAL};
    GraphicsView *mpParentGraphicsView;

    void addPoint(QPointF point);
    void setStartComponent(ComponentAnnotation *pComponent);
    void setEndComponent(ComponentAnnotation *pCompoent);
    int getNumberOfLines();
    Connector::geometryType getGeometry(int lineNumber);
    ComponentAnnotation* getStartComponent();
    ComponentAnnotation* getEndComponent();
    ConnectorLine* getLine(int line);
    bool isActive();
private:
    ConnectorLine *mpConnectorLine;
    ComponentAnnotation *mpStartComponent;
    ComponentAnnotation *mpEndComponent;
    QVector<ConnectorLine*> mpLines;
    QVector<QPointF> mPoints;
    QVector<geometryType> mGeometries;
    bool mEndComponentConnected;
    bool mIsActive;
signals:
    void endComponentConnected();
public slots:
    void drawConnector();
    void updateStartPoint(QPointF point);
    void updateEndPoint(QPointF point);
    void moveAllPoints(qreal offsetX, qreal offsetY);
    void updateLine(int);
    void doSelect(bool lineSelected, int lineNumber);
    void setActive();
    void setPassive();
    void setHovered();
    void setUnHovered();
};

class ConnectorLine : public QObject, public QGraphicsLineItem
{
    Q_OBJECT
private:

public:
    ConnectorLine(qreal x1, qreal y1, qreal x2, qreal y2, int lineNumber, Connector *parent = 0);

    Connector *mpParentConnector;
    QPointF startPos;
    QPointF endPos;

    void paint(QPainter *p, const QStyleOptionGraphicsItem *o, QWidget *w);
    void setActive();
    void setPassive();
    void setHovered();
    void setLine(QPointF pos1, QPointF pos2);
    int getLineNumber();
public slots:
    void setConnected();
signals:
    void lineClicked();
    void lineMoved(int);
    void lineHoverEnter();
    void lineHoverLeave();
    void lineSelected(bool isSelected, int lineNumber);
protected:
    virtual void mousePressEvent(QGraphicsSceneMouseEvent *event);
    virtual void mouseReleaseEvent(QGraphicsSceneMouseEvent *event);
    virtual void hoverEnterEvent(QGraphicsSceneHoverEvent *event);
    virtual void hoverLeaveEvent(QGraphicsSceneHoverEvent *event);
    virtual QVariant itemChange(GraphicsItemChange change, const QVariant &value);
private:
    bool mIsActive;
    bool mParentConnectorEndComponentConnected;
    int mLineNumber;
    QPointF mOldPos;
    QPen mActivePen;
    QPen mPassivePen;
    QPen mHoverPen;
};

#endif // CONNECTORWIDGET_H
