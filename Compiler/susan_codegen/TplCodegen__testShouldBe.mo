package TplCodegen

protected constant Tpl.Text emptyTxt = Tpl.MEM_TEXT({}, {});

public import Tpl;

public import TplAbsyn;

protected function lm_3
  input Tpl.Text in_txt;
  input list<TplAbsyn.MMDeclaration> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      local
        list<TplAbsyn.MMDeclaration> rest;
        TplAbsyn.MMDeclaration i_it;
      equation
        txt = mmDeclaration(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_3(txt, rest);
      then txt;
  end matchcontinue;
end lm_3;

public function mmPackage
  input Tpl.Text in_txt;
  input TplAbsyn.MMPackage in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           TplAbsyn.MM_PACKAGE(name = i_name, mmDeclarations = i_mmDeclarations) )
      local
        list<TplAbsyn.MMDeclaration> i_mmDeclarations;
        TplAbsyn.PathIdent i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("package "));
        txt = pathIdent(txt, i_name);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "protected constant Tpl.Text emptyTxt = Tpl.MEM_TEXT({}, {});\n",
                                    "\n",
                                    "public import Tpl;\n",
                                    "\n"
                                }, true));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_3(txt, i_mmDeclarations);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "end "
                                }, false));
        txt = pathIdent(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end mmPackage;

protected function fun_5
  input Tpl.Text in_txt;
  input TplAbsyn.TypedIdents in_i_mf_locals;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_mf_locals)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_mf_locals )
      local
        TplAbsyn.TypedIdents i_mf_locals;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("protected\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = typedIdents(txt, i_mf_locals);
        txt = Tpl.popBlock(txt);
      then txt;
  end matchcontinue;
end fun_5;

protected function lm_6
  input Tpl.Text in_txt;
  input list<TplAbsyn.MMExp> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      local
        list<TplAbsyn.MMExp> rest;
        TplAbsyn.MMExp i_it;
      equation
        txt = mmExp(txt, i_it, ":=");
        txt = Tpl.nextIter(txt);
        txt = lm_6(txt, rest);
      then txt;
  end matchcontinue;
end lm_6;

protected function fun_7
  input Tpl.Text in_txt;
  input list<TplAbsyn.MMExp> in_i_statements;
  input TplAbsyn.TypedIdents in_i_mf_locals;
  input TplAbsyn.TypedIdents in_i_mf_outArgs;
  input TplAbsyn.TypedIdents in_i_mf_inArgs;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_statements, in_i_mf_locals, in_i_mf_outArgs, in_i_mf_inArgs)
    local
      Tpl.Text txt;
      TplAbsyn.TypedIdents i_mf_locals;
      TplAbsyn.TypedIdents i_mf_outArgs;
      TplAbsyn.TypedIdents i_mf_inArgs;

    case ( txt,
           {(i_c as TplAbsyn.MM_MATCH(matchCases = i_c_matchCases))},
           i_mf_locals,
           i_mf_outArgs,
           i_mf_inArgs )
      local
        list<TplAbsyn.MMMatchCase> i_c_matchCases;
        TplAbsyn.MMExp i_c;
      equation
        txt = mmMatchFunBody(txt, i_mf_inArgs, i_mf_outArgs, i_mf_locals, i_c_matchCases);
      then txt;

    case ( txt,
           i_sts,
           i_mf_locals,
           i_mf_outArgs,
           i_mf_inArgs )
      local
        list<TplAbsyn.MMExp> i_sts;
      equation
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = typedIdentsEx(txt, i_mf_inArgs, "input", "");
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = typedIdentsEx(txt, i_mf_outArgs, "output", "out_");
        txt = Tpl.softNewLine(txt);
        txt = fun_5(txt, i_mf_locals);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("algorithm\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_6(txt, i_sts);
        txt = Tpl.popIter(txt);
        txt = Tpl.popBlock(txt);
      then txt;
  end matchcontinue;
end fun_7;

public function mmDeclaration
  input Tpl.Text in_txt;
  input TplAbsyn.MMDeclaration in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           TplAbsyn.MM_IMPORT(packageName = TplAbsyn.IDENT(ident = "Tpl")) )
      then txt;

    case ( txt,
           TplAbsyn.MM_IMPORT(packageName = TplAbsyn.IDENT(ident = "builtin")) )
      then txt;

    case ( txt,
           TplAbsyn.MM_IMPORT(isPublic = i_isPublic, packageName = i_packageName) )
      local
        TplAbsyn.PathIdent i_packageName;
        Boolean i_isPublic;
      equation
        txt = mmPublic(txt, i_isPublic);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" import "));
        txt = pathIdent(txt, i_packageName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;

    case ( txt,
           TplAbsyn.MM_STR_TOKEN_DECL(isPublic = i_isPublic, name = i_name, value = i_value) )
      local
        TplAbsyn.StringToken i_value;
        TplAbsyn.Ident i_name;
        Boolean i_isPublic;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = mmPublic(txt, i_isPublic);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" constant Tpl.StringToken "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = stringTokenConstant(txt, i_value);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;

    case ( txt,
           TplAbsyn.MM_LITERAL_DECL(isPublic = i_isPublic, litType = i_litType, name = i_name, value = i_value) )
      local
        String i_value;
        TplAbsyn.Ident i_name;
        TplAbsyn.TypeSignature i_litType;
        Boolean i_isPublic;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = mmPublic(txt, i_isPublic);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" constant "));
        txt = typeSig(txt, i_litType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeStr(txt, i_value);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;

    case ( txt,
           (i_mf as TplAbsyn.MM_FUN(isPublic = i_isPublic, name = i_name, statements = i_statements, inArgs = i_mf_inArgs, outArgs = i_mf_outArgs, locals = i_mf_locals)) )
      local
        TplAbsyn.TypedIdents i_mf_locals;
        TplAbsyn.TypedIdents i_mf_outArgs;
        TplAbsyn.TypedIdents i_mf_inArgs;
        list<TplAbsyn.MMExp> i_statements;
        TplAbsyn.Ident i_name;
        Boolean i_isPublic;
        TplAbsyn.MMDeclaration i_mf;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = mmPublic(txt, i_isPublic);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" function "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.softNewLine(txt);
        txt = fun_7(txt, i_statements, i_mf_locals, i_mf_outArgs, i_mf_inArgs);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("end "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end mmDeclaration;

protected function lm_9
  input Tpl.Text in_txt;
  input TplAbsyn.TypedIdents in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_nm, _) :: rest )
      local
        TplAbsyn.TypedIdents rest;
        TplAbsyn.Ident i_nm;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out_"));
        txt = Tpl.writeStr(txt, i_nm);
        txt = Tpl.nextIter(txt);
        txt = lm_9(txt, rest);
      then txt;
  end matchcontinue;
