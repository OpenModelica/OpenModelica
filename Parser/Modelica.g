/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
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
 * from Linkoping University, either from the above address,
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
grammar Modelica;

options {
  ASTLabelType = pANTLR3_BASE_TREE;
  language = C;
}

tokens {
  T_ALGORITHM  = 'algorithm'  ;
  T_AND    = 'and'    ;
  T_ANNOTATION  = 'annotation'  ;
  BLOCK    = 'block'  ;
  CODE    = '$Code'  ;
  CLASS    = 'class'  ;
  CONNECT  = 'connect'  ;
  CONNECTOR  = 'connector'  ;
  CONSTANT  = 'constant'  ;
  DISCRETE  = 'discrete'  ;
  DER           = 'der'   ;
  DEFINEUNIT    = 'defineunit'  ;
  EACH    = 'each'  ;
  ELSE    = 'else'  ;
  ELSEIF  = 'elseif'  ;
  ELSEWHEN  = 'elsewhen'  ;
  T_END    = 'end'    ;
  ENUMERATION  = 'enumeration'  ;
  EQUATION  = 'equation'  ;
  ENCAPSULATED  = 'encapsulated';
  EXPANDABLE  = 'expandable'  ;
  EXTENDS  = 'extends'     ;
  CONSTRAINEDBY = 'constrainedby' ;
  EXTERNAL  = 'external'  ;
  T_FALSE  = 'false'  ;
  FINAL    = 'final'  ;
  FLOW    = 'flow'  ;
  FOR    = 'for'    ;
  FUNCTION  = 'function'  ;
  IF    = 'if'    ;
  IMPORT  = 'import'  ;
  T_IN    = 'in'    ;
  INITIAL  = 'initial'  ;
  INNER    = 'inner'  ;
  T_INPUT  = 'input'  ;
  LOOP    = 'loop'  ;
  MODEL    = 'model'  ;
  T_NOT    = 'not'    ;
  T_OUTER  = 'outer'  ;
  OPERATOR  = 'operator'; 
  OVERLOAD  = 'overload'  ;
  T_OR    = 'or'    ;
  T_OUTPUT  = 'output'  ;
  PACKAGE  = 'package'  ;
  PARAMETER  = 'parameter'  ;
  PARTIAL  = 'partial'  ;
  PROTECTED  = 'protected'  ;
  PUBLIC  = 'public'  ;
  RECORD  = 'record'  ;
  REDECLARE  = 'redeclare'  ;
  REPLACEABLE  = 'replaceable'  ;
  RESULTS  = 'results'  ;
  THEN    = 'then'  ;
  T_TRUE  = 'true'  ;
  TYPE    = 'type'  ;
  UNSIGNED_REAL  = 'unsigned_real';
  WHEN    = 'when'  ;
  WHILE    = 'while'  ;
  WITHIN  = 'within'   ;
  RETURN  = 'return'  ;
  BREAK    = 'break'  ;
  STREAM  = 'stream'  ; /* for Modelica 3.1 stream connectors */  
  /* MetaModelica keywords. I guess not all are needed here. */
  AS    = 'as'            ;
  CASE    = 'case'    ;
  EQUALITY  = 'equality'      ;
  FAILURE  = 'failure'       ;
  LOCAL    = 'local'    ;
  MATCH    = 'match'    ;
  MATCHCONTINUE  = 'matchcontinue' ;
  UNIONTYPE  = 'uniontype'    ;
  WILD    = '_'      ;
  SUBTYPEOF     = 'subtypeof'     ;
  COLONCOLON ;
  
  // ---------
  // Operators
  // ---------
  
  DOT    = '.'           ;  
  LPAR    = '('    ;
  RPAR    = ')'    ;
  LBRACK  = '['    ;
  RBRACK  = ']'    ;
  LBRACE  = '{'    ;
  RBRACE  = '}'    ;
  EQUALS  = '='    ;
  ASSIGN  = ':='    ;
  COMMA    = ','    ;
  COLON    = ':'    ;
  SEMICOLON  = ';'    ;
  /* elementwise operators */  
  PLUS_EW       = '.+'    ; /* Modelica 3.0 */
  MINUS_EW      = '.-'       ; /* Modelica 3.0 */    
  STAR_EW       = '.*'       ; /* Modelica 3.0 */
  SLASH_EW      = './'    ; /* Modelica 3.0 */  
  POWER_EW      = '.^'     ; /* Modelica 3.0 */
  
  /* MetaModelica operators */
  COLONCOLON    = '::'    ;
  MOD    = '%'   ;
  
  // parser tokens 
ALGORITHM_STATEMENT;
ARGUMENT_LIST;
CLASS_DEFINITION;
CLASS_EXTENDS ;
CLASS_MODIFICATION;
CODE_EXPRESSION;
CODE_MODIFICATION;
CODE_ELEMENT;
CODE_EQUATION;
CODE_INITIALEQUATION;
CODE_ALGORITHM;
CODE_INITIALALGORITHM;
COMMENT;
COMPONENT_DEFINITION;
DECLARATION  ;
DEFINITION ;
ENUMERATION_LITERAL;
ELEMENT    ;
ELEMENT_MODIFICATION    ;
ELEMENT_REDECLARATION  ;
EQUATION_STATEMENT;
EXTERNAL_ANNOTATION ;
INITIAL_EQUATION;
INITIAL_ALGORITHM;
IMPORT_DEFINITION;
IDENT_LIST;
EXPRESSION_LIST;
EXTERNAL_FUNCTION_CALL;
FOR_INDICES ;
FOR_ITERATOR ;
FUNCTION_CALL    ;
INITIAL_FUNCTION_CALL    ;
FUNCTION_ARGUMENTS;
NAMED_ARGUMENTS;
QUALIFIED;
RANGE2    ;
RANGE3    ;
STORED_DEFINITION ;
STRING_COMMENT;
UNARY_MINUS  ;
UNARY_PLUS  ;
UNARY_MINUS_EW ;
UNARY_PLUS_EW ;
UNQUALIFIED;
FLAT_IDENT;
TYPE_LIST;
EMPTY;
OPERATOR;
}


