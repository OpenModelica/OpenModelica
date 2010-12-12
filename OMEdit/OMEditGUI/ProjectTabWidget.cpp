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

/*
 * HopsanGUI
 * Fluid and Mechatronic Systems, Department of Management and Engineering, Linkoping University
 * Main Authors 2009-2010:  Robert Braun, Bjorn Eriksson, Peter Nordin
 * Contributors 2009-2010:  Mikael Axin, Alessandro Dell'Amico, Karl Pettersson, Ingo Staack
 */

#include <QtGui>
#include <QSizePolicy>
#include <QMap>

#include "ProjectTabWidget.h"
#include "LibraryWidget.h"
#include "mainwindow.h"

//! @class GraphicsView
//! @brief The GraphicsView class is a class which display the content of a scene of components.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
GraphicsView::GraphicsView(int iconType, ProjectTab *parent)
    : QGraphicsView(parent), mIconType(iconType)
{
    mpParentProjectTab = parent;
    this->setFrameShape(QGraphicsView::NoFrame);
    this->setDragMode(QGraphicsView::RubberBandDrag);
    this->setInteractive(true);
    this->setEnabled(true);
    this->setAcceptDrops(true);
    this->mIsCreatingConnector = false;
    this->mIsMovingComponents = false;
    this->mIsCreatingLine = false;
    this->mIsCreatingPolygon = false;
    this->mIsCreatingRectangle = false;
    this->mIsCreatingEllipse = false;
    this->mIsCreatingText = false;
    //this->setMinimumSize(Helper::viewWidth, Helper::viewHeight);
    this->setViewportUpdateMode(QGraphicsView::FullViewportUpdate);
    this->setTransformationAnchor(QGraphicsView::AnchorUnderMouse);
    this->setSceneRect(-100.0, -100.0, 200.0, 200.0);
    this->centerOn(this->sceneRect().center());
    this->createActions();
    this->createMenus();

    // if user is viewing some readonly component then dont draw backgrounds.
    if (!mpParentProjectTab->isReadOnly())
    {
        this->scale(2.0, -2.0);
        if (mIconType == StringHandler::ICON)
        {
            this->setStyleSheet(QString("background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1")
                                         .append(", stop: 0 lightGray, stop: 1 gray);"));
        }
        // change the background shade if user is in Icon View
        else if (mIconType == StringHandler::DIAGRAM)
        {
            this->setStyleSheet(QString("background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1")
                                         .append(", stop: 0 gray, stop: 1 lightGray);"));
        }
    }
    // if readonly view then don't scale the graphics view
    else
    {
        this->scale(1.0, -1.0);
    }

    connect(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->gridLinesAction,
            SIGNAL(toggled(bool)), this, SLOT(showGridLines(bool)));
}

void GraphicsView::drawBackground(QPainter *painter, const QRectF &rect)
{
    Q_UNUSED(rect);

    if (mpParentProjectTab->isReadOnly())
        return;

    // draw scene rectangle
    painter->setPen(Qt::black);
    painter->setBrush(QBrush(Qt::white, Qt::SolidPattern));
    painter->drawRect(this->sceneRect());

    //! @todo Grid Lines changes when resize the window. Update it.
    if (mpParentProjectTab->mpParentProjectTabWidget->mShowLines)
    {
        painter->scale(1.0, -1.0);
        painter->setBrush(Qt::NoBrush);
        painter->setPen(Qt::gray);

        int xAxis = sceneRect().x();
        int yAxis = sceneRect().y();

        // Horizontal Lines
        while (yAxis < sceneRect().right())
        {
            yAxis += 20;
            painter->drawLine(xAxis, yAxis, sceneRect().right(), yAxis);
        }

        // Vertical Lines
        yAxis = sceneRect().y();
        while (xAxis < sceneRect().bottom())
        {
            xAxis += 20;
            painter->drawLine(xAxis, yAxis, xAxis, sceneRect().bottom());
        }
    }
    // draw scene rectangle again without brush
    painter->setPen(Qt::black);
    painter->setBrush(Qt::NoBrush);
    painter->drawRect(this->sceneRect());
}

//! Defines what happens when moving an object in a GraphicsView.
//! @param event contains information of the drag operation.
void GraphicsView::dragMoveEvent(QDragMoveEvent *event)
{
    // check if the view is readonly or not
    if (mpParentProjectTab->isReadOnly() or (mIconType == StringHandler::DIAGRAM))
    {
        event->ignore();
        return;
    }

    if (event->mimeData()->hasFormat("image/modelica-component"))
    {
        event->setDropAction(Qt::CopyAction);
        event->accept();
    }
    else
    {
        event->ignore();
    }
}

//! Defines what happens when drop an object in a GraphicsView.
//! @param event contains information of the drop operation.
void GraphicsView::dropEvent(QDropEvent *event)
{
    // check if the view is readonly or not
    if (mpParentProjectTab->isReadOnly() or (mIconType == StringHandler::DIAGRAM))
    {
        event->ignore();
        return;
    }

    if (!event->mimeData()->hasFormat("image/modelica-component"))
        event->ignore();

    QByteArray itemData = event->mimeData()->data("image/modelica-component");
    QDataStream dataStream(&itemData, QIODevice::ReadOnly);

    QString className;
    dataStream >> className;

    MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;

    // if item is a class, model, block, connector or record. then we can drop it to the graphicsview
    if (pMainWindow->mpOMCProxy->isWhat(StringHandler::CLASS, className) or
        pMainWindow->mpOMCProxy->isWhat(StringHandler::MODEL, className) or
        pMainWindow->mpOMCProxy->isWhat(StringHandler::BLOCK, className) or
        pMainWindow->mpOMCProxy->isWhat(StringHandler::CONNECTOR, className) or
        pMainWindow->mpOMCProxy->isWhat(StringHandler::RECORD, className))
    {
        // Check if the icon is already loaded.
        Component *oldComponent = pMainWindow->mpLibrary->getComponentObject(className);
        Component *newComponent;
        QString iconName = getUniqueComponentName(StringHandler::getLastWordAfterDot(className).toLower());

        if (!oldComponent)
        {
            QString result = pMainWindow->mpOMCProxy->getIconAnnotation(className);
            newComponent = new Component(result, iconName, className, mapToScene(event->pos()),
                                         StringHandler::ICON, false, pMainWindow->mpOMCProxy,
                                         mpParentProjectTab->mpGraphicsView);
        }
        else
        {
            newComponent = new Component(oldComponent, iconName, mapToScene(event->pos()), StringHandler::ICON,
                                         false, mpParentProjectTab->mpGraphicsView);
        }
        addComponentObject(newComponent);
        event->accept();
    }
    else
    {
        event->ignore();
    }
}

void GraphicsView::addComponentObject(Component *component)
{
    MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
    // Add the component to model in OMC Global Scope.
    pMainWindow->mpOMCProxy->addComponent(component->getName(), component->getClassName(),
                                          mpParentProjectTab->mModelNameStructure);
    // add the annotations of icon
    component->updateAnnotationString();
    // add the component to local list.
    mComponentsList.append(component);
}

void GraphicsView::deleteComponentObject(Component *component)
{
    // First Remove the Connector associated to this icon
    int i = 0;
    while(i != mConnectorsVector.size())
    {
        if((mConnectorsVector[i]->getStartComponent()->getParentComponent()->getName() == component->getName()) or
           (mConnectorsVector[i]->getEndComponent()->getParentComponent()->getName() == component->getName()))
        {
            this->removeConnector(mConnectorsVector[i]);
            i = 0;   //Restart iteration if map has changed
        }
        else
        {
            ++i;
        }
    }
    // remove the icon now
    mComponentsList.removeOne(component);
    mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy->deleteComponent(component->getName(), mpParentProjectTab->mModelNameStructure);
}

Component* GraphicsView::getComponentObject(QString componentName)
{
    foreach (Component *component, mComponentsList)
    {
        if (component->getName() == componentName)
            return component;
    }
    return 0;
}

QString GraphicsView::getUniqueComponentName(QString iconName, int number)
{
    QString name;
    name = iconName + QString::number(number);

    foreach (Component *icon, mComponentsList)
    {
        if (icon->getName() == name)
        {
            name = getUniqueComponentName(iconName, ++number);
            break;
        }
    }
    return name;
}

bool GraphicsView::checkComponentName(QString iconName)
{
    foreach (Component *icon, mComponentsList)
    {
        if (icon->getName() == iconName)
        {
            return false;
        }
    }

    return true;
}

void GraphicsView::addShapeObject(ShapeAnnotation *shape)
{
    mShapesList.append(shape);
}

void GraphicsView::deleteShapeObject(ShapeAnnotation *shape)
{
    mShapesList.removeOne(shape);
}

