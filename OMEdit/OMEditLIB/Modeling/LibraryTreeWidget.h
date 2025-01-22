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

#include <QTreeView>
#include <QRegExp>
#include <QSortFilterProxyModel>

class CompleterItem;
class GraphicsView;
class ModelWidget;
class ShapeAnnotation;
class Element;
class LineAnnotation;
class LibraryTreeModel;
class LibraryTreeItem : public QObject
{
  Q_OBJECT
public:
  enum LibraryType {
    Modelica,         /* Used to represent Modelica models. */
    Text,             /* Used to represent text based files. */
    OMS,              /* Used to represent OMSimulator models. */
    CRML              /* Used to represent CRML models. */
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
  LibraryTreeItem(QAbstractItemModel *pParent);
  LibraryTreeItem(LibraryType type, QString text, QString nameStructure, QString fileName, bool isSaved, LibraryTreeItem *pParent = 0);
  ~LibraryTreeItem();
  bool isRootItem() const {return mIsRootItem;}
  int childrenSize() const {return mChildren.size();}
  LibraryTreeItem* childAt(int index) const {return mChildren.at(index);}
  QList<LibraryTreeItem*> childrenItems() {return mChildren;}
  LibraryType getLibraryType() {return mLibraryType;}
  void setLibraryType(LibraryType libraryType) {mLibraryType = libraryType;}
  bool isModelica() const {return mLibraryType == LibraryTreeItem::Modelica;}
  bool isText() const {return mLibraryType == LibraryTreeItem::Text;}
  bool isCRML() const {return mLibraryType == LibraryTreeItem::CRML;}
  bool isSSP() const {return mLibraryType == LibraryTreeItem::OMS;}
  void setSystemLibrary(bool systemLibrary) {mSystemLibrary = systemLibrary;}
  bool isSystemLibrary() {return mSystemLibrary;}
  void setModelWidget(ModelWidget *pModelWidget);
  ModelWidget* getModelWidget() {return mpModelWidget;}
  void setName(QString name) {mName = name;}
  const QString& getName() const {return mName;}
  void setNameStructure(QString nameStructure) {mNameStructure = nameStructure;}
  const QString& getNameStructure() const {return mNameStructure;}
  QString getWhereToMoveFMU();
  void updateClassInformation();
  void setFileName(QString fileName) {mFileName = fileName;}
  const QString& getFileName() const {return mFileName;}
  const QString& getVersion() const;
  const QString& getVersionDate() const;
  const QString& getVersionBuild() const;
  const QString& getDateModified() const;
  const QString& getRevisionId() const;
  bool isCRMLFile() const;
  bool isMOSFile() const {return mFileName.endsWith(".mos");}
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
  bool isSaveInOneFile() const {return mSaveContentsType == LibraryTreeItem::SaveInOneFile;}
  bool isSaveFolderStructure() const {return mSaveContentsType == LibraryTreeItem::SaveFolderStructure;}
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
  bool isEncryptedClass() const {return mFileName.endsWith(".moc");}
  bool isInternal() const {return mInternal;}
  void setInternal(bool internal) {mInternal = internal;}
  bool isAccessAnnotationsEnabled() const {return mAccessAnnotations;}
  void setAccessAnnotations(bool accessAnnotations) {mAccessAnnotations = accessAnnotations;}
  void setOMSElement(oms_element_t *pOMSComponent) {mpOMSElement = pOMSComponent;}
  oms_element_t* getOMSElement() const {return mpOMSElement;}
  bool isSystemElement() const {return (mpOMSElement && (mpOMSElement->type == oms_element_system));}
  bool isComponentElement() const {return (mpOMSElement && (mpOMSElement->type == oms_element_component));}
  bool isFMUComponent() const {return (mpOMSElement && (mpOMSElement->type == oms_element_component) && (mComponentType == oms_component_fmu));}
  bool isExternalTLMModelComponent() const {return (mpOMSElement && (mpOMSElement->type == oms_element_component) && (mComponentType == oms_component_external));}
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
  void setExternalTLMModelInfo(const oms_external_tlm_model_info_t *pExternalTLMModelInfo) { mpExternalTLMModelInfo = pExternalTLMModelInfo;}
  const oms_external_tlm_model_info_t* getExternalTLMModelInfo() const {return mpExternalTLMModelInfo;}
  void setSubModelPath(QString subModelPath) {mSubModelPath = subModelPath;}
  QString getSubModelPath() const {return mSubModelPath;}
  QString getTooltip() const;
  QIcon getLibraryTreeItemIcon() const;
  bool inRange(int lineNumber);
  bool isInPackageOneFile();
  int getNestedLevelInPackage() const;
  void insertChild(int position, LibraryTreeItem *pLibraryTreeItem);
  LibraryTreeItem* child(int row);
  void moveChild(int from, int to);
  const QList<LibraryTreeItem*> &getInheritedClasses();
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
  void updateChildrenNameStructure();
  QString getHTMLDescription() const;

