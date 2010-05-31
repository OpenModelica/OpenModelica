package test

protected constant Tpl.Text emptyTxt = Tpl.MEM_TEXT({}, {});

public import Tpl;

public import TplAbsyn;

public function pathIdent
  input Tpl.Text in_txt;
  input TplAbsyn.PathIdent in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
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

protected function lm_3
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
           (i_id, i_pid) :: rest )
      local
        TplAbsyn.TypedIdents rest;
        TplAbsyn.PathIdent i_pid;
        TplAbsyn.Ident i_id;
      equation
        txt = pathIdent(txt, i_pid);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeStr(txt, i_id);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";//heja"));
        txt = Tpl.nextIter(txt);
        txt = lm_3(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        TplAbsyn.TypedIdents rest;
      equation
        txt = lm_3(txt, rest);
      then txt;
  end matchcontinue;
end lm_3;

public function typedIdents
  input Tpl.Text txt;
  input TplAbsyn.TypedIdents i_decls;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_3(out_txt, i_decls);
  out_txt := Tpl.popIter(out_txt);
end typedIdents;

protected function lm_5
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
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_5(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_5(txt, rest);
      then txt;
  end matchcontinue;
end lm_5;

public function test
  input Tpl.Text txt;
  input list<String> i_items;
  input Integer i_ind;

  output Tpl.Text out_txt;
protected
  String ret_5;
  Integer ret_4;
  Tpl.StringToken ret_3;
  Tpl.Text txt_2;
  Integer ret_1;
  String ret_0;
algorithm
  ret_0 := intString(i_ind);
  ret_1 := testfn(intString(i_ind));
  txt_2 := Tpl.writeTok(emptyTxt, Tpl.ST_STRING("ss"));
  txt_2 := Tpl.writeStr(txt_2, intString(i_ind));
  ret_3 := Tpl.textStrTok(txt_2);
  ret_4 := testfn("2");
  ret_5 := intString(ret_4);
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(ret_0)), ret_1, 0, ret_3, 0, Tpl.ST_STRING(ret_5)));
  out_txt := lm_5(out_txt, i_items);
  out_txt := Tpl.popIter(out_txt);
end test;

protected function lm_7
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
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_7(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_7(txt, rest);
      then txt;
  end matchcontinue;
end lm_7;

public function test2
  input Tpl.Text txt;
  input list<String> i_items;
  input String i_sep;
  input Integer i_a;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(i_sep)), i_a, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_7(out_txt, i_items);
  out_txt := Tpl.popIter(out_txt);
end test2;

protected function lm_9
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
           i_st :: rest )
      local
        list<String> rest;
        String i_st;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("bla"));
        txt = Tpl.writeStr(txt, i_st);
        txt = Tpl.nextIter(txt);
        txt = lm_9(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_9(txt, rest);
      then txt;
  end matchcontinue;
end lm_9;

protected function smf_10
  input Tpl.Text in_txt;
  input String in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_st )
      local
        String i_st;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("bla"));
        txt = Tpl.writeStr(txt, i_st);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_10;

protected function smf_11
  input Tpl.Text in_txt;
  input Integer in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_st )
      local
        Integer i_st;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("bla"));
        txt = Tpl.writeStr(txt, intString(i_st));
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_11;

