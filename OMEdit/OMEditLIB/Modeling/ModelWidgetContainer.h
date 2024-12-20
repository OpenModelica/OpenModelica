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

#include "Element/Element.h"
#include "Util/StringHandler.h"
#include "Util/Helper.h"
#include "Model.h"
#include "Editors/BaseEditor.h"
#include "Editors/ModelicaEditor.h"
#include "Editors/OMSimulatorEditor.h"
#include "Editors/CEditor.h"
#include "Editors/CRMLEditor.h"
#include "Editors/MOSEditor.h"
#include "Editors/TextEditor.h"
#include "Editors/MetaModelicaEditor.h"
#include "LibraryTreeWidget.h"
#include "OMSimulator/OMSimulator.h"

#include <QOpenGLContext>
#include <QGraphicsView>
#include <QGraphicsScene>
#include <QStatusBar>
#include <QListWidget>
#include <QMdiArea>
#ifndef OM_DISABLE_DOCUMENTATION
#ifndef OM_OMEDIT_ENABLE_QTWEBENGINE
#include <QtWebKit>
#endif // #ifndef OM_OMEDIT_ENABLE_QTWEBENGINE
#endif // #ifndef OM_DISABLE_DOCUMENTATION
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

class ModelInfo
{
public:
  ModelInfo();
  Element* getIconElement(const QString &name) const;
  Element* getDiagramElement(const QString &name) const;
  LineAnnotation* getConnection(const QString &startElementName, const QString &endElementName) const;

