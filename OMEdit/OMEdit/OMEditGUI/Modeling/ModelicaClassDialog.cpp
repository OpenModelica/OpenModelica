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

#include <limits>

#include "Modeling/ModelicaClassDialog.h"
#include "MainWindow.h"
#include "Options/OptionsDialog.h"
#include "MessagesWidget.h"
#include "Util/StringHandler.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Commands.h"
#include "Modeling/ItemDelegate.h"

#include <QApplication>
#include <QMessageBox>
#include <QCompleter>
#include <QHeaderView>

LibraryBrowseDialog::LibraryBrowseDialog(QString title, QLineEdit *pLineEdit, LibraryWidget *pLibraryWidget)
  : QDialog(0)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(title));
  resize(250, 500);
  mpLineEdit = pLineEdit;
  mpLibraryWidget = pLibraryWidget;
  mpTreeSearchFilters = new TreeSearchFilters(this);
  mpTreeSearchFilters->getFilterTextBox()->setPlaceholderText(Helper::filterClasses);
  connect(mpTreeSearchFilters->getFilterTextBox(), SIGNAL(returnPressed()), SLOT(searchClasses()));
  connect(mpTreeSearchFilters->getFilterTextBox(), SIGNAL(textEdited(QString)), SLOT(searchClasses()));
  connect(mpTreeSearchFilters->getCaseSensitiveCheckBox(), SIGNAL(toggled(bool)), SLOT(searchClasses()));
  connect(mpTreeSearchFilters->getSyntaxComboBox(), SIGNAL(currentIndexChanged(int)), SLOT(searchClasses()));
  // create the tree
  mpLibraryTreeProxyModel = new LibraryTreeProxyModel(mpLibraryWidget, true);
  mpLibraryTreeProxyModel->setDynamicSortFilter(true);
  mpLibraryTreeProxyModel->setSourceModel(mpLibraryWidget->getLibraryTreeModel());
  mpLibraryTreeView = new QTreeView;
  mpLibraryTreeView->setItemDelegate(new ItemDelegate(mpLibraryTreeView));
  mpLibraryTreeView->setTextElideMode(Qt::ElideMiddle);
  mpLibraryTreeView->setIndentation(Helper::treeIndentation);
  mpLibraryTreeView->setDragEnabled(true);
  int libraryIconSize = OptionsDialog::instance()->getGeneralSettingsPage()->getLibraryIconSizeSpinBox()->value();
  mpLibraryTreeView->setIconSize(QSize(libraryIconSize, libraryIconSize));
  mpLibraryTreeView->setContextMenuPolicy(Qt::CustomContextMenu);
  mpLibraryTreeView->setExpandsOnDoubleClick(false);
  mpLibraryTreeView->setModel(mpLibraryTreeProxyModel);
  connect(mpTreeSearchFilters->getExpandAllButton(), SIGNAL(clicked()), mpLibraryTreeView, SLOT(expandAll()));
  connect(mpTreeSearchFilters->getCollapseAllButton(), SIGNAL(clicked()), mpLibraryTreeView, SLOT(collapseAll()));
  connect(mpLibraryTreeView, SIGNAL(doubleClicked(QModelIndex)), SLOT(useModelicaClass()));
  // try to automatically select of user has something in the text box.
  mpTreeSearchFilters->getFilterTextBox()->setText(mpLineEdit->text());
  searchClasses();
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(useModelicaClass()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpTreeSearchFilters, 0, 0);
  pMainLayout->addWidget(mpLibraryTreeView, 1, 0);
  pMainLayout->addWidget(mpButtonBox, 2, 0, 1, 1, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief LibraryBrowseDialog::searchClasses
 * Searches the classes.
 */
void LibraryBrowseDialog::searchClasses()
{
  mpLibraryTreeView->selectionModel()->clearSelection();
  QString searchText = mpTreeSearchFilters->getFilterTextBox()->text();
  QRegExp::PatternSyntax syntax = QRegExp::PatternSyntax(mpTreeSearchFilters->getSyntaxComboBox()->itemData(mpTreeSearchFilters->getSyntaxComboBox()->currentIndex()).toInt());
  Qt::CaseSensitivity caseSensitivity = mpTreeSearchFilters->getCaseSensitiveCheckBox()->isChecked() ? Qt::CaseSensitive: Qt::CaseInsensitive;
  QRegExp regExp(searchText, caseSensitivity, syntax);
  mpLibraryTreeProxyModel->setFilterRegExp(regExp);
  // if we have really searched something
  if (!searchText.isEmpty()) {
    QModelIndex proxyIndex = mpLibraryTreeProxyModel->index(0, 0);
    if (proxyIndex.isValid()) {
      QModelIndex modelIndex = mpLibraryTreeProxyModel->mapToSource(proxyIndex);
      LibraryTreeItem *pLibraryTreeItem = mpLibraryWidget->getLibraryTreeModel()->findLibraryTreeItem(regExp, static_cast<LibraryTreeItem*>(modelIndex.internalPointer()));
      if (pLibraryTreeItem) {
        modelIndex = mpLibraryWidget->getLibraryTreeModel()->libraryTreeItemIndex(pLibraryTreeItem);
        proxyIndex = mpLibraryTreeProxyModel->mapFromSource(modelIndex);
        mpLibraryTreeView->selectionModel()->select(proxyIndex, QItemSelectionModel::Select);
        while (proxyIndex.parent().isValid()) {
          proxyIndex = proxyIndex.parent();
          mpLibraryTreeView->expand(proxyIndex);
        }
      }
    }
  }
}

/*!
 * \brief LibraryBrowseDialog::useModelicaClass
 * Uses the selected Modelica class.
 */
void LibraryBrowseDialog::useModelicaClass()
{
  const QModelIndexList modelIndexes = mpLibraryTreeView->selectionModel()->selectedIndexes();
  if (!modelIndexes.isEmpty()) {
    QModelIndex index = modelIndexes.at(0);
    index = mpLibraryTreeProxyModel->mapToSource(index);
    LibraryTreeItem *pLibraryTreeItem = static_cast<LibraryTreeItem*>(index.internalPointer());
    mpLineEdit->setText(pLibraryTreeItem->getNameStructure());
  }
  accept();
}

/*!
 * \class ModelicaClassDialog
 * \brief Creates a dialog to allow users to create new Modelica class restriction.
 */
/*!
 * \brief ModelicaClassDialog::ModelicaClassDialog
 * \param pParent
 */
ModelicaClassDialog::ModelicaClassDialog(QWidget *pParent)
  : QDialog(pParent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::createNewModelicaClass));
  setMinimumWidth(400);
  // Create the name label and text box
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit;
  // Create the specialization label and combo box
  mpSpecializationLabel = new Label(tr("Specialization:"));
  mpSpecializationComboBox = new QComboBox;
  mpSpecializationComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Model));
  mpSpecializationComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Class));
  mpSpecializationComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Connector));
  mpSpecializationComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::ExpandableConnector));
  mpSpecializationComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Record));
  mpSpecializationComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Block));
  mpSpecializationComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Function));
  mpSpecializationComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Package));
  mpSpecializationComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Type));
  mpSpecializationComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Operator));
  mpSpecializationComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::OperatorRecord));
  mpSpecializationComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::OperatorFunction));
  /* Don't add optimization restriction for now.
  mpSpecializationComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::OPTIMIZATION));
  */
  connect(mpSpecializationComboBox, SIGNAL(currentIndexChanged(QString)), SLOT(showHideSaveContentsInOneFileCheckBox(QString)));
  // create the extends the label and text box
  mpExtendsClassLabel = new Label(tr("Extends (optional):"));
  mpExtendsClassTextBox = new QLineEdit;
  mpExtendsClassBrowseButton = new QPushButton(Helper::browse);
  mpExtendsClassBrowseButton->setAutoDefault(false);
  connect(mpExtendsClassBrowseButton, SIGNAL(clicked()), SLOT(browseExtendsClass()));
  // Create the parent package label, text box, browse button
  mpParentClassLabel = new Label(tr("Insert in class (optional):"));
  mpParentClassTextBox = new QLineEdit;
  mpParentClassBrowseButton = new QPushButton(Helper::browse);
  mpParentClassBrowseButton->setAutoDefault(false);
  connect(mpParentClassBrowseButton, SIGNAL(clicked()), SLOT(browseParentClass()));
  // create partial checkbox
  mpPartialCheckBox = new QCheckBox(tr("Partial"));
  // create encapsulated checkbox
  mpEncapsulatedCheckBox = new QCheckBox(tr("Encapsulated"));
  // create state checkbox
  mpStateCheckBox = new QCheckBox(tr("State"));
  // create save contents of package in one file checkbox
  mpSaveContentsInOneFileCheckBox = new QCheckBox(Helper::saveContentsInOneFile);
  mpSaveContentsInOneFileCheckBox->setChecked(true);
  mpSaveContentsInOneFileCheckBox->setVisible(false);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(createModelicaClass()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpNameLabel, 0, 0);
  pMainLayout->addWidget(mpNameTextBox, 0, 1, 1, 2);
  pMainLayout->addWidget(mpSpecializationLabel, 1, 0);
  pMainLayout->addWidget(mpSpecializationComboBox, 1, 1, 1, 2);
  pMainLayout->addWidget(mpExtendsClassLabel, 2, 0);
  pMainLayout->addWidget(mpExtendsClassTextBox, 2, 1);
  pMainLayout->addWidget(mpExtendsClassBrowseButton, 2, 2);
  pMainLayout->addWidget(mpParentClassLabel, 3, 0);
  pMainLayout->addWidget(mpParentClassTextBox, 3, 1);
  pMainLayout->addWidget(mpParentClassBrowseButton, 3, 2);
  pMainLayout->addWidget(mpPartialCheckBox, 4, 0);
  pMainLayout->addWidget(mpSaveContentsInOneFileCheckBox, 4, 1, 1, 2);
  pMainLayout->addWidget(mpEncapsulatedCheckBox, 5, 0, 1, 3);
  pMainLayout->addWidget(mpStateCheckBox, 6, 0, 1, 3);
  pMainLayout->addWidget(mpButtonBox, 7, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief ModelicaClassDialog::showHideSaveContentsInOneFileCheckBox
 * Show/Hide save contents in one file checkbox.
 * \param text
 */
void ModelicaClassDialog::showHideSaveContentsInOneFileCheckBox(QString text)
{
  if (text.toLower().compare("package") == 0) {
    mpSaveContentsInOneFileCheckBox->setVisible(true);
  } else {
    mpSaveContentsInOneFileCheckBox->setVisible(false);
    mpSaveContentsInOneFileCheckBox->setChecked(true);
  }
}

void ModelicaClassDialog::browseExtendsClass()
{
  LibraryBrowseDialog *pLibraryBrowseDialog = new LibraryBrowseDialog(tr("Select Extends Class"), mpExtendsClassTextBox,
                                                                      MainWindow::instance()->getLibraryWidget());
  pLibraryBrowseDialog->exec();
}

void ModelicaClassDialog::browseParentClass()
{
  LibraryBrowseDialog *pLibraryBrowseDialog = new LibraryBrowseDialog(tr("Select Parent Class"), mpParentClassTextBox,
                                                                      MainWindow::instance()->getLibraryWidget());
  pLibraryBrowseDialog->exec();
}

/*!
  Creates a new Modelica class restriction.\n
  Slot activated when mpOkButton clicked signal is raised.
  */
void ModelicaClassDialog::createModelicaClass()
{
  if (mpNameTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                            GUIMessages::ENTER_NAME).arg(mpSpecializationComboBox->currentText()), Helper::ok);
    return;
  }
  /* if extends class doesn't exist. */
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pExtendsLibraryTreeItem = 0;
  if (!mpExtendsClassTextBox->text().isEmpty()) {
    pExtendsLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(mpExtendsClassTextBox->text());
    if (!pExtendsLibraryTreeItem) {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::EXTENDS_CLASS_NOT_FOUND).arg(mpExtendsClassTextBox->text()), Helper::ok);
      return;
    }
  }
  /* if insert in class doesn't exist. */
  LibraryTreeItem *pParentLibraryTreeItem = pLibraryTreeModel->getRootLibraryTreeItem();
  if (!mpParentClassTextBox->text().isEmpty()) {
    pParentLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(mpParentClassTextBox->text());
    if (!pParentLibraryTreeItem) {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::INSERT_IN_CLASS_NOT_FOUND).arg(mpParentClassTextBox->text()), Helper::ok);
      return;
    }
  }
  /* if insert in class is system library. */
  if (pParentLibraryTreeItem && pParentLibraryTreeItem->isSystemLibrary()) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::INSERT_IN_SYSTEM_LIBRARY_NOT_ALLOWED)
                          .arg(mpParentClassTextBox->text()), Helper::ok);
    return;
  }
  QString model, parentPackage;
  if (mpParentClassTextBox->text().isEmpty()) {
    model = mpNameTextBox->text().trimmed();
    parentPackage = "Global Scope";
  } else {
    model = QString(mpParentClassTextBox->text().trimmed()).append(".").append(mpNameTextBox->text().trimmed());
    parentPackage = QString("Package '").append(mpParentClassTextBox->text().trimmed()).append("'");
  }
  // Check whether model exists or not.
  if (MainWindow::instance()->getOMCProxy()->existClass(model) || pLibraryTreeModel->findLibraryTreeItemOneLevel(model)) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                            GUIMessages::MODEL_ALREADY_EXISTS).arg(mpSpecializationComboBox->currentText()).arg(model)
                          .arg(parentPackage), Helper::ok);
    return;
  }
  // create the model.
  QString modelicaClass = mpEncapsulatedCheckBox->isChecked() ? "encapsulated " : "";
  modelicaClass.append(mpPartialCheckBox->isChecked() ? "partial " : "");
  modelicaClass.append(mpSpecializationComboBox->currentText().toLower());
  if (mpParentClassTextBox->text().isEmpty()) {
    if (!MainWindow::instance()->getOMCProxy()->createClass(modelicaClass, mpNameTextBox->text().trimmed(), pExtendsLibraryTreeItem)) {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                              GUIMessages::ERROR_OCCURRED).arg(MainWindow::instance()->getOMCProxy()->getErrorString()).append("\n\n").
                            append(GUIMessages::getMessage(GUIMessages::NO_OPENMODELICA_KEYWORDS)), Helper::ok);
      return;
    }
  } else {
    if (!MainWindow::instance()->getOMCProxy()->createSubClass(modelicaClass, mpNameTextBox->text().trimmed(), pParentLibraryTreeItem, pExtendsLibraryTreeItem)) {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                              GUIMessages::ERROR_OCCURRED).arg(MainWindow::instance()->getOMCProxy()->getErrorString()).append("\n\n").
                            append(GUIMessages::getMessage(GUIMessages::NO_OPENMODELICA_KEYWORDS)), Helper::ok);
      return;
    }
  }
  // if state
  if (mpStateCheckBox->isChecked()) {
    QString nameStructure;
    if (pParentLibraryTreeItem->getNameStructure().isEmpty()) {
      nameStructure = mpNameTextBox->text().trimmed();
    } else {
      nameStructure = pParentLibraryTreeItem->getNameStructure() + "." + mpNameTextBox->text().trimmed();
    }
    MainWindow::instance()->getOMCProxy()->addClassAnnotation(nameStructure, "annotate=Icon(graphics={Text(extent={{-100,100},{100,-100}},textString=\"%name\")})");
    MainWindow::instance()->getOMCProxy()->addClassAnnotation(nameStructure, "annotate=__Dymola_state(true)");
    MainWindow::instance()->getOMCProxy()->addClassAnnotation(nameStructure, "annotate=singleInstance(true)");
  }
  // open the new tab in central widget and add the model to library tree.
  LibraryTreeItem *pLibraryTreeItem;
  pLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(mpNameTextBox->text().trimmed(), pParentLibraryTreeItem, false, false, true);
  if (pParentLibraryTreeItem != pLibraryTreeModel->getRootLibraryTreeItem() && pParentLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveInOneFile) {
    pLibraryTreeItem->setSaveContentsType(LibraryTreeItem::SaveInOneFile);
  } else if (mpSaveContentsInOneFileCheckBox->isChecked()) {
    pLibraryTreeItem->setSaveContentsType(LibraryTreeItem::SaveInOneFile);
  } else {
    pLibraryTreeItem->setSaveContentsType(LibraryTreeItem::SaveFolderStructure);
  }
  pLibraryTreeModel->checkIfAnyNonExistingClassLoaded();
  pLibraryTreeItem->setExpanded(true);
  // show the ModelWidget
  pLibraryTreeModel->showModelWidget(pLibraryTreeItem, true);
  if (pLibraryTreeItem->getModelWidget()) {
    pLibraryTreeItem->getModelWidget()->getIconGraphicsView()->addClassAnnotation(false);
    pLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->addClassAnnotation(false);
    pLibraryTreeItem->getModelWidget()->updateModelText();
  }
  accept();
}

