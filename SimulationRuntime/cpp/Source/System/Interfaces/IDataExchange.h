#pragma once

#include <ostream>
using std::ostream;

/*****************************************************************************/
/**

Abstract interface class data exchange. Temporary - To be replaced by 
data exchange entity of open modelica.

\date     September, 1st, 2008
\author   

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class IDataExchange 
{
public:
	virtual ~IDataExchange()	{};

	/// Set stream for output
	virtual void setOutput(ostream* outputStream) = 0;
};
