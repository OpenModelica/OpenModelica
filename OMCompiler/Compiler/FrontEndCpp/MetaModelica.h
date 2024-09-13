#ifndef METAMODELICA_H
#define METAMODELICA_H

#include <cstdint>
#include <cstddef>
#include <string>
#include <string_view>
#include <iosfwd>
#include <optional>
#include <functional>
#include <memory>
#include <initializer_list>
#include <iterator>
#include <vector>
#include <type_traits>

struct record_description;

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
        explicit Value(void *value) noexcept;
        explicit Value(int64_t value) noexcept;
        explicit Value(int value) noexcept;
        explicit Value(double value) noexcept;
        explicit Value(bool value) noexcept;
        explicit Value(std::string_view value) noexcept;
        explicit Value(const char *value) noexcept;

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

        // Converts an Option value to an std::optional<T> using T(value).
        template<typename T> std::optional<T> mapOptional() const;
        // Converts an Option value to a T using T(value) if the Option contains
        // a value and T() otherwise.
        template<typename T> T mapOptionalOrDefault() const;
        // Converts an Option value to an std::unique_ptr<T> using T(value).
        template<typename T> std::unique_ptr<T> mapPointer() const;
        // Converts an Array or List value to an std::vector<T> using T(value)
        // for each value in the array/list.
        template<typename T> std::vector<T> mapVector() const;
        // Converts an Array or List value to an std::vector<T> using f(value)
        // for each value in the array/list.
        template<typename ConvertFunc, typename T = typename std::invoke_result<ConvertFunc, Value>::type>
        std::vector<T> mapVector(ConvertFunc f) const;

        // Converts the value using the corresponding Value::toX method for T.
        template<typename T> T to() const;
        // Converts an Option value to an std::optional<T> using the corresponding
        // Value::toX method for T.
        template<typename T> std::optional<T> toOptional() const;
        // Converts an Array or List value to an std::vector<T> using the
        // corresponding Value::toX method for T.
        template<typename T> std::vector<T> toVector() const;

        explicit operator bool() const;

        std::string name() const noexcept;
        void* data() const noexcept;

      private:
        void *_value;
    };

    class Value::ArrowProxy
    {
      public:
        explicit ArrowProxy(void *value) noexcept : _value{value} {}
        const Value* operator->() const noexcept { return &_value; }

      private:
        Value _value;
    };

    std::ostream& operator<< (std::ostream &os, Value value) noexcept;

    class Option
    {
      public:
        Option() noexcept;
        explicit Option(Value value) noexcept;
        explicit Option(void *value) noexcept;

        template<typename T>
        explicit Option(const std::optional<T> &value) noexcept
          : Option(value ? Value{*value} : Value{static_cast<void*>(nullptr)})
        {

        }

        template<typename T, typename ConvertFunc>
        Option(const std::optional<T> &value, ConvertFunc f) noexcept
          : Option(value ? f(*value) : Value{static_cast<void*>(nullptr)})
        {

        }

        template<typename T>
        explicit Option(T *value) noexcept
          : Option(value ? Value{*value} : Value{static_cast<void*>(nullptr)})
        {

        }

        template<typename T, typename ConvertFunc>
        Option(T *value, ConvertFunc f) noexcept
          : Option(value ? f(*value) : Value{static_cast<void*>(nullptr)})
        {

        }

        operator Value() const noexcept { return Value(_value); };
        Value operator*() const noexcept;
        Value::ArrowProxy operator->() const noexcept;
        explicit operator bool() const noexcept;

        bool hasValue() const noexcept;
        Value value() const;
        void* data() const noexcept;

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

            explicit ConstIterator(void *value) noexcept;

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
        List() noexcept;
        explicit List(void *value) noexcept;

        // Constructs a List from a container of a type convertible to Value.
        template<typename Container>
        explicit List(const Container &values) noexcept
          : List()
        {
          for (auto it = values.rbegin(); it != values.rend(); ++it) {
            cons(Value{*it});
          }
        }

        // Constructs a List from an iterator range of a type convertible to Value.
        template<typename BidirIt>
        List(BidirIt first, BidirIt last) noexcept
          : List()
        {
          auto it = std::make_reverse_iterator(last);
          auto end = std::make_reverse_iterator(first);

          for (; it != end; ++it) {
            cons(Value{*it});
          }
        }

        // Constructs a List from a container using the given conversion
        // function to convert each element to a Value.
        template<typename Container, typename ConvertFunc>
        List(const Container &values, ConvertFunc f) noexcept
          : List()
        {
          for (auto it = values.rbegin(); it != values.rend(); ++it) {
            cons(f(*it));
          }
        }

        // Constructs a List from an iterator range using the given conversion
        // function to convert each element to a Value.
        template<typename BidirIt, typename ConvertFunc>
        List(BidirIt first, BidirIt last, ConvertFunc f) noexcept
          : List()
        {
          auto it = std::make_reverse_iterator(last);
          auto end = std::make_reverse_iterator(first);

          for (; it != end; ++it) {
            cons(f(*it));
          }
        }

        operator Value() const noexcept { return Value{_value}; }

        Value front() const noexcept;
        List rest() const noexcept;
        ConstIterator begin() const noexcept;
        ConstIterator cbegin() const noexcept;
        ConstIterator end() const noexcept;
        ConstIterator cend() const noexcept;
        bool empty() const noexcept;
        std::size_t size() const noexcept;

        void cons(Value v) noexcept;
        void* data() const noexcept;

        template<typename T>
        std::vector<T> mapVector() const
        {
          std::vector<T> v;
          v.reserve(size());
          for (const auto e: *this) v.emplace_back(e);
          return v;
        }

        template<typename ConvertFunc, typename T = typename std::invoke_result<ConvertFunc, Value>::type>
        std::vector<T> mapVector(ConvertFunc f) const
        {
          std::vector<T> v;
          v.reserve(size());
          for (const auto e: *this) v.emplace_back(f(e));
          return v;
        }

        template<typename T>
        std::vector<T> toVector() const
        {
          std::vector<T> v;
          v.reserve(size());
          for (const auto e: *this) v.emplace_back(e.to<T>());
          return v;
        }
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

        IndexedConstIterator(void *value, std::size_t index) noexcept;

        value_type operator*() const noexcept;
        Value::ArrowProxy operator->() const noexcept;
        IndexedConstIterator& operator++() noexcept;
        IndexedConstIterator operator++(int) noexcept;

        friend bool operator== (const IndexedConstIterator &i1, const IndexedConstIterator &i2) noexcept;
        friend bool operator!= (const IndexedConstIterator &i1, const IndexedConstIterator &i2) noexcept;

      private:
        void *_value;
        std::size_t _index = 0;
    };

    bool operator== (const IndexedConstIterator &i1, const IndexedConstIterator &i2) noexcept;
    bool operator!= (const IndexedConstIterator &i1, const IndexedConstIterator &i2) noexcept;

    class Array
    {
      public:
        explicit Array(void *value) noexcept;

        Value front() const noexcept;
        Value back() const noexcept;
        IndexedConstIterator begin() const noexcept;
        IndexedConstIterator cbegin() const noexcept;
        IndexedConstIterator end() const noexcept;
        IndexedConstIterator cend() const noexcept;
        bool empty() const noexcept;
        std::size_t size() const noexcept;

        Value operator[](std::size_t index) const noexcept;
        Value at(std::size_t index) const;
        void* data() const noexcept;

        template<typename T>
        std::vector<T> mapVector() const
        {
          std::vector<T> v;
          v.reserve(size());
          for (const auto e: *this) v.emplace_back(e);
          return v;
        }

        template<typename ConvertFunc, typename T = typename std::invoke_result<ConvertFunc, Value>::type>
        std::vector<T> mapVector(ConvertFunc f) const
        {
          std::vector<T> v;
          v.reserve(size());
          for (const auto e: *this) v.emplace_back(f(e));
          return v;
        }

        template<typename T>
        std::vector<T> toVector() const
        {
          std::vector<T> v;
          v.reserve(size());
          for (const auto e: *this) v.emplace_back(e.to<T>());
          return v;
        }
      private:
        void *_value;
    };

    std::ostream& operator<< (std::ostream &os, Array array) noexcept;

    class Tuple
    {
      public:
        explicit Tuple(void *value) noexcept;
        explicit Tuple(std::initializer_list<Value> lst) noexcept;

        operator Value() const noexcept { return Value{_value}; }

        IndexedConstIterator begin() const noexcept;
        IndexedConstIterator cbegin() const noexcept;
        IndexedConstIterator end() const noexcept;
        IndexedConstIterator cend() const noexcept;
        std::size_t size() const noexcept;

        Value operator[](std::size_t index) const noexcept;
        Value at(std::size_t index) const;
        void* data() const noexcept;

      private:
        void *_value;
    };

    std::ostream& operator<< (std::ostream &os, Tuple tuple) noexcept;

    class Record
    {
      public:
        explicit Record(void *value) noexcept;
        Record(Value value);
        Record(int index, record_description &desc, std::initializer_list<Value> values = {});

        operator Value() const noexcept { return Value{_value}; }

        // Returns the full name of the record (e.g. SCode.Element.CLASS).
        std::string fullName() const noexcept;
        // Returns the name of the uniontype (e.g. SCode.Element).
        std::string uniontypeName() const noexcept;
        // Returns the name of the record (e.g. CLASS).
        std::string recordName() const noexcept;
        // The index of the record in the uniontype, starting from 0.
        int index() const noexcept;

        IndexedConstIterator begin() const noexcept;
        IndexedConstIterator cbegin() const noexcept;
        IndexedConstIterator end() const noexcept;
        IndexedConstIterator cend() const noexcept;
        std::size_t size() const noexcept;

        Value operator[](std::string_view name) const noexcept;
        Value operator[](std::size_t index) const noexcept;
        Value at(std::size_t index) const;
        IndexedConstIterator find(std::string_view name) const noexcept;
        bool contains(std::string_view name) const noexcept;
        void* data() const noexcept;

      private:
        void *_value;
    };

    std::ostream& operator<< (std::ostream &os, Record record) noexcept;

    template<typename T> std::optional<T> Value::mapOptional() const
    {
      auto o = toOption();
      return o ? std::make_optional(T(o.value())) : std::nullopt;
    }

    template<typename T> T Value::mapOptionalOrDefault() const
    {
      auto o = toOption();
      return o ? T(o.value()) : T();
    }

    template<typename T> std::unique_ptr<T> Value::mapPointer() const
    {
      auto o = toOption();
      return o ? std::make_unique<T>(o.value()) : nullptr;
    }

    template<typename T>
    std::vector<T> Value::mapVector() const
    {
      return isList() ? toList().mapVector<T>() : toArray().mapVector<T>();
    }

    template<typename ConvertFunc, typename T>
    std::vector<T> Value::mapVector(ConvertFunc f) const
    {
      return isList() ? toList().mapVector(f) : toArray().mapVector(f);
    }

    template<typename T>
    std::optional<T> Value::toOptional() const
    {
      auto o = toOption();
      return o ? std::make_optional(o->to<T>()) : std::nullopt;
    }

    template<typename T>
    std::vector<T> Value::toVector() const
    {
      return isList() ? toList().toVector<T>() : toArray().toVector<T>();
    }
  }
}

#endif /* METAMODELICA_H */
