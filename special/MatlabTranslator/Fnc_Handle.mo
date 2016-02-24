encapsulated package Fnc_Handle

import Absyn;
import AbsynMat;
import System;
import Mat_Builtin;
import Mod_Builtin;
import Translate;

public function transform_in_put
input String in_put;
output list<Absyn.ElementItem> eli_lst;
algorithm
eli_lst := matchcontinue(in_put)
  local
    String in_put1;
    list<Absyn.ElementItem> eli_lst1;
      Absyn.Info info;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec tSpec;
      list<Absyn.ElementItem> eli;
      list<Absyn.ComponentItem> com; 
    case(in_put1)
      equation
            
        attr = Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.VAR(), Absyn.INPUT(),Absyn.NONFIELD(),{});
        tSpec = Absyn.TPATH(Absyn.IDENT("Real"),NONE());
        com = Absyn.COMPONENTITEM(Absyn.COMPONENT(in_put1,{},NONE()),NONE(),NONE())::{};
        info=SOURCEINFO("",false,0,0,0,0,0.0);        
        eli_lst1 = Absyn.ELEMENTITEM((Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),Absyn.COMPONENTS(attr,tSpec,com),info,NONE())))::{};
        
    then eli_lst1; 
  end matchcontinue; 
end transform_in_put;

public function transform_in_put_lst
input list<String> in_lst;
output list<Absyn.ElementItem> eli_lst;
algorithm
  eli_lst := matchcontinue(in_lst)
  local
    list<String> in_lst1;
    String in_put;
    list<Absyn.ElementItem> eli_lst1, eli_lst2, eli_lst3;
    case(in_put::in_lst1)
      equation
      eli_lst1 = transform_in_put(in_put);
      eli_lst2 = transform_in_put_lst(in_lst1);
      eli_lst3 = listAppend(eli_lst1,eli_lst2);
      
      then eli_lst3;
    case({})
      then {};
   end matchcontinue; 
end transform_in_put_lst;

public function rmvKeywords
input String in_put;
output list<String> out_put;
algorithm
  out_put := matchcontinue(in_put)
  local
    list<String> in_put1;
    String in_string;
    case("Integer")
    then {};
    case("Real")
    then {};
    case(in_string)
      equation
        in_put1 = in_string::{};
    then in_put1;   
  end matchcontinue;
end rmvKeywords;

public function rmvKeywords_lst
input list<String> in_lst;
output list<String> out_lst;
algorithm
  out_lst := matchcontinue(in_lst)
  local
    list<String> in_lst1, in_lst2, in_lst3, in_put1;
    String in_put;
    case(in_put::in_lst1)
      equation
        in_put1 = rmvKeywords(in_put);
        in_lst2 = rmvKeywords_lst(in_lst1);
        in_lst3 = listAppend(in_put1,in_lst2);
        then in_lst3;
    case({})
    then {};
  end matchcontinue;
end rmvKeywords_lst;

