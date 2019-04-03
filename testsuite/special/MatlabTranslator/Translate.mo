
encapsulated package Translate
import List;
import Absyn;
import AbsynMat;
import System;
import Mat_Builtin;
import Mod_Builtin;
import Fnc_Handle;

public function escape_modkeywords
"This function is used to differentiate modelica keywords with underscore added at the end if any modelica keyword
found in rml relations or statements"
  input String instring;
  output String outstring;
algorithm
  outstring:= matchcontinue(instring)
    local
      String id;
    case("match") then "match_";
    case("algorithm") then "algorithm_";
    case("annotation") then "annotation_";
    case("as") then "as_";
    case("block") then "block_";
    case("case") then "case_";
    case("class") then "class_";
    case("connect") then "connect_";
    case("connector") then "connector_";
    case("constant") then "constant_";
    case("discrete") then "discrete_";
    case("each") then "each_";
    case("else") then "else_";
    case("elseif") then "elseif_";
    case("elsewhen") then "elsewhen_";
    case("encapsulated") then "encapsulated_";
    case("end") then "end_";
    case("enumeration") then "enumeration_";
    case("equation") then "equation_";
    case("extends") then "extends_";
    case("external") then "external_";
    case("final") then "final_";
    case("flow") then "flow_";
    case("for") then "for_";
    case("function") then "function_";
    case("if") then "if_";
    case("import") then "import_";
    case("in") then "in_";
    case("initial") then "initial_";
    case("inner") then "inner_";
    case("input") then "input_";      
    case("list") then "list_";
    case("loop") then "loop_";
    case("local") then "local_";
    case("model") then "model_";
    case("matchcontinue") then "matchcontinue_";
    case ("not") then "not_";
    case("or") then "or_";
    case("outer") then "outer_";
    case("output") then "output_";
    case("overload") then "overload_";
    case("package") then "package_";
    case("parameter") then "parameter_";
    case("partial") then "partial_";
    case("protected") then "protected_";
    case("public") then "public_";
    case("record") then "record_";
    case("redeclare") then "redeclare_";
    case("replaceable") then "replaceable_";
    case("relation") then "relation_";
    case("then") then "then_";
    case("tuple") then "tuple_";
    case("type") then "type_";
    case("uniontype") then "uniontype_";
    case("when") then "when_";
    case("while") then "while_";
    case("within") then "within_";
    case(id) then  id;
      
  end matchcontinue;
end escape_modkeywords;

public function create_standard_elementitem
input Absyn.ElementSpec inelementspec;
  output Absyn.ElementItem outelement;
algorithm
  outelement:= matchcontinue(inelementspec)
    local
      Absyn.Info info;
      Absyn.ElementSpec elementspec;
    case(elementspec)
      equation
        info=SOURCEINFO("",false,0,0,0,0,0.0);
      then
        Absyn.ELEMENTITEM(Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),elementspec,info,NONE()));
  end matchcontinue;  
end create_standard_elementitem;

public function create_pubclasspart
  "function to create public classpart"
  input list<Absyn.ElementItem> initem;
  input Boolean inbool;
  output Absyn.ClassPart outclasspart;
algorithm
  outclasspart:= matchcontinue(initem,inbool)
    local
      list<Absyn.ElementItem> eitems;
      Boolean b;
    case(eitems,true)
      equation
    then 
      Absyn.PUBLIC(eitems);
    case(eitems,false)
    then
      Absyn.PROTECTED(eitems);
  end matchcontinue;
end create_pubclasspart;

public function create_class_parts
  input Ident inident;
  input Absyn.Restriction inrestriction;
  input Boolean inbool;
  input list<Absyn.ClassPart> inclasspart;
  input list<String> incomment;
  input Boolean inbool1;
  output Absyn.Class outclass;
algorithm
  outclass:= matchcontinue(inident,inrestriction,inbool,inclasspart,incomment,inbool1)
    local
      Ident id;
      Absyn.Restriction restriction;
      Boolean partial1;
      list<Absyn.ClassPart> classparts;
      Absyn.Info info;
      list<String> com;
      String mcom;
      Boolean b;
    case(id,restriction,partial1,classparts,com,b)
      equation
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        mcom="empty";        
      then
        Absyn.CLASS(id,partial1,false,false,restriction,Absyn.PARTS({},{},classparts,mcom),info);                
  end matchcontinue;
end create_class_parts;

public function separator
input AbsynMat.Separator sep;
output Boolean sep2;
algorithm 
  sep2 := matchcontinue(sep)
/*	case(AbsynMat.COMMA()
    then    
    case(AbsynMat.COMMA())
    then
    case (AbsynMat.SEMI_COLON())
    then
    case(AbsynMat.NEWLINES())
    then
 */
    case(AbsynMat.EMPTY())
    then true;
  end matchcontinue;   
end separator;


public function mat_operator
  input AbsynMat.Operator op;
  output Absyn.Operator mod_op;
  output String str_op;
algorithm
  (mod_op,str_op) := matchcontinue(op)
  local
    case(AbsynMat.UPLUS())
    then (Absyn.UPLUS(),("UPLUS"));
    case(AbsynMat.UMINUS())
    then (Absyn.UMINUS(),("UMINUS"));
    case(AbsynMat.ADD())
    then (Absyn.ADD(),("ADD"));
    case(AbsynMat.SUB())
    then (Absyn.SUB(),("SUB"));
    case(AbsynMat.MUL())
    then (Absyn.MUL(),("MUL"));
    case(AbsynMat.DIV())
    then (Absyn.DIV(),("DIV"));
    case(AbsynMat.POW())
    then (Absyn.POW(),("POW"));
    case(AbsynMat.EXPR_LT())
    then (Absyn.LESS(),("EXPR_LT"));
    case(AbsynMat.EXPR_LE())
    then (Absyn.LESSEQ(),("EXPR_LE"));
    case(AbsynMat.EXPR_EQ())
    then (Absyn.EQUAL(),("EXPR_EQ"));   ///???
    case(AbsynMat.EXPR_GE())    
    then (Absyn.GREATEREQ(),("EXPR_GE"));
    case(AbsynMat.EXPR_GT())
    then (Absyn.GREATER(),("EXPR_GT"));
    case(AbsynMat.EXPR_NE())
    then (Absyn.NEQUAL(),("EXPR_NE"));
    case(AbsynMat.EMUL())
    then (Absyn.MUL_EW(),("EMUL"));    
    case(AbsynMat.EDIV())
    then (Absyn.DIV_EW(),("EDIV"));
    case(AbsynMat.EPOW())
    then (Absyn.POW_EW(),("EPOW"));  
    case(AbsynMat.EXPR_AND())
    then (Absyn.AND(),("EXPR_AND"));      
    case(AbsynMat.EXPR_OR())
    then (Absyn.OR(),("EXPR_OR"));
    case(AbsynMat.EXPR_AND_AND())
    then (Absyn.AND(),("EXPR_AND_AND"));
    case(AbsynMat.EXPR_OR_OR())
    then (Absyn.OR(),("EXPR_OR_OR"));
    case(AbsynMat.EXPR_NOT())
    then (Absyn.NOT(),("EXPR_NOT"));   
  end matchcontinue;
end mat_operator;

public function vec_or_mtx
input list<list<Absyn.Exp>> exp_lst_lst;
output Boolean vec_mtx;
algorithm
  vec_mtx := matchcontinue(exp_lst_lst)
  local
    list<list<Absyn.Exp>> exp_lst_lst1;
    case({})  // Vector
    equation
    then false;
    case(exp_lst_lst1) // Matrix
    equation
    then true;
  end matchcontinue;
end vec_or_mtx;

public function bool_chk
input Boolean chk;
input Boolean chk2;
output String o_str;
algorithm
o_str := matchcontinue (chk,chk2)
 local
   case(true,false)
     then "vector";
   case(false,false)
     then "column_vector";
   case(false,true)
     then "matrix";    
  end matchcontinue;
end bool_chk;

public function chk_column_vet
 input Integer int;
 input Boolean chk;
 output Boolean chko;
 algorithm
   chko := matchcontinue(int,chk)
   local
     Integer int1;
     Boolean chk1;
     case(1,chk1)
       then chk1;
     case(int1,chk1)
       then false;
   end matchcontinue;
end chk_column_vet;

public function cmp_lst1_lst2
input Integer lst1;
input Integer lst2;
output String ary;
algorithm
  ary := matchcontinue(lst1,lst2)
  local
    String ary2;
    Integer lst11, lst22;
    Boolean chk, chk2, chk3;
 /*   case(lst11,lst22)
      equation
       chk = intGt(lst11,lst22);
       chk3 = chk_column_vet(lst11,chk);
       chk2 = intEq(lst11,lst22);
       ary2 = bool_chk(chk,chk2); 
      then ary2; */
    case(1,lst22)
      then "column_vector";
    case(lst11,0)
      then "vector";
    case(lst11,lst22)
      then "matrix";   
  end matchcontinue;
end cmp_lst1_lst2;

public function dtype
 input String typ;
 input list<String> dnum;
 output String outtyp;
 algorithm
   outtyp := matchcontinue(typ,dnum)
   local
     list<String> dnum1;
     String typ1, dnum0, outtyp1;
     Integer i, i2;
     case(typ1,dnum0::dnum1)
       equation
        i = stringInt(dnum0);
        i2 = i + 1;
        outtyp1 = intString(i2);
     then outtyp1;
   end matchcontinue;
end dtype;

public function dtype_to_num
 input list<String> d_type;
 input list<String> dnum;
 output list<String> outnum;
 algorithm
   outnum := matchcontinue(d_type,dnum)
   local
     list<String> d_type1, d_type2, dnum1, outnum1;
     String typ, typ1;
     Integer lth;
     case({},dnum1)
     then {};
     case(typ::d_type1,dnum1)
       equation
        typ1 = dtype(typ,dnum1);
        d_type2 = dtype_to_num(d_type1,dnum1);
        outnum1 = listAppend({typ1},d_type2);
       then outnum1;   
   end matchcontinue;  
end dtype_to_num;
 

public function mat_matrix
input list<AbsynMat.Matrix> agr_lst;
input list<String> dnum;
output list<list<Absyn.Exp>> exp_lst;
output list<String> d_type;
output Boolean vec_mtx;
output String ary_info;
output list<String> d_type7;
algorithm
  (exp_lst,d_type,vec_mtx,ary_info,d_type7) := matchcontinue(agr_lst,dnum)
  local
  list<AbsynMat.Argument> arg_lst1;
  list<AbsynMat.Matrix> mtx_lst;
  list<Absyn.Exp> exp, exp2, exp3;
  list<String> d_type1, d_type2, d_type3, d_type6, d_type8, d_type9, dnum1, dnum2;
  list<list<Absyn.Exp>> mat;
  Integer lst1, lst2;
  Boolean vec_mtx1;
  String ary;
   case(AbsynMat.MATRIX(arg_lst1)::mtx_lst,dnum1)
    equation 
      (exp,d_type1) = argument_lst(arg_lst1,true);
      d_type6 = d_type1; 
      dnum2 = dtype_to_num(d_type1,dnum1);
      (mat, d_type2,vec_mtx1,ary,d_type8)= mat_matrix(mtx_lst,dnum2); 
      vec_mtx1 = vec_or_mtx(mat);   //either variable is Vector or Matrix      
      d_type3 = listAppend(dnum2,d_type2);  
      d_type9 = listAppend(d_type6,d_type8);   
      lst1 = listLength(d_type6);  
      lst2 = listLength(d_type8);
      ary = cmp_lst1_lst2(lst1,lst2);
   then
      (exp::mat,d_type3,vec_mtx1,ary,d_type9);
      
  case({},dnum1)
    equation
      ary="";
  then ({},{},false,ary,{});
  end matchcontinue;
end mat_matrix;

public function expression_cref
input AbsynMat.Expression exp;
output String cref;
algorithm
  cref := matchcontinue(exp)
  local
    AbsynMat.Expression exp1;
    String cref1;
    AbsynMat.Ident ident;
    case(AbsynMat.IDENTIFIER(ident))
      equation
         cref1 = ident;
      then
        cref1;
  end matchcontinue;
end expression_cref;

public function fnc_call
input String cref;
input list<String> f_call;
output Boolean fnc_chk;
algorithm
  fnc_chk := matchcontinue(cref,f_call)
  local
    list<String> f_call1;
    String cref1;
    Boolean fnc_chk1;
    case(cref1,f_call1)
      equation
      fnc_chk1 = listMember(cref1,f_call1);
    then fnc_chk1;  
  end matchcontinue;
end fnc_call;

public function fnc_ident
input String fnc_hdl_ident;
output Absyn.Exp mod_exp;
algorithm
  mod_exp := matchcontinue(fnc_hdl_ident)
  local
  String fnc_hdl_ident1;
  Absyn.Exp mod_exp1;
    case(fnc_hdl_ident1)      
      equation
    then (Absyn.CREF(Absyn.CREF_IDENT(fnc_hdl_ident1,{}))); 
  end matchcontinue;   
end fnc_ident; 
   
public function ident_lst
input list<String> fnc_hdl_idents;
output list<Absyn.Exp> mod_lst;
algorithm
  mod_lst := matchcontinue(fnc_hdl_idents)
  local
    list<String> fnc_hdl_idents1;
    Absyn.Exp mod_exp;
    list<Absyn.Exp> mod_lst2, mod_lst3;
    String fnc_hdl_ident,fname;
    case(fnc_hdl_ident::fnc_hdl_idents1)
    equation
      mod_exp = fnc_ident(fnc_hdl_ident);
      mod_lst2 = ident_lst(fnc_hdl_idents1);
      mod_lst3 = listAppend(mod_exp::{},mod_lst2);
    then mod_lst3;
    case({})
    then {};
  end matchcontinue;
end ident_lst;

public function rpl_arg_fnc_hdl
input list<String> fnc_hdl_idents;
input String cref;
output Absyn.Exp out;
algorithm
  out := matchcontinue(fnc_hdl_idents,cref)
  local
  list<String> fnc_hdl_idents1;
  String cref1, fname;
   list<Absyn.Exp> mod_lst;
  case(fname::fnc_hdl_idents1,cref1) //drop first ident because its a function name and rest of ident is declared as a function arguments
    equation
      mod_lst = ident_lst(fnc_hdl_idents1);
      out = Absyn.CALL(Absyn.CREF_IDENT(cref1,{}),Absyn.FUNCTIONARGS(mod_lst,{}));
        then out; 
  end matchcontinue;
end rpl_arg_fnc_hdl;

public function fnc_or_index
input list<AbsynMat.Argument> arg_lst;
input String cref;
input Boolean blt_chk;
input Boolean fnc_chk;
output Absyn.Exp out;
algorithm
  out := matchcontinue(arg_lst,cref,blt_chk,fnc_chk)
   local
     list<Absyn.Subscript> sub_lst;
     list<AbsynMat.Argument> arg_lst1;
     list<Absyn.Exp> mod_lst;
     String cref1;
     Absyn.Exp out1;
    case(arg_lst1,cref1,true,true)
      equation
        mod_lst = argument_lst(arg_lst1,false);
        out1 = Absyn.CALL(Absyn.CREF_IDENT(cref1,{}),Absyn.FUNCTIONARGS(mod_lst,{}));
        then out1; 
    case(arg_lst1,cref1,true,false)
      equation
        mod_lst = argument_lst(arg_lst1,false);
        out1 = Absyn.CALL(Absyn.CREF_IDENT(cref1,{}),Absyn.FUNCTIONARGS(mod_lst,{}));
        then out1;
    case(arg_lst1,cref1,false,true)
      equation
          mod_lst = argument_lst(arg_lst1,false);
          out1 = Absyn.CALL(Absyn.CREF_IDENT(cref1,{}),Absyn.FUNCTIONARGS(mod_lst,{}));
        then out1;
    case(arg_lst1,cref1,false,false)
      equation
        sub_lst = array_lst(arg_lst1);
        out1 = Absyn.CREF(Absyn.CREF_IDENT(cref1,sub_lst));     
        then  out1;
  end matchcontinue;
end fnc_or_index;  
      
public function tslat_vec_mtx
input list<list<Absyn.Exp>> mod_exp_lst;
input Boolean vec_mtx;
output Absyn.Exp mod_exp;
algorithm 
  mod_exp := matchcontinue(mod_exp_lst,vec_mtx)
  local
    list<list<Absyn.Exp>> mod_exp_lst1, mod_exp_lst2;
    Boolean vec_mtx1;
    list<Absyn.Exp> mod_exp1, mod_exp3, mod_exp4;
    Absyn.Exp mod_exp2, out, out2;
    Absyn.FunctionArgs fnc_args;
    list<list<Absyn.Exp>> mod_exp_lst_lst;
    case(mod_exp1::mod_exp_lst1,true)
      equation
        out = Absyn.MATRIX({mod_exp1});   
        mod_exp2 = tslat_vec_mtx(mod_exp_lst1,true);    
        {out2} = listAppend({out},{mod_exp2});         
      then out2;
    case(mod_exp_lst1,true)
      equation
        out = Absyn.MATRIX(mod_exp_lst1);    
      then out;
    case(mod_exp_lst1,false)
      equation
        {mod_exp4} = mod_exp_lst1;
        fnc_args = Absyn.FUNCTIONARGS(mod_exp4,{});       
        out = Absyn.CALL(Absyn.CREF_IDENT("array",{}),fnc_args);      
      then out;
  end matchcontinue;
end tslat_vec_mtx;      
      
public function bool_String
input Boolean bool;
output String mtx_vec;
algorithm
  mtx_vec := matchcontinue(bool)
  local
    String mtx_vec1;
  case(true)
    then "matrix";
  case(false)
    then "vector";
  end matchcontinue;
end bool_String;      

public function fnc_hdl_stmt
  input AbsynMat.Statement fnc_stmt;
  output Absyn.Exp mod_exp;
  output list<String> ident_lst;
algorithm
  (mod_exp,ident_lst) := matchcontinue(fnc_stmt)
    local
    AbsynMat.Expression exp; 
    Absyn.Exp mod_exp1;
    list<String> stmt_ident;   
    case(AbsynMat.STATEMENT(NONE(),SOME(exp),NONE(),NONE()))
      equation
        (mod_exp1,stmt_ident) = expression(exp,{},{});
      then 
        (mod_exp1,stmt_ident);
  end matchcontinue; 
end fnc_hdl_stmt;

public function arg_fnc_hdl
input Boolean fnc_hdl_chk;
input list<String> fnc_hdl_idents;
input String cref;
input list<AbsynMat.Argument> arg_lst;
input Boolean blt_chk;
input Boolean fnc_chk;
output Absyn.Exp mod_exp;
algorithm
 mod_exp := matchcontinue(fnc_hdl_chk,fnc_hdl_idents,cref,arg_lst,blt_chk,fnc_chk)
 local
   Boolean blt_chk1,fnc_chk1;
   list<String> fnc_hdl_idents1;
   String cref1;
   list<AbsynMat.Argument> arg_lst1;
   Absyn.Exp mod_exp1;
   case(true,fnc_hdl_idents1,cref1,arg_lst1,blt_chk1,fnc_chk1)
     equation
       mod_exp1 = rpl_arg_fnc_hdl(fnc_hdl_idents1,cref1); // replaces fnc arg with fnd hdl idents for proper fnc call
     then mod_exp1;
    case(false,fnc_hdl_idents1,cref1,arg_lst1,blt_chk1,fnc_chk1)
     equation
       mod_exp1 = fnc_or_index(arg_lst1,cref1,blt_chk1,fnc_chk1);                
     then mod_exp1;
end matchcontinue;
end arg_fnc_hdl; 

public function decl
input AbsynMat.Decl_Elt decl_elt;
output String ident;
algorithm
  ident := matchcontinue(decl_elt)
    local
    String ident2, ident_in;
    case(AbsynMat.DECL(ident_in,NONE()))
      equation  
        then 
          ident_in;
  end matchcontinue;
end decl;

public function decl_lst
input list<AbsynMat.Decl_Elt> decl_elt_lst;
output list<String> ident_lst;
algorithm
  ident_lst := matchcontinue(decl_elt_lst)
local
  list<AbsynMat.Decl_Elt> decl_elt_lst2;  
  AbsynMat.Decl_Elt decl_elt;
  list<String> ident_out, ident2;
  String ident;
  case(decl_elt::decl_elt_lst2)
    equation
      ident = decl(decl_elt);
      ident2 = decl_lst(decl_elt_lst2);
      ident_out = listAppend({ident},ident2);
    then ident_out; 
  case({})
  then {};
  end matchcontinue;
end decl_lst;
/*
public function loop_heading  // transform for s = [1,2,3] to for s in {1,2,3}
  input list<AbsynMat.Matrix> mtx;
  input list<String> lp_chk;
  output Absyn.Exp mod_exp;
  output list<String> mat_vet;
algorithm
  (mod_exp,mat_vet) := matchcontinue (mtx,lp_chk)
    local
      String mv;
      list<String> arg_str, d_type, arg_str, f_call, ary_n_type;
      Absyn.Exp out;
      list<Absyn.Exp> mod_lst;
      list<list<Absyn.Exp>> mod_lst_lst;
      Boolean vec_mtx;
      list<AbsynMat.Matrix> mtx1;
      list<AbsynMat.Argument> arg_lst;
    case(AbsynMat.MATRIX(arg_lst)::{},{"for_loop"})
      equation
        (mod_lst,arg_str) = argument_lst(arg_lst,false);
        out = Absyn.ARRAY(mod_lst);
        print("\n Heading for loop \n");
      then
        (out,arg_str);
    case(mtx1,f_call)
      equation
        (mod_lst_lst,d_type,vec_mtx) = mat_matrix(mtx);
        print("\n Expression FINISH_MATRIX 3\n");
        print(anyString(d_type));
        out =  tslat_vec_mtx(mod_lst_lst,vec_mtx);  
        mv = bool_String(vec_mtx);
        ary_n_type = listAppend({mv},d_type);
      then       
        (out,ary_n_type); 
  end matchcontinue;
end loop_heading;
*/

public function ident_subscript2
 input Absyn.Exp mod_exp;
 output String dim;
 algorithm
   dim := matchcontinue(mod_exp)
   local
   Integer i;
   Real r;
   String dim1, dim2;
     case(Absyn.INTEGER(i))
       equation
         dim1 = intString(i);
         dim2 = "1" + "x";
       then dim2;
     case(Absyn.REAL(dim1))
       equation
         //dim1 = realString(r);
         dim2 = dim1 + "x";
       then dim2;
     case(Absyn.CREF(Absyn.CREF_IDENT(dim1,{})))
       equation
         dim2 = "ARYIDENT";
     then dim2; 
     case(Absyn.BINARY(Absyn.CREF(Absyn.CREF_IDENT(dim1,{})),Absyn.ADD(),Absyn.INTEGER(i)))
         equation
         dim2 = "ARYIDENT";
     then dim2; 
     case(Absyn.BINARY(Absyn.CREF(Absyn.CREF_IDENT(dim1,{})),Absyn.SUB(),Absyn.INTEGER(i)))
         equation
         dim2 = "ARYIDENT";
     then dim2;
      case(Absyn.BINARY(Absyn.CREF(Absyn.CREF_IDENT(dim1,{})),Absyn.ADD(),Absyn.CREF(Absyn.CREF_IDENT(dim2,{}))))
         equation
         dim2 = "ARYIDENT";
     then dim2;      
       case(Absyn.BINARY(Absyn.CREF(Absyn.CREF_IDENT(dim1,{})),Absyn.SUB(),Absyn.CREF(Absyn.CREF_IDENT(dim2,{}))))
         equation
         dim2 = "ARYIDENT";
     then dim2;         
   end matchcontinue;
