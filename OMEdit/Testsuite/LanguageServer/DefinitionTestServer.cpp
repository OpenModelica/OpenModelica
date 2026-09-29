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

// Minimal stdio LSP fixture: the first definition is missing, the next resolves.
// Keep this independent of the real server's parser and symbol-resolution rules.
#include <QCoreApplication>
#include <QFileInfo>
#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrl>

#include <cstdio>
#include <iostream>
#include <string>
#ifdef Q_OS_WIN
#include <fcntl.h>
#include <io.h>
#endif

int main(int argc, char **argv)
{
  QCoreApplication app(argc, argv);
#ifdef Q_OS_WIN
  _setmode(_fileno(stdin), _O_BINARY);
  _setmode(_fileno(stdout), _O_BINARY);
#endif
  int definitions = 0;
  for (;;) {
    int length = -1;
    std::string header;
    while (std::getline(std::cin, header)) {
      if (header == "\r" || header.empty()) break;
      const QByteArray line = QByteArray::fromStdString(header);
      if (line.startsWith("Content-Length:")) {
        bool ok;
        length = line.mid(15).trimmed().toInt(&ok);
        if (!ok || length < 0 || length > 1024 * 1024) return 1;
      }
    }
    if (!std::cin) return 0;
    if (length < 0) return 1;
    QByteArray body(length, '\0');
    if (!std::cin.read(body.data(), length)) return 1;
    QJsonParseError error;
    const auto document = QJsonDocument::fromJson(body, &error);
    if (error.error != QJsonParseError::NoError || !document.isObject()) return 1;
    const auto request = document.object();
    const QString method = request.value("method").toString();
    if (method == "exit") return 0;
    if (!request.contains("id")) continue;

    QJsonValue result(QJsonValue::Null);
    if (method == "initialize") {
      result = QJsonObject{{"capabilities", QJsonObject{{"definitionProvider", true}, {"textDocumentSync", 1}}}};
    } else if (method == "textDocument/definition" && ++definitions > 1) {
      const QString uri = request.value("params").toObject().value("textDocument").toObject().value("uri").toString();
      const QString target = QFileInfo(QUrl(uri).toLocalFile()).dir().filePath("Target.mo");
      result = QJsonObject{{"uri", QUrl::fromLocalFile(target).toString()},
        {"range", QJsonObject{{"start", QJsonObject{{"line", 1}, {"character", 0}}},
                              {"end", QJsonObject{{"line", 3}, {"character", 11}}}}}};
    }
    const QByteArray response = QJsonDocument(QJsonObject{{"jsonrpc", "2.0"},
      {"id", request.value("id")}, {"result", result}}).toJson(QJsonDocument::Compact);
    std::cout << "Content-Length: " << response.size() << "\r\n\r\n";
    std::cout.write(response.constData(), response.size());
    std::cout.flush();
    if (!std::cout) return 1;
  }
}
