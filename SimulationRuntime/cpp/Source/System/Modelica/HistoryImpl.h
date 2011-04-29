#pragma once
#include "SettingsFactory/Interfaces/IGlobalSettings.h"
#include "DataExchange/Interfaces/IHistory.h"




template< template <unsigned long,unsigned long>  class ResultsPolicy,unsigned long dim_1,unsigned long dim_2>
class HistoryImpl: public IHistory,
	public ResultsPolicy<dim_1,dim_2>
{ 
public: 

	HistoryImpl(IGlobalSettings& globalSettings)
	:ResultsPolicy<dim_1,dim_2>((globalSettings.getEndTime()-globalSettings.getStartTime())/globalSettings.gethOutput(),globalSettings.getOutputPath())
	{

	}

	void setOutputs(vector<unsigned int> var_outputs)
	{
		_var_outputs=var_outputs;
	
	}


	void getSimResults(const double time,ublas::vector<double>& v,ublas::vector<double>& dv)
	{
		ResultsPolicy<dim_1,dim_2>::read(time,v,dv);

	}


	void getSimResults(ublas::matrix<double>& R,ublas::matrix<double>& dR)
	{

		ResultsPolicy<dim_1,dim_2>::read(R,dR);

	}
	virtual void getOutputResults(ublas::matrix<double>& Ro)
	{
		ResultsPolicy<dim_1,dim_2>::read(Ro,_var_outputs);
	}

	unsigned long getSize()
	{
		return  ResultsPolicy<dim_1,dim_2>::size();
	}


	unsigned long getDimdR()
	{
		return  dim_2;
	}



	unsigned long getDimR()
	{
		return  dim_1;
	}


	vector<double> getTimeEntries()
	{
		vector<double> time;
		ResultsPolicy<dim_1,dim_2>::getTime(time);
		return time;
	}

    void clear()
	{
       ResultsPolicy<dim_1,dim_2>::eraseAll();
	};
private:
	//List of indices of all output variables 
	vector<unsigned int> _var_outputs;

};