#pragma once




class Reduction
{
public:
	Reduction( shared_ptr<IMixedSystem> system,IReduceDAESettings* settings);
	~Reduction(void);

    std::vector<unsigned int> cancelTerms(label_list_type& labels,ublas::matrix<double>& Ro, shared_ptr<IMixedSystem> _system,IReduceDAESettings* _settings,
                                          SimSettings simsettings, string modelKey,vector<string> output_names,double timeout,ISimController* sim_controller);


	ublas::vector<double> getError(ublas::matrix<double>& R,ublas::matrix<double>& R2,vector<string> output_names);
	bool isLess(ublas::vector<double>& v1,ublas::vector<double>& v2,vector<int> indexes,vector<string> output_names);
private:
	 shared_ptr<IMixedSystem>  _system;
	 IReduceDAESettings* _settings;
};
