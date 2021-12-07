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

#include "util/omc_error.h"
#include "simulation_data.h"
#include "openmodelica_func.h"
#include "simulation/solver/external_input.h"
#include "simulation/options.h"
#include "simulation/solver/model_help.h"
#include <iostream>
#include <sstream>
#include <string>
#include <fstream>
#include <vector>
#include <algorithm>
#include <iomanip>
#include <stdlib.h>
#include <math.h>
#include <ctime>
#include <regex>
#include "omc_config.h"
#include "../util/omc_file.h"
#include <cmath>
#include "dataReconciliation.h"
using namespace std;

extern "C"
{
  int dgesv_(int *n, int *nrhs, double *a, int *lda, int *ipiv, double *b, int *ldb, int *info);
  int dgemm_(char *transa, char *transb, int *m, int *n, int *k, double *alpha, double *a, int *lda,
             double *b, int *ldb, double *beta, double *c, int *ldc);
  int dgetrf_(int *m, int *n, double *a, int *lda, int *ipiv, int *info);
  int dgetri_(int *n, double *a, int *lda, int *ipiv, double *work, int *lwork, int *info);
  int dscal_(int *n, double *da, double *dx, int *incx);
  int dcopy_(int *n, double *dx, int *incx, double *dy, int *incy);
}

// only 200 values of chisquared x^2 values are added with degree of freedom
static double chisquaredvalue[200] = {3.84146, 5.99146, 7.81473, 9.48773, 11.0705, 12.5916, 14.0671, 15.5073, 16.919, 18.307, 19.6751, 21.0261, 22.362, 23.6848, 24.9958, 26.2962, 27.5871, 28.8693, 30.1435, 31.4104, 32.6706, 33.9244, 35.1725, 36.415, 37.6525, 38.8851, 40.1133, 41.3371, 42.557, 43.773, 44.9853, 46.1943, 47.3999, 48.6024, 49.8018, 50.9985, 52.1923, 53.3835, 54.5722, 55.7585, 56.9424, 58.124, 59.3035, 60.4809, 61.6562, 62.8296, 64.0011, 65.1708, 66.3386, 67.5048, 68.6693, 69.8322, 70.9935, 72.1532, 73.3115, 74.4683, 75.6237, 76.7778, 77.9305, 79.0819, 80.2321, 81.381, 82.5287, 83.6753, 84.8206, 85.9649, 87.1081, 88.2502, 89.3912, 90.5312, 91.6702, 92.8083, 93.9453, 95.0815, 96.2167, 97.351, 98.4844, 99.6169, 100.749, 101.879, 103.01, 104.139, 105.267, 106.395, 107.522, 108.648, 109.773, 110.898, 112.022, 113.145, 114.268, 115.39, 116.511, 117.632, 118.752, 119.871, 120.99, 122.108, 123.225, 124.342, 125.458, 126.574, 127.689, 128.804, 129.918, 131.031, 132.144, 133.257, 134.369, 135.48, 136.591, 137.701, 138.811, 139.921, 141.03, 142.138, 143.246, 144.354, 145.461, 146.567, 147.674, 148.779, 149.885, 150.989, 152.094, 153.198, 154.302, 155.405, 156.508, 157.61, 158.712, 159.814, 160.915, 162.016, 163.116, 164.216, 165.316, 166.415, 167.514, 168.613, 169.711, 170.809, 171.907, 173.004, 174.101, 175.198, 176.294, 177.39, 178.485, 179.581, 180.676, 181.77, 182.865, 183.959, 185.052, 186.146, 187.239, 188.332, 189.424, 190.516, 191.608, 192.7, 193.791, 194.883, 195.973, 197.064, 198.154, 199.244, 200.334, 201.423, 202.513, 203.602, 204.69, 205.779, 206.867, 207.955, 209.042, 210.13, 211.217, 212.304, 213.391, 214.477, 215.563, 216.649, 217.735, 218.82, 219.906, 220.991, 222.076, 223.16, 224.245, 225.329, 226.413, 227.496, 228.58, 229.663, 230.746, 231.829, 232.912};

struct csvData
{
  int linecount;
  int rowcount;
  int columncount;
  vector<double> xdata;
  vector<double> sxdata;
  vector<string> headers;
  vector< vector<string> > rx;
};

struct correlationData
{
  vector<double> data;
  vector<string> rowHeaders;
  vector<string> columnHeaders;
};

struct correlationDataWarning
{
  vector<string> diagonalEntry;
  vector<string> aboveDiagonalEntry;
};

struct matrixData
{
  int rows;
  int column;
  double * data;
};

struct inputData
{
  int rows;
  int column;
  double * data;
  vector<int> index;
};

struct errorData
{
  string name;
  string x;
  string sx;
};

void copyReferenceFile(DATA * data, const std::string & filename)
{
  std::string outputPath = std::string(omc_flagValue[FLAG_OUTPUT_PATH]) + "/" + std::string(data->modelData->modelFilePrefix) + filename;
  std::string referenceFile = string(data->modelData->modelFilePrefix) + filename; // current directory

  ifstream ifstreamfile;
  ifstreamfile.open(referenceFile);

  if (ifstreamfile.good())
  {
    ofstream ofstreamfile;
    ofstreamfile.open(outputPath);
    ofstreamfile << ifstreamfile.rdbuf();
    ofstreamfile.close();
    ifstreamfile.close();
  }
}

int getRealtedBoundaryConditions(DATA * data)
{
  // check for _relatedBoundaryConditionsEquations.txt file exists to map the nonReconciled Vars failing with condition-2 of extraction algorithm
  std::string relatedBoundaryConditionsFilename = string(data->modelData->modelFilePrefix) +  "_relatedBoundaryConditionsEquations.txt";

  if (omc_flag[FLAG_OUTPUT_PATH])
  {
    relatedBoundaryConditionsFilename = string(omc_flagValue[FLAG_OUTPUT_PATH]) + "/" + relatedBoundaryConditionsFilename;
    copyReferenceFile(data, "_relatedBoundaryConditionsEquations.txt");
  }

  ifstream relatedBoundaryConditionsFilenameip(relatedBoundaryConditionsFilename);
  string line;
  int count = 0;
  if (relatedBoundaryConditionsFilenameip.good())
  {
    while (relatedBoundaryConditionsFilenameip.good())
    {
      getline(relatedBoundaryConditionsFilenameip, line);
      if (!line.empty())
      {
        count = count + 1;
      }
    }
    relatedBoundaryConditionsFilenameip.close();
    //omc_unlink(relatedBoundaryConditionsFilename.c_str());
  }
  return count;
}

/*
 * create html report with error logs for D.1
 */
void createErrorHtmlReport(DATA * data, int status = 0)
{
  // create HTML Report with Error Logs
  ofstream myfile;
  time_t now = time(0);
  std::stringstream htmlfile;
  if (omc_flag[FLAG_OUTPUT_PATH])
  {
    htmlfile << string(omc_flagValue[FLAG_OUTPUT_PATH]) << "/" << data->modelData->modelName << ".html";
  }
  else
  {
    htmlfile << data->modelData->modelName << ".html";
  }
  string html = htmlfile.str();
  myfile.open(html.c_str());

  /* Add Overview Data */
  myfile << "<!DOCTYPE html><html>\n <head> <h1> Data Reconciliation Report</h1></head> \n <body> \n ";
  myfile << "<h2> Overview: </h2>\n";
  myfile << "<table> \n";
  myfile << "<tr> \n" << "<th align=right> Model file: </th> \n" << "<td>" << data->modelData->modelFilePrefix << ".mo" << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Model name: </th> \n" << "<td>" << data->modelData->modelName << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Model directory: </th> \n" << "<td>" << data->modelData->modelDir << "</td> </tr>\n";
  if (omc_flagValue[FLAG_DATA_RECONCILE_Sx])
  {
    myfile << "<tr> \n" << "<th align=right> Measurement input file: </th> \n" << "<td>" << omc_flagValue[FLAG_DATA_RECONCILE_Sx] << "</td> </tr>\n";
  }
  else
  {
    myfile << "<tr> \n" << "<th align=right> Measurement input file: </th> \n" << "<td style=color:red>" << "no file provided" << "</td> </tr>\n";
  }
  myfile << "<tr> \n" << "<th align=right> Correlation matrix input file: </th> \n" << "<td>" << "no file provided" << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Generated: </th> \n" << "<td>" << ctime(&now) << " by "<< "<b>" << CONFIG_VERSION << "</b>" << "</td> </tr>\n";
  myfile << "</table>\n";

  /* add analysis section */
  myfile << "<h2> Analysis: </h2>\n";
  myfile << "<table> \n";
  myfile << "<tr> \n" << "<th align=right> Number of auxiliary conditions: </th> \n" << "<td>" << data->modelData->nSetcVars << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Number of variables to be reconciled: </th> \n" << "<td>" << data->modelData->ndataReconVars << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Number of related boundary conditions: </th> \n" << "<td>" << getRealtedBoundaryConditions(data) << "</td> </tr>\n";
  myfile << "</table> \n";

  // Auxiliary Conditions
  myfile << "<h3> <a href=" << data->modelData->modelFilePrefix << "_AuxiliaryConditions.html" << " target=_blank> Auxiliary conditions </a> </h3>\n";
  // Intermediate Conditions
  myfile << "<h3> <a href=" << data->modelData->modelFilePrefix << "_IntermediateEquations.html" << " target=_blank> Intermediate equations </a> </h3>\n";

  // Error log
  myfile << "<h2> <a href=" << data->modelData->modelFilePrefix << ".log" << " target=_blank> Errors </a> </h2>\n";
  // copy the error log to output path
  if (omc_flag[FLAG_OUTPUT_PATH])
  {
    copyReferenceFile(data, ".log");
  }

  // debug log
  if (status == 0)
  {
    myfile << "<h2> <a href=" << data->modelData->modelName << "_debug.txt" << " target=_blank> Debug log </a> </h2>\n";
  }

  myfile << "</table>\n";
  myfile << "</body>\n</html>";
  myfile.flush();
  myfile.close();
}

