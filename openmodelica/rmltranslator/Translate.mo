encapsulated package Translate
" file:        Translate.mo
  package:     Translate
  description: This package contains functions which is used to translate RML AST to MetaModelica AST
               When the final translation is done, we can unparse the AST to Dump.mo to get a readable output"
import Absyn;
import Absynrml;
import System;
import List;
import Dict;

type Ident = String;

public function escape_modkeywords
"This function is used to differentiate modelica keywords with underscore added at the end, if any modelica keyword found in rml relations or statements"
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

      // case("list") then "list_";
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
    case ("then") then "then_";
    case("tuple") then "tuple_";
    case("type") then "type_";
    case("uniontype") then "uniontype_";
    case("when") then "when_";
    case("while") then "while_";
    case("within") then "within_";
    case(id) then  id;

  end matchcontinue;
end escape_modkeywords;

public function identName
"this function is used to extract the Identifiers or string  from RML AST to MetaModelica AST "
  input Absynrml.RMLIdent inrmlident;
  output String outstring;
algorithm
  outstring:= matchcontinue(inrmlident)
    local
      String name,prefix,name1,qualified_name;
    case (Absynrml.RMLSHORTID(name))then name;
    case (Absynrml.RMLLONGID(prefix,name))
      equation
        name1=stringAppend(".",name);
        qualified_name=stringAppend(prefix,name1);
      then
        qualified_name;
  end matchcontinue;
end identName;

public function get_rml_id
" help function to get id from special constructs in RML and to
build special id in modelica"
  input Absynrml.RMLIdent inrmlident;
  input Boolean inbool;
  output String outstring;
algorithm
  outstring:= matchcontinue(inrmlident,inbool)
    local
      Ident name,prefix,name1;
      String mname,mname1,mname2,mname3;
      Boolean b;
    case (Absynrml.RMLSHORTID(name),b)
      equation
        mname=escape_modkeywords(name);
        mname1=System.trim(mname,"'");
      then
        mname1;

    case (Absynrml.RMLLONGID(prefix,name),true)
      equation
        mname=escape_modkeywords(name);
        mname3=stringAppend(prefix,mname);
        mname3=System.trim(mname3,"'");
      then
        mname3;

    case (Absynrml.RMLLONGID(prefix,name),false)
      equation
        mname=escape_modkeywords(name);
        mname3=stringAppend(prefix,mname);
        mname3=System.trim(mname3,"'");
      then
        mname3;

    case(_,_)
      equation
      then
        "";

  end matchcontinue;
end get_rml_id;

public function fixRMLBuiltinsName
  "This function is used to match the RML builtins function with MetaModelica Builtin functions"
  input String instring;
  output String outstring;
algorithm
  outstring:= matchcontinue(instring)
    local
      String x;
    case("vector_nth")then "arrayNth";
    case("list_vector")then "listVector";
      // integer operations
    case("int_add") then "intAdd";
    case("int_sub") then "intSub";
    case("int_mul") then  "intMul";
    case("int_div") then "intDiv";
    case("int_mod") then "intMod";
    case("int_neg") then "intNeg";
    case("int_lt") then "intLt";
    case("int_le") then "intLe";
    case("int_eq") then "intEq";
    case("int_ne") then "intNe";
    case("int_ge") then "intGe";
    case("int_gt") then "intGt";
    case("int_min") then "intMin";
    case("int_max") then "intMax";
      //real operations
    case("real_add") then "realAdd";
    case("real_sub") then "realSub";
    case("real_mul") then "realMul";
    case("real_div") then "realDiv";
    case("real_neg") then "realNeg";
    case("real_lt") then "realLt";
    case("real_le") then "realLe";
    case("real_gt") then "realGt";
    case("real_ge") then "realGe";
    case("real_ne") then "realNe";
    case("real_eq") then "realEq";
    case("real_mod") then "realMod";
    case("real_min") then "realMin";
    case("real_max") then "realMax";
      // conversion types
    case("int_real")then "intReal";
    case("real_string") then "realString";
    case("int_string") then "intString";
    case("string_int") then "stringInt";
    case("bool_string") then "boolString";
    case("bool_and") then "boolAnd";
    case("bool_or") then "boolOr";
    case("bool_not") then "boolNot";
    case("string_append") then "stringAppend";
    case("list_append") then "listAppend";
    case("list_reverse") then "listReverse";
    case("list_member") then "listMember";
      // to add more rml builts ins
    case(x) then x;
  end matchcontinue;
end fixRMLBuiltinsName;

public function fixRMLbuiltins
  "help function for builtins"
  input Absynrml.RMLIdent inrmlident;
  output Absynrml.RMLIdent outrmlident;
algorithm
  outrmlident:= matchcontinue(inrmlident)
    local
      Ident prefix,name;
      Absynrml.RMLIdent x;
    case(x as Absynrml.RMLLONGID(prefix,name))
      equation
        failure(equality(prefix ="RML"));

      then
        x;
    case(x as Absynrml.RMLLONGID(prefix,name))
      equation
        prefix="RML";
        name=fixRMLBuiltinsName(name);
      then
        Absynrml.RMLLONGID(prefix,name);
    case(x as Absynrml.RMLSHORTID(name))
      equation
        name=fixRMLBuiltinsName(name);
      then
        Absynrml.RMLSHORTID(name);
  end matchcontinue;
end fixRMLbuiltins;

public function get_rml_id2
"help function to extract identifier from RML AST"
  input Absynrml.RMLIdent inrmlident;
  output String outstring;
algorithm
  outstring:= matchcontinue(inrmlident)

    local
      Ident name,prefix;
      String mname,mname1,mname2,mname3;

    case (Absynrml.RMLSHORTID(name))
      equation
        mname1=escape_modkeywords(name);
        mname2=System.trim(mname1,"'");
      then
        mname2;
    case (Absynrml.RMLLONGID(prefix,name))
      equation
        mname=escape_modkeywords(name);
        mname2=stringAppend(".",mname);
        mname3=stringAppend(prefix,mname2);
        mname3=System.trim(mname3,"'");
      then
        mname3;
  end matchcontinue;
end get_rml_id2;

public function transform_id_java
  "help function to extract identifier from RML AST"
  input Absynrml.RMLIdent inrmlident;
  output Absynrml.RMLIdent outrmlident;
algorithm
  outrmlident:= matchcontinue(inrmlident)
    local
      Ident name,prefix;
      Ident java_name;

    case(Absynrml.RMLSHORTID(name))
      equation
      then
        Absynrml.RMLSHORTID(name);

    case(Absynrml.RMLLONGID(prefix,name))
      equation

      then
        Absynrml.RMLLONGID(prefix,name);

  end matchcontinue;
end transform_id_java;

public function get_tyvar_id
"help function to get tyvar id from from RML AST"
  input Absynrml.RMLIdent inrmlident;
  input String instring;
  output String outstring;
algorithm
  outstring:= matchcontinue(inrmlident,instring)
    local
      Ident name;
      String mname,name1,id;
    case (Absynrml.RMLSHORTID(name),id)
      equation
        name1=transform_tyvar(name,id);
        mname=transform_id_handle_quotes(name1,0,0);

      then
        mname;
  end matchcontinue;
end get_tyvar_id;


public function transform_id
"special function to extract id from RML AST and translate to Absyn AST Path"
  input Absynrml.RMLIdent inrmlident;
  output Absyn.Path outpath;
algorithm
  outpath:= matchcontinue(inrmlident)
    local
      Ident prefix,name;
      String mname,mname1,mprefix;
    case (Absynrml.RMLSHORTID(name))
      equation
        mname1=escape_modkeywords(name);
        mname=fixRMLBuiltinsName(mname1);
      then
        Absyn.IDENT(mname);

    case (Absynrml.RMLLONGID(prefix,name))
      equation
        mname1=escape_modkeywords(name);
      then
        Absyn.QUALIFIED(prefix,Absyn.IDENT(mname1));
  end matchcontinue;
end transform_id;

public function transform_id_handle_quotes
"help function for filtering quotes and special characters"
  input String instring;
  input Integer ininteger;
  input Integer ininteger1;
  output String outstring;
algorithm
  outstring := matchcontinue(instring,ininteger,ininteger1)
    local
      Integer l,ic,qc,i,q;
      Boolean b;
      String sq,mstr,str,ss,mq,mq1,s,tstr;

    case(_,_,_)
      equation

      then
        "";

    case (s,i,q)
      equation

        l=stringLength(s);
        true=intGe(i,l);
        true=intGe(q,l);
        sq=intString(q);
        mstr=stringAppend("_",sq);

      then
        mstr;

    case (s,i,q)
      equation

        l=stringLength(s);
        true=intGe(ininteger,l);

      then
        "";

    case (s,i,q)
      equation

        "'" = stringGetStringChar(s,i);
        qc=intAdd(q,1);
        ic=intAdd(i,1);
        str=transform_id_handle_quotes(s,ic,qc);

      then
        str;

    case (s,i,q)
      equation

        true=intGe(q,1);
        ic=intAdd(i,1);
        ss=stringGetStringChar(s,i);
        str=transform_id_handle_quotes(s,ic,0);
        sq=intString(q);
        mq=stringAppend(sq,"_");
        mq1=stringAppend(mq,ss);
        mstr=stringAppend(mq1,str);

      then
        mstr;

    case(s,i,q)
      equation

        ss=stringGetStringChar(s,i);
        ic=intAdd(i,1);
        str=transform_id_handle_quotes(s,ic,q);
        tstr=stringAppend(ss,str);

      then
        tstr;


  end matchcontinue;
end transform_id_handle_quotes;


public function add_v_if_tyvar
"help function to add v after tyvar extracting tyvar id"
  input String instring;
  input Absynrml.RMLType inrmltype;
  output String outstring;
algorithm
  outstring:= matchcontinue(instring,inrmltype)
    local
      String id,id1;

    case (id,Absynrml.RMLTYPE_TYVAR(_))
      equation
        id1=stringAppend("V",id);
      then
        id1;
    case (id,_)then id;
  end matchcontinue;
end add_v_if_tyvar;

public function transform_tyvar
"help function to transform tyvar_id to normal id"
  input String instring;
  input String instring1;
  output String outstring;
algorithm
  outstring :=matchcontinue(instring,instring1)
    local
      String id,id1,id2;
      Integer len;

    case (id,"")
      equation
        len=stringLength(id);
        id1=System.substring(id,0,len); /*taking appos from 'a to a*/
        id2=stringAppend("Type_",id1);

      then
        id2;

    case (id,_)
      equation
        len=stringLength(id);
        id1=System.substring(id,1,len); /*taking appos from 'a to a*/
        id2=stringAppend("VType_",id1);
      then
        id2;

  end matchcontinue;
end transform_tyvar;


public function get_binop
"Function to match RML binary operation to MEtaModelica binary operators"
  input String instring;
  output Absyn.Operator outoperator;
algorithm
  outoperator:= matchcontinue(instring)

    /*fixed*/
    case ("int_add") then  Absyn.ADD();
    case ("int_sub") then Absyn.SUB();
    case ("int_mul") then Absyn.MUL();
    case ("int_div") then Absyn.DIV();

    case ("real_add") then  Absyn.ADD_EW();
    case ("real_sub") then  Absyn.SUB_EW();
    case ("real_mul") then  Absyn.MUL_EW();
    case ("real_div") then  Absyn.DIV_EW();

    case ("intAdd")   then Absyn.ADD();
    case ("intSub")   then  Absyn.SUB();
    case ("intMul")  then Absyn.MUL();
    case ("intDiv")  then  Absyn.DIV();

    case ("realAdd") then Absyn.ADD_EW();
    case ("realSub") then Absyn.SUB_EW();
    case ("realMul") then Absyn.MUL_EW();
    case ("realDiv") then Absyn.DIV_EW();

  end matchcontinue;
end get_binop;

public function get_relop
"Function to match RML relational operation to MEtaModelica relational operators"
  input String instring;
  output Absyn.Operator outoperator;
algorithm
  outoperator:= matchcontinue(instring)
    case ("int_lt") then Absyn.LESS();
    case ("int_le") then Absyn.LESSEQ();
    case ("int_ne") then Absyn.NEQUAL();
    case ("int_eq") then Absyn.EQUAL();
    case ("int_gt") then  Absyn.GREATER();
    case ("int_ge") then Absyn.GREATEREQ();


    case ("real_lt")then  Absyn.RLESS();
    case ("real_le")then  Absyn.RLESSEQ();
    case ("real_ne")then  Absyn.RNEQUAL();
    case ("real_eq") then Absyn.REQUAL();
    case ("real_gt") then Absyn.RGREATER();
    case ("real_ge") then Absyn.RGREATEREQ();

    case ("intLt") then Absyn.LESS();
    case ("intLe") then Absyn.LESSEQ();
    case ("intNe") then Absyn.NEQUAL();
    case ("intEq") then  Absyn.EQUAL();
    case ("intGT") then  Absyn.GREATER();
    case ("intGe") then  Absyn.GREATEREQ();


    case ("realLt") then Absyn.RLESS();
    case ("realLe") then Absyn.RLESSEQ();
    case ("realNe") then Absyn.RNEQUAL();
    case ("realEq") then Absyn.REQUAL();
    case ("realGt") then Absyn.RGREATER();
    case ("realGe") then Absyn.RGREATEREQ();
  end matchcontinue;
end get_relop;

public function get_bool
"Function to match RML boolean operation to MEtaModelica boolean operators"
  input String instring;
  output Absyn.Exp outexp;
algorithm
  outexp:= matchcontinue(instring)
    local
      String id;
      Boolean value;
    case(id)
      equation
        0=System.strcmp(id,"true");
      then
        Absyn.BOOL(value=true);

    case(id)
      equation
        0=System.strcmp(id,"false");
      then
        Absyn.BOOL(value=false);

  end matchcontinue;
end get_bool;

public function get_unop
"Function to match RML unary operation to MEtaModelica unary operators"
  input String instring;
  output Absyn.Operator outoperator;
algorithm
  outoperator:= matchcontinue(instring)

    case ("int_neg")  then  Absyn.UMINUS();
    case ("real_neg") then  Absyn.RUMINUS();
    case ("intNeg")   then  Absyn.UMINUS();
    case ("realNeg")  then  Absyn.RUMINUS();
  end matchcontinue;
end get_unop;

/*special help relation*/
public function getiffalse
  input String instring;
  input Boolean inbool;
  output String outstring;
algorithm
  outstring := matchcontinue(instring,inbool)
    local
      String s;

    case (s,false) then s;
    case (s,_) then  "";
  end matchcontinue;
end getiffalse;

public function get_specialtypetuple_id
"special function to extract id from RML types and add to structures in MetaModelica AST"
  input list<Absynrml.RMLType> inrmltypelst;
  input Boolean inbool;
  output String outstring;
algorithm
  outstring :=matchcontinue(inrmltypelst,inbool)
    local
      list<Absynrml.RMLType> rest;
      Absynrml.RMLType first;
      Boolean b_ei,b;
      String fid,tid,rid;
    case ({},_) then "";

    case (first::rest,b_ei)
      equation
        (fid,b)=get_specialtype_id(first,"",b_ei);
        rid=get_specialtypetuple_id(rest,b_ei);
        tid=stringAppend(fid,rid);
      then
        tid;
  end matchcontinue;
end get_specialtypetuple_id;

public function get_specialtype_id
  "special function to extract id from RML types and add to Structures in MetaModelica AST"
  input Absynrml.RMLType inrmltype;
  input String instring;
  input Boolean inbool;
  output String outstring;
  output Boolean outbool;
algorithm
  (outstring,outbool):= matchcontinue(inrmltype,instring,inbool)
    local
      String iid,uid,str1,str2,rid,tid,tuple_String;
      String cid,cid1,aid1,aid,id,mid,fid,fid1;
      Boolean b_ei,b;
      Absynrml.RMLType last;
      list<Absynrml.RMLType> intype,outtype,typelist;
      Absynrml.RMLIdent nid;
    case(Absynrml.RMLTYPE_SIGNATURE(Absynrml.CALLSIGN(intype,outtype)),id,b_ei)
      equation
        iid=get_specialtypetuple_id(intype,false);
        uid=get_specialtypetuple_id(outtype,false);
        str1=stringAppend(iid,"To");
        str2=stringAppend(str1,uid);
        rid=stringAppend("FuncType","");
        (cid,b)=get_alternative_typeid(rid,b_ei);
      then
        (cid,b);

    case(Absynrml.RMLTYPE_TYCONS(last::{},nid),id,b_ei)
      equation
        mid=get_rml_id(nid,true);
        cid=transform_typeid(mid,false);
        tid=stringAppend(cid,id);
        (fid,_)=get_specialtype_id(last,cid,b_ei);
        fid1=stringAppend(fid,id);
        (aid,b)=get_alternative_typeid(fid1,b_ei);

      then
        (aid,b);

    case (Absynrml.RMLTYPE_TYVAR(nid),id,b_ei)
      equation
        cid=get_tyvar_id(nid,id);
        tid=stringAppend(cid,id);
        (aid,false)=get_alternative_typeid(tid,b_ei);
        b=false;
      then
        (aid,b);


    case (Absynrml.RMLTYPE_USERDEFINED(nid),id,b_ei)
      equation

        mid=get_rml_id(nid,true);
        cid=transform_typeid(mid,false);
        (cid1,_)=get_alternative_typeid(cid,b_ei);
        tid=stringAppend(cid1,id);
        (aid,b)=get_alternative_typeid(tid,b_ei);

      then
        (aid,b);

    case (Absynrml.RMLTYPE_TUPLE(typelist),id,b_ei)
      equation
        tid=get_specialtypetuple_id(typelist,b_ei);
        fid=stringAppend("tuple",tid);
        (aid,_)=get_alternative_typeid(fid,b_ei);
        cid1=stringAppend(aid,id);
        (aid1,b)=get_alternative_typeid(cid1,b_ei);
      then
        (aid1,b);

    case (Absynrml.RMLTYPE_TYCONS({},nid),id,b_ei)
      equation

        mid=get_rml_id(nid,true);
        cid=transform_typeid(mid,false);
        (aid,b)=get_alternative_typeid(cid,b_ei);
        tid=stringAppend(aid,id);
      then
        (tid,b);

  end matchcontinue;
end get_specialtype_id;

