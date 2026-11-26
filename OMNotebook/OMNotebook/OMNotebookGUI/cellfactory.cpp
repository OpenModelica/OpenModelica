/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*!
* \file cellfactory.cpp
* \author Ingemar Axelsson (and Anders Fernström)
* \date 2005-10-28 (update)
*/


//QT Headers
#include <QtGlobal>
#include <QtWidgets>

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
    CellDocument *pCellDocument = static_cast<CellDocument*>(doc_);
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
          throw std::runtime_error("No Input style defined, the inputcell may not work correctly, please define an Input style in stylesheet.xml");
      }
      catch( const std::exception &e )
      {
        QMessageBox::warning(nullptr, QObject::tr("Warning"), e.what());
      }

      try
      {
        text->setDelegate(OmcInteractiveEnvironment::getInstance());
      }
      catch( const std::exception &e )
      {}

      QObject::connect(text, &InputCell::cellselected,
        pCellDocument, &CellDocument::selectedACell);
      QObject::connect(text, &InputCell::clicked,
        pCellDocument, &CellDocument::mouseClickedOnCell);
      QObject::connect(text, &InputCell::clickedOutput,
        pCellDocument, &CellDocument::mouseClickedOnCellOutput);

      // 2005-11-29 AF
      QObject::connect(text, &InputCell::heightChanged,
        pCellDocument, &CellDocument::updateScrollArea);

      // 2006-01-17 AF
      QObject::connect(text, QOverload<bool>::of(&InputCell::textChanged),
        pCellDocument, &CellDocument::setChanged);

      // 2006-04-27 AF
      QObject::connect(text, &InputCell::forwardAction,
        pCellDocument, &CellDocument::forwardAction);

      QObject::connect(text->input_, &QTextBrowser::copyAvailable, pCellDocument, &CellDocument::copyAvailable);
      QObject::connect(text->input_, &QTextBrowser::undoAvailable, pCellDocument, &CellDocument::undoAvailable);
      QObject::connect(text->input_, &QTextBrowser::redoAvailable, pCellDocument, &CellDocument::redoAvailable);
      QObject::connect(text->output_, &QTextBrowser::copyAvailable, pCellDocument, &CellDocument::copyAvailable);

      return text;
    }
    else if( style == "cursor")
    {
      return new CellCursor(parent);
    }
    else if(style == "cellgroup")
    {
      Cell *text = new CellGroup(parent);

      QObject::connect(text, &Cell::cellOpened,
        pCellDocument, &CellDocument::cursorMoveAfter);
      QObject::connect(text, &Cell::cellselected,
        pCellDocument, &CellDocument::selectedACell);
      QObject::connect(text, &Cell::clicked,
        pCellDocument, &CellDocument::mouseClickedOnCell);
      QObject::connect(text, &Cell::openLink,
        pCellDocument, &CellDocument::linkClicked);

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
          throw std::runtime_error("No Input style defined, the inputcell may not work correctly, please define an Input style in stylesheet.xml");
      }
      catch( const std::exception &e )
      {
        QMessageBox::warning(nullptr, QObject::tr("Warning"), e.what());
      }

      QObject::connect(text, &LatexCell::cellselected,
        pCellDocument, &CellDocument::selectedACell);
      QObject::connect(text, &LatexCell::clicked,
        pCellDocument, &CellDocument::mouseClickedOnCell);
      QObject::connect(text, &LatexCell::clickedOutput,
        pCellDocument, &CellDocument::mouseClickedOnCellOutput);

      // 2005-11-29 AF
      QObject::connect(text, &LatexCell::heightChanged,
        pCellDocument, &CellDocument::updateScrollArea);

      // 2006-01-17 AF
      QObject::connect(text, QOverload<bool>::of(&LatexCell::textChanged),
        pCellDocument, &CellDocument::setChanged);

      // 2006-04-27 AF
      QObject::connect(text, &LatexCell::forwardAction,
        pCellDocument, &CellDocument::forwardAction);


      QObject::connect(text, &LatexCell::updatePos, pCellDocument, &CellDocument::updatePos);
      QObject::connect(text, &LatexCell::newState, pCellDocument, &CellDocument::newState);
      QObject::connect(text, &LatexCell::setStatusMenu, pCellDocument, &CellDocument::setStatusMenu);


      QObject::connect(text->input_, &MyTextEdit3::copyAvailable, pCellDocument, &CellDocument::copyAvailable);
      QObject::connect(text->input_, &MyTextEdit3::undoAvailable, pCellDocument, &CellDocument::undoAvailable);
      QObject::connect(text->input_, &MyTextEdit3::redoAvailable, pCellDocument, &CellDocument::redoAvailable);
      QObject::connect(text->output_, &MyTextEdit3::copyAvailable, pCellDocument, &CellDocument::copyAvailable);
      QObject::connect(text->output_, &MyTextEdit3::undoAvailable, pCellDocument, &CellDocument::undoAvailable);
      QObject::connect(text->output_, &MyTextEdit3::redoAvailable, pCellDocument, &CellDocument::redoAvailable);

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
          throw std::runtime_error("No Input style defined, the inputcell may not work correctly, please define an Input style in stylesheet.xml");
      }
      catch( const std::exception &e )
      {
        QMessageBox::warning(nullptr, QObject::tr("Warning"), e.what());
      }

      text->setDelegate(OmcInteractiveEnvironment::getInstance());

      QObject::connect(text, &GraphCell::cellselected,
        pCellDocument, &CellDocument::selectedACell);
      QObject::connect(text, &GraphCell::clicked,
        pCellDocument, &CellDocument::mouseClickedOnCell);
      QObject::connect(text, &GraphCell::clickedOutput,
        pCellDocument, &CellDocument::mouseClickedOnCellOutput);

      // 2005-11-29 AF
      QObject::connect(text, &GraphCell::heightChanged,
        pCellDocument, &CellDocument::updateScrollArea);

      // 2006-01-17 AF
      QObject::connect(text, QOverload<bool>::of(&GraphCell::textChanged),
        pCellDocument, &CellDocument::setChanged);

      // 2006-04-27 AF
      QObject::connect(text, &GraphCell::forwardAction,
        pCellDocument, &CellDocument::forwardAction);


      QObject::connect(text, &GraphCell::updatePos, pCellDocument, &CellDocument::updatePos);
      QObject::connect(text, &GraphCell::newState, pCellDocument, &CellDocument::newState);
      QObject::connect(text, &GraphCell::setStatusMenu, pCellDocument, &CellDocument::setStatusMenu);


      QObject::connect(text->input_, &MyTextEdit2a::copyAvailable, pCellDocument, &CellDocument::copyAvailable);
      QObject::connect(text->input_, &MyTextEdit2a::undoAvailable, pCellDocument, &CellDocument::undoAvailable);
      QObject::connect(text->input_, &MyTextEdit2a::redoAvailable, pCellDocument, &CellDocument::redoAvailable);
      QObject::connect(text->output_, &QTextBrowser::copyAvailable, pCellDocument, &CellDocument::copyAvailable);

      QObject::connect(pCellDocument, &CellDocument::setAutoIndent, text->input_, &MyTextEdit2a::setAutoIndent);
      text->input_->setAutoIndent(dynamic_cast<CellDocument*>(doc_)->autoIndent);
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



      QObject::connect(text, &TextCell::cellselected,
        pCellDocument, &CellDocument::selectedACell);
      QObject::connect(text, &TextCell::clicked,
        pCellDocument, &CellDocument::mouseClickedOnCell);
      QObject::connect(text, &TextCell::openLink,
        pCellDocument, &CellDocument::linkClicked);

      // 2005-11-29 AF
      QObject::connect(text, &TextCell::heightChanged,
        pCellDocument, &CellDocument::updateScrollArea);

      // 2006-01-17 AF
      QObject::connect(text, QOverload<bool>::of(&TextCell::textChanged),
        pCellDocument, &CellDocument::setChanged);

      // 2006-02-10 AF
      QObject::connect(text, &TextCell::hoverOverUrl,
        pCellDocument, &CellDocument::hoverOverUrl);

      // 2006-04-27 AF
      QObject::connect(text, &TextCell::forwardAction,
        pCellDocument, &CellDocument::forwardAction);

      QObject::connect(text->text_, &QTextBrowser::copyAvailable, pCellDocument, &CellDocument::copyAvailable);
      QObject::connect(text->text_, &QTextBrowser::undoAvailable, pCellDocument, &CellDocument::undoAvailable);
      QObject::connect(text->text_, &QTextBrowser::redoAvailable, pCellDocument, &CellDocument::redoAvailable);
      return text;
    }
  }
}
