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

#ifndef TRANSFORMATIONSWIDGET_H
#define TRANSFORMATIONSWIDGET_H

#include "MainWindow.h"
#include "OMDumpXML.h"

class MainWindow;
class TransformationsWidget : public QWidget
{
  Q_OBJECT
public:
  TransformationsWidget(MainWindow *pMainWindow);
  MainWindow* getMainWindow() {return mpMainWindow;}
  MyHandler* getInfoXMLFileHandler() {return mpInfoXMLFileHandler;}
  void showTransformations(QString fileName);
private:
  MainWindow *mpMainWindow;
  MyHandler *mpInfoXMLFileHandler;
  QToolButton *mpPreviousToolButton;
  QToolButton *mpNextToolButton;
  Label *mpInfoXMLFilePathLabel;
  QStackedWidget *mpPagesWidget;
};

class TransformationPage : public QWidget
{
  Q_OBJECT
public:
  TransformationPage(TransformationsWidget *pTransformationsWidget);
  void initialize();
private:
  TransformationsWidget *mpTransformationsWidget;
  QTreeWidget *mpVariablesTreeWidget;
  QTreeWidget *mpTypesTreeWidget;
  QTreeWidget *mpDefinedInTreeWidget;
  QTreeWidget *mpUsedInTreeWidget;
  void fetchTypes(OMVariable &variable);
  void fetchDefinedInEquations(OMVariable &variable);
  void fetchUsedInEquations(OMVariable &variable);
public slots:
  void fetchTypesDefinedInAndUsedIn(QTreeWidgetItem *pVariableTreeItem, int column);
};

#endif // TRANSFORMATIONSWIDGET_H