public function get_record_id
  "help function to extract id from RML datatype statements and add to Record structure identifier in MetaModelica"
  input Absynrml.RMLType inrmltype;
  input Boolean inbool;
  output Absyn.Path outpath;
algorithm
  outpath:= matchcontinue(inrmltype,inbool)
    local
      Absynrml.RMLType ttype;
      Absynrml.RMLIdent id;
      Boolean b_ei;
      String aid,mid,cid,ttype_id;
    case(Absynrml.RMLTYPE_USERDEFINED(id),b_ei)
      equation
        mid=get_rml_id(id,true);
        cid=transform_typeid(mid,false);
        (aid,true)=get_alternative_typeid(cid,b_ei);
      then
        Absyn.IDENT(aid);
    case(Absynrml.RMLTYPE_USERDEFINED(id),b_ei)
      equation
        mid=get_rml_id2(id);
        cid=transform_typeid(mid,false);
      then
        Absyn.IDENT(cid);
    case(ttype,b_ei)
      equation
        (ttype_id,_)=get_specialtype_id(ttype,"",b_ei);
      then
        Absyn.IDENT(ttype_id);
  end matchcontinue;
end get_record_id;

public function get_valtype_id
  "help function to extract identifer from RMLtype userdefined AST"
  input Absynrml.RMLType inrmltype;
  input Boolean inbool;
  output String outstring;
algorithm
  outstring:= matchcontinue(inrmltype,inbool)
    local
      Absynrml.RMLType ttype;
      Boolean b_ei,b;
      String aid,cid,ttype_id,mid,cid,aid,ttype_id;
      Absynrml.RMLIdent id;
    case(Absynrml.RMLTYPE_USERDEFINED(id),b_ei)
      equation
        mid=get_rml_id(id,true);
        cid=transform_typeid(mid,false);
        (aid,true)=get_alternative_typeid(cid,b_ei);
      then
        aid;
    case(Absynrml.RMLTYPE_USERDEFINED(id),b_ei)
      equation
        mid=get_rml_id2(id);
        cid=transform_typeid(mid,false);
      then
        cid;
    case(ttype,b_ei)
      equation
        (ttype_id,_)=get_specialtype_id(ttype,"",b_ei);
      then
        ttype_id;
  end matchcontinue;
end get_valtype_id;

/*Fucntions to get the types that builds special constructions like lists,vectors,records,option..*/

public function is_unique
"help function to extract id from lists"
  input String instring;
  input list<String> instringlst;
  output Boolean outbool;
algorithm
  outbool:= matchcontinue(instring,instringlst)
    local
      String id;
      list<String> list1;
      Boolean b,a;
    case(_,_)
      equation
      then
        false;
    case (id,list1)
      equation
        b=listMember(id,list1);
        a=boolNot(b);
      then
        a;
  end matchcontinue;
end is_unique;

public function is_unique_list
"help function to extract id from lists"
  input list<String> inidentlst;
  output Boolean outbool;
algorithm
  outbool := matchcontinue(inidentlst)
    local
      Boolean b;
      String first;
      list<String> rest;
    case({}) then true;

    case(first::rest)
      equation
        false=is_unique(first,rest);
      then
        false;

    case(_::rest)
      equation
        b=is_unique_list(rest);
      then
        b;

  end matchcontinue;
end is_unique_list;

public function get_specialtypes_lst
"help function to extract id from RMLtype list types"

  input list<Absynrml.RMLType> inrmltype;
  input Boolean inbool;
  input Integer ininteger;
  output list<Absyn.ElementItem> outelement;
  output Integer outinteger;
algorithm
  (outelement,outinteger):= matchcontinue(inrmltype,inbool,ininteger)
    local
      Absynrml.RMLType first;
      list<Absynrml.RMLType> rest;
      list<Absyn.ElementItem> type_list,ftypes,ftypes1,rtypes,rtypes1;
      Boolean b_ei;
      Integer fc,fc1,fc2;


    case(first::rest,b_ei,fc)
      equation
        (ftypes,fc1)=get_specialtypes(first,b_ei,NONE(),fc);
        (rtypes,fc2)=get_specialtypes_lst(rest,b_ei,fc1);
        type_list=listAppend(ftypes,rtypes);
      then
        (List.unique(type_list),fc2);

    case ({},_,fc)
      equation
      then
        ({},fc);

  end matchcontinue;
end get_specialtypes_lst;

public function get_specialtypes
"Special function to extract special type id from rmltypes and convert to MEtaModelica structure lile tuple, list,option"
  input Absynrml.RMLType inrmltype;
  input Boolean inbool;
  input Option<Absyn.Comment> instring2;
  input Integer ininteger;
  output list<Absyn.ElementItem> outtype;
  output Integer outInteger;
algorithm
  (outtype,outInteger):= matchcontinue(inrmltype,inbool,instring2,ininteger)
    local
      Absynrml.RMLType sign,tyvar,last;
      list<Absynrml.RMLType> signin,signout;
      Absyn.Class class1,class2,class3;
      Absyn.ClassDef derived;
      Absyn.ElementItem elementitem,specialtypes;
      list<Absynrml.RMLType> typelist;
      list<Absyn.ElementItem> in_out_spec,in_out_decl,specialtypes_sub,elast,specialtypes1;
      String sfc,mid,cmid,mid1,spec_id,tspec_id,tspec_id1,type_id1,spec_id1,spec_id2,spec_id3,tuple_string,tuple_id;
      String type_id,utype_id,type_id1;
      list<String> il,ol;
      Option<Absyn.Comment> com;
      Boolean b_ei,b;
      Integer fc,fc1;
      Absyn.FunctionRestriction restriction;
      Absynrml.RMLIdent lid,id;
      Absyn.Info info:=Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));
      Boolean bi,b_dummy,bo;
      Integer ic;
      list<String> inspecids,outspecids,inlist,outlist,inlist1,outlist1;
      list<Absyn.ElementItem> mintypes,mouttypes,inout_types,inspecial,outspecial,inout_special;

    case (Absynrml.RMLTYPE_TUPLE(typelist),b_ei,com,fc)
      equation
        (specialtypes_sub,_)=get_specialtypes_lst(typelist,b_ei,0);
        tuple_id=get_specialtypetuple_id(typelist,b_ei);
        type_id=stringAppend("tuple",tuple_id);
        (_,false)=get_alternative_typeid(type_id,b_ei);
        derived=get_specialtype_record(typelist,b_ei,com);
        class1=create_class(type_id,Absyn.R_TYPE(),derived,info);
        elementitem=create_standard_elementitem(Absyn.CLASSDEF(false,class1),info);
        specialtypes1=listAppend(specialtypes_sub,{elementitem});

      then
        (specialtypes1,fc);


    case(tyvar as Absynrml.RMLTYPE_TYVAR(lid),b_ei,com,fc)
      equation
        (type_id,false)=get_specialtype_id(tyvar,"",b_ei);
        derived=get_specialtype("replaceable",type_id,com);
        class1=create_class_parts("a",Absyn.R_TYPE(),false,{},{},true,info);
        specialtypes=create_replaceable_elementitem(Absyn.CLASSDEF(true,class1));

      then
        (specialtypes::{},fc);

    case(Absynrml.RMLTYPE_TYCONS({Absynrml.RMLTYPE_TYVAR(lid)},id),b_ei,com,fc)
      equation
        mid=get_rml_id(id,true);
        class1=create_class_parts(mid,Absyn.R_TYPE(),false,{},{},true,info);
        specialtypes=create_replaceable_elementitem(Absyn.CLASSDEF(true,class1));
      then
        (specialtypes::{},fc);


    case(Absynrml.RMLTYPE_TYCONS(Absynrml.RMLTYPE_USERDEFINED(lid)::{},id),b_ei,com,fc)
      equation
        mid=get_rml_id(id,true);
        cmid=transform_typeid(mid,false);

        mid1=transform_typeid(mid,true);

        spec_id=get_rml_id(lid,true);

        tspec_id=transform_typeid(spec_id,false);

        (tspec_id1,_)=get_alternative_typeid(tspec_id,b_ei);

        type_id=stringAppend(tspec_id1,cmid);

        type_id1=stringAppend(tspec_id,cmid);

        (_,false)=get_alternative_typeid(type_id,b_ei);

        spec_id1=get_rml_id2(lid);

        spec_id2=transform_typeid(spec_id1,false);

        (spec_id3,_)=get_alternative_typeid(spec_id2,b_ei);

        derived=get_specialtype(mid1,spec_id3,com);

        class1=create_class(type_id,Absyn.R_TYPE(),derived,info);

        specialtypes=create_standard_elementitem(Absyn.CLASSDEF(false,class1),info);

      then
        (specialtypes::{},fc);


    case(Absynrml.RMLTYPE_TYCONS(last::{},id),b_ei,com,fc)
      equation

        mid=get_rml_id(id,true);
        cmid=transform_typeid(mid,false);
        mid1=transform_typeid(mid,true);
        (spec_id1,b)=get_specialtype_id(last,"",b_ei);
        spec_id=add_v_if_tyvar(spec_id1,last);
        type_id=stringAppend(spec_id1,cmid);
        (_,false)=get_alternative_typeid(type_id,b_ei);
        derived=get_specialtype(mid1,spec_id1,NONE());
        class1=create_class(type_id,Absyn.R_TYPE(),derived,info);
        elementitem=create_standard_elementitem(Absyn.CLASSDEF(false,class1),info);
        (elast,_)=get_specialtypes(last,b_ei,com,fc);
        specialtypes1=listAppend(elast,{elementitem});

      then
        (specialtypes1,fc);



    case (Absynrml.RMLTYPE_SIGNATURE(Absynrml.CALLSIGN(signin,signout)),b_ei,com,fc)
      equation

        (inspecial,_) = get_specialtypes_lst(signin,false,0);
        (outspecial,_) = get_specialtypes_lst(signout,false,0);
        (inspecids,inlist) = get_iotypeids("in",0,signin,false);
        bi = is_unique_list(inlist);
        (mintypes,inlist1) = transform_iotype(0,inlist,inspecids,Absyn.INPUT(),bi);
        (outspecids,outlist) = get_iotypeids("out",0,signout,false);
        bo = is_unique_list(outlist);
        (mouttypes,outlist1) = transform_iotype(0, outlist, outspecids, Absyn.OUTPUT(), bo);
        inout_special = listAppend(inspecial,outspecial);
        inout_types = listAppend(mintypes,mouttypes);
        utype_id = stringAppend("FuncType", "");
        class1 = create_class_parts(utype_id, Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.NO_PURITY())), true,{Absyn.PUBLIC(inout_types)}, {}, true,info);
        elementitem = create_standard_elementitem(Absyn.CLASSDEF(false,class1),info);

      then
        ({elementitem},fc);

    case (_,_,_,fc)
    then
      ({},fc);


  end matchcontinue;
end get_specialtypes;



public function get_specialtype
  "special function to get id from rmltypes like list, option and translate to MEtaModelica AST classdef"
  input String instring;
  input String inident;
  input Option<Absyn.Comment> instring2;
  output Absyn.ClassDef outclassdef;
algorithm
  outclassdef:= matchcontinue(instring,inident,instring2)
    local
      String spec_type, spec_id;
      Option<Absyn.Comment> com;
      Boolean b;
      Integer i;

    case(spec_type,spec_id,com)
      equation
      then
        Absyn.DERIVED_TYPES(Absyn.IDENT(spec_type),{Absyn.IDENT(spec_id)},com);
  end matchcontinue;
end get_specialtype;

public function get_record_ides
  "help function to get record id from rmltype AST"
  input list<Absynrml.RMLType> inrmltype;
  input Boolean inbool;
  output list<Absyn.Path> outpath;
algorithm
  outpath:= matchcontinue(inrmltype,inbool)
    local
      Absyn.Path frid;
      list<Absyn.Path> rrid;
      list<Absynrml.RMLType> rest;
      Absynrml.RMLType first;
      Boolean b_ei;
    case({},_) then {};

    case ((first::rest),b_ei)
      equation
        frid=get_record_id(first,b_ei);
        rrid=get_record_ides(rest,b_ei);
      then
        (frid::rrid);
  end matchcontinue;
end get_record_ides;

public function get_specialtype_record
  "help function to get record id from rmltype AST with list structures to MEtaModelica AST classdef "
  input list<Absynrml.RMLType> inrmltype;
  input Boolean inbool;
  input Option<Absyn.Comment> instring;
  output Absyn.ClassDef outclassdef;
algorithm
  outclassdef:= matchcontinue(inrmltype,inbool,instring)
    local
      list<Absynrml.RMLType> typelist;
      list<Absyn.Path> pathlist;
      Boolean b_ei;
      Option<Absyn.Comment> com;
    case(typelist,b_ei,com)
      equation
        pathlist=get_record_ides(typelist,b_ei);
      then
        Absyn.DERIVED_TYPES(Absyn.IDENT("tuple"),pathlist,com);
  end matchcontinue;
end get_specialtype_record;

public function get_import_name
"help function to get id from with statements in rml and add to import statement in metamodelica"
  input String instring;
  output String outstring;
algorithm
  outstring:= matchcontinue(instring)
    local
      String s,name,name1;
      Integer i;
    case(s)
      equation
        i=stringLength(s);
        name=get_module_name(s,1,i,"");
      then
        name;
  end matchcontinue;
end get_import_name;

public function getClasses
  "function to get list of classes from list of elementitem"
  input list<Absyn.ElementItem> inelementlst;
  output list<Absyn.Class> outclass;
algorithm
  outclass:=matchcontinue(inelementlst)
    local
      list<Absyn.ElementItem> rest;
      list<Absyn.Class> classes;
      Absyn.Class class1;
    case(Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_,Absyn.CLASSDEF(_,class1),_,_))::rest)
      equation
        classes=getClasses(rest);
      then
        class1::classes;
    case({})
    then
      {};
  end matchcontinue;
end getClasses;

public function get_module_name
" function extract the id from module in rml"
  input String instring;
  input Integer ininteger;
  input Integer ininteger1;
  input String instring1;
  output String outstring;
algorithm
  outstring:= matchcontinue(instring,ininteger,ininteger1,instring1)
    local
      Boolean bool;
      String s,ns,ss,nstr,str,str1;
      Integer i,l,ic;
    case(s,i,l,ns)
      equation
        true=intGe(i,l);
      then
        "";
    case (s,i,l,ns)
      equation

        "." =stringGetStringChar(s,i);

      then
        ns;
    case(s,i,l,ns)
      equation

        ic=intAdd(i,1);
        ss=stringGetStringChar(s,ic);

        nstr=stringAppend(ns,ss);

        str=get_module_name(s,ic,l,nstr);

        str1=System.trim(str,".");

      then
        str1;
  end matchcontinue;
end get_module_name;


public function check_filenames
  input String instring;
  input String instring1;
  output Boolean outbool;
algorithm
  outbool:= matchcontinue(instring,instring1)
    local
      String f1,f2;
      Integer l1,l2,start;
      Boolean bool;
    case(f1,f2)
      equation
        l1=stringLength(f1);
        l2=stringLength(f2);
        true=intGe(l2,l1);
        start=intSub(l2,l1);
        true=System.isIdenticalFile(f2,f1);
      then
        true;
    case(_,_)
      equation  then false;
  end matchcontinue;
end check_filenames;

public function compare_filenames
  input String instring;
  input String instring1;
  input Integer ininteger;
  input Integer ininteger1;
  output Boolean outbool;
algorithm
  outbool:= matchcontinue(instring,instring1,ininteger,instring1)
    local
      String f1,f2,s,st,s1,s2;
      Integer i,max,ic,st;
      Boolean bool;
    case(f1,f2,i,s)
      equation
        max=stringLength(f1);
        true=intGe(i,max);
      then
        true;
    case(f1,f2,i,st)
      equation
        ic=intAdd(i,1);
        s1=stringGetStringChar(f1,i);
        is=intAdd(i,st);
        s2=stringGetStringChar(f2,is);
        0=System.strcmp(s1,s2);
        true=compare_filenames(f1,f2,ic,st);
      then
        true;
    case(_,_,_,_)
    then
      false;
  end matchcontinue;
end compare_filenames;



public function get_alternative_typeid
  "special function to create new type id with same names and to differentitate between them by adding numbers at the end
  eg: interger1,integer2"
  input String instring;
  input Boolean inbool;
  output String outstring;
  output Boolean outbool;
algorithm
  (outstring,outbool):= matchcontinue(instring,inbool)
    local
      String the_typeid,a_typeid;
      Absyn.Ident ctype_id;
      String alt_typeid;
      Boolean bool_ext,b_ei,b;
    case(the_typeid,_)
    then
      (the_typeid,false);

    case(the_typeid,b_ei)
      equation
        (a_typeid,b)=get_alternative_typeid(the_typeid,b_ei);
      then
        (a_typeid,b);


    case(the_typeid,bool_ext)
      equation
      then
        (the_typeid,true);

    case(_,_)
    then
      ("",true);
  end matchcontinue;
end get_alternative_typeid;


public function create_local_type
  input list<Ident> inident;
  input list<Ident> inident1;
  output list<Absyn.ElementItem> outelement;
algorithm
  outelement:= matchcontinue(inident,inident1)
    local
      Integer n,i=0;
      Ident first1,first2,firsttype,first,firstvar;
      list<Ident> types,variables,resttypes,restvariables,rest,restvar;
      Absyn.ElementSpec components;
      list<Absyn.ElementItem> restspec,elist1,reitems;
      Absyn.ElementItem elist,eitems;
      Absyn.Info info:=Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));

    case({},{})  then {};
    case(first::{},restvar)
      equation
        components = create_components(restvar, first, Absyn.BIDIR(),NONE());
        eitems = create_standard_elementitem(components,info);
      then
        {eitems};

    case (first::rest,firstvar::restvar)
      equation
        eitems=assign_type(first,firstvar);
        reitems=create_local_type(rest,restvar);
      then
        (eitems::reitems);
  end matchcontinue;
end create_local_type;

public function assign_type
  input Ident inident;
  input Ident inident1;
  output Absyn.ElementItem outelementitem;
algorithm
  outelementitem:= matchcontinue(inident,inident1)
    local
      Absyn.ElementItem eitem;
      Absyn.ElementSpec components;
      Ident firsttype,firstvar;
      Absyn.Info info:=Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));

    case(firsttype,firstvar)
      equation
        components = create_components({firstvar}, firsttype, Absyn.BIDIR(),NONE());
        eitem = create_standard_elementitem(components,info);
      then
        eitem;
  end matchcontinue;