end ident_subscript2;
 
public function ident_subscript
 input list<Absyn.Exp> mod_exp;
 output String dim;
 algorithm
   dim := matchcontinue(mod_exp)
   local
     Absyn.Exp mod;
     list<Absyn.Exp> mod_exp1;
     String dim1, dim2, dim0;
     case({})
     then "0";
      case(mod::mod_exp1)
       equation
       dim1 = ident_subscript2(mod);
       dim2 = ident_subscript(mod_exp1);
       dim0 = stringAppend(dim1,dim2);
     then dim0;
   end matchcontinue;
 end ident_subscript;

public function length
  input Integer lgth;
  input String dim;
  output String string;
algorithm
  string := matchcontinue(lgth,dim)
    local
      Integer lgth1;
      String dim1;
    case(3,dim1)
    then "empty";
    case(lgth1,dim1)
    then dim1;
  end matchcontinue;
end length;

public function vec_mtx
  input list<String> stringlist; 
  input String dim;
  output String dimo;
algorithm
   dimo := matchcontinue(stringlist,dim)
     local
     list<String> stringlist1;
     String dim1, dim2;
     Integer lgth;
     case(stringlist1,dim1)
       equation
         lgth = listLength(stringlist1);
         dim2 = length(lgth,dim1);
       then dim2;
  end matchcontinue;
end vec_mtx;

public function matlab_builtin
input String cref;
input list<Absyn.Exp> mod_exp;
output String dim;
output String dim2;
algorithm
  (dim,dim2) := matchcontinue(cref,mod_exp)
  local
  list<Absyn.Exp> mod_exp2,mod_exp3;
  String dim0, ret_str,fnc_dim, fnc_dim2, fnc_dim3, dim1;
  Integer i,j;
  list<String> stringlist;
  case("zeros",Absyn.INTEGER(i)::mod_exp3)
    equation
      Absyn.INTEGER(j)::{}=mod_exp3;     
      fnc_dim = intString(i);
      fnc_dim2 = intString(j);
      fnc_dim3 = stringAppend(fnc_dim,fnc_dim2);
    then ("zeros",fnc_dim3);
  case("ones",Absyn.INTEGER(i)::mod_exp3)
    equation
      Absyn.INTEGER(j)::{}=mod_exp3;
      fnc_dim = intString(i);
      fnc_dim2 = intString(j);
      fnc_dim3 = stringAppend(fnc_dim,fnc_dim2);
    then ("ones",fnc_dim3);
  case("sqrt",mod_exp2)
    equation
      ret_str="";
    then (ret_str,"Real"); 
  case("ceil",mod_exp2)
     equation
      ret_str="";
    then (ret_str,"Real");
  case("floor",mod_exp2)
     equation
      ret_str="";
    then (ret_str,"Real");
  case("abs",mod_exp2)    //real or integer, depends on input
   equation
      ret_str="";
    then (ret_str,"Real"); 
  case("mod",mod_exp2)    //real or integer, depends on input
   equation
      ret_str="";
    then (ret_str,"Real");                       
  case(ret_str,mod_exp2) 
    equation
      dim0 = ident_subscript(mod_exp2);
      stringlist = stringListStringChar(dim0);
      dim1 = vec_mtx(stringlist,dim0);
      ret_str="";
    then 
      (ret_str,dim1);         
 end matchcontinue;
end matlab_builtin;

public function expression
input AbsynMat.Expression exp;
input list<String> f_call;
input list<String> fnc_hdl_idents_i;
output Absyn.Exp mod_exp;
output list<String> stmt_ident;
algorithm
  (mod_exp,stmt_ident) := matchcontinue(exp,f_call,fnc_hdl_idents_i)
  local
    list<AbsynMat.Argument> arg, arg_lst,arglst;
    list<AbsynMat.Expression> exp_lst;
    list<Absyn.Exp> mod_exp6;
    AbsynMat.Operator op;
    AbsynMat.Expression exp1,exp2, exp3, mat_exp;
    AbsynMat.Ident ident;
    String mv, vname, str, cref, ident1, strop,id;
    AbsynMat.Operator mat_op;
    Absyn.Operator mod_op;
    Absyn.Exp out, out1, outexp1, outexp2, outexp3, out_name;
    list<AbsynMat.Matrix> mtx;
    list<list<Absyn.Exp>> mod_lst;
    String ary_info, dim_str, fnc_dim, snumber;
    Real number; 
    Integer int;  
    list<String> d_type9, dims, ident_op, strop_lst, ident2, ident3, ident4, f_call1,f_call2, ary, d_type, ary_n_type, fnc_hdl_idents;
    Boolean blt_chk, fnc_chk, vec_mtx, fnc_hdl_chk; 
    Absyn.FunctionArgs fnc_args;
    AbsynMat.Statement fnc_stmt;
    list<AbsynMat.Parameter> prm_lst;
    list<AbsynMat.Decl_Elt> decl_elt_lst;
    case(AbsynMat.FINISH_COLON_EXP(exp_lst),f_call1,fnc_hdl_idents)
      equation
        (SOME(outexp3),f_call2) = expression_lst(exp_lst,f_call1,fnc_hdl_idents); 
       then
        (outexp3,f_call2);
    case(AbsynMat.BINARY_EXPRESSION(exp1,exp2,op),f_call1,fnc_hdl_idents)      
      equation
        (outexp1,ident2) = expression(exp1,{},fnc_hdl_idents);        
        (outexp2,ident3) = expression(exp2,{},fnc_hdl_idents);        
        (mod_op,strop) = mat_operator(op);   
        //out = Absyn.BINARY(outexp1,mod_op,outexp2);
        out = assignoperatorexpression(mod_op,outexp1,outexp2);
        strop_lst = {strop};
        ident_op = listAppend(ident2,strop_lst);
        ident4 = listAppend(ident_op,ident3);  //ident4 = listAppend(ident2,ident3); 
          
      then
        (out,ident4);    
   case(AbsynMat.ANON_FCN_HANDLE(AbsynMat.PARM(decl_elt_lst)::{},fnc_stmt),f_call1,fnc_hdl_idents)
      equation
        ident2 = decl_lst(decl_elt_lst);
        (out,ident3) = fnc_hdl_stmt(fnc_stmt);
        ident4 = listAppend(ident2,ident3);        
    then 
        (out,ident4);         
    case(AbsynMat.FINISH_MATRIX(mtx),f_call1,fnc_hdl_idents)
      equation
        //(out,mv) = loop_heading(mtx,f_call1);
        (mod_lst,d_type,vec_mtx,ary_info,d_type9) = mat_matrix(mtx,{"0"});
        out =  tslat_vec_mtx(mod_lst,vec_mtx);  
        ary_n_type = listAppend({ary_info},d_type);      
      then
        (out,ary_n_type);
    case(AbsynMat.PREFIX_EXPRESSION(mat_exp, mat_op),f_call1,fnc_hdl_idents)
      equation
        (mod_op,strop) = mat_operator(mat_op);
        (outexp1,ident2) = expression(mat_exp,{},fnc_hdl_idents);  
        strop_lst = {strop};
        ident_op = listAppend(strop_lst,ident2);                
        out = Absyn.UNARY(mod_op,outexp1);
      then
        (out,ident_op);
    case(AbsynMat.INDEX_EXPRESSION(mat_exp,arg_lst),f_call1,fnc_hdl_idents)
      equation
        cref = expression_cref(mat_exp);
        (id,arglst)=checkbuiltins(cref,arg_lst);
        (mod_exp6,dims) = argument_lst(arg_lst,false);
        (dim_str,fnc_dim) = matlab_builtin(cref,mod_exp6);      
        blt_chk = Mat_Builtin.builtIn(cref);
        fnc_chk = fnc_call(cref,f_call1);
        fnc_hdl_chk = fnc_call(cref,fnc_hdl_idents);  // return true if fnc name matches the list of fnc hdl idents
 
       // out = arg_fnc_hdl(fnc_hdl_chk,fnc_hdl_idents,cref,arg_lst,blt_chk,fnc_chk);
        out = arg_fnc_hdl(fnc_hdl_chk,fnc_hdl_idents,id,arglst,blt_chk,fnc_chk);
        //  out = rpl_arg_fnc_hdl(fnc_hdl_idents,cref); // replaces fnc arg with fnd hdl idents for proper fnc call       
        //  out = fnc_or_index(arg_lst,cref,blt_chk,fnc_chk);
        then
        (out,{cref,fnc_dim}); 
    case(AbsynMat.STR(str),f_call1,fnc_hdl_idents)
    then (Absyn.STRING(str),{});  
    case(AbsynMat.IDENTIFIER(ident),f_call1,fnc_hdl_idents)
      equation               
         then
      (Absyn.CREF(Absyn.CREF_IDENT(ident,{})),{ident});
    case(AbsynMat.INT(int),f_call1,fnc_hdl_idents)
      equation 
    then 
      (Absyn.INTEGER(int),{"Integer"});
    case(AbsynMat.NUM(number),f_call1,fnc_hdl_idents)
      equation
        snumber = realString(number);
      then 
        (Absyn.REAL(snumber),{"Real"}); 
    case(AbsynMat.CONSTANT(),f_call1,fnc_hdl_idents)
      equation
         then 
       (Absyn.REAL("0.000"),{"Constants"});      
  end matchcontinue;
end expression;

public function assignoperatorexpression
input Absyn.Operator inop;
input Absyn.Exp inexp;
input Absyn.Exp inexp1;
output Absyn.Exp outexp;
algorithm
  outexp:= matchcontinue(inop,inexp,inexp1)
  local
    Absyn.Exp exp1,exp2,exp;
    Absyn.Operator modop;
    case (Absyn.LESS(),exp1,exp2)
      equation
        exp=Absyn.RELATION(exp1,Absyn.LESS(),exp2);
      then
        exp;        
    case (Absyn.LESSEQ(),exp1,exp2)
      equation
        exp=Absyn.RELATION(exp1,Absyn.LESSEQ(),exp2);
      then
        exp;           
    case (Absyn.GREATEREQ(),exp1,exp2)
     equation
        exp=Absyn.RELATION(exp1,Absyn.GREATEREQ(),exp2);
      then
        exp;
    case (Absyn.GREATER(),exp1,exp2)
      equation
        exp=Absyn.RELATION(exp1,Absyn.GREATER(),exp2);
      then
        exp;
    case (Absyn.NEQUAL(),exp1,exp2)
       equation
        exp=Absyn.RELATION(exp1,Absyn.NEQUAL(),exp2);
      then
        exp;
    case (Absyn.EQUAL(),exp1,exp2)
       equation
        exp=Absyn.RELATION(exp1,Absyn.EQUAL(),exp2);
      then
        exp;
        
    case (Absyn.AND(),exp1,exp2)     
       equation
        exp=Absyn.LBINARY(exp1,Absyn.AND(),exp2);
      then
        exp;
    case (Absyn.OR(),exp1,exp2)     
       equation
        exp=Absyn.LBINARY(exp1,Absyn.OR(),exp2);
      then
        exp;
    case(modop,exp1,exp2)
      equation
        exp=Absyn.BINARY(exp1,modop,exp2);
      then
        exp;   
    
   end matchcontinue;
end assignoperatorexpression;

public function checkbuiltins
input String instring;
input list<AbsynMat.Argument> matargs;
output String outstring;
output list<AbsynMat.Argument> outmatargs;
algorithm
  (outstring,outmatargs):=matchcontinue(instring,matargs)
    local 
      String id,matid,inputstring;
      list<AbsynMat.Argument> arglist,inarglist;
      case("length",{AbsynMat.ARGUMENT(AbsynMat.FINISH_COLON_EXP({AbsynMat.IDENTIFIER(matid)}))})
        equation
          id="size";
          arglist={AbsynMat.ARGUMENT(AbsynMat.FINISH_COLON_EXP({AbsynMat.IDENTIFIER(matid)})),
                   AbsynMat.ARGUMENT(AbsynMat.FINISH_COLON_EXP({AbsynMat.INT(1)}))};
          then 
            (id,arglist);
      case("size",{AbsynMat.ARGUMENT(AbsynMat.FINISH_COLON_EXP({AbsynMat.IDENTIFIER(matid)})),AbsynMat.ARGUMENT(AbsynMat.FINISH_COLON_EXP({AbsynMat.INT(2)}))})
        equation
          id="size";
          arglist={AbsynMat.ARGUMENT(AbsynMat.FINISH_COLON_EXP({AbsynMat.IDENTIFIER(matid)})),
                   AbsynMat.ARGUMENT(AbsynMat.FINISH_COLON_EXP({AbsynMat.INT(1)}))};
          then 
            (id,arglist);
      case(inputstring,inarglist)
        equation
            outstring=inputstring;
            outmatargs=inarglist;    
        then 
          (outstring,outmatargs);
            end matchcontinue;
end checkbuiltins;

public function expression_lst
  input list<AbsynMat.Expression> exp_lst;
  input list<String> f_call;
  input list<String> fnc_hdl_ident;
  output Option<Absyn.Exp> out_exp;
  output list<String> f_call1;
algorithm
  (out_exp,f_call1) := matchcontinue(exp_lst,f_call,fnc_hdl_ident)
    local
    list<AbsynMat.Expression> exp_lst1;
    AbsynMat.Expression exp1, exp2, exp3, exp4;
    Absyn.Exp mod_exp1, mod_exp2, mod_exp3;
    Option<Absyn.Exp> out_exp1;
     Absyn.Exp out_exp2;
     list<String> f_call2, fnc_hdl_ident1;
      case(AbsynMat.FINISH_COLON_EXP(exp_lst1)::{},f_call2,fnc_hdl_ident1)
        equation
           
          (out_exp1,{}) = expression_lst(exp_lst1,f_call2,fnc_hdl_ident1);
          then
          (out_exp1,{});
       case(AbsynMat.FINISH_COLON_EXP(exp4::{})::{},{},fnc_hdl_ident1)  
        equation
           (out_exp2,f_call2) = expression(exp4,{},fnc_hdl_ident1);                    
          then
          (SOME(out_exp2),f_call2);         
      case(exp1::exp2::exp3::{},{},fnc_hdl_ident1)
        equation
          mod_exp1 = expression(exp1,{},{});
          mod_exp2 = expression(exp2,{},{});
          mod_exp3 = expression(exp3,{},{});
          out_exp2 = Absyn.RANGE(mod_exp1,SOME(mod_exp2),mod_exp2);          
          out_exp1 = SOME(out_exp2);
          then
            (out_exp1,{});          
      case(exp1::exp2::{},{},fnc_hdl_ident1)
        equation
          mod_exp1 = expression(exp1,{},{});
          mod_exp2 = expression(exp2,{},{});
          out_exp2 = Absyn.RANGE(mod_exp1,NONE(),mod_exp2);          
          out_exp1 = SOME(out_exp2);
          then
            (out_exp1,{});    
    case(exp1::{},f_call2,fnc_hdl_ident1)
      equation
        (mod_exp1,f_call2) = expression(exp1,f_call2,fnc_hdl_ident1);
    then
        (SOME(mod_exp1),f_call2);
    case({},{},fnc_hdl_ident1)
      then (NONE(),{});
  end matchcontinue;
end expression_lst;

public function for_ident
input list<AbsynMat.Argument> arg;
input Option<AbsynMat.Expression> mod_exp;
output String out_ident;
algorithm
  (out_ident) := matchcontinue(arg,mod_exp)
  local
    AbsynMat.Ident ident;
    String ident1;
    AbsynMat.Argument arg1;
    Option<AbsynMat.Expression> exp;
    case(arg1::{},NONE())
      equation
        exp = for_argument(arg1);
        ident1 = for_ident({},exp);        
      then
        ident1;
    case({},SOME(AbsynMat.FINISH_COLON_EXP(AbsynMat.IDENTIFIER(ident)::{})))    
      equation
        ident1 = ident;
      then ident1;    
  end matchcontinue;
end for_ident;

public function for_argument
  input AbsynMat.Argument arg;
  output Option<AbsynMat.Expression> mod_exp;
algorithm
  mod_exp := matchcontinue(arg)
    local
    AbsynMat.Expression exp;            
    case(AbsynMat.ARGUMENT(exp))
    then SOME(exp);
  end matchcontinue;
end for_argument;

public function argument
  input AbsynMat.Argument arg;
  input Boolean tf; //true
  output Absyn.Exp mod_exp;
  output list<String> arg_ident;
algorithm
  (mod_exp,arg_ident) := matchcontinue(arg,tf)
    local
      String var_name,ident;
      AbsynMat.Expression exp;
      Absyn.Exp exp1;
      list<String> ident2;
      Integer int;
      Real number;
      AbsynMat.Matrix mtx;
    case(AbsynMat.ARGUMENT(exp),false)
      equation
        (exp1,ident2) = expression(exp,{},{});    
        
      then
        (exp1,ident2);   
    case(AbsynMat.ARGUMENT(AbsynMat.FINISH_COLON_EXP(AbsynMat.INT(int)::{})),true)
      equation
        ident = intString(int);
      then (Absyn.CREF(Absyn.CREF_IDENT(ident,{})),{"Integer"});
    case(AbsynMat.ARGUMENT(AbsynMat.FINISH_COLON_EXP(AbsynMat.NUM(number)::{})),true)
      equation
        ident = realString(number);        
      then (Absyn.CREF(Absyn.CREF_IDENT(ident,{})),{"Real"});
    case(AbsynMat.ARGUMENT(AbsynMat.FINISH_COLON_EXP(AbsynMat.IDENTIFIER(ident)::{})),true)
    then (Absyn.CREF(Absyn.CREF_IDENT(ident,{})),{ident});         
    case(AbsynMat.ARGUMENT(AbsynMat.FINISH_COLON_EXP(AbsynMat.PREFIX_EXPRESSION(AbsynMat.INT(int), AbsynMat.UMINUS())::{})),true)
    equation       // dealing with unary elements in array e.g. a = [-1, 2 3 4]
        ident = intString(-int);
    then (Absyn.CREF(Absyn.CREF_IDENT(ident,{})),{"Integer"}); 
    case(AbsynMat.ARGUMENT(AbsynMat.FINISH_COLON_EXP(AbsynMat.PREFIX_EXPRESSION(AbsynMat.NUM(number), AbsynMat.UMINUS())::{})),true)
    equation       // dealing with unary elements in array e.g. a = [-1, 2 3 4]
        ident = realString(-number);
    then (Absyn.CREF(Absyn.CREF_IDENT(ident,{})),{"Real"});   
  end matchcontinue;
end argument;

public function argument_lst
  input list<AbsynMat.Argument> arg;
  input Boolean mat_mtx;   
  output list<Absyn.Exp> mod_exp;
  output list<String> arg_ident;
algorithm
  (mod_exp,arg_ident) := matchcontinue(arg,mat_mtx)
    local
      list<AbsynMat.Argument> arglst2;
      Absyn.Exp exp;
      list<Absyn.Exp> mod_lst, mod_lst1;
      AbsynMat.Argument arg1;
      list<String> ident, ident1, ident2;
      Boolean tf;
    case(arg1::arglst2,tf)
      equation
        (exp,ident) = argument(arg1,tf); 
        (mod_lst,ident1) =  argument_lst(arglst2,tf);
        ident2 = listAppend(ident,ident1);   
        mod_lst1 = listAppend({exp},mod_lst);              
      then  
        (mod_lst1,ident2);
    case(arg1::{},tf)
      equation
        (exp,ident1) = argument(arg1,tf);
      then
        ({exp},ident1);
    case({},tf)
      then ({},{});
  end matchcontinue;
end argument_lst;

public function modExp
input Absyn.Exp exp;
output Absyn.Subscript sub;
algorithm
  sub := matchcontinue(exp)
  local
    Absyn.Exp exp1;
     case(Absyn.REAL("0.000"))  ///// Real changed to String
      equation
      then Absyn.NOSUB();
    case(exp1) 
      equation
    then Absyn.SUBSCRIPT(exp1);
  end matchcontinue;
end modExp;

public function modExpLst
input list<Absyn.Exp> exp_lst;
output list<Absyn.Subscript> sub_lst;
algorithm
  sub_lst := matchcontinue(exp_lst)
  local
    list<Absyn.Exp> exp_lst1;
    list<Absyn.Subscript> sub_lst1, sub_lst2;
    Absyn.Subscript sub;
    Absyn.Exp exp;
    case(exp::exp_lst1)
      equation
        sub = modExp(exp);
        sub_lst1 = modExpLst(exp_lst1);
        sub_lst2 = listAppend({sub},sub_lst1);
      then
        sub_lst2;
    case({})
    then ({});
  end matchcontinue;
end modExpLst;

public function array_lst
  input list<AbsynMat.Argument> arg;
  output list<Absyn.Subscript> mod_exp;
algorithm
  mod_exp := matchcontinue(arg)
    local
      list<AbsynMat.Argument> arglst;
      Absyn.Exp exp;
      list<Absyn.Exp> mod_lst, mod_lst1;
      list<Absyn.Subscript> sub_lst;
      AbsynMat.Argument arg1;
      Absyn.Subscript sub;
     case(arg1::arglst)
      equation
        exp = argument(arg1,false);  
        mod_lst =  argument_lst(arglst,false);
        mod_lst1 = listAppend({exp},mod_lst);
        sub_lst = modExpLst(mod_lst1);       
      then  
        sub_lst;
    case(arg1::{})
      equation
        exp = argument(arg1,false);
        sub = Absyn.SUBSCRIPT(exp);
      then
        {sub};
    case({})
    then {Absyn.NOSUB()};
  end matchcontinue;
end array_lst;

public function sclr_ary
input String ary;
input list<Absyn.AlgorithmItem> alg_exp;
output Boolean tf;
output list<Absyn.AlgorithmItem> alg_exp_o;
algorithm
  (tf,alg_exp_o) := matchcontinue(ary,alg_exp)
  local
  list<Absyn.AlgorithmItem> alg_exp1;
  String ary1;
    case("matrix",alg_exp1)
    then (true,{});
    case("vector",alg_exp1)
    then (true,{});
    case("Integer",alg_exp1)
    then (false,alg_exp1);
    case("Real",alg_exp1)
    then (false,alg_exp1);
    case(ary1,alg_exp1)
    then (false,alg_exp1);         
end matchcontinue;
end sclr_ary;

public function sclr_ary_lst
input list<String> i_type;
input list<String> i_type2;
input list<Absyn.AlgorithmItem> alg_exp;
output Boolean tf;
output list<Absyn.AlgorithmItem> alg_exp2;
output list<String> o_type;
algorithm
  (tf,alg_exp2,o_type) := matchcontinue (i_type,i_type2,alg_exp)
  local
    list<String> type_lst,type_lst2;
    String d_type;
    Boolean tf1;
    list<Absyn.AlgorithmItem> alg_exp1;
    case(d_type::type_lst,type_lst2,alg_exp1)
      equation
       (tf1,alg_exp2) =  sclr_ary(d_type,alg_exp1);
      then (tf1,alg_exp2,type_lst2);
    case({},{},alg_exp1)
      then (false,alg_exp1,{});
  end matchcontinue;
end sclr_ary_lst; 


public function ary_decl
input Absyn.Exp mod_exp;
output list<Absyn.Subscript> sub_lst;
algorithm
  sub_lst := matchcontinue(mod_exp)
  local
    list<Absyn.Subscript> sub_lst1;
    list<Absyn.Exp> exp_lst;
    case(Absyn.ARRAY(exp_lst))
      equation
      sub_lst1 = modExpLst(exp_lst);
    then sub_lst1;
  end matchcontinue;
end ary_decl;

public function modification
  input AbsynMat.Expression exp;
  output String ary_ident;
  output Absyn.Modification modfic;
  output list<String> mtx_vec;
