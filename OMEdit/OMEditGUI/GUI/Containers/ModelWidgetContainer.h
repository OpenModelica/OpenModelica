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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
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

#include "Component.h"
#include "StringHandler.h"
#include "Helper.h"
#include "Utilities.h"
#include "ModelicaTextWidget.h"

class ModelWidget;
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
  void setExtent(QList<QPointF> extent);
  QList<QPointF> getExtent();
  void setPreserveAspectRatio(bool PreserveAspectRatio);
  bool getPreserveAspectRatio();
  void setInitialScale(qreal initialScale);
  qreal getInitialScale();
  void setGrid(QPointF grid);
  QPointF getGrid();
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
  GraphicsScene(int iconType, ModelWidget *parent);
  ModelWidget *mpModelWidget;
  int mIconType;
};

class GraphicsView : public QGraphicsView
{
  Q_OBJECT
private:
  StringHandler::ViewType mViewType;
  ModelWidget *mpModelWidget;
  CoOrdinateSystem *mpCoOrdinateSystem;
  bool mIsCustomScale;
  bool mCanAddClassAnnotation;
  bool mIsCreatingConnection;
  bool mDeleteCreatingConnection;
  bool mIsCreatingLineShape;
  bool mIsCreatingPolygonShape;
  bool mIsCreatingRectangleShape;
  bool mIsCreatingEllipseShape;
  bool mIsCreatingTextShape;
  bool mIsCreatingBitmapShape;
  bool mIsMovingComponentsAndShapes;
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
  QAction *mpCancelConnectionAction;
  QAction *mpDeleteConnectionAction;
  QAction *mpDeleteAction;
  QAction *mpDuplicateAction;
  QAction *mpRotateClockwiseAction;
  QAction *mpRotateAntiClockwiseAction;
  QAction *mpFlipHorizontalAction;
  QAction *mpFlipVerticalAction;
public:
  GraphicsView(StringHandler::ViewType viewType, ModelWidget *parent);
  bool mSkipBackground; /* Do not draw the background rectangle */
  StringHandler::ViewType getViewType();
  ModelWidget* getModelWidget();
  CoOrdinateSystem* getCoOrdinateSystem();
  void setIsCustomScale(bool enable);
  bool isCustomScale();
  void setCanAddClassAnnotation(bool enable);
  bool canAddClassAnnotation();
  void setIsCreatingConnection(bool enable);
  bool isCreatingConnection();
  void setDeleteCreatingConnection(bool enable);
  bool canDeleteCreatingConnection();
  void setIsCreatingLineShape(bool enable);
  bool isCreatingLineShape();
  void setIsCreatingPolygonShape(bool enable);
  bool isCreatingPolygonShape();
  void setIsCreatingRectangleShape(bool enable);
  bool isCreatingRectangleShape();
  void setIsCreatingEllipseShape(bool enable);
  bool isCreatingEllipseShape();
  void setIsCreatingTextShape(bool enable);
  bool isCreatingTextShape();
  void setIsCreatingBitmapShape(bool enable);
  bool isCreatingBitmapShape();
  void setIsMovingComponentsAndShapes(bool enable);
  bool isMovingComponentsAndShapes();
  QAction* getDeleteConnectionAction();
  QAction* getDeleteAction();
  QAction* getDuplicateAction();
  QAction* getRotateClockwiseAction();
  QAction* getRotateAntiClockwiseAction();
  QAction* getFlipHorizontalAction();
  QAction* getFlipVerticalAction();
  bool addComponent(QString className, QPointF position);
  void addComponentToView(QString name, QString className, QString transformationString, QPointF point, StringHandler::ModelicaClasses type,
                          bool addObject = true, bool openingClass = false, bool inheritedClass = false);
  void addComponentObject(Component *pComponent);
  void deleteComponentObject(Component *pComponent);
  Component* getComponentObject(QString componentName);
  QString getUniqueComponentName(QString componentName, int number = 1);
  bool checkComponentName(QString componentName);
  QList<Component*> getComponentList();
  void createConnection(QString startComponentName, QString endComponentName);
  void deleteConnection(QString startComponentName, QString endComponentName);
  void addConnectionObject(LineAnnotation *pConnectionLineAnnotation);
  void deleteConnectionObject(LineAnnotation *pConnectionLineAnnotation);
  void addShapeObject(ShapeAnnotation *pShape);
  void deleteShapeObject(ShapeAnnotation *pShape);
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
private:
  void createActions();
signals:
  void keyPressDelete();
  void keyPressRotateClockwise();
  void keyReleaseRotateClockwise();
  void keyPressRotateAntiClockwise();
  void keyReleaseRotateAntiClockwise();
  void keyPressUp();
  void keyReleaseUp();
  void keyPressShiftUp();
  void keyReleaseShiftUp();
  void keyPressDown();
  void keyReleaseDown();
  void keyPressShiftDown();
  void keyReleaseShiftDown();
  void keyPressLeft();
  void keyReleaseLeft();
  void keyPressShiftLeft();
  void keyReleaseShiftLeft();
  void keyPressRight();
  void keyReleaseRight();
  void keyPressShiftRight();
  void keyReleaseShiftRight();
  void keyPressDuplicate();
public slots:
  void addConnection(Component *pComponent);
  void removeConnection();
  void removeConnection(LineAnnotation *pConnection);
  void resetZoom();
  void zoomIn();
  void zoomOut();
  void selectAll();
  void addClassAnnotation();
  void showGraphicsViewProperties();
protected:
  virtual void dragMoveEvent(QDragMoveEvent *event);
  virtual void dropEvent(QDropEvent *event);
  virtual void drawBackground(QPainter *painter, const QRectF &rect);
  virtual void mousePressEvent(QMouseEvent *event);
  virtual void mouseMoveEvent(QMouseEvent *event);
  virtual void mouseReleaseEvent(QMouseEvent *event);
  virtual void mouseDoubleClickEvent(QMouseEvent *event);
  virtual void keyPressEvent(QKeyEvent *event);
  virtual void keyReleaseEvent(QKeyEvent *event);
  virtual void contextMenuEvent(QContextMenuEvent *event);
  virtual void resizeEvent(QResizeEvent *event);
};

