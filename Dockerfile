FROM devkitpro/devkitarm:20250728 AS build

RUN mkdir /docker_logs

# ----- Download library archives -----

WORKDIR /tmp

# CREATES citro3d-wyatt-james.zip
RUN wget https://github.com/Wyatt-James/citro3d/archive/ad2b990d867d97397d8151e62ac52b8de2b43f19.zip \
  -O citro3d-wyatt-james.zip && \
  echo F14B0B8E80BB5D900DDD3B68D38CA2660FFA3E66263EA103F469759AC477576C  citro3d-wyatt-james.zip | sha256sum --check

# CREATES libctru-wyatt-james.zip
RUN wget https://github.com/Wyatt-James/libctru/archive/cf29600389990e078bba757f2f1a46cdc939f11c.zip \
  -O libctru-wyatt-james.zip && \
  echo 4262393D4DF8F3F0FC02B49B0EB095070C3126A571E2610118E93BB4A129B693  libctru-wyatt-james.zip | sha256sum --check

# CREATES citro2d.zip
RUN wget https://github.com/devkitPro/citro2d/archive/147b02aae021da61b1f620446ad2892ecc45411e.zip \
  -O citro2d.zip && \
  echo 279C2E69570B494133E77EDE4279694E7E6EFF6B64E84E723710E934FC0B42EF  citro2d.zip | sha256sum --check

# ----- Extract archives in-place, removing commit-specific container folders -----
  
# CREATES citro3d-wyatt-james-temp, citro3d-wyatt-james
RUN unzip -d ./citro3d-wyatt-james-temp citro3d-wyatt-james.zip
RUN mv ./citro3d-wyatt-james-temp/citro3d-* ./citro3d-wyatt-james
  
# CREATES libctru-wyatt-james-temp, libctru-wyatt-james
RUN unzip -d ./libctru-wyatt-james-temp libctru-wyatt-james.zip
RUN mv ./libctru-wyatt-james-temp/libctru-* ./libctru-wyatt-james
  
# CREATES citro2d-temp, citro2d
RUN unzip -d ./citro2d-temp citro2d.zip
RUN mv ./citro2d-temp/citro2d-* ./citro2d

# ----- Install dependencies -----

# Install wyatt-james's fork of libctru. Use the longer line to build with GDB-optimized debug data included.
# Removing this will leave the official devkitPro version installed.
WORKDIR /tmp/libctru-wyatt-james/libctru
RUN make install GPUCMD_DISABLE_BOUNDS_CHECKS=1 GPUCMD_INLINE_THRESH=0 GPUCMD_ENABLE_ZERO_PADDING=0 ENABLE_LTO=1 > /docker_logs/make_libctru-wyatt-james.txt
# RUN make install ARCH="-ggdb -march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft" > /docker_logs/make_libctru-wyatt-james.txt

# Install wyatt-james's fork of Citro3D. Use the longer line to build with GDB-optimized debug data included.
# Removing this will leave the official devkitPro version installed.
WORKDIR /tmp/citro3d-wyatt-james
RUN make install GPUCMD_DISABLE_BOUNDS_CHECKS=1 GPUCMD_INLINE_THRESH=0 GPUCMD_ENABLE_ZERO_PADDING=0 ENABLE_PROFILER=0 ENABLE_LTO=1 > /docker_logs/make_citro3d-wyatt-james.txt
# RUN make install ENABLE_PROFILER=0 > /docker_logs/make_citro3d-wyatt-james.txt
# RUN make install ARCH="-ggdb -march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft" > /docker_logs/make_citro3d-wyatt-james.txt

# Citro2D must be rebuilt if building the fork of C3D.
# Removing this will leave the official devkitPro version installed.
WORKDIR /tmp/citro2d
RUN catnip install > /docker_logs/make_citro2d.txt

# ----- Clean up temporaries -----
WORKDIR /tmp
RUN rm citro3d-wyatt-james.zip
RUN rm libctru-wyatt-james.zip
RUN rm citro2d.zip
RUN rm -rf citro3d-wyatt-james-temp
RUN rm -rf citro3d-wyatt-james
RUN rm -rf libctru-wyatt-james-temp
RUN rm -rf libctru-wyatt-james
RUN rm -rf citro2d-temp
RUN rm -rf citro2d

# ----- Set up environment variables -----
ENV PATH="/opt/devkitpro/tools/bin/:${PATH}"
ENV DEVKITPRO=/opt/devkitpro
ENV DEVKITARM=/opt/devkitpro/devkitARM
ENV DEVKITPPC=/opt/devkitpro/devkitPPC

# ----- Navigate to final working directory -----
RUN mkdir /red-viper
WORKDIR /red-viper

# ----- How to build this Dockerfile -----

# Replace <yourname> with your screen name and <yourversion> with anything you'd like. Don't worry, nothing will be uploaded.

# build docker image: `docker build -t <yourname>/red-viper:<yourversion> - < ./Dockerfile`
# build Red Viper:    `docker run --rm -v $(pwd):/red-viper <yourname>/red-viper:<yourversion> make --jobs 8 VERSION=us`
