model EquationCallIntegerArray

function arrcalli
input Real r;
output Integer[3] rs;
algorithm
rs := {1,integer(20*r),integer(30*r)};
end arrcalli;

Integer[3] i;
Boolean b;
equation

i = arrcalli(time);

when sample(0, 0.05) then
b = not pre(b);
end when;

end EquationCallIntegerArray;
