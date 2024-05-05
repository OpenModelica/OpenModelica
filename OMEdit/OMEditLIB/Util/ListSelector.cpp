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
 * @author Adrian.Pop@liu.se
 */


#include "ListSelector.h"
#include <QHBoxLayout>
#include <QPushButton>
#include <QFileDialog>
#include <QDir>
#include "Helper.h"
#include "StringHandler.h"

ListSelector::ListSelector(QWidget *parent, QString labelText) : QWidget(parent) {
    QGridLayout *layout = new QGridLayout(this);
    // layout->setAlignment(Qt::AlignTop | Qt::AlignLeft);

    itemLabel = new Label(labelText);
    itemList = new QListWidget(this);
    addButton = new QPushButton(Helper::addItem, this);
    removeButton = new QPushButton(Helper::removeItem, this);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->addWidget(itemLabel, 0, 0);
    layout->addWidget(addButton, 1, 0, 1, 1);
    layout->addWidget(removeButton, 1, 1, 1, 1);
    layout->addWidget(itemList, 2, 0, 1, 2);

    connect(addButton, &QPushButton::clicked, this, &ListSelector::addItem);
    connect(removeButton, &QPushButton::clicked, this, &ListSelector::removeItem);
}

void ListSelector::addItem() {
    QString item = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), NULL, Helper::omFileTypes, NULL);

    if (!item.isEmpty()) {
        itemList->addItem(item);
    }
}

void ListSelector::removeItem() {
    QListWidgetItem *selectedItem = itemList->currentItem();
    if (selectedItem) {
        delete itemList->takeItem(itemList->row(selectedItem));
    }
}

void ListSelector::setItems(QStringList items) {
    // clear the list!
    itemList->clear();
    // set the list items!
    for (int i = 0; i < items.size(); ++i) {
       QListWidgetItem *item = new QListWidgetItem(items[i], itemList);
       itemList->addItem(item);
    }
}

void ListSelector::setText(QString text) {
    QStringList items = text.split(separator);
    // clear the list!
    itemList->clear();
    // set the list items!
    for (int i = 0; i < items.size(); ++i) {
       QListWidgetItem *item = new QListWidgetItem(items[i], itemList);
       itemList->addItem(item);
    }
}

QStringList ListSelector::list() {
    QStringList lst;
    for (int i = 0; i < itemList->count(); ++i)
       lst << itemList->item(i)->text();
    return lst;
}

QString ListSelector::text() {
    QStringList lst;
    for (int i = 0; i < itemList->count(); ++i)
       lst << itemList->item(i)->text();
    return lst.join(separator);
}
