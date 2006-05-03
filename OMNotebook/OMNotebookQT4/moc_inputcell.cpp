/****************************************************************************
** Meta object code from reading C++ file 'inputcell.h'
**
** Created: to 27. apr 10:59:06 2006
**      by: The Qt Meta Object Compiler version 59 (Qt 4.1.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "inputcell.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'inputcell.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 59
#error "This file was generated using the moc from 4.1.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

static const uint qt_meta_data_IAEX__InputCell[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
      28,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // signals: signature, parameters, type, tag, flags
      17,   16,   16,   16, 0x05,
      33,   16,   16,   16, 0x05,
      47,   16,   16,   16, 0x05,
      65,   16,   16,   16, 0x05,
      86,   16,   16,   16, 0x05,

 // slots: signature, parameters, type, tag, flags
     105,   16,   16,   16, 0x0a,
     112,   16,   16,   16, 0x0a,
     122,   16,   16,   16, 0x0a,
     136,   16,   16,   16, 0x0a,
     148,   16,   16,   16, 0x0a,
     161,   16,   16,   16, 0x0a,
     180,   16,   16,   16, 0x0a,
     202,  197,   16,   16, 0x0a,
     224,  219,   16,   16, 0x0a,
     252,  245,   16,   16, 0x0a,
     275,  219,   16,   16, 0x0a,
     312,  302,   16,   16, 0x0a,
     336,  330,   16,   16, 0x0a,
     363,  356,   16,   16, 0x0a,
     398,   16,  390,   16, 0x0a,
     415,   16,  390,   16, 0x0a,
     445,  436,   16,   16, 0x0a,
     473,  463,   16,   16, 0x0a,
     499,  492,   16,   16, 0x0a,
     521,  515,   16,   16, 0x0a,
     536,  515,   16,   16, 0x0a,
     557,   16,   16,   16, 0x08,
     576,   16,   16,   16, 0x08,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__InputCell[] = {
    "IAEX::InputCell\0\0heightChanged()\0textChanged()\0textChanged(bool)\0"
    "clickedOutput(Cell*)\0forwardAction(int)\0eval()\0command()\0"
    "nextCommand()\0nextField()\0clickEvent()\0clickEventOutput()\0"
    "contentChanged()\0text\0setText(QString)\0html\0setTextHtml(QString)\0"
    "output\0setTextOutput(QString)\0setTextOutputHtml(QString)\0stylename\0"
    "setStyle(QString)\0style\0setStyle(CellStyle)\0number\0"
    "setChapterCounter(QString)\0QString\0ChapterCounter()\0"
    "ChapterCounterHtml()\0readonly\0setReadOnly(bool)\0evaluated\0"
    "setEvaluated(bool)\0closed\0setClosed(bool)\0focus\0setFocus(bool)\0"
    "setFocusOutput(bool)\0addToHighlighter()\0"
    "charFormatChanged(QTextCharFormat)\0"
};

const QMetaObject IAEX::InputCell::staticMetaObject = {
    { &Cell::staticMetaObject, qt_meta_stringdata_IAEX__InputCell,
      qt_meta_data_IAEX__InputCell, 0 }
};

const QMetaObject *IAEX::InputCell::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::InputCell::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__InputCell))
	return static_cast<void*>(const_cast<InputCell*>(this));
    return Cell::qt_metacast(_clname);
}

int IAEX::InputCell::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = Cell::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: heightChanged(); break;
        case 1: textChanged(); break;
        case 2: textChanged(*reinterpret_cast< bool*>(_a[1])); break;
        case 3: clickedOutput(*reinterpret_cast< Cell**>(_a[1])); break;
        case 4: forwardAction(*reinterpret_cast< int*>(_a[1])); break;
        case 5: eval(); break;
        case 6: command(); break;
        case 7: nextCommand(); break;
        case 8: nextField(); break;
        case 9: clickEvent(); break;
        case 10: clickEventOutput(); break;
        case 11: contentChanged(); break;
        case 12: setText(*reinterpret_cast< QString*>(_a[1])); break;
        case 13: setTextHtml(*reinterpret_cast< QString*>(_a[1])); break;
        case 14: setTextOutput(*reinterpret_cast< QString*>(_a[1])); break;
        case 15: setTextOutputHtml(*reinterpret_cast< QString*>(_a[1])); break;
        case 16: setStyle(*reinterpret_cast< QString*>(_a[1])); break;
        case 17: setStyle(*reinterpret_cast< CellStyle*>(_a[1])); break;
        case 18: setChapterCounter(*reinterpret_cast< QString*>(_a[1])); break;
        case 19: { QString _r = ChapterCounter();
            if (_a[0]) *reinterpret_cast< QString*>(_a[0]) = _r; }  break;
        case 20: { QString _r = ChapterCounterHtml();
            if (_a[0]) *reinterpret_cast< QString*>(_a[0]) = _r; }  break;
        case 21: setReadOnly(*reinterpret_cast< bool*>(_a[1])); break;
        case 22: setEvaluated(*reinterpret_cast< bool*>(_a[1])); break;
        case 23: setClosed(*reinterpret_cast< bool*>(_a[1])); break;
        case 24: setFocus(*reinterpret_cast< bool*>(_a[1])); break;
        case 25: setFocusOutput(*reinterpret_cast< bool*>(_a[1])); break;
        case 26: addToHighlighter(); break;
        case 27: charFormatChanged(*reinterpret_cast< QTextCharFormat*>(_a[1])); break;
        }
        _id -= 28;
    }
    return _id;
}

// SIGNAL 0
void IAEX::InputCell::heightChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, 0);
}

// SIGNAL 1
void IAEX::InputCell::textChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, 0);
}

// SIGNAL 2
void IAEX::InputCell::textChanged(bool _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 2, _a);
}

// SIGNAL 3
void IAEX::InputCell::clickedOutput(Cell * _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 3, _a);
}

// SIGNAL 4
void IAEX::InputCell::forwardAction(int _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 4, _a);
}
static const uint qt_meta_data_IAEX__MyTextEdit[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
       7,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // signals: signature, parameters, type, tag, flags
      18,   17,   17,   17, 0x05,
      32,   17,   17,   17, 0x05,
      56,   17,   17,   17, 0x05,
      66,   17,   17,   17, 0x05,
      80,   17,   17,   17, 0x05,
      92,   17,   17,   17, 0x05,
      99,   17,   17,   17, 0x05,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__MyTextEdit[] = {
    "IAEX::MyTextEdit\0\0clickOnCell()\0wheelMove(QWheelEvent*)\0command()\0"
    "nextCommand()\0nextField()\0eval()\0forwardAction(int)\0"
};

const QMetaObject IAEX::MyTextEdit::staticMetaObject = {
    { &QTextBrowser::staticMetaObject, qt_meta_stringdata_IAEX__MyTextEdit,
      qt_meta_data_IAEX__MyTextEdit, 0 }
};

const QMetaObject *IAEX::MyTextEdit::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::MyTextEdit::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__MyTextEdit))
	return static_cast<void*>(const_cast<MyTextEdit*>(this));
    return QTextBrowser::qt_metacast(_clname);
}

int IAEX::MyTextEdit::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QTextBrowser::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: clickOnCell(); break;
        case 1: wheelMove(*reinterpret_cast< QWheelEvent**>(_a[1])); break;
        case 2: command(); break;
        case 3: nextCommand(); break;
        case 4: nextField(); break;
        case 5: eval(); break;
        case 6: forwardAction(*reinterpret_cast< int*>(_a[1])); break;
        }
        _id -= 7;
    }
    return _id;
}

// SIGNAL 0
void IAEX::MyTextEdit::clickOnCell()
{
    QMetaObject::activate(this, &staticMetaObject, 0, 0);
}

// SIGNAL 1
void IAEX::MyTextEdit::wheelMove(QWheelEvent * _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 1, _a);
}

// SIGNAL 2
void IAEX::MyTextEdit::command()
{
    QMetaObject::activate(this, &staticMetaObject, 2, 0);
}

// SIGNAL 3
void IAEX::MyTextEdit::nextCommand()
{
    QMetaObject::activate(this, &staticMetaObject, 3, 0);
}

// SIGNAL 4
void IAEX::MyTextEdit::nextField()
{
    QMetaObject::activate(this, &staticMetaObject, 4, 0);
}

// SIGNAL 5
void IAEX::MyTextEdit::eval()
{
    QMetaObject::activate(this, &staticMetaObject, 5, 0);
}

// SIGNAL 6
void IAEX::MyTextEdit::forwardAction(int _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 6, _a);
}
