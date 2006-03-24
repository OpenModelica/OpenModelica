/****************************************************************************
** Meta object code from reading C++ file 'textcell.h'
**
** Created: to 23. mar 15:11:41 2006
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
      19,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // signals: signature, parameters, type, tag, flags
      16,   15,   15,   15, 0x05,
      30,   15,   15,   15, 0x05,
      53,   48,   15,   15, 0x05,

 // slots: signature, parameters, type, tag, flags
      72,   15,   15,   15, 0x0a,
      90,   85,   15,   15, 0x0a,
     119,  107,   15,   15, 0x0a,
     157,  152,   15,   15, 0x0a,
     188,  178,   15,   15, 0x0a,
     212,  206,   15,   15, 0x0a,
     239,  232,   15,   15, 0x0a,
     274,   15,  266,   15, 0x0a,
     291,   15,  266,   15, 0x0a,
     321,  312,   15,   15, 0x0a,
     345,  339,   15,   15, 0x0a,
     360,   15,   15,   15, 0x09,
     377,   48,   15,   15, 0x09,
     401,  397,   15,   15, 0x09,
     431,   15,   15,   15, 0x09,
     453,   15,   15,   15, 0x09,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__TextCell[] = {
    "IAEX::TextCell\0\0textChanged()\0textChanged(bool)\0link\0"
    "hoverOverUrl(QUrl)\0clickEvent()\0text\0setText(QString)\0text,format\0"
    "setText(QString,QTextCharFormat)\0html\0setTextHtml(QString)\0stylename\0"
    "setStyle(QString)\0style\0setStyle(CellStyle)\0number\0"
    "setChapterCounter(QString)\0QString\0ChapterCounter()\0"
    "ChapterCounterHtml()\0readonly\0setReadOnly(bool)\0focus\0"
    "setFocus(bool)\0contentChanged()\0hoverOverLink(QUrl)\0url\0"
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
        case 0: textChanged(); break;
        case 1: textChanged(*reinterpret_cast< bool*>(_a[1])); break;
        case 2: hoverOverUrl(*reinterpret_cast< QUrl*>(_a[1])); break;
        case 3: clickEvent(); break;
        case 4: setText(*reinterpret_cast< QString*>(_a[1])); break;
        case 5: setText(*reinterpret_cast< QString*>(_a[1]),*reinterpret_cast< QTextCharFormat*>(_a[2])); break;
        case 6: setTextHtml(*reinterpret_cast< QString*>(_a[1])); break;
        case 7: setStyle(*reinterpret_cast< QString*>(_a[1])); break;
        case 8: setStyle(*reinterpret_cast< CellStyle*>(_a[1])); break;
        case 9: setChapterCounter(*reinterpret_cast< QString*>(_a[1])); break;
        case 10: { QString _r = ChapterCounter();
            if (_a[0]) *reinterpret_cast< QString*>(_a[0]) = _r; }  break;
        case 11: { QString _r = ChapterCounterHtml();
            if (_a[0]) *reinterpret_cast< QString*>(_a[0]) = _r; }  break;
        case 12: setReadOnly(*reinterpret_cast< bool*>(_a[1])); break;
        case 13: setFocus(*reinterpret_cast< bool*>(_a[1])); break;
        case 14: contentChanged(); break;
        case 15: hoverOverLink(*reinterpret_cast< QUrl*>(_a[1])); break;
        case 16: openLinkInternal(*reinterpret_cast< const QUrl**>(_a[1])); break;
        case 17: textChangedInternal(); break;
        case 18: charFormatChanged(*reinterpret_cast< QTextCharFormat*>(_a[1])); break;
        }
        _id -= 19;
    }
    return _id;
}

// SIGNAL 0
void IAEX::TextCell::textChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, 0);
}

// SIGNAL 1
void IAEX::TextCell::textChanged(bool _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 1, _a);
}

// SIGNAL 2
void IAEX::TextCell::hoverOverUrl(const QUrl & _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 2, _a);
}
static const uint qt_meta_data_IAEX__MyTextBrowser[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
       4,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // signals: signature, parameters, type, tag, flags
      21,   20,   20,   20, 0x05,
      43,   20,   20,   20, 0x05,
      57,   20,   20,   20, 0x05,

 // slots: signature, parameters, type, tag, flags
      86,   81,   20,   20, 0x0a,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__MyTextBrowser[] = {
    "IAEX::MyTextBrowser\0\0openLink(const QUrl*)\0clickOnCell()\0"
    "wheelMove(QWheelEvent*)\0name\0setSource(QUrl)\0"
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
        case 3: setSource(*reinterpret_cast< QUrl*>(_a[1])); break;
        }
        _id -= 4;
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
