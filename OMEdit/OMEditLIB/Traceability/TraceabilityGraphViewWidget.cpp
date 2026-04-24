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

#include "TraceabilityGraphViewWidget.h"

TraceabilityGraphViewWidget::TraceabilityGraphViewWidget(QWidget *pParent)
  : QWidget(pParent)
{
#ifndef OM_DISABLE_DOCUMENTATION
#ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
  mpTraceabilityGraphWebView = new QWebEngineView;
#else // #ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
  mpTraceabilityGraphWebView = new QWebView;
#endif // #ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
  mpTraceabilityGraphWebView->load(QUrl("http://localhost:7474/browser/"));
#endif // #ifndef OM_DISABLE_DOCUMENTATION
  mpTraceabilityGraphViewLabel = new QLabel(tr("Traceability Graph View"));
  QFont font;
  font.setPointSize(15);
  font.setBold(true);
  mpTraceabilityGraphViewLabel->setFont(font);
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpTraceabilityGraphViewLabel, 0, 0);
#ifndef OM_DISABLE_DOCUMENTATION
  pMainLayout->addWidget(mpTraceabilityGraphWebView, 1, 0);
#else // #ifndef OM_DISABLE_DOCUMENTATION
  qDebug() << "Traceability graph view is not supported due to missing webkit and webengine.";
#endif // #ifndef OM_DISABLE_DOCUMENTATION
  setLayout(pMainLayout);
}
