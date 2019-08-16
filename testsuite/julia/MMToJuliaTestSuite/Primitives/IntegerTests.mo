package IntegerTests

function negativeOne
  output Integer b;
algorithm
  b := -1;
end negativeOne;

function five
  "Test to see if we can have function just to return one value"
  output Integer a;
  algorithm
    a:=5;
end five;

function six
  "Test to see if we can have function just to return one value"
  output Integer a;
  algorithm
    a:=6;
end six;

function leet
  output Integer a;
algorithm
  a := 1337 * 8;
end leet;

function leetLeet
  "Try to call a void function in a void function."
  output Integer a;
algorithm
  a := leet();
end leetLeet;

function minusFive
  "Test to see if we can have a function returning a negative value"
  output Integer a;
 algorithm
  a:=-5;
end minusFive;

function iAdd
  "Testing integer addition"
  input Integer a;
  input Integer b;
  output Integer c;
  algorithm
    c := a+b;
end iAdd;

function iMult
  "Testing integer multiplication"
  input Integer a;
  input Integer b;
  output Integer c;
algorithm
  c := a*b;
end iMult;

function iDiv
  "Testing integer division"
  input Integer a;
  input Integer b;
  output Integer c;
algorithm
  c := div(a,b);
end iDiv;

function iSub
  "Testing integer subtraction"
  input Integer a;
  input Integer b;
  output Integer c;
algorithm
  c := a - b;
end iSub;

function negateInteger
  "Check to see if negation works"
  input Integer a;
  output Integer b;
algorithm
  b := -a;
end negateInteger;

function branchTestInteger
  input Integer a;
  output Integer b;
algorithm
  if a == 1 then
	b := 1;
  elseif a == 2 then
	b := 2;
  elseif a == 3 then
	b := 3;
  elseif a == 4 then
	b := 4;
  elseif a == 5 then
	b := 5;
  end if;
end branchTestInteger;

function integerArithmeticTest
  "Check different arithmetic operations"
  input Integer x;
  output Integer y;
  protected Integer t1;
  protected Integer t2;
  protected Real t3;
  protected Real t4;
  algorithm
    t1 := 1;
    t2 := 2;
    y := x*3;
    t3 := t1/t2;
    t4 := t3/t1;

    if t1 < 0 then
	  y := 4;
    end if;
end integerArithmeticTest;

function integerArithmeticTest2
  "Check that DAE optimisations do not cause trouble"
  input Integer x;
  output Integer y;
  algorithm
    y := x+x+x;
end integerArithmeticTest2;

function absoluteVal1
  "Checking greater then operator"
  input Integer a;
  output Integer b;
  algorithm
  if a > 0 then
    b := a;
  else
	b := -a;
  end if;
end absoluteVal1;

function absoluteVal2
  "Checking less then operator"
  input Integer a;
  output Integer b;
  algorithm
  if a < 0 then
    b := -a;
  else
	b := a;
  end if;
end absoluteVal2;

function checkGEQOperator
  "Takes two inputs a,b returns 1 if a >= b."
  input Integer a;
  input Integer b;
  output Integer c;
algorithm
  if a >= b then
	c := 1;
  else
	c := 0;
  end if;
end checkGEQOperator;

function checkLEQOperator
  "Takes two inputs a,b returns 1 if a <= b."
  input Integer a;
  input Integer b;
  output Integer c;
algorithm
  if a <= b then
	c := 1;
  else
	c := 0;
  end if;
end checkLEQOperator;

function checkGTOperator
  "Takes two inputs a,b returns 1 if a > b."
  input Integer a;
  input Integer b;
  output Integer c;
algorithm
  if a > b then
	c := 1;
  else
	c := 0;
  end if;
end checkGTOperator;

function checkLTOperator
  "Takes two inputs a,b returns 1 if a < b."
  input Integer a;
  input Integer b;
  output Integer c;
algorithm
  if a < b then
	c := 1;
  else
	c := 0;
  end if;
end checkLTOperator;

function checkEQOperator
  "Takes two inputs a,b returns 1 if a = b."
  input Integer a;
  input Integer b;
  output Integer c;
algorithm
  if a == b then
	c := 1;
  else
	c := 0;
  end if;
end checkEQOperator;

function mReturnsInt
  "Takes the tuple (a,b,c) doubles them "
  input Integer a;
  input Integer b;
  input Integer c;
  output Integer a1;
  output Integer b1;
  output Integer c1;
algorithm
  a1 := a*2;
  b1 := b*2;
  c1 := c*2;
end mReturnsInt;

function mReturnsInt2
  input Integer a;
  input Real b;
  output Integer a1;
  output Real b1;
algorithm
  a1 := a;
  b1 := b;
end mReturnsInt2;

function callMReturnsInt
  input Integer a;
  input Integer b;
  input Integer c;
  output Integer a1;
  output Integer b2;
  output Integer c3;
algorithm
  (a1,b2,c3) := mReturnsInt(a,b,c);
end callMReturnsInt;


function summa
  "Testing if recursion works."
  input Integer a;
  input Integer i;
  output Integer b;
  algorithm
  if i == 0 then
    b := a;
  else
    b := summa(a+1,i-1);
  end if;
end summa;

function whileSum
  input Integer a;
  output Integer b;
protected
  Integer i;
  Integer summa;
algorithm
  i := 1;
  summa := 0;
  while i <= a loop
    summa := i + summa;
    i := i + 1;
  end while;
  b := summa;
end whileSum;

function castTest
  input Integer a;
  output Real c;
protected
  Integer start = 1;
  Integer stop = 1;
  Integer i = 0;
  Real PI = 3.14;
algorithm
  c := (-2.0 * PI * intReal(i - 1));
end castTest;

end IntegerTests;