/*
* create html report for data Reconciliation D.1
*/
void createHtmlReportFordataReconciliation(DATA *data, csvData &csvinputs, matrixData &xdiag, matrixData &reconciled_X, matrixData &copyreconSx_diag, double *newX, double &eps, int &iterationcount, double &value, correlationDataWarning &warningCorrelationData)
{
  ofstream myfile;
  time_t now = time(0);
  std::stringstream htmlfile;
  if (omc_flag[FLAG_OUTPUT_PATH])
  {
    htmlfile << string(omc_flagValue[FLAG_OUTPUT_PATH]) << "/" << data->modelData->modelName << ".html";
  }
  else
  {
    htmlfile << data->modelData->modelName << ".html";
  }
  string html = htmlfile.str();
  myfile.open(html.c_str());

  /* create a csv file */
  ofstream csvfile;
  std::stringstream csv_file;
  if (omc_flag[FLAG_OUTPUT_PATH])
  {
    csv_file << string(omc_flagValue[FLAG_OUTPUT_PATH]) << "/" << data->modelData->modelName << "_Outputs.csv";
  }
  else
  {
    csv_file << data->modelData->modelName << "_Outputs.csv";
  }

  string tmpcsv = csv_file.str();
  csvfile.open(tmpcsv.c_str());

  // check for nonReconciledVars.txt file exists to map the nonReconciled Vars failing with condition-2 of extraction algorithm
  std::string nonReconciledVarsFilename = string(data->modelData->modelFilePrefix) +  "_NonReconcilcedVars.txt";
  vector<std::string> nonReconciledVars;

  if (omc_flag[FLAG_OUTPUT_PATH])
  {
    nonReconciledVarsFilename = string(omc_flagValue[FLAG_OUTPUT_PATH]) + "/" + nonReconciledVarsFilename;
    copyReferenceFile(data, "_NonReconcilcedVars.txt");
  }

  ifstream nonreconcilevarsip(nonReconciledVarsFilename);
  string line;
  if (nonreconcilevarsip.good())
  {
    while (nonreconcilevarsip.good())
    {
      getline(nonreconcilevarsip, line);
      if (!line.empty())
      {
        //std::cout << "\n reading nonVariables of interest : " << line;
        nonReconciledVars.push_back(line);
      }
    }
    nonreconcilevarsip.close();
    omc_unlink(nonReconciledVarsFilename.c_str());
  }

  /* Add Overview Data */
  myfile << "<!DOCTYPE html><html>\n <head> <h1> Data Reconciliation Report</h1></head> \n <body> \n ";
  myfile << "<h2> Overview: </h2>\n";
  myfile << "<table> \n";
  myfile << "<tr> \n" << "<th align=right> Model file: </th> \n" << "<td>" << data->modelData->modelFilePrefix << ".mo" << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Model name: </th> \n" << "<td>" << data->modelData->modelName << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Model directory: </th> \n" << "<td>" << data->modelData->modelDir << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Measurement input file: </th> \n" << "<td>" << omc_flagValue[FLAG_DATA_RECONCILE_Sx] << "</td> </tr>\n";
  if (omc_flagValue[FLAG_DATA_RECONCILE_Cx])
  {
    myfile << "<tr> \n" << "<th align=right> Correlation matrix input file: </th> \n" << "<td>" << omc_flagValue[FLAG_DATA_RECONCILE_Cx] << "</td> </tr>\n";
  }
  else
  {
    myfile << "<tr> \n" << "<th align=right> Correlation matrix input file: </th> \n" << "<td>" << "no file provided" << "</td> </tr>\n";
  }
  myfile << "<tr> \n" << "<th align=right> Generated: </th> \n" << "<td>" << ctime(&now) << " by "<< "<b>" << CONFIG_VERSION << "</b>" << "</td> </tr>\n";
  myfile << "</table>\n";

  /* Add Analysis data */
  myfile << "<h2> Analysis: </h2>\n";
  myfile << "<table> \n";
  myfile << "<tr> \n" << "<th align=right> Number of auxiliary conditions: </th> \n" << "<td>" << data->modelData->nSetcVars << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Number of variables to be reconciled: </th> \n" << "<td>" << data->modelData->ndataReconVars << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Number of related boundary conditions: </th> \n" << "<td>" << getRealtedBoundaryConditions(data) << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Number of iterations to convergence: </th> \n" << "<td>" << iterationcount << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Final value of (J*/r) : </th> \n" << "<td>" << value << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Epsilon : </th> \n" << "<td>" << eps << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Final value of the objective function (J*) : </th> \n" << "<td>" << (value*data->modelData->nSetcVars) << "</td> </tr>\n";
  //myfile << "<tr> \n" << "<th align=right> Chi-square value : </th> \n" << "<td>" << quantile(complement(chi_squared(data->modelData->nSetcVars), 0.05)) << "</td> </tr>\n";

  if (data->modelData->nSetcVars > 200)
  {
    myfile << "<tr> \n" << "<th align=right> Chi-square value : </th> \n" << "<td>" << "NOT Available for equations > 200 in setC" << "</td> </tr>\n";
  }
  else
  {
    myfile << "<tr> \n" << "<th align=right> Chi-square value : </th> \n" << "<td>" << chisquaredvalue[data->modelData->nSetcVars - 1] << "</td> </tr>\n";
  }
  myfile << "<tr> \n" << "<th align=right> Result of global test : </th> \n" << "<td>" << "TRUE" << "</td> </tr>\n";
  myfile << "</table>\n";

  // Auxiliary Conditions
  myfile << "<h3> <a href=" << data->modelData->modelFilePrefix << "_AuxiliaryConditions.html" << " target=_blank> Auxiliary conditions </a> </h3>\n";

  // Intermediate Conditions
  myfile << "<h3> <a href=" << data->modelData->modelFilePrefix << "_IntermediateEquations.html" << " target=_blank> Intermediate equations </a> </h3>\n";

  // Debug log
  myfile << "<h3> <a href=" << data->modelData->modelName << "_debug.txt" << " target=_blank> Debug log </a> </h3>\n";

  // create a warning log for correlation input file
  if (!warningCorrelationData.aboveDiagonalEntry.empty() || !warningCorrelationData.diagonalEntry.empty())
  {
    myfile << "<h3> <a href=" << data->modelData->modelName << "_warning.txt" << " target=_blank> Warnings </a> </h3>\n";
    /* create a warning log file */
    ofstream warningfile;
    std::stringstream warning_file;
    if (omc_flag[FLAG_OUTPUT_PATH])
    {
      warning_file << string(omc_flagValue[FLAG_OUTPUT_PATH]) << "/" << data->modelData->modelName << "_warning.txt";
    }
    else
    {
      warning_file << data->modelData->modelName << "_warning.txt";
    }

    warningfile.open(warning_file.str().c_str());
    // user warning #1 : Diagonal entry for variable of interest <variable name> in correlation input file <input file name> is ignored
    for (const auto &index : warningCorrelationData.diagonalEntry)
    {
      warningfile << "|  warning  |   " << "Diagonal entry for variable of interest " << index << " in correlation input file " << omc_flagValue[FLAG_DATA_RECONCILE_Cx] << " is ignored" << "\n";
    }
    // user warning #2 : Above diagonal entry for variable of interest <variable name> in correlation input file <input file name> is ignored
    for (const auto &index : warningCorrelationData.aboveDiagonalEntry)
    {
      warningfile << "|  warning  |   " << "Above diagonal entry for variable of interest " << index << " in correlation input file " << omc_flagValue[FLAG_DATA_RECONCILE_Cx] << " is ignored" << "\n";
    }
    warningfile.close();
  }

  /* Add Results data */
  myfile << "<h2> Results: </h2>\n";
  myfile << "<table border=2>\n";
  myfile << "<tr>\n" << "<th> Variables to be Reconciled </th>\n" << "<th> Initial Measured Values </th>\n" << "<th> Reconciled Values </th>\n" << "<th> Initial Half-width Confidence Intervals </th>\n" <<"<th> Reconciled Half-width Confidence Intervals </th>\n";
  csvfile << "Variables to be Reconciled ," << "Initial Measured Values ," << "Reconciled Values ," << "Initial Half-width Confidence Intervals ," << "Reconciled Half-width Confidence Intervals,";
  myfile << "<th> Results of Local Tests </th>\n" << "<th> Values of Local Tests </th>\n" << "<th> Margin to Correctness(distance from 1.96) </th>\n" << "</tr>\n";
  csvfile << "Results of Local Tests ," << "Values of Local Tests ," << "Margin to Correctness(distance from 1.96) ," << "\n";

  for (unsigned int r = 0; r < csvinputs.headers.size(); r++)
  {
    bool reconciled = true;
    if (!nonReconciledVars.empty())
    {
      auto nonReconciledVar = std::find(nonReconciledVars.begin(), nonReconciledVars.end(), csvinputs.headers[r]);
      if (nonReconciledVar != nonReconciledVars.end())
      {
        reconciled = false;
      }
    }

    if (reconciled)
    {
      myfile << "<tr>\n";
      // variables of interest
      myfile << "<td>" << csvinputs.headers[r] << "</td>\n";
      csvfile << csvinputs.headers[r] << ",";

      // Initial Measured Values
      myfile << "<td>" << xdiag.data[r] << "</td>\n";
      csvfile << xdiag.data[r] << ",";

      // Reconciled Values
      myfile << "<td>" << reconciled_X.data[r] << "</td>\n";
      csvfile << reconciled_X.data[r] << ",";

      // Initial Uncertainty Values
      myfile << "<td>" << csvinputs.sxdata[r] << "</td>\n";
      csvfile << csvinputs.sxdata[r] << ",";

      // Reconciled Uncertainty Values
      myfile << "<td>" << copyreconSx_diag.data[r] << "</td>\n";
      csvfile << copyreconSx_diag.data[r] << ",";

      // Results of Local Tests
      if (newX[r] < 1.96)
      {
        myfile << "<td>" << "TRUE" << "</td>\n";
        csvfile << "TRUE" << ",";
      }
      else
      {
        myfile << "<td>" << "FALSE" << "</td>\n";
        csvfile << "FALSE" << ",";
      }

      // Values of Local Tests
      myfile << "<td>" << newX[r] << "</td>\n";
      csvfile << newX[r] << ",";

      // Margin to Correctness(distance from 1.96)
      myfile << "<td>" << (1.96 - newX[r]) << "</td>\n";
      csvfile << (1.96 - newX[r]) << ",\n";
    }
    else
    {
      myfile << "<tr>\n";
      // variables of interest
      myfile << "<td>" << csvinputs.headers[r] << "</td>\n";
      csvfile << csvinputs.headers[r] << ",";

      // Initial Measured Values
      myfile << "<td>" << xdiag.data[r] << "</td>\n";
      csvfile << xdiag.data[r] << ",";

      // Reconciled Values
      myfile << "<td style=color:red>" << "Not reconciled" << "</td>\n";
      csvfile << "Not reconciled" << ",";

      // Initial Uncertainty Values
      myfile << "<td>" << csvinputs.sxdata[r] << "</td>\n";
      csvfile << csvinputs.sxdata[r] << ",";

      // Reconciled Uncertainty Values
      myfile << "<td style=color:red>" << "Not reconciled" << "</td>\n";
      csvfile << "Not reconciled" << ",";

      // Results of Local Tests
      myfile << "<td style=color:red>" << "Not reconciled" << "</td>\n";
      csvfile << "Not reconciled" << ",";

      // Values of Local Tests
      myfile << "<td style=color:red>" << "Not reconciled" << "</td>\n";
      csvfile << "Not reconciled" << ",";

      // Margin to Correctness(distance from 1.96)
      myfile << "<td style=color:red>" << "Not reconciled" << "</td>\n";
      csvfile << "Not reconciled" << ",\n";
    }
    csvfile.flush();
    myfile << "</tr>\n";
    myfile.flush();
  }

  csvfile.close();
  myfile << "</table>\n";
  myfile << "</body>\n</html>";
  myfile.close();
}

/*
 * create html report with error logs for Boundary conditions D.2
 */
void createErrorHtmlReportForBoundaryConditions(DATA * data, int status = 0)
{
  // create HTML Report with Error Logs
  ofstream myfile;
  time_t now = time(0);
  std::stringstream htmlfile;
  if (omc_flag[FLAG_OUTPUT_PATH])
  {
    htmlfile << string(omc_flagValue[FLAG_OUTPUT_PATH]) << "/" << data->modelData->modelName << "_BoundaryConditions.html";
  }
  else
  {
    htmlfile << data->modelData->modelName << "_BoundaryConditions.html";
  }
  string html = htmlfile.str();
  myfile.open(html.c_str());

  /* Add Overview Data */
  myfile << "<!DOCTYPE html><html>\n <head> <h1> Boundary Conditions Report </h1></head> \n <body> \n ";
  myfile << "<h2> Overview: </h2>\n";
  myfile << "<table> \n";
  myfile << "<tr> \n" << "<th align=right> Model file: </th> \n" << "<td>" << data->modelData->modelFilePrefix << ".mo" << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Model name: </th> \n" << "<td>" << data->modelData->modelName << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Model directory: </th> \n" << "<td>" << data->modelData->modelDir << "</td> </tr>\n";
  // Sx input file
  if (omc_flagValue[FLAG_DATA_RECONCILE_Sx])
  {
    myfile << "<tr> \n" << "<th align=right> Reconciled values input file: </th> \n" << "<td>" << omc_flagValue[FLAG_DATA_RECONCILE_Sx] << "</td> </tr>\n";
  }
  else
  {
    myfile << "<tr> \n" << "<th align=right> Reconciled values input file: </th> \n" << "<td style=color:red>" << "no file provided" << "</td> </tr>\n";
  }
  // Cx input file
  if (omc_flagValue[FLAG_DATA_RECONCILE_Cx])
  {
    myfile << "<tr> \n" << "<th align=right> Reconciled covariance matrix input file: </th> \n" << "<td>" << omc_flagValue[FLAG_DATA_RECONCILE_Cx] << "</td> </tr>\n";
  }
  else
  {
    myfile << "<tr> \n" << "<th align=right> Reconciled covariance matrix input file: </th> \n" << "<td style=color:red>" << "no file provided" << "</td> </tr>\n";
  }
  myfile << "<tr> \n" << "<th align=right> Generated: </th> \n" << "<td>" << ctime(&now) << " by "<< "<b>" << CONFIG_VERSION << "</b>" << "</td> </tr>\n";
  myfile << "</table>\n";

  /* add analysis section */
  myfile << "<h2> Analysis: </h2>\n";
  myfile << "<table> \n";
  myfile << "<tr> \n" << "<th align=right> Number of boundary conditions: </th> \n" << "<td>" << data->modelData->nSetcVars << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Number of variables to be reconciled: </th> \n" << "<td>" << data->modelData->ndataReconVars << "</td> </tr>\n";
  myfile << "</table> \n";

  // Boundary Conditions
  myfile << "<h3> <a href=" << data->modelData->modelFilePrefix << "_BoundaryConditionsEquations.html" << " target=_blank> Boundary conditions </a> </h3>\n";
  // Intermediate Conditions
  myfile << "<h3> <a href=" << data->modelData->modelFilePrefix << "_BoundaryConditionIntermediateEquations.html" << " target=_blank> Intermediate equations </a> </h3>\n";

  // Error log
  myfile << "<h2> <a href=" << data->modelData->modelFilePrefix << ".log" << " target=_blank> Errors </a> </h2>\n";
  // copy the error log to output path
  if (omc_flag[FLAG_OUTPUT_PATH])
  {
    copyReferenceFile(data, ".log");
  }

  // debug log
  if (status == 0)
  {
    myfile << "<h2> <a href=" << data->modelData->modelName << "_BoundaryConditions_debug.txt" << " target=_blank> Debug log </a> </h2>\n";
  }

  myfile << "</table>\n";
  myfile << "</body>\n</html>";
  myfile.flush();
  myfile.close();
}

/*
 * create HTML Report for Boundary Conditions D.2
 */
void createHtmlReportForBoundaryConditions(DATA * data, std::vector<std::string> & boundaryConditionVars, double* values, double* uncertaintyValues)
{
  ofstream myfile;
  time_t now = time(0);
  std::stringstream htmlfile;
  if (omc_flag[FLAG_OUTPUT_PATH])
  {
    htmlfile << string(omc_flagValue[FLAG_OUTPUT_PATH]) << "/" << data->modelData->modelName << "_BoundaryConditions.html";
  }
  else
  {
    htmlfile << data->modelData->modelName << "_BoundaryConditions.html";
  }
  string html = htmlfile.str();
  myfile.open(html.c_str());

  /* create a csv file */
  ofstream csvfile;
  std::stringstream csv_file;
  if (omc_flag[FLAG_OUTPUT_PATH])
  {
    csv_file << string(omc_flagValue[FLAG_OUTPUT_PATH]) << "/" << data->modelData->modelName << "_BoundaryConditions_Outputs.csv";
  }
  else
  {
    csv_file << data->modelData->modelName << "_BoundaryConditions_Outputs.csv";
  }

  string tmpcsv = csv_file.str();
  csvfile.open(tmpcsv.c_str());

  /* Add Overview Data */
  myfile << "<!DOCTYPE html><html>\n <head> <h1> Boundary Conditions Report </h1></head> \n <body> \n ";
  myfile << "<h2> Overview: </h2>\n";
  myfile << "<table> \n";
  myfile << "<tr> \n" << "<th align=right> Model file: </th> \n" << "<td>" << data->modelData->modelFilePrefix << ".mo" << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Model name: </th> \n" << "<td>" << data->modelData->modelName << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Model directory: </th> \n" << "<td>" << data->modelData->modelDir << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Reconciled values input file: </th> \n" << "<td>" << omc_flagValue[FLAG_DATA_RECONCILE_Sx] << "</td> </tr>\n";
  if (omc_flagValue[FLAG_DATA_RECONCILE_Cx])
  {
    myfile << "<tr> \n" << "<th align=right> Reconciled covariance matrix input file: </th> \n" << "<td>" << omc_flagValue[FLAG_DATA_RECONCILE_Cx] << "</td> </tr>\n";
  }
  else
  {
    myfile << "<tr> \n" << "<th align=right> Correlation matrix input file: </th> \n" << "<td>" << "no file provided" << "</td> </tr>\n";
  }
  myfile << "<tr> \n" << "<th align=right> Generated: </th> \n" << "<td>" << ctime(&now) << " by "<< "<b>" << CONFIG_VERSION << "</b>" << "</td> </tr>\n";
  myfile << "</table>\n";

  /* Add Analysis data */
  myfile << "<h2> Analysis: </h2>\n";
  myfile << "<table> \n";
  myfile << "<tr> \n" << "<th align=right> Number of boundary conditions: </th> \n" << "<td>" << data->modelData->nSetcVars << "</td> </tr>\n";
  myfile << "<tr> \n" << "<th align=right> Number of variables to be reconciled: </th> \n" << "<td>" << data->modelData->ndataReconVars << "</td> </tr>\n";
  myfile << "</table>\n";

  // Boundary Conditions
  myfile << "<h3> <a href=" << data->modelData->modelFilePrefix << "_BoundaryConditionsEquations.html" << " target=_blank> Boundary conditions </a> </h3>\n";

  // Intermediate Conditions
  myfile << "<h3> <a href=" << data->modelData->modelFilePrefix << "_BoundaryConditionIntermediateEquations.html" << " target=_blank> Intermediate equations </a> </h3>\n";

  // Debug log
  myfile << "<h3> <a href=" << data->modelData->modelName << "_BoundaryConditions_debug.txt" << " target=_blank> Debug log </a> </h3>\n";

  /* Add Results data */
  myfile << "<h2> Results: </h2>\n";
  myfile << "<table border=2>\n";
  myfile << "<tr>\n" << "<th> Boundary conditions </th>\n" << "<th> Values </th>\n" << "<th> Reconciled Half-width Confidence Intervals </th> </tr>\n";
  csvfile << "Boundary conditions ," << "Values ," << "Reconciled Half-width Confidence Intervals," << "\n";

  for (unsigned int r = 0; r < boundaryConditionVars.size(); r++)
  {
    myfile << "<tr>\n";
    // Boundary Conditions
    myfile << "<td>" << boundaryConditionVars[r] << "</td>\n";
    csvfile << boundaryConditionVars[r] << ",";

    // simulation Values
    myfile << "<td>" << values[r] << "</td>\n";
    csvfile << values[r] << ",";

    // uncertainty Values
    myfile << "<td>" << uncertaintyValues[r] << "</td>\n";
    myfile << "</tr>\n";
    csvfile << uncertaintyValues[r] << "," << "\n";
  }

  myfile << "</table>\n</html>";
  myfile.close();
  csvfile.close();
}

