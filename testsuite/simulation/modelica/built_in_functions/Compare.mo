package Compare
model Modell1
    Real a, b, c;
equation
    a = time;
    b = sin(a);
    c = a^2;
end Modell1;

model Modell2
    Real b, c;
equation
    b = sin(time);
    c = time^2;
end Modell2;

end Compare;