algorithm 
  (ary_ident,modfic,mtx_vec) := matchcontinue(exp)
    local
      AbsynMat.Expression exp1;
      list<Absyn.Exp> exp_lst;
      Absyn.Exp mod_exp;
      list<AbsynMat.Argument> arg1;
      AbsynMat.Operator op;
      list<Absyn.Subscript> sub_lst1;
      String ary_ident1;   
      list<String> mtx_vec1;  
      Absyn.Modification modfic1;
      Absyn.Info info;
     case(AbsynMat.ASSIGN_OP(arg1,op,exp1))
      equation
        (exp_lst,{ary_ident1}) = argument_lst(arg1,false);
        (mod_exp,mtx_vec1) = expression(exp1,"empty"::{},{});
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        modfic1 = Absyn.CLASSMOD({},Absyn.EQMOD(mod_exp,info));
      then
        (ary_ident1,modfic1,mtx_vec1);         
  end matchcontinue;
end modification;

public function arrayDim
  input AbsynMat.Expression exp;
  output String ary_ident;
  output list<Absyn.Subscript> sub_lst;
algorithm 
  (ary_ident,sub_lst) := matchcontinue(exp)
    local
      AbsynMat.Expression exp1;
      list<Absyn.Exp> exp_lst;
      Absyn.Exp mod_exp;
      list<AbsynMat.Argument> arg1;
      AbsynMat.Operator op;
      list<Absyn.Subscript> sub_lst1;
      String ary_ident1; 
      list<String> emt_str;     
     case(AbsynMat.ASSIGN_OP(arg1,op,exp1))
      equation
        (exp_lst,{ary_ident1}) = argument_lst(arg1,false);
      //  sub_lst1 =  array_lst(arg1);   ??
        (mod_exp,emt_str) = expression(exp1,"empty"::{},{});
        sub_lst1 = ary_decl(mod_exp);
      then
        (ary_ident1,sub_lst1);         
  end matchcontinue;
end arrayDim;

public function rmv_non_protected
input list<String> in1;
input list<String> in2;
output list<String> out1;
algorithm 
  out1 := matchcontinue(in1,in2)
   local 
     list<String> in_lst;
     list<String> in_lst2;
     list<String> types;
    case(in_lst,{})
    then {};
    case(in_lst,in_lst2)
      equation
        types = listAppend(in_lst,in_lst2);
      then types; 
  end matchcontinue;
end rmv_non_protected;

public function anon_fcn_handle
input list<AbsynMat.Argument> arg;
input AbsynMat.Expression exp;
output Boolean tf;
algorithm
  (tf) := matchcontinue(arg,exp)
  local
    AbsynMat.Expression exp1;
    list<AbsynMat.Parameter> prm_lst;
    list<AbsynMat.Argument> arg1;
    AbsynMat.Statement stmt;
    Absyn.Exp out;
    list<Absyn.Exp> arg_exp;
    list<String> ident, ident1, fname, all;
    case(arg1, AbsynMat.ANON_FCN_HANDLE(prm_lst,stmt))
      equation
        (arg_exp,fname) = argument_lst(arg1,false);
        (out,ident) = fnc_hdl_stmt(stmt);
        ident1 = Fnc_Handle.rmvKeywords_lst(ident);
        all = listAppend(fname,ident1);
      then (true);
    case(arg1,exp1)
      then (false);
  end matchcontinue;   
end anon_fcn_handle;

public function anon_fcn_handle_ept
input Boolean fnc_hdl_tf;
input list<Absyn.AlgorithmItem> alg_exp2;
input list<String> arg_ident;
input Boolean tf;
input list<String> types;
input list<String> fnc_hdl_ident;
output list<Absyn.AlgorithmItem> alg_exp2_o;
output list<String> arg_ident_o;
output Boolean tf_o;
output list<String> types_o;
output list<String> fnc_hdl_ident_o;
algorithm
  (alg_exp2_o,arg_ident_o,tf_o,types_o,fnc_hdl_ident_o) := matchcontinue(fnc_hdl_tf,alg_exp2,arg_ident,tf,types,fnc_hdl_ident)
    local
      list<Absyn.AlgorithmItem> alg_exp3;
      list<String> arg_ident1;
      Boolean tf1;
      list<String> types1, fnc_hdl_ident1;
    case(true,alg_exp3,arg_ident1,tf1,types1,fnc_hdl_ident1)  //if true send send only fnc hdl idents to stmt 
    then ({},{},false,{},fnc_hdl_ident1);  
    case(false,alg_exp3,arg_ident1,tf1,types1,fnc_hdl_ident1)
    then (alg_exp3,arg_ident1,tf1,types1,{});
  end matchcontinue;
end anon_fcn_handle_ept;

public function lhs_ident
input String ident;
output list<String> otype;
algorithm
  otype := matchcontinue(ident)
  local
    list<String> unkn;
    String ident1;
    case("Real")
    then({"Real"});
    case("Integer")
    then({"Integer"});  
    case("UPLUS")
    then({"UPLUS"});
    case("UMINUS")
    then({"UMINUS"});
    case("ADD")
    then({"ADD"});
    case("SUB")
    then({"SUB"});
    case("MUL")
    then({"MUL"});
    case("DIV")
    then({"DIV"});
    case("POW")
    then({"POW"});
    case("EXPR_LT")
    then({"EXPR_LT"});
    case("EXPR_LE")
    then({"EXPR_LE"});
    case("EXPR_EQ")
    then({"EXPR_EQ"});
    case("EXPR_GE")
    then({"EXPR_GE"});
    case("EXPR_GT")
    then({"EXPR_GT"});
    case("EXPR_NE")
    then({"EXPR_NE"});
    case("EMUL")    
    then({"EMUL"});
    case("EDIV")
    then({"EDIV"});
    case("EPOW")  
    then({"EPOW"});
    case("EXPR_AND") 
    then({"EXPR_AND"});     
    case("EXPR_OR")
    then({"EXPR_OR"});
    case("EXPR_AND_AND")
    then({"EXPR_AND_AND"});
    case("EXPR_OR_OR")
    then({"EXPR_OR_OR"});
    case("EXPR_NOT")
    then({"EXPR_NOT"});
    case(ident1)
      equation 
        unkn = listAppend({ident1},{"Unknown"});
    then(unkn);
  end matchcontinue;
end lhs_ident;

public function lhs_ident_lst
input list<String> ident_lst;
output list<String> otype;
algorithm
  otype := matchcontinue(ident_lst)
  local
    list<String> i_lst, ident_lst1, ident_lst2, ident_lst3;
    String ident;
    case(ident::ident_lst1)
     equation                    
      i_lst = lhs_ident(ident);                   
      ident_lst2 = lhs_ident_lst(ident_lst1);     
      ident_lst3 = listAppend(i_lst,ident_lst2);
    then ident_lst3;
    case({})
    then {};
  end matchcontinue;
end lhs_ident_lst;

public function assign_types_lst
input list<String> types;
input Boolean chk;
output list<String> otypes;
algorithm
  otypes := matchcontinue(types,chk)
  local
    list<String> types1, idtypes, idtypes1, idtypes2;
    String stype, stype1;
    case(stype::types1,false)
      equation
        idtypes1 = listAppend({stype},{"Unknown"});
        idtypes = lhs_ident_lst(types1);   
        idtypes2 = listAppend(idtypes1,idtypes);     
    then idtypes2;
    case(stype::types1,true)
    equation
      idtypes1 = listAppend({stype},{"Unknown"});
      idtypes2 = listAppend(idtypes1,types1);  
      then idtypes2;
    case({},false)
    then {};
  end matchcontinue;
end assign_types_lst;    

public function rhs_real 
  input Boolean rl;
  input Boolean int;
  output String otype;
algorithm
  otype := matchcontinue(rl,int)
    local
    case(true,true)
    then ("Real");  
    case(true,false)
    then ("Real");
    case(false,true)
    then ("Integer");
    case(false,false)
    //then ("Unknown");
    then ("Real");
  end matchcontinue;
end rhs_real;  

public function ident_typelst
input list<String> idtypes;
output list<String> odtypes;
algorithm
  odtypes := matchcontinue(idtypes)
  local
    list<String> idtypes1,idtypes2;
    String idtype,idtype2, dim;
    Boolean rl,int,vec,mtx,cvec;
    case(idtype::idtypes1)
      equation
    //   print("\n ident_typelst \n");
    //   print(anyString(idtypes1));
       rl = listMember("Real",idtypes1);
    //   print("\n ident_typelst real \n");
    //   print(anyString(rl));
       int = listMember("Integer",idtypes1);
    //   print("\n ident_typelst int \n");
    //   print(anyString(int));
       
       idtype2 = rhs_real(rl,int);
       idtypes2 = listAppend({idtype},{idtype2});
      then  idtypes2;
    case({})
    then {};
  end matchcontinue;   
end ident_typelst;

public function chk_bol
 input Boolean b1;
 input Boolean b2;
 input Boolean b3;
 output Boolean bout;
 algorithm
   bout := matchcontinue(b1,b2,b3)
     case(true,false,false)
     then true;
     case(false,true,false)
     then true;
     case(false,false,true)
     then true; 
     case(false,false,false)
     then false; 
   end matchcontinue;
end chk_bol;

public function chk_ary_scl
 input list<String> types;
 output Boolean chk;
 algorithm 
   chk := matchcontinue(types)
   local
     list<String> lst;
     Boolean b1,b2,b3,b4;
     case(lst)
       equation
      b1 = listMember("vector",lst);
      b2 = listMember("matrix",lst);
      b3 = listMember("column_vector",lst);
      b4 = chk_bol(b1,b2,b3);
      then b4;
   end matchcontinue;
end chk_ary_scl;

public function assign_operator
  input Option<AbsynMat.Expression> exp;
  input list<String> f_call;
  input list<String> fnc_hdl_ident_i;
  input list<String> io_lstun;
  output list<Absyn.AlgorithmItem> alg;  
  output list<String> agn_ident;
  output Boolean ary_true;
  output list<String> d_type_lst;
  output list<String> fnc_hdl_ident_o; //list of fnc hdl idents
algorithm 
  (alg,agn_ident,ary_true,d_type_lst,fnc_hdl_ident_o) := matchcontinue(exp,f_call,fnc_hdl_ident_i,io_lstun)
    local
      AbsynMat.Expression exp1, exp2, mat_exp;
      list<AbsynMat.Argument> arg1, arg2;
      Absyn.Exp exp3, exp4;
      Absyn.Algorithm alg3;
      AbsynMat.Operator op;
      list<Absyn.AlgorithmItem> alg_exp, alg_exp2, alg_exp3;
      Absyn.Info info;
      Option<AbsynMat.Expression> exp5;     
      list<String> idtypes, arg_ident, arg_ident1, var_lst1, f_call1, ary1, d_type, types, types1, fnc_hdl_ident;
      list<String> io_lstun1, fnc_hdl_ident1, fnc_hdl_ident2, itypes; 
      Boolean tf, fnc_hdl_tf, tf1, chk;
      list<Absyn.Subscript> mod_exp; 
      String mod_fname, mat_fname;
    case(SOME(AbsynMat.ASSIGN_OP(arg1,op,exp1)),f_call1,fnc_hdl_ident1,io_lstun1)
      equation
        (fnc_hdl_tf) = anon_fcn_handle(arg1,exp1); // confirm whether matlab expression is anonymous function or not
        ({exp3},arg_ident) = argument_lst(arg1,false); 
        (exp4,ary1) =  expression(exp1,f_call1,fnc_hdl_ident1);       
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        alg_exp = Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(exp3,exp4),NONE(),info)::{};       
        (tf,alg_exp2,d_type) = sclr_ary_lst(ary1,ary1,alg_exp); //tf = true if variable is Array else false        
        types = rmv_non_protected(arg_ident,ary1);  // remove all non protected variables.  
        chk = chk_ary_scl(types);     
        idtypes = assign_types_lst(types,chk); 
        itypes = ident_typelst(idtypes);
        (alg_exp3,arg_ident1,tf1,types1,fnc_hdl_ident2) = anon_fcn_handle_ept(fnc_hdl_tf,alg_exp2,arg_ident,tf,idtypes,fnc_hdl_ident1);           
      then
        (alg_exp3,arg_ident1,tf1,types1,fnc_hdl_ident2);           
    case(SOME(AbsynMat.FINISH_COLON_EXP(AbsynMat.INDEX_EXPRESSION(AbsynMat.IDENTIFIER(mat_fname),arg1)::{})),f_call1,fnc_hdl_ident1,io_lstun1)
      equation
        mod_fname = Mod_Builtin.builtIn(mat_fname);       
        ({exp3},arg_ident) = argument_lst(arg1,false);
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        alg_exp = Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(Absyn.CREF_IDENT(mod_fname,{}),Absyn.FUNCTIONARGS(exp3::{},{})),NONE(),info)::{};        
      then (alg_exp,arg_ident,false,{},{});
    case(NONE(),f_call1,fnc_hdl_ident1,io_lstun1)
     then ({},{},false,{},{});
  end matchcontinue;
end assign_operator;

public function trs_else_if
input AbsynMat.Elseif els_if;
input list<String> f_call;
output list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> mod_else_if;
output list<String> idents_rhs0;
algorithm
  (mod_else_if,idents_rhs0) := matchcontinue(els_if,f_call)
  local
    AbsynMat.Separator sep, sep2;
    AbsynMat.Expression exp;
    Absyn.Exp mod_exp;
    list<AbsynMat.Statement> stmtlst;
    Option<AbsynMat.Mat_Comment> cmt;
    list<Absyn.AlgorithmItem> mod_stmt;
    list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> mod_else_if1;
    list<String> f_call1, idents_rhs;
    case(AbsynMat.ELSEIF_CLAUSE (sep,exp,sep2,stmtlst,cmt),f_call1)
      equation
        mod_exp = expression(exp,f_call1,{});
        (mod_stmt,{},{},{},idents_rhs,{}) = stmt_lst(stmtlst,f_call1,{},{});
           
        mod_else_if1 = (mod_exp,mod_stmt)::{};             
                     
      then
        (mod_else_if1,idents_rhs);
  end matchcontinue;
end trs_else_if;

public function trs_else_ifs
input list<AbsynMat.Elseif> els_if;
input list<String> f_call;
output list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> mod_else_if;
output list<String> ident_rhs0;
algorithm
 (mod_else_if,ident_rhs0) := matchcontinue(els_if,f_call)
  local
  list<AbsynMat.Elseif> else_ifs;
  AbsynMat.Elseif else_if;
  list<Absyn.Exp> exp, exp2, exp3, exp4, exp_if1, exp_ifs, exp_if2;
  list<Absyn.AlgorithmItem> alg_itm1, alg_itms, alg_itm2;
  list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> mod_else_if1, mod_else_if2, mod_else_if3;
  list<String> f_call1,ident_rhs,ident_rhs1,ident_rhs2;
    case(else_if::else_ifs,f_call1)
      equation
     
    (mod_else_if1,ident_rhs) = trs_else_if(else_if,f_call1);
    (mod_else_if2,ident_rhs1) = trs_else_ifs(else_ifs,f_call1);
     ident_rhs2 = listAppend(ident_rhs,ident_rhs1);
     mod_else_if3 = listAppend(mod_else_if1,mod_else_if2);     
  then
    (mod_else_if3,ident_rhs2);      
    case({},f_call1) 
    then ({},{});
  end matchcontinue;
end trs_else_ifs;

public function iterator
  input String mod_exp;
  input list<AbsynMat.Expression> mod_exp1; 
  output list<Absyn.ForIterator> foriterator;
algorithm
  foriterator := matchcontinue(mod_exp, mod_exp1)
    local
    String mod_ident;
    list<String> f_call, arg_str;
    Option<Absyn.Exp> mod_exp3;
    Absyn.Exp mod_exp4;    
    list<AbsynMat.Expression> mat_exp;
    list<Absyn.ForIterator> foriterator1, foriterator2;
    list<AbsynMat.Argument> arg_lst;
    list<Absyn.Exp> mod_lst;
    
     case(mod_ident,AbsynMat.FINISH_COLON_EXP(AbsynMat.FINISH_MATRIX(AbsynMat.MATRIX(arg_lst)::{})::{})::{})  //transform for s = [1,2,3] to for s in {1,2,3}
      equation
        (mod_lst,arg_str) = argument_lst(arg_lst,false);
        mod_exp4 = Absyn.ARRAY(mod_lst);
        foriterator1 = Absyn.ITERATOR(mod_ident,NONE(),SOME(mod_exp4))::{};         
      then foriterator1;
     case(mod_ident,{})
      equation
        foriterator2 = Absyn.ITERATOR(mod_ident,NONE(),NONE())::{};
      then
        foriterator2;
     case(mod_ident,mat_exp)
      equation
      
        (mod_exp3,f_call) = expression_lst(mat_exp,{},{});
        foriterator1 = Absyn.ITERATOR(mod_ident,NONE(),mod_exp3)::{};        
      then        
      foriterator1;
     
    end matchcontinue;
end iterator;

public function swt_else_if
input Absyn.Exp mod_exp1;
input Absyn.Exp mod_exp2;
input Absyn.AlgorithmItem swt_stmt;
output list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> mod_else_ifs;
algorithm
  mod_else_ifs := matchcontinue(mod_exp1,mod_exp2,swt_stmt)
  local
  Absyn.Exp mod_exp11, mod_exp22, mod_els_if;
  Absyn.AlgorithmItem swt_stmt1;
  list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> mod_else_ifs2;
    case(mod_exp11,mod_exp22,swt_stmt1)
      equation
       
        mod_els_if = Absyn.BINARY(mod_exp11,Absyn.EQUAL(),mod_exp22);
        mod_else_ifs2 = (mod_els_if,{swt_stmt1})::{};       
     then 
       mod_else_ifs2;    
  end matchcontinue;
end swt_else_if;

public function swt_else_ifs
input Absyn.Exp mod_exp;
input list<Absyn.Exp> swt_exp_lst;
input list<Absyn.AlgorithmItem> swt_stmt_lst;
output list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> mod_else_ifs;
output list<Absyn.AlgorithmItem> else_stmt;
algorithm
(mod_else_ifs,else_stmt) := matchcontinue (mod_exp,swt_exp_lst,swt_stmt_lst)
local
  Absyn.Exp mod_exp1,mod_exp2;
  list<Absyn.Exp> mod_exp_lst1;
  Absyn.AlgorithmItem swt_stmt;
  list<Absyn.AlgorithmItem> swt_stmt_lst1, swt_stmt_lst2;
  list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> mod_else_ifs2, mod_else_ifs3, mod_else_ifs4;
  list<String> a,b;
  case(mod_exp1,mod_exp2::mod_exp_lst1,swt_stmt::swt_stmt_lst1)
  equation
    
    mod_else_ifs2 = swt_else_if(mod_exp1,mod_exp2,swt_stmt);
    (mod_else_ifs3,swt_stmt_lst2) = swt_else_ifs(mod_exp1,mod_exp_lst1,swt_stmt_lst1);
    mod_else_ifs4 = listAppend(mod_else_ifs2,mod_else_ifs3);    
  then (mod_else_ifs4,swt_stmt_lst2);
  case(mod_exp1,{},swt_stmt_lst1)
    equation
  then ({},swt_stmt_lst1);  
  case(mod_exp1,{},{})    
  then ({},{});
  end matchcontinue;
end swt_else_ifs;  

public function switch
input AbsynMat.Switch_Case swt;
output list<Absyn.Exp> exp_lst;
output list<Absyn.AlgorithmItem> mod_lst;
output list<String> idents_rhs;
algorithm
  (exp_lst,mod_lst,idents_rhs) := matchcontinue(swt)
  local
    AbsynMat.Separator sep;
    AbsynMat.Expression exp;
    AbsynMat.Separator sep2;
    list<AbsynMat.Statement> stmt_list;
    Option<AbsynMat.Mat_Comment> m_cmt;
    list<Absyn.AlgorithmItem> mod_if_stmt;
    Absyn.Exp mod_if_exp;
    list<String> idents_rhs1;
    case(AbsynMat.SWITCH_CASE(sep,exp,sep2,stmt_list,m_cmt))
    equation
    mod_if_exp  = expression(exp,{},{});
    (mod_if_stmt,{},{},{},idents_rhs1,{}) = stmt_lst(stmt_list,{},{},{});
    then ({mod_if_exp},mod_if_stmt,idents_rhs1);
    case(AbsynMat.DEFAULT_CASE(sep,stmt_list,m_cmt))
    equation
    (mod_if_stmt,{},{},{},idents_rhs1,{}) = stmt_lst(stmt_list,{},{},{});      
    then ({},mod_if_stmt,idents_rhs1);
  end matchcontinue;
end switch;

public function switch_lst
input list<AbsynMat.Switch_Case> swt_lst;
output list<Absyn.Exp> exp;
output list<Absyn.AlgorithmItem> mod_lst;
output list<String> idents_rhs;
algorithm 
  (exp,mod_lst,idents_rhs) := matchcontinue(swt_lst)
  local
    list<AbsynMat.Switch_Case> swt_lst1;
    list<Absyn.Exp> exp_lst,exp_lst2,exp_lst3;
    list<Absyn.AlgorithmItem> mod_lst2,mod_lst3,mod_lst4;
    list<String> idents_rhs1, idents_rhs2, idents_rhs3;
    AbsynMat.Switch_Case swt;
    case(swt::swt_lst1)
      equation
    (exp_lst,mod_lst2,idents_rhs1) = switch(swt);
    (exp_lst2,mod_lst3,idents_rhs2) = switch_lst(swt_lst1);
    exp_lst3 = listAppend(exp_lst,exp_lst2);
    mod_lst4 = listAppend(mod_lst2,mod_lst3);
    idents_rhs3 = listAppend(idents_rhs1,idents_rhs2);
  then (exp_lst3, mod_lst4,idents_rhs3);
    case({})
    then ({},{},{});
  end matchcontinue;
end switch_lst;

public function switch_tpl
input tuple<list<AbsynMat.Switch_Case>, Option<AbsynMat.Switch_Case>> swcse_lst; 
output list<Absyn.Exp> exp;
output list<Absyn.AlgorithmItem> mod_lst;
output list<String> idents_rhs;
algorithm 
  (exp,mod_lst,idents_rhs) := matchcontinue(swcse_lst)
    local
    list<AbsynMat.Switch_Case> swt_lst;
    AbsynMat.Switch_Case swt_op;
    list<Absyn.Exp> exp1,exp2,exp3;
    list<Absyn.AlgorithmItem> mod_lst1,mod_lst2,mod_lst3;
    list<String> idents_rhs1, idents_rhs2, idents_rhs3;
    tuple<list<AbsynMat.Switch_Case>, Option<AbsynMat.Switch_Case>> swcse_lst1;
    case(swcse_lst1)
      equation
        (swt_lst,SOME(swt_op)) = swcse_lst1;
        (exp1,mod_lst1,idents_rhs1) = switch_lst(swt_lst);
        (exp2,mod_lst2,idents_rhs2) = switch(swt_op);
        idents_rhs3 = listAppend(idents_rhs1, idents_rhs2);
        exp3 = listAppend(exp1,exp2);
        mod_lst3 = listAppend(mod_lst1,mod_lst2);
      then (exp3,mod_lst3,idents_rhs3);
 end matchcontinue;
end switch_tpl;

