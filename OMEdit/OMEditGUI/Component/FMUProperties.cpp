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
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("SubModel Attributes")));
  setAttribute(Qt::WA_DeleteOnClose);
  mpComponent = pComponent;
  // Create the name label and text box
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit(mpComponent->getName());
  mpNameTextBox->setDisabled(true);
  // Model parameters
  mpParametersLabel = new Label("Parameters:");
  mpParametersLayout = new QGridLayout;
  mpParametersLayout->addWidget(mpParametersLabel, 0, 0, 1, 2);
  mpParametersScrollWidget = new QWidget;
  mpParametersScrollWidget->setLayout(mpParametersLayout);
  mpParametersScrollArea = new QScrollArea;
  mpParametersScrollArea->setWidgetResizable(true);
  mpParametersScrollArea->setWidget(mpParametersScrollWidget);
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
        QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
        QLineEdit *pParameterLineEdit = new QLineEdit;
        pParameterLineEdit->setValidator(pDoubleValidator);
        if (pInterfaces[i]->type == oms_signal_type_real) {
          double value;
          if (OMSProxy::instance()->getRealParameter(pInterfaces[i]->name, &value)) {
            pParameterLineEdit->setText(QString::number(value));
          }
        } else if (pInterfaces[i]->type == oms_signal_type_integer) {
          int value;
          if (OMSProxy::instance()->getIntegerParameter(pInterfaces[i]->name, &value)) {
            pParameterLineEdit->setText(QString::number(value));
          }
        } else if (pInterfaces[i]->type == oms_signal_type_boolean) {
          int value;
          if (OMSProxy::instance()->getBooleanParameter(pInterfaces[i]->name, &value)) {
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
        mParameterLineEdits.append(pParameterLineEdit);
        mOldFMUProperties.mParameterValues.append(pParameterLineEdit->text());
        mpParametersLayout->addWidget(mParameterLabels.last(), index, 0);
        mpParametersLayout->addWidget(mParameterLineEdits.last(), index, 1);
      }
    }
  }
  mpParametersScrollWidget->setVisible(index > 0);
  mpParametersLabel->setVisible(index > 0);
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
  pMainLayout->addWidget(mpNameLabel, 0, 0);
  pMainLayout->addWidget(mpNameTextBox, 0, 1);
  pMainLayout->addWidget(mpParametersScrollArea, 1, 0, 1, 2);
  pMainLayout->addWidget(mpButtonBox, 2, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief FMUPropertiesDialog::updateFMUParameters
 * Slot activated when mpOkButton clicked SIGNAL is raised.\n
 * Updates the FMU properties.
 */
void FMUPropertiesDialog::updateFMUParameters()
{
  FMUProperties newFMUProperties;
  foreach (QLineEdit *pParameterLineEdit, mParameterLineEdits) {
    newFMUProperties.mParameterValues.append(pParameterLineEdit->text());
  }
  // push the change on the undo stack
  FMUPropertiesCommand *pFMUPropertiesCommand = new FMUPropertiesCommand(mpComponent, mOldFMUProperties, newFMUProperties);
  ModelWidget *pModelWidget = mpComponent->getGraphicsView()->getModelWidget();
  pModelWidget->getUndoStack()->push(pFMUPropertiesCommand);
  pModelWidget->updateModelText();
  // accept the dialog
  accept();
}
