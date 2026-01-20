# Copyright 2026 Vadim Ushakov <wandrien.dev@gmail.com>

proc SelectionToUpperCase {{w ""}} {
    ProcessSelection TextToUpperCase $w
}

proc SelectionToLowerCase {{w ""}} {
    ProcessSelection TextToLowerCase $w
}

proc SelectionToTitleCase {{w ""}} {
    ProcessSelection TextToTitleCase $w
}

proc SelectionToggleCase {{w ""}} {
    ProcessSelection TextToggleCase $w
}

proc SelectionToSentenceCase {{w ""}} {
    ProcessSelection TextToSentenceCase $w
}

################################################################################

proc TextToUpperCase {text} {
    return [string toupper $text]
}

proc TextToLowerCase {text} {
    return [string tolower $text]
}

proc TextToTitleCase {text} {
    set result ""
    set wordStart 1

    foreach char [split $text ""] {
        if {[string is alpha $char]} {
            if {$wordStart} {
                append result [string toupper $char]
                set wordStart 0
            } else {
                append result [string tolower $char]
            }
        } else {
            append result $char
            if {[string is space $char] || $char in {- _ . , ; : ! ? ( ) [ ]}} {
                set wordStart 1
            }
        }
    }

    return $result
}

proc TextToSentenceCase {text} {
    set text [TextToLowerCase $text]
    set result ""
    set sentenceStart 1
    set afterPunctuation 0

    foreach char [split $text ""] {
        if {[string is alpha $char]} {
            if {$sentenceStart} {
                append result [TextToUpperCase $char]
                set sentenceStart 0
            } else {
                append result $char
            }
            set afterPunctuation 0
        } elseif {$char in {. ! ?}} {
            append result $char
            set afterPunctuation 1
        } elseif {[string is space $char]} {
            append result $char
            if {$afterPunctuation} {
                set sentenceStart 1
            }
        } else {
            append result $char
            set afterPunctuation 0
        }
    }

    return $result
}

proc TextToggleCase {text} {
    set result ""

    foreach char [split $text ""] {
        if {[string is upper $char]} {
            append result [TextToLowerCase $char]
        } elseif {[string is lower $char]} {
            append result [TextToUpperCase $char]
        } else {
            append result $char
        }
    }

    return $result
}

################################################################################
# Identifier case conversion
################################################################################

proc IsIdentSeparator {char} {
    expr {$char eq "_" || $char eq "-" || [string is space $char]}
}
proc IsUpperChar {c} { string is upper -strict $c }
proc IsLowerChar {c} { string is lower -strict $c }
proc IsAlphaChar {c} { string is alpha -strict $c }
proc IsDigitChar {c} { string is digit -strict $c }

# Граница внутри "слитного" идентификатора (camel/pascal/акронимы/цифры):
#  - lower -> Upper    : twoWords
#  - digit <-> alpha   : word2Word, word2, 2word
#  - "HTTPServer"      : HTTP | Server (между P и S, т.к. S Upper и дальше lower)
proc IdentHasBoundary {prev cur next} {
    set prevLower [IsLowerChar $prev]
    set prevUpper [IsUpperChar $prev]
    set prevAlpha [IsAlphaChar $prev]
    set prevDigit [IsDigitChar $prev]

    set curUpper  [IsUpperChar $cur]
    set curAlpha  [IsAlphaChar $cur]
    set curDigit  [IsDigitChar $cur]

    set nextLower 0
    if {$next ne ""} {
        set nextLower [IsLowerChar $next]
    }

    if {$prevLower && $curUpper} {
        return 1
    }
    if {($prevAlpha && $curDigit) || ($prevDigit && $curAlpha)} {
        return 1
    }
    if {$prevUpper && $curUpper && $nextLower} {
        return 1
    }
    return 0
}

# Главная стадия №1: распознать границы частей и вернуть список частей.
proc IdentSplit {text} {
    set parts {}
    set token ""

    set len [string length $text]
    for {set i 0} {$i < $len} {incr i} {
        set c [string index $text $i]

        if {[IsIdentSeparator $c]} {
            if {$token ne ""} {
                lappend parts $token
                set token ""
            }
            continue
        }

        if {$token ne ""} {
            set prev [string index $text [expr {$i-1}]]
            if {$i+1 < $len} {
                set next [string index $text [expr {$i+1}]]
            } else {
                set next ""
            }

            if {[IdentHasBoundary $prev $c $next]} {
                lappend parts $token
                set token ""
            }
        }

        append token $c
    }

    if {$token ne ""} {
        lappend parts $token
    }

    return $parts
}

