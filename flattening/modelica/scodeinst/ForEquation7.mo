// name: ForEquation7
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model ForEquation7
  Real x;
equation
  for i in 1:5 loop
    for j in i+1:i+3 loop
      x = j * i;
    end for;
  end for;
end ForEquation7;

// Result:
// class ForEquation7
//   Real x;
// equation
//   x = 2.0;
//   x = 3.0;
//   x = 4.0;
//   x = 6.0;
//   x = 8.0;
//   x = 10.0;
//   x = 12.0;
//   x = 15.0;
//   x = 18.0;
//   x = 20.0;
//   x = 24.0;
//   x = 28.0;
//   x = 30.0;
//   x = 35.0;
//   x = 40.0;
// end ForEquation7;
// endResult
