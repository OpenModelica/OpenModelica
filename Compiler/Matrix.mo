package Matrix  "
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

 Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

 Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  
  file:	 Matrix.mo
  module:      Matrix
  description: Matrix data structure and operations
"
public import Absyn;
public import Util;

// Data structure for a pattern of the form path=pattern
public 
uniontype RenamedPat "The `RenamedPat\' datatype"
  record RP_INTEGER
    Absyn.Ident var;
    Integer value "value" ;
  end RP_INTEGER;
  
  record RP_REAL
    Absyn.Ident var;
    Real value "value" ;
  end RP_REAL;
  
  record RP_CREF
    Absyn.Ident var;
    Absyn.Ident compRef;
    //  Absyn.ComponentRef componentReg "componentReg" ;
  end RP_CREF;
  
  record RP_STRING
    Absyn.Ident var;
    String value "value" ;
  end RP_STRING;
  
  record RP_BOOL
    Absyn.Ident var;
    Boolean value "value Binary operations, e.g. ab" ;
  end RP_BOOL;
  
  record RP_CALL
    Absyn.Ident var;
    Absyn.ComponentRef function_ "function" ;
    RenamedPatList functionArgs "functionArgs Array construction using \'{\',\'}\' or \'array\'" ;
  end RP_CALL;
  
  record RP_TUPLE
    Absyn.Ident var;
    list<RenamedPat> expressions "expressions array access operator for last element, e.g. a{end}:=1;" ;
  end RP_TUPLE;
  
  // MetaModelica expression follows!
  record RP_CONS
    Absyn.Ident var;
    RenamedPat head " head of the list ";
    RenamedPat rest " rest of the list ";
  end RP_CONS;

  record RP_WILDCARD  
    Absyn.Ident lhsVar;
  end RP_WILDCARD;
  
  record RP_EMPTYLIST 
    Absyn.Ident var; 
  end RP_EMPTYLIST;
  
end RenamedPat;

type RenamedPatList = list<RenamedPat>;

// Datastructure for the righthand sides in a matchcontinue expression
public
uniontype RightHandSide
  
  record RIGHTHANDSIDE
    list<Absyn.ElementItem> localDecls;
    list<Absyn.EquationItem> equations;
    Absyn.Exp result; 
    Integer numberOfCase;
  end RIGHTHANDSIDE;
  
  // We use this one in the pattern matching so that we do not have
  // to carry around a lot of code all the time
  record RIGHTHANDLIGHT 
    Integer numberOfCase; 
  end RIGHTHANDLIGHT;
end RightHandSide;

type RenamedPatVec = RenamedPat[:];
type RenamedPatList = list<RenamedPat>;
type RenamedPatMatrix = RenamedPatList[:];
type RenamedPatMatrix2 = list<RenamedPatList>;  
type IndexVector = list<Integer>;
type RightHandVector = RightHandSide[:]; 
type RightHandList = list<RightHandSide>;


public function patternsFromCol "function: patternsFromCol
	author: KS
	Selects patterns from a column according to the indices in the index vector
"
  input RenamedPatMatrix patMat;
  input IndexVector indices;
  input Integer colNum;
  output RenamedPatList outList;
algorithm
  outList := patternsFromColHelper(patMat[colNum],indices,{});
end patternsFromCol;


public function patternsFromColHelper "function: patternsFromColHelper
	author: KS
	Recursive helper function to patternsFromCol
"
  input RenamedPatList patList;
  input IndexVector indices;
  input RenamedPatList accPatList;
  output RenamedPatList outPatVec;
algorithm  
  outPatVec := 
  matchcontinue (patList,indices,accPatList)
    local
      RenamedPatList localAccPatList;  
      Integer first;
      IndexVector rest;
      RenamedPatList localPatList;
    case (_,{},localAccPatList)
      equation then localAccPatList; 	      	    
    case (localPatList,first :: rest,localAccPatList)
      local
        RenamedPat[:] temp;
        RenamedPat temp2;
      equation
        temp = listArray(localPatList);
        temp2 = temp[first];
      then patternsFromColHelper(localPatList,rest,listAppend(localAccPatList,temp2 :: {}));
  end matchcontinue;