public function command
input Option<AbsynMat.Command> cmd;
input list<String> f_call;
input list<String> fnc_hdl_ident;
output list<Absyn.AlgorithmItem> alg;
output list<String> for_ident;
output list<String> asg_ident;
output list<String> idents_rhs0;
algorithm
  (alg,for_ident,asg_ident,idents_rhs0) := matchcontinue(cmd,f_call,fnc_hdl_ident)
  local
    list<AbsynMat.Argument> arg;
    AbsynMat.Expression exp1, w_exp, if_ex, swt_ex;
    Option<AbsynMat.Separator> sep, w_sep, if_sep2;
    AbsynMat.Separator if_sep, swt_sep;
    list<AbsynMat.Elseif> else_ifs;
    list<AbsynMat.Statement> mat_stmt, w_stmt, if_stmt, if_stmt2, mat_stmt_out;
    Option<AbsynMat.Mat_Comment> m_cmt_lst, w_cmt_lst, if_cmt_lst, if_cmt_lst2;
    Absyn.Algorithm mod_while;
    list<Absyn.AlgorithmItem> mod_alg, mod_stmt, mod_w_stmt, mod_w_stmt1, mod_if_stmt, mod_if_stmt2, swt_stmt_lst, swt_stmt_lst2, mod_else;
    Absyn.Exp mod_exp1,mod_w_exp, mod_if_exp, mod_exp2, swt_exp;
    Absyn.AlgorithmItem swt_stmt;
    list<Absyn.Exp> swt_exp_lst, swt_exp_lst2;
    String in_ident;
    Absyn.Info info;
    list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> mod_else_if;
    list<Absyn.ForIterator> foriterator;
    list<String> for_ident1, for_ident2, asg_ident1, f_call1, fnc_hdl_ident1;
    tuple<list<AbsynMat.Switch_Case>, Option<AbsynMat.Switch_Case>> swcse_lst; 
    list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> mod_else_ifs;
    list<AbsynMat.Expression> exp_lst1, no_exp;
    list<String> idents_rhs, idents_rhs1, idents_rhs2, idents_rhs3, idents_rhs4, no_str, no_str1, no_for;
    Boolean bool_loop;
    case(SOME(AbsynMat.FOR_COMMAND(arg,exp1,sep,mat_stmt,m_cmt_lst)),f_call1,fnc_hdl_ident1)
      equation
        in_ident = for_ident(arg,NONE());
      
      //  (exp_lst1,mat_stmt_out,bool_loop) = Fnc_Handle.stmt_lst(mat_stmt,SOME(in_ident),false);
        
        (mod_stmt,for_ident2,asg_ident1,no_exp,idents_rhs,no_str) = stmt_lst(mat_stmt,f_call1,fnc_hdl_ident1,{});
        foriterator = iterator(in_ident,{exp1});
        info=SOURCEINFO("",false,0,0,0,0,0.0);        
        mod_alg = Absyn.ALGORITHMITEM(Absyn.ALG_FOR(foriterator,mod_stmt),NONE(),info)::{};
        for_ident1 = listAppend(for_ident2,{in_ident});
      then
        (mod_alg, for_ident1,asg_ident1,idents_rhs);
    case(SOME(AbsynMat.WHILE_COMMAND(w_exp,w_sep,w_stmt,w_cmt_lst)),f_call1,fnc_hdl_ident1)
      equation
        mod_w_exp = expression(w_exp,f_call1,fnc_hdl_ident1);
        (mod_w_stmt,no_for,no_str,no_exp,idents_rhs,no_str1) = stmt_lst(w_stmt,f_call1,fnc_hdl_ident1,{});
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        mod_alg = Absyn.ALGORITHMITEM(Absyn.ALG_WHILE(mod_w_exp,mod_w_stmt),NONE(),info)::{};
      then
       (mod_alg, {}, {},idents_rhs);
    case(SOME(AbsynMat.IF_COMMAND (if_ex,if_sep,if_stmt,{},NONE(),{},if_cmt_lst, NONE())),f_call1, fnc_hdl_ident1)
      equation
        mod_if_exp  = expression(if_ex,f_call1,fnc_hdl_ident1);
       
        (mod_if_stmt,no_for,no_str,no_exp,idents_rhs,no_str1) = stmt_lst(if_stmt,f_call1,fnc_hdl_ident1,{});
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        mod_alg = Absyn.ALGORITHMITEM(Absyn.ALG_IF(mod_if_exp,mod_if_stmt,{},{}),NONE(),info)::{};  
                
      then
        (mod_alg, {},{},idents_rhs);
    case(SOME(AbsynMat.IF_COMMAND (if_ex,if_sep,if_stmt,{},if_sep2,if_stmt2 ,if_cmt_lst,if_cmt_lst2)),f_call1,fnc_hdl_ident1)
      equation  
             
        mod_if_exp  = expression(if_ex,f_call1,fnc_hdl_ident1);
       
        (mod_if_stmt,no_for,no_str,no_exp,idents_rhs,no_str1) = stmt_lst(if_stmt,f_call1,fnc_hdl_ident1,{});
        (mod_if_stmt2,no_for,no_str,no_exp,idents_rhs2,no_str1) = stmt_lst(if_stmt2,f_call1,fnc_hdl_ident1,{});
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        mod_alg = Absyn.ALGORITHMITEM(Absyn.ALG_IF(mod_if_exp,mod_if_stmt,{},mod_if_stmt2),NONE(),info)::{}; 
        idents_rhs3 = listAppend(idents_rhs,idents_rhs2);
      then
        (mod_alg, {},{},idents_rhs3); 
      case(SOME(AbsynMat.IF_COMMAND (if_ex,if_sep,if_stmt,else_ifs,if_sep2,if_stmt2,if_cmt_lst,if_cmt_lst2)),f_call1,fnc_hdl_ident1)
      equation     
        
        mod_if_exp  = expression(if_ex,f_call1,fnc_hdl_ident1);
        (mod_if_stmt,no_for,no_str,no_exp,idents_rhs,no_str1) = stmt_lst(if_stmt,f_call1,fnc_hdl_ident1,{});      
        (mod_else_if,idents_rhs1) = trs_else_ifs(else_ifs,f_call1);
         idents_rhs2 = listAppend(idents_rhs,idents_rhs1);
        (mod_if_stmt2,no_for,no_str,no_exp,idents_rhs3,no_str1) = stmt_lst(if_stmt2,f_call1,fnc_hdl_ident1,{});
        idents_rhs4 = listAppend(idents_rhs3,idents_rhs2);
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        mod_alg = Absyn.ALGORITHMITEM(Absyn.ALG_IF(mod_if_exp,mod_if_stmt,mod_else_if,mod_if_stmt2),NONE(),info)::{};      
      then
        (mod_alg,{},{},idents_rhs4); 
    case(SOME(AbsynMat.SWITCH_COMMAND(swt_ex,swt_sep,swcse_lst,if_cmt_lst)),f_call1,fnc_hdl_ident1)  
      equation
        
        mod_exp1  = expression(swt_ex,f_call1,fnc_hdl_ident1);      
        (swt_exp_lst,swt_stmt_lst,idents_rhs1) = switch_tpl(swcse_lst);
        swt_exp::swt_exp_lst2 = swt_exp_lst;      
        swt_stmt::swt_stmt_lst2 = swt_stmt_lst;
        mod_if_exp = Absyn.BINARY(mod_exp1,Absyn.EQUAL(),swt_exp);
        (mod_else_ifs,mod_else) = swt_else_ifs(mod_exp1,swt_exp_lst2,swt_stmt_lst2);
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        mod_alg = Absyn.ALGORITHMITEM(Absyn.ALG_IF(mod_if_exp,{swt_stmt},mod_else_ifs,mod_else),NONE(),info)::{};         
      then 
        (mod_alg,{},{},{});
    case(SOME(AbsynMat.BREAK_COMMAND()),f_call1,fnc_hdl_ident1)
      equation 
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        mod_alg = Absyn.ALGORITHMITEM(Absyn.ALG_BREAK(),NONE(),info)::{}; 
      then    
        (mod_alg,{},{},{});
    case(SOME(AbsynMat.RETURN_COMMAND()),f_call1,fnc_hdl_ident1)
      equation
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        mod_alg = Absyn.ALGORITHMITEM(Absyn.ALG_RETURN(),NONE(),info)::{}; 
      then
        (mod_alg, {},{},{});
    case(NONE(),f_call1,fnc_hdl_ident1)
    then ({},{},{},{});
  end matchcontinue;
end command;

public function mtx_vtr
  input Boolean tf;
  input Option<AbsynMat.Expression> exp;
  input list<String> ident;
  output list<AbsynMat.Expression> exp_out;
  output list<String> ident1;
algorithm
    (exp_out,ident1) := matchcontinue(tf,exp,ident)
      local
    Option<AbsynMat.Expression> exp1;
        AbsynMat.Expression exp2;
        list<AbsynMat.Expression> exp_lst;
        list<String> ident2;
      case(true,exp1,ident2)  
        equation
          SOME(exp2) = exp1;
          exp_lst = {exp2};            
        then (exp_lst,{});  
      case(false,exp1,ident2)
    then ({},ident2);
  end matchcontinue;
end mtx_vtr;

public function stmt
  input AbsynMat.Statement stmt;
  input list<String> f_call;
  input list<String> fnc_hdl;
  input list<String> io_lstun;
  output list<Absyn.AlgorithmItem> outclasspart;
  output list<String> for_ident;
  output list<String> asg_ident;
  output list<AbsynMat.Expression> exp_lst;
  output list<String> d_type_lst;
  output list<String> fnc_hdl_idents_o;
algorithm
  (outclasspart,for_ident,asg_ident,exp_lst,d_type_lst,fnc_hdl_idents_o) := matchcontinue(stmt, f_call,fnc_hdl,io_lstun)
    local
      Option<AbsynMat.Expression> exp;
      list<AbsynMat.Expression> exp1, exp2;
      Option<AbsynMat.Command> cmd;
      Option<AbsynMat.Start> fnc_str;
      Option<AbsynMat.Mat_Comment> m_cmt;
      Option<AbsynMat.Separator> sep_op;
      AbsynMat.Separator sep;
      list<AbsynMat.Statement> stmt_lst;
      Absyn.Algorithm asg_exp, mod_cmd;
      Absyn.Info info;
      list<Absyn.AlgorithmItem> alg_lst, alg_lst1, alg_exp, alg_cmd, alg_exp9;
      Absyn.Exp mod_exp;
      list<String> io_lstun1, for_ident1, for_ident2, asg_ident1, asg_ident2, asg_ident3, asg_ident4, fnc_hdl_idents;
      list<String> idents_rhs, idents_rhs1, itypes, var_lst1, f_call1, f_call2, asg_ident9, asg_ident4, d_type, d_type0, d_type1, d_type2, fnc_hdl_idents_i;
      Boolean ary, fnc_hdl_tf, fnc_hdl_tf1;
    case(AbsynMat.STATEMENT_APPEND(AbsynMat.STATEMENT(cmd,exp,fnc_str,m_cmt),sep),f_call1,fnc_hdl_idents_i,io_lstun1)
      equation
        //(alg_exp9,asg_ident9,fnc_hdl_tf) = assign_operator(exp,f_call1);  //alg_exp9, asg_ident9 extra
        //(alg_exp9,asg_ident9,ary,d_type,fnc_hdl_idents) = assign_operator(exp,f_call1,fnc_hdl_idents_i);  //alg_exp9, asg_ident9 extra
        (alg_exp,asg_ident1,ary,d_type,fnc_hdl_idents) = assign_operator(exp,f_call1,fnc_hdl_idents_i,io_lstun1);
        (exp1,asg_ident4) = mtx_vtr(ary,exp,asg_ident1);  
        (alg_cmd,for_ident1,asg_ident2,d_type0) = command(cmd,f_call1,fnc_hdl_idents_i);  
        d_type1 = listAppend({"nStatement"},d_type0);
        d_type2 = listAppend(d_type,d_type1);
        alg_lst = listAppend(alg_exp,alg_cmd);
        asg_ident3 = listAppend(asg_ident4,asg_ident2);          
      then  
        (alg_lst,for_ident1,asg_ident3,exp1,d_type2,fnc_hdl_idents);    
      end matchcontinue;
end stmt;

public function stmt_lst
  input list<AbsynMat.Statement> stmtlst;
  input list<String> f_call;
  input list<String> fnc_hdl_ident_i;  
  input list<String> io_lstun;
  output list<Absyn.AlgorithmItem> outclasspart;
  output list<String> for_ident;
  output list<String> asg_ident;
  output list<AbsynMat.Expression> exp_lst;
  output list<String> d_type_lst;
  output list<String> fnc_hdl_ident_o;  
algorithm
  (outclasspart,for_ident, asg_ident,exp_lst,d_type_lst,fnc_hdl_ident_o) := matchcontinue(stmtlst, f_call,fnc_hdl_ident_i,io_lstun)
    local
      list<AbsynMat.Statement> stmtlst1, stmtlst2;
      AbsynMat.Statement stmt1;
      list<Absyn.AlgorithmItem> alg_itm, alg_lst, alg_lst2, alg_lst3, alg_itm, alg_itm2;
      list<String> for_ident1, for_ident2, for_ident3, for_ident4, asg_ident1, asg_ident2, asg_ident3, asg_ident4, var_lst1;
      list<String> io_lstun1, f_call1, d_type, d_type0, d_type1, d_type2, d_type3, fnc_hdl_idents, fnc_hdl_idents1, fnc_hdl_idents2, fnc_hdl;
      list<AbsynMat.Expression> exp_lst1,exp_lst2,exp_lst3,exp_lst4;
      Boolean fnc_hdl_tf, fnc_hdl_tf1;
    case(stmt1::stmtlst1,f_call1,fnc_hdl,io_lstun1)
      equation 
        (alg_itm,for_ident1,asg_ident1,exp_lst1,d_type,fnc_hdl_idents) = stmt(stmt1,f_call1,fnc_hdl,io_lstun);
        (alg_lst,for_ident2,asg_ident2,exp_lst2,d_type0,fnc_hdl_idents1)  = stmt_lst(stmtlst1,f_call1,fnc_hdl,io_lstun);
        for_ident3 = listAppend(for_ident1,for_ident2);
        asg_ident3 = listAppend(asg_ident1,asg_ident2);
        alg_lst2 = listAppend(alg_itm,alg_lst);
        exp_lst3 = listAppend(exp_lst1,exp_lst2);   
        d_type1 = listAppend({"nStatement"},d_type0);
        d_type2 = listAppend(d_type,d_type1);         
        fnc_hdl_idents2 = listAppend(fnc_hdl_idents,fnc_hdl_idents1); 
      then  
        (alg_lst2,for_ident3,asg_ident3,exp_lst3,d_type2,fnc_hdl_idents2);
    case({},f_call1,fnc_hdl_idents2,io_lstun1)
    then ({},{},{},{},{},{});  
  end matchcontinue;
end stmt_lst;

public function scl_ary_type
 input String identtype;
 input String typ;
 input String dim0;
 input String dim;
 input String ident;
 output list<Absyn.Subscript> subscp;
 algorithm
  subscp := matchcontinue(identtype,typ,dim0,dim,ident)
   local
     list<Absyn.Subscript> subscp1, subscp2, subscp3;
     String dim1, dim2, ident1, typ1;
     Integer intdim, intdim2;
     case("Scalar",typ1,dim1,dim2,ident1)
      then {};
     case("vector",typ1,dim1,dim2,ident1)    // "vector","Integer"
       equation
         intdim = stringInt(dim1);
         subscp1 = Absyn.SUBSCRIPT(Absyn.INTEGER(intdim))::{};
         then subscp1;
     case("vector","Real",dim1,dim2,ident1)
      equation
         intdim = stringInt(dim1);
         subscp1 = Absyn.SUBSCRIPT(Absyn.INTEGER(intdim))::{};
         then subscp1;
     case("matrix",typ1,dim1,dim2,ident1) //"matrix","Integer"
     equation
         intdim = stringInt(dim1);
         intdim2 = stringInt(dim2);
         subscp1 = Absyn.SUBSCRIPT(Absyn.INTEGER(intdim2))::{};
         subscp2 = Absyn.SUBSCRIPT(Absyn.INTEGER(intdim))::{};
         subscp3 = listAppend(subscp1,subscp2);
         then subscp3;
     case("matrix","Real",dim1,dim2,ident1)
     equation
         intdim = stringInt(dim1);
         intdim2 = stringInt(dim2);
         subscp1 = Absyn.SUBSCRIPT(Absyn.INTEGER(intdim))::{};
         subscp2 = Absyn.SUBSCRIPT(Absyn.INTEGER(intdim2))::{};
         subscp3 = listAppend(subscp1,subscp2);
         then subscp3;
     case("column_vector",typ1,dim1,dim2,ident1)  //"column_vector","Integer"
     equation
         intdim = stringInt(dim2);
         subscp1 = Absyn.SUBSCRIPT(Absyn.INTEGER(intdim))::{};
         subscp2 = Absyn.SUBSCRIPT(Absyn.INTEGER(1))::{};
         subscp3 = listAppend(subscp1,subscp2);
         then subscp3;
     case("column_vector","Real",dim1,dim2,ident1) 
        equation
         intdim = stringInt(dim2);
         subscp1 = Absyn.SUBSCRIPT(Absyn.INTEGER(intdim))::{};
         subscp2 = Absyn.SUBSCRIPT(Absyn.INTEGER(1))::{};
         subscp3 = listAppend(subscp1,subscp2);
         then subscp3;      
   end matchcontinue;
end scl_ary_type;

public function match_type
 input Boolean tf;
 input String ident;
 input list<String> all_idents;
 input list<String> appident;
 output list<String> typ;
 output list<String> all_idents_o;
 output list<Absyn.Subscript> subscp;
 algorithm
   (typ,all_idents_o,subscp) := matchcontinue(tf,ident,all_idents,appident)
     local
     String typ1,ident1, identtype, dim, dim2;
     list<String> all_idents1, appident1;
     list<Absyn.Subscript> subscp1;
       case(true,ident1,typ1::all_idents1,appident1)
         equation
             identtype = listGet(appident1,4);
             dim = listGet(appident1,2);
             dim2 = listGet(appident1,3);
             
             subscp1 = scl_ary_type(identtype,typ1,dim,dim2,ident1);
            
       then ({typ1},{},subscp1);
       case(false,ident1,all_idents1,appident1)        
       then ({ident1},all_idents1,{});
   end matchcontinue;    
end match_type;
 
public function match_ident_type
 input String ident;
 input list<String> all_idents;
 input list<String> appident;
 output list<String> typ;
 output list<Absyn.Subscript> subscp;
algorithm
  (typ,subscp) := matchcontinue(ident,all_idents,appident)
 local
   String ident1,ident2;
   list<String> ident3, ident4, ident5, appident1,appident2,all_idents1, all_idents2, all_idents3;
   Boolean tf;
   list<Absyn.Subscript> subscp1, subscp2, subscp3;
   case(ident1,{},appident1)
     then ({},{});
   case(ident1,ident2::all_idents1,appident1)
     equation
       appident2 = listAppend({ident2},appident1);
       tf = stringEqual(ident1,ident2);
       (ident3,all_idents2,subscp1) = match_type(tf,ident1,all_idents1,appident2);    
       (ident4,subscp2) = match_ident_type(ident1,all_idents2,appident2);
       ident5 = listAppend(ident3,ident4); 
       subscp3 = listAppend(subscp1,subscp2);       
       then (ident5,subscp3);
  end matchcontinue;
end match_ident_type;

public function output_type
 input String ident;
 input list<String> all_idents;
 output list<String> typ;
 output list<Absyn.Subscript> subscp;
 algorithm 
   (typ,subscp) := matchcontinue (ident, all_idents)
   local
     String ident1;
     list<String> all_idents1, typ1;
     list<Absyn.Subscript> subscp1;
     case(ident1, all_idents1)
       equation 
        (typ1,subscp1) = match_ident_type(ident1,all_idents1,{});        
       then 
         (typ1,subscp1); 
   end matchcontinue;
end output_type;

public function ret_typ
 input list<String> typ;
 output String data_type;
 algorithm
   data_type := matchcontinue(typ)
  local
    String data_type1;
    list<String> typ1, lstRev;
    case({})
      then "empty";  
    case(typ1)
      equation
        lstRev = listReverse(typ1);        
        data_type1 = listGet(lstRev,1);
      then data_type1;
 end matchcontinue;
end ret_typ;

public function create_out
  input AbsynMat.Decl_Elt ret;
  input Boolean tf;
  input list<String> all_idents;
  output list<Absyn.ElementItem> outclasspart;
  output String in_out_ident;
algorithm
  (outclasspart,in_out_ident) := matchcontinue(ret,tf,all_idents)
    local
      Absyn.ElementAttributes attr, attr1;
      Absyn.TypeSpec tSpec, tSpec1;
      list<Absyn.ElementItem> eli;
      list<Absyn.ComponentItem> com, com1;
      Absyn.ClassPart in1, out1;
      Absyn.Info info, info1; 
      AbsynMat.Ident ident;
      String in_put, out_put, data_type, testcomment, testcomment2;    
      list<String> all_idents1, typ, typ1;
      Integer lth;
      list<Absyn.Subscript> subscp1;
    case(AbsynMat.DECL(ident,NONE()),true,all_idents1)
      equation
        in_put = ident;
        attr = Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.VAR(), Absyn.INPUT(),Absyn.NONFIELD(),{});
        tSpec = Absyn.TPATH(Absyn.IDENT("Real"),NONE());
        com = Absyn.COMPONENTITEM(Absyn.COMPONENT(in_put,{},NONE()),NONE(),NONE())::{};
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        eli = Absyn.ELEMENTITEM((Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),Absyn.COMPONENTS(attr,tSpec,com),info,NONE())))::{};
      then 
        (eli,ident); 
     case(AbsynMat.DECL(ident,NONE()),false,all_idents1)
      equation
        testcomment2 =  "Translator generated data type " ;
        //testcomment2 = trimquotes(testcomment);
        (typ,subscp1) = output_type(ident,all_idents);
        data_type = ret_typ(typ);      
        out_put = ident;
        attr1 = Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.VAR(), Absyn.OUTPUT(),Absyn.NONFIELD(),{});
        tSpec1 = Absyn.TPATH(Absyn.IDENT("Real"),NONE());
        com1 = Absyn.COMPONENTITEM(Absyn.COMPONENT(out_put,subscp1,NONE()),NONE(),SOME(Absyn.COMMENT(NONE(),SOME(testcomment2))))::{};
        info1=SOURCEINFO("",false,0,0,0,0,0.0);
        eli = Absyn.ELEMENTITEM((Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),Absyn.COMPONENTS(attr1,tSpec1,com1),info1,NONE())))::{};
      then 
        (eli,ident); 
     case(_,_,_)
       then
         ({},"");   
  end matchcontinue;
end create_out;

public function trimquotes
  input String inString;
  output String outString;
algorithm
  outString := matchcontinue(inString)
    local
      String inString1, outString1;
    case(inString1)
      equation
        {outString1} = listDelete({inString1},1);
      then
        outString1;
  end matchcontinue;
end trimquotes;

/*
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
*/

public function create_in
 input AbsynMat.Parameter prm; 
 output list<Absyn.ElementItem> outspec;
 output list<String> io_lst;
algorithm
  (outspec,io_lst):= matchcontinue(prm)
    local
     list<AbsynMat.Decl_Elt> prm1;    
     list<Absyn.ElementItem> outspec1;
     list<String> io_lst1;
     case(AbsynMat.PARM(prm1))
      equation
        (outspec1,io_lst1) = create_out_list(prm1,true,{});            
      then 
        (outspec1,io_lst1);       
  end matchcontinue;
end create_in;

public function create_in_list
 input list<AbsynMat.Parameter> prm;
