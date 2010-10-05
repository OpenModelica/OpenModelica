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

#include <QtGui>
#include <QSizePolicy>
#include <QMap>
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <cassert>

#include "ProjectTabWidget.h"
#include "LibraryWidget.h"
#include "mainwindow.h"
#include "MessageWidget.h"
#include "Helper.h"

//! @class GraphicsView
//! @brief The GraphicsView class is a class which display the content of a scene of components.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
GraphicsView::GraphicsView(ProjectTab *parent)
    : QGraphicsView(parent)
{
    mpParentProjectTab = parent;
    //this->setFrameShape(QGraphicsView::NoFrame);
    this->setDragMode(RubberBandDrag);
    this->setInteractive(true);
    this->setEnabled(true);
    this->setAcceptDrops(true);
    this->mIsCreatingConnector = false;
    this->setViewportUpdateMode(QGraphicsView::FullViewportUpdate);
    this->setTransformationAnchor(QGraphicsView::AnchorUnderMouse);
    this->setSizePolicy(QSizePolicy::Preferred, QSizePolicy::Preferred);
    this->setSceneRect(-100.0, -100.0, 200.0, 200.0);
    this->scale(2.0, -2.0);
    this->centerOn(this->sceneRect().center());
    this->mBackgroundColor = QColor(Qt::white);

    connect(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->gridLinesAction, SIGNAL(toggled(bool)), this, SLOT(showGridLines(bool)));
}

void GraphicsView::drawBackground(QPainter *painter, const QRectF &rect)
{
    //! @todo Grid Lines changes when resize the window. Update it.
    painter->drawRect(this->sceneRect());
    if (this->mpParentProjectTab->mpParentProjectTabWidget->mShowLines)
    {
        painter->scale(1.0, -1.0);
        painter->setPen(Qt::gray);

        int xAxis = rect.x();
        int yAxis = rect.y();

        // Horizontal Lines
        while (yAxis < rect.height())
        {
            yAxis += 28;
            painter->drawLine(xAxis - 1, yAxis, xAxis + rect.width(), yAxis);
        }

        // Vertical Lines
        yAxis = rect.y();
        while (xAxis < rect.width())
        {
            xAxis += 14;
            painter->drawLine(xAxis - 1, yAxis, xAxis - 1, yAxis + rect.height());
        }
    }
}

//! Defines what happens when moving an object in a GraphicsView.
//! @param event contains information of the drag operation.
void GraphicsView::dragMoveEvent(QDragMoveEvent *event)
{

}

//! Defines what happens when drop an object in a GraphicsView.
//! @param event contains information of the drop operation.
void GraphicsView::dropEvent(QDropEvent *event)
{
    QTreeWidget *tree = dynamic_cast<QTreeWidget *>(event->source());
    QTreeWidgetItem *item = tree->currentItem();

    if (item->text(0).isEmpty())
        event->ignore();

    MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
    if (!pMainWindow->mpOMCProxy->isWhat(StringHandler::PACKAGE, item->toolTip(0)))
    {
        // Check if the icon is already loaded.
        IconAnnotation *oldIcon = mpParentProjectTab->mpParentProjectTabWidget->getGlobalIconObject(item->toolTip(0));
        IconAnnotation *newIcon;
        QString iconName = checkIconName(item->text(0).toLower());

        if (oldIcon == NULL)
        {
            QString result = pMainWindow->mpOMCProxy->getIconAnnotation(item->toolTip(0));
            newIcon = new IconAnnotation(result, iconName, item->toolTip(0), mapToScene(event->pos()),
                                         pMainWindow->mpOMCProxy, this->mpParentProjectTab->mpGraphicsScene, this);
            mpParentProjectTab->mpParentProjectTabWidget->addGlobalIconObject(newIcon);
            addIconObject(newIcon);
        }
        else
        {
            newIcon = new IconAnnotation(oldIcon, iconName, mapToScene(event->pos()),
                                         this->mpParentProjectTab->mpGraphicsScene, this);
            addIconObject(newIcon);
        }
        // Add the component to model in OMC Global Scope.
        pMainWindow->mpOMCProxy->addComponent(iconName, item->toolTip(0), mpParentProjectTab->mModelFileStrucrure);
        event->accept();
    }
    else
        event->ignore();
}