end lm_9;

protected function fun_10
  input Tpl.Text in_txt;
  input TplAbsyn.TypedIdents in_i_outArgs;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outArgs)
    local
      Tpl.Text txt;

    case ( txt,
           {(i_nm, _)} )
      local
        TplAbsyn.Ident i_nm;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out_"));
        txt = Tpl.writeStr(txt, i_nm);
      then txt;

    case ( txt,
           i_outArgs )
      local
        TplAbsyn.TypedIdents i_outArgs;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_9(txt, i_outArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;
  end matchcontinue;
end fun_10;

protected function lm_11
  input Tpl.Text in_txt;
  input TplAbsyn.TypedIdents in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_nm, _) :: rest )
      local
        TplAbsyn.TypedIdents rest;
        TplAbsyn.Ident i_nm;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("in_"));
        txt = Tpl.writeStr(txt, i_nm);
        txt = Tpl.nextIter(txt);
        txt = lm_11(txt, rest);
      then txt;
  end matchcontinue;
end lm_11;

protected function lm_12
  input Tpl.Text in_txt;
  input list<TplAbsyn.MatchingExp> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      local
        list<TplAbsyn.MatchingExp> rest;
        TplAbsyn.MatchingExp i_it;
      equation
        txt = mmMatchingExp(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_12(txt, rest);
      then txt;
  end matchcontinue;
end lm_12;

protected function fun_13
  input Tpl.Text in_txt;
  input TplAbsyn.TypedIdents in_i_locals;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_locals)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_locals )
      local
        TplAbsyn.TypedIdents i_locals;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("      local\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(8));
        txt = typedIdents(txt, i_locals);
        txt = Tpl.popBlock(txt);
      then txt;
  end matchcontinue;
end fun_13;

protected function lm_14
  input Tpl.Text in_txt;
  input list<TplAbsyn.MMExp> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      local
        list<TplAbsyn.MMExp> rest;
        TplAbsyn.MMExp i_it;
      equation
        txt = mmExp(txt, i_it, "=");
        txt = Tpl.nextIter(txt);
        txt = lm_14(txt, rest);
      then txt;
  end matchcontinue;
end lm_14;

protected function fun_15
  input Tpl.Text in_txt;
  input list<TplAbsyn.MMExp> in_i_statements;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_statements)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_statements )
      local
        list<TplAbsyn.MMExp> i_statements;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("      equation\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(8));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_14(txt, i_statements);
        txt = Tpl.popIter(txt);
        txt = Tpl.popBlock(txt);
      then txt;
  end matchcontinue;
end fun_15;

protected function lm_16
  input Tpl.Text in_txt;
  input TplAbsyn.TypedIdents in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_nm, _) :: rest )
      local
        TplAbsyn.TypedIdents rest;
        TplAbsyn.Ident i_nm;
      equation
        txt = Tpl.writeStr(txt, i_nm);
        txt = Tpl.nextIter(txt);
        txt = lm_16(txt, rest);
      then txt;
  end matchcontinue;
