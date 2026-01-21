---
layout: default
title:  "Installing Window Subsystem for Linux"
---


In this tutorial, we will prepare your Windows machin for ARGoS. ARGoS is only native on Linux, so we will first need to install WSL (Windows Subsystem for Linux) that allows you to run any program that runs on Linux. In order to install WSL, you need to open the Power Shell (the command line of Windows). To do so, open your start menu (either by pressing on the Windows key of your keyboard, or by clicking on the start/window button in your task bar). Then, in the search text area, enter **PowerShell**, and then click on the associated program that should appear in the list.

In the **PowerShell**, type the following command and run it (press enter) in order to install WSL:

```bash
wsl --install
```
This should take between 2 and 5 minutes depending on your connection. You might be asked to reboot your system. Do so, and then open again the **PowerShell**, and run the following command:

```bash
wsl
```

You might see a message telling you that no distribution is installed, such as "Windows Subsystem for Linux has no installed distributtions". If so, then run the following command, installing Ubuntu 24.04:

```bash
wsl --install -d Ubuntu-24.04
```

If you the system instead show you the help (as a list of commands in the command line), it might be that your system has not enabled WSL as a service. A possible solution then is to go in your power shell (possibly needed this time to be run as an administrator), and run `dism /online /get-features /format:table | findstr /i "Subsystem-Linux VirtualMachinePlatform Microsoft-Hyper-V"`. A table will appear, check if WSL is enabled. If not, run `dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart` and then reboot and resume the commands above. If it still does not work, you can also run `wsl --update` and then install Ubuntu again with the command above.

A graphical help window will then appear, you are free to roam around or just close it. In the command line, you are then asked to enter an account name, and a password. Please remember both! Password input in Linux doesn't show any characters (not even *), which is always a bit stressful at first!

Last, we run an update on your system, to be sure that your software repository have all the latest versions:
```bash
sudo apt update && sudo apt upgrade
```

And now you are done. Please go back to the [setting up page](./pages/setting-up.html) to continue with the instalation process.