@includes {
  #include <stdio.h>
  #include "rml.h"
  #include "Absyn.h"
  /* Eat anything so we can test code gen */
  void* mk_box_eat_all(int ix, ...);
  #define false 0
  #define true 1
  #define or_nil(x) (x != 0 ? x : mk_nil())
  #define mk_some_or_none(x) (x ? mk_some(x) : mk_none())
  #define mk_tuple2(x1,x2) mk_box2(0,x1,x2)
  #define make_redeclare_keywords(replaceable,redeclare) (replaceable && redeclare ? Absyn__REDECLARE_5fREPLACEABLE : replaceable ? Absyn__REPLACEABLE : redeclare ? Absyn__REDECLARE : NULL)
  #define make_inner_outer(i,o) (i && o ? Absyn__INNEROUTER : i ? Absyn__INNER : o ? Absyn__OUTER : Absyn__UNSPECIFIED)
  #define mk_bcon(x) (x ? RML_TRUE : RML_FALSE)
#if 0
  #define mk_scon(x) x
  #define mk_rcon(x) mk_box_eat_all(0,x)
  #define mk_box0(x1) mk_box_eat_all(x1)
  #define mk_box1(x1,x2) mk_box_eat_all(x1,x2)
  #define mk_box2(x1,x2,x3) mk_box_eat_all(x1,x2,x3)
  #define mk_box3(x1,x2,x3,x4) mk_box_eat_all(x1,x2,x3,x4)
  #define mk_box4(x1,x2,x3,x4,x5) mk_box_eat_all(x1,x2,x3,x4,x5)
  #define mk_box5(x1,x2,x3,x4,x5,x6) mk_box_eat_all(x1,x2,x3,x4,x5,x6)
  #define mk_box6(x1,x2,x3,x4,x5,x6,x7) mk_box_eat_all(x1,x2,x3,x4,x5,x6,x7)
  #define mk_box7(x1,x2,x3,x4,x5,x6,x7,x8) mk_box_eat_all(x1,x2,x3,x4,x5,x6,x7,x8)
  #define mk_box8(x1,x2,x3,x4,x5,x6,x7,x8,x9) mk_box_eat_all(x1,x2,x3,x4,x5,x6,x7,x8,x9)
  #define mk_box9(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10) mk_box_eat_all(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10)
  #define mk_cons(x1,x2) mk_box_eat_all(0,x1,x2)
  #define mk_some(x1) mk_box_eat_all(0,x1)
  #define mk_none(void) NULL
  #define mk_nil() NULL
  #undef RML_GETHDR
  #define RML_GETHDR(x) 0
  #undef RML_STRUCTHDR
  #define RML_STRUCTHDR(x,y) 0
#endif
  #define token_to_scon(tok) mk_scon(tok->getText(tok)->chars)
  #define metamodelica_enabled(void) 0
  #define code_expressions_enabled(void) 0
  #define NYI(void) 0
  #define INFO(start,stop) Absyn__INFO(file, isReadOnly, mk_icon(start->line), mk_icon(start->charPosition), mk_icon(stop->line), mk_icon(stop->charPosition), Absyn__TIMESTAMP(mk_rcon(0),mk_rcon(0)))
  typedef unsigned char bool;
}

@members
{
  void* file = "ENTER FILENAME HERE";
  void* isReadOnly = RML_FALSE;
  void* mk_box_eat_all(int ix, ...) {return NULL;}
  double getCurrentTime(void)
    {             
      time_t t;
      time( &t );
      return difftime(t, 0);
    }
}




/*------------------------------------------------------------------
 * LEXER RULES
 *------------------------------------------------------------------*/

STAR    : '*'('.')?         ;
MINUS    : '-'('.')?          ;
PLUS    : '+'('.'|'&')?        ; 
LESS    : '<'('.')?          ;
LESSEQ    : '<='('.')?        ;
LESSGT    : '!='('.')?|'<>'('.')?    ;
GREATER    : '>'('.')?          ;
GREATEREQ  : '>='('.')?        ;
EQEQ    : '=='('.'|'&')?      ;
POWER    : '^'('.')?          ;
SLASH    : '/'('.')?          ;

WS : ( ' ' | '\t' | NL )+ { $channel=HIDDEN; }
  ;
  
LINE_COMMENT
    : '//' ( ~('\r'|'\n')* ) (NL|EOF) { $channel=HIDDEN; }
    ;  

ML_COMMENT
    :   '/*' (options {greedy=false;} : .)* '*/' { $channel=HIDDEN;  }
    ;

fragment 
NL: (('\r')? '\n');

IDENT :
       ('_' {  $type = WILD; } | NONDIGIT { $type = IDENT; })
       (('_' | NONDIGIT | DIGIT) { $type = IDENT; })*
    | (QIDENT { $type = IDENT; })
    ;

fragment
QIDENT :
         '\'' (QCHAR | SESCAPE) (QCHAR | SESCAPE)* '\'' ;

fragment
QCHAR :  NL  | '\t' | ~('\n' | '\t' | '\r' | '\\' | '\'');

fragment
NONDIGIT :   ('a'..'z' | 'A'..'Z');

fragment
DIGIT :
  '0'..'9'
  ;

fragment
EXPONENT :
  ('e'|'E') ('+' | '-')? (DIGIT)+
  ;


UNSIGNED_INTEGER :
    (DIGIT)+ ('.' (DIGIT)* { $type = UNSIGNED_REAL; } )? (EXPONENT { $type = UNSIGNED_REAL; } )?
  | ('.' { $type = DOT; } )
      ( (DIGIT)+ { $type = UNSIGNED_REAL; } (EXPONENT { $type = UNSIGNED_REAL; } )?
         | /* Modelica 3.0 element-wise operators! */
         (('+' { $type = PLUS_EW; }) 
          |('-' { $type = MINUS_EW; }) 
          |('*' { $type = STAR_EW; }) 
          |('/' { $type = SLASH_EW; }) 
          |('^' { $type = POWER_EW; })
          )?
      )
  ;

STRING : '"' STRING_GUTS '"'
       {SETTEXT($STRING_GUTS.text);};

