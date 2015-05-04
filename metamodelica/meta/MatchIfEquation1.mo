package MatchIfEquation1

function func
  input Integer i;
  output Integer o;
algorithm
  o := match i
    local
      Integer i2;
    case _
      equation
        if i == 1 then
          failure(2 = i);
          1 = i;
          i2 = 42;
        else
          print("Exception!!!\n");
          fail();
        end if;
      then i2;
  end match;
end func;

end MatchIfEquation1;
