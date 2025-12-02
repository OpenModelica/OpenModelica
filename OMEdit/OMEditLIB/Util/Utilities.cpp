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

#include "Utilities.h"
#include "Helper.h"
#include "StringHandler.h"
#include "OMC/OMCProxy.h"
#include "Modeling/ItemDelegate.h"
#include "Editors/BaseEditor.h"
#include "OMPlot.h"

#include <QApplication>
#include <QCryptographicHash>
#include <QByteArray>
#include <QGridLayout>
#include <QStylePainter>
#include <QPainter>
#include <QColorDialog>
#include <QDir>
#include <QRegExp>

extern "C" {
extern const char* System_openModelicaPlatform();
}

SplashScreen *SplashScreen::mpInstance = 0;

SplashScreen *SplashScreen::instance()
{
  if (!mpInstance) {
    mpInstance = new SplashScreen;
  }
  return mpInstance;
}

TreeSearchFilters::TreeSearchFilters(QWidget *pParent)
  : QWidget(pParent)
{
  // create the filter text box
  mpFilterTextBox = new QLineEdit;
  mpFilterTextBox->installEventFilter(this);
  mpFilterTextBox->setClearButtonEnabled(true);
  connect(this, SIGNAL(clearFilter(QString)), mpFilterTextBox, SIGNAL(textEdited(QString)));
  // filter timer
  mpFilterTimer = new QTimer(this);
  mpFilterTimer->setSingleShot(true);
  mpScrollToActiveButton = new QToolButton;
  QString scrollToActiveButtonText = tr("Scroll to Active");
  mpScrollToActiveButton->setText(scrollToActiveButtonText);
  mpScrollToActiveButton->setIcon(QIcon(":/Resources/icons/step-into.svg"));
  mpScrollToActiveButton->setToolTip(scrollToActiveButtonText);
  mpScrollToActiveButton->setAutoRaise(true);
  mpScrollToActiveButton->hide();
  // expand all button
  mpExpandAllButton = new QToolButton;
  mpExpandAllButton->setText(Helper::expandAll);
  mpExpandAllButton->setIcon(QIcon(":/Resources/icons/bottom.svg"));
  mpExpandAllButton->setToolTip(Helper::expandAll);
  mpExpandAllButton->setAutoRaise(true);
  // collapse all button
  mpCollapseAllButton = new QToolButton;
  mpCollapseAllButton->setText(Helper::collapseAll);
  mpCollapseAllButton->setIcon(QIcon(":/Resources/icons/top.svg"));
  mpCollapseAllButton->setToolTip(Helper::collapseAll);
  mpCollapseAllButton->setAutoRaise(true);
  // show hide button
  mpShowHideButton = new QToolButton;
  QString showHideButtonText = tr("Show/hide filters");
  mpShowHideButton->setText(showHideButtonText);
  mpShowHideButton->setIcon(QIcon(":/Resources/icons/down.svg"));
  mpShowHideButton->setToolTip(showHideButtonText);
  mpShowHideButton->setAutoRaise(true);
  mpShowHideButton->setCheckable(true);
  connect(mpShowHideButton, SIGNAL(toggled(bool)), SLOT(showHideFilters(bool)));
  // filters widget
  mpFiltersWidget = new QWidget;
  // create the case sensitivity checkbox
  mpCaseSensitiveCheckBox = new QCheckBox(tr("Case Sensitive"));
  // create the search syntax combobox
  mpSyntaxComboBox = new QComboBox;
  QStringList syntaxDescriptions;
  syntaxDescriptions << tr("A rich Perl-like pattern matching syntax.")
                      << tr("A simple pattern matching syntax similar to that used by shells (command interpreters) for \"file globbing\".")
                      << tr("Fixed string matching.");
  mpSyntaxComboBox->addItem(tr("Regular Expression"), QRegExp::RegExp);
  mpSyntaxComboBox->addItem(tr("Wildcard"), QRegExp::Wildcard);
  mpSyntaxComboBox->addItem(tr("Fixed String"), QRegExp::FixedString);
  Utilities::setToolTip(mpSyntaxComboBox, "Filters", syntaxDescriptions);
  // create the layout
  QGridLayout *pFiltersWidgetLayout = new QGridLayout;
  pFiltersWidgetLayout->setContentsMargins(0, 0, 0, 0);
  pFiltersWidgetLayout->setAlignment(Qt::AlignTop);
  pFiltersWidgetLayout->addWidget(mpCaseSensitiveCheckBox, 0, 0);
  pFiltersWidgetLayout->addWidget(mpSyntaxComboBox, 0, 1);
  mpFiltersWidget->setLayout(pFiltersWidgetLayout);
  mpFiltersWidget->hide();
  // create the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setSpacing(0);
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpFilterTextBox, 0, 0);
  pMainLayout->addWidget(mpScrollToActiveButton, 0, 1);
  pMainLayout->addWidget(mpExpandAllButton, 0, 2);
  pMainLayout->addWidget(mpCollapseAllButton, 0, 3);
  pMainLayout->addWidget(mpShowHideButton, 0, 4);
  pMainLayout->addWidget(mpFiltersWidget, 1, 0, 1, 5);
  setLayout(pMainLayout);
}

/*!
 * \brief TreeSearchFilters::eventFilter
 * Handles the ESC key press for filter text box
 * \param pObject
 * \param pEvent
 * \return
 */
bool TreeSearchFilters::eventFilter(QObject *pObject, QEvent *pEvent)
{
  /* Ticket #3987
   * Clear contents of filter field by clicking ESC key.
   */
  QLineEdit *pFilterTextBox = qobject_cast<QLineEdit*>(pObject);
  if (pFilterTextBox && pEvent->type() == QEvent::KeyPress) {
    QKeyEvent *pKeyEvent = static_cast<QKeyEvent*>(pEvent);
    if (pKeyEvent && pKeyEvent->key() == Qt::Key_Escape) {
      pFilterTextBox->clear();
      /* Ticket #5998
       * Emit clearFilter signal which calls textEdited signal of mpFilterTextBox to reset filter.
       */
      emit clearFilter("");
      return true;
    }
  }
  return QWidget::eventFilter(pObject, pEvent);
}