public function fnc_hdl_to_sub_fnc
input AbsynMat.Expression exp_lst;
output list<Absyn.Class> mod_class;
output list<String> f_call;
output list<String> fnc_hdl_ident;
algorithm
  (mod_class,f_call,fnc_hdl_ident) := matchcontinue(exp_lst)
    local
      AbsynMat.Expression exp1;
      Absyn.Exp mod_exp1,mod_exp2;      
      list<AbsynMat.Argument> arg_lst;
      AbsynMat.Operator op;
      String fname, out_put;
      list<String> ary1, in_ident, f_call1, in_ident1, fnc_hdl_ident1, fnc_hdl_ident2;
      Absyn.ClassDef cd;
      list<Absyn.ClassPart> cp;
      Absyn.ClassPart cls_stmt, in_cp;
      list<Absyn.Class> class1;
      Absyn.Info info;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec tSpec;
      list<Absyn.ElementItem> eli_out_lst, eli_in_lst, eli_in_out;
      list<Absyn.ComponentItem> com;    
      list<Absyn.AlgorithmItem> alg_exp;
    case (AbsynMat.ASSIGN_OP(arg_lst,op,exp1))
      equation
        ({mod_exp1},{fname}) = Translate.argument_lst(arg_lst,false);
        (mod_exp2,ary1) =  Translate.expression(exp1,{},{}); 
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        alg_exp = Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(mod_exp1,mod_exp2),NONE(),info)::{};  
        in_ident = Translate.rmvDuplicate(ary1);  
        in_ident1 = rmvKeywords_lst(in_ident);
        
        eli_in_lst = transform_in_put_lst(in_ident1);      
        
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        attr = Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.VAR(), Absyn.OUTPUT(),Absyn.NONFIELD(),{});
        tSpec = Absyn.TPATH(Absyn.IDENT("Real"),NONE());
        com = Absyn.COMPONENTITEM(Absyn.COMPONENT(fname,{},NONE()),NONE(),NONE())::{};
        
        eli_out_lst = Absyn.ELEMENTITEM((Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),Absyn.COMPONENTS(attr,tSpec,com),info,NONE())))::{};
        
        eli_in_out = listAppend(eli_in_lst,eli_out_lst);  
        in_cp = Absyn.PUBLIC(eli_in_out);
        cls_stmt = Absyn.ALGORITHMS(alg_exp);      
        cp = listAppend(in_cp::{},cls_stmt::{});      
        cd = Absyn.PARTS({},{},cp,{},NONE());                
        class1 = Absyn.CLASS(fname,false,false,false,Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.NO_PURITY())),cd,info)::{};    
        fnc_hdl_ident2 = listAppend(fname::{},in_ident1);
      then (class1,{fname},fnc_hdl_ident2); 
    end matchcontinue;  
end fnc_hdl_to_sub_fnc;

public function fnc_hdl_to_sub_fnc_lst
  input list<AbsynMat.Expression> exp_lst;
  output list<Absyn.Class> mod_class;
  output list<String> f_call;
  output list<String> fnc_hdl_ident;
algorithm    
  (mod_class,f_call,fnc_hdl_ident) := matchcontinue(exp_lst)
    local
    list<AbsynMat.Expression> exp_lst1;
    AbsynMat.Expression exp;
    list<Absyn.Class> mod_class1, mod_class2, mod_class3;
    list<String> f_call1, f_call2, f_call3, fnc_hdl_ident1, fnc_hdl_ident2, fnc_hdl_ident3;
    case(exp::exp_lst1)
    equation
      (mod_class1,f_call1,fnc_hdl_ident1) = fnc_hdl_to_sub_fnc(exp);
      (mod_class2,f_call2,fnc_hdl_ident2) = fnc_hdl_to_sub_fnc_lst(exp_lst1);
      f_call3 = listAppend(f_call1,f_call2);
      mod_class3 = listAppend(mod_class1,mod_class2);
      fnc_hdl_ident3 = listAppend(fnc_hdl_ident1,fnc_hdl_ident2);
    then
      (mod_class3,f_call3,fnc_hdl_ident3);
    case({})
      then ({},{},{});
  end matchcontinue;
end fnc_hdl_to_sub_fnc_lst;

public function anon_fcn_handle
input AbsynMat.Expression exp;
output Boolean tf;
algorithm
  tf := matchcontinue(exp)
  local
    AbsynMat.Expression exp1;
    list<AbsynMat.Parameter> prm_lst;
    AbsynMat.Statement stmt;
    case(AbsynMat.ANON_FCN_HANDLE(prm_lst,stmt))
      then true;
    case(exp1)
      then false;
  end matchcontinue;   
end anon_fcn_handle;

public function stmt_fnc_handle
  input Boolean fnc_hdl_tf;
  input Option<AbsynMat.Expression> exp;
  output list<AbsynMat.Expression> exp1_o; 
