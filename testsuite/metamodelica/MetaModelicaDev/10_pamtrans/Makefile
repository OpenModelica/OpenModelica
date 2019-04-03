SOLUTIONS=SCRIPT.mos
CLEAN=Absyn_* Emit_* Main_* Mcode_* Parse_* Trans_*
DEPS=lexer.o parser.o Emit.mo Tpl.mo.dummy Config.mo.dummy Print.mo.dummy Util.mo.dummy Debug.mo.dummy Flags.mo.dummy Global.mo.dummy System.mo.dummy Error.mo.dummy ErrorExt.mo.dummy List.mo.dummy
include ../common.omc

Debug.mo.dummy:
	test -f ../../../../Compiler/Template/Tpl.mo && cp ../../../../Compiler/Template/Tpl.mo .

Tpl.mo.dummy:
	test -f ../../../../Compiler/Template/Tpl.mo && cp ../../../../Compiler/Template/Tpl.mo .

Print.mo.dummy:
	test -f ../../../../Compiler/Util/Print.mo && cp ../../../../Compiler/Util/Print.mo .

Util.mo.dummy:
	test -f ../../../../Compiler/Util/Util.mo && cp ../../../../Compiler/Util/Util.mo .

Flags.mo.dummy:
	test -f ../../../../Compiler/Util/Flags.mo && cp ../../../../Compiler/Util/Flags.mo .

Global.mo.dummy:
	test -f ../../../../Compiler/Global/Global.mo && cp ../../../../Compiler/Global/Global.mo .

System.mo.dummy:
	test -f ../../../../Compiler/Util/System.mo && cp ../../../../Compiler/Util/System.mo .

Error.mo.dummy:
	test -f ../../../../Compiler/Util/Error.mo && cp ../../../../Compiler/Util/Error.mo .

ErrorExt.mo.dummy:
	test -f ../../../../Compiler/Util/ErrorExt.mo && cp ../../../../Compiler/Util/ErrorExt.mo .

List.mo.dummy:
	test -f ../../../../Compiler/Util/List.mo && cp ../../../../Compiler/Util/List.mo .

Config.mo.dummy:
	test -f ../../../../Compiler/Util/Config.mo && cp ../../../../Compiler/Util/Config.mo .

