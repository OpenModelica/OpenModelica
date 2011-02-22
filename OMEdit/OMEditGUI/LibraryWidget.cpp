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

ModelicaTreeNode::ModelicaTreeNode(QString text, QString parentName, QString tooltip, int type, QTreeWidget *parent)
    : QTreeWidgetItem(parent)
{
    mType = type;
    mName = text;
    mParentName = parentName;
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
    case StringHandler::TYPE:
        return QIcon(":/Resources/icons/type-icon.png");
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
    mpRenameAction = new QAction(QIcon(":/Resources/icons/rename.png"), tr("Rename"), this);
    connect(mpRenameAction, SIGNAL(triggered()), SLOT(renameClass()));

    mpCheckModelAction = new QAction(QIcon(":/Resources/icons/check.png"), tr("Check"), this);
    connect(mpCheckModelAction, SIGNAL(triggered()), SLOT(checkModelicaModel()));

    mpDeleteAction = new QAction(QIcon(":/Resources/icons/delete.png"), tr("Delete"), this);
    connect(mpDeleteAction, SIGNAL(triggered()), SLOT(deleteNodeTriggered()));
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
    // Delete the tab from the list of removed tabs
    else
    {
        pCurrentTab = pMainWindow->mpProjectTabs->getRemovedTabByName(item->mNameStructure);
        if (pCurrentTab)
        {
            pMainWindow->mpProjectTabs->mRemovedTabsList.removeOne(pCurrentTab);
        }
    }
}

void ModelicaTree::removeChildNodes(ModelicaTreeNode *item)
{
    int count = item->childCount();

    for (int i = 0 ; i < count ; i++)
    {
        ModelicaTreeNode *treeNode = dynamic_cast<ModelicaTreeNode*>(item->child(i));
        deleteNode(treeNode);
    }
    // remove the items from the tree as well
    if (item->childCount())
        qDeleteAll(item->takeChildren());
}

void ModelicaTree::addNode(QString name, int type, QString parentName, QString parentStructure)
{
    ModelicaTreeNode *newTreePost;

    if (parentName.isEmpty())
    {
        newTreePost = new ModelicaTreeNode(name, parentName, parentStructure + name, type, this);
        insertTopLevelItem(0, newTreePost);
    }
    else
    {
        newTreePost = new ModelicaTreeNode(name, parentName, parentStructure + name, type);
        ModelicaTreeNode *treeNode = getNode(StringHandler::removeLastDot(parentStructure));
        treeNode->addChild(newTreePost);
    }
    setCurrentItem(newTreePost);
    mModelicaTreeNodesList.append(newTreePost);
}