/*
 * function which returns the index pos
 * of input variables
 */
int getVariableIndex(vector<string> headers, string name, ofstream & logfile, DATA * data)
{
  int pos = -1;
  for (unsigned int i = 0; i < headers.size(); i++)
  {
    //logfile << "founded headers " << headers[i] << i << "\n";
    if (strcmp(headers[i].c_str(), name.c_str()) == 0)
    {
      pos = i;
      break;
    }
  }
  //logfile << "founded pos " << name << ": " << pos << "\n";
  if (pos == -1)
  {
    //logfile << "Variable Name not Matched :" << name;
    logfile << "|  error   |   " << "CoRelation-Coefficient Variable Name not Matched:  " << name << " ,getVariableIndex() failed!" << "\n";
    logfile.close();
    exit(1);
    createErrorHtmlReport(data);
  }
  return pos;
}

/*
 * check string is a valid double
 */
bool isStringValidDouble(std::string &cref)
{
  return std::regex_match(cref, std::regex("[-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?"));
}

/*
 * check string is a empty, (i.e) contains only "," in csv input
 * also ignore lines starting with c comments //
 */
bool isLineEmptyData(std::string &cref)
{
  return std::regex_match(cref, std::regex("^[,|/]+.*"));
}

/*
 * Function which reads the csv file
 * and stores the initial measured value X and HalfWidth confidence
 * interval Wx and also the input variable names
 */
csvData readMeasurementInputFile(ofstream & logfile, DATA * data, bool boundaryConditions = false)
{
  char * filename = NULL;
  filename = (char*) omc_flagValue[FLAG_DATA_RECONCILE_Sx];

  if (filename == NULL && !boundaryConditions)
  {
    errorStreamPrint(LOG_STDOUT, 0, "Measurement input file not provided (eg:-sx=filename.csv), DataReconciliation cannot be computed!.");
    logfile << "|  error   |   " << "Measurement input file not provided (eg:-sx=filename.csv), DataReconciliation cannot be computed!.\n";
    logfile.close();
    createErrorHtmlReport(data);
    exit(1);
  }

  if (filename == NULL && boundaryConditions)
  {
    errorStreamPrint(LOG_STDOUT, 0, "Reconciled values input file not provided (eg:-sx=filename.csv), Boundary conditions cannot be computed!.");
    logfile << "|  error   |   " << "Reconciled values input file not provided (eg:-sx=filename.csv), Boundary conditions cannot be computed!.\n";
    logfile.close();
    createErrorHtmlReportForBoundaryConditions(data);
    exit(1);
  }

  ifstream ip(filename);
  string line;
  vector<double> xdata;
  vector<double> sxdata;
  vector<string> names;
  //vector<double> rx_ik;
  vector< vector<string> > rx;
  int Sxrowcount = 0;
  int linecount = 1;
  int Sxcolscount = 0;
  bool flag = false;
  vector<errorData> errorInfo;
  vector<int> errorInfoHeaders;

  if (!ip.good() && !boundaryConditions)
  {
    errorStreamPrint(LOG_STDOUT, 0, "Measurement input file path not found %s.",filename);
    logfile << "|  error   |   " << "Measurement input file path not found " << filename << "\n";
    logfile.close();
    createErrorHtmlReport(data);
    exit(1);
  }

  if (!ip.good() && boundaryConditions)
  {
    errorStreamPrint(LOG_STDOUT, 0, "Reconciled values input file path not found %s.", filename);
    logfile << "|  error   |   " << "Reconciled values input file path not found " << filename << "\n";
    logfile.close();
    createErrorHtmlReportForBoundaryConditions(data);
    exit(1);
  }

  while (ip.good())
  {
    getline(ip, line);
    vector<string> t1;

    // allow comments on the line#1 until finding the headers
    if (linecount == 1 && isLineEmptyData(line))
    {
      continue;
    }

    if (linecount > 1 && !line.empty() && !isLineEmptyData(line))
    {
      //std::cout << "\nline info:" << line;
      std::replace(line.begin(), line.end(), ';', ',');
      // remove whitespace in a string
      line.erase(std::remove_if(line.begin(), line.end(), ::isspace), line.end());

      stringstream ss(line);
      string temp;
      int columnCount = 0;
      bool col0 = false, col1 = false, col2 = false;
      while (getline(ss, temp, ','))
      {
        if (columnCount == 0)
        {
          // // error : no variable of interest is provided by user at column #1
          if (temp.empty())
          {
            errorInfoHeaders.push_back(linecount);
          }
          col0 = true;
          names.push_back(temp.c_str());
          Sxrowcount++;
          if (flag == false)
          {
            Sxcolscount++;
          }
        }
        if (columnCount == 1 && !temp.empty() && isStringValidDouble(temp))
        {
          //std::cout << "\n x: " << temp << " type : "<< isStringValidDouble(temp);
          //logfile << "xdata" << temp << " double" << atof(temp.c_str()) <<"\n";
          col1 = true;
          xdata.push_back(atof(temp.c_str()));
          if (flag == false)
          {
            Sxcolscount++;
          }
        }
        if (columnCount == 2 && !temp.empty() && isStringValidDouble(temp))
        {
          //std::cout << "\n sxdata: " << temp << " valid type " << isStringValidDouble(temp);
          //logfile << "sxdata" << temp << " double" << atof(temp.c_str()) <<"\n";
          col2 = true;
          sxdata.push_back(atof(temp.c_str()));
          if (flag == false)
          {
            Sxcolscount++;
          }
        }
        // ignore columns greater than 3
        if (columnCount > 2)
        {
          break;
        }
        columnCount++;
      }
      flag = true;

      if (!col0 || !col1 || !col2)
      {
        std::string column1 = "(no-Value/wrong-Type)", column2 = "(no-Value/wrong-Type)", column3 = "(no-Value/wrong-Type)";
        if (col0)
        {
          column1 = names.back();
        }
        if (col1)
        {
          column2 = std::to_string(xdata.back());
        }
        if (col2)
        {
          column3 = std::to_string(sxdata.back());
        }
        errorData info = {column1, column2, column3};
        errorInfo.push_back(info);
      }
    }
    linecount++;
  }

// user error : variable of interest is missing in column #1
  if (!errorInfoHeaders.empty())
  {
    for (const auto &line : errorInfoHeaders)
    {
      errorStreamPrint(LOG_STDOUT, 0, "the name of the variable of interest in measurement input file  %s is missing in line #%d ", filename, line);
      logfile << "|  error   |   " << "the name of the variable of interest in measurement input file " << filename << " is missing in line #" << line << "\n";
    }
    logfile.close();
    createErrorHtmlReport(data);
    exit(1);
  }

  // user error #6: Entry for variable of interest <variable name> in measurement input file <input file name> is incorrect: <reason (no value or incorrect value type)>
  if (!errorInfo.empty())
  {
    for (const auto & info : errorInfo)
    {
      errorStreamPrint(LOG_STDOUT, 0, "Entry for variable of interest %s in measurement input file %s is incorrect because of (no-Value/wrong-Type), with following data: [%s, %s, %s] ", info.name.c_str(), filename, info.name.c_str(), info.x.c_str(), info.sx.c_str());
      logfile << "|  error   |   " << "Entry for variable of interest " <<  info.name << " in measurement input file " << filename << " is incorrect because of (no-Value/wrong-Type), with following data: " << "[" << info.name << ", " << info.x << ", " << info.sx  << "]" <<"\n";
    }
    logfile.close();
    createErrorHtmlReport(data);
    exit(1);
  }

  //logfile << "csvdata header:" << "header length: " << names.size() << "   " << names[0] << names[1] << names[2] << "" << "\n";
  //logfile << "linecount:" << linecount << " " << "rowcount :" << Sxrowcount << " " << "colscount:" << Sxcolscount << "\n";

  csvData csvData = {linecount, Sxrowcount, Sxcolscount, xdata, sxdata, names, rx};
  return csvData;
}

/*
 * Function which arranges the elements in column major
 */
void initColumnMatrix(vector<double> data, int rows, int cols, double * tempSx)
{
  for (int i = 0; i < rows; i++)
  {
    for (int j = 0; j < cols; j++)
    {
      // store the matrix in column order
      tempSx[j + i * rows] = data[i + j * rows];
    }
  }
}

/*
 * Function to print and debug whether the matrices are stored in column major
 */
void printColumnAlginment(double * matrix, int rows, int cols, string name)
{
  cout << "\n" << "************ " << name << " **********" << "\n";
  for (int i = 0; i < rows * cols; i++)
  {
    cout << matrix[i] << " ";
  }
  cout << "\n";
}

/*
 * Function to Print the matrix in row based format
 */
void printMatrix(double * matrix, int rows, int cols, string name, ofstream & logfile)
{
  logfile << "\n" << "************ " << name << " **********" << "\n";
  for (int i = 0; i < rows; i++)
  {
    for (int j = 0; j < cols; j++)
    {
      //cout << setprecision(5);
      logfile << std::right << setw(15) << matrix[i + j * rows];
      logfile.flush();
    }
    logfile << "\n";
  }
  logfile << "\n";
}

/*
 * Function to Print the matrix in row based format
 */
void printMatrixModelicaFormat(double * matrix, int rows, int cols, string name, ofstream & logfile)
{
  logfile << "\n" << "************ " << name << " **********" << "\n";
  logfile << "\n[";
  for (int i = 0; i < rows; i++)
  {
    for (int j = 0; j < cols; j++)
    {
      //cout << setprecision(5);
      if (j == cols - 1)
      {
        logfile << std::right << setw(15) << matrix[i + j * rows] << ";\n";
      }
      else
      {
        logfile << std::right << setw(15) << matrix[i + j * rows] << ",";
      }

      logfile.flush();
    }
    //logfile << ";\n";
  }
  logfile << "\n";
}

/*
 *
 Function to Print the matrix in row based format with headers
 */
void printMatrixWithHeaders(double * matrix, int rows, int cols, vector<string> headers, string name, ofstream & logfile)
{
  logfile << "\n" << "************ " << name << " **********" << "\n";
  for (int i = 0; i < rows; i++)
  {
    logfile << std::right << setw(10) << headers[i];
    for (int j = 0; j < cols; j++)
    {
      //cout << setprecision(5);
      logfile << std::right << setw(15) << matrix[i + j * rows];
      logfile.flush();
      //printf("% .5e ", matrix[i+j*rows]);
    }
    logfile << "\n";
  }
  logfile << "\n";
}

/*
 *
 Function to Print the matrix in row based format with headers
 */
void printBoundaryConditionsResults(double * matrixA, double * matrixB, int rows, int cols, vector<string> headers, string name, ofstream & logfile)
{
  logfile << "\n" << "************ " << name << " **********" << "\n";
  logfile << "\n Boundary conditions" << setw(20) << "Values" << setw(45) << "Half-width Confidence Interval" << "\n";
  for (int i = 0; i < rows; i++)
  {
    logfile << std::right << setw(20) << headers[i];
    for (int j = 0; j < cols; j++)
    {
      //cout << setprecision(5);
      logfile << std::right << setw(20) << matrixA[i + j * rows] << setw(25) << matrixB[i + j * rows];
      logfile.flush();
      //printf("% .5e ", matrix[i+j*rows]);
    }
    logfile << "\n";
  }
  logfile << "\n";
}

void dumpReconciledSxToCSV(double * matrix, int rows, int cols, vector<string> headers, DATA * data)
{
  /* create a csv file */
  ofstream csvfile;
  std::stringstream csv_file;
  if (omc_flag[FLAG_OUTPUT_PATH])
  {
    csv_file << string(omc_flagValue[FLAG_OUTPUT_PATH]) << "/" << data->modelData->modelName << "_Reconciled_Sx.csv";
  }
  else
  {
    csv_file << data->modelData->modelName << "_Reconciled_Sx.csv";
  }

  string tmpcsv = csv_file.str();
  csvfile.open(tmpcsv.c_str());

  csvfile << "Sxij" << ",";
  for (auto it : headers)
  {
    //std::cout << "headers : " << it << "\n";
    csvfile << it << ",";
  }
  csvfile << "\n";

  for (int i = 0; i < rows; i++)
  {
    csvfile << headers[i] << ",";
    for (int j = 0; j < cols; j++)
    {
      //cout << setprecision(5);
      csvfile << matrix[i + j * rows] << ",";
      //csvfile.flush();
      //printf("% .5e ", matrix[i+j*rows]);
    }
    csvfile << "\n";
  }
  //csvfile << "\n";
  csvfile.flush();
  csvfile.close();
}

/*
 *Function to Print the vecomatrix in row based format with headers
 *based on vector arrays
 */
void printVectorMatrixWithHeaders(vector<double> matrix, int rows, int cols, vector<string> headers, string name, ofstream & logfile)
{
  logfile << "\n" << "************ " << name << " **********" << "\n";
  for (int i = 0; i < rows; i++)
  {
    logfile << std::right << setw(10) << headers[i];
    for (int j = 0; j < cols; j++)
    {
      //cout << setprecision(5);
      logfile << std::right << setw(15) << matrix[i + j * rows];
      logfile.flush();
      //printf("% .5e ", matrix[i+j*rows]);
    }
    logfile << "\n";
  }
  logfile << "\n";
}

/*
 Function to Print the corelation matrix in row based format with headers
 */
void printCorelationMatrix(vector<double> cx_data, vector<string> rowHeaders, vector<string> columnHeaders, string name, ofstream & logfile, correlationDataWarning & warningCorrelationData)
{
  if (cx_data.empty())
  {
    return;
  }

  logfile << "\n" << "************ " << name << " **********" << "\n";
  for (int i = 0; i < rowHeaders.size(); i++)
  {
    logfile << std::right << setw(10) << rowHeaders[i];
    for (int j = 0; j < columnHeaders.size(); j++)
    {
      if (i == j && cx_data[columnHeaders.size() * i + j] != 0)
      {
        warningCorrelationData.diagonalEntry.push_back(rowHeaders[i]);
      }
      else if (j > i && cx_data[columnHeaders.size() * i + j] != 0)
      {
        warningCorrelationData.aboveDiagonalEntry.push_back(rowHeaders[i]);
      }
      logfile << std::right << setw(15) << cx_data[columnHeaders.size() * i + j];
    }
    logfile << "\n";
  }
  logfile << "\n";
}

