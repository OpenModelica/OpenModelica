/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * For more information about the Qt-library visit TrollTech's webpage
 * regarding the Qt licence: http://www.trolltech.com/products/qt/licensing.html
 */

#include "evalthread.h"
#include <QPushButton>
#include <fstream>
#include <QApplication>
#include <QMessageBox>
using namespace std;

EvalThread::EvalThread(InputCellDelegate* delegate_, QString expr_, QObject* parent):
  QThread(parent), delegate_(delegate_), expr(expr_)
{
  res = "";
  error = "";
}

EvalThread::~EvalThread()
{
}

QMutex evalMutex; // adrpo 2009-01-19

void EvalThread::run()
{
  evalMutex.lock(); // lock so NO other threads can enter this part!
  delegate_->evalExpression(expr);
  res = delegate_->getResult();
  error = delegate_->getError();
  evalMutex.unlock(); // unlock so other threads can enter this part!
}
