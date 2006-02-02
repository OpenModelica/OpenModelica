/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet,
Department of Computer and Information Science, PELAB
See also: www.ida.liu.se/projects/OpenModelica

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    
	* Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

    * Neither the name of Linköpings universitet nor the names of its contributors
      may be used to endorse or promote products derived from this software without
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

For more information about the Qt-library visit TrollTech:s webpage regarding
licence: http://www.trolltech.com/products/qt/licensing.html

------------------------------------------------------------------------------------
*/

/*! 
* \file highlighterthread.cpp
* \author Anders Fernström
* \date 2005-12-17
*/

//STD Headers
#include <iostream>

//QT Headers
#include <QtGui/QTextCursor>
#include <QtGui/QTextEdit>

//IAEX Headers
#include "highlighterthread.h"
//#include "stylesheet.h"


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
		: QThread( parent ), highlighter_( highlighter )
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
		//2005-12-29
		while( true )
		{
			if( !stack_.isEmpty() )
			{
				QTextEdit *editor = stack_.pop();
				highlighter_->highlight( editor->document() );

				// force text to be updated
				QTextCursor cursor = editor->textCursor();
				editor->setTextCursor( cursor );
			}

			// 2006-01-05 AF, check if any editor should be removed
			while( !removeQueue_.isEmpty() )
			{
				QTextEdit *editor = removeQueue_.dequeue();
				int index = stack_.indexOf( editor );
				if( index >= 0 )
					stack_.remove( index );
			}

			// 2006-01-13 AF, stop thread when nothing to do
			if( stack_.isEmpty() )
				break;
		}
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
			if(	!isRunning() )
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
			if(	!isRunning() )
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

}