  QString mName;
  QList<Element*> mIconElementsList;
  QList<Element*> mDiagramElementsList;
  QList<LineAnnotation*> mConnectionsList;
  QList<LineAnnotation*> mTransitionsList;
  QList<LineAnnotation*> mInitialStatesList;
};

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
  QList<LineAnnotation*> mInheritedTransitionsList;
  QList<LineAnnotation*> mInheritedInitialStatesList;
  QList<ShapeAnnotation*> mInheritedShapesList;
  LineAnnotation *mpConnectionLineAnnotation;
  LineAnnotation *mpTransitionLineAnnotation;
  LineAnnotation *mpLineShapeAnnotation;
  PolygonAnnotation *mpPolygonShapeAnnotation;
  RectangleAnnotation *mpRectangleShapeAnnotation;
  EllipseAnnotation *mpEllipseShapeAnnotation;
  TextAnnotation *mpTextShapeAnnotation;
  TextAnnotation *mpErrorTextShapeAnnotation;
  BitmapAnnotation *mpBitmapShapeAnnotation;
  QAction *mpParametersAction;
  QAction *mpPropertiesAction;
  QAction *mpRenameAction;
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
  GraphicsView(StringHandler::ViewType viewType, ModelWidget *pModelWidget);
  ~GraphicsView();
  ModelInstance::CoordinateSystem mCoordinateSystem;
  ModelInstance::CoordinateSystem mMergedCoordinateSystem;
  bool mSkipBackground; /* Do not draw the background rectangle */
  QPointF mContextMenuStartPosition;
  bool mContextMenuStartPositionValid;
  void initializeCoordinateSystem();
  void resetCoordinateSystem();
  bool isIconView() const {return mViewType == StringHandler::Icon;}
  bool isDiagramView() const {return mViewType == StringHandler::Diagram;}
  ModelWidget* getModelWidget() {return mpModelWidget;}
  void setIsVisualizationView(bool visualizationView);
  bool isVisualizationView() {return mVisualizationView;}

  void drawCoordinateSystem();
  void drawShapes(ModelInstance::Model *pModelInstance, bool inhertied, bool openingModel);
  void drawElements(ModelInstance::Model *pModelInstance, bool inherited, const ModelInfo &modelInfo);
  void drawConnections(ModelInstance::Model *pModelInstance, bool inherited, const ModelInfo &modelInfo);
  void drawTransitions(ModelInstance::Model *pModelInstance, bool inherited, const ModelInfo &modelInfo);
  void drawInitialStates(ModelInstance::Model *pModelInstance, bool inherited, const ModelInfo &modelInfo);
  void handleCollidingConnections();

  void setExtentRectangle(const QRectF rectangle, bool moveToCenter);
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
  QList<ShapeAnnotation*> getShapesList() {return mShapesList;}
  void setShapesList(QList<ShapeAnnotation*> shapesList) {mShapesList = shapesList;}
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
  bool performElementCreationChecks(const QString &nameStructure, bool partial, QString *name, QString *defaultPrefix);
  static ModelInstance::Component* createModelInstanceComponent(ModelInstance::Model *pModelInstance, const QString &name, const QString &className);
  static ModelInstance::Component* createModelInstanceComponent(ModelInstance::Model *pModelInstance, const QString &name, const QString &className, bool isConnector);
  bool addComponent(QString className, QPointF position);
  void addElementToView(ModelInstance::Component *pComponent, bool inherited, bool addElementToOMC, bool createTransformation, QPointF position,
                        const QString &placementAnnotation, bool clearSelection);
  void addElementToList(Element *pElement) {mElementsList.append(pElement);}
  void addElementToOutOfSceneList(Element *pElement) {mOutOfSceneElementsList.append(pElement);}
  void addInheritedElementToList(Element *pElement) {mInheritedElementsList.append(pElement);}
  void addElementToClass(Element *pElement);
  static void addUsesAnnotation(const QString &insertedClassName, const QString &containingClassName, bool updateParentText);
  void addElementItem(Element *pElement);
  void removeElementItem(Element *pElement);
  void deleteElement(Element *pElement);
  void deleteElementFromClass(Element *pElement);
  void deleteElementFromList(Element *pElement) {mElementsList.removeOne(pElement);}
  void deleteElementFromOutOfSceneList(Element *pElement) {mOutOfSceneElementsList.removeOne(pElement);}
  void deleteInheritedElementFromList(Element *pElement) {mInheritedElementsList.removeOne(pElement);}
  Element* getElementObject(QString elementName);
  Element* getElementObjectFromQualifiedName(QString elementQualifiedName);
  QString getUniqueElementName(const QString &nameStructure, const QString &name, QString *defaultName);
  QString getUniqueElementName(const QString &nameStructure, QString elementName, int number = 0);
  bool checkElementName(const QString &nameStructure, QString elementName);
  QList<Element*> getElementsList() {return mElementsList;}
  QList<Element*> getInheritedElementsList() {return mInheritedElementsList;}
  QList<LineAnnotation*> getConnectionsList() {return mConnectionsList;}
  bool connectionExists(const QString &startElementName, const QString &endElementName, bool inherited);
  void addConnectionDetails(LineAnnotation *pConnectionLineAnnotation);
  void addConnectionToView(LineAnnotation *pConnectionLineAnnotation, bool inherited);
  bool addConnectionToClass(LineAnnotation *pConnectionLineAnnotation, bool deleteUndo = false);
  void deleteConnectionFromClass(LineAnnotation *pConnectionLineAnnotation);
  void addConnectionToList(LineAnnotation *pConnectionLineAnnotation) {mConnectionsList.append(pConnectionLineAnnotation);}
  void addConnectionToOutOfSceneList(LineAnnotation *pConnectionLineAnnotation) {mOutOfSceneConnectionsList.append(pConnectionLineAnnotation);}
  void addInheritedConnectionToList(LineAnnotation *pConnectionLineAnnotation) {mInheritedConnectionsList.append(pConnectionLineAnnotation);}
  void deleteConnectionFromList(LineAnnotation *pConnectionLineAnnotation) {mConnectionsList.removeOne(pConnectionLineAnnotation);}
  void deleteConnectionFromOutOfSceneList(LineAnnotation *pConnectionLineAnnotation) {mOutOfSceneConnectionsList.removeOne(pConnectionLineAnnotation);}
  void removeConnectionDetails(LineAnnotation *pConnectionLineAnnotation);
  void removeConnectionFromView(LineAnnotation *pConnectionLineAnnotation);
  void removeConnectionsFromView();
  void deleteInheritedConnectionFromList(LineAnnotation *pConnectionLineAnnotation) {mInheritedConnectionsList.removeOne(pConnectionLineAnnotation);}
  int numberOfElementConnections(Element *pElement, LineAnnotation *pExcludeConnectionLineAnnotation = 0);
  QString getConnectorName(Element *pConnector);
  QList<LineAnnotation*> getTransitionsList() {return mTransitionsList;}
  void addTransitionToView(LineAnnotation *pTransitionLineAnnotation, bool inherited);
  void addTransitionToClass(LineAnnotation *pTransitionLineAnnotation);
  void removeTransitionFromView(LineAnnotation *pTransitionLineAnnotation);
  void deleteTransitionFromClass(LineAnnotation *pTransitionLineAnnotation);
  void addTransitionToList(LineAnnotation *pTransitionLineAnnotation) {mTransitionsList.append(pTransitionLineAnnotation);}
  void addTransitionToOutOfSceneList(LineAnnotation *pTransitionLineAnnotation) {mOutOfSceneTransitionsList.append(pTransitionLineAnnotation);}
  void addInheritedTransitionToList(LineAnnotation *pTransitionLineAnnotation) {mInheritedTransitionsList.append(pTransitionLineAnnotation);}
  void deleteTransitionFromList(LineAnnotation *pTransitionLineAnnotation) {mTransitionsList.removeOne(pTransitionLineAnnotation);}
  void deleteTransitionFromOutOfSceneList(LineAnnotation *pTransitionLineAnnotation) {mOutOfSceneTransitionsList.removeOne(pTransitionLineAnnotation);}
  void removeTransitionsFromView();
  void deleteInheritedTransitionFromList(LineAnnotation *pTransitionLineAnnotation) {mInheritedTransitionsList.removeOne(pTransitionLineAnnotation);}
  QList<LineAnnotation*> getInitialStatesList() {return mInitialStatesList;}
  void addInitialStateToView(LineAnnotation *pInitialStateLineAnnotation, bool inherited);
  void addInitialStateToClass(LineAnnotation *pInitialStateLineAnnotation);
  void removeInitialStateFromView(LineAnnotation *pInitialStateLineAnnotation);
  void deleteInitialStateFromClass(LineAnnotation *pInitialStateLineAnnotation);
  void addInitialStateToList(LineAnnotation *pInitialStateLineAnnotation) {mInitialStatesList.append(pInitialStateLineAnnotation);}
  void addInitialStateToOutOfSceneList(LineAnnotation *pInitialStateLineAnnotation) {mOutOfSceneInitialStatesList.append(pInitialStateLineAnnotation);}
  void addInheritedInitialStateToList(LineAnnotation *pInitialStateLineAnnotation) {mInheritedInitialStatesList.append(pInitialStateLineAnnotation);}
  void deleteInitialStateFromList(LineAnnotation *pInitialStateLineAnnotation) {mInitialStatesList.removeOne(pInitialStateLineAnnotation);}
  void deleteInitialStateFromOutOfSceneList(LineAnnotation *pInitialStateLineAnnotation) {mOutOfSceneInitialStatesList.removeOne(pInitialStateLineAnnotation);}
  void removeInitialStatesFromView();
  void deleteInheritedInitialStateFromList(LineAnnotation *pInitialStateLineAnnotation) {mInheritedInitialStatesList.removeOne(pInitialStateLineAnnotation);}
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
  void clearGraphicsViewsExceptOutOfSceneItems();
  void removeClassComponents();
  void removeShapesFromScene();
  void removeElementsFromScene();
  void removeOutOfSceneClassComponents();
  void removeInheritedClassShapes();
  void removeInheritedClassElements();
  void removeInheritedClassConnections();
  void removeInheritedClassTransitions();
  void removeInheritedClassInitialStates();
  void removeAllShapes() {mShapesList.clear();}
  void removeOutOfSceneShapes();
  void removeAllConnections() {mConnectionsList.clear();}
  void removeConnectionsFromScene();
  void removeOutOfSceneConnections();
  void removeAllTransitions() {mTransitionsList.clear();}
  void removeTransitionsFromScene();
  void removeOutOfSceneTransitions();
  void removeAllInitialStates() {mInitialStatesList.clear();}
  void removeInitialStatesFromScene();
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
  void emitResetDynamicSelect();
  void showReplaceSubModelDialog(QString name);
  void addErrorTextShape();
  void removeErrorTextShape();
