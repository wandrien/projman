######################################################
#                ProjMan 2
#        Distributed under GNU Public License
# Author: Sergey Kalinin svk@nuk-svk.ru
# Copyright (c) "", 2022, https://nuk-svk.ru
######################################################
#
# All procedures module
#
######################################################

proc Quit {} {
    global dir
    Config::write $dir(cfg)
    if {[FileOper::CloseAll] eq "cancel"} {
        return "cancel"
    } else {
        exit
    }
}

proc ViewFilesTree {{hotkey "false"}} {
    global cfgVariables
    if {$hotkey eq "true"} {
        if {$cfgVariables(filesPanelShow) eq "false"} {
            set cfgVariables(filesPanelShow) true
        } else {
            set cfgVariables(filesPanelShow) false
        }
    }
    if {$cfgVariables(filesPanelShow) eq "false"} {
        .frmBody.panel forget .frmBody.frmTree
    } else {
        switch $cfgVariables(filesPanelPlace) {
            "left" {        
                .frmBody.panel insert 0 .frmBody.frmTree
            }
            "right" {
                if {[lsearch -exact [.frmBody.panel panes] .frmBody.frmTree] != -1} {
                    .frmBody.panel forget .frmBody.frmTree
                }
                .frmBody.panel add .frmBody.frmTree
            }
            default {
                .frmBody.panel insert 0 .frmBody.frmTree
            }
        }
    }
}

proc ViewMenuBar {{hotkey "false"}} {
    global cfgVariables
    if {$hotkey eq "true"} {
        if {$cfgVariables(menuShow) eq "false"} {
            set cfgVariables(menuShow) true
        } else {
            set cfgVariables(menuShow) false
        }
    }
    if {$cfgVariables(menuShow) eq "false"} {
        grid remove .frmMenu
    } else {
        grid .frmMenu -row 0 -column 0 -sticky new
    }
}

proc ViewStatusBar {{hotkey "false"}} {
    global cfgVariables
    if {$hotkey eq "true"} {
        if {$cfgVariables(statusBarShow) eq "false"} {
            set cfgVariables(statusBarShow) true
        } else {
            set cfgVariables(statusBarShow) false
        }
    }
    if {$cfgVariables(statusBarShow) eq "false"} {
        grid remove .frmStatus
    } else {
        grid .frmStatus -row 2 -column 0 -sticky sew
    }
}

proc ViewToolBar {{hotkey "false"}} {
    global cfgVariables
    if {$hotkey eq "true"} {
        if {$cfgVariables(toolBarShow) eq "false"} {
            set cfgVariables(toolBarShow) true
        } else {
            set cfgVariables(toolBarShow) false
        }
    }
    if {$cfgVariables(toolBarShow) eq "false"} {
        grid remove .frmBody.frmTool
    } else {
        grid .frmBody.frmTool -row 0 -column 0 -sticky nsw
    }
}

# Enable/Disabled line numbers in editor
proc ViewLineNumbers {} {
    global cfgVariables nbEditor
    foreach node [$nbEditor tabs] {
        if [winfo exists $node.frmText.t] {
            $node.frmText.t configure -linemap $cfgVariables(lineNumberShow)
        }
    }
}

