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
 * \file inputcell.h
 * \author Ingemar Axelsson and Anders Fernström
 * \date 2005-10-27 (update)
 *
 * \brief Describes a inputcell.
 */

#ifndef INPUTCELL_H_
#define INPUTCELL_H_


//QT Headers
#include <QtGui/QWidget>
#include <QtGui/QTextBrowser>
//Added by qt3to4:
#include <QtGui/QMouseEvent>
#include <QtGui/QGridLayout>
#include <QtGui/QResizeEvent>
#include <QtCore/QEvent>

//IAEX Headers
#include "cell.h"
#include "inputcelldelegate.h"
#include "syntaxhighlighter.h"
//#include "highlighter.h"
#include "document.h"


namespace IAEX
{   
	class InputCell : public Cell
	{
		Q_OBJECT

	public:
		InputCell(Document *doc, QWidget *parent=0);	// Changed 2005-11-23 AF
		virtual ~InputCell();

		QString text();
		QString textHtml();					// Added 2005-10-27 AF
		virtual QString textOutput();		// Added 2005-11-23 AF
		virtual QString textOutputHtml();	// Added 2005-11-23 AF
		virtual QTextCursor textCursor();	// Added 2005-10-27 AF
		virtual QTextEdit* textEdit();		// Added 2006-01-05 AF
		virtual void viewExpression(const bool){} 

		virtual void addCellWidgets();
		virtual void removeCellWidgets();

		void setDelegate(InputCellDelegate *d);
		virtual void accept(Visitor &v);
		virtual bool isClosed();							// Added 2006-01-17 AF
		virtual bool isEditable();
		virtual bool isEvaluated();							// Added 2005-11-23 AF
		virtual bool isPlot(QString text = QString::null);	// Added 2005-11-23 AF


	signals:
		void textChanged();
		void textChanged( bool );

	public slots:
		void eval();
		void command();									// Added 2005-12-15 AF
		void nextCommand();								// Added 2005-12-15 AF
		void nextField();								// Added 2005-12-15 AF
		void clickEvent();
		void contentChanged();
		void setText(QString text);
		void setTextHtml(QString html);					// Added 2005-11-01 AF
		virtual void setTextOutput(QString output);		// Added 2005-11-23 AF
		virtual void setTextOutputHtml(QString html);	// Added 2005-11-23 AF
		void setStyle(const QString &stylename);		// Changed 2005-10-28 AF
		void setStyle(CellStyle style);					// Changed 2005-10-27 AF
		void setReadOnly(const bool readonly);			// Added 2005-11-01 AF
		void setEvaluated(const bool evaluated);		// Added 2006-01-16 AF
		void setClosed(const bool closed);
		virtual void setFocus(const bool focus);
		
		

	protected:
		void resizeEvent(QResizeEvent *event);		//AF
		void mouseDoubleClickEvent(QMouseEvent *);
		void clear();

		bool hasDelegate();
		InputCellDelegate *delegate();

	private slots:
		void addToHighlighter();							// Added 2005-12-29 AF
		void charFormatChanged(const QTextCharFormat &);	// Added 2006-01-17 AF

	private:
		void createInputCell();
		void createOutputCell();

		bool evaluated_;
		bool closed_;
		static int numEvals_;

		QTextBrowser *input_;
		QTextBrowser *output_;
		InputCellDelegate *delegate_;
		//SyntaxHighlighter *syntaxHighlighter_;

		QGridLayout *layout_;
		Document *document_;
	};


	//***************************************************
	// 2005-12-13 AF, changed from QTextEdit to QTextBrowser (browser better when working with images)
	class MyTextEdit : public QTextBrowser
	{
		Q_OBJECT

	public:
		MyTextEdit(QWidget *parent=0);
		virtual ~MyTextEdit();

		bool isStopingHighlighter();		// Added 2006-01-16 AF

	signals:
		void clickOnCell();					// Added 2005-11-01 AF
		void wheelMove( QWheelEvent* );		// Added 2005-11-28 AF
		void command();						// Added 2005-12-15 AF
		void nextCommand();					// Added 2005-12-15 AF
		void nextField();					// Added 2005-12-15 AF
		void eval();						// Added 2005-12-15 AF

	protected:
		void mousePressEvent(QMouseEvent *event);			// Added 2005-11-01 AF
		void wheelEvent(QWheelEvent *event);				// Added 2005-11-28 AF
		void keyPressEvent(QKeyEvent *event );				// Added 2005-12-15 AF
		void insertFromMimeData(const QMimeData *source);	// Added 2006-01-23 AF

	private:
		bool inCommand;						// Added 2005-12-15 AF
		bool stopHighlighter;				// Added 2006-01-16 AF
	};

}
#endif
