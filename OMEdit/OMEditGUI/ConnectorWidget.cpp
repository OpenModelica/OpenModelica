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
    this->scale(Helper::globalXScale, Helper::globalYScale);
    setZValue(-1.0);
    this->updateStartPoint(mpStartComponent->mapToScene(mpStartComponent->boundingRect().center()));
    this->mEndComponentConnected = false;
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
    this->mEndComponentConnected = true;
    this->mpEndComponent = pCompoent;

    //Make all lines selectable and all lines except first and last movable
    if(mpLines.size() > 1)
    {
        for(std::size_t i=1; i!=mpLines.size()-1; ++i)
            mpLines[i]->setFlag(QGraphicsItem::ItemIsMovable, true);
    }
    for(std::size_t i=0; i!=mpLines.size(); ++i)
        mpLines[i]->setFlag(QGraphicsItem::ItemIsSelectable, true);

    emit endComponentConnected();
    //this->setPassive();
}

//! Returns the number of lines in a connector.
int Connector::getNumberOfLines()
{
    return mpLines.size();
}

//! Returns the geometry type of the specified line.
//! @param lineNumber is the number of the specified line in the mpLines vector.
Connector::geometryType Connector::getGeometry(int lineNumber)
{
    return mGeometries[lineNumber];
}

ComponentAnnotation* Connector::getStartComponent()
{
    return mpStartComponent;
}

ComponentAnnotation* Connector::getEndComponent()
{
    return mpEndComponent;
}

//! Returns the line with specified number.
//! @param line is the number of the wanted line.
//! @see getThirdLastLine()
//! @see getSecondLastLine()
//! @see getLastLine()
ConnectorLine* Connector::getLine(int line)
{
    return mpLines[line];
}

//! Returns true if the connector is active ("selected").
bool Connector::isActive()
{
    return mIsActive;
}

void Connector::drawConnector()
{
    if (!mEndComponentConnected)
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
                mpConnectorLine->setPassive();
                connect(mpConnectorLine,SIGNAL(lineSelected(bool, int)),this,SLOT(doSelect(bool, int)));
                connect(mpConnectorLine,SIGNAL(lineMoved(int)),this, SLOT(updateLine(int)));
                connect(mpConnectorLine,SIGNAL(lineHoverEnter()),this,SLOT(setHovered()));
                connect(mpConnectorLine,SIGNAL(lineHoverLeave()),this,SLOT(setUnHovered()));
                connect(this,SIGNAL(endComponentConnected()),mpConnectorLine,SLOT(setConnected()));
                mpLines.push_back(mpConnectorLine);
            }
        }
        if(!mEndComponentConnected && mpLines.size() > 1)
        {
            mpLines.back()->setActive();
            mpLines[mpLines.size()-2]->setPassive();
        }
    }
    else
    {
        if (mpStartComponent->getParentIcon()->isSelected() && mpEndComponent->getParentIcon()->isSelected())
        {
            //Both components and connector are selected, so move whole connector along with components
            moveAllPoints(getStartComponent()->mapToScene(getStartComponent()->boundingRect().center()).x()-mPoints[0].x(),
                          getStartComponent()->mapToScene(getStartComponent()->boundingRect().center()).y()-mPoints[0].y());
        }
        else
        {
            //Retrieve start and end points from ports in case components have moved
            updateStartPoint(getStartComponent()->mapToScene(getStartComponent()->boundingRect().center()));
            updateEndPoint(getEndComponent()->mapToScene(getEndComponent()->boundingRect().center()));
        }

        //Redraw the lines based on the mPoints vector
        for(int i = 0; i != mPoints.size()-1; ++i)
        {
            mpLines[i]->setLine(mapFromScene(mPoints[i]), mapFromScene(mPoints[i+1]));
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
        if(mGeometries[0] == Connector::HORIZONTAL)
            mPoints[1] = QPointF(mPoints[1].x(),mPoints[0].y());
        else if(mGeometries[0] == Connector::VERTICAL)
            mPoints[1] = QPointF(mPoints[0].x(),mPoints[1].y());
    }
}

//! Updates the last point of the connector, and adjusts the second last point accordingly depending on the geometry vector.
//! @param point is the new start point.
//! @see updateEndPoint(QPointF point)
void Connector::updateEndPoint(QPointF point)
{
    mPoints.back() = point;
    if(mGeometries.back() == Connector::HORIZONTAL)
        mPoints[mPoints.size()-2] = QPointF(mPoints[mPoints.size()-2].x(),point.y());
    else if(mGeometries.back() == Connector::VERTICAL)
        mPoints[mPoints.size()-2] = QPointF(point.x(),mPoints[mPoints.size()-2].y());
}