/*!
 * \class OpenModelicaFile
 * \brief Creates a dialog to allow users to open Modelica file(s).
 */
/*!
 * \brief OpenModelicaFile::OpenModelicaFile
 * \param pParent
 */
OpenModelicaFile::OpenModelicaFile(QWidget *pParent)
  : QDialog(pParent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::openConvertModelicaFiles));
  setMinimumWidth(400);
  setModal(true);
  // create the File Label, textbox and browse button.
  mpFileLabel = new Label(Helper::fileLabel);
  mpFileTextBox = new QLineEdit;
  mpFileBrowseButton = new QPushButton(Helper::browse);
  mpFileBrowseButton->setAutoDefault(false);
  connect(mpFileBrowseButton, SIGNAL(clicked()), SLOT(browseForFile()));
  // create the encoding label, combobox and encoding note.
  mpEncodingLabel = new Label(Helper::encoding);
  mpEncodingComboBox = new QComboBox;
  StringHandler::fillEncodingComboBox(mpEncodingComboBox);
  mpConvertAllFilesCheckBox = new QCheckBox(tr("Convert all files within the selected directory and sub-directories"));
  // Create the buttons
  /* Open with selected encoding button */
  mpOpenWithEncodingButton = new QPushButton(tr("Open with selected encoding"));
  mpOpenWithEncodingButton->setStyleSheet("QPushButton{padding: 5px 15px 5px 15px;}");
  mpOpenWithEncodingButton->setAutoDefault(true);
  connect(mpOpenWithEncodingButton, SIGNAL(clicked()), SLOT(openModelicaFiles()));
  /* Open and convert to utf-8 button */
  mpOpenAndConvertToUTF8Button = new QPushButton(tr("Open and convert to UTF-8"));
  mpOpenAndConvertToUTF8Button->setStyleSheet("QPushButton{padding: 5px 15px 5px 15px;}");
  connect(mpOpenAndConvertToUTF8Button, SIGNAL(clicked()), SLOT(convertModelicaFiles()));
  /* cancel button */
  mpCancelButton = new QPushButton(Helper::cancel);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOpenWithEncodingButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpOpenAndConvertToUTF8Button, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpFileLabel, 0, 0);
  pMainLayout->addWidget(mpFileTextBox, 0, 1);
  pMainLayout->addWidget(mpFileBrowseButton, 0, 2);
  pMainLayout->addWidget(mpEncodingLabel, 1, 0);
  pMainLayout->addWidget(mpEncodingComboBox, 1, 1, 1, 2);
  pMainLayout->addWidget(mpConvertAllFilesCheckBox, 2, 0, 1, 3);
  pMainLayout->addWidget(mpButtonBox, 3, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
  Looks for the files and directories for conversion to UTF-8.
  \param filesAndDirectories - the list of files and directories that should be converted.
  \param path - the directory path where files and directories are located.
  */
void OpenModelicaFile::convertModelicaFiles(QStringList filesAndDirectories, QString path, QTextCodec *pCodec)
{
  foreach (QString fileOrDirectory, filesAndDirectories)
  {
    QFileInfo fileOrDirectoryInfo(QString(path).append("/").append(fileOrDirectory));
    if (fileOrDirectoryInfo.isDir())
    {
      QDir directory(QString(path).append("/").append(fileOrDirectory));
      QStringList nameFilter("*.mo");
      QStringList filesAndDirectories = directory.entryList(nameFilter, QDir::AllDirs | QDir::Files | QDir::NoSymLinks |
                                                            QDir::NoDotAndDotDot | QDir::Writable | QDir::CaseSensitive);
      convertModelicaFiles(filesAndDirectories, directory.absolutePath(), pCodec);
    }
    else
    {
      convertModelicaFile(QString(path).append("/").append(fileOrDirectory), pCodec);
    }
  }
}

/*!
  Converts the file to UTF-8 encoding.
  \param fileName - the full name of the file to convert.
  */
void OpenModelicaFile::convertModelicaFile(QString fileName, QTextCodec *pCodec)
{
  QFile file(fileName);
  file.open(QIODevice::ReadOnly);
  QString fileData(pCodec->toUnicode(file.readAll()));
  file.close();
  file.open(QIODevice::WriteOnly | QIODevice::Truncate);
  QTextStream out(&file);
  out.setCodec(Helper::utf8.toStdString().data());
  out.setGenerateByteOrderMark(false);
  out << fileData;
  file.close();
}

/*!
  Asks the user to select the Modelica file(s) they want to open.\n
  Slot activated when mpFileBrowseButton clicked signal is raised.
  */
void OpenModelicaFile::browseForFile()
{
  QStringList fileNames;
  mFileNames.clear();
  fileNames = StringHandler::getOpenFileNames(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFiles),
                                              NULL, Helper::omFileTypes, NULL);
  foreach (QString fileName, fileNames)
  {
    mFileNames.append(fileName.replace("\\", "/"));
  }
  mpFileTextBox->setText(mFileNames.join(";"));
}

/*!
  Opens the selected Modelica file(s).\n
  Slot activated when mpOpenButton clicked signal is raised.
  */
void OpenModelicaFile::openModelicaFiles(bool convertedToUTF8)
{
  int progressValue = 0;
  MainWindow::instance()->getProgressBar()->setRange(0, mFileNames.size());
  MainWindow::instance()->showProgressBar();
  foreach (QString fileName, mFileNames)
  {
    MainWindow::instance()->getStatusBar()->showMessage(QString(Helper::loading).append(": ").append(fileName));
    MainWindow::instance()->getProgressBar()->setValue(++progressValue);
    // if file doesn't exists
    if (!QFile::exists(fileName))
    {
      QMessageBox *pMessageBox = new QMessageBox(MainWindow::instance());
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
      pMessageBox->setIcon(QMessageBox::Critical);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(fileName)));
      pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::FILE_NOT_FOUND).arg(fileName)));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
    }
    else
    {
      if (convertedToUTF8)
        MainWindow::instance()->getLibraryWidget()->openFile(fileName, Helper::utf8, false);
      else
        MainWindow::instance()->getLibraryWidget()->openFile(fileName, mpEncodingComboBox->itemData(mpEncodingComboBox->currentIndex()).toString(), false);
    }
  }
  MainWindow::instance()->getStatusBar()->clearMessage();
  MainWindow::instance()->hideProgressBar();
  accept();
}

/*!
  Converts the selected Modelica file(s).\n
  Slot activated when mpOpenAndConvertToUTF8Button clicked signal is raised.
  */
void OpenModelicaFile::convertModelicaFiles()
{
  QTextCodec *pCodec = QTextCodec::codecForName(mpEncodingComboBox->itemData(mpEncodingComboBox->currentIndex()).toString().toStdString().data());
  if (pCodec != NULL)
  {
    MainWindow::instance()->getStatusBar()->showMessage(tr("Converting files to UTF-8"));
    QApplication::setOverrideCursor(Qt::WaitCursor);
    foreach (QString fileName, mFileNames)
    {
      if (QFile::exists(fileName))
      {
        if (mpConvertAllFilesCheckBox->isChecked())
        {
          QFileInfo fileInfo(fileName);
          QDir directory = fileInfo.absoluteDir();
          QStringList nameFilter("*.mo");
          QStringList filesAndDirectories = directory.entryList(nameFilter, QDir::AllDirs | QDir::Files | QDir::NoSymLinks |
                                                                QDir::NoDotAndDotDot | QDir::Writable | QDir::CaseSensitive);
          convertModelicaFiles(filesAndDirectories, directory.absolutePath(), pCodec);
        }
        else
        {
          convertModelicaFile(fileName, pCodec);
        }
      }
    }
  }
  MainWindow::instance()->getStatusBar()->clearMessage();
  QApplication::restoreOverrideCursor();
  openModelicaFiles(true);
}

/*!
 * \class SaveAsClassDialog
 * \brief Creates a dialog to allow users to save as the Modelica class.
 */
/*!
 * \brief SaveAsClassDialog::SaveAsClassDialog
 * \param pModelWidget
 * \param pParent
 */
