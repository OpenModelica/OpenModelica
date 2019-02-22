/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef LIBRARYTREEWIDGET_H
#define LIBRARYTREEWIDGET_H

#include "OMC/OMCProxy.h"
#include "Util/StringHandler.h"
#include "Simulation/SimulationOptions.h"
#include "OMS/OMSProxy.h"
#include "OMS/OMSSimulationOptions.h"

#include <QTreeView>
#include <QSortFilterProxyModel>

class CompleterItem;
class GraphicsView;
class ModelWidget;
class ShapeAnnotation;
class Component;
class LineAnnotation;
class LibraryTreeModel;
class LibraryTreeItem : public QObject
{
  Q_OBJECT
public:
  enum LibraryType {
    Modelica,         /* Used to represent Modelica models. */
    Text,             /* Used to represent text based files. */
    CompositeModel,   /* Used to represent CompositeModel files. */
    OMS               /* Used to represent OMSimulator models. */
  };
  enum Access {
    hide,
    icon,
    documentation,
    diagram,
    nonPackageText,
    nonPackageDuplicate,
    packageText,
    packageDuplicate,
    all,   /* OMEdit specific when there is no Access annotation. Everything is allowed. */
  };
  enum SaveContentsType {
    SaveInOneFile,
    SaveFolderStructure
  };
  LibraryTreeItem();
  LibraryTreeItem(LibraryType type, QString text, QString nameStructure, OMCInterface::getClassInformation_res classInformation,
                  QString fileName, bool isSaved, LibraryTreeItem *pParent = 0);
  ~LibraryTreeItem();
  bool isRootItem() const {return mIsRootItem;}
  int childrenSize() const {return mChildren.size();}
  LibraryTreeItem* childAt(int index) const {return mChildren.at(index);}
  QList<LibraryTreeItem*> childrenItems() {return mChildren;}
  LibraryType getLibraryType() {return mLibraryType;}
  void setLibraryType(LibraryType libraryType) {mLibraryType = libraryType;}
  void setSystemLibrary(bool systemLibrary) {mSystemLibrary = systemLibrary;}
  bool isSystemLibrary() {return mSystemLibrary;}
  void setModelWidget(ModelWidget *pModelWidget);
  ModelWidget* getModelWidget() {return mpModelWidget;}
  void setName(QString name) {mName = name;}
  const QString& getName() const {return mName;}
  void setNameStructure(QString nameStructure) {mNameStructure = nameStructure;}
  const QString& getNameStructure() {return mNameStructure;}
  QString getWhereToMoveFMU();
  void setClassInformation(OMCInterface::getClassInformation_res classInformation);
  void setFileName(QString fileName) {mFileName = fileName;}
  const QString& getFileName() const {return mFileName;}
  bool isFilePathValid();
  void setReadOnly(bool readOnly) {mReadOnly = readOnly;}
  bool isReadOnly() {return mReadOnly;}
  void setIsSaved(bool isSaved) {mIsSaved = isSaved;}
  bool isSaved() {return mIsSaved;}
  bool isProtected() {return mLibraryType == LibraryTreeItem::Modelica ? mClassInformation.isProtectedClass : false;}
  bool isDocumentationClass();
  StringHandler::ModelicaClasses getRestriction() const {return StringHandler::getModelicaClassType(mClassInformation.restriction);}
  bool isConnector() {return (getRestriction() == StringHandler::ExpandableConnector || getRestriction() == StringHandler::Connector);}
  bool isPartial() {return mClassInformation.partialPrefix;}
  bool isState() {return mClassInformation.state;}
  Access getAccess();
  void setSaveContentsType(LibraryTreeItem::SaveContentsType saveContentsType) {mSaveContentsType = saveContentsType;}
  SaveContentsType getSaveContentsType() {return mSaveContentsType;}
  void setPixmap(QPixmap pixmap) {mPixmap = pixmap;}
  QPixmap getPixmap() {return mPixmap;}
  void setDragPixmap(QPixmap dragPixmap) {mDragPixmap = dragPixmap;}
  QPixmap getDragPixmap() {return mDragPixmap;}
  void setClassTextBefore(QString classTextBefore) {mClassTextBefore = classTextBefore;}
  QString getClassTextBefore() {return mClassTextBefore;}
  void setClassText(QString classText);
  QString getClassText(LibraryTreeModel *pLibraryTreeModel);
  void setClassTextAfter(QString classTextAfter) {mClassTextAfter = classTextAfter;}
  QString getClassTextAfter() {return mClassTextAfter;}
  void setExpanded(bool expanded) {mExpanded = expanded;}
  bool isExpanded() const {return mExpanded;}
  void setNonExisting(bool nonExisting) {mNonExisting = nonExisting;}
  bool isNonExisting() const {return mNonExisting;}
  bool isAccessAnnotationsEnabled() const {return mAccessAnnotations;}
  void setAccessAnnotations(bool accessAnnotations) {mAccessAnnotations = accessAnnotations;}
  void setOMSElement(oms_element_t *pOMSComponent) {mpOMSElement = pOMSComponent;}
  oms_element_t* getOMSElement() const {return mpOMSElement;}
  bool isSystemElement() const {return (mpOMSElement && (mpOMSElement->type == oms_element_system));}
  bool isComponentElement() const {return (mpOMSElement && (mpOMSElement->type == oms_element_component));}
  bool isFMUComponent() const {return (mpOMSElement && (mpOMSElement->type == oms_element_component) && (mComponentType == oms_component_fmu));}
  bool isTableComponent() const {return (mpOMSElement && (mpOMSElement->type == oms_element_component) && (mComponentType == oms_component_table));}
  void setSystemType(oms_system_enu_t type) {mSystemType = type;}
  oms_system_enu_t getSystemType() {return mSystemType;}
  bool isTLMSystem() const {return mSystemType == oms_system_tlm;}
  bool isWCSystem() const {return mSystemType == oms_system_wc;}
  bool isSCSystem() const {return mSystemType == oms_system_sc;}
  void setComponentType(oms_component_enu_t type) {mComponentType = type;}
  oms_component_enu_t getComponentType() {return mComponentType;}
  ssd_element_geometry_t getOMSElementGeometry();
  void setOMSConnector(oms_connector_t *pOMSConnector) {mpOMSConnector = pOMSConnector;}
  oms_connector_t* getOMSConnector() const {return mpOMSConnector;}
  void setOMSBusConnector(oms_busconnector_t *pOMSBusConnector) {mpOMSBusConnector = pOMSBusConnector;}
  oms_busconnector_t* getOMSBusConnector() const {return mpOMSBusConnector;}
  void setOMSTLMBusConnector(oms_tlmbusconnector_t *pOMSTLMBusConnector) {mpOMSTLMBusConnector = pOMSTLMBusConnector;}
  oms_tlmbusconnector_t* getOMSTLMBusConnector() const {return mpOMSTLMBusConnector;}
  void setFMUInfo(const oms_fmu_info_t *pFMUInfo) {mpFMUInfo = pFMUInfo;}
  const oms_fmu_info_t* getFMUInfo() const {return mpFMUInfo;}
  void setSubModelPath(QString subModelPath) {mSubModelPath = subModelPath;}
  QString getSubModelPath() const {return mSubModelPath;}
  oms_modelState_enu_t getModelState() const {return mModelState;}
  void setModelState(const oms_modelState_enu_t &modelState) {mModelState = modelState;}
  QString getTooltip() const;
  QIcon getLibraryTreeItemIcon() const;
  bool inRange(int lineNumber);
  bool isInPackageOneFile();
  int getNestedLevelInPackage() const;
  void insertChild(int position, LibraryTreeItem *pLibraryTreeItem);
  LibraryTreeItem* child(int row);
  void moveChild(int from, int to);
  void addInheritedClass(LibraryTreeItem *pLibraryTreeItem);
  void removeInheritedClasses();
  QList<LibraryTreeItem*> getInheritedClasses() const {return mInheritedClasses;}
  QList<LibraryTreeItem*> getInheritedClassesDeepList();
  LibraryTreeItem *getDirectComponentsClass(const QString &name);
  LibraryTreeItem *getComponentsClass(const QString &name);
  void tryToComplete(QList<CompleterItem> &completionClasses, QList<CompleterItem> &completionComponents, const QString &lastPart);
  void removeChild(LibraryTreeItem *pLibraryTreeItem);
  QVariant data(int column, int role = Qt::DisplayRole) const;
  int row() const;
  void setParent(LibraryTreeItem *pParentLibraryTreeItem) {mpParentLibraryTreeItem = pParentLibraryTreeItem;}
  LibraryTreeItem* parent() const {return mpParentLibraryTreeItem;}
  bool isTopLevel() const;
  bool isSimulationAllowed();
  void emitLoaded();
  void emitUnLoaded();
  void emitShapeAdded(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView);
  void emitComponentAdded(Component *pComponent);
  void emitComponentAddedForComponent() {emit componentAddedForComponent();}
  void emitNameChanged() {emit nameChanged();}
  void updateChildrenNameStructure();
  void emitConnectionAdded(LineAnnotation *pConnectionLineAnnotation) {emit connectionAdded(pConnectionLineAnnotation);}
  void emitCoOrdinateSystemUpdated(GraphicsView *pGraphicsView) {emit coOrdinateSystemUpdated(pGraphicsView);}
  bool isInstantiated();
  QString getHTMLDescription() const;

