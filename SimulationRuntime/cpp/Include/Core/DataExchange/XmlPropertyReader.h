#pragma once

class IContinuous;
class IGlobalSettings;

class BOOST_EXTENSION_XML_READER_DECL XmlPropertyReader : public IPropertyReader
{
  public:
    XmlPropertyReader(IGlobalSettings *globalSettings, std::string propertyFile);
    ~XmlPropertyReader();

    void readInitialValues(IContinuous& system, shared_ptr<ISimVars> sim_vars);

    std::string getPropertyFile();
    void setPropertyFile(std::string file);
    const output_int_vars_t& getIntOutVars();
    const output_real_vars_t& getRealOutVars();
    const output_bool_vars_t& getBoolOutVars();

  private:
    IGlobalSettings *_globalSettings;
    string _propertyFile;

    output_int_vars_t _intVars;
    output_bool_vars_t _boolVars;
    output_real_vars_t _realVars;

    bool _isInitialized;
};
