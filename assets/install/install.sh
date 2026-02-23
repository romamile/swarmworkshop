#!/bin/bash

echo " == Installing packages"
sudo apt-get install -y build-essential cmake pkg-config libfreeimage-dev libfreeimageplus-dev \
  freeglut3-dev libxi-dev libxmu-dev liblua5.3-dev \
  lua5.3 doxygen graphviz libgraphviz-dev asciidoc \
  qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools qttools5-dev qttools5-dev-tools libqt5opengl5-dev


echo " == Installing ARGoS"

git clone https://github.com/ilpincy/argos3.git argos3

cd argos3
mkdir build_simulator
cd build_simulator
cmake ../src
make


# installation
make doc           # documentation is required!
sudo make install


echo " == Installing epuck plugin"
cd ../..
git clone https://github.com/demiurge-project/argos3-epuck argos3-epuck

cd argos3-epuck
mkdir build
cd build
cmake ../src
make

# installation
sudo make install


# Downloading assets
cd ../..
wget https://romamile.com/swlang/assets/setup/one_spot.png
wget https://romamile.com/swlang/assets/setup/expSetup.argos
