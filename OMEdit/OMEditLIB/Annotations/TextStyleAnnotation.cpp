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
#include "TextStyleAnnotation.h"

TextStyleAnnotation::TextStyleAnnotation()
{
  clear();
}

void TextStyleAnnotation::clear()
{
  mValue.clear();
  QVector<StringHandler::TextStyle> v;
  mValue.swap(v);
}

TextStyleAnnotation& TextStyleAnnotation::operator= (const QVector<StringHandler::TextStyle> &value)
{
  mValue = value;
  setExp();
  return *this;
}

QFont::Weight TextStyleAnnotation::getWeight() const
{
  foreach (StringHandler::TextStyle textStyle, mValue) {
    if (textStyle == StringHandler::TextStyleBold) {
      return QFont::Bold;
    }
  }
  return QFont::Normal;
}

bool TextStyleAnnotation::isItalic() const
{
  foreach (StringHandler::TextStyle textStyle, mValue) {
    if (textStyle == StringHandler::TextStyleItalic) {
      return true;
    }
  }
  return false;
}

bool TextStyleAnnotation::isUnderLine() const
{
  foreach (StringHandler::TextStyle textStyle, mValue) {
    if (textStyle == StringHandler::TextStyleUnderLine) {
      return true;
    }
  }
  return false;
}

FlatModelica::Expression TextStyleAnnotation::toExp() const
{
  std::vector<FlatModelica::Expression> elems;

  for (auto &v: mValue) {
    elems.emplace_back(FlatModelica::Expression(StringHandler::getTextStyleString(v).toStdString(), v));
  }

  return FlatModelica::Expression(std::move(elems));
}

void TextStyleAnnotation::fromExp(const FlatModelica::Expression &exp)
{
  if (exp.isArray()) {
    auto &elems = exp.elements();
    // clear before setting new value
    clear();

    for (size_t i = 0u; i < elems.size(); ++i) {
      mValue.append(elems[i].isInteger() ? StringHandler::getTextStyleType(QString::fromStdString(elems[i].enumValue())) : StringHandler::TextStyleBold);
    }
  }
}
