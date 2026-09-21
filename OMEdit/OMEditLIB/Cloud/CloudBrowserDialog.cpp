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

#include "Cloud/CloudBrowserDialog.h"
#include "Cloud/CloudAccount.h"
#include "Cloud/CloudProvider.h"
#include "Util/Helper.h"

#include <QComboBox>
#include <QDialogButtonBox>
#include <QLabel>
#include <QPushButton>
#include <QTreeWidget>
#include <QInputDialog>
#include <QMenu>
#include <QVBoxLayout>

namespace {

// Marks a folder whose children have not been listed yet.
const int kFolderIdRole = Qt::UserRole;
const int kLoadedRole = Qt::UserRole + 1;
const int kIsFolderRole = Qt::UserRole + 2;

} // namespace

CloudBrowserDialog::CloudBrowserDialog(Mode mode, QWidget *pParent)
  : QDialog(pParent), mMode(mode)
{
  setWindowTitle(mode == OpenFolder ? tr("%1 - Open from Cloud Storage").arg(Helper::applicationName)
                                    : tr("%1 - Save to Cloud Storage").arg(Helper::applicationName));
  setMinimumSize(520, 420);

  mpAccountComboBox = new QComboBox;
  const QList<CloudAccount *> accounts = CloudAccountManager::instance()->accounts();
  for (CloudAccount *pAccount : accounts) {
    mpAccountComboBox->addItem(QString("%1 - %2").arg(cloudProviderDisplayName(pAccount->kind()),
                                                      pAccount->displayName()),
                               pAccount->key());
  }
  connect(mpAccountComboBox, SIGNAL(currentIndexChanged(int)), SLOT(accountChanged()));

  mpTreeWidget = new QTreeWidget;
  mpTreeWidget->setHeaderLabels(QStringList() << tr("Folder"));
  mpTreeWidget->setSelectionMode(QAbstractItemView::SingleSelection);
  // A new folder is made on demand from here, rather than every save being forced
  // to invent one.
  mpTreeWidget->setContextMenuPolicy(Qt::CustomContextMenu);
  connect(mpTreeWidget, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
  connect(mpTreeWidget, SIGNAL(itemExpanded(QTreeWidgetItem*)), SLOT(itemExpanded(QTreeWidgetItem*)));
  connect(mpTreeWidget, SIGNAL(itemSelectionChanged()), SLOT(selectionChanged()));

  mpStatusLabel = new QLabel;
  mpStatusLabel->setWordWrap(true);

  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpOkButton = new QPushButton(mode == OpenFolder ? tr("Open") : Helper::save);
  mpOkButton->setEnabled(false);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(accept()));
  QPushButton *pCancelButton = new QPushButton(Helper::cancel);
  connect(pCancelButton, SIGNAL(clicked()), SLOT(reject()));
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(pCancelButton, QDialogButtonBox::ActionRole);

  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addWidget(new QLabel(tr("Account:")));
  pMainLayout->addWidget(mpAccountComboBox);
  pMainLayout->addWidget(new QLabel(mode == OpenFolder
                                       ? tr("Choose a folder or a file to open:")
                                       : tr("Choose the folder to save into (right-click for a new folder):")));
  pMainLayout->addWidget(mpTreeWidget);
  pMainLayout->addWidget(mpStatusLabel);
  pMainLayout->addWidget(mpButtonBox);
  setLayout(pMainLayout);

  if (accounts.isEmpty()) {
    mpStatusLabel->setText(tr("No cloud accounts yet. Add one on the Cloud Storage page of the options dialog."));
  } else {
    loadRoot();
  }
}

CloudAccount *CloudBrowserDialog::selectedAccount() const
{
  if (mpAccountComboBox->currentIndex() < 0) {
    return 0;
  }
  return CloudAccountManager::instance()->account(mpAccountComboBox->currentData().toString());
}

void CloudBrowserDialog::setBusy(bool busy, const QString &message)
{
  mPendingRequests += busy ? 1 : -1;
  if (mPendingRequests < 0) {
    mPendingRequests = 0;
  }
  mpStatusLabel->setText(message);
  mpAccountComboBox->setEnabled(mPendingRequests == 0);
}

void CloudBrowserDialog::accountChanged()
{
  mpTreeWidget->clear();
  mSelectedFolderId.clear();
  mSelectedFolderName.clear();
  selectionChanged();
  loadRoot();
}

void CloudBrowserDialog::loadRoot()
{
  CloudAccount *pAccount = selectedAccount();
  if (!pAccount) {
    return;
  }
  setBusy(true, tr("Opening %1...").arg(cloudProviderDisplayName(pAccount->kind())));
  CloudReply *pReply = pAccount->provider()->appRootFolder();
  connect(pReply, &CloudReply::finished, this, [this, pReply]() {
    setBusy(false);
    if (pReply->error().isError()) {
      mpStatusLabel->setText(tr("Could not open the cloud folder: %1").arg(pReply->error().message));
      return;
    }
    QTreeWidgetItem *pRoot = new QTreeWidgetItem(mpTreeWidget);
    pRoot->setText(0, pReply->item().name);
    pRoot->setData(0, kFolderIdRole, pReply->item().id);
    pRoot->setData(0, kLoadedRole, false);
    pRoot->setData(0, kIsFolderRole, true);
    // A placeholder child makes the item expandable before anything is listed.
    new QTreeWidgetItem(pRoot);
    pRoot->setExpanded(true);
    mpTreeWidget->setCurrentItem(pRoot);
  });
}

