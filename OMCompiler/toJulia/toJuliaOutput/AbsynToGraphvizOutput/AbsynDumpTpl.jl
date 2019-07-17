  module AbsynDumpTpl


    using MetaModelica
    #= ExportAll is not good practice but it makes it so that we do not have to write export after each function :( =#
    using ExportAll

        import Tpl

        import Absyn

        import AbsynUtil

        import Config

        import Dump

        import System

        import Flags

        function lm_8(in_txt::Tpl.Text, in_items::IList, in_a_options::Dump.DumpOptions)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local a_options::Dump.DumpOptions
                  local i_cls::Absyn.Class
                @match (in_txt, in_items, in_a_options) begin
                  (txt,  nil(), _)  => begin
                    txt
                  end

                  (txt, i_cls <| rest, a_options)  => begin
                      txt = dumpClass(txt, i_cls, a_options)
                      txt = Tpl.nextIter(txt)
                      txt = lm_8(txt, rest, a_options)
                    txt
                  end
                end
              end
          out_txt
        end

        function dump(in_txt::Tpl.Text, in_a_program::Absyn.Program, in_a_options::Dump.DumpOptions)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_options::Dump.DumpOptions
                  local i_classes::IList
                  local i_within__::Absyn.Within
                  local l_cls__str::Tpl.Text
                  local l_within__str::Tpl.Text
                @match (in_txt, in_a_program, in_a_options) begin
                  (txt, Absyn.PROGRAM(classes =  nil()), _)  => begin
                    txt
                  end

                  (txt, Absyn.PROGRAM(within_ = i_within__, classes = i_classes), a_options)  => begin
                      l_within__str = dumpWithin(Tpl.emptyTxt, i_within__)
                      l_cls__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING_LIST(list(";\n", "\n"), true)), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_cls__str = lm_8(l_cls__str, i_classes, a_options)
                      l_cls__str = Tpl.popIter(l_cls__str)
                      txt = Tpl.writeText(txt, l_within__str)
                      txt = Tpl.writeText(txt, l_cls__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"))
                    txt
                  end

                  (txt, _, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpClass(txt::Tpl.Text, a_cls::Absyn.Class, a_options::Dump.DumpOptions)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = dumpClassElement(txt, a_cls, "", "", "", "", a_options)
          out_txt
        end

        function dumpWithin(in_txt::Tpl.Text, in_a_within::Absyn.Within)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_path::Absyn.Path
                  local l_path__str::Tpl.Text
                @match (in_txt, in_a_within) begin
                  (txt, Absyn.TOP())  => begin
                    txt
                  end

                  (txt, Absyn.WITHIN(path = i_path))  => begin
                      l_path__str = dumpPath(Tpl.emptyTxt, i_path)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("within "))
                      txt = Tpl.writeText(txt, l_path__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST(list(";\n", "\n"), true))
                    txt
                  end

                  (txt, _)  => begin
                      Tpl.addSourceTemplateError("Unknown operation", Tpl.sourceInfo("AbsynDumpTpl.tpl", 29, 56))
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpClassHeader(in_txt::Tpl.Text, in_a_cls::Absyn.Class, in_a_final__str::String, in_a_redecl__str::String, in_a_repl__str::String, in_a_io__str::String)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_final__str::String
                  local a_redecl__str::String
                  local a_repl__str::String
                  local a_io__str::String
                  local i_cls::Absyn.Class
                  local i_restriction::Absyn.Restriction
                  local l_pref__str::Tpl.Text
                  local l_res__str::Tpl.Text
                @match (in_txt, in_a_cls, in_a_final__str, in_a_redecl__str, in_a_repl__str, in_a_io__str) begin
                  (txt, i_cls && Absyn.CLASS(restriction = i_restriction), a_final__str, a_redecl__str, a_repl__str, a_io__str)  => begin
                      l_res__str = dumpRestriction(Tpl.emptyTxt, i_restriction)
                      l_pref__str = dumpClassPrefixes(Tpl.emptyTxt, i_cls, a_final__str, a_redecl__str, a_repl__str, a_io__str)
                      txt = Tpl.writeText(txt, l_pref__str)
                      txt = Tpl.writeText(txt, l_res__str)
                    txt
                  end

                  (txt, _, _, _, _, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpClassElement(in_txt::Tpl.Text, in_a_cls::Absyn.Class, in_a_final__str::String, in_a_redecl__str::String, in_a_repl__str::String, in_a_io__str::String, in_a_options::Dump.DumpOptions)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_final__str::String
                  local a_redecl__str::String
                  local a_repl__str::String
                  local a_io__str::String
                  local a_options::Dump.DumpOptions
                  local i_name::Absyn.Ident
                  local i_body::Absyn.ClassDef
                  local i_cls::Absyn.Class
                  local l_body__str::Tpl.Text
                  local l_header__str::Tpl.Text
                @match (in_txt, in_a_cls, in_a_final__str, in_a_redecl__str, in_a_repl__str, in_a_io__str, in_a_options) begin
                  (txt, i_cls && Absyn.CLASS(body = i_body, name = i_name), a_final__str, a_redecl__str, a_repl__str, a_io__str, a_options)  => begin
                      l_header__str = dumpClassHeader(Tpl.emptyTxt, i_cls, a_final__str, a_redecl__str, a_repl__str, a_io__str)
                      l_body__str = dumpClassDef(Tpl.emptyTxt, i_body, i_name, a_options)
                      txt = Tpl.writeText(txt, l_header__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "))
                      txt = Tpl.writeText(txt, l_body__str)
                    txt
                  end

                  (txt, _, _, _, _, _, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_14(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_typevar::String
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_typevar <| rest)  => begin
                      txt = Tpl.writeStr(txt, i_typevar)
                      txt = Tpl.nextIter(txt)
                      txt = lm_14(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_15(in_txt::Tpl.Text, in_a_typeVars::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_typeVars::IList
                @match (in_txt, in_a_typeVars) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_typeVars)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("<"))
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_14(txt, i_typeVars)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(">"))
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_16(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_a::Absyn.Annotation
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_a <| rest)  => begin
                      txt = dumpAnnotation(txt, i_a)
                      txt = Tpl.nextIter(txt)
                      txt = lm_16(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_17(in_txt::Tpl.Text, in_items::IList, in_a_options::Dump.DumpOptions)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local a_options::Dump.DumpOptions
                  local x_idx::ModelicaInteger
                  local i_class__part::Absyn.ClassPart
                @match (in_txt, in_items, in_a_options) begin
                  (txt,  nil(), _)  => begin
                    txt
                  end

                  (txt, i_class__part <| rest, a_options)  => begin
                      x_idx = Tpl.getIteri_i0(txt)
                      txt = dumpClassPart(txt, i_class__part, x_idx, a_options)
                      txt = Tpl.nextIter(txt)
                      txt = lm_17(txt, rest, a_options)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_18(in_txt::Tpl.Text, in_a_ann__str::Tpl.Text)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_ann__str::Tpl.Text
                @match (in_txt, in_a_ann__str) begin
                  (txt, Tpl.MEM_TEXT(tokens =  nil()))  => begin
                    txt
                  end

                  (txt, i_ann__str)  => begin
                      txt = Tpl.writeText(txt, i_ann__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"))
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_19(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_arg::Absyn.ElementArg
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_arg <| rest)  => begin
                      txt = dumpElementArg(txt, i_arg)
                      txt = Tpl.nextIter(txt)
                      txt = lm_19(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_20(in_txt::Tpl.Text, in_a_arguments::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_arguments::IList
                @match (in_txt, in_a_arguments) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_arguments)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("("))
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_19(txt, i_arguments)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_21(in_txt::Tpl.Text, in_items::IList, in_a_options::Dump.DumpOptions)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local a_options::Dump.DumpOptions
                  local x_idx::ModelicaInteger
                  local i_class__part::Absyn.ClassPart
                @match (in_txt, in_items, in_a_options) begin
                  (txt,  nil(), _)  => begin
                    txt
                  end

                  (txt, i_class__part <| rest, a_options)  => begin
                      x_idx = Tpl.getIteri_i0(txt)
                      txt = dumpClassPart(txt, i_class__part, x_idx, a_options)
                      txt = Tpl.nextIter(txt)
                      txt = lm_21(txt, rest, a_options)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_22(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_mod::Absyn.ElementArg
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_mod <| rest)  => begin
                      txt = dumpElementArg(txt, i_mod)
                      txt = Tpl.nextIter(txt)
                      txt = lm_22(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_23(in_txt::Tpl.Text, in_a_modifications::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_modifications::IList
                @match (in_txt, in_a_modifications) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_modifications)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("("))
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_22(txt, i_modifications)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_24(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_a::Absyn.Annotation
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_a <| rest)  => begin
                      txt = dumpAnnotation(txt, i_a)
                      txt = Tpl.nextIter(txt)
                      txt = lm_24(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_25(in_txt::Tpl.Text, in_a_ann__str::Tpl.Text)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_ann__str::Tpl.Text
                @match (in_txt, in_a_ann__str) begin
                  (txt, Tpl.MEM_TEXT(tokens =  nil()))  => begin
                    txt
                  end

                  (txt, i_ann__str)  => begin
                      txt = Tpl.writeText(txt, i_ann__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"))
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_26(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_fn::Absyn.Path
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_fn <| rest)  => begin
                      txt = dumpPath(txt, i_fn)
                      txt = Tpl.nextIter(txt)
                      txt = lm_26(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_27(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_var::Absyn.Ident
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_var <| rest)  => begin
                      txt = Tpl.writeStr(txt, i_var)
                      txt = Tpl.nextIter(txt)
                      txt = lm_27(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpClassDef(in_txt::Tpl.Text, in_a_cdef::Absyn.ClassDef, in_a_cls__name::String, in_a_options::Dump.DumpOptions)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_cls__name::String
                  local a_options::Dump.DumpOptions
                  local i_vars::IList
                  local i_functionName::Absyn.Path
                  local i_functionNames::IList
                  local i_enumLiterals::Absyn.EnumDef
                  local i_baseClassName::Absyn.Ident
                  local i_modifications::IList
                  local i_parts::IList
                  local i_comment_1::Option
                  local i_arguments::IList
                  local i_typeSpec::Absyn.TypeSpec
                  local i_attributes::Absyn.ElementAttributes
                  local i_classParts::IList
                  local i_comment::Option
                  local i_ann::IList
                  local i_typeVars::IList
                  local l_vars__str::Tpl.Text
                  local l_fn__str::Tpl.Text
                  local l_funcs__str::Tpl.Text
                  local l_enum__str::Tpl.Text
                  local ret_8::IList
                  local l_mod__str::Tpl.Text
                  local l_ty__str::Tpl.Text
                  local l_attr__str::Tpl.Text
                  local l_body__str::Tpl.Text
                  local l_cmt__str::Tpl.Text
                  local ret_2::IList
                  local l_ann__str::Tpl.Text
                  local l_tvs__str::Tpl.Text
                @match (in_txt, in_a_cdef, in_a_cls__name, in_a_options) begin
                  (txt, Absyn.PARTS(typeVars = i_typeVars, ann = i_ann, comment = i_comment, classParts = i_classParts), a_cls__name, a_options)  => begin
                      l_tvs__str = fun_15(Tpl.emptyTxt, i_typeVars)
                      ret_2 = listReverse(i_ann)
                      l_ann__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(";\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_ann__str = lm_16(l_ann__str, ret_2)
                      l_ann__str = Tpl.popIter(l_ann__str)
                      l_cmt__str = dumpStringCommentOption(Tpl.emptyTxt, i_comment)
                      l_body__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING("")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_body__str = lm_17(l_body__str, i_classParts, a_options)
                      l_body__str = Tpl.popIter(l_body__str)
                      txt = Tpl.writeStr(txt, a_cls__name)
                      txt = Tpl.writeText(txt, l_tvs__str)
                      txt = Tpl.writeText(txt, l_cmt__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE())
                      txt = Tpl.writeText(txt, l_body__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = fun_18(txt, l_ann__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.popBlock(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("end "))
                      txt = Tpl.writeStr(txt, a_cls__name)
                    txt
                  end

                  (txt, Absyn.DERIVED(attributes = i_attributes, typeSpec = i_typeSpec, arguments = i_arguments, comment = i_comment_1), a_cls__name, _)  => begin
                      l_attr__str = dumpElementAttr(Tpl.emptyTxt, i_attributes)
                      l_ty__str = dumpTypeSpec(Tpl.emptyTxt, i_typeSpec)
                      l_mod__str = fun_20(Tpl.emptyTxt, i_arguments)
                      l_cmt__str = dumpCommentOpt(Tpl.emptyTxt, i_comment_1)
                      txt = Tpl.writeStr(txt, a_cls__name)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "))
                      txt = Tpl.writeText(txt, l_attr__str)
                      txt = Tpl.writeText(txt, l_ty__str)
                      txt = Tpl.writeText(txt, l_mod__str)
                      txt = Tpl.writeText(txt, l_cmt__str)
                    txt
                  end

                  (txt, Absyn.CLASS_EXTENDS(parts = i_parts, modifications = i_modifications, comment = i_comment, ann = i_ann, baseClassName = i_baseClassName), a_cls__name, a_options)  => begin
                      l_body__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_body__str = lm_21(l_body__str, i_parts, a_options)
                      l_body__str = Tpl.popIter(l_body__str)
                      l_mod__str = fun_23(Tpl.emptyTxt, i_modifications)
                      l_cmt__str = dumpStringCommentOption(Tpl.emptyTxt, i_comment)
                      ret_8 = listReverse(i_ann)
                      l_ann__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(";\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_ann__str = lm_24(l_ann__str, ret_8)
                      l_ann__str = Tpl.popIter(l_ann__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("extends "))
                      txt = Tpl.writeStr(txt, i_baseClassName)
                      txt = Tpl.writeText(txt, l_mod__str)
                      txt = Tpl.writeText(txt, l_cmt__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.writeText(txt, l_body__str)
                      txt = Tpl.softNewLine(txt)
                      txt = fun_25(txt, l_ann__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.popBlock(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("end "))
                      txt = Tpl.writeStr(txt, a_cls__name)
                    txt
                  end

                  (txt, Absyn.ENUMERATION(enumLiterals = i_enumLiterals, comment = i_comment_1), a_cls__name, _)  => begin
                      l_enum__str = dumpEnumDef(Tpl.emptyTxt, i_enumLiterals)
                      l_cmt__str = dumpCommentOpt(Tpl.emptyTxt, i_comment_1)
                      txt = Tpl.writeStr(txt, a_cls__name)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = enumeration("))
                      txt = Tpl.writeText(txt, l_enum__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                      txt = Tpl.writeText(txt, l_cmt__str)
                    txt
                  end

                  (txt, Absyn.OVERLOAD(functionNames = i_functionNames, comment = i_comment_1), a_cls__name, _)  => begin
                      l_funcs__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_funcs__str = lm_26(l_funcs__str, i_functionNames)
                      l_funcs__str = Tpl.popIter(l_funcs__str)
                      l_cmt__str = dumpCommentOpt(Tpl.emptyTxt, i_comment_1)
                      txt = Tpl.writeStr(txt, a_cls__name)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = overload("))
                      txt = Tpl.writeText(txt, l_funcs__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                      txt = Tpl.writeText(txt, l_cmt__str)
                    txt
                  end

                  (txt, Absyn.PDER(functionName = i_functionName, vars = i_vars), a_cls__name, _)  => begin
                      l_fn__str = dumpPath(Tpl.emptyTxt, i_functionName)
                      l_vars__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_vars__str = lm_27(l_vars__str, i_vars)
                      l_vars__str = Tpl.popIter(l_vars__str)
                      txt = Tpl.writeStr(txt, a_cls__name)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = der("))
                      txt = Tpl.writeText(txt, l_fn__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "))
                      txt = Tpl.writeText(txt, l_vars__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end

                  (txt, _, _, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_29(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_lit::Absyn.EnumLiteral
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_lit <| rest)  => begin
                      txt = dumpEnumLiteral(txt, i_lit)
                      txt = Tpl.nextIter(txt)
                      txt = lm_29(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpEnumDef(in_txt::Tpl.Text, in_a_enum__def::Absyn.EnumDef)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_enumLiterals::IList
                @match (in_txt, in_a_enum__def) begin
                  (txt, Absyn.ENUMLITERALS(enumLiterals = i_enumLiterals))  => begin
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_29(txt, i_enumLiterals)
                      txt = Tpl.popIter(txt)
                    txt
                  end

                  (txt, Absyn.ENUM_COLON())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(":"))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpEnumLiteral(in_txt::Tpl.Text, in_a_lit::Absyn.EnumLiteral)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_literal::Absyn.Ident
                  local i_comment::Option
                  local l_cmt__str::Tpl.Text
                @match (in_txt, in_a_lit) begin
                  (txt, Absyn.ENUMLITERAL(comment = i_comment, literal = i_literal))  => begin
                      l_cmt__str = dumpCommentOpt(Tpl.emptyTxt, i_comment)
                      txt = Tpl.writeStr(txt, i_literal)
                      txt = Tpl.writeText(txt, l_cmt__str)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_32(in_txt::Tpl.Text, in_a_encapsulatedPrefix::Bool)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_encapsulatedPrefix) begin
                  (txt, false)  => begin
                    txt
                  end

                  (txt, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("encapsulated "))
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_33(in_txt::Tpl.Text, in_a_partialPrefix::Bool)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_partialPrefix) begin
                  (txt, false)  => begin
                    txt
                  end

                  (txt, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("partial "))
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_34(in_txt::Tpl.Text, in_a_cls::Absyn.Class, in_a_redecl__str::String, in_a_repl__str::String, in_a_io__str::String)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_redecl__str::String
                  local a_repl__str::String
                  local a_io__str::String
                  local i_finalPrefix::Bool
                  local i_partialPrefix::Bool
                  local i_encapsulatedPrefix::Bool
                  local l_fin__str::Tpl.Text
                  local l_partial__str::Tpl.Text
                  local l_enc__str::Tpl.Text
                @match (in_txt, in_a_cls, in_a_redecl__str, in_a_repl__str, in_a_io__str) begin
                  (txt, Absyn.CLASS(encapsulatedPrefix = i_encapsulatedPrefix, partialPrefix = i_partialPrefix, finalPrefix = i_finalPrefix), a_redecl__str, a_repl__str, a_io__str)  => begin
                      l_enc__str = fun_32(Tpl.emptyTxt, i_encapsulatedPrefix)
                      l_partial__str = fun_33(Tpl.emptyTxt, i_partialPrefix)
                      l_fin__str = dumpFinal(Tpl.emptyTxt, i_finalPrefix)
                      txt = Tpl.writeStr(txt, a_redecl__str)
                      txt = Tpl.writeText(txt, l_fin__str)
                      txt = Tpl.writeStr(txt, a_io__str)
                      txt = Tpl.writeStr(txt, a_repl__str)
                      txt = Tpl.writeText(txt, l_enc__str)
                      txt = Tpl.writeText(txt, l_partial__str)
                    txt
                  end

                  (txt, _, _, _, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpClassPrefixes(txt::Tpl.Text, a_cls::Absyn.Class, a_final__str::String, a_redecl__str::String, a_repl__str::String, a_io__str::String)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = fun_34(txt, a_cls, a_redecl__str, a_repl__str, a_io__str)
          out_txt
        end

        function fun_36(in_txt::Tpl.Text, in_a_functionRestriction::Absyn.FunctionRestriction)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_functionRestriction) begin
                  (txt, Absyn.FR_NORMAL_FUNCTION(purity = Absyn.IMPURE()))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("impure "))
                    txt
                  end

                  (txt, Absyn.FR_NORMAL_FUNCTION(purity = Absyn.PURE()))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("pure "))
                    txt
                  end

                  (txt, Absyn.FR_NORMAL_FUNCTION(purity = Absyn.NO_PURITY()))  => begin
                    txt
                  end

                  (txt, Absyn.FR_OPERATOR_FUNCTION())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("operator "))
                    txt
                  end

                  (txt, Absyn.FR_PARALLEL_FUNCTION())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("parallel "))
                    txt
                  end

                  (txt, Absyn.FR_KERNEL_FUNCTION())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("kernel "))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_37(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_tv::String
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_tv <| rest)  => begin
                      txt = Tpl.writeStr(txt, i_tv)
                      txt = Tpl.nextIter(txt)
                      txt = lm_37(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_38(in_txt::Tpl.Text, in_a_typeVars::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_typeVars::IList
                @match (in_txt, in_a_typeVars) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_typeVars)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("<"))
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(",")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_37(txt, i_typeVars)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(">"))
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpRestriction(in_txt::Tpl.Text, in_a_restriction::Absyn.Restriction)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_typeVars::IList
                  local i_functionRestriction::Absyn.FunctionRestriction
                  local l_prefix__str::Tpl.Text
                @match (in_txt, in_a_restriction) begin
                  (txt, Absyn.R_CLASS())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("class"))
                    txt
                  end

                  (txt, Absyn.R_OPTIMIZATION())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("optimization"))
                    txt
                  end

                  (txt, Absyn.R_MODEL())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("model"))
                    txt
                  end

                  (txt, Absyn.R_RECORD())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("record"))
                    txt
                  end

                  (txt, Absyn.R_BLOCK())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("block"))
                    txt
                  end

                  (txt, Absyn.R_CONNECTOR())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("connector"))
                    txt
                  end

                  (txt, Absyn.R_EXP_CONNECTOR())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("expandable connector"))
                    txt
                  end

                  (txt, Absyn.R_TYPE())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("type"))
                    txt
                  end

                  (txt, Absyn.R_PACKAGE())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("package"))
                    txt
                  end

                  (txt, Absyn.R_FUNCTION(functionRestriction = i_functionRestriction))  => begin
                      l_prefix__str = fun_36(Tpl.emptyTxt, i_functionRestriction)
                      txt = Tpl.writeText(txt, l_prefix__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("function"))
                    txt
                  end

                  (txt, Absyn.R_OPERATOR())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("operator"))
                    txt
                  end

                  (txt, Absyn.R_OPERATOR_RECORD())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("operator record"))
                    txt
                  end

                  (txt, Absyn.R_ENUMERATION())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("enumeration"))
                    txt
                  end

                  (txt, Absyn.R_PREDEFINED_INTEGER())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("Integer"))
                    txt
                  end

                  (txt, Absyn.R_PREDEFINED_REAL())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("Real"))
                    txt
                  end

                  (txt, Absyn.R_PREDEFINED_STRING())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("String"))
                    txt
                  end

                  (txt, Absyn.R_PREDEFINED_BOOLEAN())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("Boolean"))
                    txt
                  end

                  (txt, Absyn.R_PREDEFINED_ENUMERATION())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("enumeration(:)"))
                    txt
                  end

                  (txt, Absyn.R_UNIONTYPE())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("uniontype"))
                    txt
                  end

                  (txt, Absyn.R_METARECORD(typeVars = i_typeVars))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("metarecord"))
                      txt = fun_38(txt, i_typeVars)
                    txt
                  end

                  (txt, Absyn.R_UNKNOWN())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("*unknown*"))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_40(in_txt::Tpl.Text, in_a_idx::ModelicaInteger)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_idx) begin
                  (txt, 0)  => begin
                    txt
                  end

                  (txt, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("public"))
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_41(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_exp::Absyn.Exp
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_exp <| rest)  => begin
                      txt = dumpExp(txt, i_exp)
                      txt = Tpl.nextIter(txt)
                      txt = lm_41(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_42(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_eq::Absyn.EquationItem
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_eq <| rest)  => begin
                      txt = dumpEquationItem(txt, i_eq)
                      txt = Tpl.nextIter(txt)
                      txt = lm_42(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_43(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_eq::Absyn.EquationItem
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_eq <| rest)  => begin
                      txt = dumpEquationItem(txt, i_eq)
                      txt = Tpl.nextIter(txt)
                      txt = lm_43(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_44(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_eq::Absyn.AlgorithmItem
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_eq <| rest)  => begin
                      txt = dumpAlgorithmItem(txt, i_eq)
                      txt = Tpl.nextIter(txt)
                      txt = lm_44(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_45(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_eq::Absyn.AlgorithmItem
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_eq <| rest)  => begin
                      txt = dumpAlgorithmItem(txt, i_eq)
                      txt = Tpl.nextIter(txt)
                      txt = lm_45(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_46(in_txt::Tpl.Text, in_a_annotation__::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_ann::Absyn.Annotation
                @match (in_txt, in_a_annotation__) begin
                  (txt, SOME(i_ann))  => begin
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(1))
                      txt = dumpAnnotation(txt, i_ann)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"))
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_47(in_txt::Tpl.Text, in_a_funcName::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_fn::Absyn.Ident
                @match (in_txt, in_a_funcName) begin
                  (txt, SOME(i_fn))  => begin
                      txt = Tpl.writeStr(txt, i_fn)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_48(in_txt::Tpl.Text, in_a_lang::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_l::String
                @match (in_txt, in_a_lang) begin
                  (txt, SOME(i_l))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""))
                      txt = Tpl.writeStr(txt, i_l)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\" "))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_49(in_txt::Tpl.Text, in_a_output__::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_o::Absyn.ComponentRef
                @match (in_txt, in_a_output__) begin
                  (txt, SOME(i_o))  => begin
                      txt = dumpCref(txt, i_o)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_50(in_txt::Tpl.Text, in_a_fn__str::Tpl.Text)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_fn__str) begin
                  (txt, Tpl.MEM_TEXT(tokens =  nil()))  => begin
                    txt
                  end

                  (txt, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("()"))
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_51(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_arg::Absyn.Exp
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_arg <| rest)  => begin
                      txt = dumpExp(txt, i_arg)
                      txt = Tpl.nextIter(txt)
                      txt = lm_51(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_52(in_txt::Tpl.Text, in_a_args::IList, in_a_fn__str::Tpl.Text)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_fn__str::Tpl.Text
                  local i_args::IList
                @match (in_txt, in_a_args, in_a_fn__str) begin
                  (txt,  nil(), a_fn__str)  => begin
                      txt = fun_50(txt, a_fn__str)
                    txt
                  end

                  (txt, i_args, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("("))
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_51(txt, i_args)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_53(in_txt::Tpl.Text, in_a_externalDecl::Absyn.ExternalDecl, in_a_ann__str::Tpl.Text)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_ann__str::Tpl.Text
                  local i_annotation__::Option
                  local i_args::IList
                  local i_output__::Option
                  local i_lang::Option
                  local i_funcName::Option
                  local l_ann2__str::Tpl.Text
                  local l_args__str::Tpl.Text
                  local l_output__str::Tpl.Text
                  local l_lang__str::Tpl.Text
                  local l_fn__str::Tpl.Text
                @match (in_txt, in_a_externalDecl, in_a_ann__str) begin
                  (txt, Absyn.EXTERNALDECL(funcName = i_funcName, lang = i_lang, output_ = i_output__, args = i_args, annotation_ = i_annotation__), a_ann__str)  => begin
                      l_fn__str = fun_47(Tpl.emptyTxt, i_funcName)
                      l_lang__str = fun_48(Tpl.emptyTxt, i_lang)
                      l_output__str = fun_49(Tpl.emptyTxt, i_output__)
                      l_args__str = fun_52(Tpl.emptyTxt, i_args, l_fn__str)
                      l_ann2__str = dumpAnnotationOptSpace(Tpl.emptyTxt, i_annotation__)
                      txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE())
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("external "))
                      txt = Tpl.writeText(txt, l_lang__str)
                      txt = Tpl.writeText(txt, l_output__str)
                      txt = Tpl.writeText(txt, l_fn__str)
                      txt = Tpl.writeText(txt, l_args__str)
                      txt = Tpl.writeText(txt, l_ann2__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"))
                      txt = Tpl.writeText(txt, a_ann__str)
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, _, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpClassPart(in_txt::Tpl.Text, in_a_class__part::Absyn.ClassPart, in_a_idx::ModelicaInteger, in_a_options::Dump.DumpOptions)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_idx::ModelicaInteger
                  local a_options::Dump.DumpOptions
                  local i_externalDecl::Absyn.ExternalDecl
                  local i_annotation__::Option
                  local i_contents_3::IList
                  local i_contents_2::IList
                  local i_contents_1::IList
                  local i_contents::IList
                  local l_ann__str::Tpl.Text
                  local l_el__str::Tpl.Text
                  local l_section__str::Tpl.Text
                @match (in_txt, in_a_class__part, in_a_idx, in_a_options) begin
                  (txt, Absyn.PUBLIC(contents = i_contents), a_idx, a_options)  => begin
                      l_section__str = fun_40(Tpl.emptyTxt, a_idx)
                      l_el__str = dumpElementItems(Tpl.emptyTxt, i_contents, "", true, a_options)
                      txt = Tpl.writeText(txt, l_section__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.writeText(txt, l_el__str)
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, Absyn.PROTECTED(contents = i_contents), _, a_options)  => begin
                      l_el__str = dumpElementItems(Tpl.emptyTxt, i_contents, "", true, a_options)
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE("protected\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.writeText(txt, l_el__str)
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, Absyn.CONSTRAINTS(contents = i_contents_1), _, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE("constraint\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING("; ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_41(txt, i_contents_1)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, Absyn.EQUATIONS(contents = i_contents_2), _, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE("equation\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_42(txt, i_contents_2)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE())
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, Absyn.INITIALEQUATIONS(contents = i_contents_2), _, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE("initial equation\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_43(txt, i_contents_2)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE())
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, Absyn.ALGORITHMS(contents = i_contents_3), _, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE("algorithm\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_44(txt, i_contents_3)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE())
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, Absyn.INITIALALGORITHMS(contents = i_contents_3), _, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE("initial algorithm\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_45(txt, i_contents_3)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE())
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, Absyn.EXTERNAL(annotation_ = i_annotation__, externalDecl = i_externalDecl), _, _)  => begin
                      l_ann__str = fun_46(Tpl.emptyTxt, i_annotation__)
                      txt = fun_53(txt, i_externalDecl, l_ann__str)
                    txt
                  end

                  (txt, _, _, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_55(in_txt::Tpl.Text, in_a_first::Bool, in_a_prevSpacing::String, in_a_spacing::Tpl.Text)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_prevSpacing::String
                  local a_spacing::Tpl.Text
                @match (in_txt, in_a_first, in_a_prevSpacing, in_a_spacing) begin
                  (txt, false, a_prevSpacing, a_spacing)  => begin
                      txt = dumpElementItemPreSpacing(txt, Tpl.textString(a_spacing), a_prevSpacing)
                    txt
                  end

                  (txt, _, _, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_56(in_txt::Tpl.Text, in_a_rest__str::Tpl.Text, in_a_spacing::Tpl.Text)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_spacing::Tpl.Text
                @match (in_txt, in_a_rest__str, in_a_spacing) begin
                  (txt, Tpl.MEM_TEXT(tokens =  nil()), _)  => begin
                    txt
                  end

                  (txt, _, a_spacing)  => begin
                      txt = Tpl.writeText(txt, a_spacing)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_57(in_txt::Tpl.Text, in_a_rest__str::Tpl.Text)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_rest__str::Tpl.Text
                @match (in_txt, in_a_rest__str) begin
                  (txt, Tpl.MEM_TEXT(tokens =  nil()))  => begin
                    txt
                  end

                  (txt, i_rest__str)  => begin
                      txt = Tpl.writeText(txt, i_rest__str)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpElementItems(in_txt::Tpl.Text, in_a_items::IList, in_a_prevSpacing::String, in_a_first::Bool, in_a_options::Dump.DumpOptions)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_prevSpacing::String
                  local a_first::Bool
                  local a_options::Dump.DumpOptions
                  local i_rest__items::IList
                  local i_item::Absyn.ElementItem
                  local l_post__spacing::Tpl.Text
                  local l_rest__str::Tpl.Text
                  local l_item__str::Tpl.Text
                  local l_pre__spacing::Tpl.Text
                  local l_spacing::Tpl.Text
                @match (in_txt, in_a_items, in_a_prevSpacing, in_a_first, in_a_options) begin
                  (txt, i_item <| i_rest__items, a_prevSpacing, a_first, a_options)  => begin
                      l_spacing = dumpElementItemSpacing(Tpl.emptyTxt, i_item)
                      l_pre__spacing = fun_55(Tpl.emptyTxt, a_first, a_prevSpacing, l_spacing)
                      l_item__str = dumpElementItem(Tpl.emptyTxt, i_item, a_options)
                      l_rest__str = dumpElementItems(Tpl.emptyTxt, i_rest__items, Tpl.textString(l_spacing), false, a_options)
                      l_post__spacing = fun_56(Tpl.emptyTxt, l_rest__str, l_spacing)
                      txt = Tpl.writeText(txt, l_pre__spacing)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.writeText(txt, l_item__str)
                      txt = Tpl.writeText(txt, l_post__spacing)
                      txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE())
                      txt = fun_57(txt, l_rest__str)
                    txt
                  end

                  (txt, _, _, _, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_59(in_txt::Tpl.Text, in_a_prevSpacing::String, in_a_curSpacing::String)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_curSpacing::String
                @match (in_txt, in_a_prevSpacing, in_a_curSpacing) begin
                  (txt, "", a_curSpacing)  => begin
                      txt = Tpl.writeStr(txt, a_curSpacing)
                    txt
                  end

                  (txt, _, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpElementItemPreSpacing(txt::Tpl.Text, a_curSpacing::String, a_prevSpacing::String)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = fun_59(txt, a_prevSpacing, a_curSpacing)
          out_txt
        end

        function dumpElementItemSpacing(in_txt::Tpl.Text, in_a_item::Absyn.ElementItem)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_cdef::Absyn.ClassDef
                @match (in_txt, in_a_item) begin
                  (txt, Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(body = i_cdef)))))  => begin
                      txt = dumpClassDefSpacing(txt, i_cdef)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpClassDefSpacing(in_txt::Tpl.Text, in_a_cdef::Absyn.ClassDef)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_cdef) begin
                  (txt, Absyn.PARTS(typeVars = _))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE())
                    txt
                  end

                  (txt, Absyn.CLASS_EXTENDS(baseClassName = _))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE())
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpElementItem(in_txt::Tpl.Text, in_a_eitem::Absyn.ElementItem, in_a_options::Dump.DumpOptions)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_options::Dump.DumpOptions
                  local i_comment::String
                  local i_element::Absyn.Element
                  local ret_0::String
                @match (in_txt, in_a_eitem, in_a_options) begin
                  (txt, Absyn.ELEMENTITEM(element = i_element), a_options)  => begin
                      txt = dumpElement(txt, i_element, a_options)
                    txt
                  end

                  (txt, Absyn.LEXER_COMMENT(comment = i_comment), _)  => begin
                      ret_0 = System.trimWhitespace(i_comment)
                      txt = Tpl.writeStr(txt, ret_0)
                    txt
                  end

                  (txt, _, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_64(in_txt::Tpl.Text, in_a_redeclareKeywords::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_re::Absyn.RedeclareKeywords
                @match (in_txt, in_a_redeclareKeywords) begin
                  (txt, SOME(i_re))  => begin
                      txt = dumpRedeclare(txt, i_re)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_65(in_txt::Tpl.Text, in_a_redeclareKeywords::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_re::Absyn.RedeclareKeywords
                @match (in_txt, in_a_redeclareKeywords) begin
                  (txt, SOME(i_re))  => begin
                      txt = dumpReplaceable(txt, i_re)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_66(in_txt::Tpl.Text, in_a_constrainClass::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_cc::Absyn.ConstrainClass
                @match (in_txt, in_a_constrainClass) begin
                  (txt, SOME(i_cc))  => begin
                      txt = dumpConstrainClass(txt, i_cc)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_67(in_txt::Tpl.Text, in_mArg::Bool, in_a_constrainClass::Option, in_a_options::Dump.DumpOptions, in_a_specification::Absyn.ElementSpec, in_a_innerOuter::Absyn.InnerOuter, in_a_redeclareKeywords::Option, in_a_finalPrefix::Bool)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_constrainClass::Option
                  local a_options::Dump.DumpOptions
                  local a_specification::Absyn.ElementSpec
                  local a_innerOuter::Absyn.InnerOuter
                  local a_redeclareKeywords::Option
                  local a_finalPrefix::Bool
                  local l_cc__str::Tpl.Text
                  local l_ec__str::Tpl.Text
                  local l_io__str::Tpl.Text
                  local l_repl__str::Tpl.Text
                  local l_redecl__str::Tpl.Text
                  local l_final__str::Tpl.Text
                @match (in_txt, in_mArg, in_a_constrainClass, in_a_options, in_a_specification, in_a_innerOuter, in_a_redeclareKeywords, in_a_finalPrefix) begin
                  (txt, false, _, _, _, _, _, _)  => begin
                    txt
                  end

                  (txt, _, a_constrainClass, a_options, a_specification, a_innerOuter, a_redeclareKeywords, a_finalPrefix)  => begin
                      l_final__str = dumpFinal(Tpl.emptyTxt, a_finalPrefix)
                      l_redecl__str = fun_64(Tpl.emptyTxt, a_redeclareKeywords)
                      l_repl__str = fun_65(Tpl.emptyTxt, a_redeclareKeywords)
                      l_io__str = dumpInnerOuter(Tpl.emptyTxt, a_innerOuter)
                      l_ec__str = dumpElementSpec(Tpl.emptyTxt, a_specification, Tpl.textString(l_final__str), Tpl.textString(l_redecl__str), Tpl.textString(l_repl__str), Tpl.textString(l_io__str), a_options)
                      l_cc__str = fun_66(Tpl.emptyTxt, a_constrainClass)
                      txt = Tpl.writeText(txt, l_ec__str)
                      txt = Tpl.writeText(txt, l_cc__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"))
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_68(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_arg::Absyn.NamedArg
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_arg <| rest)  => begin
                      txt = dumpNamedArg(txt, i_arg)
                      txt = lm_68(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_69(in_txt::Tpl.Text, in_a_args::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_args::IList
                @match (in_txt, in_a_args) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_args)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("("))
                      txt = lm_68(txt, i_args)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_70(in_txt::Tpl.Text, in_a_optName::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_name::Absyn.Ident
                @match (in_txt, in_a_optName) begin
                  (txt, SOME(i_name))  => begin
                      txt = Tpl.writeStr(txt, i_name)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_71(in_txt::Tpl.Text, in_mArg::Bool, in_a_string::String, in_a_info::SourceInfo, in_a_optName::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_string::String
                  local a_info::SourceInfo
                  local a_optName::Option
                  local l_info__str::Tpl.Text
                  local l_name__str::Tpl.Text
                @match (in_txt, in_mArg, in_a_string, in_a_info, in_a_optName) begin
                  (txt, false, _, _, _)  => begin
                    txt
                  end

                  (txt, _, a_string, a_info, a_optName)  => begin
                      l_name__str = fun_70(Tpl.emptyTxt, a_optName)
                      l_info__str = dumpInfo(Tpl.emptyTxt, a_info)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("/* Absyn.TEXT(SOME(\""))
                      txt = Tpl.writeText(txt, l_name__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\"), \""))
                      txt = Tpl.writeStr(txt, a_string)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\", \""))
                      txt = Tpl.writeText(txt, l_info__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\"); */"))
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpElement(in_txt::Tpl.Text, in_a_elem::Absyn.Element, in_a_options::Dump.DumpOptions)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_options::Dump.DumpOptions
                  local i_string::String
                  local i_optName::Option
                  local i_name::Absyn.Ident
                  local i_args::IList
                  local i_constrainClass::Option
                  local i_specification::Absyn.ElementSpec
                  local i_innerOuter::Absyn.InnerOuter
                  local i_redeclareKeywords::Option
                  local i_finalPrefix::Bool
                  local i_elem::Absyn.Element
                  local i_info::SourceInfo
                  local ret_5::Bool
                  local l_args__str::Tpl.Text
                  local ret_3::Bool
                  local ret_2::Bool
                  local ret_1::Bool
                  local ret_0::Bool
                @match (in_txt, in_a_elem, in_a_options) begin
                  (txt, i_elem && Absyn.ELEMENT(info = i_info, finalPrefix = i_finalPrefix, redeclareKeywords = i_redeclareKeywords, innerOuter = i_innerOuter, specification = i_specification, constrainClass = i_constrainClass), a_options)  => begin
                      ret_0 = Dump.boolUnparseFileFromInfo(i_info, a_options)
                      ret_1 = AbsynUtil.isClassdef(i_elem)
                      ret_2 = boolNot(ret_1)
                      ret_3 = boolOr(ret_0, ret_2)
                      txt = fun_67(txt, ret_3, i_constrainClass, a_options, i_specification, i_innerOuter, i_redeclareKeywords, i_finalPrefix)
                    txt
                  end

                  (txt, Absyn.DEFINEUNIT(args = i_args, name = i_name), _)  => begin
                      l_args__str = fun_69(Tpl.emptyTxt, i_args)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("defineunit "))
                      txt = Tpl.writeStr(txt, i_name)
                      txt = Tpl.writeText(txt, l_args__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"))
                    txt
                  end

                  (txt, Absyn.TEXT(info = i_info, optName = i_optName, string = i_string), a_options)  => begin
                      ret_5 = Dump.boolUnparseFileFromInfo(i_info, a_options)
                      txt = fun_71(txt, ret_5, i_string, i_info, i_optName)
                    txt
                  end

                  (txt, _, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_73(in_txt::Tpl.Text, in_a_isReadOnly::Bool)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_isReadOnly) begin
                  (txt, false)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("writable"))
                    txt
                  end

                  (txt, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("readonly"))
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpInfo(in_txt::Tpl.Text, in_a_info::SourceInfo)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_columnNumberEnd::ModelicaInteger
                  local i_lineNumberEnd::ModelicaInteger
                  local i_columnNumberStart::ModelicaInteger
                  local i_lineNumberStart::ModelicaInteger
                  local i_fileName::String
                  local i_isReadOnly::Bool
                  local l_rm__str::Tpl.Text
                @match (in_txt, in_a_info) begin
                  (txt, SOURCEINFO(isReadOnly = i_isReadOnly, fileName = i_fileName, lineNumberStart = i_lineNumberStart, columnNumberStart = i_columnNumberStart, lineNumberEnd = i_lineNumberEnd, columnNumberEnd = i_columnNumberEnd))  => begin
                      l_rm__str = fun_73(Tpl.emptyTxt, i_isReadOnly)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("SOURCEINFO(\""))
                      txt = Tpl.writeStr(txt, i_fileName)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\", "))
                      txt = Tpl.writeText(txt, l_rm__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "))
                      txt = Tpl.writeStr(txt, intString(i_lineNumberStart))
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "))
                      txt = Tpl.writeStr(txt, intString(i_columnNumberStart))
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "))
                      txt = Tpl.writeStr(txt, intString(i_lineNumberEnd))
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "))
                      txt = Tpl.writeStr(txt, intString(i_columnNumberEnd))
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")\\n"))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_75(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_earg::Absyn.ElementArg
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_earg <| rest)  => begin
                      txt = dumpElementArg(txt, i_earg)
                      txt = Tpl.nextIter(txt)
                      txt = lm_75(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpAnnotation(in_txt::Tpl.Text, in_a_ann::Absyn.Annotation)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_elementArgs::IList
                  local ret_1::Tpl.StringToken
                  local txt_0::Tpl.Text
                @match (in_txt, in_a_ann) begin
                  (txt, Absyn.ANNOTATION(elementArgs =  nil()))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("annotation()"))
                    txt
                  end

                  (txt, Absyn.ANNOTATION(elementArgs = i_elementArgs))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE("annotation(\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt_0 = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING(","))
                      txt_0 = Tpl.writeTok(txt_0, Tpl.ST_NEW_LINE())
                      ret_1 = Tpl.textStrTok(txt_0)
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(ret_1), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_75(txt, i_elementArgs)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpAnnotationOpt(in_txt::Tpl.Text, in_a_oann::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_ann::Absyn.Annotation
                @match (in_txt, in_a_oann) begin
                  (txt, SOME(i_ann))  => begin
                      txt = dumpAnnotation(txt, i_ann)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpAnnotationOptSpace(in_txt::Tpl.Text, in_a_oann::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_ann::Absyn.Annotation
                @match (in_txt, in_a_oann) begin
                  (txt, SOME(i_ann))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "))
                      txt = dumpAnnotation(txt, i_ann)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpComment(in_txt::Tpl.Text, in_a_cmt::Absyn.Comment)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_annotation__::Option
                  local i_comment::Option
                @match (in_txt, in_a_cmt) begin
                  (txt, Absyn.COMMENT(comment = i_comment, annotation_ = i_annotation__))  => begin
                      txt = dumpStringCommentOption(txt, i_comment)
                      txt = dumpAnnotationOptSpace(txt, i_annotation__)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpCommentOpt(in_txt::Tpl.Text, in_a_ocmt::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_cmt::Absyn.Comment
                @match (in_txt, in_a_ocmt) begin
                  (txt, SOME(i_cmt))  => begin
                      txt = dumpComment(txt, i_cmt)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_81(in_txt::Tpl.Text, in_a_modification::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_mod::Absyn.Modification
                @match (in_txt, in_a_modification) begin
                  (txt, SOME(i_mod))  => begin
                      txt = dumpModification(txt, i_mod)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_82(in_txt::Tpl.Text, in_a_constrainClass::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_cc::Absyn.ConstrainClass
                @match (in_txt, in_a_constrainClass) begin
                  (txt, SOME(i_cc))  => begin
                      txt = dumpConstrainClass(txt, i_cc)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpElementArg(in_txt::Tpl.Text, in_a_earg::Absyn.ElementArg)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_constrainClass::Option
                  local i_elementSpec::Absyn.ElementSpec
                  local i_redeclareKeywords::Absyn.RedeclareKeywords
                  local i_comment::Option
                  local i_modification::Option
                  local i_path::Absyn.Path
                  local i_finalPrefix::Bool
                  local i_eachPrefix::Absyn.Each
                  local l_cc__str::Tpl.Text
                  local l_elem__str::Tpl.Text
                  local l_eredecl__str::Tpl.Text
                  local l_repl__str::Tpl.Text
                  local l_redecl__str::Tpl.Text
                  local l_cmt__str::Tpl.Text
                  local l_mod__str::Tpl.Text
                  local l_path__str::Tpl.Text
                  local l_final__str::Tpl.Text
                  local l_each__str::Tpl.Text
                @match (in_txt, in_a_earg) begin
                  (txt, Absyn.MODIFICATION(eachPrefix = i_eachPrefix, finalPrefix = i_finalPrefix, path = i_path, modification = i_modification, comment = i_comment))  => begin
                      l_each__str = dumpEach(Tpl.emptyTxt, i_eachPrefix)
                      l_final__str = dumpFinal(Tpl.emptyTxt, i_finalPrefix)
                      l_path__str = dumpPath(Tpl.emptyTxt, i_path)
                      l_mod__str = fun_81(Tpl.emptyTxt, i_modification)
                      l_cmt__str = dumpStringCommentOption(Tpl.emptyTxt, i_comment)
                      txt = Tpl.writeText(txt, l_each__str)
                      txt = Tpl.writeText(txt, l_final__str)
                      txt = Tpl.writeText(txt, l_path__str)
                      txt = Tpl.writeText(txt, l_mod__str)
                      txt = Tpl.writeText(txt, l_cmt__str)
                    txt
                  end

                  (txt, Absyn.REDECLARATION(eachPrefix = i_eachPrefix, finalPrefix = i_finalPrefix, redeclareKeywords = i_redeclareKeywords, elementSpec = i_elementSpec, constrainClass = i_constrainClass))  => begin
                      l_each__str = dumpEach(Tpl.emptyTxt, i_eachPrefix)
                      l_final__str = dumpFinal(Tpl.emptyTxt, i_finalPrefix)
                      l_redecl__str = dumpRedeclare(Tpl.emptyTxt, i_redeclareKeywords)
                      l_repl__str = dumpReplaceable(Tpl.emptyTxt, i_redeclareKeywords)
                      l_eredecl__str = Tpl.writeText(Tpl.emptyTxt, l_redecl__str)
                      l_eredecl__str = Tpl.writeText(l_eredecl__str, l_each__str)
                      l_elem__str = dumpElementSpec(Tpl.emptyTxt, i_elementSpec, Tpl.textString(l_final__str), Tpl.textString(l_eredecl__str), Tpl.textString(l_repl__str), "", Dump.defaultDumpOptions)
                      l_cc__str = fun_82(Tpl.emptyTxt, i_constrainClass)
                      txt = Tpl.writeText(txt, l_elem__str)
                      txt = Tpl.writeText(txt, l_cc__str)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpEach(in_txt::Tpl.Text, in_a_each::Absyn.Each)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_each) begin
                  (txt, Absyn.EACH())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("each "))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpFinal(in_txt::Tpl.Text, in_a_final::Bool)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_final) begin
                  (txt, false)  => begin
                    txt
                  end

                  (txt, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("final "))
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpRedeclare(in_txt::Tpl.Text, in_a_redecl::Absyn.RedeclareKeywords)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_redecl) begin
                  (txt, Absyn.REDECLARE())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("redeclare "))
                    txt
                  end

                  (txt, Absyn.REDECLARE_REPLACEABLE())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("redeclare "))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpReplaceable(in_txt::Tpl.Text, in_a_repl::Absyn.RedeclareKeywords)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_repl) begin
                  (txt, Absyn.REPLACEABLE())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("replaceable "))
                    txt
                  end

                  (txt, Absyn.REDECLARE_REPLACEABLE())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("replaceable "))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpInnerOuter(in_txt::Tpl.Text, in_a_io::Absyn.InnerOuter)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_io) begin
                  (txt, Absyn.INNER())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("inner "))
                    txt
                  end

                  (txt, Absyn.OUTER())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("outer "))
                    txt
                  end

                  (txt, Absyn.INNER_OUTER())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("inner outer "))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_89(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_earg::Absyn.ElementArg
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_earg <| rest)  => begin
                      txt = dumpElementArg(txt, i_earg)
                      txt = Tpl.nextIter(txt)
                      txt = lm_89(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_90(in_txt::Tpl.Text, in_a_elementArgLst::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_elementArgLst::IList
                @match (in_txt, in_a_elementArgLst) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_elementArgLst)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("("))
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_89(txt, i_elementArgLst)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpModification(in_txt::Tpl.Text, in_a_mod::Absyn.Modification)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_eqMod::Absyn.EqMod
                  local i_elementArgLst::IList
                  local l_eq__str::Tpl.Text
                  local l_arg__str::Tpl.Text
                @match (in_txt, in_a_mod) begin
                  (txt, Absyn.CLASSMOD(elementArgLst = i_elementArgLst, eqMod = i_eqMod))  => begin
                      l_arg__str = fun_90(Tpl.emptyTxt, i_elementArgLst)
                      l_eq__str = dumpEqMod(Tpl.emptyTxt, i_eqMod)
                      txt = Tpl.writeText(txt, l_arg__str)
                      txt = Tpl.writeText(txt, l_eq__str)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpEqMod(in_txt::Tpl.Text, in_a_eqmod::Absyn.EqMod)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_exp::Absyn.Exp
                @match (in_txt, in_a_eqmod) begin
                  (txt, Absyn.EQMOD(exp = i_exp))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "))
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("= "))
                      txt = dumpExp(txt, i_exp)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_93(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_earg::Absyn.ElementArg
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_earg <| rest)  => begin
                      txt = dumpElementArg(txt, i_earg)
                      txt = Tpl.nextIter(txt)
                      txt = lm_93(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_94(in_txt::Tpl.Text, in_a_args__str::Tpl.Text)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_args__str::Tpl.Text
                @match (in_txt, in_a_args__str) begin
                  (txt, Tpl.MEM_TEXT(tokens =  nil()))  => begin
                    txt
                  end

                  (txt, i_args__str)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("("))
                      txt = Tpl.writeText(txt, i_args__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_95(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_comp::Absyn.ComponentItem
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_comp <| rest)  => begin
                      txt = dumpComponentItem(txt, i_comp)
                      txt = Tpl.nextIter(txt)
                      txt = lm_95(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpElementSpec(in_txt::Tpl.Text, in_a_elem::Absyn.ElementSpec, in_a_final::String, in_a_redecl::String, in_a_repl::String, in_a_io::String, in_a_options::Dump.DumpOptions)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_final::String
                  local a_redecl::String
                  local a_repl::String
                  local a_io::String
                  local a_options::Dump.DumpOptions
                  local i_import__::Absyn.Import
                  local i_components::IList
                  local i_attributes::Absyn.ElementAttributes
                  local i_typeSpec::Absyn.TypeSpec
                  local i_annotationOpt::Option
                  local i_elementArg::IList
                  local i_path::Absyn.Path
                  local i_class__::Absyn.Class
                  local l_imp__str::Tpl.Text
                  local l_prefix__str::Tpl.Text
                  local l_comps__str::Tpl.Text
                  local l_dim__str::Tpl.Text
                  local l_attr__str::Tpl.Text
                  local l_ty__str::Tpl.Text
                  local l_ann__str::Tpl.Text
                  local l_mod__str::Tpl.Text
                  local l_args__str::Tpl.Text
                  local l_bc__str::Tpl.Text
                @match (in_txt, in_a_elem, in_a_final, in_a_redecl, in_a_repl, in_a_io, in_a_options) begin
                  (txt, Absyn.CLASSDEF(class_ = i_class__), a_final, a_redecl, a_repl, a_io, a_options)  => begin
                      txt = dumpClassElement(txt, i_class__, a_final, a_redecl, a_repl, a_io, a_options)
                    txt
                  end

                  (txt, Absyn.EXTENDS(path = i_path, elementArg = i_elementArg, annotationOpt = i_annotationOpt), _, _, _, _, _)  => begin
                      l_bc__str = dumpPath(Tpl.emptyTxt, i_path)
                      l_args__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_args__str = lm_93(l_args__str, i_elementArg)
                      l_args__str = Tpl.popIter(l_args__str)
                      l_mod__str = fun_94(Tpl.emptyTxt, l_args__str)
                      l_ann__str = dumpAnnotationOptSpace(Tpl.emptyTxt, i_annotationOpt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("extends "))
                      txt = Tpl.writeText(txt, l_bc__str)
                      txt = Tpl.writeText(txt, l_mod__str)
                      txt = Tpl.writeText(txt, l_ann__str)
                    txt
                  end

                  (txt, Absyn.COMPONENTS(typeSpec = i_typeSpec, attributes = i_attributes, components = i_components), a_final, a_redecl, a_repl, a_io, _)  => begin
                      l_ty__str = dumpTypeSpec(Tpl.emptyTxt, i_typeSpec)
                      l_attr__str = dumpElementAttr(Tpl.emptyTxt, i_attributes)
                      l_dim__str = dumpElementAttrDim(Tpl.emptyTxt, i_attributes)
                      l_comps__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_comps__str = lm_95(l_comps__str, i_components)
                      l_comps__str = Tpl.popIter(l_comps__str)
                      l_prefix__str = Tpl.writeStr(Tpl.emptyTxt, a_redecl)
                      l_prefix__str = Tpl.writeStr(l_prefix__str, a_final)
                      l_prefix__str = Tpl.writeStr(l_prefix__str, a_io)
                      l_prefix__str = Tpl.writeStr(l_prefix__str, a_repl)
                      txt = Tpl.writeText(txt, l_prefix__str)
                      txt = Tpl.writeText(txt, l_attr__str)
                      txt = Tpl.writeText(txt, l_ty__str)
                      txt = Tpl.writeText(txt, l_dim__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "))
                      txt = Tpl.writeText(txt, l_comps__str)
                    txt
                  end

                  (txt, Absyn.IMPORT(import_ = i_import__), _, _, _, _, _)  => begin
                      l_imp__str = dumpImport(Tpl.emptyTxt, i_import__)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("import "))
                      txt = Tpl.writeText(txt, l_imp__str)
                    txt
                  end

                  (txt, _, _, _, _, _, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_97(in_txt::Tpl.Text, in_a_flowPrefix::Bool)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_flowPrefix) begin
                  (txt, false)  => begin
                    txt
                  end

                  (txt, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("flow "))
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_98(in_txt::Tpl.Text, in_a_streamPrefix::Bool)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_streamPrefix) begin
                  (txt, false)  => begin
                    txt
                  end

                  (txt, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("stream "))
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpElementAttr(in_txt::Tpl.Text, in_a_attr::Absyn.ElementAttributes)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_direction::Absyn.Direction
                  local i_variability::Absyn.Variability
                  local i_isField::Absyn.IsField
                  local i_parallelism::Absyn.Parallelism
                  local i_streamPrefix::Bool
                  local i_flowPrefix::Bool
                  local l_dir__str::Tpl.Text
                  local l_var__str::Tpl.Text
                  local l_field__str::Tpl.Text
                  local l_par__str::Tpl.Text
                  local l_stream__str::Tpl.Text
                  local l_flow__str::Tpl.Text
                @match (in_txt, in_a_attr) begin
                  (txt, Absyn.ATTR(flowPrefix = i_flowPrefix, streamPrefix = i_streamPrefix, parallelism = i_parallelism, isField = i_isField, variability = i_variability, direction = i_direction))  => begin
                      l_flow__str = fun_97(Tpl.emptyTxt, i_flowPrefix)
                      l_stream__str = fun_98(Tpl.emptyTxt, i_streamPrefix)
                      l_par__str = dumpParallelism(Tpl.emptyTxt, i_parallelism)
                      l_field__str = dumpIsField(Tpl.emptyTxt, i_isField)
                      l_var__str = dumpVariability(Tpl.emptyTxt, i_variability)
                      l_dir__str = dumpDirection(Tpl.emptyTxt, i_direction)
                      txt = Tpl.writeText(txt, l_flow__str)
                      txt = Tpl.writeText(txt, l_stream__str)
                      txt = Tpl.writeText(txt, l_par__str)
                      txt = Tpl.writeText(txt, l_field__str)
                      txt = Tpl.writeText(txt, l_var__str)
                      txt = Tpl.writeText(txt, l_dir__str)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpParallelism(in_txt::Tpl.Text, in_a_par::Absyn.Parallelism)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_par) begin
                  (txt, Absyn.PARGLOBAL())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("parglobal "))
                    txt
                  end

                  (txt, Absyn.PARLOCAL())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("parlocal "))
                    txt
                  end

                  (txt, Absyn.NON_PARALLEL())  => begin
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpIsField(in_txt::Tpl.Text, in_a_isField::Absyn.IsField)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_isField) begin
                  (txt, Absyn.NONFIELD())  => begin
                    txt
                  end

                  (txt, Absyn.FIELD())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("field "))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpVariability(in_txt::Tpl.Text, in_a_var::Absyn.Variability)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_var) begin
                  (txt, Absyn.VAR())  => begin
                    txt
                  end

                  (txt, Absyn.DISCRETE())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("discrete "))
                    txt
                  end

                  (txt, Absyn.PARAM())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("parameter "))
                    txt
                  end

                  (txt, Absyn.CONST())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("constant "))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpDirection(in_txt::Tpl.Text, in_a_dir::Absyn.Direction)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_dir) begin
                  (txt, Absyn.BIDIR())  => begin
                    txt
                  end

                  (txt, Absyn.INPUT())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("input "))
                    txt
                  end

                  (txt, Absyn.OUTPUT())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("output "))
                    txt
                  end

                  (txt, Absyn.INPUT_OUTPUT())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("input output "))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpElementAttrDim(in_txt::Tpl.Text, in_a_attr::Absyn.ElementAttributes)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_arrayDim::Absyn.ArrayDim
                @match (in_txt, in_a_attr) begin
                  (txt, Absyn.ATTR(arrayDim = i_arrayDim))  => begin
                      txt = dumpSubscripts(txt, i_arrayDim)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_105(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_e::Absyn.ElementArg
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_e <| rest)  => begin
                      txt = dumpElementArg(txt, i_e)
                      txt = Tpl.nextIter(txt)
                      txt = lm_105(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_106(in_txt::Tpl.Text, in_a_el::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_el::IList
                @match (in_txt, in_a_el) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_el)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("("))
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_105(txt, i_el)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpConstrainClass(in_txt::Tpl.Text, in_a_cc::Absyn.ConstrainClass)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_comment::Option
                  local i_el::IList
                  local i_p::Absyn.Path
                  local l_cmt__str::Tpl.Text
                  local l_el__str::Tpl.Text
                  local l_path__str::Tpl.Text
                @match (in_txt, in_a_cc) begin
                  (txt, Absyn.CONSTRAINCLASS(elementSpec = Absyn.EXTENDS(path = i_p, elementArg = i_el), comment = i_comment))  => begin
                      l_path__str = dumpPath(Tpl.emptyTxt, i_p)
                      l_el__str = fun_106(Tpl.emptyTxt, i_el)
                      l_cmt__str = dumpCommentOpt(Tpl.emptyTxt, i_comment)
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(1))
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("constrainedby "))
                      txt = Tpl.writeText(txt, l_path__str)
                      txt = Tpl.writeText(txt, l_el__str)
                      txt = Tpl.writeText(txt, l_cmt__str)
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpComponentItem(in_txt::Tpl.Text, in_a_comp::Absyn.ComponentItem)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_comment::Option
                  local i_condition::Option
                  local i_component::Absyn.Component
                  local l_cmt::Tpl.Text
                  local l_cond__str::Tpl.Text
                  local l_comp__str::Tpl.Text
                @match (in_txt, in_a_comp) begin
                  (txt, Absyn.COMPONENTITEM(component = i_component, condition = i_condition, comment = i_comment))  => begin
                      l_comp__str = dumpComponent(Tpl.emptyTxt, i_component)
                      l_cond__str = dumpComponentCondition(Tpl.emptyTxt, i_condition)
                      l_cmt = dumpCommentOpt(Tpl.emptyTxt, i_comment)
                      txt = Tpl.writeText(txt, l_comp__str)
                      txt = Tpl.writeText(txt, l_cond__str)
                      txt = Tpl.writeText(txt, l_cmt)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_109(in_txt::Tpl.Text, in_a_modification::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_mod::Absyn.Modification
                @match (in_txt, in_a_modification) begin
                  (txt, SOME(i_mod))  => begin
                      txt = dumpModification(txt, i_mod)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpComponent(in_txt::Tpl.Text, in_a_comp::Absyn.Component)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_name::Absyn.Ident
                  local i_modification::Option
                  local i_arrayDim::Absyn.ArrayDim
                  local l_mod__str::Tpl.Text
                  local l_dim__str::Tpl.Text
                @match (in_txt, in_a_comp) begin
                  (txt, Absyn.COMPONENT(arrayDim = i_arrayDim, modification = i_modification, name = i_name))  => begin
                      l_dim__str = dumpSubscripts(Tpl.emptyTxt, i_arrayDim)
                      l_mod__str = fun_109(Tpl.emptyTxt, i_modification)
                      txt = Tpl.writeStr(txt, i_name)
                      txt = Tpl.writeText(txt, l_dim__str)
                      txt = Tpl.writeText(txt, l_mod__str)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpComponentCondition(in_txt::Tpl.Text, in_a_cond::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_cexp::Absyn.ComponentCondition
                  local l_exp__str::Tpl.Text
                @match (in_txt, in_a_cond) begin
                  (txt, SOME(i_cexp))  => begin
                      l_exp__str = dumpExp(Tpl.emptyTxt, i_cexp)
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(1))
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("if "))
                      txt = Tpl.writeText(txt, l_exp__str)
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_112(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_group::Absyn.GroupImport
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_group <| rest)  => begin
                      txt = dumpGroupImport(txt, i_group)
                      txt = Tpl.nextIter(txt)
                      txt = lm_112(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpImport(in_txt::Tpl.Text, in_a_imp::Absyn.Import)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_groups::IList
                  local i_prefix::Absyn.Path
                  local i_path::Absyn.Path
                  local i_name::Absyn.Ident
                  local l_groups__str::Tpl.Text
                  local l_prefix__str::Tpl.Text
                @match (in_txt, in_a_imp) begin
                  (txt, Absyn.NAMED_IMPORT(name = i_name, path = i_path))  => begin
                      txt = Tpl.writeStr(txt, i_name)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "))
                      txt = dumpPath(txt, i_path)
                    txt
                  end

                  (txt, Absyn.QUAL_IMPORT(path = i_path))  => begin
                      txt = dumpPath(txt, i_path)
                    txt
                  end

                  (txt, Absyn.UNQUAL_IMPORT(path = i_path))  => begin
                      txt = dumpPath(txt, i_path)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(".*"))
                    txt
                  end

                  (txt, Absyn.GROUP_IMPORT(prefix = i_prefix, groups = i_groups))  => begin
                      l_prefix__str = dumpPath(Tpl.emptyTxt, i_prefix)
                      l_groups__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(",")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_groups__str = lm_112(l_groups__str, i_groups)
                      l_groups__str = Tpl.popIter(l_groups__str)
                      txt = Tpl.writeText(txt, l_prefix__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(".{"))
                      txt = Tpl.writeText(txt, l_groups__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpGroupImport(in_txt::Tpl.Text, in_a_gimp::Absyn.GroupImport)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_rename::String
                  local i_name::String
                @match (in_txt, in_a_gimp) begin
                  (txt, Absyn.GROUP_IMPORT_NAME(name = i_name))  => begin
                      txt = Tpl.writeStr(txt, i_name)
                    txt
                  end

                  (txt, Absyn.GROUP_IMPORT_RENAME(rename = i_rename, name = i_name))  => begin
                      txt = Tpl.writeStr(txt, i_rename)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "))
                      txt = Tpl.writeStr(txt, i_name)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpEquationItem(in_txt::Tpl.Text, in_a_eq::Absyn.EquationItem)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_comment_1::String
                  local i_comment::Option
                  local i_equation__::Absyn.Equation
                  local ret_2::String
                  local l_cmt__str::Tpl.Text
                  local l_eq__str::Tpl.Text
                @match (in_txt, in_a_eq) begin
                  (txt, Absyn.EQUATIONITEM(equation_ = i_equation__, comment = i_comment))  => begin
                      l_eq__str = dumpEquation(Tpl.emptyTxt, i_equation__)
                      l_cmt__str = dumpCommentOpt(Tpl.emptyTxt, i_comment)
                      txt = Tpl.writeText(txt, l_eq__str)
                      txt = Tpl.writeText(txt, l_cmt__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"))
                    txt
                  end

                  (txt, Absyn.EQUATIONITEMCOMMENT(comment = i_comment_1))  => begin
                      txt = Tpl.pushBlock(txt, Tpl.BT_ABS_INDENT(0))
                      ret_2 = System.trimWhitespace(i_comment_1)
                      txt = Tpl.writeStr(txt, ret_2)
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_116(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_eq::Absyn.EquationItem
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_eq <| rest)  => begin
                      txt = dumpEquationItem(txt, i_eq)
                      txt = Tpl.nextIter(txt)
                      txt = lm_116(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpEquationItems(txt::Tpl.Text, a_eql::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
              out_txt = lm_116(out_txt, a_eql)
              out_txt = Tpl.popIter(out_txt)
          out_txt
        end

        function lm_118(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_b::IList
                  local i_c::Absyn.Exp
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, (i_c, i_b) <| rest)  => begin
                      txt = dumpEquationBranch(txt, i_c, i_b, "elseif")
                      txt = Tpl.nextIter(txt)
                      txt = lm_118(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_119(in_txt::Tpl.Text, in_a_else__branch__str::Tpl.Text)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_else__branch__str::Tpl.Text
                @match (in_txt, in_a_else__branch__str) begin
                  (txt, Tpl.MEM_TEXT(tokens =  nil()))  => begin
                    txt
                  end

                  (txt, i_else__branch__str)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE("else\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.writeText(txt, i_else__branch__str)
                      txt = Tpl.popBlock(txt)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_120(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_b::IList
                  local i_c::Absyn.Exp
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, (i_c, i_b) <| rest)  => begin
                      txt = dumpEquationBranch(txt, i_c, i_b, "elsewhen")
                      txt = Tpl.nextIter(txt)
                      txt = lm_120(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpEquation(in_txt::Tpl.Text, in_a_eq::Absyn.Equation)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_equ::Absyn.EquationItem
                  local i_functionArgs::Absyn.FunctionArgs
                  local i_functionName::Absyn.ComponentRef
                  local i_elseWhenEquations::IList
                  local i_whenEquations::IList
                  local i_whenExp::Absyn.Exp
                  local i_forEquations::IList
                  local i_iterators::Absyn.ForIterators
                  local i_connector2::Absyn.ComponentRef
                  local i_connector1::Absyn.ComponentRef
                  local i_domain::Absyn.ComponentRef
                  local i_rightSide::Absyn.Exp
                  local i_leftSide::Absyn.Exp
                  local i_equationElseItems::IList
                  local i_elseIfBranches::IList
                  local i_equationTrueItems::IList
                  local i_ifExp::Absyn.Exp
                  local l_eq__str::Tpl.Text
                  local l_args__str::Tpl.Text
                  local l_name__str::Tpl.Text
                  local l_elsewhen__str::Tpl.Text
                  local l_when__str::Tpl.Text
                  local l_body__str::Tpl.Text
                  local l_iter__str::Tpl.Text
                  local l_c2__str::Tpl.Text
                  local l_c1__str::Tpl.Text
                  local l_domain__str::Tpl.Text
                  local l_rhs::Tpl.Text
                  local l_lhs::Tpl.Text
                  local l_else__str::Tpl.Text
                  local l_else__branch__str::Tpl.Text
                  local l_elseif__str::Tpl.Text
                  local l_if__str::Tpl.Text
                @match (in_txt, in_a_eq) begin
                  (txt, Absyn.EQ_IF(ifExp = i_ifExp, equationTrueItems = i_equationTrueItems, elseIfBranches = i_elseIfBranches, equationElseItems = i_equationElseItems))  => begin
                      l_if__str = dumpEquationBranch(Tpl.emptyTxt, i_ifExp, i_equationTrueItems, "if")
                      l_elseif__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_elseif__str = lm_118(l_elseif__str, i_elseIfBranches)
                      l_elseif__str = Tpl.popIter(l_elseif__str)
                      l_else__branch__str = dumpEquationItems(Tpl.emptyTxt, i_equationElseItems)
                      l_else__str = fun_119(Tpl.emptyTxt, l_else__branch__str)
                      txt = Tpl.writeText(txt, l_if__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.writeText(txt, l_elseif__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.writeText(txt, l_else__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("end if"))
                    txt
                  end

                  (txt, Absyn.EQ_EQUALS(leftSide = i_leftSide, rightSide = i_rightSide))  => begin
                      l_lhs = dumpLhsExp(Tpl.emptyTxt, i_leftSide)
                      l_rhs = dumpExp(Tpl.emptyTxt, i_rightSide)
                      txt = Tpl.writeText(txt, l_lhs)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "))
                      txt = Tpl.writeText(txt, l_rhs)
                    txt
                  end

                  (txt, Absyn.EQ_PDE(leftSide = i_leftSide, rightSide = i_rightSide, domain = i_domain))  => begin
                      l_lhs = dumpLhsExp(Tpl.emptyTxt, i_leftSide)
                      l_rhs = dumpExp(Tpl.emptyTxt, i_rightSide)
                      l_domain__str = dumpCref(Tpl.emptyTxt, i_domain)
                      txt = Tpl.writeText(txt, l_lhs)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "))
                      txt = Tpl.writeText(txt, l_rhs)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" indomain "))
                      txt = Tpl.writeText(txt, l_domain__str)
                    txt
                  end

                  (txt, Absyn.EQ_CONNECT(connector1 = i_connector1, connector2 = i_connector2))  => begin
                      l_c1__str = dumpCref(Tpl.emptyTxt, i_connector1)
                      l_c2__str = dumpCref(Tpl.emptyTxt, i_connector2)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("connect("))
                      txt = Tpl.writeText(txt, l_c1__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "))
                      txt = Tpl.writeText(txt, l_c2__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end

                  (txt, Absyn.EQ_FOR(iterators = i_iterators, forEquations = i_forEquations))  => begin
                      l_iter__str = dumpForIterators(Tpl.emptyTxt, i_iterators)
                      l_body__str = dumpEquationItems(Tpl.emptyTxt, i_forEquations)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("for "))
                      txt = Tpl.writeText(txt, l_iter__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE(" loop\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.writeText(txt, l_body__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.popBlock(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("end for"))
                    txt
                  end

                  (txt, Absyn.EQ_WHEN_E(whenExp = i_whenExp, whenEquations = i_whenEquations, elseWhenEquations = i_elseWhenEquations))  => begin
                      l_when__str = dumpEquationBranch(Tpl.emptyTxt, i_whenExp, i_whenEquations, "when")
                      l_elsewhen__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_elsewhen__str = lm_120(l_elsewhen__str, i_elseWhenEquations)
                      l_elsewhen__str = Tpl.popIter(l_elsewhen__str)
                      txt = Tpl.writeText(txt, l_when__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.writeText(txt, l_elsewhen__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("end when"))
                    txt
                  end

                  (txt, Absyn.EQ_NORETCALL(functionName = i_functionName, functionArgs = i_functionArgs))  => begin
                      l_name__str = dumpCref(Tpl.emptyTxt, i_functionName)
                      l_args__str = dumpFunctionArgs(Tpl.emptyTxt, i_functionArgs)
                      txt = Tpl.writeText(txt, l_name__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("("))
                      txt = Tpl.writeText(txt, l_args__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end

                  (txt, Absyn.EQ_FAILURE(equ = i_equ))  => begin
                      l_eq__str = dumpEquationItem(Tpl.emptyTxt, i_equ)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("failure("))
                      txt = Tpl.writeText(txt, l_eq__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_122(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_eq::Absyn.EquationItem
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_eq <| rest)  => begin
                      txt = dumpEquationItem(txt, i_eq)
                      txt = Tpl.nextIter(txt)
                      txt = lm_122(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpEquationBranch(txt::Tpl.Text, a_cond::Absyn.Exp, a_body::IList, a_header::String)::Tpl.Text
              local out_txt::Tpl.Text

              local l_body__str::Tpl.Text
              local l_cond__str::Tpl.Text

              l_cond__str = dumpExp(Tpl.emptyTxt, a_cond)
              l_body__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
              l_body__str = lm_122(l_body__str, a_body)
              l_body__str = Tpl.popIter(l_body__str)
              out_txt = Tpl.writeStr(txt, a_header)
              out_txt = Tpl.writeTok(out_txt, Tpl.ST_STRING(" "))
              out_txt = Tpl.writeText(out_txt, l_cond__str)
              out_txt = Tpl.writeTok(out_txt, Tpl.ST_LINE(" then\n"))
              out_txt = Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2))
              out_txt = Tpl.writeText(out_txt, l_body__str)
              out_txt = Tpl.popBlock(out_txt)
          out_txt
        end

        function lm_124(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_alg::Absyn.AlgorithmItem
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_alg <| rest)  => begin
                      txt = dumpAlgorithmItem(txt, i_alg)
                      txt = Tpl.nextIter(txt)
                      txt = lm_124(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpAlgorithmItems(txt::Tpl.Text, a_algs::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
              out_txt = lm_124(out_txt, a_algs)
              out_txt = Tpl.popIter(out_txt)
          out_txt
        end

        function dumpAlgorithmItem(in_txt::Tpl.Text, in_a_alg::Absyn.AlgorithmItem)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_comment_1::String
                  local i_comment::Option
                  local i_algorithm__::Absyn.Algorithm
                  local ret_2::String
                  local l_cmt__str::Tpl.Text
                  local l_alg__str::Tpl.Text
                @match (in_txt, in_a_alg) begin
                  (txt, Absyn.ALGORITHMITEM(algorithm_ = i_algorithm__, comment = i_comment))  => begin
                      l_alg__str = dumpAlgorithm(Tpl.emptyTxt, i_algorithm__)
                      l_cmt__str = dumpCommentOpt(Tpl.emptyTxt, i_comment)
                      txt = Tpl.writeText(txt, l_alg__str)
                      txt = Tpl.writeText(txt, l_cmt__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"))
                    txt
                  end

                  (txt, Absyn.ALGORITHMITEMCOMMENT(comment = i_comment_1))  => begin
                      txt = Tpl.pushBlock(txt, Tpl.BT_ABS_INDENT(0))
                      ret_2 = System.trimWhitespace(i_comment_1)
                      txt = Tpl.writeStr(txt, ret_2)
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_127(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_b::IList
                  local i_c::Absyn.Exp
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, (i_c, i_b) <| rest)  => begin
                      txt = dumpAlgorithmBranch(txt, i_c, i_b, "elseif", "then")
                      txt = Tpl.nextIter(txt)
                      txt = lm_127(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_128(in_txt::Tpl.Text, in_a_else__branch__str::Tpl.Text)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_else__branch__str::Tpl.Text
                @match (in_txt, in_a_else__branch__str) begin
                  (txt, Tpl.MEM_TEXT(tokens =  nil()))  => begin
                    txt
                  end

                  (txt, i_else__branch__str)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE("else\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.writeText(txt, i_else__branch__str)
                      txt = Tpl.popBlock(txt)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_129(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_b::IList
                  local i_c::Absyn.Exp
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, (i_c, i_b) <| rest)  => begin
                      txt = dumpAlgorithmBranch(txt, i_c, i_b, "elsewhen", "then")
                      txt = Tpl.nextIter(txt)
                      txt = lm_129(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_130(in_txt::Tpl.Text, in_a_equ::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_equ::IList
                @match (in_txt, in_a_equ) begin
                  (txt,  nil())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("..."))
                    txt
                  end

                  (txt, i_equ)  => begin
                      txt = dumpAlgorithmItems(txt, i_equ)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpAlgorithm(in_txt::Tpl.Text, in_a_alg::Absyn.Algorithm)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_elseBody::IList
                  local i_body::IList
                  local i_equ::IList
                  local i_functionArgs::Absyn.FunctionArgs
                  local i_functionCall::Absyn.ComponentRef
                  local i_elseWhenAlgorithmBranch::IList
                  local i_whenBody::IList
                  local i_whileBody::IList
                  local i_boolExpr::Absyn.Exp
                  local i_parforBody::IList
                  local i_forBody::IList
                  local i_iterators::Absyn.ForIterators
                  local i_elseBranch::IList
                  local i_elseIfAlgorithmBranch::IList
                  local i_trueBranch::IList
                  local i_ifExp::Absyn.Exp
                  local i_value::Absyn.Exp
                  local i_assignComponent::Absyn.Exp
                  local l_arg2::Tpl.Text
                  local l_arg1::Tpl.Text
                  local l_arg__str::Tpl.Text
                  local l_args__str::Tpl.Text
                  local l_name__str::Tpl.Text
                  local l_elsewhen__str::Tpl.Text
                  local l_when__str::Tpl.Text
                  local l_while__str::Tpl.Text
                  local l_body__str::Tpl.Text
                  local l_iter__str::Tpl.Text
                  local l_else__str::Tpl.Text
                  local l_else__branch__str::Tpl.Text
                  local l_elseif__str::Tpl.Text
                  local l_if__str::Tpl.Text
                  local l_rhs__str::Tpl.Text
                  local l_lhs__str::Tpl.Text
                @match (in_txt, in_a_alg) begin
                  (txt, Absyn.ALG_ASSIGN(assignComponent = i_assignComponent, value = i_value))  => begin
                      l_lhs__str = dumpLhsExp(Tpl.emptyTxt, i_assignComponent)
                      l_rhs__str = dumpExp(Tpl.emptyTxt, i_value)
                      txt = Tpl.writeText(txt, l_lhs__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" := "))
                      txt = Tpl.writeText(txt, l_rhs__str)
                    txt
                  end

                  (txt, Absyn.ALG_IF(ifExp = i_ifExp, trueBranch = i_trueBranch, elseIfAlgorithmBranch = i_elseIfAlgorithmBranch, elseBranch = i_elseBranch))  => begin
                      l_if__str = dumpAlgorithmBranch(Tpl.emptyTxt, i_ifExp, i_trueBranch, "if", "then")
                      l_elseif__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_elseif__str = lm_127(l_elseif__str, i_elseIfAlgorithmBranch)
                      l_elseif__str = Tpl.popIter(l_elseif__str)
                      l_else__branch__str = dumpAlgorithmItems(Tpl.emptyTxt, i_elseBranch)
                      l_else__str = fun_128(Tpl.emptyTxt, l_else__branch__str)
                      txt = Tpl.writeText(txt, l_if__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.writeText(txt, l_elseif__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.writeText(txt, l_else__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("end if"))
                    txt
                  end

                  (txt, Absyn.ALG_FOR(iterators = i_iterators, forBody = i_forBody))  => begin
                      l_iter__str = dumpForIterators(Tpl.emptyTxt, i_iterators)
                      l_body__str = dumpAlgorithmItems(Tpl.emptyTxt, i_forBody)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("for "))
                      txt = Tpl.writeText(txt, l_iter__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE(" loop\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.writeText(txt, l_body__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.popBlock(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("end for"))
                    txt
                  end

                  (txt, Absyn.ALG_PARFOR(iterators = i_iterators, parforBody = i_parforBody))  => begin
                      l_iter__str = dumpForIterators(Tpl.emptyTxt, i_iterators)
                      l_body__str = dumpAlgorithmItems(Tpl.emptyTxt, i_parforBody)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("parfor "))
                      txt = Tpl.writeText(txt, l_iter__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE(" loop\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.writeText(txt, l_body__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.popBlock(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("end parfor"))
                    txt
                  end

                  (txt, Absyn.ALG_WHILE(boolExpr = i_boolExpr, whileBody = i_whileBody))  => begin
                      l_while__str = dumpAlgorithmBranch(Tpl.emptyTxt, i_boolExpr, i_whileBody, "while", "loop")
                      txt = Tpl.writeText(txt, l_while__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("end while"))
                    txt
                  end

                  (txt, Absyn.ALG_WHEN_A(boolExpr = i_boolExpr, whenBody = i_whenBody, elseWhenAlgorithmBranch = i_elseWhenAlgorithmBranch))  => begin
                      l_when__str = dumpAlgorithmBranch(Tpl.emptyTxt, i_boolExpr, i_whenBody, "when", "then")
                      l_elsewhen__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_elsewhen__str = lm_129(l_elsewhen__str, i_elseWhenAlgorithmBranch)
                      l_elsewhen__str = Tpl.popIter(l_elsewhen__str)
                      txt = Tpl.writeText(txt, l_when__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.writeText(txt, l_elsewhen__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("end when"))
                    txt
                  end

                  (txt, Absyn.ALG_NORETCALL(functionCall = i_functionCall, functionArgs = i_functionArgs))  => begin
                      l_name__str = dumpCref(Tpl.emptyTxt, i_functionCall)
                      l_args__str = dumpFunctionArgs(Tpl.emptyTxt, i_functionArgs)
                      txt = Tpl.writeText(txt, l_name__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("("))
                      txt = Tpl.writeText(txt, l_args__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end

                  (txt, Absyn.ALG_RETURN())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("return"))
                    txt
                  end

                  (txt, Absyn.ALG_BREAK())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("break"))
                    txt
                  end

                  (txt, Absyn.ALG_FAILURE(equ = i_equ))  => begin
                      l_arg__str = fun_130(Tpl.emptyTxt, i_equ)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("failure("))
                      txt = Tpl.writeText(txt, l_arg__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end

                  (txt, Absyn.ALG_TRY(body = i_body, elseBody = i_elseBody))  => begin
                      l_arg1 = dumpAlgorithmItems(Tpl.emptyTxt, i_body)
                      l_arg2 = dumpAlgorithmItems(Tpl.emptyTxt, i_elseBody)
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE("try\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.writeText(txt, l_arg1)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.popBlock(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE("else\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.writeText(txt, l_arg2)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.popBlock(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("end try;"))
                    txt
                  end

                  (txt, Absyn.ALG_CONTINUE())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("continue"))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_132(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_eq::Absyn.AlgorithmItem
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_eq <| rest)  => begin
                      txt = dumpAlgorithmItem(txt, i_eq)
                      txt = Tpl.nextIter(txt)
                      txt = lm_132(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpAlgorithmBranch(txt::Tpl.Text, a_cond::Absyn.Exp, a_body::IList, a_header::String, a_exec__str::String)::Tpl.Text
              local out_txt::Tpl.Text

              local l_body__str::Tpl.Text
              local l_cond__str::Tpl.Text

              l_cond__str = dumpExp(Tpl.emptyTxt, a_cond)
              l_body__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
              l_body__str = lm_132(l_body__str, a_body)
              l_body__str = Tpl.popIter(l_body__str)
              out_txt = Tpl.writeStr(txt, a_header)
              out_txt = Tpl.writeTok(out_txt, Tpl.ST_STRING(" "))
              out_txt = Tpl.writeText(out_txt, l_cond__str)
              out_txt = Tpl.writeTok(out_txt, Tpl.ST_STRING(" "))
              out_txt = Tpl.writeStr(out_txt, a_exec__str)
              out_txt = Tpl.softNewLine(out_txt)
              out_txt = Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2))
              out_txt = Tpl.writeText(out_txt, l_body__str)
              out_txt = Tpl.popBlock(out_txt)
          out_txt
        end

        function fun_134(in_txt::Tpl.Text, in_mArg::Bool, in_a_path::Absyn.Path, in_a_name::Absyn.Ident)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_path::Absyn.Path
                  local a_name::Absyn.Ident
                @match (in_txt, in_mArg, in_a_path, in_a_name) begin
                  (txt, false, a_path, a_name)  => begin
                      txt = Tpl.writeStr(txt, a_name)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("."))
                      txt = dumpPath(txt, a_path)
                    txt
                  end

                  (txt, _, a_path, a_name)  => begin
                      txt = Tpl.writeStr(txt, a_name)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("__"))
                      txt = dumpPath(txt, a_path)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpPath(in_txt::Tpl.Text, in_a_path::Absyn.Path)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_name::Absyn.Ident
                  local i_path::Absyn.Path
                  local ret_0::Bool
                @match (in_txt, in_a_path) begin
                  (txt, Absyn.FULLYQUALIFIED(path = i_path))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("."))
                      txt = dumpPath(txt, i_path)
                    txt
                  end

                  (txt, Absyn.QUALIFIED(name = i_name, path = i_path))  => begin
                      ret_0 = Flags.getConfigBool(Flags.MODELICA_OUTPUT)
                      txt = fun_134(txt, ret_0, i_path, i_name)
                    txt
                  end

                  (txt, Absyn.IDENT(name = i_name))  => begin
                      txt = Tpl.writeStr(txt, i_name)
                    txt
                  end

                  (txt, _)  => begin
                      txt = errorMsg(txt, "SCodeDump.dumpPath: Unknown path.")
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpPathNoQual(in_txt::Tpl.Text, in_a_path::Absyn.Path)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_path::Absyn.Path
                @match (in_txt, in_a_path) begin
                  (txt, Absyn.FULLYQUALIFIED(path = i_path))  => begin
                      txt = dumpPath(txt, i_path)
                    txt
                  end

                  (txt, i_path)  => begin
                      txt = dumpPath(txt, i_path)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpStringCommentOption(in_txt::Tpl.Text, in_a_cmt::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_str::String
                @match (in_txt, in_a_cmt) begin
                  (txt, SOME(i_str))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "))
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""))
                      txt = Tpl.writeStr(txt, i_str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_138(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_ty::Absyn.TypeSpec
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_ty <| rest)  => begin
                      txt = dumpTypeSpec(txt, i_ty)
                      txt = Tpl.nextIter(txt)
                      txt = lm_138(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpTypeSpec(in_txt::Tpl.Text, in_a_typeSpec::Absyn.TypeSpec)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_typeSpecs::IList
                  local i_arrayDim::Option
                  local i_path::Absyn.Path
                  local l_ty__str::Tpl.Text
                  local l_arraydim__str::Tpl.Text
                  local l_path__str::Tpl.Text
                @match (in_txt, in_a_typeSpec) begin
                  (txt, Absyn.TPATH(path = i_path, arrayDim = i_arrayDim))  => begin
                      l_path__str = dumpPath(Tpl.emptyTxt, i_path)
                      l_arraydim__str = dumpArrayDimOpt(Tpl.emptyTxt, i_arrayDim)
                      txt = Tpl.writeText(txt, l_path__str)
                      txt = Tpl.writeText(txt, l_arraydim__str)
                    txt
                  end

                  (txt, Absyn.TCOMPLEX(path = i_path, typeSpecs = i_typeSpecs, arrayDim = i_arrayDim))  => begin
                      l_path__str = dumpPath(Tpl.emptyTxt, i_path)
                      l_ty__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_ty__str = lm_138(l_ty__str, i_typeSpecs)
                      l_ty__str = Tpl.popIter(l_ty__str)
                      l_arraydim__str = dumpArrayDimOpt(Tpl.emptyTxt, i_arrayDim)
                      txt = Tpl.writeText(txt, l_path__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("<"))
                      txt = Tpl.writeText(txt, l_ty__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(">"))
                      txt = Tpl.writeText(txt, l_arraydim__str)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpArrayDimOpt(in_txt::Tpl.Text, in_a_arraydim::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_ad::Absyn.ArrayDim
                @match (in_txt, in_a_arraydim) begin
                  (txt, SOME(i_ad))  => begin
                      txt = dumpSubscripts(txt, i_ad)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_141(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_s::Absyn.Subscript
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_s <| rest)  => begin
                      txt = dumpSubscript(txt, i_s)
                      txt = Tpl.nextIter(txt)
                      txt = lm_141(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpSubscripts(in_txt::Tpl.Text, in_a_subscripts::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_subscripts::IList
                  local l_sub__str::Tpl.Text
                @match (in_txt, in_a_subscripts) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_subscripts)  => begin
                      l_sub__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_sub__str = lm_141(l_sub__str, i_subscripts)
                      l_sub__str = Tpl.popIter(l_sub__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("["))
                      txt = Tpl.writeText(txt, l_sub__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("]"))
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpSubscript(in_txt::Tpl.Text, in_a_subscript::Absyn.Subscript)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_subscript::Absyn.Exp
                @match (in_txt, in_a_subscript) begin
                  (txt, Absyn.NOSUB())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(":"))
                    txt
                  end

                  (txt, Absyn.SUBSCRIPT(subscript = i_subscript))  => begin
                      txt = dumpExp(txt, i_subscript)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_144(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_e::Absyn.Exp
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_e <| rest)  => begin
                      txt = dumpExp(txt, i_e)
                      txt = Tpl.nextIter(txt)
                      txt = lm_144(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_145(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_e::Absyn.Exp
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_e <| rest)  => begin
                      txt = dumpExp(txt, i_e)
                      txt = Tpl.nextIter(txt)
                      txt = lm_145(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_146(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_row::IList
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_row <| rest)  => begin
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_145(txt, i_row)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.nextIter(txt)
                      txt = lm_146(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_147(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_e::Absyn.Exp
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_e <| rest)  => begin
                      txt = dumpExp(txt, i_e)
                      txt = Tpl.nextIter(txt)
                      txt = lm_147(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_148(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_e::Absyn.Exp
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_e <| rest)  => begin
                      txt = dumpExp(txt, i_e)
                      txt = Tpl.nextIter(txt)
                      txt = lm_148(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpExp(in_txt::Tpl.Text, in_a_exp::Absyn.Exp)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_index::Absyn.Exp
                  local i_exps::IList
                  local i_rest::Absyn.Exp
                  local i_head::Absyn.Exp
                  local i_id::Absyn.Ident
                  local i_code::Absyn.CodeNode
                  local i_expressions::IList
                  local i_stop::Absyn.Exp
                  local i_step::Absyn.Exp
                  local i_start::Absyn.Exp
                  local i_matrix::IList
                  local i_arrayExp::IList
                  local i_function__::Absyn.ComponentRef
                  local i_functionArgs::Absyn.FunctionArgs
                  local i_exp::Absyn.Exp
                  local i_op::Absyn.Operator
                  local i_exp2::Absyn.Exp
                  local i_e::Absyn.Exp
                  local i_exp1::Absyn.Exp
                  local i_value_2::Bool
                  local i_componentRef::Absyn.ComponentRef
                  local i_value_1::String
                  local i_value::ModelicaInteger
                  local l_list__str::Tpl.Text
                  local l_rest__str::Tpl.Text
                  local l_head__str::Tpl.Text
                  local l_tuple__str::Tpl.Text
                  local l_stop__str::Tpl.Text
                  local l_step__str::Tpl.Text
                  local l_start__str::Tpl.Text
                  local l_matrix__str::Tpl.Text
                  local l_array__str::Tpl.Text
                  local l_func__str::Tpl.Text
                  local l_args__str::Tpl.Text
                  local l_exp__str::Tpl.Text
                  local l_op__str::Tpl.Text
                  local l_rhs__str::Tpl.Text
                  local l_lhs__str::Tpl.Text
                @match (in_txt, in_a_exp) begin
                  (txt, Absyn.INTEGER(value = i_value))  => begin
                      txt = Tpl.writeStr(txt, intString(i_value))
                    txt
                  end

                  (txt, Absyn.REAL(value = i_value_1))  => begin
                      txt = Tpl.writeStr(txt, i_value_1)
                    txt
                  end

                  (txt, Absyn.CREF(componentRef = i_componentRef))  => begin
                      txt = dumpCref(txt, i_componentRef)
                    txt
                  end

                  (txt, Absyn.STRING(value = i_value_1))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""))
                      txt = Tpl.pushBlock(txt, Tpl.BT_ABS_INDENT(0))
                      txt = Tpl.writeStr(txt, i_value_1)
                      txt = Tpl.popBlock(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""))
                    txt
                  end

                  (txt, Absyn.BOOL(value = i_value_2))  => begin
                      txt = Tpl.writeStr(txt, Tpl.booleanString(i_value_2))
                    txt
                  end

                  (txt, i_e && Absyn.BINARY(exp1 = i_exp1, exp2 = i_exp2, op = i_op))  => begin
                      l_lhs__str = dumpOperand(Tpl.emptyTxt, i_exp1, i_e, true)
                      l_rhs__str = dumpOperand(Tpl.emptyTxt, i_exp2, i_e, false)
                      l_op__str = dumpOperator(Tpl.emptyTxt, i_op)
                      txt = Tpl.writeText(txt, l_lhs__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "))
                      txt = Tpl.writeText(txt, l_op__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "))
                      txt = Tpl.writeText(txt, l_rhs__str)
                    txt
                  end

                  (txt, i_e && Absyn.UNARY(exp = i_exp, op = i_op))  => begin
                      l_exp__str = dumpOperand(Tpl.emptyTxt, i_exp, i_e, false)
                      l_op__str = dumpOperator(Tpl.emptyTxt, i_op)
                      txt = Tpl.writeText(txt, l_op__str)
                      txt = Tpl.writeText(txt, l_exp__str)
                    txt
                  end

                  (txt, i_e && Absyn.LBINARY(exp1 = i_exp1, exp2 = i_exp2, op = i_op))  => begin
                      l_lhs__str = dumpOperand(Tpl.emptyTxt, i_exp1, i_e, true)
                      l_rhs__str = dumpOperand(Tpl.emptyTxt, i_exp2, i_e, false)
                      l_op__str = dumpOperator(Tpl.emptyTxt, i_op)
                      txt = Tpl.writeText(txt, l_lhs__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "))
                      txt = Tpl.writeText(txt, l_op__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "))
                      txt = Tpl.writeText(txt, l_rhs__str)
                    txt
                  end

                  (txt, i_e && Absyn.LUNARY(exp = i_exp, op = i_op))  => begin
                      l_exp__str = dumpOperand(Tpl.emptyTxt, i_exp, i_e, false)
                      l_op__str = dumpOperator(Tpl.emptyTxt, i_op)
                      txt = Tpl.writeText(txt, l_op__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "))
                      txt = Tpl.writeText(txt, l_exp__str)
                    txt
                  end

                  (txt, i_e && Absyn.RELATION(exp1 = i_exp1, exp2 = i_exp2, op = i_op))  => begin
                      l_lhs__str = dumpOperand(Tpl.emptyTxt, i_exp1, i_e, true)
                      l_rhs__str = dumpOperand(Tpl.emptyTxt, i_exp2, i_e, false)
                      l_op__str = dumpOperator(Tpl.emptyTxt, i_op)
                      txt = Tpl.writeText(txt, l_lhs__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "))
                      txt = Tpl.writeText(txt, l_op__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "))
                      txt = Tpl.writeText(txt, l_rhs__str)
                    txt
                  end

                  (txt, i_exp && Absyn.IFEXP(ifExp = _))  => begin
                      txt = dumpIfExp(txt, i_exp)
                    txt
                  end

                  (txt, Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "\array"), functionArgs = i_functionArgs))  => begin
                      l_args__str = dumpFunctionArgs(Tpl.emptyTxt, i_functionArgs)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("{"))
                      txt = Tpl.writeText(txt, l_args__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"))
                    txt
                  end

                  (txt, Absyn.CALL(function_ = i_function__, functionArgs = i_functionArgs))  => begin
                      l_func__str = dumpCref(Tpl.emptyTxt, i_function__)
                      l_args__str = dumpFunctionArgs(Tpl.emptyTxt, i_functionArgs)
                      txt = Tpl.writeText(txt, l_func__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("("))
                      txt = Tpl.writeText(txt, l_args__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end

                  (txt, Absyn.PARTEVALFUNCTION(function_ = i_function__, functionArgs = i_functionArgs))  => begin
                      l_func__str = dumpCref(Tpl.emptyTxt, i_function__)
                      l_args__str = dumpFunctionArgs(Tpl.emptyTxt, i_functionArgs)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("function "))
                      txt = Tpl.writeText(txt, l_func__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("("))
                      txt = Tpl.writeText(txt, l_args__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end

                  (txt, Absyn.ARRAY(arrayExp = i_arrayExp))  => begin
                      l_array__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_array__str = lm_144(l_array__str, i_arrayExp)
                      l_array__str = Tpl.popIter(l_array__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("{"))
                      txt = Tpl.writeText(txt, l_array__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"))
                    txt
                  end

                  (txt, Absyn.MATRIX(matrix = i_matrix))  => begin
                      l_matrix__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING("; ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_matrix__str = lm_146(l_matrix__str, i_matrix)
                      l_matrix__str = Tpl.popIter(l_matrix__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("["))
                      txt = Tpl.writeText(txt, l_matrix__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("]"))
                    txt
                  end

                  (txt, i_e && Absyn.RANGE(step = SOME(i_step), start = i_start, stop = i_stop))  => begin
                      l_start__str = dumpOperand(Tpl.emptyTxt, i_start, i_e, false)
                      l_step__str = dumpOperand(Tpl.emptyTxt, i_step, i_e, false)
                      l_stop__str = dumpOperand(Tpl.emptyTxt, i_stop, i_e, false)
                      txt = Tpl.writeText(txt, l_start__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(":"))
                      txt = Tpl.writeText(txt, l_step__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(":"))
                      txt = Tpl.writeText(txt, l_stop__str)
                    txt
                  end

                  (txt, i_e && Absyn.RANGE(step = NONE(), start = i_start, stop = i_stop))  => begin
                      l_start__str = dumpOperand(Tpl.emptyTxt, i_start, i_e, false)
                      l_stop__str = dumpOperand(Tpl.emptyTxt, i_stop, i_e, false)
                      txt = Tpl.writeText(txt, l_start__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(":"))
                      txt = Tpl.writeText(txt, l_stop__str)
                    txt
                  end

                  (txt, Absyn.TUPLE(expressions = i_expressions))  => begin
                      l_tuple__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, SOME(Tpl.ST_STRING("")), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_tuple__str = lm_147(l_tuple__str, i_expressions)
                      l_tuple__str = Tpl.popIter(l_tuple__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("("))
                      txt = Tpl.writeText(txt, l_tuple__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end

                  (txt, Absyn.END())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("end"))
                    txt
                  end

                  (txt, Absyn.CODE(code = i_code))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("Code("))
                      txt = dumpCodeNode(txt, i_code)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end

                  (txt, Absyn.AS(exp = i_exp, id = i_id))  => begin
                      l_exp__str = dumpExp(Tpl.emptyTxt, i_exp)
                      txt = Tpl.writeStr(txt, i_id)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" as "))
                      txt = Tpl.writeText(txt, l_exp__str)
                    txt
                  end

                  (txt, Absyn.CONS(head = i_head, rest = i_rest))  => begin
                      l_head__str = dumpExp(Tpl.emptyTxt, i_head)
                      l_rest__str = dumpExp(Tpl.emptyTxt, i_rest)
                      txt = Tpl.writeText(txt, l_head__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" :: "))
                      txt = Tpl.writeText(txt, l_rest__str)
                    txt
                  end

                  (txt, i_exp && Absyn.MATCHEXP(matchTy = _))  => begin
                      txt = dumpMatchExp(txt, i_exp)
                    txt
                  end

                  (txt, Absyn.LIST(exps = i_exps))  => begin
                      l_list__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_list__str = lm_148(l_list__str, i_exps)
                      l_list__str = Tpl.popIter(l_list__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("{"))
                      txt = Tpl.writeText(txt, l_list__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"))
                    txt
                  end

                  (txt, Absyn.DOT(exp = i_exp, index = i_index))  => begin
                      txt = dumpExp(txt, i_exp)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("."))
                      txt = dumpExp(txt, i_index)
                    txt
                  end

                  (txt, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("/* AbsynDumpTpl.dumpExp: UNHANDLED Abyn.Exp */"))
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpLhsExp(in_txt::Tpl.Text, in_a_lhs::Absyn.Exp)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_lhs::Absyn.Exp
                @match (in_txt, in_a_lhs) begin
                  (txt, i_lhs && Absyn.IFEXP(ifExp = _))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("("))
                      txt = dumpExp(txt, i_lhs)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end

                  (txt, i_lhs)  => begin
                      txt = dumpExp(txt, i_lhs)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_151(in_txt::Tpl.Text, in_mArg::Bool, in_a_op__str::Tpl.Text)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_op__str::Tpl.Text
                @match (in_txt, in_mArg, in_a_op__str) begin
                  (txt, false, a_op__str)  => begin
                      txt = Tpl.writeText(txt, a_op__str)
                    txt
                  end

                  (txt, _, a_op__str)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("("))
                      txt = Tpl.writeText(txt, a_op__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"))
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpOperand(txt::Tpl.Text, a_operand::Absyn.Exp, a_operation::Absyn.Exp, a_lhs::Bool)::Tpl.Text
              local out_txt::Tpl.Text

              local ret_1::Bool
              local l_op__str::Tpl.Text

              l_op__str = dumpExp(Tpl.emptyTxt, a_operand)
              ret_1 = Dump.shouldParenthesize(a_operand, a_operation, a_lhs)
              out_txt = fun_151(txt, ret_1, l_op__str)
          out_txt
        end

        function dumpIfExp(in_txt::Tpl.Text, in_a_if__exp::Absyn.Exp)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_elseIfBranch::IList
                  local i_elseBranch::Absyn.Exp
                  local i_trueBranch::Absyn.Exp
                  local i_ifExp::Absyn.Exp
                  local l_else__if__str::Tpl.Text
                  local l_else__branch__str::Tpl.Text
                  local l_true__branch__str::Tpl.Text
                  local l_cond__str::Tpl.Text
                @match (in_txt, in_a_if__exp) begin
                  (txt, Absyn.IFEXP(ifExp = i_ifExp, trueBranch = i_trueBranch, elseBranch = i_elseBranch, elseIfBranch = i_elseIfBranch))  => begin
                      l_cond__str = dumpExp(Tpl.emptyTxt, i_ifExp)
                      l_true__branch__str = dumpExp(Tpl.emptyTxt, i_trueBranch)
                      l_else__branch__str = dumpExp(Tpl.emptyTxt, i_elseBranch)
                      l_else__if__str = dumpElseIfExp(Tpl.emptyTxt, i_elseIfBranch)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("if "))
                      txt = Tpl.writeText(txt, l_cond__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" then "))
                      txt = Tpl.writeText(txt, l_true__branch__str)
                      txt = Tpl.writeText(txt, l_else__if__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" else "))
                      txt = Tpl.writeText(txt, l_else__branch__str)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_154(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_branch::Absyn.Exp
                  local i_cond::Absyn.Exp
                  local l_branch__str::Tpl.Text
                  local l_cond__str::Tpl.Text
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, (i_cond, i_branch) <| rest)  => begin
                      l_cond__str = dumpExp(Tpl.emptyTxt, i_cond)
                      l_branch__str = dumpExp(Tpl.emptyTxt, i_branch)
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(1))
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("elseif "))
                      txt = Tpl.writeText(txt, l_cond__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" then "))
                      txt = Tpl.writeText(txt, l_branch__str)
                      txt = Tpl.popBlock(txt)
                      txt = Tpl.nextIter(txt)
                      txt = lm_154(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpElseIfExp(txt::Tpl.Text, a_else__if::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
              out_txt = lm_154(out_txt, a_else__if)
              out_txt = Tpl.popIter(out_txt)
          out_txt
        end

        function fun_156(in_txt::Tpl.Text, in_a_boolean::Bool)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_boolean) begin
                  (txt, false)  => begin
                    txt
                  end

                  (txt, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("initial "))
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_157(in_txt::Tpl.Text, in_a_boolean::Bool)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_boolean) begin
                  (txt, false)  => begin
                    txt
                  end

                  (txt, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("initial "))
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_158(in_txt::Tpl.Text, in_a_boolean::Bool)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_boolean) begin
                  (txt, false)  => begin
                    txt
                  end

                  (txt, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("initial "))
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpCodeNode(in_txt::Tpl.Text, in_a_code::Absyn.CodeNode)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_modification::Absyn.Modification
                  local i_exp::Absyn.Exp
                  local i_element::Absyn.Element
                  local i_algorithmItemLst::IList
                  local i_equationItemLst::IList
                  local i_boolean::Bool
                  local i_componentRef::Absyn.ComponentRef
                  local i_path::Absyn.Path
                  local l_algs__str::Tpl.Text
                  local l_eql__str::Tpl.Text
                  local l_initial__str::Tpl.Text
                @match (in_txt, in_a_code) begin
                  (txt, Absyn.C_TYPENAME(path = i_path))  => begin
                      txt = dumpPath(txt, i_path)
                    txt
                  end

                  (txt, Absyn.C_VARIABLENAME(componentRef = i_componentRef))  => begin
                      txt = dumpCref(txt, i_componentRef)
                    txt
                  end

                  (txt, Absyn.C_CONSTRAINTSECTION(boolean = i_boolean, equationItemLst = i_equationItemLst))  => begin
                      l_initial__str = fun_156(Tpl.emptyTxt, i_boolean)
                      l_eql__str = dumpEquationItems(Tpl.emptyTxt, i_equationItemLst)
                      txt = Tpl.writeText(txt, l_initial__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE("constraint\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.writeText(txt, l_eql__str)
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, Absyn.C_EQUATIONSECTION(boolean = i_boolean, equationItemLst = i_equationItemLst))  => begin
                      l_initial__str = fun_157(Tpl.emptyTxt, i_boolean)
                      l_eql__str = dumpEquationItems(Tpl.emptyTxt, i_equationItemLst)
                      txt = Tpl.writeText(txt, l_initial__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE("equation\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.writeText(txt, l_eql__str)
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, Absyn.C_ALGORITHMSECTION(boolean = i_boolean, algorithmItemLst = i_algorithmItemLst))  => begin
                      l_initial__str = fun_158(Tpl.emptyTxt, i_boolean)
                      l_algs__str = dumpAlgorithmItems(Tpl.emptyTxt, i_algorithmItemLst)
                      txt = Tpl.writeText(txt, l_initial__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE("algorithm\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.writeText(txt, l_algs__str)
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, Absyn.C_ELEMENT(element = i_element))  => begin
                      txt = dumpElement(txt, i_element, Dump.defaultDumpOptions)
                    txt
                  end

                  (txt, Absyn.C_EXPRESSION(exp = i_exp))  => begin
                      txt = dumpExp(txt, i_exp)
                    txt
                  end

                  (txt, Absyn.C_MODIFICATION(modification = i_modification))  => begin
                      txt = dumpModification(txt, i_modification)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_160(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_c::Absyn.Case
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_c <| rest)  => begin
                      txt = dumpMatchCase(txt, i_c)
                      txt = Tpl.nextIter(txt)
                      txt = lm_160(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpMatchExp(in_txt::Tpl.Text, in_a_match__exp::Absyn.Exp)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_comment::Option
                  local i_cases::IList
                  local i_localDecls::IList
                  local i_inputExp::Absyn.Exp
                  local i_matchTy::Absyn.MatchType
                  local l_cmt__str::Tpl.Text
                  local l_cases__str::Tpl.Text
                  local l_locals__str::Tpl.Text
                  local l_input__str::Tpl.Text
                  local l_ty__str::Tpl.Text
                @match (in_txt, in_a_match__exp) begin
                  (txt, Absyn.MATCHEXP(matchTy = i_matchTy, inputExp = i_inputExp, localDecls = i_localDecls, cases = i_cases, comment = i_comment))  => begin
                      l_ty__str = dumpMatchType(Tpl.emptyTxt, i_matchTy)
                      l_input__str = dumpExp(Tpl.emptyTxt, i_inputExp)
                      l_locals__str = dumpMatchLocals(Tpl.emptyTxt, i_localDecls)
                      l_cases__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING_LIST(list("\n", "\n"), true)), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_cases__str = lm_160(l_cases__str, i_cases)
                      l_cases__str = Tpl.popIter(l_cases__str)
                      l_cmt__str = dumpStringCommentOption(Tpl.emptyTxt, i_comment)
                      txt = Tpl.writeText(txt, l_ty__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "))
                      txt = Tpl.writeText(txt, l_input__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.writeText(txt, l_locals__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2))
                      txt = Tpl.writeText(txt, l_cases__str)
                      txt = Tpl.writeText(txt, l_cmt__str)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.popBlock(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("end "))
                      txt = Tpl.writeText(txt, l_ty__str)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpMatchType(in_txt::Tpl.Text, in_a_match__type::Absyn.MatchType)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_match__type) begin
                  (txt, Absyn.MATCH())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("match"))
                    txt
                  end

                  (txt, Absyn.MATCHCONTINUE())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("matchcontinue"))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_163(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_decl::Absyn.ElementItem
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_decl <| rest)  => begin
                      txt = dumpElementItem(txt, i_decl, Dump.defaultDumpOptions)
                      txt = Tpl.nextIter(txt)
                      txt = lm_163(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpMatchLocals(in_txt::Tpl.Text, in_a_locals::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_locals::IList
                @match (in_txt, in_a_locals) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_locals)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_LINE("  local\n"))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(4))
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_163(txt, i_locals)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.softNewLine(txt)
                      txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE())
                      txt = Tpl.popBlock(txt)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_165(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_eq::Absyn.EquationItem
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_eq <| rest)  => begin
                      txt = dumpEquationItem(txt, i_eq)
                      txt = Tpl.nextIter(txt)
                      txt = lm_165(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_166(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_alg::Absyn.AlgorithmItem
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_alg <| rest)  => begin
                      txt = dumpAlgorithmItem(txt, i_alg)
                      txt = Tpl.nextIter(txt)
                      txt = lm_166(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpMatchEquations(in_txt::Tpl.Text, in_a_cp::Absyn.ClassPart)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_algs::IList
                  local i_eql::IList
                @match (in_txt, in_a_cp) begin
                  (txt, Absyn.EQUATIONS(contents =  nil()))  => begin
                    txt
                  end

                  (txt, Absyn.EQUATIONS(contents = i_eql))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST(list("\n", "  equation\n"), true))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(4))
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_165(txt, i_eql)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, Absyn.ALGORITHMS(contents =  nil()))  => begin
                    txt
                  end

                  (txt, Absyn.ALGORITHMS(contents = i_algs))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST(list("\n", "  algorithm\n"), true))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(4))
                      txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      txt = lm_166(txt, i_algs)
                      txt = Tpl.popIter(txt)
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_168(in_txt::Tpl.Text, in_a_patternGuard::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_g::Absyn.Exp
                @match (in_txt, in_a_patternGuard) begin
                  (txt, SOME(i_g))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("guard "))
                      txt = dumpExp(txt, i_g)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_169(in_txt::Tpl.Text, in_a_eql__str::Tpl.Text, in_a_result__str::Tpl.Text)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_result__str::Tpl.Text
                @match (in_txt, in_a_eql__str, in_a_result__str) begin
                  (txt, Tpl.MEM_TEXT(tokens =  nil()), a_result__str)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("then "))
                      txt = Tpl.writeText(txt, a_result__str)
                    txt
                  end

                  (txt, _, a_result__str)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST(list("\n", "  then\n"), true))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(4))
                      txt = Tpl.writeText(txt, a_result__str)
                      txt = Tpl.popBlock(txt)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_170(in_txt::Tpl.Text, in_a_eql__str::Tpl.Text, in_a_result__str::Tpl.Text)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_result__str::Tpl.Text
                @match (in_txt, in_a_eql__str, in_a_result__str) begin
                  (txt, Tpl.MEM_TEXT(tokens =  nil()), a_result__str)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("then "))
                      txt = Tpl.writeText(txt, a_result__str)
                    txt
                  end

                  (txt, _, a_result__str)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST(list("\n", "  then\n"), true))
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(4))
                      txt = Tpl.writeText(txt, a_result__str)
                      txt = Tpl.popBlock(txt)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpMatchCase(in_txt::Tpl.Text, in_a_c::Absyn.Case)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_comment::Option
                  local i_result::Absyn.Exp
                  local i_classPart::Absyn.ClassPart
                  local i_patternGuard::Option
                  local i_pattern::Absyn.Exp
                  local l_cmt__str::Tpl.Text
                  local l_then__str::Tpl.Text
                  local l_result__str::Tpl.Text
                  local l_eql__str::Tpl.Text
                  local l_guard__str::Tpl.Text
                  local l_pattern__str::Tpl.Text
                @match (in_txt, in_a_c) begin
                  (txt, Absyn.CASE(pattern = i_pattern, patternGuard = i_patternGuard, classPart = i_classPart, result = i_result, comment = i_comment))  => begin
                      l_pattern__str = dumpExp(Tpl.emptyTxt, i_pattern)
                      l_guard__str = fun_168(Tpl.emptyTxt, i_patternGuard)
                      l_eql__str = dumpMatchEquations(Tpl.emptyTxt, i_classPart)
                      l_result__str = dumpExp(Tpl.emptyTxt, i_result)
                      l_then__str = fun_169(Tpl.emptyTxt, l_eql__str, l_result__str)
                      l_cmt__str = dumpStringCommentOption(Tpl.emptyTxt, i_comment)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("case "))
                      txt = Tpl.writeText(txt, l_pattern__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "))
                      txt = Tpl.writeText(txt, l_guard__str)
                      txt = Tpl.writeText(txt, l_cmt__str)
                      txt = Tpl.writeText(txt, l_eql__str)
                      txt = Tpl.writeText(txt, l_then__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"))
                    txt
                  end

                  (txt, Absyn.ELSE(classPart = i_classPart, result = i_result, comment = i_comment))  => begin
                      l_eql__str = dumpMatchEquations(Tpl.emptyTxt, i_classPart)
                      l_result__str = dumpExp(Tpl.emptyTxt, i_result)
                      l_then__str = fun_170(Tpl.emptyTxt, l_eql__str, l_result__str)
                      l_cmt__str = dumpStringCommentOption(Tpl.emptyTxt, i_comment)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("else "))
                      txt = Tpl.writeText(txt, l_cmt__str)
                      txt = Tpl.writeText(txt, l_eql__str)
                      txt = Tpl.writeText(txt, l_then__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpOperator(in_txt::Tpl.Text, in_a_op::Absyn.Operator)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_op) begin
                  (txt, Absyn.ADD())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"))
                    txt
                  end

                  (txt, Absyn.SUB())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("-"))
                    txt
                  end

                  (txt, Absyn.MUL())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("*"))
                    txt
                  end

                  (txt, Absyn.DIV())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("/"))
                    txt
                  end

                  (txt, Absyn.POW())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("^"))
                    txt
                  end

                  (txt, Absyn.UPLUS())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"))
                    txt
                  end

                  (txt, Absyn.UMINUS())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("-"))
                    txt
                  end

                  (txt, Absyn.ADD_EW())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(".+"))
                    txt
                  end

                  (txt, Absyn.SUB_EW())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(".-"))
                    txt
                  end

                  (txt, Absyn.MUL_EW())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(".*"))
                    txt
                  end

                  (txt, Absyn.DIV_EW())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("./"))
                    txt
                  end

                  (txt, Absyn.POW_EW())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(".^"))
                    txt
                  end

                  (txt, Absyn.UPLUS_EW())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(".+"))
                    txt
                  end

                  (txt, Absyn.UMINUS_EW())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(".-"))
                    txt
                  end

                  (txt, Absyn.AND())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("and"))
                    txt
                  end

                  (txt, Absyn.OR())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("or"))
                    txt
                  end

                  (txt, Absyn.NOT())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("not"))
                    txt
                  end

                  (txt, Absyn.LESS())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("<"))
                    txt
                  end

                  (txt, Absyn.LESSEQ())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("<="))
                    txt
                  end

                  (txt, Absyn.GREATER())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(">"))
                    txt
                  end

                  (txt, Absyn.GREATEREQ())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(">="))
                    txt
                  end

                  (txt, Absyn.EQUAL())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("=="))
                    txt
                  end

                  (txt, Absyn.NEQUAL())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("<>"))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_173(in_txt::Tpl.Text, in_mArg::Bool)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_mArg) begin
                  (txt, false)  => begin
                    txt
                  end

                  (txt, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"))
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpCref(in_txt::Tpl.Text, in_a_cref::Absyn.ComponentRef)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_componentRef::Absyn.ComponentRef
                  local i_subscripts::IList
                  local i_name::Absyn.Ident
                  local ret_0::Bool
                @match (in_txt, in_a_cref) begin
                  (txt, Absyn.CREF_QUAL(name = i_name, subscripts = i_subscripts, componentRef = i_componentRef))  => begin
                      txt = Tpl.writeStr(txt, i_name)
                      txt = dumpSubscripts(txt, i_subscripts)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("."))
                      txt = dumpCref(txt, i_componentRef)
                    txt
                  end

                  (txt, Absyn.CREF_IDENT(name = i_name, subscripts = i_subscripts))  => begin
                      txt = Tpl.writeStr(txt, i_name)
                      txt = dumpSubscripts(txt, i_subscripts)
                    txt
                  end

                  (txt, Absyn.CREF_FULLYQUALIFIED(componentRef = i_componentRef))  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("."))
                      txt = dumpCref(txt, i_componentRef)
                    txt
                  end

                  (txt, Absyn.WILD())  => begin
                      ret_0 = Config.acceptMetaModelicaGrammar()
                      txt = fun_173(txt, ret_0)
                    txt
                  end

                  (txt, Absyn.ALLWILD())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("__"))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_175(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_arg::Absyn.Exp
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_arg <| rest)  => begin
                      txt = dumpExp(txt, i_arg)
                      txt = Tpl.nextIter(txt)
                      txt = lm_175(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_176(in_txt::Tpl.Text, in_items::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::IList
                  local i_narg::Absyn.NamedArg
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_narg <| rest)  => begin
                      txt = dumpNamedArg(txt, i_narg)
                      txt = Tpl.nextIter(txt)
                      txt = lm_176(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_177(in_txt::Tpl.Text, in_a_argNames::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_argNames) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, _)  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "))
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_178(in_txt::Tpl.Text, in_a_args__str::Tpl.Text, in_a_argNames::IList)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local a_argNames::IList
                @match (in_txt, in_a_args__str, in_a_argNames) begin
                  (txt, Tpl.MEM_TEXT(tokens =  nil()), _)  => begin
                    txt
                  end

                  (txt, _, a_argNames)  => begin
                      txt = fun_177(txt, a_argNames)
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_179(in_txt::Tpl.Text, in_items::Absyn.ForIterators)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::Absyn.ForIterators
                  local i_i::Absyn.ForIterator
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_i <| rest)  => begin
                      txt = dumpForIterator(txt, i_i)
                      txt = Tpl.nextIter(txt)
                      txt = lm_179(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_180(in_txt::Tpl.Text, in_a_iterType::Absyn.ReductionIterType)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                @match (in_txt, in_a_iterType) begin
                  (txt, Absyn.THREAD())  => begin
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("threaded "))
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpFunctionArgs(in_txt::Tpl.Text, in_a_args::Absyn.FunctionArgs)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_iterType::Absyn.ReductionIterType
                  local i_iterators::Absyn.ForIterators
                  local i_exp::Absyn.Exp
                  local i_argNames::IList
                  local i_args::IList
                  local l_iter__str::Tpl.Text
                  local l_exp__str::Tpl.Text
                  local l_separator::Tpl.Text
                  local l_namedargs__str::Tpl.Text
                  local l_args__str::Tpl.Text
                @match (in_txt, in_a_args) begin
                  (txt, Absyn.FUNCTIONARGS(args = i_args, argNames = i_argNames))  => begin
                      l_args__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_args__str = lm_175(l_args__str, i_args)
                      l_args__str = Tpl.popIter(l_args__str)
                      l_namedargs__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_namedargs__str = lm_176(l_namedargs__str, i_argNames)
                      l_namedargs__str = Tpl.popIter(l_namedargs__str)
                      l_separator = fun_178(Tpl.emptyTxt, l_args__str, i_argNames)
                      txt = Tpl.writeText(txt, l_args__str)
                      txt = Tpl.writeText(txt, l_separator)
                      txt = Tpl.writeText(txt, l_namedargs__str)
                    txt
                  end

                  (txt, Absyn.FOR_ITER_FARG(exp = i_exp, iterators = i_iterators, iterType = i_iterType))  => begin
                      l_exp__str = dumpExp(Tpl.emptyTxt, i_exp)
                      l_iter__str = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
                      l_iter__str = lm_179(l_iter__str, i_iterators)
                      l_iter__str = Tpl.popIter(l_iter__str)
                      txt = Tpl.writeText(txt, l_exp__str)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "))
                      txt = fun_180(txt, i_iterType)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("for "))
                      txt = Tpl.writeText(txt, l_iter__str)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpNamedArg(in_txt::Tpl.Text, in_a_narg::Absyn.NamedArg)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_argValue::Absyn.Exp
                  local i_argName::Absyn.Ident
                @match (in_txt, in_a_narg) begin
                  (txt, Absyn.NAMEDARG(argName = i_argName, argValue = i_argValue))  => begin
                      txt = Tpl.writeStr(txt, i_argName)
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "))
                      txt = dumpExp(txt, i_argValue)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function lm_183(in_txt::Tpl.Text, in_items::Absyn.ForIterators)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local rest::Absyn.ForIterators
                  local i_i::Absyn.ForIterator
                @match (in_txt, in_items) begin
                  (txt,  nil())  => begin
                    txt
                  end

                  (txt, i_i <| rest)  => begin
                      txt = dumpForIterator(txt, i_i)
                      txt = Tpl.nextIter(txt)
                      txt = lm_183(txt, rest)
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpForIterators(txt::Tpl.Text, a_iters::Absyn.ForIterators)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()))
              out_txt = lm_183(out_txt, a_iters)
              out_txt = Tpl.popIter(out_txt)
          out_txt
        end

        function fun_185(in_txt::Tpl.Text, in_a_range::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_r::Absyn.Exp
                @match (in_txt, in_a_range) begin
                  (txt, SOME(i_r))  => begin
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(1))
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("in "))
                      txt = dumpExp(txt, i_r)
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function fun_186(in_txt::Tpl.Text, in_a_guardExp::Option)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_g::Absyn.Exp
                @match (in_txt, in_a_guardExp) begin
                  (txt, SOME(i_g))  => begin
                      txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(1))
                      txt = Tpl.writeTok(txt, Tpl.ST_STRING("guard "))
                      txt = dumpExp(txt, i_g)
                      txt = Tpl.popBlock(txt)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function dumpForIterator(in_txt::Tpl.Text, in_a_iterator::Absyn.ForIterator)::Tpl.Text
              local out_txt::Tpl.Text

              out_txt = begin
                  local txt::Tpl.Text
                  local i_name::String
                  local i_guardExp::Option
                  local i_range::Option
                  local l_guard__str::Tpl.Text
                  local l_range__str::Tpl.Text
                @match (in_txt, in_a_iterator) begin
                  (txt, Absyn.ITERATOR(range = i_range, guardExp = i_guardExp, name = i_name))  => begin
                      l_range__str = fun_185(Tpl.emptyTxt, i_range)
                      l_guard__str = fun_186(Tpl.emptyTxt, i_guardExp)
                      txt = Tpl.writeStr(txt, i_name)
                      txt = Tpl.writeText(txt, l_guard__str)
                      txt = Tpl.writeText(txt, l_range__str)
                    txt
                  end

                  (txt, _)  => begin
                    txt
                  end
                end
              end
          out_txt
        end

        function errorMsg(txt::Tpl.Text, a_errMessage::String)::Tpl.Text
              local out_txt::Tpl.Text

              Tpl.addTemplateError(a_errMessage)
              out_txt = Tpl.writeStr(txt, a_errMessage)
          out_txt
        end

    #= So that we can use wildcard imports and named imports when they do occur. Not good Julia practice =#
    @exportAll()
  end