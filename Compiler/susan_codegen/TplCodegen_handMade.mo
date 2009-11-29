package TplCodegen

//import Debug;
public import Tpl;
public import Util;

public import TplAbsyn;


protected
constant Tpl.Text emptyTxt = Tpl.MEM_TEXT({}, {}); 

//type TA = TplAbsyn;

public function f_mmPackage
  input Tpl.Text inTxt;
  input TplAbsyn.MMPackage in_it;
 
  output Tpl.Text outTxt;  
algorithm
  outTxt := 
  matchcontinue(inTxt, in_it)
  local
    Tpl.Text txt;
    //TA.MMPackage v_it;
  case (txt, 
          TplAbsyn.MM_PACKAGE(
            name = v_it_name, 
            mmDeclarations = v_it_mmDeclarations
          )
         )    
    local
      TplAbsyn.PathIdent v_it_name;
      list<TplAbsyn.MMDeclaration> v_it_mmDeclarations;
    equation
      txt = Tpl.writeStr(txt, "package ");
      txt = f_pathIdent(txt, v_it_name);
      txt = Tpl.softNewLine(txt);
      txt = Tpl.writeTok(txt, 
        Tpl.ST_STRING_LIST({
          "\n",
          "protected constant Tpl.Text emptyTxt = Tpl.MEM_TEXT({}, {});\n",
          "\n",
          "public import Tpl;\n",
          "\n"
        }, true) );
      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
      txt = f_mmPackage_lm0(txt, v_it_mmDeclarations); //<mmDeclarations : mmDeclaration()\n>
      txt = Tpl.popIter(txt);
      txt = Tpl.softNewLine(txt);
      txt = Tpl.newLine(txt);
      txt = Tpl.writeStr(txt, "end ");
      txt = f_pathIdent(txt, v_it_name);
      txt = Tpl.writeStr(txt, ";");
    then txt;  
  end matchcontinue;
end f_mmPackage;

//<mmDeclarations : mmDeclaration()\n>
public function f_mmPackage_lm0
  input Tpl.Text inTxt;
  input list<TplAbsyn.MMDeclaration> inItems;
  
  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems)
  local
    Tpl.Text txt;
    TplAbsyn.MMDeclaration h;
    list<TplAbsyn.MMDeclaration> rest;
  case (txt, {} )    
    then txt;  
  
  case (txt, h :: rest )    
    equation
      txt = f_mmDeclaration(txt, h);
      txt = Tpl.nextIter(txt);
      txt = f_mmPackage_lm0(txt, rest);
    then txt;
      
  end matchcontinue;
end f_mmPackage_lm0;

public function f_mmDeclaration
  input Tpl.Text inTxt;
  input TplAbsyn.MMDeclaration in_it;
    
  output Tpl.Text outTxt;
algorithm
  outTxt := 
  matchcontinue(inTxt, in_it)
  local
    Tpl.Text txt;
  case (txt, 
        TplAbsyn.MM_IMPORT(
            packageName = TplAbsyn.IDENT("Tpl")
        )
       )    
    then txt;
  
  case (txt, 
        TplAbsyn.MM_IMPORT(
            packageName = TplAbsyn.IDENT("builtin")
        )
       )    
    then txt;
  
  case (txt, 
        TplAbsyn.MM_IMPORT(
            isPublic = v_it_isPublic, 
            packageName = v_it_packageName
        )
       )    
    local
      Boolean v_it_isPublic;
      TplAbsyn.PathIdent v_it_packageName;
    equation
      txt = f_mmPublic(txt, v_it_isPublic);
      txt = Tpl.writeStr(txt, " import ");
      txt = f_pathIdent(txt, v_it_packageName);
      txt = Tpl.writeStr(txt, ";");
      //txt = Tpl.newLine(txt);
    then txt;
  
  case (txt, 
        TplAbsyn.MM_STR_TOKEN_DECL(
            isPublic = v_isPublic, 
            name = v_it_name,
            value = v_it_value
        )
       )    
    local
      Boolean v_isPublic;
      String v_it_name;
      Tpl.StringToken v_it_value;
    equation
      txt = Tpl.newLine(txt);  
      txt = f_mmPublic(inTxt, v_isPublic);
      txt = Tpl.softNewLine(txt);
      txt = Tpl.writeStr(txt, "constant Tpl.StringToken ");
      txt = Tpl.writeParseNL(txt, v_it_name);
      txt = Tpl.writeStr(txt, " = ");
      txt = f_stringTokenConstant(txt, v_it_value);
      txt = Tpl.writeStr(txt, ";");
    then txt;
  
  case (txt, 
        TplAbsyn.MM_LITERAL_DECL(
            isPublic = v_it_isPublic, 
            name = v_it_name,
            value = v_it_value,
            litType = v_litType
        )
       )    
    local
      Boolean v_it_isPublic;
      String v_it_name;
      String v_it_value;
      TplAbsyn.TypeSignature v_litType;
    equation
      txt = Tpl.newLine(txt);  
      txt = f_mmPublic(inTxt, v_it_isPublic );
      txt = Tpl.softNewLine(txt);
      txt = Tpl.writeStr(txt, "constant ");
      txt = f_typeSig(txt, v_litType);
      txt = Tpl.writeStr(txt, " ");
      txt = Tpl.writeParseNL(txt, v_it_name);
      txt = Tpl.writeStr(txt, " = ");
      txt = Tpl.writeStr(txt, v_it_value);
      txt = Tpl.writeStr(txt, ";");
    then txt;
      
  case (txt, 
        v_mf as TplAbsyn.MM_FUN(
            isPublic = v_it_isPublic, 
            name = v_it_templName,
            inArgs = v_it_inArgs,
            outArgs = v_it_outArgs,
            locals = v_it_locals,
            statements = v_it_statements
        )
       )    
    local
      TplAbsyn.MMDeclaration v_mf;
      Boolean v_it_isPublic;
      String v_it_templName;
      TplAbsyn.TypedIdents v_it_inArgs;
      TplAbsyn.TypedIdents v_it_outArgs;
      TplAbsyn.TypedIdents v_it_locals;
      list<TplAbsyn.MMExp> v_it_statements;
    equation
      txt = Tpl.newLine(txt);
      txt = f_mmPublic(txt, v_it_isPublic);
      txt = Tpl.softNewLine(txt);
      txt = Tpl.writeStr(txt, "function ");
      txt = Tpl.writeParseNL(txt, v_it_templName);
      txt = Tpl.softNewLine(txt);
      txt = f_mmDeclaration_mf0(txt, v_it_statements,v_it_inArgs, v_it_outArgs, v_it_locals); //<   match statements
      txt = Tpl.writeStr(txt, "end ");
      txt = Tpl.writeParseNL(txt, v_it_templName);
      txt = Tpl.writeStr(txt, ";");
    then txt;

  end matchcontinue;
