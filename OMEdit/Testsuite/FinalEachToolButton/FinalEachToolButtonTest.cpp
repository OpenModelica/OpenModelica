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

#include "FinalEachToolButtonTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "Element/ElementProperties.h"

#include <QDialog>
#include <QMenu>
#include <QPushButton>
#include <QHBoxLayout>

OMEDITTEST_MAIN(FinalEachToolButtonTest)

/*!
 * \brief FinalEachToolButtonTest::openMenuWithKeyboard
 * Tests that the key opens the menu with the final action active and that the dialog is not accepted.
 * See issue #12164.
 */
void FinalEachToolButtonTest::openMenuWithKeyboard()
{
  QFETCH(int, key);

  QDialog dialog;
  FinalEachToolButton *pFinalEachToolButton = new FinalEachToolButton(true);
  QPushButton *pOkButton = new QPushButton("OK");
  pOkButton->setAutoDefault(true);
  pOkButton->setDefault(true);
  connect(pOkButton, &QPushButton::clicked, &dialog, &QDialog::accept);
  QHBoxLayout *pLayout = new QHBoxLayout(&dialog);
  pLayout->addWidget(pFinalEachToolButton);
  pLayout->addWidget(pOkButton);
  dialog.show();
  QVERIFY(QTest::qWaitForWindowExposed(&dialog));
  pFinalEachToolButton->setFocus();

  QMenu *pMenu = pFinalEachToolButton->getFinalEachMenu();
  bool menuShown = false;
  QAction *pActiveAction = nullptr;
  QTimer::singleShot(0, [&]() {
    menuShown = pMenu->isVisible();
    pActiveAction = pMenu->activeAction();
    QTest::keyClick(pMenu, Qt::Key_Return);
    pMenu->close();
  });
  QTest::keyClick(pFinalEachToolButton, static_cast<Qt::Key>(key));

  QVERIFY(menuShown);
  QCOMPARE(pActiveAction, pMenu->actions().value(0));
  QVERIFY(pFinalEachToolButton->isFinal());
  QCOMPARE(dialog.result(), static_cast<int>(QDialog::Rejected));
  QVERIFY(dialog.isVisible());
}

void FinalEachToolButtonTest::openMenuWithKeyboard_data()
{
  QTest::addColumn<int>("key");

  QTest::newRow("Return") << static_cast<int>(Qt::Key_Return);
  QTest::newRow("Enter") << static_cast<int>(Qt::Key_Enter);
  QTest::newRow("Space") << static_cast<int>(Qt::Key_Space);
  QTest::newRow("Down") << static_cast<int>(Qt::Key_Down);
  QTest::newRow("F4") << static_cast<int>(Qt::Key_F4);
}

void FinalEachToolButtonTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
