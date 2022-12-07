######################################################
#                ProjMan 2
#        Distributed under GNU Public License
# Author: Sergey Kalinin svk@nuk-svk.ru
# Copyright (c) "", 2022, https://nuk-svk.ru
######################################################
namespace eval Highlight {} {
    proc TCL {txt} {
        ctext::addHighlightClassForRegexp $txt flags orange {\s-[a-zA-Z]+}
        ctext::addHighlightClass $txt stackControl #19a2a6 [info commands]
        ctext::addHighlightClass $txt widgets #9d468d [list canvas ctext button entry label text labelframe frame toplevel scrollbar checkbutton canvas listbox menu menubar menubutton  radiobutton scale entry message tk_chooseDir tk_getSaveFile  tk_getOpenFile tk_chooseColor tk_optionMenu ttk::button ttk::checkbutton ttk::combobox ttk::entry ttk::frame ttk::intro ttk::label ttk::labelframe ttk::menubutton ttk::treeview ttk::notebook ttk::panedwindow ttk::progressbar ttk::radiobutton ttk::scale ttk::scrollbar ttk::separator ttk::sizegrip ttk::spinbox ]
        ctext::addHighlightClassWithOnlyCharStart $txt vars #4471ca "\$"
        ctext::addHighlightClass $txt variable_funcs gold {set global variable unset}
        ctext::addHighlightClassForSpecialChars $txt brackets green {[]{}()}
        ctext::addHighlightClassForRegexp $txt paths lightblue {\.[a-zA-Z0-9\_\-]+}
        ctext::addHighlightClassForRegexp $txt comments #666666 {(#|//)[^\n\r]*}    
        ctext::addHighlightClassForRegexp $txt namespaces #4f64ff {::}
        ctext::addHighlightClassForSpecialChars $txt qoute #b84a0c {"'`}
    }

    proc Default {txt} {
        ctext::addHighlightClassForRegexp $txt flags orange {\s-[a-zA-Z\-_]+}
        ctext::addHighlightClass $txt stackControl #19a2a6 [info commands]
        ctext::addHighlightClassWithOnlyCharStart $txt vars #4471ca "\$"
        ctext::addHighlightClass $txt variable_funcs gold {set global variable unset}
        ctext::addHighlightClassForSpecialChars $txt brackets green {[]{}()}
        ctext::addHighlightClassForRegexp $txt paths lightblue {\.[a-zA-Z0-9\_\-]+}
        ctext::addHighlightClassForRegexp $txt comments #666666 {(#|//)[^\n\r]*}    
        ctext::addHighlightClassForRegexp $txt namespaces #4f64ff {::}
        ctext::addHighlightClassForSpecialChars $txt qoute #b84a0c {"'`}
    }
    
    proc SH {txt} {
        ctext::addHighlightClassForRegexp $txt flags orange {-+[a-zA-Z\-_]+}
        ctext::addHighlightClass $txt stackControl #19a2a6 {if fi else elseif then while case esac do in exit source echo package mkdir ls rm sed awk grep date jq zip tar gzip mount umount test make curl git iconv less gcc scp rsync cut tr function}
        ctext::addHighlightClassWithOnlyCharStart $txt vars #4471ca "\$"
        ctext::addHighlightClassForRegexp $txt vars_extended #4471ca {\$\{[a-zA-Z0-9\_\-:\./\$\{\}]+\}}
        ctext::addHighlightClass $txt variable_funcs gold {set export}
        ctext::addHighlightClassForSpecialChars $txt brackets green {[]{}()}
        ctext::addHighlightClassForRegexp $txt paths lightblue {\.[a-zA-Z0-9\_\-]+}
        ctext::addHighlightClassForRegexp $txt comments #666666 {(#|//)[^\n\r]*}    
        ctext::addHighlightClassForSpecialChars $txt qoute #b84a0c {"'`}
    }
    
    proc GO {txt} {
        ctext::addHighlightClassForRegexp $txt flags orange {-+[a-zA-Z\-_]+}
        ctext::addHighlightClass $txt stackControl #19a2a6 {break default func goto select case defer if map chan else import package switch const fallthrough interface  range continue for go return}
        ctext::addHighlightClass $txt types #7187d5 {string int int16 int32 int64 float bool byte}
        ctext::addHighlightClassWithOnlyCharStart $txt vars #4471ca "\&"
        ctext::addHighlightClassWithOnlyCharStart $txt vars #4471ca "\*"
        # ctext::addHighlightClassForRegexp $txt vars_extended #4471ca {\$\{[a-zA-Z0-9\_\-:\./\$\{\}]+\}}
        ctext::addHighlightClass $txt variable_funcs gold {var type struct}
        ctext::addHighlightClassForSpecialChars $txt brackets green {[]{}()}
        ctext::addHighlightClassForRegexp $txt paths lightblue {\.[a-zA-Z0-9\_\-]+}
        ctext::addHighlightClassForRegexp $txt comments #666666 {(#|//)[^\n\r]*}    
        ctext::addHighlightClassForSpecialChars $txt qoute #b84a0c {"'`}
    }

