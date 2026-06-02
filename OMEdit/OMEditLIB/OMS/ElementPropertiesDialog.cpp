/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
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
#include "Element/ElementProperties.h"
#include "OMS/OMSModel.h"

#include <QMessageBox>

/*!
 * \class ElementPropertiesDialog
 * \brief A dialog for displaying element properties.
 */
/*!
 * \brief ElementPropertiesDialog::ElementPropertiesDialog
 * \param pComponent - pointer to Component
 * \param pParent
 */
ElementPropertiesDialog::ElementPropertiesDialog(Element *pComponent, QWidget *pParent)
  : QDialog(pParent)
{
  mpComponent = pComponent;
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName, Helper::properties, pComponent->getName()));
  setAttribute(Qt::WA_DeleteOnClose);
  setMinimumWidth(400);
  // heading
  mpHeading = Utilities::getHeadingLabel(QString("%1 - %2").arg(Helper::properties, pComponent->getName()));
  // horizontal line
  mpHorizontalLine = Utilities::getHeadingLine();
  // Create the name label and text box
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit(mpComponent->getName());

  // tab widget
  mpTabWidget = new QTabWidget;
  // info tab
  if (mpComponent->getLibraryTreeItem()->getOMSModelElement()->hasFMUInfo()) {
    const OMSModel::FMUInfo &pFMUInfo = mpComponent->getLibraryTreeItem()->getFMUInfo();
    mpGeneralGroupBox = new QGroupBox(Helper::general);
    mpDescriptionLabel = new Label(QString("%1:").arg(Helper::description));
    mpDescriptionValueLabel = new Label(QString(pFMUInfo.getDescription()));
    mpDescriptionValueLabel->setElideMode(Qt::ElideMiddle);
    mpFMUKindLabel = new Label(tr("FMU Kind:"));
    mpFMUKindValueLabel = new Label(pFMUInfo.getFMIKind());
    mpFMIVersionLabel = new Label(tr("FMI Version:"));
    mpFMIVersionValueLabel = new Label(QString(pFMUInfo.getFMIVersion()));
    mpGenerationToolLabel = new Label(tr("Generation Tool:"));
    mpGenerationToolValueLabel = new Label(QString(pFMUInfo.getGenerationTool()));
    mpGuidLabel = new Label(tr("Guid:"));
    mpGuidValueLabel = new Label(QString(pFMUInfo.getGuid()));
    mpGenerationTimeLabel = new Label(tr("Generation Time:"));
    mpGenerationTimeValueLabel = new Label(QString(pFMUInfo.getGenerationDateAndTime()));
    mpModelNameLabel = new Label(tr("Model Name:"));
    mpModelNameValueLabel = new Label(QString(pFMUInfo.getModelName()));
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
    mpCanBeInstantiatedOnlyOncePerProcessValueLabel = new Label(pFMUInfo.getCanBeInstantiatedOnlyOncePerProcess() ? "true" : "false");
    mpCanGetAndSetFMUStateLabel = new Label("canGetAndSetFMUstate:");
    mpCanGetAndSetFMUStateValueLabel = new Label(pFMUInfo.getCanGetAndSetFMUstate() ? "true" : "false");
    mpCanNotUseMemoryManagementFunctionsLabel = new Label("canNotUseMemoryManagementFunctions:");
    mpCanNotUseMemoryManagementFunctionsValueLabel = new Label(pFMUInfo.getCanNotUseMemoryManagementFunctions() ? "true" : "false");
    mpCanSerializeFMUStateLabel = new Label("canSerializeFMUstate:");
    mpCanSerializeFMUStateValueLabel = new Label(pFMUInfo.getCanSerializeFMUstate() ? "true" : "false");
    mpCompletedIntegratorStepNotNeededLabel = new Label("completedIntegratorStepNotNeeded:");
    mpCompletedIntegratorStepNotNeededValueLabel = new Label(pFMUInfo.getCompletedIntegratorStepNotNeeded() ? "true" : "false");
    mpNeedsExecutionToolLabel = new Label("needsExecutionTool:");
    mpNeedsExecutionToolValueLabel = new Label(pFMUInfo.getNeedsExecutionTool() ? "true" : "false");
    mpProvidesDirectionalDerivativeLabel = new Label("providesDirectionalDerivative:");
    mpProvidesDirectionalDerivativeValueLabel = new Label(pFMUInfo.getProvidesDirectionalDerivative() ? "true" : "false");
    mpCanInterpolateInputsLabel = new Label("canInterpolateInputs:");
    mpCanInterpolateInputsValueLabel = new Label(pFMUInfo.getCanInterpolateInputs() ? "true" : "false");
    mpMaxOutputDerivativeOrderLabel = new Label("maxOutputDerivativeOrder:");
    mpMaxOutputDerivativeOrderValueLabel = new Label(QString::number(pFMUInfo.getMaxOutputDerivativeOrder()));
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
  bool hasParameter = false;
  OMSModel::Element *pElement = mpComponent->getLibraryTreeItem()->getOMSModelElement();
  if (pElement) {
    for (OMSModel::Connector *pConnector : pElement->getConnectors()) {
      if (!pConnector->isParameter())
        continue;
      hasParameter = true;
      const QString name = pConnector->getName();
      const QString nameStructure = QString("%1.%2").arg(mpComponent->getLibraryTreeItem()->getNameStructure(), name);
      mParameterLabels.append(new Label(name));
      QLineEdit *pParameterLineEdit = new QLineEdit;
      pParameterLineEdit->installEventFilter(this);
      bool status = false;
      if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_real) {
        pParameterLineEdit->setValidator(new QDoubleValidator(this));
        double value;
        if ((status = OMSProxy::instance()->getReal(nameStructure, value)))
          pParameterLineEdit->setText(QString::number(value));
      } else if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_integer
              || pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_enum) {
        pParameterLineEdit->setValidator(new QIntValidator(this));
        int value;
        if ((status = OMSProxy::instance()->getInteger(nameStructure, value)))
          pParameterLineEdit->setText(QString::number(value));
      } else if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_boolean) {
        pParameterLineEdit->setValidator(new QIntValidator(this));
        bool value;
        if ((status = OMSProxy::instance()->getBoolean(nameStructure, value)))
          pParameterLineEdit->setText(QString::number(value));
      } else if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_string) {
        qDebug() << "ElementPropertiesDialog: oms_signal_type_string not implemented yet.";
      }
      if (!status) pParameterLineEdit->setPlaceholderText("unknown");
      mParameterLineEdits.append(pParameterLineEdit);
      int row = pParametersGridLayout->rowCount();
      pParametersGridLayout->addWidget(mParameterLabels.last(), row, 0);
      pParametersGridLayout->addWidget(mParameterLineEdits.last(), row, 1);
    }
    if (hasParameter)
      mpTabWidget->addTab(pParametersScrollArea, Helper::parameters);
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
  if (pElement) {
    for (OMSModel::Connector *pConnector : pElement->getConnectors()) {
      if (!pConnector->isInput())
        continue;
      hasInput = true;
      const QString name = pConnector->getName();
      const QString nameStructure = QString("%1.%2").arg(mpComponent->getLibraryTreeItem()->getNameStructure(), name);
      Label *pNameLabel = new Label(name);
      pNameLabel->setToolTip(nameStructure);
      mInputLabels.append(pNameLabel);
      QLineEdit *pInputLineEdit = new QLineEdit;
      pInputLineEdit->installEventFilter(this);
      bool status = false;
      if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_real) {
        pInputLineEdit->setValidator(new QDoubleValidator(this));
        double value;
        if ((status = OMSProxy::instance()->getReal(nameStructure, value)))
          pInputLineEdit->setText(QString::number(value));
      } else if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_integer
              || pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_enum) {
        pInputLineEdit->setValidator(new QIntValidator(this));
        int value;
        if ((status = OMSProxy::instance()->getInteger(nameStructure, value)))
          pInputLineEdit->setText(QString::number(value));
      } else if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_boolean) {
        pInputLineEdit->setValidator(new QIntValidator(this));
        bool value;
        if ((status = OMSProxy::instance()->getBoolean(nameStructure, value)))
          pInputLineEdit->setText(QString::number(value));
      } else if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_string) {
        qDebug() << "ElementPropertiesDialog: oms_signal_type_string not implemented yet.";
      }
      if (!status) pInputLineEdit->setPlaceholderText("unknown");
      mInputLineEdits.append(pInputLineEdit);
      int row = pInputsGridLayout->rowCount();
      pInputsGridLayout->addWidget(mInputLabels.last(), row, 0);
      pInputsGridLayout->addWidget(mInputLineEdits.last(), row, 1);
    }
    if (hasInput)
      mpTabWidget->addTab(pInputsScrollArea, Helper::inputs);
  }
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
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
  if(mpComponent->getLibraryTreeItem()->isExternalTLMModelComponent()) {
      pMainLayout->addWidget(mpStartScriptLabel, 3, 0);
      pMainLayout->addWidget(mpStartScriptTextBox, 3, 1);
  }
  if (mpComponent->getLibraryTreeItem()->getOMSModelElement()->hasFMUInfo() || hasParameter || hasInput) {
      pMainLayout->addWidget(mpTabWidget, 4, 0, 1, 2);
  }
  pMainLayout->addWidget(mpButtonBox, 5, 0, 1, 2, Qt::AlignRight);
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
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(Helper::item), QMessageBox::Ok);
    return;
  }
  ModelWidget *pModelWidget = mpComponent->getGraphicsView()->getModelWidget();
  // Update parameters and inputs
  OMSModel::Element *pElement = mpComponent->getLibraryTreeItem()->getOMSModelElement();
  if (pElement) {
    int parametersIndex = 0, inputsIndex = 0;
    for (OMSModel::Connector *pConnector : pElement->getConnectors()) {
      const QString nameStructure = QString("%1.%2").arg(mpComponent->getLibraryTreeItem()->getNameStructure(), pConnector->getName());
      if (pConnector->isParameter()) {
        const QString value = mParameterLineEdits.at(parametersIndex++)->text();
        if (value.isEmpty()) {
          OMSProxy::instance()->omsDelete(nameStructure + ":start");
        } else {
          if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_real)
            OMSProxy::instance()->setReal(nameStructure, value.toDouble());
          else if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_integer
                || pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_enum)
            OMSProxy::instance()->setInteger(nameStructure, value.toInt());
          else if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_boolean)
            OMSProxy::instance()->setBoolean(nameStructure, value.toInt());
          else if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_string)
            qDebug() << "ElementPropertiesDialog::updateProperties() oms_signal_type_string not implemented yet.";
        }
      } else if (pConnector->isInput()) {
        const QString value = mInputLineEdits.at(inputsIndex++)->text();
        if (value.isEmpty()) {
          OMSProxy::instance()->omsDelete(nameStructure + ":start");
        } else {
          if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_real)
            OMSProxy::instance()->setReal(nameStructure, value.toDouble());
          else if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_integer
                || pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_enum)
            OMSProxy::instance()->setInteger(nameStructure, value.toInt());
          else if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_boolean)
            OMSProxy::instance()->setBoolean(nameStructure, value.toInt());
          else if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_string)
            qDebug() << "ElementPropertiesDialog::updateProperties() oms_signal_type_string not implemented yet.";
        }
      }
    }
  }
  // if the name is same as old then skip.
  if (mpNameTextBox->text().compare(mpComponent->getName()) != 0) {
    OMSProxy::instance()->rename(mpComponent->getLibraryTreeItem()->getNameStructure(), mpNameTextBox->text());
  }
  bool doSnapShot = !mpComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->isSystemLibrary();
  pModelWidget->createOMSimulatorUndoCommand(QString("Update Element %1 Parameters").arg(mpNameTextBox->text()), doSnapShot);
  pModelWidget->updateModelText();
  // accept the dialog
  accept();
}

