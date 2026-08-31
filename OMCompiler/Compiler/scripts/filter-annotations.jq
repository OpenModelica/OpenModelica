# Filter annotations of interest out of a modelInstance.json file produced by
# the OpenModelica getModelInstance API. Used by the Cpp FMU export when the
# --fmiExtraAnnotations=<regex> flag is set.
#
# Usage:
#   jq --arg regex "__Optimization|__Estimation" -f filter-annotations.jq Model_modelInstance.json > modelAnnotations.json
def keep_annotation:
  if type == "object" then
    if (.prefixes? | type) == "object" and (.prefixes.outer? // false) then
      null
    else
      (
        . as $obj
        # place dims first to know them when parsing a name or type in one pass
        # | reduce ($obj | keys_unsorted[]) as $k
        | reduce ((if has("dims") then {dims} else {} end)
                  + with_entries(select(.key != "dims")) | keys_unsorted[]) as $k
            ({};
              if $k | test($regex) then
                . + {($k): $obj[$k]}
              elif ($k == "name" or $k == "restriction" or $k == "dims")
                    and ($obj | any(.. | objects; .annotation? | objects | keys | any(test($regex)))) then
                . + if $k == "dims" then {($k): $obj[$k]["typed"]} else {($k): $obj[$k]} end
              else
                ($obj[$k] | keep_annotation) as $v
                | if $v == null or $v == {} or $v == [] then
                    .
                  else
                    . + {($k): $v}
                  end
              end
            )
      )
      | if . == {} then null else . end
    end
  elif type == "array" then
    map(keep_annotation)
    | map(select(. != null and . != {} and . != []))
    | if length == 0 then null else . end
  else null
  end;

keep_annotation