/*
 *
 Function Which gets the diagonal elements of the matrix
 */
void getDiagonalElements(double * matrix, int rows, int cols, double * result)
{
  int k = 0;
  for (int i = 0; i < rows; i++)
  {
    for (int j = 0; j < cols; j++)
    {
      if (i == j)
      {
        result[k++] = matrix[i + j * rows];
      }
    }
  }
}

/*
 * Function to transpose the Matrix
 */
void transposeMatrix(double * jacF, double * jacFT, int rows, int cols)
{
  for (int i = 0; i < rows; i++)
  {
    for (int j = 0; j < cols; j++)
    {
      // Perform matrix transpose store the elements in column major
      jacFT[i * cols + j] = jacF[i + j * rows];
    }
  }
}


/*
 * Matrix Multiplication using dgemm LaPack routine
 */
void solveMatrixMultiplication(double *matrixA, double *matrixB, int rowsa, int colsa, int rowsb, int colsb, double *matrixC, ofstream &logfile, DATA * data)
{
  char trans = 'N';
  double one = 1.0, zero = 0.0;
  int rowsA = rowsa;
  int colsA = colsa;
  int rowsB = rowsb;
  int colsB = colsb;
  int common = colsa;

  if (colsA != rowsB)
  {
    //cout << "\n Error: Column of First Matrix not equal to Rows  of Second Matrix \n ";
    errorStreamPrint(LOG_STDOUT, 0, "solveMatrixMultiplication() Failed!, Column of First Matrix not equal to Rows of Second Matrix %i != %i.",colsA,rowsB);
    logfile << "|  error   |   " << "solveMatrixMultiplication() Failed!, Column of First Matrix not equal to Rows of Second Matrix " << colsA << " != " << rowsB << "\n";
    logfile.close();
    createErrorHtmlReport(data);
    exit(1);
  }
  // solve matrix multiplication using dgemm_ LAPACK routine
  dgemm_(&trans, &trans, &rowsA, &colsB, &common, &one, matrixA, &rowsA, matrixB, &common, &zero, matrixC, &rowsA);
}

/*
 * Solve the Linear System A*x=b using LAPACK Solver routine dgesv_
 */
void solveSystemFstar(int n, int nhrs, double *tmpMatrixD, double *tmpMatrixC, ofstream &logfile, DATA * data)
{
  int N = n; // number of rows of Matrix A
  int NRHS = nhrs;  // number of columns of Matrix B
  int LDA = N;
  int LDB = N;
  int ipiv[N];
  int info;
  // call the external function
  dgesv_(&N, &NRHS, tmpMatrixD, &LDA, ipiv, tmpMatrixC, &LDB, &info);
  if (info > 0)
  {
    //cout << "The solution could not be computed, The info satus is : " << info;
    errorStreamPrint(LOG_STDOUT, 0, "solveSystemFstar() Failed !, The solution could not be computed, The info satus is %i ", info);
    logfile << "|  error   |   " << "solveSystemFstar() Failed !, The solution could not be computed, The info satus is " << info << "\n";
    logfile.close();
    createErrorHtmlReport(data);
    exit(1);
  }
}

/*
 * Solve the matrix Subtraction of two matrices
 */
void solveMatrixSubtraction(matrixData A, matrixData B, double *result, ofstream &logfile, DATA * data)
{
  if (A.rows != B.rows && A.column != B.column)
  {
    //cout << "The Matrix Dimensions are not equal to Compute ! \n";
    errorStreamPrint(LOG_STDOUT, 0, "solveMatrixSubtraction() Failed !, The Matrix Dimensions are not equal to Compute ! %i != %i.", A.rows,B.rows);
    logfile << "|  error   |   " << "solveMatrixSubtraction() Failed !, The Matrix Dimensions are not equal to Compute" << A.rows << " != " << B.rows << "\n";
    logfile.close();
    createErrorHtmlReport(data);
    exit(1);
  }

  //printColumnAlginment(A.data,A.rows,A.column,"A-Matrix");
  //printColumnAlginment(B.data,B.rows,B.column,"B-Matrix");

  // subtract elements in cloumn major
  for (int i = 0; i < A.rows * A.column; i++)
  {
    result[i] = A.data[i] - B.data[i];
  }
}

/*
 * Solve the matrix addition of two matrices
 */
matrixData solveMatrixAddition(matrixData A, matrixData B, ofstream &logfile, DATA * data)
{
  double *result = (double*) calloc(A.rows * A.column, sizeof(double));
  if (A.rows != B.rows && A.column != B.column)
  {
    //cout << "The Matrix Dimensions are not equal to Compute ! \n";
    errorStreamPrint(LOG_STDOUT, 0, "solveMatrixAddition() Failed !, The Matrix Dimensions are not equal to Compute ! %i != %i.", A.rows,B.rows);
    logfile << "|  error   |   " << "solveMatrixAddition() Failed !, The Matrix Dimensions are not equal to Compute" << A.rows << " != " << B.rows << "\n";
    logfile.close();
    createErrorHtmlReport(data);
    exit(1);
  }

  //printColumnAlginment(A.data,A.rows,A.column,"A-Matrix");
  //printColumnAlginment(B.data,B.rows,B.column,"B-Matrix");

  // Add the elements in cloumn major
  for (int i = 0; i < A.rows * A.column; i++)
  {
    result[i] = A.data[i] + B.data[i];
  }
  matrixData tmpadd_a_b = {A.rows, A.column, result};
  return tmpadd_a_b;
}

/*
 * Function which Calculates the Matrix Multiplication
 * of (Sx*Ft)*Fstar
 */
matrixData Calculate_Sx_Ft_Fstar(matrixData Sx, matrixData Ft, matrixData Fstar, ofstream &logfile, DATA * data)
{
  // Sx*Ft
  double *tmpMatrixA = (double*) calloc(Sx.rows * Ft.column, sizeof(double));
  solveMatrixMultiplication(Sx.data, Ft.data, Sx.rows, Sx.column, Ft.rows, Ft.column, tmpMatrixA, logfile, data);
  //printMatrix1(tmpMatrixA,Sx.rows,Ft.column,"Reconciled-(Sx*Ft)");
  //printMatrix1(Fstar.data,Fstar.rows,Fstar.column,"REconciled-FStar");

  //(Sx*Ft)*Fstar
  double *tmpMatrixB = (double*) calloc(Sx.rows * Fstar.column, sizeof(double));
  solveMatrixMultiplication(tmpMatrixA, Fstar.data, Sx.rows, Ft.column, Fstar.rows, Fstar.column, tmpMatrixB, logfile, data);
  matrixData rhsdata = {Sx.rows, Fstar.column, tmpMatrixB};

  free(tmpMatrixA);
  free(tmpMatrixB);
  return rhsdata;
}

/*
 * Solves the system
 * recon_x = x - (Sx*Ft*fstar)
 */
matrixData solveReconciledX(matrixData x, matrixData Sx, matrixData Ft, matrixData Fstar, ofstream &logfile, DATA * data)
{
  // Sx*Ft
  double *tmpMatrixAf = (double*) calloc(Sx.rows * Ft.column, sizeof(double));
  solveMatrixMultiplication(Sx.data, Ft.data, Sx.rows, Sx.column, Ft.rows, Ft.column, tmpMatrixAf, logfile, data);
  //printMatrix(tmpMatrixAf,Sx.rows,Ft.column,"Sx*Ft");

  //(Sx*Ft)*fstar
  double *tmpMatrixBf = (double*) calloc(Sx.rows * Fstar.column, sizeof(double));
  solveMatrixMultiplication(tmpMatrixAf, Fstar.data, Sx.rows, Ft.column, Fstar.rows, Fstar.column, tmpMatrixBf, logfile, data);
  //printMatrix(tmpMatrixBf,Sx.rows,Fstar.column,"(Sx*Ft*fstar)");

  matrixData rhs = {Sx.rows, Fstar.column, tmpMatrixBf};
  //matrixData rhs = Calculate_Sx_Ft_Fstar(Sx, Ft, Fstar, data);

  double *reconciledX = (double*) calloc(x.rows * x.column, sizeof(double));
  solveMatrixSubtraction(x, rhs, reconciledX, logfile, data);
  //printMatrix(reconciledX,x.rows,x.column,"reconciled X^cap ===> (x - (Sx*Ft*fstar))");

  if (ACTIVE_STREAM(LOG_JAC))
  {
    logfile << "Calculations of Reconciled_x ==> (x - (Sx*Ft*f*))" << "\n";
    logfile << "====================================================";
    printMatrix(tmpMatrixAf, Sx.rows, Ft.column, "Sx*Ft", logfile);
    printMatrix(tmpMatrixBf, Sx.rows, Fstar.column, "(Sx*Ft*f*)", logfile);
    printMatrix(reconciledX, x.rows, x.column, "x - (Sx*Ft*f*))", logfile);
    logfile << "***** Completed ****** \n\n";
  }
  matrixData recon_x = {x.rows, x.column, reconciledX};
  //free(reconciledX);
  free(tmpMatrixAf);
  free(tmpMatrixBf);
  return recon_x;
}

/*
 * Solves the system
 * recon_Sx = Sx - (Sx*Ft*Fstar)
 */
matrixData solveReconciledSx(matrixData Sx, matrixData Ft, matrixData Fstar, ofstream &logfile, DATA * data)
{
  // Sx*Ft
  double *tmpMatrixA = (double*) calloc(Sx.rows * Ft.column, sizeof(double));
  solveMatrixMultiplication(Sx.data, Ft.data, Sx.rows, Sx.column, Ft.rows, Ft.column, tmpMatrixA, logfile, data);
  //printMatrix(tmpMatrixA,Sx.rows,Ft.column,"Reconciled-(Sx*Ft)");
  //printMatrix(Fstar.data,Fstar.rows,Fstar.column,"REconciled-FStar");

  //(Sx*Ft)*Fstar
  double *tmpMatrixB = (double*) calloc(Sx.rows * Fstar.column, sizeof(double));
  solveMatrixMultiplication(tmpMatrixA, Fstar.data, Sx.rows, Ft.column, Fstar.rows, Fstar.column, tmpMatrixB, logfile, data);
  //printMatrix(tmpMatrixB,Sx.rows,Fstar.column,"Reconciled-(Sx*Ft*Fstar)");

  matrixData rhs = {Sx.rows, Fstar.column, tmpMatrixB};
  //matrixData rhs = Calculate_Sx_Ft_Fstar(Sx, Ft, Fstar, data);

  double *reconciledSx = (double*) calloc(Sx.rows * Sx.column, sizeof(double));
  solveMatrixSubtraction(Sx, rhs, reconciledSx, logfile, data);
  //printMatrix(reconciledSx,Sx.rows,Sx.column,"reconciled Sx ===> (Sx - (Sx*Ft*Fstar))");

  if (ACTIVE_STREAM(LOG_JAC))
  {
    logfile << "Calculations of Reconciled_Sx ===> (Sx - (Sx*Ft*F*))" << "\n";
    logfile << "============================================";
    printMatrix(tmpMatrixA, Sx.rows, Ft.column, "(Sx*Ft)", logfile);
    printMatrix(tmpMatrixB, Sx.rows, Fstar.column, "(Sx*Ft*F*)", logfile);
    printMatrix(reconciledSx, Sx.rows, Sx.column, "Sx - (Sx*Ft*F*))", logfile);
    logfile << "***** Completed ****** \n\n";
  }
  matrixData recon_sx = {Sx.rows, Sx.column, reconciledSx};
  //free(reconciledSx);
  free(tmpMatrixA);
  free(tmpMatrixB);
  return recon_sx;
}

/*
 * Function Which Computes the
 * Jacobian Matrix F
 */
matrixData getJacobianMatrixF(DATA * data, threadData_t * threadData, ofstream & logfile, bool boundaryConditions = false)
{
  // initialize the jacobian call
  const int index = data->callback->INDEX_JAC_F;
  ANALYTIC_JACOBIAN *jacobian = &(data->simulationInfo->analyticJacobians[index]);
  data->callback->initialAnalyticJacobianF(data, threadData, jacobian);
  int cols = jacobian->sizeCols;
  int rows = jacobian->sizeRows;
  if (cols == 0)
  {
    errorStreamPrint(LOG_STDOUT, 0, "Cannot Compute Jacobian Matrix F");
    logfile << "|  error   |   " << "Cannot Compute Jacobian Matrix F" << "\n";
    logfile.close();
    if (!boundaryConditions)
    {
      createErrorHtmlReport(data);
    }
    else
    {
      createErrorHtmlReportForBoundaryConditions(data);
    }
    exit(1);
  }
  double *jacF = (double*) calloc(rows * cols, sizeof(double)); // allocate for Matrix F
  int k = 0;
  for (int x = 0; x < cols; x++)
  {
    jacobian->seedVars[x] = 1.0;
    data->callback->functionJacF_column(data, threadData, jacobian, NULL);
    //cout << "Calculate one column\n:";
    for (int y = 0; y < rows; y++)
    {
      jacF[k++] = jacobian->resultVars[y];
    }
    jacobian->seedVars[x] = 0.0;
  }
  matrixData Fdata = {rows, cols, jacF};
  return Fdata;
}

/*
 * Function Which Computes the
 * Transpose of Jacobian Matrix FT
 */
matrixData getTransposeMatrix(matrixData jacF)
{
  int rows = jacF.column;
  int cols = jacF.rows;
  double *jacFT = (double*) calloc(rows * cols, sizeof(double)); // allocate for Matrix F-transpose
  int k = 0;
  for (int i = 0; i < jacF.rows; i++)
  {
    for (int j = 0; j < jacF.column; j++)
    {
      // Perform matrix transpose store the elements in column major
      //cout << (i1*jacF.rows+j1) << " index :" << (i1+j1*jacF.rows) << " value is: " << jacF.data[i1+j1*jacF.rows] << "\n";
      jacFT[k++] = jacF.data[i + j * jacF.rows];

    }
  }
  matrixData Ft_data = {rows, cols, jacFT};
  return Ft_data;
}

/*
 * Function which reads the vector
 * and assign to c pointer arrays
 */
matrixData getCovarianceMatrixSx(csvData Sx_result, DATA *data, threadData_t *threadData)
{
  double *tempSx = (double*) calloc(Sx_result.rowcount * Sx_result.columncount, sizeof(double));
  initColumnMatrix(Sx_result.sxdata, Sx_result.rowcount, Sx_result.columncount, tempSx);
  matrixData Sx_data = {Sx_result.rowcount, Sx_result.columncount, tempSx};
  return Sx_data;
}