SaveAsClassDialog::SaveAsClassDialog(ModelWidget *pModelWidget, QWidget *pParent)
  : QDialog(pParent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Save As Modelica Class")));
  setMinimumWidth(400);
  mpModelWidget = pModelWidget;
  setModal(true);
  // Create the name label and text box
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit(pModelWidget->getLibraryTreeItem()->getName());
  // Create the parent package label, text box, browse button
  mpParentPackageLabel = new Label(tr("Insert in class (optional):"));
  mpParentClassComboBox = new QComboBox;
  mpParentClassComboBox->setEditable(true);
  /* Since the default QCompleter for QComboBox is case insenstive. */
  QCompleter *pParentClassComboBoxCompleter = mpParentClassComboBox->completer();
  pParentClassComboBoxCompleter->setCaseSensitivity(Qt::CaseSensitive);
  mpParentClassComboBox->setCompleter(pParentClassComboBoxCompleter);
  mpParentClassComboBox->addItem("");
  int currentIndex = mpParentClassComboBox->findText(pModelWidget->getLibraryTreeItem()->parent()->getNameStructure(), Qt::MatchExactly);
  if (currentIndex > -1)
    mpParentClassComboBox->setCurrentIndex(currentIndex);
  connect(mpParentClassComboBox, SIGNAL(editTextChanged(QString)), SLOT(showHideSaveContentsInOneFileCheckBox(QString)));
  // create save contents of package in one file checkbox
  mpSaveContentsInOneFileCheckBox = new QCheckBox(Helper::saveContentsInOneFile);
  mpSaveContentsInOneFileCheckBox->setChecked(true);
  if (pModelWidget->getLibraryTreeItem()->getRestriction() == StringHandler::Package && mpParentClassComboBox->currentText().isEmpty())
    mpSaveContentsInOneFileCheckBox->setVisible(true);
  else
    mpSaveContentsInOneFileCheckBox->setVisible(false);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(saveAsModelicaClass()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpNameLabel, 0, 0);
  pMainLayout->addWidget(mpNameTextBox, 0, 1);
  pMainLayout->addWidget(mpParentPackageLabel, 1, 0);
  pMainLayout->addWidget(mpParentClassComboBox, 1, 1);
  pMainLayout->addWidget(mpSaveContentsInOneFileCheckBox, 2, 0);
  pMainLayout->addWidget(mpButtonBox, 2, 1, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
  Creates a new Modelica class restriction.\n
  Slot activated when mpOkButton clicked signal is raised.
  */
void SaveAsClassDialog::saveAsModelicaClass()
{
  QString type = StringHandler::getModelicaClassType(mpModelWidget->getLibraryTreeItem()->getRestriction());
  if (mpNameTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                            GUIMessages::ENTER_NAME).arg(type), Helper::ok);
    return;
  }
  /* if insert in class doesn't exist. */
  if (!mpParentClassComboBox->currentText().isEmpty()) {
    if (!MainWindow::instance()->getOMCProxy()->existClass(mpParentClassComboBox->currentText())) {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                              GUIMessages::INSERT_IN_CLASS_NOT_FOUND).arg(mpParentClassComboBox->currentText()), Helper::ok);
      return;
    }
  }
  /* if insert in class is system library. */
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pParentLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(mpParentClassComboBox->currentText());
  if (pParentLibraryTreeItem) {
    if (pParentLibraryTreeItem->isSystemLibrary()) {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                              GUIMessages::INSERT_IN_SYSTEM_LIBRARY_NOT_ALLOWED).arg(mpParentClassComboBox->currentText()), Helper::ok);
      return;
    }
  }

  QString model, parentPackage;
  if (mpParentClassComboBox->currentText().isEmpty())
  {
    model = mpNameTextBox->text();
    parentPackage = "Global Scope";
  }
  else
  {
    model = QString(mpParentClassComboBox->currentText()).append(".").append(mpNameTextBox->text());
    parentPackage = QString("Package '").append(mpParentClassComboBox->currentText()).append("'");
  }
  // Check whether model exists or not.
  if (MainWindow::instance()->getOMCProxy()->existClass(model) || MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItemOneLevel(model)) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                            GUIMessages::MODEL_ALREADY_EXISTS).arg(type).arg(model).arg(parentPackage), Helper::ok);
    return;
  }
  // duplicate the model.
  QString sourceModelText = MainWindow::instance()->getOMCProxy()->list(mpModelWidget->getLibraryTreeItem()->getNameStructure());
  QString duplicateModelText = sourceModelText;
  /* remove the starting and ending text strings of the model. */
  duplicateModelText.remove(0, QString(type.toLower()).append(" ").append(mpModelWidget->getLibraryTreeItem()->getName()).length());
  QString endString = QString("end ").append(mpModelWidget->getLibraryTreeItem()->getName()).append(";");
  duplicateModelText.remove(duplicateModelText.lastIndexOf(endString), endString.length());
  /* add the starting and ending text strings. */
  duplicateModelText.prepend(QString(type.toLower()).append(" ").append(mpNameTextBox->text()));
  duplicateModelText.append(QString("end ").append(mpNameTextBox->text()).append(";"));
  if (!mpParentClassComboBox->currentText().isEmpty())
  {
    duplicateModelText.prepend(QString("within ").append(mpParentClassComboBox->currentText()).append(";"));
  }
  MainWindow::instance()->getOMCProxy()->sendCommand(duplicateModelText);
  if (MainWindow::instance()->getOMCProxy()->getResult().toLower().contains("error"))
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                            GUIMessages::ERROR_OCCURRED).arg(MainWindow::instance()->getOMCProxy()->getResult()).append("\n\n").
                          append(GUIMessages::getMessage(GUIMessages::NO_OPENMODELICA_KEYWORDS)), Helper::ok);
    return;
  }
  //open the new tab in central widget and add the model to library tree.
  LibraryTreeItem *pLibraryTreeItem;
  if (pParentLibraryTreeItem) {
    pLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(mpNameTextBox->text(), pParentLibraryTreeItem, false, false, true);
  } else {
    pLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(mpNameTextBox->text(), pLibraryTreeModel->getRootLibraryTreeItem(), false, false, true);
  }
  pLibraryTreeItem->setSaveContentsType(mpSaveContentsInOneFileCheckBox->isChecked() ? LibraryTreeItem::SaveInOneFile : LibraryTreeItem::SaveFolderStructure);
  pLibraryTreeModel->checkIfAnyNonExistingClassLoaded();
  // show the ModelWidget
  pLibraryTreeModel->showModelWidget(pLibraryTreeItem);
  accept();
}

void SaveAsClassDialog::showHideSaveContentsInOneFileCheckBox(QString text)
{
  if (text.isEmpty() && mpModelWidget->getLibraryTreeItem()->getRestriction() == StringHandler::Package)
    mpSaveContentsInOneFileCheckBox->setVisible(true);
  else
    mpSaveContentsInOneFileCheckBox->setVisible(false);
}

/*!
 * \class DuplicateClassDialog
 * \brief Creates a dialog to allow users to duplicate/save as the Modelica class.
 */
/*!
 * \brief DuplicateClassDialog::DuplicateClassDialog
 * \param saveAs
 * \param pLibraryTreeItem
 * \param pParent
 */
DuplicateClassDialog::DuplicateClassDialog(bool saveAs, LibraryTreeItem *pLibraryTreeItem, QWidget *pParent)
  : QDialog(pParent), mpLibraryTreeItem(pLibraryTreeItem)
{
  setMinimumWidth(400);
  setAttribute(Qt::WA_DeleteOnClose);
  mSaveAs = saveAs;
  QString heading = mSaveAs ? Helper::saveAs : Helper::duplicate;
  setWindowTitle(QString("%1 - %2 %3").arg(Helper::applicationName).arg(heading).arg(mpLibraryTreeItem->getNameStructure()));
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit(mpLibraryTreeItem->getName());
  mpNameTextBox->selectAll();
  mpPathLabel = new Label(Helper::path);
  mpPathTextBox = new QLineEdit(mpLibraryTreeItem->isTopLevel() ? "" : mpLibraryTreeItem->parent()->getNameStructure());
  mpPathBrowseButton = new QPushButton(Helper::browse);
  mpPathBrowseButton->setAutoDefault(false);
  connect(mpPathBrowseButton, SIGNAL(clicked()), SLOT(browsePath()));
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(duplicateClass()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpNameLabel, 0, 0);
  pMainLayout->addWidget(mpNameTextBox, 0, 1, 1, 2);
  pMainLayout->addWidget(mpPathLabel, 1, 0);
  pMainLayout->addWidget(mpPathTextBox, 1, 1);
  pMainLayout->addWidget(mpPathBrowseButton, 1, 2);
  pMainLayout->addWidget(new Label(tr("* Note: This operation can take sometime to finish depending on the size of your library.")), 2, 0, 1, 3, Qt::AlignLeft);
  pMainLayout->addWidget(mpButtonBox, 3, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief DuplicateClassDialog::selectFileType
 * Shows a QDialog which asks for a file type for a class.
 * \param pLibraryTreeItem - The source LibraryTreeItem.
 * \param pParentLibraryTreeItem - The parent LibraryTreeItem where the class will be duplicated.
 * \return
 */
DuplicateClassDialog::FileType DuplicateClassDialog::selectFileType(LibraryTreeItem *pLibraryTreeItem,
                                                                    LibraryTreeItem *pParentLibraryTreeItem)
{
  // if the destination package is saved in one file then we always save in one file
  if (pLibraryTreeItem->getRestriction() == StringHandler::Package
      && pParentLibraryTreeItem
      && !pParentLibraryTreeItem->isRootItem()
      && pParentLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveInOneFile) {
    return OneFile;
  } else if (pLibraryTreeItem->getRestriction() == StringHandler::Package) {
    // select dialog
    QDialog *pSelectFileTypeDialog = new QDialog;
    pSelectFileTypeDialog->setAttribute(Qt::WA_DeleteOnClose);
    pSelectFileTypeDialog->setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, Helper::question));
    // icon
    int iconSize = this->style()->pixelMetric(QStyle::PM_MessageBoxIconSize, 0, this);
    QIcon tmpIcon = this->style()->standardIcon(QStyle::SP_MessageBoxQuestion, 0, this);
    Label *pPixmapLabel = new Label;
    pPixmapLabel->setPixmap(tmpIcon.pixmap(iconSize, iconSize));
    // text
    Label *pTextLabel = new Label(tr("Select file type for %1").arg(pLibraryTreeItem->getNameStructure()));
    // buttons
    QSignalMapper signalMapper;
    // Keep structure button
    QPushButton *pKeepStructureButton = new QPushButton(tr("Keep Structure"));
    pKeepStructureButton->setToolTip(tr("Keeps the same file type structure for the package and its contents recursively."));
    pKeepStructureButton->setAutoDefault(true);
    connect(pKeepStructureButton, SIGNAL(clicked()), &signalMapper, SLOT(map()));
    // One File button
    QPushButton *pOneFileButton = new QPushButton(tr("One File"));
    pOneFileButton->setToolTip(tr("Stores the package and all its contents in one file."));
    pOneFileButton->setAutoDefault(false);
    connect(pOneFileButton, SIGNAL(clicked()), pSelectFileTypeDialog, SLOT(reject()));
    // Directory button
    QPushButton *pDirectoryButton = new QPushButton(tr("Directory"));
    pDirectoryButton->setToolTip(tr("Creates a directory for the package."));
    pDirectoryButton->setAutoDefault(false);
    connect(pDirectoryButton, SIGNAL(clicked()), pSelectFileTypeDialog, SLOT(accept()));
    // Directories button
    QPushButton *pDirectoriesForAllButton = new QPushButton(tr("Directories For All"));
    pDirectoriesForAllButton->setToolTip(tr("Creates the directories for the package and its contents recursively."));
    pDirectoriesForAllButton->setAutoDefault(false);
    connect(pDirectoriesForAllButton, SIGNAL(clicked()), &signalMapper, SLOT(map()));
    // set signal mapping
    signalMapper.setMapping(pDirectoriesForAllButton, 2);
    signalMapper.setMapping(pKeepStructureButton, 3);
    connect(&signalMapper, SIGNAL(mapped(int)), pSelectFileTypeDialog, SLOT(done(int)));
    // layout the buttons
    QDialogButtonBox *pButtonBox = new QDialogButtonBox;
    pButtonBox->addButton(pKeepStructureButton, QDialogButtonBox::ActionRole);
    pButtonBox->addButton(pOneFileButton, QDialogButtonBox::ActionRole);
    pButtonBox->addButton(pDirectoryButton, QDialogButtonBox::ActionRole);
    pButtonBox->addButton(pDirectoriesForAllButton, QDialogButtonBox::ActionRole);
    // horizontal layout
    QHBoxLayout *pHorizontalLayout = new QHBoxLayout;
    pHorizontalLayout->addWidget(pPixmapLabel, 0, Qt::AlignTop);
    pHorizontalLayout->addWidget(pTextLabel, 0, Qt::AlignTop);
    // main layout
    QGridLayout *pMainLayout = new QGridLayout;
    pMainLayout->addLayout(pHorizontalLayout, 0, 0, Qt::AlignTop | Qt::AlignLeft);
    pMainLayout->addWidget(pButtonBox, 1, 0, Qt::AlignRight | Qt::AlignBottom);
    pSelectFileTypeDialog->setLayout(pMainLayout);
    int answer = pSelectFileTypeDialog->exec();

    switch (answer) {
      case 1:
        return Directory;
      case 2:
        return Directories;
      case 3:
        return KeepStructure;
      case 0:
      default:
        return OneFile;
    }
  } else {
    return OneFile;
  }
}

