#import "HOTDOG.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>
#include <ctype.h>
#include <errno.h>
#include <netinet/in.h>
#include <sys/shm.h>

static struct sockaddr_in _addr;

static uint16_t read_uint16(unsigned char *p)
{
    uint16_t val = p[1];
    val <<= 8;
    val |= p[0];
    return val;
}
static uint32_t read_uint32(unsigned char *p)
{
    uint32_t val = p[3];
    val <<= 8;
    val |= p[2];
    val <<= 8;
    val |= p[1];
    val <<= 8;
    val |= p[0];
    return val;
}
static void write_uint16(unsigned char *p, uint16_t val)
{
    p[0] = val&0xff;
    val>>=8;
    p[1] = val&0xff;
}

static void write_uint32(unsigned char *p, uint32_t val)
{
    p[0] = val&0xff;
    val>>=8;
    p[1] = val&0xff;
    val>>=8;
    p[2] = val&0xff;
    val>>=8;
    p[3] = val&0xff;
}

static id name_for_opcode(int opcode)
{
    if (opcode == 1) return @"CreateWindow";
    if (opcode == 2) return @"ChangeWindowAttributes";
    if (opcode == 3) return @"GetWindowAttributes";
    if (opcode == 4) return @"DestroyWindow";
    if (opcode == 5) return @"DestroySubwindows";
    if (opcode == 6) return @"ChangeSaveSet";
    if (opcode == 7) return @"ReparentWindow";
    if (opcode == 8) return @"MapWindow";
    if (opcode == 9) return @"MapSubwindows";
    if (opcode == 10) return @"UnmapWindow";
    if (opcode == 11) return @"UnmapSubwindows";
    if (opcode == 12) return @"ConfigureWindow";
    if (opcode == 13) return @"CirculateWindow";
    if (opcode == 14) return @"GetGeometry";
    if (opcode == 15) return @"QueryTree";
    if (opcode == 16) return @"InternAtom";
    if (opcode == 17) return @"GetAtomName";
    if (opcode == 18) return @"ChangeProperty";
    if (opcode == 19) return @"DeleteProperty";
    if (opcode == 20) return @"GetProperty";
    if (opcode == 21) return @"ListProperties";
    if (opcode == 22) return @"SetSelectionOwner";
    if (opcode == 23) return @"GetSelectionOwner";
    if (opcode == 24) return @"ConvertSelection";
    if (opcode == 25) return @"SendEvent";
    if (opcode == 26) return @"GrabPointer";
    if (opcode == 27) return @"UngrabPointer";
    if (opcode == 28) return @"GrabButton";
    if (opcode == 29) return @"UngrabButton";
    if (opcode == 30) return @"ChangeActivePointerGrab";
    if (opcode == 31) return @"GrabKeyboard";
    if (opcode == 32) return @"UngrabKeyboard";
    if (opcode == 33) return @"GrabKey";
    if (opcode == 34) return @"UngrabKey";
    if (opcode == 35) return @"AllowEvents";
    if (opcode == 36) return @"GrabServer";
    if (opcode == 37) return @"UngrabServer";
    if (opcode == 38) return @"QueryPointer";
    if (opcode == 39) return @"GetMotionEvents";
    if (opcode == 40) return @"TranslateCoordinates";
    if (opcode == 41) return @"WarpPointer";
    if (opcode == 42) return @"SetInputFocus";
    if (opcode == 43) return @"GetInputFocus";
    if (opcode == 44) return @"QueryKeymap";
    if (opcode == 45) return @"OpenFont";
    if (opcode == 46) return @"CloseFont";
    if (opcode == 47) return @"QueryFont";
    if (opcode == 48) return @"QueryTextExtents";
    if (opcode == 49) return @"ListFonts";
    if (opcode == 50) return @"ListFontsWithInfo";
    if (opcode == 51) return @"SetFontPath";
    if (opcode == 52) return @"GetFontPath";
    if (opcode == 53) return @"CreatePixmap";
    if (opcode == 54) return @"FreePixmap";
    if (opcode == 55) return @"CreateGC";
    if (opcode == 56) return @"ChangeGC";
    if (opcode == 57) return @"CopyGC";
    if (opcode == 58) return @"SetDashes";
    if (opcode == 59) return @"SetClipRectangles";
    if (opcode == 60) return @"FreeGC";
    if (opcode == 61) return @"ClearArea";
    if (opcode == 62) return @"CopyArea";
    if (opcode == 63) return @"CopyPlane";
    if (opcode == 64) return @"PolyPoint";
    if (opcode == 65) return @"PolyLine";
    if (opcode == 66) return @"PolySegment";
    if (opcode == 67) return @"PolyRectangle";
    if (opcode == 68) return @"PolyArc";
    if (opcode == 69) return @"FillPoly";
    if (opcode == 70) return @"PolyFillRectangle";
    if (opcode == 71) return @"PolyFillArc";
    if (opcode == 72) return @"PutImage";
    if (opcode == 73) return @"GetImage";
    if (opcode == 74) return @"PolyText8";
    if (opcode == 75) return @"PolyText16";
    if (opcode == 76) return @"ImageText8";
    if (opcode == 77) return @"ImageText16";
    if (opcode == 78) return @"CreateColormap";
    if (opcode == 79) return @"FreeColormap";
    if (opcode == 80) return @"CopyColormapAndFree";
    if (opcode == 81) return @"InstallColormap";
    if (opcode == 82) return @"UninstallColormap";
    if (opcode == 83) return @"ListInstalledColormaps";
    if (opcode == 84) return @"AllocColor";
    if (opcode == 85) return @"AllocNamedColor";
    if (opcode == 86) return @"AllocColorCells";
    if (opcode == 87) return @"AllocColorPlanes";
    if (opcode == 88) return @"FreeColors";
    if (opcode == 89) return @"StoreColors";
    if (opcode == 90) return @"StoreNamedColor";
    if (opcode == 91) return @"QueryColors";
    if (opcode == 92) return @"LookupColor";
    if (opcode == 93) return @"CreateCursor";
    if (opcode == 94) return @"CreateGlyphCursor";
    if (opcode == 95) return @"FreeCursor";
    if (opcode == 96) return @"RecolorCursor";
    if (opcode == 97) return @"QueryBestSize";
    if (opcode == 98) return @"QueryExtension";
    if (opcode == 99) return @"ListExtensions";
    if (opcode == 100) return @"ChangeKeyboardMapping";
    if (opcode == 101) return @"GetKeyboardMapping";
    if (opcode == 102) return @"ChangeKeyboardControl";
    if (opcode == 103) return @"GetKeyboardControl";
    if (opcode == 104) return @"Bell";
    if (opcode == 105) return @"ChangePointerControl";
    if (opcode == 106) return @"GetPointerControl";
    if (opcode == 107) return @"SetScreenSaver";
    if (opcode == 108) return @"GetScreenSaver";
    if (opcode == 109) return @"ChangeHosts";
    if (opcode == 110) return @"ListHosts";
    if (opcode == 111) return @"SetAccessControl";
    if (opcode == 112) return @"SetCloseDownMode";
    if (opcode == 113) return @"KillClient";
    if (opcode == 114) return @"RotateProperties";
    if (opcode == 115) return @"ForceScreenSaver";
    if (opcode == 116) return @"SetPointerMapping";
    if (opcode == 117) return @"GetPointerMapping";
    if (opcode == 118) return @"SetModifierMapping";
    if (opcode == 119) return @"GetModifierMapping";
    if (opcode == 127) return @"NoOperation";
    return @"unknown";
}

id name_for_predefined_atom(int atom)
{
    if (atom == 1) return @"PRIMARY";
    if (atom == 2) return @"SECONDARY";
    if (atom == 3) return @"ARC";
    if (atom == 4) return @"ATOM";
    if (atom == 5) return @"BITMAP";
    if (atom == 6) return @"CARDINAL";
    if (atom == 7) return @"COLORMAP";
    if (atom == 8) return @"CURSOR";
    if (atom == 9) return @"CUT_BUFFER0";
    if (atom == 10) return @"CUT_BUFFER1";
    if (atom == 11) return @"CUT_BUFFER2";
    if (atom == 12) return @"CUT_BUFFER3";
    if (atom == 13) return @"CUT_BUFFER4";
    if (atom == 14) return @"CUT_BUFFER5";
    if (atom == 15) return @"CUT_BUFFER6";
    if (atom == 16) return @"CUT_BUFFER7";
    if (atom == 17) return @"DRAWABLE";
    if (atom == 18) return @"FONT";
    if (atom == 19) return @"INTEGER";
    if (atom == 20) return @"PIXMAP";
    if (atom == 21) return @"POINT";
    if (atom == 22) return @"RECTANGLE";
    if (atom == 23) return @"RESOURCE_MANAGER";
    if (atom == 24) return @"RGB_COLOR_MAP";
    if (atom == 25) return @"RGB_BEST_MAP";
    if (atom == 26) return @"RGB_BLUE_MAP";
    if (atom == 27) return @"RGB_DEFAULT_MAP";
    if (atom == 28) return @"RGB_GRAY_MAP";
    if (atom == 29) return @"RGB_GREEN_MAP";
    if (atom == 30) return @"RGB_RED_MAP";
    if (atom == 31) return @"STRING";
    if (atom == 32) return @"VISUALID";
    if (atom == 33) return @"WINDOW";
    if (atom == 34) return @"WM_COMMAND";
    if (atom == 35) return @"WM_HINTS";
    if (atom == 36) return @"WM_CLIENT_MACHINE";
    if (atom == 37) return @"WM_ICON_NAME";
    if (atom == 38) return @"WM_ICON_SIZE";
    if (atom == 39) return @"WM_NAME";
    if (atom == 40) return @"WM_NORMAL_HINTS";
    if (atom == 41) return @"WM_SIZE_HINTS";
    if (atom == 42) return @"WM_ZOOM_HINTS";
    if (atom == 43) return @"MIN_SPACE";
    if (atom == 44) return @"NORM_SPACE";
    if (atom == 45) return @"MAX_SPACE";
    if (atom == 46) return @"END_SPACE";
    if (atom == 47) return @"SUPERSCRIPT_X";
    if (atom == 48) return @"SUPERSCRIPT_Y";
    if (atom == 49) return @"SUBSCRIPT_X";
    if (atom == 50) return @"SUBSCRIPT_Y";
    if (atom == 51) return @"UNDERLINE_POSITION";
    if (atom == 52) return @"UNDERLINE_THICKNESS";
    if (atom == 53) return @"STRIKEOUT_ASCENT";
    if (atom == 54) return @"STRIKEOUT_DESCENT";
    if (atom == 55) return @"ITALIC_ANGLE";
    if (atom == 56) return @"X_HEIGHT";
    if (atom == 57) return @"QUAD_WIDTH";
    if (atom == 58) return @"WEIGHT";
    if (atom == 59) return @"POINT_SIZE";
    if (atom == 60) return @"RESOLUTION";
    if (atom == 61) return @"COPYRIGHT";
    if (atom == 62) return @"NOTICE";
    if (atom == 63) return @"FONT_NAME";
    if (atom == 64) return @"FAMILY_NAME";
    if (atom == 65) return @"FULL_NAME";
    if (atom == 66) return @"CAP_HEIGHT";
    if (atom == 67) return @"WM_CLASS";
    if (atom == 68) return @"WM_TRANSIENT_FOR";
    return nil;
}

@implementation Definitions(fjkewlmfkldsmfklmsdklfm)
+ (id)XServer
{
    int port = 6002;

    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        NSLog(@"unable to create socket");
        exit(1);
    }
 
    int sock_opt = 1;
    if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT, &sock_opt, sizeof(sock_opt))) {
        NSLog(@"setsockopt failed");
        exit(1);
    }
    _addr.sin_family = AF_INET;
    _addr.sin_addr.s_addr = INADDR_ANY;
    _addr.sin_port = htons(port);
 
    if (bind(sockfd, (struct sockaddr *)&_addr, sizeof(_addr)) < 0) {
        NSLog(@"unable to bind socket to port %d", port);
        exit(1);
    }

    if (listen(sockfd, 5) < 0) {
        NSLog(@"listen failed");
        exit(1);
    }

    id obj = [@"XServer" asInstance];
    [obj setValue:nsfmt(@"%d", sockfd) forKey:@"sockfd"];

    [obj setAsValueForKey:@"XServer"];
    return obj;
}
@end

@interface XServer : IvarObject
{
    int _sockfd;
    id _connections;

    int _rootWindow;
    int _colormap;
    int _visualStaticGray;
    int _visualTrueColor24;
    int _visualTrueColor32;
    int _internAtomCounter;
    id _internAtoms;
    id _windows;
    id _shmSegments;

    int _scrollY;
    int _mouseX;
    int _mouseY;
    Int4 _rect;
    int _currentColumn;
}
@end
@implementation XServer
- (void)removeCurrentColumn
{
    if (_currentColumn >= 1) {
        if (_currentColumn <= [_connections count]) {
            [_connections removeObjectAtIndex:_currentColumn-1];
        }
    }
}
- (id)contextualMenu
{
NSLog(@"XServer contextualMenu");
    if (_currentColumn >= 1) {
        if (_currentColumn <= [_connections count]) {
            id elt = [_connections nth:_currentColumn-1];
            return [elt contextualMenu];
        }
    }
    return nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        _sockfd = -1;

        _rootWindow = 99;
        _colormap = 98;
        _visualStaticGray = 97;
        _visualTrueColor24 = 96;
        _visualTrueColor32 = 95;
        _internAtomCounter = 100;
        [self setValue:nsdict() forKey:@"internAtoms"];

        id rootWindow = nsdict();
        [rootWindow setValue:@"32" forKey:@"depth"];
        [rootWindow setValue:@"1024" forKey:@"width"];
        [rootWindow setValue:@"768" forKey:@"height"];
        id windows = nsdict();
        [windows setValue:rootWindow forKey:@"99"];
        [self setValue:windows forKey:@"windows"];
        [self setValue:nsdict() forKey:@"shmSegments"];

        [self setValue:nsarr() forKey:@"connections"];
    }
    return self;
}
- (int *)fileDescriptors
{
    static int _fds[256];

    _fds[0] = _sockfd;
    int fdCount = 1;

    for (int i=0; i<[_connections count]; i++) {
        id elt = [_connections nth:i];
        int connfd = [elt intValueForKey:@"connfd"];
        if (connfd < 0) {
            continue;
        }
        _fds[fdCount] = connfd;
        fdCount++;
        if (fdCount == 255) {
            break;
        }
    }

    _fds[fdCount] = -1;
    return _fds;

}

- (void)handleFileDescriptor:(int)fd
{
    NSLog(@"XServer handleFileDescriptor:%d", fd);
    if (fd == _sockfd) {
        [self handleSocketFileDescriptor];
        return;
    }

    for (int i=0; i<[_connections count]; i++) {
        id elt = [_connections nth:i];
        int connfd = [elt intValueForKey:@"connfd"];
        if (fd == connfd) {
            [elt handleFileDescriptor];
            return;
        }
    }

    NSLog(@"unhandled fd %d", fd);
}

- (void)handleSocketFileDescriptor
{
    NSLog(@"XServer handleSocketFileDescriptor");
    if (_sockfd < 0) {
        return;
    }

    socklen_t addrlen = sizeof(_addr);
    int connfd = accept(_sockfd, (struct sockaddr *)&_addr, &addrlen);
    if (connfd < 0) {
        NSLog(@"accept failed");
        return;
    }

    NSLog(@"connfd %d", connfd);
    id connection = [@"XServerConnection" asInstance];
    [connection setValue:nsfmt(@"%d", connfd) forKey:@"connfd"];
    [_connections addObject:connection];
}
- (void)drawInBitmap:(id)bitmap rect:(Int4)r
{
    _rect = r;

    int numberOfColumns = [_connections count] + 1;
    int columnWidth = r.w/numberOfColumns;


    [bitmap useAtariSTFont];
    [bitmap setColor:@"white"];
    [bitmap fillRect:r];
    [bitmap setColor:@"black"];

    int textHeight = [bitmap bitmapHeightForText:@"X"];


    int cursorY = r.y+_scrollY;

    id arr = nsarr();
    [arr addObject:nsfmt(@"sockfd %d", _sockfd)];
    for (int i=0; i<[_connections count]; i++) {
        id elt = [_connections nth:i];
        [arr addObject:nsfmt(@"connection %d: %@", i, elt)];
    }
    [arr addObject:nsfmt(@"rootWindow %d", _rootWindow)];
    [arr addObject:nsfmt(@"colormap %d", _colormap)];
    [arr addObject:nsfmt(@"visualStaticGray %d", _visualStaticGray)];
    [arr addObject:nsfmt(@"visualTrueColor24 %d", _visualTrueColor24)];
    [arr addObject:nsfmt(@"visualTrueColor32 %d", _visualTrueColor32)];
    [arr addObject:nsfmt(@"internAtomCounter %d", _internAtomCounter)];
    [arr addObject:nsfmt(@"internAtoms %@", _internAtoms)];
    [arr addObject:nsfmt(@"windows %@", [_windows allKeys])];
    [arr addObject:nsfmt(@"mouseX %d", _mouseX)];
    [arr addObject:nsfmt(@"mouseY %d", _mouseY)];
    [arr addObject:nsfmt(@"shmSegments %@", _shmSegments)];

    id windowsAllKeys = [_windows allKeys];
    for (int i=0; i<[windowsAllKeys count]; i++) {
        id key = [windowsAllKeys nth:i];
        id val = [_windows valueForKey:key];
        cursorY += 10;
        id text = nsfmt(@"window %@ x:%@ y:%@ width:%@ height:%@", key, [val valueForKey:@"x"], [val valueForKey:@"y"], [val valueForKey:@"width"], [val valueForKey:@"height"]);
        text = [bitmap fitBitmapString:text width:columnWidth-10];
        [bitmap drawBitmapText:text x:r.x+5 y:cursorY];
        cursorY += [bitmap bitmapHeightForText:text];
        id valBitmap = [val valueForKey:@"bitmap"];
        [bitmap drawBitmap:valBitmap x:r.x+5 y:cursorY];
        cursorY += [valBitmap bitmapHeight];
    }


    id text = [arr join:@"\n"];
    text = [bitmap fitBitmapString:text width:columnWidth-10];
    cursorY += 10;
    [bitmap drawBitmapText:text x:r.x+5 y:cursorY];

    for (int i=0; i<[_connections count]; i++) {
        id elt = [_connections nth:i];
        Int4 rr;
        rr.x = columnWidth*(i+1);
        rr.y = r.y;
        rr.w = columnWidth;
        rr.h = r.h;
        [bitmap setColor:@"black"];
        [bitmap drawVerticalLineAtX:rr.x-1 y:r.y y:r.y+r.h-1];
        [elt drawInBitmap:bitmap rect:rr];
    }

    [bitmap setColor:@"blue"];
    Int4 rr;
    rr.x = columnWidth*_currentColumn;
    rr.y = r.y;
    rr.w = columnWidth-1;
    rr.h = r.h;
    [bitmap drawRectangle:rr];
}
- (id)nameForAtom:(int)atom
{
    if (atom < 100) {
        return name_for_predefined_atom(atom);
    }
    id key = nsfmt(@"%d", atom);
    return [_internAtoms valueForKey:key];
}
- (void)handleMouseMoved:(id)event
{
    _mouseX = [event intValueForKey:@"mouseX"];
    _mouseY = [event intValueForKey:@"mouseY"];
    int numberOfColumns = [_connections count]+1;
    int columnWidth = _rect.w / numberOfColumns;
    _currentColumn = _mouseX / columnWidth;
}
- (void)handleScrollWheel:(id)event
{
    if (_currentColumn >= 1) {
        if (_currentColumn <= [_connections count]) {
            id elt = [_connections nth:_currentColumn-1];
            [elt handleScrollWheel:event];
            return;
        }
    }

    _scrollY += [event intValueForKey:@"deltaY"];
}
- (void)handleMouseDown:(id)event
{
    if (_currentColumn >= 1) {
        if (_currentColumn <= [_connections count]) {
            id elt = [_connections nth:_currentColumn-1];
            [elt sendResponse];
            return;
        }
    }
}
@end

