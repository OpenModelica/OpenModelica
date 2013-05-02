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

encapsulated package Instance
" file:  Instance.mo
  package:     Instance
  description: Instance is an instance of an Element.

  RCS: $Id: Instance.mo 8980 2011-05-13 09:12:21Z adrpo $

  An element node and its modifications gives us an instance.
  Instance point to reference nodes via their id.
  These reference nodes should be resolved to other instances!"

public
uniontype TypeKind
  record LOCD "long class definition. i.e. parts"
    Integer iIDcc "points to the reference node which should be resolved to an instance of the class constraint, if there is no constraint points to itself";
  end LOCD;

  record SHCD "short class definition. i.e. derived"
    Integer iIDty "points to the reference node which should be resolved to the instance of derived type, class extends; for a local class points to itself";
    Integer iIDcc "points to the reference node which should be resolved to the instance of the class constraint, if there is no constraint points to itself";
  end SHCD;

  record EXCD "class extends definition (ExtendsClassDefinition)"
    Integer ty "points to the reference node which should be resolved to the instance of derived type, class extends; for a local class points to itself";
    Integer cc "points to the reference node which should be resolved to the instance of the class constraint, if there is no constraint points to itself";
  end EXCD;

  record ENCD "enumeration definition (enumeration class definition)"
  end ENCD;

  record OVCD "overloaded"
  end OVCD;

  record PDCD "partial der"
  end PDCD;
end TypeKind;

uniontype Import "classification of imports, ed=element definition"
  record UIM "unqualified package import"
    Integer iIDed "points to the reference node which should be resolved to a type or component definition";
  end UIM;
  record NIM "named import, a qualified A.B.C is transformed to named C = A.B.C"
    Integer nameId "the rename, the X in X = A.B.C";
    Integer iIDed "points to the reference node which should be resolved to a type or component definition";
  end NIM;
end Import;

uniontype Kind

  record TI "type instance, i.e. local class, class extends or derived"
    TypeKind tk "the type kind";
  end TI;

  record CI "component instance"
    Integer iIDty "points to the reference node which should be resolved to the instance of the component type";
    Integer iIDcc "points to the reference node which should be resolved to the class constraint, if there is no constraint points to itself";
  end CI;

  record EI "extends instance"
    Integer iIDty "points to the reference node which should be resolved to the instance of the extends type";
  end EI;

  record II "import instance"
    Import ir;
  end II;

  record UI "define unit instance"
  end UI;

end Kind;

uniontype Status
  record INI "initial"      end INI;
  record AZD "anlayzed"     end AZD;
  record NZD "not analyzed" end NZD;
end Status;

uniontype Instance "an instance of a node"
  record I
    Kind      kind   "depending on what kind of instance this is it has different information!";
    Status    status "the instance status";
  end I;
end Instance;

constant Instance initialTI = I(TI(LOCD(0)), INI());

end Instance;

