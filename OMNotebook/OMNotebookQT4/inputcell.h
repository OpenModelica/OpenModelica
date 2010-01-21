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
		QString textHtml();						// Added 2005-10-27 AF
		virtual QString textOutput();			// Added 2005-11-23 AF
		virtual QString textOutputHtml();		// Added 2005-11-23 AF
		virtual QTextCursor textCursor();		// Added 2005-10-27 AF
		virtual QTextEdit* textEdit();			// Added 2006-01-05 AF
		virtual QTextEdit* textEditOutput();	// Added 2006-02-03 AF
		virtual void viewExpression(const bool){}

		virtual void addCellWidgets();
		virtual void removeCellWidgets();

		void setDelegate(InputCellDelegate *d);
		virtual void accept(Visitor &v);
		virtual bool isClosed();							// Added 2006-01-17 AF
		virtual bool isEditable();
		virtual bool isEvaluated();							// Added 2005-11-23 AF
		virtual bool isJavaPlot(QString text = QString::null);	// Added 2005-11-23 AF


	signals:
		void heightChanged();
		void textChanged();
		void textChanged( bool );
		void clickedOutput( Cell* );					// Added 2006-02-03 AF
		void forwardAction( int );						// Added 2006-04-27 AF

	public slots:
		void eval();
		void command();									// Added 2005-12-15 AF
		void nextCommand();								// Added 2005-12-15 AF
		void nextField();								// Added 2005-12-15 AF
		void clickEvent();
		void clickEventOutput();						// Added 2006-02-03 AF
		void contentChanged();
		void setText(QString text);
		void setTextHtml(QString html);					// Added 2005-11-01 AF
		virtual void setTextOutput(QString output);		// Added 2005-11-23 AF
		virtual void setTextOutputHtml(QString html);	// Added 2005-11-23 AF
		void setStyle(const QString &stylename);		// Changed 2005-10-28 AF
		void setStyle(CellStyle style);					// Changed 2005-10-27 AF
		void setChapterCounter(QString number);			// Added 2006-03-02 AF
		QString ChapterCounter();						// Added 2006-03-02 AF
		QString ChapterCounterHtml();					// Added 2006-03-03 AF
		void setReadOnly(const bool readonly);			// Added 2005-11-01 AF
		void setEvaluated(const bool evaluated);		// Added 2006-01-16 AF
		void setClosed(const bool closed, bool update = true); //Changed 2006-08-24
		virtual void setFocus(const bool focus);
		virtual void setFocusOutput(const bool focus);	// Added 2006-02-03 AF



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
		void createChapterCounter();
		void exceptionInEval(exception &e);					// Added 2006-02-02 AF
		void setOutputStyle();								// Added 2006-04-21 AF

	private:
		bool evaluated_;
		bool closed_;
		static int numEvals_;
		int oldHeight_;										// Added 2006-04-10 AF

	public:
		QTextBrowser *input_;
		QTextBrowser *output_;
	private:
		QTextBrowser *chaptercounter_;

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
		void forwardAction( int );			// Added 2006-04-27 AF


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
