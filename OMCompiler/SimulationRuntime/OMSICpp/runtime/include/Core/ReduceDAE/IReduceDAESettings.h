#pragma once

class IGlobalSettings;
class IReduceDAESettings
{

public:
	/// Enum to choose the integration method
	enum RANKINGMETHOD
	{
        NORANKING=0,
		PERFECT		= 1,
        RESIDUEN = 2
	};

	/// Enum to choose the method for zero search
	enum REDUCTIONMETHOD
	{
		CANCEL_TERMS			= 0,	///<
		LINEARIZE_TERMS			= 1,	///<
		SUBSTITUTE_TERMS        = 2, ///<
		BUILD_LABELS            = 3

	};
	virtual unsigned int getRankingMethod()=0;
	virtual void setRankingMethod(unsigned int)=0;
	virtual unsigned int getReductionMethod()=0;
	virtual void setReductionMethod(unsigned int)=0;
	virtual unsigned int getNFail()=0;
	virtual void setNFail(unsigned int)=0;
	virtual ublas::vector<double> getMaxError()=0;
	virtual void setMaxError(ublas::vector<double>& error)=0;
	virtual IGlobalSettings* getGlobalSettings()=0;
    virtual vector<string> getOutputNames()=0;
};
