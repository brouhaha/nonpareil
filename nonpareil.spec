# RPM spec file for Nonpareil
# Copyright 2005 Eric L. Smith <eric@brouhaha.com>
# $Id$

Name: nonpareil
Summary: Microcode-level calculator simulator
Version: @version@
Release: 1
License: GPL
Group: Applications/Productivity
URL: http://nonpareil.brouhaha.com/
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildPrereq: scons
BuildPrereq: python

%description
Nonpareil simulates many HP calculator models introduced between
1972 and 1982, including the HP-35, HP-25, HP-34C, HP-38C, HP-41CX,
HP-11C, HP-12C, HP-15C, HP-16C, and other models.
 
%prep
%setup -q

%build
scons

%install
scons install
rm -rf %{buildroot}

%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%doc


%changelog
* Sat May 28 2005 Eric Smith <eric@brouhaha.com> - 
- Initial build.

