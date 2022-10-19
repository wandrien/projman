######################################################
#                ProjMan 2
#        Distributed under GNU Public License
# Author: Sergey Kalinin svk@nuk-svk.ru
# Copyright (c) "", 2022, https://nuk-svk.ru
######################################################
# Working with files module
######################################################


namespace eval FileOper {
    variable  types
    
    set ::types {
        {"All files" *}
    }        
    
    proc OpenDialog {} {
        global env project activeProject
        if [info exists activeProject] {
            set dir $activeProject
        } else {
            set dir $env(HOME)
        }
        set fullPath [tk_getOpenFile -initialdir $dir -filetypes $::types -parent .]
        set file [string range $fullPath [expr [string last "/" $fullPath]+1] end]
        regsub -all "." $file "_" node
        set dir [file dirname $fullPath]
        set file [file tail $fullPath]
        set name [file rootname $file]
        set ext [string range [file extension $file] 1 end]
        if {$fullPath != ""} {
            # puts $fullPath
            return $fullPath
        } else {
            return
        }
    }
    
    proc OpenFolderDialog {} {
        global env activeProject
        #global tree node types dot env noteBook fontNormal fontBold fileList noteBook projDir activeProject imgDir editor rootDir
        #     set dir $projDir
        if [info exists activeProject] {
            set dir $activeProject
        } else {
            set dir $env(HOME)
        }
        set fullPath [tk_chooseDirectory  -initialdir $dir -parent .]
        set file [string range $fullPath [expr [string last "/" $fullPath]+1] end]
        regsub -all "." $file "_" node
        set dir [file dirname $fullPath]
        #     EditFile .frmBody.frmCat.noteBook.ffiles.frmTreeFiles.treeFiles $node $fullPath
        # puts $fullPath
        if ![info exists activeProject] {
            set activeProject $fullPath
        }
        .frmStatus.lblGitLogo configure -image git_logo_20x20
        .frmStatus.lblGit configure -text "[::msgcat::mc "Branch"]: [Git::Branches current]"
        return $fullPath
    }

    proc CloseFolder {} {
        global tree nbEditor activeProject

        set treeItem [$tree selection]
        set parent [$tree parent $treeItem]
        while {$parent ne ""} {
            set treeItem $parent
            set parent [$tree parent $treeItem]
        }
        if {$parent eq "" && [string match "directory::*" $treeItem] == 1} {
            # puts "tree root item: $treeItem"
            foreach nbItem [$nbEditor tabs] {
                set item [string trimleft [file extension $nbItem] "."]
                # puts $item
                if [$tree exists "file::$item"] {
                    $nbEditor select $nbItem
                    Close
                }
            }
            $tree delete $treeItem
        }
        set activeProject ""
        .frmStatus.lblGitLogo configure -image pixel
        .frmStatus.lblGit configure -text ""
    }

    proc CloseAll {} {
        global nbEditor modified
        foreach nbItem [array names modified] {
            if {$modified($nbItem) eq "true"} {
                $nbEditor select $nbItem
                # puts "close tab $nbItem"
                if {[Close] eq "cancel"} {return "cancel"}
            }
        }
    }

    proc Close {} {
        global nbEditor modified tree
        set nbItem [$nbEditor select]
	    # puts "close tab $nbItem"
    	   
        if {$nbItem == ""} {return}
        if [info exists modified($nbItem)] {
            if {$modified($nbItem) eq "true"} {
                set answer [tk_messageBox -message [::msgcat::mc "File was modifyed"] \
                    -icon question -type yesnocancel \
                    -detail [::msgcat::mc "Do you want to save it?"]]
                switch $answer {
                    yes Save
                    no {}
                    cancel {return "cancel"}
                }
            }
        }
        $nbEditor forget $nbItem
        destroy $nbItem
        set treeItem "file::[string range $nbItem [expr [string last "." $nbItem] +1] end ]"
        if [$tree exists $treeItem] {
            # delete all functions from tree item
            set children [$tree children $treeItem]
            if {$children ne ""} {
                foreach i $children {
                    $tree delete $i
                }
            }
            if {[$tree parent $treeItem] eq ""} {
                $tree delete $treeItem
            }
        }
        unset modified($nbItem)
        .frmStatus.lblPosition configure -text ""
    }
    
    proc Save {} {
        global nbEditor tree env activeProject

        if [info exists activeProject] {
            set dir $activeProject
        } else {
            set dir $env(HOME)
        }
        
        set nbEditorItem [$nbEditor select]
        puts "Saved editor text: $nbEditorItem"
        if [string match "*untitled*" $nbEditorItem] {
            set filePath [tk_getSaveFile -initialdir $dir -filetypes $::types -parent .]
            if {$filePath eq ""} {
                return
            }
            # set fileName [string range $filePath [expr [string last "/" $filePath]+1] end]
            set fileName [file tail $filePath]
            $nbEditor tab $nbEditorItem -text $fileName
            # set treeitem [Tree::InsertItem $tree {} $filePath "file" $fileName]
            set lblName "lbl[string range $nbEditorItem [expr [string last "." $nbEditorItem] +1] end]"
            $nbEditorItem.header.$lblName configure -text $filePath
        } else {
            set treeItem "file::[string range $nbEditorItem [expr [string last "." $nbEditorItem] +1] end ]"
            set filePath [Tree::GetItemID $tree $treeItem]
        }
        set editedText [$nbEditorItem.frmText.t get 0.0 end]
        set f [open $filePath "w+"]
        puts -nonewline $f $editedText
        puts "$f was saved"
        close $f
        ResetModifiedFlag $nbEditorItem
    }
    
