########################################################
#
#-------------------------------------------------------
# "PROCNAME" in procFindString will be changed on
# "procName" from procRegexpCommand
#-------------------------------------------------------
# TCL/TK
dict set lexers TCL commentSymbol {#}
dict set lexers TCL variableSymbol {$}
dict set lexers TCL procFindString {proc PROCNAME}
dict set lexers TCL procRegexpCommand {regexp -nocase -all -- {^\s*?(proc) (.*?) \{(.*?)\} \{} $line match keyWord procName params}
dict set lexers TCL varRegexpCommand {regexp -nocase -all -- {^\s*?set\s+([a-zA-Z0-9\:\-_$]+)\s+(.+?)($|;)} $line match varName varValue lineEnd}
dict set lexers TCL commands [info commands]

#--------------------------------------------------
# Go lang
dict set lexers GO commentSymbol {//}
dict set lexers GO procFindString {func.*?PROCNAME}
dict set lexers GO procRegexpCommand {regexp -nocase -all -- {\s*?func\s*?(\(\w+\s*?\**?\w+\)|)\s*?(\w+)\((.*?)\)\s+?([a-zA-Z0-9\{\}\[\]\(\)-_.]*?|)\s*?\{} $line match linkName procName params returns}
dict set lexers GO varRegexpCommand {regexp -nocase -all -line -- {^\s*?var\s+([a-zA-Z0-9\-_$]+)\s+(.+?)(\s*$)} $line match varName varType lineEnd}
#--------------------------------------------------
# SHELL (Bash)
dict set lexers SH commentSymbol {#}
dict set lexers SH variableSymbol {$}
dict set lexers SH procFindString {(function |)\s*?PROCNAME\(\)}
dict set lexers SH procRegexpCommand {regexp -nocase -all -- {^\s*?(function |)\s*?(.*?)\(()\)} $line match keyWord procName params}

#--------------------------------------------------
# Python 
dict set lexers PY commentSymbol {#}
dict set lexers PY procFindString {(def )\s*?PROCNAME}
dict set lexers PY procRegexpCommand {regexp -nocase -all -- {^\s*?(def)\s*?(.*?)\((.*?)\):} $line match keyWord procName params}

#--------------------------------------------------
# Ruby 
dict set lexers RB commentSymbol {#}
dict set lexers RB tabSize 2
dict set lexers RB procFindString {(def |class )\s*?PROCNAME}
dict set lexers RB procRegexpCommand {regexp -nocase -all -- {^\s*?(def|class)\s([a-zA-Z0-9\-_:\?]+?)($|\s|\(.+?\))} $line match keyWord procName params}

#--------------------------------------------------
# YAML (ansible)
dict set lexers YML commentSymbol {#}
# dict set lexers YML variableSymbol {\{\{}
dict set lexers YML tabSize 2
dict set lexers YML procFindString {(- name:)\s*?PROCNAME}
dict set lexers YML procRegexpCommand {regexp -nocase -all -- {^\s*?- (name):\s(.+?)$} $line match keyWord procName}
dict set lexers YML varRegexpCommand {regexp -nocase -all -- {^(\s*?)([a-zA-Z0-9\-_$]+):\s+(.+?)(\s*$)} $line match indent varName varValue lineEnd}
dict set lexers YML varRegexpCommandMultiline {regexp -all -line -- {^(\s*)(set_fact|vars):$} $line match indent keyWord}

#--------------------------------------------------
# MD (markdown)
dict set lexers MD tabSize 2
dict set lexers MD procFindString {(#+?)\s*?PROCNAME}
dict set lexers MD procRegexpCommand {regexp -nocase -all -- {^(#+?)\s(.+?)$} $line match keyWord procName}
# dict set lexers YML varRegexpCommandMultiline {regexp -all -line -- {^(\s*)(set_fact|vars):$} $line match indent keyWord}

#--------------------------------------------------
# Perl
dict set lexers PL commentSymbol {#}
dict set lexers PL variableSymbol {$}
dict set lexers PL tabSize 4
dict set lexers PL procFindString {(sub )\s*?PROCNAME}
dict set lexers PL procRegexpCommand {regexp -nocase -all -- {^\s*?(sub)\s([a-zA-Z0-9\-_:]+?)($|\(.+?\))} $line match keyWord procName params}
dict set lexers PL varRegexpCommand {regexp -nocase -all -- {^(\s*?)\$([a-zA-Z0-9\-_$]+)\s+=\s+(.+?)(\s*;$)} $line match indent varName varValue lineEnd}

#--------------------------------------------------
# Perl
dict set lexers INI commentSymbol {#}
dict set lexers INI tabSize 4
dict set lexers INI procFindString {(\[)PROCNAME(\])}
dict set lexers INI procRegexpCommand {regexp -nocase -all -- {^\s*?(\[)([a-zA-Z0-9\-_:]+?)(\])$} $line match keyWord procName}

# -------------------------------------------------
dict set lexers ALL varDirectory {variables vars group_vars host_vars defaults}