fragment
STRING_GUTS: (SCHAR | SESCAPE)*
       ;

fragment
SCHAR :  NL | '\t' | ~('\n' | '\t' | '\r' | '\\' | '"');

fragment
SESCAPE : '\\' ('\\' | '"' | '\'' | '?' | 'a' | 'b' | 'f' | 'n' | 'r' | 't' | 'v');


/*------------------------------------------------------------------
 * PARSER RULES
 *------------------------------------------------------------------*/

stored_definition returns [void* ast] :
  (within=within_clause SEMICOLON)?
  cl=class_definition_list?
    {
      ast = Absyn__PROGRAM(or_nil(cl), within ? within : Absyn__TOP, Absyn__TIMESTAMP(mk_rcon(0.0), mk_rcon(getCurrentTime())));
    }
  ;

within_clause returns [void* ast] :
    WITHIN (name=name_path)? {ast = Absyn__WITHIN(name);}
  ;

class_definition_list returns [void* ast] :
  ((f=FINAL)? cd=class_definition[f != NULL] SEMICOLON) cl=class_definition_list?
    {
      ast = mk_cons(cd.ast, or_nil(cl));
    }
  ;

class_definition [bool final] returns [void* ast]
@declarations {
  void* ast = 0;
  void* name = 0;
}
  :
  ((e=ENCAPSULATED)? (p=PARTIAL)? class_type class_specifier[&name])
    {
      ast = Absyn__CLASS(name, mk_bcon(p), mk_bcon(final), mk_bcon(e),
                         class_type, class_specifier, INFO($start,$stop));
    }
  ;

class_type returns [void* ast] :
  ( CLASS { ast = Absyn__R_5fCLASS; }
  | MODEL { ast = Absyn__R_5fMODEL; }
  | RECORD { ast = Absyn__R_5fRECORD; }
  | BLOCK { ast = Absyn__R_5fBLOCK; }
  | ( e=EXPANDABLE )? CONNECTOR { ast = e ? Absyn__R_5fEXP_5fCONNECTOR : Absyn__R_5fCONNECTOR; }
  | TYPE { ast = Absyn__R_5fTYPE; }
  | PACKAGE { ast = Absyn__R_5fPACKAGE; }
  | FUNCTION { ast = Absyn__R_5fFUNCTION; } 
  | UNIONTYPE { ast = Absyn__R_5fUNIONTYPE; }
  | OPERATOR (f=FUNCTION | r=RECORD)? 
          { 
            ast = f ? Absyn__R_5fOPERATOR_5fFUNCTION : 
                  r ? Absyn__R_5fOPERATOR_5fRECORD : 
                  Absyn__R_5fOPERATOR;
          }
  )
  ;

class_specifier [void** name] returns [void* ast] :
        i1=IDENT {*name = token_to_scon(i1);} spec=class_specifier2 {ast = spec;}
    |   EXTENDS i1=IDENT {*name = token_to_scon(i1);} (class_modification)? string_comment composition T_END i2=IDENT
        ;

class_specifier2 returns [void* ast] :
( 
  cmt=string_comment c=composition T_END i2=IDENT { ast = Absyn__PARTS(c, mk_some_or_none(cmt)); }
  /* { fprintf(stderr,"position composition for \%s -> \%d\n", $i2.text->chars, $c->getLine()); } */
| EQUALS base_prefix type_specifier ( cm=class_modification )? cmt=comment
  {
  }
| EQUALS cs=enumeration {ast=cs;}
| EQUALS cs=pder {ast=cs;}
| EQUALS cs=overloading {ast=cs;}
| SUBTYPEOF type_specifier
)
;

pder returns [void* ast] :
  DER LPAR func=name_path COMMA var_lst=ident_list RPAR cmt=comment
  {
    ast = Absyn__PDER(func, var_lst, mk_some_or_none(cmt));
  }
  ;

ident_list returns [void* ast]:
  i=IDENT (COMMA il=ident_list)?
    {
      ast = mk_cons(i, or_nil(il));
    }
  ;


overloading returns [void* ast] :
  OVERLOAD LPAR name_list RPAR cmt=comment
    {
      ast = Absyn__OVERLOAD(name_list, mk_some_or_none(cmt));
    }
  ;

base_prefix :
  type_prefix
  ;

name_list returns [void* ast] :
  n=name_path (COMMA nl=name_list)?
    {
      ast = mk_cons(n, or_nil(nl));
    }
  ;

enumeration returns [void* ast] :
  ENUMERATION LPAR (el=enum_list | c=COLON ) RPAR cmt=comment
    {
      if (c) {
        ast = Absyn__ENUMERATION(Absyn__ENUM_5fCOLON, mk_some_or_none(cmt));
      } else {
        ast = Absyn__ENUMERATION(Absyn__ENUMLITERALS(el), mk_some_or_none(cmt));
      }
    }
  ;

enum_list returns [void* ast] :
  e=enumeration_literal ( COMMA el=enum_list )? { ast = mk_cons(e, or_nil(el)); }
  ;

enumeration_literal returns [void* ast] :
  i1=IDENT c1=comment { ast = Absyn__ENUMLITERAL(token_to_scon(i1),mk_some_or_none(c1)); }
  ;

composition returns [void* ast] :
  el=element_list els=composition2 { ast = mk_cons(Absyn__PUBLIC(el),els); }
  ;

composition2 returns [void* ast] :
  ( ext=external_clause? {ast = or_nil(ext); }
  | ( el=public_element_list
    | el=protected_element_list
    | el=initial_equation_clause
    | el=initial_algorithm_clause
    | el=equation_clause
    | el=algorithm_clause
    ) els=composition2 {ast = mk_cons(el,els);}
  )
  ;

external_clause returns [void* ast] :
        EXTERNAL
        ( lang=language_specification )?
        ( ( retexp=component_reference EQUALS )?
          funcname=IDENT LPAR ( expl=expression_list )? RPAR )?
        ( ann1 = annotation )? SEMICOLON
        ( ann2 = external_annotation )?
          {
            ast = Absyn__EXTERNALDECL(mk_some_or_none(funcname), mk_some_or_none(lang), mk_some_or_none(retexp), or_nil(expl), mk_some_or_none(ann1));
            ast = Absyn__EXTERNAL(ast, mk_some_or_none(ann2));
          }
        ;

