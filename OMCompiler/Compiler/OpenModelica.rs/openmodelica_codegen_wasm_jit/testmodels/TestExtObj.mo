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

// External-object spike (libc only): an external object whose constructor is
// strdup(String)->void*, destructor free(void*), read fn strlen(void*)->Integer.
// Exercises the whole external-object mechanism — i32 handle registry, String
// marshalling, pointer round-trip — with no MSL/array/ModelicaUtilities.
// der(x) = strlen("hello") = 5, x(0)=0; x(1) = 5.
model TestExtObj
  class StrBox
    extends ExternalObject;
    function constructor
      input String s;
      output StrBox b;
      external "C" b = strdup(s) annotation(Include = "#include <string.h>");
    end constructor;
    function destructor
      input StrBox b;
      external "C" free(b) annotation(Include = "#include <stdlib.h>");
    end destructor;
  end StrBox;

  function boxlen
    input StrBox b;
    output Integer n;
    external "C" n = strlen(b) annotation(Include = "#include <string.h>");
  end boxlen;

  parameter StrBox box = StrBox("hello");
  Real x(start = 0, fixed = true);
equation
  der(x) = boxlen(box);
end TestExtObj;