end assign_type;

/* Special Help function to create structures in the modelica-ast*/
public function create_classdef
  input Ident inident;
  input Absyn.Restriction inrestriction;
  input list<Absyn.ClassPart> inclasspart;
  input list<String> instring;
  input Boolean inbool;
  input Absyn.Info ininfo;
  output Absyn.ElementSpec outspec;
algorithm
  outspec:= matchcontinue(inident,inrestriction,inclasspart,instring,inbool,ininfo)
    local
      Absyn.Ident id;
      Absyn.Restriction restriction;
      list<Absyn.ClassPart> classparts;
      Absyn.Class class1;
      // Absyn.Info info:=Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));
      Absyn.Info info;
      list<String> com;
      Boolean b;
    case(id,restriction,classparts,com,b,info)
      equation
        class1=create_class_parts(id,restriction,false,classparts,com,b,info);
      then
        Absyn.CLASSDEF(false,class1);
  end matchcontinue;
end create_classdef;


public function get_imp_option
  input Ident instring;
  output Absyn.Path outpath;
algorithm
  outpath:= matchcontinue(instring)
    local
      Ident name;
      Absyn.Path fail1,prefix;

    case(name)
      equation
        prefix=get_prefix(name);
      then
        prefix;
  end matchcontinue;
end get_imp_option;

public function get_prefix
  input Ident instring;
  output Absyn.Path outpath;
algorithm
  outpath:= matchcontinue(instring)
    local
      Ident name;
    case(name)
    then
      Absyn.IDENT(name);
  end matchcontinue;
end get_prefix;

public function create_import
  input Ident inident;
  input Option<Absyn.Comment> instring;
  input Absyn.Info ininfo;
  output Absyn.ElementSpec outspec;
algorithm
  outspec:= matchcontinue(inident,instring,ininfo)
    local
      Option<Absyn.Comment> com;
      Absyn.Info info;
      Ident name;
      Absyn.Path prefix;
    case(name,com,info)
      equation
        prefix=get_imp_option(name);
      then
        Absyn.IMPORT(Absyn.QUAL_IMPORT(prefix),com,info);

        /*default prefix */
    case(name,com,info)
    then
      // Absyn.IMPORT(Absyn.QUAL_IMPORT(Absyn.QUALIFIED("OpenModelica",Absyn.QUALIFIED("Compiler",Absyn.IDENT(name)))),com,info);
      Absyn.IMPORT(Absyn.QUAL_IMPORT(Absyn.IDENT(name)),com,info);


  end matchcontinue;
end create_import;

public function create_class_parts
  input Ident inident;
  input Absyn.Restriction inrestriction;
  input Boolean inbool;
  input list<Absyn.ClassPart> inclasspart;
  input list<String> incomment;
  input Boolean inbool1;
  input Absyn.Info ininfo;
  output Absyn.Class outclass;
algorithm
  outclass:= matchcontinue(inident,inrestriction,inbool,inclasspart,incomment,inbool1,ininfo)
    local
      Ident id;
      Absyn.Restriction restriction;
      Boolean partial1;
      list<Absyn.ClassPart> classparts;
      Absyn.Info info;
      list<String> com;
      Option<String> mcom;
      Boolean b;
      Absyn.Info info;
    case(id,restriction,partial1,classparts,com,b,info)
      equation

        //info=Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));
        mcom=get_comment(com,b);
      then
        Absyn.CLASS(id,partial1,false,false,restriction,Absyn.PARTS({},{},classparts,mcom),info);
  end matchcontinue;
end create_class_parts;

public function create_class
  input Ident inident;
  input Absyn.Restriction inrestriction;
  input Absyn.ClassDef inclassdef;
  input Absyn.Info ininfo;
  output Absyn.Class outclass;
algorithm
  outclass:= matchcontinue(inident,inrestriction,inclassdef,ininfo)
    local
      Ident id;
      Absyn.Restriction restriction;
      Absyn.ClassDef classdef;
      Absyn.Info info;
      //Absyn.Info info:=Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));
      Boolean b;
    case(id,restriction,classdef,info)
    then
      Absyn.CLASS(id,false,false,false,restriction,classdef,info);
  end matchcontinue;
end create_class;

public function create_elementitem_list
  input list<Absyn.Class> inclass;
  input Absyn.Info ininfo;
  output list<Absyn.ElementItem> outelementlist;
algorithm
  outelementlist:= matchcontinue(inclass,ininfo)
    local
      list<Absyn.Class> rest;
      Absyn.Class first;
      Absyn.ElementItem efirst;
      list<Absyn.ElementItem> erest;
      Absyn.Info info;
      Boolean b;
    case({},info)then {};
    case(first::rest,info)
      equation
        efirst=create_standard_elementitem(Absyn.CLASSDEF(false,first),info);
        erest=create_elementitem_list(rest,info);
      then
        (efirst::erest);
  end matchcontinue;
end create_elementitem_list;

public function create_standard_elementitem
  input Absyn.ElementSpec inelementspec;
  input Absyn.Info ininfo;
  output Absyn.ElementItem outelement;
algorithm
  outelement:= matchcontinue(inelementspec,ininfo)
    local
      Absyn.Info info;

      Absyn.ElementSpec elementspec;
    case(elementspec,info)
      equation
        // info=Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));

      then
        Absyn.ELEMENTITEM(Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),elementspec,info,NONE()));
  end matchcontinue;
end create_standard_elementitem;

public function create_replaceable_elementitem
  input Absyn.ElementSpec inelementspec;
  output Absyn.ElementItem outelementitem;
algorithm
  outelementitem:= matchcontinue(inelementspec)
    local
      Absyn.ElementSpec elementspec;
      Absyn.Info info:= Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));

    case(elementspec)
    then
      Absyn.ELEMENTITEM(Absyn.ELEMENT(false,SOME(Absyn.REPLACEABLE()),Absyn.NOT_INNER_OUTER(),elementspec,info,NONE()));
  end matchcontinue;
end create_replaceable_elementitem;

public function create_standard_algorithmitem
  input Absyn.Algorithm inalgorithm;
  input Absyn.Info ininfo;
  output Absyn.AlgorithmItem outalgorithm;
algorithm
  outalgorithm:= matchcontinue(inalgorithm,ininfo)
    local
      Absyn.Algorithm algorithm1;
      // Absyn.Info info:= Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));
      Absyn.Info info;
    case(algorithm1,info)
    then
      Absyn.ALGORITHMITEM(algorithm1,NONE(),info);
  end matchcontinue;
end create_standard_algorithmitem;

public function create_algorithm_inputs
  input list<Ident> inident;
  input Boolean inbool;
  output list<Absyn.Exp> outexp;
algorithm
  outexp:= matchcontinue(inident,inbool)
    local
      Boolean b;
      Ident first_input;
      list<Ident> rest_inputs;
      list<Absyn.Exp> rest_inputs1;

    case({},false) then Absyn.BOOL(true)::{};
    case({},true)  then {};
    case(first_input::rest_inputs,b)
      equation
        rest_inputs1=create_algorithm_inputs(rest_inputs,true);
      then
        Absyn.CREF(Absyn.CREF_IDENT(first_input,{}))::rest_inputs1;
  end matchcontinue;
end create_algorithm_inputs;

public function create_algorithm_outputs
  input list<Ident> inident;
  output list<Absyn.ComponentRef> outcomponentref;
algorithm
  outcomponentref:= matchcontinue(inident)
    local
      Ident first_output;
      list<Ident> rest_outputs;
      list<Absyn.ComponentRef> rest_outputs1;

    case({}) then {};

    case(first_output::rest_outputs)
      equation
        rest_outputs1=create_algorithm_outputs(rest_outputs);
      then
        Absyn.CREF_IDENT(first_output,{})::rest_outputs1;
  end matchcontinue;
end create_algorithm_outputs;

public function create_algorithm_match
  input list<Ident> inident;
  input list<Ident> inident1;
  input list<Absyn.ElementItem> inelementlist;
  input list<Absyn.Case> incaselist;
  output Absyn.Algorithm outalgorithm;
algorithm
  outalgorithm:= matchcontinue(inident,inident1,inelementlist,incaselist)
    local
      list<Ident> inlist,outlist;
      list<Absyn.ElementItem> eilist;
      list<Absyn.Case> case_list;
      list<Absyn.Exp> input_list;
      list<Absyn.ComponentRef> output1;
    case(inlist,outlist,eilist,case_list)
      equation
        input_list=create_algorithm_inputs(inlist,true);
        output1=create_algorithm_outputs(outlist);
      then
        Absyn.ALG_MATCH(output1,Absyn.TUPLE(input_list),eilist,case_list);
  end matchcontinue;
end create_algorithm_match;

public function create_algorithm_simplematch
  input list<Absyn.EquationItem> inequationitem;
  output Absyn.Algorithm outalgorithm;
algorithm
  outalgorithm:= matchcontinue(inequationitem)
    local
      list<Absyn.EquationItem> equations;
    case(equations) then Absyn.ALG_SIMPLEMATCH(equations);
  end matchcontinue;

end create_algorithm_simplematch;

public function create_components_init
  input list<Ident> inident;
  input String instring;
  input Absyn.Variability invar;
  input Absyn.Direction indir;
  input Absyn.Exp inexp;
  input Option<Absyn.Comment> instringlst;
  output Absyn.ElementSpec outcomponent;
algorithm
  outcomponent:= matchcontinue(inident,instring,invar,indir,inexp,instringlst)
    local
      list<Ident> var_lst;
      String the_type;
      Absyn.Variability var;
      Absyn.Direction dir;
      Absyn.Info info;
      Absyn.Exp exp;
      Option<Absyn.Comment> com;
      list<Absyn.ComponentItem> cilist;
      Absyn.ElementSpec components;
    case(var_lst,the_type,var,dir,exp,com)
      equation

        info=Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));
        cilist=create_componentitems(var_lst,SOME(Absyn.CLASSMOD({},Absyn.EQMOD(exp,info))),com);
        components=create_components_lst(cilist,the_type,var,dir);
      then
        components;
  end matchcontinue;
end create_components_init;

public function create_components
  input list<Ident> inident;
  input String instring;
  input Absyn.Direction indir;
  input Option<Absyn.Comment> incomment;
  output Absyn.ElementSpec outcomponent;
algorithm
  outcomponent:= matchcontinue(inident,instring,indir,incomment)
    local
      String the_type;
      list<Ident> var_lst;
      Absyn.Direction dir;
      Absyn.Variability var;
      Option<Absyn.Comment> com;
      Absyn.ElementSpec components;
      list<Absyn.ComponentItem> cilist;
    case(var_lst,the_type,dir,com)
      equation
        cilist=create_componentitems(var_lst,NONE(),com);
        components=create_components_lst(cilist,the_type,Absyn.VAR(),dir);
      then
        components;
  end matchcontinue;

end create_components;

public function create_components_lst
  input list<Absyn.ComponentItem> incomponent;
  input String instring;
  input Absyn.Variability invar;
  input Absyn.Direction indir;
  output Absyn.ElementSpec outspec;
algorithm
  outspec:= matchcontinue(incomponent,instring,invar,indir)
    local
      list<Absyn.ComponentItem> component_items;
      Absyn.Direction dir;
      Absyn.Variability var;
      Absyn.Parallelism par:=Absyn.NON_PARALLEL();

      String the_type;
    case(component_items,the_type,var,dir)
    then
      Absyn.COMPONENTS(Absyn.ATTR(false,false,par,var,dir,{}),Absyn.TPATH(Absyn.IDENT(the_type),NONE()),component_items);
  end matchcontinue;
end create_components_lst;

public function create_componentitem
  input Ident invar;
  input Option<Absyn.Modification> inmod;
  input Option<Absyn.Comment> instring;
  output Absyn.ComponentItem outcomponent;
algorithm
  outcomponent:= matchcontinue(invar,inmod,instring)
    local
      Absyn.Direction dir;
      Ident var,var1;
      Option<Absyn.Modification> exp;
      Option<Absyn.Comment> com;
    case(var,exp,com)
      equation
      then
        Absyn.COMPONENTITEM(Absyn.COMPONENT(var,{},exp),NONE(),com);
  end matchcontinue;
end create_componentitem;

public function create_componentitems
  input list<Ident> inident;
  input Option<Absyn.Modification> inmod;
  input Option<Absyn.Comment> instring;
  output list<Absyn.ComponentItem> outcomponent;
algorithm
  outcomponent:= matchcontinue(inident,inmod,instring)
    local
      Ident fvar;
      list<Ident> rest;
      Option<Absyn.Modification> exp;
      Option<Absyn.Comment> com;
      Absyn.ComponentItem ci;
      list<Absyn.ComponentItem> cilst;
    case({},_,_) then {};

    case(fvar::rest,exp,com)
      equation
        ci=create_componentitem(fvar,exp,com);
        cilst=create_componentitems(rest,exp,com);
      then
        (ci::cilst);
  end matchcontinue;
end create_componentitems;

public function create_standard_equationitem
  input Absyn.Equation inequation;
  input Option<Absyn.Comment> incomment;
  input Absyn.Info ininfo;
  output Absyn.EquationItem outeqitem;
algorithm
  outeqitem:= matchcontinue(inequation,incomment,ininfo)
    local
      String filepath;
      Integer linenumber;
      Absyn.Equation equation1;
      Option<Absyn.Comment> comment;
      Absyn.Comment comment1;
      Absyn.ElementArg elementarg;
      Absyn.Modification modification;
      Absyn.Annotation ann;
      // Absyn.Info info:= Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));
      Absyn.Info info;
    case(equation1,comment,info)
      equation
        (filepath,linenumber)=getfileinfo(info);
        modification=Absyn.CLASSMOD({},Absyn.EQMOD(Absyn.TUPLE({Absyn.STRING(filepath),Absyn.INTEGER(linenumber)}),info));
        elementarg=Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT("__OpenModelica_FileInfo"),SOME(modification),NONE(),info);
        ann=Absyn.ANNOTATION({elementarg});
        comment1=Absyn.COMMENT(SOME(ann),NONE());

      then
        Absyn.EQUATIONITEM(equation1,SOME(comment1),info);
        // Absyn.EQUATIONITEM(equation1,SOME(comment),info);
  end matchcontinue;
end create_standard_equationitem;

public function getfileinfo
  input Absyn.Info ininfo;
  output String outstring;
  output Integer outinteger;
algorithm
  (outstring,outinteger):= matchcontinue(ininfo)
    local
      String filename,filepath,filepath1;
      Boolean b;
      Integer lns,cns,lne,cne;
      Absyn.TimeStamp timestamp;
    case(Absyn.INFO(filename,b,lns,cns,lne,cne,timestamp))
      equation
        filepath=System.realpath(filename);
        filepath1=System.stringReplace(filepath,"\\","/");
      then
        (filepath1,lns);
  end matchcontinue;

end getfileinfo;

public function create_functionargs
  input list<Absyn.Exp> inexp;
  input list<Absyn.NamedArg> innamedargs;
  output Absyn.FunctionArgs outargs;
algorithm
  outargs:= matchcontinue(inexp,innamedargs)
    local
      list<Absyn.Exp> exp_list;
      list<Absyn.NamedArg> name_list;
    case(exp_list,name_list)
    then
      Absyn.FUNCTIONARGS(exp_list,name_list);
  end matchcontinue;
end create_functionargs;

public function create_type
  input Ident inident;
  input Option<Absyn.Comment> incomment;
  output Absyn.ClassDef outclassdef;
algorithm
  outclassdef:= matchcontinue(inident,incomment)
    local
      Ident id;
      Option<Absyn.Comment> com;
    case(id,com)
    then
      Absyn.DERIVED(Absyn.TPATH(Absyn.IDENT(id),NONE()),Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.VAR(),Absyn.BIDIR(),{}),{},com);

  end matchcontinue;
end create_type;

public function create_cref
  input Ident inident;
  output Absyn.ComponentRef outcomponentref;
algorithm
  outcomponentref:= matchcontinue(inident)
    local
      Ident id;
    case(id) then Absyn.CREF_IDENT(id,{});
  end matchcontinue;
end create_cref;

public function create_cref_sub
  input Ident inident;
  input list<Absyn.Subscript> inscript;
  output Absyn.ComponentRef outcomponentref;
algorithm
  outcomponentref:= matchcontinue(inident,inscript)
    local
      Ident id;
      list<Absyn.Subscript> sub;
    case(id,sub) then  Absyn.CREF_IDENT(id,sub);
  end matchcontinue;
end create_cref_sub;

public function create_exp_cref
  input Ident inident;
  input list<Absyn.Subscript> inscript;
  output Absyn.Exp outexp;
algorithm
  outexp:= matchcontinue(inident,inscript)
    local
      Ident id;
      list<Absyn.Subscript> sub;
      Absyn.ComponentRef cref;
    case(id,sub)
      equation
        cref=create_cref_sub(id,sub);
      then
        Absyn.CREF(cref);
  end matchcontinue;
end create_exp_cref;

/*end of modelic AST constucts*/

/*Start of Transformation Relations*/


public function transform_typeid
"special function to tansform some built in  datatypes id to MetaModelica builtin types"
  input String instring;
  input Boolean inbool;
  output String outstring;
algorithm
  outstring:= matchcontinue (instring,inbool)
    local
      String id,list_String;
    case ("int",_) then "Integer";
    case ("real",_) then "Real";
    case ("bool",_) then "Boolean";
    case ("string",_) then "String";
    case ("char",_) then "String";
    case ("array",_) then "Array";
    case ("option",_) then "Option";
    case ("vector",_) then "Array";
    case(id,false) then  id;
    case(id,true) then id;
    case (id,true)
      equation
        false = is_unique(id, {"list","list_"});
      then
        "list";
    case (id,_) then id;
  end matchcontinue;
end transform_typeid;

public function transform_literal
"function to tranlsate rml literals to MetaModelica Strings"
  input Absynrml.RMLLiteral inrmlliteral;
  output Absyn.Exp outexp;
  output list<Ident> outidentlst;