    proc SaveAll {} {
        
    }
    
    proc Delete {} {
        set node [$tree selection get]
        set fullPath [$tree itemcget $node -data]
        set dir [file dirname $fullPath]
        set file [file tail $fullPath]
        set answer [tk_messageBox -message "[::msgcat::mc "Delete file"] \"$file\"?"\
        -type yesno -icon question -default yes]
        case $answer {
            yes {
                FileDialog $tree close
                file delete -force "$fullPath"
                $tree delete $node
                $tree configure -redraw 1
                return 0
            }
        }
    }
    
    proc ReadFolder {directory {parent ""}} {
        global tree dir lexers  project
        puts "Read the folder $directory"
        set rList ""
        if {[catch {cd $directory}] != 0} {
            return ""
        }
        set parent [Tree::InsertItem $tree $parent $directory "directory" [file tail $directory]]
        $tree selection set $parent
        # if {[ $tree  item $parent -open] eq "false"} {
            # $tree  item $parent -open true
        # } else {
            # $tree  item $parent -open false
        # }
        # Проверяем наличие списка каталогов для спецобработки
        # и если есть читаем в список (ножно для ansible)
        if {[dict exists $lexers ALL varDirectory] == 1} {
            foreach i [split [dict get $lexers ALL varDirectory] " "] {
                # puts "-------- $i"
                lappend dirListForCheck [string trim $i]
            }
        }
        # Getting an files and directorues lists
        foreach file [glob -nocomplain *] {
            lappend rList [list [file join $directory $file]]
            if [file isdirectory $file] {
                lappend lstDir $file
            } else {
                lappend lstFiles $file
            }
        }
        foreach file [glob -nocomplain .?*] {
            if {$file ne ".."} {
                lappend rList [list [file join $directory $file]]
                if [file isdirectory $file] {
                    lappend lstDir $file
                } else {
                    lappend lstFiles $file
                }
            }
        }
        # Sort  lists and insert into tree
        if {[info exists lstDir] && [llength $lstDir] > 0} {
            foreach f [lsort $lstDir] {
                set i [Tree::InsertItem $tree $parent [file join $directory $f] "directory" $f]
                # puts "Tree insert item: $i $f]"
                ReadFolder [file join $directory $f] $i
                unset i
            }
        }
        if {[info exists lstFiles] && [llength $lstFiles] > 0} {
            foreach f [lsort $lstFiles] {
                Tree::InsertItem $tree $parent [file join $directory $f] "file" $f
                # puts "Tree insert item: "
            }
        }
        # Чтение структуры файлов в каталоге
        #  пока криво работает
        # Accept $dir(lib) $directory
    }
    
    proc ReadFile {fileFullPath itemName} {
        set txt $itemName.frmText.t
        if ![string match "*untitled*" $itemName] {
            set file [open "$fileFullPath" r]
            $txt insert end [chan read -nonewline $file]  
            close $file
        }
        # Delete emty last line
        if {[$txt get {end-1 line} end] eq "\n" || [$txt get {end-1 line} end] eq "\r\n"} {
            $txt delete {end-1 line} end
            puts ">[$txt get {end-1 line} end]<"
        }
        $txt see 1.0
    }
    
    proc Edit {fileFullPath} {
        global nbEditor tree
        if {[file exists $fileFullPath] == 0} {
            return false
        }
        
        set filePath [file dirname $fileFullPath]
        set fileName [file tail $fileFullPath]
        regsub -all {\.|/|\\|\s} $fileFullPath "_" itemName
        set itemName "$nbEditor.$itemName"
        set treeItemName [Tree::InsertItem $tree {} $fileFullPath "file" $fileName]
        if {[winfo exists $itemName] == 0} {
            NB::InsertItem $nbEditor $fileFullPath "file"
            Editor::Editor $fileFullPath $nbEditor $itemName
            ReadFile $fileFullPath $itemName
            $itemName.frmText.t highlight 1.0 end
            ResetModifiedFlag $itemName
            $itemName.frmText.t see 1.1
        }
        $nbEditor select $itemName
        Editor::ReadStructure $itemName.frmText.t $treeItemName
        GetVariablesFromFile $fileFullPath
        $itemName.frmText.t.t mark set insert 1.0
        $itemName.frmText.t.t see 1.0
        focus -force $itemName.frmText.t.t
        
        return $itemName
    }
    
    proc FindInFiles {} {
        global nbEditor activeProject
        set res ""
        set txt ""
        set str ""
        set nbEditorItem [$nbEditor select]
        if {$nbEditorItem ne ""} {
            set txt $nbEditorItem.frmText.t
            # set txt [focus]
            set selIndex [$txt tag ranges sel]
            if {$selIndex ne ""} {
                set selBegin [lindex [$txt tag ranges sel] 0]
                set selEnd [lindex [$txt tag ranges sel] 1]
                set str [$txt get $selBegin $selEnd]
                puts $str
                set res [SearchStringInFolder $str]
            }
        }
        FindInFilesDialog $txt $res
        .find.entryFind delete 0 end
        .find.entryFind insert end $str
    }

    proc ReplaceInFiles {} {
        global nbEditor
        return
        # set selIndex [$txt tag ranges sel]
        # set selBegin [lindex [$txt tag ranges sel] 0]
        # set selEnd [lindex [$txt tag ranges sel] 1]
        # puts [$txt get [$txt tag ranges sel]]
    # }
    
}
