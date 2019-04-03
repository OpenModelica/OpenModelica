encapsulated package ParseCodeModelica // OMCCp v0.10.0 OpenModelica lexer and parser generator (2014)
import Types;

constant Boolean debug = false;
// Note: AstItem must be defined, and TOKEN(someToken) must return a valid AstItem (usually a record in the uniontype)


import Absynrml;
import Absyn;
import OMCCTypes;
import System;

constant list<String> lstSemValue3 = {};
constant list<String> lstSemValue  = {
 "error", "$undefined", "KW_AND", "KW_AS", "KW_AXIOM",
  "KW_DATATYPE", "KW_DEFAULT", "KW_END", "KW_EQTYPE", "KW_FAIL", "KW_LET",
  "KW_MODULE", "KW_NOT", "KW_OF", "KW_RELATION", "KW_RULE", "KW_TYPE",
  "KW_VAL", "KW_WITH", "KW_INTERFACE", "KW_WITHTYPE", "AMPERSAND", "LPAR",
  "RPAR", "STAR", "COMMA", "DASHES", "DOT", "COLONCOLON", "COLON", "EQ",
  "FATARROW", "LBRACK", "RBRACK", "WILD", "BAR", "ADD_INT", "SUB_INT",
  "NEG_INT", "DIV_INT", "MOD_INT", "ADD_REAL", "SUB_REAL", "NEG_REAL",
  "MUL_REAL", "DIV_REAL", "MOD_REAL", "POWER_REAL", "EQEQ_INT", "GE_INT",
  "GT_INT", "LE_INT", "LT_INT", "NOTEQ_INT", "EQEQ_REAL", "GE_REAL",
  "GT_REAL", "LE_REAL", "LT_REAL", "NOTEQ_REAL", "IDENT", "TYVAR", "ICON",
  "RCON", "SCON", "$accept", "module", "rml_interface",
  "rml_interface_item_star", "rml_interface_item", "rml_definitions",
  "rml_definition_item", "relbind_plus", "opt_type", "relbind",
  "typbind_plus", "typbind", "datbind_plus", "datbind", "conbind_plus",
  "conbind", "default_opt", "clause_plus", "clause", "result",
  "conjunctive_goal_opt", "conjunctive_goal", "atomic_goal", "rml_addsub",
  "rml_muldiv", "rml_unary", "ty", "tuple_ty", "ty_sans_star",
  "ty_comma_seq2", "seq_ty", "tyvarseq1", "tyvarparseq", "tyvarseq",
  "longid", "longorshortid", "ident", "rml_ident", "tyvar", "rml_literal",
  "pat", "pat_a", "pat_b", "pat_c", "pat_d", "pat_e", "res_pat", "seq_pat",
  "pat_star", "pat_comma_star", "pat_comma_plus", "rml_expression",
  "rml_expression_list", "rml_exp_a", "rml_exp_b", "rml_exp_c",
  "rml_primary", "rml_exp_comma_star", "rml_exp_comma_plus",
  "rml_exp_star", "seq_exp"};

uniontype AstItem
record TOKEN
 OMCCTypes.Token tok;
 end TOKEN;

record PROGRAM
 Absynrml.Program program;
end PROGRAM;

record STRING
  String string;
end STRING;

record RMLIDENT
  Absynrml.RMLIdent rmlident;
end RMLIDENT;

record RMLINTERFACE
   Absynrml.RMLDec rmlinterface;
end RMLINTERFACE;

record RMLINTERFACES
  list<Absynrml.RMLDec> rmlinterfaces;
end RMLINTERFACES;

record RMLDEFINITION
   Absynrml.RMLDefinition rmldef;
end RMLDEFINITION;

record RMLDEFINITIONS
    list<Absynrml.RMLDefinition> rmldefs;
end RMLDEFINITIONS;

record RMLDATATYPE
   Absynrml.RMLDatatype rmldatatype;
end RMLDATATYPE;

record RMLTYPE
   Absynrml.RMLType rmltype;
end RMLTYPE;

record RMLTYPES
   list<Absynrml.RMLType> rmltypes;
end RMLTYPES;

record RMLTYOPT
   Option<Absynrml.RMLType> rmltyopt;
end RMLTYOPT;

record DTMEMBER
   Absynrml.DTMember dtmember;
end DTMEMBER;

record DTMEMBERS
   list<Absynrml.DTMember> dtmembers;
end DTMEMBERS;

record RMLRULE
   Absynrml.RMLRule rmlrule;
end RMLRULE;

record RMLRULES
   list<Absynrml.RMLRule> rmlrules;
end RMLRULES;

record RMLRULEOPT
   Option<Absynrml.RMLRule> rmlruleopt;
end RMLRULEOPT;

record RMLPATTERN
   Absynrml.RMLPattern rmlpattern;
end RMLPATTERN;

record RMLPATTERNS
   list<Absynrml.RMLPattern> rmlpatterns;
end RMLPATTERNS;

record RMLPATTERNOPT
  Option<Absynrml.RMLPattern> rmlpatternopt;
end RMLPATTERNOPT;

record RMLRESULT
   Absynrml.RMLResult rmlresult;
end RMLRESULT;

record RMLGOAL
   Absynrml.RMLGoal rmlgoal;
end RMLGOAL;

record RMLGOALOPT
   Option<Absynrml.RMLGoal> rmlgoalopt;
end RMLGOALOPT;

record EXP
   Absynrml.RMLExp exp;
end EXP;

record EXPS
   list<Absynrml.RMLExp> exps;