algorithm
  (outexp,outidentlst):= matchcontinue(inrmlliteral)
    local
      Integer i,l;
      Real r;
      String s,ts,s1;

    case(Absynrml.RMLLIT_CHAR(i))
      equation
        s=intStringChar(i);
      then
        (Absyn.STRING(s),{s});

    case(Absynrml.RMLLIT_STRING(s))
      equation
        ts=System.trim(s,"\"");
      then
        (Absyn.STRING(ts),{ts});

    case(Absynrml.RMLLIT_INTEGER(i))
    then
      (Absyn.INTEGER(i),{});

    case(Absynrml.RMLLIT_REAL(r))
    then
      (Absyn.REAL(r),{});
  end matchcontinue;
end transform_literal;


public function transform_expression_list
  "function to translate RML AST expression list to MEtaModelica AST expression list"
  input list<Absynrml.RMLExp> inexp;
  output list<Absyn.Exp> outexp;
  output list<Ident> outident;
algorithm
  (outexp,outident):= matchcontinue(inexp)
    local
      Absynrml.RMLExp last,first;
      Absyn.Exp mlast,mfirst;
      list<Absyn.Exp> mrest;
      list<Absynrml.RMLExp> rest;
      list<Ident> ifirst,irest,ids;
    case({})then ({},{});
    case(first::rest)
      equation
        (mfirst,ifirst)=transform_expression(first);
        (mrest,irest)=transform_expression_list(rest);
        ids=listAppend(ifirst,irest);
      then
        (mfirst::mrest,ids);

    case(last::{})
      equation
        (mlast,irest)=transform_expression(last);
      then
        (mlast::{},irest);
  end matchcontinue;
end transform_expression_list;


public function transform_expression
  "function to translate RML AST expression to MEtaModelica AST expression"
  input Absynrml.RMLExp inexp;
  output Absyn.Exp outexp;
  output list<Ident> outident;
algorithm
  (outexp,outident):= matchcontinue(inexp)
    local
      Absynrml.RMLIdent id,id_java;
      String mid,mid1;
      list<String> mids,mids1,mids2;
      Absyn.Path path;
      Absyn.ComponentRef cref;
      Absyn.Operator op;
      Absynrml.RMLLiteral lit;
      Absynrml.RMLExp exp,left,right;
      Absyn.Exp mleft,mright,mexp_left,mexp_right,mexp;
      list<Absynrml.RMLExp> args,exp_list;
      list<Absyn.Exp> mexp_list;
      String pdb;

      /* record RMLCALL */
    case(Absynrml.RMLCALL(id,args))
      equation
        path=transform_id(id);
        (mexp_list,mids)=transform_expression_list(args);
      then
        (Absyn.MSTRUCTURAL(SOME(path),mexp_list),mids);

        /*record RMLREFERENCE*/
    case(Absynrml.RML_REFERENCE(id))
      equation

        mid=get_rml_id2(id);
        mid1=eliminaterecord(mid);
        id_java=transform_id_java(id);
        mid=get_rml_id2(id_java);
        cref=create_cref(mid1);
      then
        (Absyn.CREF(cref),{mid});

    case(Absynrml.RML_REFERENCE(id))
      equation
        mid=get_rml_id2(id);
      then
        (Absyn.MSTRUCTURAL(SOME(Absyn.IDENT(mid)),{}),{mid});

    case(Absynrml.RML_REFERENCE(id))
      equation

        "nil"=get_rml_id2(id);
      then
        (Absyn.MSTRUCTURAL(SOME(Absyn.IDENT("list")),{}),{});


    case(Absynrml.RML_REFERENCE(id))
      equation
        id=fixRMLbuiltins(id);
        mid=get_rml_id2(id);
        cref=create_cref(mid);
      then
        (Absyn.CREF(cref),{mid});

        /*record RMLIST*/
    case(Absynrml.RMLLIST(exp_list))
      equation
        mexp_list=transform_expression_list(exp_list);
      then
        (Absyn.MSTRUCTURAL(SOME(Absyn.IDENT("list")),mexp_list),{});

        /*record RMLCONS*/
    case(Absynrml.RMLCONS(left,right))
      equation
        (mleft,mids)=transform_expression(left);
        (mright,mids1)=transform_expression(right);
        mids2=listAppend(mids,mids1);
      then
        (Absyn.MSTRUCTURAL(SOME(Absyn.IDENT("cons")),{mleft,mright}),mids2);

        /*record BINARY*/
    case(Absynrml.RMLBINARY(left,op,right))
      equation
        mexp_left=transform_expression(left);
        mexp_right=transform_expression(right);
      then
        (Absyn.BINARY(mexp_left,op,mexp_right),{});

        /* record UNARY*/
    case(Absynrml.RMLUNARY(op,exp))
      equation
        mexp=transform_expression(exp);
      then
        (Absyn.UNARY(op,mexp),{});

        /*record RMLLIT*/
    case(Absynrml.RMLLIT(lit))
      equation
        (mexp,mids)=transform_literal(lit);
      then
        (mexp,{});

        /*record RMLNIL*/
    case(Absynrml.RMLNIL())
      equation
      then
        (Absyn.MSTRUCTURAL(NONE(),{}),{});

        /*record RMLTUPLE*/
    case(Absynrml.RMLTUPLE(exp_list))
      equation
        mexp_list=transform_expression_list(exp_list);
      then
        (Absyn.MSTRUCTURAL(NONE(),mexp_list),{});

  end matchcontinue;
end transform_expression;

function eliminaterecord
  input String instring;
  output String outstring;
algorithm
  outstring:= matchcontinue(instring)
    local
      String id;

    case("Env.BOOLTYPE") then "Env.BOOLTYPE()";
    case("Env.INTTYPE") then "Env.INTTYPE()";
    case("Env.REALTYPE") then "Env.REALTYPE()";
    case("BOOLTYPE") then "BOOLTYPE()";
    case("FCode.CtoI") then "FCode.CtoI()";
    case("FCode.ItoR") then "FCode.ItoR()";
    case("FCode.RtoI") then "FCode.RtoI()";
    case("FCode.ItoC") then "FCode.ItoC()";
    case("FCode.PtoI") then "FCode.PtoI()";
    case("FCode.CHAR") then "FCode.CHAR()";
    case("FCode.INT") then "FCode.INT()";
    case("FCode.REAL") then "FCode.REAL()";
    case("FCode.SKIP") then "FCode.SKIP()";
    case("FCode.IADD") then "FCode.IADD()";
    case ("FCode.ISUB") then "FCode.ISUB()";
    case ("FCode.IMUL") then "FCode.IMUL()";
    case ("FCode.IDIV") then "FCode.IDIV()";
    case ("FCode.IMOD") then "FCode.IMOD()";
    case ("FCode.IAND") then "FCode.IAND()";
    case ("FCode.IOR") then "FCode.IOR()";
    case ("FCode.ILT") then "FCode.ILT()";
    case ("FCode.ILE") then "FCode.ILE()";
    case ("FCode.IEQ") then "FCode.IEQ()";
    case ("FCode.RADD") then "FCode.RADD()";
    case ("FCode.RSUB") then "FCode.RSUB()";
    case ("FCode.RMUL") then "FCode.RMUL()";
    case ("FCode.RDIV") then "FCode.RDIV()";
    case ("FCode.RLT") then "FCode.RLT()";
    case ("FCode.RLE") then "FCode.RLE()";
    case ("FCode.REQ") then "FCode.REQ()";
    case("Types.INT") then "Types.INT()";
    case("Types.REAL") then "Types.REAL()";
    case("Types.CHAR") then "Types.CHAR()";
    case("NILbnd") then "NILbnd()";
    case("TCode.IEQ") then "TCode.IEQ()";
    case("TCode.REQ") then "TCode.REQ()";
    case("TCode.LOAD") then "TCode.LOAD()";
    case("Types.PTRNIL") then "Types.PTRNIL()";
    case("TCode.SKIP") then "TCode.SKIP()";
    case("TCode.CHAR") then "TCode.CHAR()";
    case("TCode.INT") then "TCode.INT()";
    case("TCode.REAL") then "TCode.REAL()";
    case("TCode.CtoI") then "TCode.CtoI()";
    case("TCode.ItoR") then "TCode.ItoR()";
    case("TCode.RtoI") then "TCode.RtoI()";
    case("TCode.ItoC") then "TCode.ItoC()";
    case("TCode.PtoI") then "TCode.PtoI()";
    case("INT") then "INT()";
    case("REAL") then "REAL()";
    case ("TCode.ILT") then "TCode.ILT()";
    case ("TCode.ILE") then "TCode.ILE()";
    case ("TCode.RLT") then "TCode.RLT()";
    case ("TCode.RLE") then "TCode.RLE()";
    case ("TCode.ISUB") then "TCode.ISUB()";
    case ("TCode.IMUL") then "TCode.IMUL()";
    case ("TCode.IDIV") then "TCode.IDIV()";
    case ("TCode.IMOD") then "TCode.IMOD()";
    case ("TCode.IAND") then "TCode.IAND()";
    case ("TCode.IOR") then "TCode.IOR()";
    case ("TCode.IEQ") then "TCode.IEQ()";
    case ("TCode.IADD") then "TCode.IADD()";

    case ("TCode.RADD") then "TCode.RADD()";
    case ("TCode.RSUB") then "TCode.RSUB()";
    case ("TCode.RMUL") then "TCode.RMUL()";
    case ("TCode.RDIV") then "TCode.RDIV()";
    case ("TCode.REQ") then "TCode.REQ()";
    case("Mcode.MADD") then "Mcode.MADD()";
    case("Mcode.MSUB") then "Mcode.MSUB()";
    case("Mcode.MMULT") then "Mcode.MMULT()";
    case("Mcode.MDIV") then "Mcode.MDIV()";
    case("Mcode.MJNP") then "Mcode.MJNP()";
    case("Mcode.MJP") then "Mcode.MJP()";
    case("Mcode.MJPZ") then "Mcode.MJPZ()";
    case("Mcode.MJNZ") then "Mcode.MJNZ()";
    case("Mcode.MJN") then "Mcode.MJN()";
    case("Mcode.MJZ") then "Mcode.MJZ()";
    case("Mcode.MHALT") then "Mcode.MHALT()";
    case("EQ") then "EQ()";
    case("LT") then "LT()";
    case("GT") then "GT()";
    case("NONE") then "NONE()";
    case("EMPTY") then "EMPTY()";
    case(id) then id;
  end matchcontinue;
end eliminaterecord;


public function transform_pattern_list
  "function to translate from RML PAttern list to MEtaModelica Pattern matching list"
  input list<Absynrml.RMLPattern> inpattern;
  output list<Absyn.Pattern> outpattern;
  output list<Ident> outstring;
algorithm
  (outpattern,outstring):= matchcontinue(inpattern)
    local
      list<Ident> ifirst,irest,ids;
      list<Absynrml.RMLPattern> rest;
      Absynrml.RMLPattern first;
      Absyn.Pattern mfirst;
      list<Absyn.Pattern> mrest;
    case({})then({},{});
    case(first::rest)
      equation
        (mfirst,ifirst)=transform_pattern(first);
        (mrest,irest)=transform_pattern_list(rest);
        ids=listAppend(ifirst,irest);
      then
        (mfirst::mrest,ids);
  end matchcontinue;

end transform_pattern_list;

public function transform_rulepattern
  "Function to transform patterns appearing in rules of rml relations"
  input Absynrml.RMLPattern inrmlpattern;
  output Absyn.Pattern outpattern;
  output list<Ident> outstring;
algorithm
  (outpattern,outstring):= matchcontinue(inrmlpattern)
    local
      Absynrml.RMLPattern pat;
      Absyn.Pattern mpat;
      list<Ident> ids;
      String pdb;
    case(Absynrml.RMLPAT_STRUCT(NONE(),{}))
    then
      (Absyn.MSTRUCTpat(NONE(),{}),{});

    case(pat)
      equation
        (mpat,ids)=transform_pattern(pat);
      then
        (mpat,ids);
  end matchcontinue;
end transform_rulepattern;

public function transform_pattern
  "function to translate from RML PAttern to MEtaModelica Pattern matching "

  input Absynrml.RMLPattern inrmlpattern;
  output Absyn.Pattern outmpattern;
  output list<Ident> outstring;
algorithm
  (outmpattern,outstring):= matchcontinue(inrmlpattern)
    local
      Absynrml.RMLIdent id;
      String mid,mid1;
      list<Ident> ids,ids1,ids2;
      Absyn.Exp mexp;
      Absynrml.RMLPattern pat,first,rest,wild;
      Absynrml.RMLLiteral lit;
      Absyn.Path path;
      list<Absyn.Pattern> mpat_list;
      list<Absynrml.RMLPattern> list1,patlist;
      Absyn.Pattern mpat,mfirst,mrest;

      /*record RMLPAT_AS */
    case(Absynrml.RMLPAT_AS(id,pat))
      equation
        mid=get_rml_id(id,true);
        (mpat,ids1)=transform_pattern(pat);
        ids=listAppend({mid},ids1);
      then
        (Absyn.MBINDpat(mid,mpat),ids);

        /*record RMLPAT_CONS*/
    case(Absynrml.RMLPAT_CONS(first,rest))
      equation
        (mfirst,ids1)=transform_pattern(first);
        (mrest,ids2)=transform_pattern(rest);
        ids=listAppend(ids1,ids2);
      then
        (Absyn.MSTRUCTpat(SOME(Absyn.IDENT("cons")),{mfirst,mrest}),ids);

        /*record RMLPAT_LIST*/
    case(Absynrml.RMLPAT_LIST(list1))
      equation
        (mpat_list,ids)=transform_pattern_list(list1);
      then
        (Absyn.MSTRUCTpat(SOME(Absyn.IDENT("list")),mpat_list),ids);

        /*record RMLPAT_STRUCT*/
    case(Absynrml.RMLPAT_STRUCT(NONE(),{}))
    then
      (Absyn.MSTRUCTpat(NONE(),{}),{});

    case(Absynrml.RMLPAT_STRUCT(NONE(),list1))
      equation
        (mpat_list,ids)=transform_pattern_list(list1);
      then
        (Absyn.MSTRUCTpat(NONE(),mpat_list),ids);

        /*record RMLPAT_NIL*/
    case(Absynrml.RMLPAT_NIL())
    then
      (Absyn.MSTRUCTpat(NONE(),{}),{});

        /*record RMLPAT_STRUCT1*/
    case(Absynrml.RMLPAT_STRUCT(SOME(id),patlist))
      equation
        path=transform_id(id);
        (mpat_list,ids)=transform_pattern_list(patlist);
      then
        (Absyn.MSTRUCTpat(SOME(path),mpat_list),ids);

        /*record RMLPAT_IDENT*/
    case(Absynrml.RMLPAT_IDENT(id))
      equation
        mid=get_rml_id2(id);
      then
        (Absyn.MPAT(mid),{mid});

        /*record RMLPAT_IDENT1*/
    case(Absynrml.RMLPAT_IDENT(id))
      equation
        mid=get_rml_id2(id);

      then
        (Absyn.MIDENTpat(mid,Absyn.MSTRUCTpat(NONE(),{})),{});

    case(Absynrml.RMLPAT_IDENT(id))
      equation
        "nil"=get_rml_id2(id);
      then
        (Absyn.MSTRUCTpat(SOME(Absyn.IDENT("list")),{}),{});

    case(Absynrml.RMLPAT_IDENT(id))
      equation
        mid=get_rml_id2(id);
      then
        (Absyn.MIDENTpat(mid,Absyn.MSTRUCTpat(NONE(),{})),{});

        /*record RMLPAT_WILDCARD*/
    case(Absynrml.RMLPAT_WILDCARD())
    then
      (Absyn.MWILDpat(),{});

        /*record RMLPAT_LITERAL*/
    case(Absynrml.RMLPAT_LITERAL(lit))
      equation
        mexp=transform_literal(lit);
      then
        (Absyn.MLITpat(mexp),{});
  end matchcontinue;
end transform_pattern;

public function transform_goals
  "function to translate Goals statements in rml relations"
  input Absynrml.RMLGoal inrmlgoal;
  input Absynrml.RMLResult inrmlresult;
  output list<Absyn.EquationItem> outeqitem;
  output list<Ident> outident;
  output Option<Absyn.Exp> outresult;
  output list<String> outstring;
  output list<Absyn.ElementItem> outelement;
algorithm
  (outeqitem,outident,outresult,outstring,outelement):= matchcontinue(inrmlgoal,inrmlresult)
    local
      Absynrml.RMLGoal goal,leftgoal,rightgoal;
      Absynrml.RMLResult res;
      Absyn.EquationItem eqitem_left,eqitem;
      Absyn.Equation eqleft,equ,equation1;
      Option<Absyn.Comment> mcom;
      Option<Absyn.Exp> specres;
      Absyn.Exp resexp:=Absyn.STRING("");
      list<Absyn.EquationItem> restei;
      list<Ident> ids,ids1,ids2;
      list<Absyn.ElementItem> elistgoal,elistgoalrest,elistgoal1;
      Ident mid4,mid2;
      String mid="";
      Absynrml.RMLIdent id;
      list<String> com1,com,com3;
      list<String> com2:= {};
      String pdb;
      Absyn.Info info:= Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));

    case(Absynrml.RMLGOAL_AND(leftgoal,rightgoal),res)
      equation
        (eqleft,ids1,com,elistgoal,info)=transform_goal(leftgoal);
        mcom=transform_comment(com,false);
        eqitem_left=create_standard_equationitem(eqleft,mcom,info);
        (restei,ids2,specres,com1,elistgoalrest)=transform_goals(rightgoal,res);
        ids=listAppend(ids1,ids2);
        elistgoal1=listAppend(elistgoal,elistgoalrest);
      then
        (eqitem_left::restei,ids,specres,com1,elistgoal1);

    case(goal,Absynrml.RETURN(Absynrml.RML_REFERENCE(id)::{},info))
      equation

        (equ,ids,com1,elistgoal,info)=transform_goal(goal);
        equ=Absyn.EQ_EQUALS(Absyn.CREF(Absyn.CREF_IDENT(mid,{})),resexp);
        mid2=get_rml_id(id,true);
        0=System.strcmp(mid,mid2);
        com=listAppend(com1,com2);
      then
        ({},{},SOME(resexp),com,elistgoal);

    case(goal,res)
      equation

        (equation1,ids,com,elistgoal,info)=transform_goal(goal);
        mcom=transform_comment(com,false);
        eqitem=create_standard_equationitem(equation1,mcom,info);
      then
        ({eqitem},ids,NONE(),{},elistgoal);

  end matchcontinue;
