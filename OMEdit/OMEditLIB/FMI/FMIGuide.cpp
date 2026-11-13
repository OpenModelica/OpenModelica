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

#include "FMIGuide.h"

#include <QCoreApplication>
#include <QJsonDocument>

#if defined(__EMSCRIPTEN__)
#include "OMC/OMCProxy.h"
#else
#include "omcruntime_rust.h"
#endif

/*!
 * \brief FMIGuide::call
 * Sends a request to the settings guide of omc.
 * \param request - see openmodelica_fmi_guide::call.
 * \return the reply.
 */
QJsonObject FMIGuide::call(const QJsonObject &request)
{
  const QByteArray json = QJsonDocument(request).toJson(QJsonDocument::Compact);
#if defined(__EMSCRIPTEN__)
  const QByteArray reply = omcWorkerFmiGuide(QString::fromUtf8(json)).toUtf8();
#else
  char *pReply = omcrs_fmi_guide(json.constData());
  const QByteArray reply(pReply);
  omcrs_free_string(pReply);
#endif
  return QJsonDocument::fromJson(reply).object();
}

/*!
 * \brief FMIGuide::translate
 * The texts of the guide come from its model file. FMIGuideTexts.cpp names them to lupdate.
 * \param text - a text of the model file.
 * \return the text in the language of the user interface.
 */
QString FMIGuide::translate(const QString &text)
{
  return QCoreApplication::translate("FMIGuide", text.toUtf8().constData());
}
