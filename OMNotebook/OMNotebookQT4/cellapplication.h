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

#ifndef _CELLAPPLICATION_H
#define _CELLAPPLICATION_H

// QT Headers
#include <QtGui/QApplication>
#include <QtCore/QObject>

// IAEX Headers
#include "application.h"
#include "commandcenter.h"
#include "documentview.h"
#include "xmlnodename.h"

namespace IAEX
{
	// forward declaration
	class NotebookSocket;


	class CellApplication : public QObject, public Application
	{
		Q_OBJECT
	public:
		CellApplication(int &argc, char *argv[]);
		virtual ~CellApplication();

		virtual CommandCenter *commandCenter();
		virtual void setCommandCenter(CommandCenter *c);

		virtual void addToPasteboard(Cell *c);
		virtual void clearPasteboard();
		vector<Cell *> pasteboard();

		int exec();
		void add(Document *doc);
		void add(DocumentView *view);

		void open(const QString filename, int readmode = READMODE_NORMAL );
		void removeTempFiles(QString filename);			// Added 2006-01-16 AF
		vector<DocumentView *> documentViewList();		// Added 2006-01-27 AF
		void removeDocumentView( DocumentView *view );	// Added 2006-01-27 AF
    QApplication* getApplication() { return app_; }
    QWidget* getMainWindow() { return mainWindow; }

	private:
		void convertDrModelica();						// Added 2006-03-21 AF

	private:
		QApplication *app_;
    QWidget* mainWindow;
		vector<Document *> documents_;
		vector<DocumentView *> views_;
		CommandCenter *cmdCenter_;
		vector<Cell *> pasteboard_;
		QStringList removeList_;		// Added 2006-01-16 AF

		NotebookSocket *notebooksocket_;
	};
}

#endif
