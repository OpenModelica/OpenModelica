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

encapsulated package NFFlatten
" file:        NFFlatten.mo
  package:     NFFlatten
  description: Flattening

  RCS: $Id$

  New instantiation, enable with +d=scodeInst.
"

public import NFInst.{Instance};


public function flattenClass
  input Instance inClass;
  output Instance outClass = inClass;
algorithm
  outClass := match outClass
    case NFInst.CLASS_INST()
      algorithm
        outClass.children := flattenElements(outClass.children);
      then
        outClass;

  end match;
end flattenClass;

protected function flattenElements
  input list<Instance> inElements;
  output list<Instance> outElements = {};
algorithm
  for e in inElements loop
    outElements := flattenElement(e, outElements);
  end for;
end flattenElements;

protected function flattenElement
  input Instance inElement;
  input list<Instance> inAccum = {};
  output list<Instance> outElements;
algorithm
  outElements := match inElement
    local
      list<Instance> el;

   case NFInst.COMP_INST(ty = NFInst.CLASS_INST(parentScope = 1))
     then inElement :: inAccum;

   case NFInst.COMP_INST()
      algorithm
        NFInst.CLASS_INST(children = el) := flattenClass(inElement.ty);
        el := prefixElements(el, inElement.name);
      then
        listAppend(el, inAccum);

    else inAccum;
  end match;
end flattenElement;

protected function prefixElement
  input Instance inElement;
  input String inPrefix;
  output Instance outElement = inElement;
algorithm
  outElement := match outElement
   case NFInst.COMP_INST()
      algorithm
        outElement.name := inPrefix + "." + outElement.name;
      then
        outElement;

    else inElement;
  end match;
end prefixElement;

protected function prefixElements
  input list<Instance> inElements;
  input String inPrefix;
  output list<Instance> outElements;
algorithm
  outElements := list(prefixElement(e, inPrefix) for e in inElements);
end prefixElements;

annotation(__OpenModelica_Interface="frontend");
end NFFlatten;
