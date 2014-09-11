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

import MetaModelica_Lexer; /* Makes all tokens defined, imported in OptiMo_Lexer */
//import ParModelica_Lexer; /* Makes all tokens defined, except the ones specific to MetaModelica */
//import OptiMo_Lexer;  /* Makes all tokens defined */

@includes {
  #include <stdlib.h>
  #include <stdio.h>
  #include <errno.h>
  #include <time.h>

  #include "ModelicaParserCommon.h"
  #include "runtime/errorext.h"

  #define ModelicaParserException 100
  #define ModelicaLexerException  200
  #define modelicaParserAssert(cond,msg,func,_line1,_offset1,_line2,_offset2) {if (!(cond)) { \
fileinfo* __info = (fileinfo*)malloc(sizeof(fileinfo)); \
CONSTRUCTEX(); \
EXCEPTION->type = ModelicaParserException; \
EXCEPTION->message = (void *) (msg); \
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
  #define make_redeclare_keywords(replaceable,redeclare) (((replaceable) && (redeclare)) ? Absyn__REDECLARE_5fREPLACEABLE : ((replaceable) ? Absyn__REPLACEABLE : ((redeclare) ? Absyn__REDECLARE : NULL)))
  #define make_inner_outer(i,o) (i && o ? Absyn__INNER_5fOUTER : i ? Absyn__INNER : o ? Absyn__OUTER : Absyn__NOT_5fINNER_5fOUTER)
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

  #define PARSER_INFO(start) ((void*) Absyn__INFO(ModelicaParser_filename_RML, mk_bcon(ModelicaParser_readonly), mk_icon(start->line), mk_icon(start->line == 1 ? start->charPosition+2 : start->charPosition+1), mk_icon(LT(1)->line), mk_icon(LT(1)->charPosition+1), ModelicaParser_timeStamp))
  typedef struct fileinfo_struct {
    int line1;
    int line2;
    int offset1;
    int offset2;
  } fileinfo;
}

@members
{
  parser_members members;
  void* mk_box_eat_all(int ix, ...) {return NULL;}
}

/*------------------------------------------------------------------
 * PARSER RULES
 *------------------------------------------------------------------*/

stored_definition returns [void* ast]
@init{ within = NULL; cl = NULL; } :
  BOM? (within=within_clause SEMICOLON)?
  cl=class_definition_list?
  EOF
    {
      ast = Absyn__PROGRAM(or_nil(cl), within ? within : Absyn__TOP, ModelicaParser_timeStamp);
    }
  ;

within_clause returns [void* ast]
@init{ name = NULL; } :
  WITHIN (name=name_path)? {ast = name ? Absyn__WITHIN(name) : Absyn__TOP;}
  ;

class_definition_list returns [void* ast]
@init{ f = NULL; cd.ast = NULL; cl = NULL; } :
  ((f=FINAL)? cd=class_definition[f != NULL] SEMICOLON) cl=class_definition_list?
    {
      ast = mk_cons(cd.ast, or_nil(cl));
    }
  ;

class_definition [int final] returns [void* ast]
@init{ e = 0; p = 0; ct = 0; cs.ast = 0; } :
  ((e=ENCAPSULATED)? (p=PARTIAL)? ct=class_type cs=class_specifier)
    {
      $ast = Absyn__CLASS($cs.name, mk_bcon(p), mk_bcon(final), mk_bcon(e), ct, $cs.ast, PARSER_INFO($start));
    }
  ;

class_type returns [void* ast]
@init{ e = 0;  pur = 0; impur = 0; opr = 0; prl = 0; ker = 0; r = 0; } :
  ( CLASS { ast = Absyn__R_5fCLASS; }
  | OPTIMIZATION { ast = Absyn__R_5fOPTIMIZATION; }
  | MODEL { ast = Absyn__R_5fMODEL; }
  | RECORD { ast = Absyn__R_5fRECORD; }
  | BLOCK { ast = Absyn__R_5fBLOCK; }
  | ( e=EXPANDABLE )? CONNECTOR { ast = e ? Absyn__R_5fEXP_5fCONNECTOR : Absyn__R_5fCONNECTOR; }
  | TYPE { ast = Absyn__R_5fTYPE; }
  | T_PACKAGE { ast = Absyn__R_5fPACKAGE; }
  | (pur=PURE | impur=IMPURE)? (opr=OPERATOR | prl=T_PARALLEL | ker=T_KERNEL)? FUNCTION
      {
        ast = opr ? Absyn__R_5fFUNCTION(Absyn__FR_5fOPERATOR_5fFUNCTION) :
              prl ? Absyn__R_5fFUNCTION(Absyn__FR_5fPARALLEL_5fFUNCTION) :
              ker ? Absyn__R_5fFUNCTION(Absyn__FR_5fKERNEL_5fFUNCTION) :
              pur ? Absyn__R_5fFUNCTION(Absyn__FR_5fNORMAL_5fFUNCTION(Absyn__PURE)) :
              impur ? Absyn__R_5fFUNCTION(Absyn__FR_5fNORMAL_5fFUNCTION(Absyn__IMPURE)) :
              Absyn__R_5fFUNCTION(Absyn__FR_5fNORMAL_5fFUNCTION(Absyn__NO_5fPURITY));
      }
  | UNIONTYPE { ast = Absyn__R_5fUNIONTYPE; }
  | OPERATOR (r=RECORD)?
          {
            ast = r ? Absyn__R_5fOPERATOR_5fRECORD :
                  Absyn__R_5fOPERATOR;
          }
  )
  ;

identifier returns [char* str] :
  ( id=IDENT | id=DER | id=CODE | id=EQUALITY | id=INITIAL ) { str = (char*)$id.text->chars; }
  ;

class_specifier returns [void* ast, void* name]
@init{ s1 = 0; mod = 0; cmt = 0; s2 = 0; comp.ast = 0; comp.ann = 0; spec.ast = 0; } :
    ( s1=identifier spec=class_specifier2
      {
        modelicaParserAssert($spec.s2 == NULL || !strcmp(s1,$spec.s2), "The identifier at start and end are different", class_specifier, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition);
        $ast = $spec.ast;
        $name = mk_scon(s1);
      }
    | EXTENDS s1=identifier (mod=class_modification)? cmt=string_comment comp=composition s2=END_IDENT
      {
        modelicaParserAssert(!strcmp(s1,(char*)$s2.text->chars), "The identifier at start and end are different", class_specifier, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition);
        $name = mk_scon(s1);
        $ast = Absyn__CLASS_5fEXTENDS($name, or_nil(mod), mk_some_or_none(cmt), $comp.ast, $comp.ann);
      }
    )
    ;

class_specifier2 returns [void* ast, const char *s2]
@init {
  $s2 = 0; ids = 0; gt = 0; cmtStr = 0; cmt = 0; c.ast = 0; c.ann = 0;
  na = 0; rp = 0; attr = 0; path.ast = 0; cm = 0; cs = 0; ts.ast = 0;
} :
(
  (lt=LESS ids=ident_list gt=GREATER)? cmtStr=string_comment c=composition id=END_IDENT
    {
      $s2 = (char*)$id.text->chars;
      if (lt != NULL) {
        modelicaParserAssert(metamodelica_enabled(),"Polymorphic classes are only available in MetaModelica", class_specifier2, $start->line, $start->charPosition+1, $gt->line, $gt->charPosition+2);
        $ast = Absyn__PARTS(ids, mk_nil(), $c.ast, $c.ann, mk_some_or_none(cmtStr));
      } else {
        $ast = Absyn__PARTS(mk_nil(), mk_nil(), $c.ast, $c.ann, mk_some_or_none(cmtStr));
      }
    }
| (lp = LPAR na=named_arguments rp=RPAR) cmtStr=string_comment c=composition id=END_IDENT
    {
      modelicaParserAssert(optimica_enabled(),"Class attributes are currently allowed only for Optimica. Use +g=Optimica.", class_specifier2, $start->line, $start->charPosition+1, $lp->line, $lp->charPosition+2);
      $ast = Absyn__PARTS(mk_nil(), na, $c.ast, $c.ann, mk_some_or_none(cmtStr));
    }
| EQUALS attr=base_prefix path=type_specifier ( cm=class_modification )? cmt=comment
    {
      $ast = Absyn__DERIVED($path.ast, attr, or_nil(cm), mk_some_or_none(cmt));
    }
| EQUALS cs=enumeration { $ast=cs; }
| EQUALS cs=pder { $ast=cs; }
| EQUALS cs=overloading { $ast=cs; }
| SUBTYPEOF ts=type_specifier
   {
     $ast = Absyn__DERIVED(Absyn__TCOMPLEX(Absyn__IDENT(mk_scon("polymorphic")),mk_cons($ts.ast,mk_nil()),mk_nil()),
                           Absyn__ATTR(RML_FALSE,RML_FALSE,Absyn__NON_5fPARALLEL,Absyn__VAR,Absyn__BIDIR,mk_nil()),mk_nil(),mk_none());
   }
)
;