void TreeSearchFilters::showHideFilters(bool On)
{
  if (On) {
    mpFiltersWidget->show();
  } else {
    mpFiltersWidget->hide();
  }
}

/*!
 * \class FileDataNotifier
 * \brief Looks for new data on file. When data is available emits bytesAvailable SIGNAL.
 * \brief FileDataNotifier::FileDataNotifier
 * \param fileName
 */
FileDataNotifier::FileDataNotifier(const QString fileName)
{
  mFile.setFileName(fileName);
  mStop = false;
}

/*!
 * \brief FileDataNotifier::exit
 * Reimplementation of QThread::exit()
 * Sets mStop to true.
 * \param retcode
 */
void FileDataNotifier::exit(int retcode)
{
  mStop = true;
  QThread::exit(retcode);
}

/*!
 * \brief FileDataNotifier::run
 * Reimplentation of QThread::run().
 * Looks for when is new data available for reading on file.
 * Emits the bytesAvailable SIGNAL.
 */
void FileDataNotifier::run()
{
  if (mFile.open(QIODevice::ReadOnly)) {
    while (!mStop) {
      // if file doesn't exist then break.
      if (!mFile.exists()) {
        break;
      }
      // if file has bytes available to read.
      if (mFile.bytesAvailable() > 0) {
        emit sendData(QString(mFile.readAll()));
      }
      Sleep::sleep(1);
    }
  }
}

/*!
 * \brief FileDataNotifier::start
 * Reimplementation of QThread::start()
 * Sets mStop to false.
 * \param priority
 */
void FileDataNotifier::start(Priority priority)
{
  mStop = false;
  QThread::start(priority);
}

Label::Label(QWidget *parent, Qt::WindowFlags flags)
  : QLabel(parent, flags), mElideMode(Qt::ElideNone), mText("")
{
  setTextInteractionFlags(Qt::TextSelectableByMouse);
}

Label::Label(const QString &text, QWidget *parent, Qt::WindowFlags flags)
  : QLabel(text, parent, flags), mElideMode(Qt::ElideNone), mText(text)
{
  setTextInteractionFlags(Qt::TextSelectableByMouse);
  setToolTip(text);
}