  OMCInterface::getClassInformation_res mClassInformation;
  SimulationOptions mSimulationOptions;
  OMSSimulationOptions mOMSSimulationOptions;
private:
  bool mIsRootItem;
  LibraryTreeItem *mpParentLibraryTreeItem;
  QList<LibraryTreeItem*> mChildren;
  QList<LibraryTreeItem*> mInheritedClasses;
  QList<ComponentInfo*> mComponents;
  bool mComponentsLoaded;
  const QList<ComponentInfo *> &getComponentsList();
  LibraryType mLibraryType;
  bool mSystemLibrary;
  ModelWidget *mpModelWidget;
  QString mName;
  QString mParentName;
  QString mNameStructure;
  QString mFileName;
  bool mReadOnly;
  bool mIsSaved;
  SaveContentsType mSaveContentsType;
  QPixmap mPixmap;
  QPixmap mDragPixmap;
  QString mClassTextBefore;
  QString mClassText;
  QString mClassTextAfter;
  bool mExpanded;
  bool mNonExisting;
  bool mAccessAnnotations;
  oms_element_t *mpOMSElement;
  oms_system_enu_t mSystemType;
  oms_component_enu_t mComponentType;
  oms_connector_t *mpOMSConnector;
  oms_busconnector_t *mpOMSBusConnector;
  oms_tlmbusconnector_t *mpOMSTLMBusConnector;
  const oms_fmu_info_t *mpFMUInfo;
  QString mSubModelPath;
  oms_modelState_enu_t mModelState;
signals:
  void loaded(LibraryTreeItem *pLibraryTreeItem);
  void loadedForComponent();
  void unLoaded();
  void unLoadedForComponent();
  void shapeAdded(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView);
  void shapeAddedForComponent();
  void componentAdded(Component *pComponent);
  void componentAddedForComponent();
  void nameChanged();
  void connectionAdded(LineAnnotation *pConnectionLineAnnotation);
  void iconUpdated();
  void coOrdinateSystemUpdated(GraphicsView *pGraphicsView);
public slots:
  void handleLoaded(LibraryTreeItem *pLibraryTreeItem);
  void handleUnloaded();
  void handleShapeAdded(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView);
  void handleComponentAdded(Component *pComponent);
  void handleConnectionAdded(LineAnnotation *pConnectionLineAnnotation);
  void handleIconUpdated();
  void handleCoOrdinateSystemUpdated(GraphicsView *pGraphicsView);
};

