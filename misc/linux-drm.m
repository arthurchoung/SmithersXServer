/*

 SmithersXServer

 Copyright (c) 2024 Arthur Choung. All rights reserved.

 Email: arthur -at- hotdoglinux.com

 This file is part of SmithersXServer.

 SmithersXServer is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.

 */

#import "HOTDOG.h"

#include <stdint.h>
#include <xf86drm.h>
#include <xf86drmMode.h>

#include <drm_fourcc.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

static char *pointerPalette =
". #000000\n"
"X #AABBCC\n"
"o #DD2222\n"
"O #ffffff\n"
;

static char *pointerPixels =
"............          \n"
"............          \n"
"..XXXXXXXXXX..        \n"
"..XXXXXXXXXX..        \n"
"..ooooooooXX..        \n"
"..ooooooooXX..        \n"
"..ooooooXX..          \n"
"..ooooooXX..          \n"
"..ooooooooXX..        \n"
"..ooooooooXX..        \n"
"..oooo..ooooXX..      \n"
"..oooo..ooooXX..      \n"
"  ....  ..ooooXX..    \n"
"  ....  ..ooooXX..    \n"
"          ..ooooXX..  \n"
"          ..ooooXX..  \n"
"            ..ooooXX..\n"
"            ..ooooXX..\n"
"              ..oo..  \n"
"              ..oo..  \n"
"                ..    \n"
"                ..    \n"
;

static id nameForConnectorType(uint32_t type)
{
    if (type == DRM_MODE_CONNECTOR_VGA) return @"VGA";
    if (type == DRM_MODE_CONNECTOR_DVII) return @"DVI-I";
    if (type == DRM_MODE_CONNECTOR_DVID) return @"DVI-D";
    if (type == DRM_MODE_CONNECTOR_DVIA) return @"DVI-A";
    if (type == DRM_MODE_CONNECTOR_Composite) return @"Composite";
    if (type == DRM_MODE_CONNECTOR_SVIDEO) return @"SVIDEO";
    if (type == DRM_MODE_CONNECTOR_LVDS) return @"LVDS";
    if (type == DRM_MODE_CONNECTOR_Component) return @"Component";
    if (type == DRM_MODE_CONNECTOR_9PinDIN) return @"DIN";
    if (type == DRM_MODE_CONNECTOR_DisplayPort) return @"DP";
    if (type == DRM_MODE_CONNECTOR_HDMIA) return @"HDMI-A";
    if (type == DRM_MODE_CONNECTOR_HDMIB) return @"HDMI-B";
    if (type == DRM_MODE_CONNECTOR_TV) return @"TV";
    if (type == DRM_MODE_CONNECTOR_eDP) return @"eDP";
    if (type == DRM_MODE_CONNECTOR_VIRTUAL) return @"Virtual";
    if (type == DRM_MODE_CONNECTOR_DSI) return @"DSI";
    return @"Unknown";
}

static int calculateRefreshRateMhz(drmModeModeInfo *mode)
{
	int val = (mode->clock * 1000000L / mode->htotal + mode->vtotal / 2) / mode->vtotal;

	if (mode->flags & DRM_MODE_FLAG_INTERLACE) {
		val *= 2;
    }

	if (mode->flags & DRM_MODE_FLAG_DBLSCAN) {
		val /= 2;
    }

	if (mode->vscan > 1) {
		val /= mode->vscan;
    }

	return val;
}

static id getEncoder(int drmFD, uint32_t encoderID)
{
    drmModeEncoder *encoder = drmModeGetEncoder(drmFD, encoderID);
    if (!encoder) {
        return nil;
    }

    id dict = nsdict();
    [dict setValue:nsfmt(@"%lu", encoder->encoder_id) forKey:@"encoderID"];
    [dict setValue:nsfmt(@"%lu", encoder->encoder_type) forKey:@"encoderType"];
    [dict setValue:nsfmt(@"%lu", encoder->crtc_id) forKey:@"crtcID"];
    [dict setValue:nsfmt(@"%lu", encoder->possible_crtcs) forKey:@"possibleCrtcs"];
    [dict setValue:nsfmt(@"%lu", encoder->possible_clones) forKey:@"possibleClones"];

    drmModeFreeEncoder(encoder);

    return dict;
}

