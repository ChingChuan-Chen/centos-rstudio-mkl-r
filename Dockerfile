FROM centos:7

ENV TZ=Asia/Taipei \
  R_VER=3.4.4 \
  PCRE_VER=8.42 ICU_VER=61.1 LIBPNG_VER=1.6.36 \
  CAIRO_VER=1.15.14 ICONV_VER=1.15 READLINE_VER=6.3 \
  CRAN_URL=https://cran.rstudio.com/

# setup timezone, install cjk fonts, mkl, devtoolset-7 and deps of R
## x11, libX* is X device
## libtiff-devel libjpeg-turbo-devel cairo-devel for images
## pango-devel must be installed to use cairo as default device
## zlib-devel bzip2-devel xz-devel for compression/decompression
## tcl-devel tk-devel to support tcltk
## pcre-devel for regular expression with Perl
## libicu-devel for Unicode
## readline-devel for automatic complete
## texlive texlive-preprint texinfo-tex for manual
## pigz pxz for parallel compression/decompression
## libssh2-devel openssl-devel libcurl-devel readline-devel cyrus-sasl-devel for 
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
  yum install -y wget google-noto-cjk-fonts adobe-source-han-sans-twhk-fonts epel-release centos-release-scl && \
  yum-config-manager --add-repo https://yum.repos.intel.com/setup/intelproducts.repo && \
  yum-config-manager --enable rhel-server-rhscl-7-rpms && \
  rm -rf /var/cache/yum/ && yes | yum makecache fast && \
  yum install -y intel-mkl-64bit devtoolset-7 && \
  echo "/opt/intel/mkl/lib/intel64" >> /etc/ld.so.conf.d/intel.conf && ldconfig && \
  yum install -y xorg-x11-server-devel libX11-devel libXt-devel libXmu-devel libXext-devel libssh2-devel openssl-devel libcurl-devel readline-devel cyrus-sasl-devel nlopt-devel libquadmath-devel pcre-devel tcl-devel tk-devel zlib-devel bzip2-devel xz-devel libicu-devel libxml2-devel libtiff-devel libjpeg-turbo-devel cairo-devel pango-devel texlive texlive-preprint texinfo-tex pigz pxz java-1.8.0-openjdk-devel unzip