QSize Label::minimumSizeHint() const
{
#if QT_VERSION >= QT_VERSION_CHECK(5, 15, 0)
  if (!pixmap(Qt::ReturnByValue).isNull() || mElideMode == Qt::ElideNone) {
#else // QT_VERSION_CHECK
  if (pixmap() != NULL || mElideMode == Qt::ElideNone) {
#endif // QT_VERSION_CHECK
    return QLabel::minimumSizeHint();
  }
  const QFontMetrics &fm = fontMetrics();
#if QT_VERSION >= QT_VERSION_CHECK(5, 11, 0)
  QSize size(fm.horizontalAdvance("..."), fm.height()+5);
#else // QT_VERSION_CHECK
  QSize size(fm.width("..."), fm.height()+5);
#endif // QT_VERSION_CHECK
  // use minimum size width 200 if mUseMinimumSize is true
  // this is used in parameter dialogs
  if (mUseMinimumSize && !mText.isEmpty()) {
    size.setWidth(qMax(size.width(), 200));
  }
  return size;
}

QSize Label::sizeHint() const
{
#if QT_VERSION >= QT_VERSION_CHECK(5, 15, 0)
  if (!pixmap(Qt::ReturnByValue).isNull() || mElideMode == Qt::ElideNone) {
#else // QT_VERSION_CHECK
  if (pixmap() != NULL || mElideMode == Qt::ElideNone) {
#endif // QT_VERSION_CHECK
    return QLabel::sizeHint();
  }
  const QFontMetrics& fm = fontMetrics();
#if QT_VERSION >= QT_VERSION_CHECK(5, 11, 0)
  QSize size(fm.horizontalAdvance(mText), fm.height()+5);
#else // QT_VERSION_CHECK
  QSize size(fm.width(mText), fm.height()+5);
#endif // QT_VERSION_CHECK
  return size;
}

void Label::setText(const QString &text)
{
  mText = text;
  setToolTip(text);
  const QString text1 = elidedText();
  // if text is empty OR if we get "..." i.e., QChar(0x2026) as text
  if (text1.isEmpty() || text1.compare(QChar(0x2026)) == 0) {
    QLabel::setText(mText);
  } else {
    QLabel::setText(text1);
  }
}

QString Label::elidedText() const
{
  if (mElideMode != Qt::ElideNone) {
    return fontMetrics().elidedText(mText, mElideMode, size().width());
  } else {
    return mText;
  }
}

void Label::resizeEvent(QResizeEvent *event)
{
  QLabel::resizeEvent(event);
  QLabel::setText(elidedText());
}

ComboBox::ComboBox(QWidget *parent)
  : QComboBox(parent)
{
  setFocusPolicy(Qt::StrongFocus);
}

/*!
 * \brief ComboBox::addElidedItem
 * Adds an item with elided text if it exceeds maximum width.
 * Sets the full text as tooltip.
 * \param text
 * \param userData
 */
void ComboBox::addElidedItem(const QString &text, const QVariant &userData)
{
  QFontMetrics fm = fontMetrics();
  // use elided text for the item with maximum width of 500 pixels
  const QString elidedText = fm.elidedText(text, Qt::ElideMiddle, 500);
  addItem(elidedText, userData);
  setItemData(count() - 1, text, Qt::ToolTipRole);
}

void ComboBox::wheelEvent(QWheelEvent *event)
{
  if (!hasFocus()) {
    event->ignore();
  } else {
    QComboBox::wheelEvent(event);
  }
}

SpinBox::SpinBox(QWidget *parent)
  : QSpinBox(parent)
{
  setFocusPolicy(Qt::StrongFocus);
}

void SpinBox::wheelEvent(QWheelEvent *event)
{
  if (!hasFocus()) {
    event->ignore();
  } else {
    QSpinBox::wheelEvent(event);
  }
}

DoubleSpinBox::DoubleSpinBox(QWidget *parent)
  : QDoubleSpinBox(parent)
{
  setFocusPolicy(Qt::StrongFocus);
}

void DoubleSpinBox::wheelEvent(QWheelEvent *event)
{
  if (!hasFocus()) {
    event->ignore();
  } else {
    QDoubleSpinBox::wheelEvent(event);
  }
}

FixedCheckBox::FixedCheckBox(QWidget *parent)
 : QCheckBox(parent)
{
  setCheckable(false);
  mDefaultValue = false;
  mInheritedValue = false;
  mFixedState = false;
}

void FixedCheckBox::setTickState(bool defaultValue, bool fixedState)
{
  mDefaultValue = defaultValue;
  if (mDefaultValue) {
    mInheritedValue = fixedState;
  } else {
    mFixedState = fixedState;
  }
}

QString FixedCheckBox::getTickStateString() const
{
  if (mDefaultValue) {
    return "";
  } else if (mFixedState) {
    return "true";
  } else {
    return "false";
  }
}

/*!
  Reimplementation of QCheckBox::paintEvent.\n
  Draws a custom checkbox suitable for fixed modifier.
  */
void FixedCheckBox::paintEvent(QPaintEvent *event)
{
  Q_UNUSED(event);
  QStylePainter p(this);
  QStyleOptionButton opt;
  opt.initFrom(this);
  if (mDefaultValue) {
    p.setBrush(QColor(225, 225, 225));
  } else {
    p.setBrush(Qt::white);
  }
  p.drawRect(opt.rect.adjusted(0, 0, -1, -1));
  // if is checked then draw a tick
  if ((!mDefaultValue && mFixedState) || (mDefaultValue && mInheritedValue)) {
    p.setRenderHint(QPainter::Antialiasing);
    QPen pen = p.pen();
    pen.setWidthF(1.5);
    p.setPen(pen);
    QVector<QPoint> lines;
    lines << QPoint(opt.rect.left() + 3, opt.rect.center().y());
    lines << QPoint(opt.rect.center().x() - 1, opt.rect.bottom() - 3);
    lines << QPoint(opt.rect.center().x() - 1, opt.rect.bottom() - 3);
    lines << QPoint(opt.rect.width() - 3, opt.rect.top() + 3);
    p.drawLines(lines);
  }
}

PreviewPlainTextEdit::PreviewPlainTextEdit(QWidget *parent)
 : QPlainTextEdit(parent)
{
  QTextDocument *pTextDocument = document();
  pTextDocument->setDocumentMargin(2);
  BaseEditorDocumentLayout *pModelicaTextDocumentLayout = new BaseEditorDocumentLayout(pTextDocument);
  pTextDocument->setDocumentLayout(pModelicaTextDocumentLayout);
  setDocument(pTextDocument);
  // parentheses matcher
  mParenthesesMatchFormat = Utilities::getParenthesesMatchFormat();
  mParenthesesMisMatchFormat = Utilities::getParenthesesMisMatchFormat();

  updateHighlights();
  connect(this, SIGNAL(cursorPositionChanged()), this, SLOT(updateHighlights()));
}

/*!
 * \brief PreviewPlainTextEdit::highlightCurrentLine
 * Hightlights the current line.
 */
void PreviewPlainTextEdit::highlightCurrentLine()
{
  Utilities::highlightCurrentLine(this);
}

/*!
 * \brief PreviewPlainTextEdit::highlightParentheses
 * Highlights the matching parentheses.
 */
void PreviewPlainTextEdit::highlightParentheses()
{
  Utilities::highlightParentheses(this, mParenthesesMatchFormat, mParenthesesMisMatchFormat);
}

void PreviewPlainTextEdit::updateHighlights()
{
  QList<QTextEdit::ExtraSelection> selections;
  setExtraSelections(selections);
  highlightCurrentLine();
  highlightParentheses();
}

ListWidgetItem::ListWidgetItem(QString text, QColor color, QListWidget *pParentListWidget)
  : QListWidgetItem(pParentListWidget)
{
  setText(text);
  mColor = color;
  setForeground(mColor);
}

/*!
 * \brief QDetachableProcess::QDetachableProcess
 * Implementation from https://stackoverflow.com/questions/42051405/qprocess-with-cmd-command-does-not-result-in-command-line-window
 * \param pParent
 */
QDetachableProcess::QDetachableProcess(QObject *pParent)
  : QProcess(pParent)
{
#ifdef Q_OS_WIN
  setCreateProcessArgumentsModifier([](QProcess::CreateProcessArguments *args) {
    args->flags |= CREATE_NEW_CONSOLE;
    args->startupInfo->dwFlags &=~ STARTF_USESTDHANDLES;
  });
#endif
}

/*!
 * \brief QDetachableProcess::start
 * Starts a process and detaches from it.
 * \param program
 * \param arguments
 * \param mode
 */
void QDetachableProcess::start(const QString &program, const QStringList &arguments, QIODevice::OpenMode mode)
{
  QProcess::start(program, arguments, mode);
  waitForStarted();
  setProcessState(QProcess::NotRunning);
}

#if QT_VERSION < QT_VERSION_CHECK(5, 15, 0)
/*!
 * \brief QDetachableProcess::start
 * Starts a process and detaches from it.
 * \param command
 * \param mode
 */
void QDetachableProcess::start(const QString &command, QIODevice::OpenMode mode)
{
  QProcess::start(command, mode);
  waitForStarted();
  setProcessState(QProcess::NotRunning);
}
#endif


JsonDocument::JsonDocument(QObject *pParent)
  : QObject(pParent)
{
  result.clear();
  errorString = "";
}

bool JsonDocument::parse(const QString &fileName)
{
  bool success = true;
  QFile file(fileName);
  if (file.exists()) {
    if (file.open(QIODevice::ReadOnly)) {
      QJsonParseError jsonParserError;
      QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &jsonParserError);
      if (doc.isNull()) {
        errorString = QString("Failed to parse file %1 with error %2").arg(file.fileName(), jsonParserError.errorString());
        success = false;
      } else {
        result = doc.toVariant();
      }
      file.close();
    } else {
      errorString = GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg(file.fileName(), file.errorString());
      success = false;
    }
  }
  return success;
}

bool JsonDocument::parse(const QByteArray &jsonData)
{
  bool success = true;
  QString msg("Failed to parse json %1 with error %2");
  QJsonParseError jsonParserError;
  QJsonDocument doc = QJsonDocument::fromJson(jsonData, &jsonParserError);
  if (doc.isNull()) {
    errorString = QString(msg).arg(jsonData, jsonParserError.errorString());
    success = false;
  } else {
    result = doc.toVariant();
  }
  return success;
}

VariableNode::VariableNode(const QVector<QVariant> &variableNodeData)
{
  mVariableNodeData = variableNodeData;
  mEditable = false;
  mVariability = "";
  mChildren.clear();
}

VariableNode::~VariableNode()
{
  qDeleteAll(mChildren);
  mChildren.clear();
}

VariableNode* VariableNode::findVariableNode(const QString &name, VariableNode *pParentVariableNode)
{
  VariableNode *pVariableNode = pParentVariableNode->mChildren.value(name, 0);
  if (pVariableNode) {
    return pVariableNode;
  } else {
    QHash<QString, VariableNode*>::const_iterator iterator = pParentVariableNode->mChildren.constBegin();
    while (iterator != pParentVariableNode->mChildren.constEnd()) {
      if (VariableNode *node = VariableNode::findVariableNode(name, iterator.value())) {
        return node;
      }
      ++iterator;
    }
  }
  return 0;
}

QString Utilities::escapeForHtmlNonSecure(const QString &str)
{
  return QString(str)
      .replace("& ", "&amp;") // should be the first replacement
      .replace("< ", "&lt;");
}

/*!
 * \brief Utilities::tempDirectory
 * Returns the application temporary directory.
 * \return
 */
QString& Utilities::tempDirectory()
{
  static int init = 0;
  static QString tmpPath;
  if (!init) {
    init = 1;
#if defined(_WIN32)
    tmpPath = QDir::tempPath() + "/OpenModelica/OMEdit/";
#else // UNIX environment
    char *user = getenv("USER");
    tmpPath = QDir::tempPath() + "/OpenModelica_" + QString(user ? user : "nobody") + "/OMEdit/";
#endif
    tmpPath.remove("\"");
    if (!QDir().exists(tmpPath)) {
      if (!QDir().mkpath(tmpPath)) {
        qDebug() << "Failed to create the tempDirectory" << tmpPath
                 << "will use" << QDir::tempPath() << "instead.";
        tmpPath = QDir::tempPath();
        tmpPath.remove("\"");
      }
    }
  }
  return tmpPath;
}

/*
 * \brief Utilities::generateHash
 * hash the string input
 * \param input
 * \return hashprefix with first 4 chars
*/
QString Utilities::generateHash(const QString &input)
{
    // Convert the input string to a QByteArray
    QByteArray byteArray = input.toUtf8();
    // Create a QCryptographicHash object with the desired algorithm (SHA-256 in this case)
    QCryptographicHash hash(QCryptographicHash::Sha256);
    // Add the data to be hashed
    hash.addData(byteArray);
    // Obtain the resulting hash as a QByteArray
    QByteArray hashResult = hash.result();
    // Convert the hash result to a hex string for readability
    QString hashString = hashResult.toHex();
    // Extract the first 4 characters
    QString hashPrefix = hashString.left(4);

    return hashPrefix;
}

/*!
 * \brief Utilities::getApplicationSettings
 * Returns the application settings object.
 * \return
 */
QSettings* Utilities::getApplicationSettings()
{
  static int init = 0;
  static QSettings *pSettings;
  if (!init) {
    init = 1;
    pSettings = new QSettings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    pSettings->setIniCodec(Helper::utf8.toUtf8().constData());
#endif
  }
  return pSettings;
}

/*!
 * \brief Utilities::convertUnit
 * Converts the value using the unit offset and scale factor.
 * \param value
 * \param offset
 * \param scaleFactor
 * \return
 */
qreal Utilities::convertUnit(qreal value, qreal offset, qreal scaleFactor)
{
  return (value - offset) / scaleFactor;
}

/*!
 * \brief Utilities::extractArrayParts
 * Parses the input string and extracts the parts of an array.
 * \param input
 * \return
 */
QStringList Utilities::extractArrayParts(const QString &input) {
  QString trimmed = input.trimmed();
  // If input is NOT an array (doesn't start with { and end with }), return it as single element
  if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
    return QStringList{ trimmed };
  }

  // Remove outer braces
  QString content = trimmed.mid(1, trimmed.length() - 2);
  // Regex matches:
  // 1) quoted strings in group 1
  // 2) numbers in group 2
  // 3) unquoted strings in group 3
  QRegularExpression regex("\"([^\"]*)\"|(-?\\d+(?:\\.\\d+)?(?:[eE][-+]?\\d+)?)|([a-zA-Z_][a-zA-Z0-9_]*)");

  QStringList parts;
  QRegularExpressionMatchIterator i = regex.globalMatch(content);

  while (i.hasNext()) {
    QRegularExpressionMatch match = i.next();
    if (!match.captured(1).isNull()) {
      parts << match.captured(1);  // quoted string without quotes
    } else if (!match.captured(2).isNull()) {
      parts << match.captured(2);  // number
    } else if (!match.captured(3).isNull()) {
      parts << match.captured(3);  // unquoted string
    }
  }

  return parts;
}