void ModelicaTree::openProjectTab(QTreeWidgetItem *item, int column)
{
    Q_UNUSED(column);
    // set the cursor to wait cursor
    setCursor(Qt::WaitCursor);

    bool isFound = false;
    // if the clicked item is model
    ModelicaTreeNode *treeNode = dynamic_cast<ModelicaTreeNode*>(item);
    ProjectTab *pCurrentTab;
    MainWindow *pMainWindow = mpParentLibraryWidget->mpParentMainWindow;
    pCurrentTab = pMainWindow->mpProjectTabs->getTabByName(treeNode->mNameStructure);
    if (pCurrentTab)
    {
        pMainWindow->mpProjectTabs->setCurrentWidget(pCurrentTab);
        isFound = true;
    }
    // if the tab is closed by user then reopen it and set it as current tab
    if (!isFound)
    {
        pCurrentTab = pMainWindow->mpProjectTabs->getRemovedTabByName(treeNode->mNameStructure);
        if (pCurrentTab)
        {
            pMainWindow->mpProjectTabs->addTab(pCurrentTab, pCurrentTab->mModelName);
            pMainWindow->mpProjectTabs->setCurrentWidget(pCurrentTab);
            pMainWindow->mpProjectTabs->mRemovedTabsList.removeOne(pCurrentTab);
            isFound = true;
        }
    }
    // if the tab is not found in current tabs and removed tabs then user has loaded a new model, just open it then
    if (!isFound)
    {
        ProjectTab *newTab;
        if (treeNode->mParentName.isEmpty())
        {
            newTab = new ProjectTab(treeNode->mType, StringHandler::ICON, false, false, pMainWindow->mpProjectTabs);
        }
        else
        {
            newTab = new ProjectTab(treeNode->mType, StringHandler::ICON, false, true, pMainWindow->mpProjectTabs);
            newTab->mIsSaved = true;
        }
        pMainWindow->mpProjectTabs->addProjectTab(newTab, treeNode->mName, treeNode->mNameStructure);
        // make the icon view visible and focused for key press events
        newTab->showIconView(true);
    }
    // unset the cursor
    unsetCursor();
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
        menu.addAction(mpRenameAction);
        menu.addAction(mpDeleteAction);
        menu.addAction(mpCheckModelAction);
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

void ModelicaTree::checkModelicaModel()
{
    // validate the modelica text before checking the model
    ProjectTab *pCurrentTab = mpParentLibraryWidget->mpParentMainWindow->mpProjectTabs->getCurrentTab();
    if (pCurrentTab)
    {
        if (!pCurrentTab->mpModelicaEditor->validateText())
            return;
    }

    CheckModelWidget *widget = new CheckModelWidget(mpParentLibraryWidget->mSelectedModelicaNode->mName,
                                                    mpParentLibraryWidget->mSelectedModelicaNode->mNameStructure,
                                                    mpParentLibraryWidget->mpParentMainWindow);
    widget->show();
}

bool ModelicaTree::deleteNodeTriggered(ModelicaTreeNode *node, bool askQuestion)
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

    if (askQuestion)
    {
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
    }

    if (pMainWindow->mpOMCProxy->deleteClass(treeNode->mNameStructure))
    {
        // print the message before deleting node,
        // because after delete treenode is not available to print message :)
        if (askQuestion)
        {
            pMainWindow->mpMessageWidget->printGUIInfoMessage("'" + treeNode->mName + "' deleted successfully.");
        }
        deleteNode(treeNode);
        if (treeNode->childCount())
            qDeleteAll(treeNode->takeChildren());
        delete treeNode;
        return true;
    }
    else
    {
        pMainWindow->mpMessageWidget->printGUIErrorMessage(GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED)
                                                          .arg(pMainWindow->mpOMCProxy->getResult())
                                                          .append("while deleting " + treeNode->mName));
        return false;
    }
}

void ModelicaTree::saveChildModels(QString modelName, QString filePath)
{
    MainWindow *pMainWindow = mpParentLibraryWidget->mpParentMainWindow;
    ModelicaTreeNode *node = getNode(modelName);
    if (!node)
        return;

    for (int i = 0 ; i < node->childCount() ; i++)
    {
        ModelicaTreeNode *childNode = dynamic_cast<ModelicaTreeNode*>(node->child(i));
        if (childNode)
        {
            ProjectTab *pCurrentTab = pMainWindow->mpProjectTabs->getTabByName(childNode->mNameStructure);
            // if projectTab not found then look in removed tabs
            if (!pCurrentTab)
            {
                pCurrentTab = pMainWindow->mpProjectTabs->getRemovedTabByName(childNode->mNameStructure);
            }
            if (pCurrentTab)
            {
                pMainWindow->mpOMCProxy->setSourceFile(pCurrentTab->mModelNameStructure, filePath);
                pCurrentTab->setModelFilePathLabel(filePath);
                // if current node is package then save all items under it to the same file
                if (pCurrentTab->mModelicaType == StringHandler::PACKAGE)
                {
                    saveChildModels(pCurrentTab->mModelNameStructure, filePath);
                }
            }
            // if not found in removed tabs then read the model name form tree
            else
            {
                pMainWindow->mpOMCProxy->setSourceFile(childNode->mNameStructure, filePath);
                if (childNode->mType == StringHandler::PACKAGE)
                {
                    saveChildModels(childNode->mNameStructure, filePath);
                }
            }
        }
    }
}