/*
 * function which validates corelation inputs
 * and displays error messages for
 * user error #7: variable of interest has multiple entry in measurement input file
 * user error #8: variable of interest in correlation input file does not correspond to variable of interest
 */
void validateCorelationInputs(csvData Sx_result, DATA * data, ofstream &logfile, vector<string> headers, string comments, bool boundaryConditions = false)
{
  vector<string> noEntry, multipleEntry, entry;
  for (int i = 0; i < headers.size(); i++)
  {
    bool flag = false;
    for (int j = 0; j < Sx_result.headers.size(); j++)
    {
      if (strcmp(headers[i].c_str(), Sx_result.headers[j].c_str()) == 0)
      {
        //std::cout << "\n matched variables of interest: "<< headers[i] << " => " << Sx_result.headers[j]  << " pos: " << j << "\n";
        flag = true;
        auto it = find(entry.begin(), entry.end(), headers[i]);
        if (it != entry.end())
        {
          //std::cout << "Element found in myvector: " << headers[i] << "\n";
          multipleEntry.push_back(headers[i]);
        }
        else
        {
          entry.push_back(headers[i]);
        }
      }
    }

    // user error variable of interest in correlation input file does not correspond to variable of interest
    if (flag == false)
    {
      noEntry.push_back(headers[i]);
    }
  }

  // dump user error #7: variable of interest , has multiple entry in measurement input file
  for (int i = 0; i < multipleEntry.size(); i++)
  {
    if (!boundaryConditions)
    {
      errorStreamPrint(LOG_STDOUT, 0, "variable of interest %s, at %s has multiple entries in correlation input file %s ", multipleEntry[i].c_str(), comments.c_str(), omc_flagValue[FLAG_DATA_RECONCILE_Cx]);
      logfile << "|  error   |   " << "variable of interest " << multipleEntry[i] << " at " << comments << " has multiple entries in correlation input file " << omc_flagValue[FLAG_DATA_RECONCILE_Cx] << "\n";
    }
    else
    {
      errorStreamPrint(LOG_STDOUT, 0, "variable of interest %s, at %s has multiple entries in reconciled covariance matrix input file %s ", multipleEntry[i].c_str(), comments.c_str(), omc_flagValue[FLAG_DATA_RECONCILE_Cx]);
      logfile << "|  error   |   " << "variable of interest " << multipleEntry[i] << " at " << comments << " has multiple entries in reconciled covariance matrix input file " << omc_flagValue[FLAG_DATA_RECONCILE_Cx] << "\n";
    }
  }

  // dump user error #8: variable of interest in correlation input file does not correspond to variable of interest
  for (int i = 0; i < noEntry.size(); i++)
  {
    if (!boundaryConditions)
    {
      errorStreamPrint(LOG_STDOUT, 0, "variable of interest %s, at %s entry in correlation input file %s does not correspond to a variable of interest ", noEntry[i].c_str(), comments.c_str(), omc_flagValue[FLAG_DATA_RECONCILE_Cx]);
      logfile << "|  error   |   " << "variable of interest " << noEntry[i]  << ", at " << comments << " entry in correlation input file " << omc_flagValue[FLAG_DATA_RECONCILE_Cx] << " does not correspond to a variable of interest" << "\n";
    }
    else
    {
      errorStreamPrint(LOG_STDOUT, 0, "variable of interest %s, at %s entry in reconciled covariance matrix input file %s does not correspond to a variable of interest ", noEntry[i].c_str(), comments.c_str(), omc_flagValue[FLAG_DATA_RECONCILE_Cx]);
      logfile << "|  error   |   " << "variable of interest " << noEntry[i]  << ", at " << comments << " entry in reconciled covariance matrix input file " << omc_flagValue[FLAG_DATA_RECONCILE_Cx] << " does not correspond to a variable of interest" << "\n";
    }
  }

  if (!noEntry.empty() || !multipleEntry.empty())
  {
    logfile.close();
    if (!boundaryConditions)
    {
      createErrorHtmlReport(data);
    }
    else
    {
      createErrorHtmlReportForBoundaryConditions(data);
    }
    exit(1);
  }
}

/*
 * function which validates corelation inputs is
 * square matrix or not and displays error messages for
 * user error #10: Lines and columns are in different orders
 */
void validateCorelationInputsSquareMatrix(DATA * data, ofstream &logfile, vector<string> rowHeaders, vector<string> columnHeaders, bool boundaryConditions = false)
{
  if (rowHeaders != columnHeaders)
  {
    if (!boundaryConditions)
    {
      errorStreamPrint(LOG_STDOUT, 0, "Lines and columns of correlation matrix in correlation input file  %s, do not have identical names in the same order.", omc_flagValue[FLAG_DATA_RECONCILE_Cx]);
      logfile << "|  error   |   " << "Lines and columns of correlation matrix in correlation input file " << omc_flagValue[FLAG_DATA_RECONCILE_Cx] << " do not have identical names in the same order." << "\n";
    }
    else
    {
      errorStreamPrint(LOG_STDOUT, 0, "Lines and columns of covariance matrix in reconciled covariance matrix input file  %s, do not have identical names in the same order.", omc_flagValue[FLAG_DATA_RECONCILE_Cx]);
      logfile << "|  error   |   " << "Lines and columns of covariance matrix in reconciled covariance matrix input file " << omc_flagValue[FLAG_DATA_RECONCILE_Cx] << " do not have identical names in the same order." << "\n";
    }

    // user error #10: missing line headers
    for (const auto & index : columnHeaders)
    {
      auto it = std::find(rowHeaders.begin(), rowHeaders.end(), index);
      if (it == rowHeaders.end())
      {
        errorStreamPrint(LOG_STDOUT, 0, "Line %s is missing", index.c_str());
        logfile << "|  error   |   " << "Line " << index << " is missing " << "\n";
      }
    }

    // user error #10 : missing column headers
    for (const auto & index : rowHeaders)
    {
      auto it = find(columnHeaders.begin(), columnHeaders.end(), index);
      if (it == columnHeaders.end())
      {
        errorStreamPrint(LOG_STDOUT, 0, "Column %s is missing", index.c_str());
        logfile << "|  error   |   " << "Column " << index << " is missing " << "\n";
      }
    }

    // user error #10 : missing line Vs column
    for (int i = 0; i < rowHeaders.size(); i++)
    {
      //std::cout << "\n " << i << rowHeaders[i] << " Vs " << columnHeaders[i];
      if (rowHeaders[i] != columnHeaders[i])
      {
        errorStreamPrint(LOG_STDOUT, 0, "Lines and columns are in different orders %s Vs %s", rowHeaders[i].c_str(), columnHeaders[i].c_str());
        logfile << "|  error   |   " << "Lines and columns are in different orders " << rowHeaders[i] << " Vs " << columnHeaders[i] << "\n";
      }
    }

    logfile.close();
    if (!boundaryConditions)
    {
      createErrorHtmlReport(data);
    }
    else
    {
      createErrorHtmlReportForBoundaryConditions(data);
    }
    exit(1);
  }
}

/*
 * Function which reads the correlation coefficient input file
 * and stores the correlation coefficient matrix Cx for DataReconciliation
 */
correlationData readCorrelationCoefficientFile(csvData Sx_result, ofstream & logfile, DATA * data, bool boundaryConditions = false)
{
  char * filename = NULL;
  filename = (char*) omc_flagValue[FLAG_DATA_RECONCILE_Cx];

  vector<string> columnHeaders, rowHeaders;
  vector<double> cx_data;
  vector<errorData> errorInfo;
  correlationData Cx;
  vector<int> errorInfoHeaders;

  if (filename == NULL && !boundaryConditions)
  {
    Cx = {cx_data, rowHeaders, columnHeaders};
    return Cx;
  }

  if (filename == NULL && boundaryConditions)
  {
    errorStreamPrint(LOG_STDOUT, 0, "Reconciled covariance matrix input file not provided (eg:-cx=filename.csv), Boundary conditions cannot be computed!.");
    logfile << "|  error   |   " << "Reconciled covariance matrix input file not provided (eg:-cx=filename.csv), Boundary conditions cannot be computed!.\n";
    logfile.close();
    createErrorHtmlReportForBoundaryConditions(data);
    exit(1);
  }

  // read the file
  ifstream ip(filename);
  string line;
  if (!ip.good() && !boundaryConditions)
  {
    errorStreamPrint(LOG_STDOUT, 0, "correlation coefficient input file path not found %s.", filename);
    logfile << "|  error   |   " << "correlation coefficient input file path not found " << filename << "\n";
    logfile.close();
    createErrorHtmlReport(data);
    exit(1);
  }

  if (!ip.good() && boundaryConditions)
  {
    errorStreamPrint(LOG_STDOUT, 0, "Reconciled covariance matrix input file path not found %s.", filename);
    logfile << "|  error   |   " << "Reconciled covariance matrix input file path not found " << filename << "\n";
    logfile.close();
    createErrorHtmlReportForBoundaryConditions(data);
    exit(1);
  }

  int linecount = 1;
  while (ip.good())
  {
    getline(ip, line);
    vector<string> t1;
    std::replace(line.begin(), line.end(), ';', ',');
    // remove whitespace in a string
    line.erase(std::remove_if(line.begin(), line.end(), ::isspace), line.end());
    stringstream ss(line);
    string temp;

    // allow comments on the line#1 until finding the headers
    if (linecount == 1 && isLineEmptyData(line))
    {
      continue;
    }

    if (linecount == 1 && !line.empty())
    {
      int columnCount = 1;
      while (getline(ss, temp, ','))
      {
        if (columnCount > 1)
        {
          //std::cout << "\nreading Column headers : " << temp;
          columnHeaders.push_back(temp);
        }
        columnCount++;
      }
    }
    else if (linecount > 1 && !line.empty() && !isLineEmptyData(line))
    {
      //std::cout << "\nreading covariance matrix : " << line << " size : " << columnHeaders.size();
      int columnCount = 1;
      while (getline(ss, temp, ','))
      {
        if (columnCount == 1)
        {
          // error : no variable of interest is provided by user at column #1
          if (temp.empty())
          {
            errorInfoHeaders.push_back(linecount);
          }
          rowHeaders.push_back(temp);
        }
        else
        {
          //std::cout << "\nreading Column values : " << temp << " : " << columnCount << " value= " << atof(temp.c_str());
          if (temp.empty())
          {
            cx_data.push_back(0);
          }
          else if (!isStringValidDouble(temp))
          {
            //std::cout << "\n check wrong type : " << columnCount << " = " << columnHeaders[columnCount-2];
            errorData info = {rowHeaders.back(), columnHeaders[columnCount-2], temp};
            errorInfo.push_back(info);
          }
          else
          {
            cx_data.push_back(atof(temp.c_str()));
          }
        }
        columnCount++;
      }
      if (columnCount - 2 == columnHeaders.size())
      {
        // rows and columns have values correctly entered
      }
      else
      {
        // just in case, fill the empty rows with zeros
        int count = columnHeaders.size() - (columnCount -2);
        for (int i = 0; i < count; ++i)
        {
          cx_data.push_back(0);
        }
      }
    }
    linecount++;
  }

  // user error : variable of interest is missing in column #1
  if (!errorInfoHeaders.empty())
  {
    for (const auto &line : errorInfoHeaders)
    {
      if (!boundaryConditions)
      {
        errorStreamPrint(LOG_STDOUT, 0, "the name of the variable of interest in correlation input file  %s is missing in line #%d ", filename, line);
        logfile << "|  error   |   " << "the name of the variable of interest in correlation input file " << filename << " is missing in line #" << line << "\n";
      }
      else
      {
        errorStreamPrint(LOG_STDOUT, 0, "the name of the variable of interest in reconciled covariance matrix input file  %s is missing in line #%d ", filename, line);
        logfile << "|  error   |   " << "the name of the variable of interest in reconciled covariance matrix input file " << filename << " is missing in line #" << line << "\n";
      }
    }
    logfile.close();
    if (!boundaryConditions)
    {
      createErrorHtmlReport(data);
    }
    else
    {
      createErrorHtmlReportForBoundaryConditions(data);
    }
    exit(1);
  }

  // user error #9: Entry for variable of interest <variable name> and variable of interest <variable name> in correlation input file <input file name> is incorrect: incorrect value type.
  if (!errorInfo.empty())
  {
    for (const auto & info : errorInfo)
    {
      if (!boundaryConditions)
      {
        errorStreamPrint(LOG_STDOUT, 0, "Entry for variable of interest %s and variable of interest %s in correlation input file %s is incorrect because of wrong-Type: [%s] ", info.name.c_str(), info.x.c_str(), filename, info.sx.c_str());
        logfile << "|  error   |   " << "Entry for variable of interest " <<  info.name << " and variable of interest " << info.x << " in correlation input file " << filename <<  " is incorrect because of wrong-Type: " << "[" << info.sx  << "]" <<"\n";
      }
      else
      {
        errorStreamPrint(LOG_STDOUT, 0, "Entry for variable of interest %s and variable of interest %s in reconciled covariance matrix input file %s is incorrect because of wrong-Type: [%s] ", info.name.c_str(), info.x.c_str(), filename, info.sx.c_str());
        logfile << "|  error   |   " << "Entry for variable of interest " <<  info.name << " and variable of interest " << info.x << " in reconciled covariance matrix input file " << filename <<  " is incorrect because of wrong-Type: " << "[" << info.sx  << "]" <<"\n";
      }
    }
    logfile.close();
    if (!boundaryConditions)
    {
      createErrorHtmlReport(data);
    }
    else
    {
      createErrorHtmlReportForBoundaryConditions(data);
    }
    exit(1);
  }

  // validate correlation input column headers
  validateCorelationInputs(Sx_result, data, logfile, columnHeaders, "column headers", boundaryConditions);

  // validate correlation input column headers
  validateCorelationInputs(Sx_result, data, logfile, rowHeaders, "row headers", boundaryConditions);

  // check for square matrix
  validateCorelationInputsSquareMatrix(data, logfile, rowHeaders, columnHeaders, boundaryConditions);

  Cx = {cx_data, rowHeaders, columnHeaders};

  return Cx;
}


/*
 * Function which Computes
 * covariance matrix Sx based on
 * Half width confidence interval provided by user (i.e) csvData.sxdata
 * Sx=(Wxi/1.96)^2
 */
