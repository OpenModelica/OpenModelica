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
#include "Element/Element.h"
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
class ElementInfo;
class LineAnnotation;
class PolygonAnnotation;
class RectangleAnnotation;
class EllipseAnnotation;
class TextAnnotation;
class BitmapAnnotation;
class NetworkAccessManager;

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
  CoOrdinateSystem mCoOrdinateSystem;
public:
  CoOrdinateSystem mMergedCoOrdinateSystem;
  CoOrdinateSystem getCoOrdinateSystem() const {return mCoOrdinateSystem;}
  void setCoOrdinateSystem(const CoOrdinateSystem coOrdinateSystem) {mCoOrdinateSystem = coOrdinateSystem;}
private:
  bool mVisualizationView;
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
  Element *mpClickedComponent;
  Element *mpClickedState;
  bool mIsMovingComponentsAndShapes;
  bool mRenderingLibraryPixmap;
  bool mSharpLibraryPixmap;
  QList<Element*> mElementsList;
  // A list of components that are not deleted but are removed from scene.
  QList<Element*> mOutOfSceneElementsList;
  QList<LineAnnotation*> mConnectionsList;
  QList<LineAnnotation*> mOutOfSceneConnectionsList;
  QList<LineAnnotation*> mTransitionsList;
  QList<LineAnnotation*> mOutOfSceneTransitionsList;
  QList<LineAnnotation*> mInitialStatesList;
  QList<LineAnnotation*> mOutOfSceneInitialStatesList;
  QList<ShapeAnnotation*> mShapesList;
  QList<ShapeAnnotation*> mOutOfSceneShapesList;
  QList<Element*> mInheritedElementsList;
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
  QAction *mpCutAction;
  QAction *mpCopyAction;
  QAction *mpPasteAction;
  QAction *mpDuplicateAction;
  QAction *mpRotateClockwiseAction;
  QAction *mpRotateAntiClockwiseAction;
  QAction *mpFlipHorizontalAction;
  QAction *mpFlipVerticalAction;
  QAction *mpCreateConnectorAction;
  QAction *mpCancelConnectionAction;
  QAction *mpSetInitialStateAction;
  QAction *mpCancelTransitionAction;
  // scene->items().contains(...) involves sorting on each items() call, avoid it
  QSet<QGraphicsItem*> mAllItems;
