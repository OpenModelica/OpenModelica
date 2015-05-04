program big;

{ 8q.d }
procedure eightqueens1;

const
    ESC = 27;
    SPACE = 32;		{ ' ' }
    PLUS = 43;		{ '+' }
    HASH = 35;		{ '#' }
    DASH = 45;		{ '-' }
    BAR = 124;		{ '|' }
    J = 72;		    { 'J' }
    Q = 81;		    { 'Q' }
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
end;

{ 8q.d }
procedure eightqueens2;

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
end;

{ cirkel.d }
procedure cirkel1;

  const pi = 3.14159;

  var o : real; 
      r : real;

  procedure init;
    begin
      r := 17.0
    end;

  function omkrets(radie : real) : real;

    function diameter: real;
      begin
	return 2.0 * radie
      end;

  begin
    return diameter() * pi
  end;

begin
  init();
  o := omkrets(r)
end;

{ cirkel.d }
procedure cirkel2;

  const pi = 3.14159;

  var o : real; 
      r : real;

  procedure init;
    begin
      r := 17.0
    end;

  function omkrets(radie : real) : real;

    function diameter: real;
      begin
	return 2.0 * radie
      end;

  begin
    return diameter() * pi
  end;

begin
  init();
  o := omkrets(r)
end;

{ codtest.d }
procedure codtest1;

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
end;

{ codtest.d }
procedure codtest2;

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
end;

{ factorial.d }
procedure factorial1;

var
    n : integer;

{ write_int -- write integer on standard output }
procedure write_int(val : integer);
const
    ASCII0 = 48;       { ascii value of '0' }
    MINUS = 45;
var
    c : integer;
    buf : array[10] of integer; { no integer can occupy more than 10 digits }
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

function fact(n : integer) : integer;
var
    temp : integer;
begin
    if n = 0 then
    	return 1
    else
    	temp := fact(n - 1);
	return n * temp;
    end;
end;

begin
    n := read();
    n := n - 48;
    write_int(fact(n));
    write(10);
end;
    
{ factorial.d }
procedure factorial2;

var
    n : integer;

{ write_int -- write integer on standard output }
procedure write_int(val : integer);
const
    ASCII0 = 48;       { ascii value of '0' }
    MINUS = 45;
var
    c : integer;
    buf : array[10] of integer; { no integer can occupy more than 10 digits }
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

function fact(n : integer) : integer;
var
    temp : integer;
begin
    if n = 0 then
    	return 1
    else
    	temp := fact(n - 1);
	return n * temp;
    end;
end;

begin
    n := read();
    n := n - 48;
    write_int(fact(n));
    write(10);
end;
    
{ fib.d }
procedure fibonacci1;

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
end;

{ fib.d }
procedure fibonacci2;

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
end;

{ params.d }
procedure params1;

var x:real;

function sum(a: real; b:integer; c:integer; d:real):real;
begin
    return a+b+c+d;
end;

begin
   x:=sum(sum(sum(1.0,2,3,4.0),5,6,7.0),8,9,10.0);
   if ((x-55.0)<0.05) then
      write(48) {Write zero}
   else
      write(49) {Write one}
   end
end;

{ params.d }
procedure params2;

var x:real;

function sum(a: real; b:integer; c:integer; d:real):real;
begin
    return a+b+c+d;
end;

begin
   x:=sum(sum(sum(1.0,2,3,4.0),5,6,7.0),8,9,10.0);
   if ((x-55.0)<0.05) then
      write(48) {Write zero}
   else
      write(49) {Write one}
   end
end;

{ parstest1.d }
procedure parstest11;

var
    arr : array[10] of integer;
    i : integer;

function echo(i:integer) : integer;
begin;
    return i;
end;

begin
    i := echo(10289);
    arr[1] := i;
end;

{ parstest1.d }
procedure parstest12;

var
    arr : array[10] of integer;
    i : integer;

function echo(i:integer) : integer;
begin;
    return i;
end;

begin
    i := echo(10289);
    arr[1] := i;
end;

{ qsort.d }
procedure qsort1;

const SIZE = 20;

var s : array[SIZE] of integer;

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

procedure readsequence;
var i : integer;
begin
    i := 0;
    while (i < SIZE) do
	s[i] := read_int();
	i := i + 1;
    end;
