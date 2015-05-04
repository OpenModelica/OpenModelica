package Main

import Parse;
import Pam;

function main "Parse and translate a PAM program into MCode,
  then emit it as textual assembly code.
"
  output Integer out;
protected
  Pam.Stmt program;
algorithm
  print("[Parse. Enter a program, then press CTRL+z (Windows) or CTRL+d (Linux).]\n");
  program := Parse.parse();
  _ := Pam.evalStmt({}, program);
  print("\n");
  out := 0;
end main;
end Main;

