/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Link�ping University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
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
 * from Link�ping University, either from the above address,
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

encapsulated package FCore
" file:        FCore.mo
  package:     FCore
  description: Structures to hold Modelica constructs

  RCS: $Id: FCore.mo 14085 2012-11-27 12:12:40Z adrpo $

  This module holds types used in FNode, FGraph and all the other F* packages 
"


public 
import Absyn;
import DAE;
import SCode;

// ************************ FNode structures ***************************
// ************************ FNode structures ***************************
// ************************ FNode structures ***************************
// ************************ FNode structures ***************************
 
type Name = String "An identifier is just a string";
type Import = Absyn.Import;
type Id = Integer;
type Seq = Integer;
type Next = Seq;

constant ImportTable emptyImportTable = IMPORT_TABLE(false, {}, {});

uniontype ImportTable
  record IMPORT_TABLE
    // Imports should not be inherited, but removing them from the node
    // when doing lookup through extends causes problems for the lookup later
    // on, because for example components may have types that depends on
    // imports.  The hidden flag allows the lookup to 'hide' the imports
    // temporarily, without actually removing them.
    Boolean hidden "If true means that the imports are hidden.";
    list<Import> qualifiedImports;
    list<Import> unqualifiedImports;
  end IMPORT_TABLE;
end ImportTable;

type Ref = Array<Node> "array of 1";

uniontype Node
  record N
    Name     name       "node name, class/component/extends name, etc. see also *NodeName in above";
    Id       id         "Unique node id";
    Parents  parents    "A node can have several parents depending on the context";
    Children children   "List of uniquely named classes and variables";
    Data     data       "More data for this node, Class, Var, etc";
  end N;
end Node;

uniontype Data
  record TOP "top"    
  end TOP;

  record CL "class"
    SCode.Element e;
    Kind kind "usedefined, builtin, basic type";
    // we don't add the imports in node's children as they don't have a name
    ImportTable importTable "imports";
  end CL;
  
  record CO "component"
    SCode.Element e;
    DAE.Var instantiated "instantiated component" ;
    Status status "if it untyped, typed or fully instantiated (dae)";
    Kind kind "usedefined, builtin, basic type";
  end CO;
  
  record EX "extends"
    SCode.Element e;
  end EX;
  
  record DE "derived"
    SCode.ClassDef d;
  end DE;

  record DU "unit"
    SCode.Element e;
  end DU;
    
  record TY "type node"
    list<DAE.Type> tys "list since several types with the same name can exist in the same scope (overloading)";
  end TY;

  record AL "algorithm section"
    Name name "al or ial (initial)";
    list<SCode.AlgorithmSection> a;
  end AL;
  
  record EQ "equation section"
    Name name "eq or ieq (initial)";
    list<SCode.Equation> e;
  end EQ;
  
  record OT "optimization"
    list<SCode.ConstraintSection> constrainLst;
    list<Absyn.NamedArg> clsAttrs;
  end OT;
  
  record ED "external declaration"
    SCode.ExternalDecl ed;
  end ED;
  
  record FS "for iterators scope"
    Absyn.ForIterators fis;
  end FS;
  
  record FI "for iterator"
    Absyn.ForIterator fi;
  end FI;
  
  record MS "match scope"
    Absyn.Exp e;
  end MS;

  record MO "mod"
    SCode.Mod m;
  end MO;
    
  record EXP "binding, condition, array dim, etc"
    String name "what is the expression for";
    Absyn.Exp e;
  end EXP;

  record CR "component reference"
    Absyn.ComponentRef r;
  end CR;

  record DIMS "dimensions"
    String name "what are the dimensions for, type or component";
    Absyn.ArrayDim dims;
  end DIMS;

  record CC "constrainedby class"
    SCode.ConstrainClass cc;
  end CC;

  record REF "reference node"
    Ref target;
  end REF;
  
  record CLONE "clone node"
    Ref target;
  end CLONE;

  record ND "no data"
  end ND;

end Data;

type Refs = list<Ref>;
type Parents = Refs;
type Scope = Refs;
type Children = CAvlTree;

public type CAvlKey = Name;
public type CAvlValue = Ref;