/*!
 * \brief Utilities::isValueLiteralConstant
 * \param value
 * \return
 */
bool Utilities::isValueLiteralConstant(QString value)
{
  /* Issue #11795. Allow setting negative values for parameters.
   * Issue #11840. Allow setting array of values.
   * The following regular expression allows decimal values and array of decimal values. The values can be negative.
   */
  QRegExp rx("\\{?\\s*-?\\d+(\\.\\d+)?([eE][-+]?\\d+)?(?:\\s*,\\s*-?\\d+(\\.\\d+)?([eE][-+]?\\d+)?)*\\s*\\}?");
  return rx.exactMatch(value);
}

/*!
 * \brief Utilities::isValueScalarLiteralConstant
 * \param value
 * \return
 */
bool Utilities::isValueScalarLiteralConstant(QString value)
{
  /* Issue #13636
   * Check if value is scalar and literal constant.
   */
  QRegExp rx("\\s*-?\\d+(\\.\\d+)?([eE][-+]?\\d+)?");
  return rx.exactMatch(value);
}

/*!
 * \brief Utilities::arrayExpressionUnitConversion
 * If the expression is like an array of constants see ticket:4840
 * \param pOMCProxy
 * \param value
 * \param fromUnit
 * \param toUnit
 * \return
 */
