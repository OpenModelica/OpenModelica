/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef MODELICACLASSDIALOG_H
#define MODELICACLASSDIALOG_H

#include "MainWindow.h"

class MainWindow;
class Label;
class LibraryWidget;
class LibraryTreeProxyModel;

class LibraryBrowseDialog : public QDialog
{
  Q_OBJECT
public:
  LibraryBrowseDialog(QString title, QLineEdit *pLineEdit, LibraryWidget *pLibraryWidget);
private:
  QLineEdit *mpLineEdit;
  LibraryWidget *mpLibraryWidget;
  TreeSearchFilters *mpTreeSearchFilters;
  LibraryTreeProxyModel *mpLibraryTreeProxyModel;
  QTreeView *mpLibraryTreeView;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void searchClasses();
  void useModelicaClass();
};

class ModelicaClassDialog : public QDialog
{
  Q_OBJECT
public:
  ModelicaClassDialog(MainWindow *pParent);
  MainWindow* getMainWindow();
  QLineEdit* getParentClassTextBox();
private:
  MainWindow *mpMainWindow;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpSpecializationLabel;
  QComboBox *mpSpecializationComboBox;
  Label *mpExtendsClassLabel;
  QLineEdit *mpExtendsClassTextBox;
  QPushButton *mpExtendsClassBrowseButton;
  Label *mpParentClassLabel;
  QLineEdit *mpParentClassTextBox;
  QPushButton *mpParentClassBrowseButton;
  QCheckBox *mpPartialCheckBox;
  QCheckBox *mpEncapsulatedCheckBox;
  QCheckBox *mpSaveContentsInOneFileCheckBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void browseExtendsClass();
  void browseParentClass();
  void showHideSaveContentsInOneFileCheckBox(QString text);
  void createModelicaClass();
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
  QCheckBox *mpConvertAllFilesCheckBox;
  QPushButton *mpOpenWithEncodingButton;
  QPushButton *mpOpenAndConvertToUTF8Button;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  void convertModelicaFiles(QStringList filesAndDirectories, QString path, QTextCodec *pCodec);
  void convertModelicaFile(QString fileName, QTextCodec *pCodec);
private slots:
  void browseForFile();
  void openModelicaFiles(bool convertedToUTF8 = false);
  void convertModelicaFiles();
};

class ModelWidget;
class SaveAsClassDialog : public QDialog
{
  Q_OBJECT
public:
  SaveAsClassDialog(ModelWidget *pModelWidget, MainWindow *pParent);
  QComboBox* getParentClassComboBox();
private:
  ModelWidget *mpModelWidget;
  MainWindow *mpMainWindow;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpParentPackageLabel;
  QComboBox *mpParentClassComboBox;
  QCheckBox *mpSaveContentsInOneFileCheckBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void saveAsModelicaClass();
  void showHideSaveContentsInOneFileCheckBox(QString text);
};