//! Defines what happens when the mouse is moving in a GraphicsView.
//! @param event contains information of the mouse moving operation.
void GraphicsView::mouseMoveEvent(QMouseEvent *event)
{
    // don't send mouse move events to items if we are creating something
    if (!mIsCreatingConnector and !mIsCreatingLine and !mIsCreatingPolygon and !mIsCreatingRectangle
        and !mIsCreatingEllipse and !mIsCreatingText)
    {
        QGraphicsView::mouseMoveEvent(event);
    }

    //If creating connector, the end port shall be updated to the mouse position.
    if (this->mIsCreatingConnector)
    {
        mpConnector->updateEndPoint(this->mapToScene(event->pos()));
        mpConnector->drawConnector();
    }
    //If creating line shape, the end points shall be updated to the mouse position.
    else if (this->mIsCreatingLine)
    {
        mpLineShape->updateEndPoint(this->mapToScene(event->pos()));
        mpLineShape->update();
    }
    //If creating rectangle shape, the end points shall be updated to the mouse position.
    else if (this->mIsCreatingPolygon)
    {
        mpPolygonShape->updateEndPoint(this->mapToScene(event->pos()));
        mpPolygonShape->update();
    }
    //If creating rectangle shape, the end points shall be updated to the mouse position.
    else if (this->mIsCreatingRectangle)
    {
        mpRectangleShape->updateEndPoint(this->mapToScene(event->pos()));
        mpRectangleShape->update();
    }
    //If creating rectangle shape, the end points shall be updated to the mouse position.
    else if (this->mIsCreatingEllipse)
    {
        mpEllipseShape->updateEndPoint(this->mapToScene(event->pos()));
        mpEllipseShape->update();
    }
}

//! Defines what happens when clicking in a GraphicsView.
//! @param event contains information of the mouse click operation.
void GraphicsView::mousePressEvent(QMouseEvent *event)
{
    MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
    // if left button presses and we are creating a connector
    if ((event->button() == Qt::LeftButton) && (this->mIsCreatingConnector))
    {
        mpConnector->addPoint(this->mapToScene(event->pos()));
    }
    // if left button presses and we are starting to create a Line
    else if ((event->button() == Qt::LeftButton) && pMainWindow->lineAction->isChecked())
    {
        // if we are starting to create a line then create line object and add to graphicsview
        createLineShape(this->mapToScene(event->pos()));
    }
    // if left button presses and we are starting to create a Line
    else if ((event->button() == Qt::LeftButton) && pMainWindow->polygonAction->isChecked())
    {
        // if we are starting to create a line then create line object and add to graphicsview
        createPolygonShape(this->mapToScene(event->pos()));
    }
    // if left button presses and we are starting to create a Rectangle
    else if ((event->button() == Qt::LeftButton) && pMainWindow->rectangleAction->isChecked())
    {
        // if we are starting to create a rectangle then create rectangle object and add to graphicsview
        createRectangleShape(this->mapToScene(event->pos()));
    }
    // if left button presses and we are starting to create an Ellipse
    else if ((event->button() == Qt::LeftButton) && pMainWindow->ellipseAction->isChecked())
    {
        // if we are starting to create a rectangle then create rectangle object and add to graphicsview
        createEllipseShape(this->mapToScene(event->pos()));
    }
    // if left button presses and we are not creating a connector
    else if ((event->button() == Qt::LeftButton))
    {
        // this flag is just used to have seperate identify for if statement in mouse release event of graphicsview
        this->mIsMovingComponents = true;
        // save the position of all components
        foreach (Component *component, mComponentsList)
        {
            component->mOldPosition = component->pos();
            component->isMousePressed = true;
        }
    }
    /* don't send mouse press events to items if we are creating something, only send them if creating a connector
       because for connector we need to select end port */
    if (!mIsCreatingLine and !mIsCreatingPolygon and !mIsCreatingRectangle and !mIsCreatingEllipse
        and !mIsCreatingText)
    {
        QGraphicsView::mousePressEvent(event);
    }
}

void GraphicsView::mouseReleaseEvent(QMouseEvent *event)
{
    if ((event->button() == Qt::LeftButton) && (this->mIsMovingComponents))
    {
        this->mIsMovingComponents = false;
        // if component position is changed then update annotations
        foreach (Component *component, mComponentsList)
        {
            if (component->mOldPosition != component->pos())
            {
                component->updateAnnotationString();
                // if there are any connectors associated to component update their annotations as well.
                foreach (Connector *connector, mConnectorsVector)
                {
                    if ((connector->getStartComponent()->mpParentComponent == component) or
                        (connector->getEndComponent()->mpParentComponent == component))
                    {
                        connector->updateConnectionAnnotationString();
                    }
                }
            }
            component->isMousePressed = false;
        }
    }
    QGraphicsView::mouseReleaseEvent(event);
}

void GraphicsView::mouseDoubleClickEvent(QMouseEvent *event)
{
    MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
    if (this->mIsCreatingLine)
    {
        // finish creating the line
        this->mIsCreatingLine = false;
        // add the line to shapes list
        addShapeObject(mpLineShape);
        mpLineShape->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpLineShape->drawRectangleCornerItems();
        // make the toolbar button of line unchecked
        pMainWindow->lineAction->setChecked(false);
    }
    else if (this->mIsCreatingPolygon)
    {
        // finish creating the line
        this->mIsCreatingPolygon = false;
        // add the line to shapes list
        addShapeObject(mpPolygonShape);
        mpPolygonShape->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpPolygonShape->drawRectangleCornerItems();
        // make the toolbar button of line unchecked
        pMainWindow->polygonAction->setChecked(false);
    }
    QGraphicsView::mouseDoubleClickEvent(event);
}

void GraphicsView::keyPressEvent(QKeyEvent *event)
{
    if (event->key() == Qt::Key_Delete)
    {
        emit keyPressDelete();
    }
    else if(event->key() == Qt::Key_Up)
    {
        emit keyPressUp();
    }
    else if(event->key() == Qt::Key_Down)
    {
        emit keyPressDown();
    }
    else if(event->key() == Qt::Key_Left)
    {
        emit keyPressLeft();
    }
    else if(event->key() == Qt::Key_Right)
    {
        emit keyPressRight();
    }
    else if (event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_A)
    {
        this->selectAll();
    }
    else if (!event->modifiers().testFlag(Qt::ShiftModifier) and event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_R)
    {
        emit keyPressRotateClockwise();
    }
    else if (event->modifiers().testFlag(Qt::ShiftModifier) and event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_R)
    {
        emit keyPressRotateAntiClockwise();
    }
    else
    {
        QGraphicsView::keyPressEvent(event);
    }
}

//! Defines what shall happen when a key is released.
//! @param event contains information about the keypress operation.
void GraphicsView::keyReleaseEvent(QKeyEvent *event)
{
    QGraphicsView::keyReleaseEvent(event);
}

void GraphicsView::createActions()
{
    // Connection Delete Action
    mpCancelConnectionAction = new QAction(QIcon(":/Resources/icons/delete.png"),
                                          tr("Cancel Connection"), this);
    connect(mpCancelConnectionAction, SIGNAL(triggered()), SLOT(removeConnector()));    
    // Icon Rotate ClockWise Action
    mpRotateIconAction = new QAction(QIcon(":/Resources/icons/rotateclockwise.png"),
                                    tr("Rotate Clockwise"), this);
    mpRotateIconAction->setShortcut(QKeySequence("Ctrl+r"));
    // Icon Rotate Anti-ClockWise Action
    mpRotateAntiIconAction = new QAction(QIcon(":/Resources/icons/rotateanticlockwise.png"),
                                        tr("Rotate Anticlockwise"), this);
    mpRotateAntiIconAction->setShortcut(QKeySequence("Ctrl+Shift+r"));
    // Icon Reset Rotation Action
    mpResetRotation = new QAction(tr("Reset Rotation"), this);
    // Icon Delete Action
    mpDeleteIconAction = new QAction(QIcon(":/Resources/icons/delete.png"), tr("Delete"), this);
    mpDeleteIconAction->setShortcut(QKeySequence::Delete);
}

void GraphicsView::createMenus()
{

}

void GraphicsView::createLineShape(QPointF point)
{
    if (mpParentProjectTab->isReadOnly())
        return;

    if (!this->mIsCreatingLine)
    {
        this->mIsCreatingLine = true;
        mpLineShape = new LineAnnotation(this);
        mpLineShape->addPoint(point);
        mpLineShape->addPoint(point);
        this->scene()->addItem(mpLineShape);
    }
    // if we are already creating a line then only add one point.
    else
    {
        mpLineShape->addPoint(point);
    }
}