@interface XServerConnection : IvarObject
{
    BOOL _auto;
    int _sequenceNumber;
    int _connfd;
    id _data;
    id _request;

    int _scrollY;
    int _mouseX;
    int _mouseY;

}
@end
@implementation XServerConnection
- (id)nameForAtom:(int)atom
{
    id xserver = [@"XServer" valueForKey];
    return [xserver nameForAtom:atom];
}
- (id)contextualMenu
{
static id str =
@"hotKey,displayName,messageForClick\n"
@"r,sendResponse,sendResponse\n"
@",consumeRequest,consumeRequest\n"
@",parseData,parseData\n"
@"1,sendKeyPressEvent:2,sendKeyPressEvent:2\n"
@"return,sendKeyPressEvent:28,sendKeyPressEvent:28\n"
@"a,sendKeyPressEvent:30,sendKeyPressEvent:30\n"
@"m,sendMotionNotifyEvent,sendMotionNotifyEvent\n"
@"b,sendButtonPressEvent,sendButtonPressEvent;sendButtonReleaseEvent\n"
@",toggle auto,\"toggleBoolKey:'auto'\"\n"
@",Reset Sequence Number,\"setValue:0 forKey:'sequenceNumber'\"\n"
@",,\n"
@",removeCurrentColumn,\"'XServer'|valueForKey|removeCurrentColumn\"\n"
;
    id menu = [[str parseCSVFromString] asMenu];
    [menu setValue:self forKey:@"contextualObject"];
    return menu;
}

- (int)fileDescriptor
{
    return _connfd;
}

- (void)handleFileDescriptor
{
    NSLog(@"XServerConnection handleFileDescriptor");
    if (_connfd < 0) {
        return;
    }

    if (!_data) {
        [self setValue:[[[NSMutableData alloc] initWithCapacity:1024*1024] autorelease] forKey:@"data"];
    }

    char buf[65536];
NSLog(@"reading from %d", _connfd);
    int result = recv(_connfd, buf, sizeof(buf), MSG_DONTWAIT);
NSLog(@"result %d", result);
    if (result > 0) {
        [_data appendBytes:buf length:result];
        [self setValue:nil forKey:@"request"];
        [self parseData];
    } else if (result == 0) {
        close(_connfd);
        _connfd = -1;
    } else {
        NSLog(@"read error %d %s", errno, strerror(errno));
        if (errno == EAGAIN) {
        } else if (errno == EINTR) {
        }
    }
}
- (void)drawInBitmap:(id)bitmap rect:(Int4)r
{
    [bitmap useAtariSTFont];
    [bitmap setColor:@"white"];
    [bitmap fillRect:r];
    [bitmap setColor:@"black"];

    int textHeight = [bitmap bitmapHeightForText:@"X"];

    int cursorY = r.y+_scrollY;



    if (_sequenceNumber) {
        int len = [_data length];
        if (len < 4) {
            id text = @"not enough data";
            cursorY += 10;
            [bitmap drawBitmapText:text x:r.x+5 y:cursorY];
            cursorY += [bitmap bitmapHeightForText:text];
        } else {
            unsigned char *bytes = [_data bytes];

            int opcode = bytes[0];
            int requestLength = read_uint16(bytes+2);
            id text = nsfmt(@"opcode %d (%@) requestLength %d\n", opcode, name_for_opcode(opcode), requestLength);
            cursorY += 10;
            [bitmap drawBitmapText:text x:r.x+5 y:cursorY];
            cursorY += [bitmap bitmapHeightForText:text];
        }
    }


    if (_request) {
        cursorY += 10;
        if (isnsdict(_request)) {
            id keys = [_request allKeys];
            for (int i=0; i<[keys count]; i++) {
                id key = [keys nth:i];
                id val = [_request valueForKey:key];
                if (isnsdict(val)) {
                    id text = nsfmt(@"%@:keys=%@", key, [val allKeys]);
                    [bitmap drawBitmapText:text x:r.x+5 y:cursorY];
                    cursorY += [bitmap bitmapHeightForText:text];
                } else {
                    id text = nsfmt(@"%@:%@", key, val);
                    [bitmap drawBitmapText:text x:r.x+5 y:cursorY];
                    cursorY += [bitmap bitmapHeightForText:text];
                    if ([[val className] isEqual:@"Bitmap"]) {
                        [bitmap drawBitmap:val x:r.x y:cursorY];
                        cursorY += [val bitmapHeight];
                    }
                }
            }
        } else {
            [bitmap drawBitmapText:_request x:r.x+5 y:cursorY];
            cursorY += [bitmap bitmapHeightForText:_request];
        }
    }

    id arr = nsarr();
    [arr addObject:nsfmt(@"auto %d", _auto)];
    [arr addObject:nsfmt(@"sequenceNumber %d", _sequenceNumber)];
    [arr addObject:nsfmt(@"connfd %d", _connfd)];

    [arr addObject:nsfmt(@"data length %d", [_data length])];
    unsigned char *bytes = [_data bytes];
    int upToLen = [_data length];
    if (upToLen > 100) {
        upToLen = 100;
    }
    for (int i=0; i<upToLen; i++) {
        [arr addObject:nsfmt(@"i %d 0x%.2x %d %c", i, bytes[i], bytes[i], (isprint(bytes[i]) ? bytes[i] : '.'))];
    }
    id text = [arr join:@"\n"];
    text = [bitmap fitBitmapString:text width:r.w-10];
    cursorY += 10;
    [bitmap drawBitmapText:text x:r.x+5 y:cursorY];
}
- (void)handleScrollWheel:(id)event
{
    _scrollY += [event intValueForKey:@"deltaY"];
}
- (void)handleMouseMoved:(id)event
{
    _mouseX = [event intValueForKey:@"mouseX"];
    _mouseY = [event intValueForKey:@"mouseY"];
}
- (void)clearData
{
    [_data setLength:0];
}
- (void)consumeRequest
{
    [self setValue:nil forKey:@"request"];

    if (!_sequenceNumber) {
        [_data deleteBytesFromIndex:0 length:12];
        _sequenceNumber = 1;
        [self parseData];
        return;
    }

    int len = [_data length];
    if (len < 4) {
        return;
    }
    unsigned char *bytes = [_data bytes];

    int opcode = bytes[0];
    int requestLength = read_uint16(bytes+2);
    if (len < requestLength*4) {
        return;
    }
    [_data deleteBytesFromIndex:0 length:requestLength*4];
    _sequenceNumber++;
    [self parseData];
}
- (void)parseData
{
    if (_sequenceNumber) {
        [self parseRequest];
        return;
    }

    int len = [_data length];
    if (len < 12) {
        return;
    }
    unsigned char *bytes = [_data bytes];
    unsigned char *p = bytes;

    int byteOrderMSB = (*p == 0x42) ? 1 : 0;
    int byteOrderLSB = (*p == 0x6c) ? 1 : 0;
    p++;

    p++;

    int protocolMajorVersion = read_uint16(p);
    p+=2;

    int protocolMinorVersion = read_uint16(p);
    p+=2;

    int lengthOfAuthorizationProtocolName = read_uint16(p);
    p+=2;

    int lengthOfAuthorizationProtocolData = read_uint16(p);
    p+=2;

    p+=2;

    id text = nsfmt(
@"byteOrderMSB %d\n"
@"byteOrderLSB %d\n"
@"protocolMajorVersion %d\n"
@"protocolMinorVersion %d\n"
@"lengthOfAuthorizationProtocolName %d\n"
@"lengthOfAuthorizationProtocolData %d\n",
byteOrderMSB, byteOrderLSB,
protocolMajorVersion, protocolMinorVersion,
lengthOfAuthorizationProtocolName,
lengthOfAuthorizationProtocolData);
    [self setValue:text forKey:@"request"];
    
}
- (void)parseRequest
{
    int len = [_data length];
    if (len < 4) {
        [self setValue:@"not enough data" forKey:@"request"];
        return;
    }
    unsigned char *bytes = [_data bytes];

    int opcode = bytes[0];
    int requestLength = read_uint16(bytes+2);
    if (len < requestLength*4) {
        [self setValue:@"not enough data" forKey:@"request"];
        return;
    }

    id results = nil;
    if (opcode == 98) { results = [self parseQueryExtensionRequest:requestLength]; }
    else if (opcode == 55) { results = [self parseCreateGCRequest:requestLength]; }
    else if (opcode == 20) { results = [self parseGetPropertyRequest:requestLength]; }
    else if (opcode == 45) { results = [self parseOpenFontRequest:requestLength]; }
    else if (opcode == 16) { results = [self parseInternAtomRequest:requestLength]; }
    else if (opcode == 47) { results = [self parseQueryFontRequest:requestLength]; }
    else if (opcode == 53) { results = [self parseCreatePixmapRequest:requestLength]; }
    else if (opcode == 54) { results = [self parseFreePixmapRequest:requestLength]; }
    else if (opcode == 94) { results = [self parseCreateGlyphCursorRequest:requestLength]; }
    else if (opcode == 72) { results = [self parsePutImageRequest:requestLength]; }
    else if (opcode == 60) { results = [self parseFreeGCRequest:requestLength]; }
    else if (opcode == 1) { results = [self parseCreateWindowRequest:requestLength]; }
    else if (opcode == 18) { results = [self parseChangePropertyRequest:requestLength]; }
    else if (opcode == 46) { results = [self parseCloseFontRequest:requestLength]; }
    else if (opcode == 12) { results = [self parseConfigureWindowRequest:requestLength]; }
    else if (opcode == 96) { results = [self parseRecolorCursorRequest:requestLength]; }
    else if (opcode == 2) { results = [self parseChangeWindowAttributesRequest:requestLength]; }
    else if (opcode == 3) { results = [self parseGetWindowAttributesRequest:requestLength]; }
    else if (opcode == 14) { results = [self parseGetGeometryRequest:requestLength]; }
    else if (opcode == 101) { results = [self parseGetKeyboardMappingRequest:requestLength]; }
    else if (opcode == 28) { results = [self parseGrabButtonRequest:requestLength]; }
    else if (opcode == 84) { results = [self parseAllocColorRequest:requestLength]; }
    else if (opcode == 9) { results = [self parseMapSubwindowsRequest:requestLength]; }
    else if (opcode == 8) { results = [self parseMapWindowRequest:requestLength]; }
    else if (opcode == 76) { results = [self parseImageText8Request:requestLength]; }
    else if (opcode == 65) { results = [self parsePolyLineRequest:requestLength]; }
    else if (opcode == 62) { results = [self parseCopyAreaRequest:requestLength]; }
    else if (opcode == 61) { results = [self parseClearAreaRequest:requestLength]; }
    else if (opcode == 112) { results = [self parseSetCloseDownModeRequest:requestLength]; }
    else if (opcode == 25) { results = [self parseSendEventRequest:requestLength]; }
    else if (opcode == 23) { results = [self parseGetSelectionOwnerRequest:requestLength]; }
    else if (opcode == 38) { results = [self parseQueryPointerRequest:requestLength]; }
    else if (opcode == 40) { results = [self parseTranslateCoordinatesRequest:requestLength]; }
    else if (opcode == 115) { results = [self parseForceScreenSaverRequest:requestLength]; }
    else if (opcode == 10) { results = [self parseUnmapWindowRequest:requestLength]; }
    else if (opcode == 4) { results = [self parseDestroyWindowRequest:requestLength]; }
    else if (opcode == 79) { results = [self parseFreeColormapRequest:requestLength]; }
    else if (opcode == 44) { results = [self parseQueryKeymapRequest:requestLength]; }
    else if (opcode == 103) { results = [self parseGetKeyboardControlRequest:requestLength]; }
    else if (opcode == 129) {
        int minoropcode = bytes[1];
        if (minoropcode == 0) {
            results = [self parsePresentQueryVersionRequest:requestLength];
        }
    } else if (opcode == 130) {
        int minoropcode = bytes[1];
        if (minoropcode == 0) {
            results = [self parseXFixesQueryVersionRequest:requestLength];
        }
    } else if (opcode == 135) {
        int minoropcode = bytes[1];
        if (minoropcode == 0) {
            results = [self parseMITSHMQueryVersionRequest:requestLength];
        } else if (minoropcode == 1) {
            results = [self parseMITSHMAttachRequest:requestLength];
        } else if (minoropcode == 2) {
            results = [self parseMITSHMDetachRequest:requestLength];
        } else if (minoropcode == 3) {
            results = [self parseMITSHMPutImageRequest:requestLength];
        }
    }

    [self setValue:results forKey:@"request"];
}

- (id)parseFreeColormapRequest:(int)requestLength
{
    if (requestLength != 2) {
        return nil;
    }

    unsigned char *bytes = [_data bytes];

    id results = nsdict();

    uint32_t colormap = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", colormap) forKey:@"colormap"];

    return results;
}
- (id)parseQueryKeymapRequest:(int)requestLength
{
    if (requestLength != 1) {
        return nil;
    }

    id results = nsdict();

    return results;
}
- (id)parseGetKeyboardControlRequest:(int)requestLength
{
    if (requestLength != 1) {
        return nil;
    }

    id results = nsdict();

    return results;
}
- (id)parseDestroyWindowRequest:(int)requestLength
{
    if (requestLength != 2) {
        return nil;
    }

    unsigned char *bytes = [_data bytes];

    id results = nsdict();

    uint32_t window = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", window) forKey:@"window"];

    return results;
}
- (id)parseUnmapWindowRequest:(int)requestLength
{
    if (requestLength != 2) {
        return nil;
    }

    unsigned char *bytes = [_data bytes];

    id results = nsdict();

    uint32_t window = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", window) forKey:@"window"];

    return results;
}

