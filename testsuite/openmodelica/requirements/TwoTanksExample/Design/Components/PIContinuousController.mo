within TwoTanksExample.Design.Components;

model PIContinuousController
extends TwoTanksExample.Design.Components.BaseController ;
  Real x;
  equation
  der(x) = error/T;
  outCtr = K*(error + x);

end PIContinuousController;