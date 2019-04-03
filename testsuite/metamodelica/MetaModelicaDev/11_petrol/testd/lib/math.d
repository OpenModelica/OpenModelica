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


