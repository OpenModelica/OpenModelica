#pragma once

class IContinuous;
class IGlobalSettings;

class BOOST_EXTENSION_XML_READER_DECL XmlPropertyReader : public IPropertyReader
{
  public:
    XmlPropertyReader(shared_ptr<IGlobalSettings> globalSettings, std::string propertyFile);
    XmlPropertyReader(shared_ptr<IGlobalSettings> globalSettings, std::string propertyFile, int dimRHS);
    ~XmlPropertyReader();

    void readInitialValues(IContinuous& system, shared_ptr<ISimVars> sim_vars);

    std::string getPropertyFile();
    void setPropertyFile(std::string file);
    const output_int_vars_t& getIntOutVars();
    const output_real_vars_t& getRealOutVars();
    const output_bool_vars_t& getBoolOutVars();
    const output_der_vars_t& getDerOutVars();
  const output_res_vars_t& getResOutVars();
  private:
    shared_ptr<IGlobalSettings> _globalSettings;
    string _propertyFile;

    output_int_vars_t _intVars;
    output_bool_vars_t _boolVars;
    output_real_vars_t _realVars;
    output_der_vars_t _derVars;
    output_res_vars_t _resVars;
	int _dimRHS;
    bool _isInitialized;
};
