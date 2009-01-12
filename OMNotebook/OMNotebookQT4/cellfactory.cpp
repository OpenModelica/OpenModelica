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
* \file cellfactory.cpp
* \author Ingemar Axelsson (and Anders Fernström)
* \date 2005-10-28 (update)
*/


//QT Headers
#include <QtCore/QObject>
#include <QtGui/QMessageBox>

#include <exception>
#include <stdexcept>

//IAEX Headers
#include "cellfactory.h"
#include "textcell.h"
#include "inputcell.h"
#include "cellgroup.h"
#include "cellcursor.h"
#include "stylesheet.h"
#include "celldocument.h"
#include "notebook.h"

#include <string>
#include "graphcell.h"
#include "omcinteractiveenvironment.h"
using namespace std;

namespace IAEX
{
  /*!
  * \author Ingemar Axelsson
  *
  * \brief The class constructor
  */
  CellFactory::CellFactory(Document *doc)
    : doc_(doc)
  {
  }

  /*!
  * \author Ingemar Axelsson
  *
  * \brief The class destructor
  */
  CellFactory::~CellFactory()
  {
  }

  /*!
  * \author Ingemar Axelsson and Anders Fernström
  *
  *
  * \todo Remove document dependency from Cellstructure. It is only
  * used to point to a commandcenter (in this case the current
  * document) and for the click event to get the current
  * cursor. This can be done in some better way. Maybe by sending a
  * signal to the document instead.(Ingemar Axelsson)
  */
  Cell *CellFactory::createCell(const QString &style, Cell *parent)
  {
    if(style == "input" || style == "Input" || style == "ModelicaInput")
    {
      InputCell *text = new InputCell(doc_, parent);

      try
      {
        Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" );
        CellStyle cstyle = sheet->getStyle( "Input" );

        if( cstyle.name() != "null" )
          text->setStyle( cstyle );
        else
          throw runtime_error("No Input style defened, the inputcell may not work correctly, please define a Input style in stylesheet.xml");
      }
      catch( exception e )
      {
        QMessageBox::warning( 0, "Warning", e.what(), "OK" );
      }

      try
      {
        text->setDelegate(new OmcInteractiveEnvironment());
      }
      catch( exception e )
      {}

      QObject::connect(text, SIGNAL(cellselected(Cell *,Qt::KeyboardModifiers)),
        doc_, SLOT(selectedACell(Cell*,Qt::KeyboardModifiers)));
      QObject::connect(text, SIGNAL(clicked(Cell *)),
        doc_, SLOT(mouseClickedOnCell(Cell*)));
      QObject::connect(text, SIGNAL(clickedOutput(Cell *)),
        doc_, SLOT(mouseClickedOnCellOutput(Cell*)));

      // 2005-11-29 AF
      QObject::connect( text, SIGNAL( heightChanged() ),
        doc_, SLOT( updateScrollArea() ));

      // 2006-01-17 AF
      QObject::connect( text, SIGNAL( textChanged(bool) ),
        doc_, SLOT( setChanged(bool) ));

      // 2006-04-27 AF
      QObject::connect( text, SIGNAL( forwardAction(int) ),
        doc_, SIGNAL( forwardAction(int) ));

      //			CellDocument* d = dynamic_cast<CellDocument*>(doc_);
      //			DocumentView* d2 = d->observers_[0];
      //			NotebookWindow *d3 = dynamic_cast<NotebookWindow*>(d2);
      QObject::connect(text->input_, SIGNAL(copyAvailable(bool)), doc_, SIGNAL(copyAvailable(bool)));
      QObject::connect(text->input_, SIGNAL(undoAvailable(bool)), doc_, SIGNAL(undoAvailable(bool)));
      QObject::connect(text->input_, SIGNAL(redoAvailable(bool)), doc_, SIGNAL(redoAvailable(bool)));
      QObject::connect(text->output_, SIGNAL(copyAvailable(bool)), doc_, SIGNAL(copyAvailable(bool)));

      //QObject::connect(doc_, SIGNAL(evaluate()), text->input_, SIGNAL(eval()));

      /*
      QObject::connect(text->input_, SIGNAL(copyAvailable(bool)), d3->copyAction, SLOT(setEnabled(bool)));
      QObject::connect(text->input_, SIGNAL(copyAvailable(bool)), d3->cutAction, SLOT(setEnabled(bool)));
      QObject::connect(text->input_, SIGNAL(undoAvailable(bool)), d3->undoAction, SLOT(setEnabled(bool)));
      QObject::connect(text->input_, SIGNAL(redoAvailable(bool)), d3->redoAction, SLOT(setEnabled(bool)));

      QObject::connect(text->output_, SIGNAL(copyAvailable(bool)), d3->copyAction, SLOT(setEnabled(bool)));
      */
      return text;
    }
    else if( style == "cursor")
    {
      return new CellCursor(parent);
    }
    else if(style == "cellgroup")
    {
      Cell *text = new CellGroup(parent);

      QObject::connect(text, SIGNAL(cellOpened(Cell *, const bool)),
        doc_, SLOT(cursorMoveAfter(Cell*, const bool)));
      QObject::connect(text, SIGNAL(cellselected(Cell *, Qt::KeyboardModifiers)),
        doc_, SLOT(selectedACell(Cell*, Qt::KeyboardModifiers)));
      QObject::connect(text, SIGNAL(clicked(Cell *)),
        doc_, SLOT(mouseClickedOnCell(Cell*)));
      QObject::connect(text, SIGNAL(openLink(const QUrl*)),
        doc_, SLOT(linkClicked(const QUrl*)));

      return text;
    }
    else if (style == "Graph")
    {
      GraphCell *text = new GraphCell(doc_, parent);
      try
      {
        Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" );
        CellStyle cstyle = sheet->getStyle( "Input" );

        if( cstyle.name() != "null" )
          text->setStyle( cstyle );
        else
          throw runtime_error("No Input style defened, the inputcell may not work correctly, please define a Input style in stylesheet.xml");
      }
      catch( exception e )
      {
        QMessageBox::warning( 0, "Warrning", e.what(), "OK" );
      }

      try
      {
        text->setDelegate(new OmcInteractiveEnvironment());
      }
      catch( exception e )
      {}

      QObject::connect(text, SIGNAL(cellselected(Cell *,Qt::KeyboardModifiers)),
        doc_, SLOT(selectedACell(Cell*,Qt::KeyboardModifiers)));
      QObject::connect(text, SIGNAL(clicked(Cell *)),
        doc_, SLOT(mouseClickedOnCell(Cell*)));
      QObject::connect(text, SIGNAL(clickedOutput(Cell *)),
        doc_, SLOT(mouseClickedOnCellOutput(Cell*)));

      // 2005-11-29 AF
      QObject::connect( text, SIGNAL( heightChanged() ),
        doc_, SLOT( updateScrollArea() ));

      // 2006-01-17 AF
      QObject::connect( text, SIGNAL( textChanged(bool) ),
        doc_, SLOT( setChanged(bool) ));

      // 2006-04-27 AF
      QObject::connect( text, SIGNAL( forwardAction(int) ),
        doc_, SIGNAL( forwardAction(int) ));


      QObject::connect( text, SIGNAL( updatePos(int, int)), doc_, SIGNAL(updatePos(int, int)));
      QObject::connect( text, SIGNAL( newState(QString)), doc_, SIGNAL(newState(QString)));
      QObject::connect(text, SIGNAL( setStatusMenu(QList<QAction*>)), doc_, SIGNAL(setStatusMenu(QList<QAction*>)));


      QObject::connect(text->input_, SIGNAL(copyAvailable(bool)), doc_, SIGNAL(copyAvailable(bool)));
      QObject::connect(text->input_, SIGNAL(undoAvailable(bool)), doc_, SIGNAL(undoAvailable(bool)));
      QObject::connect(text->input_, SIGNAL(redoAvailable(bool)), doc_, SIGNAL(redoAvailable(bool)));
      QObject::connect(text->output_, SIGNAL(copyAvailable(bool)), doc_, SIGNAL(copyAvailable(bool)));

      //			if(CellDocument* d = dynamic_cast<CellDocument*>(doc_))
      QObject::connect(doc_, SIGNAL(setAutoIndent(bool)), text->input_, SLOT(setAutoIndent(bool)));
      //QObject::connect(doc_, SIGNAL(evaluate()), text->input_, SIGNAL(eval()));
      text->input_->setAutoIndent(dynamic_cast<CellDocument*>(doc_)->autoIndent);
      /*
      if(d)
      {
      if(d->observers_.size())
      {


      DocumentView* d2 = d->observers_[0];

      NotebookWindow *d3 = dynamic_cast<NotebookWindow*>(d2);
      QObject::connect(text->input_, SIGNAL(copyAvailable(bool)), d3->copyAction, SLOT(setEnabled(bool)));
      QObject::connect(text->input_, SIGNAL(copyAvailable(bool)), d3->cutAction, SLOT(setEnabled(bool)));
      QObject::connect(text->input_, SIGNAL(undoAvailable(bool)), d3->undoAction, SLOT(setEnabled(bool)));
      QObject::connect(text->input_, SIGNAL(redoAvailable(bool)), d3->redoAction, SLOT(setEnabled(bool)));

      QObject::connect(text->output_, SIGNAL(copyAvailable(bool)), d3->copyAction, SLOT(setEnabled(bool)));
      }
      }
      */
      return text;
    }
    else //All other styles will be implemented with a TextCell.
    {
      TextCell *text = new TextCell(parent);

      // set correct cell style
      QString style_ = style;
      if(style_ == QString::null)
        style_ = QString("Text");

      text->setStyle( style_ );



      QObject::connect(text, SIGNAL(cellselected(Cell *, Qt::KeyboardModifiers)),
        doc_, SLOT(selectedACell(Cell*, Qt::KeyboardModifiers)));
      QObject::connect(text, SIGNAL(clicked(Cell *)),
        doc_, SLOT(mouseClickedOnCell(Cell*)));
      QObject::connect(text, SIGNAL(openLink(const QUrl*)),
        doc_, SLOT(linkClicked(const QUrl*)));

      // 2005-11-29 AF
      QObject::connect( text, SIGNAL( heightChanged() ),
        doc_, SLOT( updateScrollArea() ));

      // 2006-01-17 AF
      QObject::connect( text, SIGNAL( textChanged(bool) ),
        doc_, SLOT( setChanged(bool) ));

      // 2006-02-10 AF
      QObject::connect( text, SIGNAL( hoverOverUrl(const QUrl &) ),
        doc_, SLOT( hoverOverUrl(const QUrl &) ));

      // 2006-04-27 AF
      QObject::connect( text, SIGNAL( forwardAction(int) ),
        doc_, SIGNAL( forwardAction(int) ));

      QObject::connect(text->text_, SIGNAL(copyAvailable(bool)), doc_, SIGNAL(copyAvailable(bool)));
      QObject::connect(text->text_, SIGNAL(undoAvailable(bool)), doc_, SIGNAL(undoAvailable(bool)));
      QObject::connect(text->text_, SIGNAL(redoAvailable(bool)), doc_, SIGNAL(redoAvailable(bool)));
      //			QObject::connect(text->output_, SIGNAL(copyAvailable(bool)), this, SLOT(copyAvailable(bool)));
      /*

      CellDocument* d = dynamic_cast<CellDocument*>(doc_);
      DocumentView* d2 = d->observers_[0];
      NotebookWindow *d3 = dynamic_cast<NotebookWindow*>(d2);
      QObject::connect(text->text_, SIGNAL(copyAvailable(bool)), d3->copyAction, SLOT(setEnabled(bool)));
      QObject::connect(text->text_, SIGNAL(copyAvailable(bool)), d3->cutAction, SLOT(setEnabled(bool)));
      QObject::connect(text->text_, SIGNAL(undoAvailable(bool)), d3->undoAction, SLOT(setEnabled(bool)));
      QObject::connect(text->text_, SIGNAL(redoAvailable(bool)), d3->redoAction, SLOT(setEnabled(bool)));
      */
      return text;
    }
  }
}
