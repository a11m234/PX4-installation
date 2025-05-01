# Installing PX4 and ROS 2 Humble on Ubuntu 22.04

This guide details the steps to install the PX4 Autopilot software and ROS 2 Humble Hawksbill on Ubuntu 22.04 LTS.

## Prerequisites

* **Ubuntu 22.04 LTS:** A fresh installation is recommended.
    * **Dual Boot:** Generally preferred for better performance, especially for simulations. https://www.youtube.com/watch?v=QKn5U2esuRk.
    * **Virtual Machine (e.g., VirtualBox, VMware):** An alternative, but may have performance limitations. Ensure you allocate sufficient resources (CPU cores, RAM, disk space). https://www.youtube.com/watch?v=rJ9ysibH768.
* **Internet Connection:** Required for downloading packages and cloning repositories.
* **Basic Linux Terminal Knowledge:** Familiarity with navigating directories (`cd`) and running commands.

## Step 1: Initial System Update and Essential Tools

First, ensure your system is up-to-date and install essential tools like `git` (for version control) and `curl` (for transferring data).

1.  **Open a Terminal:** Press `Ctrl+Alt+T` or search for "Terminal".
2.  **Update Package Lists:**
    ```bash
    sudo apt update
    ```
3.  **Install Git & Curl:**
    ```bash
    sudo apt install git curl -y
    ```
    *(The `-y` flag automatically confirms the installation)*
4.  **Upgrade Installed Packages:**
    ```bash
    sudo apt upgrade -y
    ```
5.  **(Recommended) Restart:** It's often good practice to restart after significant updates.
    ```bash
    sudo reboot now
    ```

## Step 2: Install PX4 Autopilot Source Code

We will clone the PX4 source code from GitHub and run the official setup script to install dependencies.

1.  **Navigate to Home Directory:** Open a new terminal after rebooting.
    ```bash
    cd 
    ```
    
2.  **Clone the PX4 Repository:** This command downloads the PX4 source code and its submodules.
    ```bash
    git clone https://github.com/PX4/PX4-Autopilot.git --recursive
    ```
    * `--recursive` is crucial to download necessary submodules. This might take some time.*
3.  **Run the Ubuntu Setup Script:** This script installs all required dependencies for building and simulating PX4.
    ```bash
    bash ./PX4-Autopilot/Tools/setup/ubuntu.sh
    ```
    * *You might be prompted for your password multiple times.*
4.  **(Required) Restart Your System:** A restart is often necessary for all system changes (like group permissions) to take effect correctly.
    ```bash
    sudo reboot now
    ```

## Step 3: Build and Run PX4 SITL Simulation

Let's verify the PX4 installation by building and running a basic Software-In-The-Loop (SITL) simulation using Gazebo Garden (the default simulator).

1.  **Navigate to the PX4 Directory:** Open a terminal.
    ```bash
    cd ~/PX4-Autopilot
    ```
2.  **Build and Run Simulation:** This command compiles the PX4 firmware for SITL and launches the Gazebo simulator with an X500 quadcopter model.
    ```bash
    make px4_sitl gazebo-classic_x500
    ```
    * *The first build will take a significant amount of time.*
    * *You should see the Gazebo simulator window open with a drone model.*
    * *You can stop the simulation by pressing `Ctrl+C` in the terminal where you ran the `make` command.*

## Step 4: Install ROS 2 Humble Hawksbill

Now, we'll install ROS 2 Humble, the recommended ROS 2 version for Ubuntu 22.04.

1.  **Set Locale:** Ensure your system supports UTF-8.
    ```bash
    sudo apt update && sudo apt install locales -y
    sudo locale-gen en_US en_US.UTF-8
    sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
    export LANG=en_US.UTF-8
    ```
    * *You can check your locale settings with `locale`.*
2.  **Enable Ubuntu Universe Repository:**
    ```bash
    sudo apt install software-properties-common -y
    sudo add-apt-repository universe -y
    ```