pder returns [void* ast]
@init { func = 0; var_lst = 0; cmt = 0; } :
  DER LPAR func=name_path COMMA var_lst=ident_list RPAR cmt=comment
  {
    ast = Absyn__PDER(func, var_lst, mk_some_or_none(cmt));
  }
  ;

ident_list returns [void* ast]
@init { i = 0; il = 0; } :
  i=IDENT (COMMA il=ident_list)?
    {
      ast = mk_cons(token_to_scon(i), or_nil(il));
    }
  ;


overloading returns [void* ast]
@init { nl = 0; cmt = 0; } :
  OVERLOAD LPAR nl=name_list RPAR cmt=comment
    {
      ast = Absyn__OVERLOAD(nl, mk_some_or_none(cmt));
    }
  ;

base_prefix returns [void* ast] :
  tp=type_prefix {ast = Absyn__ATTR(tp.flow, tp.stream, tp.parallelism, tp.variability, tp.direction, mk_nil());}
  ;

name_list returns [void* ast]
@init { n = 0; nl = 0; } :
  n=name_path (COMMA nl=name_list)?
    {
      ast = mk_cons(n, or_nil(nl));
    }
  ;

enumeration returns [void* ast]
@init { el = 0; c = 0; cmt = 0; } :
  ENUMERATION LPAR (el=enum_list | c=COLON ) RPAR cmt=comment
    {
      if (c) {
        ast = Absyn__ENUMERATION(Absyn__ENUM_5fCOLON, mk_some_or_none(cmt));
      } else {
        ast = Absyn__ENUMERATION(Absyn__ENUMLITERALS(el), mk_some_or_none(cmt));
      }
    }
  ;

enum_list returns [void* ast]
@init { e = 0; el = 0; } :
  e=enumeration_literal ( COMMA el=enum_list )? { ast = mk_cons(e, or_nil(el)); }
  ;

enumeration_literal returns [void* ast]
@init { i1 = 0; c1 = 0; } :
  i1=IDENT c1=comment { ast = Absyn__ENUMLITERAL(token_to_scon(i1),mk_some_or_none(c1)); }
  ;

composition returns [void* ast, void* ann]
@init { $ann = mk_nil(); el = 0; els = 0; a = 0; } :
  el=element_list[&$ann] els=composition2[&$ann] (a=annotation SEMICOLON)?
  {
    $ast = mk_cons(Absyn__PUBLIC(el),els);
    $ann = a ? mk_cons(a,$ann) : $ann;
  }
  ;

composition2 [void **ann] returns [void* ast]
@init { ext = 0; el = 0; } :
  ( ext=external_clause? { ast = or_nil(ext); }
  | ( el=public_element_list[ann]
    | el=protected_element_list[ann]
    | el=initial_equation_clause[ann]
    | el=initial_algorithm_clause[ann]
    | el=equation_clause[ann]
    | el=constraint_clause[ann]
    | el=algorithm_clause[ann]
    ) els=composition2[ann] {ast = mk_cons(el,els);}
  )
  ;

external_clause returns [void* ast]
@init { retexp.ast = 0; lang = 0; funcname = 0; expl = 0; ann1 = 0;} :
        EXTERNAL
        ( lang=language_specification )?
        ( ( retexp=component_reference EQUALS )?
          funcname=IDENT LPAR ( expl=expression_list )? RPAR )?
        ( ann1 = annotation )? SEMICOLON
          {
            ast = Absyn__EXTERNALDECL(
                    funcname ? mk_some(token_to_scon(funcname)) : mk_none(),
                    mk_some_or_none(lang),
                    mk_some_or_none(retexp.ast),
                    or_nil(expl),
                    mk_some_or_none(ann1));
            ast = mk_cons(Absyn__EXTERNAL(ast, mk_none()), mk_nil());
          }
        ;

external_annotation returns [void* ast]
@init { ann = 0; } :
  ann=annotation SEMICOLON { ast = ann; }
  ;

public_element_list [void **ann] returns [void* ast]
@init { es = 0; } :
  PUBLIC es=element_list[ann] { ast = Absyn__PUBLIC(es); }
  ;

protected_element_list [void **ann] returns [void* ast]
@init { es = 0; } :
  PROTECTED es=element_list[ann] {ast = Absyn__PROTECTED(es);}
  ;

language_specification returns [void* ast] :
  id=STRING {ast = token_to_scon(id);}
  ;

element_list [void **ann] returns [void* ast]
@init {
  int first = 0, last = 0;
  e.ast = 0;
  ast = 0;
  first = omc_first_comment;
  last = LT(1)->getTokenIndex(LT(1));
  omc_first_comment = last;
  a = 0;
  s = 0;
  es = 0;
} :
  (((  e=element
     | ( { ModelicaParser_langStd < 31 || 1 }? a=annotation {*ann = mk_cons(a, *ann);} )
    ) s=SEMICOLON
   ) es=element_list[ann]
  )?
    {
      if (e.ast) {
        ast = mk_cons(Absyn__ELEMENTITEM(e.ast), es);
      } else if (a) {
        ast = es;
      } else {
        ast = mk_nil();
      }
      for (;first<last;last--) {
        pANTLR3_COMMON_TOKEN tok = INPUT->get(INPUT,last-1);
        if (tok->getChannel(tok) == HIDDEN && (tok->type == LINE_COMMENT || tok->type == ML_COMMENT)) {
          ast = mk_cons(Absyn__LEXER_5fCOMMENT(mk_scon((char*)tok->getText(tok)->chars)),ast);
        }
      }
    }
  ;

element returns [void* ast]
@declarations { void *final = 0, *innerouter = 0, *redecl = 0; }
@init { cc = 0; f = 0; i = 0; o = 0; r = 0; $ast = 0; cdef.ast = 0; constr = 0; }
  :
    ic=import_clause { $ast = Absyn__ELEMENT(RML_FALSE,mk_none(),Absyn__NOT_5fINNER_5fOUTER, ic, PARSER_INFO($start), mk_none()); }
  | ec=extends_clause { $ast = Absyn__ELEMENT(RML_FALSE,mk_none(),Absyn__NOT_5fINNER_5fOUTER, ec, PARSER_INFO($start),mk_none()); }
  | du=defineunit_clause { $ast = du; }
  | (r=REDECLARE)? (f=FINAL)? (i=INNER)? (o=T_OUTER)? { final = mk_bcon(f); innerouter = make_inner_outer(i,o); }
    ( ( cdef=class_definition[f != NULL] | cc=component_clause )
        {
           if (!cc)
             $ast = Absyn__ELEMENT(final, r != NULL ? mk_some(make_redeclare_keywords(false,r != NULL)) : mk_none(),
                                  innerouter,
                                  Absyn__CLASSDEF(RML_FALSE, cdef.ast),
                                  PARSER_INFO($start), mk_none());
           else
             $ast = Absyn__ELEMENT(final, r != NULL ? mk_some(make_redeclare_keywords(false,r != NULL)) : mk_none(), innerouter,
                                   cc, PARSER_INFO($start), mk_none());
        }
    | (REPLACEABLE ( cdef=class_definition[f != NULL] | cc=component_clause ) constr=constraining_clause_comment? )
        {
           if (cc)
             $ast = Absyn__ELEMENT(final, mk_some(make_redeclare_keywords(true,r != NULL)), innerouter,
                                   cc, PARSER_INFO($start), mk_some_or_none(constr));
           else
             $ast = Absyn__ELEMENT(final, mk_some(make_redeclare_keywords(true,r != NULL)), innerouter,
                                   Absyn__CLASSDEF(RML_TRUE, cdef.ast), PARSER_INFO($start), mk_some_or_none(constr));
        }
    )
  | conn=CONNECT
    {
       modelicaParserAssert(0, "Found the start of a connect equation but expected an element (are you missing the equation keyword?)", element, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition);
    }
  ;

import_clause returns [void* ast]
@init { cmt = 0; im = 0; imp = 0; } :
  im=IMPORT (imp=explicit_import_name | imp=implicit_import_name) cmt=comment
    {
      ast = Absyn__IMPORT(imp, mk_some_or_none(cmt), PARSER_INFO($im));
    }
  ;

defineunit_clause returns [void* ast]
@init { id = 0; na = 0; } :
  DEFINEUNIT id=IDENT (LPAR na=named_arguments RPAR)?
    {
      ast = Absyn__DEFINEUNIT(token_to_scon(id),or_nil(na));
    }
  ;

explicit_import_name returns [void* ast]
@init { id = 0; p = 0; } :
  (id=IDENT|id=CODE) EQUALS p=name_path {ast = Absyn__NAMED_5fIMPORT(token_to_scon(id),p);}
  ;

implicit_import_name returns [void* ast]
@init { np.lst = 0; np.ast = 0; np.unqual = 0; } :
  np=name_path_star
  {
    ast = np.lst ? Absyn__GROUP_5fIMPORT(np.ast, np.lst) : np.unqual ? Absyn__UNQUAL_5fIMPORT(np.ast) : Absyn__QUAL_5fIMPORT(np.ast);
  }
;

/*
 * 2.2.3 Extends
 */

