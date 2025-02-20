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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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

#ifndef UTILITIES_H
#define UTILITIES_H

#include <QApplication>
#include <QSplashScreen>
#include <QStatusBar>
#include <QMdiArea>
#include <QLineEdit>
#include <QThread>
#include <QToolButton>
#include <QComboBox>
#include <QPushButton>
#include <QFile>
#include <QLabel>
#include <QDoubleSpinBox>
#include <QCheckBox>
#include <QVariant>
#include <QDebug>
#include <QPlainTextEdit>
#include <QTextEdit>
#include <QProcess>
#include <QSettings>
#include <QFileIconProvider>
#include <QGroupBox>
#include <QListWidget>
#include <QListWidgetItem>
#include <QScrollArea>
#include <QScrollBar>

#if defined(_WIN32)
#include <windows.h>
#include <tlhelp32.h>
#endif

class OMCProxy;

class SplashScreen : public QSplashScreen
{
  Q_OBJECT
private:
  SplashScreen() : QSplashScreen() {}

  static SplashScreen *mpInstance;
public:
  static SplashScreen *instance();
public slots:
  void showMessage(const QString &message, int alignment = Qt::AlignLeft, const QColor &color = Qt::black)
  {
    QSplashScreen::showMessage(message, alignment, color);
    // Call repaint() to get the immediate update. Calling repaint() is better than qApp->processEvents() which processes all pending events.
    repaint();
  }
};

class StatusBar : public QStatusBar
{
  Q_OBJECT
public:
  StatusBar() : QStatusBar() {}
public slots:
  void showMessage(const QString &message, int timeout = 0)
  {
    QStatusBar::showMessage(message, timeout);
    /* QStatusBar::showMessage calls update() which schedules a paint event for processing when Qt returns to the main event loop
     * so we call repaint() to get the immediate update. Calling repaint() is better than qApp->processEvents() which processes all pending events.
     */
    repaint();
  }
};

//! @brief Used to create platform independent sleep for the application.
class Sleep : public QThread
{
  Q_OBJECT
public:
  Sleep() {}
  ~Sleep() {}
  static void sleep(unsigned long secs) {QThread::sleep(secs);}
  static void msleep(unsigned long msecs) {QThread::msleep(msecs);}
protected:
  void run() {}
};

class TreeSearchFilters : public QWidget
{
  Q_OBJECT
public:
  TreeSearchFilters(QWidget *pParent = 0);
  QLineEdit* getFilterTextBox() {return mpFilterTextBox;}
  QTimer* getFilterTimer() {return mpFilterTimer;}
  QToolButton* getScrollToActiveButton() {return mpScrollToActiveButton;}
  QToolButton* getExpandAllButton() {return mpExpandAllButton;}
  QToolButton* getCollapseAllButton() {return mpCollapseAllButton;}
  QComboBox* getSyntaxComboBox() {return mpSyntaxComboBox;}
  QCheckBox* getCaseSensitiveCheckBox() {return mpCaseSensitiveCheckBox;}

  bool eventFilter(QObject *pObject, QEvent *pEvent);
private:
  QLineEdit *mpFilterTextBox;
  QTimer *mpFilterTimer;
  QToolButton *mpScrollToActiveButton;
  QToolButton *mpExpandAllButton;
  QToolButton *mpCollapseAllButton;
  QToolButton *mpShowHideButton;
  QWidget *mpFiltersWidget;
  QComboBox *mpSyntaxComboBox;
  QCheckBox *mpCaseSensitiveCheckBox;
private slots:
  void showHideFilters(bool On);
signals:
  void clearFilter(const QString &);
};

class FileDataNotifier : public QThread
{
  Q_OBJECT
public:
  FileDataNotifier(const QString fileName);
  void exit(int retcode = 0);
private:
  QFile mFile;
  bool mStop;
protected:
  void run();
public slots:
  void start(Priority = InheritPriority);
signals:
  void sendData(QString data);
};

