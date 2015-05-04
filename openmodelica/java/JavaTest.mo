package JavaTest

function GetJavaSystemProperty
  input String prop;
  output String out;
  external "Java" out='java.lang.System.getProperty'(prop) annotation(JavaMapping="simple");
end GetJavaSystemProperty;

function JavaIntString
  input Integer val;
  output String out;
  external "Java" out='java.lang.String.valueOf'(val) annotation(JavaMapping="simple");
end JavaIntString;

function JavaRealString
  input Real val;
  output String out;
  external "Java" out='java.lang.String.valueOf'(val) annotation(JavaMapping="simple");
end JavaRealString;

function JavaBoolString
  input Boolean val;
  output String out;
  external "Java" out='java.lang.String.valueOf'(val) annotation(JavaMapping="simple");
end JavaBoolString;

function JavaStringInt
  input String str;
  output Integer val;
  external "Java" val='java.lang.Integer.parseInt'(str) annotation(JavaMapping="simple");
end JavaStringInt;

function JavaStringReal
  input String str;
  output Real val;
  external "Java" val='java.lang.Double.parseDouble'(str) annotation(JavaMapping="simple");
end JavaStringReal;

function JavaStringBool
  input String str;
  output Boolean val;
  external "Java" val='java.lang.Boolean.parseBoolean'(str) annotation(JavaMapping="simple");
end JavaStringBool;

end JavaTest;
