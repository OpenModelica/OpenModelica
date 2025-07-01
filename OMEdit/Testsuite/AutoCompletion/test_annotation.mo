model test_annotation
  parameter Real Hello = 5 annotation(Dialog(tab = "General"));
  // from here completion only proposes Dialog options.
  parameter Real Hola = 3;
  parameter Real Bonjour = 2 annotation(Evaluate= true);
  // here completion returns to normal
  parameter Real Hej = 1 annotation(Dialog(tab = "General"));

  // annotation
  // here completion works as intended, annotation keyword seems to reset completion event if written in comment

  type KindOfController=Integer(min=1,max=3)
    annotation(choices(
                choice=1 "P",
                choice=2 "PI",
                choice=3 "PID"));
  // completion does not work here...

  parameter Boolean isActive = true annotation(choices(checkBox = true));
  // ... but works there
end test_annotation;
