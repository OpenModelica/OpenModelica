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

#ifndef MODELWIDGETCONTAINER_H
#define MODELWIDGETCONTAINER_H

#include "CoOrdinateSystem.h"
#include "Component/Component.h"
#include "Util/StringHandler.h"
#include "Util/Helper.h"
#include "Editors/BaseEditor.h"
#include "Editors/ModelicaEditor.h"
#include "Editors/CompositeModelEditor.h"
#include "Editors/OMSimulatorEditor.h"
#include "Editors/CEditor.h"
#include "Editors/TextEditor.h"
#include "Editors/MetaModelicaEditor.h"
#include "LibraryTreeWidget.h"
#include "OMSimulator.h"

#include <QGraphicsView>
#include <QGraphicsScene>
#include <QStatusBar>
#include <QListWidget>
#include <QMdiArea>
#include <QtWebKit>
#include <QtXmlPatterns>
#include <QSplitter>
#include <QUndoStack>
#include <QUndoView>

class ModelWidget;
class ComponentInfo;
class LineAnnotation;
class PolygonAnnotation;
class RectangleAnnotation;
class EllipseAnnotation;
class TextAnnotation;
class BitmapAnnotation;

class GraphicsScene : public QGraphicsScene
{
  Q_OBJECT
public:
  GraphicsScene(StringHandler::ViewType viewType, ModelWidget *pModelWidget);
  ModelWidget *mpModelWidget;
  StringHandler::ViewType mViewType;
};

