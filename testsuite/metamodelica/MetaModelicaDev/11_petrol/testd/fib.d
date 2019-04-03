program fibonacci;

var
    res : integer;

function fib(x : integer) : integer;
begin
    if (x > 2) then
	return fib(x-1) + fib(x-2)
    else
	return 1
    end
end;

begin
    res := fib(5);
end.
