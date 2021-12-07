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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "ModelDialog.h"
#include <Modeling/LibraryTreeWidget.h>
#include <Modeling/ModelWidgetContainer.h>
#include <Modeling/Commands.h>

#include <QGridLayout>
#include <QMessageBox>

/*!
 * \class SystemWidget
 * \brief Creates a widget with name and type.
 */
/*!
 * \brief SystemWidget::SystemWidget
 * \param pLibraryTreeItem
 * \param pParent
 */
SystemWidget::SystemWidget(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent)
  : QWidget(pParent)
{
  // name
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit;
  // type
  mpTypeLabel = new Label(Helper::type);
  mpTypeComboBox = new QComboBox;
  if (!pLibraryTreeItem || pLibraryTreeItem->isTopLevel()) {
    mpTypeComboBox->addItem(Helper::systemTLM, oms_system_tlm);
    mpTypeComboBox->addItem(Helper::systemWC, oms_system_wc);
    mpTypeComboBox->addItem(Helper::systemSC, oms_system_sc);
    mpTypeComboBox->setCurrentIndex(1);
  } else if (pLibraryTreeItem->isSystemElement()) {
    if (pLibraryTreeItem->isTLMSystem()) {
      mpTypeComboBox->addItem(Helper::systemWC, oms_system_wc);
    } else if (pLibraryTreeItem->isWCSystem()) {
      mpTypeComboBox->addItem(Helper::systemSC, oms_system_sc);
    }
  }
  // layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpNameLabel, 0, 0);
  pMainLayout->addWidget(mpNameTextBox, 0, 1);
  pMainLayout->addWidget(mpTypeLabel, 1, 0);
  pMainLayout->addWidget(mpTypeComboBox, 1, 1);
  setLayout(pMainLayout);
}

/*!
 * \class CreateModelDialog
 * \brief Creates a dialog to allow users to create a new OMSimulator model.
 */
/*!
 * \brief CreateModelDialog::CreateModelDialog
 * \param pParent
 */
CreateModelDialog::CreateModelDialog(QWidget *pParent)
  : QDialog(pParent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName).arg(Helper::newOMSimulatorModel));
  setMinimumWidth(400);
  // set heading
  mpHeading = Utilities::getHeadingLabel(Helper::newOMSimulatorModel);
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  // model name
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit;
  // Root system groupbox
  mpRootSystemGroupBox = new QGroupBox(tr("Root System"));
  // system widget
  mpSystemWidget = new SystemWidget(0, this);
  mpSystemWidget->getNameTextBox()->setText("Root");
  QHBoxLayout *pSystemGroupBoxLayout = new QHBoxLayout;
  pSystemGroupBoxLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pSystemGroupBoxLayout->addWidget(mpSystemWidget);
  mpRootSystemGroupBox->setLayout(pSystemGroupBoxLayout);
  // buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(createNewModel()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // add buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpHeading, 0, 0, 1, 2);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 2);
  pMainLayout->addWidget(mpNameLabel, 2, 0);
  pMainLayout->addWidget(mpNameTextBox, 2, 1);
  pMainLayout->addWidget(mpRootSystemGroupBox, 3, 0, 1, 2);
  pMainLayout->addWidget(mpButtonBox, 4, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief CreateModelDialog::createNewModel
 * Creates a new OMSimulator model.
 */
void CreateModelDialog::createNewModel()
{
  if (mpNameTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(tr("Model")), Helper::ok);
    return;
  }

  if (mpSystemWidget->getNameTextBox()->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(tr("System")), Helper::ok);
    return;
  }

  // create new model
  if (OMSProxy::instance()->newModel(mpNameTextBox->text())) {
    QString systemNameStructure = QString("%1.%2").arg(mpNameTextBox->text(), mpSystemWidget->getNameTextBox()->text());
    if (OMSProxy::instance()->addSystem(systemNameStructure, (oms_system_enu_t)mpSystemWidget->getTypeComboBox()->itemData(mpSystemWidget->getTypeComboBox()->currentIndex()).toInt())) {
      LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
      LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(mpNameTextBox->text(), mpNameTextBox->text(), "", false, pLibraryTreeModel->getRootLibraryTreeItem());
      if (pLibraryTreeItem) {
        pLibraryTreeModel->showModelWidget(pLibraryTreeItem);
        // expand the ssp model
        QModelIndex modelIndex = pLibraryTreeModel->libraryTreeItemIndex(pLibraryTreeItem);
        QModelIndex proxyIndex = MainWindow::instance()->getLibraryWidget()->getLibraryTreeProxyModel()->mapFromSource(modelIndex);
        MainWindow::instance()->getLibraryWidget()->getLibraryTreeView()->expand(proxyIndex);
        // open the root system inside it
        if (pLibraryTreeItem->childrenSize() > 0) {
          LibraryTreeItem *pRootSystemLibraryTreeItem  = pLibraryTreeItem->childAt(0);
          if (pRootSystemLibraryTreeItem) {
            pLibraryTreeModel->showModelWidget(pRootSystemLibraryTreeItem);
          }
        }
      }
      accept();
    } else {
      // if creating the root system failed then delete the model created.
      OMSProxy::instance()->omsDelete(mpNameTextBox->text());
    }
  }
}