end patternsFromColHelper;


public function patternsFromOtherCol "function: patternsFromOtherCol
	author: KS
	Selects patterns from all columns except one according to
	the indices in the index vector
"
  input RenamedPatMatrix patMat;
  input IndexVector indices;
  input Integer colNum;
  output RenamedPatMatrix outPatMat;
algorithm
  outPatMat := patternsFromOtherColHelper(1,colNum,indices,patMat,{});  
end patternsFromOtherCol;


public function patternsFromOtherColHelper "function: patternsFromOtherColHelper
	author: KS
	Recursive helper function to patternsFromOtherCol
"
  input Integer pivot;
  input Integer colNum;
  input IndexVector indices;
  input RenamedPatMatrix patMat;
  input list<RenamedPatList> accPatMat;
  output RenamedPatMatrix patList;
algorithm
  patList :=
  matchcontinue (pivot,colNum,indices,patMat,accPatMat)
    local
      Integer localPivot;
      Integer localColNum;
      IndexVector localIndices;
      RenamedPatMatrix localPatMat;
      list<RenamedPatList> localAccPatMat;
    case (localPivot,_,_,localPatMat,localAccPatMat)
      equation 
        true = (localPivot > arrayLength(localPatMat));
      then listArray(localAccPatMat);
    case (localPivot,localColNum,localIndices,localPatMat,localAccPatMat)
      equation
        true = (localPivot == localColNum);
      then patternsFromOtherColHelper(localPivot+1,localColNum,localIndices,localPatMat,localAccPatMat);        
    case (localPivot,localColNum,localIndices,localPatMat,localAccPatMat)
      local
        RenamedPatList patternsFromThisCol;
      equation
        patternsFromThisCol = patternsFromColHelper(localPatMat[localPivot],localIndices,{});
      then patternsFromOtherColHelper(localPivot+1,localColNum,localIndices,localPatMat,
        listAppend(localAccPatMat,cons(patternsFromThisCol,{})));  
  end matchcontinue;
end patternsFromOtherColHelper;


public function appendMatrices "function: appendMatrices
	author: KS
	Appends two matrices with the same number of rows
"
  input RenamedPatMatrix2 patMat1;
  input RenamedPatMatrix2 patMat2;
  output RenamedPatMatrix2 outPatMat;
algorithm
  outPatMat := listAppend(patMat1,patMat2);
end appendMatrices;

public function firstRow "function: firstRow
	author: KS
	Selects the first row of a RenamedPat matrix and returns it as a list.
"
  input RenamedPatMatrix2 patMat;
  input RenamedPatList accList;
  output RenamedPatList outList;
algorithm
  outList :=
  matchcontinue (patMat,accList)
    local
      RenamedPatList localAccList;
    case ({},localAccList) equation then localAccList;
    case ((first :: _) :: rest,localAccList)
      local
        RenamedPat first;
        list<RenamedPatList> rest;
        RenamedPatList patList;
      equation 
        patList = firstRow(rest,listAppend(localAccList,Util.listCreate(first))); 
      then patList;
  end matchcontinue;
end firstRow;


public function removeFirstRow "function: removeFirstRow
	author: KS
	Removes the first row from a matrix and returns the matrix with 
	the first row removed
"
  input RenamedPatMatrix2 patMat;
  input RenamedPatMatrix2 accPatMat;
  output RenamedPatMatrix2 outPatMat;
algorithm
  outPatMat :=
  matchcontinue (patMat,accPatMat)
    local
      list<RenamedPatList> localAccPatMat;
    case (localPatMat,{})
      local
        RenamedPatMatrix2 localPatMat;
        list<RenamedPat> listTemp;
      equation
        listTemp = Util.listFirst(localPatMat);
        true = (listLength(listTemp) == 1);
      then {};      
    case ({},localAccPatMat) 
      equation 
      then localAccPatMat;    
    case ((_ :: restFirst) :: rest,localAccPatMat) 
      local
        list<RenamedPatList> rest;
        RenamedPatList restFirst;
        RenamedPatMatrix2 temp;
      equation 
        localAccPatMat = listAppend(localAccPatMat,restFirst :: {});
        temp = removeFirstRow(rest,localAccPatMat);
      then temp;
  end matchcontinue;