LibraryTreeNode::LibraryTreeNode(QString text, QString parentName, QString tooltip, QTreeWidget *parent)
    : QTreeWidgetItem(parent)
{
    mName = text;
    mParentName = parentName;
    mNameStructure = tooltip;

    setText(0, mName);
    setToolTip(0, mNameStructure);
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

    connect(this, SIGNAL(itemPressed(QTreeWidgetItem*,int)), SLOT(treeItemPressed(QTreeWidgetItem*)));
    connect(this, SIGNAL(itemExpanded(QTreeWidgetItem*)), SLOT(expandLib(QTreeWidgetItem*)));
    connect(this, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
    connect(this, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), SLOT(showComponent(QTreeWidgetItem*,int)));
}

LibraryTree::~LibraryTree()
{
    // delete all the items in the tree
    for (int i = 0; i < topLevelItemCount(); ++i)
        qDeleteAll(topLevelItem(i)->takeChildren());
}

void LibraryTree::createActions()
{
    mpShowComponentAction = new QAction(QIcon(":/Resources/icons/model.png"), tr("Show Component"), this);
    connect(mpShowComponentAction, SIGNAL(triggered()), SLOT(showComponent()));

    mpViewDocumentationAction = new QAction(QIcon(":/Resources/icons/info-icon.png"), tr("View Documentation"), this);
    connect(mpViewDocumentationAction, SIGNAL(triggered()), SLOT(viewDocumentation()));

    mpCheckModelAction = new QAction(QIcon(":/Resources/icons/check.png"), tr("Check"), this);
    connect(mpCheckModelAction, SIGNAL(triggered()), SLOT(checkLibraryModel()));
}

//! Let the user add the OM Standard Library to library widget.
void LibraryTree::addModelicaStandardLibrary()
{
    // load Modelica Standard Library.
    mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy->loadStandardLibrary();
    if (mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy->isStandardLibraryLoaded())
    {
        // It should be possible to load multiple libraries in OMEdit...
        const int numLib=2;
        const char *libs[numLib] = {"Modelica", "ModelicaServices"};
        for (int i=0; i<numLib; i++) {
            LibraryTreeNode *newTreePost = new LibraryTreeNode(QString(libs[i]), QString(""), QString(libs[i]),
                                                               this);
            int classType = mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy->getClassRestriction(QString(libs[i]));
            newTreePost->mType = classType;
            newTreePost->setChildIndicatorPolicy(QTreeWidgetItem::ShowIndicator);
            insertTopLevelItem(0, newTreePost);

            // get the Icon for Modelica tree node
            LibraryLoader *libraryLoader = new LibraryLoader(newTreePost, tr(libs[i]), this);
            libraryLoader->start(QThread::HighestPriority);
            while (libraryLoader->isRunning())
                qApp->processEvents();
        }

//        addClass("Ground", "", "Modelica.Electrical.Analog.Basic.", true);
//        addClass("Resistor", "", "Modelica.Electrical.Analog.Basic.", true);
    }
}

