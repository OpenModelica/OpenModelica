#include <Core/Utils/extension/measure_time.hpp>

MeasureTime * MeasureTime::instance = 0;
MeasureTime::file_map MeasureTime::toWrite;

MeasureTimeValues::MeasureTimeValues() {}

MeasureTimeValues::~MeasureTimeValues() {}

MeasureTimeData::MeasureTimeData() : id(""), sumMeasuredValues(MeasureTime::getZeroValues()), numCalcs(0) {}

MeasureTimeData::MeasureTimeData(std::string id) : id(id), sumMeasuredValues(MeasureTime::getZeroValues()), numCalcs(0) {}

MeasureTimeData::~MeasureTimeData()
{
  //if(sumMeasuredValues != NULL)
    //delete sumMeasuredValues;
}

std::string MeasureTimeData::serializeToJson() const
{
  std::stringstream ss("");
  ss << "\"ncall\":" << numCalcs << "," << sumMeasuredValues->serializeToJson();
  return ss.str();
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
  std::cerr << "Deinit:" << std::endl;
  if (instance != 0)
  {
    std::cerr << "try is " << std::endl;
    delete instance;
  std::cerr << "succed!" << std::endl;
  }
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

void MeasureTime::setOverheadToZero()
{
  if(overhead != NULL)
    delete overhead;

  overhead = getZeroValuesP();
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
    MeasureTime::getTimeValuesStart(overheadMeasureStart);
    MeasureTime::getTimeValuesEnd(overheadMeasureEnd);
  }

  for(int i = 0; i < 100; i++)
  {
    MeasureTime::getTimeValuesStart(overheadMeasureStart);
    MeasureTime::getTimeValuesEnd(overheadMeasureEnd);
    overheadMeasureEnd->sub(overheadMeasureStart);
    overhead->add(overheadMeasureEnd);
  }
  overhead->div(100);

  delete overheadMeasureStart;
  delete overheadMeasureEnd;
}

void MeasureTime::addResultContentBlock(const std::string model_name, const std::string blockname, const std::vector<MeasureTimeData> * in)
{
  toWrite[model_name][blockname] = in;
}

void MeasureTime::writeToJson()
{
  std::stringstream date;
  date.str("");
  time_t sec = time(NULL);
  tm * date_t = localtime(&sec);
  date << date_t->tm_year + 1900 << "-" << date_t->tm_mon + 1 << "-" << date_t->tm_mday << " " << date_t->tm_hour << ":" << date_t->tm_min << ":" << date_t->tm_sec;

  for( file_map::const_iterator model = toWrite.begin() ; model != toWrite.end() ; ++model ) // iterate files
  {
    std::ofstream os;
    os.open((model->first + std::string("_prof.json")).c_str());
    os << "{\n\"name\":\"" << model->first << "\",\n";
    os << "\"prefix\":\"" << model->first << "\",\n";
    os << "\"date\":\"" << date.str() << "\",\n";

    //write blocks:
    bool isFirstBlock = true;
    for( block_map::const_iterator block = model->second.begin() ; block != model->second.end() ; ++block ) // iterate blocks
    {
      const std::vector<MeasureTimeData> * data = block->second;

      if(isFirstBlock) isFirstBlock = false;
      else
      {
        os << ",\n";
      }
      os << "\"" << block->first << "\":[\n";

      //write data
      for (unsigned i = 0; i < data->size()-1; ++i)
      {
        os << "{\"id\":\"" << (*data)[i].id << "\"," << (*data)[i].serializeToJson() << "},\n";
      }
      if( data->size() > 0 ) os << "{\"id\":\"" << (*data)[data->size()-1].id << "\"," << (*data)[data->size()-1].serializeToJson() << "}]";
      else os << "]";

    } // end blocks

    os << "\n}\n";
    os.close();

  } // end files
}