class LibraryTreeItem;
class DuplicateClassDialog : public QDialog
{
  Q_OBJECT
public:
  DuplicateClassDialog(bool saveAs, LibraryTreeItem *pLibraryTreeItem, MainWindow *pMainWindow);
private:
  bool mSaveAs;
  LibraryTreeItem *mpLibraryTreeItem;
  MainWindow *mpMainWindow;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpPathLabel;
  QLineEdit *mpPathTextBox;
  QPushButton *mpPathBrowseButton;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
public slots:
  void browsePath();
  void duplicateClass();
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

class InformationDialog : public QWidget
{
private:
  MainWindow *mpMainWindow;
public:
  InformationDialog(QString windowTitle, QString informationText, bool modelicaTextHighlighter = false, MainWindow *pMainWindow = 0);
  void closeEvent(QCloseEvent *event);
};

class GraphicsView;
class GraphicsViewProperties : public QDialog
{
  Q_OBJECT
public:
  GraphicsViewProperties(GraphicsView *pGraphicsView);
private:
  GraphicsView *mpGraphicsView;
  QTabWidget *mpTabWidget;
  QGroupBox *mpExtentGroupBox;
  Label *mpLeftLabel;
  DoubleSpinBox *mpLeftSpinBox;
  Label *mpBottomLabel;
  DoubleSpinBox *mpBottomSpinBox;
  Label *mpRightLabel;
  DoubleSpinBox *mpRightSpinBox;
  Label *mpTopLabel;
  DoubleSpinBox *mpTopSpinBox;
  QGroupBox *mpGridGroupBox;
  Label *mpHorizontalLabel;
  DoubleSpinBox *mpHorizontalSpinBox;
  Label *mpVerticalLabel;
  DoubleSpinBox *mpVerticalSpinBox;
  QGroupBox *mpComponentGroupBox;
  Label *mpScaleFactorLabel;
  DoubleSpinBox *mpScaleFactorSpinBox;
  QCheckBox *mpPreserveAspectRatioCheckBox;
  QCheckBox *mpCopyProperties;
  Label *mpVersionLabel;
  QLineEdit *mpVersionTextBox;
  QGroupBox *mpUsesGroupBox;
  QList<QList<QString> > mUsesAnnotation;
  QTableWidget *mpUsesTableWidget;
  QToolButton *mpMoveUpButton;
  QToolButton *mpMoveDownButton;
  QToolButton *mpAddUsesAnnotationButton;
  QToolButton *mpRemoveUsesAnnotationButton;
  QDialogButtonBox *mpUsesButtonBox;
  Label *mpOMCFlagsLabel;
  QString mOMCFlags;
  QPlainTextEdit *mpOMCFlagsTextBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void moveUp();
  void moveDown();
  void addUsesAnnotation();
  void removeUsesAnnotation();
  void saveGraphicsViewProperties();
};

class SaveChangesDialog : public QDialog
{
  Q_OBJECT
public:
  SaveChangesDialog(MainWindow *pMainWindow);
  void listUnSavedClasses();
private:
  MainWindow *mpMainWindow;
  Label *mpSaveChangesLabel;
  QListWidget *mpUnsavedClassesListWidget;
  QPushButton *mpYesButton;
  QPushButton *mpNoButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;

  void listUnSavedClasses(LibraryTreeItem *pLibraryTreeItem);
private slots:
  void saveChanges();
public slots:
  int exec();
};

class ExportFigaroDialog : public QDialog
{
  Q_OBJECT
public:
  ExportFigaroDialog(MainWindow *pMainWindow, LibraryTreeItem *pLibraryTreeItem);
private:
  MainWindow *mpMainWindow;
  LibraryTreeItem *mpLibraryTreeItem;
  Label *mpFigaroModeLabel;
  QComboBox *mpFigaroModeComboBox;
  Label *mpWorkingDirectoryLabel;
  QLineEdit *mpWorkingDirectoryTextBox;
  QPushButton *mpWorkingDirectoryBrowseButton;
  QPushButton *mpExportFigaroButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
public slots:
  void browseWorkingDirectory();
  void exportModelFigaro();
};

class CreateNewItemDialog : public QDialog
{
  Q_OBJECT
public:
  CreateNewItemDialog(QString path, bool isCreateFile, MainWindow *pMainWindow);
private:
  QString mPath;
  bool mIsCreateFile;
  MainWindow *mpMainWindow;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpPathLabel;
  QLineEdit *mpPathTextBox;
  QPushButton *mpPathBrowseButton;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void browsePath();
  void createNewFileOrFolder();
};

class RenameItemDialog : public QDialog
{
  Q_OBJECT
public:
  RenameItemDialog(QString path, bool isCreateFile, MainWindow *pMainWindow);
private:
  QString mPath;
  bool mIsCreateFile;
  MainWindow *mpMainWindow;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;

  void updateChildrenPath(LibraryTreeItem *pLibraryTreeItem);
private slots:
  void renameFileOrFolder();
};

#endif // MODELICACLASSDIALOG_H