- (id)parseForceScreenSaverRequest:(int)requestLength
{
    if (requestLength != 1) {
        return nil;
    }

    unsigned char *bytes = [_data bytes];

    int mode = bytes[1]; //0=reset 1=activate

    id results = nsdict();
    [results setValue:nsfmt(@"%d", mode) forKey:@"mode"];
    [results setValue:@"0=reset 1=activate" forKey:@"modeDescription"];

    return results;
}
- (id)parseTranslateCoordinatesRequest:(int)requestLength
{
    if (requestLength != 4) {
        return nil;
    }

    unsigned char *bytes = [_data bytes];

    uint32_t srcWindow = read_uint32(bytes+4);
    uint32_t dstWindow = read_uint32(bytes+8);
    int srcX = read_uint16(bytes+12);
    int srcY = read_uint16(bytes+14);

    id results = nsdict();
    [results setValue:nsfmt(@"%lu", srcWindow) forKey:@"srcWindow"];
    [results setValue:nsfmt(@"%lu", dstWindow) forKey:@"dstWindow"];
    [results setValue:nsfmt(@"%d", srcX) forKey:@"srcX"];
    [results setValue:nsfmt(@"%d", srcY) forKey:@"srcY"];

    return results;
}
- (id)parseQueryExtensionRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    int lengthOfName = read_uint16(bytes+4);

    if (requestLength != 2+((lengthOfName+3)/4)) {
        return nil;
    }

    id name = @"";
    if (lengthOfName > 0) {
        name = nsfmt(@"%.*s", lengthOfName, bytes+8);
    }

    id results = nsdict();
    [results setValue:nsfmt(@"%d", lengthOfName) forKey:@"lengthOfName"];
    [results setValue:name forKey:@"name"];
    return results;
}
- (id)parseCreateGCRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength < 4) {
        return nil;
    }

    id results = nsdict();

    uint32_t cid = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", cid) forKey:@"cid"];
    [results setValue:nsfmt(@"0x%x", cid) forKey:@"cidHex"];

    uint32_t drawable = read_uint32(bytes+8);
    [results setValue:nsfmt(@"%lu", drawable) forKey:@"drawable"];
    [results setValue:nsfmt(@"0x%x", drawable) forKey:@"drawableHex"];

    uint32_t valueMask = read_uint32(bytes+12);
    [results setValue:nsfmt(@"%lu", valueMask) forKey:@"valueMask"];
    [results setValue:nsfmt(@"0x%x", valueMask) forKey:@"valueMaskHex"];

    int numberOfBits = 0;
    for (int i=0; i<23; i++) {
        if (valueMask & (1L<<i)) {
            numberOfBits++;
        }
    }

    if (requestLength != 4+numberOfBits) {
        return nil;
    }

    char *p = bytes+16;
    if (valueMask & 0x000001) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"function"];
        [results setValue:@"0=Clear 1=And 2=AndReverse 3=Copy 4=AndInverted 5=NoOp 6=Xor 7=Or 8=Nor 9=Equiv 10=Invert 11=OrReverse 12=CopyInverted 13=OrInverted 14=Nand 15=Set" forKey:@"functionDescription"];
    }
    if (valueMask & 0x000002) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"planeMask"];
    }
    if (valueMask & 0x000004) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"foreground"];
    }
    if (valueMask & 0x000008) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"background"];
    }
    if (valueMask & 0x000010) {
        int val = read_uint16(p);
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"lineWidth"];
    }
    if (valueMask & 0x000020) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"lineStyle"];
        [results setValue:@"0=Solid 1=OnOffDash 2=DoubleDash" forKey:@"lineStyleDescription"];
    }
    if (valueMask & 0x000040) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"capStyle"];
        [results setValue:@"0=NotLast 1=Butt 2=Round 3=Projecting" forKey:@"capStyleDescription"];
    }
    if (valueMask & 0x000080) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"joinStyle"];
        [results setValue:@"0=Miter 1=Round 2=Bevel" forKey:@"joinStyleDescription"];
    }
    if (valueMask & 0x000100) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"fillStyle"];
        [results setValue:@"0=Solid 1=Tiled 2=Stippled 3=OpaqueStippled" forKey:@"fillStyleDescription"];
    }
    if (valueMask & 0x000200) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"fillRule"];
        [results setValue:@"0=EvenOdd 1=Winding" forKey:@"fillRuleDescription"];
    }
    if (valueMask & 0x000400) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"tile"];
    }
    if (valueMask & 0x000800) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"stipple"];
    }
    if (valueMask & 0x001000) {
        int val = read_uint16(p);
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"tileStippleXOrigin"];
    }
    if (valueMask & 0x002000) {
        int val = read_uint16(p);
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"tileStippleYOrigin"];
    }
    if (valueMask & 0x004000) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"font"];
    }
    if (valueMask & 0x008000) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"subwindowMode"];
        [results setValue:@"0=ClipByChildren 1=IncludeInferiors" forKey:@"subwindowModeDescription"];
    }
    if (valueMask & 0x010000) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"graphicsExposures"];
    }
    if (valueMask & 0x020000) {
        int val = read_uint16(p);
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"clipXOrigin"];
    }
    if (valueMask & 0x040000) {
        int val = read_uint16(p);
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"clipYOrigin"];
    }
    if (valueMask & 0x080000) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"clipMask"];
    }
    if (valueMask & 0x100000) {
        int val = read_uint16(p);
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"dashOffset"];
    }
    if (valueMask & 0x200000) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"dashes"];
    }
    if (valueMask & 0x400000) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"arcMode"];
        [results setValue:@"0=Chord 1=PieSlice" forKey:@"arcModeDescription"];
    }

    return results;
}
- (id)parseGetPropertyRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    int delete = bytes[1];

    if (requestLength != 6) {
NSLog(@"requestLength is not 6");
        return nil;
    }

    id results = nsdict();

    [results setValue:nsfmt(@"%d", delete) forKey:@"delete"];

    uint32_t window = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", window) forKey:@"window"];
    [results setValue:nsfmt(@"0x%x", window) forKey:@"windowHex"];

    uint32_t property = read_uint32(bytes+8);
    [results setValue:nsfmt(@"%lu", property) forKey:@"property"];
    [results setValue:nsfmt(@"0x%x", property) forKey:@"propertyHex"];
    [results setValue:[self nameForAtom:property] forKey:@"propertyAtom"];

    uint32_t type = read_uint32(bytes+12);
    [results setValue:nsfmt(@"%lu", type) forKey:@"type"];
    [results setValue:nsfmt(@"0x%x", type) forKey:@"typeHex"];
    [results setValue:[self nameForAtom:type] forKey:@"typeAtom"];

    uint32_t longOffset = read_uint32(bytes+16);
    [results setValue:nsfmt(@"%lu", longOffset) forKey:@"longOffset"];
    [results setValue:nsfmt(@"0x%x", longOffset) forKey:@"longOffsetHex"];

    uint32_t longLength = read_uint32(bytes+20);
    [results setValue:nsfmt(@"%lu", longLength) forKey:@"longLength"];
    [results setValue:nsfmt(@"0x%x", longLength) forKey:@"longLengthHex"];

    return results;
}
- (id)parseOpenFontRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength < 3) {
        return nil;
    }

    uint32_t fid = read_uint32(bytes+4);
    int lengthOfName = read_uint16(bytes+8);

    if (requestLength != 3+((lengthOfName+3)/4)) {
        return nil;
    }

    id name = @"";
    if (lengthOfName > 0) {
        name = nsfmt(@"%.*s", lengthOfName, bytes+12);
    }

    id results = nsdict();

    [results setValue:nsfmt(@"%lu", fid) forKey:@"fid"];
    [results setValue:nsfmt(@"0x%x", fid) forKey:@"fidHex"];
    [results setValue:name forKey:@"name"];

    return results;
}
- (id)parseInternAtomRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    int onlyIfExists = bytes[1];

    if (requestLength < 2) {
        return nil;
    }

    int lengthOfName = read_uint16(bytes+4);

    if (requestLength != 2+((lengthOfName+3)/4)) {
        return nil;
    }

    id name = @"";
    if (lengthOfName > 0) {
        name = nsfmt(@"%.*s", lengthOfName, bytes+8);
    }

    id results = nsdict();
    [results setValue:nsfmt(@"%d", onlyIfExists) forKey:@"onlyIfExists"];

    [results setValue:nsfmt(@"%d", lengthOfName) forKey:@"lengthOfName"];
    [results setValue:name forKey:@"name"];

    return results;
}
- (id)parseQueryFontRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength != 2) {
        return nil;
    }

    id results = nsdict();

    uint32_t fontable = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", fontable) forKey:@"fontable"];
    [results setValue:nsfmt(@"0x%x", fontable) forKey:@"fontableHex"];

    return results;
}
- (id)parseCreatePixmapRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength != 4) {
        return nil;
    }

    id results = nsdict();

    uint32_t pid = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", pid) forKey:@"pid"];
    [results setValue:nsfmt(@"0x%x", pid) forKey:@"pidHex"];

    uint32_t drawable = read_uint32(bytes+8);
    [results setValue:nsfmt(@"%lu", drawable) forKey:@"drawable"];
    [results setValue:nsfmt(@"0x%x", drawable) forKey:@"drawableHex"];

    uint16_t width = read_uint16(bytes+12);
    [results setValue:nsfmt(@"%d", width) forKey:@"width"];

    uint16_t height = read_uint16(bytes+14);
    [results setValue:nsfmt(@"%d", height) forKey:@"height"];

    return results;
}
- (id)parseFreePixmapRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength != 2) {
        return nil;
    }

    id results = nsdict();

    uint32_t pixmap = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", pixmap) forKey:@"pixmap"];
    [results setValue:nsfmt(@"0x%x", pixmap) forKey:@"pixmapHex"];

    return results;
}
- (id)parseCreateGlyphCursorRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength != 8) {
        return nil;
    }

    id results = nsdict();

    uint32_t cid = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", cid) forKey:@"cid"];
    [results setValue:nsfmt(@"0x%x", cid) forKey:@"cidHex"];

    uint32_t sourceFont = read_uint32(bytes+8);
    [results setValue:nsfmt(@"%lu", sourceFont) forKey:@"sourceFont"];
    [results setValue:nsfmt(@"0x%x", sourceFont) forKey:@"sourceFontHex"];

    uint32_t maskFont = read_uint32(bytes+12);
    [results setValue:nsfmt(@"%lu", maskFont) forKey:@"maskFont"];
    [results setValue:nsfmt(@"0x%x", maskFont) forKey:@"maskFontHex"];

    uint16_t sourceChar = read_uint16(bytes+16);
    [results setValue:nsfmt(@"%lu", sourceChar) forKey:@"sourceChar"];
    [results setValue:nsfmt(@"0x%x", sourceChar) forKey:@"sourceCharHex"];

    uint16_t maskChar = read_uint16(bytes+18);
    [results setValue:nsfmt(@"%lu", maskChar) forKey:@"maskChar"];
    [results setValue:nsfmt(@"0x%x", maskChar) forKey:@"maskCharHex"];

    uint16_t foreRed = read_uint16(bytes+20);
    [results setValue:nsfmt(@"%lu", foreRed) forKey:@"foreRed"];
    [results setValue:nsfmt(@"0x%x", foreRed) forKey:@"foreRedHex"];

    uint16_t foreGreen = read_uint16(bytes+22);
    [results setValue:nsfmt(@"%lu", foreGreen) forKey:@"foreGreen"];
    [results setValue:nsfmt(@"0x%x", foreGreen) forKey:@"foreGreenHex"];

    uint16_t foreBlue = read_uint16(bytes+24);
    [results setValue:nsfmt(@"%lu", foreBlue) forKey:@"foreBlue"];
    [results setValue:nsfmt(@"0x%x", foreBlue) forKey:@"foreBlueHex"];

    uint16_t backRed = read_uint16(bytes+26);
    [results setValue:nsfmt(@"%lu", backRed) forKey:@"backRed"];
    [results setValue:nsfmt(@"0x%x", backRed) forKey:@"backRedHex"];

    uint16_t backGreen = read_uint16(bytes+28);
    [results setValue:nsfmt(@"%lu", backGreen) forKey:@"backGreen"];
    [results setValue:nsfmt(@"0x%x", backGreen) forKey:@"backGreenHex"];

    uint16_t backBlue = read_uint16(bytes+30);
    [results setValue:nsfmt(@"%lu", backBlue) forKey:@"backBlue"];
    [results setValue:nsfmt(@"0x%x", backBlue) forKey:@"backBlueHex"];

    return results;
}

- (id)parsePutImageRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    int format = bytes[1];

    if (requestLength < 6) {
        return nil;
    }

    id results = nsdict();

    uint32_t drawable = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", drawable) forKey:@"drawable"];
    [results setValue:nsfmt(@"0x%x", drawable) forKey:@"drawableHex"];

    uint32_t gc = read_uint32(bytes+8);
    [results setValue:nsfmt(@"%lu", gc) forKey:@"gc"];
    [results setValue:nsfmt(@"0x%x", gc) forKey:@"gcHex"];

    int width = read_uint16(bytes+12);
    [results setValue:nsfmt(@"%d", width) forKey:@"width"];

    int height = read_uint16(bytes+14);
    [results setValue:nsfmt(@"%d", height) forKey:@"height"];

    int dstX = read_uint16(bytes+16);
    [results setValue:nsfmt(@"%d", dstX) forKey:@"dstX"];

    int dstY = read_uint16(bytes+18);
    [results setValue:nsfmt(@"%d", dstY) forKey:@"dstY"];

    int leftPad = bytes[20];
    [results setValue:nsfmt(@"%d", leftPad) forKey:@"leftPad"];

    int depth = bytes[21];
    [results setValue:nsfmt(@"%d", depth) forKey:@"depth"];

    if ((depth == 24) || (depth == 32)) {
        int len = [_data length];
        if (len >= width*height*4+6*4) {
            id bitmap = [Definitions bitmapWithWidth:width height:height];
            unsigned char *pixelBytes = [bitmap pixelBytes];
            memcpy(pixelBytes, bytes+24, width*height*4);
            [results setValue:bitmap forKey:@"bitmap"];
        }
    } else if (depth == 1) {
/*
        if (len >= (width*height+7)/8+6*4) {
            id bitmap = [Definitions bitmapWithWidth:width height:height];
            [bitmap setColor:@"white"];
            [bitmap fillRectangleAtX:0 y:0 w:width h:height];
            unsigned char *pixelBytes = [bitmap pixelBytes];
            for (int y=0; y<height; y++) {
                for (int x=0; x<width; x++) {
                }
            }
            [self setValue:bitmap forKey:@"putImageBitmap"];
        }
*/
    }

    return results;
}

- (id)parseFreeGCRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength != 2) {
        return nil;
    }

    id results = nsdict();

    uint32_t gc = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", gc) forKey:@"gc"];
    [results setValue:nsfmt(@"0x%x", gc) forKey:@"gcHex"];

    return results;
}
- (id)parseCreateWindowRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    int depth = bytes[1];

    if (requestLength < 8) {
        return nil;
    }

    id results = nsdict();
    [results setValue:nsfmt(@"%d", depth) forKey:@"depth"];

    uint32_t wid = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", wid) forKey:@"wid"];
    [results setValue:nsfmt(@"0x%x", wid) forKey:@"widHex"];

    uint32_t parent = read_uint32(bytes+8);
    [results setValue:nsfmt(@"%lu", parent) forKey:@"parent"];
    [results setValue:nsfmt(@"0x%x", parent) forKey:@"parentHex"];

    int x = read_uint16(bytes+12);
    [results setValue:nsfmt(@"%d", x) forKey:@"x"];

    int y = read_uint16(bytes+14);
    [results setValue:nsfmt(@"%d", y) forKey:@"y"];

    int width = read_uint16(bytes+16);
    [results setValue:nsfmt(@"%d", width) forKey:@"width"];

    int height = read_uint16(bytes+18);
    [results setValue:nsfmt(@"%d", height) forKey:@"height"];

    int borderWidth = read_uint16(bytes+20);
    [results setValue:nsfmt(@"%d", borderWidth) forKey:@"borderWidth"];

    int class = read_uint16(bytes+22);
    [results setValue:nsfmt(@"%d", class) forKey:@"class"];

    uint32_t visual = read_uint32(bytes+24);
    [results setValue:nsfmt(@"%lu", visual) forKey:@"visual"];
    [results setValue:nsfmt(@"0x%x", visual) forKey:@"visualHex"];

    uint32_t valueMask = read_uint32(bytes+28);
    [results setValue:nsfmt(@"%lu", valueMask) forKey:@"valueMask"];
    [results setValue:nsfmt(@"0x%x", valueMask) forKey:@"valueMaskHex"];

    int numberOfBits = 0;
    for (int i=0; i<15; i++) {
        if (valueMask & (1<<i)) {
            numberOfBits++;
        }
    }

    if (requestLength != 8+numberOfBits) {
        return nil;
    }

    id bitmap = nil;
    if (width && height) {
        bitmap = [Definitions bitmapWithWidth:width height:height];
        [bitmap useAtariSTFont];
        [bitmap setColor:@"black"];
        [bitmap fillRectangleAtX:0 y:0 w:width h:height];
        [results setValue:bitmap forKey:@"bitmap"];
    }

    char *p = bytes+32;
    if (valueMask & 0x0001) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"backgroundPixmap"];
        [results setValue:@"0=None 1=ParentRelative" forKey:@"backgroundPixmapDescription"];
    }
    if (valueMask & 0x0002) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"backgroundPixel"];
    }
    if (valueMask & 0x0004) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"borderPixmap"];
        [results setValue:@"0=CopyFromParent" forKey:@"borderPixmapDescription"];
    }
    if (valueMask & 0x0008) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"borderPixel"];
    }
    if (valueMask & 0x0010) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"bitGravity"];
    }
    if (valueMask & 0x0020) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"winGravity"];
    }
    if (valueMask & 0x0040) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"backingStore"];
        [results setValue:@"0=NotUseful 1=WhenMapped 2=Always" forKey:@"backingStoreDescription"];
    }
    if (valueMask & 0x0080) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"backingPlanes"];
    }
    if (valueMask & 0x0100) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"backingPixel"];
    }
    if (valueMask & 0x0200) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"overrideRedirect"];
    }
    if (valueMask & 0x0400) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"saveUnder"];
    }
    if (valueMask & 0x0800) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"eventMask"];
    }
    if (valueMask & 0x1000) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"doNotPropagateMask"];
    }
    if (valueMask & 0x2000) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"colormap"];
        [results setValue:@"0=CopyFromParent" forKey:@"colormapDescription"];
    }
    if (valueMask & 0x4000) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"cursor"];
    }

    return results;
}
- (id)parseChangeWindowAttributesRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength < 3) {
        return nil;
    }

    id results = nsdict();

    uint32_t window = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", window) forKey:@"window"];
    [results setValue:nsfmt(@"0x%x", window) forKey:@"windowHex"];

    uint32_t valueMask = read_uint32(bytes+8);
    [results setValue:nsfmt(@"%lu", valueMask) forKey:@"valueMask"];
    [results setValue:nsfmt(@"0x%x", valueMask) forKey:@"valueMaskHex"];

    int numberOfBits = 0;
    for (int i=0; i<15; i++) {
        if (valueMask & (1<<i)) {
            numberOfBits++;
        }
    }

    if (requestLength != 3+numberOfBits) {
        return nil;
    }

    char *p = bytes+12;
    if (valueMask & 0x0001) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"backgroundPixmap"];
        [results setValue:@"0=None 1=ParentRelative" forKey:@"backgroundPixmapDescription"];
    }
    if (valueMask & 0x0002) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"backgroundPixel"];
    }
    if (valueMask & 0x0004) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"borderPixmap"];
        [results setValue:@"0=CopyFromParent" forKey:@"borderPixmapDescription"];
    }
    if (valueMask & 0x0008) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"borderPixel"];
    }
    if (valueMask & 0x0010) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"bitGravity"];
    }
    if (valueMask & 0x0020) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"winGravity"];
    }
    if (valueMask & 0x0040) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"backingStore"];
        [results setValue:@"0=NotUseful 1=WhenMapped 2=Always" forKey:@"backingStoreDescription"];
    }
    if (valueMask & 0x0080) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"backingPlanes"];
    }
    if (valueMask & 0x0100) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"backingPixel"];
    }
    if (valueMask & 0x0200) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"overrideRedirect"];
    }
    if (valueMask & 0x0400) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"saveUnder"];
    }
    if (valueMask & 0x0800) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"eventMask"];
    }
    if (valueMask & 0x1000) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"doNotPropagateMask"];
    }
    if (valueMask & 0x2000) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"colormap"];
        [results setValue:@"0=CopyFromParent" forKey:@"colormapDescription"];
    }
    if (valueMask & 0x4000) {
        uint32_t val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"cursor"];
    }

    return results;
}
- (id)parseChangePropertyRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    int mode = bytes[1];

    if (requestLength < 6) {
        return nil;
    }

    id results = nsdict();
    [results setValue:nsfmt(@"%d", mode) forKey:@"mode"];
    [results setValue:@"0=replace 1=prepend 2=append" forKey:@"modeDescription"];

    uint32_t window = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", window) forKey:@"window"];
    [results setValue:nsfmt(@"0x%x", window) forKey:@"windowHex"];

    uint32_t property = read_uint32(bytes+8);
    [results setValue:nsfmt(@"%lu", property) forKey:@"property"];
    [results setValue:nsfmt(@"0x%x", property) forKey:@"propertyHex"];
    [results setValue:[self nameForAtom:property] forKey:@"propertyAtom"];

    uint32_t type = read_uint32(bytes+12);
    [results setValue:nsfmt(@"%lu", type) forKey:@"type"];
    [results setValue:nsfmt(@"0x%x", type) forKey:@"typeHex"];
    [results setValue:[self nameForAtom:type] forKey:@"typeAtom"];

    int format = bytes[16];
    [results setValue:nsfmt(@"%d", format) forKey:@"format"];

    int lengthOfDataInFormatUnits = read_uint32(bytes+20);
    [results setValue:nsfmt(@"%d", lengthOfDataInFormatUnits) forKey:@"lengthOfDataInFormatUnits"];

    if (lengthOfDataInFormatUnits > 0) {
        if (format == 8) {
            if (requestLength == 6+((lengthOfDataInFormatUnits+3)/4)) {
                id data = [NSData dataWithBytes:bytes+24 length:lengthOfDataInFormatUnits];
                [results setValue:data forKey:@"data"];
                [results setValue:[data asString] forKey:@"dataString"];
            }
        } else if (format == 16) {
            if (requestLength == 6+((lengthOfDataInFormatUnits*2+3)/4)) {
                id data = [NSData dataWithBytes:bytes+24 length:lengthOfDataInFormatUnits*2];
                [results setValue:data forKey:@"data"];
                id arr = nsarr();
                for (int i=0; i<lengthOfDataInFormatUnits; i++) {
                    uint16_t val = read_uint16(bytes+24+i*2);
                    [arr addObject:nsfmt(@"%d", val)];
                }
                [results setValue:arr forKey:@"dataArray"];
            }
        } else if (format == 32) {
            if (requestLength == 6+lengthOfDataInFormatUnits) {
                id data = [NSData dataWithBytes:bytes+24 length:lengthOfDataInFormatUnits*4];
                [results setValue:data forKey:@"data"];
                id arr = nsarr();
                for (int i=0; i<lengthOfDataInFormatUnits; i++) {
                    uint32_t val = read_uint32(bytes+24+i*4);
                    [arr addObject:nsfmt(@"%lu", val)];
                }
                [results setValue:arr forKey:@"dataArray"];
            }
        }
    }

    return results;
}
- (id)parseCloseFontRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength != 2) {
        return nil;
    }

    id results = nsdict();

    uint32_t font = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", font) forKey:@"font"];
    [results setValue:nsfmt(@"0x%x", font) forKey:@"fontHex"];

    return results;
}

