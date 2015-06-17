#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/DataExchange/XmlPropertyReader.h>
#include <boost/property_tree/xml_parser.hpp>
#include <boost/property_tree/ptree.hpp>
#include <fstream>
#include <iostream>

XmlPropertyReader::XmlPropertyReader(std::string propertyFile) : IPropertyReader(), propertyFile(propertyFile)
{
}

XmlPropertyReader::~XmlPropertyReader()
{

}

void XmlPropertyReader::readInitialValues(boost::shared_ptr<ISimVars> sim_vars)
{
  using boost::property_tree::ptree;
  std::ifstream file(propertyFile.c_str());

  if(file)
  {
    double *realVars = sim_vars->getRealVarsVector();
    int *intVars = sim_vars->getIntVarsVector();
    bool *boolVars = sim_vars->getBoolVarsVector();

    ptree tree;
    read_xml(file, tree);

    ptree modelDescription = tree.get_child("ModelDescription");

    BOOST_FOREACH(ptree::value_type const& vars, modelDescription.get_child("ModelVariables"))
    {
      if(vars.first == "ScalarVariable")
      {
        int refIdx = vars.second.get<int>("<xmlattr>.valueReference");
        BOOST_FOREACH(ptree::value_type const& var, vars.second.get_child(""))
        {
          if(var.first == "Real")
          {
            boost::optional<float> v = var.second.get_optional<float>("<xmlattr>.start");
            std::cerr << "Setting real variable for " << vars.second.get<std::string>("<xmlattr>.name") << " with reference " << refIdx << " to " << *v << std::endl;
            if(v)
              realVars[refIdx] = *v;
          }
          else if(var.first == "Int")
          {
            boost::optional<int> v = var.second.get_optional<int>("<xmlattr>.start");
            std::cerr << "Setting int variable for " << vars.second.get<std::string>("<xmlattr>.name") << " with reference " << refIdx << " to " << *v << std::endl;
            if(v)
              intVars[refIdx] = *v;
          }
          else if(var.first == "Boolean")
          {
            boost::optional<bool> v = var.second.get_optional<bool>("<xmlattr>.start");
            std::cerr << "Setting bool variable for " << vars.second.get<std::string>("<xmlattr>.name") << " with reference " << refIdx << " to " << *v << std::endl;
            if(v)
              realVars[refIdx] = *v;
          }
        }
      }
      sim_vars->setRealVarsVector(realVars);
      sim_vars->setIntVarsVector(intVars);
      sim_vars->setBoolVarsVector(boolVars);
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