proc ViewHelper {helper} {
    global cfgVariables
    # Changed global settigs
    if {$cfgVariables($helper) eq "true"} {
        set cfgVariables($helper) false
    } else {
        set cfgVariables($helper) true
    }
}
proc WelcomeDialog {} {
    set win .welcome
    set x [winfo rootx .frmWork]
    set y [winfo rooty .frmWork]

    if { [winfo exists $win] } {
        destroy $win
        return
    }
    toplevel $win
    wm transient $win .
    wm overrideredirect $win 1
    
    ttk::button $win.btnOpenFolder -text [::msgcat::mc "Open folder"] -command {
        destroy .welcome
        set folderPath [FileOper::OpenFolderDialog]
        if {$folderPath != ""} {
            set activeProject $folderPath
            FileOper::ReadFolder $folderPath
            ReadFilesFromDirectory $folderPath $folderPath
        }
    }
    ttk::button $win.btnOpenFile -text [::msgcat::mc "Open file"] -command {
        destroy .welcome
        set filePath [FileOper::OpenDialog]
        if {$filePath != ""} {
            FileOper::Edit $filePath
        }
    }
    ttk::button $win.btnNewFile -compound center -text [::msgcat::mc "New file"] \
        -command {
            destroy .welcome
            Editor::New
        }
    
    pack $win.btnOpenFolder -expand true -fill x -side top -padx 3 -pady 3
    pack $win.btnOpenFile -expand true -fill x -side top -padx 3 -pady 3
    pack $win.btnNewFile -expand true -fill x -side top -padx 3 -pady 3

    bind $win <Escape> "destroy $win"
    # Определям расстояние до края экрана (основного окна) и если
    # оно меньше размера окна со списком то сдвигаем его вверх
    set winGeom [winfo reqheight $win]
    set topHeight [winfo height .]
    # debug_puts "$x, $y, $winGeom, $topHeight"
    if [expr [expr $topHeight - $y] < $winGeom] {
        set y [expr $topHeight - $winGeom]
    }
    wm geom $win +$x+$y
    focus $win.btnOpenFolder
}    

proc ToolBtnTreePress {} {
    global cfgVariables activeProject
    if [info exists activeProject] {
        if {$activeProject ne ""} {
            ViewFilesTree true
        }
    } else {
        WelcomeDialog
    }
}

proc Del {} {
    return
}

proc YScrollCommand {txt canv} {
    $txt yview
    $canv yview"
}

proc ResetModifiedFlag {w nbEditor} {
    global modified 
    $w.frmText.t edit modified false
    set modified($w) "false"
    set lbl [string trimleft [$nbEditor tab $w -text] "* "]
    # debug_puts "ResetModifiedFlag: $lbl"
    $nbEditor tab $w -text $lbl
}
proc SetModifiedFlag {w nbEditor force} {
    global modified
    if {$force eq "force"} {
        $w.frmText.t edit modified true
    } else {
        if {![$w.frmText.t edit modified]} {
            return
        }
    }
    set modified($w) "true"
    set lbl [$nbEditor tab $w -text]
    # debug_puts "SetModifiedFlag: $w; $modified($w); >$lbl<"
    if {[regexp -nocase -all -- {^\*} $lbl match] == 0} {
        set lbl "* $lbl"
    }
    $nbEditor tab $w -text $lbl
}

proc ImageBase64Encode {} {
    global env nbEditor
    set types {
        {"PNG" {.png}}
        {"GIF" {.gif}}
        {"JPEG" {.jpg}}
        {"BMP" {.bmp}}
        {"All files" *}
    }
    set txt "[$nbEditor select].frmText.t"
    set img [tk_getOpenFile -initialdir $env(HOME) -filetypes $types -parent .]
    if {$img ne ""} {
        set f [open $img]
        fconfigure $f -translation binary
        set data [base64::encode [read $f]]
        close $f
        # base name on root name of the image file
        set name [file root [file tail $img]]
        $txt insert insert "image create photo $name -data {\n$data\n}"
    }
}
proc FindImage {ext} {
    set imageType {
        PNG
        JPG
        JPEG
        WEBP
        GIF
        TIFF
        JP2
        ICO
        XPM
        SVG
    }
    foreach img [image names] {
        if [regexp -nocase -all -- "^($ext)(_16x12)" $img match v1 v2] {
            # debug_puts "\nFindinig images: $img \n"
            return $img
        }
    }
    if {[lsearch -exact -nocase $imageType $ext] != -1} {
        return image_16x12
    }
}

namespace eval Help {
    proc About {} {
        global projman
        set msg "Tcl/Tk project Manager\n\n"
        append msg  "Version: " $projman(Version) "\n" \
            "Release: " $projman(Release) "\n" \
            "Build: " $projman(Build) "\n\n" \
            "Author: " $projman(Author) "\n" \
            "Home page: " $projman(Homepage)
        # foreach name [array names projman] {
            # append msg $name ": " $projman($name) "\n"
        # }
        set answer [
            tk_messageBox -message "[::msgcat::mc "About ..."] ProjMan" \
            -icon info -type ok -detail $msg
        ]
        switch $answer {
            ok {return}
        }
    }
}

