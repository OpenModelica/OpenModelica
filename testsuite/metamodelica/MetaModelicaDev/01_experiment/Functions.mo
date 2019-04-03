package Functions

import Types;

function test
  input String s;
  output Integer x;
algorithm
  x := matchcontinue s
    case "one"   then 1;
    case "two"   then 2;
    case "three" then 3;
    case _ then 0;
  end matchcontinue;
end test;

function factorial
  input Integer inValue;
  output Integer outValue;
algorithm
  outValue := matchcontinue inValue
    local Integer n;
    case 0 then 1;
    case n then n*factorial(n-1);
  end matchcontinue;
end factorial;

// your code here


end Functions;