end;

procedure writesequence;
const SPACE = 32;
var i : integer;
begin
    i := 0;
    while (i < SIZE) do
	write_int(s[i]);
	write(SPACE);
	i := i + 1;
    end;
end;

procedure quicksort(l : integer; r : integer);
var
    i : integer;
    j : integer;
    t : integer;
    pivot : integer;
begin
    i := l; 
    j := r;
    pivot := s[(l+r) div 2];
    while not(i > j) do
        while (s[i] < pivot) do
	    i := i + 1;
	end;
        while (pivot < s[j]) do
	    j := j - 1;
	end;
        if (i - j < 1) then
            t := s[i];
	    s[i] := s[j];
	    s[j] := t;
	    i := i + 1;
	    j := j - 1;
	end;
    end;
    if (j > l) then
	quicksort(l, j);
    end;
    if (r > i) then
	quicksort(i, r);
    end;
end;

begin
    readsequence();
    quicksort(0, SIZE-1);
    writesequence();
end;

{ qsort.d }
procedure qsort2;

const SIZE = 20;

var s : array[SIZE] of integer;

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

procedure readsequence;
var i : integer;
begin
    i := 0;
    while (i < SIZE) do
	s[i] := read_int();
	i := i + 1;
    end;
end;

procedure writesequence;
const SPACE = 32;
var i : integer;
begin
    i := 0;
    while (i < SIZE) do
	write_int(s[i]);
	write(SPACE);
	i := i + 1;
    end;
end;

procedure quicksort(l : integer; r : integer);
var
    i : integer;
    j : integer;
    t : integer;
    pivot : integer;
begin
    i := l; 
    j := r;
    pivot := s[(l+r) div 2];
    while not(i > j) do
        while (s[i] < pivot) do
	    i := i + 1;
	end;
        while (pivot < s[j]) do
	    j := j - 1;
	end;
        if (i - j < 1) then
            t := s[i];
	    s[i] := s[j];
	    s[j] := t;
	    i := i + 1;
	    j := j - 1;
	end;
    end;
    if (j > l) then
	quicksort(l, j);
    end;
    if (r > i) then
	quicksort(i, r);
    end;
end;

begin
    readsequence();
    quicksort(0, SIZE-1);
    writesequence();
end;

{ quadtest.d }
procedure quadtest1;

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
end;

{ quadtest.d }
procedure quadtest2;

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
end;

{ return.d }
procedure maxtest1;

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
end;

{ return.d }
procedure maxtest2;

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
end;

{ semtest1.d }
procedure semtest11;

{ all the stuff below should work }

var
	a : integer;
	b : integer;
	x : real;
	y : real;
	i_arr : array[10] of integer;

procedure index(i : integer);
var
	j : integer;
begin
	j := 10;
	while (j > 0) do 
		i_arr[1+i-1] := j;
		i_arr[i_arr[i]] := i_arr[i] - j;
		j := j - 1;
	end;
end;

function max(a : integer; x : real) : integer;
begin
	if (a > b) then
		return a
	elsif (b > a) then
		return b
	else
		return a
	end;
end;

procedure nasty(i : integer; j : integer; x : real; y : real);
var
	nasty_1 : integer;
	nasty_2 : array[10] of integer;
	
	procedure do_zero;
	const
		OREZ = 48;
		ZERO = OREZ;
	var
		z : integer;
	begin	
		z := ZERO;
		write(z);
	end;

begin
	i := j;
	x := -i;
	i := i div j;
	x := i/j;
	do_zero();
	if ((x = i) and (i < j)) then
		i := max(i, y);
		j := 0;
		x := 0;
		y := 0;
	end;
end;

begin
	a := 1; b := 2;	x := 1; y := 3.14;
	index(a);
	nasty(1 div 2, 5, 1/2, 8.0+7);
end;

{ semtest1.d }
procedure semtest12;

{ all the stuff below should work }

var
	a : integer;
	b : integer;
	x : real;
	y : real;
	i_arr : array[10] of integer;

procedure index(i : integer);
var
	j : integer;
begin
	j := 10;
	while (j > 0) do 
		i_arr[1+i-1] := j;
		i_arr[i_arr[i]] := i_arr[i] - j;
		j := j - 1;
	end;
