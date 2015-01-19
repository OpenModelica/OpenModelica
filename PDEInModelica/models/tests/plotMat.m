fileName = "eulerTests.Riemann1V_res.mat";
varName = "riemann1.rho[";
load(fileName);
nameT = transpose(name);
indexes = [];
for i = 1:size(name,2)
  if isequal(varName,nameT(i,1:size(varName,2)))
	  indexes = [indexes i];
  end;
end;
%indexes
nSteps = size(data_2,2);
%var = data_2(indexes,40);
var = data_2(indexes,nSteps);
plot(var)
