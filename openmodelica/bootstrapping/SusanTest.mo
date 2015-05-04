package SusanTest

function main
  input list<String> args;
protected
  list<String> args_1;
algorithm
  args_1 := Flags.new(args);
  _ := match (args_1)
    local
      String arg;
    case {arg} equation TplMain.main(arg); then ();
    case {} equation print("SusanTest.Main: No file given\n"); then fail();
    else equation print("Too many files given as input: " + Util.stringDelimitList(args_1, " ") + "\n"); then fail();
  end match;
end main;

end SusanTest;