end EXPS;

record RMLLITERAL
   Absynrml.RMLLiteral rmlliteral;
end RMLLITERAL;
end AstItem;


uniontype AstStack
  record ASTSTACK
    list<OMCCTypes.Token> stackToken;
    list<AstItem> stack;
  end ASTSTACK;
end AstStack;

function initAstStack
  output AstStack astStack;
 algorithm
   astStack := ASTSTACK({},{});
end initAstStack;

function actionRed
  input Integer act;
  input AstStack astStack;
  input String fileName;
  output AstStack outStack;
  output Boolean error=false;
  output String errorMsg="";
protected
  list<OMCCTypes.Token> stackToken;
  list<AstItem> stack;
  AstItem yyval;
algorithm
  ASTSTACK(stackToken=stackToken,stack=stack) := astStack;
  if debug then
    print("reduce: " + intString(act) + ", " + intString(listLength(stack)) + " on stack with top token ctor " + intString(valueConstructor(listGet(stackToken,1))) + "\n");
  end if;
  _ := match act
    local
      //local variables
        AstItem yysp_1,yysp_2,yysp_3,yysp_4,yysp_5,yysp_6,yysp_7;

       case 2
         equation
           stackToken = mergeStackTokens(stackToken,5) annotation(__OpenModelica_FileInfo=("parserModelica.y",216));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",216));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",216));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",216));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",216));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",216));
           (yyval) = PROGRAM(Absynrml.MODULE(getRMLIdent(yysp_2),getRMLInterfaces(yysp_4),getRMLDefinitions(yysp_5),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",216));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",216));
         then ();

       case 3
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",219));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",219));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",219));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",219));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",219));
           (yyval) = PROGRAM(Absynrml.MODULE(getRMLIdent(yysp_2),getRMLInterfaces(yysp_4),{},OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",219));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",219));
         then ();

       case 4
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",224));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",224));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",224));
           (yyval) = RMLINTERFACES(getRMLInterfaces(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",224));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",224));
         then ();

       case 5
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",228));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",228));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",228));
           (yyval) = RMLINTERFACES(getRMLInterface(yysp_1)::getRMLInterfaces(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",228));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",228));
         then ();

       case 6
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",231));
           (yyval) = RMLINTERFACES({}) annotation(__OpenModelica_FileInfo=("parserModelica.y",231));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",231));
         then ();

       case 7
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",235));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",235));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",235));
           (yyval) = RMLINTERFACE(Absynrml.WITH(getString(yysp_2),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",235));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",235));
         then ();

       case 8
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",238));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",238));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",238));
           (yyval) = RMLINTERFACE(getRMLInterface(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",238));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",238));
         then ();

       case 9
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",241));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",241));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",241));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",241));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",241));
           (yyval) = RMLINTERFACE(Absynrml.VAL_INTERFACE(getRMLIdent(yysp_2),getRMLType(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",241));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",241));
         then ();

       case 10
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",244));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",244));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",244));
           (yyval) = RMLINTERFACE(Absynrml.DATATYPE_INTERFACE(getRMLDatatype(yysp_2),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",244));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",244));
         then ();

       case 11
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",247));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",247));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",247));
           (yyval) = RMLINTERFACE(Absynrml.DATATYPE_INTERFACE(getRMLDatatype(yysp_2),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",247));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",247));
         then ();

       case 12
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",250));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",250));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",250));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",250));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",250));
           (yyval) = RMLINTERFACE(Absynrml.RELATION_INTERFACE(getRMLIdent(yysp_2),getRMLType(yysp_4))) annotation(__OpenModelica_FileInfo=("parserModelica.y",250));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",250));
         then ();

       case 13
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",254));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",254));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",254));
           (yyval) = RMLDEFINITIONS(getRMLDefinition(yysp_1)::getRMLDefinitions(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",254));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",254));
         then ();

       case 14
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",257));
           (yyval) = RMLDEFINITIONS({}) annotation(__OpenModelica_FileInfo=("parserModelica.y",257));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",257));
         then ();

       case 15
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",261));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",261));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",261));
           (yyval) = RMLDEFINITION(Absynrml.WITH_DEF(getString(yysp_2),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",261));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",261));
         then ();

       case 16
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",264));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",264));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",264));
           (yyval) = RMLDEFINITION(Absynrml.DATATYPE_DEFINITION(getRMLDatatype(yysp_2),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",264));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",264));
         then ();

       case 17
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",267));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",267));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",267));
           (yyval) = RMLDEFINITION(Absynrml.DATATYPE_DEFINITION(getRMLDatatype(yysp_2),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",267));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",267));
         then ();

       case 18
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",270));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",270));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",270));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",270));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",270));
           (yyval) = RMLDEFINITION(Absynrml.VAL_DEF(getRMLIdent(yysp_2),getExp(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",270));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",270));
         then ();

       case 19
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",273));
           (yyval) = RMLDEFINITION(getRMLDefinition(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",273));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",273));
         then ();

       case 20
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",277));
           (yyval) = RMLDEFINITION(getRMLDefinition(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",277));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",277));
         then ();

       case 21
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",281));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",281));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",281));
           (yyval) = RMLTYOPT(SOME(getRMLType(yysp_2))) annotation(__OpenModelica_FileInfo=("parserModelica.y",281));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",281));
         then ();

       case 22
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",284));
           (yyval) = RMLTYOPT(NONE()) annotation(__OpenModelica_FileInfo=("parserModelica.y",284));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",284));
         then ();

       case 23
         equation
           stackToken = mergeStackTokens(stackToken,7) annotation(__OpenModelica_FileInfo=("parserModelica.y",287));
           yysp_7::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",287));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",287));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",287));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",287));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",287));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",287));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",287));
           (yyval) = RMLDEFINITION(Absynrml.RELATION_DEFINITION(getRMLIdent(yysp_2),getRMLTyopt(yysp_3),getRMLRules(yysp_5),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",287));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",287));
         then ();

       case 24
         equation
           stackToken = mergeStackTokens(stackToken,7) annotation(__OpenModelica_FileInfo=("parserModelica.y",290));
           yysp_7::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",290));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",290));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",290));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",290));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",290));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",290));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",290));
           (yyval) = RMLDEFINITION(Absynrml.RELATION_DEFINITION(getRMLIdent(yysp_2),getRMLTyopt(yysp_3),getRMLRules(yysp_5),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",290));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",290));
         then ();

       case 25
         equation
           stackToken = mergeStackTokens(stackToken,6) annotation(__OpenModelica_FileInfo=("parserModelica.y",293));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",293));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",293));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",293));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",293));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",293));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",293));
           (yyval) = RMLDEFINITION(Absynrml.RELATION_DEFINITION(getRMLIdent(yysp_2),NONE(),getRMLRules(yysp_5),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",293));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",293));
         then ();

       case 26
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",297));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",297));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",297));
           (yyval) = RMLRULEOPT(SOME(getRMLRule(yysp_2))) annotation(__OpenModelica_FileInfo=("parserModelica.y",297));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",297));
         then ();

       case 27
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",300));
           (yyval) = RMLRULEOPT(NONE()) annotation(__OpenModelica_FileInfo=("parserModelica.y",300));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",300));
         then ();

       case 28
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",304));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",304));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",304));
           (yyval) = RMLRULES(getRMLRule(yysp_1)::getRMLRules(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",304));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",304));
         then ();

       case 29
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",307));
           (yyval) = RMLRULES(getRMLRule(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",307));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",307));
         then ();

       case 30
         equation
           stackToken = mergeStackTokens(stackToken,6) annotation(__OpenModelica_FileInfo=("parserModelica.y",311));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",311));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",311));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",311));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",311));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",311));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",311));
           (yyval) = RMLRULE(Absynrml.RMLRULE(getRMLIdent(yysp_4),getRMLPattern(yysp_5),getRMLGoalopt(yysp_2),getRMLResult(yysp_6),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",311));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",311));
         then ();

       case 31
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",314));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",314));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",314));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",314));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",314));
           (yyval) = RMLRULE(Absynrml.RMLRULE(getRMLIdent(yysp_2),getRMLPattern(yysp_3),NONE(),getRMLResult(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",314));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",314));
         then ();

       case 32
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",318));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",318));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",318));
           (yyval) = RMLRESULT(Absynrml.RETURN(getExps(yysp_2),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",318));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",318));
         then ();

       case 33
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",321));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",321));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",321));
           (yyval) = RMLRESULT(Absynrml.FAIL()) annotation(__OpenModelica_FileInfo=("parserModelica.y",321));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",321));
         then ();

       case 34
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",324));
           (yyval) = RMLRESULT(Absynrml.EMPTY_RESULT()) annotation(__OpenModelica_FileInfo=("parserModelica.y",324));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",324));
         then ();

       case 35
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",328));
           (yyval) = RMLGOALOPT(SOME(getRMLGoal(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",328));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",328));
         then ();

       case 36
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",331));
           (yyval) = RMLGOALOPT(NONE()) annotation(__OpenModelica_FileInfo=("parserModelica.y",331));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",331));
         then ();

       case 37
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",335));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",335));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",335));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",335));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_AND(getRMLGoal(yysp_1),getRMLGoal(yysp_3))) annotation(__OpenModelica_FileInfo=("parserModelica.y",335));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",335));
         then ();

       case 38
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",338));
           (yyval) = RMLGOAL(getRMLGoal(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",338));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",338));
         then ();

       case 39
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",342));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",342));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",342));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",342));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",342));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",342));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",342));
         then ();

       case 40
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",345));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",345));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",345));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",345));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",345));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",345));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",345));
         then ();

       case 41
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",348));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",348));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",348));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",348));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",348));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",348));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",348));
         then ();

       case 42
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",351));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",351));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",351));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",351));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",351));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",351));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",351));
         then ();

       case 43
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",354));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",354));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",354));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",354));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",354));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",354));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",354));
         then ();

       case 44
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",357));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",357));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",357));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",357));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",357));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",357));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",357));
         then ();

       case 45
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",360));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",360));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",360));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",360));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",360));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",360));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",360));
         then ();

       case 46
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",363));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",363));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",363));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",363));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",363));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",363));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",363));
         then ();

       case 47
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",366));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",366));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",366));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",366));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",366));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",366));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",366));
         then ();

       case 48
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",369));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",369));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",369));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",369));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",369));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",369));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",369));
         then ();

       case 49
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",372));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",372));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",372));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",372));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",372));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",372));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",372));
         then ();

       case 50
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",375));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",375));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",375));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",375));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",375));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",375));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",375));
         then ();

       case 51
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",378));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",378));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",378));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",378));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",378));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",378));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",378));
         then ();

       case 52
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",381));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",381));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",381));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",381));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",381));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",381));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",381));
         then ();

       case 53
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",384));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",384));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",384));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",384));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_3),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",384));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",384));
         then ();

       case 54
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",387));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",387));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",387));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",387));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_3),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",387));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",387));
         then ();

       case 55
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",390));
           (yyval) = RMLGOAL(getRMLGoal(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",390));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",390));
         then ();

       case 56
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",393));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(getRMLIdent(yysp_1),{},NONE(),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",393));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",393));
         then ();

       case 57
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",396));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",396));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",396));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",396));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(getRMLIdent(yysp_1),getExps(yysp_2),getRMLPatternopt(yysp_3),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",396));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",396));
         then ();

       case 58
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",399));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",399));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",399));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",399));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_EQUAL(getRMLIdent(yysp_1),getExp(yysp_3),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",399));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",399));
         then ();

       case 59
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",402));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",402));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",402));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",402));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",402));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_LET(getRMLPattern(yysp_2),getExp(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",402));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",402));
         then ();

       case 60
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",405));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",405));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",405));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_NOT(getRMLGoal(yysp_2),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",405));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",405));
         then ();

       case 61
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",408));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",408));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",408));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",408));
           (yyval) = RMLGOAL(getRMLGoal(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",408));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",408));
         then ();

       case 62
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",412));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",412));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",412));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",412));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",412));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",412));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",412));
         then ();

       case 63
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",415));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",415));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",415));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",415));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",415));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",415));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",415));
         then ();

       case 64
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",418));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",418));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",418));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",418));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",418));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",418));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",418));
         then ();

       case 65
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",421));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",421));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",421));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",421));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",421));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",421));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",421));
         then ();

       case 66
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",424));
           (yyval) = RMLGOAL(getRMLGoal(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",424));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",424));
         then ();

       case 67
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",428));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",428));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",428));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",428));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",428));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",428));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",428));
         then ();

       case 68
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",431));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",431));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",431));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",431));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",431));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",431));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",431));
         then ();

       case 69
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",434));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",434));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",434));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",434));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",434));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",434));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",434));
         then ();

       case 70
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",437));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",437));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",437));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",437));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",437));
           (yyval) = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString(yysp_2)),{},getRMLPatternopt(yysp_4),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",437));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",437));
         then ();

       case 71
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",440));
           (yyval) = EXP(getExp(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",440));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",440));
         then ();

       case 72
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",444));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",444));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",444));
           (yyval) = EXP(Absynrml.RMLUNARY(Absyn.UMINUS(),getExp(yysp_2))) annotation(__OpenModelica_FileInfo=("parserModelica.y",444));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",444));
         then ();

       case 73
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",447));
           (yyval) = EXP(getExp(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",447));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",447));
         then ();

       case 74
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",451));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",451));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",451));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",451));
           (yyval) = RMLPATTERN(Absynrml.RMLPAT_AS(getRMLIdent(yysp_1),getRMLPattern(yysp_3))) annotation(__OpenModelica_FileInfo=("parserModelica.y",451));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",451));
         then ();

       case 75
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",454));
           (yyval) = RMLPATTERN(getRMLPattern(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",454));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",454));
         then ();

       case 76
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",458));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",458));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",458));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",458));
           (yyval) = RMLPATTERN(Absynrml.RMLPAT_CONS(getRMLPattern(yysp_1),getRMLPattern(yysp_3))) annotation(__OpenModelica_FileInfo=("parserModelica.y",458));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",458));
         then ();

       case 77
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",461));
           (yyval) = RMLPATTERN(getRMLPattern(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",461));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",461));
         then ();

       case 78
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",465));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",465));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",465));
           (yyval) = RMLPATTERN(Absynrml.RMLPAT_NIL()) annotation(__OpenModelica_FileInfo=("parserModelica.y",465));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",465));
         then ();

       case 79
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",468));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",468));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",468));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",468));
           (yyval) = RMLPATTERN(getRMLPattern(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",468));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",468));
         then ();

       case 80
         equation
           stackToken = mergeStackTokens(stackToken,5) annotation(__OpenModelica_FileInfo=("parserModelica.y",471));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",471));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",471));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",471));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",471));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",471));
           (yyval) = RMLPATTERN(Absynrml.RMLPAT_STRUCT(NONE(),getRMLPattern(yysp_2)::getRMLPatterns(yysp_4))) annotation(__OpenModelica_FileInfo=("parserModelica.y",471));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",471));
         then ();

       case 81
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",474));
           (yyval) = RMLPATTERN(getRMLPattern(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",474));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",474));
         then ();

       case 82
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",478));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",478));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",478));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",478));
           (yyval) = RMLPATTERN(Absynrml.RMLPAT_CONS(getRMLPattern(yysp_1),getRMLPattern(yysp_3))) annotation(__OpenModelica_FileInfo=("parserModelica.y",478));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",478));
         then ();

       case 83
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",481));
           (yyval) = RMLPATTERN(getRMLPattern(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",481));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",481));
         then ();

       case 84
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",484));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",484));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",484));
           (yyval) = RMLPATTERN(Absynrml.RMLPAT_STRUCT(SOME(getRMLIdent(yysp_1)),getRMLPatterns(yysp_2))) annotation(__OpenModelica_FileInfo=("parserModelica.y",484));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",484));
         then ();

       case 85
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",487));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",487));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",487));
           (yyval) = RMLPATTERN(Absynrml.RMLPAT_STRUCT(SOME(getRMLIdent(yysp_1)),getRMLPattern(yysp_2)::{})) annotation(__OpenModelica_FileInfo=("parserModelica.y",487));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",487));
         then ();

       case 86
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",490));
           (yyval) = RMLPATTERN(getRMLPattern(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",490));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",490));
         then ();

       case 87
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",494));
           (yyval) = RMLPATTERN(Absynrml.RMLPAT_WILDCARD()) annotation(__OpenModelica_FileInfo=("parserModelica.y",494));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",494));
         then ();

       case 88
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",497));
           (yyval) = RMLPATTERN(Absynrml.RMLPAT_LITERAL(getRMLLiteral(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",497));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",497));
         then ();

       case 89
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",500));
           (yyval) = RMLPATTERN(Absynrml.RMLPAT_IDENT(getRMLIdent(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",500));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",500));
         then ();

       case 90
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",503));
           (yyval) = RMLPATTERN(Absynrml.RMLPAT_IDENT(getRMLIdent(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",503));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",503));
         then ();

       case 91
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",506));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",506));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",506));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",506));
           (yyval) = RMLPATTERN(Absynrml.RMLPAT_LIST(getRMLPatterns(yysp_2))) annotation(__OpenModelica_FileInfo=("parserModelica.y",506));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",506));
         then ();

       case 92
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",510));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",510));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",510));
           (yyval) = RMLPATTERNOPT(SOME(getRMLPattern(yysp_2))) annotation(__OpenModelica_FileInfo=("parserModelica.y",510));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",510));
         then ();

       case 93
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",513));
           (yyval) = RMLPATTERNOPT(NONE()) annotation(__OpenModelica_FileInfo=("parserModelica.y",513));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",513));
         then ();

       case 94
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",517));
           (yyval) = RMLPATTERN(getRMLPattern(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",517));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",517));
         then ();

       case 95
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",520));
           (yyval) = RMLPATTERN(Absynrml.RMLPAT_STRUCT(NONE(),getRMLPatterns(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",520));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",520));
         then ();

       case 96
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",523));
           (yyval) = RMLPATTERN(Absynrml.RMLPAT_STRUCT(NONE(),{})) annotation(__OpenModelica_FileInfo=("parserModelica.y",523));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",523));
         then ();

       case 97
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",527));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",527));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",527));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",527));
           (yyval) = RMLPATTERNS(getRMLPatterns(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",527));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",527));
         then ();

       case 98
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",531));
           (yyval) = RMLPATTERNS(getRMLPatterns(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",531));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",531));
         then ();

       case 99
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",534));
           (yyval) = RMLPATTERNS({}) annotation(__OpenModelica_FileInfo=("parserModelica.y",534));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",534));
         then ();

       case 100
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",538));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",538));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",538));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",538));
           (yyval) = RMLPATTERNS(getRMLPattern(yysp_1)::getRMLPatterns(yysp_3)) annotation(__OpenModelica_FileInfo=("parserModelica.y",538));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",538));
         then ();

       case 101
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",541));
           (yyval) = RMLPATTERNS(getRMLPattern(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",541));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",541));
         then ();

       case 102
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",545));
           (yyval) = RMLLITERAL(Absynrml.RMLLIT_INTEGER(stringInt(getString(yysp_1)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",545));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",545));
         then ();

       case 103
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",548));
           (yyval) = RMLLITERAL(Absynrml.RMLLIT_REAL(stringReal(getString(yysp_1)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",548));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",548));
         then ();

       case 104
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",551));
           (yyval) = RMLLITERAL(Absynrml.RMLLIT_STRING(getString(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",551));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",551));
         then ();

       case 105
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",554));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",554));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",554));
           (yyval) = RMLLITERAL(Absynrml.RMLLIT_INTEGER(intNeg(stringInt(getString(yysp_2))))) annotation(__OpenModelica_FileInfo=("parserModelica.y",554));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",554));
         then ();

       case 106
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",557));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",557));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",557));
           (yyval) = RMLLITERAL(Absynrml.RMLLIT_REAL(realNeg(stringReal(getString(yysp_2))))) annotation(__OpenModelica_FileInfo=("parserModelica.y",557));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",557));
         then ();

       case 107
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",561));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",561));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",561));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",561));
           (yyval) = EXP(Absynrml.RMLCONS(getExp(yysp_1),getExp(yysp_3))) annotation(__OpenModelica_FileInfo=("parserModelica.y",561));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",561));
         then ();

       case 108
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",564));
           (yyval) = EXP(getExp(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",564));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",564));
         then ();

       case 109
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",568));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",568));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",568));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",568));
           (yyval) = EXPS(getExp(yysp_1)::getExps(yysp_3)) annotation(__OpenModelica_FileInfo=("parserModelica.y",568));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",568));
         then ();

       case 110
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",571));
           (yyval) = EXPS(getExp(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",571));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",571));
         then ();

       case 111
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",576));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",576));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",576));
           (yyval) = EXP(Absynrml.RMLEXP_NIL()) annotation(__OpenModelica_FileInfo=("parserModelica.y",576));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",576));
         then ();

       case 112
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",579));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",579));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",579));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",579));
           (yyval) = EXP(getExp(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",579));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",579));
         then ();

       case 113
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",582));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",582));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",582));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",582));
           (yyval) = EXP(Absynrml.RMLTUPLE(getExps(yysp_2))) annotation(__OpenModelica_FileInfo=("parserModelica.y",582));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",582));
         then ();

       case 114
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",585));
           (yyval) = EXP(getExp(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",585));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",585));
         then ();

       case 115
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",589));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",589));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",589));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",589));
           (yyval) = EXP(Absynrml.RMLCONS(getExp(yysp_1),getExp(yysp_3))) annotation(__OpenModelica_FileInfo=("parserModelica.y",589));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",589));
         then ();

       case 116
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",592));
           (yyval) = EXP(getExp(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",592));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",592));
         then ();

       case 117
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",596));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",596));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",596));
           (yyval) = EXP(Absynrml.RMLCALL(getRMLIdent(yysp_1),getExps(yysp_2))) annotation(__OpenModelica_FileInfo=("parserModelica.y",596));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",596));
         then ();

       case 118
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",599));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",599));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",599));
           (yyval) = EXP(Absynrml.RMLCALL(getRMLIdent(yysp_1),getExp(yysp_2)::{})) annotation(__OpenModelica_FileInfo=("parserModelica.y",599));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",599));
         then ();

       case 119
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",602));
           (yyval) = EXP(getExp(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",602));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",602));
         then ();

       case 120
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",606));
           (yyval) = EXP(Absynrml.RMLLIT(getRMLLiteral(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",606));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",606));
         then ();

       case 121
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",609));
           (yyval) = EXP(Absynrml.RML_REFERENCE(getRMLIdent(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",609));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",609));
         then ();

       case 122
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",612));
           (yyval) = EXP(Absynrml.RML_REFERENCE(getRMLIdent(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",612));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",612));
         then ();

       case 123
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",615));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",615));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",615));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",615));
           (yyval) = EXP(Absynrml.RMLLIST(getExps(yysp_2))) annotation(__OpenModelica_FileInfo=("parserModelica.y",615));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",615));
         then ();

       case 124
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",618));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",618));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",618));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",618));
           (yyval) = EXP(getExp(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",618));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",618));
         then ();

       case 125
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",623));
           (yyval) = EXPS(getExps(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",623));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",623));
         then ();

       case 126
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",626));
           (yyval) = EXPS({}) annotation(__OpenModelica_FileInfo=("parserModelica.y",626));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",626));
         then ();

       case 127
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",630));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",630));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",630));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",630));
           (yyval) = EXPS(getExp(yysp_1)::getExps(yysp_3)) annotation(__OpenModelica_FileInfo=("parserModelica.y",630));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",630));
         then ();

       case 128
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",633));
           (yyval) = EXPS(getExp(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",633));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",633));
         then ();

       case 129
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",638));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",638));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",638));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",638));
           (yyval) = EXPS(getExps(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",638));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",638));
         then ();

       case 130
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",642));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",642));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",642));
           (yyval) = EXPS({}) annotation(__OpenModelica_FileInfo=("parserModelica.y",642));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",642));
         then ();

       case 131
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",645));
           (yyval) = EXPS(getExp(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",645));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",645));
         then ();

       case 132
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",648));
           (yyval) = EXPS(getExps(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",648));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",648));
         then ();

       case 133
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",651));
           (yyval) = EXPS({}) annotation(__OpenModelica_FileInfo=("parserModelica.y",651));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",651));
         then ();

       case 134
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",655));
           (yyval) = RMLINTERFACE(getRMLInterface(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",655));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",655));
         then ();

       case 135
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",659));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",659));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",659));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",659));
           (yyval) = RMLINTERFACE(Absynrml.TYPE(getRMLIdent(yysp_1),getRMLType(yysp_3),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",659));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",659));
         then ();

       case 136
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",663));
           (yyval) = RMLDATATYPE(getRMLDatatype(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",663));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",663));
         then ();

       case 137
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",667));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",667));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",667));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",667));
           (yyval) = RMLDATATYPE(Absynrml.DATATYPE(getRMLIdent(yysp_1),getDTMembers(yysp_3))) annotation(__OpenModelica_FileInfo=("parserModelica.y",667));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",667));
         then ();

       case 138
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",670));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",670));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",670));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",670));
           (yyval) = RMLDATATYPE(Absynrml.DATATYPE(getRMLIdent(yysp_1),getDTMember(yysp_3)::{})) annotation(__OpenModelica_FileInfo=("parserModelica.y",670));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",670));
         then ();

       case 139
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",675));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",675));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",675));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",675));
           (yyval) = DTMEMBERS(getDTMember(yysp_1)::getDTMembers(yysp_3)) annotation(__OpenModelica_FileInfo=("parserModelica.y",675));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",675));
         then ();

       case 140
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",678));
           (yyval) = DTMEMBERS(getDTMember(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",678));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",678));
         then ();

       case 141
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",682));
           (yyval) = DTMEMBER(Absynrml.DTCONS(getRMLIdent(yysp_1),{},OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",682));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",682));
         then ();

       case 142
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",685));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",685));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",685));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",685));
           (yyval) = DTMEMBER(Absynrml.DTCONS(getRMLIdent(yysp_1),getRMLType(yysp_3)::{},OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",685));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",685));
         then ();

       case 143
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",688));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",688));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",688));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",688));
           (yyval) = DTMEMBER(Absynrml.DTCONS(getRMLIdent(yysp_1),getRMLTypes(yysp_3),OMCCTypes.makeInfo(listGet(stackToken,1),fileName))) annotation(__OpenModelica_FileInfo=("parserModelica.y",688));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",688));
         then ();

       case 144
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",692));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",692));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",692));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",692));
           (yyval) = RMLDATATYPE(Absynrml.DATATYPE(getRMLIdent(yysp_1),getDTMembers(yysp_3))) annotation(__OpenModelica_FileInfo=("parserModelica.y",692));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",692));
         then ();

       case 145
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",697));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",697));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",697));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",697));
           (yyval) = RMLTYPE(Absynrml.RMLTYPE_SIGNATURE(Absynrml.CALLSIGN(getRMLTypes(yysp_1),getRMLTypes(yysp_3)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",697));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",697));
         then ();

       case 146
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",700));
           (yyval) = RMLTYPE(getRMLType(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",700));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",700));
         then ();

       case 147
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",703));
           (yyval) = RMLTYPE(Absynrml.RMLTYPE_TUPLE(getRMLTypes(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",703));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",703));
         then ();

       case 148
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",707));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",707));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",707));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",707));
           (yyval) = RMLTYPES(getRMLType(yysp_1)::getRMLTypes(yysp_3)) annotation(__OpenModelica_FileInfo=("parserModelica.y",707));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",707));
         then ();

       case 149
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",710));
           (yyval) = RMLTYPES(getRMLType(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",710));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",710));
         then ();

       case 150
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",714));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",714));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",714));
           (yyval) = RMLTYPE(Absynrml.RMLTYPE_TYCONS(getRMLType(yysp_1)::{},getRMLIdent(yysp_2))) annotation(__OpenModelica_FileInfo=("parserModelica.y",714));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",714));
         then ();

       case 151
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",717));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",717));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",717));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",717));
           (yyval) = RMLTYPE(getRMLType(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",717));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",717));
         then ();

       case 152
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",720));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",720));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",720));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",720));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",720));
           (yyval) = RMLTYPE(Absynrml.RMLTYPE_TYCONS(getRMLTypes(yysp_2),getRMLIdent(yysp_4))) annotation(__OpenModelica_FileInfo=("parserModelica.y",720));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",720));
         then ();

       case 153
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",723));
           (yyval) = RMLTYPE(getRMLType(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",723));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",723));
         then ();

       case 154
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",726));
           (yyval) = RMLTYPE(Absynrml.RMLTYPE_USERDEFINED(getRMLIdent(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",726));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",726));
         then ();

       case 155
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",730));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",730));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",730));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",730));
           (yyval) = RMLTYPES(getRMLType(yysp_1)::getRMLTypes(yysp_3)) annotation(__OpenModelica_FileInfo=("parserModelica.y",730));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",730));
         then ();

       case 156
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",733));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",733));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",733));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",733));
           (yyval) = RMLTYPES(getRMLType(yysp_1)::getRMLType(yysp_3)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",733));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",733));
         then ();

       case 157
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",737));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",737));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",737));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",737));
           (yyval) = RMLTYPES(getRMLTypes(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",737));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",737));
         then ();

       case 158
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",740));
           (yyval) = RMLTYPES(getRMLTypes(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",740));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",740));
         then ();

       case 159
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",743));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",743));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",743));
           (yyval) = RMLTYPES({}) annotation(__OpenModelica_FileInfo=("parserModelica.y",743));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",743));
         then ();

       case 160
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",748));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",748));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",748));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",748));
           (yyval) = RMLIDENT(Absynrml.RMLLONGID(getString(yysp_1),getString(yysp_3))) annotation(__OpenModelica_FileInfo=("parserModelica.y",748));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",748));
         then ();

       case 161
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",752));
           (yyval) = RMLIDENT(getRMLIdent(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",752));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",752));
         then ();

       case 162
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",755));
           (yyval) = RMLIDENT(getRMLIdent(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",755));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",755));
         then ();

       case 163
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",759));
           (yyval) = STRING(getString(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",759));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",759));
         then ();

       case 164
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",763));
           (yyval) = RMLIDENT(Absynrml.RMLSHORTID(getString(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",763));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",763));
         then ();

       case 165
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",767));
           (yyval) = RMLTYPE(Absynrml.RMLTYPE_TYVAR(Absynrml.RMLSHORTID(getString(yysp_1)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",767));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",767));
         then ();

     else
       equation
          error = true;
       then ();
  end match;
  if debug then
    print("reduce: " + intString(act) + " to " + intString(listLength(stack)) + " on stack\n");
  end if;
  outStack := ASTSTACK(stackToken=stackToken,stack=stack);
end actionRed;

function mergeStackTokens
  input list<OMCCTypes.Token> skToken;
  input Integer nTokens(min=2);
  output list<OMCCTypes.Token> skTokenRes;
protected
  list<OMCCTypes.Token> skToken1:=skToken;
  OMCCTypes.Token token;
  OMCCTypes.Info tmpInfo;
  Integer lns,cns,lne,cne,i;
  String fn;
algorithm
  for i in 1:nTokens loop
     token::skToken1 := skToken1;
     if (i==nTokens) then
        OMCCTypes.TOKEN(lineNumberStart=lns,columnNumberStart=cns) := token;
     end if;
     if (i==1) then
        OMCCTypes.TOKEN(lineNumberEnd=lne,columnNumberEnd=cne) := token;
     end if;
  end for;
  // TODO: merge the contents also?
  token := OMCCTypes.TOKEN("grouped token",0,"",0,0,lns,cns,lne,cne);
  skTokenRes := token::skToken1;
end mergeStackTokens;

function push
  input AstStack astStk;
  input OMCCTypes.Token token;
  output AstStack astStk2;
protected
  list<OMCCTypes.Token> stackToken;
  list<AstItem> stack;
algorithm
  ASTSTACK(stackToken=stackToken,stack=stack) := astStk;
  stackToken := token::stackToken;
  stack := TOKEN(token)::stack;
  astStk2 := ASTSTACK(stackToken=stackToken,stack=stack);
end push;




public function trimquotes
"removes chars in charsToRemove from inString"
  input String inString;
  output String outString;
 algorithm
  if (stringLength(inString)>2) then
    outString := System.substring(inString,2,stringLength(inString)-1);
  else
    outString := "";
  end if;
end trimquotes;

function getString
  input AstItem item;
  output String out;
algorithm
  out := match item
    local
      OMCCTypes.Token tok;
    case STRING(string=out) then out;
    case TOKEN(tok=tok) then OMCCTypes.getStringValue(tok);
    else equation print("getString() failed\n"); then fail();
  end match;
end getString;


function getProgram
  input AstItem item;
  output Absynrml.Program out;
algorithm
  PROGRAM(program=out) := item;
end getProgram;

function getToken
  input AstItem item;
  output OMCCTypes.Token out;
algorithm
  OMCCTypes.TOKEN(tok=out) := item;
end getToken;

function getIdent
  input AstItem item;
  output Absynrml.Ident out;
algorithm
  IDENT(ident=out) := item;
end getIdent;

function getRMLIdent
  input AstItem item;
  output Absynrml.RMLIdent out;
  algorithm
  RMLIDENT(rmlident=out) :=item;
end getRMLIdent;

function getRMLInterface
  input AstItem item;
  output Absynrml.RMLDec out;
  algorithm
  RMLINTERFACE(rmlinterface=out) :=item;
end getRMLInterface;

function getRMLInterfaces
  input AstItem item;
  output list<Absynrml.RMLDec> out;
  algorithm
  RMLINTERFACES(rmlinterfaces=out) :=item;
end getRMLInterfaces;

function getRMLDefinition
  input AstItem item;
  output Absynrml.RMLDefinition out;
  algorithm
  RMLDEFINITION(rmldef=out) :=item;
end getRMLDefinition;

function getRMLDefinitions
  input AstItem item;
  output list<Absynrml.RMLDefinition> out;
  algorithm
  RMLDEFINITIONS(rmldefs=out) :=item;
end getRMLDefinitions;


function getRMLDatatype
  input AstItem item;
  output Absynrml.RMLDatatype out;
  algorithm
  RMLDATATYPE(rmldatatype=out) :=item;
end getRMLDatatype;


function getRMLType
  input AstItem item;
  output Absynrml.RMLType out;
  algorithm
  RMLTYPE(rmltype=out) :=item;
end getRMLType;

function getRMLTypes
  input AstItem item;
  output list<Absynrml.RMLType> out;
  algorithm
  RMLTYPES(rmltypes=out) :=item;
end getRMLTypes;

function getRMLTyopt
  input AstItem item;
  output Option<Absynrml.RMLType> out;
  algorithm
  RMLTYOPT(rmltyopt=out) :=item;
end getRMLTyopt;

function getDTMember
  input AstItem item;
  output Absynrml.DTMember out;
  algorithm
  DTMEMBER(dtmember=out) :=item;
end getDTMember;


function getDTMembers
  input AstItem item;
  output list<Absynrml.DTMember> out;
  algorithm
  DTMEMBERS(dtmembers=out) :=item;
end getDTMembers;

function getRMLRule
  input AstItem item;
  output Absynrml.RMLRule out;
  algorithm
  RMLRULE(rmlrule=out) :=item;
end getRMLRule;

function getRMLRules
  input AstItem item;
  output list<Absynrml.RMLRule> out;
  algorithm
  RMLRULES(rmlrules=out) :=item;
end getRMLRules;

function getRMLRuleopt
  input AstItem item;
  output Option<Absynrml.RMLRule> out;
  algorithm
  RMLRULEOPT(rmlruleopt=out) :=item;
end getRMLRuleopt;


function getRMLPattern
  input AstItem item;
  output Absynrml.RMLPattern out;
  algorithm
  RMLPATTERN(rmlpattern=out) :=item;
end getRMLPattern;

function getRMLPatterns
  input AstItem item;
  output list<Absynrml.RMLPattern> out;
  algorithm
  RMLPATTERNS(rmlpatterns=out) :=item;
end getRMLPatterns;

function getRMLPatternopt
  input AstItem item;
  output Option<Absynrml.RMLPattern> out;
  algorithm
  RMLPATTERNOPT(rmlpatternopt=out) :=item;
end getRMLPatternopt;


function getRMLResult
  input AstItem item;
  output Absynrml.RMLResult out;
  algorithm
  RMLRESULT(rmlresult=out) :=item;
end getRMLResult;

function getRMLGoal
  input AstItem item;
  output Absynrml.RMLGoal out;
  algorithm
  RMLGOAL(rmlgoal=out) :=item;
end getRMLGoal;

function getRMLGoalopt
  input AstItem item;
  output Option<Absynrml.RMLGoal> out;
  algorithm
  RMLGOALOPT(rmlgoalopt=out) :=item;
end getRMLGoalopt;


function getExp
  input AstItem item;
  output Absynrml.RMLExp out;
  algorithm
  EXP(exp=out) :=item;
end getExp;


function getExps
  input AstItem item;
  output list<Absynrml.RMLExp> out;
  algorithm
  EXPS(exps=out) :=item;
end getExps;


function getRMLLiteral
  input AstItem item;
  output Absynrml.RMLLiteral out;
  algorithm
  RMLLITERAL(rmlliteral=out) :=item;
end getRMLLiteral;



end ParseCodeModelica;
