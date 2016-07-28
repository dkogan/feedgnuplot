# Sample spec file for rpm-based systems. Debian-based systems already have this
# packaged, so we do not ship those here

Name:           feedgnuplot
Version:        1.38
Release:        1%{?dist}
Summary:        Pipe-oriented frontend to Gnuplot
BuildArch:      noarch

License:        Artistic or GPL-1+
URL:            https://www.github.com/dkogan/feedgnuplot/
Source0:        https://www.github.com/dkogan/feedgnuplot/archive/v%{version}.tar.gz#/%{name}-%{version}.tar.gz

BuildRequires:  /usr/bin/pod2html
BuildRequires:  perl-String-ShellQuote
BuildRequires:  perl-ExtUtils-MakeMaker
BuildRequires:  perl
BuildRequires:  gawk
BuildRequires:  gnuplot
BuildRequires:  perl-IPC-Run

Requires:       gnuplot

%description
Flexible, command-line-oriented frontend to Gnuplot. Creates plots from data
coming in on STDIN or given in a filename passed on the commandline. Various
data representations are supported, as is hardcopy output and streaming display
of live data.

%prep
%setup -q

%build
perl Makefile.PL INSTALLDIRS=vendor
make
pod2html --title=feedgnuplot bin/feedgnuplot > feedgnuplot.html

%install
make install DESTDIR=%{buildroot} PREFIX=/usr

mkdir -p %{buildroot}%{_defaultdocdir}/%{name}
cp Changes LICENSE feedgnuplot.html %{buildroot}%{_defaultdocdir}/%{name}

mkdir -p %{buildroot}%{_datadir}/zsh/site-functions
cp completions/zsh/* %{buildroot}%{_datadir}/zsh/site-functions

mkdir -p %{buildroot}%{_datadir}/bash-completion/completions
cp completions/bash/* %{buildroot}%{_datadir}/bash-completion/completions

rm -rf %{buildroot}/usr/lib64


%files
%{_bindir}/*
%{_datadir}/zsh/*
%{_datadir}/bash-completion/*
%doc %{_defaultdocdir}/%{name}/*
%doc %{_mandir}
