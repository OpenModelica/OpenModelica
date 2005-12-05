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
#include <exception>
#include <stdexcept>
#include <sstream>

#include <qapplication.h>

//IAEX Headers
#include "inputcell.h"
//#include "cellcursor.h"
#include "treeview.h"
#include "stylesheet.h"

namespace IAEX{

   /*! \class NullHighlighter
    * \brief This class is used if no SyntaxHighlighter is set. 
    *
    */
   class NullHighlighter : public SyntaxHighlighter
   {
   public:
      virtual void rehighlight(){}
      virtual void setTextEdit(QTextEdit *){}
   };
   

   /*! \class InputCell
    * \brief Describes how an inputcell works.
    *
    * Input cells is places where the user can do input. To evaluate
    * the content of an inputcell just press shift+enter. It will
    * throw an exception if it cant find modeq. Start modeq with
    * following commandline: 
    *
    * # modeq +d=interactiveCorba
    *
    * For other environments such as SML environment no process is
    * needed. See the actual environment for more information about
    * this topic.
    *
    * \todo Create a state for the inputcell. If it is evaluated or
    * not. This should reflect the drawing of its content. Notis when
    * the evaluation is invalidated. This could be done with the
    * state-pattern. With a DFA it is easier to track errors.
    * 
    * \todo Make it possible to add cells within a inputcell?
    * \todo Make it possiblee to add and change syntax coloring of code.
    */

   int InputCell::numEvals_ = 1;

   InputCell::InputCell(QWidget *parent, const char *name)
      : Cell(parent, name), 
	evaluated_(false), 
	closed_(true), 
	delegate_(0)
   {
      QWidget *main = new QWidget(this);
      setMainWidget(main);
      layout_ = new QGridLayout(mainWidget(), 2, 1);
	  
      setTreeWidget(new InputTreeView(this));
      
	  setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed));
      setFocusPolicy(QWidget::NoFocus);

	  setSyntaxHighlighter(new NullHighlighter());

      createInputCell();
      createOutputCell();
      
      setBackgroundColor(QColor(200,200,255));

	  //input_->setText("");
	//setHeight(20); 	
	  //setClosed(true);      
   }
   
   InputCell::~InputCell()
   {
      delete input_;
//      if(output_)
	 delete output_;
      delete syntaxHighlighter_;
   }
   
   /*! \brief Sets the evaulator delegate.
    */
   void InputCell::setDelegate(InputCellDelegate *d)
   {
      delegate_ = d;
   }
   
   InputCellDelegate *InputCell::delegate()
   {
      if(!hasDelegate())
	 throw runtime_error("No delegate.");

      return delegate_;
   }

   /*! \brief Sets the syntaxhighlighter.
    *
    *
    * \param h Syntax highlighter to use. If 0 a NullHighlighter is
    * used.
    */
   void InputCell::setSyntaxHighlighter(SyntaxHighlighter *h)
   { 
      if(!h)
      {
	 h = new NullHighlighter();
      }
      
      h->setTextEdit(input_);
      syntaxHighlighter_ = h;
   }
   
   bool InputCell::hasDelegate()
   {
      return delegate_ != 0;
   }
   
   /*!
    * Sizehint is not implemented correctly. This method makes
    * inputcell behaive strange.
    */
//    QSize InputCell::sizeHint() const
//    {
//       QSize size = QSize(width(), input_->heightForWidth(width()));
      
//       if(evaluated_ && !closed_)
// 	 size +=  QSize(width(), output_->heightForWidth(width()));
      
