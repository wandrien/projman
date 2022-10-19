######################################################
#                ProjMan 2
#        Distributed under GNU Public License
# Author: Sergey Kalinin svk@nuk-svk.ru
# Copyright (c) "SVK", 2022, https://nuk-svk.ru
######################################################
# Git module
# usage a system git command
#######################################################


namespace eval Git {
    variable gitCommand
    
    proc GetConfig {} {
        global activeProject
        set confOptions {
            remote.origin.url
            user.user
            user.email
            init.defaultbranch
            branch.master.remote
        }
    }

    proc Branches {opt} {
        global cfgVariables activeProject
        set cmd exec
        set d [pwd]
        if {$activeProject ne ""} {
            cd $activeProject
        }
        lappend cmd $cfgVariables(gitCommand)
        lappend cmd "branch"
        # lappend cmd "-s"
        # lappend cmd "--"
        # lappend cmd $activeProject
        switch $opt {
            current {
                lappend cmd "--show-current"
            }
            list {
                lappend cmd "-l"
            }
        }
        catch $cmd pipe
        if [regexp -nocase -- {^fatal:} $pipe match] {
            return 
        }
        foreach line [split $pipe "\n"] {
            lappend res $line
        }
        cd $d
        if [info exists res] {
            return $res
        }
    }
    
    proc Status {} {
        global cfgVariables activeProject
        set cmd exec
        lappend cmd $cfgVariables(gitCommand)
        lappend cmd "status"
        lappend cmd "-s"
        lappend cmd "--"
        lappend cmd $activeProject
        catch $cmd pipe
        if [regexp -nocase -- {^fatal:} $pipe match] {
            return 
        }
        foreach line [split $pipe "\n"] {
            lappend res $line
        }
        if [info exists res] {
            return $res
        }
    }
    
    proc Diff {f} {
        global cfgVariables activeProject
        set cmd exec
        lappend cmd $cfgVariables(gitCommand)
        lappend cmd "diff"
        lappend cmd "--"
        lappend cmd [file join $activeProject [string trimleft $f "../"]]
        catch $cmd pipe
        puts $cmd
        if [regexp -nocase -- {^fatal:} $pipe match] {
            return 
        }
        foreach line [split $pipe "\n"] {
            lappend res $line
        }
        return $res
    }
    
    proc Commit {w} {
        global cfgVariables activeProject
        set txt [string trim [$w get 0.0 end]]
        puts $txt
        set cmd exec
        append cmd " $cfgVariables(gitCommand)"
        append cmd " commit"
        append cmd " -m"
        append cmd " \"$txt\""
        append cmd " --"
        append cmd " $activeProject"
        if {$txt eq ""} {
            set answer [tk_messageBox -message [::msgcat::mc "Empty commit description"] \
                -icon info -type ok \
                -detail [::msgcat::mc "You must enter a commit description"]]
            switch $answer {
                ok {return "cancel"}
            }
        } else {
            puts $cmd
            catch $cmd pipe
            puts $pipe
            if [regexp -nocase -- {^fatal:} $pipe match] {
                return 
            }
            foreach line [split $pipe "\n"] {
                lappend res $line
            }
            return $res
        }
    }
    
    proc Pull {} {
        global cfgVariables activeProject
    }
    
    proc Push {} {
        global cfgVariables activeProject
    }
    
    proc Merge {} {
        global cfgVariables activeProject
    }
    
