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
 * \file celldocument.h
 * \author Ingemar Axelsson and Anders Fernström
 *
 * \brief Implementation of CellDocument class.
 */


//STD Headers
#include <iostream>
#include <exception>
#include <algorithm>

//QT Headers
#include <QtCore/QDir>
#include <QtCore/QEvent>
#include <QtCore/QFileInfo>
#include <QtCore/QUrl>
#include <QtGui/QGridLayout>
#include <QtGui/QImageWriter>
#include <QtGui/QScrollArea>
#include <QtGui/QScrollBar>

//IAEX Headers
#include "celldocument.h"
#include "cellfactory.h"
#include "serializingvisitor.h"
#include "nbparser.h"
#include "parserfactory.h"
#include "notebookcommands.h"
#include "cursorcommands.h"
#include "cellcommands.h"
#include "textcursorcommands.h"
#include "documentview.h"
#include "xmlparser.h"
#include "cursorposvisitor.h"


namespace IAEX
{
	/*! 
	 * \class CellDocument
	 * \author Ingemar Axelsson and Anders Fernström
	 *
	 * \brief Main widget for the cell workspace.
	 *
	 * This class represents the mainwidget for the application. It has
	 * functionality to open files and create cells from them. It also
	 *  knows which cells that are selected. 
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
	 * lot of strange headerfiles. Just one headerfile should be enough.(Ingemar Axelsson)
	 *
	 * \todo Implement functionality for dragging cells around.(Ingemar Axelsson)
	 *
	 * \todo Make it possible to change celltype. From textcell to
	 * inputcell for example. Inputcell should only be a decorator of a
	 * textcell.(Ingemar Axelsson)
	 *
	 *
	 * \bug When opening a second file, some connections is missing.
	 *  
	 * \bug Closing a document does not work correctly.
	 */


	/*! 
	 * \author Ingemar Axelsson (and Anders Fernström)
	 * \date 2005-11-28 (update)
	 *
	 * \brief Constructor, initialize a CellGroup as maincontent.
	 *
	 * 2005-11-28 AF, added connection between 'cursorChanged()' 
	 * and 'updateScrollArea()'
	 *
	 * \todo Remove the dependency of QFrame from document.(Ingemar Axelsson)
	 */
	CellDocument::CellDocument( Application *a, const QString filename, 
		int readmode )
		: changed_(false),
		open_(false), 
		saved_(false), 
		app_(a), 
		filename_(filename),
		currentImageNo_(0),
		lastClickedCell_(0)
	{
		mainFrame_ = new QFrame();
		mainFrame_->setSizePolicy(QSizePolicy(QSizePolicy::Expanding, 
			QSizePolicy::Expanding));

		mainLayout_ = new QGridLayout(mainFrame_);
		mainLayout_->setMargin(0);
		mainLayout_->setSpacing(0);
		

		//Initialize workspace.
		factory_ = new CellFactory(this);
		setWorkspace(factory_->createCell("cellgroup"));

		// 2005-11-28 AF
		connect( this, SIGNAL( cursorChanged() ), 
			this, SLOT( updateScrollArea() ));

		// 2005-12-01 AF, Added try-catch
		try
		{
			if(filename_ != QString::null)
				open( filename_, readmode );
		}
		catch( exception &e )
		{
			throw e;
		}


		open_ = true; // 2005-09-26 AF, not sure if this should be here
	}

	/*! 
	 * \author Ingemar Axelsson
	 *
	 * \brief The class destructor
	 */
	CellDocument::~CellDocument()
	{
		delete scroll_;
		delete mainLayout_;
		//delete workspace_;
		delete mainFrame_;
		delete factory_;

		// 2006-01-16 AF (update), remove all images in memory and add
		// the temporary images to removelist in the main applicaiton
		QHash<QString, QImage*>::iterator i_iter = images_.begin();
		while( i_iter != images_.end() )
		{
			// add temporary images to removelist
			application()->removeTempFiles( i_iter.key() );
			
			// delete image
			delete i_iter.value();
			++i_iter;
		}
	}

