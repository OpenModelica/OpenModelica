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
 * \file puretextvisitor.h
 * \author Anders Fernström
 */

#ifndef PURETEXTVISITOR_H
#define PURETEXTVISITOR_H

//IAEX Headers
#include "visitor.h"
#include "document.h"

//Forward declaration
class QFile;
class QTextStream;


namespace IAEX
{
  class PureTextVisitor : public Visitor
  {

  public:
    PureTextVisitor(QFile *file);
    virtual ~PureTextVisitor();

    virtual void visitCellNodeBefore(Cell *node);
    virtual void visitCellNodeAfter(Cell *node);

    virtual void visitCellGroupNodeBefore(CellGroup *node);
    virtual void visitCellGroupNodeAfter(CellGroup *node);

    virtual void visitTextCellNodeBefore(TextCell *node);
    virtual void visitTextCellNodeAfter(TextCell *node);

    virtual void visitInputCellNodeBefore(InputCell *node);
    virtual void visitInputCellNodeAfter(InputCell *node);

    virtual void visitGraphCellNodeBefore(GraphCell *node);
    virtual void visitGraphCellNodeAfter(GraphCell *node);

    virtual void visitLatexCellNodeBefore(LatexCell *node);
    virtual void visitLatexCellNodeAfter(LatexCell *node);

    virtual void visitCellCursorNodeBefore(CellCursor *cursor);
    virtual void visitCellCursorNodeAfter(CellCursor *cursor);

  private:
    QTextStream *ts_;
  };
}
#endif
