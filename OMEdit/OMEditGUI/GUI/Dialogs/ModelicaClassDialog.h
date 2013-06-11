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

#ifndef MODELICACLASSDIALOG_H
#define MODELICACLASSDIALOG_H

#include "MainWindow.h"

class MainWindow;
class Label;
class ModelicaClassDialog : public QDialog
{
  Q_OBJECT
public:
  ModelicaClassDialog(MainWindow *pParent);
  QComboBox* getParentClassComboBox();
private:
  MainWindow *mpMainWindow;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpRestrictionLabel;
  QComboBox *mpRestrictionComboBox;
  Label *mpParentPackageLabel;
  QComboBox *mpParentClassComboBox;
  QCheckBox *mpPartialCheckBox;
  QCheckBox *mpEncapsulatedCheckBox;
  QCheckBox *mpSaveContentsInOneFileCheckBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void createModelicaClass();
  void showHideSaveContentsInOneFileCheckBox(QString text);
};

class OpenModelicaFile : public QDialog
{
  Q_OBJECT
public:
  OpenModelicaFile(MainWindow *pParent);
private:
  MainWindow *mpMainWindow;
  QStringList mFileNames;
  Label *mpFileLabel;
  QLineEdit *mpFileTextBox;
  QPushButton *mpFileBrowseButton;
  Label *mpEncodingLabel;
  QComboBox *mpEncodingComboBox;
  Label *mpEncodingNoteLabel;
  QCheckBox *mpConvertAllFilesCheckBox;
  QPushButton *mpOpenWithEncodingButton;
  QPushButton *mpOpenAndConvertToUTF8Button;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  void convertModelicaFiles(QStringList filesAndDirectories, QString path, QTextCodec *codec);
  void convertModelicaFile(QString fileName, QTextCodec *codec);
private slots:
  void browseForFile();
  void openModelicaFiles(bool convertedToUTF8 = false);
  void convertModelicaFiles();
};

class RenameClassDialog : public QDialog
{
  Q_OBJECT
public:
  RenameClassDialog(QString name, QString nameStructure, MainWindow *parent);

  MainWindow *mpMainWindow;
private:
  QString mName;
  QString mNameStructure;
  Label *mpModelNameLabel;
  QLineEdit *mpModelNameTextBox;
  QPushButton *mpCancelButton;
  QPushButton *mpOkButton;
  QDialogButtonBox *mpButtonBox;
public slots:
  void renameClass();
};

class LibraryTreeNode;
class InformationDialog : public QDialog
{
public:
  InformationDialog(QString windowTitle, QString informationText, bool modelicaTextHighlighter = false, MainWindow *pMainWindow = 0);
};

class GraphicsView;
class GraphicsViewProperties : public QDialog
{
  Q_OBJECT
public:
  GraphicsViewProperties(GraphicsView *pGraphicsView);
private:
  GraphicsView *mpGraphicsView;
  QGroupBox *mpExtentGroupBox;
  Label *mpLeftLabel;
  QLineEdit *mpLeftTextBox;
  Label *mpBottomLabel;
  QLineEdit *mpBottomTextBox;
  Label *mpRightLabel;
  QLineEdit *mpRightTextBox;
  Label *mpTopLabel;
  QLineEdit *mpTopTextBox;
  QGroupBox *mpGridGroupBox;
  Label *mpHorizontalLabel;
  QLineEdit *mpHorizontalTextBox;
  Label *mpVerticalLabel;
  QLineEdit *mpVerticalTextBox;
  QGroupBox *mpComponentGroupBox;
  Label *mpScaleFactorLabel;
  QLineEdit *mpScaleFactorTextBox;
  QCheckBox *mpPreserveAspectRatioCheckBox;
  QCheckBox *mpCopyProperties;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void saveGraphicsViewProperties();
};

class SaveChangesDialog : public QDialog
{
  Q_OBJECT
public:
  SaveChangesDialog(MainWindow *pMainWindow);
  bool getUnsavedClasses();
private:
  MainWindow *mpMainWindow;
  Label *mpSaveChangesLabel;
  QListWidget *mpUnsavedClassesListWidget;
  QPushButton *mpYesButton;
  QPushButton *mpNoButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void saveChanges();
public slots:
  int exec();
};

#endif // MODELICACLASSDIALOG_H