//! Updates the mPoints vector when a line has been moved. Used to make lines follow each other when they are moved, and to make sure horizontal lines can only move vertically and vice versa.
//! @param lineNumber is the number of the line that has moved.
void Connector::updateLine(int lineNumber)
{
   if ((mEndComponentConnected) && (lineNumber != 0) && (lineNumber != int(mpLines.size())))
    {
        if(mGeometries[lineNumber] == Connector::HORIZONTAL)
        {
            mPoints[lineNumber] = QPointF(mPoints[lineNumber].x(), getLine(lineNumber)->mapToScene(getLine(lineNumber)->line().p1()).y());
            mPoints[lineNumber+1] = QPointF(mPoints[lineNumber+1].x(), getLine(lineNumber)->mapToScene(getLine(lineNumber)->line().p2()).y());
        }
        else if (mGeometries[lineNumber] == Connector::VERTICAL)
        {
            mPoints[lineNumber] = QPointF(getLine(lineNumber)->mapToScene(getLine(lineNumber)->line().p1()).x(), mPoints[lineNumber].y());
            mPoints[lineNumber+1] = QPointF(getLine(lineNumber)->mapToScene(getLine(lineNumber)->line().p2()).x(), mPoints[lineNumber+1].y());
        }
    }
    drawConnector();
}

void Connector::moveAllPoints(qreal offsetX, qreal offsetY)
{
    for(int i=0; i != mPoints.size(); ++i)
    {
        mPoints[i] = QPointF(mPoints[i].x()+offsetX, mPoints[i].y()+offsetY);
    }
}

//! Slot that activates or deactivates the connector if one of its lines is selected or deselected.
//! @param lineSelected tells whether the signal was induced by selection or deselection of a line.
//! @see setActive()
//! @see setPassive()
void Connector::doSelect(bool lineSelected, int lineNumber)
{
    if(this->mEndComponentConnected)     //Non-finished lines shall not be selectable
    {
        if(lineSelected)
        {
            this->setActive();
            for (int i=0; i != mpLines.size(); ++i)
            {
               if(i != (std::size_t)lineNumber)     //I think this means that only one line in a connector can be selected at one time
                   mpLines[i]->setSelected(false);
            }
        }
        else
        {
            bool noneSelected = true;
            for (int i=0; i != mpLines.size(); ++i)
            {
               if(mpLines[i]->isSelected())
                {
                   noneSelected = false;
               }
            }
            if(noneSelected)
            {
                this->setPassive();
            }
       }
    }
}

//! Activates a connector, activates each line and connects delete function with delete key.
//! @see setPassive()
void Connector::setActive()
{
    //connect(this->mpParentGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()));
    if(this->mEndComponentConnected)
    {
        mIsActive = true;
        for (std::size_t i=0; i!=mpLines.size(); ++i )
        {
            mpLines[i]->setActive();
        }
    }
}

//! Deactivates a connector, deactivates each line and disconnects delete function with delete key.
//! @see setActive()
void Connector::setPassive()
{
    //disconnect(this->mpParentGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()));
    if(this->mEndComponentConnected)
    {
        mIsActive = false;
        for (std::size_t i=0; i!=mpLines.size(); ++i )
        {
            mpLines[i]->setPassive();
            //mpLines[i]->setSelected(false);       //OBS! Kanske inte blir bra...
        }
    }
}

//! Changes connector style to hovered if it is not active. Used when mouse starts hovering a line.
//! @see setUnHovered()
void Connector::setHovered()
{
    if(this->mEndComponentConnected && !this->mIsActive)
    {
        for (std::size_t i=0; i!=mpLines.size(); ++i )
        {
            mpLines[i]->setHovered();
        }
    }
}

//! Changes connector style back to normal if it is not active. Used when mouse stops hovering a line.
//! @see setHovered()
//! @see setPassive()
void Connector::setUnHovered()
{
    if(this->mEndComponentConnected && !this->mIsActive)
    {
        for (std::size_t i=0; i!=mpLines.size(); ++i )
        {
            mpLines[i]->setPassive();
        }
    }
}

ConnectorLine::ConnectorLine(qreal x1, qreal y1, qreal x2, qreal y2, int lineNumber, Connector *parent)
    : QGraphicsLineItem(x1, y1, x2, y2, parent)
{
    mpParentConnector = parent;
    setFlags(QGraphicsItem::ItemSendsGeometryChanges | QGraphicsItem::ItemUsesExtendedStyleOption);
    this->setAcceptHoverEvents(true);
    this->startPos = QPointF(x1,y1);
    this->endPos = QPointF(x2,y2);
    this->mLineNumber = lineNumber;
    this->mParentConnectorEndComponentConnected = false;
    this->mActivePen = QPen(Qt::red, 5.7);
    this->mPassivePen = QPen(Qt::black, 5.7);
    this->mHoverPen = QPen(Qt::darkRed, 6.0);
}