/*!
 * \class AddSystemDialog
 * \brief Creates a dialog to allow users to add a system to OMSimulator model.
 */
/*!
 * \brief AddSystemDialog::AddSystemDialog
 * \param pGraphicsView
 */
AddSystemDialog::AddSystemDialog(GraphicsView *pGraphicsView)
  : QDialog(pGraphicsView)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName).arg(Helper::addSystem));
  setMinimumWidth(400);
  mpGraphicsView = pGraphicsView;
  // set heading
  mpHeading = Utilities::getHeadingLabel(Helper::addSystem);
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  // system widget
  mpSystemWidget = new SystemWidget(mpGraphicsView->getModelWidget()->getLibraryTreeItem(), this);
  // buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(addSystem()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // add buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpHeading, 0, 0);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0);
  pMainLayout->addWidget(mpSystemWidget, 2, 0);
  pMainLayout->addWidget(mpButtonBox, 3, 0, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief AddSystemDialog::addSystem
 * Adds a system to the OMSimulator model.
 */
void AddSystemDialog::addSystem()
{
  if (mpSystemWidget->getNameTextBox()->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(tr("System")), Helper::ok);
    return;
  }

  LibraryTreeItem *pParentLibraryTreeItem = mpGraphicsView->getModelWidget()->getLibraryTreeItem();
  // Check if Model already have the system
  if (pParentLibraryTreeItem->isTopLevel() && pParentLibraryTreeItem->childrenSize() > 0) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          tr("A model already have a system. Only one system is allowed inside a model."), Helper::ok);
    return;
  }
  // Check if system already exists
  for (int i = 0 ; i < pParentLibraryTreeItem->childrenSize() ; i++) {
    LibraryTreeItem *pChildLibraryTreeItem = pParentLibraryTreeItem->child(i);
    if (pChildLibraryTreeItem && pChildLibraryTreeItem->getName().compare(mpSystemWidget->getNameTextBox()->text()) == 0) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            GUIMessages::getMessage(GUIMessages::MODEL_ALREADY_EXISTS)
                            .arg(tr("System"), mpSystemWidget->getNameTextBox()->text(), pParentLibraryTreeItem->getNameStructure()), Helper::ok);
      return;
    }
  }
  // add the system
  oms_system_enu_t systemType = (oms_system_enu_t)mpSystemWidget->getTypeComboBox()->itemData(mpSystemWidget->getTypeComboBox()->currentIndex()).toInt();
  QString nameStructure = QString("%1.%2").arg(pParentLibraryTreeItem->getNameStructure()).arg(mpSystemWidget->getNameTextBox()->text());
  if (OMSProxy::instance()->addSystem(nameStructure, systemType)) {
    if (mpGraphicsView->mContextMenuStartPositionValid) {
      OMSProxy::instance()->createElementGeometryUsingPosition(nameStructure, mpGraphicsView->mContextMenuStartPosition);
    }
    mpGraphicsView->getModelWidget()->createOMSimulatorUndoCommand(QString("Add system %1").arg(nameStructure));
    mpGraphicsView->getModelWidget()->updateModelText();
    accept();
  }
}

