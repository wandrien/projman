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

    proc Reflog {} {
        global cfgVariables activeProject
        set cmd exec
        lappend cmd "$cfgVariables(gitCommand)"
        lappend cmd "reflog"
        lappend cmd "--"
        lappend cmd "$activeProject"
        # if [regexp -nocase -- {^fatal:} $pipe match] {
            # return 
        # }
        puts $cmd
        catch $cmd pipe
        # puts $pipe
        foreach line [split $pipe "\n"] {
            # puts "$line"
            lappend res $line
        }
        return $res
    }
    
    #  git show --pretty=format:"%h;%ad;%s"
    proc Show {w} {
        global cfgVariables activeProject
        set commitString [$w.body.lLog get [$w.body.lLog curselection]]
        set hash [string trim [lindex [split $commitString " "] 0]]
        $w.body.t delete 1.0 end
        $w.body.tCommit delete 1.0 end
        set cmd exec
        lappend cmd "$cfgVariables(gitCommand)"
        lappend cmd "show"
        lappend cmd "--pretty=format:\"%H;%an;%ae;%ad;%s\""
        lappend cmd $hash
        lappend cmd "--"
        lappend cmd "$activeProject"

        puts $cmd
        catch $cmd pipe
        # puts $pipe
        set i 0
        foreach line [split $pipe "\n"] {
            if {$i == 0} {
                set str [split $line ";"]
                $w.body.tCommit inser end "Hash: [string trimleft [lindex $str 0] "\""]\n"
                $w.body.tCommit inser end "Author: [lindex $str 1]\n"
                $w.body.tCommit inser end "Email: [lindex $str 2]\n"
                $w.body.tCommit inser end "Date: [lindex $str 3]\n"
                $w.body.tCommit inser end "Description: [string trimright [lindex $str 4] "\""]\n"
            } else {
                # puts "$line"
                $w.body.t inser end "$line\n"
            }
            incr i
            # lappend res $line
        }
        $w.body.t highlight 1.0 end
        $w.body.tCommit highlight 1.0 end
        # return $res
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
    
    proc DialogUpdate {w} {
        global activeProject
        # Git repo status
        $w.body.t delete 1.0 end
        $w.body.tCommit delete 1.0 end
        $w.body.lCommit delete 0 end
        $w.body.lBox delete 0 end
        $w.body.lLog delete 0 end
        foreach { word } [Git::Status] {
            # puts $word
            if [regexp -nocase -- {([\w\s])([\s\w?]+)\s../(.+?)} $word match v1 v2 fileName] {
                # puts "$v1 $v2 $fileName"
                # $fr.body.t delete 1.0 end
                if {$v1 ne " "} {
                    $w.body.lCommit insert end $fileName
                }
                if {$v2 ne " "} {
                    $w.body.lBox insert end $fileName
                }
            }
        }
        
        # Git commit history
        foreach { line } [Git::Reflog] {
            # puts $line
            $w.body.lLog insert end $line
        }         
        # End Git commit history
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
        pack $fr.header -side top -fill x  -padx 3

        ttk::frame $fr.body
        pack $fr.body -side top -expand true -fill both -padx 3
        
        ttk::label $fr.body.lblUnindexed -justify left -padding {3 3} \
            -text "[::msgcat::mc "Unindexed changes"]:"
        
    		listbox $fr.body.lBox -border 0 -yscrollcommand "$fr.body.yscroll set" -width 10
        ttk::scrollbar $fr.body.yscroll -orient vertical -command  "$fr.body.lBox yview"

        # pack [ttk::scrollbar $fr.body.v -command "$fr.body.t yview"] -side right -fill y
        ttk::scrollbar $fr.body.v -orient vertical -command "$fr.body.t yview"
        ttk::scrollbar $fr.body.h -orient horizontal -command "$fr.body.t xview"
        ctext $fr.body.t -xscrollcommand "$fr.body.h set" -yscrollcommand "$fr.body.v set" \
            -font $cfgVariables(font) -relief flat -wrap none -linemap 0 \
            -tabs "[expr {4 * [font measure $cfgVariables(font) 0]}] left" \
            -tabstyle tabular -undo true -width 10
        
        ttk::button $fr.body.bAdd -image forward_20x20 -compound center \
            -command "Git::CommitAdd $fr"
        ttk::button $fr.body.bRemove -compound center -image backward_20x20
        ttk::label $fr.body.lblCommitText -padding {3 3} \
            -text "[::msgcat::mc "Commit description"]:"
            
      		listbox $fr.body.lCommit -border 0 -yscrollcommand "$fr.body.vlCommit set"
        ttk::scrollbar $fr.body.vlCommit -orient vertical -command  "$fr.body.lCommit yview"
        ttk::scrollbar $fr.body.vCommit -command "$fr.body.tCommit yview"
        # ttk::scrollbar $fr.body.hCommit -orient horizontal -command "$fr.body.tCommit xview"
        ctext $fr.body.tCommit -tabstyle tabular -undo true \
            -yscrollcommand "$fr.body.vCommit set" \
            -font $cfgVariables(font) -relief flat -wrap word -linemap 0

        ttk::button $fr.body.bCommit -image done_20x20 -compound left \
            -text "[::msgcat::mc "Commit changes"]" \
            -command "Git::Commit $fr.body.tCommit; Git::DialogUpdate $fr"
        ttk::button $fr.body.bPush -image doneall_20x20 -compound left \
            -text "[::msgcat::mc "Push changes"]" \
            -command "Git::Push; Git::DialogUpdate $fr"
        
        ttk::label $fr.body.lblLog -padding {3 3} -text "[::msgcat::mc "Commit history"]:"
    		listbox $fr.body.lLog -border 0 \
                		-yscrollcommand "$fr.body.vLog set"	-xscrollcommand "$fr.body.hLog set"
        ttk::scrollbar $fr.body.vLog -orient vertical -command  "$fr.body.lLog yview"
        ttk::scrollbar $fr.body.hLog -orient horizontal -command  "$fr.body.lLog xview"


        # pack $txt -fill both -expand 1
        # pack $fr.body.h -side bottom -fill x

        grid $fr.body.lblUnindexed -column 0 -row 0 -sticky new -columnspan 4
        
        grid $fr.body.lBox    -column 0 -row 1 -sticky nsew -rowspan 2 -columnspan 2
        grid $fr.body.yscroll -column 2 -row 1 -sticky nsw -rowspan 2
        grid $fr.body.t -column	3 -row 1 -sticky nsew -columnspan 2
        grid $fr.body.v -column 5 -row 1 -sticky nsw
        grid $fr.body.h -column 3 -row 2 -sticky new -columnspan 2

        grid $fr.body.bAdd          -column 0 -row 3 -sticky nsew
        grid $fr.body.bRemove       -column 1 -row 3 -sticky nsew
        grid $fr.body.lblCommitText -column 3 -row 3 -sticky nsew -columnspan 2
        
        grid $fr.body.lCommit  -column 0 -row 4 -sticky nsew -rowspan 3 -columnspan 2
        grid $fr.body.vlCommit -column 2 -row 4 -sticky nsw -rowspan 3
        grid $fr.body.tCommit  -column 3 -row 4 -sticky nsew -columnspan 2 
        grid $fr.body.vCommit  -column 5 -row 4 -sticky nsw
        # grid $fr.body.hCommit  -column 3 -row 5 -sticky new -columnspan 2
        grid $fr.body.bCommit  -column 3 -row 6 -sticky new
        grid $fr.body.bPush    -column 4 -row 6 -sticky new

        grid $fr.body.lblLog -column 0 -row 7 -sticky nsew -columnspan 5
        grid $fr.body.lLog   -column 0 -row 8 -sticky nsew -columnspan 5
        grid $fr.body.vLog   -column 5 -row 8 -sticky nsw
        grid $fr.body.hLog   -column 0 -row 9 -sticky new -columnspan 5


        grid rowconfigure $fr.body $fr.body.t -weight 1
        grid columnconfigure $fr.body $fr.body.t -weight 1
        grid rowconfigure $fr.body $fr.body.tCommit -weight 1
        grid columnconfigure $fr.body $fr.body.tCommit -weight 1
        grid rowconfigure $fr.body $fr.body.lLog -weight 1
        grid columnconfigure $fr.body $fr.body.lLog -weight 1

        # Git repo status
        foreach { word } [Git::Status] {
            # puts $word
            if [regexp -nocase -- {([\w\s])([\s\w?]+)\s../(.+?)} $word match v1 v2 fileName] {
                # puts "$v1 $v2 $fileName"
                # $fr.unindexed.t delete 1.0 end
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
        bind $fr.body.lBox <Double-Button-1> "catch {Git::CommitAdd $fr}"
        bind $fr.body.lBox <Button-1><ButtonRelease-1> "Git::ListBoxPress $fr"
        bind $fr.body.lBox <KeyRelease> "Git::Key %K $fr"

        bind $fr.body.lLog <Double-Button-1> "Git::Show $fr"
        bind $fr.body.lLog <Return> "Git::Show $fr"
        
        focus -force $fr.body.lBox
        catch {
            $fr.body.lBox activate 0
            $fr.body.lBox selection set 0 0
            Git::ListBoxPress $fr
        }
        
        # Git commit history
        foreach { line } [Git::Reflog] {
            # puts $line
            $fr.body.lLog insert end $line
        }         
        # End Git commit history
        
        ctext::addHighlightClassForRegexp $fr.body.t paths #19a2a6 {@@.+@@}
        ctext::addHighlightClassForRegexp $fr.body.t add green {^\+.*$}
        ctext::addHighlightClassForRegexp $fr.body.t gremove grey {^\-.*$}
        $fr.body.t highlight 1.0 end
        
        ctext::addHighlightClassForRegexp $fr.body.tCommit stackControl lightblue {^[\w]+:}
    }
}
