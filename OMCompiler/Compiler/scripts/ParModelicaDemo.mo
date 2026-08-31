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

model ParModelicaDemo
  "Small parallel-by-construction model for the parmodauto clustering-optimization demo.

   It is N independent chains  x[i] -> a[i] -> {der(x[i]), b[i]}  feeding a single
   join  total = sum(b).  The independent chains give the auto-parallelizer a wide,
   shallow task graph (lots to spread across lanes) and the join gives a clear
   fan-in leaf, so the clustering and its optimization are easy to see in the
   exported GraphML/SVG. No Modelica Standard Library needed, so it builds in
   seconds."
  constant Integer N = 16;
  Real x[N](each start = 1.0, each fixed = true);
  Real a[N];
  Real b[N];
  Real total;
equation
  for i in 1:N loop
    a[i] = sin(time * i) + 0.5 * x[i];
    der(x[i]) = -0.3 * x[i] + 0.05 * a[i];
    b[i] = a[i] ^ 2 - 0.1 * x[i] + 0.01 * a[i] * x[i];
  end for;
  total = sum(b);
  annotation(experiment(StopTime = 1.0));
end ParModelicaDemo;
