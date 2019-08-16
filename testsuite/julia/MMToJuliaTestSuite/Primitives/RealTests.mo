package RealTests

function five
  output Real a;
algorithm
    a:=5;
end five;

function minusFive
  output Real a;
algorithm
  a:=-5;
end minusFive;

function rAdd
  "Testing real addition"
  input Real a;
  input Real b;
  output Real c;
  algorithm
    c := a+b;
end rAdd;

function rMult
  "Testing real multiplication"
  input Real a;
  input Real b;
  output Real c;
algorithm
  c := a*b;
end rMult;

function rDiv
  "Testing real division"
  input Real a;
  input Real b;
  output Real c;
algorithm
  c := a / b;
end rDiv;

function rSub
  "Testing real subtraction"
  input Real a;
  input Real b;
  output Real c;
algorithm
  c := a - b;
end rSub;

function negateReal
  "Check to see if negation works"
  input Real a;
  output Real b;
algorithm
  b := -a;
end negateReal;

function powTest
  "Calculates a ^ b"
  input Real a;
  input Real b;
  output real c;
algorithm
  c := a ^ b;
end powTest;

function branchTestReal
  input Real a;
  output Real b;
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
end branchTestReal;
function realArithmeticTest
  "Check different arithmetic operations"
  input Real x;
  output Real y;
  protected Real t1;
  protected Real t2;
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
end realArithmeticTest;

function realArithmeticTest2
  "Check that DAE optimisations do not cause trouble"
  input Real x;
  output Real y;
  algorithm
    y := x+x+x;
end realArithmeticTest2;

function absoluteVal1
  "Checking greater then operator"
  input Real a;
  output Real b;
  algorithm
  if a > 0 then
    b := a;
  else
	b := -a;
  end if;
end absoluteVal1;

function absoluteVal2
  "Checking less then operator"
  input Real a;
  output Real b;
  algorithm
  if a < 0 then
    b := -a;
  else
	b := a;
  end if;
end absoluteVal2;

function checkGEQOperator
  "Takes two inputs a,b returns 1 if a >= b."
  input Real a;
  input Real b;
  output Real c;
algorithm
  if a >= b then
	c := 1;
  else
	c := 0;
  end if;
end checkGEQOperator;

function checkLEQOperator
  "Takes two inputs a,b returns 1 if a <= b."
  input Real a;
  input Real b;
  output Real c;
algorithm
  if a <= b then
	c := 1;
  else
	c := 0;
  end if;
end checkLEQOperator;

function checkGTOperator
  "Takes two inputs a,b returns 1 if a > b."
  input Real a;
  input Real b;
  output Real c;
algorithm
  if a > b then
	c := 1;
  else
	c := 0;
  end if;
end checkGTOperator;
function checkLTOperator
  "Takes two inputs a,b returns 1 if a < b."
  input Real a;
  input Real b;
  output Real c;
algorithm
  if a < b then
	c := 1;
  else
	c := 0;
  end if;
end checkLTOperator;

function checkEQOperator
  "Takes two inputs a,b returns 1 if a = b."
  input Real a;
  input Real b;
  output Real c;
algorithm
  if a == b then
	c := 1;
  else
	c := 0;
  end if;
end checkEQOperator;

function mReturnsReal
  "Takes the tuple (a,b,c) doubles them "
  input Real a;
  input Real b;
  input Real c;
  output Real a1;
  output Real b1;
  output Real c1;
algorithm
  a1 := a*2;
  b1 := b*2;
  c1 := c*2;
end mReturnsReal;

function summa
  "Testing if recursion works."
  input Real a;
  input Real i;
  output Real b;
algorithm
  if i == 0 then
    b := a;
  else
    b := summa(a+1,i-1);
  end if;
end summa;

function whileSum
  input Real a;
  output Real b;
  protected Real i;
  protected Real summa;
algorithm
  i := 1;
  summa := 0;
  while i <= a loop
    summa := i + summa;
    i := i + 1;
  end while;
  b := summa;
end whileSum;

end RealTests;