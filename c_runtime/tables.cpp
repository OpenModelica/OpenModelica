/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include <deque>
#include <string>
#include <iostream>
#include <fstream>
#include <utility>
#include <memory>
#include <cstring>
#include <limits>
#include <algorithm>
#include <cmath>
#include <cassert>
#include <cstdarg>
#include <cctype>

#include "simulation_runtime.h"

#include "tables.h"

//extern char *model_dir; // defined somewhere else (where?)

namespace {

// definition and implementation of some error classes
class CustomError : public TerminateSimulationException
{
protected:
  inline void saveMessage(const char *format, va_list args)
  {
    char buf[4096];
    vsnprintf(buf,4096,format,args);
    errorMessage.assign(buf);
  }
  CustomError() {}
public:
  explicit CustomError(const char *format, ...)
 :TerminateSimulationException(0.0)
  {
    va_list args;
    va_start(args,format);
    saveMessage(format,args);
    va_end(args);
  }
  virtual ~CustomError() throw() {}
};
class AllocFailed : public CustomError
{
protected:
  explicit AllocFailed() {}
public:
  explicit AllocFailed(const char *func)
    :CustomError("%s(): Could not allocate memory.",func) {}
//  explicit AllocFailed(const char *type)
//    :CustomError("Could not allocate memory of type %s.",type) {}
  explicit AllocFailed(const char *type, long size)
    :CustomError("Could not allocate memory buffer of type %s and size %d.",type,size) {}
  explicit AllocFailed(const char *func, const char *type, long size)
    :CustomError("%s(): could not allocate memory buffer of type %s and size %d.",func,type,size) {}
  virtual ~AllocFailed() throw() {}
};

// std::deque wrapper that calls deletes stores pointer in destructor
template <typename item_t>
class Holder {
public:
  inline item_t* &operator[](size_t idx)  { return list[idx]; }
  inline void push_back(item_t* item) { list.push_back(item); }
  inline size_t size() { return list.size(); }
  ~Holder()
  { std::for_each(list.begin(),list.end(),free); }
private:
  std::deque<item_t*> list;
  static void free(item_t* item) { delete item; }
};

class InterpolationTable;
class InterpolationTable2D;

Holder<InterpolationTable> interpolationTables;
Holder<InterpolationTable2D> interpolationTables2D;


class InterpolationTable {
public:
  InterpolationTable(double time,double startTime, int ipoType, int expoType,
		     const char* tableName, const char* fileName, 
		     double *table, 
		     int tableDim1, int tableDim2,int colWise);
  InterpolationTable(InterpolationTable& orig);
  ~InterpolationTable();
  double interpolate(double time, size_t col) const;
  double maxTime() const { return (data?getElt(rows-1,0):0.0); }
  double minTime() const { return (data?data[0]:0.0); }
  bool compare(const char* fname, const char* tname, const double* table) const;
private:
  double extrapolate(double time, size_t col, bool beforeData) const;
  inline double interpolateLin(double time, size_t i, size_t j) const;
  inline const double& getElt(size_t row, size_t col) const;
  void checkValidityOfData() const;

  std::string filename;
  std::string tablename;
  bool own_data;
  double* data;
  size_t rows;
  size_t cols;
  bool colWise;
  int ipoType;
  int expoType;
  double startTime;
};

class InterpolationTable2D {
public:
  InterpolationTable2D(int ipoType, const char* tableName,
		       const char* fileName, double *table,
		       int tableDim1, int tableDim2, int colWise);
  ~InterpolationTable2D();
  double interpolate(double x1, double x2);
  bool compare(const char* fname, const char* tname, const double* table) const;
private:
  std::string filename;
  std::string tablename;
  bool own_data;
  double *data;
  size_t rows;
  size_t cols;

  bool colWise;
  int ipoType;
  int expoType;

  double linInterpolate(double x, double x_1, double x_2,
			double f_1, double f_2) const;
  const double& getElt(size_t row, size_t col) const;
  void checkValidityOfData() const;
};

} // namespace