    proc PY {txt} {
        ctext::addHighlightClassForRegexp $txt flags orange {-+[a-zA-Z\-_]+}
        ctext::addHighlightClass $txt stackControl #19a2a6 {if else: elif for while case switch def import from return make break defer continue package len print with open try: except: in}
        ctext::addHighlightClass $txt types #7187d5 {string int int16 int32 int64 float bool byte}
        ctext::addHighlightClassWithOnlyCharStart $txt vars #4471ca "\&"
        ctext::addHighlightClassWithOnlyCharStart $txt vars #4471ca "\*"
        # ctext::addHighlightClass $txt variable_funcs gold {var type struct}
        ctext::addHighlightClassForSpecialChars $txt brackets green {[]{}()}
        ctext::addHighlightClassForRegexp $txt paths lightblue {\.[a-zA-Z0-9\_\-]+}
        ctext::addHighlightClassForRegexp $txt comments #666666 {(#|//)[^\n\r]*}    
        ctext::addHighlightClassForSpecialChars $txt qoute #b84a0c {"'`}
    }
    proc YAML {txt} {
        ctext::addHighlightClassForRegexp $txt qoute #b84a0c {("|'|`).*?("|'|`)}
        ctext::addHighlightClassForRegexp $txt stackControl #19a2a6 {\s*?[\w]+:}
        ctext::addHighlightClassForRegexp $txt vars #4471ca {(\$|\*|\&)[\.a-zA-Z0-9\_\-]+}
        ctext::addHighlightClassForRegexp $txt varsansible #4471ca {(\{\{)(\s*?|)[\.a-zA-Z0-9\_\-]+((\s*?|))(\}\})}
        ctext::addHighlightClassForSpecialChars $txt brackets green {[]{}()}
        ctext::addHighlightClassForRegexp $txt paths lightblue {\.[a-zA-Z0-9\_\-]+}
        ctext::addHighlightClassForRegexp $txt comments #666666 {(#|//)[^\n\r]*}    
    }
    proc YML {txt} {
        ctext::addHighlightClassForRegexp $txt qoute #b84a0c {("|'|`).*?("|'|`)}
        ctext::addHighlightClassForRegexp $txt stackControl #19a2a6 {\s*?[\w]+:}
        ctext::addHighlightClassForRegexp $txt vars #4471ca {(\$|\*|\&)(\{|)[\.a-zA-Z0-9\_\-]+}
        ctext::addHighlightClassForRegexp $txt varsansible #4471ca {(\{\{)(\s*?|)[\.a-zA-Z0-9\_\-]+((\s*?|))(\}\})}
        ctext::addHighlightClassForSpecialChars $txt brackets green {[]{}()}
        ctext::addHighlightClassForRegexp $txt paths lightblue {\.[a-zA-Z0-9\_\-]+}
        ctext::addHighlightClassForRegexp $txt comments #666666 {(#|//)[^\n\r]*}    
    }
    proc XML {txt} {
        ctext::addHighlightClassForRegexp $txt qoute #b84a0c {("|'|`).*?("|'|`)}
        ctext::addHighlightClassForRegexp $txt stackControl #19a2a6 {(<|<\\)*?[\w]+>}
        ctext::addHighlightClassForRegexp $txt vars #4471ca {(\$|\*|\&)[\.a-zA-Z0-9\_\-]+}
        ctext::addHighlightClassForSpecialChars $txt brackets green {[]{}()}
        # ctext::addHighlightClassForRegexp $txt paths lightblue {\.[a-zA-Z0-9\_\-]+}
        # ctext::addHighlightClassForRegexp $txt comments #666666 {(#|//)[^\n\r]*}    
        ctext::addHighlightClassForSpecialChars $txt tags #666666 {<>/}
    }
    proc RB {txt} {
        ctext::addHighlightClassForRegexp $txt qoute #b84a0c {("|'|`).*?("|'|`)}
        ctext::addHighlightClassForRegexp $txt flags orange {\s-[a-zA-Z]+}
        ctext::addHighlightClass $txt stackControl #19a2a6 {def end class if else for while case when}
        # ctext::addHighlightClass $txt widgets #9d468d [list canvas ctext button entry label text labelframe frame toplevel scrollbar checkbutton canvas listbox menu menubar menubutton  radiobutton scale entry message tk_chooseDir tk_getSaveFile  tk_getOpenFile tk_chooseColor tk_optionMenu ttk::button ttk::checkbutton ttk::combobox ttk::entry ttk::frame ttk::intro ttk::label ttk::labelframe ttk::menubutton ttk::treeview ttk::notebook ttk::panedwindow ttk::progressbar ttk::radiobutton ttk::scale ttk::scrollbar ttk::separator ttk::sizegrip ttk::spinbox ]
        ctext::addHighlightClassForRegexp $txt vars #4471ca {(\$|\*|\&)[\.a-zA-Z0-9\_\-\[\]]+}
        # ctext::addHighlightClass $txt variable_funcs gold {set global variable unset}
        ctext::addHighlightClassForSpecialChars $txt brackets green {[]{}()}
        ctext::addHighlightClassForRegexp $txt paths lightblue {\.[a-zA-Z0-9\_\-]+}
        ctext::addHighlightClassForRegexp $txt comments #666666 {(#|//)[^\n\r]*}    
        ctext::addHighlightClassForRegexp $txt namespaces #4f64ff {::}
    }
    proc MD {txt} {
        ctext::addHighlightClassForRegexp $txt comments #666666 {^\s+?(#|//).*$}
        ctext::addHighlightClassForRegexp $txt lists #4471ca {(\*|-|\+)+}
        ctext::addHighlightClassForSpecialChars $txt brackets green {[]{}()}
        ctext::addHighlightClassForRegexp $txt url #19a2a6 {(http|https|ftp|ssh)(://)(\w|\.|-|/)+?}
        ctext::addHighlightClassForRegexp $txt email #467a7b {(\w|\.|-)+?(@)(\w|\.|-)+?($|\s)}
        ctext::addHighlightClassForRegexp $txt qoute #b84a0c {("|'|`).*?("|'|`)}
        ctext::addHighlightClassForRegexp $txt sharp #975db4 {^(#+?)\s(.*?)$}
        ctext::addHighlightClassForRegexp $txt quotedtext #a9b36c {^(\s*?)(>+).+?$}
        ctext::addHighlightClassForRegexp $txt italictext #dff74e {((_|\*)+?)(\w+?)((_|\*)+?)}
    }
    