static id getModeInfo(drmModeModeInfo *info)
{
    id dict = nsdict();

    int width = info->hdisplay;
    int height = info->vdisplay;
    int refreshRate = calculateRefreshRateMhz(info);
    [dict setValue:nsfmt(@"%d", width) forKey:@"width"];
    [dict setValue:nsfmt(@"%d", height) forKey:@"height"];
    [dict setValue:nsfmt(@"%d", refreshRate) forKey:@"refreshRate"];
    NSLog(@"mode width %d height %d refreshRate %d", width, height, refreshRate);

    id modeData = [NSData dataWithBytes:info length:sizeof(drmModeModeInfo)];
NSLog(@"modeData %@", modeData);
    [dict setValue:modeData forKey:@"modeData"];

    return dict;
}

static id getConnector(int drmFD, uint32_t connectorID)
{
    drmModeConnector *connector = drmModeGetConnector(drmFD, connectorID);
    if (!connector) {
        NSLog(@"drmModeGetConnector failed %lu", connectorID);
        return nil;
    }

    id dict = nsdict();

    [dict setValue:nsfmt(@"%d", connector->connector_id) forKey:@"connectorID"];

    id name = nsfmt(@"%@-%d", nameForConnectorType(connector->connector_type), connector->connector_type_id);
    [dict setValue:name forKey:@"name"];
    NSLog(@"name '%@'", name);

    [dict setValue:nsfmt(@"%d", connector->connection) forKey:@"connection"];
    if (connector->connection == DRM_MODE_CONNECTED) {
        [dict setValue:@"1" forKey:@"isConnected"];
    } else {
        [dict setValue:@"0" forKey:@"isConnected"];
    }

    id modes = nsarr();
    for (int i=0; i<connector->count_modes; i++) {
        id elt = getModeInfo(&connector->modes[i]);
        [modes addObject:elt];
    }
    [dict setValue:modes forKey:@"modes"];

    id encoders = nsarr();
    for (int i=0; i<connector->count_encoders; i++) {
        id elt = getEncoder(drmFD, connector->encoders[i]);
        if (elt) {
            [encoders addObject:elt];
        }
    }
    [dict setValue:encoders forKey:@"encoders"];

    drmModeFreeConnector(connector);

    return dict;
}
static id getResources(int drmFD)
{
	drmModeRes *resources = drmModeGetResources(drmFD);
	if (!resources) {
        NSLog(@"drmModeGetResources failed");
        return nil;
	}

    id dict = nsdict();

    id crtcIDs = nsarr();
    for (int i=0; i<resources->count_crtcs; i++) {
        [crtcIDs addObject:nsfmt(@"%lu", resources->crtcs[i])];
    }
    [dict setValue:crtcIDs forKey:@"crtcIDs"];

    id connectors = nsarr();
    for (int i=0; i<resources->count_connectors; i++) {
        id elt = getConnector(drmFD, resources->connectors[i]);
        if (elt) {
            [connectors addObject:elt];
        }
    }
    [dict setValue:connectors forKey:@"connectors"];

    drmModeFreeResources(resources);

    return dict;
}

