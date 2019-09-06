# To the extent possible under law, the author(s) have dedicated all
# copyright and related and neighboring rights to this software to the
# public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along
# with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

export ORIG_PATH=$PATH

make_winpath()
{
    P=$1
    if [ "$IN_CYGWIN" = "true" ]; then
        cygpath -d "$P"
    else
        (cd "$P" && /bin/cmd //C "for %i in (".") do @echo %~fsi")
    fi
}

make_upath()
{
    P=$1
    if [ "$IN_CYGWIN" = "true" ]; then
        cygpath "$P"
    else
        echo "$P" | /bin/sed 's,^\([a-zA-Z]\):\\,/\L\1/,;s,\\,/,g'
    fi
}

# Some common paths
if [ -x /usr/bin/msys-?.0.dll ]; then
  # Without this the path conversion won't work
  COMSPEC='C:\Windows\System32\cmd.exe'
  MSYSTEM=MINGW32  # Comment out this line if in MSYS2
  export MSYSTEM COMSPEC
  # For MSYS2: Change /mingw/bin to the msys bin dir on the line below
  PATH=/usr/local/bin:/mingw/bin:/bin:/c/Windows/system32:/c/Windows:/c/Windows/System32/Wbem
  C_DRV=/c
  IN_CYGWIN=false
else
  PATH=/ldisk/overrides:/usr/local/bin:/usr/bin:/bin:/usr/X11R6/bin:/cygdrive/c/windows/system32:/cygdrive/c/windows:/cygdrive/c/windows/system32/Wbem
  C_DRV=/cygdrive/c
  IN_CYGWIN=true
fi

obe_otp_gcc_vsn_map="
    .*=>default
"
obe_otp_64_gcc_vsn_map="
    .*=>default
"
# Program Files
PRG_FLS64=$C_DRV/Program\ Files
PRG_FLS32=$C_DRV/Program\ Files\ \(x86\)

# Visual Studio
VISUAL_STUDIO_ROOT=$PRG_FLS32/Microsoft\ Visual\ Studio\ 12.0
WIN_VISUAL_STUDIO_ROOT="C:\\Program Files (x86)\\Microsoft Visual Studio 12.0"

# SDK
SDK=$PRG_FLS32/Windows\ Kits/8.1
WIN_SDK="C:\\Program Files (x86)\\Windows Kits\\8.1"

# NSIS
NSIS_BIN=$PRG_FLS32/NSIS

# Java
JAVA_BIN=$PRG_FLS64/Java/jdk1.8.0_151/bin

## The PATH variable should be Cygwin'ish
VCPATH=$VISUAL_STUDIO_ROOT/VC/bin/amd64:$VISUAL_STUDIO_ROOT/VC/vcpackages:$VISUAL_STUDIO_ROOT/Common7/IDE:$VISUAL_STUDIO_ROOT/Common7/Tools:$SDK/bin/x86

## Microsoft SDK libs
LIBPATH=$WIN_VISUAL_STUDIO_ROOT\\VC\\lib\\amd64

LIB=$WIN_VISUAL_STUDIO_ROOT\\VC\\lib\\amd64\;$WIN_SDK\\lib\\winv6.3\\um\\x64

INCLUDE=$WIN_VISUAL_STUDIO_ROOT\\VC\\include\;$WIN_SDK\\include\\shared\;$WIN_SDK\\include\\um\;$WIN_SDK\\include\\winrt\;$WIN_SDK\\include\\um\\gl

# Put nsis, c compiler and java in path
export PATH=$VCPATH:$PATH:$JAVA_BIN:$NSIS_BIN:$ORIG_PATH

# Make sure LIB and INCLUDE is available for others
export LIBPATH LIB INCLUDE