external_annotation returns [void* ast] :
  ann=annotation SEMICOLON {ast = ann;}
  ;

public_element_list returns [void* ast] :
  PUBLIC es=element_list {Absyn__PUBLIC(es);}
  ;

protected_element_list returns [void* ast] :
  PROTECTED es=element_list {Absyn__PROTECTED(es);}
  ;

language_specification returns [void* ast] :
  id=STRING {ast = token_to_scon(id);}
  ;

element_list returns [void* ast] :
  (((e=element {ast = Absyn__ELEMENTITEM(e.ast);} | a=annotation {ast = Absyn__ANNOTATIONITEM(a);} ) s=SEMICOLON) es=element_list)?
    {
      ast = ast ? mk_cons(ast, es) : mk_nil();
    }
  ;

element returns [void* ast] @declarations {
  void *final;
  void *innerouter;
} :
    ic=import_clause { $ast = Absyn__ELEMENT(RML_FALSE,mk_none(),Absyn__UNSPECIFIED,mk_scon("import"), ic, INFO($start,$stop), mk_none());}
  | ec=extends_clause { $ast = Absyn__ELEMENT(RML_FALSE,mk_none(),Absyn__UNSPECIFIED,mk_scon("extends"), ec, INFO($start,$stop),mk_none());}
  | du=defineunit_clause { $ast = du;}
  | (r=REDECLARE)? (f=FINAL)? (i=INNER)? (o=T_OUTER)? { final = mk_bcon(f); innerouter = make_inner_outer(i,o); }
    ( ( cdef=class_definition[f != NULL]
        {
           $ast = Absyn__ELEMENT(final, mk_some_or_none(make_redeclare_keywords(false,r)),
                                innerouter, mk_scon("??"),
                                Absyn__CLASSDEF(RML_FALSE, cdef.ast),
                                INFO($start,$stop), mk_none());
        }
      | cc=component_clause)
        {
           $ast = Absyn__ELEMENT(final, mk_some_or_none(make_redeclare_keywords(false,r)), innerouter,
                                 mk_scon("component"), cc, INFO($start, $stop), mk_none());
        }
    | (REPLACEABLE ( cdef=class_definition[f != NULL] | cc=component_clause ) constr=constraining_clause_comment? )
        {
           if (cc)
             $ast = Absyn__ELEMENT(final, mk_some_or_none(make_redeclare_keywords(true,r)), innerouter,
                                  mk_scon("replaceable component"), cc, INFO($start, $stop), mk_some_or_none(constr));
           else
             $ast = Absyn__ELEMENT(final, mk_some_or_none(make_redeclare_keywords(true,r)), innerouter,
                                  mk_scon("??"), Absyn__CLASSDEF(RML_TRUE, cdef.ast), INFO($start, $stop), mk_some_or_none(constr));
        }
    )
  ;

import_clause returns [void* ast] :
  IMPORT (imp=explicit_import_name | imp=implicit_import_name) cmt=comment
    {
      ast = Absyn__IMPORT(imp, mk_some_or_none(cmt));
    }
  ;
defineunit_clause returns [void* ast] :
  DEFINEUNIT id=IDENT (LPAR na=named_arguments RPAR)?
    {
      ast = Absyn__DEFINEUNIT(token_to_scon(id),or_nil(na));
    }
  ;

explicit_import_name returns [void* ast] :
  id=IDENT EQUALS p=name_path {ast = Absyn__NAMED_5fIMPORT(token_to_scon(id),p);}
  ;

implicit_import_name returns [void* ast]
@declarations {
  bool unqual = 0;
} :
  np=name_path_star[&unqual]
  {
    ast = unqual ? Absyn__UNQUAL_5fIMPORT(np) : Absyn__QUAL_5fIMPORT(np);
  }
;

/*
 * 2.2.3 Extends
 */

// Note that this is a minor modification of the standard by
// allowing the comment.
extends_clause returns [void* ast] :
  EXTENDS path=name_path (mod=class_modification)? (ann=annotation)? {ast = Absyn__EXTENDS(path,or_nil(mod),mk_some_or_none(ann));}
    ;

constraining_clause_comment returns [void* ast] :
  constr=constraining_clause cmt=comment {ast = Absyn__CONSTRAINCLASS(constr, mk_some_or_none(cmt));}
  ;

constraining_clause returns [void* ast] :
    EXTENDS np=name_path  (mod=class_modification)? { ast = Absyn__EXTENDS(np,or_nil(mod),mk_none()); }
  | CONSTRAINEDBY np=name_path (mod=class_modification)? { ast = Absyn__EXTENDS(np,or_nil(mod),mk_none()); }
  ;

/*
 * 2.2.4 Component clause
 */

component_clause returns [void* ast] :
  tp = type_prefix np=type_specifier clst=component_list
  ;

type_prefix :
  (FLOW|STREAM)? (DISCRETE|PARAMETER|CONSTANT)? (T_INPUT|T_OUTPUT)?
  ;

type_specifier returns [void* ast] :
  np=name_path
  (LESS ts=type_specifier_list GREATER)?
  (as=array_subscripts)?
    {
      if (ts != NULL)
        ast = Absyn__TCOMPLEX(np,ts,mk_some_or_none(as));
      else
        ast = Absyn__TPATH(np,mk_some_or_none(as));
    }
  ;

type_specifier_list returns [void* ast] :
  np1=type_specifier (COMMA np2=type_specifier)? {ast = mk_cons(np1,or_nil(np2));}
  ;

component_list returns [void* ast] :
  c=component_declaration (COMMA cs=component_list)? {ast = mk_cons(c, or_nil(cs));}
  ;

component_declaration returns [void* ast] :
  decl=declaration (cond=conditional_attribute)? cmt=comment
    {
      ast = Absyn__COMPONENTITEM(decl, mk_some_or_none(cond), mk_some_or_none(cmt));
    }
  ;

conditional_attribute returns [void* ast] :
        IF e=expression {ast = e;}
        ;