/*!
 * \brief DuplicateClassDialog::setSaveContentsTypeAsFolderStructure
 * Set LibraryTreeItem::SaveFolderStructure for all nested packages.
 * \param pLibraryTreeItem
 */
void DuplicateClassDialog::setSaveContentsTypeAsFolderStructure(LibraryTreeItem *pLibraryTreeItem)
{
  for (int i = 0; i < pLibraryTreeItem->childrenSize(); i++) {
    LibraryTreeItem *pChildLibraryTreeItem = pLibraryTreeItem->child(i);
    if (pChildLibraryTreeItem->getRestriction() == StringHandler::Package) {
      pChildLibraryTreeItem->setSaveContentsType(LibraryTreeItem::SaveFolderStructure);
      pChildLibraryTreeItem->setClassText(QString("within %1;\npackage %2\nend %2;").arg(pLibraryTreeItem->getNameStructure(),
                                                                                         pChildLibraryTreeItem->getName()));
    }
    setSaveContentsTypeAsFolderStructure(pChildLibraryTreeItem);
  }
}

/*!
 * \brief DuplicateClassDialog::duplicateClassHelper
 * Duplicates the classes recursively. Performs the diff to preserve formatting.
 * \param pDestinationLibraryTreeItem
 * \param pSourceLibraryTreeItem
 * \param fileType
 */
void DuplicateClassDialog::duplicateClassHelper(LibraryTreeItem *pDestinationLibraryTreeItem, LibraryTreeItem *pSourceLibraryTreeItem,
                                                FileType fileType)
{
  QString classText;
  if (pDestinationLibraryTreeItem->parent()->getSaveContentsType() == LibraryTreeItem::SaveInOneFile
      && pSourceLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveFolderStructure && fileType == OneFile) {
    classText = MainWindow::instance()->getOMCProxy()->listFile(pDestinationLibraryTreeItem->getNameStructure(), false);
  } else if (!pDestinationLibraryTreeItem->parent()->isRootItem()
      && pDestinationLibraryTreeItem->parent()->getSaveContentsType() == LibraryTreeItem::SaveInOneFile) {
    classText = MainWindow::instance()->getOMCProxy()->list(pDestinationLibraryTreeItem->getNameStructure());
  } else if (fileType == KeepStructure) {
    classText = MainWindow::instance()->getOMCProxy()->listFile(pDestinationLibraryTreeItem->getNameStructure(),
                                                                pSourceLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveInOneFile);
  } else {
    classText = MainWindow::instance()->getOMCProxy()->listFile(pDestinationLibraryTreeItem->getNameStructure(), fileType == OneFile);
  }
  QString beforeClassText = pSourceLibraryTreeItem->getClassText(MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel());
  beforeClassText = StringHandler::removeLeadingSpaces(beforeClassText);
  /* Ticket #3912
   * In order to preserve the formatting we use OMCProxy::diffModelicaFileListings()
   */
  classText = MainWindow::instance()->getOMCProxy()->diffModelicaFileListings(beforeClassText, classText);
  // set the class text
  pDestinationLibraryTreeItem->setClassText(classText);

  if (pDestinationLibraryTreeItem->parent()->getSaveContentsType() == LibraryTreeItem::SaveInOneFile
      && pSourceLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveFolderStructure && fileType == OneFile) {
    /* Case 8, 10
     * If the save type is save in one file and source package is saved as folder structure
     * then we need to flat the package to one file and then insert it inside the package if within is specified.
     */
    classText = StringHandler::removeLine(classText, QString("within %1;").arg(pDestinationLibraryTreeItem->parent()->getNameStructure()));
    // remove the whitespaces around the string if any
    classText = classText.trimmed();
    QString childClassText;
    folderToOneFilePackage(pDestinationLibraryTreeItem, pSourceLibraryTreeItem, &childClassText);
    // insert the class in package
    classText = StringHandler::insertClassAtPosition(classText, childClassText, 1, 2);
    // set the class text
    pDestinationLibraryTreeItem->setClassText(classText);
    if (!pDestinationLibraryTreeItem->parent()->isRootItem()) {
      insertClassInOneFilePackage(pDestinationLibraryTreeItem);
    }
  } else if (!pDestinationLibraryTreeItem->parent()->isRootItem()
             && pDestinationLibraryTreeItem->parent()->getSaveContentsType() == LibraryTreeItem::SaveInOneFile) {
    /* Case 2
     * If the save type is save in one file then we need to insert the new class inside the package.
     */
    insertClassInOneFilePackage(pDestinationLibraryTreeItem);
  }

  if (fileType == Directory || fileType == Directories
      || (fileType == KeepStructure && pSourceLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveFolderStructure)) {
    for (int i = 0 ; i < pDestinationLibraryTreeItem->childrenSize() ; i++) {
      LibraryTreeItem *pDestinationChildLibraryTreeItem = pDestinationLibraryTreeItem->childAt(i);
      LibraryTreeItem *pSourceChildLibraryTreeItem = pSourceLibraryTreeItem->childAt(i);
      // save file type
      FileType saveFileType = fileType;
      if (fileType == Directory) {
        fileType = selectFileType(pDestinationChildLibraryTreeItem);
      }
      if (fileType == OneFile || pDestinationChildLibraryTreeItem->getRestriction() != StringHandler::Package) {
        pDestinationChildLibraryTreeItem->setSaveContentsType(LibraryTreeItem::SaveInOneFile);
      } else if (fileType == KeepStructure) {
        pDestinationChildLibraryTreeItem->setSaveContentsType(pSourceChildLibraryTreeItem->getSaveContentsType());
      } else {
        pDestinationChildLibraryTreeItem->setSaveContentsType(LibraryTreeItem::SaveFolderStructure);
      }
      duplicateClassHelper(pDestinationChildLibraryTreeItem, pSourceChildLibraryTreeItem, fileType);
      // restore file type so the next iteration can use the correct file type.
      fileType = saveFileType;
    }
  }
}

/*!
 * \brief DuplicateClassDialog::syncDuplicatedModelWithOMC
 * Send the duplicated model text to OMC to sync the line numbers.
 * \param pLibraryTreeItem
 */
void DuplicateClassDialog::syncDuplicatedModelWithOMC(LibraryTreeItem *pLibraryTreeItem)
{
  /* Ticket #3793
   * We need to call loadString with the new text of the class so that the getClassInformation returns the correct line number information.
   * Otherwise we have the problems like the one reported in Ticket #3793.
   */
  QString filename = pLibraryTreeItem->getNameStructure();
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  if (!pLibraryTreeItem->parent()->isRootItem() && pLibraryTreeItem->parent()->getSaveContentsType() == LibraryTreeItem::SaveInOneFile) {
    LibraryTreeItem *pParentLibraryTreeItem = pLibraryTreeModel->getContainingFileParentLibraryTreeItem(pLibraryTreeItem);
    filename = pParentLibraryTreeItem->isFilePathValid() ? pParentLibraryTreeItem->getFileName() : pParentLibraryTreeItem->getNameStructure();
    pLibraryTreeItem = pParentLibraryTreeItem;
  }
  QString classText = pLibraryTreeItem->getClassText(pLibraryTreeModel);
  // load the string in omc so that OMC and OMEdit have same line numbers.
  MainWindow::instance()->getOMCProxy()->loadString(classText, filename, Helper::utf8, false, false);

  if (pLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveInOneFile) {
    pLibraryTreeModel->updateChildLibraryTreeItemClassText(pLibraryTreeItem, classText, pLibraryTreeItem->getFileName());
  } else {
    for (int i = 0 ; i < pLibraryTreeItem->childrenSize() ; i++) {
      syncDuplicatedModelWithOMC(pLibraryTreeItem->childAt(i));
    }
  }
  pLibraryTreeItem->setClassInformation(MainWindow::instance()->getOMCProxy()->getClassInformation(pLibraryTreeItem->getNameStructure()));
}

/*!
 * \brief DuplicateClassDialog::folderToOneFilePackage
 * Takes the package saved in folder structure and flats it out to a string for one file.
 * \param pDestinationLibraryTreeItem
 * \param pSourceLibraryTreeItem
 * \param classText
 */
void DuplicateClassDialog::folderToOneFilePackage(LibraryTreeItem *pDestinationLibraryTreeItem, LibraryTreeItem *pSourceLibraryTreeItem,
                                                  QString *classText)
{
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  for (int i = 0 ; i < pSourceLibraryTreeItem->childrenSize() ; i++) {
    LibraryTreeItem *pSourceChildLibraryTreeItem = pSourceLibraryTreeItem->childAt(i);
    LibraryTreeItem *pDestinationChildLibraryTreeItem = pDestinationLibraryTreeItem->childAt(i);
    if (pSourceChildLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveInOneFile) {
      QString afterChildClassText = MainWindow::instance()->getOMCProxy()->listFile(pDestinationChildLibraryTreeItem->getNameStructure());
      QString beforeChildClassText = pSourceChildLibraryTreeItem->getClassText(pLibraryTreeModel);
      QString diffClassText = MainWindow::instance()->getOMCProxy()->diffModelicaFileListings(beforeChildClassText, afterChildClassText);
      QString lineToRemove = QString("within %1;").arg(pDestinationLibraryTreeItem->getNameStructure());
      *classText += StringHandler::removeLine(diffClassText, lineToRemove) + "\n";
    } else {
      QString afterChildClassText = MainWindow::instance()->getOMCProxy()->listFile(pDestinationChildLibraryTreeItem->getNameStructure(),
                                                                                    false);
      QString beforeChildClassText = pSourceChildLibraryTreeItem->getClassText(pLibraryTreeModel);
      QString parentClassText = MainWindow::instance()->getOMCProxy()->diffModelicaFileListings(beforeChildClassText, afterChildClassText);
      QString lineToRemove = QString("within %1;").arg(pDestinationLibraryTreeItem->getNameStructure());
      parentClassText = StringHandler::removeLine(parentClassText, lineToRemove);
      // remove the whitespaces around the string if any
      parentClassText = parentClassText.trimmed();
      QString childClassText;
      folderToOneFilePackage(pDestinationChildLibraryTreeItem, pSourceChildLibraryTreeItem, &childClassText);
      // insert the class in package
      *classText += StringHandler::insertClassAtPosition(parentClassText, childClassText, 1, 2);
    }
  }
}

/*!
 * \brief DuplicateClassDialog::insertClassInOneFilePackage
 * Takes a class LibraryTreeItem and insert its text inside its parent class.
 * \param pLibraryTreeItem
 */
void DuplicateClassDialog::insertClassInOneFilePackage(LibraryTreeItem *pLibraryTreeItem)
{
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pParentLibraryTreeItem = pLibraryTreeModel->getContainingFileParentLibraryTreeItem(pLibraryTreeItem);
  QString parentClassText = pParentLibraryTreeItem->getClassText(pLibraryTreeModel);
  QString childClassText = pLibraryTreeItem->getClassText(pLibraryTreeModel);
  int linePosition;
  /* We need to know where to insert the new class.
   * Note that the new class is already part of the package because of the copyClass but it doesn't have right formatting.
   * We know that the package always have 1 class so we check from more than 1.
   * Take the second last since last one is the new class. When taking the second last one insert one line break at top to make it look nice.
   * When there is only one class then use the lineNumberStart of the package.
   */
  if (pLibraryTreeItem->parent()->childrenSize() > 1) {
    LibraryTreeItem *pLastChildLibraryTreeItem = pLibraryTreeItem->parent()->childAt(pLibraryTreeItem->parent()->childrenSize() - 2);
    linePosition = pLastChildLibraryTreeItem->mClassInformation.lineNumberEnd;
    childClassText = "\n" + childClassText;
  } else {
    linePosition = pLibraryTreeItem->parent()->mClassInformation.lineNumberStart;
  }
  // insert the class in package
  QString classText = StringHandler::insertClassAtPosition(parentClassText, childClassText, linePosition,
                                                           pLibraryTreeItem->getNestedLevelInPackage());
  // update the class text, mark it unsaved
  pParentLibraryTreeItem->setClassText(classText);
  pParentLibraryTreeItem->setIsSaved(false);
  pLibraryTreeModel->updateLibraryTreeItem(pParentLibraryTreeItem);
  if (pParentLibraryTreeItem->getModelWidget()) {
    pParentLibraryTreeItem->getModelWidget()->setWindowTitle(QString(pParentLibraryTreeItem->getName()).append("*"));
  }
}

/*!
 * \brief DuplicateClassDialog::browsePath
 * Browse the destination path.
 */
