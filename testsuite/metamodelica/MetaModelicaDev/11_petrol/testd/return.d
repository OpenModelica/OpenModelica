program maxtest;

{ ******************************* }
{ *                             * }
{ *   Standard I/O primitives   * }
{ *                             * }
{ ******************************* }

procedure newline;
const
    NEWLINE = 10;
begin
    write(NEWLINE);
end;

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
    
procedure write_real(val : real);
const
    DOT = 46;
var
    i : integer;
begin
    i := trunc(val);
    write_int(i);
    val := (val - i) * 1e6;  { can only warrant 7 digits }
    i := trunc(val);
    write(DOT);
    write_int(i);
end;

function read_int : integer;
const
    BLANK = 32;
    ASCII0 = 48;
    ASCII9 = 57;
var
    acc : integer;
    c : integer;
begin
    acc := 0;
    c := read();
    while (c < ASCII0) or (c > ASCII9) do
    	c := read();
    end;
    while not ((c < ASCII0) or (c > ASCII9)) do
    	acc := 10 * acc + c - ASCII0;
	c := read();
    end;
    return acc;
end;

function read_real : real;
const
    BLANK = 32;
    ASCII0 = 48;
    ASCII9 = 57;
    DOT = 46;
var
    res : real;
    acc : integer;
    c : integer;
begin
    acc := 0;
    c := read();
    while (c < ASCII0) or (c > ASCII9) do
    	c := read();
    end;
    while not ((c < ASCII0) or (c > ASCII9)) do
    	acc := 10 * acc + c - ASCII0;
	c := read();
    end;
    res := acc;
    if (c <> DOT) then
	return res;
    end;
    acc := 1;
    c := read();
    while not ((c < ASCII0) or (c > ASCII9)) do
    	acc := 10 * acc;
	c := c - ASCII0;
	res := res + c/acc;
	c := read();
    end;
    return res;
end;

function max(a : integer; b : integer) : integer;
begin
    if a > b then
	return a
    else
	return b
    end
end;

begin
    write_int(max(3, 7));
end.
