######################################################
#                ProjMan 2
#        Distributed under GNU Public License
# Author: Sergey Kalinin svk@nuk-svk.ru
# Copyright (c) "SVK", 2022, https://nuk-svk.ru
######################################################
# Editor module
######################################################

namespace eval Editor {
    variable selectionTex
    # Set the editor option
    proc SetOption {optionName value} {
        global cfgVariables nbEditor
        # apply changes for opened tabs
        foreach node [$nbEditor tabs] {
            $node.frmText.t configure -$optionName $value
        }
    }
    
    # Comment one string or selected string
    proc Comment {txt fileType} {
        global lexers
        set selIndex [$txt tag ranges sel]
        set pos [$txt index insert]
        set lineNum [lindex [split $pos "."] 0]
        set PosNum [lindex [split $pos "."] 1]

        if [dict exists $lexers $fileType commentSymbol] {
            set symbol [dict get $lexers $fileType commentSymbol]
        } else {
            set symbol "#"
        }
        puts "Select : $selIndex"
        if {$selIndex != ""} {
            set lineBegin [lindex [split [lindex $selIndex 0] "."] 0]
            set lineEnd [lindex [split [lindex $selIndex 1] "."] 0]
            set posBegin [lindex [split [lindex $selIndex 1] "."] 0]
            set posEnd [lindex [split [lindex $selIndex 1] "."] 1]
            if {$lineEnd == $lineNum && $posEnd == 0} {
                set lineEnd [expr $lineEnd - 1]
            }
            for {set i $lineBegin} {$i <=$lineEnd} {incr i} {
                #$txt insert $i.0 "# "
                regexp -nocase -indices -- {^(\s*)(.*?)} [$txt get $i.0 $i.end] match v1 v2
                $txt insert  $i.[lindex [split $v2] 0] "$symbol "
            }
            $txt tag add comments $lineBegin.0 $lineEnd.end
            $txt tag raise comments
        } else {
            regexp -nocase -indices -- {^(\s*)(.*?)} [$txt get $lineNum.0 $lineNum.end] match v1 v2
            $txt insert  $lineNum.[lindex [split $v2] 0] "$symbol "
            $txt tag add comments $lineNum.0 $lineNum.end
            $txt tag raise comments
        }
    }

    # Uncomment one string selected strings
    proc Uncomment {txt fileType} {
        set selIndex [$txt tag ranges sel]
        set pos [$txt index insert]
        set lineNum [lindex [split $pos "."] 0]
        set posNum [lindex [split $pos "."] 1]
        
        if  {[info procs GetComment:$fileType] ne ""} {
            set commentProcedure "GetComment:$fileType"
        } else {
            set commentProcedure {GetComment:Unknown}
        }
        # set commentProcedure "GetComment"
        
        # puts "$fileType, $commentProcedure"
        if {$selIndex != ""} {
            set lineBegin [lindex [split [lindex $selIndex 0] "."] 0]
            set lineEnd [lindex [split [lindex $selIndex 1] "."] 0]
            set posBegin [lindex [split [lindex $selIndex 1] "."] 0]
            set posEnd [lindex [split [lindex $selIndex 1] "."] 1]
            if {$lineEnd == $lineNum && $posEnd == 0} {
                set lineEnd [expr $lineEnd - 1]
            }            
            for {set i $lineBegin} {$i <=$lineEnd} {incr i} {
                set str [$txt get $i.0 $i.end]
                set commentSymbolIndex [$commentProcedure $str]
                if {$commentSymbolIndex != 0} {
                    $txt delete $i.[lindex $commentSymbolIndex 0] $i.[lindex $commentSymbolIndex 1]
                }
            }
            $txt tag remove comments $lineBegin.0 $lineEnd.end
            $txt tag add	sel $lineBegin.0 $lineEnd.end
            $txt highlight $lineBegin.0 $lineEnd.end
        } else {
            set posNum [lindex [split $pos "."] 1]
            set str [$txt get $lineNum.0 $lineNum.end]
            set commentSymbolIndex [$commentProcedure $str]
            if {$commentSymbolIndex != 0} {
                $txt delete $lineNum.[lindex $commentSymbolIndex 0] $lineNum.[lindex $commentSymbolIndex 1]
            }
            $txt tag remove comments $lineNum.0 $lineNum.end
            $txt highlight $lineNum.0 $lineNum.end
        }
    }
    proc GetComment {fileType str} {
        global lexers
        puts [dict get $lexers $fileType commentSymbol]
        if {[dict exists $lexers $fileType commentSymbol] == 0} {
            return
        }
        
        if {[regexp -nocase -indices -- {(^| )([dict get $lexers $fileType commentSymbol]\s)(.+)} $str match v1 v2 v3]} {
            puts "$match, $v1, $v2, $v3"
            return [list [lindex [split $v2] 0] [lindex [split $v3] 0]]
        } else {
            return 0
        }
    }

