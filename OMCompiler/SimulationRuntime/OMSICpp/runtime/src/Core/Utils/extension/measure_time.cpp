#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Utils/extension/measure_time.hpp>
#include <Core/Utils/extension/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>

MeasureTime * MeasureTime::_instance = NULL;
MeasureTime::file_map MeasureTime::_valuesToWrite;

MeasureTimeValues::MeasureTimeValues() : _numCalcs(0){}

MeasureTimeValues::~MeasureTimeValues()
{
}

void MeasureTimeValues::reset()
{
  _numCalcs = 0;
}

MeasureTimeValuesSolver::MeasureTimeValuesSolver() : MeasureTimeValues(), _functionEvaluations(0), _errorTestFailures(0)
{}

MeasureTimeValuesSolver::MeasureTimeValuesSolver(unsigned long long functionEvaluations, unsigned long long errorTestFailures) :
        MeasureTimeValues(), _functionEvaluations(functionEvaluations), _errorTestFailures(errorTestFailures)
{}

MeasureTimeValuesSolver::MeasureTimeValuesSolver(const MeasureTimeValuesSolver &timeValues) :
        MeasureTimeValues(), _functionEvaluations(timeValues._functionEvaluations), _errorTestFailures(timeValues._errorTestFailures)
{}

MeasureTimeValuesSolver::~MeasureTimeValuesSolver() {}

std::string MeasureTimeValuesSolver::serializeToJson() const
{
  std::stringstream ss;
  ss << "\"functionEvaluations\":" <<  _functionEvaluations << ",\"errorTestFailures\":" << _errorTestFailures;
  return ss.str();
}

void MeasureTimeValuesSolver::add(MeasureTimeValues *values)
{
  MeasureTimeValuesSolver *val = static_cast<MeasureTimeValuesSolver*>(values);
  _functionEvaluations += val->_functionEvaluations;
  _errorTestFailures += val->_errorTestFailures;
}

void MeasureTimeValuesSolver::sub(MeasureTimeValues *values)
{
  MeasureTimeValuesSolver *val = static_cast<MeasureTimeValuesSolver*>(values);
  _functionEvaluations -= val->_functionEvaluations;
  _errorTestFailures -= val->_errorTestFailures;
}

void MeasureTimeValuesSolver::div(int counter)
{
  _functionEvaluations = _functionEvaluations / counter;
  _errorTestFailures = _errorTestFailures / counter;
}

MeasureTimeValues* MeasureTimeValuesSolver::clone() const
{
  return new MeasureTimeValuesSolver(*this);
}

void MeasureTimeValuesSolver::reset()
{
  MeasureTimeValues::reset();
  _functionEvaluations = 0;
  _errorTestFailures = 0;
}

MeasureTimeData::MeasureTimeData() : _id(""), _sumMeasuredValues(MeasureTime::getZeroValues())
{

}

MeasureTimeData::MeasureTimeData(std::string id) : _id(id), _sumMeasuredValues(MeasureTime::getZeroValues())
{

}

MeasureTimeData::MeasureTimeData(const MeasureTimeData &data): _id(data._id), _sumMeasuredValues(data._sumMeasuredValues->clone())
{

}

MeasureTimeData::~MeasureTimeData()
{
  if(_sumMeasuredValues != NULL)
    delete _sumMeasuredValues;
}

std::string MeasureTimeData::serializeToJson() const
{
  std::stringstream ss("");
  ss << _sumMeasuredValues->serializeToJson();
  return ss.str();
}

MeasureTime::MeasureTime() : _measuredOverhead(NULL) {}

MeasureTime::~MeasureTime()
{
  for(file_map::iterator it = _valuesToWrite.begin(); it != _valuesToWrite.end(); it++)
  {
    for(block_map::iterator iter = it->second.begin(); iter != it->second.end(); iter++)
    {
      for(int i = 0; i < iter->second->size(); i++)
        delete iter->second->at(i);

      iter->second->clear();
      delete iter->second;
    }
    it->second.clear();
  }
  _valuesToWrite.clear();

  if(_measuredOverhead != NULL)
    delete _measuredOverhead;

  _measuredOverhead = NULL;
}

MeasureTime* MeasureTime::getInstance()
{
  return _instance;
}

void MeasureTime::deinitialize()
{
  if (_instance != NULL)
  {
    delete _instance;
  }
  _instance = NULL;
}

MeasureTimeValues* MeasureTime::getZeroValues()
{
  if (_instance == NULL)
    return NULL;

  return _instance->getZeroValuesP();
}

MeasureTimeValues* MeasureTime::getOverhead()
{
  if (_instance == NULL)
    return NULL;

  return _instance->_measuredOverhead;
}

void MeasureTime::setOverheadToZero()
{
  if(_measuredOverhead != NULL)
    delete _measuredOverhead;

  _measuredOverhead = getZeroValuesP();
}

void MeasureTime::benchOverhead()
{
  if(_measuredOverhead != NULL)
    delete _measuredOverhead;

  _measuredOverhead = getZeroValues();

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
    _measuredOverhead->add(overheadMeasureEnd);
  }
  _measuredOverhead->div(100);

  delete overheadMeasureStart;
  delete overheadMeasureEnd;
}

void MeasureTime::addResultContentBlock(std::string modelName, std::string blockName, std::vector<MeasureTimeData*> *data)
{
  _valuesToWrite[modelName][blockName] = data;
}

void MeasureTime::writeToJson()
{
  std::stringstream date;
  std::string tmpS;
  date.str("");
  time_t sec = time(NULL);
  tm * date_t = localtime(&sec);
  date << date_t->tm_year + 1900 << "-" << date_t->tm_mon + 1 << "-" << date_t->tm_mday << " " << date_t->tm_hour << ":" << date_t->tm_min << ":" << date_t->tm_sec;

  for( file_map::iterator model = _valuesToWrite.begin() ; model != _valuesToWrite.end() ; ++model ) // iterate files
  {
    std::ofstream os;
    os.open((model->first + std::string("_prof.json")).c_str());
    os << "{\n\"name\":\"" << model->first << "\",\n";
    os << "\"prefix\":\"" << model->first << "\",\n";
    os << "\"date\":\"" << date.str() << "\",\n";

    //write blocks:
    bool isFirstBlock = true;
    for( block_map::iterator block = model->second.begin() ; block != model->second.end() ; ++block ) // iterate blocks
    {
      std::vector<MeasureTimeData*> *data = block->second;

      if(isFirstBlock) isFirstBlock = false;
      else
      {
        os << ",\n";
      }
      os << "\"" << block->first << "\":[\n";

      //write data
      for (unsigned i = 0; i < (data->size() == 0 ? 1 : data->size()) - 1; ++i)
      {
          if((*data)[i] == NULL)
          {
              LOGGER_WRITE("Skipped a measured block in '" + block->first + "' because it is null.", LC_OUTPUT, LL_ERROR);
              continue;
          }
    	  tmpS = (*data)[i]->serializeToJson();
    	  if(tmpS != "")
    		  os << "{\"id\":\"" << (*data)[i]->_id << "\"," << tmpS << "},\n";
      }
      if( data->size() > 0 ) os << "{\"id\":\"" << (*data)[data->size()-1]->_id << "\"," << (*data)[data->size()-1]->serializeToJson() << "}]";
      else os << "]";

    } // end blocks

    os << "\n}\n";
    os.close();

    std::cout << "Profiling results written to " << (model->first + std::string("_prof.json")) << std::endl;

  } // end files
}
