/*
Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <vector>
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>

using namespace std;

#include "tables.h"
#include "simulation_runtime.h"

vector<InterpolationTable*> interpolationTables;

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
	char *tableName,char* fileName, double *table,int tableDim1,int tableDim2,int colWise)
{	
	// might be called several times, only initialize once.
	int i=0;
	for (vector<InterpolationTable*>::iterator it = interpolationTables.begin(); it != interpolationTables.end(); it++,i++)
		{
			/* A table is identified by its fileName, columnName and memory location ptr*/
			if (string((*it)->getTableName()) == string(tableName) && 
				string((*it)->getFileName()) == string(fileName) &&
				(*it)->getData() == table) {
					return i;
			}	
		}
	interpolationTables.push_back(
			new InterpolationTable(timeIn,startTime,ipoType,expoType,
			  tableName,fileName,table,tableDim1,tableDim2,colWise)
	);		
		// use position in vector (0..n-1) as tableID
	return interpolationTables.size()-1; 
}

extern "C"
double omcTableTimeIpo(int tableID,int icol,double timeIn)
{ 	
    if ((int)interpolationTables.size() != 0 && tableID >= 0 && tableID < (int)interpolationTables.size()) {
    	return interpolationTables[tableID]->Interpolate(timeIn,icol-1);	
    } else { // error, unvalid tableID
    	if (acceptedStep) {
    		cerr << "in omcTableTimeIpo, tableID " << tableID << " is not a valid table ID." << endl;
    		cerr << " There are currently " << interpolationTables.size() << " tables allocated" << endl;
    	}
    	return 0.0;
    }
}

extern "C"
double omcTableTimeTmax(int tableID)
{
	 if ((int)interpolationTables.size() != 0 && tableID >= 0 && tableID < (int)interpolationTables.size()) {
	 	InterpolationTable* table = interpolationTables[tableID];
	 	return table->MaxTime();
    } else { // error, unvalid tableID
    	if (acceptedStep) {
    		cerr << "in omcTableTimeTmax, tableID " << tableID << " is not a valid table ID." << endl;
	    	cerr << " There are currently " << interpolationTables.size() << " tables allocated" << endl;
    	}    	
    	return 0.0;
    }	
}

extern "C"
double omcTableTimeTmin(int tableID)
{
	 if ((int)interpolationTables.size() != 0 && tableID >= 0 && tableID < (int)interpolationTables.size()) {
	 	InterpolationTable* table = interpolationTables[tableID];
	 	return table->MinTime();
    } else { // error, unvalid tableID
    	if (acceptedStep) {
    		cerr << "in omcTableTimeTmin, tableID " << tableID << " is not a valid table ID." << endl;
    		cerr << " There are currently " << interpolationTables.size() << " tables allocated" << endl;
    	}
    	return 0.0;
    }
}


/* Implementation of InterpolationTable class */


InterpolationTable::InterpolationTable(double time,double startTime, int ipoType, int expoType,
			char* tableName, char* fileName, double *table, int tableDim1, int tableDim2, int colWise)
			: fileName_(fileName),tableName_(tableName), 
			time_(time), startTime_(startTime),
			ipoType_(ipoType), expoType_(expoType),
			colWise_(colWise),
			data_(table),nRows_(tableDim1),nCols_(tableDim2)
{
	string fileStr = string(fileName);
	string tableStr = string(tableName);
	if (string(fileName) != string("NoName")) { // data in file
		if ( fileStr.length()> 4 && fileStr.substr(fileStr.length()-4,4) == string(".mat")) {
			fileStr = string(model_dir)+string("/")+fileStr;
			readMatFile(fileStr,tableStr);
		} else if ( fileStr.length()> 4 && fileStr.substr(fileStr.length()-4,4) == string(".txt")) {
			fileStr = string(model_dir)+string("/")+fileStr;			
			readTextFile(fileStr,tableStr);
		} else if (fileStr.length()> 4 && fileStr.substr(fileStr.length()-4,4) == string(".csv")) {
			fileStr = string(model_dir)+string("/")+fileStr;
			readCSVFile(fileStr,tableStr);
		} else {
			cerr << "Error, unsupported file extension. Filename must end with .mat, .txt or .csv, filename is " 
			<< fileName << endl;
		}		
	}
}	

InterpolationTable::InterpolationTable() 
 : time_(0.0), startTime_(0.0),
			ipoType_(0), expoType_(0),
			data_(0),nRows_(0), nCols_(0) 
{
}

InterpolationTable::~InterpolationTable() 
{
}
/** \brief Returns the maximum time value in the first data column
 */
double InterpolationTable::MaxTime()
{
	if (data_ == 0) return 0.0; 
	else return getElt(nRows_-1,0);
}

/** \brief Returns the minimum time value in the first data column
 */ 
double InterpolationTable::MinTime()
{
	if (data_ == 0) return 0.0; 
	else return getElt(0,0);
}

/** \brief Returns the interpolated value at time from a given column number 0..n
 */