/*!
 * \class AddSubModelDialog
 * \brief Creates a dialog to allow users to add a submodel to OMSimulator model.
 */
/*!
 * \brief AddSubModelDialog::AddSubModelDialog
 * \param pGraphicsView
 * \param path
 * \param name
 */
AddSubModelDialog::AddSubModelDialog(GraphicsView *pGraphicsView, const QString &path, const QString &name)
  : QDialog(pGraphicsView)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName).arg(Helper::addSubModel));
  setMinimumWidth(400);
  mpGraphicsView = pGraphicsView;
  // set heading
  mpHeading = Utilities::getHeadingLabel(Helper::addSubModel);
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  // name
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit(name);
  // path
  mpPathLabel = new Label(Helper::path);
  mpPathTextBox = new QLineEdit(path);
  mpBrowsePathButton = new QPushButton(Helper::browse);
  mpBrowsePathButton->setAutoDefault(false);
  connect(mpBrowsePathButton, SIGNAL(clicked()), SLOT(browseSubModelPath()));
  // start script
  mpStartScriptLabel = new Label(Helper::startScript);
  mpStartScriptTextBox = new QLineEdit;
  mpBrowseStartScriptButton = new QPushButton(Helper::browse);
  mpBrowseStartScriptButton->setAutoDefault(false);
  connect(mpBrowseStartScriptButton, SIGNAL(clicked()), SLOT(browseStartScript()));
  // buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(addSubModel()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // add buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpHeading, 0, 0, 1, 3);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 3);
  pMainLayout->addWidget(mpPathLabel, 2, 0);
  pMainLayout->addWidget(mpPathTextBox, 2, 1);
  pMainLayout->addWidget(mpBrowsePathButton, 2, 2);
  pMainLayout->addWidget(mpNameLabel, 3, 0);
  pMainLayout->addWidget(mpNameTextBox, 3, 1, 1, 2);
  if(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isTLMSystem()) {
    pMainLayout->addWidget(mpStartScriptLabel, 4, 0);
    pMainLayout->addWidget(mpStartScriptTextBox, 4, 1);
    pMainLayout->addWidget(mpBrowseStartScriptButton,4,2);
  }
  pMainLayout->addWidget(mpButtonBox, 5, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainLayout);
  // Fixes issue #7150. Set the focus on the name instead of path.
  mpNameTextBox->selectAll();
  mpNameTextBox->setFocus();
}

/*!
 * \brief AddSubModelDialog::browseSubModelPath
 * Allows the user to select the submodel path and returns it.
 * \param pGraphicsView
 * \return
 */
QString AddSubModelDialog::browseSubModelPath(GraphicsView *pGraphicsView, QString *pName)
{
  QString fileTypes;
  if (!pGraphicsView->getModelWidget()->getLibraryTreeItem()->isTLMSystem()) {
    fileTypes = Helper::subModelFileTypes;
  }
  QString path = StringHandler::getOpenFileName(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), NULL, fileTypes, NULL);
  QFileInfo fileInfo(path);
  if (fileInfo.exists()) {
    *pName = fileInfo.completeBaseName().replace(QStringLiteral("."), QStringLiteral("_"));
  }
  return path;
}

/*!
 * \brief AddSubModelDialog::browseSubModelPath
 * Slot activated when mpBrowsePathButton clicked signal is raised.
 */
