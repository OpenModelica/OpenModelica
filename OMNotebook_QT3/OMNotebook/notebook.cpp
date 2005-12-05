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

/*! \file notebook.cpp
 * \author Ingemar Axelsson
 * \date 2005-02-07
 */

#ifndef _NOTEBOOK_HH
#define _NOTEBOOK_HH

//STD Headers
#include <exception>
#include <stdexcept>
#include <fstream>

//QT Headers
#include <qaction.h>
#include <qapplication.h>
#include <qfiledialog.h>
#include <qmessagebox.h>
#include <qtextedit.h>
#include <qtimer.h>

//IAEX Headers
#include "notebook.h"
#include "stylesheet.h"
#include "command.h"
#include "notebookcommands.h"
#include "cursorcommands.h"
#include "cellcommands.h"
#include "celldocument.h"


using namespace std;

namespace IAEX{
   
   /*! \class NotebookWindow 
    * \brief This class describes a mainwindow using the CellDocument
    * 
    * This is the main applicationwindow. It contains of a menu, a
    * toolbar, a statusbar and a workspace. The workspace will contain a
    * celldocument view.
    *
    * 
    * 
    * \todo Add exceptions instead of error printings.
    *
    * \todo Make edit work correctly or remove it.
    *
    * \todo Implement menus for changing cellstyles. Also add menus
    * for changing font style and size of selected text. Read the
    * stylesheet file and create menus for every single style. Also
    * think through what will happen if a section and subsection is
    * created? Should a new CellGroup be added then?
    *
    * \todo Implement commands for deletion and makeing of new
    * cells. This allows undo/redo.
    *
    * \todo implement a timer that saves a document every 5 minutes 
	* or so.
    *
    * \todo Implement section numbering. Could be done with some kind 
	* of vistors.
    *
    * 
    * \bug Segmentation fault when quit. Only sometimes.
    */
   
	NotebookWindow::NotebookWindow(Document *subject, 
		const QString &filename, QWidget *parent, const char *name)
		: DocumentView(parent, name),//QMainWindow(0,0,WDestructiveClose),
		subject_(subject),
		filename_(filename),
		app_( subject->application() ) //AF
	{
		subject_->attach(this);

		//reimplement in some way.
		//connect(subject_, SIGNAL(cursorChanged()),
		//	      this, SLOT(setSelectedStyle()));

		createMenu();
		createEditMenu();
		createCellMenu();
		createFormatMenu();
		createAboutMenu();

		update();

		if( filename_ != QString::null )
			qDebug( filename_ );

		setCaption(QString("OMNotebook: ").append( strippedFileName(filename_) ));    
		statusBar()->message("Ready");
		resize(800, 600);
	}
   
   NotebookWindow::~NotebookWindow()
   {
      subject_->detach(this);
      subject_ = 0;
      //delete document_;
   }

   void NotebookWindow::update()
   {
      QFrame *mainWidget = subject_->getState();
      mainWidget->reparent(this, QPoint(0,0));
      setCentralWidget(mainWidget);
      mainWidget->show();
   }
   
   /*! \todo Add more information to the about dialog.
    */
   void NotebookWindow::aboutQTNotebook()
   {
      QMessageBox::about(this, "OMNotebook",
			 "<p>Information about OMNotebook.</p>");
   }

