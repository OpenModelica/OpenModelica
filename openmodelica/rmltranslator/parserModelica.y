%{
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

%}

%token KW_AND
%token KW_AS
%token KW_AXIOM
%token KW_DATATYPE
%token KW_DEFAULT
%token KW_END
%token KW_EQTYPE
%token KW_FAIL
%token KW_LET
%token KW_MODULE
%token KW_NOT
%token KW_OF
%token KW_RELATION
%token KW_RULE
%token KW_TYPE
%token KW_VAL
%token KW_WITH
%token KW_INTERFACE
%token KW_WITHTYPE 

%token AMPERSAND
%token LPAR
%token RPAR
%token STAR
%token COMMA
%token DASHES
%token DOT
%token COLONCOLON
%token COLON
%token EQ
%token FATARROW
%token LBRACK
%token RBRACK
%token WILD
%token BAR

%token ADD_INT
%token SUB_INT
%token NEG_INT
%token DIV_INT
%token MOD_INT


%token ADD_REAL
%token SUB_REAL
%token NEG_REAL
%token MUL_REAL
%token DIV_REAL
%token MOD_REAL
%token POWER_REAL

%token EQEQ_INT 
%token GE_INT 
%token GT_INT 
%token LE_INT 
%token LT_INT 
%token NOTEQ_INT 


%token EQEQ_REAL
%token GE_REAL
%token GT_REAL
%token LE_REAL 
%token LT_REAL 
%token NOTEQ_REAL 

%token IDENT 
%token TYVAR
%token ICON
%token RCON
%token SCON
%%

module: KW_MODULE rml_ident COLON rml_interface rml_definitions 		          
		   { $$ = PROGRAM(Absynrml.MODULE(getRMLIdent($2),getRMLInterfaces($4),getRMLDefinitions($5),yyinfo)); }
		            
        |KW_MODULE rml_ident COLON rml_interface
           { $$ = PROGRAM(Absynrml.MODULE(getRMLIdent($2),getRMLInterfaces($4),{},yyinfo)); }	  
        
        

rml_interface: rml_interface_item_star KW_END                 
                 { $$ = RMLINTERFACES(getRMLInterfaces($1)); }
               
		          
rml_interface_item_star: rml_interface_item rml_interface_item_star	                  
		                   { $$ = RMLINTERFACES(getRMLInterface($1)::getRMLInterfaces($2)); } 
                             
                         |/*EMPTY*/      
                           { $$ = RMLINTERFACES({}); }  
	                      

rml_interface_item :  KW_WITH SCON    
	                    { $$ = RMLINTERFACE(Absynrml.WITH(getString($2),yyinfo)); }
                    
	                  |KW_TYPE typbind_plus
                         { $$ = RMLINTERFACE(getRMLInterface($2)); }
						                                              
                      |KW_VAL rml_ident COLON ty
	                     { $$ = RMLINTERFACE(Absynrml.VAL_INTERFACE(getRMLIdent($2),getRMLType($4),yyinfo)); }
	     
                      |KW_DATATYPE datbind_plus 
	                     { $$ = RMLINTERFACE(Absynrml.DATATYPE_INTERFACE(getRMLDatatype($2),yyinfo)); }
			        
			          |KW_AND datbind_plus 
	                     { $$ = RMLINTERFACE(Absynrml.DATATYPE_INTERFACE(getRMLDatatype($2),yyinfo)); }
                         
                      |KW_RELATION rml_ident COLON ty
                         { $$ = RMLINTERFACE(Absynrml.RELATION_INTERFACE(getRMLIdent($2),getRMLType($4))); }

                                                     
rml_definitions:   rml_definition_item rml_definitions
		              { $$ = RMLDEFINITIONS(getRMLDefinition($1)::getRMLDefinitions($2)); }
					  
                   |/*empty*/
                      { $$ = RMLDEFINITIONS({}); }
		           

