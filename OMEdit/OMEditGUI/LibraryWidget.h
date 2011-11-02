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

#ifndef LIBRARYWIDGET_H
#define LIBRARYWIDGET_H

#include <string>
#include <map>
#include <QListWidget>
#include <QStringList>
#include <QTreeWidget>
#include <QVBoxLayout>
#include <QListWidgetItem>
#include <QStringList>

#include "mainwindow.h"
#include "StringHandler.h"

class MainWindow;
class Component;
class OMCProxy;
class LibraryWidget;
class ModelBrowserWidget;
class ModelicaTree;
class LibraryComponent;
class ModelBrowserTree;
class ModelicaTreeNode : public QTreeWidgetItem
{
public:
    ModelicaTreeNode(QString text, QString parentName,QString namestruc, QString tooltip, int type, QTreeWidget *parent = 0);
    static QIcon getModelicaNodeIcon(int type);

    int mType;
    QString mName;
    QString mParentName;
    QString mNameStructure;
};

class ModelicaTree : public QTreeWidget
{
    Q_OBJECT
public:
    ModelicaTree(LibraryWidget *parent);
    ~ModelicaTree();
    void createActions();
    ModelicaTreeNode* getNode(QString name);
    QList<ModelicaTreeNode*> getModelicaTreeNodes();
    void deleteNode(ModelicaTreeNode *item);
    void removeChildNodes(ModelicaTreeNode *item);

    LibraryWidget *mpParentLibraryWidget;
private:
    QList<ModelicaTreeNode*> mModelicaTreeNodesList;
    QAction *mpRenameAction;
    QAction *mpDeleteAction;
    QAction *mpCheckModelAction;
    QAction *mpFlatModelAction;
    QAction *mpCopyModelAction;
    QAction *mpPasteModelAction;
signals:
    void nodeDeleted();
    void changeTab();
public slots:
    void addNode(QString name, int type, QString parentName=QString(), QString parentStructure=QString());
    void openProjectTab(QTreeWidgetItem *item, int column);
    void showContextMenu(QPoint point);
    void renameClass();
    void checkModelicaModel();
    void flatModel();
    bool deleteNodeTriggered(ModelicaTreeNode *node = 0, bool askQuestion = true);
    void copyModel(ModelicaTreeNode *node = 0);
    void pasteModel();
    void saveChildModels(QString modelName, QString filePath);
    void loadingLibraryComponent(ModelicaTreeNode *treeNode, QString className);
    void tabChanged();
protected:
    virtual void mouseDoubleClickEvent(QMouseEvent *event);
    virtual void startDrag(Qt::DropActions supportedActions);
    Qt::DropActions supportedDropActions() const;
};

class LibraryTreeNode : public QTreeWidgetItem
{
public:
    LibraryTreeNode(QString text, QString parentName,QString namestruc , QString tooltip, QTreeWidget *parent = 0);

    int mType;
    QString mName;
    QString mParentName;
    QString mNameStructure;
};

class LibraryTree : public QTreeWidget
{
    Q_OBJECT
private:
    QList<QString> mTreeList;

    QAction *mpShowComponentAction;
    QAction *mpViewDocumentationAction;
    QAction *mpCheckModelAction;
    QAction *mpFlatModelAction;
public:
    LibraryTree(LibraryWidget *pParent);
    ~LibraryTree();
    void createActions();
    void addModelicaStandardLibrary();
    void loadModelicaLibraryHierarchy(QString value, QString prefixStr=QString());
    void addClass(QList<LibraryTreeNode*> *tempPackageNodesList, QList<LibraryTreeNode*> *tempNonPackageNodesList,
                  QString className, QString parentClassName=QString(), QString parentStructure=QString(),
                  bool hasIcon=false);
    void addNodes(QList<LibraryTreeNode*> nodes);
    bool isTreeItemLoaded(QTreeWidgetItem *item);
    static bool sortNodesAscending(const LibraryTreeNode *node1, const LibraryTreeNode *node2);

    LibraryWidget *mpParentLibraryWidget;
private slots:
    void expandLib(QTreeWidgetItem *item);
    void collapseLib(QTreeWidgetItem *item);
    void showContextMenu(QPoint point);
    void showComponent(QTreeWidgetItem *item, int column);
    void showComponent();
    void viewDocumentation();
    void flatModel();
    void checkLibraryModel();
signals:
    void changeTab();
public slots:
    void loadingLibraryComponent(LibraryTreeNode *treeNode, QString className);
    void tabChanged();
protected:
    virtual void mouseDoubleClickEvent(QMouseEvent *event);
    virtual void startDrag(Qt::DropActions supportedActions);
    Qt::DropActions supportedDropActions() const;
};

class ItemDelegate : public QItemDelegate
{
    Q_OBJECT
private:
    QObject *mpParent;
    QStyle::State mStyleState;
public:
    ItemDelegate(QObject *pParent = 0);
    virtual void paint(QPainter *painter, const QStyleOptionViewItem &option, const QModelIndex &index) const;
    virtual QSize sizeHint(const QStyleOptionViewItem &option, const QModelIndex &index) const;
};

class MSLSuggestCompletion;
class SearchMSLWidget;

class MSLSearchBox : public QLineEdit
{
public:
    MSLSearchBox(SearchMSLWidget *pParent);

    SearchMSLWidget *mpSearchMSLWidget;
    MSLSuggestCompletion *mpMSLSuggestionCompletion;
    QString mDefaultText;
protected:
    virtual void focusInEvent(QFocusEvent *event);
    virtual void focusOutEvent(QFocusEvent *event);
};

