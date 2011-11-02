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

#ifndef PLOTWIDGET_H
#define PLOTWIDGET_H

#include "mainwindow.h"

class MainWindow;

class PlotTreeItem : public QTreeWidgetItem
{
public:
    PlotTreeItem(QString text, QString parentName, QString nameStructure, QString fileName, QString tooltip, QTreeWidget *parent = 0);
    void setName(QString name);
    QString getName();
    void setParentName(QString parentName);
    QString getParentName();
    void setNameStructure(QString nameStructure);
    QString getNameStructure();
    void setFileName(QString fileName);
    QString getFileName();
    QString getPlotVariable();
private:
    QString mName;
    QString mParentName;
    QString mNameStructure;
    QString mFileName;
};

class PlotWidget;

class PlotTree : public QTreeWidget
{
    Q_OBJECT
public:
    PlotTree(PlotWidget *pParent);
    PlotTreeItem* getTreeItem(QString name);
    PlotWidget* getPlotWidget();
private:
    PlotWidget *mpParentPlotWidget;
private slots:
    void expandNode(QTreeWidgetItem *item);
    void collapseNode(QTreeWidgetItem *item);
};

class PlotWidget : public QWidget
{
    Q_OBJECT
public:
    PlotWidget(MainWindow *pParent);
    void createActions();
    QList<QString> readPlotVariables(QString fileName);
    void addPlotVariablestoTree(QString fileName, QList<QString> plotVariablesList);
    void addPlotVariableToTree(QString fileName, QString parentStructure, QString childName, QString fullStructure = QString(), bool derivative = false);

    MainWindow *mpParentMainWindow;
private:
    PlotTree *mpPlotTree;
    QVBoxLayout *mpVerticalLayout;
    QList<QStringList> mPlotParametricVariables;
    QString mFileName;
    PlotTreeItem *mSelectedPlotTreeItem;
    QAction *mpDeleteResultAction;
signals:
    void removePlotFile(PlotTreeItem *item);
public slots:
    void plotVariables(QTreeWidgetItem *item, int column);
    void updatePlotVariablesTree(QMdiSubWindow *window);
    void showContextMenu(QPoint point);
    void deletePlotTreeItem();
};

#endif // PLOTWIDGET_H
