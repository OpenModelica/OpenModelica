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

#include <QX11Info>

#include "ModelicaClassDialog.h"
#include "StringHandler.h"
#include "ModelWidgetContainer.h"

/*!
  \class ModelicaClassDialog
  \brief Creates a dialog to allow users to create new Modelica class restriction.
  */

/*!
  \param pParent - pointer to MainWindow
  */
ModelicaClassDialog::ModelicaClassDialog(MainWindow *pParent)
  : QDialog(pParent, Qt::WindowTitleHint)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::createNewModelicaClass));
  setMinimumWidth(400);
  mpMainWindow = pParent;
  setModal(true);
  // Create the name label and text box
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit;
  // Create the restriction label and combo box
  mpRestrictionLabel = new Label(tr("Restriction:"));
  mpRestrictionComboBox = new QComboBox;
  mpRestrictionComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Model));
  mpRestrictionComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Class));
  mpRestrictionComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Connector));
  mpRestrictionComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::ExpandableConnector));
  mpRestrictionComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Record));
  mpRestrictionComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Block));
  mpRestrictionComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Function));
  mpRestrictionComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Package));
  mpRestrictionComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Type));
  mpRestrictionComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::Operator));
  mpRestrictionComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::OperatorRecord));
  mpRestrictionComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::OperatorFunction));
  /* Don't add optimization restriction for now.
  mpRestrictionComboBox->addItem(StringHandler::getModelicaClassType(StringHandler::OPTIMIZATION));
  */
  connect(mpRestrictionComboBox, SIGNAL(currentIndexChanged(QString)), SLOT(showHideSaveContentsInOneFileCheckBox(QString)));
  // Create the parent package label, text box, browse button
  mpParentPackageLabel = new Label(tr("Insert in class (optional):"));
  mpParentClassComboBox = new QComboBox;
  mpParentClassComboBox->setEditable(true);
  /* Since the default QCompleter for QComboBox is case insenstive. */
  QCompleter *pParentClassComboBoxCompleter = mpParentClassComboBox->completer();
  pParentClassComboBoxCompleter->setCaseSensitivity(Qt::CaseSensitive);
  mpParentClassComboBox->setCompleter(pParentClassComboBoxCompleter);
  mpParentClassComboBox->addItem("");
  mpParentClassComboBox->addItems(mpMainWindow->getLibraryTreeWidget()->getNonSystemLibraryTreeNodeList());
  connect(mpParentClassComboBox, SIGNAL(editTextChanged(QString)), SLOT(showHideSaveContentsInOneFileCheckBox(QString)));
  // create partial checkbox
  mpPartialCheckBox = new QCheckBox(tr("Partial"));
  // create encapsulated checkbox
  mpEncapsulatedCheckBox = new QCheckBox(tr("Encapsulated"));
  // create save contents of package in one file checkbox
  mpSaveContentsInOneFileCheckBox = new QCheckBox(tr("Save contents in one file"));
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
  pMainLayout->addWidget(mpNameTextBox, 0, 1);
  pMainLayout->addWidget(mpRestrictionLabel, 1, 0);
  pMainLayout->addWidget(mpRestrictionComboBox, 1, 1);
  pMainLayout->addWidget(mpParentPackageLabel, 2, 0);
  pMainLayout->addWidget(mpParentClassComboBox, 2, 1);
  pMainLayout->addWidget(mpPartialCheckBox, 3, 0);
  pMainLayout->addWidget(mpSaveContentsInOneFileCheckBox, 3, 1);
  pMainLayout->addWidget(mpEncapsulatedCheckBox, 4, 0, 1, 2);
  pMainLayout->addWidget(mpButtonBox, 5, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

QComboBox *ModelicaClassDialog::getParentClassComboBox()
{
  return mpParentClassComboBox;
}

/*!
  Creates a new Modelica class restriction.\n
  Slot activated when mpOkButton clicked signal is raised.
  */
void ModelicaClassDialog::createModelicaClass()
{
  if (mpNameTextBox->text().isEmpty())
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                            GUIMessages::ENTER_NAME).arg(mpRestrictionComboBox->currentText()), Helper::ok);
    return;
  }

  if (!mpParentClassComboBox->currentText().isEmpty())
  {
    if (!mpMainWindow->getOMCProxy()->existClass(mpParentClassComboBox->currentText()))
    {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            tr("Insert in class <b>%1</b> does not exist.").arg(mpParentClassComboBox->currentText()), Helper::ok);
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
    parentPackage = QString("in Package '").append(mpParentClassComboBox->currentText()).append("'");
  }
  // Check whether model exists or not.
  if (mpMainWindow->getOMCProxy()->existClass(model))
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                            GUIMessages::MODEL_ALREADY_EXISTS).arg(mpRestrictionComboBox->currentText()).arg(model)
                          .arg(parentPackage), Helper::ok);
    return;
  }
  // create the model.
  QString modelicaClass = mpEncapsulatedCheckBox->isChecked() ? "encapsulated " : "";
  modelicaClass.append(mpPartialCheckBox->isChecked() ? "partial " : "");
  modelicaClass.append(mpRestrictionComboBox->currentText().toLower());
  if (mpParentClassComboBox->currentText().isEmpty())
  {
    if (!mpMainWindow->getOMCProxy()->createClass(modelicaClass, mpNameTextBox->text()))
    {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                              GUIMessages::ERROR_OCCURRED).arg(mpMainWindow->getOMCProxy()->getResult()).append("\n\n").
                            append(GUIMessages::getMessage(GUIMessages::NO_OPENMODELICA_KEYWORDS)), Helper::ok);
      return;
    }
  }
  else
  {
    if(!mpMainWindow->getOMCProxy()->createSubClass(modelicaClass, mpNameTextBox->text(), mpParentClassComboBox->currentText()))
    {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                              GUIMessages::ERROR_OCCURRED).arg(mpMainWindow->getOMCProxy()->getResult()).append("\n\n").
                            append(GUIMessages::getMessage(GUIMessages::NO_OPENMODELICA_KEYWORDS)), Helper::ok);
      return;
    }
  }
  //open the new tab in central widget and add the model to library tree.
  LibraryTreeWidget *pLibraryTree = mpMainWindow->getLibraryTreeWidget();
  LibraryTreeNode *pLibraryTreeNode;
  pLibraryTreeNode = pLibraryTree->addLibraryTreeNode(mpNameTextBox->text(),
                                                      StringHandler::getModelicaClassType(mpRestrictionComboBox->currentText()),
                                                      mpParentClassComboBox->currentText(), false);
  pLibraryTreeNode->setSaveContentsType(mpSaveContentsInOneFileCheckBox->isChecked() ? LibraryTreeNode::SaveInOneFile : LibraryTreeNode::SaveFolderStructure);
  pLibraryTree->addToExpandedLibraryTreeNodesList(pLibraryTreeNode);
  pLibraryTree->showModelWidget(pLibraryTreeNode, true);
  accept();
}