/*!
 * \class Label
 * \brief Creates a QLabel with elidable text. The default elide mode is Qt::ElideNone. Allows text selection via mouse.
 */
class Label : public QLabel
{
public:
  Label(QWidget *parent = 0, Qt::WindowFlags flags = Qt::WindowFlags());
  Label(const QString &text, QWidget *parent = 0, Qt::WindowFlags flags = Qt::WindowFlags());
  Qt::TextElideMode elideMode() const {return mElideMode;}
  void setElideMode(Qt::TextElideMode elideMode) {mElideMode = elideMode;}
  virtual QSize minimumSizeHint() const override;
  virtual QSize sizeHint() const override;
  void setText(const QString &text);
private:
  Qt::TextElideMode mElideMode;
  QString mText;

  QString elidedText() const;
protected:
  virtual void resizeEvent(QResizeEvent *event) override;
};

/* ticket:10458 ticket:13591
 * Disable the wheel event of combobox, spinbox and doublespinbox
 * Set the focus to Qt::StrongFocus instead of Qt::WheelFocus
 * Ignore the wheel event if it doesn't have the focus.
 */

/*!
 * \class ComboBox
 * \brief Creates a QComboBox.
 */
class ComboBox : public QComboBox
{
  Q_OBJECT
public:
  ComboBox(QWidget *parent = nullptr);
protected:
  virtual void wheelEvent(QWheelEvent *event) override;
};

/*!
 * \class SpinBox
 * \brief Creates a QSpinBox.
 */
class SpinBox : public QSpinBox
{
  Q_OBJECT
public:
  SpinBox(QWidget *parent = 0);
protected:
  virtual void wheelEvent(QWheelEvent *event) override;
};

/*!
 * \class DoubleSpinBox
 * \brief Creates a QDoubleSpinBox.
 */
class DoubleSpinBox : public QDoubleSpinBox
{
  Q_OBJECT
public:
  DoubleSpinBox(QWidget *parent = 0);
protected:
  virtual void wheelEvent(QWheelEvent *event) override;
};

/*!
 * \class FixedCheckBox
 * \brief Creates a custom QCheckBox to represent the fixed modifier of components.
 */
class FixedCheckBox : public QCheckBox
{
  Q_OBJECT
private:
  bool mDefaultValue;
  bool mInheritedValue;
  bool mFixedState;
public:
  FixedCheckBox(QWidget *parent = 0);
  void setTickState(bool defaultValue, bool fixedState);
  bool isDefaultValue() {return mDefaultValue;}
  bool getInheritedValue() const {return mInheritedValue;}
  QString getTickStateString() const;
protected:
  virtual void paintEvent(QPaintEvent *event) override;
};

//! @struct RecentFile
/*! \brief It contains the recently opened file name and its encoding.
 * We must register this struct as a meta type since we need to use it as a QVariant.
 * This is used to store the recent files information in omedit.ini file.
 * The QDataStream also needed to be defined for this struct.
 */
struct RecentFile
{
  QString fileName;
  QString encoding;
  operator QVariant() const
  {
    return QVariant::fromValue(*this);
  }
};
Q_DECLARE_METATYPE(RecentFile)

inline QDataStream& operator<<(QDataStream& out, const RecentFile& recentFile)
{
  out << recentFile.fileName;
  out << recentFile.encoding;
  return out;
}

inline QDataStream& operator>>(QDataStream& in, RecentFile& recentFile)
{
  in >> recentFile.fileName;
  in >> recentFile.encoding;
  return in;
}

inline bool operator==(const RecentFile& lhs, const RecentFile& rhs)
{
  return lhs.fileName == rhs.fileName;
}

//! @struct FindTextOM
/*! \brief It contains the recently searched text from find/replace dialog .
 * We must register this struct as a meta type since we need to use it as a QVariant.
 * This is used to store the recent texts information in omedit.ini file.
 * The QDataStream also needed to be defined for this struct.
 */
