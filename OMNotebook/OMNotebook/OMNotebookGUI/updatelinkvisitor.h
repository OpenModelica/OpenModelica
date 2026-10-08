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
 * \file updatelinkvisitor.h
 * \author Anders Fernström
 */

#ifndef UPDATELINKVISITOR_H
#define UPDATELINKVISITOR_H

// Qt headers
#include <QDir>

// IAEX headers
#include "visitor.h"
#include "document.h"


namespace IAEX
{
  class UpdateLinkVisitor : public Visitor
  {

  public:
    UpdateLinkVisitor(QString oldFilepath, QString newFilepath);
    virtual ~UpdateLinkVisitor();

    virtual void visitCellNodeBefore(Cell *node) override;
    virtual void visitCellNodeAfter(Cell *node) override;

    virtual void visitCellGroupNodeBefore(CellGroup *node) override;
    virtual void visitCellGroupNodeAfter(CellGroup *node) override;

    virtual void visitTextCellNodeBefore(TextCell *node) override;
    virtual void visitTextCellNodeAfter(TextCell *node) override;

    virtual void visitInputCellNodeBefore(InputCell *node) override;
    virtual void visitInputCellNodeAfter(InputCell *node) override;

    virtual void visitGraphCellNodeBefore(GraphCell *node) override;
    virtual void visitGraphCellNodeAfter(GraphCell *node) override;

    virtual void visitLatexCellNodeBefore(LatexCell *node) override;
    virtual void visitLatexCellNodeAfter(LatexCell *node) override;

    virtual void visitCellCursorNodeBefore(CellCursor *cursor) override;
    virtual void visitCellCursorNodeAfter(CellCursor *cursor) override;

  private:
    QDir oldDir_;
    QDir newDir_;
  };
}
#endif