   /*! \brief Method for creating all menus.
    */
   void NotebookWindow::createMenu()
   {
      QAction *openFileAction = new QAction("Open", "&Open", CTRL+Key_O, this, "open");
      QObject::connect(openFileAction, SIGNAL(activated()), this, SLOT(openFile()));
      QAction *closeFileAction = new QAction("Close","&Close", CTRL+Key_W, this,"close");
      QObject::connect(closeFileAction, SIGNAL(activated()), this, SLOT(close()));
      
      QAction *quitWindowAction = new QAction("Quit", "&Quit", ALT+Key_Q, this, "quit");
      QObject::connect(quitWindowAction, SIGNAL(activated()),qApp, SLOT(closeAllWindows()));
      
      QAction * saveAsAction = new QAction("Save As...","&Save As...", 0, this, "saveas");
      QObject::connect(saveAsAction, SIGNAL(activated()), this, SLOT(saveas()));
      QAction * saveAction = new QAction("Save","Save", CTRL+Key_S, this, "save");
      QObject::connect(saveAction, SIGNAL(activated()), this, SLOT(save()));
      QAction * newAction = new QAction("New...","&New...", CTRL+Key_N, this, "newdoc");
      QObject::connect(newAction, SIGNAL(activated()), this, SLOT(newFile()));

      fileMenu = new QPopupMenu(this);
      menuBar()->insertItem("&File", fileMenu);
      newAction->addTo(fileMenu);
      openFileAction->addTo(fileMenu);
      saveAction->addTo(fileMenu);
      saveAsAction->addTo(fileMenu);
      closeFileAction->addTo(fileMenu);
      fileMenu->insertSeparator(6);
      quitWindowAction->addTo(fileMenu);
      //treeviewToggle->addTo(fileMenu);
   }
   
   void NotebookWindow::createAboutMenu()
   {
      QAction *aboutAction = new QAction("About", "&About", 0, this, "about");
      QObject::connect(aboutAction, SIGNAL(activated()), this, SLOT(aboutQTNotebook()));
      
      aboutMenu = new QPopupMenu(this);
      menuBar()->insertItem("&Help", aboutMenu);
      aboutAction->addTo(aboutMenu);
   }

   /*! \todo Make the menu correspond to the current cell. 
    */
   void NotebookWindow::createCellMenu()
   {
      
      QAction *cutCellAction = new QAction("Cut cell", "&Cut Cell", 
					      CTRL+SHIFT+Key_X, this, "cutcell");
      QObject::connect(cutCellAction, SIGNAL(activated()), 
		       this, SLOT(cutCell()));

      QAction *copyCellAction = new QAction("Copy cell", "&Copy Cell", 
					      CTRL+SHIFT+Key_C, this, "copycell");
      QObject::connect(copyCellAction, SIGNAL(activated()), 
		       this, SLOT(copyCell()));

      QAction *pasteCellAction = new QAction("Paste cell", "&Paste Cell", 
					      CTRL+SHIFT+Key_V, this, "pastecell");
      QObject::connect(pasteCellAction, SIGNAL(activated()), 
		       this, SLOT(pasteCell()));

      QAction *addCellAction = new QAction("Add cell", "&Add Cell", CTRL+Key_A, 
					   this, "addcell");
      QObject::connect(addCellAction, SIGNAL(activated()), 
		       this, SLOT(createNewCell()));

      QAction *deleteCellAction = new QAction("Delete cell", "&Delete Cell", 
					      CTRL+SHIFT+Key_D, this, "deletecell");
      QObject::connect(deleteCellAction, SIGNAL(activated()), 
		       this, SLOT(deleteCurrentCell()));

      QAction *nextCellAction = new QAction("next cell", "&Next Cell", 
					      0, this, "nextcell");
      QObject::connect(nextCellAction, SIGNAL(activated()), 
		       this, SLOT(moveCursorDown()));
      QAction *previousCellAction = new QAction("previous cell", "&Previous Cell", 
					      0, this, "prevoiscell");
      QObject::connect(previousCellAction, SIGNAL(activated()), 
		       this, SLOT(moveCursorUp()));

      cellMenu = new QPopupMenu(this);
      menuBar()->insertItem("&Cell", cellMenu);

      cutCellAction->addTo(cellMenu);
      copyCellAction->addTo(cellMenu);
      pasteCellAction->addTo(cellMenu);

      addCellAction->addTo(cellMenu);
      deleteCellAction->addTo(cellMenu);
      nextCellAction->addTo(cellMenu);
      previousCellAction->addTo(cellMenu);
      cellMenu->insertSeparator(3);
      cellMenu->insertSeparator(5);
   }