QString Utilities::arrayExpressionUnitConversion(OMCProxy *pOMCProxy, QString value, QString fromUnit, QString toUnit)
{
  QStringList values = Utilities::extractArrayParts(value);
  QStringList convertedValues;
  OMCInterface::convertUnits_res convertUnit;
  int i = 0;
  bool ok = true;
  foreach (QString value, values) {
    qreal realValue = value.toDouble(&ok);
    if (ok) {
      if (i == 0) {
        convertUnit = pOMCProxy->convertUnits(fromUnit, toUnit);
      }
      if (convertUnit.unitsCompatible) {
        realValue = Utilities::convertUnit(realValue, convertUnit.offset, convertUnit.scaleFactor);
        convertedValues.append(StringHandler::number(realValue));
      }
    } else {
      convertedValues.append(value);
    }
  }
  return QString("{%1}").arg(convertedValues.join(","));
}

Label* Utilities::getHeadingLabel(QString heading)
{
  Label *pHeadingLabel = new Label(heading);
  pHeadingLabel->setFont(QFont(Helper::systemFontInfo.family(), Helper::headingFontSize));
  return pHeadingLabel;
}

QFrame* Utilities::getHeadingLine()
{
  QFrame *pHeadingLine = new QFrame();
  pHeadingLine->setFrameShape(QFrame::HLine);
  pHeadingLine->setFrameShadow(QFrame::Sunken);
  return pHeadingLine;
}

/*!
 * \brief Utilities::detectBOM
 * Detects if the file has byte order mark (BOM) or not.
 * \param fileName
 * \return
 */
bool Utilities::detectBOM(QString fileName)
{
  QFile file(fileName);
  if (file.exists()) {
    if (file.open(QIODevice::ReadOnly)) {
      QByteArray data = file.readAll();
      const int bytesRead = data.size();
      const unsigned char *buf = reinterpret_cast<const unsigned char *>(data.constData());
      // code taken from qtextstream
      if (bytesRead >= 3 && ((buf[0] == 0xef && buf[1] == 0xbb) && buf[2] == 0xbf)) {
        return true;
      } else {
        return false;
      }
      file.close();
    } else {
      qDebug() << QString("Failed to detect byte order mark. Unable to open file %1.").arg(fileName);
    }
  }
  return false;
}

QTextCharFormat Utilities::getParenthesesMatchFormat()
{
  QTextCharFormat parenthesesMatchFormat;
  parenthesesMatchFormat.setForeground(Qt::red);
  parenthesesMatchFormat.setBackground(QColor(160, 238, 160));
  return parenthesesMatchFormat;
}

QTextCharFormat Utilities::getParenthesesMisMatchFormat()
{
  QTextCharFormat parenthesesMisMatchFormat;
  parenthesesMisMatchFormat.setBackground(Qt::red);
  return parenthesesMisMatchFormat;
}

void Utilities::highlightCurrentLine(QPlainTextEdit *pPlainTextEdit)
{
  QList<QTextEdit::ExtraSelection> selections = pPlainTextEdit->extraSelections();
  QTextEdit::ExtraSelection selection;
  QColor lineColor = QColor(232, 242, 254);
  selection.format.setBackground(lineColor);
  selection.format.setProperty(QTextFormat::FullWidthSelection, true);
  selection.cursor = pPlainTextEdit->textCursor();
  selection.cursor.clearSelection();
  selections.append(selection);
  pPlainTextEdit->setExtraSelections(selections);
}

void Utilities::highlightParentheses(QPlainTextEdit *pPlainTextEdit, QTextCharFormat parenthesesMatchFormat,
                                     QTextCharFormat parenthesesMisMatchFormat)
{
  if (pPlainTextEdit->isReadOnly()) {
    return;
  }

  QTextCursor backwardMatch = pPlainTextEdit->textCursor();
  QTextCursor forwardMatch = pPlainTextEdit->textCursor();
  if (pPlainTextEdit->overwriteMode()) {
    backwardMatch.movePosition(QTextCursor::Right);
  }

  const TextBlockUserData::MatchType backwardMatchType = TextBlockUserData::matchCursorBackward(&backwardMatch);
  const TextBlockUserData::MatchType forwardMatchType = TextBlockUserData::matchCursorForward(&forwardMatch);
  QList<QTextEdit::ExtraSelection> selections = pPlainTextEdit->extraSelections();

  if (backwardMatchType == TextBlockUserData::NoMatch && forwardMatchType == TextBlockUserData::NoMatch) {
    pPlainTextEdit->setExtraSelections(selections);
    return;
  }

  if (backwardMatch.hasSelection()) {
    QTextEdit::ExtraSelection selection;
    if (backwardMatchType == TextBlockUserData::Mismatch) {
      selection.cursor = backwardMatch;
      selection.format = parenthesesMisMatchFormat;
      selections.append(selection);
    } else {
      selection.cursor = backwardMatch;
      selection.format = parenthesesMatchFormat;

      selection.cursor.setPosition(backwardMatch.selectionStart());
      selection.cursor.setPosition(selection.cursor.position() + 1, QTextCursor::KeepAnchor);
      selections.append(selection);

      selection.cursor.setPosition(backwardMatch.selectionEnd());
      selection.cursor.setPosition(selection.cursor.position() - 1, QTextCursor::KeepAnchor);
      selections.append(selection);
    }
  }

  if (forwardMatch.hasSelection()) {
    QTextEdit::ExtraSelection selection;
    if (forwardMatchType == TextBlockUserData::Mismatch) {
      selection.cursor = forwardMatch;
      selection.format = parenthesesMisMatchFormat;
      selections.append(selection);
    } else {
      selection.cursor = forwardMatch;
      selection.format = parenthesesMatchFormat;

      selection.cursor.setPosition(forwardMatch.selectionStart());
      selection.cursor.setPosition(selection.cursor.position() + 1, QTextCursor::KeepAnchor);
      selections.append(selection);

      selection.cursor.setPosition(forwardMatch.selectionEnd());
      selection.cursor.setPosition(selection.cursor.position() - 1, QTextCursor::KeepAnchor);
      selections.append(selection);
    }
  }
  pPlainTextEdit->setExtraSelections(selections);
}

