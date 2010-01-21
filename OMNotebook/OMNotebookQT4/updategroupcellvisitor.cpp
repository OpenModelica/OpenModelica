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
 * \file updategroupcellvisitor.cpp
 * \author Anders Fernström
 */

//IAEX Headers
#include "updategroupcellvisitor.h"
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


	//CELLCURSOR
	void UpdateGroupcellVisitor::visitCellCursorNodeBefore(CellCursor *)
	{}

	void UpdateGroupcellVisitor::visitCellCursorNodeAfter(CellCursor *)
	{}
}
