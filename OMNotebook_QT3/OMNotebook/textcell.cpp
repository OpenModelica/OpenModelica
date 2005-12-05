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

//STD Headers
#include <iostream>
#include <exception>
#include <stdexcept>

//QT Headers
#include <qframe.h>
#include <qstylesheet.h>
#include <qbrush.h>
#include <qtextbrowser.h>
#include <qapplication.h>
#include <qmainwindow.h>
#include <qstatusbar.h>
#include <qapplication.h>
#include <qstring.h>
#include <qurl.h>

//IAEX Headers
#include "textcell.h"

namespace IAEX{
   
   /*! \class MyTextBrowser
    * \brief extends QTextBrowser. Mostly so I can catch when a user
    * clicks on a link without a change in textbrowsers content.
    *
    * QT bugs: 
    * 
    * \li Try to write a lot of fi after eachother. Then the
    *  textcursor starts to fly away. This has to be a bug. In qt
    *  3.3.3.
    * \li SuperScript tags does not work with large fonts.
    */
   MyTextBrowser::MyTextBrowser(QWidget *parent, const char *name)
      : QTextBrowser(parent, name)
   {
      setTextFormat(Qt::RichText);

      //Place the cursor in between.
      //setText("Mamma < div > 6 < /div >"); //Does not work.
      //setCursorPosition(0,5);
   }
   
   MyTextBrowser::~MyTextBrowser(){}

