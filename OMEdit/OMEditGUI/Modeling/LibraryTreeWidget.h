/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#ifndef LIBRARYTREEWIDGET_H
#define LIBRARYTREEWIDGET_H

#include "MainWindow.h"
#include "StringHandler.h"

class ItemDelegate : public QItemDelegate
{
  Q_OBJECT
private:
  bool mDrawRichText;
  QPoint mLastTextPos;
  bool mDrawGrid;
  QColor mGridColor;
  QObject *mpParent;
public:
  ItemDelegate(QObject *pParent = 0, bool drawRichText = false, bool drawGrid = false);
  QColor getGridColor() {return mGridColor;}
  void setGridColor(QColor color) {mGridColor = color;}
  QString formatDisplayText(QVariant variant) const;
  void initTextDocument(QTextDocument *pTextDocument, QFont font, int width) const;
  virtual void paint(QPainter *painter, const QStyleOptionViewItem &option, const QModelIndex &index) const;
  void drawHover(QPainter *painter, const QStyleOptionViewItem &option, const QModelIndex &index) const;
  virtual QSize sizeHint(const QStyleOptionViewItem &option, const QModelIndex &index) const;
  virtual bool editorEvent(QEvent *event, QAbstractItemModel *model, const QStyleOptionViewItem &option, const QModelIndex &index);
};

class ModelWidget;
class ShapeAnnotation;
class Component;
class LineAnnotation;
class LibraryTreeItem : public QObject
{
  Q_OBJECT
public:
  enum LibraryType {
    Modelica,   /* Used to represent Modelica models. */
    Text,       /* Used to represent text based files. */
    TLM         /* Used to represent TLM files. */
  };
  enum SaveContentsType {
    SaveInOneFile,
    SaveFolderStructure
  };
  LibraryTreeItem();
  LibraryTreeItem(LibraryType type, QString text, QString nameStructure, OMCInterface::getClassInformation_res classInformation,
                  QString fileName, bool isSaved, LibraryTreeItem *pParent = 0);
  ~LibraryTreeItem();
  bool isRootItem() {return mIsRootItem;}
  QList<LibraryTreeItem*> getChildren() const {return mChildren;}
  LibraryType getLibraryType() {return mLibraryType;}
  void setLibraryType(LibraryType libraryType) {mLibraryType = libraryType;}
  void setSystemLibrary(bool systemLibrary) {mSystemLibrary = systemLibrary;}
  bool isSystemLibrary() {return mSystemLibrary;}
  void setModelWidget(ModelWidget *pModelWidget) {mpModelWidget = pModelWidget;}
  ModelWidget* getModelWidget() {return mpModelWidget;}
  void setName(QString name) {mName = name;}
  const QString& getName() const {return mName;}
  void setNameStructure(QString nameStructure) {mNameStructure = nameStructure;}
  const QString& getNameStructure() {return mNameStructure;}
  void setClassInformation(OMCInterface::getClassInformation_res classInformation);
  void setFileName(QString fileName) {mFileName = fileName;}
  const QString& getFileName() {return mFileName;}
  bool isFilePathValid();
  void setReadOnly(bool readOnly) {mReadOnly = readOnly;}
  bool isReadOnly() {return mReadOnly;}
  void setIsSaved(bool isSaved) {mIsSaved = isSaved;}
  bool isSaved() {return mIsSaved;}
  void setIsProtected(bool isProtected) {mIsProtected = isProtected;}
  bool isProtected() {return mIsProtected;}
  void setIsDocumentationClass(bool documentationClass) {mDocumentationClass = documentationClass;}
  bool isDocumentationClass() {return mDocumentationClass;}
  StringHandler::ModelicaClasses getRestriction() {return StringHandler::getModelicaClassType(mClassInformation.restriction);}
  bool isConnector() {return (getRestriction() == StringHandler::ExpandableConnector || getRestriction() == StringHandler::Connector);}
  bool isPartial() {return mClassInformation.partialPrefix;}
  void setSaveContentsType(LibraryTreeItem::SaveContentsType saveContentsType) {mSaveContentsType = saveContentsType;}
  SaveContentsType getSaveContentsType() {return mSaveContentsType;}
  void setToolTip(QString toolTip) {mToolTip = toolTip;}
  void setIcon(QIcon icon) {mIcon = icon;}
  void setPixmap(QPixmap pixmap) {mPixmap = pixmap;}
  QPixmap getPixmap() {return mPixmap;}
  void setDragPixmap(QPixmap dragPixmap) {mDragPixmap = dragPixmap;}
  QPixmap getDragPixmap() {return mDragPixmap;}
  void setClassText(QString classText) {mClassText = classText;}
  QString getClassText() {return mClassText;}
  void setExpanded(bool expanded) {mExpanded = expanded;}
  bool isExpanded() const {return mExpanded;}
  void setNonExisting(bool nonExisting) {mNonExisting = nonExisting;}
  bool isNonExisting() const {return mNonExisting;}
  void updateAttributes();
  QIcon getLibraryTreeItemIcon();
  bool inRange(int lineNumber) {return (lineNumber >= mClassInformation.lineNumberStart) && (lineNumber <= mClassInformation.lineNumberEnd);}
  bool isInPackageOneFile();
  void insertChild(int position, LibraryTreeItem *pLibraryTreeItem);
  LibraryTreeItem* child(int row);
  void moveChild(int from, int to);
  void addInheritedClass(LibraryTreeItem *pLibraryTreeItem);
  void removeInheritedClasses();
  QList<LibraryTreeItem*> getInheritedClasses() const {return mInheritedClasses;}
  void removeChild(LibraryTreeItem *pLibraryTreeItem);
  QVariant data(int column, int role = Qt::DisplayRole) const;
  int row() const;
  void setParent(LibraryTreeItem *pParentLibraryTreeItem) {mpParentLibraryTreeItem = pParentLibraryTreeItem;}
  LibraryTreeItem* parent() {return mpParentLibraryTreeItem;}
  bool isTopLevel();
  bool isSimulationAllowed();
  void emitLoaded() {emit loaded(this);}
  void emitUnLoaded() {emit unLoaded(this);}
  void emitShapeAdded(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView) {emit shapeAdded(this, pShapeAnnotation, pGraphicsView);}
  void emitComponentAdded(Component *pComponent, GraphicsView *pGraphicsView) {emit componentAdded(this, pComponent, pGraphicsView);}
  void emitConnectionAdded(LineAnnotation *pConnectionLineAnnotation) {emit connectionAdded(this, pConnectionLineAnnotation);}

