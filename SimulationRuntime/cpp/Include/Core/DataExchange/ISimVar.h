#pragma once

/*
Interface for all sim variables
*/
class ISimVar
{

public:
	virtual ~ISimVar()	{};
	virtual void setName(string name) =0;
	virtual string getName() = 0;

};