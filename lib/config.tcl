######################################################
#                ProjMan 2
#        Distributed under GNU Public License
# Author: Sergey Kalinin svk@nuk-svk.ru
# Copyright (c) "", 2022, https://nuk-svk.ru
######################################################
# The config file procedures
# create
# copy
# save
######################################################

namespace eval Config {} {
    variable cfgINISections
    variable cfgVariables
    variable cfgOnConfigSaveCb
}

if [info exists env(LANG)] {
    set locale $env(LANG)
} else {
    set locale "en"
}

set ::configDefault "\[General\]
cfgModifyDate=''
searchCommand=/usr/bin/grep
searchCommandOptions=-r -n -H
gitCommand=/usr/bin/git
gitkCommand=/usr/bin/gitk
# must return a mime type of file
fileTypeCommand=/usr/bin/file
fileTypeCommandOptions=-i -b
\[GUI\]
locale=$locale
theme=dark
toolBarShow=true
menuShow=true
statusBarShow=true
filesPanelShow=true
filesPanelPlace=left
geometry=1024x768
guiFont={Droid Sans Mono} 9
guiFontBold={Droid Sans Mono} 9 bold
guiFG=#cccccc
\[Editor\]
autoFormat=true
font=Monospace 10
fontBold=Monospace 10
backGround=#333333
foreground=#cccccc
selectbg=#10a410a410a4
selectLightBg=grey
nbNormal=#000000
nbModify=#ffff5d705d70
lineNumberFG=#444444
lineNumberBG=#151515
selectBorder=0
# must be: none, word or char
editorWrap=word
lineNumberShow=true
tabSize=4
procedureHelper=false
variableHelper=true
multilineComments=true
\[UserSession\]
opened=
editedFiles=
"
proc Config::create {dir} {
    set cfgFile [open [file join $dir projman.ini]  "w+"]
    puts $cfgFile $::configDefault
    close $cfgFile
}

proc Config::read {dir} {
    set cfgFile [ini::open [file join $dir projman.ini] "r"]
    foreach section [ini::sections $cfgFile] {
        foreach key [ini::keys $cfgFile $section] {
            lappend ::cfgINISections($section)  $key
            set ::cfgVariables($key)  [ini::value $cfgFile $section $key]
        }
    }
    ini::close $cfgFile
}

proc Config::registerCallbackOnConfigSave {callback {link ""}} {
    variable cfgOnConfigSaveCb
    registerCallback cfgOnConfigSaveCb $callback $link
    debug_puts "registerCallbackOnConfigSave: $callback"
}

proc Config::write {dir} {
    variable cfgOnConfigSaveCb
    global activeProject editors
    set cfgFile [ini::open [file join $dir projman.ini] "w"]
    foreach section  [array names ::cfgINISections] {
        foreach key $::cfgINISections($section) {
            ini::set $cfgFile $section $key $::cfgVariables($key)
        }
    }
    set systemTime [clock seconds]
    # Set a config modify time (i don't know why =))'
    ini::set $cfgFile "General" cfgModifyDate [clock format $systemTime -format "%D %H:%M:%S"]
    ini::set $cfgFile "UserSession" editedFiles ""

    # Save an top level window geometry into config
    fireCallbacks cfgOnConfigSaveCb $cfgFile
    if {[info exists activeProject] !=0 && $activeProject ne ""} {
        ini::set $cfgFile "UserSession" opened $activeProject
        # Добавим пути к открытым в редакторе файлам в переменную
        if [info exists editors] {
            foreach i [dict keys $editors] {
                # debug_puts [dict get $editors $i]
                if [dict exists $editors $i fileFullPath] {
                    lappend edited [dict get $editors $i fileFullPath]
                }
            }
            if [info exists edited] {
                ini::set $cfgFile "UserSession" editedFiles $edited
            }
        }
    } else {
        ini::set $cfgFile "UserSession" opened ""
        ini::set $cfgFile "UserSession" editedFiles ""
    }
    # debug_puts $editors

    ini::commit $cfgFile
    ini::close $cfgFile
}
