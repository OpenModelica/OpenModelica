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

#include "ConnectorWidget.h"

Connector::Connector(ComponentAnnotation *pComponent, GraphicsView *parentView, QGraphicsItem *parent)
{
    Q_UNUSED(parent);
    this->mpParentGraphicsView = parentView;
    this->setStartComponent(pComponent);
    setFlags(QGraphicsItem::ItemIsFocusable);
    this->setPos(mpStartComponent->mapToScene(mpStartComponent->boundingRect().center()));
    this->updateStartPoint(mpStartComponent->mapToScene(mpStartComponent->boundingRect().center()));
    this->drawConnector();
}

void Connector::addPoint(QPointF point)
{
    //! @todo make it better
    mPoints.append(point);
    if(getNumberOfLines() == 0 && (fabs(mpStartComponent->getRotateAngle()) == 0 || fabs(mpStartComponent->getRotateAngle()) == 180))
    {
        mGeometries.push_back(Connector::HORIZONTAL);
    }
    else if(getNumberOfLines() == 0 && (fabs(mpStartComponent->getRotateAngle()) == 90 || fabs(mpStartComponent->getRotateAngle()) == 270))
    {
        mGeometries.push_back(Connector::VERTICAL);
    }
    else if(getNumberOfLines() != 0 && mGeometries.back() == Connector::HORIZONTAL)
    {
        mGeometries.push_back(Connector::VERTICAL);
    }
    else if(getNumberOfLines() != 0 && mGeometries.back() == Connector::VERTICAL)
    {
        mGeometries.push_back(Connector::HORIZONTAL);
    }
    else if(getNumberOfLines() != 0 && mGeometries.back() == Connector::DIAGONAL)
    {
        mGeometries.push_back(Connector::DIAGONAL);
        //Give new line correct angle!
    }
    if(mPoints.size() > 1)
        drawConnector();
}

void Connector::setStartComponent(ComponentAnnotation *pComponent)
{
    this->mpStartComponent = pComponent;
}

void Connector::setEndComponent(ComponentAnnotation *pCompoent)
{
    this->mpEndComponent = pCompoent;
}

//! Returns the number of lines in a connector.
int Connector::getNumberOfLines()
{
    return mpLines.size();
}

ComponentAnnotation* Connector::getStartComponent()
{
    return mpStartComponent;
}

ComponentAnnotation* Connector::getEndComponent()
{
    return mpEndComponent;
}

void Connector::drawConnector()
{
    //Remove all lines
    while(!mpLines.empty())
    {
        this->scene()->removeItem(mpLines.back());
        mpLines.pop_back();
    }
    mpLines.clear();

    if(mPoints.size() > 1)
    {
        for(int i = 0; i != mPoints.size()-1; ++i)
        {
            mpConnectorLine = new ConnectorLine(mapFromScene(mPoints[i]).x(), mapFromScene(mPoints[i]).y(),
                                                mapFromScene(mPoints[i+1]).x(), mapFromScene(mPoints[i+1]).y(),
                                                mpLines.size(), this);
            mpLines.push_back(mpConnectorLine);
        }
    }
    //Remove the extra lines if there are too many
    while(mPoints.size() < int(mpLines.size()+1))
    {
        delete(mpLines.back());
        mpLines.pop_back();
        this->scene()->update();
    }
}

//! Updates the first point of the connector, and adjusts the second point accordingly depending on the geometry vector.
//! @param point is the new start point.
//! @see updateEndPoint(QPointF point)
void Connector::updateStartPoint(QPointF point)
{
    if(mPoints.size() == 0)
        mPoints.push_back(point);
    else
        mPoints[0] = point;

    if(mPoints.size() != 1)
    {
        mPoints[1] = QPointF(mPoints[1].x(),mPoints[0].y());
    }
}

//! Updates the last point of the connector, and adjusts the second last point accordingly depending on the geometry vector.
//! @param point is the new start point.
//! @see updateEndPoint(QPointF point)
void Connector::updateEndPoint(QPointF point)
{
    mPoints.back() = point;
    // Check whether the second last line is vertical or horizontal?
//    if (mPoints[mPoints.size()-2].y() == mPoints[mPoints.size()-2].y()) // horizontal line
//        mPoints[mPoints.size()-2] = QPointF(point.x(),mPoints[mPoints.size()-2].y());
//    else if (mPoints[mPoints.size()-2].x() == mPoints[mPoints.size()-2].x()) // vertical line
//        mPoints[mPoints.size()-2] = QPointF(mPoints[mPoints.size()-2].x(), point.y());

    if(mGeometries.back() == Connector::HORIZONTAL)
        mPoints[mPoints.size()-2] = QPointF(mPoints[mPoints.size()-2].x(),point.y());
    else if(mGeometries.back() == Connector::VERTICAL)
        mPoints[mPoints.size()-2] = QPointF(point.x(),mPoints[mPoints.size()-2].y());
}

ConnectorLine::ConnectorLine(qreal x1, qreal y1, qreal x2, qreal y2, int lineNumber, Connector *parent)
    : QGraphicsLineItem(x1, y1, x2, y2, parent)
{
    mpParentConnector = parent;
    setFlags(QGraphicsItem::ItemSendsGeometryChanges | QGraphicsItem::ItemUsesExtendedStyleOption);
    this->startPos = QPointF(x1,y1);
    this->endPos = QPointF(x2,y2);
}
