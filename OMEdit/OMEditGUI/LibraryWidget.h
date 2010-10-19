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

#ifndef LIBRARYWIDGET_H
#define LIBRARYWIDGET_H

#include <string>
#include <map>
#include <QListWidget>
#include <QStringList>
#include <QTreeWidget>
#include <QVBoxLayout>
#include <QListWidgetItem>
#include <QStringList>

#include "mainwindow.h"
#include "StringHandler.h"
#include "Components.h"

class MainWindow;
class OMCProxy;

class LibraryWidget : public QWidget
{
    Q_OBJECT

public:
    QTreeWidget *mpProjectsTree;
    //Member functions
    LibraryWidget(MainWindow *parent = 0);
    void addModelicaStandardLibrary();
    void loadModelicaLibraryHierarchy(QString value, QString prefixStr=QString());
    void addClass(QString className, QString parentClassName=QString(), QString parentStructure=QString(), bool hasIcon=false);
    void loadModel(QString path);
    void addModelNode(QString name, QString parentName=QString(), QString parentStructure=QString());
    void addModelFiles(QString fileName, QString parentFileName=QString(), QString parentStructure=QString());
    void removeProject();
    bool isTreeItemLoaded(QTreeWidgetItem *item);
    void addGlobalIconObject(IconAnnotation* icon);
    IconAnnotation* getGlobalIconObject(QString className);
    void updateNodeText(QString text, QString textStructure);
    void createActions();

    QTreeWidgetItem *mSelectedItem;
private slots:
    void showLib(QTreeWidgetItem *item);
    void openProjectTab(QTreeWidgetItem *item, int column);
    void showContextMenu(QPoint point);
    void renameClass();
    void checkClass();
    void deleteClass();
private:
    //Member variables
    MainWindow *mpParentMainWindow;
    QTreeWidget *mpTree;
    QVBoxLayout *mpGrid;
    QList<QString> mTreeList;
    QList<IconAnnotation*> mGlobalIconsList;

    QAction *mRenameAction;
    QAction *mCheckModelAction;
    QAction *mDeleteAction;
};

#endif // LIBRARYWIDGET_H
