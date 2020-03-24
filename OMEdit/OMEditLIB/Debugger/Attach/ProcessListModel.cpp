/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include <QLibrary>
#include <QDebug>

#include "ProcessListModel.h"

#ifdef Q_OS_WIN
// Enable Win API of XP SP1 and later
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0502
#include <windows.h>
#include <tlhelp32.h>
#include <psapi.h>

/*!
  Resolve QueryFullProcessImageNameW out of kernel32.dll due to incomplete MinGW import libs and it not being present on Windows XP.
  */
static BOOL queryFullProcessImageName(HANDLE h, DWORD flags, LPWSTR buffer, DWORD *size)
{
  // Resolve required symbols from the kernel32.dll
  typedef BOOL (WINAPI *QueryFullProcessImageNameWProtoType) (HANDLE, DWORD, LPWSTR, PDWORD);
  static QueryFullProcessImageNameWProtoType queryFullProcessImageNameW = 0;
  if (!queryFullProcessImageNameW)
  {
    QLibrary kernel32Lib(QLatin1String("kernel32.dll"), 0);
    if (kernel32Lib.isLoaded() || kernel32Lib.load())
      queryFullProcessImageNameW = (QueryFullProcessImageNameWProtoType)kernel32Lib.resolve("QueryFullProcessImageNameW");
  }
  if (!queryFullProcessImageNameW)
    return FALSE;
  // Read out process
  return (*queryFullProcessImageNameW)(h, flags, buffer, size);
}

/*!
  Reads the process name.
  \param processId - the process to read.
  \return the process name.
  */
static QString imageName(DWORD processId)
{
  QString  rc;
  HANDLE handle = OpenProcess(PROCESS_QUERY_INFORMATION , FALSE, processId);
  if (handle == INVALID_HANDLE_VALUE)
    return rc;
  WCHAR buffer[MAX_PATH];
  DWORD bufSize = MAX_PATH;
  if (queryFullProcessImageName(handle, 0, buffer, &bufSize))
    rc = QString::fromUtf16(reinterpret_cast<const ushort*>(buffer));
  CloseHandle(handle);
  return rc;
}

/*!
  \class ProcessListModel
  \brief Contains the list of processes.
  */
/*!
  \param pParent -  the pointer to QObject
  */
ProcessListModel::ProcessListModel(QObject *pParent)
  : QAbstractItemModel(pParent), mSelfProcessId(GetCurrentProcessId())
{

}

/*!
  Returns the list of local processes.
  */
QList<ProcessItem> ProcessListModel::getLocalProcesses()
{
  QList<ProcessItem> processes;

  PROCESSENTRY32 pe;
  pe.dwSize = sizeof(PROCESSENTRY32);
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snapshot == INVALID_HANDLE_VALUE)
    return processes;

  for (bool hasNext = Process32First(snapshot, &pe); hasNext; hasNext = Process32Next(snapshot, &pe))
  {
    ProcessItem p;
    p.mProcessId = pe.th32ProcessID;
    // Image has the absolute path, but can fail.
    p.mProcessName = QString::fromWCharArray(pe.szExeFile);
    const QString image = imageName(pe.th32ProcessID);
    p.mProcessPath = image.isEmpty() ? QString::fromWCharArray(pe.szExeFile) : image;
    processes << p;
  }
  CloseHandle(snapshot);
  return processes;
}
#endif //Q_OS_WIN

#ifdef Q_OS_UNIX
#include <QProcess>
#include <QDir>
#include <signal.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>

/*!
  \class ProcessListModel
  \brief Contains the list of processes.
  */
/*!
  \param omcProcessId - the process Id of OMEdit's OMC instance.
  \param pParent -  the pointer to QObject
  */
ProcessListModel::ProcessListModel(QObject *pParent)
  : QAbstractItemModel(pParent), mSelfProcessId(getpid())
{

}

static bool isUnixProcessId(const QString &procname)
{
  for (int i = 0; i != procname.size(); ++i)
    if (!procname.at(i).isDigit())
      return false;
  return true;
}