end;

function max(a : integer; x : real) : integer;
begin
	if (a > b) then
		return a
	elsif (b > a) then
		return b
	else
		return a
	end;
end;

procedure nasty(i : integer; j : integer; x : real; y : real);
var
	nasty_1 : integer;
	nasty_2 : array[10] of integer;
	
	procedure do_zero;
	const
		OREZ = 48;
		ZERO = OREZ;
	var
		z : integer;
	begin	
		z := ZERO;
		write(z);
	end;

begin
	i := j;
	x := -i;
	i := i div j;
	x := i/j;
	do_zero();
	if ((x = i) and (i < j)) then
		i := max(i, y);
		j := 0;
		x := 0;
		y := 0;
	end;
end;

begin
	a := 1; b := 2;	x := 1; y := 3.14;
	index(a);
	nasty(1 div 2, 5, 1/2, 8.0+7);
end;

{ sieve.d }
procedure prime1;

const
    SIZE = 8191;
    FALSE = 0;
    TRUE = 1;
    
var
    flags : array[SIZE] of integer;
    i : integer;
    prime : integer;
    k : integer;
    count : integer;
    iter : integer;

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
    
begin
    iter := 0;
    while (iter < 10) do 
    	count := 0;
	i := 0;
	while (i < SIZE) do
	    flags[i] := TRUE;
	    i := i + 1;
	end;
	i := 0;
	while (i < SIZE) do
	    if (flags[i]) then
	    	prime := i + i + 3;
		write_int(prime);
		newline();
		k := i + prime;
		while (k < SIZE) do
		    flags[k] := FALSE;
		    k := k + prime;
		end;
		count := count + 1;
	    end;
	    i := i + 1;
	end;
    	iter := iter + 1;
    end;
end;

{ sieve.d }
procedure prime2;

const
    SIZE = 8191;
    FALSE = 0;
    TRUE = 1;
    
var
    flags : array[SIZE] of integer;
    i : integer;
    prime : integer;
    k : integer;
    count : integer;
    iter : integer;

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
    
begin
    iter := 0;
    while (iter < 10) do 
    	count := 0;
	i := 0;
	while (i < SIZE) do
	    flags[i] := TRUE;
	    i := i + 1;
	end;
	i := 0;
	while (i < SIZE) do
	    if (flags[i]) then
	    	prime := i + i + 3;
		write_int(prime);
		newline();
		k := i + prime;
		while (k < SIZE) do
		    flags[k] := FALSE;
		    k := k + prime;
		end;
		count := count + 1;
	    end;
	    i := i + 1;
	end;
    	iter := iter + 1;
    end;
end;

{ stone.d }
procedure stone1;

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

procedure down(n : integer);
begin
    if n = 0 then
	return
    else
	down(n-1);
	write_int(n);
	newline();
    end;
end;

begin
    down(10);
end;

{ stone.d }
procedure stone2;

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

procedure down(n : integer);
begin
    if n = 0 then
	return
    else
	down(n-1);
	write_int(n);
	newline();
    end;
end;

begin
    down(10);
end;

{ testmath.d }
procedure test21;

var
    x : real;

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
function abs(x : real) : real;
begin
    if (x < 0) then
	return -x;
    else
	return x;
    end;
end;

function sqrt(x : real) : real;
const
    EPSILON = 1e-4;	{ Seems to work better than 1e-5... }
var
    xn : real;
begin
    xn := x/2;
    while (abs(xn*xn - x) > EPSILON) do
	xn := (xn + x/xn) / 2;
    end;
    return xn;
end;

begin
    x := read_real();
    write_real(sqrt(x));
    newline();
end;

{ testmath.d }
procedure test22;

var
    x : real;

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
function abs(x : real) : real;
begin
    if (x < 0) then
	return -x;
    else
	return x;
    end;
end;

function sqrt(x : real) : real;
const
    EPSILON = 1e-4;	{ Seems to work better than 1e-5... }
var
    xn : real;
begin
    xn := x/2;
    while (abs(xn*xn - x) > EPSILON) do
	xn := (xn + x/xn) / 2;
    end;
    return xn;
end;

begin
    x := read_real();
    write_real(sqrt(x));
    newline();
end;

{ dummy main }
begin
 eightqueens2();
end.
