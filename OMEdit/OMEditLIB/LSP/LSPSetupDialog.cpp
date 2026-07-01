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

#include "LSP/LSPSetupDialog.h"
#include "LSP/LSPClient.h"

#include <QDesktopServices>
#include <QFont>
#include <QGroupBox>
#include <QHBoxLayout>
#include <QLabel>
#include <QPlainTextEdit>
#include <QPushButton>
#include <QUrl>
#include <QVBoxLayout>

/*!
 * \brief LSPSetupDialog::LSPSetupDialog
 * \param pParent
 */
LSPSetupDialog::LSPSetupDialog(QWidget *pParent)
  : QDialog(pParent),
    mNodeFound(false),
    mpStatusLabel(new QLabel)
{
  setWindowTitle(tr("Language Server Setup"));
  setMinimumWidth(500);

  QLabel *pInfoLabel = new QLabel(
    tr("<b>Node.js is required</b> to run the bundled Modelica language server "
       "but was not found on the system PATH.<br><br>"
       "Install Node.js and click <i>Check Again</i>, or provide a standalone "
       "server executable in <i>Options &gt; Language Server</i>."));
  pInfoLabel->setWordWrap(true);

  // Platform-specific install command
#if defined(Q_OS_WIN)
  const QString installCmd = QStringLiteral("winget install OpenJS.NodeJS.LTS");
#elif defined(Q_OS_MACOS)
  const QString installCmd = QStringLiteral("brew install node");
#else
  const QString installCmd =
    QStringLiteral("sudo apt install nodejs   # Debian / Ubuntu\n"
                   "sudo dnf install nodejs   # Fedora / RHEL");
#endif

  QFont monoFont(QStringLiteral("monospace"));
  monoFont.setStyleHint(QFont::Monospace);

  QPlainTextEdit *pCmdEdit = new QPlainTextEdit(installCmd);
  pCmdEdit->setReadOnly(true);
  pCmdEdit->setFont(monoFont);
  pCmdEdit->setFixedHeight(pCmdEdit->fontMetrics().height() * 3);

  QPushButton *pNodeJsButton = new QPushButton(tr("Open nodejs.org"));
  pNodeJsButton->setAutoDefault(false);
  connect(pNodeJsButton, SIGNAL(clicked()), SLOT(openNodeJsWebsite()));

  QVBoxLayout *pInstallLayout = new QVBoxLayout;
  pInstallLayout->addWidget(pCmdEdit);
  pInstallLayout->addWidget(pNodeJsButton, 0, Qt::AlignLeft);

  QGroupBox *pInstallGroupBox = new QGroupBox(tr("Install Node.js"));
  pInstallGroupBox->setLayout(pInstallLayout);

  mpStatusLabel->setWordWrap(true);

  QPushButton *pCheckAgainButton = new QPushButton(tr("Check Again"));
  pCheckAgainButton->setDefault(true);
  connect(pCheckAgainButton, SIGNAL(clicked()), SLOT(checkAgain()));

  QPushButton *pDisableButton = new QPushButton(tr("Disable Language Server"));
  pDisableButton->setAutoDefault(false);
  connect(pDisableButton, SIGNAL(clicked()), SLOT(reject()));

  QPushButton *pSkipButton = new QPushButton(tr("Skip for Now"));
  pSkipButton->setAutoDefault(false);
  connect(pSkipButton, SIGNAL(clicked()), SLOT(accept()));

  QHBoxLayout *pButtonLayout = new QHBoxLayout;
  pButtonLayout->addWidget(pCheckAgainButton);
  pButtonLayout->addStretch(1);
  pButtonLayout->addWidget(pDisableButton);
  pButtonLayout->addWidget(pSkipButton);

  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addWidget(pInfoLabel);
  pMainLayout->addWidget(pInstallGroupBox);
  pMainLayout->addWidget(mpStatusLabel);
  pMainLayout->addLayout(pButtonLayout);
  pMainLayout->setAlignment(Qt::AlignTop);
  setLayout(pMainLayout);
}

/*!
 * \brief LSPSetupDialog::checkAgain
 * Re-checks whether node is now on PATH.
 */
void LSPSetupDialog::checkAgain()
{
  QString node = LSPClient::findNodeExecutable();
  if (!node.isEmpty()) {
    mNodeFound = true;
    mpStatusLabel->setText(
      tr("<font color='green'>Node.js found at %1.</font>").arg(node));
    accept();
  } else {
    mpStatusLabel->setText(
      tr("<font color='red'>Node.js not found yet. Install it and try again.</font>"));
  }
}

/*!
 * \brief LSPSetupDialog::openNodeJsWebsite
 */
void LSPSetupDialog::openNodeJsWebsite()
{
  QDesktopServices::openUrl(QUrl(QStringLiteral("https://nodejs.org")));
}
