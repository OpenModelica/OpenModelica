/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2009, Linköpings University,
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
* \file celldocument.h
* \author Ingemar Axelsson and Anders Fernström
*
* \brief Describes the mainwidget used in other applications.
*/

#ifndef CELLDOCUMENT_H
#define CELLDOCUMENT_H


//QT Headers
#include <QtCore/QHash>
#include <QtGui/QScrollArea>
#include <QtGui/QGridLayout>

//Forward declaration
class QDom;
class QEvent;
class QLayout;
class QScrollArea;
class QUrl;

//IAEX Headers
#include "cellapplication.h"
#include "document.h"
#include "xmlparser.h"


namespace IAEX
{

	class CellDocument : public Document
	{
		Q_OBJECT

	public:
		typedef vector<DocumentView*> observers_t;

		CellDocument(CellApplication *a, const QString filename, int readmode = READMODE_NORMAL);
		virtual ~CellDocument();

		void setApplication(CellApplication *app){app_ = app;}
		CellApplication *application(){ return app_;}

		//Document implementations
		virtual void open( const QString filename, int readmode = READMODE_NORMAL );
		virtual void close();
		virtual QString getFilename();
		virtual void setFilename( QString filename );	//AF
		virtual void setSaved( bool saved );			//AF

		virtual void attach(DocumentView *d);
		virtual void detach(DocumentView *d);
		virtual void notify();

		//Cursor methods
		virtual void cursorStepUp();
		virtual void cursorStepDown();
		virtual void cursorAddCell();
		virtual void cursorUngroupCell();					// Added 2006-04-26 AF
		virtual void cursorSplitCell();						// Added 2006-04-26 AF
		virtual void cursorDeleteCell();
		virtual void cursorCutCell();
		virtual void cursorCopyCell();
		virtual void cursorPasteCell();
		virtual void cursorChangeStyle(CellStyle style);	// Changed 2005-10-28 AF

		//TextCursor operations, added 2006-02-07 AF
		virtual void textcursorCutText();
		virtual void textcursorCopyText();
		virtual void textcursorPasteText();
		//TextCursor operations, added 2005-11-03 AF
		virtual void textcursorChangeFontFamily( QString family );
		virtual void textcursorChangeFontFace( int face );
		virtual void textcursorChangeFontSize( int size );
		virtual void textcursorChangeFontStretch( int stretch );
		virtual void textcursorChangeFontColor( QColor color );
		virtual void textcursorChangeTextAlignment( int alignment );
		virtual void textcursorChangeVerticalAlignment( int alignment );
		virtual void textcursorChangeMargin( int margin );
		virtual void textcursorChangePadding( int padding );
		virtual void textcursorChangeBorder( int border );

		// Added 2005-11-18 AF, Image operations
		virtual void textcursorInsertImage( QString filepath, QSize size );
		virtual QString addImage( QImage *image );
		virtual QImage *getImage( QString name );

		// Added 2005-12-05 AF, Link operations
		virtual void textcursorInsertLink( QString filepath, QTextCursor& cursor);

		//State operations
		virtual bool hasChanged() const;
		bool isOpen() const;
		bool isSaved() const;
		bool isEmpty() const;		// Added 2006-08-24 AF

		//Cursor operations
		CellCursor *getCursor();
		Factory *cellFactory();
		Cell* getMainCell();				// Added 2006-08-24 AF
		vector<Cell*> getSelection();

		//Command
		void executeCommand(Command *cmd);

		//Traversals.
		void runVisitor(Visitor &v);

		virtual void setAutoIndent2(bool);

		//observer
		QFrame *getState();

	public slots:
		void toggleMainTreeView();
		void setEditable(bool editable);
		void cursorChangedPosition();
		void updateScrollArea();				// Added 2005-11-29 AF
		void setChanged( bool changed );		// Added 2006-01-17 AF
		void hoverOverUrl( const QUrl &link );	// Added 2006-02-10 AF
		void selectedACell(Cell *selected, Qt::KeyboardModifiers);
		void clearSelection();
		void mouseClickedOnCell(Cell *clickedCell);
		void mouseClickedOnCellOutput(Cell *clickedCell); //Added 2006-02-03
		void linkClicked(const QUrl *url);
//		void anchorClicked(const QUrl *url);
		virtual void cursorMoveAfter(Cell *aCell, const bool open);
		void showHTML(bool b);


	signals:
		virtual void copyAvailable(bool);
		virtual void undoAvailable(bool);
		virtual void redoAvailable(bool);
		virtual void setAutoIndent(bool);

		void updatePos(int, int);
		void newState(QString);
		void setStatusMenu(QList<QAction*>);
		void widthChanged(const int);
		void cursorChanged();
		void viewExpression(const bool);
		void contentChanged();				// Added 2005-11-29 AF
		void hoverOverFile( QString );		// Added 2006-02-10 AF
		void forwardAction( int );			// Added 2006-04-27 AF


	protected:
		void setWorkspace(Cell *newWorkspace);
		bool eventFilter(QObject *o, QEvent *e);

	private:
		void addSelectedCell( Cell* cell );
		void removeSelectedCell( Cell* cell );


	private:
		bool changed_;					// Added 2006-01-17 AF
		bool open_;
		bool saved_;

		CellApplication *app_;
		QString filename_;

		Cell *workspace_;				//This should alwas be a cellgroup.
		Cell *lastClickedCell_;			// Added 2006-04-25 AF
		QFrame *mainFrame_;


		QScrollArea *scroll_;			// Added 2005-11-01 AF
		QGridLayout *mainLayout_;

		CellCursor *current_;
		Factory *factory_;

		vector<Cell*> selectedCells_;

	public:
		observers_t observers_;
		bool autoIndent;
	private:
		QHash<QString, QImage*> images_;		// Added 2005-11-19 AF
		int currentImageNo_;					// Added 2005-11-19 AF
	};

}

#endif
