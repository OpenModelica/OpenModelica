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

/*PDEModelica extension built-ins*/

record DomainLineSegment1D "Record representing 1-dimensional domain where a partial differential equation hold."
  record Region
  end Region;
  parameter Real x0(unit="m")=0 "x value at left boundary";
  parameter Real L(unit="m")=1 "length of the domain";
  constant Integer N(unit="")=10 "number of grid nodes";
  parameter Real dx = L / (N-1) "grid space step";
  parameter Real[N] x(each unit="m") = array(x0 + i*dx for i in 0:N-1) "space coordinate";
  Region left, right, interior "regions representing boundaries and the interior";
end DomainLineSegment1D;

function pder "Partial space derivative of the input expression in the first argument with respect to second argument"
  input Real u(unit="'p");
  input Real x(unit="'q");
  output Real du(unit="'p/'q");
external "builtin";
annotation(Documentation(info="<html>
  See <a href=\"???\">pder()</a>
</html>"));
end pder;

function extrapolateField "Extrapolates field in the boundary"
  output Real u;
external "builtin";
end extrapolateField;
