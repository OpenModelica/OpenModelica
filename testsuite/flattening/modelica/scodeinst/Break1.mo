// name: Break1
// keywords:
// status: correct
//

function f
  input Integer n;
  output Integer res = 0;
algorithm
  for i in 1:n loop
    res := res + i;

    if i > 5 then
      break;
    end if;
  end for;
end f;

model Break1
  Real x1 = f(4);
  Real x2 = f(10);
end Break1;

// Result:
// class Break1
//   Real x1 = 10.0;
//   Real x2 = 21.0;
// end Break1;
// endResult
