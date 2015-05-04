program quadtest;

const
	SIZE = 10;

var
	a : array[SIZE] of integer;
	i : integer;
	x : real;

function foo(i : integer; x : real) : integer;
begin
	{ test if-then-else }
	if i < x then
		i := i + 1;
		x := x - 1;
	elsif not(i <> x) then
		{ do nothing }
	else
		if i <> 0 then
			i := -i;
		else
			i := 7;
		end;
		x := x + 1;
		write(33);
	end;
	return i;
end;

begin
	{ test array index }
	a[1] := 2;
	a[a[1]-1] := a[1];
	{ test coercion }
	x := 3;
	i := trunc(x);
	x := 4 + 4/2;
	{ test parameters }
	i := foo(i, x);
end.
