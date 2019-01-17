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

#include "ElementPropertiesDialog.h"
#include "Modeling/Commands.h"
#include "Component/ComponentProperties.h"

#include <QMessageBox>

ElementProperties::ElementProperties()
{
  mParameterValues.clear();
  mInputValues.clear();
}

/*!
 * \class ElementPropertiesDialog
 * \brief A dialog for displaying element properties.
 */
/*!
 * \brief ElementPropertiesDialog::ElementPropertiesDialog
 * \param pComponent - pointer to Component
 * \param pParent
 */
ElementPropertiesDialog::ElementPropertiesDialog(Component *pComponent, QWidget *pParent)
  : QDialog(pParent)
{
  mpComponent = pComponent;
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName, Helper::properties, pComponent->getName()));
  setAttribute(Qt::WA_DeleteOnClose);
  setMinimumWidth(400);
  // heading
  mpHeading = Utilities::getHeadingLabel(QString("%1- %2").arg(Helper::properties, pComponent->getName()));
  // horizontal line
  mpHorizontalLine = Utilities::getHeadingLine();
  // Create the name label and text box
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit(mpComponent->getName());
  /*! @todo Remove the following line once oms_rename is available for elements.
   * And then fix the OMSRenameCommand accordingly.
   */
  mpNameTextBox->setDisabled(true);
  // tab widget
  mpTabWidget = new QTabWidget;
  // info tab
  if (mpComponent->getLibraryTreeItem()->getFMUInfo()) {
    const oms_fmu_info_t *pFMUInfo = mpComponent->getLibraryTreeItem()->getFMUInfo();
    mpGeneralGroupBox = new QGroupBox(Helper::general);
    mpDescriptionLabel = new Label(QString("%1:").arg(Helper::description));
    mpDescriptionValueLabel = new Label(QString(pFMUInfo->description));
    mpDescriptionValueLabel->setElideMode(Qt::ElideMiddle);
    mpFMUKindLabel = new Label(tr("FMU Kind:"));
    mpFMUKindValueLabel = new Label(OMSProxy::getFMUKindString(pFMUInfo->fmiKind));
    mpFMIVersionLabel = new Label(tr("FMI Version:"));
    mpFMIVersionValueLabel = new Label(QString(pFMUInfo->fmiVersion));
    mpGenerationToolLabel = new Label(tr("Generation Tool:"));
    mpGenerationToolValueLabel = new Label(QString(pFMUInfo->generationTool));
    mpGuidLabel = new Label(tr("Guid:"));
    mpGuidValueLabel = new Label(QString(pFMUInfo->guid));
    mpGenerationTimeLabel = new Label(tr("Generation Time:"));
    mpGenerationTimeValueLabel = new Label(QString(pFMUInfo->generationDateAndTime));
    mpModelNameLabel = new Label(tr("Model Name:"));
    mpModelNameValueLabel = new Label(QString(pFMUInfo->modelName));
    QGridLayout *pGeneralLayout = new QGridLayout;
    pGeneralLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
    pGeneralLayout->addWidget(mpDescriptionLabel, 0, 0);
    pGeneralLayout->addWidget(mpDescriptionValueLabel, 0, 1);
    pGeneralLayout->addWidget(mpFMUKindLabel, 1, 0);
    pGeneralLayout->addWidget(mpFMUKindValueLabel, 1, 1);
    pGeneralLayout->addWidget(mpFMIVersionLabel, 2, 0);
    pGeneralLayout->addWidget(mpFMIVersionValueLabel, 2, 1);
    pGeneralLayout->addWidget(mpGenerationToolLabel, 3, 0);
    pGeneralLayout->addWidget(mpGenerationToolValueLabel, 3, 1);
    pGeneralLayout->addWidget(mpGuidLabel, 4, 0);
    pGeneralLayout->addWidget(mpGuidValueLabel, 4, 1);
    pGeneralLayout->addWidget(mpGenerationTimeLabel, 5, 0);
    pGeneralLayout->addWidget(mpGenerationTimeValueLabel, 5, 1);
    pGeneralLayout->addWidget(mpModelNameLabel, 6, 0);
    pGeneralLayout->addWidget(mpModelNameValueLabel, 6, 1);
    mpGeneralGroupBox->setLayout(pGeneralLayout);
    // FMU capabilities
    mpCapabilitiesGroupBox = new QGroupBox(tr("Capabilities"));
    mpCanBeInstantiatedOnlyOncePerProcessLabel = new Label("canBeInstantiatedOnlyOncePerProcess:");
    mpCanBeInstantiatedOnlyOncePerProcessValueLabel = new Label(pFMUInfo->canBeInstantiatedOnlyOncePerProcess ? "true" : "false");
    mpCanGetAndSetFMUStateLabel = new Label("canGetAndSetFMUstate:");
    mpCanGetAndSetFMUStateValueLabel = new Label(pFMUInfo->canGetAndSetFMUstate ? "true" : "false");
    mpCanNotUseMemoryManagementFunctionsLabel = new Label("canNotUseMemoryManagementFunctions:");
    mpCanNotUseMemoryManagementFunctionsValueLabel = new Label(pFMUInfo->canNotUseMemoryManagementFunctions ? "true" : "false");
    mpCanSerializeFMUStateLabel = new Label("canSerializeFMUstate:");
    mpCanSerializeFMUStateValueLabel = new Label(pFMUInfo->canSerializeFMUstate ? "true" : "false");
    mpCompletedIntegratorStepNotNeededLabel = new Label("completedIntegratorStepNotNeeded:");
    mpCompletedIntegratorStepNotNeededValueLabel = new Label(pFMUInfo->completedIntegratorStepNotNeeded ? "true" : "false");
    mpNeedsExecutionToolLabel = new Label("needsExecutionTool:");
    mpNeedsExecutionToolValueLabel = new Label(pFMUInfo->needsExecutionTool ? "true" : "false");
    mpProvidesDirectionalDerivativeLabel = new Label("providesDirectionalDerivative:");
    mpProvidesDirectionalDerivativeValueLabel = new Label(pFMUInfo->providesDirectionalDerivative ? "true" : "false");
    mpCanInterpolateInputsLabel = new Label("canInterpolateInputs:");
    mpCanInterpolateInputsValueLabel = new Label(pFMUInfo->canInterpolateInputs ? "true" : "false");
    mpMaxOutputDerivativeOrderLabel = new Label("maxOutputDerivativeOrder:");
    mpMaxOutputDerivativeOrderValueLabel = new Label(QString::number(pFMUInfo->maxOutputDerivativeOrder));
    QGridLayout *pCapabilitiesGridLayout = new QGridLayout;
    pCapabilitiesGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
    pCapabilitiesGridLayout->addWidget(mpCanBeInstantiatedOnlyOncePerProcessLabel, 0, 0);
    pCapabilitiesGridLayout->addWidget(mpCanBeInstantiatedOnlyOncePerProcessValueLabel, 0, 1);
    pCapabilitiesGridLayout->addWidget(mpCanGetAndSetFMUStateLabel, 1, 0);
    pCapabilitiesGridLayout->addWidget(mpCanGetAndSetFMUStateValueLabel, 1, 1);
    pCapabilitiesGridLayout->addWidget(mpCanNotUseMemoryManagementFunctionsLabel, 2, 0);
    pCapabilitiesGridLayout->addWidget(mpCanNotUseMemoryManagementFunctionsValueLabel, 2, 1);
    pCapabilitiesGridLayout->addWidget(mpCanSerializeFMUStateLabel, 3, 0);
    pCapabilitiesGridLayout->addWidget(mpCanSerializeFMUStateValueLabel, 3, 1);
    pCapabilitiesGridLayout->addWidget(mpCompletedIntegratorStepNotNeededLabel, 4, 0);
    pCapabilitiesGridLayout->addWidget(mpCompletedIntegratorStepNotNeededValueLabel, 4, 1);
    pCapabilitiesGridLayout->addWidget(mpNeedsExecutionToolLabel, 5, 0);
    pCapabilitiesGridLayout->addWidget(mpNeedsExecutionToolValueLabel, 5, 1);
    pCapabilitiesGridLayout->addWidget(mpProvidesDirectionalDerivativeLabel, 6, 0);
    pCapabilitiesGridLayout->addWidget(mpProvidesDirectionalDerivativeValueLabel, 6, 1);
    pCapabilitiesGridLayout->addWidget(mpCanInterpolateInputsLabel, 7, 0);
    pCapabilitiesGridLayout->addWidget(mpCanInterpolateInputsValueLabel, 7, 1);
    pCapabilitiesGridLayout->addWidget(mpMaxOutputDerivativeOrderLabel, 8, 0);
    pCapabilitiesGridLayout->addWidget(mpMaxOutputDerivativeOrderValueLabel, 8, 1);
    mpCapabilitiesGroupBox->setLayout(pCapabilitiesGridLayout);
    // info tab widget
    QWidget *pInfoWidget = new QWidget;
    QVBoxLayout *pInfoLayout = new QVBoxLayout;
    pInfoLayout->addWidget(mpGeneralGroupBox);
    pInfoLayout->addWidget(mpCapabilitiesGroupBox);
    pInfoWidget->setLayout(pInfoLayout);
    mpTabWidget->addTab(pInfoWidget, Helper::information);
  }
  // Parameters widget
  QGridLayout *pParametersGridLayout = new QGridLayout;
  pParametersGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  QWidget *pParametersWidget = new QWidget;
  pParametersWidget->setLayout(pParametersGridLayout);
  QScrollArea *pParametersScrollArea = new QScrollArea;
  pParametersScrollArea->setFrameShape(QFrame::NoFrame);
  pParametersScrollArea->setBackgroundRole(QPalette::Base);
  pParametersScrollArea->setWidgetResizable(true);
  pParametersScrollArea->setWidget(pParametersWidget);
  mParameterLabels.clear();
  mParameterLineEdits.clear();
  LibraryTreeItem *pModelLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(
                                             StringHandler::getFirstWordBeforeDot(mpComponent->getLibraryTreeItem()->getNameStructure()));
  bool modelInstantiated = pModelLibraryTreeItem && pModelLibraryTreeItem->isInstantiated();
  bool hasParameter = false;
  if (mpComponent->getLibraryTreeItem()->getOMSElement() && mpComponent->getLibraryTreeItem()->getOMSElement()->connectors) {
    oms_connector_t** pInterfaces = mpComponent->getLibraryTreeItem()->getOMSElement()->connectors;
    for (int i = 0 ; pInterfaces[i] ; i++) {
      if (pInterfaces[i]->causality == oms_causality_parameter) {
        hasParameter = true;
        QString name = QString(pInterfaces[i]->name);
        Label *pNameLabel = new Label(name);
        QString nameStructure = QString("%1.%2").arg(mpComponent->getLibraryTreeItem()->getNameStructure(), name);
        mParameterLabels.append(pNameLabel);
        QLineEdit *pParameterLineEdit = new QLineEdit;
        bool status = false;
        if (pInterfaces[i]->type == oms_signal_type_real) {
          QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
          pParameterLineEdit->setValidator(pDoubleValidator);
          double value;
          if (modelInstantiated && (status = OMSProxy::instance()->getReal(nameStructure, &value))) {
            pParameterLineEdit->setText(QString::number(value));
          }
        } else if (pInterfaces[i]->type == oms_signal_type_integer) {
          QIntValidator *pIntValidator = new QIntValidator(this);
          pParameterLineEdit->setValidator(pIntValidator);
          int value;
          if (modelInstantiated && (status = OMSProxy::instance()->getInteger(nameStructure, &value))) {
            pParameterLineEdit->setText(QString::number(value));
          }
        } else if (pInterfaces[i]->type == oms_signal_type_boolean) {
          QIntValidator *pIntValidator = new QIntValidator(this);
          pParameterLineEdit->setValidator(pIntValidator);
          bool value;
          if (modelInstantiated && (status = OMSProxy::instance()->getBoolean(nameStructure, &value))) {
            pParameterLineEdit->setText(QString::number(value));
          }
        } else if (pInterfaces[i]->type == oms_signal_type_string) {
          qDebug() << "ElementPropertiesDialog::ElementPropertiesDialog() oms_signal_type_string not implemented yet.";
        } else if (pInterfaces[i]->type == oms_signal_type_enum) {
          qDebug() << "ElementPropertiesDialog::ElementPropertiesDialog() oms_signal_type_enum not implemented yet.";
        } else if (pInterfaces[i]->type == oms_signal_type_bus) {
          qDebug() << "ElementPropertiesDialog::ElementPropertiesDialog() oms_signal_type_bus not implemented yet.";
        } else {
          qDebug() << "ElementPropertiesDialog::ElementPropertiesDialog() unknown oms_signal_type_enu_t.";
        }
        if (!status) {
          pParameterLineEdit->setPlaceholderText("unknown");
        }
        mParameterLineEdits.append(pParameterLineEdit);
        mOldElementProperties.mParameterValues.append(pParameterLineEdit->text());
        int layoutIndex = pParametersGridLayout->rowCount();
        int columnIndex = 0;
        pParametersGridLayout->addWidget(mParameterLabels.last(), layoutIndex, columnIndex++);
        pParametersGridLayout->addWidget(mParameterLineEdits.last(), layoutIndex, columnIndex++);
      }
    }
    if (hasParameter) {
      mpTabWidget->addTab(pParametersScrollArea, Helper::parameters);
    }
  }
  // Inputs widget
  QGridLayout *pInputsGridLayout = new QGridLayout;
  pInputsGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  QWidget *pInputsWidget = new QWidget;
  pInputsWidget->setLayout(pInputsGridLayout);
  QScrollArea *pInputsScrollArea = new QScrollArea;
  pInputsScrollArea->setFrameShape(QFrame::NoFrame);
  pInputsScrollArea->setBackgroundRole(QPalette::Base);
  pInputsScrollArea->setWidgetResizable(true);
  pInputsScrollArea->setWidget(pInputsWidget);
  mInputLabels.clear();
  mInputLineEdits.clear();
  bool hasInput = false;
  if (mpComponent->getLibraryTreeItem()->getOMSElement() && mpComponent->getLibraryTreeItem()->getOMSElement()->connectors) {
    oms_connector_t** pInterfaces = mpComponent->getLibraryTreeItem()->getOMSElement()->connectors;
    for (int i = 0 ; pInterfaces[i] ; i++) {
      if (pInterfaces[i]->causality == oms_causality_input) {
        hasInput = true;
        QString name = QString(pInterfaces[i]->name);
        Label *pNameLabel = new Label(name);
        QString nameStructure = QString("%1.%2").arg(mpComponent->getLibraryTreeItem()->getNameStructure(), name);
        pNameLabel->setToolTip(nameStructure);
        mInputLabels.append(pNameLabel);
        QLineEdit *pInputLineEdit = new QLineEdit;
        bool status = false;
        if (pInterfaces[i]->type == oms_signal_type_real) {
          QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
          pInputLineEdit->setValidator(pDoubleValidator);
          double value;
          if (modelInstantiated && (status = OMSProxy::instance()->getReal(nameStructure, &value))) {
            pInputLineEdit->setText(QString::number(value));
          }
        } else if (pInterfaces[i]->type == oms_signal_type_integer) {
          QIntValidator *pIntValidator = new QIntValidator(this);
          pInputLineEdit->setValidator(pIntValidator);
          int value;
          if (modelInstantiated && (status = OMSProxy::instance()->getInteger(nameStructure, &value))) {
            pInputLineEdit->setText(QString::number(value));
          }
        } else if (pInterfaces[i]->type == oms_signal_type_boolean) {
          QIntValidator *pIntValidator = new QIntValidator(this);
          pInputLineEdit->setValidator(pIntValidator);
          bool value;
          if (modelInstantiated && (status = OMSProxy::instance()->getBoolean(nameStructure, &value))) {
            pInputLineEdit->setText(QString::number(value));
          }
        } else if (pInterfaces[i]->type == oms_signal_type_string) {
          qDebug() << "ElementPropertiesDialog::ElementPropertiesDialog() oms_signal_type_string not implemented yet.";
        } else if (pInterfaces[i]->type == oms_signal_type_enum) {
          qDebug() << "ElementPropertiesDialog::ElementPropertiesDialog() oms_signal_type_enum not implemented yet.";
        } else if (pInterfaces[i]->type == oms_signal_type_bus) {
          qDebug() << "ElementPropertiesDialog::ElementPropertiesDialog() oms_signal_type_bus not implemented yet.";
        } else {
          qDebug() << "ElementPropertiesDialog::ElementPropertiesDialog() unknown oms_signal_type_enu_t.";
        }
        if (!status) {
          pInputLineEdit->setPlaceholderText("unknown");
        }
        mInputLineEdits.append(pInputLineEdit);
        mOldElementProperties.mInputValues.append(pInputLineEdit->text());
        int layoutIndex = pInputsGridLayout->rowCount();
        int columnIndex = 0;
        pInputsGridLayout->addWidget(mInputLabels.last(), layoutIndex, columnIndex++);
        pInputsGridLayout->addWidget(mInputLineEdits.last(), layoutIndex, columnIndex++);
      }
    }
    if (hasInput) {
      mpTabWidget->addTab(pInputsScrollArea, Helper::inputs);
    }
  }
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  mpOkButton->setEnabled(modelInstantiated);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(updateProperties()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  // Create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpHeading, 0, 0, 1, 2);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 2);
  pMainLayout->addWidget(mpNameLabel, 2, 0);
  pMainLayout->addWidget(mpNameTextBox, 2, 1);
  if (mpComponent->getLibraryTreeItem()->getFMUInfo() || hasParameter || hasInput) {
    pMainLayout->addWidget(mpTabWidget, 3, 0, 1, 2);
  }
  pMainLayout->addWidget(mpButtonBox, 4, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief ElementPropertiesDialog::updateProperties
 * Slot activated when mpOkButton clicked SIGNAL is raised.\n
 * Updates the element properties.
 */
void ElementPropertiesDialog::updateProperties()
{
  // check name
  if (mpNameTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error), GUIMessages::getMessage(
                            GUIMessages::ENTER_NAME).arg(Helper::item), Helper::ok);
    return;
  }
  ModelWidget *pModelWidget = mpComponent->getGraphicsView()->getModelWidget();
  pModelWidget->beginMacro("Update Element properties");
  // if the name is same as old then skip OMSRenameCommand.
  if (mpNameTextBox->text().compare(mpComponent->getName()) != 0) {
    // push the change on the undo stack
    pModelWidget->getUndoStack()->push(new OMSRenameCommand(mpComponent->getLibraryTreeItem(), mpNameTextBox->text()));
  }
  ElementProperties newElementProperties;
  foreach (QLineEdit *pParameterLineEdit, mParameterLineEdits) {
    newElementProperties.mParameterValues.append(pParameterLineEdit->text());
  }
  foreach (QLineEdit *pInputLineEdit, mInputLineEdits) {
    newElementProperties.mInputValues.append(pInputLineEdit->text());
  }
  // push the change on the undo stack
  pModelWidget->getUndoStack()->push(new ElementPropertiesCommand(mpComponent, mpNameTextBox->text(),
                                                                  mOldElementProperties, newElementProperties));
  pModelWidget->updateModelText();
  pModelWidget->endMacro();
  // accept the dialog
  accept();
}
