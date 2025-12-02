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

#include <QDialog>
#include <QLineEdit>
#include <QTreeView>
#include <QPushButton>
#include <QDialogButtonBox>
#include <QComboBox>
#include <QCheckBox>
#include <QGroupBox>
#include <QTableWidget>
#include <QPlainTextEdit>
#include <QListWidget>
#include <QRegExp>
#include <QToolButton>
#include <QTreeWidget>
#include <QTextCodec>

class Label;
class LibraryWidget;
class LibraryTreeProxyModel;
class TreeSearchFilters;
class DoubleSpinBox;

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

  void findAndSelectLibraryTreeItem(const QRegExp &regExp);
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  void findAndSelectLibraryTreeItem(const QRegularExpression &regExp);
#endif
private slots:
  void searchClasses();
  void useModelicaClass();
};

class ModelicaClassDialog : public QDialog
{
  Q_OBJECT
public:
  ModelicaClassDialog(QWidget *pParent = 0);
  QLineEdit* getParentClassTextBox() {return mpParentClassTextBox;}
private:
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
  QCheckBox *mpStateCheckBox;
  QCheckBox *mpSaveContentsInOneFileCheckBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void browseExtendsClass();
  void browseParentClass();
  void showHideSaveContentsInOneFileCheckBox(int index);
  void createModelicaClass();
};

class OpenModelicaFile : public QDialog
{
  Q_OBJECT
public:
  OpenModelicaFile(QWidget *pParent = 0);
private:
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
  SaveAsClassDialog(ModelWidget *pModelWidget, QWidget *pParent = 0);
  QComboBox* getParentClassComboBox() {return mpParentClassComboBox;}
private:
  ModelWidget *mpModelWidget;
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
  enum FileType {
    OneFile,
    Directory,
    Directories,
    KeepStructure
  };
  DuplicateClassDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent = 0);
private:
  LibraryTreeItem *mpLibraryTreeItem;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpPathLabel;
  QLineEdit *mpPathTextBox;
  QPushButton *mpPathBrowseButton;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;

  FileType selectFileType(LibraryTreeItem *pLibraryTreeItem, LibraryTreeItem *pParentLibraryTreeItem = 0);
  void setSaveContentsTypeAsFolderStructure(LibraryTreeItem *pLibraryTreeItem);

  void duplicateClassHelper(LibraryTreeItem *pDestinationLibraryTreeItem, LibraryTreeItem *pSourceLibraryTreeItem, FileType fileType);
  void syncDuplicatedModelWithOMC(LibraryTreeItem *pLibraryTreeItem);
  void folderToOneFilePackage(LibraryTreeItem *pDestinationLibraryTreeItem, LibraryTreeItem *pSourceLibraryTreeItem, QString *classText);
  void insertClassInOneFilePackage(LibraryTreeItem *pLibraryTreeItem);
private slots:
  void browsePath();
  void duplicateClass();
};

class RenameClassDialog : public QDialog
{
  Q_OBJECT
public:
  RenameClassDialog(QString name, QString nameStructure, QWidget *pParent = 0);
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

class SaveTotalFileDialog : public QDialog
{
  Q_OBJECT
public:
  SaveTotalFileDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent = 0);
private:
  LibraryTreeItem *mpLibraryTreeItem;
  QCheckBox *mpObfuscateOutputCheckBox;
  QCheckBox *mpStripAnnotationsCheckBox;
  QCheckBox *mpStripCommentsCheckBox;
  QCheckBox *mpUseSimplifiedHeuristic;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void saveTotalModel();
};

class InformationDialog : public QWidget
{
  Q_OBJECT
public:
  InformationDialog(QString windowTitle, QString informationText, bool modelicaTextHighlighter = false, QWidget *pParent = 0);
  void closeEvent(QCloseEvent *event) override;
protected:
  virtual void keyPressEvent(QKeyEvent *event) override;
};

class ConvertClassUsesAnnotationDialog : public QDialog
{
  Q_OBJECT
public:
  ConvertClassUsesAnnotationDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent = 0);
private:
  LibraryTreeItem *mpLibraryTreeItem;
  QTreeWidget *mpUsesLibrariesTreeWidget;
  Label *mpProgressLabel;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  void updateClassTextRecursive(LibraryTreeItem *pLibraryTreeItem);
private slots:
  void convert();
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
  Label *mpPreserveAspectRatioLabel;
  QComboBox *mpPreserveAspectRatioComboBox;
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
  SaveChangesDialog(QWidget *pParent = 0);
  void listUnSavedClasses();
private:
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
  ExportFigaroDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent = 0);
private:
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
  CreateNewItemDialog(QString path, bool isCreateFile, QString extension, QWidget *pParent = 0);
private:
  QString mPath;
  bool mIsCreateFile;
  QString mExtension;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpPathLabel;
  QLineEdit *mpPathTextBox;
  QPushButton *mpPathBrowseButton;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;

  QString getHeading() const;
private slots:
  void browsePath();
  void createNewFileOrFolder();
};

class RenameItemDialog : public QDialog
{
  Q_OBJECT
public:
  RenameItemDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent = 0);
private:
  LibraryTreeItem *mpLibraryTreeItem;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;

  void updateChildrenPath(LibraryTreeItem *pLibraryTreeItem);
private slots:
  void renameItem();
};

class ComponentNameDialog : public QDialog
{
  Q_OBJECT
public:
  ComponentNameDialog(const QString &nameStructure, QString name, GraphicsView *pGraphicsView, QWidget *pParent = 0);
  QString getComponentName() {return mpNameTextBox->text();}
private:
  GraphicsView *mpGraphicsView;
  QString mNameStructure;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  QCheckBox *mpDontShowThisMessageAgainCheckBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void updateComponentName();
};

#endif // MODELICACLASSDIALOG_H
