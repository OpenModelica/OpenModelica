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
 * \file cellgroup.h
 * \author Ingemar Axelsson and Anders Fernström
 *
 */

#ifndef CELLGROUP_H
#define CELLGROUP_H

//STD Headers
#include <vector>
#include <list>

//QT Headers
#include <QtGlobal>
#include <QtWidgets>

//IAEX Headers
#include "cell.h"
#include "visitor.h"

using namespace IAEX;

namespace IAEX{

  class CellGroup : public Cell
  {
    Q_OBJECT

  public:
    CellGroup(QWidget *parent=0);
    virtual ~CellGroup();

    void viewExpression(const bool) override;

    //Traversals implementation
    virtual void accept(Visitor &v) override;

    //Datastructure implementation.
    virtual void addChild(Cell *newCell) override;
    virtual void removeChild(Cell *aCell) override;

    virtual void addCellWidget(Cell *newCell) override;
    virtual void addCellWidgets() override;
    virtual void removeCellWidgets() override;

    int height();
    CellStyle *style() override;
    QString text() override;

    void closeChildCells();

    //Flag
    bool isClosed() const override;
    bool isEditable() override;

    QTextDocument* document() override;
    QTextEdit* textEdit() override;

    void cutText() override;
    void copyText() override;
    void pasteText() override;
    bool findText(const QString &exp, QTextDocument::FindFlags options) override;

    QTextCursor textCursor() override;
    void clearSelection() override;
    void moveCursor(QTextCursor::MoveOperation operation) override;

  public slots:
    virtual void setStyle( CellStyle style ) override;
    void setClosed(const bool closed, bool update = true) override;
    virtual void setFocus(const bool focus) override;

  protected:
    void mouseDoubleClickEvent(QMouseEvent *event) override;

  protected slots:
    void adjustHeight();

  private:
    bool closed_;

    QWidget *main_;
    QGridLayout *layout_;
    unsigned long newIndex_;
  };
}
#endif