class MSLSuggestCompletion : QObject
{
    Q_OBJECT
public:
    MSLSuggestCompletion(MSLSearchBox *pParent);
    ~MSLSuggestCompletion();
    bool eventFilter(QObject *pObject, QEvent *event);
    void showCompletion(const QStringList &choices);
    QTimer* getTimer();
public slots:
    void doneCompletion();
    void preventSuggestions();
    void getSuggestions();
private:
    MSLSearchBox *mpMSLSearchBox;
    QTreeWidget *mpPopup;
    QTimer *mpTimer;
};

class SearchMSLWidget : public QWidget
{
    Q_OBJECT
public:
    SearchMSLWidget(MainWindow *pParent);
    QStringList getMSLItemsList();

    MSLSearchBox* getMSLSearchTextBox();
    MainWindow *mpParentMainWindow;
private:
    MSLSearchBox *mpSearchTextBox;
    QPushButton *mpSearchButton;
    LibraryTree *mpSearchedItemsTree;
    QStringList mMSLItemsList;

public slots:
    void searchMSL();
};

class LibraryWidget : public QWidget
{
    Q_OBJECT
public:
    LibraryTree *mpLibraryTree;
    ModelicaTree *mpModelicaTree;
    QTabWidget *mpLibraryTabs;
    //Member functions
    LibraryWidget(MainWindow *parent);
    ~LibraryWidget();
    void addModelicaNode(QString name, int type, QString parentName=QString(), QString parentStructure=QString());
    void addModelFiles(QString fileName, QString parentFileName=QString(), QString parentStructure=QString());
    void loadFile(QString path, QStringList modelsList);
    void loadModel(QString modelText, QStringList modelsList);
    void addComponentObject(LibraryComponent *libraryComponent);
    void addModelicaComponentObject(LibraryComponent *libraryComponent);
    Component* getComponentObject(QString className);
    Component* getModelicaComponentObject(QString className);
    LibraryComponent* getLibraryComponentObject(QString className);
    LibraryComponent* getModelicaLibraryComponentObject(QString className);
    void updateNodeText(QString text, QString textStructure, ModelicaTreeNode *node = 0);

    MainWindow *mpParentMainWindow;
    ModelicaTreeNode *mSelectedModelicaNode;
    QTreeWidgetItem *mSelectedLibraryNode;
signals:
    void addModelicaTreeNode(QString name, int type, QString parentName=QString(), QString parentStructure=QString());
private:
    //Member variables
    QVBoxLayout *mpGrid;
    QList<LibraryComponent*> mComponentsList;
    //component list of custom modelica models
    QList<LibraryComponent*> mModelicaComponentsList;
};

class LibraryComponent
{
public:
    LibraryComponent(QString value, QString className, OMCProxy *omc);
    ~LibraryComponent();
    void generateSvg(QPainter *painter, Component *pComponent);
    QPixmap getComponentPixmap(QSize size);

    QString mClassName;
    Component *mpComponent;
    QGraphicsView *mpGraphicsView;
    QRectF mRectangle;
};

class LibraryLoader : public QThread
{
    Q_OBJECT
public:
    LibraryLoader(LibraryTreeNode *treeNode, QString className, LibraryTree *pParent);
    LibraryLoader(ModelicaTreeNode *treeNode, QString className, ModelicaTree *pParent);

    LibraryTree *mpLibraryTree;
    LibraryTreeNode *mpLibraryTreeNode;
    ModelicaTree *mpModelicaTree;
    ModelicaTreeNode *mpModelicaTreeNode;
    QString mClassName;
    bool mIsLibraryNode;
protected:
    void run();
signals:
    void loadLibraryComponent(LibraryTreeNode *treeNode, QString className);
    void loadLibraryComponent(ModelicaTreeNode *treeNode, QString className);
};

class ModelBrowserTreeNode : public QTreeWidgetItem
{
public:
    ModelBrowserTreeNode(QString text, QString parentName, QString classname, QString namestruc, QString tooltip, int type,
                         QTreeWidget *parent = 0);
    QString mClassName;
    int mType;
    QString mName;
    QString mParentName;
    QString mNameStructure;
};

class ModelBrowserTree : public QTreeWidget
{
    Q_OBJECT
public:
    ModelBrowserTree(ModelBrowserWidget *parent);
    ~ModelBrowserTree();
    //void createActions();
    ModelBrowserTreeNode* getBrowserNode(QString name);
    void addBrowserNode(QString name, int type, QString className, QString parentName=QString(), QString parentStructure=QString());
    void deleteBrowserNode(ModelBrowserTreeNode *item);
    void addBrowserChild(QString name,QString className,QString parentStructure=QString(), ModelBrowserTreeNode *pItem = 0);
    ModelBrowserWidget *mpParentModelBrowserWidget;
private:
    QList<ModelBrowserTreeNode*> mModelBrowserTreeNodeList;
private slots:
    void expandTree(QTreeWidgetItem *item);
    void collapseTree(QTreeWidgetItem *item);
public slots:
    void editModelBrowser();
};

class ModelBrowserWidget : public QWidget
{
    Q_OBJECT
public:
    ModelBrowserTree *mpModelBrowserTree;
    //Member functions
    ModelBrowserWidget(MainWindow *parent);
    ~ModelBrowserWidget();
    void addModelBrowserNode();
    MainWindow *mpParentMainWindow;
    QTreeWidgetItem *mSelectedModelBrowserNode;
signals:
    void addModelBrowserTreeNode();
private:
    //Member variables
    QVBoxLayout *mpGrid;
};

#endif // LIBRARYWIDGET_H