matrixData computeCovarianceMatrixSx(csvData Sx_result, correlationData Cx_data, ofstream &logfile, DATA * data)
{
  double *tempSx = (double*) calloc(Sx_result.sxdata.size() * Sx_result.sxdata.size(), sizeof(double));
  vector<double> tmpdata;
  int k = 0;

  for (unsigned int i = 0; i < Sx_result.sxdata.size(); i++)
  {
    double data = pow(Sx_result.sxdata[k] / 1.96, 2);
    for (unsigned int j = 0; j < Sx_result.sxdata.size(); j++)
    {
      if (i == j)
      {
        //tmpdata.push_back(pow(Sx_result.sxdata[k]/1.96,2));
        //k++;
        tmpdata.push_back(data);
      }
      else
      {
        tmpdata.push_back(0);
      }
      // logfile << " data " << count << "=="<< tmpdata[count++] << "\n";
    }
    k++;
  }

  // check for correlation coefficient Cx_data is not empty and recompute the covariance matrix
  if (! Cx_data.data.empty())
  {
    for (int i = 0; i < Cx_data.rowHeaders.size(); i++)
    {
      for (int j = 0; j < Cx_data.columnHeaders.size(); j++)
      {
        // consider the values which are strictly below the diagonal entry
        if (j < i && Cx_data.data[Cx_data.columnHeaders.size() * i + j] != 0)
        {
          //std::cout << "\n value : " << Cx_data.rowHeaders[i] << "=" << Cx_data.data[columnHeaders.size() * i + j];
          int rowpos = getVariableIndex(Sx_result.headers, Cx_data.rowHeaders[i], logfile, data);
          int colpos = getVariableIndex(Sx_result.headers, Cx_data.columnHeaders[j], logfile, data);

          double xi = tmpdata[(Sx_result.rowcount * rowpos) + rowpos];
          double xk = tmpdata[(Sx_result.rowcount * colpos) + colpos];

          //std::cout << "\n row pos : "  << rowpos << " col pos: " << colpos << " xi " << xi;
          double tmprx = Cx_data.data[Cx_data.columnHeaders.size() * i + j] * sqrt(xi) * sqrt(xk);

          // find the symmetric position and insert the elements
          tmpdata[(Sx_result.rowcount * rowpos) + colpos] = tmprx;
          tmpdata[(Sx_result.rowcount * colpos) + rowpos] = tmprx;
        }
      }
    }
  }

  initColumnMatrix(tmpdata, Sx_result.rowcount, Sx_result.rowcount, tempSx);
  matrixData Sx_data = {Sx_result.rowcount, Sx_result.rowcount, tempSx};
  return Sx_data;
}

/*
 * function which validates the inputs read from measurement input file
 * and validates (i.e) all the variables of interest in input file = all variables of interest in model
 * and displays error message if the above condition fails.
 * Also it perform internal mapping to sort the variable of interest in input file to match with variables of interest in model
 * which is very important for jacobians and also to get correct numerical results
 */

csvData validateMeasurementInputs(csvData Sx_result, DATA * data, ofstream &logfile, bool boundaryConditions = false)
{
  if (data->modelData->ndataReconVars != Sx_result.headers.size())
  {
    errorStreamPrint(LOG_STDOUT, 0, "invalid input file %s, number of variable of interest(%li) != (%zu)number of variables in measurement input file", omc_flagValue[FLAG_DATA_RECONCILE_Sx], data->modelData->ndataReconVars, Sx_result.headers.size());
    logfile << "|  error   |   " << "invalid input file "<< omc_flagValue[FLAG_DATA_RECONCILE_Sx] << ", number of variable of interest(" << data->modelData->ndataReconVars << ")" << " != " << "(" << Sx_result.headers.size() << ")" << "number of variables in measurement input file";
    logfile.close();
    if (!boundaryConditions)
    {
      createErrorHtmlReport(data);
    }
    else
    {
      createErrorHtmlReportForBoundaryConditions(data);
    }
    exit(1);
  }

  char **knowns = (char**) malloc(data->modelData->ndataReconVars * sizeof(char*));
  data->callback->dataReconciliationInputNames(data, knowns);

  vector<string> noEntry, multipleEntry;
  vector<int> mapindex;
  for (int i = 0; i < data->modelData->ndataReconVars; i++)
  {
    bool flag = false;
    int count = 0;
    for (int j = 0; j < Sx_result.headers.size(); j++)
    {
      if (strcmp(knowns[i], Sx_result.headers[j].c_str()) == 0)
      {
        //std::cout << "\n matched variables of interest: "<< knowns[i] << " => " << Sx_result.headers[j]  << " pos: " << j << " size : " << Sx_result.headers.size() << "\n";
        mapindex.push_back(j);
        flag = true;
        count ++;
      }
    }

    // user error variable of interest , has no entry in measurement input file
    if (flag == false)
    {
      noEntry.push_back(knowns[i]);
    }
    // user error variable of interest , has multiple entry in measurement input file
    if (count > 1)
    {
      multipleEntry.push_back(knowns[i]);
    }
  }

  // dump user error #3: variable of interest, has no entry in measurement input file
  for (int i = 0; i < noEntry.size(); i++)
  {
    errorStreamPrint(LOG_STDOUT, 0, "variable of interest %s, has no entry in measurement input file %s ", noEntry[i].c_str(), omc_flagValue[FLAG_DATA_RECONCILE_Sx]);
    logfile << "|  error   |   " << "variable of interest " << noEntry[i] << ", has no entry in measurement input file" << omc_flagValue[FLAG_DATA_RECONCILE_Sx] << "\n";
  }

  // dump user error #4: variable of interest , has multiple entry in measurement input file
  for (int i = 0; i < multipleEntry.size(); i++)
  {
    errorStreamPrint(LOG_STDOUT, 0, "variable of interest %s, has multiple entries in measurement input file %s ", multipleEntry[i].c_str(), omc_flagValue[FLAG_DATA_RECONCILE_Sx]);
    logfile << "|  error   |   " << "variable of interest " << multipleEntry[i] << ", has multiple entries in measurement input file " << omc_flagValue[FLAG_DATA_RECONCILE_Sx] << "\n";
  }

  // dump user error #5 entry in measurement input file does not correspond to a variable of interest
  bool userError5 = false;
  for (int i = 0; i < data->modelData->ndataReconVars; i++)
  {
    auto it = find(mapindex.begin(), mapindex.end(), i);
    if (it == mapindex.end())
    {
      //std::cout << "\n not found" << i;
      userError5 = true;
      errorStreamPrint(LOG_STDOUT, 0, "variable of interest %s, entry in measurement input file %s does not correspond to a variable of interest ", Sx_result.headers[i].c_str(), omc_flagValue[FLAG_DATA_RECONCILE_Sx]);
      logfile << "|  error   |   " << "variable of interest " << Sx_result.headers[i] << ", entry in measurement input file " << omc_flagValue[FLAG_DATA_RECONCILE_Sx] << " does not correspond to a variable of interest" << "\n";
    }
  }

  if (!noEntry.empty() || !multipleEntry.empty() || userError5)
  {
    logfile.close();
    free(knowns);
    if (!boundaryConditions)
    {
      createErrorHtmlReport(data);
    }
    else
    {
      createErrorHtmlReportForBoundaryConditions(data);
    }
    exit(1);
  }

  // map csv inputs with order of variable of interest in the model
  vector<double> mapped_xdata, mapped_Sxdata;
  vector<string> mappedHeader;
  for (const auto & index : mapindex)
  {
    mapped_xdata.push_back(Sx_result.xdata[index]);
    mapped_Sxdata.push_back(Sx_result.sxdata[index]);
    mappedHeader.push_back(Sx_result.headers[index]);
  }

  // assign the mapped order
  Sx_result.xdata = mapped_xdata;
  Sx_result.sxdata = mapped_Sxdata;
  Sx_result.headers = mappedHeader;

  free(knowns);
  return Sx_result;
}


/*
 * Function which reads the input data from csvData.xdata
 * and stores the input values in double array
 */
inputData getInputData(csvData Sx_result, ofstream & logfile)
{
  double * tempx = (double*) calloc(Sx_result.rowcount, sizeof(double));
  vector<int> index;

  for (int i = 0; i < Sx_result.headers.size(); i++)
  {
    tempx[i] = Sx_result.xdata[i];
  }

  inputData x_data = {Sx_result.rowcount, 1, tempx, index};
  return x_data;
}

/*
 * Function which reads the input data from csvData.xdata
 * and stores the input values in double array
 */
inputData getReconciledX(csvData Sx_result, ofstream & logfile)
{
  double * tempx = (double*) calloc(Sx_result.rowcount, sizeof(double));
  vector<int> index;

  for (int i = 0; i < Sx_result.headers.size(); i++)
  {
    tempx[i] = Sx_result.sxdata[i];
  }

  inputData x_data = {Sx_result.rowcount, 1, tempx, index};
  return x_data;
}

/*
 * Function  which Copy Matrix
 * using dcopy_ LAPACK routine
 * this is mostly used when LAPACK routines override arrays
 */
matrixData copyMatrix(matrixData matdata)
{
  double *tmpcopymatrix = (double*) calloc(matdata.rows * matdata.column, sizeof(double));
  int n = matdata.rows * matdata.column;
  int inc = 1;
  dcopy_(&n, matdata.data, &inc, tmpcopymatrix, &inc);

  //  for (int i=0; i < matdata.rows*matdata.column; i++)
  //  {
  //    tmpcopymatrix[i]=matdata.data[i];
  //  }
  matrixData tmpcopymatrixdata = {matdata.rows, matdata.column, tmpcopymatrix};
  return tmpcopymatrixdata;
}

/*
 * Function which scales the MAtrix with constant
 * dscal_ LAPACK_routine and result is updated in data
 * eg: alpha = 2, data=[2,4,5]
 * result = [4,8,10]
 */
void scaleVector(int rows, int cols, double alpha, double *data)
{
  int n = rows * cols;
  int inc = 1;
  dscal_(&n, &alpha, data, &inc);
}

/*
 * Function which calculates the square root of elements
 * eg : a=[1,2,3,4]
 * result a = [srt(1),sqrt(2).......]
 */
void calculateSquareRoot(double *data, int length)
{
  for (int i = 0; i < length; i++)
  {
    data[i] = sqrt(data[i]);
  }
}

/*
 * Function which calculates
 * J*=(recon_x-x)T*(Sx^-1)*(recon_x-x)+2.[f+F*(recon_x-x)]T*fstar
 * where T= transpose of matrix
 * and returns the converged value
 */
double solveConvergence(DATA *data, matrixData conv_recon_x, matrixData conv_recon_sx, inputData conv_x, matrixData conv_sx, matrixData conv_jacF, matrixData conv_vector_c, matrixData conv_fstar, ofstream &logfile)
{

  //printMatrix(conv_vector_c.data,conv_vector_c.rows,conv_vector_c.column,"Convergence_C(x,y)");
  //printMatrix(conv_fstar.data,conv_fstar.rows,conv_fstar.column,"Convergence_f*");
  //printMatrix(conv_recon_x.data,conv_recon_x.rows,conv_recon_x.column,"check_recon_x*");

  // calculate(recon_x-x)
  double *conv_data1 = (double*) calloc(conv_x.rows * conv_x.column, sizeof(double));
  matrixData conv_inputs = {conv_x.rows, conv_x.column, conv_x.data};
  solveMatrixSubtraction(conv_recon_x, conv_inputs, conv_data1, logfile, data);
  matrixData conv_data1result = {conv_x.rows, conv_x.column, conv_data1};
  matrixData copy_reconx_x = copyMatrix(conv_data1result);

  //printMatrix(conv_inputs.data,conv_inputs.rows,conv_inputs.column,"check_inputs");
  //printMatrix(conv_data1result.data,conv_data1result.rows,conv_data1result.column,"(recon_X - X)");

  // calculate Transpose_(recon_x-x)
  matrixData conv_data1Transpose = getTransposeMatrix(conv_data1result);
  //printMatrix(conv_data1Transpose.data,conv_data1Transpose.rows,conv_data1Transpose.column,"Transpose(recon_X - X)");

  /* solves (Sx^-1)*(recon_x-x)
   * Solve the inverse of matrix Sx using linear form
   * Ax=b
   * where A=Sx and b= (recon_x-x) to avoid inversion of Sx which is
   * expensive
   */
  solveSystemFstar(conv_sx.rows, 1, conv_sx.data, conv_data1result.data, logfile, data);
  //printMatrix(conv_data1result.data,conv_sx.rows,conv_data1result.column,"inverse multiplication_without inverse");

  double *conv_tmpmatrixlhs = (double*) calloc(conv_data1Transpose.rows * conv_data1result.column, sizeof(double));
  /*
   * Solve (recon_x-x)T*(Sx^-1)*(recon_x-x)
   */
  solveMatrixMultiplication(conv_data1Transpose.data, conv_data1result.data, conv_data1Transpose.rows, conv_data1Transpose.column, conv_data1result.rows, conv_data1result.column, conv_tmpmatrixlhs, logfile, data);
  //printMatrix(conv_tmpmatrixlhs,conv_data1Transpose.rows,conv_data1result.column,"(recon_x-x)T*(Sx^-1)*(recon_x-x)");
  matrixData struct_conv_tmpmatrixlhs = {conv_data1Transpose.rows, conv_data1result.column, conv_tmpmatrixlhs};

  /*
   * Solve rhs = 2.[f+F*(recon_x-x)]T*fstar
   *
   */
  // Calculate F*(recon_x-x)
  double *tmp_F_recon_x_x = (double*) calloc(conv_jacF.rows * copy_reconx_x.column, sizeof(double));
  solveMatrixMultiplication(conv_jacF.data, copy_reconx_x.data, conv_jacF.rows, conv_jacF.column, copy_reconx_x.rows, copy_reconx_x.column, tmp_F_recon_x_x, logfile, data);
  //printMatrix(tmp_F_recon_x_x,conv_jacF.rows,copy_reconx_x.column,"F*(recon_x-x)");
  matrixData mult_F_recon_x_x = {conv_jacF.rows, copy_reconx_x.column, tmp_F_recon_x_x};

  // Calculate f + F*(recon_x-x)
  matrixData add_f_F_recon_x_x = solveMatrixAddition(conv_vector_c, mult_F_recon_x_x, logfile, data);
  //printMatrix(add_f_F_recon_x_x.data,add_f_F_recon_x_x.rows,add_f_F_recon_x_x.column,"f + F*(recon_x-x)");

  matrixData transpose_add_f_F_recon_x_x = getTransposeMatrix(add_f_F_recon_x_x);
  //printMatrix(transpose_add_f_F_recon_x_x.data,transpose_add_f_F_recon_x_x.rows,transpose_add_f_F_recon_x_x.column,"transpose-[f + F*(recon_x-x)]");

  // calculate [f + F*(recon_x-x)]T*fstar
  double *conv_tmpmatrixrhs = (double*) calloc(transpose_add_f_F_recon_x_x.rows * conv_fstar.column, sizeof(double));
  solveMatrixMultiplication(transpose_add_f_F_recon_x_x.data, conv_fstar.data, transpose_add_f_F_recon_x_x.rows, transpose_add_f_F_recon_x_x.column, conv_fstar.rows, conv_fstar.column, conv_tmpmatrixrhs, logfile, data);
  //printMatrix(conv_tmpmatrixrhs, transpose_add_f_F_recon_x_x.rows, conv_fstar.column,"[f + F*(recon_x-x)]*fstar");

  // scale the matrix with 2*[f + F*(recon_x-x)]T*fstar
  scaleVector(transpose_add_f_F_recon_x_x.rows, conv_fstar.column, 2.0, conv_tmpmatrixrhs);
  //printMatrix(conv_tmpmatrixrhs, transpose_add_f_F_recon_x_x.rows, conv_fstar.column,"2*[f + F*(recon_x-x)]*fstar");
  matrixData struct_conv_tmpmatrixrhs = {transpose_add_f_F_recon_x_x.rows, conv_fstar.column, conv_tmpmatrixrhs};

  /*
   * solve the final J*=J*=(recon_x-x)T*(Sx^-1)*(recon_x-x)+2.[f+F*(recon_x-x)]T*fstar
   * J*=_struct_conv_tmpmatrixlhs + struct_conv_tmpmatrixrhs
   */
  matrixData struct_Jstar = solveMatrixAddition(struct_conv_tmpmatrixlhs, struct_conv_tmpmatrixrhs, logfile, data);
  //printMatrix(struct_Jstar.data,struct_Jstar.rows,struct_Jstar.column,"J*",logfile);

  int r = data->modelData->nSetcVars; // number of setc equations
  double val = 1.0 / r;

  /*
   * calculate J/r < epselon
   */
  scaleVector(struct_Jstar.rows, struct_Jstar.column, val, struct_Jstar.data);
  //printMatrix(struct_Jstar.data,struct_Jstar.rows,struct_Jstar.column,"J*/r ");
  double convergedvalue = struct_Jstar.data[0];

  //  free(struct_Jstar.data);
  //  free(struct_conv_tmpmatrixrhs.data);
  //  free(conv_tmpmatrixrhs);
  //  free(transpose_add_f_F_recon_x_x.data);
  //  free(add_f_F_recon_x_x.data);
  //  free(transpose_add_f_F_recon_x_x.data);
  //  free(mult_F_recon_x_x.data);
  //  free(tmp_F_recon_x_x);
  //  free(struct_conv_tmpmatrixlhs.data);
  //  free(conv_tmpmatrixlhs);
  //  free(conv_data1Transpose.data);
  //  free(copy_reconx_x.data);
  //  free(conv_data1result.data);
  //  free(conv_data1);

  return convergedvalue;
}