rml_definition_item: KW_WITH SCON 
     	               { $$ = RMLDEFINITION(Absynrml.WITH_DEF(getString($2),yyinfo)); }
     	                                 
                     |KW_DATATYPE datbind_def 
	                   { $$ = RMLDEFINITION(Absynrml.DATATYPE_DEFINITION(getRMLDatatype($2),yyinfo)); } 
			                  			        
			         |KW_AND datbind_def 
	                   { $$ = RMLDEFINITION(Absynrml.DATATYPE_DEFINITION(getRMLDatatype($2),yyinfo)); } 
			            
	                 |KW_VAL rml_ident EQ rml_expression
	           	       { $$ = RMLDEFINITION(Absynrml.VAL_DEF(getRMLIdent($2),getExp($4),yyinfo)); }
	   	                    
                     |relbind_plus
              		   { $$ = RMLDEFINITION(getRMLDefinition($1)); }
 
 
relbind_plus : relbind
              		   { $$ = RMLDEFINITION(getRMLDefinition($1)); }
                             
		                 
opt_type     : COLON ty
	             { $$ = RMLTYOPT(SOME(getRMLType($2))); } 
		              
	           | /*empty*/
			     { $$ = RMLTYOPT(NONE()); }
  
relbind     :  KW_RELATION rml_ident opt_type EQ clause_plus default_opt KW_END
	            { $$ = RMLDEFINITION(Absynrml.RELATION_DEFINITION(getRMLIdent($2),getRMLTyopt($3),getRMLRules($5),yyinfo)); }
           
              |KW_AND rml_ident opt_type EQ clause_plus default_opt KW_END
	            { $$ = RMLDEFINITION(Absynrml.RELATION_DEFINITION(getRMLIdent($2),getRMLTyopt($3),getRMLRules($5),yyinfo)); }
              
              |KW_AND rml_ident EQ clause_plus default_opt KW_END
	            { $$ = RMLDEFINITION(Absynrml.RELATION_DEFINITION(getRMLIdent($2),NONE(),getRMLRules($5),yyinfo)); }
                    
 
default_opt  :  KW_DEFAULT clause_plus
                { $$ = RMLRULEOPT(SOME(getRMLRule($2))); }                       			   
    		  
    		   |/*empty*/
			    { $$ = RMLRULEOPT(NONE()); }             
                    
   				
clause_plus  :  clause clause_plus
		          { $$ = RMLRULES(getRMLRule($1)::getRMLRules($2)); }  
		        
	            |clause
		          { $$ = RMLRULES(getRMLRule($1)::{}); }				    	

				
clause       : KW_RULE conjunctive_goal_opt DASHES rml_ident seq_pat result
         		{ $$ = RMLRULE(Absynrml.RMLRULE(getRMLIdent($4),getRMLPattern($5),getRMLGoalopt($2),getRMLResult($6),yyinfo)); }   			          
			
	          |KW_AXIOM rml_ident seq_pat result
		        { $$ = RMLRULE(Absynrml.RMLRULE(getRMLIdent($2),getRMLPattern($3),NONE(),getRMLResult($4),yyinfo)); }
                     	
									 									 
result  : FATARROW seq_exp
            { $$ = RMLRESULT(Absynrml.RETURN(getExps($2),yyinfo)); }    
          
          |FATARROW KW_FAIL
		    { $$ = RMLRESULT(Absynrml.FAIL()); }   
			    
		  |/*empty*/
		    { $$ = RMLRESULT(Absynrml.EMPTY_RESULT()); }  
			  
 
conjunctive_goal_opt  :   conjunctive_goal
		                    { $$ = RMLGOALOPT(SOME(getRMLGoal($1))); } 		  
				  	        
	                      |/* empty */
                   		    { $$ = RMLGOALOPT(NONE()); }
                               

conjunctive_goal  :  atomic_goal AMPERSAND conjunctive_goal
                       { $$ = RMLGOAL(Absynrml.RMLGOAL_AND(getRMLGoal($1),getRMLGoal($3))); }   
		                 
                     |atomic_goal
		               { $$ = RMLGOAL(getRMLGoal($1)); }	 
                                  

