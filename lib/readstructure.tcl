######################################################
#                ProjMan 2
#        Distributed under GNU Public License
# Author: Sergey Kalinin svk@nuk-svk.ru
# Copyright (c) "", 2022, https://nuk-svk.ru
######################################################
# 
# Module for read files structure into directory
# 
######################################################
package require fileutil
package require Thread

# TCL procedure

proc GetVariablesFromFile {fileName} {
    global tree nbEditor editors lexers project
    set fileType [string toupper [string trimleft [file extension $fileName] "."]]
    set procList ""
    set varList ""
    set params ""
    set varsBegin false
    puts $fileName
    set f [open "$fileName" r]
    if {[dict exists $lexers $fileType] == 0} {return}
    while {[gets $f line] >=0 } {
        if {[dict exists $lexers $fileType varRegexpCommandMultiline] != 0 } {
            if {[eval [dict get $lexers $fileType varRegexpCommandMultiline]]} {
                if [info exists indent] {
                    set indentSize [string length $indent]
                } else {
                    set indentSize 0
                }
                set varsBegin true
                puts "====== $varsBegin $indentSize"
                continue
                # lappend varList [list $varName $varValue]
            }
        }
        if {$varsBegin eq "true"} {
            set l [GetVarFromLine $line $fileType]
            if {$line eq ""} {
               set varsBegin false
               puts "====== $varsBegin $indentSize [lindex $l 3]"
               continue
            }
            if {[lindex $l 3] ne ""} {
                if [expr [lindex $l 3] <= $indentSize] {
                   set varsBegin false
                   puts "====== $varsBegin $indentSize >[lindex $l 3]<"
                   continue
                }
            }
            lappend varList [list [lindex $l 0] [lindex $l 1] [lindex $l 2]]
        }
    }
    # puts $procList
    # puts $varList	
    close $f
    return $varList
}
proc GetVarFromLine {line fileType} {
    global lexers
    if {[dict exists $lexers $fileType varRegexpCommand] != 0 } {
        if {[eval [dict get $lexers $fileType varRegexpCommand]]} {
            if [info exists varName] {
                set varName [string trim $varName]
            } else {
                set varName ""
            }
            if [info exists varValue] {
                set varValue [string trim $varValue]
            } else {
                set varValue ""
            }
            if [info exists varType] {
                set varType [string trim $varType]
            } else {
                set varType ""
            }
            set indentLength  [string length $indent]
            puts "variable: $varName, value: $varValue, type: $varType, indent: >$indent< $indentLength"
            return [list $varName $varValue $varType $indentLength]
        }
    }
}
proc GetVariablesFromVarFile {fileName} {
    global tree nbEditor editors lexers project
    set fileType [string toupper [string trimleft [file extension $fileName] "."]]
    set procList ""
    set varList ""
    set params ""
    puts $fileName
    set f [open "$fileName" r]
    if {[dict exists $lexers $fileType] == 0} {return}
    while {[gets $f line] >=0 } {
        # Выбираем процедуры (функции, классы и т.д.)
        # if {[dict exists $lexers $fileType procRegexpCommand] != 0 } {
            # if {[eval [dict get $lexers $fileType procRegexpCommand]]} {
                # set procName_ [string trim $procName]
                # # puts [Tree::InsertItem $tree $treeItemName $procName_  "procedure" "$procName_ ($params)"]
                # lappend procList [list $procName_ $params]
                # unset procName_
            # }
        # }
        # Выбираем переменные
        lappend varList [GetVarFromLine $line $fileType]
    }
    # puts $procList
    # puts $varList	
    close $f
    return $varList
}
proc ReadFilesFromDirectory {directory root {type ""}} {
    global procList project lexers variables
    
    foreach i [split [dict get $lexers ALL varDirectory] " "] {
        lappend l [string trim $i]
        # puts "---->$i"
    }
    if {[catch {cd $directory}] != 0} {
        return ""
    }
    foreach fileName [glob -nocomplain *] {
        puts "Find file: $fileName [lsearch -exact -nocase $l $fileName]"
        if {[lsearch -exact $l $fileName] != -1 && [file isdirectory [file join $root $directory $fileName]] == 1} {
            # puts "--- $root $fileName"
            ReadFilesFromDirectory [file join $directory $fileName] $root "var"
        } elseif {[file isdirectory $fileName] == 1} {
            # set type ""
            ReadFilesFromDirectory [file join $directory $fileName] $root
        }
        if {[string match {*inventory*} [string tolower $fileName]]} {
            lappend project($root) [file join $root $directory $fileName]
            set variables([file join $root $directory $fileName]) \
                [GetVariablesFromVarFile [file join $root $directory $fileName]]        
        }
        if {[string tolower $fileName] eq "ansible.cfg"} {
            # puts "find ansible.cfg [file join $root $directory $fileName]"
            set f [open [file join $root $directory $fileName] r]
            while {[gets $f line] >= 0} {
                if [regexp -nocase -all -- {^\s*inventory\s*=\s*(\.\/|)(.+?)$} $line match v1 fileName] {
                    # puts "Inventory file is a: $line"
                    if {[lsearch $project($root) [file join $root $directory $fileName]] eq "-1"} {
                    lappend project($root) [file join $root $directory $fileName]
                        set variables([file join $root $directory $fileName]) \
                            [GetVariablesFromVarFile [file join $root $directory $fileName]]
                    }
                }
            }
            close $f
        }
        
        if {$type eq "var" && [file isdirectory [file join $root $directory $fileName]] != 1} {
            # puts ">>>>>$root $fileName"
            # puts "[GetVariablesFromFile $fileName]"
            # dict set project $root [file join $root $directory $fileName];# "[GetVariablesFromFile $fileName]"
            lappend project($root) [file join $root $directory $fileName]
            set variables([file join $root $directory $fileName]) \
                [GetVariablesFromVarFile [file join $root $directory $fileName]]
            # puts "[file join $root $directory $fileName]---$variables([file join $root $directory $fileName])"
        }
    }
}


# set threadID [thread::create {
    # proc runCommand {ID command} {
        # set result [eval $command]
        # eval [subst {thread::send -async $ID \
            # {::printResult [list $result]}}]
    # }
    # thread::wait
# }] 
# 
proc Accept { dirLib directory } {
    global dir
    puts $dir(lib)
   puts $dirLib
  # переменная с указанием ваших действия перед порождением потока
    set threadinit {
        # если необходимо, загружаем исходный tcl код, расположенный в других файлах
        foreach { s } { readstructure } {
          # uplevel #0 source [file join /home/svkalinin/Проекты/projman/lib $s.tcl]
          uplevel #0 source [file join $dirLib $s.tcl]
        }
        # не завершаем поток, ибо будет запущен событийный сокетный обработчик
        thread::wait
    }

      # порождаем поток, выполнив предварительные действия, описанные в переменной threadinit
      set tid [thread::create $threadinit]

      # thread::transfer $tid
      # запускаем поток в асинхронном режиме
      thread::send -async $tid [list ReadFilesFromDirectory $directory]
}


# процедура завершения потока
proc Exit:Thread {  } {
  # уничтожаем, останавливаем поток
  thread::release
}