struct FindTextOM
{
  QString text;
  operator QVariant() const
  {
    return QVariant::fromValue(*this);
  }
};
Q_DECLARE_METATYPE(FindTextOM)

inline QDataStream& operator<<(QDataStream& out, const FindTextOM& findText)
{
  out << findText.text;
  return out;
}

inline QDataStream& operator>>(QDataStream& in, FindTextOM& findText)
{
  in >> findText.text;
  return in;
}

inline bool operator==(const FindTextOM& lhs, const FindTextOM& rhs)
{
  return lhs.text == rhs.text;
}

//! @struct DebuggerConfiguration
/*! \brief It contains the debugger configuration settings  from debugger configuration dialog .
 * We must register this struct as a meta type since we need to use it as a QVariant.
 * This is used to store the debugger configuration settings information in omedit.ini file.
 * The QDataStream also needed to be defined for this struct.
 */
struct DebuggerConfiguration
{
  QString name;
  QString program;
  QString workingDirectory;
  QString GDBPath;
  QString arguments;
  operator QVariant() const
  {
    return QVariant::fromValue(*this);
  }
};
Q_DECLARE_METATYPE(DebuggerConfiguration)

inline QDataStream& operator<<(QDataStream& out, const DebuggerConfiguration& configurationSettings)
{
  out << configurationSettings.name;
  out << configurationSettings.program;
  out << configurationSettings.workingDirectory;
  out << configurationSettings.GDBPath;
  out << configurationSettings.arguments;
  return out;
}

inline QDataStream& operator>>(QDataStream& in, DebuggerConfiguration& configurationSettings)
{
  in >> configurationSettings.name;
  in >> configurationSettings.program;
  in >> configurationSettings.workingDirectory;
  in >> configurationSettings.GDBPath;
  in >> configurationSettings.arguments;
  return in;
}

inline bool operator==(const DebuggerConfiguration& lhs, const DebuggerConfiguration& rhs)
{
  return lhs.name == rhs.name;
}

class PreviewPlainTextEdit : public QPlainTextEdit
{
  Q_OBJECT
public:
  PreviewPlainTextEdit(QWidget *parent = 0);
private:
  QTextCharFormat mParenthesesMatchFormat;
  QTextCharFormat mParenthesesMisMatchFormat;

  void highlightCurrentLine();
  void highlightParentheses();
public slots:
  void updateHighlights();
};

class ListWidgetItem : public QListWidgetItem
{
public:
  ListWidgetItem(QString text, QColor color, QListWidget *pParentListWidget);
  QColor getColor() {return mColor;}
  void setColor(QColor color) {mColor = color;}
private:
  QColor mColor;
};

/*!
 * \brief The VerticalScrollArea class
 * A scroll area with vertical bar and adjustment of width
 * See: https://forum.qt.io/topic/13374/solved-qscrollarea-vertical-scroll-only
 */
class VerticalScrollArea : public QScrollArea
{
  Q_OBJECT
public:
  VerticalScrollArea()
  {
    setWidgetResizable(true);
    setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
    setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
  }

  virtual bool eventFilter(QObject *o, QEvent *e) override
  {
    if (o && o == widget() && e->type() == QEvent::Resize) {
      setMinimumWidth(widget()->minimumSizeHint().width() + verticalScrollBar()->width());
    }
    return QScrollArea::eventFilter(o, e);
  }
};

class QDetachableProcess : public QProcess
{
  Q_OBJECT
public:
  QDetachableProcess(QObject *pParent = 0);

  void start(const QString &program, const QStringList &arguments, OpenMode mode = ReadWrite);
#if QT_VERSION < QT_VERSION_CHECK(5, 15, 0)
  void start(const QString &command, OpenMode mode = ReadWrite);
#endif
};

