#pragma once




class IContinuous;

class BOOST_EXTENSION_XML_READER_DECL XmlPropertyReader : public IPropertyReader
{
  public:
    XmlPropertyReader(std::string propertyFile);
    ~XmlPropertyReader();

    void readInitialValues(IContinuous& system, shared_ptr<ISimVars> sim_vars);

    std::string getPropertyFile();
    void setPropertyFile(std::string file);

  private:
    std::string propertyFile;
};