// Note that this is a minor modification of the standard by
// allowing the comment.
extends_clause returns [void* ast]
@init { path = 0; mod = 0; ann = 0; } :
  EXTENDS path=name_path (mod=class_modification)? (ann=annotation)?
  {
    ast = Absyn__EXTENDS(path,or_nil(mod),mk_some_or_none(ann));
  }
  ;

constraining_clause_comment returns [void* ast]
@init { constr = 0; cmt = 0; } :
  constr=constraining_clause cmt=comment { $ast = Absyn__CONSTRAINCLASS(constr, mk_some_or_none(cmt)); }
  ;

constraining_clause returns [void* ast]
@init { np = 0; mod = 0; } :
    EXTENDS np=name_path  (mod=class_modification)? { ast = Absyn__EXTENDS(np,or_nil(mod),mk_none()); }
  | CONSTRAINEDBY np=name_path (mod=class_modification)? { ast = Absyn__EXTENDS(np,or_nil(mod),mk_none()); }
  ;

/*
 * 2.2.4 Component clause
 */

component_clause returns [void* ast]
@declarations { void *arr = 0, *ar_option = 0; }
@init { path.ast = 0; clst = 0; ast = 0; } :
  tp=type_prefix path=type_specifier clst=component_list
    {
      // Take the last (array subscripts) from type and move it to ATTR
      if (RML_GETHDR($path.ast) == RML_STRUCTHDR(2, Absyn__TPATH_3dBOX2)) // is TPATH(path, arr)
      {
        struct rml_struct *p = (struct rml_struct*)RML_UNTAGPTR($path.ast);
        ar_option = p->data[1+UNBOX_OFFSET];  // get the array option
        p->data[1+UNBOX_OFFSET] = mk_none();  // replace the array with nothing
      }
      else if (RML_GETHDR($path.ast) == RML_STRUCTHDR(3, Absyn__TCOMPLEX_3dBOX3))
      {
        struct rml_struct *p = (struct rml_struct*)RML_UNTAGPTR($path.ast);
        ar_option = p->data[2+UNBOX_OFFSET];         // get the array option
        p->data[2+UNBOX_OFFSET] = mk_none();  // replace the array with nothing
      }
      else
      {
        fprintf(stderr, "component_clause error\n");
      }

      { /* adrpo - use the ANSI C standard */
        // no arr was set, inspect ar_option and fix it
        struct rml_struct *p = (struct rml_struct*)RML_UNTAGPTR(ar_option);
        if (optionNone(ar_option))
        {
          arr = mk_nil();
        }
        else // is SOME(arr)
        {
          arr = p->data[0];
        }
      }

      ast = Absyn__COMPONENTS(Absyn__ATTR(tp.flow, tp.stream, tp.parallelism, tp.variability, tp.direction, arr), $path.ast, clst);
    }
  ;

type_prefix returns [void* flow, void* stream, void* parallelism, void* variability, void* direction]
@init { fl = 0; st = 0; srd = 0; glb = 0; di = 0; pa = 0; co = 0; in = 0; out = 0; } :
  (fl=FLOW|st=STREAM)? (srd=T_LOCAL|glb=T_GLOBAL)? (di=DISCRETE|pa=PARAMETER|co=CONSTANT)? (in=T_INPUT|out=T_OUTPUT)?
    {
      $flow = mk_bcon(fl);
      $stream = mk_bcon(st);
      $parallelism = srd ? Absyn__PARLOCAL : glb ? Absyn__PARGLOBAL : Absyn__NON_5fPARALLEL;
      $variability = di ? Absyn__DISCRETE : pa ? Absyn__PARAM : co ? Absyn__CONST : Absyn__VAR;
      $direction = in ? Absyn__INPUT : out ? Absyn__OUTPUT : Absyn__BIDIR;
    }
  ;

type_specifier returns [void* ast]
@init { ts = 0; as = 0; } :
  np=name_path
  (lt=LESS ts=type_specifier_list gt=GREATER)? (as=array_subscripts)?
    {
      if (ts != NULL) {
        modelicaParserAssert(metamodelica_enabled(),"Algebraic data types are only available in MetaModelica", type_specifier, $start->line, $start->charPosition+1, $gt->line, $gt->charPosition+2);

        $ast = Absyn__TCOMPLEX(np,ts,mk_some_or_none(as));
      } else {
        $ast = Absyn__TPATH(np,mk_some_or_none(as));
      }
    }
  ;

type_specifier_list returns [void* ast]
@init { np1.ast; np2 = 0; } :
  np1=type_specifier ( COMMA np2=type_specifier_list )? { ast = mk_cons($np1.ast,or_nil(np2)); }
  ;

component_list returns [void* ast]
@init { c = 0; cs = 0; } :
  c=component_declaration (COMMA cs=component_list)? {ast = mk_cons(c, or_nil(cs));}
  ;

component_declaration returns [void* ast]
@init { decl = 0; cond = 0; cmt = 0; } :
  decl=declaration (cond=conditional_attribute)? cmt=comment
  {
    ast = Absyn__COMPONENTITEM(decl, mk_some_or_none(cond), mk_some_or_none(cmt));
  }
  ;

conditional_attribute returns [void* ast] :
        IF e=expression {ast = e;}
        ;

declaration returns [void* ast]
@init { id = 0; as = 0; mod = 0; } :
  ( id=IDENT | id=OPERATOR ) (as=array_subscripts)? (mod=modification)?
    {
      ast = Absyn__COMPONENT(token_to_scon(id), or_nil(as), mk_some_or_none(mod));
    }
  ;

/*
 * 2.2.5 Modification
 */

modification returns [void* ast]
@init { e = 0; eq = 0; cm = 0; } :
  ( cm=class_modification ( eq=EQUALS e=expression )?
  | eq=EQUALS e=expression
  | eq=ASSIGN e=expression
  )
    {
      ast = Absyn__CLASSMOD(or_nil(cm), e ? Absyn__EQMOD(e,PARSER_INFO($eq)) : Absyn__NOMOD);
    }
  ;

class_modification returns [void* ast]
@init { as = 0; ast = 0; } :
  LPAR ( as=argument_list )? RPAR { ast = or_nil(as); }
  ;

argument_list returns [void* ast]
@init { a = 0; as = 0; } :
  a=argument ( COMMA as=argument_list )? { ast = mk_cons(a, or_nil(as)); }
  ;

argument returns [void* ast]
@init { em = 0; er.ast = 0; } :
  ( em=element_modification_or_replaceable { $ast = em; }
  | er=element_redeclaration { $ast = $er.ast; }
  )
  ;

element_modification_or_replaceable returns [void* ast]
@init { ast = NULL; em.ast = NULL; e = 0; f = 0; } :
    (e=EACH)? (f=FINAL)? ( em=element_modification[e ? Absyn__EACH : Absyn__NON_5fEACH, mk_bcon(f)]
                         | er=element_replaceable[e != NULL,f != NULL,false]
                         )
      {
        ast = $em.ast ? $em.ast : $er.ast;
      }
    ;

element_modification [void *each, void *final] returns [void* ast]
@init { $ast = NULL; mod = 0; cmt = 0; br = 0;} :
  path=name_path2 (br=LBRACK | ((mod=modification)? cmt=string_comment))
  {
    if (br) {
      ModelicaParser_lexerError = ANTLR3_TRUE;
      c_add_source_message(NULL, 2, ErrorType_syntax, ErrorLevel_error, "Subscripting modifiers is not allowed. Apply the modification on the whole identifier using an array-expression or an each-modifier.",
              NULL, 0, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition,
              ModelicaParser_readonly, ModelicaParser_filename_C_testsuiteFriendly);
    }
    $ast = Absyn__MODIFICATION(final, each, path, mk_some_or_none(mod), mk_some_or_none(cmt), PARSER_INFO($start));
  }
  ;

element_redeclaration returns [void* ast]
@init { $ast = NULL; er.ast = NULL; f = 0; cc = 0; e = 0; cdef.ast = 0; } :
  REDECLARE (e=EACH)? (f=FINAL)?
  ( (cdef=class_definition[f != NULL] | cc=component_clause1) | er=element_replaceable[e != NULL,f != NULL, true] )
     {
       if ($er.ast) {
         $ast = $er.ast;
       } else {
         $ast = Absyn__REDECLARATION(mk_bcon(f), make_redeclare_keywords(false,true), e ? Absyn__EACH : Absyn__NON_5fEACH, $cc.ast ? $cc.ast : Absyn__CLASSDEF(RML_FALSE,$cdef.ast), mk_none(), PARSER_INFO($start));
       }
     }
  ;

element_replaceable [int each, int final, int redeclare] returns [void* ast]
@init { $ast = NULL; e_spec = 0; cd.ast = 0; constr = 0; } :
  REPLACEABLE ( cd=class_definition[final] | e_spec=component_clause1 ) constr=constraining_clause_comment?
  {
      $ast = Absyn__REDECLARATION(mk_bcon(final), make_redeclare_keywords(true,redeclare),
                                  each ? Absyn__EACH : Absyn__NON_5fEACH, e_spec ? e_spec : Absyn__CLASSDEF(RML_TRUE, $cd.ast),
                                  mk_some_or_none(constr), PARSER_INFO($start));
  }
  ;

