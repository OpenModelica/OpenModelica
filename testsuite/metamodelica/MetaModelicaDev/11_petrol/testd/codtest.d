program test;

procedure write_int(val : integer);
const
    ASCII0 = 48;                { ascii value of '0' }
    MINUS = 45;
var
    c : integer;
    buf : array[10] of integer; { enough for 10 digits }
    bufp : integer;
begin
    if (val = 0) then
	write(ASCII0);
	return;
    end;
    if (val < 0) then
	write(MINUS);
        val := -val;
    end;
    bufp := 0;
    while val > 0 do
    	c := val mod 10;
	buf[bufp] := c + ASCII0;
	bufp := bufp + 1;
	val := val div 10;
    end;
    while (bufp > 0) do 
	bufp := bufp - 1;
    	write(buf[bufp]);
    end;
end;

begin
	write_int(23);
end.