end transform_goals;

public function transform_goal
  "function to translate Goals statements in rml relations"
  input Absynrml.RMLGoal ingoal;
  output Absyn.Equation outequation;
  output list<Ident> outident;
  output list<String> outstring;
  output list<Absyn.ElementItem> outelement;
  output Absyn.Info outinfo;
algorithm
  (outequation,outident,outstring,outelement,outinfo):= matchcontinue(ingoal)
    local
      /*fix Absyn.Equation*/
      Absynrml.RMLGoal goal;
      Absyn.Path path;
      Absyn.Equation equation1;
      Absyn.EquationItem eqitem;
      Absynrml.RMLPattern pat;
      list<Absynrml.RMLPattern> patlist,mpat_list;
      Absyn.Pattern mpat;
      Absyn.FunctionArgs fargs;
      Absyn.Exp mexp,rmexp;
      Absynrml.RMLExp exp,rightexp;
      list<Absyn.ElementItem> elist,elistgoal;
      list<Absynrml.RMLExp> args;
      list<Absyn.Exp> margs;
      Absynrml.RMLIdent id,id1;
      String mid;
      list<Ident> ids,ids1,ids2,idgoals,idgoals1,builtintypes,builtinids,builtinids1,checkedids;
      String pdb,pdb1;
      list<String> com={};
      Absyn.Info info:= Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));
      // list<String> com:= com1;

      /*record RMLGOAL_NOT*/
    case(Absynrml.RMLGOAL_NOT(goal,info))
      equation
        (equation1,ids,com,elist)=transform_goal(goal);
      then
        (Absyn.EQ_FAILURE({equation1}),ids,com,elist,info);

        /*record RMLGOAL_LET*/
    case(Absynrml.RMLGOAL_LET(pat,exp,info))
      equation
        (mpat,ids)=transform_pattern(pat);
        (mexp,ids1)=transform_expression(exp);
        ids2=listAppend(ids,ids1);
      then
        (Absyn.EQ_LET(mpat,mexp),ids2,com,{},info);

        /*record RMLGOal_equal*/
    case(Absynrml.RMLGOAL_EQUAL(id,rightexp,info))
      equation
        mid=get_rml_id(id,true);
        (rmexp,ids)=transform_expression(rightexp);
        ids1=listAppend({mid},ids);
      then
        (Absyn.EQ_STRUCTEQUAL(mid,rmexp),ids1,com,{},info);

        /*record RMLGOAL_RELATION*/
    case(Absynrml.RMLGOAL_RELATION(id,args,NONE(),info))
      equation
        id=transform_id_java(id);
        mid=get_rml_id2(id);
        (margs,idgoals)=transform_expression_list(args);
        fargs=create_functionargs(margs,{});

      then
        (Absyn.EQ_NORETCALL(Absyn.CREF_IDENT(mid,{}),fargs),idgoals,com,{},info);

    case(Absynrml.RMLGOAL_RELATION(id,args,SOME(Absynrml.RMLPAT_STRUCT(NONE(),{})),info))
      equation

        id=transform_id_java(id);
        mid=get_rml_id2(id);
        margs=transform_expression_list(args);
        fargs=create_functionargs(margs,{});
      then
        (Absyn.EQ_NORETCALL(Absyn.CREF_IDENT(mid,{}),fargs),{},com,{},info);


    case(Absynrml.RMLGOAL_RELATION(id,args,SOME(pat),info))
      equation
        pdb=get_rml_id(id,true);
        path=transform_id(id);
        (margs,idgoals)=transform_expression_list(args);
        fargs=create_functionargs(margs,{});
        (mpat,ids)=transform_pattern(pat);
        ids1=eliminatebooleanvalues(ids);
        builtinids=listAppend(idgoals,ids1);
        builtintypes=getbuiltintypes(pdb);
        elist=create_local_type(builtintypes,builtinids);
      then
        (Absyn.EQ_CALL(path,fargs,mpat),builtinids,com,elist,info);

    case(Absynrml.RMLGOAL_RELATION(id,args,SOME(pat),info))
      equation

        (mpat,ids)=transform_pattern(pat);
        equation1=transform_special_relation(id,args,mpat);
      then
        (equation1,ids,com,{},info);

  end matchcontinue;
end transform_goal;


public function transform_optional_pattern
  input Absynrml.RMLIdent inident;
  input list<Absynrml.RMLPattern> inrmlpattern;
  output Absyn.Pattern outpattern;
  output Ident outident;
  output list<Ident> outidentlist;
algorithm
  (outpattern,outident,outidentlist):= matchcontinue(inident,inrmlpattern)
    local
      Ident pdb;
      Absyn.Path path;
      Absynrml.RMLIdent id1;
      list<Absynrml.RMLPattern> patlist;
      list<Absyn.Pattern> mpat_list;
      list<Ident> ids1;
    case(id1,patlist)
      equation
        path=transform_id(id1);
        pdb=get_rml_id(id1,true);
        (mpat_list,ids1)=transform_pattern_list(patlist);
      then
        (Absyn.MSTRUCTpat(SOME(path),mpat_list),pdb,ids1);
  end matchcontinue;
end transform_optional_pattern;

public function eliminatebooleanvalues
  input list<Ident> inidentlst;
  output list<Ident> outidentlst;
algorithm
  outidentlst:= matchcontinue(inidentlst)
    local
      list<Ident> id;
    case({"true"}) then {};
    case({"false"}) then {};
    case(id) then id;
  end matchcontinue;
end eliminatebooleanvalues;


public function getbuiltintypes
  input String inident;
  output list<String> outident;
algorithm
  outident:=matchcontinue(inident)
    local
      Ident id;
      list<String> file;
    case("int_add") then {"Integer"};
    case("int_sub") then {"Integer"};
    case("int_mul") then {"Integer"};
    case("int_div") then {"Integer"};
    case("int_neg") then {"Integer"};
    case("int_le") then {"Integer"};
    case("int_lt") then {"Integer"};
    case("int_eq") then {"Integer"};
    case("int_ne") then {"Integer"};
    case("int_ge") then {"Integer"};
    case("int_gt") then {"Integer"};
    case(id)
      equation
        file=Dict.readFile(id);
      then
        file;
  end matchcontinue;
end getbuiltintypes;


public function transform_special_relation
  input Absynrml.RMLIdent inident;
  input list<Absynrml.RMLExp> inexp;
  input Absyn.Pattern inpattern;
  output Absyn.Equation outequation;
algorithm
  outequation:= matchcontinue(inident,inexp,inpattern)
    local
      Absynrml.RMLIdent id;
      String mid,rid;
      list<Absynrml.RMLExp> args;
      Absyn.Equation eq;
      Absyn.Exp cref,mexp;
      Absynrml.RMLExp exp,left,right;
      Absyn.Exp mleft,mright,b;
      Absyn.Pattern pat;
      Absyn.Operator binop,relop,unop;
    case(id,left::right::{},Absyn.MIDENTpat(mid,_))
      equation
        rid=get_rml_id(id,true);
        binop=get_binop(rid);
        mleft=transform_expression(left);
        mright=transform_expression(right);
        cref=create_exp_cref(mid,{});
      then
        Absyn.EQ_EQUALS(cref,Absyn.BINARY(mleft,binop,mright));

    case(id,left::right::{},Absyn.MIDENTpat(mid,_))
      equation
        rid=get_rml_id(id,true);
        relop=get_relop(rid);
        mleft=transform_expression(left);
        mright=transform_expression(right);
        b=get_bool(mid);
      then
        Absyn.EQ_EQUALS(Absyn.LBINARY(mleft,relop,mright),b);

    case(id,left::right::{},Absyn.MIDENTpat(mid,_))
      equation
        rid=get_rml_id(id,true);
        relop=get_relop(rid);
        mleft=transform_expression(left);
        mright=transform_expression(right);
        cref=create_exp_cref(mid,{});
      then
        Absyn.EQ_EQUALS(cref,Absyn.LBINARY(mleft,relop,mright));

    case(id,exp::{},Absyn.MIDENTpat(mid,_))
      equation
        rid=get_rml_id(id,true);
        unop=get_unop(rid);
        mexp=transform_expression(exp);
        cref=create_exp_cref(mid,{});
      then
        Absyn.EQ_EQUALS(cref,Absyn.UNARY(unop,mexp));

    case(id,args, pat as Absyn.MIDENTpat(mid,_))
      equation
        rid=get_rml_id(id,true);
        eq=transform_char_to_stringChar(rid,args,pat);
      then
        eq;
  end matchcontinue;
end transform_special_relation;


/* in metamodelica there is no char type change to string char*/

public function transform_char_to_stringChar
  input String inident;
  input list<Absynrml.RMLExp> inexp;
  input Absyn.Pattern inmpattern;
  output Absyn.Equation outequation;
algorithm
  outequation:= matchcontinue(inident,inexp,inmpattern)
    local
      Absynrml.RMLIdent str_id,lst_id,int_id;
      String str_id1,lst_id1,int_id1;
      Absyn.Pattern mpat;
      Absynrml.RMLExp exp,e1,cref;
      Absyn.Exp mexp,me1;
      Absyn.FunctionArgs fargs;
    case("string_setnth",Absynrml.RML_REFERENCE(str_id)::exp::e1::{},mpat)
      equation
        mexp=transform_expression(exp);
        me1=transform_expression(e1);
        str_id1=get_rml_id(str_id,true);
        fargs=create_functionargs({Absyn.CREF(Absyn.CREF_IDENT(str_id1,{})),Absyn.BINARY(mexp,Absyn.ADD(),Absyn.INTEGER(1)),me1},{});
      then
        Absyn.EQ_CALL(Absyn.IDENT("string_update_string_char"),fargs,mpat);

    case("string_setnth",Absynrml.RML_REFERENCE(str_id)::exp::e1::{},mpat)
      equation
        mexp=transform_expression(exp);
        me1=transform_expression(e1);
        str_id1=get_rml_id(str_id,true);
        fargs=create_functionargs({Absyn.CREF(Absyn.CREF_IDENT(str_id1,{})),me1,mexp},{});
      then
        Absyn.EQ_CALL(Absyn.IDENT("string_update_string_char"),fargs,mpat);

        /*listString(var)*/

    case("listString",Absynrml.RML_REFERENCE(lst_id)::{},mpat)
      equation
        lst_id1=get_rml_id(lst_id,true);
        fargs=create_functionargs({Absyn.CREF(Absyn.CREF_IDENT(lst_id1,{}))},{});
      then
        Absyn.EQ_CALL(Absyn.IDENT("stringcharListString"),fargs,mpat);

        /*listString(list)*/

    case("listString",exp::{},mpat)
      equation
        mexp=transform_expression(exp);
        fargs=create_functionargs({mexp},{});
      then
        Absyn.EQ_CALL(Absyn.IDENT("stringcharListString"),fargs,mpat);

        /*list_string(var)*/
    case("listString",Absynrml.RML_REFERENCE(lst_id)::{},mpat)
      equation
        lst_id1=get_rml_id(lst_id,true);
        fargs=create_functionargs({Absyn.CREF(Absyn.CREF_IDENT(lst_id1,{}))},{});
      then
        Absyn.EQ_CALL(Absyn.IDENT("string_char_list_string"),fargs,mpat);

        /*list_string(list)*/

    case("list_string",exp::{},mpat)
      equation
        mexp=transform_expression(exp);
        fargs=create_functionargs({mexp},{});
      then
        Absyn.EQ_CALL(Absyn.IDENT("string_char_list_string"),fargs,mpat);

    case("stringList",Absynrml.RML_REFERENCE(str_id)::{},mpat)
      equation
        str_id1=get_rml_id(str_id,true);
        fargs=create_functionargs({Absyn.CREF(Absyn.CREF_IDENT(str_id1,{}))},{});
      then
        Absyn.EQ_CALL(Absyn.IDENT("stringListStringChar"),fargs,mpat);

    case("string_list",Absynrml.RML_REFERENCE(str_id)::{},mpat)
      equation
        str_id1=get_rml_id(str_id,true);
        fargs=create_functionargs({Absyn.CREF(Absyn.CREF_IDENT(str_id1,{}))},{});
      then
        Absyn.EQ_CALL(Absyn.IDENT("string_list_string_char"),fargs,mpat);

        /*int_char(var)->int_string_char(var)*/

    case("int_char",Absynrml.RML_REFERENCE(int_id)::{},mpat)
      equation
        int_id1=get_rml_id(int_id,true);
        fargs=create_functionargs({Absyn.CREF(Absyn.CREF_IDENT(int_id1,{}))},{});

      then
        Absyn.EQ_CALL(Absyn.IDENT("int_string_char"),fargs,mpat);

        /* int_char(integer) -> int_string_char(integer) */

    case("int_char",exp::{},mpat)
      equation
        mexp=transform_expression(exp);
        fargs=create_functionargs({mexp},{});

      then
        Absyn.EQ_CALL(Absyn.IDENT("int_string_char"),fargs,mpat);

        /* char_int(var) -> string_char_int(var) */
    case("char_int",Absynrml.RML_REFERENCE(int_id)::{},mpat)
      equation
        int_id1=get_rml_id(int_id,true);
        fargs=create_functionargs({Absyn.CREF(Absyn.CREF_IDENT(int_id1,{}))},{});

      then
        Absyn.EQ_CALL(Absyn.IDENT("string_char_int"),fargs,mpat);

        /* int_char(integer) -> int_string_char(integer) */
    case("char_int",exp::{},mpat)
      equation
        mexp=transform_expression(exp);
        fargs=create_functionargs({mexp},{});

      then
        Absyn.EQ_CALL(Absyn.IDENT("string_char_int"),fargs,mpat);

  end matchcontinue;
end transform_char_to_stringChar;

public function transform_result
  " function to translate rml result to MetaModelica expression "
  input Absynrml.RMLResult inresult;
  input Option<Absyn.Exp> inoptexp;
  input Boolean inbool;
  output Absyn.Exp outexp;
  output list<String> outstring;
  output list<Ident> outidentlist;
algorithm
  (outexp,outstring,outidentlist):= matchcontinue(inresult,inoptexp,inbool)
    local
      Absyn.Info info;
      Absynrml.RMLResult res;
      Absynrml.RMLExp last;
      Absyn.Exp exp,specres;
      list<Absynrml.RMLExp> exp_list,list1;
      list<Absyn.Exp> exp_list1;
      list<Ident> ids;
      list<String> comments={};
      Boolean value;
    case(res,SOME(specres),_)
      equation
      then
        (specres,{},{});

    case(Absynrml.FAIL(),_,_)
    then
      (Absyn.MSTRUCTURAL(SOME(Absyn.IDENT("fail")),{}),comments,{});

    case(Absynrml.EMPTY_RESULT(),_,false)
    then
      (Absyn.MSTRUCTURAL(NONE(),{}),comments,{});

    case(Absynrml.EMPTY_RESULT(),_,true)
    then
      (Absyn.BOOL(value=true),comments,{});

    case(Absynrml.RETURN({},info),_,false)
    then
      (Absyn.MSTRUCTURAL(NONE(),{}),comments,{});

    case(Absynrml.RETURN({},info),_,true)
    then
      (Absyn.BOOL(value=true),comments,{});


    case(Absynrml.RETURN((last as Absynrml.RMLTUPLE(exp_list))::{},info),_,_)
      equation
        (exp,ids)=transform_expression(last);
      then
        (Absyn.TUPLE(exp::{}),comments,ids);

    case(Absynrml.RETURN(last::{},info),_,_)
      equation
        (exp,ids)=transform_expression(last);
      then
        (exp,comments,ids);

    case(Absynrml.RETURN(list1,info),_,_)
      equation
        exp_list1=transform_expression_list(list1);
      then
        (Absyn.TUPLE(exp_list1),comments,{});

  end matchcontinue;
end transform_result;

public function transform_rule
  "special functin to translate rml rules to case statements in MetAModelica AST"
  input Absynrml.RMLRule inrmlrule;
  input list<Ident> inident;
  input list<Absynrml.RMLType> inrmltype;
  output Absyn.Case outcase;
  output list<Absyn.ElementItem> outelement;
  output list<Ident> outidentlist;
algorithm
  (outcase,outelement,outidentlist):= matchcontinue(inrmlrule,inident,inrmltype)
    local
      Absynrml.RMLIdent id;
      list<Ident> rml_idents1,rml_idents2,rml_idents,rml_idents3,typeid,ids;
      Absyn.Exp cresult;
      Option<Absyn.Exp> specres;
      list<Absynrml.RMLType> intypes;
      Absynrml.RMLType intype;
      list<Absyn.ElementItem> local_decl;
      list<Absyn.EquationItem> equations,equation_item_list;
      Absyn.Info info;
      Absyn.Pattern mpattern;
      Absynrml.RMLPattern pattern;
      Absynrml.RMLGoal goal;
      Absynrml.RMLResult result;
      Boolean b_dummy;
      Absyn.ElementSpec variables;
      list<Absyn.ElementSpec> testing;
      list<Absyn.ElementItem> elist,elistgoal,elist1,outlist;
      Option<Absyn.Comment> mcomment,mendcomment;
      list<String> spec_com,rcom,comment1,comment2;
      list<String> comment:= comment1;
      list<String> cend:= {};
      list<Ident> typeid;
      Ident first1,first2,first3;

    case(Absynrml.RMLRULE(id,pattern,SOME(goal),result,info),typeid,intypes)
      equation
        (mpattern,rml_idents2)=transform_rulepattern(pattern);
        (equation_item_list,rml_idents1,specres,spec_com,elistgoal)=transform_goals(goal,result);
        (cresult,rcom,ids)=transform_result(result,specres,false);
        rml_idents=listAppend(rml_idents1,rml_idents2);
        rml_idents3=removerecordconstructs(rml_idents);
        //local_decl=create_local_decl(decl_db,alttypes_db);
      then
        (Absyn.RMLCASE({mpattern},{},Absyn.EQUATIONS(equation_item_list),cresult,NONE(),NONE()),{},rml_idents3);

    case(Absynrml.RMLRULE(id,pattern,NONE(),result,info),typeid,intypes)
      equation
        (mpattern,rml_idents)=transform_rulepattern(pattern);
        rml_idents1=removerecordconstructs(rml_idents);
        (cresult,rcom)=transform_result(result,NONE(),false);
        //local_decl=create_local_decl(decl_db,alttypes_db);
      then
        (Absyn.RMLCASE({mpattern},{},Absyn.EQUATIONS({}),cresult,NONE(),NONE()),{},rml_idents1);
  end matchcontinue;