atomic_goal    : rml_primary EQEQ_INT rml_primary res_pat   
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }
			  
	             |rml_primary GE_INT rml_primary res_pat     
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }
                            	     
                 |rml_primary GT_INT rml_primary res_pat   
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }
          	               
	             |rml_primary LE_INT rml_primary res_pat   
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }
              	  
                 |rml_primary LT_INT rml_primary res_pat    
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }
             	  
                 |rml_primary NOTEQ_INT rml_primary res_pat    
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }
                	   
                 |rml_primary EQEQ_REAL rml_primary res_pat   
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }
             	  
                 |rml_primary GE_REAL rml_primary res_pat     
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }

                 |rml_primary GT_REAL rml_primary res_pat   
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }
  
                 |rml_primary LE_REAL rml_primary res_pat    
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }

              	 |rml_primary LT_REAL rml_primary res_pat    
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }

              	 |rml_primary NOTEQ_REAL rml_primary res_pat    
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }

		         |longorshortid SUB_REAL rml_addsub res_pat    
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }
  
			     |longorshortid SUB_INT rml_addsub res_pat  
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }

                 |SUB_REAL longorshortid res_pat     
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($3),yyinfo)); }
                                         	
                 |SUB_INT longorshortid res_pat     
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($3),yyinfo)); }

                 |rml_addsub
		            { $$ = RMLGOAL(getRMLGoal($1)); } 
   
				 |longorshortid
	            	{ $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(getRMLIdent($1),{},NONE(),yyinfo)); }
                             
                 |longorshortid seq_exp res_pat
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(getRMLIdent($1),getExps($2),getRMLPatternopt($3),yyinfo)); } 
                                 
                 |rml_ident EQ rml_expression
		            { $$ = RMLGOAL(Absynrml.RMLGOAL_EQUAL(getRMLIdent($1),getExp($3),yyinfo)); } 
   
			     |KW_LET pat EQ rml_expression                  
                    { $$ = RMLGOAL(Absynrml.RMLGOAL_LET(getRMLPattern($2),getExp($4),yyinfo)); }
	   
      			 |KW_NOT atomic_goal    
		           { $$ = RMLGOAL(Absynrml.RMLGOAL_NOT(getRMLGoal($2),yyinfo)); }      					 
                            
	             |LPAR conjunctive_goal RPAR
		           { $$ = RMLGOAL(getRMLGoal($2)); } 
			           

rml_addsub    :  rml_muldiv ADD_REAL rml_addsub res_pat  
                   { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }

                 |rml_muldiv SUB_REAL rml_addsub res_pat   
                   { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }
  
			     |rml_muldiv ADD_INT rml_addsub res_pat
                   { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }
						
				 |rml_muldiv SUB_INT rml_addsub res_pat
                   { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }
                 
                 |rml_muldiv
		           { $$ = RMLGOAL(getRMLGoal($1)); }


rml_muldiv    : rml_unary MUL_REAL rml_muldiv res_pat
                   { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }
                        		
                |rml_unary DIV_REAL rml_muldiv res_pat
                   { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }
 						 				   
                |rml_unary STAR rml_muldiv res_pat
                   { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }
							
                |rml_unary DIV_INT rml_muldiv res_pat
                   { $$ = RMLGOAL(Absynrml.RMLGOAL_RELATION(Absynrml.RMLSHORTID(getString($2)),{},getRMLPatternopt($4),yyinfo)); }

           		|rml_unary 
		          { $$ = EXP(getExp($1)); } 		
				 
				
rml_unary    :  SUB_INT rml_unary
		          { $$ = EXP(Absynrml.RMLUNARY(Absyn.UMINUS(),getExp($2))); }    
 			  
	            |rml_primary
		          { $$ = EXP(getExp($1)); } 
                            
 
pat         :   rml_ident KW_AS pat     
                  { $$ = RMLPATTERN(Absynrml.RMLPAT_AS(getRMLIdent($1),getRMLPattern($3))); } 
                
                |pat_a
		          { $$ = RMLPATTERN(getRMLPattern($1)); } 
		     
	
pat_a       :  pat_b COLONCOLON pat_a      
                 { $$ = RMLPATTERN(Absynrml.RMLPAT_CONS(getRMLPattern($1),getRMLPattern($3))); } 
	         
	          |pat_b
	             { $$ = RMLPATTERN(getRMLPattern($1)); }


