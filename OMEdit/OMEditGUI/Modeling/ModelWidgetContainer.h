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

#ifndef MODELWIDGETCONTAINER_H
#define MODELWIDGETCONTAINER_H

#include <QGraphicsView>
#include <QGraphicsScene>
#include <QStatusBar>
#include <QListWidget>
#include <QMdiArea>
#include <map>
#include <QtWebKit>
#include <QtXmlPatterns>

#include "Component.h"
#include "StringHandler.h"
#include "Helper.h"
#include "BaseEditor.h"
#include "ModelicaTextEditor.h"
#include "TLMEditor.h"
#include "TextEditor.h"

class ModelWidget;
class ComponentInfo;
class LineAnnotation;
class PolygonAnnotation;
class RectangleAnnotation;
class EllipseAnnotation;
class TextAnnotation;
class BitmapAnnotation;


class CoOrdinateSystem
{
public:
  CoOrdinateSystem();
  void setExtent(QList<QPointF> extent) {mExtent = extent;}
  QList<QPointF> getExtent() {return mExtent;}
  void setPreserveAspectRatio(bool PreserveAspectRatio) {mPreserveAspectRatio = PreserveAspectRatio;}
  bool getPreserveAspectRatio() {return mPreserveAspectRatio;}
  void setInitialScale(qreal initialScale) {mInitialScale = initialScale;}
  qreal getInitialScale() {return mInitialScale;}
  void setGrid(QPointF grid) {mGrid = grid;}
  QPointF getGrid() {return mGrid;}
  qreal getHorizontalGridStep();
  qreal getVerticalGridStep();
private:
  QList<QPointF> mExtent;
  bool mPreserveAspectRatio;
  qreal mInitialScale;
  QPointF mGrid;      // horizontal and vertical spacing for grid
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
  CoOrdinateSystem *mpCoOrdinateSystem;
  QRectF mExtentRectangle;
  bool mIsCustomScale;
  bool mAddClassAnnotationNeeded;
  bool mIsCreatingConnection;
  bool mIsCreatingLineShape;
  bool mIsCreatingPolygonShape;
  bool mIsCreatingRectangleShape;
  bool mIsCreatingEllipseShape;
  bool mIsCreatingTextShape;
  bool mIsCreatingBitmapShape;
  Component *mpClickedComponent;
  bool mIsMovingComponentsAndShapes;
  bool mRenderingLibraryPixmap;
  QList<Component*> mComponentsList;
  QList<LineAnnotation*> mConnectionsList;
  QList<ShapeAnnotation*> mShapesList;
  LineAnnotation *mpConnectionLineAnnotation;
  LineAnnotation *mpLineShapeAnnotation;
  PolygonAnnotation *mpPolygonShapeAnnotation;
  RectangleAnnotation *mpRectangleShapeAnnotation;
  EllipseAnnotation *mpEllipseShapeAnnotation;
  TextAnnotation *mpTextShapeAnnotation;
  BitmapAnnotation *mpBitmapShapeAnnotation;
  QAction *mpPropertiesAction;
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
public:
  GraphicsView(StringHandler::ViewType viewType, ModelWidget *parent);
  bool mSkipBackground; /* Do not draw the background rectangle */
  StringHandler::ViewType getViewType() {return mViewType;}
  ModelWidget* getModelWidget() {return mpModelWidget;}
  CoOrdinateSystem* getCoOrdinateSystem() {return mpCoOrdinateSystem;}
  void setExtentRectangle(qreal x1, qreal y1, qreal x2, qreal y2);
  QRectF getExtentRectangle() {return mExtentRectangle;}
  void setIsCustomScale(bool enable) {mIsCustomScale = enable;}
  bool isCustomScale() {return mIsCustomScale;}
  void setAddClassAnnotationNeeded(bool needed) {mAddClassAnnotationNeeded = needed;}
  bool isAddClassAnnotationNeeded() {return mAddClassAnnotationNeeded;}
  void setIsCreatingConnection(bool enable);
  bool isCreatingConnection() {return mIsCreatingConnection;}
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
  void setItemsFlags(bool enable);
  void updateUndoRedoActions(bool enable);
  void setIsMovingComponentsAndShapes(bool enable) {mIsMovingComponentsAndShapes = enable;}
  bool isMovingComponentsAndShapes() {return mIsMovingComponentsAndShapes;}
  void setRenderingLibraryPixmap(bool renderingLibraryPixmap) {mRenderingLibraryPixmap = renderingLibraryPixmap;}
  bool isRenderingLibraryPixmap() {return mRenderingLibraryPixmap;}
  QList<ShapeAnnotation*> getShapesList() {return mShapesList;}
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
  void addComponentToView(QString name, LibraryTreeItem *pLibraryTreeItem, QString transformationString, QPointF position,
                          ComponentInfo *pComponentInfo, bool addObject = true, bool openingClass = false);
  void addComponentToList(Component *pComponent);
  void addComponentToClass(Component *pComponent);
  void deleteComponent(Component *pComponent);
  void deleteComponentFromClass(Component *pComponent);
  void deleteComponentFromList(Component *pComponent);
  Component* getComponentObject(QString componentName);
  QString getUniqueComponentName(QString componentName, int number = 1);
  bool checkComponentName(QString componentName);
  QList<Component*> getComponentsList() {return mComponentsList;}
  QList<LineAnnotation*> getConnectionsList() {return mConnectionsList;}
  void addConnectionToClass(LineAnnotation *pConnectionLineAnnotation);
  void deleteConnectionFromClass(LineAnnotation *pConnectonLineAnnotation);
  void addConnectionToList(LineAnnotation *pConnectionLineAnnotation) {mConnectionsList.append(pConnectionLineAnnotation);}
  void deleteConnectionFromList(LineAnnotation *pConnectionLineAnnotation) {mConnectionsList.removeOne(pConnectionLineAnnotation);}
  void addShapeToList(ShapeAnnotation *pShape) {mShapesList.append(pShape);}
  void deleteShape(ShapeAnnotation *pShape);
  void deleteShapeFromList(ShapeAnnotation *pShape) {mShapesList.removeOne(pShape);}
  void reOrderItems();
  void bringToFront(ShapeAnnotation *pShape);
  void bringForward(ShapeAnnotation *pShape);
  void sendToBack(ShapeAnnotation *pShape);
  void sendBackward(ShapeAnnotation *pShape);
  void removeAllComponents();
  void removeAllShapes();
  void removeAllConnections();
  void createLineShape(QPointF point);
  void createPolygonShape(QPointF point);
  void createRectangleShape(QPointF point);
  void createEllipseShape(QPointF point);
  void createTextShape(QPointF point);
  void createBitmapShape(QPointF point);
  QRectF itemsBoundingRect();
  QPointF snapPointToGrid(QPointF point);
  QPointF movePointByGrid(QPointF point);
  QPointF roundPoint(QPointF point);
  bool hasAnnotation();
  void addItem(QGraphicsItem *pGraphicsItem);
  void removeItem(QGraphicsItem *pGraphicsItem);
private:
  void createActions();
  bool isClassDroppedOnItself(LibraryTreeItem *pLibraryTreeItem);
  bool isAnyItemSelectedAndEditable(int key);
signals:
  void mouseDelete();
  void mouseRotateClockwise();
  void mouseRotateAntiClockwise();
  void keyPressDelete();
  void keyPressRotateClockwise();
  void keyPressRotateAntiClockwise();
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
  void keyRelease();
public slots:
  void addConnection(Component *pComponent);
  void removeCurrentConnection();
  void deleteConnection(LineAnnotation *pConnectionLineAnnotation);
  void resetZoom();
  void zoomIn();
  void zoomOut();
  void selectAll();
  void addClassAnnotation(bool updateModelicaText = true);
  void showGraphicsViewProperties();
  void deleteItems();
  void rotateClockwise();
  void rotateAntiClockwise();
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
};