proc SearchVariable {txt} {
    global fileStructure project variables
    set varName [$txt get {insert wordstart} {insert wordend}]
    debug_puts ">>>$varName<<<"
    if {[info exists project] == 0} {return}
    foreach f [array names project] {
        debug_puts "--$f"
        debug_puts "----"
        foreach a $project($f) {
            debug_puts "-----$variables($a)"
            foreach b $variables($a) {
                debug_puts "------$b -- [lindex $b 0]"
                if {$varName eq [lindex $b 0]} {
                    debug_puts "УРААААААА $varName = $b в файле $a \n\t [lindex $b 0]"
                    # FindVariablesDialog $txt "$varName: \[...\][file tail $a]"
                    lappend l [list $varName [lindex $b 1] $a]
                }
            }
        }
    }
    if [info exists l] {
        FindVariablesDialog $txt $l
    } else {
        return
    }
}
proc GetVariableFilePath {txt} {
    set str [$txt get {insert linestart} {insert lineend}]
    if [regexp -nocase -all -- {^([0-9A-Za-z\-_:]*?) > (.*?) > (.*?)$} $str match vName vValue vPath] {
        return [list $vName $vPath $vValue]
    }
}

proc FindVariablesDialog {txt args} {
    global editors lexers cfgVariables
    # variable txt 
    variable win
    variable t $txt
    # set txt $w.frmText.t
    set box [$txt bbox insert]
    set x   [expr [lindex $box 0] + [winfo rootx $txt] ]
    set y   [expr [lindex $box 1] + [winfo rooty $txt] + [lindex $box 3] ]

    set win .findVariables
    if [winfo exists .varhelper] {
       destroy .varhelper
    }

    if { [winfo exists $win] }  { destroy $win }
    toplevel $win
    wm transient $win .
    wm overrideredirect $win 1
    # set win [canvas $win.c -yscrollcommand "$win.v set" -xscrollcommand "$win.h set"]

    # listbox $win.lBox -width 50 -border 2 -yscrollcommand "$win.yscroll set" -border 1
    # ttk::treeview $win.lBox -show headings -height 5\
        # -columns "variable value path" -displaycolumns "variable value path"\
        # -yscrollcommand [list $win.v set] -xscrollcommand [list $win.h set]
    ctext $win.lBox -height 5 -font $cfgVariables(font) -wrap none \
        -yscrollcommand [list $win.v set] -xscrollcommand [list $win.h set] \
        -linemapfg $cfgVariables(lineNumberFG) -linemapbg $cfgVariables(lineNumberBG)
    
    ttk::scrollbar $win.v -orient vertical -command  "$win.lBox yview"
    ttk::scrollbar $win.h -orient horizontal -command  "$win.lBox xview"
    # pack $win.lBox -expand true -fill y -side left
    # pack $win.yscroll -side left -expand false -fill y
    # pack $win.xscroll -side bottom -expand false -fill x
        
    grid $win.lBox -row 0 -column 0 -sticky nsew
    grid $win.v -row 0 -column 1 -sticky nsew
    grid $win.h -row 1 -column 0 -sticky nsew
    grid columnconfigure $win 0 -weight 1
    grid rowconfigure $win 0 -weight 1
        
    # $win.lBox heading variable -text [::msgcat::mc "Variable"]
    # $win.lBox heading value -text [::msgcat::mc "Value"]
    # $win.lBox heading path -text [::msgcat::mc "File path"]
    # set height 0
    foreach { word } $args {
        foreach lst $word {
            # set l [split $lst " "]
            debug_puts "[lindex $lst 0] -[lindex $lst 1] -[lindex $lst 2]"
            # lappend l2 [lindex $l 0] [lindex $l 1] [file tail [lindex $l 2]]
            # $win.lBox insert {} end -values $lst -text {1 2 3}
            $win.lBox insert end "[lindex $lst 0] > [lindex $lst 1] > [lindex $lst 2]\n"
            # $win.lBox insert end $word
            incr height
        }
    }
    # $win.lBox selection set I001
    # catch { $win.lBox activate 0 ; $win.lBox selection set 0 0 }
    
    if { $height > 10 } { set height 10 }
    $win.lBox configure -height $height

    bind $win <Escape> { 
        destroy $win
        focus -force $t.t
        break
    }
    bind $win.lBox <Escape> {
        destroy $win
        focus -force $t.t
        break
    }
    bind $win.lBox <Return> {
        # set findString [dict get $lexers [dict get $editors $Editor::txt fileType] procFindString]
        # set id [$win.lBox selection]
        # set values [$win.lBox item $id -values]
        # set key [lindex [split $id "::"] 0]
        # 
        # debug_puts "- $id - $values - $key"
        # regsub -all {PROCNAME} $findString $values str
        # Editor::FindFunction "$str"
        set _v [GetVariableFilePath $win.lBox]
        set varName [lindex $_v 0]
        set path [lindex $_v 1]
        unset _v
        if {$path ne ""} {
            destroy .findVariables
            FileOper::Edit $path
            Editor::FindFunction $t "$varName"
        }
        # $txt tag remove sel 1.0 end
        # focus $Editor::txt.t
        break
    }
    # bind $win.lBox <Double-ButtonPress-1> {Tree::DoublePressItem $win.lBox}
    bind $win.lBox <ButtonRelease-1> {
        set _v [GetVariableFilePath $win.lBox]
        set varName [lindex $_v 0]
        set path [lindex $_v 1]
        unset _v
        if {$path ne ""} {
            destroy .findVariables
            FileOper::Edit $path
            Editor::FindFunction $t "$varName"
        }
        break
    }
    
    # bind $win.lBox <Any-Key> {Editor::ListBoxSearch %W %A}
    # Определям расстояние до края экрана (основного окна) и если
    # оно меньше размера окна со списком то сдвигаем его вверх
    set winGeom [winfo reqheight $win]
    set topHeight [winfo height .]
    # debug_puts "$x, $y, $winGeom, $topHeight"
    if [expr [expr $topHeight - $y] < $winGeom] {
        set y [expr $topHeight - $winGeom]
    }
    ctext::addHighlightClassForSpecialChars $win.lBox namespaces #4f64ff {>}
    $win.lBox highlight 1.0 end
    
    wm geom $win +$x+$y
    $win.lBox mark set insert 1.0
    $win.lBox see 1.0
    focus -force $win.lBox.t
    # $win.lBox focus I001
}