class WelcomePageWidget : public QWidget
{
  Q_OBJECT
public:
  WelcomePageWidget(MainWindow *parent = 0);
  void addRecentFilesListItems();
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
private slots:
  void addLatestNewsListItems();
  void readLatestNewsXML(QNetworkReply *pNetworkReply);
  void openRecentFileItem(QListWidgetItem *pItem);
  void openLatestNewsItem(QListWidgetItem *pItem);
};

class LibraryTreeNode;
class ModelWidgetContainer;
class ModelicaTextWidget;
class ModelicaTextHighlighter;
class Label;
class ModelWidget : public QWidget
{
  Q_OBJECT
public:
  ModelWidget(bool newClass, bool extendsClass, LibraryTreeNode* pLibraryTreeNode, ModelWidgetContainer *pParent);
  LibraryTreeNode* getLibraryTreeNode();
  ModelWidgetContainer* getModelWidgetContainer();
  GraphicsView* getDiagramGraphicsView();
  GraphicsView* getIconGraphicsView();
  ModelicaTextWidget* getModelicaTextWidget();
  QToolButton* getIconViewToolButton();
  QToolButton* getDiagramViewToolButton();
  QToolButton* getModelicaTextViewToolButton();
  QToolButton* getDocumentationViewToolButton();
  void setModelFilePathLabel(QString path);
  Label* getCursorPositionLabel();
  void setModelModified();
  void updateParentModelsText(QString className);
  void getModelComponents(QString className, bool inheritedCycle = false);
  void getModelIconDiagramShapes(QString className, bool inheritedCycle = false);
  void getModelIconDiagramShapes(QString annotationString, StringHandler::ViewType viewType, bool inheritedCycle = false);
  void getModelConnections(QString className, bool inheritedCycle = false);
  Component* getConnectorComponent(Component *pConnectorComponent, QString connectorName);
  void refresh();
private:
  LibraryTreeNode *mpLibraryTreeNode;
  ModelWidgetContainer *mpModelWidgetContainer;
  GraphicsView *mpDiagramGraphicsView;
  GraphicsScene *mpDiagramGraphicsScene;
  GraphicsView *mpIconGraphicsView;
  GraphicsScene *mpIconGraphicsScene;
  ModelicaTextWidget *mpModelicaTextWidget;
  ModelicaTextHighlighter *mpModelicaTextHighlighter;
  QStatusBar *mpModelStatusBar;
  QButtonGroup *mpViewsButtonGroup;
  QToolButton *mpDiagramViewToolButton;
  QToolButton *mpIconViewToolButton;
  QToolButton *mpModelicaTextViewToolButton;
  QToolButton *mpDocumentationViewToolButton;
  Label *mpReadOnlyLabel;
  Label *mpModelicaTypeLabel;
  Label *mpViewTypeLabel;
  Label *mpModelFilePathLabel;
  Label *mpCursorPositionLabel;
  QToolButton *mpFileLockToolButton;
public slots:
  void makeFileWritAble();
  void showIconView(bool checked);
  void showDiagramView(bool checked);
  void showModelicaTextView(bool checked);
  void showDocumentationView();
  bool modelicaEditorTextChanged();
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
public slots:
  void openRecentModelWidget(QListWidgetItem *pItem);
  void currentModelWidgetChanged(QMdiSubWindow *pSubWindow);
  void saveModelWidget();
  void saveAsModelWidget();
  void printModel();
};

#endif // MODELWIDGETCONTAINER_H