    proc ListBoxPress {w} {
        set fileName [$w.body.lBox get [$w.body.lBox curselection]]
        # puts $values
        $w.body.t delete 1.0 end
        set i 0
        foreach line [Git::Diff $fileName] {
            puts $line
            if {$i > 3} {
                $w.body.t inser end "$line\n"
            }
            incr i
        }
        $w.body.t highlight 1.0 end
    }
    proc CommitAdd {w} {
        global activeProject cfgVariables
        set fileName [$w.body.lBox get [$w.body.lBox curselection]]
        # puts $values
        set cmd exec
        lappend cmd $cfgVariables(gitCommand)
        lappend cmd "add"
        lappend cmd [file join $activeProject $fileName]
        catch $cmd pipe
        puts $cmd
        $w.body.lCommit insert end $fileName
        $w.body.lBox delete [$w.body.lBox curselection]
    }
    proc Key {k fr} {
        # puts [Editor::Key $k]
        switch $k {
            Up {
               Git::ListBoxPress $fr
            }
            Down {
                Git::ListBoxPress $fr
            }
        }
    }
    proc Dialog {} {
        global cfgVariables activeProject nbEditor
        variable fr
        if [winfo exists $nbEditor.git_browse] {
            $nbEditor select $nbEditor.git_browse
            return
        }
        set fr [NB::InsertItem $nbEditor git_browse "git"]
        ttk::frame $fr.header
        set lblName "lblGit"
        set lblText "$activeProject | [::msgcat::mc "Branch"]: [Git::Branches current]"
        ttk::label $fr.header.$lblName -text $lblText -justify right
        pack $fr.header.$lblName -side right -expand true -fill x
        pack $fr.header -side top -fill x

        ttk::frame $fr.body
        pack $fr.body -side top -expand true -fill both
        
    		set lstFiles [listbox $fr.body.lBox -width 30 -border 0 -yscrollcommand "$fr.body.yscroll set" -border 1]
        ttk::scrollbar $fr.body.yscroll -orient vertical -command  "$fr.body.lBox yview"
        # pack $fr.body.lBox -expand true -fill y -side left
        # pack $fr.body.yscroll -side left -expand false -fill y

        set txt $fr.body.t
        # set txt $frmText.t
        
        # pack [ttk::scrollbar $fr.body.v -command "$fr.body.t yview"] -side right -fill y
        ttk::scrollbar $fr.body.v -command "$fr.body.t yview"
        ttk::scrollbar $fr.body.h -orient horizontal -command "$fr.body.t xview"
        ctext $txt -xscrollcommand "$fr.body.h set" -yscrollcommand "$fr.body.v set" \
            -font $cfgVariables(font) -relief flat -wrap none -linemap 0 \
            -tabs "[expr {4 * [font measure $cfgVariables(font) 0]}] left" -tabstyle tabular -undo true
        
        ttk::button $fr.body.bAdd -image forward_20x20 -command "Git::CommitAdd $fr"
        ttk::button $fr.body.bRemove -state disable -image backward_20x20
        ttk::button $fr.body.bCommit -image done_20x20  -compound left -text "[::msgcat::mc "Commit changes"]" \
            -command "Git::Commit $fr.body.tCommit"
        ttk::button $fr.body.bDone -image doneall_20x20 -compound left -text "[::msgcat::mc "Push changes"]" \
            -command Git::Push

    		set lstFilesCommit [listbox $fr.body.lCommit -width 30 -border 0 -yscrollcommand "$fr.body.yscroll2 set" -border 1]
        ttk::scrollbar $fr.body.yscroll2 -orient vertical -command  "$fr.body.lCommit yview"

        ttk::label $fr.body.lblCommitText -text "[::msgcat::mc "Commit description"]"
        ttk::scrollbar $fr.body.vCommit -command "$fr.body.tCommit yview"
        ttk::scrollbar $fr.body.hCommit -orient horizontal -command "$fr.body.tCommit xview"
        ctext $fr.body.tCommit -xscrollcommand "$fr.body.hCommit set" -yscrollcommand "$fr.body.vCommit set" \
            -font $cfgVariables(font) -relief flat -wrap none -linemap 0 \
            -tabs "[expr {4 * [font measure $cfgVariables(font) 0]}] left" -tabstyle tabular -undo true

        # pack $txt -fill both -expand 1
        # pack $fr.body.h -side bottom -fill x
        grid $lstFiles -column 0 -row 0 -sticky nsew -columnspan 3 -rowspan 2
        grid $fr.body.yscroll -column 3 -row 0 -sticky nsw -rowspan 2
        grid $txt -column	 4 -row 0 -sticky nsew -columnspan 2
        grid $fr.body.v -column 5 -row 0 -sticky nsew
        grid $fr.body.h -column 4 -row 1 -columnspan 3 -sticky nsew
        grid rowconfigure $fr.body $fr.body.t -weight 1
        grid columnconfigure $fr.body $fr.body.t -weight 1

        grid $fr.body.bAdd -column 0 -row 3 -sticky nsew
        grid $fr.body.bRemove -column 1 -row 3 -sticky nsew
        grid $fr.body.lCommit -column 0 -row 4 -columnspan 3 -rowspan 3 -sticky nsew
        grid $fr.body.lblCommitText -column 4 -row 3 -sticky nsew -columnspan 2
        grid $fr.body.tCommit -column 4 -row 4 -sticky nsew -columnspan 2
        grid $fr.body.vCommit -column 6 -row 4 -sticky nsew
        grid $fr.body.hCommit -column 4 -row 5 -columnspan 3 -sticky nsew
        grid $fr.body.bCommit -column 4 -row 6 -sticky nsew
        grid $fr.body.bDone -column 5 -row 6 -sticky nsew

        foreach { word } [Git::Status] {
            puts $word
            if [regexp -nocase -- {([\w\s])([\s\w?]+)\s../(.+?)} $word match v1 v2 fileName] {
                # puts "$v1 $v2 $fileName"
                # $fr.body.t delete 1.0 end
                if {$v1 ne " "} {
                    $fr.body.lCommit insert end $fileName
                }
                if {$v2 ne " "} {
                    $fr.body.lBox insert end $fileName
                }
            }
        }        
        
        catch { $fr.body.lBox activate 0 ; $fr.body.lBox selection set 0 0 }
        
        bind $fr.body.lBox <Return> "Git::CommitAdd $fr"
        bind $fr.body.lBox <Double-Button-1> "Git::CommitAdd $fr"
        bind $fr.body.lBox <Button-1><ButtonRelease-1> "Git::ListBoxPress $fr"
        bind $fr.body.lBox <KeyRelease> "Git::Key %K $fr"
        
        focus -force $fr.body.lBox
        catch {
            $fr.body.lBox activate 0
            $fr.body.lBox selection set 0 0
            Git::ListBoxPress $fr
        }
        
        ctext::addHighlightClassForRegexp $txt paths #19a2a6 {@@.+@@}
        ctext::addHighlightClassForRegexp $txt add green {^\+.*$}
        ctext::addHighlightClassForRegexp $txt gremove grey {^\-.*$}
        $txt highlight 1.0 end
    }
}
