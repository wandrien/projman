#!/bin/sh
# Tcl ignores the next line -*- tcl -*- \
exec wish "$0" -- "$@"

######################################################
#        Tcl/Tk Project manager 2.0
#        Distributed under GNU Public License
# Author: Sergey Kalinin svk@nuk-svk.ru
# Home page: https://nuk-svk.ru
######################################################
# Version: 2.0.0
# Release: alpha
# Build: 24112022115832
######################################################

# определим текущую версию, релиз и т.д.
set f [open [info script] "RDONLY"]
while {[gets $f line] >=0} {
    if [regexp -nocase -all -- {version:\s+([0-9]+?.[0-9]+?.[0-9]+?)} $line match v1] {
        set projman(Version) $v1
    }
    if [regexp -nocase -all -- {release:\s+([a-z0-9]+?)} $line match v1] {
        set projman(Release) $v1
    }
    if [regexp -nocase -all -- {build:\s+([a-z0-9]+?)} $line match v1] {
        set projman(Build) $v1
    }
    if [regexp -nocase -all -- {author:\s+(.+?)} $line match v1] {
        set projman(Author) $v1
    }
    if [regexp -nocase -all -- {home page:\s+(.+?)} $line match v1] {
        set projman(Homepage) $v1
    }
}
close $f

if { $::argc > 0 } {
    foreach arg $::argv {
        lappend opened $arg
    }
    puts $opened
}

package require msgcat
package require inifile
package require ctext
package require base64
package require fileutil
package require Thread
package require fileutil::magic::filetype

# Устанавливаем текущий каталог
set dir(root) [pwd]
set dir(doc) [file join $dir(root) doc]

# Устанавливаем рабочий каталог, если его нет то создаём.
# Согласно спецификации XDG проверяем наличие переменных и каталогов
if [info exists env(XDG_CONFIG_HOME)] {
    set dir(cfg) [file join $env(XDG_CONFIG_HOME) projman]
} elseif [file exists [file join $env(HOME) .config]] {
    set dir(cfg) [file join $env(HOME) .config projman]
} else {
    set dir(cfg) [file join $env(HOME) .projman]
}

if {[file exists $dir(cfg)] == 0} {
    file mkdir $dir(cfg)
}

# puts "Config dir is $dir(cfg)"

# каталог с модулями
set dir(lib) "[file join $dir(root) lib]"

source [file join $dir(lib) config.tcl]

foreach modFile [lsort [glob -nocomplain [file join $dir(lib) *.tcl]]] {
    if {[file tail $modFile] ne "gui.tcl" && [file tail $modFile] ne "config.tcl"} {
        source $modFile
        puts "Loading module $modFile"
    }
}

# TTK Theme loading
set dir(theme) "[file join $dir(root) theme]"
foreach modFile [lsort [glob -nocomplain [file join $dir(theme) *]]] {
    if [file isdirectory $modFile] {
        source $modFile/[file tail $modFile].tcl
        puts "Loading theme $modFile.tcl"
    } elseif {[file extension $modFile] eq ".tcl"} {
        source $modFile
        puts "Loading theme $modFile"
    }
}


# загружаем пользовательский конфиг, если он отсутствует, то копируем дефолтный
if {[file exists [file join $dir(cfg) projman.ini]] ==0} {
    Config::create $dir(cfg)
}
Config::read $dir(cfg)

::msgcat::mclocale $cfgVariables(locale)

if [::msgcat::mcload [file join $dir(lib) msgs]] {
    puts "Load locale messages... OK"
}
puts "Setting the locale... [::msgcat::mclocale]"

source [file join $dir(lib) gui.tcl]

# Open the PATH if command line argument has been setting
if [info exists opened] {
    # puts ">$opened"
    foreach path $opened {
        if {[file pathtype $path] ne "absolute"} {
            puts "\n\t[::msgcat::mc "Specify the absolute path to the directory or file"]: $path\n"
            exit
        }
        if [file isdirectory $path] {
            set activeProject $path
            .frmStatus.lblGitLogo configure -image git_logo_20x20
            .frmStatus.lblGit configure -text "[::msgcat::mc "Branch"]: [Git::Branches current]"
            FileOper::ReadFolder $path
            ReadFilesFromDirectory $path $path
        } elseif [file exists $path] {
            ResetModifiedFlag [FileOper::Edit $path]
        }
    }
} else {
    if {$cfgVariables(opened) ne ""} {
        # puts "<$cfgVariables(opened)"
        set activeProject $cfgVariables(opened)
        .frmStatus.lblGitLogo configure -image git_logo_20x20
        .frmStatus.lblGit configure -text "[::msgcat::mc "Branch"]: [Git::Branches current]"
        FileOper::ReadFolder $cfgVariables(opened)
        ReadFilesFromDirectory $cfgVariables(opened) $cfgVariables(opened)
        if {$cfgVariables(editedFiles) ne ""} {
            foreach f [split $cfgVariables(editedFiles) " "] {
                # puts $f
                FileOper::Edit $f
            }
        }
    }
}