class LibraryTreeItem;
class GraphicsView : public QGraphicsView
{
  Q_OBJECT
private:
  StringHandler::ViewType mViewType;
  ModelWidget *mpModelWidget;
  bool mVisualizationView;
  QRectF mExtentRectangle;
  bool mIsCustomScale;
  bool mAddClassAnnotationNeeded;
  bool mIsCreatingConnection;
  bool mIsCreatingTransition;
  bool mIsCreatingLineShape;
  bool mIsCreatingPolygonShape;
  bool mIsCreatingRectangleShape;
  bool mIsCreatingEllipseShape;
  bool mIsCreatingTextShape;
  bool mIsCreatingBitmapShape;
  bool mIsPanning;
  QPoint mLastMouseEventPos;
  Component *mpClickedComponent;
  Component *mpClickedState;
  bool mIsMovingComponentsAndShapes;
  bool mRenderingLibraryPixmap;
  QList<Component*> mComponentsList;
  QList<LineAnnotation*> mConnectionsList;
  QList<LineAnnotation*> mTransitionsList;
  QList<LineAnnotation*> mInitialStatesList;
  QList<ShapeAnnotation*> mShapesList;
  QList<Component*> mInheritedComponentsList;
  QList<LineAnnotation*> mInheritedConnectionsList;
  QList<ShapeAnnotation*> mInheritedShapesList;
  LineAnnotation *mpConnectionLineAnnotation;
  LineAnnotation *mpTransitionLineAnnotation;
  LineAnnotation *mpLineShapeAnnotation;
  PolygonAnnotation *mpPolygonShapeAnnotation;
  RectangleAnnotation *mpRectangleShapeAnnotation;
  EllipseAnnotation *mpEllipseShapeAnnotation;
  TextAnnotation *mpTextShapeAnnotation;
  BitmapAnnotation *mpBitmapShapeAnnotation;
  QAction *mpPropertiesAction;
  QAction *mpRenameAction;
  QAction *mpSimulationParamsAction;
  QAction *mpManhattanizeAction;
  QAction *mpDeleteAction;
  QAction *mpBringToFrontAction;
  QAction *mpBringForwardAction;
  QAction *mpSendToBackAction;
  QAction *mpSendBackwardAction;
  QAction *mpDuplicateAction;
  QAction *mpRotateClockwiseAction;
  QAction *mpRotateAntiClockwiseAction;
  QAction *mpFlipHorizontalAction;
  QAction *mpFlipVerticalAction;
  QAction *mpSetInitialStateAction;
  QAction *mpCancelTransitionAction;
public:
  GraphicsView(StringHandler::ViewType viewType, ModelWidget *parent, bool visualizationView = false);
  CoOrdinateSystem mCoOrdinateSystem;
  bool mSkipBackground; /* Do not draw the background rectangle */
  StringHandler::ViewType getViewType() {return mViewType;}
  ModelWidget* getModelWidget() {return mpModelWidget;}
  bool isVisualizationView() {return mVisualizationView;}
  void setExtentRectangle(qreal x1, qreal y1, qreal x2, qreal y2);
  QRectF getExtentRectangle() {return mExtentRectangle;}
  void setIsCustomScale(bool enable) {mIsCustomScale = enable;}
  bool isCustomScale() {return mIsCustomScale;}
  void setAddClassAnnotationNeeded(bool needed) {mAddClassAnnotationNeeded = needed;}
  bool isAddClassAnnotationNeeded() {return mAddClassAnnotationNeeded;}
  void setIsCreatingConnection(bool enable);
  bool isCreatingConnection() {return mIsCreatingConnection;}
  void setIsCreatingTransition(bool enable);
  bool isCreatingTransition() {return mIsCreatingTransition;}
  void setIsCreatingLineShape(bool enable);
  bool isCreatingLineShape() {return mIsCreatingLineShape;}
  void setIsCreatingPolygonShape(bool enable);
  bool isCreatingPolygonShape() {return mIsCreatingPolygonShape;}
  void setIsCreatingRectangleShape(bool enable);
  bool isCreatingRectangleShape() {return mIsCreatingRectangleShape;}
  void setIsCreatingEllipseShape(bool enable);
  bool isCreatingEllipseShape() {return mIsCreatingEllipseShape;}
  void setIsCreatingTextShape(bool enable);
  bool isCreatingTextShape() {return mIsCreatingTextShape;}
  void setIsCreatingBitmapShape(bool enable);
  bool isCreatingBitmapShape() {return mIsCreatingBitmapShape;}
  void setIsPanning(bool enable);
  bool isPanning() {return mIsPanning;}
  void setDragModeInternal(bool enable, bool updateCursor = false);
  void setItemsFlags(bool enable);
  void updateUndoRedoActions(bool enable);
  void setIsMovingComponentsAndShapes(bool enable) {mIsMovingComponentsAndShapes = enable;}
  bool isMovingComponentsAndShapes() {return mIsMovingComponentsAndShapes;}
  void setRenderingLibraryPixmap(bool renderingLibraryPixmap) {mRenderingLibraryPixmap = renderingLibraryPixmap;}
  bool isRenderingLibraryPixmap() {return mRenderingLibraryPixmap;}
  QList<ShapeAnnotation*> getShapesList() {return mShapesList;}
  QList<ShapeAnnotation*> getInheritedShapesList() {return mInheritedShapesList;}
  QAction* getManhattanizeAction() {return mpManhattanizeAction;}
  QAction* getDeleteAction() {return mpDeleteAction;}
  QAction* getDuplicateAction() {return mpDuplicateAction;}
  QAction* getBringToFrontAction() {return mpBringToFrontAction;}
  QAction* getBringForwardAction() {return mpBringForwardAction;}
  QAction* getSendToBackAction() {return mpSendToBackAction;}
  QAction* getSendBackwardAction() {return mpSendBackwardAction;}
  QAction* getRotateClockwiseAction() {return mpRotateClockwiseAction;}
  QAction* getRotateAntiClockwiseAction() {return mpRotateAntiClockwiseAction;}
  QAction* getFlipHorizontalAction() {return mpFlipHorizontalAction;}
  QAction* getFlipVerticalAction() {return mpFlipVerticalAction;}
  bool addComponent(QString className, QPointF position);
  void addComponentToView(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, QPointF position,
                          ComponentInfo *pComponentInfo, bool addObject = true, bool openingClass = false);
  void addComponentToList(Component *pComponent) {mComponentsList.append(pComponent);}
  void addInheritedComponentToList(Component *pComponent) {mInheritedComponentsList.append(pComponent);}
  void addComponentToClass(Component *pComponent);
  void deleteComponent(Component *pComponent);
  void deleteComponentFromClass(Component *pComponent);
  void deleteComponentFromList(Component *pComponent) {mComponentsList.removeOne(pComponent);}
  void deleteInheritedComponentFromList(Component *pComponent) {mInheritedComponentsList.removeOne(pComponent);}
  Component* getComponentObject(QString componentName);
  QString getUniqueComponentName(QString componentName, int number = 1);
  bool checkComponentName(QString componentName);
  QList<Component*> getComponentsList() {return mComponentsList;}
  QList<Component*> getInheritedComponentsList() {return mInheritedComponentsList;}
  QList<LineAnnotation*> getConnectionsList() {return mConnectionsList;}
  QList<LineAnnotation*> getInheritedConnectionsList() {return mInheritedConnectionsList;}
  bool addConnectionToClass(LineAnnotation *pConnectionLineAnnotation);
  void deleteConnectionFromClass(LineAnnotation *pConnectionLineAnnotation);
  void updateConnectionInClass(LineAnnotation *pConnectionLineAnnotation);
  void addConnectionToList(LineAnnotation *pConnectionLineAnnotation) {mConnectionsList.append(pConnectionLineAnnotation);}
  void addInheritedConnectionToList(LineAnnotation *pConnectionLineAnnotation) {mInheritedConnectionsList.append(pConnectionLineAnnotation);}
  void deleteConnectionFromList(LineAnnotation *pConnectionLineAnnotation) {mConnectionsList.removeOne(pConnectionLineAnnotation);}
  void removeConnectionsFromView();
  void deleteInheritedConnectionFromList(LineAnnotation *pConnectionLineAnnotation) {mInheritedConnectionsList.removeOne(pConnectionLineAnnotation);}
  QList<LineAnnotation*> getTransitionsList() {return mTransitionsList;}
  void addTransitionToClass(LineAnnotation *pTransitionLineAnnotation);
  void deleteTransitionFromClass(LineAnnotation *pTransitionLineAnnotation);
  void addTransitionToList(LineAnnotation *pTransitionLineAnnotation) {mTransitionsList.append(pTransitionLineAnnotation);}
  void deleteTransitionFromList(LineAnnotation *pTransitionLineAnnotation) {mTransitionsList.removeOne(pTransitionLineAnnotation);}
  void removeTransitionsFromView();
  QList<LineAnnotation*> getInitialStatesList() {return mInitialStatesList;}
  void addInitialStateToClass(LineAnnotation *pInitialStateLineAnnotation);
  void deleteInitialStateFromClass(LineAnnotation *pInitialStateLineAnnotation);
  void addInitialStateToList(LineAnnotation *pInitialStateLineAnnotation) {mInitialStatesList.append(pInitialStateLineAnnotation);}
  void deleteInitialStateFromList(LineAnnotation *pInitialStateLineAnnotation) {mInitialStatesList.removeOne(pInitialStateLineAnnotation);}
  void removeInitialStatesFromView();
  void addShapeToList(ShapeAnnotation *pShape, int index = -1);
  void addInheritedShapeToList(ShapeAnnotation *pShape) {mInheritedShapesList.append(pShape);}
  void deleteShape(ShapeAnnotation *pShapeAnnotation);
  int deleteShapeFromList(ShapeAnnotation *pShape);
  void deleteInheritedShapeFromList(ShapeAnnotation *pShape) {mInheritedShapesList.removeOne(pShape);}
  void reOrderShapes();
  void bringToFront(ShapeAnnotation *pShape);
  void bringForward(ShapeAnnotation *pShape);
  void sendToBack(ShapeAnnotation *pShape);
  void sendBackward(ShapeAnnotation *pShape);
  void removeAllComponents() {mComponentsList.clear();}
  void removeAllShapes() {mShapesList.clear();}
  void removeAllConnections() {mConnectionsList.clear();}
  void removeAllTransitions() {mTransitionsList.clear();}
  void removeAllInitialStates() {mInitialStatesList.clear();}
  void createLineShape(QPointF point);
  void createPolygonShape(QPointF point);
  void createRectangleShape(QPointF point);
  void createEllipseShape(QPointF point);
  void createTextShape(QPointF point);
  void createBitmapShape(QPointF point);
  QRectF itemsBoundingRect();
  QPointF snapPointToGrid(QPointF point);
  QPointF movePointByGrid(QPointF point, QPointF origin = QPointF(0, 0), bool useShiftModifier = false);
  QPointF roundPoint(QPointF point);
  bool hasAnnotation();
  void addItem(QGraphicsItem *pGraphicsItem);
  void removeItem(QGraphicsItem *pGraphicsItem);
  void fitInViewInternal();
private:
  void createActions();
  bool isClassDroppedOnItself(LibraryTreeItem *pLibraryTreeItem);
  bool isAnyItemSelectedAndEditable(int key);
  Component* connectorComponentAtPosition(QPoint position);
  Component* stateComponentAtPosition(QPoint position);
signals:
  void mouseManhattanize();
  void mouseDelete();
  void mouseDuplicate();
  void mouseRotateClockwise();
  void mouseRotateAntiClockwise();
  void mouseFlipHorizontal();
  void mouseFlipVertical();
  void keyPressDelete();
  void keyPressRotateClockwise();
  void keyPressRotateAntiClockwise();
  void keyPressFlipHorizontal();
  void keyPressFlipVertical();
  void keyPressUp();
  void keyPressShiftUp();
  void keyPressCtrlUp();
  void keyPressDown();
  void keyPressShiftDown();
  void keyPressCtrlDown();
  void keyPressLeft();
  void keyPressShiftLeft();
  void keyPressCtrlLeft();
  void keyPressRight();
  void keyPressShiftRight();
  void keyPressCtrlRight();
  void keyPressDuplicate();
public slots:
  void addConnection(Component *pComponent);
  void removeCurrentConnection();
  void deleteConnection(LineAnnotation *pConnectionLineAnnotation);
  void addTransition(Component *pComponent);
  void removeCurrentTransition();
  void deleteTransition(LineAnnotation *pTransitionLineAnnotation);
  void deleteInitialState(LineAnnotation *pInitialLineAnnotation);
  void resetZoom();
  void zoomIn();
  void zoomOut();
  void selectAll();
  void clearSelection();
  void addClassAnnotation(bool alwaysAdd = true);
  void showGraphicsViewProperties();
  void showRenameDialog();
  void showSimulationParamsDialog();
  void manhattanizeItems();
  void deleteItems();
  void duplicateItems();
  void rotateClockwise();
  void rotateAntiClockwise();
  void flipHorizontal();
  void flipVertical();
  void setInitialState();
  void cancelTransition();
protected:
  virtual void dragMoveEvent(QDragMoveEvent *event);
  virtual void dropEvent(QDropEvent *event);
  virtual void drawBackground(QPainter *painter, const QRectF &rect);
  virtual void mousePressEvent(QMouseEvent *event);
  virtual void mouseMoveEvent(QMouseEvent *event);
  virtual void mouseReleaseEvent(QMouseEvent *event);
  virtual void mouseDoubleClickEvent(QMouseEvent *event);
  virtual void focusOutEvent(QFocusEvent *event);
  virtual void keyPressEvent(QKeyEvent *event);
  virtual void keyReleaseEvent(QKeyEvent *event);
  virtual void contextMenuEvent(QContextMenuEvent *event);
  virtual void resizeEvent(QResizeEvent *event);
  virtual void wheelEvent(QWheelEvent *event);
  virtual void leaveEvent(QEvent *event);
};

