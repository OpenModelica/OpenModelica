/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
* c/o Linköpings universitet, Department of Computer and Information Science,
* SE-58183 Linköping, Sweden.
*
* All rights reserved.
*
* THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
* THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
* ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
* RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
* ACCORDING TO RECIPIENTS CHOICE.
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
encapsulated uniontype NBStrongComponent
"file:        NBStrongComponent.mo
 package:     NBStrongComponent
 description: This file contains the data-types used save the strong Component
              data after causalization.
"
protected
  import BackendDAE = NBackendDAE;
  import NBEquation.Equation;
  import Variable = NFVariable;

public
  record SINGLEEQUATION
    Pointer<Equation> eqn;
    Pointer<Variable> var;
  end SINGLEEQUATION;

  record SINGLEARRAY
    Pointer<Equation> eqn;
    list<Pointer<Variable>> vars;
  end SINGLEARRAY;

  record SINGLEALGORITHM
    Pointer<Equation> eqn;
    list<Pointer<Variable> > vars;
  end SINGLEALGORITHM;

  record SINGLECOMPLEXEQUATION
    Pointer<Equation> eqn;
    list<Pointer<Variable>> vars;
  end SINGLECOMPLEXEQUATION;

  record SINGLEWHENEQUATION
    Pointer<Equation> eqn;
    list<Pointer<Variable>> vars;
  end SINGLEWHENEQUATION;

  record SINGLEIFEQUATION
    Pointer<Equation> eqn;
    list<Pointer<Variable>> vars;
  end SINGLEIFEQUATION;

  record EQUATIONSYSTEM
    list<Pointer<Equation>> eqns;
    list<Pointer<Variable>> vars;
    BackendDAE jac;
    Boolean mixedSystem   "true for system that discrete dependencies to the
                          iteration variables";
  end EQUATIONSYSTEM;

/* ToDo: Needs to be added once tearing is implemented
  record TORNSYSTEM
    TearingSet strictTearingSet;
    Option<TearingSet> casualTearingSet;
    Boolean linear;
    Boolean mixedSystem "true for system that discrete dependencies to the iteration variables";
  end TORNSYSTEM;
*/
annotation(__OpenModelica_Interface="backend");
end NBStrongComponent;
