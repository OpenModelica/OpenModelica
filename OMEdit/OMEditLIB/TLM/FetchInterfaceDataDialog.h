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

#ifndef FETCHINTERFACEDATADIALOG_H
#define FETCHINTERFACEDATADIALOG_H

#include "Util/StringHandler.h"

#include <QDialog>
#include <QProgressBar>
#include <QPlainTextEdit>
#include <QListWidget>
#include <QDialogButtonBox>

class LibraryTreeItem;
class Label;
class FetchInterfaceDataThread;
class ModelWidget;
class LineAnnotation;

class FetchInterfaceDataDialog : public QDialog
{
  Q_OBJECT
public:
  FetchInterfaceDataDialog(LibraryTreeItem *pLibraryTreeItem, QString singleModel = QString(), QWidget *pParent = 0);
  LibraryTreeItem* getLibraryTreeItem() {return mpLibraryTreeItem;}
  QString getSingleModel() {return mSingleModel;}
private:
  LibraryTreeItem *mpLibraryTreeItem;
  QString mSingleModel;
  Label *mpProgressLabel;
  QProgressBar *mpProgressBar;
  QPushButton *mpCancelButton;
  QPushButton *mpFetchAgainButton;
  Label *mpOutputLabel;
  QPlainTextEdit *mpOutputTextBox;
  FetchInterfaceDataThread *mpFetchInterfaceDataThread;
public slots:
  void cancelFetchingInterfaceData();
  void fetchAgainInterfaceData();
  void managerProcessStarted();
  void writeManagerOutput(QString output, StringHandler::SimulationMessageType type);
  void managerProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
  void reject();
signals:
  void readInterfaceData(LibraryTreeItem *pLibraryTreeItem);
};

class AlignInterfacesDialog : public QDialog
{
  Q_OBJECT
public:
  AlignInterfacesDialog(ModelWidget *pModelWidget, LineAnnotation *pConnectionLineAnnotation = 0);
private:
  ModelWidget *mpModelWidget;
  Label *mpAlignInterfacesHeading;
  QFrame *mpHorizontalLine;
  QListWidget *mpInterfaceListWidget;
  QListWidget *mpToInterfaceListWidget;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
public slots:
  void alignInterfaces();
};

#endif // FETCHINTERFACEDATADIALOG_H