/*
 * event filter for mParameterLineEdits and mInputLineEdit
 * to detect the focus out event, and update
 * the default start values from modeldesctiption.xml
 */
bool ElementPropertiesDialog::eventFilter(QObject *pObject, QEvent *pEvent)
{
  QLineEdit *pLineEdit = qobject_cast<QLineEdit*>(pObject);

  if (pLineEdit && pEvent->type() != QEvent::FocusOut) {
    return QWidget::eventFilter(pObject, pEvent);
  }

  if (!pLineEdit->text().isEmpty()) {
    return QWidget::eventFilter(pObject, pEvent);
  }

  if (!mpComponent->getLibraryTreeItem()->getOMSModelElement()) {
    return QWidget::eventFilter(pObject, pEvent);
  }

  // search the lineEdit index in parameters
  int parameterIndex = mParameterLineEdits.indexOf(pLineEdit);
  if (parameterIndex != -1) {
    QString parameterLabelText = mParameterLabels.at(parameterIndex)->text();
    deleteStartValueAndRestoreDefault(parameterLabelText, pLineEdit);
  }

  // search the lineEdit index in inputs
  int inputIndex = mInputLineEdits.indexOf(pLineEdit);
  if (inputIndex != -1) {
    QString inputLabelText = mInputLabels.at(inputIndex)->text();
    deleteStartValueAndRestoreDefault(inputLabelText, pLineEdit);
  }

  return QWidget::eventFilter(pObject, pEvent);
}