end f_mmDeclaration;

//<   match statements
public function f_mmDeclaration_mf0
  input Tpl.Text inTxt;
  input list<TplAbsyn.MMExp> in_it_statements;
  input TplAbsyn.TypedIdents in_mf_inArgs;
  input TplAbsyn.TypedIdents in_mf_outArgs;
  input TplAbsyn.TypedIdents in_mf_locals;
    
  output Tpl.Text outTxt;
algorithm
  outTxt := 
  matchcontinue(inTxt, in_it_statements, in_mf_inArgs, in_mf_outArgs, in_mf_locals)
  local
    Tpl.Text txt;
    //list<TplAbsyn.MMExp> v_it_statements;
    TplAbsyn.TypedIdents v_mf_inArgs;
    TplAbsyn.TypedIdents v_mf_outArgs;
    TplAbsyn.TypedIdents v_mf_locals;      
  
  case (txt, 
        { v_c as TplAbsyn.MM_MATCH( matchCases = v_c_matchCases ) },
        v_mf_inArgs, v_mf_outArgs, v_mf_locals
        )
    local
      TplAbsyn.MMExp v_c;
      list<TplAbsyn.MMMatchCase> v_c_matchCases;
    equation
      txt = Tpl.pushBlock(txt,Tpl.BT_INDENT(2));
      txt = f_typedIdentsEx(txt, v_mf_inArgs, "input", "in_");
      txt = Tpl.softNewLine(txt);
      txt = Tpl.newLine(txt);
      txt = f_typedIdentsEx(txt, v_mf_outArgs, "output", "out_");
      txt = Tpl.softNewLine(txt);
      txt = Tpl.popBlock(txt);
      
      txt = f_mmMatchFunBody(txt, v_mf_inArgs, v_mf_outArgs, v_mf_locals, v_c_matchCases);
    then txt;

  case (txt, v_sts, v_mf_inArgs, v_mf_outArgs, v_mf_locals)
    local
      list<TplAbsyn.MMExp> v_sts; 
    equation
      txt = Tpl.pushBlock(txt,Tpl.BT_INDENT(2));
      txt = f_typedIdentsEx(txt, v_mf_inArgs, "input", "");
      txt = Tpl.softNewLine(txt);
      txt = Tpl.newLine(txt);
      txt = f_typedIdentsEx(txt, v_mf_outArgs, "output", "out_");
      txt = Tpl.softNewLine(txt);
      txt = Tpl.popBlock(txt);
      
      txt = Tpl.newLine(txt);
      txt = Tpl.pushBlock(txt,Tpl.BT_INDENT(2));      
      txt = f_typedIdents(txt, v_mf_locals);
      txt = Tpl.softNewLine(txt);
      txt = Tpl.popBlock(txt);
      txt = Tpl.writeStr(txt, "algorithm");
      txt = Tpl.softNewLine(txt);
      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
      txt = f_mmDeclaration_lm1(txt, v_sts);
      txt = Tpl.popIter(txt);
      txt = Tpl.softNewLine(txt);      
    then txt;
  end matchcontinue;
end f_mmDeclaration_mf0;

public function f_mmDeclaration_lm1
  input Tpl.Text inTxt;
  input list<TplAbsyn.MMExp> inItems;
  
  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems)
  local
    Tpl.Text txt;
    TplAbsyn.MMExp v_it;
    list<TplAbsyn.MMExp> rest;
  
  case (txt, {} )
    then txt;  
  
  case (txt, v_it :: rest )    
    equation
      txt = f_mmExp(txt, v_it, ":=" );
      txt = Tpl.nextIter(txt);
      txt = f_mmDeclaration_lm1(txt, rest);
    then txt;
      
  end matchcontinue;
end f_mmDeclaration_lm1;


public function f_mmMatchFunBody
  input Tpl.Text intxt;
  input TplAbsyn.TypedIdents in_mf_inArgs;
  input TplAbsyn.TypedIdents in_mf_outArgs;
  input TplAbsyn.TypedIdents in_mf_locals;
  input list<TplAbsyn.MMMatchCase> in_c_matchCases;
    
  output Tpl.Text outtxt;
