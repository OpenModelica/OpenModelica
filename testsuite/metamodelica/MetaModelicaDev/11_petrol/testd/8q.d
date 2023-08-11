program eightqueens;

const
    ESC = 27;
    SPACE = 32;		{ ' ' }
    PLUS = 43;		{ '+' }
    HASH = 35;		{ '#' }
    DASH = 45;		{ '-' }
    BAR = 124;		{ '|' }
    J = 72;		{ 'J' }
    Q = 81;		{ 'Q' }
    LBRACK = 91;	{ '[' }
    NEWLINE = 10;	{ '\n' }

var
    up : array[{0..15}16] of integer;	{ up - facing diagonals }
    down : array[{0..15}16] of integer;	{ down - facing diagonals }
    rows : array[{0..7}8] of integer;	{ rows }
    x : array[{0..7}8] of integer;	{ holds solution }
    
procedure init;
var
    i : integer;
begin
    i := 0;
    while (i < 16) do
    	up[i] := 1;
	down[i] := 1;
	i := i + 1;
    end;
    i := 0;
    while (i < 8) do
    	rows[i] := 1;
	i := i + 1;
    end;
end;

procedure print;
var
    c : integer;
    r : integer;

    procedure dodash;
    var
    	i : integer;
    begin
    	write(NEWLINE);
    	i := 0;
	while (i < 8) do
	    write(PLUS);
	    write(DASH);
	    i := i + 1;
	end;
	write(PLUS);
	write(NEWLINE);
    end;
	
begin
    write(ESC); write(LBRACK); write(J);	{ home }
    r := 0;
    while (r < 8) do
	dodash();
	c := 0;
	while (c < 8) do
	    write(BAR);
	    if (x[c] = r) then
		write(Q)
	    else
		write(SPACE)
	    end;
	    c := c + 1;
	end;
	write(BAR);
	r := r + 1;
    end;
    dodash();
    write(NEWLINE);
end;

procedure queens(c : integer);
var
    r : integer;
begin
    r := 0;
    while (r < 8) do
	if rows[r] and up[r-c+8] and down[r+c] then
	    rows[r] := 0;
	    up[r-c+8] := 0;
	    down[r+c] := 0;
	    x[c] := r;			{ record solution so far }
	    if (c = 7) then
		print()			{ print the solution }
	    else
		queens(c+1);
	    end;
	    rows[r] := 1;
	    up[r-c+8] := 1;
	    down[r+c] := 1;
	end;
	r := r + 1;
    end;
end;
    
begin
    init();
    queens(0);				{ place 1st and subsequent queens }
end.
