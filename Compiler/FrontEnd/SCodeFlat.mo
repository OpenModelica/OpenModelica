/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package SCodeFlat
" file:        SCodeFlat.mo
  package:     SCodeFlat
  description: SCodeFlat is a flattened form of SCode

  RCS: $Id: SCodeFlat.mo 8980 2011-05-13 09:12:21Z perost $

  The SCodeFlat representation is used to simplify the models even further.
  
Flattening:
-----------

Idea: *everything in Modelica can be reduced to components*
- components: Type c[AD](mods);
  + encoded as Type[AD](mods) c;
- classes:    class Type ... end Type;
  + encoded as Type Type;
- extends:    class A extends B(mods); end A;
  + encoded as A.B(mods) A.$e(B);
- derived:    class A = B[AD](mods);
  + encoded as A.B[AD](mods) A.$e(B);
- equations:  equation  eq1; eq2; eq3;
  + encoded as Type.$eq Type.$eq{eq1,eq2,eq3};
- algorithms: algorithm al1; al2; al3;
  + encoded as Type.$al Type.$al{al1,al2,al3}; "

public import Absyn;
public import SCode;

public constant String extendsName = "$e";
public constant String derivedName = "$d";

public constant String algorithmsName = "$al";
public constant String equationsName = "$eq";

public
uniontype Kind
  record NORMAL  end NORMAL;  
  record EXTENDS end EXTENDS;
  record DERIVED end DERIVED;
  record ALGORITHMS end ALGORITHMS;
  record EQUATIONS  end EQUATIONS;
end Kind;

uniontype Type 
  record T 
    SCode.Ident   name         "the type name, for derived/extends we use the predefined constants above: extendsName and derivedName";
    SCode.Element origin       "the element from which the type originates";
    SCode.Mod     modification "the modification of this type";
    Kind          kind         "what kind of type it is"; 
  end T;
end Type;

type TypePath = list<Type> 
  "a type path is used to represent the type of a component or type component
   Example: 
     package N = P (redeclare package R = P_R);
     will be represented as (the left hand side is a type path), the right hand side is a component reference:
     RP.N                                                       RP.N;
     RP.N.$d(P(redeclare R = P_R))                              RP.N.$d(P);";

uniontype Component "a component"
  record C
    SCode.Ident   name         "the type name, for derived/extends we use the predefined constants above: extendsName and derivedName";
    SCode.Element origin       "the element from which the component originates";
    Kind          kind         "what kind of component it is";
    TypePath      ty           "the full type path for this component";
  end C;
end Component;

// a qualifed component is a list of components
type QualifiedComponent = list<Component>;

// a flat program is a list of qualified components.
type FlatProgram = list<QualifiedComponent>;

end SCodeFlat;