declaration returns [void* ast] :
  ( id=IDENT | id=OPERATOR ) (as=array_subscripts)? (mod=modification)?
    {
      ast = Absyn__COMPONENT(token_to_scon(id), or_nil(as), mk_some_or_none(mod));
    }
  ;

/*
 * 2.2.5 Modification
 */

modification returns [void* ast] :
  ( cm=class_modification ( EQUALS e=expression )?
  | EQUALS e=expression
  | ASSIGN e=expression
  )
    {
      ast = Absyn__CLASSMOD(or_nil(cm), mk_some_or_none(e));
    }
  ;

class_modification returns [void* ast] :
  LPAR ( as=argument_list )? RPAR {ast = or_nil(as);}
  ;

argument_list returns [void* ast] :
  a=argument ( COMMA as=argument_list )? {ast = mk_cons(a, or_nil(as));}
  ;

argument returns [void* ast] :
  ( em=element_modification_or_replaceable
  | er=element_redeclaration
  )
  ;

element_modification_or_replaceable:
        (e=EACH)? (f=FINAL)? (element_modification | element_replaceable[e != NULL,f != NULL,false])
    ;

element_modification :
  component_reference ( modification )? string_comment
  ;

element_redeclaration :
  REDECLARE (e=EACH)? (f=FINAL)?
  ( (class_definition[f != NULL] | component_clause1) | element_replaceable[e != NULL,f != NULL,true] )
  ;

element_replaceable [bool each, bool final, bool redeclare] returns [void* ast] :
  REPLACEABLE ( cd=class_definition[final] | e_spec=component_clause1 ) constr=constraining_clause_comment?
    {
      ast = Absyn__REDECLARATION(mk_bcon(final), make_redeclare_keywords(true,redeclare),
                                 each ? Absyn__EACH : Absyn__NON_5fEACH, cd.ast ? Absyn__CLASSDEF(RML_TRUE, cd.ast) : e_spec,
                                 mk_some_or_none(constr));
    }
  ;
  
component_clause1 returns [void* ast] :
  type_prefix type_specifier component_declaration1
  ;

component_declaration1 returns [void* ast] :
        declaration comment
  ;


/*
 * 2.2.6 Equations
 */

initial_equation_clause returns [void* ast] :
  { LA(2)==EQUATION }?
  INITIAL EQUATION es=equation_annotation_list {ast = Absyn__INITIALEQUATIONS(es);}
  ;

equation_clause returns [void* ast] :
  EQUATION es=equation_annotation_list {ast = Absyn__EQUATIONS(es);}
    ;

equation_annotation_list returns [void* ast] :
  { LA(1) == T_END || LA(1) == EQUATION || LA(1) == T_ALGORITHM || LA(1)==INITIAL || LA(1) == PROTECTED || LA(1) == PUBLIC }? {ast = mk_nil();}
  |
  ( eq=equation SEMICOLON {e = eq.ast;} | e=annotation SEMICOLON {e = Absyn__EQUATIONITEMANN(e);}) es=equation_annotation_list {ast = mk_cons(e,es);}
  ;

algorithm_clause returns [void* ast] :
  T_ALGORITHM as=algorithm_annotation_list {ast = Absyn__ALGORITHMS(as);}
  ;

initial_algorithm_clause returns [void* ast] :
  { LA(2)==T_ALGORITHM }?
  INITIAL T_ALGORITHM as=algorithm_annotation_list {ast = Absyn__INITIALALGORITHMS(as);}
  ;

algorithm_annotation_list returns [void* ast] :
  { LA(1) == T_END || LA(1) == EQUATION || LA(1) == T_ALGORITHM || LA(1)==INITIAL || LA(1) == PROTECTED || LA(1) == PUBLIC }? {ast = mk_nil();}
  |
  ( al=algorithm SEMICOLON {a = al.ast;} | a=annotation SEMICOLON {a = Absyn__ALGORITHMITEMANN(a);}) as=algorithm_annotation_list {ast = mk_cons(a,as);}
  ;

equation returns [void* ast] :
  ( e=equality_or_noretcall_equation   
  | e=conditional_equation_e
  | e=for_clause_e
  | e=connect_clause
  | e=when_clause_e   
  | FAILURE LPAR eq=equation RPAR { e = Absyn__EQ_5fFAILURE(eq.ast); }
  | EQUALITY LPAR e1=expression EQUALS e2=expression RPAR
    {
      e = Absyn__ALG_5fNORETCALL(Absyn__CREF_5fIDENT(mk_scon("equality"),mk_nil()),Absyn__FUNCTIONARGS(mk_cons(e1,mk_cons(e2,mk_nil())),mk_nil()));
    }
  )
  cmt=comment
    {$ast = Absyn__EQUATIONITEM(e, mk_some_or_none(cmt), INFO($start,$stop));}
  ;

algorithm returns [void* ast] :
  ( a=assign_clause_a
  | a=conditional_equation_a
  | a=for_clause_a
  | a=while_clause
  | a=when_clause_a
  | BREAK {a = Absyn__ALG_5fBREAK;}
  | RETURN {a = Absyn__ALG_5fRETURN;}
  | FAILURE LPAR al=algorithm RPAR {a = Absyn__ALG_5fFAILURE(al.ast);}
  | EQUALITY LPAR e1=expression ASSIGN e2=expression RPAR
    {
      a = Absyn__ALG_5fNORETCALL(Absyn__CREF_5fIDENT(mk_scon("equality"),mk_nil()),Absyn__FUNCTIONARGS(mk_cons(e1,mk_cons(e2,mk_nil())),mk_nil()));
    }
  )
  cmt=comment
    {$ast = Absyn__ALGORITHMITEM(a, mk_some_or_none(cmt), INFO($start,$stop));}
  ;