void GraphicsView::createPolygonShape(QPointF point)
{
    if (mpParentProjectTab->isReadOnly())
        return;

    if (!this->mIsCreatingPolygon)
    {
        this->mIsCreatingPolygon = true;
        mpPolygonShape = new PolygonAnnotation(this);
        mpPolygonShape->addPoint(point);
        mpPolygonShape->addPoint(point);
        mpPolygonShape->addPoint(point);
        this->scene()->addItem(mpPolygonShape);
    }
    // if we are already creating a polygon then only add one point.
    else
    {
        mpPolygonShape->addPoint(point);
    }
}

void GraphicsView::createRectangleShape(QPointF point)
{
    if (mpParentProjectTab->isReadOnly())
        return;

    if (!this->mIsCreatingRectangle)
    {
        this->mIsCreatingRectangle = true;
        mpRectangleShape = new RectangleAnnotation(this);
        mpRectangleShape->addPoint(point);
        mpRectangleShape->addPoint(point);
        this->scene()->addItem(mpRectangleShape);
    }
    // if we are already creating a rectangle then simply finish creating it.
    else
    {
        // finish creating the rectangle
        this->mIsCreatingRectangle = false;
        // add the line to shapes list
        addShapeObject(mpRectangleShape);
        mpRectangleShape->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpRectangleShape->drawRectangleCornerItems();
        // make the toolbar button of line unchecked
        mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->rectangleAction->setChecked(false);
    }
}

void GraphicsView::createEllipseShape(QPointF point)
{
    if (mpParentProjectTab->isReadOnly())
        return;

    if (!this->mIsCreatingEllipse)
    {
        this->mIsCreatingEllipse = true;
        mpEllipseShape = new EllipseAnnotation(this);
        mpEllipseShape->addPoint(point);
        mpEllipseShape->addPoint(point);
        this->scene()->addItem(mpEllipseShape);
    }
    // if we are already creating a rectangle then simply finish creating it.
    else
    {
        // finish creating the rectangle
        this->mIsCreatingEllipse = false;
        // add the line to shapes list
        addShapeObject(mpEllipseShape);
        mpEllipseShape->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpEllipseShape->drawRectangleCornerItems();
        // make the toolbar button of line unchecked
        mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->ellipseAction->setChecked(false);
    }
}

void GraphicsView::createTextShape(QPointF point)
{

}

