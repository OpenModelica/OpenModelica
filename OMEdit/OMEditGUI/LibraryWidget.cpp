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
#include <map>
#include <iostream>

#include "LibraryWidget.h"

ModelicaTreeNode::ModelicaTreeNode(QString text, QString tooltip, int type, QTreeWidget *parent)
    :QTreeWidgetItem(parent)
{
    mType = type;
    mName = text;
    mNameStructure = tooltip;

    setText(0, mName);
    setToolTip(0, mNameStructure);
    setIcon(0, getModelicaNodeIcon(mType));
}

QIcon ModelicaTreeNode::getModelicaNodeIcon(int type)
{
    switch (type)
    {
    case StringHandler::MODEL:
        return QIcon(":/Resources/icons/model-icon.png");
    case StringHandler::CLASS:
        return QIcon(":/Resources/icons/class-icon.png");
    case StringHandler::CONNECTOR:
        return QIcon(":/Resources/icons/connector-icon.png");
    case StringHandler::RECORD:
        return QIcon(":/Resources/icons/record-icon.png");
    case StringHandler::BLOCK:
        return QIcon(":/Resources/icons/block-icon.png");
    case StringHandler::FUNCTION:
        return QIcon(":/Resources/icons/function-icon.png");
    case StringHandler::PACKAGE:
        return QIcon(":/Resources/icons/package-icon.png");
    }
}

ModelicaTree::ModelicaTree(LibraryWidget *parent)
    : QTreeWidget(parent)
{
    mpParentLibraryWidget = parent;

    setFrameShape(QFrame::NoFrame);
    setHeaderLabel(tr("Modelica Files"));
    setIconSize(Helper::iconSize);
    setColumnCount(1);
    setIndentation(Helper::treeIndentation);
    setContextMenuPolicy(Qt::CustomContextMenu);
    setExpandsOnDoubleClick(false);

    createActions();

    connect(this, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), SLOT(openProjectTab(QTreeWidgetItem*,int)));
    connect(this, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
    connect(mpParentLibraryWidget, SIGNAL(addModelicaTreeNode(QString,int,QString,QString)),
            SLOT(addNode(QString,int,QString,QString)));
}

ModelicaTree::~ModelicaTree()
{
    // delete all the items in the tree
    for (int i = 0; i < topLevelItemCount(); ++i)
        qDeleteAll(topLevelItem(i)->takeChildren());
}

void ModelicaTree::createActions()
{
    mRenameAction = new QAction(QIcon(":/Resources/icons/rename.png"), tr("Rename"), this);
    connect(mRenameAction, SIGNAL(triggered()), SLOT(renameClass()));

    mCheckModelAction = new QAction(QIcon(":/Resources/icons/check.png"), tr("Check"), this);
    connect(mCheckModelAction, SIGNAL(triggered()), SLOT(checkClass()));

    mDeleteAction = new QAction(QIcon(":/Resources/icons/delete.png"), tr("Delete"), this);
    connect(mDeleteAction, SIGNAL(triggered()), SLOT(deleteNodeTriggered()));
}

ModelicaTreeNode* ModelicaTree::getNode(QString name)
{
    foreach (ModelicaTreeNode *node, mModelicaTreeNodesList)
    {
        if (node->mNameStructure == name)
            return node;
    }
    return 0;
}

void ModelicaTree::deleteNode(ModelicaTreeNode *item)
{
    MainWindow *pMainWindow = mpParentLibraryWidget->mpParentMainWindow;
    ProjectTab *pCurrentTab;
    int count = item->childCount();
    // Close the corresponding tabs if open
    for (int i = 0 ; i < count ; i++)
    {
        ModelicaTreeNode *treeNode = dynamic_cast<ModelicaTreeNode*>(item->child(i));
        deleteNode(treeNode);
    }
    // Delete the node from list as well
    mModelicaTreeNodesList.removeOne(item);
    // Delete the tab of the parent item as well
    pCurrentTab = pMainWindow->mpProjectTabs->getTabByName(item->mNameStructure);
    if (pCurrentTab)
    {
        pMainWindow->mpProjectTabs->removeTab(pCurrentTab->mTabPosition);
        emit nodeDeleted();
    }
    // Delete the complete tree node now
    //delete item;
}

