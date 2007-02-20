/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet,
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
 * \file replaceallvisitor.h
 * \author Anders Fernström
 * \date 2006-08-24
 */

#ifndef IAEX_REPLACEALLVISITOR
#define IAEX_REPLACEALLVISITOR


//Qt Headers
#include <QtGui/QTextCursor>
#include <QtGui/QTextEdit>

// IAEX Headers
#include "visitor.h"
#include "document.h"
#include "inputcell.h"
#include "textcell.h"
#include "graphcell.h"


namespace IAEX
{
	class ReplaceAllVisitor : public Visitor
	{
	public:
		ReplaceAllVisitor( QString findText, QString replaceText, bool matchCase = false, bool matchWord = false, int* count = 0 )
			: findText_( findText ), replaceText_( replaceText ), matchCase_( matchCase ), matchWord_( matchWord ), count_( count )
		{}
		~ReplaceAllVisitor(){}

		// Visitor function - CELL
		void visitCellNodeBefore( Cell *node ){}
		void visitCellNodeAfter( Cell *node ){}

		// Visitor function - GROUPCELL
		void visitCellGroupNodeBefore( CellGroup *node ){}
		void visitCellGroupNodeAfter( CellGroup *node ){}

		// Visitor function - TEXTCELL
		void visitTextCellNodeBefore( TextCell *node )
		{
			if( node->textEdit() )
			{
				int options( 0 );

				// move cursor to start of text
				QTextCursor cursor = node->textEdit()->textCursor();
				cursor.movePosition( QTextCursor::Start );
				node->textEdit()->setTextCursor( cursor );

				// match case & match word
				if( matchCase_ && matchWord_ )
					options = QTextDocument::FindCaseSensitively | QTextDocument::FindWholeWords;
				else if( matchCase_ )
					options = QTextDocument::FindCaseSensitively;
				else if( matchWord_ )
					options = QTextDocument::FindWholeWords;

				// replace all
				while( node->textEdit()->find( findText_, (QTextDocument::FindFlag)options ))
				{
					node->textEdit()->textCursor().insertText( replaceText_ );
					if( count_ )
						(*count_)++;
				}
			}
		}
		void visitTextCellNodeAfter( TextCell *node ){}

		// Visitor function - INPUTCELL
		void visitInputCellNodeBefore( InputCell *node )
		{
			if( node->textEdit() )
			{
				int options( 0 );

				// move cursor to start of text
				QTextCursor cursor = node->textEdit()->textCursor();
				cursor.movePosition( QTextCursor::Start );
				node->textEdit()->setTextCursor( cursor );

				// match case & match word
				if( matchCase_ && matchWord_ )
					options = QTextDocument::FindCaseSensitively | QTextDocument::FindWholeWords;
				else if( matchCase_ )
					options = QTextDocument::FindCaseSensitively;
				else if( matchWord_ )
					options = QTextDocument::FindWholeWords;

				// replace all
				while( node->textEdit()->find( findText_, (QTextDocument::FindFlag)options ))
				{
					node->textEdit()->textCursor().insertText( replaceText_ );
					if( count_ )
						(*count_)++;
				}
			}
		}
		void visitInputCellNodeAfter( InputCell *node ){}


		// Visitor function - GRAPHCELL
		void visitGraphCellNodeBefore( GraphCell *node )
		{
			if( node->textEdit() )
			{
				int options( 0 );

				// move cursor to start of text
				QTextCursor cursor = node->textEdit()->textCursor();
				cursor.movePosition( QTextCursor::Start );
				node->textEdit()->setTextCursor( cursor );

				// match case & match word
				if( matchCase_ && matchWord_ )
					options = QTextDocument::FindCaseSensitively | QTextDocument::FindWholeWords;
				else if( matchCase_ )
					options = QTextDocument::FindCaseSensitively;
				else if( matchWord_ )
					options = QTextDocument::FindWholeWords;

				// replace all
				while( node->textEdit()->find( findText_, (QTextDocument::FindFlag)options ))
				{
					node->textEdit()->textCursor().insertText( replaceText_ );
					if( count_ )
						(*count_)++;
				}
			}
		}
		void visitGraphCellNodeAfter( GraphCell *node ){}

		// Visitor function - CURSORCELL
		void visitCellCursorNodeBefore( CellCursor *cursor ){}
		void visitCellCursorNodeAfter( CellCursor *cursor ){}
		

	private:
		QString findText_;
		QString replaceText_;
		bool matchCase_;
		bool matchWord_;
		int* count_;
	};
}

#endif
