// name: IfEquation5
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfEquation5
  Real x[2];
  parameter Boolean p[2] = {false, true};
equation
  x[1] = 1;
  for i in 1:2 loop
    if p[i] then
      x[i] = 2;
    end if;
  end for;
end IfEquation5;

// Result:
// class IfEquation5
//   Real x[1];
//   Real x[2];
//   parameter Boolean p[1] = false;
//   parameter Boolean p[2] = true;
// equation
//   x[1] = 1.0;
//   x[2] = 2.0;
// end IfEquation5;
// endResult