algorithm
  (exp1_o) := matchcontinue (fnc_hdl_tf,exp)
  local
  list<AbsynMat.Expression> exp2;
  Option<AbsynMat.Expression> exp1;
  AbsynMat.Expression exp3;
  case(true,exp1)
    equation
      SOME(exp3) = exp1;
      exp2 = exp3::{};
  then (exp2);
  case(false,exp1)
  then ({});
  case(false,NONE())
  then ({});
  end matchcontinue;
end stmt_fnc_handle;

public function in_var
  input String in_ident;
  input Boolean tf1;
  output list<String> in_idt;
  output Option<AbsynMat.Expression> exp_out;
algorithm
  (in_idt,exp_out) := matchcontinue(in_ident,tf1)
    local
      String in_ident1, in_ident2;
      Option<AbsynMat.Expression> exp;
      AbsynMat.Expression exp1;
      list<AbsynMat.Argument> arg1;
      AbsynMat.Operator op; 
     case(in_ident1,true)   
      equation
        in_ident2 = in_ident1 + "trans";
        arg1 = {AbsynMat.ARGUMENT(AbsynMat.FINISH_COLON_EXP({AbsynMat.IDENTIFIER(in_ident2)}))};
        op = AbsynMat.EQ();
        exp1 = AbsynMat.FINISH_COLON_EXP({AbsynMat.IDENTIFIER(in_ident1)});
        exp =  SOME(AbsynMat.ASSIGN_OP(arg1,op,exp1));    //here we add new for loop statment e.g. jtrans = j;    
      then ({in_ident1},exp);
    case(in_ident1,false)
      equation
      then ({},NONE());          
  end matchcontinue;
end in_var;

public function in_add
  input list<String> ary;
  input Option<String> in_ident;
  output list<String> in_idt;
  output Option<AbsynMat.Expression> exp;
algorithm    
  (in_idt,exp) := matchcontinue(ary,in_ident)
    local
      list<String> ary1, in_idt1;
      Option<String> in_ident1;
      String in_ident2;
      Boolean tf1;
      Option<AbsynMat.Expression> exp1;      
    case(ary1,in_ident1)
      equation
        SOME(in_ident2) = in_ident1; 
        tf1 = listMember(in_ident2, ary1);
        (in_idt1,exp1) = in_var(in_ident2,tf1);
      then (in_idt1,exp1); 
    case(ary1,NONE())
    then ({},NONE());   
  end matchcontinue;
end in_add;

public function in_left_var
  input Option<String> in_ident;
  input list<String> ident;
  input Boolean tf1;
  output list<AbsynMat.Argument> arg;
algorithm
  (arg) := matchcontinue(in_ident,ident,tf1)
    local
      Option<String> in_ident1;
      String in_ident2, in_ident3, ident3;
      list<String> ident2;
      Option<AbsynMat.Expression> exp;
      AbsynMat.Expression exp1;
      list<AbsynMat.Argument> arg1;
      AbsynMat.Operator op; 
    case(in_ident1,ident2,true)   
      equation
        SOME(in_ident2) = in_ident1;
        in_ident3 = in_ident2 + "trans";        
        arg1 = {AbsynMat.ARGUMENT(AbsynMat.FINISH_COLON_EXP({AbsynMat.IDENTIFIER(in_ident3)}))};
      then (arg1);
    case(in_ident1,ident2,false)
      equation
        {ident3} = ident2;
        arg1 = {AbsynMat.ARGUMENT(AbsynMat.FINISH_COLON_EXP({AbsynMat.IDENTIFIER(ident3)}))};
      then (arg1);
  end matchcontinue;
end in_left_var;

public function in_left
  input list<String> ary;
  input Option<String> in_ident;
  output list<AbsynMat.Argument> arg;
algorithm    
  (arg) := matchcontinue(ary,in_ident)
    local
      list<String> ary1;
      Option<String> in_ident1;
      String in_ident2;
      Boolean tf1;
      list<AbsynMat.Argument> arg1;
    case(ary1,in_ident1)
      equation
       
        SOME(in_ident2) = in_ident1; 
        tf1 = listMember(in_ident2, ary1);
       (arg1) = in_left_var(in_ident1,ary1,tf1);
      then (arg1); 
    case(ary1,NONE())
    then ({});
  end matchcontinue;