output list<Absyn.ElementItem> outspec;
output list<String> io_lst;
algorithm
  (outspec,io_lst):= matchcontinue(prm)
    local
     list<AbsynMat.Parameter> prm2;
     AbsynMat.Parameter prm1;    
     list<Absyn.ElementItem> outspec1, outspec2, out;
     list<String> io_lst1, io_lst2, io_lst3;
     case(prm1::prm2)
      equation
        //print("\n create_in_list prm1::prm2");
        (outspec1,io_lst1) = create_in(prm1);
        (outspec2,io_lst2) = create_in_list(prm2);
        io_lst3 = listAppend(io_lst1,io_lst2);  
        out = listAppend(outspec1,outspec2);          
      then 
        (out,io_lst3);     
     case({})                
     then ({},{});  
  end matchcontinue;
end create_in_list;


public function create_out_list
 input list<AbsynMat.Decl_Elt> retlst;
 input Boolean bln; 
 input list<String> all_idents;
 output list<Absyn.ElementItem> outspec;
 output list<String> io_lst;
algorithm
  (outspec,io_lst) := matchcontinue(retlst,bln,all_idents)
    local
     list<AbsynMat.Decl_Elt> retlst1;
     AbsynMat.Decl_Elt ret;     
     list<Absyn.ElementItem> out, eli, eli2;
     Boolean bln1;
     String in_out_ident;
     list<String> io_lst1, io_lst2, all_idents1;
     case(ret::retlst1,bln1,all_idents1)
      equation
        //print("\n create_out_list ret::retlst1,bln1");       
        (eli,in_out_ident) = create_out(ret,bln1,all_idents1);   
        (eli2,io_lst1) = create_out_list(retlst1,bln1,all_idents);   
        io_lst2 = listAppend(io_lst1,in_out_ident::{});            
        out = listAppend(eli,eli2);                
      then 
        (out,io_lst2);   
     case({},bln1,all_idents1)                
       then ({},{});            
  end matchcontinue;
end create_out_list;

public function array_rmv
input String ident;
input list<String> lst;
output String ident1;
algorithm
  ident1 := matchcontinue(ident,lst)
  local
    String ident2;
    list<String> lst1;
    case("matrix",ident2::lst1)
    then ident2;
    case("vector",ident2::lst1)
    then ident2;
    case(ident2,lst1)
    then ident2;
    case(ident2,{})
    then ident2;  
      end matchcontinue;
end array_rmv;

public function var_match
input Boolean tf;
input list<String> type_lst;
output list<String> d_type;
algorithm
d_type := matchcontinue(tf,type_lst)
      local
        Boolean tf1;
        list<String> type_lst1;
        String d_type1, d_type2;
        case(true,d_type1::type_lst1)
          equation
            //print("\n Check var_match true \n");  
            d_type2 = array_rmv(d_type1,type_lst1); //this fnc removes the matrix or vector string from list          
            //print(anyString(d_type2));
          then {d_type2};
        case(true,{})          
          then {};
        case(false,type_lst1)
          equation
            //print("\n Check var_match false \n");
          then {};
  end matchcontinue;
end var_match;


public function asg_type
input String ident;
input list<String> type_lst;
output list<String> ary_type;
algorithm
ary_type := matchcontinue(ident,type_lst)
local
  String ident1,ident2;
  list<String> type_lst1, ident3, ident4, ident5;
  Boolean tf;
  case(ident1,ident2::type_lst1)
    equation
      //print("\n Var Match \n");
      tf = stringEqual(ident1,ident2);
      ident3 = var_match(tf,type_lst1);
      ident4 = asg_type(ident1,type_lst1);
      ident5 = listAppend(ident3,ident4);
      /*print("\n Protected Var \n");
      print(anyString(ident1));
      print("\n Protected Type \n");
      print(anyString(ident5)); */
      then ident5;     
  case(ident1,{})
    then {};
    end matchcontinue;
end asg_type;

public function real_integer
  input Boolean chk_real;
  output String type_o;
algorithm
  type_o := matchcontinue(chk_real)
    local
      String type_o1;
    case(true)
    then "Real";
    case(false)
    then "Integer";
  end matchcontinue;
end real_integer;

public function prt_mtx_vec_type
input list<String> type_lst;
output String type_out;
algorithm
  type_out := matchcontinue(type_lst)
    local
      list<String> type_lst1;
      String type1, type2;
      Boolean chk_real;
    case(type1::type_lst1)  //doesn't handle 1,1,1.0, if list contain mix of Integer and Real
    equation
      chk_real = listMember("Real",type_lst1);
      type2 = real_integer(chk_real);
      then type2;
    case("Real"::type_lst1)
      then "Real"; 
  end matchcontinue;
end prt_mtx_vec_type;  

public function prt_mtx_vec
input list<String> ary_type;
input String ident;
input Absyn.Modification modfic;
input list<String> mtx_vec;
input list<String> all_idents;
output list<Absyn.ElementItem> eli;
algorithm
  eli := matchcontinue(ary_type,ident,modfic,mtx_vec,all_idents)
  local
    list<Absyn.ElementItem> eli1;
    String ary_type1, ident1, data_type;
    list<String> type_lst, ary_type_lst;
    Absyn.Modification modfic1;
    Absyn.ElementAttributes attr;
    Absyn.TypeSpec tSpec;    
    list<Absyn.ComponentItem> com;
    Absyn.Info info;
    list<String> all_idents1, typ;
    list<Absyn.Subscript> subscp1;
    case(ary_type1::ary_type_lst,ident1,modfic1,"vector"::type_lst,all_idents1)
      equation
        ary_type1 = prt_mtx_vec_type(type_lst);
        (typ,subscp1) = output_type(ident1,all_idents1);
        data_type = ret_typ(typ);        
        attr = Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.VAR(),Absyn.BIDIR(),Absyn.NONFIELD(),Absyn.NOSUB()::{});  // Absyn.NOSUB()::{} = Real[:] 
        tSpec = Absyn.TPATH(Absyn.IDENT(data_type),NONE());
        com = Absyn.COMPONENTITEM(Absyn.COMPONENT(ident1,{},SOME(modfic)),NONE(),NONE())::{}; //modification
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        eli = Absyn.ELEMENTITEM((Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),Absyn.COMPONENTS(attr,tSpec,com),info,NONE())))::{};
   
      then eli; 
   /* case(ary_type1::{},ident1,modfic1,"vector"::type_lst)
      equation
         print("\n Modification 2 Vector \n");
        ary_type1 = prt_mtx_vec_type(type_lst);
        attr = Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.VAR(),Absyn.BIDIR(),Absyn.NONFIELD(),Absyn.NOSUB()::{});  // Absyn.NOSUB()::{} = Real[:] 
        tSpec = Absyn.TPATH(Absyn.IDENT(ary_type1),NONE());
        com = Absyn.COMPONENTITEM(Absyn.COMPONENT(ident1,{},SOME(modfic)),NONE(),NONE())::{}; //modification
        info=Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));
        eli = Absyn.ELEMENTITEM((Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),Absyn.COMPONENTS(attr,tSpec,com),info,NONE())))::{};
   
      then eli; */
    case(ary_type1::ary_type_lst,ident1,modfic1,"matrix"::type_lst,all_idents1)
      equation
        (typ,subscp1) = output_type(ident1,all_idents1);
        data_type = ret_typ(typ);          
        ary_type1 = prt_mtx_vec_type(type_lst);
        attr = Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.VAR(),Absyn.BIDIR(),Absyn.NONFIELD(),{});
        tSpec = Absyn.TPATH(Absyn.IDENT(data_type),NONE());
        com = Absyn.COMPONENTITEM(Absyn.COMPONENT(ident1,subscp1,SOME(modfic)),NONE(),NONE())::{}; // Absyn.NOSUB() = Real[:,:] 
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        eli = Absyn.ELEMENTITEM((Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),Absyn.COMPONENTS(attr,tSpec,com),info,NONE())))::{};
   
      then eli;
  end matchcontinue;
end prt_mtx_vec;

public function typcheck
input String typ;
output String otyp;
algorithm
  otyp := matchcontinue(typ)
  local
    String typ1;
    case("Integer")
    then ("Integer");
    case("Real")
    then ("Real");
    case(typ1)
      equation
            //print("\n inside typecheck");
      then("Real");
    //then("Unknown"); 
  end matchcontinue;
end typcheck;

public function lsttostring
input list<String> ary_type;
output String prt_type;
algorithm
  prt_type := matchcontinue(ary_type)
  local
    list<String> ary_type1;
    String typ,typ2;
    case(typ::ary_type1)  
      equation
        typ2 = typcheck(typ);
    then typ2; 
    case(typ::{})
      equation
        typ2 = typcheck(typ);
    then typ2;     
    case({})
    //then ("Unknown");
      then ("Real");  
  end matchcontinue;  
end lsttostring;

public function protectTransform
input Option<String> ident;
input Option<AbsynMat.Expression> exp;
input list<String> type_lst;
input list<String> all_idents;
output list<Absyn.ElementItem> elitem;
algorithm
  elitem := matchcontinue(ident,exp,type_lst,all_idents)
  local
    list<Absyn.ElementItem> outspec;
    String ident1, ident2, ary_type1, data_type ,data_type1;
    list<String> typ, type_lst1, ary_type, mtx_vec, all_idents1;
    Absyn.ElementAttributes attr;
    Absyn.TypeSpec tSpec;
    list<Absyn.ElementItem> eli;
    list<Absyn.ComponentItem> com;
    Absyn.Info info; 
    AbsynMat.Expression exp1;
    Absyn.Modification modfic;  
    list<Absyn.Subscript> subscp1; 
    case(NONE(),SOME(exp1),type_lst1,all_idents1)  // Array
      equation
       
        (ident2,modfic,mtx_vec) = modification(exp1);
           
        ary_type = asg_type(ident2,type_lst1);
        
        eli = prt_mtx_vec(ary_type,ident2,modfic,mtx_vec,all_idents1);
      then
        eli;  
    case(SOME(ident1),NONE(),type_lst1,all_idents1)  // Scalar 
      equation
        (typ,subscp1) = output_type(ident1,all_idents1);
        data_type = ret_typ(typ); 
        data_type1=checkscalartype(data_type);
        ary_type = asg_type(ident1,type_lst1);
        ary_type1 = lsttostring(ary_type);
        attr = Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.VAR(),Absyn.BIDIR(),Absyn.NONFIELD(),{});
        tSpec = Absyn.TPATH(Absyn.IDENT(data_type1),NONE());
        com = Absyn.COMPONENTITEM(Absyn.COMPONENT(ident1,subscp1,NONE()),NONE(),NONE())::{};
        info=SOURCEINFO("",false,0,0,0,0,0.0);
        eli = Absyn.ELEMENTITEM((Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),Absyn.COMPONENTS(attr,tSpec,com),info,NONE())))::{};
      then
        eli;  
  end matchcontinue;
end protectTransform;

public function checkscalartype
input String instring;
output String outstring;
algorithm
  outstring :=matchcontinue(instring)
  local
    String str=instring;
    case("Integer") then "Integer";
    case ("Real") then "Real";
    case (str) then "Real";
    end matchcontinue;     
        
end checkscalartype;

public function protect_lst2  //function declaration for array constant only in protected e.g. Real C[1,2,3];
  input list<AbsynMat.Expression> exp_lst;
  input list<String> type_lst;
  input list<String> all_idents;
  output list<Absyn.ElementItem> outspec;
algorithm
  outspec := matchcontinue(exp_lst,type_lst,all_idents)
    local
    list<String> all_ident1, type_lst1;
    String ident;
    list<Absyn.ElementItem> outspec1, outspec2, outspec3;
    list<AbsynMat.Expression> exp_lst1;
    AbsynMat.Expression exp;
    list<String> all_idents1;
    case(exp::exp_lst1,type_lst1,all_idents1)
    equation
    
    outspec1 = protectTransform(NONE(),SOME(exp),type_lst1,all_idents1);
    outspec2 = protect_lst2(exp_lst1,type_lst1,all_idents1);
      outspec3 = listAppend(outspec1,outspec2);
    then (outspec3);
    case({},type_lst1,all_idents1)
    then ({});
  end matchcontinue;
end protect_lst2;

public function protect_lst  //function declaration for scalar constants only in protected e.g. Real C;
  input list<String> all_ident;
  input list<String> type_lst;
  input list<String> all_idents;
  output list<Absyn.ElementItem> outspec;
algorithm
  outspec := matchcontinue(all_ident,type_lst,all_idents)
    local
      list<String> all_ident1, type_lst1, all_idents1;
      String ident;
      list<Absyn.ElementItem> outspec1, outspec2, outspec3;
      list<AbsynMat.Expression> exp_lst1;
      AbsynMat.Expression exp;
    case(ident::all_ident1,type_lst1,all_idents1)
      equation
        outspec1 = protectTransform(SOME(ident),NONE(),type_lst1,all_idents1);        
        outspec2 = protect_lst(all_ident1,type_lst1,all_idents1);        
        outspec3 = listAppend(outspec1,outspec2);        
      then (outspec3);
    case({},type_lst1,all_idents1)
    then ({});
  end matchcontinue;
end protect_lst;

public function prtVariable
  input Boolean chk;
  input String prt_ident;
  output list<String> out_ident;
algorithm
  out_ident := matchcontinue(chk,prt_ident)
    local
      String prt_ident1;
    case(false,prt_ident1)
    then ({prt_ident1});
    case(true,prt_ident1)    
    then ({});
  end matchcontinue;
end prtVariable;

public function rmvIdent
  input String ident;
  input Boolean chk;
  output list<String> out;
algorithm 
  out := matchcontinue(ident,chk)
    local
      String ident1;
      Boolean chk1;
    case(ident1,false)
    then {ident1};
    case(ident1,true)      
    then ({});   
  end matchcontinue;
end rmvIdent;


public function rmvIdent2
  input String ident;
  input Boolean chk;
  output list<String> out;
algorithm 
  out := matchcontinue(ident,chk)
    local
      String ident1;
      Boolean chk1;
    case(ident1,false)
    then {ident1};
    case("vector",true)      
    then ({"vector"});
    case("matrix",true)      
    then ({"matrix"});
    case("Integer",true)      
    then ({"Integer"});
    case("Real",true)      
    then ({"Real"});        
    case(ident1,true)      
    then ({});   
  end matchcontinue;
end rmvIdent2;

public function rmvDuplicate
  input list<String> all;
  output list<String> out;
algorithm 
  out := matchcontinue(all)
    local
      list<String> lst_ident, lst_ident1, lst_ident2, lst_ident3;
      String ident;
      Boolean chk;
    case(ident::lst_ident)
      equation
        chk = listMember(ident,lst_ident);
        lst_ident1 = rmvIdent(ident,chk);
        lst_ident2 = rmvDuplicate(lst_ident);
        lst_ident3 = listAppend(lst_ident1, lst_ident2);
      then lst_ident3;
    case({})
    then ({});
  end matchcontinue;
end rmvDuplicate;

public function rmvDuplicate2
  input list<String> all;   //remove duplicate idents only,, not datatypes such as Integer, Real, vector, matrix
  output list<String> out;
algorithm 
  out := matchcontinue(all)
    local
      list<String> lst_ident, lst_ident1, lst_ident2, lst_ident3;
      String ident;
      Boolean chk;
    case(ident::lst_ident)
      equation
        chk = listMember(ident,lst_ident);
        lst_ident1 = rmvIdent2(ident,chk);
        lst_ident2 = rmvDuplicate2(lst_ident);
        lst_ident3 = listAppend(lst_ident1, lst_ident2);
      then lst_ident3;
    case({})
    then ({});
  end matchcontinue;
end rmvDuplicate2;

public function rmvInOut
  input list<String> all;
  input list<String> prt;
  output list<String> out;
algorithm 
  out := matchcontinue(all,prt)
    local
      list<String> lst_ident, lst_ident1, lst_ident2, lst_ident3, prt2;
      String ident;
      Boolean chk;
    case(ident::lst_ident,prt2)
      equation
        chk = listMember(ident,prt2);
        lst_ident1 = rmvIdent(ident,chk);
        lst_ident2 = rmvInOut(lst_ident,prt2);
        lst_ident3 = listAppend(lst_ident1, lst_ident2);
      then lst_ident3;
    case({},prt2)
    then ({});
  end matchcontinue;
end rmvInOut;

public function protectVariable
  input list<String> all_ident;
  input list<String> asg_ident;
  output list<String> prt_ident;
algorithm
  prt_ident := matchcontinue(all_ident,asg_ident)
    local
      list<String> all_ident1, asg_ident1, ident, prt_var, all_ident1, all_ident2, all;
      String asg_ident2, chk_ident;
      Boolean chk;
    case(all_ident1,asg_ident2::asg_ident1)
      equation
        chk = listMember(asg_ident2,all_ident1);
        prt_var = prtVariable(chk,asg_ident2);
        ident = protectVariable(all_ident1,asg_ident1);
        all_ident2 = listAppend(ident,prt_var);
        all = rmvDuplicate(all_ident2);
      then (all);
    case(all_ident1,{})
    then ({});
  end matchcontinue;
end protectVariable;

public function unknowntype
  input String io;
  output list<String> io_o;
 algorithm
   io_o := matchcontinue(io)
   local
     String io_i, io_i2;
     list<String> io_lst,io_lst2,io_lst3;
     case(io_i)
       equation
       //io_i2 = "Unknown";
       io_i2 = "Real";
       io_lst = {io_i2};
       io_lst2 = {io_i};
       io_lst3 = listAppend(io_lst,io_lst2);       
     then (io_lst3); 
   end matchcontinue;  
end unknowntype;

public function unknowntype_lst
 input list<String> io_lst;
 output list<String> io_olst;
 algorithm 
   io_olst := matchcontinue(io_lst)
   local
    list<String> io_lst1, io_lst2, io_lst3, io_lst4;
    String io;
     case(io::io_lst1)
       equation
       io_lst2 = unknowntype(io);
       io_lst3 = unknowntype_lst(io_lst1);
       io_lst4 = listAppend(io_lst2,io_lst3);       
     then  io_lst4;
     case({})
     then {};
   end matchcontinue;  
end unknowntype_lst;

public function user_function
  input list<Absyn.ElementItem> in_out; 
  input AbsynMat.User_Function uf;
  input list<String> io_lst;
  input list<String> f_call;
  input list<String> fnc_hdl_ident;
  input list<String> all_idents;
  output String fnc_name;
  output list<Absyn.ClassPart> outclasspart;
  output list<String> d_type1;
algorithm
  (fnc_name,outclasspart,d_type1) := matchcontinue(in_out,uf,io_lst,f_call,fnc_hdl_ident,all_idents)
    local
      AbsynMat.User_Function usr_fnc, usr_fnc1, usr_fnc2;
      list<AbsynMat.Parameter> prm; 
      Option<AbsynMat.Separator> sep;             
      list<AbsynMat.Statement> stmt, stmt_end;       
      AbsynMat.Statement stmt_2nd; 
      list<AbsynMat.Decl_Elt> ret;   
      list<Absyn.AlgorithmItem> alg;
      list<Absyn.ClassPart> cls_prt, cls_prt2, cls_prt3, cls_rev, cls_rev2, prm_stmt, prm_stmt2, prm_stmt3;
      Absyn.ClassPart cls_stmt, in_cp, out_cp, prt_cp;
      list<Absyn.ElementItem> inout, inout1, in_put, out_put, prtVar, prtVar2, prtVar3; 
      Absyn.Ident fname, fname1;
      list<String> un_rdtype, un_dtype, un_dtype2, io_lst3, io_lst1, io_lst2, for_ident, all_ident, asg_ident; 
      list<String> all_idents1, io_lstun, all, all2, f_call1, d_type_lst, fnc_hdl_ident1, fnc_hdl_ident2;
      list<AbsynMat.Expression> exp_lst, exp_lst2, exp_lst3;
    case(inout, AbsynMat.START_FUNCTION(fname,prm,sep,stmt,stmt_2nd),io_lst1, f_call1, fnc_hdl_ident1, all_idents1)
      equation
        f_call1 = listAppend(fname::{},f_call1);                
        (in_put,io_lst3) = create_in_list(prm);        
        io_lst2 = listAppend(io_lst3,io_lst1);        
        inout1 = listAppend(in_put,inout);         
        io_lstun = unknowntype_lst(io_lst2);        
        (alg,for_ident,asg_ident,exp_lst,d_type_lst,fnc_hdl_ident2) = stmt_lst(stmt, f_call1, fnc_hdl_ident1, io_lstun);        
        all_ident = listAppend(io_lst2,for_ident);         
        all = protectVariable(all_ident,asg_ident);          
        all2 = listReverse(all);           
        prtVar = protect_lst(all2,d_type_lst,all_idents1);        
        //un_dtype = rmv_non_protected(d_type_lst,io_lst2);
        un_dtype = rmvInOut(d_type_lst,io_lst2);        
        un_rdtype = listReverse(un_dtype);        
        un_dtype2 = rmvDuplicate2(un_rdtype);
        un_rdtype = listReverse(un_dtype2);
        prtVar2 = protect_lst2(exp_lst,un_rdtype,all_idents1);
        prtVar3 = listAppend(prtVar,prtVar2);
        in_cp = Absyn.PUBLIC(inout1);
        prt_cp = Absyn.PROTECTED(prtVar3);
        cls_stmt = Absyn.ALGORITHMS(alg);
        prm_stmt = listAppend(cls_stmt::{},prt_cp::{}); 
        prm_stmt2 = listAppend(prm_stmt,in_cp::{});               
      then 
        (fname, prm_stmt2,d_type_lst);       
    case({}, AbsynMat.FINISH_FUNCTION(ret,usr_fnc2),{},f_call1,fnc_hdl_ident1, all_idents1)
      equation
          (out_put,io_lst3) = create_out_list(ret,false,all_idents);        
          (fname, cls_prt,d_type_lst) = user_function(out_put, usr_fnc2, io_lst3, f_call1,fnc_hdl_ident1,all_idents1);
           cls_rev = listReverse(cls_prt);
      then
        (fname, cls_rev,d_type_lst);       
    case({},_,{},{},{},{})
      then ("",{},{});
   end matchcontinue;                     
end user_function;

public function sub_function
input list<AbsynMat.Statement> stmt_lst;
input list<String> in_f_call;
input list<String> fnc_hdl_ident;
output list<Absyn.Class> mod_class;
output list<String> f_call;
algorithm
  (mod_class,f_call) := matchcontinue(stmt_lst,in_f_call,fnc_hdl_ident)
  local
    AbsynMat.User_Function usr_fnc;
    AbsynMat.Separator sep;
    Absyn.ClassDef cd;
    list<Absyn.ClassPart> cp;
    Absyn.Class class1;
    list<Absyn.Class> class2, mod_class2;   
    String fname;
    list<String> f_call1, f_call2, f_call3, f_call4, fnc_hdl_ident1, no_ident;
    Absyn.Info info;
    list<AbsynMat.Statement> stmt_lst2;
    case(AbsynMat.STATEMENT_APPEND(AbsynMat.STATEMENT(NONE(),NONE(),SOME(AbsynMat.START(usr_fnc,sep,stmt_lst2)),NONE()),_)::{},f_call4,fnc_hdl_ident1)
    equation
    (mod_class2,f_call1) = sub_function(stmt_lst2,f_call4,fnc_hdl_ident1); 
    f_call3 = listAppend(f_call1,f_call4);
    (fname, cp, no_ident) = user_function({},usr_fnc,{},f_call3,fnc_hdl_ident1,{}); 
    f_call2 = listAppend(f_call1,fname::{});
    cd = Absyn.PARTS({},{},cp,{},NONE());                
    info=SOURCEINFO("",false,0,0,0,0,0.0);
    class1 = Absyn.CLASS(fname,false,false,false,Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.NO_PURITY())),cd,info); 
    class2 = listAppend(class1::{},mod_class2);  
    then (class2,f_call2);  
    case({},f_call4,fnc_hdl_ident1)
    then ({},{});
  end matchcontinue;
