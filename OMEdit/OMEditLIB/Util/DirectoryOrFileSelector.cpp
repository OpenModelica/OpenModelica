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
 * @author adrian.pop@liu.se
 */

#include "DirectoryOrFileSelector.h"
#include "Utilities.h"
#include "Helper.h"
#include "StringHandler.h"
#include "Modeling/ItemDelegate.h"

#include <QGridLayout>

DirectoryOrFileSelector::DirectoryOrFileSelector(bool isDir, QString labelText, QWidget *parent)
  : QWidget(parent)
{
  mIsDir = isDir;
  mpItemLabel = new Label(labelText);
  mpItemListWidget = new QListWidget;
  mpItemListWidget->setItemDelegate(new ItemDelegate(mpItemListWidget));
  mpAddButton = new QPushButton(Helper::addItem);
  connect(mpAddButton, &QPushButton::clicked, this, &DirectoryOrFileSelector::addItem);
  mpRemoveButton = new QPushButton(Helper::removeItem);
  connect(mpRemoveButton, &QPushButton::clicked, this, &DirectoryOrFileSelector::removeItem);
  // layout
  QGridLayout *pGridLayout = new QGridLayout;
  pGridLayout->setContentsMargins(0, 0, 0, 0);
  pGridLayout->addWidget(mpItemLabel, 0, 0, 1, 2);
  pGridLayout->addWidget(mpItemListWidget, 1, 0);
  QVBoxLayout *pVBoxLayout = new QVBoxLayout;
  pVBoxLayout->addWidget(mpAddButton);
  pVBoxLayout->addWidget(mpRemoveButton);
  pGridLayout->addLayout(pVBoxLayout, 1, 1, Qt::AlignTop);
  setLayout(pGridLayout);
}

void DirectoryOrFileSelector::addItem()
{
  QString item;
  if (mIsDir) {
    item = StringHandler::getExistingDirectory(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseDirectory), NULL);
  } else {
    item = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), NULL, Helper::omFileTypes, NULL);
  }

  if (!item.isEmpty()) {
    mpItemListWidget->addItem(item);
  }
}

void DirectoryOrFileSelector::removeItem()
{
  QListWidgetItem *selectedItem = mpItemListWidget->currentItem();
  if (selectedItem) {
    delete mpItemListWidget->takeItem(mpItemListWidget->row(selectedItem));
  }
}

void DirectoryOrFileSelector::setItems(const QStringList &items)
{
  // clear the list!
  mpItemListWidget->clear();
  // set the list items!
  foreach (QString item, items) {
    QListWidgetItem *pListWidgetItem = new QListWidgetItem(item);
    mpItemListWidget->addItem(pListWidgetItem);
  }
}

QStringList DirectoryOrFileSelector::items() const
{
  QStringList lst;
  for (int i = 0; i < mpItemListWidget->count(); ++i) {
    lst << mpItemListWidget->item(i)->text();
  }
  return lst;
}
