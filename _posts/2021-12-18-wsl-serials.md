---
layout: post
title:  "WSL2 & USB Serials"
date:   2021-12-18 22:40 +0100
tags: blog WSL2 usbipd-win
show_sidebar: true
# hide_hero: true
hero_height: is-small

---

Yo yo! USB & USB-serials in WSL? Read more!

{::nomarkdown}
<div id="toc" style="float:none">
{:/}
* Table of Content
{:toc}
{::nomarkdown}
</div>
{:/}

# Introductory rambling

WSL1 is supercool, as it makes ELF-binaries executable _straight up_ by the windows OS.

WSL2 which uses slim virtual machines is not quite as _cool_, but it is way more _convenient_ to get compabitility with practically everything.
But, passthrough of USB peripherals to the WSL2 kernel has been missing for a while.

Fret not! The handsome looking fellas over at Microsoft has collaborated with _Frans van Dorsselaer_, famous for his [usbipd-win](https://github.com/dorssel/usbipd-win)-project, which brings _USB over IP_ -hosting capabilities to windows! By setting up the hosting of USB devices on the windows end, you can connect and mount them into your WSL-space, making everybody happy as can be!

# WSL Kernel version needs to be lifted!

The kernel needs to be _usbip_-aware in order to be aware of usbip. Previously it didn't know it should be, so we need to help it out with that.

Read on about how to pull updates from MS if you are interested, but you **most likely** want to build the kernel yourself to get drivers anyway.

## Do I need to win11 or windows update??
Fake news out there suggest that you need to upgrade to Win11 in order to make it work.
It even suggests that you need to use windows update in order to get it working.

Don't panic! You can run `wsl --update` to update your kernel to a new fancy version!
You should probably do this while the WSL host is not running. If you can't figure out how to close them gracefully, bring out the killswitch with `wsl --shutdown`. Docker doesn't seem to always like this, but that's not my problem ¯\\\_(ツ)_/¯

However this _might_ require you to enable the _Receive updates for other Microsoft products when you update Windows_ in Windows Update.

This cool fellow on Github wrote how to [Manually get the latest WSL2-kernel](https://github.com/microsoft/WSL/issues/5650#issuecomment-765825503). **Thanks Mr. cool guy!**

Run `uname -r` in WSL to get the current version of the kernel.

## Just build the kernel yourself, it's not scary

*But hey!* You are probably one of those noobs who want to be able to actually _use_ the imported USB-devices!
In that case you might need to [build the kernel](https://askubuntu.com/questions/1373910/ch340-serial-device-doesnt-appear-in-dev-wsl/) yourself in the end, with **drivers** either built directly into the kernel, or as **runtime-loadable modules**.
It's pretty straightforward to do in WSL2 with the instructions in the linked post.

# USBIPD-WIN

OK, so now you have a new fancy updated kernel with USB-drivers. Fuck yeah, you are pretty cool!
Time to get this `usbipd-win`-ball rolling! Head over to the [usbipd-win releases](https://github.com/dorssel/usbipd-win/releases)-page to download and install that shit!

## Troubles in paradise

Before you go any further - Try running `reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{36fc9e60-c465-11cf-8056-444553540000}" /v UpperFilters`.

If you get any output from that registry key, you are [in for a bad time](https://github.com/dorssel/usbipd-win/issues/118).

It means something is trying to intercept and listen to the USB communication. For me it was _USBPcap_ which I installed with the _Wireshark_-package.
But I've actually never used _USBPcap_ so to solve problems I just uninstalled it. **Yeet!**

A new version of usbipd-win is comming out that adds a `--force`-flag to the `usbipd bind` command which forces that to resolve itself, but at the cost of making the USB device _exclusive_ to either (general purpose) Windows or usbipd. The normal `usbipd bind`-command leaves it up to whoever attaches to the device first.

### Share thy wealth
Alright! Now we're ready to go! Run `usbipd bind --all` to expose everything!! Fuck security, fuck everything! (Actually be responsible though)

Hop over to WSL and run `usbip list -r <your ip>` to get a listing of what devices are exposed. If you can't find `usbip`, follow the instructions at [usbipd-win kernel building](https://github.com/dorssel/usbipd-win/wiki/WSL-support#building-your-own-usbip-enabled-wsl-2-kernel) to get `usbip`-commands that are guaranteed compatible with your machine and distro. You might also want to do the `sudo visudo`-part to update the secure path.

# Let WSL2 join the fun (or: `usbip` in `wsl`)
Now we're ready! You've done the `usbip list`-command in WSL and can see that there is stuff available from windows! Take note of the **busid** of the device you want to import, because you need to pass it to `sudo usbip attach -r <your ip> --busid <busid>`.

After you've done that, run `lsusb` to verify that it's there. Next, run `ls -al /dev` to find that your device is now available!

## You can't access that!

But wait, fuck! You probably also notice that the device in `/dev` is owned by `root` and nobody else has access to it! Crap!

That's because the `udev`-service isn't running. Manually kickstart it with `sudo service udev restart` and reattach your device.

### Missing udev rules??
Still fully owned by root?? Maybe you have the same problem I had! I had a Ubuntu18.04-distro which seemed to be missing the `udev` rule files. I did a distro-upgrade to 20.04 (because of other reasons) and they magically appeared. Thanks 20.04!

With the `udev`-rules in place and the `udev`-serive running, my device was properly exposed under `/dev/serial/by-*/*`. Heck yeah! We're pretty awesome by this stage!

## Automate WSL `udev service` starting
It's a hassle to have to do the `sudo service restart udev` every time WSL is started though.

I adapted the solution from the [automatic filecache clearing](https://github.com/microsoft/WSL/issues/4166#issuecomment-618159162)(which you probably also want to do to reclaim memory! Spent ~90 minutes reading through that and related threads, it boils down to linux using all available ram _which it doesn't use *itself*_ for file caching, but it doesn't play well when there are others sharing that RAM. Oh well!)

Point 2&3 from that link was thus adapted to kickstart `udev` when a WSL-bash is started.

* `[ -z "$(ps -ef | grep systemd-udevd | grep -v grep)" ] && sudo service udev restart &> /dev/null` in `~/.bashrs` to restart(more stable than starting it 🤔) if `udev` isn't already running in WSL2
* `%sudo ALL=NOPASSWD: /usr/sbin/service udev restart` added in `sudo visudo` to allow `.bashrc` (or well anyone) to actually do it.).

You can verify with `dmesg` that stuff is recognized and attached by `udev` as you attach/dettach the device with `usbip`. 

# The promised land

Finally! The perfect workflow!

Hah! Not quite yet! There's more to this saga!

## Automating WSL-side attaching
Guess what's very very irritating? When you're doing some programming of a device and it restarts. That is often to be expected and part of the flashing workflow, but now you just lost the USB connection.

Guess you'll just have to manually open a shell an reattach the device again...
Or! OR! You can spend a few hours writing some crap that does it for you, automatically!!

That's what I did, and I'm very proud of my sucky solution, so much so that I'm going to share it with you, at no cost, free of charge. Yep, I'm a generous god. Use it at your own risk.

Credit where credit is due: This is a mutilated version of [Registering for device notification](https://docs.microsoft.com/en-us/windows/win32/devio/registering-for-device-notification), and the mutilation is probably not very healthy.

It uses a specific format of `device->dbcc_name` to extract VID&PID-information, which on serial-port-detection (which happens in a pass immediately after) is sent to `attach.py` using `system()` 🤦‍♂️

Why pass it to python? It boils down to

* String handling in c(++) sucks ass
* It's easier to detect ip, wsl-location, and pass process arguments in python.

Am I proud of it? Not at all! But this is a work-in-progress until auto-wsl-attach is available in `usbipd-win`. And it works _adequately_! My devices are instantly(well at least very speedily, <1sec) exposed to within WSL, and there's no stupid polling loop.

I started a [auto-attach discussion](https://github.com/dorssel/usbipd-win/discussions/168) about doing it the proper way in `usbipd-win` and it seems it's already in the backlog.

Build with `gcc main.cpp -o main.exe -lole32`, or however you want to, I'm not your daddy, you can take care of yourself, I'm proud of you son.

The code is available on github, in the [shitty_usbipd-win_wsl_autoattacher](https://github.com/DrInfiniteExplorer/shitty_usbipd-win_wsl_autoattacher) repo.

### C++

{::nomarkdown}<details><summary>CLICK TO EXPAND C++ code for automation</summary>{:/nomarkdown} 
{% raw  %}
```c++
// RegisterDeviceNotification.cpp
#include <windows.h>
#include <stdio.h>
#include <tchar.h>
#include <strsafe.h>
#include <dbt.h>

// This GUID is for all USB serial host PnP drivers, but you can replace it 
// with any valid device class guid.
GUID WceusbshGUID = { 0x25dbce51, 0x6c8f, 0x4a72,
                      0x8a,0x6d,0xb5,0x4c,0x2b,0x4f,0xc8,0x35 };

// For informational messages and window titles.
PWSTR g_pszAppName;

void OutputMessage(
    HWND hOutWnd,
    WPARAM wParam,
    LPARAM lParam
)
//     lParam  - String message to send to the window.
{
    printf("Message: %s\n", lParam);
}

void ErrorHandler(
    LPCTSTR lpszFunction
)
{

    LPVOID lpMsgBuf;
    LPVOID lpDisplayBuf;
    DWORD dw = GetLastError();

    FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        dw,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPTSTR)&lpMsgBuf,
        0, NULL);

    printf("Error: %d - %s\n", dw, lpMsgBuf);
    LocalFree(lpMsgBuf);
}

BOOL DoRegisterDeviceInterfaceToHwnd(
    IN GUID InterfaceClassGuid,
    IN HWND hWnd,
    OUT HDEVNOTIFY* hDeviceNotify
)
{
    DEV_BROADCAST_DEVICEINTERFACE NotificationFilter;

    ZeroMemory(&NotificationFilter, sizeof(NotificationFilter));
    NotificationFilter.dbcc_size = sizeof(DEV_BROADCAST_DEVICEINTERFACE);
    NotificationFilter.dbcc_devicetype = DBT_DEVTYP_DEVICEINTERFACE;
    NotificationFilter.dbcc_classguid = InterfaceClassGuid;

    *hDeviceNotify = RegisterDeviceNotification(
        hWnd,                       // events recipient
        &NotificationFilter,        // type of device
        DEVICE_NOTIFY_WINDOW_HANDLE | DEVICE_NOTIFY_ALL_INTERFACE_CLASSES
    );

    if (NULL == *hDeviceNotify)
    {
        ErrorHandler("RegisterDeviceNotification");
        return FALSE;
    }

    return TRUE;
}

void MessagePump(
    HWND hWnd
)
{
    MSG msg;
    int retVal;

    while ((retVal = GetMessage(&msg, NULL, 0, 0)) != 0)
    {
        if (retVal == -1)
        {
            ErrorHandler("GetMessage");
            break;
        }
        else
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }
}

void startThing(int VID, int PID)
{

    char cmd[5123];
    snprintf(cmd, sizeof(cmd), "py attach.py %4x:%4x", VID, PID);
    printf("Starting '%s'\n", cmd);
    system(cmd);
}

INT_PTR WINAPI WinProcCallback(
    HWND hWnd,
    UINT message,
    WPARAM wParam,
    LPARAM lParam
)
{
    LRESULT lRet = 1;
    static HDEVNOTIFY hDeviceNotify;
    static HWND hEditWnd;
    static ULONGLONG msgCount = 0;

    switch (message)
    {
    case WM_CREATE:
        if (!DoRegisterDeviceInterfaceToHwnd(
            WceusbshGUID,
            hWnd,
            &hDeviceNotify))
        {
            // Terminate on failure.
            ErrorHandler("DoRegisterDeviceInterfaceToHwnd");
            ExitProcess(1);
        }

        break;

    case WM_DEVICECHANGE:
    {
        //
        // This is the actual message from the interface via Windows messaging.
        // This code includes some additional decoding for this particular device type
        // and some common validation checks.
        //
        // Note that not all devices utilize these optional parameters in the same
        // way. Refer to the extended information for your particular device type 
        // specified by your GUID.
        //
        PDEV_BROADCAST_DEVICEINTERFACE b = (PDEV_BROADCAST_DEVICEINTERFACE)lParam;
        TCHAR strBuff[256];

        // Output some messages to the window.
        switch (wParam)
        {
        case DBT_DEVICEARRIVAL:
            msgCount++;
            StringCchPrintf(
                strBuff, 256,
                TEXT("Message %d: DBT_DEVICEARRIVAL\n"), (int)msgCount);
            
            {
                static const char* types[] = {"OEM", "???", "VOLUME", "PORT", "???", "DEVICEINTERFACE", "HANDLE"};

                const auto* dev = reinterpret_cast<DEV_BROADCAST_HDR*>(lParam);
                printf("Type: %d - %s\n", dev->dbch_devicetype, types[dev->dbch_devicetype]);

                static int VID = -1;
                static int PID = -1;
                if(dev->dbch_devicetype == DBT_DEVTYP_DEVICEINTERFACE)
                {
                    const auto* device = reinterpret_cast<const DEV_BROADCAST_DEVICEINTERFACE*>(dev);
                    wchar_t guidStringBuffer[256];
                    StringFromGUID2(device->dbcc_classguid, guidStringBuffer, sizeof(guidStringBuffer)/sizeof(guidStringBuffer[0]));
                    printf("Device guid: %S\n", guidStringBuffer);
                    printf("Device name: %s\n", device->dbcc_name);

                    // \\?\USB#VID_1A86&PID_7523#5&521a615&0&9                    
                    const bool longEnough = strlen(device->dbcc_name) >= 25;
                    const bool startsOk = device->dbcc_name == strstr(device->dbcc_name, "\\\\?\\USB#VID_");
                    auto ampPIDOffset = device->dbcc_name + 16 * longEnough;
                    const bool continuesOk = ampPIDOffset == strstr(ampPIDOffset, "&PID_");
                    if(startsOk && continuesOk)
                    {
                        char vid[5], pid[5];

                        memcpy(vid, device->dbcc_name+12, 4);
                        memcpy(pid, device->dbcc_name+21, 4);
                        vid[4] = pid[4] = 0;
                        VID = (int)strtol(vid, NULL, 16);
                        PID = (int)strtol(pid, NULL, 16);

                        printf("GOT YOU NOW %04x:%04x\n", VID, PID);
                    }
                }
                if(dev->dbch_devicetype == DBT_DEVTYP_PORT)
                {
                    const auto* port = reinterpret_cast<const DEV_BROADCAST_PORT*>(dev);
                    printf("Port name: %s\n", port->dbcp_name);
                    if(VID != -1 && PID != -1)
                    {
                        startThing(VID,PID);
                        VID = PID = -1;
                    }
                }
                
            }

            break;
        case DBT_DEVICEREMOVECOMPLETE:
            msgCount++;
            StringCchPrintf(
                strBuff, 256,
                TEXT("Message %d: DBT_DEVICEREMOVECOMPLETE\n"), (int)msgCount);
            break;
        case DBT_DEVNODES_CHANGED:
            msgCount++;
            StringCchPrintf(
                strBuff, 256,
                TEXT("Message %d: DBT_DEVNODES_CHANGED\n"), (int)msgCount);
            break;
        default:
            msgCount++;
            StringCchPrintf(
                strBuff, 256,
                TEXT("Message %d: WM_DEVICECHANGE message received, value %d unhandled.\n"),
                (int)msgCount, wParam);
            break;
        }
        OutputMessage(hEditWnd, wParam, (LPARAM)strBuff);
    }
    break;
    case WM_CLOSE:
        if (!UnregisterDeviceNotification(hDeviceNotify))
        {
            ErrorHandler("UnregisterDeviceNotification");
        }
        DestroyWindow(hWnd);
        break;

    case WM_DESTROY:
        PostQuitMessage(0);
        break;

    default:
        // Send all other messages on to the default windows handler.
        lRet = DefWindowProc(hWnd, message, wParam, lParam);
        break;
    }

    return lRet;
}

#define WND_CLASS_NAME TEXT("Usbipd-win-wsl-autoattach")

BOOL InitWindowClass()
{
    WNDCLASSEX wndClass;

    wndClass.cbSize = sizeof(WNDCLASSEX);
    wndClass.style = CS_OWNDC | CS_HREDRAW | CS_VREDRAW;
    wndClass.hInstance = reinterpret_cast<HINSTANCE>(GetModuleHandle(0));
    wndClass.lpfnWndProc = reinterpret_cast<WNDPROC>(WinProcCallback);
    wndClass.cbClsExtra = 0;
    wndClass.cbWndExtra = 0;
    wndClass.hIcon = LoadIcon(0, IDI_APPLICATION);
    wndClass.hbrBackground = 0; //CreateSolidBrush(RGB(192, 192, 192));
    wndClass.hCursor = LoadCursor(0, IDC_ARROW);
    wndClass.lpszClassName = WND_CLASS_NAME;
    wndClass.lpszMenuName = NULL;
    wndClass.hIconSm = wndClass.hIcon;

    if (!RegisterClassEx(&wndClass))
    {
        ErrorHandler("RegisterClassEx");
        return FALSE;
    }
    return TRUE;
}

int __stdcall _tWinMain(
    _In_ HINSTANCE hInstanceExe,
    _In_opt_ HINSTANCE, // should not reference this parameter
    _In_ PTSTR lpstrCmdLine,
    _In_ int nCmdShow)
{
    if (!InitWindowClass())
    {
        return -1;
    }

    HWND hWnd = CreateWindowEx(
        WS_EX_CLIENTEDGE | WS_EX_APPWINDOW,
        WND_CLASS_NAME,
        "Yolo boi",
        WS_OVERLAPPEDWINDOW, // style
        CW_USEDEFAULT, 0,
        32, 32,
        NULL, NULL,
        hInstanceExe,
        NULL);

    if (hWnd == NULL)
    {
        ErrorHandler("CreateWindowEx: main appwindow hWnd");
        return -1;
    }

    //ShowWindow(hWnd, SW_SHOWNORMAL);
    UpdateWindow(hWnd);

    MessagePump(hWnd);

    return 1;
}
```
{% endraw  %}
{::nomarkdown}</details>{:/nomarkdown}

### Python3

{::nomarkdown}<details><summary>CLICK TO EXPAND Python3 code.</summary>{:/nomarkdown} 
{% raw  %}

```python
import sys
import socket
import subprocess
import platform
import os

def main():
  print(sys.argv)

  id = sys.argv[1]
  ip = socket.gethostbyname_ex(socket.gethostname())[2][0]
  usbip = "/usr/lib/linux-tools/5.4.0-77-generic/usbip"

  get_busid_cmd = f"{usbip} list -r {ip} | grep {id} | cut -f 1 -d : | awk '{{$1=$1;print}}'"
  attach_cmd = f"{usbip} attach -r {ip} --busid $({get_busid_cmd})"
  print(get_busid_cmd)
  print(attach_cmd)


  is32bit = (platform.architecture()[0] == '32bit')
  system32 = os.path.join(os.environ['SystemRoot'], 'SysNative' if is32bit else 'System32')
  wsl = os.path.join(system32, 'wsl.exe')

  wsl_cmd = f'{wsl} -e /bin/bash -c'
  print(wsl_cmd)

  split_cmd = wsl_cmd.split() + [f"sudo {attach_cmd}"]
  print(split_cmd)

  subprocess.Popen(split_cmd)
  return

if __name__ == '__main__':
  main()

```
{% endraw  %}

{::nomarkdown}</details>{:/nomarkdown}

What am I going to do with this? Program some AVRs and nanos and STM32s and ESPs, and of course I'm going to run a [prind stack](https://github.com/mkuf/prind) inside WSL2 now that I can! Hah, can't trick me into buying expensive raspberries now that there are no more _Zero W2_ on the market 😭

