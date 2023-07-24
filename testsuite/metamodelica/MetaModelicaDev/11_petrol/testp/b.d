program test;
type
	cons_t =
		record
			car : integer;
			cdr : ^cons_t;
		end;
var
	list : ^cons_t;

function malloc(nbytes : integer) : ^cons_t; extern;

function cons(car : integer; cdr : ^cons_t) : ^cons_t;
var	p : ^cons_t;
begin
	p := malloc(8);
	p^.car := car;
	p^.cdr := cdr;
	return p;
end;

function car(p : ^cons_t) : integer;
begin
	return p^.car;
end;

function cdr(p : ^cons_t) : ^cons_t;
begin
	return p^.cdr;
end;

begin
	list := cons(65, cons(10, nil));
	write(car(list));
	write(car(cdr(list)));
end.