double InterpolationTable::Interpolate(double time, int col)
{   int i=0;
	double y=0,y1,y2,t1,t2;
	if (time < startTime_ || data_ == 0) return 0.0;
	
	time -= startTime_;
	
	while(i < nRows_ && getElt(i,0) <= time) i++;
	if (i == nRows_ || i == 0 ) { // time before or after end of data
		y = extrapolate(time,col,i == 0);
	} else {
	  	t1 = getElt(i-1,0);
	  	t2 = getElt(i,0);
	  	y1 = getElt(i-1,col);
	  	y2 = getElt(i,col);
	  	y =  y1 + (y2 - y1)*(time - t1)/(t2 - t1);	  	
	}
	return y; 
}

/* \brief Performs extrapolation of data outside the interpolated data region.
 */
double InterpolationTable::extrapolate(double time, int col,bool beforeData)
{
	double t1,t2,y1,y2,y=0.0;
	if (expoType_ == 0) { // Hold last/first value
		y= getElt(beforeData? 0: nRows_-1,col);
	} else if  ( expoType_ == 1) { // Extrapolate through last/first two values
		if (beforeData) {
		t1 = getElt(0,0);
	  	t2 = getElt(1,0);
	  	y1 = getElt(nRows_-2,col);
	  	y2 = getElt(nRows_-1,col);
	  	y =  y1 + (y2 - y1)*(time - t1)/(t2 - t1);
		} else {
		t1 = getElt(nRows_-2,0);
	  	t2 = getElt(nRows_-1,0);
	  	y1 = getElt(nRows_-2,col);
	  	y2 = getElt(nRows_-1,col);
	  	y =  y1 + (y2 - y1)*(time - t1)/(t2 - t1);
		}	
	} else if ( expoType_ == 2) { // periodically repeat signal
		double endPeriodTime = MaxTime();
		while (time >= endPeriodTime) time -= endPeriodTime;		
		y = Interpolate(time+startTime_,col);
	}
	return y;
}

/* \brief returns an element in the data matrix, given a row and column. Respects the colWise member.
 */
double InterpolationTable::getElt(int row, int col)
{
	// Remove this check once running. it's internal checking only.
	if (row < 0 || row > nRows_ || col < 0 || col > nCols_) {
		if(acceptedStep) {
			cerr << "Error, indexing out of data with data[" << row << ", " << col << "]" << endl;
			cerr << "nRows = " << nRows_ << " nCols = " << nCols_ << endl;
		}
		return 0.0;
	}
	int index = 0;
	if (colWise_ == 0) { // Column major
		index = col + row*nCols_;
	} else { // Row major
		index = row + col*nRows_;
	}
	return data_[index];
}
/** \brief Read data from matlab file 
 * 
 **/
void InterpolationTable::readMatFile(string& fileName, string& columnName)
{
	cerr << "Reading data from matlab file not impl. yet" << endl;	
}


/** \brief Read data from text file.
 * 
 * Text file format: 
 *  #1  
 * double A(2,2) # comment here
 *   1 0
 *   0 1
 * double M(3,3) # comment
 *   1 2 3
 *   3 4 5
 *   1 1 1
 */ 

void InterpolationTable::readTextFile(string& fileName, string& columnName)
{
	ifstream file(fileName.c_str());
	
	if (!file) {
		cerr << "Error opening file " << fileName << endl;
	}
	char buf[400];
	while(file.getline(buf,400) && !isTableHeaderNamed(string(buf),columnName));
	
	if (file.eof()) {
		cerr << "Error, table " << columnName << " not found in file " << fileName << endl;
		return;
	}	
	if (readTableHeader(string(buf))) {
		data_ = new double[nRows_*nCols_];
		for (int r = 0,i=0; r < nRows_; r++) {
			for (int c = 0; c < nCols_; c++) {
				file >> data_[i++];
			}
		}	 
	} else { // Error reading data.
		cerr << "Error reading data from file " << fileName << endl;
	nRows_=0;
	nCols_=0;
	data_=0;	
	}
}

/* \brief Reads the column and row size from the header and stores in nRows_ and nCols_
*/
bool InterpolationTable::readTableHeader(string line)
{
	string::size_type pos = line.find("(");
	if (pos == string::npos) {
		cerr << "error reading column and row size from header: " << line << endl;
	}
	stringstream str(line.substr(pos+1));
	str >> nRows_;
	char ch;
	if ((ch = str.get()) != ',') {
		cerr << "error reading column and row size from header: " << line 
		<< " column and row size should be separated by ',', got " << ch <<  endl;
		return false;
	}
	str >> nCols_;
   return true;
}

/* \brief checks if line is a header with tablename = columnName
 */
bool InterpolationTable::isTableHeaderNamed(string line, string& columnName)
{
	if (line.compare(0,6,string("double"))==0) {
		string::size_type pos = line.find_first_not_of(string(" "),7);
		if (pos == string::npos) {
			cerr << "error in table header: " <<  line << endl;
			return false;	
		}
		string subStr = line.substr(pos);
		if(subStr.compare(0,columnName.length(),columnName)==0) {
			return true;
		}			
	}
	return false;
}

void InterpolationTable::readCSVFile(string& fileName, string& columnName)
{
	cerr << "Reading data from CSV file not impl. yet" << endl;
}