assign_clause_a returns [void* ast] :
  ( {!metamodelica_enabled()}?
    ( cr=component_reference
      ( (ASSIGN|EQUALS {NYI();}) e=expression {ast = Absyn__ALG_5fASSIGN(Absyn__CREF(cr),e);}
      | fc=function_call {ast = Absyn__ALG_5fNORETCALL(cr,fc);}
      )
    | LPAR es=expression_list RPAR ASSIGN
      cr=component_reference fc=function_call {ast = Absyn__ALG_5fASSIGN(Absyn__TUPLE(es),Absyn__CALL(cr,fc));} 
    )
  | {metamodelica_enabled()}? /* MetaModelica allows pattern matching on arbitrary expressions in algorithm sections... */
    e1=simple_expression
      ( (ASSIGN|EQUALS) e2=expression {ast = Absyn__ALG_5fASSIGN(e1,e2);}
      | {RML_GETHDR(e1) == RML_STRUCTHDR(2, Absyn__CALL_3dBOX2)}? /* It has to be a CALL */
        {
          struct rml_struct *p = (struct rml_struct*)RML_UNTAGPTR(e1);
          ast = Absyn__ALG_5fNORETCALL(p->data[0],p->data[1]);
        }
      )
  )
  ;

equality_or_noretcall_equation returns [void* ast] :
  e1=simple_expression
    (  EQUALS e2=expression {ast = Absyn__EQ_5fEQUALS(e1,e2);}
    | {RML_GETHDR(e1) == RML_STRUCTHDR(2, Absyn__CALL_3dBOX2)}? /* It has to be a CALL */
       {
         struct rml_struct *p = (struct rml_struct*)RML_UNTAGPTR(e1);
         ast = Absyn__EQ_5fNORETCALL(p->data[0],p->data[1]);
       }
    )
  ;

conditional_equation_e returns [void* ast] :
  IF e=expression THEN then_b=equation_list else_if_b=equation_elseif_list? ( ELSE else_b=equation_list )? T_END IF
    {
      ast = Absyn__EQ_5fIF(e, then_b, or_nil(else_if_b), or_nil(else_b));
    }
  ;

conditional_equation_a returns [void* ast] :
  IF e=expression THEN then_b=algorithm_list else_if_b=algorithm_elseif_list? ( ELSE else_b=algorithm_list )? T_END IF
    {
      ast = Absyn__ALG_5fIF(e, then_b, or_nil(else_if_b), or_nil(else_b));
    }
  ;

for_clause_e returns [void* ast] :
  FOR is=for_indices LOOP es=equation_list T_END FOR {ast = Absyn__EQ_5fFOR(is,es);}
  ;

for_clause_a returns [void* ast] :
  FOR is=for_indices LOOP as=algorithm_list T_END FOR {ast = Absyn__ALG_5fFOR(is,as);}
  ;

while_clause returns [void* ast] :
  WHILE e=expression LOOP as=algorithm_list T_END WHILE { ast = Absyn__ALG_5fWHILE(e,as); }
  ;

when_clause_e returns [void* ast] :
  WHEN e=expression THEN body=equation_list es=else_when_e_list? T_END WHEN
    {
      ast = Absyn__EQ_5fWHEN_5fE(e,body,or_nil(es));
    }
  ;

else_when_e_list returns [void* ast] :
  e=else_when_e es=else_when_e_list? {ast = mk_cons(e,or_nil(es));}
  ;

else_when_e returns [void* ast] :
  ELSEWHEN e=expression THEN es=equation_list { ast = mk_tuple2(e,es); }
  ;

when_clause_a returns [void* ast] :
  WHEN e=expression THEN body=algorithm_list es=else_when_a_list? T_END WHEN
    {
      ast = Absyn__ALG_5fWHEN_5fA(e,body,or_nil(es));
    }
  ;

else_when_a_list returns [void* ast] :
  e=else_when_a es=else_when_a_list? {ast = mk_cons(e,or_nil(es));}
  ;

else_when_a returns [void* ast] :
  ELSEWHEN e=expression THEN as=algorithm_list {ast = mk_tuple2(e,as);}
  ;

equation_elseif_list returns [void* ast] :
  e=equation_elseif es=equation_elseif_list? {ast = mk_cons(e,or_nil(es));}
  ;

equation_elseif returns [void* ast] :
  ELSEIF e=expression THEN es=equation_list {ast = mk_tuple2(e,es);}
  ;

algorithm_elseif_list returns [void* ast] :
  a=algorithm_elseif as=algorithm_elseif_list? {ast = mk_cons(a,or_nil(as));}
  ;

algorithm_elseif returns [void* ast] :
  ELSEIF e=expression THEN as=algorithm_list {ast = mk_tuple2(e,as);}
  ;

equation_list_then returns [void* ast] :
    { LA(1) == THEN }? {ast = mk_nil();}
  | (e=equation SEMICOLON es=equation_list_then) {ast = mk_cons(e.ast,es);}
  ;


equation_list returns [void* ast] :
  {LA(1) != T_END || (LA(1) == T_END && LA(2) != IDENT)}? {ast = mk_nil();}
  |
  ( e=equation SEMICOLON es=equation_list ) {ast = mk_cons(e.ast,es);}
  ;

algorithm_list returns [void* ast] :
  {LA(1) != T_END || (LA(1) == T_END && LA(2) != IDENT)}? {ast = mk_nil();}
  | a=algorithm SEMICOLON as=algorithm_list {ast = mk_cons(a.ast,as);}
  ;

connect_clause returns [void* ast] :
  CONNECT LPAR cr1=connector_ref COMMA cr2=connector_ref RPAR {ast = Absyn__EQ_5fCONNECT(cr1,cr2);}
  ;

connector_ref returns [void* ast] :
  id=IDENT ( as=array_subscripts )? ( DOT cr2=connector_ref_2 )?
    {
      if (cr2)
        ast = Absyn__CREF_5fQUAL(token_to_scon(id),or_nil(as),cr2);
      else
        ast = Absyn__CREF_5fIDENT(token_to_scon(id),or_nil(as));
    }
  ;

connector_ref_2 returns [void* ast] :
  id=IDENT ( as=array_subscripts )? {ast = Absyn__CREF_5fIDENT(token_to_scon(id),or_nil(as));}
  ;

/*
 * 2.2.7 Expressions
 */
