#pragma once
#include <Core/ReduceDAE/IReduceDAESettings.h>

class ReduceDAESettings : public IReduceDAESettings
{

public:
	ReduceDAESettings(IGlobalSettings*	globalSettings);
	//Returns ranking mehtod
	virtual unsigned int getRankingMethod();
	//Sets ranking mehtod
	virtual void setRankingMethod(unsigned int);
	//Returns reduction method
	virtual unsigned int getReductionMethod();
	//Sets reduction method
	virtual void setReductionMethod(unsigned int);
	//Returns Number of restarts afer error bound was reached
	virtual unsigned int getNFail();
	//Sets the number of restarts
	virtual void setNFail(unsigned int);
    //Returns value of error bound to stop reduction
	//Returns the maximum error of each outputvaribale
	virtual ublas::vector<double> getMaxError();
	//Sets the maximum of error of each outputvaribale
	virtual void setMaxError(ublas::vector<double>& error);
    //Retunrs the global settings object
	virtual IGlobalSettings* getGlobalSettings();
	//initializes the settings object by an xml file
    virtual vector<string> getOutputNames();
	void load(std::string xml_file);
private:
	IGlobalSettings*
		_globalSettings;	///< Global simulation settings
	unsigned int
		_ranking_method,				///< ranking mehtod
		_reduction_method,				///< reduction mehtod
		_nfail;							///< number of restarts after error bound was reached
	ublas::vector<double>
		_max_error;						///< max error for all output variables, used in reduction algorithm

    vector<string>  _output_names;

	//Serialization of settings class
	friend class boost::serialization::access;
    template<class archive>
	void serialize(archive& ar, const unsigned int version)

	{

		try
		{
			using boost::serialization::make_nvp;

			ar & make_nvp("NFail", _nfail);
			ar & make_nvp("RakingMethod", _ranking_method);

			ar & make_nvp("ReductionMethod", _reduction_method);

			ar &   make_nvp("MaximumError", _max_error);

		}
		catch(std::exception& ex)
		{
			string error = ex.what();
		}


	}

};

