

function Factorial
  input Integer n;
  output Integer z;
algorithm
  if n == 0 then
    z := 1;
  else
    z := n * Factorial(n - 1);
  end if;
end Factorial;