end lm_16;

protected function fun_17
  input Tpl.Text in_txt;
  input TplAbsyn.TypedIdents in_i_outArgs;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outArgs)
    local
      Tpl.Text txt;

    case ( txt,
           {(i_nm, _)} )
      local
        TplAbsyn.Ident i_nm;
      equation
        txt = Tpl.writeStr(txt, i_nm);
      then txt;

    case ( txt,
           i_oas )
      local
        TplAbsyn.TypedIdents i_oas;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_16(txt, i_oas);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;
  end matchcontinue;
end fun_17;

protected function lm_18
  input Tpl.Text in_txt;
  input list<TplAbsyn.MMMatchCase> in_items;
  input TplAbsyn.TypedIdents in_i_outArgs;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_i_outArgs)
    local
      Tpl.Text txt;
      TplAbsyn.TypedIdents i_outArgs;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           (i_mexps, i_locals, i_statements) :: rest,
           i_outArgs )
      local
        list<TplAbsyn.MMMatchCase> rest;
        list<TplAbsyn.MMExp> i_statements;
        TplAbsyn.TypedIdents i_locals;
        list<TplAbsyn.MatchingExp> i_mexps;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(4));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("case ( "));
        txt = Tpl.pushBlock(txt, Tpl.BT_ANCHOR(0));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_12(txt, i_mexps);
        txt = Tpl.popIter(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" )\n"));
        txt = Tpl.popBlock(txt);
        txt = fun_13(txt, i_locals);
        txt = Tpl.softNewLine(txt);
        txt = fun_15(txt, i_statements);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(6));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("then "));
        txt = fun_17(txt, i_outArgs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.nextIter(txt);
        txt = lm_18(txt, rest, i_outArgs);
      then txt;
  end matchcontinue;
end lm_18;

public function mmMatchFunBody
  input Tpl.Text txt;
  input TplAbsyn.TypedIdents i_inArgs;
  input TplAbsyn.TypedIdents i_outArgs;
  input TplAbsyn.TypedIdents i_locals;
  input list<TplAbsyn.MMMatchCase> i_matchCases;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
  out_txt := typedIdentsEx(out_txt, i_inArgs, "input", "in_");
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
  out_txt := typedIdentsEx(out_txt, i_outArgs, "output", "out_");
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("algorithm\n"));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := fun_10(out_txt, i_outArgs);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       " :=\n",
                                       "matchcontinue("
                                   }, false));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_11(out_txt, i_inArgs);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       ")\n",
                                       "  local\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(4));
  out_txt := typedIdents(out_txt, i_locals);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_18(out_txt, i_matchCases, i_outArgs);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("  end matchcontinue;"));
