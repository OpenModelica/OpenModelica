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
#include "graphWindow.h"

class MainWindow;

class PlotWidget : public QWidget
{
    Q_OBJECT
public:
    PlotWidget(MainWindow *pParent = 0);

    MainWindow *mpParentMainWindow;

    void readPlotVariables(QString fileName);
    void addPlotVariablestoTree(QString fileName, QList<QString> plotVariablesList);
    void addInGraphWindowMap(QString key, GraphWindow *graphWindow);
    void deleteInGraphWindowMap(QString key);
    GraphWindow* getGraphWindow(QString key);
private:
    QLabel *mpPlotTypesLabel;
    QComboBox *mpPlotTypesCombo;
    QTreeWidget *mpPlotVariablesTree;
    QVBoxLayout *mpVerticalLayout;
    QMap<QString, GraphWindow*> mGraphWindowsMap;
public slots:
    void plotVariables(QTreeWidgetItem *item, int column);
    void visualize(QString value);
protected:
    void contextMenuEvent(QContextMenuEvent *event);
};

#endif // PLOTWIDGET_H
