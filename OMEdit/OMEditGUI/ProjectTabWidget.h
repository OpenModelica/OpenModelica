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

/*
 * RCS: $Id$
 */

#ifndef PROJECTTABWIDGET_H
#define PROJECTTABWIDGET_H

#include <QGraphicsView>
#include <QGraphicsScene>
#include <QTabWidget>
#include <map>

#include "Component.h"
#include "ConnectorWidget.h"
#include "StringHandler.h"
#include "ModelicaEditor.h"

class ProjectTab;
class Component;
class Connector;
class LineAnnotation;
class PolygonAnnotation;
class RectangleAnnotation;
class EllipseAnnotation;
class TextAnnotation;
class TextWidget;
class BitmapAnnotation;
class BitmapWidget;

class GraphicsScene : public QGraphicsScene
{
  Q_OBJECT
public:
  GraphicsScene(int iconType, ProjectTab *parent);
  ProjectTab *mpParentProjectTab;
  int mIconType;
};

class GraphicsView : public QGraphicsView
{
  Q_OBJECT
private:
  Connector *mpConnector;
  void createActions();
  void createLineShape(QPointF point);
  void createPolygonShape(QPointF point);
  void createRectangleShape(QPointF point);
  void createEllipseShape(QPointF point);
  void createTextShape(QPointF point);
  void createBitmapShape(QPointF point);
public:
  GraphicsView(int iconType, ProjectTab *parent);
  void addComponentoView(QString name, QString className, QPointF point, bool isConnector = false,
                         bool addObject = true, bool diagram = false);
  void addComponentObject(Component *icon);
  void deleteComponentObject(Component *component, bool update = true);
  void deleteAllComponentObjects();
  Component* getComponentObject(QString componentName);
  QString getUniqueComponentName(QString iconName, int number = 1);
  bool checkComponentName(QString iconName);
  void addShapeObject(ShapeAnnotation *shape);
  void deleteShapeObject(ShapeAnnotation *shape);
  void deleteAllShapesObject();
  void removeAllConnectors();
  void createConnection(Component *pStartComponent, QString startIconCompName, Component *pComponent, QString endIconCompName);
  void deleteConnection(QString startIconCompName, QString endIconCompName, bool update = true);
  void addConnectorForArray(Component *pStartComponent,Component *pEndComponent ,int startindex, int endindex);
  QRectF iconBoundingRect();
  QList<Component*> mComponentsList;
  QList<ShapeAnnotation*> mShapesList;
  LineAnnotation *mpLineShape;
  PolygonAnnotation *mpPolygonShape;
  RectangleAnnotation *mpRectangleShape;
  EllipseAnnotation *mpEllipseShape;
  TextAnnotation *mpTextShape;
  TextWidget *mpTextWidget;
  BitmapAnnotation *mpBitmapShape;
  BitmapWidget *mpBitmapWidget;

  int mIconType;
  bool mIsCreatingConnector;
  bool mIsMovingComponents;
  bool mIsCreatingLine;
  bool mIsCreatingPolygon;
  bool mIsCreatingRectangle;
  bool mIsCreatingEllipse;
  bool mIsCreatingText;
  bool mIsCreatingBitmap;
  bool mCustomScale;
  bool mSkipBackground; /* Do not draw the background rectangle */
  QVector<Connector*> mConnectorsVector;
  ProjectTab *mpParentProjectTab;
  QAction *mpCancelConnectionAction;
  QAction *mpRotateIconAction;
  QAction *mpHorizontalFlipAction;
  QAction *mpVerticalFlipAction;
  QAction *mpRotateAntiIconAction;
  QAction *mpResetRotation;
  QAction *mpDeleteIconAction;
signals:
  void keyPressDelete();
  void keyPressUp();
  void keyPressDown();
  void keyPressLeft();
  void keyPressRight();
  void keyPressRotateClockwise();
  void keyPressRotateAntiClockwise();
  void currentChange(int index);
public slots:
  void addConnector(Component *pComponent);
  void removeConnector();
  void removeConnector(Connector* pConnector, bool update = true);
  void resetZoom();
  void zoomIn();
  void zoomOut();
  void showGridLines(bool showLines);
  void selectAll();
  void addClassAnnotation(bool update = true);
protected:
  virtual void dragMoveEvent(QDragMoveEvent *event);
  virtual void dropEvent(QDropEvent *event);
  virtual void drawBackground(QPainter *painter, const QRectF &rect);
  virtual void mouseMoveEvent(QMouseEvent *event);
  virtual void mousePressEvent(QMouseEvent *event);
  virtual void mouseReleaseEvent(QMouseEvent *event);
  virtual void mouseDoubleClickEvent(QMouseEvent *event);
  virtual void keyPressEvent(QKeyEvent *event);
  virtual void keyReleaseEvent(QKeyEvent *event);
  virtual void contextMenuEvent(QContextMenuEvent *event);
  virtual void resizeEvent(QResizeEvent *event);
};