/*!
  Get the  UNIX processes by reading "/proc". Default to ps if it does not exist.
  */
static const char procDirC[] = "/proc/";

static QList<ProcessItem> getLocalProcessesUsingProc(const QDir &procDir)
{
  QList<ProcessItem> processes;
  const QString procDirPath = QLatin1String(procDirC);
  const QStringList procIds = procDir.entryList();
  foreach (const QString &procId, procIds)
  {
    if (!isUnixProcessId(procId))
      continue;
    ProcessItem processItem;
    processItem.mProcessId = procId.toInt();
    const QString root = procDirPath + procId;
    QFile symLinkFile(root + QLatin1String("/exe"));
    QString exeFilePath = symLinkFile.symLinkTarget();
    // symLinkTarget resolves the /proc/123/exe and returns the actual absolute path of process
    // Use QFileInfo to extract the name of the process
    QFileInfo exeFileInfo (exeFilePath);
    processItem.mProcessName = exeFileInfo.fileName();
    QFile cmdLineFile(root + QLatin1String("/cmdline"));
    // process may have exited
    if (cmdLineFile.open(QIODevice::ReadOnly))
    {
      QList<QByteArray> tokens = cmdLineFile.readAll().split('\0');
      if (!tokens.isEmpty())
      {
        if (processItem.mProcessName.isEmpty())
          processItem.mProcessName = QString::fromLocal8Bit(tokens.front());
        foreach (const QByteArray &t, tokens)
        {
          if (!processItem.mProcessPath.isEmpty())
            processItem.mProcessPath.append(QLatin1Char(' '));
          processItem.mProcessPath.append(QString::fromLocal8Bit(t));
        }
      }
    }
    if (processItem.mProcessName.isEmpty())
    {
      QFile statFile(root + QLatin1String("/stat"));
      if (statFile.open(QIODevice::ReadOnly))
      {
        const QStringList data = QString::fromLocal8Bit(statFile.readAll()).split(QLatin1Char(' '));
        if (data.size() < 2)
          continue;
        processItem.mProcessName = data.at(1);
        processItem.mProcessPath = data.at(1); // PPID is element 3
        if (processItem.mProcessName.startsWith(QLatin1Char('(')) && processItem.mProcessName.endsWith(QLatin1Char(')')))
        {
          processItem.mProcessName.truncate(processItem.mProcessName.size() - 1);
          processItem.mProcessName.remove(0, 1);
        }
      }
    }
    if (!processItem.mProcessName.isEmpty())
      processes.push_back(processItem);
  }
  return processes;
}

/*!
  Get the UNIX processes by running ps
  */
static QList<ProcessItem> getLocalProcessesUsingPs()
{
  QList<ProcessItem> processes;
  QProcess psProcess;
  QStringList args;
  args << QLatin1String("-e") << QLatin1String("-o") << QLatin1String("pid,comm,args");
  psProcess.start(QLatin1String("ps"), args);
  psProcess.waitForFinished();
  QByteArray output = psProcess.readAllStandardOutput();
  // Split "457 /Users/foo.app arg1 arg2"
  const QStringList lines = QString::fromLocal8Bit(output).split(QLatin1Char('\n'));
  const int lineCount = lines.size();
  const QChar blank = QLatin1Char(' ');
  for (int l = 1; l < lineCount; l++) { // Skip header
    const QString line = lines.at(l).simplified();
    const int pidSep = line.indexOf(blank);
    const int cmdSep = pidSep != -1 ? line.indexOf(blank, pidSep + 1) : -1;
    if (cmdSep > 0) {
      const int argsSep = cmdSep != -1 ? line.indexOf(blank, cmdSep + 1) : -1;
      ProcessItem processItem;
      processItem.mProcessId = line.left(pidSep).toInt();
      processItem.mProcessPath = line.mid(cmdSep + 1);
      if (argsSep == -1)
        processItem.mProcessName = line.mid(cmdSep + 1);
      else
        processItem.mProcessName = line.mid(cmdSep + 1, argsSep - cmdSep -1);
      processes.push_back(processItem);
    }
  }
  return processes;
}