## Search string into all files from directory
proc SearchStringInFolder {str} {
    global cfgVariables activeProject tcl_platform
    set res ""
    if {$tcl_platform(platform) == "windows"} {
    } elseif {$tcl_platform(platform) == "mac"} {
    } elseif {$tcl_platform(platform) == "unix"} {
        debug_puts "$cfgVariables(searchCommand) $cfgVariables(searchCommandOptions) $str $activeProject"
        # Составляем строку (точнее список) для запуска команды
        set cmd exec
        regsub -all {\[} $str {\\[} str
        regsub -all {\]} $str {\\]} str
        lappend cmd $cfgVariables(searchCommand)
        foreach o [split $cfgVariables(searchCommandOptions) " "] {
            lappend cmd $o
        }
        lappend cmd $str
        lappend cmd $activeProject
        # запускаем
        # debug_puts $cmd
        catch $cmd pipe
        # debug_puts $pipe
        # fileevent $pipe readable
        # fconfigure $pipe -buffering none -blocking no
    }
    # while {[chan gets $pipe line] >= 0} {
        # debug_puts "--> $line"
    # }
    foreach line [split $pipe "\n"] {
        if [regexp -nocase -all -line -- {^((\/[\w\-_\.\s]+)+):([0-9]+):\s*(.+?)} $line match fullPath fileName lineNumber fullString] {
            # debug_puts "$fullPath $fileName $lineNumber $fullString"
            lappend res [list $lineNumber $fullPath $fullString]
        }
    }
    if {$res ne ""} {
        return $res
    } else {
        return false
    }
}

