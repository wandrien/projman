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
    
    proc Status {} {
        global cfgVariables activeProject
        set cmd exec
        lappend cmd $cfgVariables(gitCommand)
        lappend cmd "status"
        lappend cmd "-s"
        lappend cmd "--"
        lappend cmd $activeProject
        catch $cmd pipe
        foreach line [split $pipe "\n"] {
            lappend res $line
        }
        return $res
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
        # puts $pipe
        foreach line [split $pipe "\n"] {
            lappend res $line
        }
        return $res
    }
    
    proc Commit {} {
        global cfgVariables activeProject
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
    
    proc Dialog {} {
        global cfgVariables activeProject nbEditor
        variable fr
        set fr [NB::InsertItem $nbEditor git_browse "git"]
        ttk::frame $fr.header
        set lblName "lblGit"
        set lblText $activeProject
        ttk::label $fr.header.$lblName -text $lblText
        pack $fr.header.$lblName -side left -expand true -fill x
        pack $fr.header -side top -fill x

        ttk::frame $fr.body     
        pack $fr.body -side top -expand true -fill both
        
    		set lstFiles [listbox $fr.body.lBox -width 30 -border 2 -yscrollcommand "$fr.body.yscroll set" -border 1]
        ttk::scrollbar $fr.body.yscroll -orient vertical -command  "$fr.body.lBox yview"
        pack $fr.body.lBox -expand true -fill y -side left
        pack $fr.body.yscroll -side left -expand false -fill y

        set txt $fr.body.t
        # set txt $frmText.t
        
        pack [ttk::scrollbar $fr.body.v -command "$fr.body.t yview"] -side right -fill y
        ttk::scrollbar $fr.body.h -orient horizontal -command "$fr.body.t xview"
        ctext $txt -xscrollcommand "$fr.body.h set" -yscrollcommand "$fr.body.v set" \
            -font $cfgVariables(font) -relief flat -wrap none \
            -linemapfg $cfgVariables(lineNumberFG) -linemapbg $cfgVariables(lineNumberBG) \
            -tabs "[expr {4 * [font measure $cfgVariables(font) 0]}] left" -tabstyle tabular -undo true
            
        pack $txt -fill both -expand 1
        pack $fr.body.h -side bottom -fill x
        
        foreach { word } [Git::Status] {
            $fr.body.lBox insert end [string trim $word]
        }
        catch { $fr.body.lBox activate 0 ; $fr.body.lBox selection set 0 0 }
        bind $fr.body.lBox <Return> {
            set values [$Git::fr.body.lBox get [$Git::fr.body.lBox curselection]]
            if [regexp -nocase -line -lineanchor -- {([\w?]+)\s(.+?)} $values m mod fileName] {
                $Git::fr.body.t delete 1.0 end
                switch $mod {
                    M {
                        set i 0
                        foreach line [Git::Diff $fileName] {
                            puts $line
                            if {$i > 3} {
                                $Git::fr.body.t inser end "$line\n"
                            }
                            incr i
                        }
                        $Git::fr.body.t highlight 1.0 end
                    }
                    "??" {
                        $Git::fr.body.t inser end [::msgcat::mc "Untraceable file"]
                    }
                    D {
                        $Git::fr.body.t inser end [::msgcat::mc "File was deleted"]
                    }
                }
            }

            break
        }
        ctext::addHighlightClassForRegexp $txt paths #19a2a6 {@@.+@@}
        ctext::addHighlightClassForRegexp $txt add green {^\+.*$}
        ctext::addHighlightClassForRegexp $txt gremove grey {^\-.*$}
        $txt highlight 1.0 end
    }
}