Connector* GraphicsView::getConnector()
{
    return this->mpConnector;
}

void GraphicsView::addIconObject(IconAnnotation *icon)
{
    mIconsList.append(icon);
}

void GraphicsView::deleteIconObject(IconAnnotation *icon)
{
    mIconsList.removeOne(icon);
    mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy->deleteComponent(icon->getName(), mpParentProjectTab->mModelFileStrucrure);
}

QString GraphicsView::checkIconName(QString iconName, int number)
{
    QString name;
    if (number > 0)
        name = iconName + QString::number(number);
    else
        name = iconName;
    foreach (IconAnnotation *icon, mIconsList)
    {
        if (icon->getName() == name)
        {
            name = checkIconName(iconName, ++number);
            break;
        }
    }
    return name;
}

//! Defines what happens when the mouse is moving in a GraphicsView.
//! @param event contains information of the mouse moving operation.
void GraphicsView::mouseMoveEvent(QMouseEvent *event)
{
    QGraphicsView::mouseMoveEvent(event);
    //this->setBackgroundBrush(mBackgroundColor);     //Refresh the viewport

    //If creating connector, the end port shall be updated to the mouse position.
    if (this->mIsCreatingConnector)
    {
        mpConnector->updateEndPoint(this->mapToScene(event->pos()));
        mpConnector->drawConnector();
    }
}

//! Defines what happens when clicking in a GraphicsView.
//! @param event contains information of the mouse click operation.
void GraphicsView::mousePressEvent(QMouseEvent *event)
{
    if ((event->button() == Qt::LeftButton) && (this->mIsCreatingConnector))
    {
        mpConnector->addPoint(this->mapToScene(event->pos()));
    }
    QGraphicsView::mousePressEvent(event);
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
    else if (event->modifiers() and Qt::ControlModifier and event->key() == Qt::Key_A)
        this->selectAll();
    else
        QGraphicsView::keyPressEvent (event);
}

//! Defines what shall happen when a key is released.
//! @param event contains information about the keypress operation.
void GraphicsView::keyReleaseEvent(QKeyEvent *event)
{
    QGraphicsView::keyReleaseEvent(event);
}

//! Begins creation of connector or complete creation of connector depending on the mIsCreatingConnector flag.
//! @param pPort is a pointer to the clicked port, either start or end depending on the mIsCreatingConnector flag.
//! @param doNotRegisterUndo is true if the added connector shall not be registered in the undo stack, for example if this function is called by a redo function.
void GraphicsView::addConnector(ComponentAnnotation *pComponent)
{
    //When clicking start port
    if (!mIsCreatingConnector)
    {
        QPointF startPos = pComponent->mapToScene(pComponent->boundingRect().center());

        this->mpConnector = new Connector(pComponent, this);

        this->scene()->addItem(mpConnector);
        this->mIsCreatingConnector = true;
        pComponent->getParentIcon()->addConnector(this->mpConnector);

        this->mpConnector->setStartComponent(pComponent);
        this->mpConnector->addPoint(startPos);
        this->mpConnector->addPoint(startPos);
        this->mpConnector->drawConnector();
    }
    else
    {
        ComponentAnnotation *pStartComponent = this->mpConnector->getStartComponent();
        // add the code to check of we can connect to component or not.
        MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
        if (pMainWindow->mpOMCProxy->addConnection(pStartComponent->getParentIcon()->getName() + "." +
                                                   pStartComponent->mpComponentProperties->getName(),
                                                   pComponent->getParentIcon()->getName() + "." +
                                                   pComponent->mpComponentProperties->getName(),
                                                   mpParentProjectTab->mModelFileStrucrure))
        {
            this->mIsCreatingConnector = false;
            QPointF newPos = pComponent->mapToScene(pComponent->boundingRect().center());
            this->mpConnector->updateEndPoint(newPos);
            pComponent->getParentIcon()->addConnector(this->mpConnector);
            this->mpConnector->setEndComponent(pComponent);
        }
        else
        {
            //! @todo Make the addconnection feature better. OMC doesn't handle the wrong connections.
            pMainWindow->mpMessageWidget->printGUIErrorMessage(pMainWindow->mpOMCProxy->getErrorString());
        }
    }
}

