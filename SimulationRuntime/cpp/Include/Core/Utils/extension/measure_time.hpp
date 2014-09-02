#ifndef MEASURE_TIME_HPP
#define MEASURE_TIME_HPP

#if defined(_MSC_VER)
#include <intrin.h>
#endif

#include <fstream>
#include <string>
#include <sstream>
#include <vector>
#include <ctime>
#include <iostream>
#include <Core/Modelica.h>


class RDTSC_MeasureTime;

class BOOST_EXTENSION_EXPORT_DECL MeasureTime
{
public:
  MeasureTime() {}
	virtual ~MeasureTime() {}

	struct data
	{
		unsigned long long sum_time;
		unsigned num_calcs;
		unsigned long long max_time;
	};

	static MeasureTime* getInstance();

	static unsigned long long getTime();

	static void deinitialize();

	void writeTimeToJason(std::string model_name, std::vector<data> times);

public:
	virtual unsigned long long getTimeP() = 0;
protected:
	static RDTSC_MeasureTime *instance;
};

class BOOST_EXTENSION_EXPORT_DECL RDTSC_MeasureTime : public MeasureTime
{
public:
	RDTSC_MeasureTime() : MeasureTime() {};

	virtual unsigned long long getTimeP();

public:
	virtual ~RDTSC_MeasureTime() {}

	static void initialize();

private:
	static unsigned long long RDTSC();

};

//class PAPI_MeasureTime : public MeasureTime
//{
//
//};
#endif // MEASURE_TIME_HPP
