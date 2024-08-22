#!/bin/sh
# Tcl ignores the next line -*- tcl -*- \
exec tclsh "$0" -- "$@"

######################################################################
#                ProjMan 2
#        Distributed under GNU Public License
# Author: Sergey Kalinin svk@nuk-svk.ru
# Copyright (c) "SVK", 2024, https://nuk-svk.ru
#######################################################################
# Changelog generator from the Git commit history.
# For DEB and RPM packages
# usage a git command:
# 
#    git log --abbrev-commit --all --pretty='%h, %ad, %an, %ae, %s, %b'
#######################################################################

# puts $tcl_platform(platform)

# Устанавливаем рабочий каталог, если его нет то создаём.
# Согласно спецификации XDG проверяем наличие переменных и каталогов
if [info exists env(XDG_CONFIG_HOME)] {
    set dir(cfg) [file join $env(XDG_CONFIG_HOME) changelog-gen]
} elseif [file exists [file join $env(HOME) .config]] {
    set dir(cfg) [file join $env(HOME) .config changelog-gen]
} else {
    #set dir(cfg) [file join $env(HOME) .changelog-gen]
}

if {[file exists $dir(cfg)] == 0} {
    file mkdir $dir(cfg)
}

# Use whereis command for finding the git executable file.
# for unix-like operating systems
proc GetGitCommandUnix {} {
    global gitCommand
    set cmd "whereis -b git"
    catch "exec $cmd" result
    # puts $result
    if {$result ne ""} {
        set fields [split $result ":"]
        # puts $fields
        if {[lindex $fields 1] ne ""} {
            # puts [lindex $fields 1]
	        set gitCommand "[string trim [lindex $fields 1]]"
		} else {
            puts "GIT command not found"
            exit
        }
    }
}

# Setting the git-command for windows family OS
proc GetGitCommandWindows {} {
    global gitCommand
    set gitCommand "c:/git/bin/git.exe"
}

switch $tcl_platform(platform) {
    unix     {GetGitCommandUnix}
    windows  {GetGitCommandWindows}
}