//! Resets zoom factor to 100%.
//! @see zoomIn()
//! @see zoomOut()
void GraphicsView::resetZoom()
{
    this->resetMatrix();
    this->scale(5.3, -2.3);
}

//! Increases zoom factor by 15%.
//! @see resetZoom()
//! @see zoomOut()
void GraphicsView::zoomIn()
{
    this->scale(1.15, 1.15);
}

//! Decreases zoom factor by 13.04% (1 - 1/1.15).
//! @see resetZoom()
//! @see zoomIn()
void GraphicsView::zoomOut()
{
    this->scale(1/1.15, 1/1.15);
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
    foreach (IconAnnotation *icon, mIconsList)
    {
        icon->setSelected(true);
    }
}

//! @class GraphicsScene
//! @brief The GraphicsScene class is a container for graphicsl components in a simulationmodel.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
GraphicsScene::GraphicsScene(ProjectTab *parent)
        :   QGraphicsScene(parent)
{
    mpParentProjectTab = parent;
}

//! @class ProjectTab
//! @brief The ProjectTab class is a Widget to contain a simulation model

//! ProjectTab contains a drawing space to create models.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
ProjectTab::ProjectTab(ProjectTabWidget *parent)
    : QWidget(parent)
{
    mpParentProjectTabWidget = parent;
    if (!mpParentProjectTabWidget->mpParentMainWindow->gridLinesAction->isEnabled())
        mpParentProjectTabWidget->mpParentMainWindow->gridLinesAction->setEnabled(true);

    mpGraphicsScene = new GraphicsScene(this);
    mpGraphicsView  = new GraphicsView(this);
    mpGraphicsView->setScene(mpGraphicsScene);

    mpModelicaModelButton = new QPushButton(QIcon("../OMEditGUI/Resources/icons/model.png"), tr("Modeling"), this);
    mpModelicaModelButton->setIconSize(QSize(25, 25));
    mpModelicaModelButton->setObjectName(tr("ModelicaModelButton"));
    mpModelicaModelButton->setCheckable(true);
    mpModelicaModelButton->setChecked(true);
    connect(mpModelicaModelButton, SIGNAL(clicked()), this, SLOT(showModelicaModel()));

    mpModelicaTextButton = new QPushButton(QIcon("../OMEditGUI/Resources/icons/modeltext.png") ,tr("Model Text"), this);
    mpModelicaTextButton->setIconSize(QSize(25, 25));
    mpModelicaTextButton->setCheckable(true);
    mpModelicaTextButton->setObjectName(tr("ModelicaTextButton"));
    connect(mpModelicaTextButton, SIGNAL(clicked()), this, SLOT(showModelicaText()));

    mpEditBox = new QTextEdit(this);
    mpEditBox->hide();

    QHBoxLayout *layout = new QHBoxLayout();
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setAlignment(Qt::AlignRight);
    layout->addWidget(mpModelicaModelButton);
    layout->addWidget(mpModelicaTextButton);

    QVBoxLayout *tabLayout = new QVBoxLayout;
    //tabLayout->setContentsMargins(0, 0, 0, 0);
    tabLayout->addWidget(mpGraphicsView);
    tabLayout->addWidget(mpEditBox);
    tabLayout->addItem(layout);
    setLayout(tabLayout);
}

void ProjectTab::showModelicaModel()
{
    mpModelicaModelButton->setChecked(true);
    mpModelicaTextButton->setChecked(false);
    mpEditBox->hide();
    mpGraphicsView->show();
}