//       return size;
//    }
   
   
   void InputCell::createInputCell()
   {
      input_ = new QTextEdit(mainWidget(), "input textedit");
      layout_->addWidget(input_, 1,1);
      
      input_->setTextFormat(Qt::PlainText);	
	  //input_->setTextFormat(Qt::RichText);	//AF
      input_->setReadOnly(false);
      input_->setFrameShape(QFrame::Panel);
      //input_->setFrameStyle(QFrame::Panel);
      input_->setHScrollBarMode(QScrollView::AlwaysOff);
      input_->setVScrollBarMode(QScrollView::AlwaysOff);
      input_->setResizePolicy(QScrollView::AutoOneFit);
	  input_->setAutoFormatting(QTextEdit::AutoNone);
      //input_->setStyleSheet(QStyleSheet::defaultSheet());
      //input_->setAutoFormatting(QTextEdit::AutoAll);
      input_->setPaletteBackgroundColor(QColor(200,200,255));      
     
      //input_->setFrameShadow(QFrame::Sunken);
      input_->installEventFilter(this);

      input_->setPointSize(12);
	  input_->setFixedHeight(12);

      //Can theese signals be converted to events?
      connect(input_, SIGNAL(returnPressed()), 
	      this, SLOT(contentChanged()));
      
      connect(input_, SIGNAL(textChanged()),
	      this, SLOT(contentChanged()));

      connect(input_, SIGNAL(clicked(int, int)),
	      this, SLOT(clickEvent(int, int)));

	  contentChanged();
   }

   void InputCell::createOutputCell()
   {
      output_ = new QTextEdit(mainWidget(), "output textedit");
      layout_->addWidget(output_, 2,1);
      output_->setReadOnly(false);
      output_->setFrameShape(QFrame::Panel);
      //output_->setFrameShadow(QFrame::Sunken);
      //output_->installEventFilter(this);
      output_->setHScrollBarMode(QScrollView::AlwaysOff);
      output_->setVScrollBarMode(QScrollView::AlwaysOff);
      //output_->setResizePolicy(QScrollView::AutoOneFit);
      //output_->setStyleSheet(QStyleSheet::defaultSheet());
      //output_->setAutoFormatting(QTextEdit::AutoAll);
      output_->setReadOnly(true);
      output_->hide();
      
      //Can theese signals be converted to use events instead?
      connect(input_, SIGNAL(returnPressed()), 
	      this, SLOT(contentChanged()));
      
      connect(input_, SIGNAL(textChanged()),
	      this, SLOT(contentChanged()));

      connect(input_, SIGNAL(clicked(int, int)),
	      this, SLOT(clickEvent(int, int)));
   }

   void InputCell::clickEvent(int, int)
   {
      emit clicked(this);
   }

   /*! \brief Do not use this member.
    *
    * This is an ugly part of the cell structure.
    */
   void InputCell::addCellWidgets()
   {
      layout_->addWidget(input_,0,0);	 
      
      if(evaluated_)
	 layout_->addWidget(output_,1,0);
   }
   
   void InputCell::removeCellWidgets()
   {
      layout_->remove(input_);
      if(evaluated_)
	 layout_->remove(output_);
   }

   /*! \brief resets the input cell. Removes all output data and
    *  restores the initial state.
    */
   void InputCell::clear()
   {
	   if(evaluated_)
	   {
		   output_->clear();
		   evaluated_ = false;
		   layout_->remove(output_);
	   }

	   input_->setReadOnly(false);
	   input_->clear();
	   treeView()->setClosed(false); //Notis this
	   setClosed(true);
   }
   
    bool InputCell::eventFilter(QObject *o, QEvent *e)
    {
       //Take care of SHIFT + RETURN.
       if(o == input_)
       {
	  if(e->type() == QEvent::KeyPress)//QEvent::KeyRelease)
	  {
	     QKeyEvent *k = (QKeyEvent *)e;
	     
    if(k->key() == Qt::Key_Return && k->state() == Qt::ShiftButton)
	     {
		eval();
		return TRUE;
	     }
	  }
	  return Cell::eventFilter(o,e);
       }
       else
	  return Cell::eventFilter(o,e);
       
    }

   /*! \brief Sends the content of the inputcell to the
    * evaluator. Displays the result in a outputcell. 
    *
    * Removes whitespaces and tags from the content string. Then sends
    * the content to the delegate object for evaluation. The result is
    * printed in a output cell. No indentation and syntax
    * highlightning is used in the output cell.
    * 
    */
	void InputCell::eval()
	{
		//Get only the text, no tags.
		QString expr = input_->text();
		expr = expr.simplifyWhiteSpace();


		createOutputCell();      
		output_->clear();      

		if(hasDelegate())
		{
			delegate()->evalExpression(expr);	 

			// 2005-11-24 AF, added check to see if the user wants to quit
			if( 0 == expr.find( "quit()", 0, false ))
			{
				qApp->closeAllWindows();
				return;
			}


			output_->setText(delegate()->getResult());

			//qDebug( "Eval:" );
			//qDebug( output_->text() );

			//Change state if evaluated.
			output_->show();

			++numEvals_;
			evaluated_ = true;

			setClosed(false);
			contentChanged();
		}
	}
   
	void InputCell::contentChanged()
	{
		syntaxHighlighter_->rehighlight();

		//qDebug( "Width-Inputcell: %i", width() );
		int _height = input_->heightForWidth(width());
		//int _height = input_->contentsHeight();

		input_->setMinimumHeight(_height);

		if(evaluated_)
		{	
			int outHeight = output_->heightForWidth(width());
			output_->setMinimumHeight(outHeight);
			_height += outHeight;
		}

		setHeight(_height);

		emit textChanged();
	}

   /*!
    * \deprecated
    */
   void InputCell::setStyleSheet(QStyleSheet *)
   {
      qDebug("inputSetStyleSheet");

      //Qt::TextFormat f = input_->textFormat();
      //input_->setTextFormat(Qt::PlainText);
      //QString tmp = input_->text();
      //input_->setTextFormat(f);
      //input_->clear();
      
      //input_->setStyleSheet(sheet);
      
      //if(evaluated_)
      //{
//	 Stylesheet *stylesheet = Stylesheet::instance("stylesheet.xml");
//	 QStyleSheet *outsheet = new QStyleSheet(output_, 0);
//	 output_->setStyleSheet(stylesheet->getStyle(outsheet, "Output"));
//     }

   }

   /*!
    * Resize textcell when the mainwindow is resized. This because the
    * cellcontent should always be visible.
	*
	* Added by AF, copied from textcell.cpp
    */
   void InputCell::resizeEvent(QResizeEvent *event)
   {
      contentChanged(); 
      Cell::resizeEvent(event);
   }
   
   void InputCell::setText(QString text)
   {
	   // 2005-10-04 AF, added som code to replace/remove
		QString tmp = text.replace("<br>", "\n");
		tmp.remove( "&nbsp;" );

	   input_->setText( tmp );
	  contentChanged();

   }
   
   QString InputCell::text()
   {
//       Qt::TextFormat f = input_->textFormat();
//       input_->setTextFormat(Qt::PlainText);
//       QString tmp = input_->text();
      
//      tmp = tmp.replace(QString("\n"), QString("<br>"));
//       tmp = tmp.replace(QString("\t"), QString(""));
//      input_->setTextFormat(f);
      
      return input_->text();//tmp;
   }

   void InputCell::setClosed(const bool closed)
   {
	   int newHeight = input_->height();

	   if(closed)
	   {
		   if(evaluated_)
			   output_->hide();
	   }
	   else
	   {
		   if(evaluated_)
		   {
			   newHeight = input_->height() + output_->height();
			   output_->show();
		   }
	   }
	   setHeight(newHeight);
	   closed_ = closed;
   }
   
   void InputCell::setFocus(const bool focus)
   {
      if(focus)
	 input_->setFocus();
   }

   void InputCell::mouseDoubleClickEvent(QMouseEvent *)
   {
      if(treeView()->hasMouse())
      {
	 setClosed(!closed_);
      }
   }
   
   void InputCell::accept(Visitor &v)
   {
      v.visitInputCellNodeBefore(this);

      if(hasChilds())
      	 child()->accept(v);

      v.visitInputCellNodeAfter(this);

      if(hasNext())
	 next()->accept(v);
   }

   /*!
    * InputCell setStyle is locked on the "input" style. So if it does
    * not work, see if the "input" style is defined. If it is, then it
    * should appear in the style menu.
    */
   void InputCell::setStyle(const QString &style)
   {
      // Stylesheet *stylesheet = Stylesheet::instance("stylesheet.xml");
//       QStyleSheet *sheet = new QStyleSheet(input_, 0);
      
//       setStyleSheet(stylesheet->getStyle(sheet, "Input"));
      
      Cell::setStyle(style);
   }
   
   void InputCell::setStyle(const QString &name, const QString &val)
   {
//        Stylesheet *stylesheet = Stylesheet::instance("stylesheet.xml");
//        QStyleSheet *sheet = new QStyleSheet(input_, 0);
      
//        setStyleSheet(stylesheet->getStyle(sheet, name, val));
      
       Cell::setStyle(name, val);
   }
}
