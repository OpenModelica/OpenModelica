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

// External "C" with `_Out_` scalar pointers (void return, two `int*` outputs):
// ModelicaStrings_scanInteger(str, startIndex, unsigned, /*out*/ nextIndex, number).
// der(x) = scanIntNum("123") = 123, so x(1) = 123.
model TestScanInteger
  function scanInteger
    input String str;
    input Integer startIndex;
    input Boolean unsigned;
    output Integer nextIndex;
    output Integer number;
    external "C" ModelicaStrings_scanInteger(str, startIndex, unsigned, nextIndex, number);
  end scanInteger;

  function scanIntNum
    input String str;
    output Integer number;
  protected
    Integer nextIndex;
  algorithm
    (nextIndex, number) := scanInteger(str, 1, false);
  end scanIntNum;

  Real x(start = 0, fixed = true);
equation
  der(x) = scanIntNum("123");
end TestScanInteger;
