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
    global gitCommand lastCommitTimeStampSec projectName
    set cmd exec
    set i 0
    lappend cmd "$gitCommand"
    lappend cmd "log"
    lappend cmd "--abbrev-commit"
    # Проверяем была ли запись для данного проекта если была то к времени последнего коммита прибавляем 1 сек.
    # и получаем журнал после этой даты
    if [info exists lastCommitTimeStampSec] {
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
        puts "\nRepository '$projectName' do not have any changes\n"
        exit
    }
}

proc StoreProjectInfo {projectName projectVersion projectRelease timeStamp} {
    global dir
    set cfgFile [open [file join $dir(cfg) $projectName.conf]  "w+"]
    puts $cfgFile "# set projectVersion \"$projectVersion\""
    puts $cfgFile "# set projectRelease \"$projectRelease\""
    puts $cfgFile "set lastCommitTimeStamp \"$timeStamp\""
    puts $cfgFile "set lastCommitTimeStampSec [clock scan $timeStamp]"
    close $cfgFile   
}


proc GenerateChangelogDEB {} {
    global projectName projectVersion projectRelease
    # puts "GenerateChangelogDEB"
    set lastCommitTimeStamp ""
    set commiter ""
    set commitText ""
    # ReadGitLog
    set lst [lsort -integer -index 0 [ReadGitLog]]
    # puts $lst
    # exit
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
            puts "$projectName ($projectVersion-$projectRelease) stable; urgency=medium\n"
            set commiter [lindex $record 2]
            StoreProjectInfo $projectName $projectVersion $projectRelease $timeStamp
         	  # puts "\n \[ [string trim $commiter] \]"
        }
        # puts ">> $commiter"
        if {$commiter ne [lindex $record 2]} {
            puts "\n -- [string trim $commiter] <$email>  $timeStamp"
            puts "\n$projectName ($projectVersion-$projectRelease) stable; urgency=medium\n"
            set commiter [lindex $record 2]
            # puts "\n \[ [string trim $commiter] \]"
        }
        
        set commitTex [lindex $record 4]
        puts "  * $commitTex"

    }
    puts "\n -- [string trim $commiter] <$email>  $timeStamp"
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
    puts "\tchangelog-gen.tcl {DEB RPM TXT}\n"
    puts "Where{DEB RPM TXT} - changelog format for same packages. The list can be either complete or from any number of elements.\nDefault is a TXT"    
}

if [info exists env(PROJECT_NAME)] {
    set projectName $env(PROJECT_NAME)
    # puts $projectName
} else {
    puts "You mast set PROJECT_NAME variable \n"
    exit
}
if [info exists env(PROJECT_VERSION)] {
    set projectVersion $env(PROJECT_VERSION)
    # puts $projectVersion
} else {
    puts "You mast set PROJECT_VERSION variable \n"
    exit
}
if [info exists env(PROJECT_RELEASE)] {
    set projectRelease $env(PROJECT_RELEASE)
    # puts $projectRelease
} else {
    puts "You mast set PROJECT_RELEASE variable \n"
    exit
}

if [file exists [file join $dir(cfg) $projectName.conf]] {
    source [file join $dir(cfg) $projectName.conf]
}

if { $::argc > 1 } {
    foreach arg $::argv {
        switch -glob -nocase $arg {
            DEB {GenerateChangelogDEB}
            RPM {GenerateChangelogRPM}
            TXT {GenerateChangelogTXT}
            *help {ShowHelp}
        }
    }
} else {
    ShowHelp
}
