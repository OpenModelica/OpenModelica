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

encapsulated package FMod
" file:        FMod.mo
  package:     FMod
  description: Utilities for Modifier handling

  RCS: $Id: FMod.mo 14085 2012-11-27 12:12:40Z adrpo $

  This module contains functions for modifier handling
"

// public imports
public
import FCore;

// protected imports
protected

public
type Name = FCore.Name;
type Id = FCore.Id;
type Seq = FCore.Seq;
type Next = FCore.Next;
type Node = FCore.Node;
type Data = FCore.Data;
type Kind = FCore.Kind;
type Ref = FCore.Ref;
type Refs = FCore.Refs;
type Children = FCore.Children;
type Parents = FCore.Parents;
type Scope = FCore.Scope;
type ImportTable = FCore.ImportTable;
type Graph = FCore.Graph;
type Extra = FCore.Extra;
type Visited = FCore.Visited;
type Import = FCore.Import;
type AvlTree = FCore.CAvlTree;
type AvlKey = FCore.CAvlKey;
type AvlValue = FCore.CAvlValue;
type AvlTreeValue = FCore.CAvlTreeValue;


public function merge
"@author: adrpo
 merge 2 modifiers, one outer one inner"
  input Ref inParentRef;
  input Ref inOuterModRef;
  input Ref inInnerModRef;
  input Graph inGraph;
  output Graph outGraph;
  output Ref outMergedModRef;
algorithm
  (outGraph, outMergedModRef) := match(inParentRef, inOuterModRef, inInnerModRef, inGraph)
    local
      Ref r;
      Graph g;
    case (r, _, _, g)
      equation
      then
        (g, r);
  end match;
end merge;

public function apply
"@author: adrpo
 apply the modifier to the given target"
  input Ref inTargetRef;
  input Ref inModRef;
  input Graph inGraph;
  output Graph outGraph;
  output Ref outNodeRef;
algorithm
  (outGraph, outNodeRef) := match(inTargetRef, inModRef, inGraph)
    local
      Ref r;
      Graph g;
    case (r, _, g)
      equation
      then
        (g, r);
  end match;
end apply;

end FMod;