protected function lm_12
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
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_12(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_12(txt, rest);
      then txt;
  end matchcontinue;
end lm_12;

protected function smf_13
  input Tpl.Text in_txt;
  input String in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        String i_it;
      equation
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_13;

protected function smf_14
  input Tpl.Text in_txt;
  input Integer in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Integer i_it;
      equation
        txt = Tpl.writeStr(txt, intString(i_it));
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_14;

protected function lm_15
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
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_15(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_15(txt, rest);
      then txt;
  end matchcontinue;
end lm_15;

protected function smf_16
  input Tpl.Text in_txt;
  input String in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        String i_it;
      equation
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_16;

protected function smf_17
  input Tpl.Text in_txt;
  input Integer in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Integer i_it;
      equation
        txt = Tpl.writeStr(txt, intString(i_it));
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_17;

protected function smf_18
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_18;

protected function smf_19
  input Tpl.Text in_txt;
  input Tpl.StringToken in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.StringToken i_it;
      equation
        txt = Tpl.writeTok(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_19;

protected function lm_20
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
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_20(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_20(txt, rest);
      then txt;
  end matchcontinue;
end lm_20;

protected function smf_21
  input Tpl.Text in_txt;
  input String in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        String i_it;
      equation
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_21;

protected function smf_22
  input Tpl.Text in_txt;
  input Integer in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Integer i_it;
      equation
        txt = Tpl.writeStr(txt, intString(i_it));
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_22;

protected function lm_23
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
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_23(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_23(txt, rest);
      then txt;
  end matchcontinue;
end lm_23;

protected function smf_24
  input Tpl.Text in_txt;
  input String in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        String i_it;
      equation
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_24;

protected function smf_25
  input Tpl.Text in_txt;
  input Integer in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Integer i_it;
      equation
        txt = Tpl.writeStr(txt, intString(i_it));
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_25;

protected function fun_26
  input Tpl.Text in_txt;
  input String in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        String i_it;
      equation
        txt = Tpl.writeStr(txt, i_it);
      then txt;
  end matchcontinue;
end fun_26;

protected function lm_27
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
        txt = fun_26(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_27(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_27(txt, rest);
      then txt;
  end matchcontinue;
end lm_27;

protected function fun_28
  input Tpl.Text in_txt;
  input String in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        String i_it;
      equation
        txt = Tpl.writeStr(txt, i_it);
      then txt;
  end matchcontinue;
end fun_28;

protected function smf_29
  input Tpl.Text in_txt;
  input String in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        String i_it;
      equation
        txt = fun_28(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_29;

protected function fun_30
  input Tpl.Text in_txt;
  input Integer in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Integer i_it;
      equation
        txt = Tpl.writeStr(txt, intString(i_it));
      then txt;
  end matchcontinue;
end fun_30;

protected function smf_31
  input Tpl.Text in_txt;
  input Integer in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Integer i_it;
      equation
        txt = fun_30(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_31;

protected function fun_32
  input Tpl.Text in_txt;
  input String in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        String i_it;
      equation
        txt = Tpl.writeStr(txt, i_it);
      then txt;
  end matchcontinue;
end fun_32;

protected function smf_33
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
        String str_0;
      equation
        str_0 = Tpl.textString(i_it);
        txt = fun_32(txt, str_0);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_33;

protected function fun_34
  input Tpl.Text in_txt;
  input Tpl.StringToken in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.StringToken i_it;
      equation
        txt = Tpl.writeTok(txt, i_it);
      then txt;
  end matchcontinue;
end fun_34;

protected function smf_35
  input Tpl.Text in_txt;
  input Tpl.StringToken in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.StringToken i_it;
      equation
        txt = fun_34(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_35;

protected function fun_36
  input Tpl.Text in_txt;
  input String in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        String i_it;
      equation
        txt = Tpl.writeStr(txt, i_it);
      then txt;
  end matchcontinue;
end fun_36;

public function test3
  input Tpl.Text txt;
  input list<String> i_items;
  input String i_item;
  input Integer i_ii;

  output Tpl.Text out_txt;
protected
  String str_3;
  Tpl.Text txt_2;
  Tpl.Text txt_1;
  Tpl.Text txt_0;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_9(out_txt, i_items);
  out_txt := smf_10(out_txt, i_item);
  out_txt := smf_11(out_txt, i_ii);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  txt_0 := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  txt_0 := lm_12(txt_0, i_items);
  txt_0 := smf_13(txt_0, i_item);
  txt_0 := smf_14(txt_0, i_ii);
  txt_0 := Tpl.popIter(txt_0);
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_15(out_txt, i_items);
  out_txt := smf_16(out_txt, i_item);
  out_txt := smf_17(out_txt, i_ii);
  out_txt := smf_18(out_txt, txt_0);
  out_txt := smf_19(out_txt, Tpl.ST_STRING("blaaa"));
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_20(out_txt, i_items);
  out_txt := smf_21(out_txt, i_item);
  out_txt := smf_22(out_txt, i_ii);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("!!!!!error should be\n"));
  txt_1 := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  txt_1 := lm_23(txt_1, i_items);
  txt_1 := smf_24(txt_1, i_item);
  txt_1 := smf_25(txt_1, i_ii);
  txt_1 := Tpl.popIter(txt_1);
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_27(out_txt, i_items);
  out_txt := smf_29(out_txt, i_item);
  out_txt := smf_31(out_txt, i_ii);
  out_txt := smf_33(out_txt, txt_1);
  out_txt := smf_35(out_txt, Tpl.ST_STRING("blaaa"));
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  txt_2 := Tpl.writeTok(emptyTxt, Tpl.ST_STRING("aha"));
  txt_2 := Tpl.writeStr(txt_2, intString(i_ii));
  str_3 := Tpl.textString(txt_2);
  out_txt := fun_36(out_txt, str_3);
end test3;

public function testCond
  input Tpl.Text in_txt;
  input Option<tuple<String, Integer>> in_i_nvOpt;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_nvOpt)
    local
      Tpl.Text txt;

    case ( txt,
           SOME((i_name, i_value)) )
      local
        Integer i_value;
        String i_name;
      equation
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeStr(txt, intString(i_value));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("no value"));
      then txt;
  end matchcontinue;
end testCond;

public function testCond2
  input Tpl.Text in_txt;
  input Option<tuple<String, Integer>> in_i_nvOpt;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_nvOpt)
    local
      Tpl.Text txt;

    case ( txt,
           SOME((i_name, i_value)) )
      local
        Integer i_value;
        String i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("SOME("));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeStr(txt, intString(i_value));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("none"));
      then txt;
  end matchcontinue;
end testCond2;

public function mapInt
  input Tpl.Text txt;
  input Integer i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("(int:"));
  out_txt := Tpl.writeStr(out_txt, intString(i_it));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(")"));
end mapInt;

public function mapString
  input Tpl.Text txt;
  input String i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("(str:"));
  out_txt := Tpl.writeStr(out_txt, i_it);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(")"));
