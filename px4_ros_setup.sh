#!/bin/bash

# ==============================================================================
# PX4 and ROS 2 Humble Installation Script for Ubuntu 22.04
# ==============================================================================
# This script automates the installation of PX4 Autopilot and ROS 2 Humble
# based on the provided guide.
#
# IMPORTANT:
# - Run this script with a user that has sudo privileges.
# - The script will prompt for your password when 'sudo' is used.
# - Some steps require a system restart. The script will prompt you.
#   You will need to RE-RUN the script after rebooting. It's designed
#   to be mostly idempotent, but it's best to run it until it completes
#   without exiting early.
# - It's HIGHLY recommended to read through the script before running it.
# - No guarantees! Use at your own risk.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to prompt for reboot
prompt_reboot() {
  echo ""
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "!!! A SYSTEM RESTART IS REQUIRED for changes to take effect. !"
  echo "!!! Please save your work, run 'sudo reboot now', and then   !"
  echo "!!! RE-RUN THIS SCRIPT to continue the installation.         !"
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  read -p "Press Enter to exit the script now..."
  exit 1
}

# Keep track if a reboot happened
REBOOT_MARKER_FILE="/tmp/px4_ros_install_rebooted"

echo "========================================="
echo "Starting PX4 and ROS 2 Humble Installation"
echo "========================================="

# --- Step 1: Initial System Update and Essential Tools ---
echo ""
echo "--- Step 1: Initial System Update and Essential Tools ---"
sudo apt update
sudo apt install git curl -y
sudo apt upgrade -y
echo "Initial update and tools installation complete."

# Check if first reboot is needed
if [ ! -f "$REBOOT_MARKER_FILE.1" ]; then
  touch "$REBOOT_MARKER_FILE.1"
  prompt_reboot
fi
echo "System has been rebooted once, continuing..."


# --- Step 2: Install PX4 Autopilot Source Code ---
echo ""
echo "--- Step 2: Install PX4 Autopilot Source Code ---"
cd ~
if [ ! -d "PX4-Autopilot" ]; then
  echo "Cloning PX4-Autopilot repository (this may take a while)..."
  git clone https://github.com/PX4/PX4-Autopilot.git --recursive
else
  echo "PX4-Autopilot directory already exists, skipping clone."
fi

echo "Running PX4 setup script..."
bash ./PX4-Autopilot/Tools/setup/ubuntu.sh

echo "PX4 setup script finished."

# Check if second reboot is needed
if [ ! -f "$REBOOT_MARKER_FILE.2" ]; then
  touch "$REBOOT_MARKER_FILE.2"
  prompt_reboot
fi
echo "System has been rebooted twice, continuing..."

# --- Step 3: Install QGroundControl Requirements & Download ---
echo ""
echo "--- Step 3: Install QGroundControl Requirements & Download ---"
echo "Adding current user ($USER) to the dialout group..."
sudo usermod -a -G dialout $USER
echo "Removing modemmanager..."
sudo apt-get remove modemmanager -y || echo "modemmanager not found, skipping."
echo "Installing GStreamer plugins and libraries..."
sudo apt install gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl -y
sudo apt install libfuse2 -y
sudo apt install libxcb-xinerama0 libxkbcommon-x11-0 libxcb-cursor-dev -y

cd ~
if [ ! -f "QGroundControl.AppImage" ]; then
  echo "Downloading QGroundControl.AppImage..."
  wget https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl.AppImage
  sudo chmod +x ./QGroundControl.AppImage
else
  echo "QGroundControl.AppImage already exists, skipping download."
  sudo chmod +x ./QGroundControl.AppImage # Ensure it's executable
fi
echo "QGroundControl setup complete. You can run it with './QGroundControl.AppImage'."

# --- Step 4: Install ROS 2 Humble Hawksbill ---
echo ""
echo "--- Step 4: Install ROS 2 Humble Hawksbill ---"
echo "Setting locale..."
sudo apt update && sudo apt install locales -y
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

echo "Enabling Ubuntu Universe Repository and adding ROS 2 key..."
sudo apt install software-properties-common -y
sudo add-apt-repository universe -y
sudo apt update && sudo apt install curl -y
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

echo "Adding ROS 2 repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

