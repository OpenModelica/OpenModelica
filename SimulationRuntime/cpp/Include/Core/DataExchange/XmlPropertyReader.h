#pragma once

#include <Core/DataExchange/IPropertyReader.h>
#include <string>

class XmlPropertyReader : public IPropertyReader
{
  public:
    XmlPropertyReader(std::string propertyFile);
    ~XmlPropertyReader();

    void readInitialValues(boost::shared_ptr<ISimVars> sim_vars);

    std::string getPropertyFile();
    void setPropertyFile(std::string file);

  private:
    std::string propertyFile;
};