algorithm
  outtxt := Tpl.writeTok(intxt, Tpl.ST_LINE("algorithm\n"));
  outtxt := Tpl.pushBlock(outtxt, Tpl.BT_INDENT(2));
  outtxt := Tpl.writeTok(outtxt, Tpl.ST_STRING("("));
  outtxt := Tpl.pushIter(outtxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
  outtxt := f_mmMatchFunBody_lm0(outtxt, in_mf_outArgs); //<outArgs of (_,nm): "out_<nm>" ', '>
  outtxt := Tpl.popIter(outtxt);
  outtxt := Tpl.writeTok(outtxt, Tpl.ST_STRING_LIST({
                ") := \n",
                "matchcontinue(" }, false));
  outtxt := Tpl.pushIter(outtxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
  outtxt := f_mmMatchFunBody_lm1(outtxt, in_mf_inArgs); //<inArgs of (_,nm) : "in_<nm>" ', '>
  outtxt := Tpl.popIter(outtxt);
  outtxt := Tpl.writeTok(outtxt, Tpl.ST_LINE(")\n"));
  outtxt := Tpl.pushBlock(outtxt, Tpl.BT_INDENT(2));
  outtxt := Tpl.writeTok(outtxt, Tpl.ST_LINE("local\n"));
  outtxt := Tpl.pushBlock(outtxt, Tpl.BT_INDENT(2));
  outtxt := f_typedIdents(outtxt, in_mf_locals);
  outtxt := Tpl.softNewLine(outtxt);
  outtxt := Tpl.popBlock(outtxt);
  outtxt := Tpl.popBlock(outtxt);
  outtxt := Tpl.popBlock(outtxt);
  outtxt := Tpl.pushIter(outtxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
  outtxt := f_mmMatchFunBody_lm2(outtxt, in_c_matchCases, in_mf_outArgs); //matchCases of (mexps, locals, statements) :
  outtxt := Tpl.popIter(outtxt);
  outtxt := Tpl.softNewLine(outtxt);
  outtxt := Tpl.writeTok(outtxt, Tpl.ST_LINE("  end matchcontinue;\n"));  
end f_mmMatchFunBody;

//<outArgs of (_,nm): "out_<nm>" ', '>
public function f_mmMatchFunBody_lm0
  input Tpl.Text inTxt;
  input TplAbsyn.TypedIdents inItems;

  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems)
  local
    Tpl.Text txt;
  
  case (txt, {} )
    then txt;  
  
  case (txt, (v_nm, _) :: rest )
    local
      TplAbsyn.Ident v_nm;
      TplAbsyn.TypedIdents rest;    
    equation
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("out_"));
      txt = Tpl.writeTok(txt, Tpl.ST_STRING(v_nm));
      txt = Tpl.nextIter(txt);      
      txt = f_mmMatchFunBody_lm0(txt, rest);      
    then txt;
      
  end matchcontinue;
end f_mmMatchFunBody_lm0;

//<inArgs of (_,nm) : "in_<nm>" ', '>
public function f_mmMatchFunBody_lm1
  input Tpl.Text inTxt;
  input TplAbsyn.TypedIdents inItems;

  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems)
  local
    Tpl.Text txt;
  
  case (txt, {} )
    then txt;  
  
  case (txt, (v_nm, _) :: rest )
    local
      TplAbsyn.Ident v_nm;
      TplAbsyn.TypedIdents rest;    
    equation
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("in_"));
      txt = Tpl.writeTok(txt, Tpl.ST_STRING(v_nm));
      txt = Tpl.nextIter(txt);      
      txt = f_mmMatchFunBody_lm1(txt, rest);      
    then txt;
      
  end matchcontinue;
end f_mmMatchFunBody_lm1;

//matchCases of (mexps, locals, statements) :
public function f_mmMatchFunBody_lm2
  input Tpl.Text inTxt;
  input list<TplAbsyn.MMMatchCase> inItems;
  input TplAbsyn.TypedIdents in_mf_outArgs;  

  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems, in_mf_outArgs)
  local
    Tpl.Text txt;
  
  case (txt, {}, _)
    then txt;  
  
  case (txt, (v_mexps, v_locals, v_statements) :: rest, v_mf_outArgs)
    local
      list<TplAbsyn.MatchingExp> v_mexps;
      TplAbsyn.TypedIdents v_locals;
      list<TplAbsyn.MMExp> v_statements;
      list<TplAbsyn.MMMatchCase> rest;
      TplAbsyn.TypedIdents v_mf_outArgs;    
    equation
      txt = Tpl.pushBlock(txt,Tpl.BT_INDENT(4));      
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("case ( "));
      txt = Tpl.pushBlock(txt,Tpl.BT_ANCHOR(0));            
      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
      txt = f_mmMatchFunBody_lm3(txt, v_mexps); //<mexps : mmMatchingExp() ',\n'; anchor>
      txt = Tpl.popIter(txt);
      txt = Tpl.popBlock(txt);
      txt = Tpl.softNewLine(txt);
      txt = Tpl.writeTok(txt, Tpl.ST_LINE("     )\n"));      
      txt = Tpl.popBlock(txt);
      txt = f_mmMatchFunBody_cf0(txt, v_locals); //if locals <> {} then
      txt = Tpl.softNewLine(txt);
      txt = Tpl.writeTok(txt, Tpl.ST_LINE("      equation\n"));      
      txt = Tpl.pushBlock(txt,Tpl.BT_INDENT(8));      
      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
      txt = f_mmMatchFunBody_lm4(txt, v_statements); //<statements : mmExp(it, '=')\n>
      txt = Tpl.popIter(txt);
      txt = Tpl.popBlock(txt);
      txt = Tpl.softNewLine(txt);
      txt = Tpl.pushBlock(txt,Tpl.BT_INDENT(6));      
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("then ("));
      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
      txt = f_mmMatchFunBody_lm5(txt, v_mf_outArgs); //<match mf.outArgs ...
      txt = Tpl.popIter(txt);
      txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      txt = Tpl.popBlock(txt);
      txt = Tpl.nextIter(txt);      
      txt = f_mmMatchFunBody_lm2(txt, rest, v_mf_outArgs);      
    then txt;
      
  end matchcontinue;
end f_mmMatchFunBody_lm2;

//if locals <> {} then
public function f_mmMatchFunBody_cf0
  input Tpl.Text inTxt;
  input TplAbsyn.TypedIdents in_locals;

  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, in_locals)
  local
    Tpl.Text txt;
  
  case (txt, {} )
    then txt;  
  
  case (txt, v_locals)
    local
      TplAbsyn.TypedIdents v_locals;    
    equation
      txt = Tpl.writeTok(txt, Tpl.ST_LINE("      local\n"));      
      txt = Tpl.pushBlock(txt,Tpl.BT_INDENT(8));
      txt = f_typedIdents(txt, v_locals);
      txt = Tpl.softNewLine(txt);     
      txt = Tpl.popBlock(txt);
    then txt;
      
  end matchcontinue;
