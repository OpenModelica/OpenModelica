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


#include "PathSelector.h"
#include <QHBoxLayout>
#include <QPushButton>
#include <QFileDialog>
#include <QDir>
#include "Helper.h"
#include "StringHandler.h"

PathSelector::PathSelector(QWidget *parent, QString labelText) : QWidget(parent) {
    QGridLayout *layout = new QGridLayout(this);
    // layout->setAlignment(Qt::AlignTop | Qt::AlignLeft);

    pathLabel = new Label(labelText);
    pathText = new QLineEdit(this);
    pathText->setReadOnly(true);
    pathText->setToolTip(Helper::pathListTip);
    pathList = new QListWidget(this);
    addButton = new QPushButton(Helper::addPath, this);
    removeButton = new QPushButton(Helper::removePath, this);

    layout->addWidget(pathLabel, 0, 0);
    layout->addWidget(pathText, 1, 0, 1, 2);
    layout->addWidget(pathList, 2, 0, 1, 2);
    layout->addWidget(addButton, 3, 0, 1, 1);
    layout->addWidget(removeButton, 3, 1, 1, 1);

    connect(addButton, &QPushButton::clicked, this, &PathSelector::addPath);
    connect(removeButton, &QPushButton::clicked, this, &PathSelector::removePath);
    connect(pathList, &QListWidget::itemSelectionChanged, this, &PathSelector::updatePathText);
}

void PathSelector::addPath() {
    QString path = StringHandler::getExistingDirectory(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseDirectory), NULL);

    if (!path.isEmpty()) {
        pathList->addItem(path);
        updatePathText();
    }
}

void PathSelector::removePath() {
    QListWidgetItem *selectedItem = pathList->currentItem();
    if (selectedItem) {
        delete pathList->takeItem(pathList->row(selectedItem));
        updatePathText();
    }
}

void PathSelector::updatePathText() {
    QString concatenatedPaths;

    for (int i = 0; i < pathList->count(); ++i) {
        concatenatedPaths += pathList->item(i)->text();

        if (i < pathList->count() - 1) {
            concatenatedPaths += QDir::listSeparator();
        }
    }

    pathText->setText(concatenatedPaths);
}

void PathSelector::setText(QString paths) {
    pathText->setText(paths);
    // split the text by QDir::listSeparator() and populate the list!
    QStringList l = paths.split(QDir::listSeparator());
    // clear the list!
    pathList->clear();
    // set the list items!
    for (int i = 0; i < l.size(); ++i) {
       QListWidgetItem *item = new QListWidgetItem(l[i], pathList);
       pathList->addItem(item);
    }
};

QString PathSelector::text() {
    return pathText->text();
};
