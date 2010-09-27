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

import MetaModelica_Lexer; /* Makes all tokens defined */

@includes {
  #include <stdlib.h>
  #include <stdio.h>
  #include <errno.h>
  #include <time.h>
#ifdef __cplusplus
extern "C" {
#endif  
  #include "rml.h"
  #include "Absyn.h"
  #include "Interactive.h"
#ifdef __cplusplus
}
#endif
  
  #include "ModelicaParserCommon.h"
  #include "runtime/errorext.h"
  
  #define ModelicaParserException 100
  #define ModelicaLexerException  200
  #define modelicaParserAssert(cond,msg,func,_line1,_offset1,_line2,_offset2) {if (!(cond)) { \
fileinfo* __info = (fileinfo*)malloc(sizeof(fileinfo)); \
CONSTRUCTEX(); \
EXCEPTION->type = ModelicaParserException; \
EXCEPTION->message = (void *) msg; \
__info->line1 = _line1; \
__info->line2 = _line2; \
__info->offset1 = _offset1; \
__info->offset2 = _offset2; \
EXCEPTION->custom = __info; \
goto rule ## func ## Ex; }}

  #define false 0
  #define true 1
  #define or_nil(x) (x != 0 ? x : mk_nil())
  #define mk_some_or_none(x) (x ? mk_some(x) : mk_none())
  #define mk_tuple2(x1,x2) mk_box2(0,x1,x2)
  #define make_redeclare_keywords(replaceable,redeclare) (replaceable && redeclare ? Absyn__REDECLARE_5fREPLACEABLE : replaceable ? Absyn__REPLACEABLE : redeclare ? Absyn__REDECLARE : NULL)
  #define make_inner_outer(i,o) (i && o ? Absyn__INNEROUTER : i ? Absyn__INNER : o ? Absyn__OUTER : Absyn__UNSPECIFIED)
#if 1 /* mk_bcon will be defined in RML later */
  #define mk_bcon(x) (x ? RML_TRUE : RML_FALSE)
#endif
#if 0
  /* Enable if you don't want to generate the tree */
  void* mk_box_eat_all(int ix, ...);
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
  #define token_to_scon(tok) mk_scon((char*)tok->getText(tok)->chars)
  #define NYI(void) fprintf(stderr, "NYI \%s \%s:\%d\n", __FUNCTION__, __FILE__, __LINE__); exit(1);
  #define INFO(start) Absyn__INFO(ModelicaParser_filename_RML, isReadOnly, mk_icon(start->line), mk_icon(start->charPosition+1), mk_icon(LT(1)->line), mk_icon(LT(1)->charPosition+1), Absyn__TIMESTAMP(mk_rcon(0),mk_rcon(0)))
  typedef struct fileinfo_struct {
    int line1;
    int line2;
    int offset1;
    int offset2;
  } fileinfo;
}

@members
{
  void* ModelicaParser_filename_RML = 0;
  const char* ModelicaParser_filename_C = 0;
  int ModelicaParser_readonly = 0;
  int ModelicaParser_flags = 0;
  void* isReadOnly = RML_FALSE;
  void* mk_box_eat_all(int ix, ...) {return NULL;}
  double getCurrentTime(void) {             
    time_t t;
    time( &t );
    return difftime(t, 0);
  }
}

/*------------------------------------------------------------------
 * PARSER RULES
 *------------------------------------------------------------------*/

stored_definition returns [void* ast] :
  (within=within_clause SEMICOLON)?
  cl=class_definition_list?
  EOF
    {
      ast = Absyn__PROGRAM(or_nil(cl), within ? within : Absyn__TOP, Absyn__TIMESTAMP(mk_rcon(0.0), mk_rcon(getCurrentTime())));
    }
  ;

within_clause returns [void* ast] :
    WITHIN (name=name_path)? {ast = name ? Absyn__WITHIN(name) : Absyn__TOP;}
  ;

class_definition_list returns [void* ast] :
  ((f=FINAL)? cd=class_definition[f != NULL] SEMICOLON) cl=class_definition_list?
    {
      ast = mk_cons(cd.ast, or_nil(cl));
    }
  ;

