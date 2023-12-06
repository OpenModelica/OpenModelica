#ifndef ABSYN_COMMENT_H
#define ABSYN_COMMENT_H

#include <optional>
#include <iosfwd>

#include "MetaModelica.h"
#include "Annotation.h"

namespace OpenModelica::Absyn
{
  class Comment
  {
    public:
      Comment() = default;
      Comment(MetaModelica::Record value);
      Comment(std::string description, Annotation annotation = Annotation()) noexcept;

      MetaModelica::Value toSCode() const noexcept;

      std::optional<std::string> descriptionString() const noexcept;
      const Annotation& annotation() const noexcept;

      void printDescription(std::ostream &os, std::string_view indent = {}) const noexcept;
      void printAnnotation(std::ostream &os, std::string_view indent = {}) const noexcept;

    private:
      std::optional<std::string> _description;
      Annotation _annotation;
  };

  std::ostream& operator<< (std::ostream &os, const Comment &comment) noexcept;
}

#endif /* ABSYN_COMMENT_H */
