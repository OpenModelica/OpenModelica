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

#include <vector>
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>

using namespace std;

#include "tables.h"
#include "simulation_runtime.h"

vector<InterpolationTable*> interpolationTables;
vector<InterpolationTable2D*> interpolationTables2D;

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

extern "C"
int omcTable2DIni(int ipoType,
	char *tableName,char* fileName, double *table,int tableDim1,int tableDim2,int colWise)
{
	// might be called several times, only initialize once.
	int i=0;
	for (vector<InterpolationTable2D*>::iterator it = interpolationTables2D.begin(); it != interpolationTables2D.end(); it++,i++)
		{
			/* A table is identified by its fileName, columnName and memory location ptr*/
			if (string((*it)->getTableName()) == string(tableName) &&
				string((*it)->getFileName()) == string(fileName) &&
				(*it)->getData() == table) {
					return i;
			}
		}
	interpolationTables2D.push_back(
			new InterpolationTable2D(ipoType,
			  tableName,fileName,table,tableDim1,tableDim2,colWise)
	);
		// use position in vector (0..n-1) as tableID
	return interpolationTables2D.size()-1;
}

extern "C"
double omcTable2DIpo(int tableID,double u1_, double u2_)
{
    if ((int)interpolationTables2D.size() != 0 && tableID >= 0 && tableID < (int)interpolationTables2D.size()) {
    	return interpolationTables2D[tableID]->Interpolate(u1_,u2_);
    } else { // error, unvalid tableID
    	if (acceptedStep) {
    		cerr << "in omcTable2DIpo, tableID " << tableID << " is not a valid table ID." << endl;
    		cerr << " There are currently " << interpolationTables2D.size() << " tables allocated" << endl;
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


/* Implementation of InterpolationTable2D class */

InterpolationTable2D::InterpolationTable2D(int ipoType,
			char* tableName, char* fileName, double *table, int tableDim1, int tableDim2, int colWise)
			: fileName_(fileName),tableName_(tableName),
			ipoType_(ipoType),
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

InterpolationTable2D::InterpolationTable2D()
 : 	ipoType_(0), data_(0),nRows_(0), nCols_(0)
{
}

InterpolationTable2D::~InterpolationTable2D()
{
}

/* interpolation */
double InterpolationTable2D::Interpolate(double u1_, double u2_)
{
	check_data(u1_,u2_);

	/* bilinear Interpolation */

	// next smaller points of u1 and u2
	unsigned int u1_dis = 0;
	unsigned int u2_dis = 0;

	/* simple algorithm to get u1_dis/u2_dis, ToDo: use better algorithm */
	for(unsigned int i=1; i<nRows_;i++)
	{
		if(getElt(i,0)>=u1_)
		{
			u1_dis=i;
			break;
		}
	}

	if(u1_dis==nRows_) u1_dis-=1;

	for(unsigned int i=1; i<nCols_;i++)
	{
		if(getElt(0,i)>=u2_)
		{
			u2_dis=i;
			break;
		}
	}

	if(u2_dis==nCols_) u2_dis-=1;

	double u11, u12, u21, u22;
	u11=getElt(u1_dis,0);
	u12=getElt(u1_dis+1,0);
	u21=getElt(0,u2_dis);
	u22=getElt(0,u2_dis+1);

	double f_u11,f_u12,f_u21,f_u22;
	f_u11=getElt(u1_dis,u2_dis);
	f_u12=getElt(u1_dis,u2_dis+1);
	f_u21=getElt(u1_dis+1,u2_dis);
	f_u22=getElt(u1_dis+1,u2_dis+1);

	/* bilinear Interpolation */
	double f_r1, f_r2;
	f_r1= (u12-u1_)/(u12-u11) * f_u11 + (u1_-u11)/(u12-u11)*f_u21;
	f_r2= (u12-u1_)/(u12-u11) * f_u12 + (u1_-u11)/(u12-u11)*f_u22;

	return (u22-u2_)/(u22-u21)*f_r1 + (u2_-u21)/(u22-u21)*f_r2;
}

/* test if u1 and u2 are strict growing */
bool InterpolationTable2D::check_data(double u1_, double u2_)
{
	for(unsigned int i=1;i<nRows_-1;i++)
	{
		if(!(getElt(i,0)<getElt(i+1,0))) throw "u1 nicht streng monoton";
	}

	for(unsigned int i=1;i<nCols_-1;i++)
	{
		if(!(getElt(0,i)<getElt(0,i+1))) throw "u2 nicht streng monoton";
	}

	if( (u1_ < min_row()) || (u1_ > max_row()) || (u2_ < min_col()) || (u2_ > max_col()) ) throw "zu interpolierende Punkte ausserhalb des Gitters";

	return true;
}

/* get boundary values of area */
double InterpolationTable2D::max_row()
{
	if (nRows_==0) return 0.0;
	else return getElt(nRows_-1,0);
}
double InterpolationTable2D::min_row()
{
	if (nRows_==0) return 0.0;
	else return getElt(1,0);
}
double InterpolationTable2D::max_col()
{
	if (nCols_==0) return 0.0;
	else return getElt(0,nCols_-1);
}
double InterpolationTable2D::min_col()
{
	if (nCols_==0) return 0.0;
	else return getElt(0,1);
}

/* \brief returns an element in the data matrix, given a row and column. Respects the colWise member.
 */
double InterpolationTable2D::getElt(unsigned int row, unsigned int col)
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
void InterpolationTable2D::readMatFile(string& fileName, string& columnName)
{
	cerr << "Reading data from matlab file not impl. yet" << endl;
}


/** \brief Read data from text file.
 *
 * Text file format:
 *  #1
 * double A(2,2) # comment here
 *   0 0 1
 *   0 0 0
 *   1 1 1
 * double M(3,3) # comment
 *   0 0 1 2
 *   0 1 4 5
 *   1 3 1 1
 *   2 1 1 1
 */

void InterpolationTable2D::readTextFile(string& fileName, string& columnName)
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
		for (unsigned int r = 0,i=0; r < nRows_; r++) {
			for (unsigned int c = 0; c < nCols_; c++) {
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
bool InterpolationTable2D::readTableHeader(string line)
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
bool InterpolationTable2D::isTableHeaderNamed(string line, string& columnName)
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

void InterpolationTable2D::readCSVFile(string& fileName, string& columnName)
{
	cerr << "Reading data from CSV file not impl. yet" << endl;
}