end sub_function;

public function rem_nStatement
input list<String> nstmt;
output list<String> o_stmt;
algorithm
  o_stmt := matchcontinue(nstmt)
  local
    list<String> nstmt1, nstmt2, nstmt3;
    String nstring;
    case("nStatement"::nstmt1)
      equation
      nstmt2 = rem_nStatement(nstmt1);
    then nstmt2;      
    case(nstmt1)           
    then nstmt1;      
end matchcontinue;  
end rem_nStatement;

public function chk_lst
input list<String> i_typelst1;
input list<String> i_typelst2;
output list<String> o_typelst;
algorithm
  o_typelst := matchcontinue(i_typelst1,i_typelst2)
  local
    list<String> i_typelst3,i_typelst4;
    case(i_typelst3,{})
    then i_typelst3;
    case({},i_typelst3)
    then i_typelst3;
    case(i_typelst3,i_typelst4)
    then i_typelst4;  
    case({},{})
    then {};
  end matchcontinue;
end chk_lst;

public function update_lst
input String ident;
input String upd_type;
input list<String> u_typelst;
input Boolean tf;
input list<String> u2_typelst;
output list<String> o_typelst;
algorithm
  o_typelst := matchcontinue(ident,upd_type,u_typelst,tf,u2_typelst)
  local
    String ident1, add_type1, u_type, upd_type1;
    list<String> u_typelst1, u2_typelst2, o_typelst2, o_typelst3, o_typelst4, o_typelst5;
    Boolean tf1;
    case(ident1,upd_type1,u_type::u_typelst1,false,u2_typelst2)
      equation
 /*    print("\n update_lst false 0\n");
     print(anyString(ident1));
     print("\n update_lst false 1\n");
     print(anyString(upd_type1));
     print("\n update_lst false 2\n");
     print(anyString(u_type));
     print("\n update_lst false 3\n");
     print(anyString(u_typelst1));
     print("\n update_lst false 4\n");
     print(anyString(u2_typelst2));          
  */   tf1  = stringEqual(ident1,u_type);
     o_typelst3 = listAppend(u2_typelst2,{u_type});
     o_typelst2 = update_lst(ident1,upd_type1,u_typelst1,tf1,o_typelst3); 
    then o_typelst2;
    case(ident1,upd_type1,u_type::u_typelst1,true,u2_typelst2)
      equation
     
         o_typelst2 = listAppend({upd_type1},u_typelst1);   
         o_typelst3 = listAppend(u2_typelst2, o_typelst2);      
    
        o_typelst4 = update_lst(ident1,upd_type1,o_typelst2,false,u2_typelst2); 
        o_typelst5 = chk_lst(o_typelst3,o_typelst4);       
  
        then o_typelst5;
    case(ident1,upd_type1,{},false,u2_typelst2)
    then {};  
  end matchcontinue;
end update_lst;

public function chk_ept
input list<String> i_typelst;
input list<String> f_lst;
output list<String> o_typelst;
algorithm 
  o_typelst := matchcontinue(i_typelst,f_lst)
  local
    list<String> i_typelst1,f_lst1;
    case({},f_lst1)
    then f_lst1;
    case(i_typelst1,{})
    then i_typelst1;
    case(i_typelst1,f_lst1)
    then i_typelst1;
    case({},{})
    then {};     
  end matchcontinue;
end chk_ept;

public function update_type
input Boolean bool;
input String u_type;
input list<String> u_typelst;
input Boolean tf;
input list<String> upd_type;
input list<String> f_lst;
output list<String> o_typelst;
algorithm
  o_typelst := matchcontinue(bool,u_type,u_typelst,tf,upd_type,f_lst)
  local
    list<String> o_typelst1,upd_typelst;
    String u_type1,u_type2, rmv_ident, upd_type1;
    list<String> u_typelst1,u_typelst2, f_lst1;
    Boolean tf1;
    case(true,u_type1,u_typelst1,false,upd_typelst,f_lst1)
      then u_typelst1;
    case(false,u_type1,u_typelst1,false,{},f_lst1)
      then {}; 
    case(false,u_type1,{},false,upd_typelst,f_lst1)
      then {};      
    case(false,u_type1,{},false,{},f_lst1)
      then {};
    case(false,u_type1,u_type2::u_typelst1,false,{},f_lst1)
      equation
 //     print("\n update_type false {}\n");
      tf1  = stringEqual(u_type1,u_type2); 
      o_typelst = update_type(false,u_type1,u_typelst1,tf1,{},f_lst1);      
      then o_typelst;
    case(false,u_type1,u_type2::u_typelst1,false,upd_typelst,f_lst1)
      equation
    
      tf1  = stringEqual(u_type1,u_type2); 
      o_typelst = update_type(false,u_type1,u_typelst1,tf1,upd_typelst,f_lst1); 
      o_typelst1 = chk_ept(o_typelst,f_lst1);
    
      then o_typelst1;
    case(false,u_type1,u_typelst1,true,upd_type1::upd_typelst,f_lst1)
      equation
       u_typelst2 = update_lst(u_type1,upd_type1,f_lst1,false,{});
         
      then u_typelst2;        
  end matchcontinue;  
end update_type;

public function chk_keywords
  input list<String> type22;
  output Boolean bool;
algorithm
  bool := matchcontinue(type22)
    local
     String ident;
     list<String> type221,lst_numbers;
     Boolean num_bool;
    case("vector"::type221)
    then true;
    case("matrix"::type221)
    then true;
    case("column_vector"::type221)
    then true;
    case("empty"::type221)
    then true;
     case("Real"::type221)
    then true;
     case("Integer"::type221)
    then true;    
    case(ident::type221) //check for numbers  0 1 2 3 4 5 6 7 8 9
    equation
      lst_numbers = {"0","1","2","3","4","5","6","7","8","9"};
      num_bool = listMember(ident,lst_numbers);
    then num_bool;
  end matchcontinue;
end chk_keywords;

public function update_typelst
  input list<String> u_type1;
  input list<String> u_type2;
  input Boolean chk_1st;
  output list<String> type_lst;
  output Boolean o_chk_1st;
algorithm 
  (type_lst,o_chk_1st) := matchcontinue(u_type1,u_type2,chk_1st)
    local
  Boolean chk_1st1, chk_key;
  list<String> type11, type22, type33, type44, type_lst2, type_lst3, type_lst4, type_lst5, type_lst6;
  String stype, stype1, stype2;  
  case(type11,{},true)
    equation
     type_lst2 = ident_typelst(type11); 
     chk_1st1 = false;   
  then (type_lst2,chk_1st1);
  case(type11,{},chk_1st1)
    equation 
   //   print("\n update_typelst type11 \n");
   //   print(anyString(type11));
  then ({},chk_1st);  
  case({},type22,chk_1st1)
    equation 
  //    print("\n update_typelst type22 \n");
  then ({},chk_1st1);
  case({},{},chk_1st1)
    equation 
   //   print("\n update_typelst end \n");
  then ({},chk_1st1);
  case(type11,stype::{},chk_1st1)
    equation
      
      type_lst2 = update_type(true,stype, type11, false,{},type11);
      (type_lst3,chk_1st1) = update_typelst(type11,{},false);
      type_lst4 =  listAppend(type_lst2,type_lst3);

    then (type_lst4,chk_1st1);  
  case(type11,type22,chk_1st1)
    equation
       chk_key = chk_keywords(type22); //return true if first element is ident else false for keywords and numbers
       stype1::type33 = type22;       
    //   stype2::type44 = type33;
       type_lst2 = update_type(chk_key,stype1, type11, false,type33,type11); //if chk_key is true then ignore comparing else search for ident
       (type_lst3,chk_1st1) = update_typelst(type_lst2,type33,false);
   //  type_lst4 =  listAppend({"nstmt"},type_lst3);
   //  type_lst5 = listAppend(type_lst2,type_lst4);
       type_lst6 = rtn_sgl(type_lst2,type_lst3);
       then 
         (type_lst6,chk_1st1);     
  end matchcontinue;
end update_typelst;

public function split  //not in use
  input String d_type;
  input list<String> stmt;
  input list<String> sep_lst0;
  input list<String> ident_type;
  output list<String> o_stmt;
  output list<String> o_stmt2;
algorithm
  (o_stmt,o_stmt2) := matchcontinue(d_type,stmt,sep_lst0, ident_type)
  local
  String d_type1;
  list<String> stmt2, d_type2,d_type3, sep_lst, ret_type, ret_type2, ident_type1, ident_type2, u_type, u_type2;
    case("nstmt",{"nstmt","nstmt"}, sep_lst, ident_type1)  
      equation
        ident_type2 = listAppend(sep_lst,ident_type1);  
    
      then 
        ({},ident_type2);
    case("nstmt",d_type2, sep_lst, ident_type1) 
      equation   
       then ({},sep_lst);       
    case(d_type1,stmt2,sep_lst,ident_type1)
      equation
  
        d_type2 = listAppend(sep_lst,{d_type1});      
    then (d_type2,{});   
  end matchcontinue;
end split;

public function rtn_sgl
input list<String> ident_type2;
input list<String> d_type_lst2;
output list<String> o_type;
algorithm
  o_type := matchcontinue(ident_type2,d_type_lst2)
  local
    list<String> i_ident,i_ident2;
    case(i_ident,{})
      equation
    //    print("\n rtn 1 \n");
    //    print(anyString(i_ident));
    then i_ident;
    case({},i_ident2)
      equation
    //    print("\n rtn 2\n");
    //    print(anyString(i_ident2));
    then i_ident2;
    case(i_ident,i_ident2)
      equation
     //   print("\n rtn 3\n");
     //   print(anyString(i_ident2));    
    then i_ident2;
  end matchcontinue;
end rtn_sgl;

public function split_lst  //not in use
input list<String> d_type_lst;
input list<String> sep_lst;
input list<String> ident_type;
output list<String> f_type_lst;
algorithm
  f_type_lst := matchcontinue (d_type_lst,sep_lst,ident_type)
  local
    list<String> d_type_lst1, o_type_lst1, d_type_lst2, d_type_lst3, o_type_lst2, o_type_lst3, sep_lst1, ident_type1, ident_type2;
    String d_type,d_type2;
    case({},sep_lst1,ident_type1)
      equation 
      then {}; 
   case(d_type::{},sep_lst1,ident_type1)
   then sep_lst1;                
    case(d_type::d_type_lst1,sep_lst1,ident_type1)
      equation
        
        d_type2::d_type_lst3 = d_type_lst1;
  
       (o_type_lst1,ident_type2) = split(d_type,{d_type,d_type2},sep_lst1,ident_type1);
       d_type_lst2 = split_lst(d_type_lst1,o_type_lst1,ident_type2);
       o_type_lst2 = rtn_sgl(ident_type2,d_type_lst2);
         
    then o_type_lst2;
  end matchcontinue;
end split_lst;

public function chk_emp
input list<String> u_type;
input list<String> ret_type;
output list<String> o_type;
algorithm 
  o_type := matchcontinue(u_type,ret_type)
  local
    list<String> u_type1, ret_type1;
    case({},ret_type1)
    then ret_type1; 
    case(u_type1,ret_type1)
    then u_type1; 
  end matchcontinue;
end chk_emp;

public function ary_fnc
input Boolean zeros;
input Boolean ones;
input list<String> i_lst;
output list<String> o_lst;
output Boolean zos;
algorithm
  (o_lst,zos) := matchcontinue(zeros,ones,i_lst)
  local
    list<String> i_lst1,i_lst2,i_lst3,i_lst4,i_lst5, i_lst6, lst_ap, lst_ap1, lst_ap2;
    String str, str2, dim, dim1, dim2;
    Integer dim_length, total_length;
    case(true,false,i_lst1)
    equation
      dim = listGet(i_lst1,5);
      dim1 = stringGetStringChar(dim,1);
      dim2 = stringGetStringChar(dim,2);
      str::i_lst2=i_lst1;
      i_lst3 = listDelete(i_lst2,1);
      i_lst4 = listDelete(i_lst3,1);
      i_lst5 = listDelete(i_lst4,1);
      str2::i_lst6 = i_lst5;
      lst_ap =  {"matrix",dim1,dim2};
      lst_ap1 = listAppend(lst_ap,{str});
      lst_ap2 = listAppend(lst_ap1,{"Real"});      
    then (lst_ap2,true);
    case(false,true,i_lst1)
    equation
      dim = listGet(i_lst1,5);
     
      dim1 = stringGetStringChar(dim,1);
      dim2 = stringGetStringChar(dim,2);
     
      str::i_lst2=i_lst1;
      i_lst3 = listDelete(i_lst2,1);
      i_lst4 = listDelete(i_lst3,1);
      i_lst5 = listDelete(i_lst4,1);
      str2::i_lst6 = i_lst5;
      lst_ap =  {"matrix",dim1,dim2};
      lst_ap1 = listAppend(lst_ap,{str});
      lst_ap2 = listAppend(lst_ap1,{"Real"});
    then (lst_ap2,true);
    case(false,false,i_lst1)
    equation
      i_lst2 = ident_typelst(i_lst1);
      i_lst3 = listAppend({"Scalar"},{"1"});
      i_lst4 = listAppend(i_lst3,{"1"});
      i_lst5 = listAppend(i_lst4,i_lst2);      
    then (i_lst5,false);  
  end matchcontinue;  
end ary_fnc;

public function ary_dims
 input list<String> lst;
 output String dim;
 algorithm
   dim := matchcontinue(lst)
   local
     list<String> lst1,lst2;
     String ident;
     case(lst1)
       equation
        lst2 = listReverse(lst1);
        ident = listGet(lst2,1);
     then ident;   
 end matchcontinue;
end ary_dims;

public function chk_type
input Boolean vet;
input Boolean mtr;
input Boolean cln_vet;
input list<String> i_lst;
output list<String> o_lst;
output Boolean ary_scl;
algorithm
  (o_lst,ary_scl) := matchcontinue(vet,mtr,cln_vet,i_lst)
  local
  list<String> i_lst1, i_lst2, i_lst3, i_lst4, i_lst5, o_lst1, upd_lst, upd_lst2, upd_lst3, upd_lst4;
  String ident,dim, dim2, dim5, fident;
  Integer dim_length, total_length, dim4, dim3, dim0;
  Boolean zeros, ones, zos;
    case(true,false,false,i_lst1)
      equation
        fident::upd_lst=i_lst1;
        upd_lst2 = listDelete(upd_lst,1);
        upd_lst3 = listAppend({"Real"},upd_lst2);
        upd_lst4 = listAppend({fident},upd_lst3);
        total_length = listLength(i_lst1);
        dim_length = total_length - 3;
        dim = intString(dim_length);
        i_lst2 = ident_typelst(upd_lst4);
        i_lst3 = listAppend({"vector"},{"1"});
        i_lst4 = listAppend(i_lst3,{dim});
        i_lst5 = listAppend(i_lst4,i_lst2);        
    then (i_lst5,true);
    case(false,true,false,i_lst1)
      equation
        
        fident::upd_lst=i_lst1;
        upd_lst2 = listDelete(upd_lst,1);
        upd_lst3 = listAppend({"Real"},upd_lst2);
        upd_lst4 = listAppend({fident},upd_lst3);
       
        total_length = listLength(i_lst1);
        dim_length = total_length - 3;
        dim = intString(dim_length);
        dim2 = ary_dims(i_lst1);
        dim3 = stringInt(dim2);
        dim0 = stringInt(dim);
        dim4 = realInt(dim0/dim3);
        dim5 = intString(dim4);
       
        i_lst2 = ident_typelst(upd_lst4);        
        i_lst3 = listAppend({"matrix"},{dim2});
        i_lst4 = listAppend(i_lst3,{dim5});
        i_lst5 = listAppend(i_lst4,i_lst2); 
       
      then (i_lst5,true);
     case(false,false,true,i_lst1)
      equation
        fident::upd_lst=i_lst1;
        upd_lst2 = listDelete(upd_lst,1);
        upd_lst3 = listAppend({"Real"},upd_lst2);
        upd_lst4 = listAppend({fident},upd_lst3);
        total_length = listLength(i_lst1);
        dim_length = total_length - 3;
        dim = intString(dim_length);
        i_lst2 = ident_typelst(upd_lst4);
        i_lst3 = listAppend({"column_vector"},{dim});
        i_lst4 = listAppend(i_lst3,{"1"});
        i_lst5 = listAppend(i_lst4,i_lst2);       
      then (i_lst5,true);    
    case(false,false,false,i_lst1)
      equation
        
        zeros = listMember("zeros",i_lst1);
        ones = listMember("ones",i_lst1);
        (i_lst4,zos) = ary_fnc(zeros,ones,i_lst1);           
        then (i_lst4,zos); 
  end matchcontinue;
end chk_type;

public function scl_ary
input list<String> i_lst;
output list<String> o_lst;
output Boolean ary_scl;
algorithm
  (o_lst,ary_scl) := matchcontinue(i_lst)
  local
  list<String> i_lst1, ary_scl_lst;
  Boolean vet,mtr,clm_vet,ary_scl1;
  case(i_lst1)
    equation     
    vet = listMember("vector",i_lst1);
    mtr = listMember("matrix",i_lst1);  
    clm_vet = listMember("column_vector",i_lst1);
    (ary_scl_lst,ary_scl1) = chk_type(vet,mtr,clm_vet,i_lst1);   
    then (ary_scl_lst,ary_scl1);
  case({})
  then ({},false);
end matchcontinue;
end scl_ary;

public function merge_lst
input list<String> scl_ary_lst;
input list<String> ident_type;
input list<String> ret_type;
input Boolean ary_scl;
output list<String> merg_lst;
algorithm 
  merg_lst := matchcontinue(scl_ary_lst,ident_type,ret_type,ary_scl)
  local
  list<String> add_scl, add_scl1 ,merg_lst1, scl_ary_lst1,ident_type1,ret_type1;
  case(scl_ary_lst1,ident_type1,ret_type1,true)
  equation
    merg_lst1 = listAppend(scl_ary_lst1,ident_type1);
  then merg_lst1;
  case(scl_ary_lst1,ident_type1,ret_type1,false)
  equation
 //   add_scl = listAppend({"Scalar"},{"1"});
 //   add_scl1 = listAppend(add_scl,ret_type1);
    merg_lst1 = listAppend(ret_type1,ident_type1);
  then merg_lst1; 
  end matchcontinue;  
end merge_lst;

public function chk_vet_mtx
input list<String> typ;
output Boolean tf11;
output Boolean tf22;
output Boolean tf33;
output Boolean tf44;
output Boolean tf55;
algorithm
  (tf11,tf22,tf33,tf44,tf55) := matchcontinue(typ)
  local
    list<String> typ1;
    Boolean tf1,tf2,tf3,tf4,tf5;
    case(typ1)
      equation
       tf1 = listMember("vector",typ1);
       tf2 = listMember("matrix",typ1);
       tf3 = listMember("column_vector",typ1);  
       tf4 = listMember("zeros",typ1);
       tf5 = listMember("ones",typ1);  
      then (tf1,tf2,tf3,tf4,tf5);   
  end matchcontinue;
end chk_vet_mtx;

public function chk_string
  input String ident1;
  input String ident2;
  output Boolean tf;
algorithm
  tf := matchcontinue(ident1,ident2)
    local
      String ident3,ident4;
      Boolean chk2;    
      case("vector",ident4)
      then false;
      case("matrix",ident4)
      then false;
      case("column_vector",ident4)
      then false;
      case("Scalar",ident4)
      then false;  
      case("Integer",ident4)
      then false;
      case("Real",ident4)
      then false;
      case(ident3,ident4)
        equation
          chk2 = stringEqual(ident3,ident4);        
        then  chk2;
   end matchcontinue;
 end chk_string;

public function chk_mat_vet_cvet
 input String ident3;
 input String ident4;
 input String ident5;
 output list<String> lst;
 algorithm
   lst := matchcontinue(ident3,ident4,ident5)
   local
     String ident6,ident7,ident8;
     list<String> lst2, lst3, lst4;
     case("matrix",ident6,ident7)
       equation
        lst2 = listAppend({"matrix"},{ident7});
        lst3 = listAppend(lst2,{ident6});
       then lst3;
     case(ident6,ident7,ident8)
       equation
        
         lst2 = listAppend({ident6},{ident8});
         lst3 = listAppend(lst2,{ident7});
        
       then lst3;
   end matchcontinue;
end chk_mat_vet_cvet;

public function upd_scl_ary4
 input list<String> ident_type;
 input String ident;
 input list<String> ident_lst;
 input list<String> prv_lst;
 input list<String> nxt_lst;
 input Boolean tf;
 output list<String> ful_info;
 output Boolean tfo;
 algorithm
   (ful_info,tfo) := matchcontinue(ident_type,ident,ident_lst,prv_lst,nxt_lst,tf) 
   local
     list<String> ful2, ident_type1, ful_lst, prv_lst1, prv_upt, prv_upt2, prv_lst2, prv_lst3, nxt_lst1, ident_lst1, ident_lst2, ident_lst3, ident_lst4, ident_lst5, ful_info1, ful;
     String ident1,ident2, ident3, ident4, ident5;
     Boolean tf1;
     Integer lgt;
      case({},ident2,ident_lst1,prv_lst1,nxt_lst1,false)
        equation
      then (prv_lst1,false);
     case(ident1::ident_type1,ident2,ident_lst1,prv_lst1,nxt_lst1,false)
       equation
 
         tf1 = chk_string(ident1,ident2);
           ident_lst2 = listAppend(ident_lst1,{ident1});     
         ful_info1 = upd_scl_ary4(ident_type1,ident2,ident_lst2,prv_lst1,nxt_lst1,tf1); 
       then (ful_info1,tf1);
     case(ident_type1,ident2,ident_lst1,prv_lst1,nxt_lst1,true)  
       equation
  
       ident_lst3 = listReverse(ident_lst1);
      // prv_lst2 = listReverse(prv_lst1);
        lgt = listLength(prv_lst1);
        prv_lst3 = listDelete(prv_lst1,lgt-1);
       
       ident3 = listGet(ident_lst3,2);
        ident4 = listGet(ident_lst3,3);
        ident5 = listGet(ident_lst3,4);
        
        ful2 = chk_mat_vet_cvet(ident5,ident3,ident4);
        
      //  ful = listAppend({ident5},{ident3});
      //  ful2 = listAppend(ful,{ident4});
        prv_upt = listAppend(prv_lst3,ful2);
        prv_upt2 = listAppend(prv_upt,{ident2});
        ful_lst = listAppend(prv_upt2,nxt_lst1);
        //ful_info1 = listAppend(ful_lst,{ident2});
         
        //ful_info1 = upd_scl_ary3(ident_lst1, nxt_lst1,prv_upt2);        
       then (prv_upt2,true);
   end matchcontinue;
end upd_scl_ary4;

public function update_prv
 input String ident;
 input list<String> identi;
 input Boolean tf1;
 output list<String> idento;
algorithm
  idento := matchcontinue(ident,identi,tf1)
 local
 list<String> idento1, identi1;
 String ident1;
  case(ident1,identi1,false)
    equation
      idento1 = listAppend(identi1,{ident});
      then idento1;
   case(ident1,identi1,true)
   then identi1;
 end matchcontinue;
end update_prv;