class JsonDocument : public QObject
{
  Q_OBJECT
public:
  JsonDocument(QObject *pParent = 0);
  bool parse(const QString &fileName);
  bool parse(const QByteArray &jsonData);

  QVariant result;
  QString errorString;
};

class VariableNode
{
public:
  VariableNode(const QVector<QVariant> &variableNodeData);
  ~VariableNode();
  QVector<QVariant> mVariableNodeData;
  bool mEditable;
  QString mVariability;
  QHash<QString, VariableNode*> mChildren;

  static VariableNode* findVariableNode(const QString &name, VariableNode *pParentVariableNode);
};

namespace Utilities {

  enum LineEndingMode {
    CRLFLineEnding = 0,
    LFLineEnding = 1,
    NativeLineEnding =
#if defined(_WIN32)
    CRLFLineEnding,
#else
    LFLineEnding
#endif
  };

  enum BomMode {
    AlwaysAddBom = 0,
    KeepBom = 1,
    AlwaysDeleteBom = 2
  };

  QString escapeForHtmlNonSecure(const QString &str);
  QString& tempDirectory();
  QSettings* getApplicationSettings();
  QString generateHash(const QString &input);
  qreal convertUnit(qreal value, qreal offset, qreal scaleFactor);
  bool isValueLiteralConstant(QString value);
  bool isValueScalarLiteralConstant(QString value);
  QString arrayExpressionUnitConversion(OMCProxy *pOMCProxy, QString modifierValue, QString fromUnit, QString toUnit);
  Label* getHeadingLabel(QString heading);
  QFrame* getHeadingLine();
  bool detectBOM(QString fileName);
  QTextCharFormat getParenthesesMatchFormat();
  QTextCharFormat getParenthesesMisMatchFormat();
  void highlightCurrentLine(QPlainTextEdit *pPlainTextEdit);
  void highlightParentheses(QPlainTextEdit *pPlainTextEdit, QTextCharFormat parenthesesMatchFormat, QTextCharFormat parenthesesMisMatchFormat);
  qint64 getProcessId(QProcess *pProcess);
  QString formatExitCode(int code);
#if defined(_WIN32)
  void killProcessTreeWindows(DWORD myprocID);
#endif
  bool isCFile(QString extension);
  bool isModelicaFile(QString extension);
  QString getGDBPath();

  namespace FileIconProvider {
    class FileIconProviderImplementation : public QFileIconProvider
    {
    public:
      FileIconProviderImplementation();
      QIcon icon(const QFileInfo &info);
      using QFileIconProvider::icon;
      // Mapping of file suffix to icon.
      QHash<QString, QIcon> mIconsHash;
      QIcon mUnknownFileIcon;
    };
    // Access to the single instance
    QFileIconProvider *iconProvider();
    QIcon icon(const QFileInfo &info);
  } // namespace FileIconProvider

  bool containsWord(QString text, int index, QString keyword, bool checkParenthesis = false);
  float maxi(float arr[],int n);
  float mini(float arr[], int n);
  QList<QPointF> liangBarskyClipper(float xmin, float ymin, float xmax, float ymax, float x1, float y1, float x2, float y2);
  void removeDirectoryRecursively(QString path);
  qreal mapToCoordinateSystem(qreal value, qreal startA, qreal endA, qreal startB, qreal endB);
  QStringList variantListToStringList(const QVariantList lst);
  void addDefaultDisplayUnit(const QString &unit, QStringList &displayUnit);
  QString convertUnitToSymbol(const QString &displayUnit);
  QString convertSymbolToUnit(const QString &symbol);
  QRectF adjustSceneRectangle(const QRectF sceneRectangle, const qreal factor);
  void setToolTip(QComboBox *pComboBox, const QString &description, const QStringList &optionsDescriptions);
  bool isMultiline(const QString &text);
  QMap<QString, QLocale> supportedLanguages();
} // namespace Utilities

#endif // UTILITIES_H
