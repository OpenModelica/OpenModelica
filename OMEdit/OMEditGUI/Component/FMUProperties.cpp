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

#include "FMUProperties.h"
#include "Modeling/Commands.h"
#include "ComponentProperties.h"

FMUProperties::FMUProperties()
{
  mParameterValues.clear();
}

/*!
 * \class FMUPropertiesDialog
 * \brief A dialog for displaying FMU properties.
 */
/*!
 * \brief FMUPropertiesDialog::FMUPropertiesDialog
 * \param pComponent - pointer to Component
 * \param pParent
 */
FMUPropertiesDialog::FMUPropertiesDialog(Component *pComponent, QWidget *pParent)
  : QDialog(pParent)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("FMU Properties")));
  setAttribute(Qt::WA_DeleteOnClose);
  mpComponent = pComponent;
  // heading
  mpHeading = Utilities::getHeadingLabel(tr("FMU Properties"));
  // horizontal line
  mpHorizontalLine = Utilities::getHeadingLine();
  // Create the name label and text box
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit(mpComponent->getName());
  // FMU Info
  const oms_fmu_info_t *pFMUInfo = mpComponent->getLibraryTreeItem()->getFMUInfo();
  mpGeneralGroupBox = new QGroupBox(Helper::general);
  mpDescriptionLabel = new Label(QString("%1:").arg(Helper::description));
  mpDescriptionValueLabel = new Label(QString(pFMUInfo->description));
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
  pGeneralLayout->addWidget(mpGenerationTimeValueLabel, 3, 1);
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
  mpCapabilitiesGroupBox->setLayout(pCapabilitiesGridLayout);
  // FMU Parameters
  ParametersScrollArea *pParametersScrollArea = new ParametersScrollArea;
  pParametersScrollArea->setBackgroundRole(QPalette::NoRole);
  pParametersScrollArea->getLayout()->setContentsMargins(0, 0, 0, 0);
  GroupBox *pParametersGroupBox = new GroupBox("Parameters");
  pParametersScrollArea->addGroupBox(pParametersGroupBox);
  mParameterLabels.clear();
  mParameterLineEdits.clear();
  int index = 0;
  if (mpComponent->getLibraryTreeItem()->getOMSElement()) {
    oms_connector_t** pInterfaces = mpComponent->getLibraryTreeItem()->getOMSElement()->interfaces;
    for (int i = 0 ; pInterfaces[i] ; i++) {
      if (pInterfaces[i]->causality == oms_causality_parameter) {
        index++;
        QString name = StringHandler::getLastWordAfterDot(pInterfaces[i]->name);
        name = name.split(':', QString::SkipEmptyParts).last();
        mParameterLabels.append(new Label(name));
        QLineEdit *pParameterLineEdit = new QLineEdit;
        bool status = false;
        if (pInterfaces[i]->type == oms_signal_type_real) {
          QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
          pParameterLineEdit->setValidator(pDoubleValidator);
          double value;
          if ((status = OMSProxy::instance()->getRealParameter(pInterfaces[i]->name, &value))) {
            pParameterLineEdit->setText(QString::number(value));
          }
        } else if (pInterfaces[i]->type == oms_signal_type_integer) {
          QIntValidator *pIntValidator = new QIntValidator(this);
          pParameterLineEdit->setValidator(pIntValidator);
          int value;
          if ((status = OMSProxy::instance()->getIntegerParameter(pInterfaces[i]->name, &value))) {
            pParameterLineEdit->setText(QString::number(value));
          }
        } else if (pInterfaces[i]->type == oms_signal_type_boolean) {
          QIntValidator *pIntValidator = new QIntValidator(this);
          pParameterLineEdit->setValidator(pIntValidator);
          bool value;
          if ((status = OMSProxy::instance()->getBooleanParameter(pInterfaces[i]->name, &value))) {
            pParameterLineEdit->setText(QString::number(value));
          }
        } else if (pInterfaces[i]->type == oms_signal_type_string) {
          qDebug() << "OMSSubModelAttributes::OMSSubModelAttributes() oms_signal_type_string not implemented yet.";
        } else if (pInterfaces[i]->type == oms_signal_type_enum) {
          qDebug() << "OMSSubModelAttributes::OMSSubModelAttributes() oms_signal_type_enum not implemented yet.";
        } else if (pInterfaces[i]->type == oms_signal_type_bus) {
          qDebug() << "OMSSubModelAttributes::OMSSubModelAttributes() oms_signal_type_bus not implemented yet.";
        } else {
          qDebug() << "OMSSubModelAttributes::OMSSubModelAttributes() unknown oms_signal_type_enu_t.";
        }
        if (!status) {
          pParameterLineEdit->setPlaceholderText("unknown");
        }
        mParameterLineEdits.append(pParameterLineEdit);
        mOldFMUProperties.mParameterValues.append(pParameterLineEdit->text());
        GroupBox *pParametersGroupBox = pParametersScrollArea->getGroupBox("Parameters");
        if (pParametersGroupBox) {
          pParametersGroupBox->show();
          QGridLayout *pGroupBoxGridLayout = pParametersGroupBox->getGridLayout();
          int layoutIndex = pGroupBoxGridLayout->rowCount();
          int columnIndex = 0;
          pGroupBoxGridLayout->addWidget(mParameterLabels.last(), layoutIndex, columnIndex++);
          pGroupBoxGridLayout->addWidget(mParameterLineEdits.last(), layoutIndex, columnIndex++);
        }
      }
    }
  }
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(updateFMUParameters()));
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
  pMainLayout->addWidget(mpGeneralGroupBox, 3, 0, 1, 2);
  pMainLayout->addWidget(mpCapabilitiesGroupBox, 4, 0, 1, 2);
  pMainLayout->addWidget(pParametersScrollArea, 5, 0, 1, 2);
  pMainLayout->addWidget(mpButtonBox, 6, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief FMUPropertiesDialog::updateFMUParameters
 * Slot activated when mpOkButton clicked SIGNAL is raised.\n
 * Updates the FMU properties.
 */
void FMUPropertiesDialog::updateFMUParameters()
{
  QString oldName = mpComponent->getLibraryTreeItem()->getNameStructure();
  QString newName = QString("%1.%2").arg(mpComponent->getLibraryTreeItem()->parent()->getNameStructure(), mpNameTextBox->text());
  FMUProperties newFMUProperties;
  foreach (QLineEdit *pParameterLineEdit, mParameterLineEdits) {
    newFMUProperties.mParameterValues.append(pParameterLineEdit->text());
  }
  // push the change on the undo stack
  FMUPropertiesCommand *pFMUPropertiesCommand = new FMUPropertiesCommand(mpComponent, oldName, newName, mOldFMUProperties, newFMUProperties);
  ModelWidget *pModelWidget = mpComponent->getGraphicsView()->getModelWidget();
  pModelWidget->getUndoStack()->push(pFMUPropertiesCommand);
  pModelWidget->updateModelText();
  // accept the dialog
  accept();
}