end transform_rule;


function removerecordconstructs
  input list<Ident> inidentlist;
  output list<Ident> outidentlist;
algorithm
  outidentlist:= matchcontinue(inidentlist)
    local
      list<Ident> id,rest,first1,rest1,removedids;
      Ident first;
    case({}) then {};
    case(first::rest)
      equation
        first1=checkrecord(first);
        rest1=removerecordconstructs(rest);
        removedids=listAppend(first1,rest1);
      then
        removedids;
  end matchcontinue;
end removerecordconstructs;

/* TO do ADD the empty record constructs of other exercises when encountered */

function checkrecord
  input Ident inident;
  output list<Ident> outidentlist;
algorithm
  outidentlist:= matchcontinue(inident)
    local
      Ident id;

      /*PAMDECL emptyrecord */
    case("Env.INTTYPE") then {};
    case("Env.REALTYPE") then {};
    case("Eval.init_env") then {};
    case("Env.BOOLTYPE") then {};
    case("Absyn.ADD") then {};
    case("Absyn.SUB") then {};
    case("Absyn.MUL") then {};
    case("Absyn.DIV") then {};
    case("Absyn.NEG") then {};

    case("Absyn.LT") then {};
    case("Absyn.LE") then {};
    case("Absyn.GT") then {};
    case("Absyn.GE") then {};
    case("Absyn.NE") then {};
    case("Absyn.EQ") then {};

      /*PETROL emptyrecord */

    case("FCode.CHAR") then {};
    case("FCode.INT") then {};
    case("FCode.REAL") then {};

    case("FCode.IADD") then {};
    case("FCode.ISUB") then {};
    case("FCode.IMUL") then {};
    case("FCode.IDIV") then {};
    case("FCode.IMOD") then {};
    case("FCode.IAND") then {};
    case("FCode.IOR") then {};
    case("FCode.ILT") then {};
    case("FCode.ILE") then {};
    case("FCode.IEQ") then {};
    case("FCode.RADD") then {};
    case("FCode.RSUB") then {};
    case("FCode.RMUL") then {};
    case("FCode.RDIV") then {};
    case("FCode.RMOD") then {};
    case("FCode.RAND") then {};
    case("FCode.ROR") then {};
    case("FCode.RLT") then {};
    case("FCode.RLE") then {};
    case("FCode.REQ") then {};
    case("FCode.SKIP") then {};
    case("FCode.CtoI") then {};
    case("FCode.ItoC") then {};
    case("FCode.RtoI") then {};
    case("FCode.ItoR") then {};
    case("FCode.PtoI") then {};
    case ("TCode.IADD") then {};
    case ("TCode.ISUB") then {};
    case ("TCode.IMUL") then {};
    case ("TCode.IDIV") then {};
    case ("TCode.IMOD") then {};
    case ("TCode.IAND") then {};
    case ("TCode.IOR") then {};
    case ("TCode.ILT") then {};
    case ("TCode.ILE") then {};
    case ("TCode.IEQ") then {};
    case ("TCode.RADD") then {};
    case ("TCode.RSUB") then {};
    case ("TCode.RMUL") then {};
    case ("TCode.RDIV") then {};
    case ("TCode.RLT") then {};
    case ("TCode.RLE") then {};
    case ("TCode.REQ") then {};
    case("TCode.CtoI") then {};
    case("TCode.ItoC") then {};
    case("TCode.RtoI") then {};
    case("TCode.ItoR") then {};
    case("TCode.PtoI") then {};
    case("TCode.SKIP") then {};
    case("Absyn.ADDR") then {};
    case("Absyn.INDIR") then {};
    case("Absyn.NOT") then {};
    case("Absyn.PRETURN") then {};
    case("Absyn.SKIP") then {};
    case("TCode.CHAR") then {};
    case("TCode.INT") then {};
    case("TCode.REAL") then {};
    case("Absyn.RDIV") then {};
    case("Absyn.IDIV") then {};
    case("Absyn.IMOD") then {};
    case("Absyn.IAND") then {};
    case("Absyn.IOR") then {};
    case("Mcode.MHALT") then {};
    case("Mcode.MADD") then {};
    case("Mcode.MSUB") then {};
    case("Mcode.MMULT") then {};
    case("Mcode.MDIV") then {};
    case("Mcode.MJNP") then {};
    case("Mcode.MJP") then {};
    case("Mcode.MJPZ") then {};
    case("Mcode.MJZ") then {};
    case("Mcode.MJNZ") then {};
    case("Mcode.MJN") then {};

    case("decay_formal") then {};
    case("mkvar") then {};
    case("mkvarbnd") then {};
    case("extract_ty") then {};
    case("emit_proc_decl") then {};
    case("emit_proc_decl") then {};
    case("emit_proc_defn") then {};
    case("emit_comma_arg") then {};
    case("env_init") then {};
    case("conv_formal_decl") then {};
    case("trans_var") then {};
    case("PTRNIL") then {};
    case("CHAR") then {};
    case("INT") then {};
    case("REAL") then {};

    case("NILbnd") then {};
    case("EMPTY") then {};
    case("NONE") then {};
    case("ADD") then {};
    case("SUB") then {};
    case("MUL") then {};
    case("DIV") then {};
    case("NEG") then {};

    case("EQ") then {};
    case("LT") then {};
    case("GT") then {};
    case("LE") then {};
    case("GE") then {};
    case("NE") then {};
    case("false") then {};
    case("true") then {};
    case(id) then {id};

  end matchcontinue;
end checkrecord;

public function transform_rule_list
  input list<Absynrml.RMLRule> inrmlrule;
  input list<Ident> inident;
  input list<Absynrml.RMLType> inrmltype;
  output list<Absyn.Case> outcase;
  output list<Absyn.ElementItem> outelement;
  output list<Ident> outidentlist;

algorithm
  (outcase,outelement,outidentlist):= matchcontinue(inrmlrule,inident,inrmltype)
    local
      String pdb;
      Absynrml.RMLRule first;
      list<Absyn.ElementItem> elist1,elist,elist2,elist3;
      list<Absynrml.RMLRule> rest;
      list<Absynrml.RMLType> intypes;
      Absyn.Case firstc;
      list<Absyn.Case> restc;
      list<Ident> typeid,rmlidents1,rmlidents2,rmlidents3;
    case({},_,_)
    then
      ({},{},{});

    case(first::rest,typeid,intypes)
      equation
        (firstc,elist1,rmlidents1)=transform_rule(first,typeid,intypes);
        (restc,elist,rmlidents2)=transform_rule_list(rest,typeid,intypes);
        rmlidents3=listAppend(rmlidents1,rmlidents2);
        elist2=listAppend(elist1,elist);
        elist3=List.union(elist1,elist);
      then
        (firstc::restc,elist3,rmlidents3);
  end matchcontinue;
end transform_rule_list;

public function check_lst_members
  input list<String> instringlst;
  input list<String> instring;
  output Boolean outbool;
algorithm
  outbool:= matchcontinue(instringlst,instring)
    local
      Boolean bvalue1,bvalue2,bresult;
      list<String> rest,lst_chars;
      String start;
    case({},_)then false;

    case(start::rest,lst_chars)
      equation
        bvalue1=listMember(start,lst_chars);
        bvalue2=check_lst_members(rest,lst_chars);
        bresult=boolOr(bvalue1,bvalue2);
      then
        bresult;
  end matchcontinue;
end check_lst_members;

public function literal_keywords
  input String instring;
  output String outstring;
algorithm
  outstring:=matchcontinue(instring)
    local
      String x;
    case("false") then "false_";
    case("true") then "true_";
    case(x) then x;
  end matchcontinue;
end literal_keywords;

public function get_commentname
  input String instring;
  input list<String> instringlst;
  input String instring1;
  input Integer ininteger;
  output String outstring;
algorithm
  outstring:= matchcontinue(instring,instringlst,instring1,ininteger)
    local
      Integer i,slen;
      String id1,id2,id3,id4,other,str,com;
      String id;
      Boolean b;
    case(_,com::_,other,i)
      equation
        str=System.trimWhitespace(com);
        slen=stringLength(str);
        false=intGt(slen,0);
        id2=literal_keywords(other);
      then
        id2;
    case(_,com::_,other,i)
      equation
        str=System.trimWhitespace(com);
        slen=stringLength(str);
        true=intGt(slen,0);
        id3=literal_keywords(other);
      then
        id3;

    case(_,_,other,_)
      equation
        id2=literal_keywords(other);
      then
        id2;

  end matchcontinue;
end get_commentname;

public function transform_tupletype
  input Integer ininteger;
  input list<String> instringlst;
  input list<String> instringlst1;
  input list<String> instringlst2;
  input Absyn.Direction indirection;
  input Boolean inbool;
  input Absyn.Info ininfo;
  output list<Absyn.ElementItem> outelementitem;
  output list<String> outstringlst;
algorithm
  (outelementitem,outstringlst):=matchcontinue(ininteger,instringlst,instringlst1,instringlst2,indirection,inbool,ininfo)
    local
      Integer i,ic;
      Absyn.Direction dir;
      Absyn.ElementItem firstei;
      list<Absyn.ElementItem> restei;
      String cname1,istr,istr1,cname,spec_id;
      list<String> com,restnames,rest_spec_id,rest_names,rcom1,fcom;
      list<String> rcom:={};
      Option<Absyn.Comment> fcom1;
      Boolean b_unique;
      // Absyn.Info info:=Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));
      Absyn.Info info;
      Absyn.ElementSpec components;

    case(i,{},{},_,_,_,_) then ({},{});

    case(i,cname::rest_names,spec_id::rest_spec_id,fcom,dir,b_unique,info)
      equation
        ic=intAdd(i,1);
        istr=intString(ic);
        istr1=getiffalse(istr,b_unique);
        cname1=stringAppend(cname,istr1);
        fcom1=transform_comment(fcom,false);
        components=create_components({cname1},spec_id,dir,fcom1);
        firstei=create_standard_elementitem(components,info);
        (restei,restnames)=transform_tupletype(ic,rest_names,rest_spec_id,rcom,dir,b_unique,info);
      then
        (firstei::restei,cname1::restnames);

        /*  case(i,cname::rest_names,spec_id::rest_spec_id,com,dir,b_unique,info)
         equation

         ic=intAdd(i,1);
         istr=intString(ic);
         istr1=getiffalse(istr,b_unique);
         cname1=stringAppend(cname,istr1);
         components=create_components({cname1},spec_id,dir,NONE());
         firstei=create_standard_elementitem(components,info);
         (restei,restnames)=transform_tupletype(ic,rest_names,rest_spec_id,com,dir,b_unique,info);

         then
         (firstei::restei,cname1::restnames); */
  end matchcontinue;
end transform_tupletype;


public function get_tupletypeids
  input String instring;
  input Integer ininteger;
  input list<Absynrml.RMLType> intype;
  input list<String> instringlst;
  input Boolean inbool;
  output list<String> outstringlst;
  output list<String> outstringlst1;
algorithm
  (outstringlst,outstringlst1):= matchcontinue(instring,ininteger,intype,instringlst,inbool)
    local
      String name,cname1,cname2,cname,spec_id,spec_id1;
      list<String> fcom,nrest,com,restei;
      list<String> rcom:={};
      Boolean b_ei;
      Integer i,ic;
      Absynrml.RMLIdent id;
      String mid,mid1;
      Absynrml.RMLType first_type;
      list<Absynrml.RMLType> rest_types;
    case (name,i,{},_,_) then ({},{});

    case (name,i,Absynrml.RMLTYPE_USERDEFINED(id)::rest_types,fcom,b_ei)
      equation
        mid = get_rml_id2(id);
        spec_id = transform_typeid(mid,false);
        mid1 = get_rml_id(id,false);
        spec_id1 = transform_typeid(mid1,false);
        ic = intAdd(i,1);
        cname = stringAppend(name,spec_id1);
        cname2 = get_commentname("",fcom,cname,0);
        (restei,nrest) = get_tupletypeids(name, ic, rest_types, rcom,b_ei);
      then
        ((spec_id :: restei),(cname2::nrest));
    case (name,i,(first_type :: rest_types),fcom,b_ei)
      equation
        (spec_id,_) = get_specialtype_id(first_type, "", b_ei);
        ic = intAdd(i,1);
        cname = stringAppend(name,spec_id);
        cname2 = get_commentname("", fcom, cname, 0);
        (restei,nrest) = get_tupletypeids(name, ic, rest_types, rcom, b_ei);

      then
        ((spec_id :: restei),(cname2 :: nrest));


    case (name,i,(Absynrml.RMLTYPE_USERDEFINED(id) :: rest_types),com,b_ei)
      equation
        mid = get_rml_id2(id);
        spec_id = transform_typeid(mid,false);
        mid1 = get_rml_id(id,false);
        spec_id1 = transform_typeid(mid1,false);
        ic =intAdd(i,1);
        cname = stringAppend(name,spec_id1);
        (restei,nrest) = get_tupletypeids(name, ic, rest_types, com, b_ei);
      then
        ((spec_id :: restei),(cname :: nrest));


    case (name,i,(first_type :: rest_types),com,b_ei)
      equation
        (spec_id,_) = get_specialtype_id(first_type, "", b_ei);
        ic = intAdd(i,1);
        cname = stringAppend(name,spec_id);
        (restei,nrest) = get_tupletypeids(name, ic, rest_types, com, b_ei);
      then
        ((spec_id :: restei),(cname :: nrest));


  end matchcontinue;
end get_tupletypeids;

public function transform_iotype
  "special function to Translate input and ouput parameters in rml to MetaModelica"
  input Integer ininteger;
  input list<String> instringlst;
  input list<String> instringlst1;
  input Absyn.Direction indirection;
  input Boolean inbool;
  output list<Absyn.ElementItem> outelement;
  output list<String> outstringlst;

algorithm
  (outelement,outstringlst):= matchcontinue(ininteger,instringlst,instringlst1,indirection,inbool)
    local
      Integer i,ic;
      String cname,cname1,cname2,spec_id,spec_id1,istr,istr1;
      list<String> restnames,rest_names,rest_spec_id;
      Absyn.ElementItem firstei;
      list<Absyn.ElementItem> restei;
      Absyn.Direction dir;
      Boolean b_unique;
      Absyn.Info info:=Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));

      Absyn.ElementSpec components;
    case (i,{},{},_,_)
      equation
      then ({},{});

    case (i,(cname :: rest_names),(spec_id :: rest_spec_id),dir,b_unique)
      equation

        ic = intAdd(i,1);

        istr = intString(ic);

        istr1 = getiffalse(istr,b_unique);

        cname1 = stringAppend(cname,istr1);

        components = create_components({cname1}, spec_id, dir, NONE());

        firstei = create_standard_elementitem(components,info);

        (restei,restnames) = transform_iotype(ic, rest_names, rest_spec_id, dir, b_unique);

      then
        ((firstei::restei),(cname1::restnames));
  end matchcontinue;

end transform_iotype;


public function get_iotypeids
  "special function to extract the input and ouput parameters from rml patterns"
  input String instring;
  input Integer ininteger;
  input list<Absynrml.RMLType> inrmltype;
  input Boolean inbool;
  output list<String> outstringlst;
  output list<String> outstringlst1;
algorithm
  (outstringlst,outstringlst1):= matchcontinue(instring,ininteger,inrmltype,inbool)
    local
      Integer i,ic;
      Absynrml.RMLIdent id;
      String mid,mid1;
      String name,cname,cname1,cname2,spec_id,spec_id1;
      list<String> nrest,restei;
      Absynrml.RMLType first_type;
      list<Absynrml.RMLType> rest_types;
      Boolean b_ei;

      // case ("out",0,{},_,_) then ({"Boolean"},{"dummy"});

    case ("out",0,{},_) then ({},{});
    case (name,i,{},_) then ({},{});

    case (name,i,(Absynrml.RMLTYPE_USERDEFINED(id) :: rest_types),b_ei)
      equation
        mid = get_rml_id2(id);
        spec_id = transform_typeid(mid,false);
        mid1 = get_rml_id(id, false);
        spec_id1 = transform_typeid(mid1,false);
        ic =intAdd(i,1);
        cname = stringAppend(name,spec_id1);
        (restei,nrest) = get_iotypeids(name, ic, rest_types,b_ei);
      then
        ((spec_id :: restei),(cname :: nrest));

    case (name,i,(first_type :: rest_types),b_ei)
      equation
        (spec_id,_) = get_specialtype_id(first_type, "",b_ei);
        ic = intAdd(i,1);
        cname = stringAppend(name,spec_id);
        (restei,nrest) = get_iotypeids(name, ic,rest_types,b_ei);
      then

        ((spec_id :: restei),(cname :: nrest));
  end matchcontinue;
end get_iotypeids;

public function transform_type
  //checked and fixed
  input list<Ident> inident;
  input Absynrml.RMLType inrmltype;
  input Option<Absyn.Comment> incomment;
  input Absyn.Direction indirection;
  input Boolean inbool;
  output Absyn.ElementItem outelement;
algorithm
  outelement:= matchcontinue(inident,inrmltype,incomment,indirection,inbool)
    local
      list<Ident> var_lst;
      Boolean b_ext;
      Absyn.Direction dir;
      Absyn.ElementItem elementitem;
      Absynrml.RMLType the_type;
      Absynrml.RMLIdent id;
      String mid;
      list<AlternativeTypesNames> a,alttypes_db;
      Option<Absyn.Comment> com;
      String cid,spec_id;
      Absyn.ElementSpec components;

    case (var_lst,Absynrml.RMLTYPE_USERDEFINED(id),com,dir,b_ext)
      equation
        mid = get_rml_id2(id);
        cid = transform_typeid(mid,false);
        (spec_id,_) = get_alternative_typeid(cid,b_ext);
        components = create_components(var_lst, spec_id, dir, com);
        elementitem = create_standard_elementitem(components);
      then
        elementitem;
    case (var_lst,the_type,com,dir,b_ext)
      equation
        (spec_id,_) = get_specialtype_id(the_type,"",b_ext);
        components = create_components(var_lst, spec_id, dir, com);
        elementitem = create_standard_elementitem(components);
      then
        elementitem;
    case (var_lst,_,com,dir,b_ext)
      equation
        components = create_components(var_lst,"dummy", dir,com);
        elementitem = create_standard_elementitem(components);
      then
        elementitem;
  end matchcontinue;