end mmMatchFunBody;

public function pathIdent
  input Tpl.Text in_txt;
  input TplAbsyn.PathIdent in_i_path;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_path)
    local
      Tpl.Text txt;

    case ( txt,
           TplAbsyn.IDENT(ident = i_ident) )
      local
        TplAbsyn.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
      then txt;

    case ( txt,
           TplAbsyn.PATH_IDENT(ident = i_ident, path = i_path) )
      local
        TplAbsyn.PathIdent i_path;
        TplAbsyn.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = pathIdent(txt, i_path);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end pathIdent;

public function mmPublic
  input Tpl.Text in_txt;
  input Boolean in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           true )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("public"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("protected"));
      then txt;
  end matchcontinue;
end mmPublic;

protected function lm_22
  input Tpl.Text in_txt;
  input TplAbsyn.TypedIdents in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_id, i_ts) :: rest )
      local
        TplAbsyn.TypedIdents rest;
        TplAbsyn.TypeSignature i_ts;
        TplAbsyn.Ident i_id;
      equation
        txt = typeSig(txt, i_ts);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeStr(txt, i_id);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_22(txt, rest);
      then txt;
  end matchcontinue;
end lm_22;

public function typedIdents
  input Tpl.Text txt;
  input TplAbsyn.TypedIdents i_decls;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_22(out_txt, i_decls);
  out_txt := Tpl.popIter(out_txt);
end typedIdents;

protected function lm_24
  input Tpl.Text in_txt;
  input TplAbsyn.TypedIdents in_items;
  input String in_i_idPrfx;
  input String in_i_typePrfx;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_i_idPrfx, in_i_typePrfx)
    local
      Tpl.Text txt;
      String i_idPrfx;
      String i_typePrfx;

    case ( txt,
           {},
           _,
           _ )
      then txt;

    case ( txt,
           (i_id, i_ty) :: rest,
           i_idPrfx,
           i_typePrfx )
      local
        TplAbsyn.TypedIdents rest;
        TplAbsyn.TypeSignature i_ty;
        TplAbsyn.Ident i_id;
      equation
        txt = Tpl.writeStr(txt, i_typePrfx);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = typeSig(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeStr(txt, i_idPrfx);
        txt = Tpl.writeStr(txt, i_id);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_24(txt, rest, i_idPrfx, i_typePrfx);
      then txt;
  end matchcontinue;
end lm_24;

public function typedIdentsEx
  input Tpl.Text txt;
  input TplAbsyn.TypedIdents i_decls;
  input String i_typePrfx;
  input String i_idPrfx;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_24(out_txt, i_decls, i_idPrfx, i_typePrfx);
  out_txt := Tpl.popIter(out_txt);
end typedIdentsEx;

protected function lm_26
  input Tpl.Text in_txt;
  input list<TplAbsyn.TypeSignature> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      local
        list<TplAbsyn.TypeSignature> rest;
        TplAbsyn.TypeSignature i_it;
      equation
        txt = typeSig(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_26(txt, rest);
      then txt;
  end matchcontinue;
end lm_26;

public function typeSig
  input Tpl.Text in_txt;
  input TplAbsyn.TypeSignature in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           TplAbsyn.LIST_TYPE(ofType = i_ofType) )
      local
        TplAbsyn.TypeSignature i_ofType;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("list<"));
        txt = typeSig(txt, i_ofType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(">"));
      then txt;

    case ( txt,
           TplAbsyn.ARRAY_TYPE(ofType = i_ofType) )
      local
        TplAbsyn.TypeSignature i_ofType;
      equation
        txt = typeSig(txt, i_ofType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("[:]"));
      then txt;

    case ( txt,
           TplAbsyn.OPTION_TYPE(ofType = i_ofType) )
      local
        TplAbsyn.TypeSignature i_ofType;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Option<"));
        txt = typeSig(txt, i_ofType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(">"));
      then txt;

    case ( txt,
           TplAbsyn.TUPLE_TYPE(ofTypes = i_ofTypes) )
      local
        list<TplAbsyn.TypeSignature> i_ofTypes;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("tuple<"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_26(txt, i_ofTypes);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(">"));
      then txt;

    case ( txt,
           TplAbsyn.NAMED_TYPE(name = i_name) )
      local
        TplAbsyn.PathIdent i_name;
      equation
        txt = pathIdent(txt, i_name);
      then txt;

    case ( txt,
           TplAbsyn.STRING_TYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("String"));
      then txt;

    case ( txt,
           TplAbsyn.TEXT_TYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Tpl.Text"));
      then txt;

    case ( txt,
           TplAbsyn.STRING_TOKEN_TYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Tpl.StringToken"));
      then txt;

    case ( txt,
           TplAbsyn.INTEGER_TYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Integer"));
      then txt;

    case ( txt,
           TplAbsyn.REAL_TYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Real"));
      then txt;

    case ( txt,
           TplAbsyn.BOOLEAN_TYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Boolean"));
      then txt;

    case ( txt,
           TplAbsyn.UNRESOLVED_TYPE(reason = i_reason) )
      local
        String i_reason;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#type? "));
        txt = Tpl.writeStr(txt, i_reason);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" ?#"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end typeSig;

protected function lm_28
  input Tpl.Text in_txt;
  input list<String> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      local
        list<String> rest;
        String i_it;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = escapeStringConst(txt, i_it, true);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.nextIter(txt);
        txt = lm_28(txt, rest);
      then txt;
  end matchcontinue;
end lm_28;

public function stringTokenConstant
  input Tpl.Text in_txt;
  input Tpl.StringToken in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           Tpl.ST_NEW_LINE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Tpl.ST_NEW_LINE()"));
      then txt;

    case ( txt,
           Tpl.ST_STRING(value = i_value) )
      local
        String i_value;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Tpl.ST_STRING(\""));
        txt = escapeStringConst(txt, i_value, true);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\")"));
      then txt;

    case ( txt,
           Tpl.ST_LINE(line = i_line) )
      local
        String i_line;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Tpl.ST_LINE(\""));
        txt = escapeStringConst(txt, i_line, true);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\")"));
      then txt;

    case ( txt,
           Tpl.ST_STRING_LIST(strList = i_strList, lastHasNewLine = i_lastHasNewLine) )
      local
        Boolean i_lastHasNewLine;
        list<String> i_strList;
      equation
        txt = Tpl.pushBlock(txt, Tpl.BT_ANCHOR(0));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("Tpl.ST_STRING_LIST({\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(4));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_28(txt, i_strList);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}, "));
        txt = Tpl.writeStr(txt, Tpl.booleanString(i_lastHasNewLine));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
        txt = Tpl.popBlock(txt);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end stringTokenConstant;

