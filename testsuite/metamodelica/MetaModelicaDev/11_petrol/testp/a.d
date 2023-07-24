program test;
var x : integer;
    p : ^integer;
begin
  x := 65;
  write(x);
  p := &x;
  p^ := 66;
  write(x);
  write(10);
end.
