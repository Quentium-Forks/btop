Name:           btop
Version:        1.4.7
Release:        1%{?dist}
Summary:        Resource monitor that shows usage and stats for processor, memory, disks, network and processes.

License:        GPLv3
URL:            https://github.com/Quentium-Forks/btop
Source0:        %{name}-%{version}.tar.gz

BuildArch:      x86_64
Requires:       lowdown glibc systemd

%description
Resource monitor that shows usage and stats for processor, memory, disks, network and processes.
C++ version and continuation of bashtop and bpytop.

%prep
%setup -q

%build
cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=%{_prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBTOP_GPU=ON \
    -DBUILD_TESTING=OFF

cmake --build build -j $(nproc)

%install
rm -rf %{buildroot}

DESTDIR=%{buildroot} cmake --install build

%files
%license LICENSE
%doc README.md
%{_bindir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/metainfo/io.github.aristocratos.%{name}.metainfo.xml
%{_datadir}/icons/hicolor/48x48/apps/%{name}.png
%{_datadir}/icons/hicolor/scalable/apps/%{name}.svg
%{_datadir}/%{name}/themes/*
%{_mandir}/man1/%{name}.1.*

%changelog