class WelcomePageWidget : public QWidget
{
  Q_OBJECT
public:
  WelcomePageWidget(QWidget *pParent = 0);
  void addRecentFilesListItems();
  QFrame* getLatestNewsFrame();
  QSplitter* getSplitter();
private:
  QFrame *mpMainFrame;
  QFrame *mpTopFrame;
  Label *mpPixmapLabel;
  Label *mpHeadingLabel;
  QFrame *mpRecentFilesFrame;
  Label *mpRecentFilesLabel;
  Label *mpNoRecentFileLabel;
  QListWidget *mpRecentItemsList;
  QPushButton *mpClearRecentFilesListButton;
  QFrame *mpLatestNewsFrame;
  Label *mpLatestNewsLabel;
  Label *mpNoLatestNewsLabel;
  QListWidget *mpLatestNewsListWidget;
  QPushButton *mpReloadLatestNewsButton;
  Label *mpVisitWebsiteLabel;
  QNetworkAccessManager *mpLatestNewsNetworkAccessManager;
  QSplitter *mpSplitter;
  QFrame *mpBottomFrame;
  QPushButton *mpCreateModelButton;
  QPushButton *mpOpenModelButton;
public slots:
  void addLatestNewsListItems();
private slots:
  void readLatestNewsXML(QNetworkReply *pNetworkReply);
  void openRecentFileItem(QListWidgetItem *pItem);
  void openLatestNewsItem(QListWidgetItem *pItem);
};

