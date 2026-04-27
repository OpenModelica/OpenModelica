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
 * \file chaptercountervisitor.cpp
 * \author Anders Fernström
 */

//STD Headers
#include <exception>

//IAEX Headers
#include "chaptercountervisitor.h"
#include "cellgroup.h"
#include "textcell.h"
#include "latexcell.h"
#include "inputcell.h"
#include "cellcursor.h"
#include "graphcell.h"


namespace IAEX
{
  /*!
   * \class ChapterCounterVisitor
   * \date 2006-03-02
   *
   * \brief Update the chapter counters in the document
   */

  /*!
   * \author Anders Fernström
   *
   * \brief The class constructor
   */
  ChapterCounterVisitor::ChapterCounterVisitor()
  {
    for( int i = 0; i < COUNTERS; ++i )
      counters_[i] = 0;
  }

  /*!
   * \author Anders Fernström
   *
   * \brief The class deconstructor
   */
  ChapterCounterVisitor::~ChapterCounterVisitor()
  {}

  // CELL
  void ChapterCounterVisitor::visitCellNodeBefore(Cell *)
  {}

  void ChapterCounterVisitor::visitCellNodeAfter(Cell *)
  {}

  // GROUPCELL
  void ChapterCounterVisitor::visitCellGroupNodeBefore(CellGroup *node)
  {}

  void ChapterCounterVisitor::visitCellGroupNodeAfter(CellGroup *)
  {}

  // TEXTCELL
  void ChapterCounterVisitor::visitTextCellNodeBefore(TextCell *node)
  {
    int level = node->style()->chapterLevel();
    if( level > 0 && level <= COUNTERS )
    {
      // Add on chapter couner
      counters_[ level - 1 ]++;

      QString counter;
      QString number;
      for( int i = 0; i < level; ++i )
      {
        number.setNum( counters_[i] );

        if( !counter.isEmpty() )
          counter += ".";

        counter += number;
      }

      // reset all counters avter counter[level]
      for( int i = level; i < COUNTERS; ++i )
        counters_[i] = 0;

      node->setChapterCounter( counter );
    }
    else
    {
      // clear chapter counter
      node->setChapterCounter( "" );
    }
  }

  void ChapterCounterVisitor::visitTextCellNodeAfter(TextCell *)
  {}

  //INPUTCELL
  void ChapterCounterVisitor::visitInputCellNodeBefore(InputCell *node)
  {
    int level = node->style()->chapterLevel();
    if( level > 0 && level <= COUNTERS )
    {
      // Add on chapter couner
      counters_[ level - 1 ]++;

      QString counter;
      QString number;
      for( int i = 0; i < level; ++i )
      {
        number.setNum( counters_[i] );

        if( !counter.isEmpty() )
          counter += ".";

        counter += number;
      }

      // reset all counters avter counter[level]
      for( int i = level; i < COUNTERS; ++i )
        counters_[i] = 0;

      node->setChapterCounter( counter );
    }
    else
    {
      // clear chapter counter
      node->setChapterCounter( "" );
    }
  }

  void ChapterCounterVisitor::visitInputCellNodeAfter(InputCell *)
  {}


  //GRAPHCELL

  void ChapterCounterVisitor::visitGraphCellNodeBefore(GraphCell *node)
  {
    int level = node->style()->chapterLevel();
    if( level > 0 && level <= COUNTERS )
    {
      // Add on chapter couner
      counters_[ level - 1 ]++;

      QString counter;
      QString number;
      for( int i = 0; i < level; ++i )
      {
        number.setNum( counters_[i] );

        if( !counter.isEmpty() )
          counter += ".";

        counter += number;
      }

      // reset all counters avter counter[level]
      for( int i = level; i < COUNTERS; ++i )
        counters_[i] = 0;

      node->setChapterCounter( counter );
    }
    else
    {
      // clear chapter counter
      node->setChapterCounter( "" );
    }
  }

  void ChapterCounterVisitor::visitGraphCellNodeAfter(GraphCell *)
  {}

  // LATEXCELL
  void ChapterCounterVisitor::visitLatexCellNodeBefore(LatexCell *node)
  {
    int level = node->style()->chapterLevel();
    if( level > 0 && level <= COUNTERS )
    {
      // Add on chapter couner
      counters_[ level - 1 ]++;

      QString counter;
      QString number;
      for( int i = 0; i < level; ++i )
      {
        number.setNum( counters_[i] );

        if( !counter.isEmpty() )
          counter += ".";

        counter += number;
      }

      // reset all counters avter counter[level]
      for( int i = level; i < COUNTERS; ++i )
        counters_[i] = 0;

      node->setChapterCounter( counter );
    }
    else
    {
      // clear chapter counter
      node->setChapterCounter( "" );
    }
  }

  void ChapterCounterVisitor::visitLatexCellNodeAfter(LatexCell *)
  {}

  //CELLCURSOR
  void ChapterCounterVisitor::visitCellCursorNodeBefore(CellCursor *)
  {}

  void ChapterCounterVisitor::visitCellCursorNodeAfter(CellCursor *)
  {}
}
