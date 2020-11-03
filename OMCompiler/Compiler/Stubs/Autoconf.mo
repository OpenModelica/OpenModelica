encapsulated package Autoconf

  constant Boolean is64Bit = true;

  constant String bstatic = "";
  constant String bdynamic = "";
  constant String configureCommandLine = "Manually created Makefiles for bootstrapping";
  constant String os = "";
  constant String make = "";
  constant String exeExt = "";
  constant String dllExt = "";
  constant String ldflags_basic = "";

  constant String ldflags_runtime = "";
  constant String ldflags_runtime_sim = "";
  constant String ldflags_runtime_fmu = "";

  constant String platform = "";
  constant String pathDelimiter = "/";
  constant String groupDelimiter = ";";

  constant String corbaLibs = "";
  constant list<String> systemLibs = {};

  constant String triple = "";

annotation(__OpenModelica_Interface="util");
end Autoconf;