void GraphicsView::contextMenuEvent(QContextMenuEvent *event)
{
    if (mIsCreatingConnector)
    {
        QMenu menu(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
        mpCancelConnectionAction->setText("Cancel Connection");
        menu.addAction(mpCancelConnectionAction);
        menu.exec(event->globalPos());
        return;         // return from it because at a time we only want one context menu.
    }
    QGraphicsView::contextMenuEvent(event);
}

//! Begins creation of connector or complete creation of connector depending on the mIsCreatingConnector flag.
//! @param pPort is a pointer to the clicked port, either start or end depending on the mIsCreatingConnector flag.
//! @param doNotRegisterUndo is true if the added connector shall not be registered in the undo stack, for example if this function is called by a redo function.
void GraphicsView::addConnector(Component *pComponent)
{
    //When clicking start port
    if (!mIsCreatingConnector)
    {
        QPointF startPos = pComponent->mapToScene(pComponent->boundingRect().center());

        this->mpConnector = new Connector(pComponent, this);

        this->scene()->addItem(mpConnector);
        this->mIsCreatingConnector = true;
        pComponent->getParentComponent()->addConnector(this->mpConnector);

        this->mpConnector->setStartComponent(pComponent);
        this->mpConnector->addPoint(startPos);
        this->mpConnector->addPoint(startPos);
        this->mpConnector->drawConnector();
    }
    // When clicking end port
    else
    {
        Component *pStartComponent = this->mpConnector->getStartComponent();
        // add the code to check if we can connect to component or not.
        MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
        QString startIconName = pStartComponent->getParentComponent()->getName();
        QString startIconCompName = pStartComponent->mpComponentProperties->getName();
        QString endIconName = pComponent->getParentComponent()->getName();
        QString endIconCompName = pComponent->mpComponentProperties->getName();
        // If both components are same
        if (pStartComponent == pComponent)
        {
            removeConnector();
            pMainWindow->mpMessageWidget->printGUIErrorMessage(GUIMessages::getMessage(GUIMessages::SAME_PORT_CONNECT));
        }
        else
        {
            if (pMainWindow->mpOMCProxy->addConnection(startIconName + "." + startIconCompName,
                                                       endIconName + "." + endIconCompName,
                                                       mpParentProjectTab->mModelNameStructure))
            {
                // Check if both ports connected are compatible or not.
                if (pMainWindow->mpOMCProxy->instantiateModel(mpParentProjectTab->mModelNameStructure))
                {
                    this->mIsCreatingConnector = false;
                    QPointF newPos = pComponent->mapToScene(pComponent->boundingRect().center());
                    this->mpConnector->updateEndPoint(newPos);
                    pComponent->getParentComponent()->addConnector(this->mpConnector);
                    this->mpConnector->setEndComponent(pComponent);
                    this->mConnectorsVector.append(mpConnector);
                    // add the connection annotation to OMC
                    mpConnector->updateConnectionAnnotationString();
                    pMainWindow->mpMessageWidget->printGUIInfoMessage("Conncted: (" + startIconName + "." + startIconCompName +
                                                                      ", " + endIconName + "." + endIconCompName + ")");
                }
                else
                {
                    removeConnector();
                    //! @todo make the error message better
                    pMainWindow->mpMessageWidget->printGUIErrorMessage(GUIMessages::getMessage(GUIMessages::INCOMPATIBLE_CONNECTORS));
                    pMainWindow->mpMessageWidget->printGUIErrorMessage(pMainWindow->mpOMCProxy->getErrorString());
                    // remove the connection from model
                    pMainWindow->mpOMCProxy->deleteConnection(startIconName + "." + startIconCompName,
                                                              endIconName + "." + endIconCompName,
                                                              mpParentProjectTab->mModelNameStructure);
                }
            }
        }
    }
}

//! Removes the current connecting connector from the model.
void GraphicsView::removeConnector()
{
    if (mIsCreatingConnector)
    {
        scene()->removeItem(mpConnector);
        delete mpConnector;
        mIsCreatingConnector = false;
    }
    else
    {
        int i = 0;
        while(i != mConnectorsVector.size())
        {
            if(mConnectorsVector[i]->isActive())
            {
                this->removeConnector(mConnectorsVector[i]);
                i = 0;   //Restart iteration if map has changed
            }
            else
            {
                ++i;
            }
        }
    }
}

//! Removes the connector from the model.
//! @param pConnector is a pointer to the connector to remove.
//! @param doNotRegisterUndo is true if the removal of the connector shall not be registered in the undo stack, for example if this function is called by a redo-function.
void GraphicsView::removeConnector(Connector* pConnector)
{
    bool doDelete = false;
    int i;

    for(i = 0; i != mConnectorsVector.size(); ++i)
    {
        if(mConnectorsVector[i] == pConnector)
        {
            scene()->removeItem(pConnector);
            doDelete = true;
            break;
        }
        if(mConnectorsVector.empty())
            break;
    }
    if(doDelete)
    {
        // If GUI delete is successful then remove the connection from omc as well.
        MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
        QString startComponentName = pConnector->getStartComponent()->getParentComponent()->getName();
        QString startIconCompName = pConnector->getStartComponent()->mpComponentProperties->getName();
        QString endComponentName = pConnector->getEndComponent()->getParentComponent()->getName();
        QString endIconCompName = pConnector->getEndComponent()->mpComponentProperties->getName();

        if (pMainWindow->mpOMCProxy->deleteConnection(startComponentName + "." + startIconCompName,
                                                      endComponentName + "." + endIconCompName,
                                                      mpParentProjectTab->mModelNameStructure))
        {
            pMainWindow->mpMessageWidget->printGUIInfoMessage("Disconncted: (" + startComponentName + "." + startIconCompName +
                                                              ", " + endComponentName + "." + endIconCompName + ")");
        }
        else
        {
            pMainWindow->mpMessageWidget->printGUIErrorMessage(pMainWindow->mpOMCProxy->getErrorString());
        }
        delete pConnector;
        mConnectorsVector.remove(i);
    }
}

//! Resets zoom factor to 100%.
//! @see zoomIn()
//! @see zoomOut()
void GraphicsView::resetZoom()
{
    this->resetMatrix();
    this->scale(2.0, -2.0);
}

//! Increases zoom factor by 15%.
//! @see resetZoom()
//! @see zoomOut()
void GraphicsView::zoomIn()
{
    //this->scale(1.15, 1.15);
    this->scale(1.12, 1.12);
}

//! Decreases zoom factor by 13.04% (1 - 1/1.15).
//! @see resetZoom()
//! @see zoomIn()
void GraphicsView::zoomOut()
{
    //if (transform().m11() != 2.0 and transform().m22() != -2.0)
    this->scale(1/1.12, 1/1.12);
}

void GraphicsView::showGridLines(bool showLines)
{
    this->mpParentProjectTab->mpParentProjectTabWidget->mShowLines = showLines;
    this->scene()->update();
}

//! Selects all objects and connectors.
void GraphicsView::selectAll()
{
    //Select all components
    foreach (Component *icon, mComponentsList)
    {
        icon->setSelected(true);
    }

    // Select all connectors
    foreach (Connector *connector, mConnectorsVector)
    {
        // just make one line of connector selected, it will make the whole connector selected
        foreach (ConnectorLine *connectorLine, connector->mpLines)
        {
            connectorLine->setSelected(true);
            break;
        }
    }
}

void GraphicsView::saveModelAnnotation()
{
//    // get the canvase positions
//    int canvasXStart = -((int)sceneRect().width() / 2);
//    int canvasYStart = -((int)sceneRect().height() / 2);
//    int canvasXEnd = ((int)sceneRect().width() / 2);
//    int canvasYEnd = ((int)sceneRect().height() / 2);

//    // create the annotation string
//    QString annotationString = "annotate=Diagram(";
//    annotationString.append("coordinateSystem=CoordinateSystem(extent={{");
//    annotationString.append(QString::number(canvasXStart)).append(", ");
//    annotationString.append(QString::number(canvasYStart)).append("}, {");
//    annotationString.append(QString::number(canvasXEnd)).append(", ");
//    annotationString.append(QString::number(canvasYEnd)).append("}}))");

//    // Send the annotation to OMC
//    OMCProxy *pOMCProcy = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy;
//    pOMCProcy->addClassAnnotation(mpParentProjectTab->mModelNameStructure, annotationString);
}

void GraphicsView::addClassAnnotation()
{
    MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
    QString annotationString;
    annotationString.append("annotate=");

    int counter = 0;

    if (mIconType == StringHandler::ICON)
    {
        annotationString.append("Diagram(");
    }
    else if (mIconType == StringHandler::DIAGRAM)
    {
        annotationString.append("Icon(");
    }
    if (mShapesList.size() > 0)
    {
        annotationString.append("graphics={");
        foreach (ShapeAnnotation *shape, mShapesList)
        {
            annotationString.append(shape->getShapeAnnotation());
            if (counter < mShapesList.size() - 1)
                annotationString.append(",");
            counter++;
        }
        annotationString.append("}");
    }
    annotationString.append(")");

    // add the class annotation to model through OMC
    if (!pMainWindow->mpOMCProxy->addClassAnnotation(mpParentProjectTab->mModelNameStructure, annotationString))
    {
        pMainWindow->mpMessageWidget->printGUIErrorMessage("Error in class annotation");
    }
}

//! @class GraphicsScene
//! @brief The GraphicsScene class is a container for graphicsl components in a simulationmodel.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
GraphicsScene::GraphicsScene(int iconType, ProjectTab *parent)
    : QGraphicsScene(parent), mIconType(iconType)
{
    mpParentProjectTab = parent;

    // only attach the haschanged slot if we are viewing the icon view.
    if (mIconType == StringHandler::ICON)
        connect(this, SIGNAL(changed( const QList<QRectF> & )),mpParentProjectTab, SLOT(hasChanged()));
}

//GraphicsViewScroll::GraphicsViewScroll(GraphicsView *graphicsView, QWidget *parent)
//    : QScrollArea(parent)
//{
//    mpGraphicsView = graphicsView;
//}

//void GraphicsViewScroll::scrollContentsBy(int dx, int dy)
//{
//    QScrollArea::scrollContentsBy(dx, dy);
//    mpGraphicsView->update();
//}

//! @class ProjectTab
//! @brief The ProjectTab class is a Widget to contain a simulation model

//! ProjectTab contains a drawing space to create models.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
ProjectTab::ProjectTab(int modelicaType, int iconType, bool readOnly, bool isChild, ProjectTabWidget *parent)
    : QWidget(parent)
{
    mIsSaved = true;
    mModelFileName.clear();
    mpParentProjectTabWidget = parent;
    mModelicaType = modelicaType;
    mIconType = iconType;
    setReadOnly(readOnly);
    setIsChild(isChild);

    // icon graphics framework
    mpGraphicsScene = new GraphicsScene(StringHandler::ICON, this);
    mpGraphicsView = new GraphicsView(StringHandler::ICON, this);
    mpGraphicsView->setScene(mpGraphicsScene);

    // diagram graphics framework
    mpDiagramGraphicsScene = new GraphicsScene(StringHandler::DIAGRAM, this);
    mpDiagramGraphicsView = new GraphicsView(StringHandler::DIAGRAM, this);
    mpDiagramGraphicsView->setScene(mpDiagramGraphicsScene);

    // create a modelica text editor for modelica text
    mpModelicaEditor = new ModelicaEditor(this);
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    mpModelicaTextHighlighter = new ModelicaTextHighlighter(pMainWindow->mpOptionsWidget->mpModelicaTextSettings,
                                                            mpModelicaEditor->document());
    connect(pMainWindow->mpOptionsWidget, SIGNAL(modelicaTextSettingsChanged()), mpModelicaTextHighlighter,
            SLOT(settingsChanged()));

    // set Project Status Bar lables
    mpReadOnlyLabel = isReadOnly() ? new QLabel(Helper::readOnly) : new QLabel(Helper::writeAble);
    mpModelicaTypeLabel = new QLabel(StringHandler::getModelicaClassType(mModelicaType));
    mpViewTypeLabel = new QLabel(StringHandler::getViewType(mIconType));
    mpModelFilePathLabel = new QLabel(tr(""));

    // frame to contain view buttons
    QFrame *viewsButtonsFrame = new QFrame;
    QHBoxLayout *viewsButtonsHorizontalLayout = new QHBoxLayout;
    viewsButtonsHorizontalLayout->setContentsMargins(0, 0, 0, 0);

    // icon view tool button
    mpDiagramToolButton = new QToolButton;
    mpDiagramToolButton->setText(Helper::iconView);
    mpDiagramToolButton->setIcon(QIcon(":/Resources/icons/model.png"));
    mpDiagramToolButton->setIconSize(Helper::buttonIconSize);
    mpDiagramToolButton->setToolTip(Helper::iconView);
    mpDiagramToolButton->setAutoRaise(true);
    mpDiagramToolButton->setCheckable(true);
    connect(mpDiagramToolButton, SIGNAL(clicked(bool)), SLOT(showDiagramView(bool)));
    viewsButtonsHorizontalLayout->addWidget(mpDiagramToolButton);

    // diagram view tool button
    mpIconToolButton = new QToolButton;
    mpIconToolButton->setText(Helper::diagramView);
    mpIconToolButton->setIcon(QIcon(":/Resources/icons/omeditor.png"));
    mpIconToolButton->setIconSize(Helper::buttonIconSize);
    mpIconToolButton->setToolTip(Helper::diagramView);
    mpIconToolButton->setAutoRaise(true);
    mpIconToolButton->setCheckable(true);
    connect(mpIconToolButton, SIGNAL(clicked(bool)), SLOT(showIconView(bool)));
    viewsButtonsHorizontalLayout->addWidget(mpIconToolButton);

    // modelica text view tool button
    mpModelicaTextToolButton = new QToolButton;
    mpModelicaTextToolButton->setText(Helper::modelicaTextView);
    mpModelicaTextToolButton->setIcon(QIcon(":/Resources/icons/modeltext.png"));
    mpModelicaTextToolButton->setIconSize(Helper::buttonIconSize);
    mpModelicaTextToolButton->setToolTip(Helper::modelicaTextView);
    mpModelicaTextToolButton->setAutoRaise(true);
    mpModelicaTextToolButton->setCheckable(true);
    connect(mpModelicaTextToolButton, SIGNAL(clicked(bool)), SLOT(showModelicaTextView(bool)));
    viewsButtonsHorizontalLayout->addWidget(mpModelicaTextToolButton);

    viewsButtonsFrame->setLayout(viewsButtonsHorizontalLayout);

    // view buttons box
    mpViewsButtonGroup = new QButtonGroup;
    mpViewsButtonGroup->setExclusive(true);
    mpViewsButtonGroup->addButton(mpIconToolButton);
    mpViewsButtonGroup->addButton(mpDiagramToolButton);
    mpViewsButtonGroup->addButton(mpModelicaTextToolButton);

    // create project status bar
    mpProjectStatusBar = new QStatusBar;
    mpProjectStatusBar->setObjectName(tr("PojectStatusBar"));
    mpProjectStatusBar->setSizeGripEnabled(false);
    mpProjectStatusBar->addPermanentWidget(viewsButtonsFrame, 5);
    mpProjectStatusBar->addPermanentWidget(mpReadOnlyLabel, 10);
    mpProjectStatusBar->addPermanentWidget(mpModelicaTypeLabel, 10);
    mpProjectStatusBar->addPermanentWidget(mpViewTypeLabel, 10);
    mpProjectStatusBar->addPermanentWidget(mpModelFilePathLabel, 65);

    // create the layout for Modelica Editor
    QHBoxLayout *modelicaEditorHorizontalLayout = new QHBoxLayout;
    modelicaEditorHorizontalLayout->setContentsMargins(0, 0, 0, 0);
    modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpSearchLabelImage);
    modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpSearchLabel);
    modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpSearchTextBox);
    modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpPreviuosButton);
    modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpNextButton);
    modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpMatchCaseCheckBox);
    modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpMatchWholeWordCheckBox);
    modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpCloseButton);
    mpModelicaEditor->mpFindWidget->setLayout(modelicaEditorHorizontalLayout);
    QVBoxLayout *modelicaEditorVerticalLayout = new QVBoxLayout;
    modelicaEditorVerticalLayout->setContentsMargins(0, 0, 0, 0);
    modelicaEditorVerticalLayout->addWidget(mpModelicaEditor);
    modelicaEditorVerticalLayout->addWidget(mpModelicaEditor->mpFindWidget);
    mpModelicaEditorWidget = new QWidget;
    mpModelicaEditorWidget->setLayout(modelicaEditorVerticalLayout);

    QVBoxLayout *tabLayout = new QVBoxLayout;
    tabLayout->setContentsMargins(2, 2, 2, 2);
    tabLayout->addWidget(mpProjectStatusBar);
    tabLayout->addWidget(mpGraphicsView);
    tabLayout->addWidget(mpDiagramGraphicsView);
    tabLayout->addWidget(mpModelicaEditorWidget);
    setLayout(tabLayout);

    // Hide the modelica text view, icon view and show diagram view
    mpModelicaEditorWidget->hide();
    mpDiagramGraphicsView->hide();
    mpIconToolButton->setChecked(true);

    connect(this, SIGNAL(disableMainWindow(bool)),
            mpParentProjectTabWidget->mpParentMainWindow, SLOT(disableMainWindow(bool)));
    connect(this, SIGNAL(updateAnnotations()), SLOT(updateModelAnnotations()));
}

