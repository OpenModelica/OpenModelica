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

protected function lm_2
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
        txt = lm_2(txt, rest);
      then txt;
  end matchcontinue;
end lm_2;

public function typedIdents
  input Tpl.Text txt;
  input TplAbsyn.TypedIdents i_decls;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_2(out_txt, i_decls);
  out_txt := Tpl.popIter(out_txt);
end typedIdents;

end test;