end mapString;

public function mapIntString
  input Tpl.Text txt;
  input Integer i_intPar;
  input String i_stPar;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("(int:"));
  out_txt := Tpl.writeStr(out_txt, intString(i_intPar));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(",str:"));
  out_txt := Tpl.writeStr(out_txt, i_stPar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(")"));
end mapIntString;

protected function smf_43
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = mapString(txt, Tpl.textString(i_it));
      then txt;
  end matchcontinue;
end smf_43;

protected function lm_44
  input Tpl.Text in_txt;
  input list<Integer> in_items;

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
        list<Integer> rest;
        Integer i_it;
        Tpl.Text txt_0;
      equation
        txt_0 = mapInt(emptyTxt, i_it);
        txt = smf_43(txt, txt_0);
        txt = Tpl.nextIter(txt);
        txt = lm_44(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Integer> rest;
      equation
        txt = lm_44(txt, rest);
      then txt;
  end matchcontinue;
end lm_44;

public function testMap
  input Tpl.Text txt;
  input list<Integer> i_ints;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_44(out_txt, i_ints);
  out_txt := Tpl.popIter(out_txt);
end testMap;

protected function smf_46
  input Tpl.Text in_txt;
  input Tpl.Text in_it;
  input Integer in_i_int;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_int)
    local
      Tpl.Text txt;
      Integer i_int;

    case ( txt,
           i_st,
           i_int )
      local
        Tpl.Text i_st;
      equation
        txt = mapIntString(txt, i_int, Tpl.textString(i_st));
      then txt;
  end matchcontinue;
end smf_46;

