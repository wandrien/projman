######################################################
#                ProjMan 2
#        Distributed under GNU Public License
# Author: Sergey Kalinin svk@nuk-svk.ru
# Copyright (c) "", 2022, https://nuk-svk.ru
######################################################
#
# Operation with  NoteBook widget module
#
######################################################

namespace eval NB {
    proc InsertItem {nb item type} {
        switch $type {
            file {
                regsub -all {\.|/|\\|\s} $item "_" itemName
                if [winfo exists $nb.$itemName] {
                    set fm $nb.$itemName
                } else {
                    set fm [ttk::frame $nb.$itemName]
                    pack $fm -side top -expand true -fill both
                    $nb add $fm -text [file tail $item];# -image close_12x12 -compound right
                    $nb select $fm
                }
            }
            git {
                if [winfo exists $nb.$item] {
                    return $nb.$item
                }
                set fm [ttk::frame $nb.$item]
                pack $fm -side top -expand true -fill both
                $nb add $fm -text Git;# -image close_12x12 -compound right
                $nb select $fm                
            }
        }
        # puts "NB item - $fm"
        return $fm
    }

    proc PressTab {w x y} {
        if {[$w identify tab $x $y] ne ""} {
            $w select [$w identify tab $x $y]
        } else {
            return
        }
        if {[$w identify $x $y] == "close_button"} {
            FileOper::Close
        } else {
            set txt [$w select].frmText.t
            if [winfo exists $txt] {
                focus -force $txt.t
            }
        }
    }

    proc NextTab {w step} {
        set i [expr [$w index end] - 1]
        set nbItemIndex [$w index [$w select]]
        if {$nbItemIndex eq 0 && $step eq "-1"} {
            $w select $i
        } elseif {$nbItemIndex eq $i && $step eq "1"} {
            $w select 0
        } else {
            $w select [expr $nbItemIndex + $step]
        }
        set txt [$w select].frmText.t
        focus -force $txt.t
    }
}