class_definition [int final] returns [void* ast] :
  ((e=ENCAPSULATED)? (p=PARTIAL)? ct=class_type cs=class_specifier)
    {
      $ast = Absyn__CLASS($cs.name, mk_bcon(p), mk_bcon(final), mk_bcon(e), ct, $cs.ast, INFO($start));
    }
  ;

class_type returns [void* ast] :
  ( CLASS { ast = Absyn__R_5fCLASS; }
  | MODEL { ast = Absyn__R_5fMODEL; }
  | RECORD { ast = Absyn__R_5fRECORD; }
  | BLOCK { ast = Absyn__R_5fBLOCK; }
  | ( e=EXPANDABLE )? CONNECTOR { ast = e ? Absyn__R_5fEXP_5fCONNECTOR : Absyn__R_5fCONNECTOR; }
  | TYPE { ast = Absyn__R_5fTYPE; }
  | T_PACKAGE { ast = Absyn__R_5fPACKAGE; }
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

identifier returns [char* str] :
  (id=IDENT|id=CODE) {str = (char*)$id.text->chars;}
  ;

class_specifier returns [void* ast, void* name] :
    ( s1=identifier spec=class_specifier2
      {
        modelicaParserAssert($spec.s2 == NULL || !strcmp(s1,$spec.s2), "The identifier at start and end are different", class_specifier, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition);
        $ast = $spec.ast;
        $name = mk_scon(s1);
      }
    | EXTENDS s1=identifier (mod=class_modification)? cmt=string_comment comp=composition T_END s2=identifier
      {
        modelicaParserAssert(!strcmp(s1,s2), "The identifier at start and end are different", class_specifier, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition);
        $name = mk_scon(s1);
        $ast = Absyn__CLASS_5fEXTENDS($name, or_nil(mod), mk_some_or_none(cmt), comp);
      }
    )  
    ;

class_specifier2 returns [void* ast, const char *s2] @init {
  $s2 = 0;
} :
( 
  cmt=string_comment c=composition T_END id=identifier
    {
      $s2 = id;
      $ast = Absyn__PARTS(c, mk_some_or_none(cmt));
    }
| EQUALS attr=base_prefix path=type_specifier ( cm=class_modification )? cmt=comment
    {
      $ast = Absyn__DERIVED(path, attr, or_nil(cm), mk_some_or_none(cmt));
    }
| EQUALS cs=enumeration {$ast=cs;}
| EQUALS cs=pder {$ast=cs;}
| EQUALS cs=overloading {$ast=cs;}
| SUBTYPEOF ts=type_specifier
   {
     $ast = Absyn__DERIVED(Absyn__TCOMPLEX(Absyn__IDENT(mk_scon("polymorphic")),mk_cons(ts,mk_nil()),mk_nil()),
                           Absyn__ATTR(RML_FALSE,RML_FALSE,Absyn__VAR,Absyn__BIDIR,mk_nil()),mk_nil(),mk_none());
   }
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
  OVERLOAD LPAR nl=name_list RPAR cmt=comment
    {
      ast = Absyn__OVERLOAD(nl, mk_some_or_none(cmt));
    }
  ;

base_prefix returns [void* ast] :
  tp=type_prefix {ast = Absyn__ATTR(tp.flow, tp.stream, tp.variability, tp.direction, mk_nil());}
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
  ( ext=external_clause? { ast = or_nil(ext); }
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
            ast = Absyn__EXTERNALDECL(funcname ? mk_some(token_to_scon(funcname)) : mk_none(), mk_some_or_none(lang), mk_some_or_none(retexp), or_nil(expl), mk_some_or_none(ann1));
            ast = mk_cons(Absyn__EXTERNAL(ast, mk_some_or_none(ann2)), mk_nil());
          }
        ;

external_annotation returns [void* ast] :
  ann=annotation SEMICOLON {ast = ann;}
  ;

public_element_list returns [void* ast] :
  PUBLIC es=element_list {ast = Absyn__PUBLIC(es);}
  ;

protected_element_list returns [void* ast] :
  PROTECTED es=element_list {ast = Absyn__PROTECTED(es);}
  ;

language_specification returns [void* ast] :
  id=STRING {ast = token_to_scon(id);}
  ;

element_list returns [void* ast] @init {
  e.ast = 0;
} :
  (((e=element | a=annotation) s=SEMICOLON) es=element_list)?
    {
      if (e.ast)
        ast = mk_cons(Absyn__ELEMENTITEM(e.ast), es);
      else if (a)
        ast = mk_cons(Absyn__ANNOTATIONITEM(a), es);
      else
        ast = mk_nil();
    }
  ;

element returns [void* ast] @declarations {
  void *final;
  void *innerouter;
} :
    ic=import_clause { $ast = Absyn__ELEMENT(RML_FALSE,mk_none(),Absyn__UNSPECIFIED,mk_scon("import"), ic, INFO($start), mk_none());}
  | ec=extends_clause { $ast = Absyn__ELEMENT(RML_FALSE,mk_none(),Absyn__UNSPECIFIED,mk_scon("extends"), ec, INFO($start),mk_none());}
  | du=defineunit_clause { $ast = du;}
  | (r=REDECLARE)? (f=FINAL)? (i=INNER)? (o=T_OUTER)? { final = mk_bcon(f); innerouter = make_inner_outer(i,o); }
    ( ( cdef=class_definition[f != NULL] | cc=component_clause )
        {
           if (!cc)
             $ast = Absyn__ELEMENT(final, mk_some_or_none(make_redeclare_keywords(false,r)),
                                  innerouter, mk_scon("??"),
                                  Absyn__CLASSDEF(RML_FALSE, cdef.ast),
                                  INFO($start), mk_none());
           else
             $ast = Absyn__ELEMENT(final, mk_some_or_none(make_redeclare_keywords(false,r)), innerouter,
                                   mk_scon("component"), cc, INFO($start), mk_none());
        }
    | (REPLACEABLE ( cdef=class_definition[f != NULL] | cc=component_clause ) constr=constraining_clause_comment? )
        {
           if (cc)
             $ast = Absyn__ELEMENT(final, mk_some_or_none(make_redeclare_keywords(true,r)), innerouter,
                                  mk_scon("replaceable component"), cc, INFO($start), mk_some_or_none(constr));
           else
             $ast = Absyn__ELEMENT(final, mk_some_or_none(make_redeclare_keywords(true,r)), innerouter,
                                  mk_scon("replaceable ??"), Absyn__CLASSDEF(RML_TRUE, cdef.ast), INFO($start), mk_some_or_none(constr));
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

implicit_import_name returns [void* ast] :
  np=name_path_star
  {
    ast = np.unqual ? Absyn__UNQUAL_5fIMPORT(np.ast) : Absyn__QUAL_5fIMPORT(np.ast);
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
  constr=constraining_clause cmt=comment {$ast = Absyn__CONSTRAINCLASS(constr, mk_some_or_none(cmt));}
  ;

constraining_clause returns [void* ast] :
    EXTENDS np=name_path  (mod=class_modification)? { ast = Absyn__EXTENDS(np,or_nil(mod),mk_none()); }
  | CONSTRAINEDBY np=name_path (mod=class_modification)? { ast = Absyn__EXTENDS(np,or_nil(mod),mk_none()); }
  ;

/*
 * 2.2.4 Component clause
 */

component_clause returns [void* ast] @declarations {
  void *arr = 0, *ar_option = 0;
} :
  tp=type_prefix path=type_specifier clst=component_list
    {
      // Take the last (array subscripts) from type and move it to ATTR
      if (RML_GETHDR(path) == RML_STRUCTHDR(2, Absyn__TPATH_3dBOX2)) // is TPATH(path, arr)
			{
				struct rml_struct *p = (struct rml_struct*)RML_UNTAGPTR(path);
				ar_option = p->data[1];         // get the array option
				p->data[1] = mk_none();  // replace the array with nothing
			}
			else if (RML_GETHDR(path) == RML_STRUCTHDR(3, Absyn__TCOMPLEX_3dBOX3))
			{
				struct rml_struct *p = (struct rml_struct*)RML_UNTAGPTR(path);
				ar_option = p->data[2];         // get the array option
				p->data[2] = mk_none();  // replace the array with nothing
			}
      else
      {
        fprintf(stderr, "component_clause error\n");
      }

              { /* adrpo - use the ANSI C standard */
				// no arr was set, inspect ar_option and fix it
				struct rml_struct *p = (struct rml_struct*)RML_UNTAGPTR(ar_option);
				if (RML_GETHDR(ar_option) == RML_STRUCTHDR(0,0)) // is NONE
				{
					arr = mk_nil();
				}
				else // is SOME(arr)
				{
					arr = p->data[0];
				}
		      }

      ast = Absyn__COMPONENTS(Absyn__ATTR(tp.flow, tp.stream, tp.variability, tp.direction, arr), path, clst);
    }
  ;

type_prefix returns [void* flow, void* stream, void* variability, void* direction] :
  (fl=FLOW|st=STREAM)? (di=DISCRETE|pa=PARAMETER|co=CONSTANT)? (in=T_INPUT|out=T_OUTPUT)?
    {
      $flow = mk_bcon(fl);
      $stream = mk_bcon(st);
      $variability = di ? Absyn__DISCRETE : pa ? Absyn__PARAM : co ? Absyn__CONST : Absyn__VAR;
      $direction = in ? Absyn__INPUT : out ? Absyn__OUTPUT : Absyn__BIDIR;
    }
  ;

type_specifier returns [void* ast] :
  np=name_path
  (LESS ts=type_specifier_list GREATER)? (as=array_subscripts)?
    {
      if (ts != NULL)
        ast = Absyn__TCOMPLEX(np,ts,mk_some_or_none(as));
      else
        ast = Absyn__TPATH(np,mk_some_or_none(as));
    }
  ;

type_specifier_list returns [void* ast] :
  np1=type_specifier (COMMA np2=type_specifier_list)? {ast = mk_cons(np1,or_nil(np2));}
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
  ( em=element_modification_or_replaceable {ast = em;}
  | er=element_redeclaration {ast = er;}
  )
  ;

element_modification_or_replaceable returns [void* ast] :
    (e=EACH)? (f=FINAL)? (em=element_modification[e ? Absyn__EACH : Absyn__NON_5fEACH, mk_bcon(f)] | er=element_replaceable[e != NULL,f != NULL,false])
      {
        ast = em ? em : er;
      }
    ;

element_modification [void *each, void *final] returns [void* ast] :
  cr=component_reference ( mod=modification )? cmt=string_comment { ast = Absyn__MODIFICATION(final, each, cr, mk_some_or_none(mod), mk_some_or_none(cmt)); }
  ;

element_redeclaration returns [void* ast] :
  REDECLARE (e=EACH)? (f=FINAL)?
  ( (cdef=class_definition[f != NULL] | cc=component_clause1) | er=element_replaceable[e != NULL,f != NULL,true] )
     {
       if (er) {
         ast = er;
       } else {
         if (!cc)
          cc = Absyn__CLASSDEF(RML_FALSE,cdef.ast);
         ast = Absyn__REDECLARATION(mk_bcon(f), make_redeclare_keywords(false,true), e ? Absyn__EACH : Absyn__NON_5fEACH, cc, mk_none());
       }
     }
  ;

element_replaceable [int each, int final, int redeclare] returns [void* ast] :
  REPLACEABLE ( cd=class_definition[final] | e_spec=component_clause1 ) constr=constraining_clause_comment?
    {
      ast = Absyn__REDECLARATION(mk_bcon(final), make_redeclare_keywords(true,redeclare),
                                 each ? Absyn__EACH : Absyn__NON_5fEACH, e_spec ? e_spec : Absyn__CLASSDEF(RML_TRUE, cd.ast),
                                 mk_some_or_none($constr.ast));
    }
  ;
  
component_clause1 returns [void* ast] :
  attr=base_prefix ts=type_specifier comp_decl=component_declaration1
    {
      ast = Absyn__COMPONENTS(attr, ts, mk_cons(comp_decl, mk_nil()));
    }
  ;

component_declaration1 returns [void* ast] :
  decl=declaration cmt=comment  { ast = Absyn__COMPONENTITEM(decl, mk_none(), mk_some_or_none(cmt)); }
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
    {$ast = Absyn__EQUATIONITEM(e, mk_some_or_none(cmt), INFO($start));}
  ;

algorithm returns [void* ast] :
  ( aa=assign_clause_a {a = aa.ast;}
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
    {$ast = Absyn__ALGORITHMITEM(a, mk_some_or_none(cmt), INFO($start));}
  ;

assign_clause_a returns [void* ast] @declarations {
  char *s1 = 0;
} :
  /* MetaModelica allows pattern matching on arbitrary expressions in algorithm sections... */
  e1=simple_expression
    ( (ASSIGN|eq=EQUALS) e2=expression
      {
        modelicaParserAssert(eq==0,"Algorithms can not contain equations ('='), use assignments (':=') instead", assign_clause_a, $eq->line, $eq->charPosition+1, $eq->line, $eq->charPosition+2);
        modelicaParserAssert(eq!=0 || metamodelica_enabled() || (RML_GETHDR(e1) == RML_STRUCTHDR(1, Absyn__CREF_3dBOX1))
            || ((RML_GETHDR(e1) == RML_STRUCTHDR(1, Absyn__TUPLE_3dBOX1)) && (RML_GETHDR(e2) == RML_STRUCTHDR(2, Absyn__CALL_3dBOX2))),
            "Modelica assignment statements are either on the form 'component_reference := expression' or '( output_expression_list ) := function_call'",
            assign_clause_a, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition);
        $ast = Absyn__ALG_5fASSIGN(e1,e2);
      }
    | 
      {
        modelicaParserAssert(RML_GETHDR(e1) == RML_STRUCTHDR(2, Absyn__CALL_3dBOX2), "Only function call expressions may stand alone in an algorithm section",
                             assign_clause_a, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition);
        { /* uselsess block for ANSI C crap */
        struct rml_struct *p = (struct rml_struct*)RML_UNTAGPTR(e1);
        $ast = Absyn__ALG_5fNORETCALL(p->data[0],p->data[1]);
        }
      }
    )
  ;

equality_or_noretcall_equation returns [void* ast] :
  e1=simple_expression
    (  EQUALS e2=expression {ast = Absyn__EQ_5fEQUALS(e1,e2);}
    | {LA(1) != EQUALS && RML_GETHDR(e1) == RML_STRUCTHDR(2, Absyn__CALL_3dBOX2)}? /* It has to be a CALL */
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
  | e=part_eval_function_expression {ast = e;}
  | e=match_expression {ast = e;}
  )
  ;

part_eval_function_expression returns [void* ast] :
  FUNCTION cr=component_reference fc=function_call { ast = Absyn__PARTEVALFUNCTION(cr, fc); }
  ;

if_expression returns [void* ast] :
  IF cond=expression THEN e1=expression es=elseif_expression_list? ELSE e2=expression {ast = Absyn__IFEXP(cond,e1,e2,or_nil(es));}
  ;

elseif_expression_list returns [void* ast] :
  e=elseif_expression es=elseif_expression_list? { ast = mk_cons(e,or_nil(es)); }
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
    e1=simple_expr {ast = e;} (COLONCOLON e2=simple_expression)?
    {
      if (e2)
        ast = Absyn__CONS(e1,e2);
      else
        ast = e1;
    }
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
  e1=logical_term {ast = e1;} ( T_OR e2=logical_term {ast = Absyn__LBINARY(ast,Absyn__OR,e2);})*
  ;

logical_term returns [void* ast] :
  e1=logical_factor {ast = e1;} ( T_AND e2=logical_factor {ast = Absyn__LBINARY(ast,Absyn__AND,e2);} )*
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
      ast = e2 ? Absyn__RELATION(e1,op,e2) : e1;
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
  | MINUS t=term    { ast = Absyn__UNARY(Absyn__UMINUS,t); }
  | PLUS_EW t=term  { ast = Absyn__UNARY(Absyn__UPLUS_5fEW,t); }
  | MINUS_EW t=term { ast = Absyn__UNARY(Absyn__UMINUS_5fEW,t); }
  | t=term          { ast = t; }
  )
  ;

term returns [void* ast] @declarations {
  void* op;
} :
  e1=factor {ast = e1;}
    (
      ( STAR {op=Absyn__MUL;} | SLASH {op=Absyn__DIV;} | STAR_EW {op=Absyn__MUL_5fEW;} | SLASH_EW {op=Absyn__DIV_5fEW;} )
      e2=factor {ast = Absyn__BINARY(ast,op,e2);}
    )*
  ;

factor returns [void* ast] :
  e1=primary ( ( pw=POWER | pw=POWER_EW ) e2=primary )?
    {
      ast = pw ? Absyn__BINARY(e1.ast, $pw.type ==POWER ? Absyn__POW : Absyn__POW_5fEW, e2.ast) : e1.ast;
    }
  ;

primary returns [void* ast] @declarations {
  int tupleExpressionIsTuple = 0;
} :
  ( v=UNSIGNED_INTEGER
    {
      char* chars = (char*)$v.text->chars;
      char* endptr;
      const char* args[2] = {NULL};
      long l = 0;
      errno = 0;
      l = strtol(chars,&endptr,10);
      args[0] = chars;
      args[1] = RML_SIZE_INT == 8 ? "OpenModelica (64-bit) only supports 63"
                                  : errno || *endptr != 0 ? "Modelica only supports 32"
                                                          : "OpenModelica only supports 31";
      
      if (errno || *endptr != 0) {
        double d = 0;
        errno = 0;
        d = strtod(chars,&endptr);
        modelicaParserAssert(*endptr == 0 && errno==0, "Number is too large to represent as a long or double on this machine", primary, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition+1);
        c_add_source_message(2, "SYNTAX", "Warning", "\%s-bit signed integers! Transforming: \%s into a real",
          args, 2, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition+1,
          ModelicaParser_readonly, ModelicaParser_filename_C);
        $ast = Absyn__REAL(mk_rcon(d));
      } else {
        if (((long)1<<(RML_SIZE_INT*8-2))-1 >= l) {
          $ast = Absyn__INTEGER(RML_IMMEDIATE(RML_TAGFIXNUM(l))); /* We can't use mk_icon here - it takes "int"; not "long" */
        } else {
          if (l > ((long)1<<30)-1) {
            c_add_source_message(2, "SYNTAX", "Warning", "\%s-bit signed integers! Truncating integer: \%s to 1073741823",
                                 args, 2, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition+1,
                                 ModelicaParser_readonly, ModelicaParser_filename_C);
            $ast = Absyn__INTEGER(mk_icon(1073741823));
          } else {
            $ast = Absyn__REAL(mk_rcon((double)l));
          }
        }
      }
    }
  | v=UNSIGNED_REAL    {$ast = Absyn__REAL(mk_rcon(atof((char*)$v.text->chars)));}
  | v=STRING           {$ast = Absyn__STRING(mk_scon((char*)$v.text->chars));}
  | T_FALSE            {$ast = Absyn__BOOL(RML_FALSE);}
  | T_TRUE             {$ast = Absyn__BOOL(RML_TRUE);}
  | ptr=component_reference__function_call {$ast = ptr;}
  | DER el=function_call {$ast = Absyn__CALL(Absyn__CREF_5fIDENT(mk_scon("der"), mk_nil()),el);}
  | LPAR el=output_expression_list[&tupleExpressionIsTuple]
    {
      $ast = tupleExpressionIsTuple ? Absyn__TUPLE(el) : el;
    }
  | LBRACK el=matrix_expression_list RBRACK {$ast = Absyn__MATRIX(el);}
  | LBRACE for_or_el=for_or_expression_list RBRACE
    {
      if (!for_or_el.isFor)
        $ast = Absyn__ARRAY(for_or_el.ast);
      else
        $ast = Absyn__CALL(Absyn__CREF_5fIDENT(mk_scon("array"), mk_nil()),for_or_el.ast);
    }
  | T_END { $ast = Absyn__END; }
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
  (dot=DOT)? np=name_path2
    { ast = dot ? Absyn__FULLYQUALIFIED(np) : np; }
  ;

name_path2 returns [void* ast] :
  { LA(2)!=DOT }? id=IDENT {ast = Absyn__IDENT(token_to_scon(id));}
  | id=IDENT DOT p=name_path {ast = Absyn__QUALIFIED(token_to_scon(id),p);}
  ;

name_path_star returns [void* ast, int unqual] :
  (dot=DOT)? np=name_path_star2
    {
      $ast = dot ? Absyn__FULLYQUALIFIED(np.ast) : np.ast;
      $unqual = np.unqual;
    }
  ;

name_path_star2 returns [void* ast, int unqual] :
    { LA(2) != DOT }? id=IDENT ( uq=STAR_EW )?
    {
      $ast = Absyn__IDENT(token_to_scon(id));
      $unqual = uq != 0;
    }
  | id=IDENT DOT p=name_path_star2
    {
      $ast = Absyn__QUALIFIED(token_to_scon(id),p.ast);
      $unqual = p.unqual;
    }
  ;

component_reference returns [void* ast] :
  (dot=DOT)? cr=component_reference2
    {
      $ast = dot ? Absyn__CREF_5fFULLYQUALIFIED(cr) : cr;
    }
  | WILD {$ast = Absyn__WILD;}
  ;

component_reference2 returns [void* ast] :
    (id=IDENT | id=OPERATOR) ( arr=array_subscripts )? ( DOT cr=component_reference2 )?
    {
      if (cr)
        ast = Absyn__CREF_5fQUAL(token_to_scon(id), or_nil(arr), cr);
      else {
        ast = Absyn__CREF_5fIDENT(token_to_scon(id), or_nil(arr));
      }
    }
  ;

function_call returns [void* ast] :
  LPAR fa=function_arguments RPAR {ast = fa;}
  ;

function_arguments returns [void* ast] :
  for_or_el=for_or_expression_list (namel=named_arguments) ?
    {
      if (for_or_el.isFor)
        ast = for_or_el.ast;
      else
        ast = Absyn__FUNCTIONARGS(for_or_el.ast, or_nil(namel));
    }
  ;

for_or_expression_list returns [void* ast, int isFor]:
  ( {LA(1)==IDENT || LA(1)==OPERATOR && LA(2) == EQUALS || LA(1) == RPAR || LA(1) == RBRACE}? { $ast = mk_nil(); $isFor = 0; }
  | ( e=expression
      ( (COMMA el=for_or_expression_list2)
      | (FOR forind=for_indices)
      )?
    )
    {
      if (el != NULL) {
        $ast = mk_cons(e,el);
      } else if (forind != NULL) {
        $ast = Absyn__FOR_5fITER_5fFARG(e, forind);
      } else {
        $ast = mk_cons(e, mk_nil());
      }
      $isFor = forind != 0;
    }
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

output_expression_list [int* isTuple] returns [void* ast] :
  ( RPAR
    {
      ast = mk_nil();
      *isTuple = true;
    }
  | COMMA {*isTuple = true;} el=output_expression_list[isTuple]
      {
        $ast = mk_cons(Absyn__CREF(Absyn__WILD), el);
      }
  | e1=expression
    ( COMMA {*isTuple = true;} el=output_expression_list[isTuple]
      {
        ast = mk_cons(e1, el);
      }
    | RPAR
      {
        ast = *isTuple ? mk_cons(e1, mk_nil()) : e1;
      }
    )
  )
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
  ( s1=STRING {t1 = s1->getText(s1);} (PLUS s2=STRING {t1->appendS(t1,s2->getText(s2));})* {ast = mk_scon((char*)t1->chars);})?
  ;

annotation returns [void* ast] :
  T_ANNOTATION cmod=class_modification {ast = Absyn__ANNOTATION(cmod);}
  ;


/* Code quotation mechanism */

code_expression returns [void* ast] :
  ( CODE LPAR
    ( (initial=INITIAL)? ((EQUATION eq=code_equation_clause)|(T_ALGORITHM alg=code_algorithm_clause))
    | m=modification
    | (expression RPAR)=> e=expression
    | el=element (SEMICOLON)?
    )  RPAR
      {
        if (e) {
          ast = Absyn__CODE(Absyn__C_5fEXPRESSION(e));
        } else if (m) {
          ast = Absyn__CODE(Absyn__C_5fMODIFICATION(m));
        } else if (eq) {
          ast = Absyn__CODE(Absyn__C_5fEQUATIONSECTION(mk_bcon(initial), eq));
        } else if (alg) {
          ast = Absyn__CODE(Absyn__C_5fALGORITHMSECTION(mk_bcon(initial), alg));
        } else {
          ast = Absyn__CODE(Absyn__C_5fELEMENT(el.ast));
        }
      }
  )
  ;

code_equation_clause returns [void* ast] :
  ( e=equation SEMICOLON as=code_equation_clause?
    {
      ast = mk_cons(e.ast,or_nil(as));
    }
  | a=annotation SEMICOLON as=code_equation_clause?
    {
      ast = mk_cons(Absyn__EQUATIONITEMANN(a),or_nil(as));
    }
  )
  ;

code_algorithm_clause returns [void* ast] :
  ( al=algorithm SEMICOLON as=code_algorithm_clause?
    {
      ast = mk_cons(al.ast,or_nil(as));
    }
  | a=annotation SEMICOLON as=code_algorithm_clause?
    {
      ast = mk_cons(Absyn__ALGORITHMITEMANN(a),or_nil(as));
    }
  )
  ;

/* End Code quotation mechanism */


top_algorithm returns [void* ast, int isExp] :
  ( (expression (SEMICOLON|EOF))=> e=expression
  | ( a=top_assign_clause_a
    | a=conditional_equation_a
    | a=for_clause_a
    | a=while_clause
    )
    cmt=comment
  )
    {
      if (!e) {
        $ast = Absyn__ALGORITHMITEM(a, mk_some_or_none(cmt), INFO($start));
        $isExp = 0;
      } else {
        $ast = e;
        $isExp = 1;
      }
    }
  ;

top_assign_clause_a returns [void* ast] :
  e1=simple_expression ASSIGN e2=expression
    {
      ast = Absyn__ALG_5fASSIGN(e1,e2);
    }
  ;

interactive_stmt returns [void* ast]
@declarations {
int last_sc = 0;
} :
  // A list of expressions or algorithms separated by semicolons and optionally ending with a semicolon
  ss=interactive_stmt_list[&last_sc] EOF
    {
      ast = Interactive__ISTMTS(or_nil(ss), mk_bcon(last_sc));
    }
  ;

interactive_stmt_list [int *last_sc] returns [void* ast] @init {
  $ast = 0;
} :
  a=top_algorithm ((SEMICOLON ss=interactive_stmt_list[last_sc])|(SEMICOLON {*last_sc = 1;})|)
    {
      if (!a.isExp)
        ast = mk_cons(Interactive__IALG(a.ast), or_nil(ss));
      else
        ast = mk_cons(Interactive__IEXP(a.ast), or_nil(ss));
    }
  ;

/* MetaModelica */
match_expression returns [void* ast] : 
  ( (ty=MATCHCONTINUE exp=expression cmt=string_comment
     es=local_clause
     cs=cases
     T_END MATCHCONTINUE)
  | (ty=MATCH exp=expression cmt=string_comment
     es=local_clause
     cs=cases
     T_END MATCH)
  )
     {
       ast = Absyn__MATCHEXP(ty->type==MATCHCONTINUE ? Absyn__MATCHCONTINUE : Absyn__MATCH, exp, es, cs, mk_some_or_none(cmt));
     }
  ;

local_clause returns [void* ast] :
  (LOCAL el=element_list)?
    {
      ast = or_nil(el);
    }
  ;

cases returns [void* ast] :
  c=onecase cs=cases2
    {
      ast = mk_cons(c,cs);
    }
  ;

cases2 returns [void* ast] :
  ( (ELSE (cmt=string_comment es=local_clause (EQUATION eqs=equation_list_then)? THEN)? exp=expression SEMICOLON)?
    {
      if (exp)
       ast = mk_cons(Absyn__ELSE(es,or_nil(eqs),exp,mk_some_or_none(cmt)),mk_nil());
      else
       ast = mk_nil();
    }
  | c=onecase cs=cases2
    {
      ast = mk_cons(c, cs);
    }
  )
  ;

onecase returns [void* ast] :
  (CASE pat=pattern cmt=string_comment es=local_clause (EQUATION eqs=equation_list_then)? THEN exp=expression SEMICOLON)
    {
        ast = Absyn__CASE(pat,es,or_nil(eqs),exp,mk_some_or_none(cmt));
    }
  ;

pattern returns [void* ast] :
  e=expression {ast = e;}
  ;