  OMCInterface::getClassInformation_res mClassInformation;
private:
  bool mIsRootItem;
  LibraryTreeItem *mpParentLibraryTreeItem;
  QList<LibraryTreeItem*> mChildren;
  QList<LibraryTreeItem*> mInheritedClasses;
  LibraryType mLibraryType;
  bool mSystemLibrary;
  ModelWidget *mpModelWidget;
  QString mName;
  QString mParentName;
  QString mNameStructure;
  QString mFileName;
  bool mReadOnly;
  bool mIsSaved;
  bool mIsProtected;
  bool mDocumentationClass;
  SaveContentsType mSaveContentsType;
  QString mToolTip;
  QIcon mIcon;
  QPixmap mPixmap;
  QPixmap mDragPixmap;
  QString mClassText;
  bool mExpanded;
  bool mNonExisting;
signals:
  void loaded(LibraryTreeItem *pLibraryTreeItem);
  void unLoaded(LibraryTreeItem *pLibraryTreeItem);
  void shapeAdded(LibraryTreeItem *pLibraryTreeItem, ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView);
  void componentAdded(LibraryTreeItem *pLibraryTreeItem, Component *pComponent, GraphicsView *pGraphicsView);
  void connectionAdded(LibraryTreeItem *pLibraryTreeItem, LineAnnotation *pConnectionLineAnnotation);
  void iconUpdated();
public slots:
  void handleLoaded(LibraryTreeItem *pLibraryTreeItem);
  void handleUnloaded(LibraryTreeItem *pLibraryTreeItem);
  void handleShapeAdded(LibraryTreeItem *pLibraryTreeItem, ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView);
  void handleComponentAdded(LibraryTreeItem *pLibraryTreeItem, Component *pComponent, GraphicsView *pGraphicsView);
  void handleConnectionAdded(LibraryTreeItem *pLibraryTreeItem, LineAnnotation *pConnectionLineAnnotation);
  void handleIconUpdated();
};

class LibraryWidget;
class LibraryTreeProxyModel : public QSortFilterProxyModel
{
  Q_OBJECT
public:
  LibraryTreeProxyModel(LibraryWidget *pLibraryWidget);
private:
  LibraryWidget *mpLibraryWidget;
protected:
  virtual bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;
};