private:
  void createActions();
  bool isClassDroppedOnItself(LibraryTreeItem *pLibraryTreeItem);
  bool isAnyItemSelectedAndEditable(int key);
  void duplicateItems(const QString &action);
  bool isCreatingShape();
  Element* getElementFromQGraphicsItem(QGraphicsItem *pGraphicsItem);
  Element* elementAtPosition(QPoint position);
  Element* connectorElementAtPosition(QPoint position);
  Element* stateElementAtPosition(QPoint position);
  static bool updateElementConnectorSizingParameter(GraphicsView *pGraphicsView, QString className, Element *pElement);
  Element* getConnectorElement(ModelInstance::Connector *pConnector);
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
  void omsGraphicsViewContextMenu(QMenu *pMenu);
  void omsOneShapeContextMenu(ShapeAnnotation *pShapeAnnotation, QMenu *pMenu);
  void omsOneComponentContextMenu(Element *pComponent, QMenu *pMenu);
  void omsMultipleItemsContextMenu(QMenu *pMenu);
  void getCoordinateSystemAndGraphics(QStringList &coOrdinateSystemList, QStringList &graphicsList);
signals:
  void manhattanize();
  void deleteSignal();
  void duplicate();
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
  void updateDynamicSelect(double time);
  void resetDynamicSelect();