protected function lm_47
  input Tpl.Text in_txt;
  input list<Integer> in_items;

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
           i_int :: rest )
      local
        list<Integer> rest;
        Integer i_int;
        Tpl.Text txt_0;
      equation
        txt_0 = mapInt(emptyTxt, i_int);
        txt = smf_46(txt, txt_0, i_int);
        txt = Tpl.nextIter(txt);
        txt = lm_47(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Integer> rest;
      equation
        txt = lm_47(txt, rest);
      then txt;
  end matchcontinue;
end lm_47;

public function testMap2
  input Tpl.Text txt;
  input list<Integer> i_ints;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_47(out_txt, i_ints);
  out_txt := Tpl.popIter(out_txt);
end testMap2;

protected function lm_49
  input Tpl.Text in_txt;
  input list<Integer> in_items;

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
           i_int :: rest )
      local
        list<Integer> rest;
        Integer i_int;
      equation
        txt = mapInt(txt, i_int);
        txt = Tpl.nextIter(txt);
        txt = lm_49(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Integer> rest;
      equation
        txt = lm_49(txt, rest);
      then txt;
  end matchcontinue;
end lm_49;

protected function lm_50
  input Tpl.Text in_txt;
  input list<list<Integer>> in_items;

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
           i_intLst :: rest )
      local
        list<list<Integer>> rest;
        list<Integer> i_intLst;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_49(txt, i_intLst);
        txt = Tpl.popIter(txt);
        txt = Tpl.nextIter(txt);
        txt = lm_50(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<list<Integer>> rest;
      equation
        txt = lm_50(txt, rest);
      then txt;
  end matchcontinue;
end lm_50;

public function testMap3
  input Tpl.Text txt;
  input list<list<Integer>> i_lstOfLst;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushBlock(txt, Tpl.BT_ANCHOR(0));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(";\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_50(out_txt, i_lstOfLst);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.popBlock(out_txt);
end testMap3;

protected function lm_52
  input Tpl.Text in_txt;
  input list<Integer> in_items;

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
        list<Integer> rest;
        Integer i_it;
      equation
        txt = mapInt(txt, i_it);
        txt = lm_52(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Integer> rest;
      equation
        txt = lm_52(txt, rest);
      then txt;
  end matchcontinue;
end lm_52;

protected function lm_53
  input Tpl.Text in_txt;
  input list<list<Integer>> in_items;

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
        list<list<Integer>> rest;
        list<Integer> i_it;
      equation
        txt = lm_52(txt, i_it);
        txt = lm_53(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<list<Integer>> rest;
      equation
        txt = lm_53(txt, rest);
      then txt;
  end matchcontinue;
end lm_53;

public function testMap4
  input Tpl.Text txt;
  input list<list<Integer>> i_lstOfLst;

  output Tpl.Text out_txt;
algorithm
  out_txt := lm_53(txt, i_lstOfLst);
end testMap4;

protected function lm_55
  input Tpl.Text in_txt;
  input list<Integer> in_items;

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
        list<Integer> rest;
        Integer i_it;
        Tpl.Text txt_0;
      equation
        txt_0 = mapInt(emptyTxt, i_it);
        txt = mapString(txt, Tpl.textString(txt_0));
        txt = Tpl.nextIter(txt);
        txt = lm_55(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Integer> rest;
      equation
        txt = lm_55(txt, rest);
      then txt;
  end matchcontinue;
end lm_55;

public function testMap5
  input Tpl.Text txt;
  input list<Integer> i_ints;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_55(out_txt, i_ints);
  out_txt := Tpl.popIter(out_txt);
end testMap5;

protected function lm_57
  input Tpl.Text in_txt;
  input list<Integer> in_items;

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
        list<Integer> rest;
        Integer i_it;
      equation
        txt = Tpl.writeStr(txt, intString(i_it));
        txt = Tpl.nextIter(txt);
        txt = lm_57(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Integer> rest;
      equation
        txt = lm_57(txt, rest);
      then txt;
  end matchcontinue;
end lm_57;

protected function lm_58
  input Tpl.Text in_txt;
  input list<list<Integer>> in_items;

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
           i_intLst :: rest )
      local
        list<list<Integer>> rest;
        list<Integer> i_intLst;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_57(txt, i_intLst);
        txt = Tpl.popIter(txt);
        txt = Tpl.nextIter(txt);
        txt = lm_58(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<list<Integer>> rest;
      equation
        txt = lm_58(txt, rest);
      then txt;
  end matchcontinue;
end lm_58;

public function intMatrix
  input Tpl.Text txt;
  input list<list<Integer>> i_lstOfLst;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("[ "));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_ANCHOR(0));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(";\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_58(out_txt, i_lstOfLst);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" ]"));
end intMatrix;

protected function fun_60
  input Tpl.Text in_txt;
  input String in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           "" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/* weird I */"));
      then txt;

    case ( txt,
           str_1 )
      local
        String str_1;
      equation
        txt = Tpl.writeStr(txt, str_1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" name;"));
      then txt;
  end matchcontinue;
end fun_60;

public function ifTest
  input Tpl.Text txt;
  input Integer i_i;

  output Tpl.Text out_txt;
protected
  String str_1;
  Tpl.Text txt_0;
algorithm
  txt_0 := mapInt(emptyTxt, i_i);
  str_1 := Tpl.textString(txt_0);
  out_txt := fun_60(txt, str_1);
end ifTest;

protected function smf_62
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_ii )
      local
        Tpl.Text i_ii;
      equation
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("some hej"));
        txt = Tpl.writeText(txt, i_ii);
        txt = Tpl.popBlock(txt);
      then txt;
  end matchcontinue;
end smf_62;

public function bindTest
  input Tpl.Text txt;

  output Tpl.Text out_txt;
protected
  Tpl.Text txt_0;
algorithm
  txt_0 := ifTest(emptyTxt, 1);
  out_txt := smf_62(txt, txt_0);
end bindTest;

public function txtTest
  input Tpl.Text txt;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_txt;
algorithm
  i_txt := Tpl.writeTok(emptyTxt, Tpl.ST_STRING("ahoj"));
  i_txt := Tpl.writeTok(i_txt, Tpl.ST_STRING("hej"));
  out_txt := Tpl.writeText(txt, i_txt);
end txtTest;

public function txtTest2
  input Tpl.Text txt;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_txt;
algorithm
  i_txt := Tpl.writeTok(emptyTxt, Tpl.ST_STRING("ahoj2"));
  i_txt := Tpl.writeTok(i_txt, Tpl.ST_STRING("hej2"));
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("bláá "));
  out_txt := Tpl.writeText(out_txt, i_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("jo"));
