
header "post_include_hpp" {
#define null 0
    
    
    extern "C" {
#include <stdio.h>
#include "yacclib.h"
    }
    
#include <cstdlib>
#include <iostream>
    
#include "rml.h"
#include "../absyn.h"
#include "../interactive.h"
#include <stack>
#include <string>
    
}

options {
    language = "Cpp";
}



class modelica_tree_parser extends TreeParser;

options {
    importVocab = modelica_parser;
    k = 2;
    buildAST = true;
    defaultErrorHandler = false;
}

tokens {
    INTERACTIVE_STMT;
}
{
    
    typedef std::string mstring;
    
    void* to_rml_str(antlr::RefAST &t)
    {
        return mk_scon(const_cast<char*>(t->getText().c_str()));
    }
    
    int str_to_int(mstring const& str)
    {
        return atoi(str.c_str());
    }
    
    double str_to_double(std::string const& str)
    {
        return atof(str.c_str());
    }
    
    typedef std::stack<void*> l_stack;
    
    void* make_rml_list_from_stack(l_stack& s)
    {
        void *l = mk_nil();
        
        while (!s.empty())
        {
            l = mk_cons(s.top(), l);
            s.pop();
        }   
        return l;
    }
    

    struct type_prefix_t
    {
        type_prefix_t():flow(0), variability(0),direction(0){}
        void* flow;
        void* variability;
        void* direction;
    };
    

}

stored_definition returns [void *ast]
{
    void *within = 0;
    void *class_def = 0;
    l_stack el_stack;
}
    :
        #(STORED_DEFINITION      
            ( within = within_clause )?
            ((f:FINAL )? 
                class_def = class_definition[f != NULL] 
                {
                    if (class_def)
                    {   
                        el_stack.push(class_def);
                    }
                }
            )*
        )
        {
            if (within == 0) { within=Absyn__TOP; }
            ast = Absyn__PROGRAM(make_rml_list_from_stack(el_stack),within);
        }
    ;

interactive_stmt returns [void *ast]
{
    void *a1=0;
    void *e1=0;
}
    :
        #(INTERACTIVE_STMT
            (a1 = algorithm | e1 = expression ))
        {
            if (a1 != 0 ) 
            ast = Interactive__ISTMTS(mk_cons(Interactive__IALG(a1),mk_nil()));
            else
            ast = Interactive__ISTMTS(mk_cons(Interactive__IEXP(e1),mk_nil()));
            assert(ast != 0);
        }
    ;

within_clause returns [void *ast]
{
    void * name= 0;
}
    : #(WITHIN (name = name_path)? )	
        {
            ast = Absyn__WITHIN(name);
        }
    ;

class_definition [bool final] returns [ void* ast ]
{
    void* restr = 0;
    void* class_spec = 0;
    }
    :
        #(CLASS_DEFINITION 
            (e:ENCAPSULATED )? 
            (p:PARTIAL )?
            restr = class_restriction
            i:IDENT 	
            class_spec = class_specifier
        )
        {   
            ast = Absyn__CLASS(
                to_rml_str(i),
                RML_PRIM_MKBOOL(p != 0),
                RML_PRIM_MKBOOL(e != 0), 
                restr,
                class_spec
            );                
        }
    ;

class_restriction returns [void* ast]
    :
        ( CLASS     { ast = Absyn__R_5fCLASS; }
        | MODEL     { ast = Absyn__R_5fMODEL; }
        | RECORD    { ast = Absyn__R_5fRECORD; }
        | BLOCK     { ast = Absyn__R_5fBLOCK; }
        | CONNECTOR { ast = Absyn__R_5fCONNECTOR; }
        | TYPE      { ast = Absyn__R_5fTYPE; }
        | PACKAGE   { ast = Absyn__R_5fPACKAGE; }
        | FUNCTION  { ast = Absyn__R_5fFUNCTION; }
        )
    ;

class_specifier returns [void* ast]
{
  void *comp = 0;
}
  :
    ( string_comment 
      comp = composition		
      {
        ast = Absyn__PARTS(comp);
      }
    )
  | EQUALS ( ast = derived_class | ast = enumeration) 

  ;

derived_class returns [void *ast]
{
  void *p = 0;
  void *as = 0;
  void *cmod = 0;
}
  :
    (
      p = name_path 
      ( as = array_subscripts )? 
      ( cmod = class_modification )? 
      comment
      {
        if (as) { as = mk_some(as); }
        else { as = mk_none(); }
        if (!cmod) { cmod = mk_nil(); }
        
        ast = Absyn__DERIVED(p, as, cmod);
      }
    )
  ;

