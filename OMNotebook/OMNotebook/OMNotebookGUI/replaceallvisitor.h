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

/*!
 * \file replaceallvisitor.h
 * \author Anders Fernström
 * \date 2006-08-24
 */

#ifndef IAEX_REPLACEALLVISITOR
#define IAEX_REPLACEALLVISITOR


//Qt Headers
#include <QtGlobal>
#include <QtWidgets>
#include <QTextCursor>
#include <QTextEdit>

// IAEX Headers
#include "visitor.h"
#include "document.h"
#include "inputcell.h"
#include "textcell.h"
#include "latexcell.h"
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

    void visitLatexCellNodeBefore( LatexCell *node )
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

    void visitLatexCellNodeAfter( LatexCell *node ){}

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
