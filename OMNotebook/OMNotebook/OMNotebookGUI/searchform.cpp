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
 * \file searchform.cpp
 * \author Anders Fernström
 * \date 2006-08-24
 */


// QT Headers
#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#include <QMessageBox>
#else
#include <QtGui/QMessageBox>
#endif

// IAEX Headers
#include "cellcursor.h"
#include "cellgroup.h"
#include "document.h"
#include "inputcell.h"
#include "searchform.h"
#include "replaceallvisitor.h"

#include <typeinfo>

namespace IAEX
{

  /*!
   * \author Anders Fernström
   * \date 2006-08-24
   *
   * \brief Class constructor
   */
  SearchForm::SearchForm( QWidget* parent, Document* document, bool viewReplace )
    : QDialog( parent ),
    document_( document ),
    viewReplace_( viewReplace )
  {
    ui.setupUi(this);

    // connections
    connect( ui.viewReplaceButton_, SIGNAL( clicked() ),
      this, SLOT( showHideReplace() ));
    connect( ui.hideReplaceButton_, SIGNAL( clicked() ),
      this, SLOT( showHideReplace() ));
    connect( ui.searchButton_, SIGNAL( clicked() ),
      this, SLOT( search() ));
    connect( ui.replaceButton_, SIGNAL( clicked() ),
      this, SLOT( replace() ));
    connect( ui.replaceAllButton_, SIGNAL( clicked() ),
      this, SLOT( replaceAll() ));
    connect( ui.searchComboBox_, SIGNAL( returnPressed() ),
      this, SLOT( search() ));
    connect( ui.closeButton_, SIGNAL( clicked() ),
      this, SLOT( closeForm() ));

    // Replace stuff
    showOrHideReplace();
  }

  /*!
   * \author Anders Fernström
   * \date 2006-08-24
   *
   * \brief Class destructor
   */
  SearchForm::~SearchForm()
  {

  }

  /*!
   * \author Anders Fernström
   * \date 2006-08-24
   *
   * \brief Function for seting the correct notebook/document
   */
  void SearchForm::setDocument( Document* document )
  {
    document_ = document;
  }


  // PRIVATE SLOTS / MAIN CORE FUNCTION
  // ------------------------------------------------------------------

