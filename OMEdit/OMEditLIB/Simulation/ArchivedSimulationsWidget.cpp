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

#include "ArchivedSimulationsWidget.h"
#include "Util/Utilities.h"
#include "Modeling/ItemDelegate.h"
#include "Util/Helper.h"
#include "Modeling/MessagesWidget.h"
#include "Options/OptionsDialog.h"

#include <QDateTime>
#include <QGridLayout>

ArchivedSimulationItem::ArchivedSimulationItem(const QString &name, const double startTime, const double stopTime, QWidget *pSimulationOutputWidget)
  : mpSimulationOutputWidget(pSimulationOutputWidget)
{
  setText(0, name);
  setToolTip(0, name);
  setText(1, QDateTime::currentDateTime().toString());
  setToolTip(1, QDateTime::currentDateTime().toString());
  setText(2, QString::number(startTime));
  setToolTip(2, QString::number(startTime));
  setText(3, QString::number(stopTime));
  setToolTip(3, QString::number(stopTime));
  setStatus(Helper::running);
}

void ArchivedSimulationItem::setStatus(QString status) {
  setText(4, status);
  setToolTip(4, status);
}

ArchivedSimulationsWidget *ArchivedSimulationsWidget::mpInstance = 0;

void ArchivedSimulationsWidget::create()
{
  if (!mpInstance) {
    mpInstance = new ArchivedSimulationsWidget;
  }
}

void ArchivedSimulationsWidget::destroy()
{
  mpInstance->deleteLater();
  mpInstance = 0;
}

ArchivedSimulationsWidget::ArchivedSimulationsWidget(QWidget *pParent)
  : QWidget(pParent)
{
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, Helper::archivedSimulations));
  Label *pHeadingLabel = Utilities::getHeadingLabel(Helper::archivedSimulations);
  QFrame *pHeadingLineFrame = Utilities::getHeadingLine();
  mpArchivedSimulationsTreeWidget = new QTreeWidget;
  mpArchivedSimulationsTreeWidget->setItemDelegate(new ItemDelegate(mpArchivedSimulationsTreeWidget));
  mpArchivedSimulationsTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpArchivedSimulationsTreeWidget->setColumnCount(4);
  QStringList headers;
  headers << tr("Model") << Helper::dateTime << Helper::startTime << Helper::stopTime << Helper::status;
  mpArchivedSimulationsTreeWidget->setHeaderLabels(headers);
  mpArchivedSimulationsTreeWidget->setIndentation(0);
  connect(mpArchivedSimulationsTreeWidget, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), SLOT(showArchivedSimulation(QTreeWidgetItem*)));
  QGridLayout *pMainGridLayout = new QGridLayout;
  pMainGridLayout->setAlignment(Qt::AlignTop);
  pMainGridLayout->addWidget(pHeadingLabel, 0, 0);
  pMainGridLayout->addWidget(pHeadingLineFrame, 1, 0);
  pMainGridLayout->addWidget(mpArchivedSimulationsTreeWidget, 2, 0);
  setLayout(pMainGridLayout);
}

void ArchivedSimulationsWidget::show()
{
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations() && Utilities::getApplicationSettings()->contains("ArchivedSimulations/geometry")) {
    restoreGeometry(Utilities::getApplicationSettings()->value("ArchivedSimulations/geometry").toByteArray());
  }
  QWidget::show();
}

void ArchivedSimulationsWidget::showArchivedSimulation(QTreeWidgetItem *pTreeWidgetItem)
{
  ArchivedSimulationItem *pArchivedSimulationItem = dynamic_cast<ArchivedSimulationItem*>(pTreeWidgetItem);
  if (pArchivedSimulationItem && pArchivedSimulationItem->getSimulationOutputWidget()) {
    MessagesWidget::instance()->addSimulationOutputTab(pArchivedSimulationItem->getSimulationOutputWidget(), pArchivedSimulationItem->text(0), false);
  }
}

void ArchivedSimulationsWidget::keyPressEvent(QKeyEvent *event)
{
  if (event->key() == Qt::Key_Escape) {
    close();
    return;
  }
  QWidget::keyPressEvent(event);
}

void ArchivedSimulationsWidget::closeEvent(QCloseEvent *event)
{
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations()) {
    Utilities::getApplicationSettings()->setValue("ArchivedSimulations/geometry", saveGeometry());
  }
  QWidget::closeEvent(event);
}