ProjectTab::~ProjectTab()
{
    delete mpProjectStatusBar;
}

void ProjectTab::updateTabName(QString name, QString nameStructure)
{
    mModelName = name;
    mModelNameStructure = nameStructure;

    if (mIsSaved)
        mpParentProjectTabWidget->setTabText(mTabPosition, mModelName);
    else
        mpParentProjectTabWidget->setTabText(mTabPosition, QString(mModelName).append("*"));
}

void ProjectTab::updateModel(QString name)
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    QString newNameStructure;
    QString oldModelName = mModelName;
    // rename the model, if user has changed the name
    if (pMainWindow->mpOMCProxy->renameClass(mModelNameStructure, name))
    {
        newNameStructure = StringHandler::removeFirstLastCurlBrackets(pMainWindow->mpOMCProxy->getResult());
        // Change the name in tree
        ModelicaTreeNode *node = pMainWindow->mpLibrary->mpModelicaTree->getNode(mModelNameStructure);
        pMainWindow->mpLibrary->updateNodeText(name, newNameStructure, node);
        pMainWindow->mpMessageWidget->printGUIInfoMessage("Renamed '"+oldModelName+"' to '"+name+"'");
    }
}

//! Should be called when a model has changed in some sense,
//! e.g. a component added or a connection has changed.
void ProjectTab::hasChanged()
{
    // if the model is readonly then simply return.........e.g Ground, Inertia, EMF etc.
    // if model is a child then simply return.....
    if (isReadOnly() or isChild())
        return;

    if (mIsSaved)
    {
        QString tabName = mpParentProjectTabWidget->tabText(mpParentProjectTabWidget->currentIndex());
        tabName.append("*");
        mpParentProjectTabWidget->setTabText(mpParentProjectTabWidget->currentIndex(), tabName);
        mIsSaved = false;
    }
}

void ProjectTab::showDiagramView(bool checked)
{
    if (!checked or (checked and mpDiagramGraphicsView->isVisible()))
        return;
    // Enable the main window
    emit disableMainWindow(false);
    mpModelicaEditorWidget->hide();
    mpGraphicsView->hide();
    mpDiagramGraphicsView->show();
    mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::DIAGRAM));
}

void ProjectTab::showIconView(bool checked)
{
    if (!checked or (checked and mpGraphicsView->isVisible()))
        return;
    // Enable the main window
    emit disableMainWindow(false);
    mpModelicaEditorWidget->hide();
    mpDiagramGraphicsView->hide();
    mpGraphicsView->show();
    mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::ICON));
}

void ProjectTab::showModelicaTextView(bool checked)
{
    if (!checked or (checked and mpModelicaEditorWidget->isVisible()))
        return;
    // Disable the main window
    emit disableMainWindow(true);
    emit updateModelAnnotations();

    mpGraphicsView->hide();
    mpDiagramGraphicsView->hide();
    mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::MODELICATEXT));
    // get the modelica text of the model
    mpModelicaEditor->setText(mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy->list(mModelNameStructure));
    mpModelicaEditor->mLastValidText = mpModelicaEditor->toPlainText();
    mpModelicaEditor->setFocus();
    mpModelicaEditorWidget->show();
}

bool ProjectTab::loadModelFromText(QString modelName)
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    QString modelNameStructure;
    // if a model is a sub model then
    if (mModelNameStructure.contains("."))
    {
        modelNameStructure = StringHandler::removeLastWordAfterDot(mModelNameStructure)
                             .append(".").append(modelName);
        // if model with this name already exists
        if (!pMainWindow->mpOMCProxy->existClass(modelNameStructure))
        {
            return loadSubModel(modelName);
        }
        else
        {
            pMainWindow->mpOMCProxy->setResult(GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS));
            return false;
        }
    }
    // if a model is a root model then
    else
    {
        modelNameStructure = modelName;
        if (!pMainWindow->mpOMCProxy->existClass(modelNameStructure))
        {
            return loadRootModel(mpModelicaEditor->toPlainText());
        }
        else
        {
            pMainWindow->mpOMCProxy->setResult(GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS));
            return false;
        }
    }
}

bool ProjectTab::loadRootModel(QString model)
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    // if model text is fine then
    if (pMainWindow->mpOMCProxy->saveModifiedModel(model))
    {
        updateModel(StringHandler::removeFirstLastCurlBrackets(pMainWindow->mpOMCProxy->getResult()));
        return true;
    }
    // if there is some error in model then dont accept it
    else
        return false;
}

bool ProjectTab::loadSubModel(QString model)
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    // if model text is fine then
//    if (pMainWindow->mpOMCProxy->updateSubClass(StringHandler::removeLastWordAfterDot(mModelNameStructure), model))
//    {
        updateModel(model);
        return true;
//    }
//    // if there is some error in model then dont accept it
//    else
//        return false;
}

//! Gets the components of the model and place them in the GraphicsView.
void ProjectTab::getModelComponents()
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    QList<ComponentsProperties*> components = pMainWindow->mpOMCProxy->getComponents(mModelNameStructure);
    QStringList componentsAnnotationsList = pMainWindow->mpOMCProxy->getComponentAnnotations(mModelNameStructure);

    int i = 0;
    foreach (ComponentsProperties *componentProperties, components)
    {
        //! @todo add the code to check if components are of types Real, so that we dont check annotation for them.
        Component *oldComponent = pMainWindow->mpLibrary->getComponentObject(componentProperties->getClassName());
        Component *newComponent;
        // create a component
        if (!pMainWindow->mpOMCProxy->isWhat(StringHandler::PACKAGE, componentProperties->getClassName()))
        {
            // Check if the icon is already loaded.
            QString iconName;
            iconName = componentProperties->getName();

            if (!oldComponent)
            {
                LibraryComponent *libComponent;
                QString result = pMainWindow->mpOMCProxy->getIconAnnotation(componentProperties->getClassName());
                libComponent = new LibraryComponent(result, componentProperties->getClassName(),
                                                     mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy);
                // add the component to library widget components lists
                mpParentProjectTabWidget->mpParentMainWindow->mpLibrary->addComponentObject(libComponent);
                // create a new copy component here
                newComponent = new Component(libComponent->mpComponent, iconName, QPointF(0.0, 0.0),
                                             StringHandler::ICON, false, mpGraphicsView);
//                newComponent = new Component(result, iconName, componentProperties->getClassName(), QPointF(0.0, 0.0),
//                                             StringHandler::ICON, false, pMainWindow->mpOMCProxy, mpGraphicsView);
            }
            else
            {
                // create a new copy component here
                newComponent = new Component(oldComponent, iconName, QPointF(0.0, 0.0), StringHandler::ICON,
                                             false, mpGraphicsView);
            }
            //mpGraphicsView->addComponentObject(newComponent);
            mpGraphicsView->mComponentsList.append(newComponent);
        }

        if (static_cast<QString>(componentsAnnotationsList.at(i)).toLower().contains("error"))
            continue;

        // if component annotation is found then place it according to annotation otherwise go to else block
        if (StringHandler::removeFirstLastCurlBrackets(componentsAnnotationsList.at(i)).length() > 0)
        {
            newComponent->mTransformationString = componentsAnnotationsList.at(i);
            Transformation *transformation = new Transformation(newComponent);
            //newComponent->setTransform(transformation->getTransformationMatrix());
            //! @todo We need to reset the matrix before applying tranformations.
            newComponent->resetTransform();
            newComponent->setPos(transformation->getPositionX(), transformation->getPositionY());
            newComponent->setRotation(transformation->getRotateAngle());
            newComponent->scale(transformation->getScale(), transformation->getScale());
        }
        i++;
    }
}