/*!
 * \brief Utilities::getProcessId
 * Returns the process id.
 * \param pProcess
 * \return
 */
qint64 Utilities::getProcessId(QProcess *pProcess)
{
  qint64 processId = 0;
#if QT_VERSION >= QT_VERSION_CHECK(5, 3, 0)
  processId = pProcess->processId();
#else /* Qt4 */
#if defined(_WIN32)
  _PROCESS_INFORMATION *procInfo = pProcess->pid();
  if (procInfo) {
    processId = procInfo->dwProcessId;
  }
#else
  processId = pProcess->pid();
#endif /* WIN32 */
#endif /* QT_VERSION */
  return processId;
}

/*!
 * \brief Utilities::formatExitCode
 * Returns the given process exit code as a string in an OS appropriate format.
 * \param code
 * \return
 */
QString Utilities::formatExitCode(int code)
{
#if defined(_WIN32)
  // Use 0xXXXXXXXX format on Windows.
  return QStringLiteral("0x%1").arg(code, 8, 16, QChar('0'));
#else
  // Use normal decimal on other OS.
  return QString::number(code);
#endif
}

#if defined(_WIN32)
/* adrpo: found this on http://stackoverflow.com/questions/1173342/terminate-a-process-tree-c-for-windows
 * thanks go to: mjmarsh & Firas Assaad
 * adapted to recurse on children ids
 */
void Utilities::killProcessTreeWindows(DWORD myprocID)
{
  PROCESSENTRY32 pe;
  HANDLE hSnap = NULL, hProc = NULL;

  memset(&pe, 0, sizeof(PROCESSENTRY32));
  pe.dwSize = sizeof(PROCESSENTRY32);

  hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

  if (Process32First(hSnap, &pe))
  {
    BOOL bContinue = TRUE;

    // kill child processes
    while (bContinue)
    {
      // only kill child processes
      if (pe.th32ParentProcessID == myprocID)
      {
        HANDLE hChildProc = NULL;

        // recurse
        killProcessTreeWindows(pe.th32ProcessID);

        hChildProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pe.th32ProcessID);

        if (hChildProc)
        {
          TerminateProcess(hChildProc, 1);
          CloseHandle(hChildProc);
        }
      }

      bContinue = Process32Next(hSnap, &pe);
    }

    // kill the main process
    hProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, myprocID);

    if (hProc)
    {
      TerminateProcess(hProc, 1);
      CloseHandle(hProc);
    }
  }
}
#endif

/*!
 * \brief Utilities::isCFile
 * Returns true if extension is of C file.
 * \param extension
 * \return
 */
bool Utilities::isCFile(QString extension)
{
  if (extension.compare("c") == 0 ||
      extension.compare("cpp") == 0 ||
      extension.compare("cc") == 0 ||
      extension.compare("h") == 0 ||
      extension.compare("hpp") == 0) {
    return true;
  } else {
    return false;
  }
}

/*!
 * \brief Utilities::isModelicaFile
 * Returns true if extension is of Modelica file.
 * \param extension
 * \return
 */
bool Utilities::isModelicaFile(QString extension)
{
  if (extension.compare("mo") == 0) {
    return true;
  } else {
    return false;
  }
}

QString Utilities::getGDBPath()
{
#if defined(_WIN32)
  const char *OMDEV = getenv("OMDEV");
  const char* msysEnv = System_openModelicaPlatform(); /* "ucrt64" or "mingw64" */

  // OMDEV is set: <OMDEV>/tools/msys/<CONFIG_OPENMODELICA_SPEC_PLATFORM>/bin/gdb.exe
  if (!QString(OMDEV).isEmpty()) {
    QString qOMDEV = QString(OMDEV).replace("\\", "/");
    return QString(qOMDEV) + QString("/tools/msys/") + QString(msysEnv) + QString("/bin/gdb.exe");
  }

  // Default: <OPENMODELICAHOME>/tools/msys/<CONFIG_OPENMODELICA_SPEC_PLATFORM>/bin/gdb.exe
  return QString(Helper::OpenModelicaHome) + QString("/tools/msys/") + QString(msysEnv) + QString("/bin/gdb.exe");
#else
  return "gdb";
#endif
}

Utilities::FileIconProvider::FileIconProviderImplementation *instance()
{
  static Utilities::FileIconProvider::FileIconProviderImplementation theInstance;
  return &theInstance;
}

QFileIconProvider* Utilities::FileIconProvider::iconProvider()
{
  return instance();
}

Utilities::FileIconProvider::FileIconProviderImplementation::FileIconProviderImplementation()
   : mUnknownFileIcon(qApp->style()->standardIcon(QStyle::SP_FileIcon))
{

}