pat_b       :  LPAR RPAR     
                { $$ = RMLPATTERN(Absynrml.RMLPAT_NIL()); } 
	        
	          |LPAR pat RPAR
		        { $$ = RMLPATTERN(getRMLPattern($2)); } 
			    
    	      |LPAR pat COMMA pat_comma_plus RPAR
		        { $$ = RMLPATTERN(Absynrml.RMLPAT_STRUCT(NONE(),getRMLPattern($2)::getRMLPatterns($4))); } 
			   
	          |pat_d
		        { $$ = RMLPATTERN(getRMLPattern($1)); } 
			    

pat_c       :  pat_d COLONCOLON pat_c
		        { $$ = RMLPATTERN(Absynrml.RMLPAT_CONS(getRMLPattern($1),getRMLPattern($3))); }
		    
	          |pat_d
		        { $$ = RMLPATTERN(getRMLPattern($1)); }
	
pat_d      :  longorshortid pat_star    
		        { $$ = RMLPATTERN(Absynrml.RMLPAT_STRUCT(SOME(getRMLIdent($1)),getRMLPatterns($2))); }  
		      
	         |longorshortid pat_e
		        { $$ = RMLPATTERN(Absynrml.RMLPAT_STRUCT(SOME(getRMLIdent($1)),getRMLPattern($2)::{})); }    
			     
	         |pat_e
	             { $$ = RMLPATTERN(getRMLPattern($1)); }
                  

pat_e      :  WILD
	           { $$ = RMLPATTERN(Absynrml.RMLPAT_WILDCARD()); }
	
	         |rml_literal  
		       { $$ = RMLPATTERN(Absynrml.RMLPAT_LITERAL(getRMLLiteral($1))); } 
			   
	         |longid
		       { $$ = RMLPATTERN(Absynrml.RMLPAT_IDENT(getRMLIdent($1))); } 
 
			 |rml_ident
		       { $$ = RMLPATTERN(Absynrml.RMLPAT_IDENT(getRMLIdent($1))); }   
			     
	         |LBRACK pat_comma_star RBRACK     
               { $$ = RMLPATTERN(Absynrml.RMLPAT_LIST(getRMLPatterns($2))); }     
				

res_pat    :  FATARROW seq_pat     
               { $$ = RMLPATTERNOPT(SOME(getRMLPattern($2))); }
	         
	          |/*empty */
		       { $$ = RMLPATTERNOPT(NONE()); }
                  
  	
seq_pat    :  pat_c           
               { $$ = RMLPATTERN(getRMLPattern($1)); } 
			   
	         |pat_star                
               { $$ = RMLPATTERN(Absynrml.RMLPAT_STRUCT(NONE(),getRMLPatterns($1))); } 	 
	             
             |/* empty */
               { $$ = RMLPATTERN(Absynrml.RMLPAT_STRUCT(NONE(),{})); } 	               
                  
 
pat_star   :  LPAR pat_comma_star RPAR
		        { $$ = RMLPATTERNS(getRMLPatterns($2)); } 
			   

pat_comma_star :  pat_comma_plus
		        { $$ = RMLPATTERNS(getRMLPatterns($1)); } 
			              
				  |/* empty */
	    	        { $$ = RMLPATTERNS({}); }
	           			
	
pat_comma_plus  : pat COMMA pat_comma_plus
		            { $$ = RMLPATTERNS(getRMLPattern($1)::getRMLPatterns($3)); }     
					
	              |pat
		            { $$ = RMLPATTERNS(getRMLPattern($1)::{}); } 
				   
  
rml_literal     : ICON
                   { $$ = RMLLITERAL(Absynrml.RMLLIT_INTEGER(stringInt(getString($1)))); } 
                   
                  |RCON
                   { $$ = RMLLITERAL(Absynrml.RMLLIT_REAL(stringReal(getString($1)))); }

                  |SCON
                   { $$ = RMLLITERAL(Absynrml.RMLLIT_STRING(getString($1))); }			 
		         
		          |SUB_INT ICON
		           { $$ = RMLLITERAL(Absynrml.RMLLIT_INTEGER(intNeg(stringInt(getString($2))))); } 
                    
		          |SUB_INT RCON
		           { $$ = RMLLITERAL(Absynrml.RMLLIT_REAL(realNeg(stringReal(getString($2))))); }
	                