expression returns [void* ast] :
  ( e=if_expression {ast = e;}
  | e=simple_expression {ast = e;}
  | e=code_expression {ast = e;}
  | (MATCHCONTINUE expression_or_empty
     local_clause
     cases
     T_END MATCHCONTINUE)
  | (MATCH expression_or_empty
     local_clause
     cases
     T_END MATCH)
  )
  ;

expression_or_empty returns [void* ast] :
  e = expression {ast = e;}
  | LPAR RPAR {ast = Absyn__TUPLE(mk_nil());}
  ;

local_clause returns [void* ast] :
  (LOCAL element_list)?
  ;

cases returns [void* ast] :
  (onecase)+ (ELSE (string_comment local_clause (EQUATION equation_list_then)? THEN)? expression_or_empty SEMICOLON)?
  ;

onecase returns [void* ast] :
  (CASE pattern string_comment local_clause (EQUATION equation_list_then)?
  THEN expression_or_empty SEMICOLON)
  ;

pattern returns [void* ast] :
  expression_or_empty
  ;

if_expression returns [void* ast] :
  IF cond=expression THEN e1=expression es=elseif_expression_list ELSE e2=expression {Absyn__IFEXP(cond,e1,e2,es);}
  ;

elseif_expression_list returns [void* ast] :
  e=elseif_expression es=elseif_expression_list { ast = mk_cons(e,es); }
  | { ast = mk_nil(); }
  ;

elseif_expression returns [void* ast] :
  ELSEIF e1=expression THEN e2=expression { ast = mk_tuple2(e1,e2); }
  ;

for_indices returns [void* ast] :
     i=for_index (COMMA is=for_indices)? {ast = mk_cons(i, or_nil(is));}
  ;

for_index returns [void* ast] :
     (i=IDENT (T_IN e=expression)? {ast = mk_tuple2(token_to_scon(i),mk_some_or_none(e));})
  ;

simple_expression returns [void* ast] :
    e=simple_expr {ast = e;} (COLONCOLON e=simple_expr {ast = Absyn__CONS(ast,e);})*
  | i=IDENT AS e=simple_expression {ast = Absyn__AS(token_to_scon(i),e);}
  ;

simple_expr returns [void* ast] :
  e1=logical_expression ( COLON e2=logical_expression ( COLON e3=logical_expression )? )?
    {
      if (e3)
        ast = Absyn__RANGE(e1,mk_some(e2),e3);
      else if (e2)
        ast = Absyn__RANGE(e1,mk_none(),e2);
      else
        ast = e1;
    }
  ;

logical_expression returns [void* ast] :
  e1=logical_term {ast = e1;} ( T_OR e2=logical_term {ast = Absyn__BINARY(ast,Absyn__OR,e2);})*
  ;

logical_term returns [void* ast] :
  e1=logical_factor {ast = e1;} ( T_AND e2=logical_factor {ast = Absyn__BINARY(ast,Absyn__AND,e2);} )*
  ;

logical_factor returns [void* ast] :
  ( n=T_NOT )? e=relation {ast = n ? Absyn__LUNARY(Absyn__NOT, e) : e;}
  ;

relation returns [void* ast] @declarations {
  void* op;
} :
  e1=arithmetic_expression 
  ( ( LESS {op = Absyn__LESS;} | LESSEQ {op = Absyn__LESSEQ;}
    | GREATER {op = Absyn__GREATER;} | GREATEREQ {op = Absyn__GREATEREQ;}
    | EQEQ {op = Absyn__EQUAL;} | LESSGT {op = Absyn__NEQUAL;}
    ) e2=arithmetic_expression )?
    {
      ast = e2 ? Absyn__BINARY(e1,op,e2) : e1;
    }
  ;

arithmetic_expression returns [void* ast] @declarations {
  void* op;
} :
  e1=unary_arithmetic_expression {ast = e1;}
    ( ( PLUS {op=Absyn__ADD;} | MINUS {op=Absyn__SUB;} | PLUS_EW {op=Absyn__ADD_5fEW;} | MINUS_EW {op=Absyn__SUB_5fEW;}
      ) e2=term { ast = Absyn__BINARY(ast,op,e2); }
    )*
  ;

unary_arithmetic_expression returns [void* ast] :
  ( PLUS t=term     { ast = Absyn__UNARY(Absyn__UPLUS,t); }
  | MINUS t=term    { ast = Absyn__UNARY(Absyn__SUB,t); }
  | PLUS_EW t=term  { ast = Absyn__UNARY(Absyn__UPLUS_5fEW,t); }
  | MINUS_EW t=term { ast = Absyn__UNARY(Absyn__SUB_5fEW,t); }
  | t=term          { ast = t; }
  )
  ;

term returns [void* ast] @declarations {
  void* op;
} :
  e1=factor {ast = e1;}
    (
      ( STAR {op=Absyn__MUL;} | SLASH {op=Absyn__DIV;} | STAR_EW {op=Absyn__MUL_5fEW;} | SLASH_EW {op=Absyn__DIV_5fEW;} )
      e2=factor {ast = Absyn__BINARY(e1,op,e2);}
    )*
  ;

factor returns [void* ast] :
  e1=primary ( ( pw=POWER | pw_ew=POWER_EW ) e2=primary )?
    {
      ast = e2 ? Absyn__BINARY(e1, pw ? Absyn__POW : Absyn__POW_5fEW, e2) : e1;
    }
  ;

primary returns [void* ast] @declarations {
  bool isFor = 0;
} :
  ( v=UNSIGNED_INTEGER {ast = Absyn__INTEGER(mk_icon($v.int));}
  | v=UNSIGNED_REAL    {ast = Absyn__REAL(mk_rcon(atof($v.text->chars)));}
  | v=STRING           {ast = Absyn__STRING(mk_scon($v.text->chars));}
  | T_FALSE            {ast = Absyn__BOOL(RML_FALSE);}
  | T_TRUE             {ast = Absyn__BOOL(RML_TRUE);}
  | ptr=component_reference__function_call {ast = ptr;}
  | DER el=function_call {ast = Absyn__CALL(Absyn__CREF_5fIDENT(mk_scon("der"), mk_nil()),el);}
  | LPAR expression_list RPAR {ast = Absyn__TUPLE(el);}
  | LBRACK el=matrix_expression_list RBRACK {ast = Absyn__MATRIX(el);}
  | LBRACE for_or_el=for_or_expression_list[&isFor] RBRACE
    {
      if (isFor)
        ast = Absyn__ARRAY(for_or_el);
      else
        ast = Absyn__CALL(Absyn__CREF_5fIDENT(mk_scon("array"), mk_nil()),for_or_el);
    }
  | T_END { ast = Absyn__END; }
  )
  ;

