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
#include "NetworkAccessManager.h"
#include "Helper.h"
#include "Utilities.h"

#include <QNetworkProxy>
#include <QNetworkReply>
#include <QAuthenticator>
#include <QDialogButtonBox>
#include <QGridLayout>


NetworkAccessManager::NetworkAccessManager(QObject *parent)
  : QNetworkAccessManager(parent), mProxyAuthenticationAlreadyCalled(false)
{

}

void NetworkAccessManager::proxyAuthentication(const QNetworkProxy &proxy, QAuthenticator *pAuthenticator)
{
  QSettings *pSettings = Utilities::getApplicationSettings();
  if (!mProxyAuthenticationAlreadyCalled && pSettings->contains("proxy/username") && pSettings->contains("proxy/password")) {
    pAuthenticator->setUser(pSettings->value("proxy/username").toString());
    pAuthenticator->setPassword(pSettings->value("proxy/password").toString());
    mProxyAuthenticationAlreadyCalled = true;
    return;
  }

  ProxyCredentialsDialog *pProxyCredentialsDialog = new ProxyCredentialsDialog(proxy.hostName());
  int answer = pProxyCredentialsDialog->exec();

  switch (answer) {
    case QDialog::Rejected:
      disconnect(this, SIGNAL(proxyAuthenticationRequired(QNetworkProxy,QAuthenticator*)), this, SLOT(proxyAuthentication(QNetworkProxy,QAuthenticator*)));
      break;
    case QDialog::Accepted:
    default:
      pAuthenticator->setUser(pProxyCredentialsDialog->getUsernameTextBox()->text());
      pAuthenticator->setPassword(pProxyCredentialsDialog->getPasswordTextBox()->text());
      if (pProxyCredentialsDialog->getSaveCredentialsCheckBox()->isChecked()) {
        pSettings->setValue("proxy/username", pProxyCredentialsDialog->getUsernameTextBox()->text());
        pSettings->setValue("proxy/password", pProxyCredentialsDialog->getPasswordTextBox()->text());
      }
      break;
  }
  delete pProxyCredentialsDialog;
}

void NetworkAccessManager::requestFinished(QNetworkReply *pNetworkReply)
{
  Q_UNUSED(pNetworkReply);
  mProxyAuthenticationAlreadyCalled = false;
}

QNetworkReply* NetworkAccessManager::createRequest(QNetworkAccessManager::Operation operation, const QNetworkRequest &request, QIODevice *outgoingData)
{
  connect(this, SIGNAL(proxyAuthenticationRequired(QNetworkProxy,QAuthenticator*)), SLOT(proxyAuthentication(QNetworkProxy,QAuthenticator*)), Qt::UniqueConnection);
  connect(this, SIGNAL(finished(QNetworkReply*)), SLOT(requestFinished(QNetworkReply*)), Qt::UniqueConnection);

  QNetworkReply *pNetworkReply = QNetworkAccessManager::createRequest(operation, request, outgoingData);
  pNetworkReply->ignoreSslErrors();
  return pNetworkReply;
}

ProxyCredentialsDialog::ProxyCredentialsDialog(const QString &proxyName, QWidget *parent)
  : QDialog(parent)
{
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, tr("Proxy Authentication")));
  setMinimumWidth(400);
  // controls
  mpUsernameTextBox = new QLineEdit;
  mpPasswordTextBox = new QLineEdit;
  mpPasswordTextBox->setEchoMode(QLineEdit::Password);
  mpSaveCredentialsCheckBox = new QCheckBox(tr("Save Credentials"));
  // Create the buttons
  QPushButton *pOkButton = new QPushButton(Helper::ok);
  pOkButton->setAutoDefault(true);
  connect(pOkButton, SIGNAL(clicked()), SLOT(accept()));
  QPushButton *pCancelButton = new QPushButton(Helper::cancel);
  pCancelButton->setAutoDefault(false);
  connect(pCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  QDialogButtonBox *pButtonBox = new QDialogButtonBox(Qt::Horizontal);
  pButtonBox->addButton(pOkButton, QDialogButtonBox::ActionRole);
  pButtonBox->addButton(pCancelButton, QDialogButtonBox::ActionRole);
  // layout
  QGridLayout *pMainGridLayout = new QGridLayout;
  pMainGridLayout->addWidget(new Label(tr("The proxy %1 requires a username and password.").arg(proxyName)), 0, 0, 1, 2);
  pMainGridLayout->addWidget(new Label(tr("Username:")), 1, 0);
  pMainGridLayout->addWidget(mpUsernameTextBox, 1, 1);
  pMainGridLayout->addWidget(new Label(tr("Password:")), 2, 0);
  pMainGridLayout->addWidget(mpPasswordTextBox, 2, 1);
  pMainGridLayout->addWidget(mpSaveCredentialsCheckBox, 3, 0, 1, 2);
  pMainGridLayout->addWidget(pButtonBox, 4, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainGridLayout);
}
