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
# Release: alpha16
# Build: 22082024151054
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

# Domain-independend utility functions

proc set_default {array_name key value_script} {
    upvar 1 $array_name arr
    if {![info exists arr($key)]} {
        set arr($key) [uplevel 1 $value_script]
    }
}

proc print_array {array_name print_func prefix} {
    upvar $array_name arr
    foreach key [lsort [array names arr]] {
        $print_func "$prefix$key = $arr($key)"
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

################################################################################

proc print_help {print_func} {
    upvar 1 cmdline_options cmdline_options
    upvar 1 projman projman
    $print_func $projman(Help)
    $print_func [::cmdline::usage $cmdline_options]
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

################################################################################

# Parse the command line

# TODO: Replace cmdline with a custom implementation.
# cmdline has the following limitations:
# * No support for GNU-style --long-options with double hyphen.
# * No support for options intended for multiple occurrences (--var v1=1 --var v2=2)
# * No way to disable the built-in handling of -help and -? options.
# Maybe this one fits: https://github.com/tcler/getopt.tcl

set cmdline_options {
    {log-file.arg "" "Log what we're doing to the specified file. Use 'stdout' or 'stderr' for standard streams, empty to disable."}
    {portable "Run in portable mode. All program files are located in the main script directory, not in accordance with the FHS."}
    {print-setup "Debug: print the contents of the setup array and exit"}
}

if {[catch {
    array set params [::cmdline::getoptions argv $cmdline_options]
} error]} {
    print_help puts
    exit 1
}

switch -- $params(log-file) {
    "" {
        set debugChannelId ""
    }
    stdout -
    stderr {
        set debugChannelId $params(log-file)
    }
    default {
        if {[catch {open $params(log-file) "w"} debugChannelId errorInfo]} {
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
if {$params(portable)} {
    set setup(portable) 1
}

setup_autoconf_paths setup
setup_xdg_base_dirs setup env

if {$params(print-setup)} {
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

debug_puts "Contents of the setup array:"
print_array setup debug_puts "  "

debug_puts "Contents of the dirs array:"
print_array dir debug_puts "  "

# Добавляем в список файлы (каталоги) из командной строки
# Note: After parsing options, ::argc may contain wrong value,
# since the options are removed from ::argv.
if {[llength $::argv] > 0} {
    debug_puts "Paths from command line:"
    foreach arg $::argv {
        lappend opened $arg
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

# Open the PATH if command line argument has been setting
if [info exists opened] {
    foreach path $opened {
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
