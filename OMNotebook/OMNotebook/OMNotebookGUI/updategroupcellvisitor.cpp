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
 * \file updategroupcellvisitor.cpp
 * \author Anders Fernström
 */

//IAEX Headers
#include "updategroupcellvisitor.h"
#include "latexcell.h"
#include "cellgroup.h"
#include "textcell.h"
#include "inputcell.h"
#include "cellcursor.h"


namespace IAEX
{
  /*!
   * \class UpdateGroupcellVisitor
   * \date 2005-11-30
   *
   * \brief call funciton 'closeChildCells()' in every GroupCell
   */

  /*!
   * \author Anders Fernström
   *
   * \brief The class constructor
   */
  UpdateGroupcellVisitor::UpdateGroupcellVisitor()
  {}

  /*!
   * \author Anders Fernström
   *
   * \brief The class deconstructor
   */
  UpdateGroupcellVisitor::~UpdateGroupcellVisitor()
  {}

  // CELL
  void UpdateGroupcellVisitor::visitCellNodeBefore(Cell *)
  {}

  void UpdateGroupcellVisitor::visitCellNodeAfter(Cell *)
  {}

  // GROUPCELL
  void UpdateGroupcellVisitor::visitCellGroupNodeBefore(CellGroup *node)
  {
    node->closeChildCells();
  }

  void UpdateGroupcellVisitor::visitCellGroupNodeAfter(CellGroup *)
  {}

  // TEXTCELL
  void UpdateGroupcellVisitor::visitTextCellNodeBefore(TextCell *node)
  {}

  void UpdateGroupcellVisitor::visitTextCellNodeAfter(TextCell *)
  {}

  //INPUTCELL
  void UpdateGroupcellVisitor::visitInputCellNodeBefore(InputCell *node)
  {}

  void UpdateGroupcellVisitor::visitInputCellNodeAfter(InputCell *)
  {}


  //GRAPHCELL

  void UpdateGroupcellVisitor::visitGraphCellNodeBefore(GraphCell *node)
  {}

  void UpdateGroupcellVisitor::visitGraphCellNodeAfter(GraphCell *)
  {}

  //LATEXCELL

  void UpdateGroupcellVisitor::visitLatexCellNodeBefore(LatexCell *node)
  {}

  void UpdateGroupcellVisitor::visitLatexCellNodeAfter(LatexCell *)
  {}


  //CELLCURSOR
  void UpdateGroupcellVisitor::visitCellCursorNodeBefore(CellCursor *)
  {}

  void UpdateGroupcellVisitor::visitCellCursorNodeAfter(CellCursor *)
  {}
}