void ModelicaClassDialog::showHideSaveContentsInOneFileCheckBox(QString text)
{
  QComboBox *pComboBox = qobject_cast<QComboBox*>(sender());
  if (pComboBox)
  {
    if (pComboBox == mpRestrictionComboBox)
    {
      if ((text.toLower().compare("package") == 0) && mpParentClassComboBox->currentText().isEmpty())
        mpSaveContentsInOneFileCheckBox->setVisible(true);
      else
        mpSaveContentsInOneFileCheckBox->setVisible(false);
    }
    else if (pComboBox == mpParentClassComboBox)
    {
      if (text.isEmpty() && (mpRestrictionComboBox->currentText().toLower().compare("package") == 0))
        mpSaveContentsInOneFileCheckBox->setVisible(true);
      else
        mpSaveContentsInOneFileCheckBox->setVisible(false);
    }
  }
}

/*!
  \class OpenModelicaFile
  \brief Creates a dialog to allow users to open Modelica file(s).
  */

/*!
  \param pParent - pointer to MainWindow
  */
OpenModelicaFile::OpenModelicaFile(MainWindow *pParent)
  : QDialog(pParent, Qt::WindowTitleHint)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::openModelicaFile));
  setMinimumWidth(400);
  setModal(true);
  mpMainWindow = pParent;
  // create the File Label, textbox and browse button.
  mpFileLabel = new Label(Helper::file);
  mpFileTextBox = new QLineEdit;
  mpFileBrowseButton = new QPushButton(Helper::browse);
  connect(mpFileBrowseButton, SIGNAL(clicked()), SLOT(browseForFile()));
  // create the encoding label, textbox and encoding note.
  mpEncodingLabel = new Label(Helper::encoding);
  mpEncodingTextBox = new QLineEdit;
  mpEncodingNoteLabel = new Label(tr("* The default encoding value is UTF-8."));
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(openModelicaFile()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *mainLayout = new QGridLayout;
  mainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  mainLayout->addWidget(mpFileLabel, 0, 0);
  mainLayout->addWidget(mpFileTextBox, 0, 1);
  mainLayout->addWidget(mpFileBrowseButton, 0, 2);
  mainLayout->addWidget(mpEncodingLabel, 1, 0);
  mainLayout->addWidget(mpEncodingTextBox, 1, 1, 1, 2);
  mainLayout->addWidget(mpEncodingNoteLabel, 2, 0, 1, 3);
  mainLayout->addWidget(mpButtonBox, 3, 0, 1, 3, Qt::AlignRight);
  setLayout(mainLayout);
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
  Slot activated when mpOkButton clicked signal is raised.
  */
void OpenModelicaFile::openModelicaFile()
{
  int progressValue = 0;
  mpMainWindow->getProgressBar()->setRange(0, mFileNames.size());
  mpMainWindow->showProgressBar();
  foreach (QString file, mFileNames)
  {
    mpMainWindow->getStatusBar()->showMessage(QString(Helper::loading).append(": ").append(file));
    mpMainWindow->getProgressBar()->setValue(++progressValue);
    // if file doesn't exists
    if (!QFile::exists(file))
    {
      QMessageBox *pMessageBox = new QMessageBox(mpMainWindow);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
      pMessageBox->setIcon(QMessageBox::Critical);
      pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(file)));
      pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::FILE_NOT_FOUND).arg(file)));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
    }
    else
    {
      QString encoding;
      if (mpEncodingTextBox->text().isEmpty())
        encoding = Helper::utf8;
      else
        encoding = mpEncodingTextBox->text();
      mpMainWindow->getLibraryTreeWidget()->openFile(file, encoding, false);
    }
  }
  mpMainWindow->getStatusBar()->clearMessage();
  mpMainWindow->hideProgressBar();
  accept();
}