component_clause1 returns [void* ast]
@init { attr = NULL; ts.ast = 0; comp_decl = 0; } :
  attr=base_prefix ts=type_specifier comp_decl=component_declaration1
    {
      ast = Absyn__COMPONENTS(attr, $ts.ast, mk_cons(comp_decl, mk_nil()));
    }
  ;

component_declaration1 returns [void* ast]
@init { decl = 0; cmt = 0; } :
  decl=declaration cmt=comment  { ast = Absyn__COMPONENTITEM(decl, mk_none(), mk_some_or_none(cmt)); }
  ;


/*
 * 2.2.6 Equations
 */

initial_equation_clause [void **ann] returns [void* ast] :
  { LA(2)==EQUATION }?
  INITIAL EQUATION es=equation_annotation_list[ann] { ast = Absyn__INITIALEQUATIONS(es); }
  ;

equation_clause [void **ann] returns [void* ast] :
  EQUATION es=equation_annotation_list[ann] { ast = Absyn__EQUATIONS(es); }
  ;

constraint_clause [void **ann] returns [void* ast] :
  CONSTRAINT cs=constraint_annotation_list[ann] { ast = Absyn__CONSTRAINTS(cs); }
  ;

equation_annotation_list [void **ann] returns [void* ast]
@init {
  int first,last;
  $ast = 0;
  first = omc_first_comment;
  last = LT(1)->getTokenIndex(LT(1));
  omc_first_comment = last;
  ea = 0;
  eq.ast = 0;
  es = 0;
} :
  { LA(1) == END_IDENT || LA(1) == CONSTRAINT || LA(1) == EQUATION || LA(1) == T_ALGORITHM || LA(1)==INITIAL || LA(1) == PROTECTED || LA(1) == PUBLIC }?
    {
      ast = mk_nil();
      for (;first<last;last--) {
        pANTLR3_COMMON_TOKEN tok = INPUT->get(INPUT,last-1);
        if (tok->getChannel(tok) == HIDDEN && (tok->type == LINE_COMMENT || tok->type == ML_COMMENT)) {
          ast = mk_cons(Absyn__EQUATIONITEMCOMMENT(mk_scon((char*)tok->getText(tok)->chars)),ast);
        }
      }
    }
  |
  ( eq=equation SEMICOLON | ea=annotation SEMICOLON {*ann = mk_cons(ea,*ann);}) es=equation_annotation_list[ann]
    {
      ast = ea ? es : mk_cons(eq.ast,es);
      for (;first<last;last--) {
        pANTLR3_COMMON_TOKEN tok = INPUT->get(INPUT,last-1);
        if (tok->getChannel(tok) == HIDDEN && (tok->type == LINE_COMMENT || tok->type == ML_COMMENT)) {
          ast = mk_cons(Absyn__EQUATIONITEMCOMMENT(mk_scon((char*)tok->getText(tok)->chars)),ast);
        }
      }
    }
  ;

constraint_annotation_list [void **ann] returns [void* ast]
@init { co = 0; c = 0; }
:
  { LA(1) == END_IDENT || LA(1) == CONSTRAINT || LA(1) == EQUATION || LA(1) == T_ALGORITHM || LA(1)==INITIAL || LA(1) == PROTECTED || LA(1) == PUBLIC }?
    { ast = mk_nil(); }
  |
  ( co=constraint SEMICOLON { c = co; }
  | c=annotation SEMICOLON { *ann = mk_cons(c,ann); }
  ) cs=constraint_annotation_list[ann] { ast = c ? mk_cons(c,cs) : cs; }
  ;

algorithm_clause [void **ann] returns [void* ast]
@init{ as = 0; } :
  T_ALGORITHM as=algorithm_annotation_list[ann] { ast = Absyn__ALGORITHMS(as); }
  ;

initial_algorithm_clause [void **ann] returns [void* ast]
@init{ as = 0; } :
  { LA(2)==T_ALGORITHM }?
  INITIAL T_ALGORITHM as=algorithm_annotation_list[ann] { ast = Absyn__INITIALALGORITHMS(as); }
  ;

algorithm_annotation_list [void **ann] returns [void* ast]
@init {
  int first,last,isalg = 0;
  $ast = 0;
  first = omc_first_comment;
  last = LT(1)->getTokenIndex(LT(1));
  omc_first_comment = last;
  a = 0;
  al.ast = 0;
  as = 0;
} :
  { LA(1) == END_IDENT || LA(1) == EQUATION || LA(1) == T_ALGORITHM || LA(1)==INITIAL || LA(1) == PROTECTED || LA(1) == PUBLIC }?
    {
      ast = mk_nil();
      for (;first<last;last--) {
        pANTLR3_COMMON_TOKEN tok = INPUT->get(INPUT,last-1);
        if (tok->getChannel(tok) == HIDDEN && (tok->type == LINE_COMMENT || tok->type == ML_COMMENT)) {
          ast = mk_cons(Absyn__ALGORITHMITEMCOMMENT(mk_scon((char*)tok->getText(tok)->chars)),ast);
        }
      }
    }
  |
  ( al=algorithm SEMICOLON | a=annotation SEMICOLON { *ann = mk_cons(a,*ann); }) as=algorithm_annotation_list[ann]
  {
    if (a) {
      ast = as;
    } else {
      ast = mk_cons(al.ast,as);
    }
    for (;first<last;last--) {
      pANTLR3_COMMON_TOKEN tok = INPUT->get(INPUT,last-1);
      if (tok->getChannel(tok) == HIDDEN && (tok->type == LINE_COMMENT || tok->type == ML_COMMENT)) {
        ast = mk_cons(Absyn__ALGORITHMITEMCOMMENT(mk_scon((char*)tok->getText(tok)->chars)),ast);
      }
    }
  }
  ;

equation returns [void* ast]
@init { cmt = 0; e = 0; e1 = 0; e2 = 0; eq.ast = 0; ee.ast = 0; } :
  ( ee=equality_or_noretcall_equation { e = ee.ast; }
  | e=conditional_equation_e
  | e=for_clause_e
  | e=parfor_clause_e
  | e=connect_clause
  | e=when_clause_e
  | FAILURE LPAR eq=equation RPAR { e = Absyn__EQ_5fFAILURE(eq.ast); }
  | EQUALITY LPAR e1=expression EQUALS e2=expression RPAR
    {
      e = Absyn__EQ_5fNORETCALL(Absyn__CREF_5fIDENT(mk_scon("equality"),mk_nil()),Absyn__FUNCTIONARGS(mk_cons(e1,mk_cons(e2,mk_nil())),mk_nil()));
    }
  )
  cmt=comment
  {
    $ast = Absyn__EQUATIONITEM(e, mk_some_or_none(cmt), PARSER_INFO($start));
  }
  ;

constraint returns [void* ast]
@init { a = 0; al.ast = 0; e1 = 0; e2 = 0; cmt = 0; } :
  ( a = simple_expr
  | a=conditional_equation_a
  | a=for_clause_a
  | a=parfor_clause_a
  | a=while_clause
  | a=when_clause_a
  | BREAK { a = Absyn__ALG_5fBREAK; }
  | RETURN { a = Absyn__ALG_5fRETURN; }
  | FAILURE LPAR al=algorithm RPAR { a = Absyn__ALG_5fFAILURE(mk_cons(al.ast,mk_nil())); }
  | EQUALITY LPAR e1=expression ASSIGN e2=expression RPAR
    {
      a = Absyn__ALG_5fNORETCALL(Absyn__CREF_5fIDENT(mk_scon("equality"),mk_nil()),Absyn__FUNCTIONARGS(mk_cons(e1,mk_cons(e2,mk_nil())),mk_nil()));
    }
  )
  cmt=comment
  {
    $ast = a;
  }
  ;


algorithm returns [void* ast]
@init { aa.ast = 0; al.ast = 0; a = 0; e1 = 0; e2 = 0; cmt = 0; } :
  ( aa=assign_clause_a { a = aa.ast; }
  | a=conditional_equation_a
  | a=for_clause_a
  | a=parfor_clause_a
  | a=while_clause
  | a=when_clause_a
  | BREAK { a = Absyn__ALG_5fBREAK; }
  | RETURN { a = Absyn__ALG_5fRETURN; }
  | FAILURE LPAR al=algorithm RPAR { a = Absyn__ALG_5fFAILURE(mk_cons(al.ast,mk_nil())); }
  | EQUALITY LPAR e1=expression ASSIGN e2=expression RPAR
    {
      a = Absyn__ALG_5fNORETCALL(Absyn__CREF_5fIDENT(mk_scon("equality"),mk_nil()),Absyn__FUNCTIONARGS(mk_cons(e1,mk_cons(e2,mk_nil())),mk_nil()));
    }
  )
  cmt=comment
  {
    $ast = Absyn__ALGORITHMITEM(a, mk_some_or_none(cmt), PARSER_INFO($start));
  }
  ;

