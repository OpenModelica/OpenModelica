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
 * \file searchform.h
 * \author Anders Fernström
 * \date 2006-08-24
 */

#ifndef SEARCHFORM_H
#define SEARCHFORM_H


// Form files
#include "ui_searchform.h"


namespace IAEX
{
  // forward declaration
  class Document;
  class Cell;

  class SearchForm : public QDialog
  {
    Q_OBJECT

  public:
    SearchForm(QWidget* parent, Document* document, bool viewReplace = false);
    ~SearchForm();

    void setDocument( Document* document );

  private slots:
    void search();
    void replace();
    void replaceAll();
    void showHideReplace();
    void closeForm();

  private:
    void showOrHideReplace();

  private:
    Ui::SearchFormClass ui;

    QString searchText_;
    QList<Cell*> openedCells_;

    Document* document_;
    bool viewReplace_;
    bool matchCase_;
    bool matchWord_;
  };
}
#endif // SEARCHFORM_H