/*!
  \class RenameClassDialog
  \brief Creates a dialog to allow users to rename the Modelica class.
  */

/*!
  \param name - name of Modelica class
  \param nameStructure - qualified name of Modelica class
  \param pParent - pointer to MainWindow
  */
RenameClassDialog::RenameClassDialog(QString name, QString nameStructure, MainWindow *parent)
  : QDialog(parent, Qt::WindowTitleHint), mName(name), mNameStructure(nameStructure)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - Rename ").append(name));
  setMinimumSize(300, 100);
  setModal(true);
  mpMainWindow = parent;
  mpModelNameTextBox = new QLineEdit(name);
  mpModelNameLabel = new Label(tr("New Name:"));
  // Create the buttons
  mpOkButton = new QPushButton(tr("Rename"));
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

  if (!mpMainWindow->getOMCProxy()->existClass(QString(StringHandler::removeLastWordAfterDot(mNameStructure)).append(".").append(newName)))
  {
    if (mpMainWindow->getOMCProxy()->renameClass(mNameStructure, newName))
    {
      newNameStructure = StringHandler::removeFirstLastCurlBrackets(mpMainWindow->getOMCProxy()->getResult());
      // Change the name in tree
      //mpParentMainWindow->mpLibrary->updateNodeText(newName, newNameStructure);
      accept();
    }
    else
    {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).arg(mpMainWindow->getOMCProxy()->getResult())
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
  \class InformationDialog
  \brief Creates a dialog that shows the users the result of OMCProxy::instantiateModel and OMCProxy::checkModel.
  */

/*!
  \param windowTitle - title string for dialog
  \param informationText - main text string for dialog
  \param modelicaTextHighlighter - highlights the modelica code.
  \param pParent - pointer to MainWindow
  */
InformationDialog::InformationDialog(QString windowTitle, QString informationText, bool modelicaTextHighlighter, MainWindow *pMainWindow)
  : QDialog(pMainWindow, Qt::WindowTitleHint)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(windowTitle));
  setModal(true);
  // instantiate the model
  QPlainTextEdit *pPlainTextEdit = new QPlainTextEdit(informationText);
  if (modelicaTextHighlighter)
  {
    ModelicaTextHighlighter *pModelicaHighlighter = new ModelicaTextHighlighter(pMainWindow->getOptionsDialog()->getModelicaTextSettings(),
                                                                                pMainWindow, pPlainTextEdit->document());
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
  mainLayout->addWidget(pPlainTextEdit);
  mainLayout->addLayout(buttonLayout);
  setLayout(mainLayout);
}