	void NotebookWindow::createFormatMenu()
	{
		//Create style menus.
		QActionGroup *stylesgroup = new QActionGroup(this, 0, true);

		// 2005-10-03 AF, Add this check if the stylesheet file exist
		Stylesheet *sheet;
		try
		{
			sheet = Stylesheet::instance("stylesheet.xml");
		}
		catch( exception &e )
		{
			QMessageBox::warning( this, "Error", e.what(), "OK" );
			exit(-1);
		}

		vector<QString> styles = sheet->getAvailableStyles();

		formatMenu = new QPopupMenu(this);

		//QPopupMenu *styleMenu = new QPopupMenu(this);

		vector<QString>::iterator i = styles.begin();
		for(;i != styles.end(); ++i)
		{
			QAction *tmp = new QAction((*i),(*i),0, this, (*i));
			tmp->setToggleAction(true);
			stylesgroup->add(tmp);
			//tmp->addTo(styleMenu);
			styles_[(*i)] = tmp;
		}

		QObject::connect(stylesgroup, SIGNAL(selected(QAction*)),
			this, SLOT(changeStyle(QAction*)));

		stylesgroup->setUsesDropDown(true);
		stylesgroup->setMenuText("Styles");

		QAction *groupAction = new QAction("Group Cells", "&Group cells", 
			CTRL+SHIFT+Key_G, this, "groupcells");
		QObject::connect(groupAction, SIGNAL(activated()), 
			this, SLOT(groupCellsAction()));
		QAction *inputAction = new QAction("Inputcell", "&Input cell", 
			CTRL+SHIFT+Key_I, this, "inputcells");
		QObject::connect(inputAction, SIGNAL(activated()), 
			this, SLOT(inputCellsAction()));      

		QObject::connect(formatMenu, SIGNAL(aboutToShow()),
			this, SLOT(updateStyleMenu()));

		menuBar()->insertItem("&Format", formatMenu);
		stylesgroup->addTo(formatMenu);
		groupAction->addTo(formatMenu);
		inputAction->addTo(formatMenu);

		formatMenu->insertSeparator(1);
	}

   /*! \bug map[] generates segfault in some cases, espesially if
    *  style not exists in map.
    */
   void NotebookWindow::setSelectedStyle()
   {
   }
   
   void NotebookWindow::updateStyleMenu()
   {
      cerr << "Update Style Menu" << endl;

      const QString style = subject_->getCursor()->currentCell()->style();      
      map<QString, QAction*>::iterator cs = styles_.find(style);
      
      if(cs != styles_.end())
      {
	 (*cs).second->toggle(); //this activates something that it should not.
	 //styles_[style]->toggle();
      }
      else
      {
 	 qDebug("No styles found");
 	 cs = styles_.begin();
 	 for(;cs != styles_.end(); ++cs)
 	 {
 	    (*cs).second->setOn(false);
 	 }
      }
   }
   
   void NotebookWindow::createEditMenu()
   {
      QAction *undoAction = new QAction("Undo", "&Undo", 0, this, "undoaction");
      QAction *redoAction = new QAction("Redo", "&Redo", 0, this, "redoaction");
      QAction *searchAction = new QAction("Search", "&Search", 0, this, "search");
      QAction *showExprAction = new QAction("View Expression", "&View Expression",0, this, "viewexpr");

      undoAction->setEnabled(false);
      redoAction->setEnabled(false);
      searchAction->setEnabled(false);      

//       QObject::connect(undoAction, SIGNAL(activated()),
// 		       this, SLOT(undoAction()));


//       QAction *setEditableAction = new QAction("Edit cell", "&Edit Cell", 0, 
// 					       this, "editcell");
       showExprAction->setToggleAction(true);
       showExprAction->setOn(false);
      
       QObject::connect(showExprAction, SIGNAL(toggled(bool)), 
			subject_, SLOT(showHTML(bool)));
      
//  QAction *undoAction = new QAction("Select All", "&Select All", 0, this, "selectall");
      
      editMenu = new QPopupMenu(this);
      menuBar()->insertItem("&Edit", editMenu);
      undoAction->addTo(editMenu);
      redoAction->addTo(editMenu);
      editMenu->insertSeparator(3);
      //setEditableAction->addTo(editMenu);
      searchAction->addTo(editMenu);      
      showExprAction->addTo(editMenu);
   }

