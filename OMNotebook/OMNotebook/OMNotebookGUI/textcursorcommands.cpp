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
 * \file cellcommands.h
 * \author Anders Fernström
 * \date 2005-11-03
 *
 * \brief Describes different textcursor commands
 */

//QT Headers
#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#else
#include <QtCore/QDir>
#include <QtGui/QMessageBox>
#include <QtGui/QTextCursor>
#include <QtGui/QTextDocumentFragment>
#include <QtGui/QTextEdit>
#include <QtGui/QTextFrame>
#include <QVariant>
#endif

#include <exception>
#include <stdexcept>
#include <typeinfo>

//IAEX Headers
#include "textcursorcommands.h"
#include "cellcursor.h"
#include "inputcell.h"
#include "graphcell.h"
#include "latexcell.h"


namespace IAEX
{
  /*!
     * \class TextCursorCutText
   * \author Anders Fernström
   * \date 2006-02-07
     *
     * \brief Command for cuting text
     */
  void TextCursorCutText::execute()
  {
    Cell *cell = document()->getCursor()->currentCell();
    if( cell )
    {
      if( typeid(InputCell) == typeid(*cell) )
      {
        InputCell *inputcell = dynamic_cast<InputCell*>(cell);
        if( inputcell->textEditOutput()->hasFocus() &&
          inputcell->isEvaluated() )
        {
          inputcell->textEditOutput()->copy();
        }
        else
          inputcell->textEdit()->cut();
      }
      else if( typeid(GraphCell) == typeid(*cell) )
      {
        GraphCell *graphcell = dynamic_cast<GraphCell*>(cell);
        if( graphcell->textEditOutput()->hasFocus() &&
          graphcell->isEvaluated() )
        {
          graphcell->textEditOutput()->copy();
        }
        else
          graphcell->textEdit()->cut();
      }

      else if( typeid(LatexCell) == typeid(*cell) )
      {
        LatexCell *latexcell = dynamic_cast<LatexCell*>(cell);
        if( latexcell->textEditOutput()->hasFocus() &&
          latexcell->isEvaluated() )
        {
          latexcell->textEditOutput()->cut();
        }
        else
          latexcell->textEdit()->cut();
      }


      else
      {
        QTextEdit *editor = cell->textEdit();
        if( editor )
        {
          editor->cut();
        }
      }
    }
  }


  /*!
     * \class TextCursorCopyText
   * \author Anders Fernström
   * \date 2006-02-07
     *
     * \brief Command for copying text
     */
  void TextCursorCopyText::execute()
  {
    Cell *cell = document()->getCursor()->currentCell();
    if( cell )
    {
      if( typeid(InputCell) == typeid(*cell) )
      {
        InputCell *inputcell = dynamic_cast<InputCell*>(cell);
        if( inputcell->textEditOutput()->hasFocus() &&
          inputcell->isEvaluated() )
        {
          inputcell->textEditOutput()->copy();
        }
        else
          inputcell->textEdit()->copy();
      }
      else if( typeid(GraphCell) == typeid(*cell) )
      {
        GraphCell *graphcell = dynamic_cast<GraphCell*>(cell);
        if( graphcell->textEditOutput()->hasFocus() &&
          graphcell->isEvaluated() )
        {
          graphcell->textEditOutput()->copy();
        }
        else
          graphcell->textEdit()->copy();
      }
      else if( typeid(LatexCell) == typeid(*cell) )
      {
        LatexCell *latexcell = dynamic_cast<LatexCell*>(cell);
        if( latexcell->textEditOutput()->hasFocus() &&
          latexcell->isEvaluated() )
        {
          latexcell->textEditOutput()->copy();
        }
        else
          latexcell->textEdit()->copy();
      }
      else
      {
        QTextEdit *editor = cell->textEdit();
        if( editor )
        {
          editor->copy();
        }
      }
    }
  }


  /*!
     * \class TextCursorCopyText
   * \author Anders Fernström
   * \date 2006-02-07
     *
     * \brief Command for pasting text
     */
  void TextCursorPasteText::execute()
  {
      Cell *cell = document()->getCursor()->currentCell();
      if( cell )
      {
        if( typeid(LatexCell) == typeid(*cell) )
        {
          LatexCell *latexcell = dynamic_cast<LatexCell*>(cell);
          if( latexcell->textEditOutput()->hasFocus() &&
            latexcell->isEvaluated() )
          {
            latexcell->textEditOutput()->paste();
          }
          else
          {
            latexcell->textEdit()->paste();
          }
        }
        else
        {
          QTextEdit *editor = cell->textEdit();
          if( editor )
          {
            editor->paste();
          }
        }

      }

  /*  QTextEdit *editor = document()->getCursor()->currentCell()->textEdit();
    if( editor )
    {
      editor->paste();
    }*/
  }