rml_expression   : rml_exp_a COLONCOLON rml_expression       
                     { $$ = EXP(Absynrml.RMLCONS(getExp($1),getExp($3))); } 		    
                           
	               |rml_exp_a                              
                     { $$ = EXP(getExp($1)); } 
		 	         

rml_expression_list : rml_expression COMMA rml_expression_list  
                        { $$ = EXPS(getExp($1)::getExps($3)); } 		   
			                  
                      |rml_expression
		                { $$ = EXPS(getExp($1)::{}); } 
				          

		 	          
rml_exp_a      :  LPAR RPAR           
                    { $$ = EXP(Absynrml.RMLEXP_NIL()); }   
			    
		         |LPAR rml_expression RPAR   
			        { $$ = EXP(getExp($2)); } 
				   
	             |LPAR rml_expression_list RPAR 
                    { $$ = EXP(Absynrml.RMLTUPLE(getExps($2))); }
	        	     
	             |rml_exp_c     
			        { $$ = EXP(getExp($1)); }   
				  

rml_exp_b       : rml_exp_c COLONCOLON rml_exp_b
		           { $$ = EXP(Absynrml.RMLCONS(getExp($1),getExp($3))); } 	      
		         
	             |rml_exp_c
			        { $$ = EXP(getExp($1)); }   
				 
			
rml_exp_c        : longorshortid rml_exp_star   
		             { $$ = EXP(Absynrml.RMLCALL(getRMLIdent($1),getExps($2))); }   
				  
	               |longorshortid rml_exp_c 
		             { $$ = EXP(Absynrml.RMLCALL(getRMLIdent($1),getExp($2)::{})); }   
				  
                   |rml_primary
			         { $$ = EXP(getExp($1)); }   
		           
		            
rml_primary      : rml_literal   		     
                     { $$ = EXP(Absynrml.RMLLIT(getRMLLiteral($1))); }   
				 
	               |rml_ident
		             { $$ = EXP(Absynrml.RML_REFERENCE(getRMLIdent($1))); } 
	                 
	               |longorshortid
	                 { $$ = EXP(Absynrml.RML_REFERENCE(getRMLIdent($1))); } 
	                 
	               |LBRACK rml_exp_comma_star RBRACK  
			         { $$ = EXP(Absynrml.RMLLIST(getExps($2))); } 
                                
                   |LPAR rml_expression RPAR
			         { $$ = EXP(getExp($2)); }   
				 
					 	

rml_exp_comma_star  : rml_exp_comma_plus
		                { $$ = EXPS(getExps($1)); } 
				      
				      |/*empty */
		                { $$ = EXPS({}); }
                                

rml_exp_comma_plus  : rml_expression COMMA rml_exp_comma_plus
	     	            { $$ = EXPS(getExp($1)::getExps($3)); } 	     
				          
                      |rml_expression
		                { $$ = EXPS(getExp($1)::{}); }  
					  
	

rml_exp_star       : LPAR rml_exp_comma_star RPAR
		                { $$ = EXPS(getExps($2)); }   
				     
              
seq_exp            : LPAR RPAR
	                    { $$ = EXPS({}); } 
		 
	                |rml_exp_b    
		                { $$ = EXPS(getExp($1)::{}); } 
			
		            |rml_exp_star
		                { $$ = EXPS(getExps($1)); }   
			  
			        |/*empty*/
                        { $$ = EXPS({}); }
                   
              
typbind_plus   : typbind
		          { $$ = RMLINTERFACE(getRMLInterface($1)); }	 
			     

typbind        : rml_ident EQ ty    
                  { $$ = RMLINTERFACE(Absynrml.TYPE(getRMLIdent($1),getRMLType($3),yyinfo)); }
			   

datbind_plus   : datbind
                  { $$ = RMLDATATYPE(getRMLDatatype($1)); }              
				   
				
datbind	       : rml_ident EQ conbind_plus  
			       { $$ = RMLDATATYPE(Absynrml.DATATYPE(getRMLIdent($1),getDTMembers($3))); }
			    
			    |rml_ident EQ conbind 
		           { $$ = RMLDATATYPE(Absynrml.DATATYPE(getRMLIdent($1),getDTMember($3)::{})); }
		        
		          
		    
