#pragma once
#include  <DataExchange/ISimVar.h>
using std::string;
class ISimData
{

public:

    virtual ~ISimData()    {};

    virtual void Add(string key,boost::shared_ptr<ISimVar> var) = 0;
    //Returns SimVar for a key
    virtual ISimVar* Get(string key)=0;
    //Adds Results for an output var to simdata object
    virtual void addOutputResults(string name,ublas::vector<double> v) = 0;
    //Returns reference to results for an output var, when simData object is destroyed results are no longer valid
    virtual void getOutputResults(string name,ublas::vector<double>& v) = 0;
    //Clears all output var results
    virtual void clearResults()=0;
    //Return the time intervall
    virtual void getTimeEntries(vector<double>& time_entries) = 0;
    virtual void addTimeEntries(vector<double> time_entries)= 0;
};
