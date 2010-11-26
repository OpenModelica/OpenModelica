package Unparsing

public import Tpl;

public import SimCode;
public import BackendDAE;
public import System;
public import Absyn;
public import DAE;
public import ClassInf;
public import SCode;
public import Util;
public import ComponentReference;
public import Expression;
public import RTOpts;
public import Settings;

protected function lm_14
  input Tpl.Text in_txt;
  input SCode.Program in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      SCode.Program rest;
      SCode.Class i_cl;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_cl :: rest )
      equation
        txt = classExternalHeader(txt, i_cl, "");
        txt = lm_14(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_14(txt, rest);
      then txt;
  end matchcontinue;
end lm_14;

public function programExternalHeader
  input Tpl.Text txt;
  input SCode.Program a_program;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "/* Automatically generated header for external MetaModelica functions */\n",
                                   "#ifdef __cplusplus\n",
                                   "extern \"C\" {\n",
                                   "#endif\n"
                               }, true));
  out_txt := lm_14(out_txt, a_program);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "#ifdef __cplusplus\n",
                                       "}\n",
                                       "#endif"
                                   }, false));
end programExternalHeader;

protected function lm_16
  input Tpl.Text in_txt;
  input list<SCode.Element> in_items;
  input SCode.Ident in_a_c_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_a_c_name)
    local
      Tpl.Text txt;
      list<SCode.Element> rest;
      SCode.Ident a_c_name;
      SCode.Element i_elt;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           i_elt :: rest,
           a_c_name )
      equation
        txt = elementExternalHeader(txt, i_elt, a_c_name);
        txt = lm_16(txt, rest, a_c_name);
      then txt;

    case ( txt,
           _ :: rest,
           a_c_name )
      equation
        txt = lm_16(txt, rest, a_c_name);
      then txt;
  end matchcontinue;
end lm_16;

protected function fun_17
  input Tpl.Text in_txt;
  input SCode.Class in_a_cl;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_cl)
    local
      Tpl.Text txt;
      SCode.Ident i_c_name;
      list<SCode.Element> i_p_elementLst;

    case ( txt,
           SCode.CLASS(classDef = SCode.PARTS(elementLst = i_p_elementLst), name = i_c_name) )
      equation
        txt = lm_16(txt, i_p_elementLst, i_c_name);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_17;

public function classExternalHeader
  input Tpl.Text txt;
  input SCode.Class a_cl;
  input String a_pack;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_17(txt, a_cl);
end classExternalHeader;

public function pathString
  input Tpl.Text in_txt;
  input Absyn.Path in_a_path;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_path)
    local
      Tpl.Text txt;
      Absyn.Path i_path;
      Absyn.Ident i_name;

    case ( txt,
           Absyn.IDENT(name = i_name) )
      equation
        txt = Tpl.writeStr(txt, i_name);
      then txt;

    case ( txt,
           Absyn.QUALIFIED(name = i_name, path = i_path) )
      equation
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = pathString(txt, i_path);
      then txt;

    case ( txt,
           Absyn.FULLYQUALIFIED(path = i_path) )
      equation
        txt = pathString(txt, i_path);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end pathString;

protected function lm_20
  input Tpl.Text in_txt;
  input list<SCode.Element> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SCode.Element> rest;
      SCode.Ident i_component;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SCode.COMPONENT(component = i_component) :: rest )
      equation
        txt = Tpl.writeStr(txt, i_component);
        txt = Tpl.nextIter(txt);
        txt = lm_20(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_20(txt, rest);
      then txt;
  end matchcontinue;
end lm_20;

protected function lm_21
  input Tpl.Text in_txt;
  input list<SCode.Element> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SCode.Element> rest;
      SCode.Ident i_component;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SCode.COMPONENT(component = i_component) :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.writeStr(txt, i_component);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.nextIter(txt);
        txt = lm_21(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_21(txt, rest);
      then txt;
  end matchcontinue;
end lm_21;

protected function fun_22
  input Tpl.Text in_txt;
  input list<SCode.Element> in_a_p_elementLst;
  input Tpl.Text in_a_fields;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_p_elementLst, in_a_fields)
    local
      Tpl.Text txt;
      Tpl.Text a_fields;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           _,
           a_fields )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_fields);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;
  end matchcontinue;
end fun_22;

protected function fun_23
  input Tpl.Text in_txt;
  input list<SCode.Element> in_a_p_elementLst;
  input Tpl.Text in_a_fields;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_p_elementLst, in_a_fields)
    local
      Tpl.Text txt;
      Tpl.Text a_fields;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           _,
           a_fields )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, a_fields);
      then txt;
  end matchcontinue;
end fun_23;