proc ReadGitLog {} {
    global args gitCommand lastCommitTimeStampSec
    set cmd exec
    set i 0
    lappend cmd "$gitCommand"
    lappend cmd "log"
    lappend cmd "--abbrev-commit"
    # Проверяем была ли запись для данного проекта если была то к времени последнего коммита прибавляем 1 сек.
    # и получаем журнал после этой даты
    if {[info exists lastCommitTimeStampSec] && [info exists args(--last)]} {
        lappend cmd "--after='[clock format [clock add $lastCommitTimeStampSec 1 second] -format {%a, %e %b %Y %H:%M:%S %z}]'"
    }
    lappend cmd "--all"
    lappend cmd "--pretty='%h, %ad, %an, %ae, %s, %b'"
    # puts $cmd
    catch $cmd pipe
    # puts $pipe
    set outBuffer ""
    foreach line [split $pipe "\n"] {
        # puts $line
        # set line [string trim $line]
        set line [string trim [string trim $line] {'}] 
        if {[regexp -nocase -all -- {^[0-9a-z]+} $line match]} {
            set outBuffer $line
            if {$outBuffer ne ""} {
                lappend res [list $i $outBuffer]
                incr i
            }
            # puts $outBuffer
        } else {
            if {$line ne ""} {
                append outBuffer ". " $line
            }
        }
    }
    # puts $res
    if [info exists res] {
        return $res
    } else {
        puts "\nRepository '$args(--project-name)' do not have any changes\n"
        exit
    }
}

proc StoreProjectInfo {timeStamp} {
    global dir args
    set cfgFile [open [file join $dir(cfg) $args(--project-name).conf]  "w+"]
    puts $cfgFile "# set args(--project-version) \"$args(--project-version)\""
    puts $cfgFile "# set args(--project-release) \"$args(--project-release)\""
    puts $cfgFile "set lastCommitTimeStamp \"$timeStamp\""
    puts $cfgFile "set lastCommitTimeStampSec [clock scan $timeStamp]"
    close $cfgFile   
}


proc GenerateChangelogDEB {} {
    global args
    # puts "GenerateChangelogDEB"
    set lastCommitTimeStamp ""
    set commiter ""
    set commitText ""
    # ReadGitLog
    set lst [lsort -integer -index 0 [ReadGitLog]]
    # puts $lst
    # exit
    set outText ""
    foreach l $lst {
        set index [lindex $l 0]
        set line [lindex $l 1]
        # puts "$index - $line"
        set record [split $line ","]
        set timeStamp [string trim [lindex $record 1]]
        set email [string trim [lindex $record 3]]
        if {$lastCommitTimeStamp eq ""} {
            set lastCommitTimeStamp [string trim [lindex $record 1]]
        }
        set timeStamp [clock format [clock scan $timeStamp] -format {%a, %e %b %Y %H:%M:%S %z}]
        # puts "> $commiter"
        if {$index == 0} {
            puts "$args(--project-name) ($args(--project-version)-$args(--project-release)) stable; urgency=medium\n"
            append outText "$args(--project-name) ($args(--project-version)-$args(--project-release)) stable; urgency=medium\n\n"
            set commiter [lindex $record 2]
            StoreProjectInfo $timeStamp
         	  # puts "\n \[ [string trim $commiter] \]"
        }
        # puts ">> $commiter"
        if {$commiter ne [lindex $record 2]} {
            puts "\n -- [string trim $commiter] <$email>  $timeStamp"
            append outText "\n -- [string trim $commiter] <$email>  $timeStamp\n"
            puts "\n$args(--project-name) ($args(--project-version)-$args(--project-release)) stable; urgency=medium\n"
            append outText "\n$args(--project-name) ($args(--project-version)-$args(--project-release)) stable; urgency=medium\n\n"
            set commiter [lindex $record 2]
            # puts "\n \[ [string trim $commiter] \]"
        }
        
        set commitTex [lindex $record 4]
        puts "  * $commitTex"
        append outText "  * $commitTex\n"

    }
    puts "\n -- [string trim $commiter] <$email>  $timeStamp"
    append outText "\n -- [string trim $commiter] <$email>  $timeStamp\n"
    return $outText
}

proc GenerateChangelogRPM {} {
    puts "GenerateChangelogRPM"
    
}

proc GenerateChangelogTXT {} {
    puts "GenerateChangelogTXT"
    puts [ReadGitLog]
    
}
# puts [ReadGitLog]

proc ShowHelp {} {
    puts "\nChangelog generator from the Git commit history. For DEB and RPM packages"
    puts "Usage:\n"
    puts "\tchangelog-gen \[options\]\n"
    puts "Where options:"
    puts "\t--project-name - name of project (package) "
    puts "\t--project-version - package version"
    puts "\t--project-release - package release name (number)"
    puts "\t--deb - debian package format of changelog"
    puts "\t--rpm - rpm package format of changelog"
    puts "\t--txt - plain text changelog out"
    puts "\t--out-file - changelog file name"
    puts "\t--last - The timestamp since the last launch of this program for a given project"
}

set arglen [llength $argv]
set index 0
while {$index < $arglen} {
    set arg [lindex $argv $index]
    switch -exact $arg {
        --project-name {
            set args($arg) [lindex $argv [incr index]]
        }
        --project-version {
            set args($arg) [lindex $argv [incr index]]
        }
        --project-release {
            set args($arg) [lindex $argv [incr index]]
        }
        --deb {
            set args($arg) true
        }
        --rpm {
            set args($arg) true
        }
        --txt {
            set args($arg) true
        }
        --out-file {
            set args($arg) [lindex $argv [incr index]]
        }
        --last {
            set args($arg) true
        }
        --help {
            ShowHelp
            exit
        }
        default  {
            set filename [lindex $argv $index]
        }
    }
    incr index
}

if ![info exists args(--project-name)] {
    puts "You mast set --project-name option\n"
    exit
}
if ![info exists args(--project-version)] {
    puts "You mast set --project-version option\n"
    exit
}
if ![info exists args(--project-release)] {
    puts "You mast set --project-release option\n"
    exit
}

if [file exists [file join $dir(cfg) $args(--project-name).conf]] {
    source [file join $dir(cfg) $args(--project-name).conf]
}

foreach arg [array names args] {
    puts "$arg $args($arg)"
}

if [info exists args(--deb)] {
    set outText [GenerateChangelogDEB]
    if [info exists args(--out-file)] {
        if [file exists $args(--out-file)] {
            file copy -force $args(--out-file) "$args(--out-file).tmp"
            
            set origOutFile [open "$args(--out-file).tmp"  "r"]
            set origText [read $origOutFile]
            close $origOutFile

            set outFile [open $args(--out-file)  "w"]
            puts $outFile $outText
            puts $outFile $origText
            close $outFile
            
            if [info exists args(--last)] {
                set outFile [open $args(--out-file)  "r+"]
                puts $outFile $outText
                close $outFile
            } else {
                set outFile [open $args(--out-file)  "w+"]
                puts $outFile $outText
                close $outFile
            }
        } else {
            set outFile [open $args(--out-file)  "w+"]
            puts $outFile $outText
            close $outFile
        } 
    }
}
if [info exists args(--rpm)] {
    GenerateChangelogRPM
}
if [info exists args(--txt)] {
    GenerateChangelogTXT
}


