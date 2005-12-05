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

/*! \file celldocument.cpp
 * \author Ingemar Axelsson
 * \brief Implementation of CellDocument class.
 */

//STD Headers
#include <iostream>
#include <exception>
#include <algorithm>

//QT Headers
#include <qfileinfo.h>

//IAEX Headers
#include "celldocument.h"
#include "cellfactory.h"
#include "serializingvisitor.h"
#include "nbparser.h"
#include "parserfactory.h"
#include "notebookcommands.h"
#include "cursorcommands.h"
#include "cellcommands.h"


namespace IAEX{
   
   /*! 
    * \class CellDocument
    * \brief Main widget for the cell workspace.
    *
    * This class represents the mainwidget for the application. It has
    * functionality to open files and create cells from them. It also
    * knows which cells that are selected. 
    *
    * CellDocument acts like a mediator between the application and all
    * cells. It knows how to do stuff with cells.
    *
    * The CellDocument does not have any menu. So to use menus for
    * doing stuff with the application look at the slots that exists in
    * this class.
    *
    * For more information about how to use this widget in an application
    * look at the documentation for every signal and slot in this class.
    *
    *
    * \todo Implement an interface for applications. Also sort the
    * includes in a better way. So developers does not have to include a
    * lot of strange headerfiles. Just one headerfile should be enough.
    *
    * \todo Fix the windowsize so it is more appropriate. Also fix so that
    * the cellgroup is redrawn when the application is first started, not
    * only when it is resized.
    *
    * \todo Implement functionality for dragging cells around.
    *
    * \todo Make it possible to change celltype. From textcell to
    * inputcell for example. Inputcell should only be a decorator of a
    * textcell.
    *
    * \bug When opening a second file, some connections is missing.
    *  
    * \bug Closing a document does not work correctly.
    *
    */
   
   /*! 
    * \brief Constructor, initialize a CellGroup as maincontent.
    *
    * \todo Remove the dependency of QFrame from document.
    */
   CellDocument::CellDocument(Application *a, const QString filename)
      : open_(false), saved_(false), app_(a), filename_(filename)
   {
      //New code.
       mainFrame_ = new QFrame();
       mainFrame_->setSizePolicy(QSizePolicy(QSizePolicy::Expanding, 
 					    QSizePolicy::Expanding));
       mainLayout_ = new QGridLayout(mainFrame_, 1, 1);
      
      //Old code.
//       mainLayout_ = new QGridLayout(this, 1, 1);
      
//       setSizePolicy(QSizePolicy(QSizePolicy::Expanding, 
// 				QSizePolicy::Expanding));


      factory_ = new CellFactory(this);

      //Initialize workspace.
      setWorkspace(factory_->createCell("cellgroup"));
      
	  if(filename_ != 0)
		open(filename_);


	  open_ = true; // 2005-09-26 AF, not sure if this should be here
   }

   CellDocument::~CellDocument()
   {
      //destroy(FALSE, TRUE); //Delete all subwindows and myself.
      
      delete vp_;
      delete mainLayout_;
      delete workspace_;
      //delete mainFrame_;
	  delete factory_;

   }

   void CellDocument::mouseClickedOnCell(Cell *clickedCell)
   {
      //Deselect all selection
      clearSelection();
      
      //Remove focus from old cell.
      if(getCursor()->currentCell()->isClosed())
      {
		 getCursor()->currentCell()->child()->setReadOnly(true);
		 getCursor()->currentCell()->child()->setFocus(false);
      }
      else
      {
		 getCursor()->currentCell()->setReadOnly(true);
      }
      
      //Add focus to the cell clicked on.
      if(clickedCell->parentCell()->isClosed())
      {
		 getCursor()->moveAfter(clickedCell->parentCell());
      }
      else
      {
		 getCursor()->moveAfter(clickedCell); //Results in bus error why?
      }
      
      clickedCell->setReadOnly(false);
      clickedCell->setFocus(true);
      
      emit cursorChanged();
      //qDebug("Clicked on cell");
   }

   /*! What to do when a link is clicked?
    */
   void CellDocument::linkClicked(QUrl *link)
   {
      cout << "PATH: " << link->path() << "ENDPATH" <<  endl;
      //executeCommand(new OpenFileCommand(link->path()));

	   // 2005-10-25 AF, temp fix so links works correctly, links are
	  // relative the location of the current document
	  executeCommand(new OpenFileCommand( QFileInfo(filename_).dirPath() +
		  "/" + link->path() )); 
   }