public:
  GraphicsView(StringHandler::ViewType viewType, ModelWidget *pModelWidget, bool visualizationView = false);
  bool mSkipBackground; /* Do not draw the background rectangle */
  QPointF mContextMenuStartPosition;
  bool mContextMenuStartPositionValid;
  StringHandler::ViewType getViewType() {return mViewType;}
  ModelWidget* getModelWidget() {return mpModelWidget;}
  bool isVisualizationView() {return mVisualizationView;}
  void setExtentRectangle(const QRectF rectangle);
  void setIsCustomScale(bool enable) {mIsCustomScale = enable;}
  bool isCustomScale() {return mIsCustomScale;}
  void setAddClassAnnotationNeeded(bool needed) {mAddClassAnnotationNeeded = needed;}
  bool isAddClassAnnotationNeeded() {return mAddClassAnnotationNeeded;}
  void setIsCreatingConnection(const bool enable);
  bool isCreatingConnection() {return mIsCreatingConnection;}
  void setIsCreatingTransition(const bool enable);
  bool isCreatingTransition() {return mIsCreatingTransition;}
  void setIsCreatingLineShape(const bool enable);
  bool isCreatingLineShape() {return mIsCreatingLineShape;}
  void setIsCreatingPolygonShape(const bool enable);
  bool isCreatingPolygonShape() {return mIsCreatingPolygonShape;}
  void setIsCreatingRectangleShape(const bool enable);
  bool isCreatingRectangleShape() {return mIsCreatingRectangleShape;}
  void setIsCreatingEllipseShape(const bool enable);
  bool isCreatingEllipseShape() {return mIsCreatingEllipseShape;}
  void setIsCreatingTextShape(const bool enable);
  bool isCreatingTextShape() {return mIsCreatingTextShape;}
  void setIsCreatingBitmapShape(const bool enable);
  bool isCreatingBitmapShape() {return mIsCreatingBitmapShape;}
  void setIsCreatingPrologue(const bool enable);
  void setIsPanning(bool enable);
  bool isPanning() {return mIsPanning;}
  void setDragModeInternal(bool enable, bool updateCursor = false);
  void setItemsFlags(bool enable);
  void updateUndoRedoActions(bool enable);
  void setIsMovingComponentsAndShapes(bool enable) {mIsMovingComponentsAndShapes = enable;}
  bool isMovingComponentsAndShapes() {return mIsMovingComponentsAndShapes;}
  void setRenderingLibraryPixmap(bool renderingLibraryPixmap) {mRenderingLibraryPixmap = renderingLibraryPixmap;}
  bool isRenderingLibraryPixmap() {return mRenderingLibraryPixmap;}
  void setSharpLibraryPixmap(bool sharpLibraryPixmap) {mSharpLibraryPixmap = sharpLibraryPixmap;}
  bool useSharpLibraryPixmap() {return mSharpLibraryPixmap;}
  QList<ShapeAnnotation*> getShapesList() {return mShapesList;}
  QList<ShapeAnnotation*> getInheritedShapesList() {return mInheritedShapesList;}
  QAction* getManhattanizeAction() {return mpManhattanizeAction;}
  QAction* getDeleteAction() {return mpDeleteAction;}
  QAction* getCutAction() {return mpCutAction;}
  QAction* getCopyAction() {return mpCopyAction;}
  QAction* getPasteAction() {return mpPasteAction;}
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
                          ElementInfo *pComponentInfo, bool addObject, bool openingClass, bool emitComponentAdded);
  void addElementToList(Element *pElement) {mElementsList.append(pElement);}
  void addElementToOutOfSceneList(Element *pElement) {mOutOfSceneElementsList.append(pElement);}
  void addInheritedElementToList(Element *pElement) {mInheritedElementsList.append(pElement);}
  void addElementToClass(Element *pElement);
  void deleteElement(Element *pElement);
  void deleteElementFromClass(Element *pElement);
  void deleteElementFromList(Element *pElement) {mElementsList.removeOne(pElement);}
  void deleteElementFromOutOfSceneList(Element *pElement) {mOutOfSceneElementsList.removeOne(pElement);}
  void deleteInheritedElementFromList(Element *pElement) {mInheritedElementsList.removeOne(pElement);}
  Element* getElementObject(QString elementName);
  QString getUniqueElementName(const QString &nameStructure, const QString &name, QString *defaultName);
  QString getUniqueElementName(QString elementName, int number = 0);
  bool checkElementName(QString elementName);
  QList<Element*> getElementsList() {return mElementsList;}
  QList<Element*> getInheritedElementsList() {return mInheritedElementsList;}
  QList<LineAnnotation*> getConnectionsList() {return mConnectionsList;}
  QList<LineAnnotation*> getInheritedConnectionsList() {return mInheritedConnectionsList;}
  void addConnectionToView(LineAnnotation *pConnectionLineAnnotation);
  bool addConnectionToClass(LineAnnotation *pConnectionLineAnnotation, bool deleteUndo = false);
  void deleteConnectionFromClass(LineAnnotation *pConnectionLineAnnotation);
  void updateConnectionInClass(LineAnnotation *pConnectionLineAnnotation);
  void addConnectionToList(LineAnnotation *pConnectionLineAnnotation) {mConnectionsList.append(pConnectionLineAnnotation);}
  void addConnectionToOutOfSceneList(LineAnnotation *pConnectionLineAnnotation) {mOutOfSceneConnectionsList.append(pConnectionLineAnnotation);}
  void addInheritedConnectionToList(LineAnnotation *pConnectionLineAnnotation) {mInheritedConnectionsList.append(pConnectionLineAnnotation);}
  void deleteConnectionFromList(LineAnnotation *pConnectionLineAnnotation) {mConnectionsList.removeOne(pConnectionLineAnnotation);}
  void deleteConnectionFromOutOfSceneList(LineAnnotation *pConnectionLineAnnotation) {mOutOfSceneConnectionsList.removeOne(pConnectionLineAnnotation);}
  void removeConnectionFromView(LineAnnotation *pConnectionLineAnnotation);
  void removeConnectionsFromView();
  void deleteInheritedConnectionFromList(LineAnnotation *pConnectionLineAnnotation) {mInheritedConnectionsList.removeOne(pConnectionLineAnnotation);}
  int numberOfComponentConnections(Element *pComponent, LineAnnotation *pExcludeConnectionLineAnnotation = 0);
  QList<LineAnnotation*> getTransitionsList() {return mTransitionsList;}
  void addTransitionToClass(LineAnnotation *pTransitionLineAnnotation);
  void deleteTransitionFromClass(LineAnnotation *pTransitionLineAnnotation);
  void addTransitionToList(LineAnnotation *pTransitionLineAnnotation) {mTransitionsList.append(pTransitionLineAnnotation);}
  void addTransitionToOutOfSceneList(LineAnnotation *pTransitionLineAnnotation) {mOutOfSceneTransitionsList.append(pTransitionLineAnnotation);}
  void deleteTransitionFromList(LineAnnotation *pTransitionLineAnnotation) {mTransitionsList.removeOne(pTransitionLineAnnotation);}
  void deleteTransitionFromOutOfSceneList(LineAnnotation *pTransitionLineAnnotation) {mOutOfSceneTransitionsList.removeOne(pTransitionLineAnnotation);}
  void removeTransitionsFromView();
  QList<LineAnnotation*> getInitialStatesList() {return mInitialStatesList;}
  void addInitialStateToClass(LineAnnotation *pInitialStateLineAnnotation);
  void deleteInitialStateFromClass(LineAnnotation *pInitialStateLineAnnotation);
  void addInitialStateToList(LineAnnotation *pInitialStateLineAnnotation) {mInitialStatesList.append(pInitialStateLineAnnotation);}
  void addInitialStateToOutOfSceneList(LineAnnotation *pInitialStateLineAnnotation) {mOutOfSceneInitialStatesList.append(pInitialStateLineAnnotation);}
  void deleteInitialStateFromList(LineAnnotation *pInitialStateLineAnnotation) {mInitialStatesList.removeOne(pInitialStateLineAnnotation);}
  void deleteInitialStateFromOutOfSceneList(LineAnnotation *pInitialStateLineAnnotation) {mOutOfSceneInitialStatesList.removeOne(pInitialStateLineAnnotation);}
  void removeInitialStatesFromView();
  void addShapeToList(ShapeAnnotation *pShape, int index = -1);
  void addShapeToOutOfSceneList(ShapeAnnotation *pShape) {mOutOfSceneShapesList.append(pShape);}
  void addInheritedShapeToList(ShapeAnnotation *pShape) {mInheritedShapesList.append(pShape);}
  void deleteShape(ShapeAnnotation *pShapeAnnotation);
  int deleteShapeFromList(ShapeAnnotation *pShape);
  void deleteShapeFromOutOfSceneList(ShapeAnnotation *pShape) {mOutOfSceneShapesList.removeOne(pShape);}
  void deleteInheritedShapeFromList(ShapeAnnotation *pShape) {mInheritedShapesList.removeOne(pShape);}
  void reOrderShapes();
  void bringToFront(ShapeAnnotation *pShape);
  void bringForward(ShapeAnnotation *pShape);
  void sendToBack(ShapeAnnotation *pShape);
  void sendBackward(ShapeAnnotation *pShape);
  void clearGraphicsView();
  void removeClassComponents();
  void removeOutOfSceneClassComponents();
  void removeInheritedClassShapes();
  void removeInheritedClassElements();
  void removeInheritedClassConnections();
  void removeAllShapes() {mShapesList.clear();}
  void removeOutOfSceneShapes();
  void removeAllConnections() {mConnectionsList.clear();}
  void removeOutOfSceneConnections();
  void removeAllTransitions() {mTransitionsList.clear();}
  void removeOutOfSceneTransitions();
  void removeAllInitialStates() {mInitialStatesList.clear();}
  void removeOutOfSceneInitialStates();
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
  bool isCreatingShape();
  Element* getElementFromQGraphicsItem(QGraphicsItem *pGraphicsItem);
  Element* elementAtPosition(QPoint position);
  Element* connectorComponentAtPosition(QPoint position);
  Element* stateComponentAtPosition(QPoint position);
  static bool updateComponentConnectorSizingParameter(GraphicsView *pGraphicsView, QString className, Element *pComponent);
  bool handleDoubleClickOnComponent(QMouseEvent *event);
  void uncheckAllShapeDrawingActions();
  void setOriginAdjustAndInitialize(ShapeAnnotation* shapeAnnotation);
  void setOriginAdjustAndInitialize(PolygonAnnotation* shapeAnnotation);
  void adjustInitializeDraw(ShapeAnnotation* shapeAnnotation);
  void finishDrawingGenericShape();
  void finishDrawingLineShape(bool removeLastAddedPoint = false);
  void finishDrawingPolygonShape(bool removeLastAddedPoint = false);
  void finishDrawingRectangleShape();
  void finishDrawingEllipseShape();
  void finishDrawingTextShape();
  void finishDrawingBitmapShape();
  void checkEmitUpdateSelect(const bool showPropertiesAndSelect, ShapeAnnotation* shapeAnnotation);
  void copyItems(bool cut);
  void modelicaGraphicsViewContextMenu(QMenu *pMenu);
  void modelicaOneShapeContextMenu(ShapeAnnotation *pShapeAnnotation, QMenu *pMenu);
  void modelicaOneComponentContextMenu(Element *pComponent, QMenu *pMenu);
  void modelicaMultipleItemsContextMenu(QMenu *pMenu);
  void compositeModelGraphicsViewContextMenu(QMenu *pMenu);
  void compositeModelOneShapeContextMenu(ShapeAnnotation *pShapeAnnotation, QMenu *pMenu);
  void compositeModelOneComponentContextMenu(Element *pComponent, QMenu *pMenu);
  void compositeModelMultipleItemsContextMenu(QMenu *pMenu);
  void omsGraphicsViewContextMenu(QMenu *pMenu);
  void omsOneShapeContextMenu(ShapeAnnotation *pShapeAnnotation, QMenu *pMenu);
  void omsOneComponentContextMenu(Element *pComponent, QMenu *pMenu);
  void omsMultipleItemsContextMenu(QMenu *pMenu);
