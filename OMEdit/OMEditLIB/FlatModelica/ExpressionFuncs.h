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
#ifndef EXPRESSION_FUNCS_H
#define EXPRESSION_FUNCS_H

#include <vector>

#include "Expression.h"

namespace FlatModelica
{
  // 3.7.1
  Expression evalAbs(const Expression &x);
  Expression evalSign(const Expression &x);
  Expression evalSqrt(const Expression &x);
  Expression evalString(const std::vector<Expression> &args);

  // 3.7.2
  Expression evalDiv(const Expression &x, const Expression &y);
  Expression evalMod(const Expression &x, const Expression &y);
  Expression evalRem(const Expression &x, const Expression &y);
  Expression evalCeil(const Expression &x);
  Expression evalFloor(const Expression &x);
  Expression evalInteger(const Expression &x);

  // 3.7.3
  Expression evalSin(const Expression &x);
  Expression evalCos(const Expression &x);
  Expression evalTan(const Expression &x);
  Expression evalAsin(const Expression &x);
  Expression evalAcos(const Expression &x);
  Expression evalAtan(const Expression &x);
  Expression evalAtan2(const Expression &x, const Expression &y);
  Expression evalSinh(const Expression &x);
  Expression evalCosh(const Expression &x);
  Expression evalTanh(const Expression &x);
  Expression evalExp(const Expression &x);
  Expression evalLog(const Expression &x);
  Expression evalLog10(const Expression &x);

  // 10.3.1
  Expression evalNdim(const Expression &A);
  Expression evalSize(const Expression &A);
  Expression evalSize(const Expression &A, const Expression &i);

  // 10.3.2
  Expression evalScalar(const Expression &A);
  Expression evalVector(const Expression &A);
  Expression evalMatrix(const Expression &A);

  // 10.3.3
  Expression evalIdentity(const Expression &n);
  Expression evalDiagonal(const Expression &v);
  Expression evalZeros(const std::vector<Expression> &args);
  Expression evalOnes(const std::vector<Expression> &args);
  Expression evalFill(const std::vector<Expression> &args);

  // 10.3.4
  Expression evalMin(const Expression &x, const Expression &y);
  Expression evalMin(const Expression &A);
  Expression evalMax(const Expression &x, const Expression &y);
  Expression evalMax(const Expression &A);
  Expression evalSum(const Expression &A);
  Expression evalProduct(const Expression &A);

  // 10.3.5
  Expression evalTranspose(const Expression &A);
  Expression evalSymmetric(const Expression &A);

  // 10.4.2
  Expression evalCat(const std::vector<Expression> &args);
}

#endif /* EXPRESSION_FUNCS_H */