- (id)parseConfigureWindowRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength < 3) {
        return nil;
    }

    id results = nsdict();

    uint32_t window = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", window) forKey:@"window"];
    [results setValue:nsfmt(@"0x%x", window) forKey:@"windowHex"];

    uint32_t valueMask = read_uint32(bytes+8);
    [results setValue:nsfmt(@"%lu", valueMask) forKey:@"valueMask"];
    [results setValue:nsfmt(@"0x%x", valueMask) forKey:@"valueMaskHex"];

    int numberOfBits = 0;
    for (int i=0; i<7; i++) {
        if (valueMask & (1<<i)) {
            numberOfBits++;
        }
    }

    if (requestLength != 3+numberOfBits) {
        return nil;
    }

    char *p = bytes+12;
    if (valueMask & 0x0001) {
        int val = read_uint16(p);
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"x"];
    }
    if (valueMask & 0x0002) {
        int val = read_uint16(p);
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"y"];
    }
    if (valueMask & 0x0004) {
        int val = read_uint16(p);
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"width"];
    }
    if (valueMask & 0x0008) {
        int val = read_uint16(p);
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"height"];
    }
    if (valueMask & 0x0010) {
        int val = read_uint16(p);
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"borderWidth"];
    }
    if (valueMask & 0x0020) {
        int val = read_uint32(p);
        p+=4;
        [results setValue:nsfmt(@"%lu", val) forKey:@"sibling"];
    }
    if (valueMask & 0x0020) {
        int val = *p;
        p+=4;
        [results setValue:nsfmt(@"%d", val) forKey:@"stackMode"];
        [results setValue:@"0=Above 1=Below 2=TopIf 3=BottomIf 4=Opposite" forKey:@"stackModeDescription"];
    }

    return results;
}

- (id)parseRecolorCursorRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength != 5) {
        return nil;
    }

    id results = nsdict();

    uint32_t cursor = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", cursor) forKey:@"cursor"];
    [results setValue:nsfmt(@"0x%x", cursor) forKey:@"cursorHex"];

    int foreRed = read_uint16(bytes+8);
    [results setValue:nsfmt(@"%d", foreRed) forKey:@"foreRed"];
    [results setValue:nsfmt(@"0x%x", foreRed) forKey:@"foreRedHex"];

    int foreGreen = read_uint16(bytes+10);
    [results setValue:nsfmt(@"%d", foreGreen) forKey:@"foreGreen"];
    [results setValue:nsfmt(@"0x%x", foreGreen) forKey:@"foreGreenHex"];

    int foreBlue = read_uint16(bytes+12);
    [results setValue:nsfmt(@"%d", foreBlue) forKey:@"foreBlue"];
    [results setValue:nsfmt(@"0x%x", foreBlue) forKey:@"foreBlueHex"];

    int backRed = read_uint16(bytes+14);
    [results setValue:nsfmt(@"%d", backRed) forKey:@"backRed"];
    [results setValue:nsfmt(@"0x%x", backRed) forKey:@"backRedHex"];

    int backGreen = read_uint16(bytes+16);
    [results setValue:nsfmt(@"%d", backGreen) forKey:@"backGreen"];
    [results setValue:nsfmt(@"0x%x", backGreen) forKey:@"backGreenHex"];

    int backBlue = read_uint16(bytes+18);
    [results setValue:nsfmt(@"%d", backBlue) forKey:@"backBlue"];
    [results setValue:nsfmt(@"0x%x", backBlue) forKey:@"backBlueHex"];

    return results;
}
- (id)parseGetWindowAttributesRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength != 2) {
        return nil;
    }

    id results = nsdict();

    uint32_t window = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", window) forKey:@"window"];
    [results setValue:nsfmt(@"0x%x", window) forKey:@"windowHex"];

    return results;
}
- (id)parseGetGeometryRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength != 2) {
        return nil;
    }

    id results = nsdict();

    uint32_t drawable = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", drawable) forKey:@"drawable"];
    [results setValue:nsfmt(@"0x%x", drawable) forKey:@"drawableHex"];

    return results;
}
- (id)parseGetKeyboardMappingRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength != 2) {
        return nil;
    }

    id results = nsdict();

    int firstKeycode = bytes[4];
    [results setValue:nsfmt(@"%d", firstKeycode) forKey:@"firstKeycode"];
    [results setValue:nsfmt(@"0x%x", firstKeycode) forKey:@"firstKeycodeHex"];
    int count = bytes[5];
    [results setValue:nsfmt(@"%d", count) forKey:@"count"];
    [results setValue:nsfmt(@"0x%x", count) forKey:@"countHex"];

    return results;
}
- (id)parseGrabButtonRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    int ownerEvents = bytes[1];

    if (requestLength != 6) {
        return nil;
    }

    id results = nsdict();

    [results setValue:nsfmt(@"%d", ownerEvents) forKey:@"ownerEvents"];

    uint32_t grabWindow = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", grabWindow) forKey:@"grabWindow"];
    [results setValue:nsfmt(@"0x%x", grabWindow) forKey:@"grabWindowHex"];

    int eventMask = read_uint16(bytes+8);
    [results setValue:nsfmt(@"%d", eventMask) forKey:@"eventMask"];
    [results setValue:nsfmt(@"0x%x", eventMask) forKey:@"eventMaskHex"];

    int pointerMode = bytes[10];
    [results setValue:nsfmt(@"%d", pointerMode) forKey:@"pointerMode"];
    [results setValue:@"0=Synchronous 1=Asynchronous" forKey:@"pointerModeDescription"];

    int keyboardMode = bytes[11];
    [results setValue:nsfmt(@"%d", keyboardMode) forKey:@"keyboardMode"];
    [results setValue:@"0=Synchronous 1=Asynchronous" forKey:@"keyboardModeDescription"];

    uint32_t confineTo = read_uint32(bytes+12);
    [results setValue:nsfmt(@"%lu", confineTo) forKey:@"confineTo"];
    [results setValue:nsfmt(@"0x%x", confineTo) forKey:@"confineToHex"];

    uint32_t cursor = read_uint32(bytes+16);
    [results setValue:nsfmt(@"%lu", cursor) forKey:@"cursor"];
    [results setValue:nsfmt(@"0x%x", cursor) forKey:@"cursorHex"];

    int button = bytes[20];
    [results setValue:nsfmt(@"%d", button) forKey:@"button"];

    uint16_t modifiers = read_uint16(bytes+22);
    [results setValue:nsfmt(@"%d", modifiers) forKey:@"modifiers"];
    [results setValue:nsfmt(@"0x%x", modifiers) forKey:@"modifiersHex"];

    return results;
}
- (id)parseAllocColorRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength != 4) {
        return nil;
    }

    id results = nsdict();

    uint32_t cmap = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", cmap) forKey:@"cmap"];
    [results setValue:nsfmt(@"0x%x", cmap) forKey:@"cmapHex"];

    uint16_t red = read_uint16(bytes+8);
    [results setValue:nsfmt(@"%d", red) forKey:@"red"];
    [results setValue:nsfmt(@"0x%x", red) forKey:@"redHex"];

    uint16_t green = read_uint16(bytes+10);
    [results setValue:nsfmt(@"%d", green) forKey:@"green"];
    [results setValue:nsfmt(@"0x%x", green) forKey:@"greenHex"];

    uint16_t blue = read_uint16(bytes+12);
    [results setValue:nsfmt(@"%d", blue) forKey:@"blue"];
    [results setValue:nsfmt(@"0x%x", blue) forKey:@"blueHex"];

    return results;
}
- (id)parseMapSubwindowsRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength != 2) {
        return nil;
    }

    id results = nsdict();

    uint32_t window = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", window) forKey:@"window"];
    [results setValue:nsfmt(@"0x%x", window) forKey:@"windowHex"];

    return results;
}
- (id)parseMapWindowRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength != 2) {
        return nil;
    }

    id results = nsdict();

    uint32_t window = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", window) forKey:@"window"];
    [results setValue:nsfmt(@"0x%x", window) forKey:@"windowHex"];

    return results;
}
- (id)parseImageText8Request:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    int lengthOfString = bytes[1];

    if (requestLength != 4+((lengthOfString+3)/4)) {
        return nil;
    }

    id results = nsdict();
    [results setValue:nsfmt(@"%d", lengthOfString) forKey:@"lengthOfString"];

    uint32_t drawable = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", drawable) forKey:@"drawable"];
    [results setValue:nsfmt(@"0x%x", drawable) forKey:@"drawableHex"];

    uint32_t gc = read_uint32(bytes+8);
    [results setValue:nsfmt(@"%lu", gc) forKey:@"gc"];
    [results setValue:nsfmt(@"0x%x", gc) forKey:@"gcHex"];

    int x = read_uint16(bytes+12);
    [results setValue:nsfmt(@"%d", x) forKey:@"x"];

    int y = read_uint16(bytes+14);
    [results setValue:nsfmt(@"%d", y) forKey:@"y"];

    if (lengthOfString) {
        id string = nsfmt(@"%.*s", lengthOfString, bytes+16);
        [results setValue:string forKey:@"string"];
    }

    return results;
}
- (id)parsePolyLineRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    int coordinateMode = bytes[1];

    if (requestLength < 3) {
        return nil;
    }

    id results = nsdict();
    [results setValue:nsfmt(@"%d", coordinateMode) forKey:@"coordinateMode"];
    [results setValue:@"0=Origin 1=Previous" forKey:@"coordinateModeDescription"];

    uint32_t drawable = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", drawable) forKey:@"drawable"];
    [results setValue:nsfmt(@"0x%x", drawable) forKey:@"drawableHex"];

    uint32_t gc = read_uint32(bytes+8);
    [results setValue:nsfmt(@"%lu", gc) forKey:@"gc"];
    [results setValue:nsfmt(@"0x%x", gc) forKey:@"gcHex"];

    id points = nsarr();
    for (int i=3; i<requestLength; i++) {
        int x = read_uint16(bytes+i*4);
        int y = read_uint16(bytes+i*4+2);
        [points addObject:nsfmt(@"x:%d y:%d", x, y)];
    }
    [results setValue:points forKey:@"points"];

    return results;
}
- (id)parseCopyAreaRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength != 7) {
        return nil;
    }

    id results = nsdict();

    uint32_t srcDrawable = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", srcDrawable) forKey:@"srcDrawable"];
    [results setValue:nsfmt(@"0x%x", srcDrawable) forKey:@"srcDrawableHex"];

    uint32_t dstDrawable = read_uint32(bytes+8);
    [results setValue:nsfmt(@"%lu", dstDrawable) forKey:@"dstDrawable"];
    [results setValue:nsfmt(@"0x%x", dstDrawable) forKey:@"dstDrawableHex"];

    uint32_t gc = read_uint32(bytes+12);
    [results setValue:nsfmt(@"%lu", gc) forKey:@"gc"];
    [results setValue:nsfmt(@"0x%x", gc) forKey:@"gcHex"];

    int srcX = read_uint16(bytes+16);
    [results setValue:nsfmt(@"%d", srcX) forKey:@"srcX"];

    int srcY = read_uint16(bytes+18);
    [results setValue:nsfmt(@"%d", srcY) forKey:@"srcY"];

    int dstX = read_uint16(bytes+20);
    [results setValue:nsfmt(@"%d", dstX) forKey:@"dstX"];

    int dstY = read_uint16(bytes+22);
    [results setValue:nsfmt(@"%d", dstY) forKey:@"dstY"];

    int width = read_uint16(bytes+24);
    [results setValue:nsfmt(@"%d", width) forKey:@"width"];

    int height = read_uint16(bytes+26);
    [results setValue:nsfmt(@"%d", height) forKey:@"height"];

    return results;
}
- (id)parseClearAreaRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    if (requestLength != 4) {
        return nil;
    }

    id results = nsdict();

    uint32_t window = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", window) forKey:@"window"];
    [results setValue:nsfmt(@"0x%x", window) forKey:@"windowHex"];

    int x = read_uint16(bytes+8);
    [results setValue:nsfmt(@"%d", x) forKey:@"x"];

    int y = read_uint16(bytes+10);
    [results setValue:nsfmt(@"%d", y) forKey:@"y"];

    int width = read_uint16(bytes+12);
    [results setValue:nsfmt(@"%d", width) forKey:@"width"];

    int height = read_uint16(bytes+14);
    [results setValue:nsfmt(@"%d", height) forKey:@"height"];

    return results;
}
- (id)parseSetCloseDownModeRequest:(int)requestLength
{
    unsigned char *bytes = [_data bytes];

    int mode = bytes[1];

    id results = nsdict();
    [results setValue:nsfmt(@"%d", mode) forKey:@"mode"];
    [results setValue:@"0=Destroy 1=RetainPermanent 2=RetainTemporary" forKey:@"modeDescription"];

    return results;
}
- (id)parseSendEventRequest:(int)requestLength
{
    if (requestLength != 11) {
        return nil;
    }

    unsigned char *bytes = [_data bytes];

    int propagate = bytes[1];

    id results = nsdict();
    [results setValue:nsfmt(@"%d", propagate) forKey:@"propagate"];

    uint32_t destination = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", destination) forKey:@"destination"];
    [results setValue:@"0=PointerWindow 1=InputFocus" forKey:@"destinationDescription"];

    uint32_t eventMask = read_uint32(bytes+8);
    [results setValue:nsfmt(@"%lu", eventMask) forKey:@"eventMask"];

    id event = [NSData dataWithBytes:bytes+12 length:32];
    [results setValue:event forKey:@"event"];

    return results;
}
- (id)parseGetSelectionOwnerRequest:(int)requestLength
{
    if (requestLength != 2) {
        return nil;
    }

    unsigned char *bytes = [_data bytes];

    id results = nsdict();
    uint32_t selection = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", selection) forKey:@"selection"];

    return results;
}
- (id)parseQueryPointerRequest:(int)requestLength
{
    if (requestLength != 2) {
        return nil;
    }

    unsigned char *bytes = [_data bytes];

    id results = nsdict();
    uint32_t window = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", window) forKey:@"window"];

    return results;
}
- (id)parseMITSHMQueryVersionRequest:(int)requestLength
{
    if (requestLength != 1) {
        return nil;
    }

    id results = nsdict();

    return results;
}
- (id)parseMITSHMAttachRequest:(int)requestLength
{
    if (requestLength != 4) {
        return nil;
    }

    unsigned char *bytes = [_data bytes];

    id results = nsdict();
    uint32_t shmseg = read_uint32(bytes+4);
    id shmsegkey = nsfmt(@"%lu", shmseg);
    [results setValue:shmsegkey forKey:@"shmseg"];
    uint32_t shmid = read_uint32(bytes+8);
    id shmidval = nsfmt(@"%lu", shmid);
    [results setValue:shmidval forKey:@"shmid"];
    int read_only = bytes[12];
    [results setValue:nsfmt(@"%d", read_only) forKey:@"read_only"];

    id xserver = [@"XServer" valueForKey];
    id shmSegments = [xserver valueForKey:@"shmSegments"];
    [shmSegments setValue:shmidval forKey:shmsegkey];
    return results;
}
- (id)parseMITSHMDetachRequest:(int)requestLength
{
    if (requestLength != 2) {
        return nil;
    }

    unsigned char *bytes = [_data bytes];

    id results = nsdict();
    uint32_t shmseg = read_uint32(bytes+4);
    id shmsegkey = nsfmt(@"%lu", shmseg);
    [results setValue:shmsegkey forKey:@"shmseg"];

    id xserver = [@"XServer" valueForKey];
    id shmSegments = [xserver valueForKey:@"shmSegments"];
    [shmSegments setValue:nil forKey:shmsegkey];

    return results;
}
- (id)parseMITSHMPutImageRequest:(int)requestLength
{
    if (requestLength != 10) {
        return nil;
    }

    unsigned char *bytes = [_data bytes];

    id results = nsdict();
    uint32_t drawable = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", drawable) forKey:@"drawable"];
    uint32_t gc = read_uint32(bytes+8);
    [results setValue:nsfmt(@"%lu", gc) forKey:@"gc"];
    uint16_t total_width = read_uint16(bytes+12);
    [results setValue:nsfmt(@"%u", total_width) forKey:@"total_width"];
    uint16_t total_height = read_uint16(bytes+14);
    [results setValue:nsfmt(@"%u", total_height) forKey:@"total_height"];
    uint16_t src_x = read_uint16(bytes+16);
    [results setValue:nsfmt(@"%u", src_x) forKey:@"src_x"];
    uint16_t src_y = read_uint16(bytes+18);
    [results setValue:nsfmt(@"%u", src_y) forKey:@"src_y"];
    uint16_t src_width = read_uint16(bytes+20);
    [results setValue:nsfmt(@"%u", src_width) forKey:@"src_width"];
    uint16_t src_height = read_uint16(bytes+22);
    [results setValue:nsfmt(@"%u", src_height) forKey:@"src_height"];
    uint16_t dst_x = read_uint16(bytes+24);
    [results setValue:nsfmt(@"%u", dst_x) forKey:@"dst_x"];
    uint16_t dst_y= read_uint16(bytes+26);
    [results setValue:nsfmt(@"%u", dst_y) forKey:@"dst_y"];
    int depth = bytes[28];
    [results setValue:nsfmt(@"%d", depth) forKey:@"depth"];
    int format = bytes[29];
    [results setValue:nsfmt(@"%d", format) forKey:@"format"];
    int send_event = bytes[30];
    [results setValue:nsfmt(@"%d", send_event) forKey:@"send_event"];
    uint32_t shmseg = read_uint32(bytes+32);
    id shmsegkey = nsfmt(@"%lu", shmseg);
    [results setValue:shmsegkey forKey:@"shmseg"];
    uint32_t offset = read_uint32(bytes+36);
    [results setValue:nsfmt(@"%lu", offset) forKey:@"offset"];

    if ((depth == 24) || (depth == 32)) {
        id xserver = [@"XServer" valueForKey];
        id shmSegments = [xserver valueForKey:@"shmSegments"];
        uint32_t shmid = [shmSegments unsignedLongValueForKey:shmsegkey];
NSLog(@"shmid %lu", shmid);
        void *addr = shmat(shmid, 0, SHM_RDONLY);
NSLog(@"addr %x", addr);
        if (addr != -1) {
            id bitmap = [Definitions bitmapWithWidth:total_width height:total_height];
            unsigned char *pixelBytes = [bitmap pixelBytes];
            memcpy(pixelBytes, addr, total_width*total_height*4);
            [results setValue:bitmap forKey:@"bitmap"];
            int result = shmdt(addr);
NSLog(@"shmdt %d", result);
        }
    }

    return results;
}

