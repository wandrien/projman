#!/usr/bin/wish
######################################################
#                ProjMan 2
#        Distributed under GNU Public License
# Author: Sergey Kalinin svk@nuk-svk.ru
# Copyright (c) "", 2022, https://nuk-svk.ru
######################################################
# Generate menu module
######################################################

proc GetFileMenu {m} {
    global activeProject
    $m add command -label [::msgcat::mc "New file"] -command Editor::New\
    -accelerator "Ctrl+N"
    $m add command -label [::msgcat::mc "Open file"] -accelerator "Ctrl+O" -command {
        set filePath [FileOper::OpenDialog]
        if {$filePath != ""} {
            FileOper::Edit $filePath
        }
    }
    $m add command -label [::msgcat::mc "Save file"] -command {FileOper::Save}\
        -accelerator "Ctrl+S"
    $m add command -label [::msgcat::mc "Close file"] -command {FileOper::Close}\
        -accelerator "Ctrl+w"
    $m add command -label [::msgcat::mc "Close all"] -command {FileOper::CloseAll}

    $m add separator

    $m add command -label [::msgcat::mc "Open folder"] -accelerator "Ctrl+K" -command {
        set folderPath [FileOper::OpenFolderDialog]
        if {$folderPath != ""} {
            # set activeProject $folderPath
            SetActiveProject $folderPath
            FileOper::ReadFolder $folderPath
            ReadFilesFromDirectory $folderPath $folderPath
        }
    }    
    $m add command -label [::msgcat::mc "Close folder"] -command {FileOper::CloseFolder}

    #$m add command -label [::msgcat::mc "Open"] -command {FileDialog $tree open}\
    #-font $fontNormal -accelerator "Ctrl+O"        -state disable
    $m add separator
    $m add command -label [::msgcat::mc "Exit"] -command Quit -accelerator "Ctrl+Q"
}


proc GetEditMenu {m} {
    $m add command -label [::msgcat::mc "Undo"] -command Undo\
    -accelerator "Ctrl+Z"
    $m add command -label [::msgcat::mc "Redo"] -command Redo\
    -accelerator "Ctrl+Y"
    $m add separator
    $m add command -label [::msgcat::mc "Copy"] -command Copy\
    -accelerator "Ctrl+C"
    $m add command -label [::msgcat::mc "Paste"] -command Paste\
    -accelerator "Ctrl+V"
    $m add command -label [::msgcat::mc "Cut"] -command Cut\
    -accelerator "Ctrl+Z"
    $m add separator
    $m add command -label [::msgcat::mc "Find"] -command {Editor::FindDialog ""}\
    -accelerator "Ctrl+F"
    # $m add command -label [::msgcat::mc "Replace"] -command Replace\
    # -accelerator "Ctrl+R"
    $m add separator
    $m add command -label [::msgcat::mc "Find in files"] -command "FileOper::FindInFiles"\
    -accelerator "Ctrl+Shift+F"
    $m add command -label [::msgcat::mc "Replace in files"] -command FileOper::ReplaceInFiles\
    -accelerator "Ctrl+Shift+RV"
    $m add separator
    $m add command -label [::msgcat::mc "Insert image"] -accelerator "Ctrl+I"\
        -command ImageBase64Encode
    
}

proc GetViewMenu {m} {
    global cfgVariables
    $m add checkbutton -label [::msgcat::mc "View panel"] -command ViewFilesTree \
        -variable cfgVariables(filesPanelShow) -onvalue true -offvalue false \
        -accelerator "Alt+P"
    menu $m.panelSide 
    $m add cascade -label [::msgcat::mc "Panel side"] -menu $m.panelSide 
    $m.panelSide  add radiobutton -label [::msgcat::mc "Left"] \
        -variable cfgVariables(filesPanelPlace) -value left -command ViewFilesTree
    $m.panelSide  add radiobutton -label [::msgcat::mc "Right"] \
        -variable cfgVariables(filesPanelPlace) -value right -command ViewFilesTree
        
    $m add checkbutton -label [::msgcat::mc "Show the Menu"] -command ViewMenuBar \
        -variable cfgVariables(menuShow) -onvalue true -offvalue false
    $m add checkbutton -label [::msgcat::mc "Toolbar"] -command ViewToolBar \
        -variable cfgVariables(toolBarShow) -onvalue true -offvalue false 
        $m add checkbutton -label [::msgcat::mc "Statusbar"] -command ViewStatusBar \
        -variable cfgVariables(statusBarShow) -onvalue true -offvalue false

    $m add separator
    # $m add command -label [::msgcat::mc "View line numbers"] \
        # -command ViewLineNumbers
    $m add checkbutton -label [::msgcat::mc "View line numbers"] \
        -variable cfgVariables(lineNumberShow) -onvalue true -offvalue false \
        -command ViewLineNumbers
        
    menu $m.editorWrap
    $m add cascade -label [::msgcat::mc "Editors word wrapping"] -menu $m.editorWrap
    $m.editorWrap  add radiobutton -label [::msgcat::mc "None"] -variable cfgVariables(editorWrap) \
        -value none -command "Editor::SetOption wrap $cfgVariables(editorWrap)"
    $m.editorWrap  add radiobutton -label [::msgcat::mc "Char"] -variable cfgVariables(editorWrap) \
        -value char -command "Editor::SetOption wrap $cfgVariables(editorWrap)"
    $m.editorWrap  add radiobutton -label [::msgcat::mc "Word"] -variable cfgVariables(editorWrap) \
        -value word -command "Editor::SetOption wrap $cfgVariables(editorWrap)"

    $m add separator
    menu $m.editorHelper
    $m add cascade -label [::msgcat::mc "Editor helpers"] -menu $m.editorHelper
    $m.editorHelper add checkbutton -label [::msgcat::mc "Variables"] \
        -variable cfgVariables(variableHelper) -onvalue true -offvalue false 
        # -command "ViewHelper variableHelper"
        
    $m.editorHelper add checkbutton -label [::msgcat::mc "Procedures"] \
        -variable cfgVariables(procedureHelper) -onvalue true -offvalue false 
        # -command "ViewHelper procedureHelper"

}

proc GetHelpMenu {m} {
    $m add command -label [::msgcat::mc "About ..."] -command Help::About
}

proc PopupMenu {x y} {
    tk_popup .popup $x $y
}