void AddSubModelDialog::browseSubModelPath()
{
  QString name = "";
  QString path = AddSubModelDialog::browseSubModelPath(mpGraphicsView, &name);
  if (!path.isEmpty()) {
    mpPathTextBox->setText(path);
    mpNameTextBox->setText(name);
    mpNameTextBox->selectAll();
    mpNameTextBox->setFocus();
  }
}

/*!
 * \brief AddSubModelDialog::browseStartScript
 * Slot activated when mpBrowseSubModelPathButton clicked signal is raised.\n
 * Allows the user to select the start script path
 */
void AddSubModelDialog::browseStartScript()
{
  mpStartScriptTextBox->setText(StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile)));
}

/*!
 * \brief AddSubModelDialog::addSubModel
 * Adds a submodel to the OMSimulator model.
 */
void AddSubModelDialog::addSubModel()
{
  if (mpNameTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(tr("SubModel")), Helper::ok);
    return;
  }

  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isTLMSystem() && mpStartScriptTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ENTER_SCRIPT), Helper::ok);
    return;
  }

  QFileInfo fileInfo(mpPathTextBox->text());
  if (!fileInfo.exists()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), tr("Unable to find the SubModel file."), Helper::ok);
    return;
  }
  LibraryTreeItem *pParentLibraryTreeItem;
  pParentLibraryTreeItem = mpGraphicsView->getModelWidget()->getLibraryTreeItem();
  for (int i = 0 ; i < pParentLibraryTreeItem->childrenSize() ; i++) {
    LibraryTreeItem *pChildLibraryTreeItem = pParentLibraryTreeItem->child(i);
    if (pChildLibraryTreeItem && pChildLibraryTreeItem->getName().compare(mpNameTextBox->text()) == 0) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            GUIMessages::getMessage(GUIMessages::MODEL_ALREADY_EXISTS).arg(tr("SubModel"), mpNameTextBox->text(), pParentLibraryTreeItem->getNameStructure()), Helper::ok);
      return;
    }
  }

  // add the submodel
  bool failed = false;
  QString nameStructure = QString("%1.%2").arg(pParentLibraryTreeItem->getNameStructure()).arg(mpNameTextBox->text());
  if (mpStartScriptTextBox->text().isEmpty()) {
    if (OMSProxy::instance()->addSubModel(nameStructure, fileInfo.absoluteFilePath())) {
      if (mpGraphicsView->mContextMenuStartPositionValid) {
        OMSProxy::instance()->createElementGeometryUsingPosition(nameStructure, mpGraphicsView->mContextMenuStartPosition);
      }
      mpGraphicsView->getModelWidget()->createOMSimulatorUndoCommand(QString("Add submodel %1").arg(nameStructure));
      mpGraphicsView->getModelWidget()->updateModelText();
      accept();
    } else {
      failed = true;
    }
  } else {
    if (OMSProxy::instance()->addExternalTLMModel(nameStructure, mpStartScriptTextBox->text(), fileInfo.absoluteFilePath())) {
      if (mpGraphicsView->mContextMenuStartPositionValid) {
        OMSProxy::instance()->createElementGeometryUsingPosition(nameStructure, mpGraphicsView->mContextMenuStartPosition);
      }
      mpGraphicsView->getModelWidget()->createOMSimulatorUndoCommand(QString("Add external tlm model %1").arg(nameStructure));
      mpGraphicsView->getModelWidget()->updateModelText();
      accept();
    } else {
      failed = true;
    }
  }

  if (failed) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          tr("Failed to add submodel. %1").arg(GUIMessages::getMessage(GUIMessages::CHECK_MESSAGES_BROWSER)), Helper::ok);
  }
}

/*!
 * \class AddOrEditIconDialog
 * \brief Creates a dialog to allow users to add or edit icon for system or component.
 */