class LibraryWidget;
class LibraryTreeProxyModel : public QSortFilterProxyModel
{
  Q_OBJECT
public:
  LibraryTreeProxyModel(LibraryWidget *pLibraryWidget, bool showOnlyModelica);
private:
  LibraryWidget *mpLibraryWidget;
  bool mShowOnlyModelica;
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
  LibraryTreeItem* findLibraryTreeItem(const QString &name, LibraryTreeItem *pLibraryTreeItem = 0,
                                       Qt::CaseSensitivity caseSensitivity = Qt::CaseSensitive) const;
  LibraryTreeItem* findLibraryTreeItem(const QRegExp &regExp, LibraryTreeItem *pLibraryTreeItem = 0) const;
  LibraryTreeItem* findLibraryTreeItemOneLevel(const QString &name, LibraryTreeItem *pLibraryTreeItem = 0,
                                               Qt::CaseSensitivity caseSensitivity = Qt::CaseSensitive) const;
  LibraryTreeItem* findNonExistingLibraryTreeItem(const QString &name, Qt::CaseSensitivity caseSensitivity = Qt::CaseSensitive) const;
  QModelIndex libraryTreeItemIndex(const LibraryTreeItem *pLibraryTreeItem) const;
  void addModelicaLibraries();
  LibraryTreeItem* createLibraryTreeItem(QString name, LibraryTreeItem *pParentLibraryTreeItem, bool isSaved = true,
                                         bool isSystemLibrary = false, bool load = false, int row = -1, bool activateAccessAnnotations = false);
  LibraryTreeItem* createNonExistingLibraryTreeItem(QString nameStructure);
  void createLibraryTreeItems(QFileInfo fileInfo, LibraryTreeItem *pParentLibraryTreeItem);
  LibraryTreeItem* createLibraryTreeItem(LibraryTreeItem::LibraryType type, QString name, QString nameStructure, QString path, bool isSaved,
                                         LibraryTreeItem *pParentLibraryTreeItem, int row = -1);
  LibraryTreeItem* createLibraryTreeItem(QString name, QString nameStructure, QString path, bool isSaved,
                                         LibraryTreeItem *pParentLibraryTreeItem, oms_element_t *pOMSElement = 0,
                                         oms_connector_t *pOMSConnector = 0, oms_busconnector_t *pOMSBusConnector = 0,
                                         oms_tlmbusconnector_t *pOMSTLMBusConnector = 0, int row = -1);
  void checkIfAnyNonExistingClassLoaded();
  void addNonExistingLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem) {mNonExistingLibraryTreeItemsList.append(pLibraryTreeItem);}
  void removeNonExistingLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem) {mNonExistingLibraryTreeItemsList.removeOne(pLibraryTreeItem);}
  void updateLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void updateLibraryTreeItemClassText(LibraryTreeItem *pLibraryTreeItem);
  void updateLibraryTreeItemClassTextManually(LibraryTreeItem *pLibraryTreeItem, QString contents);
  void updateChildLibraryTreeItemClassText(LibraryTreeItem *pLibraryTreeItem, QString contents, QString fileName);
  void readLibraryTreeItemClassText(LibraryTreeItem *pLibraryTreeItem);
  LibraryTreeItem* getContainingFileParentLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void loadLibraryTreeItemPixmap(LibraryTreeItem *pLibraryTreeItem);
  void loadDependentLibraries(QStringList libraries);
  LibraryTreeItem* getLibraryTreeItemFromFile(QString fileName, int lineNumber);
  void showModelWidget(LibraryTreeItem *pLibraryTreeItem, bool show = true, StringHandler::ViewType viewType = StringHandler::NoView);
  void showHideProtectedClasses();
  bool unloadClass(LibraryTreeItem *pLibraryTreeItem, bool askQuestion = true);
  bool unloadCompositeModelOrTextFile(LibraryTreeItem *pLibraryTreeItem, bool askQuestion = true);
  bool unloadOMSModel(LibraryTreeItem *pLibraryTreeItem, bool askQuestion = true);
  bool unloadLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem, bool doDeleteClass);
  bool removeLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem, LibraryTreeItem::LibraryType type);
  bool deleteTextFile(LibraryTreeItem *pLibraryTreeItem, bool askQuestion = true);
  void moveClassUpDown(LibraryTreeItem *pLibraryTreeItem, bool up);
  void moveClassTopBottom(LibraryTreeItem *pLibraryTreeItem, bool top);
  void updateBindings(LibraryTreeItem *pLibraryTreeItem);
  void generateVerificationScenarios(LibraryTreeItem *pLibraryTreeItem);
  QString getUniqueTopLevelItemName(QString name, int number = 1);
  void emitDataChanged(const QModelIndex &topLeft, const QModelIndex &bottomRight) {emit dataChanged(topLeft, bottomRight);}
