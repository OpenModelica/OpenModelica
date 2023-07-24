package Main

import Mcode;
import Absyn;

import Parse;
import Trans;
import Emit;

function main "Parse and translate a PAM program into MCode,
  then emit it as textual assembly code.
"
  type Mcode_MCodeLst = list<Mcode.MCode>;
protected
  Absyn.Stmt program;
  Mcode_MCodeLst mcode;
algorithm
  print("[Parse. Enter a program, then press CTRL+z (Windows) or CTRL+d (Linux).]\n");
  program := Parse.parse();
  mcode := Trans.transProgram(program);
  print(Tpl.tplString(Emit.emitAssembly,mcode));
end main;
end Main;