3.  **Add the ROS 2 Apt Repository:**
    ```bash
    sudo apt update && sudo apt install curl -y
    sudo curl -sSL [https://raw.githubusercontent.com/ros/rosdistro/master/ros.key](https://raw.githubusercontent.com/ros/rosdistro/master/ros.key) -o /usr/share/keyrings/ros-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] [http://packages.ros.org/ros2/ubuntu](http://packages.ros.org/ros2/ubuntu) $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
    ```
4.  **Update Apt Repositories Again:**
    ```bash
    sudo apt update
    ```
5.  **Upgrade System Packages (Optional but Recommended):** Ensure there are no conflicts.
    ```bash
    sudo apt upgrade -y
    ```
6.  **Install ROS 2 Desktop:** This includes ROS, RViz, demos, tutorials, and more.
    ```bash
    sudo apt install ros-humble-desktop -y
    ```
7.  **Install Development Tools:** Useful for building ROS 2 packages.
    ```bash
    sudo apt install ros-dev-tools -y
    ```
8.  **Source the Setup Script:** Make ROS 2 commands available in your current terminal and add it to your `.bashrc` to automatically source it in new terminals.
    ```bash
    source /opt/ros/humble/setup.bash
    echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
    ```
    * *Close and reopen your terminal or run `source ~/.bashrc` for the change to take effect in the current terminal.*
9.  **Install Essential Python Packages:** Required for ROS 2 tools and message generation.
    ```bash
    pip install --user -U empy==3.3.4 pyros-genmsg setuptools
    ```
    * *`--user` installs packages for the current user only.*
    * *`-U` upgrades if already installed.*

10. **Verify ROS 2 Installation:** Check the installed ROS distribution.
    ```bash
    echo $ROS_DISTRO
    ```
    * *This command should output: `humble`*

## Step 5: Install Micro XRCE-DDS Agent

The Micro XRCE-DDS Agent acts as a bridge, translating PX4's internal uORB messages into the DDS messages used by ROS 2.

1.  **Navigate to Home Directory (or preferred location):**
    ```bash
    cd ~
    ```
2.  **Clone the Agent Repository:** We clone a specific stable branch (`v2.4.2` in this case, check PX4 docs for current recommendations if needed).
    ```bash
    git clone -b v2.4.2 [https://github.com/eProsima/Micro-XRCE-DDS-Agent.git](https://github.com/eProsima/Micro-XRCE-DDS-Agent.git)
    ```
3.  **Build the Agent:**
    ```bash
    cd Micro-XRCE-DDS-Agent
    mkdir build
    cd build
    cmake ..
    make
    ```
4.  **Install the Agent:**
    ```bash
    sudo make install
    ```
5.  **Update Library Links:** Ensure the system can find the installed libraries.
    ```bash
    sudo ldconfig /usr/local/lib/
    ```

## Step 6: Running the Agent

To allow communication between PX4 SITL and ROS 2, you need to run the Micro XRCE-DDS agent.

1.  **Start the Agent:** Open a **new terminal** and run:
    ```bash
    MicroXRCEAgent udp4 -p 8888
    ```
    * This starts the agent listening for UDP connections on port 8888, which is the default configuration for PX4 SITL.
    * You need to keep this terminal open while running the PX4 simulation and ROS 2 nodes that need to communicate with PX4.

## Next Steps

You have now installed PX4 and ROS 2 Humble. To integrate them:

1.  Install the `px4_ros_com` package for ROS 2 workspace setup.
2.  Configure PX4 SITL to connect to the Micro XRCE-DDS Agent (usually enabled by default for UDP on port 8888).
3.  Launch PX4 SITL (e.g., `make px4_sitl gazebo-classic_x500`).
4.  Run the Micro XRCE-DDS Agent in a separate terminal (`MicroXRCEAgent udp4 -p 8888`).
5.  Run your ROS 2 nodes that subscribe to or publish topics related to PX4 (e.g., sensor data, vehicle commands).

Refer to the official PX4 documentation on ROS 2 integration for more detailed examples and configurations.