//! Gets the connections of the model and place them in the GraphicsView.
void ProjectTab::getModelConnections()
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    int connectionsCount = pMainWindow->mpOMCProxy->getConnectionCount(mModelNameStructure);

    for (int i = 1 ; i <= connectionsCount ; i++)
    {
        // get the connection from OMC
        QString connectionString;
        QStringList connectionList;
        connectionString = pMainWindow->mpOMCProxy->getNthConnection(mModelNameStructure, i);
        connectionList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(connectionString));
        // if the connectionString only contains two items then continue the loop,
        // because connection is not valid then
        if (connectionList.size() < 3)
            continue;

        // get start and end components
        QStringList startComponentList = static_cast<QString>(connectionList.at(0)).split(".");
        QStringList endComponentList = static_cast<QString>(connectionList.at(1)).split(".");

        Component *pStartComponent = mpGraphicsView->getComponentObject(startComponentList.at(0));
        Component *pEndComponent = mpGraphicsView->getComponentObject(endComponentList.at(0));

        // if Start component and end component not found then continue the loop
        if (!pStartComponent or !pEndComponent)
            continue;

        // get start and end ports
        Component *pStartPort = 0;
        Component *pEndPort = 0;
        foreach (Component *component, pStartComponent->mpComponentsList)
        {
            if (component->mpComponentProperties->getName() == startComponentList.at(1))
                pStartPort = component;
        }

        foreach (Component *component, pEndComponent->mpComponentsList)
        {
            if (component->mpComponentProperties->getName() == endComponentList.at(1))
                pEndPort = component;
        }

        // if Start port and end port not found then continue the loop
        if (!pStartPort or !pEndPort)
            continue;

        // get the connector annotations from OMC
        QString connectionAnnotationString;
        QStringList connectionAnnotationList;
        connectionAnnotationString = pMainWindow->mpOMCProxy->getNthConnectionAnnotation(mModelNameStructure, i);

        connectionAnnotationString = connectionAnnotationString.mid(QString("Line").length());
        connectionAnnotationString = StringHandler::removeFirstLastBrackets(connectionAnnotationString);

        connectionAnnotationList = StringHandler::getStrings(connectionAnnotationString);
        // if the connectionAnnotationString is empty then continue the loop,
        // because connection is not valid then
        if (connectionAnnotationList.size() < 8)
            continue;

        // create a QVector<QPointF> of annotation string to pass to connector
        QStringList pointsList;
        QVector<QPointF> points;
        pointsList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(connectionAnnotationList.at(3)));

        foreach (QString point, pointsList)
        {
            QStringList linePoints = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(point));
            if (linePoints.size() < 2)
                continue;

            qreal x = static_cast<QString>(linePoints.at(0)).toFloat();
            qreal y = static_cast<QString>(linePoints.at(1)).toFloat();
            QPointF p (x, y);
            points.append(p);
        }
        // create a connector now
        Connector *pConnector = new Connector(pStartPort, pEndPort, mpGraphicsView, points);
        mpGraphicsView->mConnectorsVector.append(pConnector);
        mpGraphicsView->scene()->addItem(pConnector);
    }
}

void ProjectTab::setReadOnly(bool readOnly)
{
    mReadOnly = readOnly;
}

bool ProjectTab::isReadOnly()
{
    return mReadOnly;
}

void ProjectTab::setIsChild(bool isChild)
{
    mIsChild = isChild;
}

bool ProjectTab::isChild()
{
    return mIsChild;
}

void ProjectTab::setModelFilePathLabel(QString filePath)
{
    mpModelFilePathLabel->setText(filePath);
}

QString ProjectTab::getModelicaTypeLabel()
{
    return mpModelicaTypeLabel->text();
}

//! Notifies the model that its corresponding text has changed.
//! @see loadModelFromText(QString name)
//! @see loadRootModel(QString model)
//! @see loadSubModel(QString model)
//! @see updateModel(QString name)
bool ProjectTab::ModelicaEditorTextChanged()
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    QString modelName = mpModelicaEditor->getModelName();
    if (!modelName.isEmpty())
    {
        if (loadModelFromText(modelName))
            return true;
        else
            return false;
    }
    else
    {
        pMainWindow->mpOMCProxy->setResult("Unknown error occurred.");
        return false;
    }
}

//! Updates the annotations of all components.
void ProjectTab::updateModelAnnotations()
{
    foreach (Component *icon, mpGraphicsView->mComponentsList)
        icon->updateAnnotationString();
}

//! @class ProjectTabWidget
//! @brief The ProjectTabWidget class is a container class for ProjectTab class

//! ProjectTabWidget contains ProjectTabWidget widgets.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
ProjectTabWidget::ProjectTabWidget(MainWindow *parent)
    : QTabWidget(parent)
{
    mpParentMainWindow = parent;
    setTabsClosable(true);
    setContentsMargins(0, 0, 0, 0);
    mShowLines = false;
    mToolBarEnabled = true;

    connect(mpParentMainWindow->openAction, SIGNAL(triggered()), this,SLOT(openModel()));
    connect(mpParentMainWindow->saveAction, SIGNAL(triggered()), this,SLOT(saveProjectTab()));
    connect(mpParentMainWindow->saveAsAction, SIGNAL(triggered()), this,SLOT(saveProjectTabAs()));
    connect(this,SIGNAL(tabCloseRequested(int)),SLOT(closeProjectTab(int)));
    connect(this, SIGNAL(tabAdded()), SLOT(enableProjectToolbar()));
    connect(this, SIGNAL(tabRemoved()), SLOT(disableProjectToolbar()));
    emit tabRemoved();
    connect(mpParentMainWindow->resetZoomAction, SIGNAL(triggered()),this,SLOT(resetZoom()));
    connect(mpParentMainWindow->zoomInAction, SIGNAL(triggered()),this,SLOT(zoomIn()));
    connect(mpParentMainWindow->zoomOutAction, SIGNAL(triggered()),this,SLOT(zoomOut()));
    connect(mpParentMainWindow->mpLibrary->mpModelicaTree, SIGNAL(nodeDeleted()), SLOT(updateTabIndexes()));
    connect(this, SIGNAL(modelSaved(QString,QString)), mpParentMainWindow->mpLibrary->mpModelicaTree,
            SLOT(saveChildModels(QString,QString)));
}

ProjectTabWidget::~ProjectTabWidget()
{
    // delete all the tabs opened currently
    while(count() > 0)
    {
        delete dynamic_cast<ProjectTab*>(this->widget(count() - 1));
    }

    // delete all the removed tabs as well.
    foreach (ProjectTab *pCurrentTab, mRemovedTabsList)
    {
        delete pCurrentTab;
    }
}

//! Returns a pointer to the currently active project tab
ProjectTab* ProjectTabWidget::getCurrentTab()
{
    return qobject_cast<ProjectTab *>(currentWidget());
}

ProjectTab* ProjectTabWidget::getTabByName(QString name)
{
    for (int i = 0; i < this->count() ; i++)
    {
        ProjectTab *pCurrentTab = dynamic_cast<ProjectTab*>(this->widget(i));
        if (pCurrentTab->mModelNameStructure == name)
        {
            return pCurrentTab;
        }
    }
    return 0;
}

ProjectTab* ProjectTabWidget::getRemovedTabByName(QString name)
{
    foreach (ProjectTab *pCurrentTab, mRemovedTabsList)
    {
        if (pCurrentTab->mModelNameStructure == name)
        {
            return pCurrentTab;
        }
    }
    return 0;
}

//! Reimplemented function to add the Tab.
int ProjectTabWidget::addTab(ProjectTab *tab, QString tabName)
{
    int position = QTabWidget::addTab(tab, tabName);
    tab->mpGraphicsView->saveModelAnnotation();
    emit tabAdded();
    return position;
}

