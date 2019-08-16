package BoolTests

function returnTrue
  output Boolean b;
algorithm
  b := true;
end returnTrue;

function notTest
  input Boolean b1;
  output Boolean b2;
  protected Integer I = 0;
algorithm
  b2 := not b1;
end notTest;

function orTest
  input Boolean b1;
  input Boolean b2;
  output Boolean bout;
algorithm
  bout := b1 or b2;
end orTest;

function andTest
  input Boolean b1;
  input Boolean b2;
  output Boolean bout;
algorithm
  bout := b1 and b2;
end andTest;

function ltTest
  input Boolean b1;
  input Boolean b2;
  output Boolean bout;
algorithm
  bout := b1 < b2;
end ltTest;

function gtTest
  input Boolean b1;
  input Boolean b2;
  output Boolean bout;
algorithm
  bout := b1 > b2;
end gtTest;

function geqTest
  input Boolean b1;
  input Boolean b2;
  output Boolean bout;
algorithm
  bout := b1 >= b2;
end geqTest;

function leqTest
  input Boolean b1;
  input Boolean b2;
  output Boolean bout;
algorithm
  bout := b1 <= b2;
end leqTest;

function eqTest
  input Boolean b1;
  input Boolean b2;
  output Boolean bout;
algorithm
  bout := b1 == b2;
end eqTest;

function booleanBranching
  input Boolean b1;
  output Boolean b2;
algorithm
  if b1 then
	b2 := b1;
  else
	b2 := false;
  end if;
end booleanBranching;

function mInverse
  input Boolean a;
  input Boolean b;
  input Boolean c;
  output Boolean a_;
  output Boolean b_;
  output Boolean c_;
algorithm
  a_ := not a;
  b_ := not b;
  c_ := not c;
//End of mInverse. I am a comment
end mInverse;

end BoolTests;