void DuplicateClassDialog::browsePath()
{
  LibraryBrowseDialog *pLibraryBrowseDialog = new LibraryBrowseDialog(tr("Select Path"), mpPathTextBox, MainWindow::instance()->getLibraryWidget());
  pLibraryBrowseDialog->exec();
}

/*!
 * \brief DuplicateClassDialog::duplicateClass
 * Duplicates the class.
 */
void DuplicateClassDialog::duplicateClass()
{
  if (mpNameTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg("class"), Helper::ok);
    return;
  }
  /* if path class doesn't exist. */
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pParentLibraryTreeItem = pLibraryTreeModel->getRootLibraryTreeItem();
  if (!mpPathTextBox->text().isEmpty()) {
    pParentLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(mpPathTextBox->text());
    if (!pParentLibraryTreeItem) {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::INSERT_IN_CLASS_NOT_FOUND).arg(mpPathTextBox->text()), Helper::ok);
      return;
    }
  }
  // check if new class already exists
  QString newClassPath = (mpPathTextBox->text().isEmpty() ? "" : mpPathTextBox->text() + ".") + mpNameTextBox->text();
  if (MainWindow::instance()->getOMCProxy()->existClass(newClassPath) || pLibraryTreeModel->findLibraryTreeItemOneLevel(newClassPath)) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::MODEL_ALREADY_EXISTS).arg("class").arg(mpNameTextBox->text())
                          .arg((mpPathTextBox->text().isEmpty() ? "Top Level" : mpPathTextBox->text())), Helper::ok);
    return;
  }
  // check if path is not a system library
  if (!mpPathTextBox->text().isEmpty()) {
    LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(mpPathTextBox->text());
    if (pLibraryTreeItem && pLibraryTreeItem->isSystemLibrary()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            tr("Cannot duplicate inside system library."), Helper::ok);
      return;
    } else if (pLibraryTreeItem->getRestriction() != StringHandler::Package) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            tr("Can only duplicate inside a package. <b>%1</b> is not a package.").arg(pLibraryTreeItem->getNameStructure()),
                            Helper::ok);
      return;
    }
  }
  // if everything is fine then duplicate the class.
  if (!StringHandler::containsSpace(mpNameTextBox->text()) &&
      MainWindow::instance()->getOMCProxy()->copyClass(mpLibraryTreeItem->getNameStructure(), mpNameTextBox->text(), mpPathTextBox->text())) {
    // create the new LibraryTreeItem
    LibraryTreeItem *pLibraryTreeItem;
    pLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(mpNameTextBox->text().trimmed(), pParentLibraryTreeItem, false, false, true);
    /* There are following cases of duplicate
     * (within - package can be one file or folder structure).
     * Case 1: The source is non package saved in one file and destination is top level.
     * Case 2: The source is non package saved in one file and destination is package saved in one file.
     * Case 3: The source is non package saved in one file and destination is package saved in folder structure.
     * Case 4: The source is a package saved in one file and destination is top level. The duplicated package saved in one file.
     * Case 5: // // // // // // // // // // // // // // // // // // // // // // // /. The duplicated package saved as folder structure.
     * Case 6: The source is a package saved in one file and destination is within. The duplicated package saved in one file.
     * Case 7: // // // // // // // // // // // // // // // // // // // // // // /. The duplicated package saved as folder structure.
     * Case 8: The source is a package saved in folder structure and destination is top level. The duplicated package saved in one file.
     * Case 9: // // // // // // // // // // // // // // // // // // // // // // // // // // . The duplicated package saved as folder structure.
     * Case 10: The source is a package saved in folder structure and destination is within. The duplicated package saved in one file.
     * Case 11: // // // // // // // // // // // // // // // // // // // // // // // // //. The duplicated package saved as folder structure.
     */
    FileType fileType = selectFileType(mpLibraryTreeItem, pParentLibraryTreeItem);
    if (fileType == Directory || fileType == Directories
        || (fileType == KeepStructure && mpLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveFolderStructure)) {
      pLibraryTreeItem->setSaveContentsType(LibraryTreeItem::SaveFolderStructure);
    }
    duplicateClassHelper(pLibraryTreeItem, mpLibraryTreeItem, fileType);
    syncDuplicatedModelWithOMC(pLibraryTreeItem);
    pLibraryTreeModel->checkIfAnyNonExistingClassLoaded();
    pLibraryTreeModel->showModelWidget(pLibraryTreeItem);
    if (mSaveAs) {
      MainWindow::instance()->getLibraryWidget()->saveLibraryTreeItem(pLibraryTreeItem);
    }
    accept();
  } else {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), tr("Unable to create class <b>%1</b>. %2")
                          .arg(mpNameTextBox->text(), GUIMessages::getMessage(GUIMessages::NO_OPENMODELICA_KEYWORDS)), Helper::ok);
  }
}

/*!
 * \class RenameClassDialog
 * \brief Creates a dialog to allow users to rename the Modelica class.
 */
/*!
 * \brief RenameClassDialog::RenameClassDialog
 * \param name
 * \param nameStructure
 * \param pParent
 */
RenameClassDialog::RenameClassDialog(QString name, QString nameStructure, QWidget *pParent)
  : QDialog(pParent), mName(name), mNameStructure(nameStructure)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - Rename ").append(name));
  setMinimumSize(300, 100);
  setModal(true);
  mpModelNameTextBox = new QLineEdit(name);
  mpModelNameLabel = new Label(tr("New Name:"));
  // Create the buttons
  mpOkButton = new QPushButton(Helper::rename);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(renameClass()));
  mpCancelButton = new QPushButton(tr("&Cancel"));
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *mainLayout = new QGridLayout;
  mainLayout->addWidget(mpModelNameLabel, 0, 0);
  mainLayout->addWidget(mpModelNameTextBox, 1, 0);
  mainLayout->addWidget(mpButtonBox, 2, 0);
  setLayout(mainLayout);
}

/*!
  Renames the Modelica class.\n
  Slot activated when mpOkButton clicked signal is raised.
  */
void RenameClassDialog::renameClass()
{
  QString newName = mpModelNameTextBox->text().trimmed();
  QString newNameStructure;
  // if no change in the name then return
  if (newName == mName)
  {
    accept();
    return;
  }

  if (!MainWindow::instance()->getOMCProxy()->existClass(QString(StringHandler::removeLastWordAfterDot(mNameStructure)).append(".").append(newName)))
  {
    if (MainWindow::instance()->getOMCProxy()->renameClass(mNameStructure, newName))
    {
      newNameStructure = StringHandler::removeFirstLastCurlBrackets(MainWindow::instance()->getOMCProxy()->getResult());
      // Change the name in tree
      //mpParentMainWindow->mpLibrary->updateNodeText(newName, newNameStructure);
      accept();
    }
    else
    {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).arg(MainWindow::instance()->getOMCProxy()->getResult())
                            .append("\n\n").append(GUIMessages::getMessage(GUIMessages::NO_OPENMODELICA_KEYWORDS)), Helper::ok);
      return;
    }
  }
  else
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS).append("\n\n")
                          .append(GUIMessages::getMessage(GUIMessages::NO_OPENMODELICA_KEYWORDS)), Helper::ok);
    return;
  }
}

/*!
 * \class InformationDialog
 * \brief Creates a dialog that shows the users the result of OMCProxy::instantiateModel and OMCProxy::checkModel.
 */
/*!
 * \brief InformationDialog::InformationDialog
 * \param windowTitle - title string for dialog
 * \param informationText - main text string for dialog
 * \param modelicaTextHighlighter - highlights the modelica code.
 * \param pParent
 */
InformationDialog::InformationDialog(QString windowTitle, QString informationText, bool modelicaTextHighlighter, QWidget *pParent)
  : QWidget(pParent, Qt::Window)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(windowTitle));
  // instantiate the model
  TextEditor *pTextEditor = new TextEditor(pParent);
  pTextEditor->setPlainText(informationText);
  if (modelicaTextHighlighter) {
    ModelicaHighlighter *pModelicaHighlighter = new ModelicaHighlighter(OptionsDialog::instance()->getModelicaEditorPage(),
                                                                        pTextEditor->getPlainTextEdit());
    Q_UNUSED(pModelicaHighlighter);
  }
  // Create the button
  QPushButton *pOkButton = new QPushButton(Helper::ok);
  connect(pOkButton, SIGNAL(clicked()), SLOT(close()));
  // set layout
  QHBoxLayout *buttonLayout = new QHBoxLayout;
  buttonLayout->setAlignment(Qt::AlignRight);
  buttonLayout->addWidget(pOkButton);
  QVBoxLayout *mainLayout = new QVBoxLayout;
  mainLayout->addWidget(pTextEditor);
  mainLayout->addLayout(buttonLayout);
  setLayout(mainLayout);
  pOkButton->setFocus();
  /* restore the window geometry. */
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations()) {
    QSettings *pSettings = Utilities::getApplicationSettings();
    restoreGeometry(pSettings->value("InformationDialog/geometry").toByteArray());
  }
}

/*!
 * \brief InformationDialog::closeEvent
 * Saves the widgets geometry.
 * \param event
 */
void InformationDialog::closeEvent(QCloseEvent *event)
{
  /* save the window geometry. */
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations()) {
    QSettings *pSettings = Utilities::getApplicationSettings();
    pSettings->setValue("InformationDialog/geometry", saveGeometry());
  }
  event->accept();
}

/*!
 * \brief InformationDialog::keyPressEvent
 * Closes the widget when Esc key is pressed.
 * \param event
 */
void InformationDialog::keyPressEvent(QKeyEvent *event)
{
  if (event->key() == Qt::Key_Escape) {
    close();
    return;
  }
  QWidget::keyPressEvent(event);
}

/*!
 * \class GraphicsViewProperties
 * \brief Creates a dialog that shows the icon/diagram GraphicsView properties.
 */
/*!
 * \brief GraphicsViewProperties::GraphicsViewProperties
 * \param pGraphicsView - pointer to GraphicsView
 */
