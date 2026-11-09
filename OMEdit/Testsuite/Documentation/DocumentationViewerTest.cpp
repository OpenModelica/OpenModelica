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

/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "Util.h"
#include "DocumentationViewerTest.h"
#include "Modeling/DocumentationWidget.h"

#include <QFile>
#include <QHostAddress>
#include <QTemporaryDir>
#include <QTcpServer>
#include <QTcpSocket>
#include <QWebEngineSettings>

OMEDITTEST_MAIN(DocumentationViewerTest)

void DocumentationViewerTest::localDocumentationCanLoadRemoteScript()
{
  QTcpServer server;
  QVERIFY(server.listen(QHostAddress::LocalHost));

  int scriptRequests = 0;
  connect(&server, &QTcpServer::newConnection, &server, [&server, &scriptRequests]() {
    while (server.hasPendingConnections()) {
      QTcpSocket *socket = server.nextPendingConnection();
      connect(socket, &QTcpSocket::readyRead, socket, [socket, &scriptRequests]() {
        socket->readAll();
        ++scriptRequests;
        const QByteArray script = "window.documentationScriptLoaded = true;";
        const QByteArray response = "HTTP/1.1 200 OK\r\n"
                                    "Content-Type: application/javascript\r\n"
                                    "Connection: close\r\n"
                                    "Content-Length: " + QByteArray::number(script.size()) + "\r\n\r\n" + script;
        socket->write(response);
        socket->disconnectFromHost();
      });
      connect(socket, &QTcpSocket::disconnected, socket, &QObject::deleteLater);
    }
  });

  QTemporaryDir temporaryDirectory;
  QVERIFY(temporaryDirectory.isValid());
  const QString htmlFileName = temporaryDirectory.filePath("documentation.html");
  QFile htmlFile(htmlFileName);
  QVERIFY(htmlFile.open(QIODevice::WriteOnly));
  const QByteArray html = "<!doctype html><html><body><script src=\"http://127.0.0.1:"
                          + QByteArray::number(server.serverPort())
                          + "/fixture.js\"></script></body></html>";
  QCOMPARE(htmlFile.write(html), qint64(html.size()));
  htmlFile.close();

  DocumentationWidget documentationWidget;
  DocumentationViewer *viewer = documentationWidget.getDocumentationViewer();
  QVERIFY(viewer);
  QVERIFY(viewer->settings()->testAttribute(QWebEngineSettings::LocalContentCanAccessRemoteUrls));
  documentationWidget.show();

  QSignalSpy loadFinishedSpy(viewer, &QWebEngineView::loadFinished);
  viewer->setUrl(QUrl::fromLocalFile(htmlFileName));
  QVERIFY(loadFinishedSpy.wait(10000));
  QVERIFY(loadFinishedSpy.constFirst().constFirst().toBool());

  QVariant scriptLoaded;
  bool callbackCalled = false;
  viewer->page()->runJavaScript("window.documentationScriptLoaded === true", [&](const QVariant &result) {
    scriptLoaded = result;
    callbackCalled = true;
  });
  QTRY_VERIFY_WITH_TIMEOUT(callbackCalled, 5000);
  QVERIFY(scriptLoaded.toBool());
  QCOMPARE(scriptRequests, 1);
}
