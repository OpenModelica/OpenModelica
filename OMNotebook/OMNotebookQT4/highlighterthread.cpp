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

/*!
* \file highlighterthread.cpp
* \author Anders Fernström
* \date 2005-12-17
*/

//STD Headers
#include <iostream>

//QT Headers
#include <QtCore/QCoreApplication>
#include <QtGui/QTextCursor>
#include <QtGui/QTextBrowser>
#include <QtGui/QTextEdit>
#include <QMessageBox>

//IAEX Headers
#include "highlighterthread.h"


using namespace std;
namespace IAEX
{
	/*!
	 * \class NullHighlighter
	 * \author Ingemar Axelsson and Anders Ferström
	 * \date 2006-01-09 (update)
	 *
	 * \brief This class is used if no SyntaxHighlighter is set.
	 *
	 * 2005-10-27 AF, Change this class to reflect the changes made
	 * to the SyntaxHighlighter interface.
	 * 2006-01-09 AF, Change this class to reflect the changes made
	 * to the SyntaxHighlighter interface (again).
	 */
	class NullHighlighter : public SyntaxHighlighter
	{
	public:
		virtual void highlight(QTextDocument *){}
	};

	/*!
	 * \class HighlighterThread
	 * \author Anders Fernström
	 * \date 2005-12-17
	 *
	 * \bried Class for runing the highligher in a seperted thread.
	 */

	/*!
	 * \author Anders Fernström
	 * \date 2005-12-17
	 *
	 * \brief The class constructor
	 */
	HighlighterThread::HighlighterThread( SyntaxHighlighter *highlighter, QObject *parent )
		: QThread( parent ),
		highlighter_( highlighter ),
		stopHighlighting_( true )
	{
	}

	// The instance
	HighlighterThread *HighlighterThread::instance_ = 0;

	/*!
	 * \author Anders Fernström
	 * \date 2005-12-17
	 *
	 * \brief returns the instance of the object, if no instance exists
	 * the functions creates an new instance.
	 *
	 * \return the instance
	 */
	HighlighterThread *HighlighterThread::instance( SyntaxHighlighter *highlighter, QObject *parent )
	{
		if( !instance_ )
		{
			if( highlighter )
				instance_ = new HighlighterThread( highlighter, parent );
			else
				instance_ = new HighlighterThread( new NullHighlighter(), parent );
		}

		return instance_;
	}


	/*!
	 * \author Anders Fernström
	 * \date 2005-12-17
	 * \date 2006-01-13 (update)
	 *
	 * \brief implementation of the virutal run function in QThread
	 *
	 * 2006-01-06 AF, added remove queue
	 * 2006-01-13 AF, stop thread when nothing to do
	 */
	void HighlighterThread::run()
	{
		//cout << "Highlight-1" << endl;

		//2005-12-29
		while( true )
		{
			//cout << "Highlight-2" << endl;

			if( !stack_.isEmpty() )
			{
				QTextEdit *editor = stack_.pop();

				//if( editor->isVisible() )
				//{
					highlighter_->highlight( editor->document() );


					// force text to be updated
//					editor->update();
//					QCoreApplication::processEvents();
//					QTextCursor cursor = editor->textCursor();
//					editor->setTextCursor( cursor );
				//}
				//else
				//{
					// add last
					//stack_.push_back( editor );
				//}
			}

			// 2006-01-05 AF, check if any editor should be removed
			while( !removeQueue_.isEmpty() )
			{
				//cout << "Highlight - Remove size: " << removeQueue_.size() << endl;
				QTextEdit *editor = removeQueue_.dequeue();
				int index = stack_.indexOf( editor );
				if( index >= 0 )
					stack_.remove( index );
			}

			//cout << "Highlight - Stack size: " << stack_.size() << endl;

			// 2006-01-13 AF, stop thread when nothing to do
			if( stack_.isEmpty() )
			{
				//cout << "Highlight: Exit thread" << endl;
				//this->exit();
				break;
			}

		}

		//cout << "Highlight-3" << endl;
	}

	/*!
	 * \author Anders Fernström
	 * \date 2005-12-29
	 * \date 2006-01-13 (update)
	 *
	 * \brief add an text editor for highlightning
	 *
	 * 2006-01-13 AF, restart thread if it have been stoped
	 */
	void HighlighterThread::addEditor( QTextEdit *editor )
	{
		if( editor )
		{
			int index = stack_.indexOf( editor );
			if( index >= 0 )
			{
				stack_.remove( index );
				stack_.push( editor );
			}
			else
				stack_.push( editor );

			// 2006-01-13 AF, restart the thread
			if(	!isRunning() && !stopHighlighting_ )
				start( QThread::LowPriority );
		}
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-01-05
	 * \date 2006-01-13 (update)
	 *
	 * \brief add text editor to remove queue
	 *
	 * 2006-01-13 AF, restart thread if it have been stoped
	 */
	void HighlighterThread::removeEditor( QTextEdit *editor )
	{
		if( editor )
		{
			removeQueue_.enqueue( editor );

			// 2006-01-13 AF, restart the thread
			if(	!isRunning() && !stopHighlighting_ )
				start( QThread::LowPriority );
		}
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-01-05
	 *
	 * \brief check if text editor is in highlighter thread
	 */
	bool HighlighterThread::haveEditor( QTextEdit *editor )
	{
		if( editor )
		{
			if( stack_.indexOf( editor ) >= 0 )
				return true;
			else
				return false;
		}

		return false;
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-01-05
	 *
	 * \brief Set whether or not highlight should be stopped.
	 */
	void HighlighterThread::setStop( bool stop )
	{
		stopHighlighting_ = stop;
		if( stopHighlighting_ && isRunning() )
			this->exit();

		if( !stopHighlighting_ && !isRunning() )
			start( QThread::LowPriority );
	}

}
