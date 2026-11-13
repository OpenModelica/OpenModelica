block Microcontroller
  annotation(
    defaultComponentName = "mcu",
    missingInnerMessage = "Missing inner block for AVR microcontroller (this
cannot have default values since the microcontrollers are all
different).");
  annotation(
    Icon(graphics = {Text(origin = {32, -3}, lineColor = {255, 255, 255}, extent = {{-44, 19}, {-20, -13}}, textString = "AVR", fontSize = 70, fontName = "Arial", textStyle = {TextStyle.Bold})}, coordinateSystem(initialScale = 0.1)));
end Microcontroller;