  OMCInterface::getClassInformation_res mClassInformation;
  SimulationOptions mSimulationOptions;
  const QList<ElementInfo> &getComponentsList();
private:
  bool mIsRootItem;
  LibraryTreeItem *mpParentLibraryTreeItem = 0;
  QList<LibraryTreeItem*> mChildren;
  bool mInheritedClassesLoaded = false;
  QList<LibraryTreeItem*> mInheritedClasses;
  QList<ElementInfo> mComponents;
  bool mComponentsLoaded = false;
  LibraryType mLibraryType = LibraryTreeItem::Modelica;
  bool mSystemLibrary = false;
  ModelWidget *mpModelWidget = 0;
  QString mName;
  QString mParentName;
  QString mNameStructure;
  QString mFileName;
  QString mVersionDate;
  QString mVersionBuild;
  QString mDateModified;
  QString mRevisionId;
  bool mReadOnly = false;
  bool mIsSaved = false;
  SaveContentsType mSaveContentsType = LibraryTreeItem::SaveInOneFile;
  QPixmap mPixmap;
  QPixmap mDragPixmap;
  QString mClassTextBefore;
  QString mClassText;
  QString mClassTextAfter;
  bool mExpanded = false;
  bool mInternal = false;
  bool mAccessAnnotations = false;
  oms_element_t *mpOMSElement = 0;
  oms_system_enu_t mSystemType = oms_system_none;
  oms_component_enu_t mComponentType = oms_component_none;
  oms_connector_t *mpOMSConnector = 0;
  oms_busconnector_t *mpOMSBusConnector = 0;
  oms_tlmbusconnector_t *mpOMSTLMBusConnector = 0;
  const oms_fmu_info_t *mpFMUInfo = 0;
  const oms_external_tlm_model_info_t *mpExternalTLMModelInfo = 0;
  QString mSubModelPath;
signals:
  void iconUpdated();
public slots:
  void handleIconUpdated();
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
  virtual bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
};

class LibraryTreeModel : public QAbstractItemModel
{
  Q_OBJECT
public:
  LibraryTreeModel(LibraryWidget *pLibraryWidget);
  LibraryTreeItem* getRootLibraryTreeItem() {return mpRootLibraryTreeItem;}
  int columnCount(const QModelIndex &parent = QModelIndex()) const override;
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const override;
  QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const override;
  QModelIndex parent(const QModelIndex & index) const override;
  QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const override;
  Qt::ItemFlags flags(const QModelIndex &index) const override;
  LibraryTreeItem* findLibraryTreeItem(const QString &name, LibraryTreeItem *pLibraryTreeItem = 0,
                                       Qt::CaseSensitivity caseSensitivity = Qt::CaseSensitive) const;
  LibraryTreeItem* findLibraryTreeItem(const QRegExp &regExp, LibraryTreeItem *pLibraryTreeItem = 0) const;
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  LibraryTreeItem* findLibraryTreeItem(const QRegularExpression &regExp, LibraryTreeItem *pLibraryTreeItem = 0) const;
#endif
  LibraryTreeItem* findLibraryTreeItemOneLevel(const QString &name, LibraryTreeItem *pLibraryTreeItem = 0, Qt::CaseSensitivity caseSensitivity = Qt::CaseSensitive) const;
  QModelIndex libraryTreeItemIndex(const LibraryTreeItem *pLibraryTreeItem) const;
  void addModelicaLibraries(const QVector<QPair<QString, QString> > libraries = QVector<QPair<QString, QString> >());
  LibraryTreeItem* createLibraryTreeItem(QString name, LibraryTreeItem *pParentLibraryTreeItem, bool isSaved = true,
                                         bool isSystemLibrary = false, bool load = false, int row = -1, bool loadingMOL = false);
  void createLibraryTreeItems(QFileInfo fileInfo, LibraryTreeItem *pParentLibraryTreeItem);
  LibraryTreeItem* createLibraryTreeItem(LibraryTreeItem::LibraryType type, QString name, QString nameStructure, QString path, bool isSaved,
                                         LibraryTreeItem *pParentLibraryTreeItem, int row = -1);
  LibraryTreeItem* createLibraryTreeItem(QString name, QString nameStructursre, QString path, bool isSaved,
                                         LibraryTreeItem *pParentLibraryTreeItem, oms_element_t *pOMSElement = 0,
                                         oms_connector_t *pOMSConnector = 0, oms_busconnector_t *pOMSBusConnector = 0,
                                         oms_tlmbusconnector_t *pOMSTLMBusConnector = 0, int row = -1);
  void updateLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void updateLibraryTreeItemClassText(LibraryTreeItem *pLibraryTreeItem);
  void updateChildLibraryTreeItemClassText(LibraryTreeItem *pLibraryTreeItem, QString contents, QString fileName);
  void readLibraryTreeItemClassText(LibraryTreeItem *pLibraryTreeItem);
  LibraryTreeItem* getContainingFileParentLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  LibraryTreeItem* getTopLevelLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void loadLibraryTreeItemPixmap(LibraryTreeItem *pLibraryTreeItem);
  void loadDependentLibraries(QStringList libraries);
  LibraryTreeItem* getLibraryTreeItemFromFile(QString fileName, int lineNumber);
  void showModelWidget(LibraryTreeItem *pLibraryTreeItem, bool show = true);
  void showHideProtectedClasses();
  bool unloadClass(LibraryTreeItem *pLibraryTreeItem, bool askQuestion = true, bool doDeleteClass = true);
  bool reloadClass(LibraryTreeItem *pLibraryTreeItem, bool askQuestion = true);
  bool unloadTextFile(LibraryTreeItem *pLibraryTreeItem, bool askQuestion = true);
  bool unloadOMSModel(LibraryTreeItem *pLibraryTreeItem, bool doDelete = true, bool askQuestion = true);
  void getExpandedLibraryTreeItemsList(LibraryTreeItem *pLibraryTreeItem, QStringList *pExpandedLibraryTreeItemsList);
  void expandLibraryTreeItems(LibraryTreeItem *pLibraryTreeItem, QStringList expandedLibraryTreeItemsList);
  void reLoadOMSimulatorModel(const QString &modelName, const QString &editedCref, const QString &snapShot, const QString &oldEditedCref, const QString &newEditedCref);
  bool unloadLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem, bool doDeleteClass);
  bool removeLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  bool deleteTextFile(LibraryTreeItem *pLibraryTreeItem, bool askQuestion = true);
  void moveClassUpDown(LibraryTreeItem *pLibraryTreeItem, bool up);
  void moveClassTopBottom(LibraryTreeItem *pLibraryTreeItem, bool top);
  void updateBindings(LibraryTreeItem *pLibraryTreeItem);
  void generateVerificationScenarios(LibraryTreeItem *pLibraryTreeItem);
  QString getUniqueTopLevelItemName(QString name, int number = 1);
  void emitDataChanged(const QModelIndex &topLeft, const QModelIndex &bottomRight) {emit dataChanged(topLeft, bottomRight);}
  void createLibraryTreeItems(LibraryTreeItem *pLibraryTreeItem);
  void unloadFileChildren(LibraryTreeItem *pLibraryTreeItem);
  void emitModelStateChanged(const QString &name) {emit modelStateChanged(name);}
  bool isCreatingAutoLoadedLibrary() const {return mCreatingAutoLoadedLibrary;}
  void setCreatingAutoLoadedLibrary(bool creatingAutoLoadedLibrary) {mCreatingAutoLoadedLibrary = creatingAutoLoadedLibrary;}
private:
  LibraryWidget *mpLibraryWidget;
  LibraryTreeItem *mpRootLibraryTreeItem;
  bool mCreatingAutoLoadedLibrary = false;

