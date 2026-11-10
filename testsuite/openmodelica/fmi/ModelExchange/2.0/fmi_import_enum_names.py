"""Write FMUs that hold only a modelDescription.xml, for importFMU.

usage: fmi_import_enum_names.py

ImportEnum2.fmu (FMI 2.0) and ImportEnum3.fmu (FMI 3.0) are Model Exchange
FMUs with an enumeration type. FMI allows any string as an item name, so
some names are not valid Modelica identifiers: a space, a minus sign, a
keyword, a quote and a backslash. One name is already a quoted identifier
and one is a valid identifier. The FMI 2.0 parameter p uses the mapping
function from Integer to the enumeration. importFMU reads only the
modelDescription.xml, so no binary is necessary.
"""
import zipfile

ITEMS = ["Option 1", "x-y", "der", "a'b", r"a\b", "'q r'", "Valid_7"]

ITEMS_XML = "\n".join(
    '        <Item name="%s" value="%d"/>' % (name, i + 1) for i, name in enumerate(ITEMS))

MD2 = """<?xml version="1.0" encoding="UTF-8"?>
<fmiModelDescription fmiVersion="2.0" modelName="ImportEnum2"
  guid="{5d1f2a7c-3b9e-4c0d-8e6f-1a2b3c4d5e20}" numberOfEventIndicators="0">
  <ModelExchange modelIdentifier="ImportEnum2"/>
  <TypeDefinitions>
    <SimpleType name="Option">
      <Enumeration>
%s
      </Enumeration>
    </SimpleType>
  </TypeDefinitions>
  <DefaultExperiment startTime="0" stopTime="1" tolerance="1e-6"/>
  <ModelVariables>
    <ScalarVariable name="p" valueReference="0" causality="parameter" variability="fixed" initial="exact"><Enumeration declaredType="Option" start="4"/></ScalarVariable>
    <ScalarVariable name="y" valueReference="1" causality="output" variability="continuous" initial="calculated"><Real/></ScalarVariable>
  </ModelVariables>
  <ModelStructure>
    <Outputs>
      <Unknown index="2" dependencies=""/>
    </Outputs>
    <InitialUnknowns>
      <Unknown index="2" dependencies=""/>
    </InitialUnknowns>
  </ModelStructure>
</fmiModelDescription>
""" % ITEMS_XML

MD3 = """<?xml version="1.0" encoding="UTF-8"?>
<fmiModelDescription fmiVersion="3.0" modelName="ImportEnum3"
  instantiationToken="{5d1f2a7c-3b9e-4c0d-8e6f-1a2b3c4d5e30}">
  <ModelExchange modelIdentifier="ImportEnum3"/>
  <TypeDefinitions>
    <EnumerationType name="Option">
%s
    </EnumerationType>
  </TypeDefinitions>
  <DefaultExperiment startTime="0" stopTime="1" tolerance="1e-6"/>
  <ModelVariables>
    <Enumeration name="u" valueReference="1" declaredType="Option" causality="input" variability="discrete" start="4"/>
    <Float64 name="y" valueReference="2" causality="output"/>
  </ModelVariables>
  <ModelStructure>
    <Output valueReference="2"/>
    <InitialUnknown valueReference="2"/>
  </ModelStructure>
</fmiModelDescription>
""" % ITEMS_XML


def write(name, md):
    with zipfile.ZipFile(name + ".fmu", "w") as z:
        z.writestr("modelDescription.xml", md)


if __name__ == "__main__":
    write("ImportEnum2", MD2)
    write("ImportEnum3", MD3)