//! Reimplemented function to remove the Tab.
void ProjectTabWidget::removeTab(int index)
{
    mpParentMainWindow->disableMainWindow(false);
    // if tab is saved and user is just closing it then save it to mRemovedTabsList, so that we can open it later on
    ProjectTab *pCurrentTab = qobject_cast<ProjectTab *>(widget(index));
    QTabWidget::removeTab(index);
    if (pCurrentTab->mIsSaved)
    {
        mRemovedTabsList.append(pCurrentTab);
    }
    else
    {
        // delete the tab if user dont save it, becasue removetab only removes the widget don't delete it
        delete pCurrentTab;
    }
    emit tabRemoved();
}

void ProjectTabWidget::disableTabs(bool disable)
{
    int i = count();
    while(i > 0)
    {
        i = i - 1;
        if (i != currentIndex())
            setTabEnabled(i, !disable);
    }
}

void ProjectTabWidget::setSourceFile(QString modelName, QString modelFileName)
{
    if (mpParentMainWindow->mpOMCProxy->isPackage(modelName))
    {
        // set the source file name
        mpParentMainWindow->mpOMCProxy->setSourceFile(modelName, modelFileName);
        // get the class names of this package
        QStringList modelsList = mpParentMainWindow->mpOMCProxy->getClassNames(modelName);

        foreach (QString model, modelsList)
            setSourceFile(modelName + "." + model, modelFileName);
    }
    else
    {
        // set the source file name
        mpParentMainWindow->mpOMCProxy->setSourceFile(modelName, modelFileName);
    }
}

//! Adds an existing ProjectTab object to itself.
//! @see closeProjectTab(int index)
void ProjectTabWidget::addProjectTab(ProjectTab *projectTab, QString modelName, QString modelStructure)
{
    projectTab->mIsSaved = true;
    projectTab->mModelName = modelName;
    projectTab->mModelNameStructure = modelStructure;
    projectTab->mModelFileName = mpParentMainWindow->mpOMCProxy->getSourceFile(modelStructure);
    projectTab->setModelFilePathLabel(projectTab->mModelFileName);
    projectTab->mTabPosition = addTab(projectTab, modelName);
    projectTab->getModelComponents();
    projectTab->getModelConnections();
    setCurrentWidget(projectTab);
    /* when we add the models and connections to the model, GraphicsView hasChanged will be called
       which mark the model as not saved, so just make it save again manually. */
//    QString tabName = tabText(currentIndex());
//    tabName.chop(1);
//    setTabText(currentIndex(), tabName);
}

//! Adds a ProjectTab object (a new tab) to itself.
//! @see closeProjectTab(int index)
void ProjectTabWidget::addNewProjectTab(QString modelName, QString modelStructure, int modelicaType)
{
    ProjectTab *newTab;
    if (modelStructure.isEmpty())
    {
        newTab = new ProjectTab(modelicaType, StringHandler::ICON, false, false, this);
        newTab->mIsSaved = false;
    }
    else
    {
        newTab = new ProjectTab(modelicaType, StringHandler::ICON, false, true, this);
    }
    newTab->mModelName = modelName;
    newTab->mModelNameStructure = modelStructure + modelName;
    newTab->mTabPosition = addTab(newTab, newTab->isChild() ? modelName : modelName.append(QString("*")));
    setCurrentWidget(newTab);
}

void ProjectTabWidget::addDiagramViewTab(QTreeWidgetItem *item, int column)
{
    Q_UNUSED(column);
    LibraryTreeNode *treeNode = dynamic_cast<LibraryTreeNode*>(item);
    ProjectTab *newTab = new ProjectTab(mpParentMainWindow->mpOMCProxy->getClassRestriction(treeNode->mNameStructure),
                                        StringHandler::DIAGRAM, true, false, this);
    newTab->mModelName = treeNode->mName;
    newTab->mModelNameStructure = treeNode->mNameStructure;
    newTab->mTabPosition = addTab(newTab, StringHandler::getLastWordAfterDot(treeNode->mNameStructure));

    Component *diagram;
    QString result = mpParentMainWindow->mpOMCProxy->getDiagramAnnotation(treeNode->toolTip(0));
    diagram = new Component(result, newTab->mModelName, newTab->mModelNameStructure, QPointF (0,0),
                            StringHandler::DIAGRAM, false, mpParentMainWindow->mpOMCProxy,
                            newTab->mpGraphicsView);


    Component *oldIconComponent = mpParentMainWindow->mpLibrary->getComponentObject(newTab->mModelNameStructure);
    Component *newIconComponent;

    if (!oldIconComponent)
    {
        QString result = mpParentMainWindow->mpOMCProxy->getIconAnnotation(newTab->mModelNameStructure);
        newIconComponent = new Component(result, newTab->mModelName, newTab->mModelNameStructure, QPointF (0,0),
                                         StringHandler::ICON, false, mpParentMainWindow->mpOMCProxy,
                                         newTab->mpDiagramGraphicsView);
    }
    else
    {
        newIconComponent = new Component(oldIconComponent, newTab->mModelName, QPointF (0,0), StringHandler::ICON,
                                        false, newTab->mpDiagramGraphicsView);
    }
    setCurrentWidget(newTab);
}

//! Saves current project.
//! @see saveProjectTab(int index)
void ProjectTabWidget::saveProjectTab()
{
    saveProjectTab(currentIndex(), false);
}

//! Saves current project to a new model file.
//! @see saveProjectTab(int index)
void ProjectTabWidget::saveProjectTabAs()
{
    saveProjectTab(currentIndex(), true);
}

//! Saves project at index.
//! @param index defines which project to save.
//! @see saveProjectTab()
void ProjectTabWidget::saveProjectTab(int index, bool saveAs)
{
    ProjectTab *pCurrentTab = qobject_cast<ProjectTab *>(widget(index));
    if (!pCurrentTab)
        return;
    // if the model is readonly then simply return.........e.g Ground, Inertia, EMF etc.
    if (pCurrentTab->isReadOnly())
        return;

    // if model is a child model then give user a message and return
    if (pCurrentTab->isChild())
    {
        MessageWidget *pMessageWidget = pCurrentTab->mpParentProjectTabWidget->mpParentMainWindow->mpMessageWidget;
        pMessageWidget->printGUIInfoMessage(QString(GUIMessages::getMessage(GUIMessages::CHILD_MODEL_SAVE))
                                            .arg(pCurrentTab->getModelicaTypeLabel()).arg(pCurrentTab->mModelName));
        return;
    }

    QString tabName = tabText(index);

    if (saveAs)
    {
        saveModel(saveAs);
    }
    // if not saveAs then
    else
    {
        // if user presses ctrl + s and model is already saved
        if (pCurrentTab->mIsSaved)
        {
            //Nothing to do
        }
        // if model is not saved then save it
        else
        {
            if (saveModel(saveAs))
            {
                tabName.chop(1);
                setTabText(index, tabName);
                pCurrentTab->mIsSaved = true;
            }
        }
    }
}

//! Saves the model in the active project tab to a model file.
//! @param saveAs tells whether or not an already existing file name shall be used
//! @see saveProjectTab()
//! @see loadModel()
bool ProjectTabWidget::saveModel(bool saveAs)
{
    ProjectTab *pCurrentTab = qobject_cast<ProjectTab *>(currentWidget());
    MainWindow *pMainWindow = pCurrentTab->mpParentProjectTabWidget->mpParentMainWindow;

    QString modelFileName;
    // if first time save or doing a saveas
    if(pCurrentTab->mModelFileName.isEmpty() | saveAs)
    {
        QDir fileDialogSaveDir;
        modelFileName = QFileDialog::getSaveFileName(this, tr("Save File"),
                                                             fileDialogSaveDir.currentPath(),
                                                             Helper::omFileOpenText);
        if (modelFileName.isEmpty())
        {
            return false;
        }
        else
        {
            // set the source file in OMC
            pMainWindow->mpOMCProxy->setSourceFile(pCurrentTab->mModelNameStructure, modelFileName);
            // if opened tab is a package save all of its child models
            if (pCurrentTab->mModelicaType == StringHandler::PACKAGE)
                emit modelSaved(pCurrentTab->mModelNameStructure, modelFileName);
            // finally save the model through OMC
            if (pMainWindow->mpOMCProxy->save(pCurrentTab->mModelNameStructure))
            {
                pCurrentTab->mModelFileName = modelFileName;
                pCurrentTab->setModelFilePathLabel(modelFileName);
                return true;
            }
            // if OMC is unable to save the file
            else
            {
                QMessageBox::critical(this, Helper::applicationName + " - Error",
                                     GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).
                                     arg(pMainWindow->mpOMCProxy->getResult()), tr("OK"));
                return false;
            }
        }
    }
    // if saving the file second time
    else
    {
        if (pMainWindow->mpOMCProxy->save(pCurrentTab->mModelNameStructure))
        {
            return true;
        }
        else
        {
            QMessageBox::critical(this, Helper::applicationName + " - Error",
                                 GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).
                                 arg(pMainWindow->mpOMCProxy->getResult()), tr("OK"));
            return false;
        }
    }
}