assign_clause_a returns [void* ast]
@declarations { char *s1 = 0; }
@init { e1 = 0; eq = 0; e2 = 0; } :
  /* MetaModelica allows pattern matching on arbitrary expressions in algorithm sections... */
  e1=simple_expression
    ( (ASSIGN|eq=EQUALS) e2=expression
      {
        modelicaParserAssert(eq==0,"Algorithms can not contain equations ('='), use assignments (':=') instead", assign_clause_a, $eq->line, $eq->charPosition+1, $eq->line, $eq->charPosition+2);
        {
          int looks_like_cref = (RML_GETHDR(e1) == RML_STRUCTHDR(1, Absyn__CREF_3dBOX1));
          int looks_like_call = ((RML_GETHDR(e1) == RML_STRUCTHDR(1, Absyn__TUPLE_3dBOX1)) && (RML_GETHDR(e2) == RML_STRUCTHDR(2, Absyn__CALL_3dBOX2)));
          int looks_like_der_cr = !looks_like_cref && !looks_like_call && call_looks_like_der_cr(e1);
          modelicaParserAssert(eq!=0 || metamodelica_enabled() || looks_like_cref || looks_like_call || looks_like_der_cr,
              "Modelica assignment statements are either on the form 'component_reference := expression' or '( output_expression_list ) := function_call'",
              assign_clause_a, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition);
          if (looks_like_der_cr && !metamodelica_enabled()) {
            c_add_source_message(NULL,2, ErrorType_syntax, ErrorLevel_warning, "der(cr) := exp is not legal Modelica code. OpenModelica accepts it for interoperability with non-standards-compliant Modelica tools. There is no way to suppress this warning.",
              NULL, 0, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition+1,
              ModelicaParser_readonly, ModelicaParser_filename_C_testsuiteFriendly);
          }
        }
        $ast = Absyn__ALG_5fASSIGN(e1,e2);
      }
    |
      {
        modelicaParserAssert(RML_GETHDR(e1) == RML_STRUCTHDR(2, Absyn__CALL_3dBOX2), "Only function call expressions may stand alone in an algorithm section",
                             assign_clause_a, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition);
        { /* uselsess block for ANSI C crap */
        struct rml_struct *p = (struct rml_struct*)RML_UNTAGPTR(e1);
        $ast = Absyn__ALG_5fNORETCALL(p->data[0+UNBOX_OFFSET],p->data[1+UNBOX_OFFSET]);
        }
      }
    )
  ;

equality_or_noretcall_equation returns [void* ast]
@init { ass = 0; e1 = 0; ass = 0; e2 = 0; } :
  e1=simple_expression
    (  (EQUALS | ass=ASSIGN) e2=expression
      {
        modelicaParserAssert(ass==0,"Equations can not contain assignments (':='), use equality ('=') instead", equality_or_noretcall_equation, $ass->line, $ass->charPosition+1, $ass->line, $ass->charPosition+2);
        $ast = Absyn__EQ_5fEQUALS(e1,e2);
      }
    | {LA(1) != EQUALS && LA(1) != ASSIGN}? /* It has to be a CALL */
       {
         struct rml_struct *p;
         modelicaParserAssert(RML_GETHDR(e1) == RML_STRUCTHDR(2, Absyn__CALL_3dBOX2),"A singleton expression in an equation section is required to be a function call", equality_or_noretcall_equation, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition);
         p = (struct rml_struct*)RML_UNTAGPTR(e1);
         $ast = Absyn__EQ_5fNORETCALL(p->data[0+UNBOX_OFFSET],p->data[1+UNBOX_OFFSET]);
       }
    )
  ;

conditional_equation_e returns [void* ast]
@init { i = 0; else_b = 0; then_b = 0; else_if_b = 0; } :
  IF e=expression THEN then_b=equation_list else_if_b=equation_elseif_list? ( ELSE else_b=equation_list )? (i=END_IF|t=END_IDENT|t=END_FOR|t=END_WHEN)
    {
      modelicaParserAssert(i,else_b ? "Expected 'end if'; did you use a nested 'else if' instead of 'elseif'?" : "Expected 'end if'",conditional_equation_e,t->line, t->charPosition+1, LT(1)->line, LT(1)->charPosition+1);
      ast = Absyn__EQ_5fIF(e, then_b, or_nil(else_if_b), or_nil(else_b));
    }
  ;

conditional_equation_a returns [void* ast]
@init { i = 0; else_b = 0; else_if_b = 0; } :
  IF e=expression THEN then_b=algorithm_list else_if_b=algorithm_elseif_list? ( ELSE else_b=algorithm_list )? (i=END_IF|t=END_IDENT|t=END_FOR|t=END_WHEN|t=END_WHILE)
  {
    modelicaParserAssert(i,else_b ? "Expected 'end if'; did you use a nested 'else if' instead of 'elseif'?" : "Expected 'end if'",conditional_equation_a,t->line, t->charPosition+1, LT(1)->line, LT(1)->charPosition+1);
    ast = Absyn__ALG_5fIF(e, then_b, or_nil(else_if_b), or_nil(else_b));
  }
  ;

for_clause_e returns [void* ast]
@init { is = 0; es = 0; } :
  FOR is=for_indices LOOP es=equation_list END_FOR { ast = Absyn__EQ_5fFOR(is,es); }
  ;

for_clause_a returns [void* ast]
@init { is = 0; as = 0; } :
  FOR is=for_indices LOOP as=algorithm_list END_FOR { ast = Absyn__ALG_5fFOR(is,as); }
  ;

parfor_clause_e returns [void* ast]
@init { is = 0; es = 0; } :
  PARFOR is=for_indices LOOP es=equation_list END_PARFOR { ast = Absyn__EQ_5fFOR(is,es); }
  ;

parfor_clause_a returns [void* ast]
@init { is = 0; as = 0; } :
  PARFOR is=for_indices LOOP as=algorithm_list END_PARFOR { ast = Absyn__ALG_5fPARFOR(is,as); }
  ;

while_clause returns [void* ast]
@init { e = 0; as = 0; } :
  WHILE e=expression LOOP as=algorithm_list END_WHILE { ast = Absyn__ALG_5fWHILE(e,as); }
  ;

when_clause_e returns [void* ast]
@init{ es = 0; body = 0; es = 0; } :
  WHEN e=expression THEN body=equation_list es=else_when_e_list? END_WHEN
    {
      ast = Absyn__EQ_5fWHEN_5fE(e,body,or_nil(es));
    }
  ;

else_when_e_list returns [void* ast]
@init{ es = 0; e = 0;} :
  e=else_when_e es=else_when_e_list? { ast = mk_cons(e,or_nil(es)); }
  ;

else_when_e returns [void* ast]
@init{ es = 0; es = 0; } :
  ELSEWHEN e=expression THEN es=equation_list { ast = mk_tuple2(e,es); }
  ;

when_clause_a returns [void* ast]
@init{ e = 0; body = 0; es = 0; } :
  WHEN e=expression THEN body=algorithm_list es=else_when_a_list? END_WHEN
    {
      ast = Absyn__ALG_5fWHEN_5fA(e,body,or_nil(es));
    }
  ;

else_when_a_list returns [void* ast]
@init{ e = 0; es = 0; } :
  e=else_when_a es=else_when_a_list? { ast = mk_cons(e,or_nil(es)); }
  ;

else_when_a returns [void* ast]
@init{ e = 0; as = 0; } :
  ELSEWHEN e=expression THEN as=algorithm_list { ast = mk_tuple2(e,as); }
  ;

equation_elseif_list returns [void* ast]
@init{ e = 0; es = 0; } :
  e=equation_elseif es=equation_elseif_list? { ast = mk_cons(e,or_nil(es)); }
  ;

equation_elseif returns [void* ast]
@init{ e = 0; es = 0; } :
  ELSEIF e=expression THEN es=equation_list { ast = mk_tuple2(e,es); }
  ;

algorithm_elseif_list returns [void* ast]
@init{ a = 0; as = 0; } :
  a=algorithm_elseif as=algorithm_elseif_list? { ast = mk_cons(a,or_nil(as)); }
  ;

algorithm_elseif returns [void* ast]
@init{ e = 0; as = 0; } :
  ELSEIF e=expression THEN as=algorithm_list { ast = mk_tuple2(e,as); }
  ;

equation_list_then returns [void* ast]
@init{ e.ast = 0; es = 0; } :
    { LA(1) == THEN }? {ast = mk_nil();}
  | (e=equation SEMICOLON es=equation_list_then) { ast = mk_cons(e.ast,es); }
  ;

