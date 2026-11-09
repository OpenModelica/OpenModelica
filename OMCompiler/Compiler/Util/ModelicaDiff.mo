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

encapsulated package ModelicaDiff
  "diffModelicaFileListings, implemented in OpenModelica.rs/openmodelica_modelica_diff:
   puts the changes of a listing into the text the user wrote, keeping its
   formatting and comments."

function merge
  "before with the changes from beforeCanonical to after. The texts have LF
   line endings and no byte order mark."
  input String before;
  input String beforeCanonical "unparse(parse(before))";
  input String after;
  output String result;
  external "C" result = om_modelica_diff(before, beforeCanonical, after) annotation(Library = "omcruntime");
end merge;

type Format = enumeration(Plain, Color "Terminal colors", Xml);

function render
  "The merged text as a diff of before and it."
  input String before;
  input String merged;
  input Format format;
  output String result;
  external "C" result = om_modelica_render(before, merged, format) annotation(Library = "omcruntime");
end render;

function codeEqual
  "Whether a and b have the same code, ignoring whitespace, comments, the
   common indentation of the lines of multi-line strings and a leading within
   clause."
  input String a;
  input String b;
  output Boolean equal;
  external "C" equal = om_modelica_code_equal(a, b) annotation(Library = "omcruntime");
end codeEqual;

annotation(__OpenModelica_Interface="util");
end ModelicaDiff;
