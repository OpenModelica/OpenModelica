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

// E3: external "C" with an OUTPUT array. ModelicaRandom_xorshift64star fills an
// Integer[2] state output (copied back) and a Real output y. With the fixed seed
// {123456789, 362436069} the reference C gives y=0.577295382940 and
// stateOut={-602104472, 331981141}. der(x)=y, der(z)=stateOut[1], so x(1)=y and
// z(1)=-602104472 — the array-output value round-tripped through the C call.
model TestXorshift
  function rng
    input Integer sIn[2];
    output Real y;
    output Integer sOut[2];
    external "C" ModelicaRandom_xorshift64star(sIn, sOut, y);
  end rng;

  function getY
    output Real y;
  protected
    Integer sOut[2];
  algorithm
    (y, sOut) := rng({123456789, 362436069});
  end getY;

  function getS0
    output Real v;
  protected
    Real y;
    Integer sOut[2];
  algorithm
    (y, sOut) := rng({123456789, 362436069});
    v := sOut[1];
  end getS0;

  Real x(start = 0, fixed = true);
  Real z(start = 0, fixed = true);
equation
  der(x) = getY();
  der(z) = getS0();
end TestXorshift;