class UndoCommand;
class UndoStack : public QUndoStack
{
  Q_OBJECT
public:
  UndoStack(QObject *parent = 0);
  void push(UndoCommand *cmd);

  bool isEnabled() {return mEnabled;}
  void setEnabled(bool enable) {mEnabled = enable;}
private:
  bool mEnabled;
};

class ModelWidgetContainer;
class ModelicaHighlighter;
class CompositeModelHighlighter;
class Label;
class ModelWidget : public QWidget
{
  Q_OBJECT
public:
  ModelWidget(LibraryTreeItem* pLibraryTreeItem, ModelWidgetContainer *pModelWidgetContainer);
  ModelWidgetContainer* getModelWidgetContainer() {return mpModelWidgetContainer;}
  void setLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem) {mpLibraryTreeItem = pLibraryTreeItem;}
  LibraryTreeItem* getLibraryTreeItem() {return mpLibraryTreeItem;}
  QToolButton* getIconViewToolButton() {return mpIconViewToolButton;}
  QToolButton* getDiagramViewToolButton() {return mpDiagramViewToolButton;}
  QToolButton* getTextViewToolButton() {return mpTextViewToolButton;}
  QToolButton* getDocumentationViewToolButton() {return mpDocumentationViewToolButton;}
  GraphicsView* getDiagramGraphicsView() {return mpDiagramGraphicsView;}
  GraphicsView* getIconGraphicsView() {return mpIconGraphicsView;}
  UndoStack* getUndoStack() {return mpUndoStack;}
  BaseEditor* getEditor() {return mpEditor;}
  void setModelClassPathLabel(QString path) {mpModelClassPathLabel->setText(path);}
  void setModelFilePathLabel(QString path) {mpModelFilePathLabel->setText(path);}
  bool isLoadedWidgetComponents() {return mCreateModelWidgetComponents;}
  void addInheritedClass(LibraryTreeItem *pLibraryTreeItem) {mInheritedClassesList.append(pLibraryTreeItem);}
  void removeInheritedClass(LibraryTreeItem *pLibraryTreeItem) {mInheritedClassesList.removeOne(pLibraryTreeItem);}
  void clearInheritedClasses() {mInheritedClassesList.clear();}
  QList<LibraryTreeItem*> getInheritedClassesList() {return mInheritedClassesList;}
  const QList<ComponentInfo*> &getComponentsList() {return mComponentsList;}
  QMap<QString, QString> getExtendsModifiersMap(QString extendsClass);
  void fetchExtendsModifiers(QString extendsClass);
  void reDrawModelWidgetInheritedClasses();
  void drawBaseCoOrdinateSystem(ModelWidget *pModelWidget, GraphicsView *pGraphicsView);
  ShapeAnnotation* createNonExistingInheritedShape(GraphicsView *pGraphicsView);
  ShapeAnnotation* createInheritedShape(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView);
  Component* createInheritedComponent(Component *pComponent, GraphicsView *pGraphicsView);
  LineAnnotation* createInheritedConnection(LineAnnotation *pConnectionLineAnnotation);
  void loadComponents();
  void loadDiagramView();
  void loadConnections();
  void getModelConnections();
  void createModelWidgetComponents();
  ShapeAnnotation* drawOMSModelElement();
  Component* getConnectorComponent(Component *pConnectorComponent, QString connectorName);
  void clearGraphicsViews();
  void reDrawModelWidget();
  bool validateText(LibraryTreeItem **pLibraryTreeItem);
  bool modelicaEditorTextChanged(LibraryTreeItem **pLibraryTreeItem);
  void updateChildClasses(LibraryTreeItem *pLibraryTreeItem);
  bool omsimulatorEditorTextChanged();
  void clearSelection();
  void updateClassAnnotationIfNeeded();
  void updateModelText();
  void updateModelicaTextManually(QString contents);
  void updateUndoRedoActions();
  void updateDynamicResults(QString resultFileName);
  QString getResultFileName() {return mResultFileName;}
  bool writeCoSimulationResultFile(QString fileName);
  bool writeVisualXMLFile(QString fileName, bool canWriteVisualXMLFile = false);
  void beginMacro(const QString &text);
  void endMacro();
  void updateViewButtonsBasedOnAccess();
  void associateBusWithConnector(QString busName, QString connectorName);
  void dissociateBusWithConnector(QString busName, QString connectorName);
  void associateBusWithConnectors(QString busName);
