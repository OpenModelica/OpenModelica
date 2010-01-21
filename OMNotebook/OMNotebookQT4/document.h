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
 * \file document.h
 * \author Ingemar Axelsson and Anders Fernström
 *
 * \brief Describes a celldocument.
 */

#ifndef DOCUMENT_H
#define DOCUMENT_H

//STD Haders
#include <vector>

//QT Headers
#include <QtCore/QObject>

//IAEX Headers
#include "cellcursor.h"

//Forward declaration
class QColor;
class QFrame;
class QImage;
class QUrl;

class CellStyle;



using namespace std;

namespace IAEX
{
	//Forward declaration
	class CellApplication;
	class Cell;
	class Command;
	class DocumentView;
	class Factory;
	class Visitor;

	/*!
	 *\interface Document
	 *
	 * \brief Describes all operations that is needed by a document.
	 *
	 * The Document interface describes all methods that must be
	 * implemented by a concrete document class.
	 */
	class Document : public QObject
	{
		Q_OBJECT

	public:
		//Application
		virtual CellApplication *application() = 0;

		//State
		virtual bool hasChanged() const = 0;
		virtual bool isOpen() const = 0;
		virtual bool isSaved() const = 0;					// AF
		virtual bool isEmpty() const = 0;					// Added 2006-08-24 AF

		//File operations
		virtual void open( const QString filename, int readmode ) = 0;
		virtual void close() = 0;
		virtual QString getFilename() = 0;
		virtual void setFilename( QString filename ) = 0;	//AF
		virtual void setSaved( bool saved ) = 0;			//AF
		virtual void setChanged( bool changed ) = 0;		// Added 2006-01-17 AF
		virtual void hoverOverUrl( const QUrl &link ) = 0;	// Added 2006-02-10 AF

		//Cursor operations
		virtual CellCursor *getCursor() = 0;
		virtual void cursorStepUp() = 0;
		virtual void cursorStepDown() = 0;
		virtual void cursorMoveAfter(Cell *aCell, const bool open) = 0;
		virtual void cursorUngroupCell() = 0;					// Added 2006-04-26 AF
		virtual void cursorSplitCell() = 0;						// Added 2006-04-26 AF
		virtual void cursorAddCell() = 0;
		virtual void cursorDeleteCell() = 0;
		virtual void cursorCutCell() = 0;
		virtual void cursorCopyCell() = 0;
		virtual void cursorPasteCell() = 0;
		virtual void cursorChangeStyle(CellStyle style) = 0;	// Changed 2005-10-28 AF

		//TextCursor operations, added 2006-02-07 AF
		virtual void textcursorCutText() = 0;
		virtual void textcursorCopyText() = 0;
		virtual void textcursorPasteText() = 0;
		//TextCursor operations, added 2005-11-03 AF
		virtual void textcursorChangeFontFamily( QString family ) = 0;
		virtual void textcursorChangeFontFace( int face ) = 0;
		virtual void textcursorChangeFontSize( int size ) = 0;
		virtual void textcursorChangeFontStretch( int stretch ) = 0;
		virtual void textcursorChangeFontColor( QColor color ) = 0;
		virtual void textcursorChangeTextAlignment( int alignment ) = 0;
		virtual void textcursorChangeVerticalAlignment( int alignment ) = 0;
		virtual void textcursorChangeMargin( int margin ) = 0;
		virtual void textcursorChangePadding( int padding ) = 0;
		virtual void textcursorChangeBorder( int border ) = 0;

		// Added 2005-11-17 AF, Image operations
		virtual void textcursorInsertImage( QString filepath, QSize size ) = 0;
		virtual QString addImage( QImage *image ) = 0;
		virtual QImage *getImage( QString name ) = 0;

		// Added 2005-12-05 AF, Link operations
		virtual void textcursorInsertLink( QString filepath, QTextCursor& cursor ) = 0;

		//Utility operations
		virtual Factory *cellFactory() = 0;
		virtual Cell* getMainCell() = 0;				// Added 2006-08-24 AF
		virtual vector<Cell *> getSelection() = 0;
		virtual void clearSelection() = 0;

		//command operations
		virtual void executeCommand(Command *cmd) = 0;

		//Observer interface
		virtual void attach(DocumentView *d) = 0;
		virtual void detach(DocumentView *d) = 0;
		virtual void notify() = 0;
		virtual QFrame *getState() = 0;

		//Visitor Initializations
		virtual void runVisitor(Visitor &v) = 0;

		virtual void setAutoIndent2(bool) = 0;

	public slots:
		virtual void updateScrollArea() = 0;		// Added 2005-11-28 AF


signals:
		virtual void copyAvailable(bool) = 0;
		virtual void undoAvailable(bool) = 0;
		virtual void redoAvailable(bool) = 0;

		virtual void updatePos(int, int) = 0;
		virtual void newState(QString) = 0;
		virtual void setStatusMenu(QList<QAction*>) = 0;


	};
}
#endif