/*
 * helper function to restore default start values read from modeldescription.xml for fmus
 * and 0 for other systems
 */
void ElementPropertiesDialog::deleteStartValueAndRestoreDefault(const QString name, QLineEdit *pLineEdit)
{
  OMSModel::Element *pElement = mpComponent->getLibraryTreeItem()->getOMSModelElement();
  if (!pElement) return;

  OMSModel::Connector *pConnector = nullptr;
  for (OMSModel::Connector *c : pElement->getConnectors()) {
    if (c->getName() == name) { pConnector = c; break; }
  }
  if (!pConnector) return;
  if (!pConnector->isParameter() && !pConnector->isInput()) return;

  const QString nameStructure = QString("%1.%2").arg(mpComponent->getLibraryTreeItem()->getNameStructure(), pConnector->getName());
  OMSProxy::instance()->omsDelete(nameStructure + ":start");

  bool status = false;
  if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_real) {
    double value;
    if ((status = OMSProxy::instance()->getReal(nameStructure, value)))
      pLineEdit->setText(QString::number(value));
  } else if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_integer) {
    int value;
    if ((status = OMSProxy::instance()->getInteger(nameStructure, value)))
      pLineEdit->setText(QString::number(value));
  } else if (pConnector->getSignalType() == OMSModel::SignalType::oms_signal_type_boolean) {
    bool value;
    if ((status = OMSProxy::instance()->getBoolean(nameStructure, value)))
      pLineEdit->setText(QString::number(value));
  }
  if (!status) pLineEdit->setPlaceholderText("unknown");
}