protected function fun_30
  input Tpl.Text in_txt;
  input Boolean in_i_escapeNewLine;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_escapeNewLine)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\\n"));
      then txt;
  end matchcontinue;
end fun_30;

protected function fun_31
  input Tpl.Text in_txt;
  input String in_i_it;
  input Boolean in_i_escapeNewLine;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it, in_i_escapeNewLine)
    local
      Tpl.Text txt;
      Boolean i_escapeNewLine;

    case ( txt,
           "\\",
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\\\\"));
      then txt;

    case ( txt,
           "\'",
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\\\'"));
      then txt;

    case ( txt,
           "\"",
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\\\""));
      then txt;

    case ( txt,
           "\n",
           i_escapeNewLine )
      equation
        txt = fun_30(txt, i_escapeNewLine);
      then txt;

    case ( txt,
           "\t",
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\\t"));
      then txt;

    case ( txt,
           i_c,
           _ )
      local
        String i_c;
      equation
        txt = Tpl.writeStr(txt, i_c);
      then txt;
  end matchcontinue;
end fun_31;

protected function lm_32
  input Tpl.Text in_txt;
  input list<String> in_items;
  input Boolean in_i_escapeNewLine;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_i_escapeNewLine)
    local
      Tpl.Text txt;
      Boolean i_escapeNewLine;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           i_it :: rest,
           i_escapeNewLine )
      local
        list<String> rest;
        String i_it;
      equation
        txt = fun_31(txt, i_it, i_escapeNewLine);
        txt = lm_32(txt, rest, i_escapeNewLine);
      then txt;
  end matchcontinue;
