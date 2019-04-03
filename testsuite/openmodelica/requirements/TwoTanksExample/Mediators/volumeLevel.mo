within TwoTanksExample.Mediators;

record volumeLevel
  extends  Mediator(mType = "Real",
  clients = {Client(modelID = "TwoTanksExample.Requirements.Volume_of_a_tank", component = "tankVolume")},
  providers = {Provider(modelID = "TwoTanksExample.Design.Components.Tank",
    template = "%getPath.volume")});
end volumeLevel;