end f_mmMatchFunBody_cf0;

//<mexps : mmMatchingExp() ',\n'; anchor>
public function f_mmMatchFunBody_lm3
  input Tpl.Text inTxt;
  input list<TplAbsyn.MatchingExp> inItems;

  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems)
  local
    Tpl.Text txt;
  
  case (txt, {} )
    then txt;  
  
  case (txt, v_it :: rest )
    local
      TplAbsyn.MatchingExp v_it;
      list<TplAbsyn.MatchingExp> rest;    
    equation
      txt = f_mmMatchingExp(txt, v_it);
      txt = Tpl.nextIter(txt);      
      txt = f_mmMatchFunBody_lm3(txt, rest);      
    then txt;
      
  end matchcontinue;
end f_mmMatchFunBody_lm3;

//<statements : mmExp(it, '=')\n>
public function f_mmMatchFunBody_lm4
  input Tpl.Text inTxt;
  input list<TplAbsyn.MMExp> inItems;

  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems)
  local
    Tpl.Text txt;
  
  case (txt, {} )
    then txt;  
  
  case (txt, v_it :: rest )
    local
      TplAbsyn.MMExp v_it;
      list<TplAbsyn.MMExp> rest;    
    equation
      txt = f_mmExp(txt, v_it, "=");
      txt = Tpl.nextIter(txt);      
      txt = f_mmMatchFunBody_lm4(txt, rest);      
    then txt;
      
  end matchcontinue;
end f_mmMatchFunBody_lm4;

//<match mf.outArgs ...
//<oas of (_,nm): nm ', '>
public function f_mmMatchFunBody_lm5
  input Tpl.Text inTxt;
  input TplAbsyn.TypedIdents inItems;

  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems)
  local
    Tpl.Text txt;
  
  case (txt, {} )
    then txt;  
  
  case (txt, (v_nm, _) :: rest )
    local
      TplAbsyn.Ident v_nm;
      TplAbsyn.TypedIdents rest;    
    equation
      txt = Tpl.writeTok(txt, Tpl.ST_STRING(v_nm));
      txt = Tpl.nextIter(txt);      
      txt = f_mmMatchFunBody_lm5(txt, rest);      
    then txt;
      
  end matchcontinue;
end f_mmMatchFunBody_lm5;


public function f_pathIdent
  input Tpl.Text inTxt;
  input TplAbsyn.PathIdent in_it;
  
  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, in_it)
  local
    Tpl.Text txt;
  
  case (txt, TplAbsyn.IDENT( ident = v_it_ident ) )    
    local
      TplAbsyn.Ident v_it_ident;
    equation
      txt = Tpl.writeStr(txt, v_it_ident);      
    then txt;
      
  case (txt, TplAbsyn.PATH_IDENT( ident = v_it_ident, path = v_it_path ) )    
    local
      TplAbsyn.Ident v_it_ident;
      TplAbsyn.PathIdent v_it_path;
    equation
      txt = Tpl.writeParseNL(txt, v_it_ident);
      txt = Tpl.writeStr(txt, ".");
      txt = f_pathIdent(txt, v_it_path);
    then txt;  
  end matchcontinue;
end f_pathIdent;


public function f_mmPublic
  input Tpl.Text inTxt;
  input Boolean in_isPublic;
  
  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, in_isPublic)
  local
    Tpl.Text txt;
  case (txt, true) 
    equation
      txt = Tpl.writeStr(txt, "public");
    then txt;
  case (txt, false) 
    equation
      txt = Tpl.writeStr(txt, "protected");
    then txt;
  end matchcontinue;
end f_mmPublic;


public function f_typedIdents
  input Tpl.Text intxt;
  input TplAbsyn.TypedIdents in_decls;
    
  output Tpl.Text outtxt;
algorithm
  outtxt := Tpl.pushIter(intxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
  outtxt := f_typedIdents_lm0(outtxt, in_decls); //decls of (t,n):
  outtxt := Tpl.popIter(outtxt);
end f_typedIdents;

public function f_typedIdents_lm0
  input Tpl.Text inTxt;
  input list<tuple<TplAbsyn.Ident, TplAbsyn.TypeSignature>> inItems;
  
  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems)
  local
    Tpl.Text txt;
  
  case (txt, {} )
    then txt;  
  
  case (txt, (v_id,v_ty) :: rest )
    local
      TplAbsyn.Ident v_id;
      TplAbsyn.TypeSignature v_ty;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeSignature>> rest;
    equation
      txt = f_typeSig(txt, v_ty);
      txt = Tpl.writeStr(txt, " ");
      txt = Tpl.writeParseNL(txt, v_id);
      txt = Tpl.writeStr(txt, ";");
      txt = Tpl.nextIter(txt);      
      txt = f_typedIdents_lm0(txt, rest);      
    then txt;
      
  end matchcontinue;
end f_typedIdents_lm0;


public function f_typedIdentsEx
  input Tpl.Text intxt;
  input TplAbsyn.TypedIdents in_decls;
  input String in_prfx;
  input String in_nmPrfx;
    
  output Tpl.Text outtxt;