private:
  ModelWidgetContainer *mpModelWidgetContainer;
  LibraryTreeItem *mpLibraryTreeItem;
  QToolButton *mpIconViewToolButton;
  QToolButton *mpDiagramViewToolButton;
  QToolButton *mpTextViewToolButton;
  QToolButton *mpDocumentationViewToolButton;
  QButtonGroup *mpViewsButtonGroup;
  Label *mpReadOnlyLabel;
  Label *mpModelicaTypeLabel;
  Label *mpViewTypeLabel;
  Label *mpModelClassPathLabel;
  Label *mpModelFilePathLabel;
  QToolButton *mpFileLockToolButton;
  GraphicsView *mpDiagramGraphicsView;
  GraphicsScene *mpDiagramGraphicsScene;
  GraphicsView *mpIconGraphicsView;
  GraphicsScene *mpIconGraphicsScene;
  UndoStack *mpUndoStack;
  QUndoView *mpUndoView;
  BaseEditor *mpEditor;
  QStatusBar *mpModelStatusBar;
  bool mComponentsLoaded;
  bool mDiagramViewLoaded;
  bool mConnectionsLoaded;
  bool mCreateModelWidgetComponents;
  bool mExtendsModifiersLoaded;
  QMap<QString, QMap<QString, QString> > mExtendsModifiersMap;
  QList<LibraryTreeItem*> mInheritedClassesList;
  QList<ComponentInfo*> mComponentsList;
  QStringList mComponentsAnnotationsList;
  QString mResultFileName;

  void getModelInheritedClasses();
  void drawModelInheritedClassShapes(ModelWidget *pModelWidget, StringHandler::ViewType viewType);
  void removeInheritedClassShapes(StringHandler::ViewType viewType);
  void getModelIconDiagramShapes(StringHandler::ViewType viewType);
  void drawModelInheritedClassComponents(ModelWidget *pModelWidget, StringHandler::ViewType viewType);
  void removeInheritedClassComponents(StringHandler::ViewType viewType);
  void removeClassComponents(StringHandler::ViewType viewType);
  void getModelComponents();
  void drawModelIconComponents();
  void drawModelDiagramComponents();
  void drawModelInheritedClassConnections(ModelWidget *pModelWidget);
  void removeInheritedClassConnections();
  void getModelTransitions();
  void getModelInitialStates();
  void getMetaModelSubModels();
  void getMetaModelConnections();
  void detectMultipleDeclarations();
  QString getCompositeModelName();
  void getCompositeModelSubModels();
  void getCompositeModelConnections();
  void drawOMSModelIconElements();
  void drawOMSModelDiagramElements();
  void drawOMSModelConnections();
  void associateBusWithConnector(QString busName, QString connectorName, GraphicsView *pGraphicsView);
  void dissociateBusWithConnector(QString busName, QString connectorName, GraphicsView *pGraphicsView);
  void associateBusWithConnectors(Component *pBusComponent, GraphicsView *pGraphicsView);