/* Initialize table.
 * timeIn - time
 * startTime - time-Offset for the signal.
 * ipoType - type of interpolation.
 *   0 = linear interpolation,
 * 	 1 = smooth interpolation with akima splines s.t der(y) is continuous
 * expoType - extrapolation type
 *   0 = hold first/last value outside the range
 *   1 = extrapolate outside the rang using last/first two values
 *   2 = periodically repeat table data
 * tableName - name of table
 * table - matrix with table data
 * tableDim1 - number of rows of table
 * tableDim2 - number of columns of table.
 * colWise - 0 = column major order
 *           1 = row major order
 */

extern "C"
int omcTableTimeIni(double timeIn, double startTime,int ipoType,int expoType,
		    const char *tableName, const char* fileName, 
		    double *table,int tableDim1, int tableDim2,int colWise)
{
  // if table is already initialized, find it
  for(size_t i = 0; i < interpolationTables.size(); ++i)
    if (interpolationTables[i]->compare(fileName,tableName,table))
      return i;
  // otherwise initialize new table
  interpolationTables.push_back(new InterpolationTable(timeIn,startTime,
						       ipoType,expoType, 
						       tableName, fileName, 
						       table, tableDim1, 
						       tableDim2, colWise));
  return (interpolationTables.size()-1);
}

extern "C"
double omcTableTimeIpo(int tableID, int icol, double timeIn)
{
  if (tableID >= 0 && tableID < (int)interpolationTables.size())
    return interpolationTables[tableID]->interpolate(timeIn,icol-1);
  else
    return 0.0;
}

extern "C"
double omcTableTimeTmax(int tableID)
{
  if (tableID >= 0 && tableID < (int)interpolationTables.size())
    return interpolationTables[tableID]->maxTime();
  else
    return 0.0;
}

extern "C"
double omcTableTimeTmin(int tableID)
{
  if (tableID >= 0 && tableID < (int)interpolationTables.size())
    return interpolationTables[tableID]->minTime();
  else
    return 0.0;
}

extern "C"
int omcTable2DIni(int ipoType, const char *tableName, const char* fileName, 
		  double *table,int tableDim1,int tableDim2,int colWise)
{
  // if table is already initialized, find it
  for(size_t i = 0; i < interpolationTables2D.size(); ++i)
    if (interpolationTables2D[i]->compare(fileName,tableName,table))
      return i;
  // otherwise initialize new table
  interpolationTables2D.push_back(new InterpolationTable2D(ipoType,tableName,
		                  fileName,table,tableDim1,tableDim2,colWise));
  return (interpolationTables2D.size()-1);
}

extern "C"
double omcTable2DIpo(int tableID,double u1_, double u2_)
{
  if (tableID >= 0 && tableID < (int)interpolationTables2D.size())
    return interpolationTables2D[tableID]->interpolate(u1_,u2_);
  else
    return 0.0;
}

// ******************************
//  ***    IMPLEMENTATION    ***
// ******************************
namespace {

class FileWrapper {
public:
  virtual bool findTable(const char* tableName,
			 size_t& cols, size_t& rows) =0;
  virtual void readTable(double *buf, size_t rows, size_t cols) =0;
  virtual void close() =0;

  static FileWrapper* openFile(const std::string& filename);
};

// \brief Read data from text file.
// 
//  Text file format:
//   #1
//  double A(2,2) # comment here
//    1 0
//    0 1
//  double M(3,3) # comment
//    1 2 3
//    3 4 5
//    1 1 1
// 
class TextFile : public FileWrapper {
public:
  static FileWrapper* create(const std::string& fileName)
  {  return new TextFile(fileName); }
  TextFile(const std::string& fileName):filename(fileName),line(0),lnStart(0)
  {
    fp.open(filename.c_str());
    if (!fp)
      throw CustomError("Could not open file `%s' for reading",filename.c_str());
  }
  virtual ~TextFile()
  {
    fp.close();
  }

