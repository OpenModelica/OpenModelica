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
 * \file textcell.h
 * \author Ingemar Axelsson and Anders Fernström
 * \date 2005-02-08
 *
 * \brief Describes a textcell.
 */

#ifndef TEXTCELL_H
#define TEXTCELL_H


//QT Headers
#include <QtGui/QTextBrowser>


//IAEX Headers
#include "cell.h"

// forward declaration
class QResizeEvent;
class QUrl;
class QWidget;



namespace IAEX
{
	class TextCell : public Cell
	{
		Q_OBJECT

	public:
		TextCell(QWidget *parent = 0);			// Changed 2005-10-28 AF
		TextCell(TextCell &t);
		virtual ~TextCell();

		QString text();
		QString textHtml();					// Added 2005-10-28 AF
		QTextCursor textCursor();			// Added 2005-10-28 AF
		QTextEdit* textEdit();				// Added 2005-10-28 AF

		void clear();
		virtual void accept(Visitor &v);
		virtual bool isEditable();
		virtual void viewExpression(const bool expr);

	signals:
		void heightChanged();
		void textChanged();
		void textChanged( bool );
		void hoverOverUrl( const QUrl &link );		// Added 2006-02-10 AF
		void forwardAction( int );					// Added 2006-04-27 AF

	public slots:
		void clickEvent();
		void setText(QString text);
		void setText(QString text, QTextCharFormat format);		// Added 2005-10-28 AF
		void setTextHtml(QString html);							// Added 2005-10-28 AF
		void setStyle(const QString &stylename);				// Changed 2005-10-28 AF
		void setStyle(CellStyle style);							// Changed 2005-10-28 AF
		void setChapterCounter(QString number);					// Added 2006-03-02 AF
		QString ChapterCounter();								// Added 2006-03-02 AF
		QString ChapterCounterHtml();							// Added 2006-03-03 AF
		void setReadOnly(const bool readonly);
		virtual void setFocus(const bool focus);



	protected slots:
		void contentChanged();
		void hoverOverLink(const QUrl &link);				// Added 2006-02-10 AF
		void openLinkInternal(const QUrl *url);
		void openLinkInternal(const QUrl &url);
		void textChangedInternal();
		void charFormatChanged(const QTextCharFormat &);	// Added 2006-01-17 AF

	protected:
		void resizeEvent(QResizeEvent *event);

	private:
		void createTextWidget();
		void createChapterCounter();

	public:
		QTextBrowser *text_;
	private:
		QTextBrowser *chaptercounter_;						// Added 2006-03-02 AF

		QString oldHoverLink_;								// Added 2006-02-10 AF

		int oldHeight_;										// Added 2006-04-10 AF
	};

	//***************************************************
	class MyTextBrowser : public QTextBrowser
	{
		Q_OBJECT

	public:
		MyTextBrowser(QWidget *parent=0);
		virtual ~MyTextBrowser();

		void setActive( bool active );				// Added 2006-04-25 AF

	signals:
		void openLink(const QUrl *);				// Changed 2005-11-03 AF
		void clickOnCell();							// Added 2005-11-01 AF
		void wheelMove( QWheelEvent* );				// Added 2005-11-28 AF
		void forwardAction( int );					// Added 2006-04-27 AF

	public slots:
		void setSource(const QUrl &name);			// Changed 2005-11-03 AF

	protected:
		void mousePressEvent(QMouseEvent *event);			// Added 2005-11-01 AF
		void wheelEvent(QWheelEvent * event);				// Added 2005-11-28 AF
		void insertFromMimeData(const QMimeData *source);	// Added 2006-01-23 AF
		void keyPressEvent(QKeyEvent *event );				// Added 2006-01-30 AF

	};

}
#endif
