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
    void addPoint(QPointF point);
    void setStartComponent(ComponentAnnotation *pComponent);
    void setEndComponent(ComponentAnnotation *pCompoent);
    int getNumberOfLines();
    ComponentAnnotation *getStartComponent();
    ComponentAnnotation *getEndComponent();

    GraphicsView *mpParentGraphicsView;
    enum geometryType {VERTICAL, HORIZONTAL, DIAGONAL};
private:
    ConnectorLine *mpConnectorLine;
    ComponentAnnotation *mpStartComponent;
    ComponentAnnotation *mpEndComponent;
    QVector<ConnectorLine*> mpLines;
    QVector<QPointF> mPoints;
    QVector<geometryType> mGeometries;
public slots:
    void drawConnector();
    void updateStartPoint(QPointF point);
    void updateEndPoint(QPointF point);
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
};

#endif // CONNECTORWIDGET_H