  QModelIndex libraryTreeItemIndexHelper(const LibraryTreeItem *pLibraryTreeItem, const LibraryTreeItem *pParentLibraryTreeItem, const QModelIndex &parentIndex) const;
  LibraryTreeItem* getLibraryTreeItemFromFileHelper(LibraryTreeItem *pLibraryTreeItem, QString fileName, int lineNumber);
  void readLibraryTreeItemClassTextFromText(LibraryTreeItem *pLibraryTreeItem, QString contents);
  QString readLibraryTreeItemClassTextFromFile(LibraryTreeItem *pLibraryTreeItem);
  LibraryTreeItem* createLibraryTreeItemImpl(QString name, LibraryTreeItem *pParentLibraryTreeItem, bool isSaved = true,
                                             bool isSystemLibrary = false, bool load = false, int row = -1, bool activateAccessAnnotations = false);
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
  void deleteFileHelper(LibraryTreeItem *pLibraryTreeItem, LibraryTreeItem *pParentLibraryTreeItem);
  void deleteFileChildren(LibraryTreeItem *pLibraryTreeItem);
protected:
  Qt::DropActions supportedDropActions() const override;
signals:
  void modelStateChanged(const QString &name);
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
  QAction *mpInformationAction;
  QAction *mpNewModelicaClassAction;
  QAction *mpSaveAction;
  QAction *mpSaveAsAction;
  QAction *mpSaveTotalAction;
  QAction *mpCopyPathAction;
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
  QAction *mpTranslateCRMLAction;
  QAction *mpTranslateAsCRMLAction;
  QAction *mpRunScriptAction;
#if !defined(WITHOUT_OSG)
  QAction *mpSimulateWithAnimationAction;
#endif
  QAction *mpSimulationSetupAction;
  QAction *mpDuplicateClassAction;
  QAction *mpUnloadClassAction;
  QAction *mpReloadClassAction;
  QAction *mpUnloadTextFileAction;
  QAction *mpNewFileAction;
  QAction *mpNewFileEmptyAction;
  QAction *mpNewFolderAction;
  QAction *mpNewFolderEmptyAction;
  QAction *mpRenameAction;
  QAction *mpDeleteAction;
  QAction *mpConvertClassUsesLibrariesAction;
  QAction *mpExportFMUAction;
  QAction *mpExportReadonlyPackageAction;
  QAction *mpExportEncryptedPackageAction;
  QAction *mpExportXMLAction;
  QAction *mpExportFigaroAction;
  QAction *mpUpdateBindingsAction;
  QAction *mpGenerateVerificationScenariosAction;
  QAction *mpOMSRenameAction;
  QAction *mpUnloadOMSModelAction;
  void createActions();
  LibraryTreeItem* getSelectedLibraryTreeItem();
  void libraryTreeItemExpanded(LibraryTreeItem *pLibraryTreeItem);
  void copyClassPathHelper(const QString &classPath);
public slots:
  void libraryTreeItemExpanded(const QModelIndex &index);
  void libraryTreeItemDoubleClicked(const QModelIndex &index);
  void showContextMenu(QPoint point);
  void openClass();
  void openInformationDialog();
  void createNewModelicaClass();
  void saveClass();
  void saveAsClass();
  void saveTotalClass();
  void copyClassPath();
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
  void translateCRML();
  void translateAsCRML();
  void runScript();
  void duplicateClass();
  void unloadClass();
  void reloadClass();
  void unloadTextFile();
  void createNewFile();
  void createNewFileEmpty();
  void createNewFolder();
  void createNewFolderEmpty();
  void renameLibraryTreeItem();
  void deleteTextFile();
  void convertClassUsesLibraries();
  void exportModelFMU();
  void exportEncryptedPackage();
  void exportReadonlyPackage();
  void exportModelXML();
  void exportModelFigaro();
  void updateBindings();
  void generateVerificationScenarios();
  void OMSRename();
  void unloadOMSModel();
protected:
  virtual void startDrag(Qt::DropActions supportedActions) override;
  virtual void keyPressEvent(QKeyEvent *event) override;
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
  void openFile(QString fileName, QString encoding = Helper::utf8, bool showProgress = true, bool checkFileExists = false, bool loadExternalModel = false);
  void openModelicaFile(QString fileName, QString encoding = Helper::utf8, bool showProgress = true, bool secondAttempt = false, int row = -1);
  void openEncryptedModelicaLibrary(QString fileName, QString encoding = Helper::utf8, bool showProgress = true);
  void openTextFile(QFileInfo fileInfo, bool showProgress = true);