QList<ProcessItem> ProcessListModel::getLocalProcesses()
{
  const QDir procDir = QDir(QLatin1String(procDirC));
  return procDir.exists() ? getLocalProcessesUsingProc(procDir) : getLocalProcessesUsingPs();
}
#endif // Q_OS_UNIX

QString ProcessListModel::processIdAt(const QModelIndex &index) const
{
  if (index.isValid()) {
    return QString::number(mProcesses.at(index.row()).mProcessId);
  }
  return "";
}

/*!
  Refreshes the list of processes.
  */
void ProcessListModel::updateProcessList()
{
  if (!mProcesses.isEmpty()) {
    beginRemoveRows(QModelIndex(), 0, mProcesses.count() - 1);
    mProcesses.clear();
    endRemoveRows();
  }

  QList<ProcessItem> processes = getLocalProcesses();
  if (!processes.isEmpty()) {
    beginInsertRows(QModelIndex(), 0, processes.count() - 1);
    mProcesses = processes;
    endInsertRows();
  }
}

QModelIndex ProcessListModel::index(int row, int column, const QModelIndex &parent) const
{
  return hasIndex(row, column, parent) ? createIndex(row, column) : QModelIndex();
}

int ProcessListModel::rowCount(const QModelIndex &parent) const
{
  return parent.isValid() ? 0 : mProcesses.count();
}

int ProcessListModel::columnCount(const QModelIndex &parent) const
{
  Q_UNUSED(parent);
  return 2;
}

QVariant ProcessListModel::headerData(int section, Qt::Orientation orientation, int role) const
{
  if (orientation != Qt::Horizontal || role != Qt::DisplayRole || section < 0 || section >= columnCount())
    return QVariant();
  return section == 0? tr("Process ID") : tr("Name");
}

QVariant ProcessListModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid() || index.row() >= rowCount(index.parent()) || index.column() >= columnCount())
    return QVariant();

  const ProcessItem &processItem = mProcesses.at(index.row());
  switch (index.column())
  {
    case 0:
      switch (role)
      {
        case Qt::DisplayRole:
        case Qt::ToolTipRole:
          return processItem.mProcessId;
        default:
          return QVariant();
      }
    case 1:
      switch (role)
      {
        case Qt::DisplayRole:
          return processItem.mProcessName;
        case Qt::ToolTipRole:
          return processItem.mProcessPath;
        default:
          return QVariant();
      }
    default:
      return QVariant();
  }
}

Qt::ItemFlags ProcessListModel::flags(const QModelIndex &index) const
{
  Qt::ItemFlags flags = QAbstractItemModel::flags(index);

  int processId = mProcesses.at(index.row()).mProcessId;
  if (index.isValid() && (processId == mSelfProcessId)) {
    flags &= ~(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
  }
  return flags;
}

QModelIndex ProcessListModel::parent(const QModelIndex &) const
{
  return QModelIndex();
}

bool ProcessListModel::hasChildren(const QModelIndex &parent) const
{
  if (!parent.isValid())
    return rowCount(parent) > 0 && columnCount(parent) > 0;
  return false;
}

/*!
  \class ProcessListFilterModel
  \brief Interface for sorting and filtering the processes.
  */
ProcessListFilterModel::ProcessListFilterModel()
  : QSortFilterProxyModel(0)
{
  setFilterCaseSensitivity(Qt::CaseInsensitive);
  setDynamicSortFilter(true);
  setFilterKeyColumn(-1);
}

bool ProcessListFilterModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
  const QString l = sourceModel()->data(left).toString();
  const QString r = sourceModel()->data(right).toString();
  if (left.column() == 0)
    return l.toInt() < r.toInt();
  return l < r;
}
