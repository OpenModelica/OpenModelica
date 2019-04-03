within TwoTanksExample.Mediators;

record sourceFlowLevel
  extends  Mediator(mType = "Real",
  clients = {Client(modelID = "TwoTanksExample.Design.Components.Source", component = "flowLevel")},
  providers = {Provider(modelID = "TwoTanksExample.Scenarios.Normal_operation",
    template = "%getPath.flowLevel"),
    Provider(modelID = "TwoTanksExample.Scenarios.Overflow",
    template = "%getPath.flowLevel")});
end sourceFlowLevel;