  /*!
     * \class TextCursorChangeFontFamily
   * \author Anders Fernström
   * \date 2005-11-03
     *
     * \brief Command for changing font family
     */
  void TextCursorChangeFontFamily::execute()
  {
    QTextEdit *editor = document()->getCursor()->currentCell()->textEdit();

    if( editor )
      editor->setFontFamily( family_ );
  }


  /*!
     * \class TextCursorChangeFontFace
   * \author Anders Fernström
   * \date 2005-11-03
   * \date 2006-01-13 (update)
     *
     * \brief Command for changing font face
   *
   * 2005-11-07 AF, Added function (case 4) in switch to change
   * strikckout settings
   * 2005-11-15 AF, added trick to get correct style on links
   * 2006-01-13 AF, remove trick to get correct style on links because
   * it made undo/redo work incorrectly
     */
  void TextCursorChangeFontFace::execute()
  {
    QTextEdit *editor = document()->getCursor()->currentCell()->textEdit();
    QFont font;

    if( editor )
    {
      switch( face_ )
      {
      case 0: // Plain
        editor->setFontWeight( QFont::Normal );
        editor->setFontItalic( false );
        editor->setFontUnderline( false );

        font = editor->currentFont();
        font.setStrikeOut( false );
        editor->setCurrentFont( font );
        break;
      case 1: // Bold
        if( editor->fontWeight() != QFont::Normal )
          editor->setFontWeight( QFont::Normal );
        else
          editor->setFontWeight( QFont::Bold );
        break;
      case 2: // Italic
        if( editor->fontItalic() )
          editor->setFontItalic( false );
        else
          editor->setFontItalic( true );
        break;
      case 3: // Underline
        if( editor->fontUnderline() )
          editor->setFontUnderline( false );
        else
          editor->setFontUnderline( true );
        break;
      case 4: // Strickout
        font = editor->currentFont();
        if( font.strikeOut() )
          font.setStrikeOut( false );
        else
          font.setStrikeOut( true );
        editor->setCurrentFont( font );
        break;
      }

      // ugly trick to make the sure that the links haven't change
      // color
      /*
      if( !editor->toPlainText().isEmpty() )
      {
        int start = editor->textCursor().selectionStart();
        int end = editor->textCursor().selectionEnd();
        editor->setHtml( editor->toHtml() );

        QTextCursor cursor( editor->textCursor() );
        cursor.setPosition( start );
        cursor.setPosition( end, QTextCursor::KeepAnchor );
        editor->setTextCursor( cursor );
      }*/
    }
  }


  /*!
     * \class TextCursorChangeFontSize
   * \author Anders Fernström
   * \date 2005-11-03
   * \date 2005-11-04 (update)
     *
     * \brief Command for changing font size
   *
   * 2005-11-04 AF, implemented the function
     */
  void TextCursorChangeFontSize::execute()
  {
    QTextEdit *editor = document()->getCursor()->currentCell()->textEdit();

    if( editor )
      editor->setFontPointSize( size_ );

  }


  /*!
     * \class TextCursorChangeFontStretch
   * \author Anders Fernström
   * \date 2005-11-03
   * \date 2005-11-04 (update)
     *
     * \brief Command for changing font stretch
   *
   * 2005-11-04 AF, implemented the function
     */
  void TextCursorChangeFontStretch::execute()
  {
    QTextCursor cursor( document()->getCursor()->currentCell()->textCursor() );
    if( !cursor.isNull() )
    {
      QTextCharFormat format = cursor.charFormat();
      QFont font = format.font();

      int oldStretch = font.stretch();
      if( oldStretch != stretch_ )
      {
        font.setStretch( stretch_ );
        format.setFont( font );

        cursor.mergeCharFormat ( format );

        if( oldStretch == cursor.charFormat().font().stretch() )
        {
          // 2006-01-30 AF, add message box
          QMessageBox::warning( 0, QObject::tr("Warning"), QObject::tr("QT was unable to stretch the font"), "OK" );
        }
      }
    }

  }


