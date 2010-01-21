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