algorithm
  outtxt := Tpl.pushIter(intxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
  outtxt := f_typedIdentsEx_lm0(outtxt, in_decls, in_prfx, in_nmPrfx); //decls of (id,ty): 
  outtxt := Tpl.popIter(outtxt);
end f_typedIdentsEx;

public function f_typedIdentsEx_lm0
  input Tpl.Text inTxt;
  input list<tuple<TplAbsyn.Ident, TplAbsyn.TypeSignature>> inItems;
  input String in_prfx;
  input String in_nmPrfx;
  
  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems, in_prfx, in_nmPrfx)
  local
    Tpl.Text txt;
  
  case (txt, {}, _, _ )
    then txt;  
  
  case (txt, (v_id,v_ty) :: rest, v_prfx,  v_nmPrfx)
    local
      TplAbsyn.Ident v_id;
      TplAbsyn.TypeSignature v_ty;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeSignature>> rest;
      String v_prfx;
      String v_nmPrfx;
  
    equation
      txt = Tpl.writeParseNL(txt, v_prfx);
      txt = Tpl.writeStr(txt, " ");
      txt = f_typeSig(txt, v_ty);
      txt = Tpl.writeStr(txt, " ");
      txt = Tpl.writeParseNL(txt, v_nmPrfx);
      txt = Tpl.writeParseNL(txt, v_id);
      txt = Tpl.writeStr(txt, ";");
      txt = Tpl.nextIter(txt);      
      txt = f_typedIdentsEx_lm0(txt, rest, v_prfx, v_nmPrfx);      
    then txt;
      
  end matchcontinue;
end f_typedIdentsEx_lm0;


public function f_typeSig
  input Tpl.Text inTxt;
  input TplAbsyn.TypeSignature in_it;
    
  output Tpl.Text outTxt;
algorithm
  outTxt := 
  matchcontinue(inTxt, in_it)
  local
    Tpl.Text txt;
  case (txt, 
        TplAbsyn.LIST_TYPE(
            ofType = v_it_ofType 
        )
       )    
    local
      TplAbsyn.TypeSignature v_it_ofType;
    equation
      txt = Tpl.writeStr(txt, "list<");
      txt = f_typeSig(txt, v_it_ofType);
      txt = Tpl.writeStr(txt, ">");      
    then txt;
  case (txt, 
        TplAbsyn.ARRAY_TYPE(
            ofType = v_it_ofType 
        )
       )    
    local
      TplAbsyn.TypeSignature v_it_ofType;
    equation
      txt = f_typeSig(txt, v_it_ofType);
      txt = Tpl.writeStr(txt, "[:]");      
    then txt;
  case (txt, 
        TplAbsyn.OPTION_TYPE(
            ofType = v_it_ofType 
        )
       )    
    local
      TplAbsyn.TypeSignature v_it_ofType;
    equation
      txt = Tpl.writeStr(txt, "Option<");
      txt = f_typeSig(txt, v_it_ofType);
      txt = Tpl.writeStr(txt, ">");      
    then txt;
  case (txt, 
        TplAbsyn.TUPLE_TYPE(
            ofTypes = v_it_ofTypes 
        )
       )    
    local
      list<TplAbsyn.TypeSignature> v_it_ofTypes;
    equation
      txt = Tpl.writeStr(txt, "tuple<");
      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
      txt = f_typeSig_lm0(txt, v_it_ofTypes);
      txt = Tpl.popIter(txt);
      txt = Tpl.writeStr(txt, ">");      
    then txt;
  case (txt, 
        TplAbsyn.NAMED_TYPE(
            name = v_it_name 
        )
       )    
    local
      TplAbsyn.PathIdent v_it_name;
    equation
      txt = f_pathIdent(txt, v_it_name);
    then txt;
  
  case (txt, TplAbsyn.STRING_TYPE() )    
    equation
      txt = Tpl.writeStr(txt, "String");
    then txt;
  
  case (txt, TplAbsyn.TEXT_TYPE() )    
    equation
      txt = Tpl.writeStr(txt, "Tpl.Text");
    then txt;
      
  case (txt, TplAbsyn.STRING_TOKEN_TYPE() )    
    equation
      txt = Tpl.writeStr(txt, "Tpl.StringToken");
    then txt;
      
  case (txt, TplAbsyn.INTEGER_TYPE() )    
    equation
      txt = Tpl.writeStr(txt, "Integer");
    then txt;
      
  case (txt, TplAbsyn.REAL_TYPE() )    
    equation
      txt = Tpl.writeStr(txt, "Real");
    then txt;
      
  case (txt, TplAbsyn.BOOLEAN_TYPE() )    
    equation
      txt = Tpl.writeStr(txt, "Boolean");
    then txt;
      
  case (txt, 
        TplAbsyn.UNRESOLVED_TYPE(
            reason = v_reason 
        )
       )    
    local
      String v_reason;
    equation
      txt = Tpl.writeStr(txt, "#type? ");
      txt = Tpl.writeStr(txt, v_reason);
      txt = Tpl.writeStr(txt, " ?#");      
    then txt;
  
  
  case (txt,_) // no fail behaviour ... when some the union has in fact more tags 
    then txt;   
  end matchcontinue;
end f_typeSig;

//$ofTypes : typeSig(ofType)', '$
public function f_typeSig_lm0
  input Tpl.Text inTxt;
  input list<TplAbsyn.TypeSignature> inItems;

  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems)
  local
    Tpl.Text txt;
  
  case (txt, {} )
    then txt;  
  
  case (txt, v_it :: rest )
    local
      TplAbsyn.TypeSignature v_it;
      list<TplAbsyn.TypeSignature> rest;    
    equation
      txt = f_typeSig(txt, v_it);
      txt = Tpl.nextIter(txt);      
      txt = f_typeSig_lm0(txt, rest);      
    then txt;
      
  end matchcontinue;
end f_typeSig_lm0;



public function f_stringTokenConstant
  input Tpl.Text inTxt;
  input TplAbsyn.StringToken in_it;
    
  output Tpl.Text outTxt;
