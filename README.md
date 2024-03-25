# SmithersXServer

Simple X Server (X11)

## How to compile and run

$ perl build.pl

$ sh makeUtils.sh

Run the X Server from the console using /dev/dri/card0 (listening on port 6002):

$ ./smithers runDRM

To run it using /dev/dri/card1 (note the colon and space):

$ ./smithers runDRM: 1

Then run a program that connects to port 6002 (:2 means 6000+2):

$ DISPLAY=:2 mpv --vo=x11 video.mp4

The first column is the server object. If there are no connections, it is the only column.

Each additional column represents a client connection.

Click on the appropriate client column to send a response to the data, if possible.

Hit Control-C to quit.

## Legal

Copyright (c) 2024 Arthur Choung. All rights reserved.

Email: arthur -at- hotdoglinux.com

Released under the GNU General Public License, version 3.

For details on the license, refer to the LICENSE file.

