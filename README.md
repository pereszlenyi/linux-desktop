# Setup Windows Subsystem for Linux for Development

Scripts in this repo automate the setup of Linux on [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/).
The primary purpose is to have everything set up and ready for development.
Currently, the scripts only work with Ubuntu.

## Installation

We have to do a few steps before actually running these scrips.

### Windows Terminal

The default terminal app in Windows is painful.
Therefore, it is recommended to [install Windows Terminal](https://github.com/microsoft/terminal#installing-and-running-windows-terminal) and execute all the below commands in it.
(Another decent alternative is [MobaXterm](https://mobaxterm.mobatek.net/) which comes with its own X11 server.)

### Install Linux on WSL

You need to install Ubuntu on WSL.
But, before installing, make sure that you will use [WSL 2](https://learn.microsoft.com/en-us/windows/wsl/compare-versions#whats-new-in-wsl-2) instead of WSL 1.
You can do that by opening a [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows) terminal (preferably inside Windows Terminal) and running `wsl --set-default-version 2`:

~~~
PS C:\> wsl --set-default-version 2
For information on key differences with WSL 2 please visit https://aka.ms/wsl2
The operation completed successfully.
~~~

This, as you have guessed, [sets the default version](https://learn.microsoft.com/en-us/windows/wsl/basic-commands#set-default-wsl-version) to 2.

Now, go ahead and install the [latest and greatest version of Ubuntu](https://learn.microsoft.com/en-us/windows/wsl/basic-commands#list-available-linux-distributions).
You can use [Microsoft's guide](https://learn.microsoft.com/en-us/windows/wsl/install).
After you are done, come back and continue from here.

Using PowerShell, [shut down WSL](https://learn.microsoft.com/en-us/windows/wsl/basic-commands#shutdown) by `wsl --shutdown` and then [update](https://learn.microsoft.com/en-us/windows/wsl/basic-commands#update-wsl) it by `wsl --update`:

~~~
PS C:\> wsl --shutdown
PS C:\> wsl --update
Checking for updates.
The most recent version of Windows Subsystem for Linux is already installed.
~~~

Now, [checking the version of WSL](https://learn.microsoft.com/en-us/windows/wsl/basic-commands#check-wsl-version) should output something like this:

~~~
PS C:\> wsl --version
WSL version: 1.1.3.0
Kernel version: 5.15.90.1
WSLg version: 1.0.49
MSRDC version: 1.2.3770
Direct3D version: 1.608.2-61064218
DXCore version: 10.0.25131.1002-220531-1700.rs-onecore-base2-hyp
Windows version: 10.0.19045.2728
~~~

You can also see the [list of installed distributions](https://learn.microsoft.com/en-us/windows/wsl/basic-commands#list-installed-linux-distributions) by running `wsl --list --verbose --all`:

~~~
PS C:\> wsl --list --verbose --all
  NAME      STATE           VERSION
* Ubuntu    Stopped         2
~~~

It is important that the version is 2.

### Use this Repo in Ubuntu

Finally, open an Ubuntu terminal.
(Again, preferably in Windows Terminal.)
Go to a directory where you want this repo to be saved.
You can also just stay in your home directory.
The following command will clone this repository and start the installation and setup:

~~~
git clone --quiet https://github.com/pereszlenyi/wsl.git && ./wsl/install.sh
~~~

It will ask your password 2 or 3 times because some of the steps are run as root.
When running for the first time, it will ask for your name and email which will be used to configure git.
