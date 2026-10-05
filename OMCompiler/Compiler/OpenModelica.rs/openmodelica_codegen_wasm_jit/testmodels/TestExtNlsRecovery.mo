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

// A ModelicaError inside a nonlinear-solver residual is a rejected trial, not the
// end of the run. The raising function is ModelicaExternalC's, unlike testsuite
// ExternalNlsRecovery's, so this is the web target's error path: the side module.
// The first Newton step overshoots far past u_max = 2 (the slope at the start
// point is 1/1000 of the one at the root), where NoExtrapolation refuses.
// Root: y = 0.001 + 0.999*(u - 1) = 0.5 + 0.4*time, i.e. u = 1.4995 .. 1.8999.
model TestExtNlsRecovery
  Modelica.Blocks.Tables.CombiTable1Ds tab(
    table = [0, 0; 1, 0.001; 2, 1],
    extrapolation = Modelica.Blocks.Types.Extrapolation.NoExtrapolation);
  Real x(start = 0.5);
equation
  tab.u = x;
  tab.y[1] = 0.5 + 0.4 * time;
end TestExtNlsRecovery;