algorithm
  outTxt := 
  matchcontinue(inTxt, in_it)
  local
    Tpl.Text txt;
  case (txt, Tpl.ST_NEW_LINE() )    
    equation
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("Tpl.ST_NEW_LINE()"));
    then txt;
  
  case (txt, Tpl.ST_STRING( value = v_value ) )    
    local
      String v_value;
    equation
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("Tpl.ST_STRING(\""));
      txt = f_escapeStringConst(txt, stringListStringChar(v_value), true);
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\")"));
    then txt;
  
  case (txt, Tpl.ST_LINE( line = v_line ) )    
    local
      String v_line;
    equation
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("Tpl.ST_LINE(\""));
      txt = f_escapeStringConst(txt, stringListStringChar(v_line), true);
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\")"));
    then txt;
  
  case (txt, Tpl.ST_STRING_LIST( strList = v_strList, lastHasNewLine = v_lastHasNewLine ) )    
    local
      list<String> v_strList;
      Boolean v_lastHasNewLine;
    equation
      txt = Tpl.writeTok(txt, Tpl.ST_LINE("Tpl.ST_STRING_LIST({\n"));
      txt = Tpl.pushBlock(txt,Tpl.BT_INDENT(4));            
      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
      txt = f_stringTokenConstant_lm0(txt, v_strList); //<strList : <<"<escapeStringConst(it,true)>">> ',\n' ;anchor>
      txt = Tpl.popIter(txt);
      txt = Tpl.popBlock(txt);
      txt = Tpl.softNewLine(txt);      
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("}, "));
      txt = Tpl.writeStr(txt, Tpl.booleanString(v_lastHasNewLine));
      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
    then txt;
  
  case (txt, _)    
    then txt;

  end matchcontinue;
end f_stringTokenConstant;

//<strList : <<"<escapeStringConst(it,true)>">> ',\n' ;anchor>
public function f_stringTokenConstant_lm0
  input Tpl.Text inTxt;
  input list<String> inItems;

  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems)
  local
    Tpl.Text txt;
  
  case (txt, {} )
    then txt;  
  
  case (txt, v_it :: rest )
    local
      String v_it;
      list<String> rest;    
    equation
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      txt = f_escapeStringConst(txt, stringListStringChar(v_it), true);
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      txt = Tpl.nextIter(txt);      
      txt = f_stringTokenConstant_lm0(txt, rest);      
    then txt;
      
  end matchcontinue;
end f_stringTokenConstant_lm0;

/*
public function f_stringLiteralConstant
  input Tpl.Text inTxt;
  input TplAbsyn.StringToken in_it;
    
  output Tpl.Text outTxt;
algorithm
  outTxt := 
  matchcontinue(inTxt, in_it)
  local
    Tpl.Text txt;
  case (txt, Tpl.ST_NEW_LINE() )    
    equation
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\\n"));
    then txt;
  
  case (txt, Tpl.ST_STRING( value = _it_value ) )    
    local
      String _value;
    equation
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      txt = f_escapeStringConst(txt, _value, false);
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
    then txt;
  
  case (txt, Tpl.ST_LINE( line = _line ) )    
    local
      String _line;
    equation
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      txt = f_escapeStringConst(txt, _line, true);
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
    then txt;
  
  case (txt, Tpl.ST_STRING_LIST( strList = _strList ) )    
    local
      list<String> _strList;
    equation
      txt = Tpl.writeTok(txt, Tpl.ST_LINE("\""));
      txt = Tpl.pushBlock(txt,Tpl.BT_ABS_INDENT(0));            
      //txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
      txt = f_stringLiteralConstant_lm0(txt, _strList); //<strList : escapeStringConst(it,false); noindent>
      //txt = Tpl.popIter(txt);
      txt = Tpl.popBlock(txt);
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
    then txt;
  
  case (txt, _)    
    then txt;

  end matchcontinue;
end f_stringLiteralConstant;

//<strList : escapeStringConst(it,false); noindent>
public function _stringLiteralConstant_lm0
  input Tpl.Text inTxt;
  input list<String> inItems;

  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems)
  local
    Tpl.Text txt;
  
  case (txt, {} )
    then txt;  
  
  case (txt, _it :: rest )
    local
      String _it;
      list<String> rest;    
    equation
      txt = _escapeStringConst(txt, stringListStringChar(_it), false);
      //txt = Tpl.nextIter(txt);      
      txt = _stringTokenConstant_lm0(txt, rest);      
    then txt;
      
  end matchcontinue;
end _stringLiteralConstant_lm0;
*/


public function f_escapeStringConst
  input Tpl.Text txt;
  input list<String> inItems;
  input Boolean in_escapeNewLine;
    
  output Tpl.Text out_txt;
algorithm
  (out_txt) := Tpl.pushBlock(txt, Tpl.BT_ABS_INDENT(0));
  out_txt := f_escapeStringConst_(out_txt, inItems, in_escapeNewLine);
  (out_txt) := Tpl.popBlock(out_txt);
end f_escapeStringConst;


public function f_escapeStringConst_
  input Tpl.Text inTxt;
  input list<String> inItems;
  input Boolean in_escapeNewLine;
    
  output Tpl.Text outTxt;
algorithm
  outTxt := matchcontinue(inTxt, inItems, in_escapeNewLine)
  local
    Tpl.Text txt;
  
  case (txt, {}, _ )
    then txt;  
  
  case (txt, v_it :: rest, v_escapeNewLine )
    local
      String v_it;
      list<String> rest; 
      Boolean v_escapeNewLine;   
    equation
      txt = f_escapeStringConst_mf0(txt, v_it, v_escapeNewLine);
      txt = f_escapeStringConst_(txt, rest, v_escapeNewLine);      
    then txt;
  end matchcontinue;
end f_escapeStringConst_;

protected function f_escapeStringConst_mf0
  input Tpl.Text inTxt;
  input String in_it;
  input Boolean in_escapeNewLine;
    
  output Tpl.Text outTxt;
