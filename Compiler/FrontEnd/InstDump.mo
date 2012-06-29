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

encapsulated package InstDump
" file:        InstDump.mo
  package:     Connect
  description: Dumping functions for the intermediary instantiation structures.

  RCS: $Id$

  This package contains dumping functions for the intermediary instantiation
  structures, mostly wrappers for InstDumpTpl.
"

public import Connect2;
public import InstTypes;

protected import InstDumpTpl;
protected import Tpl;

public function modelStr
  input String inName;
  input InstTypes.Class inClass;
  output String outString;
algorithm
  outString := Tpl.tplString2(InstDumpTpl.dumpModel, inName, inClass);
end modelStr;

public function elementStr
  input InstTypes.Element inElement;
  output String outString;
algorithm
  outString := Tpl.tplString(InstDumpTpl.dumpElement, inElement);
end elementStr;

public function componentStr
  input InstTypes.Component inComponent;
  output String outString;
algorithm
  outString := Tpl.tplString(InstDumpTpl.dumpComponent, inComponent);
end componentStr;

public function bindingStr
  input InstTypes.Binding inBinding;
  output String outString;
algorithm
  outString := Tpl.tplString(InstDumpTpl.dumpBinding, inBinding);
end bindingStr;

public function prefixStr
  input InstTypes.Prefix inPrefix;
  output String outString;
algorithm
  outString := Tpl.tplString(InstDumpTpl.dumpPrefix, inPrefix);
end prefixStr;

public function equationStr
  input InstTypes.Equation inEquation;
  output String outString;
algorithm
  outString := Tpl.tplString(InstDumpTpl.dumpEquation, inEquation);
end equationStr;

public function connectionsStr
  input Connect2.Connections inConnections;
  output String outString;
algorithm
  outString := Tpl.tplString(InstDumpTpl.dumpConnections, inConnections);
end connectionsStr;

end InstDump;
