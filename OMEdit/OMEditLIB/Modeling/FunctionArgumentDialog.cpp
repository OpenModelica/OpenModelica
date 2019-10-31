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

#include "FunctionArgumentDialog.h"

#include "LibraryTreeWidget.h"
#include "Component/Component.h"

#include <QGridLayout>
#include <QLineEdit>

FunctionArgumentDialog::FunctionArgumentDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *parent):
  QDialog(parent), mpLibraryTreeItem(pLibraryTreeItem)
{
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName, Helper::callFunction, pLibraryTreeItem->getNameStructure()));
  setMinimumWidth(400);

  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  // Function description
  QGroupBox *pDescriptionGroupBox = new QGroupBox(Helper::description);
  QVBoxLayout *pDescriptionLayout = new QVBoxLayout;
  pDescriptionGroupBox->setAlignment(Qt::AlignTop);
  pDescriptionLayout->addWidget(new Label(mpLibraryTreeItem->mClassInformation.comment));
  pDescriptionGroupBox->setLayout(pDescriptionLayout);
  pMainLayout->addWidget(pDescriptionGroupBox);

  // Function arguments
  QList<ComponentInfo*> components = mpLibraryTreeItem->getModelWidget()->getComponentsList();
  QGroupBox *pInputsGroupBox = new QGroupBox(Helper::inputs);
  QGridLayout *pInputsGridLayout = new QGridLayout;
  pInputsGridLayout->setAlignment(Qt::AlignTop);
  int row = 0;
  for (int i = 0; i < components.size(); ++i) {
    ComponentInfo *pComponent = components[i];
    if (!isInput(pComponent)) {
      continue;
    }
    // input name
    pInputsGridLayout->addWidget(new Label(pComponent->getName()), row, 0);
    // input textbox
    QLineEdit *pEditor = new QLineEdit();
    mEditors.append(pEditor);
    pInputsGridLayout->addWidget(pEditor, row, 1);
    // input comment
    pInputsGridLayout->addWidget(new Label(pComponent->getComment()), row, 2);

    ++row;
  }

  pInputsGroupBox->setLayout(pInputsGridLayout);
  pMainLayout->addWidget(pInputsGroupBox);

  QDialogButtonBox *pButtons = new QDialogButtonBox(
        QDialogButtonBox::StandardButton::Ok |
        QDialogButtonBox::StandardButton::Cancel);
  pMainLayout->addWidget(pButtons);
  connect(pButtons, SIGNAL(accepted()), SLOT(accept()));
  connect(pButtons, SIGNAL(rejected()), SLOT(reject()));

  setLayout(pMainLayout);
}

QString FunctionArgumentDialog::getFunctionCallCommand()
{
  QString result = mpLibraryTreeItem->getNameStructure() + "(";
  int inputArgIndex = 0;
  QList<ComponentInfo*> components = mpLibraryTreeItem->getModelWidget()->getComponentsList();
  for (int i = 0; i < components.size(); ++i) {
    ComponentInfo *pComponent = components[i];
    if (!isInput(pComponent)) {
      continue;
    }

    QString value = mEditors[inputArgIndex]->text();

    if (inputArgIndex != 0) {
      result += ", ";
    }

    if (pComponent->getClassName() == "String") {
      result += "\"" + value + "\"";
    } else {
      result += value;
    }

    ++inputArgIndex;
  }
  result += ")";
  return result;
}

bool FunctionArgumentDialog::isInput(ComponentInfo *pComponentInfo)
{
  return pComponentInfo->getCausality() == "input";
}