public slots:
  void addConnection(Element *pComponent, bool createConnector = false);
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
  void addClassAnnotation();
  void showParameters();
  void showGraphicsViewProperties();
  void showRenameDialog();
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
  QPushButton *mpSystemLibrariesButton;
  QPushButton *mpInstallLibraryButton;
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
class Label;
class ModelWidget : public QWidget
{
  Q_OBJECT
public:
  ModelWidget(LibraryTreeItem* pLibraryTreeItem, ModelWidgetContainer *pModelWidgetContainer);
  ~ModelWidget();
  ModelWidgetContainer* getModelWidgetContainer() {return mpModelWidgetContainer;}
  ModelInstance::Model *getModelInstance() const {return mpModelInstance;}
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
  bool isDiagramViewLoaded() const {return mDiagramViewLoaded;}
  void setModelClassPathLabel(QString path) {mpModelClassPathLabel->setText(path);}
  void setModelFilePathLabel(QString path) {mpModelFilePathLabel->setText(path);}
  QVBoxLayout* getMainLayout() {return mpMainLayout;}
  bool isLoadedWidgetComponents() {return mCreateModelWidgetComponents;}
  QList<LibraryTreeItem*> getInheritedClassesList() {return mInheritedClassesList;}

  void addDependsOnModel(const QString &dependsOnModel);
  void clearDependsOnModels() {mDependsOnModelsList.clear();}
  void setHandleCollidingConnectionsNeeded(bool needed) {mHandleCollidingConnectionsNeeded = needed;}
  bool isHandleCollidingConnectionsNeeded() {return mHandleCollidingConnectionsNeeded;}
  void setRequiresUpdate(bool requiresUpdate) {mRequiresUpdate = requiresUpdate;}
  bool requiresUpdate() {return mRequiresUpdate;}
  bool isElementMode() const {return !mModelInstanceList.isEmpty();}
  void setComponentModified(bool modified) {mComponentModified = modified;}
  bool isComponentModified() const {return mComponentModified;}
  void setRestoringModel(bool restoring) {mRestoringModel = restoring;}
  bool isRestoringModel() const {return mRestoringModel;}

  void drawModelIconDiagramShapes(QStringList shapes, GraphicsView *pGraphicsView, bool select);