end in_left;

public function var_append
input String ident;
input Boolean tf;
output AbsynMat.Expression exp_o;
algorithm
  exp_o := matchcontinue(ident,tf)
  local
    String ident1;
    case(ident1,true)
      equation
         then AbsynMat.IDENTIFIER(ident1+"trans");
    case(ident1,false)
      equation
       then AbsynMat.IDENTIFIER(ident1);
    end matchcontinue;
end var_append;

public function var_rpl
input Option<String> ident;
input AbsynMat.Expression exp;
output AbsynMat.Expression exp_o;
algorithm
  exp_o := matchcontinue(ident,exp)
  local
      Boolean tf;
      Integer i;
      Real r;
      String idt;
      Option<String> ident1;
      AbsynMat.Ident ident2;
      AbsynMat.Expression exp1,exp2, exp_o1, exp_o2;
      list<AbsynMat.Expression> exp_lst, exp_lst2, exp_lst3;
      AbsynMat.Operator op;
    case (ident1, AbsynMat.INT(i))          
    then AbsynMat.INT(i);
    case (ident1, AbsynMat.NUM(r))          
    then AbsynMat.NUM(r);
    case (ident1, AbsynMat.IDENTIFIER(ident2))     
      equation
        SOME(idt) = ident1;
        tf = stringEqual(idt,ident2);    
        exp1 = var_append(ident2,tf); 
    then exp1;
    case (ident1, AbsynMat.BINARY_EXPRESSION(exp1,exp2,op))          
      equation
         
        exp_o1 = var_rpl(ident1,exp1);
        exp_o2 = var_rpl(ident1,exp2);          
      then AbsynMat.BINARY_EXPRESSION(exp_o1,exp_o2,op);              
  end matchcontinue;    
end var_rpl;

public function var_rpl_lst
  input Option<String> in_ident;
  input list<AbsynMat.Expression> iexp_lst;
  output list<AbsynMat.Expression> oexp_lst;
algorithm 
  oexp_lst := matchcontinue(in_ident,iexp_lst)
    local
      Option<String> in_ident1;
      AbsynMat.Expression exp1,exp2;
      list<AbsynMat.Expression> exp_lst, exp_lst2, exp_lst3;    
      case(in_ident1, exp1::exp_lst)
        equation
          exp2 = var_rpl(in_ident1,exp1);
          exp_lst2 = var_rpl_lst(in_ident1,exp_lst);
          exp_lst3 = listAppend({exp2},exp_lst2);
        then exp_lst3;
      case(in_ident1,{})
      then {};    
      case(NONE(),{})
      then {};
  end matchcontinue;    
end var_rpl_lst;

public function in_right_var
  input Option<String> in_ident;
  input Boolean tf;
  input AbsynMat.Expression exp;
  output AbsynMat.Expression exp_o;
algorithm
  (exp_o) := matchcontinue(in_ident,tf,exp)
    local
      Option<String> in_ident1;
      AbsynMat.Expression exp1, exp2;
      list<AbsynMat.Expression> exp_lst, exp_lst2;
    case (in_ident1,true,AbsynMat.FINISH_COLON_EXP(exp_lst))
      equation
        exp_lst2 = var_rpl_lst(in_ident1,exp_lst);
      then AbsynMat.FINISH_COLON_EXP(exp_lst2);        
  end matchcontinue;
end in_right_var; 

public function in_right
  input list<String> ary;
  input Option<String> in_ident;
  input AbsynMat.Expression exp;
  output AbsynMat.Expression exp_o;
algorithm
  (exp_o) := matchcontinue(ary,in_ident,exp)
    local
      list<String> ary1, in_idt1;
      Option<String> in_ident1;
      String ident;
      AbsynMat.Expression exp1,exp2;    
      Boolean tf;
    case(ary1,in_ident1,exp1)
      equation
        SOME(ident) = in_ident1;
        tf = listMember(ident, ary1);
        (exp2) = in_right_var(in_ident1,tf,exp1); 
      then exp2;        
  end matchcontinue;    