equation_list returns [void* ast]
@init {
  int first = 0, last = 0;
  e.ast = 0;
  es = 0;
  first = omc_first_comment;
  last = LT(1)->getTokenIndex(LT(1));
  omc_first_comment = last;
} :
  {LA(1) != END_IDENT || LA(1) != END_IF || LA(1) != END_WHEN || LA(1) != END_FOR}?
    {
       ast = mk_nil();
      for (;first<last;last--) {
        pANTLR3_COMMON_TOKEN tok = INPUT->get(INPUT,last-1);
        if (tok->getChannel(tok) == HIDDEN && (tok->type == LINE_COMMENT || tok->type == ML_COMMENT)) {
          ast = mk_cons(Absyn__EQUATIONITEMCOMMENT(mk_scon((char*)tok->getText(tok)->chars)),ast);
        }
      }
    }
  |
  ( e=equation SEMICOLON es=equation_list ) {
    ast = es;
    ast = mk_cons(e.ast,ast);
    for (;first<last;last--) {
      pANTLR3_COMMON_TOKEN tok = INPUT->get(INPUT,last-1);
      if (tok->getChannel(tok) == HIDDEN && (tok->type == LINE_COMMENT || tok->type == ML_COMMENT)) {
        ast = mk_cons(Absyn__EQUATIONITEMCOMMENT(mk_scon((char*)tok->getText(tok)->chars)),ast);
      }
    }
  }
  ;

algorithm_list returns [void* ast]
@init { a.ast = 0; as = 0; } :
  {LA(1) != END_IDENT || LA(1) != END_IF || LA(1) != END_WHEN || LA(1) != END_FOR || LA(1) != END_WHILE}?
    { ast = mk_nil(); }
  | a=algorithm SEMICOLON as=algorithm_list { ast = mk_cons(a.ast,as); }
  ;

connect_clause returns [void* ast] :
  CONNECT LPAR cr1=component_reference COMMA cr2=component_reference RPAR
  {
    ast = Absyn__EQ_5fCONNECT(cr1.ast,cr2.ast);
  }
  ;

/* adrpo: 2010-10-11, replaced commented-out part with the rule above
                      which is conform to the grammar in the Modelica specification!
connect_clause returns [void* ast] :
  CONNECT LPAR cr1=connector_ref COMMA cr2=connector_ref RPAR {ast = Absyn__EQ_5fCONNECT(cr1,cr2);}
  ;

connector_ref returns [void* ast]
@init{ as = 0; cr2 = 0; } :
  id=IDENT ( as=array_subscripts )? ( DOT cr2=connector_ref_2 )?
    {
      if (cr2)
        ast = Absyn__CREF_5fQUAL(token_to_scon(id),or_nil(as),cr2);
      else
        ast = Absyn__CREF_5fIDENT(token_to_scon(id),or_nil(as));
    }
  ;

connector_ref_2 returns [void* ast]
@init{ id = 0; as = 0; } :
  id=IDENT ( as=array_subscripts )? {ast = Absyn__CREF_5fIDENT(token_to_scon(id),or_nil(as));}
  ;
*/

/*
 * 2.2.7 Expressions
 */
expression returns [void* ast] :
  ( e=if_expression { ast = e; }
  | e=simple_expression { ast = e; }
  | e=code_expression { ast = e; }
  | e=match_expression { ast = e; }
  )
  ;

part_eval_function_expression returns [void* ast]
@init { cr.ast = 0; fc = 0; } :
  FUNCTION cr=component_reference fc=function_call { ast = Absyn__PARTEVALFUNCTION(cr.ast, fc); }
  ;

if_expression returns [void* ast]
@init{ cond = 0; e1 = 0; es = 0; e2 = 0; } :
  IF cond=expression THEN e1=expression es=elseif_expression_list? ELSE e2=expression
  {
    ast = Absyn__IFEXP(cond,e1,e2,or_nil(es));
  }
  ;

elseif_expression_list returns [void* ast]
@init{ e = 0; es = 0; } :
  e=elseif_expression es=elseif_expression_list? { ast = mk_cons(e,or_nil(es)); }
  ;

elseif_expression returns [void* ast]
@init { e1 = 0; e2 = 0; } :
  ELSEIF e1=expression THEN e2=expression { ast = mk_tuple2(e1,e2); }
  ;

for_indices returns [void* ast]
@init{ i = 0; is = 0; } :
  i=for_index (COMMA is=for_indices)? { ast = mk_cons(i, or_nil(is)); }
  ;

for_index returns [void* ast]
@init{ i = 0; e = 0; guard = 0; } :
  (i=IDENT ((GUARD guard=expression)? T_IN e=expression)?
   {
     ast = Absyn__ITERATOR(token_to_scon(i),mk_some_or_none(guard),mk_some_or_none(e));
   }
  )
  ;

simple_expression returns [void* ast]
@init{ e1 = 0; e2 = 0; i = 0; e = 0; } :
    e1=simple_expr { ast = e; } (COLONCOLON e2=simple_expression)?
    {
      if (e2)
        ast = Absyn__CONS(e1,e2);
      else
        ast = e1;
    }
  | i=IDENT AS e=simple_expression
    {
      ast = Absyn__AS(token_to_scon(i),e);
    }
  ;

simple_expr returns [void* ast]
@init{ e1 = 0; e2 = 0; e3 = 0; } :
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

logical_expression returns [void* ast]
@init{ e1 = 0; e2 = 0; } :
  e1=logical_term { ast = e1; } ( T_OR e2=logical_term { ast = Absyn__LBINARY(ast,Absyn__OR,e2); } )*
  ;

logical_term returns [void* ast]
@init{ e2 = 0; } :
  e1=logical_factor { ast = e1; } ( T_AND e2=logical_factor { ast = Absyn__LBINARY(ast,Absyn__AND,e2); } )*
  ;

logical_factor returns [void* ast]
@init{ n = 0; e = 0; } :
  ( n=T_NOT )? e=relation { ast = n ? Absyn__LUNARY(Absyn__NOT, e) : e; }
  ;

relation returns [void* ast]
@declarations { void* op = NULL; }
@init { e1 = 0; e2 = 0; } :
  e1=arithmetic_expression
  ( ( LESS {op = Absyn__LESS;} | LESSEQ {op = Absyn__LESSEQ;}
    | GREATER {op = Absyn__GREATER;} | GREATEREQ {op = Absyn__GREATEREQ;}
    | EQEQ {op = Absyn__EQUAL;} | LESSGT {op = Absyn__NEQUAL;}
    ) e2=arithmetic_expression )?
    {
      ast = e2 ? Absyn__RELATION(e1,op,e2) : e1;
    }
  ;

arithmetic_expression returns [void* ast]
@declarations { void* op = NULL; }
@init { e1 = 0; e2 = 0; } :
  e1=unary_arithmetic_expression { ast = e1; }
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

term returns [void* ast]
@declarations { void* op = NULL; }
@init { e1 = 0; e2 = 0; } :
  e1=factor { ast = e1; }
    (
      ( STAR {op=Absyn__MUL;} | SLASH {op=Absyn__DIV;} | STAR_EW {op=Absyn__MUL_5fEW;} | SLASH_EW {op=Absyn__DIV_5fEW;} )
      e2=factor { ast = Absyn__BINARY(ast,op,e2); }
    )*
  ;

factor returns [void* ast]
@init{ e1.ast = 0; pw = 0; e2.ast = 0; } :
  e1=primary ( ( pw=POWER | pw=POWER_EW ) e2=primary )?
    {
      ast = pw ? Absyn__BINARY(e1.ast, $pw.type == POWER ? Absyn__POW : Absyn__POW_5fEW, e2.ast) : e1.ast;
    }
  ;

primary returns [void* ast]
@declarations { int tupleExpressionIsTuple = 0; }
@init { v = 0; ptr.ast = 0; el = 0; for_or_el.ast = 0; for_or_el.isFor = 0; } :
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
        modelicaParserAssert(*endptr == 0 && errno==0, "Number is too large to be represented by a double on this machine", primary, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition+1);
        c_add_source_message(NULL,2, ErrorType_syntax, ErrorLevel_warning, "\%s-bit signed integers! Transforming: \%s into a real",
          args, 2, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition+1,
          ModelicaParser_readonly, ModelicaParser_filename_C_testsuiteFriendly);
        $ast = Absyn__REAL(mk_scon(chars));
      } else {
        if (((long)1<<(RML_SIZE_INT*8-2))-1 >= l) {
          $ast = Absyn__INTEGER(RML_IMMEDIATE(RML_TAGFIXNUM(l))); /* We can't use mk_icon here - it takes "int"; not "long" */
        } else {
          long lt = ((long)1<<(RML_SIZE_INT == 8 ? 62 : 30))-1;
          if (l > lt) {
            const char *msg = RML_SIZE_INT != 8 ? "\%s-bit signed integers! Truncating integer: \%s to 1073741823" : "\%s-bit signed integers! Truncating integer: \%s to 4611686018427387903";
            c_add_source_message(NULL,2, ErrorType_syntax, ErrorLevel_warning, msg,
                                 args, 2, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition+1,
                                 ModelicaParser_readonly, ModelicaParser_filename_C_testsuiteFriendly);
            $ast = Absyn__INTEGER(RML_IMMEDIATE(RML_TAGFIXNUM(lt)));
          } else {
            $ast = Absyn__REAL(mk_scon(chars));
          }
        }
      }
    }
  | v=UNSIGNED_REAL
    {
      char* chars = (char*)$v.text->chars;
      char *endptr;
      errno = 0;
      double d = strtod(chars,&endptr);
      if (!(*endptr == 0 && errno==0)) {
        c_add_source_message(NULL,2,ErrorType_syntax, ErrorLevel_error, "\%s cannot be represented by a double on this machine", &chars, 1, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition+1, ModelicaParser_readonly, ModelicaParser_filename_C_testsuiteFriendly);
        ModelicaParser_lexerError = ANTLR3_TRUE;
      }
      $ast = Absyn__REAL(mk_scon(chars));
    }
  | v=STRING           { $ast = Absyn__STRING(mk_scon((char*)$v.text->chars)); }
  | T_FALSE            { $ast = Absyn__BOOL(RML_FALSE); }
  | T_TRUE             { $ast = Absyn__BOOL(RML_TRUE); }
  | ptr=component_reference__function_call { $ast = ptr.ast; }
  | DER el=function_call { $ast = Absyn__CALL(Absyn__CREF_5fIDENT(mk_scon("der"), mk_nil()),el); }
  | LPAR el=output_expression_list[&tupleExpressionIsTuple]
    {
      $ast = tupleExpressionIsTuple ? Absyn__TUPLE(el) : el;
    }
  | LBRACK el=matrix_expression_list RBRACK { $ast = Absyn__MATRIX(el); }
  | LBRACE for_or_el=for_or_expression_list RBRACE
    {
      if (!for_or_el.isFor) {
        modelicaParserAssert(RML_NILHDR != RML_GETHDR(for_or_el.ast) || metamodelica_enabled(), "Empty array constructors are not valid in Modelica.", primary, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition);
        $ast = Absyn__ARRAY(for_or_el.ast);
      } else {
        $ast = Absyn__CALL(Absyn__CREF_5fIDENT(mk_scon("array"), mk_nil()),for_or_el.ast);
      }
    }
  | T_END { $ast = Absyn__END; }
  )
  ;