class LibraryTreeModel : public QAbstractItemModel
{
  Q_OBJECT
public:
  LibraryTreeModel(LibraryWidget *pLibraryWidget);
  LibraryTreeItem* getRootLibraryTreeItem() {return mpRootLibraryTreeItem;}
  int columnCount(const QModelIndex &parent = QModelIndex()) const;
  int rowCount(const QModelIndex &parent = QModelIndex()) const;
  QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const;
  QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const;
  QModelIndex parent(const QModelIndex & index) const;
  QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;
  Qt::ItemFlags flags(const QModelIndex &index) const;
  LibraryTreeItem* findLibraryTreeItem(const QString &name, LibraryTreeItem *root = 0, Qt::CaseSensitivity caseSensitivity = Qt::CaseSensitive) const;
  LibraryTreeItem* findLibraryTreeItem(const QRegExp &regExp, LibraryTreeItem *root = 0) const;
  LibraryTreeItem* findNonExistingLibraryTreeItem(const QString &name, Qt::CaseSensitivity caseSensitivity = Qt::CaseSensitive) const;
  QModelIndex libraryTreeItemIndex(const LibraryTreeItem *pLibraryTreeItem) const;
  void addModelicaLibraries(QSplashScreen *pSplashScreen);
  void createLibraryTreeItems(LibraryTreeItem *pLibraryTreeItem);
  LibraryTreeItem* createLibraryTreeItem(QString name, LibraryTreeItem *pParentLibraryTreeItem, bool &wasNonExisting, bool isSaved = true,
                                         bool isSystemLibrary = false, bool load = false);
  LibraryTreeItem* createLibraryTreeItem(LibraryTreeItem::LibraryType type, QString name, bool isSaved);
  LibraryTreeItem* createNonExistingLibraryTreeItem(QString nameStructure);
  void createNonExistingLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem, LibraryTreeItem *pParentLibraryTreeItem, bool isSaved = true);
  void loadNonExistingLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void addNonExistingLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem) {mNonExistingLibraryTreeItemsList.append(pLibraryTreeItem);}
  void removeNonExistingLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem) {mNonExistingLibraryTreeItemsList.removeOne(pLibraryTreeItem);}
  void updateLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void readLibraryTreeItemClassText(LibraryTreeItem *pLibraryTreeItem);
  QString readLibraryTreeItemClassTextFromText(LibraryTreeItem *pLibraryTreeItem, QString contents);
  QString readLibraryTreeItemClassTextFromFile(LibraryTreeItem *pLibraryTreeItem);
  void updateLibraryTreeItemClassText(LibraryTreeItem *pLibraryTreeItem);
  void updateChildLibraryTreeItemClassText(LibraryTreeItem *pLibraryTreeItem, QString contents, QString fileName);
  LibraryTreeItem* getContainingFileParentLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void loadLibraryTreeItemPixmap(LibraryTreeItem *pLibraryTreeItem);
  void loadDependentLibraries(QStringList libraries);
  LibraryTreeItem* getLibraryTreeItemFromFile(QString fileName, int lineNumber);
  void showModelWidget(LibraryTreeItem *pLibraryTreeItem, QString text = QString(""), bool show = true);
  void showHideProtectedClasses();
  bool unloadClass(LibraryTreeItem *pLibraryTreeItem, bool askQuestion = true);
  bool unloadTLMOrTextFile(LibraryTreeItem *pLibraryTreeItem, bool askQuestion = true);
  void moveClassUpDown(LibraryTreeItem *pLibraryTreeItem, bool up);
  void moveClassTopBottom(LibraryTreeItem *pLibraryTreeItem, bool top);
  QString getUniqueTopLevelItemName(QString name, int number = 1);
  void emitDataChanged(const QModelIndex &topLeft, const QModelIndex &bottomRight) {emit dataChanged(topLeft, bottomRight);}
private:
  LibraryWidget *mpLibraryWidget;
  LibraryTreeItem *mpRootLibraryTreeItem;
  QList<LibraryTreeItem*> mNonExistingLibraryTreeItemsList;
  QModelIndex libraryTreeItemIndexHelper(const LibraryTreeItem *pLibraryTreeItem, const LibraryTreeItem *pParentLibraryTreeItem,
                                         const QModelIndex &parentIndex) const;
  LibraryTreeItem* getLibraryTreeItemFromFileHelper(LibraryTreeItem *pLibraryTreeItem, QString fileName, int lineNumber);
  void unloadClassHelper(LibraryTreeItem *pLibraryTreeItem, LibraryTreeItem *pParentLibraryTreeItem);
  void unloadClassChildren(LibraryTreeItem *pLibraryTreeItem);
protected:
  Qt::DropActions supportedDropActions() const;
};