GraphicsViewProperties::GraphicsViewProperties(GraphicsView *pGraphicsView)
  : QDialog(pGraphicsView)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::properties).append(" - ")
                 .append(pGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure()));
  setMinimumWidth(400);
  mpGraphicsView = pGraphicsView;
  // tab widget
  mpTabWidget = new QTabWidget;
  // graphics tab
  QWidget *pGraphicsWidget = new QWidget;
  // create extent points group box
  mpExtentGroupBox = new QGroupBox(Helper::extent);
  mpLeftLabel = new Label(QString(Helper::left).append(":"));
  mpLeftSpinBox = new DoubleSpinBox;
  mpLeftSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpLeftSpinBox->setValue(mpGraphicsView->mCoOrdinateSystem.getExtent().at(0).x());
  mpLeftSpinBox->setSingleStep(10);
  mpBottomLabel = new Label(Helper::bottom);
  mpBottomSpinBox = new DoubleSpinBox;
  mpBottomSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpBottomSpinBox->setValue(mpGraphicsView->mCoOrdinateSystem.getExtent().at(0).y());
  mpBottomSpinBox->setSingleStep(10);
  mpRightLabel = new Label(QString(Helper::right).append(":"));
  mpRightSpinBox = new DoubleSpinBox;
  mpRightSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpRightSpinBox->setValue(mpGraphicsView->mCoOrdinateSystem.getExtent().at(1).x());
  mpRightSpinBox->setSingleStep(10);
  mpTopLabel = new Label(Helper::top);
  mpTopSpinBox = new DoubleSpinBox;
  mpTopSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpTopSpinBox->setValue(mpGraphicsView->mCoOrdinateSystem.getExtent().at(1).y());
  mpTopSpinBox->setSingleStep(10);
  // set the extent group box layout
  QGridLayout *pExtentLayout = new QGridLayout;
  pExtentLayout->setColumnStretch(1, 1);
  pExtentLayout->setColumnStretch(3, 1);
  pExtentLayout->addWidget(mpLeftLabel, 0, 0);
  pExtentLayout->addWidget(mpLeftSpinBox, 0, 1);
  pExtentLayout->addWidget(mpBottomLabel, 0, 2);
  pExtentLayout->addWidget(mpBottomSpinBox, 0, 3);
  pExtentLayout->addWidget(mpRightLabel, 1, 0);
  pExtentLayout->addWidget(mpRightSpinBox, 1, 1);
  pExtentLayout->addWidget(mpTopLabel, 1, 2);
  pExtentLayout->addWidget(mpTopSpinBox, 1, 3);
  mpExtentGroupBox->setLayout(pExtentLayout);
  // create the grid group box
  mpGridGroupBox = new QGroupBox(Helper::grid);
  mpHorizontalLabel = new Label(QString(Helper::horizontal).append(":"));
  mpHorizontalSpinBox = new DoubleSpinBox;
  mpHorizontalSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpHorizontalSpinBox->setValue(mpGraphicsView->mCoOrdinateSystem.getGrid().x());
  mpHorizontalSpinBox->setSingleStep(1);
  mpVerticalLabel = new Label(QString(Helper::vertical).append(":"));
  mpVerticalSpinBox = new DoubleSpinBox;
  mpVerticalSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpVerticalSpinBox->setValue(mpGraphicsView->mCoOrdinateSystem.getGrid().y());
  mpVerticalSpinBox->setSingleStep(1);
  // set the grid group box layout
  QGridLayout *pGridLayout = new QGridLayout;
  pGridLayout->setColumnStretch(1, 1);
  pGridLayout->addWidget(mpHorizontalLabel, 0, 0);
  pGridLayout->addWidget(mpHorizontalSpinBox, 0, 1);
  pGridLayout->addWidget(mpVerticalLabel, 1, 0);
  pGridLayout->addWidget(mpVerticalSpinBox, 1, 1);
  mpGridGroupBox->setLayout(pGridLayout);
  // create the Component group box
  mpComponentGroupBox = new QGroupBox(Helper::component);
  mpScaleFactorLabel = new Label(Helper::scaleFactor);
  mpScaleFactorSpinBox = new DoubleSpinBox;
  mpScaleFactorSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpScaleFactorSpinBox->setValue(mpGraphicsView->mCoOrdinateSystem.getInitialScale());
  mpScaleFactorSpinBox->setSingleStep(0.1);
  mpPreserveAspectRatioCheckBox = new QCheckBox(Helper::preserveAspectRatio);
  mpPreserveAspectRatioCheckBox->setChecked(mpGraphicsView->mCoOrdinateSystem.getPreserveAspectRatio());
  // set the grid group box layout
  QGridLayout *pComponentLayout = new QGridLayout;
  pComponentLayout->setColumnStretch(1, 1);
  pComponentLayout->addWidget(mpScaleFactorLabel, 0, 0);
  pComponentLayout->addWidget(mpScaleFactorSpinBox, 0, 1);
  pComponentLayout->addWidget(mpPreserveAspectRatioCheckBox, 1, 0, 1, 2);
  mpComponentGroupBox->setLayout(pComponentLayout);
  // copy properties check box
  mpCopyProperties = new QCheckBox;
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpCopyProperties->setText(tr("Copy properties to Diagram layer"));
  } else {
    mpCopyProperties->setText(tr("Copy properties to Icon layer"));
  }
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations() &&
      Utilities::getApplicationSettings()->contains("GraphicsViewProperties/copyProperties")) {
    mpCopyProperties->setChecked(Utilities::getApplicationSettings()->value("GraphicsViewProperties/copyProperties").toBool());
  } else {
    mpCopyProperties->setChecked(true);
  }
  // Graphics tab layout
  QVBoxLayout *pGraphicsWidgetLayout = new QVBoxLayout;
  pGraphicsWidgetLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pGraphicsWidgetLayout->addWidget(mpExtentGroupBox);
  pGraphicsWidgetLayout->addWidget(mpGridGroupBox);
  pGraphicsWidgetLayout->addWidget(mpComponentGroupBox);
  pGraphicsWidgetLayout->addWidget(mpCopyProperties);
  pGraphicsWidget->setLayout(pGraphicsWidgetLayout);
  mpTabWidget->addTab(pGraphicsWidget, tr("Graphics"));
  // version tab
  QWidget *pVersionWidget = new QWidget;
  mpVersionLabel = new Label(Helper::version);
  mpVersionTextBox = new QLineEdit(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->mClassInformation.version);
  // uses annotation
  mpUsesGroupBox = new QGroupBox(tr("Uses"));
  mpUsesTableWidget = new QTableWidget;
  mpUsesTableWidget->setTextElideMode(Qt::ElideMiddle);
  mpUsesTableWidget->setSelectionBehavior(QAbstractItemView::SelectRows);
  mpUsesTableWidget->setSelectionMode(QAbstractItemView::SingleSelection);
  mpUsesTableWidget->setColumnCount(2);
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
  mpUsesTableWidget->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);
#else /* Qt4 */
  mpUsesTableWidget->horizontalHeader()->setResizeMode(QHeaderView::Stretch);
#endif
  mpUsesTableWidget->horizontalHeader()->setDefaultAlignment(Qt::AlignLeft);
  QStringList headerLabels;
  headerLabels << Helper::library << Helper::version;
  mpUsesTableWidget->setHorizontalHeaderLabels(headerLabels);
  // get the uses annotation
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  mUsesAnnotation = pOMCProxy->getUses(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure());
  mpUsesTableWidget->setRowCount(mUsesAnnotation.size());
  for (int i = 0 ; i < mUsesAnnotation.size() ; i++) {
    QTableWidgetItem *pLibraryTableWidgetItem = new QTableWidgetItem(mUsesAnnotation.at(i).at(0));
    pLibraryTableWidgetItem->setFlags(pLibraryTableWidgetItem->flags() | Qt::ItemIsEditable);
    mpUsesTableWidget->setItem(i, 0, pLibraryTableWidgetItem);
    QTableWidgetItem *pVersionTableWidgetItem = new QTableWidgetItem(mUsesAnnotation.at(i).at(1));
    pVersionTableWidgetItem->setFlags(pVersionTableWidgetItem->flags() | Qt::ItemIsEditable);
    mpUsesTableWidget->setItem(i, 1, pVersionTableWidgetItem);
  }
  // uses navigation buttons
  mpMoveUpButton = new QToolButton;
  mpMoveUpButton->setObjectName("ShapePointsButton");
  mpMoveUpButton->setIcon(QIcon(":/Resources/icons/up.svg"));
  mpMoveUpButton->setToolTip(Helper::moveUp);
  connect(mpMoveUpButton, SIGNAL(clicked()), SLOT(moveUp()));
  mpMoveDownButton = new QToolButton;
  mpMoveDownButton->setObjectName("ShapePointsButton");
  mpMoveDownButton->setIcon(QIcon(":/Resources/icons/down.svg"));
  mpMoveDownButton->setToolTip(Helper::moveDown);
  connect(mpMoveDownButton, SIGNAL(clicked()), SLOT(moveDown()));
  // uses manipulation buttons
  mpAddUsesAnnotationButton = new QToolButton;
  mpAddUsesAnnotationButton->setObjectName("ShapePointsButton");
  mpAddUsesAnnotationButton->setIcon(QIcon(":/Resources/icons/add-icon.svg"));
  mpAddUsesAnnotationButton->setToolTip(tr("Add new uses annotation"));
  connect(mpAddUsesAnnotationButton, SIGNAL(clicked()), SLOT(addUsesAnnotation()));
  mpRemoveUsesAnnotationButton = new QToolButton;
  mpRemoveUsesAnnotationButton->setObjectName("ShapePointsButton");
  mpRemoveUsesAnnotationButton->setIcon(QIcon(":/Resources/icons/delete.svg"));
  mpRemoveUsesAnnotationButton->setToolTip(tr("Remove uses annotation"));
  connect(mpRemoveUsesAnnotationButton, SIGNAL(clicked()), SLOT(removeUsesAnnotation()));
  mpUsesButtonBox = new QDialogButtonBox(Qt::Vertical);
  mpUsesButtonBox->addButton(mpMoveUpButton, QDialogButtonBox::ActionRole);
  mpUsesButtonBox->addButton(mpMoveDownButton, QDialogButtonBox::ActionRole);
  mpUsesButtonBox->addButton(mpAddUsesAnnotationButton, QDialogButtonBox::ActionRole);
  mpUsesButtonBox->addButton(mpRemoveUsesAnnotationButton, QDialogButtonBox::ActionRole);
  // uses Group Box layout
  QGridLayout *pUsesGroupBoxLayout = new QGridLayout;
  pUsesGroupBoxLayout->setAlignment(Qt::AlignTop);
  pUsesGroupBoxLayout->setColumnStretch(0, 1);
  pUsesGroupBoxLayout->addWidget(mpUsesTableWidget, 0, 0);
  pUsesGroupBoxLayout->addWidget(mpUsesButtonBox, 0, 1);
  mpUsesGroupBox->setLayout(pUsesGroupBoxLayout);
  // Version tab layout
  QGridLayout *pVersionGridLayout = new QGridLayout;
  pVersionGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pVersionGridLayout->addWidget(mpVersionLabel, 0, 0);
  pVersionGridLayout->addWidget(mpVersionTextBox, 0, 1);
  pVersionGridLayout->addWidget(mpUsesGroupBox, 1, 0, 1, 2);
  pVersionWidget->setLayout(pVersionGridLayout);
  mpTabWidget->addTab(pVersionWidget, Helper::version);
  if (!mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isTopLevel()) {
    mpTabWidget->setTabEnabled(1, false);
  }
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(saveGraphicsViewProperties()));
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() || mpGraphicsView->isVisualizationView()) {
    mpOkButton->setDisabled(true);
  }
  mpCancelButton = new QPushButton(Helper::cancel);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addWidget(mpTabWidget);
  pMainLayout->addWidget(mpButtonBox, 0, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief GraphicsViewProperties::movePointUp
 * Moves the uses annotation up.\n
 */
void GraphicsViewProperties::moveUp()
{
  if (mpUsesTableWidget->selectedItems().size() > 0) {
    int row = mpUsesTableWidget->selectedItems().at(0)->row();
    if (row == 0) {
      return;
    }
    QTableWidgetItem *pSourceLibraryItem = mpUsesTableWidget->takeItem(row, 0);
    QTableWidgetItem *pSourceVersionItem = mpUsesTableWidget->takeItem(row, 1);
    QTableWidgetItem *pDestinationLibraryItem = mpUsesTableWidget->takeItem(row - 1, 0);
    QTableWidgetItem *pDestinationVersionItem = mpUsesTableWidget->takeItem(row - 1, 1);
    mpUsesTableWidget->setItem(row - 1, 0, pSourceLibraryItem);
    mpUsesTableWidget->setItem(row - 1, 1, pSourceVersionItem);
    mpUsesTableWidget->setItem(row, 0, pDestinationLibraryItem);
    mpUsesTableWidget->setItem(row, 1, pDestinationVersionItem);
    mpUsesTableWidget->setCurrentCell(row - 1, 0);
  }
}

/*!
 * \brief GraphicsViewProperties::movePointDown
 * Moves the uses annotation down.\n
 */
void GraphicsViewProperties::moveDown()
{
  if (mpUsesTableWidget->selectedItems().size() > 0) {
    int row = mpUsesTableWidget->selectedItems().at(0)->row();
    if (row == mpUsesTableWidget->rowCount() - 1) {
      return;
    }
    QTableWidgetItem *pSourceLibraryItem = mpUsesTableWidget->takeItem(row, 0);
    QTableWidgetItem *pSourceVersionItem = mpUsesTableWidget->takeItem(row, 1);
    QTableWidgetItem *pDestinationLibraryItem = mpUsesTableWidget->takeItem(row + 1, 0);
    QTableWidgetItem *pDestinationVersionItem = mpUsesTableWidget->takeItem(row + 1, 1);
    mpUsesTableWidget->setItem(row + 1, 0, pSourceLibraryItem);
    mpUsesTableWidget->setItem(row + 1, 1, pSourceVersionItem);
    mpUsesTableWidget->setItem(row, 0, pDestinationLibraryItem);
    mpUsesTableWidget->setItem(row, 1, pDestinationVersionItem);
    mpUsesTableWidget->setCurrentCell(row + 1, 0);
  }
}

/*!
 * \brief GraphicsViewProperties::addUsesAnnotation
 * Adds a new row for uses annotation.
 */
void GraphicsViewProperties::addUsesAnnotation()
{
  int row = mpUsesTableWidget->rowCount();
  if (mpUsesTableWidget->selectedItems().size() > 0) {
    row = mpUsesTableWidget->selectedItems().at(0)->row() + 1;
  }
  mpUsesTableWidget->insertRow(row);
  QTableWidgetItem *pLibraryTableWidgetItem = new QTableWidgetItem("");
  pLibraryTableWidgetItem->setFlags(pLibraryTableWidgetItem->flags() | Qt::ItemIsEditable);
  mpUsesTableWidget->setItem(row, 0, pLibraryTableWidgetItem);
  QTableWidgetItem *pVersionTableWidgetItem = new QTableWidgetItem("");
  pVersionTableWidgetItem->setFlags(pVersionTableWidgetItem->flags() | Qt::ItemIsEditable);
  mpUsesTableWidget->setItem(row, 1, pVersionTableWidgetItem);
}

/*!
 * \brief GraphicsViewProperties::removeUsesAnnotation
 * Removes the selected uses annotaton row.
 */
void GraphicsViewProperties::removeUsesAnnotation()
{
  if (mpUsesTableWidget->selectedItems().size() > 0) {
    mpUsesTableWidget->removeRow(mpUsesTableWidget->selectedItems().at(0)->row());
  }
}

/*!
 * \brief GraphicsViewProperties::saveGraphicsViewProperties
 * Saves the new GraphicsView properties in the form of coordinate system annotation.\n
 * Slot activated when mpOkButton clicked signal is raised.
 */
void GraphicsViewProperties::saveGraphicsViewProperties()
{
  // we need to set focus on the OK button otherwise QTableWidget doesn't read any active cell editing value.
  mpOkButton->setFocus(Qt::ActiveWindowFocusReason);
  MainWindow *pMainWindow = MainWindow::instance();
  // validate uses
  for (int i = 0 ; i < mpUsesTableWidget->rowCount() ; i++) {
    QTableWidgetItem *pUsesTableWidgetItem = mpUsesTableWidget->item(i, 0); /* library value */
    if (pUsesTableWidgetItem->text().isEmpty()) {
      QMessageBox::critical(pMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg(Helper::library), Helper::ok);
      mpUsesTableWidget->editItem(pUsesTableWidgetItem);
      return;
    }
    pUsesTableWidgetItem = mpUsesTableWidget->item(i, 1); /* version value */
    if (pUsesTableWidgetItem->text().isEmpty()) {
      QMessageBox::critical(pMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg(Helper::version), Helper::ok);
      mpUsesTableWidget->editItem(pUsesTableWidgetItem);
      return;
    }
  }
  // save the old CoOrdinateSystem
  CoOrdinateSystem oldCoOrdinateSystem = mpGraphicsView->mCoOrdinateSystem;
  // construct a new CoOrdinateSystem
  CoOrdinateSystem newCoOrdinateSystem;
  qreal left = qMin(mpLeftSpinBox->value(), mpRightSpinBox->value());
  qreal bottom = qMin(mpBottomSpinBox->value(), mpTopSpinBox->value());
  qreal right = qMax(mpLeftSpinBox->value(), mpRightSpinBox->value());
  qreal top = qMax(mpBottomSpinBox->value(), mpTopSpinBox->value());
  QList<QPointF> extent;
  extent << QPointF(left, bottom) << QPointF(right, top);
  newCoOrdinateSystem.setExtent(extent);
  newCoOrdinateSystem.setPreserveAspectRatio(mpPreserveAspectRatioCheckBox->isChecked());
  newCoOrdinateSystem.setInitialScale(mpScaleFactorSpinBox->value());
  qreal horizontal = mpHorizontalSpinBox->value();
  qreal vertical = mpVerticalSpinBox->value();
  newCoOrdinateSystem.setGrid(QPointF(horizontal, vertical));
  newCoOrdinateSystem.setValid(true);
  // save old version
  QString oldVersion = mpGraphicsView->getModelWidget()->getLibraryTreeItem()->mClassInformation.version;
  // save the old uses annotation
  QStringList oldUsesAnnotation;
  for (int i = 0 ; i < mUsesAnnotation.size() ; i++) {
    oldUsesAnnotation.append(QString("%1(version=\"%2\")").arg(mUsesAnnotation.at(i).at(0)).arg(mUsesAnnotation.at(i).at(1)));
  }
  QString oldUsesAnnotationString = QString("annotate=$annotation(uses(%1))").arg(oldUsesAnnotation.join(","));
  // new uses annotation
  QStringList newUsesAnnotation;
  for (int i = 0 ; i < mpUsesTableWidget->rowCount() ; i++) {
    newUsesAnnotation.append(QString("%1(version=\"%2\")").arg(mpUsesTableWidget->item(i, 0)->text()).arg(mpUsesTableWidget->item(i, 1)->text()));
  }
  QString newUsesAnnotationString = QString("annotate=$annotation(uses(%1))").arg(newUsesAnnotation.join(","));

  // push the CoOrdinateSystem change to undo stack
  UpdateCoOrdinateSystemCommand *pUpdateCoOrdinateSystemCommand;
  pUpdateCoOrdinateSystemCommand = new UpdateCoOrdinateSystemCommand(mpGraphicsView, oldCoOrdinateSystem, newCoOrdinateSystem,
                                                                     mpCopyProperties->isChecked(), oldVersion, mpVersionTextBox->text(),
                                                                     oldUsesAnnotationString, newUsesAnnotationString);
  mpGraphicsView->getModelWidget()->getUndoStack()->push(pUpdateCoOrdinateSystemCommand);
  mpGraphicsView->getModelWidget()->updateModelText();
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations()) {
    Utilities::getApplicationSettings()->setValue("GraphicsViewProperties/copyProperties", mpCopyProperties->isChecked());
  }
  accept();
}