  void openDirectory(QFileInfo fileInfo, bool showProgress = true);
  void openOMSModelFile(QFileInfo fileInfo, bool showProgress = true);
  void parseAndLoadModelicaText(QString modelText);
  bool saveFile(QString fileName, QString contents);
  bool saveLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void saveAsLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void saveTotalLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void openLibraryTreeItem(QString nameStructure);
  void loadAutoLoadedLibrary(const QString &modelName);
  bool isLoadingLibraries() const {return mLoadingLibraries;}
  void setLoadingLibraries(bool loadingLibraries) {mLoadingLibraries = loadingLibraries;}
private:
  bool mLoadingLibraries;
  QTimer mAutoLoadedLibrariesTimer;
  QStringList mAutoLoadedLibrariesList;
  TreeSearchFilters *mpTreeSearchFilters;
  LibraryTreeModel *mpLibraryTreeModel;
  LibraryTreeProxyModel *mpLibraryTreeProxyModel;
  LibraryTreeView *mpLibraryTreeView;
  bool multipleTopLevelClasses(const QStringList &classesList, const QString &fileName);
  bool saveModelicaLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem, bool saveAs);
  bool saveModelicaLibraryTreeItemHelper(LibraryTreeItem *pLibraryTreeItem, bool saveAs);
  bool saveModelicaLibraryTreeItemOneFile(LibraryTreeItem *pLibraryTreeItem, bool saveAs);
  void saveChildLibraryTreeItemsOneFile(LibraryTreeItem *pLibraryTreeItem);
  void saveChildLibraryTreeItemsOneFileHelper(LibraryTreeItem *pLibraryTreeItem);
  bool saveModelicaLibraryTreeItemFolder(LibraryTreeItem *pLibraryTreeItem);
  bool saveTextLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem, bool saveAs);
  bool saveOMSLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void saveOMSLibraryTreeItemHelper(LibraryTreeItem *pLibraryTreeItem, QString fileName);
  bool saveAsOMSLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem);
  void saveTotalLibraryTreeItemHelper(LibraryTreeItem *pLibraryTreeItem);
  bool resolveConflictWithLoadedLibraries(const QString &library, const QStringList classes);
  static void cancelLoadingLibraries(const QStringList classes);
private slots:
  void handleAutoLoadedLibrary();
public slots:
  void loadSystemLibrary();
  void loadSystemLibrary(const QString &library, QString version = QString("default"), bool secondAttempt = false);
  void scrollToActiveLibraryTreeItem();
  void searchClasses();
};

#endif // LIBRARYTREEWIDGET_H
