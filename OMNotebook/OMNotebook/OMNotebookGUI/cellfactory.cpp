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
* \file cellfactory.cpp
* \author Ingemar Axelsson (and Anders Fernström)
* \date 2005-10-28 (update)
*/


//QT Headers
#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#else
#include <QtCore/QObject>
#include <QtGui/QMessageBox>
#endif

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
#include "latexcell.h"
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
          throw runtime_error("No Input style defined, the inputcell may not work correctly, please define an Input style in stylesheet.xml");
      }
      catch( exception e )
      {
        QMessageBox::warning( 0, QObject::tr("Warning"), e.what(), "OK" );
      }

      try
      {
        text->setDelegate(OmcInteractiveEnvironment::getInstance());
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

      //      CellDocument* d = dynamic_cast<CellDocument*>(doc_);
      //      DocumentView* d2 = d->observers_[0];
      //      NotebookWindow *d3 = dynamic_cast<NotebookWindow*>(d2);
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

    else if (style == "Latex")
    {
      LatexCell *text = new LatexCell(doc_, parent);

      try
      {
        Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" );
        CellStyle cstyle = sheet->getStyle( "Latex" );

        if( cstyle.name() != "null" )

          text->setStyle( cstyle );
        else
          throw runtime_error("No Input style defined, the inputcell may not work correctly, please define an Input style in stylesheet.xml");
      }
      catch( exception e )
      {

        QMessageBox::warning( 0, QObject::tr("Warning"), e.what(), "OK" );
      }

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
      QObject::connect(text->output_, SIGNAL(undoAvailable(bool)), doc_, SIGNAL(undoAvailable(bool)));
      QObject::connect(text->output_, SIGNAL(redoAvailable(bool)), doc_, SIGNAL(redoAvailable(bool)));

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
          throw runtime_error("No Input style defined, the inputcell may not work correctly, please define an Input style in stylesheet.xml");
      }
      catch( exception e )
      {
        QMessageBox::warning( 0, QObject::tr("Warning"), e.what(), "OK" );
      }

      try
      {
        text->setDelegate(OmcInteractiveEnvironment::getInstance());
      }
      catch( exception e )
      {
        e.what();
      }

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

      //      if(CellDocument* d = dynamic_cast<CellDocument*>(doc_))
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
      if(style_.isNull())
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
      //      QObject::connect(text->output_, SIGNAL(copyAvailable(bool)), this, SLOT(copyAvailable(bool)));
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