matrix_expression_list returns [void* ast]
@init{ e1 = 0; e2 = 0; } :
  e1=expression_list (SEMICOLON e2=matrix_expression_list)? { ast = mk_cons(e1, or_nil(e2)); }
  ;

component_reference__function_call returns [void* ast]
@init{ cr.ast = 0; fc = 0; i = 0; } :
  cr=component_reference ( fc=function_call )? {
      if (fc != NULL)
        $ast = Absyn__CALL(cr.ast,fc);
      else {
        modelicaParserAssert(!cr.isNone, "NONE is not valid MetaModelica syntax regardless of what tricks RML has played on you! Use NONE() instead.", component_reference__function_call, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition);
        $ast = Absyn__CREF(cr.ast);
      }
    }
  | i=INITIAL LPAR RPAR {
      $ast = Absyn__CALL(Absyn__CREF_5fIDENT(mk_scon("initial"), mk_nil()),Absyn__FUNCTIONARGS(mk_nil(),mk_nil()));
    }
  ;

name_path_end returns [void* ast] :
  np=name_path EOF
  {
    $ast = np;
  }
  ;

name_path returns [void* ast]
@init{ dot = 0; np = 0; } :
  (dot=DOT)? np=name_path2
  {
    ast = dot ? Absyn__FULLYQUALIFIED(np) : np;
  }
  ;

name_path2 returns [void* ast]
@init{ id = 0; p = 0; } :
    { LA(2) != DOT }? (id=IDENT|id=CODE) { ast = Absyn__IDENT(token_to_scon(id)); }
  | (id=IDENT | id=CODE) DOT p=name_path { ast = Absyn__QUALIFIED(token_to_scon(id),p); }
  ;

name_path_star returns [void* ast, int unqual, void* lst]
@init{ dot = 0; np.lst = 0; np.unqual = 0; } :
  (dot=DOT)? np=name_path_star2
  {
    $ast = dot ? Absyn__FULLYQUALIFIED(np.ast) : np.ast;
    $unqual = np.unqual;
    $lst = np.lst;
  }
  ;

name_path_star2 returns [void* ast, int unqual, void* lst]
@init{ id = 0; uq = 0; mlst = 0; p.ast = 0; p.lst = 0; } :
    { LA(2) != DOT || LA(3) == LBRACE }? (id=IDENT|id=CODE) ( uq=STAR_EW | DOT LBRACE mlst=name_path_group RBRACE )?
    {
      $ast = Absyn__IDENT(token_to_scon(id));
      $unqual = uq != 0;
      $lst = mlst;
    }
  | (id=IDENT|id=CODE) DOT p=name_path_star2
    {
      $ast = Absyn__QUALIFIED(token_to_scon(id),p.ast);
      $unqual = p.unqual;
      $lst = p.lst;
    }
  ;

name_path_group returns [void* ast]
@init{ id1 = 0; id2 = 0; rest = 0; } :
  (id1=IDENT|id1=CODE) (EQUALS (id2=IDENT|id2=CODE))? (COMMA rest=name_path_group)?
    {
      $ast = mk_cons(id2 ? Absyn__GROUP_5fIMPORT_5fRENAME(token_to_scon(id1),token_to_scon(id2)) :
                           Absyn__GROUP_5fIMPORT_5fNAME(token_to_scon(id1)),
                     or_nil(rest));
    }
  ;

component_reference_end returns [void* ast] :
  cr=component_reference EOF
  {
    $ast = cr.ast;
  }
  ;

component_reference returns [void* ast, int isNone]
@init{ cr.ast = 0; dot = 0; cr.isNone = 0; } :
  (dot=DOT)? cr=component_reference2
    {
      $ast = dot ? Absyn__CREF_5fFULLYQUALIFIED(cr.ast) : cr.ast;
      $isNone = cr.isNone;
    }
  | ALLWILD {$ast = Absyn__ALLWILD; $isNone = false;}
  | WILD {$ast = Absyn__WILD; $isNone = false;}
  ;

component_reference2 returns [void* ast, int isNone]
@init { id = 0; cr.ast = 0; arr = 0; } :
    (id=IDENT | id=OPERATOR) ( arr=array_subscripts )? ( DOT cr=component_reference2 )?
    {
      if (cr.ast) {
        $ast = Absyn__CREF_5fQUAL(token_to_scon(id), or_nil(arr), cr.ast);
        $isNone = false;
      }
      else {
        $isNone = metamodelica_enabled() && strcmp("NONE",(char*)$id.text->chars) == 0;
        $ast = Absyn__CREF_5fIDENT(token_to_scon(id), or_nil(arr));
      }
    }
  ;

function_call returns [void* ast]
@init { fa = 0; } :
  LPAR fa=function_arguments RPAR { ast = fa; }
  ;

function_arguments returns [void* ast]
@init{ for_or_el.ast = 0; for_or_el.isFor = 0; namel = 0; } :
  for_or_el=for_or_expression_list (namel=named_arguments)?
    {
      if (for_or_el.isFor)
        ast = for_or_el.ast;
      else
        ast = Absyn__FUNCTIONARGS(for_or_el.ast, or_nil(namel));
    }
  ;

for_or_expression_list returns [void* ast, int isFor]
@init{ e = 0; el = 0; forind = 0; } :
  ( {LA(1)==IDENT || LA(1)==OPERATOR && LA(2) == EQUALS || LA(1) == RPAR || LA(1) == RBRACE}? { $ast = mk_nil(); $isFor = 0; }
  | ( (e=expression | e=part_eval_function_expression)
      ( (COMMA el=for_or_expression_list2)
      | (threaded=THREADED? FOR forind=for_indices)
      )?
    )
    {
      if (el != NULL) {
        $ast = mk_cons(e,el);
      } else if (forind != NULL) {
        $ast = Absyn__FOR_5fITER_5fFARG(e, threaded ? Absyn__THREAD : Absyn__COMBINE, forind);
      } else {
        $ast = mk_cons(e, mk_nil());
      }
      $isFor = forind != 0;
    }
  )
  ;

for_or_expression_list2 returns [void* ast]
@init{ e = 0; el = 0; } :
    {LA(2) == EQUALS}? { ast = mk_nil(); }
  | (e=expression | e=part_eval_function_expression) (COMMA el=for_or_expression_list2)? { ast = mk_cons(e, or_nil(el)); }
  ;

named_arguments returns [void* ast]
@init{ a = 0; as = 0; } :
  a=named_argument (COMMA as=named_arguments)? { ast = mk_cons(a, or_nil(as)); }
  ;

named_argument returns [void* ast]
@init{ id = 0; e = 0; } :
  ( id=IDENT | id=OPERATOR) EQUALS (e=expression | e=part_eval_function_expression) { ast = Absyn__NAMEDARG(token_to_scon(id),e); }
  ;

output_expression_list [int* isTuple] returns [void* ast]
@init{ el = 0; e1 = 0; } :
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
        if (RML_NILHDR != RML_GETHDR(el))
        {
          ast = mk_cons(e1, el);
        }
        else
        {
          ast = mk_cons(e1, mk_cons(Absyn__CREF(Absyn__WILD), el));
        }
      }
    | RPAR
      {
        ast = *isTuple ? mk_cons(e1, mk_nil()) : e1;
      }
    )
  )
  ;