end in_right;

public function prf_rpl
input list<String> arg_ident;
input Option<String> in_ident;
input list<AbsynMat.Argument> arg;
input AbsynMat.Operator op;
input AbsynMat.Expression exp;
input Boolean bool_i;
input Boolean in_tf;
output Option<AbsynMat.Expression> exp_out;
output Option<AbsynMat.Expression> exp_out2;  
output Boolean bool_o;
algorithm
(exp_out,exp_out2,bool_o) := matchcontinue(arg_ident,in_ident,arg,op,exp,bool_i,in_tf)  
local
     Option<String> in_ident1;
     list<String> ary1, in_idt1, in_idt2, arg_ident1, arg_ident2;
     String in_ident2, arg_ident3;
     list<AbsynMat.Argument> arg1;
     Boolean tf1, in_tf1, ryt_tf;
     AbsynMat.Expression exp1, exp2;
     list<AbsynMat.Argument> arg1;
     AbsynMat.Operator op1; 
     Absyn.Exp exp3, exp4;
     Option<AbsynMat.Expression> exp_out1, exp_out3;
     list<AbsynMat.Argument> arg1;
     AbsynMat.Operator op1;
  case(arg_ident1,in_ident1,arg1,op1,exp1,true,true)
    equation
       (in_idt1,exp_out1) =  in_add(arg_ident1,in_ident1);  // check for loop variable wheather its available at LHS e.g. j = 2 * j then generate new statement j1 = j;;
       (exp4,ary1) =  Translate.expression(exp1,{},{});
       (arg1) =  in_left(arg_ident1,in_ident1);
       (exp2) =  in_right(ary1,in_ident1,exp1);
       exp_out3 = SOME(AbsynMat.ASSIGN_OP(arg1,op1,exp2)); 
     then 
       (exp_out1,exp_out3,true);  
  case(arg_ident1,in_ident1,arg1,op1,exp1,true,false)
    equation
       (in_idt1,exp_out1) =  in_add(arg_ident1,in_ident1);  // check for loop variable wheather its available at LHS e.g. j = 2 * j then generate new statement j1 = j;;
       (exp4,ary1) =  Translate.expression(exp1,{},{});
       (arg1) =  in_left(arg_ident1,in_ident1);
       (exp2) =  in_right(ary1,in_ident1,exp1);
       exp_out3 = SOME(AbsynMat.ASSIGN_OP(arg1,op1,exp2)); 
     then 
       (exp_out1,exp_out3,true);       
  case(arg_ident1,in_ident1,arg1,op1,exp1,false,true)
    equation
       (in_idt1,exp_out1) =  in_add(arg_ident1,in_ident1);  // check for loop variable wheather its available at LHS e.g. j = 2 * j then generate new statement j1 = j;;
       (exp4,ary1) =  Translate.expression(exp1,{},{});
       (arg1) =  in_left(arg_ident1,in_ident1);
       (exp2) =  in_right(ary1,in_ident1,exp1);
       exp_out3 = SOME(AbsynMat.ASSIGN_OP(arg1,op1,exp2)); 
     then (exp_out1,exp_out3,false);  
       case(arg_ident1,in_ident1,arg1,op1,exp1,false,false)
    equation
       exp_out3 = SOME(AbsynMat.ASSIGN_OP(arg1,op1,exp1)); 
     then (NONE(),exp_out3,false);  
  end matchcontinue;
end prf_rpl;

public function assign_operator_fhdl
  input Option<AbsynMat.Expression> exp;
  output Boolean fnc_hdl; 
algorithm 
  (fnc_hdl) := matchcontinue(exp)
    local
      Boolean fnc_hdl_tf;      
      AbsynMat.Expression exp1;
      Option<AbsynMat.Expression> exp2;
      list<AbsynMat.Argument> arg1;
      AbsynMat.Operator op;   
      AbsynMat.Ident ident;
    case(SOME(AbsynMat.ASSIGN_OP(arg1,op,exp1)))
      equation
        fnc_hdl_tf = anon_fcn_handle(exp1); // determine whether matlab expression is anonymous function or not
      then
        (fnc_hdl_tf);           
     case(NONE())
     then (false);
  end matchcontinue;
