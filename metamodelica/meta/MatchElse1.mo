package MatchElse1

function func
  input Integer x;
  output Integer y;
algorithm
  y := match (x)
    case 1
      equation
        print("Sad thing\n");
      then fail();
    else
      equation
        print("Great success\n");
      then 42;
  end match;
end func;

end MatchElse1;