/*!
 * \brief AddOrEditIconDialog::AddOrEditIconDialog
 * \param pShapeAnnotation
 * \param pGraphicsView
 * \param pParent
 */
AddOrEditIconDialog::AddOrEditIconDialog(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView, QWidget *pParent)
  : QDialog(pParent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2 Icon").arg(Helper::applicationName).arg(pShapeAnnotation ? Helper::edit : Helper::add));
  setMinimumWidth(400);
  mpShapeAnnotation = pShapeAnnotation;
  mpGraphicsView = pGraphicsView;
  mpFileLabel = new Label(Helper::fileLabel);
  mpFileTextBox = new QLineEdit(mpShapeAnnotation ? mpShapeAnnotation->getFileName() : "");
  mpFileTextBox->setEnabled(false);
  mpBrowseFileButton = new QPushButton(Helper::browse);
  connect(mpBrowseFileButton, SIGNAL(clicked()), SLOT(browseImageFile()));
  mpPreviewImageLabel = new Label;
  mpPreviewImageLabel->setAlignment(Qt::AlignCenter);
  if (mpShapeAnnotation) {
    mpPreviewImageLabel->setPixmap(QPixmap::fromImage(mpShapeAnnotation->getImage()));
  }
  mpPreviewImageScrollArea = new QScrollArea;
  mpPreviewImageScrollArea->setMinimumSize(400, 150);
  mpPreviewImageScrollArea->setWidgetResizable(true);
  mpPreviewImageScrollArea->setWidget(mpPreviewImageLabel);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(addOrEditIcon()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the layput
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->addWidget(mpFileLabel, 0, 0);
  pMainLayout->addWidget(mpFileTextBox, 0, 1);
  pMainLayout->addWidget(mpBrowseFileButton, 0, 2);
  pMainLayout->addWidget(mpPreviewImageScrollArea, 1, 0, 1, 3);
  pMainLayout->addWidget(mpButtonBox, 2, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief AddOrEditIconDialog::browseImageFile
 * Slot activated when mpBrowseFileButton clicked SIGNAL is raised.
 * Allows the user to select an icon file.
 */
void AddOrEditIconDialog::browseImageFile()
{
  QString imageFileName = StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile), NULL, Helper::bitmapFileTypes, NULL);
  if (imageFileName.isEmpty()) {
    return;
  }
  mpFileTextBox->setText(imageFileName);
  QPixmap pixmap;
  pixmap.load(imageFileName);
  mpPreviewImageLabel->setPixmap(pixmap);
}

/*!
 * \brief AddOrEditIconDialog::addOrEditIcon
 * Slot activated when mpOkButton clicked SIGNAL is raised.
 * Adds or edit the icon for system or component.
 */
void AddOrEditIconDialog::addOrEditIcon()
{
  if (mpShapeAnnotation) { // edit case
    if (mpShapeAnnotation->getFileName().compare(mpFileTextBox->text()) != 0) {
      mpShapeAnnotation->getGraphicsView()->getModelWidget()->addUpdateDeleteOMSElementIcon(mpFileTextBox->text());
    }
  } else { // add case
    if (mpFileTextBox->text().isEmpty()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(Helper::fileLabel), Helper::ok);
      mpFileTextBox->setFocus();
      return;
    }
    mpGraphicsView->getModelWidget()->addUpdateDeleteOMSElementIcon(mpFileTextBox->text());
  }
  accept();
}

/*!
 * \class AddConnectorDialog
 * \brief Creates a dialog to allow users to add a connector to OMSimulator model.
 */
/*!
 * \brief AddConnectorDialog::AddConnectorDialog
 * \param pGraphicsView
 */