signals:
  void manhattanize();
  void deleteSignal();
  void mouseDuplicate();
  void mouseRotateClockwise();
  void mouseRotateAntiClockwise();
  void mouseFlipHorizontal();
  void mouseFlipVertical();
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
  void addConnection(Element *pComponent);
  void removeCurrentConnection();
  void deleteConnection(LineAnnotation *pConnectionLineAnnotation);
  void addTransition(Element *pComponent);
  void removeCurrentTransition();
  void deleteTransition(LineAnnotation *pTransitionLineAnnotation);
  void deleteInitialState(LineAnnotation *pInitialLineAnnotation);
  void resetZoom();
  void zoomIn();
  void zoomOut();
  void selectAll();
  void cutItems();
  void copyItems();
  void pasteItems();
  void clearSelection(QGraphicsItem *pSelectGraphicsItem = 0);
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
  void createConnector();
  void cancelConnection();
  void setInitialState();
  void cancelTransition();
protected:
  virtual void dragMoveEvent(QDragMoveEvent *event) override;
  virtual void dropEvent(QDropEvent *event) override;
  virtual void drawBackground(QPainter *painter, const QRectF &rect) override;
  virtual void mousePressEvent(QMouseEvent *event) override;
  virtual void mouseMoveEvent(QMouseEvent *event) override;
  virtual void mouseReleaseEvent(QMouseEvent *event) override;
  virtual void mouseDoubleClickEvent(QMouseEvent *event) override;
  virtual void focusOutEvent(QFocusEvent *event) override;
  virtual void keyPressEvent(QKeyEvent *event) override;
  virtual void keyReleaseEvent(QKeyEvent *event) override;
  virtual void contextMenuEvent(QContextMenuEvent *event) override;
  virtual void resizeEvent(QResizeEvent *event) override;
  virtual void wheelEvent(QWheelEvent *event) override;
  virtual void leaveEvent(QEvent *event) override;
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
  NetworkAccessManager *mpLatestNewsNetworkAccessManager;
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