end txtTest2;

public function txtTest3
  input Tpl.Text txt;
  input String i_hej;
  input Tpl.Text i_buf;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_buf;
protected
  Tpl.Text i_txt;
algorithm
  i_txt := Tpl.writeTok(emptyTxt, Tpl.ST_STRING("aahoj2"));
  i_txt := Tpl.writeTok(i_txt, Tpl.ST_STRING("ahej2"));
  out_i_buf := Tpl.writeText(i_buf, i_txt);
  (out_i_buf, out_i_buf) := txtTest4(out_i_buf, "ha!", out_i_buf);
  out_i_buf := Tpl.writeTok(out_i_buf, Tpl.ST_STRING("ahoj"));
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("abláá "));
  out_txt := Tpl.writeText(out_txt, i_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("ajo"));
end txtTest3;

public function txtTest4
  input Tpl.Text in_txt;
  input String in_i_hej;
  input Tpl.Text in_i_buf;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_buf;
algorithm
  (out_txt, out_i_buf) :=
  matchcontinue(in_txt, in_i_hej, in_i_buf)
    local
      Tpl.Text txt;
      Tpl.Text i_buf;

    case ( txt,
           "",
           i_buf )
      then (txt, i_buf);

    case ( txt,
           i_hej,
           i_buf )
      local
        String i_hej;
        Tpl.Text i_txt;
      equation
        i_txt = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("ahoj2"));
        i_txt = Tpl.writeStr(i_txt, i_hej);
        i_buf = Tpl.writeText(i_buf, i_txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("bláá "));
        txt = Tpl.writeText(txt, i_txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("jo"));
      then (txt, i_buf);
  end matchcontinue;