static id createFramebuffer(int drmFD, int width, int height)
{
    struct drm_mode_create_dumb createarg = {
        .width = width,
        .height = height,
        .bpp = 32
    };

    int result = drmIoctl(drmFD, DRM_IOCTL_MODE_CREATE_DUMB, &createarg);
    if (result < 0) {
        NSLog(@"DRM_IOCTL_MODE_CREATE_DUMB failed");
        return nil;
    }

    id dict = nsdict();
    [dict setValue:nsfmt(@"%d", width) forKey:@"width"];
    [dict setValue:nsfmt(@"%d", height) forKey:@"height"];
    [dict setValue:nsfmt(@"%d", createarg.pitch) forKey:@"stride"];
    [dict setValue:nsfmt(@"%d", createarg.handle) forKey:@"handle"];
    [dict setValue:nsfmt(@"%d", createarg.size) forKey:@"size"];

    uint32_t handles[4] = { createarg.handle };
    uint32_t strides[4] = { createarg.pitch };
    uint32_t offsets[4] = { 0 };

    uint32_t framebufferID = 0;

    result = drmModeAddFB2(drmFD, width, height, DRM_FORMAT_XRGB8888, handles, strides, offsets, &framebufferID, 0);
    if (result < 0) {
        NSLog(@"drmModeAddFB2 failed");
        return nil;
    }

    NSLog(@"framebufferID %d", framebufferID);
    [dict setValue:nsfmt(@"%d", framebufferID) forKey:@"framebufferID"];

    struct drm_mode_map_dumb maparg = {
        .handle = createarg.handle
    };
    result = drmIoctl(drmFD, DRM_IOCTL_MODE_MAP_DUMB, &maparg);
    if (result < 0) {
        NSLog(@"DRM_IOCTL_MODE_MAP_DUMB");
        return nil;
    }

//FIXME handle dealloc
    unsigned char *pixels = mmap(0, createarg.size, PROT_READ|PROT_WRITE, MAP_SHARED, drmFD, maparg.offset);
    if (!pixels) {
        NSLog(@"mmap failed");
        return nil;
    }
    
    memset(pixels, 0xff, createarg.size);
    id data = [[[NSData alloc] initWithBytesNoCopy:pixels length:createarg.size] autorelease];
    [dict setValue:data forKey:@"pixelData"];

    return dict;
}