  virtual bool findTable(const char* tableName, 
			 size_t& cols, size_t& rows)
  {
    std::string strLn, tblName;
    size_t _cols, _rows;

    while (fp.good()) {
      // start new line, update counters
      ++line;
      lnStart= fp.tellg();

      // read whole line
      std::getline(fp,strLn);
      if (!fp)
	throw ParsingError(filename,line,(size_t)(fp.tellg()-lnStart));
      // check if we read header
      if (parseHead(strLn.data(),strLn.length(),tblName,_rows,_cols)) {
	// is table name the one we are looking for?
	if (tblName == tableName) {
	  cols = _cols;
	  rows = _rows;
	  return true;
	}
      }
    }
    // no header found
    return false;
  }

  virtual void readTable(double *buf, size_t rows, size_t cols)
  {
    for(size_t i = 0; i < rows; ++i) {
      lnStart = fp.tellg();
      ++line;
      for(size_t j = 0; j < cols; ++j) {
	fp >> buf[i*cols+j];
	if (!fp) throw ParsingError(filename,line,(size_t)(fp.tellg()-lnStart));
      }
      fp.ignore(std::numeric_limits<std::streamsize>::max(),'\n');
    }

  }

  virtual void close()
  {
    fp.close();
    if (!fp.good())
      throw CustomError("Could not close file `%s'.",filename.c_str());
  }
private:
  std::string filename;
  std::ifstream fp;
  size_t line;
  size_t cpos;
  std::ifstream::pos_type lnStart;

  class ParsingError : public CustomError {
  public:
    ParsingError(const char* fileName, size_t line, size_t col)
      :CustomError("In file `%s': parsing error at line %d and col %d.",
		   fileName, line, col) {}
    ParsingError(const std::string& fileName, size_t line, size_t col)
      :CustomError("In file `%s': parsing error at line %d and col %d.",
		   fileName.c_str(), line, col) {}
  };

  void skipLine()
  {
    fp.ignore(std::numeric_limits<std::streamsize>::max(),'\n');
    ++line;
    lnStart = fp.tellg();
  }