public function upd_scl_ary3
 input list<String> ident_type;
 input list<String> u_type;
 input list<String> ident_lst;
 input Boolean tf;
 output list<String> ful_info;
 algorithm
   ful_info := matchcontinue(ident_type, u_type, ident_lst,tf)
   local
     list<String> ident_type1, u_type1, ful_info1, ful_info2, ful_info3, ful_info4, ident_lst1, ident_lst2;
     String ident;
     Boolean tf1;
     case(ident_type1,{},ident_lst1,tf1)
       equation
       then {};
     case(ident_type1,ident::u_type1,ident_lst1,tf1)
     equation       
          
     ident_lst2 = update_prv(ident,ident_lst1,tf1);

     ful_info1 = upd_scl_ary4(ident_type1,ident,{},ident_lst2,u_type1,false);  
  
     ful_info2 = upd_scl_ary3(ident_type1,u_type1,ful_info1,tf1);
     ful_info3 = rtn_sgl(ful_info1,ful_info2); 
    // ful_info3 = listAppend(ful_info1,ful_info2);

     then ful_info3;
     case({},u_type1,ident_lst1,tf1) 
     then {};
   end matchcontinue;
end upd_scl_ary3;

public function chk_ful_info
 input list<String> ful_info;
 input list<String> scl_ary_lst;
 output list<String> ful_info_o;
 algorithm
   ful_info_o := matchcontinue(ful_info, scl_ary_lst)
   local
     list<String> scl_ary_lst1, ful_info1;
     case({}, scl_ary_lst1)
     then scl_ary_lst1;
     case(ful_info1, scl_ary_lst1)
     then ful_info1;
   end matchcontinue;
end chk_ful_info;

public function upd_scl_ary2
 input Boolean tf;
 input list<String> scl_ary_lst;
 input list<String> ident_type;
 input list<String> u_type;
 output list<String> ful_info;
algorithm
  ful_info := matchcontinue(tf,scl_ary_lst,ident_type,u_type)
  local
    list<String> scl_ary_lst1,ident_type1,u_type1, u_type2, u_type3, ful_info1, ful_info2;
    String ident, ident1;
    case(true,scl_ary_lst1,ident_type1,u_type1)
    then scl_ary_lst1;
    case(false,scl_ary_lst1,{},u_type1)
    then scl_ary_lst1;  
    case(false,scl_ary_lst1,ident_type1,u_type1)
    equation
  //    print("\n upd_scl_ary2 \n"); 
       ful_info1 = upd_scl_ary3(ident_type1,u_type1,{},false);
       ful_info2 = chk_ful_info(ful_info1,scl_ary_lst1);
  //   u_type3 = listAppend(scl_ary_lst1,ful_info1); 
      then ful_info2;   
  end matchcontinue;
end upd_scl_ary2;

public function chk_bool
 input Boolean tf1;
 input Boolean tf2;
 input Boolean tf3;
 input Boolean tf4;
 input Boolean tf5;
 output Boolean tf6;
 algorithm
   tf6 := matchcontinue(tf1,tf2,tf3,tf4,tf5)
     case(true,false,false,false,false)
     then true;
     case(false,true,false,false,false)
     then true;
     case(false,false,true,false,false)
     then true;
     case(false,false,false,true,false)
     then true;
     case(false,false,false,false,true)
     then true;  
     case(false,false,false,false,false)
     then false;
 end matchcontinue;
end chk_bool;

public function upd_scl_ary
  input list<String> scl_ary_lst;
  input list<String> ident_type;
  input list<String> u_type;
  output list<String> ful_info;
algorithm
  ful_info := matchcontinue(scl_ary_lst,ident_type,u_type)
  local
  list<String> scl_ary_lst1,ident_type1,u_type1, ful_info1, u_type2;
  Boolean tf1, tf2, tf3, tf4,tf5,tf6;
    case(scl_ary_lst1,ident_type1,u_type1)    
    equation
      (tf1,tf2,tf3,tf4,tf5) = chk_vet_mtx(u_type1);
      tf6 = chk_bool(tf1,tf2,tf3,tf4,tf5);
      ful_info1 = upd_scl_ary2(tf6,scl_ary_lst1,ident_type1,u_type1); 
    then ful_info1;        
  end matchcontinue;
end upd_scl_ary;

/*
public function update_string
input String identi;
output list<String> idento;
algorithm
  idento := matchcontinue(identi)
  local 
    String ident1;
    list<String> ident_upd;
    case("Unknown")
      equation
         ident_upd = listAppend({"Unknown,0"},{"Unknown"});
        then ident_upd;
    case(ident1)
      equation
        ident_upd = {ident1};
    then {};    
      end matchcontinue;
end update_string;

public function ret_dim
 input String ident;
 output String dim;
 output String ary_scl;
  algorithm
    (dim,ary_scl) := matchcontinue(ident)
    local
      String ident1,dim1,ary_scl1;
      case(ident1)
      
end ret_dim;  
  
public function update_unknown
  input list<String> ful_info;
  input list<String> prv0;
  output list<String> ful_info_o;
algorithm
  ful_info_o := matchcontinue(ful_info,prv0)
  local
    list<String> prv, prv_lst, prv_lst1 ,ful_info1, ful_info_o1, ful_lst, ful_lst1;
    String ident,dim,ary_scl;
    case({},{})
    then {};
    case(ident::ful_info1,prv)
    equation
      print("\n update_unknown \n");
      print(anyString(ident));
      listMember("vector");
      (ary_scl,dim) = ret_dim(ident);
//     prv_lst = listAppend({ident},prv); 
//     ful_info_o1 = update_string(ident);
//     prv_lst1 = listAppend(prv_lst,ful_info_o1);
//     ful_lst = update_unknown(ful_info1,prv_lst1);
    // ful_lst1 = listAppend(prv_lst1,ful_lst);
     then ful_lst;
  end matchcontinue;  
end update_unknown; 
*/

public function get_dim1
 input String ident;
 input list<String> idtypes;
 output list<String> dim;
 output Boolean tf;
 algorithm 
   (dim,tf) := matchcontinue(ident,idtypes)
   local
     list<String> idtypes1, idtypes2, dim3;
     String dim1, dim2;
     case("vector",idtypes1)
       equation
         dim1 = listGet(idtypes1,2); 
         dim3 = listAppend({"1"},{dim1});       
       then (dim3,true);  
     case("matrix",idtypes1)
       equation
        
         dim1 = listGet(idtypes1,1);  
         dim2 = listGet(idtypes1,2);  
         dim3 = listAppend({dim1},{dim2});       
       then (dim3,true);  
     case("column_vector",idtypes1)
       equation
        
         dim1 = listGet(idtypes1,1);
         dim3 = listAppend({dim1},{"1"});         
       then (dim3,true); 
     case(dim2,idtypes1)             
       then ({},false);        
   end matchcontinue;
end get_dim1;
 
public function get_dimlst
  input list<String> idtypes;
  input Boolean tf;
  output list<String> idtypeso;
  algorithm
    idtypeso := matchcontinue(idtypes,tf)
 local
   String ident;
   list<String> dim, idtypes1, dim_lst, dim_lst1;
   Boolean tf1;
   case({},false)
   then {};
   case({},true)
   then {};  
   case(idtypes1,true)
   then {};  
   case(ident::idtypes1,false)
     equation
   (dim,tf1) = get_dim1(ident,idtypes1);
   dim_lst = get_dimlst(idtypes1,tf1);
   dim_lst1 = listAppend(dim,dim_lst);
   then dim_lst1;
 end matchcontinue;
end get_dimlst;
 
public function get_dim
 input Boolean vec;
 input Boolean mtx;
 input Boolean cvec;
 input Boolean emp;
 input list<String> idtypes;
 output list<String> dim;
 algorithm
   dim := matchcontinue(vec,mtx,cvec,emp,idtypes)
     local
       list<String> idtypes1, dim1,dim2, dim3;
       case(true,false,false,false,idtypes1)
         equation
          dim1 = get_dimlst(idtypes,false);
          dim2 = listAppend({"vector"},dim1);
         then dim2;
       case(true,false,false,true,idtypes1)
         equation
          dim1 = get_dimlst(idtypes,false);
          dim2 = listAppend({"vector"},dim1);
         then dim2;    
       case(false,true,false,false,idtypes1)
         equation
           dim1 = get_dimlst(idtypes,false);
           dim2 = listAppend({"matrix"},dim1);
         then dim2;
       case(false,true,false,true,idtypes1)
         equation
           dim1 = get_dimlst(idtypes,false);
           dim2 = listAppend({"matrix"},dim1);
         then dim2;                
       case(false,false,true,false,idtypes1)
         equation
           dim1 = get_dimlst(idtypes,false);
           dim2 = listAppend({"column_vector"},dim1);
         then dim2;
       case(false,false,true,true,idtypes1)
         equation
           dim1 = get_dimlst(idtypes,false);
           dim2 = listAppend({"column_vector"},dim1);
         then dim2;               
       case(false,false,false,false,idtypes1)
         equation
         dim2 = listAppend({"Scalar"},{"1"});
         dim3 = listAppend(dim2,{"1"});
         then dim3; 
       case(false,false,false,true,idtypes1)
         equation
         dim2 = listAppend({"Scalar"},{"1"});
         dim3 = listAppend(dim2,{"1"});
         then dim3;    
   end matchcontinue;           
end get_dim;
  
public function get_dim_ary
 input list<String> u_type;
 output list<String> dim_out;
 algorithm
   dim_out := matchcontinue(u_type)
   local
     list<String> u_type1, dim;
     Boolean vec, mtx, cvec, emp;
     case({})
     then {};
     case(u_type1)
       equation     
      
       emp = listMember("empty",u_type1);      
       vec = listMember("vector",u_type1);
       mtx = listMember("matrix",u_type1);
       cvec = listMember("column_vector",u_type1);
       dim = get_dim(vec,mtx,cvec,emp,u_type1);
       then dim;     
 end matchcontinue;
end get_dim_ary;

public function chk_index2
 input Boolean emp;
 input Boolean vec;
 input Boolean mat;
 input Boolean cvec;
 input list<String> ful_info;
 output list<String> ful_info_o;
algorithm
ful_info_o := matchcontinue(emp,vec,mat,cvec,ful_info)
  local
    list<String> ful_info1, f2, f3, f4, f5, f6, f7, f8, ful_info2;
    String ident, ident1;
    case(true,false,false,false,ful_info1)
      equation
       ident = listGet(ful_info,1);
       ident1 = listGet(ful_info,2);
       f2  = listDelete(ful_info1,1);
       f3  = listDelete(f2,1);
       f4  = listDelete(f3,1);
       f5  = listDelete(f4,1);
       f6 =  listAppend({ident},{ident1});
       f7 = listAppend(f6,{"Scalar"});
       f8 = listAppend(f7,{"1"});
       ful_info2 = listAppend(f8,f5);    
      then ful_info2;
    case(true,true,false,false,ful_info1)
    then ful_info1;
    case(false,true,false,false,ful_info1)
    then ful_info1;
    case(true,false,true,false,ful_info1)
    then ful_info1;
    case(false,false,true,false,ful_info1)
    then ful_info1;
    case(true,false,false,true,ful_info1)
    then ful_info1;
    case(false,false,false,true,ful_info1)
    then ful_info1;
    case(false,false,false,false,ful_info1)
    then ful_info1;             
end matchcontinue;
end chk_index2;

/*
public function convert
 input String string;
 input list<String> prv_lst;
 output list<String> nxt_lst;
algorithm
  nxt_lst := matchcontinue(string,prv_lst)
  local
    case("empty",prv_lst)
      equation
        
        then {};
  end matchcontinue;
end convert;

public function convert_idx_subscp
 input list<String> ful_info;
 output list<String> cov_lst;
 algorithm
   cov_lst := matchcontinue(ful_info)
  local
    list<String> ful_info1,prv_lst, prv_lst1;
    String string;
    case(string::ful_info1,prv_lst)      
      equation
        prv_lst1 = listAppend(prv_lst,{string});
         convert(string,prv_lst1);
      then   
   end matchcontinue;
end convert_idx_subscp;
*/

public function chk_length
 input Integer lth;
 input list<String> ful_info;
 output list<String> ful_info_o;
algorithm
  ful_info_o := matchcontinue(lth,ful_info)
  local
    list<String> cov_lst, ful_info1, ful_info2, ful_info3, ful_info4, ful_info5, ful_info6, ful_info9;
    Integer lth1;
    Boolean emp,vec,mat,cvec;
    case(4,ful_info1)
    then ful_info1;
    case(lth1,ful_info1)
      equation       
       ful_info9 = ful_info1; 
       
  //   cov_lst = convert_idx_subscp(ful_info1);
       ful_info2 = listDelete(ful_info1,1);
       ful_info3 = listDelete(ful_info2,1);
       ful_info4 = listDelete(ful_info3,1);
       ful_info5 = listDelete(ful_info4,1);
       
       emp = listMember("empty",ful_info5);
       vec = listMember("vector",ful_info5);
       mat = listMember("matrix",ful_info5);
       cvec = listMember("column_vector",ful_info5);
       ful_info6 = chk_index2(emp,vec,mat,cvec,ful_info9);
      
       then ful_info6;
    end matchcontinue;
end chk_length;

public function chk_key_string2
 input String ident0;
 input String ident;
 input list<String> nxt_lst;
 output list<String> nxt_lst0;
 output list<String> new_lst0;
 algorithm
   (nxt_lst0,new_lst0) := matchcontinue(ident0,ident,nxt_lst)
   local
     String ident1,dim1,dim2,dim3,dim4,dim5,ident2;
     list<String> nxt_lst1, nxt_lst2, nxt_lst3, nxt_lst4, nxt_lst5, nxt_lst6, new_lst, new_lst1, new_lst2;
     case("empty",ident2,nxt_lst1)
       equation
        
         dim3 = listGet(nxt_lst1,3);
         dim4 = listGet(nxt_lst1,4);
         dim5 = listGet(nxt_lst1,5); 
         
        new_lst = {"Scalar","1",dim3,dim4,dim5};
        new_lst1 = listAppend(new_lst,{"1"});
        nxt_lst2 = listDelete(nxt_lst1,1);
        nxt_lst3 = listDelete(nxt_lst2,1);
        nxt_lst4 = listDelete(nxt_lst3,1);
        nxt_lst5 = listDelete(nxt_lst4,1); 
        nxt_lst6 = listDelete(nxt_lst5,1);  
       // new_lst2 = listAppend(new_lst1,nxt_lst3);
       then (nxt_lst6,new_lst);         
     case("ARYIDENT0",ident2,nxt_lst1)
       equation
         dim3 = listGet(nxt_lst1,3);
         dim4 = listGet(nxt_lst1,4);
         dim5 = listGet(nxt_lst1,5); 
        new_lst = {"Scalar","1",dim3,dim4,dim5};
        new_lst1 = listAppend(new_lst,{"1"});
        nxt_lst2 = listDelete(nxt_lst1,1);
        nxt_lst3 = listDelete(nxt_lst2,1);
        nxt_lst4 = listDelete(nxt_lst3,1);
        nxt_lst5 = listDelete(nxt_lst4,1); 
        nxt_lst6 = listDelete(nxt_lst5,1);  
       // new_lst2 = listAppend(new_lst1,nxt_lst3);
       then (nxt_lst6,new_lst);    
     case("0.0x0",ident2,nxt_lst1)
       equation
        
         dim1 = listGet(nxt_lst1,1);
         dim2 = listGet(nxt_lst1,2);
         dim3 = listGet(nxt_lst1,3);
         dim4 = listGet(nxt_lst1,4);
         dim5 = listGet(nxt_lst1,5);
         new_lst = {"column_vector",dim2,dim1,dim3,dim4,dim5};
        // new_lst1 = listAppend(new_lst,{dim1});
         nxt_lst2 = listDelete(nxt_lst1,1);
         nxt_lst3 = listDelete(nxt_lst2,1); 
         nxt_lst4 = listDelete(nxt_lst3,1);
         nxt_lst5 = listDelete(nxt_lst4,1); 
         nxt_lst6 = listDelete(nxt_lst5,1);        
    //    new_lst2 = listAppend(new_lst1,nxt_lst3);
       
       then (nxt_lst6,new_lst);              
     case("ARYIDENT0.0x0",ident2,nxt_lst1)
       equation
         
         dim1 = listGet(nxt_lst1,1);
         dim2 = listGet(nxt_lst1,2);
         dim3 = listGet(nxt_lst1,3);
         dim4 = listGet(nxt_lst1,4);
         dim5 = listGet(nxt_lst1,5);
         new_lst = {"vector","1",dim2,dim3,dim4,dim5};
    //     new_lst1 = listAppend(new_lst,{dim2});
         nxt_lst2 = listDelete(nxt_lst1,1);
         nxt_lst3 = listDelete(nxt_lst2,1);
         nxt_lst4 = listDelete(nxt_lst3,1);
         nxt_lst5 = listDelete(nxt_lst4,1); 
         nxt_lst6 = listDelete(nxt_lst5,1); 
 //       print("\n CHK KEY 0.0x0 1\n");
 //        print(anyString(nxt_lst3));
    //    new_lst2 = listAppend(new_lst1,nxt_lst3);        
       then (nxt_lst6,new_lst);
     case("1x0.0x0",ident2,nxt_lst1)
       equation
        
         dim1 = listGet(nxt_lst1,1);
         dim2 = listGet(nxt_lst1,2);
         dim3 = listGet(nxt_lst1,3);
         dim4 = listGet(nxt_lst1,4);
         dim5 = listGet(nxt_lst1,5);
         new_lst = {"vector","1",dim2,dim3,dim4,dim5};
    //     new_lst1 = listAppend(new_lst,{dim2});
         nxt_lst2 = listDelete(nxt_lst1,1);
         nxt_lst3 = listDelete(nxt_lst2,1);
         nxt_lst4 = listDelete(nxt_lst3,1);
         nxt_lst5 = listDelete(nxt_lst4,1); 
         nxt_lst6 = listDelete(nxt_lst5,1); 
 //       print("\n CHK KEY 0.0x0 1\n");
 //        print(anyString(nxt_lst3));
    //    new_lst2 = listAppend(new_lst1,nxt_lst3);        
       then (nxt_lst6,new_lst);            
       case("0.0xARYIDENT0",ident2,nxt_lst1)
       equation
       
        dim1 = listGet(nxt_lst1,1);
        dim2 = listGet(nxt_lst1,2);
        dim3 = listGet(nxt_lst1,3);
        dim4 = listGet(nxt_lst1,4);
        dim5 = listGet(nxt_lst1,5); 
        new_lst = {"column_vector",dim1,"1",dim3,dim4,dim5};
      //  new_lst1 = listAppend(new_lst,{"1"});
        nxt_lst2 = listDelete(nxt_lst1,1);
        nxt_lst3 = listDelete(nxt_lst2,1);
        nxt_lst4 = listDelete(nxt_lst3,1);
        nxt_lst5 = listDelete(nxt_lst4,1); 
        nxt_lst6 = listDelete(nxt_lst5,1);        
       
 //       new_lst2 = listAppend(new_lst1,nxt_lst3);        
       then (nxt_lst6,new_lst);   
       case("0.0x1x0",ident2,nxt_lst1)
       equation
       
        dim1 = listGet(nxt_lst1,1);
        dim2 = listGet(nxt_lst1,2);
        dim3 = listGet(nxt_lst1,3);
        dim4 = listGet(nxt_lst1,4);
        dim5 = listGet(nxt_lst1,5); 
        new_lst = {"column_vector",dim1,"1",dim3,dim4,dim5};
      //  new_lst1 = listAppend(new_lst,{"1"});
        nxt_lst2 = listDelete(nxt_lst1,1);
        nxt_lst3 = listDelete(nxt_lst2,1);
        nxt_lst4 = listDelete(nxt_lst3,1);
        nxt_lst5 = listDelete(nxt_lst4,1); 
        nxt_lst6 = listDelete(nxt_lst5,1);        
       
 //       new_lst2 = listAppend(new_lst1,nxt_lst3);        
       then (nxt_lst6,new_lst);   
        case("1x1x0",ident2,nxt_lst1)
         equation     
        dim1 = listGet(nxt_lst1,1);
        dim2 = listGet(nxt_lst1,2);
        dim3 = listGet(nxt_lst1,3);
        dim4 = listGet(nxt_lst1,4);
        dim5 = listGet(nxt_lst1,5); 
        new_lst = {"Scalar","1","1",dim3,dim4,dim5};
        nxt_lst2 = listDelete(nxt_lst1,1);
        nxt_lst3 = listDelete(nxt_lst2,1);
        nxt_lst4 = listDelete(nxt_lst3,1);
        nxt_lst5 = listDelete(nxt_lst4,1); 
        nxt_lst6 = listDelete(nxt_lst5,1);       
                 
       then (nxt_lst6,new_lst);                 
       case("ARYIDENTARYIDENT0",ident2,nxt_lst1)
         equation     
        dim1 = listGet(nxt_lst1,1);
        dim2 = listGet(nxt_lst1,2);
        dim3 = listGet(nxt_lst1,3);
        dim4 = listGet(nxt_lst1,4);
        dim5 = listGet(nxt_lst1,5); 
        new_lst = {"Scalar","1","1",dim3,dim4,dim5};
        nxt_lst2 = listDelete(nxt_lst1,1);
        nxt_lst3 = listDelete(nxt_lst2,1);
        nxt_lst4 = listDelete(nxt_lst3,1);
        nxt_lst5 = listDelete(nxt_lst4,1); 
        nxt_lst6 = listDelete(nxt_lst5,1);       
                 
       then (nxt_lst6,new_lst);           
       case("0.0x0.0x0",ident2,nxt_lst1)
         equation
        dim1 = listGet(nxt_lst1,1);
        dim2 = listGet(nxt_lst1,2);
        dim3 = listGet(nxt_lst1,3);
        dim4 = listGet(nxt_lst1,4);
        dim5 = listGet(nxt_lst1,5); 
        new_lst = {"matrix",dim1,dim2,dim3,dim4,dim5};
        nxt_lst2 = listDelete(nxt_lst1,1);
        nxt_lst3 = listDelete(nxt_lst2,1);
        nxt_lst4 = listDelete(nxt_lst3,1);
        nxt_lst5 = listDelete(nxt_lst4,1); 
        nxt_lst6 = listDelete(nxt_lst5,1);       
                 
       then (nxt_lst6,new_lst);  
       case(ident1,ident2,nxt_lst1)
           equation
         nxt_lst2 = listAppend({ident2},nxt_lst1);
       then ({},nxt_lst2); 
   end matchcontinue;
end chk_key_string2;

public function chk_colon
 input String ident;
 input list<String> nxt_lst;
 input list<String> prv_lst;
 output list<String> new_lst;
 output list<String> prv_lst0;
 algorithm
   (new_lst,prv_lst0) := matchcontinue(ident,nxt_lst,prv_lst)
   local
     String ident1,ident4;
     list<String> prv_lst1, prv_lst2, prv_lst3, prv_lst4, nxt_lst1, nxt_lst2;
     case("empty",nxt_lst1,prv_lst1)
     equation
        ident4 = "empty";
        (nxt_lst2,prv_lst2) = chk_key_string2("empty",ident4,nxt_lst1);
        prv_lst3 = listAppend(prv_lst1,prv_lst2);
       
       then (nxt_lst2,prv_lst3);       
     case("ARYIDENT0",nxt_lst1,prv_lst1)
     equation
        ident4 = "empty";
        (nxt_lst2,prv_lst2) = chk_key_string2("empty",ident4,nxt_lst1);
        prv_lst3 = listAppend(prv_lst1,prv_lst2);
       
       then (nxt_lst2,prv_lst3);     
     case("0.0x0",nxt_lst1,prv_lst1)
     equation
        
        prv_lst2 = listAppend(prv_lst1,{"column_vector"});
        //prv_lst3 = listAppend(prv_lst1,prv_lst2);
        
       then (nxt_lst1,prv_lst2);
     case(ident1,nxt_lst1,prv_lst1)
     equation
        (nxt_lst2,prv_lst2) = chk_key_string2(ident1,"abc",nxt_lst1);
        prv_lst3 = listAppend(prv_lst2,{"column_vector"});
        prv_lst4 = listAppend(prv_lst1,prv_lst3);
       then (nxt_lst2,prv_lst4);  
   end matchcontinue;