/*!
 * \class SaveChangesDialog
 * \brief Creates a dialog that shows the list of unsaved Modelica classes.
 */
/*!
 * \brief SaveChangesDialog::SaveChangesDialog
 * \param pParent
 */
SaveChangesDialog::SaveChangesDialog(QWidget *pParent)
  : QDialog(pParent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Save Changes")));
  setMinimumWidth(400);
  mpSaveChangesLabel = new Label(tr("Save changes to the following classes?"));
  mpUnsavedClassesListWidget = new QListWidget;
  mpUnsavedClassesListWidget->setObjectName("UnsavedClassesListWidget");
  mpUnsavedClassesListWidget->setItemDelegate(new ItemDelegate(mpUnsavedClassesListWidget));
  mpUnsavedClassesListWidget->setSelectionMode(QAbstractItemView::ExtendedSelection);
  // Create the buttons
  // create the Yes button
  mpYesButton = new QPushButton(tr("Yes"));
  mpYesButton->setAutoDefault(true);
  connect(mpYesButton, SIGNAL(clicked()), SLOT(saveChanges()));
  // create the No button
  mpNoButton = new QPushButton(tr("No"));
  mpNoButton->setAutoDefault(false);
  connect(mpNoButton, SIGNAL(clicked()), SLOT(accept()));
  // create the Cancel button
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpYesButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpNoButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // create a main layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpSaveChangesLabel);
  pMainLayout->addWidget(mpUnsavedClassesListWidget);
  pMainLayout->addWidget(mpButtonBox, 0, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief SaveChangesDialog::listUnSavedClasses
 * Lists the unsaved Modelica classes.
 */
void SaveChangesDialog::listUnSavedClasses()
{
  listUnSavedClasses(MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->getRootLibraryTreeItem());
  mpUnsavedClassesListWidget->selectAll();
}

/*!
 * \brief SaveChangesDialog::listUnSavedClasses
 * \param LibraryTreeItem
 * Helper function for SaveChangesDialog::listUnSavedClasses()
 */
void SaveChangesDialog::listUnSavedClasses(LibraryTreeItem *pLibraryTreeItem)
{
  for (int i = 0; i < pLibraryTreeItem->childrenSize(); i++) {
    LibraryTreeItem *pChildLibraryTreeItem = pLibraryTreeItem->child(i);
    if (pChildLibraryTreeItem && !pChildLibraryTreeItem->isSystemLibrary()) {
      if (!pChildLibraryTreeItem->isSaved()) {
        QListWidgetItem *pListItem = new QListWidgetItem(mpUnsavedClassesListWidget);
        if (pChildLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
          pListItem->setText(pChildLibraryTreeItem->getNameStructure());
        } else {
          pListItem->setText(pChildLibraryTreeItem->getName());
        }
      } else {
        listUnSavedClasses(pChildLibraryTreeItem);
      }
    }
  }
}

/*!
 * \brief SaveChangesDialog::saveChanges
 * Saves the unsaved classes. \n
 * Slot activated when mpYesButton clicked signal is raised.
 */
void SaveChangesDialog::saveChanges()
{
  bool saveResult = true;
  for (int i = 0; i < mpUnsavedClassesListWidget->count(); i++) {
    QListWidgetItem *pListItem = mpUnsavedClassesListWidget->item(i);
    LibraryTreeItem *pLibraryTreeItem;
    pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(pListItem->text());
    if (pLibraryTreeItem && !MainWindow::instance()->getLibraryWidget()->saveLibraryTreeItem(pLibraryTreeItem)) {
      saveResult = false;
    }
  }
  if (saveResult) {
    accept();
  } else {
    reject();
  }
}

/*!
 * \brief SaveChangesDialog::exec
 * Reimplementation of exec.
 * \return
 */
int SaveChangesDialog::exec()
{
  listUnSavedClasses();
  if (mpUnsavedClassesListWidget->count() == 0) {
    return 1;
  }
  return QDialog::exec();
}

/*!
 * \class ExportFigaroDialog
 * \brief Creates a dialog for Figaro export.
 */
/*!
 * \brief ExportFigaroDialog::ExportFigaroDialog
 * \param ppLibraryTreeItem
 * \param pParent
 */
ExportFigaroDialog::ExportFigaroDialog(LibraryTreeItem *ppLibraryTreeItem, QWidget *pParent)
  : QDialog(pParent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::exportFigaro));
  mpLibraryTreeItem = ppLibraryTreeItem;
  // figaro mode
  mpFigaroModeLabel = new Label(tr("Figaro Mode:"));
  mpFigaroModeComboBox = new QComboBox;
  mpFigaroModeComboBox->addItem("figaro0", "figaro0");
  mpFigaroModeComboBox->addItem("fault-tree", "fault-tree");
  // working directory
  mpWorkingDirectoryLabel = new Label(Helper::workingDirectory);
  mpWorkingDirectoryTextBox = new QLineEdit(Utilities::tempDirectory());
  mpWorkingDirectoryBrowseButton = new QPushButton(Helper::browse);
  connect(mpWorkingDirectoryBrowseButton, SIGNAL(clicked()), SLOT(browseWorkingDirectory()));
  // create the export button
  mpExportFigaroButton = new QPushButton(Helper::exportFigaro);
  mpExportFigaroButton->setAutoDefault(true);
  connect(mpExportFigaroButton, SIGNAL(clicked()), SLOT(exportModelFigaro()));
  // create the cancel button
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpExportFigaroButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // layout
  QGridLayout *pMainGridLayout = new QGridLayout;
  pMainGridLayout->setAlignment(Qt::AlignTop);
  pMainGridLayout->addWidget(mpFigaroModeLabel, 0, 0);
  pMainGridLayout->addWidget(mpFigaroModeComboBox, 0, 1, 1, 2);
  pMainGridLayout->addWidget(mpWorkingDirectoryLabel, 1, 0);
  pMainGridLayout->addWidget(mpWorkingDirectoryTextBox, 1, 1);
  pMainGridLayout->addWidget(mpWorkingDirectoryBrowseButton, 1, 2);
  pMainGridLayout->addWidget(mpButtonBox, 2, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainGridLayout);
}

void ExportFigaroDialog::browseWorkingDirectory()
{
  mpWorkingDirectoryTextBox->setText(StringHandler::getExistingDirectory(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseDirectory), NULL));
}

void ExportFigaroDialog::exportModelFigaro()
{
  // set the status message.
  MainWindow::instance()->getStatusBar()->showMessage(tr("Exporting model as Figaro"));
  // show the progress bar
  MainWindow::instance()->getProgressBar()->setRange(0, 0);
  MainWindow::instance()->showProgressBar();
  FigaroPage *pFigaroPage = OptionsDialog::instance()->getFigaroPage();
  QString directory = mpWorkingDirectoryTextBox->text();
  QString library = pFigaroPage->getFigaroDatabaseFileTextBox()->text();
  QString mode = mpFigaroModeComboBox->currentText();
  QString options = pFigaroPage->getFigaroOptionsTextBox()->text();
  QString processor = pFigaroPage->getFigaroProcessTextBox()->text();
  if (MainWindow::instance()->getOMCProxy()->exportToFigaro(mpLibraryTreeItem->getNameStructure(), directory, library, mode, options, processor)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::FIGARO_GENERATED),
                                                          Helper::scriptingKind, Helper::notificationLevel));
  }
  // hide progress bar
  MainWindow::instance()->hideProgressBar();
  // clear the status bar message
  MainWindow::instance()->getStatusBar()->clearMessage();
  accept();
}

/*!
 * \class CreateNewItemDialog
 * \brief Creates a dialog to allow users to create new file/folder.
 */
/*!
 * \brief CreateNewItemDialog::CreateNewItemDialog
 * \param path
 * \param isCreateFile
 * \param pParent
 */