end removeFirstRow;

public function printMatrix "function: printMatrix
	author: KS
"
  input RenamedPatMatrix2 patMat;
algorithm
  _ :=
  matchcontinue (patMat)
    case ({}) equation then ();  
    case (first :: rest)
      local
        RenamedPatList first;
        RenamedPatMatrix2 rest;
      equation
        printList(first);
        printMatrix(rest);
      then (); 
  end matchcontinue;             
end printMatrix;

public function matrixFix "function: matrixFix
	author: KS
"
  input RenamedPatMatrix2 inMat;
  output RenamedPatMatrix2 outAccMat;
algorithm
  outAccMat :=
  matchcontinue(inMat)
    case ({}) equation then {};
    case ({} :: {}) equation then {};
    case (first :: rest)
      local
        RenamedPatList first;
        RenamedPatMatrix2 rest,temp;  
      equation
        temp = matrixFix(rest);
        temp = first :: temp;
      then temp;           
  end matchcontinue;
end matrixFix;

public function printList "function: printList
	author: KS
"
  input RenamedPatList inList;
algorithm
  _ :=
  matchcontinue (inList)
    case ({}) equation then ();
    case (first :: rest) 
      local
        RenamedPat first;
        RenamedPatList rest;
      equation
        printPattern(first);
        print("\n");
        printList(rest);
      then ();
  end matchcontinue;
end printList;

public function printPattern "function: printPattern
	author: KS
"
  input RenamedPat inPat;
algorithm
  _ :=
  matchcontinue (inPat)
    case(RP_INTEGER(var,value))
      local
        Absyn.Ident var;
        Integer value;
      equation
        print("Pathvar:");
        print(var);
        print(":");
        print(intString(value));
      then ();   
    case(RP_BOOL(var,value))
      local
        Absyn.Ident var;
        Boolean value;
      equation
        print("Pathvar:");
        print(var);
        print(":");
        print("BOOL");
      then ();   
    case(RP_STRING(var,value))
      local
        Absyn.Ident var;
        String value;
      equation
        print("Pathvar:");
        print(var);
        print(":");
        print(value);
        print("\n");
      then ();
    case(RP_CONS(var,head,rest))     
      local
        RenamedPat head;
        RenamedPat rest;
        Absyn.Ident var;
      equation
        print("Pathvar:");
        print(var);
        print(" CONS:");
        printPattern(head);
        print(",");
        printPattern(rest);
        print("\n");
      then ();
    case(RP_WILDCARD(var))     
      local
        Absyn.Ident var;
      equation
        print("Pathvar:");
        print(var);
        print(" WILDCARD");
        print("\n");
      then ();
    case(RP_EMPTYLIST(var))     
      local
        Absyn.Ident var;
      equation
        print("Pathvar:");
        print(var);
        print(" EMPTY LIST");
        print("\n");
      then ();
    case (_) 
      equation
        print("Printing of pattern not implemented");
      then ();             
  end matchcontinue;
end printPattern;

public function getRightHandSideNumbers "function: getRightHandSideNumbers"
  input RightHandList inList;
  input list<Integer> accList; 
  output list<Integer> outList;
algorithm
  outList := 
  matchcontinue (inList,accList) 
    local
      list<Integer> localAccList; 
    case ({},localAccList) then localAccList; 
    case (RIGHTHANDLIGHT(n) :: rest,localAccList) 
      local  
        Integer n; 
        RightHandList rest;
      equation  
        localAccList = listAppend(localAccList,{n}); 
        localAccList = getRightHandSideNumbers(rest,localAccList);
      then localAccList; 
  end matchcontinue;  
end getRightHandSideNumbers;  
  
end Matrix;