echo "Updating and upgrading packages..."
sudo apt update
sudo apt upgrade -y

echo "Installing ROS 2 Desktop and Dev Tools..."
sudo apt install ros-humble-desktop -y
sudo apt install ros-dev-tools -y

echo "Sourcing ROS 2 setup and adding to .bashrc..."
# Check if source line already exists in .bashrc
if ! grep -q "source /opt/ros/humble/setup.bash" ~/.bashrc; then
  echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
fi
source /opt/ros/humble/setup.bash

echo "Installing essential Python packages..."
pip install --user -U empy==3.3.4 pyros-genmsg setuptools

echo "Installing ROS Gazebo bridge..."
sudo apt install ros-humble-ros-gzharmonic -y

echo "ROS 2 Humble installation complete."

# --- Step 5: Install Micro XRCE-DDS Agent ---
echo ""
echo "--- Step 5: Install Micro XRCE-DDS Agent ---"
cd ~
if [ ! -d "Micro-XRCE-DDS-Agent" ]; then
  echo "Cloning Micro-XRCE-DDS-Agent repository..."
  git clone -b v2.4.2 https://github.com/eProsima/Micro-XRCE-DDS-Agent.git
else
  echo "Micro-XRCE-DDS-Agent directory already exists, skipping clone."
fi

echo "Building and installing Micro-XRCE-DDS-Agent..."
cd Micro-XRCE-DDS-Agent
# Only create build dir if it doesn't exist
if [ ! -d "build" ]; then
  mkdir build
fi
cd build
cmake ..
make
sudo make install
sudo ldconfig /usr/local/lib/

echo "Micro XRCE-DDS Agent installation complete."

# --- Step 7: Build PX4-ROS 2 Communication Workspace ---
echo ""
echo "--- Step 7: Build PX4-ROS 2 Communication Workspace ---"
echo "Creating ROS 2 workspace..."
mkdir -p ~/ws_sensor_combined/src
cd ~/ws_sensor_combined/src

echo "Installing setuptools 65.5.1..."
pip install --user setuptools==65.5.1

echo "Cloning px4_msgs and px4_ros_com repositories..."
if [ ! -d "px4_msgs" ]; then
  git clone https://github.com/PX4/px4_msgs.git
else
  echo "px4_msgs directory already exists, skipping clone."
fi
if [ ! -d "px4_ros_com" ]; then
  git clone https://github.com/PX4/px4_ros_com.git
else
  echo "px4_ros_com directory already exists, skipping clone."
fi

echo "Building the workspace with colcon..."
cd ~/ws_sensor_combined/
source /opt/ros/humble/setup.bash
colcon build

echo "Adding workspace setup to .bashrc..."
# Check if source line already exists in .bashrc
if ! grep -q "source ~/ws_sensor_combined/install/setup.bash" ~/.bashrc; then
  echo "source ~/ws_sensor_combined/install/setup.bash" >> ~/.bashrc
fi

echo "PX4-ROS 2 Workspace build complete."

# --- Final Cleanup and Notes ---
echo ""
echo "========================================="
echo "      INSTALLATION COMPLETE! 🚀"
echo "========================================="
echo ""
echo "What's next?"
echo "------------"
echo "1. IMPORTANT: Close this terminal and open a NEW one for all changes"
echo "   (especially .bashrc additions) to take effect."
echo "2. To run the PX4 SITL simulation:"
echo "   cd ~/PX4-Autopilot/"
echo "   make px4_sitl gz_x500"
echo "3. In ANOTHER new terminal, run the Micro XRCE-DDS Agent:"
echo "   MicroXRCEAgent udp4 -p 8888"
echo "4. In a THIRD new terminal, run the ROS 2 listener example:"
echo "   cd ~/ws_sensor_combined/"
echo "   source install/setup.bash"
echo "   ros2 launch px4_ros_com sensor_combined_listener.launch.py"
echo "5. To run QGroundControl (optional, from your home directory):"
echo "   ./QGroundControl.AppImage"
echo ""
echo "Remember to run these in separate terminals as needed."
echo "Enjoy your PX4 and ROS 2 setup! 😊"

# Clean up marker files
rm -f $REBOOT_MARKER_FILE.1 $REBOOT_MARKER_FILE.2

exit 0
