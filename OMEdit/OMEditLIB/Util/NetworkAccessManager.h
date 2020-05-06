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
#ifndef NETWORKACCESSMANAGER_H
#define NETWORKACCESSMANAGER_H

#include <QNetworkAccessManager>
#include <QDialog>
#include <QLineEdit>
#include <QCheckBox>

/*!
 * \class NetworkAccessManager
 * \brief Subclass QNetworkAccessManager to provide proxy authentication mechanism.
 */
class NetworkAccessManager : public QNetworkAccessManager
{
  Q_OBJECT
public:
  NetworkAccessManager(QObject *parent = 0);
private:
  /*!
   * \brief mProxyAuthenticationAlreadyCalled used to check if QNetworkAccessManager::proxyAuthenticationRequired() SIGNAL is raised more than once.
   */
  bool mProxyAuthenticationAlreadyCalled;
private slots:
  /*!
   * \brief proxyAuthentication
   * Opens the ProxyCredentialsDialog and allows the user to provide proxy credentials.
   * \param proxy
   * \param pAuthenticator
   */
  void proxyAuthentication(const QNetworkProxy &proxy, QAuthenticator *pAuthenticator);
  /*!
   * \brief requestFinished
   * Resets the mProxyAuthenticationAlreadyCalled flag once the request is finished.
   * \param pNetworkReply
   */
  void requestFinished(QNetworkReply *pNetworkReply);
protected:
  /*!
   * \brief createRequest
   * Reimplementation of QNetworkAccessManager::createRequest()
   * \param operation
   * \param request
   * \param outgoingData
   * \return
   */
  virtual QNetworkReply* createRequest(QNetworkAccessManager::Operation operation, const QNetworkRequest &request, QIODevice *outgoingData) override;
};

/*!
 * \class ProxyCredentialsDialog
 * \brief A dialog for asking the proxy credentials from user.
 */
class ProxyCredentialsDialog : public QDialog
{
  Q_OBJECT
public:
  explicit ProxyCredentialsDialog(const QString &proxyName, QWidget *parent = nullptr);
  QLineEdit* getUsernameTextBox() const {return mpUsernameTextBox;}
  QLineEdit* getPasswordTextBox() const {return mpPasswordTextBox;}
  QCheckBox* getSaveCredentialsCheckBox() const {return mpSaveCredentialsCheckBox;}
private:
  QLineEdit *mpUsernameTextBox;
  QLineEdit *mpPasswordTextBox;
  QCheckBox *mpSaveCredentialsCheckBox;
};

#endif // NETWORKACCESSMANAGER_H