//! Adds a whole tree structure hierarchy of OM Standard library to the library widget.
//! @param value is the name of the class.
//! @param prefixstr is the name of the parent hierarchy of the class.
void LibraryTree::loadModelicaLibraryHierarchy(QString value, QString prefixStr)
{
    QList<LibraryTreeNode*> tempPackageNodesList;
    QList<LibraryTreeNode*> tempNonPackageNodesList;

    if (mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy->isPackage(value))
    {
        QStringList list = mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy->getClassNames(value);
        prefixStr += value + ".";
        foreach (QString str, list)
        {
            addClass(&tempPackageNodesList, &tempNonPackageNodesList, str,
                     StringHandler::getSubStringFromDots(prefixStr), prefixStr, true);
        }
    }

    //! @todo
    /* if both the lists are empty then remove the + sign from tree node. Work Around for Constants Library
       at the moment. */

    if (tempPackageNodesList.isEmpty() and tempNonPackageNodesList.isEmpty())
    {
        // get the node and remove the ChildIndicatorPolicy
        QTreeWidgetItemIterator it(this);
        while (*it)
        {
            if ((*it)->toolTip(0) == value)
            {
                (*it)->setChildIndicatorPolicy(QTreeWidgetItem::DontShowIndicator);
            }
            ++it;
        }
    }
    else
    {
        addNodes(tempPackageNodesList);
        addNodes(tempNonPackageNodesList);
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
void LibraryTree::addClass(QList<LibraryTreeNode *> *tempPackageNodesList,
                           QList<LibraryTreeNode *> *tempNonPackageNodesList, QString className,
                           QString parentClassName, QString parentStructure, bool hasIcon)
{
    mpParentLibraryWidget->mpParentMainWindow->statusBar->showMessage(QString("Loading: ")
                                                                      .append(parentStructure + className));
    LibraryTreeNode *newTreePost = new LibraryTreeNode(className, parentClassName,
                                                       QString(parentStructure + className), (QTreeWidget*)0);

    // If Loaded class is package show treewidgetitem expand indicator
    // Remove if using load once library feature
    int classType = mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy->getClassRestriction(parentStructure +
                                                                                               className);
    newTreePost->mType = classType;
    if (classType == StringHandler::PACKAGE)
    {
        newTreePost->setChildIndicatorPolicy(QTreeWidgetItem::ShowIndicator);
        //hasIcon = false;
        tempPackageNodesList->append(newTreePost);
    }
    else
    {
        tempNonPackageNodesList->append(newTreePost);
    }

    if (hasIcon)
    {
        LibraryLoader *libraryLoader = new LibraryLoader(newTreePost, parentStructure + className, this);
        libraryLoader->start(QThread::HighestPriority);
        while (libraryLoader->isRunning())
            qApp->processEvents();
    }
}

void LibraryTree::addNodes(QList<LibraryTreeNode *> nodes)
{
    qSort(nodes.begin(), nodes.end(), sortNodesAscending);
    foreach (LibraryTreeNode *node, nodes)
    {
        if (node->mParentName.isEmpty())
        {
            insertTopLevelItem(0, node);
        }
        else
        {
            QTreeWidgetItemIterator it(this);
            while (*it)
            {
                if ((*it)->toolTip(0) == StringHandler::removeLastWordAfterDot(node->mNameStructure))
                {
                    (*it)->addChild(node);
                }
                ++it;
            }
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

bool LibraryTree::sortNodesAscending(const LibraryTreeNode *node1, const LibraryTreeNode *node2)
{
    return node1->mName.toLower() < node2->mName.toLower();
}

//! Makes a library expand.
//! @param item is the library to show.
void LibraryTree::expandLib(QTreeWidgetItem *item)
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
        menu.addAction(mpShowComponentAction);
        menu.addAction(mpViewDocumentationAction);
        menu.addAction(mpCheckModelAction);
        point.setY(point.y() + adjust);
        menu.exec(mapToGlobal(point));
    }
}

void LibraryTree::showComponent(QTreeWidgetItem *item, int column)
{
    Q_UNUSED(column);
    mpParentLibraryWidget->mSelectedLibraryNode = item;
    showComponent();
}

void LibraryTree::showComponent()
{
    ProjectTabWidget *pProjectTabs = mpParentLibraryWidget->mpParentMainWindow->mpProjectTabs;
    setCursor(Qt::WaitCursor);
    pProjectTabs->addDiagramViewTab(mpParentLibraryWidget->mSelectedLibraryNode, 0);
    unsetCursor();
}

void LibraryTree::viewDocumentation()
{
    MainWindow *pMainWindow = mpParentLibraryWidget->mpParentMainWindow;
    pMainWindow->documentationdock->show();
    pMainWindow->mpDocumentationWidget->show(mpParentLibraryWidget->mSelectedLibraryNode->toolTip(0));
}

void LibraryTree::checkLibraryModel()
{
    CheckModelWidget *widget = new CheckModelWidget(mpParentLibraryWidget->mSelectedLibraryNode->text(0),
                                                    mpParentLibraryWidget->mSelectedLibraryNode->toolTip(0),
                                                    mpParentLibraryWidget->mpParentMainWindow);
    widget->show();
}

void LibraryTree::loadingLibraryComponent(LibraryTreeNode *treeNode, QString className)
{
    QString result;
    result = mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy->getIconAnnotation(className);
    LibraryComponent *libComponent = new LibraryComponent(result, className,
                                                          mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy);

    QPixmap pixmap = libComponent->getComponentPixmap(Helper::iconSize);
    if (pixmap.isNull())
    {
        if (QString(className).toLower().contains("usersguide"))
            treeNode->setIcon(0, QIcon(":/Resources/icons/info-icon.png"));
        else
            treeNode->setIcon(0, ModelicaTreeNode::getModelicaNodeIcon(treeNode->mType));
    }
    else
    {
        treeNode->setIcon(0, QIcon(libComponent->getComponentPixmap(Helper::iconSize)));
    }
    mpParentLibraryWidget->addComponentObject(libComponent);
}

void LibraryTree::treeItemPressed(QTreeWidgetItem *item)
{
    if (qApp->mouseButtons() != Qt::LeftButton)
        return;

    if (!item)
        return;

//  if item is package then return
//  if (mpParentLibraryWidget->mpParentMainWindow->mpOMCProxy->isWhat(StringHandler::PACKAGE, item->toolTip(0)))
//      return;

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

MSLSearchBox::MSLSearchBox(SearchMSLWidget *pParent)
    : mDefaultText(Helper::modelicaLibrarySearchText)
{
    setText(mDefaultText);

    mpSearchMSLWidget = pParent;
    // create msl suggestion completion object
    mpMSLSuggestionCompletion = new MSLSuggestCompletion(this);
}

void MSLSearchBox::focusInEvent(QFocusEvent *event)
{
    Q_UNUSED(event);

    if (text().compare(mDefaultText) == 0)
        setText(tr(""));

    QLineEdit::focusInEvent(event);
}

void MSLSearchBox::focusOutEvent(QFocusEvent *event)
{
    Q_UNUSED(event);

    if (text().isEmpty())
    {
        setText(mDefaultText);
    }
    QLineEdit::focusOutEvent(event);
}

MSLSuggestCompletion::MSLSuggestCompletion(MSLSearchBox *pParent)
    : QObject(pParent), mpMSLSearchBox(pParent)
{
    // set up the popup tree that will show up for suggestion
    mpPopup = new QTreeWidget;
    mpPopup->setWindowFlags(Qt::Popup);
    mpPopup->setFocusPolicy(Qt::NoFocus);
    mpPopup->setFocusProxy(pParent);
    mpPopup->setMouseTracking(true);
    mpPopup->setColumnCount(1);
    mpPopup->setUniformRowHeights(true);
    mpPopup->setRootIsDecorated(false);
    mpPopup->setEditTriggers(QTreeWidget::NoEditTriggers);
    mpPopup->setSelectionBehavior(QTreeWidget::SelectRows);
    mpPopup->setFrameStyle(QFrame::Box | QFrame::Plain);
    //mpPopup->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
    mpPopup->header()->hide();
    // install the event filter
    mpPopup->installEventFilter(this);
    connect(mpPopup, SIGNAL(itemClicked(QTreeWidgetItem*,int)), SLOT(doneCompletion()));
    // set up the timer to get the suggestions
    mpTimer = new QTimer(this);
    mpTimer->setSingleShot(true);
    mpTimer->setInterval(500);
    connect(mpTimer, SIGNAL(timeout()), SLOT(getSuggestions()));
    connect(mpMSLSearchBox, SIGNAL(textEdited(QString)), mpTimer, SLOT(start()));
}

MSLSuggestCompletion::~MSLSuggestCompletion()
{
    delete mpPopup;
    delete mpTimer;
}

bool MSLSuggestCompletion::eventFilter(QObject *pObject, QEvent *event)
{
    if (pObject != mpPopup)
        return false;
    if (event->type() == QEvent::MouseButtonPress)
    {
        mpPopup->hide();
        mpMSLSearchBox->setFocus();
        return true;
    }
    if (event->type() == QEvent::KeyPress)
    {
        bool consumed = false;
        int key = static_cast<QKeyEvent*>(event)->key();
        switch (key) {
        case Qt::Key_Enter:
        case Qt::Key_Return:
            doneCompletion();
            consumed = true;
        case Qt::Key_Escape:
            mpMSLSearchBox->setFocus();
            mpPopup->hide();
            consumed = true;
        case Qt::Key_Up:
        case Qt::Key_Down:
        case Qt::Key_Home:
        case Qt::Key_End:
        case Qt::Key_PageUp:
        case Qt::Key_PageDown:
            break;
        default:
            mpMSLSearchBox->setFocus();
            mpMSLSearchBox->event(event);
            //mpPopup->hide();
            break;
        }
        return consumed;
    }
    return false;
}

//! Reads the suggestions and creates a popup tree of it for the user.
//! @see getSuggestions()
void MSLSuggestCompletion::showCompletion(const QStringList &choices)
{
    if (choices.isEmpty())
        return;

    mpPopup->setUpdatesEnabled(false);
    mpPopup->clear();
    for (int i = 0; i < choices.count(); ++i) {
        QTreeWidgetItem * item;
        item = new QTreeWidgetItem(mpPopup);
        item->setText(0, choices[i]);
    }
    // adjust the size of popup tree
    mpPopup->resizeColumnToContents(0);
    mpPopup->adjustSize();
    mpPopup->setUpdatesEnabled(true);

    // subtract -3 from width and -40 from height to make the suggestion box best fit :D
    mpPopup->resize(mpMSLSearchBox->mpSearchMSLWidget->mpParentMainWindow->searchMSLdock->width() - 3,
                    mpMSLSearchBox->mpSearchMSLWidget->mpParentMainWindow->searchMSLdock->height() - 40);

    // adjust the position of popup tree
    mpPopup->move(mpMSLSearchBox->mapToGlobal(QPoint(0, mpMSLSearchBox->height())));
    mpPopup->setFocus();
    mpPopup->show();
}

QTimer* MSLSuggestCompletion::getTimer()
{
    return mpTimer;
}

//! Puts the selected suggestion text in the MSL SearchTextBox and notifies that the suggestion is completed.
//! @see showCompletion()
//! @see getSuggestions()
void MSLSuggestCompletion::doneCompletion()
{
    mpTimer->stop();
    mpPopup->hide();
    mpMSLSearchBox->setFocus();
    QTreeWidgetItem *item = mpPopup->currentItem();
    if (item)
        mpMSLSearchBox->setText(item->text(0));
    else
        QMetaObject::invokeMethod(mpMSLSearchBox, "returnPressed");
}

//! Creates the MSL suggestion tree from the Modelica Standards Library items.
//! @see showCompletion()
void MSLSuggestCompletion::getSuggestions()
{
    if ((mpMSLSearchBox->text().compare(Helper::modelicaLibrarySearchText) == 0) or (mpMSLSearchBox->text().isEmpty()))
    {
        preventSuggestions();
        return;
    }

    QStringList foundedItemsList;
    QStringList itemsList = mpMSLSearchBox->mpSearchMSLWidget->getMSLItemsList();

    foreach (QString item, itemsList)
    {
        item = item.trimmed();
        if (item.contains(mpMSLSearchBox->text().trimmed(), Qt::CaseInsensitive))
            foundedItemsList.append(item);
    }

    showCompletion(foundedItemsList);
}

//! Stops the suggestion process.
//! @see showCompletion()
//! @see doneCompletion()
//! @see getSuggestions()
void MSLSuggestCompletion::preventSuggestions()
{
    mpTimer->stop();
}

SearchMSLWidget::SearchMSLWidget(MainWindow *pParent)
    : QWidget(pParent)
{
    mpParentMainWindow = pParent;

    // get MSL recursive
    mMSLItemsList = mpParentMainWindow->mpOMCProxy->getClassNamesRecursive(tr("Modelica"));

    // create search controls
    mpSearchTextBox = new MSLSearchBox(this);
    connect(mpSearchTextBox, SIGNAL(returnPressed()), SLOT(searchMSL()));

    mpSearchButton = new QPushButton(tr("Search"));
    connect(mpSearchButton, SIGNAL(pressed()), SLOT(searchMSL()));

    mpSearchedItemsTree = new LibraryTree(mpParentMainWindow->mpLibrary);
    mpSearchedItemsTree->setFrameShape(QFrame::StyledPanel);
    mpSearchedItemsTree->setHeaderLabel(tr("Searched Items"));

    // add the search controls to layout
    QHBoxLayout *horizontalLayout = new QHBoxLayout;
    horizontalLayout->addWidget(mpSearchTextBox);
    horizontalLayout->addWidget(mpSearchButton);

    QVBoxLayout *verticalLayout = new QVBoxLayout;
    verticalLayout->setContentsMargins(0, 0, 2, 0);
    verticalLayout->addLayout(horizontalLayout);
    verticalLayout->addWidget(mpSearchedItemsTree);

    setLayout(verticalLayout);
}

QStringList SearchMSLWidget::getMSLItemsList()
{
   return mMSLItemsList;
}

MSLSearchBox* SearchMSLWidget::getMSLSearchTextBox()
{
    return mpSearchTextBox;
}

void SearchMSLWidget::searchMSL()
{
    // stop the msl search suggestion completion time
    mpSearchTextBox->mpMSLSuggestionCompletion->getTimer()->stop();
    // Remove the items from search tree
    int i = 0;
    while(i < mpSearchedItemsTree->topLevelItemCount())
    {
        qDeleteAll(mpSearchedItemsTree->topLevelItem(i)->takeChildren());
        delete mpSearchedItemsTree->topLevelItem(i);
        i = 0;   //Restart iteration
    }

    QString foundedItemString;
    QStringList foundedItemsList;

    foreach (QString item, mMSLItemsList)
    {
        item = item.trimmed();
        // for packages...so that the search don't go inside a package....
        if (!foundedItemString.isEmpty())
        {
            if (item.startsWith(foundedItemString, Qt::CaseInsensitive))
                continue;
        }
        if (item.contains(mpSearchTextBox->text().trimmed(), Qt::CaseInsensitive))
        {
            foundedItemString = item;
            foundedItemsList.append(item);
        }
    }

    // if no item is found
    if (foundedItemsList.isEmpty())
    {
        mpSearchedItemsTree->insertTopLevelItem(0, new QTreeWidgetItem(QStringList(Helper::noItemFound)));
        return;
    }

    foreach (QString foundedItem, foundedItemsList)
    {
        LibraryTreeNode *newTreePost = new LibraryTreeNode(foundedItem, QString(""), foundedItem, mpSearchedItemsTree);
        newTreePost->mType = mpParentMainWindow->mpOMCProxy->getClassRestriction(foundedItem);
        mpSearchedItemsTree->insertTopLevelItem(0, newTreePost);

        // get the Icon for Modelica tree node
        LibraryLoader *libraryLoader = new LibraryLoader(newTreePost, foundedItem, mpSearchedItemsTree);
        libraryLoader->start(QThread::HighestPriority);
        while (libraryLoader->isRunning())
            qApp->processEvents();
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

    if (mpComponent->mRectangle.width() > 1)
        mRectangle = mpComponent->mRectangle;
    else
        mRectangle = QRectF(-100.0, -100.0, 200.0, 200.0);

    qreal adjust = 25;
    mRectangle.setX(mRectangle.x() - adjust);
    mRectangle.setY(mRectangle.y() - adjust);
    mRectangle.setWidth(mRectangle.width() + adjust);
    mRectangle.setHeight(mRectangle.height() + adjust);

    mpGraphicsView = new QGraphicsView;
    mpGraphicsView->setScene(new QGraphicsScene);
    mpGraphicsView->setSceneRect(mRectangle);
    mpGraphicsView->scene()->addItem(mpComponent);
}

LibraryComponent::~LibraryComponent()
{
    delete mpComponent;
    delete mpGraphicsView;
}

QPixmap LibraryComponent::getComponentPixmap(QSize size)
{
    if (mpComponent->mRectangle.width() < 1)
        return QPixmap();

    QPixmap pixmap(size);
    pixmap.fill(QColor(Qt::transparent));
    QPainter painter(&pixmap);
    painter.setWindow(mRectangle.toRect());
    painter.scale(1.0, -1.0);
    mpGraphicsView->scene()->render(&painter, mRectangle, mpGraphicsView->sceneRect());
    painter.end();
    return pixmap;
}

LibraryLoader::LibraryLoader(LibraryTreeNode *treeNode, QString className, LibraryTree *pParent)
{
    mTreeNode = treeNode;
    mClassName = className;
    mpParentLibraryTree = pParent;

    connect(this, SIGNAL(loadLibraryComponent(LibraryTreeNode*,QString)),
            mpParentLibraryTree, SLOT(loadingLibraryComponent(LibraryTreeNode*,QString)));
}

void LibraryLoader::run()
{
    emit loadLibraryComponent(mTreeNode, mClassName);
}