   ///////SLOT IMPLEMENTATIONS ///////////////////////////////////////

   void NotebookWindow::changeStyle(QAction *action)
   {    
      subject_->cursorChangeStyle(action->text());
   }

   void NotebookWindow::changeStyle()
   { 
      cerr << "Ever called" << endl;
      map<QString, QAction*>::iterator cs = styles_.begin();
      for(;cs != styles_.end(); ++cs)
      {
	 if((*cs).second->isOn())
	 {
	    subject_->cursorChangeStyle((*cs).first); //Change style.
	 }
      }
   }
	   
	void NotebookWindow::createNewCell()
	{
		subject_->cursorAddCell();
	}

   void NotebookWindow::deleteCurrentCell()
   {
      //subject_->executeCommand(new DeleteCurrentCellCommand());
      subject_->cursorDeleteCell();
   }

   void NotebookWindow::cutCell()
   {
      //subject_->executeCommand(new DeleteCurrentCellCommand());
      subject_->cursorCutCell();
   }

   void NotebookWindow::copyCell()
   {
      //subject_->executeCommand(new DeleteCurrentCellCommand());
      subject_->cursorCopyCell();
   }

   void NotebookWindow::pasteCell()
   {
      //subject_->executeCommand(new DeleteCurrentCellCommand());
      subject_->cursorPasteCell();
   }

   void NotebookWindow::moveCursorDown()
   {
      //subject_->executeCommand(new CursorMoveDownCommand());
      subject_->cursorStepDown();
   }
   
   void NotebookWindow::moveCursorUp()
   {
      //subject_->executeCommand(new CursorMoveUpCommand());
      subject_->cursorStepUp();
   }

   /*! \todo Some of this code should be moved to CellDocument
    *  instead. The filename should be connected to the document, not
    *  to the window for example.
    */
	void NotebookWindow::saveas()
	{

		QString filename = QFileDialog::getSaveFileName(
			QString::null, 
			"Notebooks (*.xml)",
			this,
			"save file dialog", 
			"Choose a filename to save under");

		if(!filename.isEmpty())
		{
			// 2005-09-30 AF, add check for file end when saving.
			// false because it's not supposted to be casesensitiv
			if( -1 == filename.find( ".xml", 0, false ) )
			{
				qDebug( ".xml not found" );
				filename.append( ".xml" );
			}

			statusBar()->message("Saving file");
			application()->commandCenter()->executeCommand(
				new SaveDocumentCommand(subject_, filename));

			filename_ = filename;
			statusBar()->message("Ready");

			//2005-09-22 AF: Added this code line:
			setCaption(QString("OMNotebook: ").append( strippedFileName(filename_) ));
		}
	}

	/*!
	 * uses QT functionality to stripp the filepath and return only
	 * the filename. //AF
	 */
	QString NotebookWindow::strippedFileName( const QString &fullFileName )
	{
		QString name = QFileInfo( fullFileName ).fileName();
		name.remove( "\n" );
		return name;
	}

	/*! 
     * Added a check that controlls if the user have saved before, 
	 * if not the function saveas should be used insted. //AF
     */
	void NotebookWindow::save()
	{
		if( !subject_->isSaved() )
		{
			saveas();
		}
		else
		{
			// old code, without check use only this code //AF
			statusBar()->message("Saving file");
			application()->commandCenter()->executeCommand(new SaveDocumentCommand(subject_));
			statusBar()->message("Ready");
		}
	}