    proc PL {txt} {
        ctext::addHighlightClassForRegexp $txt qoute #b84a0c {("|'|`).*?("|'|`)}
        ctext::addHighlightClassForRegexp $txt flags orange {\s-[a-zA-Z]+}
        ctext::addHighlightClass $txt stackControl #19a2a6 {sub my end class new if else elsif for foreach while case when use ne eq print exit chdir rand die lt gt le ge say unless return chomp package push exec grep eval warn scalar next continue close}
        ctext::addHighlightClassForRegexp $txt vars #4471ca {(\$|\*|\&)[\.a-zA-Z0-9\_\-\[\]]+}
        ctext::addHighlightClassForSpecialChars $txt brackets green {[]{}()}
        # ctext::addHighlightClassForSpecialChars $txt dog #0082ff {@}
        ctext::addHighlightClassForRegexp $txt dog #0082ff {(@)[\.a-zA-Z0-9\_\-\[\]]+}
        ctext::addHighlightClassForRegexp $txt paths lightblue {\.[a-zA-Z0-9\_\-]+}
        ctext::addHighlightClassForRegexp $txt comments #666666 {(#|//)[^\n\r]*}    
        ctext::addHighlightClassForRegexp $txt namespaces #0093ff {->|\+\+|::}
    }
    proc INI {txt} {
        ctext::addHighlightClassForRegexp $txt qoute #b84a0c {("|'|`).*?("|'|`)}
        ctext::addHighlightClassForRegexp $txt flags orange {\s-[a-zA-Z]+}
        ctext::addHighlightClassForRegexp $txt stackControl #4471ca {^(\s*?)\[[\.a-zA-Z0-9\_\-\[\]]+\]}
        ctext::addHighlightClassForSpecialChars $txt brackets green {[]{}()}
        ctext::addHighlightClassForRegexp $txt dog #0082ff {(@)[\.a-zA-Z0-9\_\-\[\]]+}
        ctext::addHighlightClassForRegexp $txt comments lightblue {(#|//)[^\n\r]*}
        ctext::addHighlightClassForRegexp $txt keyword #19a2a6 {^(\s*?)[a-zA-Z0-9\_\-]+(\s*?=)}
        ctext::addHighlightClassForSpecialChars $txt equal #0082ff {=}
    }
}
