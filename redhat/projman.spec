Name:           projman
Version:        2.0.0
Release:        rh1
Summary:        Tcl/Tk Project Manager
License:        GPL
Group:          Development/Tcl
Url:            https://nuk-svk.ru
BuildArch:      noarch
Source:         %name-%version-%release.tar.gz
Requires:       tcl, tk, tklib, tcllib

%description
This a editor for programming in TCL/Tk (and other language). It includes a file manager, a source editor with syntax highlighting and code navigation, a context-sensitive help system, Git support, and much more.

%description -l ru_RU.UTF8
Интегрированная среда для программирования на Tcl/Tk. Включает в себя - менеджер проектов, полнофункциональный редактор, систему навигации по файлам и структуре файлов и многое другое.

%prep
%setup -n %name

%build

%install
mkdir -p $RPM_BUILD_ROOT%_bindir
mkdir -p $RPM_BUILD_ROOT%_datadir/%name/lib/msgs
mkdir -p $RPM_BUILD_ROOT%_datadir/%name/theme
mkdir -p $RPM_BUILD_ROOT%{_datarootdir}/applications

install -p -m755 projman $RPM_BUILD_ROOT%_bindir/%name
install -p -m755 tkregexp.tcl $RPM_BUILD_ROOT%_bindir/tkregexp

# install -p -m644 *.tcl $RPM_BUILD_ROOT%_datadir/%name/
install -p -m644 lib/*.tcl $RPM_BUILD_ROOT%_datadir/%name/lib/
install -p -m644 lib/msgs/*.* $RPM_BUILD_ROOT%_datadir/%name/lib/msgs/
install -p -m644 theme/*.tcl $RPM_BUILD_ROOT%_datadir/%name/theme
install -p -m644 projman.desktop	$RPM_BUILD_ROOT%{_datarootdir}/applications

%post
%update_menus

%postun
%clean_menus

%files
%doc INSTALL CHANGELOG TODO LICENSE README.md
%_bindir/%name
%_bindir/tkregexp
%_datarootdir/applications/%name.desktop
%_datadir/%name


%changelog
* Mon Nov 28 2022 Sergey Kalinin <svk@nuk-svk.ru> 2.0.0
    - Initial release