matrix_expression_list returns [void* ast] :
  e1=expression_list (SEMICOLON e2=matrix_expression_list)? {ast = mk_cons(e1, or_nil(e2));}
  ;

component_reference__function_call returns [void* ast] :
  cr=component_reference ( fc=function_call )? {
      if (fc != NULL)
        ast = Absyn__CALL(cr,fc);
      else
        ast = Absyn__CREF(cr);
    }
  | i=INITIAL LPAR RPAR {
      ast = Absyn__CALL(Absyn__CREF_5fIDENT(mk_scon("initial"), mk_nil()),Absyn__FUNCTIONARGS(mk_nil(),mk_nil()));
    }
  ;

name_path returns [void* ast] :
  { LA(2)!=DOT }? id=IDENT {ast = Absyn__IDENT(token_to_scon(id));}
  | id=IDENT DOT p=name_path {ast = Absyn__QUALIFIED(token_to_scon(id),p);}
  ;

name_path_star [bool* unqual] returns [void* ast] :
    { LA(2) != DOT }? id=IDENT ( uq=STAR_EW )?
    {
      ast = Absyn__IDENT(token_to_scon(id));
      *unqual = uq != 0;
    }
  | id=IDENT DOT p=name_path_star[unqual] {ast = Absyn__QUALIFIED(token_to_scon(id),p);}
  ;

component_reference returns [void* ast] :
    ( id=IDENT | id=OPERATOR) ( arr=array_subscripts )? ( DOT cr=component_reference )?
    {
      if (cr)
        ast = Absyn__CREF_5fQUAL(token_to_scon(id), or_nil(arr), cr);
      else
        ast = Absyn__CREF_5fIDENT(token_to_scon(id), or_nil(arr));
    }
  | WILD {ast = Absyn__WILD;}
  ;

function_call returns [void* ast] :
  LPAR (function_arguments) RPAR {ast = function_arguments;}
  ;

function_arguments returns [void* ast] @declarations {
  bool isFor = 0;
} :
  (for_or_el=for_or_expression_list[&isFor]) (namel=named_arguments) ?
    {
      ast = isFor ? for_or_el : Absyn__FUNCTIONARGS(for_or_el,namel);
    }
  ;

for_or_expression_list [bool* isFor] returns [void* ast]:
  ({LA(1)==IDENT || LA(1)==OPERATOR && LA(2) == EQUALS || LA(1) == RPAR || LA(1) == RBRACE}?
   {ast = mk_nil();} /* empty */
  |(e=expression {ast = e;} ( COMMA el=for_or_expression_list2 {ast = mk_cons(e,el);} | FOR forind=for_indices {ast = Absyn__FOR_5fITER_5fFARG(e, forind); *isFor = 1;})? )
  )
    ;

for_or_expression_list2 returns [void* ast] :
    {LA(2) == EQUALS}? {ast = mk_nil();}
  | e=expression (COMMA el=for_or_expression_list2)? {ast = mk_cons(e, or_nil(el));}
  ;

named_arguments returns [void* ast] :
  a=named_argument (COMMA as=named_arguments)? {ast = mk_cons(a, or_nil(as));}
  ;

named_argument returns [void* ast] :
  ( id=IDENT | id=OPERATOR) EQUALS e=expression {ast = Absyn__NAMEDARG(token_to_scon(id),e);}
  ;

expression_list returns [void* ast] :
  e1=expression (COMMA el=expression_list)? { ast = (el==NULL ? mk_cons(e1,mk_nil()) : mk_cons(e1,el)); }
  ;

array_subscripts returns [void* ast] :
  LBRACK sl=subscript_list RBRACK {ast = sl;}
  ;

subscript_list returns [void* ast] :
  s1=subscript ( COMMA s2=subscript_list )? {ast = mk_cons(s1, or_nil(s2));}
  ;

subscript returns [void* ast] :
    e=expression {ast = Absyn__SUBSCRIPT(e);}
  | COLON {ast = Absyn__NOSUB;}
  ;

comment returns [void* ast] :
  (cmt=string_comment (ann=annotation)?)
    {
       if (cmt || ann) {
         ast = Absyn__COMMENT(mk_some_or_none(ann), mk_some_or_none(cmt));
       }
    }
  ;

string_comment returns [void* ast]
@declarations {
  pANTLR3_STRING t1;
} :
  ( s1=STRING {t1 = s1->getText(s1);} (PLUS s2=STRING {t1->appendS(t1,s2->getText(s2));})* {ast = mk_scon(t1->chars);})?
  ;

annotation returns [void* ast] :
  T_ANNOTATION cmod=class_modification {ast = Absyn__ANNOTATION(cmod);}
  ;


/* Code quotation mechanism */
code_expression returns [void* ast] :
  CODE LPAR ((expression RPAR)=> e=expression | m=modification | el=element (SEMICOLON)?
  | eq=code_equation_clause | ieq=code_initial_equation_clause
  | alg=code_algorithm_clause | ialg=code_initial_algorithm_clause
  )  RPAR
  ;

code_equation_clause :
  ( EQUATION ( equation SEMICOLON | annotation SEMICOLON )*  )
  ;

code_initial_equation_clause :
  { LA(2)==EQUATION }?
  INITIAL ec=code_equation_clause 
  ;

code_algorithm_clause :
  T_ALGORITHM (algorithm SEMICOLON | annotation SEMICOLON)*
  ;

code_initial_algorithm_clause :
  { LA(2) == T_ALGORITHM }?
  INITIAL T_ALGORITHM
  ( algorithm SEMICOLON | annotation SEMICOLON )* 
  ;
/* End Code quotation mechanism */