class WelcomePageWidget : public QWidget
{
  Q_OBJECT
public:
  WelcomePageWidget(MainWindow *parent = 0);
  void addRecentFilesListItems();
  QFrame* getLatestNewsFrame();
  QSplitter* getSplitter();
private:
  MainWindow *mpMainWindow;
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

class ModelWidgetContainer;
class ModelicaTextHighlighter;
class TLMHighlighter;
class Label;
class ModelWidget : public QWidget
{
  Q_OBJECT
public:
  ModelWidget(LibraryTreeItem* pLibraryTreeItem, ModelWidgetContainer *pModelWidgetContainer, QString text, bool newModel);

  class InheritedClass : public QObject
  {
  public:
    InheritedClass()
    {
      mpLibraryTreeItem = 0;
      mIconShapesList.clear();
      mDiagramShapesList.clear();

    }
    InheritedClass(LibraryTreeItem *pLibraryTreeItem)
    {
      mpLibraryTreeItem = pLibraryTreeItem;
      mIconShapesList.clear();
      mDiagramShapesList.clear();
    }
    LibraryTreeItem *mpLibraryTreeItem;
    QList<ShapeAnnotation*> mIconShapesList;
    QList<ShapeAnnotation*> mDiagramShapesList;
    QList<Component*> mIconComponentsList;
    QList<Component*> mDiagramComponentsList;
    QList<LineAnnotation*> mConnectionsList;
  };