algorithm
  outTxt := matchcontinue(inTxt, in_it, in_escapeNewLine)
  local
    Tpl.Text txt;    
  case (txt, "\\",_  )    
    equation
      txt = Tpl.writeStr(txt, "\\\\");
    then txt;
  case (txt, 
        "\'",_
       )    
    equation
      txt = Tpl.writeStr(txt, "\\\'");
    then txt;
  case (txt, 
        "\"",_
       )    
    equation
      txt = Tpl.writeStr(txt, "\\\"");
    then txt;
  /*
  //TODO: Error in the .srz
  case (txt, 
        "\a",_ 
       )    
    equation
      txt = Tpl.writeStr(txt, "\\a");
    then txt;
  case (txt, 
        "\b",_
       )    
    equation
      txt = Tpl.writeStr(txt, "\\b");
    then txt;
  case (txt, 
        "\f",_
       )    
    equation
      txt = Tpl.writeStr(txt, "\\f");
    then txt;
  case (txt, 
        "\v",_
       )    
    equation
      txt = Tpl.writeStr(txt, "\\v");
    then txt;
 */
  case (txt, 
        "\n",v_escapeNewLine
       )    
    local
      Boolean v_escapeNewLine;
      String nl;
    equation
      nl = Util.if_(v_escapeNewLine, "\\n", "\n");
      txt = Tpl.writeStr(txt, nl);
    then txt;
  /*
  //TODO: Error - should be \r
  case (txt, 
        "\r",_ 
       )    
    equation
      txt = Tpl.writeStr(txt, "\\r");
    then txt;
  */
  case (txt, 
        "\t",_
       )    
    equation
      txt = Tpl.writeStr(txt, "\\t");
    then txt;
  
  case (txt, 
        v_it,_
       )
    local
      String v_it;    
    equation
      txt = Tpl.writeStr(txt, v_it);
    then txt;
  end matchcontinue;
end f_escapeStringConst_mf0;


public function f_mmExp
  input Tpl.Text inTxt;
  input TplAbsyn.MMExp in_it;
  input String in_assignStr;
    
  output Tpl.Text outTxt;
algorithm
  outTxt := 
  matchcontinue(inTxt, in_it, in_assignStr)
  local
    Tpl.Text txt;
    String v_assignStr;
  
  case (txt, 
        TplAbsyn.MM_ASSIGN(
            lhsArgs = v_it_lhsArgs,
            rhs = v_it_rhs
        ),
        v_assignStr
       )    
    local
      list<String> v_it_lhsArgs;
      TplAbsyn.MMExp v_it_rhs;
    equation
      txt = Tpl.writeStr(txt, "(");
      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
      txt = f_mmExp_lm0(txt, v_it_lhsArgs); //<args', '>
      txt = Tpl.popIter(txt);
      txt = Tpl.writeStr(txt, ")");
      txt = Tpl.writeStr(txt, " ");
      txt = Tpl.writeParseNL(txt, v_assignStr);
      txt = Tpl.writeStr(txt, " ");
      txt = f_mmExp(txt, v_it_rhs, v_assignStr);      
      txt = Tpl.writeStr(txt, ";");
    then txt;
  
  case (txt, 
        TplAbsyn.MM_FN_CALL(
            fnName = v_it_fnName,
            args = v_it_args
        ),
        v_assignStr
       )    
    local
      TplAbsyn.PathIdent v_it_fnName;
      list<TplAbsyn.MMExp> v_it_args;
    equation
      txt = f_pathIdent(txt, v_it_fnName);      
      txt = Tpl.writeStr(txt, "(");
      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
      txt = f_mmExp_lm1(txt, v_it_args, v_assignStr); //<args : mmExp(it,assignStr)', '>
      txt = Tpl.popIter(txt);
      txt = Tpl.writeStr(txt, ")");
    then txt;
  
  
  case (txt, 
        TplAbsyn.MM_IDENT(
            ident = v_it_ident
        ), _
       )    
    local
      TplAbsyn.PathIdent v_it_ident;
    equation
      txt = f_pathIdent(txt, v_it_ident);      
    then txt;
  
  case (txt, 
        TplAbsyn.MM_STR_TOKEN(
            value = v_value
        ), _
       )    
    local
      Tpl.StringToken v_value;
    equation
      txt = f_stringTokenConstant(txt, v_value);      
    then txt;
  
  
  case (txt, 
        TplAbsyn.MM_STRING(
            value = v_value
        ), _
       )    
    local
      String v_value;
    equation
      (txt) = Tpl.pushBlock(txt, Tpl.BT_ABS_INDENT(0));
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      txt = f_escapeStringConst(txt, stringListStringChar(v_value), true);
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      (txt) = Tpl.popBlock(txt);
    then txt;
  
  case (txt, 
        TplAbsyn.MM_LITERAL(
            value = v_value
        ), _
       )    
    local
      String v_value;
    equation
      txt = Tpl.writeStr(txt,v_value);      
    then txt;
      
  case (txt,_, _)  
    then txt;   
  
  end matchcontinue;
end f_mmExp;

//<args', '>
public function f_mmExp_lm0
  input Tpl.Text inTxt;
  input list<String> inItems;

  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems)
  local
    Tpl.Text txt;
  
  case (txt, {} )
    then txt;  
  
  case (txt, v_it :: rest )
    local
      String v_it;
      list<String> rest;    
    equation
      txt = Tpl.writeStr(txt, v_it);
      txt = Tpl.nextIter(txt);      
      txt = f_mmExp_lm0(txt, rest);      
    then txt;
      
  end matchcontinue;
end f_mmExp_lm0;


//<args : mmExp(it,assignStr)', '>
public function f_mmExp_lm1
  input Tpl.Text inTxt;
  input list<TplAbsyn.MMExp> inItems;
  input String in_assignStr;

  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems, in_assignStr)
  local
    Tpl.Text txt;
  
  case (txt, {}, _ )
    then txt;  
  
  case (txt, v_it :: rest, v_assignStr )
    local
      TplAbsyn.MMExp v_it;
      list<TplAbsyn.MMExp> rest;
      String v_assignStr;    
    equation
      txt = f_mmExp(txt, v_it, v_assignStr);
      txt = Tpl.nextIter(txt);      
      txt = f_mmExp_lm1(txt, rest, v_assignStr);      
    then txt;
      
  end matchcontinue;
end f_mmExp_lm1;


public function f_mmMatchingExp
  input Tpl.Text inTxt;
  input TplAbsyn.MatchingExp in_it;
    
  output Tpl.Text outTxt;