class ProjectTabWidget; //Forward declaration
class ModelicaEditor;
class ModelicaTextHighlighter;
class ProjectTab : public QWidget
{
  Q_OBJECT
private:
  ModelicaTextHighlighter *mpModelicaTextHighlighter;
  QStatusBar *mpProjectStatusBar;
  QButtonGroup *mpViewsButtonGroup;
  QToolButton *mpIconToolButton;
  QToolButton *mpDiagramToolButton;
  QToolButton *mpModelicaTextToolButton;
  QToolButton *mpDocumentationViewToolButton;
  QLabel *mpReadOnlyLabel;
  QLabel *mpModelicaTypeLabel;
  QLabel *mpViewTypeLabel;
  QLabel *mpModelFilePathLabel;
  bool mReadOnly;
  bool mIsChild;
public:
  ProjectTab(QString name, QString nameStructure, int modelicaType, int iconType, bool readOnly, bool isChild, bool openMode, ProjectTabWidget *parent = 0);
  ~ProjectTab();
  void updateTabName(QString name, QString nameStructure);
  void updateModel(QString name);
  bool loadModelFromText(QString name);
  bool loadRootModel(QString model);
  bool loadSubModel(QString model);
  void getModelComponents(QString modelName);
  void getModelConnections();
  void getModelShapes(QString annotationString, int type);
  void getModelIconDiagram();
  void setReadOnly(bool readOnly);
  bool isReadOnly();
  void setIsChild(bool isChild);
  bool isChild();
  void setModelFilePathLabel(QString filePath);
  QString getModelicaTypeLabel();
  QToolButton* getModelicaTextToolButton();

  ProjectTabWidget *mpParentProjectTabWidget;
  GraphicsView *mpDiagramGraphicsView;
  GraphicsScene *mpDiagramGraphicsScene;
  GraphicsView *mpIconGraphicsView;
  GraphicsScene *mpIconGraphicsScene;
  QWidget *mpModelicaEditorWidget;
  ModelicaEditor *mpModelicaEditor;
  QString mModelFileName;
  QString mModelName;
  QString mModelNameStructure;
  int mModelicaType;
  int mIconType;
  bool mIsSaved;
  int mTabPosition;
  bool mOpenMode;
public slots:
  void showIconView(bool checked);
  void showDiagramView(bool checked);
  void showModelicaTextView(bool checked);
  void showDocumentationView();
  bool modelicaEditorTextChanged();
};

class WelcomePageWidget : public QWidget
{
  Q_OBJECT
public:
  WelcomePageWidget(MainWindow *parent = 0);
  void addListItems();

  MainWindow *mpParentMainWindow;
private:
  QFrame *mpMainFrame;
  QFrame *mpTopFrame;
  QLabel *mpPixmapLabel;
  QLabel *mpHeadingLabel;
  QFrame *mpMiddleFrame;
  QLabel *mpRecentFilesLabel;
  QLabel *mpNoRecentFileLabel;
  QListWidget *mpRecentItemsList;
  QFrame *mpBottomFrame;
  QPushButton *mpCreateModelButton;
  QPushButton *mpOpenModelButton;
protected:
  virtual void paintEvent(QPaintEvent *event);
private slots:
  void openRecentItem(QListWidgetItem *item);
};

class MainWindow;
class LibraryTreeNode;
class ProjectTabWidget : public QTabWidget
{
  Q_OBJECT
public:
  ProjectTabWidget(MainWindow *parent);
  ~ProjectTabWidget();
  ProjectTab* getCurrentTab();
  ProjectTab* getProjectTab(QString name);
  ProjectTab* getTabByName(QString name);
  ProjectTab* getRemovedTabByName(QString name);

  int addTab(ProjectTab *tab, QString tabName);
  void removeTab(int index);
  void disableTabs(bool disable);
  void setSourceFile(QString modelName, QString modelFileName);
  void saveChilds(ProjectTab *pProjectTab);

  MainWindow *mpParentMainWindow;
  bool mShowLines;
  bool mToolBarEnabled;
  QList<ProjectTab*> mRemovedTabsList;
signals:
  void tabAdded();
  void tabRemoved();

  void modelSaved(QString modelName, QString filePath);
public slots:
  void addProjectTab(ProjectTab *projectTab, QString modelName, QString modelStructure);
  void addNewProjectTab(QString modelName, QString modelStructure, int modelicaType);
  void addDiagramViewTab(QTreeWidgetItem *item, int column);
  void saveProjectTab();
  void saveProjectTabAs();
  void saveProjectTab(int index, bool saveAs);
  bool saveModel(bool saveAs);
  bool closeProjectTab(int index);
  bool closeAllProjectTabs();
  void openFile(QString fileName = QString());
  void openModel(QString modelText);
  void resetZoom();
  void zoomIn();
  void zoomOut();
  void updateTabIndexes();
  void enableProjectToolbar();
  void disableProjectToolbar();
  void tabChanged();
protected:
  virtual void keyPressEvent(QKeyEvent *event);
};

#endif // PROJECTTABWIDGET_H
