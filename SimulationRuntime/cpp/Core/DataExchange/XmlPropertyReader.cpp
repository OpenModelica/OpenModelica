#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/DataExchange/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>
#include <Core/DataExchange/XmlPropertyReader.h>
#include <fstream>
#include <iostream>

XmlPropertyReader::XmlPropertyReader(std::string propertyFile) : IPropertyReader(), propertyFile(propertyFile)
{
}

XmlPropertyReader::~XmlPropertyReader()
{

}

void XmlPropertyReader::readInitialValues(IContinuous& system, shared_ptr<ISimVars> sim_vars)
{
  using boost::property_tree::ptree;
  std::ifstream file;
  file.open (propertyFile.c_str(), std::ifstream::in);
  if(file.good())
  {
    double *realVars = sim_vars->getRealVarsVector();
    int *intVars = sim_vars->getIntVarsVector();
    bool *boolVars = sim_vars->getBoolVarsVector();
    string *stringVars = sim_vars->getStringVarsVector();
    int refIdx = -1;
    boost::optional<int> refIdxOpt;
    try
    {
      ptree tree;
      read_xml(file, tree);

      ptree modelDescription = tree.get_child("ModelDescription");

      BOOST_FOREACH(ptree::value_type const& vars, modelDescription.get_child("ModelVariables"))
      {
        if(vars.first == "ScalarVariable")
        {
          refIdxOpt = vars.second.get_optional<int>("<xmlattr>.valueReference");
          if(!refIdxOpt)
          {
            //boost::property_tree::xml_parser::write_xml(std::cout, vars.second);
            continue;
          }

          refIdx = *refIdxOpt;
          std::string aliasInfo = vars.second.get<std::string>("<xmlattr>.alias");

          //If a start value is given for the alias and the referred variable, skip the alias declaration
          if(aliasInfo.compare("noAlias") != 0)
            continue;

          BOOST_FOREACH(ptree::value_type const& var, vars.second.get_child(""))
          {
            if(var.first == "Real")
            {
              boost::optional<double> v = var.second.get_optional<double>("<xmlattr>.start");
              double value = (v? (*v):0.0);
              LOGGER_WRITE("XMLPropertyReader: Setting real variable for " + boost::lexical_cast<std::string>(vars.second.get<std::string>("<xmlattr>.name")) + " with reference " + boost::lexical_cast<std::string>(refIdx) + " to " + boost::lexical_cast<std::string>(value) ,LC_INIT,LL_DEBUG);
              system.setRealStartValue(realVars[refIdx],value);
            }
            else if(var.first == "Integer")
            {
              boost::optional<int> v = var.second.get_optional<int>("<xmlattr>.start");
              int value = (v? (*v):0);
              LOGGER_WRITE("XMLPropertyReader: Setting int variable for " + boost::lexical_cast<std::string>(vars.second.get<std::string>("<xmlattr>.name")) + " with reference " + boost::lexical_cast<std::string>(refIdx) + " to " + boost::lexical_cast<std::string>(value) ,LC_INIT,LL_DEBUG);
              system.setIntStartValue(intVars[refIdx],value);
            }
            else if(var.first == "Boolean")
            {
              boost::optional<bool> v = var.second.get_optional<bool>("<xmlattr>.start");
              bool value = (v? (*v):false);
              LOGGER_WRITE("XMLPropertyReader: Setting bool variable for " + boost::lexical_cast<std::string>(vars.second.get<std::string>("<xmlattr>.name")) + " with reference " + boost::lexical_cast<std::string>(refIdx) + " to " + boost::lexical_cast<std::string>(value) ,LC_INIT,LL_DEBUG);
              system.setBoolStartValue(boolVars[refIdx],value);
            }
            else if(var.first == "String")
            {
              boost::optional<string> v = var.second.get_optional<string>("<xmlattr>.start");
              string value = (v? (*v):"");
              LOGGER_WRITE("XMLPropertyReader: Setting string variable for " + boost::lexical_cast<std::string>(vars.second.get<std::string>("<xmlattr>.name")) + " with reference " + boost::lexical_cast<std::string>(refIdx) + " to " + boost::lexical_cast<std::string>(value) ,LC_INIT,LL_DEBUG);
              system.setStringStartValue(stringVars[refIdx],value);
            }
          }
        }
      }
    }
    catch(exception &ex)
    {
      std::stringstream sstream;
      sstream << "Could not read start values. Current variable reference is " << refIdx;
      throw ModelicaSimulationError(UTILITY,sstream.str());
    }

    file.close();
  }
}

std::string XmlPropertyReader::getPropertyFile()
{
  return propertyFile;
}

void XmlPropertyReader::setPropertyFile(std::string file)
{
  propertyFile = file;
}
