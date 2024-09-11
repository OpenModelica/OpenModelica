#ifndef FMUEXPORTOUTPUTWIDGET_H
#define FMUEXPORTOUTPUTWIDGET_H


#include <QPlainTextEdit>
#include <QProgressBar>
#include <QPushButton>
#include <QWidget>
#include <QProcess>
#include <QTabWidget>
#include "Modeling/LibraryTreeWidget.h"

class Label;
class OutputPlainTextEdit;

class FmuExportOutputWidget : public QWidget
{
  Q_OBJECT
public:
  FmuExportOutputWidget(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent = 0);
  ~FmuExportOutputWidget();
  QProgressBar* getProgressBar() {return mpProgressBar;}
  QTabWidget* getGeneratedFilesTabWidget() {return mpGeneratedFilesTabWidget;}
  QProcess* getCompilationProcess() {return mpCompilationProcess;}
  void setCompilationProcessKilled(bool killed) {mIsCompilationProcessKilled = killed;}
  bool isCompilationProcessKilled() {return mIsCompilationProcessKilled;}
  bool isCompilationProcessRunning() {return mIsCompilationProcessRunning;}
  QProcess* getPostCompilationProcess() {return mpPostCompilationProcess;}
  void setPostCompilationProcessKilled(bool killed) {mIsPostCompilationProcessKilled = killed;}
  bool isPostCompilationProcessKilled() {return mIsPostCompilationProcessKilled;}
  bool isPostCompilationProcessRunning() {return mIsPostCompilationProcessRunning;}
  QProcess* getZipCompilationProcess() {return mpZipCompilationProcess;}
  void setZipCompilationProcessKilled(bool killed) {mIsZipCompilationProcessKilled = killed;}
  bool isZipCompilationProcessKilled() {return mIsZipCompilationProcessKilled;}
  bool isZipCompilationProcessRunning() {return mIsZipCompilationProcessRunning;}
  QString getFMUPath() {return mpFmuLocationPath;}
  void updateMessageTab(const QString &text);
  void updateMessageTabProgress();
  void compileModel();
private:
  QString mpFmuTmpPath;
  QString mpFMUName;
  QString mpFmuLocationPath;
  LibraryTreeItem *mpLibraryTreeItem;
  Label *mpProgressLabel;
  QProgressBar *mpProgressBar;
  QPushButton *mpCancelButton;
  QTabWidget *mpGeneratedFilesTabWidget;
  OutputPlainTextEdit *mpCompilationOutputTextBox;
  OutputPlainTextEdit *mpPostCompilationOutputTextBox;
  QProcess *mpCompilationProcess;
  bool mIsCompilationProcessKilled;
  bool mIsCompilationProcessRunning;
  QProcess *mpPostCompilationProcess;
  bool mIsPostCompilationProcessKilled;
  bool mIsPostCompilationProcessRunning;
  QProcess *mpZipCompilationProcess;
  bool mIsZipCompilationProcessKilled;
  bool mIsZipCompilationProcessRunning;
  void runPostCompilation();
  void postCompilationProcessFinishedHelper(int exitCode, QProcess::ExitStatus exitStatus);
  void writeCompilationOutput(QString output, QColor color);
  void writePostCompilationOutput(QString output, QColor color);
  void compilationProcessFinishedHelper(int exitCode, QProcess::ExitStatus exitStatus);
  void zipFMU();
  void ZipCompilationProcessFinishedHelper(int exitCode, QProcess::ExitStatus exitStatus);
  void setDefaults();
private slots:
  void compilationProcessStarted();
  void readCompilationStandardOutput();
  void readCompilationStandardError();
  void compilationProcessError(QProcess::ProcessError error);
  void compilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
  void postCompilationProcessStarted();
  void readPostCompilationStandardOutput();
  void readPostCompilationStandardError();
  void postCompilationProcessError(QProcess::ProcessError error);
  void postCompilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
  void ZipCompilationProcessStarted();
  void readZipCompilationStandardOutput();
  void readZipCompilationStandardError();
  void ZipCompilationProcessError(QProcess::ProcessError error);
  void ZipCompilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
public slots:
  void cancelCompilation();
signals:
  void updateText(const QString &text);
  void updateProgressBar(QProgressBar *pProgressBar);
};

#endif // FMUEXPORTOUTPUTWIDGET_H

