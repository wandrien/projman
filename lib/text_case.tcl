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