/*
 * Example Function which performs matrix inverse
 * using dgetri_ and dgetrf_ LAPACK routine
 * which is expensive one and not recommended
 * use it when no other way to compute it
 */
void checkExpensiveMatrixInverse()
{
  double  newval[3*3]={3,2,0,
      0,0,1,
      2,-2,1};

  int N = 3;
  int LDA = N;
  int LDB = N;
  int ipiv[N];
  int info = 1;
  int LWORK = N;
  double *WORK = (double*) calloc(LWORK, sizeof(double));

  dgetrf_(&N, &N, newval, &N, ipiv, &info);
  dgetri_(&N, newval, &N, ipiv, WORK, &LWORK, &info);
  //printMatrix(newval,3,3,"Expensive_Matrix_Inverse");
}

/*
 * Function which performs matrix inverse without performing
 * actual matrix inverse, Instead use the dgesv to get result
 * Ax=b where matrix mutiplication of x=bA gives the inversed
 * mutiplication result b with A inverse
 */
void checkInExpensiveMatrixInverse(ofstream & logfile, DATA * data)
{
  double newchecksx[3*3]={1,1,1,
      0,0.95,0,
      0,0,0.95};
  double checksx[3 * 1] = {-0.028, 0.026, -0.004};
  solveSystemFstar(3, 1, newchecksx, checksx, logfile, data);
  //printMatrix(checksx,3,1,"InExpensive_Matrix_Inverse");
}

int RunReconciliation(DATA *data, threadData_t *threadData, inputData x, matrixData Sx, matrixData tmpjacF, matrixData tmpjacFt, double eps, int iterationcount, csvData csvinputs, matrixData xdiag, matrixData sxdiag, ofstream &logfile, correlationDataWarning & warningCorrelationData)
{
  // set the inputs from csv file to simulationInfo datainputVars
  for (int i = 0; i < x.rows * x.column; i++)
  {
    data->simulationInfo->datainputVars[i] = x.data[i];
    //logfile << "input data:" << x.data[i]<<"\n";
  }

  /* set the inputs via this special function generated for dataReconciliation
   * which also sets inputs for models not involving top level inputs
   */
  data->callback->data_function(data, threadData);
  //data->callback->input_function(data, threadData);
  data->callback->functionDAE(data, threadData);
  //data->callback->functionODE(data,threadData);
  data->callback->setc_function(data, threadData);

  matrixData jacF = getJacobianMatrixF(data, threadData, logfile);
  matrixData jacFt = getTransposeMatrix(jacF);

  printMatrix(jacF.data, jacF.rows, jacF.column, "F", logfile);
  printMatrix(jacFt.data, jacFt.rows, jacFt.column, "Ft", logfile);

  // allocate data for setc array
  double *setc = (double*) calloc (data->modelData->nSetcVars, sizeof(double));

  // store the setc data to compute for convergence as setc will be overriddeen with new values
  double *tmpsetc = (double*) calloc (data->modelData->nSetcVars, sizeof(double));

  /* loop to store the data C(x,y) rhs side, get the elements in reverse order */
  int t = 0;
  for (int i = data->modelData->nSetcVars; i > 0; i--)
  {
    setc[t] = data->simulationInfo->setcVars[i-1];
    tmpsetc[t] = data->simulationInfo->setcVars[i-1];
    t++;
    //cout << "array_setc_vars:=>" << t << ":" << data->simulationInfo->setcVars[i-1] << "\n";
  }

  int nsetcvars = data->modelData->nSetcVars;
  matrixData vector_c = {nsetcvars, 1, tmpsetc};

  //allocate data for matrix multiplication F*Sx
  double *tmpmatrixC = (double*) calloc (jacF.rows * Sx.column, sizeof(double));
  solveMatrixMultiplication (jacF.data, Sx.data, jacF.rows, jacF.column,Sx.rows, Sx.column, tmpmatrixC, logfile, data);
  //printMatrix(tmpmatrixC,jacF.rows,Sx.column,"F*Sx");

  //allocate data for matrix multiplication (F*Sx)*Ftranspose
  double *tmpmatrixD = (double*) calloc (jacF.rows * jacFt.column, sizeof(double));
  solveMatrixMultiplication (tmpmatrixC, jacFt.data, jacF.rows, Sx.column, jacFt.rows, jacFt.column, tmpmatrixD, logfile, data);

  //printMatrix(tmpmatrixD,jacF.rows,jacFt.column,"F*Sx*Ft");
  //printMatrix(setc,nsetcvars,1,"c(x,y)");

  /*
   * Copy tmpmatrixC and tmpmatrixD to avoid loss of data
   * when calculating F*
   */
  matrixData cpytmpmatrixC = {jacF.rows, Sx.column, tmpmatrixC};
  matrixData cpytmpmatrixD = {jacF.rows, jacFt.column, tmpmatrixD};
  matrixData tmpmatrixC1 = copyMatrix(cpytmpmatrixC);
  matrixData tmpmatrixD1 = copyMatrix(cpytmpmatrixD);

  if(ACTIVE_STREAM(LOG_JAC))
  {
    logfile << "Calculations of Matrix (F*Sx*Ft) f* = c(x,y) " << "\n";
    logfile << "============================================\n";
    printMatrix(tmpmatrixC, jacF.rows, Sx.column, "F*Sx", logfile);
    printMatrix(tmpmatrixD, jacF.rows, jacFt.column, "F*Sx*Ft", logfile);
    printMatrix(setc, nsetcvars, 1, "c(x,y)", logfile);
  }

  /*
   * calculate f* for covariance matrix (F*Sx*Ftranspose).F*= c(x,y)
   * matrix setc will be overridden with new values which is the output
   * for the calculation A *x =B
   * A = tmpmatrixD
   * B = setc
   */
  solveSystemFstar(jacF.rows, 1, tmpmatrixD, setc, logfile, data);

  if(ACTIVE_STREAM(LOG_JAC))
  {
    printMatrix(setc, jacF.rows, 1, "f*", logfile);
    logfile << "***** Completed ****** \n\n";
  }

  matrixData tmpxcap = {x.rows, 1, x.data};
  matrixData tmpfstar = {jacF.rows, 1, setc};
  matrixData reconciled_X = solveReconciledX(tmpxcap, Sx, jacFt, tmpfstar, logfile, data);
  //printMatrix(reconciled_X.data,reconciled_X.rows,reconciled_X.column,"reconciled_X ===> (x - (Sx*Ft*fstar))");

  if (ACTIVE_STREAM(LOG_JAC))
  {
    logfile << "Calculations of Matrix (F*Sx*Ft) F* = F*Sx " << "\n";
    logfile << "===============================================\n";
    //printMatrix(tmpmatrixC,jacF.rows,Sx.column,"F*Sx");
    //printMatrix(tmpmatrixD,jacF.rows,jacFt.column,"F*Sx*Ft");
    printMatrix(tmpmatrixC1.data, tmpmatrixC1.rows, tmpmatrixC1.column, "F*Sx", logfile);
    printMatrix(tmpmatrixD1.data, tmpmatrixD1.rows, tmpmatrixD1.column, "F*Sx*Ft", logfile);
  }

  /*
   * calculate F* for covariance matrix (F*Sx*Ftranspose).F*= (F*Sx)
   * tmpmatrixC1 will be overridden with new values which is the output
   * for the calculation A *x =B
   * A = tmpmatrixD
   * B = tmpmatrixC
   */
  solveSystemFstar(jacF.rows, Sx.column, tmpmatrixD1.data, tmpmatrixC1.data, logfile, data);

  if (ACTIVE_STREAM(LOG_JAC))
  {
    printMatrix(tmpmatrixC1.data, jacF.rows, Sx.column, "F*", logfile);
    logfile << "***** Completed ****** \n\n";
  }

  matrixData tmpFstar = {jacF.rows, Sx.column, tmpmatrixC1.data};
  matrixData reconciled_Sx = solveReconciledSx(Sx, jacFt, tmpFstar, logfile, data);
  //printMatrix(reconciled_Sx.data,reconciled_Sx.rows,reconciled_Sx.column,"reconciled Sx ===> (Sx - (Sx*Ft*Fstar))");

  matrixData copySx = copyMatrix(Sx);
  double value = solveConvergence(data, reconciled_X, reconciled_Sx, x, copySx, jacF, vector_c, tmpfstar, logfile);
  if (value > eps)
  {
    logfile << "J*/r" << "(" << value << ")" << " > " << eps << ", Value not Converged \n";
    logfile << "==========================================\n\n";
  }
  if (value > eps)
  {
    logfile << "Running Convergence iteration: " << iterationcount << " with the following reconciled values:" << "\n";
    logfile << "========================================================================" << "\n";
    //cout << "J*/r :=" << value << "\n";
    //printMatrix(jacF.data,jacF.rows,jacF.column,"F");
    //printMatrix(jacFt.data,jacFt.rows,jacFt.column,"Ft");
    //printMatrix(setc,jacF.rows,1,"f*");
    //printMatrix(tmpmatrixC,jacF.rows,Sx.column,"F*");
    printMatrixWithHeaders(reconciled_X.data, reconciled_X.rows, reconciled_X.column, csvinputs.headers, "reconciled_X ===> (x - (Sx*Ft*fstar))", logfile);
    printMatrixWithHeaders(reconciled_Sx.data, reconciled_Sx.rows, reconciled_Sx.column, csvinputs.headers, "reconciled_Sx ===> (Sx - (Sx*Ft*Fstar))", logfile);
    //free(x.data);
    //free(Sx.data);
    x.data = reconciled_X.data;
    //Sx.data=reconciled_Sx.data;
    iterationcount++;
    return RunReconciliation(data, threadData, x, Sx, jacF, jacFt, eps, iterationcount, csvinputs, xdiag, sxdiag, logfile, warningCorrelationData);
  }

  if (value < eps && iterationcount == 1)
  {
    logfile << "J*/r" << "(" << value << ")" << " > " << eps << ", Convergence iteration not required \n\n";
  }
  else
  {
    logfile << "***** Value Converged, Convergence Completed******* \n\n";
  }
  logfile << "Final Results:\n";
  logfile << "=============\n";
  logfile << "Total Iteration to Converge : " << iterationcount << "\n";
  logfile << "Final Converged Value(J*/r) : " << value << "\n";
  logfile << "Epsilon                     : " << eps << "\n";
  printMatrixWithHeaders(reconciled_X.data, reconciled_X.rows, reconciled_X.column, csvinputs.headers, "reconciled_X ===> (x - (Sx*Ft*fstar))", logfile);
  printMatrixWithHeaders(reconciled_Sx.data, reconciled_Sx.rows, reconciled_Sx.column, csvinputs.headers, "reconciled_Sx ===> (Sx - (Sx*Ft*Fstar))", logfile);

  dumpReconciledSxToCSV(reconciled_Sx.data, reconciled_Sx.rows, reconciled_Sx.column, csvinputs.headers, data);

  /*
   * Calculate half width Confidence interval
   * W=lambda*sqrt(Sx)
   * where lamba = 1.96 and
   * Sx - diagonal elements of reconciled_Sx
   */
  double *reconSx_diag = (double*) calloc (reconciled_Sx.rows * 1, sizeof(double));
  getDiagonalElements(reconciled_Sx.data, reconciled_Sx.rows, reconciled_Sx.column, reconSx_diag);

  matrixData copyreconSx_diag = {reconciled_Sx.rows, 1, reconSx_diag};
  matrixData tmpcopyreconSx_diag = copyMatrix(copyreconSx_diag);

  if (ACTIVE_STREAM(LOG_JAC))
  {
    logfile << "Calculations of HalfWidth Confidence Interval " << "\n";
    logfile << "===============================================\n";
    printMatrix(copyreconSx_diag.data, reconciled_Sx.rows, 1, "reconciled-Sx_Diagonal", logfile);
  }

  calculateSquareRoot(copyreconSx_diag.data, reconciled_Sx.rows);

  if (ACTIVE_STREAM(LOG_JAC))
  {
    printMatrix(copyreconSx_diag.data, reconciled_Sx.rows, 1, "reconciled-Sx_SquareRoot", logfile);
    logfile << "*****Completed***********\n";
  }

  scaleVector(reconciled_Sx.rows, 1, 1.96, copyreconSx_diag.data);
  printMatrixWithHeaders(copyreconSx_diag.data, reconciled_Sx.rows, 1, csvinputs.headers, "Wx-HalfWidth-Interval-(1.96)*sqrt(Sx_diagonal)", logfile);

  /*
   * Calculate individual tests
   * (recon_x - x)/sqrt(Sx-recon_Sx)
   */
  double *newSx_diag = (double*) calloc (reconciled_Sx.rows * 1, sizeof(double));
  solveMatrixSubtraction(sxdiag, tmpcopyreconSx_diag, newSx_diag, logfile, data);

  if (ACTIVE_STREAM(LOG_JAC))
  {
    logfile << "Calculations of Individual Tests " << "\n";
    logfile << "===============================================\n";
    printMatrix(newSx_diag, sxdiag.rows, sxdiag.column, "Sx-recon_Sx", logfile);
  }

  calculateSquareRoot(newSx_diag, reconciled_Sx.rows);

  if (ACTIVE_STREAM(LOG_JAC))
  {
    printMatrix (newSx_diag, sxdiag.rows, sxdiag.column, "squareroot-newSx", logfile);
  }

  double *newX = (double*) calloc (xdiag.rows * 1, sizeof(double));
  solveMatrixSubtraction(reconciled_X, xdiag, newX, logfile, data);

  // calculate absolute value for this numeric analysis
  for (int a = 0; a < xdiag.rows; a++)
  {
    newX[a] = fabs (newX[a]);
  }

  if (ACTIVE_STREAM(LOG_JAC))
  {
    printMatrix(newX, xdiag.rows, xdiag.column, "recon_X - X", logfile);
    logfile << "*********Completed***********\n";
  }

  for (int val = 0; val < xdiag.rows; val++)
  {
    newX[val] = newX[val] / max(newSx_diag[val], sqrt(sxdiag.data[val] / 10));
  }

  printMatrixWithHeaders(newX, xdiag.rows, xdiag.column, csvinputs.headers, "IndividualTests_Value- (recon_x-x)/sqrt(Sx_diag)", logfile);

  // create HTML Report for D.1
  createHtmlReportFordataReconciliation(data, csvinputs, xdiag, reconciled_X, copyreconSx_diag, newX, eps, iterationcount, value, warningCorrelationData);

  free(tmpFstar.data);
  free(tmpfstar.data);
  //free(tmpmatrixC);
  //free(tmpmatrixD);
  //free(setc);
  free(reconciled_Sx.data);
  free(reconciled_X.data);
  free(copyreconSx_diag.data);
  free(tmpcopyreconSx_diag.data);
  free(newSx_diag);
  free(newX);
  //free(jacF.data);
  //free(jacFt.data);
  //free(x.data);
  //free(Sx.data);
  return 0;
}

