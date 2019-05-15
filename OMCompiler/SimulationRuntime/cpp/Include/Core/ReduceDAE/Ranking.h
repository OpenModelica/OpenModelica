#pragma once
//#include "../../System/Interfaces/IDAESystem.h"

class Ranking
{
public:
	Ranking(shared_ptr<IMixedSystem> system,IReduceDAESettings* settings);
	~Ranking(void);
	virtual label_list_type DoRanking(ublas::matrix<double>& R,ublas::matrix<double>& dR,ublas::matrix<double>& Re,vector<double>& time_values);
	label_list_type residuenRanking(ublas::matrix<double>& R,ublas::matrix<double>& dR,ublas::matrix<double>& Re,vector<double>& time_values);
    label_list_type   perfectRanking(ublas::matrix<double>& Ro,shared_ptr<IMixedSystem> _system,IReduceDAESettings* _settings,SimSettings simsettings,
                                              string modelKey,vector<string> output_names, double timeout,ISimController* sim_controller);
private:
	//methods:
	IReduceDAESettings* _settings;
    shared_ptr<IMixedSystem>  _system;
	double	*_zeroVal;
	double	*_zeroValOld;



};
/*
Helper class to select the index of the label tuple  and return it
*/
class Li
{
public:
  typedef  std::tuple_element<0,label_type>::type result_type;
  result_type operator()(const label_type& u) const
  {
      return get<0>(u);
  }
};