class IconDiagramMap
{
public:
  IconDiagramMap()
  {
    mExtent.clear();
    mExtent << QPointF(0, 0) << QPointF(0, 0);
    mPrimitivesVisible = true;
  }

  QList<QPointF> mExtent;
  bool mPrimitivesVisible;
};

class MimeData : public QMimeData
{
  Q_OBJECT
public:
  MimeData() : QMimeData()
  {
    mComponents.clear();
    mConnections.clear();
    mShapes.clear();
  }
  void addComponent(Element *pComponent) {mComponents.append(pComponent);}
  QList<Element*> getComponents() const {return mComponents;}
  void addConnection(LineAnnotation *pConnectionLineAnnotation) {mConnections.append(pConnectionLineAnnotation);}
  QList<LineAnnotation*> getConnections() const {return mConnections;}
  void addShape(ShapeAnnotation *pShapeAnnotation) {mShapes.append(pShapeAnnotation);}
  QList<ShapeAnnotation*> getShapes() const {return mShapes;}
private:
  QList<Element*> mComponents;
  QList<LineAnnotation*> mConnections;
  QList<ShapeAnnotation*> mShapes;
  // QMimeData interface
public:
  virtual QStringList formats() const override
  {
    return QStringList() << "text/plain" << Helper::cutCopyPasteFormat;
  }
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
  void setDiagramGraphicsView(GraphicsView *pDiagramGraphicsView) {mpDiagramGraphicsView = pDiagramGraphicsView;}
  GraphicsView* getDiagramGraphicsView() {return mpDiagramGraphicsView;}
  void setIconGraphicsView(GraphicsView *pIconGraphicsView) {mpIconGraphicsView = pIconGraphicsView;}
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
  QMap<int, IconDiagramMap> getInheritedClassIconMap() {return mInheritedClassesIconMap;}
  QMap<int, IconDiagramMap> getInheritedClassDiagramMap() {return mInheritedClassesDiagramMap;}
  const QList<ElementInfo*> &getComponentsList() {return mElementsList;}
  QMap<QString, QString> getExtendsModifiersMap(QString extendsClass);
  QMap<QString, QString> getDerivedClassModifiersMap();
  void fetchExtendsModifiers(QString extendsClass);
  void reDrawModelWidgetInheritedClasses();
  void drawModelCoOrdinateSystem(GraphicsView *pGraphicsView);
  void drawModelIconDiagramShapes(QStringList shapes, GraphicsView *pGraphicsView, bool select);
  ShapeAnnotation* createNonExistingInheritedShape(GraphicsView *pGraphicsView);
  static ShapeAnnotation* createInheritedShape(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView);
  Element* createInheritedComponent(Element *pComponent, GraphicsView *pGraphicsView);
  LineAnnotation* createInheritedConnection(LineAnnotation *pConnectionLineAnnotation);
  void loadElements();
  void loadDiagramView();
  void loadConnections();
  void getModelConnections();
  void addConnection(QStringList connectionList, QString connectionAnnotationString, bool addToOMC, bool select);
  void createModelWidgetComponents();
  ShapeAnnotation* drawOMSModelElement();
  void addUpdateDeleteOMSElementIcon(const QString &iconPath);
  Element* getConnectorComponent(Element *pConnectorComponent, QString connectorName);
  void clearGraphicsViews();
  void reDrawModelWidget();
  bool validateText(LibraryTreeItem **pLibraryTreeItem);
  bool modelicaEditorTextChanged(LibraryTreeItem **pLibraryTreeItem);
  void updateChildClasses(LibraryTreeItem *pLibraryTreeItem);
  bool omsimulatorEditorTextChanged();
  void clearSelection();
  void updateClassAnnotationIfNeeded();
  void updateModelText();
  void updateUndoRedoActions();
  bool writeCoSimulationResultFile(QString fileName);
  bool writeVisualXMLFile(QString fileName, bool canWriteVisualXMLFile = false);
  void beginMacro(const QString &text);
  void endMacro();
  void updateViewButtonsBasedOnAccess();
  void associateBusWithConnector(QString busName, QString connectorName);
  void dissociateBusWithConnector(QString busName, QString connectorName);
  void associateBusWithConnectors(QString busName);
  QList<QVariant> toOMSensData();
  void createOMSimulatorUndoCommand(const QString &commandText, const bool doSnapShot = true, const bool switchToEdited = true,
                                    const QString oldEditedCref = QString(""), const QString newEditedCref = QString(""));
  void createOMSimulatorRenameModelUndoCommand(const QString &commandText, const QString &cref, const QString &newCref);
  void processPendingModelUpdate();
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
  QString mIconAnnotationString;
  QString mDiagramAnnotationString;
  bool mExtendsModifiersLoaded;
  QMap<QString, QMap<QString, QString> > mExtendsModifiersMap;
  bool mDerivedClassModifiersLoaded;
  QMap<QString, QString> mDerivedClassModifiersMap;
  QList<LibraryTreeItem*> mInheritedClassesList;
  QMap<int, IconDiagramMap> mInheritedClassesIconMap;
  QMap<int, IconDiagramMap> mInheritedClassesDiagramMap;
  QList<ElementInfo*> mElementsList;
  QStringList mElementsAnnotationsList;
  QTimer mUpdateModelTimer;

