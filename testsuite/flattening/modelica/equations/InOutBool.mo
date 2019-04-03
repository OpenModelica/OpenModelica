// name:     InOutBool
// keywords: equation
// status:   correct

function testBool
  input Integer x;
  input Integer y;
  input Boolean should_be_equal;
  output Boolean t;
algorithm
  t := false;
  if (x == y) and should_be_equal then
     t := true;
  elseif (x <> y) and not should_be_equal then
     t := true;
  end if;
end testBool;

model Booltest
  Boolean t;
equation
  t = testBool(1,1,false);
  t = testBool(1,1,true);
  t = testBool(1,2,false);
  t = testBool(1,2,true);
end Booltest;

// Result:
// function testBool
//   input Integer x;
//   input Integer y;
//   input Boolean should_be_equal;
//   output Boolean t;
// algorithm
//   t := false;
//   if x == y and should_be_equal then
//     t := true;
//   elseif x <> y and not should_be_equal then
//     t := true;
//   end if;
// end testBool;
//
// class Booltest
//   Boolean t;
// equation
//   t = false;
//   t = true;
//   t = true;
//   t = false;
// end Booltest;
// endResult
