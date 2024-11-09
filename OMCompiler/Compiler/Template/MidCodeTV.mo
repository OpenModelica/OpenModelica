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

interface package MidCodeTV

package MidCode

uniontype Program
  record PROGRAM
    String name;
    list<Function> functions;
    list<Record> records;
  end PROGRAM;
end Program;

uniontype Record
   " A record in MidCode IR may either be a full definition
     or a declaration"
  record RECORD_DEFINITION
    String name;
    String definitionPath;
    list<MidCode.Var> variables;
  end RECORD_DEFINITION;
  record RECORD_DECLARATION
    String definitionPath;
    String encodedPath;
    list<String> fieldNames;
  end RECORD_DECLARATION;
end Record;

uniontype Var
  record VAR
    String name;
    DAE.Type ty;
    Boolean volatile;
  end VAR;
end Var;

uniontype VarBuf
  /*
  A MidCode variable containing a jmp_buf for longjmp.
  */
  record VARBUF
    String name;
  end VARBUF;
end VarBuf;

uniontype VarBufPtr
  /*
  A MidCode variable containing a jmp_buf pointer for longjmp.
  */
  record VARBUFPTR
    String name;
  end VARBUFPTR;
end VarBufPtr;

uniontype OutVar
  record OUT_VAR
    Var var;
  end OUT_VAR;
  record OUT_WILD end OUT_WILD;
end OutVar;


uniontype Function
  record FUNCTION
    Absyn.Path name;
    list<Var> locals;
    list<VarBuf> localBufs; // jmb_buf for longjmp
    list<VarBufPtr> localBufPtrs; // jmb_buf pointers for longjmp
    list<Var> inputs;
    list<Var> outputs;
    list<Block> body;
    Integer entryId;
    Integer exitId;
  end FUNCTION;
end Function;

uniontype Block
  record BLOCK
  "Basic block.
   No control flow within block.
   Can branch or jump on exit, called the block's terminator."
    Integer id;
    list<Stmt> stmts;
    Terminator terminator;
  end BLOCK;
end Block;

uniontype Terminator
  record GOTO
    Integer next;
  end GOTO;

  record BRANCH
    Var condition;
    Integer onTrue;
    Integer onFalse;
  end BRANCH;

  record CALL
    Absyn.Path func;
    Boolean builtin;
    list<Var> inputs;
    list<OutVar> outputs;
    Integer next;
  end CALL;

  record RETURN
  end RETURN;

  record SWITCH
    Var condition;
    list<tuple<Integer,Integer>> cases;
  end SWITCH;

  record LONGJMP "used for fail() stmts"
  end LONGJMP;

  record PUSHJMP "used for match-continue fail() handling"
    VarBufPtr old_buf "where to save old jmp_buf";
    VarBuf new_buf "what to use as new jmp_buf";
    Integer next "where to goto next and the setjmp target";
  end PUSHJMP;

  /* POPJMP does not cause control flow but
     if it is a terminator to simplify matching
     with their respective PUSHJMPS.
  */
  record POPJMP "used for match-continue fail() handling"
    VarBufPtr old_buf "what to reset to";
    Integer next;
  end POPJMP;

  record ASSERT
    Var condition;
    Var message;
    Var level;
    Integer next;
  end ASSERT;

  record TERMINATE
    Var message;
  end TERMINATE;

end Terminator;

uniontype Stmt
  record NOP
  end NOP;

  record ASSIGN
    Var dest;
    RValue src;
  end ASSIGN;

  record ASSIGN_INDEX
    Var dest;
    Var index;
    RValue src;
  end ASSIGN_INDEX;
end Stmt;

uniontype RValue
  record VARIABLE
    Var src;
  end VARIABLE;

  record UNARYOP
    UnaryOp op;
    Var src;
  end UNARYOP;

  record BINARYOP
    BinaryOp op;
    Var lsrc;
    Var rsrc;
  end BINARYOP;

  record LITERALINTEGER
    Integer value;
  end LITERALINTEGER;

  record LITERALREAL
    Real value;
  end LITERALREAL;

  record LITERALBOOLEAN
    Boolean value;
  end LITERALBOOLEAN;

  record LITERALSTRING
    String value;
  end LITERALSTRING;

  record LITERALMETATYPE
    list<Var> elements;
    DAE.Type ty;
  end LITERALMETATYPE;

  record UNIONTYPEVARIANT
    Var src;
  end UNIONTYPEVARIANT;

  record ISSOME
    Var src;
  end ISSOME;

  record ISCONS
    Var src;
  end ISCONS;

  record METAFIELD "get value from metamodelica object"
    Var src;
    Integer index;
    DAE.Type ty "type of value";
  end METAFIELD;
end RValue;

uniontype UnaryOp
  record MOVE end MOVE;
  record UMINUS end UMINUS;
  record NOT end NOT;
  record UNBOX end UNBOX;
  record BOX end BOX;
end UnaryOp;

uniontype BinaryOp
  record ADD end ADD;
  record SUB end SUB;
  record MUL end MUL;
  record DIV end DIV;
  record POW end POW;
  record LESS end LESS;
  record LESSEQ end LESSEQ;
  record GREATER end GREATER;
  record GREATEREQ end GREATEREQ;
  record EQUAL end EQUAL;
  record NEQUAL end NEQUAL;
end BinaryOp;

end MidCode;

end MidCodeTV;