proc InsertListIntoText {win lst} {
    set height 0
    set fCount 0
    set fName ""
    # debug_puts $lst
    foreach { word } $lst {
        foreach lst $word {
            # set l [split $lst " "]
            # debug_puts "[lindex $lst 0] -[lindex $lst 1] -[lindex $lst 2]"
            # lappend l2 [lindex $l 0] [lindex $l 1] [file tail [lindex $l 2]]
            # $win.lBox insert {} end -values $lst -text {1 2 3}
            $win.lBox insert end "[lindex $lst 0] > [lindex $lst 1] > [lindex $lst 2]\n"
            # $win.lBox insert end $word
            incr height
            if {$fName ne [lindex $lst 1]} {
                set fName [lindex $lst 1]
                incr fCount
            }
        }
    }
    set rows $height
    if { $height > 10 } { set height 10 }
    $win.lBox configure -height $height
    unset height
    return [list $rows $fCount]
}

proc FindInFilesDialog {txt {args ""}} {
    global editors lexers cfgVariables
    # variable txt
    variable win
    variable t $txt
    variable lblText "[::msgcat::mc "Found"] %s\
        [::msgcat::mc "Matches"]\
        [::msgcat::mc "In"] %s\
        [::msgcat::mc "Files"]"

    # debug_puts $txt
    # set txt $w.frmText.t
    if {$txt ne ""} {
        focus $txt
        set box [$txt bbox insert]
        set x   [expr [lindex $box 0] + [winfo rootx $txt] ]
        set y   [expr [lindex $box 1] + [winfo rooty $txt] + [lindex $box 3] ]
    } else {
        set txt .frmWork
        set x [winfo rootx .frmWork]
        set y [winfo rooty .frmWork]
    }
    set win .find
        
    if { [winfo exists $win] }  { destroy $win; return false}
    toplevel $win
    wm transient $win .
    wm overrideredirect $win 1
    # set win [canvas $win.c -yscrollcommand "$win.v set" -xscrollcommand "$win.h set"]

    ttk::entry $win.entryFind -width 30 -textvariable findString
    ttk::entry $win.entryReplace -width 30 -textvariable replaceString
    set cmd {
        $win.lBox delete 1.0 end
        set res [list [SearchStringInFolder $findString]]
        set rows [InsertListIntoText $win $res]
        set lblText "[::msgcat::mc "Found"] [lindex $rows 0]\
            [::msgcat::mc "Matches"]\
            [::msgcat::mc "In"] [lindex $rows 1]\
            [::msgcat::mc "Files"]"
        .find.lblCounter configure -text $lblText
        # unset lblText
        ctext::addHighlightClassForSpecialChars $win.lBox namespaces #4f64ff {>}
        $win.lBox highlight 1.0 end

        $win.lBox mark set insert 1.0
        $win.lBox see 1.0
        focus -force $win.lBox.t
    }
    ttk::button $win.bForward -image forward_20x20 -command $cmd

    ttk::button $win.bDoneAll -image doneall_20x20 -command {
        # Editor::FindReplaceText $Editor::txt "$findString" "$replaceString" $regexpSet
    }
    ttk::label $win.lblCounter -justify right -anchor w -text ""
    
    ctext $win.lBox -height 5 -font $cfgVariables(font) -wrap none \
        -yscrollcommand [list $win.v set] -xscrollcommand [list $win.h set] \
        -linemapfg $cfgVariables(lineNumberFG) -linemapbg $cfgVariables(lineNumberBG)
    
    ttk::scrollbar $win.v -orient vertical -command  "$win.lBox yview"
    ttk::scrollbar $win.h -orient horizontal -command  "$win.lBox xview"
    
    bind $win.entryFind <Return> $cmd
    
    grid $win.entryFind -row 0 -column 0 -sticky nsew
    grid $win.entryReplace -row 1 -column 0 -sticky nsew 
    grid $win.bForward -row 0 -column 2 -sticky e -columnspan 2
    grid $win.bDoneAll -row 1 -column 2 -sticky e -columnspan 2
    # grid $win.chkRegexp -row 2 -column 0 -sticky w
    # grid $win.chkAll -row 2 -column 1  -sticky w
    grid $win.lblCounter -row 2 -column 0 -columnspan 4 -sticky we
        
    grid $win.lBox -row 3 -column 0 -columnspan 3 -sticky nsew
    grid $win.v -row 3 -column 3 -sticky nsew
    grid $win.h -row 4 -column 0 -sticky nsew -columnspan 4
    grid columnconfigure $win 0 -weight 1
    grid rowconfigure $win 0 -weight 1

    if {$args ne ""} {
        set rows [InsertListIntoText $win $args]
        set lblText [format $lblText [lindex $rows 0] [lindex $rows 1]]
        # focus -force $win.lBox.t
    } else {
        set lblText ""
        # focus -force $win.entryFind
    }
    .find.lblCounter configure -text $lblText
    unset lblText
    
    # $win.lBox selection set I001
    # catch { $win.lBox activate 0 ; $win.lBox selection set 0 0 }
    
    bind $win <Escape> { 
        destroy $win
        focus -force $t
        break
    }
    bind $win.lBox <Escape> {
        destroy $win
        focus -force $t
        break
    }
    bind $win.lBox <Return> {
        set _v [GetVariableFilePath $win.lBox]
        set lineNum [lindex $_v 0]
        set path [lindex $_v 2]
        unset _v
        # debug_puts "$lineNum $path"
        if {$path ne ""} {
            destroy .find
            set fr [FileOper::Edit $path]
            Editor::GoToLineNumber $fr.frmText.t.t $lineNum
        }
        break
    }
    # bind $win.lBox <Double-ButtonPress-1> {Tree::DoublePressItem $win.lBox}
    bind $win.lBox <ButtonRelease-1> {
        set _v [GetVariableFilePath $win.lBox]
        set lineNum [lindex $_v 0]
        set path [lindex $_v 2]
        unset _v
        # debug_puts "$lineNum $path"
        if {$path ne ""} {
            destroy .find
            set fr [FileOper::Edit $path]
            Editor::GoToLineNumber $fr.frmText.t.t $lineNum
        }
        break
    }
    
    # bind $win.lBox <Any-Key> {Editor::ListBoxSearch %W %A}
    # Определям расстояние до края экрана (основного окна) и если
    # оно меньше размера окна со списком то сдвигаем его вверх
    set winGeom [winfo reqheight $win]
    set topHeight [winfo height .]
    # debug_puts "$x, $y, $winGeom, $topHeight"
    if [expr [expr $topHeight - $y] < $winGeom] {
        set y [expr $topHeight - $winGeom]
    }
    ctext::addHighlightClassForSpecialChars $win.lBox namespaces #4f64ff {>}
    $win.lBox highlight 1.0 end
    
    wm geom $win +$x+$y
    $win.lBox mark set insert 1.0
    $win.lBox see 1.0
    if {$args ne ""} {
        focus -force $win.lBox.t
    } else {
        focus -force $win.entryFind
    }
    # $win.lBox focus I001
    return true
}

proc ShowMessage {title msg} {
        set answer [
        tk_messageBox -message $title \
        -icon info -type ok -detail $msg
    ]
    switch $answer {
        ok {return}
    }
}

proc SetActiveProject {path} {
    global activeProject projman
    set activeProject $path
    set titleFolder [file tail $path]
    wm title . "ProjMan \($projman(Version)-$projman(Release)\) - $titleFolder"
    # set file [string range $fullPath [expr [string last "/" $fullPath]+1] end]
    # regsub -all "." $file "_" node
    # set dir [file dirname $fullPath]
    #     EditFile .frmBody.frmCat.noteBook.ffiles.frmTreeFiles.treeFiles $node $fullPath
    # debug_puts $fullPath
    # if ![info exists activeProject] {
        # set activeProject $fullPath
    # }
    .frmStatus.lblGitLogo configure -image git_logo_20x20
    .frmStatus.lblGit configure -text "[::msgcat::mc "Branch"]: [Git::Branches current]"
}