end transform_type;

public function transform_dtmember
"Special function to translate datatype statements in rml to uniontype in MetaModelica"
  input Absynrml.DTMember indtmember;
  output Absyn.ElementItem outelement;
  output list<Absyn.ElementItem> outelementlist;

algorithm
  (outelement,outelementlist):= matchcontinue(indtmember)
    local
      Absynrml.RMLIdent id;
      String mid;
      Absyn.ElementSpec classdef;
      list<Absynrml.RMLType> typelist;
      list<Absyn.ElementItem> special_types;
      Absyn.ElementItem elementitem;
      list<Absyn.ElementItem> components;
      Boolean bi,b1,b2;
      list<String> comments={};
      list<String> specids,typelist1;
      // Absyn.Info info:=Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));
      Absyn.Info info;

    case (Absynrml.DTCONS(id,{},info))
      equation

        mid = get_rml_id(id,true);
        classdef = create_classdef(mid,Absyn.R_RECORD(),{Absyn.PUBLIC({})},comments,false,info);
        elementitem = create_standard_elementitem(classdef,info);
      then
        (elementitem,{});


    case (Absynrml.DTCONS(id,typelist,info))
      equation
        (special_types,_) = get_specialtypes_lst(typelist, false, 0);
        (specids,typelist1) = get_tupletypeids("", 0, typelist, comments, false);
        b1 = is_unique_list(specids) ;
        b2 = is_unique_list(typelist1) "check first to see if unique comments" ;
        bi = boolOr(b1,b2);
        (components,_) = transform_tupletype(0, typelist1, specids, comments, Absyn.BIDIR(), bi,info);
        mid = get_rml_id(id,true) "transform_type_tuple(\"x\",0,typelist,Absyn.BIDIR,comments,alttypes_db') => components &  " ;
        classdef = create_classdef(mid, Absyn.R_RECORD(), {Absyn.PUBLIC(components)}, {}, false,info);
        elementitem = create_standard_elementitem(classdef,info);
      then
        (elementitem,special_types);
  end matchcontinue;

end transform_dtmember;

public function transform_dtmember_list
  //checked and fixed
  "Special function to translate datatype statements in rml to uniontype in MetaModelica"

  input list<Absynrml.DTMember> indtmemberlst;
  output list<Absyn.ElementItem> outelementitemlst;
  output list<Absyn.ElementItem>  outelementitemlst1;
algorithm
  (outelementitemlst,outelementitemlst1):= matchcontinue(indtmemberlst)
    local
      Absyn.Info info;
      Absynrml.DTMember first,last;
      Absyn.ElementItem firstrecord,lastrecord;
      list<Absynrml.DTMember> rest;
      list<Absyn.ElementItem> restrecord;
      list<Absyn.ElementItem> lspec,type_list,fspec,rspec;

    case (last :: {})
      equation
        (lastrecord,lspec) = transform_dtmember(last);
      then
        ((lastrecord :: {}),lspec);


    case ((first :: rest))
      equation
        (firstrecord,fspec) = transform_dtmember(first);
        (restrecord,rspec) = transform_dtmember_list(rest);
        type_list = listAppend(fspec,rspec);


      then
        ((firstrecord :: restrecord),type_list);

  end matchcontinue;
end transform_dtmember_list;

/*A special relation to see if we need dummy or not */

public function need_dummy
  //checked and fixed
  input Boolean inbool;
  input list<Absynrml.RMLType> inrmltype;
  output Integer outinteger;
algorithm
  outinteger:= matchcontinue(inbool,inrmltype)
    case(false,{})then -1;
    case(_,_)then 0;
  end matchcontinue;
end need_dummy;

public function transform_decl_signature
  //checked and fixed
  input Absynrml.RMLType inrmltype;
  input Boolean inbool;
  output list<Absyn.ElementItem> outelementtype;
  output list<Absyn.ElementItem> outelementtype1;
  output list<String> outstringlst;
  output list<String> outstringlst1;
  output list<String> outstringlst2;
  output list<Absynrml.RMLType> outtype;
algorithm
  (outelementtype,outelementtype1,outstringlst,outstringlst1,outstringlst2,outtype):= matchcontinue(inrmltype,inbool)
    local
      list<Absynrml.RMLType> intypes,outtypes;
      Boolean b_dummy;
      list<String> inspecids,outspecids,inlist,outlist,inlist1,outlist1;
      list<Absyn.ElementItem> mintypes,mouttypes,inout_types,inspecial,outspecial,inout_special;
      Boolean bi,b_dummy,bo;
      Integer ic;

    case (Absynrml.RMLTYPE_SIGNATURE(Absynrml.CALLSIGN(intypes,outtypes)),b_dummy)
      equation

        (inspecial,_) = get_specialtypes_lst(intypes,false,0);
        (outspecial,_) = get_specialtypes_lst(outtypes,false,0);
        (inspecids,inlist) = get_iotypeids("in",0,intypes,false);
        bi = is_unique_list(inlist);
        (mintypes,inlist1) = transform_iotype(0,inlist,inspecids,Absyn.INPUT(),bi);
        ic = need_dummy(b_dummy,outtypes);
        (outspecids,outlist) = get_iotypeids("out",ic,outtypes,false);
        bo = is_unique_list(outlist);
        (mouttypes,outlist1) = transform_iotype(0, outlist, outspecids, Absyn.OUTPUT(), bo);
        inout_special = listAppend(inspecial,outspecial);
        inout_types = listAppend(mintypes,mouttypes);
      then
        ((inout_special),(inout_types),inlist1,outlist1,inspecids,intypes);
    case(_,_)
    then
      ({},{},{},{},{},{});
  end matchcontinue;
end transform_decl_signature;

public function get_simplelist
  // checked and fixed
  input list<Absynrml.Exp> inexp;
  input list<Absynrml.RMLType> inrmltype;
  output list<Ident> outstringlst;
  output list<Absyn.EquationItem> outeqitem;
algorithm
  (outstringlst,outeqitem):= matchcontinue(inexp,inrmltype)
    local
      Absynrml.RMLIdent id;
      String id1;
      Absyn.Exp mexp;
      Absyn.RMLExp exp;
      list<Absynrml.Exp> rest,explst;
      list<Ident> rest1;
      list<Absynrml.RMLType> outtypes_rest;
      Absynrml.RMLType outtype;
      String pdb;
      Ident outtypeid,outypeid1;
      Absyn.ComponentRef cref;
      Absyn.EquationItem eqitem;
      Absyn.Info info:= Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));
      list<Absyn.EquationItem> eqitems,eqitems1;

    case ({},_) then ({},{});
    case ((Absynrml.RML_REFERENCE(id)::rest),(_::outtypes_rest))
      equation
        id1 = get_rml_id(id,true);
        failure(equality(id1 = "nil"));
        (rest1,eqitems) = get_simplelist(rest,outtypes_rest);
      then
        ((id1::rest1),eqitems);

    case ((exp::rest),(outtype::outtypes_rest))
      equation
        (_,(outtypeid :: _)) = get_iotypeids("out", 0, {outtype}, {}, false);
        (rest1,eqitems) = get_simplelist(rest,outtypes_rest);
        mexp = transform_expression(exp);
        cref = create_cref(outtypeid);
        eqitem = Absyn.EQUATIONITEM(Absyn.EQ_EQUALS(Absyn.CREF(cref),mexp),NONE(),info);
        eqitems1 = listAppend(eqitems,{eqitem});
      then
        ((outtypeid :: rest1),eqitems1);

    case({exp as Absynrml.RMLTUPLE(explst)},{outtype})
      equation
        (_,(outtypeid :: _)) = get_iotypeids("out", 0, {outtype}, {}, false);
        mexp = transform_expression(exp);
        cref = create_cref(outtypeid);
        eqitem = Absyn.EQUATIONITEM(Absyn.EQ_EQUALS(Absyn.CREF(cref),mexp),NONE(),info);
      then
        (outtypeid::{},{eqitem});

    case(_,_) then ({},{});
  end matchcontinue;
end get_simplelist;

public function get_simplereslist
  input Absynrml.RMLResult inrmlresult;
  input list<Absynrml.RMLType> inrmltype;
  output list<Ident> outident;
  output list<Absyn.EquationItem> outequationitem;
algorithm
  (outident,outequationitem):=matchcontinue(inrmlresult,inrmltype)
    local
      Absynrml.RMLIdent id;
      Ident id1,id2,outtypeid;
      Absyn.ComponentRef cref;
      Absynrml.RMLType outtype;
      list<Absynrml.RMLType> outtypes;
      String pdb;
      Absyn.Info info:= Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));
      list<String> com:={};
      Option<Absyn.Comment> mcom;
      Absyn.Exp mexp;
      Absyn.RMLExp exp;
      list<Absynrml.Exp> x,explist;
      list<Ident> reslist;
      list<Absyn.EquationItem> eqitems;
      Absyn.EquationItem eqitem;

    case(Absynrml.RETURN({},info),_)then ({},{});
    case(Absynrml.FAIL(),_)then ({},{});

    case(Absynrml.RETURN(Absynrml.RML_REFERENCE(id)::{},info),_)
      equation
        id1=get_rml_id(id,true);
        failure(equality(id1 = "nil"));
      then
        (id1::{},{});

        /*we have more then one output results but just one output */
    case(Absynrml.RETURN(x as Absynrml.RMLTUPLE(explist)::{},info),{outtype})
      equation
        (reslist,eqitems)=get_simplelist(x,{outtype});
      then
        (reslist,eqitems);

        /*we have more then one output*/

    case(Absynrml.RETURN(Absynrml.RMLTUPLE(explist)::{},info),outtypes)
      equation
        (reslist,eqitems)=get_simplelist(explist,outtypes);
      then
        (reslist,eqitems);

        /*ordinary output, can also be used in simplecase*/

    case(Absynrml.RETURN(exp::{},info),outtype::{})
      equation
        (_,(outtypeid :: _)) = get_iotypeids("out", 0, {outtype}, {}, false);
        mexp=transform_expression(exp);
        mcom=transform_comment(com,false);
        cref=create_cref(outtypeid);
        eqitem = Absyn.EQUATIONITEM(Absyn.EQ_EQUALS(Absyn.CREF(cref),mexp),mcom,info);

      then
        (outtypeid::{},{eqitem});

  end matchcontinue;
end get_simplereslist;

public function getif_simplepatlist
  // checked and fixed,
  input list<Absynrml.RMLPattern> inrmlpattern;
  output list<Ident> outident;
  output Boolean outbool;
algorithm
  (outident,outbool):= matchcontinue(inrmlpattern)
    local
      Absynrml.RMLIdent id;
      String id1,cid;
      list<Ident> rest1;
      list<Absynrml.RMLPattern> rest;
      Boolean b;
      String pdb;
    case ({}) then ({},true);
    case ((Absynrml.RMLPAT_IDENT(id)::rest))
      equation
        id1 = get_rml_id(id,true);
        failure(equality(id1 = "nil"));
        (rest1,b) = getif_simplepatlist(rest);

      then
        ((id1::rest1),b);
    case (_) then ({},false);
  end matchcontinue;
end getif_simplepatlist;

public function getif_simpleinlist
  input Absynrml.RMLPattern inrmlpattern;
  output list<Ident> outident;
  output Boolean outbool;
algorithm
  (outident,outbool):= matchcontinue(inrmlpattern)
    local
      Absynrml.RMLIdent id;
      String id1,cid;
      String pdb;
      Boolean b;
      list<Absynrml.RMLPattern> patlist;
      list<Ident> rest,rest1;
    case(Absynrml.RMLPAT_IDENT(id))
      equation
        id1=get_rml_id(id,true);
        cid=get_rml_id2(id);

        failure(equality(id1 = "nil"));
      then
        ({id1},true);

    case(Absynrml.RMLPAT_STRUCT(NONE(),patlist))
      equation
        (rest1,b)=getif_simplepatlist(patlist);
      then
        (rest1,b);
  end matchcontinue;
end getif_simpleinlist;

public function remove_ids
  input list<Ident> inident;
  input list<Ident> inrmlident;
  output list<Ident> outrmlident;
algorithm
  outrmlident:= matchcontinue(inident,inrmlident)
    local
      Ident id,varname;
      list<Ident> id_list,rest1;
      list<Ident> rest;
    case(_,{}) then {};


    case(id_list,varname::rest)
      equation
        false=is_unique(varname,id_list);
        rest1=remove_ids(id_list,rest);
      then
        rest1;

    case(id_list,id::rest)
      equation
        rest1=remove_ids(id_list,rest);
      then
        id::rest1;
  end matchcontinue;
end remove_ids;

public function getif_simplecase
  input list<Absynrml.RMLRule> inrmlrule;
  input Absynrml.RMLType inrmltype;
  output list<Absyn.ElementItem> outelementitem;
  output list<Absyn.ElementItem> outelementitem1;
  output list<Absyn.EquationItem> outequationitem;
algorithm
  (outelementitem,outelementitem1,outequationitem):=matchcontinue(inrmlrule,inrmltype)
    local
      Absynrml.RMLIdent id;
      list<Ident> ids,locals,locals1;
      Absynrml.RMLPattern pattern;
      Absynrml.RMLGoal goals;
      Absynrml.RMLResult result;
      list<Absyn.ElementItem> mintypes,mouttypes, inout_types,inspecial,outspecial,inout_special;
      list<Absyn.ElementItem> special_types1,local_decl1,spec_n_locals;
      list<Absyn.ElementItem> special_types:= special_types1;
      list<Absyn.ElementItem> local_decl:= {};
      Absyn.Info info;
      list<Ident>  simplelist,reslist;
      list<String> inspecids,outspecids;
      Boolean bei;
      list<Absyn.EquationItem> eqitems,eqitems1,eqres;
      list<Absynrml.RMLType> intypes,outtypes;

    case(Absynrml.RMLRULE(id,pattern,SOME(goals),result,info)::{},Absynrml.RMLTYPE_SIGNATURE(Absynrml.CALLSIGN(intypes,outtypes)))
      equation
        (simplelist,true)=getif_simpleinlist(pattern);
        (reslist,eqres)=get_simplereslist(result,outtypes);
        (eqitems,ids,_,_)=transform_goals(goals,Absynrml.EMPTY_RESULT());
        (inspecial,_)=get_specialtypes_lst(intypes,false,0);
        (outspecial,_)=get_specialtypes_lst(outtypes,false,0);
        (inspecids,_)=get_iotypeids("in",0,intypes,false);
        (mintypes,_)=transform_iotype(0,simplelist,inspecids,Absyn.INPUT(),true);
        bei=is_unique_list(reslist);
        (outspecids,_)=get_iotypeids("out",0,outtypes,false);
        (mouttypes,_)=transform_iotype(0,reslist,outspecids,Absyn.OUTPUT(),bei);
        (eqitems,ids,_,_)=transform_goals(goals,Absynrml.EMPTY_RESULT());
        eqitems1=listAppend(eqitems,eqres);
        inout_special=listAppend(inspecial,outspecial);
        inout_types=listAppend(mintypes,mouttypes);
      then
        (inout_types,inout_special,eqitems1);
  end matchcontinue;
end getif_simplecase;

public function get_pub_or_pro
  "special function to get public and protected statements"
  input Ident inident;
  input list<Absyn.ElementItem> initem;
  output Absyn.ClassPart outclasspart;
algorithm
  outclasspart:=matchcontinue(inident,initem)
    local
      Ident id;
      list<Absyn.ElementItem> eitems;
    case(id,eitems)
    then
      Absyn.PUBLIC(eitems);
    case(_,eitems)
    then
      Absyn.PROTECTED(eitems);
  end matchcontinue;
end get_pub_or_pro;

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
    then
      Absyn.PUBLIC(eitems);
    case(eitems,false)
    then
      Absyn.PROTECTED(eitems);
  end matchcontinue;
end create_pubclasspart;

/* New function to handle rmldefintion section */
public function transform_rmldef
  input Absynrml.RMLDefinition inrmldef;
  input Boolean inbool;
  input String instring;
  output list<Absyn.ClassPart> outclasspart;