  ModelWidgetContainer* getModelWidgetContainer() {return mpModelWidgetContainer;}
  LibraryTreeItem* getLibraryTreeItem() {return mpLibraryTreeItem;}
  QToolButton* getIconViewToolButton() {return mpIconViewToolButton;}
  QToolButton* getDiagramViewToolButton() {return mpDiagramViewToolButton;}
  QToolButton* getTextViewToolButton() {return mpTextViewToolButton;}
  QToolButton* getDocumentationViewToolButton() {return mpDocumentationViewToolButton;}
  GraphicsView* getDiagramGraphicsView() {return mpDiagramGraphicsView;}
  GraphicsView* getIconGraphicsView() {return mpIconGraphicsView;}
  QUndoStack* getUndoStack() {return mpUndoStack;}
  BaseEditor* getEditor() {return mpEditor;}
  void setModelFilePathLabel(QString path) {mpModelFilePathLabel->setText(path);}
  Label* getCursorPositionLabel() {return mpCursorPositionLabel;}
  bool isLoadedWidgetComponents() {return mloadWidgetComponents;}
  void setReloadNeeded(bool reloadNeeded) {mReloadNeeded = reloadNeeded;}
  bool isReloadNeeded() {return mReloadNeeded;}
  void loadModelWidget();
  void addInheritedClass(LibraryTreeItem *pLibraryTreeItem);
  void removeInheritedClass(InheritedClass *pInheritedClass) {mInheritedClassesList.removeOne(pInheritedClass);}
  QList<InheritedClass*> getInheritedClassesList() {return mInheritedClassesList;}
  void clearInheritedClasses() {mInheritedClassesList.clear();}
  InheritedClass* findInheritedClass(LibraryTreeItem *pLibraryTreeItem);
  void setModelModified();
  void modelInheritedClassLoaded(InheritedClass *pInheritedClass);
  void modelInheritedClassUnLoaded(InheritedClass *pInheritedClass);
  ShapeAnnotation* createNonExistingInheritedShape(GraphicsView *pGraphicsView);
  ShapeAnnotation* createInheritedShape(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView);
  Component* createInheritedComponent(Component *pComponent, GraphicsView *pGraphicsView);
  LineAnnotation* createInheritedConnection(LineAnnotation *pConnectionLineAnnotation, LibraryTreeItem *pInheritedLibraryTreeItem);
  void createWidgetComponents();
  Component* getConnectorComponent(Component *pConnectorComponent, QString connectorName);
  void refresh();
  bool validateText();
  bool modelicaEditorTextChanged();
  void updateClassAnnotationIfNeeded();
  void updateModelicaText();
  void updateUndoRedoActions();
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
  Label *mpModelFilePathLabel;
  Label *mpCursorPositionLabel;
  QToolButton *mpFileLockToolButton;
  GraphicsView *mpDiagramGraphicsView;
  GraphicsScene *mpDiagramGraphicsScene;
  GraphicsView *mpIconGraphicsView;
  GraphicsScene *mpIconGraphicsScene;
  QUndoStack *mpUndoStack;
  QUndoView *mpUndoView;
  BaseEditor *mpEditor;
  ModelicaTextHighlighter *mpModelicaTextHighlighter;
  TLMHighlighter *mpTLMHighlighter;
  QStatusBar *mpModelStatusBar;
  bool mloadWidgetComponents;
  bool mReloadNeeded;
  QList<InheritedClass*> mInheritedClassesList;
  void getModelInheritedClasses(LibraryTreeItem *pLibraryTreeItem);
  void drawModelInheritedClasses();
  void removeInheritedClassShapes(InheritedClass *pInheritedClass, StringHandler::ViewType viewType);
  void drawModelInheritedClassShapes(InheritedClass *pInheritedClass, StringHandler::ViewType viewType);
  void getModelIconDiagramShapes();
  void parseModelIconDiagramShapes(QString annotationString, StringHandler::ViewType viewType);
  void drawModelInheritedComponents();
  void removeInheritedClassComponents(InheritedClass *pInheritedClass);
  void drawModelInheritedClassComponents(InheritedClass *pInheritedClass);
  void getModelComponents();
  void drawModelInheritedConnections();
  void removeInheritedClassConnections(InheritedClass *pInheritedClass);
  void drawModelInheritedClassConnections(InheritedClass *pInheritedClass);
  void getModelConnections();
  void getTLMComponents();
  void getTLMConnections();
private slots:
  void showIconView(bool checked);
  void showDiagramView(bool checked);
  void showTextView(bool checked);
public slots:
  void makeFileWritAble();
  void showDocumentationView();
  bool TLMEditorTextChanged();
  void handleCanUndoChanged(bool canUndo);
  void handleCanRedoChanged(bool canRedo);
protected:
  virtual void closeEvent(QCloseEvent *event);
};

class MdiArea;
class ModelWidgetContainer : public MdiArea
{
  Q_OBJECT
public:
  ModelWidgetContainer(MainWindow *pParent);
  void addModelWidget(ModelWidget *pModelWidget, bool checkPreferedView = true);
  ModelWidget* getCurrentModelWidget();
  QMdiSubWindow* getCurrentMdiSubWindow();
  QMdiSubWindow* getMdiSubWindow(ModelWidget *pModelWidget);
  void setPreviousViewType(StringHandler::ViewType viewType);
  StringHandler::ViewType getPreviousViewType();
  void setShowGridLines(bool On);
  bool isShowGridLines();
  bool eventFilter(QObject *object, QEvent *event);
  void changeRecentModelsListSelection(bool moveDown);
private:
  StringHandler::ViewType mPreviousViewType;
  bool mShowGridLines;
  QDialog *mpModelSwitcherDialog;
  QListWidget *mpRecentModelsList;
  void loadPreviousViewType(ModelWidget *pModelWidget);
  void saveModelicaModelWidget(ModelWidget *pModelWidget);
  void saveTextModelWidget(ModelWidget *pModelWidget);
  void saveTLMModelWidget(ModelWidget *pModelWidget);
public slots:
  void openRecentModelWidget(QListWidgetItem *pItem);
  void currentModelWidgetChanged(QMdiSubWindow *pSubWindow);
  void saveModelWidget();
  void saveAsModelWidget();
  void saveTotalModelWidget();
  void printModel();
};

#endif // MODELWIDGETCONTAINER_H
