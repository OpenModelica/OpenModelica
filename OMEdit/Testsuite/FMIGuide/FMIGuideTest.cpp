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

#include "FMIGuideTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "FMI/FMIGuideDialog.h"
#include "Util/Helper.h"

#include <QAbstractButton>
#include <QJsonArray>
#include <QPushButton>

OMEDITTEST_MAIN(FMIGuideTest)

static QJsonObject host(const QJsonArray &versions)
{
  return QJsonObject{{"name", "the test"},
                     {"offers", QJsonObject{{"fmiVersion", versions}, {"csSolver", QJsonArray{"euler", "cvode", "ida"}}}},
                     {"applies", QJsonArray{"fmiVersion", "fmiType", "daeMode", "csSolver"}}};
}

static void answer(FMIGuideDialog *pDialog, const QString &input, const QString &value)
{
  foreach (QAbstractButton *pButton, pDialog->findChildren<QAbstractButton*>()) {
    if (pButton->property("input").toString() == input && pButton->property("value").toString() == value) {
      pButton->click();
      return;
    }
  }
  QFAIL(QString("No answer %1 for the question %2.").arg(value, input).toStdString().c_str());
}

void FMIGuideTest::recommendsWhatTheHostOffers()
{
  FMIGuideDialog dialog(host(QJsonArray{"2.0", "3.0"}));
  QCOMPARE(dialog.values().value("fmiVersion").toString(), QString("2.0"));
  QCOMPARE(dialog.values().value("fmiType").toString(), QString("me_cs"));
  QCOMPARE(dialog.values().value("csSolver").toString(), QString("cvode"));

  answer(&dialog, "importerKinds", "cs");
  answer(&dialog, "algebraicLoops", "yes");
  QCOMPARE(dialog.values().value("fmiType").toString(), QString("cs"));
  QCOMPARE(dialog.values().value("daeMode").toString(), QString("on"));
  QCOMPARE(dialog.values().value("csSolver").toString(), QString("ida"));

  answer(&dialog, "algebraicLoops", "no");
  answer(&dialog, "stiffModel", "no");
  answer(&dialog, "solverPrecision", "low");
  QCOMPARE(dialog.values().value("daeMode").toString(), QString("off"));
  QCOMPARE(dialog.values().value("csSolver").toString(), QString("euler"));
}

void FMIGuideTest::refusesWhenNothingFits()
{
  FMIGuideDialog dialog(host(QJsonArray{"3.0"}));
  QPushButton *pApplyButton = 0;
  foreach (QPushButton *pButton, dialog.findChildren<QPushButton*>()) {
    if (pButton->text() == Helper::apply) {
      pApplyButton = pButton;
    }
  }
  QVERIFY(pApplyButton);
  QVERIFY(pApplyButton->isEnabled());
  // The importing tool reads FMI 2.0 only, the host exports FMI 3.0 only.
  answer(&dialog, "importerVersions", "2.0");
  QVERIFY(!pApplyButton->isEnabled());
  answer(&dialog, "importerVersions", "2.0");
  QVERIFY(pApplyButton->isEnabled());
}

void FMIGuideTest::recommendsPackaging()
{
  QJsonObject packaging = host(QJsonArray{"2.0", "3.0"});
  packaging.insert("applies", QJsonArray{"platforms", "fmiSources", "fmiFilter"});
  FMIGuideDialog dialog(packaging);
  QCOMPARE(dialog.values().value("platforms").toString(), QString("static"));
  QCOMPARE(dialog.values().value("fmiSources").toString(), QString("false"));

  answer(&dialog, "target", "embedded");
  QCOMPARE(dialog.values().value("platforms").toString(), QString("source"));
  QCOMPARE(dialog.values().value("fmiSources").toString(), QString("slim"));

  answer(&dialog, "ip", "yes");
  QCOMPARE(dialog.values().value("platforms").toString(), QString("cross"));
  QCOMPARE(dialog.values().value("fmiSources").toString(), QString("false"));
  QCOMPARE(dialog.values().value("fmiFilter").toString(), QString("blackBox"));
}

void FMIGuideTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
