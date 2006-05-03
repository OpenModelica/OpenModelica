/****************************************************************************
** Meta object code from reading C++ file 'textcell.h'
**
** Created: to 27. apr 10:52:31 2006
**      by: The Qt Meta Object Compiler version 59 (Qt 4.1.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "textcell.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'textcell.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 59
#error "This file was generated using the moc from 4.1.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

static const uint qt_meta_data_IAEX__TextCell[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
      21,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // signals: signature, parameters, type, tag, flags
      16,   15,   15,   15, 0x05,
      32,   15,   15,   15, 0x05,
      46,   15,   15,   15, 0x05,
      69,   64,   15,   15, 0x05,
      88,   15,   15,   15, 0x05,

 // slots: signature, parameters, type, tag, flags
     107,   15,   15,   15, 0x0a,
     125,  120,   15,   15, 0x0a,
     154,  142,   15,   15, 0x0a,
     192,  187,   15,   15, 0x0a,
     223,  213,   15,   15, 0x0a,
     247,  241,   15,   15, 0x0a,
     274,  267,   15,   15, 0x0a,
     309,   15,  301,   15, 0x0a,
     326,   15,  301,   15, 0x0a,
     356,  347,   15,   15, 0x0a,
     380,  374,   15,   15, 0x0a,
     395,   15,   15,   15, 0x09,
     412,   64,   15,   15, 0x09,
     436,  432,   15,   15, 0x09,
     466,   15,   15,   15, 0x09,
     488,   15,   15,   15, 0x09,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__TextCell[] = {
    "IAEX::TextCell\0\0heightChanged()\0textChanged()\0textChanged(bool)\0"
    "link\0hoverOverUrl(QUrl)\0forwardAction(int)\0clickEvent()\0text\0"
    "setText(QString)\0text,format\0setText(QString,QTextCharFormat)\0html\0"
    "setTextHtml(QString)\0stylename\0setStyle(QString)\0style\0"
    "setStyle(CellStyle)\0number\0setChapterCounter(QString)\0QString\0"
    "ChapterCounter()\0ChapterCounterHtml()\0readonly\0setReadOnly(bool)\0"
    "focus\0setFocus(bool)\0contentChanged()\0hoverOverLink(QUrl)\0url\0"
    "openLinkInternal(const QUrl*)\0textChangedInternal()\0"
    "charFormatChanged(QTextCharFormat)\0"
};

const QMetaObject IAEX::TextCell::staticMetaObject = {
    { &Cell::staticMetaObject, qt_meta_stringdata_IAEX__TextCell,
      qt_meta_data_IAEX__TextCell, 0 }
};

const QMetaObject *IAEX::TextCell::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::TextCell::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__TextCell))
	return static_cast<void*>(const_cast<TextCell*>(this));
    return Cell::qt_metacast(_clname);
}

int IAEX::TextCell::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = Cell::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: heightChanged(); break;
        case 1: textChanged(); break;
        case 2: textChanged(*reinterpret_cast< bool*>(_a[1])); break;
        case 3: hoverOverUrl(*reinterpret_cast< QUrl*>(_a[1])); break;
        case 4: forwardAction(*reinterpret_cast< int*>(_a[1])); break;
        case 5: clickEvent(); break;
        case 6: setText(*reinterpret_cast< QString*>(_a[1])); break;
        case 7: setText(*reinterpret_cast< QString*>(_a[1]),*reinterpret_cast< QTextCharFormat*>(_a[2])); break;
        case 8: setTextHtml(*reinterpret_cast< QString*>(_a[1])); break;
        case 9: setStyle(*reinterpret_cast< QString*>(_a[1])); break;
        case 10: setStyle(*reinterpret_cast< CellStyle*>(_a[1])); break;
        case 11: setChapterCounter(*reinterpret_cast< QString*>(_a[1])); break;
        case 12: { QString _r = ChapterCounter();
            if (_a[0]) *reinterpret_cast< QString*>(_a[0]) = _r; }  break;
        case 13: { QString _r = ChapterCounterHtml();
            if (_a[0]) *reinterpret_cast< QString*>(_a[0]) = _r; }  break;
        case 14: setReadOnly(*reinterpret_cast< bool*>(_a[1])); break;
        case 15: setFocus(*reinterpret_cast< bool*>(_a[1])); break;
        case 16: contentChanged(); break;
        case 17: hoverOverLink(*reinterpret_cast< QUrl*>(_a[1])); break;
        case 18: openLinkInternal(*reinterpret_cast< const QUrl**>(_a[1])); break;
        case 19: textChangedInternal(); break;
        case 20: charFormatChanged(*reinterpret_cast< QTextCharFormat*>(_a[1])); break;
        }
        _id -= 21;
    }
    return _id;
}

// SIGNAL 0
void IAEX::TextCell::heightChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, 0);
}

// SIGNAL 1
void IAEX::TextCell::textChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, 0);
}

// SIGNAL 2
void IAEX::TextCell::textChanged(bool _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 2, _a);
}

// SIGNAL 3
void IAEX::TextCell::hoverOverUrl(const QUrl & _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 3, _a);
}

// SIGNAL 4
void IAEX::TextCell::forwardAction(int _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 4, _a);
}
static const uint qt_meta_data_IAEX__MyTextBrowser[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
       5,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // signals: signature, parameters, type, tag, flags
      21,   20,   20,   20, 0x05,
      43,   20,   20,   20, 0x05,
      57,   20,   20,   20, 0x05,
      81,   20,   20,   20, 0x05,

 // slots: signature, parameters, type, tag, flags
     105,  100,   20,   20, 0x0a,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__MyTextBrowser[] = {
    "IAEX::MyTextBrowser\0\0openLink(const QUrl*)\0clickOnCell()\0"
    "wheelMove(QWheelEvent*)\0forwardAction(int)\0name\0setSource(QUrl)\0"
};

const QMetaObject IAEX::MyTextBrowser::staticMetaObject = {
    { &QTextBrowser::staticMetaObject, qt_meta_stringdata_IAEX__MyTextBrowser,
      qt_meta_data_IAEX__MyTextBrowser, 0 }
};

const QMetaObject *IAEX::MyTextBrowser::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::MyTextBrowser::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__MyTextBrowser))
	return static_cast<void*>(const_cast<MyTextBrowser*>(this));
    return QTextBrowser::qt_metacast(_clname);
}

int IAEX::MyTextBrowser::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QTextBrowser::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: openLink(*reinterpret_cast< const QUrl**>(_a[1])); break;
        case 1: clickOnCell(); break;
        case 2: wheelMove(*reinterpret_cast< QWheelEvent**>(_a[1])); break;
        case 3: forwardAction(*reinterpret_cast< int*>(_a[1])); break;
        case 4: setSource(*reinterpret_cast< QUrl*>(_a[1])); break;
        }
        _id -= 5;
    }
    return _id;
}

// SIGNAL 0
void IAEX::MyTextBrowser::openLink(const QUrl * _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}

// SIGNAL 1
void IAEX::MyTextBrowser::clickOnCell()
{
    QMetaObject::activate(this, &staticMetaObject, 1, 0);
}

// SIGNAL 2
void IAEX::MyTextBrowser::wheelMove(QWheelEvent * _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 2, _a);
}

// SIGNAL 3
void IAEX::MyTextBrowser::forwardAction(int _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 3, _a);
}