end chk_colon;

public function chk_key_string
 input String ident;
 input list<String> nxt_lst;
 input list<String> prv_lst;
 output list<String> new_lst;
 output list<String> prv_lst9;
algorithm
  (new_lst,prv_lst9) := matchcontinue(ident,nxt_lst,prv_lst)
  local
    String ident1,ident4,ident5;
    list<String> nxt_lst1, nxt_lst2, new_lst0, new_lst1, prv_lst1, prv_lst2;
     case("matrix",nxt_lst1,prv_lst1)
      equation   
        ident4 = "matrix";
     ident5 = listGet(nxt_lst1,5);
     
     (nxt_lst2,new_lst1) = chk_key_string2(ident5,ident4,nxt_lst1);
     prv_lst2 = listAppend(prv_lst1,new_lst1);
     
    then (nxt_lst2,prv_lst2);
    case("vector",nxt_lst1,prv_lst1)
      equation
     ident4 = "vector";
     ident1 = listGet(nxt_lst1,5);
    
     (nxt_lst2,new_lst1) = chk_key_string2(ident1,ident4,nxt_lst1);
     prv_lst2 = listAppend(prv_lst1,new_lst1);
    
     then (nxt_lst2,prv_lst2);
    case("column_vector",nxt_lst1,prv_lst1)
      equation
     ident1 = listGet(nxt_lst1,5);
     
     (nxt_lst2,prv_lst2) = chk_colon(ident1,nxt_lst1,prv_lst1);        
  	 
     then (nxt_lst2,prv_lst2); 
    case(ident1,nxt_lst1,prv_lst1)
      equation
     prv_lst2 = listAppend(prv_lst1,{ident1});
    then (nxt_lst1,prv_lst2);  
 end matchcontinue;
end chk_key_string;

public function chk_key_arys
 input list<String> ful_info;
 input list<String> prv_lst;
 output list<String> upd_lst;
 algorithm
   upd_lst := matchcontinue(ful_info,prv_lst)
   local
     String ident, ident1;
     list<String> ful_info1, prv_lst1, prv_lst2, prv_lst3, prv_lst4, new_lst;     
     case({},prv_lst1)
       equation
       then prv_lst1;
     case(ident::ful_info1,prv_lst1)
       equation
        
         (new_lst,prv_lst2) = chk_key_string(ident,ful_info1,prv_lst1); 
         prv_lst3 = chk_key_arys(new_lst,prv_lst2);
       //  prv_lst4 = listAppend(prv_lst3,prv_lst2);     
      then prv_lst3;
 end matchcontinue;
end chk_key_arys;

public function chk_index
  input list<String> ful_info;
  output list<String> ful_info_o;
algorithm
  ful_info_o := matchcontinue(ful_info)
    local
       list<String> ful_info1, ful_info2, ful_info3;
       Integer lth;
    case("vector"::ful_info1)
      equation
        ful_info2 = listAppend({"vector"},ful_info1);
      then ful_info2;
    case("matrix"::ful_info1)
      equation
        ful_info2 = listAppend({"matrix"},ful_info1);
      then ful_info2;
    case("column_vector"::ful_info1)
      equation
        ful_info2 = listAppend({"column_vector"},ful_info1);
      then ful_info2;
    case("Scalar"::ful_info1)
      equation
        ful_info2 = listAppend({"Scalar"},ful_info1);
      then ful_info2;
    case(ful_info1)
      equation
        
        ful_info2 = chk_key_arys(ful_info1,{}); // find index and convert such as vector, 4, 1, C, Real, 0.0x0 to column_vector, 4,1, C etc
        
        lth = listLength(ful_info2);
        ful_info3 = chk_length(lth,ful_info2);
      then ful_info3;
  end matchcontinue;
end chk_index;

public function make_real
 input Integer lth;
 output list<String> ret_rel;
algorithm
  ret_rel := matchcontinue(lth)
  local
    list<String> ret_rel1;
    Integer lth1;
    case(lth1)
    then {"Real"};
  end matchcontinue;
end make_real;
  
public function make_real_lst
 input Integer lth;
 output list<String> rel_lst;
 algorithm
   rel_lst := matchcontinue(lth)
   local
     list<String> rel_lst1,rel_lst2, rel_lst3;
     Integer lth1;
     case(0)
     then {};
     case(lth1)
       equation
         rel_lst1 = make_real(lth1);
         rel_lst2 = make_real_lst(lth1-1);
         rel_lst3 = listAppend(rel_lst1,rel_lst2);
       then rel_lst3; 
   end matchcontinue;
end make_real_lst;

public function chk_ary_lst
  input Boolean chk;
  input Boolean chk1;
  input Boolean chk2;
  input list<String> ident_lst;
  output list<String> upd_lst;
 algorithm
   upd_lst := matchcontinue(chk,chk1,chk2,ident_lst)
   local
     list<String> ident_lst1, rel_lst, rel_lst2;
     String ident;
     Integer lth;
     case(true,false,false,ident::ident_lst1)
     equation
      lth = listLength(ident_lst1);
      rel_lst = make_real_lst(lth);
      rel_lst2 = listAppend({ident},rel_lst);
     then rel_lst2; 
     case(false,true,false,ident::ident_lst1)
     equation
      lth = listLength(ident_lst1);
      rel_lst = make_real_lst(lth);
      rel_lst2 = listAppend({ident},rel_lst);
     then rel_lst2; 
     case(false,false,true,ident::ident_lst1)
     equation
      lth = listLength(ident_lst1);
      rel_lst = make_real_lst(lth);
      rel_lst2 = listAppend({ident},rel_lst);
     then rel_lst2;
     case(false,false,false,ident_lst1)          
     then ident_lst1;     
   end matchcontinue;
end chk_ary_lst;
   
public function cov_num_to_real
 input list<String> ident_lst;
 output list<String> upd_lst;
 algorithm
   upd_lst := matchcontinue(ident_lst)
   local
     list<String> ident_lst1, ident_lst2, upd_lst1, upd_lst2, upd_lst3;
     String ident, ident1;
     Boolean chk, chk1, chk2;
     case(ident::ident_lst1)
     equation
       ident1::ident_lst2 = ident_lst1;
       chk = listMember("vector",ident_lst2);
       chk1 = listMember("matrix",ident_lst2);
       chk2 = listMember("column_vector",ident_lst2);
       upd_lst1 = chk_ary_lst(chk,chk1,chk2,ident_lst2);
       upd_lst2 = listAppend({ident1},upd_lst1);
       upd_lst3 = listAppend({ident},upd_lst2);       
       then upd_lst3;
   end matchcontinue;
 end cov_num_to_real;
 
 
public function sep_statement
  input String d_type;
  input list<String> sep_lst0;
  input list<String> ident_type;
  input Boolean chk_1st;
  output list<String> o_stmt;
  output list<String> o_stmt2;
  output Boolean o_chk_1st;
algorithm
  (o_stmt,o_stmt2,o_chk_1st) := matchcontinue(d_type,sep_lst0, ident_type,chk_1st)
  local
  String d_type1;
  Boolean chk_1st1,ary_scl;
  list<String> ident_type0, dim_ary1, upd_unk, ful_info, ful_info1, scl_ary_lst, d_type2,d_type3, sep_lst, ret_type, ret_type2, ret_type3, ident_type1, ident_type2, ident_type3,u_type, u_type2, upd_lst;
    case("nStatement", {}, ident_type1,chk_1st1)  
    then ({},ident_type1,chk_1st1);
    case("nStatement", sep_lst, ident_type1,chk_1st1)  
      equation
        ret_type = rem_nStatement(sep_lst);
       
        ident_type0 = cov_num_to_real(ret_type);
       
        (scl_ary_lst,ary_scl) = scl_ary(ret_type); // ret_type
        
        (u_type,chk_1st1) = update_typelst(ret_type,ident_type1,chk_1st1); //ident_type0 replaces ret_type  
         
        ful_info = upd_scl_ary(scl_ary_lst,ident_type1,u_type);
       
        ful_info1 = chk_index(ful_info);   
       
        dim_ary1 = get_dim_ary(ful_info1);
       
        u_type2 = chk_emp(u_type,ret_type);  //ident_type0 replaces ret_type
        //  upd_lst = split_lst(u_type,{},{});       
       
        ret_type2 = ident_typelst(u_type2);
       
        ret_type3 = listAppend(dim_ary1,ret_type2);
        ident_type2 = merge_lst(scl_ary_lst,ident_type1,ret_type3,ary_scl);
        // ident_type2 = listAppend(ident_type1,ret_type2);  
                
    then ({},ident_type2,chk_1st1);     
    case(d_type1, sep_lst, ident_type1,chk_1st1)
      equation
        d_type2 = listAppend(sep_lst,{d_type1});      
    then (d_type2,ident_type1,chk_1st1);   
  end matchcontinue;
end sep_statement;

public function ret_lst_final
 input list<String> ident_type;
 input list<String> o_type_lst;
 output list<String> o_lst;
 algorithm
   o_lst :=matchcontinue(ident_type,o_type_lst)
   local
     list<String> lst1, lst2;
     case(lst1,{})
       then lst1;
     case({},lst2)
       then lst2;
     case(lst1,lst2)
       then lst2;
   end matchcontinue;
end ret_lst_final;

public function assign_type
input list<String> d_type_lst;
input list<String> sep_lst;
input list<String> ident_type;
input Boolean chk_1st;
input list<String> ident_type33;
output list<String> f_type_lst;
output list<String> ident_type13;
algorithm
  (f_type_lst,ident_type13) := matchcontinue (d_type_lst,sep_lst,ident_type,chk_1st,ident_type33)
  local
    list<String> final_lst, d_type_lst1, o_type_lst1, d_type_lst2, o_type_lst2, o_type_lst3, sep_lst1, ident_type1, ident_type2, ident_type3, ident_type4;
    String d_type;
    Boolean chk_1st1;
    case(d_type::d_type_lst1,sep_lst1,ident_type1,chk_1st1,ident_type3)
      equation
     //  print("\n assign_type \n");
       (o_type_lst1,ident_type2,chk_1st1) = sep_statement(d_type, sep_lst1,ident_type1,chk_1st1);
       (d_type_lst2,ident_type4) = assign_type(d_type_lst1,o_type_lst1,ident_type2,chk_1st1,ident_type3);
       o_type_lst2 = listAppend(o_type_lst1,d_type_lst2);  
       final_lst = ret_lst_final(ident_type2,ident_type4);
               
    then (ident_type2,final_lst);
    case({},sep_lst1,ident_type1,chk_1st1,ident_type3)
    then ({},ident_type3);
  end matchcontinue;
end assign_type;

public function Scl
  input Boolean tf;
  output String scl;
algorithm
  scl := matchcontinue(tf)
    case(true)
      then "1";
    case(false)
      then "0";
  end matchcontinue;
end Scl;

public function Vec
  input Boolean tf;
  output String vec;
algorithm
  vec := matchcontinue(tf)
    case(true)
      then "1";
    case(false)
      then "0";
  end matchcontinue;
end Vec;

public function Mat
  input Boolean tf;
  output String mat;
algorithm
  mat := matchcontinue(tf)
    case(true)
      then "1";
    case(false)
      then "0";
  end matchcontinue;
end Mat;

public function CVec
  input Boolean tf;
  output String cvec;
algorithm
  cvec := matchcontinue(tf)
    case(true)
      then "1";
    case(false)
      then "0";
  end matchcontinue;
end CVec;

public function Int
  input Boolean tf;
  output String int;
algorithm
  int := matchcontinue(tf)
    case(true)
      then "1";
    case(false)
      then "0";
  end matchcontinue;
end Int;

public function Re
  input Boolean tf;
  output String re;
algorithm
  re := matchcontinue(tf)
    case(true)
      then "1";
    case(false)
      then "0";
  end matchcontinue;
end Re;

public function Chk
  input Boolean tf;
  output String str;
algorithm
  str := matchcontinue(tf)
    case(true)
      then "1";
    case(false)
      then "0";
  end matchcontinue;
end Chk;

public function Chk2
  input Boolean tf;
  output String str;
algorithm
  str := matchcontinue(tf)
    case(true)
      then "1";
    case(false)
      then "0";
  end matchcontinue;
end Chk2;

public function chk_number
  input Boolean scl;
  input Boolean vec;
  input Boolean mat;
  input Boolean cvec;
  output Boolean tf;
 algorithm
  (tf) := matchcontinue(scl,vec,mat,cvec)
    local
      Boolean scl1,vec1,mat1,cvec1, tf1;
      list<String> lst_ident1, bools, bools1, bools2, lst_ident2;      
      String s,v,m,c;
    case(scl1,vec1,mat1,cvec1)
      equation
        s = Scl(scl1);
        v = Vec(vec1);
        m = Mat(mat1);
        c = CVec(cvec1);
        bools = listAppend({s},{v});
        bools1 = listAppend({m},{c});
        bools2 = listAppend(bools,bools1);
        tf1 = listMember("1",bools2);        
      then tf1;   
  end matchcontinue;
end chk_number;

public function deleteDup3
  input Boolean chk;
  input String ident;
  input list<String> prv_lst;
  input list<String> nxt_lst;
  output list<String> prv_upt;
  output list<String> nxt_upt;
algorithm
  (prv_upt,nxt_upt) := matchcontinue(chk,ident,prv_lst,nxt_lst)
    local
    list<String> prv_lst1, nxt_lst1, prv_lst2, prv_lst3, prv_lst4, prv_lst5, nxt_lst2, nxt_lst3;
    String ident2;
    case(true,ident2,prv_lst1,nxt_lst1)
      equation
       
     // prv_lst2 = listReverse(prv_lst1);
        prv_lst2 = listDelete(prv_lst1,1);
        prv_lst3 = listDelete(prv_lst2,1);
      //  prv_lst5 = listReverse(prv_lst4);
        nxt_lst2 = listDelete(nxt_lst1,1);
     //   nxt_lst3 = listReverse(nxt_lst2);
     
     //   nxt_lst3 = listAppend({ident2},nxt_lst2);
      then (prv_lst3,nxt_lst2);
    case(false,ident2,prv_lst1,nxt_lst1)
       equation
        prv_lst2 = listAppend({ident2},prv_lst1);
    then (prv_lst2,nxt_lst1);
  end matchcontinue;
end deleteDup3;

public function deleteDup2
  input String ident;
  input list<String> lst_ident;
  input list<String> prv_lst;
  output list<String> prv_lsto;
  output list<String> nxt_lsto;
 algorithm
   (prv_lsto,nxt_lsto) := matchcontinue(ident,lst_ident,prv_lst)
   local
     String ident1,ident2;
     list<String> lst_ident1, lst_ident2, prv_lst1, prv_lst2, prv_lst3, prv_lst4, prv_lst5, nxt_lst2, nxt_lst3;
     Boolean chk;
     case(ident1,{},prv_lst1)
     then (prv_lst1,{});
     case(ident1,ident2::lst_ident1,prv_lst1)
       equation
         
         //prv_lst2 = listAppend({ident2},prv_lst1);
         chk = stringEqual(ident1,ident2);
         (prv_lst3,nxt_lst2) = deleteDup3(chk,ident2,prv_lst1,lst_ident1);
         
       //  prv_lst4 = listReverse(prv_lst3);
         (prv_lst4,nxt_lst3)  = deleteDup2(ident1,nxt_lst2,prv_lst3);
       then (prv_lst4,nxt_lst3);
   end matchcontinue;
end deleteDup2;

public function deleteDup
  input Boolean chk;
  input String ident;
  input list<String> lst_ident;
  output list<String> prv_lst;
  output list<String> nxt_lst;
algorithm
  (prv_lst,nxt_lst) := matchcontinue(chk,ident,lst_ident)
    local
      Boolean chk1;
      String ident1;
      list<String> lst_ident1, prv_lst1, prv_lst2, nxt_lst1;  
    case(true,ident1,lst_ident1)
      equation
        (prv_lst1,nxt_lst1) = deleteDup2(ident1,lst_ident1,{});
         
         prv_lst2 = listReverse(prv_lst1);
         
      then (prv_lst2,nxt_lst1);
    case(false,ident1,lst_ident1)
    then ({},lst_ident1);
  end matchcontinue;
end deleteDup;

public function rmvDuplicate4
  input Boolean chk;
  input Boolean chk1;
  input String ident;
  input list<String> lst_ident;
  input Boolean num;
  output list<String> prv_lst;
  output list<String> nxt_lst;
algorithm
  (prv_lst,nxt_lst) := matchcontinue(chk,chk1,ident,lst_ident,num)
    local
      list<String> lst_ident2, lst_ident3, prv_lst1, nxt_lst1;   
      String ident1;     
      Boolean chk2;
    case(true,true,ident1,lst_ident2,false)
      equation
        //lst_ident3 = listAppend({ident1},lst_ident2);      
    then ({},lst_ident2);
    case(false,true,ident1,lst_ident2,false)
      equation
        //lst_ident3 = listAppend({ident1},lst_ident2); 
    then ({},lst_ident2);
    case(false,false,ident1,lst_ident2,true)
      equation
        //lst_ident3 = listAppend({ident1},lst_ident2);      
    then ({},lst_ident2);
    case(false,false,ident1,lst_ident2,false)
      equation
              
        chk2 = listMember(ident1,lst_ident);
        (prv_lst1,nxt_lst1) = deleteDup(chk2,ident1,lst_ident2);  
       
      then (prv_lst1,nxt_lst1);
  end matchcontinue;
end rmvDuplicate4;

public function chk_lsts
 input list<String> prv_lst;
 input list<String> nxt_lst;
 input list<String> prv;
 input Boolean chk;
 output list<String> lst;
 algorithm
   lst := matchcontinue(prv_lst, nxt_lst, prv,chk)
   local
   list<String> prv_lst0, prv_lst1, nxt_lst1, nxt_lst2, ful_lst;
   Boolean chk1;
   case(prv_lst1,{},prv_lst0,chk1)
     equation
      
       nxt_lst1 = rmvDuplicate3(prv_lst1,chk1,prv_lst0);       
      
       then nxt_lst1;
   case(prv_lst1,nxt_lst1,prv_lst0,chk1)
     equation
       nxt_lst2 = rmvDuplicate3(nxt_lst1,chk1,prv_lst0);  
       ful_lst = listAppend(prv_lst1, nxt_lst2);
       then ful_lst;
   end matchcontinue;
end chk_lsts;

public function rmvDuplicate3
  input list<String> all;
  input Boolean num;
  input list<String> prv;
  output list<String> out;
algorithm 
  out := matchcontinue(all,num,prv)
    local
      list<String> lst_numbers, ful_lst, ful_lst2, lst_ident, lst_ident1, lst_ident2, lst_ident3, intre_lst, all_bools,prv_lst0,prv_lst9, prv_lst1, nxt_lst1, nxt_lst2;
      String ident, ints, rel, str_chk, str_chk2;
      Boolean num_bool,num1,chk,chk1,chk2,scl,vec,mat,cvec,int, re;
    case(ident::lst_ident,num1,prv_lst0)
      equation
        lst_numbers = {"0","1","2","3","4","5","6","7","8","9"};
        num_bool = listMember(ident,lst_numbers);
        prv_lst9 = listAppend({ident},prv_lst0);
        scl =  stringEqual("Scalar",ident);
        vec =  stringEqual("vector",ident);
        mat =  stringEqual("matrix",ident);
        cvec =  stringEqual("column_vector",ident);
        chk = chk_number(scl,vec,mat,cvec);
        int =  stringEqual("Integer",ident);
        re =  stringEqual("Real",ident);
        ints = Int(int);
        rel = Re(re);
        intre_lst   = listAppend({ints},{rel});
        chk1 = listMember("1",intre_lst);
        str_chk = Chk(chk1);
        str_chk2 = Chk2(chk);
        all_bools = listAppend({str_chk},{str_chk2});
        chk2 = listMember("1",all_bools);
        (prv_lst1,nxt_lst1) = rmvDuplicate4(chk,chk2,ident,lst_ident,num_bool);
        ful_lst = chk_lsts(prv_lst1,nxt_lst1,prv_lst9,chk);  
       
        ful_lst2 = listAppend(prv_lst9,ful_lst);      
        
      then ful_lst;
    case({},num1,prv_lst0)
    then (prv_lst0);
  end matchcontinue;
end rmvDuplicate3;

public function transform_start
"special function to translate module to package in MetaModelica"
  input AbsynMat.Start inprogram;
  output Absyn.Program outprogram;
algorithm
  outprogram:=matchcontinue(inprogram)
    local
      AbsynMat.User_Function uf,uf2,uf3;
      AbsynMat.Separator sep;
      Absyn.Program ast;
      Absyn.Class class1; 
      list<Absyn.Class> class2, class3, sub_class, sub_class1;     
      String fname, no_fname;
      list<String> upd_lst, all_idents, ident_type4, final_types, f_call, f_call1, f_call2, fnc_hdl_ident, idents_rhs, d_type_lst, io_lst, f_call, fnc_hdl_ident, no_ident;
      Absyn.Info info;   
      Absyn.ClassDef cd;
      list<Absyn.ClassPart> cp, no_cp;  
      list<AbsynMat.Statement> stmt_lst;
      list<AbsynMat.Expression> exp, exp2, exp3;
      Boolean fnc_hdl;
      list<Absyn.ElementItem> in_out; 
    case(AbsynMat.START(uf,sep,stmt_lst))
      equation
        (no_fname, no_cp,d_type_lst) = user_function({}, uf, {}, {}, {}, {});
        (final_types,ident_type4) = assign_type(d_type_lst,{},{},true,{});   //type evaluation 
         upd_lst = rmvDuplicate3(ident_type4,false,{});
        //upd_lst={};
        all_idents = listReverse(upd_lst);           
        exp = Fnc_Handle.user_function(uf);        
        exp2 = Fnc_Handle.sub_function(stmt_lst);        
        exp3 = listAppend(exp,exp2);        
        (sub_class1,f_call1,fnc_hdl_ident) = Fnc_Handle.fnc_hdl_to_sub_fnc_lst(exp3);  // converting anonymous function to sub function        
        (sub_class,f_call) = sub_function(stmt_lst,f_call1,fnc_hdl_ident); // sub function         
        f_call2 = listAppend(f_call,f_call1);        
        (fname, cp, no_ident) = user_function({},uf,{},f_call2,fnc_hdl_ident,all_idents);          
        cd = Absyn.PARTS({},{},cp,{},NONE());                        
        info=SOURCEINFO("",false,0,0,0,0,0.0);        
        class1 = Absyn.CLASS(fname,false,false,false,Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.NO_PURITY())),cd,info);             
        class2 = listAppend(class1::{},sub_class);          
        class3 = listAppend(class2,sub_class1);                  
      then
        Absyn.PROGRAM(class3,Absyn.TOP());
              
   // case(ast) then ast;
        
  end matchcontinue;
end transform_start;

public function transform
  "Main function which starts the rml translation to MEtaModelica AST  , get the RML AST as input and passes the 
   AST to different functions to get the MEtaModelica AST"
  input AbsynMat.AstStart inprogram;
  output Absyn.Program outprogram;
algorithm
  outprogram:= matchcontinue(inprogram)
    local
      AbsynMat.Start ast;
      Absyn.Program astNew;
    case(AbsynMat.ASTSTART(ast))
      equation
        astNew=transform_start(ast);   
      then
        astNew;
  end matchcontinue;
end transform;

end Translate;

