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
    
    proc GetConfig {option} {
        global activeProject cfgVariables
        set confOptions {
            remote.origin.url
            user.user
            user.email
            init.defaultbranch
            branch.master.remote
        }
        if {$activeProject ne ""} {
            cd $activeProject
        }
        
        set cmd exec
        lappend cmd $cfgVariables(gitCommand)
        lappend cmd "config"
        switch $option {
            all {
                lappend cmd "-l"
            }
            default {
                lappend cmd "--get"
                lappend cmd "$option"
            }
        }
        # lappend cmd $activeProject
        catch $cmd pipe        
        foreach line [split $pipe "\n"] {
            lappend res $line
        }
        return $res
    }

    proc Checkout {opt {ent ".branch.entBranch"}} {
        global cfgVariables activeProject
        set cmd exec
        set d [pwd]
        if {$activeProject ne ""} {
            cd $activeProject
        }
        lappend cmd $cfgVariables(gitCommand)
        lappend cmd "checkout"
        # lappend cmd "-s"
        # lappend cmd "--"
        # lappend cmd $activeProject
        switch $opt {
            switchBranch {
                set branch [.branch.lBox get [.branch.lBox curselection]]
                lappend cmd "[string trim $branch]"
            }
            new {
                lappend cmd "-b"
                lappend cmd "[$ent get]"
                # puts "Branch [$ent get]"
            }
        }
        catch $cmd pipe
        puts $cmd
        puts $pipe
        if [regexp -nocase -- {^error:} $pipe match] {
            ShowMessage "Command: '$cmd' error" $pipe
            return 
        }
        foreach line [split $pipe "\n"] {
            lappend res $line
        }
        # cd $d
        
        .frmStatus.lblGit configure -text "[::msgcat::mc "Branch"]: [Git::Branches current]"
        FileOper::ReadFolder $activeProject
        
        if [info exists res] {
            return $res
        }
    }

    proc Branches {opt} {
        global cfgVariables activeProject
        set cmd exec
        set d [pwd]
        if {$activeProject ne "" && [file isdirectory $activeProject] == 1} {
            cd $activeProject
            if ![file exists .git] {
                return
            }
        } else {
            return ""
        }
        puts $activeProject
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
            ShowMessage "Command: '$cmd' error" $pipe
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
        if [file isdirectory $activeProject] {
            cd $activeProject
            if ![file exists .git] {
                return
            }
        } else {
            return false
        }
        set cmd exec
        lappend cmd $cfgVariables(gitCommand)
        lappend cmd "status"
        lappend cmd "-s"
        lappend cmd "--"
        lappend cmd $activeProject
        catch $cmd pipe
        puts $cmd
        if [regexp -nocase -- {^fatal:} $pipe match] {
            ShowMessage "Command: '$cmd' error" $pipe
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
        set res ""
        lappend cmd $cfgVariables(gitCommand)
        lappend cmd "diff"
        lappend cmd "--"
        lappend cmd [file join $activeProject [string trimleft $f "../"]]
        catch $cmd pipe
        puts $cmd
        if [regexp -nocase -- {^fatal:} $pipe match] {
            ShowMessage "Command: '$cmd' error" $pipe
            return 
        }
        foreach line [split $pipe "\n"] {
            lappend res $line
        }
        return $res
    }
    
    proc Commit {w} {
        global cfgVariables activeProject
        set txt $w.body.tCommit
        set listBox $w.body.lCommit 
        set description [string trim [$txt get 0.0 end]]
        puts $description
        set cmd exec
        append cmd " $cfgVariables(gitCommand)"
        append cmd " commit"
        append cmd " -m"
        regsub -all {\"|\'} $description {'} description
        append cmd " \"$description\""
        append cmd " --"
        foreach item [$listBox get 0 [$listBox size]] {
            append cmd " [file join $activeProject $item]"
        }
        if {$description eq ""} {
            set answer [tk_messageBox -message [::msgcat::mc "Empty commit description"] \
                -icon info -type ok \
                -detail [::msgcat::mc "You must enter a commit description"]]
            switch $answer {
                ok {return "cancel"}
            }
        } else {
            puts $cmd
            puts $description
            catch $cmd pipe
            puts $pipe
            if [regexp -nocase -- {^fatal:} $pipe match] {
                ShowMessage "Command: '$cmd' error" $pipe
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
    
    # Вызов диалога авторизации если ссылка на репу по http
    # Если ссылка по ssh то вызов Push
    proc PushPrepare {} {
        global cfgVariables activeProject gitUser gitPassword
        # set cmd exec
        cd $activeProject
        set url [Git::GetConfig remote.origin.url]
        puts $url
        if [regexp -nocase -all -- {^(http|https)://(.+)} $url match proto address] {
            Git::AuthorizationDialog "[::msgcat::mc "Authorization required"] [::msgcat::mc "for"] Git" $url
        } else {
            Git::Push $url
        }
    }
    
    # /usr/bin/git push https://user:pass@git.nuk-svk.ru/repo.git
    # /usr/bin/git push ssh://git@git.nuk-svk.ru/repo.git
    proc Push {url} {
        global cfgVariables activeProject gitUser gitPassword
        set cmd exec
        lappend cmd "$cfgVariables(gitCommand)"
        cd $activeProject       
        lappend cmd "push"
        lappend cmd "$url"
        # lappend cmd "$activeProject"
        # puts "$cmd"
        catch $cmd pipe
        puts $pipe
        if [regexp -nocase -- {^fatal:} $pipe match] {
            ShowMessage "Command: '$cmd' error" $pipe
            return 
        }
        foreach line [split $pipe "\n"] {
            # puts "$line"
            lappend res $line
        }
        return $res
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
    
    proc Reset {w} {
        global activeProject cfgVariables
        # puts $values
        set selectedItems [$w.body.lCommit curselection]
        if {$selectedItems eq ""} {return}
        set cmd exec
        lappend cmd $cfgVariables(gitCommand)
        lappend cmd "reset"
        foreach itemNumber [lsort -integer -increasing $selectedItems] {
            set fileName [$w.body.lCommit get $itemNumber]
            $w.body.lBox insert end $fileName
            lappend cmd [file join $activeProject $fileName]
        }
        foreach itemNumber [lsort -integer -decreasing $selectedItems] {
            $w.body.lCommit delete $itemNumber
        }
        catch $cmd pipe
        puts $cmd
        $w.body.t delete 1.0 end
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
        if {[$w.body.lBox curselection] ne ""} {
            if {[llength [$w.body.lBox curselection]] == 1} {
                set fileName [$w.body.lBox get [$w.body.lBox curselection]]
            } else {
                set fileName [$w.body.lBox get [$w.body.lBox index active]]
            }
        } else {
            return
        }
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
        # puts $values
        set selectedItems [$w.body.lBox curselection]
        set cmd exec
        lappend cmd $cfgVariables(gitCommand)
        lappend cmd "add"
        foreach itemNumber [lsort -integer -increasing $selectedItems] {
            set fileName [$w.body.lBox get $itemNumber]
            lappend cmd [file join $activeProject $fileName]
            $w.body.lCommit insert end $fileName
        }
        foreach itemNumber [lsort -integer -decreasing $selectedItems] {
            $w.body.lBox delete $itemNumber
        }
        catch $cmd pipe
        puts $cmd
        $w.body.t delete 1.0 end
    }
    
    proc Clone {repo dir} {
        global activeProject cfgVariables
        # puts $values
        set cmd exec
        lappend cmd $cfgVariables(gitCommand)
        lappend cmd "clone"
        lappend cmd $repo
        lappend cmd $dir
        puts $cmd

        catch $cmd pipe
        puts $pipe
        return
    }
    proc Config {repo user email} {
        global activeProject cfgVariables
        # puts $values
        set cmd exec
        lappend cmd $cfgVariables(gitCommand)
        lappend cmd "config"
        lappend cmd $repo
        lappend cmd $dir
        puts $cmd

        # catch $cmd pipe
        # puts $pipe
        return
    }
    proc Init {} {
        global activeProject cfgVariables
        # puts $values
        if [file isdirectory $activeProject] {
            cd $activeProject
        } else {
            return false
        }
        set cmd exec
        lappend cmd $cfgVariables(gitCommand)
        lappend cmd "init"
        lappend cmd $activeProject
        puts $cmd

        catch $cmd pipe
        if [regexp -nocase -- {^fatal:} $pipe match] {
            ShowMessage "Command: '$cmd' error" $pipe
            return 
        }
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
        set lblText "$activeProject | [::msgcat::mc "Branch"]: [Git::Branches current]"
        $w.header.lblGit configure -text $lblText
        $w.body.t delete 1.0 end
        $w.body.tCommit delete 1.0 end
        $w.body.lCommit delete 0 end
        $w.body.lBox delete 0 end
        $w.body.lLog delete 0 end
        foreach { word } [Git::Status] {
            puts ">>$word"
            if [regexp -nocase -- {([\w\s]+)([\s\w?]+)\s(../|)(.+?)} $word match v1 v2 v3 fileName] {
                puts "$v1 $v2 $fileName"
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
        focus -force $w.body.lBox
        catch {
            $w.body.lBox activate 0
            $w.body.lBox selection set 0 0
            Git::ListBoxPress $w
        }
    }
    
    proc AddToplevel {lbl img {win_name .auth}} {
        set cmd "destroy $win_name"
        if [winfo exists $win_name] {destroy $win_name}
        toplevel $win_name
        wm transient $win_name .
        wm title $win_name [::msgcat::mc "Add record"]
        # wm iconphoto $win_name tcl
        ttk::label $win_name.lbl -image $img -anchor nw
        
        set frm [ttk::labelframe $win_name.frm -text $lbl -labelanchor nw]
        grid columnconfigure $frm 0 -weight 1
        grid rowconfigure $frm 0 -weight 1
        set frm_btn [ttk::frame $win_name.frm_btn ]
        ttk::button $frm_btn.btn_ok -image done_20x20 -command { }
        ttk::button $frm_btn.btn_cancel -command $cmd -image cancel_20x20 
        grid $win_name.lbl -row 0 -column 0 -sticky nsw -padx 0 -pady 1 -rowspan 2 
        grid $frm -row 0 -column 1 -sticky nw -padx 2 -pady 2
        grid $frm_btn -row 1 -column 1 -sticky sew -padx 0 -pady 0
        pack  $frm_btn.btn_cancel $frm_btn.btn_ok -side right -padx 5 -pady 5
        #pack  $frm_btn.btn_ok  -side right -padx 2
        bind $win_name <Escape> $cmd
        return $frm
    }
    proc GetAuthData {url} {
        global gitUser gitPassword
        # puts [.auth_win.frm.ent_name get]
        # puts [.auth_win.frm.ent_pwd get]	
        set gitUser [.auth_win.frm.ent_name get]
        set gitPassword [.auth_win.frm.ent_pwd get]
        if [regexp -nocase -all -- {^(http|https)://(.+)} $url match proto address] {
    
            # puts $gitUser
            # puts $gitPassword
            if {$gitUser ne ""} {
                append repoUrl "$proto"
                append repoUrl "://"
                append repoUrl "$gitUser"
            }
            if {$gitPassword ne ""} {
                append repoUrl ":$gitPassword"
                append repoUrl "@$address"
            }
            # puts $repoUrl
            Git::Push $repoUrl    
        }
        destroy .auth_win
    }
    proc AuthorizationDialog {txt url} {
        global gitUser gitPassword
        set frm [Git::AddToplevel "$txt" key_64x64 .auth_win]
        wm title .auth_win [::msgcat::mc "Authorization"]
        ttk::label $frm.lbl_name -text [::msgcat::mc "User name"]
        ttk::entry  $frm.ent_name
        ttk::label $frm.lbl_pwd -text [::msgcat::mc "Password"]
        ttk::entry $frm.ent_pwd
        
        grid $frm.lbl_name -row 0 -column 0 -sticky nw -padx 5 -pady 5
        grid $frm.ent_name -row 0 -column 1 -sticky nsew -padx 5 -pady 5
        grid $frm.lbl_pwd -row 1 -column 0 -sticky nw -padx 5 -pady 5
        grid $frm.ent_pwd -row 1 -column 1 -sticky nsew -padx 5 -pady 5
        grid columnconfigure $frm 0 -weight 1
        grid rowconfigure $frm 0 -weight 1
        #set frm_btn [frame .add.frm_btn -border 0]
        .auth_win.frm_btn.btn_ok configure -command "Git::GetAuthData $url"
    }
    
    proc BranchDialog {x y} {
        global editors lexers newBranchName
        variable win
        # set txt $w.frmText.t
        set win .branch
        # set x [winfo rootx .frmWork]
        # set y [winfo rooty .frmWork]
        
        if { [winfo exists $win] } { destroy $win }
        toplevel $win
        wm transient $win .
        wm overrideredirect $win 1
        ttk::button $win.bAdd -image new_14x14 -compound left -text "[::msgcat::mc "Add new branch"]" \
            -command {
                grid forget .branch.lBox .branch.yscroll
                grid .branch.entBranch
                bind .branch <Return> "Git::Checkout new .branch.entBranch; destroy .branch"
            }
        ttk::entry $win.entBranch -textvariable newBranchName
        
        listbox $win.lBox -width 30 -border 2 -yscrollcommand "$win.yscroll set" -border 1
        ttk::scrollbar $win.yscroll -orient vertical -command  "$win.lBox yview"
        # pack $win.lBox -expand true -fill y -side left
        # pack $win.yscroll -side left -expand false -fill y
        grid $win.bAdd -column 0 -row 0 -columnspan 2 -sticky new
        grid $win.lBox -column 0 -row 1
        grid $win.yscroll -column 1 -row 1 -sticky nsw
        
        set lst [Git::Branches all]
        foreach { word } $lst {
            $win.lBox insert end $word
        }
        
        focus -force $win.lBox
        catch { $win.lBox activate 0 ; $win.lBox selection set 0 0 }
        
        if { [set height [llength $lst]] > 10 } { set height 10 }
        $win.lBox configure -height $height

        bind $win <Escape> { 
            destroy .branch
            break
        }
        bind $win.lBox <Escape> {
            destroy .branch
            break
        }
        bind $win.lBox <Return> {
            Git::Checkout switchBranch
            .frmStatus.lblGit configure -text "[::msgcat::mc "Branch"]: [Git::Branches current]"
            destroy .branch
        }
        bind $win.lBox <Any-Key> {}
        bind $win.lBox <Double-Button-1> {
            Git::Checkout switchBranch
            .frmStatus.lblGit configure -text "[::msgcat::mc "Branch"]: [Git::Branches current]"
            destroy .branch
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
    }
    
    proc CloneDialog {} {
        global activeProject
        set win .clone
        set x [winfo rootx .frmWork]
        set y [winfo rooty .frmWork]
    
        if { [winfo exists $win] } {
            destroy $win
            return
        }
        toplevel $win

        wm transient $win .
        wm overrideredirect $win 1
        
        ttk::entry $win.entUrl
        ttk::entry $win.entFolder
        ttk::button $win.btnFolder -image folder -command {
            set folderPath [tk_chooseDirectory  -initialdir $env(HOME) -parent .]
            .clone.entFolder insert end $folderPath
        }

        ttk::button $win.btnClone -compound left -image done_20x20 \
            -text [::msgcat::mc "Clone repository"] \
            -command {
                set folderPath [.clone.entFolder get]
                set repo [.clone.entUrl get]
                if {$repo eq ""} {return}
                if {$folderPath eq ""} {
                    set folderPath [tk_chooseDirectory  -initialdir $env(HOME) -parent .]
                    if {$folderPath eq ""} {return}
                }
                set repoDir [file join $folderPath [string trimright [file rootname [file tail $repo]] "."]]
                Git::Clone $repo $repoDir
                FileOper::ReadFolder $repoDir
                ReadFilesFromDirectory $repoDir $repoDir
                destroy .clone
            }

        ttk::button $win.btnInit -compound left -image new_20x20 \
            -text [::msgcat::mc "Init repository"] -command {
                Git::Init
                FileOper::ReadFolder $activeProject
                ReadFilesFromDirectory $activeProject $activeProject
                destroy .clone
            }
        
        grid $win.entUrl -row 0 -column 0 -columnspan 2 -sticky new
        grid $win.entFolder -row 1 -column 0 -sticky new
        grid $win.btnFolder -row 1 -column 1 -sticky ew
        grid $win.btnClone -row 2 -column 0 -columnspan 2 -sticky new
        grid $win.btnInit -row 3 -column 0 -columnspan 2 -sticky new
    
        bind $win <Escape> "destroy $win"
        
        # Определям расстояние до края экрана (основного окна) и если
        # оно меньше размера окна со списком то сдвигаем его вверх
        set winGeom [winfo reqheight $win]
        set topHeight [winfo height .]
        # puts "$x, $y, $winGeom, $topHeight"
        if [expr [expr $topHeight - $y] < $winGeom] {
            set y [expr $topHeight - $winGeom]
        }
        wm geom $win +$x+$y
        focus $win.entUrl
    }    
    

    proc Dialog {} {
        global cfgVariables activeProject nbEditor
        variable fr
        if [winfo exists $nbEditor.git_browse] {
            if {[$nbEditor select] eq "$nbEditor.git_browse"} {
                destroy $nbEditor.git_browse
            } else {
                $nbEditor select $nbEditor.git_browse
            }
            return
        }
        if {[info exists activeProject] == 0 || [file exists [file join $activeProject .git]] == 0} {
            Git::CloneDialog
            return
        }
        set fr [NB::InsertItem $nbEditor git_browse "git"]
        ttk::frame $fr.header
        set lblText "$activeProject | [::msgcat::mc "Branch"]: [Git::Branches current]"
        ttk::label $fr.header.lblGit -text $lblText -justify right
        ttk::button $fr.header.btnRefresh -image refresh_11x11 \
            -command "Git::DialogUpdate $fr"
        pack $fr.header.lblGit -side left -expand true -fill x
        pack $fr.header.btnRefresh -side right
        pack $fr.header -side top -fill x  -padx 3

        ttk::frame $fr.body
        pack $fr.body -side top -expand true -fill both -padx 3
        
        ttk::label $fr.body.lblUnindexed -justify left -padding {3 3} \
            -text "[::msgcat::mc "Unindexed changes"]:"
        
    		listbox $fr.body.lBox -selectmode extended -border 0 \
            -yscrollcommand "$fr.body.yscroll set" -width 10
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
        ttk::button $fr.body.bRemove -compound center -image backward_20x20 \
            -command "Git::Reset $fr"
        ttk::label $fr.body.lblCommitText -padding {3 3} \
            -text "[::msgcat::mc "Commit description"]:"
            
      		listbox $fr.body.lCommit -selectmode multiple -border 0 \
      		    -yscrollcommand "$fr.body.vlCommit set"
        ttk::scrollbar $fr.body.vlCommit -orient vertical -command  "$fr.body.lCommit yview"
        ttk::scrollbar $fr.body.vCommit -command "$fr.body.tCommit yview"
        # ttk::scrollbar $fr.body.hCommit -orient horizontal -command "$fr.body.tCommit xview"
        ctext $fr.body.tCommit -tabstyle tabular -undo true \
            -yscrollcommand "$fr.body.vCommit set" \
            -font $cfgVariables(font) -relief flat -wrap word -linemap 0

        ttk::button $fr.body.bCommit -image done_20x20 -compound left \
            -text "[::msgcat::mc "Commit changes"]" \
            -command "Git::Commit $fr; Git::DialogUpdate $fr"
        ttk::button $fr.body.bPush -image doneall_20x20 -compound left \
            -text "[::msgcat::mc "Push changes"]" \
            -command "Git::PushPrepare; Git::DialogUpdate $fr"
        
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

        grid $fr.body.bAdd          -column 0 -row 3 -sticky nsw
        grid $fr.body.bRemove       -column 1 -row 3 -sticky nsw
        grid $fr.body.lblCommitText -column 3 -row 3 -sticky nsew -columnspan 2
        
        grid $fr.body.lCommit  -column 0 -row 4 -sticky nsw -rowspan 3 -columnspan 2
        grid $fr.body.vlCommit -column 2 -row 4 -sticky nsw -rowspan 3
        grid $fr.body.tCommit  -column 3 -row 4 -sticky nsew -columnspan 2 
        grid $fr.body.vCommit  -column 5 -row 4 -sticky nsw
        # grid $fr.body.hCommit  -column 3 -row 5 -sticky new -columnspan 2
        grid $fr.body.bCommit  -column 3 -row 6 -sticky new
        grid $fr.body.bPush    -column 4 -row 6 -sticky new

        grid $fr.body.lblLog -column 0 -row 7 -sticky nsw -columnspan 5
        grid $fr.body.lLog   -column 0 -row 8 -sticky nsew -columnspan 5
        grid $fr.body.vLog   -column 5 -row 8 -sticky nsw
        grid $fr.body.hLog   -column 0 -row 9 -sticky new -columnspan 5

        grid rowconfigure $fr.body $fr.body.t -weight 1
        grid columnconfigure $fr.body $fr.body.t -weight 1
        grid rowconfigure $fr.body $fr.body.tCommit -weight 1
        grid columnconfigure $fr.body $fr.body.tCommit -weight 1
        # grid rowconfigure $fr.body $fr.body.lLog -weight 1
        # grid columnconfigure $fr.body $fr.body.lLog -weight 1

        # Git repo status
        foreach { word } [Git::Status] {
            puts $word
            if [regexp -nocase -- {([\w\s\?])([\s\w\\*\?]+)\s(.+?)} $word match v1 v2 fileName] {
                puts "$v1 $v2 $fileName"
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

        bind $fr.header.lblGit <Button-1><ButtonRelease-1> {
            Git::BranchDialog %X %Y
            Git::DialogUpdate $Git::fr
        }
        bind $fr.body.lBox <Return> "Git::CommitAdd $fr"
        bind $fr.body.lBox <Double-Button-1> \
            "catch {Git::CommitAdd $fr; $fr.body.t delete 0.0 end; $fr.body.tCommit delete 0.0 end}"
        # bind $fr.body.lBox <Button-1><ButtonPress-1> "Git::ListBoxPress $fr"
        bind $fr.body.lBox <<ListboxSelect>> "Git::ListBoxPress $fr"
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
        
        ctext::addHighlightClassForRegexp $fr.body.t files yellow {^diff.*$}
        ctext::addHighlightClassForRegexp $fr.body.t paths #19a2a6 {@@.+@@}
        ctext::addHighlightClassForRegexp $fr.body.t add green {^\+.*$}
        ctext::addHighlightClassForRegexp $fr.body.t gremove grey {^\-.*$}
        $fr.body.t highlight 1.0 end
        
        ctext::addHighlightClassForRegexp $fr.body.tCommit stackControl lightblue {^[\w]+:}
    }
}