/*!
  \class GraphicsViewProperties
  \brief Creates a dialog that shows the icon/diagram GraphicsView properties.
  */

/*!
  \param pGraphicsView - pointer to GraphicsView
  */
GraphicsViewProperties::GraphicsViewProperties(GraphicsView *pGraphicsView)
  : QDialog(pGraphicsView, Qt::WindowTitleHint)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::properties));
  setMinimumWidth(400);
  setModal(true);
  mpGraphicsView = pGraphicsView;
  // create extent points group box
  mpExtentGroupBox = new QGroupBox(Helper::extent);
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
  mpLeftLabel = new Label(QString(Helper::left).append(":"));
  mpLeftTextBox = new QLineEdit(QString::number(mpGraphicsView->getCoOrdinateSystem()->getExtent().at(0).x()));
  mpLeftTextBox->setValidator(pDoubleValidator);
  mpBottomLabel = new Label(Helper::bottom);
  mpBottomTextBox = new QLineEdit(QString::number(mpGraphicsView->getCoOrdinateSystem()->getExtent().at(0).y()));
  mpBottomTextBox->setValidator(pDoubleValidator);
  mpRightLabel = new Label(QString(Helper::right).append(":"));
  mpRightTextBox = new QLineEdit(QString::number(mpGraphicsView->getCoOrdinateSystem()->getExtent().at(1).x()));
  mpRightTextBox->setValidator(pDoubleValidator);
  mpTopLabel = new Label(Helper::top);
  mpTopTextBox = new QLineEdit(QString::number(mpGraphicsView->getCoOrdinateSystem()->getExtent().at(1).y()));
  mpTopTextBox->setValidator(pDoubleValidator);
  // set the extent group box layout
  QGridLayout *pExtentLayout = new QGridLayout;
  pExtentLayout->addWidget(mpLeftLabel, 0, 0);
  pExtentLayout->addWidget(mpLeftTextBox, 0, 1);
  pExtentLayout->addWidget(mpBottomLabel, 0, 2);
  pExtentLayout->addWidget(mpBottomTextBox, 0, 3);
  pExtentLayout->addWidget(mpRightLabel, 1, 0);
  pExtentLayout->addWidget(mpRightTextBox, 1, 1);
  pExtentLayout->addWidget(mpTopLabel, 1, 2);
  pExtentLayout->addWidget(mpTopTextBox, 1, 3);
  mpExtentGroupBox->setLayout(pExtentLayout);
  // create the grid group box
  mpGridGroupBox = new QGroupBox(Helper::grid);
  QIntValidator *pIntValidator = new QIntValidator(this);
  pIntValidator->setBottom(1);
  mpHorizontalLabel = new Label(QString(Helper::horizontal).append(":"));
  mpHorizontalTextBox = new QLineEdit(QString::number(mpGraphicsView->getCoOrdinateSystem()->getGrid().x()));
  mpHorizontalTextBox->setValidator(pIntValidator);
  mpVerticalLabel = new Label(QString(Helper::vertical).append(":"));
  mpVerticalTextBox = new QLineEdit(QString::number(mpGraphicsView->getCoOrdinateSystem()->getGrid().y()));
  mpVerticalTextBox->setValidator(pIntValidator);
  // set the grid group box layout
  QGridLayout *pGridLayout = new QGridLayout;
  pGridLayout->addWidget(mpHorizontalLabel, 0, 0);
  pGridLayout->addWidget(mpHorizontalTextBox, 0, 1);
  pGridLayout->addWidget(mpVerticalLabel, 1, 0);
  pGridLayout->addWidget(mpVerticalTextBox, 1, 1);
  mpGridGroupBox->setLayout(pGridLayout);
  // create the Component group box
  mpComponentGroupBox = new QGroupBox(Helper::component);
  mpScaleFactorLabel = new Label(Helper::scaleFactor);
  mpScaleFactorTextBox = new QLineEdit(QString::number(mpGraphicsView->getCoOrdinateSystem()->getInitialScale()));
  mpScaleFactorTextBox->setValidator(pDoubleValidator);
  mpPreserveAspectRatioCheckBox = new QCheckBox(Helper::preserveAspectRatio);
  mpPreserveAspectRatioCheckBox->setChecked(mpGraphicsView->getCoOrdinateSystem()->getPreserveAspectRatio());
  // set the grid group box layout
  QGridLayout *pComponentLayout = new QGridLayout;
  pComponentLayout->addWidget(mpScaleFactorLabel, 0, 0);
  pComponentLayout->addWidget(mpScaleFactorTextBox, 0, 1);
  pComponentLayout->addWidget(mpPreserveAspectRatioCheckBox, 1, 0, 1, 2);
  mpComponentGroupBox->setLayout(pComponentLayout);
  // copy properties check box
  mpCopyProperties = new QCheckBox;
  if (mpGraphicsView->getViewType() == StringHandler::Icon)
    mpCopyProperties->setText(tr("Copy properties to Diagram layer"));
  else
    mpCopyProperties->setText(tr("Copy properties to Icon layer"));
  mpCopyProperties->setChecked(true);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(saveGraphicsViewProperties()));
  if (mpGraphicsView->getModelWidget()->getLibraryTreeNode()->isSystemLibrary())
    mpOkButton->setDisabled(true);
  mpCancelButton = new QPushButton(Helper::cancel);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addWidget(mpExtentGroupBox);
  pMainLayout->addWidget(mpGridGroupBox);
  pMainLayout->addWidget(mpComponentGroupBox);
  pMainLayout->addWidget(mpCopyProperties);
  pMainLayout->addWidget(mpButtonBox, 0, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
  Saves the new GraphicsView properties in the form of coordinate system annotation.\n
  Slot activated when mpOkButton clicked signal is raised.
  */
void GraphicsViewProperties::saveGraphicsViewProperties()
{
  qreal left = qMin(mpLeftTextBox->text().toFloat(), mpRightTextBox->text().toFloat());
  qreal bottom = qMin(mpBottomTextBox->text().toFloat(), mpTopTextBox->text().toFloat());
  qreal right = qMax(mpLeftTextBox->text().toFloat(), mpRightTextBox->text().toFloat());
  qreal top = qMax(mpBottomTextBox->text().toFloat(), mpTopTextBox->text().toFloat());
  QList<QPointF> extent;
  extent << QPointF(left, bottom) << QPointF(right, top);
  mpGraphicsView->getCoOrdinateSystem()->setExtent(extent);
  mpGraphicsView->getCoOrdinateSystem()->setPreserveAspectRatio(mpPreserveAspectRatioCheckBox->isChecked());
  mpGraphicsView->getCoOrdinateSystem()->setInitialScale(mpScaleFactorTextBox->text().toFloat());
  qreal horizontal = mpHorizontalTextBox->text().toFloat();
  qreal vertical = mpVerticalTextBox->text().toFloat();
  mpGraphicsView->getCoOrdinateSystem()->setGrid(QPointF(horizontal, vertical));
  mpGraphicsView->setSceneRect(left, bottom, fabs(left - right), fabs(bottom - top));
  mpGraphicsView->fitInView(mpGraphicsView->sceneRect(), Qt::KeepAspectRatio);
  mpGraphicsView->setIsCustomScale(false);
  mpGraphicsView->addClassAnnotation();
  mpGraphicsView->setCanAddClassAnnotation(true);
  // if copy properties is true
  if (mpCopyProperties->isChecked())
  {
    GraphicsView *pGraphicsView;
    if (mpGraphicsView->getViewType() == StringHandler::Icon)
      pGraphicsView = mpGraphicsView->getModelWidget()->getDiagramGraphicsView();
    else
      pGraphicsView = mpGraphicsView->getModelWidget()->getIconGraphicsView();

    pGraphicsView->getCoOrdinateSystem()->setExtent(extent);
    pGraphicsView->getCoOrdinateSystem()->setPreserveAspectRatio(mpPreserveAspectRatioCheckBox->isChecked());
    pGraphicsView->getCoOrdinateSystem()->setInitialScale(mpScaleFactorTextBox->text().toFloat());
    pGraphicsView->getCoOrdinateSystem()->setGrid(QPointF(horizontal, vertical));
    pGraphicsView->setSceneRect(left, bottom, fabs(left - right), fabs(bottom - top));
    pGraphicsView->fitInView(pGraphicsView->sceneRect(), Qt::KeepAspectRatio);
    pGraphicsView->setIsCustomScale(false);
    pGraphicsView->addClassAnnotation();
    pGraphicsView->setCanAddClassAnnotation(true);
  }
  accept();
}

/*!
  \class SaveChangesDialog
  \brief Creates a dialog that shows the list of unsaved Modelica classes.
  */

/*!
  \param pMainWindow - pointer to GraphicsView
  */
SaveChangesDialog::SaveChangesDialog(MainWindow *pMainWindow)
  : QDialog(pMainWindow, Qt::WindowTitleHint)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Save Changes")));
  setMinimumWidth(400);
  mpMainWindow = pMainWindow;
  mpSaveChangesLabel = new Label(tr("Save changes to the following classes?"));
  mpUnsavedClassesListWidget = new QListWidget;
  mpUnsavedClassesListWidget->setObjectName("UnsavedClassesListWidget");
  mpUnsavedClassesListWidget->setItemDelegate(new ItemDelegate(this));
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
  \return false if no unsaved Modelica classes are present otherwise true.
  */
bool SaveChangesDialog::getUnsavedClasses()
{
  bool hasUnsavedClasses = false;
  foreach (LibraryTreeNode* pLibraryTreeNode, mpMainWindow->getLibraryTreeWidget()->getLibraryTreeNodesList())
  {
    if (!pLibraryTreeNode->isSaved())
    {
      if (pLibraryTreeNode->getParentName().isEmpty())
      {
        hasUnsavedClasses = true;
        QListWidgetItem *pListItem = new QListWidgetItem(mpUnsavedClassesListWidget);
        pListItem->setText(pLibraryTreeNode->getNameStructure());
      }
    }
  }
  mpUnsavedClassesListWidget->selectAll();
  return hasUnsavedClasses;
}

/*!
  Saves the unsaved classes. \n
  Slot activated when mpYesButton clicked signal is raised.
  */
void SaveChangesDialog::saveChanges()
{
  bool saveResult = true;
  for (int i = 0; i < mpUnsavedClassesListWidget->count(); i++)
  {
    QListWidgetItem *pListItem = mpUnsavedClassesListWidget->item(i);
    LibraryTreeNode *pLibraryTreeNode = mpMainWindow->getLibraryTreeWidget()->getLibraryTreeNode(pListItem->text());
    if (!mpMainWindow->getLibraryTreeWidget()->saveLibraryTreeNode(pLibraryTreeNode))
      saveResult = false;
  }
  if (saveResult)
    accept();
  else
    reject();
}

/*!
  Reimplementation of exec.
  */
int SaveChangesDialog::exec()
{
  if (!getUnsavedClasses())
    return 1;
  return QDialog::exec();
}