end lm_32;

public function escapeStringConst
  input Tpl.Text txt;
  input String i_internalValue;
  input Boolean i_escapeNewLine;

  output Tpl.Text out_txt;
  protected
    list<String> ret_0;
algorithm
  ret_0 := stringListStringChar(i_internalValue);
  out_txt := lm_32(txt, ret_0, i_escapeNewLine);
end escapeStringConst;

protected function lm_34
  input Tpl.Text in_txt;
  input list<TplAbsyn.Ident> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      local
        list<TplAbsyn.Ident> rest;
        TplAbsyn.Ident i_it;
      equation
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_34(txt, rest);
      then txt;
  end matchcontinue;
end lm_34;

protected function fun_35
  input Tpl.Text in_txt;
  input list<TplAbsyn.Ident> in_i_lhsArgs;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_lhsArgs)
    local
      Tpl.Text txt;

    case ( txt,
           {i_id} )
      local
        TplAbsyn.Ident i_id;
      equation
        txt = Tpl.writeStr(txt, i_id);
      then txt;

    case ( txt,
           i_args )
      local
        list<TplAbsyn.Ident> i_args;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_34(txt, i_args);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;
  end matchcontinue;
end fun_35;

protected function lm_36
  input Tpl.Text in_txt;
  input list<TplAbsyn.MMExp> in_items;
  input String in_i_assignStr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_i_assignStr)
    local
      Tpl.Text txt;
      String i_assignStr;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           i_it :: rest,
           i_assignStr )
      local
        list<TplAbsyn.MMExp> rest;
        TplAbsyn.MMExp i_it;
      equation
        txt = mmExp(txt, i_it, i_assignStr);
        txt = Tpl.nextIter(txt);
        txt = lm_36(txt, rest, i_assignStr);
      then txt;
  end matchcontinue;
end lm_36;

