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
 * \file qmosh.cpp
 * \author Anders Fernström
 * \date 2005-11-10 (created)
 */

#ifndef OMS_H
#define OMS_H


//QT Headers
#include <QtGui/QKeyEvent>
#include <QtGui/QMainWindow>
#include <QtGui/QTextCharFormat>
#include <QtGui/QTextCursor>
#include <QtGui/QTextEdit>

//IAEX Headers
#include "inputcelldelegate.h"

//Forward Declaration
class QAction;
class QFrame;
class QMenu;
class QStringList;
class QVBoxLayout;




class OMS : public QMainWindow
{
	Q_OBJECT

public:
	OMS( QWidget* parent = 0 );
	~OMS();

signals:
	void emitQuit();

public slots:
	void returnPressed();
	void insertNewline();
	void prevCommand();
	void nextCommand();
	void goHome( bool shift );
	void codeCompletion( bool same );

	void loadModel();
	void loadModelicaLibrary();
	void exit();
	void cut();
	void copy();
	void paste();
	void fontSize();
	void viewToolbar();
	void viewStatusbar();
	void aboutOMS();
	void print();
	bool startServer();
	void stopServer();
	void clear();

private slots:
	void closeEvent( QCloseEvent *event );		// Added 2006-02-09 AF

private:
	void createMoshEdit();
	void createMoshError();
	void createAction();
	void createMenu();
	void createToolbar();
	void exceptionInEval(exception &e);
	void addCommandLine();
	void selectCommandLine();
	QStringList getFunctionNames(QString);

	QFrame* mainFrame_;
	QTextCursor cursor_;
	QTextEdit* moshEdit_;
	QTextEdit* moshError_;
	QVBoxLayout* layout_;
	QString clipboard_;

	IAEX::InputCellDelegate* delegate_;
	int fontSize_;

	int currentFunction_;
	QString currentFunctionName_;
	QStringList* functionList_; 

	int currentCommand_;
	QStringList* commands_;
	QTextCharFormat commandSignFormat_;
	QTextCharFormat textFormat_;

	QMenu* fileMenu_;
	QMenu* editMenu_;
	QMenu* viewMenu_;
	QMenu* helpMenu_;
	QAction* loadModel_;
	QAction* loadModelicaLibrary_;
	QAction* exit_;
	QAction* cut_;
	QAction* copy_;
	QAction* paste_;
	QAction* font_;
	QAction* viewToolbar_;
	QAction* viewStatusbar_;
	QAction* aboutOMS_;
	QAction* print_;
	QAction* startServer_;
	QAction* stopServer_;
	QAction* clearWindow_;

	QToolBar* toolbar_;
};

//********************************
class MyTextEdit : public QTextEdit
{
	Q_OBJECT

public:
	MyTextEdit( QWidget* parent = 0 );
	virtual ~MyTextEdit();
	void sendKey( QKeyEvent *event );

signals:
	void returnPressed();
	void insertNewline();
	void prevCommand();
	void nextCommand();
	void goHome( bool shift );
	void codeCompletion( bool same );

protected:
	void keyPressEvent(QKeyEvent *event);
	void insertFromMimeData(const QMimeData *source);	// Added 2006-01-30

private:
	bool insideCommandSign();
	bool startOfCommandSign();
	bool sameTab_;
};


#endif