public function elementExternalHeader
  input Tpl.Text in_txt;
  input SCode.Element in_a_elt;
  input String in_a_pack;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_elt, in_a_pack)
    local
      Tpl.Text txt;
      String a_pack;
      SCode.Class i_classDef;
      Integer i_r_index;
      SCode.Ident i_c_name;
      Absyn.Path i_r_name;
      list<SCode.Element> i_p_elementLst;
      Integer ret_11;
      Integer ret_10;
      Integer ret_9;
      String ret_8;
      Integer ret_7;
      String ret_6;
      Integer ret_5;
      Tpl.Text l_nElts;
      String ret_3;
      Tpl.Text l_omcname;
      Tpl.Text l_fieldsStr;
      Tpl.Text l_fields;

    case ( txt,
           SCode.CLASSDEF(classDef = SCode.CLASS(restriction = SCode.R_METARECORD(name = i_r_name, index = i_r_index), classDef = SCode.PARTS(elementLst = i_p_elementLst), name = i_c_name)),
           a_pack )
      equation
        l_fields = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(",")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        l_fields = lm_20(l_fields, i_p_elementLst);
        l_fields = Tpl.popIter(l_fields);
        l_fieldsStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(",")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        l_fieldsStr = lm_21(l_fieldsStr, i_p_elementLst);
        l_fieldsStr = Tpl.popIter(l_fieldsStr);
        l_omcname = Tpl.writeStr(Tpl.emptyTxt, a_pack);
        l_omcname = Tpl.writeTok(l_omcname, Tpl.ST_STRING("_"));
        l_omcname = pathString(l_omcname, i_r_name);
        l_omcname = Tpl.writeTok(l_omcname, Tpl.ST_STRING("_"));
        ret_3 = System.stringReplace(i_c_name, "_", "__");
        l_omcname = Tpl.writeStr(l_omcname, ret_3);
        ret_5 = listLength(i_p_elementLst);
        l_nElts = Tpl.writeStr(Tpl.emptyTxt, intString(ret_5));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "#ifdef ADD_METARECORD_DEFINTIONS\n",
                                    "#ifndef "
                                }, false));
        txt = Tpl.writeText(txt, l_omcname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "__desc_added\n",
                                    "#define "
                                }, false));
        txt = Tpl.writeText(txt, l_omcname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "__desc_added\n",
                                    "const char* "
                                }, false));
        txt = Tpl.writeText(txt, l_omcname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("__desc__fields["));
        txt = Tpl.writeText(txt, l_nElts);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = {"));
        txt = Tpl.writeText(txt, l_fieldsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "};\n",
                                    "struct record_description "
                                }, false));
        txt = Tpl.writeText(txt, l_omcname);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("__desc = {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.writeText(txt, l_omcname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\",\n",
                                    "\""
                                }, false));
        txt = Tpl.writeStr(txt, a_pack);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = pathString(txt, i_r_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeStr(txt, i_c_name);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("\",\n"));
        txt = Tpl.writeText(txt, l_omcname);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("__desc__fields\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "};\n",
                                    "#endif\n",
                                    "#else /* Only use the file as a header */\n",
                                    "extern struct record_description "
                                }, false));
        txt = Tpl.writeText(txt, l_omcname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "__desc;\n",
                                    "#endif\n",
                                    "#define "
                                }, false));
        txt = Tpl.writeStr(txt, a_pack);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("__"));
        ret_6 = System.stringReplace(i_c_name, "_", "_5f");
        txt = Tpl.writeStr(txt, ret_6);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_3dBOX"));
        txt = Tpl.writeText(txt, l_nElts);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        ret_7 = intAdd(3, i_r_index);
        txt = Tpl.writeStr(txt, intString(ret_7));
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = Tpl.writeStr(txt, a_pack);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("__"));
        ret_8 = System.stringReplace(i_c_name, "_", "_5f");
        txt = Tpl.writeStr(txt, ret_8);
        txt = fun_22(txt, i_p_elementLst, l_fields);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" (mmc_mk_box"));
        ret_9 = listLength(i_p_elementLst);
        ret_10 = intAdd(1, ret_9);
        txt = Tpl.writeStr(txt, intString(ret_10));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        ret_11 = intAdd(3, i_r_index);
        txt = Tpl.writeStr(txt, intString(ret_11));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(",&"));
        txt = Tpl.writeText(txt, l_omcname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("__desc"));
        txt = fun_23(txt, i_p_elementLst, l_fields);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           SCode.CLASSDEF(classDef = i_classDef),
           a_pack )
      equation
        txt = classExternalHeader(txt, i_classDef, a_pack);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end elementExternalHeader;

end Unparsing;