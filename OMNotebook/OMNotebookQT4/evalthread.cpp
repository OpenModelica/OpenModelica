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

void EvalThread::exceptionInEval(exception &e)
{
	// 2006-0-09 AF, try to reconnect to OMC first.
	try
	{
		delegate_->closeConnection();
		delegate_->reconnect();
		run();
	}
	catch( exception &e )
	{
		// unable to reconnect, ask if user want to restart omc.
		QString msg = QString( e.what() ) + "\n\nUnable to reconnect with OMC. Do you want to restart OMC?";
		int result = QMessageBox::critical( 0, tr("Communication Error with OMC"),
			msg,
			QMessageBox::Yes | QMessageBox::Default,
			QMessageBox::No );

		if( result == QMessageBox::Yes )
		{
			delegate_->closeConnection();
			if( delegate_->startDelegate() )
			{
				// 2006-03-14 AF, wait before trying to reconnect,
				// give OMC time to start up
				msleep(1000);
				try
				{
					delegate_->reconnect();
					run();
				}
				catch( exception &e )
				{
          e.what();
					QMessageBox::critical( 0, tr("Communication Error"), tr("<B>Unable to communication correctlly with OMC.</B>") );
				}
			}
		}
	}
}

QMutex evalMutex; // adrpo 2009-01-19

void EvalThread::run()
{
  evalMutex.lock(); // lock so NO other threads can enter this part!  
	try
	{
		delegate_->evalExpression(expr);
	}
	catch( exception &e )
	{
		exceptionInEval(e);
	}
  res = delegate_->getResult();
  error = delegate_->getError();
  evalMutex.unlock(); // unlock so other threads can enter this part!
}