  /*!
   * \author Anders Fernström
   * \date 2006-08-24
   *
   * \brief Function for searching a word
   */
  void SearchForm::search()
  {
    if( !document_ )
    {
      QMessageBox::information( this, "Information", "This window don't contain a document." );
      return;
    }

    // check if document is empty
    if( document_->isEmpty() )
    {
      QMessageBox::information( this, "Information", "This notebook is empty." );
      return;
    }

    // find text
    searchText_ = ui.searchComboBox_->currentText();
    if( searchText_.isEmpty() )
    {
      QMessageBox::information( this, "Information", "You must enter a text that should be searched for." );
      return;
    }

    // add filetext to search box
    if( ui.searchComboBox_->findText( searchText_ ) == -1 )
      ui.searchComboBox_->addItem( searchText_ );

    // match case & match word
    int options( 0 );
    matchCase_ = ui.matchCaseBox_->isChecked();
    matchWord_ = ui.matchWord_->isChecked();
    if( matchCase_ && matchWord_ )
      options = QTextDocument::FindCaseSensitively | QTextDocument::FindWholeWords;
    else if( matchCase_ )
      options = QTextDocument::FindCaseSensitively;
    else if( matchWord_ )
      options = QTextDocument::FindWholeWords;

    // get options (inside group & search direction) and current cell
    bool insideClosedCell = ui.insideGroupCellBox_->isChecked();
    bool searchDown = ui.downRadioButton_->isChecked();
    Cell* currentCell = document_->getCursor()->currentCell();

    // if no currentCell, use first cell in document
    if( !currentCell )
      currentCell =  document_->getMainCell();

    if( !currentCell )
    {
      QMessageBox::information( this, "Information", "No cell is selected. Please select a cell and try again." );
      return;
    }

    // SEARCH
    bool foundText( false );
    while( !foundText )
    {
      // if cell have a editor, search in it.
      QTextEdit* editor;
      if( currentCell )
      {
        editor = currentCell->textEdit();
        if( editor )
        {
          // FIND FUNCTION
          if( searchDown )
          {
            if( editor->find( searchText_, (QTextDocument::FindFlag)options ))
            {
              // TODO: Activate Main Window, don't know if it is necessary
              //parentWidget()->activateWindow();
              break;
            }
          }
          else
          {
            if( editor->find( searchText_, (QTextDocument::FindFlag)options | QTextDocument::FindBackward ))
            {
              // TODO: Activate Main Window, don't know if it is necessary
              //parentWidget()->activateWindow();
              break;
            }
          }
        }

        // search inside inputcells
        if( typeid( (*currentCell) ) == typeid( InputCell ) )
        {
          InputCell* inputcell = dynamic_cast<InputCell*>( currentCell );
          if( inputcell )
          {
            // only look inside open inputcells
            if( !inputcell->isClosed() )
            {
              editor = inputcell->textEditOutput();
              if( editor )
              {
                // FIND FUNCTION
                if( searchDown )
                {
                  if( editor->find( searchText_, (QTextDocument::FindFlag)options ))
                    break;
                }
                else
                {
                  if( editor->find( searchText_, (QTextDocument::FindFlag)options | QTextDocument::FindBackward ))
                    break;
                }
              }
            }
          }
        }
      }

      // no hit in cell, move to next cell
      if( searchDown )
      {
        // DOWN
        // check if the cell after the current cell is a closed cell, if so open it.
        if( insideClosedCell )
        {
          if( currentCell )
          {
            Cell* nextCell = currentCell->next(); // this cell should be the cellcursor
            if( nextCell )
            {
              if( typeid( (*nextCell) ) == typeid( CellCursor ) )
              {
                Cell* nextCellAgain = nextCell->next();
                if( nextCellAgain )
                {
                  if( typeid( (*nextCellAgain) ) == typeid( CellGroup ) )
                  {
                    CellGroup* groupcell = dynamic_cast<CellGroup*>( nextCellAgain );
                    if( groupcell )
                    {
                      if( groupcell->isClosed() )
                      {
                        groupcell->setClosed( false, false );
                        groupcell->closeChildCells();
                        openedCells_.push_back( groupcell );
                      }
                    }
                  }
                  else if( typeid( (*nextCellAgain) ) == typeid( InputCell ) )
                  {
                    InputCell* inputcell = dynamic_cast<InputCell*>( nextCellAgain );
                    if( inputcell )
                    {
                      if( inputcell->isClosed() )
                      {
                        inputcell->setClosed( false, false );
                        openedCells_.push_back( inputcell );
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // before moving, clear last cursor selection
        if( currentCell->textEdit() )
        {
          QTextCursor cursor = currentCell->textEdit()->textCursor();
          cursor.clearSelection();
          currentCell->textEdit()->setTextCursor( cursor );

          // if inputcell, clear output also
          if( typeid( (*currentCell) ) == typeid( InputCell ) )
          {
            InputCell* inputcell = dynamic_cast<InputCell*>( currentCell );
            if( inputcell )
            {
              QTextCursor cursor = inputcell->textEditOutput()->textCursor();
              cursor.clearSelection();
              inputcell->textEditOutput()->setTextCursor( cursor );
            }
          }
        }

        if( document_->getCursor()->moveDown() )
        {
          // after move, update scrollarea
          document_->updateScrollArea();

          // moved down one cell, get new currentcell
          currentCell = document_->getCursor()->currentCell();

          // if the new currentCell have a text editor, move the text cursor to pos 'start'
          if( currentCell )
          {
            editor = currentCell->textEdit();
            if( editor )
            {
              QTextCursor cursor = editor->textCursor();
              cursor.movePosition( QTextCursor::Start );
              editor->setTextCursor( cursor );
            }

            // if inputcell, also move the cursor of the output
            if( typeid( (*currentCell) ) == typeid( InputCell ) )
            {
              InputCell* inputcell = dynamic_cast<InputCell*>( currentCell );
              if( inputcell )
              {
                editor = inputcell->textEditOutput();
                if( editor )
                {
                  QTextCursor cursor = editor->textCursor();
                  cursor.movePosition( QTextCursor::Start );
                  editor->setTextCursor( cursor );
                }
              }
            }
          }
        }
        else
        {
          // unable to move down, assume that the cursor have reached end of document
          QString msg = QString( "Reached end of document. No more instances of '" ) +
            searchText_ + QString( "' found." );
          QMessageBox::information( this, "Information", msg );
          return;
        }
      }
      else
      {
        // UP
        // before moving, clear last cursor selection
        if( currentCell->textEdit() )
        {
          QTextCursor cursor = currentCell->textEdit()->textCursor();
          cursor.clearSelection();
          currentCell->textEdit()->setTextCursor( cursor );

          // if inputcell, clear output also
          if( typeid( (*currentCell) ) == typeid( InputCell ) )
          {
            InputCell* inputcell = dynamic_cast<InputCell*>( currentCell );
            if( inputcell )
            {
              QTextCursor cursor = inputcell->textEditOutput()->textCursor();
              cursor.clearSelection();
              inputcell->textEditOutput()->setTextCursor( cursor );
            }
          }
        }

        // move
        if( document_->getCursor()->moveUp() )
        {
          // after move, update scrollarea
          document_->updateScrollArea();

          // moved up one cell
          currentCell = document_->getCursor()->currentCell();
          if( currentCell )
          {
            // if the new currentCell have a text editor,
            // move the text cursor to pos 'end'
            editor = currentCell->textEdit();
            if( editor )
            {
              QTextCursor cursor = editor->textCursor();
              cursor.movePosition( QTextCursor::End );
              editor->setTextCursor( cursor );
            }

            // if inputcell, also move the cursor of the output
            if( typeid( (*currentCell) ) == typeid( InputCell ) )
            {
              InputCell* inputcell = dynamic_cast<InputCell*>( currentCell );
              if( inputcell )
              {
                editor = inputcell->textEditOutput();
                if( editor )
                {
                  QTextCursor cursor = editor->textCursor();
                  cursor.movePosition( QTextCursor::End );
                  editor->setTextCursor( cursor );
                }
              }
            }

            // if the new currentCell is closed and the option inside cells is set,
            // open the new cell
            if( insideClosedCell && currentCell->isClosed() )
            {
              if( typeid( (*currentCell) ) == typeid( CellGroup ) )
              {
                CellGroup* groupcell = dynamic_cast<CellGroup*>( currentCell );
                if( groupcell )
                {
                  groupcell->setClosed( false, false );
                  groupcell->closeChildCells();
                  openedCells_.push_back( currentCell );
                }
              }
            }
          }
        }
        else
        {
          // unable to move up, assume that the cursor have reached start of document
          QString msg = QString( "Reached start of document. No more instances of '" ) +
            searchText_ + QString( "' found." );
          QMessageBox::information( this, "Information", msg );
          return;
        }
      }
    }
  }

  /*!
   * \author Anders Fernström
   * \date 2006-08-24
   *
   * \brief Function for replaceing a word
   */
  void SearchForm::replace()
  {
    if( !document_ )
    {
      QMessageBox::information( this, "Information", "This window don't contain a document." );
      return;
    }

    bool correct( false );
    Cell* currentCell = document_->getCursor()->currentCell();
    if( currentCell )
    {
      QTextEdit* editor = currentCell->textEdit();
      if( editor )
      {
        QTextCursor cursor = editor->textCursor();
        if( cursor.hasSelection() )
        {
          // check if correct text is selected
          int cs( 0 );
          QString text = cursor.selectedText();
          if( matchCase_ )
            cs = Qt::CaseSensitive;
          else
            cs = Qt::CaseInsensitive;

          if( text.startsWith( searchText_, ( Qt::CaseSensitivity)cs ) &&
            text.endsWith( searchText_, ( Qt::CaseSensitivity)cs ))
          {
            // REPLACE
            correct = true;
            cursor.insertText( ui.replaceText_->text() );
          }
        }
      }
    }

    // if correct, do search again
    if( correct )
      search();
    else
    {
      QMessageBox::information( this, "Information", "The correct search text isn't selected, can't preform replace." );
      return;
    }
  }

  /*!
   * \author Anders Fernström
   * \date 2006-08-24
   *
   * \brief Function for replaceing all word that match the specified
   * word.
   */
  void SearchForm::replaceAll()
  {
    // check if document is empty
    if( document_ )
    {
      if( document_->isEmpty() )
      {
        QMessageBox::information( this, "Information", "This document is empty." );
        return;
      }
    }
    else
    {
      QMessageBox::information( this, "Information", "This window don't contain a document." );
      return;
    }

    int count( 0 );

    // find/replace text
    QString findText = ui.searchComboBox_->currentText();
    QString replaceText = ui.replaceText_->text();

    if( findText.isEmpty() )
    {
      QMessageBox::information( this, "Information", "You must enter a text that should be replaced." );
      return;
    }

    // clear find/replace text
    ui.searchComboBox_->addItem( findText );
    ui.searchComboBox_->clearEditText();
    ui.replaceText_->clear();

    // start making a composite command in the commandcenter
    // create and run the replace all visitor
    ReplaceAllVisitor visitor( findText, replaceText, ui.matchCaseBox_->isChecked(),
      ui.matchWord_->isChecked(), &count );
    document_->runVisitor( visitor );

    // done, show message box with status info
    QString msg;
    msg.setNum( count );
    msg += QString( " instances of the text '" ) + findText +
      QString( "' was replaced with the text '" ) + replaceText + QString( "'." );
    QMessageBox::information( this, "Done", msg );
  }

  /*!
   * \author Anders Fernström
   * \date 2006-08-24
   *
   * \brief Function for showing/hiding the replace function
   */
  void SearchForm::showHideReplace()
  {
    viewReplace_ = !viewReplace_;
    showOrHideReplace();
  }

  /*!
   * \author Anders Fernström
   * \date 2006-08-24
   *
   * \brief Close search form and restore any closed cells that had been opened
   */
  void SearchForm::closeForm()
  {
    for (auto cell: openedCells_) {
      cell->setClosed( true, false );
      CellGroup* groupcell = dynamic_cast<CellGroup*>( cell );
      if( groupcell ) groupcell->closeChildCells();
    }

    close();
  }

  // HELP FUNCTIONS
  // ------------------------------------------------------------------

  /*!
   * \author Anders Fernström
   * \date 2006-08-24
   *
   * \brief Help function for showing/hiding the replace function
   */
  void SearchForm::showOrHideReplace()
  {
    if( viewReplace_ )
    {
      // View Replace
      ui.viewReplaceButton_->hide();
      ui.hideReplaceButton_->show();
      ui.replaceText_->show();
      ui.replaceLabel_->show();
      ui.replaceButton_->show();
      ui.replaceAllButton_->show();

      setWindowTitle( tr("Replace Form") );
    }
    else
    {
      // Don't show replace - only search
      ui.viewReplaceButton_->show();
      ui.hideReplaceButton_->hide();
      ui.replaceText_->hide();
      ui.replaceLabel_->hide();
      ui.replaceButton_->hide();
      ui.replaceAllButton_->hide();

      setWindowTitle( tr("Search Form") );
    }
  }
}