@implementation Definitions(mfeklwfmklsdmfklsdmfkls)
+ (void)runDRM
{
	int drmFD = open("/dev/dri/card0", O_RDWR|O_NONBLOCK);
	if (drmFD < 0) {
		NSLog(@"unable to open /dev/dri/card0");
		exit(1);
	}

    id resources = getResources(drmFD);
    if (!resources) {
        exit(1);
    }

    id crtcIDs = [resources valueForKey:@"crtcIDs"];

    id allConnectors = [resources valueForKey:@"connectors"];

    uint32_t usedCrtcs = 0;
    int totalWidth = 0;
    int highestHeight = 0;

    for (int i=0; i<[allConnectors count]; i++) {
        id connector = [allConnectors nth:i];

        if (![connector intValueForKey:@"isConnected"]) {
            continue;
        }

        id mode0 = [[connector valueForKey:@"modes"] nth:0];
        if (!mode0) {
            continue;
        }
        int width = [mode0 intValueForKey:@"width"];
        int height = [mode0 intValueForKey:@"height"];

        id allEncoders = [connector valueForKey:@"encoders"];
        for (int j=0; j<[allEncoders count]; j++) {
            id encoder = [allEncoders nth:j];
            uint32_t possibleCrtcs = [encoder unsignedLongValueForKey:@"possibleCrtcs"];
            for (int k=0; k<[crtcIDs count]; k++) {
                uint32_t bitmask = 1<<k;
                if (!(possibleCrtcs & bitmask)) {
                    continue;
                }
                if (usedCrtcs & bitmask) {
                    continue;
                }
                usedCrtcs |= bitmask;
                [connector setValue:[crtcIDs nth:k] forKey:@"usingCrtcID"];
                totalWidth += width;
                if (height > highestHeight) {
                    highestHeight = height;
                }
                goto skip;
            }
        }
skip:
    }

    NSLog(@"totalWidth %d highestHeight %d", totalWidth, highestHeight);
    id framebuffer = createFramebuffer(drmFD, totalWidth, highestHeight);
    if (!framebuffer) {
        NSLog(@"unable to create framebuffer");
        exit(1);
    }

    int framebufferID = [framebuffer intValueForKey:@"framebufferID"];

    for (int i=0; i<[allConnectors count]; i++) {
        id connector = [allConnectors nth:i];

        id crtcIDNumber = [connector valueForKey:@"usingCrtcID"];
        if (!crtcIDNumber) {
            continue;
        }
        uint32_t crtcID = [crtcIDNumber unsignedLongValue];

        id mode0 = [[connector valueForKey:@"modes"] nth:0];
        id modeData = [mode0 valueForKey:@"modeData"];
        if (!modeData) {
            continue;
        }

//FIXME handle dealloc
		drmModeCrtc *oldCrtc = drmModeGetCrtc(drmFD, crtcID);

        int connectorID = [connector intValueForKey:@"connectorID"];
NSLog(@"crtcID %d", crtcID);
NSLog(@"framebufferID %d", framebufferID);
NSLog(@"connectorID %d (before)", connectorID);
NSLog(@"modeData %@", modeData);
        int result = drmModeSetCrtc(drmFD, crtcID, framebufferID, 0, 0, &connectorID, 1, [modeData bytes]);
        if (result < 0) {
            NSLog(@"drmModeSetCrtc failed");
            exit(1);
        }
NSLog(@"connectorID %d (after)", connectorID);
    }

    id cmd = nsarr();
    [cmd addObject:@"smithers-readMouse"];
    id readMouseProcess = [cmd runCommandAndReturnProcess];


    id xserver = [Definitions XServer];

    id pixelData = [framebuffer valueForKey:@"pixelData"];
    unsigned char *pixelBytes = [pixelData bytes];
    int stride = [framebuffer intValueForKey:@"stride"];

    id bitmap = [Definitions bitmapWithWidth:totalWidth height:highestHeight];
    unsigned char *srcBytes = [bitmap pixelBytes];
    int srcStride = [bitmap bitmapStride];

    int mouseX = totalWidth/2;
    int mouseY = highestHeight/2;
	for (;;) {
        id pool = [[NSAutoreleasePool alloc] init];


        Int4 r;
        r.x = 0;
        r.y = 0;
        r.w = [bitmap bitmapWidth];
        r.h = [bitmap bitmapHeight];
        [xserver drawInBitmap:bitmap rect:r];
        [bitmap drawCString:pointerPixels palette:pointerPalette x:mouseX y:mouseY];
        [bitmap setColor:@"red"];
        [bitmap drawBitmapText:@"Click to send response" x:mouseX y:mouseY+22];
        for (int y=0; y<highestHeight; y++) {
            unsigned char *src = srcBytes + y*srcStride;
            unsigned char *dst = pixelBytes + y*stride;

            for (int x=0; x<totalWidth; x++) {
                dst[x*4+0] = src[x*4+0];
                dst[x*4+1] = src[x*4+1];
                dst[x*4+2] = src[x*4+2];
                dst[x*4+3] = src[x*4+3];
            }
        }


        fd_set rfds;
        int maxFD=0;
        int readMouseFD = -1;
        FD_ZERO(&rfds);
        if ([readMouseProcess respondsToSelector:@selector(fileDescriptor)]) {
            readMouseFD = [readMouseProcess fileDescriptor];
            if (readMouseFD != -1) {
                FD_SET(readMouseFD, &rfds);
                if (readMouseFD > maxFD) {
                    maxFD = readMouseFD;
                }
            }
        }
        int *xserverFDs = [xserver fileDescriptors];
        for (int i=0; xserverFDs[i]>=0; i++) {
            FD_SET(xserverFDs[i], &rfds);
            if (xserverFDs[i] > maxFD) {
                maxFD = xserverFDs[i];
            }
        }

        struct timeval tv;
        tv.tv_sec = 0;
        tv.tv_usec = 16666;
        int result = select(maxFD+1, &rfds, 0, 0, &tv);
        if (result > 0) {
            if (FD_ISSET(readMouseFD, &rfds)) {
                if ([readMouseProcess respondsToSelector:@selector(handleFileDescriptor)]) {
                    [readMouseProcess handleFileDescriptor];
                    for(;;) {
                        id line = [[readMouseProcess valueForKey:@"data"] readLine];
                        if (!line) {
                            break;
                        }
                        int dx = [line intValueForKey:@"dx"];
                        int dy = [line intValueForKey:@"dy"];
                        int left = [line intValueForKey:@"left"];
                        mouseX += dx;
                        mouseY -= dy;
                        if (left) {//FIXME temporary hack
                            [xserver sendResponse];
                        }
                    }
                }
            }
            for (int i=0; xserverFDs[i]>=0; i++) {
                if (FD_ISSET(xserverFDs[i], &rfds)) {
                    [xserver handleFileDescriptor:xserverFDs[i]];
                }
            }
        }



        [pool drain];

	}

    exit(0);
}
@end