private slots:
  void showIconView(bool checked);
  void showDiagramView(bool checked);
  void showTextView(bool checked);
public slots:
  void makeFileWritAble();
  void showDocumentationView();
  bool compositeModelEditorTextChanged();
  void handleCanUndoChanged(bool canUndo);
  void handleCanRedoChanged(bool canRedo);
  void removeDynamicResults(QString resultFileName = "");
protected:
  virtual void closeEvent(QCloseEvent *event);
};


void addCloseActionsToSubWindowSystemMenu(QMdiSubWindow *pMdiSubWindow);

class ModelWidgetContainer : public QMdiArea
{
  Q_OBJECT
public:
  ModelWidgetContainer(QWidget *pParent = 0);
  void addModelWidget(ModelWidget *pModelWidget, bool checkPreferedView = true, StringHandler::ViewType viewType = StringHandler::NoView);
  ModelWidget* getCurrentModelWidget();
  ModelWidget* getModelWidget(const QString &className);
  QMdiSubWindow* getCurrentMdiSubWindow();
  QMdiSubWindow* getMdiSubWindow(ModelWidget *pModelWidget);
  void setPreviousViewType(StringHandler::ViewType viewType) {mPreviousViewType = viewType;}
  StringHandler::ViewType getPreviousViewType() {return mPreviousViewType;}
  void setShowGridLines(bool On) {mShowGridLines = On;}
  bool isShowGridLines() {return mShowGridLines;}
  bool eventFilter(QObject *object, QEvent *event);
  void changeRecentModelsListSelection(bool moveDown);
#if !defined(WITHOUT_OSG)
  void updateThreeDViewer(ModelWidget *pModelWidget);
#endif
private:
  StringHandler::ViewType mPreviousViewType;
  bool mShowGridLines;
  QDialog *mpModelSwitcherDialog;
  QListWidget *mpRecentModelsList;
  void loadPreviousViewType(ModelWidget *pModelWidget);
public slots:
  bool openRecentModelWidget(QListWidgetItem *pListWidgetItem);
  void currentModelWidgetChanged(QMdiSubWindow *pSubWindow);
  void updateThreeDViewer(QMdiSubWindow *pSubWindow);
  void saveModelWidget();
  void saveAsModelWidget();
  void saveTotalModelWidget();
  void printModel();
  void showSimulationParams();
  void alignInterfaces();
  void addSystem();
  void addOrEditIcon();
  void deleteIcon();
  void addConnector();
  void addBus();
  void addTLMBus();
  void addSubModel();
};

#endif // MODELWIDGETCONTAINER_H
