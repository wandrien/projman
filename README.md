## About

ProjMan (aka "Tcl/Tk Project Manager") is a editor for programming in TCL/Tk (and other language).
It includes a file manager, a source editor with syntax highlighting and code navigation, a context-sensitive help system, Git support, and much more.
Working an Linux and Windows.

## Support languages

Highlightning and source code navigation:

* Tcl/Tk
* GO
* Perl
* Python
* Ruby
* Shell (BASH)
* Markdown
* YAML (Ansible support)
* Lua

Highlightning:

* HTML
* XML

## Requirements

For UNIX-like OS
Tcl/Tk >= 8.6 http://tcl.tk
tcllib, tklib

## Screenshots

- Navigation the source code structure, and syntax highlighting

![projman_go_codenav.png](https://nuk-svk.ru/images/projman_go_codenav.png)
![projman_tcl_vars.png](https://nuk-svk.ru/images/projman_tcl_vars.png)
![projman_tcl_codenav.png](https://nuk-svk.ru/images/projman_tcl_codenav.png)
![projman_syntax_highlight.png](https://nuk-svk.ru/images/projman_syntax_highlight.png)
![projman_html.png](https://nuk-svk.ru/images/projman_html.png)

- Hints when entering names of variables and procedures

![projman_proc_vars.png](https://nuk-svk.ru/images/projman/projman_proc_vars.png)

- Searching for a variable definition in ansible files
- Navigation the ansible source code structure

![projman_yaml_variables.png](https://nuk-svk.ru/images/projman_yaml_variables.png)

- Navigation the markdown source code structure

![projman_md_codenav.png](https://nuk-svk.ru/images/projman_md_codenav.png)

- Git dialog (commit history)
- Git dialog (changes)

![projman_git.png](https://nuk-svk.ru/images/projman/projman_git.png)

- Flexible interface configuration

![projman_gui_flexibility.png](https://nuk-svk.ru/images/projman_gui_flexibility.png)

- Find/Replace dialog

![projman_find_replace.png](https://nuk-svk.ru/images/projman_find_replace.png)

- Global searching dialog

![projman_global_search.png](https://nuk-svk.ru/images/projman_global_search.png)

## Getting source code

Download the source code https://git.nuk-svk.ru/svk/projman/

Or use git:

```
  git clone https://git.nuk-svk.ru/svk/projman.git
```

## Build package

```
  cd projman/debian/
  ./build-deb-projman.sh 

  cd projman/redhat/
  ./build-rpm-projman.sh 
```

## Install

Use package manager for you system:

Debian ```sudo dpkg -i projman_2.0.0-alpha_amd64.deb```

Redhat ```sudo rpm -Uhv projman_2.0.0-alpha_amd64.rpm```

## Usage

Running command (need full path to the each file or folder):

Open files

```
  projman ~/tmp/test.tcl ~/tmp/2.go ...
```

Open folders

```
  projman ~/projects/projman ...
```

Or type "projman" into terminal, Or choose the name of the program "Projman" on the Start menu.

### Keyboard shortcut

- Ctrl-N - Create new file
- Ctrl-O - Open file
- Ctrl-W - Close editor (file)
- Ctrl-K - Open folder
- Ctrl-Q - Quit from ProjMan
- Ctrl-J - Show procedures (functions) list for navigation in open editor
- Ctrl-L - Find and display files where the variable is defined, the name of which is located under the cursor in the editor
- Ctrl-F - Search text in open editor

- Ctrl-[ - Move the line (or selected lines) one position (see config tabSize=4) to the right
- Ctrl-] - Move the line (or selected lines) one position to the left
- Ctrl-, - Comment the line (or selected lines)
- Ctrl-. - Uncomment the line (or selected lines)
- Ctrl-I - Insert base64 encoded image into edited text
- Ctrl-G - Go to line dialog
- Ctrl-C - Copy selected text into buffer
- Ctrl-V - Paste text from buffer

- Alt-P - Show/Hide the file tree panel
- Alt-W - Delete the current word
- Alt-E - Delete text from current position to end of line
- Alt-B - Delete text from current position to begin of line
- Alt-R - Delete current line
- Alt-Y - Copy current line into buffer
- Alt-S - Split the edited window horizontally

## Credits

Sergey Kalinin - author
svk@nuk-svk.ru
http://nuk-svk.ru

Laurent Riesterer - VisualREGEXP and TkDIFF+ parts
laurent.riesterer@free.fr
http://laurent.riesterer.free.fr