void CloudBrowserDialog::itemExpanded(QTreeWidgetItem *pItem)
{
  if (pItem->data(0, kLoadedRole).toBool()) {
    return;
  }
  listInto(pItem, pItem->data(0, kFolderIdRole).toString());
}

void CloudBrowserDialog::listInto(QTreeWidgetItem *pItem, const QString &folderId)
{
  CloudAccount *pAccount = selectedAccount();
  if (!pAccount || folderId.isEmpty()) {
    return;
  }
  pItem->setData(0, kLoadedRole, true);
  setBusy(true, tr("Listing %1...").arg(pItem->text(0)));
  CloudReply *pReply = pAccount->provider()->listFolder(folderId);
  connect(pReply, &CloudReply::finished, this, [this, pReply, pItem]() {
    setBusy(false);
    if (pReply->error().isError()) {
      pItem->setData(0, kLoadedRole, false);
      mpStatusLabel->setText(tr("Could not list the folder: %1").arg(pReply->error().message));
      return;
    }
    // Drop the placeholder now that the real children are known.
    qDeleteAll(pItem->takeChildren());
    // Files are shown as well as folders: hiding them made a file that had just
    // been saved look as though it were not there.
    const QList<RemoteItem> items = pReply->items();
    for (const RemoteItem &item : items) {
      QTreeWidgetItem *pChild = new QTreeWidgetItem(pItem);
      pChild->setText(0, item.name);
      pChild->setData(0, kFolderIdRole, item.id);
      pChild->setData(0, kIsFolderRole, item.isFolder);
      pChild->setData(0, kLoadedRole, !item.isFolder);
      if (item.isFolder) {
        new QTreeWidgetItem(pChild);
      }
    }
  });
}

void CloudBrowserDialog::selectionChanged()
{
  QTreeWidgetItem *pItem = mpTreeWidget->currentItem();
  mSelectedFolderId.clear();
  mSelectedFolderName.clear();
  mSelectedFileName.clear();
  if (!pItem) {
    mpOkButton->setEnabled(false);
    return;
  }
  const bool isFolder = pItem->data(0, kIsFolderRole).toBool();
  if (isFolder) {
    mSelectedFolderId = pItem->data(0, kFolderIdRole).toString();
    mSelectedFolderName = pItem->text(0);
  } else if (pItem->parent()) {
    // A file is opened by mounting the folder that holds it.
    mSelectedFolderId = pItem->parent()->data(0, kFolderIdRole).toString();
    mSelectedFolderName = pItem->parent()->text(0);
    mSelectedFileName = pItem->text(0);
  }
  // Saving needs somewhere to put things, so only a folder will do there.
  const bool usable = !mSelectedFolderId.isEmpty() && (mMode == OpenFolder || mSelectedFileName.isEmpty());
  mpOkButton->setEnabled(usable);
}

void CloudBrowserDialog::showContextMenu(const QPoint &position)
{
  if (!mpTreeWidget->itemAt(position)) {
    return;
  }
  QMenu menu(this);
  QAction *pNewFolderAction = menu.addAction(tr("New Folder..."));
  connect(pNewFolderAction, SIGNAL(triggered()), SLOT(createFolder()));
  menu.exec(mpTreeWidget->viewport()->mapToGlobal(position));
}

void CloudBrowserDialog::createFolder()
{
  QTreeWidgetItem *pParent = mpTreeWidget->currentItem();
  CloudAccount *pAccount = selectedAccount();
  if (!pParent || !pAccount) {
    return;
  }
  const QString parentId = pParent->data(0, kFolderIdRole).toString();

  // open(), not getText(): a modal exec() here would park the main thread and the
  // reply to the create request would never be delivered. See MainWindow::openFromCloud.
  QInputDialog *pPrompt = new QInputDialog(this);
  pPrompt->setAttribute(Qt::WA_DeleteOnClose);
  pPrompt->setWindowTitle(tr("New Folder"));
  pPrompt->setLabelText(tr("Folder name:"));
  pPrompt->setInputMode(QInputDialog::TextInput);
  connect(pPrompt, &QInputDialog::textValueSelected, this, [this, pAccount, parentId, pParent](const QString &name) {
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty()) {
      return;
    }
    setBusy(true, tr("Creating %1...").arg(trimmed));
    CloudReply *pReply = pAccount->provider()->createFolder(parentId, trimmed);
    connect(pReply, &CloudReply::finished, this, [this, pReply, pParent]() {
      setBusy(false);
      if (pReply->error().isError()) {
        mpStatusLabel->setText(tr("Could not create the folder: %1").arg(pReply->error().message));
        return;
      }
      QTreeWidgetItem *pChild = new QTreeWidgetItem(pParent);
      pChild->setText(0, pReply->item().name);
      pChild->setData(0, kFolderIdRole, pReply->item().id);
      pChild->setData(0, kLoadedRole, true);
      pParent->setExpanded(true);
      mpTreeWidget->setCurrentItem(pChild);
    });
  });
  pPrompt->open();
}