class LibraryTreeView : public QTreeView
{
  Q_OBJECT
public:
  LibraryTreeView(LibraryWidget *pLibraryWidget);
  LibraryWidget* getLibraryWidget() {return mpLibraryWidget;}
private:
  LibraryWidget *mpLibraryWidget;
  QAction *mpViewClassAction;
  QAction *mpViewDocumentationAction;
  QAction *mpNewModelicaClassAction;
  QAction *mpSaveAction;
  QAction *mpSaveAsAction;
  QAction *mpSaveTotalAction;
  QAction *mpMoveUpAction;
  QAction *mpMoveDownAction;
  QAction *mpMoveTopAction;
  QAction *mpMoveBottomAction;
  QMenu *mpOrderMenu;
  QAction *mpInstantiateModelAction;
  QAction *mpCheckModelAction;
  QAction *mpCheckAllModelsAction;
  QAction *mpSimulateAction;
  QAction *mpSimulateWithTransformationalDebuggerAction;
  QAction *mpSimulateWithAlgorithmicDebuggerAction;
  QAction *mpSimulationSetupAction;
  QAction *mpDuplicateClassAction;
  QAction *mpUnloadClassAction;
  QAction *mpUnloadTLMFileAction;
  QAction *mpRefreshAction;
  QAction *mpExportFMUAction;
  QAction *mpExportXMLAction;
  QAction *mpExportFigaroAction;
  QAction *mpFetchInterfaceDataAction;
  QAction *mpTLMCoSimulationAction;
  void createActions();
  LibraryTreeItem* getSelectedLibraryTreeItem();
  void libraryTreeItemExpanded(LibraryTreeItem* pLibraryTreeItem);
public slots:
  void libraryTreeItemExpanded(QModelIndex index);
  void showContextMenu(QPoint point);
  void viewClass();
  void viewDocumentation();
  void createNewModelicaClass();
  void saveClass();
  void saveAsClass();
  void saveTotalClass();
  void moveClassUp();
  void moveClassDown();
  void moveClassTop();
  void moveClassBottom();
  void instantiateModel();
  void checkModel();
  void checkAllModels();
  void simulate();
  void simulateWithTransformationalDebugger();
  void simulateWithAlgorithmicDebugger();
  void simulationSetup();
  void duplicateClass();
  void unloadClass();
  void unloadTLMOrTextFile();
  void exportModelFMU();
  void exportModelXML();
  void exportModelFigaro();
  void fetchInterfaceData();
  void TLMSimulate();
protected:
  virtual void mouseDoubleClickEvent(QMouseEvent *event);
  virtual void startDrag(Qt::DropActions supportedActions);
};

class MainWindow;
class LibraryWidget : public QWidget
{
  Q_OBJECT
public:
  LibraryWidget(MainWindow *pMainWindow);
  MainWindow* getMainWindow() {return mpMainWindow;}
  LibraryTreeModel* getLibraryTreeModel() {return mpLibraryTreeModel;}
  LibraryTreeProxyModel* getLibraryTreeProxyModel() {return mpLibraryTreeProxyModel;}
  LibraryTreeView* getLibraryTreeView() {return mpLibraryTreeView;}
  void openFile(QString fileName, QString encoding = Helper::utf8, bool showProgress = true, bool checkFileExists = false);
  void openModelicaFile(QString fileName, QString encoding = Helper::utf8, bool showProgress = true);
  void openTLMOrTextFile(QFileInfo fileInfo, bool showProgress = true);
  void parseAndLoadModelicaText(QString modelText);
  bool saveLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void saveAsLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  bool saveTotalLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void openLibraryTreeItem(QString nameStructure);
private:
  MainWindow *mpMainWindow;
  TreeSearchFilters *mpTreeSearchFilters;
  LibraryTreeModel *mpLibraryTreeModel;
  LibraryTreeProxyModel *mpLibraryTreeProxyModel;
  LibraryTreeView *mpLibraryTreeView;
  bool saveFile(QString fileName, QString contents);
  bool saveModelicaLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  bool saveModelicaLibraryTreeItemHelper(LibraryTreeItem *pLibraryTreeItem);
  bool saveModelicaLibraryTreeItemOneFile(LibraryTreeItem *pLibraryTreeItem);
  void saveChildLibraryTreeItemsOneFile(LibraryTreeItem *pLibraryTreeItem);
  bool saveModelicaLibraryTreeItemFolder(LibraryTreeItem *pLibraryTreeItem);
  bool saveTextLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  bool saveTLMLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  bool saveTotalLibraryTreeItemHelper(LibraryTreeItem *pLibraryTreeItem);
public slots:
  void searchClasses();
};

#endif // LIBRARYTREEWIDGET_H
