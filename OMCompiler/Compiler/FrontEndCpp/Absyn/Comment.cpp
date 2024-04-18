#include <ostream>

#include "Comment.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description SCode_Comment_COMMENT__desc;

Comment::Comment(MetaModelica::Record value)
  : _annotation{value[0].mapOptionalOrDefault<Annotation>()},
    _description{value[1].toOptional<std::string>()}
{
}

Comment::Comment(std::string description, Annotation annotation) noexcept
  : _description{std::move(description)}, _annotation{std::move(annotation)}
{

}

MetaModelica::Value Comment::toSCode() const noexcept
{
  return MetaModelica::Record(0, SCode_Comment_COMMENT__desc, {
    _annotation.toSCodeOpt(),
    MetaModelica::Option(_description)
  });
}

std::optional<std::string> Comment::descriptionString() const noexcept
{
  return _description;
}

const Annotation& Comment::annotation() const noexcept
{
  return _annotation;
}

void Comment::printDescription(std::ostream &os, std::string_view indent) const noexcept
{
  if (_description) {
    os << indent << '"' << *_description << '"';
  }
}

void Comment::printAnnotation(std::ostream &os, std::string_view indent) const noexcept
{
  if (!_annotation.modifier().isEmpty()) {
    os << indent << _annotation;
  }
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const Comment &comment) noexcept
{
  comment.printDescription(os, " ");
  comment.printAnnotation(os, " ");
  return os;
}