private:
  LibraryWidget *mpLibraryWidget;
  LibraryTreeItem *mpRootLibraryTreeItem;
  QList<LibraryTreeItem*> mNonExistingLibraryTreeItemsList;
  QModelIndex libraryTreeItemIndexHelper(const LibraryTreeItem *pLibraryTreeItem, const LibraryTreeItem *pParentLibraryTreeItem,
                                         const QModelIndex &parentIndex) const;
  LibraryTreeItem* getLibraryTreeItemFromFileHelper(LibraryTreeItem *pLibraryTreeItem, QString fileName, int lineNumber);
  void updateOMSLibraryTreeItemClassText(LibraryTreeItem *pLibraryTreeItem);
  void readLibraryTreeItemClassTextFromText(LibraryTreeItem *pLibraryTreeItem, QString contents);
  QString readLibraryTreeItemClassTextFromFile(LibraryTreeItem *pLibraryTreeItem);
public:
  void createLibraryTreeItems(LibraryTreeItem *pLibraryTreeItem);
  void updateOMSChildLibraryTreeItemClassText(LibraryTreeItem *pLibraryTreeItem);
private:
  LibraryTreeItem* createLibraryTreeItemImpl(QString name, LibraryTreeItem *pParentLibraryTreeItem, bool isSaved = true,
                                             bool isSystemLibrary = false, bool load = false, int row = -1, bool activateAccessAnnotations = false);
  void createNonExistingLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem, LibraryTreeItem *pParentLibraryTreeItem, bool isSaved = true,
                                        int row = -1);
  void createLibraryTreeItemsImpl(QFileInfo fileInfo, LibraryTreeItem *pParentLibraryTreeItem);
  LibraryTreeItem* createLibraryTreeItemImpl(LibraryTreeItem::LibraryType type, QString name, QString nameStructure, QString path, bool isSaved,
                                             LibraryTreeItem *pParentLibraryTreeItem, int row = -1);
  LibraryTreeItem* createOMSLibraryTreeItemImpl(QString name, QString nameStructure, QString path, bool isSaved,
                                                LibraryTreeItem *pParentLibraryTreeItem, oms_element_t *pOMSElement = 0,
                                                oms_connector_t *pOMSConnector = 0, oms_busconnector_t *pOMSBusConnector = 0,
                                                oms_tlmbusconnector_t *pOMSTLMBusConnector = 0);
  void createOMSConnectorLibraryTreeItems(LibraryTreeItem *pLibraryTreeItem);
  void createOMSBusConnectorLibraryTreeItems(LibraryTreeItem *pLibraryTreeItem);
  void createOMSTLMBusConnectorLibraryTreeItems(LibraryTreeItem *pLibraryTreeItem);
  void unloadClassHelper(LibraryTreeItem *pLibraryTreeItem, LibraryTreeItem *pParentLibraryTreeItem);
  void unloadClassChildren(LibraryTreeItem *pLibraryTreeItem);
  void unloadFileHelper(LibraryTreeItem *pLibraryTreeItem, LibraryTreeItem *pParentLibraryTreeItem);