/*
 * Runs the numerical procedure to compute constraint equation (D.1)
*/
int dataReconciliation(DATA * data, threadData_t * threadData, int status)
{
  TRACE_PUSH

  // copy the reference files "AuxiliaryConditions and IntermediateEquations.html to output path"
  if (omc_flag[FLAG_OUTPUT_PATH])
  {
    copyReferenceFile(data, "_AuxiliaryConditions.html");
    copyReferenceFile(data, "_IntermediateEquations.html");
    copyReferenceFile(data, "_relatedBoundaryConditionsEquations.txt");
  }

  // report run time initialization and non linear convergence error to html
  if (status != 0)
  {
    createErrorHtmlReport(data, status);
    exit(1);
  }

  const char * epselon = NULL;
  epselon = (char*) omc_flagValue[FLAG_DATA_RECONCILE_Eps];

  // create a debug log file
  ofstream logfile;
  std::stringstream logfilename;
  if (omc_flag[FLAG_OUTPUT_PATH])
  {
    logfilename << omc_flagValue[FLAG_OUTPUT_PATH] << "/" << data->modelData->modelName << "_debug.txt";
  }
  else
  {
    logfilename << data->modelData->modelName << "_debug.txt";
  }

  string tmplogfilename = logfilename.str();
  logfile.open(tmplogfilename.c_str());
  logfile << "|  info    |   " << "DataReconciliation Starting!\n";
  logfile << "|  info    |   " << data->modelData->modelName << "\n";

  // set default value (epselon = 1.e-10), if no value provided by user
  if (epselon == NULL)
  {
    epselon = "0.0000000001";
  }

  // read the measurement input data provide by user
  csvData csvdata = readMeasurementInputFile(logfile, data);

  // validate the input data read from measurement input file
  csvData Sx_data = validateMeasurementInputs(csvdata, data, logfile);

  // extracts the input data (x) from csvData
  inputData x = getInputData(Sx_data, logfile);

  // read the correlation coefficient input data provide by user
  correlationData Cx_data = readCorrelationCoefficientFile(Sx_data, logfile, data);

  // Compute the covariance matrix (Sx) from csvData
  matrixData Sx = computeCovarianceMatrixSx(Sx_data, Cx_data, logfile, data);

  // Compute the Jacobian Matrix F
  matrixData jacF = getJacobianMatrixF(data, threadData, logfile);

  // Compute the Transpose of jacobian Matrix F
  matrixData jacFt = getTransposeMatrix(jacF);

  double * Sx_diag = (double*) calloc(Sx.rows * 1, sizeof(double));
  getDiagonalElements(Sx.data, Sx.rows, Sx.column, Sx_diag);
  matrixData tmpSx_diag = {Sx.rows, 1, Sx_diag};

  matrixData tmp_x = {x.rows, x.column, x.data};
  matrixData x_diag = copyMatrix(tmp_x);

  correlationDataWarning warningCorrelationData;
  // Print the initial information
  logfile << "\n\nInitial Data \n" << "=============\n";
  printMatrixWithHeaders(x.data, x.rows, x.column, Sx_data.headers, "X", logfile);
  printVectorMatrixWithHeaders(Sx_data.sxdata, Sx_data.rowcount, 1, Sx_data.headers, "Half-WidthConfidenceInterval", logfile);
  printCorelationMatrix(Cx_data.data, Cx_data.rowHeaders, Cx_data.columnHeaders, "Co-Relation_Coefficient", logfile, warningCorrelationData);
  printMatrixWithHeaders(Sx.data, Sx.rows, Sx.column, Sx_data.headers, "Sx", logfile);

  // Start the Algorithm
  RunReconciliation(data, threadData, x, Sx, jacF, jacFt, atof(epselon), 1, Sx_data, x_diag, tmpSx_diag, logfile, warningCorrelationData);
  logfile << "|  info    |   " << "DataReconciliation Completed! \n";
  logfile.flush();
  logfile.close();
  free(Sx.data);
  free(x.data);
  free(jacF.data);
  free(jacFt.data);
  free(tmpSx_diag.data);
  free(x_diag.data);
  TRACE_POP
  return 0;
}


/*
 * Runs the numerical procedure to compute Boundary conditions (D.2)
*/
int reconcileBoundaryConditions(DATA * data, threadData_t * threadData, int status)
{
  TRACE_PUSH

  // copy the reference files "BoundaryConditionsEquations.html and _BoundaryConditionIntermediateEquations.html to output path"
  if (omc_flag[FLAG_OUTPUT_PATH])
  {
    copyReferenceFile(data, "_BoundaryConditionsEquations.html");
    copyReferenceFile(data, "_BoundaryConditionIntermediateEquations.html");
  }

  // report run time initialization and non linear convergence error to html
  if (status != 0)
  {
    createErrorHtmlReportForBoundaryConditions(data, status);
    exit(1);
  }

  // create a debug log file
  ofstream logfile;
  std::stringstream logfilename;
  if (omc_flag[FLAG_OUTPUT_PATH])
  {
    logfilename << omc_flagValue[FLAG_OUTPUT_PATH] << "/" << data->modelData->modelName << "_BoundaryConditions_debug.txt";
  }
  else
  {
    logfilename << data->modelData->modelName << "_BoundaryConditions_debug.txt";
  }

  string tmplogfilename = logfilename.str();
  logfile.open(tmplogfilename.c_str());
  logfile << "|  info    |   " << "Reconcile Boundary Conditions Starting!\n";
  logfile << "|  info    |   " << data->modelData->modelName << "\n";

  // read the measurement input data provide by user
  csvData csvdata = readMeasurementInputFile(logfile, data, true);

  // validate the input data read from measurement input file
  csvData Sx_data = validateMeasurementInputs(csvdata, data, logfile, true);

  // extracts the input data (x) from csvData
  inputData reconciled_x = getReconciledX(Sx_data, logfile);

  // read the reconciled covariance matrix input file provided by user
  correlationData cx_data = readCorrelationCoefficientFile(Sx_data, logfile, data, true);

  // create the column matrix from the covariance matrix
  int rowsize = cx_data.rowHeaders.size();
  int colsize = cx_data.columnHeaders.size();
  double *tempSx = (double*) calloc(rowsize * colsize, sizeof(double));
  initColumnMatrix(cx_data.data, rowsize, colsize, tempSx);
  matrixData reconciled_Sx = {rowsize, colsize, tempSx};


  logfile << "\n\nInitial Data \n" << "=============\n";
  printMatrixWithHeaders(reconciled_x.data, reconciled_x.rows, reconciled_x.column, Sx_data.headers, "Reconciled_X", logfile);
  //printCorelationMatrix(reconciled_Sx.data, reconciled_Sx.rowHeaders, reconciled_Sx.columnHeaders, "Reconciled_Sx", logfile, warningCorrelationData);
  printMatrixWithHeaders(reconciled_Sx.data, reconciled_Sx.rows, reconciled_Sx.column, Sx_data.headers, "Reconciled_Sx", logfile);

  // set the inputs from csv file to simulationInfo datainputVars
  for (int i = 0; i < reconciled_x.rows * reconciled_x.column; i++)
  {
    data->simulationInfo->datainputVars[i] = reconciled_x.data[i];
  }

  /* set the inputs via this special function generated for dataReconciliation
   * which also sets inputs for models not involving top level inputs
   */
  data->callback->data_function(data, threadData);
  // solve the system with reconciled input values got from D.1
  data->callback->functionDAE(data, threadData);
  // call the setc function which stores the results of boundary conditions variable
  data->callback->setc_function(data, threadData);

  // Compute the Jacobian Matrix F
  matrixData jacF = getJacobianMatrixF(data, threadData, logfile, true);
  printMatrix(jacF.data, jacF.rows, jacF.column, "F", logfile);

  // Compute the Transpose of jacobian Matrix F
  matrixData jacFt = getTransposeMatrix(jacF);
  printMatrix(jacFt.data, jacFt.rows, jacFt.column, "Ft", logfile);

  /*
   * Compute St = jacF*reconciles_Sx*jacFt
   */
  // F*reconciledSx
  double *tmpMatrixAf = (double *)calloc(jacF.rows * reconciled_Sx.column, sizeof(double));
  solveMatrixMultiplication(jacF.data, reconciled_Sx.data, jacF.rows, jacF.column, reconciled_Sx.rows, reconciled_Sx.column, tmpMatrixAf, logfile, data);
  printMatrix(tmpMatrixAf, jacF.rows, reconciled_Sx.column, "F*reconciled_Sx", logfile);

  //(F*reconciledSx)*ftranspose
  double *S_t = (double*) calloc(jacF.rows * jacFt.column, sizeof(double));
  solveMatrixMultiplication(tmpMatrixAf, jacFt.data, jacF.rows, jacF.column, jacFt.rows, jacFt.column, S_t, logfile, data);
  printMatrix(S_t, jacF.rows, jacFt.column, "(s_t = F*reconciled_Sx*Ft)", logfile);

  /*
   * Calculate half width Confidence interval
   * W=lambda*sqrt(S_t)
   * where lamba = 1.96 and
   * S_t - diagonal elements of S_t
   */
  double *reconSt_diag = (double*) calloc (jacF.rows * 1, sizeof(double));
  getDiagonalElements(S_t, jacF.rows, jacFt.column, reconSt_diag);

  if (ACTIVE_STREAM(LOG_JAC))
  {
    logfile << "Calculations of half-width confidence interval" << "\n";
    logfile << "===============================================\n";
    printMatrix(reconSt_diag, jacF.rows, 1, "S_t_Diagonal", logfile);
  }

  calculateSquareRoot(reconSt_diag, jacF.rows);

  if (ACTIVE_STREAM(LOG_JAC))
  {
    printMatrix(reconSt_diag, jacF.rows, 1, "S_t_SquareRoot", logfile);
  }

  scaleVector(jacF.rows, 1, 1.96, reconSt_diag);

  // check for BoundaryConditionVars.txt file exists to generate the html report
  std::string boundaryConditionsVarsFilename = std::string(data->modelData->modelFilePrefix) +  "_BoundaryConditionVars.txt";
  vector<std::string> boundaryConditionVars;

  if (omc_flag[FLAG_OUTPUT_PATH])
  {
    boundaryConditionsVarsFilename = string(omc_flagValue[FLAG_OUTPUT_PATH]) + "/" + boundaryConditionsVarsFilename;
    copyReferenceFile(data, "_BoundaryConditionVars.txt");
  }

  ifstream boundaryConditionVarsip(boundaryConditionsVarsFilename);
  std::string line;
  if (boundaryConditionVarsip.good())
  {
    while (boundaryConditionVarsip.good())
    {
      getline(boundaryConditionVarsip, line);
      if (!line.empty())
      {
        //std::cout << "\n reading nonVariables of interest : " << line;
        boundaryConditionVars.push_back(line);
      }
    }
    boundaryConditionVarsip.close();
    omc_unlink(boundaryConditionsVarsFilename.c_str());
  }
  else
  {
    errorStreamPrint(LOG_STDOUT, 0, "Boundary conditions vars filename not found: %s.", boundaryConditionsVarsFilename.c_str());
    logfile << "|  error   |   " << "Boundary conditions vars filename not found: " << boundaryConditionsVarsFilename << "\n";
    logfile.close();
    createErrorHtmlReportForBoundaryConditions(data);
    exit(1);
  }

  printMatrixWithHeaders(reconSt_diag, jacF.rows, 1, boundaryConditionVars, "Half-width Confidence Interval(1.96*S_t_SquareRoot)", logfile);

  // allocate data for boundaryconditions vars simulation results
  double *boundaryConditionVarsResults = (double *)calloc(data->modelData->nSetcVars, sizeof(double));
  int t = 0;
  for (int i = data->modelData->nSetcVars; i > 0; i--)
  {
    boundaryConditionVarsResults[t] = data->simulationInfo->setcVars[i - 1];
    t++;
  }

  printBoundaryConditionsResults(boundaryConditionVarsResults, reconSt_diag,  jacF.rows, 1, boundaryConditionVars, "Final Results", logfile);

  // create html report for boundary conditions
  createHtmlReportForBoundaryConditions(data, boundaryConditionVars, boundaryConditionVarsResults, reconSt_diag);

  logfile << "*****Completed***********\n";
  logfile << "|  info    |   " << "Reconcile Boundary Conditions Completed! \n";
  logfile.flush();
  logfile.close();

  // free the memory
  free(reconciled_Sx.data);
  free(reconciled_x.data);
  free(tmpMatrixAf);
  free(S_t);
  free(jacF.data);
  free(jacFt.data);
  free(reconSt_diag);
  free(boundaryConditionVarsResults);
  TRACE_POP
  return 0;
}
