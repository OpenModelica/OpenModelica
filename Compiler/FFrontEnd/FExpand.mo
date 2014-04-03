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

encapsulated package FExpand
" file:        FExpand.mo
  package:     FExpand
  description: Expanding parts of the graph

  RCS: $Id: FExpand 18987 2014-02-05 16:24:53Z adrpo $

"

// public imports
public 
import Absyn;
import FNode;
import FLookup;

type Node = FNode.Node;
type Ref = FNode.Ref;
type Refs = FNode.Refs;
type Parents = FNode.Parents;
type Name = FNode.Name;
type Msg = Option<Absyn.Info>;

public function ext
"@author: adrpo
 for all extends.$ref add an extends.$ty in the node."
  input Ref inRef;
algorithm
  _ := match(inRef)
    case _
      equation
        
      then
        ();
  end match;
end ext;

end FExpand;
