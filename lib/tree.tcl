#!/usr/bin/wish
######################################################
#                ProjMan 2
#        Distributed under GNU Public License
# Author: Sergey Kalinin svk@nuk-svk.ru
# Copyright (c) "", 2022, https://nuk-svk.ru
######################################################
#
# Tree  widget working module
#
######################################################


namespace eval Tree {
    proc InsertItem {tree parent item type text} {
        # set img [GetImage $fileName]
        set dot "_"
        # puts "$tree $parent $item $type $text"
        switch $type  {
            file {
                regsub -all {\.|/|\\|\s} $item "_" subNode
                # puts "Inserted tree node: $subNode"
                set fileExt [string trimleft [file extension $text] "."]
                #set fileName [string trimleft [file extension $text] "."]
                set findImg [::FindImage $fileExt]
                # puts "Extention $fileExt, find image: $findImg"
                # puts ">>>>>>>>>>> [string tolower $text]; [string match {*docker*} [string tolower $text]]"
                if {[string match {*docker*} [string tolower $text]]} {
                    set findImg [::FindImage docker]
                } elseif {[string match {*gitlab*} [string tolower $text]]} {
                    set findImg [::FindImage gitlab]
                } elseif {[string match {*bitbucket*} [string tolower $text]]} {
                    set findImg [::FindImage bitbucket]
                }
                if {$fileExt ne "" || $findImg ne ""} {
                    set image $findImg
                } else {
                    set image imgFile
                }
            }
            directory {
                regsub -all {\.|/|\\|\s} $item "_" subNode
                # puts $subNode
                if {[string match {*debian*} [string tolower [file tail $item]]]} {
                    set image [::FindImage debian]
                } elseif {[string match {*redhat*} [string tolower [file tail $item]]]} {
                    set image [::FindImage redhat]
                } elseif {[string match {*gitlab*} [string tolower [file tail $item]]]} {
                    set image [::FindImage gitlab]
                } else {
                    set image pixel
                }
            }
            func {
                regsub -all {:} $item "_" subNode
                # puts $subNode
                set image proc_10x10                
            }
            procedure {
                regsub -all {\.|/|\\|\s|"|\{|\}|\(|\)} $item "_" subNode
                # puts $subNode
                set image proc_10x10                
            }
        }
        append id $type "::" $subNode
        puts "Tree ID: $id, tree item: $item"
        if ![$tree exists $id] {
            $tree insert $parent end -id "$id" -text " $text" -values "$item" -image $image
        }
        return "$id"
    }
    proc DoublePressItem {tree} {
        set id [$tree selection]
        $tree tag remove selected
        $tree item $id -tags selected
        
        set values [$tree item $id -values]
        set key [lindex [split $id "::"] 0]
        if {$values eq "" || $key eq ""} {return}
        
        puts "$key $tree $values"
        switch $key {
            directory {
                FileOper::ReadFolder  $values             
            }
            file {
                FileOper::Edit $values
                # $tree item $id -open false
            }
        }
    }

    proc PressItem {tree} {
        global nbEditor lexers editors
        set id [$tree selection]
        $tree tag remove selected
        $tree item $id -tags selected
        
        set values [$tree item $id -values]
        set key [lindex [split $id "::"] 0]
        if {$values eq "" || $key eq ""} {return}
        
        puts "$key $tree $values"
        switch -regexp $key {
            directory {
                FileOper::ReadFolder  $values
                # $tree item $id -open false
            }
            file {
                FileOper::Edit $values
            }
            I[0-9]*? {
                destroy .findVariables
                FileOper::Edit [lindex $values 2]
            }
            default {
                set parentItem [$tree parent $id]
                # puts $values
                set nbItem "$nbEditor.[string range $parentItem [expr [string last "::" $parentItem] + 2] end]"
                $nbEditor select $nbItem
                set txt $nbItem.frmText.t
                set findString [dict get $lexers [dict get $editors $txt fileType] procFindString]
                regsub -all {PROCNAME} $findString $values str

                Editor::FindFunction "$str"
            }
        }
    }

    proc GetItemID {tree item} {
        if [$tree exists $item] {
            return [$tree item $item -values]
        }
    }
}
