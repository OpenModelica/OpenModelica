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

    virtual void viewExpression(const bool){};

    //Traversals implementation
    virtual void accept(Visitor &v);

    //Datastructure implementation.
    virtual void addChild(Cell *newCell);
    virtual void removeChild(Cell *aCell);

    virtual void addCellWidget(Cell *newCell);
    virtual void addCellWidgets();
    virtual void removeCellWidgets();

    int height();
    CellStyle *style();                // Changed 2005-10-28
    virtual QString text(){return QString();}

    void closeChildCells();              // Added 2005-11-30 AF

    //Flag
    bool isClosed() const;
    bool isEditable();                // Added 2005-10-28 AF

    QTextEdit* textEdit();              // Added 2006-08-24 AF


  public slots:
    virtual void setStyle( CellStyle style );    // Changed 2005-10-28 AF
    void setClosed(const bool closed, bool update = true);
    virtual void setFocus(const bool focus);

  protected:
    void mouseDoubleClickEvent(QMouseEvent *event);

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