QIcon Utilities::FileIconProvider::FileIconProviderImplementation::icon(const QFileInfo &fileInfo)
{
  // Check for cached overlay icons by file suffix.
  bool isDir = fileInfo.isDir();
  QString suffix = !isDir ? fileInfo.suffix() : QString();
  if (!mIconsHash.isEmpty() && !isDir && !suffix.isEmpty()) {
    if (mIconsHash.contains(suffix)) {
      return mIconsHash.value(suffix);
    }
  }
  // Get icon from OS.
  QIcon icon;
  // File icons are unknown on linux systems.
#if defined(Q_OS_UNIX)
  icon = isDir ? QFileIconProvider::icon(fileInfo) : mUnknownFileIcon;
#else
  icon = QFileIconProvider::icon(fileInfo);
#endif
  if (!isDir && !suffix.isEmpty()) {
    mIconsHash.insert(suffix, icon);
  }
  return icon;
}

/*!
 * \brief icon
 * Returns the icon associated with the file suffix in fileInfo. If there is none,
 * the default icon of the operating system is returned.
 * \param info
 * \return
 */
QIcon Utilities::FileIconProvider::icon(const QFileInfo &info)
{
  return instance()->icon(info);
}

bool Utilities::containsWord(QString text, int index, QString keyword, bool checkParenthesis)
{
  if (index + keyword.length() > text.length()) {
    return false;
  }
  QString textToMatch = text.mid(index, keyword.length());
  QRegExp keywordRegExp("\\b" + keyword + "\\b");
  if (keywordRegExp.indexIn(textToMatch) != -1 && (index + keyword.length() == text.length() ||
                                                   text[index + keyword.length()].isSpace() ||
                                                   (checkParenthesis && text[index + keyword.length()] == '('))) {
    return true;
  }
  return false;
}

/*!
 * \brief Utilities::maxi
 * This function gives the maximum
 * \param arr
 * \param n
 * \return
 */
float Utilities::maxi(float arr[],int n) {
  float m = 0;
  for (int i = 0; i < n; ++i)
    if (m < arr[i])
      m = arr[i];
  return m;
}

/*!
 * \brief Utilities::mini
 * This function gives the minimum
 * \param arr
 * \param n
 * \return
 */
float Utilities::mini(float arr[], int n) {
  float m = 1;
  for (int i = 0; i < n; ++i)
    if (m > arr[i])
      m = arr[i];
  return m;
}

/*!
 * \brief liang_barsky_clipper
 * Liang–Barsky algorithm to find the intersection point.
 * Returns a list of points. The first point is when line is coming from outside and intersects the rectangle.
 * The second point in the list is when line is comming from inside and intersects the rectangle.
 * \param xmin
 * \param ymin
 * \param xmax
 * \param ymax
 * \param x1
 * \param y1
 * \param x2
 * \param y2
 * \return
 */
QList<QPointF> Utilities::liangBarskyClipper(float xmin, float ymin, float xmax, float ymax, float x1, float y1, float x2, float y2) {
  // defining variables
  float p1 = -(x2 - x1);
  float p2 = -p1;
  float p3 = -(y2 - y1);
  float p4 = -p3;

  float q1 = x1 - xmin;
  float q2 = xmax - x1;
  float q3 = y1 - ymin;
  float q4 = ymax - y1;

  float posarr[5], negarr[5];
  int posind = 1, negind = 1;
  posarr[0] = 1;
  negarr[0] = 0;

  if ((p1 == 0 && q1 < 0) || (p3 == 0 && q3 < 0)) {
      qDebug() << "Line is parallel to clipping window!";
      return QList<QPointF>();
  }
  if (p1 != 0) {
    float r1 = q1 / p1;
    float r2 = q2 / p2;
    if (p1 < 0) {
      negarr[negind++] = r1; // for negative p1, add it to negative array
      posarr[posind++] = r2; // and add p2 to positive array
    } else {
      negarr[negind++] = r2;
      posarr[posind++] = r1;
    }
  }
  if (p3 != 0) {
    float r3 = q3 / p3;
    float r4 = q4 / p4;
    if (p3 < 0) {
      negarr[negind++] = r3;
      posarr[posind++] = r4;
    } else {
      negarr[negind++] = r4;
      posarr[posind++] = r3;
    }
  }

  float xn1, yn1, xn2, yn2;
  float rn1, rn2;
  rn1 = maxi(negarr, negind); // maximum of negative array
  rn2 = mini(posarr, posind); // minimum of positive array

  xn1 = x1 + p2 * rn1;
  yn1 = y1 + p4 * rn1; // computing new points

  xn2 = x1 + p2 * rn2;
  yn2 = y1 + p4 * rn2;

//  qDebug() << x1 << y1 << xn1 << yn1 << x2 << y2 << xn2 << yn2;
  return QList<QPointF>() << QPointF(xn1, yn1) << QPointF(xn2, yn2);
}

/*!
 * \brief Utilities::removeDirectoryRecursively
 * Removes the directory recursively.
 * \param path
 */
void Utilities::removeDirectoryRecursively(QString path)
{
  QFileInfo fileInfo(path);
  if (fileInfo.isDir()) {
    QDir dir(path);
    QStringList filesList = dir.entryList(QDir::AllDirs | QDir::Files | QDir::NoSymLinks | QDir::NoDotAndDotDot | QDir::Writable | QDir::CaseSensitive);
    for (int i = 0 ; i < filesList.count() ; ++i) {
      removeDirectoryRecursively(QString("%1/%2").arg(path, filesList.at(i)));
    }
    QDir().rmdir(path);
  } else {
    QFile::remove(path);
  }
}

/*!
 * \brief Utilities::mapToCoordinateSystem
 * If you have numbers x in the range [a,b] and you want to transform them to numbers y in the range [c,d].\n
 * y = ((x−a) * ((d−c)/(b−a))) + c
 * \param value
 * \param startA
 * \param endA
 * \param startB
 * \param endB
 * \return
 */
qreal Utilities::mapToCoordinateSystem(qreal value, qreal startA, qreal endA, qreal startB, qreal endB)
{
  return ((value - startA) * ((endB - startB) / (endA - startA))) + startB;
}

QStringList Utilities::variantListToStringList(const QVariantList lst)
{
  QStringList strs;
  foreach(QVariant v, lst) {
    strs << v.toString().trimmed();
  }
  return strs;
}

/*!
 * \brief Utilities::addDefaultDisplayUnit
 * \param unit
 * \param displayUnit
 */
