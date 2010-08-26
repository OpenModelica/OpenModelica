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
 * \file qmosh.cpp
 * \author Anders FernstrÃ¶m
 * \date 2005-11-10 (created)
 */

#ifndef OMS_H
#define OMS_H

#include <exception>

using namespace std;


//QT Headers
#include <QtGui/QKeyEvent>
#include <QtGui/QMainWindow>
#include <QtGui/QTextCharFormat>
#include <QtGui/QTextCursor>
#include <QtGui/QTextEdit>

//IAEX Headers
#include "inputcelldelegate.h"
#include "commandcompletion.h"

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
	void codeNextField();

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
	void aboutQT();					// Added 2006-02-21 AF
	void print();
	bool startServer();
	void stopServer();
	void clear();

private slots:
	void closeEvent( QCloseEvent *event );		// Added 2006-02-09 AF

private:
	void createMoshEdit();
	//void createMoshError();
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
	//QTextEdit* moshError_;
	QVBoxLayout* layout_;
	QString clipboard_;
	QString omc_version_;
  QString copyright_info_;

	IAEX::InputCellDelegate* delegate_;
	IAEX::CommandCompletion* commandcompletion_;
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
	QAction* aboutQT_;				// Added 2006-02-21 AF
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
	void codeNextField();

protected:
	void keyPressEvent(QKeyEvent *event);
	void insertFromMimeData(const QMimeData *source);	// Added 2006-01-30

private:
	bool insideCommandSign();
	bool startOfCommandSign();
	bool sameTab_;
};


#endif