public function mmExp
  input Tpl.Text in_txt;
  input TplAbsyn.MMExp in_i_it;
  input String in_i_assignStr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it, in_i_assignStr)
    local
      Tpl.Text txt;
      String i_assignStr;

    case ( txt,
           TplAbsyn.MM_ASSIGN(lhsArgs = i_lhsArgs, rhs = i_rhs),
           i_assignStr )
      local
        TplAbsyn.MMExp i_rhs;
        list<TplAbsyn.Ident> i_lhsArgs;
      equation
        txt = fun_35(txt, i_lhsArgs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeStr(txt, i_assignStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = mmExp(txt, i_rhs, i_assignStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;

    case ( txt,
           TplAbsyn.MM_FN_CALL(fnName = i_fnName, args = i_args),
           i_assignStr )
      local
        list<TplAbsyn.MMExp> i_args;
        TplAbsyn.PathIdent i_fnName;
      equation
        txt = pathIdent(txt, i_fnName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_36(txt, i_args, i_assignStr);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           TplAbsyn.MM_IDENT(ident = i_ident),
           _ )
      local
        TplAbsyn.PathIdent i_ident;
      equation
        txt = pathIdent(txt, i_ident);
      then txt;

    case ( txt,
           TplAbsyn.MM_STR_TOKEN(value = i_value),
           _ )
      local
        TplAbsyn.StringToken i_value;
      equation
        txt = stringTokenConstant(txt, i_value);
      then txt;

    case ( txt,
           TplAbsyn.MM_STRING(value = i_value),
           _ )
      local
        String i_value;
      equation
        txt = Tpl.pushBlock(txt, Tpl.BT_ABS_INDENT(0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = escapeStringConst(txt, i_value, false);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.popBlock(txt);
      then txt;

    case ( txt,
           TplAbsyn.MM_LITERAL(value = i_value),
           _ )
      local
        String i_value;
      equation
        txt = Tpl.writeStr(txt, i_value);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end mmExp;

protected function lm_38
  input Tpl.Text in_txt;
  input list<tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp>> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_field, i_mexp) :: rest )
      local
        list<tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp>> rest;
        TplAbsyn.MatchingExp i_mexp;
        TplAbsyn.Ident i_field;
      equation
        txt = Tpl.writeStr(txt, i_field);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = mmMatchingExp(txt, i_mexp);
        txt = Tpl.nextIter(txt);
        txt = lm_38(txt, rest);
      then txt;
  end matchcontinue;
end lm_38;

protected function lm_39
  input Tpl.Text in_txt;
  input list<TplAbsyn.MatchingExp> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      local
        list<TplAbsyn.MatchingExp> rest;
        TplAbsyn.MatchingExp i_it;
      equation
        txt = mmMatchingExp(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_39(txt, rest);
      then txt;
  end matchcontinue;
end lm_39;

protected function lm_40
  input Tpl.Text in_txt;
  input list<TplAbsyn.MatchingExp> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      local
        list<TplAbsyn.MatchingExp> rest;
        TplAbsyn.MatchingExp i_it;
      equation
        txt = mmMatchingExp(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_40(txt, rest);
      then txt;
  end matchcontinue;
end lm_40;

public function mmMatchingExp
  input Tpl.Text in_txt;
  input TplAbsyn.MatchingExp in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           TplAbsyn.BIND_AS_MATCH(bindIdent = i_bindIdent, matchingExp = i_matchingExp) )
      local
        TplAbsyn.MatchingExp i_matchingExp;
        TplAbsyn.Ident i_bindIdent;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeStr(txt, i_bindIdent);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" as "));
        txt = mmMatchingExp(txt, i_matchingExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           TplAbsyn.BIND_MATCH(bindIdent = i_bindIdent) )
      local
        TplAbsyn.Ident i_bindIdent;
      equation
        txt = Tpl.writeStr(txt, i_bindIdent);
      then txt;

    case ( txt,
           TplAbsyn.RECORD_MATCH(tagName = i_tagName, fieldMatchings = i_fieldMatchings) )
      local
        list<tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp>> i_fieldMatchings;
        TplAbsyn.PathIdent i_tagName;
      equation
        txt = pathIdent(txt, i_tagName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_38(txt, i_fieldMatchings);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           TplAbsyn.SOME_MATCH(value = i_value) )
      local
        TplAbsyn.MatchingExp i_value;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("SOME("));
        txt = mmMatchingExp(txt, i_value);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           TplAbsyn.NONE_MATCH() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("NONE"));
      then txt;

    case ( txt,
           TplAbsyn.TUPLE_MATCH(tupleArgs = i_tupleArgs) )
      local
        list<TplAbsyn.MatchingExp> i_tupleArgs;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_39(txt, i_tupleArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           TplAbsyn.LIST_MATCH(listElts = i_listElts) )
      local
        list<TplAbsyn.MatchingExp> i_listElts;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("{"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_40(txt, i_listElts);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then txt;

    case ( txt,
           TplAbsyn.LIST_CONS_MATCH(head = i_head, rest = i_rest) )
      local
        TplAbsyn.MatchingExp i_rest;
        TplAbsyn.MatchingExp i_head;
      equation
        txt = mmMatchingExp(txt, i_head);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" :: "));
        txt = mmMatchingExp(txt, i_rest);
      then txt;

    case ( txt,
           TplAbsyn.STRING_MATCH(value = i_value) )
      local
        String i_value;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = escapeStringConst(txt, i_value, true);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      then txt;

    case ( txt,
           TplAbsyn.LITERAL_MATCH(value = i_value) )
      local
        String i_value;
      equation
        txt = Tpl.writeStr(txt, i_value);
      then txt;

    case ( txt,
           TplAbsyn.REST_MATCH() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end mmMatchingExp;

protected function lm_42
  input Tpl.Text in_txt;
  input list<TplAbsyn.MMExp> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      local
        list<TplAbsyn.MMExp> rest;
        TplAbsyn.MMExp i_it;
      equation
        txt = mmExp(txt, i_it, "=");
        txt = Tpl.nextIter(txt);
        txt = lm_42(txt, rest);
      then txt;
  end matchcontinue;
end lm_42;

public function mmStatements
  input Tpl.Text txt;
  input list<TplAbsyn.MMExp> i_stmts;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_42(out_txt, i_stmts);
  out_txt := Tpl.popIter(out_txt);
end mmStatements;

end TplCodegen;