  void createUndoStack();
  void handleCanUndoRedoChanged();
  IconDiagramMap getIconDiagramMap(QString mapAnnotation);
  void getModelInheritedClasses();
  void drawModelInheritedClassShapes(ModelWidget *pModelWidget, StringHandler::ViewType viewType);
  void getModelIconDiagramShapes(StringHandler::ViewType viewType);
  void readCoOrdinateSystemFromInheritedClass(ModelWidget *pModelWidget, GraphicsView *pGraphicsView);
  void drawModelInheritedClassComponents(ModelWidget *pModelWidget, StringHandler::ViewType viewType);
  void getModelElements();
  void drawModelIconElements();
  void drawModelDiagramElements();
  void drawModelInheritedClassConnections(ModelWidget *pModelWidget);
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
  void drawOMSElement(LibraryTreeItem *pLibraryTreeItem, const QString &annotation);
  void drawOMSModelConnections();
  void associateBusWithConnector(QString busName, QString connectorName, GraphicsView *pGraphicsView);
  void dissociateBusWithConnector(QString busName, QString connectorName, GraphicsView *pGraphicsView);
  void associateBusWithConnectors(Element *pBusComponent, GraphicsView *pGraphicsView);
  static void removeInheritedClasses(LibraryTreeItem *pLibraryTreeItem);
private slots:
  void showIconView(bool checked);
  void showDiagramView(bool checked);
  void showTextView(bool checked);
  void updateModel();
public slots:
  void makeFileWritAble();
  void showDocumentationView();
  bool compositeModelEditorTextChanged();
  void handleCanUndoChanged(bool canUndo);
  void handleCanRedoChanged(bool canRedo);
protected:
  virtual void closeEvent(QCloseEvent *event) override;
};

