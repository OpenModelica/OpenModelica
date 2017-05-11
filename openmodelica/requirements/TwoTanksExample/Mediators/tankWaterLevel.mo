within TwoTanksExample.Mediators;

record tankWaterLevel
extends  Mediator(mType = "Real",
  clients = {Client(modelID = "TwoTanksExample.Requirements.LiquidLevel", component = "waterLevel")},
  providers = {Provider(modelID = "TwoTanksExample.Design.Components.Tank",
    template = "%getPath.levelOfLiquid")});
end tankWaterLevel;