end assign_operator_fhdl;

public function assign_operator
  input Option<AbsynMat.Expression> exp;
  input Option<String> in_ident;
  input Boolean bool_i;
  output Option<AbsynMat.Expression> exp_out;
  output Option<AbsynMat.Expression> exp_out2;  
  output Boolean bool_o;
algorithm
  (exp_out,exp_out2,bool_o) := matchcontinue (exp,in_ident,bool_i)
   local
     Option<String> in_ident1;
     list<String> ary1, in_idt1, in_idt2, arg_ident, arg_ident2;
     String in_ident2, arg_ident3;
     Boolean tf1, in_tf1, ryt_tf, bool_loop1;
     AbsynMat.Expression exp1, exp2;
     list<AbsynMat.Argument> arg1;
     AbsynMat.Operator op; 
     Absyn.Exp exp3, exp4;
     Option<AbsynMat.Expression> exp_out1, exp_out3;
     list<AbsynMat.Argument> arg1;
   case(SOME(AbsynMat.ASSIGN_OP(arg1,op,exp1)),in_ident1,in_tf1)
     equation
       ({exp3},arg_ident) = Translate.argument_lst(arg1,false); 
       SOME(in_ident2) = in_ident1;
       {arg_ident3} = arg_ident;
       ryt_tf = stringEqual(in_ident2,arg_ident3);
       (exp_out1,exp_out3,bool_loop1) = prf_rpl(arg_ident,in_ident1,arg1,op,exp1,ryt_tf,in_tf1);          
     then (exp_out1,exp_out3,bool_loop1);  
   case(SOME(AbsynMat.ASSIGN_OP(arg1,op,exp1)),NONE(),false)
   then (NONE(),NONE(),false);
   case(NONE(),in_ident1,false)
   then (NONE(),NONE(),false);
   case(NONE(),NONE(),false)
   then (NONE(),NONE(),false);
  end matchcontinue;
end assign_operator;

public function stmt
  input AbsynMat.Statement stmt;
  input Option<String> in_ident;
  input Boolean bool_i;
  output list<AbsynMat.Expression> exp_lst;
  output list<AbsynMat.Statement> stmt_out;
  output Boolean bool_o;
algorithm
  (exp_lst,stmt_out,bool_o) := matchcontinue(stmt,in_ident,bool_i)
    local
      Option<AbsynMat.Expression> exp, exp_out1, exp_out2;
      list<AbsynMat.Expression> exp2;
      Boolean fnc_hdl_tf, tf1, bool_loop, bool_loop1;
      AbsynMat.Separator sep;
      Option<AbsynMat.Mat_Comment> m_cmt;
      Option<AbsynMat.Command> cmd;
      Option<AbsynMat.Start> fnc_str;
      Option<String> in_ident1;
      list<String> in_idt1;
      list<AbsynMat.Statement> stmt_out1, stmt_out2, stmt_out3;
    case(AbsynMat.STATEMENT_APPEND(AbsynMat.STATEMENT(cmd,exp,fnc_str,m_cmt),sep),in_ident1,bool_loop)
      equation
        fnc_hdl_tf = assign_operator_fhdl(exp);
        (exp2) = stmt_fnc_handle(fnc_hdl_tf,exp);
        (exp_out1,exp_out2,bool_loop1) = assign_operator(exp,in_ident1,bool_loop);         
        stmt_out1 = AbsynMat.STATEMENT_APPEND(AbsynMat.STATEMENT(NONE(),exp_out1,NONE(),NONE()),AbsynMat.SEMI_COLON())::{};
        stmt_out2 = AbsynMat.STATEMENT_APPEND(AbsynMat.STATEMENT(NONE(),exp_out2,NONE(),NONE()),AbsynMat.SEMI_COLON())::{};
        stmt_out3 = listAppend(stmt_out1,stmt_out2);              
      then  
        (exp2,stmt_out3,bool_loop1);           
  end matchcontinue;
