#pragma once



/*****************************************************************************/
/**

Abstract interface class for dae system with labels for each term in equation

\date     June, 1st, 2011
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
//typedef tuple<double*,unsigned int> label_type;
//typedef vector<label_type > label_list_type;

typedef tuple<unsigned int,double*,double*> label_type;
typedef vector<label_type > label_list_type;

class IHistory;
class IReduceDAE
{
public:
    virtual label_list_type getLabels()=0 ;
	virtual void setVariables(const ublas::vector<double>& variables,const ublas::vector<double>& variables2)=0;
	virtual IHistory* getHistory()=0;
	//virtual void giveResidues(double* f)=0;


	virtual ~IReduceDAE()	{};
	//virtual void updateAll() = 0;

};