//! Reimplementation of paint function. Removes the ugly dotted selection box.
void ConnectorLine::paint(QPainter *p, const QStyleOptionGraphicsItem *o, QWidget *w)
{
    QStyleOptionGraphicsItem *_o = const_cast<QStyleOptionGraphicsItem*>(o);
    _o->state &= ~QStyle::State_Selected;
    QGraphicsLineItem::paint(p,_o,w);
}

//! Changes the style of the line to active.
//! @see setPassive()
//! @see setHovered()
void ConnectorLine::setActive()
{
    this->setPen(mActivePen);
}

//! Changes the style of the line to default.
//! @see setActive()
//! @see setHovered()
void ConnectorLine::setPassive()
{
    this->setPen(mPassivePen);
}

//! Changes the style of the line to hovered.
//! @see setActive()
//! @see setPassive()
void ConnectorLine::setHovered()
{
    this->setPen(mHoverPen);
}

//! Defines what shall happen if a mouse key is pressed while hovering a connector line.
void ConnectorLine::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
    if(event->button() == Qt::LeftButton)
    {
        mOldPos = this->pos();
    }
    QGraphicsLineItem::mousePressEvent(event);
}

//! Defines what shall happen if a mouse key is released while hovering a connector line.
void ConnectorLine::mouseReleaseEvent(QGraphicsSceneMouseEvent *event)
{
//    if((this->pos() != mOldPos) and (event->button() == Qt::LeftButton))
//    {
//        mpParentGUIConnector->mpParentGraphicsView->undoStack->newPost();
//        mpParentGUIConnector->mpParentGraphicsView->undoStack->registerModifiedConnector(mOldPos, this->pos(), mpParentGUIConnector, getLineNumber());
//    }
    QGraphicsLineItem::mouseReleaseEvent(event);
}

//! Defines what shall happen if the mouse cursor enters the line. Change cursor if the line is movable.
//! @see hoverLeaveEvent(QGraphicsSceneHoverEvent *event)
void ConnectorLine::hoverEnterEvent(QGraphicsSceneHoverEvent *event)
{
    if(this->flags().testFlag((QGraphicsItem::ItemIsMovable)))
    {
        if(this->mParentConnectorEndComponentConnected && this->mpParentConnector->getGeometry(getLineNumber()) == Connector::VERTICAL)
        {
            this->setCursor(Qt::SizeHorCursor);
        }
        else if(this->mParentConnectorEndComponentConnected && this->mpParentConnector->getGeometry(getLineNumber()) == Connector::HORIZONTAL)
        {
            this->setCursor(Qt::SizeVerCursor);
        }
    }
    emit lineHoverEnter();
}

//! Defines what shall happen when mouse cursor leaves the line.
//! @see hoverEnterEvent(QGraphicsSceneHoverEvent *event)
void ConnectorLine::hoverLeaveEvent(QGraphicsSceneHoverEvent *event)
{
    emit lineHoverLeave();
}

//! Returns the number of the line in the connector.
int ConnectorLine::getLineNumber()
{
    return mLineNumber;
}

//! Defines what shall happen if the line is selected or moved.
QVariant ConnectorLine::itemChange(GraphicsItemChange change, const QVariant &value)
{
    if (change == QGraphicsItem::ItemSelectedHasChanged)
    {
         emit lineSelected(this->isSelected(), this->mLineNumber);
    }
    if (change == QGraphicsItem::ItemPositionHasChanged)
    {
        emit lineMoved(this->mLineNumber);
    }
    return value;
}

//! Tells the line that its parent connector has been connected at both ends
void ConnectorLine::setConnected()
{
    mParentConnectorEndComponentConnected = true;
}

//! Reimplementation of setLine; stores the start and end positions before changing them
//! @param x1 is the x-coordinate of the start position.
//! @param y1 is the y-coordinate of the start position.
//! @param x2 is the x-coordinate of the end position.
//! @param y2 is the y-coordinate of the end position.
void ConnectorLine::setLine(QPointF pos1, QPointF pos2)
{
    this->startPos = this->mapFromParent(pos1);
    this->endPos = this->mapFromParent(pos2);
    QGraphicsLineItem::setLine(this->mapFromParent(pos1).x(),this->mapFromParent(pos1).y(),
                               this->mapFromParent(pos2).x(),this->mapFromParent(pos2).y());
}