enumeration returns [void* ast]
{
  l_stack el_stack;
}
    : 
    #(ENUMERATION 
      i1:IDENT { el_stack.push(to_rml_str(i1)); } (i2:IDENT { el_stack.push(to_rml_str(i2)); } )*
    )
    {
      ast = Absyn__ENUMERATION(make_rml_list_from_stack(el_stack));
    }
  ;

composition returns [void* ast]
{
    void* el = 0;
    l_stack el_stack;
    void * ann;	
}
    :
        el = element_list
        {
            el_stack.push(Absyn__PUBLIC(el));
        }
        (
            (	
                el = public_element_list
            |	el = protected_element_list
            |	el = equation_clause
            |	el = algorithm_clause
            )
            {
                el_stack.push(el);
            }
        )*
        ( EXTERNAL
            ( el = external_function_call)
            ( ann = annotation)?
        { 
                el_stack.push(el);
                
        }
        )?
        {
            ast = make_rml_list_from_stack(el_stack);
        }
    ;

public_element_list returns [void* ast]
{
    void* el;    
}
    :
        
        #(p:PUBLIC 
            el = element_list
        )
        {
            ast = Absyn__PUBLIC(el);
        }
    ;

protected_element_list returns [void* ast]
{
    void* el;
}
    :
        
        #(p:PROTECTED
            el = element_list
        )
        {
            ast = Absyn__PROTECTED(el);
        }
    ;

external_function_call returns [void* ast]
        {
            void* temp=0;
            void* temp2=0;
            void* temp3=0;
            void *lang;
            ast = 0;
        }
        :
        (s:STRING)?
        (#(EXTERNAL_FUNCTION_CALL 
            (
                (i:IDENT (temp = expression_list)?)
                {
                    if (s != NULL) { lang = mk_some(to_rml_str(s)); } 
                    else { lang = mk_none(); }
                    if (!temp) { temp = mk_nil(); }
                    ast = Absyn__EXTERNAL(Absyn__EXTERNALDECL(mk_some(to_rml_str(i)),lang,mk_none(),temp));
                }
            | #(e:EQUALS temp2 = component_reference i2:IDENT ( temp3 = expression_list)?)
                {
                    if (s != NULL) { lang = mk_some(to_rml_str(s)); } 
                    else { lang = mk_none(); }
                    if (!temp2) { temp2 = mk_nil(); }
                    ast = Absyn__EXTERNAL(Absyn__EXTERNALDECL(mk_some(to_rml_str(i2)),lang,mk_some(temp2),temp3));
                }
            )
        ))?                            
            {
                if (!ast) { 
                    if (s != NULL) { lang = mk_some(to_rml_str(s)); } 
                    else { lang = mk_none(); }
                    ast = Absyn__EXTERNAL(Absyn__EXTERNALDECL(mk_none(),lang,mk_none(),mk_nil()));
                }
        }

    ;

element_list returns [void* ast]
{
    void* e = 0;
    l_stack el_stack;
    void *ann = 0;
}
    :
        (
            (e = element
                {
                    el_stack.push(Absyn__ELEMENTITEM(e));
                })
        | (ann = annotation 
                {
                    el_stack.push(Absyn__ANNOTATIONITEM(ann));
                }
            )              
        )*
        {
            ast = make_rml_list_from_stack(el_stack);
        }
    ;