   void MyTextBrowser::setSource(const QString &name)
   {      
      emit openLink(new QUrl(context(), name));///???
   }

   
   /*! \class TextCell
    * \brief A concrete cellclass using QTextEdit as mainwidget.
    *
    * TextCell is a class that fulfills the Cell interface. It has the
    * behavior of both QTextEdit and Cell. It is used to display texts
    * in a cell. It supports simple undo, redo, cut, copy, paste. The
    * text can be edited if the setReadOnly flag is set to
    * false. Otherwise text is just selectable. The later is the
    * default.
    *
    * \todo Add members to fulfill the QTextEdit interface. This is
    * very nice when it is needed.
    * 
    * \todo Add margins around the qtextedit widget. This can be very
    * useful for different kind of purposes.
    *
    * \bug Set so tab focuses on next cell.
    */
   TextCell::TextCell(QWidget *parent, const char *name)
      : Cell(parent, name)
   {
      setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed));
      setFocusPolicy(QWidget::NoFocus);

      createTextWidget();
   }

   TextCell::TextCell(TextCell &t)
      : Cell(t)
   {
      //cout << "TEXT: " << t.text() << endl;
      setText(t.text());
      setStyle(t.style());
   }

   TextCell::~TextCell()
   {
      setMainWidget(0);
      delete text_;
   }

   void TextCell::createTextWidget()
   {
      //text_ = new QTextBrowser(this, "textbrowser");
      text_ = new MyTextBrowser(this, "myBrowser");
      //text_->setFocusProxy(this);
      //text_->setTabChangesFocus(TRUE);
         
      setMainWidget(text_);
      
      connect(text_, SIGNAL(returnPressed()), 
	      this, SLOT(contentChanged()));
      
      connect(text_, SIGNAL(textChanged()),
	      this, SLOT(textChangedInternal()));

      connect(text_, SIGNAL(clicked(int, int)),
 	      this, SLOT(clickEvent(int, int)));
      
//      connect(text_, SIGNAL(openLink(QUrl *)),
//	      this, SLOT(openLinkInternal(QUrl *)));

      connect(text_, SIGNAL(openLink(QUrl *)),
	      this, SLOT(openLinkInternal(QUrl *)));
      
      text_->setFrameStyle(QFrame::NoFrame);
      text_->setReadOnly(true);
      text_->setHScrollBarMode(QScrollView::AlwaysOff);
      text_->setVScrollBarMode(QScrollView::AlwaysOff);
      text_->setResizePolicy(QScrollView::AutoOneFit);
      text_->setStyleSheet(QStyleSheet::defaultSheet());
      text_->setAutoFormatting(QTextEdit::AutoNone);

      //For testing only.
      //text_->setTextFormat(Qt::PlainText);

      contentChanged();
   }

   /*!
    * \todo Is there another better way to implement this.
    *
    * This should probably be done with a command.
    */
   void TextCell::clickEvent(int para, int pos)
   { 
      emit clicked(this);
   }

   void TextCell::viewExpression(const bool expr)
   {
      if(expr)
      {
	 QString txt = text_->text();
	 text_->setTextFormat(Qt::PlainText);
	 text_->setText(txt);
      }
      else
      {
	 text_->setTextFormat(Qt::RichText);
	 setStyle(Cell::style());
      }
      
      text_->setText(text_->text()); //Update
   }    

   /*! \brief Sets the visible text.
    *
    * Sets the text that should be visible. Can change the cellheight if
    * the text is very long.
    *
    * \param text Text that should be visible inside the cell mainarea.
    */ 
   void TextCell::setText(QString text)
   {
      Stylesheet *stylesheet = Stylesheet::instance("stylesheet.xml");
      
      text_->setText(text);    
      text_->setText(stylesheet->getStyle(text_, Cell::style()));
      
      contentChanged();
   }
   
   /*! \brief Returns the text that is inside the mainarea.
    *
    * \returns The text inside the cell.
    */
   QString TextCell::text()
   {
      //Save as plain text.
      Qt::TextFormat tmp = text_->textFormat();
      text_->setTextFormat(Qt::PlainText);
      QString txt = text_->text();

      Stylesheet *stylesheet = Stylesheet::instance("stylesheet.xml");      
      stylesheet->removeTagsFromString(txt, Cell::style());

      text_->setTextFormat(tmp);
      return txt;
   }

   void TextCell::textChangedInternal()
   {
      contentChanged();
   }

	void TextCell::contentChanged() //Recalculates height.
	{
		//qDebug( "Width-Textcell: %i", width() );
		const int height = text_->heightForWidth(width());
		text_->setMinimumHeight(height);
		setHeight(height);
		emit textChanged();
	}

   void TextCell::setReadOnly(const bool readonly)
   {
      text_->setReadOnly(readonly);
      if(readonly)
	 text_->setFrameStyle(QFrame::NoFrame);
      else
	 text_->setFrameStyle(QFrame::Panel|QFrame::Sunken);	 
   }
   
   void TextCell::accept(Visitor &v)
   {
      v.visitTextCellNodeBefore(this);

      if(hasChilds())
      {
	 child()->accept(v);
      }
      v.visitTextCellNodeAfter(this);    

      //Move along.
      if(hasNext())
	 next()->accept(v);    
   }

   /*!
    * Resize textcell when the mainwindow is resized. This because the
    * cellcontent should always be visible.
    */
   void TextCell::resizeEvent(QResizeEvent *event)
   {
      contentChanged(); 
      Cell::resizeEvent(event);
   }
         
   void TextCell::clear()
   {
      text_->clear();
   }

   void TextCell::setStyleSheet(QStyleSheet *sheet)
   {
      cerr << "setStyleSheet()" << endl;
      Qt::TextFormat f = text_->textFormat();
      text_->setTextFormat(Qt::PlainText);
      QString tmp = text_->text();
      text_->setTextFormat(f);
      text_->clear();
      
      text_->setStyleSheet(sheet);
      
      setText(tmp);
   }

   //Todo Implement using setFont and other memberfunctions instead of
   //QStyleSheet!!
   void TextCell::setStyle(const QString &style)
   {
//       Stylesheet *stylesheet = Stylesheet::instance("stylesheet.xml");
//       QStyleSheet *sheet = new QStyleSheet(text_, 0);
//       setStyleSheet(stylesheet->getStyle(sheet, style));
      
      //cerr << "SetStyle(" << style << ")" << endl; 

      Qt::TextFormat tmp = text_->textFormat();
      text_->setTextFormat(Qt::PlainText);
      QString txt = text_->text();
      
      Stylesheet *stylesheet = Stylesheet::instance("stylesheet.xml");      
      
      if(Cell::style() != QString::null)
      {
//	 cerr << "OLD TAG: " << Cell::style() << endl;
	 stylesheet->removeTagsFromString(txt, Cell::style());
      }      
      text_->setTextFormat(tmp);  
      text_->setText(txt);      

      text_->setText(stylesheet->getStyle(text_, style));
      
      Cell::setStyle(style);
   }


   /*! \this method should probably be deprecated. It is not a very
    * good solution.
    */
   void TextCell::setStyle(const QString &name, const QString &val)
   {      
      //Stylesheet *stylesheet = Stylesheet::instance("stylesheet.xml");
      //QStyleSheet *sheet = new QStyleSheet(text_, 0); //this, 0);      
      //setStyleSheet(stylesheet->getStyle(sheet, name, val));
      
      Cell::setStyle(name, val);
   }

   void TextCell::setFocus(const bool focus)
   {
      if(focus)
	 text_->setFocus();
   }

   /*! \bug The link is removed if the sourcefile does not
    * exists. This is strange.
    */
   void TextCell::openLinkInternal(QUrl *url)
   {
      qDebug("Link clicked");
      emit openLink(url);
   }

//<<<<<<< .mine
//    Cell TextCell::clone()
//    {
//       cerr << "TextCell::Clone()" << endl;
//       return TextCell(this);
//    }
//=======
   //Cell &TextCell::clone()
   //{
   //   cerr << "TextCell::Clone()" << endl;
   //   return TextCell(this);
   //}
//>>>>>>> .r179

}
