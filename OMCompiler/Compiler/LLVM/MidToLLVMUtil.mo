encapsulated package MidToLLVMUtil
" file:        MidToLLVMUtil.mo
  package:     MidToLLVMUtil
  description: Various utility procedures. Mainly used for the LLVM tests.
  author: John Tinnerholm
"
protected
import CodegenUtil.{underscorePath,dotPath};
import EXT_LLVM;
import List;
import MidCode;
import System;
import Tpl.{Text,textString};
import ValuesUtil;
public
function funcsAreJitCompiled
  input list<Absyn.Path> funcNames;
  output Boolean b;
algorithm
  b := Util.boolAndList(List.map(funcNames,funcIsJitCompiled));
end funcsAreJitCompiled;

function funcIsJitCompiled
  "Checks if there exists a handler to a function with the given Absyn.path."
  input Absyn.Path fName;
  output Boolean b;
protected
  String fString;
algorithm
  fString := textString(underscorePath(Tpl.MEM_TEXT({},{}),fName));
  b := EXT_LLVM.funcIsJitCompiled(fString);
end funcIsJitCompiled;

//Note that this function maybe should be in there own file, ValueToMid or something like that.
function valLstToMidVarLst
  input list<Values.Value> valLst;
  output list<MidCode.Var> midVarLst;
  algorithm
  midVarLst := List.map(valLst,valueToMidVar);
end valLstToMidVarLst;

function valueToMidVar
  input Values.Value val;
  output MidCode.Var midVar;
algorithm
  midVar := MidCode.VAR("_tmp_" + intString(System.tmpTickIndex(46)),ValuesUtil.valueExpType(val),false);
end valueToMidVar;


annotation(__OpenModelica_Interface="backendInterface");
end MidToLLVMUtil;
