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