   /*!
    * Problem with the eventfilter. Should be listening to the
      mainwidget of the cell also. Not only to the workspace.
    */
   bool CellDocument::eventFilter(QObject *o, QEvent *e)
   {
      if(o == workspace_)
      {
	 if(e->type() == QEvent::MouseButtonPress)
	 {	    
	    qDebug("Clicked");
	 }
      }
      
      return QObject::eventFilter(o,e);
   }

   CellCursor *CellDocument::getCursor()
   {
      return current_;
   }

   /*!
    * \todo Save all commands. Also implement undo. Where should the
    * undo be set? Global in application or local in document? Or
    * should different commands be stored in different places.
    *
    * \todo implement a commandCenter interface that takes care of
    * this. A problem with this conversion is the commands dependency
    * for the document reference.
    */
   void CellDocument::executeCommand(Command *cmd)
   {
      cmd->setDocument(this);
      application()->commandCenter()->executeCommand(cmd);
   }

   void CellDocument::open(const QString &filename)
   {      
      filename_ = filename;
      ParserFactory *parserFactory = new CellParserFactory();
      NBParser *parser = parserFactory->createParser(filename, factory_);
      setWorkspace(parser->parse());
	  
      //Delete the parser after it is used.  
	  delete parser;

	  // 2005-09-22 AF: Added this...
	  open_ = true;
	  saved_ = false;
   }
   
   /*!
	* \todo Check if factory is instantiated. 
	*/
   Factory *CellDocument::cellFactory()
   {
      return factory_;
   }
   
   QString CellDocument::getFilename()
   {
      return filename_;
   }

   void CellDocument::setFilename( QString filename )
   {
	   filename_ = filename;
   }

	void CellDocument::setSaved( bool saved )
	{
		saved_ = saved;
	}
   
	/*! \todo Implement hasChanged correctly.
	 *
	 * Does it belong here?
	 */
	bool CellDocument::hasChanged() const
	{
		return true;
	}
      
	bool CellDocument::isOpen() const
	{
		return open_;
	}

	bool CellDocument::isSaved() const
	{
		return saved_;
	}

   /*! Hmmm check this later.
    */
   void CellDocument::close()
   {
      //workspace_->close(true); //Close widget
      //mainLayout_->deleteLater();
	  workspace_->close();

      setWorkspace(factory_->createCell("cellgroup"));
      workspace_->hide();
      open_ = false;
   }
   
   /*! \brief Toggles the main workspace treeview.
    * 
    * Shows or hides the outermost treeview. This is just used for
    * testing. Should not be used by anyone else.
    *
    * \deprecated
    */
   void CellDocument::toggleMainTreeView()
   {
      workspace_->hideTreeView(!workspace_->isTreeViewVisible());
   }   


   /*! \brief Attach a CellGroup to be the main workspace for cells. 
    *
    * Connects a cellgroup to the scrollview. Does some reparent stuff
    * also so all subcells will be drawn. This must be done every time
    * this member is changed.
    * 
    * \param[in] newWorkspace A pointer to the CellGroup that will be seen as
    * the main cellworkspace in the application.
    *
    * \todo The old workspace must be deleted!
    *
    */
   void CellDocument::setWorkspace(Cell *newWorkspace)
   {
      //New Code
      vp_ = new QScrollView(mainFrame_);

      vp_->enableClipper(TRUE);
      vp_->setSizePolicy(QSizePolicy(QSizePolicy::Expanding, 
				     QSizePolicy::Expanding));
      vp_->setResizePolicy(QScrollView::AutoOneFit);
      mainLayout_->addWidget(vp_, 1, 1);
      
      workspace_ = newWorkspace;
      workspace_->reparent(vp_->viewport(), QPoint(0,0), true);
      
      vp_->addChild(workspace_);
      
      //?? Should this be done by the factory?
      current_ = dynamic_cast<CellCursor*>(factory_->createCell("cursor", workspace_));
 
      //Make the cursor visible at all time.
      QObject::connect(current_, SIGNAL(positionChanged(int, int, int, int)),
		       vp_, SLOT(ensureVisible(int, int, int, int)));
      
      workspace_->addChild(current_); 
      
	  //To hide the outhermost treeview.
      workspace_->hideTreeView(true);
      workspace_->show();
   }

   //Ever used?
    void CellDocument::cursorChangedPosition()
    {
//       emit cursorChanged();
    }
      
