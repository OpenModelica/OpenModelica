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

#include "ConnectorWidget.h"
#include "Component.h"

Connector::Connector(Component *pComponent, GraphicsView *pParentView, QGraphicsItem *pParent)
{
    Q_UNUSED(pParent);
    this->mpParentGraphicsView = pParentView;
    this->setStartComponent(pComponent);
    setFlags(QGraphicsItem::ItemIsFocusable);
    this->setPos(mpStartComponent->mapToScene(mpStartComponent->boundingRect().center()));
    this->scale(1.0, 1.0);
    setZValue(-1.0);
    this->updateStartPoint(mpStartComponent->mapToScene(mpStartComponent->boundingRect().center()));
    this->mEndComponentConnected = false;
    this->mStartConnectorIsArray=false;
    this->mEndConnectorIsArray=false;
    this->mIsActive = false;
    this->mpStartConnectorArrayMenu= new ConnectorArrayMenu(this,mpParentGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
    this->mpConnectorArrayMenu= new ConnectorArrayMenu(this,mpParentGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
    this->drawConnector();
}

//! Constructor used to create a whole connector at once. Used when loading models.
//! @param *pStartPort is a pointer to the start port.
//! @param *pEndPort is a pointer to the end port.
//! @param points is the point vector for the connector.
//! @param *pParentView is a pointer to the GraphicsView the connector belongs to.
//! @param *pParent is the parent of the port.
Connector::Connector(Component *pStartPort, Component *pEndPort, GraphicsView *pParentView, QVector<QPointF> points,
                     QGraphicsItem *pParent)
{
    Q_UNUSED(pParent);
    setFlags(QGraphicsItem::ItemIsFocusable);
    mpParentGraphicsView = pParentView;
    setStartComponent(pStartPort);
    setEndComponent(pEndPort);
    setPos(mpStartComponent->mapToScene(mpStartComponent->boundingRect().center()));
    scale(Helper::globalDiagramXScale, Helper::globalDiagramYScale);
    setZValue(-1.0);
    mPoints = points;

    //Setup the geometries vector based on the point geometry
    for(int i = 0 ; i < mPoints.size()-1 ; ++i)
    {
        if(mPoints[i].x() == mPoints[i+1].x())
            mGeometries.push_back(Connector::VERTICAL);
        else if(mPoints[i].y() == mPoints[i+1].y())
            mGeometries.push_back(Connector::HORIZONTAL);
        else
            mGeometries.push_back(Connector::DIAGONAL);
    }

    mEndComponentConnected = true;
    emit endComponentConnected();
    this->setPassive();
    if (mpEndComponent->mpParentComponent)
        connect(mpEndComponent->mpParentComponent, SIGNAL(componentDeleted()), SLOT(deleteMe()));
    else
        connect(mpEndComponent, SIGNAL(componentDeleted()), SLOT(deleteMe()));

    //Create the lines, so that drawConnector has something to work with
    for(int i = 0 ; i < mPoints.size()-1 ; ++i)
    {
        ConnectorLine *tempLine = new ConnectorLine(mapFromScene(mPoints[i]).x(), mapFromScene(mPoints[i]).y(),
                                                    mapFromScene(mPoints[i+1]).x(), mapFromScene(mPoints[i+1]).y(), i, this);

        mpLines.push_back(tempLine);
        tempLine->setConnected();
        tempLine->setPassive();
        connect(tempLine,SIGNAL(lineSelected(bool, int)),this,SLOT(doSelect(bool, int)));
        connect(tempLine,SIGNAL(lineMoved(int)),this, SLOT(updateLine(int)));
        connect(tempLine,SIGNAL(lineHoverEnter()),this,SLOT(setHovered()));
        connect(tempLine,SIGNAL(lineHoverLeave()),this,SLOT(setUnHovered()));
    }

    this->drawConnector();

    //Make all lines selectable and all lines except first and last movable
    for(int i = 1 ; i < mpLines.size() - 1 ; ++i)
        mpLines[i]->setFlag(QGraphicsItem::ItemIsMovable, true);
    for(int i = 0 ; i < mpLines.size() ; ++i)
        mpLines[i]->setFlag(QGraphicsItem::ItemIsSelectable, true);

    if (mpStartComponent->mpParentComponent)
        mpStartComponent->mpParentComponent->addConnector(this);
    else
        mpStartComponent->addConnector(this);

    if (mpEndComponent->mpParentComponent)
        mpEndComponent->mpParentComponent->addConnector(this);
    else
        mpEndComponent->addConnector(this);
}

void Connector::addPoint(QPointF point)
{
    //! @todo make it better
    mPoints.append(point);
    if(getNumberOfLines() == 0 && (fabs(mpStartComponent->mpTransformation->getRotateAngle()) == 0 || fabs(mpStartComponent->mpTransformation->getRotateAngle()) == 180))
    {
        mGeometries.push_back(Connector::HORIZONTAL);
    }
    else if(getNumberOfLines() == 0 && (fabs(mpStartComponent->mpTransformation->getRotateAngle()) == 90 || fabs(mpStartComponent->mpTransformation->getRotateAngle()) == 270))
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

void Connector::setStartComponent(Component *pComponent)
{
    this->mpStartComponent = pComponent;
}

void Connector::setEndComponent(Component *pComponent)
{
    this->mpEndComponent = pComponent;
    this->mEndComponentConnected = true;
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

void Connector::setEndConnectorisArray(bool isArray)
{
    this->mEndConnectorIsArray = isArray;
}

void Connector::setStartConnectorisArray(bool isArray)
{
    this->mStartConnectorIsArray = isArray;
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

Component* Connector::getStartComponent()
{
    return mpStartComponent;
}

Component* Connector::getEndComponent()
{
    return mpEndComponent;
}

bool Connector::getEndConnectorisArray()
{
    return mEndConnectorIsArray;
}

bool Connector::getStartConnectorisArray()
{
    return mStartConnectorIsArray;
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

void Connector::updateConnectionAnnotationString()
{
    // if no end component connected then just simply return;
    if (!getEndComponent())
        return;

    // create the annotation string
    QString annotationString = "annotate=Line(";

    // add the line points to annotation string
    QString pointsString;
    QStringList pointsList;
    annotationString.append("points={");
    foreach (QPointF point, mPoints)
    {
        pointsString.append("{").append(QString::number(point.x())).append(",");
        pointsString.append(QString::number(point.y())).append("}");
        pointsList.append(pointsString);
        pointsString.clear();
    }
    annotationString.append(pointsList.join(","));
    annotationString.append("}");

    //! @todo add the line color annotation
    //! @todo add the line pattern annotation
    //! @todo add the line thickness annotation
    //! @todo add the line smooth annotation
    //! @todo add the line arrow annotation
    //! @todo add the line visible annotation

    annotationString.append(")");

    QString startIconName, startIconCompName, endIconName, endIconCompName;
    if (getStartComponent()->mpParentComponent)
    {
        startIconName = QString(getStartComponent()->mpParentComponent->getName()).append(".");
        if(!this->getStartConnectorisArray())
        startIconCompName = getStartComponent()->mpComponentProperties->getName();
        else
        startIconCompName = getStartComponent()->mpComponentProperties->getName() + "[" + this->mpStartConnectorArrayMenu->getConnectorIndex() + "]";

    }
    else
    {

        if(!this->getStartConnectorisArray())
        startIconCompName = getStartComponent()->getName();
        else
        startIconCompName = getStartComponent()->getName() + "[" + this->mpStartConnectorArrayMenu->getConnectorIndex() + "]";

    }
    if (getEndComponent()->mpParentComponent)
    {
        endIconName = QString(getEndComponent()->mpParentComponent->getName()).append(".");
        if(!this->getEndConnectorisArray())
        endIconCompName = getEndComponent()->mpComponentProperties->getName();
        else
        endIconCompName = getEndComponent()->mpComponentProperties->getName() + "[" + this->mpConnectorArrayMenu->getConnectorIndex() + "]";
    }
    else
    {
        if(!this->getEndConnectorisArray())
        endIconCompName = getEndComponent()->getName();
        else
        endIconCompName = getEndComponent()->getName() + "[" + this->mpConnectorArrayMenu->getConnectorIndex() + "]";

    }
    // send the updateconnection command to omc
    MainWindow *pMainWindow = mpParentGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
    pMainWindow->mpOMCProxy->updateConnection(startIconName + startIconCompName, endIconName + endIconCompName,
                                              mpParentGraphicsView->mpParentProjectTab->mModelNameStructure, annotationString);
}

void Connector::drawConnector(bool isRotated)
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
                                                    mapFromScene(mPoints[i+1]).x(), mapFromScene(mPoints[i+1]).y(), i, this);
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
        if (isRotated)
        {
            //Retrieve start and end points from ports in case components have moved
            updateStartPoint(getStartComponent()->mapToScene(getStartComponent()->boundingRect().center()));
            updateEndPoint(getEndComponent()->mapToScene(getEndComponent()->boundingRect().center()));
        }
        else if (mpStartComponent->getParentComponent()->isSelected() && mpEndComponent->getParentComponent()->isSelected())
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
    connect(this->mpParentGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()));
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
    disconnect(this->mpParentGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()));
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

//! Asks my parent to delete myself.
void Connector::deleteMe()
{
    mpParentGraphicsView->removeConnector(this);
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
    this->mActivePen = QPen(Qt::red);
    this->mPassivePen = QPen(Qt::black);
    QPen pen (Qt::darkRed);
    pen.setWidth(3);
    pen.setCosmetic(true);
    this->mHoverPen = pen;
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
    isMousePressed = true;
    mOldPosition = pos();
    QGraphicsLineItem::mousePressEvent(event);
}

//! Defines what shall happen if a mouse key is released while hovering a connector line.
void ConnectorLine::mouseReleaseEvent(QGraphicsSceneMouseEvent *event)
{
    if (mOldPosition != pos())
    {
        mpParentConnector->updateConnectionAnnotationString();
        // update connectors annotations that are associated to this component
        ProjectTab *pProjectTab = mpParentConnector->mpParentGraphicsView->mpParentProjectTab;
        OMCProxy *pOMCProxy = mpParentConnector->mpParentGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy;
        pProjectTab->mpModelicaEditor->setText(pOMCProxy->list(pProjectTab->mModelNameStructure));
    }

    isMousePressed = false;
    QGraphicsLineItem::mouseReleaseEvent(event);
}

//! Defines what shall happen if the mouse cursor enters the line. Change cursor if the line is movable.
//! @see hoverLeaveEvent(QGraphicsSceneHoverEvent *event)
void ConnectorLine::hoverEnterEvent(QGraphicsSceneHoverEvent *event)
{
    Q_UNUSED(event);
    // if we are creating the connector then don't show selection box on hover events
    if (mpParentConnector->mpParentGraphicsView->mIsCreatingConnector)
    {
        return;
    }

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
    Q_UNUSED(event);
    emit lineHoverLeave();
}

//! Returns the number of the line in the connector.
int ConnectorLine::getLineNumber()
{
    return mLineNumber;
}

void ConnectorLine::contextMenuEvent(QGraphicsSceneContextMenuEvent *event)
{
    // make the connector selected
    this->setSelected(true);

    QMenu menu(mpParentConnector->mpParentGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
    mpParentConnector->mpParentGraphicsView->mpCancelConnectionAction->setText("Delete Connection");
    menu.addAction(mpParentConnector->mpParentGraphicsView->mpCancelConnectionAction);
    menu.exec(event->screenPos());
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
       if (!isMousePressed)
        {
            mpParentConnector->updateConnectionAnnotationString();
            // update connectors annotations that are associated to this component
            ProjectTab *pProjectTab = mpParentConnector->mpParentGraphicsView->mpParentProjectTab;
            OMCProxy *pOMCProxy = mpParentConnector->mpParentGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy;
            pProjectTab->mpModelicaEditor->setText(pOMCProxy->list(pProjectTab->mModelNameStructure));
        }
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


ConnectorArrayMenu::ConnectorArrayMenu(Connector *pConnector,QWidget *pParent)
    : QDialog(pParent, Qt::WindowTitleHint)
{
    mpConnector = pConnector;
    setMinimumSize(375, 140);
    //setModal(true);

    // Create the Text Box, File Dialog and Labels
    mpIndexLabel = new QLabel;
    mpIndexTextBox = new QLineEdit;


    // Create the buttons
    mpOkButton = new QPushButton(tr("OK"));
    mpOkButton->setAutoDefault(true);
    connect(mpOkButton, SIGNAL(pressed()), SLOT(addIndex()));
    mpCancelButton = new QPushButton(tr("Cancel"));
    mpCancelButton->setAutoDefault(false);
    connect(mpCancelButton, SIGNAL(pressed()), SLOT(reject()));

    mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
    mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
    mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);

    // Create a layout
    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->addWidget(mpIndexLabel, 0, 0);
    mainLayout->addWidget(mpIndexTextBox, 1, 0);

    mainLayout->addWidget(mpButtonBox, 4, 0);

    setLayout(mainLayout);
}

ConnectorArrayMenu::~ConnectorArrayMenu()
{

}

void ConnectorArrayMenu::show(int maxIndex)
{

    setWindowTitle(QString(Helper::applicationName).append(" - Create New "));
    mpIndexLabel->setText(" Index:");
    mpIndexTextBox->setText(tr(""));
    mpIndexTextBox->setFocus();
     mMaxIndex=maxIndex;
    setVisible(true);

}

QString ConnectorArrayMenu::getConnectorIndex()
{
    return mConnectorIndex;
}

void ConnectorArrayMenu::setConnectorIndex(QString connectorIndex )
{
    mConnectorIndex=connectorIndex;
}

void ConnectorArrayMenu::addIndex()
{
bool ok;
    int index= mpIndexTextBox->text().toInt(&ok,10);

    if(ok)
{
    if(index>=0 && index<=mMaxIndex || index>=0 && mMaxIndex ==-2)
    {

         Component *pEndComponent = this->mpConnector->getEndComponent();
         Component *pStartComponent = this->mpConnector->getStartComponent();
         QString indexStr = QString::number(index);
         this->setConnectorIndex(indexStr);


         if(!pEndComponent)
         accept();

             else
         {
            this->mpConnector->mpParentGraphicsView->addConnectorForArray(pStartComponent,pEndComponent,index);
            accept();
         }
    }
    else
    {
        if(mMaxIndex==-2)
        {
            QMessageBox::critical(this, Helper::applicationName + " - Error",
                                  GUIMessages::getMessage(GUIMessages::ENTER_VALID_INTEGER)
                                  , tr("OK"));
        }
        else
        {
        QMessageBox::critical(this, Helper::applicationName + " - Error",
                              GUIMessages::getMessage(GUIMessages::ENTER_VALID_INTEGER).
                              arg("less than equal to"+QString::number(mMaxIndex)), tr("OK"));
        }
        return;
    }
}
    else
    {
        if(mMaxIndex==-2)
        {
            QMessageBox::critical(this, Helper::applicationName + " - Error",
                                  GUIMessages::getMessage(GUIMessages::ENTER_VALID_INTEGER)
                                  , tr("OK"));
        }
        else
        {
        QMessageBox::critical(this, Helper::applicationName + " - Error",
                              GUIMessages::getMessage(GUIMessages::ENTER_VALID_INTEGER).
                              arg("less than equal to"+QString::number(mMaxIndex)), tr("OK"));
        }
        return;
    }

}

void ConnectorArrayMenu::reject()
{
    Component *pEndComponent = this->mpConnector->getEndComponent();
    Component *pStartComponent = this->mpConnector->getStartComponent();
this->mpConnector->mpParentGraphicsView->addConnectorForArray(pStartComponent,pEndComponent,-1);
            QDialog::reject();

}


