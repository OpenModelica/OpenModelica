%fileName = "eulerTests.Riemann1_res.mat";
%fileName = "conservationLaws.Riemann1_res.mat";
fileName = "conservationLaws.advection_res.mat";
varName = "u";
[nameT, data_2, N] = openMat(fileName);
nPlots = 10;
for i = 1:nPlots
 nFrame = round(1 + (N-1)/(nPlots-1)*(i-1) ) ;
 getTimeMat(nFrame, nameT, data_2) 
 plot(getVarMat(varName, nFrame, nameT, data_2));
 pause(0.2);
end;