uniontype CAvlTree "The binary tree data structure for children"
  record CAVLTREENODE
    Option<CAvlTreeValue> value "Value" ;
    Integer height "heigth of tree, used for balancing";
    Option<CAvlTree> left "left subtree" ;
    Option<CAvlTree> right "right subtree" ;
  end CAVLTREENODE;
end CAvlTree;

uniontype CAvlTreeValue "Each node in the binary tree can have a value associated with it."
  record CAVLTREEVALUE
    CAvlKey key "Key" ;
    CAvlValue value "Value" ;
  end CAVLTREEVALUE;
end CAvlTreeValue;

constant CAvlTree emptyCAvlTree = CAVLTREENODE(NONE(),0,NONE(),NONE());
  
uniontype Kind
  record USERDEFINED end USERDEFINED;
  record BUILTIN end BUILTIN;
  record BASIC_TYPE end BASIC_TYPE;
end Kind;

uniontype Status
"Used to distinguish between different phases of the instantiation of a component
A component is first added to node untyped. It can thereafter be instantiated to get its type
and finally instantiated to produce the DAE. These three states are indicated by this datatype."

  record S_UNTYPED "Untyped variables, initially added to env"
  end S_UNTYPED;

  record S_TYPED "Typed variables, when instantiation to get type has been performed"
  end S_TYPED;

  record S_DAE "Typed variables that also have been instantiated to generate dae. Required to distinguish
                  between typed variables without DAE to know when to skip multiply declared dae elements"
  end S_DAE;
end Status;

// ************************ FVisit structures ***************************
// ************************ FVisit structures ***************************
// ************************ FVisit structures ***************************
// ************************ FVisit structures ***************************

uniontype Visit "Visit Node Info"
  record VN "Visit Node Info"
    Ref ref "which node it is";
    Seq seq "order in which was visited";
  end VN;
end Visit;

uniontype Visited "Visited structure is an AvlTree Id <-> Visit"
  record V 
    VAvlTree tree;
    Next next "the next visit node id";
  end V;
end Visited;

public type VAvlKey = Id;
public type VAvlValue = Visit;

uniontype VAvlTree "The binary tree data structure for visited"
  record VAVLTREENODE
    Option<VAvlTreeValue> value "Value" ;
    Integer height "heigth of tree, used for balancing";
    Option<VAvlTree> left "left subtree" ;
    Option<VAvlTree> right "right subtree" ;
  end VAVLTREENODE;
end VAvlTree;

uniontype VAvlTreeValue "Each node in the binary tree can have a value associated with it."
  record VAVLTREEVALUE
    VAvlKey key "Key" ;
    VAvlValue value "Value" ;
  end VAVLTREEVALUE;
end VAvlTreeValue;

constant VAvlTree emptyVAvlTree = VAVLTREENODE(NONE(),0,NONE(),NONE());

// ************************ FGraph structures ***************************
// ************************ FGraph structures ***************************
// ************************ FGraph structures ***************************
// ************************ FGraph structures ***************************


constant Absyn.Path dummyTopModel = Absyn.IDENT("$EMPTY"); 
constant Extra dummyExtra = EXTRA(dummyTopModel);

constant String forScopeName="$for loop scope$" "a unique scope used in for equations";
constant String forIterScopeName="$foriter loop scope$" "a unique scope used in for iterators";
constant String parForScopeName="$pafor loop scope$" "a unique scope used in parfor loops";
constant String parForIterScopeName="$parforiter loop scope$" "a unique scope used in parfor iterators";
constant String matchScopeName="$match scope$" "a unique scope used by match expressions";
constant String caseScopeName="$case scope$" "a unique scope used by match expressions; to be removed when local decls are deprecated";
constant list<String> implicitScopeNames={forScopeName,forIterScopeName,parForScopeName,parForIterScopeName,matchScopeName,caseScopeName};
 
uniontype Extra "propagate more info into env if needed"
  record EXTRA "propagate more info into env if needed"
    Absyn.Path topModel;
  end EXTRA;
end Extra;
  
uniontype Graph
  record G
    Ref top;
    Visited visited;
    Extra extra;
    Next next "next node id for this graph";
  end G;
end Graph;


public constant Id firstId = 0; 

public function next
  input Next inext;
  output Next onext;
algorithm
  onext := inext + 1;
end next;

end FCore;