void Utilities::addDefaultDisplayUnit(const QString &unit, QStringList &displayUnit)
{
  /* Issue #5447
   * For angular speeds always add in the menu in the unit column, in addition to the standard "rad/s" also "rpm"
   * For energies always add in the menu in the Unit column, in addition to standard "J", also "Wh" (prefixes such as kWh, MWh, GWh will be obtained automatically)
   */
  if (unit.compare(QStringLiteral("rad/s")) == 0) {
    displayUnit << "rpm";
  } else if (unit.compare(QStringLiteral("J")) == 0) {
    displayUnit << "Wh";
  } else if (unit.compare(QStringLiteral("K")) == 0) {
    /* Issue #8758
     * Whenever unit = "K", we also add "degC" even if it is not defined as displayUnits.
     */
    displayUnit << "degC";
  } else if (unit.compare(QStringLiteral("m/s")) == 0) {
    /* Issue #12340
     * Whenever unit = "m/s", we also add "km/h" even if it is not defined as displayUnits.
     */
    displayUnit << "km/h";
  } else if (unit.compare(QStringLiteral("m3/s")) == 0) {
    /* Issue #13379
     * For volume flow rate it would be good to have extra display units l/s, which is 0.001 m3/s, and maybe also m3/h, which is 1/3600 m3/s.
     * Whenever unit = "m3/s", we also add "l/s" and "m3/h" even if it is not defined as displayUnits.
     */
    displayUnit << "l/s" << "m3/h";
  }

  // add prefixes if unit is prefixable
  QStringList newDisplayUnits = displayUnit;
  foreach (auto newDisplayUnit, newDisplayUnits) {
    if (OMPlot::Plot::prefixableUnit(newDisplayUnit)) {
      displayUnit << QString("k%1").arg(newDisplayUnit)
                  << QString("M%1").arg(newDisplayUnit)
                  << QString("G%1").arg(newDisplayUnit)
                  << QString("T%1").arg(newDisplayUnit)
                  << QString("m%1").arg(newDisplayUnit)
                  << QString("u%1").arg(newDisplayUnit)
                  << QString("n%1").arg(newDisplayUnit)
                  << QString("p%1").arg(newDisplayUnit);
    }
  }
  // remove duplicates
  displayUnit.removeDuplicates();
}

/*!
 * \brief Utilities::adjustRectangle
 * Adjusts the scene rectangle.
 * \param rectangle
 * \param factor
 * \return
 */
QRectF Utilities::adjustSceneRectangle(const QRectF sceneRectangle, const qreal factor)
{
  // Yes the top of the rectangle is bottom for us since the coordinate system is inverted.
  qreal left = sceneRectangle.left();
  qreal bottom = sceneRectangle.top();
  qreal right = sceneRectangle.right();
  qreal top = sceneRectangle.bottom();
  QRectF rectangle(left, bottom, qFabs(left - right), qFabs(bottom - top));
  /* Ticket:4340 Extend vertical space
   * Make the drawing area 25% bigger than the actual size. So we can better use the panning feature.
   */
  const qreal widthFactor = sceneRectangle.width() * factor;
  const qreal heightFactor = sceneRectangle.width() * factor;
  rectangle.adjust(-widthFactor, -heightFactor, widthFactor, heightFactor);
  return rectangle;
}

/*!
 * \brief Utilities::setToolTip
 * Sets the tooltip for Combobox and its items.
 * \param pComboBox
 * \param description
 * \param optionsDescriptions
 */
void Utilities::setToolTip(QComboBox *pComboBox, const QString &description, const QStringList &optionsDescriptions)
{
  QString itemsToolTip;
  for (int i = 0; i < pComboBox->count(); ++i) {
    // skip empty items
    if (!pComboBox->itemText(i).isEmpty()) {
      itemsToolTip.append(QString("<li><i>%1</i>").arg(pComboBox->itemText(i)));
      if (optionsDescriptions.size() > i && !optionsDescriptions.at(i).isEmpty()) {
        itemsToolTip.append(QString(": %1").arg(optionsDescriptions.at(i)));
        pComboBox->setItemData(i, optionsDescriptions.at(i), Qt::ToolTipRole);
      }
      itemsToolTip.append("</li>");
    }
  }
  pComboBox->setToolTip(QString("<html><head/><body><p>%1</p><ul>%2</ul></body></html>").arg(description, itemsToolTip));
}

/*!
 * \brief Utilities::isMultiline
 * Returns true if the text containts \n.
 * \param text
 * \return
 */
bool Utilities::isMultiline(const QString &text)
{
  return text.indexOf('\n') >= 0;
}

/*!
 * \brief Utilities::supportedLanguages
 * Returns the map of languages that OMEdit support.
 * \return
 */
QMap<QString, QLocale> Utilities::supportedLanguages()
{
  static int init = 0;
  static QMap<QString, QLocale> languagesMap;
  if (!init) {
    init = 1;
    languagesMap.insert(QObject::tr("Chinese").append(" (zh_CN)"), QLocale(QLocale::Chinese));
    languagesMap.insert(QObject::tr("English").append(" (en)"), QLocale(QLocale::English));
    languagesMap.insert(QObject::tr("French").append(" (fr)"), QLocale(QLocale::French));
    languagesMap.insert(QObject::tr("German").append(" (de)"), QLocale(QLocale::German));
    languagesMap.insert(QObject::tr("Italian").append(" (it)"), QLocale(QLocale::Italian));
    languagesMap.insert(QObject::tr("Japanese").append(" (ja)"), QLocale(QLocale::Japanese));
    languagesMap.insert(QObject::tr("Romanian").append(" (ro)"), QLocale(QLocale::Romanian));
    languagesMap.insert(QObject::tr("Russian").append(" (ru)"), QLocale(QLocale::Russian));
    languagesMap.insert(QObject::tr("Spanish").append(" (es)"), QLocale(QLocale::Spanish));
    languagesMap.insert(QObject::tr("Swedish").append(" (sv)"), QLocale(QLocale::Swedish));
  }
  return languagesMap;
}
