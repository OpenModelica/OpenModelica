/*
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 *
 */

//! @file   plotwindow.h
//! @author harka011
//! @date   2011-02-03

//! @brief Tool drawing 2D plot graph, supports .plt .mat .csv and plot plotParametric plotAll

#ifndef PLOTWINDOW_H
#define PLOTWINDOW_H

#include <QtGui/QMainWindow>
#include <QtGui/QApplication>
#include <QFile>
#include <QCheckBox>
#include <QToolButton>
#include <QMessageBox>
#include <QToolBar>
#include <QHBoxLayout>
#include <QLabel>
#include <QImageWriter>
#include <QFileDialog>
#include <QDockWidget>
#include <QStatusBar>
#include <QTextStream>

#include <qwt_plot.h>
#include <qwt_plot_curve.h>
#include <qwt_plot_picker.h>
#include <qwt_picker_machine.h>
#include <qwt_plot_grid.h>
#include <qwt_curve_fitter.h>
#include <qwt_legend.h>
#include <qwt_plot_zoomer.h>
#include <qwt_plot_panner.h>
#include <qwt_scale_engine.h>
#include <stdexcept>
#include "../../c_runtime/read_matlab4.h"

// Info about a curve
struct curveData
{
    QVector<double> xAxisVector;
    QVector<double> yAxisVector;
    QString curveName;
};

class PlotWindow : public QMainWindow
{
    Q_OBJECT
public:           
    PlotWindow(QStringList arguments, QWidget *parent = 0);    
    PlotWindow(QString fileName, QWidget *parent = 0);
    ~PlotWindow();

    void plot(QStringList);
    void plotAll();
    void plotParametric(QString, QString);
    void plotGraph(QList<curveData>);

    void openFile(QString);
    void initializePlot();
    void setupToolbar();
    void initializeZoom();

    void setTitle(QString);
    void setLegend(QString);
    void setLogX(QString);
    void setLogY(QString);
    void setXLabel(QString);
    void setYLabel(QString);
    void setXRange(double min, double max);
    void setYRange(double min, double max);
    void checkForErrors(QStringList, QVector<int> );
private:
    QwtPlot *mpQwtPlot;
    QwtLegend *mpQwtLegend;
    QwtPlotPicker *mpPlotPicker;
    QwtPlotGrid *mpGrid;
    QwtPlotZoomer *mpPlotZoomer;
    QwtPlotPanner *mpPlotPanner;

    QCheckBox *mpXCheckBox;
    QCheckBox *mpYCheckBox;
    QToolButton *mpGridButton;
    QToolButton *mpZoomButton;
    QToolButton *mpPanButton;

    QList<curveData> mCurveDataList;

    QTextStream *mpTextStream;
    QFile *mpFile;
public Q_SLOTS:
    void enableZoomMode(bool);
    void enablePanMode(bool);
    void exportDocument();
    void setLog();
    void setGrid(bool);
    void setOriginal();
};

//Class for zooming
class  Zoomer: public QwtPlotZoomer
{
public:
    Zoomer(int xAxis, int yAxis, QwtPlotCanvas *canvas):
        QwtPlotZoomer(xAxis, yAxis, canvas)
    {
        setTrackerMode(QwtPicker::AlwaysOff);
        setRubberBand(QwtPicker::NoRubberBand);

        // RightButton: zoom out by 1
        // Ctrl+RightButton: zoom out to full size

        setMousePattern(QwtEventPattern::MouseSelect2,
            Qt::RightButton, Qt::ControlModifier);
        setMousePattern(QwtEventPattern::MouseSelect3,
            Qt::RightButton);
    }
};

//Exception classes
class PlotException : public std::runtime_error
{
public:
    PlotException(const char *e) : std::runtime_error(e) {}
};

class NoFileException : public PlotException
{
public:
    NoFileException(const char * fileName) : PlotException(fileName) {}
private:
    const char * temp;
};

class NoVariableException : public PlotException
{
public:
    NoVariableException(const char * fileName) : PlotException(fileName) {}
};

#endif // PLOTWINDOW_H
