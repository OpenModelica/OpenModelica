/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2009, Linköpings University,
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

/*!
 * \file highlighterthread.h
 * \author Anders Fernström
 * \date 2005-12-16
 */

#ifndef HIGHLIGHTERTHREAD_H
#define HIGHLIGHTERTHREAD_H


//QT Headers
#include <QtCore/QStack>
#include <QtCore/QQueue>
#include <QtCore/QThread>

//IAEX Headers
#include "openmodelicahighlighter.h"

//farward declaration
class QTextEdit;

using namespace std;
namespace IAEX
{
	class HighlighterThread : public QThread
	{
	public:
		static HighlighterThread *instance( SyntaxHighlighter *highlighter = 0, QObject *parent = 0 );
		void run();
		void addEditor( QTextEdit *editor );		// Added 2005-12-29 AF
		void removeEditor( QTextEdit *editor );		// Added 2006-01-05 AF
		bool haveEditor( QTextEdit *editor );		// Added 2006-01-05 AF
		void setStop( bool stop );					// Added 2006-05-03 AF

	private:
		HighlighterThread( SyntaxHighlighter *highlighter = 0, QObject *parent = 0 );

	private:
		static HighlighterThread *instance_;
		bool stopHighlighting_;

		SyntaxHighlighter *highlighter_;
		QStack<QTextEdit*> stack_;
		QQueue<QTextEdit*> removeQueue_;
	};
}
#endif