expression_list returns [void* ast]
@init { e1 = 0; el = 0; } :
  e1=expression (COMMA el=expression_list)? { ast = (el == NULL ? mk_cons(e1,mk_nil()) : mk_cons(e1,el)); }
  ;

array_subscripts returns [void* ast]
@init{ sl = 0; } :
  LBRACK sl=subscript_list RBRACK { ast = sl; }
  ;

subscript_list returns [void* ast]
@init{ s1 = 0; s2 = 0; } :
  s1=subscript ( COMMA s2=subscript_list )? { ast = mk_cons(s1, or_nil(s2)); }
  ;

subscript returns [void* ast]
@init{ e = 0; } :
    e=expression { ast = Absyn__SUBSCRIPT(e); }
  | COLON { ast = Absyn__NOSUB; }
  ;

comment returns [void* ast]
@init{ cmt = 0; ann = 0; ast = 0; } :
  (cmt=string_comment (ann=annotation)?)
    {
       if (cmt || ann) {
         ast = Absyn__COMMENT(mk_some_or_none(ann), mk_some_or_none(cmt));
       }
    }
  ;

string_comment returns [void* ast]
@declarations { pANTLR3_STRING t1; }
@init { s1 = 0; s2 = 0; ast = 0; } :
  ( s1=STRING { t1 = s1->getText(s1); } (PLUS s2=STRING {t1->appendS(t1,s2->getText(s2));})*
    { ast = mk_scon((char*)t1->chars); }
  )?
  ;

annotation returns [void* ast]
@init{ cmod = 0; } :
  T_ANNOTATION cmod=class_modification { ast = Absyn__ANNOTATION(cmod); }
  ;


/* Code quotation mechanism */

code_expression returns [void* ast]
@init{ initial = 0; eq = 0; constr = 0; alg = 0; e = 0; m = 0; el.ast = 0; name = 0; cr.ast = 0; } :
  ( CODE LPAR
    ( (initial=INITIAL)?
      ( (EQUATION eq=code_equation_clause)
       |(CONSTRAINT constr=code_constraint_clause)
       |(T_ALGORITHM alg=code_algorithm_clause))
    | (LPAR expression RPAR) => e=expression   /* Allow Code((<expr>)) */
    | m=modification
    | (expression RPAR) => e=expression
    | el=element (SEMICOLON)?
    )  RPAR
      {
        if (e) {
          ast = Absyn__CODE(Absyn__C_5fEXPRESSION(e));
        } else if (m) {
          ast = Absyn__CODE(Absyn__C_5fMODIFICATION(m));
        } else if (eq) {
          ast = Absyn__CODE(Absyn__C_5fEQUATIONSECTION(mk_bcon(initial), eq));
        } else if (constr) {
          ast = Absyn__CODE(Absyn__C_5fCONSTRAINTSECTION(mk_bcon(initial), constr));
        } else if (alg) {
          ast = Absyn__CODE(Absyn__C_5fALGORITHMSECTION(mk_bcon(initial), alg));
        } else {
          ast = Absyn__CODE(Absyn__C_5fELEMENT($el.ast));
        }
      }
  | CODE_NAME LPAR name=name_path RPAR {ast = Absyn__CODE(Absyn__C_5fTYPENAME(name));}
  | CODE_VAR LPAR cr=component_reference RPAR {ast = Absyn__CODE(Absyn__C_5fVARIABLENAME(cr.ast));}
  )
  ;

code_equation_clause returns [void* ast]
@init{ e.ast = 0; as = 0; } :
  ( e=equation SEMICOLON as=code_equation_clause?
    {
      ast = mk_cons(e.ast,or_nil(as));
    }
  )
  ;

code_constraint_clause returns [void* ast]
@init{ e.ast = 0; as = 0; } :
  e=equation SEMICOLON as=code_constraint_clause?
    {
      ast = mk_cons(e.ast,or_nil(as));
    }
  ;

code_algorithm_clause returns [void* ast]
@init{ al.ast = 0; as = 0; } :
  al=algorithm SEMICOLON as=code_algorithm_clause?
    {
      ast = mk_cons(al.ast,or_nil(as));
    }
  ;

/* End Code quotation mechanism */


top_algorithm returns [void* ast, int isExp]
@init{ e = 0; a = 0; cmt = 0; } :
  ( (expression (SEMICOLON|EOF))=> e=expression
  | ( a=top_assign_clause_a
    | a=conditional_equation_a
    | a=for_clause_a
    | a=parfor_clause_a
    | a=while_clause
    )
    cmt=comment
  )
    {
      if (!e) {
        $ast = Absyn__ALGORITHMITEM(a, mk_some_or_none(cmt), PARSER_INFO($start));
        $isExp = 0;
      } else {
        $ast = e;
        $isExp = 1;
      }
    }
  ;

top_assign_clause_a returns [void* ast]
@init{ e1 = 0; e2 = 0; } :
  e1=simple_expression ASSIGN e2=expression
    {
      ast = Absyn__ALG_5fASSIGN(e1,e2);
    }
  ;

interactive_stmt returns [void* ast]
@declarations { int last_sc = 0; }
@init{ ss = 0; } :
  // A list of expressions or algorithms separated by semicolons and optionally ending with a semicolon
  BOM? ss=interactive_stmt_list[&last_sc] EOF
    {
      ast = GlobalScript__ISTMTS(or_nil(ss), mk_bcon(last_sc));
    }
  ;

interactive_stmt_list [int *last_sc] returns [void* ast]
@init { a.ast = 0; a.isExp = 0; ss = 0; $ast = 0; } :
  a=top_algorithm ( (SEMICOLON ss=interactive_stmt_list[last_sc]) | (SEMICOLON { *last_sc = 1; }) | /* empty */ )
    {
      if (!a.isExp)
        ast = mk_cons(GlobalScript__IALG(a.ast), or_nil(ss));
      else
        ast = mk_cons(GlobalScript__IEXP(a.ast), or_nil(ss));
    }
  ;

/* MetaModelica */
match_expression returns [void* ast]
@init{ ty = 0; exp = 0; cmt = 0; es = 0; cs = 0; } :
  ( (ty=MATCHCONTINUE exp=expression cmt=string_comment
     es=local_clause
     cs=cases
     END_MATCHCONTINUE)
  | (ty=MATCH exp=expression cmt=string_comment
     es=local_clause
     cs=cases
     END_MATCH)
  )
     {
       ast = Absyn__MATCHEXP(ty->type==MATCHCONTINUE ? Absyn__MATCHCONTINUE : Absyn__MATCH, exp, or_nil(es), cs, mk_some_or_none(cmt));
     }
  ;

local_clause returns [void* ast]
@init{ el = 0; } :
  (LOCAL el=element_list[0])?
    {
      ast = el;
    }
  ;

cases returns [void* ast]
@init{ c.ast = 0; cs.ast = 0; } :
  c=onecase cs=cases2
    {
      $ast = mk_cons(c.ast,cs.ast);
    }
  ;

cases2 returns [void* ast]
@init{ el = 0; cmt = 0; es = 0; eqs = 0; th = 0; exp = 0; c.ast = 0; cs.ast = 0; } :
  ( (el=ELSE (cmt=string_comment es=local_clause (EQUATION eqs=equation_list_then)? th=THEN)? exp=expression SEMICOLON)?
    {
      if (es != NULL)
        c_add_source_message(NULL,2, ErrorType_syntax, ErrorLevel_warning, "case local declarations are deprecated. Move all case- and else-declarations to the match local declarations.",
                             NULL, 0, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition+1,
                             ModelicaParser_readonly, ModelicaParser_filename_C_testsuiteFriendly);
      if ($th) $el = $th;
      if (exp)
       $ast = mk_cons(Absyn__ELSE(or_nil(es),or_nil(eqs),exp,PARSER_INFO($el),mk_some_or_none(cmt),PARSER_INFO($start)),mk_nil());
      else
       $ast = mk_nil();
    }
  | c=onecase cs=cases2
    {
      $ast = mk_cons(c.ast, cs.ast);
    }
  )
  ;

onecase returns [void* ast]
@init{ pat.ast = 0; guard = 0; cmt = 0; es = 0; eqs = 0; th = 0; exp = 0; } :
  (CASE pat=pattern (GUARD guard=expression)? cmt=string_comment es=local_clause (EQUATION eqs=equation_list_then)? th=THEN exp=expression SEMICOLON)
    {
        if (es != NULL)
          c_add_source_message(NULL,2, ErrorType_syntax, ErrorLevel_warning, "case local declarations are deprecated. Move all case- and else-declarations to the match local declarations.",
                               NULL, 0, $start->line, $start->charPosition+1, LT(1)->line, LT(1)->charPosition+1,
                               ModelicaParser_readonly, ModelicaParser_filename_C_testsuiteFriendly);
        $ast = Absyn__CASE(pat.ast,mk_some_or_none(guard),pat.info,or_nil(es),or_nil(eqs),exp,PARSER_INFO($th),mk_some_or_none(cmt),PARSER_INFO($start));
    }
  ;

pattern returns [void* ast, void* info] :
  e=expression {$ast = e; $info = PARSER_INFO($start);}
  ;
