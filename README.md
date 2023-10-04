# Metahub

![Metahub](https://github.com/proffapt/Metahub/assets/86282911/462e41c9-f3e1-437a-b1c3-949628ca6b00)
> **Note** This is a completely student-run hub and is not officially affiliated with IIT Kharagpur.

Metahub is a Direct Connect ([DC](https://en.wikipedia.org/wiki/Advanced_Direct_Connect)) Hub for IIT Kharagpur. It is a private hub and can only be accessed from within the IIT Kharagpur network. Users can connect to this hub using DC clients and share files at high speeds. The popular hub, "[HiT Hi FiT Hai](https://wiki.metakgp.org/w/HiT_Hi_FiT_Hai)," can also be accessed using this service. The purpose of this repository is to document the server's internal configuration. If you wish to connect to the hub, please refer to the following guide: https://proffapt.hashnode.dev/dc-client-setup.

## Host Device Specifications

Raspberry Pi 4 Model B Rev 1.1 ( 2 GB ) \
OS : Rasbian 64 Bit

## Setting up the server

- [Searching the Pi and SSH](#searching-the-pi-and-ssh)
    - [Automatic Searching](#automatic-searching)
    - [Manual Searching](#manual-searching)
- [Installing Ptokax on Raspberry Pi](#installing-ptokax-on-raspberry-pi)
- [Running Scripts](#running-scripts)
    - [Changing Message of the Day](#changing-message-of-the-day)
    - [Changing the Share limit](#changing-the-share-limit)
- [Changes Made to HHFH Version](#changes-made-to-ptokax-hhfh-version)

### Searching the Pi and SSH

1. Install the following dependencies based on your system:
   - Linux
      - `nmap`
   - MacOS
      - `nmap`
      - `iproute2mac`
      
    For Debian/Ubuntu : `sudo apt update && sudo apt install -y nmap`<br>
    For MacOS using brew : `brew install nmap iproute2mac`<br>
2. Make sure you are connected to the same ethernet subnetwork as that of pi before you start the search for its ip.
3. Follow either one of the following methods to get the ip:

   > **Note** Manual Searching should be used as a __failsafe__ method when Automatic Searching fails.

   - [Automatic Searching](#automatic-searching)
   - [Manual Searching](#manual-searching)
 
4. Now ssh to the pi : `ssh pi@IP`. If it is a new install, then the password will be `raspberrypi`.

#### Automatic Searching

Run the follwoing set of commands to get the `ipofpi.sh` script and execute it.
```bash
git clone https://github.com/proffapt/Metahub --depth 1 --branch main --single-branch Metahub
mv Metahub/ipofpi.sh ./
chmod +x ipofpi.sh
rm -rf Metahub
./ipofpi.sh
```
   
   > **Note** All this drama needs to be done because there is a high chance that https://raw.githubusercontent.com will be blocked on campus network :)
  
#### Manual Searching

- Check your ethernet interface name by running : `ip addr`. <br>
In my case it's `eth0`.

- Run the following command to get your subnet IP and replace `eth0` with your interface name : 
  ```bash
  ip route | grep link | grep eth0 | cut -d ' ' -f 1
  ```
- If you are not on the same subnet then get the subnet address from a friend on the same subnet as in the above step.
- Now to find Pi run (Replace `10.112.5.0/24` with yout subnet address ) :
  ```bash
  sudo nmap -sS -O -p22 10.112.5.0/24 -oG result
  ```
  This will create a file named `result`.
  
- Now view the contents of the file, it will be similar to this:
  ```bash
  # Nmap 7.92 scan initiated Fri Feb 25 00:55:18 2022 as: nmap -sS -O -p22 -oG testing 10.112.5.0/24
  Host: 10.112.5.2 ()	Status: Up
  Host: 10.112.5.2 ()	Ports: 22/closed/tcp//ssh///
  Host: 10.112.5.32 ()	Status: Up
  Host: 10.112.5.32 ()	Ports: 22/filtered/tcp//ssh///
  Host: 10.112.5.123 ()	Status: Up
  Host: 10.112.5.123 ()	Ports: 22/closed/tcp//ssh///
  Host: 10.112.5.167 ()	Status: Up
  Host: 10.112.5.167 ()	Ports: 22/open/tcp//ssh///	OS: Linux 4.15 - 5.6	Seq Index: 260	IP ID Seq: All zeros
  # Nmap done at Fri Feb 25 00:55:25 2022 -- 256 IP addresses (4 hosts up) scanned in 7.22 seconds
  ```
  In this case, required IP is `10.112.5.167` - the status is **Up**, the port is **open** and the OS is **Linux**. If there are more than one devices, then try with all of them.
  ```bash
  Host: 10.112.5.167 ()	Status: Up
  Host: 10.112.5.167 ()	Ports: 22/open/tcp//ssh///	OS: Linux 4.15 - 5.6	Seq Index: 260	IP ID Seq: All zeros
  ```
  
### Installing Ptokax on Raspberry Pi

1. __Clone__ the repository in a _structured manner_ and _remove unnecessary files_, then execute the setup script using the following set of commands.
    ```bash
    git clone https://github.com/proffapt/Metahub --depth 1 --branch main --single-branch /home/pi/Metahub
    sudo rm -rf /home/pi/Metahub/.git /home/pi/Metahub/README.md /home/pi/Metahub/ipofpi.sh
    chmod +x /home/pi/Metahub/ptokax-setup.sh
    ./Metahub/ptokax-setup.sh
    source ~/.bashrc
    ```

   > **Note** All this drama needs to be done because there is a high chance that https://raw.githubusercontent.com will be blocked on campus network :)
  
2. Use the below commands to achieve the specified tasks with the PtokaX server:

   | Task | Command |
   |------|---------|
   | Start | `ptokax.start` |
   | Stop | `ptokax.stop` |
   | Check status | `ptokax.status` |
   | Configure | `ptokax.config` |
  
### Running Scripts

Repositories with all the PtokaX Scripts : https://github.com/HiT-Hi-FiT-Hai/ptokax-scripts

> **Warning**: Make sure to stop ptokax first and then change settings otherwise default settings are stored.

#### Changing Message of the Day

Edit `~/PtokaX/cfg/Motd.txt`

#### Changing the Share limit 

1. Edit `~/PtokaX/scripts/external/restrict/share.lua`
  
   ```lua
   -- change the 3rd value in units of GiB ( 90 means 90 GiB )
   local sAllowedProfiles, iBanTime, iShareLimit, iDivisionFactor = "01236", 6, 0, ( 2^10 )^3
   ```

2. Then start/restart the following scripts using the !startscript/!restartscript command _after logging into the DC_ using any client (LinuxDC++ preferred on Linux and DC++ on windows)

   ```
   !startscript startup.lua
   !startscript restrictions.lua
   ```

### Changes made to Ptokax HHFH version

- Fixed errors in compilation

  ```console
  /home/pi/PtokaX/core/SettingManager.cpp: In member function ‘void SettingManager::Save()’:
  /home/pi/PtokaX/core/SettingManager.cpp:507:25: error: ISO C++ forbids comparison between pointer and integer [-fpermissive]
    507 |      if(SetBoolCom[szi] != '\0') {
        |         ~~~~~~~~~~~~~~~~^~~~~~~
  /home/pi/PtokaX/core/SettingManager.cpp:530:26: error: ISO C++ forbids comparison between pointer and integer [-fpermissive]
    530 |      if(SetShortCom[szi] != '\0') {
        |         ~~~~~~~~~~~~~~~~~^~~~~~~
  /home/pi/PtokaX/core/SettingManager.cpp:553:24: error: ISO C++ forbids comparison between pointer and integer [-fpermissive]
    553 |      if(SetTxtCom[szi] != '\0') {
        |         ~~~~~~~~~~~~~~~^~~~~~~
  /home/pi/PtokaX/core/SettingManager.cpp: In member function ‘void SettingManager::SetText(size_t, const char*, size_t)’:
  /home/pi/PtokaX/core/SettingManager.cpp:1112:41: warning: this statement may fall through [-Wimplicit-fallthrough=]
   1112 |             if(szLen == 0 || szLen > 64 || strpbrk(sTxt, " $|") != NULL) {
        |                                         ^
  /home/pi/PtokaX/core/SettingManager.cpp:1115:9: note: here
   1115 |         case SETTXT_TCP_PORTS:
        |         ^~~~
  make: *** [makefile:340: /home/pi/PtokaX/obj/SettingManager.o] Error 1
  ```

- Fixed Bug: Ban followed by wrong redirection

  In this bug users are sometimes redirected to the wrong hub address and are banned. To fix this, change `REDIRECT_ADDRESS`, `HUB_NAME` & `HUB_ADDRESS` - in the following files as shown.

    - PtokaX/core/SettingDefaults.h
      ```bash
      const char* SetTxtDef[] = {
          "Metahub", //HUB_NAME
          "Admin", //ADMIN_NICK
          "10.112.5.167", //HUB_ADDRESS
          "1209;411", //TCP_PORTS
          "0", //UDP_PORT
          "", //HUB_DESCRIPTION
          "10.112.5.167:411", //REDIRECT_ADDRESS
          "reg.hublist.org;serv.hubs-list.com;hublist.cz;hublist.dreamland-net.eu;allhublista.myip.hu;publichublist-nl.no-ip.org;reg.hublist.dk;hublist.te-home.net;dc.gwhublist.com", //REGISTER_SERVERS
          "Sorry, this hub is only for registered users.", //REG_ONLY_MSG
          "", //REG_ONLY_REDIR_ADDRESS
      ```

    - PtokaX/cfg.example/Settings.pxt

      ```bash
      # Hub name. Minimal length 1, maximal length 256. $ and | is not allowed
      #HubName	=	Metahub
      # Admin nick. Minimal length 1. Maximal length 64. $, | and space is not allowed
      #AdminNick	=	Admin
      # Hub address. Minimal length 1. Maximal length 256. $ and | is not allowed
      #HubAddress	=	10.112.5.167
      # TCP ports. Minimal length 1. Maximal length 64
      #TCPPorts	=	1209;411
      # UDP port. Minimal length 1. Maximal length 5
      #UDPPort	=	0
      # Hub description. Maximal length 256. $ and | is not allowed
      #HubDescription	=	
      # Main redirect address. Maximal length 256. | is not allowed
      #RedirectAddress	=	10.112.5.167:411
      # Hublist register servers. Maximal length 1024
      ```
      
- Created scripts to setup, start and stop ptokax server.
- Created script to check the status of ptokax server.
- Created service for ptokax to be executed when the pi is restarted.
- Extended the service to handle static ip configuration when the host device changes hall.
