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

/*
 * HopsanGUI
 * Fluid and Mechatronic Systems, Department of Management and Engineering, Linkoping University
 * Main Authors 2009-2010:  Robert Braun, Bjorn Eriksson, Peter Nordin
 * Contributors 2009-2010:  Mikael Axin, Alessandro Dell'Amico, Karl Pettersson, Ingo Staack
 */

#ifndef CONNECTORWIDGET_H
#define CONNECTORWIDGET_H

#include <QtCore>
#include <QtGui>
//#include "Component.h"

class ConnectorLine;
class GraphicsView;
class Component;
class ConnectorArrayMenu;

class Connector : public QGraphicsWidget
{
    Q_OBJECT
public:
    Connector(Component *pComponent, GraphicsView *pParentView, QGraphicsItem *pParent = 0);
    Connector(Component *pStartPort, Component *pEndPort, GraphicsView *pParentView, QVector<QPointF> points,
              QGraphicsItem *pParent = 0);

    enum geometryType {VERTICAL, HORIZONTAL, DIAGONAL};
    GraphicsView *mpParentGraphicsView;
    QVector<ConnectorLine*> mpLines;
    ConnectorArrayMenu *mpConnectorArrayMenu;
    void addPoint(QPointF point);
    void setStartComponent(Component *pComponent);
    void setEndComponent(Component *pComponent);
    void setEndConnectorisArray(bool isArray);
    void setStartConnectorisArray(bool isArray);
    int getNumberOfLines();
    Connector::geometryType getGeometry(int lineNumber);
    Component* getStartComponent();
    Component* getEndComponent();
    bool getEndConnectorisArray();
    bool getStartConnectorisArray();
    ConnectorLine* getLine(int line);
    bool isActive();
private:
    ConnectorLine *mpConnectorLine;
    Component *mpStartComponent;
    bool mEndConnectorIsArray;
    bool mStartConnectorIsArray;
    Component *mpEndComponent;
    QVector<QPointF> mPoints;
    QVector<geometryType> mGeometries;
    bool mEndComponentConnected;
    bool mIsActive;
signals:
    void endComponentConnected();
public slots:
    void drawConnector(bool isRotated = false);
    void updateStartPoint(QPointF point);
    void updateEndPoint(QPointF point);
    void moveAllPoints(qreal offsetX, qreal offsetY);
    void updateLine(int);
    void doSelect(bool lineSelected, int lineNumber);
    void setActive();
    void setPassive();
    void setHovered();
    void setUnHovered();
    void deleteMe();
    void updateConnectionAnnotationString();
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
    bool isMousePressed;
    QPointF mOldPosition;

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
    virtual void contextMenuEvent(QGraphicsSceneContextMenuEvent *event);
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

class ConnectorArrayMenu : public QDialog
{
    Q_OBJECT
public:
    ConnectorArrayMenu(Connector *pConnector, QWidget *pParent = 0);
    Connector *mpConnector;
    ~ConnectorArrayMenu();
    void show();
   // void setText(QString text);
private:
    QLabel *mpLabel;
    QLabel *mpStartIndexLabel;
    QLabel *mpEndIndexLabel;
    QString mEndConnectorIndex;
    QString mStartConnectorIndex;
    QLineEdit *mpStartIndexTextBox;
    QLineEdit *mpEndIndexTextBox;
    QPushButton *mpCancelButton;
    QPushButton *mpOkButton;
    QDialogButtonBox *mpButtonBox;
    bool mStartArrayExist;
    bool mEndArrayExist;
public slots:
    QString getEndConnectorIndex();
    void setEndConnectorIndex(QString connectorIndex);
    QString getStartConnectorIndex();
    void setStartConnectorIndex(QString connectorIndex);
    void addIndex();
    void reject();
};

#endif // CONNECTORWIDGET_H
