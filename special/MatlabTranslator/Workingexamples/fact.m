function y = special_fact1(n, m)
% using loops to calculate the numerator
f1 = 1.0;
for i = m+1 : n
    f1 = f1 * i;
end
% using loops to calculate the denominator
f2 = 1.0;
for i = 1 : n-m
    f2 = f2 * i;
end
% assembling the appropriate terms
y = f1/f2;