end stmt;

public function stmt_lst
  input list<AbsynMat.Statement> stmtlst;
  input Option<String> in_ident;
  input Boolean bool_i;
  output list<AbsynMat.Expression> exp_lst;
  output list<AbsynMat.Statement> stmtlst_out;  
  output Boolean bool_o;
algorithm
  (exp_lst,stmtlst_out,bool_o) := matchcontinue(stmtlst, in_ident, bool_i)
    local
    list<AbsynMat.Statement> stmt_out1, stmt_out2, stmtlst1, stmtlst_out1;
    AbsynMat.Statement stmt1;
    Boolean fnc_hdl_tf, fnc_hdl_tf1, bool_loop, bool_loop1, bool_loop2;
    list<AbsynMat.Expression> exp_lst1, exp_lst2, exp_lst3;
    Option<String> in_ident1;
    Option<AbsynMat.Expression> exp_out1;
    case(stmt1::stmtlst1, in_ident1, bool_loop)
      equation
        (exp_lst1,stmt_out1,bool_loop1) = stmt(stmt1,in_ident1,bool_loop);
        (exp_lst2,stmt_out2,bool_loop2)  = stmt_lst(stmtlst1, in_ident1, bool_loop1);
        exp_lst3 = listAppend(exp_lst1,exp_lst2);   
        stmtlst_out1 = listAppend(stmt_out1,stmt_out2); 
      then  
        (exp_lst3,stmtlst_out1,bool_loop2);   
    case({},in_ident1,bool_loop)
    then ({},{},bool_loop);  
    case({},NONE(),bool_loop)
    then ({},{},bool_loop);        
  end matchcontinue;
end stmt_lst;

public function user_function
input AbsynMat.User_Function uf;
output list<AbsynMat.Expression> exp_lst;
algorithm
  (exp_lst) := matchcontinue(uf)
  local
    AbsynMat.User_Function usr_fnc;
    list<AbsynMat.Parameter> prm; 
    Option<AbsynMat.Separator> sep;             
    list<AbsynMat.Statement> sstmt_lst, sstmt_lst2;       
    AbsynMat.Statement stmt_2nd; 
    list<AbsynMat.Decl_Elt> ret;   
    Absyn.Ident fname, fname1;
    list<AbsynMat.Expression> exp_lst1;
    list<String> ept;
    case(AbsynMat.START_FUNCTION(fname,prm,sep,sstmt_lst,stmt_2nd))
      equation
        (exp_lst1,sstmt_lst2,false) = stmt_lst(sstmt_lst,NONE(),false);        
      then 
        (exp_lst1);       
    case(AbsynMat.FINISH_FUNCTION(ret,usr_fnc))
      equation
        (exp_lst1) = user_function(usr_fnc);         
      then
        (exp_lst1);       
   end matchcontinue;                     
end user_function;

public function sub_function
input list<AbsynMat.Statement> stmt_lst;
output list<AbsynMat.Expression> exp_lst1;
algorithm
  (exp_lst1) := matchcontinue(stmt_lst)
  local
    AbsynMat.User_Function usr_fnc;
    AbsynMat.Separator sep;
    String fname;
    list<AbsynMat.Statement> stmt_lst2;
    list<AbsynMat.Expression> exp_lst2, exp_lst3, exp_lst4;
    case(AbsynMat.STATEMENT_APPEND(AbsynMat.STATEMENT(NONE(),NONE(),SOME(AbsynMat.START(usr_fnc,sep,stmt_lst2)),NONE()),_)::{})
    equation
    (exp_lst2) = sub_function(stmt_lst2); 
    (exp_lst3) = user_function(usr_fnc); 
     
    exp_lst4 = listAppend(exp_lst2,exp_lst3);
    then (exp_lst4);  
    case({})
    then ({});
  end matchcontinue;
end sub_function;


end Fnc_Handle;