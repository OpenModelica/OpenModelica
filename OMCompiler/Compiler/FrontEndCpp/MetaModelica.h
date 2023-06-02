#ifndef METAMODELICA_H
#define METAMODELICA_H

#include <cstdint>
#include <string>
#include <ostream>

namespace OpenModelica
{
  namespace MetaModelica
  {
    class Option;
    class List;
    class Array;
    class Tuple;
    class Record;

    class Value
    {
      public:
        enum class Type
        {
          integer,
          real,
          string,
          option,
          list,
          array,
          tuple,
          record,
          unknown
        };

        class ArrowProxy;

      public:
        Value(void *value) noexcept;

        Type getType() const noexcept;
        bool isInteger() const noexcept;
        bool isReal() const noexcept;
        bool isBoolean() const noexcept;
        bool isString() const noexcept;
        bool isOption() const noexcept;
        bool isList() const noexcept;
        bool isArray() const noexcept;
        bool isTuple() const noexcept;
        bool isRecord() const noexcept;

        int64_t toInt() const;
        double toDouble() const;
        bool toBool() const;
        std::string toString() const;
        Option toOption() const;
        List toList() const;
        Array toArray() const;
        Tuple toTuple() const;
        Record toRecord() const;

        void* data() const noexcept;

      private:
        void *_value;
    };

    class Value::ArrowProxy
    {
      public:
        ArrowProxy(void *value) noexcept : _value(value) {}
        Value operator->() const noexcept { return _value; }

      private:
        Value _value;
    };

    std::ostream& operator<< (std::ostream &os, Value value) noexcept;

    class Option
    {
      public:
        Option(void *value) noexcept;

        Value operator*() const noexcept;
        Value::ArrowProxy operator->() const noexcept;
        explicit operator bool() const noexcept;

        bool hasValue() const noexcept;
        Value value() const;

      private:
        void *_value;
    };

    std::ostream& operator<< (std::ostream &os, Option option) noexcept;

    class List
    {
      public:
        class ConstIterator
        {
          public:
            using iterator_category = std::forward_iterator_tag;
            using difference_type   = std::ptrdiff_t;
            using value_type        = Value;
            using pointer           = value_type*;
            using reference         = value_type&;

            ConstIterator(void *value) noexcept;

            value_type operator*() const noexcept;
            Value::ArrowProxy operator->() const noexcept;
            ConstIterator& operator++() noexcept;
            ConstIterator operator++(int) noexcept;

            friend bool operator== (const ConstIterator &i1, const ConstIterator &i2) noexcept;
            friend bool operator!= (const ConstIterator &i1, const ConstIterator &i2) noexcept;

          private:
            void *_value;
        };

      public:
        List(void *value) noexcept;

        Value front() const noexcept;
        List rest() const noexcept;
        ConstIterator begin() const noexcept;
        ConstIterator cbegin() const noexcept;
        ConstIterator end() const noexcept;
        ConstIterator cend() const noexcept;
        bool empty() const noexcept;
        size_t size() const noexcept;

      private:
        void *_value;
    };

    bool operator== (const List::ConstIterator &i1, const List::ConstIterator &i2) noexcept;
    bool operator!= (const List::ConstIterator &i1, const List::ConstIterator &i2) noexcept;
    std::ostream& operator<< (std::ostream &os, List list) noexcept;

    class IndexedConstIterator
    {
      public:
        using iterator_category = std::forward_iterator_tag;
        using difference_type   = std::ptrdiff_t;
        using value_type        = Value;
        using pointer           = value_type*;
        using reference         = value_type&;

        IndexedConstIterator(void *value, size_t index) noexcept;

        value_type operator*() const noexcept;
        Value::ArrowProxy operator->() const noexcept;
        IndexedConstIterator& operator++() noexcept;
        IndexedConstIterator operator++(int) noexcept;

        friend bool operator== (const IndexedConstIterator &i1, const IndexedConstIterator &i2) noexcept;
        friend bool operator!= (const IndexedConstIterator &i1, const IndexedConstIterator &i2) noexcept;

      private:
        void *_value;
        size_t _index = 0;
    };

    bool operator== (const IndexedConstIterator &i1, const IndexedConstIterator &i2) noexcept;
    bool operator!= (const IndexedConstIterator &i1, const IndexedConstIterator &i2) noexcept;

    class Array
    {
      public:
        Array(void *value) noexcept;

        Value front() const noexcept;
        Value back() const noexcept;
        IndexedConstIterator begin() const noexcept;
        IndexedConstIterator cbegin() const noexcept;
        IndexedConstIterator end() const noexcept;
        IndexedConstIterator cend() const noexcept;
        bool empty() const noexcept;
        size_t size() const noexcept;

        Value operator[](size_t index) const noexcept;
        Value at(size_t index) const;

      private:
        void *_value;
    };

    std::ostream& operator<< (std::ostream &os, Array array) noexcept;

    class Tuple
    {
      public:
        Tuple(void *value) noexcept;

        IndexedConstIterator begin() const noexcept;
        IndexedConstIterator cbegin() const noexcept;
        IndexedConstIterator end() const noexcept;
        IndexedConstIterator cend() const noexcept;
        size_t size() const noexcept;

        Value operator[](size_t index) const noexcept;
        Value at(size_t index) const;

      private:
        void *_value;
    };

    std::ostream& operator<< (std::ostream &os, Tuple tuple) noexcept;

    class Record
    {
      public:
        Record(void *value) noexcept;

        std::string name() const noexcept;
        IndexedConstIterator begin() const noexcept;
        IndexedConstIterator cbegin() const noexcept;
        IndexedConstIterator end() const noexcept;
        IndexedConstIterator cend() const noexcept;
        size_t size() const noexcept;

        // TODO: Change to C++17 and use string_view instead.
        Value operator[](const std::string &name) const noexcept;
        Value operator[](size_t index) const noexcept;
        Value at(size_t index) const;
        IndexedConstIterator find(const std::string &name) const noexcept;
        bool contains(const std::string &name) const noexcept;

      private:
        void *_value;
    };

    std::ostream& operator<< (std::ostream &os, Record record) noexcept;
  }
}

#endif /* METAMODELICA_H */
