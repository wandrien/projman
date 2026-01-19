#!/bin/sh
# Tcl ignores the next line -*- tcl -*- \
exec wish "$0" -- "$@"

######################################################
#        Tcl/Tk Project manager 2.0
#        Distributed under GNU Public License
# :Author: Sergey Kalinin svk@nuk-svk.ru
# :Home page: https://nuk-svk.ru
######################################################
# :Version: 2.0.0
# :Release: alpha16
# :Build: 22082024151054
######################################################

################################################################################

# This file contains an embedded copy of getOpt.tcl from:
# https://github.com/tcler/getopt.tcl/blob/a604ae7a01d275c9592d659faece31a067812635/getOpt-3.0/getOpt.tcl
# Command-line options must be parsed during initial startup,
# before module search paths are configured,
# therefore we include the code locally.
# This is not a verbatim copy. Additional improvements have been made
# to the getUsage method.
# License follows below.

# Copyright (c) 2015, tcler.yin <yin-jianhong@163.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of getOpt.tcl nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

########################################################################
#
#  getOpt -- similar as getopt_long_only(3)
#
# (C) 2017 Jianhong Yin <yin-jianhong@163.com>
#
# $Revision: 1.0 $, $Date: 2017/02/24 10:57:22 $
########################################################################

namespace eval ::getOpt {
    namespace export getOptions getUsage
}

set ::getOpt::flag(NOTOPT)  1
set ::getOpt::flag(KNOWN)   2
set ::getOpt::flag(NEEDARG) 3
set ::getOpt::flag(UNKNOWN) 4
set ::getOpt::flag(END)     5
set ::getOpt::flag(AGAIN)   6

proc ::getOpt::getOptObj {optList optName} {
    foreach {optNameList optAttr} $optList {
        if {$optName in $optNameList} {
            return [list [lindex $optNameList 0] $optAttr]
        }
    }
    return ""
}

