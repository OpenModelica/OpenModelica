function time = getTimeMat(n,nameT,data_2)
  varName = "time";
  i = 1;
while not (isequal(varName,nameT(i,1:size(varName,2))))
  i = i + 1
end;
time = data_2(i,n);
