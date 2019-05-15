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

encapsulated package InstTypes
" file:        InstTypes.mo
  package:     InstTypes
  description: Intermediate types used internally during model instantiation

"

public
import DAE;

uniontype CallingScope "
Calling scope is used to determine when unconnected flow variables should be set to zero."
  record TOP_CALL   "this is a top call"    end TOP_CALL;
  record INNER_CALL "this is an inner call" end INNER_CALL;
  record TYPE_CALL  "a call to determine type of a class" end TYPE_CALL;
end CallingScope;

type PolymorphicBindings = list<tuple<String,list<DAE.Type>>>;

constant Boolean alwaysUnroll = true;
constant Boolean neverUnroll = false;

uniontype SearchStrategy
  record SEARCH_LOCAL_ONLY
    "this one searches only in the local scope, it won't find *time* variable"
  end SEARCH_LOCAL_ONLY;
  record SEARCH_ALSO_BUILTIN
    "this one searches also in the builtin scope, it will find *time* variable"
  end SEARCH_ALSO_BUILTIN;
end SearchStrategy;

uniontype SplicedExpData
  record SPLICEDEXPDATA "data for 'spliced expression' (typically a component reference) returned in lookupVar"
    Option<DAE.Exp> splicedExp "the spliced expression";
    DAE.Type identType "the type of the variable without subscripts, needed for vectorization";
  end SPLICEDEXPDATA;
end SplicedExpData;

type TypeMemoryEntry = tuple<DAE.Type, DAE.Type>;
type TypeMemoryEntryList = list<TypeMemoryEntry>;
type TypeMemoryEntryListArray = array<TypeMemoryEntryList>;

public function callingScopeStr
  input CallingScope inCallingScope;
  output String str;
algorithm
  str := match(inCallingScope)
    case (TOP_CALL()) then "topCall";
    case (INNER_CALL()) then "innerCall";
    case (TYPE_CALL()) then "typeCall";
  end match;
end callingScopeStr;

annotation(__OpenModelica_Interface="frontend");
end InstTypes;