CreateNewItemDialog::CreateNewItemDialog(QString path, bool isCreateFile, QWidget *pParent)
  : QDialog(pParent), mPath(path), mIsCreateFile(isCreateFile)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - Create New %2").arg(Helper::applicationName).arg(mIsCreateFile ? Helper::file : Helper::folder));
  setMinimumWidth(400);
  // Create the name label and text box
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit;
  // Create the path label, text box, browse button
  mpPathLabel = new Label(Helper::path);
  mpPathTextBox = new QLineEdit(path);
  mpPathBrowseButton = new QPushButton(Helper::browse);
  mpPathBrowseButton->setAutoDefault(false);
  connect(mpPathBrowseButton, SIGNAL(clicked()), SLOT(browsePath()));
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(createNewFileOrFolder()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpNameLabel, 0, 0);
  pMainLayout->addWidget(mpNameTextBox, 0, 1, 1, 2);
  pMainLayout->addWidget(mpPathLabel, 1, 0);
  pMainLayout->addWidget(mpPathTextBox, 1, 1);
  pMainLayout->addWidget(mpPathBrowseButton, 1, 2);
  pMainLayout->addWidget(mpButtonBox, 2, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief CreateNewItemDialog::browsePath
 * Creates a new file/folder.\n
 * Slot activated when mpOkButton clicked signal is raised.
 */
void CreateNewItemDialog::browsePath()
{
  QString currentPath = mpPathTextBox->text();
  QString path = StringHandler::getExistingDirectory(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseDirectory),
                                                     currentPath.isEmpty() ? NULL : &currentPath);
  if (path.isEmpty()) {
    return;
  }
  mpPathTextBox->setText(path);
}

void CreateNewItemDialog::createNewFileOrFolder()
{
  // check name
  if (mpNameTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error), GUIMessages::getMessage(
                            GUIMessages::ENTER_NAME).arg(mIsCreateFile ? Helper::file : Helper::folder), Helper::ok);
    return;
  }
  // check path
  if (mpPathTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error), tr("Please enter path."), Helper::ok);
    return;
  }
  // check if path exists
  QFileInfo pathInfo(mpPathTextBox->text());
  if (!pathInfo.exists()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                          tr("Path <b>%1</b> does not exist.").arg(mpPathTextBox->text()), Helper::ok);
    return;
  }
  // check if file/folder already exists
  QString fileOrFolderPath = QString("%1/%2").arg(mpPathTextBox->text()).arg(mpNameTextBox->text());
  QFileInfo fileInfo(fileOrFolderPath);
  if (fileInfo.exists()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                          GUIMessages::getMessage(GUIMessages::MODEL_ALREADY_EXISTS).arg(mIsCreateFile ? Helper::file : Helper::folder)
                          .arg(mpNameTextBox->text()).arg(mpPathTextBox->text()), Helper::ok);
    return;
  }
  // find the LibraryTreeItem based on path
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pParentLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(mpPathTextBox->text());
  if (!pParentLibraryTreeItem) {
    pParentLibraryTreeItem = pLibraryTreeModel->getRootLibraryTreeItem();
  }
  // create file
  bool success = false;
  if (mIsCreateFile) {
    success = MainWindow::instance()->getLibraryWidget()->saveFile(fileOrFolderPath, "");
  } else {
    QDir directory(mpPathTextBox->text());
    success = directory.mkdir(mpNameTextBox->text());
  }
  // if file or folder creation is successful.
  if (success) {
    // find insertion index for new file or folder
    int row = -1;
    QDir directory(mpPathTextBox->text());
    QFileInfoList files = directory.entryInfoList(QDir::Dirs | QDir::Files | QDir::NoSymLinks | QDir::NoDotAndDotDot,
                                                  QDir::Name | QDir::DirsFirst | QDir::IgnoreCase);
    foreach (QFileInfo file, files) {
      row += 1;
      if (file.fileName().compare(mpNameTextBox->text()) == 0) {
        break;
      }
    }
    LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(LibraryTreeItem::Text, fileInfo.fileName(),
                                                                                 fileInfo.absoluteFilePath(), fileInfo.absoluteFilePath(),
                                                                                 true, pParentLibraryTreeItem, row);
    if (pLibraryTreeItem && mIsCreateFile) {
      pLibraryTreeModel->showModelWidget(pLibraryTreeItem);
    }
  }
  accept();
}

/*!
 * \class RenameItemDialog
 * \brief Creates a dialog to allow users to rename a file/folder.
 */
/*!
 * \brief RenameItemDialog::RenameItemDialog
 * \param pLibraryTreeItem
 * \param pParent
 */
RenameItemDialog::RenameItemDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent)
  : QDialog(pParent), mpLibraryTreeItem(pLibraryTreeItem)
{
  setAttribute(Qt::WA_DeleteOnClose);
  if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
    setWindowTitle(QString("%1 - %2 %3").arg(Helper::applicationName).arg(Helper::rename).arg(mpLibraryTreeItem->getNameStructure()));
  } else {
    setWindowTitle(QString("%1 - %2 %3").arg(Helper::applicationName).arg(Helper::rename).arg(mpLibraryTreeItem->getName()));
  }
  setMinimumWidth(400);
  // Create the name label and text box
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit(mpLibraryTreeItem->getName());
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(renameItem()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpNameLabel, 0, 0);
  pMainLayout->addWidget(mpNameTextBox, 0, 1);
  pMainLayout->addWidget(mpButtonBox, 1, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief RenameItemDialog::updateChildrenPath
 * Updates the file path of childrens rescursivly.
 * \param pLibraryTreeItem
 */
void RenameItemDialog::updateChildrenPath(LibraryTreeItem *pLibraryTreeItem)
{
  for (int i = 0 ; i < pLibraryTreeItem->childrenSize() ; i++) {
    LibraryTreeItem *pChildLibraryTreeItem = pLibraryTreeItem->child(i);
    QString newPath = QString("%1/%2").arg(pLibraryTreeItem->getFileName()).arg(pChildLibraryTreeItem->getName());
    pChildLibraryTreeItem->setNameStructure(newPath);
    pChildLibraryTreeItem->setFileName(newPath);
    if (pChildLibraryTreeItem->getModelWidget()) {
      pChildLibraryTreeItem->getModelWidget()->setModelFilePathLabel(newPath);
    }
    QFileInfo fileInfo(pChildLibraryTreeItem->getFileName());
    if (fileInfo.isDir()) {
      updateChildrenPath(pChildLibraryTreeItem);
    }
  }
}

/*!
 * \brief RenameItemDialog::renameItem
 * Renames a LibraryTreeItem.\n
 * Slot activated when mpOkButton clicked signal is raised.
 */
void RenameItemDialog::renameItem()
{
  // check name
  if (mpNameTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error), GUIMessages::getMessage(
                            GUIMessages::ENTER_NAME).arg(Helper::item), Helper::ok);
    return;
  }
  // if the name is same as old then simply return.
  if (mpNameTextBox->text().compare(mpLibraryTreeItem->getName()) == 0) {
    return;
  }
  if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Text) {
    // check if file/folder already exists
    QFileInfo oldFileInfo(mpLibraryTreeItem->getFileName());
    QString fileOrFolderPath = QString("%1/%2").arg(oldFileInfo.absoluteDir().absolutePath()).arg(mpNameTextBox->text());
    QFileInfo fileInfo(fileOrFolderPath);
    if (fileInfo.exists()) {

      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                            GUIMessages::getMessage(GUIMessages::MODEL_ALREADY_EXISTS).arg(Helper::item)
                            .arg(mpNameTextBox->text()).arg(fileInfo.absoluteDir().absolutePath()), Helper::ok);
      return;
    }
    if (QFile::rename(oldFileInfo.absoluteFilePath(), fileInfo.absoluteFilePath())) {
      mpLibraryTreeItem->setName(mpNameTextBox->text());
      mpLibraryTreeItem->setNameStructure(fileInfo.absoluteFilePath());
      mpLibraryTreeItem->setFileName(fileInfo.absoluteFilePath());
      if (mpLibraryTreeItem->getModelWidget()) {
        mpLibraryTreeItem->getModelWidget()->setModelFilePathLabel(fileInfo.absoluteFilePath());
        mpLibraryTreeItem->getModelWidget()->setWindowTitle(mpNameTextBox->text());
      }
      // if we have renamed a directory then we need to update the file paths of the nested files.
      if (fileInfo.isDir()) {
        updateChildrenPath(mpLibraryTreeItem);
      }
    }
  } else if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::CompositeModel) {
    if (mpLibraryTreeItem->getModelWidget()) {
      CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpLibraryTreeItem->getModelWidget()->getEditor());
      RenameCompositeModelCommand *pRenameCompositeModelCommand = new RenameCompositeModelCommand(pCompositeModelEditor,
                                                                                                  mpLibraryTreeItem->getName(),
                                                                                                  mpNameTextBox->text());
      mpLibraryTreeItem->getModelWidget()->getUndoStack()->push(pRenameCompositeModelCommand);
      mpLibraryTreeItem->getModelWidget()->updateModelText();
    }
  } else if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::OMS) {
    if (!mpLibraryTreeItem->getModelWidget()) {
      MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(mpLibraryTreeItem, false);
    }
    OMSRenameCommand *pOMSRenameCommand = new OMSRenameCommand(mpLibraryTreeItem, mpNameTextBox->text());
    mpLibraryTreeItem->getModelWidget()->getUndoStack()->push(pOMSRenameCommand);
    mpLibraryTreeItem->getModelWidget()->updateModelText();
  } else if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
    qDebug() << "Rename feature not implemented for Modelica library type.";
  } else {
    qDebug() << "Unable to rename, unknown library type.";
  }
  accept();
}

/*!
 * \class ComponentNameDialog
 * \brief Creates a dialog to allow users to specify a component name.
 */
/*!
 * \brief ComponentNameDialog::ComponentNameDialog
 * \param name
 * \param pGraphicsView
 * \param pParent
 */
ComponentNameDialog::ComponentNameDialog(QString name, GraphicsView *pGraphicsView, QWidget *pParent)
  : QDialog(pParent), mpGraphicsView(pGraphicsView)
{
  setWindowTitle(tr("%1 - Enter Component Name").arg(Helper::applicationName));
  setMinimumWidth(400);
  Label *pNoteLabel = new Label(tr("Please choose a meaningful name for this component, to improve the readability of simulation results."));
  pNoteLabel->setElideMode(Qt::ElideMiddle);
  // Create the name label and text box
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit(name);
  mpNameTextBox->selectAll();
  // don't show this message again checkbox.
  mpDontShowThisMessageAgainCheckBox = new QCheckBox(Helper::dontShowThisMessageAgain);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(updateComponentName()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(pNoteLabel, 0, 0, 1, 2);
  pMainLayout->addWidget(mpNameLabel, 1, 0);
  pMainLayout->addWidget(mpNameTextBox, 1, 1);
  QHBoxLayout *pHorizontalLayout = new QHBoxLayout;
  pHorizontalLayout->addWidget(mpDontShowThisMessageAgainCheckBox, 0, Qt::AlignLeft);
  pHorizontalLayout->addWidget(mpButtonBox, 0, Qt::AlignRight);
  pMainLayout->addLayout(pHorizontalLayout, 2, 0, 1, 2);
  setLayout(pMainLayout);
}

/*!
 * \brief ComponentNameDialog::updateComponentName
 * Specifies a name for a component.\n
 * Slot activated when mpOkButton clicked signal is raised.
 */
void ComponentNameDialog::updateComponentName()
{
  // check if name is empty
  if (mpNameTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error), GUIMessages::getMessage(
                            GUIMessages::ENTER_NAME).arg(Helper::item), Helper::ok);
    return;
  }
  // check for spaces
  if (StringHandler::containsSpace(mpNameTextBox->text())) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                          tr("A component name should not have spaces. Please choose another name."), Helper::ok);
    return;
  }
  // check for comma
  if (mpNameTextBox->text().contains(',')) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                          GUIMessages::getMessage(GUIMessages::INVALID_INSTANCE_NAME).arg(mpNameTextBox->text()), Helper::ok);
    return;
  }
  // check for existing component name
  if (!mpGraphicsView->checkComponentName(mpNameTextBox->text())) {
    QMessageBox::information(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName).arg(Helper::information),
                             GUIMessages::getMessage(GUIMessages::SAME_COMPONENT_NAME).arg(mpNameTextBox->text()), Helper::ok);
    return;
  }
  if (mpDontShowThisMessageAgainCheckBox->isChecked()) {
    QSettings *pSettings = Utilities::getApplicationSettings();
    pSettings->setValue("notifications/alwaysAskForDraggedComponentName", false);
    OptionsDialog::instance()->getNotificationsPage()->getAlwaysAskForDraggedComponentName()->setChecked(false);
  }
  // check for invalid names
  MainWindow::instance()->getOMCProxy()->setLoggingEnabled(false);
  QList<QString> result = MainWindow::instance()->getOMCProxy()->parseString(QString("model M N %1; end M;").arg(mpNameTextBox->text()),
                                                                             "M", false);
  MainWindow::instance()->getOMCProxy()->setLoggingEnabled(true);
  if (result.isEmpty()) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                          GUIMessages::getMessage(GUIMessages::INVALID_INSTANCE_NAME).arg(mpNameTextBox->text()), Helper::ok);
    return;
  }
  accept();
}