end txtTest4;

public function txtTest5
  input Tpl.Text txt;
  input String i_hej;
  input Tpl.Text i_buf;
  input Tpl.Text i_nobuf;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_buf;
  output Tpl.Text out_i_nobuf;
protected
  Tpl.Text i_txt;
algorithm
  i_txt := Tpl.writeTok(emptyTxt, Tpl.ST_STRING("aahoj2"));
  i_txt := Tpl.writeTok(i_txt, Tpl.ST_STRING("ahej2"));
  out_i_buf := Tpl.writeText(i_buf, i_txt);
  (out_i_buf, out_i_buf) := txtTest4(out_i_buf, "ha!", out_i_buf);
  out_i_buf := Tpl.writeTok(out_i_buf, Tpl.ST_STRING("ahoj"));
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("abláá "));
  out_txt := Tpl.writeText(out_txt, i_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("ajo"));
  out_i_nobuf := i_nobuf;
end txtTest5;

protected function lm_69
  input Tpl.Text in_txt;
  input list<String> in_items;
  input Tpl.Text in_i_nomut;
  input Tpl.Text in_i_mytxt;
  input Tpl.Text in_i_buf2;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_mytxt;
  output Tpl.Text out_i_buf2;
algorithm
  (out_txt, out_i_mytxt, out_i_buf2) :=
  matchcontinue(in_txt, in_items, in_i_nomut, in_i_mytxt, in_i_buf2)
    local
      Tpl.Text txt;
      Tpl.Text i_nomut;
      Tpl.Text i_mytxt;
      Tpl.Text i_buf2;

    case ( txt,
           {},
           _,
           i_mytxt,
           i_buf2 )
      then (txt, i_mytxt, i_buf2);

    case ( txt,
           i_it :: rest,
           i_nomut,
           i_mytxt,
           i_buf2 )
      local
        list<String> rest;
        String i_it;
      equation
        i_buf2 = Tpl.writeStr(i_buf2, i_it);
        i_mytxt = Tpl.writeStr(i_mytxt, i_it);
        i_mytxt = Tpl.writeTok(i_mytxt, Tpl.ST_STRING("jo"));
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.writeText(txt, i_nomut);
        txt = Tpl.nextIter(txt);
        (txt, i_mytxt, i_buf2) = lm_69(txt, rest, i_nomut, i_mytxt, i_buf2);
      then (txt, i_mytxt, i_buf2);

    case ( txt,
           _ :: rest,
           i_nomut,
           i_mytxt,
           i_buf2 )
      local
        list<String> rest;
      equation
        (txt, i_mytxt, i_buf2) = lm_69(txt, rest, i_nomut, i_mytxt, i_buf2);
      then (txt, i_mytxt, i_buf2);
  end matchcontinue;
end lm_69;

protected function smf_70
  input Tpl.Text in_txt;
  input String in_it;
  input Tpl.Text in_i_nomut;
  input Tpl.Text in_i_mytxt;
  input Tpl.Text in_i_buf2;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_mytxt;
  output Tpl.Text out_i_buf2;
algorithm
  (out_txt, out_i_mytxt, out_i_buf2) :=
  matchcontinue(in_txt, in_it, in_i_nomut, in_i_mytxt, in_i_buf2)
    local
      Tpl.Text txt;
      Tpl.Text i_nomut;
      Tpl.Text i_mytxt;
      Tpl.Text i_buf2;

    case ( txt,
           i_it,
           i_nomut,
           i_mytxt,
           i_buf2 )
      local
        String i_it;
      equation
        i_buf2 = Tpl.writeStr(i_buf2, i_it);
        i_mytxt = Tpl.writeStr(i_mytxt, i_it);
        i_mytxt = Tpl.writeTok(i_mytxt, Tpl.ST_STRING("jo"));
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.writeText(txt, i_nomut);
      then (txt, i_mytxt, i_buf2);
  end matchcontinue;
