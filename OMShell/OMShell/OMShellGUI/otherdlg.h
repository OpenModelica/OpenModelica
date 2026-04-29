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
 * \file otherdlg.h
 * \author Anders Fernström
 */

#ifndef OTHERDLG_H
#define OTHERDLG_H


#include "ui_OtherDlg.h"


namespace IAEX
{
  /*!
   * \class OtherDlg
   * \author Anders Fernström
   * \date 2005-11-04
   *
   * \breif Class of opening a dialog window for entering av value...
   */
  class OtherDlg : public QDialog
  {
  public:
    OtherDlg( QWidget *parent, int min, int max)
      : QDialog(parent), min_(min), max_(max)
    {
      ui.setupUi(this);

      QString minW;
      QString maxW;
      minW.setNum( min_ );
      maxW.setNum( max_ );

      QString text = QString("Enter value (") + minW +
        QString("-") + maxW + QString(")");

      ui.label->setText( text );
    }
    virtual ~OtherDlg(){}
    int value()
    {
      bool ok;
      int value = ui.lineEdit->text().toInt(&ok);

      if(ok)
        if( min_ <= value && value <= max_ )
          return value;

      return -1;
    }

  private:
    Ui::Dialog ui;
    int min_;
    int max_;
  };
}

#endif
