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

proc ViewFilesTree {} {
    global cfgVariables
    if {$cfgVariables(filesPanelShow) eq "true"} {
        .frmBody.panel forget .frmBody.frmTree
        set cfgVariables(filesPanelShow) false
    } else {
        switch $cfgVariables(filesPanelPlace) {
        "left" {        
                .frmBody.panel insert 0 .frmBody.frmTree
            }
            "right" {
                .frmBody.panel add .frmBody.frmTree
            }
            default {
                .frmBody.panel insert 0 .frmBody.frmTree
            }
        }
        set cfgVariables(filesPanelShow) true
    }
}

# Enable/Disabled line numbers in editor
proc ViewLineNumbers {} {
    global cfgVariables nbEditor
    # Changed global settigs
    if {$cfgVariables(lineNumberShow) eq "true"} {
        set cfgVariables(lineNumberShow) false
    } else {
        set cfgVariables(lineNumberShow) true
    }
    # apply changes for opened tabs
    foreach node [$nbEditor tabs] {
        $node.frmText.t configure -linemap $cfgVariables(lineNumberShow)
    }
}

proc Del {} {
    return
}

proc YScrollCommand {txt canv} {
    $txt yview
    $canv yview"
}

proc ResetModifiedFlag {w} {
    global modified nbEditor
    $w.frmText.t edit modified false
    set modified($w) "false"
    set lbl [string trimleft [$nbEditor tab $w -text] "* "]
    puts "ResetModifiedFlag: $lbl"
    $nbEditor tab $w -text $lbl
}
proc SetModifiedFlag {w} {
    global modified nbEditor
    #$w.frmText.t edit modified false
    set modified($w) "true"
    set lbl [$nbEditor tab $w -text]
    puts "SetModifiedFlag: $w; $modified($w); >$lbl<"
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
    foreach img [image names] {
        if [regexp -nocase -all -- "^($ext)(_)" $img match v1 v2] {
            # puts "\nFindinig images: $img \n"
            return $img
        }
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
    puts ">>>$varName<<<"
    if {[info exists project] == 0} {return}
    foreach f [array names project] {
        puts "--$f"
        puts "----"
        foreach a $project($f) {
            puts "-----$variables($a)"
            foreach b $variables($a) {
                puts "------$b -- [lindex $b 0]"
                if {$varName eq [lindex $b 0]} {
                    puts "УРААААААА $varName = $b в файле $a \n\t [lindex $b 0]"
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
            puts "[lindex $lst 0] -[lindex $lst 1] -[lindex $lst 2]"
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
        # puts "- $id - $values - $key"
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
    # puts "$x, $y, $winGeom, $topHeight"
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
        puts "$cfgVariables(searchCommand) $cfgVariables(searchCommandOptions) $str $activeProject"
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
        # puts $cmd
        catch $cmd pipe
        # puts $pipe
        # fileevent $pipe readable
        # fconfigure $pipe -buffering none -blocking no
    }
    # while {[chan gets $pipe line] >= 0} {
        # puts "--> $line"
    # }
    foreach line [split $pipe "\n"] {
        if [regexp -nocase -all -line -- {^((\/[\w\-_\.\s]+)+):([0-9]+):\s*(.+?)} $line match fullPath fileName lineNumber fullString] {
            # puts "$fullPath $fileName $lineNumber $fullString"
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
    # puts $lst
    foreach { word } $lst {
        foreach lst $word {
            # set l [split $lst " "]
            # puts "[lindex $lst 0] -[lindex $lst 1] -[lindex $lst 2]"
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

    # puts $txt
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
        
    if { [winfo exists $win] }  { destroy $win }
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
    grid $win.bForward -row 0 -column 1 -sticky e
    grid $win.bDoneAll -row 1 -column 1 -sticky e
    # grid $win.chkRegexp -row 2 -column 0 -sticky w
    # grid $win.chkAll -row 2 -column 1  -sticky w
    grid $win.lblCounter -row 2 -column 0 -columnspan 2 -sticky we
        
    grid $win.lBox -row 3 -column 0 -columnspan 2 -sticky nsew
    grid $win.v -row 3 -column 2 -sticky nsew
    grid $win.h -row 4 -column 0 -sticky nsew
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
        # puts "$lineNum $path"
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
        # puts "$lineNum $path"
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
    # puts "$x, $y, $winGeom, $topHeight"
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
}