// returns datatype Element
element returns [void* ast]
 {
     void* class_def = 0;
     void* e_spec = 0;
     void* final = 0;
     void* innerouter = 0;
 }
     : 
         ( e_spec = import_clause
             {
                 ast = Absyn__ELEMENT(RML_FALSE,Absyn__UNSPECIFIED,mk_scon("import"),e_spec);
             }
         | e_spec = extends_clause
             {
                 ast = Absyn__ELEMENT(RML_FALSE,Absyn__UNSPECIFIED,mk_scon("extends"),e_spec);
             }
         | #(DECLARATION 
                 (   // TODO: fix Absyn to handle inner, outer
                     (f:FINAL)? { final = f!=NULL?RML_TRUE:RML_FALSE; }
                     (i:INNER | o:OUTER)? { 
                        if (i!=NULL) {
                         innerouter = Absyn__INNER; 
                        } else if (o != NULL) {
                         innerouter = Absyn__OUTER;
                        } else {
                         innerouter = Absyn__UNSPECIFIED;
                        }
                      }
                     (e_spec = component_clause
                         {
                             ast = Absyn__ELEMENT(final,innerouter,
                                 mk_scon("component"),e_spec);
                         }
                     | r:REPLACEABLE 
                         // TODO: fix Absyn to handle replaceable and 
                         // constr_clause
                         e_spec = component_clause 
                         (constraining_clause)?
                         {
                             ast = Absyn__ELEMENT(final,Absyn__UNSPECIFIED,
                                 mk_scon("replaceable_component"),e_spec);
                         }
                     )

                 )
             )
         | #(DEFINITION
                 (   // TODO: fix Absyn to handle final, inner, outer
                     (fd:FINAL)? { final = fd!=NULL?RML_TRUE:RML_FALSE; }
                     (id:INNER | od:OUTER)?
                     (
                         class_def = class_definition[fd != NULL]
                         {
                             ast = Absyn__CLASSDEF(RML_PRIM_MKBOOL(1),
                                 class_def);
                             ast = Absyn__ELEMENT(final,Absyn__UNSPECIFIED,mk_scon("??"),ast);

                         }
                     | 
                         (rd:REPLACEABLE 
                             class_def = class_definition[fd != NULL] 
                             // TODO: fix Absyn to handle constr_clause
                             (constraining_clause)?
                         )
                         {
                             ast = Absyn__CLASSDEF(RML_PRIM_MKBOOL(1),
                                 class_def);
                             ast = Absyn__ELEMENT(final,Absyn__UNSPECIFIED,mk_scon("??"),ast);
                         }
                     )
                 )
             )
         )
     ;

 // returns ElementSpec
 import_clause returns [void* ast]
 {
     void* imp = 0;
 }
     :
         #(i:IMPORT 
             (imp = explicit_import_name
             |imp = implicit_import_name
             ) 
             comment
         )
         {
             ast = Absyn__IMPORT(imp);
         }
         ;

 // returns Import
 explicit_import_name returns [void* ast]
 {
     void* path;
     void* id;
 }
     :
         #(EQUALS i:IDENT path = name_path)	
         {
             id = to_rml_str(i);
             ast = Absyn__NAMED_5fIMPORT(id,path);
         }
     ;

 implicit_import_name returns [void* ast]
 {
     void* path;
 }
     :
         (#(UNQUALIFIED path = name_path)
             {
                 ast = Absyn__UNQUAL_5fIMPORT(path);
             }
         |#(QUALIFIED path = name_path)
             {
                 ast = Absyn__QUAL_5fIMPORT(path);
             }
         )
     ;


 // Note that this is a minor modification of the standard by 
 // allowing the comment.
 // ****************************
 // returns datatype ElementSpec
 // ****************************
 extends_clause returns [void* ast]
 {
     void* path;
     void* mod = 0;
 }
     : 
         (#(e:EXTENDS 
                 path = name_path 
                 ( mod = class_modification )? 
                 comment
             )
             {
                 if (!mod) mod = mk_nil();
                 ast = Absyn__EXTENDS(path,mod);
             }
         )
     ;

 constraining_clause :
 {
    void* temp;
 }
         (temp = extends_clause);

 // returns datatype ElementSpec
 component_clause returns [void* ast]
 {
     type_prefix_t pfx;
     void* attr = 0;
     void* path = 0;
     void* arr = 0;
     void* comp_list = 0;
 }
     :
         type_prefix[pfx] 
         path = type_specifier 
         (arr = array_subscripts)? 
         comp_list = component_list
         {
             if (!arr)
             {
                 arr = mk_nil();
             }

             attr = Absyn__ATTR(
                 pfx.flow,
                 pfx.variability,
                 pfx.direction,
                 arr);

             ast = Absyn__COMPONENTS(attr, path, comp_list);
         }
     ;

 type_prefix [type_prefix_t& prefix]
     :
         (f:FLOW)?
         (d:DISCRETE 
         |p:PARAMETER
         |c:CONSTANT
         )?
         (i:INPUT 
         |o:OUTPUT 
         )?
         {
             if (f != NULL) { prefix.flow = RML_PRIM_MKBOOL(1); }
             else { prefix.flow = RML_PRIM_MKBOOL(0); }

             if (d != NULL) { prefix.variability = Absyn__DISCRETE; }
             else if (p != NULL) { prefix.variability = Absyn__PARAM; }
             else if (c != NULL) { prefix.variability = Absyn__CONST; }
             else { prefix.variability = Absyn__VAR; }

             if (i != NULL) { prefix.direction = Absyn__INPUT; }
             else if (o != NULL) { prefix.direction = Absyn__OUTPUT; }
             else { prefix.direction = Absyn__BIDIR; }
         }
         ;

 // returns datatype Path
 type_specifier returns [void* ast]
     :
         ast = name_path;


 // returns datatype Component list
 component_list returns [void* ast]
 {
     l_stack el_stack;
     void* e=0;
 }
     :
         e = component_declaration { el_stack.push(e); }
         (e = component_declaration { el_stack.push(e); } )*
         {
             ast = make_rml_list_from_stack(el_stack);
         }
     ;


 // returns datatype Component
 component_declaration returns [void* ast]
 {
     void* ann = 0;
     void* dec = 0;

 }
     :
         (dec = declaration) (ann = comment)
         {
             if (!ann) ann = mk_none();
             else ann = mk_some(ann);
             ast = Absyn__COMPONENTITEM(dec,ann);
         }
         ;


 // returns datatype Component
 declaration returns [void* ast]
 {
     void* arr = 0;
     void* mod = 0;
     void* id = 0;
 }
     :
         #(i:IDENT (arr = array_subscripts)? (mod = modification)?)
         {
             if (!arr) arr = mk_nil();
             if (!mod) mod = mk_none();
             else mod = mk_some(mod);
             id = to_rml_str(i);

             ast = Absyn__COMPONENT(id, arr, mod);

         }
     ;


 modification returns [void* ast] 
 {
     void* e = 0;
     void* cm = 0;
 }
     :
         ( cm = class_modification ( e = expression )?
         |#(EQUALS e = expression)
         |#(ASSIGN e = expression)
         )
         {
             if (!e) e = mk_none();
             else e = mk_some(e);

             if (!cm) cm = mk_nil();

             ast = Absyn__CLASSMOD(cm, e);
         }
     ;

 class_modification returns [void* ast]
 {
     ast = 0;
 }
     :
         #(CLASS_MODIFICATION (ast = argument_list)?)
         {
             if (!ast) ast = mk_nil();
         }
     ;

 argument_list returns [void* ast]
 {
     l_stack el_stack;
     void* e;
 }
     :
         #(ARGUMENT_LIST 
             e = argument { el_stack.push(e); }
             (e = argument { el_stack.push(e); } )*
         )
         {
             ast = make_rml_list_from_stack(el_stack);
         }
     ;

 argument returns [void* ast]
     :
         #(ELEMENT_MODIFICATION ast = element_modification)
         |
         #(ELEMENT_REDECLARATION ast = element_redeclaration) 
         ;

 element_modification returns [void* ast]
 {
     void* cref;
     void* mod;
     void* final;
 }
     :
         (f:FINAL)? 
         cref = component_reference 
         mod = modification 
         string_comment
         {
             final = f != NULL ? RML_TRUE : RML_FALSE;
             ast = Absyn__MODIFICATION(final, cref, mod);
         }
         ;

 element_redeclaration returns [void* ast]
 {
     void* class_def = 0;
     void* e_spec;
 }
         :
         (#(r:REDECLARE 
                (	
                     (class_def = class_definition[false] 
                         {
                             e_spec = Absyn__CLASSDEF(RML_FALSE,class_def);
                             ast = Absyn__REDECLARATION(RML_FALSE,e_spec);
                         }
                     | e_spec = component_clause1
                         {
                             ast = Absyn__REDECLARATION(RML_FALSE, e_spec);
                         }
                     )
                 |
                     ( re:REPLACEABLE 
                         (class_def = class_definition[false]
                             {
                                 e_spec = Absyn__CLASSDEF(RML_TRUE, class_def);
                                 ast = Absyn__REDECLARATION(RML_TRUE, e_spec);
                             }
                         | e_spec = component_clause1
                             {
                                 ast = Absyn__REDECLARATION(RML_TRUE, e_spec);
                             }
                         )
                         // TODO: fix Absyn to handle constr_clause
                         (constraining_clause)?
                     )
                 )
             )
         )
         ;

 component_clause1 returns [void* ast]
 {
     type_prefix_t pfx;
     void* attr = 0;
     void* path = 0;
     void* arr = 0;
     void* comp_decl = 0;
     void* comp_list = 0;
 }
     :
         type_prefix[pfx]
         path = type_specifier 
         comp_decl = component_declaration
         {
             if (!arr)
             {
                 arr = mk_nil();
             }
             comp_list = mk_cons(comp_decl,mk_nil());
             attr = Absyn__ATTR(
                 pfx.flow,
                 pfx.variability,
                 pfx.direction,
                 arr);

             ast = Absyn__COMPONENTS(attr, path, comp_list);
         }
     ;

 equation_clause returns [void* ast]
 {
     l_stack el_stack;
     void *e=0; 
 }
     :
         #(EQUATION
             (
         (e = equation | annotation) 
         { 
             el_stack.push(e); 

         }
             )*
         )
         {
             ast = Absyn__EQUATIONS(make_rml_list_from_stack(el_stack));
         }

         ;

 algorithm_clause returns [void* ast]
 {
     l_stack el_stack;
     void* e;
     void* ann;
 }
     :
         #(ALGORITHM 
             (e = algorithm { el_stack.push(e); }
             | ann = annotation 
             )*
         )
         {
             ast = Absyn__ALGORITHMS(make_rml_list_from_stack(el_stack));
         }
         ;

 equation returns [void* ast] 
 {
 void *ann=0;

 }
     :
         #(EQUATION_STATEMENT
             (	ast = equality_equation
             |	ast = conditional_equation_e
             |	ast = for_clause_e
             |	ast = when_clause_e
             |	ast = connect_clause
             |	ast = assert_clause
             )
             ann = comment
     {
       if (!ann) ann=mk_none();
       else ann=mk_some(ann); 
       ast = Absyn__EQUATIONITEM(ast,ann);
     }
         )
         ;

 algorithm returns [void* ast]
 {
     void* cref;
     void* expr;
     void* temp;
     void* temp2;
     void* temp3;
 }
     :
         #(ALGORITHM_STATEMENT 
             (#(ASSIGN 
                     (cref = component_reference expr = expression
                         {
                             ast = Absyn__ALG_5fASSIGN(cref,expr);
                         }
                     |	(temp=expression_list temp2=component_reference temp3= function_call)
                         {
                             // TODO: fix Absyn to handle tuple assign
                             ast = 0;
                         }
                     )

                 )
             | ast = algorithm_function_call
             | ast = conditional_equation_a
             | ast = for_clause_a
             | ast = while_clause
             | ast = when_clause_a
             | ast = assert_clause
             )
             comment
         )
         ;
 algorithm_function_call returns [void* ast]
 {
   void* temp;
   void* temp2;
 }
     :
         temp = component_reference temp2 = function_call
         {
             // TODO: fix Absyn to handle function calls w/o assign
             ast = 0;
         }
     ;

 equality_equation returns [void* ast]
 {
     void* e1;
     void* e2;
 }
     :
         #(EQUALS e1 = simple_expression e2 = expression)
         {
             ast = Absyn__EQ_5fEQUALS(e1,e2);
         }
     ;

 conditional_equation_e returns [void* ast]
 {
     void* e1;
     void* then_b;
     void* else_b = 0;
     void* else_if_b;
     l_stack el_stack;
     void* e;
 }
     :
         #(IF
             e1 = expression
             then_b = equation_list
             ( e = equation_elseif { el_stack.push(e); } )*
             (ELSE else_b = equation_list)?
         )
         {
             else_if_b = make_rml_list_from_stack(el_stack);
             if (!else_b) else_b = mk_nil();
             ast = Absyn__EQ_5fIF(e1, then_b, else_if_b, else_b);
         }
         ;

 conditional_equation_a returns [void* ast]
 {
     void* e1;
     void* then_b;
     void* else_b = 0;
     void* else_if_b;
     l_stack el_stack;
     void* e;
 }
 :
         #(IF
             e1 = expression
             then_b = algorithm_list
         ( e = algorithm_elseif { el_stack.push(e); } )*
         ( ELSE else_b = algorithm_list)?
         )
         {
             else_if_b = make_rml_list_from_stack(el_stack);
             if (!else_b) else_b = mk_nil();
             ast = Absyn__ALG_5fIF(e1, then_b, else_if_b, else_b);
         }
         ;

 for_clause_e returns [void* ast] 
 {
     void* e;
     void* eq;
     void* id;
 }
     :
         #(FOR i:IDENT
             e = expression
             eq = equation_list
         )
         {
             id = to_rml_str(i);
             ast = Absyn__EQ_5fFOR(id,e,eq);
         }
         ;

 for_clause_a returns [void* ast]
 {
     void* e;
     void* eq;
     void* id;
 }
     :
         #(FOR i:IDENT
             e = expression
             eq = algorithm_list
         )
         {
             id = to_rml_str(i);
             ast = Absyn__ALG_5fFOR(id,e,eq);
         }
         ;

 while_clause returns [void* ast]
 {
     void* e;
     void* body;
 }
     :
         #(WHILE 
             e = expression 
             body = algorithm_list)
         {
             ast = Absyn__ALG_5fWHILE(e,body);
         }
     ;

 when_clause_e returns [void* ast]
 {
     void* e;
     void* body;
 }
  :
         #(WHEN 
             e = expression
             body = equation_list
         )
         {
             ast = Absyn__EQ_5fWHEN_5fE(e,body);
         }

         ;

 when_clause_a returns [void* ast]
 {
     void* e;
     void* body;
 }
     :
         #(WHEN 
             e = expression
             body = algorithm_list 
             (else_when_a)* // TODO: fix Absyn to handle elsewhen
         )
         {
             ast = Absyn__ALG_5fWHEN_5fA(e,body);
         }

         ;

 else_when_a
 { 
   void * temp;
   void * temp2;
 }
     :
         #(e:ELSEWHEN temp = expression  temp2 = algorithm_list)
         ;

 equation_elseif returns [void* ast]
 {
     void* e;
     void* eq;
 }
     :
         #(ELSEIF 
             e = expression 
             eq = equation_list
         )
         {
             ast = mk_box2(0,e,eq);
         }
     ;

 algorithm_elseif returns [void* ast]
 {
     void* e;
     void* body;
 }
     :
         #(ELSEIF 
             e = expression
             body = algorithm_list
         )
         {
             ast = mk_box2(0,e,body);
         }
     ;

 equation_list returns [void* ast]
 {
     void* e;
     l_stack el_stack;
 }
     :
         (e = equation { el_stack.push(e); })*
         {
             ast = make_rml_list_from_stack(el_stack);
         }
     ;

 algorithm_list returns [void* ast]
 {
     void* e;
     l_stack el_stack;
 }
     :
         (e = algorithm { el_stack.push(e); } )*
         {
             ast = make_rml_list_from_stack(el_stack);
         }
     ;

 connect_clause returns [void* ast]
 {
     void* r1;
     void* r2;
 }
     :
         #(CONNECT 
             r1 = connector_ref
             r2 = connector_ref
         )
         {
             ast = Absyn__EQ_5fCONNECT(r1,r2);
         }
         ;

 connector_ref returns [void* ast]
 {
     void* as = 0;
     void* id = 0;
 }
     :
         (#(i:IDENT (as = array_subscripts)? )
             {
                 if (!as) as = mk_nil();
                 id = to_rml_str(i);
                 ast = Absyn__CREF_5fIDENT(id,as);
             }
         |#(DOT #(i2:IDENT (as = array_subscripts)?) 
                 ast = connector_ref_2)
             {
                 if (!as) as = mk_nil();
                 id = to_rml_str(i2);
                 ast = Absyn__CREF_5fQUAL(id,as,ast);
             }
         )
         ;

 connector_ref_2 returns [void* ast]
 {
     void* as = 0;
     void* id;
 }
     :
         #(i:IDENT (as = array_subscripts)? )
         {
             if (!as) as = mk_nil();
             id = to_rml_str(i);
             ast = Absyn__CREF_5fIDENT(id,as);
         }
         ;

 assert_clause returns [void* ast]
 {
     void* e;
     l_stack el_stack;
 }
     :
         (#(ASSERT
             e = expression
             s:STRING { el_stack.push(to_rml_str(s)); }
             (PLUS 
                 s2:STRING { el_stack.push(to_rml_str(s2)); }
             )* 
         )
             {
                 ast = Absyn__ASSERT(e,make_rml_list_from_stack(el_stack));
             }
         |#(TERMINATE s3:STRING { el_stack.push(to_rml_str(s)); }
                 (PLUS
                     s4:STRING { el_stack.push(to_rml_str(s4)); }
                 )*
             )
         {
             // TODO: fix Absyn to handle assert
             ast = Absyn__TERMINATE(make_rml_list_from_stack(el_stack));
         }
         )
         ;

 expression returns [void* ast]
     :
         (	ast = simple_expression
         |	ast = if_expression
         )
         ;

 if_expression returns [void* ast]
 {
     void* e1;
     void* e2;
     void* e3;
 }
     :
         #(IF e1 = expression
             e2 = expression e3 = expression
         )
         {
             ast = Absyn__IFEXP(e1,e2,e3);
         }
     ;

 simple_expression returns [void* ast]
 {
     void* e1;
     void* e2;
     void* e3;
 }
     :
         (#(RANGE3 e1 = logical_expression 
             e2 = logical_expression 
             e3 = logical_expression)
             {
                 ast = Absyn__RANGE(e1,mk_some(e2),e3);
             }
         |#(RANGE2 e1 = logical_expression e3 = logical_expression)
             {
                 ast = Absyn__RANGE(e1,mk_none(),e3);
             }
         | ast = logical_expression
         )
     ;

 logical_expression returns [void* ast]
 {
     void* e1;
     void* e2;
 }
     : 
         (ast = logical_term
         | #(OR e1 = logical_expression e2 = logical_term)
             {
                 ast = Absyn__LBINARY(e1,Absyn__OR, e2);
             }
         )

     ;

 logical_term returns [void* ast]
 {
     void* e1;
     void* e2;
 }
     :
         (ast = logical_factor
         | #(AND e1 = logical_term e2 = logical_factor)
             {
                 ast = Absyn__LBINARY(e1,Absyn__AND,e2);
             }
         )
     ;

 logical_factor returns [void* ast]
     :
         #(NOT ast = relation { ast = Absyn__LUNARY(Absyn__NOT,ast); })
         | ast = relation;

 relation returns [void* ast]
 {
     void* e1;
     void* op = 0;
     void* e2 = 0;
 }
     : 
         ( ast = arithmetic_expression
         | 
             ( #(LESS e1=arithmetic_expression e2=arithmetic_expression)
                 { op = Absyn__LESS; }                    
             | #(LESSEQ e1=arithmetic_expression e2=arithmetic_expression)
                 { op = Absyn__LESSEQ; }                    
             | #(GREATER e1=arithmetic_expression e2=arithmetic_expression)
                 { op = Absyn__GREATER; }                    
             | #(GREATEREQ e1=arithmetic_expression e2=arithmetic_expression)
                 { op = Absyn__GREATEREQ; }                    
             | #(EQEQ e1=arithmetic_expression e2=arithmetic_expression)
                 { op = Absyn__EQUAL; }                    
             | #(LESSGT e1=arithmetic_expression e2=arithmetic_expression )
                 { op = Absyn__NEQUAL; }                    
             )
             {
                 ast = Absyn__RELATION(e1,op,e2);
             }
         )
     ;

 rel_op returns [void* ast]
     :
         ( LESS { ast = Absyn__LESS; }
         | LESSEQ { ast = Absyn__LESSEQ; }
         | GREATER { ast = Absyn__GREATER; }
         | GREATEREQ { ast = Absyn__GREATEREQ; }
         | EQEQ { ast = Absyn__EQUAL; }
         | LESSGT { ast = Absyn__NEQUAL; }
         )
         ;

 arithmetic_expression returns [void* ast]
 {
     void* e1;
     void* e2;
 }
     :
         (ast = unary_arithmetic_expression
         |#(PLUS e1 = arithmetic_expression e2 = term)
             {
                 ast = Absyn__BINARY(e1,Absyn__ADD,e2);
             }
         |#(MINUS e1 = arithmetic_expression e2 = term)
             {
                 ast = Absyn__BINARY(e1,Absyn__SUB,e2);
             }
         )
     ;

 unary_arithmetic_expression returns [void* ast]
     :
         (#(UNARY_PLUS ast = term) { ast = Absyn__UNARY(Absyn__UPLUS,ast); }
         |#(UNARY_MINUS ast = term) { ast = Absyn__UNARY(Absyn__UMINUS,ast); }
         | ast = term
         )
     ;

 term returns [void* ast]
 {
     void* e1;
     void* e2;
 }
     :
         (ast = factor
         |#(STAR e1 = term e2 = factor) 
             {
                 ast = Absyn__BINARY(e1,Absyn__MUL,e2); 
             }
         |#(SLASH e1 = term e2 = factor)
             {
                 ast = Absyn__BINARY(e1,Absyn__DIV,e2); 
             }
         )
     ;

 factor returns [void* ast]
 {
     void* e1;
     void* e2;
 }
     :
         (ast = primary
         |#(POWER e1 = primary e2 = primary)
             {
                 Absyn__BINARY(e1,Absyn__POW,e2);
             }
         )
         ;

 primary returns [void* ast]
 {
     l_stack el_stack;
     void* e;
 }
     :
         ( ui:UNSIGNED_INTEGER 
             { 
                 ast = Absyn__INTEGER(mk_icon(str_to_int(ui->getText()))); 
             }
         | ur:UNSIGNED_REAL
             { 
                 ast = Absyn__REAL(mk_rcon(str_to_double(ur->getText()))); 
             }
         | str:STRING
             {
                 ast = Absyn__STRING(to_rml_str(str));
             }
         | FALSE { ast = Absyn__BOOL(RML_FALSE); }
         | TRUE { ast = Absyn__BOOL(RML_TRUE); }
         | ast = component_reference__function_call
         | #(LPAR ast = tuple_expression_list)
         | #(LBRACK  e = expression_list { el_stack.push(e); }
                 (e = expression_list { el_stack.push(e); } )* )
             {
                 ast = Absyn__MATRIX(make_rml_list_from_stack(el_stack));
             }
         | #(LBRACE ast = expression_list) { ast = Absyn__ARRAY(ast); }
         )
     ;


 component_reference__function_call returns [void* ast]
 {
     void* cref;
     void* fnc = 0;
 }
     :
         (#(FUNCTION_CALL cref = component_reference (fnc = function_call)?)
             {
                 if (!fnc) fnc = mk_nil();
                 ast = Absyn__CALL(cref,fnc);
             }
         | cref = component_reference
             {
                 ast = Absyn__CREF(cref);
             }
         )
     ;

 name_path returns [void* ast]
 {
     void* str;

 }
     :
         i:IDENT 
         {
             str = to_rml_str(i);
             ast = Absyn__IDENT(str);
         }
         |#(d:DOT i2:IDENT ast = name_path )
         {
             str = to_rml_str(i2);
             ast = Absyn__QUALIFIED(str, ast);
         }
         ;

 component_reference	returns [void* ast]
 {
     void* arr = 0;
     void* id = 0;
 }
     :
         (#(i:IDENT (arr = array_subscripts)?) 
             {
                 if (!arr) arr = mk_nil();
                 id = to_rml_str(i);
                 ast = Absyn__CREF_5fIDENT(
                     id,
                     arr);

             }
         |#(DOT #(i2:IDENT (arr = array_subscripts)?)  
             ast = component_reference)
             {
                 if (!arr) arr = mk_nil();
                 id = to_rml_str(i2);
                 ast = Absyn__CREF_5fQUAL(
                     id,
                     arr,
                     ast);

             }
         )
         ;

 function_call returns [void* ast]
     :
         #(FUNCTION_ARGUMENTS ast = function_arguments);

 function_arguments 	returns [void* ast]
 {
     l_stack el_stack;
     void* e=0;
     void* elist=0;
     void* namel=0;
 }
     :
         (e = expression { el_stack.push(e); } )* (namel = named_arguments)?
         {

         elist = make_rml_list_from_stack(el_stack);
         if (!namel) namel = mk_nil();
         ast = Absyn__FUNCTIONARGS(elist,namel); 		
         }
     ;

 named_arguments returns [void* ast]
 {
     l_stack el_stack;
     void* n;
 } 
     :
         (n = named_argument { el_stack.push(n); }) (n = named_argument { el_stack.push(n); } )*
     {
         ast = make_rml_list_from_stack(el_stack);
     }
     ;

 named_argument returns [void* ast]
 {
   void* temp;
 }
      :
         #(eq:EQUALS i:IDENT temp = expression)
     {
         ast = Absyn__NAMEDARG(to_rml_str(i),temp);
     }
     ;

 expression_list returns [void* ast]
 {
     l_stack el_stack;
     void* e;
 }
     : 
         (#(EXPRESSION_LIST 
                 e = expression { el_stack.push(e); }
                 (e = expression { el_stack.push(e); } )*
             )
         )
         {
             ast = make_rml_list_from_stack(el_stack);
         }
     ;

 tuple_expression_list returns [void* ast]
 {
     l_stack el_stack;
     void* e;
 }
     : 
         (#(EXPRESSION_LIST 
                 e = expression { el_stack.push(e); }
                 (e = expression { el_stack.push(e); } )*
             )
         )
         {
             if (el_stack.size() == 1)
             {
                 ast = el_stack.top();
             }
             else
             {
                 ast = Absyn__TUPLE(make_rml_list_from_stack(el_stack));
             }
         }
     ;

 array_subscripts returns [void* ast]
 {
     l_stack el_stack;
     void* s = 0;
 }
     :
         #(LBRACK s = subscript 
             {
                 el_stack.push(s);
             }
             (s = subscript
                 {
                     el_stack.push(s);
                 }
                 )* )
         {
             ast = make_rml_list_from_stack(el_stack);
         }
         ;

 subscript returns [void* ast]
 {
     void* e;
 }
     :
         (
             e = expression 
             {
                 ast = Absyn__SUBSCRIPT(e);
             }
         | c:COLON 
             {
                 ast = Absyn__NOSUB;
             }
         )
     ;

 comment returns [void* ast]
 {
 void* ann=0;
 }		:
         #(COMMENT string_comment (ann = annotation)?)
         {
             ast = ann;
         }
         | 
	 {
	   ast = 0;
	 }
         ;

 string_comment :
         #(STRING_COMMENT string_concatenation)
         |
         ;

 string_concatenation :
         s:STRING  
         |#(p:PLUS string_concatenation s2:STRING)
         ;

annotation returns [ void *ast]
{
    void *cmod=0;
}
    :
        #(a:ANNOTATION cmod = class_modification)
        {
            ast = Absyn__ANNOTATION(cmod);
        }
    ;		