//! Closes current project.
//! @param index defines which project to close.
//! @return true if closing went ok. false if the user canceled the operation.
//! @see closeAllProjectTabs()
bool ProjectTabWidget::closeProjectTab(int index)
{
    ModelicaTree *pTree = mpParentMainWindow->mpLibrary->mpModelicaTree;
    ProjectTab *pCurrentTab = dynamic_cast<ProjectTab*>(widget(index));
    if (!(pCurrentTab->mIsSaved))
    {
        QString modelName;
        modelName = tabText(index);
        modelName.chop(1);
        QMessageBox *msgBox = new QMessageBox(mpParentMainWindow);
        msgBox->setWindowTitle(QString(Helper::applicationName).append(" - Question"));
        msgBox->setIcon(QMessageBox::Question);
        msgBox->setText(QString(GUIMessages::getMessage(GUIMessages::SAVED_MODEL))
                        .arg(pCurrentTab->getModelicaTypeLabel()).arg(pCurrentTab->mModelName));
        msgBox->setInformativeText(GUIMessages::getMessage(GUIMessages::SAVE_CHANGES));
        msgBox->setStandardButtons(QMessageBox::Save | QMessageBox::Discard | QMessageBox::Cancel);
        msgBox->setDefaultButton(QMessageBox::Save);

        int answer = msgBox->exec();

        switch (answer)
        {
        case QMessageBox::Save:
            // Save was clicked
            saveProjectTab(index, false);
            removeTab(index);
            return true;
        case QMessageBox::Discard:
            // Don't Save was clicked
            //if (pTree->deleteNodeTriggered(pTree->getNode(pCurrentTab->mModelNameStructure)))
                //removeTab(index);
            pTree->deleteNodeTriggered(pTree->getNode(pCurrentTab->mModelNameStructure));
            return true;
        case QMessageBox::Cancel:
            // Cancel was clicked
            return false;
        default:
            // should never be reached
            return false;
        }
    }
    else
    {
        removeTab(index);
        return true;
    }
}

//! Closes all opened projects.
//! @return true if closing went ok. false if the user canceled the operation.
//! @see closeProjectTab(int index)
//! @see saveProjectTab()
bool ProjectTabWidget::closeAllProjectTabs()
{
    for (int i = 0 ; i < count() ; i++)
    {
        if (!(dynamic_cast<ProjectTab*>(widget(i)))->mIsSaved)
        {
            QMessageBox *msgBox = new QMessageBox(mpParentMainWindow);
            msgBox->setWindowTitle(QString(Helper::applicationName).append(" - Question"));
            msgBox->setIcon(QMessageBox::Question);
            msgBox->setText(QString("There are unsaved models opened. Do you still want to quit?"));
            msgBox->setStandardButtons(QMessageBox::Yes | QMessageBox::No);
            msgBox->setDefaultButton(QMessageBox::No);

            int answer = msgBox->exec();
            msgBox->raise();

            switch (answer)
            {
            case QMessageBox::Yes:
                return true;
            case QMessageBox::No:
                return false;
            default:
                // should never be reached
                return false;
            }
        }
    }
    return true;
}

//! Loads a model from a file and opens it in a new project tab.
//! @see saveModel(bool saveAs)
void ProjectTabWidget::openModel()
{
    QString fileName = QFileDialog::getOpenFileName(this, tr("Choose File"),
                                                    QDir::currentPath() + QString("/../.."),
                                                    Helper::omFileOpenText);
    if (fileName.isEmpty())
        return;

    // create new OMC instance and load the file in it
    OMCProxy *omc = new OMCProxy(mpParentMainWindow, false);
    // if error in loading file
    if (!omc->loadFile(fileName))
    {
        mpParentMainWindow->mpMessageWidget->printGUIErrorMessage(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE));
        return;
    }
    // get the class names now to check if they are already loaded or not
    QStringList existingmodelsList;
    QStringList modelsList = omc->getClassNames();
    bool existModel = false;
    // check if the model already exists in OMEdit OMC instance
    foreach(QString model, modelsList)
    {
        if (mpParentMainWindow->mpOMCProxy->existClass(model))
        {
            existingmodelsList.append(model);
            existModel = true;
        }
    }

    // check if existModel is true
    if (existModel)
    {
        QMessageBox *msgBox = new QMessageBox(mpParentMainWindow);
        msgBox->setWindowTitle(QString(Helper::applicationName).append(" - Question"));
        msgBox->setIcon(QMessageBox::Information);
        msgBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE)));
        msgBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::REDEFING_EXISTING_MODELS))
                                   .arg(existingmodelsList.join(",")).append("\n")
                                   .append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD)));
        msgBox->setStandardButtons(QMessageBox::Ok);
        msgBox->exec();
    }
    // if no conflicting model found then just load the file simply
    else
    {
        mpParentMainWindow->mpLibrary->loadModel(fileName, modelsList);
    }
    // quit the temporary OMC
    omc->stopServer();
}

//! Tells the current tab to reset zoom to 100%.
//! @see zoomIn()
//! @see zoomOut()
void ProjectTabWidget::resetZoom()
{
    ProjectTab *pCurrentTab = getCurrentTab();
    if (pCurrentTab)
    {
        if (pCurrentTab->mpGraphicsView->isVisible())
            pCurrentTab->mpGraphicsView->resetZoom();
        else if (pCurrentTab->mpDiagramGraphicsView->isVisible())
            pCurrentTab->mpDiagramGraphicsView->resetZoom();
    }
}

//! Tells the current tab to increase its zoom factor.
//! @see resetZoom()
//! @see zoomOut()
void ProjectTabWidget::zoomIn()
{
    ProjectTab *pCurrentTab = getCurrentTab();
    if (pCurrentTab)
    {
        if (pCurrentTab->mpGraphicsView->isVisible())
            pCurrentTab->mpGraphicsView->zoomIn();
        else if (pCurrentTab->mpDiagramGraphicsView->isVisible())
            pCurrentTab->mpDiagramGraphicsView->zoomIn();
    }
}

//! Tells the current tab to decrease its zoom factor.
//! @see resetZoom()
//! @see zoomIn()
void ProjectTabWidget::zoomOut()
{
    ProjectTab *pCurrentTab = getCurrentTab();
    if (pCurrentTab)
    {
        if (pCurrentTab->mpGraphicsView->isVisible())
            pCurrentTab->mpGraphicsView->zoomOut();
        else if (pCurrentTab->mpDiagramGraphicsView->isVisible())
            pCurrentTab->mpDiagramGraphicsView->zoomOut();
    }
}

void ProjectTabWidget::updateTabIndexes()
{
    for (int i = 0 ; i < count() ; i++)
    {
        (dynamic_cast<ProjectTab*>(widget(i)))->mTabPosition = i;
    }
}

void ProjectTabWidget::enableProjectToolbar()
{
    if (!mToolBarEnabled)
    {
        mpParentMainWindow->gridLinesAction->setEnabled(true);
        mpParentMainWindow->resetZoomAction->setEnabled(true);
        mpParentMainWindow->zoomInAction->setEnabled(true);
        mpParentMainWindow->zoomOutAction->setEnabled(true);
        mpParentMainWindow->checkModelAction->setEnabled(true);
        // enable the shapes tool bar
        mpParentMainWindow->shapesToolBar->setEnabled(true);
        mToolBarEnabled = true;
    }
}

void ProjectTabWidget::disableProjectToolbar()
{
    if (mToolBarEnabled and (count() == 0))
    {
        mpParentMainWindow->gridLinesAction->setEnabled(false);
        mpParentMainWindow->resetZoomAction->setEnabled(false);
        mpParentMainWindow->zoomInAction->setEnabled(false);
        mpParentMainWindow->zoomOutAction->setEnabled(false);
        mpParentMainWindow->checkModelAction->setEnabled(false);
        // disable the shapes tool bar
        mpParentMainWindow->shapesToolBar->setEnabled(false);
        mToolBarEnabled = false;
    }
}

void ProjectTabWidget::keyPressEvent(QKeyEvent *event)
{
    ProjectTab *pCurrentTab = getCurrentTab();
    if (!pCurrentTab)
        return;

    if (!pCurrentTab->mpModelicaEditorWidget->isVisible())
        return;

    if (event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_F)
    {
        pCurrentTab->mpModelicaEditor->mpFindWidget->show();
        pCurrentTab->mpModelicaEditor->mpSearchTextBox->setFocus();
    }

    QTabWidget::keyPressEvent(event);
}
