%fileName = "eulerTests.Riemann1V_res.mat";
fileName = "conservationLaws.advection_res.mat";
varName = "u[";
load(fileName);
nameT = transpose(name);
indexes = [];
for i = 1:size(name,2)
  if isequal(varName,nameT(i,1:size(varName,2)))
	  indexes = [indexes i];
  end;
end;
nSteps = size(data_2,2)
nPlots = 10;
for i = 1:nPlots
 nFrame = round(1 + (nSteps-1)/(nPlots-1)*(i-1) ) 
 var = data_2(indexes,nFrame);
 plot(var);
 pause(1);
end;
