// name: InnerOuter9
// keywords: 
// status: correct
// cflags: -d=newInst
//

model PrescribedPump  
  extends PartialPump;
end PrescribedPump;

partial model PartialPump  
  PartialHeatTransfer heatTransfer;
end PartialPump;

partial model PartialHeatTransfer  
  parameter Real T_ambient = system.T_ambient;
  outer System system;
end PartialHeatTransfer;

model System  
  parameter Real T_ambient = 293.15;
end System;

model InnerOuter9  
  PrescribedPump pumps;
  inner System system;
end InnerOuter9;


// Result:
// class InnerOuter9
//   parameter Real pumps.heatTransfer.T_ambient = system.T_ambient;
//   parameter Real system.T_ambient = 293.15;
// end InnerOuter9;
// endResult
