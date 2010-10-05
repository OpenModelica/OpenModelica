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
public:
    GraphicsView(ProjectTab *parent = 0);
    Connector *getConnector();
    void addIconObject(IconAnnotation* icon);
    void deleteIconObject(IconAnnotation* icon);
    QString checkIconName(QString iconName, int number = 0);

    bool mIsCreatingConnector;
    QVector<Connector *> mConnectorVector;
    ProjectTab *mpParentProjectTab;
    QColor mBackgroundColor;
signals:
    void keyPressDelete();
    void keyPressUp();
    void keyPressDown();
    void keyPressLeft();
    void keyPressRight();
public slots:
    void addConnector(ComponentAnnotation *pComponent);
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
};

class ProjectTabWidget; //Forward declaration
class ProjectTab : public QWidget
{
    Q_OBJECT
private:
    QPushButton *mpModelicaModelButton;
    QPushButton *mpModelicaTextButton;
    QTextEdit *mpEditBox;
public:
    ProjectTab(ProjectTabWidget *parent = 0);
    ProjectTabWidget *mpParentProjectTabWidget;
    GraphicsView *mpGraphicsView;
    GraphicsScene *mpGraphicsScene;
    QString mModelFileName;
    QString mModelFileStrucrure;
public slots:
    void showModelicaModel();
    void showModelicaText();
};

class MainWindow;
class ProjectTabWidget : public QTabWidget
{
    Q_OBJECT
private:
    QList<IconAnnotation*> mGlobalIconsList;
public:
    ProjectTabWidget(MainWindow *parent = 0);
    ProjectTab *getCurrentTab();
    void addGlobalIconObject(IconAnnotation* icon);
    IconAnnotation* getGlobalIconObject(QString className);

    MainWindow *mpParentMainWindow;
    bool mShowLines;
public slots:
    void addProjectTab(ProjectTab *projectTab, QString tabName="Untitled");
    void addNewProjectTab(QString tabName, QString modelStructure);
    bool closeProjectTab(int index);
    bool closeAllProjectTabs();
    void loadModel();
    void resetZoom();
    void zoomIn();
    void zoomOut();
};

#endif // PROJECTTABWIDGET_H