algorithm
  outTxt := 
  matchcontinue(inTxt, in_it)
  local
    Tpl.Text txt;
  
  case (txt, 
        TplAbsyn.BIND_AS_MATCH(
            bindIdent = v_bindIdent,
            matchingExp = v_matchingExp            
        )
       )    
    local
      String v_bindIdent;
      TplAbsyn.MatchingExp v_matchingExp;
    equation
      txt = Tpl.writeParseNL(txt, v_bindIdent);
      txt = Tpl.writeStr(txt, " as ");
      txt = f_mmMatchingExp(txt, v_matchingExp);
    then txt;
  
  case (txt, 
        TplAbsyn.BIND_MATCH(
            bindIdent = v_it_bindIdent            
        )
       )    
    local
      String v_it_bindIdent;
    equation
      txt = Tpl.writeParseNL(txt, v_it_bindIdent);
    then txt;
  
  case (txt, 
        TplAbsyn.RECORD_MATCH(
            tagName = v_it_tagName,
            fieldMatchings = v_it_fieldMatchings
        )
       )    
    local
      Option<TplAbsyn.Ident> v_it_bindIdent;
      TplAbsyn.PathIdent v_it_tagName;
      list<tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp>> v_it_fieldMatchings;
    equation
      txt = f_pathIdent(txt, v_it_tagName);      
      txt = Tpl.writeStr(txt, "(");
      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
      txt = f_mmMatchingExp_lm0(txt, v_it_fieldMatchings); //<fieldMatchings of (field, mexp) :
      txt = Tpl.popIter(txt);
      txt = Tpl.writeStr(txt, ")");      
    then txt;
  
  case (txt,  TplAbsyn.SOME_MATCH( value = v_it_value ))
    local
      TplAbsyn.MatchingExp v_it_value;
    equation
      txt = Tpl.writeStr(txt, "SOME(");
      txt = f_mmMatchingExp(txt, v_it_value);
      txt = Tpl.writeStr(txt, ")");
    then txt;
  
  case (txt, 
        TplAbsyn.NONE_MATCH()
       )    
    equation
      txt = Tpl.writeStr(txt, "NONE");
    then txt;
  
  case (txt, 
        TplAbsyn.TUPLE_MATCH(
            tupleArgs = v_it_tupleArgs            
        )
       )    
    local
      list<TplAbsyn.MatchingExp> v_it_tupleArgs;
    equation
      txt = Tpl.writeStr(txt, "(");
      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
      txt = f_mmMatchingExp_lm1(txt, v_it_tupleArgs); //<tupleArgs : mmMatchingExp()', '>
      txt = Tpl.popIter(txt);
      txt = Tpl.writeStr(txt, ")");
    then txt;
  
  case (txt, 
        TplAbsyn.LIST_MATCH( listElts = v_listElts  ) )    
    local
      list<TplAbsyn.MatchingExp> v_listElts;
    equation
      txt = Tpl.writeStr(txt, "{");
      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE() ));
      txt = f_mmMatchingExp_lm1(txt, v_listElts); //<listElts : mmMatchingExp()', '>
      txt = Tpl.popIter(txt);
      txt = Tpl.writeStr(txt, "}");
    then txt;
  
  case (txt, 
        TplAbsyn.LIST_CONS_MATCH( head = v_head, rest = v_rest  ) )    
    local
      TplAbsyn.MatchingExp v_head;
      TplAbsyn.MatchingExp v_rest;
    equation
      txt = f_mmMatchingExp(txt, v_head);
      txt = Tpl.writeStr(txt, " :: ");
      txt = f_mmMatchingExp(txt, v_rest);
    then txt;
  
  case (txt, 
        TplAbsyn.STRING_MATCH( value = v_value )
       )    
    local
      String v_value;
    equation
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      txt = f_escapeStringConst(txt, stringListStringChar(v_value), true);
      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
    then txt;
  
  case (txt, 
        TplAbsyn.LITERAL_MATCH( value = v_it_value )
       )    
    local
      String v_it_value;
    equation
      txt = Tpl.writeStr(txt, v_it_value);
    then txt;
  
  case (txt, TplAbsyn.REST_MATCH() )    
    equation
      txt = Tpl.writeStr(txt, "_");
    then txt;
  
  case (txt,_)  
    then txt;
       
  end matchcontinue;
end f_mmMatchingExp;


//<fieldMatchings of (field, mexp) :
public function f_mmMatchingExp_lm0
  input Tpl.Text inTxt;
  input list<tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp>> inItems;

  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems)
  local
    Tpl.Text txt;
  
  case (txt, {} )
    then txt;  
  
  case (txt, (v_field, v_mexp) :: rest )
    local
      TplAbsyn.Ident v_field;
      TplAbsyn.MatchingExp v_mexp;
      list<tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp>> rest;    
    equation
      txt = Tpl.writeStr(txt, v_field);
      txt = Tpl.writeStr(txt, " = ");
      txt = f_mmMatchingExp(txt, v_mexp);
      txt = Tpl.nextIter(txt);      
      txt = f_mmMatchingExp_lm0(txt, rest);      
    then txt;
      
  end matchcontinue;
end f_mmMatchingExp_lm0;

//<tupleArgs : mmMatchingExp()', '>
//<listElts : mmMatchingExp()', '>
public function f_mmMatchingExp_lm1
  input Tpl.Text inTxt;
  input list<TplAbsyn.MatchingExp> inItems;

  output Tpl.Text outTxt;    
algorithm
  outTxt := 
  matchcontinue(inTxt, inItems)
  local
    Tpl.Text txt;
  
  case (txt, {} )
    then txt;  
  
  case (txt, v_it :: rest )
    local
      TplAbsyn.MatchingExp v_it;
      list<TplAbsyn.MatchingExp> rest;    
    equation
      txt = f_mmMatchingExp(txt, v_it);
      txt = Tpl.nextIter(txt);      
      txt = f_mmMatchingExp_lm1(txt, rest);      
    then txt;
      
  end matchcontinue;
end f_mmMatchingExp_lm1;


end TplCodegen;