  /*!
     * \class TextCursorChangeFontColor
   * \author Anders Fernström
   * \date 2005-11-03
   * \date 2006-01-13 (update)
     *
     * \brief Command for changing font color
   *
   * 2005-11-07 AF, implemented the function
   * 2005-11-15 AF, added trick to get correct style on links
   * 2006-01-13 AF, remove trick to get correct style on links because
   * it made undo/redo work incorrectly
     */
  void TextCursorChangeFontColor::execute()
  {
    QTextEdit *editor = document()->getCursor()->currentCell()->textEdit();

    if( editor )
    {
      editor->setTextColor( color_ );


      // ugly trick to make the sure that the links haven't change
      // color
      /*
      if( !editor->toPlainText().isEmpty() )
      {
        int start = editor->textCursor().selectionStart();
        int end = editor->textCursor().selectionEnd();
        editor->setHtml( editor->toHtml() );

        QTextCursor cursor( editor->textCursor() );
        cursor.setPosition( start );
        cursor.setPosition( end, QTextCursor::KeepAnchor );
        editor->setTextCursor( cursor );
      }
      */
    }
  }


  /*!
     * \class TextCursorChangeTextAlignment
   * \author Anders Fernström
   * \date 2005-11-03
   * \date 2005-11-07 (update)
     *
     * \brief Command for changing text alignment
   *
   * 2005-11-07 AF, implemented the function
     */
  void TextCursorChangeTextAlignment::execute()
  {
    QTextEdit *editor = document()->getCursor()->currentCell()->textEdit();

    if( editor )
    {
      editor->setAlignment( (Qt::Alignment)alignment_ );

      // create a rule for the alignment
      Rule *rule;
      if( (Qt::Alignment)alignment_ == Qt::AlignLeft )
        rule = new Rule( "TextAlignment", "Left" );
      else if( (Qt::Alignment)alignment_ == Qt::AlignRight )
        rule = new Rule( "TextAlignment", "Right" );
      else if( (Qt::Alignment)alignment_ == Qt::AlignHCenter )
        rule = new Rule( "TextAlignment", "Center" );
      else if( (Qt::Alignment)alignment_ == Qt::AlignJustify )
        rule = new Rule( "TextAlignment", "Justify" );
      else
        rule = new Rule( "TextAlignment", "Left" );

      document()->getCursor()->currentCell()->addRule( rule );

      // update the cells style
      document()->getCursor()->currentCell()->style()->setAlignment( alignment_ );
    }
  }


  /*!
     * \class TextCursorChangeVerticalAlignment
   * \author Anders Fernström
   * \date 2005-11-03
   * \date 2005-11-07 (update)
     *
     * \brief Command for changing the vertical alignment
   *
   * 2005-11-07 AF, implemented the function
     */
  void TextCursorChangeVerticalAlignment::execute()
  {
    QTextCursor cursor( document()->getCursor()->currentCell()->textCursor() );
    if( !cursor.isNull() )
    {

      QTextCharFormat format = cursor.charFormat();
      format.setVerticalAlignment( (QTextCharFormat::VerticalAlignment)alignment_ );

      cursor.mergeCharFormat ( format );
    }
  }


  /*!
     * \class TextCursorChangeMargin
   * \author Anders Fernström
   * \date 2005-11-03
   * \date 2005-11-07 (update)
     *
     * \brief Command for changing margin
   *
   * 2005-11-07 AF, implemented the function
     */
  void TextCursorChangeMargin::execute()
  {
    QTextEdit *editor = document()->getCursor()->currentCell()->textEdit();

    if( editor )
    {
      QTextFrameFormat format = editor->document()->rootFrame()->frameFormat();
      format.setMargin( margin_ );
      editor->document()->rootFrame()->setFrameFormat( format );

      // create a rule for the margin
      QString ruleValue;
      ruleValue.setNum( margin_ );
      Rule *rule = new Rule( "OMNotebook_Margin", ruleValue );
      document()->getCursor()->currentCell()->addRule( rule );

      // update the cells style
      document()->getCursor()->currentCell()->style()->textFrameFormat()->setMargin( margin_ );
    }
  }