   /*! \brief Open a file. Shows a file dialog.
    *
    * \todo Add exceptions if the file could not be opened.
    *
    * \todo When opening a file a new documentwindow is opened. So lot
    * of the code below is obsolete.
    */
   void NotebookWindow::openFile(const QString &filename)
   {      
	   try
	   {
		   //Open a new document

		   /*	 
		   2005-09-22 AF: Removed this check
		   if(subject_->isOpen()) 
				closeFile();
		   */

		   if(filename.isEmpty())
		   {    
			   //Show a dialog for choosing a file.
			   filename_ = QFileDialog::getOpenFileName(
				   QString::null, "Notebooks (*.xml *.nb)",
				   this,"file open", "Notebook -- File Open" );
		   }
		   else
		   {
			   filename_ = filename;
		   }

		   if(!filename_.isEmpty())
		   {
			   //subject_->executeCommand(new OpenFileCommand(filename_));
			   application()->commandCenter()->executeCommand(new OpenFileCommand(filename_));
			   //setCaption("Qt Notebook: " + filename_);
			   //setCentralWidget(subject_);
			   //subject_->show();

			   //createSavingTimer();
		   }
		   else
		   {
			   //Cancel pushed. Do nothing
		   }
	   }
	   catch(exception &e)
	   {
		   cerr << "In NotebookWindow(), Exception: " << e.what() << endl;
		   openFile();
	   }
   }
   
   
	/*! 
	 * \todo Not implemented yet. 
	 * 
	 * the function isn't used, this funciton should also close the 
	 * window, if it isn't the last window //AF
	 */
	void NotebookWindow::closeFile()
	{
		subject_->executeCommand(new CloseFileCommand());


		//application()->

		// if(savingTimer_)
		//       {
		// 	 savingTimer_->stop();
		// 	 delete savingTimer_;
		//       }
		//delete subject_;
	}

	/*! 
	 * \todo Fix the code when the window dosen't have any file open,
	 * the command should create the new document, not this function //AF
	 *
	 */
	void NotebookWindow::newFile()
	{
		/*
		application()->commandCenter()->executeCommand(new NewFileCommand());

		closeFile();
	      
		createSavingTimer();

		subject_ = new CellDocument(this);

		connect(subject_, SIGNAL(cursorChanged()),
 			this, SLOT(setSelectedStyle()));

		setCentralWidget(subject_);
	      
		subject_->show();
		*/

		// AF
		if( subject_->isOpen() )
		{
			// a file is open, open a new window with the new file //AF
			application()->commandCenter()->executeCommand(new OpenFileCommand(QString::null));
		}
		else
		{
			subject_ = new CellDocument(app_, QString::null);
			subject_->executeCommand(new NewFileCommand());
			subject_->attach(this);

			update();
		}
	}

   void NotebookWindow::groupCellsAction()
   {
      subject_->executeCommand(new MakeGroupCellCommand());
   }

   void NotebookWindow::inputCellsAction()
   {
      subject_->executeCommand(new CreateNewCellCommand("Input"));
   }

   void NotebookWindow::createSavingTimer()
   {
      //start a saving timer.
      savingTimer_ = new QTimer();	    
      savingTimer_->start(30000);
	    
      connect(savingTimer_, SIGNAL(timeout()),
	      this, SLOT(save()));
   }

   /*!
    * Why does not keyPressEvents occur? They are eaten somewhere.
    */
   void NotebookWindow::keyPressEvent(QKeyEvent *event)
   {
   }

   void NotebookWindow::keyReleaseEvent(QKeyEvent *event)
   {
	   //qDebug( event->text() );

      if(event->state() == Qt::ControlButton)
      {
	 if(event->key() == Qt::Key_Up)
	 {
	    moveCursorUp();
	    event->accept();
	 }
	 else if(event->key() == Qt::Key_Down)
	 {
	    moveCursorDown();
	    event->accept();
	 }
	 else
	 {
	    QMainWindow::keyReleaseEvent(event);
	 }
      }
      else
      {
	 QMainWindow::keyReleaseEvent(event);
      }
   }

   Application *NotebookWindow::application()
   {
      return subject_->application();
   }

}

#endif
