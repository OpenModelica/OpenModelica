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

encapsulated package NFApi

import Absyn;
import DAE;

public
function evaluateAnnotation
  "Instantiates the annotation class, gets the DAE and populates the annotation result"
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  input Absyn.Annotation inAnnotation;
  output String outString = "";
end evaluateAnnotation;

public
function evaluateAnnotations
  "Instantiates the annotation class, gets the DAE and populates the annotation result"
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  input list<Absyn.Element> inElements;
  output list<String> outStringLst = {};
end evaluateAnnotations;

public
function mkFullyQual
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  input Absyn.Path pathToQualify;
  input Boolean failOnError = false;
  output Absyn.Path qualPath = pathToQualify;
end mkFullyQual;

function getInheritedClasses
  input Absyn.Path classPath;
  input Absyn.Program program;
  output list<Absyn.Path> extendsPaths;
end getInheritedClasses;

  annotation(__OpenModelica_Interface="backend");
end NFApi;