  bool parseHead(const char* hdr, size_t hdrLen, std::string& name,
		 size_t& rows, size_t& cols) const
  {
    char* endptr;
    size_t hLen = hdrLen;

    trim(hdr,hLen);
    
    if (strncmp("double",hdr,std::min((size_t)6,hLen)) != 0)
      return false;    
    trim(hdr += 6, hLen -= 6);

    for(size_t len = 1; len < hLen; ++len)
      if (isspace(hdr[len]) || hdr[len] == '(') {
	name.assign(hdr,len);
	hdr += len;
	hLen -= len;
	break;
      }
    if (!readChr(hdr,hLen,'('))
      throw ParsingError(filename,line,hdrLen-hLen);
    rows = (size_t)strtol(hdr,&endptr,10);
    if (hdr == endptr)
      throw ParsingError(filename,line,hdrLen-hLen);
    hLen -= endptr-hdr;
    hdr = endptr;
    if (!readChr(hdr,hLen,','))
      throw ParsingError(filename,line,hdrLen-hLen);
    cols = (size_t)strtol(hdr,&endptr,10);
    if (hdr == endptr)
      throw ParsingError(filename,line,hdrLen-hLen);
    hLen -= endptr-hdr;
    hdr = endptr;
    readChr(hdr,hLen,')');
    
    if (hLen > 0 && *hdr != '#')
      throw ParsingError(filename,line,hdrLen-hLen);

    return true;
  }
  inline void trim(const char* &ptr, size_t& len) const
  {
    for(; len > 0; ++ptr, --len)
      if (!isspace(*ptr)) return;
  }
  inline bool readChr(const char* &ptr, size_t& len, char chr) const
  {
    trim(ptr,len);
    if (len-- > 0 && *(ptr++) != chr)
      return false;
    trim(ptr,len);
    return true;
  }
};


class MatFile : public FileWrapper {
public:
  static FileWrapper* create(const std::string& fileName)
  { 
    return new MatFile(fileName); 
  }
  MatFile(const std::string& fileName):filename(fileName)
  {
    memset(&hdr,0,sizeof(hdr_t));
    fp.open(filename.c_str(),std::ios::in|std::ios::binary);
    if (!fp)
      throw CustomError("Could not open file `%s' for reading.",filename.c_str());
  }
  virtual ~MatFile() {
    fp.close();
  }
  bool findTable(const char* tableName, size_t& cols, size_t& rows)
  {
    char name[256];
    long pos;
    while (!fp.eof()) {
      fp.read((char*)&hdr,sizeof(hdr));
      if (!fp.good())
	throw CustomError("Could not read from file `%s'.",filename.c_str());
      fp.read(name,std::min(hdr.namelen,(long)256));
      if (strncmp(tableName,name,strlen(tableName)) == 0) {
	if (hdr.type%10 != 0 || hdr.type/1000 > 1)
	  throw CustomError("Table `%s' not in supported format.",tableName);
	if (hdr.mrows <= 0 || hdr.ncols <= 0)
	  throw CustomError("Table `%s' has zero dimensions.",tableName);
	rows = hdr.mrows;
	cols = hdr.ncols;
	return true;
      }
      pos = fp.tellg();
      fp.seekg(pos+hdr.mrows*hdr.ncols*getTypeSize(hdr.type)*(hdr.imagf?2:1));
    }
    return false;
  }
  void readTable(double *buf, size_t rows, size_t cols)
  {
    elem_t readbuf;
    long P = (hdr.type%1000)/100;
    bool isBigEndian = (hdr.type/1000) == 1;
    size_t elemSize = getTypeSize(hdr.type);

    for(size_t i=0; i < rows; ++i)
      for(size_t j=0; j < cols; ++j) {
	fp.read(readbuf.p,elemSize);
	if (!fp.good())
	  throw CustomError("Could not read from file `%s'.",filename.c_str());
	buf[i*cols+j] = getElem(readbuf,P,isBigEndian);
      }
  }
  void close() 
  {
    fp.close();
  }
private:
  typedef struct {
    long type;
    long mrows;
    long ncols;
    long imagf;
    long namelen;
  } hdr_t;
  typedef union {
    char p[8];
    double d;
    float f;
    int i;
    short s;
    unsigned short us;
    unsigned char c;
  } elem_t;
  std::string filename;
  std::ifstream fp;
  hdr_t hdr;
  size_t getTypeSize(long type) const
  {
    switch((type%1000)/100) {
    case 0:
      return sizeof(double);
    case 1:
      return sizeof(float);
    case 2:
      return 4;
    case 3:
    case 4:
      return 2;
    case 5:
      return 1;
    default:
      throw CustomError("Corrupted MAT-file: `%s'",filename.c_str());
    }
  }
  double getElem(elem_t& num, char type, bool dataEndianness)
  {
    switch(type) {
    case 0:
      return correctEndianness(num.d,dataEndianness);
    case 1:
      return correctEndianness(num.f,dataEndianness);
    case 2:
      return correctEndianness(num.i,dataEndianness);
    case 3:
      return correctEndianness(num.s,dataEndianness);
    case 4:
      return correctEndianness(num.us,dataEndianness);
    default:
      return correctEndianness(num.c,dataEndianness);
    }
  }
  template<typename num_t>
	inline num_t correctEndianness(num_t _num, bool dataEndianness) {
    if (getEndianness() != dataEndianness) {
      union {
	num_t num;
	unsigned char b[sizeof(num_t)];
      } dat1, dat2;
      dat1.num = _num;
      for(size_t i=0; i < sizeof(num_t); ++i)
	dat2.b[i] = dat1.b[sizeof(num_t)-i-1];
      return dat2.num;
    }
    return _num;
  }
  inline static bool getEndianness()
  {
    const int endian_test = 1;
    return ((*(char*)&endian_test) == 0);
  }
};

class CSVFile : public FileWrapper {
public:
  static FileWrapper* create(const std::string& fileName)
  { 
    throw CustomError("Loading tables from CSV files not supported.");
    return NULL;
  }
};

FileWrapper *FileWrapper::openFile(const std::string& filename)
{
  static const std::pair<const char*,FileWrapper* (*)(const std::string&)> 
    fileFormats[3] = {
    std::make_pair(".txt",&TextFile::create),
    std::make_pair(".mat",&MatFile::create),
    std::make_pair(".csv",&CSVFile::create)
  };
  FileWrapper *fptr;
  std::string fileExt = filename.substr(filename.rfind('.'));

  for (int i = 0; i < 3; ++i)
    if (fileExt == fileFormats[i].first) {
      fptr = fileFormats[i].second(filename);
      if (!fptr) 
	throw CustomError("Could not allocate memory to read file `%s'",
			  filename.c_str());
      return (fptr);
    }
  throw CustomError("Interpolation table: uknown file extension -- `%s'.",
		    fileExt.c_str());
  return NULL;
}

//
// implementation of InterpolationTable methods
//
InterpolationTable::InterpolationTable(double time, double startTime,
				       int ipoType, int expoType,
				       const char* tableName, const char* fileName, 
				       double* table, int tableDim1,
				       int tableDim2, int colWise)
  :tablename(tableName?tableName:""),own_data(false),data(table),
   rows(tableDim1),cols(tableDim2),colWise(colWise),
   ipoType(ipoType),expoType(expoType),startTime(startTime)
{
  if (fileName && strncmp("NoName",fileName,6) != 0) {
    filename = fileName;
    
    std::auto_ptr<FileWrapper> file(FileWrapper::openFile(filename));
    
    if (file->findTable(tableName,cols,rows)) {
      data = new double[rows*cols];
      if (!data) throw AllocFailed("InterpolationTable","dobule",rows*cols);
      own_data = true;
      
      file->readTable(data,rows,cols);
      file->close();
    } else {
      throw CustomError("No table named `%s' in file `%s'.",tableName,fileName);
    }
  } else {
    data = new double[rows*cols];
    if (!data) throw AllocFailed("InterpolationTime2D","double",rows*cols);
    own_data = true;

    std::copy(table,table+(rows*cols),data);
  }
  // check that time column is strictly monotonous
  checkValidityOfData();
}
InterpolationTable::~InterpolationTable()
{
  if (own_data) delete[] data;
}

double InterpolationTable::interpolate(double time, size_t col) const
{
  size_t lastIdx = colWise ? cols : rows;

  if (!data) return 0.0;

  // substract time offset
  time -= startTime;
  
  if (time < 0.0)
    return extrapolate(time,col,time <= minTime());

  for(size_t i = 1; i < lastIdx; ++i)
    if (getElt(i,0) > time) {
      return interpolateLin(time, i-1,col);
    }
  return extrapolate(time,col,time <= minTime());
}
bool InterpolationTable::compare(const char* fname, const char* tname,
				 const double* table) const
{
  if (fname == NULL || tname == NULL) return false;
  if (strncmp("NoName",fname,6) == 0 && strncmp("NoName",tname,6) == 0)
    // table passed as memory location
    return (data == table);
  else
    // table loaded from file
    return (filename == fname && tablename == tname);
  return false;
}
double InterpolationTable::extrapolate(double time, size_t col, 
				       bool beforeData) const
{
  size_t lastIdx;

  switch(expoType) {
  case 1:
    // hold last/first value
    return getElt((beforeData ? 0 :rows-1),col);
  case 2:
    // extrapolate through first/last two values
    lastIdx = (colWise ? cols : rows) - 2;
    return interpolateLin(time,(beforeData?0:lastIdx),col);
  case 3:
    // periodically repeat signal
    time = startTime + (time - maxTime()*floor(time/maxTime()));
    return interpolate(time,col);
  default:
    return 0.0;
  }
}
double InterpolationTable::interpolateLin(double time, size_t i, size_t j) const
{
  double t_1 = getElt(i,0);
  double t_2 = getElt(i+1,0);
  double y_1 = getElt(i,j);
  double y_2 = getElt(i+1,j);
  //if (std::abs(t_2-t_1) < 100.0*std::numeric_limits<double>::epsilon())
  //  return y_1;
  //else
  return (y_1 + ((time-t_1)/(t_2-t_1)) * (y_2-y_1));
}

const double& InterpolationTable::getElt(size_t row, size_t col) const
{
  assert(row < rows && col < cols);
  return data[colWise ? col*rows+row : row*cols+col];
}
void InterpolationTable::checkValidityOfData() const
{
  size_t maxSize = colWise ? cols : rows;
  for(size_t i = 1; i < maxSize; ++i)
    if (getElt(i-1,0) >= getElt(i,0))
      throw CustomError("TimeTable: Column with time variable not monotonous: %g >= %g.", getElt(i-1,0),getElt(i,0));
}


//
// interpolation 2D
//
InterpolationTable2D::InterpolationTable2D(int ipoType, const char* tableName,
		       const char* fileName, double *table,
		       int tableDim1, int tableDim2, int colWise)
  :tablename(tableName?tableName:""),own_data(false),data(NULL),
   rows(tableDim1),cols(tableDim2), colWise(colWise)
{
  if (fileName && strncmp("NoName",fileName,6) != 0) {
    filename = fileName;
    
    std::auto_ptr<FileWrapper> file(FileWrapper::openFile(filename));
    
    if (file->findTable(tableName,cols,rows)) {
      data = new double[rows*cols];
      if (!data) throw AllocFailed("InterpolationTable2D","double",rows*cols);
      own_data = true;

      file->readTable(data,rows,cols);
      file->close();
    } else {
      throw CustomError("No table named `%s' in file `%s'.",tableName,fileName);
    }
  } else {
    data = new double[rows*cols];
    if (!data) throw AllocFailed("InterpolationTime2D","double",rows*cols);
    own_data = true;

    std::copy(table,table+(rows*cols),data);
  }
  // check if table is valid
  checkValidityOfData();
}
InterpolationTable2D::~InterpolationTable2D()
{
  if (own_data) delete[] data;
}

double InterpolationTable2D::interpolate(double x1, double x2)
{
  size_t i, j;
  if (colWise) std::swap(x1,x2);

  // if out of boundary, just set to min/max
  x1 = fmin(fmax(x1,getElt(1,0)),getElt(rows-1,0));
  x2 = fmin(fmax(x2,getElt(0,1)),getElt(0,cols-1));

  // find intervals corresponding x1 and x2
  for(i = 2; i < rows; ++i)
    if (getElt(i,0) >= x1) break;
  for(j = 2; j < cols; ++j)
    if (getElt(0,j) >= x2) break;
  
  // bilinear interpolation
  double f_1, f_2;
  f_1 = linInterpolate(x1,getElt(i-1,0),getElt(i,0),getElt(i-1,j-1),getElt(i,j-1));
  f_2 = linInterpolate(x1,getElt(i-1,0),getElt(i,0),getElt(i-1,j),getElt(i,j));
  return linInterpolate(x2,getElt(0,j-1),getElt(0,j),f_1,f_2);
}
bool InterpolationTable2D::compare(const char* fname, const char* tname,
				 const double* table) const
{
  if (fname == NULL || tname == NULL) return false;
  if (strncmp("NoName",fname,6) == 0 && strncmp("NoName",tname,6) == 0)
    // table passed as memory location
    return (data == table);
  else
    // table loaded from file
    return (filename == fname && tablename == tname);
  return false;
}

double InterpolationTable2D::linInterpolate(double x, double x_1, double x_2,
					    double f_1, double f_2) const
{
  return ((x_2 - x)*f_1 + (x - x_1)*f_2) / (x_2-x_1);
}
const double& InterpolationTable2D::getElt(size_t row, size_t col) const
{
  assert(row < rows && col < cols);
  return data[row*cols+col];
}

void InterpolationTable2D::checkValidityOfData() const
{
  // check that first row and column are strictly monotonous
  for(size_t i=2; i < rows; ++i)
    if (getElt(i-1,0) >= getElt(i,0))
      throw CustomError("Table2D: independent variable u1 not strictly \
monotonous: %g >= %g.",getElt(i-1,0),getElt(i,0));
  for(size_t i=2; i < cols; ++i)
    if (getElt(0,i-1) >= getElt(0,i))
      throw CustomError("Table2D: independent variable u2 not strictly \
monotonous: %g >= %g.",getElt(0,i-1),getElt(0,i));
}

} // namespace
