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

#include "Cloud/CloudConflictDialog.h"
#include "Cloud/CloudSyncEngine.h"
#include "Util/Helper.h"

#include <QComboBox>
#include <QDialogButtonBox>
#include <QHeaderView>
#include <QLabel>
#include <QPushButton>
#include <QTreeWidget>
#include <QVBoxLayout>

namespace {

QString describe(SyncAction::ConflictKind kind)
{
  switch (kind) {
    case SyncAction::BothChanged:
      return CloudConflictDialog::tr("Changed here and in the cloud");
    case SyncAction::BothCreated:
      return CloudConflictDialog::tr("Created here and in the cloud");
    case SyncAction::LocalDeletedRemoteChanged:
      return CloudConflictDialog::tr("Deleted here, changed in the cloud");
    case SyncAction::LocalChangedRemoteDeleted:
      return CloudConflictDialog::tr("Changed here, deleted in the cloud");
    case SyncAction::NoConflict:
      break;
  }
  return QString();
}

void fillChoices(QComboBox *pComboBox, SyncAction::ConflictKind kind)
{
  const bool localGone = kind == SyncAction::LocalDeletedRemoteChanged;
  const bool remoteGone = kind == SyncAction::LocalChangedRemoteDeleted;
  pComboBox->addItem(localGone ? CloudConflictDialog::tr("Delete it in the cloud too")
                               : CloudConflictDialog::tr("Keep my version"),
                     CloudSyncEngine::KeepLocal);
  pComboBox->addItem(remoteGone ? CloudConflictDialog::tr("Delete my copy too")
                                : CloudConflictDialog::tr("Take the cloud version"),
                     CloudSyncEngine::TakeRemote);
  pComboBox->addItem(CloudConflictDialog::tr("Keep both"), CloudSyncEngine::KeepBoth);
  pComboBox->setCurrentIndex(pComboBox->findData(CloudSyncEngine::KeepBoth));
}

} // namespace

CloudConflictDialog::CloudConflictDialog(const QString &remoteName, const QList<SyncAction> &conflicts,
                                         QWidget *pParent)
  : QDialog(pParent)
{
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, tr("Synchronisation Conflicts")));
  setAttribute(Qt::WA_DeleteOnClose);
  resize(650, 380);

  QLabel *pHeadingLabel =
      new QLabel(tr("These files in <b>%1</b> changed both here and in the cloud since the last synchronisation. "
                    "Keeping both writes the cloud version to the original name and yours beside it.")
                     .arg(remoteName));
  pHeadingLabel->setWordWrap(true);

  mpTreeWidget = new QTreeWidget;
  mpTreeWidget->setColumnCount(3);
  mpTreeWidget->setHeaderLabels(QStringList() << tr("File") << tr("What happened") << tr("What to do"));
  mpTreeWidget->setRootIsDecorated(false);
  mpTreeWidget->header()->setSectionResizeMode(0, QHeaderView::Stretch);
  for (const SyncAction &conflict : conflicts) {
    QTreeWidgetItem *pItem = new QTreeWidgetItem(mpTreeWidget);
    pItem->setText(0, conflict.relativePath);
    pItem->setText(1, describe(conflict.conflict));
    QComboBox *pComboBox = new QComboBox;
    fillChoices(pComboBox, conflict.conflict);
    mpTreeWidget->setItemWidget(pItem, 2, pComboBox);
    mChoices.insert(conflict.relativePath, pComboBox);
  }
  mpTreeWidget->resizeColumnToContents(1);

  QPushButton *pKeepMineButton = new QPushButton(tr("Keep Mine For All"));
  connect(pKeepMineButton, &QPushButton::clicked, this, [this]() { applyToAll(CloudSyncEngine::KeepLocal); });
  QPushButton *pTakeCloudButton = new QPushButton(tr("Take Cloud For All"));
  connect(pTakeCloudButton, &QPushButton::clicked, this, [this]() { applyToAll(CloudSyncEngine::TakeRemote); });
  QPushButton *pKeepBothButton = new QPushButton(tr("Keep Both For All"));
  connect(pKeepBothButton, &QPushButton::clicked, this, [this]() { applyToAll(CloudSyncEngine::KeepBoth); });

  QHBoxLayout *pAllLayout = new QHBoxLayout;
  pAllLayout->addWidget(pKeepMineButton);
  pAllLayout->addWidget(pTakeCloudButton);
  pAllLayout->addWidget(pKeepBothButton);
  pAllLayout->addStretch();

  mpButtonBox = new QDialogButtonBox(QDialogButtonBox::Cancel);
  mpButtonBox->addButton(tr("Synchronise"), QDialogButtonBox::AcceptRole);
  connect(mpButtonBox, &QDialogButtonBox::accepted, this, &QDialog::accept);
  connect(mpButtonBox, &QDialogButtonBox::rejected, this, &QDialog::reject);

  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addWidget(pHeadingLabel);
  pMainLayout->addWidget(mpTreeWidget);
  pMainLayout->addLayout(pAllLayout);
  pMainLayout->addWidget(mpButtonBox);
  setLayout(pMainLayout);
}

void CloudConflictDialog::applyToAll(int resolution)
{
  for (QComboBox *pComboBox : std::as_const(mChoices)) {
    const int index = pComboBox->findData(resolution);
    if (index >= 0) {
      pComboBox->setCurrentIndex(index);
    }
  }
}

QHash<QString, int> CloudConflictDialog::resolutions() const
{
  QHash<QString, int> chosen;
  for (auto it = mChoices.constBegin(); it != mChoices.constEnd(); ++it) {
    chosen.insert(it.key(), it.value()->currentData().toInt());
  }
  return chosen;
}