# build some deps from source
ENV PATH=/opt/rh/devtoolset-7/root/usr/bin/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  LD_LIBRARY_PATH=/opt/rh/devtoolset-7/root/usr/lib64:/opt/rh/devtoolset-7/root/usr/lib:/usr/lib64:/usr/lib:/usr/local/lib64:/usr/local/lib
WORKDIR /R-deps
RUN wget -q http://download.icu-project.org/files/icu4c/${ICU_VER}/icu4c-${ICU_VER/./_}-src.tgz && \
  # install ICU \
  tar zxf icu4c-${ICU_VER/./_}-src.tgz && \
  cd icu/source && \
  ./configure --prefix=/usr --libdir=/usr/lib64 && \
  make -j${nproc} && make install && cd .. && \
  # install libiconv \
  wget -q https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${ICONV_VER}.tar.gz && \
  tar zxf libiconv-${ICONV_VER}.tar.gz && \
  cd libiconv-${ICONV_VER} && \
  ./configure --prefix=/usr --libdir=/usr/lib64 && \
  make -j${nproc} && make install && cd .. && \
  # install readline \
  wget -q ftp://ftp.gnu.org/gnu/readline/readline-${READLINE_VER}.tar.gz && \
  tar zxf readline-${READLINE_VER}.tar.gz && \
  cd readline-${READLINE_VER} && \
  ./configure --prefix=/usr --libdir=/usr/lib64 && \
  make -j${nproc} && make install && cd .. && \
  # install PCRE \
  wget -q ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${PCRE_VER}.tar.gz && \
  tar zxf pcre-${PCRE_VER}.tar.gz && \ 
  cd pcre-${PCRE_VER} && \
  ./configure --prefix=/usr --libdir=/usr/lib64 --enable-pcre16 --enable-pcre32 --enable-utf --enable-pcregrep-libz --enable-pcregrep-libbz2 --enable-pcretest-libreadline --enable-unicode-properties && \
  make -j${nproc} && make install && cd .. && \
  # install libpng \
  wget -q https://download.sourceforge.net/libpng/libpng-${LIBPNG_VER}.tar.xz && \
  tar Jxf libpng-${LIBPNG_VER}.tar.xz && \
  cd libpng-${LIBPNG_VER} && \
  ./configure --prefix=/usr --libdir=/usr/lib64 && \
  make -j${nproc} && make install && cd .. && \
  # install CAIRO \
  wget -q https://www.cairographics.org/snapshots/cairo-${CAIRO_VER}.tar.xz && \
  tar Jxf cairo-${CAIRO_VER}.tar.xz && \
  cd cairo-${CAIRO_VER} && \
  ./configure --prefix=/usr --libdir=/usr/lib64 && \
  make -j${nproc} && make install && cd .. && \
  # install inconsolata.sty for compiling R manual \
  yum install -y levien-inconsolata-fonts && \
  wget -q http://mirrors.ctan.org/install/fonts/inconsolata.tds.zip && \
  mkdir inconsolata && \
  unzip inconsolata.tds.zip -d inconsolata && \
  cp -r inconsolata/* /usr/share/texmf && \
  printf 'Map zi4.map\n' >> /usr/share/texlive/texmf-dist/web2c/updmap.cfg && \
  mktexlsr && yes | updmap-sys --enable Map=zi4.map --syncwithtrees --force

# compile R
WORKDIR /R-deps
RUN wget --no-check-certificate -q https://cran.r-project.org/src/base/R-3/R-${R_VER}.tar.gz && \
  tar zxvf R-${R_VER}.tar.gz && \
  cd R-${R_VER} && \
  export MKLROOT=/opt/intel/compilers_and_libraries/linux && \
  export LD_LIBRARY_PATH=${MKLROOT}/mkl/lib/intel64 && \
  export MKL="-L${MKLROOT}/mkl/lib/intel64 -lmkl_gf_lp64 -lmkl_gnu_thread -lmkl_core -fopenmp -lpthread -ldl -lm" && \
  export CFLAGS="-std=gnu99 -g -O3 -march=native -DU_STATIC_IMPLEMENTATION" && \
  export CXXFLAGS="-g -O3 -march=native -DU_STATIC_IMPLEMENTATION" && \
  export CXXSTD=-std=gnu++98 && \
  ./configure --prefix=/usr --libdir=/usr/lib64 --with-cairo --with-x --enable-R-shlib --enable-shared --enable-R-profiling --enable-BLAS-shlib --enable-memory-profiling --with-blas="$MKL" --with-lapack --with-tcl-config=/usr/lib64/tcl8.5/tclConfig.sh --with-tk-config=/usr/lib64/tkConfig.sh --enable-prebuilt-html && \
  make -j${nproc} && make install && \
  groupadd ruser && \
  chown -R root:ruser /usr/lib64/R && \
  chmod -R g+w /usr/lib64/R && \
  cd / && rm -rf /R-deps

# install rstudio server and config
WORKDIR /
RUN RSTUDIO_VERSION=$(wget --no-check-certificate -qO- https://s3.amazonaws.com/rstudio-server/current.ver) && \
  wget -q https://download2.rstudio.org/rstudio-server-rhel-${RSTUDIO_VERSION}-x86_64.rpm && \
  yum install --nogpgcheck -y rstudio-server-rhel-${RSTUDIO_VERSION}-x86_64.rpm && \
  printf 'Sys.setenv(PATH = paste0("/opt/rh/devtoolset-7/root/usr/bin:", Sys.getenv("PATH")),LD_LIBRARY_PATH = paste0("/opt/rh/devtoolset-7/root/usr/lib64:", Sys.getenv("LD_LIBRARY_PATH")))\n' >> /usr/lib/rstudio-server/R/ServerOptions.R && \
  printf "r-libs-user=/usr/lib64/R/library\nsession-timeout-minutes=0\\nr-cran-repos=${CRAN_URL}\n" >> /etc/rstudio/rsession.conf && \
  rm -f *.rpm

# copy rstudio-setting
COPY docker-entrypoint.sh /rstudio-server/docker-entrypoint.sh
COPY keybindings /rstudio-server/keybindings
COPY user-settings /rstudio-server/user-settings
COPY benchmark.R /rstudio-server/benchmark.R

# add user and rstudio config
RUN useradd rstudio && \
  echo "rstudio:rstudio" | chpasswd && \
  usermod -a -G ruser rstudio && \
  mkdir -p /home/rstudio/.R/rstudio/keybindings && \
  cp /rstudio-server/keybindings/*.json /home/rstudio/.R/rstudio/keybindings/ && \
  mkdir -p /home/rstudio/.rstudio/monitored/user-settings && \
  cp /rstudio-server/user-settings/* /home/rstudio/.rstudio/monitored/user-settings/ && \
  cp /rstudio-server/benchmark.R /home/rstudio && \
  chown -R rstudio: /home/rstudio

EXPOSE 8787
ENTRYPOINT ["/rstudio-server/docker-entrypoint.sh"]
CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize", "0", "--rsession-which-r", "/usr/lib64/R/bin/R", "--auth-required-user-group", "ruser"]