	/*! 
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2005-12-01 (update)
	 *
	 * \brief Open an file and parse the content
	 *
	 * 2005-09-22 AF, Added open_ variable
	 * 2005-10-02 AF, Added saved_ variable
	 * 2005-12-01 AF, Added try-catch
	 */
	void CellDocument::open( const QString &filename, int readmode )
	{      
		filename_ = filename;

		ParserFactory *parserFactory = new CellParserFactory();
		NBParser *parser = parserFactory->createParser(filename, factory_, this, readmode);

		// 2005-12-01 AF, Added try-catch
		try
		{
			Cell *cell = parser->parse();
			setWorkspace( cell );
		}
		catch( exception e )
		{
			delete parserFactory;
			delete parser;
			throw e;
		}
		

		//Delete the parser after it is used. 
		delete parserFactory;
		delete parser;

		// 2005-09-22 AF, Added this...
		open_ = true;

		// 2005-11-02 AF, set saved_ to true if the loaded file is .onb
		if( 0 < filename_.indexOf( ".onb", 0, Qt::CaseInsensitive ) )
			saved_ = true;
		else
			saved_ = false;
	}

	/*! 
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2005-10-28 (update)
	 *
	 * \brief Change the style of the selected cell/cells
	 */
	void CellDocument::cursorChangeStyle(CellStyle style)
	{  
		//Invoke style changes to all selected cells.
		executeCommand(new ChangeStyleOnSelectedCellsCommand(style));
	}

	/*!
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2005-11-01 (update)
	 *
	 * \brief Attach a CellGroup to be the main workspace for cells. 
	 *
	 * Connects a cellgroup to the scrollview. Does some reparent stuff
	 * also so all subcells will be drawn. This must be done every time
	 * this member is changed.
	 *
	 * 2005-11-01 AF, replaced the old Q3ScrollView with the new
	 * QScrollArea and needed to change/update some thing in this 
	 * function;
	 * 
	 * \param newWorkspace A pointer to the CellGroup that will be seen as
	 * the main cellworkspace in the application.
	 *
	 *
	 * \todo The old workspace must be deleted!(Ingemar Axelsson)
	 */
	void CellDocument::setWorkspace(Cell *newWorkspace)
	{
		scroll_ = new QScrollArea( mainFrame_ );
		scroll_->setWidgetResizable( true );
		scroll_->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
		scroll_->setVerticalScrollBarPolicy( Qt::ScrollBarAsNeeded );
		
		mainLayout_->addWidget(scroll_, 1, 1);
		
		workspace_ = newWorkspace;

		// PORT >> workspace_->reparent(scroll_->viewport(), QPoint(0,0), true);
		//workspace_->setParent( scroll_->viewport() );
		//workspace_->move( QPoint(0,0) );
		//workspace_->show();

		scroll_->setWidget( workspace_ );

		//?? Should this be done by the factory?
		current_ = dynamic_cast<CellCursor*>(factory_->createCell("cursor", workspace_));

		//Make the cursor visible at all time.
		//QObject::connect(current_, SIGNAL(positionChanged(int, int, int, int)),
		//	vp_, SLOT(ensureVisible(int, int, int, int)));

		workspace_->addChild( current_ ); 

		//To hide the outhermost treeview.
		workspace_->hideTreeView( true );
		workspace_->show();
	}

	/*!
	 * \author Ingemar Axelsson
	 */	
	void CellDocument::cursorStepUp()
	{
		executeCommand(new CursorMoveUpCommand());
		emit cursorChanged();
	}

	/*!
	 * \author Ingemar Axelsson
	 */	
	void CellDocument::cursorStepDown()
	{      
		executeCommand(new CursorMoveDownCommand());
		emit cursorChanged();
	}