  /*!
     * \class TextCursorChangePadding
   * \author Anders Fernström
   * \date 2005-11-03
   * \date 2005-11-07 (update)
     *
     * \brief Command for changing padding
   *
   * 2005-11-07 AF, implemented the function
     */
  void TextCursorChangePadding::execute()
  {
    QTextEdit *editor = document()->getCursor()->currentCell()->textEdit();

    if( editor )
    {
      QTextFrameFormat format = editor->document()->rootFrame()->frameFormat();
      format.setPadding( padding_ );
      editor->document()->rootFrame()->setFrameFormat( format );

      // create a rule for the padding
      QString ruleValue;
      ruleValue.setNum( padding_ );
      Rule *rule = new Rule( "OMNotebook_Padding", ruleValue );
      document()->getCursor()->currentCell()->addRule( rule );

      // update the cells style
      document()->getCursor()->currentCell()->style()->textFrameFormat()->setPadding( padding_ );
    }
  }


  /*!
     * \class TextCursorChangeBorder
   * \author Anders Fernström
   * \date 2005-11-03
   * \date 2005-11-07 (update)
     *
     * \brief Command for changing border
   *
   * 2005-11-07 AF, implemented the function
     */
  void TextCursorChangeBorder::execute()
  {
    QTextEdit *editor = document()->getCursor()->currentCell()->textEdit();

    if( editor )
    {
      QTextFrameFormat format = editor->document()->rootFrame()->frameFormat();
      format.setBorder( border_ );
      editor->document()->rootFrame()->setFrameFormat( format );

      // create a rule for the border
      QString ruleValue;
      ruleValue.setNum( border_ );
      Rule *rule = new Rule( "OMNotebook_Border", ruleValue );
      document()->getCursor()->currentCell()->addRule( rule );

      // update the cells style
      document()->getCursor()->currentCell()->style()->textFrameFormat()->setBorder( border_ );
    }
  }


  /*!
     * \class TextCursorInsertImage
   * \author Anders Fernström
   * \date 2005-11-18
     *
     * \brief Command for inserting an image
     */
  void TextCursorInsertImage::execute()
  {
    QTextCursor cursor( document()->getCursor()->currentCell()->textCursor() );
    if( !cursor.isNull() )
    {
      QImage* image = new QImage( filepath_ );
      if( !image->isNull() )
      {
        QString imagename = document()->addImage( image );

        QTextCursor cursor( document()->getCursor()->currentCell()->textCursor() );
        if( !cursor.isNull() )
        {
          QTextEdit *editor = document()->getCursor()->currentCell()->textEdit();
          if( editor )
          {
            // save text settings and set them after image have been inserted
            QTextCharFormat format = cursor.charFormat();
            if( editor->toPlainText().isEmpty() )
              format = *document()->getCursor()->currentCell()->style()->textCharFormat();

            QTextImageFormat imageformat;
            imageformat.merge( format );
            imageformat.setHeight( height_ );
            imageformat.setWidth( width_ );
            imageformat.setName( imagename );

            cursor.insertImage( imageformat );
          }
        }
      }
      else
      {
        std::string str = std::string("Could not open image: ") + filepath_.toStdString().c_str();
        throw std::runtime_error( str.c_str() );
      }
    }
  }


  /*!
     * \class TextCursorInsertLink
   * \author Anders Fernström
   * \date 2005-12-05
     *
     * \brief Command for inserting an link
     */
  void TextCursorInsertLink::execute()

  {

//    QTextCursor cursor( document()->getCursor()->currentCell()->textCursor() );
    if( !cursor.isNull() )
    {
      if( cursor.hasSelection() )
      {
        QDir dir;
        QString currentfilepath = document()->getFilename();
        if( !currentfilepath.isEmpty() && !currentfilepath.isNull() )
          dir.setPath( QFileInfo(currentfilepath).absolutePath() );

        // check if dir exist
        if( !dir.exists() )
          return;
        // get the relative link path
        QString relativepath = dir.relativeFilePath( filepath_ );

        // create html code for the link and insert it to the document'
        QString text = cursor.selection().toHtml();
        int fragmentStart = text.indexOf( "<!--StartFragment-->",
          0, Qt::CaseInsensitive ) + 20;
        int fragmentEnd = text.indexOf( "<!--EndFragment-->",
          fragmentStart, Qt::CaseInsensitive );

        QString html = text.mid( fragmentStart, fragmentEnd - fragmentStart );
        QString htmlcode = "<a href=\"" + relativepath + "\">" +
          html + "</a>";
        cursor.insertFragment( QTextDocumentFragment::fromHtml( htmlcode ));

        // set the cursor, so there is no selection
                QTextEdit *editor = document()->getCursor()->currentCell()->textEdit();
        if( editor )
          editor->setTextCursor( cursor );
      }
    }
  }

}
