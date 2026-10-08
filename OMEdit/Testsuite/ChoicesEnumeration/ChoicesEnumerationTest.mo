within ;
package EnumWithChoices

  model ClassWithInstance
    ClassWithEnum classWithEnum annotation(
      Placement(transformation(origin = {-10, 10}, extent = {{-10, -10}, {10, 10}})));
  equation

  end ClassWithInstance;

  model ClassWithEnum
    parameter EnumWithChoices.SomeType enumParam = EnumWithChoices.SomeType.Choice1;

    parameter EnumWithChoices.SomeType enumParamWithChoices = EnumWithChoices.SomeType.Choice1
      annotation (
        choices(
          choice = EnumWithChoices.SomeType.Choice1 "First choice",
          choice = EnumWithChoices.SomeType.Choice2 "Second choice"));
  end ClassWithEnum;

  type SomeType = enumeration(Choice1 "First choice", Choice2 "Second choice", Choice3 "Third choice") "Type with enum";
end EnumWithChoices;
