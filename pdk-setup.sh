#!/bin/bash
# ========================================================================
# Initialization of IIC Open-Source EDA Environment for OpenRule1umPDK
#
# SPDX-FileCopyrightText: 2023-2024 Mori Mizuki, Noritsuna Imamura 
# ISHI-KAI
# 
# SPDX-FileCopyrightText: 2021-2022 Harald Pretl, Johannes Kepler 
# University, Institute for Integrated Circuits
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0
#
# This script installs xschem, ngspice, magic, netgen, klayout
# and a few other tools for use with OpenRule1umPDK.
# This script supports WSL(Windows Subsystem for Linux), Ubuntu 22.04, Mac M core series.
# ========================================================================

# Define setup environment
# ------------------------
export SRC_DIR="$HOME/src"
my_path=$(realpath "$0")
my_dir=$(dirname "$my_path")
export SCRIPT_DIR="$my_dir"
export KLAYOUT_VERSION=0.29.5

# for Mac
export MAC_OS_NAME=Sonoma
export TCL_VERSION=8.6.14
export TK_VERSION=8.6.14
export GTK_VERSION=3.24.42
export CC_VERSION=-14
export CXX_VERSION=-14

# ---------------
# Now go to work!
# ---------------

# Update installation
# ----------------------------------
# the sed is needed for xschem build
echo ">>>> Update packages"
if [ "$(uname)" == 'Darwin' ]; then
  OS='Mac'
  if [ ! -d "/opt/homebrew" ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> $HOME/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  brew update
  brew install wget
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
  OS='Linux'
  sudo sed -i 's/# deb-src/deb-src/g' /etc/apt/sources.list
  sudo apt -qq update -y
  sudo apt -qq upgrade -y
elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then
  OS='Cygwin'
  echo "Your platform ($(uname -a)) is not supported."
  exit 1
else
  echo "Your platform ($(uname -a)) is not supported."
  exit 1
fi
cd $SRC_DIR


# Copy KLayout Configurations
# ----------------------------------
if [ ! -d "$HOME/.klayout" ]; then
  mkdir -p $HOME/.klayout/salt
  mkdir $HOME/.klayout/macros
  mkdir $HOME/.klayout/drc
  mkdir $HOME/.klayout/pymacros
  mkdir $HOME/.klayout/libraries
fi


# Install basic tools via apt
# ------------------------------------------
echo ">>>> Installing required packages via APT"
if [ "$(uname)" == 'Darwin' ]; then
  OS='Mac'
  python3 -m pip install --upgrade pip
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
  OS='Linux'
  sudo apt -qq install -y build-essential python3-pip
elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then
  OS='Cygwin'
  echo "Your platform ($(uname -a)) is not supported."
  exit 1
else
  echo "Your platform ($(uname -a)) is not supported."
  exit 1
fi
python3 -m pip install --upgrade --no-cache-dir volare


# Install/update xschem
# ---------------------
if [ ! -d "$SRC_DIR/xschem" ]; then
  echo ">>>> Installing xschem"
  if [ "$(uname)" == 'Darwin' ]; then
    OS='Mac'
    brew install libx11
    brew install libxpm
    brew install gawk
    brew install macvim
    brew install dbus
    brew install --cask xquartz
    brew install libglu freeglut

    cd $SRC_DIR
    wget https://prdownloads.sourceforge.net/tcl/tcl$TCL_VERSION-src.tar.gz
    tar xfz tcl$TCL_VERSION-src.tar.gz
    rm tcl$TCL_VERSION-src.tar.gz
    cd tcl$TCL_VERSION/unix
    ./configure
    make -j$(nproc)
    sudo make install
    make clean

    cd $SRC_DIR
    wget https://prdownloads.sourceforge.net/tcl/tk$TK_VERSION-src.tar.gz
    tar xfz tk$TK_VERSION-src.tar.gz
    rm tk$TK_VERSION-src.tar.gz
    cd tk$TK_VERSION/unix
    ./configure
    make -j$(nproc)
    sudo make install
    make clean
  elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
    OS='Linux'
    sudo apt -qq install -y xterm graphicsmagick ghostscript \
    libx11-6 libx11-dev libxrender1 libxrender-dev \
    libxcb1 libx11-xcb-dev libcairo2 libcairo2-dev  \
    tcl8.6 tcl8.6-dev tk8.6 tk8.6-dev \
    flex bison libxpm4 libxpm-dev gawk tcl-tclreadline
  elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then
    OS='Cygwin'
    echo "Your platform ($(uname -a)) is not supported."
    exit 1
  else
    echo "Your platform ($(uname -a)) is not supported."
    exit 1
  fi
  git clone https://github.com/StefanSchippers/xschem.git "$SRC_DIR/xschem"
  cd "$SRC_DIR/xschem" || exit
  ./configure
else
  echo ">>>> Updating xschem"
  cd "$SRC_DIR/xschem" || exit
  git pull
fi
make clean
make -j"$(nproc)" && sudo make install
make clean


# Install/update xschem-gaw
# -------------------------
if [ ! -d "$SRC_DIR/xschem-gaw" ]; then
  echo ">>>> Installing gaw"
  if [ "$(uname)" == 'Darwin' ]; then
    OS='Mac'
    brew install pkg-config
    brew install automake
    brew install autoconf
    brew install gtk+3
    gettextize -f

    cd $SRC_DIR
    wget https://download.gnome.org/sources/gtk+/3.24/gtk%2B-$GTK_VERSION.tar.xz
    tar xfj gtk+-$GTK_VERSION.tar.xz
    rm gtk+-$GTK_VERSION.tar.xz
    cd gtk+-$GTK_VERSION/
    cd gdk
    sudo mkdir /usr/local/include/gdk/
    sudo cp *.h /usr/local/include/gdk/
    cd x11
    sudo mkdir /usr/local/include/gdk/x11/
    sudo cp *.h /usr/local/include/gdk/x11/

  elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
    OS='Linux'
    sudo apt -qq install -y libgtk-3-dev alsa libasound2-dev gettext libtool
  elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then
    OS='Cygwin'
    echo "Your platform ($(uname -a)) is not supported."
    exit 1
  else
    echo "Your platform ($(uname -a)) is not supported."
    exit 1
  fi
  git clone https://github.com/StefanSchippers/xschem-gaw.git "$SRC_DIR/xschem-gaw"
  cd "$SRC_DIR/xschem-gaw" || exit
   aclocal && automake --add-missing && autoconf
  if [ "$(uname)" == 'Darwin' ]; then
    OS='Mac'
#    export LDFLAGS="-L/usr/X11/lib $LDFLAGS"
    sed -i '' 's/GETTEXT_MACRO_VERSION = 0.18/GETTEXT_MACRO_VERSION = 0.20/g' po/Makefile.in.in
    ./configure --enable-gawsound=no LDFLAGS="-L/usr/X11/lib"
  elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
    OS='Linux'
    #  FIXME this is just a WA for 22.04 LTS
    sed -i 's/GETTEXT_MACRO_VERSION = 0.18/GETTEXT_MACRO_VERSION = 0.20/g' po/Makefile.in.in
    ./configure
  fi
else
  echo ">>>> Updating gaw"
  cd "$SRC_DIR/xschem-gaw" || exit
  git pull
fi
make clean
make -j"$(nproc)" && sudo make install
make clean

# Install/Update KLayout
# ---------------------
echo ">>>> Installing KLayout-$KLAYOUT_VERSION"
if [ "$(uname)" == 'Darwin' ]; then
  OS='Mac'
  python3 -m pip install docopt pandas scipy matplotlib pip-autoremove --break-system-packages
#  brew install klayout
#  wget https://www.klayout.org/downloads/MacOS/HW-klayout-$KLAYOUT_VERSION-macOS-$MAC_OS_NAME-1-qt5MP-RsysPhb311.dmg
#  hdiutil mount HW-klayout-$KLAYOUT_VERSION-macOS-$MAC_OS_NAME-1-qt5MP-RsysPhb311.dmg
#  cd /Volumes/KLayout/
#  hdiutil detach /Volumes/KLayout/
  if [ ! -d "$SRC_DIR/klayout" ]; then
    echo ">>>> Building klayout"
    brew install qt5
    brew install libgit2
    git clone https://github.com/KLayout/klayout.git "$SRC_DIR/klayout"
    cd "$SRC_DIR/klayout" || exit
  else
    echo ">>>> Updating klayout"
    cd "$SRC_DIR/klayout" || exit
    git pull
  fi
  python3 build4mac.py -r HB33 -p HBAuto -q Qt5Brew -m ‘—jobs=8’ -n -u
  mkdir -p $HOME/bin/klayout.app
  cp -aR   cd $SRC_DIR/klayout/qt5Brew.bin.macos-Sonoma-release-Rhb33Phbauto/* $HOME/bin/klayout.app/
  echo 'export PATH="$HOME/bin/:$PATH"' >> ~/.zshrc
  export PATH="$HOME/bin/:$PATH"
  cp $my_dir/klayout.sh $HOME/bin/
  chmod +x $HOME/bin/klayout.sh
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
  OS='Linux'
  wget https://www.klayout.org/downloads/Ubuntu-22/klayout_$KLAYOUT_VERSION-1_amd64.deb
  sudo apt -qq install -y ./klayout_$KLAYOUT_VERSION-1_amd64.deb
  rm klayout_$KLAYOUT_VERSION-1_amd64.deb
  pip install docopt pandas pip-autoremove
elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then
  OS='Cygwin'
  echo "Your platform ($(uname -a)) is not supported."
  exit 1
else
  echo "Your platform ($(uname -a)) is not supported."
  exit 1
fi


# Install/update magic
# --------------------
if [ ! -d "$SRC_DIR/magic" ]; then
  echo ">>>> Installing magic"
  if [ "$(uname)" == 'Darwin' ]; then
    OS='Mac'
  elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
    OS='Linux'
    sudo apt -qq install -y m4 tcsh csh libx11-dev tcl-dev tk-dev \
    libcairo2-dev mesa-common-dev libglu1-mesa-dev
  elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then                                                                                           
    OS='Cygwin'
    echo "Your platform ($(uname -a)) is not supported."
    exit 1
  else
    echo "Your platform ($(uname -a)) is not supported."
    exit 1
  fi
  git clone https://github.com/RTimothyEdwards/magic.git "$SRC_DIR/magic"
  cd "$SRC_DIR/magic" || exit
  git checkout magic-8.3
  ./configure
else
  echo ">>>> Updating magic"
  cd "$SRC_DIR/magic" || exit
  git pull
fi
make clean
make && sudo make install
make clean


# Install/update netgen
# ---------------------
if [ ! -d "$SRC_DIR/netgen" ]; then
  echo ">>>> Installing netgen"
  git clone https://github.com/RTimothyEdwards/netgen.git "$SRC_DIR/netgen"
  cd "$SRC_DIR/netgen" || exit
  git checkout netgen-1.5
  ./configure
else
  echo ">>>> Updating netgen"
  cd "$SRC_DIR/netgen" || exit
  git pull
fi
make clean
make -j"$(nproc)" && sudo make install
make clean


# Install/update ngspice
# ----------------------
if [ ! -d "$SRC_DIR/ngspice" ]; then
  echo ">>>> Installing ngspice"
  if [ "$(uname)" == 'Darwin' ]; then
    OS='Mac'
    brew install libtool
    brew install libxft
    brew install libmux
    brew install libxaw
    brew install fftw
    brew install bison
    brew install bazel
    brew install flex
    brew install lex
    brew install fontconfig
    brew install m4
#    echo 'export PATH="/opt/homebrew/opt/m4/bin:$PATH"' >> ~/.zshrc    
    export PATH="/opt/homebrew/opt/m4/bin:$PATH"
    brew link bison --force
#    echo 'export PATH="/opt/homebrew/opt/bison/bin:$PATH"' >> ~/.zshrc
#    export PATH="/opt/homebrew/opt/bison/bin:$PATH"
#    export LDFLAGS="-L/opt/homebrew/opt/bison/lib $LDFLAGS"
    brew install libomp
  elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
    OS='Linux'
    sudo apt -qq install -y libxaw7-dev libxmu-dev libxext-dev libxft-dev \
    libfontconfig1-dev libxrender-dev libfreetype6-dev libx11-dev libx11-6 \
    libtool bison flex libreadline-dev libfftw3-dev 
  elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then                                                                                           
    OS='Cygwin'
    echo "Your platform ($(uname -a)) is not supported."
    exit 1
  else
    echo "Your platform ($(uname -a)) is not supported."
    exit 1
  fi

  git clone http://git.code.sf.net/p/ngspice/ngspice "$SRC_DIR/ngspice"
  cd "$SRC_DIR/ngspice" || exit
  ./autogen.sh

  if [ "$(uname)" == 'Darwin' ]; then
    OS='Mac'
    ./configure --disable-debug --with-readline=no --enable-openmp --with-x CXX="g++$CXX_VERSION" CC="gcc$CC_VERSION" CFLAGS="-m64 -O2 -Wno-error=implicit-function-declaration -Wno-error=implicit-int" CPPFLAGS="-I/opt/homebrew/opt/freetype2/include/freetype2/ -I/opt/homebrew/opt/libomp/include/" LDFLAGS="-m64 -s -L/opt/homebrew/opt/freetype2/lib/ -L/opt/homebrew/opt/fontconfig/lib/ -L/opt/homebrew/opt/libomp/lib/ -L/usr/X11/lib/"
    sed -i '' 's/TCGETS/TIOCMGET/g' src/frontend/parser/complete.c
    sed -i '' 's/TCSETS/TIOCMSET/g' src/frontend/parser/complete.c
    sed -i '' 's/LEX = :/LEX = lex/g' src/xspice/cmpp/Makefile
  elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
    OS='Linux'
    ./configure --disable-debug --with-readline=yes --enable-openmp CFLAGS="-m64 -O2" LDFLAGS="-m64 -s" 
  elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then                                                                                           
    OS='Cygwin'
    echo "Your platform ($(uname -a)) is not supported."
    exit 1
  else
    echo "Your platform ($(uname -a)) is not supported."
    exit 1
  fi
else
  echo ">>>> Updating ngspice"
        cd "$SRC_DIR/ngspice" || exit
        git pull
  export PATH="/opt/homebrew/opt/m4/bin:$PATH"
fi
make clean
make -j"$(nproc)" && sudo make install
make clean


# setup gnome-terminal (WA for Ubuntu 24 WSL2)
# --------
if [ "$(uname)" == 'Darwin' ]; then
  OS='Mac'
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
  OS='Linux'
  sudo apt -qq install -y gnome-terminal
  systemctl --user start gnome-terminal-server
fi


# setup OpenRule1umPDK
# ----------------------------------
if [ ! -d "$SRC_DIR/OpenRule1um" ]; then
  cd $SRC_DIR
  git clone  https://github.com/mineda-support/OpenRule1um.git
  cp -aR OpenRule1um $HOME/.klayout/salt/
else
  echo ">>>> Updating OpenRule1um"
  cd $SRC_DIR/OpenRule1um || exit
  git pull
  cp -aR ./* $HOME/.klayout/salt/OpenRule1um/
fi
if [ ! -d "$SRC_DIR/AnagixLoader" ]; then
  cd $SRC_DIR
  git clone  https://github.com/mineda-support/AnagixLoader.git
  cp -aR AnagixLoader $HOME/.klayout/salt/
else
  echo ">>>> Updating AnagixLoader"
  cd $SRC_DIR/AnagixLoader || exit
  git pull
  cp -aR ./* $HOME/.klayout/salt/AnagixLoader/
fi

if [ ! -d "$HOME/.xschem/symbols" ]; then
  mkdir -p $HOME/.xschem/symbols
else
  cd $my_dir
  cp xschem/xschemrc_PTC06 $HOME/.xschem/xschemrc
  cp xschem/title_PTC06.sch $HOME/.xschem/title_PTC06.sch
  cp -aR ./xschem/symbols/* $HOME/.xschem/symbols/
  cp -aR ./xschem/lib/* $HOME/.xschem/lib/
fi

if [ ! -d "$HOME/.klayout/macros" ]; then
  mkdir -p $HOME/.klayout/macros
else
  cd $my_dir
  cp -aR ./klayout/macros/* $HOME/.klayout/macros/
fi
cd $my_dir
cp -f ./klayout/klayoutrc $HOME/.klayout/klayoutrc


# Install GDSfactory
# -----------------------------------
if [ "$(uname)" == 'Darwin' ]; then
  OS='Mac'
  python3 -m pip install gdsfactory pip-autoremove --break-system-packages
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
  OS='Linux'
  pip install gdsfactory
elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then
  OS='Cygwin'
  echo "Your platform ($(uname -a)) is not supported."
  exit 1
else
  echo "Your platform ($(uname -a)) is not supported."
  exit 1
fi


# Finished
# --------
echo ""
echo ">>>> All done."
echo ""