void ProjectTab::showModelicaText()
{
    mpModelicaModelButton->setChecked(false);
    mpModelicaTextButton->setChecked(true);
    mpGraphicsView->hide();
    // get the modelica text of the model
    mpEditBox->setText(mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy->list(mModelFileStrucrure));
    mpEditBox->show();
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
    this->mShowLines = false;
    if (this->count() == 0)
        mpParentMainWindow->gridLinesAction->setEnabled(false);
    connect(this,SIGNAL(tabCloseRequested(int)),SLOT(closeProjectTab(int)));
    connect(mpParentMainWindow->resetZoomAction, SIGNAL(triggered()),this,SLOT(resetZoom()));
    connect(mpParentMainWindow->zoomInAction, SIGNAL(triggered()),this,SLOT(zoomIn()));
    connect(mpParentMainWindow->zoomOutAction, SIGNAL(triggered()),this,SLOT(zoomOut()));
}

//! Returns a pointer to the currently active project tab
ProjectTab *ProjectTabWidget::getCurrentTab()
{
    return qobject_cast<ProjectTab *>(currentWidget());
}

void ProjectTabWidget::addGlobalIconObject(IconAnnotation *icon)
{
    mGlobalIconsList.append(icon);
}

IconAnnotation* ProjectTabWidget::getGlobalIconObject(QString className)
{
    foreach (IconAnnotation* icon, mGlobalIconsList)
    {
        if (icon->getClassName() == className)
            return icon;
    }
    return NULL;
}

//! Adds an existing ProjectTab object to itself.
//! @see closeProjectTab(int index)
void ProjectTabWidget::addProjectTab(ProjectTab *projectTab, QString tabName)
{
    projectTab->setParent(this);
    addTab(projectTab, tabName);
    setCurrentWidget(projectTab);
}

//! Adds a ProjectTab object (a new tab) to itself.
//! @see closeProjectTab(int index)
void ProjectTabWidget::addNewProjectTab(QString modelName, QString modelStructure)
{
    ProjectTab *newTab = new ProjectTab(this);
    newTab->mModelFileName = modelName;
    newTab->mModelFileStrucrure = modelStructure + modelName;
    addTab(newTab, modelName.append(QString("*")));
    setCurrentWidget(newTab);
}

//! Closes current project.
//! @param index defines which project to close.
//! @return true if closing went ok. false if the user canceled the operation.
//! @see closeAllProjectTabs()
bool ProjectTabWidget::closeProjectTab(int index)
{
    removeTab(index);
    if (this->count() == 0)
        mpParentMainWindow->gridLinesAction->setEnabled(false);
    return true;
}

//! Closes all opened projects.
//! @return true if closing went ok. false if the user canceled the operation.
//! @see closeProjectTab(int index)
//! @see saveProjectTab()
bool ProjectTabWidget::closeAllProjectTabs()
{
    while(count() > 0)
    {
        setCurrentIndex(count()-1);
        if (!closeProjectTab(count()-1))
        {
            return false;
        }
    }
    return true;
}

//! Loads a model from a file and opens it in a new project tab.
//! @see saveModel(bool saveAs)
void ProjectTabWidget::loadModel()
{
    QString fileName = QFileDialog::getOpenFileName(this, tr("Choose File"),
                                                    QDir::currentPath() + QString("/../.."),
                                                    Helper::omFileOpenText);
    if (fileName.isEmpty())
        return;

    this->mpParentMainWindow->mpLibrary->loadModel(fileName);
}

//! Tells the current tab to reset zoom to 100%.
//! @see zoomIn()
//! @see zoomOut()
void ProjectTabWidget::resetZoom()
{
    this->getCurrentTab()->mpGraphicsView->resetZoom();
}

//! Tells the current tab to increase its zoom factor.
//! @see resetZoom()
//! @see zoomOut()
void ProjectTabWidget::zoomIn()
{
    this->getCurrentTab()->mpGraphicsView->zoomIn();
}

//! Tells the current tab to decrease its zoom factor.
//! @see resetZoom()
//! @see zoomIn()
void ProjectTabWidget::zoomOut()
{
    this->getCurrentTab()->mpGraphicsView->zoomOut();
}