proc ::getOpt::argparse {optionList argvVar optVar optArgVar} {
    upvar $argvVar  argv
    upvar $optVar optName
    upvar $optArgVar optArg

    set result $::getOpt::flag(UNKNOWN)
    set optName ""
    set optArg ""

    if {[llength $argv] == 0} {
        return $::getOpt::flag(END)
    }

    set rarg [lindex $argv 0]
    if {$rarg in {-}} {
        set optArg $rarg
        set argv [lrange $argv 1 end]
        return $::getOpt::flag(NOTOPT)
    }
    if {$rarg in {--}} {
        set argv [lrange $argv 1 end]
        return $::getOpt::flag(END)
    }

    set argv [lrange $argv 1 end]
    switch -glob -- $rarg {
        "-*" -
        "--*" {
            set opttype long
            set optName [string range $rarg 1 end]
            if [string equal [string range $optName 0 0] "-"] {
                set optName [string range $rarg 2 end]
            } else {
                set opttype short
            }

            set idx [string first "=" $optName 1]
            if {$idx != -1} {
                set toptName [string range $optName 0 [expr $idx-1]]
                lassign [getOptObj $optionList $toptName] toptFind toptAttr
                if {$toptFind != ""} {
                    set _val [string range $optName [expr $idx+1] end]
                    set optName [string range $optName 0 [expr $idx-1]]
                }
            }

            lassign [getOptObj $optionList $optName] optFind optAttr
            if {$optFind != ""} {
                set optName $optFind
                set result $::getOpt::flag(KNOWN)
                set argtype n
                if [dict exists $optAttr arg] {
                    set argtype [dict get $optAttr arg]
                }
                switch -exact -- $argtype {
                    "o" {
                        if [info exists _val] {
                            set optArg $_val
                        }
                    }
                    "y" -
                    "m" {
                        if [info exists _val] {
                            set optArg $_val
                        } elseif {[llength $argv] != 0 &&
                            [lindex $argv 0] != "--"} {
                            set optArg [lindex $argv 0]
                            set argv [lrange $argv 1 end]
                        } else {
                            set result $::getOpt::flag(NEEDARG)
                        }
                    }
                }
            } elseif {![info exists _val] && $opttype in {short} && [string length $optName] > 1} {
                # expand short args
                set insertArgv [list]
                while {[string length $optName]!=0} {
                    set x [string range $optName 0 0]
                    set optName [string range $optName 1 end]

                    if {$x in {= - { } \\ \' \"}} break

                    lassign [getOptObj $optionList $x] _x optAttr
                    if {$_x == ""} {
                        lappend insertArgv  -$x
                        continue
                    }

                    # get option type
                    set xtype n
                    if [dict exists $optAttr arg] {
                        set xtype [dict get $optAttr arg]
                    }
                    if {[dict exists $optionList $x link]} {
                        set x_link [dict get $optionList $x link]
                        lassign [getOptObj $optionList $x_link] _x_link optAttr
                        if {$_x_link != ""} {
                            if [dict exists $optAttr arg] {
                                set xtype [dict get $optAttr arg]
                            }
                        } else {
                            lappend insertArgv  -$x
                            continue
                        }
                    }

                    switch -exact -- $xtype {
                        "n" { lappend insertArgv  -$x }
                        "o" {
                            lappend insertArgv  -$x=$optName
                            break
                        }
                        "y" -
                        "m" {
                            lappend insertArgv  -$x
                            continue
                        }
                    }
                }
                set argv [concat $insertArgv $argv]
                return $::getOpt::flag(AGAIN)
            } else {
                set result $::getOpt::flag(UNKNOWN)
            }
        }
        default {
            set optArg $rarg
            set result $::getOpt::flag(NOTOPT)
        }
    }

    return $result
}

proc ::getOpt::getOptions {optLists argv validOptionVar invalidOptionVar notOptionVar {forwardOptionVar ""}} {
    upvar $validOptionVar validOption
    upvar $invalidOptionVar invalidOption
    upvar $notOptionVar notOption
    upvar $forwardOptionVar forwardOption

    #clear out var
    array unset validOption *
    array unset invalidOption *
    set notOption [list]

    set optList "[concat {*}[dict values $optLists]]"
    set opt ""
    set optarg ""
    set nargv $argv
    #set argc [llength $nargv]

    while {1} {
        set prefix {-}
        set curarg [lindex $nargv 0]
        if [string equal [string range $curarg 0 1] "--"] {
            set prefix {--}
        }

        set ret [argparse $optList nargv opt optarg]

        if {$ret == $::getOpt::flag(AGAIN)} {
            continue
        } elseif {$ret == $::getOpt::flag(NOTOPT)} {
            if {[lindex $optarg 0] == {--}} {
                set notOption [concat $notOption $optarg]
            } else {
                lappend notOption $optarg
            }
        } elseif {$ret == $::getOpt::flag(KNOWN)} {
            #known options
            set argtype n
            lassign [getOptObj $optList $opt] _optFind optAttr
            if [dict exists $optAttr arg] {
                set argtype [dict get $optAttr arg]
            }

            set forward {}
            if [dict exists $optAttr forward] {
                set forward y
            }

            if {$forward == "y"} {
                switch -exact -- $argtype {
                    "n" {lappend forwardOption "$prefix$opt"}
                    default {lappend forwardOption "$prefix$opt=$optarg"}
                }
                continue
            }

            switch -exact -- $argtype {
                "m" {lappend validOption($opt) $optarg}
                "n" {incr validOption($opt) 1}
                default {set validOption($opt) $optarg}
            }
        } elseif {$ret == $::getOpt::flag(NEEDARG)} {
            set invalidOption($opt) "option -$opt need argument"
        } elseif {$ret == $::getOpt::flag(UNKNOWN)} {
            #unknown options
            set invalidOption($opt) "unknown options"
        } elseif {$ret == $::getOpt::flag(END)} {
            #end of nargv or get --
            set notOption [concat $notOption $nargv]
            break
        }
    }

    return 0
}

proc ::getOpt::genOptdesc {optNameList} {
    # print options as GNU style:
    # -o, --long-option    <abstract>
    set shortOpt {}
    set longOpt {}

    foreach k $optNameList {
        if {[string length $k] == 1} {
            lappend shortOpt -$k
        } else {
            lappend longOpt --$k
        }
    }
    set optdesc [join "$shortOpt $longOpt" ", "]
}

proc ::getOpt::getUsage {optLists {out "stdout"}} {

    foreach {group optDict} $optLists {

        #ignore hide options
        foreach key [dict keys $optDict] {
            if [dict exists $optDict $key hide] {
                dict unset optDict $key
            }
        }

        puts $out "$group"

        #generate usage list
        foreach opt [dict keys $optDict] {
            set pad 26
            set argdesc ""
            set optdesc [genOptdesc $opt]

            set argtype n
            if [dict exists $optDict $opt arg] {
                set argtype [dict get $optDict $opt arg]
            }
            switch -exact $argtype {
                "o" {set argdesc {[arg]}; set flag(o) yes}
                "y" {set argdesc {<arg>}; set flag(y) yes}
                "m" {set argdesc {{arg}}; set flag(m) yes}
            }

            set opthelp {nil #no help found for this options}
            if [dict exists $optDict $opt help] {
                set opthelp [dict get $optDict $opt help]
            }

            set opt_length [string length "$optdesc $argdesc"]
            set help_length [string length "$opthelp"]

            if {$opt_length > $pad-4 && $help_length > 8} {
                puts $out [format "    %-${pad}s\n %${pad}s    %s" "$optdesc $argdesc" {} $opthelp]
            } else {
                puts $out [format "    %-${pad}s %s" "$optdesc $argdesc" $opthelp]
            }
        }
    }

    unset optDict

    puts $out "\nNotes:"
    if [info exist flag] {
        puts $out {  * Notation used in the usage synopsis:}
        if [info exist flag(o)] {
            puts $out {      [arg] Optional. To provide a value, use --opt=arg}
            puts $out {            (the '--opt arg' form is not accepted for optional values).}
        }
        if [info exist flag(y)] {
            puts $out {      <arg> Required, single value. If the same option is given}
            puts $out {            multiple times (e.g., -f a -f b), only the last value (b) is kept.}
        }
        if [info exist flag(m)] {
            puts $out {      {arg} Required, repeatable. Repeated uses collect all values into}
            puts $out {            a list (e.g., -f a -f b yields ['a', 'b']).}
        }
        puts $out {}
        puts $out {  * For required arguments, '--opt arg' and '--opt=arg' are equivalent.}
        puts $out {}
    }
    puts $out {  * A short option like '-opt' is interpreted as:}
    puts $out {      * '--opt' if a long option named 'opt' exists.}
    puts $out {      * Otherwise, it is split into individual short options: '-o -p -t'.}
    puts $out {      * If one of those short options (e.g., '-p') requires an argument,}
    puts $out {        the remainder is treated as its value: '-opt' becomes '-o -p=t'.}
}

# END OF getOpt.tcl

################################################################################

# Domain-independend utility functions

proc getvar {var {default_value ""}} {
    upvar $var v
    if {[info exist v]} {
        return $v
    }
    return $default_value
}

proc set_default {array_name key value_script} {
    upvar 1 $array_name arr
    if {![info exists arr($key)]} {
        set arr($key) [uplevel 1 $value_script]
    }
}

proc print_array {array_name print_func prefix} {
    upvar $array_name arr
    foreach key [lsort [array names arr]] {
        {*}$print_func "$prefix$key = $arr($key)"
    }
}

# Autoconf-style variables and path names
# Default autoconf setup:
# PACKAGE_NAME    'package' value set by AC_INIT
# PACKAGE_TARNAME 'tarname' value set by AC_INIT
# The package tarname differs from package:
# the latter designates the full package name (e.g., ‘GNU Autoconf’),
# while the former is meant for distribution tar ball names (e.g., ‘autoconf’).
# PREFIX         install architecture-independent files in PREFIX [/usr/local]
# EPREFIX        install architecture-dependent files in EPREFIX [PREFIX]
# BINDIR         user executables [EPREFIX/bin]
# SBINDIR        system admin executables [EPREFIX/sbin]
# LIBEXECDIR     program executables [EPREFIX/libexec]
# SYSCONFDIR     read-only single-machine data [PREFIX/etc]
# SHAREDSTATEDIR modifiable architecture-independent data [PREFIX/com]
# LOCALSTATEDIR  modifiable single-machine data [PREFIX/var]
# RUNSTATEDIR    modifiable per-process data [LOCALSTATEDIR/run]
# LIBDIR         object code libraries [EPREFIX/lib]
# INCLUDEDIR     C header files [PREFIX/include]
# DATAROOTDIR    read-only arch.-independent data root [PREFIX/share]
# DATADIR        read-only architecture-independent data [DATAROOTDIR]
# INFODIR        info documentation [DATAROOTDIR/info]
# LOCALEDIR      locale-dependent data [DATAROOTDIR/locale]
# MANDIR         man documentation [DATAROOTDIR/man]
# DOCDIR         documentation root [DATAROOTDIR/doc/PACKAGE_TARNAME]
# HTMLDIR        html documentation [DOCDIR]
# DVIDIR         dvi documentation [DOCDIR]
# PDFDIR         pdf documentation [DOCDIR]
# PSDIR          ps documentation [DOCDIR]
#
# Autoconf sets DATADIR == DATAROOTDIR by default, which is not quite optimal.
# DATADIR is for package-specific files.
# So we set it to DATAROOTDIR/PACKAGE_TARNAME by default.
# We follow the GNU defaults otherwise.

# init_autoconf_paths --
# Initializes autoconf-style paths missing from setup_var.
# The caller should provide PACKAGE_NAME or PACKAGE_TARNAME.
# Other keys, if absent, are initialized to default values.
proc setup_autoconf_paths {setup_var} {
    upvar 1 $setup_var setup
    if {![info exists setup(PACKAGE_NAME)] && ![info exists setup(PACKAGE_TARNAME)]} {
        error "Either PACKAGE_NAME or PACKAGE_TARNAME must be set"
    }
    set_default setup PACKAGE_TARNAME {lindex $setup(PACKAGE_NAME)}
    set_default setup PREFIX         {lindex "/usr/local"}
    set_default setup EPREFIX        {lindex $setup(PREFIX)}
    set_default setup BINDIR         {file join $setup(EPREFIX) "bin"}
    set_default setup SBINDIR        {file join $setup(EPREFIX) "sbin"}
    set_default setup LIBEXECDIR     {file join $setup(EPREFIX) "libexec"}
    set_default setup SYSCONFDIR     {file join $setup(PREFIX) "etc"}
    set_default setup SHAREDSTATEDIR {file join $setup(PREFIX) "com"}
    set_default setup LOCALSTATEDIR  {file join $setup(PREFIX) "var"}
    set_default setup RUNSTATEDIR    {file join $setup(LOCALSTATEDIR) "run"}
    set_default setup LIBDIR         {file join $setup(EPREFIX) "lib"}
    set_default setup INCLUDEDIR     {file join $setup(PREFIX) "include"}
    set_default setup DATAROOTDIR    {file join $setup(PREFIX) "share"}
    set_default setup DATADIR        {file join $setup(DATAROOTDIR) $setup(PACKAGE_TARNAME)}
    set_default setup INFODIR        {file join $setup(DATAROOTDIR) "info"}
    set_default setup LOCALEDIR      {file join $setup(DATAROOTDIR) "locale"}
    set_default setup MANDIR         {file join $setup(DATAROOTDIR) "man"}
    set_default setup DOCDIR         {file join $setup(DATAROOTDIR) "doc" $setup(PACKAGE_TARNAME)}
    set_default setup HTMLDIR        {lindex $setup(DOCDIR)}
    set_default setup DVIDIR         {lindex $setup(DOCDIR)}
    set_default setup PDFDIR         {lindex $setup(DOCDIR)}
    set_default setup PSDIR          {lindex $setup(DOCDIR)}
}

proc setup_xdg_base_dirs {setup_var env_var} {
    upvar 1 $setup_var setup
    upvar 1 $env_var env
    global tcl_platform

    if {![info exists env(HOME)]} {
        error "env(HOME) is not set"
    }

    if {$env(HOME) eq ""} {
        error "env(HOME) is empty"
    }

    set HOME $env(HOME)

    set defaults {
        {XDG_CONFIG_HOME {[file join $HOME .config]}}
        {XDG_CACHE_HOME  {[file join $HOME .cache]}}
        {XDG_DATA_HOME   {[file join $HOME .local share]}}
        {XDG_STATE_HOME  {[file join $HOME .local state]}}
    }

    if {$tcl_platform(platform) eq "windows"} {
        lappend defaults \
            {XDG_DATA_DIRS   {}} \
            {XDG_CONFIG_DIRS {}}
    } else {
        lappend defaults \
            {XDG_DATA_DIRS   "/usr/local/share/:/usr/share/"} \
            {XDG_CONFIG_DIRS "/etc/xdg"}
    }

    foreach entry $defaults {
        set key [lindex $entry 0]
        if {[info exists env($key)] && ($env($key) ne "")} {
            set setup($key) $env($key)
        } else {
            set setup($key) [subst [lindex $entry 1]]
        }
    }
}

proc get_program_name {} {
    return [file tail [info script]]
}

set debugChannelId ""

proc debug_log_enabled {} {
    global debugChannelId
    return [expr {$debugChannelId ne ""}]
}

# debug_puts ?-nonewline? string
proc debug_puts {args} {
    global debugChannelId
    if {$debugChannelId eq ""} return

    set nonewline 0
    set string ""
    set argc [llength $args]

    switch -- $argc {
        0 {
            error {wrong nr args: should be "debug_puts ?-nonewline? string"}
        }

        1 {
            set string [lindex $args 0]
        }

        2 {
            set arg1 [lindex $args 0]
            set arg2 [lindex $args 1]
            if {$arg1 eq "-nonewline"} {
                set nonewline 1
                set string $arg2
            } else {
                error "bad option \"$arg1\": must be -nonewline"
            }
        }

        default {
            error {wrong nr args: should be "debug_puts ?-nonewline? string"}
        }
    }

    if {$nonewline} {
        puts -nonewline $debugChannelId $string
    } else {
        puts $debugChannelId $string
    }
}

proc regexp_quote {str} {
    regsub -all {[][{}()*+?.\\^$|]} $str {\\&} result
    return $result
}

proc extract_fields_from_comments {targetArrayName channelId fieldDesc} {
    upvar $targetArrayName targetArray
    array set extractedFields {}
    array set fields $fieldDesc

    set quoted_keys [lmap x [array names fields] {regexp_quote $x}]
    set r "^# :([join $quoted_keys {|}]):\\s+(.*)"

    while {[gets $channelId line] >=0} {
        if [regexp -- $r $line match v1 v2] {
            set key $fields($v1)
            set extractedFields($key) $v2
            set targetArray($key) $v2
        }
        if {[array size extractedFields] == [array size fields]}  {
            break
        }
    }

    if {[array size extractedFields] == [array size fields]}  {
        return
    }

    set missing [list]
    foreach key [array names fields] {
        if {![info exists extractedFields($fields($key))]} {
            lappend missing $key
        }
    }
    throw {PARSE MISSING_FIELDS} \
        "Not all required fields found. Missing: [join $missing {, }]"
}

proc registerCallback {cbListRef callback {link ""}} {
    upvar $cbListRef cbList

    if {[info commands $callback] eq ""} {
        error "Procedure '$callback_proc' doesnt exists"
    }

    lappend cbList [list $callback $link]
}

proc fireCallbacks {cbListRef args} {
    upvar $cbListRef cbList

    foreach item $cbList {
        set callback [lindex $item 0]
        set link [lindex $item 1]
        if {[info commands $callback] ne ""} {
            #debug_puts "fireCallbacks: $callback"
            $callback $link {*}$args
        }
    }
}

################################################################################

# Extract version etc from the source code
# Note: Ignoring possible errors in open and extract_fields_from_comments is OK,
#       rely on default behavior for terminating the program.
set f [open [info script] "RDONLY"]
extract_fields_from_comments projman $f {
    Version Version
    Release Release
    Build Build
    Author Author
    "Home page" Homepage
}
close $f

set projman(Help) "projman
Version: $projman(Version)
Release: $projman(Release)
Build: $projman(Build)
Home page: $projman(Homepage)

ProjMan (aka \"Tcl/Tk Project Manager\") is a text editor for programming
in TCL/Tk and other languages.
It includes a file manager, a source editor with syntax highlighting and code
navigation, a context-sensitive help system, Git support, and much more."

package require cmdline
package require msgcat
package require inifile
package require ctext
package require base64
package require fileutil
package require Thread
package require fileutil::magic::filetype

################################################################################

# Parse the command line

set option_list {
    "\nOptions:" {
        log-file {arg m help "Log what we're doing to the specified file. Use 'stdout' or 'stderr' for standard streams, empty to disable."}
        portable {help "Run in portable mode. All program files are located in the main script directory, not in accordance with the FHS."}
        print-setup {help "Debug: print the contents of the setup array and exit"}
        {help h ?} {help "Print this message"}
    }
}

array set options {}
array set invalid_options {}
set paths_to_process {}
::getOpt::getOptions $option_list $::argv options invalid_options paths_to_process

if {[array size invalid_options] > 0} {
    set wrong_options [join [lsort [array names invalid_options]] ", "]
    set program_name [get_program_name]
    if {[array size invalid_options] ==1} {
        puts stderr "$program_name: unrecognized option: $wrong_options"
    } else {
        puts stderr "$program_name: unrecognized options: $wrong_options"
    }
    puts stderr "Try '$program_name --help' for more information."
    exit 1
}

if {[getvar options(help) 0]} {
    puts $projman(Help)
    ::getOpt::getUsage $option_list
    exit 0
}

switch -- [getvar options(log-file)] {
    "" {
        set debugChannelId ""
    }
    stdout -
    stderr {
        set debugChannelId $options(log-file)
    }
    default {
        if {[catch {open $options(log-file) "w"} debugChannelId errorInfo]} {
            puts stderr $debugChannelId
            exit 1
        }
        fconfigure $debugChannelId -buffering line
    }
}

################################################################################

set setup(PACKAGE_NAME) "projman"
set setup(PACKAGE_TARNAME) "projman"
set setup(portable) 0
# Anchor for setting ("sed"ding) values at the package build time:
# _INSTALLATION_SETUP_

# The .tcl extension is present only when the file is run from
# the source code directory. When building the distribution packages,
# the file is renamed to remove the extension.
# Therefore, if the file has the extension, enable portable mode.
if {[file extension [info script]] eq ".tcl"} {
    set setup(portable) 1
}
# Force the portable mode on Windows, since Windows doesn't follow FHS.
if {$tcl_platform(platform) eq "windows"} {
    set setup(portable) 1
}
# The portable mode can also be enabled by the command line.
if {[getvar options(portable) 0]} {
    set setup(portable) 1
}

setup_autoconf_paths setup
setup_xdg_base_dirs setup env

if {[getvar options(print-setup) 0]} {
    print_array setup puts ""
    exit 0
}

################################################################################

# Apply either portable or FHS-compliant mode
if {$setup(portable)} {
    set dir(root) [file dirname [info script]]
} else {
    set dir(root) $setup(DATADIR)
}

# Setup paths to the application files
set dir(doc) [file join $dir(root) doc]
set dir(lib) [file join $dir(root) lib]
set dir(theme) [file join $dir(root) theme]

set dir(cfg) [file join $setup(XDG_CONFIG_HOME) projman]
if {[file exists $dir(cfg)] == 0} {
    file mkdir $dir(cfg)
}

if {[debug_log_enabled]} {
    debug_puts "Contents of the projman array:"
    print_array projman debug_puts "  "

    debug_puts "Contents of the setup array:"
    print_array setup debug_puts "  "

    debug_puts "Contents of the dirs array:"
    print_array dir debug_puts "  "
}

if {[llength $paths_to_process] > 0} {
    debug_puts "Paths from command line:"
    foreach arg $paths_to_process {
        debug_puts "  $arg"
    }
}

source [file join $dir(lib) config.tcl]

foreach modFile [lsort [glob -nocomplain [file join $dir(lib) *.tcl]]] {
    if {[file tail $modFile] ne "gui.tcl" && [file tail $modFile] ne "config.tcl"} {
        source $modFile
        debug_puts "Loading module $modFile"
    }
}

# TTK Theme loading
foreach modFile [lsort [glob -nocomplain [file join $dir(theme) *]]] {
    if [file isdirectory $modFile] {
        source $modFile/[file tail $modFile].tcl
        debug_puts "Loading theme $modFile.tcl"
    } elseif {[file extension $modFile] eq ".tcl"} {
        source $modFile
        debug_puts "Loading theme $modFile"
    }
}


# загружаем пользовательский конфиг, если он отсутствует, то копируем дефолтный
if {[file exists [file join $dir(cfg) projman.ini]] ==0} {
    Config::create $dir(cfg)
}
Config::read $dir(cfg)

::msgcat::mclocale $cfgVariables(locale)

if [::msgcat::mcload [file join $dir(lib) msgs]] {
    debug_puts "Load locale messages... OK"
}
debug_puts "Setting the locale... [::msgcat::mclocale]"

source [file join $dir(lib) gui.tcl]

# Open the paths from command line, if any
if {[llength $paths_to_process] > 0} {
    foreach path $paths_to_process {
        # Приводим путь к полному виду
        if {[file pathtype $path] ne "absolute"} {
            set path [file normalize $path]
        }
        if [file isdirectory $path] {
            # set activeProject $path
            SetActiveProject $path
            .frmStatus.lblGitLogo configure -image git_logo_20x20
            .frmStatus.lblGit configure -text "[::msgcat::mc "Branch"]: [Git::Branches current]"
            FileOper::ReadFolder $path
            ReadFilesFromDirectory $path $path
        } elseif [file exists $path] {
            # ResetModifiedFlag [FileOper::Edit $path] 
            FileOper::Edit $path
        }
    }
# Restore files and directories from the previos session otherwise
} else {
    if {$cfgVariables(opened) ne ""} {
        # debug_puts "<$cfgVariables(opened)"
        SetActiveProject $cfgVariables(opened)
        .frmStatus.lblGitLogo configure -image git_logo_20x20
        .frmStatus.lblGit configure -text "[::msgcat::mc "Branch"]: [Git::Branches current]"
        FileOper::ReadFolder $cfgVariables(opened)
        ReadFilesFromDirectory $cfgVariables(opened) $cfgVariables(opened)
        if {$cfgVariables(editedFiles) ne ""} {
            foreach f [split $cfgVariables(editedFiles) " "] {
                # debug_puts $f
                FileOper::Edit $f
            }
        }
    }
}