	/*!
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2005-10-03 (update)
	 *
	 * 2005-10-03 AF, addad the try-catch expression
	 */
	void CellDocument::cursorAddCell()
	{
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

	/*! 
	 * \author Anders Fernström
	 * \date 2006-04-26
	 *
	 * \brief Ungroup all selected groupcells
	 */
	void CellDocument::cursorUngroupCell()
	{
		try
		{	
			executeCommand( new UngroupCellCommand() );
			emit cursorChanged();
		}
		catch( exception &e )
		{
			throw e;
		}
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-04-26
	 *
	 * \brief Split current cell
	 */
	void CellDocument::cursorSplitCell()
	{
		try
		{	
			executeCommand( new SplitCellCommand() );
			emit cursorChanged();
		}
		catch( exception &e )
		{
			throw e;
		}
	}

	/*!
	 * \author Ingemar Axelsson
	 */
	void CellDocument::cursorDeleteCell()
	{
		executeCommand(new DeleteSelectedCellsCommand());
		qDebug("cursorDeleteCell");

		//emit cursorChanged(); //This causes an untracable segfault.

		qDebug("Finished");
	}

	/*!
	 * \author Ingemar Axelsson
	 *
	 * \bug Notice that it does not work on selected cells.
	 */
	void CellDocument::cursorCutCell()
	{
		executeCommand(new DeleteCurrentCellCommand());      
	}

	/*!
	 * \author Ingemar Axelsson
	 */ 
	void CellDocument::cursorCopyCell()
	{
		executeCommand(new CopySelectedCellsCommand());
	}

	/*!
	 * \author Ingemar Axelsson
	 */
	void CellDocument::cursorPasteCell()   
	{
		executeCommand(new PasteCellsCommand());
	}

	/*!
	 * \author Ingemar Axelsson
	 */
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

	/*! 
	 * \author Anders Fernström
	 * \date 2006-02-07
	 *
	 * \brief Cut text
	 */
	void CellDocument::textcursorCutText()
	{
		executeCommand( new TextCursorCutText() );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-02-07
	 *
	 * \brief Copy text
	 */
	void CellDocument::textcursorCopyText()
	{
		executeCommand( new TextCursorCopyText() );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-02-07
	 *
	 * \brief Paste text
	 */
	void CellDocument::textcursorPasteText()
	{
		executeCommand( new TextCursorPasteText() );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-03
	 *
	 * \brief Change the font family on the selected text, if
	 * no text selected the current font family will be changed.
	 *
	 * \param family The new font family
	 */
	void CellDocument::textcursorChangeFontFamily(QString family)
	{
		executeCommand( new TextCursorChangeFontFamily(family) );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-03
	 *
	 * \brief Change the font weight on the selected text, if
	 * no text selected the current font weight will be changed.
	 *
	 * \param weight The new font weight
	 */
	void CellDocument::textcursorChangeFontFace(int face)
	{
		executeCommand( new TextCursorChangeFontFace(face) );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-03
	 *
	 * \brief Change the font size on the selected text, if
	 * no text selected the current font size will be changed.
	 *
	 * \param size The new font size
	 */
	void CellDocument::textcursorChangeFontSize(int size)
	{
		executeCommand( new TextCursorChangeFontSize(size) );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-03
	 *
	 * \brief Change the font stretch on the selected text, if
	 * no text selected the current font stretch will be changed.
	 *
	 * \param stretch The new font stretch
	 */
	void CellDocument::textcursorChangeFontStretch(int stretch)
	{
		executeCommand( new TextCursorChangeFontStretch(stretch) );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-03
	 *
	 * \brief Change the font color on the selected text, if
	 * no text selected the current font color will be changed.
	 *
	 * \param color The new font color
	 */
	void CellDocument::textcursorChangeFontColor(QColor color)
	{
		executeCommand( new TextCursorChangeFontColor(color) );
	}
	
	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-03
	 *
	 * \brief Change the text alignment on the text inside the cell
	 *
	 * \param alignment The new text alignment
	 */
	void CellDocument::textcursorChangeTextAlignment(int alignment)
	{
		executeCommand( new TextCursorChangeTextAlignment(alignment) );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-03
	 *
	 * \brief Change the vertical alignment on the selected text, if
	 * no text selected the current vertical alignment will be changed.
	 *
	 * \param color The new vertical alignment
	 */
	void CellDocument::textcursorChangeVerticalAlignment(int alignment)
	{
		executeCommand( new TextCursorChangeVerticalAlignment(alignment) );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-03
	 *
	 * \brief Change the margin of the cell
	 *
	 * \param margin The new maring
	 */
	void CellDocument::textcursorChangeMargin(int margin)
	{
		executeCommand( new TextCursorChangeMargin(margin) );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-03
	 *
	 * \brief Change the padding of the cell
	 *
	 * \param padding The new padding
	 */
	void CellDocument::textcursorChangePadding(int padding)
	{
		executeCommand( new TextCursorChangePadding(padding) );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-03
	 *
	 * \brief Change the border of the cell
	 *
	 * \param border The new border
	 */
	void CellDocument::textcursorChangeBorder(int border)
	{
		executeCommand( new TextCursorChangeBorder(border) );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-18
	 *
	 * \brief Insert a image into the selected cell
	 *
	 * \param filepath The path to the image
	 */
	void CellDocument::textcursorInsertImage(QString filepath, QSize size)
	{
		executeCommand( new TextCursorInsertImage(filepath, size) );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-18
	 * \date 2006-02-13 (update)
	 *
	 * \brief Add image to the document
	 *
	 * The function first check for an availible name for the image,
	 * then saves the image temporary to the harddirve and returns
	 * the name of the file.
	 *
	 * 2005-12-12 AF, Added 'file:///(path)/' to very image name
	 * 2006-02-13 AF, All images are added in the sub dir 
	 * 'OMNotebook_tempfiles'.
	 *
	 * \param image A pointer to the images that should be added
	 * \return the filename of the saved image
	 */
	QString CellDocument::addImage(QImage *image)
	{
		// first find a correct temp filename
		QDir dir;

		// 2006-02-13 AF, store images in temp dir
		dir.setPath( dir.absolutePath() + "/OMNoteboook_tempfiles" );

		QString name;
		while( true )
		{
			currentImageNo_++;
			name.setNum( currentImageNo_ );
			name += ".png";
			if( !dir.exists( name ))
				break;
		}

		name = dir.absolutePath() + "/" + name;

		// save the image temporary to the harddrive
		QImageWriter writer( name, "png" );
		writer.setDescription( "Temporary OMNotebook image" );
		writer.setQuality( 100 );
		writer.write( *image );
		
		images_[ name ] = image;

		// 2005-12-12 AF, Add file:/// to filename
		name = QString("file:///") + name;

		// return the imagename
		return name;
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-20
	 * \date 2005-12-12 (update)
	 *
	 * \brief Returns the image with the specified name
	 *
	 * 2005-12-12 AF, remove 'file:///' from name
	 *
	 * \param name Name of the image
	 * \return a pointer to the image
	 */
	QImage *CellDocument::getImage(QString name)
	{
		name.remove( "file:///" );

		QImage *image;

		if( images_.contains( name ))
			image = images_[name];
		else
		{
			cout << "Could not find image: " << name.toStdString() << endl;
			image = new QImage();
		}

		return image;
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-12-05
	 *
	 * \brief Insert a link to the selected text
	 *
	 * \param filepath The linkpath to another docuement
	 */
	void CellDocument::textcursorInsertLink( QString filepath )
	{
		executeCommand( new TextCursorInsertLink( filepath ));
	}

	/*! 
	 * \author Ingemar Axelsson and Anders Fernström
	 */
	bool CellDocument::hasChanged() const
	{
		return changed_;
	}

	/*! 
	 * \author Ingemar Axelsson
	 */
	bool CellDocument::isOpen() const
	{
		return open_;
	}

	/*! 
	 * \author Anders Fernström
	 */
	bool CellDocument::isSaved() const
	{
		return saved_;
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-29
	 * \date 2006-03-03 (update)
	 *
	 * \brief Update the scrollarea so the correct area is displayed
	 *
	 * 2005-12-08 AF, remade function becuase the earlier version hade
	 * some large bugs. Didn't calculate cells position correct, becuase
	 * qt:s layout system reset position to 0 in every groupcell and
	 * layout are probobly not set correctly.
	 * 2006-03-03 AF, ignore move if the cursor it at the end of the 
	 * document
	 */
	void CellDocument::updateScrollArea()
	{
		if( scroll_->verticalScrollBar()->isVisible() )
		{
			CellCursor *cursor = getCursor();
			if( cursor )
			{
				// ignore, if selected cell is a groupcell
				if( typeid( *cursor->currentCell() ) != typeid( CellGroup ) )
				{
					// calculate the position of the cursor, by adding the height
					// of all the cells before the cellcursor, using a visitor
					CursorPosVisitor visitor;
					runVisitor( visitor );
					int pos = visitor.position();

					// size of scrollarea
					int scrollTop = scroll_->widget()->visibleRegion().boundingRect().top();
					int scrollBottom = scroll_->widget()->visibleRegion().boundingRect().bottom();

					// cell height
					int height = cursor->currentCell()->height();

					/*
					cout << "*********************************************" << endl;
					cout << "SCROLL TOP: " << scrollTop << endl;
					cout << "SCROLL BOTTOM: " << scrollBottom << endl;
					cout << "CELL CURSOR: " << pos << endl;
					cout << "CELL HEIGHT: " << height << endl;
					*/
					
					

					// TO BIG
					if( height > (scrollBottom-scrollTop) )
					{
						//qDebug( "TO BIG" );
						// cell so big that it span over entire viewarea
						return;
					}
					// END OF DOCUMENT
					else if( pos > (scroll_->widget()->height() - 2 ) &&
						scrollBottom > (scroll_->widget()->height() - 2 ) )
					{
						//cout << "END OF DOCUMENT, widget height(" << scroll_->widget()->height() << ")" << endl;
						// 2006-03-03 AF, ignore if cursor at end of document
						return;
					}
					// UP
					else if( (pos - height) < scrollTop )
					{
						// cursor have moved above the viewarea of the 
						// scrollbar, move up the scrollbar

						// remove cell height + a little extra
						pos -= (height + 10);
						if( pos < 0 )
							pos = 0;

						// set new scrollvalue
						//cout << "UP: old(" << scroll_->verticalScrollBar()->value() << "), new(" << pos << ")" << endl;
						scroll_->verticalScrollBar()->setValue( pos );
					}
					// DOWN
					else if( pos > (scrollBottom - 10) )
					{
						// cursor have moved below the viewarea of the 
						// scrollbar, move down the scrollbar

						// add cell height + a little extra to scrollbar
						//pos = height + 20 + scroll_->verticalScrollBar()->value();

						// add differens between cell cursor position och scroll bottom
						// to the scroll value
						pos = scroll_->verticalScrollBar()->value() + (pos - (scrollBottom - 10));
						
						if( pos >= scroll_->verticalScrollBar()->maximum() )
						{
							pos = scroll_->verticalScrollBar()->maximum();
						
							// a little extra to the max value of the scrollbar
							scroll_->verticalScrollBar()->setMaximum( 5 +
								scroll_->verticalScrollBar()->maximum() );
						}

						// set new scrollvalue
						//cout << "DOWN: old(" << scroll_->verticalScrollBar()->value() << "), new(" << pos << ")" << endl;
						scroll_->verticalScrollBar()->setValue( pos );
					}
				}
			}
		}
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-01-17
	 *
	 * \brief set the change variable
	 */
	void CellDocument::setChanged( bool changed )
	{
		changed_ = changed;
		emit contentChanged();
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-02-10
	 */
	void CellDocument::hoverOverUrl( const QUrl &link )
	{
		QString filelink = link.path();

		if( !link.fragment().isEmpty() )
			filelink += QString("#") + link.fragment();

		if( !filelink.isEmpty() && !link.path().isEmpty() )
		{
			if( filename_.isEmpty() || filename_.isEmpty() )
			{
				// replace '\' with '/' in the link path
				filelink.replace( "\\", "/" );

				QDir dir;
				filelink = dir.absolutePath() + "/" + filelink; 	
			}
			else
			{
				// replace '\' with '/' in the link path
				filelink.replace( "\\", "/" );
				filelink = QFileInfo(filename_).absolutePath() + "/" + filelink; 	
			}
		}
		
        emit hoverOverFile( filelink );
	}

	/*! 
	 * \author Ingemar Axelsson
	 */
	void CellDocument::mouseClickedOnCell(Cell *clickedCell)
	{
		// 2006-04-25, AF
		if( lastClickedCell_ == clickedCell )
			return;
		else
			lastClickedCell_ = clickedCell;


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
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-02-03
	 *
	 * \brief set focus on output part in inputcell
	 */
	void CellDocument::mouseClickedOnCellOutput(Cell *clickedCell)
	{
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

		if( typeid(InputCell) == typeid(*clickedCell) )
		{
			InputCell *inputcell = dynamic_cast<InputCell*>(clickedCell);
			inputcell->setReadOnly(false);
			inputcell->setFocusOutput(true);
		}
		else
		{
			clickedCell->setReadOnly(false);
			clickedCell->setFocus(true);
		}

		emit cursorChanged();
	}

	/*! 
	 * \author Anders Fernström and Ingemar Axelsson
	 * \date 2006-02-10 (update)
	 *
	 * \brief open a new document
	 *
	 * 2005-12-05 AF, check if filename exists, otherwise use work dir 
	 * 2006-02-10 AF, check if link path and fragment exists
	 */
	void CellDocument::linkClicked(const QUrl *link)
	{ 
		// 2006-02-10 AF, check if path is empty
		if( !link->path().isEmpty() )
		{
			// 2005-12-05 AF, check if filename exists, otherwise use work dir
			if( filename_.isEmpty() || filename_.isEmpty() )
			{
				// replace '\' with '/' in the link path
				QString linkpath = link->path();
				linkpath.replace( "\\", "/" );

				QDir dir;
				executeCommand(new OpenFileCommand( dir.absolutePath() + "/" + linkpath )); 	
			}
			else
			{
				// replace '\' with '/' in the link path
				QString linkpath = link->path();
				linkpath.replace( "\\", "/" );

				executeCommand(new OpenFileCommand( QFileInfo(filename_).absolutePath() + "/" + linkpath )); 	
			}
		}


		// 2006-02-10 AF, check if there is a link fragment
		if( !link->fragment().isEmpty() )
		{
			//should handel internal document links in some way

		}
	}




	// ***************************************************************





	

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
	* should different commands be stored in different places.(Ingemar Axelsson)
	*
	* \todo implement a commandCenter interface that takes care of
	* this. A problem with this conversion is the commands dependency
	* for the document reference.(Ingemar Axelsson)
	*/
	void CellDocument::executeCommand(Command *cmd)
	{
		cmd->setDocument(this);
		application()->commandCenter()->executeCommand(cmd);
	}

	/*!
	* \todo Check if factory is instantiated. (Ingemar Axelsson)
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


	//Ever used?
	void CellDocument::cursorChangedPosition()
	{
		//       emit cursorChanged();
	}

	/*!
	* \todo Check if ever used. It does seem to be deprecated.(Ingemar Axelsson)
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

	/*! 
	 * \author Anders Fernström
	 * \date 2006-04-18
	 *
	 * \brief Help function for selection handling
	 */
	void CellDocument::addSelectedCell( Cell* cell )
	{
		if( cell )
		{
			cell->setSelected( true );
			selectedCells_.push_back( cell );
		}
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-04-18
	 *
	 * \brief Help function for selection handling
	 */
	void CellDocument::removeSelectedCell( Cell* cell )
	{
		if( cell )
		{
			vector<Cell*>::iterator found = std::find( selectedCells_.begin(),
				selectedCells_.end(), cell );

			if( found != selectedCells_.end() )
			{
				(*found)->setSelected( false );
				selectedCells_.erase( found );
			}
		}
	}

	void CellDocument::clearSelection()
	{      
		vector<Cell*>::iterator i = selectedCells_.begin();

		for(;i!= selectedCells_.end();++i)
			(*i)->setSelected(false);
		
		selectedCells_.clear();
	}

	// 2006-04-18 AF, Reimplemented the function. Also added support
	// for selecting several cells by holding SHIFT down
	void CellDocument::selectedACell( Cell *selected, Qt::KeyboardModifiers state )
	{
		if( selected )
		{
			// if SHIFT is pressed, select all cells from last cell
			if( state == Qt::ShiftModifier && 
				selected->isSelected() &&
				selectedCells_.size() > 0 )
			{
				// if last selected cell and this selected cell aren't
				// int the same groupcell this funciton can't be used.
				Cell *lastCell = selectedCells_[ selectedCells_.size() - 1 ];
				if( selected->parentCell() == lastCell->parentCell() )
				{
					// check which cell is first in list
					int count(0);
					int cellCount(0);
					int lastCellCound(0);

					Cell *current = selected->next();
					while( current )
					{
						// don't count cursor
						if( typeid(CellCursor) != typeid(*current) )
							++cellCount;

						current = current->next();
					}

					current = lastCell->next();
					while( current )
					{
						// don't count cursor
						if( typeid(CellCursor) != typeid(*current) )
							++lastCellCound;

						current = current->next();
					}

					// LASTCELL, last in list
					if( cellCount > lastCellCound )
					{
						count = ( cellCount - lastCellCound ) + 1; // also add last cell
						removeSelectedCell( lastCell );

						current = selected;
						for( int i = 0; i < count; ++i )
						{
							// don't add cursor
							if( typeid(CellCursor) != typeid(*current) )
								addSelectedCell( current );
							else
								++count;

							current = current->next();
						}
					}
					// LASTCELL, first in list
					else
					{
						count = ( lastCellCound - cellCount );

						current = lastCell->next();
						for( int i = 0; i < count; ++i )
						{
							// don't add cursor
							if( typeid(CellCursor) != typeid(*current) )
								addSelectedCell( current );
							else
								++count;

							current = current->next();
						}
					}
				}
				else
				{
					selected->setSelected( false );
					return;
				}
			}
			// if CTRL is pressed, keep existing selections
			else if( state == Qt::ControlModifier )
			{
				if( selected->isSelected() )
					addSelectedCell( selected );
				else
					removeSelectedCell( selected );
			}
			else
			{
				bool flag = ( selectedCells_.size() > 1 );
				clearSelection();

				if( flag || selected->isSelected() )
					addSelectedCell( selected );
				else
					removeSelectedCell( selected );
			}

			// move cell cursor to cell
			cursorMoveAfter( selected, false );
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

	

	void CellDocument::showHTML(bool b)
	{
		getCursor()->currentCell()->viewExpression(b);
	}
};