   /*!
    * \todo Check if ever used. It does seem to be deprecated.
    */
   void CellDocument::setEditable(bool editable)
   {
      if(current_->hasPrevious())
      {
	 current_->previous()->setReadOnly(!editable);
      }
   }
   
   /*! \brief Runs a visitor on the cellstructure. 
    *
    * Traverses the tree in preorder. For more usage information \see visitor.
    *
    * \param v Visitor to run on the treestructure.
    */
   void CellDocument::runVisitor(Visitor &v)
   {
      //For all workspace_ child! Not ws itself.
      workspace_->accept(v);
   }

   ////SELECTION HANDLING/////////////////////////

   void CellDocument::clearSelection()
   {      
      vector<Cell*>::iterator i = selectedCells_.begin();
      for(;i!= selectedCells_.end();++i)
	 (*i)->setSelected(false);
      selectedCells_.clear();
   }

   void CellDocument::selectedACell(Cell *selected, Qt::ButtonState state)
   {
      vector<Cell*>::iterator found = std::find(selectedCells_.begin(), 
						selectedCells_.end(),
						selected);
      if(found != selectedCells_.end())
      {  	 
		 //State - 1 is QT stuff.
		 if(state-1 == Qt::ControlButton)
		 {
			(*found)->setSelected(false);
		 }
		 else
		 {
			clearSelection();
		 }
      }
      else
      {  //if not selected
		 if(state - 1 == Qt::ControlButton)
		 { //add to selection.
			selectedCells_.push_back(selected);
		 }
		 else
		 {  
			clearSelection();
			
			//Add new cell to selected.
			selectedCells_.push_back(selected);
		 }
      }
   }
   
   vector<Cell*> CellDocument::getSelection()
   {
      return selectedCells_;
   }

/////OBSERVER IMPLEMENTATION//////////////

   void CellDocument::attach(DocumentView *d)
   {
      observers_.push_back(d);
   }
   
   void CellDocument::detach(DocumentView *d)
   {
      observers_t::iterator found = find(observers_.begin(),
					 observers_.end(),
					 d);
      if(found != observers_.end())
	 observers_.erase(found);
   }
   
   void CellDocument::notify()
   {
      observers_t::iterator i = observers_.begin();
      for(;i != observers_.end(); ++i)
      {
	 (*i)->update();
      }
   }

///////CURSOR METHODS///////////////////////////////   

   QFrame *CellDocument::getState()
   {
      return mainFrame_;
   }

   void CellDocument::cursorStepUp()
   {
      executeCommand(new CursorMoveUpCommand());
      emit cursorChanged();
   }

   void CellDocument::cursorStepDown()
   {      
      executeCommand(new CursorMoveDownCommand());
      emit cursorChanged();
   }

	void CellDocument::cursorAddCell()
	{
		// 2005-10-03 AF, added try-catch
		try
		{
			executeCommand(new AddCellCommand());
			open_ = true;
			emit cursorChanged();
		}
		catch( exception &e )
		{
			throw e;
		}
	}

   void CellDocument::cursorDeleteCell()
   {
      executeCommand(new DeleteSelectedCellsCommand());
      qDebug("cursorDeleteCell");
	  
      //emit cursorChanged(); //This causes an untracable segfault.
      
      qDebug("Finished");
   }

   /*! Notice that it does not work on selected cells.
	*/
   void CellDocument::cursorCutCell()
   {
      executeCommand(new DeleteCurrentCellCommand());      
   }

   void CellDocument::cursorCopyCell()
   {
      executeCommand(new CopySelectedCellsCommand());
   }
   
   void CellDocument::cursorPasteCell()   
   {
      executeCommand(new PasteCellsCommand());
   }

   void CellDocument::cursorChangeStyle(const QString &style)
   {  
      //Invoke style changes to all selected cells.
      executeCommand(new ChangeStyleOnSelectedCellsCommand(style));
      //executeCommand(new ChangeStyleOnCurrentCellCommand(style));
   }

   void CellDocument::cursorMoveAfter(Cell *aCell, const bool open)
   {
      //if(!open)
      executeCommand(new CursorMoveAfterCommand(aCell));
      // else
//       {
// 	 if(aCell->hasChilds())
// 	    executeCommand(new CursorMoveAfterCommand(aCell->child()));
// 	 else
// 	    executeCommand(new CursorMoveAfterCommand(aCell));
//       }
      
      emit cursorChanged();
   }

   void CellDocument::showHTML(bool b)
   {
      getCursor()->currentCell()->viewExpression(b);
   }
};
