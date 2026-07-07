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

// External "C" with a `char**` string output (via ModelicaAllocateString → our
// arena → rebuilt as an in-wasm String). scanString parses the quoted literal
// "42" → the String "42"; scanInteger then reads that String back → 42.
// der(x) = 42, so x(1) = 42. Exercises the string-output round-trip end to end.
model TestScanString
  function scanString
    input String str;
    input Integer startIndex;
    output Integer nextIndex;
    output String string;
    external "C" ModelicaStrings_scanString(str, startIndex, nextIndex, string);
  end scanString;

  function scanInteger
    input String str;
    input Integer startIndex;
    input Boolean unsigned;
    output Integer nextIndex;
    output Integer number;
    external "C" ModelicaStrings_scanInteger(str, startIndex, unsigned, nextIndex, number);
  end scanInteger;

  function parseQuoted
    input String str;
    output Integer number;
  protected
    Integer ni1, ni2;
    String s;
  algorithm
    (ni1, s) := scanString(str, 1);
    (ni2, number) := scanInteger(s, 1, false);
  end parseQuoted;

  Real x(start = 0, fixed = true);
equation
  der(x) = parseQuoted("\"42\"");
end TestScanString;