  void drawModel(const ModelInfo &modelInfo);
  void drawModelIconDiagram(ModelInstance::Model *pModelInstance, bool inherited, const ModelInfo &modelInfo);
  void loadModelInstance(bool icon, const ModelInfo &modelInfo);
  void loadDiagramViewNAPI();
  void detectMultipleDeclarations();
  void createModelWidgetComponents();
  ShapeAnnotation* drawOMSModelElement();
  void addUpdateDeleteOMSElementIcon(const QString &iconPath);
  Element* getConnectorElement(Element *pConnectorComponent, QString connectorName);
  void clearGraphicsViews();
  void clearGraphicsViewsExceptOutOfSceneItems();
  void reDrawModelWidget();
  void reDrawModelWidget(const ModelInfo &modelInfo);
  bool validateText(LibraryTreeItem **pLibraryTreeItem);
  bool modelicaEditorTextChanged(LibraryTreeItem **pLibraryTreeItem);
  void updateChildClasses(LibraryTreeItem *pLibraryTreeItem);
  bool omsimulatorEditorTextChanged();
  void clearSelection();
  void updateClassAnnotationIfNeeded();
  void updateModelText();
  void callHandleCollidingConnectionsIfNeeded();
  void updateUndoRedoActions();
  void beginMacro(const QString &text);
  void endMacro();
  void updateViewButtonsBasedOnAccess();
  void associateBusWithConnectors(QString busName);
  QList<QVariant> toOMSensData();
  void createOMSimulatorUndoCommand(const QString &commandText, const bool doSnapShot = true, const bool switchToEdited = true,
                                    const QString oldEditedCref = QString(""), const QString newEditedCref = QString(""));
  void createOMSimulatorRenameModelUndoCommand(const QString &commandText, const QString &cref, const QString &newCref);
  void processPendingModelUpdate();
  ModelInfo createModelInfo() const;
  void showElement(ModelInstance::Model *pModelInstance, bool addToList);
  void selectDeselectElement(const QString &name, bool selected);
  void navigateToClass(const QString &className);
private:
  ModelWidgetContainer *mpModelWidgetContainer;
  ModelInstance::Model *mpModelInstance;
  LibraryTreeItem *mpLibraryTreeItem;
  QToolButton *mpIconViewToolButton;
  QToolButton *mpDiagramViewToolButton;
  QToolButton *mpTextViewToolButton;
  QToolButton *mpDocumentationViewToolButton;
  QButtonGroup *mpViewsButtonGroup;
  QToolButton *mpBackToolButton;
  QToolButton *mpForwardToolButton;
  QToolButton *mpExitToolButton;
  Label *mpElementModeLabel;
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
  bool mDiagramViewLoaded;
  bool mCreateModelWidgetComponents;
  QVBoxLayout *mpMainLayout;
  QList<LibraryTreeItem*> mInheritedClassesList;
  QTimer mUpdateModelTimer;
  QStringList mDependsOnModelsList;
  bool mHandleCollidingConnectionsNeeded = false;
  bool mRequiresUpdate = false;
  ModelInstance::Model *mpRootModelInstance;
  QList<ModelInstance::Model*> mModelInstanceList;
  int mModelInstancesPos = -1;
  QList<ShapeAnnotation*> mPreservedIconShapesList;
  QList<ShapeAnnotation*> mPreservedDiagramShapesList;
  ModelInfo mModelInfo;
  bool mComponentModified = false;
  bool mRestoringModel = false;

  void createUndoStack();
  void handleCanUndoRedoChanged();
  void drawOMSModelIconElements();
  void drawOMSModelDiagramElements();
  void drawOMSElement(LibraryTreeItem *pLibraryTreeItem, const QString &annotation);
  void drawOMSModelConnections();
  void associateBusWithConnectors(Element *pBusComponent, GraphicsView *pGraphicsView);
  bool dependsOnModel(const QString &modelName);
  void updateElementModeButtons();
private slots:
  void showIconView(bool checked);
  void showDiagramView(bool checked);
  void showTextView(bool checked);
  void backElement();
  void forwardElement();
  void exitElement();
  void updateModel();
public slots:
  void makeFileWritAble();
  void showDocumentationView();
  void handleCanUndoChanged(bool canUndo);
  void handleCanRedoChanged(bool canRedo);
  void updateModelIfDependsOn(const QString &modelName);
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
  bool validateText();
  void getOpenedModelWidgetsAndSelectedElementsOfClass(const QString &modelName, QHash<QString, QPair<QStringList, QStringList> > *pOpenedModelWidgetsAndSelectedElements);
  void openModelWidgetsAndSelectElement(QHash<QString, QPair<QStringList, QStringList> > closedModelWidgetsAndSelectedElements, bool skipSelection = false);
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
  void saveModelWidget();
  void saveAsModelWidget();
  void saveTotalModelWidget();
  void printModel();
  void fitToDiagram();
  void addSystem();
  void addOrEditIcon();
  void deleteIcon();
  void addConnector();
  void addBus();
  void addTLMBus();
  void addSubModel();
};

#endif // MODELWIDGETCONTAINER_H
