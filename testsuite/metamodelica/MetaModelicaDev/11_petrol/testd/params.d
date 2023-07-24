program params;

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
end.

