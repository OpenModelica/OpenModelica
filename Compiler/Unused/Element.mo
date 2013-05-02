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

encapsulated package Element
" file:  Element.mo
  package:     Element
  description: Element represents an element.
  @author:     adrpo

  RCS: $Id: Element.mo 8980 2011-05-13 09:12:21Z adrpo $

  The Element "

public
import Absyn;
import SCode;
import Scope;



public
uniontype Element
"an element with an id and order"
  record E
    SCode.Element element  "the element definition";
    Integer       order    "the element position in its parent";
  end E;
end Element;

public function setOrder
"sets the order in the element"
  input  Element inE;
  input Integer inOrder;
  output Element outE;
protected
  SCode.Element e;
  Integer order;
algorithm
  E(e, order) := inE;
  outE := E(e, inOrder);
end setOrder;

public function order
"gets the order in the element"
  input  Element inE;
  output Integer order;
algorithm
  E(order = order) := inE;
end order;

public function element
"gets the SCode.Element in the element"
  input  Element inE;
  output SCode.Element element;
algorithm
  E(element = element) := inE;
end element;

public function properties "returns the element properties"
  input  Element e;
  output String name;
  output Scope.Kind segmentKind;
algorithm
  (name, segmentKind) := matchcontinue(e)
    local
      String n;
      Absyn.Path p;
      Absyn.Import imp;

    case E(element = SCode.IMPORT(imp = imp))
      equation
   n = Absyn.printImportString(imp);
      then
  (n, Scope.NI(0,0));

    case E(element = SCode.EXTENDS(baseClassPath = p))
      equation
  n = Absyn.pathString(p);
      then
  (n, Scope.EX(0));

    case E(element = SCode.CLASS(name = n))
      then (n, Scope.TY());

    case E(element = SCode.COMPONENT(name = n))
      then (n, Scope.CO(0));

    case E(element = SCode.DEFINEUNIT(name = n))
      then (n, Scope.UN());

  end matchcontinue;
end properties;

end Element;

