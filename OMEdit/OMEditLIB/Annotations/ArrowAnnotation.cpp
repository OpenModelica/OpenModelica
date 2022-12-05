/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */
#include "ArrowAnnotation.h"

ArrowAnnotation::ArrowAnnotation()
{
  clear();
}

void ArrowAnnotation::clear()
{
  mValue.replace(0, StringHandler::ArrowNone);
  mValue.replace(1, StringHandler::ArrowNone);
}

ArrowAnnotation& ArrowAnnotation::operator= (const QVector<StringHandler::Arrow> &value)
{
  mValue = value;
  setExp();
  return *this;
}

FlatModelica::Expression ArrowAnnotation::toExp() const
{
  std::vector<FlatModelica::Expression> elems;
  elems.emplace_back(FlatModelica::Expression(StringHandler::getArrowString(mValue.at(0)).toStdString(), mValue.at(0)));
  elems.emplace_back(FlatModelica::Expression(StringHandler::getArrowString(mValue.at(1)).toStdString(), mValue.at(1)));
  return FlatModelica::Expression(std::move(elems));
}

void ArrowAnnotation::fromExp(const FlatModelica::Expression &exp)
{
  if (exp.isArray()) {
    auto &elems = exp.elements();

    if (elems.size() == 2) {
      mValue.replace(0, elems[0].isInteger() ? StringHandler::getArrowType(QString::fromStdString(elems[0].enumValue())) : StringHandler::ArrowNone);
      mValue.replace(1, elems[1].isInteger() ? StringHandler::getArrowType(QString::fromStdString(elems[1].enumValue())) : StringHandler::ArrowNone);
    }
  }
}