public:
  void unloadFileChildren(LibraryTreeItem *pLibraryTreeItem);
private:
  void deleteFileHelper(LibraryTreeItem *pLibraryTreeItem, LibraryTreeItem *pParentLibraryTreeItem);
  void deleteFileChildren(LibraryTreeItem *pLibraryTreeItem);
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
  QAction *mpOpenClassAction;
  QAction *mpViewIconAction;
  QAction *mpViewDiagramAction;
  QAction *mpViewTextAction;
  QAction *mpViewDocumentationAction;
  QAction *mpInformationAction;
  QAction *mpNewModelicaClassAction;
  QAction *mpNewModelicaClassEmptyAction;
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
  QAction *mpCallFunctionAction;
  QAction *mpSimulateWithTransformationalDebuggerAction;
  QAction *mpSimulateWithAlgorithmicDebuggerAction;
#if !defined(WITHOUT_OSG)
  QAction *mpSimulateWithAnimationAction;
#endif
  QAction *mpSimulationSetupAction;
  QAction *mpDuplicateClassAction;
  QAction *mpUnloadClassAction;
  QAction *mpUnloadCompositeModelFileAction;
  QAction *mpNewFileAction;
  QAction *mpNewFileEmptyAction;
  QAction *mpNewFolderAction;
  QAction *mpNewFolderEmptyAction;
  QAction *mpRenameAction;
  QAction *mpDeleteAction;
  QAction *mpExportFMUAction;
  QAction *mpExportReadonlyPackageAction;
  QAction *mpExportEncryptedPackageAction;
  QAction *mpExportXMLAction;
  QAction *mpExportFigaroAction;
  QAction *mpUpdateBindingsAction;
  QAction *mpGenerateVerificationScenariosAction;
  QAction *mpFetchInterfaceDataAction;
  QAction *mpTLMCoSimulationAction;
  QAction *mpOMSRenameAction;
  QAction *mpOMSSimulationSetupAction;
  QAction *mpUnloadOMSModelAction;
  void createActions();
  LibraryTreeItem* getSelectedLibraryTreeItem();
  void libraryTreeItemExpanded(LibraryTreeItem* pLibraryTreeItem);
