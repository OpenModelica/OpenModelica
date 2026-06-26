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
 * \file removehighlightervisitor.h
 * \author Anders Fernström
 */

#ifndef REMOVEHIGHLIGHTERVISITOR_H
#define REMOVEHIGHLIGHTERVISITOR_H

//IAEX Headers
#include "visitor.h"
#include "document.h"
#include "cellgroup.h"
#include "textcell.h"
#include "inputcell.h"
#include "cellcursor.h"
#include "graphcell.h"

namespace IAEX
{
  class RemoveHighlighterVisitor : public Visitor
  {

  public:
    RemoveHighlighterVisitor(){}
    virtual ~RemoveHighlighterVisitor(){}

    virtual void visitCellNodeBefore(Cell *) override {}
    virtual void visitCellNodeAfter(Cell *) override {}

    virtual void visitCellGroupNodeBefore(CellGroup *) override {}
    virtual void visitCellGroupNodeAfter(CellGroup *) override {}

    virtual void visitTextCellNodeBefore(TextCell *) override {}
    virtual void visitTextCellNodeAfter(TextCell *) override {}

    virtual void visitInputCellNodeBefore(InputCell *) override {}
    virtual void visitInputCellNodeAfter(InputCell *) override {}

    virtual void visitGraphCellNodeBefore(GraphCell *) override {}
    virtual void visitGraphCellNodeAfter(GraphCell *) override {}


    virtual void visitLatexCellNodeBefore(LatexCell *) override {}
    virtual void visitLatexCellNodeAfter(LatexCell *) override {}


    virtual void visitCellCursorNodeBefore(CellCursor *) override {}
    virtual void visitCellCursorNodeAfter(CellCursor *) override {}
  };
}
#endif