AddConnectorDialog::AddConnectorDialog(GraphicsView *pGraphicsView)
  : QDialog(pGraphicsView)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName).arg(Helper::addConnector));
  setMinimumWidth(400);
  mpGraphicsView = pGraphicsView;
  // set heading
  mpHeading = Utilities::getHeadingLabel(Helper::addConnector);
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  // name
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit;
  // causality
  mpCausalityLabel = new Label("Causality:");
  mpCausalityComboBox = new QComboBox;
  mpCausalityComboBox->addItem("Input", oms_causality_input);
  mpCausalityComboBox->addItem("Output", oms_causality_output);
  mpCausalityComboBox->addItem("Parameter", oms_causality_parameter);

  // type
  mpTypeLabel = new Label(Helper::type);
  mpTypeComboBox = new QComboBox;
  mpTypeComboBox->addItem("Real", oms_signal_type_real);
  mpTypeComboBox->addItem("Integer", oms_signal_type_integer);
  mpTypeComboBox->addItem("Boolean", oms_signal_type_boolean);
  mpTypeComboBox->addItem("String", oms_signal_type_string);
  mpTypeComboBox->addItem("Bus", oms_signal_type_bus);
  // buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(addConnector()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // add buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpHeading, 0, 0, 1, 2);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 2);
  pMainLayout->addWidget(mpNameLabel, 2, 0);
  pMainLayout->addWidget(mpNameTextBox, 2, 1);
  pMainLayout->addWidget(mpCausalityLabel, 3, 0);
  pMainLayout->addWidget(mpCausalityComboBox, 3, 1);
  pMainLayout->addWidget(mpTypeLabel, 4, 0);
  pMainLayout->addWidget(mpTypeComboBox, 4, 1);
  pMainLayout->addWidget(mpButtonBox, 5, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief AddConnectorDialog::addConnector
 * Adds a connector to the OMSimulator model.
 */
void AddConnectorDialog::addConnector()
{
  if (mpNameTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(tr("Connector")), Helper::ok);
    return;
  }

  LibraryTreeItem *pParentLibraryTreeItem;
  pParentLibraryTreeItem = mpGraphicsView->getModelWidget()->getLibraryTreeItem();
  for (int i = 0 ; i < pParentLibraryTreeItem->childrenSize() ; i++) {
    LibraryTreeItem *pChildLibraryTreeItem = pParentLibraryTreeItem->child(i);
    if (pChildLibraryTreeItem && pChildLibraryTreeItem->getName().compare(mpNameTextBox->text()) == 0) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            GUIMessages::getMessage(GUIMessages::MODEL_ALREADY_EXISTS).arg(tr("Connector"), mpNameTextBox->text(), pParentLibraryTreeItem->getNameStructure()), Helper::ok);
      return;
    }
  }
  // add the connector
  QString nameStructure = QString("%1.%2").arg(pParentLibraryTreeItem->getNameStructure()).arg(mpNameTextBox->text());
  oms_causality_enu_t causality = (oms_causality_enu_t)mpCausalityComboBox->itemData(mpCausalityComboBox->currentIndex()).toInt();
  oms_signal_type_enu_t signalType = (oms_signal_type_enu_t)mpTypeComboBox->itemData(mpTypeComboBox->currentIndex()).toInt();
  if (OMSProxy::instance()->addConnector(nameStructure, causality, signalType)) {
    if (mpGraphicsView->mContextMenuStartPositionValid) {
      ssd_connector_geometry_t connectorGeometry;
      connectorGeometry.x = Utilities::mapToCoOrdinateSystem(mpGraphicsView->mContextMenuStartPosition.x(), -100, 100, 0, 1);
      connectorGeometry.y = Utilities::mapToCoOrdinateSystem(mpGraphicsView->mContextMenuStartPosition.y(), -100, 100, 0, 1);
      OMSProxy::instance()->setConnectorGeometry(nameStructure, &connectorGeometry);
    }
    mpGraphicsView->getModelWidget()->createOMSimulatorUndoCommand(QString("Add connector %1").arg(nameStructure));
    mpGraphicsView->getModelWidget()->updateModelText();
    accept();
  }
}
