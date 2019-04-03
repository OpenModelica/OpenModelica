package OptionInteractive

  function someToNone
    input Option<Integer> intOption;
    output Option<Integer> out;
  algorithm
    out := NONE();
  end someToNone;

  function optionIdent
    input Option<Integer> intOption;
    output Option<Integer> out;
  algorithm
    out := intOption;
  end optionIdent;

end OptionInteractive;