- (id)parsePresentQueryVersionRequest:(int)requestLength
{
    if (requestLength != 3) {
        return nil;
    }

    unsigned char *bytes = [_data bytes];

    id results = nsdict();
    uint32_t clientMajorVersion = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", clientMajorVersion) forKey:@"clientMajorVersion"];
    uint32_t clientMinorVersion = read_uint32(bytes+8);
    [results setValue:nsfmt(@"%lu", clientMinorVersion) forKey:@"clientMinorVersion"];

    return results;
}
- (id)parseXFixesQueryVersionRequest:(int)requestLength
{
    if (requestLength != 3) {
        return nil;
    }

    unsigned char *bytes = [_data bytes];

    id results = nsdict();
    uint32_t clientMajorVersion = read_uint32(bytes+4);
    [results setValue:nsfmt(@"%lu", clientMajorVersion) forKey:@"clientMajorVersion"];
    uint32_t clientMinorVersion = read_uint32(bytes+8);
    [results setValue:nsfmt(@"%lu", clientMinorVersion) forKey:@"clientMinorVersion"];

    return results;
}

- (void)sendResponse
{
    if (_connfd < 0) {
        return;
    }

    if (!_sequenceNumber) {
        int len = [_data length];
        if (len < 12) {
            return;
        }
        [self sendConnectionSetupResponse];
        [self consumeRequest];
        return;
    }

    int len = [_data length];
    if (len < 4) {
        return;
    }
    unsigned char *bytes = [_data bytes];

    int opcode = bytes[0];
    int requestLength = read_uint16(bytes+2);
    if (len < requestLength*4) {
        return;
    }

    if (opcode == 98) { //QueryExtension
        [self sendQueryExtensionResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 55) { //CreateGC
        [self consumeRequest];
        return;
    } else if (opcode == 16) { //InternAtom
        [self sendInternAtomResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 15) { //QueryTree
        [self sendQueryTreeResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 3) { //GetWindowAttributes
        [self sendGetWindowAttributesResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 14) { //GetGeometry
        [self sendGetGeometryResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 2) { //ChangeWindowAttributes
        [self consumeRequest];
        return;
    } else if (opcode == 91) { //QueryColors
        [self sendQueryColorsResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 84) { //AllocColor
        [self sendAllocColorResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 53) { //CreatePixmap
        [self consumeRequest];
        return;
    } else if (opcode == 72) { //PutImage
        [self processPutImageRequest:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 60) { //FreeGC
        [self consumeRequest];
        return;
    } else if (opcode == 54) { //FreePixmap
        [self consumeRequest];
        return;
    } else if (opcode == 43) { //GetInputFocus
        [self sendGetInputFocusResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 92) { //LookupColor
        [self sendLookupColorResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 20) { //GetProperty
        [self sendGetPropertyResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 112) { //SetCloseDownMode
        [self consumeRequest];
        return;
    } else if (opcode == 78) { //CreateColormap
        [self consumeRequest];
        return;
    } else if (opcode == 1) { //CreateWindow
        [self processCreateWindowRequest:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 18) { //ChangeProperty
        [self processChangePropertyRequest:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 45) { //OpenFont
        [self consumeRequest];
        return;
    } else if (opcode == 47) { //QueryFont
        [self sendQueryFontResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 94) { //CreateGlyphCursor
        [self consumeRequest];
        return;
    } else if (opcode == 46) { //CloseFont
        [self consumeRequest];
        return;
    } else if (opcode == 12) { //ConfigureWindow
        [self processConfigureWindowRequest:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 96) { //RecolorCursor
        [self consumeRequest];
        return;
    } else if (opcode == 8) { //MapWindow
        [self processMapWindowRequest:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 119) { //GetModifierMapping
        [self sendGetModifierMappingResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 101) { //GetKeyboardMapping
        [self sendGetKeyboardMappingResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 28) { //GrabButton
        [self consumeRequest];
        return;
    } else if (opcode == 9) { //MapSubwindows
        [self consumeRequest];
        return;
    } else if (opcode == 76) { //ImageText8
        [self processImageText8Request:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 65) { //PolyLine
        [self consumeRequest];
        return;
    } else if (opcode == 62) { //CopyArea
        [self processCopyAreaRequest:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 61) { //ClearArea
        [self processClearAreaRequest:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 117) { //GetPointerMapping
        [self sendGetPointerMappingResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 25) { //SendEvent
        [self processSendEventRequest:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 23) { //GetSelectionOwner
        [self sendGetSelectionOwnerResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 38) { //QueryPointer
        [self sendQueryPointerResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 40) { //TranslateCoordinates
        [self sendTranslateCoordinatesResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 115) { //ForceScreenSaver
        [self consumeRequest];
        return;
    } else if (opcode == 10) { //UnmapWindow
        [self consumeRequest];
        return;
    } else if (opcode == 4) { //DestroyWindow
        [self consumeRequest];
        return;
    } else if (opcode == 79) { //FreeColormap
        [self consumeRequest];
        return;
    } else if (opcode == 44) { //QueryKeymap
        [self sendQueryKeymapResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 103) { //GetKeyboardControl
        [self sendGetKeyboardControlResponse:requestLength];
        [self consumeRequest];
        return;
    } else if (opcode == 129) {
        int minoropcode = bytes[1];
        if (minoropcode == 0) {
            [self sendPresentQueryVersionResponse:requestLength];
            [self consumeRequest];
        }
    } else if (opcode == 130) {
        int minoropcode = bytes[1];
        if (minoropcode == 0) {
            [self sendXFixesQueryVersionResponse:requestLength];
            [self consumeRequest];
        }
    } else if (opcode == 135) {
        int minoropcode = bytes[1];
        if (minoropcode == 0) {
            [self sendMITSHMQueryVersionResponse:requestLength];
            [self consumeRequest];
        } else if (minoropcode == 1) {
            [self consumeRequest];
        } else if (minoropcode == 2) {
            [self consumeRequest];
        } else if (minoropcode == 3) {
            [self sendMITSHMPutImageResponse:requestLength];
            [self consumeRequest];

        }
    }

    _auto = 0;
}
- (void)sendConnectionSetupResponse
{
    unsigned char buf[256];
    unsigned char *p = buf;

    //1     1                               Success
    p[0] = 1;
    p++;

    //1                                     unused
    p[0] = 0;
    p++;

    //2     CARD16                          protocol-major-version
    p[0] = 11;
    p[1] = 0;
    p+=2;

    //2     CARD16                          protocol-minor-version
    p[0] = 0;
    p[1] = 0;
    p+=2;

    //2     8+2n+(v+p+m)/4                  length in 4-byte units of
    //                                       "additional data"
    p[0] = 8;
    p[1] = 0;
    p+=2;

    //4     CARD32                          release-number
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //4     CARD32                          resource-id-base
    p[0] = 0xff;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //4     CARD32                          resource-id-mask
    p[0] = 0;
    p[1] = 0xff;
    p[2] = 0xff;
    p[3] = 0x0f;
    p+=4;

    //4     CARD32                          motion-buffer-size
    p[0] = 0xff;//motion-buffer-size
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //2     v                               length of vendor
    p[0] = 0;
    p[1] = 0;
    p+=2;

    //2     CARD16                          maximum-request-length
    p[0] = 0xff;
    p[1] = 0xff;
    p+=2;

    //1     CARD8                           number of SCREENs in roots
    p[0] = 1;
    p++;

    //1     n                               number for FORMATs in
    //                                       pixmap-formats
    p[0] = 1;
    p++;

    //1                                     image-byte-order
    //      0     LSBFirst
    //      1     MSBFirst
    p[0] = 0;
    p++;

    //1                                     bitmap-format-bit-order
    //      0     LeastSignificant
    //      1     MostSignificant
    p[0] = 0;
    p++;

    //1     CARD8                           bitmap-format-scanline-unit
    p[0] = 32;
    p++;

    //1     CARD8                           bitmap-format-scanline-pad
    p[0] = 32;
    p++;

    //1     KEYCODE                         min-keycode
    p[0] = 0x08;
    p++;

    //1     KEYCODE                         max-keycode
    p[0] = 0xff;
    p++;

    //4                                     unused
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //v     STRING8                         vendor
    //p                                     unused, p=pad(v)

    //8n     LISTofFORMAT                   pixmap-formats
    //1     CARD8                           depth
    p[0] = 32;
    p++;

    //1     CARD8                           bits-per-pixel
    p[0] = 32;
    p++;

    //1     CARD8                           scanline-pad
    p[0] = 32;
    p++;

    //5                                     unused
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p[4] = 0;
    p+=5;

    id xserver = [@"XServer" valueForKey];
    //m     LISTofSCREEN                    roots (m is always a multiple of 4)
    //4     WINDOW                          root
    write_uint32(p, [xserver unsignedLongValueForKey:@"rootWindow"]);
    p+=4;

    //4     COLORMAP                        default-colormap
    write_uint32(p, [xserver unsignedLongValueForKey:@"colormap"]);
    p+=4;

    //4     CARD32                          white-pixel
    p[0] = 0xff;
    p[1] = 0xff;
    p[2] = 0xff;
    p[3] = 0;
    p+=4;

    //4     CARD32                          black-pixel
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //4     SETofEVENT                      current-input-masks
    p[0] = 0x4f;
    p[1] = 0x00;
    p[2] = 0x7a;
    p[3] = 0x00;
    p+=4;

    //2     CARD16                          width-in-pixels
    write_uint16(p, 1024);
    p+=2;

    //2     CARD16                          height-in-pixels
    write_uint16(p, 768);
    p+=2;

    //2     CARD16                          width-in-millimeters
    write_uint16(p, 1024);
    p+=2;

    //2     CARD16                          height-in-millimeters
    write_uint16(p, 768);
    p+=2;

    //2     CARD16                          min-installed-maps
    p[0] = 1;
    p[1] = 0;
    p+=2;

    //2     CARD16                          max-installed-maps
    p[0] = 1;
    p[1] = 0;
    p+=2;

    //4     VISUALID                        root-visual
    write_uint32(p, [xserver unsignedLongValueForKey:@"visualTrueColor24"]);
    p+=4;

    //1                                     backing-stores
    //      0     Never
    //      1     WhenMapped
    //      2     Always
    p[0] = 2;
    p++;

    //1     BOOL                            save-unders
    p[0] = 0;
    p++;

    //1     CARD8                           root-depth
    p[0] = 24;
    p++;

    //1     CARD8                           number of DEPTHs in allowed-depths
    p[0] = 3;
    p++;

    //n     LISTofDEPTH                     allowed-depths (n is always a
    //                                       multiple of 4)
    //1     CARD8                           depth
    p[0] = 1;
    p++;
    //1                                     unused
    p[0] = 0;
    p++;
    //2     n                               number of VISUALTYPES in visuals
    p[0] = 1;
    p[1] = 0;
    p+=2;
    //4                                     unused
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //24n     LISTofVISUALTYPE              visuals
    //4     VISUALID                        visual-id
    write_uint32(p, [xserver unsignedLongValueForKey:@"visualStaticGray"]);
    p+=4;
    //1                                     class
    //      0     StaticGray
    //      1     GrayScale
    //      2     StaticColor
    //      3     PseudoColor
    //      4     TrueColor
    //      5     DirectColor
    p[0] = 0;
    p++;
    //1     CARD8                           bits-per-rgb-value
    p[0] = 1;
    p++;
    //2     CARD16                          colormap-entries
    p[0] = 2;
    p[1] = 0;
    p+=2;
    //4     CARD32                          red-mask
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;
    //4     CARD32                          green-mask
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;
    //4     CARD32                          blue-mask
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;
    //4                                     unused
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

///

    //1     CARD8                           depth
    p[0] = 24;
    p++;
    //1                                     unused
    p[0] = 0;
    p++;
    //2     n                               number of VISUALTYPES in visuals
    p[0] = 1;
    p[1] = 0;
    p+=2;
    //4                                     unused
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //24n     LISTofVISUALTYPE              visuals
    //4     VISUALID                        visual-id
    write_uint32(p, [xserver unsignedLongValueForKey:@"visualTrueColor24"]);
    p+=4;
    //1                                     class
    //      0     StaticGray
    //      1     GrayScale
    //      2     StaticColor
    //      3     PseudoColor
    //      4     TrueColor
    //      5     DirectColor
    p[0] = 4;
    p++;
    //1     CARD8                           bits-per-rgb-value
    p[0] = 8;
    p++;
    //2     CARD16                          colormap-entries
    p[0] = 0;
    p[1] = 1;
    p+=2;
    //4     CARD32                          red-mask
    p[0] = 0;
    p[1] = 0;
    p[2] = 0xff;
    p[3] = 0;
    p+=4;
    //4     CARD32                          green-mask
    p[0] = 0;
    p[1] = 0xff;
    p[2] = 0;
    p[3] = 0;
    p+=4;
    //4     CARD32                          blue-mask
    p[0] = 0xff;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;
    //4                                     unused
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;
///

    //1     CARD8                           depth
    p[0] = 32;
    p++;
    //1                                     unused
    p[0] = 0;
    p++;
    //2     n                               number of VISUALTYPES in visuals
    p[0] = 1;
    p[1] = 0;
    p+=2;
    //4                                     unused
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //24n     LISTofVISUALTYPE              visuals
    //4     VISUALID                        visual-id
    write_uint32(p, [xserver unsignedLongValueForKey:@"visualTrueColor32"]);
    p+=4;
    //1                                     class
    //      0     StaticGray
    //      1     GrayScale
    //      2     StaticColor
    //      3     PseudoColor
    //      4     TrueColor
    //      5     DirectColor
    p[0] = 4;
    p++;
    //1     CARD8                           bits-per-rgb-value
    p[0] = 8;
    p++;
    //2     CARD16                          colormap-entries
    p[0] = 0;
    p[1] = 1;
    p+=2;
    //4     CARD32                          red-mask
    p[0] = 0;
    p[1] = 0;
    p[2] = 0xff;
    p[3] = 0;
    p+=4;
    //4     CARD32                          green-mask
    p[0] = 0;
    p[1] = 0xff;
    p[2] = 0;
    p[3] = 0;
    p+=4;
    //4     CARD32                          blue-mask
    p[0] = 0xff;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;
    //4                                     unused
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    buf[6] = (p-buf)/4-2;
NSLog(@"sending %d bytes p[6]=%d", p-buf, p[6]);
    send(_connfd, buf, p-buf, 0);

}
- (void)sendQueryExtensionResponse:(int)requestLength
{
    id request = [self parseQueryExtensionRequest:requestLength];
    if (!request) {
        return;
    }
    id name = [request valueForKey:@"name"];

    unsigned char buf[256];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1                                     unused
    p[0] = 0;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     0                               reply length
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //1     BOOL                            present
    if ([name isEqual:@"Present"]) {
        p[0] = 0;
    } else if ([name isEqual:@"XFIXES"]) {
        p[0] = 0;
    } else if ([name isEqual:@"MIT-SHM"]) {
        p[0] = 1;
    } else {
        p[0] = 0;
    }
    p++;

    //1     CARD8                           major-opcode
    if ([name isEqual:@"Present"]) {
        p[0] = 0;//129;
    } else if ([name isEqual:@"XFIXES"]) {
        p[0] = 0;//130;
    } else if ([name isEqual:@"MIT-SHM"]) {
        p[0] = 135;
    } else {
        p[0] = 0;
    }
    p++;

    //1     CARD8                           first-event
    if ([name isEqual:@"MIT-SHM"]) {
        p[0] = 65;
    } else {
        p[0] = 0;
    }
    p++;

    //1     CARD8                           first-error
    p[0] = 0;
    p++;

    //20                                    unused
    memset(p, 0, 20);
    p+=20;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendGetPropertyResponse:(int)requestLength
{
    id request = [self parseGetPropertyRequest:requestLength];
    int requestDelete = [request intValueForKey:@"delete"];
    id requestWindow = [request valueForKey:@"window"];
    id requestProperty = [request valueForKey:@"property"];
    id requestType = [request valueForKey:@"type"];
    int requestLongOffset = [request intValueForKey:@"longOffset"];
    int requestLongLength = [request intValueForKey:@"longLength"];

    if ([requestProperty isEqual:@"23"]) {
        id data = [[Definitions homeDir:@"xclientdata.out~RESOURCE_MANAGER"] dataFromFile];
        if (data) {
            unsigned char *bytes = [data bytes];
            int len = [data length];
            write_uint16(bytes+2, _sequenceNumber);
            send(_connfd, bytes, len, 0);
NSLog(@"Sending xclientdata.out~RESOURCE_MANAGER");
            return;
        }
    }

    id xserver = [@"XServer" valueForKey];
    id windows = [xserver valueForKey:@"windows"];
    id window = [windows valueForKey:requestWindow];
    id property = [[window valueForKey:@"properties"] valueForKey:requestProperty];

    int replyFormat = [property intValueForKey:@"format"];

    uint32_t replyType = [property unsignedLongValueForKey:@"type"];
    uint32_t replyBytesAfter = 0;
    id data = [property valueForKey:@"data"];
    int dataLength = [data length];

    if (property) {
        if (requestType) {
            if (requestType != replyType) {
                replyBytesAfter = dataLength;
                data = nil;
            }
        }
    }

    int replyLength = 0;
    int replyLengthOfValueInFormatUnits = 0;
    if (data && dataLength) {
        replyLength = (dataLength+3)/4;
        if (replyFormat == 8) {
            replyLengthOfValueInFormatUnits = dataLength;
        } else if (replyFormat == 16) {
            replyLengthOfValueInFormatUnits = dataLength/2;
        } else if (replyFormat == 32) {
            replyLengthOfValueInFormatUnits = dataLength/4;
        }
    }
    
    // FIXME handle delete

    unsigned char buf[256]; // FIXME should allocate correct size
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1     CARD8                           format
    p[0] = replyFormat;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     (n+p)/4                         reply length
    write_uint32(p, replyLength);
    p+=4;

    //4     ATOM                            type
    write_uint32(p, replyType);
    p+=4;

    //4     CARD32                          bytes-after
    write_uint32(p, replyBytesAfter);
    p+=4;

    //4     CARD32                          length of value in format units
    write_uint32(p, replyLengthOfValueInFormatUnits);
    p+=4;

    //12                                    unused
    memset(p, 0, 12);
    p+=12;

    //n     LISTofBYTE                      value
    //                (n is zero for format = 0)
    //                (n is a multiple of 2 for format = 16)
    //                (n is a multiple of 4 for format = 32)
    //p                                     unused, p=pad(n)
    if (data && dataLength) {
        memcpy(p, [data bytes], dataLength);
        p += replyLength*4;
    }

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendGetWindowAttributesResponse:(int)requestLength
{
    id request = [self parseGetWindowAttributesRequest:requestLength];
    id window = nil;
    if (request) {
        id xserver = [@"XServer" valueForKey];
        id windows = [xserver valueForKey:@"windows"];
        id windowKey = [request valueForKey:@"window"];
        window = [windows valueForKey:windowKey];
    }

    unsigned char buf[256];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1                                     backing-store
    p[0] = 1;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     3                               reply length
    write_uint32(p, 3);
    p+=4;

    //4     VISUALID                        visual
    id xserver = [@"XServer" valueForKey];
    write_uint32(p, [xserver unsignedLongValueForKey:@"visualTrueColor24"]);
    p+=4;

    //2                                     class
    //      1     InputOutput
    //      2     InputOnly
    write_uint16(p, 1);
    p+=2;

    //1     BITGRAVITY                      bit-gravity
    p[0] = [window intValueForKey:@"bitGravity"];
    p++;

    //1     WINGRAVITY                      win-gravity
    p[0] = [window intValueForKey:@"winGravity"];
    p++;

    //4     CARD32                          backing-planes
    write_uint32(p, [window unsignedLongValueForKey:@"backingPlanes"]);
    p+=4;

    //4     CARD32                          backing-pixel
    write_uint32(p, [window unsignedLongValueForKey:@"backingPixel"]);
    p+=4;

    //1     BOOL                            save-under
    p[0] = [window intValueForKey:@"saveUnder"];
    p++;

    //1     BOOL                            map-is-installed
    p[0] = 1; //FIXME
    p++;

    //1                                     map-state
    //      0     Unmapped
    //      1     Unviewable
    //      2     Viewable
    p[0] = [window intValueForKey:@"mapState"];;
    p++;

    //1     BOOL                            override-redirect
    p[0] = [window intValueForKey:@"overrideRedirect"];
    p++;

    //4     COLORMAP                        colormap
    //      0     None
    write_uint32(p, [window unsignedLongValueForKey:@"colormap"]);
    p+=4;

    //4     SETofEVENT                      all-event-masks
    write_uint32(p, [window unsignedLongValueForKey:@"eventMask"]);
    p+=4;

    //4     SETofEVENT                      your-event-mask
    write_uint32(p, [window unsignedLongValueForKey:@"eventMask"]);
    p+=4;

    //2     SETofDEVICEEVENT                do-not-propagate-mask
    write_uint16(p, [window intValueForKey:@"doNotPropagateMask"]);
    p+=2;

    //2                                    unused
    p[0] = 0;
    p[1] = 0;
    p+=2;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendGetGeometryResponse:(int)requestLength
{
    id request = [self parseGetGeometryRequest:requestLength];
    id drawableKey = [request valueForKey:@"drawable"];
    id xserver = [@"XServer" valueForKey];
    id windows = [xserver valueForKey:@"windows"];
    id window = [windows valueForKey:drawableKey];

    unsigned char buf[256];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1     CARD8                           depth
    p[0] = [window intValueForKey:@"depth"];
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     0                               reply length
    write_uint32(p, 0);
    p+=4;

    //4     WINDOW                          root
    write_uint32(p, [xserver unsignedLongValueForKey:@"rootWindow"]);
    p+=4;

    //2     INT16                           x
    write_uint16(p, [window intValueForKey:@"x"]);
    p+=2;

    //2     INT16                           y
    write_uint16(p, [window intValueForKey:@"y"]);
    p+=2;

    //2     CARD16                          width
    write_uint16(p, [window intValueForKey:@"width"]);
    p+=2;

    //2     CARD16                          height
    write_uint16(p, [window intValueForKey:@"height"]);
    p+=2;

    //2     CARD16                          border-width
    write_uint16(p, [window intValueForKey:@"borderWidth"]);
    p+=2;

    //10                                    unused
    memset(p, 0, 10);
    p+=10;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendInternAtomResponse:(int)requestLength
{
    id request = [self parseInternAtomRequest:requestLength];
    if (!request) {
        return;
    }

    int onlyIfExists = [request intValueForKey:@"onlyIfExists"];

    id name = [request valueForKey:@"name"];
    if (!name) {
        name = @"";
    }

    id xserver = [@"XServer" valueForKey];
    id internAtoms = [xserver valueForKey:@"internAtoms"];
    int internAtomCounter = [xserver intValueForKey:@"internAtomCounter"];
    [internAtoms setValue:name forKey:nsfmt(@"%d", internAtomCounter)];
    internAtomCounter++;
    [xserver setValue:nsfmt(@"%d", internAtomCounter) forKey:@"internAtomCounter"];

    unsigned char buf[256];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1                                     unused
    p[0] = 0;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     0                               reply length
    write_uint32(p, 0);
    p+=4;

    //4     ATOM                            atom
    write_uint32(p, [xserver unsignedLongValueForKey:@"internAtomCounter"]);
    p+=4;

    //20                                    unused
    memset(p, 0, 20);
    p+=20;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);

}
- (void)sendQueryTreeResponse:(int)requestLength
{
    unsigned char buf[256];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1                                     unused
    p[0] = 0;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     0                               reply length
    write_uint32(p, 0);
    p+=4;

    //4     WINDOW                          root
    id xserver = [@"XServer" valueForKey];
    write_uint32(p, [xserver unsignedLongValueForKey:@"rootWindow"]);
    p+=4;

    //4     WINDOW                          parent
    //      0     None
    write_uint32(p, 0);
    p+=4;

    //2     n                               number of WINDOWs in children
    write_uint16(p, 0);
    p+=2;

    //14                                    unused
    memset(p, 0, 14);
    p+=14;

    //4n     LISTofWINDOW                   children

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendQueryColorsResponse:(int)FIXMErequestLength
{
    unsigned char *bytes = [_data bytes];
    int len = [_data length];
    if (len < 4) {
NSLog(@"not enough data");
        return;
    }

    int requestLength = read_uint16(bytes+2);
    if (len < requestLength*4) {
NSLog(@"not enough data");
        return;
    }
    if (requestLength < 2) {
NSLog(@"not enough data");
        return;
    }
    int numberOfColors = requestLength - 2;

    unsigned char *buf = malloc(32+8*numberOfColors);
    if (!buf) {
NSLog(@"Out of memory");
exit(1);
        return;
    }
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1                                     unused
    p[0] = 0;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     2n                              reply length
    write_uint32(p, 2*numberOfColors);
    p+=4;

    //2     n                               number of RGBs in colors
    write_uint16(p, numberOfColors);
    p+=2;

    //22                                    unused
    memset(p, 0, 22);
    p+=22;

    //8n     LISTofRGB                      colors
    for (int i=0; i<numberOfColors; i++) {
        uint32_t pixel = read_uint32(bytes+8+4*i);
        unsigned char r = (unsigned char) ((pixel>>24)&0xff);
        unsigned char g = (unsigned char) ((pixel>>16)&0xff);
        unsigned char b = (unsigned char) ((pixel>>8)&0xff);

        //2     CARD16                          red
        p[0] = r;
        p[1] = r;
        p+=2;

        //2     CARD16                          green
        p[0] = g;
        p[1] = g;
        p+=2;

        //2     CARD16                          blue
        p[0] = b;
        p[1] = b;
        p+=2;

        //2                                     unused
        p[0] = 0;
        p[1] = 0;
        p+=2;
    }

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);

    free(buf);
}
- (void)sendAllocColorResponse:(int)requestLength
{
    id request = [self parseAllocColorRequest:requestLength];
    if (!request) {
        return;
    }

    int red = [request intValueForKey:@"red"];
    int green = [request intValueForKey:@"green"];
    int blue = [request intValueForKey:@"blue"];

    unsigned char buf[4096];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1                                     unused
    p[0] = 0;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     0                               reply length
    write_uint32(p, 0);
    p+=4;

    //2     CARD16                          red
    write_uint16(p, red);
    p+=2;

    //2     CARD16                          green
    write_uint16(p, green);
    p+=2;

    //2     CARD16                          blue
    write_uint16(p, blue);
    p+=2;

    //2                                     unused
    p[0] = 0;
    p[1] = 0;
    p+=2;

    //4     CARD32                          pixel
    p[0] = blue/256;
    p[1] = green/256;
    p[2] = red/256;
    p[3] = 0;
    p+=4;

    //12                                    unused
    memset(p, 0, 12);
    p+=12;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendGetInputFocusResponse:(int)requestLength
{
    unsigned char buf[4096];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1                                     revert-to
    //      0     None
    //      1     PointerRoot
    //      2     Parent
    p[0] = 0;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     0                               reply length
    write_uint32(p, 0);
    p+=4;

    //4     WINDOW                          focus
    //      0     None
    //      1     PointerRoot
    write_uint32(p, 0);
    p+=4;

    //20                                    unused
    memset(p, 0, 20);
    p+=20;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendLookupColorResponse:(int)requestLength
{
    unsigned char buf[256];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1                                     unused
    p[0] = 0;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     0                               reply length
    write_uint32(p, 0);
    p+=4;

//FIXME
    //2     CARD16                          exact-red
    p[0] = 0;
    p[1] = 0;
    p+=2;

    //2     CARD16                          exact-green
    p[0] = 0;
    p[1] = 0;
    p+=2;

    //2     CARD16                          exact-blue
    p[0] = 0;
    p[1] = 0;
    p+=2;

    //2     CARD16                          visual-red
    p[0] = 0;
    p[1] = 0;
    p+=2;

    //2     CARD16                          visual-green
    p[0] = 0;
    p[1] = 0;
    p+=2;

    //2     CARD16                          visual-blue
    p[0] = 0;
    p[1] = 0;
    p+=2;

    //12                                    unused
    memset(p, 0, 12);
    p+=12;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendQueryFontResponse:(int)requestLength
{
    unsigned char buf[4096];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1                                     unused
    p[0] = 0;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     7+2n+3m                         reply length
    unsigned char *replyLength = p;
    p+=4;

    //12     CHARINFO                       min-bounds
    //2     INT16                           left-side-bearing
    write_uint16(p, 0);
    p+=2;

    //2     INT16                           right-side-bearing
    write_uint16(p, 0);
    p+=2;

    //2     INT16                           character-width
    write_uint16(p, 8);
    p+=2;

    //2     INT16                           ascent
    write_uint16(p, 16);
    p+=2;

    //2     INT16                           descent
    write_uint16(p, 0);
    p+=2;

    //2     CARD16                          attributes
    write_uint16(p, 0);
    p+=2;

    //4                                     unused
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //12     CHARINFO                       max-bounds
    //2     INT16                           left-side-bearing
    write_uint16(p, 0);
    p+=2;

    //2     INT16                           right-side-bearing
    write_uint16(p, 0);
    p+=2;

    //2     INT16                           character-width
    write_uint16(p, 8);
    p+=2;

    //2     INT16                           ascent
    write_uint16(p, 16);
    p+=2;

    //2     INT16                           descent
    write_uint16(p, 0);
    p+=2;

    //2     CARD16                          attributes
    write_uint16(p, 0);
    p+=2;

    //4                                     unused
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //2     CARD16                          min-char-or-byte2
    write_uint16(p, 0);
    p+=2;

    //2     CARD16                          max-char-or-byte2
    write_uint16(p, 127);
    p+=2;

    //2     CARD16                          default-char
    write_uint16(p, 32);
    p+=2;

    //2     n                               number of FONTPROPs in properties
    write_uint16(p, 0);
    p+=2;

    //1                                     draw-direction
    //      0     LeftToRight
    //      1     RightToLeft
    p[0] = 0;
    p++;

    //1     CARD8                           min-byte1
    p[0] = 0;
    p++;

    //1     CARD8                           max-byte1
    p[0] = 127;
    p++;

    //1     BOOL                            all-chars-exist
    p[0] = 1;
    p++;

    //2     INT16                           font-ascent
    write_uint16(p, 16);
    p+=2;

    //2     INT16                           font-descent
    write_uint16(p, 0);
    p+=2;

    //4     m                               number of CHARINFOs in char-infos
    write_uint32(p, 256);
    p+=4;

    //8n     LISTofFONTPROP                 properties
    //FONTPROP
    //4     ATOM                            name
    //4     <32-bits>                 value

    //12m     LISTofCHARINFO                char-infos
    for (int i=0; i<256; i++) {
        //CHARINFO
        //2     INT16                           left-side-bearing
        write_uint16(p, 0);
        p+=2;

        //2     INT16                           right-side-bearing
        write_uint16(p, 0);
        p+=2;

        //2     INT16                           character-width
        write_uint16(p, 8);
        p+=2;

        //2     INT16                           ascent
        write_uint16(p, 16);
        p+=2;

        //2     INT16                           descent
        write_uint16(p, 0);
        p+=2;

        //2     CARD16                          attributes
        write_uint16(p, 0);
        p+=2;
    }

    write_uint32(replyLength, (p-buf-32)/4);
NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendGetModifierMappingResponse:(int)requestLength
{
    unsigned char buf[4096];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1     n                               keycodes-per-modifier
    p[0] = 4;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     2n                              reply length
    write_uint32(p, 8);
    p+=4;

    //24                                    unused
    memset(p, 0, 24);
    p+=24;

    //8n     LISTofKEYCODE                  keycodes
    p[0] = 0x32;
    p[1] = 0x3e;
    p[2] = 0x00;
    p[3] = 0x00;
    p[4] = 0x42;
    p[5] = 0x00;
    p[6] = 0x00;
    p[7] = 0x00;
    p[8] = 0x25;
    p[9] = 0x69;
    p[10] = 0x00;
    p[11] = 0x00;
    p[12] = 0x40;
    p[13] = 0x6c;
    p[14] = 0xcd;
    p[15] = 0x00;
    p[16] = 0x4d;
    p[17] = 0x00;
    p[18] = 0x00;
    p[19] = 0x00;
    p[20] = 0x00;
    p[21] = 0x00;
    p[22] = 0x00;
    p[23] = 0x00;
    p[24] = 0x85;
    p[25] = 0x86;
    p[26] = 0xce;
    p[27] = 0xcf;
    p[28] = 0x5c;
    p[29] = 0xcb;
    p[30] = 0x00;
    p[31] = 0x00;
    p+=32;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendGetKeyboardMappingResponse:(int)requestLength
{
#define KEYMAPLEN 6976
static unsigned char keymap[KEYMAPLEN] = {
0x01,0x07,0x01,0x00,0xc8,0x06,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x1b,0xff,0x00,0x00,
0x00,0x00,0x00,0x00,0x1b,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x31,0x00,0x00,0x00,0x21,0x00,0x00,0x00,
0x31,0x00,0x00,0x00,0x21,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x32,0x00,0x00,0x00,0x40,0x00,0x00,0x00,0x32,0x00,0x00,0x00,
0x40,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x33,0x00,0x00,0x00,0x23,0x00,0x00,0x00,0x33,0x00,0x00,0x00,0x23,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x34,0x00,0x00,0x00,0x24,0x00,0x00,0x00,0x34,0x00,0x00,0x00,0x24,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x35,0x00,0x00,0x00,0x25,0x00,0x00,0x00,0x35,0x00,0x00,0x00,0x25,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x36,0x00,0x00,0x00,0x5e,0x00,0x00,0x00,0x36,0x00,0x00,0x00,0x5e,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x37,0x00,0x00,0x00,0x26,0x00,0x00,0x00,0x37,0x00,0x00,0x00,0x26,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x38,0x00,0x00,0x00,
0x2a,0x00,0x00,0x00,0x38,0x00,0x00,0x00,0x2a,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x39,0x00,0x00,0x00,0x28,0x00,0x00,0x00,
0x39,0x00,0x00,0x00,0x28,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x30,0x00,0x00,0x00,0x29,0x00,0x00,0x00,0x30,0x00,0x00,0x00,
0x29,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x2d,0x00,0x00,0x00,0x5f,0x00,0x00,0x00,0x2d,0x00,0x00,0x00,0x5f,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x3d,0x00,0x00,0x00,0x2b,0x00,0x00,0x00,0x3d,0x00,0x00,0x00,0x2b,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0xff,0x00,0x00,0x08,0xff,0x00,0x00,0x08,0xff,0x00,0x00,0x08,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xd5,0xfe,0x00,0x00,0x09,0xff,0x00,0x00,0x20,0xfe,0x00,0x00,0x09,0xff,0x00,0x00,0x20,0xfe,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x71,0x00,0x00,0x00,0x51,0x00,0x00,0x00,0x71,0x00,0x00,0x00,0x51,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x77,0x00,0x00,0x00,
0x57,0x00,0x00,0x00,0x77,0x00,0x00,0x00,0x57,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x65,0x00,0x00,0x00,0x45,0x00,0x00,0x00,
0x65,0x00,0x00,0x00,0x45,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x72,0x00,0x00,0x00,0x52,0x00,0x00,0x00,0x72,0x00,0x00,0x00,
0x52,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x74,0x00,0x00,0x00,0x54,0x00,0x00,0x00,0x74,0x00,0x00,0x00,0x54,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x79,0x00,0x00,0x00,0x59,0x00,0x00,0x00,0x79,0x00,0x00,0x00,0x59,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x75,0x00,0x00,0x00,0x55,0x00,0x00,0x00,0x75,0x00,0x00,0x00,0x55,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x69,0x00,0x00,0x00,0x49,0x00,0x00,0x00,0x69,0x00,0x00,0x00,0x49,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x6f,0x00,0x00,0x00,0x4f,0x00,0x00,0x00,0x6f,0x00,0x00,0x00,0x4f,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x70,0x00,0x00,0x00,
0x50,0x00,0x00,0x00,0x70,0x00,0x00,0x00,0x50,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x5b,0x00,0x00,0x00,0x7b,0x00,0x00,0x00,
0x5b,0x00,0x00,0x00,0x7b,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x5d,0x00,0x00,0x00,0x7d,0x00,0x00,0x00,0x5d,0x00,0x00,0x00,
0x7d,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x0d,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x0d,0xff,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xe3,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0xe3,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x61,0x00,0x00,0x00,0x41,0x00,0x00,0x00,0x61,0x00,0x00,0x00,0x41,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x73,0x00,0x00,0x00,0x53,0x00,0x00,0x00,0x73,0x00,0x00,0x00,0x53,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x64,0x00,0x00,0x00,0x44,0x00,0x00,0x00,0x64,0x00,0x00,0x00,0x44,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x66,0x00,0x00,0x00,
0x46,0x00,0x00,0x00,0x66,0x00,0x00,0x00,0x46,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x67,0x00,0x00,0x00,0x47,0x00,0x00,0x00,
0x67,0x00,0x00,0x00,0x47,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x68,0x00,0x00,0x00,0x48,0x00,0x00,0x00,0x68,0x00,0x00,0x00,
0x48,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x6a,0x00,0x00,0x00,0x4a,0x00,0x00,0x00,0x6a,0x00,0x00,0x00,0x4a,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x6b,0x00,0x00,0x00,0x4b,0x00,0x00,0x00,0x6b,0x00,0x00,0x00,0x4b,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x6c,0x00,0x00,0x00,0x4c,0x00,0x00,0x00,0x6c,0x00,0x00,0x00,0x4c,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x3b,0x00,0x00,0x00,0x3a,0x00,0x00,0x00,0x3b,0x00,0x00,0x00,0x3a,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x27,0x00,0x00,0x00,0x22,0x00,0x00,0x00,0x27,0x00,0x00,0x00,0x22,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x60,0x00,0x00,0x00,
0x7e,0x00,0x00,0x00,0x60,0x00,0x00,0x00,0x7e,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xe1,0xff,0x00,0x00,0x00,0x00,0x00,0x00,
0xe1,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x5c,0x00,0x00,0x00,0x7c,0x00,0x00,0x00,0x5c,0x00,0x00,0x00,
0x7c,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x7a,0x00,0x00,0x00,0x5a,0x00,0x00,0x00,0x7a,0x00,0x00,0x00,0x5a,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x78,0x00,0x00,0x00,0x58,0x00,0x00,0x00,0x78,0x00,0x00,0x00,0x58,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x63,0x00,0x00,0x00,0x43,0x00,0x00,0x00,0x63,0x00,0x00,0x00,0x43,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x76,0x00,0x00,0x00,0x56,0x00,0x00,0x00,0x76,0x00,0x00,0x00,0x56,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x62,0x00,0x00,0x00,0x42,0x00,0x00,0x00,0x62,0x00,0x00,0x00,0x42,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x6e,0x00,0x00,0x00,
0x4e,0x00,0x00,0x00,0x6e,0x00,0x00,0x00,0x4e,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x6d,0x00,0x00,0x00,0x4d,0x00,0x00,0x00,
0x6d,0x00,0x00,0x00,0x4d,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x2c,0x00,0x00,0x00,0x3c,0x00,0x00,0x00,0x2c,0x00,0x00,0x00,
0x3c,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x2e,0x00,0x00,0x00,0x3e,0x00,0x00,0x00,0x2e,0x00,0x00,0x00,0x3e,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x2f,0x00,0x00,0x00,0x3f,0x00,0x00,0x00,0x2f,0x00,0x00,0x00,0x3f,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xe2,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0xe2,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0xaa,0xff,0x00,0x00,0xaa,0xff,0x00,0x00,0xaa,0xff,0x00,0x00,0xaa,0xff,0x00,0x00,0xaa,0xff,0x00,0x00,0xaa,0xff,0x00,0x00,0x21,0xfe,0x08,0x10,
0xe9,0xff,0x00,0x00,0xe7,0xff,0x00,0x00,0xe9,0xff,0x00,0x00,0xe7,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x20,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x20,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xe5,0xff,0x00,0x00,0x00,0x00,0x00,0x00,
0xe5,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xbe,0xff,0x00,0x00,0xbe,0xff,0x00,0x00,0xbe,0xff,0x00,0x00,
0xbe,0xff,0x00,0x00,0xbe,0xff,0x00,0x00,0xbe,0xff,0x00,0x00,0x01,0xfe,0x08,0x10,0xbf,0xff,0x00,0x00,0xbf,0xff,0x00,0x00,0xbf,0xff,0x00,0x00,0xbf,0xff,0x00,0x00,
0xbf,0xff,0x00,0x00,0xbf,0xff,0x00,0x00,0x02,0xfe,0x08,0x10,0xc0,0xff,0x00,0x00,0xc0,0xff,0x00,0x00,0xc0,0xff,0x00,0x00,0xc0,0xff,0x00,0x00,0xc0,0xff,0x00,0x00,
0xc0,0xff,0x00,0x00,0x03,0xfe,0x08,0x10,0xc1,0xff,0x00,0x00,0xc1,0xff,0x00,0x00,0xc1,0xff,0x00,0x00,0xc1,0xff,0x00,0x00,0xc1,0xff,0x00,0x00,0xc1,0xff,0x00,0x00,
0x04,0xfe,0x08,0x10,0xc2,0xff,0x00,0x00,0xc2,0xff,0x00,0x00,0xc2,0xff,0x00,0x00,0xc2,0xff,0x00,0x00,0xc2,0xff,0x00,0x00,0xc2,0xff,0x00,0x00,0x05,0xfe,0x08,0x10,
0xc3,0xff,0x00,0x00,0xc3,0xff,0x00,0x00,0xc3,0xff,0x00,0x00,0xc3,0xff,0x00,0x00,0xc3,0xff,0x00,0x00,0xc3,0xff,0x00,0x00,0x06,0xfe,0x08,0x10,0xc4,0xff,0x00,0x00,
0xc4,0xff,0x00,0x00,0xc4,0xff,0x00,0x00,0xc4,0xff,0x00,0x00,0xc4,0xff,0x00,0x00,0xc4,0xff,0x00,0x00,0x07,0xfe,0x08,0x10,0xc5,0xff,0x00,0x00,0xc5,0xff,0x00,0x00,
0xc5,0xff,0x00,0x00,0xc5,0xff,0x00,0x00,0xc5,0xff,0x00,0x00,0xc5,0xff,0x00,0x00,0x08,0xfe,0x08,0x10,0xc6,0xff,0x00,0x00,0xc6,0xff,0x00,0x00,0xc6,0xff,0x00,0x00,
0xc6,0xff,0x00,0x00,0xc6,0xff,0x00,0x00,0xc6,0xff,0x00,0x00,0x09,0xfe,0x08,0x10,0xc7,0xff,0x00,0x00,0xc7,0xff,0x00,0x00,0xc7,0xff,0x00,0x00,0xc7,0xff,0x00,0x00,
0xc7,0xff,0x00,0x00,0xc7,0xff,0x00,0x00,0x0a,0xfe,0x08,0x10,0x7f,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x7f,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x14,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x14,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x95,0xff,0x00,0x00,0xb7,0xff,0x00,0x00,0x95,0xff,0x00,0x00,0xb7,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x97,0xff,0x00,0x00,0xb8,0xff,0x00,0x00,0x97,0xff,0x00,0x00,0xb8,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x9a,0xff,0x00,0x00,
0xb9,0xff,0x00,0x00,0x9a,0xff,0x00,0x00,0xb9,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xad,0xff,0x00,0x00,0xad,0xff,0x00,0x00,
0xad,0xff,0x00,0x00,0xad,0xff,0x00,0x00,0xad,0xff,0x00,0x00,0xad,0xff,0x00,0x00,0x23,0xfe,0x08,0x10,0x96,0xff,0x00,0x00,0xb4,0xff,0x00,0x00,0x96,0xff,0x00,0x00,
0xb4,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x9d,0xff,0x00,0x00,0xb5,0xff,0x00,0x00,0x9d,0xff,0x00,0x00,0xb5,0xff,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x98,0xff,0x00,0x00,0xb6,0xff,0x00,0x00,0x98,0xff,0x00,0x00,0xb6,0xff,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xab,0xff,0x00,0x00,0xab,0xff,0x00,0x00,0xab,0xff,0x00,0x00,0xab,0xff,0x00,0x00,0xab,0xff,0x00,0x00,0xab,0xff,0x00,0x00,
0x22,0xfe,0x08,0x10,0x9c,0xff,0x00,0x00,0xb1,0xff,0x00,0x00,0x9c,0xff,0x00,0x00,0xb1,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x99,0xff,0x00,0x00,0xb2,0xff,0x00,0x00,0x99,0xff,0x00,0x00,0xb2,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x9b,0xff,0x00,0x00,
0xb3,0xff,0x00,0x00,0x9b,0xff,0x00,0x00,0xb3,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x9e,0xff,0x00,0x00,0xb0,0xff,0x00,0x00,
0x9e,0xff,0x00,0x00,0xb0,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x9f,0xff,0x00,0x00,0xae,0xff,0x00,0x00,0x9f,0xff,0x00,0x00,
0xae,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0xfe,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0xfe,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x3c,0x00,0x00,0x00,0x3e,0x00,0x00,0x00,0x3c,0x00,0x00,0x00,0x3e,0x00,0x00,0x00,0x7c,0x00,0x00,0x00,0xa6,0x00,0x00,0x00,
0x7c,0x00,0x00,0x00,0xc8,0xff,0x00,0x00,0xc8,0xff,0x00,0x00,0xc8,0xff,0x00,0x00,0xc8,0xff,0x00,0x00,0xc8,0xff,0x00,0x00,0xc8,0xff,0x00,0x00,0x0b,0xfe,0x08,0x10,
0xc9,0xff,0x00,0x00,0xc9,0xff,0x00,0x00,0xc9,0xff,0x00,0x00,0xc9,0xff,0x00,0x00,0xc9,0xff,0x00,0x00,0xc9,0xff,0x00,0x00,0x0c,0xfe,0x08,0x10,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x26,0xff,0x00,0x00,0x00,0x00,0x00,0x00,
0x26,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x25,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x25,0xff,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x23,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x23,0xff,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x27,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x27,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x22,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x22,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x8d,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x8d,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xe4,0xff,0x00,0x00,
0x00,0x00,0x00,0x00,0xe4,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xaf,0xff,0x00,0x00,0xaf,0xff,0x00,0x00,
0xaf,0xff,0x00,0x00,0xaf,0xff,0x00,0x00,0xaf,0xff,0x00,0x00,0xaf,0xff,0x00,0x00,0x20,0xfe,0x08,0x10,0x61,0xff,0x00,0x00,0x15,0xff,0x00,0x00,0x61,0xff,0x00,0x00,
0x15,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xea,0xff,0x00,0x00,0xe8,0xff,0x00,0x00,0xea,0xff,0x00,0x00,0xe8,0xff,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x0a,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x0a,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x50,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x50,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x52,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x52,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x55,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x55,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x51,0xff,0x00,0x00,
0x00,0x00,0x00,0x00,0x51,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x53,0xff,0x00,0x00,0x00,0x00,0x00,0x00,
0x53,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x57,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x57,0xff,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x54,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x54,0xff,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x56,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x56,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x63,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x63,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0xff,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0xff,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x12,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x12,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x11,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x11,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x13,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x13,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x2a,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x2a,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xbd,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0xbd,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xb1,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xb1,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x13,0xff,0x00,0x00,0x6b,0xff,0x00,0x00,0x13,0xff,0x00,0x00,0x6b,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x4a,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x4a,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xae,0xff,0x00,0x00,
0xae,0xff,0x00,0x00,0xae,0xff,0x00,0x00,0xae,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x31,0xff,0x00,0x00,0x00,0x00,0x00,0x00,
0x31,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x34,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x34,0xff,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xeb,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0xeb,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xec,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0xec,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x67,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x67,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x69,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x69,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x66,0xff,0x00,0x00,
0x00,0x00,0x00,0x00,0x66,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x70,0xff,0x05,0x10,0x00,0x00,0x00,0x00,
0x70,0xff,0x05,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x65,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x65,0xff,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x71,0xff,0x05,0x10,0x00,0x00,0x00,0x00,0x71,0xff,0x05,0x10,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x57,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x57,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x6b,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x6b,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x6d,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x6d,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x68,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x68,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x58,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x58,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x6a,0xff,0x00,0x00,0x00,0x00,0x00,0x00,
0x6a,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x65,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x65,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x1d,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x1d,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x2f,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x2f,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x2b,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x2b,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x5d,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x5d,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x7b,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x7b,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x8a,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x8a,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x41,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x41,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x42,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x42,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x2e,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x2e,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x5a,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x5a,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x2d,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x2d,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x74,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x74,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x7f,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x7f,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x19,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x19,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x30,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x30,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x33,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x33,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x26,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x26,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x27,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x27,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x2c,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x2c,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x2c,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x2c,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x17,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x17,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x14,0xff,0x08,0x10,0x31,0xff,0x08,0x10,0x14,0xff,0x08,0x10,0x31,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x16,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x16,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x15,0xff,0x08,0x10,0x2c,0xff,0x08,0x10,0x15,0xff,0x08,0x10,0x2c,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x1c,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x1c,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x3e,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x3e,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x6e,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x6e,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x81,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x81,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x18,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x18,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x73,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x73,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x56,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x56,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x78,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x78,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x79,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x79,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x28,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x28,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x29,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x29,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x68,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x68,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x66,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x66,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x81,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x81,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x45,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x45,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x46,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x46,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x47,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x47,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x48,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x48,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x49,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x49,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xb2,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0xb2,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0xa9,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0xa9,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xb0,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0xb0,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xb1,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0xb1,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x7e,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x7e,0xff,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xe9,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0xe9,0xff,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xe7,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0xe7,0xff,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xeb,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0xeb,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xed,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0xed,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x14,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x14,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x31,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x31,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x43,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x43,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x44,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x44,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x4b,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x4b,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xa7,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0xa7,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x56,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x56,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x14,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x14,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x97,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x97,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x61,0xff,0x00,0x00,0x00,0x00,0x00,0x00,
0x61,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x8f,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x8f,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xb6,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0xb6,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x19,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x19,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x8e,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x8e,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x1b,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x1b,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x5f,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x5f,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x3c,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x3c,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x5e,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x5e,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x36,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x36,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x69,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x69,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x03,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x03,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x02,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x32,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x32,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x59,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x59,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x04,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x04,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x06,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x06,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x05,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x05,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x7b,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x7b,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x72,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x72,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x90,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x90,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x77,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x77,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x5b,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x5b,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x93,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x93,0xff,0x08,0x10,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x94,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x94,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x95,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x95,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x96,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x96,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x22,0xfe,0x08,0x10,
0x00,0x00,0x00,0x00,0x22,0xfe,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x23,0xfe,0x08,0x10,0x00,0x00,0x00,0x00,
0x23,0xfe,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x07,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x07,0xff,0x08,0x10,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xf4,0x10,0x08,0x10,0x00,0x00,0x00,0x00,0xf4,0x10,0x08,0x10,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xf5,0x10,0x08,0x10,0x00,0x00,0x00,0x00,0xf5,0x10,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xb4,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0xb4,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0xb5,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0xb5,0xff,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
};
    unsigned char buf[KEYMAPLEN];
    memcpy(buf, keymap, KEYMAPLEN);

    unsigned char *bytes = buf;
    int len = KEYMAPLEN;
    write_uint16(bytes+2, _sequenceNumber);
    send(_connfd, bytes, len, 0);
    return;


#if 0


    unsigned char *bytes = [_data bytes];
    int len = [_data length];
    if (len < 4) {
NSLog(@"not enough data");
        return;
    }
    int firstKeycode = bytes[4];
    int count = bytes[5];

    unsigned char buf[4096];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1     n                               keysyms-per-keycode
    p[0] = 1;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     nm                              reply length (m = count field
    //                                       from the request)
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //24                                    unused
    memset(p, 0, 24);
    p+=24;

    //4nm     LISTofKEYSYM                  keysyms
    for (int i=0; i<count; i++) {
        p[0] = 32;
        p[1] = 0;
        p[2] = 0;
        p[3] = 0;
        p+=4;
    }

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
#endif
}
- (void)sendGetPointerMappingResponse:(int)requestLength
{
    unsigned char buf[4096];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1     n                               length of map
    p[0] = 3;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     (n+p)/4                         reply length
    write_uint32(p, 1);
    p+=4;

    //24                                    unused
    memset(p, 0, 24);
    p+=24;

    //n     LISTofCARD8                     map
    p[0] = 1;
    p[1] = 2;
    p[2] = 3;
    p[3] = 0;
    p+=4;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendGetScreenSaverResponse:(int)requestLength
{
    unsigned char buf[4096];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1                                     unused
    p[0] = 0;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     0                               reply length
    write_uint32(p, 0);
    p+=4;

    //2     CARD16                          timeout
    write_uint16(p, 0);
    p+=2;

    //2     CARD16                          interval
    write_uint16(p, 0);
    p+=2;

    //1                                     prefer-blanking
    //      0     No
    //      1     Yes
    *p = 0;
    p++;

    //1                                     allow-exposures
    //      0     No
    //      1     Yes
    *p = 0;
    p++;

    //18                                    unused
    memset(p, 0, 18);
    p+=18;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendGetSelectionOwnerResponse:(int)requestLength
{
    unsigned char buf[4096];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1                                     unused
    p[0] = 0;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     0                               reply length
    write_uint32(p, 0);
    p+=4;

    //4     WINDOW                          owner
    //      0     None
    write_uint32(p, 0);
    p+=4;

    //20                                    unused
    memset(p, 0, 20);
    p+=20;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendQueryPointerResponse:(int)requestLength
{
    unsigned char buf[4096];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1     BOOL                            same-screen
    p[0] = 1;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     0                               reply length
    write_uint32(p, 0);
    p+=4;

    //4     WINDOW                          root
    id xserver = [@"XServer" valueForKey];
    write_uint32(p, [xserver unsignedLongValueForKey:@"rootWindow"]);
    p+=4;

    //4     WINDOW                          child
    //      0     None
    write_uint32(p, 0);
    p+=4;

    //2     INT16                           root-x
    write_uint16(p, _mouseX);
    p+=2;

    //2     INT16                           root-y
    write_uint16(p, _mouseY);
    p+=2;

    //2     INT16                           win-x
    write_uint16(p, _mouseX);
    p+=2;

    //2     INT16                           win-y
    write_uint16(p, _mouseY);
    p+=2;

    //2     SETofKEYBUTMASK                 mask
    write_uint16(p, 0);
    p+=2;

    //6                                     unused
    memset(p, 0, 6);
    p+=6;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendTranslateCoordinatesResponse:(int)requestLength
{
    id request = [self parseTranslateCoordinatesRequest:requestLength];
    if (!request) {
        return;
    }

    unsigned char buf[4096];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1     BOOL                            same-screen
    p[0] = 1;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     0                               reply length
    write_uint32(p, 0);
    p+=4;

    //4     WINDOW                          child
    //      0     None
    write_uint32(p, 0);
    p+=4;

    //2     INT16                           dst-x
    write_uint16(p, [request intValueForKey:@"srcX"]);
    p+=2;

    //2     INT16                           dst-y
    write_uint16(p, [request intValueForKey:@"srcY"]);
    p+=2;

    //16                                    unused
    memset(p, 0, 16);
    p+=16;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendQueryKeymapResponse:(int)requestLength
{
    id request = [self parseQueryKeymapRequest:requestLength];
    if (!request) {
        return;
    }

    unsigned char buf[4096];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1                                     unused
    p[0] = 0;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     0                               reply length
    write_uint32(p, 2);
    p+=4;

    for (int i=0; i<32; i++) {
        *p = 0;
        p++;
    }

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendGetKeyboardControlResponse:(int)requestLength
{
    id request = [self parseGetKeyboardControlRequest:requestLength];
    if (!request) {
        return;
    }

    unsigned char buf[4096];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1                                     global-auto-repeat
    //      0     Off
    //      1     On
    p[0] = 0;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     0                               reply length
    write_uint32(p, 5);
    p+=4;

    //4     CARD32                          led-mask
    write_uint32(p, 0);
    p+=4;

    //1     CARD8                           key-click-percent
    *p = 0;
    p++;

    //1     CARD8                           bell-percent
    *p = 0;
    p++;

    //2     CARD16                          bell-pitch
    write_uint16(p, 0);
    p+=2;

    //2     CARD16                          bell-duration
    write_uint16(p, 0);
    p+=2;

    //2                                     unused
    p[0] = 0;
    p[1] = 0;
    p+=2;

    for (int i=0; i<32; i++) {
        *p = 0;
        p++;
    }

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}



- (void)sendMITSHMQueryVersionResponse:(int)requestLength
{
    id request = [self parseMITSHMQueryVersionRequest:requestLength];
    if (!request) {
        return;
    }

    unsigned char buf[4096];
    unsigned char *p = buf;

    //reply
    p[0] = 1;
    p++;

    //shared_pixmaps
    p[0] = 1;
    p++;

    //sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //reply length
    write_uint32(p, 0);
    p+=4;

    //major_version
    write_uint16(p, 1);
    p+=2;

    //minor_version
    write_uint16(p, 2);
    p+=2;

    //uid
    write_uint16(p, 0);
    p+=2;

    //gid
    write_uint16(p, 100);
    p+=2;

    //pixmap_format
    *p = 2;
    p++;

    //unused
    memset(p, 0, 15);
    p+=15;


NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendMITSHMPutImageResponse:(int)requestLength
{
    id request = [self parseMITSHMPutImageRequest:requestLength];
    if (!request) {
        return;
    }

    int send_event = [request intValueForKey:@"send_event"];
    if (!send_event) {
        return;
    }

    unsigned char buf[4096];
    unsigned char *p = buf;

    //code
    p[0] = 65;
    p++;

    //unused
    p[0] = 0;
    p++;

    //sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //drawable
    write_uint32(p, [request unsignedLongValueForKey:@"drawable"]);
    p+=4;

    //minor_event
    write_uint16(p, 3);
    p+=2;

    //major_event
    *p = 135;
    p++;

    //unused
    *p = 0;
    p++;

    //shmseg
    write_uint32(p, [request unsignedLongValueForKey:@"shmseg"]);
    p+=4;

    //offset
    write_uint32(p, [request unsignedLongValueForKey:@"offset"]);
    p+=4;

    //unused
    memset(p, 0, 12);
    p+=12;


NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}

- (void)sendPresentQueryVersionResponse:(int)requestLength
{
    id request = [self parsePresentQueryVersionRequest:requestLength];
    if (!request) {
        return;
    }

    unsigned char buf[4096];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //
    p[0] = 0;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     0                               reply length
    write_uint32(p, 0);
    p+=4;

    //major-version:		CARD32
    write_uint32(p, [request unsignedLongValueForKey:@"clientMajorVersion"]);
    p+=4;

    //minor-version:		CARD32
    write_uint32(p, [request unsignedLongValueForKey:@"clientMinorVersion"]);
    p+=4;

    memset(p, 0, 16);
    p+=16;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendXFixesQueryVersionResponse:(int)requestLength
{
    id request = [self parseXFixesQueryVersionRequest:requestLength];
    if (!request) {
        return;
    }

    unsigned char buf[4096];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //
    p[0] = 0;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber);
    p+=2;

    //4     0                               reply length
    write_uint32(p, 0);
    p+=4;

    //major-version:		CARD32
    write_uint32(p, [request unsignedLongValueForKey:@"clientMajorVersion"]);
    p+=4;

    //minor-version:		CARD32
    write_uint32(p, [request unsignedLongValueForKey:@"clientMinorVersion"]);
    p+=4;

    memset(p, 0, 16);
    p+=16;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}


- (void)processCreateWindowRequest:(int)requestLength
{
    id request = [self parseCreateWindowRequest:requestLength];
    if (!request){ 
        return;
    }

    id key = [request valueForKey:@"wid"];
    if (!key) {
        return;
    }
    [request setValue:nsdict() forKey:@"properties"];
    id xserver = [@"XServer" valueForKey];
    id windows = [xserver valueForKey:@"windows"];
    [windows setValue:request forKey:key];
}

- (void)processChangePropertyRequest:(int)requestLength
{
    id request = [self parseChangePropertyRequest:requestLength];
    if (!request) {
        return;
    }

    id windowKey = [request valueForKey:@"window"];
    if (!windowKey) {
        return;
    }

    id xserver = [@"XServer" valueForKey];
    id windows = [xserver valueForKey:@"windows"];
    id window = [windows valueForKey:windowKey];
    if (window) {
        int mode = [request intValueForKey:@"mode"];
        id propertyKey = [request valueForKey:@"property"];
        if (propertyKey) {
            [[window valueForKey:@"properties"] setValue:request forKey:propertyKey];
        }
    }
}

- (void)processImageText8Request:(int)requestLength
{
    id request = [self parseImageText8Request:requestLength];
    if (!request) {
        return;
    }

    id drawableKey = [request valueForKey:@"drawable"];
    if (!drawableKey) {
        return;
    }
    id xserver = [@"XServer" valueForKey];
    id windows = [xserver valueForKey:@"windows"];
    id window = [windows valueForKey:drawableKey];
    if (!window) {
        return;
    }

    id string = [request valueForKey:@"string"];
    if (!string) {
        return;
    }

    id bitmap = [window valueForKey:@"bitmap"];
    int x = [request intValueForKey:@"x"];
    int y = [request intValueForKey:@"y"];

    [bitmap setColor:@"white"];
    [bitmap drawBitmapText:string x:x y:y-16];
}

- (void)processCopyAreaRequest:(int)requestLength
{
    id request = [self parseCopyAreaRequest:requestLength];
    if (!request) {
        return;
    }

    id srcDrawableKey = [request valueForKey:@"srcDrawable"];
    id dstDrawableKey = [request valueForKey:@"dstDrawable"];
    if (!srcDrawableKey || !dstDrawableKey) {
        return;
    }

    id xserver = [@"XServer" valueForKey];
    id windows = [xserver valueForKey:@"windows"];
    id srcWindow = [windows valueForKey:srcDrawableKey];
    id dstWindow = [windows valueForKey:dstDrawableKey];
    if (!srcWindow || !dstWindow) {
        return;
    }

    int srcX = [request intValueForKey:@"srcX"];
    int srcY = [request intValueForKey:@"srcY"];
    int dstX = [request intValueForKey:@"dstX"];
    int dstY = [request intValueForKey:@"dstY"];
    int width = [request intValueForKey:@"width"];
    int height = [request intValueForKey:@"height"];

    id srcBitmap = [srcWindow valueForKey:@"bitmap"];
    id dstBitmap = [dstWindow valueForKey:@"bitmap"];
    [dstBitmap drawBitmap:srcBitmap x:srcX y:srcY w:width h:height atX:dstX y:dstY];
}
- (void)processClearAreaRequest:(int)requestLength
{
    id request = [self parseClearAreaRequest:requestLength];
    if (!request) {
        return;
    }

    id windowKey = [request valueForKey:@"window"];
    if (!windowKey) {
        return;
    }

    id xserver = [@"XServer" valueForKey];
    id windows = [xserver valueForKey:@"windows"];
    id window = [windows valueForKey:windowKey];
    if (!window) {
        return;
    }

    id bitmap = [window valueForKey:@"bitmap"];

    int x = [request intValueForKey:@"x"];
    int y = [request intValueForKey:@"y"];
    int width = [request intValueForKey:@"width"];
    int height = [request intValueForKey:@"height"];
    [bitmap setColor:@"black"];
    [bitmap fillRectangleAtX:x y:y w:width h:height];
}
- (void)processPutImageRequest:(int)requestLength
{
    id request = [self parsePutImageRequest:requestLength];
    if (!request) {
        return;
    }

    id drawableKey = [request valueForKey:@"drawable"];
    if (!drawableKey) {
        return;
    }

    id xserver = [@"XServer" valueForKey];
    id windows = [xserver valueForKey:@"windows"];
    id window = [windows valueForKey:drawableKey];
    if (!window) {
        return;
    }

    id requestBitmap = [request valueForKey:@"bitmap"];
    if (!requestBitmap) {
        return;
    }

    id windowBitmap = [window valueForKey:@"bitmap"];

    int width = [request intValueForKey:@"width"];
    int height = [request intValueForKey:@"height"];
    int dstX = [request intValueForKey:@"dstX"];
    int dstY = [request intValueForKey:@"dstY"];

    [windowBitmap drawBitmap:requestBitmap x:dstX y:dstY];
}

- (void)processConfigureWindowRequest:(int)requestLength
{
    id request = [self parseConfigureWindowRequest:requestLength];
    if (!request) {
        return;
    }

    id windowKey = [request valueForKey:@"window"];
    if (!windowKey) {
        return;
    }

    id xserver = [@"XServer" valueForKey];
    id windows = [xserver valueForKey:@"windows"];
    id window = [windows valueForKey:windowKey];
    if (!window) {
        return;
    }

    id x = [request valueForKey:@"x"];
    if (x) {
        [window setValue:x forKey:@"x"];
    }

    id y = [request valueForKey:@"y"];
    if (y) {
        [window setValue:y forKey:@"y"];
    }

    id width = [request valueForKey:@"width"];
    if (width) {
        [window setValue:width forKey:@"width"];
    }

    id height = [request valueForKey:@"height"];
    if (height) {
        [window setValue:height forKey:@"height"];
    }

    id borderWidth = [request valueForKey:@"borderWidth"];
    if (borderWidth) {
        [window setValue:height forKey:@"borderWidth"];
    }
}
- (void)processMapWindowRequest:(int)requestLength
{
    id request = [self parseMapWindowRequest:requestLength];
    if (!request) {
        return;
    }

    unsigned char buf[256];
    unsigned char *p = buf;

    *p = 19;
    p++;

    *p = 0;
    p++;

    write_uint16(p, _sequenceNumber);
    p+=2;

    uint32_t window = [request unsignedLongValueForKey:@"window"];
    write_uint32(p, window);
    p+=4;

    write_uint32(p, window);
    p+=4;

    *p = 0;
    p++;

    memset(p, 0, 19);
    p+=19;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}

- (void)processSendEventRequest:(int)requestLength
{
    id request = [self parseSendEventRequest:requestLength];
    if (!request) {
        return;
    }

    uint32_t destination = [request unsignedLongValueForKey:@"destination"];

    id event = [request valueForKey:@"event"];

    int len = [event length];
    if (len != 32) {
        return;
    }

    unsigned char *bytes = [event bytes];

    unsigned char buf[32];
    memcpy(buf, bytes, 32);

    write_uint16(&buf[2], _sequenceNumber);
    write_uint32(&buf[4], destination);

NSLog(@"sending 32 bytes");
    send(_connfd, buf, 32, 0);
}

    

- (void)sendKeyPressEvent:(int)keycode
{
    if (_connfd < 0) {
        return;
    }

//FIXME
id xserver = [@"XServer" valueForKey];
id windows = [xserver valueForKey:@"windows"];
id allKeys = [windows allKeys];
id lastObject = [allKeys lastObject];
id window = [windows valueForKey:lastObject];

    unsigned char buf[256];
    unsigned char *p = buf;

    //1     2                               code
    *p = 2;
    p++;

    //1     KEYCODE                         detail
    *p = 8+keycode;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber-1);
    p+=2;

    //4     TIMESTAMP                       time
    write_uint32(p, 0);
    p+=4;

    //4     WINDOW                          root
    write_uint32(p, [xserver unsignedLongValueForKey:@"rootWindow"]);
    p+=4;

    //4     WINDOW                          event
    write_uint32(p, [lastObject unsignedLongValue]);
    p+=4;

    //4     WINDOW                          child
    //      0     None
    write_uint32(p, 0);
    p+=4;

    //2     INT16                           root-x
    write_uint16(p, 0);
    p+=2;

    //2     INT16                           root-y
    write_uint16(p, 0);
    p+=2;

    //2     INT16                           event-x
    write_uint16(p, 0);
    p+=2;

    //2     INT16                           event-y
    write_uint16(p, 0);
    p+=2;

    //2     SETofKEYBUTMASK                 state
    write_uint16(p, 0);
    p+=2;

    //1     BOOL                            same-screen
    *p = 0;
    p++;

    //1                                     unused
    *p = 0;
    p++;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}

- (void)sendMotionNotifyEvent
{
    if (_connfd < 0) {
        return;
    }

    int x = _mouseX;
    int y = _mouseY;

    
    unsigned char buf[256];
    unsigned char *p = buf;

    //1     6                               code
    *p = 6;
    p++;

    //1                                     detail
    //      0     Normal
    //      1     Hint
    *p = 0;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber-1);
    p+=2;

    //4     TIMESTAMP                       time
    write_uint32(p, 0);
    p+=4;

    //4     WINDOW                          root
    id xserver = [@"XServer" valueForKey];
    write_uint32(p, [xserver unsignedLongValueForKey:@"rootWindow"]);
    p+=4;

//FIXME
id windows = [xserver valueForKey:@"windows"];
id allKeys = [windows allKeys];
id lastObject = [allKeys lastObject];
id window = [windows valueForKey:lastObject];

    //4     WINDOW                          event
    write_uint32(p, [lastObject unsignedLongValue]);
    p+=4;

    //4     WINDOW                          child
    //       0     None
    write_uint32(p, 0);
    p+=4;

    //2     INT16                           root-x
    write_uint16(p, x);
    p+=2;

    //2     INT16                           root-y
    write_uint16(p, y);
    p+=2;

    //2     INT16                           event-x
    write_uint16(p, x);
    p+=2;

    //2     INT16                           event-y
    write_uint16(p, y);
    p+=2;

    //2     SETofKEYBUTMASK                 state
    write_uint16(p, 0);
    p+=2;

    //1     BOOL                            same-screen
    *p = 0;
    p++;

    //1                                     unused
    *p = 0;
    p++;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendButtonPressEvent
{
    if (_connfd < 0) {
        return;
    }

    int x = _mouseX;
    int y = _mouseY;

    
    unsigned char buf[256];
    unsigned char *p = buf;

    //1     4                               code
    *p = 4;
    p++;

    //1                                     detail
    *p = 1;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber-1);
    p+=2;

    //4     TIMESTAMP                       time
    write_uint32(p, 0);
    p+=4;

    //4     WINDOW                          root
id xserver = [@"XServer" valueForKey];
    write_uint32(p, [xserver unsignedLongValueForKey:@"rootWindow"]);
    p+=4;

//FIXME
id windows = [xserver valueForKey:@"windows"];
id allKeys = [windows allKeys];
id lastObject = [allKeys lastObject];
id window = [windows valueForKey:lastObject];

    //4     WINDOW                          event
    write_uint32(p, [lastObject unsignedLongValue]);
    p+=4;

    //4     WINDOW                          child
    //       0     None
    write_uint32(p, 0);
    p+=4;

    //2     INT16                           root-x
    write_uint16(p, x);
    p+=2;

    //2     INT16                           root-y
    write_uint16(p, y);
    p+=2;

    //2     INT16                           event-x
    write_uint16(p, x);
    p+=2;

    //2     INT16                           event-y
    write_uint16(p, y);
    p+=2;

    //2     SETofKEYBUTMASK                 state
    write_uint16(p, 0);
    p+=2;

    //1     BOOL                            same-screen
    *p = 0;
    p++;

    //1                                     unused
    *p = 0;
    p++;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendButtonReleaseEvent
{
    if (_connfd < 0) {
        return;
    }

    int x = _mouseX;
    int y = _mouseY;

    
    unsigned char buf[256];
    unsigned char *p = buf;

    //1     5                               code
    *p = 5;
    p++;

    //1                                     detail
    *p = 1;
    p++;

    //2     CARD16                          sequence number
    write_uint16(p, _sequenceNumber-1);
    p+=2;

    //4     TIMESTAMP                       time
    write_uint32(p, 0);
    p+=4;

    //4     WINDOW                          root
id xserver = [@"XServer" valueForKey];
    write_uint32(p, [xserver unsignedLongValueForKey:@"rootWindow"]);
    p+=4;

//FIXME
id windows = [xserver valueForKey:@"windows"];
id allKeys = [windows allKeys];
id lastObject = [allKeys lastObject];
id window = [windows valueForKey:lastObject];

    //4     WINDOW                          event
    write_uint32(p, [lastObject unsignedLongValue]);
    p+=4;

    //4     WINDOW                          child
    //       0     None
    write_uint32(p, 0);
    p+=4;

    //2     INT16                           root-x
    write_uint16(p, x);
    p+=2;

    //2     INT16                           root-y
    write_uint16(p, y);
    p+=2;

    //2     INT16                           event-x
    write_uint16(p, x);
    p+=2;

    //2     INT16                           event-y
    write_uint16(p, y);
    p+=2;

    //2     SETofKEYBUTMASK                 state
    write_uint16(p, 0);
    p+=2;

    //1     BOOL                            same-screen
    *p = 0;
    p++;

    //1                                     unused
    *p = 0;
    p++;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
@end

