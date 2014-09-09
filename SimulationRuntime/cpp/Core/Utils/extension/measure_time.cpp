#include <Core/Utils/extension/measure_time.hpp>

MeasureTime * MeasureTime::instance = 0;

MeasureTimeValues::MeasureTimeValues() {}

MeasureTimeValues::~MeasureTimeValues() {}

MeasureTimeData::MeasureTimeData() : id(0), sumMeasuredValues(MeasureTime::getZeroValues()), numCalcs(0), category("") {}

MeasureTimeData::~MeasureTimeData()
{
  //if(sumMeasuredValues != NULL)
    //delete sumMeasuredValues;
}

MeasureTime::MeasureTime() : overhead(NULL) {}

MeasureTime::~MeasureTime()
{
  if(overhead != NULL)
    delete overhead;
}

MeasureTime* MeasureTime::getInstance()
{
  return instance;
}

void MeasureTime::deinitialize()
{
  if (instance != 0)
    delete instance;
}

MeasureTimeValues* MeasureTime::getZeroValues()
{
  if (instance == 0)
    return 0;

  return instance->getZeroValuesP();
}

MeasureTimeValues* MeasureTime::getOverhead()
{
  if (instance == 0)
    return 0;

  return instance->overhead;
}

void MeasureTime::benchOverhead()
{
  if(overhead != NULL)
    delete overhead;

  overhead = getZeroValues();

  MeasureTimeValues *overheadMeasureStart = getZeroValues();
  MeasureTimeValues *overheadMeasureEnd = getZeroValues();

  for(int i = 0; i < 10; i++) //warmup
  {
    MeasureTime::getTimeValues(overheadMeasureStart);
    MeasureTime::getTimeValues(overheadMeasureEnd);
  }

  for(int i = 0; i < 100; i++)
  {
    MeasureTime::getTimeValues(overheadMeasureStart);
    MeasureTime::getTimeValues(overheadMeasureEnd);
    overheadMeasureEnd->sub(overheadMeasureStart);
    overhead->add(overheadMeasureEnd);
  }
  overhead->div(100);

  delete overheadMeasureStart;
  delete overheadMeasureEnd;
}

void MeasureTime::writeTimeToJason(std::string model_name, std::vector<MeasureTimeData> data)
{
  std::stringstream date;
  date.str("");
  time_t sec = time(NULL);
  tm * date_t = localtime(&sec);
  date << date_t->tm_year + 1900 << "-" << date_t->tm_mon + 1 << "-" << date_t->tm_mday << " " << date_t->tm_hour << ":" << date_t->tm_min << ":" << date_t->tm_sec;
  std::ofstream os;
  os.open((model_name + std::string("_prof.json")).c_str());
  os << "{\n\"name\":\"" << model_name << "\",\n";
  os << "\"prefix\":\"" << model_name << "\",\n";
  os << "\"date\":\"" << date.str() << "\",\n";

  os << "\"functions\":[\n],\n";
  os << "\"profileBlocks\":[\n";

  for (unsigned i = 0; i < data.size(); ++i)
  {
    os << "{\"id\":" << i+1 << ",\"ncall\":" << data[i].numCalcs << "," << data[i].sumMeasuredValues->serializeToJson() << "},\n";
  }
  os << "]\n}";
  os.close();
}