void ModelicaTree::addNode(QString name, int type, QString parentName, QString parentStructure)
{
    ModelicaTreeNode *newTreePost;

    if (parentName.isEmpty())
    {
        newTreePost = new ModelicaTreeNode(name, parentStructure + name, type, this);
        insertTopLevelItem(0, newTreePost);
    }
    else
    {
        newTreePost = new ModelicaTreeNode(name, parentStructure + name, type);
        ModelicaTreeNode *treeNode = getNode(StringHandler::removeLastDot(parentStructure));
        treeNode->addChild(newTreePost);
    }
    setCurrentItem(newTreePost);
    mModelicaTreeNodesList.append(newTreePost);
}

void ModelicaTree::openProjectTab(QTreeWidgetItem *item, int column)
{
    bool isFound = false;
    // if the clicked item is model
    ModelicaTreeNode *treeNode = dynamic_cast<ModelicaTreeNode*>(item);
    ProjectTab *pCurrentTab;
    MainWindow *pMainWindow = mpParentLibraryWidget->mpParentMainWindow;
    pCurrentTab = mpParentLibraryWidget->mpParentMainWindow->mpProjectTabs->getTabByName(treeNode->mNameStructure);
    if (pCurrentTab)
    {
        pMainWindow->mpProjectTabs->setCurrentWidget(pCurrentTab);
        isFound = true;
    }
    // if the tab is closed by user then reopen it and set it as current tab
    if (!isFound)
    {
        //! @todo make it better load the model here and get the components required.
        ProjectTab *newTab = new ProjectTab(pMainWindow->mpProjectTabs);
        pMainWindow->mpProjectTabs->addProjectTab(newTab, treeNode->mName, treeNode->mNameStructure, treeNode->mType);
    }
}

void ModelicaTree::showContextMenu(QPoint point)
{
    int adjust = 24;
    QTreeWidgetItem *item = 0;
    item = itemAt(point);

    if (item)
    {
        mpParentLibraryWidget->mSelectedModelicaNode = dynamic_cast<ModelicaTreeNode*>(item);
        QMenu menu(mpParentLibraryWidget);
        menu.addAction(mRenameAction);
        menu.addAction(mCheckModelAction);
        menu.addAction(mDeleteAction);
        point.setY(point.y() + adjust);
        menu.exec(mapToGlobal(point));
    }
}

void ModelicaTree::renameClass()
{
    RenameClassWidget *widget = new RenameClassWidget(mpParentLibraryWidget->mSelectedModelicaNode->mName,
                                                      mpParentLibraryWidget->mSelectedModelicaNode->mNameStructure,
                                                      mpParentLibraryWidget->mpParentMainWindow);
    widget->show();
}

void ModelicaTree::checkClass()
{

}

bool ModelicaTree::deleteNodeTriggered(ModelicaTreeNode *node)
{
    QString msg;
    MainWindow *pMainWindow = mpParentLibraryWidget->mpParentMainWindow;
    ModelicaTreeNode *treeNode;
    if (!node)
        treeNode = mpParentLibraryWidget->mSelectedModelicaNode;
    else
        treeNode = node;

    switch (treeNode->mType)
    {
    case StringHandler::PACKAGE:
        msg = "Are you sure you want to delete? Everything contained inside this Package will also be deleted.";
        break;
    default:
        msg = "Are you sure you want to delete?";
        break;
    }

    QMessageBox *msgBox = new QMessageBox(pMainWindow);
    msgBox->setWindowTitle(QString(Helper::applicationName).append(" - Question"));
    msgBox->setIcon(QMessageBox::Question);
    msgBox->setText(msg);
    msgBox->setStandardButtons(QMessageBox::Yes | QMessageBox::No);
    msgBox->setDefaultButton(QMessageBox::Yes);

    int answer = msgBox->exec();

    switch (answer)
    {
    case QMessageBox::Yes:
        // Yes was clicked. Don't return.
        break;
    case QMessageBox::No:
        // No was clicked
        return false;
    default:
        // should never be reached
        return false;
    }

    if (pMainWindow->mpOMCProxy->deleteClass(treeNode->mNameStructure))
    {
        // print the message before deleting node,
        // because after delete node is not available to print message :)
        pMainWindow->mpMessageWidget->printGUIInfoMessage(treeNode->mName + " deleted successfully.");
        deleteNode(treeNode);
        if (treeNode->childCount())
            qDeleteAll(treeNode->takeChildren());
        delete treeNode;
        return true;
    }
    else
    {
        pMainWindow->mpMessageWidget->printGUIInfoMessage(GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED)
                                                          .arg(pMainWindow->mpOMCProxy->getResult())
                                                          .append("while deleting " + treeNode->mName));
        return false;
    }
}

