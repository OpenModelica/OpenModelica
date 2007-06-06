/*------------------------------------------------------------------------------------
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
#include "application.h"
#include "document.h"
#include "xmlparser.h"


namespace IAEX
{
	class CellDocument : public Document
	{
		Q_OBJECT

	public:
		typedef vector<DocumentView*> observers_t;
	
		CellDocument(Application *a, const QString filenamem, int readmode = READMODE_NORMAL);
		virtual ~CellDocument();

		void setApplication(Application *app){app_ = app;}
		Application *application(){ return app_;}

		//Document implementations
		virtual void open( const QString &filename, int readmode = READMODE_NORMAL );
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
		virtual void textcursorInsertLink( QString filepath );

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

		Application *app_;
		QString filename_;

		Cell *workspace_;				//This should alwas be a cellgroup. 
		Cell *lastClickedCell_;			// Added 2006-04-25 AF
		QFrame *mainFrame_;
		QScrollArea *scroll_;			// Added 2005-11-01 AF
		QGridLayout *mainLayout_;

		CellCursor *current_;
		Factory *factory_;

		vector<Cell*> selectedCells_;

		observers_t observers_;

		QHash<QString, QImage*> images_;		// Added 2005-11-19 AF
		int currentImageNo_;					// Added 2005-11-19 AF
	};

}

#endif
