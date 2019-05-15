/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

encapsulated package NFInstDump
" file:        NFInstDump.mo
  package:     NFInstDump
  description: Dumping functions for the intermediary instantiation structures.


  This package contains dumping functions for the intermediary instantiation
  structures, mostly wrappers for NFInstDumpTpl.
"

//public import NFConnect2;
public import NFInstTypes;

protected import NFInstDumpTpl;
protected import List;
protected import Tpl;

public function modelStr
  input String inName;
  input NFInstTypes.Class inClass;
  output String outString;
algorithm
  outString := Tpl.tplString2(NFInstDumpTpl.dumpModel, inName, inClass);
end modelStr;

public function elementStr
  input NFInstTypes.Element inElement;
  output String outString;
algorithm
  outString := Tpl.tplString(NFInstDumpTpl.dumpElement, inElement);
end elementStr;

public function componentStr
  input NFInstTypes.Component inComponent;
  output String outString;
algorithm
  outString := Tpl.tplString(NFInstDumpTpl.dumpComponent, inComponent);
end componentStr;

public function bindingStr
  input NFInstTypes.Binding inBinding;
  output String outString;
algorithm
  outString := Tpl.tplString(NFInstDumpTpl.dumpBinding, inBinding);
end bindingStr;

public function prefixStr
  input NFInstTypes.Prefix inPrefix;
  output String outString;
algorithm
  outString := Tpl.tplString(NFInstDumpTpl.dumpPrefix, inPrefix);
end prefixStr;

public function equationStr
  input NFInstTypes.Equation inEquation;
  output String outString;
algorithm
  outString := Tpl.tplString(NFInstDumpTpl.dumpEquation, inEquation);
end equationStr;

//public function connectionsStr
//  input NFConnect2.Connections inConnections;
//  output String outString;
//algorithm
//  outString := Tpl.tplString(NFInstDumpTpl.dumpConnections, inConnections);
//end connectionsStr;

public function dimensionStr
  input NFInstTypes.Dimension inDimension;
  output String outString;
algorithm
  outString := Tpl.tplString(NFInstDumpTpl.dumpDimension, inDimension);
end dimensionStr;

public function dumpUntypedComponentDims
  input NFInstTypes.Component inComponent;
  output String outString;
algorithm
  outString := match(inComponent)
    local
      array<NFInstTypes.Dimension> adims;
      list<NFInstTypes.Dimension> ldims;
      String dims_str;

    case NFInstTypes.UNTYPED_COMPONENT(dimensions = adims)
      equation
        ldims = arrayList(adims);
        dims_str = List.toString(ldims, dimensionStr, "", "[", ", ", "]", false);
      then
        dims_str;

  end match;
end dumpUntypedComponentDims;

annotation(__OpenModelica_Interface="frontend");
end NFInstDump;