LibraryTree::LibraryTree(LibraryWidget *pParent)
    : QTreeWidget(pParent)
{
    mpParentLibraryWidget = pParent;

    setFrameShape(QFrame::NoFrame);
    setHeaderLabel(tr("Modelica Standard Library"));
    setIndentation(Helper::treeIndentation);
    setDragEnabled(true);
    setIconSize(Helper::iconSize);
    setColumnCount(1);
    setExpandsOnDoubleClick(false);
    setContextMenuPolicy(Qt::CustomContextMenu);
    createActions();

    connect(this, SIGNAL(itemExpanded(QTreeWidgetItem*)), SLOT(showLib(QTreeWidgetItem*)));
    connect(this, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
}

LibraryTree::~LibraryTree()
{
    // delete all the items in the tree
    for (int i = 0; i < topLevelItemCount(); ++i)
        qDeleteAll(topLevelItem(i)->takeChildren());
}

void LibraryTree::createActions()
{
    mShowComponentAction = new QAction(QIcon(":/Resources/icons/rename.png"), tr("Show Component"), this);
    connect(mShowComponentAction, SIGNAL(triggered()), SLOT(showComponent()));

    mViewDocumentationAction = new QAction(QIcon(":/Resources/icons/check.png"), tr("View Documentation"), this);
    connect(mViewDocumentationAction, SIGNAL(triggered()), SLOT(viewDocumentation()));
}

//! Let the user add the OM Standard Library to library widget.
void LibraryTree::addModelicaStandardLibrary()
{
    // load Modelica Standard Library.
    mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy->loadStandardLibrary();
    if (mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy->isStandardLibraryLoaded())
    {
        QTreeWidgetItem *newTreePost = new QTreeWidgetItem((QTreeWidget*)0);
        newTreePost->setText(0, QString("Modelica"));
        newTreePost->setToolTip(0, QString("Modelica"));
        newTreePost->setChildIndicatorPolicy(QTreeWidgetItem::ShowIndicator);
        insertTopLevelItem(0, newTreePost);
//        addClass("Ground", "", "Modelica.Electrical.Analog.Basic.", true);
//        addClass("Resistor", "", "Modelica.Electrical.Analog.Basic.", true);
    }
}

//! Adds a whole tree structure hierarchy of OM Standard library to the library widget.
//! @param value is the name of the class.
//! @param prefixstr is the name of the parent hierarchy of the class.
void LibraryTree::loadModelicaLibraryHierarchy(QString value, QString prefixStr)
{
    if (mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy->isPackage(value))
    {
        QStringList list = mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy->getClassNames(value);
        prefixStr += value + ".";
        foreach (QString str, list)
        {
            addClass(str, StringHandler::getSubStringFromDots(prefixStr), prefixStr, true);
        }
    }

    /*
        Open the Following code and comment the above if loading library once.
    */

//    if (this->mpParentMainWindow->mpOMCProxy->isPackage(prefixStr + value))
//    {
//        //if value is Modelica then dont send it to addClass. Because we already added it statically.
//        if (value != tr("Modelica"))
//        {
//            this->mpParentMainWindow->statusBar->showMessage(QString("Loading: ").append(prefixStr + value));
//            addClass(value, StringHandler::getSubStringFromDots(prefixStr), prefixStr);
//        }
//        QStringList list = this->mpParentMainWindow->mpOMCProxy->getClassNames(prefixStr + value);
//        prefixStr += value + ".";
//        foreach (QString str, list)
//        {
//            loadModelicaLibraryHierarchy(str, prefixStr);
//        }
//    }
//    else
//    {
//        addClass(value, StringHandler::getSubStringFromDots(prefixStr), prefixStr);
//    }
}

//! Let the user to point out a OM Class and adds it to the library widget.
//! @param className is the name of the OM Class.
//! @param parentClassName is the name of the parent OM Class where the OM Class should be added.
//! @param parentStructure is the name of the parent hierarchy of the OM Class where, used as a tooltip.
//! @param hasIcon is the boolean value indicating whether the class has IconAnnotation or not.
void LibraryTree::addClass(QString className, QString parentClassName, QString parentStructure, bool hasIcon)
{
    mpParentLibraryWidget->mpParentMainWindow->statusBar->showMessage(QString("Loading: ")
                                                                      .append(parentStructure + className));
    QTreeWidgetItem *newTreePost = new QTreeWidgetItem((QTreeWidget*)0);
    newTreePost->setText(0, QString(className));
    newTreePost->setToolTip(0, QString(parentStructure + className));

    // If Loaded class is package show treewidgetitem expand indicator
    // Remove if using load once library feature
    if (mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy->isPackage(parentStructure + className))
    {
        newTreePost->setChildIndicatorPolicy(QTreeWidgetItem::ShowIndicator);
        hasIcon = false;
    }

    if (hasIcon)
    {
        QString result;
        result = mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy->getIconAnnotation(parentStructure + className);
        LibraryComponent *libComponent = new LibraryComponent(result, parentStructure + className,
                                                              mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy);

        newTreePost->setIcon(0, QIcon(libComponent->getComponentPixmap(Helper::iconSize)));
        mpParentLibraryWidget->addComponentObject(libComponent);
    }

    if (parentClassName.isEmpty())
    {
        insertTopLevelItem(0, newTreePost);
    }
    else
    {
        QTreeWidgetItemIterator it(this);
        while (*it)
        {
            if ((*it)->toolTip(0) == StringHandler::removeLastDot(parentStructure))
            {
                (*it)->addChild(newTreePost);
            }
            ++it;
        }
    }
}

bool LibraryTree::isTreeItemLoaded(QTreeWidgetItem *item)
{
    foreach (QString str, mTreeList)
        if (str == item->toolTip(0))
            return false;
    return true;
}

//! Makes a library visible.
//! @param item is the library to show.
//! @param column is the position of the library name in the tree.
//! @see hideAllLib()
void LibraryTree::showLib(QTreeWidgetItem *item)
{
    if (isTreeItemLoaded(item))
    {
        mTreeList.append(item->toolTip(0));
        // Set the cursor to wait.
        setCursor(Qt::WaitCursor);
        loadModelicaLibraryHierarchy(item->toolTip(0));
        item->setExpanded(true);
        mpParentLibraryWidget->mpParentMainWindow->statusBar->clearMessage();
        // Remove the wait cursor
        unsetCursor();
    }

    /*
        Open the Following code and comment the above if loading library once.
    */

    // disconnect the mpTree itemClicked and itemExpanded signals
//    disconnect(mpTree, SIGNAL(itemClicked(QTreeWidgetItem*,int)), this, SLOT(showLib(QTreeWidgetItem*)));
//    disconnect(mpTree, SIGNAL(itemExpanded(QTreeWidgetItem*)), this, SLOT(showLib(QTreeWidgetItem*)));

//    // Set the cursor to wait.
//    setCursor(Qt::WaitCursor);
//    // Delete the temp entry now
//    item->removeChild(item->child(0));
//    loadModelicaLibraryHierarchy(tr("Modelica"));
//    this->mpParentMainWindow->statusBar->clearMessage();
//    //mpTree->sortItems(0, Qt::AscendingOrder);
//    // Remove the wait cursor
//    unsetCursor();
}

void LibraryTree::showContextMenu(QPoint point)
{
    int adjust = 24;
    QTreeWidgetItem *item = 0;
    item = itemAt(point);

    if (item)
    {
        mpParentLibraryWidget->mSelectedLibraryNode = item;
        QMenu menu(this);
        menu.addAction(mShowComponentAction);
        menu.addAction(mViewDocumentationAction);
        point.setY(point.y() + adjust);
        menu.exec(mapToGlobal(point));
    }
}

void LibraryTree::showComponent()
{
    ProjectTabWidget *pProjectTabs = mpParentLibraryWidget->mpParentMainWindow->mpProjectTabs;
    pProjectTabs->addDiagramViewTab(mpParentLibraryWidget->mSelectedLibraryNode, 0);
}

void LibraryTree::viewDocumentation()
{
    MainWindow *pMainWindow = mpParentLibraryWidget->mpParentMainWindow;
    pMainWindow->documentationdock->show();
    pMainWindow->mpDocumentationWidget->show(mpParentLibraryWidget->mSelectedLibraryNode->toolTip(0));
}

void LibraryTree::mousePressEvent(QMouseEvent *event)
{
    QTreeWidget::mousePressEvent(event);

    if ((event->button() == Qt::LeftButton))
    {
        QTreeWidgetItem *item = static_cast<QTreeWidgetItem*>(itemAt(event->pos()));
        if (!item)
            return;

        // if item is package then return
        if (mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy->isWhat(StringHandler::PACKAGE, item->toolTip(0)))
            return;

        QByteArray itemData;
        QDataStream dataStream(&itemData, QIODevice::WriteOnly);
        dataStream << item->toolTip(0);

        QMimeData *mimeData = new QMimeData;
        mimeData->setData("image/modelica-component", itemData);

        qreal adjust = 35;
        QDrag *drag = new QDrag(this);
        drag->setMimeData(mimeData);

        // get the component SVG to show on drag
        LibraryComponent *libraryComponent = mpParentLibraryWidget->getLibraryComponentObject(item->toolTip(0));

        if (libraryComponent)
        {
            QPixmap pixmap = libraryComponent->getComponentPixmap(QSize(50, 50));
            drag->setPixmap(pixmap);
            drag->setHotSpot(QPoint((drag->hotSpot().x() + adjust), (drag->hotSpot().y() + adjust)));
        }
        drag->exec(Qt::CopyAction);
    }
}

//! Constructor.
//! @param parent defines a parent to the new instanced object.
LibraryWidget::LibraryWidget(MainWindow *parent)
    : QWidget(parent)
{
    mpParentMainWindow = parent;

    mpLibraryTabs = new QTabWidget;
    mpLibraryTabs->setTabPosition(QTabWidget::South);

    mpLibraryTree = new LibraryTree(this);
    mpModelicaTree = new ModelicaTree(this);

    mpLibraryTabs->addTab(mpLibraryTree, "Modelica Library");
    mpLibraryTabs->addTab(mpModelicaTree, "Modelica Files");

    mpGrid = new QVBoxLayout(this);
    mpGrid->setContentsMargins(0, 0, 0, 0);
    mpGrid->addWidget(mpLibraryTabs);

    setLayout(mpGrid);
}

LibraryWidget::~LibraryWidget()
{
    // delete all the loaded components
    foreach (LibraryComponent *libraryComponent, mComponentsList)
    {
        delete libraryComponent;
    }
    delete mpLibraryTree;
    delete mpModelicaTree;
    delete mpLibraryTabs;
}

void LibraryWidget::addModelicaNode(QString name, int type, QString parentName, QString parentStructure)
{
    emit addModelicaTreeNode(name, type, parentName, parentStructure);
}

void LibraryWidget::addModelFiles(QString fileName, QString parentFileName, QString parentStructure)
{
    if (parentFileName.isEmpty())
    {
        this->addModelicaNode(fileName, mpParentMainWindow->mpOMCProxy->getClassRestriction(fileName),
                              parentFileName, parentStructure);
        parentStructure = fileName;
    }
    else
    {
        this->addModelicaNode(fileName, mpParentMainWindow->mpOMCProxy->getClassRestriction(parentStructure),
                              parentFileName, StringHandler::removeLastWordAfterDot(parentStructure).append("."));
    }

    if (this->mpParentMainWindow->mpOMCProxy->isPackage(parentStructure))
    {
        QStringList modelsList = this->mpParentMainWindow->mpOMCProxy->getClassNames(parentStructure);
        foreach (QString model, modelsList)
        {
            addModelFiles(model, fileName, parentStructure + tr(".") + model);
        }
    }
}

void LibraryWidget::loadModel(QString path, QStringList modelsList)
{
    // load the file in OMC
    mpParentMainWindow->mpOMCProxy->loadFile(path);

    foreach (QString model, modelsList)
    {
        addModelFiles(model, tr(""), tr(""));
    }
    // make the modelica files tab visible in library widget dock window
    mpLibraryTabs->setCurrentWidget(mpModelicaTree);
}

void LibraryWidget::addComponentObject(LibraryComponent *libraryComponent)
{
    mComponentsList.append(libraryComponent);
}

Component* LibraryWidget::getComponentObject(QString className)
{
    foreach (LibraryComponent *libraryComponent, mComponentsList)
    {
        if (libraryComponent->mClassName == className)
            return libraryComponent->mpComponent;
    }
    return 0;
}

LibraryComponent* LibraryWidget::getLibraryComponentObject(QString className)
{
    foreach (LibraryComponent *libraryComponent, mComponentsList)
    {
        if (libraryComponent->mClassName == className)
            return libraryComponent;
    }
    return 0;
}

void LibraryWidget::updateNodeText(QString text, QString textStructure, ModelicaTreeNode *node)
{
    ModelicaTreeNode *treeNode;
    if (!node)
        treeNode = mSelectedModelicaNode;
    else
        treeNode = node;

    // update the corresponding tab
    ProjectTab *pCurrentTab = mpParentMainWindow->mpProjectTabs->getTabByName(treeNode->mNameStructure);
    if (pCurrentTab)
    {
        pCurrentTab->updateTabName(text, textStructure);
    }

    // udate the node
    treeNode->mName = text;
    treeNode->mNameStructure = textStructure;
    treeNode->setText(0, text);
    treeNode->setToolTip(0, textStructure);

    // if the node has childs
    int count = treeNode->childCount();
    for (int i = 0 ; i < count ; i++)
    {
        // update the tabs of child nodes
        ModelicaTreeNode *item = dynamic_cast<ModelicaTreeNode*>(treeNode->child(i));
        updateNodeText(item->mName, QString(textStructure).append(".").append(item->mName), item);
    }
}

LibraryComponent::LibraryComponent(QString value, QString className, OMCProxy *omc)
{
    mClassName = className;
    mpComponent = new Component(value, className, omc);
    if (mpComponent->mRectangle.width() < 1)
        return;

    QRectF rect = mpComponent->mRectangle;
    qreal adjust = 22;
    rect.setX(rect.x() - adjust);
    rect.setY(rect.y() - adjust);
    rect.setWidth(rect.width() + adjust);
    rect.setHeight(rect.height() + adjust);


    QByteArray byteArray;
    QBuffer buffer(&byteArray);
    buffer.open(QIODevice::WriteOnly);

    QSvgGenerator svgGenerator;
    svgGenerator.setOutputDevice(&buffer);
    svgGenerator.setSize(QSize(rect.width(), rect.height()));
    svgGenerator.setViewBox(rect);

    QPainter painter;
    painter.begin(&svgGenerator);
    painter.scale(1.0, -1.0);

    generateSvg(&painter, mpComponent);

    painter.end();
    mSvgByteArray = byteArray;
    buffer.close();
}

LibraryComponent::~LibraryComponent()
{
    delete mpComponent;
}

void LibraryComponent::generateSvg(QPainter *painter, Component *pComponent)
{
    foreach (ShapeAnnotation *shape, pComponent->mpShapesList)
    {
        if (dynamic_cast<LineAnnotation*>(shape))
            dynamic_cast<LineAnnotation*>(shape)->drawLineAnnotaion(painter);
        if (dynamic_cast<PolygonAnnotation*>(shape))
            dynamic_cast<PolygonAnnotation*>(shape)->drawPolygonAnnotaion(painter);
        if (dynamic_cast<RectangleAnnotation*>(shape))
            dynamic_cast<RectangleAnnotation*>(shape)->drawRectangleAnnotaion(painter);
        if (dynamic_cast<EllipseAnnotation*>(shape))
            dynamic_cast<EllipseAnnotation*>(shape)->drawEllipseAnnotaion(painter);
    }

    foreach (Component *inheritance, pComponent->mpInheritanceList)
    {
        generateSvg(painter, inheritance);
    }

    foreach (Component *component, pComponent->mpComponentsList)
    {
        painter->save();
        painter->setTransform(component->mpTransformation->getLibraryTransformationMatrix());
        generateSvg(painter, component);
        painter->restore();
    }
}

QPixmap LibraryComponent::getComponentPixmap(QSize size)
{
    QSvgRenderer svgRenderer(mSvgByteArray);
    QPixmap pixmap(size);
    pixmap.fill(QColor(Qt::transparent));
    QPainter painter(&pixmap);
    svgRenderer.render(&painter);
    painter.end();
    return pixmap;
}
