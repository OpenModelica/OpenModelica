package paper

protected constant Tpl.Text emptyTxt = Tpl.MEM_TEXT({}, {});

public import Tpl;

public import Example;

protected function lm_1
  input Tpl.Text in_txt;
  input list<Example.Statement> in_items;

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
        list<Example.Statement> rest;
        Example.Statement i_it;
      equation
        txt = statement(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_1(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Example.Statement> rest;
      equation
        txt = lm_1(txt, rest);
      then txt;
  end matchcontinue;
end lm_1;

public function statement
  input Tpl.Text in_txt;
  input Example.Statement in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           Example.ASSIGN(lhs = i_lhs, rhs = i_rhs) )
      local
        Example.Exp i_rhs;
        Example.Exp i_lhs;
      equation
        txt = exp(txt, i_lhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = exp(txt, i_rhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;

    case ( txt,
           Example.WHILE(condition = i_condition, statements = i_statements) )
      local
        list<Example.Statement> i_statements;
        Example.Exp i_condition;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("while("));
        txt = exp(txt, i_condition);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_1(txt, i_statements);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end statement;

public function exp
  input Tpl.Text in_txt;
  input Example.Exp in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           Example.ICONST(value = i_value) )
      local
        Integer i_value;
      equation
        txt = Tpl.writeStr(txt, intString(i_value));
      then txt;

    case ( txt,
           Example.VARIABLE(name = i_name) )
      local
        String i_name;
      equation
        txt = Tpl.writeStr(txt, i_name);
      then txt;

    case ( txt,
           Example.BINARY(lhs = i_lhs, op = i_op, rhs = i_rhs) )
      local
        Example.Exp i_rhs;
        Example.Operator i_op;
        Example.Exp i_lhs;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = exp(txt, i_lhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = oper(txt, i_op);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = exp(txt, i_rhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end exp;

public function oper
  input Tpl.Text in_txt;
  input Example.Operator in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           Example.PLUS() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
      then txt;

    case ( txt,
           Example.TIMES() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("*"));
      then txt;

    case ( txt,
           Example.LESS() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("<"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end oper;

protected function fun_5
  input Tpl.Text in_txt;
  input Option<Integer> in_i_val;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_val)
    local
      Tpl.Text txt;

    case ( txt,
           SOME(i_val) )
      local
        Integer i_val;
      equation
        txt = Tpl.writeStr(txt, intString(i_val));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_5;

public function opt
  input Tpl.Text in_txt;
  input Option<Option<Integer>> in_i_ho;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ho)
    local
      Tpl.Text txt;

    case ( txt,
           SOME(i_val) )
      local
        Option<Integer> i_val;
      equation
        txt = fun_5(txt, i_val);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end opt;

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
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeStr(txt, intString(i_i0));
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

public function pok
  input Tpl.Text txt;
  input list<String> i_names;
  input Integer i_i0;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeStr(txt, intString(i_i0));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" "));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_7(out_txt, i_names);
  out_txt := Tpl.popIter(out_txt);
end pok;

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
           "a" :: rest )
      local
        list<String> rest;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeStr(txt, intString(i_i0));
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

public function pok2
  input Tpl.Text txt;
  input list<String> i_names;
  input String i_sep;

  output Tpl.Text out_txt;
  protected
    Tpl.StringToken ret_1;
    Tpl.Text txt_0;
algorithm
  txt_0 := Tpl.writeTok(emptyTxt, Tpl.ST_STRING("o"));
  txt_0 := Tpl.writeStr(txt_0, i_sep);
  ret_1 := Tpl.textStrTok(txt_0);
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(ret_1), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_9(out_txt, i_names);
  out_txt := Tpl.popIter(out_txt);
end pok2;

protected function lm_11
  input Tpl.Text in_txt;
  input list<Example.Exp> in_items;

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
           Example.ICONST(value = i_value) :: rest )
      local
        list<Example.Exp> rest;
        Integer i_value;
      equation
        txt = Tpl.writeStr(txt, intString(i_value));
        txt = Tpl.nextIter(txt);
        txt = lm_11(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Example.Exp> rest;
      equation
        txt = lm_11(txt, rest);
      then txt;
  end matchcontinue;
end lm_11;

public function pok3
  input Tpl.Text txt;
  input list<Example.Exp> i_exps;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_11(out_txt, i_exps);
  out_txt := Tpl.popIter(out_txt);
end pok3;

public function pok4
  input Tpl.Text txt;
  input String i_s;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeStr(txt, i_s);
end pok4;

public function pok5
  input Tpl.Text txt;
  input String i_a;
  input Integer i_it#Error-displaced it#;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeStr(txt, i_a);
end pok5;

protected function smf_15
  input Tpl.Text in_txt;
  input tuple<Integer, String> in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           (i_i, i_s) )
      local
        String i_s;
        Integer i_i;
      equation
        txt = Tpl.writeStr(txt, intString(i_i));
        txt = Tpl.writeStr(txt, i_s);
      then txt;
  end matchcontinue;
end smf_15;

public function pok6
  input Tpl.Text txt;
  input tuple<Integer, String> i_tup;

  output Tpl.Text out_txt;
algorithm
  out_txt := smf_15(txt, i_tup);
end pok6;

protected function smf_17
  input Tpl.Text in_txt;
  input tuple<String, Integer> in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           (i_s, _) )
      local
        String i_s;
      equation
        txt = Tpl.writeStr(txt, i_s);
      then txt;
  end matchcontinue;
end smf_17;

protected function lm_18
  input Tpl.Text in_txt;
  input list<tuple<String, Integer>> in_items;

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
           (it as (i_s, i_i)) :: rest )
      local
        list<tuple<String, Integer>> rest;
        Integer i_i;
        String i_s;
        tuple<String, Integer> it;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("o"));
        txt = smf_17(txt, it);
        txt = lm_18(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<tuple<String, Integer>> rest;
      equation
        txt = lm_18(txt, rest);
      then txt;
  end matchcontinue;
end lm_18;

public function pok7
  input Tpl.Text txt;
  input list<tuple<String, Integer>> i_tuples;

  output Tpl.Text out_txt;
algorithm
  out_txt := lm_18(txt, i_tuples);
end pok7;

public function pok8
  input Tpl.Text txt;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushBlock(txt, Tpl.BT_INDENT(3));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("blabla"));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("hej you!"));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "  juchi"
                                   }, false));
  out_txt := Tpl.popBlock(out_txt);
end pok8;

end paper;