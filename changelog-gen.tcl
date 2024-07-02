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
    global gitCommand
    set cmd exec
    lappend cmd "$gitCommand"
    lappend cmd "log"
    lappend cmd "--abbrev-commit"
    lappend cmd "--all"
    lappend cmd "--pretty='%h, %ad, %an, %ae, %s, %b'"
    # puts $cmd
    catch $cmd pipe
    # puts $pipe
    set outBuffer ""
    foreach line [split $pipe "\n"] {
        # set line [string trim $line]
        set line [string trim [string trim $line] {'}] 
        if {[regexp -nocase -all -- {^[0-9a-z]+} $line match]} {
            if {$outBuffer ne ""} {
                # puts $outBuffer
                lappend res $outBuffer
            }
            set outBuffer $line
        } else {
            if {$line ne ""} {
                append outBuffer ". " $line
            }
        }
    }
    # puts $res
    return $res
}

proc GenerateChangelogDEB {} {
    puts "GenerateChangelogDEB"
    set lastCommitTimeStamp ""
    set commiter ""
    set commitText ""
    # ReadGitLog
    set lst [lsort -decreasing [ReadGitLog]]
    # puts [lindex $lst 0]
    # exit
    foreach line $lst {
        set record [split $line ","]
        # puts [lindex $record 1]
        if {$lastCommitTimeStamp eq ""} {
            set lastCommitTimeStamp [string trim [lindex $record 1]]
        }
        # set timeStamp set s [clock scan {Mon Jan 22 17:30:28 2018 +0300}] -format {%a %b %e %H:%M:%S %Y %z”}
        
        if {$commiter ne [lindex $record 2]} {
            puts "\n \[ [string trim $commiter] \]"
            set commiter [lindex $record 2]
        }
        
        set commitTex [lindex $record 4]
        puts "  * $commitTex"

    }
    puts $lastCommitTimeStamp
}

proc GenerateChangelogRPM {} {
    puts "GenerateChangelogRPM"
    
}

proc GenerateChangelogTXT {} {
    puts "GenerateChangelogTXT"
    
}
# puts [ReadGitLog]

proc ShowHelp {} {
    puts "\nChangelog generator from the Git commit history. For DEB and RPM packages"
    puts "Usage:\n"
    puts "\tchangelog-gen.tcl {DEB RPM TXT}\n"
    puts "Where{DEB RPM TXT} - changelog format for same packages. The list can be either complete or from any number of elements.\nDefault is a TXT"    
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
    GenerateChangelogTXT
}