    proc GetComment:TCL {str} {
        if {[regexp -nocase -indices -- {(^| )(#\s)(.+)} $str match v1 v2 v3]} {
            return [list [lindex [split $v2] 0] [lindex [split $v3] 0]]
        } else {
            return 0
        }
    }
    proc GetComment:GO {str} {
        # puts ">>>>>>>$str"
        if {[regexp -nocase -indices -- {(^| |\t)(//\s)(.+)} $str match v1 v2 v3]} {
            # puts ">>>> $match $v1 $v2 $v3"
            return [list [lindex [split $v2] 0] [lindex [split $v3] 0]]
        } else {
            return 0
        }
    }
    proc GetComment:Unknown	{str} {
        if {[regexp -nocase -indices -- {(^| )(#\s)(.+)} $str match v1 v2 v3]} {
            return [list [lindex [split $v2] 0] [lindex [split $v3] 0]]
        } else {
            return 0
        }
    }

    proc InsertTabular {txt} {
        global cfgVariables lexers editors
        set selIndex [$txt tag ranges sel]
        set pos [$txt index insert]
        set lineNum [lindex [split $pos "."] 0]
        set fileType [dict get $editors $txt fileType]
        if {[dict exists $lexers $fileType tabSize] != 0 } {
            set tabSize [dict get $lexers $fileType tabSize]
        } else {
            set tabSize $cfgVariables(tabSize)
        }
        # puts "Select : $selIndex"
        for {set i 0} {$i < $tabSize} { incr i} {
            append tabInsert " "
        }
        # puts ">$tabInsert<"
        if {$selIndex != ""} {
            set lineBegin [lindex [split [lindex $selIndex 0] "."] 0]
            set lineEnd [lindex [split [lindex $selIndex 1] "."] 0]
            set posBegin [lindex [split [lindex $selIndex 1] "."] 0]
            set posEnd [lindex [split [lindex $selIndex 1] "."] 1]
            # if {$lineBegin == $lineNum} {
                # set lineBegin [expr $lineBegin +	 1]
            # }
            if {$lineEnd == $lineNum || $posEnd == 0} {
                set lineEnd [expr $lineEnd - 1]
            }
            # puts "Pos: $pos, Begin: $lineBegin, End: $lineEnd"
            for {set i $lineBegin} {$i <=$lineEnd} {incr i} {
                #$txt insert $i.0 "# "
                regexp -nocase -indices -- {^(\s*)(.*?)} [$txt get $i.0 $i.end] match v1 v2
                $txt insert  $i.[lindex [split $v2] 0]  $tabInsert
            }
            $txt tag remove sel $lineBegin.$posBegin $lineEnd.$posEnd
            $txt tag add	sel $lineBegin.0 $lineEnd.end
            $txt highlight $lineBegin.0 $lineEnd.end            
        } else {
            # set pos [$txt index insert]
            # set lineNum [lindex [split $pos "."] 0]
            regexp -nocase -indices -- {^(\s*)(.*?)} [$txt get $lineNum.0 $lineNum.end] match v1 v2
            # puts "$v1<>$v2"
            $txt insert  $lineNum.[lindex [split $v2] 0] $tabInsert
        }
    }
    proc DeleteTabular {txt} {
        global cfgVariables lexers editors
        set selIndex [$txt tag ranges sel]
        set pos [$txt index insert]
        set fileType [dict get $editors $txt fileType]
        if {[dict exists $lexers $fileType tabSize] != 0 } {
            set tabSize [dict get $lexers $fileType tabSize]
        } else {
            set tabSize $cfgVariables(tabSize)
        }
        set lineNum [lindex [split $pos "."] 0]
        if {$selIndex != ""} {
            set lineBegin [lindex [split [lindex $selIndex 0] "."] 0]
            set lineEnd [lindex [split [lindex $selIndex 1] "."] 0]
            set posBegin [lindex [split [lindex $selIndex 1] "."] 0]
            set posEnd [lindex [split [lindex $selIndex 1] "."] 1]
            if {$lineEnd == $lineNum && $posEnd == 0} {
                set lineEnd [expr $lineEnd - 1]
            }
            for {set i $lineBegin} {$i <=$lineEnd} {incr i} {
                set str [$txt get $i.0 $i.end]
                if {[regexp -nocase -indices -- {(^\s*)(.*?)} $str match v1 v2]} {
                    set posBegin [lindex [split $v1] 0]
                    set posEnd [lindex [split $v1] 1]
                    if {[expr $posEnd + 1] >= $tabSize} {
                        $txt delete $i.$posBegin $i.$tabSize
                    }
                }
            }
            $txt tag remove sel $lineBegin.$posBegin $lineEnd.$posEnd
            $txt tag add	sel $lineBegin.0 $lineEnd.end
            $txt highlight $lineBegin.0 $lineEnd.end
        } else {
            set str [$txt get $lineNum.0 $lineNum.end]
            puts ">>>>> $str"
            if {[regexp -nocase -indices -- {(^\s*)(.*?)} $str match v1]} {
                    set posBegin [lindex [split $v1] 0]
                    set posEnd [lindex [split $v1] 1]
                    if {[expr $posEnd + 1] >= $tabSize} {
                        $txt delete $lineNum.$posBegin $lineNum.$tabSize
                    }
             }
        }
    }
    ## TABULAR INSERT (auto indent)##
    proc Indent {txt} {
        global cfgVariables lexers editors
        # set tabSize 4
        set fileType [dict get $editors $txt fileType]
        if {[dict exists $lexers $fileType tabSize] != 0 } {
            set tabSize [dict get $lexers $fileType tabSize]
        } else {
            set tabSize $cfgVariables(tabSize)
        }
        set indentSize $tabSize
        set pos [$txt index insert]
        set lineNum [lindex [split $pos "."] 0]
        set posNum [lindex [split $pos "."] 1]
        puts "$pos"
        if {$lineNum > 1} {
            # get current text
            set curText [$txt get $lineNum.0 "$lineNum.0 lineend"]
            #get text of prev line
            set prevLineNum [expr {$lineNum - 1}]
            set prevText [$txt get $prevLineNum.0 "$prevLineNum.0 lineend"]
            #count first spaces in current line
            set spaces ""
            regexp "^| *" $curText spaces
            #count first spaces in prev line
            set prevSpaces ""
            regexp "^( |\t)*" $prevText prevSpaces
            set len [string length $prevSpaces]
            set shouldBeSpaces 0
            for {set i 0} {$i < $len} {incr i} {
                if {[string index $prevSpaces $i] == "\t"} {
                    incr shouldBeSpaces $tabSize 
                } else  {
                    incr shouldBeSpaces
                }            
            }
            #see last symbol in the prev String.
            set lastSymbol [string index $prevText [expr {[string length $prevText] - 1}]]
            # is it open brace?
            if {$lastSymbol == ":" || $lastSymbol == "\\"} {
                incr shouldBeSpaces $indentSize
            }
            if {$lastSymbol == "\{"} {
                incr shouldBeSpaces $indentSize
            }
            set a ""
            regexp "^| *\}" $curText a
            if {$a != ""} {
                # make unindent
                if {$shouldBeSpaces >= $indentSize} {
                    set shouldBeSpaces [expr {$shouldBeSpaces - $indentSize}]
                }
            }
            if {$lastSymbol == "\["} {
                incr shouldBeSpaces $indentSize
            }
            set a ""
            regexp "^| *\]" $curText a
            if {$a != ""} {
                # make unindent
                if {$shouldBeSpaces >= $indentSize} {
                    set shouldBeSpaces [expr {$shouldBeSpaces - $indentSize}]
                }
            }
            if {$lastSymbol == "\("} {
                incr shouldBeSpaces $indentSize
            }
            set a ""
            regexp {^| *\)} $curText a
            if {$a != ""} {
                # make unindent
                if {$shouldBeSpaces >= $indentSize} {
                    set shouldBeSpaces [expr {$shouldBeSpaces - $indentSize}]
                }
            }
            set spaceNum [string length $spaces]
            if {$shouldBeSpaces > $spaceNum} {
                #insert spaces
                set deltaSpace [expr {$shouldBeSpaces - $spaceNum}]
                set incSpaces ""
                for {set i 0} {$i < $deltaSpace} {incr i} {
                    append incSpaces " "
                }
                $txt insert $lineNum.0 $incSpaces
            } elseif {$shouldBeSpaces < $spaceNum} {
                #delete spaces
                set deltaSpace [expr {$spaceNum - $shouldBeSpaces}]
                $txt delete $lineNum.0 $lineNum.$deltaSpace
            }
        }
    }
    proc SelectionPaste {txt} {
        set selBegin [lindex [$txt tag ranges sel] 0]
        set selEnd [lindex [$txt tag ranges sel] 1]
        if {$selBegin ne ""} {
            $txt delete $selBegin $selEnd
            $txt highlight $selBegin $selEnd
            #tk_textPaste $txt
        }
    }

    proc SelectionGet {txt} {
        variable selectionText
        set selBegin [lindex [$txt tag ranges sel] 0]
        set selEnd [lindex [$txt tag ranges sel] 1]
        if {$selBegin ne "" && $selEnd ne ""} {
            set selectionText [$txt get $selBegin $selEnd]
        }
    }
    
    proc SelectionHighlight {txt} {
        variable selectionText

        $txt tag remove lightSelected 1.0 end 

        set selBegin [lindex [$txt tag ranges sel] 0]
        set selEnd [lindex [$txt tag ranges sel] 1]
        if {$selBegin ne "" && $selEnd ne ""} {
            set selectionText [$txt get $selBegin $selEnd]
            # set selBeginRow [lindex [split $selBegin "."] 1]
            # set selEndRow [lindex [split $selEnd "."] 1]
            # puts "$selBegin, $selBeginRow; $selEnd, $selEndRow"
            # set symNumbers [expr $selEndRow - $selBeginRow]
            set symNumbers [expr [lindex [split $selEnd "."] 1] - [lindex [split $selBegin "."] 1]]
            # puts "Selection $selectionText"
            if [string match "-*" $selectionText] {
                set selectionText "\$selectionText"
            }
            set lstFindIndex [$txt search -all "$selectionText" 0.0]
            foreach ind $lstFindIndex {
                set selFindLine [lindex [split $ind "."] 0]
                set selFindRow [lindex [split $ind "."] 1]
                set endInd "$selFindLine.[expr $selFindRow + $symNumbers]"
                # puts "$ind;  $symNumbers; $selFindLine, $selFindRow; $endInd "
                $txt tag add lightSelected $ind $endInd 
            }
        }

    }
    proc VarHelperKey { widget K A } {
        set win .varhelper
        # if { [winfo exists $win] == 0 	} { return }
        set ind [$win.lBox curselection]
        
        switch -- $K {
            Prior   {
                set up   [expr [$win.lBox index active] - [$win.lBox cget -height]]
                if { $up < 0 } { set up 0 }
                $win.lBox activate $up
                $win.lBox selection clear 0 end
                $win.lBox selection set $up $up
            }
            Next    {
                set down [expr [$win.lBox index active] + [$win.lBox cget -height]]
                if { $down >= [$win.lBox index end] }  { set down end }
                $win.lBox activate $down
                $win.lBox selection clear 0 end
                $win.lBox selection set $down $down
            }
            Up      {
                set up   [expr [$win.lBox index active] - 1]
                if { $up < 0 } { set up 0 }
                $win.lBox activate $up
                $win.lBox selection clear 0 end
                $win.lBox selection set $up $up
            }
            Down    {
                set down [expr [$win.lBox index active] + 1]
                if { $down >= [$win.lBox index end] }  { set down end }
                $win.lBox activate $down
                $win.lBox selection clear 0 end
                $win.lBox selection set $down $down
            }
            Return  {
                $widget delete "insert - 1 chars wordstart" "insert wordend - 1 chars"
                $widget insert "insert" [$win.lBox get [$win.lBox curselection]]
                # eval [bind VarHelperBind <Escape>]
                Editor::VarHelperEscape $widget
            }
            default {
                $widget insert "insert" $A
                # eval [bind VarHelperBind <Escape>]
                Editor::VarHelperEscape $widget
            }
        }
    } ;# proc auto_completition_key
    proc VarHelperEscape {w} {
        puts "VarHelperEscape"
        bindtags $w.t [list [winfo parent $w.t] $w.t Text sysAfter all]
        bindtags $w [list [winfo toplevel $w] $w Ctext sysAfter all]
        catch { destroy .varhelper }
        puts [bindtags $w]
        puts [bind $w]
        puts [bindtags $w.t]
        puts [bind $w.t]
    }
    
    proc VarHelper {x y w word wordType} {
        global editors lexers variables
        variable txt 
        variable win
        # set txt $w.frmText.t
        # блокировка открытия диалога если запущен другой
        if [winfo exists .findVariables] {
           return
        }
        set txt $w
        set win .varhelper
        puts "$x $y $w $word $wordType"
        set fileType [dict get $editors $txt fileType]

        if {[dict exists $editors $txt variableList] != 0} {
            set varList [dict get $editors $txt variableList]
            # puts $varList
        }
        if {[dict exists $editors $txt procedureList] != 0} {
            set procList [dict get $editors $txt procedureList]
        }
        # puts $procList
        # puts ">>>>>>>[dict get $lexers $fileType commands]"
        if {[dict exists $lexers $fileType commands] !=0} {
            foreach i [dict get $lexers $fileType commands] {
                # puts $i
                lappend procList $i
            }
        }

        # if {[dict exists $editors $txt variableList] == 0 && [dict exists $editors $txt procedureList] == 0} {
            # return
        # }
        set findedVars ""
        switch -- $wordType {
            vars {
                foreach i [lsearch -nocase -all $varList $word*] {
                    # puts [lindex $varList $i]
                    set item [lindex [lindex $varList $i] 0]
                    # puts $item
                    if {[lsearch $findedVars $item] eq "-1"} {
                        lappend findedVars $item
                        # puts $item
                    }
                }
            }
            procedure {
                foreach i [lsearch -nocase -all $procList $word*] {
                    # puts [lindex $varList $i]
                    set item [lindex [lindex $procList $i] 0]
                    # puts $item
                    if {[lsearch $findedVars $item] eq "-1"} {
                        lappend findedVars $item
                        # puts $item
                    }
                }
            }
            default {
                foreach i [lsearch -nocase -all $varList $word*] {
                    # puts [lindex $varList $i]
                    set item [lindex [lindex $varList $i] 0]
                    # puts $item
                    if {[lsearch $findedVars $item] eq "-1"} {
                        lappend findedVars $item
                        # puts $item
                    }
                }
                foreach i [lsearch -nocase -all $procList $word*] {
                    # puts [lindex $varList $i]
                    set item [lindex [lindex $procList $i] 0]
                    # puts $item
                    if {[lsearch $findedVars $item] eq "-1"} {
                        lappend findedVars $item
                        # puts $item
                    }
                }
            }
        }
        # unset item
        # puts $findedVars
        bindtags $txt [list VarHelperBind [winfo toplevel $txt] $txt Ctext sysAfter all]
        # bindtags $txt.t [list VarHelperBind [winfo parent $txt.t] $txt.t Text sysAfter all]
        bind VarHelperBind <Escape> "Editor::VarHelperEscape $txt; break"
            # bindtags $txt.t {[list [winfo parent $txt.t] $txt.t Text sysAfter all]};
            # bindtags $txt {[list [winfo toplevel $txt] $txt Ctext sysAfter all]};
            # catch { destroy .varhelper }"
        bind VarHelperBind <Key> {Editor::VarHelperKey $Editor::txt %K %A; break}
        
        if { [winfo exists $win] } { destroy $win }
        if {$findedVars eq ""} {
            return
        }
        
        toplevel $win
        wm transient $win .
        wm overrideredirect $win 1
        
        listbox $win.lBox -width 30 -border 0
        pack $win.lBox -expand true -fill y -side left
        
        foreach { item } $findedVars {
            $win.lBox insert end $item
        }
        
        catch { $win.lBox activate 0 ; $win.lBox selection set 0 0 }
        
        if { [set height [llength $findedVars]] > 10 } { set height 10 }
        $win.lBox configure -height $height

        bind $win <Escape> {
            destroy $Editor::win
            focus -force $Editor::txt.t
            break
        }
        bind $win.lBox <Escape> {
            destroy $Editor::win
            focus -force $Editor::txt.t
            break
        }
        # bind $win.lBox <Return> {
            # set findString [dict get $lexers [dict get $editors $Editor::txt fileType] procFindString]
            # set values [.varhelper.lBox get [.varhelper.lBox curselection]]
            # regsub -all {PROCNAME} $findString $values str
            # Editor::FindFunction $Editor::txt "$str"
            # destroy .varhelper.lBox
            # # focus $Editor::txt.t
            # break
        # }

        # Определям расстояние до края экрана (основного окна) и если
        # оно меньше размера окна со списком то сдвигаем его вверх
        set winGeomY [winfo reqheight $win]
        set winGeomX [winfo reqwidth $win]

        set topHeight [winfo height .]
        set topWidth [winfo width .]
        set topLeftUpperX [winfo x .]
        set topLeftUpperY [winfo y .]
        set topRightLowerX [expr $topLeftUpperX + $topWidth]
        set topRightLowerY [expr $topLeftUpperY + $topHeight]
        
        if {[expr [expr $x + $winGeomX] > $topRightLowerX]} {
            set x [expr $x - $winGeomX]
        }
        if {[expr [expr $y + $winGeomY] > $topRightLowerY]} {
            set y [expr $y - $winGeomY]
        }

        wm geom $win +$x+$y
    }
    
    proc ReleaseKey {k txt fileType} {
        global cfgVariables lexers
        set pos [$txt index insert]
        set lineNum [lindex [split $pos "."] 0]
        set posNum [lindex [split $pos "."] 1]
        set box   [$txt bbox insert]
        set box_x [expr [lindex $box 0] + [winfo rootx $txt] ]
        set box_y [expr [lindex $box 1] + [winfo rooty $txt] + [lindex $box 3] ]
        SearchBrackets $txt
        set lpos [split $pos "."]
        set lblText "[::msgcat::mc "Row"]: [lindex $lpos 0], [::msgcat::mc "Column"]: [lindex $lpos 1]"
        .frmStatus.lblPosition configure -text $lblText
        unset lpos
        $txt tag remove lightSelected 1.0 end
        
        if { [winfo exists .varhelper] } { destroy .varhelper }
        puts $k
        switch $k {
            Return {
                regexp {^(\s*)} [$txt get [expr $lineNum - 1].0 [expr $lineNum - 1].end] -> spaceStart
		        # puts "$pos, $lineNum, $posNum, >$spaceStart<"
                $txt insert insert $spaceStart
                Editor::Indent $txt
            }
            Up {
                return
            }
            Down {
                return
            }
            Left {
                return
            }
            Right {
                return
            }
            # Shift_L {
                # return
            # }
            # Shift_R {
                # return
            # }
            Control_L {
                return
            }
            Control_R {
                return
            }
            Alt_L {
                return
            }
            Alt_R {
                return
            }
        }
        # set lineStart [$txt index "$pos linestart"]
        # puts "$pos $lineStart"
        if {$cfgVariables(variableHelper) eq "true"} {
            if {[dict exists $lexers $fileType variableSymbol] != 0} {
                set varSymbol [dict get $lexers $fileType variableSymbol]
                set lastSymbol [string last $varSymbol [$txt get $lineNum.0 $pos]]
                if {$lastSymbol ne "-1"} {
                    set word  [string trim [$txt get $lineNum.[expr $lastSymbol + 1] $pos]]
                    Editor::VarHelper $box_x $box_y $txt $word vars
                }
            } else {
                set ind [$txt search -backwards -regexp {\W} $pos {insert linestart}]
                if {$ind ne ""} {
                    set _ [split $ind "."]
                    set ind [lindex $_ 0].[expr [lindex $_ 1] + 1]
                    set word [$txt get $ind $pos]
                 } else {
                    # set ind [$txt search -backwards -regexp {^} $pos {insert linestart}]
                    set word [$txt get {insert linestart} $pos]
                }
                if {$word ne ""} {
                    Editor::VarHelper $box_x $box_y $txt $word {}
                }
            }
        }
        
        if {$cfgVariables(procedureHelper) eq "true"} {
            set ind [$txt search -backwards -regexp {\W} $pos {insert linestart}]
            if {$ind ne ""} {
                set _ [split $ind "."]
                set ind [lindex $_ 0].[expr [lindex $_ 1] + 1]
                set word [$txt get $ind $pos]
             } else {
                # set ind [$txt search -backwards -regexp {^} $pos {insert linestart}]
                set word [$txt get {insert linestart} $pos]
            }
            if {$word ne ""} {
                Editor::VarHelper $box_x $box_y $txt $word procedure
            }
        }
    }

    proc PressKey {k txt} {
        # puts [Editor::Key $k ""]
        switch $k {
            apostrophe {
               QuotSelection $txt {'}
            }
            quotedbl {
                QuotSelection $txt {"}
            }
            grave {
                QuotSelection $txt {`}
            }
            parenleft {
                # QuotSelection $txt {)}
            }
            bracketleft {
                # QuotSelection $txt {]}
            }
            braceleft {
                # {QuotSelection} $txt {\}}
            }
            parentright {
                if [string is space [$txt get {insert linestart} {insert - 1c}]] {
                    Editor::DeleteTabular $txt
                }
            }
            bracketright {
                if [string is space [$txt get {insert linestart} {insert - 1c}]] {
                    Editor::DeleteTabular $txt
                }
            }
            braceright {
                if [string is space [$txt get {insert linestart} {insert - 1c}]] {
                    Editor::DeleteTabular $txt
                }
            }
        }
    }
    ## GET KEYS CODE ##
    proc Key {key str} {
        puts "Pressed key code: $key, $str"
        if {$key >= 10 && $key <= 22} {return "true"}
        if {$key >= 24 && $key <= 36} {return "true"}
        if {$key >= 38 && $key <= 50} {return "true"}
        if {$key >= 51 && $key <= 61 && $key != 58} {return "true"}
        if {$key >= 79 && $key <= 91} {return "true"}
        if {$key == 63 || $key == 107 || $key == 108 || $key == 112} {return "true"}
    }
    proc TextCopy {txt} {
       # $txt tag remove sel 1.0 end
       $txt tag add sel {insert linestart} {insert lineend + 1char}
       tk_textCopy $txt
       $txt tag remove sel {insert linestart} {insert lineend + 1char}
       return
    }
    proc BindKeys {w txt fileType} {
        global cfgVariables
        #  variable txt
        # set txt $w.frmText.t
        bind $txt <KeyRelease> "catch {Editor::ReleaseKey %K $txt $fileType}"
        bind $txt <KeyPress> "Editor::PressKey %K $txt"
        bind $txt <Control-igrave> "Editor::SelectionPaste $txt"
        bind $txt <Control-v> "Editor::SelectionPaste $txt"
        bind $txt <Control-l> "SearchVariable $txt; break"
        bind $txt <Control-i> "ImageBase64Encode $txt"
        bind $txt <Control-bracketleft> "Editor::InsertTabular $txt"
        bind $txt <Control-bracketright> "Editor::DeleteTabular $txt"
        bind $txt <Control-comma> "Editor::Comment $txt $fileType"
        bind $txt <Control-period> "Editor::Uncomment $txt $fileType"
        bind $txt <Control-eacute> Find
        bind $txt <Insert> {OverWrite}
        bind $txt <ButtonRelease-1> "Editor::SearchBrackets $txt"
        bind $txt <Button-1><ButtonRelease-1> "Editor::SelectionHighlight $txt"
        bind $txt <<Modified>> "SetModifiedFlag $w"
        bind $txt <Control-i> ImageBase64Encode
        bind $txt <Control-u> "Editor::SearchBrackets %W"
        bind $txt <Control-J> "catch {Editor::GoToFunction $txt}"
        bind $txt <Control-j> "catch {Editor::GoToFunction $txt}; break"
        bind $txt <Alt-w>           "$txt delete {insert wordstart} {insert wordend}"
        bind $txt <Alt-odiaeresis>  "$txt delete {insert wordstart} {insert wordend}"
        bind $txt <Alt-r>           "$txt delete {insert linestart} {insert lineend + 1char}"
        bind $txt <Alt-ecircumflex> "$txt delete {insert linestart} {insert lineend + 1char}"
        bind $txt <Alt-b> "$txt delete {insert linestart} insert"
        bind $txt <Alt-e> "$txt delete insert {insert lineend}"
        bind $txt <Alt-s>           "Editor::SplitEditorH $w $fileType"
        bind $txt <Alt-ucircumflex> "Editor::SplitEditorH $w $fileType"
        bind $txt <Alt-y> "Editor::TextCopy $txt"
        bind $txt <Control-g> "Editor::GoToLineNumberDialog $txt"
        bind $txt <Control-agrave> "Editor::FindDialog $w"
        bind $txt <Control-f> "Editor::FindDialog $txt"
        bind $txt <Control-F> "Editor::FindDialog $txt"
        bind $txt <Control-odiaeresis> FileOper::Close
        bind $txt <Control-w> FileOper::Close
        bind $txt <Control-o> {
            set filePath [FileOper::OpenDialog]
            if {$filePath != ""} {
                FileOper::Edit $filePath
            }
            break
        }
        bind $txt <Control-O> {
            set filePath [FileOper::OpenDialog]
            if {$filePath != ""} {
                FileOper::Edit $filePath
            }
            break
        }
        # bind $txt.t <KeyRelease> "Editor::ReleaseKey %K $txt.t $fileType"
        # bind $txt.t <KeyPress> "Editor::PressKey %K $txt.t"
        # bind $txt <KeyRelease> "Editor::Key %k %K" 
        #$txt tag bind Sel  <Control-/> {puts ">>>>>>>>>>>>>>>>>>>"}
        #bind $txt <Control-slash> {puts "/////////////////"}
        #     #bind $txt <Control-g> GoToLine
        #     bind $txt <F3> {FindNext $w.text 1}
        #     bind $txt <Control-ecircumflex> ReplaceDialog
        #     bind $txt <Control-r> ReplaceDialog
        #     bind $txt <F4> {ReplaceCommand $w.text 1}
        #     bind $txt <Control-ucircumflex> {FileDialog [$noteBookFiles raise] save}
        #     bind $txt <Control-s> {FileDialog [$noteBookFiles raise] save}
        #     bind $txt <Control-ocircumflex> {FileDialog [$noteBookFiles raise] save_as}
        #     bind $txt <Shift-Control-s> {FileDialog [$noteBookFiles raise] save_as}
        #     bind $txt <Control-division> "tk_textCut $w.text;break"
        #     bind $txt <Control-x> "tk_textCut $w.text;break"
        #     bind $txt <Control-ntilde> "tk_textCopy $txt"
        #     bind $txt <Control-c> "tk_textCopy $txt"
        
        #bind $txt <Control-adiaeresis> "auto_completition $txt"
        # bind $txt <Control-icircumflex> ""
        # bind $txt <Control-j> ""
        #bind . <Control-m> PageTab
        #bind . <Control-udiaeresis> PageTab
        # bind <Button-1> [bind sysAfter <Any-Key>]
        # bind $txt <Button-3> {catch [PopupMenuEditor %X %Y]}
        # bind $txt <Button-4> "%W yview scroll -3 units"
        # bind $txt <Button-5> "%W yview scroll  3 units"
        #bind $txt <Shift-Button-4> "%W xview scroll -2 units"
        #bind $txt <Shift-Button-5> "%W xview scroll  2 units"
        # bind $txt <<Selection>> "Editor::SelectionHighlight $txt"
        # bind $txt <<Selection>> "Editor::SelectionGet $txt"
    }
    
    proc SearchBrackets {txt} {
        set i -1
        catch {
            switch -- [$txt get "insert - 1 chars"] {
                \{ {set i [Editor::_searchCloseBracket $txt \{ \} insert end]}
                \[ {set i [Editor::_searchCloseBracket $txt \[ \] insert end]}
                ( {set i [Editor::_searchCloseBracket $txt (   ) insert end]}
                \} {set i [Editor::_searchOpenBracket $txt \{ \} insert 1.0]}
                \] {set i [Editor::_searchOpenBracket $txt \[ \] insert 1.0]}
                ) {set i [Editor::_searchOpenBracket $txt (  ) insert 1.0]}
            } ;# switch
            catch { $txt tag remove lightBracket 1.0 end }
            if { $i != -1 } {
                # puts $i
                $txt tag add lightBracket "$i - 1 chars" $i
            };#if
        };#catch
    }
    
    proc QuotSelection {txt symbol} {
        variable selectionText
        set selIndex [$txt tag ranges sel]
        set pos [$txt index insert]
        set lineNum [lindex [split $pos "."] 0]
        set posNum [lindex [split $pos "."] 1]
        set symbol [string trim [string trimleft $symbol "\\"]]
        # puts "Selindex : $selIndex, cursor position: $pos"
        if {$selIndex != ""} {
            set lineBegin [lindex [split [lindex $selIndex 0] "."] 0]
            set posBegin [lindex [split [lindex $selIndex 0] "."] 1]
            set lineEnd [lindex [split [lindex $selIndex 1] "."] 0]
            set posEnd [lindex [split [lindex $selIndex 1] "."] 1]
            # set selText [$txt get $lineBegin.$posBegin $lineEnd.$posEnd]
            set selText $selectionText
            # puts "Selected text: $selText, pos: $pos, lineBegin: $lineBegin, posBegin: $posBegin, pos end: $posEnd"
            if {$posNum == $posEnd} {
                $txt insert $lineBegin.$posBegin "$symbol"
            }
            if {$posNum == $posBegin} {
                $txt insert $lineBegin.$posEnd "$symbol"
            }
            $txt highlight $lineBegin.$posBegin $lineEnd.end
            # $txt insert $lineBegin.[expr $posBegin + 1] "$symbol"
        } else {
            # $txt insert $lineNum.[expr $posNum + 1] "$symbol"
            # $txt mark set insert $lineNum.[expr $posNum - 1]
            # # $txt see $lineNum.[expr $posNum - 1]
            # $txt see insert
            # $txt highlight $lineNum.$posNum $lineNum.end
        }
    }
 
    # Create editor for new file (Ctrl+N)
    proc New {} {
        global nbEditor tree untitledNumber
        if [info exists untitledNumber] {
            incr untitledNumber 1
        } else {
            set untitledNumber 0
        }
        # set filePath untitled-$untitledNumber
        # set fileName untitled-$untitledNumber
        set fileFullPath untitled-$untitledNumber
        #puts [Tree::InsertItem $tree {} $fileFullPath "file" $fileName]
        set nbEditorItem [NB::InsertItem $nbEditor  $fileFullPath "file"]
        # puts "$nbEditorItem, $nbEditor"
        Editor $fileFullPath $nbEditor $nbEditorItem
        SetModifiedFlag $nbEditorItem
    }
    
    proc ReadStructure {txt treeItemName} {
        global tree nbEditor editors lexers
        set fileType [dict get $editors $txt fileType]
        set procList ""
        set varList ""
        set params ""
        if {[dict exists $lexers $fileType] == 0} {return}
        for {set lineNumber 0} {$lineNumber <= [$txt count -lines 0.0 end]} {incr lineNumber} {
            set line [$txt get $lineNumber.0 $lineNumber.end]
            # Выбираем процедуры (функции, классы и т.д.)
            if {[dict exists $lexers $fileType procRegexpCommand] != 0 } {
                if {[eval [dict get $lexers $fileType procRegexpCommand]]} {
                    set procName_ [string trim $procName]
                    if {$treeItemName ne ""} {
                        puts [Tree::InsertItem $tree $treeItemName $procName_  "procedure" "$procName_ ($params)"]
                    }
                    lappend procList [list $procName_ $params]
                    unset procName_
                }
            }
            # Выбираем переменные
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
                    puts "variable: $varName, value: $varValue, type: $varType"
                    lappend varList [list $varName $varValue]
                }
            }
        }
        dict set editors $txt procedureList $procList
        dict set editors $txt variableList $varList
    }
    
    proc FindFunction {txt findString} {
        set pos "0.0"
        $txt see $pos
        set line [lindex [split $pos "."] 0]
        set x [lindex [split $pos "."] 1]
        set pattern "$findString\\W"
        set pos [$txt search -nocase -regexp $pattern $line.$x end]
        $txt mark set insert $pos
        $txt see $pos
        set line [lindex [split $pos "."] 0]
        $txt tag remove sel 1.0 end
        $txt tag add sel $pos $line.end
        $txt tag raise sel
        focus -force $txt.t
        return 1
    }

    # "Alexander Dederer (aka Korwin)
    ## Search close bracket in editor widget
    proc _searchCloseBracket { widget o_bracket c_bracket start_pos end_pos } {
        # puts "_searchCloseBracket: $widget $o_bracket $c_bracket $start_pos $end_pos"
        set o_count 1
        set c_count 0
        set found 0
        set pattern "\[\\$o_bracket\\$c_bracket\]"
        set pos [$widget search -regexp -- $pattern $start_pos $end_pos]
        while { ! [string equal $pos {}] } {
            set char [$widget get $pos]
            #tk_messageBox -title $pattern -message "char: $char; $pos; o_count=$o_count; c_count=$c_count"
            if {[string equal $char $o_bracket]} {incr o_count ; set found 1}
            if {[string equal $char $c_bracket]} {incr c_count ; set found 1}
            if {($found == 1) && ($o_count == $c_count) } { return [$widget index "$pos + 1 chars"] }
            set found 0
            set start_pos "$pos + 1 chars"
            set pos [$widget search -regexp -- $pattern $start_pos $end_pos]
        } ;# while search
        
        return -1
    } ;# proc _searchCloseBracket
    
    # "Alexander Dederer (aka Korwin)
    ## Search open bracket in editor widget
    proc _searchOpenBracket { widget o_bracket c_bracket start_pos end_pos } {
        # puts "_searchOpenBracket: $widget $o_bracket $c_bracket $start_pos $end_pos"
        set o_count 0
        set c_count 1
        set found 0
        set pattern "\[\\$o_bracket\\$c_bracket\]"
        set pos [$widget search -backward -regexp -- $pattern "$start_pos - 1 chars" $end_pos]
        # puts "$pos"
        while { ! [string equal $pos {}] } {
            set char [$widget get $pos]
            # tk_messageBox -title $pattern -message "char: $char; $pos; o_count=$o_count; c_count=$c_count"
            if {[string equal $char $o_bracket]} {incr o_count ; set found 1}
            if {[string equal $char $c_bracket]} {incr c_count ; set found 1}
            if {($found == 1) && ($o_count == $c_count) } { return [$widget index "$pos + 1 chars"]}
            set found 0
            set start_pos "$pos - 0 chars"
            set pos [$widget search -backward -regexp -- $pattern $start_pos $end_pos]
        } ;# while search
        return -1
    }

    # ----------------------------------------------------------------------
    # Вызов диалога со списком процедур или функций присутствующих в тексте
    proc GoToFunction { w } {
        global tree editors
        puts $w
        # set txt $w.frmText.t
        set txt $w
        set box        [$txt bbox insert]
        set box_x      [expr [lindex $box 0] + [winfo rootx $txt] ]
        set box_y      [expr [lindex $box 1] + [winfo rooty $txt] + [lindex $box 3] ]
        set l ""
        # puts "--$txt"
        # puts $editors($txt)
        foreach item [dict get $editors $txt procedureList] {
            puts $item
            lappend l [lindex $item 0]
        }
        if {$l ne ""} {
            eval GotoFunctionDialog $w $box_x $box_y [lsort $l]
            focus .gotofunction.lBox
        }
    }

    #---------------------------------------------------------
    # Поиск по списку по первой букве
    # Richard Suchenwirth 2001-03-1
    # https://wiki.tcl-lang.org/page/Listbox+navigation+by+keyboard
    proc ListBoxSearch {w key} {
        if [regexp {[-A-Za-z0-9_]} $key] {
            set n 0   
            foreach i [$w get 0 end] {
                if [string match -nocase $key* $i] {
                    $w see $n
                    $w selection clear 0 end
                    $w selection set $n
                    $w activate $n
                    break
                } else {
                    incr n
                }
            }               
        }
    }
    # ------------------------------------------------------------------------
    # Диалоговое окно со списком процедур или функций в редактируемом тексте
    proc GotoFunctionDialog {w x y args} {
        global editors lexers
        variable txt 
        variable win
        # set txt $w.frmText.t
        set txt $w
        set win .gotofunction

        if { [winfo exists $win] } { destroy $win }
        toplevel $win
        wm transient $win .
        wm overrideredirect $win 1
        
        listbox $win.lBox -width 30 -border 2 -yscrollcommand "$win.yscroll set" -border 1
        ttk::scrollbar $win.yscroll -orient vertical -command  "$win.lBox yview"
        pack $win.lBox -expand true -fill y -side left
        pack $win.yscroll -side left -expand false -fill y
        
        foreach { word } $args {
            $win.lBox insert end $word
        }
        
        catch { $win.lBox activate 0 ; $win.lBox selection set 0 0 }
        
        if { [set height [llength $args]] > 10 } { set height 10 }
        $win.lBox configure -height $height

        bind $win <Escape> { 
            destroy $Editor::win
            focus -force $Editor::txt.t
            break
        }
        bind $win.lBox <Escape> {
            destroy $Editor::win
            focus -force $Editor::txt.t
            break
        }
        bind $win.lBox <Return> {
            set findString [dict get $lexers [dict get $editors $Editor::txt fileType] procFindString]
            set values [.gotofunction.lBox get [.gotofunction.lBox curselection]]
            regsub -all {PROCNAME} $findString $values str
            Editor::FindFunction $Editor::txt "$str"
            destroy .gotofunction
            $Editor::txt tag remove sel 1.0 end
            # focus $Editor::txt.t
            break
        }
        bind $win.lBox <Any-Key> {Editor::ListBoxSearch %W %A}
        # Определям расстояние до края экрана (основного окна) и если
        # оно меньше размера окна со списком то сдвигаем его вверх
        set winGeom [winfo reqheight $win]
        set topHeight [winfo height .]
        # puts "$x, $y, $winGeom, $topHeight"
        if [expr [expr $topHeight - $y] < $winGeom] {
            set y [expr $topHeight - $winGeom]
        }
        wm geom $win +$x+$y
    }
    
    proc FindReplaceText {txt findString replaceString regexp} {
        global nbEditor
        puts [focus]
        # set txt [$nbEditor select].frmText.t
        $txt tag remove sel 1.0 end
        # $txt see $pos
        # set pos [$txt search -nocase $findString $line.$x end]
        set options ""
        # $txt see 1.0
        set pos [$txt index insert]
        set allLines [$txt count -lines 1.0 end]
        # puts "$pos $allLines"
        set line [lindex [split $pos "."] 0]

        if [expr $line == $allLines] {
            set pos "0.0"
            set line [lindex [split $pos "."] 0]
        }
        set x [lindex [split $pos "."] 1]
        # incr x $incr 

        # puts "$findString -> $replaceString, $regexp, $pos, $line.$x"
        set matchIndexPair ""
        if {$regexp eq "-regexp"} {
            # puts "$txt search -all -nocase -regexp {$findString} $line.$x end"
            set lstFindIndex [$txt search -all -nocase -regexp -count matchIndexPair "$findString" $line.$x end]
        } else {
            # puts "$txt search -all -nocase {$findString} $line.$x end"
            set lstFindIndex [$txt search -all -nocase -count matchIndexPair $findString $line.$x end]
            # set symNumbers [string length "$findString"]
        }
        # puts $lstFindIndex
        # puts $matchIndexPair
        # set lstFindIndex [$txt search -all "$selectionText" 0.0]
        set i 0
        foreach ind $lstFindIndex {
            set selFindLine [lindex [split $ind "."] 0]
            set selFindRow [lindex [split $ind "."] 1]
            # set endInd "$selFindLine.[expr $selFindRow + $symNumbers]"
            set endInd "$selFindLine.[expr [lindex $matchIndexPair $i] + $selFindRow]"
            # puts "$ind; $selFindLine, $selFindRow; $endInd "
            if {$replaceString ne ""} {
                $txt replace $ind $endInd $replaceString
            }
            $txt tag add sel $ind $endInd
            incr i
        }
        .finddialog.lblCounter configure -text "[::msgcat::mc "Finded"]: $i"
        
        # set pos [$txt search $options $findString $pos end]

        
        # $txt mark set insert $pos
        if {[lindex $lstFindIndex 0] ne "" } {
            # $txt see [lindex $lstFindIndex 0]
            $txt mark set insert [lindex $lstFindIndex 0]
            $txt see insert
        }
        # puts $pos
        # # highlight the found word
        # set line [lindex [split $pos "."] 0]
        # set x [lindex [split $pos "."] 1]
        # set x [expr {$x + [string length $findString]}]
        # $txt tag remove sel 1.0 end
        # $txt tag add sel $pos $line.end
        # #$text tag configure sel -background $editor(selectbg) -foreground $editor(fg)
        $txt tag raise sel
        # # focus -force $txt.t
        # # Position
        # return 1
    }

    # Find and replace text dialog
    proc FindDialog {w} {
        global editors lexers nbEditor regexpSet
        variable txt 
        variable win
        variable show
        set findString ""
        set replaceString ""

        if {$w ne ""} {
            set txt $w
        } else {
            if {[$nbEditor select] ne ""} {
                set txt [$nbEditor select].frmText.t
                puts $txt
            } else {
                return
            }
        }
        # set txt $w.frmText.t
        set win .finddialog
        set regexpSet ""
        set searchAll "-all"
        
        if { [winfo exists $win] }  { destroy $win }
        toplevel $win
        wm transient $win .
        wm overrideredirect $win 1
        
        ttk::entry $win.entryFind -width 30 -textvariable findString
        ttk::entry $win.entryReplace -width 30 -textvariable replaceString
        
        set show($win.entryReplace) false
        
        
        ttk::button $win.bForward -image forward_20x20 -command  {
            Editor::FindReplaceText $Editor::txt "$findString" "" $regexpSet
        }
        ttk::button $win.bBackward -state disable -image backward_20x20 -command "puts $replaceString"
        ttk::button $win.bDone -image done_20x20 -state disable -command {
            puts "$findString -> $replaceString, $regexpSet"
        }
        ttk::button $win.bDoneAll -image doneall_20x20 -command {
            Editor::FindReplaceText $Editor::txt "$findString" "$replaceString" $regexpSet
        }
        ttk::button $win.bReplace -image replace_20x20 \
            -command {
                # puts $Editor::show($Editor::win.entryReplace)
                if {$Editor::show($Editor::win.entryReplace) eq "false"} {
                    grid $Editor::win.entryReplace -row 1 -column 0 -columnspan 3 -sticky nsew
                    grid $Editor::win.bDone -row 1 -column 3 -sticky e
                    grid $Editor::win.bDoneAll -row 1 -column 4 -sticky e
                    set Editor::show($Editor::win.entryReplace) "true"
                } else {
                    grid remove $Editor::win.entryReplace $Editor::win.bDone $Editor::win.bDoneAll
                    set Editor::show($Editor::win.entryReplace) "false"
                }
            }
        ttk::checkbutton $win.chkRegexp -text "Regexp" \
            -variable regexpSet -onvalue "-regexp" -offvalue ""
        ttk::checkbutton $win.chkAll -text "All" -state disable\
            -variable searchAll -onvalue "-all" -offvalue ""
        ttk::label $win.lblCounter -justify right -anchor e -text ""
        
        grid $win.entryFind -row 0 -column 0  -columnspan 3 -sticky nsew
        grid $win.bForward -row 0 -column 3 -sticky e
        grid $win.bBackward -row 0 -column 4 -sticky e
        grid $win.bReplace -row 0 -column 5 -sticky e
        grid $win.chkRegexp -row 2 -column 0 -sticky w
        # grid $win.chkAll -row 2 -column 1  -sticky w
        grid $win.lblCounter -row 2 -column 2 -sticky we

        # set reqWidth [winfo reqwidth $win]
        set boxX [expr [winfo rootx $txt] + [expr [winfo width $nbEditor] - 350]]
        set boxY [expr [winfo rooty $txt] + 10]

        bind $win <Escape> { 
            destroy $Editor::win
            focus -force $Editor::txt.t
            break
        }
        bind $win.entryFind <Escape> {
            destroy $Editor::win
            focus -force $Editor::txt.t
            break
        }
        bind $win.entryFind <Return> {
            Editor::FindReplaceText $Editor::txt "$findString" "" $regexpSet
            break
        }
        bind $win.entryReplace <Return> {
            Editor::FindReplaceText $Editor::txt "$findString" "$replaceString" $regexpSet
            break
        }

        wm geom $win +$boxX+$boxY
        focus -force $win.entryFind
    }

    # Horizontal split the Editor text widget
    proc SplitEditorH {w fileType} {
        global cfgVariables
        puts [$w.panelTxt panes]
        if [winfo exists $w.frmText2] {
            $w.panelTxt forget $w.frmText2
            destroy $w.frmText2
            focus -force $w.frmText.t.t
            return
        }
        set frmText [Editor::EditorWidget $w $fileType]
        $frmText.t insert end [$w.frmText.t get 0.0 end]

        # $w.panelTxt add $w.frmText -weight 0  
        $w.panelTxt add $frmText -weight 1

        $frmText.t see [$w.frmText.t index insert]
        ReadStructure $frmText.t ""
        focus -force $frmText.t.t
    }

    proc SplitEditorV {w fileType} {
        global cfgVariables
        .frmBody.panel add $frmTree -weight 0

        puts [$w.panelTxt panes]
        if [winfo exists $w.frmText2] {
            $w.panelTxt forget $w.frmText2
            destroy $w.frmText2
            return
        }
        set frmText [Editor::EditorWidget $w $fileType]
        $frmText.t insert end [$w.frmText.t get 0.0 end]

        # $w.panelTxt add $w.frmText -weight 0  
        $w.panelTxt add $frmText -weight 1

        $frmText.t see [$w.frmText.t index insert]
        # $frmText.t mark set insert [$w.frmText.t index insert]
    }
    
    proc GoToLineNumber {text lineNumber} {
        # puts "\n\n\t>>>>$text $lineNumber\n\n"
        $text mark set insert $lineNumber.0
        $text see insert
    }
    
    proc GoToLineNumberDialog {w} {
        global editors lexers
        variable txt 
        variable win
        # set txt $w.frmText.t
        set txt $w
        set win .gotoline
        set box [$txt bbox insert]
        set x   [expr [lindex $box 0] + [winfo rootx $txt] ]
        set y   [expr [lindex $box 1] + [winfo rooty $txt] + [lindex $box 3] ]
    
        if { [winfo exists $win] } { destroy $win }
        toplevel $win
        wm transient $win .
        wm overrideredirect $win 1
        
        ttk::entry $win.ent
        pack $win.ent -expand true -fill y -side left -padx 3 -pady 3

        bind $win <Escape> { 
            destroy $Editor::win
            focus -force $Editor::txt.t
            break
        }
        bind $win.ent <Escape> {
            destroy $Editor::win
            focus -force $Editor::txt.t
            break
        }
        bind $win.ent <Return> {
            set lineNumber [.gotoline.ent get]
            # $txt see insert $lineNumber
            puts $Editor::txt
            $Editor::txt mark set insert $lineNumber.0
            $Editor::txt see insert
            focus $Editor::txt.t
            destroy .gotoline
            break
        }
        # Определям расстояние до края экрана (основного окна) и если
        # оно меньше размера окна со списком то сдвигаем его вверх
        set winGeom [winfo reqheight $win]
        set topHeight [winfo height .]
        # puts "$x, $y, $winGeom, $topHeight"
        if [expr [expr $topHeight - $y] < $winGeom] {
            set y [expr $topHeight - $winGeom]
        }
        wm geom $win +$x+$y
        focus $win.ent
    }    

    proc EditorWidget {fr fileType} {
        global cfgVariables editors
        
        if [winfo exists $fr.frmText] {
            set frmText [ttk::frame $fr.frmText2 -border 1]
        } else {
            set frmText [ttk::frame $fr.frmText -border 1]
        }
        set txt $frmText.t
        
        # set frmText [ttk::frame $fr.frmText -border 1]
        # set txt $frmText.t
     
        pack $frmText  -side top -expand true -fill both
        
        pack [ttk::scrollbar $frmText.v -command "$frmText.t yview"] -side right -fill y
        ttk::scrollbar $frmText.h -orient horizontal -command "$frmText.t xview"
        ctext $txt -xscrollcommand "$frmText.h set" -yscrollcommand "$frmText.v set" \
            -font $cfgVariables(font) -relief flat -wrap $cfgVariables(editorWrap) \
            -linemapfg $cfgVariables(lineNumberFG) -linemapbg $cfgVariables(lineNumberBG) \
            -tabs "[expr {4 * [font measure $cfgVariables(font) 0]}] left" -tabstyle tabular -undo true
            
        pack $txt -fill both -expand 1
        if {$cfgVariables(editorWrap) eq "none"} {
            pack $frmText.h -side bottom -fill x
        }
        # puts ">>>>>>> [bindtags $txt]"
        if {$cfgVariables(lineNumberShow) eq "false"} {
            $txt configure -linemap 0
        }
        $txt tag configure lightBracket -background $cfgVariables(selectLightBg) -foreground #00ffff
        $txt tag configure lightSelected -background $cfgVariables(selectLightBg) -foreground #00ffff
        
        # puts ">$fileType<"
        # puts [info procs Highlight::GO]
        dict set editors $txt fileType $fileType
        dict set editors $txt procedureList [list]
        
        puts ">>[dict get $editors $txt fileType]"
        puts ">>[dict get $editors $txt procedureList]"
		# puts ">>>>> $editors"
        
        if {[info procs ::Highlight::$fileType] ne ""} {
            Highlight::$fileType $txt
        } else {
            Highlight::Default $txt
        }
        BindKeys $fr $txt $fileType        
        return $frmText
    }

    proc Editor {fileFullPath nb itemName} {
        global cfgVariables editors
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
        }
        set fr $itemName
        if ![string match "*untitled*" $itemName] {
             set lblText $fileFullPath
        } else {
             set lblText ""

        }
        set fileType [string toupper [string trimleft [file extension $fileFullPath] "."]]
        if {$fileType eq ""} {set fileType "Unknown"}
        
        ttk::frame $fr.header
        set lblName "lbl[string range $itemName [expr [string last "." $itemName] +1] end]"
        ttk::label $fr.header.$lblName -text $lblText
        # pack $fr.$lblName  -side top  -anchor w -fill x
        
        set btnSplitV "btnSplitV[string range $itemName [expr [string last "." $itemName] +1] end]"
        set btnSplitH "btnSplitH[string range $itemName [expr [string last "." $itemName] +1] end]"
        ttk::button $fr.header.$btnSplitH -image split_horizontal_11x11 \
            -command "Editor::SplitEditorH $fr $fileType"
        ttk::button $fr.header.$btnSplitV -image split_vertical_11x11 \
            -command "Editor::SplitEditorV $fr $fileType" -state disable
        # pack $fr.$btnSplitH $fr.$btnSplitV  -side right  -anchor e
        pack $fr.header.$lblName -side left -expand true -fill x
        pack $fr.header.$btnSplitV $fr.header.$btnSplitH -side right
        
        pack $fr.header -side top -fill x
        
        ttk::panedwindow $fr.panelTxt -orient vertical -style TPanedwindow
        pack propagate $fr.panelTxt false 
        pack $fr.panelTxt -side top -fill both -expand true

        if {[lsearch -exact $imageType $fileType] != -1} {
            ImageViewer $fileFullPath $itemName $fr
        } else {
            set frmText [Editor::EditorWidget $fr $fileType]
        }
        $fr.panelTxt add $frmText -weight 0

        return $fr
    }
}