void addCloseActionsToSubWindowSystemMenu(QMdiSubWindow *pMdiSubWindow);

class ModelWidgetContainer : public QMdiArea
{
  Q_OBJECT
public:
  ModelWidgetContainer(QWidget *pParent = 0);
  void addModelWidget(ModelWidget *pModelWidget, bool checkPreferedView = true);
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
  bool validateText();
  void getOpenedModelWidgetsOfOMSimulatorModel(const QString &modelName, QStringList *pOpenedModelWidgetsList);
  void getCurrentModelWidgetSelectedComponents(QStringList *pIconSelectedItemsList, QStringList *pDiagramSelectedItemsList);
  void selectCurrentModelWidgetComponents(QStringList iconSelectedItemsList, QStringList diagramSelectedItemsList);
private:
  StringHandler::ViewType mPreviousViewType;
  bool mShowGridLines;
  QDialog *mpModelSwitcherDialog;
  QListWidget *mpRecentModelsList;
  QMdiSubWindow *mpLastActiveSubWindow;
  void loadPreviousViewType(ModelWidget *pModelWidget);
public slots:
  bool openRecentModelWidget(QListWidgetItem *pListWidgetItem);
  void currentModelWidgetChanged(QMdiSubWindow *pSubWindow);
  void updateThreeDViewer(QMdiSubWindow *pSubWindow);
  void saveModelWidget();
  void saveAsModelWidget();
  void saveTotalModelWidget();
  void printModel();
  void fitToDiagram();
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