algorithm
  (outclasspart):= matchcontinue(inrmldef,inbool,instring)
    local
      Absynrml.RMLIdent id,id_java,java_id,type_id;
      String mid,mid1,classident,id_name,file;
      list<Ident> mids,rmlidents,rmlidents1;
      String java_id_name,cid,cid1,mtype_id;
      String spec_type_id,import_name,valtype_id,valtype_id1,s;
      list<String> com={};
      Option<Absyn.Comment> com1;
      Absynrml.RMLType sign,sign1,x,rtype,the_type;
      list<Absynrml.RMLType> type_list;
      list<Absynrml.RMLType> intypes;
      list<Absynrml.DTMember> dtmlist;
      Absynrml.DTMember dtmember;
      String pdb;
      Absyn.Exp mexp;
      Absynrml.RMLExp exp;
      Boolean pub,b;
      Absyn.ElementSpec import1,component;
      Absyn.Class class1,first,fixed;
      list<Absyn.Class> classes,rclasses,rest,rfixed_classes;
      Absyn.Algorithm algorithm1;
      Absyn.AlgorithmItem ai;
      list<Absyn.Case> case_list;
      list<Absynrml.RMLRule> rules;
      Absyn.ClassPart classpart;
      list<Absyn.ClassPart> ext_c;
      Absyn.ClassDef derived,classdef;
      Absyn.Info info:=Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));
      list<Absyn.EquationItem> equations;
      Absyn.ElementItem eitem,eitem1;
      list<Absyn.ElementItem> in_out_spec,in_out_decl,eitemlist,special_types,local_decl,spec_n_local_decl;
      list<Absyn.ElementItem> spec_n_locals,elisttest,elistunique,elisttest1;
      list<Absyn.ElementItem> recorddef,typedef,eitemlist1,eitems,eitems1;
      list<String> il,ol,ilist,olist,typeids;
      Absyn.Restriction restriction;
      Boolean b_dummy,partialprefix,finalprefix,encapsulatedprefix;


      // with statements in definitions sections

    case(Absynrml.WITH_DEF(s,info),pub,file)
      equation
        import_name=get_import_name(s);
        com1=transform_comment(com,true);
        import1=create_import(import_name,com1,info);
        eitem=create_standard_elementitem(import1,info);
        classpart=create_pubclasspart({eitem},pub);

      then
        ({classpart});

        /*Datatype statements*/
    case(Absynrml.DATATYPE_DEFINITION(Absynrml.DATATYPE(id,dtmlist),info),pub,file)
      equation
        (recorddef,typedef)=transform_dtmember_list(dtmlist);
        mid=get_rml_id(id,true);
        class1=create_class_parts(mid,Absyn.R_UNIONTYPE(),false,{Absyn.PUBLIC((recorddef))},{},true,info);
        eitemlist=create_elementitem_list({class1},info);
        eitemlist1=listAppend(List.unique(typedef),eitemlist);
        classpart=create_pubclasspart(eitemlist1,pub);

      then

        ({classpart});

    case( Absynrml.VAL_DEF(id,exp,info),_,file)
      equation
        id_java=transform_id_java(id);
        mid=get_rml_id(id_java,true);
        (valtype_id,b)=get_alternative_typeid(mid,true);
        valtype_id1=getalternate(valtype_id);
        mexp=transform_expression(exp);
        com1=transform_comment(com,true);
        component=create_components_init({mid},valtype_id1,Absyn.CONST(),Absyn.BIDIR(),mexp,com1);
        eitem=create_standard_elementitem(component,info);
        classpart=get_pub_or_pro(mid,{eitem});

      then
        ({classpart});


        /* relation definition2 */
    case(Absynrml.RELATION_DEFINITION(id,SOME(sign),rules,info),_,file)
      equation

        mid=get_rml_id(id,true);
        (in_out_spec,in_out_decl,ilist,olist,typeids,intypes)=transform_decl_signature(sign,false);
        (case_list,elisttest,rmlidents)=transform_rule_list(rules,typeids,intypes);
        rmlidents1=List.unique(rmlidents);
        elisttest1=getlocaltypes(file,mid,rmlidents1);
        elistunique=List.unique(elisttest);
        algorithm1=create_algorithm_match(ilist,olist,elisttest1,case_list);
        ai=create_standard_algorithmitem(algorithm1,info);
        java_id=transform_id_java(id);
        mid=get_rml_id(java_id,true);
        id_name=identName(id);
        java_id_name=identName(java_id);
        class1=create_class_parts(mid,Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.NO_PURITY())),false,{Absyn.PUBLIC(in_out_decl),Absyn.PUBLIC(List.unique(in_out_spec)),Absyn.ALGORITHMS({ai})},{},true,info);
        eitemlist=create_elementitem_list({class1},info);
        classpart=create_pubclasspart(eitemlist,false);


      then
        ({classpart});




    case(Absynrml.RELATION_DEFINITION(id,NONE(),rules,info),_,file)
      equation
        (case_list,elisttest,rmlidents)=transform_rule_list(rules,{},{});
        algorithm1=create_algorithm_match({},{},{},case_list);
        ai=create_standard_algorithmitem(algorithm1,info);
        java_id=transform_id_java(id);
        mid=get_rml_id(java_id,true);
        id_name=identName(id);
        java_id_name=identName(java_id);
        class1=create_class_parts(mid,Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.NO_PURITY())),false,{Absyn.PUBLIC({}),Absyn.PUBLIC({}),Absyn.ALGORITHMS({ai})},{},true,info);
        eitemlist=create_elementitem_list({class1},info);
        classpart=create_pubclasspart(eitemlist,false);

      then
        ({classpart});


  end matchcontinue;
end transform_rmldef;

function getalternate
  input String instring;
  output String outstring;
algorithm
  outstring := matchcontinue(instring)
    local
      String id;
    case ("init_env") then "VarBndlist";
    case ("env_init") then "Env";
    case (id) then id;
  end matchcontinue;
end getalternate;

public function getlocaltypes
  input String instring;
  input Ident inident;
  input list<Ident> inident1;
  output list<Absyn.ElementItem> outelement;
algorithm
  outelement:=matchcontinue(instring,inident,inident1)
    local
      String file;
      Ident first,first1,funcname;
      list<Absyn.ElementItem> elist,elisttotal;
      Absyn.ElementItem eitems;
      list<Ident> rest;

    case(file,funcname,{}) then {};

    case(file,funcname,first::rest)
      equation
        /* Take the first variable from the list and query the dictionary for types*/
        first1=variabletypes(file,funcname,first);
        eitems=assign_type(first1,first);
        elist=getlocaltypes(file,funcname,rest);
        elisttotal=listAppend({eitems},elist);
      then
        elisttotal;
  end matchcontinue;
end getlocaltypes;

public function variabletypes
  input String filename;
  input Ident funcname;
  input Ident variablename;
  output Ident outident;
algorithm
  outident:= Dict.localdeclarationtypes(filename,funcname,variablename);
end variabletypes;

public function transform_rmldecl
  "function to translate different types of RML structures appearing in rml interface section"
  input Absynrml.RMLDec inrmldecl;
  input Boolean inbool;
  output list<Absyn.ClassPart> outclasspart;
algorithm
  outclasspart:= matchcontinue(inrmldecl,inbool)
    local
      Absynrml.RMLIdent id,id_java,java_id,type_id;
      String mid,mid1,classident,id_name;
      list<Ident> mids;
      String java_id_name,cid,cid1,mtype_id;
      String spec_type_id,import_name,valtype_id,s;
      list<String> com={};
      Option<Absyn.Comment> com1;
      Absynrml.RMLType sign,sign1,x,rtype,the_type;
      list<Absynrml.RMLType> type_list;
      list<Absynrml.DTMember> dtmlist;
      Absynrml.DTMember dtmember;
      String pdb;
      Absyn.Exp exp,mexp;
      Boolean pub,b;
      Absyn.ElementSpec import1,component;
      Absyn.Class class1,first,fixed;
      list<Absyn.Class> classes,rclasses,rest,rfixed_classes;
      Absyn.Algorithm algorithm1;
      Absyn.AlgorithmItem ai;
      list<Absyn.Case> case_list;
      list<Absynrml.RMLRule> rules;
      Absyn.ClassPart classpart;
      list<Absyn.ClassPart> ext_c;
      Absyn.ClassDef derived,classdef;
      Absyn.Info info;
      list<Absyn.EquationItem> equations;
      Absyn.ElementItem eitem,eitem1;
      list<Absyn.ElementItem> in_out_spec,in_out_decl,eitemlist,special_types,local_decl,spec_n_local_decl;
      list<Absyn.ElementItem> spec_n_locals:= {};
      list<Absyn.ElementItem> recorddef,typedef,eitemlist1,eitems,eitems1;
      list<String> il,ol,ilist,olist;
      Absyn.Restriction restriction;
      Boolean b_dummy,partialprefix,finalprefix,encapsulatedprefix;

      /*type statements 1*/

    case(Absynrml.TYPE(type_id,Absynrml.RMLTYPE_USERDEFINED(id),info),pub)
      equation
        mid=get_rml_id(id,true);
        cid=transform_typeid(mid,false);
        mid1=get_rml_id2(id);
        cid1=transform_typeid(mid1,false);
        com1=transform_comment(com,true);
        derived=create_type(cid1,com1);
        mtype_id=get_rml_id(type_id,true);
        class1=create_class(mtype_id,Absyn.R_TYPE(),derived,info);
        eitemlist=create_elementitem_list({class1},info);
        classpart=create_pubclasspart(eitemlist,pub);

      then
        ({classpart});

        /*type statements 2*/
    case(Absynrml.TYPE(type_id,x,info),pub)
      equation
        com1=transform_comment(com,true);
        (special_types,_)=get_specialtypes(x,false,com1,0);
        (spec_type_id,_)=get_specialtype_id(x,"",false);
        classes=getClasses(special_types);
        mtype_id=get_rml_id(type_id,true);
        rclasses=listReverse(classes);
        first::rest=rclasses;
        Absyn.CLASS(classident,partialprefix,finalprefix,encapsulatedprefix,restriction,classdef,info)=first;
        fixed=Absyn.CLASS(mtype_id,partialprefix,finalprefix,encapsulatedprefix,restriction,classdef,info);
        rfixed_classes=fixed::rest;
        classes=listReverse(rfixed_classes);
        eitemlist = create_elementitem_list(classes,info);
        classpart = create_pubclasspart(eitemlist,pub);

      then
        ({classpart});

    case(Absynrml.DATATYPE_INTERFACE(Absynrml.DATATYPE(id,dtmlist),info),pub)
      equation
        (recorddef,typedef)=transform_dtmember_list(dtmlist);
        mid=get_rml_id(id,true);
        class1=create_class_parts(mid,Absyn.R_UNIONTYPE(),false,{Absyn.PUBLIC(recorddef)},{},true,info);
        // class1=Absyn.CLASS(mid,false,false,false,Absyn.R_UNIONTYPE(),Absyn.PARTS({},{},{Absyn.PUBLIC(recorddef)},NONE()),info);
        eitemlist=create_elementitem_list({class1},info);
        eitemlist1=listAppend(List.unique(typedef),eitemlist);
        classpart=create_pubclasspart(eitemlist1,pub);
      then
        ({classpart});
        /*With statements */

    case(Absynrml.WITH(s,info),pub)
      equation
        import_name=get_import_name(s);
        com1=transform_comment(com,true);
        import1=create_import(import_name,com1,info);
        eitem=create_standard_elementitem(import1,info);
        classpart=create_pubclasspart({eitem},true);

      then
        ({classpart});

        /*valinterface section*/

    case( Absynrml.VAL_INTERFACE(id,rtype,info),pub)
      equation
        id_java=transform_id_java(id);
        mid=get_rml_id(id_java,true);
        (eitems,_)=get_specialtypes(rtype,false,NONE(),0);
        (valtype_id,b)=get_specialtype_id(rtype,"",false);
        classpart=get_pub_or_pro(mid,eitems);

      then
        ({classpart});

    case(_,_)then({});

  end matchcontinue;
end transform_rmldecl;


/* make more general
 rpl " "* with " "
 rpl "*" with ""
 */

public function remove_symbols
  input String instring;
  input Integer ininteger;
  output String outstring;
  output Integer outinteger;
algorithm
  (outstring,outinteger):=matchcontinue(instring,ininteger)
    local
      Integer i,ic,ic1,l;
      String s,str,str1,ss;

    case(s,i)
      equation
        l=stringLength(s);
        true=intGe(i,l);
      then
        ("",i);
    case(s,i)
      equation
        " "=stringGetStringChar(s,i);
        ic=intAdd(i,1);
        (str,ic1)=remove_symbols(s,ic);
        str1=stringAppend(" ",str);
      then
        (str1,ic1);

    case(s,i)
      equation
        "*"=stringGetStringChar(s,i);
        ic=intAdd(i,1);
        (str,ic1)=remove_symbols(s,ic);
      then
        (str,ic1);
    case(s,0)
      equation
        ss=stringGetStringChar(s,0);
      then
        (ss,1);
    case(s,i) then ("",i);
  end matchcontinue;

end remove_symbols;

/*
 this relation does this:
 rpl " with \"
 rpl [ with {
 rpl ] with }
 rpl " relation" with " function"
 if s[0]=" " then remove_symbols
 remove_symbols
 if \10 <cr> then remove_symbols (actually \n* => "")
 rpl "relation" with "function"
 rpl " "$ with $
 rpl "*"$ with $
 */

public function transform_comment_handle_dq
  input String instring;
  input Integer ininteger;
  output String outstring;
algorithm
  outstring:= matchcontinue(instring,ininteger)
    local
      Integer i;
      String s;
    case(s,i)
      equation
        s=System.stringReplace(s,"\"","\\\"");
        s=System.stringReplace(s,"\\\\\"","\\\"");
        s=System.stringReplace(s,"[","{");
        s=System.stringReplace(s,"]","}");
        s=System.stringReplace(s,"relation","function");
        s=System.stringReplace(s,"/*","/-");
        s=System.stringReplace(s,"*/","-/");
        s=System.stringReplace(s,"*","");
        s=System.stringReplace(s,"/-","/*");
        s=System.stringReplace(s,"-/","*/");
        s=System.trim(s," ");
      then
        s;
  end matchcontinue;
end transform_comment_handle_dq;

public function get_comments
  // checked and fixed
  input list<String> instringlst;
  input String instring;
  output String outstring;
algorithm
  outstring:=matchcontinue(instringlst,instring)
    local
      String s,crest,first,last,last1,comments,first1,first2;
      list<String> rest;
    case({},s)then "";
    case(last::{},s)
      equation
        last1=transform_comment_handle_dq(last,0);
      then
        last1;
    case(first::rest,s)
      equation
        crest=get_comments(rest,s);
        first1=transform_comment_handle_dq(first,0);
        first2=stringAppend(first1,s);
        comments=stringAppend(first2,crest);
      then
        comments;
  end matchcontinue;
end get_comments;

public function get_comment
  input list<String> instringlst;
  input Boolean inbool;
  output Option<String> outstring;
algorithm
  outstring:= matchcontinue(instringlst,inbool)
    local
      list<String> x;
      String x1;
      Boolean b;

    case({},_) then NONE();

    case(x,true)
      equation
        x1=get_comments(x,"\n ");
      then
        SOME(x1);

    case(x,false)
      equation
        x1=get_comments(x," ");
      then
        SOME(x1);
  end matchcontinue;
end get_comment;

public function transform_comment
  input list<String> instringlst;
  input Boolean inbool;
  output Option<Absyn.Comment> outcomment;
algorithm
  outcomment:=matchcontinue(instringlst,inbool)
    local
      list<String> comments;
      String mcomments;
    case({},_)then NONE();
    case(comments,true)
      equation
        mcomments=get_comments(comments,"\n");
      then
        SOME(Absyn.COMMENT(NONE(),SOME(mcomments)));
    case(comments,false)
      equation
        mcomments=get_comments(comments," ");
      then
        SOME(Absyn.COMMENT(NONE(),SOME(mcomments)));
    case({},false) then NONE();
  end matchcontinue;
end transform_comment;

public function transform_rmldef_list

  input list<Absynrml.RMLDefinition> inrmldef;
  input Boolean inbool;
  input String instring;
  output list<Absyn.ClassPart> outclasspart;
algorithm
  (outclasspart):= matchcontinue(inrmldef,inbool,instring)
    local
      String pdb,p,file;
      Boolean pp;
      list<Absynrml.RMLDefinition> rest;
      Absynrml.RMLDefinition first;
      list<Absyn.ClassPart> cp,cp_rest,cp_first;

    case(first::rest,pp,file)
      equation
        (cp_first)=transform_rmldef(first,pp,file);
        (cp_rest)=transform_rmldef_list(rest,pp,file);
        cp=listAppend(cp_first,cp_rest);
      then
        (cp);

    case({},pp,file) then ({});
  end matchcontinue;
end transform_rmldef_list;

public function transform_rmldecl_list
  input list<Absynrml.RMLDec> indec;
  input Boolean inbool;
  output list<Absyn.ClassPart> outclasspart;

algorithm
  (outclasspart):= matchcontinue(indec,inbool)
    local
      String pdb,p;
      Boolean pp;
      list<Absynrml.RMLDec> rest;
      Absynrml.RMLDec first;
      list<Absyn.ClassPart> cp,cp_rest,cp_first;

    case(first::rest,pp)
      equation
        (cp_first)=transform_rmldecl(first,pp);
        (cp_rest)=transform_rmldecl_list(rest,pp);
        cp=listAppend(cp_first,cp_rest);
      then
        (cp);

    case({},pp) then ({});
  end matchcontinue;
end transform_rmldecl_list;

public function transform_interfaces
  input list<Absynrml.RMLDec> indec;
  output list<Absyn.ClassPart> outclasspart;
algorithm
  outclasspart:= matchcontinue(indec)
    local
      String pdb;
      list<String> p1,p2;
      list<Absynrml.RMLDec> x;
      list<Absyn.ClassPart> cp;
    case(x)
      equation
        (cp)=transform_rmldecl_list(x,true);
      then
        (cp);
  end matchcontinue;
end transform_interfaces;

public function transform_definitions
  input list<Absynrml.RMLDefinition> indec;
  input String instring;
  output list<Absyn.ClassPart> outclasspart;
algorithm
  outclasspart:= matchcontinue(indec,instring)
    local
      String pdb,p1,p2,file;
      list<Absynrml.RMLDefinition> x;
      list<Absyn.ClassPart> cp;

    case(x,file)
      equation
        (cp)=transform_rmldef_list(x,false,file);
      then
        (cp);
  end matchcontinue;
end transform_definitions;

public function transform_module
" start function which translates rml AST to MetaModelica AST"
  input Absynrml.Program inprogram;
  input String instring;
  output Absyn.Program outprogram;
algorithm
  outprogram:=matchcontinue(inprogram,instring)
    local
      Absynrml.RMLIdent id;
      String mid,file;
      list<String> comment:={};
      list<Absyn.ClassPart> cp,cp1,cp2;
      list<Absynrml.RMLInterface> iflist;
      list<Absynrml.RMLDefinition> deflist;
      Absyn.Program ast;
      String pub_db;
      Absyn.Class class1;
      //Absyn.Info info:=Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));
      Absyn.Info info;

    case(Absynrml.MODULE(id,iflist,{},info),file)
      equation
        (cp)=transform_interfaces(iflist);
        mid=get_rml_id(id,true);
        class1=create_class_parts(mid,Absyn.R_PACKAGE(),false,cp,comment,true,info);
      then
        Absyn.PROGRAM({class1},Absyn.TOP(),Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));

    case(Absynrml.MODULE(id,iflist,deflist,info),file)
      equation
        (cp1)=transform_interfaces(iflist);
        (cp2)=transform_definitions(deflist,file);
        cp=listAppend(cp1,cp2);
        mid=get_rml_id(id,true);
        class1=create_class_parts(mid,Absyn.R_PACKAGE(),false,cp,comment,true,info);
      then
        Absyn.PROGRAM({class1},Absyn.TOP(),Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));

  end matchcontinue;
end transform_module;

public function transform
  "Main function which starts the rml translation to MEtaModelica AST  , get the RML AST as input and passes the
   AST to different  translation functions to get the MEtaModelica AST"
  input Absynrml.Program rmlast;
  input String filename;
  output Absyn.Program astTreeModelica;
algorithm
  astTreeModelica := transform_module(rmlast,filename);
end transform;
end Translate;