conbind_plus   : conbind BAR conbind_plus
                   { $$ = DTMEMBERS(getDTMember($1)::getDTMembers($3)); }
                     
	            |conbind
	               { $$ = DTMEMBERS(getDTMember($1)::{}); }
	                       

conbind       : rml_ident
                  { $$ = DTMEMBER(Absynrml.DTCONS(getRMLIdent($1),{},yyinfo)); }

	           |rml_ident KW_OF ty_sans_star
	              { $$ = DTMEMBER(Absynrml.DTCONS(getRMLIdent($1),getRMLType($3)::{},yyinfo)); } 
	         
	           |rml_ident KW_OF tuple_ty
		          { $$ = DTMEMBER(Absynrml.DTCONS(getRMLIdent($1),getRMLTypes($3),yyinfo)); } 
	               				   
				
datbind_def	  : rml_ident EQ conbind_plus 
			      { $$ = RMLDATATYPE(Absynrml.DATATYPE(getRMLIdent($1),getDTMembers($3))); }
			            


ty :           seq_ty FATARROW seq_ty     
                  { $$ = RMLTYPE(Absynrml.RMLTYPE_SIGNATURE(Absynrml.CALLSIGN(getRMLTypes($1),getRMLTypes($3)))); } 
                
               |ty_sans_star
                  { $$ = RMLTYPE(getRMLType($1)); } 
	      
               |tuple_ty
	              { $$ = RMLTYPE(Absynrml.RMLTYPE_TUPLE(getRMLTypes($1))); }
           

tuple_ty      : ty_sans_star STAR tuple_ty    
		          { $$ = RMLTYPES(getRMLType($1)::getRMLTypes($3)); } 

			   |ty_sans_star                  
		          { $$ = RMLTYPES(getRMLType($1)::{}); }     	
				
				
ty_sans_star   : ty_sans_star longorshortid
	               { $$ = RMLTYPE(Absynrml.RMLTYPE_TYCONS(getRMLType($1)::{},getRMLIdent($2))); }
                          
	             |LPAR ty RPAR
                   { $$ = RMLTYPE(getRMLType($2)); }  
			         
			     |LPAR ty_comma_seq2 RPAR longorshortid
                   { $$ = RMLTYPE(Absynrml.RMLTYPE_TYCONS(getRMLTypes($2),getRMLIdent($4))); }
                      
			     |tyvar
		           { $$ = RMLTYPE(getRMLType($1)); } 
				     
	             |longorshortid
		           { $$ = RMLTYPE(Absynrml.RMLTYPE_USERDEFINED(getRMLIdent($1))); }


ty_comma_seq2  : ty COMMA ty_comma_seq2  
                    { $$ = RMLTYPES(getRMLType($1)::getRMLTypes($3)); }
	            
	             |ty COMMA ty         
		            { $$ = RMLTYPES(getRMLType($1)::getRMLType($3)::{}); } 
		               
	
seq_ty          : LPAR ty_comma_seq2 RPAR
		             { $$ = RMLTYPES(getRMLTypes($2)); }
	                           
	             |tuple_ty 
		             { $$ = RMLTYPES(getRMLTypes($1)); }
				                                        
                 |LPAR RPAR
                     { $$ = RMLTYPES({}); } 
                       
                     	 
		   
longid      : ident DOT ident   
                { $$ = RMLIDENT(Absynrml.RMLLONGID(getString($1),getString($3))); } 
               

longorshortid  : longid
		           { $$ = RMLIDENT(getRMLIdent($1)); } 
                      
		         |rml_ident
		           { $$ = RMLIDENT(getRMLIdent($1)); } 
                           
						   
ident     : IDENT
	         { $$ = STRING(getString($1)); }
	              
	
rml_ident : ident
             { $$ = RMLIDENT(Absynrml.RMLSHORTID(getString($1))); }
                   
				 
tyvar     : TYVAR   
	         { $$ = RMLTYPE(Absynrml.RMLTYPE_TYVAR(Absynrml.RMLSHORTID(getString($1)))); }
	      
	      	    
%%


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