public slots:
  void libraryTreeItemExpanded(QModelIndex index);
  void showContextMenu(QPoint point);
  void openClass();
  void viewIcon();
  void viewDiagram();
  void viewText();
  void viewDocumentation();
  void openInformationDialog();
  void createNewModelicaClass();
  void createNewModelicaClassEmpty();
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
  void callFunction();
  void simulate();
  void simulateWithTransformationalDebugger();
  void simulateWithAlgorithmicDebugger();
  void simulateWithAnimation();
  void simulationSetup();
  void duplicateClass();
  void unloadClass();
  void unloadCompositeModelOrTextFile();
  void createNewFile();
  void createNewFileEmpty();
  void createNewFolder();
  void createNewFolderEmpty();
  void renameLibraryTreeItem();
  void deleteTextFile();
  void exportModelFMU();
  void exportEncryptedPackage();
  void exportReadonlyPackage();
  void exportModelXML();
  void exportModelFigaro();
  void updateBindings();
  void generateVerificationScenarios();
  void fetchInterfaceData();
  void TLMSimulate();
  void openOMSSimulationDialog();
  void OMSRename();
  void unloadOMSModel();
protected:
  virtual void mouseDoubleClickEvent(QMouseEvent *event);
  virtual void startDrag(Qt::DropActions supportedActions);
  virtual void keyPressEvent(QKeyEvent *event);
};

class LibraryWidget : public QWidget
{
  Q_OBJECT
public:
  LibraryWidget(QWidget *pParent = 0);
  TreeSearchFilters* getTreeSearchFilters() {return mpTreeSearchFilters;}
  LibraryTreeModel* getLibraryTreeModel() {return mpLibraryTreeModel;}
  LibraryTreeProxyModel* getLibraryTreeProxyModel() {return mpLibraryTreeProxyModel;}
  LibraryTreeView* getLibraryTreeView() {return mpLibraryTreeView;}
  void openFile(QString fileName, QString encoding = Helper::utf8, bool showProgress = true, bool checkFileExists = false,
                bool loadExternalModel = false);
  void openModelicaFile(QString fileName, QString encoding = Helper::utf8, bool showProgress = true);
  void openEncrytpedModelicaLibrary(QString fileName, QString encoding = Helper::utf8, bool showProgress = true);
  void openCompositeModelOrTextFile(QFileInfo fileInfo, bool showProgress = true);
  void openDirectory(QFileInfo fileInfo, bool showProgress = true);
  void openOMSModelFile(QFileInfo fileInfo, bool showProgress = true);
  bool parseCompositeModelFile(QFileInfo fileInfo, QString *pCompositeModelName);
  void parseAndLoadModelicaText(QString modelText);
  bool saveFile(QString fileName, QString contents);
  bool saveLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void saveAsLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  bool saveTotalLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void openLibraryTreeItem(QString nameStructure);
private:
  TreeSearchFilters *mpTreeSearchFilters;
  LibraryTreeModel *mpLibraryTreeModel;
  LibraryTreeProxyModel *mpLibraryTreeProxyModel;
  LibraryTreeView *mpLibraryTreeView;
  bool multipleTopLevelClasses(const QStringList &classesList, const QString &fileName);
  bool saveModelicaLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  bool saveModelicaLibraryTreeItemHelper(LibraryTreeItem *pLibraryTreeItem);
  bool saveModelicaLibraryTreeItemOneFile(LibraryTreeItem *pLibraryTreeItem);
  void saveChildLibraryTreeItemsOneFile(LibraryTreeItem *pLibraryTreeItem);
  void saveChildLibraryTreeItemsOneFileHelper(LibraryTreeItem *pLibraryTreeItem);
  bool saveModelicaLibraryTreeItemFolder(LibraryTreeItem *pLibraryTreeItem);
  bool saveTextLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  bool saveOMSLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void saveOMSLibraryTreeItemHelper(LibraryTreeItem *pLibraryTreeItem, QString fileName);
  bool saveCompositeModelLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  bool saveAsCompositeModelLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  bool saveAsOMSLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  bool saveCompositeModelLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem, QString fileName);
  bool saveTotalLibraryTreeItemHelper(LibraryTreeItem *pLibraryTreeItem);
public slots:
  void searchClasses();
};

#endif // LIBRARYTREEWIDGET_H