# Применение капитализации к одной части
proc IdentPartLower {p} { string tolower $p }
proc IdentPartUpper {p} { string toupper $p }
proc IdentPartTitle {p} {
    if {$p eq ""} { return "" }
    set p [string tolower $p]
    set first [string index $p 0]
    set rest  [string range $p 1 end]
    return "[string toupper $first]$rest"
}

proc IdentJoinAll {parts sep how} {
    set out ""
    set first 1
    foreach p $parts {
        if {!$first} { append out $sep } else { set first 0 }
        switch -- $how {
            lower { append out [IdentPartLower $p] }
            upper { append out [IdentPartUpper $p] }
            title { append out [IdentPartTitle $p] }
            default { error "Unknown case '$how'" }
        }
    }
    return $out
}

proc IdentJoinFirstRest {parts sep firstHow restHow} {
    if {[llength $parts] == 0} { return "" }

    set out ""
    set i 0
    foreach p $parts {
        if {$i > 0} { append out $sep }
        if {$i == 0} {
            set how $firstHow
        } else {
            set how $restHow
        }
        switch -- $how {
            lower { append out [IdentPartLower $p] }
            upper { append out [IdentPartUpper $p] }
            title { append out [IdentPartTitle $p] }
            default { error "Unknown case '$how'" }
        }
        incr i
    }
    return $out
}

################################################################################
# Stage №2: parts -> target representation
################################################################################

proc IdentToFlatCase {text} {
    return [IdentJoinAll [IdentSplit $text] "" lower]   ;# twowords / flatcase
}

proc IdentToUpperFlatCase {text} {
    return [IdentJoinAll [IdentSplit $text] "" upper]   ;# TWOWORDS / UPPERCASE
}

proc IdentToCamelCase {text} {
    return [IdentJoinFirstRest [IdentSplit $text] "" lower title] ;# twoWords
}

proc IdentToPascalCase {text} {
    return [IdentJoinAll [IdentSplit $text] "" title]   ;# TwoWords
}

proc IdentToSnakeCase {text} {
    return [IdentJoinAll [IdentSplit $text] "_" lower]  ;# two_words
}

proc IdentToScreamingSnakeCase {text} {
    return [IdentJoinAll [IdentSplit $text] "_" upper]  ;# TWO_WORDS
}

proc IdentToCamelSnakeCase {text} {
    return [IdentJoinFirstRest [IdentSplit $text] "_" lower title] ;# two_Words
}

proc IdentToTitleSnakeCase {text} {
    return [IdentJoinAll [IdentSplit $text] "_" title]  ;# Two_Words (Title_Case)
}

proc IdentToKebabCase {text} {
    return [IdentJoinAll [IdentSplit $text] "-" lower]  ;# two-words
}

proc IdentToScreamingKebabCase {text} {
    return [IdentJoinAll [IdentSplit $text] "-" upper]  ;# TWO-WORDS
}

proc IdentToTrainCase {text} {
    return [IdentJoinAll [IdentSplit $text] "-" title]  ;# Two-Words
}

proc IdentToWords {text} {
    return [IdentJoinAll [IdentSplit $text] " " lower]  ;# two words (space separated)
}

################################################################################

proc SelectionToFlatCase {{w ""}}            { ProcessSelection IdentToFlatCase $w }
proc SelectionToUpperFlatCase {{w ""}}       { ProcessSelection IdentToUpperFlatCase $w }
proc SelectionToCamelCase {{w ""}}           { ProcessSelection IdentToCamelCase $w }
proc SelectionToPascalCase {{w ""}}          { ProcessSelection IdentToPascalCase $w }
proc SelectionToSnakeCase {{w ""}}           { ProcessSelection IdentToSnakeCase $w }
proc SelectionToScreamingSnakeCase {{w ""}}  { ProcessSelection IdentToScreamingSnakeCase $w }
proc SelectionToCamelSnakeCase {{w ""}}      { ProcessSelection IdentToCamelSnakeCase $w }
proc SelectionToTitleSnakeCase {{w ""}}      { ProcessSelection IdentToTitleSnakeCase $w }
proc SelectionToKebabCase {{w ""}}           { ProcessSelection IdentToKebabCase $w }
proc SelectionToScreamingKebabCase {{w ""}}  { ProcessSelection IdentToScreamingKebabCase $w }
proc SelectionToTrainCase {{w ""}}           { ProcessSelection IdentToTrainCase $w }
proc SelectionToWords {{w ""}}               { ProcessSelection IdentToWords $w }
