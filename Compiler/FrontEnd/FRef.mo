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

encapsulated package FRef
" file:        FRef.mo
  package:     FRef
  description: A package for Modelica references (component references, type references, import references)

  RCS: $Id: FRef.mo 14085 2012-11-27 12:12:40Z adrpo $

  Structures to handle references. 
"

public import Absyn;
public import SCode;
public import Util;
public import DAE;
public import FNode;

public type Ident = FNode.Ident;
public type NodeId = FNode.NodeId;
public type Name = FNode.Ident;
public type Ref = FNode.Ref;
public type Refs = FNode.Refs;
public type NameRef = FNode.NameRef;
public type NodeData = FNode.NodeData;

constant NameRef topNameRef = FNode.R(FNode.topNodeName, {}, FNode.topNodeId);  
constant Ref topRef = {topNameRef};

protected import List;

public function string
  input Ref inRef;
  output String outStr;
algorithm
  outStr := matchcontinue(inRef)
    local 
      String str;
      Ref rest;
      NameRef s;
    
    case ({}) then ".";
    
    case (s::rest)
      equation
         str = stringName(s);
         str = str +& "." +& string(rest); 
      then
        str;
  
  end matchcontinue;
end string;

public function stringName
  input NameRef inRef;
  output String outStr;
algorithm
  outStr := matchcontinue(inRef)
    local 
      NodeId id;
      Name n;
      String str;
      Ref rest;
      Refs subs;
      NameRef s;
    
    case (FNode.R(n,subs,id))
      equation
        str = n +& "(" +& intString(id) +& ")" +& stringSRefs(subs); 
      then 
        str;
    
    case (FNode.U(n,subs))
      equation
        str = n +& stringSRefs(subs);
      then 
        str;
  
  end matchcontinue;
end stringName;

public function stringRefs
  input Refs inRefs;
  output String outStr;
algorithm
  outStr := stringDelimitList(List.map(inRefs, string), ", "); 
end stringRefs;

public function stringSRefs
  input Refs inRefs;
  output String outStr;
algorithm
  outStr := "S[" +& stringRefs(inRefs) +& "]"; 
end stringSRefs;

public function stringDRefs
  input Refs inRefs;
  output String outStr;
algorithm
  outStr := "D[" +& stringRefs(inRefs) +& "]"; 
end stringDRefs;

public function fromPath
  input Absyn.Path inPath;
  output Ref outRef;
algorithm
  outRef := matchcontinue(inPath)
    local
      Absyn.Path p;
      Ident i;
      Ref r;
      NameRef nr;
      
    case (Absyn.FULLYQUALIFIED(p))
      equation
        // add topref first, then unresolved
        r = fromPath(p);
        r = topNameRef::r;
      then
        r;
    
    case (Absyn.QUALIFIED(i, p))
      equation
        r = fromPath(p);
        r = FNode.U(i,{})::r;
      then
        r;
        
    case (Absyn.IDENT(i))
      equation
        r = {FNode.U(i,{})};
      then
        r;
        
  end matchcontinue;
end fromPath;

public function fromCref
  input Absyn.ComponentRef inCRef;
  output Ref outRef;
algorithm
  outRef := matchcontinue(inCRef)
    local
      Absyn.ComponentRef c;
      Ident i;
      Ref r;
      NameRef nr;
      list<Absyn.Subscript> s;
      Refs rs;
      
    case (Absyn.CREF_FULLYQUALIFIED(c))
      equation
        // add topref first, then unresolved
        r = fromCref(c);
        r = topNameRef::r;
      then
        r;
    
    case (Absyn.CREF_QUAL(i, s, c))
      equation
        r = fromCref(c);
        rs = fromSubs(s);
        r = FNode.U(i,rs)::r;
      then
        r;
        
    case (Absyn.CREF_IDENT(i, s))
      equation
        rs = fromSubs(s);
        r = {FNode.U(i,rs)};
      then
        r;
        
  end matchcontinue;
end fromCref;

public function fromSubs
  input list<Absyn.Subscript> inSubs;
  output Refs outRefs;
algorithm
  outRefs := List.flatten(List.map(inSubs, fromSub));
end fromSubs;

public function fromSub
  input Absyn.Subscript inSub;
  output Refs outRefs;
algorithm
  outRefs := matchcontinue(inSub)
    local
      Absyn.ComponentRef c;
      Ident i;
      Ref r;
      list<Absyn.Subscript> s;
      Refs rs;
      Absyn.Exp e;
      list<Absyn.ComponentRef> crl;
      
    case (Absyn.NOSUB()) 
      equation
        r = {FNode.U("$:", {})};
      then
        {r};
    
    case (Absyn.SUBSCRIPT(e))
      equation
        crl = Absyn.getCrefFromExp(e, true, true);
        rs = List.map(crl, fromCref);
      then
        rs;
        
  end matchcontinue;
end fromSub;

public function fromTypeSpec
  input Absyn.TypeSpec inTypeSpec;
  output Ref outRef;
algorithm
  outRef := matchcontinue(inTypeSpec)
    local
      Absyn.Path p;
      Ident i;
      Ref r;
      NameRef nr;
      list<Absyn.Subscript> s;
      Absyn.ComponentRef c;

    case (Absyn.TPATH(p, SOME(s)))
      equation
        c = Absyn.pathToCref(p);
        c = Absyn.addSubscriptsLast(c, s);
        r = fromCref(c);
      then
        r;
    
    case (Absyn.TPATH(p, NONE()))
      equation
        r = fromPath(p);
      then
        r;
    
    // TODO! FIXME! more handling for complex types
    case (Absyn.TCOMPLEX(p, _, _))
      equation
        r = fromPath(p);
      then
        r;        
  
  end matchcontinue;
end fromTypeSpec;

public function fromSubsOpt
  input Option<list<Absyn.Subscript>> inSubsOpt;
  output Refs outRefs;
algorithm
  outRefs := match(inSubsOpt)
    local
      list<Absyn.Subscript> s;
    case (NONE()) then {};
    case (SOME(s)) then fromSubs(s);
  end match;
end fromSubsOpt;

public function stringFromNodeData
  input NodeData inNodeData;
  output String outStr;
algorithm
  outStr := match(inNodeData)
    local Ref r;
    case FNode.TR(r = r) then string(r);
    case FNode.CR(r = r) then string(r);
  end match;  
end stringFromNodeData;

end FRef;