end smf_70;

protected function fun_71
  input Tpl.Text in_txt;
  input list<String> in_i_hej;
  input Tpl.Text in_i_mytxt;
  input Tpl.Text in_i_nomut;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_mytxt;
algorithm
  (out_txt, out_i_mytxt) :=
  matchcontinue(in_txt, in_i_hej, in_i_mytxt, in_i_nomut)
    local
      Tpl.Text txt;
      Tpl.Text i_mytxt;
      Tpl.Text i_nomut;

    case ( txt,
           (i_hej as "1" :: _),
           i_mytxt,
           i_nomut )
      local
        list<String> i_hej;
        Tpl.StringToken ret_1;
        Tpl.Text i_buf2;
      equation
        i_buf2 = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("hop"));
        ret_1 = Tpl.textStrTok(i_nomut);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(ret_1), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_mytxt, i_buf2) = lm_69(txt, i_hej, i_nomut, i_mytxt, i_buf2);
        txt = Tpl.popIter(txt);
      then (txt, i_mytxt);

    case ( txt,
           i_h :: _,
           i_mytxt,
           i_nomut )
      local
        String i_h;
        Tpl.StringToken ret_1;
        Tpl.Text i_buf2;
      equation
        i_buf2 = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("hop"));
        ret_1 = Tpl.textStrTok(i_nomut);
        (txt, i_mytxt, i_buf2) = smf_70(txt, i_h, i_nomut, i_mytxt, i_buf2);
      then (txt, i_mytxt);

    case ( txt,
           _,
           i_mytxt,
           _ )
      then (txt, i_mytxt);
  end matchcontinue;
end fun_71;

public function txtTest6
  input Tpl.Text txt;
  input list<String> i_hej;
  input Tpl.Text i_buf;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_buf;
protected
  Tpl.Text i_nomut;
  Tpl.Text i_mytxt;
algorithm
  i_mytxt := Tpl.writeTok(emptyTxt, Tpl.ST_STRING("bolo"));
  i_nomut := Tpl.writeTok(emptyTxt, Tpl.ST_STRING(","));
  (out_txt, i_mytxt) := fun_71(txt, i_hej, i_mytxt, i_nomut);
  out_i_buf := i_buf;
end txtTest6;

