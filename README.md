# SmithersXServer

Simple X Server (X11)

## How to compile and run

$ perl build.pl

To run the X Server (runs on port 6002):

$ ./smithers XServer

Then run a program that connects to port 6002 (:2 means 6000+2):

$ DISPLAY=:2 xterm

$ DISPLAY=:2 hotdog

## Legal

Copyright (c) 2024 Arthur Choung. All rights reserved.

Email: arthur -at- hotdoglinux.com

Released under the GNU General Public License, version 3.

For details on the license, refer to the LICENSE file.

