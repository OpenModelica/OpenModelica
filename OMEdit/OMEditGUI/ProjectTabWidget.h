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
 *
 */

/*
 * HopsanGUI
 * Fluid and Mechatronic Systems, Department of Management and Engineering, Linkoping University
 * Main Authors 2009-2010:  Robert Braun, Bjorn Eriksson, Peter Nordin
 * Contributors 2009-2010:  Mikael Axin, Alessandro Dell'Amico, Karl Pettersson, Ingo Staack
 */

#ifndef PROJECTTABWIDGET_H
#define PROJECTTABWIDGET_H

#include <QGraphicsView>
#include <QGraphicsScene>
#include <QTabWidget>
#include <map>

#include "IconAnnotation.h"
#include "ComponentAnnotation.h"
#include "ConnectorWidget.h"
#include "StringHandler.h"
#include "ModelicaEditor.h"

class ProjectTab;
class IconAnnotation;
class ComponentAnnotation;
class Connector;

class GraphicsScene : public QGraphicsScene
{
    Q_OBJECT
public:
    GraphicsScene(ProjectTab *parent = 0);
    ProjectTab *mpParentProjectTab;
};

class GraphicsView : public QGraphicsView
{
    Q_OBJECT
private:
    Connector *mpConnector;
    QList<IconAnnotation*> mIconsList;
    void createActions();
    void createMenus();
public:
    GraphicsView(ProjectTab *parent = 0);
    Connector *getConnector();
    void addIconObject(IconAnnotation* icon);
    void deleteIconObject(IconAnnotation* icon);
    QString getUniqueIconName(QString iconName, int number = 0);
    bool checkIconName(QString iconName);

    bool mIsCreatingConnector;
    QVector<Connector *> mConnectorVector;
    ProjectTab *mpParentProjectTab;
    QAction *mpCancelConnectionAction;
    QAction *mpRotateIconAction;
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
public slots:
    void addConnector(ComponentAnnotation *pComponent);
    void removeConnector();
    void removeConnector(Connector* pConnector);
    void resetZoom();
    void zoomIn();
    void zoomOut();
    void showGridLines(bool showLines);
    void selectAll();
protected:
    virtual void dragMoveEvent(QDragMoveEvent *event);
    virtual void dropEvent(QDropEvent *event);
    virtual void drawBackground(QPainter *painter, const QRectF &rect);
    virtual void mouseMoveEvent(QMouseEvent *event);
    virtual void mousePressEvent(QMouseEvent *event);
    virtual void keyPressEvent(QKeyEvent *event);
    virtual void keyReleaseEvent(QKeyEvent *event);
    virtual void contextMenuEvent(QContextMenuEvent *event);
};

class GraphicsViewScroll : public QScrollArea
{
public:
    GraphicsViewScroll(GraphicsView *graphicsView, QWidget *parent = 0);

    GraphicsView *mpGraphicsView;
protected:
    virtual void scrollContentsBy(int dx, int dy);
};

class ProjectTabWidget; //Forward declaration
class ModelicaEditor;
class ProjectTab : public QWidget
{
    Q_OBJECT
private:
    QPushButton *mpModelicaModelButton;
    QPushButton *mpModelicaTextButton;
    ModelicaEditor *mpModelicaEditor;
    GraphicsViewScroll *mpViewScrollArea;
public:
    ProjectTab(ProjectTabWidget *parent = 0);
    void updateTabName(QString name, QString nameStructure);

    ProjectTabWidget *mpParentProjectTabWidget;
    GraphicsView *mpGraphicsView;
    GraphicsScene *mpGraphicsScene;
    QString mModelFileName;
    QString mModelName;
    QString mModelNameStructure;
    bool mIsSaved;
    int mTabPosition;
public slots:
    void hasChanged();
    void showModelicaModel();
    void showModelicaText();
    void ModelicaEditorTextChanged();
};

class MainWindow;
class ProjectTabWidget : public QTabWidget
{
    Q_OBJECT
public:
    ProjectTabWidget(MainWindow *parent = 0);
    ProjectTab* getCurrentTab();
    ProjectTab* getTabByName(QString name);
    void removeTab(int index);

    MainWindow *mpParentMainWindow;
    bool mShowLines;
public slots:
    void addProjectTab(ProjectTab *projectTab, QString tabName="Untitled");
    void addNewProjectTab(QString tabName, QString modelStructure);
    void saveProjectTab();
    void saveProjectTabAs();
    void saveProjectTab(int index, bool saveAs);
    bool saveModel(bool saveAs);
    bool closeProjectTab(int index);
    bool closeAllProjectTabs();
    void loadModel();
    void resetZoom();
    void zoomIn();
    void zoomOut();
};

#endif // PROJECTTABWIDGET_H