public function contCase
  input Tpl.Text in_txt;
  input String in_i_tst;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_tst)
    local
      Tpl.Text txt;

    case ( txt,
           "a" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("hej"));
      then txt;

    case ( txt,
           "b" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("hej"));
      then txt;

    case ( txt,
           "bb" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("hej"));
      then txt;

    case ( txt,
           "c" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("hej"));
      then txt;

    case ( txt,
           "d" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Hej!"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end contCase;

public function contCase2
  input Tpl.Text in_txt;
  input TplAbsyn.PathIdent in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           TplAbsyn.IDENT(ident = i_ident) )
      local
        TplAbsyn.Ident i_ident;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("id="));
        txt = Tpl.writeStr(txt, i_ident);
      then txt;

    case ( txt,
           TplAbsyn.PATH_IDENT(ident = i_ident) )
      local
        TplAbsyn.Ident i_ident;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("id="));
        txt = Tpl.writeStr(txt, i_ident);
      then txt;

    case ( txt,
           TplAbsyn.IDENT(ident = (i_ident as "ii")) )
      local
        TplAbsyn.Ident i_ident;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("id="));
        txt = Tpl.writeStr(txt, i_ident);
      then txt;

    case ( txt,
           TplAbsyn.IDENT(ident = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("hej"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end contCase2;

public function genericTest
  input Tpl.Text txt;
  input list<String> i_lst;

  output Tpl.Text out_txt;
protected
  Integer ret_0;
algorithm
  ret_0 := listLength(i_lst);
  out_txt := Tpl.writeStr(txt, intString(ret_0));
end genericTest;

public function genericTest2
  input Tpl.Text txt;
  input list<Integer> i_lst;

  output Tpl.Text out_txt;
protected
  Integer ret_0;
algorithm
  ret_0 := listLength(i_lst);
  out_txt := Tpl.writeStr(txt, intString(ret_0));
end genericTest2;

public function genericTest3
  input Tpl.Text txt;
  input list<Integer> i_lst;

  output Tpl.Text out_txt;
protected
  Boolean ret_0;
algorithm
  ret_0 := listMember(3, i_lst);
  out_txt := Tpl.writeStr(txt, Tpl.booleanString(ret_0));
end genericTest3;

public function genericTest4
  input Tpl.Text txt;
  input list<String> i_lst;

  output Tpl.Text out_txt;
protected
  Boolean ret_0;
algorithm
  ret_0 := listMember("ahoj", i_lst);
  out_txt := Tpl.writeStr(txt, Tpl.booleanString(ret_0));
end genericTest4;

public function genericTest5
  input Tpl.Text txt;
  input list<String> i_lst;
  input String i_hoj;

  output Tpl.Text out_txt;
protected
  Boolean ret_1;
  Tpl.Text txt_0;
algorithm
  txt_0 := Tpl.writeTok(emptyTxt, Tpl.ST_STRING("a"));
  txt_0 := Tpl.writeStr(txt_0, i_hoj);
  ret_1 := listMember(Tpl.textString(txt_0), i_lst);
  out_txt := Tpl.writeStr(txt, Tpl.booleanString(ret_1));
end genericTest5;

public function genericTest6
  input Tpl.Text txt;
  input list<String> i_lst;
  input Integer i_idx;

  output Tpl.Text out_txt;
protected
  String ret_0;
algorithm
  ret_0 := listGet(i_lst, i_idx);
  out_txt := Tpl.writeStr(txt, ret_0);
end genericTest6;

public function genericTest7
  input Tpl.Text txt;
  input list<Integer> i_lst;
  input Integer i_idx;

  output Tpl.Text out_txt;
protected
  Integer ret_0;
algorithm
  ret_0 := listGet(i_lst, i_idx);
  out_txt := Tpl.writeStr(txt, intString(ret_0));
end genericTest7;

protected function lm_82
  input Tpl.Text in_txt;
  input list<Integer> in_items;

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
        list<Integer> rest;
        Integer i_it;
      equation
        txt = Tpl.writeStr(txt, intString(i_it));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("th revesed"));
        txt = lm_82(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Integer> rest;
      equation
        txt = lm_82(txt, rest);
      then txt;
  end matchcontinue;
end lm_82;

public function genericTest8
  input Tpl.Text txt;
  input list<Integer> i_lst;

  output Tpl.Text out_txt;
protected
  list<Integer> ret_0;
algorithm
  ret_0 := listReverse(i_lst);
  out_txt := lm_82(txt, ret_0);
end genericTest8;

protected function lm_84
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
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("hej!"));
        txt = lm_84(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_84(txt, rest);
      then txt;
  end matchcontinue;
end lm_84;

protected function lm_85
  input Tpl.Text in_txt;
  input list<list<String>> in_items;

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
        list<list<String>> rest;
        list<String> i_it;
        list<String> ret_0;
      equation
        ret_0 = listReverse(i_it);
        txt = lm_84(txt, ret_0);
        txt = lm_85(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<list<String>> rest;
      equation
        txt = lm_85(txt, rest);
      then txt;
  end matchcontinue;
end lm_85;

public function genericTest9
  input Tpl.Text txt;
  input list<list<String>> i_lst;

  output Tpl.Text out_txt;
protected
  list<list<String>> ret_0;
algorithm
  ret_0 := listReverse(i_lst);
  out_txt := lm_85(txt, ret_0);
end genericTest9;

end test;